// mltworld.cw — 🌍 **세계와 사건 생성기.** 한 틱이 **(관측 상태 · 행동 명령 · 프레임)** 을 낸다
//
// ★ **왜 이 파일이 못(nail)인가** — `mltconcept.md` 의 접지 기제가 *"대응을 주지 않고 **같은
//   사건 안에 놓는 것**"* 뿐이다. 그 「같은 사건」을 만드는 것이 여기이고, 이것이 깨지면
//   **상태 접지와 비전 접지가 서로를 도울 근거가 사라진다.**
//   ⚠️ 그리고 `ImageOps` 는 **2D 전용**이라 3D 투영을 **손으로** 쓴다 ⇒ ***그 손코드가 그 못의
//     유일한 몸통이다.*** FOV·클리핑·화면 사상 상수가 아래 **한 상수 표**에 있다.
//
// ══════════════════════════════════════════════════════════════════════════════
// ⛔⭐ **① 상태는 「관측 상태」다 — 제어 명령이 아니다**
// ══════════════════════════════════════════════════════════════════════════════
//   처음 설계가 *"상태 = 카메라를 움직인 파라미터(속도)"* 였고 **그것이 P0 을 무효로 만든다:**
//   속도는 **우리가 고르는 것**이라 시뮬이 「다음 값」의 정답을 **안 갖고 있다**
//   ⇒ P0 이 재는 것이 ***세계가 아니라 우리가 쓴 난수 프로세스***가 된다. 그리고 P4 가 P0 과 붕괴한다.
//
//   ```
//   상태 슬롯 = **관측 상태**(위치 x·y·z · 방위 yaw·pitch)   ← P0 의 표적 · 세계가 굴린다
//   ACT 대역  = **속도 명령**                                 ← P4 가 「주어진 행동값」으로 받는다
//                       state[t+1] = f(state[t], v[t])
//   ```
//
// ⚠️ **⑦ 틱 규약은 한 줄이다**: `apply(행동을 정한다) → advance(상태를 굴린다) → render(그 상태를 그린다)`
//   ⇒ `Frame(t)` 는 **`State(t)` 의 결과**다(행동 `t` 를 적용한 **뒤**의 상태).
//   ⚠️⚠️ 한 틱 밀려도 **P0 에는 증상이 0** 이고 P3 에서 처음 보인다 ⇒ 배관 관문에 부호 검사를 둔다.
//
// ⚠️ **⑥ 경계는 반사다**(clamp 가 아니다) — **clamp 는 복사 베이스라인의 구원**이라 지수의
//   **부호를 뒤집는다**(경계에 붙어 있으면 «다음 = 지금» 이 거의 맞는다).
//
// ⚠️ **⑧ 난수는 3단 주소지정이고 스트림을 전진시키지 않는다**(아래 `_Addr`/`_H`).
//   전역 스트림을 쓰면 어떤 변종이 난수를 한 번 더 뽑는 것만으로 **대조군이 움직이고 판 사이 비교가
//   성립하지 않는다.** ⚠️ 그리고 **확산이 약한 해시는 옆 소금값의 하위 2비트가 거의 같아
//   `%4`·`%3` 을 안 가른다** ⇒ 여기 것은 **확산 강화판**이다.
//
// ⚠️ **⑬ 씨앗 주소에 틱 번호를 쓰지 않는다** — `(씨앗번호, 에피소드, 스텝)` 이다.
//   시간으로 씨앗하면 **순서를 바꾸는 실험이 데이터를 바꾼다.**
//
// ⚠️ **⑨ 자율 변화**(스스로 움직이는 도형)는 몫을 셋(`kAuto*`)으로 둔다. 0 이면 P4 의 **오귀속률이
//   정의 불가**(모든 변화가 내 행동이다)이고, 크면 P3 이 포화한다.
//   ⚠️⚠️ **P0 의 난이도 축으로 쓰지 않는다** — 난이도는 **③ 전환율**이다.

using namespace PE;

// ══════════════════════════════════════════════════════════════════════════════
// 📐 한 상수 표 — ⚠️ **같은 사실이 두 곳에 살면 반드시 한쪽이 진다.** 전부 여기에만 있다.
// ══════════════════════════════════════════════════════════════════════════════
struct MLTWorldCfg
{
	// ── 프레임 알파벳 (⚠️ 형제 트랙과 같아야 회차를 견준다) ──────────
	//   ★ **64²** 다. 근거: 프레임의 「글자 수」가 곧 비용(64²=4096B ↔ 캡션 20~40B ⇒ ~130배)이고
	//     **아래로 못 간다**(48² 면 `kStroke=2` 테두리가 속을 못 남겨 「빈/찬」 축이 죽는다).
	static constexpr int   kSide   = 64;
	static constexpr int   kPixels = kSide * kSide;

	// ── 투영 (⚠️ 이 셋이 「못」의 상수다) ────────────────────────────
	static constexpr float kFocal   = 1.2f;    // 화면 반폭 기준 초점거리
	static constexpr float kNear    = 0.25f;   // 이보다 가까운 것은 안 그린다
	static constexpr float kFar     = 8.0f;
	static constexpr float kStroke  = 2.0f;    // ⚠️ 1.5 미만이면 큰 반지름에서 테두리에 **구멍**

	// ── 상태 역학 ────────────────────────────────────────────────
	static constexpr float kDt      = 0.12f;   // 한 틱의 적분 폭
	static constexpr float kBound   = 1.0f;    // 관측 상태의 범위(±) — **반사**한다

	// ── ③ 난이도 = **전환율** (행동 명령이 바뀌는 빈도) ─────────────
	//   ⚠️ 속도 폭은 **스케일 변환**이라 배율이 평평하고, 물체 수는 지수가 ≈0 이다.
	//   ★ 세 점은 **경우의 수**를 흔든 것이다(의존 깊이 축이 아니다).
	static constexpr int   kHoldEasy = 12;     // 12틱마다 한 번 바뀐다 ⇒ 복사가 강하다
	static constexpr int   kHoldMid  = 5;
	static constexpr int   kHoldHard = 2;      // 거의 매 틱 바뀐다

	// ── ⑨ 자율 변화의 몫 ───────────────────────────────────────
	static constexpr int   kShapes   = 14;      // 도형 개수(⚠️ 난이도 축이 **아니다**)
	//   ★ 고리에 놓으므로 개수가 곧 **각 간격**이다: 8개면 45° 마다 ⇒ 시야각 ≈80° 에 늘 2개쯤 든다.
	static constexpr int   kAutoNone = 0, kAutoFew = 1, kAutoMany = 3;   // 자율 도형 수

	// ── ⚖️ **자기상태 채널(에너지)** — ⚠️⚠️ **기본 꺼짐**(`MLTWorld::SetEnergy(true)`) ──────
	//   ★ 근거 = `mltconcept.md` 「⚖️ 부호 있는 자기 입력 채널이 최소 하나」. **하나**여야 하는
	//     이유도 그 절에 있다(*"적응에는 목표도 하나여야 한다"* · 함정 387 닭과 달걀).
	//   ⚠️ 상수 넷은 **손잡이**다 — 서명(평균·sd·자기상관·둔화 발동)이 죽어 있으면 이것을 돌린다.
	//   ⚠️⚠️ **단조 감소로 두지 않았다** — 그러면 부호가 한 번만 뒤집혀 목적이 세분화되지 않는다
	//     (컨셉의 온도 예시가 「매우 뜨거움 → 평온」 왕복이어야 하는 그 이유).
	//
	// ── ⭐ 첫 값의 **손계산**(규율 21 — 재기 전에 범위를 계산했다) ─────────────────
	//   `_PickAct` 의 진폭에서 행동 크기 합의 기대는
	//     `E[mag] = 0.5(fwd) + 0.25(up) + 0.35(side) + 0.30(dYaw) + 0.20(dPitch) = **1.60**`
	//   ⚠️ 문맥이 **8틱**이므로 그 안에서 문턱을 **넘나들어야** 한다 ⇒ 시간상수 ~4틱으로 잡는다:
	//     ㉠ 움직일 때   `D·1.60·dt − G·dt = 0.65 / 4틱`
	//     ㉡ 둔화 회복시 `G·dt − D·1.60·dt·kEnergySlow = 0.65 / 5틱`
	//   ⇒ 풀면 `D ≈ 2.35 · G ≈ 2.40` ⇒ **왕복 ≈ 9틱** ⇒ 8틱 문맥 안에 강하와 회복이 둘 다 든다.
	//   ⚠️⚠️ **처음 쓴 값(0.28 / 0.10)은 손계산으로 기각됐다** — 8틱에 `1.0 → 0.78` 밖에 안 떨어져
	//     **둔화가 한 번도 안 발동**했다(= ㈂ 기능적 결과가 죽는다). ★ 재기 전에 잡았다.
	static constexpr float kEnergyDrain = 2.40f;   // 행동 크기 합 1 당 소모 배율
	static constexpr float kEnergyGain  = 2.40f;   // 회복 배율(가만있으면 돌아온다)
	static constexpr float kEnergyLow   = 0.35f;   // 이 아래면 둔화한다(㈂ 기능적 결과)
	static constexpr float kEnergySlow  = 0.35f;   // 둔화 배율(㈃ 닫힘 — 덜 쓰므로 회복한다)

