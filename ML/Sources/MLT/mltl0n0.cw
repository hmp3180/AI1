// mltl0n0.cw — 🧪 회차 121 · **C0: L0 을 정직한 자로 다시** (`-mltl0n0`) ⭐ **판정 회차**
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 121 이다.** ⭐ **하네스보다 먼저 썼다.**
//   **상위 캔버스: `L0 을 정직한 자로 다시` · 121~ = 1회차**(규율 33 · P6 에서 바뀌었다).
//
// ── ⚠️ 무엇이 부채인가 — **회차 100 의 원문을 읽고 좁혔다** ─────────────────
//   회차 100 이 남긴 숫자와 **회차 112 가 잰 CE 의 실행 잡음(`sd_run = 0.00405`)** 을 나란히:
//   | 낱말 | 차(㈁−㈀) | 차/sd_run | 읽기 |
//   |---|---|---|---|
//   | yaw     | 0.2845 | **70배** | ⭐ 잡음이 아니다 |
//   | 뜻밖임  | 0.0401 | **10배** | ⭐ 잡음이 아니다 |
//   | 지속개수 | 0.0025 | 0.6배 | ⚠️ **못 잰다** |
//   | minDOn  | 0.0045 | 1.1배 | ⚠️ **못 잰다** |
//   ⇒ ⭐ **회차 100 의 「0/12」 둘은 실행 잡음으로 설명되지 않는다** — 그 결론은 살아 있다.
//   ⚠️⚠️ **그러나 「씨앗 잡음」은 한 번도 안 쟀다**(규율 32 는 회차 113 에서 생겼고, 그 실측이
//     ***씨앗 잡음 = 실행 잡음의 2.5배*** 였다) ⇒ ★ **그것이 이 회차가 갚을 부채다.**
//
// ── ⭐ 자를 하나 고친다 — **부호검정 → 짝지은 SE**(규율 31·32) ──────────
//   회차 100 은 `㈀<㈁` **부호검정**이었다(크기를 버린다).
//   ⇒ ★ **짝지은 차 `d = CE(㈀) − CE(㈁)` 의 평균 ± SE**(씨앗 단위)로 다시 본다.
//   ⭐ 그 형태의 값: *"학습이 얼마나 지는가"* 를 **크기와 상한**으로 말할 수 있다(규율 26).
//
// ── 🔬 설계 — ⚠️ **회차 100 하네스를 한 글자도 안 바꾼다**(자만 바꾼다) ──────
//   `mltl0m0.cw` 복사 + **집계만** 고침 + ⭐ **바깥 반복 2**(실행 잡음과 씨앗 잡음을 갈라 잰다).
//   ⭐ 낱말 넷 그대로 ⇒ **회귀 검사를 겸한다**(㈀ CE 가 회차 100 값 ±0.02 안).
//
// ── ✅ 관문 ───────────────────────────────────────────────────────────────
//   **배관** ㈃ 균형 · ㈄ 얼림/재현 · 유한 · ⭐ **회귀**(넷 다 ±0.02) · ⭐ **양성**(yaw)
//   ⭐ **표제** `|d̄(뜻밖임)|/SE ≥ 3` **그리고 부호** — ⭐ 부호가 곧 결론이다
//   ⭐ **부산물** 낱말 넷의 `sd_씨앗`·`sd_run` ⇒ **L0 의 잡음 표**(다음 회차들이 쓴다)
//
// ── ⭐ 예측 ──────────────────────────────────────────────────────────────
//   ⚠️ **최근 아홉 중 다섯을 틀렸다.**
//   · 회귀 통과 · ⭐ **`d̄ > 0` 이고 `|d̄|/SE ≥ 3`**(차 0.040 이 실행 잡음의 10배 · 씨앗이 2.5배여도 4배 남는다)
//   · ⇒ 그러면 ***회차 100 의 결론이 정직한 자로도 선다*** — ⚠️ **좋은 소식이 아니다**
//   · ⚠️ **뒤집힐 가능성**: 씨앗 잡음이 크면 판정불가 ⇒ ⭐ ***회차 100 의 「0/12」는 부호검정의 착시***
//
// ── (아래는 회차 100 의 머리말 원문 — 낱말 넷의 근거) ─────────────────────
//
// ══════════════════════════════════════════════════════════════════════════════
// mltl0m0.cw — 🧪 회차 100 · **「과제에 필요한 낱말」과 「무관한 낱말」을 나란히** ⭐ **판정**
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 100 이다.** ⭐ **하네스보다 먼저 썼다.**
//
// ── ⚠️ 먼저 — **회차 99 보고에서 한 내 진단을 정정한다** ───────────────────
//   *"과제가 몸통에게 요구하는 것이 적다"* 고 적었는데 **정확하지 않다**:
//     회차 85b 에서 몸통은 **시험 복사바닥 `1.0542` 를 `0.8777` 로** 크게 넘었다(12/12).
//     ⇒ ***과제는 잘 배운다.***
//   ⇒ ⭐ **진짜 후보는 「우리가 고른 낱말이 과제와 무관하다」다.**
//     학습은 **과제에 필요한 것**을 뭉치는데 우리는 여태 **안 필요한 것**(`yaw`·`|dYaw|`·`minDOn`)만 물었다.
//   ⚠️ 무작위 사영은 **입력 전체를 골고루** 나르므로 **과제와 무관한 양에서는 오히려 유리하다.**
//
// ── ⭐ 그래서 **한 회차로 갈린다** — 같은 자로 네 낱말을 나란히 ──────────
//   | **㊀ 표제**  | **뜻밖임** = 다음 시각 표적 8개의 `−log p_marginal` 평균 | ***손실의 주항 그 자체*** |
//   | **㊁ 표제′** | **지속 개수** = 지금 활성 8개 중 다음에도 남는 수         | 과제가 **직접 요구**한다 |
//   | ㊂ 양성      | `yaw`                                                    | 자가 도는가(규율 16) |
//   | ㊃ 참조      | `minDOn`                                                 | **무관** ⇒ 회차 97·99 의 **5/12 재현** 기대 |
//
//   ⚠️ **주변분포는 「몸통 학습 코퍼스」에서만** 잡는다(시험을 훔쳐보지 않는다).
//   ⚠️ ㊀·㊁ 은 **코퍼스 안**의 양이고 ㊃ 는 **판정 창구**(`VisibleShapes`)다 — **둘 다 모델 입력이 아니다**.
//
// ── 자·형식·팔 — 회차 99 그대로(⚠️ 판은 **하나**) ─────────────────────────
//   축 13(`MLTP3Ctx`) · **대역별 풀링 2대역 = 257차원**(⚠️ 여전히 선형) ·
//   ㈀ 학습 몸통 ↔ ㈁ 무작위 몸통 · 맞춤 384 / 보정 128 · λ 격자 · 온도 τ · 순위 3분위 · 씨앗 12
//   ⚠️ 앵커 판(축 29)은 **없다** — 회차 99 가 *"앵커를 줘도 몸통이 안 쓴다"*(7/12)로 닫았다.
//
// ── 관문 ──────────────────────────────────────────────────────────────────
//   **배관** ㈃ 균형(네 표적 다) · ㈄ 얼림/재현 · ⚠️ **㊂ 양성 `≥10/12`**(규율 16)
//   **표제 ⭐** `CE(㈀·뜻밖임) < CE(㈁·뜻밖임)` — `≥10/12` ← **규율 18 을 「과제에 필요한 낱말」에**
//   **표제′** 같은 것을 **지속 개수**로 — `≥10/12`
//   부산물: `minDOn` 의 `㈀<㈁`(⚠️ **5/12 근처가 나와야 재현**이다)
//
// ── ⭐ 예측을 미리 적었다 ─────────────────────────────────────────────────
//   ㊂ 12/12 재현 · ㊃ `minDOn` 5/12 근처 재현 · **㊀·㊁ 은 ⚠️ 진짜 모른다**:
//     · **될 근거**   — 과제가 **직접 요구**하는 양이고 몸통은 복사바닥을 **0.18 나트** 넘는다
//     · **안 될 근거** — 세 회차가 **같은 자리에서 졌다**(5·4·5·6/12). 무작위 사영이 강한 기준선이다
//
// ── ⭐ 결과의 뜻도 미리 못박았다 ──────────────────────────────────────────
//   | ㊀ 또는 ㊁ ✅ · ㊃ ⛔ | ⭐ ***설명이 닫힌다*** — 학습은 **과제에 필요한 것**을 뭉친다.
//     회차 86~99 의 null 은 ***「낱말이 과제와 무관해서」***였다 |
//   | ㊀·㊁ 둘 다 ⛔       | ⭐ ***더 무거운 사실*** — 몸통이 **자기 과제의 난이도조차** 선형으로 안 담는다 |
//   | ㊂ ⛔                | ⛔ **판정불가** |
//
// ── (아래는 회차 99 의 머리말 원문) ────────────────────────────────────────
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **회차 99 등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 99 이다.**
//
// ── ⚠️ 회차 98 이 남긴 문제 — **자가 묽어졌다**(규율 23) ────────────────────
//   앵커를 실었더니 ㈀ 이 **1.0775 → 1.0820** 으로 **오히려 약간 나빠졌다.**
//   ⚠️⚠️ 그런데 **양성 대조도 같이 나빠졌다**(`yaw×풀링` ㈀ **0.7911 → 1.0276**).
//   ⇒ ⭐ ***문맥이 104 → 232 로 커지자 전체평균 풀링이 신호를 희석했다*** — 상태 5축의 지분이
//     **4.8% → 2.2%** 다. ⇒ **앵커의 이득과 풀링의 희석이 섞여 있어** 그 비교는 못 쓴다.
//
// ── ⭐ 고침 = **대역별 풀링**(⚠️ 여전히 **선형**) ─────────────────────────
//   상태 5축 · 활성 8축 · 앵커 16축을 **따로 평균해 이어붙인다** ⇒ `3 × 128 + 1 = 385`.
//   ★ 그러면 **문맥이 길어져도 각 대역의 지분이 안 줄어든다.**
//
// ── ⭐ **영(zero) 대역** — A/B 를 공정하게 만드는 자리 ──────────────────
//   ⚠️ 대역별로 이으면 판 A 는 2대역(257) · 판 B 는 3대역(385)로 **차원이 다르다** —
//     회차 89 가 세운 규약(*차원이 다르면 릿지 비교가 불공정하다*)에 걸린다.
//   ⇒ ⭐ **판 A 도 3대역으로 만들고 앵커 대역을 「전부 0」으로 둔다** ⇒ ***둘 다 385차원.***
//   ★ 두 판의 **유일한 차이가 「그 대역이 0이냐 진짜냐」** 뿐이라 A/B 가 **최대로 짝지어진다.**
//
// ── ⭐ **인코더 활성을 한 번만 뽑아 두 코퍼스에 같이 넣는다** ───────────
//   ⚠️ 판 A 와 판 B 가 **다른 활성**을 보면 그것이 교란이다.
//   ⇒ 한 `_Gather` 루프에서 `StoreState`/`StoreAct` 를 **두 코퍼스에 나란히** 부른다.
//
// ── 판·팔 넷 ──────────────────────────────────────────────────────────────
//   | **판 A** 축 13(`MLTP3Ctx`)  · 앵커 대역 **전부 0** | ㈀ 학습 · ㈁ 무작위 |
//   | **판 B** 축 29(`MLTP3ACtx`) · 앵커 대역 **진짜**   | ㈀ 학습 · ㈁ 무작위 |
//
// ── 관문 ──────────────────────────────────────────────────────────────────
//   **배관** ㈃ 균형 · ㈄ 얼림/재현 · ⚠️ **양성(yaw)이 판 A·B 「둘 다」 `≥10/12`**(규율 16 + 23)
//   **표제 ⭐** `CE(판B · ㈀ · minDOn) < CE(판A · ㈀ · minDOn)` — `≥10/12` ← ***앵커가 돕나***
//   부산물: 각 판의 `<ln3` · 각 판의 `㈀ < ㈁`(규율 18)
//
// ── ⭐ 예측을 미리 적었다 ─────────────────────────────────────────────────
//   · 양성 대조가 **두 판에서 비슷해진다**(대역별이라 희석이 없다) ← 규율 23 의 고침이 먹었나
//   · **앵커 A/B 는 ⚠️ 진짜 모른다** — 그것이 이 회차의 값이다
// ══════════════════════════════════════════════════════════════════════════════

