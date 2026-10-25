// mltmodel.cw — 🧠 **트랜스포머 몸통.** 커널 17장을 하나의 forward/backward 로 엮는다
//
// ★ **판정 ①②가 통과했다고 이것이 맞는다는 뜻이 아니다.** 그 둘은 **커널 하나씩**을 재고
//   이 파일은 **엮는 방식**이다 — 오프셋·전치·축·잔차 연결은 **전부 여기서만** 틀릴 수 있다.
//   ⇒ 그래서 **판정 ③(조립 검사)** 을 짝으로 둔다: *"고정 배치 하나를 외울 수 있나"*(과적합).
//     손실이 안 내려가면 조립이 틀린 것이다 — **gradcheck 로는 절대 안 보인다.**
//
// ══════════════════════════════════════════════════════════════════════════════
// 🏗 구조 — pre-norm · 바이어스 없음
// ══════════════════════════════════════════════════════════════════════════════
//   ```
//   x  = Φ(v) · Win + e_sym                       ← 슬롯 임베딩((심볼, 값) 의 그 식)
//   층마다:
//     h  = RMSNorm(x, g1)
//     q,k,v = h·Wq, h·Wk, h·Wv        RoPE(q), RoPE(k)     ← 위치는 여기서만 들어간다
//     P  = attn_softmax(q·kᵗ · scale, causal)              ← 인과 마스크
//     x += (P·v) · Wo
//     h2 = RMSNorm(x, g2)
//     x += swiglu(h2·Wg, h2·Wu) · Wd                       ← 「끄기」가 여기 있다
//   logits = RMSNorm(x, gf) · Wh
//   loss   = ce_logits(logits, target)                     ← 버킷 CE(MSE 아님)
//   ```
//
// ⚠️ **RoPE 는 잔차 흐름에 안 건다** — `q`/`k` 에만 건다(표준). 잔차에 걸면 층마다 위상이 누적된다.
// ⚠️ **어텐션은 `(배치, 헤드)` 마다 gemm 두 번**이다(`q·kᵗ` · `P·v`). P0 은 배치 8 · **헤드 1** 이라 8쌍.
//   ★ 그래도 새 커널이 0개다 — `gemm` 의 `transB` 가 `kᵗ` 를 해 준다.
//   ⚠️ **헤드를 1 로 내린 것은 취향이 아니다** — `gemm` 에 간격 인자가 없어서다(아래 `kHeads` 의 근거).
// ⚠️ **`beta = 1` 을 잔차와 기울기 누산에 쓴다**(`C = A·B + 1·C`) ⇒ 별도 덧셈 커널이 필요 없다.
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **P0 의 크기를 여기 등록한다** — ⚠️ 「미리 등록한 뒤에만 흔든다」
// ══════════════════════════════════════════════════════════════════════════════
//   문서의 기본 크기는 `d=256 · L=6 · H=8 · F=688 · ctx=512`(≈5M)인데 **P0 은 그보다 작게** 시작한다.
//   근거는 하나다: **라운드가 분 단위여야 한다**(이 저장소의 그 게이트). 우리 `gemm` 은 소박한
//   삼중 루프라 큰 판에서 시간이 통째로 거기 간다.
//   ★ 그리고 P0 은 **축 하나 · 버킷 65** 라 이 크기로 이미 과분하다(과적합 검사가 그것을 보여야 한다).
//   ⚠️ **크기를 성능 손잡이로 쓰지 않는다** — 단계가 안 서는데 키우면 무엇이 통과인지 알 수 없다.

using namespace PE;

struct MLTModelCfg
{
	// ⚠️⚠️ **이 셋은 「기본값」이다 — 회차 150 부터 `Setup` 이 런타임으로 받는다.**
	//   ★ 왜 런타임으로 만들었나(2026-08-31 · 회차 150): 회차 145·146·149 가 셋 다
	//     ***"무엇을 배우든 다른 것을 그만큼 잃는다"*** 를 냈고, 그것은 **용량 한계의 서명**이다.
	//     그런데 컴파일 상수면 **한 바이너리에 두 용량을 못 담아** 같은 회차에 대조군이 없고,
	//     이 트랙의 **씨앗 변동이 0.28~0.59 나트**(규율 51)라 ***짝지음 없이는 아무것도 못 읽는다.***
	//   ⇒ ★ 그래서 「상수만 바꿔 재보는 길」은 **원리적으로 쓸 수 없다**. 팔로 만들어야 한다.
	//   ⚠️ 셰이더는 **0줄** 바뀌었다 — `gemm` 등이 `M`/`N`/`K` 를 push constant 로 받고
	//     아레나 오프셋으로 말하기 때문이다(그 규약이 여기서 값을 냈다).
	static constexpr uint32 kDim   = 128u;   // d_model — **기본값**
	static constexpr uint32 kLayer = 4u;     // **기본값**
	// ⚠️ 컴파일 타임 배열(`MLTModel::_L` · `_tXs`/`_tDXs`)의 **상한**이다. 층을 이보다 늘리려면
	//   이 값을 올린다(⚠️ 그러면 그 배열이 커지지만 아레나는 `_layer` 만큼만 쓴다).
	static constexpr uint32 kLayerMax = 12u;
	// ⚠️⚠️ **P0 은 `H = 1` 이다** — `gemm` 에 **간격(stride) 인자가 없어서**(그 커널 주석이 못 박았다:
	//   «Q 가 행 간격 3D 인 조각이 되어 이 커널이 못 읽는다») 헤드를 **열 방향으로 자를 수 없다.**
	//   ★ `H = 1` 이면 배치 블록이 **행 방향으로 연속**이라 오프셋만으로 되고 **새 커널이 0개**다.
	//   ⇒ 멀티헤드는 **P1 의 일**이다(문서가 «헤드가 축에 붙는지 보려면 헤드가 많아야 한다» 고 적었다).
	//     그때 `[N,D] → [H][N,DH]` **재배치 커널 하나**를 더한다(그것이 정직한 최소 추가다).
	static constexpr uint32 kHeads = 1u;
	static constexpr uint32 kDHead = kDim / kHeads;        // = kDim
	static constexpr uint32 kFF    = 344u;                 // ≈ 8/3·d — **기본값**
	// ══════════════════════════════════════════════════════════════════════════
	// ⭐ **P1 부터 컨텍스트가 「시각 × 축」이다**(등록: `mltp1.cw` ③)
	// ══════════════════════════════════════════════════════════════════════════
	//   `행 r = t·A + a` — 시각 `t` 의 축 `a` 슬롯. 심볼은 **축마다 다르다**.
	//   ⚠️ P0 은 `A = 1 · kTime = 64 · kCtx = 64` 였다. P1 은 `A = 3 · kTime = 32 · kCtx = 96`.
	//     ★ 시각을 64 → 32 로 줄인 근거는 **라운드가 분 단위여야 한다**는 그 게이트이고,
	//       32 는 여전히 `hold = 12` 보다 길다(외삽할 재료가 컨텍스트에 있다).
	//   ⚠️⚠️ **P0 의 하네스는 `kCtx = 64` 로 등록됐다** — 그 회차를 재현하려면 그 커밋으로
	//     돌아가야 한다. 그래서 그 하네스들이 **크게 로그를 찍고 스스로 멈춘다**(조용히 다른 수를
	//     내지 않는다).
	static constexpr uint32 kAxes  = 3u;                   // A — 축(슬롯 종류) 수
	static constexpr uint32 kTime  = 32u;                  // 시각 수
	static constexpr uint32 kCtx   = kTime * kAxes;         // T = 96 (어텐션의 행/열)
	static constexpr uint32 kBatch = 8u;
	static constexpr uint32 kRows  = kBatch * kCtx;        // N = 768
	static constexpr uint32 kBuckets = 65u;                // V — ⑩ 홀수 · 0 중심

	// ⚠️ ⑪ 값 인코딩은 **P 에서 고정 상수**다(러닝 통계면 같은 값이 스텝마다 다른 Φ 를 갖는다).
	static constexpr uint32 kFreqs   = 8u;                 // Φ 의 주파수 수 ⇒ 폭 2F
	static constexpr uint32 kPhi     = kFreqs * 2u;        // 16
	static constexpr float  kVBias   = 0.0f;
	static constexpr float  kVScale  = 1.0f;
	static constexpr float  kFreqMin = 1.0f;
	// ★ **`kFreqMax` 는 「버킷 하나를 가를 수 있나」로 정한다** — ⚠️ P0 을 **재기 전에** 등록한다.
	//   P0 의 버킷폭은 `w = 2/65 = 0.030769` 다. 최상단 주파수 `ω` 에서 값이 `w` 만큼 움직이면
	//   `Φ` 의 그 쌍은 `ω·w` 라디안 돈다:
	//     · `ω = 8`  ⇒ 0.246 rad ⇒ `|ΔΦ| / |Φ| ≈ 8.7%`   ← **버킷을 겨우 가른다**
	//     · `ω = 32` ⇒ 0.985 rad ⇒ `|ΔΦ| / |Φ| ≈ 33%`    ← 이쪽을 쓴다
	//   ⚠️⚠️ 그리고 P0 이 실제로 요구하는 것은 값의 분해가 아니라 **차이(`y[t] − y[t−1]`)의 분해**다
	//     — 그 차이가 곧 `up·dt` 이고 외삽의 재료다. 분해력이 모자라면 증상이 *"안 배운다"* 이고
	//     **판정 ③(과적합)으로는 안 보인다**(그쪽은 위치로 외울 수 있다).
	//   ★ 주파수가 높아 한 주기가 짧아지는 것(ω=32 면 [−1,1] 에 10주기)은 문제가 아니다 —
	//     아래 주파수들이 그 모호성을 푼다(다주파 코드의 그 이유).
	//
	// ══════════════════════════════════════════════════════════════════════════
	// ⛔➡️✅ **32 → 8 로 내렸다**(회차 5 · 2026-08-24) — ⚠️ 근거는 성능이 아니라 **원리**다
	// ══════════════════════════════════════════════════════════════════════════
	//   실측(중간 난이도 · 판정 씨앗 12~23 · 24회 · 부호검정 **12/12**):
	//     ```
	//                 정확도    R̄      D̄_band     D̄_out
	//     freq =  8   62.33%   0.605   **−0.546**   0.679
	//     freq = 32   66.82%   0.682   **−9.883**   0.769
	//     ```
	//   ★ 밴드(물어본 적 없는 값 구간) 지표가 **18배** 갈린다. 기제는 위에 적은 그대로다:
	//     `ω=32` 면 밴드(폭 0.2)가 그 주파수에서 **1주기 이상**이라 `Φ` 가 이웃과 위상을 안 나눠
	//     갖고 **국소적으로 고유**해진다 ⇒ **룩업에 가까워진다.**
	//   ⇒ ***`kFreqMax` 는 정확도↔일반화의 손잡이다.***
	//
	//   ⚠️⚠️ **성능만 보면 32 가 낫다**(정확도 +4.5%p). 그래도 8 을 고른다 — `mltconcept.md` 의
	//     그 못: *"저쪽의 발견을 **손제작 특징으로 옮기면** 그 순간 실패다."* 고주파 인코딩은
	//     분해력을 손으로 주는 것이고, 그것이 하는 일이 **룩업을 쉽게 만드는 것**임을 이 회차가
	//     숫자로 보였다. 이 트랙이 원하는 것은 **표가 아니라 규칙**이다.
	//   ★ 그리고 이 결정은 「크기를 성능 손잡이로 쓰지 않는다」와 **어긋나지 않는다** —
	//     우리는 **더 나쁜 정확도를 일부러 고르고 있다**(최적화의 반대 방향이다).
	//   ⚠️ P1 에서 축이 둘 이상 되면 **교호작용이 있을 수 있으므로 두 값을 다시 재라**
	//     (`MLTModel::SetFreqMax` 가 그 손잡이다).
	//   ⚠️ 그리고 **8 에서도 `D̄_band` 가 음수다** ⇒ **인코딩으로 보간을 살 수는 없다.**
	//     P0 의 보간 관문은 **P1 의 물음으로 이월**한다(「이월」은 「통과」가 아니다).
	static constexpr float  kFreqMax = 8.0f;
	static constexpr float  kRopeTheta = 10000.0f;
	static constexpr float  kNormEps   = 1.0e-6f;

