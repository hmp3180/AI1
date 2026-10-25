// mltl1d0.cw — 🪜 회차 141 · **천장을 올린다** (`-mlt -mltl1d0` · 진단은 `-mltdiag1`)
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 141 이다.** ⭐ **하네스보다 먼저 썼다.**
//   **상위 캔버스: `자의 천장을 올린다` · 141~ = 1회차**(캔버스를 바꿨으므로 **한 회차 파일럿**).
//
// ── ⭐ 표제 — ***천장을 32배 올렸는데 `SE` 도 같이 올라가나*** ────────
//   회차 140 의 처방은 손잡이 둘이고 **곱해진다**:
//     ㈎ 낱말을 **시각당 하나**(×7~8) · ㈏ 채점을 **변화 표적에만**(×4.6)
//   ⚠️ 그런데 ㈏ 는 **CE 절대값을 4배로 올리고 표본을 1/4.6 로 줄인다** ⇒ `SE` 도 따라 오르면
//   이득이 상쇄된다. ★ 그것이 이 파일럿의 물음이고, 답이 곧 **규율 49 를 쓸 수 있느냐**다.
//
// ── 🔬 **1씨앗 진단(114초)이 설계 오류 둘을 잡았다 — 판정 전에 고쳤다** ────
//   ㉠ ⭐ **상수 팔을 바닥으로 쓸 수 없다.** 섞은 낱말(정보 0)이 상수 대비 **−0.117 을 도왔다**
//      (`|d̄|/SE = 9.73`). ⇒ 값이 늘 0 인 축은 **죽은 축**이고, **변동하는 값**이 들어오는 것만으로
//      모델이 달라진다. ★ 138·139 의 「축 개수」 교란의 **새 얼굴**이다(이번엔 **입력의 변동성**).
//      ⇒ ★ **바닥을 ㈂(섞음)으로 바꾸고**, 음성 대조는 **또 다른 섞기**(㈃)로 세운다.
//   ㉡ ⭐ **천장을 넘었다 — 실현율 120.8%.** ⇒ `천장`(규율 49)은 ***관측 `d̄` 의 상한이 아니다***:
//      `d̄ = I(낱말;표적|문맥) + (KL_바닥 − KL_개입)` 이고 우리는 **두 모델을 따로 학습**시키므로
//      **근사 오차의 차**가 더해진다. ⇒ 천장은 *"정보 경로가 닫혔나"*(천장 ≪ SE)를 말할 뿐이다.
//
// ── 🎛️ 팔 넷 — ⚠️ 축·파라미터·걸음이 전부 같다(14축 · 800걸음) ───────────
//   ㈀ **상수**(계급 4 ⇒ 값 0 · **보고용** — 「변동성 효과」의 크기를 준다) ·
//   ⭐ ㈁ **그 시각에 「바뀌는」 슬롯의 표적 id 계급**(⭐ **표제/양성**) ·
//   ⭐ ㈂ ㈁ 을 **전부 섞은 것**(⭐ **바닥** — 같은 주변분포·같은 변동성 · 정보만 0) ·
//   ㈃ **다른 씨앗으로 또 섞은 것**(**음성** — ㈂ 와 구별 안 돼야 한다)
//   ⚠️ **학습 풀은 안 건드린다** — 마스크는 **시험 풀에만**. 바꾸는 것은 **자**이지 **과제**가 아니다.
//   ⚠️ 낱말 축의 표적은 `IgnoreTgt` ⇒ 채점 대상이 팔마다 같다.
//
// ── 📏 자 — ⭐ 무차원 둘 ──────────────────────────────────────────────────
//   ㉠ `천장 ÷ SE` = `(kTime × H(낱말)) / 채점표적수 ÷ SE`   ← ⭐ **규율 49 를 여기서 쓴다**
//   ㉡ `|d̄| / SE`  = 짝지은 `(㈁ − ㈀)` ± SE(**실행 항 포함**)  ← 양성이 실제로 서나
//   ⭐ 기본 장비 넷: `sd_run` 확인 관문 · SE 에 실행 항 · **실행 2회** · 무차원.
//
// ── 🔮 예측(재기 전에 적었다 · 최근 마흔둘 중 스물둘 틀림) ────────────────
//   채점 표적 **12.2/문맥** · D11 지속 CE **0.10~0.25** · 변화 CE **3.0~4.0** ·
//   `SE` **0.024~0.050** · ⭐ **㉠ 25~55(관문 ≥10 통과)** · ⭐ **㉡ > 10 · 12/12** · ㈂ 구별 안 됨
//   ⚠️ 위험: ㈏ 가 `SE` 를 **비례 이상**으로 올리면 ㉠ 이 10 미만 ⇒ ㈎ 만 쓰고 ㈏ 를 버린다.
// ══════════════════════════════════════════════════════════════════════════════

