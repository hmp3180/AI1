// mltp1w.cw — 📏 **회차 10 · 「폭을 먼저 재라」.** ⚠️⚠️ **이 회차는 아무것도 만들지 않는다.**
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문** — ⚠️ 재기 전에 적는다. 정본은 `mltlog_1.md` 회차 9 의 「회차 10 등록」이다.
// ══════════════════════════════════════════════════════════════════════════════
//
// ★ **왜 이 회차인가**
//
//   회차 9 가 **낙폭 −0.543**(부호검정 12/12)을 냈다 — 덮음이 **크다**. 그리고 등록문이 그
//   갈래에 대해 *"write-side 손잡이의 **폭 재기**로 간다"* 고 적어 뒀고, 동시에
//   ⚠️ *"「희소 갱신을 만들자」로 **바로 가지 마라**"* 고 못 박았다.
//
//   `mltconcept.md` 의 근거가 그것이다:
//   > **적응의 값은 고정값들의 폭이 상한이다.** 폭이 작으면 적응형은 **잡음만 더한다.**
//   > ⇒ 바꾸려는 대상을 **여러 상수로 고정해** 결과의 폭을 먼저 재고, 폭이 문턱을 못 넘는
//   > 목적지는 **그 라운드에서 삭제한다.**
//
//   ⇒ ***낙폭이 무엇의 함수인가***를 **고정 상수**로 스윕한다. **한 번에 하나만** 흔든다.
//
// ══════════════════════════════════════════════════════════════════════════════
// ① 손잡이 둘 × 4점 — ⚠️ 기준선은 **공유**한다
// ══════════════════════════════════════════════════════════════════════════════
//   ```
//   ㈀ B 단계의 학습률 배율   1 · 1/2 · 1/4 · 1/8
//   ㈁ 리허설 비율            0 · 1/8 · 1/4 · 1/2   (B 단계 배치에 **A 표적을 섞는 몫**)
//   기준선 = (lr×1, 리허설 0) 이고 **두 손잡이가 공유**한다 ⇒ 팔 **7개**
//   ```
//   ⭐ **㈀ 가 등록문의 `lr/N` 대조군이다** — 형제 트랙의 실측이 «주소 +21.7%p ↔ `lr/N`
//     +0.8%p» 였다. ⇒ **낙폭이 lr 로 줄면 그것은 「주소」가 아니라 「유효 학습률」**이고,
//     그때는 **주소를 만들 근거가 없다.**
//   ⚠️ ㈁ 도 **고정 상수**다(기제를 만드는 것이 아니다) — 「A 를 다시 보여주면 덮음이 줄나」만 묻는다.
//     ★ 그리고 그것이 줄인다면 다음 물음은 *"어떻게 **학습 자체**가 그 재방문을 만들게 할까"* 이고,
//       ⚠️ **semantic 슬롯을 손으로 만드는 것이 아니다**(`mltconcept.md` 의 그 못).
//   ⚠️ **리허설은 「같은 비용」을 깬다** — B 단계의 표적 중 일부가 A 가 되므로 B 를 배우는 걸음이
//     줄어든다. ⇒ 그래서 **`R_B(B 뒤)` 를 낙폭과 같은 줄에 적는다**(아래 읽는 칸).
//
// ══════════════════════════════════════════════════════════════════════════════
// ② 읽는 칸과 문턱
// ══════════════════════════════════════════════════════════════════════════════
//   · 표제 = **낙폭** `= R_A(B 뒤) − R_A(A 뒤)` (회차 9 와 **같은 정의** ⇒ 바로 견줄 수 있다)
//   · ⚠️⚠️ **같은 줄에 `R_B(B 뒤)`** — **낙폭이 줄어도 B 를 못 배우면 소용없다.**
//     ★ 그 둘을 갈라 보지 않으면 *"학습을 껐더니 덮음이 사라졌다"* 를 성과로 읽는다(자명한 함정).
//   · 손잡이의 **폭** = `max(낙폭) − min(낙폭)` (그 손잡이의 4점에서)
//   **문턱**: **폭 < 0.10**(≈6·SE · SE(낙폭)≈0.017) ⇒ ***그 목적지를 이 라운드에서 삭제한다.***
//   **부호검정**은 **양 끝점의 짝 차이**(`낙폭(끝) − 낙폭(기준)`)의 부호에 건다 ⇒ **10/12**.
//   ⚠️ 봉우리를 고른 지표(폭)와 검정을 건 지표(양 끝점 차)가 **같은 축**이다.
//
//   ⚠️⚠️ **미리 적는 해석 분기 넷**
//     · ㈀ 만 크다 ⇒ 덮음은 **유효 학습률**의 얼굴이다 ⇒ **「주소」를 만들 근거가 없다.**
//     · ㈁ 만 크다 ⇒ 덮음은 **무엇을 다시 보는가**의 함수다 ⇒ 다음 물음은
//       *"어떻게 학습 자체가 그 재방문을 만들게 할까"*.
//     · 둘 다 크다 ⇒ **반드시 쌍 대조군**으로 가른다(같은 유효 학습률에서 리허설만 다르게).
//     · 둘 다 작다 ⇒ 덮음은 이 손잡이들의 함수가 아니다 ⇒ **둘 다 삭제**하고 다른 자리를 찾는다.
//
// ⚠️ 비용: 실행당 `A300 + B300 = 600` 스텝 · 7팔 × 12씨앗 = **84 실행 ≈ 6분**(렌더CPU 7.4ms).

