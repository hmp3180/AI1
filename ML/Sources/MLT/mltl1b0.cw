// mltl1b0.cw — 🔄 회차 132 · **L1 ㉤ 역방향: 낱말을 「주면」 예측이 좋아지나** (`-mltl1b0`)
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 132 다.** ⭐ **하네스보다 먼저 썼다.**
//   **상위 캔버스: `언어를 붙인다`(재개) · 132~ = 1회차**(규율 33).
//   ⭐ 캔버스 `자를 고친다`(128~131)를 닫고 **자의 사용법을 갖고** 돌아왔다.
//
// ── ⭐ 표제 — ***언어가 감각·행동 예측을 바꾸나*** ────────────────────
//   여태 이 트랙의 관문은 **전부 「예측 → 언어」**(프로브)였다. 이번엔 **낱말을 입력으로 준다.**
//
// ── ⚠️⚠️ 설계의 급소 — **어떤 낱말을 주느냐가 전부다** ──────────────────
//   `뜻밖임`·`지속개수` 는 **다음 시각 표적에서 계산한 값**이라 그것을 입력으로 주면
//   ***정답을 흘리는 것***이지 언어가 아니다(규율 34 의 정신).
//   ⇒ ★ **표제 낱말 = `minDOn`**(화면 안 가장 가까운 도형까지의 거리). 근거 셋:
//     ㉠ **모델 입력에 없다**(`VisibleShapes` 는 판정 창구다)
//     ㉡ ⭐ **모델이 그것을 못 담는다는 것이 이미 측정돼 있다** — 회차 126·127 에서
//        음성 대조로 썼고 **5/12 · 4/12** 로 균등바닥을 못 넘었다 ⇒ ***진짜 새 정보다***
//     ㉢ 세계의 사실이라 다음 프레임 변화와 물리적으로 이어진다
//
// ── 🎛️ 팔 넷 — ⚠️ **축 개수를 맞춘다**(회차 116 의 개수 관문) ─────────────
//   ㈀ 낱말 없음(축 13) · ⭐ ㈁ `minDOn`(축 14 · **표제**) ·
//   ⭐ ㈂ `minDOn` 을 **문맥 사이에 섞은 것**(축 14 · **음성** — 같은 주변분포, 정보만 0) ·
//   ⭐ ㈃ `뜻밖임`(축 14 · **양성** — 구성상 새는 말이라 **반드시 도와야** 한다)
//   ⚠️ ㈁㈂㈃ 는 축·파라미터·걸음이 **전부 같다** ⇒ 갈림은 **낱말의 내용**뿐이다.
//   ⚠️ 낱말 축의 표적은 **`IgnoreTgt`** ⇒ ***채점되는 표적이 팔마다 똑같다***.
//
// ── 📏 자 — ⭐ **무차원**(규율 31) ────────────────────────────────────────
//   `이득률 = (CE(㈀) − CE(㈁)) / (CE(㈀) − CE(㈃))`  0 = 안 도움 · 1 = **새는 말만큼** 도움
//
// ── ✅ 관문 ───────────────────────────────────────────────────────────────
//   배관 유한·축 개수 동일·낱말 균형
//   ⭐ **양성**(㈃ < ㈀) **10/12** — ⚠️ 안 서면 **자가 죽은 것**이다
//   ⭐ **음성**(㈂ 가 ㈀ 와 구별 안 됨) `|d̄|/SE < 3`
//   ⭐ **표제** ㈁<㈀ **10/12** **그리고** ㈁<㈂ `|d̄|/SE ≥ 3`
//   ⭐ **회차 131 의 처방** — **바깥 반복 2** 를 표제에 넣고 **SE 에 실행 잡음 항**을 더한다
//     (`SE² = sd_씨앗²/n + sd_run²/(n·kOut)` — 씨앗만 쓰면 회차 127 처럼 6.36 이 0.55 가 된다)
//
// ── ⭐ 예측(재기 전에 적었다 · 최근 스물아홉 중 열넷 틀림) ────────────────
//   ㈃ **크게 도울 것** · ⭐ ㈁ **진짜 모른다**(어림 이득률 0.1~0.3) · ㈂ **구별 안 될 것**
//   ⚠️ 위험: `minDOn` 이 다음 활성 예측과 **약하게만** 이어지면 ㈁ 이 0 이 나오고,
//     그건 *"언어가 안 돕는다"* 가 아니라 ***"그 낱말이 무관하다"*** 다 ⇒ ★ 결론을 그렇게 적는다.
// ══════════════════════════════════════════════════════════════════════════════

using namespace PE;

