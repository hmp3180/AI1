// mltl1l0.cw — 🔧 회차 150 · **용량을 올리면 파레토 교환이 풀리나** (`-mlt -mltl1l0`)
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 150 이다.** ⭐ **하네스보다 먼저 썼다.**
//   **상위 캔버스: `용량이 병목인가` · 150 = 1회차.**
//
// ── 🎯 표제 ────────────────────────────────────────────────────────────────
//   ***용량을 올리면 「지속 ↔ 변화」의 간격이 줄어드나 — 그리고 전이가 나타나나.***
//
// ── ⭐ 왜 이 물음인가 — 회차 149 가 두 가설을 남겼다 ─────────────
//   145·146·149 가 셋 다 *"무엇을 배우든 다른 것을 그만큼 잃는다"* 를 냈다. 그것은 **둘의 서명**이다:
//     ㉠ **용량 부족** — 하위 과제가 구조를 **공유**하는데 모델이 둘을 못 담는다
//                        ⇒ ⭐ 용량을 올리면 **간격이 줄고 전이가 나타난다**
//     ㉡ **구조 없음**  — 하위 과제가 **진짜로 독립**이다
//                        ⇒ ⛔ 둘 다 좋아지지만 **간격이 그대로**다
//   ⚠️ 149 의 ***완벽한 대칭 손실***(㈀ 는 밀림만·㈁ 는 새id만 · 전이 **0**)이 ㉡ 쪽 낌새다.
//   ★ 그런데 **실험 하나가 둘을 가른다** — 그것이 이 회차다.
//   ⚠️⚠️ 그리고 이것은 `P` 만의 물음이 아니다: ㉡ 이면 ***세계에 언어가 붙을 구조가 없다***는 뜻이고
//     그것이 **로드맵 칸 1 을 못 벗어난 이유**의 후보다(한 번도 안 재봤다).
//
// ── ⚙️ 배관 — 용량을 런타임 팔로(커밋 `0a13dbb2`) ─────────────────────────
//   ★ `MLTModel::Setup(..., dim, layer, ff)` · **셰이더 0줄** · 회귀 확인됨(비트 동일 + 손계산).
//   ⚠️⚠️ **컴파일 상수로는 이 회차를 할 수 없었다** — 한 바이너리에 두 용량을 못 담으면
//     **짝지음이 없고**, 이 트랙의 씨앗 변동 **0.28~0.59** 에 효과가 통째로 묻힌다(규율 51).
//   ⚠️ 층은 **고정 4** — A1 의 정신대로 **축을 하나만** 움직인다.
//
// ── 📏 자 ────────────────────────────────────────────────────────────────
//   `간격(d) = 변화CE(q=1.00, d) − 변화CE(q=0.00, d)`   기본에서 **1.030**(145 실측)
//   ⇒ ⭐ **도달률 = 간격(d) / 1.030**(무차원 · 규율 31). 보조 = 절대 CE · 갈래 분해(전이).
//
// ── 🔮 예측(재기 전에 적었다) ──────────────────────────────────────────────
//   ㉠ 검산 둘 ✅ · ⭐ ㉡ 절대 CE 는 용량에 **단조 감소**할 것
//   ⭐ ㉢ **간격은 거의 안 줄 것**(도달률 0.85~1.0) ⇒ **㉡ 구조 없음** 쪽
//     (근거: 149 의 전이가 **정확히 0** 이었고 그것은 용량과 무관한 모양이다)
//   ⚠️ ㉣ `q=0.00` 쪽이 더 많이 좋아져 **간격이 오히려 커질** 수도 있다
//   ㉤ `d=256`·`q=0.00` 이 목표선 **2.1111** 을 넘을 것 · ⚠️ ㉥ 아레나가 **180 MB** 근처
// ══════════════════════════════════════════════════════════════════════════════

using namespace PE;

