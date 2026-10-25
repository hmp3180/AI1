// mltp2cb.cw — 🧱📏 **P2 걸음 9 · 코드북 행 크기 정규화 A/B**. 회차 27 의 분해가 가리킨 자리다.
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문** — ⚠️ 재기 **전에** 적는다.
// ══════════════════════════════════════════════════════════════════════════════
//
// ① **왜 여기인가** — 회차 27 의 분해가 둘을 냈다:
//    · **세기가 확실한 몫**: ids 를 그대로 두고 세기만 최소제곱으로 바꾸면 시험 오차가 **30% 준다**
//      (12/12 씨앗 · p=0.00024).
//    · **코드북은 전이된다**(㉰ 시험/학습 = 1.03배)인데 **모델은 3.24배** ⇒ 전이 실패는 **선택·세기**다.
//    ★ 세기의 뜻은 `mag × 코드북 행` 이다 ⇒ **행 크기가 흩어져 있으면 같은 `mag` 가 전혀 다른 기여**를
//      낸다. 최소제곱이 30% 를 버는 이유의 **후보 하나**가 그것이다.
//    ⚠️ 회차 26 은 **`Wd`**(점수 쪽)를 정규화했고 아무 효과가 없었다. **이번은 코드북**(계수가 곱해지는
//      쪽)이다 — 다른 자리이고, 분해가 바로 이 자리를 가리켰다.
//    ⭐ **새 커널 0개** — 코드북이 `[N, pixels]` 라 유닛 하나 = 한 행이므로 `rmsnorm` 이 곧바로 붙는다.
//    ⚠️ 이득은 **1 이 아니라 초기 RMS**(`kNormCodeRms`) — 회차 26 에서 그것으로 한 회차를 버렸다.
//
// ② **팔 둘** — ㈀ 정규화 **끔**(기준) · ㈁ **켬**(`AdamStep` 뒤 코드북 사영).
//    설정은 회차 26·27 과 같다(k=8 · N=1000 · 학습 128프레임 · 4800스텝 · 시험 **다른 에피소드**).
//
// ③ ⭐ **관문 둘을 미리 등록한다**
//    ㉠ **시험 MSE 가 낮아지나** — 씨앗별 짝지은 부호검정 **11/12**(`Q = 2` ⇒ 단측 p < **0.025**).
//    ㉡ ⭐ **세기 손실이 줄어드나** — 회차 27 의 그 지표를 **양쪽 팔에서 다시 잰다**:
//       `㉯/㉮`(= ids 그대로·세기만 최적 / 모델). 회차 27 의 값은 **0.70**(= 30% 를 세기로 잃는다).
//       ⇒ **문턱: ㈁켬의 `㉯/㉮` ≥ 0.85**(남는 세기 손실이 15% 이하).
//       ★ 이것이 이 회차의 **기제 관문**이다 — 시험 MSE 는 여러 이유로 움직일 수 있지만
//         이 비는 **오직 세기**를 본다.
//    ⭐ **회귀 검사가 공짜로 붙는다**: ㈀끔은 회차 27 과 같은 설정이므로 `㉯/㉮ ≈ 0.70` 을
//      재현해야 한다. 안 나오면 공용 헬퍼(`MLTP2Enc::LsqMse`)로 옮기는 중에 무언가 어긋난 것이다.
//
// ④ ⭐ **갈래 셋을 미리 등록한다**
//    ```
//    ㈀ ㉡ 통과(비 ≥0.85) **그리고** ㉠ 통과  ⇒ **세기 문제를 고쳤고 전이도 좋아졌다**
//    ㈁ ㉡ 통과인데 ㉠ 실패                  ⇒ **세기를 고쳐도 전이는 안 된다**(세기는 원인이 아니었다)
//    ㈂ ㉡ 실패(비가 안 오른다)               ⇒ **행 크기의 흩어짐은 세기 손실의 원인이 아니다**
//                                              ⇒ 다음은 **선택과 세기의 분리**(아래 ⑤)
//    ```
//
// ⑤ 📌 **다음 후보를 지금 적어 둔다**(결과를 보고 고르지 않게)
//    ⭐ **`mag` 은 두 일을 같은 수로 한다** — top-k 는 **가장 큰 점수**를 고르고, 그 점수가 그대로
//      재구성의 **계수**가 된다. 「뽑히려면 커야 한다」와 「계수로 맞아야 한다」는 **다른 요구**다.
//      ⇒ 계수를 **별도 머리**(`coef = patch · Wc`)에서 내고 선택은 점수로만 하면 그 결합이 풀린다.
//      ⚠️ 그것은 **`ids` 로 다른 행렬을 모으는 커널**이 필요하다(새 커널 하나) ⇒ 판정 ①② 를 먼저 통과.
//      ⚠️ 그래서 **㈂ 일 때만** 그 값을 치른다(먼저 싼 것으로 크기 요인을 배제한다).
//
// ⑥ ⚠️ 값 — 팔 둘 × 씨앗 12 × 4800스텝 + 씨앗마다 최소제곱 ⇒ **십 분 대**.
//
// ══════════════════════════════════════════════════════════════════════════════
// 🧾 **결과(회차 28) — ㈂. 그리고 ⭐ 회귀 검사가 완벽했다.**
// ══════════════════════════════════════════════════════════════════════════════
//   | 팔 | 시험 | 학습 | 비 | ㉯/㉮ | 사용률 |
//   |---|---|---|---|---|---|
//   | ㈀끔 | 0.03977 | 0.01229 | 3.23 | **0.70** | 39.5 |
//   | ㈁켬 | 0.03841 | 0.01324 | 2.90 | **0.72** | 35.6 |
//
//   · ㉠ 시험 MSE↓ **7/12**(p=0.387) = **우연** ⛔ · ㉡ 기제 관문 **0.72 < 0.85** ⛔
//   · ⇒ 등록된 **㈂**: **코드북 행 크기의 흩어짐은 세기 손실의 원인이 아니다.**
//   ⭐ **회귀 검사가 완벽했다** — ㈀끔의 `㉯/㉮ = 0.70` 이 회차 27 과 **소수점까지 같다**
//     ⇒ 최소제곱을 공용 헬퍼(`MLTP2Enc::LsqMse`)로 옮기며 아무것도 어긋나지 않았다.
//     ★ 「같은 것을 두 자리에 두지 않는다」를 지킨 대가가 이 확인이다.
//   ⓘ 학습/시험 비가 3.23 → 2.90 으로 조금 줄었지만 **시험은 거의 그대로**다(그리고 씨앗 7/12 = 우연)
//     ⇒ 성과로 읽지 않는다.
//
//   ⇒ ⭐ **정규화는 두 자리 모두에서 아무것도 아니었다**(회차 26 `Wd` · 이 회차 코드북).
//     남는 후보는 등록문 ⑤ 의 **구조**다: `mag` 이 **선택과 계수 두 일을 같은 수로** 한다.

