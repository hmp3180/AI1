// mltp1band.cw — 🌉 **P1 회차 8 · 「규칙이 축을 건너나」** (P0 에서 이월된 ⑫ 보간의 날카로운 판)
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문** — ⚠️ 재기 전에 적는다
// ══════════════════════════════════════════════════════════════════════════════
//
// ★ **무엇을 묻나**
//
//   P0 은 «규칙이 아니라 **구간 표**가 섰다» 로 닫혔다(회차 4·5): 물어본 적 없는 값 구간에서
//   거의 무작위였고, `kFreqMax` 를 낮춰 18배 좋아졌지만 **여전히 복사를 못 넘었다.**
//   ⇒ 그때 남은 물음: ***"인코딩이 아니라 구조가 규칙을 강제할 수 있나?"***
//
//   P1 등록문의 가설 ㈁ 이 그것이었다: *"축이 셋이면 같은 규칙이 세 축에 걸쳐 쓰이므로 규칙 쪽이
//   강제될 수 있다."* ⇒ 이 회차가 그것을 **직접** 가른다.
//
//   ⭐ **설계의 핵 — 밴드를 축마다 다르게 건다**
//   ```
//   팔 A(건널 수 있다)  밴드 홀드아웃을 **yaw·pitch 에만** 건다 · **y 는 안 건다**
//                       ⇒ `y` 는 그 구간을 **물어봤고** yaw/pitch 는 **안 물어봤다**
//                       ⇒ 규칙이 축을 건너면 yaw/pitch 가 **그 구간에서도** 돼야 한다
//   팔 B(건널 데가 없다) 밴드 홀드아웃을 **세 축 다** 건다  ← **대조군**
//                       ⇒ 어느 축도 그 구간을 안 물어봤다 ⇒ 건널 것이 없다
//   ```
//   ★ 이것이 `mltconcept.md` 의 성공 조건 *"**한 채널에서 배운 낱말이 다른 채널에서도 같은
//     역할**을 한다"* 와 **같은 형식**이다 — 그쪽은 언어에 대해, 이쪽은 값에 대해 묻는다.
//   ⚠️⚠️ 그리고 **P0 의 관문 형식 문제를 둘 다 피한다**: 홀드아웃을 **현재값**에 걸고(클래스
//     억압이 없다) 지표를 **버킷 거리**로 둔다(이진 임계를 연속량으로).
//
//   **설계**: 팔 A · B × **판정 씨앗 12~23** = **24 실행**(≈6분 · 풀 업로드 뒤라 값싸다)
//     · 그 밖의 모든 것은 회차 7 과 **같다**(축 셋 · 중간 hold=5 · 600스텝 · 시험 에피소드 0~31)
//     · 밴드 = `[0.30, 0.50)` (P0 과 같은 구간 — ⚠️ 바꾸면 회차 4·5 와 못 견준다)
//
//   **읽는 칸**(⚠️ 봉우리를 고른 지표와 검정을 건 지표를 같은 줄에)
//     · 표제 = **`D̄_band(yaw)` 와 `D̄_band(pitch)`** — 팔 A ↔ 팔 B
//       (`D = (복사거리 − 학습거리) / (복사거리 − 베이즈거리)` · 바닥 0 · 천장 1)
//     · 같이 읽는 것 = `D̄_out`(밴드 밖) · `D̄_band(y)` · 정확도
//     · 부호검정은 **`D_band(yaw|A) − D_band(yaw|B)` 의 부호**에 건다 ⇒ **10/12**
//       ★ `pitch` 도 같이 재지만 **검정은 `yaw` 에 건다**(⚠️ 둘 다에 걸면 다중비교가 는다).
//         근거로 `yaw` 를 고른 이유: `|Δ|` 가 가장 커서 **창이 가장 넓다**(회차 6: 60.7%p).
//
//   **관문**
//     ㉠ ★ **`D̄_band(yaw|A) > D̄_band(yaw|B)`** 그리고 부호검정 **≥ 10/12**
//        ⇒ 「규칙이 축을 건넜다」
//     ㉡ **절대값** — `D̄_band(yaw|A) ≥ 0.10` (P0 의 ⑫ 문턱 그대로) ⇒ 「보간이 됐다」
//        ⚠️ ㉠ 이 통과하고 ㉡ 이 깨지면 그것은 **「조금 건넜지만 못 넘었다」**이고, 그렇게 적는다.
//     ㉢ **배관** — 두 팔 다 `D̄_out > 0`(밴드 **밖**에서는 복사보다 좋다). 아니면 판정불가.
//     ㉣ **배관** — `probs` 행 합 1.0 ± 0.01 · 전 구간 유한
//     ㉤ ⚠️ **`y` 의 밴드가 팔 A 에서 팔 B 보다 좋아야 한다** — 팔 A 에서 `y` 는 그 구간을
//        물어봤으니 **당연히** 좋아야 하고, 안 그러면 **홀드아웃 배선이 틀린 것**이다(위생 검사).
//
//   ⚠️ **미리 적는 해석 분기**
//     · ㉠ ✅ ㉡ ✅ ⇒ **구조가 규칙을 강제했다.** P0 의 「구간 표」는 **축이 하나여서** 였다.
//     · ㉠ ✅ ㉡ ⛔ ⇒ **건너기는 실재하지만 부족하다.** 다음은 **축 수**를 손잡이로(3 → 5).
//     · ㉠ ⛔ ⇒ **축을 늘려도 규칙이 안 선다.** 그러면 다음 물음은 인코딩도 축도 아니라
//       **손실**이다(다음 스텝만으로는 규칙을 요구하지 않는다) ⇒ 그것을 그 라운드의 결과로 적는다.
//   ★ 이 세 갈래를 **미리** 적어 두는 것이 「이 결과면 안 한다」를 갖는 것이다.

