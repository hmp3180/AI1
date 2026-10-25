// mltp1run.cw — 🏁 **P1 판정 라운드.** 등록문은 `mltp1.cw` 머리말이 정본이다.
//
// ★ 여기는 **배관과 집계**만 있다 — 무엇을 이득이라 부르는지는 전부 그 등록문에 적혀 있다.
//
// ⚠️⚠️ **이 라운드에 처음 들어온 것 셋**(컨셉 감사가 찾은 누락 — `mltlog_1.md` 「컨셉 감사」)
//   ㈀ ⭐ **「넣으면 싸지나」 곡선** — `R(step)` 을 다섯 점에서 찍고 **몇 배**로 기록한다.
//     P0 은 600스텝 고정이라 이것을 **구조적으로 못 쟀다.**
//   ㈁ ⭐ **팔 8(답을 준 팔)** · **팔 9(그것만 쓰는 팔)** · **팔 10(시험만 가림)**.
//   ㈂ ⭐ **wall-clock** 을 실행마다 찍는다(규율 7 · P0 에서 빠진 자리).
//
// ⚠️ 실행 배치(등록문 ④′): 팔4(12) + 팔5(12) + 팔6/9(12) + 팔7(12) + 팔8(6) = **54**.
//   ★ 팔 10 은 **실행을 안 쓴다** — 팔 4 의 학습된 모델로 **시험을 두 번** 한다.

using namespace PE;

class MLTP1Run
{
public:
	static bool Done() { return _run >= kRuns; }

