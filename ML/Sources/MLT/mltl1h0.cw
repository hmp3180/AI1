// mltl1h0.cw — ⚖️ 회차 145 · **가중 스윕 — 대가가 얼마인가**(파레토) (`-mlt -mltl1h0`)
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 145 다.** ⭐ **하네스보다 먼저 썼다.**
//   **상위 캔버스: `모델이 변화 표적을 배우나` · 143~145 = 3회차** ⇒ ⚠️ 규율 33 의 3에 닿는다
//   ⇒ ★ 이 회차 끝에 **종료 심사**를 쓴다.
//
// ── ⭐ 표제 — ***지속을 크게 잃지 않으면서 변화를 목표선 아래로 내리는 가중이 있나*** ──
//   회차 144 가 아는 것은 *"지속을 **아예 버리면** 변화가 목표선(2.1111)을 넘는다"* 뿐이다.
//   ⚠️ 그때 지속 CE 가 `0.259 → 5.277` 이었지만 그 팔은 **지속에 손실이 0** 이라 대가가 아니다.
//   ⇒ ★ **진짜 대가**는 「둘 다 학습하되 변화에 가중」 에서만 보인다.
//
// ── ⚙️ 구현 — ⭐ **지속 표적을 확률로 버린다**(커널 무변경 · 같은 문맥) ────
//   ⚠️ 풀을 두 벌 올릴 수 없다(`MLTModelCfg::kPool = 64` 이고 학습 풀이 이미 64 스텝이다).
//   ⚠️⚠️ **스텝을 갈라 섞는 것도 안 된다** — 그러면 문맥까지 갈려 *"가중"* 이 아니라
//     *"변화는 문맥 1/4 만 본다"* 가 된다(회차 144 의 유보 1 을 되풀이한다).
//   ⇒ ⭐ 학습 풀에서 **지속 표적을 보존율 `q` 로 남기고 나머지를 `IgnoreTgt`** 로.
//     변화 표적은 **전부** 남긴다 ⇒ 유효 가중비 `변화 : 지속 = 14 : 42q`.
//   ★ 같은 문맥이고 **양쪽 끝이 회차 144 를 재현**한다(`q=1` = ㈀ · `q=0` = ㈁).
//   ⚠️ 버리기는 **씨앗·자리로 결정적**이다(해시) — 짝지음이 성립해야 한다.
//
// ── 🔮 예측(재기 전에 적었다) ────────────────────────────────────────────
//   q=1.00 → (2.780 검산, 0.259) · q=0.50 → (2.3~2.6, 0.30~0.40) ·
//   ⭐ q=0.25 → (2.0~2.3, 0.40~0.60) · ⭐ q=0.10 → (1.8~2.1, 0.7~1.5) ·
//   q=0.00 → (1.739 검산, 5.277)
//   ⭐ 표제 = ✅ **통과**(㈂ 또는 ㈃). ⚠️ 단 회차 144 의 교훈(효과를 과소평가했다)을 쓰면
//   변화가 **더 빨리** 내려가고 지속도 **더 빨리** 나빠져 **통과 구간이 좁을** 수 있다.
//   ⚠️ 통과 점이 없으면 ⇒ *"대가가 크다"* 가 답이고 처방은 **별도 헤드**다.
// ══════════════════════════════════════════════════════════════════════════════

using namespace PE;

