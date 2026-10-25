// mltl0a0.cw — 🐣 회차 86 · **L0 — 얼린 표현에 선형 프로브** (`-mltl0a0`) ⭐ **L 단계의 첫 파일**
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 86 이다.** ⭐ **하네스보다 먼저 썼다.**
//
// ⛔ **먼저 고친 것** — 회차 85 보고에서 *"86(말 배관) → 87(L0 판정)"* 이라 적었는데 **틀렸다.**
//   **L0 은 낱말을 컨텍스트에 넣지 않는다** — 얼린 은닉에 선형 사상을 붙여 낱말을 **뽑는** 것이다.
//   낱말이 **입력**으로 들어가는 것은 **L1**(언어 헤드)부터다. ⇒ ⭐ **L0 은 한 회차다.**
//
// ── ⭐ 무엇을 묻나 ──────────────────────────────────────────────────────────
//   `MLT.md` 의 🐣 표 그대로다:
//     프로브가 **된다**   ⇒ 표현이 **언어 없이 이미** 그 구분을 갖고 있었다
//                          ⇒ ⭐ **언어는 가리키는 것이고 앵커가 아니다**
//     프로브가 **안 된다** ⇒ 그 구분은 언어를 붙이면서 **생긴** 것이다 ⇒ ⛔ 언어 귀속
//
// ── ② 낱말 셋 = **「내 회전 속도」** = `|act.dYaw|` 의 3분위 ────────────────
//   정본의 예시(`빠르게`·`느리게`·`멈춤`)를 이 세계의 말로 옮긴 것 —
//   **`거의 안 돈다` / `조금 돈다` / `많이 돈다`**.
//
//   ★ 세계를 읽고 고른 근거 넷:
//     · `kHoldMid = 5` · `kTime = 8` ⇒ 한 문맥 안에 행동이 **딱 둘**(`act(0)` 이 t=0~4 ·
//       **`act(5)` 가 t=5,6,7**) ⇒ 저장된 상태의 **마지막 세 증분이 전부 같은 값**이라 신호가 깨끗하다.
//     · ⚠️⚠️ **`dYaw` 는 모델 입력에 없다** — P3 코퍼스는 `ACT` 대역이 없다(그것은 P4 다).
//       모델은 **결과(`yaw` 값)만** 봤고 **원인(회전율)은 한 번도 본 적이 없다.**
//       ⇒ ***그것이 접지 시험의 전제다.***
//     · 도형이 **고리** 위에 있어 `yaw` 가 시야를 가장 크게 바꾼다 ⇒ P3 과제가 실제로 이것을 쓴다.
//     · `dYaw = Unit(h)·0.6`, `Unit ∈ [−1,1)` ⇒ `|dYaw| ~ U[0, 0.6)` ⇒ **3분위가 균형이 맞는다**.
//
//   ⏸️ **도형 종류(찬 원·찬 사각·빈 원)는 미룬다** — 한 프레임에 도형이 여럿이라 *"어느 도형인가"* 를
//     **우리가** 골라야 한다. 그 선택 자체가 손제작이다(mltconcept.md 「축 이름은 주지 않는다」).
//
// ── ③ ⭐ 진짜 자는 **「학습 안 한 몸통」**(㈁) ─────────────────────────────
//   ⚠️ **균등 바닥(`ln3`)만 넘는 것은 아무 말도 아니다** — 무작위 몸통도 잔차 흐름으로 입력을 그대로
//     나르므로 넘는다. **회차 61 이 가르친 그 자리다**(무작위 0.1966 ↔ 학습 0.2136 으로 뒤집혔다).
//   ★ 그리고 이 판은 **짝지음이 완벽하다** — `MLTModel::_InitParams` 는 씨앗을 안 쓰므로
//     ㈀ 과 ㈁ 은 **정확히 같은 초기 가중치**에서 출발하고 **학습 여부만** 다르다.
//   ★ 그래서 **「원시 입력 팔」을 두지 않는다** — ㈁ 이 이미 **차원이 맞는 채로**(둘 다 D=128)
//     같은 질문을 한다. 차원이 다르면 릿지 비교가 불공정해진다(과적합 여지가 갈린다).
//
// ── ④ 읽는 자리 = **문맥의 마지막 행** ────────────────────────────────────
//   ⚠️ *"yaw 슬롯 행을 읽자"* 는 **우리가 어디를 볼지 정하는 것** = 손제작이다.
//   인과 마스크상 전부 본 자리인 **마지막 행**(t=kTime−1 · a=kAxes−1)으로 **고정**한다.
//   ★ yaw 행은 **부산물로만** 찍고 **결과를 보고 바꾸지 않는다.**(같은 `ReadRep` 에 이미 들어 있어 공짜다)
//
// ── ⑤ 잡음 바닥 — **먼저 계산했다**(규율 9) ───────────────────────────────
//   · 균등 3분류 CE = **`ln 3 = 1.0986`**
//   · 부호검정 12씨앗 `≥10/12` ⇒ `p = (66+12+1)/4096 = 0.0193` · 표제 **둘** 본페로니
//     ⇒ **`Q = 0.0386` < 0.05** ✅
//   · 릿지 `λ = 1e-2 × trace(XᵀX)/kFeat` — ⭐ **상대**다(규율 10) · **프로브 학습 분할에서만** 계산
//   · λ×0.1 · λ×10 의 CE 도 찍어 **부호가 뒤집히나** 본다(부산물 · 문턱 아님)
//
//   ⚠️⚠️ **원핫 릿지의 출력을 그대로 softmax 에 넣으면 CE 가 늘 `ln3` 근처다**(값이 [0,1] 대라
//     분포가 납작하다) ⇒ **온도 `τ` 하나를 붙인다.** ★ `τ` 는 **프로브 학습 분할에서만** 고르고
//     두 팔에 **같은 절차**를 쓴다(시험을 훔쳐보지 않는다).
//
// ── ⑥ 분리 **셋** — `static_assert` 가 강제한다(규율 12) ──────────────────
//     몸통 학습     1 ~  512
//     프로브 학습 2001 ~ 2512
//     프로브 시험 5001 ~ 5512
//
// ── ⑦ 관문 ────────────────────────────────────────────────────────────────
//   **배관**(⚠️ 실패하면 **판정불가** · 표제를 읽지 않는다)
//     ㈃ **클래스 균형** — 세 낱말의 **시험** 표본이 각각 `33.3% ± 3%p`
//     ㈄ **얼림/재현** — 프로브 시험 표현을 **두 번** 모아 **비트 동일**
//        (⭐ *"얼렸다"* 를 **주장이 아니라 측정으로** · 회차 53·54 가 밟은 리드백 경합을 같이 막는다)
//   **표제**
//     **표제① `CE(㈀) < ln3`** — `≥10/12`
//     **표제② ⭐ `CE(㈀) < CE(㈁)`** — `≥10/12` ← ***이것이 L0 다***
//     연속량(규율 5): **`CE(㈁) − CE(㈀)` 의 크기**를 적는다(부호만 세지 않는다)
//
// ── ⑧ ⭐ 예측을 미리 적었다 ───────────────────────────────────────────────
//   · 표제① **12/12** · 표제② **≥10/12**(근거: ㉡′ 가 12/12 로 섰다 ⇒ 몸통이 시간을 섞는다)
//   · ⚠️ 반대 가능성: 다주파 사인의 저주파가 값에 거의 선형이면 `yaw[7]−yaw[6]` 이
//     **무작위 몸통에서도** 선형으로 읽힌다 ⇒ 그러면 **5~7/12** 로 떨어진다.
// ══════════════════════════════════════════════════════════════════════════════

