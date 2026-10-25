// mltp2ab.cw — ± **P2 걸음 10 · 선택은 `|z|` · 세기는 `z` (A/B)**. 회차 27·28 이 가리킨 자리다.
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문** — ⚠️ 재기 **전에** 적는다.
// ══════════════════════════════════════════════════════════════════════════════
//
// ① **왜 여기인가 — 결함이 구체적으로 잡혔다**
//    · 회차 27: **ids 를 그대로 두고 세기만 최소제곱**으로 바꾸면 시험 오차 **30% 감소**(12/12 · p=0.00024).
//    · 회차 26·28: **크기 정규화는 두 자리 모두에서 아무것도 아니었다**(`Wd` 0.96배 · 코드북 0.70→0.72).
//    ⇒ ★ 남는 후보는 **제약의 모양**이다: `act_topk` 은 **가장 큰 점수 k개**를 골라 **그 값을 그대로
//      계수로** 쓴다 ⇒ 뽑힌 계수는 사실상 **전부 양수이고 크기도 서로 비슷하다**(어떤 행의 상위 8개니까).
//      최소제곱의 계수는 **부호도 크기도 자유롭다.** ⇒ 그 30% 의 정체 후보가 **부호·크기 제약**이다.
//    ⭐ 그래서 **「크면 뽑힌다」와 「맞으면 좋다」를 가른다**: 뽑는 기준은 **기여의 크기**(`|z|`),
//      계수는 **부호 있는 값**(`z`) 그대로. ⇒ 같은 선형사영이 **음의 계수**를 낼 수 있다.
//
// ② **커널 판정을 먼저 통과시켰다**(등록된 규율) — `act_topk_abs`:
//    · 판정 ② `dScore` **2.12e-04** ✅(선택 고정 조건부 · ★ 해석 기울기는 **`act_topk_bwd` 그대로**)
//    · 판정 ① `ids` **정확일치 0** · `mag` **오차 0** ✅ ⇒ 판정 ① **27/27**
//    · ⓘ 그리고 **진짜 다른 커널**임을 확인했다: 음수 계수 **679/1400** · 선택이 다른 칸 **1325/1400**.
//    ★ **bwd 를 새로 안 만들었다** — `mag = z[ids]` 관계가 글자 그대로 같고 선택은 상수다.
//
// ③ **팔 둘** — ㈀ `act_topk`(기존) ↔ ㈁ `act_topk_abs`.
//    설정은 회차 26·27·28 과 같다(k=8 · N=1000 · 학습 128프레임 · 4800스텝 · 시험 **다른 에피소드**).
//
// ④ ⭐ **관문 둘**
//    ㉠ **시험 MSE 가 낮아지나** — 씨앗별 짝지은 부호검정 **11/12**(`Q = 2` ⇒ 단측 p < **0.025**).
//    ㉡ ⭐ **기제 관문 — 세기 손실이 줄어드나**: `㉯/㉮`(ids 그대로·세기만 최적 / 모델).
//       회차 27·28 의 값은 **0.70 / 0.72**. ⇒ **문턱: ㈁의 `㉯/㉮` ≥ 0.85**.
//       ★ 시험 MSE 는 여러 이유로 움직이지만 이 비는 **오직 세기**를 본다.
//    ⭐ **회귀 검사**: ㈀ 은 회차 28 의 ㈀끔과 같은 설정이므로 `㉯/㉮ ≈ 0.70` 을 재현해야 한다.
//
// ⑤ ⭐ **살아 있는지 보는 칸**(관문 아님이지만 **없으면 판정이 위험하다**):
//    **뽑힌 세기의 음수 비율**. ㈁ 에서 그것이 **0 에 가까우면** 스위치가 아무 일도 안 하는 것이고,
//    그때 「효과 없음」은 **가설에 대한 정보가 아니다**(회차 26 의 그 교훈 — 팔이 살아 있나부터 본다).
//
// ⑥ ⭐ **갈래 셋을 미리 등록한다**
//    ```
//    ㈀ ㉡ 통과(≥0.85) **그리고** ㉠ 통과   ⇒ **부호·크기 제약이 범인이었고 고쳤다**
//    ㈁ ㉡ 통과인데 ㉠ 실패                ⇒ 세기는 고쳤지만 **전이는 다른 문제**다
//    ㈂ ㉡ 실패                            ⇒ 부호 제약도 아니다 ⇒ 남는 것은 **별도 계수 머리**
//                                            (`coef = patch·Wc` · ⚠️ 그때 선택의 기울기가 사라지는
//                                             문제를 함께 결정해야 한다 — 지금 등록하지 않는다)
//    ```
//
// ⑦ ⚠️ 값 — 팔 둘 × 씨앗 12 × 4800스텝 + 씨앗마다 최소제곱 ⇒ **십 분 대**.
//
// ══════════════════════════════════════════════════════════════════════════════
// 🧾 **결과(회차 29) — ㈂. 그런데 ⭐ 딴 데서 큰 것이 하나 나왔다.**
// ══════════════════════════════════════════════════════════════════════════════
//   | 팔 | 시험 | 학습 | 비 | ㉯/㉮ | 음수 세기 | 사용률 |
//   |---|---|---|---|---|---|---|
//   | ㈀topk | 0.03977 | 0.01229 | 3.23 | **0.70** | 6.2% | 39.5 |
//   | ㈁abs  | **0.04991** | 0.01368 | 3.65 | **0.48** | **53.1%** | **78.5** |
//
//   · ⭐ **팔은 확실히 살아 있었다** — 음수 세기 6.2% → **53.1%**(등록문 ⑤ 의 그 칸이 값을 했다).
//   · ㉠ 시험 MSE↓ **6/12**(p=0.613) ⛔ — 오히려 **나빠졌다**(0.0398 → 0.0499).
//   · ㉡ 기제 관문 `㉯/㉮` = **0.48** ⛔ — 세기 손실이 30% → **52%** 로 **커졌다**.
//     ★ 읽기: `|z|` 로 고르면 **「기여가 클 것 같은」 유닛**을 뽑지만 그 부호 있는 값이 **좋은 계수는
//       아니다** ⇒ 제약을 푼 것이 아니라 **더 나쁜 계수를 뽑을 자유**를 준 것이다.
//   ⇒ 등록된 **㈂**: **부호·크기 제약도 세기 손실의 원인이 아니다.**
//   ⭐ 회귀 검사 — ㈀ 의 `㉯/㉮ = 0.70` 이 회차 27·28 과 **또 같다**(세 회차 연속 재현).
//
//   ★ **딴 데서 나온 큰 것 — 「사용률이 병목」이 직접 반증됐다**
//   사용률이 **39.5 → 78.5 로 두 배**가 됐다. 이 세션에서 사용률을 움직인 **유일한** 개입이다
//   (앞의 넷은 데이터 16배 1.26 · `N` 8배 1.12 · `Wd` 정규화 0.96 · 코드북 정규화 0.90).
//   ⚠️⚠️ **그런데 시험 오차는 나빠졌다.** ⇒ 사용률과 시험 오차는 **같이 가지 않는다.**
//   ★ 회차 25·26 이 「진단을 의심해야 한다」로 남겨 둔 것을 이 회차가 **직접 죽였다.**
//     ⇒ 앞으로 **사용률을 성과 지표로 쓰지 않는다**(진단 채널로만 남긴다).
//
//   ⚠️⚠️⚠️ **그리고 문턱에 대해 알아야 할 것이 하나 더 있다**
//   `㉯`(모델의 ids · 계수 최적)가 **0.0279(㈀) / 0.0239(㈁)** 인데 ㉠ 의 문턱은 **0.0171**
//   (씨앗별 대조군 절반은 평균 **0.0160**)이다. ⇒ ★ **선택을 고정한 채로는 계수를 완벽하게 해도
//     문턱을 못 넘는다.** ⇒ 남는 여지는 **선택**뿐인데, 우리 greedy 오라클은 모델보다 나빠서
//     그 여지의 크기를 **아직 모른다**(회차 27 의 그 결함).
//   ⇒ 📌 **다음은 「선택의 여지」를 정직하게 재는 것**이다: **OMP**(직교 정합추적 — 매 걸음
//     고른 원소 전체에 대해 최소제곱을 다시 푼다)는 greedy 보다 훨씬 강하고 값이 싸다(k=8).
//     ★ OMP 가 문턱 아래로 내려가면 **문턱은 `k=8` 에서 도달 가능**하고 문제는 **순전히 선택**이다.
//       OMP 도 못 넘으면 **`k=8` 로는 등록된 문턱이 원리적으로 안 된다**는 뜻이고, 그것은
//       **등록에 대한 사실**이다(모델의 실패가 아니다).

