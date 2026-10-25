// mltpxl.cw — ⏳ **회차 18 · 「국소 천장에 닿으면 yaw 읽기가 나타나나」** (얽힌 축 · 긴 훈련)
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문** — ⚠️ 재기 전에 적는다. 정본은 `mltlog_1.md` 회차 17 의 「회차 18 등록」이다.
// ══════════════════════════════════════════════════════════════════════════════
//
// ★ **무엇을 가르나**
//
//   회차 17 이 격차 구조를 밝혔다:
//   ```
//   copy 18.9  <  모델(600스텝) ≈56  <  눈먼 외삽 66.1  <  베이즈(yaw 아는 자) 82.2   (x 축)
//   ```
//   모델은 **축-국소 전략의 천장(눈먼 외삽)에 아직 못 닿았고**, 그래서 yaw 를 읽을 압력이 없었다
//   (x표적의 yaw 질량 1%). ⇒ 물음: ***훈련을 늘려 천장에 접근하면 yaw 읽기가 나타나는가?***
//
//   **설계**: 팔 4 만 · 판정 씨앗 12~23 · **2400스텝**(회차 17 의 4배) ·
//   프로브 `{600, 1200, 2400}` 에서 **`R(x)` 와 x표적의 yaw 질량**을 **함께** 찍는다.
//   ★ 씨앗별 기준: `R_blind(x)` = 눈먼 외삽의 `R`(그 씨앗의 시험 에피소드에서 잰다) —
//     그것이 「국소 천장」의 자리다(전 씨앗 평균 ≈ 0.75).
//
//   ⚠️⚠️ **미리 적는 세 갈래**(회차 17 에 등록)
//     ㈀ `R̄(x)` 가 **천장을 넘으면서** yaw 질량이 **≥ 10%** 로 오른다
//        ⇒ **압력이 기제를 만든다** — 회차 17 의 비대각 가설이 「늦게」 맞는 것이다.
//     ㈁ `R̄(x)` 가 **천장 근처에서 멈추고** 질량이 평평하다
//        ⇒ ***국소 전략이 남아 있는 동안 교차 축 읽기가 안 생기고, 천장에 닿아도 저절로
//        안 생길 수 있다*** — 이 기계(SGD+어텐션)의 성질에 대한 발견이다.
//     ㈂ `R̄(x)` 가 천장을 넘는데 질량이 **여전히 ~1%**
//        ⇒ **모순 — 제3 의 경로**(x 자신의 긴 역사에서 yaw 드리프트를 간접 복원) ⇒ 진단 재설계.
//   **부호검정**: 씨앗별 «yaw질량(2400) > yaw질량(600)» **10/12**.
//   **배관**: probs 합 1.0 · 유한.
//
// ⚠️ 이 회차도 **아무것도 만들지 않는다.** 비용: 12 실행 × ~2415 프레임 ⇒ **≈4분**.

using namespace PE;

class MLTPXL
{
public:
	static bool Done() { return _run >= kRuns; }

