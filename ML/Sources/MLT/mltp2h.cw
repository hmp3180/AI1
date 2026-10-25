// mltp2h.cw — 🧠 **P2 걸음 12 · 은닉 한 겹**(SwiGLU ↔ 공유 정규화 경로). 회차 30 이 가리킨 자리다.
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문** — ⚠️ 재기 **전에** 적는다.
// ══════════════════════════════════════════════════════════════════════════════
//
// ① **왜 여기인가** — 회차 30 이 못 박았다:
//    · **OMP 0.01505 < 통과선 0.01599** ⇒ 문턱은 `k=8`·이 코드북에서 **도달 가능**하고 **코드북은 무죄**다.
//    · 모델은 OMP 의 **2.64배**이고 초과분은 **계수 48% · 선택 52%** ⇒ 범인은 **인코더→점수→세기** 경로.
//    ★ 그런데 그 경로는 **통째로 한 겹 선형**이다: `patch = Σ 자리표 행`(선형) →
//      `score = patch·Wdᵗ`(선형). 반면 OMP 는 **반복적이고 데이터 의존적**이다(잔차를 보고 고른다).
//      ⇒ 한 겹 선형이 그것을 흉내낼 수 없는 것은 **당연**하고, 그것이 2.64배의 정체 후보다.
//
// ② **팔 셋** — ⚠️ **셋이 같은 코드를 탄다**(`MLTP2Enc::Setup` 의 `hidden`/`useSwiglu` 인자).
//    ```
//    ㈀ 지금 그대로     은닉 없음(H = D = 128)
//    ㈁ SwiGLU 경로   H = 128 · `raw = swiglu(patch·W1aᵗ, patch·W1bᵗ)` → `rmsnorm(raw)`
//    ㈂ 공유 경로    H = 142 · `raw = patch·W1aᵗ` → **같은 `rmsnorm(raw)`**
//    ```
//    ⭐ **새 커널 0개** — `swiglu`·`rmsnorm` 순/역전파는 판정 ①② 를 **이미 통과**했다.
//    ⭐ **㈂ 가 이 회차의 핵이다.** ㈁ 에서 SwiGLU 만 뺀 경로를 나란히 둔다.
//      ★ 살아있는 파라미터: ㈀ **377,344** · ㈁ **410,112** · ㈂ **409,520** ⇒ ㈁↔㈂ 가 **0.14% 차이**다
//        (`H'' = H(2D+N)/(D+N) = 142` 로 맞췄다). 셋 다 예산 **≤ 0.5M** 안이다.
//    ⚠️ `Wd` 의 초기 산포는 **`kInitWd` 고정**이다(이상적으로는 `1/√H` 지만 H 가 128↔142 로만 갈려
//      차이가 7% 다) ⇒ **㈀ 가 예전 회차를 비트 그대로 재현하는 쪽**을 택했다.
//
// ③ ⭐ **관문**
//    ㉠ **P2 의 그 관문 그대로** — 씨앗마다 `MSE_시험 < 0.5 × 자기 대조군` · **11/12**(`Q=3` ⇒ p<0.0167).
//    ㉡ ⭐ **OMP 대비 비**(모델/OMP · 팔마다 **자기 코드북으로** 다시 잰다). 지금 **2.64**.
//       ⇒ **문턱: ㈁ 의 비 ≤ 2.0**(초과분이 절반 이상 줄어야 「흉내내기 시작했다」고 할 수 있다).
//       ★ 시험 MSE 는 코드북이 좋아져도 내려가지만 **이 비는 「경로가 오라클에 얼마나 가까운가」**만 본다.
//    ㉢ **예산** — 살아있는 파라미터 ≤ **500,000**(로그가 팔마다 찍는다).
//
// ④ ⭐ **속성 판정을 미리 등록한다**(짝지은 부호검정 세 개 · `Q = 3` ⇒ p < 0.0167)
//    ⚠️ `rmsnorm` 자체가 입력 의존 비선형이므로 ㈂는 더 이상 **순수 선형/용량 대조**가 아니다.
//    ㈁↔㈂가 말해 줄 수 있는 것은 공유 은닉+RMSNorm 경로 **위의 SwiGLU 추가 효과**다.
//    ```
//    ㈀ ㈁ 이 ㈀ 보다 낫고 **㈂ 보다도 낫다** ⇒ **SwiGLU 자체의 추가 효과**
//    ㈁ ㈂ 가 ㈀ 보다 낫지만 ㈁↔㈂ 차이는 없다 ⇒ **공유 은닉+RMSNorm 경로**
//    ㈂ 둘 다 ㈀ 보다 낫지 않다              ⇒ **정규화한 은닉 경로가 축이 아니다**
//    기타 섞인 경우                           ⇒ **판정불가**
//    ```
//
// ④′ ⭐ **「팔이 살아 있나」 관문**(회차 26·30 이 두 번 구해 준 그 칸 — 이번엔 **관문**으로 둔다)
//    각 팔의 **학습 MSE 가 ㈀ 의 2배 이내**여야 한다. 넘으면 그 팔은 **무효**이고, 그 팔의 결과를
//    **가설의 정보로 읽지 않는다**(경로를 넣다 척도가 무너지면 「효과 없음」이 거짓말이 된다).
//    ⚠️⚠️ **실제로 첫 실행이 여기서 죽었다** — 아래 🧾 를 보라.
//
// ⑤ ⭐ 진단(관문 아님): 시험/학습 비 · ㉯(계수만 최적) · 사용률 · 씨앗 10.
//    ⚠️ **사용률은 성과 지표가 아니다**(회차 29 가 직접 반증했다) — 진단 채널로만 적는다.
//
// ⑥ ⚠️ 값 — 팔 셋 × 씨앗 12 × 4800스텝 + 팔마다 OMP(씨앗당 ~2초) ⇒ **십오 분쯤**.
//
// ══════════════════════════════════════════════════════════════════════════════
// ⚠️⚠️⚠️ **첫 실행: ㈁swiglu 가 무효였다 — 척도다(관문은 하나도 안 고쳤다)**
// ══════════════════════════════════════════════════════════════════════════════
//   | 팔 | 시험 | **학습** | 모델/OMP | ㈀ 대비 짝지은 |
//   |---|---|---|---|---|
//   | ㈀없음 | 0.03977 | **0.01229** | 2.64 | — |
//   | ㈁swiglu | 0.18550 | **0.13834** ⛔ | 12.09 | 2/12 |
//   | ㈂선형2겹 | 0.03927 | 0.01381 | 2.42 | 5/12 |
//
//   ★ **학습 MSE 가 11배 무너졌다** ⇒ ㈁ 은 학습 자체를 못 했다. 원인은 척도다:
//     `W1` 을 `kInitWd`(0.09)로 두어 `rms(a) ≈ 0.055` → `rms(h) = rms(silu(a)·b) ≈ 0.0016`
//     = **패치(0.093)의 1/60**. 점수가 60배 작아져 코드북이 못 따라온다.
//   ⇒ 고침: `kInitW1 = 1.65`(⇒ `rms(a) ≈ 1` · **거의 선형이 안 되게**) + `Wd` 산포를 모드마다 줄여
//     **점수의 척도를 은닉 없는 팔과 맞춘다**. ★ 관문·문턱·갈래는 **하나도 안 바꿨다.**
//   ⚠️⚠️ **세 번째 같은 종류의 실수다**(회차 26 `rmsnorm` 이득 · 회차 30 greedy 오라클 · 여기).
//     ⇒ ★ **규율로 적는다: 새 경로를 넣을 때는 그 경로의 「출력 RMS」를 기존과 맞춘다.**
//       그리고 **「팔이 살아 있나」를 관문으로** 둔다(위 ④′).
//
//   ⭐ 반면 **㈂선형2겹은 유효한 영(null)이었다**(학습 0.01381 · 5/12) — 선형 두 겹은 한 겹과
//     표현력이 같으므로 **이론대로**다. ⇒ ★ 용량 대조군이 **제 역할을 한다는 확인**이기도 하다.
//     ⚠️ 다만 그 팔도 이번에 산포가 바뀌므로 **다시 잰다**(같은 조건에서 비교해야 한다).
//
// ══════════════════════════════════════════════════════════════════════════════
// ⚠️⚠️⚠️ **둘째 실행도 무효였다 — 그리고 그 실패가 정확한 것을 가르쳐 줬다**
// ══════════════════════════════════════════════════════════════════════════════
//   고친 산포(`kInitW1 = 1.65` + `Wd` 를 그만큼 줄임)로 다시 돌린 결과:
//   | 팔 | 시험 | **학습** | 살아있나(④′) |
//   |---|---|---|---|
//   | ㈀없음 | 0.03977 | **0.01229** | ✅ |
//   | ㈁swiglu | 6.62285 | **0.14963** | ⛔ |
//   | ㈂선형2겹 | 12.59630 | **0.04677** | ⛔ |
//   ⇒ 등록해 둔 ④′ 가 **정확히 잡아 「판정불가」로 찍었다**(그 칸을 관문으로 올린 것이 값을 했다).
//
//   ★ **원인 — 초기값 하나로 두 가지를 동시에 못 맞춘다**
//   ```
//   1차 (W1 = 0.09)          순전파 척도  rms(h) = 패치의 1/60  ⛔ | 상대 학습률  둘 다 3.3%/스텝 ✅
//   2차 (W1 = 1.65 · Wd↓)    순전파 척도  맞음                  ✅ | 상대 학습률  W1 0.18% ↔ Wd 36% ⛔
//   ```
//   ⭐ Adam 은 파라미터마다 **배율 불변**이라 절대 스텝이 대략 `lr`(3e-3)로 같다
//     ⇒ **초기값이 크면 상대 학습률이 작아진다**(1.65 는 스텝당 0.18% · 0.0084 는 36%).
//     ⇒ 두 겹이 **전혀 다른 속도로** 움직여 학습이 무너진다.
//   ★ **결론: 척도는 초기값이 아니라 「정규화」로 맞춰야 한다.**
//     ⚠️ 이것은 이 저장소가 이미 아는 것이기도 하다 — **본체(`mltmodel.cw`)는 층마다 `rmsnorm` 을
//       앞에 둔다**(pre-norm). 인코더만 그것 없이 겹을 쌓으려 한 것이 무리였다.
//
// ══════════════════════════════════════════════════════════════════════════════
// 📌 **회차 32 등록(걸음 12 재시도) — 은닉 뒤에 `rmsnorm` 을 둔다**
// ══════════════════════════════════════════════════════════════════════════════
//   `h = swiglu(...)` **뒤에 `rmsnorm(h)`** 를 걸어 사전이 보는 것의 척도를 **초기값과 무관하게** 고정한다.
//   ⭐ **새 커널 0개** — `rmsnorm`/`rmsnorm_bwd` 는 판정 ①② 를 이미 통과했고 본체가 쓰는 그 커널이다.
//   ⚠️ 그러면 `W1`·`Wd` 의 산포를 **둘 다 `kInitWd` 로 되돌릴 수 있다**(상대 학습률이 맞는다)
//     — 척도는 정규화가 맡으므로 초기값이 그 일을 겸하지 않아도 된다.
//   ⚠️ ㈂(선형 투영)에도 **같은 정규화**를 건다(안 그러면 팔끼리 다른 것을 재게 된다).
//     ⚠️ 그 결과 ㈂는 순수 용량 대조가 아니라 **SwiGLU 만 뺀 공유 경로 대조**다.
//   ⚠️ 관문은 **그대로**(㉠ · ㉡ OMP 대비 비 ≤ 2.0 · ㉢ 예산 · ④′ 살아있나).
//
// ═══════════════════════════════════════════════════════════════════════════════
// 🧾 **회차 32 결과 — 세 팔이 살았고, 정규화한 은닉 한 겹은 축이 아니었다**
// ═══════════════════════════════════════════════════════════════════════════════
//   | 팔 | 시험 | 학습 | 모델/OMP | ㈀ 대비 |
//   |---|---:|---:|---:|---:|
//   | ㈀없음 | 0.03977 | 0.01229 | 2.64 | — |
//   | ㈁swiglu+norm | 0.03384 | 0.00807 | 2.56 | **4/12** |
//   | ㈂선형+norm | 0.03262 | 0.01108 | 2.27 | **4/12** |
//   ★ ④′ 살아있나는 둘 다 ✅. 그런데 대응 부호검정은 ㈁↔㈀ **4/12**,
//     ㈂↔㈀ **4/12**, ㈁↔㈂ **7/12**로 전부 귀무였고 ㈁ 의 OMP 대비 비도 **2.56 > 2.0**.
//   ⇒ 등록 갈래 ㈂: **정규화한 은닉 한 겹은 선택·계수 병목의 축이 아니다.**
//   ⚠️ 평균은 내려갔지만(씨앗 10 이 0.22868→0.15487/0.13326) 짝지은 향상이 아니다.
//
// 📌 **다음 등록(걸음 13) — 선택 점수와 재구성 계수를 별도 머리로 풀기**
//   회차 30 의 초과분은 계수 48% · 선택 52%였고, 지금 `mag = score[ids]`는 한 수에
//   **선택 순위**와 **재구성 계수** 두 일을 시킨다. 은닉 하나로 공유 표현만 늘려도 이 결합은 남았다.
//   ```
//   ㈀ 현재            full-rank `Wd` · ids = topk(S) · mag = S[ids]
//   ㈁ 완전 분리       rank54 머리 둘 · ids = topk(S) · mag = C[ids]
//   ㈂ ⚠️ 부분 결합 대조  같은 머리 둘 · ids = topk(S) · mag = (S+C)/√2 [ids]
//   ```
//   ⭐ ㈁㈂는 기존 `Wd` 를 **rank=54 머리 둘**(`D→54→N`)로 대체한다:
//     `2·54·(128+1000)=121,824`, 살아있는 전체 **371,168 < ㈀ 377,344**.
//     ⚠️ 정본 점검으로 「두껍게·크기로 밀기」를 피하려 `rank=108` 추가안을 **재기 전 폐기**했다.
//   ⭐ 순전파 척도도 미리 맞춘다: 머리 각 출력에 고정 `≈2.61891`를 곱해 기존 점수 RMS 로,
//     ㈂ 계수는 `(S+C)/sqrt(2)`로 맞춘다(학습 gain·RMSNorm 아님).
//   ⭐ ㈁㈂는 선택 `S`·파라미터·계수 척도가 같고, **계수에 선택 점수를 남기나**만 다르다.
//   ⚠️ 새 커널은 `act_gather`·`act_gather_bwd` 둘(고른 ids 에서 별도 계수 순/역전파) ⇒ 판정 ①② 먼저.
//     선택 STE 는 기존 `act_topk_bwd`; ㈂의 `S` 에는 계수 기울기를 그 뒤 결정적으로 누산한다.
//   관문: 기존 ㉠·㉡·㉢ + 팔이 살았나. 속성 판정은 세 대응 비교(`Q=3`, p<0.0167):
//     ㈁>㈀ 그리고 ㈁>㈂ = **완전 분리**, ㈁·㈂ 둘 다>㈀ = **저랭크 인자화/최적화**,
//     둘 다 아님 = **이 분리도 축이 아님**, 기타 = **판정불가**.
//
// 🧾 **회차 33 결과 — 두 저랭크 팔이 죽어 판정불가**
//   ㈀ 0.03977/학습 0.01229 · ㈁ 0.07001/학습 0.02888 · ㈂ 0.07224/학습 0.05497.
//   생존선은 `2×0.01229=0.02458`이라 ㈁㈂ 모두 ⛔. 새 커널은 판정 ① 29/29·② 전부 통과했고
//   기준선도 완전 재현했다 ⇒ 가설 결론이 아니라 **저랭크 두 겹의 최적화 척도 실패**다.
//
// 📌 **회차 34 등록 — S/C 출력에 같은 고정 RMSNorm**
//   목표 RMS=기존 full-rank 점수 초기 RMS 0.05473. 순위는 행별 양의 공통 배율이라 불변이고,
//   학습 파라미터·관문·세 대응 갈래는 전부 그대로다. 이번에도 생존 관문이 먼저다.
// 🧾 결과: ㈁/㈂ 학습 0.01994/0.01557로 생존. 시험 0.04210/0.03355, 대응 3/12·5/12,
//   ㈁>㈂ 3/12, ㈁ 모델/OMP 2.78 ⇒ 등록 갈래 ㈂ **선택/계수 분리도 축이 아니다**.
// 📌 다음은 모델 변경 전에 현재 ids에 잔차 기반 교체 1회 CPU 오라클로 반복의 최소 몫을 잰다.