	// ══════════════════════════════════════════════════════════════════
	// ⚖️⚖️ **몸**(회차 264) — 이득을 **외형**에 건다. ⚠️⚠️ **기본 꺼짐**(`SetBody`)
	// ══════════════════════════════════════════════════════════════════
	//   ★ 여태 `kEnergyGain` 이 **상수**여서 ***이 세계에는 좋은 것도 나쁜 것도 없었다***
	//     (비용은 자기 행동에만 붙고 이득은 세계와 무관했다) ⇒ 그것이 「부호가 없다」의 실체다.
	//   ⇒ ⭐ 이득을 **관측 가능한 범주**의 함수로 만든다. ⚠️ **도형 번호에 걸면 안 된다** —
	//     `Addr(_seedNo, _epi, 0u) + i*131u` 가 외형·운동 상수를 다 정하므로 **번호는
	//     에피소드마다 뜻이 바뀐다**(그것은 정체성이 아니라 에피소드-지역 주소다).
	//     ★ `kind`(원/사각/빈원)는 **범주로서 에피소드를 건너 안정**하다 ⇒ 여기에 건다.
	//   ⭐ 뜻하지 않은 이득: `index → kind` 결속이 에피소드마다 재추첨되므로 모델은
	//     **번호 암기로 먹이를 못 찾는다 — 외형으로 배워야 한다**(범주 학습을 세계가 강제한다).
	//   ⚠️⚠️ 이름을 모델에 주지 않는다 — 모델이 보는 자기 값은 `_e` **하나**이고 누적기다.
	static constexpr int   kBodyFoodKind = 0;      // 찬 원   = 먹이(+)
	static constexpr int   kBodyPoisKind = 1;      // 찬 사각 = 독(−) · 남은 빈 원은 중립
	// ⭐ 이득의 흔들림 폭. ★ **평균을 안 바꾼다** — 먹이와 독이 각각 외형 셋 중 하나라
	//   기대가 상쇄된다 ⇒ 「세계를 조용하게 만들었다」 교란을 줄인다(공용 규율 1 의 그 경고).
	static constexpr float kBodyAmp  = 0.80f;
	static constexpr float kBodyBias = 0.60f;      // 반사의 `dYaw` 진폭(⚠️ `_PickAct` 의 그 축 범위)

	// ── ✂️ **가지치기**(회차 237 심사 · `MLTWorld::SetPrune(true)`) — ⚠️⚠️ **기본 꺼짐** ──
	//   ⛔⛔ **237 이 함정을 먼저 잡았다**: *"에너지가 낮으면 진폭을 줄인다"* 는 위 `sc` 둔화와
	//     ***수학적으로 같다***(둘 다 `act × k` 다) ⇒ **가지치기가 아니라 감쇠다.**
	//   ⇒ ★★ 자매 문서 2.3 이 요구한 것은 ***"배고프면 먹는 것만 보인다"*** = **선택지가 줄어드는 것**
	//     ⇒ 등방적으로 작아지는 것이 아니라 **어떤 축은 못 쓰게 되는 것**이다.
	//   ⇒ ⭐ 그래서 **축별 비용**을 둔다: **병진이 회전보다 비싸다**(질량을 옮기는 일 ↔ 방향만 바꾸는 일).
	//     ⇒ ⇒ ★ 에너지가 낮으면 **비싼 축이 먼저 잘린다** ⇒ 카메라가 **제자리에서 돌기만** 한다
	//       ⇒ ⭐⭐ ***같은 물체들을 계속 보게 된다*** = 표적 분포가 좁아진다(기제 가설).
	//   ⚠️⚠️ **정책이 아니라 법칙이다** — 우리가 적는 것은 *"병진이 비싸다"*(물리)이고
	//     *"배고프면 저 물체로 가라"*(방향)를 적으면 **그것이 정책 주입**이다. 후자를 안 적는다.
	//   ⚠️ 축 순서는 `MLTAct::Axis` 와 같다: fwd · up · side · dYaw · dPitch
	static constexpr float kActCost[5] = { 1.00f, 1.00f, 1.00f, 0.30f, 0.30f };
	//   ⚠️ 예산 = `_e`. 비싼 축부터 예산을 태우고 **못 내는 축은 0 이 된다.**
	//     ★ `kPruneBudget` 은 「에너지 1.0 이 살 수 있는 비용」이다 — 손계산으로 정한다:
	//       `E[비용] = 0.5·1 + 0.25·1 + 0.35·1 + 0.30·0.3 + 0.20·0.3 = **1.25**`
	//       ⇒ 예산을 `_e × 1.25` 로 두면 **에너지가 1 일 때 평균적으로 전부 살 수 있고**
	//         0.35(둔화 문턱)면 **0.44** ⇒ 병진 하나(평균 0.5)도 못 사는 자리가 생긴다.
	static constexpr float kPruneBudget = 1.25f;
	//   ⭐⭐ 회차 239 — **예산이 손잡이다**(238 이 그 이유를 표 안에 냈다):
	//     가지치기가 켜지면 둔화가 **7.6 → 0.6** 으로 준다 ⇒ ***가지치기가 에너지를 보존해
	//     자기 효과를 스스로 약화시킨다***(조건 ㈃ 닫힘이 좁힘의 깊이를 제한한다).
	//   ⇒ ★ 그래서 「얼마나 잘리나」가 아니라 **「예산이 얼마인가」**를 민다.
	//   ⚠️ 손계산 격자(규율 21·83): `E[병진] = 1.10` · `E[회전] = 0.15`
	//     1.25 = 전부 산다 · 0.60 = 병진 하나만 · **0.30 = 회전만**(제자리 회전)
	//   ⚠️⚠️ **0.15 아래로 안 내린다** — 회전도 잘리면 그것은 좁힘이 아니라 **정지 세계**이고
	//     규율 88(음성 대조가 1등이면 관문이 틀렸다)의 그 자리다.

	// ── ⑧ 난수 대역 ──────────────────────────────────────────────
	//   ★ 씨앗 두 벌: **0~11 개발/결정용** · **12~23 판정용 holdout**.
	static constexpr uint32 kSeeds     = 12u;
	static constexpr uint32 kSeedJudge = 12u;   // 판정 벌의 시작 번호
	static constexpr uint32 kBandBase  = 0x51ED2701u;
	static constexpr uint32 kBandPrime = 2654435761u;   // 씨앗 사이 간격
	static constexpr uint32 kEpiStride = 1000003u;      // 에피소드 사이
	static constexpr uint32 kStepStrid = 7919u;         // 스텝 사이
};

// ⚠️ **소금 표** — 선택마다 자기 `(소금, 스트림)` 짝을 갖는다. 자릿수를 벌려 둔다
//   (옆 숫자를 쓰면 확산이 약한 해시에서 하위 비트가 겹친다).
enum class MLTSalt : uint32
{
	Act      = 0x1000u,   // 행동 명령
	Hold     = 0x2000u,   // 언제 바꿀까
	ShapePos = 0x3000u,   // 도형 자리
	ShapeKind= 0x4000u,   // 도형 종류
	ShapeCol = 0x5000u,   // 도형 색
	AutoVel  = 0x6000u,   // 자율 도형의 속도
	Start    = 0x7000u,   // 시작 상태
};