using namespace PE;

class MLTP2Cb
{
public:
	static void Tick(RHI* rhi)
	{
		if (_arm >= kArms || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltp2cb"))
		{
			LogA("[mlt] 🧱 걸음 9(코드북 크기 정규화 A/B)는 **꺼져 있다**(`-mltp2cb`) — 회차 28 기록:"
			     " ㈀끔 0.03977(㉯/㉮ **0.70**) ↔ ㈁켬 0.03841(**0.72**) · ㉠ 7/12 · ㉡ ⛔"
			     " ⇒ **㈂ 크기 흩어짐은 세기 손실의 원인이 아니다** · ⭐ 회귀 검사 0.70 완전 재현\n");
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
	static constexpr float  kLsqFloor = 0.85f;   // ㉡ 문턱(회차 27 의 값은 0.70)
	static constexpr float  kUseFrac = 0.01f;

	enum { kInit, kTrain, kEval };

	inline static MLTP2Enc _E;
	inline static bool   _banner = false, _setup = false;
	inline static uint32 _arm = 0u, _seed = 0u;
	inline static int    _st = kInit;
	inline static uint32 _step = 0u, _ev = 0u;
	inline static double _sumTest = 0.0, _sumTrain = 0.0;
	inline static uint32 _nTest = 0u, _nTrain = 0u;
	inline static Array<float> _tgtTest, _idsTest, _code, _usage;

	inline static float _mTest[kArms][kSeeds]  = { { 0.0f } };
	inline static float _mTrain[kArms][kSeeds] = { { 0.0f } };
	inline static float _mLsq[kArms][kSeeds]   = { { 0.0f } };
	inline static uint32 _use[kArms][kSeeds]   = { { 0u } };

	static bool _NormOn() { return _arm == 1u; }
	static const char* _ArmName() { return (_arm == 0u) ? "㈀끔" : "㈁켬"; }

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🧱📏 **P2 걸음 9 · 코드북 행 크기 정규화 A/B** — 씨앗 %u (k=%u N=%u F=%u %u스텝)\n",
			kSeeds, kK, kN, kTrainF, kSteps);
		LogA("[mlt] 🧱   팔: ㈀ **끔**(기준) ↔ ㈁ **켬**(`AdamStep` 뒤 코드북 사영 · 이득 = 초기 RMS %.5f)\n",
			(double)MLTP2Cfg::kNormCodeRms);
		LogA("[mlt] 🧱   ㉠ 시험 MSE↓ 씨앗별 **%u/%u**(Q=2 ⇒ p<0.025)\n", kSignPass, kSeeds);
		LogA("[mlt] 🧱   ㉡ ⭐ **기제 관문** — `㉯/㉮`(세기만 최적/모델) ≥ **%.2f** (회차 27 의 값은 **0.70**)\n",
			(double)kLsqFloor);
		LogA("[mlt] 🧱   ⭐ ㈀끔이 회차 27 의 0.70 을 재현해야 한다(공용 헬퍼 이관의 회귀 검사)\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

	static void _BeginSeed(RHI* rhi)
	{
		if (!_setup)
		{
			if (!_E.Setup(rhi, kPoolCap, kN)) { LogA("[mlt] 🧱 준비 실패\n"); _arm = kArms; return; }
			_setup = true;
		}
		else if (!_E.ResetSeed()) { LogA("[mlt] 🧱 되돌리기 실패\n"); _arm = kArms; return; }
		_E.SetK(kK);

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
				{ LogA("[mlt] 🧱 Render/Pack 실패(학습)\n"); _arm = kArms; return; }
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
				{ LogA("[mlt] 🧱 Render/Pack 실패(시험)\n"); _arm = kArms; return; }
				const uint8* px = (const uint8*)packed.GetData();
				MLTP2Enc::AppendFrame(fr, tg, px);
				Array<float> one, dummy; one.Reset(0); dummy.Reset(0);
				MLTP2Enc::AppendFrame(dummy, one, px);
				for (uint32 i = 0; i < one.Count(); ++i) _tgtTest.Add(one[i]);
			}
		}
		if (!_E.WritePool(fr, tg, kTrainF + kTestF))
		{ LogA("[mlt] 🧱 풀 업로드 실패\n"); _arm = kArms; return; }

		// ⭐ 켬 팔은 첫 스텝 전에도 한 번 사영한다(초기 산포의 크기 차이부터 없앤다).
		if (_NormOn() && !_E.NormalizeCode())
		{ LogA("[mlt] 🧱 초기 정규화 실패\n"); _arm = kArms; return; }

		_usage.Reset(0);
		for (uint32 i = 0; i < _E.N(); ++i) _usage.Add(0.0f);
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
			{ LogA("[mlt] 🧱 스텝 실패(팔 %s 씨앗 %u 스텝 %u)\n", _ArmName(), _seed, _step); _arm = kArms; return; }
			if (_NormOn() && !_E.NormalizeCode())
			{ LogA("[mlt] 🧱 정규화 실패\n"); _arm = kArms; return; }
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
			if (!_E.ReadMse(m, fin)) { LogA("[mlt] 🧱 평가 리드백 실패\n"); _arm = kArms; return; }
			if (prev < kTestF)
			{
				_sumTest += (double)m; ++_nTest;
				Array<float> id, mg;
				if (!_E.ReadAct(id, mg)) { LogA("[mlt] 🧱 선택 리드백 실패\n"); _arm = kArms; return; }
				for (uint32 i = 0; i < id.Count(); ++i) _idsTest.Add(id[i]);
				if (!_E.AccumUsage(_usage)) { LogA("[mlt] 🧱 사용률 리드백 실패\n"); _arm = kArms; return; }
			}
			else { _sumTrain += (double)m; ++_nTrain; }
		}
		if (_ev < nEv)
		{
			_E.SetFrame((_ev < kTestF) ? (kTrainF + _ev) : (_ev - kTestF));
			if (!_E.Forward()) { LogA("[mlt] 🧱 평가 forward 실패\n"); _arm = kArms; return; }
			++_ev;
			return;
		}
		_JudgeSeed();
	}

