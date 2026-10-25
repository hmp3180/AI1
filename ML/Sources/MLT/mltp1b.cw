// mltp1b.cw — 🧨 **P1b · 간섭 베이스라인.** *"표준 트랜스포머가 write-side 를 얼마나 덮나"*
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문** — ⚠️ 재기 전에 적는다. 정본은 `MLT.md` 의 P1b 절이다.
// ══════════════════════════════════════════════════════════════════════════════
//
// ★ **왜 이 자리인가 — 그리고 왜 「그러니까 희소 갱신을 만들자」로 가면 안 되나**
//
//   형제 트랙의 실측이 이 트랙의 가장 큰 미해결점을 지목했다:
//   **읽기 라우팅은 −2.1%p**(게이트를 균등으로 바꿔도 아무 일도 안 했다) ↔
//   **갱신을 묶음별로 나누자 +21.7%p.**
//   ⇒ 어텐션은 *"지금 무엇을 볼까"* 를 훌륭히 푼다. 그런데 **SGD 는 현재 경험의 기울기를 같은
//   전역 가중치에 넣는다** ⇒ `A 배움 → B 배움 → A 의 가중치도 같이 바뀐다` 가 **살아 있다.**
//
//   ⚠️⚠️ **그래도 「희소 갱신을 만들자」로 바로 가지 않는다** — 그것이 「폭을 먼저 재라」를 어기는
//     것이다. ***먼저 표준 트랜스포머가 실제로 얼마나 덮는지 잰다.***
//   ⇒ **이 회차는 아무것도 만들지 않는다. 폭만 잰다.**
//
//   ⭐ 그리고 **회차 8 이 이것을 더 급하게 만들었다**: 축이 서로를 **돕는다**는 것이 확인됐다
//     (한 축이 물어본 값 구간을 다른 축이 물려받았다). 도움과 덮음은 **같은 통로**를 쓴다 —
//     같은 전역 가중치에 기울기가 들어간다 ⇒ **도움이 크면 덮음도 클 수 있다.**
//
// ══════════════════════════════════════════════════════════════════════════════
// ① 과제군 — **P1 의 축을 과제로 쓴다**(등록문의 그 문장)
// ══════════════════════════════════════════════════════════════════════════════
//   ```
//   과제 A = 축 y      (표적을 y 행에만 준다 — 나머지 행은 손실에서 뺀다)
//   과제 B = 축 yaw
//   과제 C = 축 pitch  ← **처음 보는 조합**(A·B 단계에서 한 번도 표적이 아니었다)
//   ```
//   ⚠️ **값은 세 축 다 컨텍스트에 있다** — 바뀌는 것은 **표적**뿐이다. 그것이 「과제」의 정의다
//     (입력을 바꾸면 그것은 다른 실험이다 — `mltconcept.md` 의 「끊는다 두 종류」).
//
// ══════════════════════════════════════════════════════════════════════════════
// ② 팔 셋
// ══════════════════════════════════════════════════════════════════════════════
//   | 팔 | 단계 | 무엇을 답하나 |
//   |---|---|---|
//   | **I**(간섭) | `A 300 → B 300 → C 150` | ㉠ 낙폭 · ㉡ 선택성 · ㉥⁺ C 가 싸지나 |
//   | **R**(같은 비용) | `A 600` | ㉢ **같은 걸음 수**에서 A 가 어디까지 가나 |
//   | **F**(신선) | `C 150` | ㉥⁺ 의 분모 — 아무것도 안 배운 모델이 C 를 얼마에 배우나 |
//   ⚠️ **팔 R 이 없으면 낙폭을 「더 돌려서 나빠진 것」과 못 가른다** — 등록문 ㉢ 이 그 자리다.
//   ★ 비용: 씨앗당 `750 + 600 + 150 = 1500` 스텝 ⇒ 12 씨앗 × 7.4ms ≈ **2분**(풀 업로드 뒤라 값싸다).
//
// ══════════════════════════════════════════════════════════════════════════════
// ③ 읽는 칸과 문턱 — ⚠️ **손으로 먼저 잡았다**
// ══════════════════════════════════════════════════════════════════════════════
//   `R_x(단계)` = 축 `x` 의 `(학습 − 복사) / (베이즈 − 복사)`, 그 단계가 끝난 직후.
//   ★ **낙폭 = `R_A(B 뒤) − R_A(A 뒤)`** (음수면 덮인 것이다).
//
//   **SE 계산**(⚠️ 회차 6 에서 「SE 를 안 붙였다」를 부채로 적었다 ⇒ 이번엔 붙인다):
//     회차 7 의 실행별 `R` 이 0.60~0.72 였다 ⇒ 씨앗 간 SD ≈ 0.04 ⇒ SE ≈ 0.04/√12 = **0.012**.
//     낙폭은 **같은 씨앗의 짝**이므로 그보다 작지만 보수적으로 SE(낙폭) ≈ **0.017** 로 둔다.
//   **문턱**(등록문의 해석 분기를 숫자로)
//     · `|낙폭| < 0.05` (≈3·SE) ⇒ ***"덮음이 작다 — 아무것도 만들지 않는다."*** 그 숫자를 남긴다.
//     · `낙폭 ≤ −0.15` (≈9·SE) ⇒ ***"크다 — write-side 손잡이의 폭 재기로 간다."***
//     · 그 사이 ⇒ ***"중간"*** — ⚠️ **한 번 더 재고 결정한다**(단정하지 않는다).
//   **부호검정**은 **낙폭의 부호**에 건다 ⇒ **10/12**.
//   ⚠️ 봉우리를 고른 지표(낙폭)와 검정을 건 지표가 **같다**.
//
//   **관문**
//     ㉠ ★ 낙폭을 위 셋 중 하나로 판정한다(그리고 부호검정을 함께 적는다)
//     ㉡ **선택적인가** — B 를 배운 뒤 **B 자신은 살아 있나**(`R_B(B 뒤) ≥ 0.5 · R_A(A 뒤)`).
//        ⚠️ 전부 나빠지면 **학습기를 망친 것**이고 그때 낙폭은 간섭의 크기가 아니다 ⇒ **판정불가**.
//     ㉢ **같은 비용** — 팔 R 의 `R_A(600)` 이 팔 I 의 `R_A(A 뒤)` 보다 **낮지 않나**.
//        ⚠️ 낮으면 「더 돌리면 나빠지는 구간」이라 낙폭의 해석이 흐려진다 ⇒ 그것을 적는다.
//     ㉣ **배관** — `probs` 합 1.0 ± 0.01 · 전 구간 유한
//     ㉥⁺ ⭐ **「넣으면 싸지나」** — 팔 I 가 C 를 배우는 곡선 ↔ 팔 F 의 그것. **몇 배**로 적는다.
//        ⚠️ 팔 F 가 팔 I 의 최종 `R_C` 에 못 닿으면 **판정불가**(억지로 수를 만들지 않는다).
//
//   ⚠️⚠️ **관문 ㉣(`lr/N` 대조군)은 이 회차에 없다** — 등록문의 그 관문은 「낙폭이 **줄었다**」를
//     주장할 때 «주소냐 유효 학습률이냐» 를 가르는 자리다. **이 회차는 아무것도 줄이지 않는다**
//     (폭만 잰다) ⇒ 대조할 대상이 없다. ★ **낙폭 감소를 처음 주장하는 회차에 등록해서 켠다.**
//     ⚠️ 조용히 빼지 않고 여기 적는다.