// 관측 상태 다섯 축 — ⚠️ **P0 의 표적**이다.
struct MLTState
{
	float x = 0.0f, y = 0.0f, z = 0.0f;   // 위치
	float yaw = 0.0f, pitch = 0.0f;       // 방위
	static constexpr int kAxes = 5;
	float Axis(int i) const
	{
		switch (i) { case 0: return x; case 1: return y; case 2: return z; case 3: return yaw; default: return pitch; }
	}
};

// ══════════════════════════════════════════════════════════════════════════════
// 👁️‍🗨️ **판정 창구** — 시뮬레이터의 은닉 상태 하나. ⚠️⚠️ **학습 입력이 아니다.**
// ══════════════════════════════════════════════════════════════════════════════
//   `mltconcept.md` 가 금지하는 것은 **모델에** 라벨을 주는 것이고, **평가자가 은닉 상태를 아는
//   것은 오히려 판정의 전제**다(「개입이 예측을 가르나」·「활성이 물체를 가르나」가 그것으로만 선다).
//   ⚠️ 이 값을 인코더 입력·손실·표적 어디에도 넣지 마라 — 그 순간 라벨을 준 것이다.
//   ★ `index` 가 곧 identity 다(한 에피소드 안에서 `kind`·`col` 이 그 번호에 고정돼 있다).
struct MLTShapeView
{
	int    index = 0;          // 도형 번호 = identity
	int    kind  = 0;          // 0 = 찬 원 · 1 = 찬 사각 · 2 = 빈 원
	uint32 col   = 0u;         // 팔레트 0..4
	float  sx = 0.0f, sy = 0.0f;   // 화면 자리(픽셀)
	float  r  = 0.0f;              // 화면 반지름(픽셀)
	float  d  = 0.0f;              // 깊이(카메라 앞 거리)
};

// 행동 명령 다섯 축 — ⚠️ **우리가 고른다**(정답이 없다). `ACT` 대역이고 P4 가 받는다.
struct MLTAct
{
	float fwd = 0.0f, up = 0.0f, side = 0.0f;   // 속도
	float dYaw = 0.0f, dPitch = 0.0f;           // 각속도
	static constexpr int kAxes = 5;
	float Axis(int i) const
	{
		switch (i) { case 0: return fwd; case 1: return up; case 2: return side; case 3: return dYaw; default: return dPitch; }
	}
};

class MLTWorld
{
public:
	// ══════════════════════════════════════════════════════════════════
	// 🎲 **확산 강화 해시** — ⚠️ 확산이 약한 판은 옆 소금값의 하위 2비트가 거의 같아
	//   `% 4`·`% 3` 같은 **작은 모듈러가 안 갈린다**(형제 트랙이 그것으로 밟았다).
	//   세계 생성기는 방향·종류·색 같은 작은 모듈러를 잔뜩 쓰므로 여기는 **강화판**이어야 한다.
	// ══════════════════════════════════════════════════════════════════
	static uint32 Hash(uint32 a, MLTSalt salt, uint32 stream)
	{
		uint32 h = a + (uint32)salt * 0x9E3779B9u + stream * 0x85EBCA6Bu;
		h ^= (h >> 16); h *= 0x7FEB352Du;
		h ^= (h >> 15); h *= 0x846CA68Bu;
		h ^= (h >> 16);
		return h;
	}

	// ⚠️ **3단 주소지정** — 스트림을 **전진시키지 않는다**(계산만 한다).
	//   `(씨앗번호, 에피소드, 스텝)` — ⚠️ **틱 번호를 쓰지 않는다.**
	static uint32 Addr(uint32 seedNo, uint32 episode, uint32 step)
	{
		return MLTWorldCfg::kBandBase
			+ seedNo  * MLTWorldCfg::kBandPrime
			+ episode * MLTWorldCfg::kEpiStride
			+ step    * MLTWorldCfg::kStepStrid;
	}

	// `[-1, 1)` 균등. ⚠️ 상위 비트를 쓴다(강화판이라 어디를 써도 되지만 관례를 하나로 둔다).
	static float Unit(uint32 h) { return ((float)(h >> 8) / 8388608.0f) - 1.0f; }
	static uint32 Mod(uint32 h, uint32 n) { return (n == 0u) ? 0u : (h % n); }

	// ══════════════════════════════════════════════════════════════════
	// 🌍 한 에피소드 — `Reset` 뒤 `Step` 을 부른다. **상태는 여기가 굴린다.**
	// ══════════════════════════════════════════════════════════════════
	// ⭐ 회차 164 — **손잡이 둘을 런타임으로 노출**한다(기본값 = 지금 값 ⇒ 기존 호출 비트 동일).
	//   `dtMul`   : 카메라 적분 폭 배율(`kDt = 0.12` 에 곱한다) — ⭐ **카메라 몫**을 줄이는 유일한 손잡이
	//   `autoAmp` : 자율 도형 운동 진폭 배율(기본 0.8 에 곱한다)
	// ⚠️ 이것은 「세계를 바꾸는 것」이 아니라 「손잡이를 노출하는 것」이다 — 세계 선택은 사람 몫이다.
	void Reset(uint32 seedNo, uint32 episode, int holdTicks, int autoShapes,
	           float dtMul = 1.0f, float autoAmp = 1.0f)
	{
		_seedNo = seedNo; _epi = episode; _step = 0u;
		_dtMul = (dtMul > 0.0f) ? dtMul : 1.0f;
		_autoAmp = (autoAmp >= 0.0f) ? autoAmp : 1.0f;
		// ⚖️ 자기상태 채널 — ⚠️ `_energyOn` 은 **여기서 안 건드린다**(`Reset` 마다 끄면
		//   하네스가 에피소드마다 다시 켜야 하고, 한 번 빠뜨리면 **조용히** 옛 세계가 된다).
		//   ⚠️⚠️⚠️ **시작값을 1.0 으로 두면 안 된다** — 그러면 `E` 가 문맥 안에서 거의
		//     **「시각 `t`」의 함수**가 되고, 시각은 **이미 모델 입력**(위치 인코딩)이다
		//     ⇒ `Î` 가 커도 **조건부 MI 는 0** 이다(회차 142 가 밟은 함정의 새 얼굴).
		//   ⇒ ★ **주소의 해시로 흩뿌린다** — 문맥마다 시작점이 달라 시각과의 상관이 깨진다.
		//   ⚠️ `Hash` 는 순수 함수라 **스트림을 안 건드린다**(관문 ㉡ 의 그 규약 · 인덱스 5 는 미사용).
		_slowHits = 0u;
		_cutHits  = 0u;      // ✂️ 238 — 가지치기 발동 수도 에피소드마다 0 에서 시작한다
		// ⚖️⚖️ 264 — 몸의 서명도 에피소드마다 0 에서 시작한다(하네스가 에피소드 평균을 모은다)
		_biasHits = 0u; _pickN = 0u;      // ⭐ D71 — 분모도 에피소드마다 0 에서
		_fwSum = 0.0; _pwSum = 0.0; _fwLowSum = 0.0; _fwN = 0u; _fwLowN = 0u;
		_hold = (holdTicks < 1) ? 1 : holdTicks;
		_autoN = (autoShapes < 0) ? 0 : ((autoShapes > MLTWorldCfg::kShapes) ? MLTWorldCfg::kShapes : autoShapes);

		const uint32 a = Addr(_seedNo, _epi, 0u);
		_st.x     = Unit(Hash(a, MLTSalt::Start, 0u)) * 0.6f;
		_st.y     = Unit(Hash(a, MLTSalt::Start, 1u)) * 0.6f;
		_st.z     = Unit(Hash(a, MLTSalt::Start, 2u)) * 0.6f;
		_st.yaw   = Unit(Hash(a, MLTSalt::Start, 3u)) * 0.6f;
		_st.pitch = Unit(Hash(a, MLTSalt::Start, 4u)) * 0.6f;
		// ⚖️ 위 ⚠️⚠️⚠️ 의 그 자리 — `[0.15, 1.0)` 에 흩뿌린다(문턱 0.35 의 양쪽이 다 들어간다).
		_e = 0.15f + 0.85f * ((Unit(Hash(a, MLTSalt::Start, 5u)) + 1.0f) * 0.5f);
		_act = _PickAct(0u);
	}