	static void Tick(RHI* rhi)
	{
		if (_run >= kRuns || rhi == nullptr) return;
		// ⚠️ 몸통이 P1 배치여야 한다 — 아니면 **조용히 다른 것을 잰다.**
		if (MLTModelCfg::kAxes != MLTP1::kAxes || MLTModelCfg::kTime != MLTP1::kTime)
		{
			LogA("[mlt] 🏁 ⛔⛔ **P1 은 축 %u · 시각 %u 를 전제한다** — 지금은 축 %u · 시각 %u 다\n",
				MLTP1::kAxes, MLTP1::kTime, MLTModelCfg::kAxes, MLTModelCfg::kTime);
			_run = kRuns; return;
		}
		// ⚠️ **기본에서 껐다** — 회차 7 로 통과했다(관문 여섯). ★ 다시 돌리려면 `-mltp1`.
		//   **지운 것이 아니라 끈 것**이다(등록문과 실측이 이 파일에 남아 있어야 한다).
		if (!OS::CommandLine::Has("-mltp1"))
		{
			LogA("[mlt] 🏁 P1 판정 라운드는 **꺼져 있다**(`-mltp1` 으로 켠다) — 통과 기록:"
			     " R̄ 0.704/0.691/0.719 · 부호검정 12·12·12 · 대각 몫 99%% · 2.0배 싸다\n");
			_run = kRuns;
			return;
		}
		if (!_banner) { _Banner(); _banner = true; }

		if (_st == kInit)
		{
			if (!_M.Setup(rhi)) { LogA("[mlt] 🏁 준비 실패(run %u)\n", _run); _run = kRuns; return; }
			const Cfg c = _Plan(_run);
			for (uint32 a = 0; a < MLTP1::kAxes; ++a)
			{
				MLTP1::_Baseline(a, kHold, c.seed, 1u, kEvalEpi0, kEvalEpis, _bCopy[a], _bBayes[a]);
				// ⚠️⚠️ **실행마다 남긴다** — `_bCopy` 는 다음 실행에서 덮인다. 부호검정은
				//   «학습_seed − **복사_seed**» 의 부호에 걸리므로 **씨앗별 복사**가 없으면 못 건다.
				//   ★ 이 버그를 쓰면서 잡았다(판정에서 마지막 실행의 바닥을 쓰고 있었다).
				_rCopy[_run][a]  = _bCopy[a].acc;
				_rBayes[_run][a] = _bBayes[a].acc;
			}
			_step = 0u; _probe = 0u; _finite = true; _first = 0.0f; _last = 0.0f;
			for (uint32 p = 0; p < kProbes; ++p) for (uint32 a = 0; a < MLTP1::kAxes; ++a) _curve[p][a] = 0.0f;
			_st = kTrain;
			return;
		}

		if (_st == kTrain)
		{
			if (_step > 0u)
			{
				float ls = 0.0f;
				if (!_M.ReadLoss(ls)) { LogA("[mlt] 🏁 손실 리드백 실패\n"); _run = kRuns; return; }
				if (!(ls == ls) || ls > 1.0e30f) _finite = false;
				if (_step == 1u) _first = ls;
				_last = ls;
			}
			// ⭐ 곡선 점에 닿았나 — 「몇 배」를 재려면 **중간에도 시험해야** 한다.
			if (_probe < kProbes && _step >= kProbeAt[_probe]) { _StartEval(kEvNormal); return; }
			if (_step >= kTrainSteps) { _StartEval(kEvFinal); return; }

			const Cfg c = _Plan(_run);
			// ⏱️⏱️ **풀 경계에서만 업로드한다** — `MLArena::Write` 가 «동기이고 무겁다(스테이징 +
			//   큐 유휴 대기) — **스텝마다 부르지 마라**» 라고 못 박아 뒀고, 실측이 그것을 확인했다:
			//   판정 ③(처음 한 번만 올린다) 렌더CPU **5~10ms** ↔ 스텝마다 올리면 **250~400ms**.
			//   ⚠️ **결과는 안 바뀐다** — 같은 배치를 같은 순서로 본다(순수 배관).
			const uint32 K = MLTModelCfg::kPool;
			const uint32 slot = _step % K;
			if (slot == 0u)
			{
				const uint32 nStep = ((kTrainSteps - _step) < K) ? (kTrainSteps - _step) : K;
				_poolVal.Reset(0); _poolTgt.Reset(0);
				for (uint32 k = 0; k < nStep; ++k)
				{
					Array<float> v, g;
					_Batch(c, kTrainEpi0 + (_step + k) * MLTModelCfg::kBatch, c.arm, v, g);
					for (uint32 i = 0; i < v.Count(); ++i) _poolVal.Add(v[i]);
					for (uint32 i = 0; i < g.Count(); ++i) _poolTgt.Add(g[i]);
				}
				if (!_M.UploadPool(_poolVal, _poolTgt, nStep))
				{ LogA("[mlt] 🏁 풀 업로드 실패(step %u · %u개)\n", _step, nStep); _run = kRuns; return; }
			}
			_M.SelectStep(slot);
			if (!_M.Forward() || !_M.Backward() || !_M.AdamStep())
			{ LogA("[mlt] 🏁 스텝 실패(run %u · step %u)\n", _run, _step); _run = kRuns; return; }
			++_step;
			// ⏱️ **비용을 찍는다**(규율 7 — P0 에서 빠졌던 자리). ★ 엔진이 이미 재고 있는 값이다:
			//   `renderCpuMs` = 렌더 경로 CPU(우리 디스패치가 거기 있다) · `gpuMs` = GPU 시간.
			//   ⚠️ 둘을 **함께** 봐야 «CPU 바운드인가 GPU 바운드인가» 가 갈린다 — 한 숫자로는 안 보인다.
			if ((_step % 200u) == 0u)
				LogA("[mlt] 🏁      ⏱️ step %3u · 렌더CPU %.1fms · GPU %.1fms"
				     " ⇒ 이 실행의 남은 시간 ≈ %.0f초\n",
					_step, (double)FrameStats::renderCpuMs, (double)FrameStats::gpuMs,
					(double)((float)(kTrainSteps - _step) * FrameStats::renderCpuMs / 1000.0f));
			return;
		}

		if (_st == kEvalUp)
		{
			if (_eb >= kEvalB) { _EvalDone(); return; }
			const Cfg c = _Plan(_run);
			// ⚠️ 시험의 팔: 정상 시험은 **학습 팔의 입력 규약**을 그대로 쓴다.
			//   ★ 팔 10(시험만 가림)은 **팔 4 로 학습한 모델**에 `가림` 입력을 준다.
			const int evArm = (_evKind == kEvMasked) ? 5 : c.arm;
			_Batch(c, kEvalEpi0 + _eb * MLTModelCfg::kBatch, evArm, _evVal, _evTgt);
			if (!_M.Upload(_evVal, _evTgt)) { LogA("[mlt] 🏁 시험 업로드 실패\n"); _run = kRuns; return; }
			if (!_M.Forward()) { LogA("[mlt] 🏁 시험 forward 실패\n"); _run = kRuns; return; }
			// ⚠️ 여기서 backward 를 **안 부른다** — 기제 진단은 아래 별 패스가 한다(그것이
			//   「축 하나만 표적」이라야 물음이 성립한다).
			_st = kEvalRd;
			return;
		}

		if (_st == kEvalRd)
		{
			uint32 h[MLTP1::kAxes] = { 0u }, n[MLTP1::kAxes] = { 0u };
			float sp = 0.0f;
			if (!_ReadPerAxis(h, n, sp)) { LogA("[mlt] 🏁 시험 리드백 실패\n"); _run = kRuns; return; }
			for (uint32 a = 0; a < MLTP1::kAxes; ++a) { _hit[a] += h[a]; _cnt[a] += n[a]; }
			_sumP += sp;
			++_eb;
			_st = kEvalUp;
			return;
		}

		// ══════════════════════════════════════════════════════════════
		// ⭐ **관문 ㉡ 의 진단 — 「축 `a` 의 손실이 축 `a` 슬롯에 몰리나」**
		//
		// ★ **왜 별 패스가 필요한가** — 처음엔 최종 시험의 backward 에서 `dVal` 을
		//   그냥 읽으려 했는데 그것은 **모든 행의 손실 합**에 대한 민감도다 ⇒ 「축별 분포」일 뿐이고
		//   물음(*"축 a 의 손실이 축 a 에 몰리나"*)이 아니다. **조용히 다른 것을 잴 자리였다.**
		//   ⇒ ★ 표적을 **한 축만 남기고**(나머지는 `kIgnoreTgt`) fwd+bwd 를 돌린다.
		//     그러면 `dVal[r]` 이 «축 a 의 손실이 슬롯 r 의 값에 얼마나 민감한가» 가 된다.
		//   ⚠️ **AdamStep 을 부르지 않는다** ⇒ 가중치가 안 변한다(시험이 오염되지 않는다).
		//   ★ 비용: 축마다 **한 배치**면 된다(비율만 보므로) ⇒ 실행당 `A = 3` 프레임 ≈ 0.5%.
		// ══════════════════════════════════════════════════════════════
		if (_st == kDiagUp)
		{
			if (_diag >= MLTP1::kAxes)
			{
				// ★ `대각 몫` = 축 a 의 손실이 **축 a 슬롯**에 실린 |dVal| 비율. 우연은 `1/A`.
				for (uint32 a = 0; a < MLTP1::kAxes; ++a)
				{
					float tot = 0.0f;
					for (uint32 j = 0; j < MLTP1::kAxes; ++j) tot += _massRow[a][j];
					_rMass[_run][a] = (tot > 1.0e-12f) ? _massRow[a][a] / tot : 0.0f;
				}
				LogA("[mlt] 🏁      ↳ ㉡ 기제: **대각 몫** %.0f/%.0f/%.0f%% (우연 %.1f%%)\n",
					(double)(_rMass[_run][0] * 100.0f), (double)(_rMass[_run][1] * 100.0f),
					(double)(_rMass[_run][2] * 100.0f), (double)(100.0f / (float)MLTP1::kAxes));
				const Cfg c = _Plan(_run);
				if (c.arm == 4) { _StartEval(kEvMasked); return; }
				_Advance();
				return;
			}
			const Cfg c = _Plan(_run);
			Array<float> val, tgt;
			_Batch(c, kEvalEpi0, c.arm, val, tgt);
			// ⚠️ **축 `_diag` 만 표적으로 남긴다** — 나머지 행은 손실에서 뺀다.
			for (uint32 r = 0; r < MLTModelCfg::kRows; ++r)
				if (((r % MLTModelCfg::kCtx) % MLTP1::kAxes) != _diag) tgt[r] = MLTModelCfg::kIgnoreTgt;
			if (!_M.Upload(val, tgt)) { LogA("[mlt] 🏁 진단 업로드 실패\n"); _run = kRuns; return; }
			if (!_M.Forward() || !_M.Backward()) { LogA("[mlt] 🏁 진단 실패\n"); _run = kRuns; return; }
			_st = kDiagRd;
			return;
		}

		// kDiagRd
		{
			float m[MLTP1::kAxes] = { 0.0f };
			if (!_M.ReadAxisMass(m, MLTP1::kAxes)) { LogA("[mlt] 🏁 진단 리드백 실패\n"); _run = kRuns; return; }
			for (uint32 j = 0; j < MLTP1::kAxes; ++j) _massRow[_diag][j] = m[j];
			++_diag;
			_st = kDiagUp;
		}
	}

private:
	// ── 계획 ────────────────────────────────────────────────────────
	struct Cfg { int arm; uint32 seed; };
	static constexpr uint32 kSeed0 = 12u, kSeeds = 12u;
	static constexpr uint32 kA8Seeds = 6u;                       // 팔 8 은 6 씨앗(천장 · 검정 안 건다)
	static constexpr uint32 kRuns = kSeeds * 4u + kA8Seeds;      // 4·5·6/9·7 각 12 + 8 은 6 = 54
	static constexpr int    kHold = MLTWorldCfg::kHoldMid;
	static constexpr uint32 kTrainSteps = 600u;
	static constexpr uint32 kTrainEpi0  = 1000u;
	static constexpr uint32 kEvalEpi0   = 0u;
	static constexpr uint32 kEvalB      = 4u;
	static constexpr uint32 kEvalEpis   = kEvalB * MLTModelCfg::kBatch;
	static constexpr float  kThreshR    = 0.15f;
	static constexpr uint32 kSignNeed   = 10u;
	static constexpr float  kArm5Max    = 0.080f;
	static constexpr float  kMassMin    = 0.50f;   // ㉡ 기제 — 우연은 1/3 = 0.333
	static constexpr float  kP0Regress  = 0.34f;   // ㉥ P0 회귀 — 「절반 이상 남았나」
	static constexpr uint32 kProbes = 4u;                                  // 곡선 점(최종은 따로)
	static constexpr uint32 kProbeAt[kProbes] = { 75u, 150u, 300u, 450u }; // ㉥⁺ 「몇 배」