using namespace PE;

class MLTP1b
{
public:
	static bool Done() { return _run >= kRuns; }

	static void Tick(RHI* rhi)
	{
		if (_run >= kRuns || rhi == nullptr) return;
		if (MLTModelCfg::kAxes != MLTP1::kAxes || MLTModelCfg::kTime != MLTP1::kTime)
		{
			LogA("[mlt] 🧨 ⛔⛔ **P1b 는 축 %u · 시각 %u 를 전제한다**\n", MLTP1::kAxes, MLTP1::kTime);
			_run = kRuns; return;
		}
		// ⚠️ **기본에서 껐다** — 회차 9 로 쟀다. ★ 다시 돌리려면 `-mltp1b`.
		if (!OS::CommandLine::Has("-mltp1b"))
		{
			LogA("[mlt] 🧨 P1b 간섭 베이스라인은 **꺼져 있다**(`-mltp1b`) — 기록: 낙폭 **−0.543**"
			     " · 부호검정 12/12 · 전이 **3.0배**\n");
			_run = kRuns;
			return;
		}
		if (!_banner) { _Banner(); _banner = true; }

		if (_st == kInit)
		{
			if (!_M.Setup(rhi)) { LogA("[mlt] 🧨 준비 실패(run %u)\n", _run); _run = kRuns; return; }
			for (uint32 a = 0; a < MLTP1::kAxes; ++a)
				MLTP1::_Baseline(a, kHold, _Seed(_run), 1u, kEvalEpi0, kEvalEpis, _bC[a], _bB[a]);
			_ph = 0u; _step = 0u; _probe = 0u; _finite = true;
			for (uint32 p = 0; p < kPhMax; ++p)
				for (uint32 a = 0; a < MLTP1::kAxes; ++a) _phR[p][a] = 0.0f;
			for (uint32 p = 0; p < kProbes; ++p) _curveC[p] = 0.0f;
			_st = kTrain;
			return;
		}

		if (_st == kTrain)
		{
			if (_step > 0u)
			{
				float ls = 0.0f;
				if (!_M.ReadLoss(ls)) { LogA("[mlt] 🧨 손실 리드백 실패\n"); _run = kRuns; return; }
				if (!(ls == ls) || ls > 1.0e30f) _finite = false;
			}
			const uint32 nPh = _NumPhases(_run);
			if (_ph >= nPh) { _Finish(); return; }
			const uint32 want = _PhaseSteps(_run, _ph);

			// ⭐ C 단계에서만 곡선 점을 찍는다(「몇 배」의 재료)
			if (_IsPhaseC(_run, _ph) && _probe < kProbes && _step >= kProbeAt[_probe])
			{ _StartEval(kEvProbe); return; }
			if (_step >= want) { _StartEval(kEvPhase); return; }

			// ⏱️ 풀 경계에서만 업로드(회차 7 의 40배)
			const uint32 K = MLTModelCfg::kPool;
			const uint32 slot = _step % K;
			if (slot == 0u)
			{
				const uint32 n = ((want - _step) < K) ? (want - _step) : K;
				_pv.Reset(0); _pt.Reset(0);
				for (uint32 k = 0; k < n; ++k)
				{
					Array<float> v, g;
					_Batch(_Seed(_run), _EpiBase(_run, _ph) + (_step + k) * MLTModelCfg::kBatch,
						_PhaseAxis(_run, _ph), v, g);
					for (uint32 i = 0; i < v.Count(); ++i) _pv.Add(v[i]);
					for (uint32 i = 0; i < g.Count(); ++i) _pt.Add(g[i]);
				}
				if (!_M.UploadPool(_pv, _pt, n)) { LogA("[mlt] 🧨 풀 업로드 실패\n"); _run = kRuns; return; }
			}
			_M.SelectStep(slot);
			if (!_M.Forward() || !_M.Backward() || !_M.AdamStep())
			{ LogA("[mlt] 🧨 스텝 실패(ph %u · step %u)\n", _ph, _step); _run = kRuns; return; }
			++_step;
			return;
		}

		if (_st == kEvalUp)
		{
			if (_eb >= kEvalB) { _EvalDone(); return; }
			// ⚠️ 시험은 **세 축 다 표적을 준다** — 어느 축이 살아 있나를 봐야 한다.
			_Batch(_Seed(_run), kEvalEpi0 + _eb * MLTModelCfg::kBatch, kAllAxes, _ev, _et);
			if (!_M.Upload(_ev, _et)) { LogA("[mlt] 🧨 시험 업로드 실패\n"); _run = kRuns; return; }
			if (!_M.Forward()) { LogA("[mlt] 🧨 시험 forward 실패\n"); _run = kRuns; return; }
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
					m.Add((_Axis(r) == a) ? 1.0f : 0.0f);
				uint32 h = 0u, n = 0u, hb = 0u, nb = 0u;
				float dd = 0.0f, ddb = 0.0f, ddo = 0.0f;
				if (!_M.ReadHits(_et, m, h, n, hb, nb, sp, dd, ddb, ddo))
				{ LogA("[mlt] 🧨 리드백 실패\n"); _run = kRuns; return; }
				_hit[a] += hb; _cnt[a] += nb;
			}
			_sumP += sp;
			++_eb;
			_st = kEvalUp;
		}
	}