	// ⚠️ 틱 규약: **apply → advance**. (render 는 부르는 쪽이 원할 때만 — ㉡ 관문의 그 이유)
	void Step()
	{
		// ── apply: 행동을 정한다. ★ **전환율**이 난이도다 — `_hold` 틱마다 새로 고른다.
		//   ⚠️ 「다시 뽑기」가 아니라 **주소를 옮기는 것**이다(스트림을 안 건드린다).
		if ((_step % (uint32)_hold) == 0u) _act = _PickAct(_step);
		_Advance();
	}

	// ══════════════════════════════════════════════════════════════════
	// ⭐ **P4 — 행동을 밖에서 준다**(개입 시험). `Step()` 과 `advance` 를 **공유**한다.
	// ══════════════════════════════════════════════════════════════════
	//   ⚠️ `_hold` 를 **건너뛴다** — 그것이 「개입」의 뜻이다(*"그 순간 다른 행동을 했다면"*).
	//   ⭐ 그래서 판정이 하나 공짜로 생긴다: `Step()` 이 고를 행동을 그대로 넣으면
	//     ***상태열이 비트 동일이어야 한다***(회차 77 의 판정 ① 이 그것이다).
	//   ⚠️⚠️ 이 함수는 **모델이 부르는 것이 아니다** — 생성기(하네스)가 준다. 모델이 행동을 내는 것은
	//     `P5` 이고 `mltconcept.md` 가 *"진짜 자기상태가 필요하다"* 로 미뤄 뒀다.
	void StepWith(const MLTAct& a) { _act = a; _Advance(); }

	// `Step()` 이 그 스텝에 고를 행동 — ⚠️ **`_hold` 규약을 포함한다**(하네스가 따라 하지 않게).
	MLTAct ActAt(uint32 step) const
	{
		return _PickAct(step - (step % (uint32)_hold));
	}

	const MLTState& State() const { return _st; }
	const MLTAct&   Act()   const { return _act; }
	uint32          StepNo() const { return _step; }
	uint32          Hold()  const { return (uint32)_hold; }
	float           DtMul() const { return _dtMul; }      // ⭐ 164
	float           AutoAmp() const { return _autoAmp; }  // ⭐ 164
	int             AutoN() const { return _autoN; }      // ⭐ 164 — 자율 낱말이 이것을 쓴다

	// ══════════════════════════════════════════════════════════════════
	// ⚖️ **자기상태 채널(에너지)** — ⚠️⚠️ **기본 꺼짐**. 켜는 것은 하네스다.
	// ══════════════════════════════════════════════════════════════════
	//   ⚠️⚠️ **끄고 돌리면 세계가 비트 동일**이다 — 회차 138~146 의 검산 사슬이 그것에 걸려 있다.
	//   ⭐ `Energy()` 는 **판정 창구가 아니다** — 하네스가 이것을 **모델 슬롯에 넣을 수 있다**
	//     (그것이 `VisibleShapes` 와 갈리는 지점이고, 「역사에서 오므로 라벨이 아니다」의 자리다).
	//   ⚠️ 그래도 **이름을 모델에 주지 않는다** — 슬롯에 놓는 것은 **불투명 스칼라 하나**다.
	// ══════════════════════════════════════════════════════════════════
	// ⭐ 회차 198 — **세계를 바꾼다**(`SetWorld2`) · ⚠️ 기본 0 = 옛 세계
	// ══════════════════════════════════════════════════════════════════
	//   ⚙️ **왜 바꾸나** — 회차 197 이 「여지 지도」를 냈다: 지금 방향을 알 때
	//     역사·위치·깊이·다른물체를 **전부 더해도 7.3%** 다 ⇒ ★ 이 세계는
	//     ***「직전 방향」이 거의 전부인 세계***다.
	//   ⇒ ⭐ **원인이 이 함수(`_ShapeWorld`)에 있다**:
	//     ㈀ 도형 14개 중 **`_autoN`(=3) 개만** 움직이고 나머지 11개는 **월드에서 정지**다
	//       ⇒ 그 11개의 화면 이동은 **전부 카메라(yaw/pitch/x/y/z)** 때문이다
	//     ㈁ 움직이는 3개도 **정현파**라 매끄럽다(꺾임이 없다)
	//     ⇒ ⇒ ★ 화면 방향 = **카메라의 공통 흐름** ⇒ 전 화면이 같은 방향으로 흐른다
	//       ⇒ 「직전 방향」이 다음 방향을 거의 완전히 예측한다
	//   ⇒ ⭐ 그리고 그것이 **회차 192 의 «상태 5축이 90%»** 와 정확히 같은 사실이다.
	//
	//   ⇒ ⭐ **처방**: 도형이 **자기 운동**을 갖고 그 운동이 ***관측 가능한 사건으로 꺾여야***
	//     한다. 모드 셋을 둔다(전부 **전 도형**이 움직인다 — 그것이 그 모드의 정의다):
	//     | 1 반사 | 등속 직선 + **상자 반사** ⇒ ★ 꺾임이 **위치**로 예측된다 |
	//     | 2 궤도 | 원점 둘레 회전 ⇒ ★ 방향이 **위치의 함수**(접선)다 |
	//     | 3 가속 | 등가속 ⇒ ★ 방향이 서서히 돌아 **역사(2점)** 가 필요하다 |
	//
	//   ⚠️⚠️⚠️ **무상태를 유지한다** — `_ShapeWorld` 는 `_step` 의 **함수**이고 하네스들이
	//     그것을 전제한다(`w.Reset(...)` 뒤 `Step()` 만으로 재현). ⇒ ★ 반사도 **닫힌 형태**
	//     (삼각파 되접기)로 쓴다 ⇒ 상태를 안 든다.
	//   ⚠️ 기본은 **0(옛 세계)** 이다 — 켜지 않으면 회차 1~197 이 **전부 그대로 돈다**.
	void   SetWorld2(int mode) { _w2 = (mode < 0) ? 0 : ((mode > 3) ? 3 : mode); }
	int    World2() const      { return _w2; }
	void   SetEnergy(bool on) { _energyOn = on; }
	// ⭐⭐ 회차 242 — **감쇠 세기가 손잡이다**(241 이 `kEnergySlow` 0.35 에서 활용률 2.54배를 냈는데
	//   ★ **그것이 격자의 끝**이라 최선인지 모른다 ⇒ 봉우리를 가둔다).
	//   ⚠️ 음수 = 기본값(`kEnergySlow` 0.35). 1.0 이면 **감쇠 없음**(에너지만 굴러간다).
	void   SetEnergySlow(float s) { _slowOv = s; }
	float  EnergySlow() const     { return (_slowOv >= 0.0f) ? _slowOv : MLTWorldCfg::kEnergySlow; }
	bool   EnergyOn() const   { return _energyOn; }
	float  Energy()   const   { return _e; }
	// ✂️ **가지치기**(회차 238) — ⚠️ **기본 꺼짐** · 켜려면 `SetEnergy(true)` 도 켜야 뜻이 있다
	//   (예산이 `_e` 인데 에너지가 안 굴러가면 `_e` 가 시작값에 고정된다)
	void   SetPrune(bool on)  { _pruneOn = on; }
	bool   PruneOn() const    { return _pruneOn; }
	// ⭐ 239 — **예산 손잡이**(음수 = 기본 `kPruneBudget` 1.25). ⚠️ 0.15 아래로 내리지 마라(정지 세계).
	void   SetPruneBudget(float b) { _prBudget = b; }
	float  PruneBudget() const     { return (_prBudget >= 0.0f) ? _prBudget : MLTWorldCfg::kPruneBudget; }
	// ⭐ 238 — **잘린 축의 수**(가지치기가 실제로 발동했나 = 배관 관문)
	uint32 CutHits() const    { return _cutHits; }
	// ⭐ 서명용 — 「기능적 결과가 실제로 발동했나」(0 이면 ㈂ 가 죽은 것이다 · 규율 21)
	uint32 SlowHits() const   { return _slowHits; }