using namespace PE;

class MLTP1Band
{
public:
	static bool Done() { return _run >= kRuns; }

	static void Tick(RHI* rhi)
	{
		if (_run >= kRuns || rhi == nullptr) return;
		if (MLTModelCfg::kAxes != MLTP1::kAxes || MLTModelCfg::kTime != MLTP1::kTime)
		{
			LogA("[mlt] 🌉 ⛔⛔ **회차 8 은 축 %u · 시각 %u 를 전제한다** — 지금은 축 %u · 시각 %u\n",
				MLTP1::kAxes, MLTP1::kTime, MLTModelCfg::kAxes, MLTModelCfg::kTime);
			_run = kRuns; return;
		}
		// ⚠️ **기본에서 껐다** — 회차 8 로 통과했다. ★ 다시 돌리려면 `-mltband`.
		if (!OS::CommandLine::Has("-mltband"))
		{
			LogA("[mlt] 🌉 회차 8(규칙이 축을 건너나)은 **꺼져 있다**(`-mltband`) — 통과 기록:"
			     " yaw 밴드 A **0.684** ↔ B **0.021** · 부호검정 12/12\n");
			_run = kRuns;
			return;
		}
		if (!_banner) { _Banner(); _banner = true; }

		if (_st == kInit)
		{
			if (!_M.Setup(rhi)) { LogA("[mlt] 🌉 준비 실패(run %u)\n", _run); _run = kRuns; return; }
			for (uint32 a = 0; a < MLTP1::kAxes; ++a) _Baseline(_Seed(_run), a, _bC[a], _bB[a]);
			_step = 0u; _eb = 0u; _finite = true; _sumP = 0.0f;
			for (uint32 a = 0; a < MLTP1::kAxes; ++a)
			{ _dB[a] = 0.0f; _dO[a] = 0.0f; _hit[a] = 0u; _cnt[a] = 0u; }
			_st = kTrain;
			return;
		}

		if (_st == kTrain)
		{
			if (_step > 0u)
			{
				float ls = 0.0f;
				if (!_M.ReadLoss(ls)) { LogA("[mlt] 🌉 손실 리드백 실패\n"); _run = kRuns; return; }
				if (!(ls == ls) || ls > 1.0e30f) _finite = false;
				if (_step == 1u) _first = ls;
				_last = ls;
			}
			if (_step >= kTrainSteps) { _eb = 0u; _st = kEvalUp; return; }

			// ⏱️ 풀 경계에서만 업로드한다(회차 7 의 그 40배).
			const uint32 K = MLTModelCfg::kPool;
			const uint32 slot = _step % K;
			if (slot == 0u)
			{
				const uint32 n = ((kTrainSteps - _step) < K) ? (kTrainSteps - _step) : K;
				_pv.Reset(0); _pt.Reset(0);
				for (uint32 k = 0; k < n; ++k)
				{
					Array<float> v, g;
					_Batch(_Seed(_run), kTrainEpi0 + (_step + k) * MLTModelCfg::kBatch, true, v, g, nullptr);
					for (uint32 i = 0; i < v.Count(); ++i) _pv.Add(v[i]);
					for (uint32 i = 0; i < g.Count(); ++i) _pt.Add(g[i]);
				}
				if (!_M.UploadPool(_pv, _pt, n)) { LogA("[mlt] 🌉 풀 업로드 실패\n"); _run = kRuns; return; }
			}
			_M.SelectStep(slot);
			if (!_M.Forward() || !_M.Backward() || !_M.AdamStep())
			{ LogA("[mlt] 🌉 스텝 실패(%u)\n", _step); _run = kRuns; return; }
			++_step;
			if ((_step % 300u) == 0u)
				LogA("[mlt] 🌉      ⏱️ step %3u · 렌더CPU %.1fms · GPU %.1fms\n",
					_step, (double)FrameStats::renderCpuMs, (double)FrameStats::gpuMs);
			return;
		}

		if (_st == kEvalUp)
		{
			if (_eb >= kEvalB) { _Finish(); return; }
			// ⚠️ 시험은 **홀드아웃을 안 건다**(그 구간이 바로 물음이다).
			_Batch(_Seed(_run), kEvalEpi0 + _eb * MLTModelCfg::kBatch, false, _ev, _et, &_eBand);
			if (!_M.Upload(_ev, _et)) { LogA("[mlt] 🌉 시험 업로드 실패\n"); _run = kRuns; return; }
			if (!_M.Forward()) { LogA("[mlt] 🌉 시험 forward 실패\n"); _run = kRuns; return; }
			_st = kEvalRd;
			return;
		}

		// kEvalRd — 축마다 「밴드 안/밖」을 갈라 읽는다
		{
			Array<float> m;
			for (uint32 a = 0; a < MLTP1::kAxes; ++a)
			{
				// 밴드 **안** & 그 축
				m.Reset(0);
				for (uint32 r = 0; r < MLTModelCfg::kRows; ++r)
					m.Add((_Axis(r) == a && _eBand[r] != 0.0f) ? 1.0f : 0.0f);
				uint32 h = 0u, n = 0u, hb = 0u, nb = 0u;
				float sp = 0.0f, dd = 0.0f, ddb = 0.0f, ddo = 0.0f;
				if (!_M.ReadHits(_et, m, h, n, hb, nb, sp, dd, ddb, ddo))
				{ LogA("[mlt] 🌉 리드백 실패\n"); _run = kRuns; return; }
				_dB[a] += ddb; _hit[a] += hb; _cnt[a] += nb;
				if (a == 0u) _sumP += sp;
				// 밴드 **밖** & 그 축
				m.Reset(0);
				for (uint32 r = 0; r < MLTModelCfg::kRows; ++r)
					m.Add((_Axis(r) == a && _eBand[r] == 0.0f) ? 1.0f : 0.0f);
				if (!_M.ReadHits(_et, m, h, n, hb, nb, sp, dd, ddb, ddo))
				{ LogA("[mlt] 🌉 리드백 실패\n"); _run = kRuns; return; }
				_dO[a] += ddb;
			}
			++_eb;
			_st = kEvalUp;
		}
	}

private:
	static constexpr uint32 kSeed0 = 12u, kSeeds = 12u;
	static constexpr uint32 kRuns = kSeeds * 2u;      // 팔 A(12) + 팔 B(12)
	static constexpr int    kHold = MLTWorldCfg::kHoldMid;
	static constexpr uint32 kTrainSteps = 600u;
	static constexpr uint32 kTrainEpi0  = 1000u;
	static constexpr uint32 kEvalEpi0   = 0u;
	static constexpr uint32 kEvalB      = 4u;
	static constexpr uint32 kEvalEpis   = kEvalB * MLTModelCfg::kBatch;
	static constexpr float  kBandLo = 0.30f, kBandHi = 0.50f;
	static constexpr float  kThresh = 0.10f;         // ㉡ 절대 문턱(P0 ⑫ 그대로)
	static constexpr uint32 kSignNeed = 10u;

