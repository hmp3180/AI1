// mltp2omp.cw — 🎯 **P2 걸음 11/14 · OMP와 잔차 1회 오라클: 「선택의 여지」를 정직하게 잰다.**
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문** — ⚠️ 재기 **전에** 적는다. ★ 이것은 **손잡이가 아니라 측정**이다.
// ══════════════════════════════════════════════════════════════════════════════
//
// ① **왜 이 측정인가** — 회차 29 가 남긴 자리다:
//    · `㉯`(모델의 ids · **계수 최적**)가 **0.0279 / 0.0239** 인데 ㉠ 문턱은 **0.0171**
//      (씨앗별 통과선 = 자기 대조군의 절반 · 평균 **0.0160**).
//    ⇒ ★ **선택을 고정한 채로는 계수를 완벽하게 해도 문턱을 못 넘는다.** 남는 여지는 **선택**뿐이다.
//    ⚠️ 그런데 회차 27 의 오라클(평범한 정합추적)은 **모델보다 나빴다**(학습에서 1.79배) ⇒ 상한이
//      아니었고, 그래서 **그 여지의 크기를 우리가 아직 모른다.**
//    ⇒ **OMP**(직교 정합추적)로 다시 잰다 — 원소를 더할 때마다 **고른 것 전체**를 최소제곱으로 다시
//      풀므로 잔차가 선택 부분공간에 **직교**하고, 같은 선택에서 **최선의 계수**를 늘 쓴다.
//
// ② ⭐ **표제 판정 — 문턱이 `k=8` 에서 도달 가능한가**
//    씨앗마다 `OMP(시험) < 통과선`(= 0.5 × 그 씨앗의 시험 대조군)인지 센다.
//    ```
//    ㈀ 12/12 (또는 11/12 이상) ⇒ **문턱은 `k=8` 에서 도달 가능** ⇒ 문제는 **순전히 선택**이다
//    ㈁ 6/12 이하              ⇒ **`k=8` 로는 등록된 문턱이 원리적으로 안 된다**
//                                ★ 그것은 **등록에 대한 사실**이고 모델의 실패가 아니다
//    ㈂ 그 사이               ⇒ 씨앗에 따라 갈린다 ⇒ 씨앗별 표를 읽는다
//    ```
//    ⚠️ OMP 도 **최적 부분집합은 아니다**(그것은 NP-난해다) ⇒ ㈁ 이어도 *"절대 불가능"* 이 아니라
//      **"우리가 아는 가장 강한 선택으로도 안 된다"** 다. 그 차이를 적어 둔다.
//
// ③ ⭐ **구현 검증 관문**(이게 없으면 ㈁ 을 믿을 수 없다)
//    ㉠ **OMP < 회차 27 의 greedy**(0.02264) — 더 강한 절차니까 당연히 그래야 한다.
//    ㉡ **OMP(학습) < 모델(학습)** — 회차 27 의 greedy 는 여기서 **졌다**(0.02196 vs 0.01229).
//       ★ OMP 가 여전히 지면 **구현이 약한 것**이고 ㈁ 을 결론으로 쓸 수 없다.
//    ⚠️ 이 둘을 통과하지 못하면 표제 판정은 **판정불가**로 찍는다.
//
// ④ **설정은 회차 27~29 의 기준 팔과 같다**(k=8 · N=1000 · 학습 128프레임 · 4800스텝 ·
//    시험 **다른 에피소드** · `act_topk`). ⇒ 절대값이 그 회차들과 나란히 읽힌다.
//
// ⑤ ⭐ 같이 찍는 것: 모델 · ㉯(ids 고정·계수 최적) · **OMP** · 그리고 **학습 쪽 셋** ·
//    씨앗별 통과선. ⚠️ 씨앗 10 은 따로 적는다(회차 24·25 의 부채).
//
// ⑥ ⚠️ 값 — 학습은 한 팔(십 분 안) · OMP 는 CPU 에서 씨앗당 ~2초
//    (`k·N·픽셀·패치` + 작은 최소제곱 여덟 번).
//
// ══════════════════════════════════════════════════════════════════════════════
// 🧾 **결과(회차 30) — ⭐ 문턱은 `k=8` 에서 도달 가능하다. 범인은 「선택+계수」다.**
// ══════════════════════════════════════════════════════════════════════════════
//   | | 시험 | 학습 |
//   |---|---|---|
//   | 모델 | **0.03977** | 0.01229 |
//   | ㉯ ids 고정 · 계수 최적 | **0.02789** | — |
//   | ⭐ **OMP**(선택+계수 최적) | **0.01505** | **0.01134** |
//   | **통과선**(0.5 × 대조군 0.03198) | **0.01599** | — |
//
//   · ⭐ **구현 검증 둘 다 통과**: OMP **0.01505** < greedy(회차 27) 0.02264 ✅ ·
//     OMP(학습) **0.01134** < 모델(학습) 0.01229 ✅ ⇒ 이제 오라클이 **정말 상한 쪽**이다.
//     ★ 회차 27 의 결함(greedy 가 모델보다 나빴다)이 **원인까지 밝혀져** 갚였다: 계수를 다시 안 풀어서였다.
//   · ⭐ **OMP 평균이 통과선 아래다**(0.01505 < 0.01599) · 씨앗 **8/12** 통과
//     ⇒ 등록된 갈래로는 **㈂**(8 은 11 과 6 사이)이지만 **읽기는 분명하다**:
//       **문턱은 `k=8`·`N=1000`·이 코드북에서 사실상 도달 가능**하다.
//     ⚠️ 등록된 문턱(≥11/12)을 못 넘었으므로 *"도달 가능하다"* 를 **판정으로 쓰지 않는다** — 그것은
//       **읽기**다. ★ 그 구분을 흐리면 등록이 뜻을 잃는다.
//   · ⭐ **모델은 OMP 의 2.64배**다. 초과분(0.03977 − 0.01505 = 0.02472)을 쪼개면:
//     ```
//     계수 탓  0.03977 → 0.02789   = 0.01188  (48%)
//     선택 탓  0.02789 → 0.01505   = 0.01284  (52%)
//     ```
//     ⇒ **거의 반반**이고 **둘 다 고쳐야** 한다. 어느 하나만으로는 문턱에 못 간다
//       (계수만 = 0.0279 ≫ 0.016 · 회차 29 가 이미 그 자리를 봤다).
//   · ⭐ **코드북은 무죄다** — 같은 코드북으로 OMP 가 문턱 아래로 간다.
//     ⇒ 회차 23~26·28 이 사전 쪽 손잡이를 다섯 번 돌렸는데 넷이 헛수고였던 이유가 **완전히** 설명된다.
//   · ⓘ 씨앗별 `OMP/통과선`: 1.34 0.71 1.03 0.74 0.88 0.71 0.92 0.83 0.72 1.06 1.41 0.90
//     ⚠️ 씨앗 10 은 여기서도 최악 쪽(1.41)이지만 **모델 0.2287 → OMP 0.0318** 로 **7배**가 준다
//     ⇒ 그 씨앗의 문제도 **선택**이다(세계가 이상한 것이 아니다). ★ 회차 24 의 부채가 여기서 풀린다.
//
// ══════════════════════════════════════════════════════════════════════════════
// 📌 **걸음 12 등록 — ⭐ 「한 겹 선형으로는 OMP 를 흉내낼 수 없다」**
// ══════════════════════════════════════════════════════════════════════════════
//   ★ 지금 픽셀 → 점수 경로는 **통째로 선형**이다:
//     `patch = Σ 자리표 행`(선형) → `score = patch · Wd`(선형) ⇒ 합쳐도 **한 겹 선형**.
//     반면 OMP 는 **반복적이고 데이터 의존적**이다(잔차를 보고 다음을 고른다).
//     ⇒ 한 겹 선형이 OMP 를 흉내낼 수 없는 것은 **당연**하고, 그것이 2.64배의 정체 후보다.
//   ⇒ **팔 둘**: ㈀ 지금 그대로 ↔ ㈁ **비선형 한 겹**을 넣는다
//     `h = swiglu(patch·W1a, patch·W1b)` → `score = h · Wd`.
//     ⭐ **새 커널 0개** — `swiglu` 는 판정 ①② 를 **이미 통과**했다(fwd·bwd 둘 다).
//   ⚠️ **예산 관문을 다시 센다** — 파라미터가 는다(`W1a`·`W1b`: `D×H` 둘). `MLT.md` 의 인코더
//     **≤ 0.5M**(살아있는 파라미터)을 넘으면 그 팔은 **자격이 없다**.
//   ⚠️ 그리고 **용량으로 밀지 않기 위한 대조**가 필요하다: ㈁ 이 좋아지면 *"비선형이 좋았나 파라미터가
//     늘어서 좋았나"* 가 갈리지 않는다 ⇒ ⭐ **팔 셋째**를 둔다 — ㈂ **같은 파라미터 수의 선형 두 겹**
//     (`h = patch·W1a` → `score = h·Wd`, 활성 없음). 그것이 좋아지면 **비선형이 아니라 용량**이다.
//   ⚠️ 관문은 ㉠ **그대로**(0.01710 · 씨앗별 11/12) + ⭐ **OMP 대비 비**(모델/OMP · 지금 2.64)를 함께 잰다.