	// ══════════════════════════════════════════════════════════════════
	// ⚖️⚖️ **몸**(회차 264) — ⚠️⚠️ **기본 꺼짐** · `SetEnergy(true)` 도 켜야 뜻이 있다
	//   (이득이 `_e` 에 실리는데 에너지가 안 굴러가면 아무 일도 안 일어난다)
	// ══════════════════════════════════════════════════════════════════
	//   ⚠️⚠️⚠️ **꺼져 있으면 상태를 한 비트도 안 건드린다** — 회차 1~263 이 비트 동일이다
	//     (`_energyOn`·`_pruneOn` 과 **같은 규약**).
	//   ⭐⭐ **부분을 따로 켤 수 있다** — 컨셉이 요구한 팔 다섯 중 넷째·다섯째가 그것이다:
	//     ***「값은 주고 기능적 결과 없음」(이득만) ↔ 「값 + 결과 있음」(닫힘)***.
	//   ⇒ ★ 그 둘의 차가 **조건 넷의 ㈂·㈃** 를 직접 가른다.
	void   SetBody(bool on) { _bodyOn = on; _bodyRefl = on; _bodySig = on; }
	void   SetBodyParts(bool gainOn, bool reflexOn) { _bodyOn = gainOn; _bodyRefl = reflexOn; }
	// ⭐⭐ **서명만** 켠다 — ⚠️ 몸이 **꺼진 팔에서도 먹이 가중을 재야** 기준선이 생긴다
	//   (ML 규율 74: *"무작위 기준선도 자리마다 직접 재라"* — 빌리면 부호까지 뒤집힌다).
	//   ⚠️ 이것은 상태를 **한 비트도 안 바꾼다**(누적기만 채운다) ⇒ 켜도 세계가 비트 동일이다.
	void   SetBodySig(bool on) { _bodySig = on; }
	bool   BodyOn() const     { return _bodyOn; }
	bool   BodyReflex() const { return _bodyRefl; }
	// ⭐ 서명 ㉡ — **반사가 실제로 발동했나**(0 이면 닫힘이 죽은 것이다)
	uint32 BiasHits() const { return _biasHits; }
	// ⭐⭐ 📌 **D71** — 그 **분모**. ★ 자는 `BiasHits() ÷ PickCount()` 로 적는다
	//   ⚠️ **문턱은 여기서 정하지 않는다** — 265 의 수에서 역산한 「0.25」가 무효였다(ML 규율 74)
	//     ⇒ 🧾 ***문턱은 그 세계에서 뽑는다.***
	uint32 PickCount() const { return _pickN; }
	// ⭐⭐ 서명 ㉢ — 「`_e` 가 낮을 때 먹이 가중이 높은가」= ***폐회로의 직접 증거***
	//   ⚠️ 낮을 때가 더 **작으면** 반사의 부호가 틀린 것이다 ⇒ 그것을 이 자로 잡는다.
	double FoodWMean() const    { return (_fwN    == 0u) ? 0.0 : _fwSum    / (double)_fwN; }
	double FoodWMeanLow() const { return (_fwLowN == 0u) ? 0.0 : _fwLowSum / (double)_fwLowN; }
	double PoisWMean() const    { return (_fwN    == 0u) ? 0.0 : _pwSum    / (double)_fwN; }
	uint32 FoodWN() const       { return _fwN; }
	uint32 FoodWLowN() const    { return _fwLowN; }

	// ══════════════════════════════════════════════════════════════════
	// 🖼️ 프레임 — 손으로 쓴 투영. ⚠️⚠️ **난수를 한 번도 안 뽑는다**(관문 ㉡ 의 그 이유).
	//   도형의 자리·종류·색은 전부 **주소의 함수**이므로 여기서 스트림이 안 움직인다.
	// ══════════════════════════════════════════════════════════════════
	// ★ **지금 상태에서 화면에 드는 도형들** — 먼 것부터(그리는 순서 그대로).
	//   ⚠️ 이것이 **`Render` 가 그리는 목록 그 자체**다. 같은 사실을 두 곳에 두지 않으려고
	//     `Render` 가 이 함수를 부른다 — 갈리면 판정이 화면과 다른 것을 보게 된다.
	//   ⚠️⚠️ 위 `MLTShapeView` 의 경고를 그대로 물려받는다: **판정자 전용**이다.
	int VisibleShapes(MLTShapeView* out, int cap) const
	{
		if (out == nullptr || cap <= 0) return 0;
		const int S = MLTWorldCfg::kSide;
		int n = 0;
		for (int i = 0; i < MLTWorldCfg::kShapes && n < cap; ++i)
		{
			float wx, wy, wz; _ShapeWorld(i, wx, wy, wz);
			float sx, sy, d;
			if (!_Project(wx, wy, wz, sx, sy, d)) continue;
			const uint32 a = Addr(_seedNo, _epi, 0u) + (uint32)i * 131u;
			out[n].index = i;
			out[n].sx = sx; out[n].sy = sy;
			out[n].r  = (1.25f / d) * (float)S * 0.5f;   // ⚠️ 0.42 → 0.95 → 1.25(아스키로 보고 두 번 키웠다)
			out[n].kind = (int)Mod(Hash(a, MLTSalt::ShapeKind, (uint32)i), 3u);
			out[n].col  = Mod(Hash(a, MLTSalt::ShapeCol, (uint32)i), 5u);
			out[n].d = d;
			++n;
		}
		for (int p = 0; p < n; ++p)      // 먼 것 먼저(삽입 정렬 — n 이 작다)
			for (int q = p + 1; q < n; ++q)
				if (out[q].d > out[p].d) { const MLTShapeView t = out[p]; out[p] = out[q]; out[q] = t; }
		return n;
	}

	bool Render(ImageFormat::Bitmap& canvas) const
	{
		const int S = MLTWorldCfg::kSide;
		if (canvas.width != (uint32)S || canvas.height != (uint32)S)
		{
			if (!ImageFormat::CreateRGBA8(canvas, (uint32)S, (uint32)S)) return false;
		}
		// ⚠️ 배경은 **검정이 아니다** — RGB332 에 바이트 0 이 없어서 검정이 1 로 밀리고,
		//   그러면 「배경」이 다른 색과 한 칸 차이가 되어 판독이 흐려진다. 어두운 회색으로 둔다.
		ImageFormat::Fill(canvas, Vector4(48.0f / 255.0f, 48.0f / 255.0f, 56.0f / 255.0f, 1.0f));

		// 먼 것부터 그린다(깊이 버퍼가 없어 **덮어쓰기**가 유일한 정렬이다).
		MLTShapeView it[MLTWorldCfg::kShapes];
		const int n = VisibleShapes(it, MLTWorldCfg::kShapes);

		for (int i = 0; i < n; ++i)
		{
			const Vector4 c = _Palette(it[i].col);
			const float r = it[i].r;
			if (r < 1.0f) continue;
			if (it[i].kind == 0)      ImageFormat::FillCircle(canvas, it[i].sx, it[i].sy, r, c);
			else if (it[i].kind == 1) ImageFormat::FillRect(canvas, (int32)(it[i].sx - r), (int32)(it[i].sy - r),
			                                                (int32)(r * 2.0f), (int32)(r * 2.0f), c);
			// ⚠️ 빈 것은 **두께 상수**가 필요하다 — 1.5 미만이면 큰 반지름에서 테두리에 구멍이 생긴다.
			else                      ImageFormat::DrawCircle(canvas, it[i].sx, it[i].sy, r, MLTWorldCfg::kStroke, c);
		}
		return true;
	}