class MLTL1B0
{
public:
	static void Tick(RHI* rhi)
	{
		if (_done || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltl1b0"))
		{
			LogA("[mlt] 🔄 회차 132(L1 ㉤ 역방향 — 낱말을 주면 예측이 좋아지나)는 **꺼져 있다**(`-mltl1b0`)\n");
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
		if (_st == kBodyInit)  { _BodyBegin(rhi); return; }
		if (_st == kBodyTrain) { _BodyTrain(); return; }
		_EvalStep();
	}

	static bool Done() { return _done; }

private:
	// ⭐ **씨앗 2 진단을 먼저 돌렸다**(3.5분) — 자가 세고(`|d̄|/SE = 16.5`) `sd_run = 0` 임을 봤고,
	//   ⚠️ **관문 둘이 씨앗 수에 매여 있던 것**을 잡아 고쳤다(위 `kSignPass`·`regApply`).
	//   ⇒ ★ 이제 **판정용 12씨앗**.
	// ⭐ 씨앗 2 진단이 **양성 대조의 오배치**를 잡았다(`yaw` = 홀드아웃 축) ⇒ 고치고 **12씨앗**.
	static constexpr uint32 kSeeds = 12u;   // ⭐ 판정(1씨앗 진단이 causal 배치 버그와 관문 오류 둘을 잡았다)
	static constexpr uint32 kEncF = 32u, kEncSteps = 1200u, kEncPerTick = 8u;
	static constexpr uint32 kN = 250u, kLocal = 8u;
	static constexpr uint32 kTime  = MLTP3Ctx::kTime;      // 8
	static constexpr uint32 kBatch = MLTP3Ctx::kBatch;     // 8
	static constexpr uint32 kSlots = MLTP3Ctx::kPersist;   // 8
	static constexpr uint32 kStateAx = MLTP3Ctx::kStateAx; // 5
	static constexpr uint32 kCandidates = MLTP2Cfg::kPatches * kLocal;
	static constexpr uint32 kGroup = kEncF / kTime;        // 4
	static constexpr uint32 kGateT = kTime - 2u;           // 6

	static constexpr uint32 kNCtx = 512u, kPbCtx = 512u, kPtCtx = 512u;
	static constexpr uint32 kTrainEpi = 1u, kPbEpi = 2001u, kPtEpi = 5001u;
	static_assert(kPbEpi >= kTrainEpi + kNCtx, "규율 12");
	static_assert(kPtEpi >= kPbEpi + kPbCtx, "규율 12");
	static constexpr uint32 kPoolSteps = kNCtx / kBatch;
	static constexpr uint32 kPbPool = kPbCtx / kBatch, kPtPool = kPtCtx / kBatch;
	// ⭐ **회차 137 이 준 것 — 틱당 16 이면 학습이 비트 동일이다**(4·1 은 4/6 으로 갈린다).
	//   ⚠️ D4 는 아직 **못 고쳤지만** ***결정적으로 재는 법***은 찾았다 ⇒ 언어 관문을 그 위에서 뽑는다.
	//   ★ 그리고 이 하네스는 **바깥 반복 2** 를 갖고 있으므로 **`sd_run == 0`** 이 그 자리에서
	//     ***공짜 배관 관문***이 된다(다른 하네스에서 얻은 결론을 **여기서 다시 확인**한다).
	static constexpr uint32 kSteps = 800u, kPerTick = 16u;

	// ⭐ **대역 셋** — 상태 · 활성 · 앵커. 판 A 는 앵커 대역이 **전부 0** 이다.
	static constexpr uint32 kD = MLTModel::RepDim();       // 128
	// ⭐ 판이 하나(축 13)라 대역은 **둘**(상태 · 활성)이다 — 회차 99 가 앵커는 안 돕는다고 닫았다.
	static constexpr uint32 kBands = 2u;
	static constexpr uint32 kFeat = kBands * kD + 1u;      // 257
	static constexpr uint32 kCls = 3u;
	static constexpr uint32 kFitCtx = 384u;
	static constexpr uint32 kCalCtx = kPbCtx - kFitCtx;    // 128
	// ⚠️⚠️ **씨앗 수에 매인 문턱은 씨앗 수에 비례해야 한다** — 회차 121 진단이 그것을 잡았다:
	//   `kSignPass = 10` 을 **2씨앗 진단**에 그대로 걸어서 **원리적으로 통과 불가**였다(양성 대조가 그랬다).
	//   ★ ⇒ `kSeeds` 의 **10/12** 로 둔다(12씨앗이면 10 · 2씨앗이면 1).
	static constexpr uint32 kSignPass = (kSeeds * 10u + 11u) / 12u;
	static constexpr float  kUnif = 1.0986123f;
	static constexpr uint32 kBalSlack = 1u;
	static constexpr uint32 kLams = 4u;
	static constexpr float  kLamGrid[kLams] = { 0.1f, 1.0f, 10.0f, 100.0f };
	static constexpr float  kNoShape = 1.0e6f;

	// 판 둘 × 팔 둘 = 넷 · 표적 둘(0 = minDOn 표제 · 1 = yaw 양성)
	// ⭐ 판은 **하나**(축 13) · 표적은 **넷** —
	//   0 = **뜻밖임**(표제 · 과제 그 자체) · 1 = **지속 개수**(표제′ · 과제가 직접 요구) ·
	//   2 = `yaw`(양성 · 규율 16) · 3 = `minDOn`(참조 · **과제와 무관** ⇒ 5/12 재현 기대)
	// ⭐ **회차 132 — 팔 넷**(⚠️ ㈁㈂㈃ 는 축·파라미터·걸음이 **전부 같다**)
	//   ㈀ 낱말 없음(축 13) · ⭐ ㈁ `minDOn`(표제) · ⭐ ㈂ 섞은 `minDOn`(음성) · ⭐ ㈃ `뜻밖임`(양성)
	static constexpr uint32 kPlates = 1u, kArms = 4u, kTgts = 4u;
	static constexpr uint32 kSymA = MLTP3Ctx::kStateAx + kN + 1u;    // 256

	enum { kEncInit, kEncTrain, kGather, kQuiesce, kBodyInit, kBodyTrain, kEval };

	inline static MLTP2Enc _E;
	inline static MLTModel _M;
	inline static MLTP3Ctx  _trA, _pbA, _ptA;    // 판 A — 축 13
	// ⚠️ 판 B(축 29)는 **없다** — 회차 99 가 *"앵커를 줘도 몸통이 안 쓴다"*(7/12)로 닫았다.
	inline static bool _done = false, _banner = false, _encSetup = false, _finite = true;
	inline static bool _pending = false;
	inline static uint32 _seed = 0u, _st = kEncInit, _step = 0u;
	inline static uint32 _plate = 0u, _arm = 0u;
	inline static uint32 _cor = 0u, _gGrp = 0u, _gIdx = 0u, _qWait = 0u, _noShape = 0u;
	inline static Array<float> _code, _norm;

	// ⭐ 낱말 재료 — 학습 코퍼스(`_mTr`)와 시험 코퍼스(`_mPt`)의 원값 + 3분위 계급
	inline static Array<float> _mTr[kTgts], _mPb[kTgts], _mPt[kTgts];
	//   `_yTrW[0]` = 뜻밖임(양성) · `_yTrW[1]` = minDOn(표제) — 학습/시험 각각
	inline static Array<uint32> _yTrW[2], _yTeW[2];
	// ⭐ 팔마다 넓힌 풀 — [0] 학습 · [1] 시험
	inline static Array<float> _eVal[2], _eSym[2], _eTgt[2];
	inline static MLTEvalGate _gate;

	// ⭐ 바깥 반복(실행 잡음 ↔ 씨앗 잡음을 가른다 · 규율 32) — ⭐ 회차 131 이 **표제에도** 넣게 했다
	static constexpr uint32 kOut = 2u;
	inline static uint32 _out = 0u;
	inline static float _ce[kOut][kArms][kSeeds];      // ⭐ 예측 CE(프로브가 아니다)
	inline static bool  _seedOk[kSeeds], _balOk[kSeeds], _repOk[kSeeds];

	static void _ToBody() { _qWait = MLTEvalGate::kDelay; _st = kQuiesce; }
	static const char* _PlateName(uint32 p) { (void)p; return "축13"; }
	static const char* _ArmName(uint32 a)
	{
		switch (a)
		{
		case 0u: return "㈀ 상수낱말(14축)";
		case 1u: return "㈁ minDOn ⭐     ";
		case 2u: return "㈂ 섞은minDOn⛔  ";
		default: return "㈃ 뜻밖임9분위⭐ ";
		}
	}
	static const char* _TgtName(uint32 t)
	{
		switch (t)
		{
		case 0u: return "㊀ 뜻밖임(표제·과제)";
		case 1u: return "㊁ 지속개수(표제′·과제)";
		case 2u: return "㊂ yaw(양성)";
		default: return "㊃ minDOn(참조·무관)";
		}
	}

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🔄 **회차 132 · L1 ㉤ 역방향 — 낱말을 「주면」 예측이 좋아지나**(⭐ 판정 회차)\n");
		LogA("[mlt] 🔄   여태 관문은 전부 **「예측 → 언어」**(프로브)였다 — 이번엔 **낱말을 입력으로 준다**\n");
		LogA("[mlt] 🔄   ⭐ 표제 낱말 = **`minDOn`** — 모델 입력에 **없고**, 회차 126·127 에서 모델이 **못 담는다**고 측정됐다(5/12·4/12)\n");
		LogA("[mlt] 🔄   팔 넷 — ㈀ 낱말없음(13축) · ⭐ ㈁ minDOn(14축·표제) · ⭐ ㈂ 섞은 minDOn(음성) · ⭐ ㈃ 뜻밖임(양성)\n");
		LogA("[mlt] 🔄   ⚠️ ㈁㈂㈃ 는 축·파라미터·걸음이 **전부 같다** · 낱말 축 표적은 `IgnoreTgt` ⇒ **채점 대상이 같다**\n");
		LogA("[mlt] 🔄   ⭐ **낱말은 그 시각의 축 0** — 몸통이 causal 이라 맨 뒤에 두면 **예측에 안 닿는다**(1씨앗 진단이 잡았다)\n");
		LogA("[mlt] 🔄   ⭐ 자 = **이득률**(무차원) = (CE(㈀)−CE(㈁)) / (CE(㈀)−CE(㈃)) · SE 에 **실행 잡음 항** 포함(회차 131)\n");
		LogA("[mlt] 🔄   ⭐ 예측 — ㈃ 크게 도울 것 · ㈁ **진짜 모른다**(어림 0.1~0.3) · ㈂ 구별 안 될 것\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

	// ── 인코더(회차 85~98 과 같다) ───────────────────────────────────
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
		for (uint32 t = 0; t < kTgts; ++t) { _mPb[t].Reset(0); _mPt[t].Reset(0); }
		_cor = 0u; _gGrp = 0u; _gIdx = 0u; _pending = false; _st = kGather;
	}

	static uint32 _NCtxOf(uint32 c) { return (c == 0u) ? kNCtx : ((c == 1u) ? kPbCtx : kPtCtx); }
	static uint32 _EpiOf(uint32 c)  { return (c == 0u) ? kTrainEpi : ((c == 1u) ? kPbEpi : kPtEpi); }
	static MLTP3Ctx&  _CorA(uint32 c) { return (c == 0u) ? _trA : ((c == 1u) ? _pbA : _ptA); }


	// ⭐ **한 루프에서 두 코퍼스에 나란히** 넣는다 — 활성이 같아야 A/B 가 짝지어진다.
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

					if (t == kGateT)
					{
						// ㊀ `minDOn` — ⚠️ `VisibleShapes` 는 **판정 창구**다(모델 입력에 안 들어간다).
						MLTShapeView vs[MLTWorldCfg::kShapes];
						const int nv = w.VisibleShapes(vs, MLTWorldCfg::kShapes);
						const float SS = (float)MLTWorldCfg::kSide;
						float dOn = kNoShape; bool haveOn = false;
						for (int i = 0; i < nv; ++i)
						{
							if (!(vs[i].sx >= 0.0f && vs[i].sx < SS && vs[i].sy >= 0.0f && vs[i].sy < SS)) continue;
							if (!haveOn || vs[i].d < dOn) { dOn = vs[i].d; haveOn = true; }
						}
						if (!haveOn) ++_noShape;
						// ⚠️ 표적 0·1(뜻밖임·지속개수)은 **코퍼스가 다 채워진 뒤** 계산한다(주변분포가 필요하다)
						//   ⇒ 여기서는 **무관 낱말 둘**만 담는다.
						// ⭐ **회차 132 가 더한 것** — **학습 코퍼스에서도** 낱말 재료를 모은다
						//   (이전 회차들은 프로브 코퍼스만 모았다 — 그때는 낱말이 **입력**이 아니었으니까)
						if (_cor == 0u)      { _mTr[2].Add(w.State().yaw); _mTr[3].Add(dOn); }
						else if (_cor == 1u) { _mPb[2].Add(w.State().yaw); _mPb[3].Add(dOn); }
						else                 { _mPt[2].Add(w.State().yaw); _mPt[3].Add(dOn); }
					}
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
		_MakeTaskWords();
		_MakeWords();
		_plate = 0u; _arm = 0u; _ToBody();
	}

	// ── ⭐ **과제에 필요한 낱말 둘** — 코퍼스 안에서 만든다 ─────────────
	//   ㊀ **뜻밖임** = 다음 시각 표적 8개의 `−log p_marginal` 평균 ⇒ ***손실의 주항 그 자체***
	//   ㊁ **지속 개수** = 지금 활성 8개 중 **다음 시각에도 남는** 수(0..8)
	//   ⚠️⚠️ **주변분포는 「몸통 학습 코퍼스」에서만** 잡는다 — 시험을 훔쳐보지 않는다.
	//   ⚠️ 둘 다 **모델 입력이 아니다**(표적은 손실에만 들어가고 프로브 특징에는 없다).
	static void _TaskOne(const MLTP3Ctx& C, uint32 nCtx, const Array<float>& marg,
		Array<float>& outSurp, Array<float>& outKeep)
	{
		outSurp.Reset(0); outKeep.Reset(0);
		for (uint32 ctx = 0; ctx < nCtx; ++ctx)
		{
			const uint32 gb = MLTP3Ctx::Row(ctx, kGateT, kStateAx);
			double s = 0.0; uint32 keep = 0u;
			for (uint32 j = 0; j < kSlots; ++j)
			{
				// 표적 = **다음 시각의 그 슬롯 id**(코퍼스가 `Row(ctx, t, ·)` 에 적어 둔다)
				const float tf = C.Tgt()[gb + j];
				const uint32 tid = (tf >= 0.0f && tf < (float)kN) ? (uint32)tf : 0u;
				float p = marg[tid];
				if (p < 1.0e-9f) p = 1.0e-9f;
				s += -(double)Log(p);
				// 지속 = 그 표적 id 가 **지금 시각의 활성 8개** 안에 있나
				for (uint32 q = 0; q < kSlots; ++q)
					if ((uint32)(C.Sym()[gb + q] - (float)kStateAx) == tid) { ++keep; break; }
			}
			outSurp.Add((float)(s / (double)kSlots));
			outKeep.Add((float)keep);
		}
	}

	static void _MakeTaskWords()
	{
		Array<float> marg;
		_trA.Marginal(marg);          // ⭐ **몸통 학습 코퍼스**에서만
		_TaskOne(_trA, kNCtx,  marg, _mTr[0], _mTr[1]);   // ⭐ 회차 132 — 학습 코퍼스도
		_TaskOne(_pbA, kPbCtx, marg, _mPb[0], _mPb[1]);
		_TaskOne(_ptA, kPtCtx, marg, _mPt[0], _mPt[1]);
	}

	// ── 순위 계급(회차 87 · `sd = 0`) ────────────────────────────────
	static void _RankClass(const float* m, uint32 n, Array<uint32>& y) { _RankClassK(m, n, kCls, y); }

	// ⭐ 회차 139 — 계급 수를 인자로(양성 대조를 **9분위**로 올리려고)
	static void _RankClassK(const float* m, uint32 n, uint32 k, Array<uint32>& y)
	{
		y.Reset(0);
		for (uint32 i = 0; i < n; ++i) y.Add(0u);
		for (uint32 i = 0; i < n; ++i)
		{
			uint32 r = 0u;
			for (uint32 j = 0; j < n; ++j)
				if (m[j] < m[i] || (m[j] == m[i] && j < i)) ++r;
			y.Data()[i] = (r * k) / n;
		}
	}
	// ⭐ **회차 139** — 양성 대조(`뜻밖임`)를 **9분위**로 올린다.
	//   ⚠️ 3분위는 **1.58 bit** 뿐이라 «구성상 정답을 흘리는 말» 치고 **너무 약했다**(138 에서 9/12).
	//   ★ 9분위 = **3.17 bit** ⇒ 양성이 서면 자가 살아 있음이 분명해진다.
	//   ⚠️ 표제(`minDOn`)는 **3분위 그대로** 둔다 — 그것을 바꾸면 138 과 못 견준다.
	static constexpr uint32 kClsPos = 9u;
	static void _MakeWords()
	{
		_RankClassK(_mTr[0].Data(), kNCtx,  kClsPos, _yTrW[0]);   // ⭐ 양성 — 9분위
		_RankClass (_mTr[3].Data(), kNCtx,          _yTrW[1]);    // 표제 — 3분위
		_RankClassK(_mPt[0].Data(), kPtCtx, kClsPos, _yTeW[0]);
		_RankClass (_mPt[3].Data(), kPtCtx,         _yTeW[1]);
		// 균형 검사 — 세 계급이 고르게 나뉘나(자가 성립하는 전제)
		bool ok = true;
		const uint32 tgt = (kPtCtx + kCls / 2u) / kCls;
		for (uint32 w = 0; w < 2u; ++w)
		{
			uint32 cnt[kCls] = { 0u, 0u, 0u };
			for (uint32 i = 0; i < kPtCtx; ++i) ++cnt[_yTeW[w][i]];
			for (uint32 c = 0; c < kCls; ++c)
			{
				const uint32 d = (cnt[c] > tgt) ? (cnt[c] - tgt) : (tgt - cnt[c]);
				if (d > kBalSlack) ok = false;
			}
		}
		_balOk[_seed] = ok; _repOk[_seed] = true;
		LogA("[mlt] 🔄 씨앗 %2u · 낱말 균형 %s · 화면안 도형0 %u회 · minDOn 범위 %.3f~%.3f\n",
			_seed, ok ? "통과" : "⛔", _noShape, (double)_mPt[3][0], (double)_mPt[3][kPtCtx - 1u]);
	}

	// ══════════════════════════════════════════════════════════════════
	// ⭐ **회차 132 의 핵심 — 13축 코퍼스를 「낱말 축」 하나 붙여 14축으로**
	// ══════════════════════════════════════════════════════════════════
	//   ★ 코퍼스 클래스(`MLTP3Ctx`)는 **안 건드린다** — `kAxes` 가 컴파일 상수라 새 클래스를 만드는 대신
	//     **여기서 배열을 넓힌다**(순수 재배치 · 새 배관 0).
	//   ⚠️ 낱말 축의 표적은 **`IgnoreTgt`** 다 ⇒ ***채점되는 표적이 팔마다 똑같다***(회차 116 의 개수 관문).
	//   ⚠️ 심볼 id 는 **255** — 상태 0~4 · 활성 5~254 뒤의 **빈 자리**다(`kSymA = 256`).
	static constexpr uint32 kAx13 = MLTP3Ctx::kAxes;          // 13
	static constexpr uint32 kAx14 = kAx13 + 1u;               // 14
	static constexpr uint32 kCtx14 = kAx14 * kTime;           // 112
	static constexpr uint32 kRows14 = kBatch * kCtx14;        // 896
	static constexpr float  kWordSym = 255.0f;
	// ⭐ 회차 139 — 지금 팔의 계급 수(값 정규화에 쓴다)
	inline static uint32 _wordCls = 3u;

	static void _Expand(const MLTP3Ctx& C, uint32 nCtx, const Array<uint32>& word,
		Array<float>& oVal, Array<float>& oSym, Array<float>& oTgt)
	{
		const uint32 steps = nCtx / kBatch;
		const uint32 n = steps * kRows14;
		oVal.Reset(0); oSym.Reset(0); oTgt.Reset(0);
		for (uint32 i = 0; i < n; ++i) { oVal.Add(0.0f); oSym.Add(0.0f); oTgt.Add((float)kN); }
		for (uint32 ctx = 0; ctx < nCtx; ++ctx)
		{
			const uint32 k = ctx / kBatch, b = ctx % kBatch;
			for (uint32 t = 0; t < kTime; ++t)
			{
				const uint32 src = MLTP3Ctx::Row(ctx, t, 0u);
				const uint32 dst = k * kRows14 + b * kCtx14 + t * kAx14;
				// ⭐ **1씨앗 진단이 잡은 자리 — 낱말은 그 시각의 「맨 앞」이어야 한다.**
				//   ⚠️⚠️ 몸통은 **causal**(decoder-only)이고 행 순서가 `t*축 + a` 다 ⇒
				//     축 `a` 는 **자기보다 앞선 축만** 본다. 처음엔 낱말을 **축 13**(맨 뒤)에 뒀는데
				//     표적을 내는 **활성 슬롯이 축 5~12**(앞)라 ***낱말이 예측에 닿을 수가 없었다.***
				//   ⇒ 실측: 구성상 정답을 흘리는 `뜻밖임` 낱말조차 **안 도왔다**(양성 대조 ⛔).
				//   ★ 그래서 낱말을 **축 0** 에 두고 원본 13축을 **1..13 으로 민다.**
				//   ⚠️ 심볼 id 는 자리와 무관하므로(상태 축은 `_sym = a` 지만 그 값 그대로 옮긴다)
				//     이 이동은 **뜻을 하나도 안 바꾼다** — 볼 수 있게만 만든다.
				// ⚠️ **회차 139** — 계급 수가 팔마다 다르다(표제 3분위 · 양성 9분위)
				//   ⇒ 값을 **−1..+1 로 정규화**한다(안 그러면 양성 팔만 값 폭이 4배가 되어
				//     *"낱말이 도왔다"* 와 *"입력이 컸다"* 가 섞인다).
				oVal.Data()[dst] = (word.Count() > ctx)
					? (((float)word[ctx] / (float)(_wordCls - 1u)) * 2.0f - 1.0f) : 0.0f;
				oSym.Data()[dst] = kWordSym;
				oTgt.Data()[dst] = (float)kN;              // IgnoreTgt
				for (uint32 a = 0; a < kAx13; ++a)
				{
					oVal.Data()[dst + 1u + a] = C.Val()[src + a];
					oSym.Data()[dst + 1u + a] = C.Sym()[src + a];
					oTgt.Data()[dst + 1u + a] = C.Tgt()[src + a];
				}
			}
		}
	}

	// ⭐ 낱말 셋 — ㈁ `minDOn` · ㈂ 그것을 **문맥 사이에 섞은 것** · ㈃ `뜻밖임`(양성 · 새는 말)
	//   ⚠️ 섞기는 **씨앗마다 고정**이다(같은 씨앗 안에서 안 바뀐다 ⇒ 짝지음이 성립).
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

	// 팔마다 학습·시험 풀을 만든다. ⚠️ ㈀ 는 **13축 원본 그대로**(넓히지 않는다).
	// ⚠️⚠️⚠️ **회차 138 이 이 함수를 고치게 했다 — 축 개수가 교란 변수였다.**
	//   실측: **섞은 낱말(㈂)이 낱말 없음(㈀)을 이겼다**(0.88469 < 0.88911, 9/12).
	//   ⇒ ★ 그 «이득» 은 **정보가 아니라 「축이 하나 더 있다」**에서 왔다 — ㈀ 만 13축이었기 때문이다.
	//   ⇒ ⭐ **㈀ 도 14축**으로 만든다(낱말 자리에 **상수 0**) ⇒ ***네 팔이 축·파라미터·걸음이 전부 같다.***
	//   ★ 이제 갈림은 **낱말 축이 무엇을 담느냐**뿐이다(상수 / 참 / 섞음 / 새는 말).
	static void _MakeArmPools()
	{
		const uint32 a = _arm;
		Array<uint32> wTr, wTe;
		if (a == 0u)
		{
			// ⭐ ㈀ — **상수 낱말**(전부 계급 1 ⇒ 값 0). 축은 있고 **정보만 0** 이다.
			wTr.Reset(0); wTe.Reset(0);
			for (uint32 i = 0; i < kNCtx;  ++i) wTr.Add(1u);
			for (uint32 i = 0; i < kPtCtx; ++i) wTe.Add(1u);
			_wordCls = kCls;                    // ⭐ ㈀ 은 상수 1 ⇒ 정규화 뒤 값이 **0** 이다
		}
		else if (a == 3u) { wTr = _yTrW[0]; wTe = _yTeW[0]; _wordCls = kClsPos; }   // ㈃ 뜻밖임(양성 · ⭐ 9분위)
		else              { wTr = _yTrW[1]; wTe = _yTeW[1]; _wordCls = kCls; }   // ㈁·㈂ minDOn
		if (a == 2u)                                            // ㈂ 음성 — 섞는다
		{
			Array<uint32> s1, s2;
			_Shuffle(wTr, s1, 11u); _Shuffle(wTe, s2, 22u);
			wTr = s1; wTe = s2;
		}
		_Expand(_trA, kNCtx, wTr, _eVal[0], _eSym[0], _eTgt[0]);
		_Expand(_ptA, kPtCtx, wTe, _eVal[1], _eSym[1], _eTgt[1]);
	}

	// ── 몸통 ──────────────────────────────────────────────────────────
	// ⭐ **회차 139** — ***네 팔이 전부 14축***이다(㈀ 은 낱말 자리에 상수). 축 효과가 사라졌다.
	static void _BodyBegin(RHI* rhi)
	{
		if (!_M.Setup(rhi, kSymA, kN, kAx14, kTime)) { _Fail("몸통 준비"); return; }
		_MakeArmPools();
		const bool okUp = _M.UploadPool(_eVal[0], _eTgt[0], kPoolSteps)
			&& _M.UploadSymbolPool(_eSym[0], kPoolSteps);
		if (!okUp) { _Fail("학습 풀 업로드"); return; }
		_step = 0u; _st = kBodyTrain;
	}

	static void _BodyTrain()
	{
		if (_step >= kSteps)
		{
			// ⭐ 학습 끝 — **시험 코퍼스**로 갈아 끼우고 예측 CE 를 잰다(이 회차의 자).
			const bool okUp = _M.UploadPool(_eVal[1], _eTgt[1], kPtPool)
				&& _M.UploadSymbolPool(_eSym[1], kPtPool);
			if (!okUp) { _Fail("시험 풀 업로드"); return; }
			_gate.Begin(kPtPool);
			_st = kEval; return;
		}
		for (uint32 i = 0; i < kPerTick && _step < kSteps; ++i)
		{
			_M.SelectStep(_step % kPoolSteps);
			if (!_M.Forward() || !_M.Backward() || !_M.AdamStep(1.0f)) { _Fail("몸통 스텝"); return; }
			++_step;
		}
	}

	// ── 평가 — ⭐ **예측 CE**(프로브가 아니다) ────────────────────────
	static void _EvalStep()
	{
		bool fail = false;
		if (!_gate.Step(_M, fail)) return;
		if (fail) { _Fail("평가 리드백"); return; }
		const float ce = _gate.Mean();
		_ce[_out][_arm][_seed] = ce;
		if (!(ce == ce) || ce > 1.0e30f) _finite = false;
		LogA("[mlt] 🔄   %s 씨앗 %2u · 바깥 %u · **예측 CE %.5f**\n", _ArmName(_arm), _seed, _out, (double)ce);
		if (++_arm < kArms) { _ToBody(); return; }
		_arm = 0u;
		// ⭐ **회차 131 의 처방** — 실행(바깥 반복) 2회를 **표제에 넣는다**(규율 37·29)
		if (++_out < kOut) { _ToBody(); return; }
		_out = 0u;
		_seedOk[_seed] = _finite;
		++_seed; _st = kEncInit;
	}

	// ⭐ 씨앗별 CE(바깥 반복 평균) · 그리고 **실행 잡음**(바깥 반복 사이 폭)
	static double _M2(uint32 a, uint32 s)
	{
		double v = 0.0;
		for (uint32 o = 0; o < kOut; ++o) v += (double)_ce[o][a][s];
		return v / (double)kOut;
	}

	// ⭐ **회차 131 의 처방** — 짝지은 차의 SE 에 **실행 잡음 항**을 더한다(규율 29·37).
	//   `SE² = sd_씨앗²/n + sd_run²/(n·kOut)`  ⇒ 씨앗 잡음만 쓰면 회차 127 처럼 6.36 이 0.55 가 된다.
	struct Pair { double d; double se; double t; double sdSeed; double sdRun; uint32 n; uint32 win; };

	static Pair _Paired(uint32 aX, uint32 aY)
	{
		Pair p{}; p.d = 0.0; p.se = 0.0; p.t = 0.0; p.sdSeed = 0.0; p.sdRun = 0.0; p.n = 0u; p.win = 0u;
		double dv[kSeeds]; double rs = 0.0;
		for (uint32 s = 0; s < kSeeds; ++s)
		{
			if (!_seedOk[s]) continue;
			const double d = _M2(aX, s) - _M2(aY, s);
			dv[p.n] = d; p.d += d; ++p.n;
			if (d < 0.0) ++p.win;                       // ⭐ `aX` 가 더 낫다(CE 가 작다)
			// 실행 잡음 — 같은 씨앗의 바깥 반복 사이 차의 폭
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
		// ⭐ 실행 항을 넣은 SE
		const double v = (p.sdSeed * p.sdSeed) / (double)p.n
			+ (p.sdRun * p.sdRun) / ((double)p.n * (double)kOut);
		p.se = Sqrt((float)v);
		p.t = (p.se > 1.0e-12) ? (Abs(p.d) / p.se) : 0.0;
		return p;
	}

	static void _Summary()
	{
		uint32 ok = 0u;
		for (uint32 s = 0; s < kSeeds; ++s) if (_seedOk[s]) ++ok;
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🔄 **회차 132 · L1 ㉤ 역방향 — 낱말을 「주면」 예측이 좋아지나** (씨앗 %u/%u · 유한 %s)\n",
			ok, kSeeds, _finite ? "✅" : "⛔");
		LogA("[mlt] 🔄   ⚠️ 표적은 **팔마다 같다** — 낱말 축의 표적이 `IgnoreTgt` 라 채점 대상이 안 바뀐다\n");
		LogA("[mlt] 🔄   ── ① 팔별 **예측 CE**(바깥 %u 평균) ──\n", kOut);
		for (uint32 a = 0; a < kArms; ++a)
		{
			double m = 0.0; uint32 n = 0u;
			for (uint32 s = 0; s < kSeeds; ++s) { if (!_seedOk[s]) continue; m += _M2(a, s); ++n; }
			LogA("[mlt] 🔄     %s │ **%.5f** (씨앗 %u)\n", _ArmName(a), (n == 0u) ? 0.0 : m / (double)n, n);
		}

		// ── ② 짝지은 차 — ⭐ SE 에 **실행 잡음 항**이 들어 있다(회차 131 의 처방) ──
		const Pair pPos = _Paired(3u, 0u);      // ㈃ − ㈀ : 양성(반드시 음수여야)
		const Pair pNeg = _Paired(2u, 0u);      // ㈂ − ㈀ : 음성(구별 안 돼야)
		const Pair pTop = _Paired(1u, 0u);      // ⭐ ㈁ − ㈀ : 표제
		const Pair pVs  = _Paired(1u, 2u);      // ⭐ ㈁ − ㈂ : 표제(음성 대비)
		LogA("[mlt] 🔄   ── ② **짝지은 차**(음수 = 낱말이 도왔다) · ⭐ SE 에 **실행 항** 포함 ──\n");
		LogA("[mlt] 🔄     견줌        │ d̄        · sd_씨앗 · sd_run  · SE      · **|d̄|/SE** · 이긴 씨앗\n");
		LogA("[mlt] 🔄     ㈃−㈀ 양성  │ %+.5f · %.5f · %.5f · %.5f · **%6.2f** · %u/%u\n",
			pPos.d, pPos.sdSeed, pPos.sdRun, pPos.se, pPos.t, pPos.win, pPos.n);
		LogA("[mlt] 🔄     ㈂−㈀ 음성  │ %+.5f · %.5f · %.5f · %.5f · **%6.2f** · %u/%u\n",
			pNeg.d, pNeg.sdSeed, pNeg.sdRun, pNeg.se, pNeg.t, pNeg.win, pNeg.n);
		LogA("[mlt] 🔄     ⭐ ㈁−㈀ 표제 │ %+.5f · %.5f · %.5f · %.5f · **%6.2f** · %u/%u\n",
			pTop.d, pTop.sdSeed, pTop.sdRun, pTop.se, pTop.t, pTop.win, pTop.n);
		LogA("[mlt] 🔄     ⭐ ㈁−㈂ 표제 │ %+.5f · %.5f · %.5f · %.5f · **%6.2f** · %u/%u\n",
			pVs.d, pVs.sdSeed, pVs.sdRun, pVs.se, pVs.t, pVs.win, pVs.n);

		// ── ③ ⭐ 무차원 이득률(규율 31) ──────────────────────────────
		//   `이득률 = (CE(㈀) − CE(㈁)) / (CE(㈀) − CE(㈃))` — 양성 대조의 이득이 **눈금**이다.
		const double gain = (Abs((float)pPos.d) > 1.0e-9) ? (pTop.d / pPos.d) : 0.0;
		LogA("[mlt] 🔄   ── ③ ⭐ **이득률**(무차원 · 규율 31) = ㈁이득 / ㈃이득 = **%+.3f**\n", gain);
		LogA("[mlt] 🔄     ★ 0 = 전혀 안 도움 · 1 = **새는 말만큼** 도움\n");

		// ── 관문 ────────────────────────────────────────────────────
		const bool gPos = (pPos.win >= kSignPass) && (pPos.d < 0.0);
		// ⚠️⚠️ **1씨앗 진단이 이 관문의 오류 둘을 잡았다**:
		//   ㉠ **방향을 안 봤다** — 묻는 것은 *"섞은 낱말이 **돕는가**"* 이므로 `d < 0`(도움)일 때만 ⛔ 다.
		//      실측에서 `d = +0.00064`(오히려 **나쁘다**)인데 ⛔ 를 찍었다.
		//   ㉡ **씨앗 수에 안 매어 뒀다** — 1씨앗은 `sd_씨앗 = 0` 이라 SE 가 0 에 붙고 `|d̄|/SE` 가
		//      **153** 으로 폭발한다(회차 121·125·126·128 이 밟은 그 함정의 또 다른 얼굴).
		const bool negApply = (kSeeds >= 3u);
		const bool gNeg = !negApply || !(pNeg.d < 0.0 && pNeg.t >= 3.0);
		const bool gTop = (pTop.win >= kSignPass) && (pTop.d < 0.0) && (pVs.t >= 3.0) && (pVs.d < 0.0);
		// ⭐ **회차 138 이 더한 배관 관문 — 자가 결정적인가**
		//   회차 137 이 *"틱당 16 이면 학습이 비트 동일"* 을 냈다. ⚠️ 그건 **다른 하네스**의 결론이므로
		//   ★ **여기서 다시 확인한다**: 바깥 반복 둘의 CE 가 같으면 `sd_run = 0` 이다.
		//   ⇒ 0 이면 ⭐ ***이 회차의 자는 완벽하다***(실행 잡음 항이 0 이라 SE 가 씨앗 잡음만 담는다).
		double runSum = 0.0; uint32 runN = 0u; uint32 runZero = 0u;
		for (uint32 s = 0; s < kSeeds; ++s)
		{
			if (!_seedOk[s]) continue;
			for (uint32 a = 0; a < kArms; ++a)
			{
				const double d = Abs((float)((double)_ce[1][a][s] - (double)_ce[0][a][s]));
				runSum += d; ++runN; if (d == 0.0) ++runZero;
			}
		}
		const bool detOk = (runN > 0u) && (runZero == runN);
		LogA("[mlt] 🔄   ── ⭐ **자가 결정적인가**(틱당 %u · 바깥 반복 둘이 비트 동일인가) ──\n", kPerTick);
		LogA("[mlt] 🔄     비트 동일 **%u/%u** · 평균 |Δ| **%.3e** → %s\n",
			runZero, runN, (runN == 0u) ? 0.0 : runSum / (double)runN,
			detOk ? "✅ ***자가 완벽하다***(회차 137 의 결론이 여기서도 선다)"
			      : "⚠️ **아직 흔들린다** — SE 의 실행 항이 살아 있다(규율 29)");

		LogA("[mlt] 🔄   ── 관문 ──\n");
		LogA("[mlt] 🔄     ⭐ **양성**(㈃ 가 ㈀ 보다 낫다) — %u/%u ≥%u → %s\n",
			pPos.win, pPos.n, kSignPass, gPos ? "✅" : "⛔ **자가 죽었다**");
		LogA("[mlt] 🔄     ⭐ **음성**(㈂ 가 ㈀ 를 **돕지 않아야**) — d̄ %+.5f · |d̄|/SE **%.2f** → %s\n",
			pNeg.d, pNeg.t, !negApply ? "⚠️ 건너뜀(씨앗 3 이상에서만 유효)"
				: (gNeg ? "✅ 안 돕는다" : "⛔ **섞은 낱말도 돕는다 = 자가 죽었다**"));
		LogA("[mlt] 🔄     ⭐ **표제**(㈁<㈀ %u/%u 그리고 ㈁<㈂ |d̄|/SE %.2f≥3) → %s\n",
			pTop.win, pTop.n, pVs.t, gTop ? "✅" : "⛔");

		// ── 판정 ────────────────────────────────────────────────────
		if (!_finite || ok < kSeeds)
			LogA("[mlt] 🔄   ⭐ 판정 = ⛔ **판정불가** — 배관이 안 섰다\n");
		else if (!gPos)
			LogA("[mlt] 🔄   ⭐ 판정 = ⛔ **판정불가** — ***양성 대조가 안 선다***\n"
			     "[mlt] 🔄      ⇒ ⚠️ 구성상 정답을 흘리는 낱말(㈃)조차 안 도우면 **낱말 축 자체가 안 읽힌다**\n");
		else if (!gNeg)
			LogA("[mlt] 🔄   ⭐ 판정 = ⛔ **판정불가** — **섞은 낱말도 돕는다** ⇒ 이득이 **정보가 아니라 축**에서 온다\n");
		else if (gTop)
			LogA("[mlt] 🔄   ⭐ 판정 = ⭐ ***낱말을 주면 예측이 좋아진다*** — **L1 ㉤(역방향) 통과**\n"
			     "[mlt] 🔄      ⇒ ★ 이득률 %+.3f — 새는 말의 **%.0f%%** 만큼 돕는다\n", gain, 100.0 * gain);
		else
			LogA("[mlt] 🔄   ⭐ 판정 = ⛔ **㉤ 실패** — `minDOn` 낱말이 예측을 **안 바꾼다**\n"
			     "[mlt] 🔄      ⇒ ⚠️⚠️ 이것은 *\"언어가 안 돕는다\"* 가 **아니다** — ***그 낱말이 이 과제와 무관***일 수 있다\n"
			     "[mlt] 🔄      ⇒ ★ 다음은 **과제와 이어진 낱말**(새지 않으면서 예측에 쓸모 있는 것)을 찾는 회차다\n");
		LogA("[mlt] 🔄   ⚠️ 문맥 학습 %u · 시험 %u · 800걸음 — 절대 성능으로 인용하지 않는다\n", kNCtx, kPtCtx);
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		_E.Destroy(); _done = true;
	}

	static void _Fail(const char* why)
	{
		LogA("[mlt] 🔄 ⛔ %s (씨앗 %u · 팔 %u · 바깥 %u · 단계 %u · 코퍼스 %u · 걸음 %u)\n",
			why, _seed, _arm, _out, _st, _cor, _step);
		_E.Destroy(); _done = true;
	}

	CW_BODY(MLTL1B0)
};