	static void Tick(RHI* rhi)
	{
		if (_run >= kRuns || rhi == nullptr) return;
		// ⚠️⚠️ **회차 127 이 고친 자리 — 이 하네스만 플래그 없이 「항상」 돌고 있었다.**
		//   체인의 **꼬리**라 눈에 안 띄었는데, 실측으로 **매 실행 ~10분**을 먹는다
		//   (회차 127 의 1씨앗 진단이 2분이어야 하는데 12분이 걸려서 잡혔다).
		//   ★ ⇒ 끝난 회차는 **꺼 두고 기록으로 인용한다**(이 파일의 다른 하네스 106개와 같은 규약).
		if (!OS::CommandLine::Has("-mltpxl"))
		{
			LogA("[mlt] ⏳ 회차 18(천장 접근과 yaw 읽기)은 **꺼져 있다**(`-mltpxl`) — 기록: "
				"R̄ 600→0.587 · 1200→0.641 · 2400→0.685(국소 천장 0.731) · yaw 질량 1.4→2.5%% (부호검정 10/12)\n");
			_run = kRuns; return;
		}
		if (MLTModelCfg::kAxes != MLTPX::kAxes || MLTModelCfg::kTime != MLTPX::kTime)
		{ LogA("[mlt] ⏳ ⛔⛔ 축/시각 전제가 다르다\n"); _run = kRuns; return; }
		if (!_banner) { _Banner(); _banner = true; }

		if (_st == kInit)
		{
			if (!_M.Setup(rhi)) { LogA("[mlt] ⏳ 준비 실패(run %u)\n", _run); _run = kRuns; return; }
			// 씨앗별 바닥·천장 + ⭐ **눈먼 외삽**(국소 천장) — 시험 에피소드에서.
			for (uint32 a = 0; a < MLTPX::kAxes; ++a)
			{
				MLTPX::Base c{}, b{};
				MLTPX::Baseline(a, _Seed(_run), 1u, kEvalEpi0, kEvalEpis, c, b);
				_cop[a] = c.acc; _bay[a] = b.acc;
			}
			_blind = MLTPX::_BlindExtrap(0u, _Seed(_run), 1u, kEvalEpi0, kEvalEpis);
			_step = 0u; _probe = 0u; _finite = true;
			_st = kTrain;
			return;
		}

		if (_st == kTrain)
		{
			if (_step > 0u)
			{
				float ls = 0.0f;
				if (!_M.ReadLoss(ls)) { LogA("[mlt] ⏳ 손실 리드백 실패\n"); _run = kRuns; return; }
				if (!(ls == ls) || ls > 1.0e30f) _finite = false;
			}
			// 프로브 점에 닿았나 — R 과 yaw 질량을 **함께** 찍는다.
			if (_probe < kProbes && _step >= kProbeAt[_probe]) { _StartEval(); return; }
			if (_step >= kTrainSteps) { _Finish(); return; }

			const uint32 K = MLTModelCfg::kPool;
			const uint32 slot = _step % K;
			if (slot == 0u)
			{
				const uint32 n = ((kTrainSteps - _step) < K) ? (kTrainSteps - _step) : K;
				_pv.Reset(0); _pt.Reset(0);
				for (uint32 k = 0; k < n; ++k)
				{
					Array<float> v, g;
					_Batch(_Seed(_run), 1000u + (_step + k) * MLTModelCfg::kBatch, kAll, v, g);
					for (uint32 i = 0; i < v.Count(); ++i) _pv.Add(v[i]);
					for (uint32 i = 0; i < g.Count(); ++i) _pt.Add(g[i]);
				}
				if (!_M.UploadPool(_pv, _pt, n)) { LogA("[mlt] ⏳ 풀 업로드 실패\n"); _run = kRuns; return; }
			}
			_M.SelectStep(slot);
			if (!_M.Forward() || !_M.Backward() || !_M.AdamStep())
			{ LogA("[mlt] ⏳ 스텝 실패(%u)\n", _step); _run = kRuns; return; }
			++_step;
			return;
		}

		if (_st == kEvalUp)
		{
			if (_eb >= kEvalB) { _st = kDiagUp; return; }
			_Batch(_Seed(_run), kEvalEpi0 + _eb * MLTModelCfg::kBatch, kAll, _ev, _et);
			if (!_M.Upload(_ev, _et)) { LogA("[mlt] ⏳ 시험 업로드 실패\n"); _run = kRuns; return; }
			if (!_M.Forward()) { LogA("[mlt] ⏳ 시험 forward 실패\n"); _run = kRuns; return; }
			_st = kEvalRd;
			return;
		}

		if (_st == kEvalRd)
		{
			Array<float> m;
			float sp = 0.0f;
			for (uint32 a = 0; a < MLTPX::kAxes; ++a)
			{
				m.Reset(0);
				for (uint32 r = 0; r < MLTModelCfg::kRows; ++r)
					m.Add((((r % MLTModelCfg::kCtx) % MLTPX::kAxes) == a) ? 1.0f : 0.0f);
				uint32 h = 0u, n = 0u, hb = 0u, nb = 0u;
				float dd = 0.0f, ddb = 0.0f, ddo = 0.0f;
				if (!_M.ReadHits(_et, m, h, n, hb, nb, sp, dd, ddb, ddo))
				{ LogA("[mlt] ⏳ 리드백 실패\n"); _run = kRuns; return; }
				_hit[a] += hb; _cnt[a] += nb;
			}
			_sumP += sp;
			++_eb;
			_st = kEvalUp;
			return;
		}

		// ── 진단: 표적을 x 만 남기고 fwd+bwd(AdamStep 없음) → yaw 질량
		if (_st == kDiagUp)
		{
			Array<float> v, g;
			_Batch(_Seed(_run), kEvalEpi0, 0u, v, g);
			if (!_M.Upload(v, g)) { LogA("[mlt] ⏳ 진단 업로드 실패\n"); _run = kRuns; return; }
			if (!_M.Forward() || !_M.Backward()) { LogA("[mlt] ⏳ 진단 실패\n"); _run = kRuns; return; }
			_st = kDiagRd;
			return;
		}

		// kDiagRd — 프로브 하나가 끝났다
		{
			float m[MLTPX::kAxes] = { 0.0f };
			if (!_M.ReadAxisMass(m, MLTPX::kAxes)) { LogA("[mlt] ⏳ 진단 리드백 실패\n"); _run = kRuns; return; }
			float tot = 0.0f;
			for (uint32 j = 0; j < MLTPX::kAxes; ++j) tot += m[j];
			const float yawShare = (tot > 1.0e-12f) ? m[2] / tot : 0.0f;
			for (uint32 a = 0; a < MLTPX::kAxes; ++a)
			{
				const float acc = _cnt[a] ? (float)_hit[a] / (float)_cnt[a] : 0.0f;
				const float w = _bay[a] - _cop[a];
				_pR[_probe][a] = (w > 1.0e-4f) ? (acc - _cop[a]) / w : 0.0f;
			}
			_pYaw[_probe] = yawShare;
			LogA("[mlt] ⏳ [%2u/%u] 씨앗%2u · step %4u · R(x) **%.3f**(천장 %.3f) · yaw 질량 **%.1f%%**\n",
				_run + 1u, kRuns, _Seed(_run), kProbeAt[_probe],
				(double)_pR[_probe][0], (double)_BlindR(), (double)(yawShare * 100.0f));
			++_probe;
			_st = kTrain;   // 훈련을 잇는다(마지막 프로브 = kTrainSteps 면 다음 분기에서 _Finish)
		}
	}

private:
	static constexpr uint32 kSeed0 = 12u, kSeeds = 12u;
	static constexpr uint32 kRuns = kSeeds;
	static constexpr int    kHold = MLTWorldCfg::kHoldMid;
	static constexpr uint32 kTrainSteps = 2400u;
	static constexpr uint32 kProbes = 3u;
	static constexpr uint32 kProbeAt[kProbes] = { 600u, 1200u, 2400u };
	static constexpr uint32 kEvalEpi0 = 0u, kEvalB = 4u;
	static constexpr uint32 kEvalEpis = kEvalB * MLTModelCfg::kBatch;
	static constexpr uint32 kAll = 0xFFFFFFFFu;
	static constexpr uint32 kSignNeed = 10u;
	static constexpr float  kMassUp = 0.10f;    // ㈀ 의 「≥ 10%」

