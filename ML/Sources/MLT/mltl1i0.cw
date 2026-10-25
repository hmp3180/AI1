// mltl1i0.cw — 🔄 회차 146 · **회전 마스크 — 대가를 「표본」과 「경쟁」으로 가른다** (`-mlt -mltl1i0`)
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 146 이다.** ⭐ **하네스보다 먼저 썼다.**
//   **상위 캔버스: `손실 편향을 표본 손실 없이 없앤다` · 146~ = 1회차**(캔버스를 바꿨으므로 파일럿).
//
// ── ⭐ 표제 — ***회차 145 의 대가 중 얼마가 「표본」이었나*** ────────────
//   회차 145 는 통과 점이 없었는데 ⚠️ 그 대가가 **경쟁**(용량)인지 **표본**(지속 표적을 덜
//   봤다)인지 못 갈랐다. ⇒ ★ 이 회차가 **표본 쪽을 원리적으로 제거**해서 그것을 가른다.
//
// ── ⚙️ 구현 — ⭐ **회전 마스크**(커널 **0줄**) ────────────────────────
//   ⚠️ **145 의 마스크는 씨앗마다 고정**이었다 ⇒ 버려진 지속 표적은 **800걸음 내내 한 번도**
//     안 보였다. ⇒ ★ **매 풀 순회마다 다른 부분집합**을 남긴다(해시에 **순회 번호**를 섞는다).
//   `800걸음 ÷ 64스텝 = 12.5 순회` ⇒ 적어도 한 번 보일 확률 `1 − (1−q)^12.5`:
//     q=0.50 → ~100% · q=0.25 → ~97% · q=0.10 → ~73%
//   ⇒ ⭐ **표본 손실이 거의 사라지고 「가중」만 남는다**(매 스텝의 지속 비중은 여전히 `q`).
//   ⭐ **왜 커널을 안 고치나** — 진짜 가중(표적별 손실 스케일)은 `ce`/`ce_logits_bwd` 셰이더를
//     고쳐야 하고 기울기 **누적** 경로도 안 열려 있다(`_Gemm` 은 `beta` 를 받지만
//     `_RmsG`·`kEmbB`·`kValB` 는 안 받는다). ⇒ ★ 회전 마스크가 **같은 것을 재면서 커널 0줄**이다.
//   ⚠️⚠️ **145 와 다른 코드는 `_Hash` 의 인자 하나(`cyc`)와 순회 경계의 재업로드뿐**이다.
//
// ── 🎛️ 팔 다섯 — ⭐ **145 와 같은 `q`**(짝지어 견준다) ────────────────────
//   ㈀ q=1.00(회전 무의미 ⇒ **검산** 2.7742) · ㈁ 0.50 · ⭐ ㈂ 0.25 · ⭐ ㈃ 0.10 ·
//   ㈄ q=0.00(회전 무의미 ⇒ **검산** 1.7443)
//   ★ 양 끝 검산이 *"풀을 12.5번 다시 올리는 배관 자체가 무해한가"* 도 같이 확인한다.
//
// ── 📏 자 — ⭐ 145 대비 분해(무차원) ─────────────────────────────────────
//   `표본 몫(q) = −(지속CE₁₄₆ − 지속CE₁₄₅) / (지속CE₁₄₅ − 0.2592)`
//     0 = 전부 경쟁 · 1 = 전부 표본. ⭐ **이것이 이 회차의 진짜 산출물**이다(표제보다 중요하다).
//
// ── 🔮 예측(재기 전에 적었다) ────────────────────────────────────────────
//   변화 CE 는 **거의 안 변할 것**(변화 표적은 회전과 무관하게 늘 전부 본다).
//   지속: q=0.50 0.4534→0.28~0.36 · 0.25 0.7378→0.35~0.55 · 0.10 1.2503→0.60~0.95
//   ⭐ **표본 몫 0.40~0.70** · ⚠️ **표제는 여전히 통과 못 할 것**.
//   ⚠️ 갈래: 몫 ≥0.7 ⇒ **진짜 가중(커널)** 이 값을 낸다 · ≤0.3 ⇒ **용량**으로 간다.
//   ⚠️ 위험: 학습 중간에 **풀을 다시 올린다** ⇒ 회차 135·136 의 *"관찰을 끼우면 갈림이 바뀐다"*
//     자리다. ★ `sd_run` 관문과 검산 둘이 그것을 잡는다.
// ══════════════════════════════════════════════════════════════════════════════

