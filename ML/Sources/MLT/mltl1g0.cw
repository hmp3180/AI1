// mltl1g0.cw — 🎯 회차 144 · **왜 못 배우나 — 손실 가중인가 걸음인가** (`-mlt -mltl1g0`)
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 144 다.** ⭐ **하네스보다 먼저 썼다.**
//   **상위 캔버스: `모델이 변화 표적을 배우나` · 143~144 = 2회차.**
//
// ── ⭐ 표제 — ***목표선 `2.1111` 을 깨는 팔이 있나*** ─────────────────
//   회차 143: 몸통 **2.7666** ↔ 학습 0 예측기 최선 **2.1111**(㉢ 슬롯 id 배제).
//   ⇒ 물음은 ***왜 못 배우나*** 이고 후보 둘을 **한 회차에서** 가른다
//     (⭐ gather 가 비용의 대부분이라 **걸음 4배 팔이 거의 공짜**다).
//
// ── 🎛️ 팔 넷 — ⚠️ 낱말 축은 **전부 상수(값 0)** ⇒ 141 의 ㈀ 과 같은 배치(14축) ──
//   ㈀ 전체 손실 · 800   — 바닥 · ⭐ **검산**(141 의 2.7666 이어야)
//   ⭐ ㈁ **변화 표적만** 손실 · 800  — ⭐ **손실 가중 후보**(지속 75%가 손실을 먹나)
//   ⭐ ㈂ 전체 손실 · **3200**        — ⭐ **걸음/용량 후보**(덜 배운 것인가)
//   ㈃ **지속 표적만** 손실 · 800     — **대조**(변화를 아예 안 배운 팔 ⇒ ㈀ 보다 나빠야)
//   ⚠️⚠️ **㈁ 에는 교란이 있다** — 손실 표적이 `56 → 14` 로 줄어 **유효 표본이 1/4** 다.
//     ⇒ ★ ㈁ 이 ⛔ 면 *"손실 가중이 아니다"* 가 아니라 ***"손실 가중인지 표본인지 못 가른다"*** 다.
//
// ── 📏 자 — ⭐ 무차원(규율 31) ────────────────────────────────────────────
//   `도달률 = (CE(㈀) − CE(팔)) / (CE(㈀) − 2.1111)`   0 = 안 내려감 · 1 = 목표선 도달
//   ⭐ 분모가 **회차 143 의 목표선**이라 눈금이 밖에서 온다. + 짝지은 차 ± SE(**실행 항 포함**).
//
// ── 🔮 예측(재기 전에 적었다) ────────────────────────────────────────────
//   검산 ㈀ 2.7666±0.05 · ⭐ ㈁ **1.9~2.4**(도달률 0.5~1.2) · ⭐ ㈂ 2.55~2.72(도달률 0.1~0.3
//   ⇒ 걸음은 주범이 아닐 것) · ㈃ 2.9~3.4(㈀ 보다 나쁘다).
//   ⭐ 표제 = ✅ **㈁ 이 ㈀ 를 뚜렷히 이길 것** · ⚠️ 목표선 돌파는 **반반**.
//   ⚠️ 위험: 넷 다 못 깨면 ⇒ **표현**(활성 사전이 변화를 못 담는다)이고 캔버스가 또 바뀐다.
// ══════════════════════════════════════════════════════════════════════════════

using namespace PE;

