// mltp4c1.cw — 🔀 회차 104 · **절제의 「분포」를 본다 — 선택적으로 읽나** (`-mltp4c1`) ⭐ **판정 회차**
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 104 이다.** ⭐ **하네스보다 먼저 썼다.**
//
// ── 🚨🚨 **사람이 회차 103 의 측정 구멍을 찔렀다**(2026-08-28) ────────────────
//   *"세계에서 입력에 대한 예측에서 어떤 건 행동을 안 봐도 되는 게 더 좋고 어떤 건 봐야 되고
//   어떤 건 뭘 봐야 되고 다르니까, 적응 대응형이 필요하지 않을까?"*
//
//   ⇒ ⭐ **그 지적이 옳고 그것은 곧바로 측정의 결함이다.** 회차 103 은 표적 28,672개의 **평균**을 봤다:
//   ```
//   어떤 표적 : 행동을 봐야 맞힌다  → 끊으면 크게 나빠진다
//   대부분    : 행동과 무관하다     → 끊어도 그대로(잡음이 줄어 살짝 좋아지기도)
//                                     ↓
//                                평균 ≈ 0
//   ```
//   ⇒ ⚠️⚠️ ***선택적으로 읽으면 평균은 정확히 0 이 나온다.*** 회차 103 의 자는 그것을 **못 가른다**
//   ⇒ 그 판정을 **보류**하고 다시 읽는다.
//
// ── ⭐ 설계 물음에 대한 답도 적어 둔다 ─────────────────────────────────────
//   | **적응 읽기 = 어텐션** | 그 기제는 **이미 있다**. 따로 만들 것이 아니다 |
//   | ⚠️ **손실이 균일하다** | 표적 28,672개를 똑같이 센다 ⇒ 행동이 필요한 것이 1% 면 기울기가 **1% 로 희석** |
//   | ⚠️ **세계도 균일하다** | `dt = 0.12` 라 한 걸음이 화면을 조금만 민다 |
//   ⇒ ⭐ ***"적응형이 필요하다" 는 「기제를 더하자」가 아니라 「그 기제가 배울 이유를 만들자」다.***
//   ⚠️ 그러나 **이 회차가 먼저다** — 안 그러면 *"세계를 바꿨더니 좋아졌다"* 를 **무엇과 견줄지** 모른다.
//
// ── 무엇을 하나 ───────────────────────────────────────────────────────────
//   `MLTModel::_tLoss` 는 이미 **행별**이다(`ReadLoss` 가 합칠 뿐) ⇒ **`ReadLossRows` 한 함수**를 더해
//   **Δ 의 분포**를 본다. 학습·코퍼스·팔은 **회차 103 그대로**다.
//
//   **팔 다섯** — ㈀ 온전 · ㈁ 행동끊음 · ㈂ 행동무작위 · ㈃ lr=0 · ⭐ **㈄ 활성끊음(눈금)**
//   ★ **㈄ 가 이 회차의 핵심** — *"Δ 가 넓은 것이 「선택적 읽음」인가 그냥 「흔들림」인가"* 를
//     **같은 실행·같은 자**로 견줄 유일한 방법이다(회차 85b 가 그 대역을 `+0.112` 로 **읽는다**고 세웠다).
//
// ── 관문 ──────────────────────────────────────────────────────────────────
//   **배관** ㈃ 평탄 · ㈀ 이 바닥 넘음 · ⭐ **㈄ 의 평균 Δ > 0**(⚠️ 눈금이 안 서면 견줄 자가 없다 · 규율 16)
//   **표제① 폭** `sd(Δ끊음)/sd(Δ활성끊음) ≥ 0.10` — `≥10/12`(⭐ **상대 문턱** · 규율 10)
//   **표제② 일치** `corr(Δ끊음, Δ무작위) ≥ 0.10` — `≥10/12`
//     ★ ***이것이 진짜 자다*** — 진짜 읽으면 ㈁·㈂ 가 **같은 표적에서** 나빠진다.
//     ⚠️ 그냥 흔들림이면 상관이 **0** 이다 ⇒ **폭만으로는 못 가르고 이것이 가른다.**
//   **잡음 바닥** — 학습이 **결정적**(회차 54)이라 ㈀↔㈀ 의 Δ 는 **정확히 0** ⇒ 영점이 자연히 있다
//
// ── ⭐ 결과의 뜻도 미리 못박았다 ──────────────────────────────────────────
//   | ①✅ ②✅ | ⭐ ***선택적으로 읽는다*** — 사람의 지적이 맞다 ⇒ 회차 103 판정을 **뒤집는다** |
//   | ①✅ ②⛔ | ⚠️ **넓지만 무작위다** — 끊기가 표현을 흔든 것 ⇒ 회차 103 판정 **유지** |
//   | ①⛔     | ⭐ **분포도 좁다** ⇒ ***회차 103 판정이 확정된다*** ⇒ **세계를 바꾼다** |
//
// ── (아래는 회차 103 의 머리말 원문) ───────────────────────────────────────
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **회차 103 등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 103 이다.**
//
// ── ⭐ 왜 자를 바꾸나 — **2×2 교차는 신호가 잡음보다 작다** ───────────────
//   회차 102 가 숫자로 못박았다: **표적을 바꾸면 CE 가 `0.030` 움직이는데 문맥의 행동을 통째로
//   뒤집으면 `0.0004`** ⇒ **비 `1 : 75`**. 표본을 8배로 늘려도 위생③이 **9/12·6/12** 로 안 섰다.
//   ⇒ ⚠️ **네 번(78·81·101·102) 같은 자로 졌다** ⇒ 규율 6 의 정신대로 **자를 바꾼다.**
//
// ── ⭐ 새 자 = **절제(ablation)** — 회차 85b 가 **이미 검증한 자** ─────────
//   ```
//   ㈀ 온전    — 행동 슬롯(5축 × 8시각) 그대로
//   ㈁ 끊음    — 「없음」 심볼 + 값 0
//   ㈂ 무작위  — 심볼은 그대로 · **값만** 무작위(⚠️ 분포 안 — `Unit` 으로 만든다)
//   ㈃ lr=0    — 위생①(평탄)
//   표제: CE(㈁) > CE(㈀) 그리고 CE(㈂) > CE(㈀) — 각 ≥10/12
//   ```
//   | ⭐ **효과가 8배** | 2×2 는 **한 시각의 개입**을 재는데 절제는 **모든 시각(8)의 행동 정보**를 없앤다 |
//   | ⭐ **표적을 다 쓴다** | 행동을 끊어도 **표적은 그대로**(표적 = 활성 id) ⇒ **채점을 안 좁힌다**
//     ⇒ `512 × 7 × 8 = 28,672` 표적(회차 102 의 **7배**) |
//   | ⭐ **이미 검증됐다** | 회차 85b 가 같은 모양으로 **12/12·12/12·분할반쪽 전부** 를 냈다 |
//   | ⭐ **규율 25 가 가리킨다** | *"학습의 값어치는 「끊어서」 잰다"* |
//
//   ⚠️⚠️ **회차 85b 와의 차이 하나** — 85b 는 과거 **활성**을 끊어 그 시각들이 **자기 입력을
//     잃었으므로** 채점을 한 칸으로 좁혀야 했다. **여기는 그 문제가 없다** ⇒ ***안 좁힌다.***
//
// ── ⭐ 예측을 미리 적었다 ─────────────────────────────────────────────────
//   · 배관 **12/12** 재현(회차 101·102 가 두 번 세웠다)
//   · **표제 ⚠️ 진짜 모른다**: **될 근거** — 절제는 8배 강하고 표적이 7배 많으며 정보는 분명히 있다
//     (회차 102: 표적이 **32.6%** 갈린다) / **안 될 근거** — 회차 102 의 **1:75** 가 이미
//     *"몸통이 그 슬롯을 안 읽는다"* 를 가리킨다 ⇒ 끊어도 **아무 일도 안 일어날** 수 있다
//   ⭐ **어느 쪽이든 판정이 난다** — 그것이 이 자를 고른 이유다.
//
// ── (아래는 회차 85b 의 머리말 원문) ───────────────────────────────────────
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **회차 85b 등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 82 이다.**
// ⭐ **회차 60 과 한 글자만 다르다: `kTestEpi` 101 → 901.**
//
// ⚠️⚠️⚠️ **왜** — 회차 81 이 찾았다: `kTrainEpi=1 · kNCtx=128` 이므로 학습은 **1~128** 인데
//   `kTestEpi=101 · kTestCtx=64` 면 시험이 **101~164** ⇒ ***101~128 = 시험의 43.75% 가 샜다.***
//   회차 58·59·60·61·62·64·77·79·80 이 전부 그 대역을 썼다. ⚠️ **회차 24 가 이미 밟은 함정**이다.
//
// ── 이 회차가 검증하는 **주장** ────────────────────────────────────────────
//   회차 81 의 기록이 이렇게 주장했다:
//     ㈀ **A/B 부호검정은 안 흔들린다** — 누출이 **모든 팔에 대칭**으로 들어가 상쇄된다
//     ㈁ ⛔ **「복사바닥을 넘나」는 흔들린다** — 그것은 **절대 비교**다
//   ⇒ ★ **이 회차가 그 두 주장을 동시에 시험한다.**
//     ㈀ 이 맞으면 표제(㈁>㈀ · ㈂>㈀)가 **12/12 로 남고**, ㈁ 이 맞으면 위생②가 **떨어진다**.
//
// ⚠️ 눈금(회차 60 · 누출판) — 바닥 **1.0731** · ㈀ **0.8681** · ㈁ **1.0029** · ㈂ **1.8536** · 12/12 · 12/12
// ══════════════════════════════════════════════════════════════════════════════
//
// ── (아래는 회차 60 의 머리말 원문) ──────────────────────────────────────
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 60 이다.**
// ⭐ 상위 캔버스가 **새것**이다: **활성이 시간을 건너 하중을 받나**.
//
// ⚠️⚠️ **먼저 — ㉡(눈감기)은 지금 배관에서 못 잰다.** `MLT.md` 의 ㉡ 은 *"`t` 부터 **프레임을 끊고**
//   활성만 남긴다"* 인데 **우리 컨텍스트에는 원본 패치가 애초에 없다**(상태 5 + 활성 8 뿐)
//   ⇒ **이미 눈을 감은 상태**다. 제대로 재려면 `EYE` 구간에 원본 패치 64개를 넣어야 하고 그것은
//   `ctx` 를 통째로 바꾼다. ⇒ **이 회차는 ㉡ 이 아니라 그 짝**이고, ㉠ 과 **정확히 짝**이다:
//     ㉠ = *상태 채널이 쓰이나* · 이 회차 = ***활성 채널의 과거가 쓰이나***.
// ══════════════════════════════════════════════════════════════════════════════
//
// ⭐ **무엇을 묻나** — 몸통이 **직전 시각만** 보고 있다면 그것은 **복사 + 상태**일 뿐이다.
//   ⇒ 시각 `0..5` 의 활성을 끊고 `6`(마지막 예측자)만 남겼을 때 예측이 나빠지나.
//
// ⚠️⚠️ **채점 자리를 좁힌다** — 시각 `0..5` 를 끊으면 그 시각들의 표적도 당연히 나빠지는데 그것은
//   *"자기 입력이 끊겼다"* 이지 *"과거가 쓰인다"* 가 아니다. ⇒ **평가는 시각 `6` 의 표적만** 센다
//   (그 행의 입력은 **온전**하고 끊긴 것은 **그 앞**뿐이다). **학습은 모든 표적으로** 한다.
//   ★ 복사바닥도 **같은 자리**에서 다시 잰다(`MLTP4Ctx::CeCopy` 의 `t1Only`).
//
// ⭐ 자(형식)는 **회차 59 가 세운 것을 그대로** 쓴다 — `R=6` · 평균 + **분할 반쪽**(A=0·2·4 / B=1·3·5).
// ⚠️ 어휘를 `5 + N + 1` 로 둔다(마지막이 **「없음」 심볼**) — **네 팔 모두** 그 어휘라 파라미터 수가 같다.