	// 프레임을 **모델의 알파벳**(RGB332 1픽셀 1바이트)으로. `prev == nullptr` 이면 키프레임.
	//   ⚠️⚠️ 그 바이트에 **0 이 없다**(0 은 「안 바뀜」 예약) ⇒ 배경을 `== 0` 으로 찾으면 못 찾는다.
	static bool Pack(const ImageFormat::Bitmap& cur, const ImageFormat::Bitmap* prev, Bytes& out)
	{
		out.Reset((uint64)MLTWorldCfg::kPixels);
		return ImageFormat::PackRGB332Delta(cur, prev, (uint8*)out.GetData(), out.GetSize());
	}

private:
	uint32 _seedNo = 0u, _epi = 0u, _step = 0u;
	// ⚖️ 자기상태 채널 — ⚠️ `_energyOn` 기본 `false` ⇒ **세계가 옛것과 비트 동일**이다.
	bool  _energyOn = false;
	float _e = 1.0f;
	// ✂️ 238 — 가지치기. ⚠️ **기본 꺼짐** ⇒ 회차 1~237 이 비트 동일이다(`_energyOn` 과 같은 규약).
	bool  _pruneOn = false;
	float _prBudget = -1.0f;      // ⭐ 239 — 음수 = 기본값(`kPruneBudget`)
	float _slowOv   = -1.0f;      // ⭐ 242 — 감쇠 세기(음수 = 기본 `kEnergySlow` 0.35)
	// ⚠️ `mutable` 인 근거: `_PickAct` 가 `const` 인데(그 계약은 `ActAt` 이 요구한다) 발동 횟수를
	//   세야 한다. ★ 이 값은 **판정 창구**이지 세계 상태가 아니다 — `_Advance` 가 이것을 안 읽는다.
	mutable uint32 _cutHits = 0u;
	uint32 _slowHits = 0u;
	// ⚖️⚖️ 264 — **몸**. ⚠️ 기본 꺼짐이므로 옛 회차가 비트 동일이다.
	bool   _bodyOn = false;             // 이득이 세계의 함수인가
	bool   _bodyRefl = false;           // 반사가 도는가(⭐ 컨셉의 팔 넷째 ↔ 다섯째를 가른다)
	bool   _bodySig  = false;           // ⭐ 서명만(몸 꺼진 팔의 **기준선** · 상태를 안 바꾼다)
	mutable uint32 _biasHits = 0u;      // ⚠️ `_PickAct` 가 `const` 다(`_cutHits` 와 같은 근거)
	// ⭐⭐ 📌 **D71**(회차 267) — **`_PickAct` 가 몇 번 불렸나**.
	//   ⛔⛔ 근거: 265 가 반사를 **6.3/에피**로 찍었는데 손계산 상한이 **4.4** 였다
	//     (`kUMax` 16 ⇒ 17 시각 ÷ `hold` 5 + `Reset` 1) ⇒ `_FillA` 의 **반사실 `ActAt` 호출**까지 셌다.
	//   ⚠️⚠️ **237 이 `_cutHits` 에서 전수 조사한 그 병**이다(*"`ActAt(과거 걸음)` 은 무상태가 아니다"*).
	//   ⇒ 🧾 ★ **발동 수를 이 수로 나눠야 하네스가 달라도 견줄 수 있다**
	//     (`_cutHits`·`_slowHits` 도 같은 대가를 진다 — 그쪽은 옛 결론이 걸려 있어 **자를 안 바꾼다**).
	mutable uint32 _pickN = 0u;
	// ⭐ 서명 누적기 — **판정 창구**이지 세계 상태가 아니다(`_Advance` 가 이것을 안 읽는다)
	double _fwSum = 0.0, _pwSum = 0.0, _fwLowSum = 0.0;
	uint32 _fwN = 0u, _fwLowN = 0u;
	int _hold = 1, _autoN = 0;
	// ⭐ 회차 198 — 세계 모드(0 = 옛 세계 · 1 반사 · 2 궤도 · 3 가속) · ⚠️ `Reset` 이 안 건드린다
	//   ★ 그래야 `SetWorld2` 를 한 번 걸고 `Reset` 을 여러 번 부르는 하네스 관용구가 성립한다
	//     (`SetEnergy` 와 같은 자리 · 같은 규약).
	int _w2 = 0;
	// ⭐ 회차 164 — 기본값이 1.0 이라 **여태의 세계와 비트 동일**하다
	float _dtMul = 1.0f, _autoAmp = 1.0f;
	MLTState _st;
	MLTAct   _act;

	// ⚠️ **반사**(clamp 가 아니다) — clamp 는 복사 베이스라인의 구원이라 지수의 부호를 뒤집는다.
	static float _Reflect(float v)
	{
		const float B = MLTWorldCfg::kBound;
		for (int guard = 0; guard < 4; ++guard)   // 한 틱에 여러 번 튕길 수 있다
		{
			if (v > B)  { v = 2.0f * B - v; continue; }
			if (v < -B) { v = -2.0f * B - v; continue; }
			break;
		}
		return v;
	}

	// ══════════════════════════════════════════════════════════════════
	// ⚖️⚖️ **몸의 가중**(회차 264) — ⭐ **계산식을 한 곳에만 둔다**(규율 16)
	//   `_Advance` 의 **이득**과 `_PickAct` 의 **반사**가 이 한 함수를 공유한다.
	//   ⚠️ 두 벌로 두면 반드시 갈린다(규율 16 이 `_nw` 에서 실측한 그 병).
	// ══════════════════════════════════════════════════════════════════
	//   가중 = **겉보기 크기 × 중앙에 가까움**. ⚠️ 「크기만」으로 두지 않은 근거:
	//     ㈀ 반사는 `dYaw` 만 쓸 수 있다(아래 `_PickAct` 의 🧮 절) ⇒ 크기만이면 **반사가 그것을
	//        못 올린다** ⇒ ㈃ **닫힘이 안 선다**.
	//     ㈁ 중앙에 가까움을 곱하면 **반사가 직접 그것을 올린다** ⇒ 🧾 ***닫힘이 구성으로 보장된다.***
	//   ⚠️ 이것은 **판정 창구가 아니다** — `_e` 의 증분에만 쓰이고 모델은 `_e` 만 본다.
	//     ★ 그리고 `_e` 는 여전히 **누적기**다(지금 프레임의 함수가 아니다) ⇒ 「역사에서 온다」.
	void _BodyWeights(float& foodW, float& poisW, float& bestEx, bool& hasFood) const
	{
		foodW = 0.0f; poisW = 0.0f; bestEx = 0.0f; hasFood = false;
		MLTShapeView it[MLTWorldCfg::kShapes];
		const int n = VisibleShapes(it, MLTWorldCfg::kShapes);
		const float half = (float)MLTWorldCfg::kSide * 0.5f;
		float bestW = 0.0f;
		for (int i = 0; i < n; ++i)
		{
			const float ex  = (it[i].sx - half) / half;      // −1 .. 1 (0 = 화면 중앙)
			const float ctr = 1.0f - Abs(ex);
			if (ctr <= 0.0f) continue;                        // 화면 밖은 안 센다
			const float w = (it[i].r / half) * ctr;
			if (it[i].kind == MLTWorldCfg::kBodyFoodKind)
			{
				foodW += w;
				if (w > bestW) { bestW = w; bestEx = ex; hasFood = true; }
			}
			else if (it[i].kind == MLTWorldCfg::kBodyPoisKind) poisW += w;
		}
	}

