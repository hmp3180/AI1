// mltp2r.cw — 🔁 **P2 걸음 14 · 공유 코드북 잔차 교체 한 번** (`-mltp2r`)
//
// 등록문 정본은 `mltlog_1.md` 회차 35 끝이다.
// ㈀ 현재 1단계 ↔ ㈁ 같은 점수·코드북으로 잔차를 보고 원자 하나만 교체한다.
// 최종 k=8·파라미터·데이터·4800스텝은 같다. CPU LSQ는 순전파와 역전파 어디에도 없다.

using namespace PE;

class MLTP2R
{
public:
	static void Tick(RHI* rhi)
	{
		if (_arm >= kArms || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltp2r"))
		{
			LogA("[mlt] 🔁 걸음 14(잔차 1회 모델)은 **꺼져 있다**(`-mltp2r`) — 회차 35 오라클 회수율 **61.6%%**\n");
			_arm = kArms; return;
		}
		if (!_banner) { _Banner(); _banner = true; }
		if (_st == kInit)  { _BeginSeed(rhi); return; }
		if (_st == kTrain) { _Train(); return; }
		if (_st == kEval)  { _Eval(); return; }
	}

	static bool Done() { return _arm >= kArms; }

private:
	static constexpr uint32 kArms = 2u, kSeeds = 12u;
	static constexpr bool kResidual[kArms] = { false, true };
	static constexpr uint32 kTrainF = 128u, kTestF = 8u, kPoolCap = kTrainF + kTestF;
	static constexpr uint32 kSteps = 4800u, kN = 1000u, kK = 8u;
	static constexpr uint32 kPerTick = 4u, kEvalTr = 8u, kTestEpisode = 1u;
	static constexpr float kRidge = 1.0e-6f, kBeat = 0.5f, kOmpRatio = 2.0f, kUseFrac = 0.01f;
	static constexpr uint32 kSignPass = 10u, kBudget = 500000u, kLiveSlot = 384u;
	enum { kInit, kTrain, kEval };

	inline static MLTP2Enc _E;
	inline static bool _banner = false;
	inline static uint32 _arm = 0u, _seed = 0u, _step = 0u, _ev = 0u;
	inline static int _st = kInit;
	inline static double _sumTest = 0.0, _sumTrain = 0.0;
	inline static uint32 _nTest = 0u, _nTrain = 0u, _swap = 0u, _swapDen = 0u;
	inline static Array<float> _tgtTest, _idsTest, _code, _usage;
	inline static float _mTest[kArms][kSeeds] = { { 0.0f } };
	inline static float _mTrain[kArms][kSeeds] = { { 0.0f } };
	inline static float _mOmp[kArms][kSeeds] = { { 0.0f } };
	inline static float _mBase[kArms][kSeeds] = { { 0.0f } };
	inline static float _mSwapFrac[kArms][kSeeds] = { { 0.0f } };
	inline static uint32 _use[kArms][kSeeds] = { { 0u } };

	static const char* _ArmName(uint32 a) { return (a == 0u) ? "㈀1단계" : "㈁잔차1회"; }
	static uint32 _Live() { return MLTP2Enc::LiveParams(kLiveSlot, kN); }

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🔁 **P2 걸음 14 · 공유 코드북 잔차 1회 모델** — 팔 %u × 씨앗 %u (k=%u N=%u F=%u %u스텝)\n",
			kArms, kSeeds, kK, kN, kTrainF, kSteps);
		LogA("[mlt] 🔁   ㈀ 현재 top-k → recon · ㈁ 현재 recon의 잔차로 원자 하나 교체(no-op 포함)\n");
		LogA("[mlt] 🔁   live **%u**%s · LSQ/정답 id/생성기 상태 0 · 대응 승리 문턱 **%u/%u**\n",
			_Live(), (_Live() <= kBudget) ? " ✅" : " ⛔예산초과", kSignPass, kSeeds);
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