using namespace PE;

class MLTP1W
{
public:
	static bool Done() { return _run >= kRuns; }

	static void Tick(RHI* rhi)
	{
		if (_run >= kRuns || rhi == nullptr) return;
		if (MLTModelCfg::kAxes != MLTP1::kAxes || MLTModelCfg::kTime != MLTP1::kTime)
		{ LogA("[mlt] 📏 ⛔⛔ 축/시각 전제가 다르다\n"); _run = kRuns; return; }
		// ⚠️ **기본에서 껐다** — 회차 10 으로 쟀다. ★ 다시 돌리려면 `-mltwidth`.
		if (!OS::CommandLine::Has("-mltwidth"))
		{
			LogA("[mlt] 📏 회차 10(폭 재기)은 **꺼져 있다**(`-mltwidth`) — 기록: lr 폭 **0.281**"
			     " · 리허설 폭 **0.674** · 둘 다 12/12\n");
			_run = kRuns;
			return;
		}
		if (!_banner) { _Banner(); _banner = true; }

		if (_st == kInit)
		{
			if (!_M.Setup(rhi)) { LogA("[mlt] 📏 준비 실패(run %u)\n", _run); _run = kRuns; return; }
			for (uint32 a = 0; a < MLTP1::kAxes; ++a)
				MLTP1::_Baseline(a, kHold, _Seed(_run), 1u, kEvalEpi0, kEvalEpis, _bC[a], _bB[a]);
			_ph = 0u; _step = 0u; _finite = true;
			_st = kTrain;
			return;
		}

		if (_st == kTrain)
		{
			if (_step > 0u)
			{
				float ls = 0.0f;
				if (!_M.ReadLoss(ls)) { LogA("[mlt] 📏 손실 리드백 실패\n"); _run = kRuns; return; }
				if (!(ls == ls) || ls > 1.0e30f) _finite = false;
			}
			if (_ph >= 2u) { _Finish(); return; }
			if (_step >= kSteps) { _StartEval(); return; }

			const uint32 K = MLTModelCfg::kPool;
			const uint32 slot = _step % K;
			if (slot == 0u)
			{
				const uint32 n = ((kSteps - _step) < K) ? (kSteps - _step) : K;
				_pv.Reset(0); _pt.Reset(0);
				for (uint32 k = 0; k < n; ++k)
				{
					Array<float> v, g;
					_Batch(_Seed(_run), 1000u + _ph * 20000u + (_step + k) * MLTModelCfg::kBatch,
						_step + k, v, g);
					for (uint32 i = 0; i < v.Count(); ++i) _pv.Add(v[i]);
					for (uint32 i = 0; i < g.Count(); ++i) _pt.Add(g[i]);
				}
				if (!_M.UploadPool(_pv, _pt, n)) { LogA("[mlt] 📏 풀 업로드 실패\n"); _run = kRuns; return; }
			}
			_M.SelectStep(slot);
			// ⭐ 손잡이 ㈀ — **B 단계에서만** 학습률 배율을 건다(A 단계는 언제나 ×1).
			const float lrMul = (_ph == 1u) ? _LrMul(_run) : 1.0f;
			if (!_M.Forward() || !_M.Backward() || !_M.AdamStep(lrMul))
			{ LogA("[mlt] 📏 스텝 실패(ph %u · step %u)\n", _ph, _step); _run = kRuns; return; }
			++_step;
			return;
		}

		if (_st == kEvalUp)
		{
			if (_eb >= kEvalB) { _EvalDone(); return; }
			_Batch(_Seed(_run), kEvalEpi0 + _eb * MLTModelCfg::kBatch, kEvalAll, _ev, _et);
			if (!_M.Upload(_ev, _et)) { LogA("[mlt] 📏 시험 업로드 실패\n"); _run = kRuns; return; }
			if (!_M.Forward()) { LogA("[mlt] 📏 시험 forward 실패\n"); _run = kRuns; return; }
			_st = kEvalRd;
			return;
		}

		// kEvalRd
		{
			Array<float> m;
			float sp = 0.0f;
			for (uint32 a = 0; a < MLTP1::kAxes; ++a)
			{
				m.Reset(0);
				for (uint32 r = 0; r < MLTModelCfg::kRows; ++r)
					m.Add((((r % MLTModelCfg::kCtx) % MLTP1::kAxes) == a) ? 1.0f : 0.0f);
				uint32 h = 0u, n = 0u, hb = 0u, nb = 0u;
				float dd = 0.0f, ddb = 0.0f, ddo = 0.0f;
				if (!_M.ReadHits(_et, m, h, n, hb, nb, sp, dd, ddb, ddo))
				{ LogA("[mlt] 📏 리드백 실패\n"); _run = kRuns; return; }
				_hit[a] += hb; _cnt[a] += nb;
			}
			_sumP += sp;
			++_eb;
			_st = kEvalUp;
		}
	}

private:
	static constexpr uint32 kSeed0 = 12u, kSeeds = 12u;
	static constexpr uint32 kArms = 7u;                  // 기준선 + lr 3점 + 리허설 3점
	static constexpr uint32 kRuns = kArms * kSeeds;      // 84
	static constexpr int    kHold = MLTWorldCfg::kHoldMid;
	static constexpr uint32 kSteps = 300u;
	static constexpr uint32 kEvalEpi0 = 0u, kEvalB = 4u;
	static constexpr uint32 kEvalEpis = kEvalB * MLTModelCfg::kBatch;
	static constexpr uint32 kEvalAll = 0xFFFFFFFFu;
	static constexpr float  kWidthMin = 0.10f;           // ② 의 그 문턱(≈6·SE)
	static constexpr uint32 kSignNeed = 10u;