private:
	static constexpr uint32 kSeed0 = 12u, kSeeds = 12u;
	static constexpr uint32 kRuns = kSeeds * 3u;      // 팔 I · R · F
	static constexpr int    kHold = MLTWorldCfg::kHoldMid;
	static constexpr uint32 kEvalEpi0 = 0u, kEvalB = 4u;
	static constexpr uint32 kEvalEpis = kEvalB * MLTModelCfg::kBatch;
	static constexpr uint32 kStepsAB = 300u, kStepsC = 150u, kStepsR = 600u;
	static constexpr uint32 kPhMax = 3u;
	static constexpr uint32 kAllAxes = 99u;           // 「세 축 다 표적」 표식
	static constexpr uint32 kProbes = 4u;
	static constexpr uint32 kProbeAt[kProbes] = { 25u, 50u, 100u, 150u };
	// ③ 의 문턱 — ⚠️ **손으로 먼저 잡았다**(SE ≈ 0.017)
	static constexpr float  kSmall = 0.05f;    // 3·SE ⇒ 「작다 — 아무것도 만들지 않는다」
	static constexpr float  kBig   = 0.15f;    // 9·SE ⇒ 「크다 — 폭 재기로 간다」
	static constexpr uint32 kSignNeed = 10u;
	static constexpr float  kAliveFrac = 0.5f; // ㉡ 선택성

	// 팔: 0..11 = I(간섭) · 12..23 = R(같은 비용) · 24..35 = F(신선)
	static bool _IsI(uint32 r) { return r < kSeeds; }
	static bool _IsR(uint32 r) { return r >= kSeeds && r < kSeeds * 2u; }
	static uint32 _Seed(uint32 r) { return kSeed0 + (r % kSeeds); }
	static uint32 _Axis(uint32 r) { return (r % MLTModelCfg::kCtx) % MLTP1::kAxes; }

	static uint32 _NumPhases(uint32 r) { return _IsI(r) ? 3u : 1u; }
	static uint32 _PhaseAxis(uint32 r, uint32 ph)
	{
		if (_IsI(r)) return ph;                 // 0=y(A) · 1=yaw(B) · 2=pitch(C)
		return _IsR(r) ? 0u : 2u;               // R = A · F = C
	}
	static uint32 _PhaseSteps(uint32 r, uint32 ph)
	{
		if (_IsI(r)) return (ph < 2u) ? kStepsAB : kStepsC;
		return _IsR(r) ? kStepsR : kStepsC;
	}
	static bool _IsPhaseC(uint32 r, uint32 ph) { return _PhaseAxis(r, ph) == 2u; }
	// ⚠️ 단계마다 **다른 에피소드 구간**을 쓴다 — 같은 데이터를 다시 보면 그것은 복습이다.
	static uint32 _EpiBase(uint32 r, uint32 ph) { return 1000u + ph * 20000u + (_IsI(r) ? 0u : 100000u); }

	enum { kInit = 0, kTrain, kEvalUp, kEvalRd };
	enum { kEvPhase = 0, kEvProbe };

	inline static MLTModel _M;
	inline static bool _banner = false;
	inline static uint32 _run = 0u, _ph = 0u, _step = 0u, _eb = 0u, _probe = 0u;
	inline static int _st = kInit, _evKind = kEvPhase;
	inline static bool _finite = true;
	inline static float _sumP = 0.0f;
	inline static uint32 _hit[MLTP1::kAxes] = { 0u }, _cnt[MLTP1::kAxes] = { 0u };
	inline static MLTP1::Base _bC[MLTP1::kAxes], _bB[MLTP1::kAxes];
	inline static float _phR[kPhMax][MLTP1::kAxes] = { { 0.0f } };
	inline static float _curveC[kProbes] = { 0.0f };
	inline static Array<float> _ev, _et, _pv, _pt;

	inline static float _rPhR[kRuns][kPhMax][MLTP1::kAxes] = { { { 0.0f } } };
	inline static float _rCurve[kRuns][kProbes] = { { 0.0f } };
	inline static bool  _rOk[kRuns] = { false };

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🧨 **P1b 간섭 베이스라인** — `A(y) → B(yaw) → C(pitch)` · 씨앗 %u~%u · %u 실행\n",
			kSeed0, kSeed0 + kSeeds - 1u, kRuns);
		LogA("[mlt] 🧨   팔 I = A%u→B%u→C%u · 팔 R = A%u(같은 비용) · 팔 F = C%u(신선)\n",
			kStepsAB, kStepsAB, kStepsC, kStepsR, kStepsC);
		LogA("[mlt] 🧨   낙폭 = R_A(B 뒤) − R_A(A 뒤) · 문턱 |낙폭|<%.2f 작다 / ≤−%.2f 크다"
		     " · 부호검정 %u/12 (SE≈0.017)\n", (double)kSmall, (double)kBig, kSignNeed);
		LogA("[mlt] 🧨   ⚠️ **이 회차는 아무것도 만들지 않는다 — 폭만 잰다**(「폭을 먼저 재라」)\n");
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
		float R[MLTP1::kAxes];
		for (uint32 a = 0; a < MLTP1::kAxes; ++a)
		{
			const float acc = _cnt[a] ? (float)_hit[a] / (float)_cnt[a] : 0.0f;
			const float w = _bB[a].acc - _bC[a].acc;
			R[a] = (w > 1.0e-4f) ? (acc - _bC[a].acc) / w : 0.0f;
		}
		if (_evKind == kEvProbe)
		{
			_curveC[_probe] = R[2];
			++_probe;
			_st = kTrain;
			return;
		}
		// 단계가 끝났다
		for (uint32 a = 0; a < MLTP1::kAxes; ++a) _phR[_ph][a] = R[a];
		LogA("[mlt] 🧨 [%2u/%u] 팔%s 씨앗%2u · 단계 %u(축 %s %u스텝) 뒤 · R = %.3f/%.3f/%.3f\n",
			_run + 1u, kRuns, _IsI(_run) ? "I" : (_IsR(_run) ? "R" : "F"), _Seed(_run),
			_ph, MLTP1::AxisName(_PhaseAxis(_run, _ph)), _PhaseSteps(_run, _ph),
			(double)R[0], (double)R[1], (double)R[2]);
		++_ph;
		_step = 0u; _probe = 0u;
		_st = kTrain;
	}

	// 표적을 **한 축에만**(또는 `kAllAxes` 면 전부) 준다. ⚠️ 값은 언제나 세 축 다 준다.
	static void _Batch(uint32 seed, uint32 epi0, uint32 tgtAxis, Array<float>& val, Array<float>& tgt)
	{
		typedef MLTModelCfg M;
		const uint32 A = MLTP1::kAxes, T = MLTP1::kTime;
		val.Reset(0); tgt.Reset(0);
		float v[MLTP1::kAxes][MLTP1::kTime + 1u];
		for (uint32 b = 0; b < M::kBatch; ++b)
		{
			for (uint32 a = 0; a < A; ++a) MLTP1::_Episode(a, seed, epi0 + b, kHold, v[a], nullptr);
			for (uint32 t = 0; t < T; ++t)
				for (uint32 a = 0; a < A; ++a)
				{
					val.Add(v[a][t]);
					const bool on = (tgtAxis == kAllAxes) || (a == tgtAxis);
					tgt.Add(on ? (float)MLTP0::Bucket(v[a][t + 1u]) : M::kIgnoreTgt);
				}
		}
	}

	static void _Finish()
	{
		const float sp = (_eb > 0u) ? _sumP / (float)_eb : 0.0f;
		for (uint32 p = 0; p < kPhMax; ++p)
			for (uint32 a = 0; a < MLTP1::kAxes; ++a) _rPhR[_run][p][a] = _phR[p][a];
		for (uint32 p = 0; p < kProbes; ++p) _rCurve[_run][p] = _curveC[p];
		_rOk[_run] = _finite && (Abs(sp - 1.0f) <= 0.01f);
		if (!_rOk[_run]) LogA("[mlt] 🧨      ⛔ 배관(run %u · probs 합 %.4f)\n", _run, (double)sp);
		++_run;
		_st = kInit;
		if (_run >= kRuns) _Judge();
	}

	static void _Judge()
	{
		float dropSum = 0.0f, aAfterA = 0.0f, aAfterB = 0.0f, bAfterB = 0.0f, aRef = 0.0f;
		uint32 signNeg = 0u;
		bool plumb = true;
		for (uint32 i = 0; i < kSeeds; ++i)
		{
			const float a0 = _rPhR[i][0][0];              // R_A(A 뒤)
			const float a1 = _rPhR[i][1][0];              // R_A(B 뒤)
			const float b1 = _rPhR[i][1][1];              // R_B(B 뒤)
			dropSum += (a1 - a0);
			aAfterA += a0; aAfterB += a1; bAfterB += b1;
			aRef += _rPhR[kSeeds + i][0][0];              // 팔 R 의 R_A(600)
			if ((a1 - a0) < 0.0f) ++signNeg;
			if (!_rOk[i] || !_rOk[kSeeds + i] || !_rOk[kSeeds * 2u + i]) plumb = false;
		}
		const float k = 1.0f / (float)kSeeds;
		const float drop = dropSum * k;
		aAfterA *= k; aAfterB *= k; bAfterB *= k; aRef *= k;

		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🧨 **P1b 결과 — 간섭의 폭**\n");
		LogA("[mlt] 🧨   R_A(A 뒤) **%.3f** → R_A(B 뒤) **%.3f**  ⇒ ★ **낙폭 %+.3f**"
		     " (부호검정 음수 **%u/12**)\n", (double)aAfterA, (double)aAfterB, (double)drop, signNeg);
		LogA("[mlt] 🧨   R_B(B 뒤) %.3f · 팔R 의 R_A(600스텝) %.3f\n", (double)bAfterB, (double)aRef);

		int fail = 0;
		if (!plumb) { LogA("[mlt] 🧨   ⛔ ㉣ 배관이 깨진 실행이 있다 — **판정불가**\n"); ++fail; }
		else          LogA("[mlt] 🧨   ✅ ㉣ 배관 — probs 합 1.0 · 전 구간 유한\n");

		const bool g2 = (bAfterB >= kAliveFrac * aAfterA);
		LogA("[mlt] 🧨   %s ㉡ 선택성 — R_B(B 뒤) %.3f ≥ %.2f × R_A(A 뒤) %.3f = %.3f"
		     " (전부 나빠지면 **학습기를 망친 것**)\n",
			g2 ? "✅" : "⛔", (double)bAfterB, (double)kAliveFrac, (double)aAfterA,
			(double)(kAliveFrac * aAfterA));
		if (!g2) ++fail;

		const bool g3 = (aRef >= aAfterA);
		LogA("[mlt] 🧨   %s ㉢ 같은 비용 — 팔R 의 R_A(600) %.3f ≥ 팔I 의 R_A(A뒤) %.3f"
		     " (낮으면 「더 돌리면 나빠지는 구간」이라 낙폭 해석이 흐려진다)\n",
			g3 ? "✅" : "⛔", (double)aRef, (double)aAfterA);
		if (!g3) ++fail;

		// ㉠ — ⚠️ 해석 분기는 **미리 등록해 뒀다**
		LogA("[mlt] 🧨   ── ㉠ 낙폭의 판정 ──\n");
		if (fail > 0)
			LogA("[mlt] 🧨   ⛔ 앞 관문이 깨졌다 ⇒ **낙폭을 간섭의 크기로 읽지 않는다**\n");
		else if (Abs(drop) < kSmall)
			LogA("[mlt] 🧨   ✅ **덮음이 작다**(|%+.3f| < %.2f) ⇒ ***아무것도 만들지 않는다.***"
			     " 그 숫자를 남긴다\n", (double)drop, (double)kSmall);
		else if (drop <= -kBig && signNeg >= kSignNeed)
			LogA("[mlt] 🧨   ⚠️⚠️ **덮음이 크다**(%+.3f ≤ −%.2f · 부호 %u/12) ⇒ ***write-side 손잡이의"
			     " 폭 재기로 간다.*** ⚠️ 「희소 갱신을 만들자」로 바로 가지 마라\n",
				(double)drop, (double)kBig, signNeg);
		else
			LogA("[mlt] 🧨   ⚠️ **중간**(%+.3f · 부호 %u/12) ⇒ **한 번 더 재고 결정한다**(단정하지 않는다)\n",
				(double)drop, signNeg);

		_JudgeCurve();
		LogA("[mlt] 🧨   ⓘ ⚠️ 관문 `lr/N` 은 이 회차에 **없다** — 그것은 「낙폭이 **줄었다**」를"
		     " 주장할 때의 대조군이고 이 회차는 아무것도 줄이지 않는다(폭만 잰다)\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

	// ⭐ 「넣으면 싸지나」 — 팔 I 가 C 를 배우는 곡선 ↔ 팔 F(신선)
	static void _JudgeCurve()
	{
		float cI[kProbes] = { 0.0f }, cF[kProbes] = { 0.0f };
		for (uint32 p = 0; p < kProbes; ++p)
		{
			float si = 0.0f, sf = 0.0f;
			for (uint32 i = 0; i < kSeeds; ++i)
			{ si += _rCurve[i][p]; sf += _rCurve[kSeeds * 2u + i][p]; }
			cI[p] = si / (float)kSeeds; cF[p] = sf / (float)kSeeds;
		}
		LogA("[mlt] 🧨   ⭐ ㉥⁺ 「넣으면 싸지나」 — 축 pitch(C) 의 `R(step)`\n");
		LogA("[mlt] 🧨     팔I(A·B 를 배운 뒤): ");
		for (uint32 p = 0; p < kProbes; ++p) LogA("%u→%.3f  ", kProbeAt[p], (double)cI[p]);
		LogA("\n[mlt] 🧨     팔F(신선)          : ");
		for (uint32 p = 0; p < kProbes; ++p) LogA("%u→%.3f  ", kProbeAt[p], (double)cF[p]);
		LogA("\n");
		const float target = cF[kProbes - 1u];
		uint32 reach = 0u;
		for (uint32 p = 0; p < kProbes; ++p) if (cI[p] >= target) { reach = kProbeAt[p]; break; }
		if (reach == 0u)
			LogA("[mlt] 🧨     ⇒ ⚠️ **판정불가** — 팔I 가 팔F 의 최종 R(%.3f)에 곡선 안에서 못 닿았다\n",
				(double)target);
		else
			LogA("[mlt] 🧨     ⇒ 팔I 가 팔F 의 최종 R(%.3f)에 **%u 스텝**에 닿는다 (팔F 는 %u)"
			     " ⇒ **%.1f배 싸다**\n", (double)target, reach, kProbeAt[kProbes - 1u],
				(double)((float)kProbeAt[kProbes - 1u] / (float)reach));
	}
};
