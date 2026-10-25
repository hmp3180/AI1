// mltp2sc.cw — 🪓 **P2 걸음 13 · 선택 순위(S)와 재구성 계수(C) 분리** (`-mltp2sc`)
//
// 등록문 정본은 `mltp2h.cw` 끝과 `MLT.md`/`mltlog_1.md`의 회차 33이다.
// ㈀ full-rank Wd: ids=topk(S), mag=S[id]
// ㈁ rank54×2 완전 분리: ids=topk(S), mag=C[id]
// ㈂ 같은 머리 부분 결합: ids=topk(S), mag=(S+C)/sqrt(2)[id]
// ㈁㈂ 살아있는 파라미터 371,168 < ㈀ 377,344. Q=3 대응 부호검정은 11/12를 요구한다.
// 회차 33은 ㈁/㈂ 학습 MSE 0.02888/0.05497로 둘 다 생존 관문에서 탈락해 판정불가였다.
// 회차 34는 같은 머리 출력 S/C에 고정 RMSNorm(목표 0.05473)을 똑같이 붙인다. 순위·파라미터·관문은 불변.
// 결과: 두 팔 생존(0.01994/0.01557), 대응 3/12·5/12·3/12, 완전분리 모델/OMP 2.78.
// ⇒ 등록 갈래 ㈂: 선택/계수 분리도 축이 아니다. 다음은 모델 변경 전 잔차 기반 1회 교체 오라클.

using namespace PE;

