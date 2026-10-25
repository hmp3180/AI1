// mltl1a2.cw — 🌉 회차 127 · **L1 ㉣ 채널 간 전이** (`-mltl1a2`) ⭐ **핵심 주장 회차**
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 127 이다.** ⭐ **하네스보다 먼저 썼다.**
//   **상위 캔버스: `언어를 붙인다` · 125~127 = 3회차** ⇒ ⚠️ **이 회차 끝에 규율 33 심사가 강제된다.**
//
// ── ⭐ 표제 — ***상태로 배운 낱말 방향이 비전 활성에서도 도나*** ────────
//   `mltconcept.md` 가 「성공」에 적은 것이고 ***이 트랙의 핵심 주장***이다:
//   **하나의 개념이 여러 채널을 건넌다.**
//
// ── 🔧 배관 — ⭐ **회차 126 이 이미 지어 뒀다**(새 세계·새 코퍼스 0) ────────
//   특징 257 = `[상태 128][비전 128][편향 1]` 이고 **둘이 같은 잔차 공간**이다(위치만 다르다):
//     대역 0 = 상태 축 5개    → **상태 채널**
//     대역 1 = 활성 슬롯 8개  → **비전 채널**(렌더 프레임의 패치 사전 id)
//   ⇒ ⭐ **상태에서 맞춘 가중치 반쪽을 비전 자리에 그대로 꽂을 수 있다.**
//   ★ 구현은 **가중치가 아니라 특징을 옮긴다**(같은 것이고 훨씬 싸다):
//     맞춤 = 그 대역 밖 128 을 **0 으로 지운** 특징 · 채점 = 읽을 대역 128 을 **맞춤 대역 자리로 복사**.
//
//   ⚠️⚠️ **값 구간 홀드아웃은 껐다** — 이번은 **보간이 아니라 전이**다.
//     둘을 같이 재면 ⛔ 가 나와도 **어느 쪽 탓인지 못 가른다**(규율 34 의 정신).
//     ⇒ 표적 넷이 다 산다(`yaw` 포함) · 회귀는 ㈆ 로 **회차 100 에 직접** 건다.
//
// ── 🎛️ 프로브 팔 일곱 — ⚠️ **몸통은 안 다시 돈다**(프로브만 7번 ⇒ 싸다) ────
//   ㈀ 상태→상태   양성 대조(같은 채널)
//   ㈁ 비전→비전   양성 대조(같은 채널) · ⭐ **㈂ 의 천장**
//   ⭐ ㈂ 상태→비전   ⭐ **표제 — 전이 →**
//   ⭐ ㈃ 비전→상태   ⭐ **표제 — 전이 ←**
//   ⭐ ㈄ 상태→비전(**차원 셔플**)  **음성 대조** — 같은 값·노름·편향, ***정렬만 깨짐***
//   ㈅ 편향만(128 성분 0)  **바닥**(균등바닥의 실측판)
//   ㈆ 둘 다        ⭐ **회귀용** — 회차 126·100 과 **같은 것**
//   ⚠️ 그리고 **몸통 팔 둘**은 그대로다(㋐ 학습 800 · ㋑ 학습 0) — *"전이가 **학습**이 만든 것인가"*.
//
// ── 📏 자 — ⭐ **무차원**(규율 31) ────────────────────────────────────────
//   `전이율 = (ln3 − CE_전이) / (ln3 − CE_같은채널)`   0 = 전혀 안 감 · 1 = 온전히 감
//     전이 → : ㈂ / ㈁      전이 ← : ㈃ / ㈀
//   ★ 실행 잡음이 분자·분모에 같이 들어가 **나눠진다**.
//
// ── ✅ 관문(등록문과 같다) ────────────────────────────────────────────────
//   배관 균형·재현·유한 12/12 · ⭐ **회귀** ㈆ 가 회차 100 refs 를 `3×sd_run+0.005` 안에 4/4
//   ⭐ **㉣-a** `CE(㈂·뜻밖임) < ln3` **10/12** · ⭐ **㉣-b** `전이율(㈂) > 전이율(㈄)` `|d̄|/SE ≥ 3`
//   ⭐ **음성** ㈄ 는 **실패해야 한다**(`CE < ln3` 가 10/12 **미만**)
//     ⚠️ ㈄ 까지 통과하면 그것은 전이가 아니라 **자가 죽은 것**이다.
//
// ── ⭐ 예측(재기 전에 적었다) ─────────────────────────────────────────────
//   ⚠️ **최근 열여섯 중 일곱을 틀렸다.**
//   · ㉣-a **통과할 것**(두 대역이 같은 잔차 공간 + 어텐션이 축을 섞는다)
//   · **전이율 0.2~0.5** — ⚠️ **온전하지는 않을 것**(위치마다 다른 부분공간을 쓰기 쉽다)
//   · `뜻밖임` **>** `지속개수`(㊀ 은 **손실의 주항**이라 모델 전체에 퍼져 있다)
//   · 학습 0(㋑)에서도 전이율이 **0 은 아닐 것** — 다만 학습팔보다 **작을 것**
//
// ── ⚠️⚠️ **이 회차로는 못 가르는 것** — 미리 적는다 ───────────────────────
//   전이가 되더라도 *"낱말이 채널을 건넜다"* 가 아니라
//   ***"어텐션이 상태를 비전 위치로 복사했다"*** 일 수 있다 — 그건 전이가 아니라 **누출**이다.
//   ★ 가르는 법 = **어텐션 마스크로 상태→비전 흐름을 끊고 다시 재기** ⇒ 🧾 **부채 D9**.
//
// ── (아래는 회차 125 의 머리말 원문 — 홀드아웃 설계의 근거) ────────────────
//
// ══════════════════════════════════════════════════════════════════════════════
// mltl1a0.cw — 🗣️ 회차 125 · **C2: L1 배관 — 값 구간 홀드아웃** ⚠️ **배관 회차**
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