	static Cfg _Plan(uint32 r)
	{
		Cfg c{};
		if (r < kSeeds)            { c.arm = 4; c.seed = kSeed0 + r; }
		else if (r < kSeeds * 2u)  { c.arm = 5; c.seed = kSeed0 + (r - kSeeds); }
		else if (r < kSeeds * 3u)  { c.arm = 6; c.seed = kSeed0 + (r - kSeeds * 2u); }
		else if (r < kSeeds * 4u)  { c.arm = 7; c.seed = kSeed0 + (r - kSeeds * 3u); }
		else                       { c.arm = 8; c.seed = kSeed0 + (r - kSeeds * 4u); }
		return c;
	}

	enum { kInit = 0, kTrain, kEvalUp, kEvalRd, kDiagUp, kDiagRd };
	enum { kEvNormal = 0, kEvFinal, kEvMasked };

	inline static MLTModel _M;
	inline static bool   _banner = false;
	inline static uint32 _run = 0u;
	inline static int    _st = kInit;
	inline static uint32 _step = 0u, _probe = 0u, _eb = 0u;
	inline static int    _evKind = kEvNormal;
	inline static float  _first = 0.0f, _last = 0.0f, _sumP = 0.0f;
	inline static bool   _finite = true;
	inline static uint32 _hit[MLTP1::kAxes] = { 0u }, _cnt[MLTP1::kAxes] = { 0u };
	inline static uint32 _diag = 0u;
	inline static float  _massRow[MLTP1::kAxes][MLTP1::kAxes] = { { 0.0f } };
	inline static MLTP1::Base _bCopy[MLTP1::kAxes], _bBayes[MLTP1::kAxes];
	inline static Array<float> _evVal, _evTgt, _poolVal, _poolTgt;
	inline static float  _curve[kProbes][MLTP1::kAxes];

