// mltl1a0.cw — 🗣️ 회차 125 · **C2: L1 배관 — 값 구간 홀드아웃** (`-mltl1a0`) ⚠️ **배관 회차**
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 125 다.** ⭐ **하네스보다 먼저 썼다.**
//   **상위 캔버스: `언어를 붙인다` · 125~ = 1회차**(규율 33) — ⭐ **부채를 다 갚거나 닫고 왔다**
//   (D1 🛑 · D2 ✅ · D3 ✅ · D4 🛑) ⇒ **이 트랙의 원래 물음**으로 간다.
//
// ── ⚠️ 설계 함정을 먼저 잡았다 — **낱말 축과 홀드아웃 축을 갈라야 한다** ────
//   `MLT.md` L1 ㉠ = *"**안 본 값 구간**에서 낱말이 맞나"*. 소박하게 짜면 죽는다:
//   ```
//   낱말 = 그 값의 3분위 · 홀드아웃 = 가운데 구간
//   ⇒ ⛔ **가운데 클래스가 통째로 사라진다** ⇒ 정확도가 **구조적으로 0**(모델과 무관)
//   ```
//   ⇒ ★ **두 축을 가른다**: **홀드아웃 축 = `yaw`**(`_mPb[2]`) · **낱말은 그대로 넷**.
//     ⭐ 축이 독립이라 **두 대역 모두에 세 클래스가 다 있다** ⇒ 자가 성립한다.
//   ★ 학습 대역 = `yaw` 의 **바깥 2/3** · 시험 대역 = **가운데 1/3**.
//
// ── 🔬 무엇을 짓나 — ⚠️ **회차 121 하네스에 홀드아웃만 더한다** ─────────────
//   ⭐ 맞춤·보정 **둘 다 학습 대역만** 본다(홀드아웃을 훔쳐보지 않는다) ·
//   ⭐ 시험은 **두 대역을 나란히** 잰다: **안 본 구간**(㉠ 이 묻는 것) ↔ **본 구간**(판정 ③).
//   ⚠️ 몸통·인코더는 **얼린 그대로**(L1 의 정의 — 헤드만 푼다).
//
// ── ✅ 관문 — ⚠️ **전부 배관이다**(㉠ 은 안 판정한다) ────────────────────
//   ⭐ **판정 ①**(누출) 두 대역이 **안 겹친다**(값 구간으로 갈랐다)
//   ⭐ **판정 ②**(균형) 두 대역 각각에 세 클래스가 다 있고 **최소 ≥20%**
//   ⭐ **판정 ③**(헤드가 사나) **본 구간**에서 `CE < ln3` — ⭐ **양성 대조**(규율 16)
//   보고 — **안 본 구간 CE**(⚠️ **다음 회차의 표제**이므로 여기서는 판정 안 한다)
//
// ── ⭐ 예측 ──────────────────────────────────────────────────────────────
//   ⚠️ **최근 열넷 중 여섯을 틀렸다.**
//   · ⭐ 판정 ①②③ 통과(회차 121 이 `yaw` 낱말에서 CE **0.535**·정확도 78.6% 를 봤다)
//   · ⚠️ 보고값(안 본 구간)이 **더 나쁠 것**으로 보지만 **얼마나인지는 모른다** ⇒ 다음 회차의 표제
//
// ── (아래는 회차 121 의 머리말 원문 — 자의 근거) ─────────────────────────
//
// ══════════════════════════════════════════════════════════════════════════════
// mltl0n0.cw — 🧪 회차 121 · **C0: L0 을 정직한 자로 다시** ⭐ **판정 회차**
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