	// AdamW
	static constexpr float  kLr = 3.0e-3f, kB1 = 0.9f, kB2 = 0.999f, kAdamEps = 1.0e-8f, kWd = 0.0f;
	// ══════════════════════════════════════════════════════════════════════════
	// ⏱️⏱️ **`kPool` — 「스텝마다 업로드하지 마라」의 그 자리**
	// ══════════════════════════════════════════════════════════════════════════
	//   `MLArena::Write` 의 주석이 못 박아 뒀다: *"동기이고 무겁다(스테이징 + 큐 유휴 대기) —
	//   **스텝마다 부르지 마라**"*. ⚠️ 그런데 P0·P1 의 하네스가 **정확히 그것을 하고 있었다.**
	//   ★ 실측(같은 모델 · 같은 크기 · 같은 디스패치):
	//     ```
	//     판정 ③ (배치를 처음 한 번만 올린다)     렌더CPU **5~10ms**
	//     P1 라운드 (스텝마다 올린다)              렌더CPU **250~400ms**   ← 30~60배
	//     ```
	//   ⇒ 비용이 거의 전부 **동기 업로드가 GPU 파이프라인을 비우는 것**이었다.
	//   ⇒ ★ `kPool` 스텝 분량을 **한 번에** 올리고 스텝마다 **오프셋만** 옮긴다.
	//     ⚠️ **결과가 안 바뀐다** — 같은 데이터를 같은 순서로 본다(순수 배관 개선이다).
	//   ⚠️ 대가는 아레나다: `2 × kPool × N` float. `kPool = 32 · N = 768` ⇒ 49,152 float(0.2MB).
	//   ⚠️ **32 → 64 로 올렸다**(회차 52) — 문맥 수 스윕이 `512 문맥 = 64 풀 스텝`을 요구한다.
	//     대가는 아레나뿐이고(`3 × kPool × N` float · N=832 이면 0.6MB) **결과는 안 바뀐다**
	//     (파라미터가 먼저 잡히므로 오프셋이 안 밀린다 · 옛 호출부는 `nSteps ≤ kPool` 이라 그대로다).
	//   ⚠️⚠️ **64 → 256 으로 올렸다**(회차 187) — `64` 는 **512 문맥에 정확히 꽉 찬** 값이었고
	//     문맥을 **2048** 로 늘리자 `UploadPool` 이 `nSteps > kPool` 로 **조용히 false** 를 냈다
	//     (하네스는 *"학습 풀 업로드 실패"* 만 찍는다 ⇒ ★ 상한이 원인임을 코드에서 찾아야 했다).
	//     ★ 근거 = 회차 186 의 손계산: **파라미터 ÷ 학습 표적 = 246배**(과적합) ⇒ **표본을 늘린다**.
	//     ⚠️ 대가는 아레나 `3 × 256 × 896` float = **2.75MB**(아레나 79.5MB 중) ⇒ 싸다.
	//     ⭐ **결과는 안 바뀐다** — 옛 호출부는 전부 `nSteps ≤ 64` 라 그대로 돈다.
	//   ⚠️⚠️⚠️ **256 → 1024 로 올렸다**(회차 194) — 문맥 **8192** 는 `nSteps = 8192/8 = 1024` 다.
	//     ★ 이것이 **세 번째**로 같은 자리를 밟는 것이다(32→64→256→1024) ⇒ ⭐ 규칙으로 적어 둔다:
	//       ***`kPool` 은 「문맥 ÷ 배치」의 상한이다*** — 문맥을 늘리는 회차는 **여기를 먼저 본다.**
	//     ⚠️ 대가는 아레나 `3 × 1024 × 896` float = **11.0MB**(아레나 79.5MB 중) ⇒ 여전히 싸다.
	static constexpr uint32 kPool = 1024u;
	static constexpr uint32 kNoIgnore = 0xFFFFFFFFu;
	// ★ **표적을 손실에서 뺄 때 쓰는 센티널.** ⚠️ `kNoIgnore`(0xFFFFFFFF)를 표적 자리에 넣으면
	//   안 된다 — 표적 버퍼는 **float** 이고 `4294967295` 는 float 로 정확히 안 담긴다
	//   (반올림 뒤 uint 캐스팅이 범위를 넘어 **정의되지 않는다**).
	//   ⭐ 커널이 이미 `t >= cols` 를 무효로 접으므로(fwd 는 손실 0 · bwd 는 기울기 **0 을 쓴다**)
	//     **범위 밖 정수 하나**면 되고 `65.0f` 는 float 로 정확하다. ⇒ 함정을 원리적으로 없앤 자리.
	static constexpr float  kIgnoreTgt = (float)kBuckets;

	// ⚠️ **기본 크기의 파라미터 수**다 — 어휘를 연 뒤(회차 49)의 실제 수는 `MLTModel::_ParamNeed()`
	//   가 계산한다(`symVocab`/`outVocab` 이 런타임 값이다). 이 함수는 문서·기본값용으로 남긴다.
	static uint32 ParamCount()
	{
		return kPhi * kDim + kAxes * kDim               // Win + e_sym(**축마다 하나**)
			+ kLayer * (kDim * 2u                        // g1, g2
				+ kDim * kDim * 4u                       // Wq,Wk,Wv,Wo
				+ kDim * kFF * 2u + kFF * kDim)          // Wg,Wu,Wd
			+ kDim + kDim * kBuckets;                    // gf + Wh
	}
};

// 층 하나의 파라미터/활성 오프셋 — ⚠️ **오프셋이 이 파일의 유일한 위험**이다.
struct MLTLayer
{
	// 파라미터
	MLTensor g1, wq, wk, wv, wo, g2, wg, wu, wd;
	// 활성(backward 가 읽는다)
	//   ★ `xm` = **어텐션 잔차를 더한 뒤**의 흐름이다. ⚠️ 이것을 안 남기면 `rmsnorm2` 의 bwd 가
	//     자기 입력을 못 본다 — 그래서 잔차 흐름을 **덮어쓰지 않고 지점마다 따로 둔다**(`_tXs[]`).
	MLTensor h, rstd1, q, k, vv, prob, att, xm, h2, rstd2, ga, gb, sw;
	// 기울기(활성 쪽) — ★ `ds` = softmax **입력**의 기울기(제자리로 쓰면 안 되는 자리)
	MLTensor dh, dq, dk, dvv, dprob, ds, datt, dxm, dh2, dga, dgb, dsw;
};