class MLTL1G0
{
public:
	static void Tick(RHI* rhi)
	{
		if (_done || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltl1g0"))
		{
			LogA("[mlt] 🎯 회차 144(왜 못 배우나 — 손실 가중인가 걸음인가)는 **꺼져 있다**(`-mltl1g0`)\n");
			_done = true; return;
		}
		if (!_banner) { _seeds = OS::CommandLine::Has("-mltdiag1") ? 1u : kSeedsMax; _Banner(); _banner = true; }
		if (_seed >= _seeds) { _Summary(); return; }
		if (_st == kEncInit)  { _EncBegin(rhi); return; }
		if (_st == kEncTrain) { _EncTrain(); return; }
		if (_st == kGather)   { _Gather(); return; }
		if (_st == kQuiesce)
		{
			if (_qWait > 0u) { --_qWait; return; }
			_st = kBodyInit; return;
		}
		if (_st == kBodyInit)  { _BodyBegin(rhi); return; }
		if (_st == kBodyTrain) { _BodyTrain(); return; }
		_EvalStep();
	}

	static bool Done() { return _done; }

private:
	static constexpr uint32 kSeedsMax = 12u;
	inline static uint32 _seeds = kSeedsMax;

	static constexpr uint32 kEncF = 32u, kEncSteps = 1200u, kEncPerTick = 8u;
	static constexpr uint32 kN = 250u, kLocal = 8u;
	static constexpr uint32 kTime  = MLTP3Ctx::kTime;      // 8
	static constexpr uint32 kBatch = MLTP3Ctx::kBatch;     // 8
	static constexpr uint32 kSlots = MLTP3Ctx::kPersist;   // 8
	static constexpr uint32 kStateAx = MLTP3Ctx::kStateAx; // 5
	static constexpr uint32 kCandidates = MLTP2Cfg::kPatches * kLocal;
	static constexpr uint32 kGroup = kEncF / kTime;        // 4

	// ⚠️ 138~143 과 **같은 코퍼스**. `_pbA` 는 안 쓴다.
	static constexpr uint32 kNCtx = 512u, kPtCtx = 512u;
	static constexpr uint32 kTrainEpi = 1u, kPtEpi = 5001u;
	static constexpr uint32 kPoolSteps = kNCtx / kBatch;
	static constexpr uint32 kPtPool = kPtCtx / kBatch;
	static constexpr uint32 kPerTick = 16u;

	static constexpr uint32 kSymA = MLTP3Ctx::kStateAx + kN + 1u;    // 256
	static constexpr uint32 kAx13 = MLTP3Ctx::kAxes;                 // 13
	static constexpr uint32 kAx14 = kAx13 + 1u;                      // 14
	static constexpr uint32 kCtx14 = kAx14 * kTime;                  // 112
	static constexpr uint32 kRows14 = kBatch * kCtx14;               // 896
	static constexpr float  kWordSym = 255.0f;
	// ⭐ 낱말은 **전부 상수** — 141 의 ㈀ 과 같은 값(계급 4 / 9 ⇒ 정확히 0)
	static constexpr uint32 kWordCls = 9u, kConstCls = 4u;

	// ⭐ 밖에서 온 눈금 둘 — ⚠️ 여기서 새로 재지 않는다.
	static constexpr float kCE141   = 2.7666f;   // 회차 141 · 몸통의 변화 CE(㈀ 과 같은 배치)
	static constexpr float kTarget  = 2.1111f;   // 회차 143 · 학습 0 예측기의 최선(㉢)

	static constexpr uint32 kArms = 4u;
	static constexpr uint32 kStepsOf[kArms] = { 800u, 800u, 3200u, 800u };
	enum { kMAll = 0u, kMChange = 1u, kMKeep = 2u, kMNone = 3u };
	static constexpr uint32 kTrMaskOf[kArms] = { kMNone, kMChange, kMNone, kMKeep };

	static constexpr uint32 kOut = 2u;
	enum { kEncInit, kEncTrain, kGather, kQuiesce, kBodyInit, kBodyTrain, kEval };

	inline static MLTP2Enc _E;
	inline static MLTModel _M;
	inline static MLTP3Ctx _trA, _ptA;
	inline static bool _done = false, _banner = false, _encSetup = false, _finite = true;
	inline static bool _pending = false;
	inline static uint32 _seed = 0u, _st = kEncInit, _step = 0u;
	inline static uint32 _arm = 0u, _out = 0u, _evalIdx = 0u;
	inline static uint32 _cor = 0u, _gGrp = 0u, _gIdx = 0u, _qWait = 0u;
	inline static Array<float> _code, _norm;
	inline static Array<uint32> _wConst;
	inline static Array<float> _eVal[2], _eSym[2], _eTgt[2];
	inline static MLTEvalGate _gate;

	inline static float _ce[kOut][kArms][kSeedsMax];        // ⭐ 판정용 = 변화만
	inline static float _ceK[kOut][kArms][kSeedsMax];       // 📊 보고 = 지속만
	inline static bool  _seedOk[kSeedsMax];
	inline static double _nCh[kSeedsMax], _nKe[kSeedsMax];
	inline static uint32 _lastScored = 0u;

	static void _ToBody() { _qWait = MLTEvalGate::kDelay; _st = kQuiesce; }
	static const char* _ArmName(uint32 a)
	{
		switch (a)
		{
		case 0u: return "㈀ 전체손실·800(바닥) ";
		case 1u: return "㈁ 변화만·800 ⭐      ";
		case 2u: return "㈂ 전체·3200걸음 ⭐   ";
		default: return "㈃ 지속만·800(대조)   ";
		}
	}
	static uint32 _SignPass() { return (_seeds * 10u + 11u) / 12u; }

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🎯 **회차 144 · 왜 못 배우나 — 손실 가중인가 걸음인가**(%s)\n",
			(_seeds == 1u) ? "⚠️ 1씨앗 진단" : "⭐ 판정 회차");
		LogA("[mlt] 🎯   ⭐ 표제 = ***목표선 %.4f(회차 143 의 학습 0 최선)를 깨는 팔이 있나***\n", (double)kTarget);
		LogA("[mlt] 🎯   ㈀ 전체·800(검산 %.4f) · ⭐ ㈁ **변화만**·800(손실 가중) · ⭐ ㈂ 전체·**3200**(걸음) · ㈃ 지속만·800(대조)\n",
			(double)kCE141);
		LogA("[mlt] 🎯   ⚠️⚠️ ㈁ 은 손실 표적이 56→14 라 **유효 표본이 1/4** — ⛔ 면 *\"가중인지 표본인지 못 가른다\"* 다\n");
		LogA("[mlt] 🎯   ⭐ 자 = **도달률** `(CE(㈀)−CE(팔)) / (CE(㈀)−%.4f)` · 짝지은 SE 에 **실행 항** 포함\n", (double)kTarget);
		LogA("[mlt] 🎯   ⭐ 예측 — ㈁ **1.9~2.4**(도달률 0.5~1.2) · ㈂ 2.55~2.72(걸음은 주범 아닐 것) · ㈃ 2.9~3.4\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

	// ── 인코더 · 코퍼스(138~143 과 같다) ────────────────────────────
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
		_trA.SetSortById(true); _ptA.SetSortById(true);
		_trA.Begin(kNCtx, kN); _ptA.Begin(kPtCtx, kN);
		_cor = 0u; _gGrp = 0u; _gIdx = 0u; _pending = false; _st = kGather;
	}

