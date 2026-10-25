// mltp2k.cw — 🎚️👁️ **P2 걸음 4 · `k` 스윕**(활성 개수). 회차 21 의 ⛔ 가 가리킨 축이다.
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문** — ⚠️ 재기 **전에** 적는다. (걸음 4 의 등록은 `mltp2run.cw` 꼬리에서 시작했다)
// ══════════════════════════════════════════════════════════════════════════════
//
// ① **왜 `k` 인가** — 회차 21 이 준 수 둘이 같은 곳을 가리킨다:
//    · 사용률 **35.1** ≪ rank **151.8** ⇒ 쓰인 유닛이 시험 패치의 부분공간을 **못 펼친다**
//      (오차 0 이 **원리적으로** 불가하다).
//    · `N` 은 이미 **1000** 인데 **35개만** 쓰인다 ⇒ `N` 을 늘리면 **죽은 유닛만 는다.**
//    ★ 그리고 `k` 는 **패치 하나가 펼칠 수 있는 부분공간의 차원**을 곧바로 올린다.
//    ⇒ 팔 셋 **`k ∈ {8, 16, 32}`** · `N` = 1000 **고정**. ⚠️ 한 회차에 축 둘을 흔들지 않는다.
//
//    ⚠️⚠️ **등록을 고쳤다(회차 23) — 조용히 바꾸지 않는다.** 처음 등록은 **{8, 32, 128}** 이었고
//      팔 둘(8·32)까지 돌린 뒤 고쳤다. 근거를 **둘** 적는다(값 하나에 기대지 않는다):
//      ㉠ ⭐ **`k=128` 은 결과가 나와도 우리가 할인해야 하는 자리였다** — `k·패치/N = 8.19` 이고
//         원래 등록문 ③ 의 ⚠️ 가 이미 *"그것은 「사전에서 고른다」가 아니라 **다 쓴다**"* 라고
//         적어 두었다. ⇒ **흔들 값어치가 있는 구간은 희소성 경계 근처**다:
//         `k·패치/N` = **0.51**(k=8) · **1.02**(k=16 ⇐ 경계 그 자리) · **2.05**(k=32).
//         ★ 그러면 스윕이 **경계를 걸치므로** *"희소성을 버려야 좋아지나"* 를 곧바로 묻는다.
//      ㉡ 값 — `k=128` 은 한 프레임 2273ms · 팔 하나 **68분**이고 GPU 를 100% 로 물어
//         **사람이 기계를 못 쓴다**(실측). ⚠️ 값만으로는 등록을 고치는 근거가 약하므로 ㉠ 이 먼저다.
//      ⚠️⚠️ **잃는 것을 적는다**: *"`k` 를 아주 크게 하면 계속 좋아지나"* = **용량 가설의 강한 형태**를
//         못 본다. 필요해지면 **그때 별도로 등록한다**(값이 68분이라는 것도 같이 적는다).
//         ★ 그리고 그래서 아래 ㈁ 의 문구를 **「이 구간에서 단조」**로 고쳤다 — 전역 용량이라고
//           말할 수 없다(k=128 을 안 봤다). 그 자리를 얼버무리면 다음 사람이 과하게 읽는다.
//
// ② **관문은 회차 21 것을 글자 그대로 다시 쓴다** — ⚠️ **고치지 않는다.**
//    · ㉠-표제 `MSE_시험 < 0.01710` · ㉠-부호검정 **10/12**(씨앗마다 자기 패치상수 대조군의 절반).
//    · 과제도 같다: 학습 프레임 0~31 · 시험 **뒤 8프레임** · 1200 스텝.
//    ★ 팔이 셋이라 **씨앗별 대조군과 랭크는 팔마다 다시 계산하지 않는다**(세계가 같으므로 같은 값이다)
//      — ⚠️ 그래도 **팔마다 다시 센다**: 같은 코드로 두 번 세어 다르면 그 자리가 이미 버그다.
//
// ③ ⭐ **봉우리 판정 — 갈래 셋을 미리 등록한다**
//    ```
//    ㈀ 가운데(k=16)가 가장 낮다   ⇒ **봉우리** = `k` 는 분해능 **손잡이**다 (⭐ 그리고 그 봉우리가
//                                     하필 `k·패치/N ≈ 1` 이면 **희소성 경계가 그 손잡이**라는 뜻이다)
//    ㈁ k=32 가 가장 낮다          ⇒ **이 구간에서 단조** — 희소성을 버리는 쪽이 낫다는 방향
//                                     ⚠️ **「용량이다」로 단정하지 않는다**(k=128 을 안 봤다)
//    ㈂ k=8 이 가장 낮다           ⇒ 사용률 가설이 **틀렸다** ⇒ 다른 축(N·초기화·lr)을 본다
//    ```
//    ⚠️ ㈁ 면 곧바로 볼 것이 있다: `k·패치 / N = k·64/1000` 이 **1 을 넘는 순간 희소성이 뜻을 잃는다**
//      (`k=16` 에서 **1.02** · `k=32` 에서 2.05). ⇒ ㈁ 은 *"경계를 넘겨야 좋아진다"* 는 말이고
//      ★ `mltconcept.md` 의 ㈀ 경고가 그 자리다 — 그때는 **좋아진 것을 성과로 읽지 않는다.**
//    ⚠️ 「가장 낮다」는 **평균**으로 가른다. 두 팔의 차이가 씨앗 표준오차보다 작으면 **판정불가**로 찍는다.
//
//    ⚠️⚠️⚠️ **이 통계는 틀렸다 — 고친다(회차 23 에서 실측으로 드러났다).**
//      씨앗은 팔마다 **같은 씨앗**이다(짝지은 설계) ⇒ 평균 ± **독립** 표준오차로 비교하면
//      **짝짓기를 버리고** 씨앗 사이 분산을 그대로 먹는다. 실측: 씨앗 7 하나가 0.065 로 튀어
//      표준오차가 ±0.004 가 되었고 **판정불가**가 나왔는데, **짝지으면 k=32 가 12/12 로 낮았다**
//      (단측 p=0.00024). ⇒ **같은 데이터가 반대 답을 준다.**
//      ★ 그래서 이 저장소의 표준 방법(**씨앗별 부호검정** · P0/P1 이 내내 쓴 것)이 여기서도 맞고,
//        ③ 에 적어 둔 「평균 ± 표준오차」가 **일탈**이었다.
//      ⇒ **등록 고침**: 봉우리 판정은 **짝지은 부호검정**으로 한다(팔 쌍마다).
//        다중비교 `Q = 3`(쌍 셋) ⇒ 단측 p < `0.05/3 = 0.0167` 을 요구한다.
//        ⚠️ 회차 23 에서는 이 수를 **사후에** 계산했다 — 그 사실을 로그가 찍는다(숨기지 않는다).
//        ★ 그 다음 회차부터는 **사전 등록**된 통계다.
//
// ④ ⭐ **진단 채널을 같이 찍는다**(관문 아님) — 회차 21 의 두 얼굴이 어느 쪽으로 움직이나:
//    · 사용률 / rank · **시험/학습 비**(㈀ 과적합형의 지표) · **대조군보다 나쁜 씨앗 수**
//    · ⭐ `k·패치/N` (희소성이 남아 있나)
//
// ⑤ **다중비교** — 표제 판정은 **팔 셋의 ㉠** ⇒ `Q = 3`.
//    부호검정 10/12 의 단측 p = **0.0193** < `0.05/3 = 0.0167`? ⚠️⚠️ **아니다**(0.0193 > 0.0167).
//    ⇒ ★ **정직하게 적는다**: 본페로니로는 10/12 가 **모자란다**. 그래서 등록을 이렇게 둔다:
//      · **팔 하나라도 ㉠ 을 통과하는가**는 `Q=3` 으로 보정해 **11/12**(p=0.0032)를 요구한다.
//      · **봉우리(③)는 판정이 아니라 방향 읽기**다 — 보정 대상이 아니고, 그래서 ㉠ 과 **따로** 적는다.
//    ⚠️ 이 자리를 얼버무리면 「셋 중 하나가 통과했다」가 우연을 성과로 읽게 된다.
//
// ⚠️ 값 — 고친 등록({8,16,32})에서는 `vis_recon_bwd_tab` 이 훑는 길이가 512 / 1024 / 2048 이라
//   **회차 전체가 십 분 안**이다. (원래 등록의 `k=128` 은 8192 였고 그 팔 하나가 68분이었다.)
//
// ══════════════════════════════════════════════════════════════════════════════
// 🧾 **결과(회차 23) — 방향은 섰다. 그런데 `k` 는 ㉠ 을 고칠 축이 아니다.**
// ══════════════════════════════════════════════════════════════════════════════
//   | k | 시험 | 학습 | 시험/학습 | 부호검정(㉠) | 사용률/rank | `k·패치/N` |
//   |---|---|---|---|---|---|---|
//   | 8  | 0.02107 | 0.01192 | **1.77배** | 6/12  | 35.1/151.8  | 0.51 |
//   | 16 | 0.01937 | 0.00976 | **1.99배** | 6/12  | 61.2/151.8  | **1.02** |
//   | 32 | **0.01562** | 0.00767 | **2.04배** | 10/12 | 114.8/151.8 | 2.05 |
//
//   · ㉠ 은 **셋 다 ⛔**(필요 11/12). k=32 는 표제 문턱을 넘었지만 부호검정이 10/12 로 하나 모자란다.
//   · ⭐ **짝지은 부호검정으로는 순서가 확실하다**: 8↔32 **12/12**(p=0.00024) · 16↔32 **11/12**
//     (p=0.00317) · 8↔16 10/12(p=0.0193 ⛔ 보정선). 사용률은 **모든 쌍에서 12/12 단조**.
//     ⇒ 갈래 **㈁ 이 구간에서 단조**. ⚠️ 「용량이다」로 단정하지 않는다(k=128 을 안 봤다).
//   · ⚠️⚠️ **그리고 그 단조가 좋은 뜻이 아니다** — 시험/학습 비가 `k` 와 **같이** 커진다
//     (1.77 → 1.99 → 2.04). ⇒ `k` 는 **재구성을 좋게 하고 일반화 격차를 키우는** 축이다.
//     ★ 수로 보면: k=32 의 **학습**은 문턱의 **45%**(0.00767/0.01710)인데 **시험**은 **91%** 다.
//     ⇒ **병목은 일반화이고 `k` 로는 안 고쳐진다.**
//   · ⚠️ 게다가 `k·패치/N` 이 k=16 에서 이미 **1.02**(희소성 경계) · k=32 에서 2.05 다
//     ⇒ 좋아진 몫의 일부는 **희소성을 버린 값**이다(성과로 읽지 않는다).
//
// ══════════════════════════════════════════════════════════════════════════════
// 📌 **걸음 5 등록 — 「데이터를 더 준다」를 흔든다** (재기 전에 적는다)
// ══════════════════════════════════════════════════════════════════════════════
//   · 팔 셋: **학습 프레임 {32, 128, 512}** · `k = 8` **고정** · `N` = 1000 고정.
//   · ⭐ **왜 학습 프레임인가**: 이 회차가 「병목 = 일반화」를 못 박았고, 일반화 격차의 가장 흔한
//     원인은 **데이터 부족**이다. 그것을 먼저 배제하지 않으면 정규화(지금 `wd = 0`)의 효과를 오독한다.
//     ★ 그리고 이 프로젝트에서 **프레임은 공짜다**(세계가 무한히 낸다) — 그것이 이 트랙의 근본 강점이고
//       여기서 처음 쓰인다.
//   · ⭐ **`k = 8` 로 돌아간다**: `k·패치/N = 0.51` 로 **희소성이 남는 팔**이다. 흔드는 축이
//     일반화이므로 **우리가 원하는 체제에서** 재야 한다(k=32 의 이득은 어차피 할인 대상이다).
//   · **스텝 = 에폭 고정**(37.5) ⇒ {1200, 4800, 19200}. ⚠️ **혼입을 적는다**: 데이터 양과 계산 양이
//     같이 는다. 스텝을 고정하면 「프레임을 덜 본다」가 섞이므로 어느 쪽이든 혼입이고, 에폭 고정이
//     *"데이터를 더 주면 일반화가 좋아지나"* 의 정직한 형태다. ⇒ **둘 다 로그에 적는다.**
//   · 관문은 ㉠ **그대로**(0.01710 · 짝지은 통계 · Q=3 ⇒ 11/12).
//   · ⭐ 진단: 시험/학습 비 · 사용률/rank · 대조군보다 나쁜 씨앗 수.
//   · ⚠️ 값 — 아레나가 는다(프레임 520장 = 8.5M float ≈ 34MB 추가) · 19,200 스텝 팔이 씨앗당 ~36초
//     ⇒ 회차 전체 **십 분 대**. `k=8` 이라 프레임당 멈춤은 작다.
//
// ══════════════════════════════════════════════════════════════════════════════
// 🧾 **부분 결과(2026-08-24) — 팔 둘까지. ⚠️ `k=128` 은 미완이다(버린 것이 아니다).**
// ══════════════════════════════════════════════════════════════════════════════
//   | k | 시험 | 학습 | 시험/학습 | 부호검정 | 사용률/rank | 대조군보다 나쁜 씨앗 |
//   |---|---|---|---|---|---|---|
//   | 8   | **0.02107** | 0.01192 | 1.77배 | **6**/12 | 35.1/151.8 | 2 |
//   | 32  | **0.01562** | 0.00767 | 2.04배 | **10**/12 | 114.8/151.8 | 1 |
//   | 128 | (미완 · 씨앗 2개: 0.00569 · 0.00871) | | | | 310·444/98·180 | |
//
//   ⭐ **k=8 은 회차 21 을 비트 그대로 재현했다**(0.02107 · 6/12 · 35.1) — 결정성 확인이고,
//     `ResetSeed` 리팩터가 결과를 **한 비트도** 안 바꿨다는 회귀 검사도 된다.
//   ⭐ **k=32 는 표제 문턱을 넘었다**(0.01562 < 0.01710) — ⚠️ 그런데 부호검정이 **10/12** 라
//     이 회차의 등록값 **11/12**(`Q=3` 보정)에 **하나 모자란다**. ⇒ 판정은 ⛔ 다.
//     ★ 회차 21 의 기준(10/12)이면 통과였을 것이다 — **보정을 미리 적어 둔 것이 값을 했다.**
//   ⭐ 사용률이 **35 → 115** 로 올랐다(rank 152 에 가까워졌다) ⇒ ㉡ 의 병목 진단이 맞았다.
//   ⚠️ 그런데 **시험/학습 비가 1.77 → 2.04 로 커졌다** ⇒ `k` 를 키우면 재구성은 좋아지지만
//     **외우는 몫도 같이 커진다**. 그것이 ㈁(용량)의 얼굴이다.
//   ⚠️ `k=128` 의 씨앗 둘은 같은 씨앗의 k=32 보다 낮다(0.00569<0.00641 · 0.00871<0.01104)
//     ⇒ **㈁ 단조로 보이지만 씨앗 둘은 판정이 아니다.** 그 팔을 끝내야 판정이 선다.
//
// ══════════════════════════════════════════════════════════════════════════════
// ⚠️⚠️ **왜 미완인가 — 기계를 못 쓰게 만들었다(사람이 옆에서 일하는 중이었다)**
// ══════════════════════════════════════════════════════════════════════════════
//   `k=128` 은 한 렌더 프레임이 **2273ms** 였다(`kPerTick=8` 일 때) ⇒ 창이 2.3초씩 멈추고
//   GPU 가 100% 로 물렸다. 씨앗 하나가 5.7분, 팔 하나가 **68분**이다.
//   ★ 고친 것 둘(⚠️ **판정값은 하나도 안 건드렸다**):
//     ① **`kPerTick` 8 → 2** — 한 프레임의 멈춤이 2.3초 → 0.57초. 총 스텝 수·순서 그대로다.
//     ② ⭐ **씨앗마다 아레나·셰이더를 다시 만들지 않는다**(`MLTP2Enc::ResetSeed`) —
//        예전엔 씨앗마다 **40MB 디바이스 버퍼 + 40MB 스테이징 0채움 + 셰이더/디스크립터 10장**을
//        만들고 버렸다(스윕이면 **36회**).
//        ⚠️⚠️ **처음에 이것을 「메모리 압박의 원인」으로 적었는데 그것은 근거가 없었다 — 고친다.**
//          확인한 사실: `RHI_Vulkan::DestroyRHIBuffer` 는 **무덤에 넣고 미룬다**
//          (`_QueueDestroyResource` · TTL = `MAX_FRAMES_IN_FLIGHT*4+4` ≈ 20프레임)
//          ⇒ 재생성이 수천 프레임에 흩어져 있었으므로 **동시에 살아 있는 것은 한둘뿐**이고
//            **릭이 아니다.** ★ 그래서 이 변경의 이유는 **churn 과 시간**이지 릭이 아니다.
//        ⚠️ 그날 본 `Memory Compression 3.8GB` 의 원인은 **모른다**(다른 세션의 앱 · 보안 에이전트
//          4.4GB 등 후보가 여럿이다). ⇒ **내 것으로 지목하지 않는다**(GPU 100% 는 내 것이 맞다).
//        ⭐ 되돌릴 것은 셋뿐이다(파라미터 · `m`/`v` · 스텝 수)이고 `g` 는 네 커널이 전부 덮는다.
//        ⭐ `m`/`v` 의 0채움은 **기존 `sub` 커널**이 한다(세 오프셋을 같은 자리로 = `x−x`).
//   ⚠️ 그래도 `k=128` 의 **GPU 총량은 그대로다**(68분) — 그것은 등록의 대가이고,
//     ⇒ **사람이 기계를 안 쓸 때 돌린다**. `-mltp2k` 로 켜는 회차라 언제든 이어서 돌릴 수 있다.