	// ── advance: 상태를 굴린다. `state[t+1] = f(state[t], v[t])`
	//   ★ 전후진은 **시선 방향**으로 간다(그래서 yaw 가 위치에 실제로 관여한다 = 축이 얽힌다).
	//   ⚠️ `Step()` 과 `StepWith()` 가 **이 한 함수를 공유한다** — 두 벌로 두면 반드시 갈린다.
	void _Advance()
	{
		const float sy = Sin(_st.yaw * 3.14159265f), cy = Cos(_st.yaw * 3.14159265f);
		const float dt = MLTWorldCfg::kDt * _dtMul;   // ⭐ 164
		// ══════════════════════════════════════════════════════════════
		// ⚖️ **자기상태 채널(에너지)** — ⚠️⚠️ **기본 꺼짐**(`SetEnergy(true)` 로만 켠다)
		// ══════════════════════════════════════════════════════════════
		//   ★ `mltconcept.md` 「⚖️ 부호 있는 자기 입력 채널이 최소 하나」 절이 요구한 **조건 넷**:
		//     ㈀ **내생적** — 값이 **자기 행동**에서 나온다(교사가 주지 않는다)
		//     ㈁ **지속**   — **누적기**다(프레임의 함수가 아니다 ⇒ 「역사에서 온다」 = 라벨이 아니다)
		//     ㈂ **기능적 결과** — 낮으면 **실제로 느려진다**(`sc`)
		//     ㈃ **닫힘**   — 느려지면 **덜 쓰므로 회복한다** ⇒ 그 선택이 다시 값을 바꾼다
		//   ⚠️⚠️ **이름을 코드에 안 심는다** — 모델에게 이것이 「통증」이라고 말하지 않는다.
		//     하네스가 슬롯에 **불투명 스칼라 하나**로 놓고 모델이 알아내게 한다(매핑 금지).
		//   ⚠️⚠️⚠️ **꺼져 있으면 이 블록이 상태를 한 비트도 안 건드린다** — 회차 138~146 의
		//     검산 사슬(141↔144 0.0136 · 142↔143 0.0000 · 144↔145 0.006 · 145↔146 0.009)이
		//     그것에 걸려 있다. ★ 새 회차만 켠다(`-validation`·`-perf` 와 같은 관용구).
		float sc = 1.0f;
		if (_energyOn)
		{
			typedef MLTWorldCfg C;
			const float mag = Abs(_act.fwd) + Abs(_act.up) + Abs(_act.side)
			                + Abs(_act.dYaw) + Abs(_act.dPitch);
			// ⭐ 242 — 감쇠 세기는 손잡이다(음수면 기본 `kEnergySlow`)
			if (_e < C::kEnergyLow) { sc = (_slowOv >= 0.0f) ? _slowOv : C::kEnergySlow; ++_slowHits; }
			// ⚖️⚖️ 264 — **이득이 세계의 함수가 된다**(몸). ⚠️ 꺼져 있으면 `gain` 이 상수 그대로라
			//   식이 옛것과 **비트 동일**하다(같은 값 · 같은 연산 순서).
			float gain = C::kEnergyGain;
			// ⚠️⚠️ **서명은 몸과 따로 켠다**(`_bodySig`) — 안 그러면 ***몸 끔 팔에서 먹이 가중이
			//   0 이라 대조가 안 된다***(기준선을 못 잰다 ⇒ 그것이 ML 규율 74 가 경고한 그 병이다).
			if (_bodyOn || _bodySig)
			{
				float fw, pw, ex; bool hf;
				_BodyWeights(fw, pw, ex, hf);
				if (_bodyOn)
				{
					float m = 1.0f + C::kBodyAmp * (fw - pw);
					if (m < 0.0f) m = 0.0f;
					if (m > 2.0f) m = 2.0f;
					gain = C::kEnergyGain * m;
				}
				// ⭐ 서명 — 성능보다 **먼저** 읽는 것들(공용 규율 1)
				_fwSum += (double)fw; _pwSum += (double)pw; ++_fwN;
				if (_e < C::kEnergyLow) { _fwLowSum += (double)fw; ++_fwLowN; }
			}
			// ⭐ 소모는 **실제로 움직인 만큼**(`sc` 를 곱한다) — 그것이 ㈃ 닫힘이다.
			_e += (gain - C::kEnergyDrain * mag * sc) * dt;
			if (_e > 1.0f) _e = 1.0f;
			if (_e < 0.0f) _e = 0.0f;
		}
		_st.x = _Reflect(_st.x + (_act.fwd * sy + _act.side * cy) * dt * sc);
		_st.z = _Reflect(_st.z + (_act.fwd * cy - _act.side * sy) * dt * sc);
		_st.y = _Reflect(_st.y + _act.up * dt * sc);
		_st.yaw   = _Reflect(_st.yaw   + _act.dYaw   * dt * sc);
		_st.pitch = _Reflect(_st.pitch + _act.dPitch * dt * sc);
		++_step;
	}

	MLTAct _PickAct(uint32 step) const
	{
		++_pickN;                      // ⭐ 📌 D71 — 발동 수의 **분모**(호출 경로를 안 가리는 대신 센다)
		const uint32 a = Addr(_seedNo, _epi, step);
		MLTAct v;
		v.fwd    = Unit(Hash(a, MLTSalt::Act, 0u));
		v.up     = Unit(Hash(a, MLTSalt::Act, 1u)) * 0.5f;
		v.side   = Unit(Hash(a, MLTSalt::Act, 2u)) * 0.7f;
		v.dYaw   = Unit(Hash(a, MLTSalt::Act, 3u)) * 0.6f;
		v.dPitch = Unit(Hash(a, MLTSalt::Act, 4u)) * 0.4f;
		// ══════════════════════════════════════════════════════════════
		// ⚖️⚖️ **반사**(회차 264 · 몸) — ⚠️⚠️ **기본 꺼짐** · **가지치기보다 앞**에 둔다
		//   (뒤에 두면 가지치기가 편향을 먼저 잘라 닫힘이 안 선다)
		// ══════════════════════════════════════════════════════════════
		//   ★ 에너지가 낮으면 **가장 크게·가운데 보이는 먹이 쪽으로 yaw 를 돌린다.**
		//   🧮 **부호를 손으로 유도했다**(규율 21) — `_Project` 가 `ang = −yaw·π` 로 돌리므로
		//     `d(cx)/d(yaw) = +π·cz > 0` ⇒ ***yaw 를 키우면 화면에서 오른쪽으로 간다***
		//     ⇒ 오른쪽(`ex > 0`)에 있는 것을 가운데로 데려오려면 **`dYaw` 가 음수**여야 한다.
		//   ⚠️ **`fwd` 는 안 건드린다** — 축 배율(1.4/1.0/0.8) 때문에 깊이 효과의 부호가 yaw 에
		//     따라 뒤집힌다(`Δcz = fwd·dt·(1.4·sin² − 0.8·cos²)`)
		//     ⇒ 🧾 ***「전진 = 가까워짐」이 이 세계에선 거짓이다*** ⇒ 전진을 반사로 못 쓴다.
		//   ⚠️⚠️ 이것은 **몸의 반사**이고 모델의 정책이 아니다 — 모델의 출력과 무관하다
		//     ⇒ 코퍼스가 모델에 의존하지 않는다 ⇒ ★ **`P5` 가 아니고 검산 사슬이 안 깨진다.**
		//   ⚠️ 그리고 `_pruneOn` 과 **같은 대가**를 진다 — 이 함수가 `_e` 를 현재 값으로 읽으므로
		//     `ActAt(과거 걸음)` 이 무상태가 아니게 된다(237 의 그 전수 조사) ⇒ 손잡이로만 켠다.
		if (_bodyRefl && _energyOn && _e < MLTWorldCfg::kEnergyLow)
		{
			float fw, pw, ex; bool hf;
			_BodyWeights(fw, pw, ex, hf);
			if (hf)
			{
				v.dYaw = (ex > 0.0f) ? -MLTWorldCfg::kBodyBias : MLTWorldCfg::kBodyBias;
				++_biasHits;
			}
		}
		// ✂️ **가지치기** — ⚠️⚠️ **기본 꺼짐**(위 `kActCost` 절의 그 근거)
		//   ★ 비싼 축부터 예산(`_e × kPruneBudget`)을 태우고 **못 내는 축은 0** 이 된다.
		//   ⚠️⚠️ 이 함수는 `const` 이고 `_e` 를 **현재 값으로** 읽는다 ⇒ ***`ActAt` 이 무상태가 아니게 된다.***
		//     ⇒ ★ 237 이 호출부를 전수 조사했다: `ActAt(StepNo())`(현재 걸음)는 안전하고
		//       `ActAt(kTime-1)`(`mltl0a*`·`b0`·`c0`)과 `wa.ActAt(t)`(`mltp4d0`·`h0`·`i0`)는 **과거/남의 걸음**이다.
		//     ⇒ ⇒ ⚠️ **그래서 손잡이로 켠다** — 꺼져 있으면 이 블록이 한 비트도 안 건드린다.
		if (_pruneOn)
		{
			typedef MLTWorldCfg C;
			// ⭐ 239 — 예산은 손잡이다(`SetPruneBudget`). 음수면 기본값(`kPruneBudget`)을 쓴다.
			float budget = _e * ((_prBudget >= 0.0f) ? _prBudget : C::kPruneBudget);
			// ⚠️ 비싼 축부터(비용 내림차순) — 축 순서 fwd·up·side 가 1.00, dYaw·dPitch 가 0.30
			//   ★ 같은 비용 안에서는 **축 번호 순**이다(설계자가 선호를 안 넣는다 — 정책 금지).
			static const uint32 order[5] = { 0u, 1u, 2u, 3u, 4u };
			for (uint32 k = 0; k < 5u; ++k)
			{
				const uint32 i = order[k];
				const float need = Abs(v.Axis((int)i)) * C::kActCost[i];
				if (need <= budget) { budget -= need; continue; }
				// 못 산다 ⇒ **그 축을 0 으로**(깎지 않는다 — 깎으면 그것이 감쇠다)
				if (need > 1.0e-9f) ++_cutHits;      // ⭐ 배관 관문 — 실제로 잘렸나
				switch (i)
				{
					case 0: v.fwd = 0.0f; break;
					case 1: v.up = 0.0f; break;
					case 2: v.side = 0.0f; break;
					case 3: v.dYaw = 0.0f; break;
					default: v.dPitch = 0.0f; break;
				}
			}
		}
		return v;
	}