using namespace PE;

class MLTP4C1
{
public:
	static void Tick(RHI* rhi)
	{
		if (_done || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltp4c1"))
		{
			LogA("[mlt] 🔀 회차 104(절제의 분포 · 선택적으로 읽나)는 **꺼져 있다**(`-mltp4c1`)\n");
			_done = true; return;
		}
		if (!_banner) { _Banner(); _banner = true; }
		if (_seed >= kSeeds) { _Summary(); return; }
		if (_st == kEncInit)  { _EncBegin(rhi); return; }
		if (_st == kEncTrain) { _EncTrain(); return; }
		if (_st == kGather)   { _Gather(); return; }
		// ⚠️ 반복 사이에 **틱을 비운다**(회차 59 의 그 배관 고침 — 제출은 Present 가 한다).
		if (_st == kQuiesce)
		{
			if (_qWait > 0u) { --_qWait; return; }
			_st = kBodyInit; return;
		}
		if (_st == kBodyInit) { _BodyBegin(rhi); return; }
		if (_st == kBodyEval) { _BodyEval(); return; }
		_BodyTrain();
	}

	static bool Done() { return _done; }

private:
	static constexpr uint32 kSeeds = 12u;
	static constexpr uint32 kEncF = 32u, kEncSteps = 1200u, kEncPerTick = 8u;
	static constexpr uint32 kN = 250u, kLocal = 8u;
	static constexpr uint32 kTime = MLTP4Ctx::kTime;
	static constexpr uint32 kBatch = MLTP4Ctx::kBatch;
	static constexpr uint32 kCandidates = MLTP2Cfg::kPatches * kLocal;
	// ⭐ **회차 103** — 채점을 **안 좁히므로** 시험 문맥을 512 로 둔다
	//   ⇒ 표적 `512 × (kTime−1) × 8 = 28,672`(회차 102 의 4096 대비 **7배**).
	static constexpr uint32 kNCtx = 512u, kTestCtx = 512u;
	// ⭐ **회차 82 가 고친 유일한 것** — `kTestEpi` 를 101 → **901**.
	//   ⚠️ 회차 60 은 `101` 이었고 학습이 `1~128` 이라 **101~128 = 시험의 43.75% 가 샜다**.
	//   ★ 규약: **`kTestEpi ≥ kTrainEpi + kNCtx`** (아래 `static_assert` 가 강제한다).
	static constexpr uint32 kTrainEpi = 1u, kTestEpi = 901u;
	static_assert(kTestEpi >= kTrainEpi + kNCtx,
		"시험 에피소드가 학습과 겹친다 — kTestEpi >= kTrainEpi + kNCtx 여야 한다(회차 81 이 찾았다)");
	static constexpr uint32 kPoolSteps = kNCtx / kBatch, kTestPool = kTestCtx / kBatch;
	static constexpr uint32 kGroup = kEncF / kTime;
	static constexpr uint32 kSteps = 800u, kPerTick = 4u;
	// ⭐ **회차 104** — 팔을 **다섯**으로. `㈄ 활성 끊음`(arm 4)이 ***「진짜 읽을 때의 Δ 분포」 눈금***이다.
	//   ★ 그것 없이는 *"Δ 가 넓은 것이 「선택적 읽음」인가 그냥 「흔들림」인가"* 를 못 가른다.
	static constexpr uint32 kArms = 5u, kRep = 6u;
	static constexpr uint32 kArmWhole = 0u, kArmActCut = 1u, kArmActRnd = 2u,
		kArmLr0 = 3u, kArmPerCut = 4u;
	static constexpr uint32 kSignPass = 10u;
	static constexpr float  kFlatRel = 1.0e-6f;
	// ⭐ **회차 104 의 문턱 둘** — ⚠️ **상대**다(규율 10) · 결과를 보고 안 고친다.
	//   ㈀ 폭비 — 「활성 끊음」의 **10분의 1**만 되어도 선택적 읽기의 증거로 넉넉히 잡았다
	//   ㈁ 상관 — 진짜 읽으면 ㈁·㈂ 가 **같은 표적에서** 나빠진다. 흔들림이면 **0** 이다
	static constexpr float  kWidePass = 0.10f;
	static constexpr float  kCorrPass = 0.10f;
	// ⭐ **회차 103 이 가르는 자리 = 「행동 슬롯」**(회차 85b 는 과거 활성이었다).
	//   ⚠️⚠️ **채점을 안 좁힌다** — 행동을 끊어도 **표적은 그대로**다(표적은 활성 id).
	//     회차 85b 는 과거 **활성**을 끊어 그 시각들이 **자기 입력을 잃었으므로** 좁혀야 했다.
	//     ⇒ ★ 그것이 이 자가 회차 102 보다 **7배 민감한** 이유다.
	static constexpr uint32 kActFrom = MLTP4Ctx::kOAct;                    // 5
	static constexpr uint32 kActTo   = MLTP4Ctx::kOAct + MLTP4Ctx::kActAx; // 10
	// 심볼 대역 — 상태 `0..4` · **행동 `5..9`** · 활성 `10..(10+kN-1)` · 「없음」은 그 뒤
	static constexpr uint32 kNone = MLTP4Ctx::kStateAx + MLTP4Ctx::kActAx + kN;   // 260
	static constexpr uint32 kSymVocab = kNone + 1u;                              // 261

	enum { kEncInit, kEncTrain, kGather, kQuiesce, kBodyInit, kBodyTrain, kBodyEval };

	inline static MLTP2Enc _E;
	inline static MLTModel _M;
	inline static MLTP4Ctx _tr, _te;
	inline static MLTEvalGate _gate;
	inline static bool _done = false, _banner = false, _encSetup = false, _finite = true;
	inline static bool _pending = false, _pre = false;
	inline static uint32 _seed = 0u, _st = kEncInit, _step = 0u, _arm = 0u, _rep = 0u;
	inline static uint32 _cor = 0u, _gGrp = 0u, _gIdx = 0u;
	inline static Array<float> _code, _norm;
	inline static Array<float> _trVal, _trSym, _teVal, _teSym, _teTgt;
	inline static float _run[kRep];
	inline static float _ce[kArms][kSeeds];
	inline static float _ceA[kArms][kSeeds], _ceB[kArms][kSeeds];
	inline static float _pre0[kSeeds];
	inline static float _floorTe[kSeeds];
	inline static bool  _seedOk[kSeeds];

	inline static uint32 _qWait = 0u;
	static void _ToBody() { _qWait = MLTEvalGate::kDelay; _st = kQuiesce; }

	// ⭐ 행별 손실 — `_rowAcc` 에 반복(rep)마다 누적하고 `_Agg` 에서 `R` 로 나눠 `_rows[arm]` 로 옮긴다.
	static constexpr uint32 kRowN = kTestPool * MLTP4Ctx::kRows;   // 64 × 1152 = 73,728
	inline static Array<float> _rowAcc;
	inline static Array<float> _rows[kArms];
	inline static uint32 _ei = 0u, _ewait = 0u;
	inline static bool   _epend = false;
	inline static double _esum = 0.0;
	// 표제 결과(씨앗별)
	inline static float _sdRatio[kSeeds], _corrCut[kSeeds];

	static uint32 _Reps() { return (_arm == kArmLr0) ? 1u : kRep; }
	static const char* _ArmName()
	{
		switch (_arm)
		{
		case kArmWhole:  return "㈀ 온전";
		case kArmActCut: return "㈁ 행동끊음";
		case kArmActRnd: return "㈂ 행동무작위";
		case kArmLr0:    return "㈃ lr=0";
		default:         return "㈄ 활성끊음(눈금)";
		}
	}

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🔀 **회차 104 · 절제의 「분포」를 본다 — 선택적으로 읽나**(⭐ 판정 회차)\n");
		LogA("[mlt] 🔀   🚨 **사람이 회차 103 의 측정 구멍을 찔렀다**:\n");
		LogA("[mlt] 🔀     *\"어떤 건 행동을 안 봐도 되고 어떤 건 봐야 되고 다르니까 적응 대응형이 필요하지 않을까?\"*\n");
		LogA("[mlt] 🔀   ⇒ ⭐ 회차 103 은 표적 %u개의 **평균**을 봤다 — ***선택적으로 읽으면 평균은 정확히 0 이 나온다***\n",
			kTestCtx * (kTime - 1u) * MLTP4Ctx::kPersist);
		LogA("[mlt] 🔀   ⭐ **행별 손실**(`ReadLossRows`)로 **Δ 의 분포**를 본다 — 학습·코퍼스·팔은 회차 103 그대로\n");
		LogA("[mlt] 🔀   팔 다섯 — ㈀ 온전 · ㈁ 행동끊음 · ㈂ 행동무작위 · ㈃ lr=0 · **㈄ 활성끊음(눈금)**\n");
		LogA("[mlt] 🔀     ★ **㈄ 가 핵심** — *\"Δ 가 넓은 것이 「선택적 읽음」인가 그냥 「흔들림」인가\"* 를 견줄 **유일한 자**다\n");
		LogA("[mlt] 🔀   **표제① 폭** `sd(Δ끊음)/sd(Δ활성끊음) ≥ %.2f` · **표제② 일치** `corr(Δ끊음,Δ무작위) ≥ %.2f` — 각 ≥%u/12\n",
			(double)kWidePass, (double)kCorrPass, kSignPass);
		LogA("[mlt] 🔀     ⭐ **②가 진짜 자다** — 진짜 읽으면 ㈁·㈂ 가 **같은 표적에서** 나빠진다. 흔들림이면 상관이 **0**\n");
		LogA("[mlt] 🔀   ⚠️ 잡음 바닥 — 학습이 **결정적**이라(회차 54) ㈀↔㈀ 의 Δ 는 **정확히 0** ⇒ 영점이 자연히 있다\n");
		LogA("[mlt] 🔀   ⭐ **예측** — 배관 12/12 재현 · **표제 ⚠️ 진짜 모른다**(⚠️ 회차 102 는 개입이 세계의 **32.6%%** 를 바꾼다고 쟀다 — 소수가 아니다)\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

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
		MLTP4Ctx& C = (_cor == 0u) ? _tr : _te;
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
					// ⭐ **P4 규약**(회차 79 가 세운 것) — 렌더·상태·활성을 **먼저** 넣고,
					//   **그 다음** 행동을 넣고 굴린다. 행동 슬롯 = 「이 시각에서 **다음으로** 갈 때 쓸 행동」.
					if (!w.Render(bmp) || !MLTWorld::Pack(bmp, nullptr, packed)) { _Fail("Render/Pack(문맥)"); return; }
					MLTP2Enc::AppendFrame(fr, tg, (const uint8*)packed.GetData());
					C.StoreState(ctx, t, w.State());
					const MLTAct a = w.ActAt(w.StepNo());
					C.StoreAct5(ctx, t, a);
					w.StepWith(a);
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
				// ⭐ 시험 복사바닥 — ⚠️ **채점과 같은 자리**(이번엔 **모든 예측 시각**)에서 잰다.
				//   λ·M 은 여전히 **학습 코퍼스**에서 고른다(바닥에 일부러 유리하게).
				//   ⭐ `kAllT1` = 「모든 예측 시각」 — 채점을 안 좁히므로 바닥도 안 좁힌다.
				Array<float> marg; _tr.Marginal(marg);
				float c1 = 0.0f, c2 = 0.0f, l1 = 0.0f, l2 = 0.0f;
				_tr.BestCopy(marg, c1, c2, l1, l2, MLTP4Ctx::kAllT1);
				const float t1 = (float)_te.CeCopy(marg, l1, false, MLTP4Ctx::kAllT1);
				const float t2 = (float)_te.CeCopy(marg, l2, true, MLTP4Ctx::kAllT1);
				_floorTe[_seed] = (t1 < t2) ? t1 : t2;
				LogA("[mlt] ✂️ 씨앗 %2u · 시험 복사바닥(**모든 예측 시각** · 표적 %u개) **%.4f**\n",
					_seed, kTestCtx * (kTime - 1u) * MLTP4Ctx::kPersist, (double)_floorTe[_seed]);
				_arm = 0u; _rep = 0u; _ToBody();
			}
		}
	}

	// ⭐ 이 팔의 입력을 만든다 — **행동 슬롯(축 5..9)을 「모든 시각」에서** 바꾼다.
	//   ⚠️⚠️ **표적은 한 칸도 안 건드린다** — 행동은 표적이 아니다(표적은 활성 id) ⇒ **채점을 안 좁힌다.**
	//     ★ 그것이 이 자가 회차 102(2×2 교차)보다 **7배 민감한** 이유다(표적 4096 → **28,672**).
	//   ⚠️ 상태 슬롯과 활성 슬롯은 **네 팔에서 손대지 않는다**.
	static void _CutPool(const MLTP4Ctx& C, uint32 nCtx, uint32 cor, Array<float>& val, Array<float>& sym)
	{
		const uint32 n = (nCtx / kBatch) * MLTP4Ctx::kRows;
		val.Reset(0); sym.Reset(0);
		for (uint32 i = 0; i < n; ++i) { val.Add(C.Val()[i]); sym.Add(C.Sym()[i]); }
		if (_arm == kArmWhole || _arm == kArmLr0) return;      // 온전 · `lr=0` 은 그대로
		// ⭐ **㈄ 활성 끊음** — 「진짜 읽을 때의 Δ 분포」 눈금(회차 85b 가 `+0.112` 로 세운 대역).
		//   ⚠️ 행동 절제와 **같은 방식**(「없음」+0)이라야 분포를 견줄 수 있다.
		if (_arm == kArmPerCut)
		{
			for (uint32 ctx = 0; ctx < nCtx; ++ctx)
				for (uint32 t = 0; t < kTime; ++t)
				{
					const uint32 base = MLTP4Ctx::Row(ctx, t, MLTP4Ctx::kOAct2);
					for (uint32 j = 0; j < MLTP4Ctx::kPersist; ++j)
					{ sym.Data()[base + j] = (float)kNone; val.Data()[base + j] = 0.0f; }
				}
			return;
		}
		for (uint32 ctx = 0; ctx < nCtx; ++ctx)
			for (uint32 t = 0; t < kTime; ++t)                 // ⭐ **모든 시각**
			{
				const uint32 base = MLTP4Ctx::Row(ctx, t, kActFrom);
				for (uint32 i = 0; i < MLTP4Ctx::kActAx; ++i)
				{
					if (_arm == 1u) { sym.Data()[base + i] = (float)kNone; val.Data()[base + i] = 0.0f; }
					else
					{
						// ㈂ 무작위 — ⚠️ **심볼은 그대로 두고 값만 무작위**로 둔다.
						//   ★ 「행동이 있다」는 사실은 남기고 **그 값만** 지운다(회차 85a 의 그 갈림).
						//   ⚠️ 코퍼스마다 다른 난수여야 한다(학습·시험이 같은 열을 쓰면 그것이 신호가 된다).
						const uint32 key = _seed * 7919u + cor * 1000003u + ctx * 131u + t * 17u + i;
						const uint32 h = MLTWorld::Hash(key, MLTSalt::Start, 42u);
						val.Data()[base + i] = MLTWorld::Unit(h);   // ⚠️ 분포 안(`_PickAct` 와 같은 `Unit`)
					}
				}
			}
	}

	static void _BodyBegin(RHI* rhi)
	{
		if (!_M.Setup(rhi, kSymVocab, kN, MLTP4Ctx::kAxes, kTime)) { _Fail("몸통 준비"); return; }
		// ⭐ 팔이 시작될 때(첫 반복) 행별 누적을 **비운다** — 반복마다 더하고 `_Agg` 에서 나눈다.
		if (_rep == 0u)
		{
			_rowAcc.Reset(0);
			for (uint32 i = 0; i < kRowN; ++i) _rowAcc.Add(0.0f);
		}
		_CutPool(_tr, kNCtx, 0u, _trVal, _trSym);
		_CutPool(_te, kTestCtx, 1u, _teVal, _teSym);
		if (!_M.UploadPool(_trVal, _tr.Tgt(), kPoolSteps) || !_M.UploadSymbolPool(_trSym, kPoolSteps))
		{ _Fail("학습 풀 업로드"); return; }
		_step = 0u;
		if (_arm == kArmLr0 && _rep == 0u) { _pre = true; _SwitchToTest(); return; }
		_pre = false; _st = kBodyTrain;
	}

	static bool _SwitchToTest()
	{
		// ⭐ **표적을 그대로 쓴다**(회차 85b 는 `_MaskTgt` 로 좁혔지만 여기는 안 좁힌다 — 위 `_CutPool` 의 ⚠️⚠️)
		if (!_M.UploadPool(_teVal, _te.Tgt(), kTestPool) || !_M.UploadSymbolPool(_teSym, kTestPool))
		{ _Fail("시험 풀 업로드"); return false; }
		_ei = 0u; _epend = false; _ewait = 0u; _esum = 0.0; _st = kBodyEval;
		return true;
	}

	static void _BodyTrain()
	{
		if (_step >= kSteps) { _SwitchToTest(); return; }
		for (uint32 i = 0; i < kPerTick && _step < kSteps; ++i)
		{
			_M.SelectStep(_step % kPoolSteps);
			if (!_M.Forward() || !_M.Backward() || !_M.AdamStep((_arm == 3u) ? 0.0f : 1.0f))
			{ _Fail("몸통 스텝"); return; }
			++_step;
		}
	}

	// ⭐ **회차 104** — `MLTEvalGate` 를 안 쓰고 **행별 손실을 같이 모으는** 평가 루프를 쓴다.
	//   ⚠️ 규약(`kDelay` 대기 · 읽기 전에 다음 forward 를 안 쏜다)은 **그 클래스와 한 글자도 안 다르다**.
	//   ★ 그것을 여기 다시 적는 이유: `MLTEvalGate` 는 **평균만** 주고, 이 회차의 물음이 **분포**다.
	static void _BodyEval()
	{
		if (_epend)
		{
			if (_ewait > 0u) { --_ewait; return; }
			float ls = 0.0f;
			if (!_M.ReadLoss(ls)) { _Fail("평가 리드백"); return; }
			if (!(ls == ls) || ls > 1.0e30f) _finite = false;
			_esum += (double)ls;
			if (_arm != 3u)                       // ⚠️ `lr=0` 팔은 분포를 안 쓴다
			{
				Array<float> rows;
				if (!_M.ReadLossRows(rows) || rows.Count() < MLTP4Ctx::kRows)
				{ _Fail("행별 손실 리드백"); return; }
				const uint64 base = (uint64)(_ei - 1u) * MLTP4Ctx::kRows;
				for (uint32 i = 0; i < MLTP4Ctx::kRows; ++i) _rowAcc.Data()[base + i] += rows[i];
			}
			_epend = false;
		}
		if (_ei >= kTestPool)
		{
			const float ce = (float)(_esum / (double)kTestPool);
			if (_pre)
			{
				_pre0[_seed] = ce; _pre = false;
				if (!_M.UploadPool(_trVal, _tr.Tgt(), kPoolSteps) || !_M.UploadSymbolPool(_trSym, kPoolSteps))
				{ _Fail("학습 풀 복귀"); return; }
				_step = 0u; _st = kBodyTrain; return;
			}
			_run[_rep] = ce;
			if (++_rep < _Reps()) { _ToBody(); return; }
			_Agg();
			return;
		}
		_M.SelectStep(_ei);
		if (!_M.Forward()) { _Fail("평가 forward"); return; }
		++_ei; _epend = true; _ewait = MLTEvalGate::kDelay;
	}

	// 평균 + 분할 반쪽(회차 59 가 세운 자 — 그대로 쓴다).
	static void _Agg()
	{
		const uint32 R = _Reps();
		double s = 0.0, sA = 0.0, sB = 0.0; uint32 nA = 0u, nB = 0u;
		for (uint32 i = 0; i < R; ++i)
		{
			s += (double)_run[i];
			if ((i % 2u) == 0u) { sA += (double)_run[i]; ++nA; } else { sB += (double)_run[i]; ++nB; }
		}
		_ce[_arm][_seed]  = (float)(s / (double)R);
		_ceA[_arm][_seed] = (nA == 0u) ? _ce[_arm][_seed] : (float)(sA / (double)nA);
		_ceB[_arm][_seed] = (nB == 0u) ? _ce[_arm][_seed] : (float)(sB / (double)nB);
		// ⭐ 행별 손실을 **반복 수로 나눠** 이 팔의 자리에 옮긴다.
		if (_arm != kArmLr0)
		{
			_rows[_arm].Reset(0);
			const float inv = 1.0f / (float)R;
			for (uint32 i = 0; i < kRowN; ++i) _rows[_arm].Add(_rowAcc[i] * inv);
		}
		LogA("[mlt] 🔀   %s 씨앗 %2u · 평균 CE **%.5f**(반쪽 A %.5f · B %.5f · R=%u)\n",
			_ArmName(), _seed, (double)_ce[_arm][_seed],
			(double)_ceA[_arm][_seed], (double)_ceB[_arm][_seed], R);
		_rep = 0u;
		if (++_arm < kArms) { _ToBody(); return; }
		_Distribution();                       // ⭐ 이 회차의 물음
		_seedOk[_seed] = _finite;
		++_seed; _st = kEncInit;
	}

	// ⭐ **절제의 「분포」** — 평균이 0 이어도 **선택적으로 읽으면 분포가 넓다**.
	//   ⚠️ 넓다고 곧 「읽는다」가 아니다 ⇒ **㈁ 과 ㈂ 가 같은 표적에서 같이 나빠지나**(상관)가 진짜 자다.
	static void _Distribution()
	{
		double sC = 0.0, sR = 0.0, sP = 0.0;                 // 평균(끊음 · 무작위 · 활성끊음)
		double qC = 0.0, qR = 0.0, qP = 0.0, xCR = 0.0;      // 제곱합 · 교차합
		uint32 n = 0u;
		for (uint32 k = 0; k < kTestPool; ++k)
			for (uint32 b = 0; b < kBatch; ++b)
			{
				const uint32 ctx = k * kBatch + b;
				for (uint32 t = 0; t + 1u < kTime; ++t)       // ⚠️ 표적이 있는 시각만
					for (uint32 j = 0; j < MLTP4Ctx::kPersist; ++j)
					{
						const uint32 r = MLTP4Ctx::Row(ctx, t, MLTP4Ctx::kOAct2) + j;
						const float tf = _te.Tgt()[r];
						if (!(tf >= 0.0f && tf < (float)kN)) continue;   // 무효 표적은 뺀다
						const float w = _rows[kArmWhole][r];
						const double dC = (double)(_rows[kArmActCut][r] - w);
						const double dR = (double)(_rows[kArmActRnd][r] - w);
						const double dP = (double)(_rows[kArmPerCut][r] - w);
						sC += dC; sR += dR; sP += dP;
						qC += dC * dC; qR += dR * dR; qP += dP * dP; xCR += dC * dR;
						++n;
					}
			}
		if (n == 0u) { _sdRatio[_seed] = 0.0f; _corrCut[_seed] = 0.0f; return; }
		const double N = (double)n;
		const double mC = sC / N, mR = sR / N, mP = sP / N;
		const double vC = qC / N - mC * mC, vR = qR / N - mR * mR, vP = qP / N - mP * mP;
		const double sdC = Sqrt((float)((vC > 0.0) ? vC : 0.0));
		const double sdR = Sqrt((float)((vR > 0.0) ? vR : 0.0));
		const double sdP = Sqrt((float)((vP > 0.0) ? vP : 0.0));
		_sdRatio[_seed] = (sdP > 1.0e-12) ? (float)(sdC / sdP) : 0.0f;
		const double cov = xCR / N - mC * mR;
		_corrCut[_seed] = (sdC > 1.0e-12 && sdR > 1.0e-12) ? (float)(cov / (sdC * sdR)) : 0.0f;
		LogA("[mlt] 🔀   ⭐ 씨앗 %2u **분포**(표적 %u) — 평균Δ 끊음 %+.5f · 무작위 %+.5f · **활성끊음 %+.5f**\n",
			_seed, n, mC, mR, mP);
		LogA("[mlt] 🔀     sd — 끊음 **%.5f** · 무작위 %.5f · **활성끊음 %.5f** │ ⭐ **폭비 %.4f** · ⭐ **상관(끊음↔무작위) %+.4f**\n",
			sdC, sdR, sdP, (double)_sdRatio[_seed], (double)_corrCut[_seed]);
	}

	static void _Summary()
	{
		double m[kArms], mf = 0.0;
		for (uint32 a = 0; a < kArms; ++a) m[a] = 0.0;
		uint32 ok = 0u, t1 = 0u, t2 = 0u, beat = 0u, flat = 0u;
		uint32 a1 = 0u, a2 = 0u, b1 = 0u, b2 = 0u;
		for (uint32 s = 0; s < kSeeds; ++s)
		{
			if (!_seedOk[s]) continue;
			++ok;
			for (uint32 a = 0; a < kArms; ++a) m[a] += _ce[a][s];
			mf += _floorTe[s];
			if (_ce[0][s] < _floorTe[s]) ++beat;
			if (Abs(_ce[3][s] - _pre0[s]) <= kFlatRel * Abs(_pre0[s])) ++flat;
			if (_ce[1][s] > _ce[0][s]) ++t1;
			if (_ce[2][s] > _ce[0][s]) ++t2;
			if (_ceA[1][s] > _ceA[0][s]) ++a1;
			if (_ceA[2][s] > _ceA[0][s]) ++a2;
			if (_ceB[1][s] > _ceB[0][s]) ++b1;
			if (_ceB[2][s] > _ceB[0][s]) ++b2;
		}
		// ⭐ **회차 104 의 표제 둘** — 분포의 **폭**과 **일치**
		uint32 gPer = 0u, gWid = 0u, gCor = 0u;
		double mRatio = 0.0, mCorr = 0.0;
		for (uint32 s = 0; s < kSeeds; ++s)
		{
			if (!_seedOk[s]) continue;
			if (_ce[kArmPerCut][s] > _ce[kArmWhole][s]) ++gPer;    // 눈금 팔이 서나(규율 16)
			if (_sdRatio[s] >= kWidePass) ++gWid;
			if (_corrCut[s] >= kCorrPass) ++gCor;
			mRatio += (double)_sdRatio[s]; mCorr += (double)_corrCut[s];
		}
		if (ok > 0u) { for (uint32 a = 0; a < kArms; ++a) m[a] /= ok; mf /= ok; mRatio /= ok; mCorr /= ok; }
		const bool split = (a1 >= kSignPass) && (a2 >= kSignPass) && (b1 >= kSignPass) && (b2 >= kSignPass);
		const bool plumb = (flat == ok) && (beat >= kSignPass) && _finite && (gPer >= kSignPass);
		const bool p1 = (t1 >= kSignPass), p2 = (t2 >= kSignPass);
		const bool q1 = (gWid >= kSignPass), q2 = (gCor >= kSignPass);

		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🔀 **회차 104 · 절제의 「분포」를 본다 — 선택적으로 읽나**(표적 %u개) — 읽은 씨앗 %u/%u\n",
			kTestCtx * (kTime - 1u) * MLTP4Ctx::kPersist, ok, kSeeds);
		LogA("[mlt] 🔀   🚨 사람이 회차 103 의 구멍을 찔렀다 — ***선택적으로 읽으면 평균은 정확히 0 이 나온다***\n");
		LogA("[mlt] 🔀   ⚠️ 견줄 것(회차 103) — ㈀ 0.9119 · ㈁ 0.9115 · ㈂ 0.9112 · 표제 6/12·6/12 · 분할반쪽 ⛔\n");
		LogA("[mlt] 🔀   배관 — ㈃ 평탄 **%u/%u** · ㈀ 이 바닥을 넘음 **%u/%u** · ⭐ **㈄ 눈금 팔이 섬 %u/%u** → %s\n",
			flat, ok, beat, kSeeds, gPer, kSeeds, plumb ? "통과" : "⛔");
		LogA("[mlt] 🔀   평균 CE — 바닥 **%.4f** · ㈀ **%.4f** · ㈁ 끊음 **%.4f** · ㈂ 무작위 **%.4f** · **㈄ 활성끊음 %.4f**\n",
			mf, m[0], m[1], m[2], m[4]);
		LogA("[mlt] 🔀   (회차 103 의 자) 분할 반쪽 — A(%u·%u) B(%u·%u) → %s │ 표제 ㈁>㈀ %u/%u · ㈂>㈀ %u/%u\n",
			a1, a2, b1, b2, split ? "통과" : "⛔", t1, kSeeds, t2, kSeeds);
		LogA("[mlt] 🔀   **⭐ 표제① 폭** — `sd(Δ끊음)/sd(Δ활성끊음)` 평균 **%.4f** · `≥%.2f` 인 씨앗 **%u/%u** → %s\n",
			mRatio, (double)kWidePass, gWid, kSeeds, q1 ? "✅" : "⛔");
		LogA("[mlt] 🔀   **⭐ 표제② 일치** — `corr(Δ끊음, Δ무작위)` 평균 **%+.4f** · `≥%.2f` 인 씨앗 **%u/%u** → %s\n",
			mCorr, (double)kCorrPass, gCor, kSeeds, q2 ? "✅" : "⛔");
		if (!plumb)
			LogA("[mlt] 🔀   ⭐ 판정 = ⛔ **판정불가** — 배관이 안 섰다(평탄/바닥/**눈금 팔**)\n");
		else if (q1 && q2)
			LogA("[mlt] 🔀   ⭐ 판정 = ⭐ ***선택적으로 읽는다*** — 사람의 지적이 맞다. 회차 103 판정을 **뒤집는다** ⇒ 다음은 *어떤 표적에서 읽나*\n");
		else if (q1 && !q2)
			LogA("[mlt] 🔀   ⭐ 판정 = ⚠️ **넓지만 무작위다** — 끊기가 표현을 흔든 것이지 **읽은 것이 아니다** ⇒ 회차 103 판정 **유지**\n");
		else
			LogA("[mlt] 🔀   ⭐ 판정 = ⭐ **분포도 좁다** ⇒ ***회차 103 판정이 확정된다*** — 평균도 0, 분포도 0 ⇒ **세계를 바꾼다**\n");
		LogA("[mlt] 🔀   ⚠️ 고정 %u문맥 · 채점 표적 %u개의 진단이다 — 절대 성능으로 인용하지 않는다\n",
			kNCtx, kTestCtx * (kTime - 1u) * MLTP4Ctx::kPersist);
		LogA("[mlt] 🔀   ⚠️ 학습은 **결정적**이다(회차 54) ⇒ ㈀↔㈀ 의 Δ 는 **정확히 0** — 영점이 자연히 있다\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		_E.Destroy(); _done = true;
	}

	static void _Fail(const char* why)
	{
		LogA("[mlt] ⏳ ⛔ %s (씨앗 %u · 팔 %u · 반복 %u · 단계 %u)\n", why, _seed, _arm, _rep, _st);
		_E.Destroy(); _done = true;
	}
};
