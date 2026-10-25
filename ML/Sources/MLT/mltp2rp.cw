// mltp2rp.cw — 🔬 **회차 37~39 · 평가전용 잔차 교체 / 계수 갱신 / GPU 이전** (`-mltp2rpost`)
// 회차 36의 죽음을 순전파·STE·계수 몫으로 나누고, 계수 갱신을 실제 GPU 순전파까지 옮긴다.

using namespace PE;

class MLTP2RP
{
public:
	static void Tick(RHI* rhi)
	{
		if (_done || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltp2rpost"))
		{
			LogA("[mlt] 🔬 회차 37~39는 **꺼져 있다**(`-mltp2rpost`) — 평가 교체 **23.2%%** · 계수 1회 **93.0%%** · GPU **0.02873**\n");
			_done = true; return;
		}
		if (!_banner) { _Banner(); _banner = true; }
		if (_st == kInit)  { _BeginSeed(rhi); return; }
		if (_st == kTrain) { _Train(); return; }
		if (_st == kEval)  { _Eval(); return; }
	}

	static bool Done() { return _done; }

private:
	static constexpr uint32 kSeeds = 12u, kTrainF = 128u, kTestF = 8u, kEvalTr = 8u;
	static constexpr uint32 kPoolCap = kTrainF + kTestF, kSteps = 4800u, kN = 1000u, kK = 8u;
	static constexpr uint32 kPerTick = 4u, kTestEpisode = 1u;
	static constexpr float kRidge = 1.0e-6f, kBeat = 0.5f, kRecover = 0.5f;
	enum { kInit, kTrain, kEval };

	inline static MLTP2Enc _E;
	inline static bool _done = false, _banner = false;
	inline static uint32 _seed = 0u, _step = 0u, _ev = 0u, _swap = 0u, _swapDen = 0u;
	inline static int _st = kInit;
	inline static double _sumBase = 0.0, _sumPost = 0.0, _sumCoeffGpu = 0.0, _sumTrain = 0.0;
	inline static uint32 _nBase = 0u, _nPost = 0u, _nCoeffGpu = 0u, _nTrain = 0u;
	inline static Array<float> _tgtTest, _idsBase, _magBase, _code;
	inline static float _mBase[kSeeds] = { 0.0f }, _mPost[kSeeds] = { 0.0f };
	inline static float _mOracle[kSeeds] = { 0.0f }, _mCoeff[kSeeds] = { 0.0f }, _mLsq[kSeeds] = { 0.0f };
	inline static float _mCoeffGpu[kSeeds] = { 0.0f }, _mTrain[kSeeds] = { 0.0f };
	inline static float _mPass[kSeeds] = { 0.0f }, _mSwapFrac[kSeeds] = { 0.0f };

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🔬 **회차 37 · 학습은 1단계, 평가만 잔차 1회** — 씨앗 %u (k=%u N=%u F=%u %u스텝)\n",
			kSeeds, kK, kN, kTrainF, kSteps);
		LogA("[mlt] 🔬   같은 파라미터에서 모델 → 평가전용 1회 → CPU LSQ+1회 · 등록 회수 문턱 %.0f%%\n",
			(double)(100.0f * kRecover));
		LogA("[mlt] 🔧   계수 분해: 모델 계수 → 고정 ids 좌표 갱신 1회 → 고정 ids LSQ · 등록 회수 문턱 %.0f%%\n",
			(double)(100.0f * kRecover));
		LogA("[mlt] 🧪   회차 39: 같은 좌표 갱신의 GPU 평가전용 값이 CPU와 맞고 12/12 개선해야 통과\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

	static void _BeginSeed(RHI* rhi)
	{
		if (_seed == 0u)
		{
			// 잔차 텐서는 잡되 학습 중에는 끈다. 파라미터 수와 초기값은 기준선 그대로다.
			if (!_E.Setup(rhi, kPoolCap, kN, 0u, false, 0u, false, false, true, true))
			{ LogA("[mlt] 🔬 준비 실패\n"); _done = true; return; }
		}
		else if (!_E.ResetSeed()) { LogA("[mlt] 🔬 되돌리기 실패\n"); _done = true; return; }
		_E.SetK(kK); _E.SetSelectAbs(false); _E.SetResidualSwap(false); _E.SetCoeffSweep(false);

		Array<float> fr, tg; fr.Reset(0); tg.Reset(0); _tgtTest.Reset(0);
		ImageFormat::Bitmap bmp; Bytes packed;
		{
			MLTWorld w; w.Reset(_seed, 0u, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
			for (uint32 f = 0; f < kTrainF; ++f)
			{
				w.Step();
				if (!w.Render(bmp) || !MLTWorld::Pack(bmp, nullptr, packed))
				{ LogA("[mlt] 🔬 Render/Pack 실패(학습)\n"); _done = true; return; }
				MLTP2Enc::AppendFrame(fr, tg, (const uint8*)packed.GetData());
			}
		}
		{
			MLTWorld w; w.Reset(_seed, kTestEpisode, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
			for (uint32 f = 0; f < kTestF; ++f)
			{
				w.Step();
				if (!w.Render(bmp) || !MLTWorld::Pack(bmp, nullptr, packed))
				{ LogA("[mlt] 🔬 Render/Pack 실패(시험)\n"); _done = true; return; }
				const uint8* px = (const uint8*)packed.GetData();
				MLTP2Enc::AppendFrame(fr, tg, px);
				Array<float> one, dummy; one.Reset(0); dummy.Reset(0);
				MLTP2Enc::AppendFrame(dummy, one, px);
				for (uint32 i = 0; i < one.Count(); ++i) _tgtTest.Add(one[i]);
			}
		}
		if (!_E.WritePool(fr, tg, kPoolCap)) { LogA("[mlt] 🔬 풀 업로드 실패\n"); _done = true; return; }
		_mPass[_seed] = kBeat * MLTP2Enc::PatchConstMse(_tgtTest);
		_idsBase.Reset(0); _magBase.Reset(0); _step = 0u; _ev = 0u; _swap = 0u; _swapDen = 0u;
		_sumBase = 0.0; _sumPost = 0.0; _sumCoeffGpu = 0.0; _sumTrain = 0.0;
		_nBase = 0u; _nPost = 0u; _nCoeffGpu = 0u; _nTrain = 0u; _st = kTrain;
	}

	static void _Train()
	{
		for (uint32 i = 0; i < kPerTick && _step < kSteps; ++i)
		{
			_E.SetFrame(_step % kTrainF);
			if (!_E.Forward() || !_E.Backward() || !_E.AdamStep(1.0f))
			{ LogA("[mlt] 🔬 학습 실패(씨앗 %u 스텝 %u)\n", _seed, _step); _done = true; return; }
			++_step;
		}
		if (_step >= kSteps) { _st = kEval; _ev = 0u; }
	}

	static void _Eval()
	{
		const uint32 nEv = kTestF * 3u + kEvalTr;
		if (_ev > 0u)
		{
			const uint32 prev = _ev - 1u; float m = 0.0f; bool fin = true;
			if (!_E.ReadMse(m, fin) || !fin) { LogA("[mlt] 🔬 평가 리드백 실패/비유한\n"); _done = true; return; }
			if (prev < kTestF)
			{
				_sumBase += (double)m; ++_nBase;
				Array<float> id, mg;
				if (!_E.ReadAct(id, mg)) { LogA("[mlt] 🔬 기준 ids 리드백 실패\n"); _done = true; return; }
				for (uint32 i = 0; i < id.Count(); ++i) _idsBase.Add(id[i]);
				for (uint32 i = 0; i < mg.Count(); ++i) _magBase.Add(mg[i]);
			}
			else if (prev < kTestF * 2u)
			{
				_sumPost += (double)m; ++_nPost;
				uint32 sw = 0u; if (!_E.ReadSwapCount(sw)) { LogA("[mlt] 🔬 교체 수 리드백 실패\n"); _done = true; return; }
				_swap += sw; _swapDen += MLTP2Cfg::kPatches;
			}
			else if (prev < kTestF * 3u) { _sumCoeffGpu += (double)m; ++_nCoeffGpu; }
			else { _sumTrain += (double)m; ++_nTrain; }
		}
		if (_ev < nEv)
		{
			if (_ev < kTestF)
			{
				_E.SetResidualSwap(false); _E.SetCoeffSweep(false); _E.SetFrame(kTrainF + _ev);
			}
			else if (_ev < kTestF * 2u)
			{
				_E.SetResidualSwap(true); _E.SetFrame(kTrainF + (_ev - kTestF));
			}
			else if (_ev < kTestF * 3u)
			{
				_E.SetCoeffSweep(true); _E.SetFrame(kTrainF + (_ev - kTestF * 2u));
			}
			else
			{
				_E.SetCoeffSweep(false); _E.SetResidualSwap(false); _E.SetFrame(_ev - kTestF * 3u);
			}
			if (!_E.Forward()) { LogA("[mlt] 🔬 평가 forward 실패\n"); _done = true; return; }
			++_ev; return;
		}
		_JudgeSeed();
	}

	static void _JudgeSeed()
	{
		typedef MLTP2Cfg C;
		if (!_E.ReadCodebook(_code)) { LogA("[mlt] 🔬 코드북 리드백 실패\n"); _done = true; return; }
		const uint32 np = _tgtTest.Count() / C::kPix;
		const float mb = (_nBase != 0u) ? (float)(_sumBase / _nBase) : 0.0f;
		const float mp = (_nPost != 0u) ? (float)(_sumPost / _nPost) : 0.0f;
		const float mg = (_nCoeffGpu != 0u) ? (float)(_sumCoeffGpu / _nCoeffGpu) : 0.0f;
		const float mt = (_nTrain != 0u) ? (float)(_sumTrain / _nTrain) : 0.0f;
		const float mo = MLTP2Enc::SwapOneMse(_code, kN, _tgtTest, _idsBase, kK, np, kRidge);
		const float mc = MLTP2Enc::CoeffSweepMse(_code, kN, _tgtTest, _idsBase, _magBase, kK, np, kRidge);
		const float sf = (_swapDen != 0u) ? (float)_swap / (float)_swapDen : 0.0f;
		_mBase[_seed] = mb; _mPost[_seed] = mp; _mOracle[_seed] = mo; _mCoeff[_seed] = mc; _mCoeffGpu[_seed] = mg;
		_mTrain[_seed] = mt; _mSwapFrac[_seed] = sf;
		const float gap = mb - mo, got = mb - mp, frac = (gap > 1.0e-9f) ? got / gap : 0.0f;
		const float ml = MLTP2Enc::LsqMse(_code, kN, _tgtTest, _idsBase, kK, np, kRidge);
		_mLsq[_seed] = ml;
		const float cGap = mb - ml, cGot = mb - mc, cFrac = (cGap > 1.0e-9f) ? cGot / cGap : 0.0f;
		LogA("[mlt] 🔬 [%2u/%u] 씨앗 %u — 모델 **%.5f** → 평가1회 **%.5f** → LSQ+1회 **%.5f**"
		     " · 회수 %.1f%% · 계수 CPU/GPU **%.5f/%.5f** → 고정LSQ **%.5f**(%.1f%%) · 통과선 %.5f · 교체 %.1f%% · 학습 %.5f\n",
			_seed + 1u, kSeeds, _seed, (double)mb, (double)mp, (double)mo,
			(double)(100.0f * frac), (double)mc, (double)mg, (double)ml, (double)(100.0f * cFrac),
			(double)_mPass[_seed], (double)(100.0f * sf), (double)mt);
		++_seed;
		if (_seed >= kSeeds) { _Summary(); _E.Destroy(); _done = true; return; }
		_st = kInit;
	}

	static void _Summary()
	{
		double sb = 0.0, sp = 0.0, so = 0.0, sc = 0.0, sg = 0.0, sl = 0.0, st = 0.0, ss = 0.0;
		uint32 wins = 0u, passB = 0u, passP = 0u;
		for (uint32 i = 0; i < kSeeds; ++i)
		{
			sb += _mBase[i]; sp += _mPost[i]; so += _mOracle[i]; sc += _mCoeff[i]; sg += _mCoeffGpu[i]; sl += _mLsq[i];
			st += _mTrain[i]; ss += _mSwapFrac[i];
			if (_mPost[i] < _mBase[i]) ++wins;
			if (_mBase[i] < _mPass[i]) ++passB;
			if (_mPost[i] < _mPass[i]) ++passP;
		}
		const float mb = (float)(sb / kSeeds), mp = (float)(sp / kSeeds), mo = (float)(so / kSeeds);
		const float mt = (float)(st / kSeeds), sf = (float)(ss / kSeeds);
		const float gap = mb - mo, got = mb - mp, frac = (gap > 1.0e-9f) ? got / gap : 0.0f;
		LogA("[mlt] ══════════════════════════════════════════════════\n[mlt] 🔬 **평가전용 잔차 1회 결과**\n");
		LogA("[mlt] 🔬   모델 **%.5f** → 평가1회 **%.5f** → LSQ+1회 **%.5f** · 학습 %.5f\n",
			(double)mb, (double)mp, (double)mo, (double)mt);
		LogA("[mlt] 🔬   회수율 (모델−평가1회)/(모델−LSQ+1회) = **%.1f%%** · 등록 문턱 %.0f%%\n",
			(double)(100.0f * frac), (double)(100.0f * kRecover));
		LogA("[mlt] 🔬   엄격 개선 %u/%u · ㉠ %u/%u → %u/%u · 교체 %.1f%%\n",
			wins, kSeeds, passB, kSeeds, passP, kSeeds, (double)(100.0f * sf));
		LogA("[mlt] 🔬   ⭐ 갈래 판정 = %s\n", (frac >= kRecover)
			? "㈀ 순전파 교체는 충분하다 — 회차 36의 주원인은 STE 학습 동역학"
			: "㈁ 현재 점수 계수의 교체가 부족하다 — 다음은 계수 갱신 분해");
		const float mc = (float)(sc / kSeeds), ml = (float)(sl / kSeeds);
		const float mg = (float)(sg / kSeeds);
		const float cGap = mb - ml, cGot = mb - mc, cFrac = (cGap > 1.0e-9f) ? cGot / cGap : 0.0f;
		uint32 cWins = 0u; for (uint32 i = 0; i < kSeeds; ++i) if (_mCoeff[i] < _mBase[i]) ++cWins;
		LogA("[mlt] 🔧   모델 계수 **%.5f** → 좌표 갱신 1회 **%.5f** → 고정-id LSQ **%.5f**\n",
			(double)mb, (double)mc, (double)ml);
		LogA("[mlt] 🔧   계수 간격 회수율 **%.1f%%** · 엄격 개선 %u/%u · 등록 문턱 %.0f%%\n",
			(double)(100.0f * cFrac), cWins, kSeeds, (double)(100.0f * kRecover));
		LogA("[mlt] 🔧   ⭐ 계수 갈래 = %s\n", (cFrac >= kRecover)
			? "㈀ 한 번의 안전 갱신이 충분하다 — 다음 순전파 손잡이로 올린다"
			: "㈁ 한 번으로 부족하다 — 결합 계수 풀이나 반복 깊이를 먼저 잰다");
		uint32 gWins = 0u, gMatch = 0u;
		for (uint32 i = 0; i < kSeeds; ++i)
		{
			if (_mCoeffGpu[i] < _mBase[i]) ++gWins;
			const float tol = 1.0e-5f + 0.005f * _mCoeff[i];
			if (Abs(_mCoeffGpu[i] - _mCoeff[i]) <= tol) ++gMatch;
		}
		const float rel = (mc > 1.0e-9f) ? Abs(mg - mc) / mc : 0.0f;
		LogA("[mlt] 🧪   GPU 계수1회 **%.5f** ↔ CPU **%.5f** · 평균 상대차 %.3f%% · 수치일치 %u/%u · 개선 %u/%u\n",
			(double)mg, (double)mc, (double)(100.0f * rel), gMatch, kSeeds, gWins, kSeeds);
		LogA("[mlt] 🧪   ⭐ 회차 39 판정 = %s\n", (gMatch == kSeeds && gWins == kSeeds)
			? "✅ GPU 이전 통과 — 계수 갱신을 실제 모델 손잡이로 확정"
			: "⛔ GPU 이전 실패 — 학습 해석 전에 커널 계약부터 고친다");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}
};