	static void _BeginSeed(RHI* rhi)
	{
		if (_seed == 0u)
		{
			if (!_E.Setup(rhi, kPoolCap, kN, 0u, false, 0u, false, false, kResidual[_arm]))
			{ LogA("[mlt] 🔁 준비 실패(%s)\n", _ArmName(_arm)); _arm = kArms; return; }
		}
		else if (!_E.ResetSeed()) { LogA("[mlt] 🔁 되돌리기 실패\n"); _arm = kArms; return; }
		_E.SetK(kK); _E.SetSelectAbs(false);

		Array<float> fr, tg; fr.Reset(0); tg.Reset(0); _tgtTest.Reset(0);
		ImageFormat::Bitmap bmp; Bytes packed;
		{
			MLTWorld w; w.Reset(_seed, 0u, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
			for (uint32 f = 0; f < kTrainF; ++f)
			{
				w.Step();
				if (!w.Render(bmp) || !MLTWorld::Pack(bmp, nullptr, packed))
				{ LogA("[mlt] 🔁 Render/Pack 실패(학습)\n"); _arm = kArms; return; }
				MLTP2Enc::AppendFrame(fr, tg, (const uint8*)packed.GetData());
			}
		}
		{
			MLTWorld w; w.Reset(_seed, kTestEpisode, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
			for (uint32 f = 0; f < kTestF; ++f)
			{
				w.Step();
				if (!w.Render(bmp) || !MLTWorld::Pack(bmp, nullptr, packed))
				{ LogA("[mlt] 🔁 Render/Pack 실패(시험)\n"); _arm = kArms; return; }
				const uint8* px = (const uint8*)packed.GetData();
				MLTP2Enc::AppendFrame(fr, tg, px);
				Array<float> one, dummy; one.Reset(0); dummy.Reset(0);
				MLTP2Enc::AppendFrame(dummy, one, px);
				for (uint32 i = 0; i < one.Count(); ++i) _tgtTest.Add(one[i]);
			}
		}
		if (!_E.WritePool(fr, tg, kPoolCap)) { LogA("[mlt] 🔁 풀 업로드 실패\n"); _arm = kArms; return; }
		_mBase[_arm][_seed] = MLTP2Enc::PatchConstMse(_tgtTest);
		_usage.Reset(0); for (uint32 i = 0; i < _E.N(); ++i) _usage.Add(0.0f);
		_idsTest.Reset(0); _step = 0u; _ev = 0u; _sumTest = 0.0; _sumTrain = 0.0;
		_nTest = 0u; _nTrain = 0u; _swap = 0u; _swapDen = 0u; _st = kTrain;
	}

	static void _Train()
	{
		for (uint32 i = 0; i < kPerTick && _step < kSteps; ++i)
		{
			_E.SetFrame(_step % kTrainF);
			if (!_E.Forward() || !_E.Backward() || !_E.AdamStep(1.0f))
			{ LogA("[mlt] 🔁 스텝 실패(%s 씨앗 %u 스텝 %u)\n", _ArmName(_arm), _seed, _step); _arm = kArms; return; }
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
			if (!_E.ReadMse(m, fin) || !fin) { LogA("[mlt] 🔁 평가 리드백 실패/비유한\n"); _arm = kArms; return; }
			if (prev < kTestF)
			{
				_sumTest += (double)m; ++_nTest;
				Array<float> id, mg;
				if (!_E.ReadAct(id, mg)) { LogA("[mlt] 🔁 선택 리드백 실패\n"); _arm = kArms; return; }
				for (uint32 i = 0; i < id.Count(); ++i) _idsTest.Add(id[i]);
				if (!_E.AccumUsage(_usage)) { LogA("[mlt] 🔁 사용률 리드백 실패\n"); _arm = kArms; return; }
				uint32 sw = 0u; if (!_E.ReadSwapCount(sw)) { LogA("[mlt] 🔁 교체 수 리드백 실패\n"); _arm = kArms; return; }
				_swap += sw; _swapDen += MLTP2Cfg::kPatches;
			}
			else { _sumTrain += (double)m; ++_nTrain; }
		}
		if (_ev < nEv)
		{
			_E.SetFrame((_ev < kTestF) ? (kTrainF + _ev) : (_ev - kTestF));
			if (!_E.Forward()) { LogA("[mlt] 🔁 평가 forward 실패\n"); _arm = kArms; return; }
			++_ev; return;
		}
		_JudgeSeed();
	}

	static void _JudgeSeed()
	{
		typedef MLTP2Cfg C;
		if (!_E.ReadCodebook(_code)) { LogA("[mlt] 🔁 코드북 리드백 실패\n"); _arm = kArms; return; }
		const float mt = (_nTest != 0u) ? (float)(_sumTest / _nTest) : 0.0f;
		const float mr = (_nTrain != 0u) ? (float)(_sumTrain / _nTrain) : 0.0f;
		const uint32 np = _tgtTest.Count() / C::kPix;
		const float omp = MLTP2Enc::OmpMse(_code, kN, _tgtTest, kK, np, kRidge);
		float mx = 0.0f; for (uint32 i = 0; i < _E.N(); ++i) if (_usage[i] > mx) mx = _usage[i];
		uint32 use = 0u;
		if (mx > 0.0f) { const float th = kUseFrac * mx; for (uint32 i = 0; i < _E.N(); ++i) if (_usage[i] > th) ++use; }
		const float sf = (_swapDen != 0u) ? (float)_swap / (float)_swapDen : 0.0f;
		_mTest[_arm][_seed] = mt; _mTrain[_arm][_seed] = mr; _mOmp[_arm][_seed] = omp;
		_mSwapFrac[_arm][_seed] = sf; _use[_arm][_seed] = use;
		LogA("[mlt] 🔁 %s [%2u/%u] 씨앗 %u — 시험 **%.5f** %s %.5f · 학습 %.5f · OMP %.5f(비 %.2f)"
		     " · 교체 %.1f%% · 사용률 %u\n", _ArmName(_arm), _seed + 1u, kSeeds, _seed,
			(double)mt, (mt < kBeat * _mBase[_arm][_seed]) ? "<" : "≥", (double)(kBeat * _mBase[_arm][_seed]),
			(double)mr, (double)omp, (double)((omp > 1.0e-9f) ? mt / omp : 0.0f), (double)(100.0f * sf), use);
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
		double st = 0.0, sr = 0.0, so = 0.0, ss = 0.0; uint32 pass = 0u, su = 0u;
		for (uint32 i = 0; i < kSeeds; ++i)
		{
			st += _mTest[_arm][i]; sr += _mTrain[_arm][i]; so += _mOmp[_arm][i]; ss += _mSwapFrac[_arm][i];
			su += _use[_arm][i]; if (_mTest[_arm][i] < kBeat * _mBase[_arm][i]) ++pass;
		}
		const float mt = (float)(st / kSeeds), mr = (float)(sr / kSeeds), mo = (float)(so / kSeeds);
		LogA("[mlt] 🔁 ── %s ── 시험 **%.5f** · 학습 %.5f · OMP %.5f · 모델/OMP %.2f · ㉠ %u/%u"
		     " · 교체 %.1f%% · 사용률 %.1f\n", _ArmName(_arm), (double)mt, (double)mr, (double)mo,
			(double)((mo > 1.0e-9f) ? mt / mo : 0.0f), pass, kSeeds,
			(double)(100.0 * ss / kSeeds), (double)((float)su / kSeeds));
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
		float mt[kArms] = { 0.0f }, mr[kArms] = { 0.0f }, mo[kArms] = { 0.0f }, sf[kArms] = { 0.0f };
		uint32 pass[kArms] = { 0u }, wins = 0u;
		for (uint32 a = 0; a < kArms; ++a)
		{
			double st = 0.0, sr = 0.0, so = 0.0, ss = 0.0;
			for (uint32 i = 0; i < kSeeds; ++i)
			{
				st += _mTest[a][i]; sr += _mTrain[a][i]; so += _mOmp[a][i]; ss += _mSwapFrac[a][i];
				if (_mTest[a][i] < kBeat * _mBase[a][i]) ++pass[a];
			}
			mt[a] = (float)(st / kSeeds); mr[a] = (float)(sr / kSeeds); mo[a] = (float)(so / kSeeds); sf[a] = (float)(ss / kSeeds);
		}
		for (uint32 i = 0; i < kSeeds; ++i) if (_mTest[1][i] < _mTest[0][i]) ++wins;
		const bool alive = mr[1] <= 2.0f * mr[0];
		const bool axis = alive && wins >= kSignPass;
		LogA("[mlt] ══════════════════════════════════════════════════\n[mlt] 🔁 **잔차 1회 모델 결과**\n");
		for (uint32 a = 0; a < kArms; ++a)
			LogA("[mlt] 🔁   %s — 시험 **%.5f** · 학습 %.5f · OMP %.5f · 모델/OMP %.2f · ㉠ %u/%u"
			     " · 교체 %.1f%% · live %u\n", _ArmName(a), (double)mt[a], (double)mr[a], (double)mo[a],
				(double)((mo[a] > 1.0e-9f) ? mt[a] / mo[a] : 0.0f), pass[a], kSeeds,
				(double)(100.0f * sf[a]), _Live());
		LogA("[mlt] 🔁   생존 %s — ㈁학습 %.5f %s 2×㈀ %.5f\n", alive ? "✅" : "⛔", (double)mr[1],
			alive ? "≤" : ">", (double)(2.0f * mr[0]));
		LogA("[mlt] 🔁   대응 ㈁>㈀ **%u/%u**(p=%.5f · 문턱 %u/%u)\n",
			wins, kSeeds, (double)_BinomP(wins), kSignPass, kSeeds);
		LogA("[mlt] 🔁   ㈁ 모델/OMP %.2f %s %.1f\n", (double)((mo[1] > 1.0e-9f) ? mt[1] / mo[1] : 0.0f),
			(mt[1] <= kOmpRatio * mo[1]) ? "≤" : ">", (double)kOmpRatio);
		LogA("[mlt] 🔁   ⭐ 갈래 판정 = %s\n", !alive ? "⚠️ 판정불가 — 팔이 죽었다"
			: axis ? "㈀ 반복 깊이가 축이다" : "㈁ 이 1회 반복은 모델 손잡이가 아니다");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}
};