using namespace PE;

class MLTL1I0
{
public:
	static void Tick(RHI* rhi)
	{
		if (_done || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltl1i0"))
		{
			LogA("[mlt] 🔄 회차 146(회전 마스크 — 표본인가 경쟁인가)는 **꺼져 있다**(`-mltl1i0`)\n");
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

	// ⭐ 밖에서 온 눈금 — ⚠️ **여기서 새로 재지 않는다**(같은 코퍼스·같은 씨앗).
	static constexpr float kTarget  = 2.1111f;   // 회차 143 · 학습 0 예측기의 최선
	static constexpr float kKeepA   = 0.2592f;   // 회차 144·145 · q=1.00 의 지속 CE
	static constexpr float kKeepLim = 0.5184f;   // ⭐ 그 2배 = 표제의 지속 문턱

	// ⭐ 지속 표적 **보존율**(천분율). `1000` = 전부 남긴다 · `0` = 전부 버린다.
	static constexpr uint32 kArms = 5u;
	static constexpr uint32 kKeepQ[kArms] = { 1000u, 500u, 250u, 100u, 0u };

	// ⭐ **회차 145 의 값**(고정 마스크) — 이 회차는 그것과 **짝지어** 견준다.
	//   ⚠️ 양 끝(q=1.00·0.00)은 회전이 무의미하므로 **검산**이다.
	static constexpr float kCE145[kArms]  = { 2.7742f, 2.3923f, 2.1735f, 1.9673f, 1.7443f };
	static constexpr float kKE145[kArms]  = { 0.2592f, 0.4534f, 0.7378f, 1.2503f, 5.1227f };

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
	// ⭐ 회전 — `_cyc` = 지금 순회 번호 · `_rot` = 갈아 끼운 횟수(배관 보고용)
	inline static uint32 _cyc = 0u, _rot = 0u;

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
		LogA("[mlt] 🔄 **회차 146 · 회전 마스크 — 대가를 「표본」과 「경쟁」으로 가른다**(%s)\n",
			(_seeds == 1u) ? "⚠️ 1씨앗 진단" : "⭐ 판정 회차");
		LogA("[mlt] 🔄   ⭐ 표제 = ***회차 145 의 대가 중 얼마가 「표본」이었나***\n");
		LogA("[mlt] 🔄   ⚠️ 145 의 마스크는 **씨앗마다 고정**이라 버려진 지속 표적이 800걸음 내내 **한 번도** 안 보였다\n");
		LogA("[mlt] 🔄   ⇒ ★ **순회마다 다른 부분집합**을 남긴다(해시에 순회 번호) · 800÷64 = **12.5 순회**\n");
		LogA("[mlt] 🔄      적어도 한 번 보일 확률 `1−(1−q)^12.5` — q=0.50 ~100%% · 0.25 ~97%% · 0.10 ~73%%\n");
		LogA("[mlt] 🔄   ⇒ ⭐ **표본 손실이 거의 사라지고 「가중」만 남는다**(커널 0줄)\n");
		LogA("[mlt] 🔄   ⭐ **양쪽 끝이 검산**(회전이 무의미하다) — q=1.00 → %.4f · q=0.00 → %.4f ±0.05\n",
			(double)kCE145[0], (double)kCE145[kArms - 1u]);
		LogA("[mlt] 🔄      ★ 그 검산이 *\"풀을 12.5번 다시 올리는 배관 자체가 무해한가\"* 도 확인한다\n");
		LogA("[mlt] 🔄   ⭐ 자 = **표본 몫** `−Δ지속 / (지속₁₄₅ − %.4f)` · 표제 통과 = 변화 < %.4f 이고 지속 < %.4f\n",
			(double)kKeepA, (double)kTarget, (double)kKeepLim);
		LogA("[mlt] 🔄   ⭐ 예측 — 변화는 거의 안 변할 것 · 지속 0.50→0.28~0.36 · 0.25→0.35~0.55 · 0.10→0.60~0.95\n");
		LogA("[mlt] 🔄      ⭐ **표본 몫 0.40~0.70** · ⚠️ 표제는 **여전히 통과 못 할 것**\n");
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

	// ⭐ **회전 해시** — 「이 자리의 지속 표적을 이 순회에 남기나」.
	//   ⚠️⚠️ **회차 145 와 다른 점이 이 인자 하나(`cyc`)다.** 145 는 씨앗마다 **고정**이라
	//     버려진 지속 표적이 **800걸음 내내 한 번도** 안 보였다 ⇒ 그것이 「표본 손실」이었다.
	//   ⇒ ★ 순회마다 다른 부분집합을 남기면 `1 − (1−q)^12.5` 확률로 적어도 한 번 보인다
	//     (q=0.50 → ~100% · 0.25 → ~97% · 0.10 → ~73%) ⇒ **가중만 남는다**.
	static uint32 _Hash(uint32 ctx, uint32 t, uint32 a, uint32 cyc)
	{
		uint32 h = ((ctx * 131u + t * 17u + a) * 2654435761u) ^ (_seed * 97u + 12345u);
		h ^= (cyc + 1u) * 2654435761u;
		h ^= h >> 15; h *= 2246822519u; h ^= h >> 13; h *= 3266489917u; h ^= h >> 16;
		return h % 1000u;
	}

	// ── 13축 → 14축(낱말은 상수 0) + 마스크 ─────────────────────────
	//   `mask == kMNone` 이면 **학습**이고 `keepQ`·`cyc` 로 지속 표적을 솎는다.
	//   `kMChange`/`kMKeep` 은 **시험 채점** 마스크다(`keepQ`·`cyc` 무시).
	static void _Expand(const MLTP3Ctx& C, uint32 nCtx, uint32 mask, uint32 keepQ, uint32 cyc,
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
						else if (keep && _Hash(ctx, t, a, cyc) >= keepQ) tf = (float)kN;
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
		_Expand(_ptA, kPtCtx, mask, 1000u, 0u, _eVal[1], _eSym[1], _eTgt[1]);
		return _M.UploadPool(_eVal[1], _eTgt[1], kPtPool) && _M.UploadSymbolPool(_eSym[1], kPtPool);
	}

	// ⭐ **순회 `cyc` 의 학습 풀을 만들어 올린다** — 이것이 이 회차의 배관 그 자체다.
	//   ⚠️ 양 끝(`q = 1000`/`0`)은 순회마다 **같은 풀**이 나오므로 검산이 그대로 성립한다
	//     ⇒ ★ 그 검산이 *"풀을 12.5번 다시 올리는 것 자체가 무해한가"* 도 같이 확인한다.
	static bool _UploadTrain(uint32 cyc)
	{
		_Expand(_trA, kNCtx, kMNone, kKeepQ[_arm], cyc, _eVal[0], _eSym[0], _eTgt[0]);
		if (_seed == 0u && _out == 0u && cyc == 0u) _nTrain[_arm] = (double)_lastScored / (double)kNCtx;
		return _M.UploadPool(_eVal[0], _eTgt[0], kPoolSteps) && _M.UploadSymbolPool(_eSym[0], kPoolSteps);
	}

	static void _BodyBegin(RHI* rhi)
	{
		if (!_M.Setup(rhi, kSymA, kN, kAx14, kTime)) { _Fail("몸통 준비"); return; }
		_cyc = 0u;
		if (!_UploadTrain(0u)) { _Fail("학습 풀 업로드"); return; }
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
			// ⭐ 순회 경계에서 **풀을 갈아 끼운다**(회전 마스크). ⚠️ 스텝 경계에서만 한다.
			const uint32 want = _step / kPoolSteps;
			if (want != _cyc)
			{
				_cyc = want;
				if (!_UploadTrain(_cyc)) { _Fail("회전 풀 업로드"); return; }
				++_rot;
			}
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
		LogA("[mlt] 🔄   %s 씨앗 %2u · 바깥 %u · **변화 %.5f** · 지속 %.5f · 학습표적 %.1f\n",
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
		LogA("[mlt] 🔄 **회차 146 · 회전 마스크 — 표본인가 경쟁인가** (씨앗 %u/%u · 유한 %s · 회전 %u회)\n",
			ok, _seeds, _finite ? "✅" : "⛔", _rot);

		// ── ① 파레토 곡선 + ⭐ **145 대비** ────────────────────────
		LogA("[mlt] 🔄   ── ① ⭐ **파레토**(목표선 변화 < %.4f · 지속 < %.4f) + **145 대비** ──\n",
			(double)kTarget, (double)kKeepLim);
		LogA("[mlt] 🔄     팔                    │ 학습표적 │ **변화 CE**(Δ145) · **지속 CE**(Δ145) │ 통과\n");
		double ch[kArms], ke[kArms];
		uint32 nPass = 0u, firstPass = kArms;
		for (uint32 a = 0; a < kArms; ++a)
		{
			ch[a] = _ArmMean(a, false); ke[a] = _ArmMean(a, true);
			const bool okA = (ch[a] < (double)kTarget) && (ke[a] < (double)kKeepLim);
			if (okA) { ++nPass; if (firstPass == kArms) firstPass = a; }
			LogA("[mlt] 🔄     %s │ %6.1f  │ **%.4f**(%+.4f) · **%.4f**(%+.4f) │ %s\n",
				_ArmName(a), _nTrain[a],
				ch[a], ch[a] - (double)kCE145[a], ke[a], ke[a] - (double)kKE145[a],
				okA ? "⭐ **통과**" : "⛔");
		}

		// ── ①′ ⭐ **표본 몫** — 이 회차의 진짜 산출물 ─────────────
		//   `표본 몫 = −Δ지속 / (지속₁₄₅ − 지속₍q=1₎)` = 「145 의 지속 악화 중 표본이 설명한 비율」
		//   ⚠️⚠️ **1씨앗에서는 못 읽는다** — 145 값이 **12씨앗 평균**이라 1씨앗 값과 견주면
		//     규율 51 의 그 함정이다(1씨앗 진단이 이 자리를 실제로 잡았다 — **네 번째**다).
		LogA("[mlt] 🔄   ── ①′ ⭐ **표본 몫**(0 = 전부 경쟁 · 1 = 전부 표본) ──%s\n",
			(_seeds < 3u) ? "  ⚠️ **1씨앗에서는 못 읽는다**(145 는 12씨앗 평균 · 규율 51)" : "");
		double shareSum = 0.0; uint32 shareN = 0u;
		for (uint32 a = 1; a + 1u < kArms; ++a)
		{
			const double den = (double)kKE145[a] - (double)kKeepA;
			const double share = (den > 1.0e-9) ? (((double)kKE145[a] - ke[a]) / den) : 0.0;
			shareSum += share; ++shareN;
			LogA("[mlt] 🔄     %s │ 지속 145 **%.4f** → 146 **%.4f** │ **표본 몫 %+.3f**\n",
				_ArmName(a), (double)kKE145[a], ke[a], share);
		}
		const double shareAvg = (shareN == 0u) ? 0.0 : shareSum / (double)shareN;
		LogA("[mlt] 🔄     ⭐ **평균 표본 몫 = %+.3f** — 예측은 0.40~0.70 이었다\n", shareAvg);

		// ── ② 짝지은 차(팔 − ㈀) ────────────────────────────────────
		LogA("[mlt] 🔄   ── ② **짝지은 차**(팔 − ㈀ · 음수 = 변화가 나아졌다) · SE 에 실행 항 ──\n");
		for (uint32 a = 1; a < kArms; ++a)
		{
			const Pair p = _Paired(a, 0u);
			LogA("[mlt] 🔄     %s │ d̄ %+.5f · SE %.5f · **|d̄|/SE %6.2f** · %u/%u\n",
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
		LogA("[mlt] 🔄   ── ③ **`sd_run` 확인**(규율 47) — 비트 동일 **%u/%u** · 평균 |Δ| **%.3e**\n",
			runZero, runN, (runN == 0u) ? 0.0 : runSum / (double)runN);
		// ⭐ 회차 145 는 **0/60 · 3.574e-02** 였다 — ⚠️ 회전 재업로드가 **결정성을 바꾸면**
		//   그것이 회차 135·136 의 *"관찰을 끼우면 갈림이 사라진다"* 자리다(등록문의 위험 항목).
		LogA("[mlt] 🔄     ↔ 회차 145(고정 마스크)는 **0/%u · 3.574e-02** 였다 → %s\n",
			runN, (runZero > 0u) ? "⭐ **회전이 결정성을 높였다**(체제가 다르다 ⇒ 검산이 그만큼 중요하다)"
			                     : "체제가 같다");

		// ── 관문 ────────────────────────────────────────────────────
		const double cA = Abs((float)(ch[0] - (double)kCE145[0]));
		const double cB = Abs((float)(ch[kArms - 1u] - (double)kCE145[kArms - 1u]));
		const bool apply = (_seeds >= 3u);
		const bool gChk = !apply || (cA <= 0.05 && cB <= 0.05);
		bool mono = true;
		for (uint32 a = 1; a < kArms; ++a) if (!(ch[a] <= ch[a - 1u])) mono = false;
		LogA("[mlt] 🔄   ── 관문 ──\n");
		LogA("[mlt] 🔄     ⭐ **검산 둘** — ㈀ %.4f(↔%.4f · 차 %.4f) · ㈄ %.4f(↔%.4f · 차 %.4f) → %s\n",
			ch[0], (double)kCE145[0], cA, ch[kArms - 1u], (double)kCE145[kArms - 1u], cB,
			!apply ? "⚠️ 건너뜀(씨앗 3 이상 — 규율 51)" : (gChk ? "✅" : "⛔ **배치가 다르다**"));
		LogA("[mlt] 🔄     ⭐ **단조성**(변화 CE 가 q 에 대해 단조 감소 · 규율 46) → %s\n",
			mono ? "✅" : "⚠️ **단조가 아니다** — 해석에 손잡이가 안 붙는다");
		LogA("[mlt] 🔄     ⭐ **표제**(변화 < %.4f 이고 지속 < %.4f 인 팔) — **%u 개**\n",
			(double)kTarget, (double)kKeepLim, nPass);

		// ── 판정 ────────────────────────────────────────────────────
		//   ⚠️ **표제(통과 점)보다 부표제(표본 몫)가 이 회차의 값**이다 — 등록문이 그렇게 적었다.
		if (!_finite || ok < _seeds)  LogA("[mlt] 🔄   ⭐ 판정 = ⛔ **판정불가** — 배관이 안 섰다\n");
		else if (!gChk)               LogA("[mlt] 🔄   ⭐ 판정 = ⛔ **판정불가** — ***검산이 깨졌다***(145 와 배치가 다르거나 회전 배관이 해롭다)\n");
		else if (_seeds == 1u)        LogA("[mlt] 🔄   ⭐ **1씨앗 진단이다 — 판정하지 않는다**(규율 51)\n");
		else
		{
			if (nPass > 0u)
				LogA("[mlt] 🔄   ⭐ 표제 = ⭐ ***통과하는 가중이 있다*** — %s (변화 %.4f · 지속 %.4f)\n",
					_ArmName(firstPass), ch[firstPass], ke[firstPass]);
			else
				LogA("[mlt] 🔄   ⭐ 표제 = ⛔ **통과 점이 없다**(145 와 같다)\n");
			if (shareAvg >= 0.7)
				LogA("[mlt] 🔄   ⭐ 부표제 = ⭐ ***대가의 대부분이 「표본」이었다***(몫 %+.3f)\n"
				     "[mlt] 🔄      ⇒ ★ 다음은 **진짜 가중**(커널의 표적별 손실 스케일)이고 그것이 값을 낸다\n", shareAvg);
			else if (shareAvg <= 0.3)
				LogA("[mlt] 🔄   ⭐ 부표제 = ⛔ ***대가가 「경쟁」이다***(몫 %+.3f) — 표본을 되돌려도 안 낫다\n"
				     "[mlt] 🔄      ⇒ ★ 다음은 **용량**(폭/층)이다 · ⚠️ 다른 하네스의 검산이 다 깨진다\n", shareAvg);
			else
				LogA("[mlt] 🔄   ⭐ 부표제 = ⚠️ **반반이다**(몫 %+.3f) — 표본도 경쟁도 절반씩\n"
				     "[mlt] 🔄      ⇒ ★ 그러면 **진짜 가중이 먼저**다(싸고, 그것을 하면 남는 것이 순수 경쟁이다)\n", shareAvg);
		}
		LogA("[mlt] 🔄   ⚠️ 문맥 학습 %u · 시험 %u · %u걸음 — 절대 성능으로 인용하지 않는다\n", kNCtx, kPtCtx, kSteps);
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		_E.Destroy(); _done = true;
	}

	static void _Fail(const char* why)
	{
		LogA("[mlt] 🔄 ⛔ %s (씨앗 %u · 팔 %u · 바깥 %u · 평가 %u · 단계 %u · 코퍼스 %u · 걸음 %u)\n",
			why, _seed, _arm, _out, _evalIdx, _st, _cor, _step);
		_E.Destroy(); _done = true;
	}

	CW_BODY(MLTL1I0)
};