	// 팔 배치 — ⚠️ **번호를 역할에 고정**한다
	//   0 = 기준선(lr×1 · 리허설 0) · 1~3 = lr ×1/2, ×1/4, ×1/8 · 4~6 = 리허설 1/8, 1/4, 1/2
	static uint32 _Arm(uint32 r) { return r / kSeeds; }
	static uint32 _Seed(uint32 r) { return kSeed0 + (r % kSeeds); }
	static float  _LrMul(uint32 r)
	{
		const uint32 a = _Arm(r);
		if (a == 1u) return 0.5f;
		if (a == 2u) return 0.25f;
		if (a == 3u) return 0.125f;
		return 1.0f;
	}
	// 리허설 비율의 **분모** — `스텝 % d == 0` 인 스텝의 표적을 A 로 준다.
	//   ⚠️ 「배치 안에서 섞기」가 아니라 **스텝 단위**로 준다: 한 배치의 표적 축을 섞으면
	//     그것은 「두 과제를 동시에」이고 리허설이 아니다(순서가 사라진다).
	static uint32 _RehearsalDenom(uint32 r)
	{
		const uint32 a = _Arm(r);
		if (a == 4u) return 8u;    // 1/8
		if (a == 5u) return 4u;    // 1/4
		if (a == 6u) return 2u;    // 1/2
		return 0u;                 // 없음
	}
	static const char* _ArmName(uint32 r)
	{
		switch (_Arm(r))
		{
			case 0: return "기준(lr×1·리허0)";
			case 1: return "lr×1/2         ";
			case 2: return "lr×1/4         ";
			case 3: return "lr×1/8         ";
			case 4: return "리허설 1/8     ";
			case 5: return "리허설 1/4     ";
			default: return "리허설 1/2     ";
		}
	}

	enum { kInit = 0, kTrain, kEvalUp, kEvalRd };

	inline static MLTModel _M;
	inline static bool _banner = false;
	inline static uint32 _run = 0u, _ph = 0u, _step = 0u, _eb = 0u;
	inline static int _st = kInit;
	inline static bool _finite = true;
	inline static float _sumP = 0.0f;
	inline static uint32 _hit[MLTP1::kAxes] = { 0u }, _cnt[MLTP1::kAxes] = { 0u };
	inline static MLTP1::Base _bC[MLTP1::kAxes], _bB[MLTP1::kAxes];
	inline static float _phR[2][MLTP1::kAxes] = { { 0.0f } };
	inline static Array<float> _ev, _et, _pv, _pt;