class MLTL1A2
{
public:
	static void Tick(RHI* rhi)
	{
		if (_done || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltl1a2"))
		{
			LogA("[mlt] 🗣️ 회차 125(C2 · L1 배관 — 값 구간 홀드아웃)는 **꺼져 있다**(`-mltl1a2`)\n");
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
	static constexpr uint32 kSeeds = 12u;   // ⭐ 판정(1씨앗 진단은 끝났다)
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

	// ══════════════════════════════════════════════════════════════════
	// ⭐ **회차 127 이 더한 것 — 프로브 팔 일곱**(채널 간 전이)
	// ══════════════════════════════════════════════════════════════════
	//   특징 257 = `[상태 128][비전 128][편향 1]` ⇒ 대역 둘이 **같은 잔차 공간**이다.
	//   ★ 가중치가 아니라 **특징을 옮긴다**: 맞춤은 `fit` 대역만 남기고, 채점은 `read` 대역을
	//     `fit` 대역 자리로 **복사**한다 ⇒ `W·x' = W_fit · x_read` = ***전이 그 자체***.
	//   ⚠️ `read = kNone` 이면 128 을 전부 0 으로(편향만) · `shuf = 1` 이면 고정 순열로 섞는다.
	static constexpr uint32 kProbes = 7u;
	static constexpr uint8  kBoth = 2u, kNone = 255u;
	struct ProbeCfg { uint8 fit; uint8 read; uint8 shuf; };
	static constexpr ProbeCfg kProbe[kProbes] = {
		{ 0u, 0u,     0u },   // ㈀ 상태→상태   (양성 · 같은 채널)
		{ 1u, 1u,     0u },   // ㈁ 비전→비전   (양성 · 같은 채널 · ㈂ 의 천장)
		{ 0u, 1u,     0u },   // ⭐ ㈂ 상태→비전 (표제 · 전이 →)
		{ 1u, 0u,     0u },   // ⭐ ㈃ 비전→상태 (표제 · 전이 ←)
		{ 0u, 1u,     1u },   // ⭐ ㈄ 상태→비전(셔플) — 음성 대조
		{ 0u, kNone,  0u },   // ㈅ 편향만 — 바닥
		{ kBoth, kBoth, 0u }, // ㈆ 둘 다 — ⭐ 회귀용(회차 126·100 과 같은 것)
	};
	static const char* _PrName(uint32 p)
	{
		switch (p)
		{
		case 0u: return "㈀ 상태→상태  ";
		case 1u: return "㈁ 비전→비전  ";
		case 2u: return "㈂ 상태→비전⭐";
		case 3u: return "㈃ 비전→상태⭐";
		case 4u: return "㈄ →비전셔플⛔";
		case 5u: return "㈅ 편향만(바닥)";
		default: return "㈆ 둘 다(회귀)";
		}
	}
	// ⭐ 표제 팔 · 천장 팔 · 음성 팔 — 이름으로 박아 둔다(인덱스가 흩어지지 않게)
	static constexpr uint32 kPrSS = 0u, kPrVV = 1u, kPrSV = 2u, kPrVS = 3u;
	static constexpr uint32 kPrShuf = 4u, kPrBias = 5u, kPrBoth = 6u;

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
	// ⭐ **회차 127** — 프로브 축을 더했다(7 × 2팔 × 4낱말 × 12씨앗 · 바깥 2)
	inline static float _ceOut[kOut][kProbes][kArms][kTgts][kSeeds];
	inline static float _ce[kProbes][kArms][kTgts][kSeeds];
	inline static float _acc[kProbes][kArms][kTgts][kSeeds];
	inline static bool  _seedOk[kSeeds], _balOk[kSeeds], _repOk[kSeeds];
	inline static uint32 _pr = 0u;                       // 지금 프로브 팔
	inline static Array<float> _gPb, _gPt;               // 프로브별로 옮겨 담은 특징
	inline static Array<uint32> _perm;                   // ㈄ 의 고정 순열(씨앗마다)

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
		LogA("[mlt] 🌉 **회차 127 · L1 ㉣ 채널 간 전이**(⭐ 이 트랙의 **핵심 주장** 회차)\n");
		LogA("[mlt] 🌉   ⭐ 표제 — ***상태로 배운 낱말 방향이 비전 활성에서도 도나***\n");
		LogA("[mlt] 🌉     `mltconcept.md` 가 「성공」에 적은 것 = **하나의 개념이 여러 채널을 건넌다**\n");
		LogA("[mlt] 🌉   특징 **%u** = [상태 %u][비전 %u][편향 1] — ⭐ **둘이 같은 잔차 공간**(위치만 다르다)\n",
			kFeat, kD, kD);
		LogA("[mlt] 🌉     ⇒ 맞춤은 그 대역만 남기고, 채점은 **읽을 대역을 맞춤 자리로 옮긴다** ⇒ `W·x' = W_fit · x_read`\n");
		LogA("[mlt] 🌉   프로브 팔 **일곱** — ㈀상태→상태 · ㈁비전→비전 · ⭐㈂상태→비전 · ⭐㈃비전→상태\n");
		LogA("[mlt] 🌉     · ⭐㈄상태→비전(**차원 셔플** = 음성 대조) · ㈅편향만(바닥) · ㈆둘 다(**회귀용**)\n");
		LogA("[mlt] 🌉   ⚠️⚠️ **값 구간 홀드아웃은 껐다** — 이번은 보간이 아니라 전이다(둘을 같이 재면 못 가른다)\n");
		LogA("[mlt] 🌉   ⭐ 자 = **무차원**(규율 31) `전이율 = (ln3 − CE) / (ln3 − CE_같은채널)`\n");
		LogA("[mlt] 🌉   ✅ 관문 — ㉣-a `CE(㈂) < ln3` **%u/%u** · ㉣-b `|d̄|/SE ≥ 3`(㈂ vs ㈄) · ⭐ **음성 ㈄ 는 실패해야 한다**\n",
			kSignPass, kSeeds);
		LogA("[mlt] 🌉   ⭐ **예측**(재기 전에 적었다) — ㉣-a 통과 · **전이율 0.2~0.5**(온전하지 않을 것) · 뜻밖임 > 지속개수\n");
		LogA("[mlt] 🌉   ⚠️⚠️ **이 회차로 못 가르는 것** — 전이인가 **누출**(어텐션이 상태를 비전 위치로 복사)인가 ⇒ **부채 D9**\n");
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

	// ⚠️⚠️ **회차 127 — 값 구간 홀드아웃을 껐다.**
	//   이번 회차는 **보간이 아니라 전이**다. 둘을 같이 재면 ⛔ 가 나와도 어느 쪽 탓인지 못 가른다
	//   (규율 34 의 정신 — *"한 회차에 두 개를 재면 자가 아니다"*).
	//   ⇒ ★ 전 구간 학습 · 전 구간 시험 ⇒ **표적 넷이 다 산다**(`yaw` 포함) ·
	//     회귀는 ㈆(둘 다) 팔로 **회차 100 refs 에 직접** 건다.
	//   ★ 배열은 남겨 둔다(전부 1) — `_Fit`/`_Ce` 의 마스크 배관을 안 뜯으려고.
	static void _MakeBands()
	{
		_bandPb.Reset(0); _bandPt.Reset(0);
		_nBandPb = kPbCtx; _nBandPt = kPtCtx;
		for (uint32 i = 0; i < kPbCtx; ++i) _bandPb.Add(1u);
		for (uint32 i = 0; i < kPtCtx; ++i) _bandPt.Add(1u);
		// ⭐ ㈄ 의 고정 순열 — **씨앗마다** 하나(같은 씨앗 안에서는 안 바뀐다 ⇒ 짝지음이 성립).
		//   ⚠️ 값·노름·편향을 다 보존하고 **정렬만** 깬다 ⇒ 그것이 음성 대조의 정의다.
		_perm.Reset(0);
		for (uint32 d = 0; d < kD; ++d) _perm.Add(d);
		uint32 rs = _seed * 2654435761u + 12345u;
		for (uint32 d = kD; d > 1u; --d)
		{
			rs = rs * 1664525u + 1013904223u;
			const uint32 j = rs % d;
			const uint32 tmp = _perm[d - 1u]; _perm.Data()[d - 1u] = _perm[j]; _perm.Data()[j] = tmp;
		}
		LogA("[mlt] 🌉   씨앗 %2u · 홀드아웃 **꺼짐**(전 구간 %u/%u) · ㈄ 순열 준비(첫 셋 %u %u %u)\n",
			_seed, _nBandPb, kPbCtx, _perm[0], _perm[1], _perm[2]);
	}

	// ══════════════════════════════════════════════════════════════════
	// ⭐ **회차 127 의 핵심 — 프로브 팔마다 특징을 옮겨 담는다**
	// ══════════════════════════════════════════════════════════════════
	//   ★ 한 줄로: **맞춤은 `fit` 대역만 남기고, 채점은 `read` 대역을 `fit` 자리로 옮긴다.**
	//     그러면 `W` 는 `fit` 자리에만 살아 있으므로 `W·x' = W_fit · x_read` 다 = ***전이***.
	//   ⚠️ **맞춤 줄(`i < kFitCtx`)과 보정 줄(`i ≥ kFitCtx`)의 변환이 다르다** —
	//     보정(τ)은 **채점 채널에서** 잡아야 한다(안 그러면 눈금이 딴 채널 것이다).
	//     ★ τ 는 **스칼라 하나**라 128차원 방향을 대신 배울 수 없다 ⇒ 전이의 뜻을 안 해친다.
	//   ⚠️ 편향(마지막 칸)은 **어느 팔에서도 그대로 1** 이다.
	static void _WriteRow(float* dst, const float* src, uint8 fit, uint8 read, uint8 shuf)
	{
		for (uint32 d = 0; d < kFeat; ++d) dst[d] = 0.0f;
		dst[kFeat - 1u] = 1.0f;
		if (read == kNone) return;                       // ㈅ 편향만
		if (fit == kBoth) { for (uint32 d = 0; d < kFeat - 1u; ++d) dst[d] = src[d]; return; }
		const float* rd = src + (uint64)read * kD;       // 읽을 대역
		float* wr = dst + (uint64)fit * kD;              // 꽂을 자리 = 맞춤 대역
		if (shuf == 0u) { for (uint32 d = 0; d < kD; ++d) wr[d] = rd[d]; }
		else            { for (uint32 d = 0; d < kD; ++d) wr[d] = rd[_perm[d]]; }
	}

	// ══════════════════════════════════════════════════════════════════
	// ⭐ **1씨앗 진단이 요구한 자** — 「전이」와 「애초에 같음」을 가른다
	// ══════════════════════════════════════════════════════════════════
	//   ⚠️ 진단에서 **㈂(상태→비전) 0.8747 이 ㈀(상태→상태) 0.8737 과 거의 같았다.**
	//     그러면 *"방향이 채널을 건넜다"* 가 아니라 ***"두 대역이 애초에 같은 벡터다"*** 일 수 있다
	//     (= 어텐션이 상태를 비전 위치로 복사한 **누출** · 등록문의 D9).
	//   ★ 그래서 문맥마다 **두 대역의 코사인 유사도**를 잰다:
	//     ⇒ **1 에 가까우면** 전이가 자명하다(잰 것이 없다) · **0 에 가까우면** 전이가 진짜 발견이다.
	//   ⭐ 그리고 **셔플한 유사도**를 같이 잰다 — 그것이 이 자의 **음성 대조**다(정렬을 깬 값).
	inline static float _cosMean[kArms][kSeeds], _cosShuf[kArms][kSeeds];
	static void _MeasureBandCos()
	{
		double s = 0.0, z = 0.0; uint32 n = 0u;
		for (uint32 i = 0; i < kPtCtx; ++i)
		{
			const float* x = _fPt.Data() + (uint64)i * kFeat;
			const float* a = x;               // 상태 대역
			const float* b = x + kD;          // 비전 대역
			double na = 0.0, nb = 0.0, ab = 0.0, az = 0.0;
			for (uint32 d = 0; d < kD; ++d)
			{
				na += (double)a[d] * (double)a[d];
				nb += (double)b[d] * (double)b[d];
				ab += (double)a[d] * (double)b[d];
				az += (double)a[d] * (double)b[_perm[d]];   // 셔플 대조
			}
			if (na < 1.0e-12 || nb < 1.0e-12) continue;
			const double den = Sqrt((float)(na * nb));
			s += ab / den; z += az / den; ++n;
		}
		_cosMean[_arm][_seed] = (n == 0u) ? 0.0f : (float)(s / (double)n);
		_cosShuf[_arm][_seed] = (n == 0u) ? 0.0f : (float)(z / (double)n);
		LogA("[mlt] 🌉   씨앗 %2u · **대역 코사인** 상태↔비전 **%+.4f** (셔플 대조 %+.4f · 문맥 %u)\n",
			_seed, (double)_cosMean[_arm][_seed], (double)_cosShuf[_arm][_seed], n);
	}

	static void _MakeProbeFeat(uint32 pr)
	{
		const ProbeCfg& c = kProbe[pr];
		_gPb.Reset(0); _gPt.Reset(0);
		for (uint32 i = 0; i < kPbCtx * kFeat; ++i) _gPb.Add(0.0f);
		for (uint32 i = 0; i < kPtCtx * kFeat; ++i) _gPt.Add(0.0f);
		for (uint32 i = 0; i < kPbCtx; ++i)
		{
			const float* s = _fPb.Data() + (uint64)i * kFeat;
			float* d = _gPb.Data() + (uint64)i * kFeat;
			// ⭐ 맞춤 줄 = `fit` 대역만 남긴다(같은 대역을 제자리에 · 셔플 없음)
			if (i < kFitCtx) _WriteRow(d, s, c.fit, (c.fit == kBoth) ? kBoth : c.fit, 0u);
			else             _WriteRow(d, s, c.fit, c.read, c.shuf);   // 보정 = 채점 변환
		}
		for (uint32 i = 0; i < kPtCtx; ++i)
			_WriteRow(_gPt.Data() + (uint64)i * kFeat, _fPt.Data() + (uint64)i * kFeat,
				c.fit, c.read, c.shuf);
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
		const float* X = _gPb.Data();      // ⭐ 회차 127 — 프로브 팔이 옮겨 담은 특징
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
		// ⭐ **회차 127** — 보정 줄은 이미 **채점 변환**으로 담겨 있다(`_MakeProbeFeat`)
		//   ⇒ τ 가 **채점 채널의 눈금**으로 잡힌다(전이팔에서 노름이 갈리는 것을 덮는다).
		const float* Xc = _gPb.Data() + (uint64)kFitCtx * kFeat;
		const uint32* yc = _yTr + kFitCtx;
		_Wb.Reset(0);
		for (uint32 i = 0; i < kFeat * kCls; ++i) _Wb.Add(0.0f);
		float bestTau = 1.0f; double bce = 1.0e30;
		for (uint32 li = 0; li < kLams; ++li)
		{
			_W.Reset(0);
			for (uint32 i = 0; i < kFeat * kCls; ++i) _W.Add(0.0f);
			if (!_Fit(kLamGrid[li], _W.Data())) continue;
			const float tau = _FitTau(Xc, yc, _W.Data());
			const double ce = _Ce(Xc, yc, kCalCtx, _W.Data(), tau, nullptr);
			if (ce < bce)
			{
				bce = ce; bestTau = tau;
				for (uint32 i = 0; i < kFeat * kCls; ++i) _Wb.Data()[i] = _W[i];
			}
		}
		if (bce > 1.0e29) return false;
		uint32 hit = 0u;
		ceOut = (float)_Ce(_gPt.Data(), _yTe, kPtCtx, _Wb.Data(), bestTau, &hit);
		accOut = (_ceN == 0u) ? 0.0f : ((float)hit / (float)_ceN);
		return true;
	}

	static void _Judge()
	{
		// ⭐ 대역 코사인은 **씨앗마다 한 번**(표현은 팔·바깥 반복에 안 매인다 — 얼린 것이다)
		if (_out == 0u) _MeasureBandCos();
		// ⭐ **회차 127** — 같은 표현 위에서 **프로브 팔 일곱**을 돈다.
		//   ⚠️ 몸통은 다시 안 돈다(표현이 이미 손에 있다) ⇒ CPU 만 7배, GPU 0배.
		for (uint32 pr = 0; pr < kProbes; ++pr)
		{
			_pr = pr;
			_MakeProbeFeat(pr);
			for (uint32 t = 0; t < kTgts; ++t)
			{
				_yTr = _yPb[t].Data(); _yTe = _yPt[t].Data();
				if (!_Probe(_ce[pr][_arm][t][_seed], _acc[pr][_arm][t][_seed]))
				{ _Fail("프로브"); return; }
			}
		}
		{
			// ⭐ 씨앗 한 줄 — **표제 팔 넷**만 나란히(뜻밖임 기준)
			LogA("[mlt] 🌉   %s 씨앗 %2u · ㊀뜻밖임 — ㈀상태%.4f ㈁비전%.4f │ ⭐㈂→%.4f ⭐㈃←%.4f │ ㈄셔플%.4f ㈅바닥%.4f ㈆둘%.4f\n",
				_ArmName(_arm), _seed,
				(double)_ce[kPrSS][_arm][0][_seed], (double)_ce[kPrVV][_arm][0][_seed],
				(double)_ce[kPrSV][_arm][0][_seed], (double)_ce[kPrVS][_arm][0][_seed],
				(double)_ce[kPrShuf][_arm][0][_seed], (double)_ce[kPrBias][_arm][0][_seed],
				(double)_ce[kPrBoth][_arm][0][_seed]);
		}
		_plate = 0u;
		// ⭐ ㈆(둘 다) 한 줄 — **회차 126·100 과 같은 자리**라 눈으로 회귀를 본다
		LogA("[mlt] 🧪   %s · %s 씨앗 %2u · **㈆ 둘 다** ㊀뜻밖임 %.5f(%.1f%%) · ㊁지속 %.5f(%.1f%%) │ ㊂yaw %.5f · ㊃minDOn %.5f\n",
			_PlateName(_plate), _ArmName(_arm), _seed,
			(double)_ce[kPrBoth][_arm][0][_seed], 100.0 * (double)_acc[kPrBoth][_arm][0][_seed],
			(double)_ce[kPrBoth][_arm][1][_seed], 100.0 * (double)_acc[kPrBoth][_arm][1][_seed],
			(double)_ce[kPrBoth][_arm][2][_seed], (double)_ce[kPrBoth][_arm][3][_seed]);
		if (++_arm < kArms) { _ToBody(); return; }
		_arm = 0u;
		// ⭐ **회차 121 이 더한 것 — 바깥 반복**(같은 씨앗을 다시 돈다).
		//   ★ 그래야 **실행 잡음과 씨앗 잡음을 갈라 잰다**(규율 32 의 형식).
		//   ⚠️ 코퍼스·표현은 **다시 안 모은다**(결정적임이 증명됐다) — 몸통만 다시 돈다.
		for (uint32 pr = 0; pr < kProbes; ++pr)
			for (uint32 t = 0; t < kTgts; ++t)
				for (uint32 a = 0; a < kArms; ++a)
					_ceOut[_out][pr][a][t][_seed] = _ce[pr][a][t][_seed];
		if (++_out < kOut) { _ToBody(); return; }
		_out = 0u;
		_seedOk[_seed] = _finite;
		++_seed; _st = kEncInit;
	}

	// ⭐ 씨앗별 평균(바깥 반복 평균) — 프로브 × 팔 × 낱말
	static double _Mean(uint32 pr, uint32 a, uint32 t, uint32 s)
	{
		double v = 0.0;
		for (uint32 o = 0; o < kOut; ++o) v += (double)_ceOut[o][pr][a][t][s];
		return v / (double)kOut;
	}

	// ⭐ **무차원 자**(규율 31) — `전이율 = (ln3 − CE_전이) / (ln3 − CE_같은채널)`
	//   ⚠️ 분모가 0 에 붙으면(같은 채널조차 균등바닥을 못 넘으면) **정의가 없다** ⇒ 세지 않고 알린다.
	static bool _Rate(uint32 prX, uint32 prC, uint32 a, uint32 t, uint32 s, double& out)
	{
		const double den = (double)kUnif - _Mean(prC, a, t, s);
		if (den < 0.02) return false;                 // ⚠️ 천장이 안 서면 비를 못 만든다
		out = ((double)kUnif - _Mean(prX, a, t, s)) / den;
		return true;
	}

	static void _Summary()
	{
		uint32 ok = 0u, bal = 0u, rep = 0u;
		for (uint32 s = 0; s < kSeeds; ++s)
		{
			if (!_seedOk[s]) continue;
			++ok; if (_balOk[s]) ++bal; if (_repOk[s]) ++rep;
		}
		const bool plumb = (bal == ok) && (rep == ok) && _finite && (ok > 0u);

		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🌉 **회차 127 · L1 ㉣ 채널 간 전이** — 읽은 씨앗 %u/%u\n", ok, kSeeds);
		LogA("[mlt] 🌉   배관 — ㈃ 균형 **%u/%u** · ㈄ 얼림/재현 **%u/%u** · 화면안 도형0 **%u회** → %s\n",
			bal, ok, rep, ok, _noShape, plumb ? "통과" : "⛔");
		LogA("[mlt] 🌉   균등바닥 **%.4f**(ln3) · 특징 **%u** = [상태 %u][비전 %u][편향 1] · 홀드아웃 **꺼짐**\n",
			(double)kUnif, kFeat, kD, kD);

		// ── ① 프로브 팔 일곱을 나란히(학습팔 ㋐ · 낱말 넷) ───────────────
		LogA("[mlt] 🌉   ── ① **프로브 팔 일곱 × 낱말 넷**(㋐ 학습 · CE · 괄호는 `<ln3` 씨앗 수) ──\n");
		for (uint32 pr = 0; pr < kProbes; ++pr)
		{
			double mm[kTgts]; uint32 gg[kTgts];
			for (uint32 t = 0; t < kTgts; ++t) { mm[t] = 0.0; gg[t] = 0u; }
			uint32 n = 0u;
			for (uint32 s = 0; s < kSeeds; ++s)
			{
				if (!_seedOk[s]) continue;
				++n;
				for (uint32 t = 0; t < kTgts; ++t)
				{
					const double v = _Mean(pr, 0u, t, s);
					mm[t] += v; if (v < (double)kUnif) ++gg[t];
				}
			}
			if (n == 0u) continue;
			for (uint32 t = 0; t < kTgts; ++t) mm[t] /= (double)n;
			LogA("[mlt] 🌉     %s │ ㊀뜻밖임 **%.4f**(%u/%u) · ㊁지속 %.4f(%u/%u) · ㊂yaw %.4f(%u/%u) · ㊃minDOn %.4f(%u/%u)\n",
				_PrName(pr), mm[0], gg[0], n, mm[1], gg[1], n, mm[2], gg[2], n, mm[3], gg[3], n);
		}

		// ── ② ⭐ 전이율(무차원) — 표제 ─────────────────────────────────
		//   전이 → = ㈂/㈁  ·  전이 ← = ㈃/㈀  ·  음성 = ㈄/㈁
		LogA("[mlt] 🌉   ── ② ⭐ **전이율**(무차원 · 규율 31) `= (ln3 − CE) / (ln3 − CE_같은채널)` ──\n");
		LogA("[mlt] 🌉     팔 · 낱말        │ 전이 →(㈂/㈁) │ 전이 ←(㈃/㈀) │ ⛔음성(㈄/㈁) │ 정의된 씨앗\n");
		for (uint32 a = 0; a < kArms; ++a)
			for (uint32 t = 0; t < kTgts; ++t)
			{
				double f = 0.0, b = 0.0, z = 0.0; uint32 nf = 0u, nb = 0u, nz = 0u;
				for (uint32 s = 0; s < kSeeds; ++s)
				{
					if (!_seedOk[s]) continue;
					double r;
					if (_Rate(kPrSV, kPrVV, a, t, s, r)) { f += r; ++nf; }
					if (_Rate(kPrVS, kPrSS, a, t, s, r)) { b += r; ++nb; }
					if (_Rate(kPrShuf, kPrVV, a, t, s, r)) { z += r; ++nz; }
				}
				LogA("[mlt] 🌉     %s %s │ **%+.3f** │ %+.3f │ %+.3f │ %u/%u/%u%s\n",
					_ArmName(a), _TgtName(t),
					(nf == 0u) ? 0.0 : f / (double)nf,
					(nb == 0u) ? 0.0 : b / (double)nb,
					(nz == 0u) ? 0.0 : z / (double)nz,
					nf, nb, nz,
					(a == 0u && t == 0u) ? "   ⭐ **표제**" : "");
			}

		// ── ③ ⭐ 회귀 관문 — ㈆(둘 다)가 회차 100 을 재현하나 ─────────────
		static constexpr float kRef100[kTgts] = { 0.7481f, 1.0903f, 0.5812f, 1.0793f };
		uint32 regOk = 0u;
		const bool regApply = (kSeeds == 12u);
		LogA("[mlt] 🌉   ── ③ ⭐ **회귀**(㈆ 둘 다 ↔ 회차 100 · 문턱 `3×sd_run + 0.005`) ──\n");
		for (uint32 t = 0; t < kTgts; ++t)
		{
			double rs = 0.0, ms = 0.0; uint32 rn = 0u;
			for (uint32 s = 0; s < kSeeds; ++s)
			{
				if (!_seedOk[s]) continue;
				rs += Abs((float)((double)_ceOut[1][kPrBoth][0][t][s] - (double)_ceOut[0][kPrBoth][0][t][s])) / 1.414213562;
				ms += _Mean(kPrBoth, 0u, t, s);
				++rn;
			}
			if (rn == 0u) continue;
			const double sdr = rs / (double)rn, mv = ms / (double)rn;
			const double thr = 3.0 * sdr + 0.005;
			const bool hit = (Abs((float)mv - kRef100[t]) <= (float)thr);
			if (!regApply || hit) ++regOk;
			LogA("[mlt] 🌉     %s │ 지금 **%.4f** ↔ 100 회차 %.4f │ 차 %.4f · 문턱 %.4f(sd_run %.5f) → %s\n",
				_TgtName(t), mv, (double)kRef100[t], Abs((float)mv - kRef100[t]), thr, sdr,
				hit ? "✅" : "⛔");
		}

		// ── ④ ⭐ 표제 관문 셋 ─────────────────────────────────────────
		//   ㉣-a  `CE(㈂·뜻밖임) < ln3` ≥ kSignPass
		//   ㉣-b  짝지은 `d = 전이율(㈂) − 전이율(㈄)` 의 `|d̄|/SE ≥ 3`
		//   음성  ㈄ 는 `CE < ln3` 가 kSignPass **미만**이어야 한다
		uint32 gSV = 0u, gShuf = 0u;
		double dm = 0.0; uint32 nd = 0u; double dv[kSeeds];
		for (uint32 s = 0; s < kSeeds; ++s)
		{
			if (!_seedOk[s]) continue;
			if (_Mean(kPrSV, 0u, 0u, s) < (double)kUnif) ++gSV;
			if (_Mean(kPrShuf, 0u, 0u, s) < (double)kUnif) ++gShuf;
			double r1, r2;
			if (_Rate(kPrSV, kPrVV, 0u, 0u, s, r1) && _Rate(kPrShuf, kPrVV, 0u, 0u, s, r2))
			{ dv[nd] = r1 - r2; dm += dv[nd]; ++nd; }
		}
		double se = 0.0, tt = 0.0;
		if (nd > 1u)
		{
			dm /= (double)nd;
			double vv = 0.0;
			for (uint32 i = 0; i < nd; ++i) { const double e = dv[i] - dm; vv += e * e; }
			se = Sqrt((float)(vv / (double)(nd - 1u))) / Sqrt((float)nd);
			tt = (se > 1.0e-12) ? (Abs(dm) / se) : 0.0;
		}
		const bool gA = (gSV >= kSignPass);
		// ⚠️⚠️ **씨앗이 적으면 `SE` 를 못 잰다** — 씨앗 1~2 에서 `|d̄|/SE` 는 **원리적으로 0** 이다.
		//   ★ 회차 121 이 밟은 그 함정(*"문턱이 씨앗 수에 매여 있다"*)의 **네 번째 얼굴**이라 미리 막는다.
		const bool bApply = (kSeeds >= 3u);
		const bool gB = !bApply || (tt >= 3.0 && dm > 0.0);
		const bool gNeg = (gShuf < kSignPass);
		LogA("[mlt] 🌉   ── ④ ⭐ **표제 관문**(전부 ㊀ 뜻밖임 · 학습팔 ㋐) ──\n");
		LogA("[mlt] 🌉     ⭐ **㉣-a** `CE(㈂ 상태→비전) < ln3` — **%u/%u** ≥%u → %s\n",
			gSV, ok, kSignPass, gA ? "✅" : "⛔");
		LogA("[mlt] 🌉     ⭐ **㉣-b** 짝지은 `d = 전이율(㈂) − 전이율(㈄셔플)` = **%+.4f** · SE %.4f · **|d̄|/SE %.2f** (씨앗 %u) → %s\n",
			dm, se, tt, nd, !bApply ? "⚠️ 건너뜀(씨앗 3 이상에서만 유효)" : (gB ? "✅" : "⛔"));
		LogA("[mlt] 🌉     ⭐ **음성**(㈄ 셔플은 **실패해야 한다**) `CE < ln3` — **%u/%u** <%u → %s\n",
			gShuf, ok, kSignPass, gNeg ? "✅ 자가 살아 있다" : "⛔ **자가 죽었다**");

		// ── ⑤ ⭐ **대역 코사인** — 「전이」인가 「애초에 같음」인가 ─────────
		//   ⚠️ 1씨앗 진단이 이 자를 요구했다: ㈂(0.8747) 이 ㈀(0.8737) 과 **거의 같았다.**
		//   ★ 읽는 법 — **|cos| 가 크면**(> 0.5) 두 대역이 사실상 같은 벡터라 ***전이가 자명***하고,
		//     **작으면**(< 0.2) ㈂ 가 넘은 것은 ***진짜로 방향이 채널을 건넌 것***이다.
		double cm[kArms], cz[kArms]; uint32 cn = 0u;
		for (uint32 a = 0; a < kArms; ++a) { cm[a] = 0.0; cz[a] = 0.0; }
		for (uint32 s = 0; s < kSeeds; ++s)
		{
			if (!_seedOk[s]) continue;
			++cn;
			for (uint32 a = 0; a < kArms; ++a)
			{ cm[a] += (double)_cosMean[a][s]; cz[a] += (double)_cosShuf[a][s]; }
		}
		LogA("[mlt] 🌉   ── ⑤ ⭐ **대역 코사인**(상태 ↔ 비전 · 문맥 평균) — *「전이」인가 「애초에 같음」인가* ──\n");
		for (uint32 a = 0; a < kArms; ++a)
			LogA("[mlt] 🌉     %s │ cos **%+.4f** │ 셔플 대조 %+.4f │ 씨앗 %u\n",
				_ArmName(a), (cn == 0u) ? 0.0 : cm[a] / (double)cn,
				(cn == 0u) ? 0.0 : cz[a] / (double)cn, cn);
		const double cAbs = (cn == 0u) ? 0.0 : Abs((float)(cm[0] / (double)cn));
		LogA("[mlt] 🌉     ⇒ %s\n", (cAbs > 0.5)
			? "⚠️⚠️ **두 대역이 사실상 같은 벡터다** — 그러면 전이는 **잰 것이 없다**(누출 · D9)"
			: ((cAbs < 0.2)
				? "⭐ **두 대역이 거의 직교다** — 그러면 ㈂ 가 넘은 것은 ***진짜 전이***다"
				: "🔶 **중간이다** — 전이와 누출이 **섞여 있다**(이 회차로는 몫을 못 가른다 · D9)"));

		// ── ⑥ 판정 ─────────────────────────────────────────────────────
		// ⚠️⚠️⚠️ **첫 판정 실행이 내 관문의 구멍을 드러냈다** — 관문 넷이 다 섰는데 ⑤ 가
		//   `cos = 0.6547` 을 찍었고, 그런데 **판정 분기가 ⑤ 를 안 봤다**(보고로만 뒀다).
		//   ⇒ ★ **새 규율**: *진단이 새 자를 낳으면 그 자를 **관문에** 걸어라 —
		//     보고로만 두면 자동 판정이 그것을 무시하고 표제를 과하게 찍는다.*
		//   ★ 그래서 ⑤ 를 **해석 관문**으로 올린다: `|cos| > 0.5` 면 통과라도 **🔶 로 내린다.**
		const bool gCos = (cAbs <= 0.5);
		if (!plumb)
			LogA("[mlt] 🌉   ⭐ 판정 = ⛔ **판정불가** — 배관이 안 섰다(균형/재현/유한)\n");
		else if (regApply && regOk != kTgts)
			LogA("[mlt] 🌉   ⭐ 판정 = ⛔ **판정불가** — **회귀가 안 선다**(㈆ 가 회차 100 과 다르다)\n");
		else if (!gNeg)
			LogA("[mlt] 🌉   ⭐ 판정 = ⛔ **판정불가** — **음성 대조가 통과했다** = 전이가 아니라 ***자가 죽은 것***이다\n");
		else if (gA && gB && gCos)
			LogA("[mlt] 🌉   ⭐ 판정 = ⭐ ***상태로 배운 낱말이 비전 활성에서도 돈다*** — **L1 ㉣(채널 간 전이) 통과**\n"
			     "[mlt] 🌉      ⇒ ★ 두 대역이 겹치지 않는데도 방향이 건넜다 ⇒ **누출로 설명되지 않는다**\n");
		else if (gA && gB)
		{
			// ⭐ **겹침이 있을 때 그래도 남는 증거 둘** — 로그가 스스로 말하게 한다.
			//   ㉠ **겹침은 학습이 만든 것이 아니다**(무작위 팔도 cos 가 비슷하다) —
			//      그런데 **전이율은 팔 사이에서 훨씬 크게 갈린다** ⇒ 겹침만으로는 설명이 안 된다.
			//   ㉡ **방향이 비대칭이다**(→ ≫ ←) — 두 대역이 「같다」면 대칭이어야 한다.
			double fwd = 0.0, bwd = 0.0, fwdR = 0.0; uint32 nf = 0u, nb2 = 0u, nr = 0u;
			for (uint32 s = 0; s < kSeeds; ++s)
			{
				if (!_seedOk[s]) continue;
				double r;
				if (_Rate(kPrSV, kPrVV, 0u, 0u, s, r)) { fwd += r; ++nf; }
				if (_Rate(kPrVS, kPrSS, 0u, 0u, s, r)) { bwd += r; ++nb2; }
				if (_Rate(kPrSV, kPrVV, 1u, 0u, s, r)) { fwdR += r; ++nr; }
			}
			const double F = (nf == 0u) ? 0.0 : fwd / (double)nf;
			const double B = (nb2 == 0u) ? 0.0 : bwd / (double)nb2;
			const double R = (nr == 0u) ? 0.0 : fwdR / (double)nr;
			LogA("[mlt] 🌉   ⭐ 판정 = 🔶 **부분 통과** — 관문 넷은 다 섰으나 **두 대역이 겹친다**(cos %.3f > 0.5)\n"
			     "[mlt] 🌉      ⇒ ⚠️ *\"낱말이 채널을 건넜다\"* 의 **일부는 겹침 때문**이다 ⇒ **몫을 못 가른다**(D9)\n",
				cAbs);
			LogA("[mlt] 🌉      ⭐ **그래도 겹침만으로는 설명이 안 되는 증거 둘**:\n");
			LogA("[mlt] 🌉        ㉠ **겹침은 학습이 만든 게 아니다** — cos 학습 %.3f ↔ 무작위 %.3f(**%.2f배**)\n"
			     "[mlt] 🌉           그런데 **전이율은 %.3f ↔ %.3f(%.2f배)** ⇒ ***전이율이 훨씬 크게 갈린다***\n",
				(cn == 0u) ? 0.0 : cm[0] / (double)cn, (cn == 0u) ? 0.0 : cm[1] / (double)cn,
				(cn == 0u || Abs((float)(cm[1] / (double)cn)) < 1.0e-6) ? 0.0 : (cm[0] / cm[1]),
				F, R, (Abs((float)R) < 1.0e-6) ? 0.0 : (F / R));
			LogA("[mlt] 🌉        ㉡ **방향이 비대칭이다** — 전이 → **%.3f** ↔ 전이 ← **%.3f**\n"
			     "[mlt] 🌉           ★ 두 대역이 「같다」면 **대칭이어야 한다** ⇒ 「같음」으로는 설명이 안 된다\n", F, B);
		}
		else if (gA)
			LogA("[mlt] 🌉   ⭐ 판정 = 🔶 **반쪽** — 절대 문턱은 넘었으나(㉣-a ✅) **셔플과 못 가른다**(㉣-b ⛔)\n"
			     "[mlt] 🌉      ⇒ ⚠️ 그러면 넘은 것은 **방향이 아니라 편향/노름**일 수 있다 — ㈅ 바닥과 견줘 읽어라\n");
		else
			LogA("[mlt] 🌉   ⭐ 판정 = ⛔ **㉣ 실패** — 상태에서 맞춘 방향이 비전 채널에서 **균등바닥을 못 넘는다**\n"
			     "[mlt] 🌉      ⇒ ⭐ 그러면 낱말은 **채널마다 따로** 산다(하나의 개념이 채널을 안 건넌다)\n");
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

	CW_BODY(MLTL1A2)
};