	// ⚠️ 팔 A(앞 12) = 밴드를 **yaw·pitch 에만** · 팔 B(뒤 12) = **세 축 다**
	static bool   _ArmA(uint32 r) { return r < kSeeds; }
	static uint32 _Seed(uint32 r) { return kSeed0 + (r % kSeeds); }
	static uint32 _Axis(uint32 r) { return (r % MLTModelCfg::kCtx) % MLTP1::kAxes; }
	// 그 실행에서 축 `a` 에 홀드아웃을 거나
	static bool   _Held(uint32 r, uint32 a) { return _ArmA(r) ? (a != 0u) : true; }

	enum { kInit = 0, kTrain, kEvalUp, kEvalRd };

	inline static MLTModel _M;
	inline static bool _banner = false;
	inline static uint32 _run = 0u, _step = 0u, _eb = 0u;
	inline static int _st = kInit;
	inline static bool _finite = true;
	inline static float _first = 0.0f, _last = 0.0f, _sumP = 0.0f;
	inline static float _dB[MLTP1::kAxes] = { 0.0f }, _dO[MLTP1::kAxes] = { 0.0f };
	inline static uint32 _hit[MLTP1::kAxes] = { 0u }, _cnt[MLTP1::kAxes] = { 0u };
	inline static MLTP1::Base _bC[MLTP1::kAxes], _bB[MLTP1::kAxes];
	inline static float _bcDist[MLTP1::kAxes] = { 0.0f }, _bbDist[MLTP1::kAxes] = { 0.0f };
	inline static float _bcOut[MLTP1::kAxes] = { 0.0f }, _bbOut[MLTP1::kAxes] = { 0.0f };
	inline static Array<float> _ev, _et, _eBand, _pv, _pt;