	inline static float _rA0[kRuns] = { 0.0f }, _rA1[kRuns] = { 0.0f }, _rB1[kRuns] = { 0.0f };
	inline static bool  _rOk[kRuns] = { false };

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 📏 **회차 10 · 폭 재기** — 낙폭이 무엇의 함수인가 · 씨앗 %u~%u · %u 실행\n",
			kSeed0, kSeed0 + kSeeds - 1u, kRuns);
		LogA("[mlt] 📏   손잡이 ㈀ B단계 lr 배율 `1·1/2·1/4·1/8` (= **`lr/N` 대조군**)"
		     " · ㈁ 리허설 `0·1/8·1/4·1/2`\n");
		LogA("[mlt] 📏   문턱: 손잡이의 **폭 < %.2f** 면 **그 목적지를 삭제한다** · 부호검정 %u/12\n",
			(double)kWidthMin, kSignNeed);
		LogA("[mlt] 📏   ⚠️⚠️ **이 회차는 아무것도 만들지 않는다 — 폭만 잰다**"
		     "(「희소 갱신을 만들자」로 바로 가지 마라)\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

	static void _StartEval()
	{
		_eb = 0u; _sumP = 0.0f;
		for (uint32 a = 0; a < MLTP1::kAxes; ++a) { _hit[a] = 0u; _cnt[a] = 0u; }
		_st = kEvalUp;
	}

	static void _EvalDone()
	{
		for (uint32 a = 0; a < MLTP1::kAxes; ++a)
		{
			const float acc = _cnt[a] ? (float)_hit[a] / (float)_cnt[a] : 0.0f;
			const float w = _bB[a].acc - _bC[a].acc;
			_phR[_ph][a] = (w > 1.0e-4f) ? (acc - _bC[a].acc) / w : 0.0f;
		}
		++_ph;
		_step = 0u;
		_st = kTrain;
	}

	// 표적 축: A 단계면 y · B 단계면 yaw(⭐ 단, **리허설 스텝은 y**) · 시험이면 전부
	static void _Batch(uint32 seed, uint32 epi0, uint32 stepNo, Array<float>& val, Array<float>& tgt)
	{
		typedef MLTModelCfg M;
		const uint32 A = MLTP1::kAxes, T = MLTP1::kTime;
		uint32 tgtAxis;
		// ⚠️ 시험은 **`stepNo == kEvalAll`** 로 표시된다(`epi0` 가 아니다 — 쓰면서 한 번 틀렸다).
		if (stepNo == kEvalAll) tgtAxis = kEvalAll;
		else if (_ph == 0u)   tgtAxis = 0u;
		else
		{
			const uint32 d = _RehearsalDenom(_run);
			tgtAxis = (d != 0u && (stepNo % d) == 0u) ? 0u : 1u;   // ⭐ 리허설 스텝은 A(y)
		}
		val.Reset(0); tgt.Reset(0);
		float v[MLTP1::kAxes][MLTP1::kTime + 1u];
		for (uint32 b = 0; b < M::kBatch; ++b)
		{
			for (uint32 a = 0; a < A; ++a) MLTP1::_Episode(a, seed, epi0 + b, kHold, v[a], nullptr);
			for (uint32 t = 0; t < T; ++t)
				for (uint32 a = 0; a < A; ++a)
				{
					val.Add(v[a][t]);
					const bool on = (tgtAxis == kEvalAll) || (a == tgtAxis);
					tgt.Add(on ? (float)MLTP0::Bucket(v[a][t + 1u]) : M::kIgnoreTgt);
				}
		}
	}

	static void _Finish()
	{
		const float sp = (_eb > 0u) ? _sumP / (float)_eb : 0.0f;
		_rA0[_run] = _phR[0][0]; _rA1[_run] = _phR[1][0]; _rB1[_run] = _phR[1][1];
		_rOk[_run] = _finite && (Abs(sp - 1.0f) <= 0.01f);
		if ((_run % kSeeds) == kSeeds - 1u)
			LogA("[mlt] 📏 [%2u/%u] %s 마지막 씨앗 · R_A %.3f→%.3f (낙폭 %+.3f) · R_B %.3f%s\n",
				_run + 1u, kRuns, _ArmName(_run), (double)_rA0[_run], (double)_rA1[_run],
				(double)(_rA1[_run] - _rA0[_run]), (double)_rB1[_run], _rOk[_run] ? "" : "  ⛔배관");
		++_run;
		_st = kInit;
		if (_run >= kRuns) _Judge();
	}

	static void _Judge()
	{
		float drop[kArms] = { 0.0f }, rb[kArms] = { 0.0f };
		bool plumb = true;
		for (uint32 m = 0; m < kArms; ++m)
		{
			float d = 0.0f, b = 0.0f;
			for (uint32 i = 0; i < kSeeds; ++i)
			{
				const uint32 r = m * kSeeds + i;
				d += (_rA1[r] - _rA0[r]); b += _rB1[r];
				if (!_rOk[r]) plumb = false;
			}
			drop[m] = d / (float)kSeeds; rb[m] = b / (float)kSeeds;
		}

		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 📏 **회차 10 결과 — 낙폭의 폭**\n");
		for (uint32 m = 0; m < kArms; ++m)
			LogA("[mlt] 📏   %s · 낙폭 **%+.3f** · R_B(B 뒤) %.3f\n",
				_ArmName(m * kSeeds), (double)drop[m], (double)rb[m]);

		if (!plumb) LogA("[mlt] 📏   ⛔ 배관이 깨진 실행이 있다 — **판정불가**\n");
		else        LogA("[mlt] 📏   ✅ 배관 — probs 합 1.0 · 전 구간 유한\n");

		// ㈀ lr — 팔 0(기준) + 1·2·3
		float lo = drop[0], hi = drop[0];
		for (uint32 m = 1; m <= 3u; ++m) { if (drop[m] < lo) lo = drop[m]; if (drop[m] > hi) hi = drop[m]; }
		const float wLr = hi - lo;
		uint32 sLr = 0u;
		for (uint32 i = 0; i < kSeeds; ++i)
			if ((_rA1[3u * kSeeds + i] - _rA0[3u * kSeeds + i]) > (_rA1[i] - _rA0[i])) ++sLr;

		// ㈁ 리허설 — 팔 0(기준) + 4·5·6
		lo = drop[0]; hi = drop[0];
		for (uint32 m = 4u; m <= 6u; ++m) { if (drop[m] < lo) lo = drop[m]; if (drop[m] > hi) hi = drop[m]; }
		const float wRe = hi - lo;
		uint32 sRe = 0u;
		for (uint32 i = 0; i < kSeeds; ++i)
			if ((_rA1[6u * kSeeds + i] - _rA0[6u * kSeeds + i]) > (_rA1[i] - _rA0[i])) ++sRe;

		LogA("[mlt] 📏   ── 폭 ──\n");
		LogA("[mlt] 📏   ㈀ **lr 배율의 폭 %.3f** (문턱 %.2f) · 끝점 부호검정 **%u/12**"
		     " · 끝점 낙폭 %+.3f ↔ 기준 %+.3f\n",
			(double)wLr, (double)kWidthMin, sLr, (double)drop[3], (double)drop[0]);
		LogA("[mlt] 📏   ㈁ **리허설의 폭 %.3f** (문턱 %.2f) · 끝점 부호검정 **%u/12**"
		     " · 끝점 낙폭 %+.3f ↔ 기준 %+.3f\n",
			(double)wRe, (double)kWidthMin, sRe, (double)drop[6], (double)drop[0]);

		const bool bigLr = (wLr >= kWidthMin) && (sLr >= kSignNeed);
		const bool bigRe = (wRe >= kWidthMin) && (sRe >= kSignNeed);

		// ⚠️ **해석 분기를 미리 등록해 뒀다** — 여기서 정하지 않는다.
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		if (!plumb)
			LogA("[mlt] 📏 ⛔ 판정불가\n");
		else if (bigLr && !bigRe)
			LogA("[mlt] 📏 ⇒ **㈀ 만 크다: 덮음은 「유효 학습률」의 얼굴이다.**"
			     " ⚠️ **「주소」를 만들 근거가 없다** ⇒ 리허설 목적지를 **삭제**한다\n");
		else if (!bigLr && bigRe)
			LogA("[mlt] 📏 ⇒ **㈁ 만 크다: 덮음은 「무엇을 다시 보는가」의 함수다.** 다음 물음은"
			     " *\"어떻게 **학습 자체**가 그 재방문을 만들게 할까\"* ⇒ lr 목적지를 **삭제**한다\n");
		else if (bigLr && bigRe)
			LogA("[mlt] 📏 ⇒ **둘 다 크다** ⇒ ⚠️ **반드시 쌍 대조군으로 가른다**"
			     "(같은 유효 학습률에서 리허설만 다르게) — 그것을 다음 회차로 등록하라\n");
		else
			LogA("[mlt] 📏 ⇒ **둘 다 작다: 덮음은 이 손잡이들의 함수가 아니다** ⇒ **둘 다 삭제**하고"
			     " 다른 자리를 찾는다\n");
		LogA("[mlt] 📏   ⚠️ 그리고 **`R_B(B 뒤)` 를 같이 읽어라** — 낙폭이 줄어도 **B 를 못 배우면"
		     " 소용없다**(위 표의 그 칸)\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}
};