	// 도형의 세계 자리. ⚠️ **자율 도형**은 스텝의 함수로 움직인다 — 그래서 그 변화는
	//   **내 행동과 무관**하다(⑨ 의 그 이유: 없으면 「모든 변화 = 내 행동」을 정답으로 준 세계다).
	void _ShapeWorld(int i, float& wx, float& wy, float& wz) const
	{
		const uint32 a = Addr(_seedNo, _epi, 0u) + (uint32)i * 131u;
		// ⚠️⚠️ **도형을 원점 둘레의 「고리」에 놓는다** — 앞쪽 상자에 놓았다가 **프레임이 98% 비는** 것을
		//   두 번 밟았다. 원인이 둘이었다: ㈀ `yaw` 가 ±π 까지 도니 **절반은 카메라 뒤**로 가고
		//   ㈁ 초점 1.2 면 `|cx/cz| < 0.83` 만 화면 안인데 옆으로 벌린 상자는 그것을 훌쩍 넘는다.
		//   ★ 고리면 **어느 방향을 봐도 시야각(≈80°) 안에 몇 개가 들어온다** ⇒ 프레임이 안 빈다.
		//   ⚠️ 그리고 이것이 세계를 더 정직하게 만든다 — `yaw` 를 돌리는 것이 **실제로 다른 것을 보게** 한다.
		const uint32 hA = Hash(a, MLTSalt::ShapePos, 0u);
		const float ang = ((float)i / (float)MLTWorldCfg::kShapes) * 6.2831853f
			+ Unit(hA) * 0.35f;                                   // 고르게 벌리고 살짝 흔든다
		const float rad = 3.2f + Unit(Hash(a, MLTSalt::ShapePos, 2u)) * 0.5f;
		wx = Sin(ang) * rad;
		wz = Cos(ang) * rad;
		wy = Unit(Hash(a, MLTSalt::ShapePos, 1u)) * 0.7f;
		// ⭐ 회차 198 — 새 세계 셋(위 `SetWorld2` 의 그 근거). ⚠️ **전 도형이 움직인다.**
		if (_w2 != 0)
		{
			const float t   = (float)_step * 0.17f;
			const float amp = 0.8f * _autoAmp;
			// 물체마다 다른 속도/방향(⚠️ 해시로 뽑아 **무상태**를 유지한다)
			const float ux = Unit(Hash(a, MLTSalt::AutoVel, 0u));
			const float uz = Unit(Hash(a, MLTSalt::AutoVel, 1u));
			if (_w2 == 1)
			{
				// ── 1 반사 — 등속 직선 + **상자 되접기**(삼각파). ★ 꺾임이 **위치**로 예측된다.
				//   ⚠️ 닫힌 형태로 쓴다: `u` 를 주기 `4L` 로 접어 `[-L, L]` 삼각파로 만든다.
				wx += _Fold(ux * t * 2.0f, amp);
				wz += _Fold(uz * t * 2.0f, amp);
			}
			else if (_w2 == 2)
			{
				// ── 2 궤도 — 원점 둘레 회전. ★ 방향이 **위치의 함수**(접선)다.
				//   ⚠️ 고리 반경을 유지하고 **각속도**만 물체마다 다르게 한다.
				const float w = 0.35f + 0.5f * (ux * 0.5f + 0.5f);
				const float ang2 = ang + w * t;
				wx = Sin(ang2) * rad;
				wz = Cos(ang2) * rad;
			}
			else
			{
				// ── 3 가속 — 등가속. ★ 방향이 서서히 돌아 **역사(2점)** 가 필요하다.
				//   ⚠️ 발산을 막으려고 위치를 되접는다(반사와 같은 이유).
				const float v0x = ux * 0.6f, v0z = uz * 0.6f;
				const float axx = -uz * 0.30f, azz = ux * 0.30f;   // 속도에 수직 ⇒ 곡선 궤적
				wx += _Fold(v0x * t + 0.5f * axx * t * t, amp * 1.5f);
				wz += _Fold(v0z * t + 0.5f * azz * t * t, amp * 1.5f);
			}
			return;
		}
		if (i < _autoN)
		{
			const float ph = (float)_step * 0.17f + (float)i;
			// ⭐ 164 — 진폭/반경 ≈ 0.22 였고 그것이 「패치 id 를 못 바꾼다」의 원인이다(회차 163)
			const float amp = 0.8f * _autoAmp;
			wx += Sin(ph) * amp * Unit(Hash(a, MLTSalt::AutoVel, 0u));
			wz += Cos(ph) * amp * Unit(Hash(a, MLTSalt::AutoVel, 1u));
		}
	}

	// ⭐ `u` 를 `[-L, L]` 로 **되접는다**(삼각파) — ★ 이것이 「상자 반사」의 닫힌 형태다.
	//   ⚠️ 상태를 안 들므로 `_ShapeWorld` 의 무상태 규약을 깨지 않는다.
	static float _Fold(float u, float L)
	{
		if (L <= 0.0f) return 0.0f;
		const float P = 4.0f * L;
		float m = u + L;
		m = m - P * Floor(m / P);          // [0, 4L)
		if (m > 2.0f * L) m = P - m;       // 되접기 ⇒ [0, 2L]
		return m - L;                      // [-L, L]
	}

	// 핀홀 투영 — ⚠️ 이 셋(초점·near·화면 사상)이 「못」의 상수다.
	bool _Project(float wx, float wy, float wz, float& sx, float& sy, float& d) const
	{
		// 카메라 기준으로 옮긴다(위치를 빼고 yaw 로 돌린다 · pitch 는 화면 y 를 밀어 준다).
		const float rx = wx - _st.x * 1.4f;
		const float ry = wy - _st.y * 1.0f;
		const float rz = wz - _st.z * 0.8f;   // ⚠️ 기여를 줄였다(도형이 near 뒤로 안 잘리게)
		const float ang = -_st.yaw * 3.14159265f;
		const float s = Sin(ang), c = Cos(ang);
		const float cx = rx * c - rz * s;
		const float cz = rx * s + rz * c;
		if (cz < MLTWorldCfg::kNear || cz > MLTWorldCfg::kFar) return false;
		d = cz;
		const float half = (float)MLTWorldCfg::kSide * 0.5f;
		sx = half + (cx / cz) * MLTWorldCfg::kFocal * half;
		sy = half - (ry / cz) * MLTWorldCfg::kFocal * half - _st.pitch * half * 0.5f;
		return true;
	}

	// ⚠️ 팔레트는 **작게**(배경과 충분히 다른 것만) — RGB332 는 상위 3비트만 남으므로
	//   가까운 색끼리는 **같은 바이트가 된다**.
	static Vector4 _Palette(uint32 k)
	{
		switch (k)
		{
			case 0:  return Vector4(224.0f / 255.0f,  32.0f / 255.0f,  32.0f / 255.0f, 1.0f);   // 붉은
			case 1:  return Vector4( 32.0f / 255.0f, 224.0f / 255.0f,  32.0f / 255.0f, 1.0f);   // 푸른(초록)
			case 2:  return Vector4( 64.0f / 255.0f,  96.0f / 255.0f, 224.0f / 255.0f, 1.0f);   // 파란
			case 3:  return Vector4(224.0f / 255.0f, 224.0f / 255.0f,  32.0f / 255.0f, 1.0f);   // 노란
			default: return Vector4(224.0f / 255.0f, 224.0f / 255.0f, 224.0f / 255.0f, 1.0f);   // 흰
		}
	}
};