using namespace PE;

class MLTP2Omp
{
public:
	static void Tick(RHI* rhi)
	{
		if (_done || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltp2omp") && !OS::CommandLine::Has("-mltp2swap"))
		{
			LogA("[mlt] 🔁 걸음 14(잔차 1회 교체)은 **꺼져 있다**(`-mltp2swap`) — 회차 35:"
			     " ㉯ **0.02789** → 1회 **0.01998** → OMP **0.01505** · 회수율 **61.6%%**"
			     " ⇒ 다음 = 최소 잔차 반복 모델\n");
			_done = true;
			return;
		}
		if (!_banner) { _Banner(); _banner = true; }
		if (_st == kInit)  { _BeginSeed(rhi); return; }
		if (_st == kTrain) { _Train();        return; }
		if (_st == kEval)  { _Eval();         return; }
	}

	static bool Done() { return _done; }

private:
	static constexpr uint32 kSeeds = 12u;
	static constexpr uint32 kTrainF = 128u, kTestF = 8u;
	static constexpr uint32 kPoolCap = kTrainF + kTestF;
	static constexpr uint32 kSteps = 4800u;
	static constexpr uint32 kN = 1000u, kK = 8u;
	static constexpr uint32 kPerTick = 4u, kEvalTr = 8u;
	static constexpr uint32 kTestEpisode = 1u;
	static constexpr float  kRidge = 1.0e-6f;
	static constexpr float  kBeat = 0.5f;
	static constexpr float  kGreedy27 = 0.02264f;   // ③㉠ 의 비교값(회차 27)
	static constexpr uint32 kWatchSeed = 10u;

	enum { kInit, kTrain, kEval };

	inline static MLTP2Enc _E;
	inline static bool   _banner = false, _setup = false, _done = false;
	inline static uint32 _seed = 0u;
	inline static int    _st = kInit;
	inline static uint32 _step = 0u, _ev = 0u;
	inline static double _sumTest = 0.0, _sumTrain = 0.0;
	inline static uint32 _nTest = 0u, _nTrain = 0u;
	inline static Array<float> _tgtTest, _tgtTrain, _idsTest, _code;

	inline static float _mModel[kSeeds] = { 0.0f }, _mTrainM[kSeeds] = { 0.0f };
	inline static float _mLsq[kSeeds]   = { 0.0f };
	inline static float _mSwap[kSeeds]  = { 0.0f };
	inline static float _mOmp[kSeeds]   = { 0.0f }, _mOmpTr[kSeeds] = { 0.0f };
	inline static float _mBase[kSeeds]  = { 0.0f };

	static void _Banner()
	{
		const bool swap = OS::CommandLine::Has("-mltp2swap");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🎯 **%s** — 씨앗 %u (k=%u N=%u F=%u %u스텝 · `act_topk`)\n",
			swap ? "회차 35 · 잔차 기반 1회 교체 오라클" : "P2 걸음 11 · OMP 오라클",
			kSeeds, kK, kN, kTrainF, kSteps);
		if (swap) LogA("[mlt] 🔁   현재 ids LSQ → 잔차 상관 최대 원자 추가 → 최소 기여 원자 제거 → k개 LSQ\n");
		LogA("[mlt] 🎯   ⚠️ 손잡이가 아니라 **측정**이다 — 「선택의 여지」가 얼마나 되나\n");
		LogA("[mlt] 🎯   표제: 씨앗마다 `OMP(시험) < 통과선`(= 0.5 × 자기 대조군)인지 센다\n");
		LogA("[mlt] 🎯   갈래: ≥11/12 = **문턱은 k=8 에서 도달 가능**(문제는 순전히 선택) ·"
		     " ≤6/12 = **k=8 로는 원리적으로 안 된다**(등록에 대한 사실)\n");
		LogA("[mlt] 🎯   ⭐ 구현 검증: ㉠ OMP < greedy(회차 27 의 %.5f) · ㉡ OMP(학습) < 모델(학습)\n",
			(double)kGreedy27);
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

	static void _BeginSeed(RHI* rhi)
	{
		if (!_setup)
		{
			if (!_E.Setup(rhi, kPoolCap, kN)) { LogA("[mlt] 🎯 준비 실패\n"); _done = true; return; }
			_setup = true;
		}
		else if (!_E.ResetSeed()) { LogA("[mlt] 🎯 되돌리기 실패\n"); _done = true; return; }
		_E.SetK(kK);
		_E.SetSelectAbs(false);          // ⚠️ 기준 팔(`act_topk`) — 회차 27~29 와 같다

		Array<float> fr, tg;
		fr.Reset(0); tg.Reset(0); _tgtTest.Reset(0); _tgtTrain.Reset(0);
		ImageFormat::Bitmap bmp;
		Bytes packed;
		{
			MLTWorld w;
			w.Reset(_seed, 0u, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
			for (uint32 f = 0; f < kTrainF; ++f)
			{
				w.Step();
				if (!w.Render(bmp) || !MLTWorld::Pack(bmp, nullptr, packed))
				{ LogA("[mlt] 🎯 Render/Pack 실패(학습)\n"); _done = true; return; }
				const uint8* px = (const uint8*)packed.GetData();
				MLTP2Enc::AppendFrame(fr, tg, px);
				if (f < kEvalTr)
				{
					Array<float> one, dummy; one.Reset(0); dummy.Reset(0);
					MLTP2Enc::AppendFrame(dummy, one, px);
					for (uint32 i = 0; i < one.Count(); ++i) _tgtTrain.Add(one[i]);
				}
			}
		}
		{
			MLTWorld w;
			w.Reset(_seed, kTestEpisode, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
			for (uint32 f = 0; f < kTestF; ++f)
			{
				w.Step();
				if (!w.Render(bmp) || !MLTWorld::Pack(bmp, nullptr, packed))
				{ LogA("[mlt] 🎯 Render/Pack 실패(시험)\n"); _done = true; return; }
				const uint8* px = (const uint8*)packed.GetData();
				MLTP2Enc::AppendFrame(fr, tg, px);
				Array<float> one, dummy; one.Reset(0); dummy.Reset(0);
				MLTP2Enc::AppendFrame(dummy, one, px);
				for (uint32 i = 0; i < one.Count(); ++i) _tgtTest.Add(one[i]);
			}
		}
		if (!_E.WritePool(fr, tg, kTrainF + kTestF))
		{ LogA("[mlt] 🎯 풀 업로드 실패\n"); _done = true; return; }

		_mBase[_seed] = MLTP2Enc::PatchConstMse(_tgtTest);
		_idsTest.Reset(0);
		_step = 0u; _ev = 0u; _sumTest = 0.0; _sumTrain = 0.0; _nTest = 0u; _nTrain = 0u;
		_st = kTrain;
	}

	static void _Train()
	{
		for (uint32 i = 0; i < kPerTick && _step < kSteps; ++i)
		{
			_E.SetFrame(_step % kTrainF);
			if (!_E.Forward() || !_E.Backward() || !_E.AdamStep(1.0f))
			{ LogA("[mlt] 🎯 스텝 실패(씨앗 %u 스텝 %u)\n", _seed, _step); _done = true; return; }
			++_step;
		}
		if (_step >= kSteps) { _st = kEval; _ev = 0u; }
	}

	static void _Eval()
	{
		const uint32 nEv = kTestF + kEvalTr;
		if (_ev > 0u)
		{
			const uint32 prev = _ev - 1u;
			float m = 0.0f; bool fin = true;
			if (!_E.ReadMse(m, fin)) { LogA("[mlt] 🎯 평가 리드백 실패\n"); _done = true; return; }
			if (prev < kTestF)
			{
				_sumTest += (double)m; ++_nTest;
				Array<float> id, mg;
				if (!_E.ReadAct(id, mg)) { LogA("[mlt] 🎯 선택 리드백 실패\n"); _done = true; return; }
				for (uint32 i = 0; i < id.Count(); ++i) _idsTest.Add(id[i]);
			}
			else { _sumTrain += (double)m; ++_nTrain; }
		}
		if (_ev < nEv)
		{
			_E.SetFrame((_ev < kTestF) ? (kTrainF + _ev) : (_ev - kTestF));
			if (!_E.Forward()) { LogA("[mlt] 🎯 평가 forward 실패\n"); _done = true; return; }
			++_ev;
			return;
		}
		_Measure();
	}

	static void _Measure()
	{
		typedef MLTP2Cfg C;
		if (!_E.ReadCodebook(_code)) { LogA("[mlt] 🎯 코드북 리드백 실패\n"); _done = true; return; }
		_mModel[_seed]  = (_nTest  != 0u) ? (float)(_sumTest  / (double)_nTest)  : 0.0f;
		_mTrainM[_seed] = (_nTrain != 0u) ? (float)(_sumTrain / (double)_nTrain) : 0.0f;
		const uint32 nT = _tgtTest.Count() / C::kPix;
		const uint32 nR = _tgtTrain.Count() / C::kPix;
		_mLsq[_seed]   = MLTP2Enc::LsqMse(_code, kN, _tgtTest, _idsTest, kK, nT, kRidge);
		const bool swap = OS::CommandLine::Has("-mltp2swap");
		_mSwap[_seed]  = swap ? MLTP2Enc::SwapOneMse(_code, kN, _tgtTest, _idsTest, kK, nT, kRidge) : 0.0f;
		_mOmp[_seed]   = MLTP2Enc::OmpMse(_code, kN, _tgtTest, kK, nT, kRidge);
		_mOmpTr[_seed] = MLTP2Enc::OmpMse(_code, kN, _tgtTrain, kK, nR, kRidge);

		const float pass = kBeat * _mBase[_seed];
		if (swap)
			LogA("[mlt] 🎯 [%2u/%u] 씨앗 %u — 모델 **%.5f** · ㉯ %.5f · **1회 %.5f** · **OMP %.5f** %s 통과선 %.5f"
			     " │ 학습: 모델 %.5f · OMP %.5f\n",
				_seed + 1u, kSeeds, _seed, (double)_mModel[_seed], (double)_mLsq[_seed], (double)_mSwap[_seed],
				(double)_mOmp[_seed], (_mOmp[_seed] < pass) ? "<" : "≥", (double)pass,
				(double)_mTrainM[_seed], (double)_mOmpTr[_seed]);
		else
			LogA("[mlt] 🎯 [%2u/%u] 씨앗 %u — 모델 **%.5f** · ㉯ %.5f · **OMP %.5f** %s 통과선 %.5f"
			     " │ 학습: 모델 %.5f · OMP %.5f\n",
				_seed + 1u, kSeeds, _seed, (double)_mModel[_seed], (double)_mLsq[_seed],
				(double)_mOmp[_seed], (_mOmp[_seed] < pass) ? "<" : "≥", (double)pass,
				(double)_mTrainM[_seed], (double)_mOmpTr[_seed]);

		++_seed;
		if (_seed >= kSeeds) { _Summary(); _E.Destroy(); _done = true; return; }
		_st = kInit;
	}

	static void _Summary()
	{
		double sM = 0.0, sL = 0.0, sS = 0.0, sO = 0.0, sB = 0.0, sTM = 0.0, sTO = 0.0;
		uint32 pass = 0u, trainWin = 0u;
		for (uint32 i = 0; i < kSeeds; ++i)
		{
			sM += _mModel[i]; sL += _mLsq[i]; sS += _mSwap[i]; sO += _mOmp[i]; sB += _mBase[i];
			sTM += _mTrainM[i]; sTO += _mOmpTr[i];
			if (_mOmp[i] < kBeat * _mBase[i]) ++pass;
			if (_mOmpTr[i] < _mTrainM[i]) ++trainWin;
		}
		const float mM = (float)(sM / kSeeds), mL = (float)(sL / kSeeds);
		const float mS = (float)(sS / kSeeds), mO = (float)(sO / kSeeds);
		const float mB = (float)(sB / kSeeds), mTM = (float)(sTM / kSeeds), mTO = (float)(sTO / kSeeds);

		const bool swap = OS::CommandLine::Has("-mltp2swap");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🎯 **%s 결과**(씨앗 %u 평균)\n", swap ? "잔차 1회/OMP 오라클" : "OMP 오라클", kSeeds);
		if (swap)
		{
			LogA("[mlt] 🎯   시험 — 모델 **%.5f** · ㉯(ids 고정·계수 최적) **%.5f** · **1회 교체 %.5f** · **OMP %.5f**"
			     " · 통과선 %.5f(대조군 %.5f)\n",
				(double)mM, (double)mL, (double)mS, (double)mO, (double)(kBeat * mB), (double)mB);
			const float gap = mL - mO, got = mL - mS;
			const float frac = (gap > 1.0e-9f) ? (got / gap) : 0.0f;
			LogA("[mlt] 🔁   ⭐ 1회 교체 회수율 = (㉯−1회)/(㉯−OMP) = (%.5f−%.5f)/(%.5f−%.5f) = **%.1f%%**\n",
				(double)mL, (double)mS, (double)mL, (double)mO, (double)(100.0f * frac));
			LogA("[mlt] 🔁   ⭐ 회차 35 갈래 = %s\n", (frac >= 0.5f)
				? "㈀ **절반 이상 — 최소 잔차 반복을 다음 모델 손잡이로 등록한다**"
				: "㈁ **절반 미만 — 반복 깊이별 오라클 곡선을 먼저 잰다**");
		}
		else
			LogA("[mlt] 🎯   시험 — 모델 **%.5f** · ㉯(ids 고정·계수 최적) **%.5f** · **OMP %.5f**"
			     " · 통과선 %.5f(대조군 %.5f)\n",
				(double)mM, (double)mL, (double)mO, (double)(kBeat * mB), (double)mB);
		LogA("[mlt] 🎯   학습 — 모델 **%.5f** · **OMP %.5f**\n", (double)mTM, (double)mTO);

		// ⭐ 구현 검증 먼저 — 이걸 통과 못 하면 표제는 판정불가다
		const bool v1 = (mO < kGreedy27);
		const bool v2 = (mTO < mTM);
		LogA("[mlt] 🎯   %s ㉠ 구현 검증 — OMP %.5f < greedy(회차 27) %.5f\n",
			v1 ? "✅" : "⛔", (double)mO, (double)kGreedy27);
		LogA("[mlt] 🎯   %s ㉡ 구현 검증 — OMP(학습) %.5f < 모델(학습) %.5f · 씨앗 %u/%u\n",
			v2 ? "✅" : "⛔", (double)mTO, (double)mTM, trainWin, kSeeds);

		LogA("[mlt] 🎯   ⭐ **표제** — `OMP(시험) < 통과선` 인 씨앗 **%u/%u**\n", pass, kSeeds);
		const char* branch;
		if (!v1 || !v2) branch = "⚠️ **판정불가 — 구현 검증이 실패했다**(OMP 가 충분히 강하지 않다)";
		else if (pass >= 11u) branch = "㈀ **문턱은 `k=8` 에서 도달 가능하다** ⇒ 문제는 **순전히 선택**이다";
		else if (pass <= 6u)  branch = "㈁ **`k=8` 로는 등록된 문턱이 안 된다** — ⚠️ 「우리가 아는 가장 강한"
		                              " 선택으로도 안 된다」는 뜻이다(최적 부분집합은 NP-난해라 미지다)";
		else branch = "㈂ 씨앗에 따라 갈린다 ⇒ 씨앗별 표를 읽어라";
		LogA("[mlt] 🎯   ⭐ 갈래 판정 = **%s**\n", branch);
		LogA("[mlt] 🎯   ⓘ 씨앗 %u(부채) — 모델 %.5f · OMP %.5f · 통과선 %.5f\n",
			kWatchSeed, (double)_mModel[kWatchSeed], (double)_mOmp[kWatchSeed],
			(double)(kBeat * _mBase[kWatchSeed]));
		LogA("[mlt] 🎯   ⓘ 씨앗별 OMP/통과선: ");
		for (uint32 i = 0; i < kSeeds; ++i)
			LogA("%.2f ", (double)((_mBase[i] > 1e-9f) ? (_mOmp[i] / (kBeat * _mBase[i])) : 0.0f));
		LogA("\n[mlt] ══════════════════════════════════════════════════\n");
	}
};