class MLTModel
{
public:
	// ══════════════════════════════════════════════════════════════════
	// 🏗 아레나에 자리를 잡는다. ⚠️ `Alloc` 은 해제가 없다 ⇒ **한 번만** 부른다.
	// ══════════════════════════════════════════════════════════════════
	// ══════════════════════════════════════════════════════════════════
	// 🔩 **어휘를 인자로 연다**(회차 49) — `symVocab` = 심볼 어휘 · `outVocab` = 출력 헤드 폭.
	//   ⚠️ 기본값을 주면 **P0/P1 호출부가 한 줄도 안 바뀐다**(그리고 그때 파라미터 블록이
	//     한 바이트도 안 달라진다 — 회차 49 의 「비트 동일」 관문이 그것을 검사한다).
	//   ★ 근거: 활성 토큰은 `320 + N` 대역이라 어휘가 1000+ 여야 하는데, 원핫 gemm 은
	//     `[N,V]` 원핫(수 MB)과 `N·D·V` MAC 이라 소박한 삼중 루프로는 못 돈다 → `embed` 게더.
	// ══════════════════════════════════════════════════════════════════
	// 🔩 **회차 50 — 슬롯 배치도 인자다**: `axes` = 한 시각의 슬롯 수 · `timeSteps` = 시각 수.
	//   ⚠️ 기본값이 P0/P1 의 등록값이라 **옛 호출부가 한 줄도 안 바뀐다**(그리고 그때 아레나·파라미터·
	//     손실 수열이 **비트 동일**이어야 한다 — 회차 50 의 선행 관문이 그것을 검사한다).
	//   ★ P3 은 한 시각이 **상태 5 + 활성 8 = 13 슬롯**이라 `axes = 13` 이 필요했고, 그것이
	//     `kAxes = 3` 이라는 컴파일 상수에 막혀 있었다.
	//   ⚠️⚠️ 옛 하네스들은 자기 배열을 `MLTModelCfg::kRows` 로 잡는다 ⇒ **기본값으로 부르는 한**
	//     그대로 맞는다. 다른 배치를 쓰는 쪽은 `Rows()`/`Ctx()`/`Axes()` 를 물어야 한다.
	// ⭐ `dim`/`layer`/`ff` 는 **회차 150 에서 열었다** — 기본값을 주면 예전과 **비트 동일**이다
	//   (그것이 이 변경의 회귀 관문이고, 회차 145 를 되재서 확인한다).
	//   ⚠️ `layer <= MLTModelCfg::kLayerMax` 여야 한다(컴파일 타임 배열 상한).
	//   ⚠️ `dim` 은 `kHeads` 로 나눠져야 한다(`kDHead`) — `kHeads = 1` 이라 지금은 늘 참이다.
	bool Setup(RHI* rhi, uint32 symVocab = MLTModelCfg::kAxes, uint32 outVocab = MLTModelCfg::kBuckets,
		uint32 axes = MLTModelCfg::kAxes, uint32 timeSteps = MLTModelCfg::kTime,
		uint32 dim = MLTModelCfg::kDim, uint32 layer = MLTModelCfg::kLayer,
		uint32 ff = MLTModelCfg::kFF)
	{
		typedef MLTModelCfg C;
		if (symVocab == 0u || outVocab < 2u || axes == 0u || timeSteps == 0u) return false;
		if (dim == 0u || layer == 0u || ff == 0u) return false;
		if (layer > C::kLayerMax) { LogA("[mlt] ③ 층 %u > kLayerMax %u\n", layer, C::kLayerMax); return false; }
		if (dim % C::kHeads != 0u) { LogA("[mlt] ③ d=%u 가 헤드 %u 로 안 나눠진다\n", dim, C::kHeads); return false; }
		_dim = dim; _layer = layer; _ff = ff;
		_axes = axes; _time = timeSteps; _ctx = _time * _axes; _rows = C::kBatch * _ctx;
		if (symVocab < _axes) return false;   // 심볼 어휘는 최소한 슬롯 종류를 담아야 한다
		_symVocab = symVocab; _outVocab = outVocab;
		// ⚠️ 어휘가 기본값을 넘으면 원핫 경로가 성립하지 않는다(`_tOnes` 가 `[N, kAxes]` 다)
		//   ⇒ 그때는 `embed` 경로로 **못 박는다**(조용히 틀린 수를 내지 않는다).
		if (_symVocab != _axes) _useEmbed = true;
		const uint32 N = _rows, D = _dim, F = _ff, T = _ctx, V = _outVocab;
		const uint32 PH = C::kBatch * C::kHeads * T * T;   // 어텐션 확률 전체

		// ⚠️ `robustBufferAccess` 가 꺼져 있어 범위 밖 쓰기는 **정의되지 않는다** ⇒ 항마다 세서 적는다.
		const uint32 need =
			  _ParamNeed() * 4u                             // 파라미터 + 기울기 + m + v
			+ (_layer + 1u) * N * D * 2u                  // 잔차 흐름 `_tXs`/`_tDXs`
			+ _layer * (14u * N * D + 6u * N * F + 3u * PH + 2u * N)
			+ N * (2u * C::kPhi + 2u * D + 3u * V + 4u + _axes)   // Φ/dΦ · hf/dhf · logit/probs/dlogit · rstdF,loss,pos,dval · onehot
			+ N * (D + C::kPool)                             // 🔩 심볼 임베딩 스크래치 + 심볼 **풀**
			+ N * C::kPool * 2u                                      // 값·표적 **풀**
			+ 4096u;

		if (!_ar.Create(rhi, need)) { LogA("[mlt] ③ 아레나 생성 실패(need=%u)\n", need); return false; }

		// ⚠️ **다시 부를 수 있다**(판정 ③ 이 팔마다 부른다) ⇒ 스텝도 되돌려야 편향보정이 맞는다.
		_step = 0u;

		// ── 파라미터 ────────────────────────────────────────────────
		_pWin = _ar.Alloc(C::kPhi, D);  _pSym = _ar.Alloc(_symVocab, D);
		for (uint32 l = 0; l < _layer; ++l)
		{
			MLTLayer& L = _L[l];
			L.g1 = _ar.Alloc(1, D);
			L.wq = _ar.Alloc(D, D); L.wk = _ar.Alloc(D, D); L.wv = _ar.Alloc(D, D); L.wo = _ar.Alloc(D, D);
			L.g2 = _ar.Alloc(1, D);
			L.wg = _ar.Alloc(D, F); L.wu = _ar.Alloc(D, F); L.wd = _ar.Alloc(F, D);
		}
		_pGf = _ar.Alloc(1, D); _pWh = _ar.Alloc(D, V);
		_pEnd = _ar.Used();
		_pCount = _pEnd;   // 파라미터는 오프셋 0..(_pCount-1) 에 연속으로 산다

		// ── 파라미터 기울기 · AdamW 상태 (파라미터와 **같은 모양**을 통째로) ──
		_gBase = _ar.Alloc(1, _pCount).offset;
		_mBase = _ar.Alloc(1, _pCount).offset;
		_vBase = _ar.Alloc(1, _pCount).offset;

		// ── 입출력 ──────────────────────────────────────────────────
		// ★ 값·표적은 **풀**이다(위 `kPool` 의 그 이유). 스텝 `k` 는 `k*N` 칸부터 쓴다.
		_tVal = _ar.Alloc(C::kPool, N); _tTgt = _ar.Alloc(C::kPool, N);
		_tPhi = _ar.Alloc(N, C::kPhi); _tDPhi = _ar.Alloc(N, C::kPhi);
		// ★ 잔차 흐름을 **지점마다** 잡는다(덮어쓰기 금지) — `_tXs[l]` 이 층 `l` 에 **들어가는** 흐름이고
		//   `_tXs[kLayer]` 가 마지막 norm 에 들어가는 흐름이다.
		for (uint32 l = 0; l <= _layer; ++l) { _tXs[l] = _ar.Alloc(N, D); _tDXs[l] = _ar.Alloc(N, D); }
		_tHf = _ar.Alloc(N, D); _tDHf = _ar.Alloc(N, D);
		_tRstdF = _ar.Alloc(1, N);
		_tLogit = _ar.Alloc(N, V); _tProbs = _ar.Alloc(N, V); _tDLogit = _ar.Alloc(N, V);
		_tLoss = _ar.Alloc(1, N);
		_tPos = _ar.Alloc(1, N);               // RoPE 의 위치 = 그 토큰의 t
		// ★ **심볼 원핫** `[N, A]` — `onehot · pSym[A,D]` 을 `beta = 1` 로 누산하면
		//   **행마다 자기 축의 심볼 벡터**가 더해진다. ⭐ P0 의 `_tOnes`(`[N,1]·[1,D]`) 트릭의
		//   **일반화**이고 **새 커널이 0개**다. bwd 는 `dSym = onehotᵗ · dX`(`transA` gemm 한 방).
		// ⚠️⚠️ **2026-08-25(회차 49)에 이 결정이 뒤집혔다 — 근거를 적는다.** 여기 원래
		//   *"`embed` 를 쓰면 판정 ①② 를 새로 통과시켜야 하니 그 값을 벌 이유가 없다"* 라고 적혀 있었다.
		//   그 근거는 **어휘가 셋일 때만** 참이다. P3 의 활성 토큰은 `320 + N` 대역이라 어휘가 1000+ 이고,
		//   그러면 원핫이 `[N, V]`(수 MB) · gemm 이 `N·D·V`(수억 MAC)라 **소박한 삼중 루프로는 못 돈다.**
		//   ★ 그리고 `embed`/`embed_bwd` 는 형제 트랙에서 **이미 판정 ①② 를 통과했다** ⇒ 새 커널이 0개다.
		//   ⇒ 두 경로를 **둘 다** 두고 `SetSymbolPath` 로 가른다 — 그것이 회차 49 의 **비트 동일 A/B**
		//     이고(등록된 관문), 그 A/B 가 이 스위치의 존재 이유다.
		_tOnes = _ar.Alloc(N, _axes);
		// 🔩 `embed` 경로의 둘 — 행마다 **심볼 id**(아레나 규약대로 float) + 게더 결과 스크래치.
		//   ⚠️⚠️ **심볼도 풀이다**(회차 50) — P3 에서는 **스텝마다 심볼이 달라진다**(활성 id 가 프레임의
		//     함수다). 스텝마다 `Write` 하면 그것이 `kPool` 주석이 못 박은 **30~60배 함정**이다.
		_tSym  = _ar.Alloc(C::kPool, N);
		_tSymE = _ar.Alloc(N, D);
		// ⭐ 기제 관문(㉡)용 — 값 슬롯의 기울기. `val_enc_bwd` 가 여기 쓴다.
		_tDVal = _ar.Alloc(1, N);
		// ★ **복사 전용 1×1 텐서.** 이 저장소에는 복사 커널이 없다. 그런데 잔차를 지점마다
		//   따로 두려면 `dst = src` 가 필요하다. ⇒ `[n,1] · [1,1]`(그 칸이 1.0) 인 gemm 이
		//   정확히 **O(n) 복사**다(`beta = 1` 이면 누산 복사). ⭐ 새 커널이 0개다.
		//   ⚠️ 항등행렬 `[D,D]` 로 하면 `n·D` 배가 된다 — 그 함정을 피한 자리다.
		_tUnit = _ar.Alloc(1, 1);

		// ── 층별 활성/기울기 ───────────────────────────────────────
		for (uint32 l = 0; l < _layer; ++l)
		{
			MLTLayer& L = _L[l];
			L.h = _ar.Alloc(N, D); L.rstd1 = _ar.Alloc(1, N);
			L.q = _ar.Alloc(N, D); L.k = _ar.Alloc(N, D); L.vv = _ar.Alloc(N, D);
			L.prob = _ar.Alloc(1, PH); L.att = _ar.Alloc(N, D); L.xm = _ar.Alloc(N, D);
			L.h2 = _ar.Alloc(N, D); L.rstd2 = _ar.Alloc(1, N);
			L.ga = _ar.Alloc(N, F); L.gb = _ar.Alloc(N, F); L.sw = _ar.Alloc(N, F);
			L.dh = _ar.Alloc(N, D); L.dq = _ar.Alloc(N, D); L.dk = _ar.Alloc(N, D); L.dvv = _ar.Alloc(N, D);
			L.dprob = _ar.Alloc(1, PH); L.ds = _ar.Alloc(1, PH);
			L.datt = _ar.Alloc(N, D); L.dxm = _ar.Alloc(N, D);
			L.dh2 = _ar.Alloc(N, D); L.dga = _ar.Alloc(N, F); L.dgb = _ar.Alloc(N, F); L.dsw = _ar.Alloc(N, F);
		}
		if (!_tUnit.IsValid() || !_L[_layer - 1u].dsw.IsValid())
		{ LogA("[mlt] ③ 텐서 할당 실패(need=%u · used=%u)\n", need, _ar.Used()); return false; }

		// ⚠️ `freqMax` 를 **여기서 찍는다** — 그것이 이 트랙에서 결론을 가른 손잡이인데
		//   런타임 값이라 소스만 보면 무엇이 실제로 쓰였는지 모른다(「추론 말고 읽어 대조」).
		LogA("[mlt] ③ 아레나 %u float(%.1f MB) · 파라미터 %u · 층 %u · d=%u H=%u F=%u T=%u B=%u V=%u"
		     " · **freqMax=%.0f**\n",
			_ar.Used(), (double)_ar.Used() * 4.0 / 1048576.0, _pCount,
			_layer, D, C::kHeads, F, T, C::kBatch, V, (double)_freqMax);
		return _LoadKernels(rhi) && _InitParams();
	}

	// 값 시계열과 표적을 올린다. `val[N]` · `tgt[N]`(버킷 id 를 float 에 담는다)
	//   ★ `tgt[r] == kIgnoreTgt` 는 **그 행을 손실에서 뺀다**(⑫ 보간 홀드아웃이 이것을 쓴다).
	//   ⚠️⚠️ 그러면 `lossScale = 1/N` 이 **틀린다** — 유효 행이 N 보다 적다. 그래서 여기서 세어 둔다.
	//     ★ 커널은 행을 안 센다(리덕션이 필요하고, 무엇보다 "유효행" 의 정의가 채널마다 다르다)
	//     ⇒ **배관의 판단**이라는 그 계약 그대로다.
	//   ⚠️⚠️ **한 스텝만 올리는 판이다** — 편의용이고, 훈련 루프는 `UploadPool` 을 써야 한다
	//     (그 이유는 `kPool` 의 그 ⏱️⏱️).
	bool Upload(const Array<float>& val, const Array<float>& tgt)
	{
		typedef MLTModelCfg C;
		if (val.Count() != _rows || tgt.Count() != _rows) return false;
		Array<float> v1 = val, t1 = tgt;
		if (!UploadPool(v1, t1, 1u)) return false;
		SelectStep(0u);
		return true;
	}

	// ══════════════════════════════════════════════════════════════════
	// ⏱️ **여러 스텝 분량을 한 번에 올린다.** `val`/`tgt` 는 `nSteps × kRows` 여야 한다.
	//   ★ 이것이 「스텝마다 업로드하지 마라」의 실행이다 — 실측 30~60배(위 `kPool`).
	// ══════════════════════════════════════════════════════════════════
	bool UploadPool(const Array<float>& val, const Array<float>& tgt, uint32 nSteps)
	{
		typedef MLTModelCfg C;
		if (nSteps == 0u || nSteps > C::kPool) return false;
		const uint32 need = nSteps * _rows;
		if (val.Count() != need || tgt.Count() != need) return false;
		// ⚠️ 유효 행을 **스텝마다** 센다 — 홀드아웃이 스텝마다 다르다.
		for (uint32 k = 0; k < nSteps; ++k)
		{
			uint32 v = 0u;
			for (uint32 i = 0; i < _rows; ++i)
			{
				const float x = tgt[k * _rows + i];
				if (x >= 0.0f && x < (float)_outVocab) ++v;
			}
			if (v == 0u) { LogA("[mlt] ③ 스텝 %u 의 유효 행이 0 이다\n", k); return false; }
			_poolValid[k] = v;
			// ⚠️⚠️ **진실 접촉을 센다** — `mltconcept.md`: *"「정답을 안 쓴다」고 적기 전에
			//   진실에 몇 번 닿는지 센다(계수기를 붙인다)."*
			//   ★ 표적은 **시뮬 진실**이다(`bucket(y[t+1])`). 다음 스텝 손실이 그 첫 소비자이고,
			//     신뢰가 「실현 오차」로 채워지면 그것이 **두 번째 소비자**가 된다.
			//   ⇒ 그때 이 계수기가 «접촉이 몇 배 늘었나» 를 말한다.
			_truth += v;
		}
		MLTensor vt = _tVal; vt.rows = nSteps;
		MLTensor tt = _tTgt; tt.rows = nSteps;
		return _ar.Write(vt, val) && _ar.Write(tt, tgt);
	}

	// 이번 스텝이 풀의 몇 번째를 쓰나. ⚠️ `Forward`/`Backward` 보다 **먼저** 부른다.
	void SelectStep(uint32 k)
	{
		_poolK = (k < MLTModelCfg::kPool) ? k : 0u;
		_valid = _poolValid[_poolK];
	}
	uint32 PoolSize() const { return MLTModelCfg::kPool; }

	uint32 Valid() const { return _valid; }

	// ★ **인코딩 주파수 상한을 런타임으로 흔든다** — 회차 5 가 `8 vs 32` 를 가른다.
	//   ⚠️ 기본값은 `MLTModelCfg::kFreqMax` 이고 **등록된 값이 정본**이다. 이 setter 는
	//     「띄워 놓고 끊어서 재라」의 그 손잡이일 뿐이고, **성능 손잡이로 쓰지 않는다**.
	//   ★ 파라미터 초기화가 이 값에 안 달렸으므로(Φ 는 입력 변환이다) `Setup` 뒤에 바꿔도 된다.
	void SetFreqMax(float f) { _freqMax = f; }
	float FreqMax() const { return _freqMax; }