using namespace PE;

class MLTL0N0
{
public:
	static void Tick(RHI* rhi)
	{
		if (_done || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltl0n0"))
		{
			LogA("[mlt] 🧪 회차 121(C0 · L0 을 정직한 자로 다시)은 **꺼져 있다**(`-mltl0n0`)\n");
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
	// ⭐ **씨앗 2 진단을 먼저 돌렸다**(3.5분) — 자가 세고(`|d̄|/SE = 16.5`) `sd_run = 0` 임을 봤고,
	//   ⚠️ **관문 둘이 씨앗 수에 매여 있던 것**을 잡아 고쳤다(위 `kSignPass`·`regApply`).
	//   ⇒ ★ 이제 **판정용 12씨앗**.
	static constexpr uint32 kSeeds = 12u;
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
	static constexpr uint32 kSteps = 800u, kPerTick = 4u;

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
	static constexpr uint32 kPlates = 1u, kArms = 2u, kTgts = 4u;
	static constexpr uint32 kSymA = MLTP3Ctx::kStateAx + kN + 1u;    // 256

	enum { kEncInit, kEncTrain, kGather, kQuiesce, kBodyInit, kBodyTrain, kRep };

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

	inline static Array<float> _fPb, _fPt, _fPt2;
	inline static Array<float> _mPb[kTgts], _mPt[kTgts];
	inline static Array<uint32> _yPb[kTgts], _yPt[kTgts];
	inline static const uint32* _yTr = nullptr;
	inline static const uint32* _yTe = nullptr;

	// ⭐ **회차 121** — 바깥 반복(실행 잡음 ↔ 씨앗 잡음을 가른다 · 규율 32)
	static constexpr uint32 kOut = 2u;
	inline static uint32 _out = 0u;
	inline static float _ceOut[kOut][kArms][kTgts][kSeeds];
	inline static float _ce[kPlates][kArms][kTgts][kSeeds];
	inline static float _acc[kPlates][kArms][kTgts][kSeeds];
	inline static bool  _seedOk[kSeeds], _balOk[kSeeds], _repOk[kSeeds];

	inline static uint32 _rw = 0u, _ri = 0u, _rwait = 0u;
	inline static bool   _rpend = false;

	// ══════════════════════════════════════════════════════════════════
	// ⭐⭐ 회차 250 — **규율 27 로 `L0` 를 다시 읽는다**: 평균이 아니라 **분포**
	// ══════════════════════════════════════════════════════════════════
	//   ⚙️ `MLT.md` 가 이 부채를 명시로 적어 뒀다: *"L0(86~100) 결론도 「평균으로 읽은 것」이다 …
	//     분포 자로 다시 재면 흔들릴 수 있다."*
	//   ⭐ 선례가 같은 트랙에 있다 — **P4**: 103 이 평균으로 *"안 읽는다"* ⛔ → **104 가 분포로 철회**
	//     (폭 0.1864 · 상관 +0.4840 · 각 12/12).
	//   ⚠️⚠️ **여기서 규율 27 은 「평균 0」이 아니다** — 121 의 `d̄` 는 **유의하게 양수**다
	//     (+0.033 · `t` ≈ 4.7 = 학습이 **더 나쁘다**) ⇒ ★ 묻는 것은 *"평균이 0 을 숨기나"* 가 아니라
	//     ***"평균이 나쁜데 일부 표본은 확실히 좋나"*** 다.
	//   ★ 표본은 **`kPtCtx` = 512** 개(시험 문맥)다 — 낱말 넷이 아니다.
	inline static Array<double> _perA[kTgts], _perB[kTgts], _perS[kTgts];
	inline static Array<double> _d1, _d2;
	inline static Array<float>  _fPb0, _fPt0;
	inline static float _ceShuf[kOut][kTgts][kSeeds];   // ㈂ 섞음 팔의 CE
	inline static float _dSd[kOut][kTgts][kSeeds];      // ㉠ 폭 `sd(Δ)`
	inline static float _dNeg[kOut][kTgts][kSeeds];     // ㉡ `P(Δ < 0)` — 학습이 나은 표본의 몫
	inline static float _dCor[kOut][kTgts][kSeeds];     // ㉢ 두 절제의 일치 `corr`
	inline static bool  _dOn = false;
	inline static uint32 _dFail = 0u;

	// ⭐ **㈂ 특징 섞기** — 표현의 **열마다 다른 순열**로 표본 사이를 섞는다.
	//   ⚠️⚠️ **같은 순열이면 표본 순서만 바뀌어 정보가 그대로다** ⇒ 반드시 **열마다** 달라야 한다.
	//   ★ 정보만 지우고 **차원·규모·주변통계를 그대로** 둔다 ⇒ `㈁ 무작위 몸통`과 **다른 절제**다
	//     (규율 27 의 ㈏ 가 요구하는 그것). ⭐ 그리고 **몸통을 다시 안 돈다**.
	static void _ShufFeat(const Array<float>& src, uint32 n, Array<float>& dst, uint32 salt)
	{
		dst.Reset(0);
		for (uint32 i = 0; i < n * kFeat; ++i) dst.Add(0.0f);
		Array<uint32> idx;
		for (uint32 c = 0; c < kFeat; ++c)
		{
			idx.Reset(0);
			for (uint32 i = 0; i < n; ++i) idx.Add(i);
			uint32 rs = _seed * 2654435761u + salt + c * 40503u;
			for (uint32 i = n; i > 1u; --i)
			{
				rs = rs * 1664525u + 1013904223u;
				const uint32 j = rs % i;
				const uint32 tmp = idx[i - 1u]; idx.Data()[i - 1u] = idx[j]; idx.Data()[j] = tmp;
			}
			for (uint32 i = 0; i < n; ++i)
				dst.Data()[(uint64)i * kFeat + c] = src[(uint64)idx[i] * kFeat + c];
		}
	}

	static void _CopyFeat(const Array<float>& src, Array<float>& dst)
	{
		dst.Reset(0);
		for (uint32 i = 0; i < src.Count(); ++i) dst.Add(src[i]);
	}

	static void _ToBody() { _qWait = MLTEvalGate::kDelay; _st = kQuiesce; }
	static uint32 _AxOf(uint32 p) { (void)p; return MLTP3Ctx::kAxes; }
	static uint32 _CtxOf(uint32 p) { (void)p; return MLTP3Ctx::kCtx; }
	static uint32 _SymOf(uint32 p) { (void)p; return kSymA; }
	static const char* _PlateName(uint32 p) { (void)p; return "축13"; }
	static const char* _ArmName(uint32 a) { return (a == 0u) ? "㈀ 학습" : "㈁ 무작위"; }
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
		LogA("[mlt] 🧪 **회차 100 · 「과제에 필요한 낱말」과 「무관한 낱말」을 나란히**(⭐ 판정 회차)\n");
		LogA("[mlt] 🧪   ⚠️ **회차 99 보고의 내 진단을 정정한다** — *\"과제가 요구하는 게 적다\"* 는 틀렸다:\n");
		LogA("[mlt] 🧪     회차 85b 에서 몸통은 **복사바닥 1.0542 를 0.8777 로** 크게 넘었다(12/12) ⇒ ***과제는 잘 배운다.***\n");
		LogA("[mlt] 🧪   ⭐ **진짜 후보 = 「우리가 고른 낱말이 과제와 무관하다」** — 학습은 **과제에 필요한 것**을 뭉친다\n");
		LogA("[mlt] 🧪     ⚠️ 무작위 사영은 **입력 전체를 골고루** 나르므로 **무관한 양에서는 오히려 유리하다**\n");
		LogA("[mlt] 🧪   표적 넷(같은 자로 나란히) — **㊀ 뜻밖임**(손실의 주항) · **㊁ 지속개수**(과제가 직접 요구)\n");
		LogA("[mlt] 🧪     · ㊂ `yaw`(양성 · 규율 16) · **㊃ `minDOn`**(참조 · **무관** ⇒ 회차 97·99 의 5/12 재현 기대)\n");
		LogA("[mlt] 🧪   자·형식·팔은 **회차 99 그대로** — 축 %u · **대역별 풀링 %u대역 = %u차원**(⚠️ 선형) · ㈀ 학습 ↔ ㈁ 무작위\n",
			MLTP3Ctx::kAxes, kBands, kFeat);
		LogA("[mlt] 🧪   ⚠️ **주변분포는 「몸통 학습 코퍼스」에서만** 잡는다(시험을 훔쳐보지 않는다)\n");
		LogA("[mlt] 🧪   ⭐ **표제** — `CE(㈀·뜻밖임) < CE(㈁·뜻밖임)` ≥%u/12(규율 18 을 **과제에 필요한 낱말**에)\n", kSignPass);
		LogA("[mlt] 🎚️   ⭐ **예측** — 양성이 **두 판에서 비슷해진다** · **앵커 A/B 는 진짜 모른다**(그것이 이 회차의 값)\n");
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
						if (_cor == 1u) { _mPb[2].Add(w.State().yaw); _mPb[3].Add(dOn); }
						else if (_cor == 2u) { _mPt[2].Add(w.State().yaw); _mPt[3].Add(dOn); }
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
		_TaskOne(_pbA, kPbCtx, marg, _mPb[0], _mPb[1]);
		_TaskOne(_ptA, kPtCtx, marg, _mPt[0], _mPt[1]);
	}

	// ── 순위 계급(회차 87 · `sd = 0`) ────────────────────────────────
	static void _RankClass(const float* m, uint32 n, Array<uint32>& y)
	{
		y.Reset(0);
		for (uint32 i = 0; i < n; ++i) y.Add(0u);
		for (uint32 i = 0; i < n; ++i)
		{
			uint32 r = 0u;
			for (uint32 j = 0; j < n; ++j)
				if (m[j] < m[i] || (m[j] == m[i] && j < i)) ++r;
			y.Data()[i] = (r * kCls) / n;
		}
	}

	static void _MakeWords()
	{
		bool ok = true;
		const uint32 tgt = (kPtCtx + kCls / 2u) / kCls;
		for (uint32 t = 0; t < kTgts; ++t)
		{
			_RankClass(_mPb[t].Data(), kPbCtx, _yPb[t]);
			_RankClass(_mPt[t].Data(), kPtCtx, _yPt[t]);
			uint32 cnt[kCls] = { 0u, 0u, 0u };
			for (uint32 i = 0; i < kPtCtx; ++i) ++cnt[_yPt[t][i]];
			for (uint32 c = 0; c < kCls; ++c)
			{
				const uint32 d = (cnt[c] > tgt) ? (cnt[c] - tgt) : (tgt - cnt[c]);
				if (d > kBalSlack) ok = false;
			}
		}
		_balOk[_seed] = ok;
		LogA("[mlt] 🎚️ 씨앗 %2u · 균형 %s · 화면안 도형0 %u회 · minDOn 경계 %.3f~%.3f\n",
			_seed, ok ? "통과" : "⛔", _noShape, (double)_mPt[0][0], (double)_mPt[0][kPtCtx - 1u]);
	}

	// ── 몸통 ──────────────────────────────────────────────────────────
	static void _BodyBegin(RHI* rhi)
	{
		if (!_M.Setup(rhi, _SymOf(_plate), kN, _AxOf(_plate), kTime)) { _Fail("몸통 준비"); return; }
		if (_arm == 1u) { _RepBegin(0u); return; }        // ㈁ = 학습 0
		const bool okUp = _M.UploadPool(_trA.Val(), _trA.Tgt(), kPoolSteps)
			&& _M.UploadSymbolPool(_trA.Sym(), kPoolSteps);
		if (!okUp) { _Fail("학습 풀 업로드"); return; }
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

	// ── 표현 모으기 — `_rw` 0=프로브학습 · 1=프로브시험① · 2=프로브시험②(재현) ────
	static Array<float>& _FeatOf(uint32 rw) { return (rw == 0u) ? _fPb : ((rw == 1u) ? _fPt : _fPt2); }
	static uint32 _FeatCtx(uint32 rw) { return (rw == 0u) ? kPbCtx : kPtCtx; }

	static void _RepBegin(uint32 rw)
	{
		_rw = rw; _ri = 0u; _rpend = false; _rwait = 0u;
		const uint32 c = (rw == 0u) ? 1u : 2u;
		const uint32 nPool = (rw == 0u) ? kPbPool : kPtPool;
		const bool okUp = _M.UploadPool(_CorA(c).Val(), _CorA(c).Tgt(), nPool)
			&& _M.UploadSymbolPool(_CorA(c).Sym(), nPool);
		if (!okUp) { _Fail("프로브 풀 업로드"); return; }
		Array<float>& F = _FeatOf(rw);
		F.Reset(0);
		const uint32 need = _FeatCtx(rw) * kFeat;
		for (uint32 i = 0; i < need; ++i) F.Add(0.0f);
		_st = kRep;
	}

	// ⭐ **대역별 평균 풀링** — 상태 · 활성 · 앵커를 **따로** 평균해 이어붙인다.
	//   ⚠️ 판 A 는 앵커 축이 없으므로 그 대역이 **전부 0** 으로 남는다(영 대역).
	static void _RepStep()
	{
		if (_rpend)
		{
			if (_rwait > 0u) { --_rwait; return; }
			Array<float> rep;
			if (!_M.ReadRep(rep)) { _Fail("표현 리드백"); return; }
			Array<float>& F = _FeatOf(_rw);
			const uint32 A = _AxOf(_plate), C = _CtxOf(_plate);
			const uint32 nAnc = 0u;      // ⚠️ 판이 하나(축 13)라 앵커 대역이 없다
			for (uint32 b = 0; b < kBatch; ++b)
			{
				const uint32 ctx = (_ri - 1u) * kBatch + b;
				float* dst = F.Data() + (uint64)ctx * kFeat;
				for (uint32 d = 0; d < kFeat; ++d) dst[d] = 0.0f;
				for (uint32 t = 0; t < kTime; ++t)
					for (uint32 a = 0; a < A; ++a)
					{
						// 대역 = 0(상태 `a < 5`) · 1(활성 `5 ≤ a < 13`) · 2(앵커 `a ≥ 13`)
						const uint32 band = (a < kStateAx) ? 0u : ((a < kStateAx + kSlots) ? 1u : 2u);
						const float* src = rep.Data() + (uint64)(b * C + t * A + a) * kD;
						float* acc = dst + band * kD;
						for (uint32 d = 0; d < kD; ++d) acc[d] += src[d];
					}
				const float i0 = 1.0f / (float)(kTime * kStateAx);
				const float i1 = 1.0f / (float)(kTime * kSlots);
				for (uint32 d = 0; d < kD; ++d) { dst[d] *= i0; dst[kD + d] *= i1; }
				if (nAnc > 0u)
				{
					const float i2 = 1.0f / (float)(kTime * nAnc);
					for (uint32 d = 0; d < kD; ++d) dst[2u * kD + d] *= i2;
				}
				dst[kFeat - 1u] = 1.0f;                    // 편향
				for (uint32 d = 0; d < kFeat; ++d)
					if (!(dst[d] == dst[d]) || Abs(dst[d]) > 1.0e30f) _finite = false;
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
		bool same = true;
		const uint32 n = kPtCtx * kFeat;
		for (uint32 i = 0; i < n; ++i) if (_fPt[i] != _fPt2[i]) { same = false; break; }
		if (_plate == 0u && _arm == 0u) _repOk[_seed] = same; else _repOk[_seed] = _repOk[_seed] && same;
		_Judge();
	}

	// ── 선형 프로브(회차 88~98 과 같은 절차) ──────────────────────────
	inline static Array<float> _A, _B, _W, _Wb;

	// ⭐⭐ 회차 252 — **특징 배열·차원·표본수를 인자로 뺐다**(조건부 `V`-정보와 MDL 이 같은 식을 타야 한다).
	//   ⚠️ 기본값이 옛 동작과 **완전히 같다**(`Xin = nullptr` ⇒ `_fPb` · `nF = kFeat` · `nRow = kFitCtx`)
	//     ⇒ 연산 순서를 한 글자도 안 바꿨다 ⇒ **비트 동일**이다(규율 58).
	static bool _Fit(float lamScale, float* W, const float* Xin = nullptr,
		uint32 nF = kFeat, uint32 nRow = kFitCtx, const uint32* yIn = nullptr)
	{
		const float* X = (Xin != nullptr) ? Xin : _fPb.Data();
		const uint32* yy = (yIn != nullptr) ? yIn : _yTr;
		_A.Reset(0); _B.Reset(0);
		for (uint32 i = 0; i < nF * nF; ++i) _A.Add(0.0f);
		for (uint32 i = 0; i < nF * kCls; ++i) _B.Add(0.0f);
		float* A = _A.Data(); float* B = _B.Data();
		for (uint32 i = 0; i < nRow; ++i)
		{
			const float* x = X + (uint64)i * nF;
			for (uint32 j = 0; j < nF; ++j)
			{
				const float xj = x[j];
				if (xj == 0.0f) continue;
				float* row = A + (uint64)j * nF;
				for (uint32 k = 0; k <= j; ++k) row[k] += xj * x[k];
				B[(uint64)j * kCls + yy[i]] += xj;
			}
		}
		for (uint32 j = 0; j < nF; ++j)
			for (uint32 k = 0; k < j; ++k) A[(uint64)k * nF + j] = A[(uint64)j * nF + k];
		double tr = 0.0;
		for (uint32 j = 0; j < nF; ++j) tr += (double)A[(uint64)j * nF + j];
		const float lam = (float)(1.0e-2 * (double)lamScale * tr / (double)nF);
		for (uint32 j = 0; j < nF; ++j) A[(uint64)j * nF + j] += lam;
		if (!SolveSymPD(A, B, nF, kCls)) return false;
		for (uint32 i = 0; i < nF * kCls; ++i) W[i] = B[i];
		return true;
	}

	// ⭐⭐ 회차 250 — **표본별 NLL 을 같이 낸다**(규율 27 — 평균이 아니라 분포로 읽는다).
	//   ★ 루프가 이미 표본별 NLL 을 계산하고 **평균만 반환**하고 있었다 ⇒ 배관이 한 줄이다.
	//   ⚠️ 연산 순서를 한 글자도 안 바꿨다(`s += nll` 은 같은 값·같은 순서) ⇒ **비트 동일**이다.
	static double _Ce(const float* X, const uint32* y, uint32 n, const float* W, float tau, uint32* hit,
		double* per = nullptr, uint32 nF = kFeat)
	{
		double s = 0.0; uint32 h = 0u;
		for (uint32 i = 0; i < n; ++i)
		{
			const float* x = X + (uint64)i * nF;
			double z[kCls]; double mx = -1.0e30; uint32 arg = 0u;
			for (uint32 c = 0; c < kCls; ++c)
			{
				double v = 0.0;
				for (uint32 j = 0; j < nF; ++j) v += (double)x[j] * (double)W[(uint64)j * kCls + c];
				z[c] = v * (double)tau;
				if (z[c] > mx) { mx = z[c]; arg = c; }
			}
			double se = 0.0;
			for (uint32 c = 0; c < kCls; ++c) se += (double)Exp((float)(z[c] - mx));
			const double nll = (mx + (double)Log((float)se)) - z[y[i]];
			s += nll;
			if (per != nullptr) per[i] = nll;
			if (arg == y[i]) ++h;
		}
		if (hit != nullptr) *hit = h;
		return (n == 0u) ? 0.0 : (s / (double)n);
	}

	static float _FitTau(const float* Xc, const uint32* yc, const float* W, uint32 nF = kFeat)
	{
		float best = 1.0f; double bce = 1.0e30;
		for (int k = -8; k <= 24; ++k)
		{
			const float tau = Pow(2.0f, (float)k * 0.5f);
			const double ce = _Ce(Xc, yc, kCalCtx, W, tau, nullptr, nullptr, nF);
			if (ce < bce) { bce = ce; best = tau; }
		}
		const float lo = best * 0.5f, hi = best * 2.0f;
		for (int k = 0; k <= 16; ++k)
		{
			const float tau = lo + (hi - lo) * ((float)k / 16.0f);
			const double ce = _Ce(Xc, yc, kCalCtx, W, tau, nullptr, nullptr, nF);
			if (ce < bce) { bce = ce; best = tau; }
		}
		return best;
	}

	// ⭐⭐ 회차 252 — 특징 배열과 차원을 인자로 받는다(기본값 = 옛 동작 ⇒ 비트 동일).
	//   `Xpb`/`Xpt` 가 null 이면 `_fPb`/`_fPt` 를 쓴다.
	static bool _Probe(float& ceOut, float& accOut, double* per = nullptr,
		const float* Xpb = nullptr, const float* Xpt = nullptr, uint32 nF = kFeat)
	{
		const float* Pb = (Xpb != nullptr) ? Xpb : _fPb.Data();
		const float* Pt = (Xpt != nullptr) ? Xpt : _fPt.Data();
		const float* Xc = Pb + (uint64)kFitCtx * nF;
		const uint32* yc = _yTr + kFitCtx;
		_Wb.Reset(0);
		for (uint32 i = 0; i < nF * kCls; ++i) _Wb.Add(0.0f);
		float bestTau = 1.0f; double bce = 1.0e30;
		for (uint32 li = 0; li < kLams; ++li)
		{
			_W.Reset(0);
			for (uint32 i = 0; i < nF * kCls; ++i) _W.Add(0.0f);
			if (!_Fit(kLamGrid[li], _W.Data(), Pb, nF)) continue;
			const float tau = _FitTau(Xc, yc, _W.Data(), nF);
			const double ce = _Ce(Xc, yc, kCalCtx, _W.Data(), tau, nullptr, nullptr, nF);
			if (ce < bce)
			{
				bce = ce; bestTau = tau;
				for (uint32 i = 0; i < nF * kCls; ++i) _Wb.Data()[i] = _W[i];
			}
		}
		if (bce > 1.0e29) return false;
		uint32 hit = 0u;
		ceOut = (float)_Ce(Pt, _yTe, kPtCtx, _Wb.Data(), bestTau, &hit, per, nF);
		accOut = (float)hit / (float)kPtCtx;
		return true;
	}

	// ══════════════════════════════════════════════════════════════════
	// ⭐⭐ 회차 252 — 자 둘: **조건부 `V`-정보**와 **MDL 온라인 부호길이**
	// ══════════════════════════════════════════════════════════════════
	//   ⚙️ 251 딥리서치가 준 것. `MLT.md` 의 세 칸 표가 「언어 귀속 ↔ 과제 귀속」을 갈라 주지만
	//     컨셉의 *"언어 없이 **자란** 표현"* 에서 **「자란」**을 안 가른다.
	//   ⇒ ⭐ 조건부 `V`-정보 = `CE([기준선]) − CE([기준선 ; 학습])` = ***학습이 보탠 몫***.
	//   ⚠️⚠️ 이 양은 **이론상 항상 `≥ 0`** 이다(특징 집합이 커지면 더 못할 수 없다)
	//     ⇒ ★ 관문은 「0 보다 크나」가 아니라 **「차원만 늘린 널보다 크나」**이고 널 팔이 **필수**다.
	static constexpr uint32 kFeat2 = kFeat * 2u;
	inline static Array<float> _fPbL, _fPtL;    // ㈀ 학습 팔의 특징(저장)
	inline static Array<float> _cPb, _cPt;      // 이어붙인 특징 `[기준선 ; X]`
	inline static float _ceCat[kOut][kTgts][kSeeds];    // CE([기준선 ; 학습])
	inline static float _ceNul[kOut][kTgts][kSeeds];    // CE([기준선 ; 기준선섞음]) — 널
	inline static float _mdlL[kOut][kTgts][kSeeds];     // MDL 부호길이(학습 · 비트)
	inline static float _mdlB[kOut][kTgts][kSeeds];     // MDL 부호길이(기준선 · 비트)
	inline static bool  _cOn = false;
	inline static uint32 _cFail = 0u;

	// `[A ; B]` 로 이어붙인다(행 `n` · 각 `kFeat` 열 ⇒ `kFeat2` 열)
	static void _Cat(const Array<float>& a, const Array<float>& b, uint32 n, Array<float>& dst)
	{
		dst.Reset(0);
		for (uint32 i = 0; i < n * kFeat2; ++i) dst.Add(0.0f);
		for (uint32 i = 0; i < n; ++i)
		{
			for (uint32 c = 0; c < kFeat; ++c)
			{
				dst.Data()[(uint64)i * kFeat2 + c]          = a[(uint64)i * kFeat + c];
				dst.Data()[(uint64)i * kFeat2 + kFeat + c]  = b[(uint64)i * kFeat + c];
			}
		}
	}

	// ⭐ **MDL 온라인 부호길이**(Voita & Titov 2020) — 중첩 블록으로 누적한다.
	//   ★ 첫 블록은 균등 부호로 낸다(`t₁ · log₂ kCls`), 그 뒤 블록 `i` 는 **앞 블록들로 맞춘 프로브**로 낸다.
	//   ⚠️ λ 는 **고정**한다(격자를 돌면 블록마다 kLams 배가 된다 — 예산 밖).
	//   ⚠️ 단위는 **비트**다(CE 는 나트라 `÷ ln2`).
	static double _MdlBits(const Array<float>& Xpb, const uint32* y)
	{
		static const uint32 kFrac[8] = { 8u, 16u, 32u, 64u, 128u, 192u, 256u, 384u };
		double bits = (double)kFrac[0] * 1.5849625007f;   // log2(3) — 첫 블록은 균등 부호
		Array<float> W;
		for (uint32 b = 0; b + 1u < 8u; ++b)
		{
			const uint32 n0 = kFrac[b], n1 = kFrac[b + 1u];
			W.Reset(0);
			for (uint32 i = 0; i < kFeat * kCls; ++i) W.Add(0.0f);
			if (!_Fit(1.0f, W.Data(), Xpb.Data(), kFeat, n0, y)) return -1.0;
			// 다음 블록(`n0..n1`)을 그 프로브로 부호화한다
			const double ce = _Ce(Xpb.Data() + (uint64)n0 * kFeat, y + n0, n1 - n0,
				W.Data(), 1.0f, nullptr, nullptr, kFeat);
			bits += (double)(n1 - n0) * ce / 0.6931471805599453;
		}
		return bits;
	}

	// ⭐ 250 — 표본별 자리를 잡아 둔다(길이 `kPtCtx`)
	static double* _PerBuf(Array<double>& a)
	{
		a.Reset(0);
		for (uint32 i = 0; i < kPtCtx; ++i) a.Add(0.0);
		return a.Data();
	}

	static void _Judge()
	{
		for (uint32 t = 0; t < kTgts; ++t)
		{
			_yTr = _yPb[t].Data(); _yTe = _yPt[t].Data();
			// ⭐⭐ 250 — 표본별 CE 를 같이 받는다(규율 27)
			double* pb = _PerBuf((_arm == 0u) ? _perA[t] : _perB[t]);
			if (!_Probe(_ce[_plate][_arm][t][_seed], _acc[_plate][_arm][t][_seed], pb))
			{ _Fail("프로브"); return; }
		}
		// ══════════════════════════════════════════════════════════
		// ⭐⭐ 250 — **㈂ 특징 섞기**: ㈀ 의 표현을 섞어 **프로브만** 다시 맞춘다(몸통 재실행 0)
		// ══════════════════════════════════════════════════════════
		if (_arm == 0u)
		{
			_CopyFeat(_fPb, _fPb0); _CopyFeat(_fPt, _fPt0);
			_ShufFeat(_fPb0, kPbCtx, _fPb, 11u);
			_ShufFeat(_fPt0, kPtCtx, _fPt, 23u);
			for (uint32 t = 0; t < kTgts; ++t)
			{
				_yTr = _yPb[t].Data(); _yTe = _yPt[t].Data();
				float dummyAcc = 0.0f;
				if (!_Probe(_ceShuf[_out][t][_seed], dummyAcc, _PerBuf(_perS[t])))
				{ ++_dFail; break; }
			}
			// ⚠️ 상태를 더럽히지 않는다 — 원본을 되돌린다
			_CopyFeat(_fPb0, _fPb); _CopyFeat(_fPt0, _fPt);
			// ⭐⭐ 252 — ㈀ 의 특징을 저장한다(㈁ 에서 이어붙여야 한다)
			_CopyFeat(_fPb, _fPbL); _CopyFeat(_fPt, _fPtL);
		}
		// ══════════════════════════════════════════════════════════
		// ⭐⭐ 252 — **조건부 `V`-정보**와 **MDL**: ㈁(기준선) 자리에서 잰다
		// ══════════════════════════════════════════════════════════
		//   `CE([기준선])` 은 이미 `_ce[0][1][t][seed]` 다 ⇒ 여기서는 이어붙인 둘만 더 잰다.
		if (_arm == 1u && _fPbL.Count() > 0u)
		{
			// 널 팔의 재료 — 기준선을 섞은 것(차원만 늘리는 효과를 잰다)
			Array<float> nPb, nPt;
			_ShufFeat(_fPb, kPbCtx, nPb, 31u);
			_ShufFeat(_fPt, kPtCtx, nPt, 37u);
			for (uint32 t = 0; t < kTgts; ++t)
			{
				_yTr = _yPb[t].Data(); _yTe = _yPt[t].Data();
				float dummy = 0.0f;
				// ⭐⭐ 표제 — `[기준선 ; 학습]`
				_Cat(_fPb, _fPbL, kPbCtx, _cPb);
				_Cat(_fPt, _fPtL, kPtCtx, _cPt);
				if (!_Probe(_ceCat[_out][t][_seed], dummy, nullptr, _cPb.Data(), _cPt.Data(), kFeat2))
				{ ++_cFail; break; }
				// ⭐ 널 — `[기준선 ; 기준선섞음]`(정보 0 인 것을 같은 차원만큼 붙인다)
				_Cat(_fPb, nPb, kPbCtx, _cPb);
				_Cat(_fPt, nPt, kPtCtx, _cPt);
				if (!_Probe(_ceNul[_out][t][_seed], dummy, nullptr, _cPb.Data(), _cPt.Data(), kFeat2))
				{ ++_cFail; break; }
				// ⭐ MDL 온라인 부호길이 — 학습 ↔ 기준선(같은 차원 · 같은 λ)
				const double bl = _MdlBits(_fPbL, _yTr);
				const double bb = _MdlBits(_fPb,  _yTr);
				if (bl < 0.0 || bb < 0.0) { ++_cFail; break; }
				_mdlL[_out][t][_seed] = (float)bl;
				_mdlB[_out][t][_seed] = (float)bb;
			}
			if (_cFail == 0u) _cOn = true;
		}
		// ⭐⭐ 250 — 두 팔이 다 끝난 자리에서 **분포 자 셋**을 낸다
		//   `Δ_무작위 = CE(㈀) − CE(㈁)` · `Δ_섞음 = CE(㈀) − CE(㈂)`  (음수 = 학습이 낫다)
		if (_arm == 1u && _dFail == 0u)
		{
			for (uint32 t = 0; t < kTgts; ++t)
			{
				if (_perA[t].Count() < kPtCtx || _perB[t].Count() < kPtCtx
				 || _perS[t].Count() < kPtCtx) { ++_dFail; break; }
				_d1.Reset(0); _d2.Reset(0);
				double m1 = 0.0, m2 = 0.0; uint32 neg = 0u;
				for (uint32 i = 0; i < kPtCtx; ++i)
				{
					const double a = _perA[t][i];
					const double x1 = a - _perB[t][i];
					const double x2 = a - _perS[t][i];
					_d1.Add(x1); _d2.Add(x2);
					m1 += x1; m2 += x2;
					if (x1 < 0.0) ++neg;
				}
				m1 /= (double)kPtCtx; m2 /= (double)kPtCtx;
				double v1 = 0.0, v2 = 0.0, cv = 0.0;
				for (uint32 i = 0; i < kPtCtx; ++i)
				{
					const double e1 = _d1[i] - m1, e2 = _d2[i] - m2;
					v1 += e1 * e1; v2 += e2 * e2; cv += e1 * e2;
				}
				_dSd[_out][t][_seed]  = (float)Sqrt((float)(v1 / (double)(kPtCtx - 1u)));
				_dNeg[_out][t][_seed] = (float)neg / (float)kPtCtx;
				_dCor[_out][t][_seed] = (v1 > 1.0e-30 && v2 > 1.0e-30)
				                      ? (float)(cv / (double)Sqrt((float)(v1 * v2))) : 0.0f;
			}
			_dOn = true;
		}
		// ⚠️ **회차 100 실행 때 이 줄의 이름표가 낡아 있었다**(회차 99 것 그대로 — `㊀ minDOn`/`㊁ yaw`).
		//   ★ 숫자는 맞았고 **요약 블록은 `_TgtName(t)` 을 쓰므로 정확했다** ⇒ 판정에는 영향이 없었다.
		//   ⚠️ 그래도 로그를 나중에 읽는 사람이 오독하므로 고쳐 둔다.
		LogA("[mlt] 🧪   %s · %s 씨앗 %2u · **㊀ 뜻밖임 %.5f(%.1f%%)** · ㊁ 지속개수 %.5f(%.1f%%) │ ㊂ yaw %.5f · ㊃ minDOn %.5f\n",
			_PlateName(_plate), _ArmName(_arm), _seed,
			(double)_ce[_plate][_arm][0][_seed], 100.0 * (double)_acc[_plate][_arm][0][_seed],
			(double)_ce[_plate][_arm][1][_seed], 100.0 * (double)_acc[_plate][_arm][1][_seed],
			(double)_ce[_plate][_arm][2][_seed], (double)_ce[_plate][_arm][3][_seed]);
		if (++_arm < kArms) { _ToBody(); return; }
		_arm = 0u;
		if (++_plate < kPlates) { _ToBody(); return; }
		_plate = 0u;
		// ⭐ **회차 121 이 더한 것 — 바깥 반복**(같은 씨앗을 다시 돈다).
		//   ★ 그래야 **실행 잡음과 씨앗 잡음을 갈라 잰다**(규율 32 의 형식).
		//   ⚠️ 코퍼스·표현은 **다시 안 모은다**(결정적임이 증명됐다) — 몸통만 다시 돈다.
		for (uint32 t = 0; t < kTgts; ++t)
			for (uint32 a = 0; a < kArms; ++a) _ceOut[_out][a][t][_seed] = _ce[0][a][t][_seed];
		if (++_out < kOut) { _ToBody(); return; }
		_out = 0u;
		_seedOk[_seed] = _finite;
		++_seed; _st = kEncInit;
	}

	static void _Summary()
	{
		double m[kPlates][kArms][kTgts], ma[kPlates][kArms][kTgts];
		uint32 g[kPlates][kArms][kTgts];
		for (uint32 p = 0; p < kPlates; ++p) for (uint32 a = 0; a < kArms; ++a) for (uint32 t = 0; t < kTgts; ++t)
		{ m[p][a][t] = 0.0; ma[p][a][t] = 0.0; g[p][a][t] = 0u; }
		uint32 ok = 0u, bal = 0u, rep = 0u;
		uint32 beat[kTgts];                       // ⭐ 규율 18(`㈀<㈁`)을 **표적마다**
		for (uint32 t = 0; t < kTgts; ++t) beat[t] = 0u;
		double gap = 0.0;
		for (uint32 s = 0; s < kSeeds; ++s)
		{
			if (!_seedOk[s]) continue;
			++ok; if (_balOk[s]) ++bal; if (_repOk[s]) ++rep;
			for (uint32 p = 0; p < kPlates; ++p) for (uint32 a = 0; a < kArms; ++a) for (uint32 t = 0; t < kTgts; ++t)
			{
				m[p][a][t] += _ce[p][a][t][s]; ma[p][a][t] += _acc[p][a][t][s];
				if (_ce[p][a][t][s] < kUnif) ++g[p][a][t];
			}
			// ⭐ **표제** — 규율 18 을 **표적마다** 센다: `CE(㈀ 학습) < CE(㈁ 무작위)`
			for (uint32 t = 0; t < kTgts; ++t)
				if (_ce[0][0][t][s] < _ce[0][1][t][s]) ++beat[t];
			gap += (double)(_ce[0][1][0][s] - _ce[0][0][0][s]);   // 뜻밖임의 이득(㈁ − ㈀)
		}
		if (ok > 0u)
		{
			for (uint32 p = 0; p < kPlates; ++p) for (uint32 a = 0; a < kArms; ++a) for (uint32 t = 0; t < kTgts; ++t)
			{ m[p][a][t] /= ok; ma[p][a][t] /= ok; }
			gap /= ok;
		}
		const bool plumb = (bal == ok) && (rep == ok) && _finite && (ok > 0u);
		const bool pos  = (g[0][0][2] >= kSignPass);        // ㊂ yaw 양성(규율 16)
		const bool p1   = (beat[0] >= kSignPass);           // ⭐ 표제 — 뜻밖임
		const bool p2   = (beat[1] >= kSignPass);           // ⭐ 표제′ — 지속개수
		const bool pRef = (beat[3] >= kSignPass);           // 참조 — minDOn(⚠️ 안 서야 재현)

		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🧪 **회차 100 · 과제에 필요한 낱말 ↔ 무관한 낱말** — 읽은 씨앗 %u/%u\n", ok, kSeeds);
		LogA("[mlt] 🧪   ⚠️ 견줄 것 — 규율 18(`㈀<㈁`)이 회차 97 **5/12** · 98 **4/12** · 99 **5·6/12** 로 **세 번 다 졌다**\n");
		LogA("[mlt] 🧪   배관 — ㈃ 균형 **%u/%u** · ㈄ 얼림/재현 **%u/%u** · 화면안 도형0 **%u회** → %s\n",
			bal, ok, rep, ok, _noShape, plumb ? "통과" : "⛔");
		LogA("[mlt] 🧪   균등바닥 **%.4f**(ln3) · 특징 **%u**(대역 %u × %u + 편향) · 축 %u\n",
			(double)kUnif, kFeat, kBands, kD, MLTP3Ctx::kAxes);
		for (uint32 t = 0; t < kTgts; ++t)
			LogA("[mlt] 🧪   **%s** — ㈀ 학습 **%.4f**(<ln3 %u/%u · %.1f%%) · ㈁ 무작위 %.4f(%u/%u · %.1f%%) │ **규율18 `㈀<㈁` %u/%u**\n",
				_TgtName(t),
				m[0][0][t], g[0][0][t], kSeeds, 100.0 * ma[0][0][t],
				m[0][1][t], g[0][1][t], kSeeds, 100.0 * ma[0][1][t],
				beat[t], kSeeds);
		LogA("[mlt] 🧪   (회차 100 의 자) **표제 ㊀ 뜻밖임 %u/%u ≥%u** → %s(이득 %+.4f) · **표제′ ㊁ %u/%u** → %s\n",
			beat[0], kSeeds, kSignPass, p1 ? "✅" : "⛔", gap, beat[1], kSeeds, p2 ? "✅" : "⛔");
		// ══════════════════════════════════════════════════════════════
		// ⭐ **회차 121 의 표제 — 짝지은 차 `d = CE(㈀) − CE(㈁)` 의 평균 ± SE**
		// ══════════════════════════════════════════════════════════════
		//   ⚠️ 회차 100 은 **부호검정**이었다(크기를 버린다 · 규율 31).
		//   ★ 여기서는 **크기와 상한**으로 말한다(규율 26) + **잡음 두 항을 갈라 잰다**(규율 32).
		LogA("[mlt] 🧪   ── ⭐ **회차 121 의 자 — 짝지은 `d = CE(㈀) − CE(㈁)`** ──\n");
		LogA("[mlt] 🧪     낱말        │ d̄        · sd_씨앗  · SE      · **|d̄|/SE** │ sd_run(실행)\n");
		for (uint32 t = 0; t < kTgts; ++t)
		{
			// 씨앗별 `d`(바깥 반복 평균) · 그리고 바깥 반복 사이 폭 = 실행 잡음
			double dm = 0.0, runSum = 0.0; uint32 n = 0u;
			double dv[kSeeds];
			for (uint32 s = 0; s < kSeeds; ++s)
			{
				if (!_seedOk[s]) continue;
				double a0 = 0.0, a1 = 0.0;
				for (uint32 o = 0; o < kOut; ++o)
				{ a0 += (double)_ceOut[o][0][t][s]; a1 += (double)_ceOut[o][1][t][s]; }
				a0 /= (double)kOut; a1 /= (double)kOut;
				dv[n] = a0 - a1; dm += dv[n]; ++n;
				// ⭐ 실행 잡음 — 같은 씨앗의 바깥 반복 사이 `d` 의 폭
				double r0 = (double)_ceOut[0][0][t][s] - (double)_ceOut[0][1][t][s];
				double r1 = (double)_ceOut[1][0][t][s] - (double)_ceOut[1][1][t][s];
				runSum += Abs((float)(r1 - r0)) / 1.414213562;   // 두 점의 sd 추정
			}
			if (n == 0u) continue;
			dm /= (double)n;
			double vv = 0.0;
			for (uint32 i = 0; i < n; ++i) { const double e = dv[i] - dm; vv += e * e; }
			const double sd = (n > 1u) ? Sqrt((float)(vv / (double)(n - 1u))) : 0.0;
			const double se = sd / Sqrt((float)n);
			const double tt = (se > 1.0e-12) ? (Abs(dm) / se) : 0.0;
			LogA("[mlt] 🧪     %s │ %+.5f · %.5f · %.5f · **%6.2f** │ %.5f%s\n",
				_TgtName(t), dm, sd, se, tt, runSum / (double)n,
				(t == 0u) ? "   ⭐ **표제**" : "");
		}
		// ══════════════════════════════════════════════════════════════
		// ⭐⭐ **회차 250 — 규율 27: 평균이 아니라 분포로 읽는다**(표본 512)
		// ══════════════════════════════════════════════════════════════
		{
			LogA("[mlt] 🧪   ── ⭐⭐ **회차 250 — 규율 27 로 다시 읽는다**(표본 **%u** · 낱말 넷이 아니다) ──\n", kPtCtx);
			LogA("[mlt] 🧪     ⚙️ `MLT.md` 의 부채: *\"L0 결론도 「평균으로 읽은 것」이다 … 분포 자로 다시 재면 흔들릴 수 있다\"*\n");
			LogA("[mlt] 🧪     ⭐ 선례 — **P4**: 103 이 평균으로 「안 읽는다」 ⛔ → **104 가 분포로 철회**(폭 0.1864 · 상관 +0.4840)\n");
			LogA("[mlt] 🧪     ⚠️⚠️ 여기서 규율 27 은 **「평균 0」이 아니다** — 121 의 `d̄` 가 **유의하게 양수**(학습이 더 나쁘다)\n");
			LogA("[mlt] 🧪        ⇒ ★ 묻는 것은 ***\"평균이 나쁜데 일부 표본은 확실히 좋나\"*** 다\n");
			LogA("[mlt] 🧪     ⭐ 두 절제 — ㈁ **무작위 몸통** ↔ 🆕 ㈂ **특징 섞기**(열마다 다른 순열 · 몸통 재실행 0)\n");
			LogA("[mlt] 🧪        ⚠️ 부호를 미리 적었다(📌 D50): 학습이 그 낱말을 나르면 **두 절제가 같이 아프다** ⇒ `corr > 0`\n");
			LogA("[mlt] 🧪     🚪 ① **배관** — 실패 **%u회** → %s\n", _dFail,
				(_dOn && _dFail == 0u) ? "✅ **살아 있다**" : "⛔⛔ **죽었다** — ★ 아래 숫자를 읽지 마라");
			if (_dOn && _dFail == 0u)
			{
				LogA("[mlt] 🧪     낱말                  │ ㉠ 폭 sd(Δ) │ ⭐⭐ ㉡ P(Δ<0) │ ⭐⭐ ㉢ corr │ ㈂ 섞음 CE\n");
				// 낱말마다 12씨앗 짝지은 통계(바깥은 평균으로 접는다 — `_ce` 와 같은 규칙)
				double negD[kTgts], negT[kTgts], corD[kTgts], corT[kTgts];
				for (uint32 t = 0; t < kTgts; ++t)
				{
					double sdM = 0.0, ngM = 0.0, crM = 0.0, shM = 0.0; uint32 n = 0u;
					double ngV[kSeeds], crV[kSeeds];
					for (uint32 s = 0; s < kSeeds; ++s)
					{
						if (!_seedOk[s]) continue;
						double sd = 0.0, ng = 0.0, cr = 0.0, sh = 0.0;
						for (uint32 o = 0; o < kOut; ++o)
						{ sd += _dSd[o][t][s]; ng += _dNeg[o][t][s]; cr += _dCor[o][t][s]; sh += _ceShuf[o][t][s]; }
						sd /= (double)kOut; ng /= (double)kOut; cr /= (double)kOut; sh /= (double)kOut;
						ngV[n] = ng - 0.5;   // ⭐ 표제 = **0.5 에서 얼마나 뜨나**
						crV[n] = cr;
						sdM += sd; ngM += ng; crM += cr; shM += sh; ++n;
					}
					if (n == 0u) { negD[t] = negT[t] = corD[t] = corT[t] = 0.0; continue; }
					sdM /= (double)n; ngM /= (double)n; crM /= (double)n; shM /= (double)n;
					// 짝지은 SE(씨앗 사이)
					double vn = 0.0, vc = 0.0;
					const double mn = ngM - 0.5;
					for (uint32 i = 0; i < n; ++i)
					{ const double a = ngV[i] - mn, b = crV[i] - crM; vn += a * a; vc += b * b; }
					const double sen = (n > 1u) ? Sqrt((float)(vn / (double)(n - 1u) / (double)n)) : 0.0;
					const double sec = (n > 1u) ? Sqrt((float)(vc / (double)(n - 1u) / (double)n)) : 0.0;
					negD[t] = mn; negT[t] = (sen > 1.0e-12) ? Abs(mn) / sen : 0.0;
					corD[t] = crM; corT[t] = (sec > 1.0e-12) ? Abs(crM) / sec : 0.0;
					LogA("[mlt] 🧪     %s │ %9.5f │ **%.4f**(%+.4f · t %5.2f) │ **%+.4f**(t %5.2f) │ %.5f\n",
						_TgtName(t), sdM, ngM, mn, negT[t], crM, corT[t], shM);
				}
				LogA("[mlt] 🧪     ⭐ 🚪 ③ **눈금(㈐)** — ㊂ yaw 폭 ↔ ㊃ minDOn 폭 · 규율 27 이 이 팔을 넣은 이유\n");
				LogA("[mlt] 🧪     ⭐⭐ 🚪 ④ **표제** — ㊀ 뜻밖임 `P(Δ<0)` 가 0.5 에서 뜨나: `%+.4f` · t **%.2f** → %s\n",
					negD[0], negT[0],
					(negT[0] >= 3.0)
						? ((negD[0] > 0.0)
							? "🎉 ⭐ **뒤집혔다** — 표본 대부분에서 학습이 낫다(P4 104 와 같은 모양)"
							: "⛔ **분포로도 학습이 덜 담는다** ⇒ 121 의 답이 분포로도 선다")
						: "🔶 **0.5 근처다** — ★ 규율 27 이 여기서는 아무것도 안 바꾼다(규율 13-a 로 적는다)");
				LogA("[mlt] 🧪     ⭐⭐ 🚪 ⑤ **두 절제의 일치** — ㊀ `corr` **%+.4f** · t **%.2f** → %s\n",
					corD[0], corT[0],
					(corT[0] >= 3.0)
						? ((corD[0] > 0.0) ? "✅ **같이 아프다**(예측한 부호)" : "⚠️⚠️ **부호가 반대다** — ★ 📌 D50 의 그 사고 자리")
						: "⛔ **안 선다** — ★ 규율 27 이 「진짜 자」라 부른 것이 이 예산으로 안 잡힌다");
				LogA("[mlt] 🧪     ⚠️ 🚪 ⑥ **음성 대조**(규율 88) — ㊃ minDOn 에서 ④⑤ 가 **안 서야** 한다: t %.2f · %.2f → %s\n",
					negT[3], corT[3],
					(negT[3] < 3.0 && corT[3] < 3.0) ? "✅ **안 선다**"
					                                 : "⛔⛔ **음성 대조가 섰다** — ★ 자가 낱말이 아닌 것을 재고 있다");
			}
		}
		// ══════════════════════════════════════════════════════════════
		// ⭐⭐⭐ **회차 252 — 학습이 보탠 몫이 있나**(조건부 `V`-정보 · MDL)
		// ══════════════════════════════════════════════════════════════
		{
			LogA("[mlt] 🧪   ── ⭐⭐⭐ **회차 252 — 학습이 보탠 몫**(조건부 `V`-정보 · MDL) ──\n");
			LogA("[mlt] 🧪     ⚙️ 251 딥리서치: *\"기준선보다 높으면 담았다\"* 를 **버리고** ***기준선에 없고 표현에만 있는 정보***를 잰다\n");
			LogA("[mlt] 🧪        (Hewitt·Ethayarajh·Liang·Manning 2021 조건부 `V`-정보 · Voita & Titov 2020 MDL)\n");
			LogA("[mlt] 🧪     ⭐⭐ 그리고 **`MLT.md` 의 세 칸 표가 이미 옳았다** — 관문은 *\"프로브의 정확도\"* 이지 **무작위 대비가 아니다**\n");
			LogA("[mlt] 🧪        ⇒ 학습 CE(㊂ %.4f · ㊀ %.4f) ≪ `ln3` %.4f ⇒ ✅ **첫째 칸 = 「언어는 가리키는 것」**\n",
				(double)_ce[0][0][2][0], (double)_ce[0][0][0][0], (double)kUnif);
			LogA("[mlt] 🧪        ⚠️ 100·121·250 이 「무작위 몸통 팔」을 **표제 판정자로 승격**시켰다 — 그것은 셋째 칸의 **보조**다\n");
			LogA("[mlt] 🧪     ⚠️⚠️ 조건부 `V`-정보는 **이론상 늘 ≥ 0** 이다 ⇒ 관문은 **널(차원만 늘림)보다 크나**다\n");
			LogA("[mlt] 🧪     🚪 ① **배관** — 실패 **%u회** → %s\n", _cFail,
				(_cOn && _cFail == 0u) ? "✅ **살아 있다**" : "⛔⛔ **죽었다** — ★ 아래 숫자를 읽지 마라");
			if (_cOn && _cFail == 0u)
			{
				LogA("[mlt] 🧪     낱말                  │ CE(기준선) │ CE(기준+학습) │ ⭐⭐ 조건부V │ CE(기준+섞음) │ ⭐ 널\n");
				double gd[kTgts], gt[kTgts], nd[kTgts];
				for (uint32 t = 0; t < kTgts; ++t)
				{
					double bM = 0.0, cM = 0.0, nM = 0.0; uint32 n = 0u;
					double gv[kSeeds];
					for (uint32 s = 0; s < kSeeds; ++s)
					{
						if (!_seedOk[s]) continue;
						double b = 0.0, c = 0.0, u = 0.0;
						for (uint32 o = 0; o < kOut; ++o)
						{ b += _ce[0][1][t][s]; c += _ceCat[o][t][s]; u += _ceNul[o][t][s]; }
						b /= (double)kOut; c /= (double)kOut; u /= (double)kOut;
						gv[n] = b - c;               // ⭐ 조건부 `V`-정보(나트) — 클수록 학습이 보탰다
						bM += b; cM += c; nM += (b - u); ++n;
					}
					if (n == 0u) { gd[t] = gt[t] = nd[t] = 0.0; continue; }
					bM /= (double)n; cM /= (double)n; nM /= (double)n;
					double gm = 0.0;
					for (uint32 i = 0; i < n; ++i) gm += gv[i];
					gm /= (double)n;
					double vv = 0.0;
					for (uint32 i = 0; i < n; ++i) { const double e = gv[i] - gm; vv += e * e; }
					const double se = (n > 1u) ? Sqrt((float)(vv / (double)(n - 1u) / (double)n)) : 0.0;
					gd[t] = gm; gt[t] = (se > 1.0e-12) ? Abs(gm) / se : 0.0; nd[t] = nM;
					LogA("[mlt] 🧪     %s │  %.5f  │   %.5f   │ **%+.5f**(t %5.2f) │  %.5f  │ %+.5f\n",
						_TgtName(t), bM, cM, gm, gt[t], bM - nM, nM);
				}
				LogA("[mlt] 🧪     ⭐⭐ 🚪 ③ **표제** — ㊀ 뜻밖임 조건부 `V`-정보 **%+.5f** · t **%.2f** → %s\n",
					gd[0], gt[0], (gt[0] >= 3.0) ? "✅ **잡음보다 크다**" : "⛔ **안 선다**");
				LogA("[mlt] 🧪     ⭐⭐ 🚪 ④ **널(차원만 늘림)** — ㊀ %+.5f → %s\n", nd[0],
					(gd[0] > nd[0])
						? "✅ ⭐ **표제가 널을 넘는다** ⇒ ***학습이 보탠 몫이 있다***"
						: "⛔⛔ **널이 표제를 넘거나 같다** — ★ 자가 **차원 수**를 재고 있다 ⇒ 판정불가");
				LogA("[mlt] 🧪     ⭐ 🚪 ⑤ **양성 대조** — ㊂ yaw 는 「학습이 버린 것」이라 보탤 것이 적어야 한다: ㊀ %+.5f ↔ ㊂ %+.5f → %s\n",
					gd[0], gd[2], (gd[0] > gd[2]) ? "✅ **㊀ > ㊂**" : "⚠️ **㊂ 가 더 크다** — ★ 그 자리를 적고 다시 읽는다");
				LogA("[mlt] 🧪     ⚠️ 🚪 ⑥ **MDL 온라인 부호길이**(비트 · 낮을수록 좋다)\n");
				LogA("[mlt] 🧪        낱말                  │ 학습     │ 기준선   │ 차(학습−기준)\n");
				for (uint32 t = 0; t < kTgts; ++t)
				{
					double lM = 0.0, bM = 0.0; uint32 n = 0u;
					for (uint32 s = 0; s < kSeeds; ++s)
					{
						if (!_seedOk[s]) continue;
						for (uint32 o = 0; o < kOut; ++o) { lM += _mdlL[o][t][s]; bM += _mdlB[o][t][s]; }
						++n;
					}
					if (n == 0u) continue;
					lM /= (double)(n * kOut); bM /= (double)(n * kOut);
					LogA("[mlt] 🧪        %s │ %8.1f │ %8.1f │ **%+8.1f**\n", _TgtName(t), lM, bM, lM - bM);
				}
				LogA("[mlt] 🧪        ⓘ **문턱 없다**(등록문의 그 자리) — ★ CE 판정과 **갈리나**만 본다(Voita 의 뒤집힘 선례)\n");
			}
		}
		// ══════════════════════════════════════════════════════════════
		// ⭐⭐ **회차 253 — 씨앗 `σ` 의 정체**(공용 규율 **3-f** 진단)
		// ══════════════════════════════════════════════════════════════
		//   ⚙️ 3-f: *"씨앗 간 `σ` 는 잡음이 아니라 「굳은 후보의 분포」일 수 있다 — 뭉치면
		//     씨앗을 늘려도 안 줄고 `√n` 가정이 깨진다."*
		//   ⚠️⚠️ 우리에게 의심할 **구조적 이유**가 있다(📌 D26): **초기화가 고정**이라 씨앗은
		//     「세계 뽑기」만 바꾼다 ⇒ 후보 집합이 **작은 이산 집합**이 되기 쉽다.
		//   ⭐ **널을 손으로 먼저 계산했다**(📌 D51 의 교훈):
		//     간격이 대략 지수분포면 `P(gap < 0.05·평균) ≈ 1 − e^{−0.05} = 0.0488`
		//     ⇒ 기대 `11 × 0.0488 = 0.54` · `sd = √(11·0.0488·0.9512) = 0.71` ⇒ **문턱 3**.
		//   ⭐ 그리고 **음성 대조가 이미 있다** — ㊃ `minDOn`(무관 낱말 · 250 에서 `t` 0.82)
		//     ⇒ ★ **모의 난수가 필요 없다**(RNG·삼각함수 0줄).
		{
			LogA("[mlt] 🧪   ── ⭐⭐ **회차 253 — 씨앗 `σ` 의 정체**(공용 규율 3-f 진단) ──\n");
			LogA("[mlt] 🧪     ⚙️ 뭉치면 **씨앗을 늘려도 안 줄고 `√n` 가정이 깨진다** ⇒ 250·252 의 `t` 가 그 위에 서 있다\n");
			LogA("[mlt] 🧪     ⚠️ 의심할 근거 = 📌 **D26**(초기화가 **고정** ⇒ 씨앗은 「세계 뽑기」만 바꾼다)\n");
			LogA("[mlt] 🧪     ⭐ 손계산 널 — 「거의 0 인 간격」 기대 **0.54** · sd **0.71** ⇒ 🚪 문턱 **3**\n");
			LogA("[mlt] 🧪        (간격이 대략 지수분포면 `P(gap < 0.05·평균) = 1 − e^-0.05 = 0.0488` · 간격 11개)\n");
			LogA("[mlt] 🧪     ⚠️ 자릿수로만 읽는다 — 정규분포는 밀도 높은 곳에서 작은 간격이 더 난다\n");
			double z0[kTgts] = { 0.0, 0.0, 0.0, 0.0 };
			for (uint32 t = 0; t < kTgts; ++t)
			{
				// 씨앗별 `d`(바깥 평균) — 250·252 의 표제 자와 **같은 값**
				double v[kSeeds]; uint32 n = 0u;
				for (uint32 s = 0; s < kSeeds; ++s)
				{
					if (!_seedOk[s]) continue;
					double a0 = 0.0, a1 = 0.0;
					for (uint32 o = 0; o < kOut; ++o)
					{ a0 += (double)_ceOut[o][0][t][s]; a1 += (double)_ceOut[o][1][t][s]; }
					v[n++] = a0 / (double)kOut - a1 / (double)kOut;
				}
				if (n < 3u) continue;
				// 삽입 정렬
				for (uint32 i = 1u; i < n; ++i)
				{
					const double x = v[i]; uint32 j = i;
					while (j > 0u && v[j - 1u] > x) { v[j] = v[j - 1u]; --j; }
					v[j] = x;
				}
				const uint32 m = n - 1u;
				double gsum = 0.0, gmax = 0.0;
				for (uint32 i = 0; i < m; ++i)
				{ const double g = v[i + 1u] - v[i]; gsum += g; if (g > gmax) gmax = g; }
				const double gmean = gsum / (double)m;
				uint32 zero = 0u;
				if (gmean > 1.0e-30)
					for (uint32 i = 0; i < m; ++i)
						if ((v[i + 1u] - v[i]) < 0.05 * gmean) ++zero;
				z0[t] = (double)zero;
				LogA("[mlt] 🧪     %s │ ⭐ 거의0 간격 **%u** · 실효 후보 **%u** · 최대÷평균 %5.2f\n",
					_TgtName(t), zero, n - zero, (gmean > 1.0e-30) ? (gmax / gmean) : 0.0);
				// 정렬된 12값을 그대로 찍는다(규율 3-f: *"정렬해서 찍기만 하면 된다"*)
				LogA("[mlt] 🧪        정렬: %+.4f %+.4f %+.4f %+.4f %+.4f %+.4f %+.4f %+.4f %+.4f %+.4f %+.4f %+.4f\n",
					v[0], v[1], v[2], (n>3u)?v[3]:0.0, (n>4u)?v[4]:0.0, (n>5u)?v[5]:0.0,
					(n>6u)?v[6]:0.0, (n>7u)?v[7]:0.0, (n>8u)?v[8]:0.0, (n>9u)?v[9]:0.0,
					(n>10u)?v[10]:0.0, (n>11u)?v[11]:0.0);
			}
			LogA("[mlt] 🧪     ⭐⭐ 🚪 ③ **표제** — ㊀ 뜻밖임의 「거의0 간격」 **%.0f** ≥ 3 → %s\n", z0[0],
				(z0[0] >= 3.0)
					? "⚠️⚠️ **뭉쳤다** — ★ 250·252 의 `t` 는 **`√n` 가정 위**다 ⇒ 📌 D55 를 그만큼 깎아 읽는다"
					: "✅ **연속이다** — ★ 250·252 의 `t` 가 **그대로 선다**");
			LogA("[mlt] 🧪     ⭐ 🚪 ④ **음성 대조** — ㊃ minDOn %.0f < 3 → %s\n", z0[3],
				(z0[3] < 3.0) ? "✅ **안 뭉친다**"
				              : "⛔⛔ **음성 대조도 뭉쳤다** — ★ 자가 낱말과 무관한 것을 잰다 ⇒ **판정불가**");
			LogA("[mlt] 🧪     ⭐ 🚪 ⑤ **양성 대조**(관찰) — ㊂ yaw %.0f(`d̄` 가 0.254 로 크다)\n", z0[2]);
			LogA("[mlt] 🧪        ⓘ 244 의 「실효 이름 수 `e^H` **7.09**」와 자릿수가 같으면 우연이 아니다(규율 68)\n");
		}
		// ⭐ **회차 121 의 판정** — 표제(뜻밖임)의 `|d̄|/SE` 로 읽는다
		double dm0 = 0.0; uint32 n0 = 0u; double dv0[kSeeds];
		for (uint32 s = 0; s < kSeeds; ++s)
		{
			if (!_seedOk[s]) continue;
			double a0 = 0.0, a1 = 0.0;
			for (uint32 o = 0; o < kOut; ++o)
			{ a0 += (double)_ceOut[o][0][0][s]; a1 += (double)_ceOut[o][1][0][s]; }
			dv0[n0] = a0 / (double)kOut - a1 / (double)kOut; dm0 += dv0[n0]; ++n0;
		}
		double se0 = 0.0, tt0 = 0.0;
		if (n0 > 1u)
		{
			dm0 /= (double)n0;
			double vv = 0.0;
			for (uint32 i = 0; i < n0; ++i) { const double e = dv0[i] - dm0; vv += e * e; }
			se0 = Sqrt((float)(vv / (double)(n0 - 1u))) / Sqrt((float)n0);
			tt0 = (se0 > 1.0e-12) ? (Abs(dm0) / se0) : 0.0;
		}
		// ⭐ 회귀 관문 — 회차 100 의 ㈀ CE 넷과 ±0.02 안인가
		static constexpr float kRef100[kTgts] = { 0.7481f, 1.0903f, 0.5812f, 1.0793f };
		// ⚠️⚠️ **씨앗 수가 12 일 때만 견준다** — 회차 100 값이 **12씨앗 평균**이라
		//   2씨앗 평균과 대면 씨앗 폭(뜻밖임 0.754↔0.814 = 0.06)에 걸려 **원리적으로 못 통과**한다.
		//   ★ 회차 121 진단이 그것을 밟았다(2/4 ⛔) — 그때는 **내 관문이 틀린 것**이었다.
		//   ⚠️⚠️ **문턱을 `±0.02` 로 뒀던 것이 규율 29 위반이었다**(회차 121 실측이 잡았다):
		//     `yaw` 의 차가 0.046 인데 **그 낱말의 `sd_run` 이 0.0525** 라 ***차가 잡음 안***이었다
		//     ⇒ *"재현이 안 됐다"* 가 아니라 **내 문턱이 잡음보다 작았다**.
		//   ★ ⇒ 문턱은 **낱말마다 `3 × sd_run`** 이다.
		uint32 regOk = 0u;
		const bool regApply = (kSeeds == 12u);
		for (uint32 t = 0; t < kTgts; ++t)
		{
			if (!regApply) { ++regOk; continue; }
			// 그 낱말의 실행 잡음(바깥 반복 사이 `㈀` CE 의 폭)
			double rs = 0.0; uint32 rn = 0u;
			for (uint32 s = 0; s < kSeeds; ++s)
			{
				if (!_seedOk[s]) continue;
				rs += Abs((float)((double)_ceOut[1][0][t][s] - (double)_ceOut[0][0][t][s])) / 1.414213562;
				++rn;
			}
			const double sdr = (rn == 0u) ? 0.0 : (rs / (double)rn);
			const double thr = 3.0 * sdr + 0.005;      // ⚠️ 바닥 0.005(잡음 0 인 경우)
			if (Abs((float)m[0][0][t] - kRef100[t]) <= (float)thr) ++regOk;
		}
		LogA("[mlt] 🧪   ⭐ **회귀 관문**(㈀ CE 가 회차 100 값의 **3×sd_run** 안) — **%u/%u** → %s\n",
			regOk, kTgts, !regApply ? "⚠️ 건너뜀(씨앗 12 에서만 유효)"
				: ((regOk == kTgts) ? "✅" : "⛔ **다른 것을 재고 있다**"));
		if (!plumb)
			LogA("[mlt] 🧪   ⭐ 판정 = ⛔ **판정불가** — 배관이 안 섰다(균형/재현)\n");
		else if (regOk != kTgts)
			LogA("[mlt] 🧪   ⭐ 판정 = ⛔ **판정불가** — **회귀가 안 선다**(회차 100 과 다른 것을 재고 있다)\n");
		else if (!pos)
			LogA("[mlt] 🧪   ⭐ 판정 = ⛔ **판정불가** — **양성(yaw)이 안 선다**(규율 16)\n");
		else if (tt0 >= 3.0 && dm0 > 0.0)
			LogA("[mlt] 🧪   ⭐ 판정 = ⭐ ***회차 100 의 결론이 정직한 자로도 선다*** — 학습이 **무작위 사영보다 덜 담는다**\n"
			     "[mlt] 🧪      ⇒ ⚠️ 크기 = `d̄ %+.5f`(SE %.5f) · **좋은 소식이 아니다** — 물음이 *표현이란 무엇인가* 로 내려간다\n",
			     dm0, se0);
		else if (tt0 >= 3.0)
			LogA("[mlt] 🧪   ⭐ 판정 = ⭐ ***뒤집혔다*** — 학습이 무작위보다 **더 담는다**(`d̄ %+.5f`) ⇒ 회차 100 이 틀렸다\n", dm0);
		else
			LogA("[mlt] 🧪   ⭐ 판정 = ⭐ ***회차 100 의 「0/12」는 부호검정이 만든 착시였다*** (|d̄|/SE = %.2f < 3)\n"
			     "[mlt] 🧪      ⇒ ⭐ **정직한 자로는 「학습 ↔ 무작위」가 구별되지 않는다** — 상한 `|d̄| < %.5f`(규율 26·31)\n",
			     tt0, 3.0 * se0);
		LogA("[mlt] 🧪   ⚠️ 문맥 %u · 프로브 %u/%u · 3분류의 진단이다 — 절대 성능으로 인용하지 않는다\n",
			kNCtx, kPbCtx, kPtCtx);
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		_E.Destroy(); _done = true;
	}

	static void _Fail(const char* why)
	{
		LogA("[mlt] 🎚️ ⛔ %s (씨앗 %u · 판 %u · 팔 %u · 단계 %u · 코퍼스 %u · 표현 %u/%u)\n",
			why, _seed, _plate, _arm, _st, _cor, _rw, _ri);
		_E.Destroy(); _done = true;
	}

	CW_BODY(MLTL0N0)
};