	static void _JudgeSeed()
	{
		typedef MLTP2Cfg C;
		if (!_E.ReadCodebook(_code)) { LogA("[mlt] 🧱 코드북 리드백 실패\n"); _arm = kArms; return; }
		const float mT = (_nTest  != 0u) ? (float)(_sumTest  / (double)_nTest)  : 0.0f;
		const float mR = (_nTrain != 0u) ? (float)(_sumTrain / (double)_nTrain) : 0.0f;
		const uint32 nP = _tgtTest.Count() / C::kPix;
		const float lsq = MLTP2Enc::LsqMse(_code, kN, _tgtTest, _idsTest, kK, nP, kRidge);
		float mx = 0.0f;
		for (uint32 i = 0; i < _E.N(); ++i) if (_usage[i] > mx) mx = _usage[i];
		uint32 use = 0u;
		if (mx > 0.0f) { const float th = kUseFrac * mx; for (uint32 i = 0; i < _E.N(); ++i) if (_usage[i] > th) ++use; }

		_mTest[_arm][_seed] = mT; _mTrain[_arm][_seed] = mR; _mLsq[_arm][_seed] = lsq;
		_use[_arm][_seed] = use;

		LogA("[mlt] 🧱 %s [%2u/%u] 씨앗 %u — 시험 **%.5f** · 학습 %.5f · ㉯세기최적 **%.5f**(비 **%.2f**)"
		     " · 사용률 %u\n",
			_ArmName(), _seed + 1u, kSeeds, _seed, (double)mT, (double)mR, (double)lsq,
			(double)((mT > 1e-9f) ? (lsq / mT) : 0.0f), use);

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
		double sT = 0.0, sR = 0.0, sL = 0.0; uint32 sU = 0u;
		for (uint32 i = 0; i < kSeeds; ++i)
		{ sT += _mTest[_arm][i]; sR += _mTrain[_arm][i]; sL += _mLsq[_arm][i]; sU += _use[_arm][i]; }
		const float mT = (float)(sT / kSeeds), mR = (float)(sR / kSeeds), mL = (float)(sL / kSeeds);
		LogA("[mlt] 🧱 ── 팔 %s ── 시험 **%.5f** · 학습 %.5f (비 %.2f배) · ㉯ **%.5f** ⇒"
		     " **㉯/㉮ = %.2f** · 사용률 %.1f\n",
			_ArmName(), (double)mT, (double)mR, (double)((mR > 1e-9f) ? (mT / mR) : 0.0f),
			(double)mL, (double)((mT > 1e-9f) ? (mL / mT) : 0.0f), (double)((float)sU / (float)kSeeds));
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
		float mT[kArms] = { 0.0f }, mL[kArms] = { 0.0f }, rat[kArms] = { 0.0f };
		for (uint32 a = 0; a < kArms; ++a)
		{
			double sT = 0.0, sL = 0.0;
			for (uint32 i = 0; i < kSeeds; ++i) { sT += _mTest[a][i]; sL += _mLsq[a][i]; }
			mT[a] = (float)(sT / kSeeds); mL[a] = (float)(sL / kSeeds);
			rat[a] = (mT[a] > 1.0e-9f) ? (mL[a] / mT[a]) : 0.0f;
		}
		uint32 wT = 0u;
		for (uint32 i = 0; i < kSeeds; ++i) if (_mTest[1][i] < _mTest[0][i]) ++wT;
		const float pT = _BinomP(wT, kSeeds);
		const bool g1 = (wT >= kSignPass) && (pT < 0.025f);
		const bool g2 = (rat[1] >= kLsqFloor);

		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🧱📏👁️ **코드북 크기 정규화 A/B 결과**\n");
		for (uint32 a = 0; a < kArms; ++a)
			LogA("[mlt] 🧱   %s · 시험 **%.5f** · ㉯ %.5f ⇒ **㉯/㉮ = %.2f**\n",
				(a == 0u) ? "㈀끔" : "㈁켬", (double)mT[a], (double)mL[a], (double)rat[a]);
		LogA("[mlt] 🧱   %s ㉠ 시험 MSE↓ 씨앗 **%u/%u** (p=%.5f · 필요 %u)\n",
			g1 ? "✅" : "⛔", wT, kSeeds, (double)pT, kSignPass);
		LogA("[mlt] 🧱   %s ㉡ **기제 관문** ㈁켬의 ㉯/㉮ = **%.2f** ≥ %.2f\n",
			g2 ? "✅" : "⛔", (double)rat[1], (double)kLsqFloor);
		LogA("[mlt] 🧱   ⭐ 회귀 검사 — ㈀끔의 ㉯/㉮ = **%.2f** (회차 27 은 0.70)\n", (double)rat[0]);

		const char* branch = !g2
			? "㈂ **행 크기의 흩어짐은 세기 손실의 원인이 아니다** ⇒ 다음은 **선택과 세기의 분리**(등록문 ⑤)"
			: (g1 ? "㈀ **세기 문제를 고쳤고 전이도 좋아졌다**"
			      : "㈁ **세기를 고쳐도 전이는 안 된다**(세기는 원인이 아니었다)");
		LogA("[mlt] 🧱   ⭐ 갈래 판정 = **%s**\n", branch);
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}
};