using namespace PE;

class MLTL1D0
{
public:
	static void Tick(RHI* rhi)
	{
		if (_done || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltl1d0"))
		{
			LogA("[mlt] 🪜 회차 141(천장을 올린다)은 **꺼져 있다**(`-mltl1d0`)\n");
			_done = true; return;
		}
		if (!_banner)
		{
			// ⭐ 규약 — **12씨앗 전에 1씨앗 진단**. `-mltdiag1` 이 그 스위치다.
			_seeds = OS::CommandLine::Has("-mltdiag1") ? 1u : kSeedsMax;
			_Banner(); _banner = true;
		}
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

	// ⚠️ **138·139·140 과 같은 코퍼스**여야 견줄 수 있다.
	static constexpr uint32 kNCtx = 512u, kPbCtx = 512u, kPtCtx = 512u;
	static constexpr uint32 kTrainEpi = 1u, kPbEpi = 2001u, kPtEpi = 5001u;
	static_assert(kPbEpi >= kTrainEpi + kNCtx, "규율 12");
	static_assert(kPtEpi >= kPbEpi + kPbCtx, "규율 12");
	static constexpr uint32 kPoolSteps = kNCtx / kBatch;
	static constexpr uint32 kPtPool = kPtCtx / kBatch;
	static constexpr uint32 kSteps = 800u, kPerTick = 16u;

	static constexpr uint32 kSymA = MLTP3Ctx::kStateAx + kN + 1u;    // 256
	static constexpr uint32 kAx13 = MLTP3Ctx::kAxes;                 // 13
	static constexpr uint32 kAx14 = kAx13 + 1u;                      // 14
	static constexpr uint32 kCtx14 = kAx14 * kTime;                  // 112
	static constexpr uint32 kRows14 = kBatch * kCtx14;               // 896
	static constexpr float  kWordSym = 255.0f;

	// ⭐ 낱말 계급 **9** — 0 = 「변화 없음」 · 1~8 = 그 표적 id 의 8분위.
	//   ★ 9 로 잡은 이유: 값이 `(cls/8)*2−1` 이라 **가운데 계급 4 가 정확히 0** ⇒ 상수 팔의 입력이 0.
	static constexpr uint32 kWordCls = 9u;
	static constexpr uint32 kConstCls = 4u;

	// ⚠️ **진단 뒤 넷으로 늘렸다** — 바닥이 ㈂(섞음)이고 음성은 ㈃(다른 섞기)다.
	static constexpr uint32 kArms = 4u;
	static constexpr uint32 kBase = 2u;   // ⭐ **바닥 팔** = ㈂ 섞음A
	// 시험 채점 마스크 — ⚠️ 판정은 **변화만**이고 나머지 둘은 **D11 보고용**이다.
	enum { kMChange = 0u, kMKeep = 1u, kMAll = 2u, kMNone = 3u };
	static constexpr uint32 kEvalsArm0 = 3u;

	static constexpr uint32 kOut = 2u;   // ⭐ 실행 2회(규율 37)

	enum { kEncInit, kEncTrain, kGather, kQuiesce, kBodyInit, kBodyTrain, kEval };

	inline static MLTP2Enc _E;
	inline static MLTModel _M;
	inline static MLTP3Ctx _trA, _pbA, _ptA;
	inline static bool _done = false, _banner = false, _encSetup = false, _finite = true;
	inline static bool _pending = false;
	inline static uint32 _seed = 0u, _st = kEncInit, _step = 0u;
	inline static uint32 _arm = 0u, _out = 0u, _evalIdx = 0u;
	inline static uint32 _cor = 0u, _gGrp = 0u, _gIdx = 0u, _qWait = 0u;
	inline static Array<float> _code, _norm;

	inline static Array<uint32> _wChTr, _wChTe;      // ⭐ ㈁ 「바뀌는 슬롯의 표적 id」 계급
	inline static Array<uint32> _wTr, _wTe;          // 지금 팔의 낱말
	inline static Array<float> _eVal[2], _eSym[2], _eTgt[2];
	inline static MLTEvalGate _gate;

	inline static float _ce[kOut][kArms][kSeedsMax];          // ⭐ 판정용(변화만)
	inline static float _ceKeep[kOut][kSeedsMax], _ceAll[kOut][kSeedsMax];   // 📊 D11
	inline static bool  _seedOk[kSeedsMax];
	inline static double _hW[kArms][kSeedsMax];               // 낱말 엔트로피(시험 코퍼스)
	inline static double _nScored[3][kSeedsMax];              // 마스크별 문맥당 채점 표적 수
	inline static uint32 _lastScored = 0u;

	static void _ToBody() { _qWait = MLTEvalGate::kDelay; _st = kQuiesce; }
	static const char* _ArmName(uint32 a)
	{
		switch (a)
		{
		case 0u: return "㈀ 상수(보고)    ";
		case 1u: return "㈁ 변화표적id ⭐ ";
		case 2u: return "㈂ 섞음A(바닥)⭐ ";
		default: return "㈃ 섞음B(음성)   ";
		}
	}
	static const char* _MaskName(uint32 m)
	{
		switch (m) { case kMChange: return "변화만"; case kMKeep: return "지속만"; default: return "전체"; }
	}
	static uint32 _SignPass() { return (_seeds * 10u + 11u) / 12u; }

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🪜 **회차 141 · 천장을 올린다**(%s)\n", (_seeds == 1u) ? "⚠️ **1씨앗 진단**" : "⭐ 판정 회차");
		LogA("[mlt] 🪜   ⭐ 표제 = ***천장을 32배 올렸는데 `SE` 도 같이 올라가나***\n");
		LogA("[mlt] 🪜   손잡이 둘 — ㈎ 낱말을 **시각당 하나**(×8) · ㈏ 채점을 **변화 표적에만**(×4.6)\n");
		LogA("[mlt] 🪜   ⚠️ ㈏ 는 CE 를 4배로 올리고 표본을 1/4.6 로 줄인다 ⇒ **`SE` 가 따라 오르면 상쇄**된다\n");
		LogA("[mlt] 🪜   팔 넷 — ㈀ 상수(보고) · ⭐ ㈁ **바뀌는 슬롯의 표적 id 계급**(표제) · ⭐ ㈂ 섞음A(**바닥**) · ㈃ 섞음B(음성)\n");
		LogA("[mlt] 🪜   ⚠️⚠️ **바닥이 상수가 아니라 「섞음」이다** — 1씨앗 진단이 *\"정보 0 인 낱말도 상수보다 낫다\"* 를 잡았다\n");
		LogA("[mlt] 🪜      (`㈂−㈀ = −0.117` · `|d̄|/SE 9.73`) ⇒ **값이 늘 0 인 축은 죽은 축**이고 변동만으로 모델이 달라진다\n");
		LogA("[mlt] 🪜   ⚠️ **학습 풀은 안 건드린다** — 마스크는 **시험 풀에만**(바꾸는 것은 자이지 과제가 아니다)\n");
		LogA("[mlt] 🪜   ⭐ 관문 = **천장÷SE ≥ 10**(규율 49) · 표제 %u/%u 이고 |d̄|/SE ≥ 3 · 음성(㈃↔㈂) 구별 안 됨\n", _SignPass(), _seeds);
		LogA("[mlt] 🪜   ⭐ 예측 — 채점 12.4/문맥 · **천장÷SE ≫ 10** · 표제 |d̄| ≈ 1.07 나트(1씨앗 진단)\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

	// ── 인코더 · 코퍼스 (138~140 과 같다) ────────────────────────────
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
		_trA.SetSortById(true); _pbA.SetSortById(true); _ptA.SetSortById(true);
		_trA.Begin(kNCtx, kN); _pbA.Begin(kPbCtx, kN); _ptA.Begin(kPtCtx, kN);
		_cor = 0u; _gGrp = 0u; _gIdx = 0u; _pending = false; _st = kGather;
	}

	static uint32 _NCtxOf(uint32 c) { return (c == 0u) ? kNCtx : ((c == 1u) ? kPbCtx : kPtCtx); }
	static uint32 _EpiOf(uint32 c)  { return (c == 0u) ? kTrainEpi : ((c == 1u) ? kPbEpi : kPtEpi); }
	static MLTP3Ctx& _CorA(uint32 c) { return (c == 0u) ? _trA : ((c == 1u) ? _pbA : _ptA); }

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
		if (++_cor < 3u) return;
		_ChangeWord(_trA, kNCtx,  _wChTr);
		_ChangeWord(_ptA, kPtCtx, _wChTe);
		_arm = 0u; _ToBody();
	}

	// ── ⭐ 낱말 — **시각당 하나**. 「그 시각에 바뀌는 첫 슬롯의 표적 id」의 8분위(+1). ──
	//   ⚠️ 0 = 「그 시각에 바뀌는 슬롯이 없다」 ⇒ 그 자체도 정보다(그리고 그 시각엔 채점거리가 없다).
	static void _ChangeWord(const MLTP3Ctx& C, uint32 nCtx, Array<uint32>& w)
	{
		w.Reset(0);
		for (uint32 ctx = 0; ctx < nCtx; ++ctx)
			for (uint32 t = 0; t < kTime; ++t)
			{
				const uint32 b = MLTP3Ctx::Row(ctx, t, kStateAx);
				uint32 cls = 0u;
				for (uint32 j = 0; j < kSlots; ++j)
				{
					const float tf = C.Tgt()[b + j];
					if (!(tf >= 0.0f && tf < (float)kN)) continue;
					const uint32 tid = (uint32)tf;
					if ((uint32)(C.Sym()[b + j] - (float)kStateAx) == tid) continue;   // 지속 — 건너뛴다
					cls = 1u + (tid * (kWordCls - 1u)) / kN;
					break;
				}
				w.Add(cls);
			}
	}

	static void _Shuffle(const Array<uint32>& in, Array<uint32>& out, uint32 salt)
	{
		out.Reset(0);
		for (uint32 i = 0; i < in.Count(); ++i) out.Add(in[i]);
		uint32 rs = _seed * 2654435761u + salt;
		for (uint32 i = out.Count(); i > 1u; --i)
		{
			rs = rs * 1664525u + 1013904223u;
			const uint32 j = rs % i;
			const uint32 tmp = out[i - 1u]; out.Data()[i - 1u] = out[j]; out.Data()[j] = tmp;
		}
	}

	// ── 13축 → 14축(낱말을 **축 0** 에) + ⭐ 시험 채점 마스크 ────────────
	//   ⚠️ 낱말은 **축 0** 이어야 한다 — 몸통이 causal 이고 행 순서가 `t*축 + a` 다(회차 132 의 진단).
	//   ⚠️ 낱말 색인이 **`ctx*kTime + t`** 다(회차 141 의 손잡이 ㈎ — 138·139 는 `ctx` 였다).
	static void _Expand(const MLTP3Ctx& C, uint32 nCtx, const Array<uint32>& word, uint32 mask,
		Array<float>& oVal, Array<float>& oSym, Array<float>& oTgt)
	{
		const uint32 steps = nCtx / kBatch;
		const uint32 n = steps * kRows14;
		oVal.Reset(0); oSym.Reset(0); oTgt.Reset(0);
		for (uint32 i = 0; i < n; ++i) { oVal.Add(0.0f); oSym.Add(0.0f); oTgt.Add((float)kN); }
		uint32 scored = 0u;
		for (uint32 ctx = 0; ctx < nCtx; ++ctx)
		{
			const uint32 k = ctx / kBatch, b = ctx % kBatch;
			for (uint32 t = 0; t < kTime; ++t)
			{
				const uint32 src = MLTP3Ctx::Row(ctx, t, 0u);
				const uint32 dst = k * kRows14 + b * kCtx14 + t * kAx14;
				const uint32 wi = ctx * kTime + t;
				const uint32 cls = (word.Count() > wi) ? word[wi] : kConstCls;
				oVal.Data()[dst] = ((float)cls / (float)(kWordCls - 1u)) * 2.0f - 1.0f;
				oSym.Data()[dst] = kWordSym;
				oTgt.Data()[dst] = (float)kN;                       // IgnoreTgt
				for (uint32 a = 0; a < kAx13; ++a)
				{
					oVal.Data()[dst + 1u + a] = C.Val()[src + a];
					oSym.Data()[dst + 1u + a] = C.Sym()[src + a];
					float tf = C.Tgt()[src + a];
					// ⭐ 손잡이 ㈏ — **시험 채점 마스크**(학습에는 안 건다)
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

	static void _MakeArmPools()
	{
		const uint32 a = _arm;
		if (a == 0u)
		{
			_wTr.Reset(0); _wTe.Reset(0);
			for (uint32 i = 0; i < kNCtx  * kTime; ++i) _wTr.Add(kConstCls);
			for (uint32 i = 0; i < kPtCtx * kTime; ++i) _wTe.Add(kConstCls);
		}
		else if (a == 1u) { _wTr = _wChTr; _wTe = _wChTe; }
		else
		{
			// ⭐ ㈂ 는 바닥 · ㈃ 는 음성 — **섞기 씨앗만 다르다**(같은 주변분포 · 같은 변동성)
			const uint32 s0 = (a == 2u) ? 11u : 33u, s1x = (a == 2u) ? 22u : 44u;
			Array<uint32> s1, s2;
			_Shuffle(_wChTr, s1, s0); _Shuffle(_wChTe, s2, s1x);
			_wTr = s1; _wTe = s2;
		}
		// 낱말 엔트로피(시험 코퍼스) — ⭐ 천장의 분자다
		Array<uint32> h; h.Reset(0);
		for (uint32 i = 0; i < kWordCls; ++i) h.Add(0u);
		for (uint32 i = 0; i < _wTe.Count(); ++i) ++h.Data()[_wTe[i] % kWordCls];
		double e = 0.0;
		for (uint32 i = 0; i < kWordCls; ++i)
		{
			if (h[i] == 0u) continue;
			const double p = (double)h[i] / (double)_wTe.Count();
			e += -p * (double)Log((float)p);
		}
		_hW[a][_seed] = e;
		_Expand(_trA, kNCtx, _wTr, kMNone, _eVal[0], _eSym[0], _eTgt[0]);   // ⚠️ 학습은 마스크 없음
	}

	static bool _UploadTest(uint32 mask)
	{
		_Expand(_ptA, kPtCtx, _wTe, mask, _eVal[1], _eSym[1], _eTgt[1]);
		if (_arm == 0u && _out == 0u) _nScored[mask][_seed] = (double)_lastScored / (double)kPtCtx;
		return _M.UploadPool(_eVal[1], _eTgt[1], kPtPool) && _M.UploadSymbolPool(_eSym[1], kPtPool);
	}

	static void _BodyBegin(RHI* rhi)
	{
		if (!_M.Setup(rhi, kSymA, kN, kAx14, kTime)) { _Fail("몸통 준비"); return; }
		_MakeArmPools();
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
			LogA("[mlt] 🪜   %s 씨앗 %2u · 바깥 %u · **변화만 CE %.5f**(채점 %.1f/문맥)\n",
				_ArmName(_arm), _seed, _out, (double)ce, _nScored[kMChange][_seed]);
		}
		else if (_evalIdx == 1u) { _ceKeep[_out][_seed] = ce; }
		else                      { _ceAll[_out][_seed] = ce; }

		// 📊 D11 — ㈀ 팔에서만 마스크 셋을 다 잰다
		if (_arm == 0u && _evalIdx + 1u < kEvalsArm0)
		{
			++_evalIdx;
			const uint32 m = (_evalIdx == 1u) ? kMKeep : kMAll;
			if (!_UploadTest(m)) { _Fail("D11 시험 풀 업로드"); return; }
			_gate.Begin(kPtPool); return;
		}
		if (_arm == 0u && _evalIdx + 1u == kEvalsArm0)
			LogA("[mlt] 🪜   📊 **D11** 씨앗 %2u · 바깥 %u — 지속만 **%.5f**(%.1f/문맥) · 전체 **%.5f**(%.1f/문맥)\n",
				_seed, _out, (double)_ceKeep[_out][_seed], _nScored[kMKeep][_seed],
				(double)_ceAll[_out][_seed], _nScored[kMAll][_seed]);

		if (++_arm < kArms) { _ToBody(); return; }
		_arm = 0u;
		if (++_out < kOut) { _ToBody(); return; }
		_out = 0u;
		_seedOk[_seed] = _finite;
		++_seed; _st = kEncInit;
	}

	// ── 짝지은 차 — ⭐ SE 에 **실행 잡음 항**(규율 29·37) ─────────────
	static double _M2(uint32 a, uint32 s)
	{
		double v = 0.0;
		for (uint32 o = 0; o < kOut; ++o) v += (double)_ce[o][a][s];
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

	static double _MeanOf(const double* v)
	{
		double m = 0.0; uint32 n = 0u;
		for (uint32 s = 0; s < _seeds; ++s) { if (!_seedOk[s]) continue; m += v[s]; ++n; }
		return (n == 0u) ? 0.0 : m / (double)n;
	}

	static void _Summary()
	{
		uint32 ok = 0u;
		for (uint32 s = 0; s < _seeds; ++s) if (_seedOk[s]) ++ok;
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🪜 **회차 141 · 천장을 올린다** (씨앗 %u/%u · 유한 %s)\n", ok, _seeds, _finite ? "✅" : "⛔");

		// ① 채점 자리 + D11
		double nCh = 0.0, nKe = 0.0, nAl = 0.0; uint32 nn = 0u;
		for (uint32 s = 0; s < _seeds; ++s)
		{
			if (!_seedOk[s]) continue;
			nCh += _nScored[kMChange][s]; nKe += _nScored[kMKeep][s]; nAl += _nScored[kMAll][s]; ++nn;
		}
		if (nn > 0u) { nCh /= (double)nn; nKe /= (double)nn; nAl /= (double)nn; }
		double ceK = 0.0, ceA = 0.0; uint32 mm = 0u;
		for (uint32 s = 0; s < _seeds; ++s)
		{
			if (!_seedOk[s]) continue;
			for (uint32 o = 0; o < kOut; ++o) { ceK += (double)_ceKeep[o][s]; ceA += (double)_ceAll[o][s]; }
			mm += kOut;
		}
		if (mm > 0u) { ceK /= (double)mm; ceA /= (double)mm; }
		double ceCh = 0.0; uint32 cc = 0u;
		for (uint32 s = 0; s < _seeds; ++s) { if (!_seedOk[s]) continue; ceCh += _M2(0u, s); ++cc; }
		if (cc > 0u) ceCh /= (double)cc;

		LogA("[mlt] 🪜   ── ① 채점 자리 + 📊 **D11**(㈀ 팔) ──\n");
		LogA("[mlt] 🪜     문맥당 채점 표적 — **변화만 %.1f** · 지속만 %.1f · 전체 %.1f\n", nCh, nKe, nAl);
		LogA("[mlt] 🪜     ㈀ 팔 CE       — **변화만 %.4f** · 지속만 **%.4f** · 전체 **%.4f**\n", ceCh, ceK, ceA);
		LogA("[mlt] 🪜     ⭐ 검산: `지속몫×지속CE + 변화몫×변화CE` = %.4f (전체 %.4f 와 맞아야)\n",
			(nAl > 1.0e-9) ? (nKe / nAl) * ceK + (nCh / nAl) * ceCh : 0.0, ceA);

		// ② 짝지은 차
		// ⚠️ **바닥은 ㈂(섞음A)이다** — 1씨앗 진단이 *"상수 팔 대비로 재면 정보 0 인 낱말도 돕는다"* 를 잡았다.
		const Pair pTop = _Paired(1u, kBase);   // ⭐ ㈁ − ㈂ : **표제/양성**
		const Pair pNeg = _Paired(3u, kBase);   // ㈃ − ㈂ : **음성**(두 섞기끼리 — 구별 안 돼야)
		const Pair pVar = _Paired(0u, kBase);   // ⭐ ㈀ − ㈂ : **「변동성 효과」**(보고 — 진단이 잡은 것)
		LogA("[mlt] 🪜   ── ② **짝지은 차**(음수 = 왼쪽이 낫다) · SE 에 **실행 항** 포함 ──\n");
		LogA("[mlt] 🪜     견줌            │ d̄        · sd_씨앗 · sd_run  · SE      · **|d̄|/SE** · 이긴 씨앗\n");
		LogA("[mlt] 🪜     ⭐ ㈁−㈂ 표제  │ %+.5f · %.5f · %.5f · %.5f · **%6.2f** · %u/%u\n",
			pTop.d, pTop.sdSeed, pTop.sdRun, pTop.se, pTop.t, pTop.win, pTop.n);
		LogA("[mlt] 🪜     ㈃−㈂ 음성      │ %+.5f · %.5f · %.5f · %.5f · **%6.2f** · %u/%u\n",
			pNeg.d, pNeg.sdSeed, pNeg.sdRun, pNeg.se, pNeg.t, pNeg.win, pNeg.n);
		LogA("[mlt] 🪜     ㈀−㈂ 변동성    │ %+.5f · %.5f · %.5f · %.5f · **%6.2f** · %u/%u  ⚠️ 양수 = 상수축이 나쁘다\n",
			pVar.d, pVar.sdSeed, pVar.sdRun, pVar.se, pVar.t, pVar.win, pVar.n);

		// ③ ⭐ 천장(규율 49)
		const double hPos = _MeanOf(_hW[1]);
		const double cap = (nCh > 1.0e-9) ? ((double)kTime * hPos) / nCh : 0.0;
		const double capSE = (pTop.se > 1.0e-12) ? cap / pTop.se : 0.0;
		LogA("[mlt] 🪜   ── ③ ⭐ **천장**(규율 49) ──\n");
		LogA("[mlt] 🪜     H(㈁ 낱말) **%.4f** × 시각 %u ÷ 채점 %.1f = 천장 **%.4f** 나트\n", hPos, kTime, nCh, cap);
		LogA("[mlt] 🪜     **천장 ÷ SE = %.1f**  (옛 자는 3.28 이었다 — 회차 140)\n", capSE);
		LogA("[mlt] 🪜     ⭐ 실현율 = |d̄| / 천장 = **%.1f%%**\n", (cap > 1.0e-12) ? 100.0 * Abs((float)pTop.d) / cap : 0.0);
		LogA("[mlt] 🪜     ⚠️⚠️ **100%% 를 넘을 수 있다** — 천장은 **정보 항**만 묶는다(1씨앗 진단 실측 120.8%%):\n");
		LogA("[mlt] 🪜        `d̄ = I(낱말;표적|문맥) + (KL_바닥 − KL_개입)` — 두 모델을 **따로 학습**시키므로\n");
		LogA("[mlt] 🪜        **근사 오차의 차**가 더해진다 ⇒ 천장이 말하는 것은 *\"정보 경로가 닫혔나\"* 뿐이다\n");

		// ④ 자가 결정적인가(기본 장비)
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
		LogA("[mlt] 🪜   ── ④ **`sd_run` 확인**(규율 47) — 비트 동일 **%u/%u** · 평균 |Δ| **%.3e**\n",
			runZero, runN, (runN == 0u) ? 0.0 : runSum / (double)runN);

		// ── 관문 ────────────────────────────────────────────────────
		const uint32 pass = _SignPass();
		const bool gCap = (capSE >= 10.0);
		const bool gPos = (pTop.win >= pass) && (pTop.d < 0.0) && (pTop.t >= 3.0);
		const bool negApply = (_seeds >= 3u);
		const bool gNeg = !negApply || !(pNeg.d < 0.0 && pNeg.t >= 3.0);
		LogA("[mlt] 🪜   ── 관문 ──\n");
		LogA("[mlt] 🪜     ⭐ **천장**(≥10) — %.1f → %s\n", capSE, gCap ? "✅" : "⛔ **SE 가 같이 올랐다**");
		LogA("[mlt] 🪜     ⭐ **표제/양성**(㈁<㈂ %u/%u≥%u 이고 |d̄|/SE %.2f≥3) → %s\n",
			pTop.win, pTop.n, pass, pTop.t, gPos ? "✅" : "⛔ **자가 죽었다**");
		LogA("[mlt] 🪜     ⭐ **음성**(㈃ 가 ㈂ 를 안 도와야) — d̄ %+.5f · |d̄|/SE **%.2f** → %s\n",
			pNeg.d, pNeg.t, !negApply ? "⚠️ 건너뜀(씨앗 3 이상)" : (gNeg ? "✅ 두 섞기가 구별 안 된다" : "⛔ **섞기끼리 갈린다 = 자가 흔들린다**"));

		// ── 판정 ────────────────────────────────────────────────────
		if (!_finite || ok < _seeds)
			LogA("[mlt] 🪜   ⭐ 판정 = ⛔ **판정불가** — 배관이 안 섰다\n");
		else if (_seeds == 1u)
			LogA("[mlt] 🪜   ⭐ **1씨앗 진단이다 — 판정하지 않는다.** 배관·부호·크기만 본다\n");
		else if (gCap && gPos && gNeg)
			LogA("[mlt] 🪜   ⭐ 판정 = ⭐ ***천장이 올라갔고 자가 산다*** — 손잡이 둘이 작동한다\n"
			     "[mlt] 🪜      ⇒ ★ 이제 **표제 낱말을 이 자 위에서** 물을 수 있다(⚠️ `minDOn` 은 아니다 — 회차 140)\n");
		else if (!gCap)
			LogA("[mlt] 🪜   ⭐ 판정 = ⛔ **천장이 안 올랐다** — ㈏ 가 `SE` 를 비례 이상으로 올렸다\n"
			     "[mlt] 🪜      ⇒ ★ 다음은 **㈎ 만** 쓰고 ㈏ 를 버린다(등록문의 갈래 그대로)\n");
		else
			LogA("[mlt] 🪜   ⭐ 판정 = ⛔ **천장은 올랐는데 양성이 안 선다** — 낱말이 축에 안 닿는다\n");
		LogA("[mlt] 🪜   ⚠️ 문맥 학습 %u · 시험 %u · %u걸음 — 절대 성능으로 인용하지 않는다\n", kNCtx, kPtCtx, kSteps);
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		_E.Destroy(); _done = true;
	}

	static void _Fail(const char* why)
	{
		LogA("[mlt] 🪜 ⛔ %s (씨앗 %u · 팔 %u · 바깥 %u · 평가 %u · 단계 %u · 코퍼스 %u · 걸음 %u)\n",
			why, _seed, _arm, _out, _evalIdx, _st, _cor, _step);
		_E.Destroy(); _done = true;
	}

	CW_BODY(MLTL1D0)
};