	// ══════════════════════════════════════════════════════════════════
	// ▶️ forward — ⚠️ 활성을 **전부 남긴다**(backward 가 읽는다).
	// ══════════════════════════════════════════════════════════════════
	bool Forward()
	{
		typedef MLTModelCfg C;
		const uint32 N = _rows, D = _dim, F = _ff, T = _ctx, V = _outVocab;
		const float scale = 1.0f / Sqrt((float)(_dim / C::kHeads));

		// ① 슬롯 임베딩 — Φ(v) · Win, 그리고 심볼 벡터를 모든 행에.
		{
			MLValEncParams p{}; p.inOff = _tVal.offset + _poolK * N; p.outOff = _tPhi.offset;
			p.rows = N; p.freqs = C::kFreqs; p.vBias = C::kVBias; p.vScale = C::kVScale;
			p.freqMin = C::kFreqMin; p.freqMax = _freqMax;
			if (!_k[kVal].Dispatch(C::kFreqs, N, 1u, &p, (uint32)sizeof(p))) return _E("val_enc");
		}
		if (!_Gemm(_tPhi, _pWin, _tXs[0], N, D, C::kPhi)) return _E("phi·Win");
		// ⚠️ 행마다 **자기 축의** 심볼 벡터를 더한다 — `[N,A] · [A,D]` 을 `beta = 1` 로 누산한다.
		//   ⭐ 원핫이라 이 gemm 이 곧 임베딩 조회다(별도 커널이 없다).
		// 🔩 두 경로는 **수학적으로 같은 식**이다 — 원핫 합은 `0 + … + Sym[a][d] + … + 0` 이고
		//   `embed` 게더는 그 값을 바로 쓴다. 둘 다 `_tXs[0]` 에 `beta = 1` 로 더한다 ⇒ **비트 동일**.
		if (_useEmbed)
		{
			MLEmbedParams p{}; p.tokOff = _tSym.offset + _poolK * N; p.aOff = _pSym.offset;
			p.bOff = _tSymE.offset; p.seqLen = N; p.dim = D; p.vocab = _symVocab;
			if (!_k[kEmb].Dispatch(D, N, 1u, &p, (uint32)sizeof(p))) return _E("embed(sym)");
			if (!_Copy(_tSymE, _tXs[0], 1.0f)) return _E("+e_sym(embed)");
		}
		else if (!_Gemm(_tOnes, _pSym, _tXs[0], N, D, _axes, 0u, 0u, 1.0f)) return _E("+e_sym");

		for (uint32 l = 0; l < _layer; ++l)
		{
			MLTLayer& L = _L[l];
			// ② pre-norm
			if (!_Rms(_tXs[l], L.g1, L.h, L.rstd1)) return _E("rmsnorm1");
			// ③ q,k,v
			if (!_Gemm(L.h, L.wq, L.q,  N, D, D)) return _E("q");
			if (!_Gemm(L.h, L.wk, L.k,  N, D, D)) return _E("k");
			if (!_Gemm(L.h, L.wv, L.vv, N, D, D)) return _E("v");
			// ④ RoPE — q,k 에만(잔차엔 안 건다). ⚠️ **제자리**다: 스레드가 자기 쌍의 유일한 주인이다.
			if (!_Rope(L.q, 1.0f)) return _E("rope(q)");
			if (!_Rope(L.k, 1.0f)) return _E("rope(k)");
			// ⑤ 어텐션 — ⚠️ `H = 1` 이라 **배치 블록이 행 방향으로 연속**이다(오프셋만 쓴다).
			for (uint32 b = 0; b < C::kBatch; ++b)
			{
				const uint32 ro = b * T * D;   // q/k/v/att 의 배치 b 블록 = [T, D] 연속
				const uint32 po = b * T * T;   // prob 의 배치 b 블록 = [T, T] 연속
				// S = q·kᵗ  (⭐ `transB = 1` 이 그 전치를 해 준다 — 새 커널이 없다)
				if (!_Gemm(L.q, L.k, L.prob, T, T, D, 0u, 1u, 0.0f, ro, ro, po)) return _E("q·kT");
				// 인과 마스크 softmax — **제자리**(행 하나 = 스레드 하나이므로 안전하다)
				MLAttnSoftmaxParams sp{};
				sp.inOff = L.prob.offset + po; sp.outOff = L.prob.offset + po;
				sp.rows = T; sp.cols = T; sp.causalOff = 0u; sp.scale = scale;
				if (!_k[kAttn].Dispatch(T, 1u, 1u, &sp, (uint32)sizeof(sp))) return _E("attn_softmax");
				// O = P·v
				if (!_Gemm(L.prob, L.vv, L.att, T, D, T, 0u, 0u, 0.0f, po, ro, ro)) return _E("P·v");
			}
			// ⑥ 잔차 ①: `xm = x + att·Wo` — ★ 복사 뒤 `beta = 1` 로 누산한다
			if (!_Copy(_tXs[l], L.xm)) return _E("xm = x");
			if (!_Gemm(L.att, L.wo, L.xm, N, D, D, 0u, 0u, 1.0f)) return _E("att·Wo(+x)");
			// ⑦ pre-norm 2 → SwiGLU → 잔차 ②
			if (!_Rms(L.xm, L.g2, L.h2, L.rstd2)) return _E("rmsnorm2");
			if (!_Gemm(L.h2, L.wg, L.ga, N, F, D)) return _E("h2·Wg");
			if (!_Gemm(L.h2, L.wu, L.gb, N, F, D)) return _E("h2·Wu");
			{
				MLSwigluParams p{}; p.aOff = L.ga.offset; p.bOff = L.gb.offset;
				p.outOff = L.sw.offset; p.count = N * F;
				if (!_k[kSwi].Dispatch(N * F, 1u, 1u, &p, (uint32)sizeof(p))) return _E("swiglu");
			}
			if (!_Copy(L.xm, _tXs[l + 1u])) return _E("x' = xm");
			if (!_Gemm(L.sw, L.wd, _tXs[l + 1u], N, D, F, 0u, 0u, 1.0f)) return _E("sw·Wd(+xm)");
		}

		// ⑧ 최종 norm → 로짓 → CE
		if (!_Rms(_tXs[_layer], _pGf, _tHf, _tRstdF)) return _E("rmsnormF");
		if (!_Gemm(_tHf, _pWh, _tLogit, N, V, D)) return _E("hf·Wh");
		{
			MLCeLogitsParams p{}; p.logitsOff = _tLogit.offset; p.targetOff = _tTgt.offset + _poolK * N;
			p.probsOff = _tProbs.offset; p.lossOff = _tLoss.offset;
			p.rows = N; p.cols = V; p.ignoreIdx = C::kNoIgnore;
			if (!_k[kCe].Dispatch(N, 1u, 1u, &p, (uint32)sizeof(p))) return _E("ce_logits");
		}
		return true;
	}

	// ══════════════════════════════════════════════════════════════════
	// ◀️ backward
	//
	// ★ **가중치 기울기는 전부 `beta = 0` 이다.** 각 가중치가 그래프에 **정확히 한 번**
	//   나오므로 gemm 한 방이 그 기울기의 유일한 필자다 ⇒ **기울기를 0 으로 지우는 커널이
	//   필요 없다**(이 저장소에 fill 커널이 없는데 그것이 문제가 안 되는 이유).
	//   ⚠️ 여러 갈래가 모이는 것은 **활성 기울기**뿐이고 그쪽에서만 `beta = 1` 을 쓴다:
	//     `dh` ← q·k·v 셋 · `dxm` ← SwiGLU 갈래 + 건너가기 · `dX[l]` ← 어텐션 갈래 + 건너가기.
	//   ⚠️⚠️ 그리고 그 셋은 **순서가 있다**: `rmsnorm_bwd` 가 `dIn` 을 **덮어쓰므로** 먼저 부르고,
	//     건너가기 갈래를 `_Copy(..., 1.0f)` 로 **그 뒤에** 더한다. 뒤집으면 조용히 한 갈래가 사라진다.
	// ══════════════════════════════════════════════════════════════════
	bool Backward()
	{
		typedef MLTModelCfg C;
		const uint32 N = _rows, D = _dim, F = _ff, T = _ctx, V = _outVocab;
		const uint32 L = _layer;
		const float scale = 1.0f / Sqrt((float)(_dim / C::kHeads));
		// ⚠️⚠️ fwd 의 `loss[r]` 합에는 이 배율이 **안 들어있다** — 곡선을 찍는 쪽(`ReadLoss`)이
		//   같은 배율로 나눠야 기울기와 **같은 목적함수**를 보는 것이 된다.
		//   ★ 분모는 `N` 이 아니라 **유효 행 수**다(홀드아웃으로 뺀 행이 있다).
		const float ls = 1.0f / (float)((_valid > 0u) ? _valid : N);

		// ⑧′ CE → 로짓 → 헤드 → 최종 norm
		{
			MLCeLogitsBwdParams p{};
			p.probsOff = _tProbs.offset; p.targetOff = _tTgt.offset + _poolK * N; p.dLogitsOff = _tDLogit.offset;
			p.rows = N; p.cols = V; p.ignoreIdx = C::kNoIgnore; p.lossScale = ls;
			if (!_k[kCeB].Dispatch(V, N, 1u, &p, (uint32)sizeof(p))) return _E("ce_logits_bwd");
		}
		if (!_Gemm(_tHf, _tDLogit, _G(_pWh), D, V, N, 1u, 0u)) return _E("dWh");
		if (!_Gemm(_tDLogit, _pWh, _tDHf, N, D, V, 0u, 1u)) return _E("dHf");
		if (!_RmsG(_tXs[L], _tRstdF, _tDHf, _G(_pGf))) return _E("dGf");
		if (!_RmsB(_tXs[L], _pGf, _tRstdF, _tDHf, _tDXs[L])) return _E("dXf");

		for (uint32 li = L; li-- > 0; )
		{
			MLTLayer& Ly = _L[li];
			// ⑦′ SwiGLU 갈래
			if (!_Gemm(_tDXs[li + 1u], Ly.wd, Ly.dsw, N, F, D, 0u, 1u)) return _E("dSw");
			if (!_Gemm(Ly.sw, _tDXs[li + 1u], _G(Ly.wd), F, D, N, 1u, 0u)) return _E("dWd");
			{
				MLSwigluBwdParams p{};
				p.aOff = Ly.ga.offset; p.bOff = Ly.gb.offset; p.dOutOff = Ly.dsw.offset;
				p.dAOff = Ly.dga.offset; p.dBOff = Ly.dgb.offset; p.count = N * F;
				if (!_k[kSwiB].Dispatch(N * F, 1u, 1u, &p, (uint32)sizeof(p))) return _E("swiglu_bwd");
			}
			if (!_Gemm(Ly.dga, Ly.wg, Ly.dh2, N, D, F, 0u, 1u, 0.0f)) return _E("dh2(g)");
			if (!_Gemm(Ly.dgb, Ly.wu, Ly.dh2, N, D, F, 0u, 1u, 1.0f)) return _E("dh2(u)");
			if (!_Gemm(Ly.h2, Ly.dga, _G(Ly.wg), D, F, N, 1u, 0u)) return _E("dWg");
			if (!_Gemm(Ly.h2, Ly.dgb, _G(Ly.wu), D, F, N, 1u, 0u)) return _E("dWu");
			if (!_RmsG(Ly.xm, Ly.rstd2, Ly.dh2, _G(Ly.g2))) return _E("dG2");
			if (!_RmsB(Ly.xm, Ly.g2, Ly.rstd2, Ly.dh2, Ly.dxm)) return _E("dXm");
			if (!_Copy(_tDXs[li + 1u], Ly.dxm, 1.0f)) return _E("dXm += dX(건너가기)");

			// ⑥′ 어텐션 출력 사영
			if (!_Gemm(Ly.dxm, Ly.wo, Ly.datt, N, D, D, 0u, 1u)) return _E("dAtt");
			if (!_Gemm(Ly.att, Ly.dxm, _G(Ly.wo), D, D, N, 1u, 0u)) return _E("dWo");
			// ⑤′ 어텐션 — 배치마다
			for (uint32 b = 0; b < C::kBatch; ++b)
			{
				const uint32 ro = b * T * D, po = b * T * T;
				if (!_Gemm(Ly.datt, Ly.vv, Ly.dprob, T, T, D, 0u, 1u, 0.0f, ro, ro, po)) return _E("dP");
				if (!_Gemm(Ly.prob, Ly.datt, Ly.dvv, T, D, T, 1u, 0u, 0.0f, po, ro, ro)) return _E("dV");
				// ⚠️ **제자리로 쓰지 않는다** — 이 커널은 행을 두 번 훑으므로(합 → 쓰기)
				//   `dIn == dOut` 이 안전한지 커널 계약이 보장하지 않는다 ⇒ `ds` 를 따로 둔다.
				MLSoftmaxBwdParams p{};
				p.probOff = Ly.prob.offset + po; p.dOutOff = Ly.dprob.offset + po;
				p.dInOff = Ly.ds.offset + po; p.rows = T; p.cols = T; p.scale = scale;
				if (!_k[kAttnB].Dispatch(T, 1u, 1u, &p, (uint32)sizeof(p))) return _E("softmax_bwd");
				if (!_Gemm(Ly.ds, Ly.k, Ly.dq, T, D, T, 0u, 0u, 0.0f, po, ro, ro)) return _E("dq(rope)");
				if (!_Gemm(Ly.ds, Ly.q, Ly.dk, T, D, T, 1u, 0u, 0.0f, po, ro, ro)) return _E("dk(rope)");
			}
			// ④′ RoPE 역회전 — `dirSign = -1`. ⚠️ 원래 `q` 는 필요 없다(회전은 자기 역을 갖는다).
			if (!_Rope(Ly.dq, -1.0f)) return _E("rope_bwd(q)");
			if (!_Rope(Ly.dk, -1.0f)) return _E("rope_bwd(k)");
			// ③′ q,k,v 사영 — `dh` 에 **셋이 모인다**
			if (!_Gemm(Ly.dq,  Ly.wq, Ly.dh, N, D, D, 0u, 1u, 0.0f)) return _E("dh(q)");
			if (!_Gemm(Ly.dk,  Ly.wk, Ly.dh, N, D, D, 0u, 1u, 1.0f)) return _E("dh(k)");
			if (!_Gemm(Ly.dvv, Ly.wv, Ly.dh, N, D, D, 0u, 1u, 1.0f)) return _E("dh(v)");
			if (!_Gemm(Ly.h, Ly.dq,  _G(Ly.wq), D, D, N, 1u, 0u)) return _E("dWq");
			if (!_Gemm(Ly.h, Ly.dk,  _G(Ly.wk), D, D, N, 1u, 0u)) return _E("dWk");
			if (!_Gemm(Ly.h, Ly.dvv, _G(Ly.wv), D, D, N, 1u, 0u)) return _E("dWv");
			// ②′ pre-norm
			if (!_RmsG(_tXs[li], Ly.rstd1, Ly.dh, _G(Ly.g1))) return _E("dG1");
			if (!_RmsB(_tXs[li], Ly.g1, Ly.rstd1, Ly.dh, _tDXs[li])) return _E("dX1");
			if (!_Copy(Ly.dxm, _tDXs[li], 1.0f)) return _E("dX1 += dXm(건너가기)");
		}

		// ①′ 슬롯 임베딩 — ⚠️ `dPhi` 는 여기서 멈춘다(값은 **데이터**이고 파라미터가 아니다).
		//   ★ P4 에서 값이 학습되는 곳에서 나오면 그때 `val_enc_bwd` 를 이어 붙인다(커널은 이미 서 있다).
		if (!_Gemm(_tDXs[0], _pWin, _tDPhi, N, C::kPhi, D, 0u, 1u)) return _E("dPhi");
		if (!_Gemm(_tPhi, _tDXs[0], _G(_pWin), C::kPhi, D, N, 1u, 0u)) return _E("dWin");
		// 🔩 ⚠️ **누산 순서도 같다** — 원핫 gemm 은 `n` 오름차순으로 `0·dX` 를 더하고(정확히 무영향)
		//   `embed_bwd` 는 같은 순서로 **맞는 행만** 더한다 ⇒ 부동소수 결과가 같다.
		if (_useEmbed)
		{
			// ⚠️ 같은 파라미터 구조를 fwd/bwd 가 공유한다 — bwd 는 `a = dOut · b = dTable` 이다.
			MLEmbedParams p{}; p.tokOff = _tSym.offset + _poolK * N; p.aOff = _tDXs[0].offset;
			p.bOff = _G(_pSym).offset; p.seqLen = N; p.dim = D; p.vocab = _symVocab;
			if (!_k[kEmbB].Dispatch(D, _symVocab, 1u, &p, (uint32)sizeof(p))) return _E("embed_bwd(sym)");
		}
		else if (!_Gemm(_tOnes, _tDXs[0], _G(_pSym), _axes, D, N, 1u, 0u)) return _E("dSym");

		// ⭐ **기제 관문(㉡)의 재료** — `dPhi` 를 값까지 내려 `dVal[r]` 을 만든다.
		//   ★ 이것은 **파라미터 기울기가 아니다**(값은 데이터다) — 「행 r 의 손실이 어느 슬롯의
		//     값에 민감한가」를 재기 위한 **진단**이다. ⚠️ 그래서 학습에는 안 쓰인다.
		//   ⚠️ 계수는 fwd 와 **같은 값**을 넣는다(다르면 위상이 갈리고 증상이 조용하다).
		{
			MLValEncBwdParams p{};
			p.inOff = _tVal.offset + _poolK * N; p.dOutOff = _tDPhi.offset; p.dInOff = _tDVal.offset;
			p.rows = N; p.freqs = C::kFreqs;
			p.vBias = C::kVBias; p.vScale = C::kVScale;
			p.freqMin = C::kFreqMin; p.freqMax = _freqMax;
			if (!_k[kValB].Dispatch(N, 1u, 1u, &p, (uint32)sizeof(p))) return _E("val_enc_bwd");
		}
		return true;
	}

