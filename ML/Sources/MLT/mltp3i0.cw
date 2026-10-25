// mltp3i0.cw — ⏳ 회차 64 · **몸통이 인코더를 밀 신호가 있나** (`-mltp3i0`)
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 64 이다.** (설계 심사 = 회차 63)
// ⭐ 상위 캔버스가 **새것**이다: **경험이 인코딩을 바꾸나**(㉣ 의 첫 걸음).
// ══════════════════════════════════════════════════════════════════════════════
//
// ⭐ *"관문이 과제 난이도보다 먼저다."* — 합동학습 배관을 **짓기 전에** 묻는다:
//   ***몸통 손실이 활성 값에 대해 0 이 아닌 기울기를 갖는가?***
//   ⇒ **인코더를 한 줄도 안 건드리고** 잰다(`MLTModel::ReadDVal` 하나 · 새 커널 0개).
//   ⇒ 없으면 회차 63 이 설계한 **교대 최적화 배관 전체가 불필요**해진다(큰 절약).
//
// ⭐ **자 = 탄력도**(무차원): `M = (mean |dVal|) × RMS(그 대역의 값) / CE`
//   ⚠️ 문턱을 손으로 안 정한다 — **상태 대역에 붙인다**. 상태는 회차 59 가 *"끊으면 CE 가 0.167
//     나빠진다"* 로 **쓰인다는 것을 12/12 로 세웠다** ⇒ 그 대역과 견줄 만하면 쓸 만한 크기다.

using namespace PE;