	// 결과 표
	inline static float _rR[kRuns][MLTP1::kAxes]   = { { 0.0f } };
	inline static float _rAcc[kRuns][MLTP1::kAxes] = { { 0.0f } };
	inline static float _rMass[kRuns][MLTP1::kAxes]= { { 0.0f } };
	inline static float _rCopy[kRuns][MLTP1::kAxes]  = { { 0.0f } };
	inline static float _rBayes[kRuns][MLTP1::kAxes] = { { 0.0f } };
	inline static float _rCurve[kRuns][kProbes][MLTP1::kAxes] = { { { 0.0f } } };
	inline static float _rMaskAcc[kSeeds][MLTP1::kAxes] = { { 0.0f } };   // 팔 10
	inline static bool  _rOk[kRuns] = { false };

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🏁 **P1 판정 라운드** — 축 셋(y·yaw·pitch) · 중간(hold=%d) · 씨앗 %u~%u · **%u 실행**\n",
			kHold, kSeed0, kSeed0 + kSeeds - 1u, kRuns);
		LogA("[mlt] 🏁   팔 4(12) · 5[가림](12) · 6/9[뺌·심볼만](12) · 7[같은비용](12) · 8[답준팔](%u)"
		     " + 팔 10 은 팔 4 에 얹는다\n", kA8Seeds);
		LogA("[mlt] 🏁   문턱: 축마다 R̄ ≥ %.2f · 부호검정 %u/12 · 기제 |dVal| 몫 ≥ %.0f%%(우연 33.3%%)"
		     " · 팔5 ≤ %.0f%% · P0 회귀 R̄(y) ≥ %.2f\n",
			(double)kThreshR, kSignNeed, (double)(kMassMin * 100.0f),
			(double)(kArm5Max * 100.0f), (double)kP0Regress);
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

	static void _StartEval(int kind)
	{
		_evKind = kind; _eb = 0u; _sumP = 0.0f;
		for (uint32 a = 0; a < MLTP1::kAxes; ++a) { _hit[a] = 0u; _cnt[a] = 0u; }
		_st = kEvalUp;
	}

	static void _EvalDone()
	{
		float acc[MLTP1::kAxes], R[MLTP1::kAxes];
		for (uint32 a = 0; a < MLTP1::kAxes; ++a)
		{
			acc[a] = _cnt[a] ? (float)_hit[a] / (float)_cnt[a] : 0.0f;
			const float w = _bBayes[a].acc - _bCopy[a].acc;
			R[a] = (w > 1.0e-4f) ? (acc[a] - _bCopy[a].acc) / w : 0.0f;
		}

		if (_evKind == kEvNormal)
		{
			// 곡선 점 — 기록하고 **훈련을 이어간다**
			for (uint32 a = 0; a < MLTP1::kAxes; ++a) _curve[_probe][a] = R[a];
			++_probe;
			_st = kTrain;
			return;
		}
		if (_evKind == kEvFinal)
		{
			const Cfg c = _Plan(_run);
			const float sp = (_eb > 0u) ? _sumP / (float)_eb : 0.0f;
			// ⚠️ `_rMass` 는 **여기서 안 채운다** — 아래 진단 패스(축마다 표적 하나)가 채운다.
			for (uint32 a = 0; a < MLTP1::kAxes; ++a)
			{
				_rAcc[_run][a] = acc[a]; _rR[_run][a] = R[a];
				for (uint32 p = 0; p < kProbes; ++p) _rCurve[_run][p][a] = _curve[p][a];
			}
			_rOk[_run] = _finite && (Abs(sp - 1.0f) <= 0.01f);
			LogA("[mlt] 🏁 [%2u/%u] 팔%d 씨앗%2u · 손실 %.3f→%.3f · 정확도 %.1f/%.1f/%.1f%%"
			     " ⇒ **R = %.3f / %.3f / %.3f**%s\n",
				_run + 1u, kRuns, c.arm, c.seed, (double)_first, (double)_last,
				(double)(acc[0] * 100.0f), (double)(acc[1] * 100.0f), (double)(acc[2] * 100.0f),
				(double)R[0], (double)R[1], (double)R[2], _rOk[_run] ? "" : "  ⛔배관");
			// ⭐ 이제 **관문 ㉡ 의 진단 패스**로 간다(축마다 표적을 하나만 남기고 fwd+bwd).
			_diag = 0u;
			_st = kDiagUp;
			return;
		}
		// kEvMasked — 팔 10
		{
			const Cfg c = _Plan(_run);
			for (uint32 a = 0; a < MLTP1::kAxes; ++a) _rMaskAcc[_run][a] = acc[a];
			LogA("[mlt] 🏁      ↳ 팔10[시험만 가림] 정확도 %.1f/%.1f/%.1f%% (같은 가중치 · 추가 훈련 0)\n",
				(double)(acc[0] * 100.0f), (double)(acc[1] * 100.0f), (double)(acc[2] * 100.0f));
			(void)c;
			_Advance();
		}
	}

	static void _Advance()
	{
		++_run;
		_st = kInit;
		if (_run >= kRuns) _Judge();
	}

	// ── 배치 ────────────────────────────────────────────────────────
	//   행 `r = b·T + t·A + a`. ⚠️ 표적은 **그 축의 다음 시각 값**이다.
	static void _Batch(const Cfg& c, uint32 epi0, int arm, Array<float>& val, Array<float>& tgt)
	{
		typedef MLTModelCfg M;
		const uint32 A = MLTP1::kAxes, T = MLTP1::kTime;
		val.Reset(0); tgt.Reset(0);
		float v[MLTP1::kAxes][MLTP1::kTime + 1u];
		for (uint32 b = 0; b < M::kBatch; ++b)
		{
			for (uint32 a = 0; a < A; ++a) MLTP1::_Episode(a, c.seed, epi0 + b, kHold, v[a], nullptr);
			for (uint32 t = 0; t < T; ++t)
				for (uint32 a = 0; a < A; ++a)
				{
					// ⭐ **팔 8(답을 준 팔)** — 값 자리에 **표적 버킷 자체**를 넣는다(정규화해서).
					//   ⚠️ 누출이다. 목적이 **천장 측정**이므로 성능을 판정문에 인용하지 않는다.
					if (arm == 8) val.Add((float)MLTP0::Bucket(v[a][t + 1u]) / (float)(MLTP0::kB - 1u) * 2.0f - 1.0f);
					// ⭐ **팔 7(내용 없는 같은 비용)** — 축 0 만 실값 · 나머지 슬롯은 0
					else if (arm == 7) val.Add((a == 0u) ? v[a][t] : 0.0f);
					// **팔 6/9** — 값을 전부 0(심볼+위치만 남는다)
					else if (arm == 6) val.Add(0.0f);
					else               val.Add(v[a][t]);
					tgt.Add((float)MLTP0::Bucket(v[a][t + 1u]));
				}
		}
		// **팔 5[가림]** — 값을 배치 전체에 걸쳐 섞는다(결정적 순열).
		//   ⚠️ 313 은 홀수 ⇒ `kRows`(2의 거듭제곱)와 서로소다... **가 아니다**: kRows = 768 = 2^8·3.
		//   ★ 그래서 `kRows` 와 서로소인 **313**(소수 · 768 = 2^8·3 과 공약수 없음)을 그대로 쓴다.
		if (arm == 5)
		{
			Array<float> src = val;
			for (uint32 i = 0; i < val.Count(); ++i) val[i] = src[(i * 313u + 17u) % M::kRows];
		}
	}

	// 행마다 argmax 를 재고 **축별로** 모은다. ⚠️ 축을 하나로 접으면 «축이 갈리나» 가 안 보인다.
	static bool _ReadPerAxis(uint32* hit, uint32* cnt, float& sumP)
	{
		typedef MLTModelCfg M;
		// `ReadHits` 는 축을 모르므로 밴드 자리를 **축 마스크**로 재활용한다 — 축마다 한 번씩 부른다.
		//   ⚠️ 리드백이 축 수만큼 늘지만 `Read` 는 프레임당 여러 번 해도 된다(같은 프레임의 결과다).
		sumP = 0.0f;
		Array<float> mask;
		for (uint32 a = 0; a < MLTP1::kAxes; ++a)
		{
			mask.Reset(0);
			for (uint32 r = 0; r < M::kRows; ++r)
				mask.Add((((r % M::kCtx) % MLTP1::kAxes) == a) ? 1.0f : 0.0f);
			uint32 h = 0u, n = 0u, hb = 0u, nb = 0u;
			float sp = 0.0f, dd = 0.0f, ddb = 0.0f, ddo = 0.0f;
			if (!_M.ReadHits(_evTgt, mask, h, n, hb, nb, sp, dd, ddb, ddo)) return false;
			hit[a] = hb; cnt[a] = nb;
			if (a == 0u) sumP = sp;
		}
		return true;
	}

	// ══════════════════════════════════════════════════════════════════
	// ⚖️ 판정 — 관문 여섯. ⚠️ 하나라도 깨지면 표제를 인용하지 않는다.
	// ══════════════════════════════════════════════════════════════════
	static void _Judge()
	{
		const uint32 A = MLTP1::kAxes;
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🏁 **P1 판정 결과**\n");

		int fail = 0;
		bool plumbing = true;
		for (uint32 r = 0; r < kRuns; ++r) if (!_rOk[r]) plumbing = false;
		if (!plumbing) { LogA("[mlt] 🏁   ⛔ 배관이 깨진 실행이 있다 — **판정불가**\n"); ++fail; }

		// ── ㉠ 표제(축마다) ────────────────────────────────────────
		float rBar[MLTP1::kAxes] = { 0.0f }; uint32 sign[MLTP1::kAxes] = { 0u };
		bool ceilOk = true;
		for (uint32 a = 0; a < A; ++a)
		{
			float s = 0.0f;
			for (uint32 i = 0; i < kSeeds; ++i)
			{
				s += _rR[i][a];
				// ★ **씨앗별 복사**와 견준다(그 실행에서 재 둔 값).
				if (_rAcc[i][a] > _rCopy[i][a]) ++sign[a];
				// ㉤ 상한 — `R > 1` 이면 베이즈 초과 = 누출이다.
				if (_rR[i][a] > 1.0f) ceilOk = false;
			}
			rBar[a] = s / (float)kSeeds;
		}
		bool g1 = true;
		for (uint32 a = 0; a < A; ++a) if (rBar[a] < kThreshR || sign[a] < kSignNeed) g1 = false;
		LogA("[mlt] 🏁   %s ㉠ 표제 — R̄ = %.3f(y) / %.3f(yaw) / %.3f(pitch) (문턱 %.2f)"
		     " · 부호검정 %u·%u·%u /12\n",
			g1 ? "✅" : "⛔", (double)rBar[0], (double)rBar[1], (double)rBar[2], (double)kThreshR,
			sign[0], sign[1], sign[2]);
		if (!g1) ++fail;

		// ── ㉡ 기제 — **대각 몫**(축 a 의 손실이 축 a 슬롯에 몰리나) ─────
		float diag[MLTP1::kAxes] = { 0.0f };
		for (uint32 a = 0; a < A; ++a)
		{
			float s = 0.0f;
			for (uint32 i = 0; i < kSeeds; ++i) s += _rMass[i][a];
			diag[a] = s / (float)kSeeds;
		}
		bool g2 = true;
		for (uint32 a = 0; a < A; ++a) if (diag[a] < kMassMin) g2 = false;
		LogA("[mlt] 🏁   %s ㉡ 기제 — **대각 몫** %.0f/%.0f/%.0f%% (문턱 %.0f%% · 우연 %.1f%%)\n",
			g2 ? "✅" : "⛔",
			(double)(diag[0] * 100.0f), (double)(diag[1] * 100.0f), (double)(diag[2] * 100.0f),
			(double)(kMassMin * 100.0f), (double)(100.0f / (float)A));
		if (!g2)
			LogA("[mlt] 🏁     ⚠️ **발화하지 않았다 ⇒ 성능이 좋아도 판정불가**(등록문 ㉡ 의 그 계약)\n");
		if (!g2) ++fail;

		// ── ㉢ 팔 7 대조 · ㉣ 대조군 · ㉥ P0 회귀 ────────────────
		float a4y = 0.0f, a7y = 0.0f, a5 = 0.0f, a6 = 0.0f;
		for (uint32 i = 0; i < kSeeds; ++i)
		{
			a4y += _rAcc[i][0];
			a7y += _rAcc[kSeeds * 3u + i][0];
			for (uint32 a = 0; a < A; ++a)
			{ a5 += _rAcc[kSeeds + i][a]; a6 += _rAcc[kSeeds * 2u + i][a]; }
		}
		a4y /= (float)kSeeds; a7y /= (float)kSeeds;
		a5 /= (float)(kSeeds * A); a6 /= (float)(kSeeds * A);

		const bool g3 = (a4y > a7y);
		LogA("[mlt] 🏁   %s ㉢ 팔7 대조 — 팔4 의 y %.2f%% vs 팔7 의 y %.2f%% (축을 늘린 것이 값을 했나)\n",
			g3 ? "✅" : "⛔", (double)(a4y * 100.0f), (double)(a7y * 100.0f));
		if (!g3) ++fail;

		const bool g4 = (a5 <= kArm5Max);
		LogA("[mlt] 🏁   %s ㉣ 대조군 — 팔5[가림] %.2f%% ≤ %.1f%% · 팔6/9[뺌·심볼만] %.2f%%\n",
			g4 ? "✅" : "⛔", (double)(a5 * 100.0f), (double)(kArm5Max * 100.0f), (double)(a6 * 100.0f));
		if (!g4) ++fail;

		LogA("[mlt] 🏁   %s ㉤ 상한 — R > 1 인 실행 %s\n", ceilOk ? "✅" : "⛔", ceilOk ? "없다" : "**있다 = 누출**");
		if (!ceilOk) ++fail;

		const bool g6 = (rBar[0] >= kP0Regress);
		LogA("[mlt] 🏁   %s ㉥ P0 회귀 — R̄(y) %.3f ≥ %.2f (P0 중간 0.68 의 절반)\n",
			g6 ? "✅" : "⛔", (double)rBar[0], (double)kP0Regress);
		if (!g6) ++fail;

		// ── ㉥⁺ 「넣으면 싸지나」 ─────────────────────────────────
		_JudgeCurve(rBar[0]);

		// ── 팔 10 ─────────────────────────────────────────────────
		float m10 = 0.0f;
		for (uint32 i = 0; i < kSeeds; ++i) for (uint32 a = 0; a < A; ++a) m10 += _rMaskAcc[i][a];
		m10 /= (float)(kSeeds * A);
		float a4all = 0.0f;
		for (uint32 i = 0; i < kSeeds; ++i) for (uint32 a = 0; a < A; ++a) a4all += _rAcc[i][a];
		a4all /= (float)(kSeeds * A);
		LogA("[mlt] 🏁   ⓘ 팔10[시험만 가림] %.2f%% ↔ 팔4 정상 %.2f%% ↔ 팔5[훈련부터 가림] %.2f%%\n"
		     "[mlt] 🏁     ⇒ 「입력에서만 가림」과 「학습에서 빼기」가 **다른 수를 낸다**는 그 자리다\n",
			(double)(m10 * 100.0f), (double)(a4all * 100.0f), (double)(a5 * 100.0f));

		// ── 팔 8(천장) — ⚠️ 성능을 판정문에 인용하지 않는다 ────────
		float a8 = 0.0f;
		for (uint32 i = 0; i < kA8Seeds; ++i) for (uint32 a = 0; a < A; ++a) a8 += _rAcc[kSeeds * 4u + i][a];
		a8 /= (float)(kA8Seeds * A);
		LogA("[mlt] 🏁   ⓘ 팔8[답을 준 팔] %.2f%% — ⚠️ **천장이다**(성능 인용 금지). 낮으면"
		     " 벽은 **입력이 아니라 표현력**이다\n", (double)(a8 * 100.0f));

		LogA("[mlt] ══════════════════════════════════════════════════\n");
		if (fail == 0)
			LogA("[mlt] 🏁 ✅✅ **P1 통과 — 축 셋이 갈리고 기제가 발화했다**\n");
		else
			LogA("[mlt] 🏁 ⛔ **P1 관문 %d개 실패 — 표제를 인용하지 않는다.** `mltlog_1.md` 에 잇는다\n", fail);
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

	// ⭐ 「넣으면 싸지나」 — **몇 배**로 기록한다
	static void _JudgeCurve(float r4final)
	{
		const uint32 steps[kProbes + 1u] = { kProbeAt[0], kProbeAt[1], kProbeAt[2], kProbeAt[3], kTrainSteps };
		float c4[kProbes + 1u] = { 0.0f }, c7[kProbes + 1u] = { 0.0f };
		for (uint32 p = 0; p < kProbes; ++p)
		{
			float s4 = 0.0f, s7 = 0.0f;
			for (uint32 i = 0; i < kSeeds; ++i)
			{ s4 += _rCurve[i][p][0]; s7 += _rCurve[kSeeds * 3u + i][p][0]; }
			c4[p] = s4 / (float)kSeeds; c7[p] = s7 / (float)kSeeds;
		}
		float s7f = 0.0f;
		for (uint32 i = 0; i < kSeeds; ++i) s7f += _rR[kSeeds * 3u + i][0];
		c4[kProbes] = r4final; c7[kProbes] = s7f / (float)kSeeds;

		LogA("[mlt] 🏁   ⭐ ㉥⁺ 「넣으면 싸지나」 — 축 y 의 `R(step)` 곡선\n");
		LogA("[mlt] 🏁     팔4(축 셋) : ");
		for (uint32 p = 0; p <= kProbes; ++p) LogA("%u→%.3f  ", steps[p], (double)c4[p]);
		LogA("\n[mlt] 🏁     팔7(축 하나): ");
		for (uint32 p = 0; p <= kProbes; ++p) LogA("%u→%.3f  ", steps[p], (double)c7[p]);
		LogA("\n");

		// 팔 7 의 **최종** `R` 에 팔 4 가 몇 스텝에 닿나
		const float target = c7[kProbes];
		uint32 reach4 = 0u;
		for (uint32 p = 0; p <= kProbes; ++p) if (c4[p] >= target) { reach4 = steps[p]; break; }
		if (reach4 == 0u)
			LogA("[mlt] 🏁     ⇒ ⚠️ **판정불가** — 팔4 가 팔7 의 최종 R(%.3f)에 곡선 안에서 못 닿았다"
			     "(억지로 수를 만들지 않는다)\n", (double)target);
		else
		{
			const float ratio = (float)kTrainSteps / (float)reach4;
			LogA("[mlt] 🏁     ⇒ 팔4 가 팔7 의 최종 R(%.3f)에 **%u 스텝**에 닿는다 vs 팔7 은 %u"
			     " ⇒ **%.1f배 싸다** (문턱 2.0배)\n",
				(double)target, reach4, kTrainSteps, (double)ratio);
			LogA("[mlt] 🏁     %s 「넣으면 싸지나」 문턱 2.0배\n", (ratio >= 2.0f) ? "✅" : "⛔");
		}
	}
};