	// AdamW 한 스텝 — ★ 파라미터가 오프셋 0 부터 **연속**이라 **디스패치 한 번**이면 된다.
	//   ⚠️ `lrMul` 은 **음성 대조군의 유일한 손잡이**다(`0` 이면 같은 그래프를 같은 순서로 돌리고
	//     갱신만 안 한다). ★ 대조군을 「호출을 건너뛰기」로 만들면 **다른 코드 경로**가 되어
	//     대조군이 대조군이 아니게 된다 — 그래서 배율로 둔다.
	// ⭐ `wd`(weight decay)도 인자다 — **회차 154 에서 열었다.** 기본값이 `kWd`(= 0)라
	//   기존 하네스 전부가 **비트 동일**하다.
	//   ⚠️ 셰이더는 **decoupled AdamW 정석**이라 `p -= lr · wd · p` 다 ⇒ 감쇠가 `lr` 에 **비례**한다
	//     (그래서 `lrMul` 을 낮추면 같은 `wd` 가 **약해진다** — 값을 고를 때 손계산이 필요하다).
	bool AdamStep(float lrMul = 1.0f, float wd = MLTModelCfg::kWd)
	{
		typedef MLTModelCfg C;
		++_step;
		MLAdamWParams p{};
		p.pOff = 0u; p.gOff = _gBase; p.mOff = _mBase; p.vOff = _vBase; p.count = _pCount;
		p.lr = C::kLr * lrMul; p.beta1 = C::kB1; p.beta2 = C::kB2; p.eps = C::kAdamEps; p.wd = wd;
		p.bc1 = 1.0f / (1.0f - Pow(C::kB1, (float)_step));   // 편향보정은 **호스트가** 낸다
		p.bc2 = 1.0f / (1.0f - Pow(C::kB2, (float)_step));
		return _k[kAdam].Dispatch(p.count, 1u, 1u, &p, (uint32)sizeof(p));
	}

	// ══════════════════════════════════════════════════════════════════
	// 🧊 **구간별 AdamW** — 「보호·동결·갱신 범위」의 폭을 재는 손잡이
	//
	// ★ **왜 이것이 새 커널 0개로 되나**: 파라미터가 오프셋 0 부터 **연속**이고
	//   `MLAdamWParams` 가 `pOff`/`count` 를 받는다 ⇒ **구간마다 한 번 디스패치**하면 된다.
	//   ⇒ 「이 구간만 갱신한다」가 곧 「나머지는 동결」이다.
	// ⚠️ `from`/`count` 는 **파라미터 블록 안의 오프셋**이다(아레나 절대 오프셋이 아니다).
	//   ★ 기울기·모멘트는 파라미터와 **같은 상대 오프셋**에 살므로 `_gBase + from` 이 그 짝이다.
	// ⚠️⚠️ **스텝 카운터는 한 번만 올린다** — 구간마다 올리면 편향보정이 구간 수만큼 어긋난다.
	// ══════════════════════════════════════════════════════════════════
	bool AdamStepRanges(const uint32* from, const uint32* count, uint32 n, float lrMul = 1.0f)
	{
		typedef MLTModelCfg C;
		if (from == nullptr || count == nullptr || n == 0u) return false;
		++_step;
		const float bc1 = 1.0f / (1.0f - Pow(C::kB1, (float)_step));
		const float bc2 = 1.0f / (1.0f - Pow(C::kB2, (float)_step));
		for (uint32 i = 0; i < n; ++i)
		{
			if (count[i] == 0u) continue;
			// ⚠️ 범위를 넘으면 **거절한다**(`robustBufferAccess` 가 꺼져 있다).
			if (from[i] + count[i] > _pCount)
			{ LogA("[mlt] ③ AdamStepRanges 범위 초과: %u+%u > %u\n", from[i], count[i], _pCount); return false; }
			MLAdamWParams p{};
			p.pOff = from[i]; p.gOff = _gBase + from[i];
			p.mOff = _mBase + from[i]; p.vOff = _vBase + from[i];
			p.count = count[i];
			p.lr = C::kLr * lrMul; p.beta1 = C::kB1; p.beta2 = C::kB2;
			p.eps = C::kAdamEps; p.wd = C::kWd; p.bc1 = bc1; p.bc2 = bc2;
			if (!_k[kAdam].Dispatch(p.count, 1u, 1u, &p, (uint32)sizeof(p))) return false;
		}
		return true;
	}

	// 층 `l` 의 파라미터가 블록 안에서 시작하는 오프셋과 길이.
	//   ★ 층은 **연속**이다(`Setup` 이 그 순서로 잡는다) ⇒ 「앞 k 층 동결」이 한 구간이다.
	uint32 LayerParamBegin(uint32 l) const { return _L[l].g1.offset; }
	uint32 ParamTotal() const { return _pCount; }

	// ══════════════════════════════════════════════════════════════════
	// 🔬 **표현 리드백** — 마지막 `rmsnorm` 뒤의 `[rows, D]`, 곧 **`Wh` 가 읽는 바로 그것**.
	// ══════════════════════════════════════════════════════════════════
	//   ★ 왜 이 지점인가: *"모델의 표현"* 이라 부를 자리가 여럿이면 회차마다 다른 곳을 읽게 된다.
	//     출력 머리가 실제로 보는 텐서 하나로 **못 박는다**(선택의 여지를 없앤다).
	//   ⚠️⚠️ `ReadLoss` 와 **같은 계약** — 이번 프레임에 디스패치한 결과는 안 보인다(부르는 쪽이 기다린다).
	//   ⚠️ 행 색인 규약은 풀과 같다: `r = b·ctx + t·axes + a`.
	//   ★ 첫 소비자 = P3 ㉢ **선형 프로브**(변화가 표현에 있나).
	// ══════════════════════════════════════════════════════════════════
	// 🔎 **회차 128(D4)** — 파라미터·기울기 **블록 통째 리드백**(비결정성 사냥용)
	// ══════════════════════════════════════════════════════════════════
	//   ⭐ 파라미터는 `0.._pCount` 에 **연속**으로 살고 기울기는 `_gBase` 에서 **같은 모양**이다
	//     (위 `_G()` 가 그 대응이다) ⇒ 합성 텐서 하나로 통째 읽을 수 있다.
	//   ⚠️ 이것은 **진단 전용**이다 — 학습 경로가 쓰면 매 걸음 스톨이 된다.
	//   ⚠️⚠️ **이 프레임에 디스패치한 결과는 안 보인다** — 다른 `Read*` 와 같은 규약이다.
	bool ReadParams(Array<float>& out) const { return _ReadBlock(0u, out); }
	bool ReadGrads(Array<float>& out) const  { return _ReadBlock(_gBase, out); }
	uint32 ParamCount() const { return _pCount; }
	// ⭐⭐ 회차 245 — **심볼 임베딩 표만** 읽는다(`[_symVocab, D]`).
	//   ★ 왜 `ReadParams` 로 안 쓰나: 그것은 블록 통째(수십만 float)라 **팔·씨앗마다** 부르면
	//     트래픽이 헛되다. 여기 필요한 것은 **그 낱말의 행**뿐이고 자리가 `_pSym` 하나로 닫혀 있다.
	//   ★ *"모델의 표현"* 자리를 회차마다 다르게 고르지 않으려고 **못 박는 것**은 `ReadRep` 과 같은 관용구다.
	//   ⚠️⚠️ 다른 `Read*` 와 **같은 계약** — 이번 프레임에 디스패치한 결과는 안 보인다.
	bool ReadSymTable(Array<float>& out) const
	{
		const uint32 n = _symVocab * _dim;
		if (n == 0u) return false;
		Bytes b;
		if (!_ar.Read(_pSym, b) || b.GetSize() < (uint64)n * sizeof(float)) return false;
		const float* v = (const float*)b.GetData();
		out.Reset(0);
		for (uint32 i = 0; i < n; ++i) out.Add(v[i]);
		return true;
	}
	// ⭐ 쌓인 컴퓨트를 씻는다(회차 128 — 「몇 틱 기다린다」를 **보장**으로 바꾼다). 진단·평가 전용.
	void Flush() const { _ar.Flush(); }
	// ⭐ **회차 136(D4-f)** — **1 float 만** 회수한다.
	//   ⚠️ 회차 135 가 *"16걸음마다 **리드백**을 끼우면 갈림이 사라진다"* 를 냈다(`Flush` 로는 안 사라진다).
	//   ★ 그러면 범인이 **「회수 행위」**(배리어·큐 전환)인지 **「회수 양」**(3.4MB 트래픽)인지 갈라야 한다.
	//   ⇒ 이것이 그 자다: **같은 행위 · 양은 1/858496**.
	bool ReadTiny(float& out) const
	{
		MLTensor t; t.offset = 0u; t.rows = 1u; t.cols = 1u;
		Bytes b;
		if (!_ar.Read(t, b) || b.GetSize() < sizeof(float)) return false;
		out = *(const float*)b.GetData();
		return true;
	}