class MLTP2SC
{
public:
	static void Tick(RHI* rhi)
	{
		if (_arm >= kArms || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltp2sc"))
		{
			LogA("[mlt] 🪓 걸음 13(선택/계수 분리)은 **꺼져 있다**(`-mltp2sc`) — 회차 34: 두 팔 생존 ✅ ·"
			     " 대응 **3/12·5/12·3/12** · 완전분리 모델/OMP **2.78** ⇒ **분리도 축이 아니다**\n");
			_arm = kArms; return;
		}
		if (!_banner) { _Banner(); _banner = true; }
		if (_st == kInit)  { _BeginSeed(rhi); return; }
		if (_st == kTrain) { _Train(); return; }
		if (_st == kEval)  { _Eval(); return; }
	}

	static bool Done() { return _arm >= kArms; }

private:
	static constexpr uint32 kArms = 3u, kSeeds = 12u;
	static constexpr uint32 kRank[kArms] = { 0u, 54u, 54u };
	static constexpr bool kCouple[kArms] = { false, false, true };
	static constexpr uint32 kTrainF = 128u, kTestF = 8u, kPoolCap = kTrainF + kTestF;
	static constexpr uint32 kSteps = 4800u, kN = 1000u, kK = 8u;
	static constexpr uint32 kPerTick = 4u, kEvalTr = 8u, kTestEpisode = 1u;
	static constexpr float kRidge = 1.0e-6f, kBeat = 0.5f, kOmpRatio = 2.0f, kUseFrac = 0.01f;
	static constexpr uint32 kSignPass = 11u, kBudget = 500000u, kWatchSeed = 10u, kLiveSlot = 384u;
	enum { kInit, kTrain, kEval };

	inline static MLTP2Enc _E;
	inline static bool _banner = false;
	inline static uint32 _arm = 0u, _seed = 0u, _step = 0u, _ev = 0u;
	inline static int _st = kInit;
	inline static double _sumTest = 0.0, _sumTrain = 0.0;
	inline static uint32 _nTest = 0u, _nTrain = 0u;
	inline static Array<float> _tgtTest, _idsTest, _code, _usage;
	inline static float _mTest[kArms][kSeeds] = { { 0.0f } };
	inline static float _mTrain[kArms][kSeeds] = { { 0.0f } };
	inline static float _mLsq[kArms][kSeeds] = { { 0.0f } };
	inline static float _mOmp[kArms][kSeeds] = { { 0.0f } };
	inline static float _mBase[kArms][kSeeds] = { { 0.0f } };
	inline static uint32 _use[kArms][kSeeds] = { { 0u } };
	inline static bool _ok[kArms][kSeeds] = { { false } };

	static const char* _ArmName(uint32 a)
	{ return (a == 0u) ? "㈀full-rank" : ((a == 1u) ? "㈁S/C분리" : "㈂부분결합"); }

	static uint32 _Live(uint32 a)
	{
		return (a == 0u) ? MLTP2Enc::LiveParams(kLiveSlot, kN)
			: MLTP2Enc::LiveSplitParams(kLiveSlot, kN, kRank[a]);
	}

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🪓 **P2 걸음 13 · 선택/계수 분리** — 팔 %u × 씨앗 %u (k=%u N=%u F=%u %u스텝)\n",
			kArms, kSeeds, kK, kN, kTrainF, kSteps);
		LogA("[mlt] 🪓   ㈀ full-rank S[id] · ㈁ rank54 C[id] · ㈂ rank54 (S+C)/sqrt(2)[id]\n");
		for (uint32 a = 0; a < kArms; ++a)
			LogA("[mlt] 🪓      %s — 살아있는 파라미터 **%u**%s\n", _ArmName(a), _Live(a),
				(_Live(a) <= kBudget) ? " ✅" : " ⛔예산초과");
		LogA("[mlt] 🪓   갈래: ㈁>㈀·㈁>㈂=완전 분리 · ㈁㈂>㈀=저랭크 인자화/최적화 · 둘 다 아님=분리도 축 아님\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

	static void _BeginSeed(RHI* rhi)
	{
		if (_seed == 0u)
		{
			if (!_E.Setup(rhi, kPoolCap, kN, 0u, false, kRank[_arm], kCouple[_arm], _arm != 0u))
			{ LogA("[mlt] 🪓 준비 실패(팔 %s)\n", _ArmName(_arm)); _arm = kArms; return; }
		}
		else if (!_E.ResetSeed()) { LogA("[mlt] 🪓 되돌리기 실패\n"); _arm = kArms; return; }
		_E.SetK(kK); _E.SetSelectAbs(false);

		Array<float> fr, tg; fr.Reset(0); tg.Reset(0); _tgtTest.Reset(0);
		ImageFormat::Bitmap bmp; Bytes packed;
		{
			MLTWorld w; w.Reset(_seed, 0u, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
			for (uint32 f = 0; f < kTrainF; ++f)
			{
				w.Step();
				if (!w.Render(bmp) || !MLTWorld::Pack(bmp, nullptr, packed))
				{ LogA("[mlt] 🪓 Render/Pack 실패(학습)\n"); _arm = kArms; return; }
				MLTP2Enc::AppendFrame(fr, tg, (const uint8*)packed.GetData());
			}
		}
		{
			MLTWorld w; w.Reset(_seed, kTestEpisode, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
			for (uint32 f = 0; f < kTestF; ++f)
			{
				w.Step();
				if (!w.Render(bmp) || !MLTWorld::Pack(bmp, nullptr, packed))
				{ LogA("[mlt] 🪓 Render/Pack 실패(시험)\n"); _arm = kArms; return; }
				const uint8* px = (const uint8*)packed.GetData();
				MLTP2Enc::AppendFrame(fr, tg, px);
				Array<float> one, dummy; one.Reset(0); dummy.Reset(0);
				MLTP2Enc::AppendFrame(dummy, one, px);
				for (uint32 i = 0; i < one.Count(); ++i) _tgtTest.Add(one[i]);
			}
		}
		if (!_E.WritePool(fr, tg, kPoolCap)) { LogA("[mlt] 🪓 풀 업로드 실패\n"); _arm = kArms; return; }
		_mBase[_arm][_seed] = MLTP2Enc::PatchConstMse(_tgtTest);
		_usage.Reset(0); for (uint32 i = 0; i < _E.N(); ++i) _usage.Add(0.0f);
		_idsTest.Reset(0); _step = 0u; _ev = 0u; _sumTest = 0.0; _sumTrain = 0.0; _nTest = 0u; _nTrain = 0u;
		_st = kTrain;
	}

	static void _Train()
	{
		for (uint32 i = 0; i < kPerTick && _step < kSteps; ++i)
		{
			_E.SetFrame(_step % kTrainF);
			if (!_E.Forward() || !_E.Backward() || !_E.AdamStep(1.0f))
			{ LogA("[mlt] 🪓 스텝 실패(%s 씨앗 %u 스텝 %u)\n", _ArmName(_arm), _seed, _step); _arm = kArms; return; }
			++_step;
		}
		if (_step >= kSteps) { _st = kEval; _ev = 0u; }
	}

	static void _Eval()
	{
		const uint32 nEv = kTestF + kEvalTr;
		if (_ev > 0u)
		{
			const uint32 prev = _ev - 1u; float m = 0.0f; bool fin = true;
			if (!_E.ReadMse(m, fin) || !fin) { LogA("[mlt] 🪓 평가 리드백 실패/비유한\n"); _arm = kArms; return; }
			if (prev < kTestF)
			{
				_sumTest += (double)m; ++_nTest;
				Array<float> id, mg;
				if (!_E.ReadAct(id, mg)) { LogA("[mlt] 🪓 선택 리드백 실패\n"); _arm = kArms; return; }
				for (uint32 i = 0; i < id.Count(); ++i) _idsTest.Add(id[i]);
				if (!_E.AccumUsage(_usage)) { LogA("[mlt] 🪓 사용률 리드백 실패\n"); _arm = kArms; return; }
			}
			else { _sumTrain += (double)m; ++_nTrain; }
		}
		if (_ev < nEv)
		{
			_E.SetFrame((_ev < kTestF) ? (kTrainF + _ev) : (_ev - kTestF));
			if (!_E.Forward()) { LogA("[mlt] 🪓 평가 forward 실패\n"); _arm = kArms; return; }
			++_ev; return;
		}
		_JudgeSeed();
	}

	static void _JudgeSeed()
	{
		typedef MLTP2Cfg C;
		if (!_E.ReadCodebook(_code)) { LogA("[mlt] 🪓 코드북 리드백 실패\n"); _arm = kArms; return; }
		const float mT = (_nTest != 0u) ? (float)(_sumTest / _nTest) : 0.0f;
		const float mR = (_nTrain != 0u) ? (float)(_sumTrain / _nTrain) : 0.0f;
		const uint32 nP = _tgtTest.Count() / C::kPix;
		const float lsq = MLTP2Enc::LsqMse(_code, kN, _tgtTest, _idsTest, kK, nP, kRidge);
		const float omp = MLTP2Enc::OmpMse(_code, kN, _tgtTest, kK, nP, kRidge);
		float mx = 0.0f; for (uint32 i = 0; i < _E.N(); ++i) if (_usage[i] > mx) mx = _usage[i];
		uint32 use = 0u;
		if (mx > 0.0f) { const float th = kUseFrac * mx; for (uint32 i = 0; i < _E.N(); ++i) if (_usage[i] > th) ++use; }
		_mTest[_arm][_seed] = mT; _mTrain[_arm][_seed] = mR; _mLsq[_arm][_seed] = lsq;
		_mOmp[_arm][_seed] = omp; _use[_arm][_seed] = use; _ok[_arm][_seed] = (mT < kBeat * _mBase[_arm][_seed]);
		LogA("[mlt] 🪓 %s [%2u/%u] 씨앗 %u — 시험 **%.5f** %s %.5f · 학습 %.5f · ㉯ %.5f ·"
		     " **OMP %.5f(비 %.2f)** · 사용률 %u\n", _ArmName(_arm), _seed + 1u, kSeeds, _seed,
			(double)mT, _ok[_arm][_seed] ? "<" : "≥", (double)(kBeat * _mBase[_arm][_seed]),
			(double)mR, (double)lsq, (double)omp, (double)((omp > 1e-9f) ? mT / omp : 0.0f), use);
		++_seed;
		if (_seed >= kSeeds)
		{
			_ArmSummary(); _seed = 0u; ++_arm;
			if (_arm >= kArms) { _Summary(); _E.Destroy(); return; }
		}
		_st = kInit;
	}

	static void _ArmSummary()
	{
		double sT = 0.0, sR = 0.0, sL = 0.0, sO = 0.0; uint32 sign = 0u, sU = 0u;
		for (uint32 i = 0; i < kSeeds; ++i)
		{
			sT += _mTest[_arm][i]; sR += _mTrain[_arm][i]; sL += _mLsq[_arm][i];
			sO += _mOmp[_arm][i]; sU += _use[_arm][i]; if (_ok[_arm][i]) ++sign;
		}
		const float mT = (float)(sT / kSeeds), mR = (float)(sR / kSeeds);
		const float mL = (float)(sL / kSeeds), mO = (float)(sO / kSeeds);
		LogA("[mlt] 🪓 ── %s ── 시험 **%.5f** · 학습 %.5f(비 %.2f) · ㉯ %.5f · OMP %.5f"
		     " ⇒ 모델/OMP **%.2f** · ㉠ %u/%u · 사용률 %.1f\n", _ArmName(_arm), (double)mT, (double)mR,
			(double)((mR > 1e-9f) ? mT / mR : 0.0f), (double)mL, (double)mO,
			(double)((mO > 1e-9f) ? mT / mO : 0.0f), sign, kSeeds, (double)((float)sU / kSeeds));
	}

	static float _BinomP(uint32 w)
	{
		double tot = 0.0;
		for (uint32 i = w; i <= kSeeds; ++i)
		{
			double c = 1.0; for (uint32 j = 0; j < i; ++j) c = c * (double)(kSeeds - j) / (double)(j + 1u);
			tot += c;
		}
		return (float)(tot / Pow(2.0f, (float)kSeeds));
	}

	static void _Summary()
	{
		float mT[kArms] = { 0.0f }, mR[kArms] = { 0.0f }, mO[kArms] = { 0.0f }, rat[kArms] = { 0.0f };
		uint32 sign[kArms] = { 0u };
		for (uint32 a = 0; a < kArms; ++a)
		{
			double sT = 0.0, sR = 0.0, sO = 0.0;
			for (uint32 i = 0; i < kSeeds; ++i)
			{ sT += _mTest[a][i]; sR += _mTrain[a][i]; sO += _mOmp[a][i]; if (_ok[a][i]) ++sign[a]; }
			mT[a] = (float)(sT / kSeeds); mR[a] = (float)(sR / kSeeds); mO[a] = (float)(sO / kSeeds);
			rat[a] = (mO[a] > 1e-9f) ? mT[a] / mO[a] : 0.0f;
		}
		uint32 w1 = 0u, w2 = 0u, w12 = 0u;
		for (uint32 i = 0; i < kSeeds; ++i)
		{
			if (_mTest[1][i] < _mTest[0][i]) ++w1;
			if (_mTest[2][i] < _mTest[0][i]) ++w2;
			if (_mTest[1][i] < _mTest[2][i]) ++w12;
		}
		const bool b1 = w1 >= kSignPass, b2 = w2 >= kSignPass, b12 = w12 >= kSignPass;
		bool alive[kArms] = { true, true, true };
		for (uint32 a = 1; a < kArms; ++a) alive[a] = mR[a] <= 2.0f * mR[0];
		LogA("[mlt] ══════════════════════════════════════════════════\n[mlt] 🪓 **선택/계수 분리 결과**\n");
		for (uint32 a = 0; a < kArms; ++a)
			LogA("[mlt] 🪓   %-12s 시험 **%.5f** · 학습 %.5f · OMP %.5f · 모델/OMP %.2f · ㉠ %u/%u · live %u\n",
				_ArmName(a), (double)mT[a], (double)mR[a], (double)mO[a], (double)rat[a], sign[a], kSeeds, _Live(a));
		LogA("[mlt] 🪓   생존: ㈁ %s · ㈂ %s (학습 MSE ≤ 2×㈀)\n", alive[1] ? "✅" : "⛔", alive[2] ? "✅" : "⛔");
		LogA("[mlt] 🪓   대응: ㈁>㈀ **%u/%u**(p=%.5f) · ㈂>㈀ **%u/%u**(p=%.5f) · ㈁>㈂ **%u/%u**(p=%.5f)\n",
			w1, kSeeds, (double)_BinomP(w1), w2, kSeeds, (double)_BinomP(w2), w12, kSeeds, (double)_BinomP(w12));
		LogA("[mlt] 🪓   %s ㉡ 완전 분리 모델/OMP %.2f ≤ %.1f\n", rat[1] <= kOmpRatio ? "✅" : "⛔",
			(double)rat[1], (double)kOmpRatio);
		const char* branch = (!alive[1] || !alive[2])
			? "⚠️ 판정불가 — 팔이 죽었다"
			: (b1 && b12) ? "㈀ 완전 분리 효과"
			: (b1 && b2) ? "㈁ 저랭크 인자화/최적화 효과"
			: (!b1 && !b2) ? "㈂ 선택/계수 분리도 축이 아니다"
			: "⚠️ 판정불가 — 대응 비교가 섞였다";
		LogA("[mlt] 🪓   ⭐ 갈래 판정 = %s\n", branch);
		LogA("[mlt] 🪓   ⓘ 씨앗 %u — ", kWatchSeed);
		for (uint32 a = 0; a < kArms; ++a) LogA("%s %.5f  ", _ArmName(a), (double)_mTest[a][kWatchSeed]);
		LogA("\n[mlt] ══════════════════════════════════════════════════\n");
	}
};