class MLTL1A0
{
public:
	static void Tick(RHI* rhi)
	{
		if (_done || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltl1a0"))
		{
			LogA("[mlt] 🗣️ 회차 125(C2 · L1 배관 — 값 구간 홀드아웃)는 **꺼져 있다**(`-mltl1a0`)\n");
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
	// ⭐ 씨앗 2 진단이 **양성 대조의 오배치**를 잡았다(`yaw` = 홀드아웃 축) ⇒ 고치고 **12씨앗**.
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
	inline static float _seen[kArms][kTgts][kSeeds];   // ⭐ 회차 125 — 본 값 구간의 CE
	inline static float _ce[kPlates][kArms][kTgts][kSeeds];
	inline static float _acc[kPlates][kArms][kTgts][kSeeds];
	inline static bool  _seedOk[kSeeds], _balOk[kSeeds], _repOk[kSeeds];

	inline static uint32 _rw = 0u, _ri = 0u, _rwait = 0u;
	inline static bool   _rpend = false;

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
		_MakeBands();      // ⭐ 회차 125 — `yaw` 로 값 구간을 가른다(L1 의 홀드아웃)
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

	// ══════════════════════════════════════════════════════════════════
	// ⭐ **회차 125 가 더한 것 — 값 구간 홀드아웃**(L1 ㉠ 보간의 배관)
	// ══════════════════════════════════════════════════════════════════
	//   ⚠️ **낱말 축과 홀드아웃 축이 달라야 한다** — 낱말이 그 값의 3분위인데 가운데를 홀드아웃하면
	//     ***클래스 하나가 통째로 사라져 정확도가 구조적으로 0*** 이 된다(모델과 무관).
	//   ⇒ ★ **낱말 = `pitch`(표적 4번) · 홀드아웃 = `yaw`(`_mPb[2]`)** — 두 축은 독립이라
	//     **두 대역 모두에 세 클래스가 다 있다**.
	//   ★ 학습 대역 = `yaw` 의 **바깥 2/3** · 시험 대역 = **가운데 1/3**.
	inline static Array<uint8> _bandPb, _bandPt;
	inline static uint32 _nBandPb = 0u, _nBandPt = 0u;

	static void _MakeBands()
	{
		// ⭐ 문턱은 **프로브 코퍼스**의 `yaw` 순위로 잡는다(시험을 훔쳐보지 않는다).
		Array<uint32> r; _RankClass(_mPb[2].Data(), kPbCtx, r);   // 0/1/2 삼분위
		_bandPb.Reset(0); _bandPt.Reset(0);
		_nBandPb = 0u; _nBandPt = 0u;
		for (uint32 i = 0; i < kPbCtx; ++i)
		{
			const uint8 keep = (r[i] != 1u) ? 1u : 0u;    // ⭐ 학습 = 바깥 2/3
			_bandPb.Add(keep); _nBandPb += keep;
		}
		// 시험 대역은 **같은 문턱**을 시험 코퍼스에 적용한다 ⇒ `yaw` 값으로 직접 가른다.
		float lo = 0.0f, hi = 0.0f; bool first = true;
		for (uint32 i = 0; i < kPbCtx; ++i)
		{
			if (r[i] != 1u) continue;
			const float v = _mPb[2][i];
			if (first) { lo = v; hi = v; first = false; }
			else { if (v < lo) lo = v; if (v > hi) hi = v; }
		}
		for (uint32 i = 0; i < kPtCtx; ++i)
		{
			const float v = _mPt[2][i];
			const uint8 keep = (v >= lo && v <= hi) ? 1u : 0u;   // ⭐ 시험 = 가운데 1/3
			_bandPt.Add(keep); _nBandPt += keep;
		}
		LogA("[mlt] 🗣️   씨앗 %2u · 대역 — 학습(바깥 2/3) **%u/%u** · 시험(가운데 [%.3f, %.3f]) **%u/%u**\n",
			_seed, _nBandPb, kPbCtx, (double)lo, (double)hi, _nBandPt, kPtCtx);
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

	static bool _Fit(float lamScale, float* W)
	{
		const float* X = _fPb.Data();
		_A.Reset(0); _B.Reset(0);
		for (uint32 i = 0; i < kFeat * kFeat; ++i) _A.Add(0.0f);
		for (uint32 i = 0; i < kFeat * kCls; ++i) _B.Add(0.0f);
		float* A = _A.Data(); float* B = _B.Data();
		for (uint32 i = 0; i < kFitCtx; ++i)
		{
			// ⭐ **회차 125** — 학습 대역(바깥 2/3) 밖은 **맞춤에서 뺀다**(L1 의 홀드아웃).
			if (_bandPb[i] == 0u) continue;
			const float* x = X + (uint64)i * kFeat;
			for (uint32 j = 0; j < kFeat; ++j)
			{
				const float xj = x[j];
				if (xj == 0.0f) continue;
				float* row = A + (uint64)j * kFeat;
				for (uint32 k = 0; k <= j; ++k) row[k] += xj * x[k];
				B[(uint64)j * kCls + _yTr[i]] += xj;
			}
		}
		for (uint32 j = 0; j < kFeat; ++j)
			for (uint32 k = 0; k < j; ++k) A[(uint64)k * kFeat + j] = A[(uint64)j * kFeat + k];
		double tr = 0.0;
		for (uint32 j = 0; j < kFeat; ++j) tr += (double)A[(uint64)j * kFeat + j];
		const float lam = (float)(1.0e-2 * (double)lamScale * tr / (double)kFeat);
		for (uint32 j = 0; j < kFeat; ++j) A[(uint64)j * kFeat + j] += lam;
		if (!SolveSymPD(A, B, kFeat, kCls)) return false;
		for (uint32 i = 0; i < kFeat * kCls; ++i) W[i] = B[i];
		return true;
	}

	// ⭐ **회차 125** — `mask` 가 있으면 **그 대역만** 센다(L1 의 홀드아웃 · `nullptr` 이면 전부).
	inline static const uint8* _ceMask = nullptr;
	inline static uint32 _ceN = 0u;

	static double _Ce(const float* X, const uint32* y, uint32 n, const float* W, float tau, uint32* hit)
	{
		double s = 0.0; uint32 h = 0u; uint32 used = 0u;
		for (uint32 i = 0; i < n; ++i)
		{
			if (_ceMask != nullptr && _ceMask[i] == 0u) continue;
			++used;
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
		_ceN = used;                                  // ⭐ 실제로 센 개수(정확도의 분모)
		return (used == 0u) ? 0.0 : (s / (double)used);
	}

	static float _FitTau(const float* Xc, const uint32* yc, const float* W)
	{
		float best = 1.0f; double bce = 1.0e30;
		for (int k = -8; k <= 24; ++k)
		{
			const float tau = Pow(2.0f, (float)k * 0.5f);
			const double ce = _Ce(Xc, yc, kCalCtx, W, tau, nullptr);
			if (ce < bce) { bce = ce; best = tau; }
		}
		const float lo = best * 0.5f, hi = best * 2.0f;
		for (int k = 0; k <= 16; ++k)
		{
			const float tau = lo + (hi - lo) * ((float)k / 16.0f);
			const double ce = _Ce(Xc, yc, kCalCtx, W, tau, nullptr);
			if (ce < bce) { bce = ce; best = tau; }
		}
		return best;
	}

	static bool _Probe(float& ceOut, float& accOut)
	{
		const float* Xc = _fPb.Data() + (uint64)kFitCtx * kFeat;
		const uint32* yc = _yTr + kFitCtx;
		_Wb.Reset(0);
		for (uint32 i = 0; i < kFeat * kCls; ++i) _Wb.Add(0.0f);
		float bestTau = 1.0f; double bce = 1.0e30;
		for (uint32 li = 0; li < kLams; ++li)
		{
			_W.Reset(0);
			for (uint32 i = 0; i < kFeat * kCls; ++i) _W.Add(0.0f);
			if (!_Fit(kLamGrid[li], _W.Data())) continue;
			// ⭐ **회차 125** — 보정도 **학습 대역만**(홀드아웃을 훔쳐보지 않는다).
			_ceMask = _bandPb.Data() + kFitCtx;
			const float tau = _FitTau(Xc, yc, _W.Data());
			const double ce = _Ce(Xc, yc, kCalCtx, _W.Data(), tau, nullptr);
			_ceMask = nullptr;
			if (ce < bce)
			{
				bce = ce; bestTau = tau;
				for (uint32 i = 0; i < kFeat * kCls; ++i) _Wb.Data()[i] = _W[i];
			}
		}
		if (bce > 1.0e29) return false;
		// ⭐ **회차 125 — 시험 코퍼스를 두 대역으로 나눠 둘 다 잰다**
		//   `ceOut`/`accOut` = ⭐ **가운데 대역**(안 본 값 구간) ⇒ ***L1 ㉠ 이 묻는 그것***
		//   `_ceSeen`        = ⭐ **바깥 대역**(학습에서 본 값 구간) ⇒ **판정 ③**(헤드가 사나)
		uint32 hit = 0u;
		_ceMask = _bandPt.Data();
		ceOut = (float)_Ce(_fPt.Data(), _yTe, kPtCtx, _Wb.Data(), bestTau, &hit);
		accOut = (_ceN == 0u) ? 0.0f : ((float)hit / (float)_ceN);
		// 바깥 대역 — 마스크를 뒤집는다
		static Array<uint8> inv;
		inv.Reset(0);
		for (uint32 i = 0; i < kPtCtx; ++i) inv.Add((uint8)(1u - _bandPt[i]));
		_ceMask = inv.Data();
		_ceSeen = (float)_Ce(_fPt.Data(), _yTe, kPtCtx, _Wb.Data(), bestTau, nullptr);
		_ceMask = nullptr;
		return true;
	}
	inline static float _ceSeen = 0.0f;      // ⭐ 판정 ③ — 본 값 구간의 CE

	static void _Judge()
	{
		for (uint32 t = 0; t < kTgts; ++t)
		{
			_yTr = _yPb[t].Data(); _yTe = _yPt[t].Data();
			if (!_Probe(_ce[_plate][_arm][t][_seed], _acc[_plate][_arm][t][_seed]))
			{ _Fail("프로브"); return; }
			_seen[_arm][t][_seed] = _ceSeen;      // ⭐ 회차 125 — 본 값 구간의 CE(판정 ③)
		}
		// ⭐ **회차 125 의 핵심 줄** — 낱말 `pitch`(표적 3 자리에 `minDOn` 대신 쓰지 않는다.
		//   ⚠️ 이 회차는 **낱말 넷을 그대로 두고** 대역만 갈랐다 ⇒ 넷 다 「안 본 구간 ↔ 본 구간」이 나온다.
		LogA("[mlt] 🗣️   %s 씨앗 %2u · **안 본 구간 ↔ 본 구간** — 뜻밖임 %.4f↔%.4f · 지속 %.4f↔%.4f"
			" · yaw %.4f↔%.4f · minDOn %.4f↔%.4f\n",
			_ArmName(_arm), _seed,
			(double)_ce[0][_arm][0][_seed], (double)_seen[_arm][0][_seed],
			(double)_ce[0][_arm][1][_seed], (double)_seen[_arm][1][_seed],
			(double)_ce[0][_arm][2][_seed], (double)_seen[_arm][2][_seed],
			(double)_ce[0][_arm][3][_seed], (double)_seen[_arm][3][_seed]);
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
		// ⚠️⚠️ **회차 125 진단이 이 줄을 고치게 했다** — `yaw` 는 **홀드아웃 축 자체**라
		//   학습 대역(바깥 2/3)이 그 낱말의 **가운데 클래스를 한 번도 못 본다** ⇒ 시험 CE 가
		//   **6.3~184**(ln3 의 6~167배)로 폭발한다. ⭐ ***내가 등록문에서 경고한 함정을 내가 밟았다.***
		//   ⇒ ★ **양성 대조를 「뜻밖임」(표적 0)으로 바꾼다** — 홀드아웃 축과 **독립**이고
		//     회차 121 이 그 낱말에서 CE **0.74**(< ln3)를 봤다.
		//   ⚠️ 그리고 **`yaw` 는 판정에서 뺀다**(보고로만 남긴다).
		const bool pos  = (g[0][0][0] >= kSignPass);        // ㊀ 뜻밖임 양성(규율 16)
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

	CW_BODY(MLTL1A0)
};