	bool ReadRep(Array<float>& out) const
	{
		Bytes b;
		const uint32 D = _dim;
		if (!_ar.Read(_tHf, b) || b.GetSize() < (uint64)_rows * (uint64)D * sizeof(float)) return false;
		const float* v = (const float*)b.GetData();
		out.Reset(0);
		for (uint32 i = 0; i < _rows * D; ++i) out.Add(v[i]);
		return true;
	}
	// ⚠️⚠️ **이것은 「기본 용량」의 폭이다 — 회차 150 부터 실제 폭은 `Dim()` 이다.**
	//   ★ `static constexpr` 로 남긴 이유: 하네스 열 곳이 `static constexpr uint32 kD =
	//     MLTModel::RepDim();` 으로 **컴파일 타임 배열 크기**를 잡는다(D4·L0 계열). 그것들은
	//     전부 **기본 용량**에서 돌았으므로 값이 참이다.
	//   ⚠️ 용량을 바꾼 회차에서 `ReadRep` 을 쓰려면 **`Dim()`** 을 봐라(이 함수는 거짓말한다).
	static constexpr uint32 RepDim() { return MLTModelCfg::kDim; }

	// ⭐ 회차 150 — **지금 이 인스턴스의 실제 용량**. 하네스가 서명으로 찍는다(규율 21).
	uint32 Dim()   const { return _dim; }
	uint32 Layers() const { return _layer; }
	uint32 FF()    const { return _ff; }
	uint32 Params() const { return _pCount; }
	uint32 ArenaUsed() const { return _ar.Used(); }

	// ⚠️⚠️ **이번 프레임에 디스패치한 결과는 안 보인다** — 부르는 쪽이 한 프레임 기다려야 한다.
	//   ★ 배율은 backward 의 `lossScale` 과 **같다**(안 맞추면 "손실은 안 주는데 학습은 된다").
	bool ReadLoss(float& out) const
	{
		Bytes b;
		if (!_ar.Read(_tLoss, b) || b.GetSize() < (uint64)_rows * sizeof(float)) return false;
		const float* v = (const float*)b.GetData();
		float s = 0.0f;
		for (uint32 i = 0; i < _rows; ++i) s += v[i];
		// ★ backward 의 `lossScale` 과 **같은 분모**를 쓴다(안 맞추면 "손실은 안 주는데 학습은 된다").
		out = s / (float)((_valid > 0u) ? _valid : _rows);
		return true;
	}

	// ⭐ **행별 손실** — `ReadLoss` 가 합치기 전의 그 배열이다(`_tLoss` 는 원래 `[rows]` 다).
	//   ★ 첫 소비자 = 회차 104(**절제의 「분포」를 본다**). 평균만 보면 ***선택적으로 읽는 것을
	//     0 으로 읽는다*** — 어떤 표적은 크게 나빠지고 대부분은 그대로면 **평균이 정확히 0** 이다.
	//   ⚠️ **나누지 않는다**(`ReadLoss` 와 달리) — 나누는 순간 행별 뜻이 흐려진다. 무효 표적 행은
	//     커널이 0 을 쓰므로 그대로 0 이다(부르는 쪽이 표적으로 걸러 쓴다).
	//   ⚠️⚠️ **이번 프레임에 디스패치한 결과는 안 보인다** — `ReadLoss` 와 같은 규약이다.
	bool ReadLossRows(Array<float>& out) const
	{
		Bytes b;
		if (!_ar.Read(_tLoss, b) || b.GetSize() < (uint64)_rows * sizeof(float)) return false;
		const float* v = (const float*)b.GetData();
		out.Reset(0);
		for (uint32 i = 0; i < _rows; ++i) out.Add(v[i]);
		return true;
	}

	// ══════════════════════════════════════════════════════════════════
	// 🎯 **정확도** — 행마다 argmax 가 표적과 같나. ⚠️ 무효 표적 행은 **세지 않는다**.
	//   ⚠️⚠️ **이번 프레임에 디스패치한 결과는 안 보인다** — 부르는 쪽이 한 프레임 기다려야 한다.
	//   ★ `probs` 를 읽는다(로짓이 아니다): softmax 는 단조라 argmax 가 같고, `probs` 는
	//     **합이 1** 이어야 하므로 유한성·정상성 확인이 값 자체로 된다.
	// ══════════════════════════════════════════════════════════════════
	//   ★ `band[r] != 0` 인 행은 ⑫ 보간 구간이다 — 그 몫을 **따로** 센다(관문 ㉡).
	//     ⚠️ 왜 여기서 세나: argmax 를 여기서만 하므로 밖에서 다시 하면 **같은 식이 두 자리**가 된다.
	//   ★ `dist`/`distB` = `Σ|argmax − 표적|`(버킷 거리). ⚠️ 규율 5: **이진 임계를 그 밑의 연속량으로.**
	//   ⚠️⚠️ `distOut` = **밴드 밖만**. 회차 4 가 밟은 자리: 밴드는 표본의 10% 인데 거리가 15 라
	//     전체 평균에 1.5 를 얹어 `D_all` 을 음수로 만들었다 — **밴드가 전체를 오염시킨다.**
	//     ⇒ 「배운 구간에서 얼마나 잘하나」는 반드시 **밴드를 뺀 칸**으로 읽는다.
	bool ReadHits(const Array<float>& tgt, const Array<float>& band,
		uint32& hits, uint32& n, uint32& hitsB, uint32& nB, float& sumP,
		float& dist, float& distB, float& distOut) const
	{
		typedef MLTModelCfg C;
		hits = 0u; n = 0u; hitsB = 0u; nB = 0u; sumP = 0.0f;
		dist = 0.0f; distB = 0.0f; distOut = 0.0f;
		uint32 nOut = 0u;
		if (tgt.Count() != _rows || band.Count() != _rows) return false;
		Bytes b;
		if (!_ar.Read(_tProbs, b) || b.GetSize() < (uint64)_rows * _outVocab * sizeof(float)) return false;
		const float* p = (const float*)b.GetData();
		for (uint32 r = 0; r < _rows; ++r)
		{
			if (!(tgt[r] >= 0.0f && tgt[r] < (float)_outVocab)) continue;   // 홀드아웃 행
			const float* row = p + (uint64)r * _outVocab;
			uint32 best = 0u;
			float acc = row[0];
			// ⚠️ 동점은 **낮은 색인이 이긴다**(비교가 `>` 다) — 이 저장소의 그 규약과 같게 둔다.
			for (uint32 c = 1; c < _outVocab; ++c) { if (row[c] > row[best]) best = c; acc += row[c]; }
			sumP += acc;
			const uint32 tb = (uint32)(tgt[r] + 0.5f);
			const bool hit = (best == tb);
			const float e = Abs((float)best - (float)tb);
			if (hit) ++hits;
			++n; dist += e;
			if (band[r] != 0.0f) { if (hit) ++hitsB; ++nB; distB += e; }
			else                 { ++nOut; distOut += e; }
		}
		if (n    > 0u) dist    /= (float)n;
		if (nB   > 0u) distB   /= (float)nB;
		if (nOut > 0u) distOut /= (float)nOut;
		if (n > 0u) sumP /= (float)n;   // ★ 1.0 이어야 한다 — 아니면 리드백이 프레임을 안 넘겼다
		return n > 0u;
	}

	// ⚠️⚠️ **회차 207 이 여기에 `ReadKeepProb` 을 지으려다 지웠다** — 규율 21 이 더 싼 자를 찾았다:
	//   ★ **지속 표적의 정답은 「지금 계급」**이므로(그것이 *"다음 = 지금"*)
	//     ***지속 CE = `−log P(지금 계급)` = `−log P(지속)`*** ⇒ ⭐ 그것이 **이진 CE 의 지속 항
	//     그 자체**다. ⇒ ⇒ 이미 있는 `_ceKeep` 이 그 자였고 **새 리드백이 필요 없었다.**
	//   ⇒ ⭐ 「변화 항」(`−log(1−P(지금))`)은 이 길로 못 얻지만 **하한만으로 판정이 된다**
	//     (하한이 상수 예측자를 넘으면 ⛔ 확정 · ⚠️ 반대로 낮아도 ✅ 는 못 준다).
	//   ★ 그래서 처방이 **하네스의 팔별 지속 CE**(205 에서 적어 둔 배관 부채)로 바뀌었다.
	uint32 Step() const { return _step; }
	// ⚠️ **진실 접촉 횟수**(표적으로 올린 유효 행의 누적). ★ 「정답을 안 쓴다」를 적기 전에 이것을 본다.
	uint64 TruthTouches() const { return _truth; }
	void   ResetTruthTouches() { _truth = 0ull; }

	// ══════════════════════════════════════════════════════════════════
	// 🔮 **오라클 신뢰의 재료** — 마스크 행들의 `|argmax − 표적|` 의 **평균과 분산**
	//
	// ★ 회차 16 의 예측자 ㈂ 다. ⚠️⚠️ **표적을 읽는다** ⇒ 이것은 **진실 접촉이 최대**인
	//   신뢰다(마진·엔트로피의 반대 극). 그 천장이 바닥이면 「예고」 목적지를 삭제한다.
	// ⚠️ 분산을 내는 이유: 1단계 `R`(= 평균 정확도)는 **짝짓기 변수**로 쓰므로 예측자로 쓰면
	//   무의미하다 ⇒ **같은 평균에서 갈리는 것**(오차가 고르게 퍼졌나 몇 행에 몰렸나)을 잰다.
	// ⚠️ **한 프레임 기다려야 한다**(아레나 규약).
	// ══════════════════════════════════════════════════════════════════
	bool ReadErrVar(const Array<float>& tgt, const Array<float>& mask,
		float& mean, float& var, uint32& n) const
	{
		typedef MLTModelCfg C;
		mean = 0.0f; var = 0.0f; n = 0u;
		if (tgt.Count() != _rows || mask.Count() != _rows) return false;
		Bytes b;
		if (!_ar.Read(_tProbs, b) || b.GetSize() < (uint64)_rows * _outVocab * sizeof(float)) return false;
		const float* p = (const float*)b.GetData();
		float s = 0.0f, s2 = 0.0f;
		for (uint32 r = 0; r < _rows; ++r)
		{
			if (mask[r] == 0.0f) continue;
			if (!(tgt[r] >= 0.0f && tgt[r] < (float)_outVocab)) continue;
			const float* row = p + (uint64)r * _outVocab;
			uint32 best = 0u;
			for (uint32 c = 1; c < _outVocab; ++c) if (row[c] > row[best]) best = c;
			const float e = Abs((float)best - tgt[r]);   // |argmax − 표적| (tgt 는 정수가 float 에 정확히 담긴 값)
			s += e; s2 += e * e;
			++n;
		}
		if (n == 0u) return false;
		mean = s / (float)n;
		var = s2 / (float)n - mean * mean;
		if (var < 0.0f) var = 0.0f;   // 부동소수 잔차
		return true;
	}