	static uint32 _Seed(uint32 r) { return kSeed0 + r; }

	enum { kInit = 0, kTrain, kEvalUp, kEvalRd, kDiagUp, kDiagRd };

	inline static MLTModel _M;
	inline static bool _banner = false;
	inline static uint32 _run = 0u, _step = 0u, _probe = 0u, _eb = 0u;
	inline static int _st = kInit;
	inline static bool _finite = true;
	inline static float _sumP = 0.0f;
	inline static uint32 _hit[MLTPX::kAxes] = { 0u }, _cnt[MLTPX::kAxes] = { 0u };
	inline static float _cop[MLTPX::kAxes] = { 0.0f }, _bay[MLTPX::kAxes] = { 0.0f };
	inline static float _blind = 0.0f;
	inline static float _pR[kProbes][MLTPX::kAxes] = { { 0.0f } };
	inline static float _pYaw[kProbes] = { 0.0f };
	inline static Array<float> _ev, _et, _pv, _pt;

	inline static float _rR[kRuns][kProbes][MLTPX::kAxes] = { { { 0.0f } } };
	inline static float _rYaw[kRuns][kProbes] = { { 0.0f } };
	inline static float _rBlindR[kRuns] = { 0.0f };
	inline static bool  _rOk[kRuns] = { false };