class MLTP3I0
{
public:
	static void Tick(RHI* rhi)
	{
		if (_done || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltp3i0"))
		{
			LogA("[mlt] ⏳ 회차 64는 **꺼져 있다**(`-mltp3i0`) — 몸통이 인코더를 밀 신호가 있나\n");
			_done = true; return;
		}
		if (!_banner) { _Banner(); _banner = true; }
		if (_seed >= kSeeds) { _Summary(); return; }
		if (_st == kEncInit)  { _EncBegin(rhi); return; }
		if (_st == kEncTrain) { _EncTrain(); return; }
		if (_st == kGather)   { _Gather(); return; }
		if (_st == kQuiesce)
		{
			if (_qWait > 0u) { --_qWait; return; }
			_st = kBodyInit; return;
		}
		if (_st == kBodyInit) { _BodyBegin(rhi); return; }
		if (_st == kBodyTrain) { _BodyTrain(); return; }
		if (_st == kProbe)    { _Probe(); return; }
	}

	static bool Done() { return _done; }

private:
	static constexpr uint32 kSeeds = 12u;
	static constexpr uint32 kEncF = 32u, kEncSteps = 1200u, kEncPerTick = 8u;
	static constexpr uint32 kN = 250u, kLocal = 8u;
	static constexpr uint32 kTime = MLTP3Ctx::kTime;
	static constexpr uint32 kBatch = MLTP3Ctx::kBatch;
	static constexpr uint32 kAxes = MLTP3Ctx::kAxes;
	static constexpr uint32 kSlots = MLTP3Ctx::kPersist;
	static constexpr uint32 kStateAx = MLTP3Ctx::kStateAx;
	static constexpr uint32 kCtxRow = MLTP3Ctx::kCtx;
	static constexpr uint32 kCandidates = MLTP2Cfg::kPatches * kLocal;
	static constexpr uint32 kNCtx = 128u, kTestCtx = 64u;
	static constexpr uint32 kTrainEpi = 1u, kTestEpi = 101u;
	static constexpr uint32 kPoolSteps = kNCtx / kBatch, kTestPool = kTestCtx / kBatch;
	static constexpr uint32 kGroup = kEncF / kTime;
	static constexpr uint32 kSteps = 800u, kPerTick = 4u;
	static constexpr uint32 kArms = 2u, kRep = 6u;
	static constexpr uint32 kSignPass = 10u;
	static constexpr float  kBeat = 0.5f;      // 표제① — `M_act > kBeat × M_state`

	enum { kEncInit, kEncTrain, kGather, kQuiesce, kBodyInit, kBodyTrain, kProbe };

	inline static MLTP2Enc _E;
	inline static MLTModel _M;
	inline static MLTP3Ctx _tr, _te;
	inline static bool _done = false, _banner = false, _encSetup = false, _finite = true;
	inline static bool _pending = false;
	inline static uint32 _seed = 0u, _st = kEncInit, _step = 0u, _arm = 0u, _rep = 0u;
	inline static uint32 _cor = 0u, _gGrp = 0u, _gIdx = 0u;
	inline static Array<float> _code, _norm;
	// 시험 코퍼스 값의 대역별 RMS(⚠️ CPU · GPU 무관 · 팔에 안 의존한다)
	inline static float _rmsAct = 1.0f, _rmsSt = 1.0f;
	// 훑기 상태
	inline static uint32 _rk = 0u, _rw = 0u; inline static bool _rpend = false;
	inline static double _sAct = 0.0, _sSt = 0.0, _sCe = 0.0;
	inline static uint32 _nAct = 0u, _nSt = 0u, _nCe = 0u;
	inline static double _slot[kSlots], _tstep[kTime];
	// 결과
	inline static float _runA[kRep], _runS[kRep];
	inline static float _mAct[kArms][kSeeds], _mSt[kArms][kSeeds];
	inline static float _mActA[kSeeds], _mActB[kSeeds], _mStA[kSeeds], _mStB[kSeeds];
	inline static bool  _seedOk[kSeeds];

	inline static uint32 _qWait = 0u;
	static void _ToBody() { _qWait = MLTEvalGate::kDelay; _st = kQuiesce; }

	static uint32 _Reps() { return (_arm == 0u) ? kRep : 1u; }
	static const char* _ArmName() { return (_arm == 0u) ? "㈀ 학습된 몸통" : "㈁ 초기화 몸통"; }

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] ⏳ **회차 64 · 몸통이 인코더를 밀 신호가 있나**(⭐ **새 상위: 경험이 인코딩을 바꾸나**)\n");
		LogA("[mlt] ⏳   자 = **탄력도**(무차원) `M = (mean |dVal|) × RMS(값) / CE` — 인코더는 **안 건드린다**\n");
		LogA("[mlt] ⏳   표제① `M_act > %.1f × M_state`(⭐ 문턱을 **회차 59 가 세운 대역**에 붙인다)\n", (double)kBeat);
		LogA("[mlt] ⏳   표제② `M_act(㈀) > M_act(㈁)` — ⭐ 그 신호가 **학습의 것인가**\n");
		LogA("[mlt] ⏳   ⇒ 없으면 회차 63 이 설계한 **합동학습 배관 전체가 불필요**해진다\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

	// ══════════════════════════════════════════════════════════════════
	static void _EncBegin(RHI* rhi)
	{
		if (!_encSetup)
		{
			if (!_E.Setup(rhi, kEncF, kN)) { _Fail("인코더 준비"); return; }
			_encSetup = true;
		}
		else if (!_E.ResetSeed()) { _Fail("인코더 되돌리기"); return; }
		_E.SetK(kLocal); _E.SetSelectAbs(false);
		Array<float> fr, tg; fr.Reset(0); tg.Reset(0);
		ImageFormat::Bitmap bmp; Bytes packed;
		MLTWorld w; w.Reset(_seed, 0u, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
		for (uint32 f = 0; f < kEncF; ++f)
		{
			w.Step();
			if (!w.Render(bmp) || !MLTWorld::Pack(bmp, nullptr, packed)) { _Fail("Render/Pack(인코더)"); return; }
			MLTP2Enc::AppendFrame(fr, tg, (const uint8*)packed.GetData());
		}
		if (!_E.WritePool(fr, tg, kEncF)) { _Fail("인코더 풀 업로드"); return; }
		_step = 0u; _st = kEncTrain;
	}

	static void _EncTrain()
	{
		for (uint32 i = 0; i < kEncPerTick && _step < kEncSteps; ++i)
		{
			_E.SetFrame(_step % kEncF);
			if (!_E.Forward() || !_E.Backward() || !_E.AdamStep(1.0f)) { _Fail("인코더 학습"); return; }
			++_step;
		}
		if (_step < kEncSteps) return;
		if (!_E.ReadCodebook(_code) || _code.Count() != kN * MLTP2Cfg::kPix) { _Fail("코드북 리드백"); return; }
		_norm.Reset(0);
		for (uint32 id = 0; id < kN; ++id)
		{
			double sq = 0.0; const float* a = _code.Data() + id * MLTP2Cfg::kPix;
			for (uint32 d = 0; d < MLTP2Cfg::kPix; ++d) sq += (double)a[d] * (double)a[d];
			_norm.Add((float)Sqrt((float)sq));
		}
		_tr.SetSortById(true); _te.SetSortById(true);
		_tr.Begin(kNCtx, kN); _te.Begin(kTestCtx, kN);
		_cor = 0u; _gGrp = 0u; _gIdx = 0u; _pending = false; _st = kGather;
	}

	static void _Gather()
	{
		MLTP3Ctx& C = (_cor == 0u) ? _tr : _te;
		const uint32 nCtx = (_cor == 0u) ? kNCtx : kTestCtx;
		if (_pending)
		{
			Array<float> ids, mag;
			if (!_E.ReadAct(ids, mag) || ids.Count() != kCandidates) { _Fail("활성 리드백"); return; }
			C.StoreAct(_gGrp * kGroup + (_gIdx - 1u) / kTime, (_gIdx - 1u) % kTime, ids, mag, _norm);
			_pending = false;
		}
		if (_gIdx == 0u)
		{
			Array<float> fr, tg; fr.Reset(0); tg.Reset(0);
			ImageFormat::Bitmap bmp; Bytes packed;
			const uint32 epi = (_cor == 0u) ? kTrainEpi : kTestEpi;
			for (uint32 g = 0; g < kGroup; ++g)
			{
				const uint32 ctx = _gGrp * kGroup + g;
				MLTWorld w; w.Reset(_seed, epi + ctx, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
				for (uint32 t = 0; t < kTime; ++t)
				{
					w.Step();
					if (!w.Render(bmp) || !MLTWorld::Pack(bmp, nullptr, packed)) { _Fail("Render/Pack(문맥)"); return; }
					MLTP2Enc::AppendFrame(fr, tg, (const uint8*)packed.GetData());
					C.StoreState(ctx, t, w.State());
				}
			}
			if (!_E.WritePool(fr, tg, kEncF)) { _Fail("문맥 풀 업로드"); return; }
		}
		if (_gIdx < kEncF)
		{
			_E.SetFrame(_gIdx);
			if (!_E.Forward()) { _Fail("문맥 forward"); return; }
			++_gIdx; _pending = true; return;
		}
		_gIdx = 0u;
		if (++_gGrp * kGroup >= nCtx)
		{
			_gGrp = 0u;
			if (++_cor >= 2u)
			{
				_ValRms();
				LogA("[mlt] ⏳ 씨앗 %2u · 시험 값 RMS — 활성 **%.4f** · 상태 **%.4f**\n",
					_seed, (double)_rmsAct, (double)_rmsSt);
				_arm = 0u; _rep = 0u; _ToBody();
			}
		}
	}

	// 시험 코퍼스 값의 대역별 RMS — ⚠️ 팔에 안 의존한다(코퍼스는 팔마다 같다).
	static void _ValRms()
	{
		double sa = 0.0, ss = 0.0; uint32 na = 0u, ns = 0u;
		for (uint32 ctx = 0; ctx < kTestCtx; ++ctx)
			for (uint32 t = 0; t < kTime; ++t)
			{
				for (uint32 a = 0; a < kStateAx; ++a)
				{ const double v = (double)_te.Val()[MLTP3Ctx::Row(ctx, t, a)]; ss += v * v; ++ns; }
				for (uint32 j = 0; j < kSlots; ++j)
				{ const double v = (double)_te.Val()[MLTP3Ctx::Row(ctx, t, kStateAx + j)]; sa += v * v; ++na; }
			}
		_rmsAct = (na == 0u) ? 1.0f : (float)Sqrt((float)(sa / (double)na));
		_rmsSt  = (ns == 0u) ? 1.0f : (float)Sqrt((float)(ss / (double)ns));
	}

	// ══════════════════════════════════════════════════════════════════
	static void _BodyBegin(RHI* rhi)
	{
		if (!_M.Setup(rhi, kStateAx + kN, kN, kAxes, kTime)) { _Fail("몸통 준비"); return; }
		if (!_M.UploadPool(_tr.Val(), _tr.Tgt(), kPoolSteps) || !_M.UploadSymbolPool(_tr.Sym(), kPoolSteps))
		{ _Fail("학습 풀 업로드"); return; }
		_step = 0u;
		if (_arm == 1u) { _ToProbe(); return; }
		_st = kBodyTrain;
	}

	static void _BodyTrain()
	{
		if (_step >= kSteps) { _ToProbe(); return; }
		for (uint32 i = 0; i < kPerTick && _step < kSteps; ++i)
		{
			_M.SelectStep(_step % kPoolSteps);
			if (!_M.Forward() || !_M.Backward() || !_M.AdamStep(1.0f)) { _Fail("몸통 스텝"); return; }
			++_step;
		}
	}

	static void _ToProbe()
	{
		if (!_M.UploadPool(_te.Val(), _te.Tgt(), kTestPool) || !_M.UploadSymbolPool(_te.Sym(), kTestPool))
		{ _Fail("시험 풀 업로드"); return; }
		_rk = 0u; _rw = 0u; _rpend = false;
		_sAct = 0.0; _sSt = 0.0; _sCe = 0.0; _nAct = 0u; _nSt = 0u; _nCe = 0u;
		for (uint32 j = 0; j < kSlots; ++j) _slot[j] = 0.0;
		for (uint32 t = 0; t < kTime; ++t) _tstep[t] = 0.0;
		_st = kProbe;
	}

	// 시험 풀을 한 바퀴 — `Forward` + `Backward` 로 `dVal` 을 만들고 읽는다.
	// ⚠️⚠️ **`AdamStep` 을 부르지 않는다** — 파라미터를 건드리면 팔이 달라진다.
	//   ★ 기울기 버퍼가 쌓이지만 **쓰지 않고** 다음 팔은 `Setup` 으로 새로 만든다.
	static void _Probe()
	{
		if (_rpend)
		{
			if (_rw > 0u) { --_rw; return; }
			Array<float> dv;
			float ce = 0.0f;
			if (!_M.ReadDVal(dv) || !_M.ReadLoss(ce)) { _Fail("dVal/CE 리드백"); return; }
			if (!(ce == ce) || ce > 1.0e30f) _finite = false;
			_sCe += (double)ce; ++_nCe;
			for (uint32 r = 0; r < dv.Count(); ++r)
			{
				const float g = dv[r];
				if (!(g == g) || g > 1.0e30f || g < -1.0e30f) { _finite = false; continue; }
				const uint32 inCtx = r % kCtxRow;
				const uint32 t = inCtx / kAxes, a = inCtx % kAxes;
				const double m = (double)Abs(g);
				if (a < kStateAx) { _sSt += m; ++_nSt; }
				else
				{
					_sAct += m; ++_nAct;
					_slot[a - kStateAx] += m;
					if (t < kTime) _tstep[t] += m;
				}
			}
			_rpend = false; ++_rk;
		}
		if (_rk >= kTestPool) { _Record(); return; }
		_M.SelectStep(_rk);
		if (!_M.Forward() || !_M.Backward()) { _Fail("dVal forward/backward"); return; }
		_rw = MLTEvalGate::kDelay; _rpend = true;
	}

	// 탄력도 — ⚠️ `(mean |dVal|) × RMS(값) / CE`(무차원). 값을 **곱**하고 손실로 **나눈다**.
	static void _Record()
	{
		const double ce = (_nCe == 0u) ? 1.0 : (_sCe / (double)_nCe);
		const double ma = (_nAct == 0u) ? 0.0 : (_sAct / (double)_nAct);
		const double ms = (_nSt == 0u) ? 0.0 : (_sSt / (double)_nSt);
		const double den = (ce > 1.0e-12) ? ce : 1.0e-12;
		_runA[_rep] = (float)(ma * (double)_rmsAct / den);
		_runS[_rep] = (float)(ms * (double)_rmsSt / den);
		if (_rep == 0u && _arm == 0u)
		{
			// 눈금 — 슬롯별·시각별 분포(첫 반복만 찍는다).
			double tot = 0.0;
			for (uint32 j = 0; j < kSlots; ++j) tot += _slot[j];
			if (tot > 0.0)
			{
				LogA("[mlt] ⏳     눈금 슬롯%%: ");
				for (uint32 j = 0; j < kSlots; ++j) LogA("%.1f ", 100.0 * _slot[j] / tot);
				LogA("\n[mlt] ⏳     눈금 시각%%: ");
				double tt = 0.0;
				for (uint32 t = 0; t < kTime; ++t) tt += _tstep[t];
				for (uint32 t = 0; t < kTime; ++t) LogA("%.1f ", (tt > 0.0) ? (100.0 * _tstep[t] / tt) : 0.0);
				LogA("\n");
			}
		}
		if (++_rep < _Reps()) { _ToBody(); return; }
		_Agg();
	}

	static void _Agg()
	{
		const uint32 Rn = _Reps();
		double a = 0.0, s = 0.0, aA = 0.0, aB = 0.0, sA = 0.0, sB = 0.0;
		uint32 nA = 0u, nB = 0u;
		for (uint32 i = 0; i < Rn; ++i)
		{
			a += (double)_runA[i]; s += (double)_runS[i];
			if ((i % 2u) == 0u) { aA += (double)_runA[i]; sA += (double)_runS[i]; ++nA; }
			else                { aB += (double)_runA[i]; sB += (double)_runS[i]; ++nB; }
		}
		_mAct[_arm][_seed] = (float)(a / (double)Rn);
		_mSt[_arm][_seed]  = (float)(s / (double)Rn);
		if (_arm == 0u)
		{
			_mActA[_seed] = (nA == 0u) ? _mAct[0][_seed] : (float)(aA / (double)nA);
			_mActB[_seed] = (nB == 0u) ? _mAct[0][_seed] : (float)(aB / (double)nB);
			_mStA[_seed]  = (nA == 0u) ? _mSt[0][_seed]  : (float)(sA / (double)nA);
			_mStB[_seed]  = (nB == 0u) ? _mSt[0][_seed]  : (float)(sB / (double)nB);
		}
		LogA("[mlt] ⏳   %s 씨앗 %2u · **M_act %.5f** · M_state %.5f · 비 **%.2f** · R=%u\n",
			_ArmName(), _seed, (double)_mAct[_arm][_seed], (double)_mSt[_arm][_seed],
			(_mSt[_arm][_seed] > 1.0e-12f) ? (double)(_mAct[_arm][_seed] / _mSt[_arm][_seed]) : 0.0, Rn);
		_rep = 0u;
		if (++_arm < kArms) { _ToBody(); return; }
		_seedOk[_seed] = _finite;
		++_seed; _st = kEncInit;
	}

	static void _Summary()
	{
		double ma[kArms], ms[kArms], mr = 0.0;
		for (uint32 i = 0; i < kArms; ++i) { ma[i] = 0.0; ms[i] = 0.0; }
		uint32 ok = 0u, t1 = 0u, t2 = 0u, a1 = 0u, a2 = 0u, b1 = 0u, b2 = 0u;
		for (uint32 s = 0; s < kSeeds; ++s)
		{
			if (!_seedOk[s]) continue;
			++ok;
			for (uint32 i = 0; i < kArms; ++i) { ma[i] += _mAct[i][s]; ms[i] += _mSt[i][s]; }
			if (_mSt[0][s] > 1.0e-12f) mr += (double)(_mAct[0][s] / _mSt[0][s]);
			if (_mAct[0][s] > kBeat * _mSt[0][s]) ++t1;
			if (_mAct[0][s] > _mAct[1][s]) ++t2;
			if (_mActA[s] > kBeat * _mStA[s]) ++a1;
			if (_mActA[s] > _mAct[1][s]) ++a2;
			if (_mActB[s] > kBeat * _mStB[s]) ++b1;
			if (_mActB[s] > _mAct[1][s]) ++b2;
		}
		if (ok > 0u) { for (uint32 i = 0; i < kArms; ++i) { ma[i] /= ok; ms[i] /= ok; } mr /= ok; }
		const bool split = (a1 >= kSignPass) && (a2 >= kSignPass) && (b1 >= kSignPass) && (b2 >= kSignPass);
		const bool p1 = (t1 >= kSignPass), p2 = (t2 >= kSignPass);

		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] ⏳ **회차 64 · 몸통이 인코더를 밀 신호가 있나** — 읽은 씨앗 %u/%u\n", ok, kSeeds);
		LogA("[mlt] ⏳   탄력도 — ㈀ 학습됨 M_act **%.5f** / M_state %.5f(비 **%.2f**)\n", ma[0], ms[0], mr);
		LogA("[mlt] ⏳   탄력도 — ㈁ 초기화 M_act **%.5f** / M_state %.5f\n", ma[1], ms[1]);
		LogA("[mlt] ⏳   **표제① 쓸 만한 크기** `M_act > %.1f×M_state` — **%u/%u**(필요 %u)\n",
			(double)kBeat, t1, kSeeds, kSignPass);
		LogA("[mlt] ⏳   **표제② 학습의 것인가** `㈀ > ㈁` — **%u/%u**(필요 %u)\n", t2, kSeeds, kSignPass);
		LogA("[mlt] ⏳   위생 분할 반쪽 — A(①%u ②%u) · B(①%u ②%u) → %s\n",
			a1, a2, b1, b2, split ? "통과" : "⛔");
		if (!_finite)
			LogA("[mlt] ⏳   ⭐ 판정 = ⛔ **판정불가** — 유한하지 않은 값이 있다\n");
		else if (p1 && p2 && split)
			LogA("[mlt] ⏳   ⭐ 판정 = ✅ **밀 신호가 있고 학습이 그것을 키웠다** ⇒ 회차 65 = **교대 최적화 배관**\n");
		else if (p1 && !p2)
			LogA("[mlt] ⏳   ⭐ 판정 = ⚠️ **신호는 있는데 학습의 것이 아니다** — 배관을 짓되 **기대를 낮춘다**(등록 다시)\n");
		else if (!p1)
			LogA("[mlt] ⏳   ⭐ 판정 = ⛔⛔ **합동학습 배관을 짓지 않는다** — 밀 신호가 없다 ⇒ **`q` 선택자 재질문**의 조건\n");
		else
			LogA("[mlt] ⏳   ⭐ 판정 = ⚠️ **판정불가**(분할 반쪽이 안 맞는다)\n");
		LogA("[mlt] ⏳   ⚠️ 고정 %u문맥의 진단이다 — 절대 성능으로 인용하지 않는다\n", kNCtx);
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		_E.Destroy(); _done = true;
	}

	static void _Fail(const char* why)
	{
		LogA("[mlt] ⏳ ⛔ %s (씨앗 %u · 팔 %u · 반복 %u · 단계 %u)\n", why, _seed, _arm, _rep, _st);
		_E.Destroy(); _done = true;
	}
};