class MLTL1H0
{
public:
	static void Tick(RHI* rhi)
	{
		if (_done || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltl1h0"))
		{
			LogA("[mlt] ⚖️ 회차 145(가중 스윕 — 대가가 얼마인가)는 **꺼져 있다**(`-mltl1h0`)\n");
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

	static constexpr uint32 kNCtx = 512u, kPtCtx = 512u;
	static constexpr uint32 kTrainEpi = 1u, kPtEpi = 5001u;
	static constexpr uint32 kPoolSteps = kNCtx / kBatch;
	static constexpr uint32 kPtPool = kPtCtx / kBatch;
	static constexpr uint32 kSteps = 800u, kPerTick = 16u;

	static constexpr uint32 kSymA = MLTP3Ctx::kStateAx + kN + 1u;
	static constexpr uint32 kAx13 = MLTP3Ctx::kAxes;                 // 13
	static constexpr uint32 kAx14 = kAx13 + 1u;                      // 14
	static constexpr uint32 kCtx14 = kAx14 * kTime;                  // 112
	static constexpr uint32 kRows14 = kBatch * kCtx14;               // 896
	static constexpr float  kWordSym = 255.0f;
	static constexpr uint32 kWordCls = 9u, kConstCls = 4u;

	// ⭐ 밖에서 온 눈금 넷 — ⚠️ 여기서 새로 재지 않는다.
	static constexpr float kTarget  = 2.1111f;   // 회차 143 · 학습 0 예측기의 최선
	static constexpr float kCE144A  = 2.7802f;   // 회차 144 · ㈀ 전체손실 (= q 1.00 검산)
	static constexpr float kCE144B  = 1.7389f;   // 회차 144 · ㈁ 변화만   (= q 0.00 검산)
	static constexpr float kKeepA   = 0.2592f;   // 회차 144 · ㈀ 의 지속 CE
	static constexpr float kKeepLim = 0.5184f;   // ⭐ 그 2배 = 표제의 지속 문턱

	// ⭐ 지속 표적 **보존율**(천분율). `1000` = 전부 남긴다 · `0` = 전부 버린다.
	static constexpr uint32 kArms = 5u;
	static constexpr uint32 kKeepQ[kArms] = { 1000u, 500u, 250u, 100u, 0u };

	enum { kMNone = 0u, kMChange = 1u, kMKeep = 2u };
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
	inline static Array<float> _eVal[2], _eSym[2], _eTgt[2];
	inline static MLTEvalGate _gate;

	inline static float _ce[kOut][kArms][kSeedsMax];        // 변화 CE(판정)
	inline static float _ceK[kOut][kArms][kSeedsMax];       // 지속 CE(대가)
	inline static bool  _seedOk[kSeedsMax];
	inline static double _nTrain[kArms];
	inline static uint32 _lastScored = 0u;

	static void _ToBody() { _qWait = MLTEvalGate::kDelay; _st = kQuiesce; }
	static const char* _ArmName(uint32 a)
	{
		switch (a)
		{
		case 0u: return "㈀ q=1.00(검산·전체) ";
		case 1u: return "㈁ q=0.50            ";
		case 2u: return "㈂ q=0.25 ⭐         ";
		case 3u: return "㈃ q=0.10 ⭐         ";
		default: return "㈄ q=0.00(검산·변화만)";
		}
	}
	static uint32 _SignPass() { return (_seeds * 10u + 11u) / 12u; }

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] ⚖️ **회차 145 · 가중 스윕 — 대가가 얼마인가**(%s)\n",
			(_seeds == 1u) ? "⚠️ 1씨앗 진단" : "⭐ 판정 회차");
		LogA("[mlt] ⚖️   ⭐ 표제 = ***지속을 크게 잃지 않으면서 변화를 %.4f 아래로 내리는 가중이 있나***\n", (double)kTarget);
		LogA("[mlt] ⚖️   구현 — 학습 풀에서 **지속 표적을 보존율 q 로** 남기고 나머지를 `IgnoreTgt`(변화는 전부 남긴다)\n");
		LogA("[mlt] ⚖️      ⇒ 유효 가중비 `변화 : 지속 = 14 : 42q` · **같은 문맥** · 커널 무변경 · 버리기는 **결정적**\n");
		LogA("[mlt] ⚖️   ⭐ **양쪽 끝이 검산**이다 — q=1.00 → %.4f(144 ㈀) · q=0.00 → %.4f(144 ㈁) ±0.05\n",
			(double)kCE144A, (double)kCE144B);
		LogA("[mlt] ⚖️   ⭐ 표제 통과 = 변화 CE < %.4f **그리고** 지속 CE < %.4f(㈀ 의 2배)\n",
			(double)kTarget, (double)kKeepLim);
		LogA("[mlt] ⚖️   ⭐ 예측 — q=0.50 (2.3~2.6, 0.30~0.40) · q=0.25 (2.0~2.3, 0.40~0.60) · q=0.10 (1.8~2.1, 0.7~1.5)\n");
		LogA("[mlt] ⚖️   ⚠️ 회차 144 의 교훈(효과를 과소평가했다) ⇒ **통과 구간이 좁을 수 있다**\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

	// ── 인코더 · 코퍼스(138~144 와 같다) ────────────────────────────
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
		_arm = 0u; _ToBody();
	}

	// ⭐ 결정적 해시 — 「이 자리의 지속 표적을 남기나」. ⚠️ 씨앗마다 다르고 팔마다 **같다**
	//   (팔이 바꾸는 것은 문턱 `q` 뿐이라 `q` 가 큰 팔의 보존 집합이 작은 팔을 **포함**한다 — 계단이 곱다).
	static uint32 _Hash(uint32 ctx, uint32 t, uint32 a)
	{
		uint32 h = ((ctx * 131u + t * 17u + a) * 2654435761u) ^ (_seed * 97u + 12345u);
		h ^= h >> 15; h *= 2246822519u; h ^= h >> 13; h *= 3266489917u; h ^= h >> 16;
		return h % 1000u;
	}

	// ── 13축 → 14축(낱말은 상수 0) + 마스크 ─────────────────────────
	//   `mask == kMNone` 이면 **학습**이고 `keepQ` 로 지속 표적을 솎는다.
	//   `kMChange`/`kMKeep` 은 **시험 채점** 마스크다(`keepQ` 무시).
	static void _Expand(const MLTP3Ctx& C, uint32 nCtx, uint32 mask, uint32 keepQ,
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
				oTgt.Data()[dst] = (float)kN;
				for (uint32 a = 0; a < kAx13; ++a)
				{
					oVal.Data()[dst + 1u + a] = C.Val()[src + a];
					oSym.Data()[dst + 1u + a] = C.Sym()[src + a];
					float tf = C.Tgt()[src + a];
					if (a >= kStateAx && tf >= 0.0f && tf < (float)kN)
					{
						const uint32 tid = (uint32)tf;
						const bool keep = ((uint32)(C.Sym()[src + a] - (float)kStateAx) == tid);
						if (mask == kMChange)      { if (keep)  tf = (float)kN; }
						else if (mask == kMKeep)   { if (!keep) tf = (float)kN; }
						// ⭐ 학습 — **지속 표적만** 보존율 `q` 로 솎는다(변화는 전부 남긴다)
						else if (keep && _Hash(ctx, t, a) >= keepQ) tf = (float)kN;
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
		_Expand(_ptA, kPtCtx, mask, 1000u, _eVal[1], _eSym[1], _eTgt[1]);
		return _M.UploadPool(_eVal[1], _eTgt[1], kPtPool) && _M.UploadSymbolPool(_eSym[1], kPtPool);
	}

	static void _BodyBegin(RHI* rhi)
	{
		if (!_M.Setup(rhi, kSymA, kN, kAx14, kTime)) { _Fail("몸통 준비"); return; }
		_Expand(_trA, kNCtx, kMNone, kKeepQ[_arm], _eVal[0], _eSym[0], _eTgt[0]);
		if (_seed == 0u && _out == 0u) _nTrain[_arm] = (double)_lastScored / (double)kNCtx;
		if (!(_M.UploadPool(_eVal[0], _eTgt[0], kPoolSteps) && _M.UploadSymbolPool(_eSym[0], kPoolSteps)))
		{ _Fail("학습 풀 업로드"); return; }
		_step = 0u; _st = kBodyTrain;
	}

	static void _BodyTrain()
	{
		if (_step >= kSteps)
		{
			_evalIdx = 0u;
			if (!_UploadTest(kMChange)) { _Fail("시험 풀 업로드"); return; }
			_gate.Begin(kPtPool); _st = kEval; return;
		}
		for (uint32 i = 0; i < kPerTick && _step < kSteps; ++i)
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
		LogA("[mlt] ⚖️   %s 씨앗 %2u · 바깥 %u · **변화 %.5f** · 지속 %.5f · 학습표적 %.1f\n",
			_ArmName(_arm), _seed, _out, (double)_ce[_out][_arm][_seed], (double)ce, _nTrain[_arm]);

		if (++_arm < kArms) { _ToBody(); return; }
		_arm = 0u;
		if (++_out < kOut) { _ToBody(); return; }
		_out = 0u;
		_seedOk[_seed] = _finite;
		++_seed; _st = kEncInit;
	}

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

	static void _Summary()
	{
		uint32 ok = 0u;
		for (uint32 s = 0; s < _seeds; ++s) if (_seedOk[s]) ++ok;
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] ⚖️ **회차 145 · 가중 스윕 — 대가가 얼마인가** (씨앗 %u/%u · 유한 %s)\n",
			ok, _seeds, _finite ? "✅" : "⛔");

		// ── ① 파레토 곡선 ──────────────────────────────────────────
		LogA("[mlt] ⚖️   ── ① ⭐ **파레토 곡선**(목표선 변화 < %.4f · 지속 < %.4f) ──\n",
			(double)kTarget, (double)kKeepLim);
		LogA("[mlt] ⚖️     팔                    │ 학습표적 │ **변화 CE** · **지속 CE** │ 통과\n");
		double ch[kArms], ke[kArms];
		uint32 nPass = 0u, firstPass = kArms;
		for (uint32 a = 0; a < kArms; ++a)
		{
			ch[a] = _ArmMean(a, false); ke[a] = _ArmMean(a, true);
			const bool okA = (ch[a] < (double)kTarget) && (ke[a] < (double)kKeepLim);
			if (okA) { ++nPass; if (firstPass == kArms) firstPass = a; }
			LogA("[mlt] ⚖️     %s │ %6.1f  │ **%.4f** · **%.4f** │ %s\n",
				_ArmName(a), _nTrain[a], ch[a], ke[a], okA ? "⭐ **통과**" : "⛔");
		}

		// ── ② 짝지은 차(팔 − ㈀) ────────────────────────────────────
		LogA("[mlt] ⚖️   ── ② **짝지은 차**(팔 − ㈀ · 음수 = 변화가 나아졌다) · SE 에 실행 항 ──\n");
		for (uint32 a = 1; a < kArms; ++a)
		{
			const Pair p = _Paired(a, 0u);
			LogA("[mlt] ⚖️     %s │ d̄ %+.5f · SE %.5f · **|d̄|/SE %6.2f** · %u/%u\n",
				_ArmName(a), p.d, p.se, p.t, p.win, p.n);
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
		LogA("[mlt] ⚖️   ── ③ **`sd_run` 확인**(규율 47) — 비트 동일 **%u/%u** · 평균 |Δ| **%.3e**\n",
			runZero, runN, (runN == 0u) ? 0.0 : runSum / (double)runN);

		// ── 관문 ────────────────────────────────────────────────────
		const double cA = Abs((float)(ch[0] - (double)kCE144A));
		const double cB = Abs((float)(ch[kArms - 1u] - (double)kCE144B));
		const bool apply = (_seeds >= 3u);
		const bool gChk = !apply || (cA <= 0.05 && cB <= 0.05);
		bool mono = true;
		for (uint32 a = 1; a < kArms; ++a) if (!(ch[a] <= ch[a - 1u])) mono = false;
		LogA("[mlt] ⚖️   ── 관문 ──\n");
		LogA("[mlt] ⚖️     ⭐ **검산 둘** — ㈀ %.4f(↔%.4f · 차 %.4f) · ㈄ %.4f(↔%.4f · 차 %.4f) → %s\n",
			ch[0], (double)kCE144A, cA, ch[kArms - 1u], (double)kCE144B, cB,
			!apply ? "⚠️ 건너뜀(씨앗 3 이상 — 규율 51)" : (gChk ? "✅" : "⛔ **배치가 다르다**"));
		LogA("[mlt] ⚖️     ⭐ **단조성**(변화 CE 가 q 에 대해 단조 감소 · 규율 46) → %s\n",
			mono ? "✅" : "⚠️ **단조가 아니다** — 해석에 손잡이가 안 붙는다");
		LogA("[mlt] ⚖️     ⭐ **표제**(변화 < %.4f 이고 지속 < %.4f 인 팔) — **%u 개**\n",
			(double)kTarget, (double)kKeepLim, nPass);

		// ── 판정 ────────────────────────────────────────────────────
		if (!_finite || ok < _seeds)  LogA("[mlt] ⚖️   ⭐ 판정 = ⛔ **판정불가** — 배관이 안 섰다\n");
		else if (!gChk)               LogA("[mlt] ⚖️   ⭐ 판정 = ⛔ **판정불가** — ***검산이 깨졌다***(144 와 배치가 다르다)\n");
		else if (_seeds == 1u)        LogA("[mlt] ⚖️   ⭐ **1씨앗 진단이다 — 판정하지 않는다**(규율 51)\n");
		else if (nPass > 0u)
			LogA("[mlt] ⚖️   ⭐ 판정 = ⭐ ***통과하는 가중이 있다*** — %s (변화 %.4f · 지속 %.4f)\n"
			     "[mlt] ⚖️      ⇒ ★ 처방이 **값 하나**로 끝난다: 지속 표적을 그 비율로 솎는다\n",
			     _ArmName(firstPass), ch[firstPass], ke[firstPass]);
		else
			LogA("[mlt] ⚖️   ⭐ 판정 = ⛔ **통과 점이 없다** ⇒ ***대가가 크다*** — 변화와 지속이 **한 헤드에서 다툰다**\n"
			     "[mlt] ⚖️      ⇒ ★ 처방은 **별도 헤드**(또는 표적을 두 갈래로 나누는 것)다\n");
		LogA("[mlt] ⚖️   ⚠️ 문맥 학습 %u · 시험 %u · %u걸음 — 절대 성능으로 인용하지 않는다\n", kNCtx, kPtCtx, kSteps);
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		_E.Destroy(); _done = true;
	}

	static void _Fail(const char* why)
	{
		LogA("[mlt] ⚖️ ⛔ %s (씨앗 %u · 팔 %u · 바깥 %u · 평가 %u · 단계 %u · 코퍼스 %u · 걸음 %u)\n",
			why, _seed, _arm, _out, _evalIdx, _st, _cor, _step);
		_E.Destroy(); _done = true;
	}

	CW_BODY(MLTL1H0)
};