class MLTL1L0
{
public:
	static void Tick(RHI* rhi)
	{
		if (_done || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltl1l0"))
		{
			LogA("[mlt] 🔧 회차 150(용량을 올리면 파레토 교환이 풀리나)는 **꺼져 있다**(`-mltl1l0`)\n");
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
	static constexpr uint32 kPerTick = 16u;
	// ⭐ **걸음도 팔이다**(회차 150b) — 1씨앗 진단이 요구했다: 용량을 3.8배로 올렸는데 걸음이
	//   **800 그대로**여서 절대 CE 가 **나빠졌다**(`q=1.00 · d=256 − d=128` = **+0.2148** · `|d̄|/SE 7.40`).
	//   ⇒ ★ 그것은 「용량 부족」도 「구조 없음」도 아닌 **㉢ 최적화 부족**의 서명이고,
	//     걸음 축을 넣지 않으면 셋을 **원리적으로 못 가른다**.
	//   ⚠️ 표제는 안 바뀌었다(*"교환이 풀리나"*) — **교란 하나를 통제**하는 것이다.
	//   ⚠️ `-mltstep` 을 주면 「걸음 축 진단」 모드가 된다(용량 고정 · 걸음 셋 · 부호만 본다).
	static constexpr uint32 kStepsBase = 800u;

	static constexpr uint32 kSymA = MLTP3Ctx::kStateAx + kN + 1u;
	static constexpr uint32 kAx13 = MLTP3Ctx::kAxes;                 // 13
	static constexpr uint32 kAx14 = kAx13 + 1u;                      // 14
	static constexpr uint32 kCtx14 = kAx14 * kTime;                  // 112
	static constexpr uint32 kRows14 = kBatch * kCtx14;               // 896
	static constexpr float  kWordSym = 255.0f;
	static constexpr uint32 kWordCls = 9u, kConstCls = 4u;

	// ⭐ 밖에서 온 눈금 — ⚠️ 여기서 새로 재지 않는다.
	static constexpr float kTarget  = 2.1111f;   // 회차 143 · 학습 0 예측기의 최선
	static constexpr float kCE145A  = 2.7742f;   // 회차 145 · q=1.00 (검산)
	static constexpr float kCE145E  = 1.7443f;   // 회차 145 · q=0.00 (검산)
	static constexpr float kGap145  = kCE145A - kCE145E;   // = 1.0299 — ⭐ 도달률의 분모

	// 🎛️ 용량 표 — `F ≈ 8/3·d`
	//   ⚠️ 0~2 는 **폭만** 움직인다(회차 150 · 축을 하나만).
	//   ⭐ 3 은 **깊이**다(회차 151 · `d=128·L=8`) — ★ `1,650,048` 파라미터로 용량 1(`1,871,424`)과
	//     **13% 안에서 같다** ⇒ ***같은 예산에서 「폭 ↔ 깊이」의 순수 비교***가 된다.
	static constexpr uint32 kCaps = 4u;
	static constexpr uint32 kCapD[kCaps]  = { 128u, 192u, 256u, 128u };
	static constexpr uint32 kCapF[kCaps]  = { 344u, 512u, 683u, 344u };
	static constexpr uint32 kCapL[kCaps]  = {   4u,   4u,   4u,   8u };
	// `q` 둘(천분율) — 145 의 양 끝점이고 **둘 다 검산**이다.
	static constexpr uint32 kQs = 2u;
	static constexpr uint32 kKeepQ[kQs] = { 1000u, 0u };

	// ── 🎛️ 팔 표 — ⭐ 모드 둘 ────────────────────────────────────────
	//   ㈀ **용량 스윕**(기본) — 용량 셋 × `q` 둘 = 6팔 · 걸음은 전부 ×1
	//   ⭐ ㈁ **걸음 축 진단**(`-mltstep`) — `d=256`·`q=0.00` 에서 걸음 ×1/×3/×6
	//      ⚠️ **`d=128`·`q=0.00`·×1 을 같은 실행에 넣는다** — 그것이 기준선(짝지음이 성립한다).
	//   ⭐ ㈂ **깊이 모드**(`-mltdepth` · 회차 151) — 기준 ↔ **깊이**(L=8) ↔ **폭**(d=192) × `q` 둘
	// ⚠️ 학습률 모드가 **7팔**이라 상한을 8 로 올렸다(회차 152 — 깊이가 표제 후보가 돼서
	//   그 최적 `lr` 을 찾아야 한다: 깊이 ×1/×0.5/**×0.25**).
	static constexpr uint32 kArmsMax = 8u;
	static constexpr uint32 kCapSweep[6]  = { 0u, 0u, 1u, 1u, 2u, 2u };
	static constexpr uint32 kQSweep[6]    = { 0u, 1u, 0u, 1u, 0u, 1u };
	static constexpr uint32 kMulSweep[6]  = { 1u, 1u, 1u, 1u, 1u, 1u };
	static constexpr uint32 kCapStep[4]   = { 0u, 2u, 2u, 2u };
	static constexpr uint32 kQStep[4]     = { 1u, 1u, 1u, 1u };
	static constexpr uint32 kMulStep[4]   = { 1u, 1u, 3u, 6u };
	// ⭐ 깊이 모드 — 용량 0(기준) · 3(깊이 L=8) · 1(폭 d=192) 을 `q` 둘로
	static constexpr uint32 kCapDeep[6]   = { 0u, 0u, 3u, 3u, 1u, 1u };
	static constexpr uint32 kQDeep[6]     = { 0u, 1u, 0u, 1u, 0u, 1u };
	//   ⭐ ㈃ **학습률 모드**(`-mltlr` · 회차 152) — ⚠️ `q = 0.00` **고정**(변화만 학습)
	//     ★ `MLTModel::AdamStep(lrMul)` 이 **이미 배율을 받는다**(`p.lr = kLr · lrMul`)
	//       ⇒ **커널·모델 0줄**이다.
	//     🎯 물음 = ***용량마다 최적 `lr` 이 다른가 — `lr` 을 맞추면 큰 모델이 기준을 이기나.***
	//     ⚠️ 표제 자가 **학습 CE** 다(이 트랙에서 처음) — *"일반화하나"* 가 아니라 *"학습을 하나"*.
	static constexpr uint32 kLrArms       = 7u;
	static constexpr uint32 kCapLr[7]     = { 0u, 1u, 1u, 1u, 3u, 3u, 3u };
	static constexpr float  kLrMul[7]     = { 1.0f, 1.0f, 0.5f, 0.25f, 1.0f, 0.5f, 0.25f };
	//   ⭐ ㈄ **파레토 모드**(`-mltpar` · 회차 153) — ***새 배치에서 파레토가 겹치나.***
	//     ★ 이 트랙의 가장 큰 결론 셋(145 파레토 통과 0 · 146 회전 무의미 · 149 대칭 손실)이
	//       전부 `L=4 · lr×1` 에서 쟀고, 152 가 그것이 ***「나르기로 도망가는」 배치***임을 보였다.
	//     ⇒ 통과 점이 생기면 **셋이 한꺼번에 조건부**가 되고, 안 생기면 **셋이 강화**된다.
	//     팔 = 옛 배치 양 끝(검산 둘) + 새 배치(`L=8·lr×0.5`) `q` 다섯.
	static constexpr uint32 kParArms      = 7u;
	static constexpr uint32 kCapPar[7]    = { 0u, 0u, 3u, 3u, 3u, 3u, 3u };
	static constexpr uint32 kQiPar[7]     = { 0u, 4u, 0u, 1u, 2u, 3u, 4u };   // kKeepQ5 색인
	static constexpr float  kLrPar[7]     = { 1.0f, 1.0f, 0.5f, 0.5f, 0.5f, 0.5f, 0.5f };
	// ⭐ `q` 다섯(천분율) — 145 와 **같은 격자**(비교 가능성이 목적이다)
	static constexpr uint32 kKeepQ5[5]    = { 1000u, 500u, 250u, 100u, 0u };
	// ⭐ **최소 미달** — `min_q [ max(0, 변화−목표선) + max(0, 지속−문턱) ]`
	//   ★ *"겹치나"* 는 **이진**이고 이것은 **연속**이다 ⇒ *"얼마나 가까워졌나"* 를 준다.
	//   ⚠️ 회차 145 의 값을 **손계산**했다(규율 21 · 문턱 = 0.2592×2 = 0.5184):
	//     q=1.00 (2.7742, 0.2592) → 0.663 + 0     = 0.663
	//     q=0.50 (2.3923, 0.4534) → 0.281 + 0     = **0.281**  ← 최소
	//     q=0.25 (2.1735, 0.7378) → 0.062 + 0.219 = **0.281**  ← 최소(우연히 같다)
	//     q=0.10 (1.9673, 1.2503) → 0     + 0.732 = 0.732
	//     q=0.00 (1.7443, 5.1227) → 0     + 4.604 = 4.604
	static constexpr float kShort145 = 0.281f;
	// ⭐ 회차 153 이 12씨앗으로 잰 값들 — ⚠️ 여기서 새로 재지 않는다.
	static constexpr float kTh153    = 0.5531f;   // 새 배치(`L=8·lr×0.5`)의 지속 문턱
	static constexpr float kCE153q25 = 2.0977f;   // 새 `q=0.25` 변화 CE (재현 눈금)
	static constexpr float kCE153q10 = 1.8749f;   // 새 `q=0.10` 변화 CE (재현 눈금)
	static constexpr float kShort153 = 0.1409f;   // 새 배치의 최소 미달

	//   ⭐ ㈅ **weight decay 모드**(`-mltwd` · 회차 154) — ***`wd` 가 남은 0.141 을 지우나.***
	//     ⚙️ 커널 0줄 — `adamw.cs.hlsl` 이 **decoupled AdamW 정석**(`p -= lr·wd·p`)이고
	//       `MLTModel::AdamStep(lrMul, wd)` 를 회차 154 에서 열었다.
	//     ⭐ 손계산으로 값을 골랐다(규율 21 · `lr = 3e-3 × 0.5 = 1.5e-3`):
	//       `wd=0.01` → 800걸음 누적 수축 **0.988**(−1.2%) · `wd=0.1` → **0.887**(−11.3%)
	//       ⚠️ `wd=1.0` → 0.301(−70%) ⇒ **너무 세다 · 넣지 않는다**(재기 전에 기각).
	//     ⚠️ `q` 를 **둘**(0.25 · 0.10) 두는 이유: `wd` 가 지속을 지켜 주면 **최적 `q` 가 더 낮은
	//       쪽으로 옮겨진다** ⇒ `q=0.25` 만 보면 놓친다.
	static constexpr uint32 kWdArms      = 7u;
	static constexpr uint32 kCapWd[7]    = { 0u,   3u,   3u,   3u,   3u,   3u,   3u   };
	static constexpr uint32 kQiWd[7]     = { 0u,   2u,   2u,   2u,   3u,   3u,   3u   };  // kKeepQ5 색인
	static constexpr float  kLrWd[7]     = { 1.0f, 0.5f, 0.5f, 0.5f, 0.5f, 0.5f, 0.5f };
	static constexpr float  kWdVal[7]    = { 0.0f, 0.0f, 0.01f, 0.1f, 0.0f, 0.01f, 0.1f };
	inline static bool   _stepMode = false, _deepMode = false, _lrMode = false, _parMode = false;
	// ⭐ 회차 161 — **델타 표현**(`-mltdelta`) · ⚠️ 세계 코드 0줄
	//   ⚠️⚠️ 규율 57 — 이 하네스가 든 절대판 상수 아홉 개는 **델타 팔에서 무효**다.
	//     쓸 수 있는 것은 `kTarget → 3.2005`(회차 160 이 쟀다) 하나이고,
	//     문턱은 이미 **규칙**(그 배치의 `q=1.00` 지속 × 2)이라 그대로 산다.
	inline static bool   _deltaOn = false;
	static constexpr float kTargetD  = 3.2005f;   // 회차 160 · 델타판 학습 0 최선
	static constexpr float kUniform  = 5.5215f;   // ln 250 — 도달률의 바닥
	// ⭐ **도달률** = (바닥 − 몸통) / (바닥 − 목표선) ⇒ ★ 표현이 달라도 견줄 수 있는 유일한 자
	// ⭐ 회차 161 절대 팔이 잰 값(최소 미달 팔 ㈄ `q=0.25` 의 도달률) — 손계산 1.0033 과 차 0.0006
	static constexpr float kReachAbs = 1.0039f;
	static double _Target() { return _deltaOn ? (double)kTargetD : (double)kTarget; }
	static double _Reach(double ce) { return ((double)kUniform - ce) / ((double)kUniform - _Target()); }
	inline static bool   _wdMode = false;
	inline static uint32 kArms = 6u;   // ⚠️ 모드가 정한다(`_Banner` 에서)

	static uint32 _ACap(uint32 a)
	{
		if (_stepMode) return kCapStep[a];
		if (_deepMode) return kCapDeep[a];
		if (_lrMode)   return kCapLr[a];
		if (_parMode)  return kCapPar[a];
		if (_wdMode)   return kCapWd[a];
		return kCapSweep[a];
	}
	// ⭐ 보존율(**천분율**)을 직접 준다 — 모드마다 `q` 격자가 다르므로 색인이 아니라 값이다.
	static uint32 _AKeepQ(uint32 a)
	{
		if (_parMode)  return kKeepQ5[kQiPar[a]];
		if (_wdMode)   return kKeepQ5[kQiWd[a]];
		if (_lrMode)   return kKeepQ[1];        // ⚠️ `q = 0.00` 고정
		if (_stepMode) return kKeepQ[kQStep[a]];
		if (_deepMode) return kKeepQ[kQDeep[a]];
		return kKeepQ[kQSweep[a]];
	}
	static uint32 _AMul(uint32 a) { return _stepMode ? kMulStep[a] : 1u; }
	static uint32 _ASteps(uint32 a) { return kStepsBase * _AMul(a); }
	static float  _ALr(uint32 a)
	{
		if (_lrMode)  return kLrMul[a];
		if (_parMode) return kLrPar[a];
		if (_wdMode)  return kLrWd[a];
		return 1.0f;
	}
	static float  _AWd(uint32 a) { return _wdMode ? kWdVal[a] : MLTModelCfg::kWd; }

	enum { kMTrain = 0u, kMChange = 1u, kMKeep = 2u, kMShift = 3u, kMNew = 4u };
	// 평가 갈래 — 0 전체변화(시험) · 1 지속 · 2 밀림 · 3 새id · ⭐ 4 **전체변화(학습 코퍼스)**
	static constexpr uint32 kEvals = 5u;
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

	inline static float _ce[kEvals][kOut][kArmsMax][kSeedsMax];
	inline static bool  _seedOk[kSeedsMax];
	inline static double _nTrain[kArmsMax];
	inline static uint32 _params[kCaps] = { 0u }, _arena[kCaps] = { 0u };
	inline static uint32 _lastScored = 0u;

	static void _ToBody() { _qWait = MLTEvalGate::kDelay; _st = kQuiesce; }
	// ⭐ 모드마다 이름표가 다르다(문자열 조립을 피한다 — 엔진 표면에 기대지 않는다).
	static const char* _ArmName(uint32 a)
	{
		if (_wdMode)
		{
			switch (a)
			{
			case 0u: return "㈀ 옛 q=1.00 wd=0(검산) ";
			case 1u: return "㈁ 새 q=.25 wd=0(재현)  ";
			case 2u: return "㈂ 새 q=.25 wd=.01 ⭐   ";
			case 3u: return "㈃ 새 q=.25 wd=.1  ⭐   ";
			case 4u: return "㈄ 새 q=.10 wd=0(재현)  ";
			case 5u: return "㈅ 새 q=.10 wd=.01 ⭐   ";
			default: return "㈆ 새 q=.10 wd=.1  ⭐   ";
			}
		}
		if (_parMode)
		{
			switch (a)
			{
			case 0u: return "㈀ 옛 L=4 q=1.00(검산)";
			case 1u: return "㈁ 옛 L=4 q=0.00(검산)";
			case 2u: return "㈂ 새 L=8 q=1.00      ";
			case 3u: return "㈃ 새 L=8 q=0.50 ⭐   ";
			case 4u: return "㈄ 새 L=8 q=0.25 ⭐   ";
			case 5u: return "㈅ 새 L=8 q=0.10 ⭐   ";
			default: return "㈆ 새 L=8 q=0.00      ";
			}
		}
		if (_lrMode)
		{
			switch (a)
			{
			case 0u: return "㈀ 기준 d=128 lr×1(검산)";
			case 1u: return "㈁ ●폭 d=192 lr×1     ";
			case 2u: return "㈂ ●폭 d=192 lr×0.5 ⭐";
			case 3u: return "㈃ ●폭 d=192 lr×0.25⭐";
			case 4u: return "㈄ ⚫︎깊이 L=8 lr×1    ";
			case 5u: return "㈅ ⚫︎깊이 L=8 lr×0.5⭐";
			default: return "㈆ ⚫︎깊이 L=8 lr×.25⭐";
			}
		}
		if (_deepMode)
		{
			switch (a)
			{
			case 0u: return "㈀ d=128 L=4 q=1.00(검산)";
			case 1u: return "㈁ d=128 L=4 q=0.00(검산)";
			case 2u: return "㈂ ⚫︎깊이 L=8 q=1.00 ⭐ ";
			case 3u: return "㈃ ⚫︎깊이 L=8 q=0.00 ⭐ ";
			case 4u: return "㈄ ●폭 d=192 q=1.00 ⭐  ";
			default: return "㈅ ●폭 d=192 q=0.00 ⭐  ";
			}
		}
		if (_stepMode)
		{
			switch (a)
			{
			case 0u: return "㈀ d=128 ×1걸음(기준)  ";
			case 1u: return "㈁ d=256 ×1걸음        ";
			case 2u: return "㈂ d=256 ×3걸음 ⭐     ";
			default: return "㈃ d=256 ×6걸음 ⭐     ";
			}
		}
		switch (a)
		{
		case 0u: return "㈀ d=128 q=1.00(검산)  ";
		case 1u: return "㈁ d=128 q=0.00(검산)  ";
		case 2u: return "㈂ d=192 q=1.00 ⭐     ";
		case 3u: return "㈃ d=192 q=0.00 ⭐     ";
		case 4u: return "㈄ d=256 q=1.00 ⭐     ";
		default: return "㈅ d=256 q=0.00 ⭐     ";
		}
	}
	static const char* _EvalName(uint32 e)
	{
		switch (e)
		{
		case 0u: return "전체변화";
		case 1u: return "지속    ";
		case 2u: return "밀림    ";
		default: return "새id    ";
		}
	}
	static uint32 _SignPass() { return (_seeds * 10u + 11u) / 12u; }

	// ⭐ 손계산 — 파라미터 수(규율 21 · 서명으로 찍어 배관을 검산한다)
	//   `kPhi·D + symVocab·D + L·(2D + 4D² + 3·D·F) + D + D·V`  (⭐ kPhi = 2·kFreqs = 16)
	static uint32 _ParamHand(uint32 d, uint32 f, uint32 L)
	{
		const uint32 phi = 2u * MLTModelCfg::kFreqs;
		return phi * d + kSymA * d
			+ L * (2u * d + 4u * d * d + 3u * d * f)
			+ d + d * kN;
	}

	static void _Banner()
	{
		_stepMode = OS::CommandLine::Has("-mltstep");
		_deepMode = !_stepMode && OS::CommandLine::Has("-mltdepth");
		_lrMode   = !_stepMode && !_deepMode && OS::CommandLine::Has("-mltlr");
		_parMode  = !_stepMode && !_deepMode && !_lrMode && OS::CommandLine::Has("-mltpar");
		_wdMode   = !_stepMode && !_deepMode && !_lrMode && !_parMode && OS::CommandLine::Has("-mltwd");
		_deltaOn  = OS::CommandLine::Has("-mltdelta");   // ⭐ 회차 161
		kArms = _stepMode ? 4u
			: (_lrMode ? kLrArms : (_parMode ? kParArms : (_wdMode ? kWdArms : 6u)));
		if (_wdMode)
		{
			LogA("[mlt] ══════════════════════════════════════════════════\n");
			LogA("[mlt] 🧲 **회차 154 · weight decay 가 남은 %.4f 을 지우나**(%s)\n",
				(double)kShort153, (_seeds == 1u) ? "⚠️ 1씨앗 진단" : "⭐ 판정 회차 · 씨앗 12");
			LogA("[mlt] 🧲   🎯 표제 = ***`wd` 를 켜면 최소 미달이 0 이 되나 — 즉 파레토가 겹치나***\n");
			LogA("[mlt] 🧲   ⚙️ 커널 **0줄** — `adamw.cs.hlsl` 이 **decoupled AdamW 정석**(`p -= lr·wd·p`)이고\n");
			LogA("[mlt] 🧲      `AdamStep(lrMul, wd)` 를 이 회차에서 열었다(기본값 = `kWd` = 0 ⇒ 기존 하네스 비트 동일)\n");
			LogA("[mlt] 🧲   ⭐ **손계산으로 값을 골랐다**(규율 21 · `lr = 3e-3 × 0.5 = 1.5e-3` · 800걸음):\n");
			LogA("[mlt] 🧲      `wd=0.01` → 누적 수축 **0.988**(−1.2%%) · `wd=0.1` → **0.887**(−11.3%%)\n");
			LogA("[mlt] 🧲      ⚠️ `wd=1.0` → 0.301(−70%%) ⇒ **너무 세다 · 재기 전에 기각했다**\n");
			LogA("[mlt] 🧲   ⚠️ `q` 를 **둘**(0.25 · 0.10) 두는 이유 = `wd` 가 지속을 지켜 주면 **최적 `q` 가 더 낮은 쪽으로**\n");
			LogA("[mlt] 🧲      옮겨진다 ⇒ `q=0.25` 만 보면 놓친다\n");
			LogA("[mlt] 🧲   📏 자 = **최소 미달**(규율 54) · 눈금 = 145 **%.3f** → 153 **%.4f** → 이 회차\n",
				(double)kShort145, (double)kShort153);
			LogA("[mlt] 🧲      ⚠️ 문턱은 **회차 153 이 잰 %.4f 을 상수로** 쓴다 — 문턱은 **배치의 성질**이고\n",
				(double)kTh153);
			LogA("[mlt] 🧲         `wd` 가 그것을 바꾸면 **자가 움직인다**\n");
			for (uint32 a = 0; a < kArms; ++a)
				LogA("[mlt] 🧲      %s → L=%u · lr ×%.2f · q %.2f · **wd %.3f**\n",
					_ArmName(a), kCapL[_ACap(a)], (double)_ALr(a),
					(double)_AKeepQ(a) / 1000.0, (double)_AWd(a));
			LogA("[mlt] 🧲   🔮 예측 — ⭐ `wd=0.1` 이 **간극을 줄이고** · ⚠️ **미달은 0 이 안 되고**(지속은 학습 안 하는 축) ·\n");
			LogA("[mlt] 🧲      ⭐ 미달은 **조금 줄고**(0.10~0.13) · ⚠️ `wd=0.1` 이 변화를 나쁘게 해 **오히려 커질** 수도 · ⭐ `q=0.10` 이 더 유망\n");
			LogA("[mlt] ══════════════════════════════════════════════════\n");
			return;
		}
		if (_parMode)
		{
			LogA("[mlt] ══════════════════════════════════════════════════\n");
			LogA("[mlt] 🪢 **회차 153 · 새 배치에서 파레토가 겹치나**(%s)\n",
				(_seeds == 1u) ? "⚠️ 1씨앗 진단" : "⭐ 판정 회차 · 씨앗 12");
			LogA("[mlt] 🪢   🎞️ 표현 = **%s** · 목표선 = **%.4f**%s\n",
				_deltaOn ? "델타(`-mltdelta`)" : "절대(기본)", _Target(),
				_deltaOn ? "(회차 160)" : "(회차 143)");
			if (_deltaOn)
			{
				LogA("[mlt] 🪢   ⭐ **회차 161** = ***델타판 몸통이 목표선 3.2005 를 넘나***\n");
				LogA("[mlt] 🪢      ⚠️⚠️ 규율 57 — 이 하네스의 **절대판 상수 아홉 개는 무효**다:\n");
				LogA("[mlt] 🪢         ⛔ 검산(2.7742·1.7443) · 재현(1.6770·2.0977·1.8749) · 미달(0.281·0.1409) · 눈금(1.0299)\n");
				LogA("[mlt] 🪢         ✅ 문턱은 **규칙**이라 산다(그 배치의 `q=1.00` 지속 × 2)\n");
				LogA("[mlt] 🪢      ⭐ 자 = **도달률** = (바닥 %.4f − 몸통)/(바닥 − 목표선) ⇒ 절대판 최선 **%.4f**\n",
					(double)kUniform, (double)kReachAbs);
			}
			else
				LogA("[mlt] 🪢   🎯 표제 = ***`L=8 · lr×0.5` 에서 「변화 < %.4f 이고 지속 < 문턱」인 `q` 가 있나***\n",
					_Target());
			LogA("[mlt] 🪢   ⭐ 이 트랙의 가장 큰 결론 셋이 전부 *\"예산을 옮기면 반대쪽이 그만큼 나빠진다\"* 다:\n");
			LogA("[mlt] 🪢      145 파레토 통과 **0** · 146 회전이 **무의미**(0.042) · 149 밀림↔새id **완벽 대칭 손실**\n");
			LogA("[mlt] 🪢      ⚠️⚠️ 그런데 **셋 다 `L=4 · lr×1` 에서 쟀고**, 회차 152 가 그것이\n");
			LogA("[mlt] 🪢         ***「나르기로 도망가는」 배치***임을 보였다(`lr` 이 높으면 복사로 붕괴)\n");
			LogA("[mlt] 🪢      ⇒ ★ 파레토가 **모델의 성질**이 아니라 **그 배치의 성질**일 수 있다\n");
			LogA("[mlt] 🪢      ⇒ ⭐ 통과 점이 생기면 **셋이 한꺼번에 조건부**가 되고 안 생기면 **셋이 강화**된다\n");
			LogA("[mlt] 🪢   ⚠️ **지속 문턱은 「그 배치의 q=1.00 지속 CE × 2」로 미리 정의한다**(값이 아니라 **규칙**)\n");
			LogA("[mlt] 🪢      ★ 145 의 0.5184 를 그대로 쓰면 **배치가 다른 두 자를 섞는다** · 사후 선택이 아니다\n");
			LogA("[mlt] 🪢   ⭐ 검산 둘 = ㈀ **%.4f ± 0.05** · ㈁ **%.4f ± 0.05** · 재현 = ㈆ 가 **1.6770 ± 0.05**\n",
				(double)kCE145A, (double)kCE145E);
			for (uint32 a = 0; a < kArms; ++a)
				LogA("[mlt] 🪢      %s → d=%u L=%u · lr ×%.2f · **q %.2f**\n",
					_ArmName(a), kCapD[_ACap(a)], kCapL[_ACap(a)],
					(double)_ALr(a), (double)_AKeepQ(a) / 1000.0);
			LogA("[mlt] 🪢   🔮 예측 — ⚠️ **통과 점이 여전히 0 일 것**(새 배치의 q=0.00 지속이 5.4349 로 더 나빴다) ·\n");
			LogA("[mlt] 🪢      ⭐ 그런데 **곡선 전체가 아래로** · ⭐ **무릎이 더 낮은 `q` 로** · ⚠️ 문턱이 커져 표제가 쉬워진다\n");
			LogA("[mlt] ══════════════════════════════════════════════════\n");
			return;
		}
		if (_lrMode)
		{
			LogA("[mlt] ══════════════════════════════════════════════════\n");
			LogA("[mlt] 📉 **회차 152 · 큰 모델이 학습조차 못 맞히는 것이 학습률 때문인가**(%s)\n",
				(_seeds == 1u) ? "⚠️ 1씨앗 진단" : "⭐ 판정 회차 · 씨앗 12");
			LogA("[mlt] 📉   🎯 표제 = ***용량마다 최적 `lr` 이 다른가 — `lr` 을 맞추면 큰 모델이 기준을 이기나***\n");
			LogA("[mlt] 📉   ⭐ 회차 151 이 처음 만든 자(**학습 CE**)가 ㉢ 을 다시 열었다:\n");
			LogA("[mlt] 📉      학습 CE 가 용량에 **나빠진다**(기준 1.6498 → 깊이 1.7405 → 폭 **1.8997**)\n");
			LogA("[mlt] 📉      ⇒ ★ 큰 모델이 **학습 데이터조차 덜 맞힌다** = 과소적합 = **최적화 문제의 정의**\n");
			LogA("[mlt] 📉      ⚠️⚠️ 150b 는 「걸음 6배에도 안 고쳐진다」로 ㉢ 을 기각했는데 **그때 시험 CE 만 봤다**\n");
			LogA("[mlt] 📉   ⚠️ 표제 자가 **학습 CE** 다(이 트랙에서 처음) — *\"일반화하나\"* 가 아니라 *\"학습을 하나\"*\n");
			LogA("[mlt] 📉   ⚙️ 커널·모델 **0줄** — `AdamStep(lrMul)` 이 이미 배율을 받는다(`kLr = 3.0e-3`)\n");
			LogA("[mlt] 📉   ⚠️ `q = 0.00` **고정**(변화만 학습) · 검산 = ㈀ 가 **%.4f ± 0.05**\n", (double)kCE145E);
			for (uint32 a = 0; a < kArms; ++a)
				LogA("[mlt] 📉      %s → d=%u L=%u · **lr ×%.2f**\n",
					_ArmName(a), kCapD[_ACap(a)], kCapL[_ACap(a)], (double)_ALr(a));
			LogA("[mlt] 📉   🔮 예측 — ⭐ `lr` 을 낮추면 학습 CE 가 좋아지고 · ⚠️ **그런데 기준을 못 이기고** ·\n");
			LogA("[mlt] 📉      ⭐ 최적 `lr` 이 용량에 따라 낮아지고 · ⚠️ 깊이가 `lr` 에 더 민감하고 · 간극은 커진다\n");
			LogA("[mlt] ══════════════════════════════════════════════════\n");
			return;
		}
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🔧 **회차 150%s · 용량을 올리면 파레토 교환이 풀리나**(%s)\n",
			_stepMode ? "b(걸음 축 진단)" : (_deepMode ? " \u2192 151(같은 예산에서 폭 \u2194 깊이)" : ""),
			(_seeds == 1u) ? "⚠️ 1씨앗 진단" : "⭐ 판정 회차 · 씨앗 12");
		if (_stepMode)
		{
			LogA("[mlt] 🔧   ⭐ **걸음 축 진단** — 1씨앗 진단이 요구했다: 용량 3.8배인데 걸음이 **800 그대로**여서\n");
			LogA("[mlt] 🔧      절대 CE 가 **나빠졌다**(`q=1.00 · d=256 − d=128` = **+0.2148** · |d̄|/SE **7.40**)\n");
			LogA("[mlt] 🔧      ⇒ ★ 그것은 ㉠ 용량부족도 ㉡ 구조없음도 아닌 **㉢ 최적화 부족**의 서명이다\n");
			LogA("[mlt] 🔧   🎯 물음 = ***걸음을 올리면 d=256 이 d=128 을 이기나***(같은 q=0.00)\n");
			LogA("[mlt] 🔧      ✅ 이기면 ㉢ 확정 ⇒ 12씨앗 판정을 「같은 걸음-파라미터 예산」으로 설계한다\n");
			LogA("[mlt] 🔧      ⛔ 안 이기면 ㉢ 이 아니고 ㉠/㉡ 갈래로 돌아간다\n");
			LogA("[mlt] 🔧   ⚠️ 표제는 안 바뀌었다 — **교란 하나(걸음)를 통제**하는 것이다(사후 관문 변경이 아니다)\n");
			for (uint32 a = 0; a < kArms; ++a)
				LogA("[mlt] 🔧      %s → d=%u · q=%.2f · 걸음 **%u**\n",
					_ArmName(a), kCapD[_ACap(a)], (double)_AKeepQ(a) / 1000.0, _ASteps(a));
			LogA("[mlt] ══════════════════════════════════════════════════\n");
			return;
		}
		LogA("[mlt] 🔧   🎯 표제 = ***용량을 올리면 「지속↔변화」 간격이 줄어드나 — 전이가 나타나나***\n");
		LogA("[mlt] 🔧   ⭐ 149 가 두 가설을 남겼다 — ㉠ **용량 부족**(구조를 공유하나 못 담는다 ⇒ 간격이 줄고 전이가 생긴다)\n");
		LogA("[mlt] 🔧      ↔ ㉡ **구조 없음**(진짜로 독립 ⇒ 둘 다 좋아지지만 간격은 그대로) — 149 의 전이 **0** 이 ㉡ 쪽 낌새다\n");
		LogA("[mlt] 🔧   ⚠️⚠️ ㉡ 이면 ***세계에 언어가 붙을 구조가 없다*** ⇒ 로드맵 칸 1 을 못 벗어난 이유의 후보다\n");
		LogA("[mlt] 🔧   ⚙️ 용량이 **런타임 팔**이다(셰이더 0줄) — ⚠️ 컴파일 상수면 짝지음이 없어 씨앗 변동 0.28~0.59 에 묻힌다\n");
		LogA("[mlt] 🔧   📏 자 = **간격 / %.4f**(145 의 눈금 · 무차원) · 보조 = 절대 CE · 갈래 분해(전이)\n", (double)kGap145);
		LogA("[mlt] 🔧   ⭐ 검산 둘 = d=128 의 두 점이 **%.4f / %.4f ± 0.05**\n", (double)kCE145A, (double)kCE145E);
		LogA("[mlt] 🔧   🔮 예측 — 절대 CE 는 단조 감소 · ⭐ **간격은 거의 안 줄 것**(도달률 0.85~1.0) ⇒ ㉡ 쪽\n");
		for (uint32 c = 0; c < kCaps; ++c)
			LogA("[mlt] 🔧      용량 %u — d=%u F=%u 층=%u · 손계산 파라미터 **%u**\n",
				c, kCapD[c], kCapF[c], kCapL[c], _ParamHand(kCapD[c], kCapF[c], kCapL[c]));
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

	// ── 인코더 · 코퍼스(138~149 과 **비트 동일**) ────────────────────
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
		ImageFormat::Bitmap bmpA, bmpB; Bytes packed;
		MLTWorld w; w.Reset(_seed, 0u, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
		for (uint32 f = 0; f < kEncF; ++f)
		{
			w.Step();
			// ⚠️ 인코더도 **같은 표현**으로 학습해야 한다
			ImageFormat::Bitmap& cur = (f % 2u == 0u) ? bmpA : bmpB;
			ImageFormat::Bitmap& prv = (f % 2u == 0u) ? bmpB : bmpA;
			if (!w.Render(cur)) { _Fail("Render(인코더)"); return; }
			const ImageFormat::Bitmap* pp = (_deltaOn && f > 0u) ? &prv : nullptr;
			if (!MLTWorld::Pack(cur, pp, packed)) { _Fail("Pack(인코더)"); return; }
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
			ImageFormat::Bitmap bmpA, bmpB; Bytes packed;
			const uint32 epi = _EpiOf(_cor);
			for (uint32 g = 0; g < kGroup; ++g)
			{
				const uint32 ctx = _gGrp * kGroup + g;
				MLTWorld w; w.Reset(_seed, epi + ctx, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
				for (uint32 t = 0; t < kTime; ++t)
				{
					w.Step();
					// ⭐ 회차 161 — 에피소드 첫 프레임은 **키프레임**이다
					ImageFormat::Bitmap& cur = (t % 2u == 0u) ? bmpA : bmpB;
					ImageFormat::Bitmap& prv = (t % 2u == 0u) ? bmpB : bmpA;
					if (!w.Render(cur)) { _Fail("Render(문맥)"); return; }
					const ImageFormat::Bitmap* pp = (_deltaOn && t > 0u) ? &prv : nullptr;
					if (!MLTWorld::Pack(cur, pp, packed)) { _Fail("Pack(문맥)"); return; }
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

	// ⭐ 결정적 해시 — 팔에 **의존하지 않는다**(짝지음이 성립하게).
	static uint32 _Hash(uint32 ctx, uint32 t, uint32 a)
	{
		uint32 h = ((ctx * 131u + t * 17u + a) * 2654435761u) ^ (_seed * 97u + 12345u);
		h ^= h >> 15; h *= 2246822519u; h ^= h >> 13; h *= 3266489917u; h ^= h >> 16;
		return h % 1000u;
	}

	// ⚠️ 「밀림」 = 그 표적 id 가 **지금 활성 8개 안**에 있다(회차 143·149 와 같은 정의).
	static bool _InActive(const MLTP3Ctx& C, uint32 src, uint32 tid)
	{
		for (uint32 q = 0; q < kSlots; ++q)
			if ((uint32)(C.Sym()[src + kStateAx + q] - (float)kStateAx) == tid) return true;
		return false;
	}

	// ── 13축 → 14축(낱말은 상수 0) + 마스크 ─────────────────────────
	//   `kMTrain` = 학습(`keepQ` 로 지속을 솎는다 · 145 와 **같은 식**) ·
	//   나머지는 **시험 채점** 마스크다.
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
						else if (mask == kMShift)  { if (keep || !_InActive(C, src, tid)) tf = (float)kN; }
						else if (mask == kMNew)    { if (keep ||  _InActive(C, src, tid)) tf = (float)kN; }
						// ⭐ 학습 — **지속 표적만** 보존율 `q` 로 솎는다(145 와 같은 식)
						else if (keep && _Hash(ctx, t, a) >= keepQ) tf = (float)kN;
					}
					if (tf >= 0.0f && tf < (float)kN) ++scored;
					oTgt.Data()[dst + 1u + a] = tf;
				}
			}
		}
		_lastScored = scored;
	}

	// ⭐ `onTrain` 이면 **학습 코퍼스를 채점한다**(회차 151) — ***일반화 간극***을 재는 자리다.
	//   ★ 이 트랙은 그것을 한 번도 안 쟀다: `mltp3d3` 이 학습 CE 를 봤지만 물음이 *"학습이 죽는 속도"*
	//     였고, `mltp3e0` 은 *"학습 CE 는 이 회차의 판정이 아니다"* 로 **명시적으로 배제**했고,
	//     `mltl1*` 전부(121~150)는 **`ReadLoss` 를 아예 안 쓴다**.
	//   ⭐ 그리고 **거의 공짜다** — `kNCtx == kPtCtx == 512` 라 풀 크기가 같아 배관이 그대로 맞는다.
	//   ⚠️ 학습 CE 는 **절대 성능으로 인용하지 않는다**(정의상 낙관적이다) — **간극만** 읽는다.
	static bool _UploadTest(uint32 mask, bool onTrain = false)
	{
		const MLTP3Ctx& C = onTrain ? _trA : _ptA;
		const uint32 n = onTrain ? kNCtx : kPtCtx;
		_Expand(C, n, mask, 1000u, _eVal[1], _eSym[1], _eTgt[1]);
		return _M.UploadPool(_eVal[1], _eTgt[1], kPtPool) && _M.UploadSymbolPool(_eSym[1], kPtPool);
	}

	static void _BodyBegin(RHI* rhi)
	{
		const uint32 c = _ACap(_arm);
		// ⭐ 용량이 팔마다 다르다 — `Setup` 이 아레나를 다시 잡는다.
		if (!_M.Setup(rhi, kSymA, kN, kAx14, kTime, kCapD[c], kCapL[c], kCapF[c]))
		{ _Fail("몸통 준비(용량)"); return; }
		if (_params[c] == 0u) { _params[c] = _M.Params(); _arena[c] = _M.ArenaUsed(); }
		_Expand(_trA, kNCtx, kMTrain, _AKeepQ(_arm), _eVal[0], _eSym[0], _eTgt[0]);
		if (_seed == 0u && _out == 0u) _nTrain[_arm] = (double)_lastScored / (double)kNCtx;
		if (!(_M.UploadPool(_eVal[0], _eTgt[0], kPoolSteps) && _M.UploadSymbolPool(_eSym[0], kPoolSteps)))
		{ _Fail("학습 풀 업로드"); return; }
		_step = 0u; _st = kBodyTrain;
	}

	static void _BodyTrain()
	{
		const uint32 nSteps = _ASteps(_arm);   // ⭐ 걸음도 팔이다
		if (_step >= nSteps)
		{
			_evalIdx = 0u;
			if (!_UploadTest(kMChange)) { _Fail("시험 풀 업로드"); return; }
			_gate.Begin(kPtPool); _st = kEval; return;
		}
		for (uint32 i = 0; i < kPerTick && _step < nSteps; ++i)
		{
			_M.SelectStep(_step % kPoolSteps);
			// ⭐ `lr` 도 팔이다(회차 152) — `AdamStep` 이 이미 배율을 받는다.
			if (!_M.Forward() || !_M.Backward() || !_M.AdamStep(_ALr(_arm), _AWd(_arm)))
			{ _Fail("몸통 스텝"); return; }
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
		_ce[_evalIdx][_out][_arm][_seed] = ce;

		if (++_evalIdx < kEvals)
		{
			uint32 m = kMKeep;
			bool onTrain = false;
			if (_evalIdx == 2u) m = kMShift;
			else if (_evalIdx == 3u) m = kMNew;
			else if (_evalIdx == 4u) { m = kMChange; onTrain = true; }   // ⭐ 학습 코퍼스 채점
			if (!_UploadTest(m, onTrain)) { _Fail("갈래 시험 풀 업로드"); return; }
			_gate.Begin(kPtPool); return;
		}

		LogA("[mlt] 🔧   %s 씨앗 %2u · 바깥 %u · **변화 %.5f** · 지속 %.5f · 밀림 %.5f · 새id %.5f · 학습표적 %.1f\n",
			_ArmName(_arm), _seed, _out,
			(double)_ce[0][_out][_arm][_seed], (double)_ce[1][_out][_arm][_seed],
			(double)_ce[2][_out][_arm][_seed], (double)_ce[3][_out][_arm][_seed], _nTrain[_arm]);

		if (++_arm < kArms) { _ToBody(); return; }
		_arm = 0u;
		if (++_out < kOut) { _ToBody(); return; }
		_out = 0u;
		_seedOk[_seed] = _finite;
		++_seed; _st = kEncInit;
	}

	static double _M2(uint32 e, uint32 a, uint32 s)
	{
		double v = 0.0;
		for (uint32 o = 0; o < kOut; ++o) v += (double)_ce[e][o][a][s];
		return v / (double)kOut;
	}
	static double _ArmMean(uint32 e, uint32 a)
	{
		double m = 0.0; uint32 n = 0u;
		for (uint32 s = 0; s < _seeds; ++s)
		{
			if (!_seedOk[s]) continue;
			m += _M2(e, a, s); ++n;
		}
		return (n == 0u) ? 0.0 : m / (double)n;
	}

	struct Pair { double d; double se; double t; double sdSeed; double sdRun; uint32 n; uint32 win; };
	// ⭐ 두 팔의 짝지은 차. `aX − aY`.
	static Pair _Paired(uint32 e, uint32 aX, uint32 aY)
	{
		Pair p{}; p.d = 0.0; p.se = 0.0; p.t = 0.0; p.sdSeed = 0.0; p.sdRun = 0.0; p.n = 0u; p.win = 0u;
		double dv[kSeedsMax]; double rs = 0.0;
		for (uint32 s = 0; s < _seeds; ++s)
		{
			if (!_seedOk[s]) continue;
			const double d = _M2(e, aX, s) - _M2(e, aY, s);
			dv[p.n] = d; p.d += d; ++p.n;
			if (d < 0.0) ++p.win;
			const double r0 = (double)_ce[e][0][aX][s] - (double)_ce[e][0][aY][s];
			const double r1 = (double)_ce[e][1][aX][s] - (double)_ce[e][1][aY][s];
			rs += Abs((float)(r1 - r0)) / 1.414213562;
		}
		if (p.n == 0u) return p;
		p.d /= (double)p.n;
		double vv = 0.0;
		for (uint32 i = 0; i < p.n; ++i) { const double e2 = dv[i] - p.d; vv += e2 * e2; }
		p.sdSeed = (p.n > 1u) ? Sqrt((float)(vv / (double)(p.n - 1u))) : 0.0;
		p.sdRun = rs / (double)p.n;
		const double v = (p.sdSeed * p.sdSeed) / (double)p.n
			+ (p.sdRun * p.sdRun) / ((double)p.n * (double)kOut);
		p.se = Sqrt((float)v);
		p.t = (p.se > 1.0e-12) ? (Abs(p.d) / p.se) : 0.0;
		return p;
	}

	// ⭐ **일반화 간극의 짝지음** — 같은 팔 안에서 `시험(갈래 0) − 학습(갈래 4)`.
	//   ★ 같은 모델·같은 걸음이라 **가장 깨끗한 짝지음**이다(씨앗 변동이 통째로 상쇄된다).
	static Pair _PairedGapTT(uint32 a)
	{
		Pair p{}; p.d = 0.0; p.se = 0.0; p.t = 0.0; p.sdSeed = 0.0; p.sdRun = 0.0; p.n = 0u; p.win = 0u;
		double dv[kSeedsMax]; double rs = 0.0;
		for (uint32 s = 0; s < _seeds; ++s)
		{
			if (!_seedOk[s]) continue;
			const double d = _M2(0u, a, s) - _M2(4u, a, s);
			dv[p.n] = d; p.d += d; ++p.n;
			if (d < 0.0) ++p.win;
			const double r0 = (double)_ce[0][0][a][s] - (double)_ce[4][0][a][s];
			const double r1 = (double)_ce[0][1][a][s] - (double)_ce[4][1][a][s];
			rs += Abs((float)(r1 - r0)) / 1.414213562;
		}
		if (p.n == 0u) return p;
		p.d /= (double)p.n;
		double vv = 0.0;
		for (uint32 i = 0; i < p.n; ++i) { const double e2 = dv[i] - p.d; vv += e2 * e2; }
		p.sdSeed = (p.n > 1u) ? Sqrt((float)(vv / (double)(p.n - 1u))) : 0.0;
		p.sdRun = rs / (double)p.n;
		const double v = (p.sdSeed * p.sdSeed) / (double)p.n
			+ (p.sdRun * p.sdRun) / ((double)p.n * (double)kOut);
		p.se = Sqrt((float)v);
		p.t = (p.se > 1.0e-12) ? (Abs(p.d) / p.se) : 0.0;
		return p;
	}

	// ⭐ **두 팔의 「간극」 차** — `간극(aX) − 간극(aY)`(간극 = 시험 − 학습). 회차 154 의 기제 자다.
	//   ★ 씨앗마다 두 간극을 만들어 짝짓는다 ⇒ 씨앗 변동이 상쇄된다.
	static Pair _PairedGapDiff(uint32 aX, uint32 aY)
	{
		Pair p{}; p.d = 0.0; p.se = 0.0; p.t = 0.0; p.sdSeed = 0.0; p.sdRun = 0.0; p.n = 0u; p.win = 0u;
		double dv[kSeedsMax]; double rs = 0.0;
		for (uint32 s = 0; s < _seeds; ++s)
		{
			if (!_seedOk[s]) continue;
			const double gX = _M2(0u, aX, s) - _M2(4u, aX, s);
			const double gY = _M2(0u, aY, s) - _M2(4u, aY, s);
			const double d = gX - gY;
			dv[p.n] = d; p.d += d; ++p.n;
			if (d < 0.0) ++p.win;
			const double r0 = ((double)_ce[0][0][aX][s] - (double)_ce[4][0][aX][s])
			                - ((double)_ce[0][0][aY][s] - (double)_ce[4][0][aY][s]);
			const double r1 = ((double)_ce[0][1][aX][s] - (double)_ce[4][1][aX][s])
			                - ((double)_ce[0][1][aY][s] - (double)_ce[4][1][aY][s]);
			rs += Abs((float)(r1 - r0)) / 1.414213562;
		}
		if (p.n == 0u) return p;
		p.d /= (double)p.n;
		double vv = 0.0;
		for (uint32 i = 0; i < p.n; ++i) { const double e2 = dv[i] - p.d; vv += e2 * e2; }
		p.sdSeed = (p.n > 1u) ? Sqrt((float)(vv / (double)(p.n - 1u))) : 0.0;
		p.sdRun = rs / (double)p.n;
		const double v = (p.sdSeed * p.sdSeed) / (double)p.n
			+ (p.sdRun * p.sdRun) / ((double)p.n * (double)kOut);
		p.se = Sqrt((float)v);
		p.t = (p.se > 1.0e-12) ? (Abs(p.d) / p.se) : 0.0;
		return p;
	}

	// ⭐ **간격의 짝지은 차** — `(q1−q0)@capX − (q1−q0)@capY`. 씨앗마다 간격을 만들어 짝짓는다.
	static Pair _GapPaired(uint32 capX, uint32 capY)
	{
		Pair p{}; p.d = 0.0; p.se = 0.0; p.t = 0.0; p.sdSeed = 0.0; p.sdRun = 0.0; p.n = 0u; p.win = 0u;
		double dv[kSeedsMax]; double rs = 0.0;
		const uint32 aX1 = capX * kQs + 0u, aX0 = capX * kQs + 1u;
		const uint32 aY1 = capY * kQs + 0u, aY0 = capY * kQs + 1u;
		for (uint32 s = 0; s < _seeds; ++s)
		{
			if (!_seedOk[s]) continue;
			const double gX = _M2(0u, aX1, s) - _M2(0u, aX0, s);
			const double gY = _M2(0u, aY1, s) - _M2(0u, aY0, s);
			const double d = gX - gY;
			dv[p.n] = d; p.d += d; ++p.n;
			if (d < 0.0) ++p.win;
			const double r0 = ((double)_ce[0][0][aX1][s] - (double)_ce[0][0][aX0][s])
			                - ((double)_ce[0][0][aY1][s] - (double)_ce[0][0][aY0][s]);
			const double r1 = ((double)_ce[0][1][aX1][s] - (double)_ce[0][1][aX0][s])
			                - ((double)_ce[0][1][aY1][s] - (double)_ce[0][1][aY0][s]);
			rs += Abs((float)(r1 - r0)) / 1.414213562;
		}
		if (p.n == 0u) return p;
		p.d /= (double)p.n;
		double vv = 0.0;
		for (uint32 i = 0; i < p.n; ++i) { const double e2 = dv[i] - p.d; vv += e2 * e2; }
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
		LogA("[mlt] 🔧 **회차 150 · 용량을 올리면 파레토 교환이 풀리나** (씨앗 %u/%u · 유한 %s)\n",
			ok, _seeds, _finite ? "✅" : "⛔");

		// ── ⓪ 배관 서명(규율 21 — 성능보다 먼저) ────────────────────
		LogA("[mlt] 🔧   ── ⓪ **배관 서명** — 파라미터가 손계산과 맞나 ──\n");
		bool gHand = true;
		for (uint32 c = 0; c < kCaps; ++c)
		{
			// ⚠️ **이 모드가 안 쓴 용량은 건너뛴다** — `_params[c] == 0` 이면 `Setup` 을 안 불렀다.
			//   ★ 안 건너뛰면 배관 관문이 «⛔ 다르다» 를 내고 **오해를 만든다**(회차 151 진단에서 밟았다).
			if (_params[c] == 0u) continue;
			const uint32 h = _ParamHand(kCapD[c], kCapF[c], kCapL[c]);
			const bool okH = (_params[c] == h);
			if (!okH) gHand = false;
			LogA("[mlt] 🔧     d=%3u F=%3u 층=%u │ 실측 **%u** ↔ 손계산 **%u** │ 아레나 %u float(%.1f MB) │ %s\n",
				kCapD[c], kCapF[c], kCapL[c], _params[c], h,
				_arena[c], (double)_arena[c] * 4.0 / 1048576.0, okH ? "✅" : "⛔ **다르다**");
		}

		// ── ① 팔별 CE ──────────────────────────────────────────────
		LogA("[mlt] 🔧   ── ① **팔별 CE**(목표선 변화 < %.4f) ──\n", (double)kTarget);
		LogA("[mlt] 🔧     팔                      │ 걸음 │ 학습표적 │ **변화** · 지속 · 밀림 · 새id\n");
		double ch[kArmsMax], ke[kArmsMax];
		for (uint32 a = 0; a < kArms; ++a)
		{
			ch[a] = _ArmMean(0u, a); ke[a] = _ArmMean(1u, a);
			LogA("[mlt] 🔧     %s │%5u │ %6.1f  │ **%.4f** · %.4f · %.4f · %.4f\n",
				_ArmName(a), _ASteps(a), _nTrain[a], ch[a], ke[a], _ArmMean(2u, a), _ArmMean(3u, a));
		}

		// ── ⭐ 일반화 간극(회차 151 · 이 트랙이 처음 갖는 자) ──────
		LogA("[mlt] 🔧   ── ①b ⭐ **일반화 간극** = 시험 변화CE − **학습** 변화CE ──\n");
		LogA("[mlt] 🔧      ⚠️ 학습 CE 는 **절대 성능으로 인용하지 않는다**(정의상 낙관적) — **간극만** 읽는다\n");
		for (uint32 a = 0; a < kArms; ++a)
		{
			const double tr = _ArmMean(4u, a);
			const Pair p = _PairedGapTT(a);
			LogA("[mlt] 🔧     %s │ 학습 %.4f → 시험 %.4f │ **간극 %+.4f** │ SE %.5f · |d̄|/SE %6.2f\n",
				_ArmName(a), tr, ch[a], ch[a] - tr, p.se, p.t);
		}

		// ── ⭐ weight decay 모드(회차 154)는 여기서 끝난다 ────────────
		if (_wdMode)
		{
			// ⚠️ 문턱은 **회차 153 이 잰 상수**다(이 회차엔 새 배치의 `q=1.00` 팔이 없다).
			const double th = (double)kTh153;
			LogA("[mlt] 🧲   ── ② ⭐ **미달**(목표선 %.4f · 문턱 %.4f — 153 이 잰 상수) ──\n",
				(double)kTarget, th);
			LogA("[mlt] 🧲     팔                       │ **변화** · **지속** │ 간극 │ **미달** │ 통과\n");
			double shBest = 1.0e9; uint32 argBest = 1u; uint32 nPass = 0u;
			for (uint32 a = 0; a < kArms; ++a)
			{
				const double ex1 = (ch[a] > (double)kTarget) ? (ch[a] - (double)kTarget) : 0.0;
				const double ex2 = (ke[a] > th) ? (ke[a] - th) : 0.0;
				const double sh = ex1 + ex2;
				const bool okA = (a >= 1u) && (sh <= 0.0);
				if (okA) ++nPass;
				if (a >= 1u && sh < shBest) { shBest = sh; argBest = a; }
				LogA("[mlt] 🧲     %s │ **%.4f** · **%.4f** │ %+.4f │ **%.4f** │ %s\n",
					_ArmName(a), ch[a], ke[a], ch[a] - _ArmMean(4u, a), sh,
					okA ? "⭐ **통과**" : (a == 0u ? "(검산)" : "⛔"));
			}
			LogA("[mlt] 🧲   ── ②b ⭐ **눈금** — 145 %.3f → 153 %.4f → **이 회차 %.4f**(%s) ⇒ 도달률 **%.0f%%**\n",
				(double)kShort145, (double)kShort153, shBest, _ArmName(argBest),
				100.0 * (1.0 - shBest / (double)kShort145));
			// ⭐ 기제 — `wd` 가 간극을 줄이나(짝지어)
			LogA("[mlt] 🧲   ── ③ ⭐ **기제 — `wd` 가 간극을 줄이나**(같은 `q` 에서 wd=0 대비 · 음수 = 줄었다) ──\n");
			{
				const uint32 base25 = 1u, base10 = 4u;
				for (uint32 a = 2; a <= 3; ++a)
				{
					const Pair p = _PairedGapDiff(a, base25);
					LogA("[mlt] 🧲     %s − ㈁ │ Δ간극 %+.5f · SE %.5f · **|d̄|/SE %5.2f** · %u/%u\n",
						_ArmName(a), p.d, p.se, p.t, p.win, p.n);
				}
				for (uint32 a = 5; a <= 6; ++a)
				{
					const Pair p = _PairedGapDiff(a, base10);
					LogA("[mlt] 🧲     %s − ㈄ │ Δ간극 %+.5f · SE %.5f · **|d̄|/SE %5.2f** · %u/%u\n",
						_ArmName(a), p.d, p.se, p.t, p.win, p.n);
				}
			}
			double runS = 0.0; uint32 runN2 = 0u, runZ = 0u;
			for (uint32 s = 0; s < _seeds; ++s)
			{
				if (!_seedOk[s]) continue;
				for (uint32 a = 0; a < kArms; ++a)
				{
					const double d = Abs((float)((double)_ce[0][1][a][s] - (double)_ce[0][0][a][s]));
					runS += d; ++runN2; if (d == 0.0) ++runZ;
				}
			}
			LogA("[mlt] 🧲   ── ④ **`sd_run`** — 비트 동일 **%u/%u** · 평균 |Δ| **%.3e**\n",
				runZ, runN2, (runN2 == 0u) ? 0.0 : runS / (double)runN2);

			// 관문
			const bool ap = (_seeds >= 3u);
			const double cA = Abs((float)(ch[0] - (double)kCE145A));
			const double r25 = Abs((float)(ch[1] - (double)kCE153q25));
			const double r10 = Abs((float)(ch[4] - (double)kCE153q10));
			const bool gChk = !ap || (cA <= 0.05);
			const bool gRep = !ap || (r25 <= 0.05 && r10 <= 0.05);
			LogA("[mlt] 🧲   ── 관문 ──\n");
			LogA("[mlt] 🧲     ⭐ **배관**(파라미터 = 손계산) → %s\n", gHand ? "✅" : "⛔");
			LogA("[mlt] 🧲     ⭐ **검산** — ㈀ %.4f(↔%.4f · 차 %.4f) → %s\n",
				ch[0], (double)kCE145A, cA,
				!ap ? "⚠️ 건너뜀(규율 51)" : (gChk ? "✅" : "⛔ **배치가 다르다**"));
			LogA("[mlt] 🧲     ⭐ **재현 둘** — ㈁ %.4f(↔%.4f · 차 %.4f) · ㈄ %.4f(↔%.4f · 차 %.4f) → %s\n",
				ch[1], (double)kCE153q25, r25, ch[4], (double)kCE153q10, r10,
				!ap ? "⚠️ 건너뜀" : (gRep ? "✅" : "⛔ **153 과 다르다**"));
			LogA("[mlt] 🧲     ⭐ **표제** — 미달이 0 인 팔 **%u 개** → %s\n",
				nPass, (nPass > 0u) ? "✅" : "⛔");
			LogA("[mlt] 🧲     ⭐ **부표제** — 미달이 153 의 %.4f 보다 작나 → %s\n",
				(double)kShort153, (shBest < (double)kShort153) ? "⭐ **작다**" : "⛔ 아니다");
			if (!_finite || ok < _seeds)
				LogA("[mlt] 🧲   ⭐ 판정 = ⛔ **판정불가** — 배관이 안 섰다\n");
			else if (!gChk)
				LogA("[mlt] 🧲   ⭐ 판정 = ⛔ **판정불가** — ***검산이 깨졌다***\n");
			else if (_seeds == 1u)
				LogA("[mlt] 🧲   ⭐ **1씨앗 진단이다 — 판정하지 않는다**(규율 51) — 부호만: 미달 %.4f(%s)\n",
					shBest, (shBest < (double)kShort153) ? "⭐ 줄었다" : "⛔ 안 줄었다");
			else if (nPass > 0u)
				LogA("[mlt] 🧲   ⭐ 판정 = ⭐ ***파레토가 겹친다 — `wd` 가 지웠다***(%s)\n"
				     "[mlt] 🧲      ⇒ ★ 145·146·149 의 「무엇을 배우든 잃는다」가 **조건부로 확정**된다\n",
				     _ArmName(argBest));
			else if (shBest < (double)kShort153)
				LogA("[mlt] 🧲   ⭐ 판정 = 🔶 **더 가까워졌다**(%.4f → **%.4f** · 145 대비 **%.0f%%**)\n"
				     "[mlt] 🧲      ⇒ ★ `wd` 가 방향은 맞지만 **부족하다** ⇒ 다음 손잡이(`kNCtx` · `kBatch`)로 간다\n",
				     (double)kShort153, shBest, 100.0 * (1.0 - shBest / (double)kShort145));
			else
				LogA("[mlt] 🧲   ⭐ 판정 = ⛔ **`wd` 는 이 자리가 아니다**(미달 %.4f ≥ 153 의 %.4f)\n"
				     "[mlt] 🧲      ⇒ ★ 정칙화가 **지속 축을 돕지 않는다** — 그것은 *학습하지 않는 축*이다\n"
				     "[mlt] 🧲      ⇒ ⭐ 다음 손잡이 = **`kNCtx`**(문맥 수 — 시험 지속을 직접 돕는다)\n",
				     shBest, (double)kShort153);
			LogA("[mlt] 🧲   ⚠️ 문맥 학습 %u · 시험 %u · %u걸음 — 절대 성능으로 인용하지 않는다\n",
				kNCtx, kPtCtx, kStepsBase);
			LogA("[mlt] ══════════════════════════════════════════════════\n");
			_E.Destroy(); _done = true; return;
		}

		// ── ⭐ 파레토 모드(회차 153)는 여기서 끝난다 ──────────────
		if (_parMode)
		{
			// ⭐ 지속 문턱 = **그 배치의 `q=1.00` 지속 CE × 2**(미리 정의한 **규칙**이다)
			const double thOld = 2.0 * ke[0];   // ㈀ = 옛 배치 q=1.00
			const double thNew = 2.0 * ke[2];   // ㈂ = 새 배치 q=1.00
			LogA("[mlt] 🪢   ── ② ⭐ **파레토**(목표선 변화 < %.4f · 지속 < 문턱) ──\n", _Target());
			LogA("[mlt] 🪢      ⚠️ 문턱 = 그 배치의 `q=1.00` 지속 × 2 ⇒ **옛 %.4f** · **새 %.4f**\n", thOld, thNew);
			LogA("[mlt] 🪢     팔                    │ **변화** · **지속** │ 통과\n");
			uint32 nPassOld = 0u, nPassNew = 0u, firstNew = kArms;
			for (uint32 a = 0; a < kArms; ++a)
			{
				const bool isNew = (a >= 2u);
				const double th = isNew ? thNew : thOld;
				const bool okA = (ch[a] < _Target()) && (ke[a] < th);
				if (okA) { if (isNew) { ++nPassNew; if (firstNew == kArms) firstNew = a; } else ++nPassOld; }
				LogA("[mlt] 🪢     %s │ **%.4f** · **%.4f** │ 도달률 **%.4f** │ %s\n",
					_ArmName(a), ch[a], ke[a], _Reach(ch[a]), okA ? "⭐ **통과**" : "⛔");
			}
			// ── ⭐ 최소 미달 — *"겹치나"* 가 아니라 *"얼마나 가까워졌나"* ──
			double shortOld = 1.0e9, shortNew = 1.0e9;
			uint32 argOld = 0u, argNew = 2u;
			for (uint32 a = 0; a < kArms; ++a)
			{
				const bool isNew = (a >= 2u);
				const double th = isNew ? thNew : thOld;
				const double ex1 = (ch[a] > _Target()) ? (ch[a] - _Target()) : 0.0;
				const double ex2 = (ke[a] > th) ? (ke[a] - th) : 0.0;
				const double sh = ex1 + ex2;
				if (isNew) { if (sh < shortNew) { shortNew = sh; argNew = a; } }
				else       { if (sh < shortOld) { shortOld = sh; argOld = a; } }
			}
			LogA("[mlt] 🪢   ── ②b ⭐ **최소 미달** = min_q [ max(0, 변화−목표선) + max(0, 지속−문턱) ] ──\n");
			LogA("[mlt] 🪢      ★ *\"겹치나\"* 는 **이진**이고 이것은 **연속**이다 ⇒ *\"얼마나 가까워졌나\"*\n");
			LogA("[mlt] 🪢     옛 배치(이 실행) │ **%.4f**(%s) │ 새 배치 │ **%.4f**(%s)\n",
				shortOld, _ArmName(argOld), shortNew, _ArmName(argNew));
			if (!_deltaOn)
				LogA("[mlt] 🪢     ⭐ 회차 145(12씨앗 · 손계산) **%.3f** ↔ 새 배치 **%.4f** ⇒ %s\n",
					(double)kShort145, shortNew,
					(shortNew < (double)kShort145) ? "⭐ **가까워졌다**" : "⛔ 안 가까워졌다");
			else
				LogA("[mlt] 🪢     ⚠️ 145·153 의 미달(0.281 · 0.1409)은 **절대판 값**이라 견주지 않는다(규율 57)\n");
			// ── ⭐ 도달률 요약 — ★ 표현이 달라도 견줄 수 있는 유일한 자 ──
			// ⭐ 기준 팔 = **최소 미달 팔**(규율 54 와 같은 자)
			//   ⚠️⚠️ 회차 161 이 고쳤다 — 예전 규칙(*"문턱을 지키는 팔 중 도달률 최고"*)은
			//     **도달률이 `q` 에 단조 증가**하므로 **문턱을 아슬하게 지키는 보수적인 팔**을 고른다.
			//     ★ 도달률은 「변화 CE」만 보므로 **단독으로는 자가 아니다** — 파레토의 다른 축을 안 본다.
			const uint32 argReach = argNew;
			const double reachBest = _Reach(ch[argReach]);
			const bool haveReach = true;
			// 보조: 문턱을 지키는 팔 중 최고(참고용 — 판정에 안 쓴다)
			double reachSafe = -1.0e9; uint32 argSafe = kArms;
			for (uint32 a = 2u; a < kArms; ++a)
				if (ke[a] < thNew && _Reach(ch[a]) > reachSafe) { reachSafe = _Reach(ch[a]); argSafe = a; }
			LogA("[mlt] 🪢   ── ②c ⭐ **도달률**(바닥 %.4f · 목표선 %.4f) ──\n",
				(double)kUniform, _Target());
			LogA("[mlt] 🪢      ★ **1.0 이면 목표선** · 절대판 최선(153 의 q=0.25) = **%.4f**\n", (double)kReachAbs);
			LogA("[mlt] 🪢      ⚠️ 도달률은 **변화 CE 만** 본다 ⇒ `q` 에 단조 증가한다 ⇒ **단독으로는 자가 아니다**\n");
			LogA("[mlt] 🪢      ★ 그래서 기준 팔은 ***최소 미달 팔***이다(규율 54 와 같은 자)\n");
			LogA("[mlt] 🪢     ⭐ **최소 미달 팔** = %s · 도달률 **%.4f** ⇒ 절대판(%.4f) 대비 **%+.4f** %s\n",
				_ArmName(argReach), reachBest, (double)kReachAbs, reachBest - (double)kReachAbs,
				(reachBest > (double)kReachAbs) ? "⭐ **낫다**" : "⛔ 낮다");
			if (argSafe < kArms)
				LogA("[mlt] 🪢     ⓘ 보조(판정에 안 쓴다) — 문턱을 지키는 최고 = %s · %.4f\n",
					_ArmName(argSafe), reachSafe);
			else
				LogA("[mlt] 🪢     ⓘ 보조 — 문턱을 지키는 팔이 **하나도 없다**\n");

			// ⭐ 교환율 — 새 배치의 인접 `q` 사이
			LogA("[mlt] 🪢   ── ③ ⭐ **교환율**(Δ지속 / Δ변화 · 새 배치의 인접 `q`) ──\n");
			for (uint32 a = 3u; a < kArms; ++a)
			{
				const double dCh = ch[a] - ch[a - 1u];
				const double dKe = ke[a] - ke[a - 1u];
				LogA("[mlt] 🪢     q %.2f → %.2f │ Δ변화 %+.4f · Δ지속 %+.4f │ 교환율 **%.1f**\n",
					(double)_AKeepQ(a - 1u) / 1000.0, (double)_AKeepQ(a) / 1000.0,
					dCh, dKe, (Abs((float)dCh) > 1.0e-9) ? Abs((float)(dKe / dCh)) : 0.0);
			}
			// ⭐ 같은 `q` 에서 새 배치가 옛 배치를 이기나(곡선이 내려갔나)
			LogA("[mlt] 🪢   ── ④ ⭐ **곡선이 내려갔나**(같은 `q` 에서 새 − 옛 · 음수 = 새가 낫다) ──\n");
			{
				const Pair p1 = _Paired(0u, 2u, 0u);   // q=1.00
				const Pair p0 = _Paired(0u, 6u, 1u);   // q=0.00
				LogA("[mlt] 🪢     q=1.00 │ d̄ %+.5f · SE %.5f · **|d̄|/SE %5.2f** · %u/%u\n",
					p1.d, p1.se, p1.t, p1.win, p1.n);
				LogA("[mlt] 🪢     q=0.00 │ d̄ %+.5f · SE %.5f · **|d̄|/SE %5.2f** · %u/%u\n",
					p0.d, p0.se, p0.t, p0.win, p0.n);
			}
			double runS = 0.0; uint32 runN2 = 0u, runZ = 0u;
			for (uint32 s = 0; s < _seeds; ++s)
			{
				if (!_seedOk[s]) continue;
				for (uint32 a = 0; a < kArms; ++a)
				{
					const double d = Abs((float)((double)_ce[0][1][a][s] - (double)_ce[0][0][a][s]));
					runS += d; ++runN2; if (d == 0.0) ++runZ;
				}
			}
			LogA("[mlt] 🪢   ── ⑤ **`sd_run`** — 비트 동일 **%u/%u** · 평균 |Δ| **%.3e**\n",
				runZ, runN2, (runN2 == 0u) ? 0.0 : runS / (double)runN2);

			// 관문
			const bool ap = (_seeds >= 3u);
			const double cA = Abs((float)(ch[0] - (double)kCE145A));
			const double cB = Abs((float)(ch[1] - (double)kCE145E));
			const double cR = Abs((float)(ch[6] - 1.6770));
			// ⭐ 회차 161 이 더한 재현 둘 — 등록문이 약속한 값이다(153 의 q=0.25 · q=0.10)
			const double c25 = Abs((float)(ch[4] - (double)kCE153q25));
			const double c10 = Abs((float)(ch[5] - (double)kCE153q10));
			const double cTh = Abs((float)(thNew - (double)kTh153));
			const double cSh = Abs((float)(shortNew - (double)kShort153));
			// ⚠️⚠️ 규율 57 — 델타 팔에서는 이 검산이 전부 **옛 표현의 값**이라 적용하지 않는다
			const bool ap2 = ap && !_deltaOn;
			const bool gChk = !ap2 || (cA <= 0.05 && cB <= 0.05);
			const bool gRep = !ap2 || (cR <= 0.05);
			LogA("[mlt] 🪢   ── 관문 ──\n");
			LogA("[mlt] 🪢     ⭐ **배관**(파라미터 = 손계산) → %s\n", gHand ? "✅" : "⛔");
			if (_deltaOn)
				LogA("[mlt] 🪢     ⚠️⚠️ **검산 건너뜀** — 이 하네스의 상수 아홉 개가 **절대판 값**이다(규율 57)\n"
				     "[mlt] 🪢        ★ 배관 증거는 **회차 159·160 이 두 번 낸 델타 서명**(변화 표적 42.2 · H 3.2574)이다\n");
			else
			{
				LogA("[mlt] 🪢     ⭐ **검산 둘** — ㈀ %.4f(↔%.4f · 차 %.4f) · ㈁ %.4f(↔%.4f · 차 %.4f) → %s\n",
					ch[0], (double)kCE145A, cA, ch[1], (double)kCE145E, cB,
					!ap ? "⚠️ 건너뜀(규율 51)" : (gChk ? "✅" : "⛔ **배치가 다르다**"));
				LogA("[mlt] 🪢     ⭐ **재현** — ㈆ %.4f(↔ 152 의 1.6770 · 차 %.4f) → %s\n",
					ch[6], cR, !ap ? "⚠️ 건너뜀" : (gRep ? "✅" : "⛔ **152 와 다르다**"));
				LogA("[mlt] 🪢     ⭐ **재현 넷(161 이 더했다)** — q=0.25 %.4f(↔%.4f·%.4f) · q=0.10 %.4f(↔%.4f·%.4f)\n"
				     "[mlt] 🪢        문턱 %.4f(↔%.4f·%.4f) · 최소 미달 %.4f(↔%.4f·%.4f) → %s\n",
					ch[4], (double)kCE153q25, c25, ch[5], (double)kCE153q10, c10,
					thNew, (double)kTh153, cTh, shortNew, (double)kShort153, cSh,
					(c25 <= 0.02 && c10 <= 0.02 && cTh <= 0.02 && cSh <= 0.02) ? "✅ 넷 다" : "⚠️ 하나 이상 어긋난다");
			}
			LogA("[mlt] 🪢     ⭐ **표제** — 새 배치의 통과 점 **%u 개**(옛 배치 %u 개) → %s\n",
				nPassNew, nPassOld, (nPassNew > 0u) ? "✅" : "⛔");
			if (!_finite || ok < _seeds)
				LogA("[mlt] 🪢   ⭐ 판정 = ⛔ **판정불가** — 배관이 안 섰다\n");
			else if (!gChk)
				LogA("[mlt] 🪢   ⭐ 판정 = ⛔ **판정불가** — ***검산이 깨졌다***\n");
			else if (_seeds == 1u)
				LogA("[mlt] 🪢   ⭐ **1씨앗 진단이다 — 판정하지 않는다**(규율 51) — 부호만: 새 배치 통과 점 %u 개\n",
					nPassNew);
			else if (_deltaOn)
				LogA("[mlt] 🪢   ⭐ 판정 = %s — **델타판 도달률 %.4f** ↔ 절대판 최선 **%.4f**\n"
				     "[mlt] 🪢      통과 점 **%u 개** · 최소 미달 **%.4f** · 문턱 **%.4f**(=그 배치 규칙)\n"
				     "[mlt] 🪢      ⇒ ★ 목표선 통과 = 도달률 **> 1.0** · 절대보다 낫다 = **> %.4f**\n",
					(nPassNew > 0u) ? "⭐ ***파레토가 겹친다 — 델타판이 두 조건을 함께 만족한다***"
						: ((reachBest > 1.0) ? "⭐ ***목표선은 넘었다***(지속은 문턱 초과)"
							: ((reachBest > (double)kReachAbs) ? "⭐ **절대보다 낫지만 목표선은 못 넘었다**"
								: "⛔ **절대보다 낮다**")),
					haveReach ? reachBest : 0.0, (double)kReachAbs,
					nPassNew, shortNew, thNew, (double)kReachAbs);
			else if (nPassNew > 0u)
				LogA("[mlt] 🪢   ⭐ 판정 = ⭐ ***파레토가 겹친다 — 배치의 성질이었다***(%s · 변화 %.4f · 지속 %.4f)\n"
				     "[mlt] 🪢      ⇒ ★ 그러면 **145·146·149 의 「무엇을 배우든 그만큼 잃는다」가 조건부가 된다**\n"
				     "[mlt] 🪢      ⇒ ⭐ 그리고 그 셋을 새 배치에서 **다시 재야 한다**\n",
				     _ArmName(firstNew), ch[firstNew], ke[firstNew]);
			else if (shortNew < (double)kShort145)
				LogA("[mlt] 🪢   ⭐ 판정 = 🔶 **통과 점은 0 인데 가까워졌다** — 최소 미달 **%.3f → %.4f**(145 대비 **%.0f%%**)\n"
				     "[mlt] 🪢      ⇒ ★ **파레토는 남지만 「모델의 성질」이라고 말할 수 없다** — 배치가 그것을 움직인다\n"
				     "[mlt] 🪢      ⇒ ⭐ 그러면 145·146·149 는 ***강화도 조건부도 아니고 「정도의 문제」***가 된다\n"
				     "[mlt] 🪢      ⇒ ⭐ 다음 물음: **아직 안 흔든 손잡이가 이것을 0 으로 만드나**(규율 53 — `kNCtx` · `kBatch` · Adam)\n",
				     (double)kShort145, shortNew, 100.0 * shortNew / (double)kShort145);
			else
				LogA("[mlt] 🪢   ⭐ 판정 = ⛔ **통과 점이 0 이고 가까워지지도 않았다**(최소 미달 %.4f ↔ 145 의 %.3f)\n"
				     "[mlt] 🪢      ⇒ ★ 그러면 ***파레토는 모델의 성질이다*** — **145·146·149 가 강화된다**\n"
				     "[mlt] 🪢      ⇒ ⭐ 남는 처방은 **세계**(표적 구조)다\n",
				     shortNew, (double)kShort145);
			LogA("[mlt] 🪢   ⚠️ 문맥 학습 %u · 시험 %u · %u걸음 — 절대 성능으로 인용하지 않는다\n",
				kNCtx, kPtCtx, kStepsBase);
			LogA("[mlt] ══════════════════════════════════════════════════\n");
			_E.Destroy(); _done = true; return;
		}

		// ── ⭐ 학습률 모드(회차 152)는 여기서 끝난다 ─────────────────
		//   ⚠️ **표제 자가 「학습 CE」다** — 이 트랙에서 처음이다.
		if (_lrMode)
		{
			LogA("[mlt] 📉   ── ② ⭐ **학습 CE**(표제) — 기준(㈀) 대비 짝지은 차 · 음수 = 이긴다 ──\n");
			double tr[kArmsMax];
			for (uint32 a = 0; a < kArms; ++a) tr[a] = _ArmMean(4u, a);
			uint32 best = 0u;
			for (uint32 a = 1; a < kArms; ++a) if (tr[a] < tr[best]) best = a;
			for (uint32 a = 0; a < kArms; ++a)
			{
				if (a == 0u)
				{
					LogA("[mlt] 📉     %s │ 학습 **%.4f** │ 시험 %.4f │ 간극 %+.4f │ (기준)\n",
						_ArmName(a), tr[a], ch[a], ch[a] - tr[a]);
					continue;
				}
				const Pair pl = _Paired(4u, a, 0u);   // 학습 CE 짝지은 차
				const Pair ps = _Paired(0u, a, 0u);   // 시험 CE 짝지은 차
				LogA("[mlt] 📉     %s │ 학습 **%.4f**(d̄ %+.5f · **%5.2f** · %u/%u) │ 시험 %.4f(d̄ %+.5f · %5.2f · %u/%u) │ 간극 %+.4f\n",
					_ArmName(a), tr[a], pl.d, pl.t, pl.win, pl.n,
					ch[a], ps.d, ps.t, ps.win, ps.n, ch[a] - tr[a]);
			}
			LogA("[mlt] 📉   ── ③ ⭐ **용량마다 최적 `lr`**(학습 CE 가 가장 낮은 팔) ──\n");
			LogA("[mlt] 📉     ●폭 d=192 — lr×1 **%.4f** · ×0.5 **%.4f** · ×0.25 **%.4f** ⇒ 최적 **×%.2f**\n",
				tr[1], tr[2], tr[3],
				(double)((tr[1] <= tr[2] && tr[1] <= tr[3]) ? kLrMul[1]
					: ((tr[2] <= tr[3]) ? kLrMul[2] : kLrMul[3])));
			LogA("[mlt] 📉     ⚫︎깊이 L=8 — lr×1 **%.4f** · ×0.5 **%.4f** · ×0.25 **%.4f** ⇒ 최적 **×%.2f**\n",
				tr[4], tr[5], tr[6],
				(double)((tr[4] <= tr[5] && tr[4] <= tr[6]) ? kLrMul[4]
					: ((tr[5] <= tr[6]) ? kLrMul[5] : kLrMul[6])));
			// ⭐ 부표제 — **시험** CE 에서 기준을 이기는 팔이 있나(그것이 진짜 이득이다)
			LogA("[mlt] 📉   ── ③b ⭐ **부표제 — 시험 CE 에서 기준을 이기는 팔**(학습만 좋아지면 과적합이다) ──\n");
			for (uint32 a = 1; a < kArms; ++a)
			{
				const Pair ps = _Paired(0u, a, 0u);
				if (ps.d < 0.0)
					LogA("[mlt] 📉     ⭐ %s │ 시험 d̄ %+.5f · |d̄|/SE **%5.2f** · %u/%u · 간극 %+.4f\n",
						_ArmName(a), ps.d, ps.t, ps.win, ps.n, ch[a] - tr[a]);
			}
			double runS = 0.0; uint32 runN2 = 0u, runZ = 0u;
			for (uint32 s = 0; s < _seeds; ++s)
			{
				if (!_seedOk[s]) continue;
				for (uint32 a = 0; a < kArms; ++a)
				{
					const double d = Abs((float)((double)_ce[0][1][a][s] - (double)_ce[0][0][a][s]));
					runS += d; ++runN2; if (d == 0.0) ++runZ;
				}
			}
			LogA("[mlt] 📉   ── ④ **`sd_run`** — 비트 동일 **%u/%u** · 평균 |Δ| **%.3e**\n",
				runZ, runN2, (runN2 == 0u) ? 0.0 : runS / (double)runN2);

			// 관문
			const bool apply3 = (_seeds >= 3u);
			const double cE3 = Abs((float)(ch[0] - (double)kCE145E));
			const bool gChk3 = !apply3 || (cE3 <= 0.05);
			const Pair pB = (best == 0u) ? Pair{} : _Paired(4u, best, 0u);
			const bool gT3 = (best != 0u) && (pB.d < 0.0) && (pB.t >= 2.0) && (pB.win >= _SignPass());
			LogA("[mlt] 📉   ── 관문 ──\n");
			LogA("[mlt] 📉     ⭐ **배관**(파라미터 = 손계산) → %s\n", gHand ? "✅" : "⛔");
			LogA("[mlt] 📉     ⭐ **검산** — ㈀ 시험 %.4f(↔%.4f · 차 %.4f) → %s\n",
				ch[0], (double)kCE145E, cE3,
				!apply3 ? "⚠️ 건너뜀(씨앗 3 이상 — 규율 51)" : (gChk3 ? "✅" : "⛔ **배치가 다르다**"));
			LogA("[mlt] 📉     ⚠️ 다중비교 — 팔 %u ⇒ 물음 Q≈8 ⇒ 표제 부호검정 **%u/12**\n", kArms, _SignPass());
			LogA("[mlt] 📉     ⭐ **표제** — 가장 좋은 팔(%s)의 학습 CE 가 기준을 이기나 · d̄ %+.5f · |d̄|/SE **%.2f** · %u/%u → %s\n",
				_ArmName(best), pB.d, pB.t, pB.win, pB.n, gT3 ? "✅" : "⛔");
			if (!_finite || ok < _seeds)
				LogA("[mlt] 📉   ⭐ 판정 = ⛔ **판정불가** — 배관이 안 섰다\n");
			else if (!gChk3)
				LogA("[mlt] 📉   ⭐ 판정 = ⛔ **판정불가** — ***검산이 깨졌다***\n");
			else if (_seeds == 1u)
				LogA("[mlt] 📉   ⭐ **1씨앗 진단이다 — 판정하지 않는다**(규율 51) — 부호만: 가장 좋은 팔이 %s\n",
					(best != 0u && tr[best] < tr[0]) ? "⭐ **기준을 이긴다** ⇒ ㉠ 학습률 쪽" : "⛔ **기준을 못 이긴다**");
			else if (gT3)
				LogA("[mlt] 📉   ⭐ 판정 = ⭐ ***㉠ 학습률이다*** — `lr` 을 맞추면 큰 모델이 학습에서 기준을 이긴다(%.4f < %.4f)\n"
				     "[mlt] 📉      ⇒ ★ 그러면 **150·151 의 모든 용량 결론이 「lr ×1 에서」** 이고 다시 재야 한다\n",
				     tr[best], tr[0]);
			else
				LogA("[mlt] 📉   ⭐ 판정 = ⛔ **㉠ 도 아니다** — 어느 `lr` 에서도 큰 모델이 학습에서 기준을 못 이긴다\n"
				     "[mlt] 📉      ⇒ ★ 남는 것은 **구조**뿐이다 ⇒ 처방은 **세계**다\n"
				     "[mlt] 📉      ⇒ ⭐ 그리고 그것이 ***로드맵 칸 1 을 못 벗어난 이유***의 가장 강한 후보가 된다\n");
			LogA("[mlt] 📉   ⚠️ 문맥 학습 %u · 시험 %u · %u걸음 — 절대 성능으로 인용하지 않는다\n",
				kNCtx, kPtCtx, kStepsBase);
			LogA("[mlt] ══════════════════════════════════════════════════\n");
			_E.Destroy(); _done = true; return;
		}

		// ── ⭐ 깊이 모드(회차 151)는 여기서 끝난다 ────────────────────
		//   ⚠️⚠️ **아래 ②(간격) 블록을 쓰면 안 된다** — 그것은 `a = c*kQs + q` 매핑을 가정하는데
		//     깊이 모드의 팔 표는 용량 {0,3,1} 이라 `c=3` 에서 `ch[7]` 을 읽어 **배열 범위를
		//     넘는다**(회차 151 진단에서 실제로 출력이 폭주했다 — ①·①b 는 그 앞이라 유효했다).
		if (_deepMode)
		{
			const uint32 aB1 = 0u, aB0 = 1u;   // 기준 d=128 L=4
			const uint32 aD1 = 2u, aD0 = 3u;   // ⭐ 깊이 L=8
			const uint32 aW1 = 4u, aW0 = 5u;   // 폭 d=192
			LogA("[mlt] 🔧   ── ② ⭐ **같은 예산에서 폭 ↔ 깊이**(음수 = 왼쪽이 낫다) ──\n");
			LogA("[mlt] 🔧      ★ 깊이 %u 파라미터 ↔ 폭 %u = **%.1f%% 차**(거의 같은 예산)\n",
				_params[3], _params[1],
				(_params[1] == 0u) ? 0.0
					: 100.0 * (1.0 - (double)_params[3] / (double)_params[1]));
			struct { const char* nm; uint32 e; } AX[4] = {
				{ "변화(바꾸기)", 0u }, { "지속(나르기)", 1u },
				{ "밀림(다른자리)", 2u }, { "새id", 3u } };
			for (uint32 i = 0; i < 4u; ++i)
			{
				const Pair pd = _Paired(AX[i].e, aD0, aB0);
				const Pair pw = _Paired(AX[i].e, aW0, aB0);
				const Pair dw = _Paired(AX[i].e, aD0, aW0);
				LogA("[mlt] 🔧     %-16s │ 깊이−기준 %+.5f(%5.2f · %u/%u) │ 폭−기준 %+.5f(%5.2f · %u/%u) │ ⭐ **깊이−폭 %+.5f(%5.2f · %u/%u)**\n",
					AX[i].nm, pd.d, pd.t, pd.win, pd.n, pw.d, pw.t, pw.win, pw.n,
					dw.d, dw.t, dw.win, dw.n);
			}
			LogA("[mlt] 🔧      (위는 `q=0.00` 팔 · 아래는 `q=1.00` 팔의 변화 축)\n");
			{
				const Pair pd = _Paired(0u, aD1, aB1);
				const Pair pw = _Paired(0u, aW1, aB1);
				const Pair dw = _Paired(0u, aD1, aW1);
				LogA("[mlt] 🔧     %-16s │ 깊이−기준 %+.5f(%5.2f · %u/%u) │ 폭−기준 %+.5f(%5.2f · %u/%u) │ ⭐ **깊이−폭 %+.5f(%5.2f · %u/%u)**\n",
					"변화(q=1.00)", pd.d, pd.t, pd.win, pd.n, pw.d, pw.t, pw.win, pw.n,
					dw.d, dw.t, dw.win, dw.n);
			}
			double runS = 0.0; uint32 runN2 = 0u, runZ = 0u;
			for (uint32 s = 0; s < _seeds; ++s)
			{
				if (!_seedOk[s]) continue;
				for (uint32 a = 0; a < kArms; ++a)
				{
					const double d = Abs((float)((double)_ce[0][1][a][s] - (double)_ce[0][0][a][s]));
					runS += d; ++runN2; if (d == 0.0) ++runZ;
				}
			}
			LogA("[mlt] 🔧   ── ③ **`sd_run`** — 비트 동일 **%u/%u** · 평균 |Δ| **%.3e**\n",
				runZ, runN2, (runN2 == 0u) ? 0.0 : runS / (double)runN2);

			// 관문
			const bool apply2 = (_seeds >= 3u);
			const double cA2 = Abs((float)(ch[aB1] - (double)kCE145A));
			const double cB2 = Abs((float)(ch[aB0] - (double)kCE145E));
			const bool gChk2 = !apply2 || (cA2 <= 0.05 && cB2 <= 0.05);
			const Pair pT = _Paired(0u, aD0, aW0);
			const bool gT = (pT.d < 0.0) && (pT.t >= 2.0);
			LogA("[mlt] 🔧   ── 관문 ──\n");
			LogA("[mlt] 🔧     ⭐ **배관**(파라미터 = 손계산) → %s\n", gHand ? "✅" : "⛔");
			LogA("[mlt] 🔧     ⭐ **검산 둘** — q=1.00 %.4f(↔%.4f · 차 %.4f) · q=0.00 %.4f(↔%.4f · 차 %.4f) → %s\n",
				ch[aB1], (double)kCE145A, cA2, ch[aB0], (double)kCE145E, cB2,
				!apply2 ? "⚠️ 건너뜀(씨앗 3 이상 — 규율 51)" : (gChk2 ? "✅" : "⛔ **배치가 다르다**"));
			LogA("[mlt] 🔧     ⭐ **표제** — 깊이가 폭보다 변화 CE 가 낮다(같은 예산) · d̄ %+.5f · |d̄|/SE **%.2f** → %s\n",
				pT.d, pT.t, gT ? "✅" : "⛔");
			if (!_finite || ok < _seeds)
				LogA("[mlt] 🔧   ⭐ 판정 = ⛔ **판정불가** — 배관이 안 섰다\n");
			else if (!gChk2)
				LogA("[mlt] 🔧   ⭐ 판정 = ⛔ **판정불가** — ***검산이 깨졌다***\n");
			else if (_seeds == 1u)
				LogA("[mlt] 🔧   ⭐ **1씨앗 진단이다 — 판정하지 않는다**(규율 51) — 부호만: 깊이가 폭을 %s\n",
					(pT.d < 0.0) ? "⭐ **이긴다** ⇒ 바꾸기는 깊이가 한다 쪽" : "⛔ 못 이긴다");
			else if (gT)
				LogA("[mlt] 🔧   ⭐ 판정 = ⭐ ***바꾸기는 깊이가 한다*** — 같은 예산에서 깊이가 폭을 %.4f 이긴다\n"
				     "[mlt] 🔧      ⇒ ★ 그리고 ㉣ 의 반쪽을 보라: **지속(나르기)** 축에서 폭이 낫고 깊이가 나쁘면\n"
				     "[mlt] 🔧         ***폭 = 나르기 · 깊이 = 바꾸기*** 가 확정된다\n",
				     -pT.d);
			else
				LogA("[mlt] 🔧   ⭐ 판정 = ⛔ **깊이도 아니다** — 같은 예산에서 깊이가 폭을 못 이긴다(d̄ %+.4f · |d̄|/SE %.2f)\n"
				     "[mlt] 🔧      ⇒ ★ 그러면 **구조가 아니라 과제**다 ⇒ 세계로 간다\n", pT.d, pT.t);
			LogA("[mlt] 🔧   ⚠️ 문맥 학습 %u · 시험 %u · %u걸음 — 절대 성능으로 인용하지 않는다\n",
				kNCtx, kPtCtx, kStepsBase);
			LogA("[mlt] ══════════════════════════════════════════════════\n");
			_E.Destroy(); _done = true; return;
		}

		// ── ⭐ 걸음 축 진단 모드는 여기서 끝난다(간격·단조성 관문이 적용되지 않는다) ──
		if (_stepMode)
		{
			LogA("[mlt] 🔧   ── ② ⭐ **걸음이 오르면 d=256 이 기준(d=128 ×1)을 이기나** ──\n");
			for (uint32 a = 1; a < kArms; ++a)
			{
				const Pair p = _Paired(0u, a, 0u);
				LogA("[mlt] 🔧     %s − 기준 │ d̄ %+.5f · SE %.5f · **|d̄|/SE %6.2f** · %u/%u %s\n",
					_ArmName(a), p.d, p.se, p.t, p.win, p.n,
					(p.d < 0.0) ? "⭐ **이긴다**" : "⛔ 진다");
			}
			double runS = 0.0; uint32 runN2 = 0u, runZ = 0u;
			for (uint32 s = 0; s < _seeds; ++s)
			{
				if (!_seedOk[s]) continue;
				for (uint32 a = 0; a < kArms; ++a)
				{
					const double d = Abs((float)((double)_ce[0][1][a][s] - (double)_ce[0][0][a][s]));
					runS += d; ++runN2; if (d == 0.0) ++runZ;
				}
			}
			LogA("[mlt] 🔧   ── ③ **`sd_run`** — 비트 동일 **%u/%u** · 평균 |Δ| **%.3e**\n",
				runZ, runN2, (runN2 == 0u) ? 0.0 : runS / (double)runN2);
			const bool wins = (ch[kArms - 1u] < ch[0]);
			LogA("[mlt] 🔧     ⭐ **배관**(파라미터 = 손계산) → %s\n", gHand ? "✅" : "⛔");
			if (_seeds == 1u)
				LogA("[mlt] 🔧   ⭐ **걸음 축 진단이다(1씨앗) — 판정하지 않는다**(규율 51) — 부호만: d=256 ×6걸음이 기준을 %s\n",
					wins ? "⭐ **이긴다** ⇒ ㉢ 최적화 부족 쪽" : "⛔ **못 이긴다** ⇒ ㉢ 이 아니다");
			else if (wins)
				LogA("[mlt] 🔧   ⭐ 판정 = ⭐ ***㉢ 최적화 부족이다*** — 걸음을 올리면 d=256 이 기준을 이긴다(%.4f < %.4f)\n"
				     "[mlt] 🔧      ⇒ ★ 12씨앗 판정을 **「같은 걸음-파라미터 예산」**으로 다시 설계한다\n",
				     ch[kArms - 1u], ch[0]);
			else
				LogA("[mlt] 🔧   ⭐ 판정 = ⛔ **㉢ 이 아니다** — 걸음 6배에도 d=256 이 기준을 못 이긴다(%.4f ≥ %.4f)\n"
				     "[mlt] 🔧      ⇒ ★ ㉠/㉡ 갈래로 돌아간다(용량이 답이 아니다)\n",
				     ch[kArms - 1u], ch[0]);
			LogA("[mlt] 🔧   ⚠️ 문맥 학습 %u · 시험 %u — 절대 성능으로 인용하지 않는다\n", kNCtx, kPtCtx);
			LogA("[mlt] ══════════════════════════════════════════════════\n");
			_E.Destroy(); _done = true; return;
		}

		// ── ② ⭐ 간격과 도달률(표제) ─────────────────────────────
		LogA("[mlt] 🔧   ── ② ⭐ **간격**(변화CE q=1.00 − q=0.00) · 도달률 = 간격 / %.4f ──\n",
			(double)kGap145);
		double gap[kCaps];
		for (uint32 c = 0; c < kCaps; ++c)
		{
			gap[c] = ch[c * kQs + 0u] - ch[c * kQs + 1u];
			LogA("[mlt] 🔧     d=%3u │ 간격 **%.4f** │ 도달률 **%.3f** │ q=1.00 %.4f · q=0.00 %.4f\n",
				kCapD[c], gap[c], gap[c] / (double)kGap145, ch[c * kQs + 0u], ch[c * kQs + 1u]);
		}
		LogA("[mlt] 🔧     ⭐ **간격의 짝지은 차**(음수 = 용량이 커서 간격이 줄었다) · SE 에 실행 항 ──\n");
		for (uint32 c = 1; c < kCaps; ++c)
		{
			const Pair p = _GapPaired(c, 0u);
			LogA("[mlt] 🔧       d=%3u − d=128 │ d̄ %+.5f · SE %.5f · **|d̄|/SE %6.2f** · %u/%u\n",
				kCapD[c], p.d, p.se, p.t, p.win, p.n);
		}

		// ── ③ 절대 CE 가 용량에 단조 감소하나(부표제) ────────────────
		LogA("[mlt] 🔧   ── ③ **절대 CE**(용량이 오르면 좋아지나) · 변화 축 ──\n");
		for (uint32 q = 0; q < kQs; ++q)
			for (uint32 c = 1; c < kCaps; ++c)
			{
				const Pair p = _Paired(0u, c * kQs + q, 0u * kQs + q);
				LogA("[mlt] 🔧     q=%.2f · d=%3u − d=128 │ d̄ %+.5f · SE %.5f · |d̄|/SE %6.2f · %u/%u\n",
					(double)kKeepQ[q] / 1000.0, kCapD[c], p.d, p.se, p.t, p.win, p.n);
			}

		// ── ④ 전이 — 갈래 둘이 「같이」 좋아지나 ─────────────────────
		LogA("[mlt] 🔧   ── ④ ⭐ **전이**(q=0.00 팔에서 밀림·새id 가 같이 좋아지나) ──\n");
		for (uint32 c = 1; c < kCaps; ++c)
		{
			const Pair ps = _Paired(2u, c * kQs + 1u, 1u);
			const Pair pn = _Paired(3u, c * kQs + 1u, 1u);
			LogA("[mlt] 🔧     d=%3u − d=128 │ 밀림 d̄ %+.5f(%.2f · %u/%u) · 새id d̄ %+.5f(%.2f · %u/%u)\n",
				kCapD[c], ps.d, ps.t, ps.win, ps.n, pn.d, pn.t, pn.win, pn.n);
		}

		// ── ⑤ 자가 결정적인가 ──────────────────────────────────────
		double runSum = 0.0; uint32 runN = 0u, runZero = 0u;
		for (uint32 s = 0; s < _seeds; ++s)
		{
			if (!_seedOk[s]) continue;
			for (uint32 a = 0; a < kArms; ++a)
			{
				const double d = Abs((float)((double)_ce[0][1][a][s] - (double)_ce[0][0][a][s]));
				runSum += d; ++runN; if (d == 0.0) ++runZero;
			}
		}
		LogA("[mlt] 🔧   ── ⑤ **`sd_run` 확인**(규율 47) — 비트 동일 **%u/%u** · 평균 |Δ| **%.3e**\n",
			runZero, runN, (runN == 0u) ? 0.0 : runSum / (double)runN);

		// ── 관문 ───────────────────────────────────────────────────
		const bool apply = (_seeds >= 3u);
		const double cA = Abs((float)(ch[0] - (double)kCE145A));
		const double cB = Abs((float)(ch[1] - (double)kCE145E));
		const bool gChk = !apply || (cA <= 0.05 && cB <= 0.05);
		bool mono = true;
		for (uint32 c = 1; c < kCaps; ++c) if (!(gap[c] <= gap[c - 1u])) mono = false;
		const double reach = gap[kCaps - 1u] / (double)kGap145;
		const Pair pTop = _GapPaired(kCaps - 1u, 0u);
		const bool gTitle = mono && (pTop.d < 0.0) && (pTop.t >= 2.0);
		LogA("[mlt] 🔧   ── 관문 ──\n");
		LogA("[mlt] 🔧     ⭐ **배관**(파라미터 = 손계산) → %s\n", gHand ? "✅" : "⛔ **배관이 틀렸다**");
		LogA("[mlt] 🔧     ⭐ **검산 둘** — q=1.00 %.4f(↔%.4f · 차 %.4f) · q=0.00 %.4f(↔%.4f · 차 %.4f) → %s\n",
			ch[0], (double)kCE145A, cA, ch[1], (double)kCE145E, cB,
			!apply ? "⚠️ 건너뜀(씨앗 3 이상 — 규율 51)" : (gChk ? "✅" : "⛔ **배치가 다르다**"));
		LogA("[mlt] 🔧     ⭐ **표제** — 간격 단조 감소(%s) + d=%u 에서 |d̄|/SE **%.2f**(≥2) → %s\n",
			mono ? "✅" : "⛔", kCapD[kCaps - 1u], pTop.t, gTitle ? "✅" : "⛔");
		LogA("[mlt] 🔧     ⭐ **도달률**(d=%u) = **%.3f** — 1.0 에 가까우면 ㉡ **구조 없음**\n",
			kCapD[kCaps - 1u], reach);

		// ── 판정 ───────────────────────────────────────────────────
		if (!_finite || ok < _seeds)
			LogA("[mlt] 🔧   ⭐ 판정 = ⛔ **판정불가** — 배관이 안 섰다\n");
		else if (!gHand)
			LogA("[mlt] 🔧   ⭐ 판정 = ⛔ **판정불가** — ***파라미터 수가 손계산과 다르다***(용량 배관이 틀렸다)\n");
		else if (!gChk)
			LogA("[mlt] 🔧   ⭐ 판정 = ⛔ **판정불가** — ***검산이 깨졌다***(145 와 배치가 다르다)\n");
		else if (_seeds == 1u)
			LogA("[mlt] 🔧   ⭐ **1씨앗 진단이다 — 판정하지 않는다**(규율 51)\n");
		else if (gTitle)
			LogA("[mlt] 🔧   ⭐ 판정 = ⭐ ***㉠ 용량 부족이다*** — 간격이 %.4f → %.4f(도달률 %.3f)로 줄었다\n"
			     "[mlt] 🔧      ⇒ ★ 그러면 143~149 의 모든 결론이 **「이 용량에서」** 이고, 다시 재야 한다\n",
			     gap[0], gap[kCaps - 1u], reach);
		else
			LogA("[mlt] 🔧   ⭐ 판정 = ⛔ ***㉡ 구조 없음이다*** — 용량을 %.1f배 올려도 간격이 %.4f → %.4f(도달률 **%.3f**)\n"
			     "[mlt] 🔧      ⇒ ⚠️⚠️ **하위 과제가 진짜로 독립이다** ⇒ ★ 처방은 용량이 아니라 **세계**다\n"
			     "[mlt] 🔧      ⇒ ⭐ 그리고 그것이 ***로드맵 칸 1 을 못 벗어난 이유***의 후보다\n",
			     (double)_params[kCaps - 1u] / (double)_params[0], gap[0], gap[kCaps - 1u], reach);
		LogA("[mlt] 🔧   ⚠️ 문맥 학습 %u · 시험 %u · %u걸음 — 절대 성능으로 인용하지 않는다\n",
			kNCtx, kPtCtx, kStepsBase);
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		_E.Destroy(); _done = true;
	}

	static void _Fail(const char* why)
	{
		LogA("[mlt] 🔧 ⛔ %s (씨앗 %u · 팔 %u · 바깥 %u · 평가 %u · 단계 %u · 코퍼스 %u · 걸음 %u)\n",
			why, _seed, _arm, _out, _evalIdx, _st, _cor, _step);
		_E.Destroy(); _done = true;
	}

	CW_BODY(MLTL1L0)
};