	static float _BlindR()
	{
		const float w = _bay[0] - _cop[0];
		return (w > 1.0e-4f) ? (_blind - _cop[0]) / w : 0.0f;
	}

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] ⏳ **회차 18 · 국소 천장에 닿으면 yaw 읽기가 나타나나** — %u 씨앗 × %u스텝\n",
			kRuns, kTrainSteps);
		LogA("[mlt] ⏳   프로브 {600, 1200, 2400} 에서 **R(x) 와 x표적의 yaw 질량**을 함께 찍는다\n");
		LogA("[mlt] ⏳   갈래: ㈀ 천장 넘고 질량 ≥%.0f%% = 압력이 기제를 만든다 · ㈁ 천장서 멈추고"
		     " 평평 = 저절로 안 생긴다 · ㈂ 넘는데 ~1%% = 제3 의 경로\n", (double)(kMassUp * 100.0f));
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

	static void _StartEval()
	{
		_eb = 0u; _sumP = 0.0f;
		for (uint32 a = 0; a < MLTPX::kAxes; ++a) { _hit[a] = 0u; _cnt[a] = 0u; }
		_st = kEvalUp;
	}

	// 값 슬롯 = x·z·yaw(회차 17 과 같은 배치). `tgtAxis` = kAll 또는 축 하나(진단).
	static void _Batch(uint32 seed, uint32 epi0, uint32 tgtAxis, Array<float>& val, Array<float>& tgt)
	{
		typedef MLTModelCfg M;
		val.Reset(0); tgt.Reset(0);
		// ⚠️ MLTPX 의 에피소드 기록기를 그대로 쓰고 싶지만 private 다 — 세계를 직접 굴린다(같은 식).
		float x[MLTPX::kTime + 1u], z[MLTPX::kTime + 1u], yw[MLTPX::kTime + 1u];
		for (uint32 b = 0; b < M::kBatch; ++b)
		{
			MLTWorld w;
			w.Reset(seed, epi0 + b, kHold, 0);
			x[0] = w.State().x; z[0] = w.State().z; yw[0] = w.State().yaw;
			for (uint32 t = 0; t < MLTPX::kTime; ++t)
			{
				w.Step();
				x[t + 1u] = w.State().x; z[t + 1u] = w.State().z; yw[t + 1u] = w.State().yaw;
			}
			const float* vs[MLTPX::kAxes] = { x, z, yw };
			for (uint32 t = 0; t < MLTPX::kTime; ++t)
				for (uint32 a = 0; a < MLTPX::kAxes; ++a)
				{
					val.Add(vs[a][t]);
					const bool on = (tgtAxis == kAll) || (a == tgtAxis);
					tgt.Add(on ? (float)MLTP0::Bucket(vs[a][t + 1u]) : M::kIgnoreTgt);
				}
		}
	}

	static void _Finish()
	{
		for (uint32 p = 0; p < kProbes; ++p)
		{
			for (uint32 a = 0; a < MLTPX::kAxes; ++a) _rR[_run][p][a] = _pR[p][a];
			_rYaw[_run][p] = _pYaw[p];
		}
		_rBlindR[_run] = _BlindR();
		_rOk[_run] = _finite;
		++_run;
		_st = kInit;
		if (_run >= kRuns) _Judge();
	}

	static void _Judge()
	{
		float rX[kProbes] = { 0.0f }, yw[kProbes] = { 0.0f };
		float blind = 0.0f;
		uint32 sign = 0u;
		bool plumb = true;
		for (uint32 i = 0; i < kRuns; ++i)
		{
			if (!_rOk[i]) plumb = false;
			for (uint32 p = 0; p < kProbes; ++p) { rX[p] += _rR[i][p][0]; yw[p] += _rYaw[i][p]; }
			blind += _rBlindR[i];
			if (_rYaw[i][kProbes - 1u] > _rYaw[i][0]) ++sign;   // yaw질량(2400) > yaw질량(600)
		}
		const float k = 1.0f / (float)kRuns;
		for (uint32 p = 0; p < kProbes; ++p) { rX[p] *= k; yw[p] *= k; }
		blind *= k;

		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] ⏳ **회차 18 결과 — 천장 접근과 yaw 읽기**\n");
		LogA("[mlt] ⏳   R̄(x)      : 600→**%.3f**  1200→**%.3f**  2400→**%.3f**"
		     "   (국소 천장 R̄_blind = **%.3f**)\n",
			(double)rX[0], (double)rX[1], (double)rX[2], (double)blind);
		LogA("[mlt] ⏳   yaw 질량  : 600→**%.1f%%**  1200→**%.1f%%**  2400→**%.1f%%**"
		     "   · 부호검정(2400>600) **%u/12**\n",
			(double)(yw[0] * 100.0f), (double)(yw[1] * 100.0f), (double)(yw[2] * 100.0f), sign);
		if (!plumb) LogA("[mlt] ⏳   ⛔ 배관이 깨진 실행이 있다 — **판정불가**\n");
		else        LogA("[mlt] ⏳   ✅ 배관 — 전 구간 유한\n");

		const bool crossed = (rX[kProbes - 1u] > blind);
		const bool massUp = (yw[kProbes - 1u] >= kMassUp) && (sign >= kSignNeed);
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		if (!plumb)
			LogA("[mlt] ⏳ ⛔ 판정불가\n");
		else if (crossed && massUp)
			LogA("[mlt] ⏳ ⇒ ✅✅ **㈀ 압력이 기제를 만든다** — 천장(%.3f)을 넘으며 yaw 질량이 올랐다."
			     " 회차 17 의 비대각 가설이 「늦게」 맞았다\n", (double)blind);
		else if (!crossed && !massUp)
			LogA("[mlt] ⏳ ⇒ ⚠️⚠️ **㈁ 천장 근처에서 멈추고 질량이 평평하다** — ***국소 전략이 남아"
			     " 있는 동안 교차 축 읽기가 안 생기고, 천장에 닿아도 저절로 안 생길 수 있다.***"
			     " 이 기계(SGD+어텐션)의 성질에 대한 발견이다\n");
		else if (crossed && !massUp)
			LogA("[mlt] ⏳ ⇒ ⚠️ **㈂ 모순 — 천장(%.3f)을 넘는데 yaw 질량이 안 올랐다(제3 의 경로).**"
			     " 진단을 다시 설계한다(x 의 긴 역사에서 간접 복원 의심)\n", (double)blind);
		else
			LogA("[mlt] ⏳ ⇒ ⚠️ 질량은 오르는데 천장을 못 넘었다 — **진행 중**으로 적는다"
			     "(더 긴 훈련이 다음 손잡이다)\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}
};