	// ══════════════════════════════════════════════════════════════════
	// 🎚️ **진실 접촉 0 인 신뢰** — 출력 분포만 본다(표적을 **안 본다**)
	//
	// ★ `mltconcept.md` 가 이것을 **기본 대조군**으로 못 박았다:
	//   > **진실 접촉 0 인 신뢰**(출력 분포의 엔트로피·마진)를 기본 대조군으로 둔다 — 그것이
	//   > 같으면 실현 채점은 **접촉만 늘리고 값은 안 한 것**이다.
	//   ⇒ ★ 그래서 **헤드를 만들기 전에 이것을 먼저 잰다.** 충분하면 만들 이유가 없다.
	//
	//   `margin` = `p(1등) − p(2등)` (클수록 확신) · `entropy` = `−Σ p log p` (작을수록 확신)
	//   ⚠️ 둘을 **함께** 본다 — 마진은 1·2등만 보고 엔트로피는 꼬리를 본다(다른 것을 잰다).
	//   ⚠️⚠️ **표적을 안 읽는다** ⇒ 이 함수는 **진실 접촉을 0 늘린다.** 그것이 요점이다.
	//   ⚠️ **한 프레임 기다려야 한다**(아레나 규약).
	// ══════════════════════════════════════════════════════════════════
	bool ReadConf(const Array<float>& mask, float& margin, float& entropy, uint32& n) const
	{
		typedef MLTModelCfg C;
		margin = 0.0f; entropy = 0.0f; n = 0u;
		if (mask.Count() != _rows) return false;
		Bytes b;
		if (!_ar.Read(_tProbs, b) || b.GetSize() < (uint64)_rows * _outVocab * sizeof(float)) return false;
		const float* p = (const float*)b.GetData();
		float sm = 0.0f, se = 0.0f;
		for (uint32 r = 0; r < _rows; ++r)
		{
			if (mask[r] == 0.0f) continue;
			const float* row = p + (uint64)r * _outVocab;
			float p1 = -1.0f, p2 = -1.0f, ent = 0.0f;
			for (uint32 c = 0; c < _outVocab; ++c)
			{
				const float v = row[c];
				if (v > p1) { p2 = p1; p1 = v; }
				else if (v > p2) { p2 = v; }
				// ⚠️ `log 0` 을 피한다 — `probs` 는 softmax 이므로 0 은 아니지만 언더플로가 있을 수 있다.
				if (v > 1.0e-30f) ent -= v * Log(v);
			}
			sm += (p1 - p2); se += ent;
			++n;
		}
		if (n == 0u) return false;
		margin = sm / (float)n;
		entropy = se / (float)n;
		return true;
	}

	// ══════════════════════════════════════════════════════════════════
	// ⭐ **기제 관문(㉡)** — 「기울기가 그 축 슬롯에 몰리나」
	//   `dVal[r]` = 행 `r` 의 **값 입력**에 대한 손실의 민감도. 축마다 `|dVal|` 을 합쳐
	//   부르는 쪽이 「같은 축 몫 / 전체」를 읽는다. ⚠️ 우연은 `1/A`(A=3 ⇒ 33.3%)다.
	//   ⚠️⚠️ **이 값은 학습에 안 쓰인다** — 진단 전용이다(값은 파라미터가 아니다).
	//   ⚠️ **한 프레임 기다려야 한다**(아레나 규약).
	// ══════════════════════════════════════════════════════════════════
	// ⭐ **`dVal` 을 날것으로 준다** — `[rows]`, 행 색인 규약은 풀과 같다(`r = b·ctx + t·axes + a`).
	//   ⚠️⚠️ 위 주석의 *"진단 전용"* 은 **지금까지의 쓰임**을 적은 것이지 금지가 아니다 —
	//     ★ 이 값이 곧 **인코더로 되돌릴 신호**다(회차 63 설계 심사가 그 자리를 짚었다).
	//   ⚠️ `ReadLoss` 와 같은 계약(한 프레임 뒤에 보인다).
	bool ReadDVal(Array<float>& out) const
	{
		Bytes b;
		if (!_ar.Read(_tDVal, b) || b.GetSize() < (uint64)_rows * sizeof(float)) return false;
		const float* v = (const float*)b.GetData();
		out.Reset(0);
		for (uint32 i = 0; i < _rows; ++i) out.Add(v[i]);
		return true;
	}

	bool ReadAxisMass(float* mass, uint32 nAxes) const
	{
		typedef MLTModelCfg C;
		if (mass == nullptr || nAxes != _axes) return false;
		for (uint32 a = 0; a < nAxes; ++a) mass[a] = 0.0f;
		Bytes b;
		if (!_ar.Read(_tDVal, b) || b.GetSize() < (uint64)_rows * sizeof(float)) return false;
		const float* v = (const float*)b.GetData();
		for (uint32 r = 0; r < _rows; ++r) mass[(r % _ctx) % _axes] += Abs(v[r]);
		return true;
	}

	MLArena& Arena() { return _ar; }

	// ══════════════════════════════════════════════════════════════════
	// 🔩 **회차 49 의 표면 셋** — 어휘와 심볼 경로.
	// ══════════════════════════════════════════════════════════════════
	//   ⚠️ `SetSymbolPath(false)` 는 **비트 동일 A/B 전용**이고 `_symVocab == kAxes` 일 때만 뜻이 있다
	//     (원핫 `_tOnes` 가 `[N, kAxes]` 라 그 위로는 표현이 안 된다).
	void SetSymbolPath(bool useEmbed)
	{
		_useEmbed = useEmbed || (_symVocab != _axes);
	}
	bool UsesEmbed() const { return _useEmbed; }
	uint32 SymVocab() const { return _symVocab; }
	// ⚠️⚠️⚠️ **회차 202 가 찾은 것 — `_Spread` 에 씨앗이 없었다.**
	//   ⇒ ★ 초기화가 「인덱스 + 고정 `salt`」의 함수였으므로 ***12씨앗 전부가 완전히 같은
	//     초기값***을 썼다(씨앗은 **세계만** 바꿨다).
	//   ⇒ ⇒ ⭐ 그래서 **어휘 id = 임베딩 행 = 고정된 초기값**이고 **씨앗 평균으로 안
	//     지워진다**(부채 D26 의 기제) · ⚠️⚠️ 더 크게는 **이 트랙의 모든 12씨앗 판정이
	//     「하나의 초기화」 위에서 났고 SE 가 그 우연을 못 담았다.**
	//   ⭐ 다만 **짝지은 차는 안 흔들린다**(같은 실행의 두 팔이 같은 초기화를 쓴다) —
	//     흔들리는 것은 **그 결론의 일반화**다(*"다른 초기화에서도 그럴까"*).
	//   ⇒ ⚠️ **기본은 0(옛 동작)** 이다 — 안 부르면 회차 1~201 이 **비트 동일**하다.
	//   ⚠️ `Setup` **보다 먼저** 부른다(`_InitParams` 가 `Setup` 안에서 돈다).
	void SetInitSeed(uint32 s) { _initSeed = s; }
	uint32 InitSeed() const    { return _initSeed; }
	uint32 OutVocab() const { return _outVocab; }
	// 🔩 회차 50 — 배치를 묻는다. ⚠️ 다른 배치를 쓰는 호출부는 `MLTModelCfg::kRows` 대신 **이것**을 본다.
	uint32 Axes() const { return _axes; }
	uint32 Time() const { return _time; }
	uint32 Ctx()  const { return _ctx; }
	uint32 Rows() const { return _rows; }
	// ⭐ 표적을 손실에서 빼는 센티널 — **출력 어휘를 넘는 정수**여야 한다(고정 상수로 두면
	//   헤드를 넓힌 순간 그것이 **유효 클래스**가 되어 조용히 손실에 들어간다).
	float IgnoreTgt() const { return (float)_outVocab; }

	// 행마다의 **심볼 id**를 덮어쓴다(P3 의 활성 토큰이 이 자리다). `nSteps × Rows()` 개여야 한다.
	//   ⚠️ 기본값은 `Setup` 이 P0/P1 규칙(`(r % ctx) % axes`)으로 **풀 전체**에 채워 둔다.
	//   ⚠️⚠️ `UploadPool` 과 **짝으로** 부른다(같은 `nSteps`) — 값·표적·심볼이 같은 칸을 가리켜야 한다.
	bool UploadSymbolPool(const Array<float>& sym, uint32 nSteps)
	{
		if (nSteps == 0u || nSteps > MLTModelCfg::kPool) return false;
		if (sym.Count() != nSteps * _rows) return false;
		MLTensor t = _tSym; t.rows = nSteps;
		return _ar.Write(t, sym);
	}

private:
	enum { kGemm, kRms, kRmsB, kRmsG, kRope, kAttn, kAttnB, kSwi, kSwiB, kCe, kCeB, kVal, kValB, kAdam,
		kEmb, kEmbB, kNK };
	MLKernel _k[kNK];
	MLArena  _ar;

	// 🔩 회차 49·50 — 어휘와 **슬롯 배치**는 런타임 값이다(`MLTModelCfg` 의 상수는 기본값일 뿐이다).
	uint32 _symVocab = MLTModelCfg::kAxes;
	// ⭐ 회차 202 — 파라미터 초기화 씨앗 · ⚠️ **기본 0 = 옛 동작**(비트 동일)
	uint32 _initSeed = 0u;
	uint32 _outVocab = MLTModelCfg::kBuckets;
	uint32 _axes = MLTModelCfg::kAxes;
	uint32 _time = MLTModelCfg::kTime;
	uint32 _ctx  = MLTModelCfg::kCtx;
	uint32 _rows = MLTModelCfg::kRows;
	// ⭐ 회차 150 — 용량이 런타임이다(근거는 `MLTModelCfg::kDim` 자리의 주석).
	uint32 _dim   = MLTModelCfg::kDim;
	uint32 _layer = MLTModelCfg::kLayer;
	uint32 _ff    = MLTModelCfg::kFF;
	bool   _useEmbed = true;    // ⚠️ 기본이 `embed` 다 — 원핫은 **비트 동일 A/B 전용**이다
	MLTensor _tSym, _tSymE;

	MLTensor _pWin, _pSym, _pGf, _pWh;
	MLTLayer _L[MLTModelCfg::kLayerMax];
	uint32 _pEnd = 0u, _pCount = 0u, _gBase = 0u, _mBase = 0u, _vBase = 0u, _step = 0u, _valid = 0u;
	float  _freqMax = MLTModelCfg::kFreqMax;
	uint64 _truth = 0ull;   // ⚠️ 진실 접촉 계수기(위 그 이유)
	uint32 _poolK = 0u;
	uint32 _poolValid[MLTModelCfg::kPool] = { 0u };
	MLTensor _tXs[MLTModelCfg::kLayerMax + 1u], _tDXs[MLTModelCfg::kLayerMax + 1u];
	MLTensor _tVal, _tTgt, _tPhi, _tDPhi, _tHf, _tDHf, _tRstdF;
	MLTensor _tLogit, _tProbs, _tDLogit, _tLoss, _tPos, _tOnes, _tUnit, _tDVal;

	// 기울기는 파라미터와 **같은 모양·같은 상대 오프셋**으로 산다 ⇒ 이 한 줄이 그 대응이다.
	//   ★ 그래서 층마다 기울기 텐서를 따로 들 필요가 없다(오프셋 실수의 자리를 하나 없앴다).
	MLTensor _G(const MLTensor& p) const { MLTensor g = p; g.offset = _gBase + p.offset; return g; }

	// 🔎 회차 128 — 블록 통째 읽기(위 `ReadParams`/`ReadGrads` 의 몸통)
	bool _ReadBlock(uint32 base, Array<float>& out) const
	{
		if (_pCount == 0u) return false;
		MLTensor t; t.offset = base; t.rows = 1u; t.cols = _pCount;
		Bytes b;
		if (!_ar.Read(t, b) || b.GetSize() < (uint64)_pCount * sizeof(float)) return false;
		const float* v = (const float*)b.GetData();
		out.Reset(0);
		for (uint32 i = 0; i < _pCount; ++i) out.Add(v[i]);
		return true;
	}

	static bool _E(const char* what) { LogA("[mlt] ③ %s 실패\n", what); return false; }

	bool _Load(RHI* rhi, int i, const char* path)
	{
		Bytes spv;
		if (!PlatformFile::LoadBytes(path, spv, PlatformFileSource::Package) || spv.GetSize() == 0)
		{ LogA("[mlt] ③ %s 를 못 읽었다(쿡 확인)\n", path); return false; }
		if (!_k[i].Create(rhi, spv.GetData(), spv.GetSize(), _ar))
		{ LogA("[mlt] ③ 커널 생성 실패: %s\n", path); return false; }
		return true;
	}