using namespace PE;

class MLTP2Ab
{
public:
	static void Tick(RHI* rhi)
	{
		if (_arm >= kArms || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltp2ab"))
		{
			LogA("[mlt] ± 걸음 10(선택 |z| A/B)는 **꺼져 있다**(`-mltp2ab`) — 회차 29 기록:"
			     " ㈀topk 0.03977(㉯/㉮ 0.70 · 사용률 39.5) ↔ ㈁abs **0.04991**(0.48 · 사용률 **78.5**)"
			     " ⇒ **㈂ 부호 제약도 아니다** · ⭐ 사용률을 **2배**로 올린 유일한 개입인데 시험은"
			     " **나빠졌다** ⇒ 「사용률이 병목」이 **직접 반증**됐다\n");
			_arm = kArms;
			return;
		}
		if (!_banner) { _Banner(); _banner = true; }
		if (_st == kInit)  { _BeginSeed(rhi); return; }
		if (_st == kTrain) { _Train();        return; }
		if (_st == kEval)  { _Eval();         return; }
	}

	static bool Done() { return _arm >= kArms; }

private:
	static constexpr uint32 kArms = 2u;
	static constexpr uint32 kSeeds = 12u;
	static constexpr uint32 kTrainF = 128u, kTestF = 8u;
	static constexpr uint32 kPoolCap = kTrainF + kTestF;
	static constexpr uint32 kSteps = 4800u;
	static constexpr uint32 kN = 1000u, kK = 8u;
	static constexpr uint32 kPerTick = 4u, kEvalTr = 8u;
	static constexpr uint32 kTestEpisode = 1u;
	static constexpr float  kRidge = 1.0e-6f;
	static constexpr uint32 kSignPass = 11u;
	static constexpr float  kLsqFloor = 0.85f;
	static constexpr float  kUseFrac = 0.01f;

	enum { kInit, kTrain, kEval };

	inline static MLTP2Enc _E;
	inline static bool   _banner = false, _setup = false;
	inline static uint32 _arm = 0u, _seed = 0u;
	inline static int    _st = kInit;
	inline static uint32 _step = 0u, _ev = 0u;
	inline static double _sumTest = 0.0, _sumTrain = 0.0;
	inline static uint32 _nTest = 0u, _nTrain = 0u;
	inline static uint32 _negSum = 0u, _negTot = 0u;
	inline static Array<float> _tgtTest, _idsTest, _code, _usage;

	inline static float _mTest[kArms][kSeeds]  = { { 0.0f } };
	inline static float _mTrain[kArms][kSeeds] = { { 0.0f } };
	inline static float _mLsq[kArms][kSeeds]   = { { 0.0f } };
	inline static float _mNeg[kArms][kSeeds]   = { { 0.0f } };
	inline static uint32 _use[kArms][kSeeds]   = { { 0u } };

	static bool _AbsOn() { return _arm == 1u; }
	static const char* _ArmName() { return (_arm == 0u) ? "㈀topk" : "㈁abs"; }

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] ±👁️ **P2 걸음 10 · 선택은 `|z|` · 세기는 `z` (A/B)** — 씨앗 %u (k=%u N=%u F=%u %u스텝)\n",
			kSeeds, kK, kN, kTrainF, kSteps);
		LogA("[mlt] ±   팔: ㈀ **`act_topk`**(가장 큰 값) ↔ ㈁ **`act_topk_abs`**(가장 큰 절댓값 · 부호 유지)\n");
		LogA("[mlt] ±   근거: 회차 27 의 「세기만 최적 = 30%% 이득」 + 회차 26·28 의 「크기 정규화는 무효」\n");
		LogA("[mlt] ±   ㉠ 시험 MSE↓ 씨앗별 **%u/%u** · ㉡ **기제 관문** `㉯/㉮` ≥ **%.2f**(지금 0.70)\n",
			kSignPass, kSeeds, (double)kLsqFloor);
		LogA("[mlt] ±   ⭐ 살아있나 칸: **뽑힌 세기의 음수 비율**(㈁ 에서 0 이면 스위치가 죽은 것이다)\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

	static void _BeginSeed(RHI* rhi)
	{
		if (!_setup)
		{
			if (!_E.Setup(rhi, kPoolCap, kN)) { LogA("[mlt] ± 준비 실패\n"); _arm = kArms; return; }
			_setup = true;
		}
		else if (!_E.ResetSeed()) { LogA("[mlt] ± 되돌리기 실패\n"); _arm = kArms; return; }
		_E.SetK(kK);
		_E.SetSelectAbs(_AbsOn());

		Array<float> fr, tg;
		fr.Reset(0); tg.Reset(0); _tgtTest.Reset(0);
		ImageFormat::Bitmap bmp;
		Bytes packed;
		{
			MLTWorld w;
			w.Reset(_seed, 0u, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
			for (uint32 f = 0; f < kTrainF; ++f)
			{
				w.Step();
				if (!w.Render(bmp) || !MLTWorld::Pack(bmp, nullptr, packed))
				{ LogA("[mlt] ± Render/Pack 실패(학습)\n"); _arm = kArms; return; }
				MLTP2Enc::AppendFrame(fr, tg, (const uint8*)packed.GetData());
			}
		}
		{
			MLTWorld w;
			w.Reset(_seed, kTestEpisode, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
			for (uint32 f = 0; f < kTestF; ++f)
			{
				w.Step();
				if (!w.Render(bmp) || !MLTWorld::Pack(bmp, nullptr, packed))
				{ LogA("[mlt] ± Render/Pack 실패(시험)\n"); _arm = kArms; return; }
				const uint8* px = (const uint8*)packed.GetData();
				MLTP2Enc::AppendFrame(fr, tg, px);
				Array<float> one, dummy; one.Reset(0); dummy.Reset(0);
				MLTP2Enc::AppendFrame(dummy, one, px);
				for (uint32 i = 0; i < one.Count(); ++i) _tgtTest.Add(one[i]);
			}
		}
		if (!_E.WritePool(fr, tg, kTrainF + kTestF))
		{ LogA("[mlt] ± 풀 업로드 실패\n"); _arm = kArms; return; }

		_usage.Reset(0);
		for (uint32 i = 0; i < _E.N(); ++i) _usage.Add(0.0f);
		_idsTest.Reset(0);
		_step = 0u; _ev = 0u; _sumTest = 0.0; _sumTrain = 0.0; _nTest = 0u; _nTrain = 0u;
		_negSum = 0u; _negTot = 0u;
		_st = kTrain;
	}

	static void _Train()
	{
		for (uint32 i = 0; i < kPerTick && _step < kSteps; ++i)
		{
			_E.SetFrame(_step % kTrainF);
			if (!_E.Forward() || !_E.Backward() || !_E.AdamStep(1.0f))
			{ LogA("[mlt] ± 스텝 실패(팔 %s 씨앗 %u 스텝 %u)\n", _ArmName(), _seed, _step); _arm = kArms; return; }
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
			if (!_E.ReadMse(m, fin)) { LogA("[mlt] ± 평가 리드백 실패\n"); _arm = kArms; return; }
			if (prev < kTestF)
			{
				_sumTest += (double)m; ++_nTest;
				Array<float> id, mg;
				if (!_E.ReadAct(id, mg)) { LogA("[mlt] ± 선택 리드백 실패\n"); _arm = kArms; return; }
				for (uint32 i = 0; i < id.Count(); ++i) _idsTest.Add(id[i]);
				uint32 neg = 0u, tot = 0u;
				if (_E.ReadNegCount(neg, tot)) { _negSum += neg; _negTot += tot; }
				if (!_E.AccumUsage(_usage)) { LogA("[mlt] ± 사용률 리드백 실패\n"); _arm = kArms; return; }
			}
			else { _sumTrain += (double)m; ++_nTrain; }
		}
		if (_ev < nEv)
		{
			_E.SetFrame((_ev < kTestF) ? (kTrainF + _ev) : (_ev - kTestF));
			if (!_E.Forward()) { LogA("[mlt] ± 평가 forward 실패\n"); _arm = kArms; return; }
			++_ev;
			return;
		}
		_JudgeSeed();
	}

	static void _JudgeSeed()
	{
		typedef MLTP2Cfg C;
		if (!_E.ReadCodebook(_code)) { LogA("[mlt] ± 코드북 리드백 실패\n"); _arm = kArms; return; }
		const float mT = (_nTest  != 0u) ? (float)(_sumTest  / (double)_nTest)  : 0.0f;
		const float mR = (_nTrain != 0u) ? (float)(_sumTrain / (double)_nTrain) : 0.0f;
		const uint32 nP = _tgtTest.Count() / C::kPix;
		const float lsq = MLTP2Enc::LsqMse(_code, kN, _tgtTest, _idsTest, kK, nP, kRidge);
		float mx = 0.0f;
		for (uint32 i = 0; i < _E.N(); ++i) if (_usage[i] > mx) mx = _usage[i];
		uint32 use = 0u;
		if (mx > 0.0f) { const float th = kUseFrac * mx; for (uint32 i = 0; i < _E.N(); ++i) if (_usage[i] > th) ++use; }
		const float negFrac = (_negTot != 0u) ? ((float)_negSum / (float)_negTot) : 0.0f;

		_mTest[_arm][_seed] = mT; _mTrain[_arm][_seed] = mR; _mLsq[_arm][_seed] = lsq;
		_mNeg[_arm][_seed] = negFrac; _use[_arm][_seed] = use;

		LogA("[mlt] ± %s [%2u/%u] 씨앗 %u — 시험 **%.5f** · 학습 %.5f · ㉯ **%.5f**(비 **%.2f**)"
		     " · 음수 세기 **%.1f%%** · 사용률 %u\n",
			_ArmName(), _seed + 1u, kSeeds, _seed, (double)mT, (double)mR, (double)lsq,
			(double)((mT > 1e-9f) ? (lsq / mT) : 0.0f), (double)(negFrac * 100.0f), use);

		++_seed;
		if (_seed >= kSeeds)
		{
			_ArmSummary();
			_seed = 0u; ++_arm;
			if (_arm >= kArms) { _Summary(); _E.Destroy(); return; }
		}
		_st = kInit;
	}

	static void _ArmSummary()
	{
		double sT = 0.0, sR = 0.0, sL = 0.0, sNg = 0.0; uint32 sU = 0u;
		for (uint32 i = 0; i < kSeeds; ++i)
		{
			sT += _mTest[_arm][i]; sR += _mTrain[_arm][i]; sL += _mLsq[_arm][i];
			sNg += _mNeg[_arm][i]; sU += _use[_arm][i];
		}
		const float mT = (float)(sT / kSeeds), mR = (float)(sR / kSeeds), mL = (float)(sL / kSeeds);
		LogA("[mlt] ± ── 팔 %s ── 시험 **%.5f** · 학습 %.5f (비 %.2f배) · ㉯ **%.5f** ⇒ **㉯/㉮ = %.2f**"
		     " · 음수 세기 **%.1f%%** · 사용률 %.1f\n",
			_ArmName(), (double)mT, (double)mR, (double)((mR > 1e-9f) ? (mT / mR) : 0.0f),
			(double)mL, (double)((mT > 1e-9f) ? (mL / mT) : 0.0f),
			(double)(sNg / kSeeds * 100.0), (double)((float)sU / (float)kSeeds));
	}

	static float _BinomP(uint32 w, uint32 n)
	{
		double tot = 0.0;
		for (uint32 i = w; i <= n; ++i)
		{
			double c = 1.0;
			for (uint32 j = 0; j < i; ++j) c = c * (double)(n - j) / (double)(j + 1u);
			tot += c;
		}
		return (float)(tot / Pow(2.0f, (float)n));
	}

	static void _Summary()
	{
		float mT[kArms] = { 0.0f }, mL[kArms] = { 0.0f }, rat[kArms] = { 0.0f }, mN[kArms] = { 0.0f };
		for (uint32 a = 0; a < kArms; ++a)
		{
			double sT = 0.0, sL = 0.0, sN = 0.0;
			for (uint32 i = 0; i < kSeeds; ++i) { sT += _mTest[a][i]; sL += _mLsq[a][i]; sN += _mNeg[a][i]; }
			mT[a] = (float)(sT / kSeeds); mL[a] = (float)(sL / kSeeds); mN[a] = (float)(sN / kSeeds);
			rat[a] = (mT[a] > 1.0e-9f) ? (mL[a] / mT[a]) : 0.0f;
		}
		uint32 wT = 0u;
		for (uint32 i = 0; i < kSeeds; ++i) if (_mTest[1][i] < _mTest[0][i]) ++wT;
		const float pT = _BinomP(wT, kSeeds);
		const bool g1 = (wT >= kSignPass) && (pT < 0.025f);
		const bool g2 = (rat[1] >= kLsqFloor);
		const bool alive = (mN[1] > 0.02f);   // ⑤ 살아있나 — 음수 세기가 2% 는 넘어야 한다

		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] ±👁️ **선택 `|z|` A/B 결과**\n");
		for (uint32 a = 0; a < kArms; ++a)
			LogA("[mlt] ±   %s · 시험 **%.5f** · ㉯ %.5f ⇒ **㉯/㉮ = %.2f** · 음수 세기 **%.1f%%**\n",
				(a == 0u) ? "㈀topk" : "㈁abs ", (double)mT[a], (double)mL[a], (double)rat[a],
				(double)(mN[a] * 100.0f));
		LogA("[mlt] ±   %s ⭐ **팔이 살아 있나** — ㈁ 의 음수 세기 **%.1f%%** > 2%%\n",
			alive ? "✅" : "⛔", (double)(mN[1] * 100.0f));
		LogA("[mlt] ±   %s ㉠ 시험 MSE↓ 씨앗 **%u/%u** (p=%.5f · 필요 %u)\n",
			g1 ? "✅" : "⛔", wT, kSeeds, (double)pT, kSignPass);
		LogA("[mlt] ±   %s ㉡ **기제 관문** ㈁ 의 ㉯/㉮ = **%.2f** ≥ %.2f\n",
			g2 ? "✅" : "⛔", (double)rat[1], (double)kLsqFloor);
		LogA("[mlt] ±   ⭐ 회귀 검사 — ㈀ 의 ㉯/㉮ = **%.2f** (회차 27·28 은 0.70)\n", (double)rat[0]);

		const char* branch = !alive
			? "⚠️ **판정불가 — 팔이 죽어 있다**(음수 세기가 거의 없다 ⇒ 스위치가 아무 일도 안 했다)"
			: (!g2 ? "㈂ **부호·크기 제약도 아니다** ⇒ 남는 것은 **별도 계수 머리**(등록문 ⑥)"
			       : (g1 ? "㈀ **부호·크기 제약이 범인이었고 고쳤다**"
			             : "㈁ 세기는 고쳤지만 **전이는 다른 문제**다"));
		LogA("[mlt] ±   ⭐ 갈래 판정 = **%s**\n", branch);
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}
};
