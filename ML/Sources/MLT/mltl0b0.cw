// mltl0b0.cw — 🎯 회차 89 · **양성 대조 — 「이 자로 무언가는 잡히나」** (`-mltl0b0`) ⚠️ **새 캔버스**
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 89 이다.** ⭐ **하네스보다 먼저 썼다.**
//
// ⚠️⚠️ **L0 캔버스가 아니다.** 규율 6 이 막는 것은 *"통과할 때까지 자 바꾸기"* 이고, 이 회차는
//   **다른 물음**이다 — **규율 16 이 요구하는 빠진 팔**(양성 대조)을 다는 것이다.
//
// ── ⭐ 왜 이 회차인가 — 회차 86~88 에는 **양성 대조가 없었다** ──────────
//   등록한 대조는 **㈁ 무작위 몸통** 하나이고 그것은 **음성 대조**다. *"이 자로 **무언가는** 잡힌다"*
//   를 보이는 팔이 없다 ⇒ ***그래서 음성 결과를 해석할 수 없다.***
//     말할 수 있는 것: 「내 회전 속도」가 **이 자로는** 안 잡힌다
//     말할 수 없는 것: 그것이 **표현에 없어서**인지 **자가 약해서**인지
//   ★ 이 트랙이 이미 적은 규칙의 **거울상**이다 — *"「값 섞기」가 안 떨어지면 판정불가다.
//     성능이 나쁘다는 뜻이 아니라 **측정하려는 것을 아직 측정하지 못했다**는 뜻이다"*(관문 ㉠ · 함정 101).
//     나는 그 규칙을 **음성 쪽에만** 적용하고 양성 쪽을 빠뜨렸다.
//
// ── ⭐ 사다리 셋 — 이것이 **벽의 자리를 찍는다** ────────────────────────
//   | 칸 | 표적 | 읽는 행 | 실패하면 |
//   | ㉮ 강한 양성   | `yaw`    | `t6·a3`(yaw **자기 행**) | ⛔ **기계가 깨졌다**(값이 문자 그대로 있다) |
//   | ㉯ 현실적 양성 | `yaw`    | `t6·a12`(**관문 행**)    | ⭐ **자는 멀쩡한데 관문 행이 상태 값을 안 나른다** |
//   | ㉰ 원래 물음   | `|dYaw|` | 두 행 다                 | 회차 88 재현 확인 |
//   ★ 세 칸을 **한 실행**에서 잰다(표적 2 × 뷰 2 × 팔 2 = 프로브 8 · 전부 CPU 라 싸다).
//
//   ⚠️ **표적 `yaw` 의 자리를 못박는다** — `StoreState(ctx, t, w.State())` 는 `Step()` **뒤**에
//     부르므로 `t` 행에 담긴 것은 `S(t+1)` 이다 ⇒ 관문 시각(`kTime−2`) 행의 값은 **`S7.yaw`** 이고
//     라벨도 **정확히 그 값**으로 잡는다(다른 시각의 yaw 가 아니다).
//
// ── 관문 ──────────────────────────────────────────────────────────────────
//   **배관** ㈃ 클래스 균형(순위 계급이라 **`sd = 0`** · ±1표본 · **두 표적 다**) · ㈄ 얼림/재현 비트동일
//   **표제① ㉮** `CE(㈀ · yaw · yaw자기행) < ln3` — `≥10/12`
//   **표제② ㉯** `CE(㈀ · yaw · 관문행)   < ln3` — `≥10/12` ← ***이것이 자를 판정한다***
//
// ── ⭐ 예측을 미리 적었다 ─────────────────────────────────────────────────
//   · **㉮ = 12/12**(㈀ **와 ㈁ 둘 다**) — 그 행의 잔차 흐름에 값이 **문자 그대로** 있고
//     다주파 사인 8개면 1D 3분위는 선형으로 충분히 잡힌다.
//   · **㉯ = ≥10/12** — 활성을 예측하려면 어텐션이 상태를 읽어야 하고, **회차 85a 가
//     *"몸통이 상태의 존재를 쓴다"* 를 10/12 로 보였다**.
//   · ⚠️⚠️ **반대 가능성이 진짜로 있다**: 같은 회차 85a 가 *"**값**은 덜 쓴다"*(㈂ 무작위 5/12)도 보였다.
//     ★ 그 경우 결론은 **「자는 성한데 관문 행이 상태 값을 안 나른다」**이고 ⇒ **풀링으로 가는 것이
//     정당해진다**(지금은 규율 6 이 막고 있는 그 길).
//
// ── (아래는 회차 88 의 머리말 원문) ────────────────────────────────────────
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **회차 88 등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 88 이다.**
//
// ⚠️⚠️ **회차 87 과 「읽는 행」 하나만 다르다** — `t=7` → **`t=6`**.
//   낱말 정의 · 팔 둘 · 씨앗 12 · 표제 둘 · `≥10/12` · 프로브 절차(맞춤/보정 · λ 격자) **전부 그대로**.
//
// ── ⭐ 회차 87 이 실측으로 가른 것 — **「본 자리」와 「하중을 받은 자리」는 다르다** ────
//   회차 87 은 12씨앗 전부에서 ㈀·㈁ 이 **`ln3` 에 딱 붙었다**(4자리에서 갈렸다). 원인을 코퍼스에서
//   찾았다:
//     · `MLTP3Ctx::StoreState` — 상태 축 `a<5` 는 **모든 t 에서** `IgnoreTgt`(*"상태는 채점하지 않는다"*)
//     · `MLTP3Ctx::StoreAct`   — 표적을 `t>0` 일 때 **`Row(ctx, t−1, ·)`** 에 쓴다
//       ⇒ 활성 슬롯의 표적은 **`t = 0 .. kTime−2`** 에만 있고 **`t = kTime−1`(=7) 은 비어 있다**
//     · `MLTModelCfg::kIgnoreTgt` 주석 — *"fwd 는 손실 0 · **bwd 는 기울기 0 을 쓴다**"*
//   ⇒ 인과 마스크상 **7번 위치 뒤에 아무도 없으므로** 그 잔차 흐름으로 들어오는 기울기가 **정확히 0**.
//   ⇒ ***회차 86·87 이 읽은 두 행은 둘 다 「한 번도 하중을 안 받은 자리」였다.***
//   ⚠️ 내가 회차 86 ④에 적은 논증(*"인과 마스크상 전부 본 자리"*)은 **본 것**만 맞고
//     **학습된 것**이 아니었다. 트랜스포머 프로브에서 그 둘은 다른 조건이다.
//
// ── 📏 **규율 15**(회차 87 이 세웠다) ──────────────────────────────────────
//   **읽을 자리는 「본 자리」가 아니라 「하중을 받은 자리」로 고른다.**
//   ★ 프로브를 붙이기 전에 ***그 행에 표적이 있나***를 **코퍼스에서** 확인한다.
//
// ── ⭐ 예측을 미리 적는다 ──────────────────────────────────────────────────
//   · 표제① `CE(㈀) < ln3` — **≥10/12** 예측(하중을 받은 자리면 무언가는 담겨 있어야 한다)
//   · 표제② `CE(㈀) < CE(㈁)` — **≥10/12** 예측
//   · ⚠️ **틀릴 수 있는 자리**: 그 행이 담는 것은 *"다음 시각의 활성 id"* 이고 **회전율은 그 원인**이다.
//     원인이 결과 예측에 필요하지 않은 방식으로 접혀 있으면(예: 화면 흐름 방향만 담고 크기는 안 담음)
//     여전히 `ln3` 에 붙는다 ⇒ 그러면 **「이 낱말은 이 자리에 선형으로 없다」**로 적고
//     ⭐ 다음 물음은 *"어느 낱말이 있나"* 가 된다(도형 종류 · 접근/후퇴 · 화면 흐름).
//
// ── (아래는 회차 87 의 머리말 원문) ────────────────────────────────────────
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **회차 87 등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 86 의 「다음 = 회차 87」 절이다.**
//
// ⚠️⚠️ **낱말 정의 · 읽는 행 · 팔 둘 · 씨앗 12 · 표제 둘 · `≥10/12` 는 한 글자도 안 바꾼다.**
//   ***결과를 보고 과제를 무르게 만들지 않는다.*** 바꾸는 것은 **자(측정 절차)뿐**이다.
//
// ── 회차 86 이 잡은 내 자 실수 둘과 그 고침 ────────────────────────────────
//  ⚠️ **실수 ⑥ — ㈃ 의 문턱이 잡음보다 작다**(규율 9 를 배관 관문에 안 썼다)
//     시험 512표본 클래스 비율의 이항 `sd = √(⅓·⅔/512) = 2.08%p` + 문턱을 512표본 **분위수**로
//     잡은 오차 ⇒ 합쳐 **≈2.9%p**. 등록한 `±3%p` 는 **딱 1 sd** ⇒ 6/12 가 자연스럽게 실패했다.
//     ★ **고침** — 낱말 계급을 **분할마다 자기 3분위**로 준다 ⇒ 균형이 **구성상 정확**(±1표본)이고
//       `ln3` 이 **정확한 바닥**이 된다. ⇒ 그러면 ㈃ 는 **코드가 도는지 보는 검사**가 된다(sd = 0).
//     ⚠️ 시험 라벨이 시험 표본들끼리로 정해지지만 **프로브는 그것을 못 본다**(가중치는 학습 분할에서
//       나오고 예측은 표본 하나만 본다) ⇒ **누출이 아니다.**
//
//  ⚠️ **실수 ⑦ — `W` 와 `τ` 를 같은 분할에서 맞췄다**(보정 붕괴)
//     정확도 **35.4% > 33.3%**(신호는 있다)인데 CE **1.1880 > ln3 1.0986** 이었고
//     `λ×0.1 < λ×1 < λ×10` 로 **규제가 셀수록 좋았다** ⇒ 등록한 `λ=1e-2` 가 너무 작았고,
//     과적합한 분할에서 고른 `τ` 가 시험에 안 맞았다 ⇒ ***프로브가 아니라 그 보정이 무너졌다.***
//     ★ **고침** — 프로브 학습 512 를 **맞춤 384 / 보정 128** 로 쪼갠다:
//       `W` 는 **맞춤**에서 · **`λ` 와 `τ` 는 보정**에서 고른다. ⚠️ **시험은 끝까지 안 본다.**
//       λ 는 **등록된 격자** `{×0.1, ×1, ×10, ×100}` 에서 보정 CE 가 가장 낮은 것.
//     ⚠️ **두 팔에 같은 절차**를 쓴다(짝지음이 깨지면 표제②가 뜻을 잃는다).
//
// ── ⭐ 예측을 미리 적었다(등록문) ──────────────────────────────────────────
//   · 보정을 고치면 ㈀ CE 가 `ln3` **아래로** 내려간다 ⇒ **표제① ≥10/12**
//   · 표제②는 회차 86 이 이미 **12/12 · λ 뒤집힘 0/12** 였으므로 **12/12**
//   · ⚠️ **틀릴 수 있는 자리**: 고쳐도 CE 가 `ln3` 위면 그것은 보정이 아니라 **표현에 그 구분이
//     없다**는 뜻이고, 그러면 표제②(12/12)는 *"㈁ 보다 덜 나쁠 뿐"* 이 된다 ⇒ **L0 미달**로 적는다.
//
// ── (아래는 회차 86 의 머리말 원문) ────────────────────────────────────────
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