	inline static float _rDB[kRuns][MLTP1::kAxes] = { { 0.0f } };
	inline static float _rDO[kRuns][MLTP1::kAxes] = { { 0.0f } };
	inline static float _rAcc[kRuns][MLTP1::kAxes] = { { 0.0f } };
	inline static bool  _rOk[kRuns] = { false };

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🌉 **회차 8 — 「규칙이 축을 건너나」** · 밴드 [%.2f, %.2f) · 씨앗 %u~%u · %u 실행\n",
			(double)kBandLo, (double)kBandHi, kSeed0, kSeed0 + kSeeds - 1u, kRuns);
		LogA("[mlt] 🌉   팔 A = 밴드를 **yaw·pitch 에만**(y 는 그 구간을 물어본다)"
		     " · 팔 B = **세 축 다**(건널 데가 없다)\n");
		LogA("[mlt] 🌉   표제 = `D̄_band(yaw)` A ↔ B · 부호검정 %u/12 · 절대 문턱 %.2f\n",
			kSignNeed, (double)kThresh);
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

	// ── 밴드 안/밖으로 갈린 축별 바닥·천장(거리) ────────────────────
	static void _Baseline(uint32 seed, uint32 axis, MLTP1::Base& c, MLTP1::Base& b)
	{
		uint32 nIn = 0u, nOut = 0u;
		float dCi = 0.0f, dBi = 0.0f, dCo = 0.0f, dBo = 0.0f;
		for (uint32 e = 0; e < kEvalEpis; ++e)
		{
			float v[MLTP1::kTime + 1u], cmd[MLTP1::kTime];
			MLTP1::_Episode(axis, seed, kEvalEpi0 + e, kHold, v, cmd);
			for (uint32 t = 0; t < MLTP1::kTime; ++t)
			{
				const uint32 tgt = MLTP0::Bucket(v[t + 1u]);
				const uint32 gC = MLTP0::Bucket(v[t]);
				const bool sw = ((t % (uint32)kHold) == 0u);
				const uint32 gB = sw ? gC : MLTP0::Bucket(_Refl(v[t] + cmd[t - 1u] * MLTWorldCfg::kDt));
				const float eC = Abs((float)gC - (float)tgt), eB = Abs((float)gB - (float)tgt);
				if (v[t] >= kBandLo && v[t] < kBandHi) { ++nIn;  dCi += eC; dBi += eB; }
				else                                   { ++nOut; dCo += eC; dBo += eB; }
			}
		}
		c.acc = 0.0f; b.acc = 0.0f;   // 이 회차는 정확도를 표제로 안 쓴다
		_bcDist[axis] = nIn  ? dCi / (float)nIn  : 0.0f;
		_bbDist[axis] = nIn  ? dBi / (float)nIn  : 0.0f;
		_bcOut[axis]  = nOut ? dCo / (float)nOut : 0.0f;
		_bbOut[axis]  = nOut ? dBo / (float)nOut : 0.0f;
	}

	static float _Refl(float x)
	{
		const float B = MLTWorldCfg::kBound;
		for (int g = 0; g < 4; ++g)
		{
			if (x > B)  { x = 2.0f * B - x; continue; }
			if (x < -B) { x = -2.0f * B - x; continue; }
			break;
		}
		return x;
	}

	// ── 배치 — ⚠️ 홀드아웃이 **축마다 다르다**(그것이 이 회차의 설계다) ──
	static void _Batch(uint32 seed, uint32 epi0, bool holdout,
		Array<float>& val, Array<float>& tgt, Array<float>* band)
	{
		typedef MLTModelCfg M;
		const uint32 A = MLTP1::kAxes, T = MLTP1::kTime;
		val.Reset(0); tgt.Reset(0);
		if (band != nullptr) band->Reset(0);
		float v[MLTP1::kAxes][MLTP1::kTime + 1u];
		for (uint32 b = 0; b < M::kBatch; ++b)
		{
			for (uint32 a = 0; a < A; ++a) MLTP1::_Episode(a, seed, epi0 + b, kHold, v[a], nullptr);
			for (uint32 t = 0; t < T; ++t)
				for (uint32 a = 0; a < A; ++a)
				{
					const bool inBand = (v[a][t] >= kBandLo && v[a][t] < kBandHi);
					val.Add(v[a][t]);
					// ★ 훈련에서 **그 축에 홀드아웃을 걸었을 때만** 그 행을 뺀다.
					const bool skip = holdout && inBand && _Held(_run, a);
					tgt.Add(skip ? M::kIgnoreTgt : (float)MLTP0::Bucket(v[a][t + 1u]));
					if (band != nullptr) band->Add(inBand ? 1.0f : 0.0f);
				}
		}
	}

	static void _Finish()
	{
		const float sp = (_eb > 0u) ? _sumP / (float)_eb : 0.0f;
		for (uint32 a = 0; a < MLTP1::kAxes; ++a)
		{
			const float dIn  = _dB[a] / (float)_eb;
			const float dOut = _dO[a] / (float)_eb;
			const float wIn  = _bcDist[a] - _bbDist[a];
			const float wOut = _bcOut[a]  - _bbOut[a];
			_rDB[_run][a] = (wIn  > 1.0e-4f) ? (_bcDist[a] - dIn)  / wIn  : 0.0f;
			_rDO[_run][a] = (wOut > 1.0e-4f) ? (_bcOut[a]  - dOut) / wOut : 0.0f;
			_rAcc[_run][a] = _cnt[a] ? (float)_hit[a] / (float)_cnt[a] : 0.0f;
		}
		_rOk[_run] = _finite && (Abs(sp - 1.0f) <= 0.01f);
		LogA("[mlt] 🌉 [%2u/%u] 팔%s 씨앗%2u · 손실 %.3f→%.3f · **D_band %.3f/%.3f/%.3f**"
		     " · D_out %.3f/%.3f/%.3f%s\n",
			_run + 1u, kRuns, _ArmA(_run) ? "A" : "B", _Seed(_run),
			(double)_first, (double)_last,
			(double)_rDB[_run][0], (double)_rDB[_run][1], (double)_rDB[_run][2],
			(double)_rDO[_run][0], (double)_rDO[_run][1], (double)_rDO[_run][2],
			_rOk[_run] ? "" : "  ⛔배관");
		++_run;
		_st = kInit;
		if (_run >= kRuns) _Judge();
	}

	static void _Judge()
	{
		const uint32 A = MLTP1::kAxes;
		float bA[MLTP1::kAxes] = { 0.0f }, bB[MLTP1::kAxes] = { 0.0f };
		float oA[MLTP1::kAxes] = { 0.0f }, oB[MLTP1::kAxes] = { 0.0f };
		uint32 sign = 0u;
		bool plumb = true;
		for (uint32 i = 0; i < kSeeds; ++i)
		{
			for (uint32 a = 0; a < A; ++a)
			{
				bA[a] += _rDB[i][a];         bB[a] += _rDB[kSeeds + i][a];
				oA[a] += _rDO[i][a];         oB[a] += _rDO[kSeeds + i][a];
			}
			if (_rDB[i][1] > _rDB[kSeeds + i][1]) ++sign;   // ★ 검정은 `yaw` 에만 건다
			if (!_rOk[i] || !_rOk[kSeeds + i]) plumb = false;
		}
		const float k = 1.0f / (float)kSeeds;
		for (uint32 a = 0; a < A; ++a) { bA[a] *= k; bB[a] *= k; oA[a] *= k; oB[a] *= k; }

		int fail = 0;
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🌉 **회차 8 결과 — 「규칙이 축을 건너나」**\n");
		LogA("[mlt] 🌉   팔 A(y 는 물어봤다) : D̄_band %.3f(y) / **%.3f(yaw)** / %.3f(pitch)"
		     " · D̄_out %.3f/%.3f/%.3f\n",
			(double)bA[0], (double)bA[1], (double)bA[2], (double)oA[0], (double)oA[1], (double)oA[2]);
		LogA("[mlt] 🌉   팔 B(아무도 안 물었다): D̄_band %.3f(y) / **%.3f(yaw)** / %.3f(pitch)"
		     " · D̄_out %.3f/%.3f/%.3f\n",
			(double)bB[0], (double)bB[1], (double)bB[2], (double)oB[0], (double)oB[1], (double)oB[2]);

		if (!plumb) { LogA("[mlt] 🌉   ⛔ ㉣ 배관이 깨진 실행이 있다 — **판정불가**\n"); ++fail; }
		else          LogA("[mlt] 🌉   ✅ ㉣ 배관 — probs 합 1.0 · 전 구간 유한\n");

		bool g3 = true;
		for (uint32 a = 0; a < A; ++a) if (oA[a] <= 0.0f || oB[a] <= 0.0f) g3 = false;
		LogA("[mlt] 🌉   %s ㉢ 배관 — 두 팔 다 밴드 **밖**에서 복사보다 좋다\n", g3 ? "✅" : "⛔");
		if (!g3) ++fail;

		// ㉤ 위생 검사 — 팔 A 의 `y` 는 그 구간을 물어봤으니 팔 B 보다 좋아야 한다
		const bool g5 = (bA[0] > bB[0]);
		LogA("[mlt] 🌉   %s ㉤ 위생 — 팔A 의 y 밴드 %.3f > 팔B 의 y 밴드 %.3f"
		     " (아니면 **홀드아웃 배선이 틀린 것**이다)\n", g5 ? "✅" : "⛔", (double)bA[0], (double)bB[0]);
		if (!g5) ++fail;

		const bool g1 = (bA[1] > bB[1]) && (sign >= kSignNeed);
		LogA("[mlt] 🌉   %s ㉠ **규칙이 축을 건넜나** — yaw 밴드 A %.3f > B %.3f · 부호검정 **%u/12**\n",
			g1 ? "✅" : "⛔", (double)bA[1], (double)bB[1], sign);
		if (!g1) ++fail;

		const bool g2 = (bA[1] >= kThresh);
		LogA("[mlt] 🌉   %s ㉡ **보간이 됐나**(절대) — yaw 밴드 A %.3f ≥ %.2f\n",
			g2 ? "✅" : "⛔", (double)bA[1], (double)kThresh);
		if (!g2) ++fail;

		LogA("[mlt] ══════════════════════════════════════════════════\n");
		// ⚠️⚠️ **해석 분기를 미리 등록해 뒀다** — 여기서 정하지 않는다.
		if (!plumb || !g3 || !g5)
			LogA("[mlt] 🌉 ⛔ **배관/위생이 깨졌다 — 판정불가.** 표제를 인용하지 마라\n");
		else if (g1 && g2)
			LogA("[mlt] 🌉 ✅✅ **구조가 규칙을 강제했다.** P0 의 「구간 표」는 **축이 하나여서**였다\n");
		else if (g1 && !g2)
			LogA("[mlt] 🌉 ⚠️ **건너기는 실재하지만 부족하다**(A > B 인데 절대 문턱 미달)"
			     " ⇒ 다음 손잡이는 **축 수**(3 → 5)\n");
		else
			LogA("[mlt] 🌉 ⚠️⚠️ **축을 늘려도 규칙이 안 선다.** ⇒ 다음 물음은 인코딩도 축도 아니라"
			     " **손실**이다(다음 스텝만으로는 규칙을 요구하지 않는다)\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		(void)fail;
	}
};