using namespace PE;

class MLTL0A0
{
public:
	static void Tick(RHI* rhi)
	{
		if (_done || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltl0a0"))
		{
			LogA("[mlt] 🐣 회차 86(L0 선형 프로브)은 **꺼져 있다**(`-mltl0a0`)\n");
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
		_RepStep();
	}

	static bool Done() { return _done; }

private:
	// ── 규모 ──────────────────────────────────────────────────────────
	static constexpr uint32 kSeeds = 12u;
	static constexpr uint32 kEncF = 32u, kEncSteps = 1200u, kEncPerTick = 8u;
	static constexpr uint32 kN = 250u, kLocal = 8u;
	static constexpr uint32 kTime  = MLTP3Ctx::kTime;    // 8
	static constexpr uint32 kBatch = MLTP3Ctx::kBatch;   // 8
	static constexpr uint32 kAx    = MLTP3Ctx::kAxes;    // 13
	static constexpr uint32 kCtxLen = MLTP3Ctx::kCtx;    // 104
	static constexpr uint32 kCandidates = MLTP2Cfg::kPatches * kLocal;
	static constexpr uint32 kGroup = kEncF / kTime;      // 4

	// ── ⑥ 분리 셋 ────────────────────────────────────────────────────
	static constexpr uint32 kNCtx = 512u;        // 몸통 학습(회차 84 가 세운 수)
	static constexpr uint32 kPbCtx = 512u;       // 프로브 **학습**
	static constexpr uint32 kPtCtx = 512u;       // 프로브 **시험**
	static constexpr uint32 kTrainEpi = 1u, kPbEpi = 2001u, kPtEpi = 5001u;
	static_assert(kPbEpi >= kTrainEpi + kNCtx,
		"프로브 학습이 몸통 학습과 겹친다 — kPbEpi >= kTrainEpi + kNCtx 여야 한다(규율 12)");
	static_assert(kPtEpi >= kPbEpi + kPbCtx,
		"프로브 시험이 프로브 학습과 겹친다 — kPtEpi >= kPbEpi + kPbCtx 여야 한다(규율 12)");

	static constexpr uint32 kPoolSteps = kNCtx / kBatch;
	static constexpr uint32 kPbPool = kPbCtx / kBatch, kPtPool = kPtCtx / kBatch;
	static constexpr uint32 kSteps = 800u, kPerTick = 4u;

	// ── 프로브 ────────────────────────────────────────────────────────
	static constexpr uint32 kD    = MLTModel::RepDim();  // 128
	static constexpr uint32 kFeat = kD + 1u;             // + 편향
	static constexpr uint32 kCls  = 3u;
	static constexpr uint32 kViews = 2u;                 // 0 = 마지막 행(관문) · 1 = yaw 행(부산물)
	static constexpr uint32 kArms = 2u;                  // ㈀ 학습 몸통 · ㈁ 무작위 몸통
	static constexpr uint32 kSignPass = 10u;
	static constexpr float  kLamRel = 1.0e-2f;
	static constexpr float  kBalTol = 0.03f;             // ±3%p
	static constexpr float  kUnif = 1.0986123f;          // ln 3

	static constexpr uint32 kNone = MLTP3Ctx::kStateAx + kN;
	static constexpr uint32 kSymVocab = kNone + 1u;

	// 읽는 행 — ⚠️ **문맥 안 오프셋**이다(`b * kCtxLen` 을 더해 쓴다).
	static constexpr uint32 kRowGate = (kTime - 1u) * kAx + (kAx - 1u);   // 103 = 마지막 행
	static constexpr uint32 kRowYaw  = (kTime - 1u) * kAx + 3u;           //  94 = yaw 슬롯

	enum { kEncInit, kEncTrain, kGather, kQuiesce, kBodyInit, kBodyTrain, kRep };

	inline static MLTP2Enc _E;
	inline static MLTModel _M;
	inline static MLTP3Ctx _tr, _pb, _pt;
	inline static bool _done = false, _banner = false, _encSetup = false, _finite = true;
	inline static bool _pending = false;
	inline static uint32 _seed = 0u, _st = kEncInit, _step = 0u, _arm = 0u;
	inline static uint32 _cor = 0u, _gGrp = 0u, _gIdx = 0u, _qWait = 0u;
	inline static Array<float> _code, _norm;

	// 특징 — `(view * nCtx + ctx) * kFeat`
	inline static Array<float> _fPb, _fPt, _fPt2;
	// 낱말 — `|dYaw|` 원값과 그 3분위 계급
	inline static Array<float> _mPb, _mPt;
	inline static Array<uint32> _yPb, _yPt;
	inline static float _thr1 = 0.0f, _thr2 = 0.0f;

	// 결과
	inline static float _ce[kArms][kSeeds];              // 관문 뷰 · λ×1
	inline static float _ceLo[kArms][kSeeds], _ceHi[kArms][kSeeds];
	inline static float _ceYaw[kArms][kSeeds];           // 부산물 뷰
	inline static float _acc[kArms][kSeeds];
	inline static bool  _seedOk[kSeeds], _balOk[kSeeds], _repOk[kSeeds];
	inline static float _bal[kSeeds][kCls];

	// 표현 모으기 상태
	inline static uint32 _rw = 0u, _ri = 0u, _rwait = 0u;
	inline static bool   _rpend = false;

	static void _ToBody() { _qWait = MLTEvalGate::kDelay; _st = kQuiesce; }
	static const char* _ArmName() { return (_arm == 0u) ? "㈀ 학습 몸통" : "㈁ 무작위 몸통"; }

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🐣 **회차 86 · L0 — 얼린 표현에 선형 프로브**(⭐ 이 트랙의 핵심 판정 · L 단계 첫 회차)\n");
		LogA("[mlt] 🐣   낱말 셋 = **내 회전 속도** `|act.dYaw|` 3분위(거의 안 돈다 · 조금 · 많이)\n");
		LogA("[mlt] 🐣   ⚠️ `dYaw` 는 **모델 입력에 없다** — 결과(yaw 값)만 봤고 원인은 한 번도 못 봤다\n");
		LogA("[mlt] 🐣   팔 둘 — **㈀ 학습 몸통** ↔ **㈁ 무작위 몸통**(⭐ 초기 가중치가 **같다**. 학습 여부만 다르다)\n");
		LogA("[mlt] 🐣   읽는 자리 = **문맥 마지막 행**(관문) · yaw 행은 **부산물만**\n");
		LogA("[mlt] 🐣   분리 셋 — 몸통 %u~%u · 프로브학습 %u~%u · 프로브시험 %u~%u\n",
			kTrainEpi, kTrainEpi + kNCtx - 1u, kPbEpi, kPbEpi + kPbCtx - 1u, kPtEpi, kPtEpi + kPtCtx - 1u);
		LogA("[mlt] 🐣   잡음 바닥 — 균등 CE **%.4f**(ln3) · 부호검정 %u/12 ⇒ p=0.0193 · 본페로니 **Q=0.0386**\n",
			(double)kUnif, kSignPass);
		LogA("[mlt] 🐣   ⭐ **예측** — 표제① 12/12 · 표제② ≥10/12(⚠️ 무작위 몸통도 값을 나르면 5~7/12 로 떨어진다)\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

	// ── 인코더(회차 85 와 같다) ──────────────────────────────────────
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
		_tr.SetSortById(true); _pb.SetSortById(true); _pt.SetSortById(true);
		_tr.Begin(kNCtx, kN); _pb.Begin(kPbCtx, kN); _pt.Begin(kPtCtx, kN);
		_mPb.Reset(0); _mPt.Reset(0);
		_cor = 0u; _gGrp = 0u; _gIdx = 0u; _pending = false; _st = kGather;
	}

	static uint32 _NCtxOf(uint32 c) { return (c == 0u) ? kNCtx : ((c == 1u) ? kPbCtx : kPtCtx); }
	static uint32 _EpiOf(uint32 c)  { return (c == 0u) ? kTrainEpi : ((c == 1u) ? kPbEpi : kPtEpi); }
	static MLTP3Ctx& _CorOf(uint32 c) { return (c == 0u) ? _tr : ((c == 1u) ? _pb : _pt); }

	// ── 세 코퍼스를 모은다. ⭐ **낱말도 여기서 만든다**(세계를 손에 쥔 유일한 자리) ────
	static void _Gather()
	{
		MLTP3Ctx& C = _CorOf(_cor);
		const uint32 nCtx = _NCtxOf(_cor);
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
			const uint32 epi = _EpiOf(_cor);
			for (uint32 g = 0; g < kGroup; ++g)
			{
				const uint32 ctx = _gGrp * kGroup + g;
				MLTWorld w; w.Reset(_seed, epi + ctx, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
				// ⭐ **낱말의 원값** — ⚠️ `ActAt` 은 `_hold` 규약을 **포함한다**(하네스가 흉내내지 않는다).
				//   저장 상태 `t` 는 세계 스텝 `t` 의 행동으로 나아간 결과다 ⇒ 마지막 행의 원인은 `ActAt(kTime-1)`.
				if (_cor == 1u) _mPb.Add(Abs(w.ActAt(kTime - 1u).dYaw));
				else if (_cor == 2u) _mPt.Add(Abs(w.ActAt(kTime - 1u).dYaw));
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
		if (++_gGrp * kGroup < nCtx) return;
		_gGrp = 0u;
		if (++_cor < 3u) return;
		_MakeWords();
		_arm = 0u; _ToBody();
	}

	// ── 3분위 문턱은 **프로브 학습 분할에서만** 잡는다(시험을 훔쳐보지 않는다) ────
	static float _Quantile(const float* m, uint32 n, float frac)
	{
		float lo = 0.0f, hi = 1.0f;
		const uint32 want = (uint32)((double)n * (double)frac + 0.5);
		for (int it = 0; it < 50; ++it)
		{
			const float mid = 0.5f * (lo + hi);
			uint32 c = 0u;
			for (uint32 i = 0; i < n; ++i) if (m[i] < mid) ++c;
			if (c < want) lo = mid; else hi = mid;
		}
		return 0.5f * (lo + hi);
	}

	static uint32 _ClassOf(float m) { return (m < _thr1) ? 0u : ((m < _thr2) ? 1u : 2u); }

	static void _MakeWords()
	{
		_thr1 = _Quantile(_mPb.Data(), kPbCtx, 1.0f / 3.0f);
		_thr2 = _Quantile(_mPb.Data(), kPbCtx, 2.0f / 3.0f);
		_yPb.Reset(0); _yPt.Reset(0);
		for (uint32 i = 0; i < kPbCtx; ++i) _yPb.Add(_ClassOf(_mPb[i]));
		uint32 cnt[kCls] = { 0u, 0u, 0u };
		for (uint32 i = 0; i < kPtCtx; ++i) { const uint32 c = _ClassOf(_mPt[i]); _yPt.Add(c); ++cnt[c]; }
		bool ok = true;
		for (uint32 c = 0; c < kCls; ++c)
		{
			_bal[_seed][c] = (float)cnt[c] / (float)kPtCtx;
			if (Abs(_bal[_seed][c] - (1.0f / 3.0f)) > kBalTol) ok = false;
		}
		_balOk[_seed] = ok;
		LogA("[mlt] 🐣 씨앗 %2u · 낱말 문턱 **%.4f / %.4f** · 시험 균형 %.1f%% / %.1f%% / %.1f%% → %s\n",
			_seed, (double)_thr1, (double)_thr2,
			100.0 * (double)_bal[_seed][0], 100.0 * (double)_bal[_seed][1], 100.0 * (double)_bal[_seed][2],
			ok ? "통과" : "⛔");
	}

	// ── 몸통 ──────────────────────────────────────────────────────────
	static void _BodyBegin(RHI* rhi)
	{
		// ⚠️ `Setup` 이 파라미터를 다시 초기화한다 — ⭐ 씨앗을 안 쓰므로 **두 팔의 시작이 같다**.
		if (!_M.Setup(rhi, kSymVocab, kN, kAx, kTime)) { _Fail("몸통 준비"); return; }
		if (_arm == 1u) { _RepBegin(0u); return; }        // ㈁ = 학습 0
		if (!_M.UploadPool(_tr.Val(), _tr.Tgt(), kPoolSteps) || !_M.UploadSymbolPool(_tr.Sym(), kPoolSteps))
		{ _Fail("학습 풀 업로드"); return; }
		_step = 0u; _st = kBodyTrain;
	}

	static void _BodyTrain()
	{
		if (_step >= kSteps) { _RepBegin(0u); return; }
		for (uint32 i = 0; i < kPerTick && _step < kSteps; ++i)
		{
			_M.SelectStep(_step % kPoolSteps);
			if (!_M.Forward() || !_M.Backward() || !_M.AdamStep(1.0f)) { _Fail("몸통 스텝"); return; }
			++_step;
		}
	}

	// ── 표현 모으기 — `_rw` 0=프로브학습 · 1=프로브시험① · 2=프로브시험②(재현 검사) ────
	static Array<float>& _FeatOf(uint32 rw) { return (rw == 0u) ? _fPb : ((rw == 1u) ? _fPt : _fPt2); }
	static uint32 _FeatCtx(uint32 rw) { return (rw == 0u) ? kPbCtx : kPtCtx; }

	static void _RepBegin(uint32 rw)
	{
		_rw = rw; _ri = 0u; _rpend = false; _rwait = 0u;
		const MLTP3Ctx& C = (rw == 0u) ? _pb : _pt;
		const uint32 nPool = (rw == 0u) ? kPbPool : kPtPool;
		if (!_M.UploadPool(C.Val(), C.Tgt(), nPool) || !_M.UploadSymbolPool(C.Sym(), nPool))
		{ _Fail("프로브 풀 업로드"); return; }
		Array<float>& F = _FeatOf(rw);
		F.Reset(0);
		const uint32 need = kViews * _FeatCtx(rw) * kFeat;
		for (uint32 i = 0; i < need; ++i) F.Add(0.0f);
		_st = kRep;
	}

	static void _RepStep()
	{
		if (_rpend)
		{
			if (_rwait > 0u) { --_rwait; return; }
			Array<float> rep;
			if (!_M.ReadRep(rep)) { _Fail("표현 리드백"); return; }
			Array<float>& F = _FeatOf(_rw);
			const uint32 nCtx = _FeatCtx(_rw);
			for (uint32 b = 0; b < kBatch; ++b)
			{
				const uint32 ctx = (_ri - 1u) * kBatch + b;
				for (uint32 v = 0; v < kViews; ++v)
				{
					const uint32 r = b * kCtxLen + ((v == 0u) ? kRowGate : kRowYaw);
					float* dst = F.Data() + ((uint64)v * nCtx + ctx) * kFeat;
					for (uint32 d = 0; d < kD; ++d)
					{
						const float x = rep[(uint64)r * kD + d];
						if (!(x == x) || Abs(x) > 1.0e30f) _finite = false;
						dst[d] = x;
					}
					dst[kD] = 1.0f;                  // 편향
				}
			}
			_rpend = false;
		}
		const uint32 nPool = (_rw == 0u) ? kPbPool : kPtPool;
		if (_ri >= nPool) { _RepDone(); return; }
		_M.SelectStep(_ri);
		if (!_M.Forward()) { _Fail("표현 forward"); return; }
		++_ri; _rpend = true; _rwait = MLTEvalGate::kDelay;
	}

	static void _RepDone()
	{
		if (_rw == 0u) { _RepBegin(1u); return; }
		if (_rw == 1u) { _RepBegin(2u); return; }
		// ㈄ 재현 — 프로브 시험 표현이 **비트 동일**인가
		bool same = true;
		const uint32 n = kViews * kPtCtx * kFeat;
		for (uint32 i = 0; i < n; ++i) if (_fPt[i] != _fPt2[i]) { same = false; break; }
		if (_arm == 0u) _repOk[_seed] = same; else _repOk[_seed] = _repOk[_seed] && same;
		_Judge();
	}

	// ── 선형 프로브 — 원핫 릿지 + 온도 하나 ──────────────────────────
	inline static Array<float> _A, _B, _W;

	static bool _Fit(uint32 view, float lamScale, float* W)
	{
		const float* X = _fPb.Data() + (uint64)view * kPbCtx * kFeat;
		_A.Reset(0); _B.Reset(0);
		for (uint32 i = 0; i < kFeat * kFeat; ++i) _A.Add(0.0f);
		for (uint32 i = 0; i < kFeat * kCls; ++i) _B.Add(0.0f);
		float* A = _A.Data(); float* B = _B.Data();
		for (uint32 i = 0; i < kPbCtx; ++i)
		{
			const float* x = X + (uint64)i * kFeat;
			for (uint32 j = 0; j < kFeat; ++j)
			{
				const float xj = x[j];
				if (xj == 0.0f) continue;
				float* row = A + (uint64)j * kFeat;
				for (uint32 k = 0; k <= j; ++k) row[k] += xj * x[k];
				B[(uint64)j * kCls + _yPb[i]] += xj;
			}
		}
		for (uint32 j = 0; j < kFeat; ++j)               // 위삼각을 채운다(대칭)
			for (uint32 k = 0; k < j; ++k) A[(uint64)k * kFeat + j] = A[(uint64)j * kFeat + k];
		double tr = 0.0;
		for (uint32 j = 0; j < kFeat; ++j) tr += (double)A[(uint64)j * kFeat + j];
		const float lam = (float)((double)kLamRel * (double)lamScale * tr / (double)kFeat);
		for (uint32 j = 0; j < kFeat; ++j) A[(uint64)j * kFeat + j] += lam;
		if (!SolveSymPD(A, B, kFeat, kCls)) return false;
		for (uint32 i = 0; i < kFeat * kCls; ++i) W[i] = B[i];
		return true;
	}

	static double _Ce(const float* X, const uint32* y, uint32 n, const float* W, float tau, uint32* hit)
	{
		double s = 0.0; uint32 h = 0u;
		for (uint32 i = 0; i < n; ++i)
		{
			const float* x = X + (uint64)i * kFeat;
			double z[kCls]; double mx = -1.0e30; uint32 arg = 0u;
			for (uint32 c = 0; c < kCls; ++c)
			{
				double v = 0.0;
				for (uint32 j = 0; j < kFeat; ++j) v += (double)x[j] * (double)W[(uint64)j * kCls + c];
				z[c] = v * (double)tau;
				if (z[c] > mx) { mx = z[c]; arg = c; }
			}
			double se = 0.0;
			for (uint32 c = 0; c < kCls; ++c) se += (double)Exp((float)(z[c] - mx));
			s += (mx + (double)Log((float)se)) - z[y[i]];
			if (arg == y[i]) ++h;
		}
		if (hit != nullptr) *hit = h;
		return (n == 0u) ? 0.0 : (s / (double)n);
	}

	// ⚠️ **온도는 프로브 학습 분할에서만 고른다** — 거친 격자 뒤 한 번 세밀화(결정적).
	static float _FitTau(uint32 view, const float* W)
	{
		const float* X = _fPb.Data() + (uint64)view * kPbCtx * kFeat;
		float best = 1.0f; double bce = 1.0e30;
		for (int k = -8; k <= 24; ++k)
		{
			const float tau = Pow(2.0f, (float)k * 0.5f);
			const double ce = _Ce(X, _yPb.Data(), kPbCtx, W, tau, nullptr);
			if (ce < bce) { bce = ce; best = tau; }
		}
		const float lo = best * 0.5f, hi = best * 2.0f;
		for (int k = 0; k <= 16; ++k)
		{
			const float tau = lo + (hi - lo) * ((float)k / 16.0f);
			const double ce = _Ce(X, _yPb.Data(), kPbCtx, W, tau, nullptr);
			if (ce < bce) { bce = ce; best = tau; }
		}
		return best;
	}

	static bool _Probe(uint32 view, float lamScale, float& ceOut, float& accOut)
	{
		_W.Reset(0);
		for (uint32 i = 0; i < kFeat * kCls; ++i) _W.Add(0.0f);
		if (!_Fit(view, lamScale, _W.Data())) return false;
		const float tau = _FitTau(view, _W.Data());
		const float* Xt = _fPt.Data() + (uint64)view * kPtCtx * kFeat;
		uint32 hit = 0u;
		ceOut = (float)_Ce(Xt, _yPt.Data(), kPtCtx, _W.Data(), tau, &hit);
		accOut = (float)hit / (float)kPtCtx;
		return true;
	}

	static void _Judge()
	{
		float acc = 0.0f, dummy = 0.0f;
		if (!_Probe(0u, 1.0f,  _ce[_arm][_seed],   acc))     { _Fail("프로브(관문 λ×1)"); return; }
		if (!_Probe(0u, 0.1f,  _ceLo[_arm][_seed], dummy))   { _Fail("프로브(λ×0.1)"); return; }
		if (!_Probe(0u, 10.0f, _ceHi[_arm][_seed], dummy))   { _Fail("프로브(λ×10)"); return; }
		if (!_Probe(1u, 1.0f,  _ceYaw[_arm][_seed], dummy))  { _Fail("프로브(yaw 행)"); return; }
		_acc[_arm][_seed] = acc;
		LogA("[mlt] 🐣   %s 씨앗 %2u · 프로브 CE **%.5f**(정확도 %.1f%% · yaw행 %.5f · λ×0.1 %.5f · λ×10 %.5f)\n",
			_ArmName(), _seed, (double)_ce[_arm][_seed], 100.0 * (double)acc,
			(double)_ceYaw[_arm][_seed], (double)_ceLo[_arm][_seed], (double)_ceHi[_arm][_seed]);
		if (++_arm < kArms) { _ToBody(); return; }
		_seedOk[_seed] = _finite;
		++_seed; _st = kEncInit;
	}

	static void _Summary()
	{
		double mA = 0.0, mB = 0.0, mAcc = 0.0, mYA = 0.0, mYB = 0.0, mGap = 0.0;
		uint32 ok = 0u, bal = 0u, rep = 0u, t1 = 0u, t2 = 0u, flip = 0u, yb = 0u;
		for (uint32 s = 0; s < kSeeds; ++s)
		{
			if (!_seedOk[s]) continue;
			++ok;
			if (_balOk[s]) ++bal;
			if (_repOk[s]) ++rep;
			mA += _ce[0][s]; mB += _ce[1][s]; mAcc += _acc[0][s];
			mYA += _ceYaw[0][s]; mYB += _ceYaw[1][s];
			mGap += (double)(_ce[1][s] - _ce[0][s]);
			if (_ce[0][s] < kUnif) ++t1;
			if (_ce[0][s] < _ce[1][s]) ++t2;
			if (_ceYaw[0][s] < _ceYaw[1][s]) ++yb;
			// λ 감도 — 문턱이 아니라 **뒤집히나**만 본다
			const bool s1 = (_ceLo[0][s] < _ceLo[1][s]), s2 = (_ceHi[0][s] < _ceHi[1][s]);
			if (s1 != (_ce[0][s] < _ce[1][s]) || s2 != (_ce[0][s] < _ce[1][s])) ++flip;
		}
		if (ok > 0u)
		{
			mA /= ok; mB /= ok; mAcc /= ok; mYA /= ok; mYB /= ok; mGap /= ok;
		}
		const bool plumb = (bal == ok) && (rep == ok) && _finite && (ok > 0u);
		const bool p1 = (t1 >= kSignPass), p2 = (t2 >= kSignPass);

		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🐣 **회차 86 · L0 선형 프로브** — 읽은 씨앗 %u/%u\n", ok, kSeeds);
		LogA("[mlt] 🐣   배관 — ㈃ 클래스 균형 **%u/%u** · ㈄ 얼림/재현(비트동일) **%u/%u** → %s\n",
			bal, ok, rep, ok, plumb ? "통과" : "⛔");
		LogA("[mlt] 🐣   평균 프로브 CE — 균등바닥 **%.4f** · **㈀ %.4f** · ㈁ %.4f  ⇒ 차이 **%+.4f**\n",
			(double)kUnif, mA, mB, mGap);
		LogA("[mlt] 🐣   **표제① ㈀ < 균등바닥** — **%u/%u**(필요 %u)\n", t1, kSeeds, kSignPass);
		LogA("[mlt] 🐣   **표제② ⭐ ㈀ < ㈁(무작위 몸통)** — **%u/%u**(필요 %u)\n", t2, kSeeds, kSignPass);
		LogA("[mlt] 🐣   부산물 — ㈀ 정확도 **%.1f%%** · yaw행 CE ㈀ %.4f ↔ ㈁ %.4f(%u/12) · λ 뒤집힘 **%u/%u**\n",
			100.0 * mAcc, mYA, mYB, yb, flip, ok);
		if (!plumb)
			LogA("[mlt] 🐣   ⭐ 판정 = ⛔ **판정불가** — 배관이 안 섰다(균형/재현) · 표제를 읽지 않는다\n");
		else if (p1 && p2)
			LogA("[mlt] 🐣   ⭐ 판정 = ✅ **L0 이 선다** — 그 구분이 **언어 없이 이미** 표현에 있었다 ⇒ ***언어는 가리키는 것이고 앵커가 아니다***\n");
		else if (p1 && !p2)
			LogA("[mlt] 🐣   ⭐ 판정 = ⚠️ **이 낱말에 대해 미달** — 균등은 넘지만 무작위 몸통을 못 넘는다 ⇒ 입력의 **선형 잔재**다(⚠️ 반증 아님)\n");
		else
			LogA("[mlt] 🐣   ⭐ 판정 = ⛔ **표제① 실패** — 낱말 정의/배관을 의심한다(㈃ 가 먼저 걸러야 한다)\n");
		LogA("[mlt] 🐣   ⚠️ 문맥 %u · 프로브 %u/%u · 낱말 3개의 진단이다 — 절대 성능으로 인용하지 않는다\n",
			kNCtx, kPbCtx, kPtCtx);
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		_E.Destroy(); _done = true;
	}

	static void _Fail(const char* why)
	{
		LogA("[mlt] 🐣 ⛔ %s (씨앗 %u · 팔 %u · 단계 %u · 코퍼스 %u · 표현 %u/%u)\n",
			why, _seed, _arm, _st, _cor, _rw, _ri);
		_E.Destroy(); _done = true;
	}

	CW_BODY(MLTL0A0)
};