	bool _LoadKernels(RHI* rhi)
	{
		return _Load(rhi, kGemm, "shaders/gemm.cs.spv")
		    && _Load(rhi, kRms,  "shaders/rmsnorm.cs.spv")
		    && _Load(rhi, kRmsB, "shaders/rmsnorm_bwd.cs.spv")
		    && _Load(rhi, kRmsG, "shaders/rmsnorm_gbwd.cs.spv")
		    && _Load(rhi, kRope, "shaders/rope.cs.spv")
		    && _Load(rhi, kAttn, "shaders/attn_softmax.cs.spv")
		    && _Load(rhi, kAttnB,"shaders/softmax_bwd.cs.spv")
		    && _Load(rhi, kSwi,  "shaders/swiglu.cs.spv")
		    && _Load(rhi, kSwiB, "shaders/swiglu_bwd.cs.spv")
		    && _Load(rhi, kEmb,  "shaders/embed.cs.spv")
		    && _Load(rhi, kEmbB, "shaders/embed_bwd.cs.spv")
		    && _Load(rhi, kCe,   "shaders/ce_logits.cs.spv")
		    && _Load(rhi, kCeB,  "shaders/ce_logits_bwd.cs.spv")
		    && _Load(rhi, kVal,  "shaders/val_enc.cs.spv")
		    && _Load(rhi, kValB, "shaders/val_enc_bwd.cs.spv")
		    && _Load(rhi, kAdam, "shaders/adamw.cs.spv");
	}

	// ⚠️ **결정적 산포로 초기화한다** — 난수를 쓰면 시드 스트림을 소비해 비트 재현이 깨진다.
	//   ★ 스케일은 `1/√fan_in`(He/Xavier 계열) — 층이 깊어도 활성이 안 터지게.
	bool _InitParams()
	{
		Array<float> p; p.Reset(0);
		for (uint32 i = 0; i < _pCount; ++i) p.Add(0.0f);
		float* d = p.Data();
		typedef MLTModelCfg C;
		_Spread(d + _pWin.offset, _pWin.Count(), 11u, C::kPhi, _initSeed);
		// ⚠️ **심볼을 0 으로 두면 축이 구별되지 않는다** — P0 은 축이 하나여서 0 이 맞았다.
		//   ★ 축마다 다른 산포로 시작한다(스케일은 `1/√A` — 다른 파라미터와 같은 관용구).
		// 🔩⭐ **회차 50 이 회차 49 의 부채를 갚은 자리** — 산포 척도를 **`1/√kAxes` 로 고정**한다.
		//   ⚠️ 옛 코드는 `fan = 어휘` 였는데(원핫 gemm 의 fan-in 이 곧 어휘였다) **게더의 진짜
		//     fan-in 은 1** 이다. 어휘가 255 면 `1/√V` 가 임베딩을 P1 때보다 **9배** 줄인다.
		//   ★ 임의 상수를 새로 고르지 않는 유일한 기준이 **지금까지 쓴 값**이라 그것으로 고정한다.
		//   ★ `_symVocab == kAxes` 면 **옛 값과 정확히 같다** ⇒ 회차 49 의 비트 동일이 그대로 산다.
		_Spread(d + _pSym.offset, _pSym.Count(), 13u, C::kAxes, _initSeed);
		for (uint32 l = 0; l < _layer; ++l)
		{
			MLTLayer& L = _L[l];
			for (uint32 i = 0; i < L.g1.Count(); ++i) d[L.g1.offset + i] = 1.0f;   // ★ RMSNorm 이득은 1
			for (uint32 i = 0; i < L.g2.Count(); ++i) d[L.g2.offset + i] = 1.0f;
			_Spread(d + L.wq.offset, L.wq.Count(), 100u + l * 7u, _dim, _initSeed);
			_Spread(d + L.wk.offset, L.wk.Count(), 101u + l * 7u, _dim, _initSeed);
			_Spread(d + L.wv.offset, L.wv.Count(), 102u + l * 7u, _dim, _initSeed);
			_Spread(d + L.wo.offset, L.wo.Count(), 103u + l * 7u, _dim, _initSeed);
			_Spread(d + L.wg.offset, L.wg.Count(), 104u + l * 7u, _dim, _initSeed);
			_Spread(d + L.wu.offset, L.wu.Count(), 105u + l * 7u, _dim, _initSeed);
			_Spread(d + L.wd.offset, L.wd.Count(), 106u + l * 7u, _ff, _initSeed);
		}
		for (uint32 i = 0; i < _pGf.Count(); ++i) d[_pGf.offset + i] = 1.0f;
		_Spread(d + _pWh.offset, _pWh.Count(), 200u, _dim, _initSeed);

		MLTensor whole; whole.offset = 0u; whole.rows = 1u; whole.cols = _pCount;
		if (!_ar.Write(whole, p)) { LogA("[mlt] ③ 파라미터 업로드 실패\n"); return false; }

		// 기울기·모멘트는 0 으로(⚠️ `Create` 가 아레나 전체를 0 으로 채웠으므로 이미 0 이다).
		// ★ 위치 텐서: RoPE 가 헤드마다 같은 `t` 를 봐야 한다.
		// ★ **RoPE 위치는 「시각」이다** — 같은 시각의 `A` 개 행이 **같은 위치**를 갖는다.
		//   ⚠️ 행 번호를 그대로 쓰면 축이 위치로 구별되어 **심볼이 할 일을 위치가 가로챈다**
		//     ⇒ 기제 관문(「기울기가 그 축 슬롯에 몰리나」)이 뜻을 잃는다.
		Array<float> pos; pos.Reset(0);
		for (uint32 n = 0; n < _rows; ++n) pos.Add((float)((n % _ctx) / _axes));
		if (!_ar.Write(_tPos, pos)) return false;
		// ★ 원핫 `[N, A]` — 행 `r` 의 축은 `(r % kCtx) % A` 다(`r = b·T + t·A + a`).
		Array<float> ones; ones.Reset(0);
		for (uint32 n = 0; n < _rows; ++n)
		{
			const uint32 a = (n % _ctx) % _axes;
			for (uint32 j = 0; j < _axes; ++j) ones.Add((j == a) ? 1.0f : 0.0f);
		}
		if (!_ar.Write(_tOnes, ones)) return false;
		// 🔩 `embed` 경로의 심볼 id — ⚠️ **원핫과 같은 규칙**이어야 한다(그래야 비트 동일이 성립한다).
		//   ★ 부르는 쪽이 `UploadSymbolPool` 로 덮어쓸 수 있다(P3 의 활성 토큰이 그 자리다).
		//   ⚠️ **풀 전체를 같은 기본값으로** 채운다 — 그래야 `_poolK` 가 무엇이든 옛 경로와 같다.
		Array<float> sym; sym.Reset(0);
		for (uint32 k = 0; k < C::kPool; ++k)
			for (uint32 n = 0; n < _rows; ++n) sym.Add((float)((n % _ctx) % _axes));
		if (!_ar.Write(_tSym, sym)) return false;
		Array<float> unit; unit.Reset(0); unit.Add(1.0f);
		return _ar.Write(_tUnit, unit);
	}

	// 🔩 실제 파라미터 수 — `ParamCount()` 의 런타임판(어휘가 인자가 된 뒤의 정본).
	uint32 _ParamNeed() const
	{
		typedef MLTModelCfg C;
		return C::kPhi * _dim + _symVocab * _dim
			+ _layer * (_dim * 2u
				+ _dim * _dim * 4u
				+ _dim * _ff * 2u + _ff * _dim)
			+ _dim + _dim * _outVocab;
	}

	// ⚠️⚠️⚠️ **회차 202 가 찾은 것 — 여기에 씨앗이 없었다.**
	//   ⇒ ★ 초기화가 「인덱스 + 고정 `salt`」의 함수였으므로 ***12씨앗 전부가 완전히 같은
	//     초기값***을 썼다(씨앗은 **세계만** 바꿨다).
	//   ⇒ ⇒ ⭐ 그래서 **어휘 id = 임베딩 행 = 고정된 초기값**이고 **씨앗 평균으로 안
	//     지워진다**(부채 D26 의 기제) · ⚠️⚠️ 더 크게는 **이 트랙의 모든 12씨앗 판정이
	//     「하나의 초기화」 위에서 났고 SE 가 그 우연을 못 담았다.**
	//   ⭐ 다만 **짝지은 차는 안 흔들린다**(같은 실행의 두 팔이 같은 초기화를 쓴다) —
	//     흔들리는 것은 **그 결론의 일반화**다(*"다른 초기화에서도 그럴까"*).
	//   ⇒ ⚠️ **기본은 0(옛 동작)** 이다 — `SetInitSeed` 를 안 부르면 회차 1~201 이 **비트 동일**.
	static void _Spread(float* p, uint32 n, uint32 salt, uint32 fanIn, uint32 seed = 0u)
	{
		const float s = 1.0f / Sqrt((float)fanIn);
		for (uint32 i = 0; i < n; ++i)
		{
			uint32 h = i * 2654435761u + salt * 2246822519u + seed * 0x9E3779B9u;
			h ^= (h >> 16); h *= 0x7FEB352Du; h ^= (h >> 15); h *= 0x846CA68Bu; h ^= (h >> 16);
			p[i] = (((float)(h >> 8) / 8388608.0f) - 1.0f) * s;
		}
	}

	// ── gemm 한 방 (⚠️ `beta = 1` 이면 `C` 에 **누산**한다) ─────────────
	bool _Gemm(const MLTensor& a, const MLTensor& b, const MLTensor& c,
		uint32 M, uint32 N, uint32 K, uint32 tA = 0u, uint32 tB = 0u, float beta = 0.0f,
		uint32 aExtra = 0u, uint32 bExtra = 0u, uint32 cExtra = 0u)
	{
		MLGemmParams p{};
		p.aOff = a.offset + aExtra; p.bOff = b.offset + bExtra; p.cOff = c.offset + cExtra;
		p.M = M; p.N = N; p.K = K; p.transA = tA; p.transB = tB; p.beta = beta;
		return _k[kGemm].Dispatch(N, M, 1u, &p, (uint32)sizeof(p));
	}

	// ── 복사 (⭐ `[n,1]·[1,1]` gemm = O(n)) ─────────────────────────
	bool _Copy(const MLTensor& src, const MLTensor& dst, float beta = 0.0f)
	{
		const uint32 n = src.Count();
		if (n == 0u || dst.Count() < n) return false;
		MLGemmParams p{};
		p.aOff = src.offset; p.bOff = _tUnit.offset; p.cOff = dst.offset;
		p.M = n; p.N = 1u; p.K = 1u; p.beta = beta;
		return _k[kGemm].Dispatch(1u, n, 1u, &p, (uint32)sizeof(p));
	}

	// ── RMSNorm 셋 (fwd · 입력 bwd · 이득 bwd) ──────────────────────
	bool _Rms(const MLTensor& in, const MLTensor& gain, const MLTensor& out, const MLTensor& rstd)
	{
		MLRmsNormParams p{};
		p.inOff = in.offset; p.gainOff = gain.offset; p.outOff = out.offset; p.rstdOff = rstd.offset;
		p.rows = _rows; p.cols = _dim; p.eps = MLTModelCfg::kNormEps;
		return _k[kRms].Dispatch(p.rows, 1u, 1u, &p, (uint32)sizeof(p));
	}
	bool _RmsB(const MLTensor& in, const MLTensor& gain, const MLTensor& rstd,
		const MLTensor& dOut, const MLTensor& dIn)
	{
		MLRmsNormBwdParams p{};
		p.inOff = in.offset; p.gainOff = gain.offset; p.rstdOff = rstd.offset;
		p.dOutOff = dOut.offset; p.dInOff = dIn.offset;
		p.rows = _rows; p.cols = _dim;
		return _k[kRmsB].Dispatch(p.rows, 1u, 1u, &p, (uint32)sizeof(p));
	}
	// ⚠️ 이쪽만 **디스패치 축이 열**이다(행 방향 리덕션이라 커널이 갈려 있다).
	bool _RmsG(const MLTensor& in, const MLTensor& rstd, const MLTensor& dOut, const MLTensor& dGain)
	{
		MLRmsNormGBwdParams p{};
		p.inOff = in.offset; p.rstdOff = rstd.offset; p.dOutOff = dOut.offset; p.dGainOff = dGain.offset;
		p.rows = _rows; p.cols = _dim;
		return _k[kRmsG].Dispatch(p.cols, 1u, 1u, &p, (uint32)sizeof(p));
	}

	// ── RoPE — `dirSign = +1` fwd · `-1` bwd. ⚠️ **제자리**로 쓴다 ────
	bool _Rope(const MLTensor& t, float dirSign)
	{
		MLRopeParams p{};
		p.inOff = t.offset; p.outOff = t.offset; p.posOff = _tPos.offset;
		p.rows = _rows; p.dim = _dim; p.mode = 0u;
		p.theta = MLTModelCfg::kRopeTheta; p.dirSign = dirSign;
		return _k[kRope].Dispatch(p.Pairs(), p.rows, 1u, &p, (uint32)sizeof(p));
	}
};