class MLTL0B0
{
public:
	static void Tick(RHI* rhi)
	{
		if (_done || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltl0b0"))
		{
			LogA("[mlt] 🎯 회차 89(양성 대조)는 **꺼져 있다**(`-mltl0b0`)\n");
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
	static constexpr float  kUnif = 1.0986123f;          // ln 3

	// ⭐ **회차 87 의 고침 ②** — 프로브 학습을 **맞춤 / 보정**으로 쪼갠다.
	//   `W` 는 맞춤에서 · **`λ`·`τ` 는 보정에서** 고른다. ⚠️ 시험은 끝까지 안 본다.
	static constexpr uint32 kFitCtx = 384u;
	static constexpr uint32 kCalCtx = kPbCtx - kFitCtx;   // 128
	static_assert(kCalCtx >= 64u, "보정 분할이 너무 작으면 τ 가 그 자체로 흔들린다");
	// **등록된 λ 격자** — 결과를 보고 늘리지 않는다.
	static constexpr uint32 kLams = 4u;
	static constexpr float  kLamGrid[kLams] = { 0.1f, 1.0f, 10.0f, 100.0f };

	// ⭐ **회차 87 의 고침 ①** — 계급은 **분할마다 자기 3분위**다 ⇒ 균형이 **구성상 정확**.
	//   ⚠️ 그래서 이 관문의 `sd = 0` 이다(규율 14 — 관문 옆에 sd 를 적는다). 문턱은 **±1표본**.
	static constexpr uint32 kBalSlack = 1u;

	static constexpr uint32 kNone = MLTP3Ctx::kStateAx + kN;
	static constexpr uint32 kSymVocab = kNone + 1u;

	// 읽는 행 — ⚠️ **문맥 안 오프셋**이다(`b * kCtxLen` 을 더해 쓴다).
	// ⭐ **회차 88 이 고친 유일한 것** — 읽는 행을 `t=7` → **`t = kTime−2 = 6`** 으로 내린다.
	//   ⚠️⚠️ 회차 87 이 실측으로 가른 것: **`t=7` 은 표적이 없다** ⇒ `bwd 는 기울기 0 을 쓴다`
	//     (`MLTModelCfg::kIgnoreTgt` 주석) ⇒ 인과 마스크상 그 뒤에 아무도 없으므로 **그 잔차 흐름으로
	//     들어오는 기울기가 정확히 0** 이다 ⇒ ***"전부 본 자리" 이되 "하중을 받은 자리" 가 아니다.***
	//   ★ 표적이 사는 자리는 `MLTP3Ctx::StoreAct` 이 `t>0` 일 때 **`Row(ctx, t−1, ·)`** 에 쓴다
	//     ⇒ 활성 슬롯 `t = 0..kTime−2` 만 채점된다(상태 축은 **어느 t 에서도** 채점 안 한다).
	//   ⭐ **낱말은 그대로 유효하다** — `kHoldMid=5` 라 `t=5,6,7` 이 전부 `act(5)` 이므로
	//     `t=6` 행의 **인과 시야**(t≤6)에 그 증분(yaw[5]→yaw[6])이 들어 있다.
	static constexpr uint32 kRowGate = (kTime - 2u) * kAx + (kAx - 1u);   // 90 = 마지막 **채점되는** 행
	static constexpr uint32 kRowYaw  = (kTime - 2u) * kAx + 3u;           // 81 = 그 시각의 yaw 슬롯(부산물)

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
	// 표적 둘 — `A` = `|act.dYaw|`(회차 86~88 의 원래 물음) · **`B` = `yaw` 그 자체**(양성 대조)
	inline static Array<float> _mPb, _mPt;       // A 원값
	inline static Array<float> _mPbB, _mPtB;     // B 원값
	inline static Array<uint32> _yPb, _yPt;      // A 계급
	inline static Array<uint32> _yPbB, _yPtB;    // B 계급
	// 지금 프로브가 쓰는 계급(맞춤·보정 = 학습 쪽 / 시험 = 시험 쪽)
	inline static const uint32* _yTr = nullptr;
	inline static const uint32* _yTe = nullptr;
	inline static float _thr1 = 0.0f, _thr2 = 0.0f;

	// 결과
	inline static float _ce[kArms][kSeeds];              // 관문 뷰 · **보정 분할이 고른** λ·τ
	inline static float _ceFix[kArms][kSeeds];           // 감도 부산물 — λ 를 ×1 로 못박은 판
	inline static float _lam[kArms][kSeeds], _tau[kArms][kSeeds];
	inline static float _ceYaw[kArms][kSeeds];           // 부산물 뷰
	// ⭐ 양성 대조 — `yaw` 를 표적으로: `_cePos` = 관문행(㉯) · `_cePosY` = yaw자기행(㉮)
	inline static float _cePos[kArms][kSeeds], _cePosY[kArms][kSeeds], _accPos[kArms][kSeeds];
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
		LogA("[mlt] 🎯 **회차 89 · 양성 대조 — 「이 자로 무언가는 잡히나」**(⚠️ **새 캔버스** · 규율 16 이 요구한 빠진 팔)\n");
		LogA("[mlt] 🎯   ⚠️ L0 캔버스가 **아니다** — 규율 6 이 막는 것은 *통과할 때까지 자 바꾸기* 이고 이건 **다른 물음**이다\n");
		LogA("[mlt] 🎯   ⭐ 사다리 셋 — ㉮ **yaw × yaw자기행**(문자 그대로 그 행의 입력) · ㉯ **yaw × 관문행** · ㉰ `|dYaw|`(회차 88 재현)\n");
		LogA("[mlt] 🎯   자·자리·팔·씨앗·프로브 절차는 **회차 88 그대로** — `W`=맞춤 %u / `λ`·`τ`=보정 %u(시험 안 봄)\n",
			kFitCtx, kCalCtx);
		LogA("[mlt] 🎯   팔 둘 — **㈀ 학습 몸통** ↔ **㈁ 무작위 몸통**(⭐ 초기 가중치가 **같다**)\n");
		LogA("[mlt] 🎯   분리 셋 — 몸통 %u~%u · 프로브학습 %u~%u · 프로브시험 %u~%u\n",
			kTrainEpi, kTrainEpi + kNCtx - 1u, kPbEpi, kPbEpi + kPbCtx - 1u, kPtEpi, kPtEpi + kPtCtx - 1u);
		LogA("[mlt] 🎯   잡음 바닥 — 균등 CE **%.4f**(ln3) · 부호검정 %u/12 ⇒ p=0.0193 · 본페로니 **Q=0.0386**\n",
			(double)kUnif, kSignPass);
		LogA("[mlt] 🎯   ⭐ **예측** — ㉮ **12/12**(㈀·㈁ 둘 다) · ㉯ **≥10/12**(⚠️ 회차 85a 가 *값은 덜 쓴다* 도 봤다 ⇒ 떨어질 수 있다)\n");
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
		_mPb.Reset(0); _mPt.Reset(0); _mPbB.Reset(0); _mPtB.Reset(0);
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
					// ⭐ **양성 대조의 표적** — ⚠️ `StoreState` 는 `Step()` **뒤**라 `t` 행에 담기는 것은
					//   `S(t+1)` 이다 ⇒ 관문 시각(`kTime−2`) 행의 값을 **그 자리에서** 집는다.
					if (t == kTime - 2u)
					{
						if (_cor == 1u) _mPbB.Add(w.State().yaw);
						else if (_cor == 2u) _mPtB.Add(w.State().yaw);
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
		_MakeWords();
		_arm = 0u; _ToBody();
	}

	// ── ⭐ **고침 ①** — 계급을 **그 분할 안의 순위**로 준다 ⇒ 정확히 `n/3` 씩 ────────
	//   ⚠️ 동률은 **인덱스**로 가른다(결정적 — 같은 씨앗은 늘 같은 라벨).
	//   ⚠️⚠️ 시험 라벨이 시험 표본들끼리로 정해지지만 **프로브는 그것을 못 본다**
	//     (가중치는 학습 분할에서 나오고 예측은 표본 하나만 본다) ⇒ **누출이 아니다.**
	//   ★ 얻는 것 둘: ㈀ 균형 관문의 **`sd` 가 0** 이 된다(규율 14) ㈁ `ln3` 이 **정확한 바닥**이 된다.
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
		_RankClass(_mPb.Data(), kPbCtx, _yPb);
		_RankClass(_mPt.Data(), kPtCtx, _yPt);
		// ⭐ 양성 대조의 계급 — ⚠️ `yaw` 는 **음수도 된다**. 순위 계급이라 범위 가정이 없다.
		_RankClass(_mPbB.Data(), kPbCtx, _yPbB);
		_RankClass(_mPtB.Data(), kPtCtx, _yPtB);
		// 기록용 경계값 — 계급 1·2 의 최솟값(관문이 아니라 사람이 읽는 눈금)
		_thr1 = 1.0e30f; _thr2 = 1.0e30f;
		uint32 cnt[kCls] = { 0u, 0u, 0u };
		for (uint32 i = 0; i < kPtCtx; ++i)
		{
			const uint32 c = _yPt[i]; ++cnt[c];
			if (c == 1u && _mPt[i] < _thr1) _thr1 = _mPt[i];
			if (c == 2u && _mPt[i] < _thr2) _thr2 = _mPt[i];
		}
		const uint32 tgt = (kPtCtx + kCls / 2u) / kCls;      // 512 → 171
		bool ok = true;
		for (uint32 c = 0; c < kCls; ++c)
		{
			_bal[_seed][c] = (float)cnt[c] / (float)kPtCtx;
			const uint32 d = (cnt[c] > tgt) ? (cnt[c] - tgt) : (tgt - cnt[c]);
			if (d > kBalSlack) ok = false;
		}
		// ⚠️ **양성 대조의 계급도 같은 관문을 통과해야 한다**(한쪽만 보면 그 표적의 바닥이 `ln3` 이 아니다).
		uint32 cntB[kCls] = { 0u, 0u, 0u };
		for (uint32 i = 0; i < kPtCtx; ++i) ++cntB[_yPtB[i]];
		for (uint32 c = 0; c < kCls; ++c)
		{
			const uint32 d = (cntB[c] > tgt) ? (cntB[c] - tgt) : (tgt - cntB[c]);
			if (d > kBalSlack) ok = false;
		}
		_balOk[_seed] = ok;
		LogA("[mlt] 🐣 씨앗 %2u · 낱말 경계 **%.4f / %.4f** · 시험 표본 %u/%u/%u(목표 %u±%u) → %s\n",
			_seed, (double)_thr1, (double)_thr2, cnt[0], cnt[1], cnt[2], tgt, kBalSlack,
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
	//   ⭐ **고침 ②** — `W` 는 **맞춤 분할**(앞 `kFitCtx`)에서만 나온다.
	inline static Array<float> _A, _B, _W, _Wb;

	static bool _Fit(uint32 view, float lamScale, float* W)
	{
		const float* X = _fPb.Data() + (uint64)view * kPbCtx * kFeat;
		_A.Reset(0); _B.Reset(0);
		for (uint32 i = 0; i < kFeat * kFeat; ++i) _A.Add(0.0f);
		for (uint32 i = 0; i < kFeat * kCls; ++i) _B.Add(0.0f);
		float* A = _A.Data(); float* B = _B.Data();
		for (uint32 i = 0; i < kFitCtx; ++i)
		{
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

	// ⭐ **고침 ②** — **온도는 「보정 분할」에서만** 고른다(맞춤 분할이 아니다).
	//   거친 격자 뒤 한 번 세밀화 — 결정적이다.
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

	// `lamFix < 0` = **등록된 격자에서 보정 CE 로 고른다** · `>= 0` = 그 배율로 못박는다(감도 부산물).
	static bool _Probe(uint32 view, float lamFix, float& ceOut, float& accOut, float& lamOut, float& tauOut)
	{
		const float* Xc = _fPb.Data() + ((uint64)view * kPbCtx + kFitCtx) * kFeat;
		const uint32* yc = _yTr + kFitCtx;
		_Wb.Reset(0);
		for (uint32 i = 0; i < kFeat * kCls; ++i) _Wb.Add(0.0f);
		float bestLam = 0.0f, bestTau = 1.0f; double bce = 1.0e30;
		for (uint32 li = 0; li < kLams; ++li)
		{
			const float lam = (lamFix >= 0.0f) ? lamFix : kLamGrid[li];
			_W.Reset(0);
			for (uint32 i = 0; i < kFeat * kCls; ++i) _W.Add(0.0f);
			if (!_Fit(view, lam, _W.Data())) { if (lamFix >= 0.0f) return false; continue; }
			const float tau = _FitTau(Xc, yc, _W.Data());
			const double ce = _Ce(Xc, yc, kCalCtx, _W.Data(), tau, nullptr);
			if (ce < bce)
			{
				bce = ce; bestLam = lam; bestTau = tau;
				for (uint32 i = 0; i < kFeat * kCls; ++i) _Wb.Data()[i] = _W[i];
			}
			if (lamFix >= 0.0f) break;
		}
		if (bce > 1.0e29) return false;
		// ⚠️ **시험은 여기서 처음이자 마지막으로 본다.**
		const float* Xt = _fPt.Data() + (uint64)view * kPtCtx * kFeat;
		uint32 hit = 0u;
		ceOut = (float)_Ce(Xt, _yTe, kPtCtx, _Wb.Data(), bestTau, &hit);
		accOut = (float)hit / (float)kPtCtx;
		lamOut = bestLam; tauOut = bestTau;
		return true;
	}

	// ⭐ **사다리 넷** — 표적 둘(`|dYaw|` · **`yaw`**) × 읽는 행 둘(관문행 · yaw자기행).
	//   ㉮ 강한 양성 = `yaw` × yaw자기행 · ㉯ 현실적 양성 = `yaw` × **관문행** · ㉰ 원래 물음 = `|dYaw|`.
	static void _SetTarget(uint32 tg)
	{
		_yTr = (tg == 0u) ? _yPb.Data()  : _yPbB.Data();
		_yTe = (tg == 0u) ? _yPt.Data()  : _yPtB.Data();
	}

	static void _Judge()
	{
		float acc = 0.0f, dummy = 0.0f, dl = 0.0f, dt = 0.0f;
		// ㉰ 원래 물음 — `|dYaw|` (관문행 · yaw자기행)
		_SetTarget(0u);
		if (!_Probe(0u, -1.0f, _ce[_arm][_seed], acc, _lam[_arm][_seed], _tau[_arm][_seed]))
		{ _Fail("프로브(㉰ dYaw · 관문행)"); return; }
		if (!_Probe(1u, -1.0f, _ceYaw[_arm][_seed], dummy, dl, dt)) { _Fail("프로브(㉰ dYaw · yaw행)"); return; }
		_acc[_arm][_seed] = acc;
		// ㉯ 현실적 양성 · ㉮ 강한 양성 — 표적을 **`yaw` 그 자체**로 바꾼다
		_SetTarget(1u);
		if (!_Probe(0u, -1.0f, _cePos[_arm][_seed], _accPos[_arm][_seed], dl, dt))
		{ _Fail("프로브(㉯ yaw · 관문행)"); return; }
		if (!_Probe(1u, -1.0f, _cePosY[_arm][_seed], dummy, dl, dt)) { _Fail("프로브(㉮ yaw · yaw행)"); return; }
		LogA("[mlt] 🎯   %s 씨앗 %2u · **㉮ %.5f** · **㉯ %.5f**(정확도 %.1f%%) │ ㉰ 관문행 %.5f(%.1f%%) · ㉰ yaw행 %.5f\n",
			_ArmName(), _seed,
			(double)_cePosY[_arm][_seed], (double)_cePos[_arm][_seed], 100.0 * (double)_accPos[_arm][_seed],
			(double)_ce[_arm][_seed], 100.0 * (double)acc, (double)_ceYaw[_arm][_seed]);
		if (++_arm < kArms) { _ToBody(); return; }
		_seedOk[_seed] = _finite;
		++_seed; _st = kEncInit;
	}

	static void _Summary()
	{
		// 평균 — [팔][칸] · 칸 0=㉮ yaw자기행 · 1=㉯ 관문행 · 2=㉰ dYaw 관문행 · 3=㉰ dYaw yaw행
		double m[kArms][4];
		for (uint32 a = 0; a < kArms; ++a) for (uint32 c = 0; c < 4u; ++c) m[a][c] = 0.0;
		double mAcc = 0.0, mAccP = 0.0;
		uint32 ok = 0u, bal = 0u, rep = 0u;
		uint32 g1 = 0u, g1B = 0u, g2 = 0u, g2B = 0u, gOld = 0u, gOldB = 0u;
		for (uint32 s = 0; s < kSeeds; ++s)
		{
			if (!_seedOk[s]) continue;
			++ok;
			if (_balOk[s]) ++bal;
			if (_repOk[s]) ++rep;
			for (uint32 a = 0; a < kArms; ++a)
			{
				m[a][0] += _cePosY[a][s]; m[a][1] += _cePos[a][s];
				m[a][2] += _ce[a][s];     m[a][3] += _ceYaw[a][s];
			}
			mAcc += _acc[0][s]; mAccP += _accPos[0][s];
			if (_cePosY[0][s] < kUnif) ++g1;    if (_cePosY[1][s] < kUnif) ++g1B;
			if (_cePos [0][s] < kUnif) ++g2;    if (_cePos [1][s] < kUnif) ++g2B;
			if (_ce    [0][s] < kUnif) ++gOld;  if (_ce    [1][s] < kUnif) ++gOldB;
		}
		if (ok > 0u)
		{
			for (uint32 a = 0; a < kArms; ++a) for (uint32 c = 0; c < 4u; ++c) m[a][c] /= ok;
			mAcc /= ok; mAccP /= ok;
		}
		const bool plumb = (bal == ok) && (rep == ok) && _finite && (ok > 0u);
		const bool p1 = (g1 >= kSignPass), p2 = (g2 >= kSignPass);

		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🎯 **회차 89 · 양성 대조 — 「이 자로 무언가는 잡히나」** — 읽은 씨앗 %u/%u\n", ok, kSeeds);
		LogA("[mlt] 🎯   ⚠️ 견줄 것(**회차 88**) — ㈀ 1.1011 · ㈁ 1.1041 · 표제① **6/12** ⛔ · 표제② 7/12 ⛔\n");
		LogA("[mlt] 🎯   배관 — ㈃ 클래스 균형(sd=0 · ±%u표본) **%u/%u** · ㈄ 얼림/재현(비트동일) **%u/%u** → %s\n",
			kBalSlack, bal, ok, rep, ok, plumb ? "통과" : "⛔");
		LogA("[mlt] 🎯   균등바닥 **%.4f**(ln3)\n", (double)kUnif);
		LogA("[mlt] 🎯   ㉮ **강한 양성**(yaw × yaw자기행) — ㈀ **%.4f** · ㈁ %.4f │ `<ln3` **%u/%u** · ㈁ %u/%u\n",
			m[0][0], m[1][0], g1, kSeeds, g1B, kSeeds);
		LogA("[mlt] 🎯   ㉯ **현실적 양성**(yaw × **관문행**) — ㈀ **%.4f** · ㈁ %.4f │ `<ln3` **%u/%u** · ㈁ %u/%u · 정확도 %.1f%%\n",
			m[0][1], m[1][1], g2, kSeeds, g2B, kSeeds, 100.0 * mAccP);
		LogA("[mlt] 🎯   ㉰ 원래 물음(|dYaw| × 관문행) — ㈀ %.4f · ㈁ %.4f │ `<ln3` %u/%u · 정확도 %.1f%%(회차 88 재현)\n",
			m[0][2], m[1][2], gOld, kSeeds, 100.0 * mAcc);
		LogA("[mlt] 🎯   **표제① ㉮ ≥%u** → %s   ·   **표제② ㉯ ≥%u** → %s\n",
			kSignPass, p1 ? "✅" : "⛔", kSignPass, p2 ? "✅" : "⛔");
		if (!plumb)
			LogA("[mlt] 🎯   ⭐ 판정 = ⛔ **판정불가** — 배관이 안 섰다(균형/재현)\n");
		else if (!p1)
			LogA("[mlt] 🎯   ⭐ 판정 = ⛔⛔ **기계가 깨졌다** — 값이 **문자 그대로 그 행에** 있는데 못 잡는다 ⇒ 프로브/리드백/라벨 배관을 판다\n");
		else if (p2)
			LogA("[mlt] 🎯   ⭐ 판정 = ✅ **자는 멀쩡하다** ⇒ 회차 86~88 의 null 은 **진짜**다 ⇒ ***「내 회전 속도」는 이 표현에 없다*** ⇒ **낱말을 바꾼다**\n");
		else
			LogA("[mlt] 🎯   ⭐ 판정 = ⚠️⚠️ **자는 멀쩡한데 「관문 행」이 상태 값을 안 나른다** ⇒ **읽는 형식(풀링)으로 간다** · 회차 86~88 의 null 은 **판정불가로 격하**\n");
		LogA("[mlt] 🎯   ⚠️ 문맥 %u · 프로브 %u/%u · 3분류의 진단이다 — 절대 성능으로 인용하지 않는다\n",
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

	CW_BODY(MLTL0B0)
};