using namespace PE;

class MLTP2K
{
public:
	static void Tick(RHI* rhi)
	{
		if (_arm >= kArms || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltp2k"))
		{
			LogA("[mlt] 🎚️ 걸음 4(`k` 스윕)는 **꺼져 있다**(`-mltp2k`) — 회차 23 기록: 시험 **0.02107 /"
			     " 0.01937 / 0.01562**(k=8/16/32) · ㉠ 은 셋 다 ⛔ · ⭐ 짝지은 부호검정 **12/12**(8↔32)"
			     " ⇒ ㈁ 이 구간에서 단조 · ⚠️ 시험/학습 **1.77→1.99→2.04** ⇒ `k` 는 일반화 축이 아니다\n");
			_arm = kArms;
			return;
		}
		if (!_banner) { _Banner(); _banner = true; }
		if (_st == kInit)  { _BeginSeed(rhi); return; }
		if (_st == kTrain) { _Train();        return; }
		if (_st == kEval)  { _Eval();         return; }
	}

	static bool Done() { return _arm >= kArms; }

private:
	static constexpr uint32 kArms  = 3u;
	// ⚠️ **고친 등록**(회차 23): {8, 32, 128} → **{8, 16, 32}**. 근거·잃는 것은 머리말 ① 에.
	static constexpr uint32 kKs[kArms] = { 8u, 16u, 32u };
	static constexpr uint32 kSeeds = 12u;
	static constexpr uint32 kTrainF = 32u, kTestF = 8u;
	static constexpr uint32 kFrames = kTrainF + kTestF;
	static constexpr uint32 kSteps = 1200u, kEvalTr = 8u;
	// ⚠️ **한 렌더 프레임에 도는 스텝 수** — 8 로 두었더니 `k=128` 에서 한 프레임이 **2.27초**가 되어
	//   사람이 쓰는 기계가 통째로 멈췄다(실측). ★ 이것은 **판정값이 아니라 값 조절**이다:
	//   총 스텝 수도 순서도 그대로이므로 **결과가 안 바뀐다**. ⇒ 2 로 내려 창이 살아 있게 한다.
	static constexpr uint32 kPerTick = 2u;
	static constexpr float  kHead = 0.01710f, kBeat = 0.5f;
	static constexpr float  kUseFrac = 0.01f, kRankTol = 1.0e-3f;
	static constexpr uint32 kSignPass = 11u;   // ⚠️ `Q=3` 보정(회차 21 은 10 이었다 — 위 ⑤)

	enum { kInit, kTrain, kEval };

	inline static MLTP2Enc _E;
	inline static bool   _banner = false;
	inline static bool   _setup = false;
	inline static uint32 _arm = 0u, _seed = 0u;
	inline static int    _st = kInit;
	inline static uint32 _step = 0u, _ev = 0u;
	inline static Array<float> _usage;
	inline static double _sumTest = 0.0, _sumTrain = 0.0;
	inline static uint32 _nTest = 0u, _nTrain = 0u;
	inline static float  _baseB = 0.0f;
	inline static uint32 _rank = 0u;
	inline static bool   _finite = true;
	inline static float  _curve = 0.0f;

	// 팔별 누산 — ⚠️ 씨앗별 값도 남긴다(부호검정과 표준오차가 그것을 요구한다)
	inline static float  _test[kArms][kSeeds] = { { 0.0f } };
	inline static float  _train[kArms][kSeeds] = { { 0.0f } };
	inline static uint32 _use[kArms][kSeeds] = { { 0u } };
	inline static uint32 _rk[kArms][kSeeds] = { { 0u } };
	inline static bool   _ok[kArms][kSeeds] = { { false } };
	inline static bool   _worse[kArms][kSeeds] = { { false } };

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🎚️👁️ **P2 걸음 4 · `k` 스윕** — 팔 %u × 씨앗 %u (N=%u 고정)\n",
			kArms, kSeeds, MLTP2Cfg::kN);
		LogA("[mlt] 🎚️   팔: k = %u / %u / %u  ⇒ `k·패치/N` = %.2f / %.2f / **%.2f**"
		     " (1 을 넘으면 희소성이 뜻을 잃는다)\n",
			kKs[0], kKs[1], kKs[2],
			(double)((float)(kKs[0] * MLTP2Cfg::kPatches) / (float)MLTP2Cfg::kN),
			(double)((float)(kKs[1] * MLTP2Cfg::kPatches) / (float)MLTP2Cfg::kN),
			(double)((float)(kKs[2] * MLTP2Cfg::kPatches) / (float)MLTP2Cfg::kN));
		LogA("[mlt] 🎚️   ㉠ 은 회차 21 것을 **글자 그대로** 쓴다(0.01710) · 부호검정 **%u/%u**"
		     "(⚠️ Q=3 보정 — 회차 21 은 10 이었다)\n", kSignPass, kSeeds);
		LogA("[mlt] 🎚️   갈래: ㈀ 가운데가 최저 = **봉우리(손잡이)** · ㈁ 단조 = **용량** ·"
		     " ㈂ k=8 이 최저 = 사용률 가설이 틀렸다\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

	static void _BeginSeed(RHI* rhi)
	{
		typedef MLTP2Cfg C;
		// ⭐ 아레나·셰이더는 **한 번만** 만든다(그 뒤로는 `ResetSeed`) — 사람이 쓰는 기계를
		//   40MB 버퍼 36개로 두들기지 않는다. ⚠️ 결과는 한 비트도 안 바뀐다.
		if (!_setup)
		{
			if (!_E.Setup(rhi)) { LogA("[mlt] 🎚️ 준비 실패(팔 %u 씨앗 %u)\n", _arm, _seed); _arm = kArms; return; }
			_setup = true;
		}
		else if (!_E.ResetSeed())
		{ LogA("[mlt] 🎚️ 되돌리기 실패(팔 %u 씨앗 %u)\n", _arm, _seed); _arm = kArms; return; }
		_E.SetK(kKs[_arm]);

		Array<float> fr, tg, testPatch;
		fr.Reset(0); tg.Reset(0); testPatch.Reset(0);
		ImageFormat::Bitmap bmp;
		Bytes packed;
		MLTWorld w;
		w.Reset(_seed, 0u, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
		for (uint32 f = 0; f < kFrames; ++f)
		{
			w.Step();
			if (!w.Render(bmp) || !MLTWorld::Pack(bmp, nullptr, packed))
			{ LogA("[mlt] 🎚️ Render/Pack 실패\n"); _arm = kArms; return; }
			const uint8* px = (const uint8*)packed.GetData();
			MLTP2Enc::AppendFrame(fr, tg, px);
			if (f >= kTrainF)
			{
				Array<float> one, dummy; one.Reset(0); dummy.Reset(0);
				MLTP2Enc::AppendFrame(dummy, one, px);
				for (uint32 i = 0; i < one.Count(); ++i) testPatch.Add(one[i]);
			}
		}
		if (!_E.WritePool(fr, tg, kFrames)) { LogA("[mlt] 🎚️ 풀 업로드 실패\n"); _arm = kArms; return; }

		_baseB = MLTP2Enc::PatchConstMse(testPatch);
		_rank  = MLTP2Enc::PatchRank(testPatch, kRankTol);

		_usage.Reset(0);
		for (uint32 i = 0; i < _E.N(); ++i) _usage.Add(0.0f);
		_step = 0u; _ev = 0u; _sumTest = 0.0; _sumTrain = 0.0; _nTest = 0u; _nTrain = 0u;
		_finite = true; _curve = 0.0f;
		_st = kTrain;
	}

	static void _Train()
	{
		for (uint32 i = 0; i < kPerTick && _step < kSteps; ++i)
		{
			_E.SetFrame(_step % kTrainF);
			if (!_E.Forward() || !_E.Backward() || !_E.AdamStep(1.0f))
			{ LogA("[mlt] 🎚️ 스텝 실패(팔 %u 씨앗 %u 스텝 %u)\n", _arm, _seed, _step); _arm = kArms; return; }
			++_step;
		}
		{ float m = 0.0f; bool fin = true; if (_E.ReadMse(m, fin)) { _curve = m; if (!fin) _finite = false; } }
		if (_step >= kSteps) { _st = kEval; _ev = 0u; }
	}

	static void _Eval()
	{
		const uint32 nEv = kTestF + kEvalTr;
		if (_ev > 0u)
		{
			const uint32 prev = _ev - 1u;
			float m = 0.0f; bool fin = true;
			if (!_E.ReadMse(m, fin)) { LogA("[mlt] 🎚️ 평가 리드백 실패\n"); _arm = kArms; return; }
			if (!fin) _finite = false;
			if (prev < kTestF)
			{
				_sumTest += (double)m; ++_nTest;
				if (!_E.AccumUsage(_usage)) { LogA("[mlt] 🎚️ 사용률 리드백 실패\n"); _arm = kArms; return; }
			}
			else { _sumTrain += (double)m; ++_nTrain; }
		}
		if (_ev < nEv)
		{
			_E.SetFrame((_ev < kTestF) ? (kTrainF + _ev) : (_ev - kTestF));
			if (!_E.Forward()) { LogA("[mlt] 🎚️ 평가 forward 실패\n"); _arm = kArms; return; }
			++_ev;
			return;
		}
		_JudgeSeed();
	}

	static void _JudgeSeed()
	{
		typedef MLTP2Cfg C;
		const float mT = (_nTest  != 0u) ? (float)(_sumTest  / (double)_nTest)  : 0.0f;
		const float mR = (_nTrain != 0u) ? (float)(_sumTrain / (double)_nTrain) : 0.0f;
		float mx = 0.0f;
		for (uint32 i = 0; i < _E.N(); ++i) if (_usage[i] > mx) mx = _usage[i];
		uint32 use = 0u;
		if (mx > 0.0f) { const float th = kUseFrac * mx; for (uint32 i = 0; i < _E.N(); ++i) if (_usage[i] > th) ++use; }

		_test[_arm][_seed] = mT; _train[_arm][_seed] = mR;
		_use[_arm][_seed] = use; _rk[_arm][_seed] = _rank;
		_ok[_arm][_seed] = (mT < kBeat * _baseB) && _finite;
		_worse[_arm][_seed] = (mT >= _baseB);

		LogA("[mlt] 🎚️ k=%3u [%2u/%u] 씨앗 %u — 시험 **%.5f** %s %.5f · 학습 %.5f · 사용률 **%u**/rank %u%s\n",
			kKs[_arm], _seed + 1u, kSeeds, _seed, (double)mT, _ok[_arm][_seed] ? "<" : "≥",
			(double)(kBeat * _baseB), (double)mR, use, _rank,
			_worse[_arm][_seed] ? " ⚠️대조군보다 나쁘다" : "");

		++_seed;
		if (_seed >= kSeeds)
		{
			_ArmSummary();
			_seed = 0u; ++_arm;
			if (_arm >= kArms) { _Summary(); _E.Destroy(); return; }
		}
		_st = kInit;
	}

	static void _ArmSummary()
	{
		double sT = 0.0, sR = 0.0; uint32 sign = 0u, sU = 0u, sK = 0u, worse = 0u;
		for (uint32 i = 0; i < kSeeds; ++i)
		{
			sT += (double)_test[_arm][i]; sR += (double)_train[_arm][i];
			sU += _use[_arm][i]; sK += _rk[_arm][i];
			if (_ok[_arm][i]) ++sign;
			if (_worse[_arm][i]) ++worse;
		}
		const float mT = (float)(sT / (double)kSeeds), mR = (float)(sR / (double)kSeeds);
		LogA("[mlt] 🎚️ ── 팔 k=%u ── 시험 **%.5f** · 학습 %.5f (시험/학습 **%.2f배**)"
		     " · 부호검정 **%u/%u** · 사용률 %.1f/rank %.1f · 대조군보다 나쁜 씨앗 **%u**\n",
			kKs[_arm], (double)mT, (double)mR, (double)((mR > 1e-9f) ? (mT / mR) : 0.0f),
			sign, kSeeds, (double)((float)sU / (float)kSeeds), (double)((float)sK / (float)kSeeds), worse);
	}

	// 단측 이항 꼬리 `P(X >= w)`, `p = 0.5`. ⚠️ `n = 12` 라 조합수가 작아 정확히 센다(근사 안 쓴다).
	static float _BinomP(uint32 w, uint32 n)
	{
		double tot = 0.0;
		for (uint32 i = w; i <= n; ++i)
		{
			double c = 1.0;
			for (uint32 j = 0; j < i; ++j) c = c * (double)(n - j) / (double)(j + 1u);
			tot += c;
		}
		return (float)(tot / Pow(2.0f, (float)n));
	}

	static void _Summary()
	{
		float mean[kArms] = { 0.0f }, se[kArms] = { 0.0f };
		uint32 sign[kArms] = { 0u };
		for (uint32 a = 0; a < kArms; ++a)
		{
			double s = 0.0;
			for (uint32 i = 0; i < kSeeds; ++i) { s += (double)_test[a][i]; if (_ok[a][i]) ++sign[a]; }
			mean[a] = (float)(s / (double)kSeeds);
			double v = 0.0;
			for (uint32 i = 0; i < kSeeds; ++i)
			{ const double d = (double)_test[a][i] - (double)mean[a]; v += d * d; }
			se[a] = (float)Sqrt(v / (double)(kSeeds * (kSeeds - 1u)));
		}
		// ── 최저 팔 ────────────────────────────────────────────────
		uint32 best = 0u;
		for (uint32 a = 1; a < kArms; ++a) if (mean[a] < mean[best]) best = a;
		// ⚠️ 「가장 낮다」가 표준오차보다 작으면 **판정불가**다(등록문 ③ 의 그 자리)
		bool clear = true;
		for (uint32 a = 0; a < kArms; ++a)
			if (a != best && (mean[a] - mean[best]) < (se[a] + se[best])) clear = false;

		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🎚️👁️ **`k` 스윕 결과**\n");
		for (uint32 a = 0; a < kArms; ++a)
			LogA("[mlt] 🎚️   k=%3u · 시험 **%.5f** ± %.5f(표준오차) · 부호검정 %u/%u · %s ㉠\n",
				kKs[a], (double)mean[a], (double)se[a], sign[a], kSeeds,
				(mean[a] < kHead && sign[a] >= kSignPass) ? "✅" : "⛔");
		LogA("[mlt] 🎚️   ㉠ 문턱 %.5f · 부호검정 필요 **%u/%u**(Q=3 본페로니 · p=0.0032)\n",
			(double)kHead, kSignPass, kSeeds);

		// ⭐ 등록한 갈래를 **그대로** 적용한다
		const char* branch;
		if (!clear) branch = "판정불가 — 팔 사이 차이가 씨앗 표준오차보다 작다";
		else if (best == 1u) branch = "㈀ **봉우리** — `k` 는 분해능 손잡이다";
		else if (best == 2u) branch = "㈁ **용량** — `k` 가 클수록 좋아진다(손잡이가 아니다)";
		else branch = "㈂ k=8 이 최저 — **사용률 가설이 틀렸다**(다른 축을 본다)";
		LogA("[mlt] 🎚️   ⭐ 봉우리 판정(등록된 통계 = 평균±표준오차) = **%s** (최저 팔 k=%u)\n",
			branch, kKs[best]);

		// ══════════════════════════════════════════════════════════════
		// ⭐ **짝지은 부호검정** — ⚠️ 씨앗이 팔마다 같으므로 **이것이 맞는 통계**다.
		//   ⚠️ 회차 23 에서는 이것을 **사후에** 얹었다(위 ③ 의 ⚠️⚠️⚠️). 숨기지 않고 찍는다.
		// ══════════════════════════════════════════════════════════════
		LogA("[mlt] 🎚️   ── ⭐ 짝지은 부호검정(같은 씨앗끼리) — **이것이 맞는 통계다** ──\n");
		uint32 pairWin[kArms][kArms] = { { 0u } };
		for (uint32 a = 0; a < kArms; ++a)
			for (uint32 b = a + 1u; b < kArms; ++b)
			{
				uint32 w = 0u;
				for (uint32 i = 0; i < kSeeds; ++i) if (_test[b][i] < _test[a][i]) ++w;
				pairWin[a][b] = w;
				const float p = _BinomP((w >= kSeeds - w) ? w : (kSeeds - w), kSeeds);
				LogA("[mlt] 🎚️     k=%-3u vs k=%-3u → k=%u 가 더 낮은 씨앗 **%u/%u** · 단측 p=%.5f %s"
				     " (Q=3 보정선 0.0167)\n",
					kKs[a], kKs[b], kKs[b], w, kSeeds, (double)p,
					(p < 0.0167f) ? "✅" : "⛔");
			}
		// ⭐ 짝지은 결과로 순서가 서면 그것을 적는다(등록된 갈래를 **짝지은 통계로** 읽는다)
		const bool mono = (pairWin[0][1] * 2u > kSeeds) && (pairWin[1][2] * 2u > kSeeds);
		const bool peak = (pairWin[0][1] * 2u > kSeeds) && (pairWin[1][2] * 2u < kSeeds);
		LogA("[mlt] 🎚️     ⇒ 짝지은 읽기 = **%s**\n",
			mono ? "㈁ 이 구간에서 **단조**(k 를 키우면 좋아진다) ⚠️ 「용량이다」로 단정하지 않는다"
			     : (peak ? "㈀ **봉우리**(가운데가 최저)" : "㈂ 또는 뒤섞임 — 씨앗별 표를 읽어라"));
		// ⚠️ 그리고 **일반화 격차**를 나란히 적는다 — ㉠ 이 왜 안 통과하나가 거기 있다
		LogA("[mlt] 🎚️     ⓘ 시험/학습 비: ");
		for (uint32 a = 0; a < kArms; ++a)
		{
			double sT = 0.0, sR = 0.0;
			for (uint32 i = 0; i < kSeeds; ++i) { sT += (double)_test[a][i]; sR += (double)_train[a][i]; }
			LogA("k=%u **%.2f배** ", kKs[a], (sR > 1e-9) ? (sT / sR) : 0.0);
		}
		LogA("\n[mlt] 🎚️     ⚠️ 이 비가 `k` 와 **같이 커지면** `k` 는 ㉠(일반화)을 고칠 축이 아니다\n");
		if (best == 2u)
			LogA("[mlt] 🎚️   ⚠️⚠️ `k·패치/N` = **%.2f** ≫ 1 ⇒ 「사전에서 고른다」가 아니라 **다 쓴다**다."
			     " ★ 좋아진 것을 성과로 읽지 마라(mltconcept ㈀ 경고)\n",
				(double)((float)(kKs[2] * MLTP2Cfg::kPatches) / (float)MLTP2Cfg::kN));
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}
};