using namespace PE;

class MLTP2H
{
public:
	static void Tick(RHI* rhi)
	{
		if (_arm >= kArms || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltp2h"))
		{
			LogA("[mlt] 🧠 걸음 12(은닉 한 겹)는 **꺼져 있다**(`-mltp2h`) — 회차 32: 세 팔 생존 ✅ ·"
			     " ㈁/㈂ vs ㈀ **4/12·4/12** · ㈁ vs ㈂ **7/12** · ㈁ 모델/OMP **2.56**"
			     " ⇒ **정규화한 은닉 한 겹은 축이 아니다** · 다음 = 선택/계수 별도 머리\n");
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
	static constexpr uint32 kArms = 3u;
	static constexpr uint32 kHid[kArms]  = { 0u, 128u, 142u };   // 0 = 은닉 없음
	static constexpr bool   kSwig[kArms] = { false, true, false };
	static constexpr uint32 kSeeds = 12u;
	static constexpr uint32 kTrainF = 128u, kTestF = 8u;
	static constexpr uint32 kPoolCap = kTrainF + kTestF;
	static constexpr uint32 kSteps = 4800u;
	static constexpr uint32 kN = 1000u, kK = 8u;
	static constexpr uint32 kPerTick = 4u, kEvalTr = 8u;
	static constexpr uint32 kTestEpisode = 1u;
	static constexpr float  kRidge = 1.0e-6f;
	static constexpr float  kBeat = 0.5f;
	static constexpr uint32 kSignPass = 11u;
	static constexpr uint32 kBudget = 500000u;
	static constexpr float  kOmpRatio = 2.0f;    // ㉡ 문턱(지금 2.64)
	static constexpr float  kUseFrac = 0.01f;
	static constexpr uint32 kWatchSeed = 10u;
	static constexpr uint32 kLiveSlot = 384u;    // 회차 20 이 잰 값(코퍼스 살아있는 자리표 행)

	enum { kInit, kTrain, kEval };

	inline static MLTP2Enc _E;
	inline static bool   _banner = false;
	inline static uint32 _arm = 0u, _seed = 0u;
	inline static int    _st = kInit;
	inline static uint32 _step = 0u, _ev = 0u;
	inline static double _sumTest = 0.0, _sumTrain = 0.0;
	inline static uint32 _nTest = 0u, _nTrain = 0u;
	inline static Array<float> _tgtTest, _idsTest, _code, _usage;

	inline static float _mTest[kArms][kSeeds]  = { { 0.0f } };
	inline static float _mTrain[kArms][kSeeds] = { { 0.0f } };
	inline static float _mLsq[kArms][kSeeds]   = { { 0.0f } };
	inline static float _mOmp[kArms][kSeeds]   = { { 0.0f } };
	inline static float _mBase[kArms][kSeeds]  = { { 0.0f } };
	inline static uint32 _use[kArms][kSeeds]   = { { 0u } };
	inline static bool   _ok[kArms][kSeeds]    = { { false } };

	static const char* _ArmName(uint32 a)
	{ return (a == 0u) ? "㈀없음" : ((a == 1u) ? "㈁swiglu+norm" : "㈂선형+norm"); }

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🧠 **P2 걸음 12 · 은닉 한 겹** — 팔 %u × 씨앗 %u (k=%u N=%u F=%u %u스텝)\n",
			kArms, kSeeds, kK, kN, kTrainF, kSteps);
		LogA("[mlt] 🧠   팔: ㈀ 은닉 없음(H=D) · ㈁ **swiglu+rmsnorm** H=%u · ㈂ **선형+rmsnorm** H=%u\n",
			kHid[1], kHid[2]);
		for (uint32 a = 0; a < kArms; ++a)
			LogA("[mlt] 🧠      %s — 살아있는 파라미터 **%u**%s\n", _ArmName(a),
				MLTP2Enc::LiveParams(kLiveSlot, kN, kHid[a], kSwig[a]),
				(MLTP2Enc::LiveParams(kLiveSlot, kN, kHid[a], kSwig[a]) <= kBudget) ? " ✅" : " ⛔예산초과");
		LogA("[mlt] 🧠   ㉠ 씨앗별 **%u/%u** · ㉡ **OMP 대비 비 ≤ %.1f**(지금 2.64) · ㉢ 예산 ≤ %u\n",
			kSignPass, kSeeds, (double)kOmpRatio, kBudget);
		LogA("[mlt] 🧠   ⭐ 갈래: ㈁>㈀·㈁>㈂ = **SwiGLU 추가 효과** · ㈂>㈀·㈁≈㈂ = **공유 경로** ·"
		     " 둘 다 ㈀ 이하 = 정규화한 은닉 경로가 축이 아니다\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

	static void _BeginSeed(RHI* rhi)
	{
		// ⚠️ 은닉 폭이 **파라미터 배치를 정한다** ⇒ 팔이 바뀌면 아레나를 다시 만든다(씨앗마다는 아니다).
		if (_seed == 0u)
		{
			if (!_E.Setup(rhi, kPoolCap, kN, kHid[_arm], kSwig[_arm]))
			{ LogA("[mlt] 🧠 준비 실패(팔 %s)\n", _ArmName(_arm)); _arm = kArms; return; }
		}
		else if (!_E.ResetSeed()) { LogA("[mlt] 🧠 되돌리기 실패\n"); _arm = kArms; return; }
		_E.SetK(kK);
		_E.SetSelectAbs(false);

		Array<float> fr, tg;
		fr.Reset(0); tg.Reset(0); _tgtTest.Reset(0);
		ImageFormat::Bitmap bmp;
		Bytes packed;
		{
			MLTWorld w;
			w.Reset(_seed, 0u, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
			for (uint32 f = 0; f < kTrainF; ++f)
			{
				w.Step();
				if (!w.Render(bmp) || !MLTWorld::Pack(bmp, nullptr, packed))
				{ LogA("[mlt] 🧠 Render/Pack 실패(학습)\n"); _arm = kArms; return; }
				MLTP2Enc::AppendFrame(fr, tg, (const uint8*)packed.GetData());
			}
		}
		{
			MLTWorld w;
			w.Reset(_seed, kTestEpisode, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
			for (uint32 f = 0; f < kTestF; ++f)
			{
				w.Step();
				if (!w.Render(bmp) || !MLTWorld::Pack(bmp, nullptr, packed))
				{ LogA("[mlt] 🧠 Render/Pack 실패(시험)\n"); _arm = kArms; return; }
				const uint8* px = (const uint8*)packed.GetData();
				MLTP2Enc::AppendFrame(fr, tg, px);
				Array<float> one, dummy; one.Reset(0); dummy.Reset(0);
				MLTP2Enc::AppendFrame(dummy, one, px);
				for (uint32 i = 0; i < one.Count(); ++i) _tgtTest.Add(one[i]);
			}
		}
		if (!_E.WritePool(fr, tg, kTrainF + kTestF))
		{ LogA("[mlt] 🧠 풀 업로드 실패\n"); _arm = kArms; return; }

		_mBase[_arm][_seed] = MLTP2Enc::PatchConstMse(_tgtTest);
		_usage.Reset(0);
		for (uint32 i = 0; i < _E.N(); ++i) _usage.Add(0.0f);
		_idsTest.Reset(0);
		_step = 0u; _ev = 0u; _sumTest = 0.0; _sumTrain = 0.0; _nTest = 0u; _nTrain = 0u;
		_st = kTrain;
	}

	static void _Train()
	{
		for (uint32 i = 0; i < kPerTick && _step < kSteps; ++i)
		{
			_E.SetFrame(_step % kTrainF);
			if (!_E.Forward() || !_E.Backward() || !_E.AdamStep(1.0f))
			{ LogA("[mlt] 🧠 스텝 실패(팔 %s 씨앗 %u 스텝 %u)\n", _ArmName(_arm), _seed, _step);
			  _arm = kArms; return; }
			++_step;
		}
		if (_step >= kSteps) { _st = kEval; _ev = 0u; }
	}

	static void _Eval()
	{
		const uint32 nEv = kTestF + kEvalTr;
		if (_ev > 0u)
		{
			const uint32 prev = _ev - 1u;
			float m = 0.0f; bool fin = true;
			if (!_E.ReadMse(m, fin)) { LogA("[mlt] 🧠 평가 리드백 실패\n"); _arm = kArms; return; }
			if (prev < kTestF)
			{
				_sumTest += (double)m; ++_nTest;
				Array<float> id, mg;
				if (!_E.ReadAct(id, mg)) { LogA("[mlt] 🧠 선택 리드백 실패\n"); _arm = kArms; return; }
				for (uint32 i = 0; i < id.Count(); ++i) _idsTest.Add(id[i]);
				if (!_E.AccumUsage(_usage)) { LogA("[mlt] 🧠 사용률 리드백 실패\n"); _arm = kArms; return; }
			}
			else { _sumTrain += (double)m; ++_nTrain; }
		}
		if (_ev < nEv)
		{
			_E.SetFrame((_ev < kTestF) ? (kTrainF + _ev) : (_ev - kTestF));
			if (!_E.Forward()) { LogA("[mlt] 🧠 평가 forward 실패\n"); _arm = kArms; return; }
			++_ev;
			return;
		}
		_JudgeSeed();
	}

	static void _JudgeSeed()
	{
		typedef MLTP2Cfg C;
		if (!_E.ReadCodebook(_code)) { LogA("[mlt] 🧠 코드북 리드백 실패\n"); _arm = kArms; return; }
		const float mT = (_nTest  != 0u) ? (float)(_sumTest  / (double)_nTest)  : 0.0f;
		const float mR = (_nTrain != 0u) ? (float)(_sumTrain / (double)_nTrain) : 0.0f;
		const uint32 nP = _tgtTest.Count() / C::kPix;
		const float lsq = MLTP2Enc::LsqMse(_code, kN, _tgtTest, _idsTest, kK, nP, kRidge);
		const float omp = MLTP2Enc::OmpMse(_code, kN, _tgtTest, kK, nP, kRidge);
		float mx = 0.0f;
		for (uint32 i = 0; i < _E.N(); ++i) if (_usage[i] > mx) mx = _usage[i];
		uint32 use = 0u;
		if (mx > 0.0f) { const float th = kUseFrac * mx; for (uint32 i = 0; i < _E.N(); ++i) if (_usage[i] > th) ++use; }

		_mTest[_arm][_seed] = mT; _mTrain[_arm][_seed] = mR;
		_mLsq[_arm][_seed] = lsq; _mOmp[_arm][_seed] = omp; _use[_arm][_seed] = use;
		_ok[_arm][_seed] = (mT < kBeat * _mBase[_arm][_seed]);

		LogA("[mlt] 🧠 %s [%2u/%u] 씨앗 %u — 시험 **%.5f** %s %.5f · 학습 %.5f · ㉯ %.5f ·"
		     " **OMP %.5f(비 %.2f)** · 사용률 %u\n",
			_ArmName(_arm), _seed + 1u, kSeeds, _seed, (double)mT, _ok[_arm][_seed] ? "<" : "≥",
			(double)(kBeat * _mBase[_arm][_seed]), (double)mR, (double)lsq, (double)omp,
			(double)((omp > 1e-9f) ? (mT / omp) : 0.0f), use);

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
		double sT = 0.0, sR = 0.0, sL = 0.0, sO = 0.0; uint32 sign = 0u, sU = 0u;
		for (uint32 i = 0; i < kSeeds; ++i)
		{
			sT += _mTest[_arm][i]; sR += _mTrain[_arm][i];
			sL += _mLsq[_arm][i]; sO += _mOmp[_arm][i]; sU += _use[_arm][i];
			if (_ok[_arm][i]) ++sign;
		}
		const float mT = (float)(sT / kSeeds), mR = (float)(sR / kSeeds);
		const float mL = (float)(sL / kSeeds), mO = (float)(sO / kSeeds);
		LogA("[mlt] 🧠 ── 팔 %s ── 시험 **%.5f** · 학습 %.5f (비 %.2f) · ㉯ %.5f · **OMP %.5f** ⇒"
		     " **모델/OMP = %.2f** · 부호검정 **%u/%u** · 사용률 %.1f\n",
			_ArmName(_arm), (double)mT, (double)mR, (double)((mR > 1e-9f) ? (mT / mR) : 0.0f),
			(double)mL, (double)mO, (double)((mO > 1e-9f) ? (mT / mO) : 0.0f),
			sign, kSeeds, (double)((float)sU / (float)kSeeds));
	}

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
		float mT[kArms] = { 0.0f }, mO[kArms] = { 0.0f }, rat[kArms] = { 0.0f };
		uint32 sign[kArms] = { 0u };
		for (uint32 a = 0; a < kArms; ++a)
		{
			double sT = 0.0, sO = 0.0;
			for (uint32 i = 0; i < kSeeds; ++i) { sT += _mTest[a][i]; sO += _mOmp[a][i]; if (_ok[a][i]) ++sign[a]; }
			mT[a] = (float)(sT / kSeeds); mO[a] = (float)(sO / kSeeds);
			rat[a] = (mO[a] > 1.0e-9f) ? (mT[a] / mO[a]) : 0.0f;
		}
		// 짝지은 부호검정 — ㈁ vs ㈀ · ㈂ vs ㈀ · ㈁ vs ㈂
		uint32 w1 = 0u, w2 = 0u, w12 = 0u;
		for (uint32 i = 0; i < kSeeds; ++i)
		{
			if (_mTest[1][i] < _mTest[0][i]) ++w1;
			if (_mTest[2][i] < _mTest[0][i]) ++w2;
			if (_mTest[1][i] < _mTest[2][i]) ++w12;
		}
		const float p1 = _BinomP(w1, kSeeds), p2 = _BinomP(w2, kSeeds), p12 = _BinomP(w12, kSeeds);
		const bool b1 = (w1 * 2u > kSeeds) && (p1 < 0.0167f);
		const bool b2 = (w2 * 2u > kSeeds) && (p2 < 0.0167f);
		const bool b12 = (w12 * 2u > kSeeds) && (p12 < 0.0167f);
		// ⭐ ④′ **팔이 살아 있나** — 학습 MSE 가 ㈀ 의 2배를 넘으면 그 팔은 **무효**다.
		float mR[kArms] = { 0.0f };
		for (uint32 a = 0; a < kArms; ++a)
		{
			double s = 0.0;
			for (uint32 i = 0; i < kSeeds; ++i) s += _mTrain[a][i];
			mR[a] = (float)(s / kSeeds);
		}
		bool alive[kArms] = { true, true, true };
		for (uint32 a = 1; a < kArms; ++a) alive[a] = (mR[a] <= 2.0f * mR[0]);

		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🧠 **은닉 한 겹 결과**\n");
		for (uint32 a = 0; a < kArms; ++a)
			LogA("[mlt] 🧠   %-10s · 시험 **%.5f** · OMP %.5f ⇒ **모델/OMP = %.2f** · ㉠ %u/%u ·"
			     " 살아있는 파라미터 %u%s\n",
				_ArmName(a), (double)mT[a], (double)mO[a], (double)rat[a], sign[a], kSeeds,
				MLTP2Enc::LiveParams(kLiveSlot, kN, kHid[a], kSwig[a]),
				(MLTP2Enc::LiveParams(kLiveSlot, kN, kHid[a], kSwig[a]) <= kBudget) ? "" : " ⛔예산초과");
		LogA("[mlt] 🧠   ── ⭐ ④′ 팔이 살아 있나(학습 MSE ≤ 2 × ㈀) ──\n");
		for (uint32 a = 0; a < kArms; ++a)
			LogA("[mlt] 🧠     %s %-10s 학습 **%.5f**%s\n", alive[a] ? "✅" : "⛔", _ArmName(a),
				(double)mR[a], (a == 0u) ? " (기준)" : "");
		LogA("[mlt] 🧠   ── 짝지은 부호검정(Q=3 ⇒ p<0.0167) ──\n");
		LogA("[mlt] 🧠     %s ㈁swiglu+norm vs ㈀ → **%u/%u**(p=%.5f)\n", b1 ? "✅" : "⛔", w1, kSeeds, (double)p1);
		LogA("[mlt] 🧠     %s ㈂선형+norm vs ㈀ → **%u/%u**(p=%.5f)\n", b2 ? "✅" : "⛔", w2, kSeeds, (double)p2);
		LogA("[mlt] 🧠     %s ㈁swiglu+norm vs ㈂선형+norm → **%u/%u**(p=%.5f)\n",
			b12 ? "✅" : "⛔", w12, kSeeds, (double)p12);
		LogA("[mlt] 🧠   %s ㉡ **OMP 대비 비** ㈁ = **%.2f** ≤ %.1f (㈀ = %.2f)\n",
			(rat[1] <= kOmpRatio) ? "✅" : "⛔", (double)rat[1], (double)kOmpRatio, (double)rat[0]);

		// ⭐ 등록한 갈래를 **그대로** 적용한다
		const char* branch = (!alive[1] || !alive[2])
			? "⚠️ **판정불가 — 팔이 죽었다**(학습 MSE 가 무너졌다 ⇒ 척도를 고치고 다시 잰다)"
			: (b1 && b12) ? "㈀ **SwiGLU 자체의 추가 효과**(공유 은닉+RMSNorm 경로보다도 낫다)"
			: (b2 && !b12) ? "㈁ **공유 은닉+RMSNorm 경로가 이유다**(RMSNorm 비선형 때문에 순수 용량 효과로는 못 읽는다)"
			: ((!b1 && !b2) ? "㈂ **정규화한 은닉 경로가 축이 아니다**"
			                  : "⚠️ **판정불가 — 세 대응 비교가 섞인 결과다**(씨앗별 표를 읽어라)");
		LogA("[mlt] 🧠   ⭐ 갈래 판정 = %s\n", branch);
		LogA("[mlt] 🧠   ⓘ 씨앗 %u — ", kWatchSeed);
		for (uint32 a = 0; a < kArms; ++a) LogA("%s %.5f  ", _ArmName(a), (double)_mTest[a][kWatchSeed]);
		LogA("\n[mlt] ══════════════════════════════════════════════════\n");
	}
};