	static uint32 _NCtxOf(uint32 c) { return (c == 0u) ? kNCtx : kPtCtx; }
	static uint32 _EpiOf(uint32 c)  { return (c == 0u) ? kTrainEpi : kPtEpi; }
	static MLTP3Ctx& _CorA(uint32 c) { return (c == 0u) ? _trA : _ptA; }

	static void _Gather()
	{
		const uint32 nCtx = _NCtxOf(_cor);
		if (_pending)
		{
			Array<float> ids, mag;
			if (!_E.ReadAct(ids, mag) || ids.Count() != kCandidates) { _Fail("활성 리드백"); return; }
			const uint32 cx = _gGrp * kGroup + (_gIdx - 1u) / kTime, tt = (_gIdx - 1u) % kTime;
			_CorA(_cor).StoreAct(cx, tt, ids, mag, _norm);
			_pending = false;
		}
		if (_gIdx == 0u)
		{
			Array<float> fr, tg; fr.Reset(0); tg.Reset(0);
			ImageFormat::Bitmap bmp; Bytes packed;
			const uint32 epi = _EpiOf(_cor);
			for (uint32 g = 0; g < kGroup; ++g)
			{
				const uint32 ctx = _gGrp * kGroup + g;
				MLTWorld w; w.Reset(_seed, epi + ctx, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
				for (uint32 t = 0; t < kTime; ++t)
				{
					w.Step();
					if (!w.Render(bmp) || !MLTWorld::Pack(bmp, nullptr, packed)) { _Fail("Render/Pack(문맥)"); return; }
					MLTP2Enc::AppendFrame(fr, tg, (const uint8*)packed.GetData());
					_CorA(_cor).StoreState(ctx, t, w.State());
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
		if (++_gGrp * kGroup < nCtx) return;
		_gGrp = 0u;
		if (++_cor < 2u) return;
		_wConst.Reset(0);
		const uint32 mx = (kNCtx > kPtCtx ? kNCtx : kPtCtx) * kTime;
		for (uint32 i = 0; i < mx; ++i) _wConst.Add(kConstCls);
		_arm = 0u; _ToBody();
	}

	// ── 13축 → 14축(낱말은 상수) + 손실/채점 마스크 ──────────────────
	static void _Expand(const MLTP3Ctx& C, uint32 nCtx, uint32 mask,
		Array<float>& oVal, Array<float>& oSym, Array<float>& oTgt)
	{
		const uint32 steps = nCtx / kBatch;
		const uint32 n = steps * kRows14;
		oVal.Reset(0); oSym.Reset(0); oTgt.Reset(0);
		for (uint32 i = 0; i < n; ++i) { oVal.Add(0.0f); oSym.Add(0.0f); oTgt.Add((float)kN); }
		uint32 scored = 0u;
		const float wv = ((float)kConstCls / (float)(kWordCls - 1u)) * 2.0f - 1.0f;   // = 0
		for (uint32 ctx = 0; ctx < nCtx; ++ctx)
		{
			const uint32 k = ctx / kBatch, b = ctx % kBatch;
			for (uint32 t = 0; t < kTime; ++t)
			{
				const uint32 src = MLTP3Ctx::Row(ctx, t, 0u);
				const uint32 dst = k * kRows14 + b * kCtx14 + t * kAx14;
				oVal.Data()[dst] = wv;
				oSym.Data()[dst] = kWordSym;
				oTgt.Data()[dst] = (float)kN;                       // IgnoreTgt
				for (uint32 a = 0; a < kAx13; ++a)
				{
					oVal.Data()[dst + 1u + a] = C.Val()[src + a];
					oSym.Data()[dst + 1u + a] = C.Sym()[src + a];
					float tf = C.Tgt()[src + a];
					if (mask != kMNone && a >= kStateAx && tf >= 0.0f && tf < (float)kN)
					{
						const uint32 tid = (uint32)tf;
						const bool keep = ((uint32)(C.Sym()[src + a] - (float)kStateAx) == tid);
						if ((mask == kMChange && keep) || (mask == kMKeep && !keep)) tf = (float)kN;
					}
					if (tf >= 0.0f && tf < (float)kN) ++scored;
					oTgt.Data()[dst + 1u + a] = tf;
				}
			}
		}
		_lastScored = scored;
	}

	static bool _UploadTest(uint32 mask)
	{
		_Expand(_ptA, kPtCtx, mask, _eVal[1], _eSym[1], _eTgt[1]);
		if (_arm == 0u && _out == 0u)
		{
			if (mask == kMChange) _nCh[_seed] = (double)_lastScored / (double)kPtCtx;
			else if (mask == kMKeep) _nKe[_seed] = (double)_lastScored / (double)kPtCtx;
		}
		return _M.UploadPool(_eVal[1], _eTgt[1], kPtPool) && _M.UploadSymbolPool(_eSym[1], kPtPool);
	}

	static void _BodyBegin(RHI* rhi)
	{
		if (!_M.Setup(rhi, kSymA, kN, kAx14, kTime)) { _Fail("몸통 준비"); return; }
		// ⭐ **팔이 바꾸는 것은 「학습 손실 마스크」와 「걸음 수」뿐이다**(입력·축·파라미터 동일).
		_Expand(_trA, kNCtx, kTrMaskOf[_arm], _eVal[0], _eSym[0], _eTgt[0]);
		if (!(_M.UploadPool(_eVal[0], _eTgt[0], kPoolSteps) && _M.UploadSymbolPool(_eSym[0], kPoolSteps)))
		{ _Fail("학습 풀 업로드"); return; }
		if (_out == 0u && _seed == 0u)
			LogA("[mlt] 🎯   %s 학습 표적 **%.1f/문맥** · 걸음 %u\n",
				_ArmName(_arm), (double)_lastScored / (double)kNCtx, kStepsOf[_arm]);
		_step = 0u; _st = kBodyTrain;
	}

	static void _BodyTrain()
	{
		if (_step >= kStepsOf[_arm])
		{
			_evalIdx = 0u;
			if (!_UploadTest(kMChange)) { _Fail("시험 풀 업로드"); return; }
			_gate.Begin(kPtPool); _st = kEval; return;
		}
		for (uint32 i = 0; i < kPerTick && _step < kStepsOf[_arm]; ++i)
		{
			_M.SelectStep(_step % kPoolSteps);
			if (!_M.Forward() || !_M.Backward() || !_M.AdamStep(1.0f)) { _Fail("몸통 스텝"); return; }
			++_step;
		}
	}

	static void _EvalStep()
	{
		bool fail = false;
		if (!_gate.Step(_M, fail)) return;
		if (fail) { _Fail("평가 리드백"); return; }
		const float ce = _gate.Mean();
		if (!(ce == ce) || ce > 1.0e30f) _finite = false;

		if (_evalIdx == 0u)
		{
			_ce[_out][_arm][_seed] = ce;
			++_evalIdx;
			if (!_UploadTest(kMKeep)) { _Fail("지속 시험 풀 업로드"); return; }
			_gate.Begin(kPtPool); return;
		}
		_ceK[_out][_arm][_seed] = ce;
		LogA("[mlt] 🎯   %s 씨앗 %2u · 바깥 %u · **변화 CE %.5f** · 지속 %.5f\n",
			_ArmName(_arm), _seed, _out, (double)_ce[_out][_arm][_seed], (double)ce);

		if (++_arm < kArms) { _ToBody(); return; }
		_arm = 0u;
		if (++_out < kOut) { _ToBody(); return; }
		_out = 0u;
		_seedOk[_seed] = _finite;
		++_seed; _st = kEncInit;
	}

	// ── 짝지은 차 — SE 에 실행 항(규율 29·37) ────────────────────────
	static double _M2(uint32 a, uint32 s)
	{
		double v = 0.0;
		for (uint32 o = 0; o < kOut; ++o) v += (double)_ce[o][a][s];
		return v / (double)kOut;
	}
	static double _M2K(uint32 a, uint32 s)
	{
		double v = 0.0;
		for (uint32 o = 0; o < kOut; ++o) v += (double)_ceK[o][a][s];
		return v / (double)kOut;
	}

	struct Pair { double d; double se; double t; double sdSeed; double sdRun; uint32 n; uint32 win; };

	static Pair _Paired(uint32 aX, uint32 aY)
	{
		Pair p{}; p.d = 0.0; p.se = 0.0; p.t = 0.0; p.sdSeed = 0.0; p.sdRun = 0.0; p.n = 0u; p.win = 0u;
		double dv[kSeedsMax]; double rs = 0.0;
		for (uint32 s = 0; s < _seeds; ++s)
		{
			if (!_seedOk[s]) continue;
			const double d = _M2(aX, s) - _M2(aY, s);
			dv[p.n] = d; p.d += d; ++p.n;
			if (d < 0.0) ++p.win;
			const double r0 = (double)_ce[0][aX][s] - (double)_ce[0][aY][s];
			const double r1 = (double)_ce[1][aX][s] - (double)_ce[1][aY][s];
			rs += Abs((float)(r1 - r0)) / 1.414213562;
		}
		if (p.n == 0u) return p;
		p.d /= (double)p.n;
		double vv = 0.0;
		for (uint32 i = 0; i < p.n; ++i) { const double e = dv[i] - p.d; vv += e * e; }
		p.sdSeed = (p.n > 1u) ? Sqrt((float)(vv / (double)(p.n - 1u))) : 0.0;
		p.sdRun = rs / (double)p.n;
		const double v = (p.sdSeed * p.sdSeed) / (double)p.n
			+ (p.sdRun * p.sdRun) / ((double)p.n * (double)kOut);
		p.se = Sqrt((float)v);
		p.t = (p.se > 1.0e-12) ? (Abs(p.d) / p.se) : 0.0;
		return p;
	}

	static double _ArmMean(uint32 a, bool keep)
	{
		double m = 0.0; uint32 n = 0u;
		for (uint32 s = 0; s < _seeds; ++s)
		{
			if (!_seedOk[s]) continue;
			m += keep ? _M2K(a, s) : _M2(a, s); ++n;
		}
		return (n == 0u) ? 0.0 : m / (double)n;
	}

	static void _Summary()
	{
		uint32 ok = 0u;
		for (uint32 s = 0; s < _seeds; ++s) if (_seedOk[s]) ++ok;
		double nch = 0.0, nke = 0.0; uint32 nn = 0u;
		for (uint32 s = 0; s < _seeds; ++s) { if (!_seedOk[s]) continue; nch += _nCh[s]; nke += _nKe[s]; ++nn; }
		if (nn > 0u) { nch /= (double)nn; nke /= (double)nn; }

		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🎯 **회차 144 · 왜 못 배우나** (씨앗 %u/%u · 유한 %s)\n", ok, _seeds, _finite ? "✅" : "⛔");
		LogA("[mlt] 🎯   채점 표적 — 변화 **%.1f/문맥** · 지속 %.1f/문맥 · 목표선 **%.4f**(회차 143)\n",
			nch, nke, (double)kTarget);

		const double base = _ArmMean(0u, false);
		const double den = base - (double)kTarget;
		LogA("[mlt] 🎯   ── ① 팔별 CE ──\n");
		LogA("[mlt] 🎯     팔                    │ **변화 CE** · 지속 CE · **도달률** · 목표선 돌파\n");
		for (uint32 a = 0; a < kArms; ++a)
		{
			const double ch = _ArmMean(a, false), ke = _ArmMean(a, true);
			LogA("[mlt] 🎯     %s │ **%.4f** · %.4f · **%+.3f** · %s\n",
				_ArmName(a), ch, ke, (Abs((float)den) > 1.0e-9) ? (base - ch) / den : 0.0,
				(ch < (double)kTarget) ? "⭐ **깼다**" : "⛔");
		}

		// ── ② 짝지은 차(팔 − ㈀) ────────────────────────────────────
		LogA("[mlt] 🎯   ── ② **짝지은 차**(팔 − ㈀ · 음수 = 팔이 낫다) · SE 에 **실행 항** 포함 ──\n");
		LogA("[mlt] 🎯     견줌              │ d̄        · sd_씨앗 · sd_run  · SE      · **|d̄|/SE** · 이긴 씨앗\n");
		Pair pr[kArms];
		for (uint32 a = 1; a < kArms; ++a)
		{
			pr[a] = _Paired(a, 0u);
			LogA("[mlt] 🎯     %s │ %+.5f · %.5f · %.5f · %.5f · **%6.2f** · %u/%u\n",
				_ArmName(a), pr[a].d, pr[a].sdSeed, pr[a].sdRun, pr[a].se, pr[a].t, pr[a].win, pr[a].n);
		}

		// ── ③ 자가 결정적인가 ───────────────────────────────────────
		double runSum = 0.0; uint32 runN = 0u, runZero = 0u;
		for (uint32 s = 0; s < _seeds; ++s)
		{
			if (!_seedOk[s]) continue;
			for (uint32 a = 0; a < kArms; ++a)
			{
				const double d = Abs((float)((double)_ce[1][a][s] - (double)_ce[0][a][s]));
				runSum += d; ++runN; if (d == 0.0) ++runZero;
			}
		}
		LogA("[mlt] 🎯   ── ③ **`sd_run` 확인**(규율 47) — 비트 동일 **%u/%u** · 평균 |Δ| **%.3e**\n",
			runZero, runN, (runN == 0u) ? 0.0 : runSum / (double)runN);

		// ── 관문 ────────────────────────────────────────────────────
		const uint32 pass = _SignPass();
		const double chk = Abs((float)(base - (double)kCE141));
		const bool gChk = (_seeds < 3u) || (chk <= 0.05);
		const bool gCtl = (_ArmMean(3u, false) > base);
		uint32 broke = 0u; uint32 brokeArm = 0u;
		for (uint32 a = 1; a < kArms; ++a)
			if (_ArmMean(a, false) < (double)kTarget && pr[a].win >= pass && pr[a].d < 0.0 && pr[a].t >= 3.0)
			{ ++broke; if (brokeArm == 0u) brokeArm = a; }
		LogA("[mlt] 🎯   ── 관문 ──\n");
		LogA("[mlt] 🎯     ⭐ **검산**(㈀ 가 회차 141 의 %.4f ± 0.05) — %.4f · 차 %.4f → %s\n",
			(double)kCE141, base, chk,
			(_seeds < 3u) ? "⚠️ 건너뜀(씨앗 3 이상 — 규율 51)" : (gChk ? "✅" : "⛔ **배치가 다르다**"));
		LogA("[mlt] 🎯     ⭐ **대조**(㈃ 지속만 학습이 ㈀ 보다 나빠야) — %.4f vs %.4f → %s\n",
			_ArmMean(3u, false), base, gCtl ? "✅ 마스크가 먹었다" : "⛔ **마스크가 안 먹었다**");
		LogA("[mlt] 🎯     ⭐ **표제**(목표선 %.4f 를 깨고 ㈀ 를 이기는 팔) — **%u 개**\n", (double)kTarget, broke);

		// ── 판정 ────────────────────────────────────────────────────
		if (!_finite || ok < _seeds)  LogA("[mlt] 🎯   ⭐ 판정 = ⛔ **판정불가** — 배관이 안 섰다\n");
		else if (!gChk)               LogA("[mlt] 🎯   ⭐ 판정 = ⛔ **판정불가** — ***검산이 깨졌다***\n");
		else if (!gCtl)               LogA("[mlt] 🎯   ⭐ 판정 = ⛔ **판정불가** — ***대조가 안 선다***(손실 마스크가 안 먹었다)\n");
		else if (_seeds == 1u)        LogA("[mlt] 🎯   ⭐ **1씨앗 진단이다 — 판정하지 않는다**(규율 51)\n");
		else if (broke > 0u)
			LogA("[mlt] 🎯   ⭐ 판정 = ⭐ ***%s 이 목표선을 깼다*** — 범인이 잡혔다\n"
			     "[mlt] 🎯      ⇒ ★ 처방은 그 팔이 바꾼 것이다(손실 마스크 / 걸음)\n", _ArmName(brokeArm));
		else if (pr[1].d < 0.0 && pr[1].t >= 3.0 && pr[1].win >= pass)
			LogA("[mlt] 🎯   ⭐ 판정 = ⚠️ **㈁ 이 ㈀ 를 이기지만 목표선은 못 깼다** ⇒ ***손실 가중은 「부분적」 범인***\n"
			     "[mlt] 🎯      ⚠️ 그리고 ㈁ 은 유효 표본이 1/4 이라 **가중인지 표본인지 못 가른다** ⇒ 다음 회차가 그것을 가른다\n");
		else
			LogA("[mlt] 🎯   ⭐ 판정 = ⛔ **넷 다 목표선을 못 깼고 ㈁ 도 안 선다** ⇒ ⚠️⚠️ 남는 후보는 **표현**이다\n"
			     "[mlt] 🎯      ⇒ ★ 캔버스를 또 바꾼다(활성 사전이 변화를 담나)\n");
		LogA("[mlt] 🎯   ⚠️ 문맥 학습 %u · 시험 %u — 절대 성능으로 인용하지 않는다\n", kNCtx, kPtCtx);
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		_E.Destroy(); _done = true;
	}

	static void _Fail(const char* why)
	{
		LogA("[mlt] 🎯 ⛔ %s (씨앗 %u · 팔 %u · 바깥 %u · 평가 %u · 단계 %u · 코퍼스 %u · 걸음 %u)\n",
			why, _seed, _arm, _out, _evalIdx, _st, _cor, _step);
		_E.Destroy(); _done = true;
	}

	CW_BODY(MLTL1G0)
};
