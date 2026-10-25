// mltp2enc.cw — 👁️ **P2 인코더 몸통** · 프레임 → 활성 → 프레임. (등록문 = `mltp2.cw`)
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **걸음 2 등록문** — ⚠️ 재기 전에 적는다. 아래 수를 보고 나서 고치면 판정이 아니다.
// ══════════════════════════════════════════════════════════════════════════════
//
//   ```
//   프레임(64² 바이트)
//     → patch_embed(자리표 [64·256, D] · 자리표2 [64, D])  → patch [64, D]
//     → gemm(사전 Wd **[N, D]**)                            → score [64, N]   ⭐ 유닛 = **한 행**
//     → act_topk(k)                                        → ids/mag [64, k]
//     → vis_recon(코드북 [N, 192])                          → recon [64, 192]
//     → sub(recon, target)                                 → dRecon [64, 192]
//     → vis_recon_bwd_mag  → dMag           → act_topk_bwd → dScore
//     → gemm(dScore·Wdᵗ)   → dPatch         → gemm(patchᵗ·dScore) → dWd
//     → patch_embed_bwd    → dSlot
//   ```
//   ⭐ **커널을 하나도 새로 안 만들었다** — 여덟 장이 전부 판정 ①② 를 통과한 것이다.
//
// ★ **기울기 넷이 전부 `g` 블록에 곧바로 써진다** — 복사도 0 채움도 없다.
//   `patch_embed_bwd`·`vis_recon_bwd_tab`·`gemm` 셋이 다 **쓴다**(더하지 않는다)이고, 각 가중치가
//   그래프에 **한 번만** 나오므로 `beta = 0` 이 맞다(P0/P1 에서 쓴 그 관용구).
//   ⭐ 그중 가장 예쁜 자리: **`dPos` 는 커널이 없다**(`dPos == dOut`) ⇒ **`dPatch` 를 `g` 의 `pos` 칸에
//     직접 만들게** 했다. 그러면 「자리표2의 기울기」가 계산 없이 제자리에 놓인다.
//     ⚠️ 그래서 **순서가 계약**이다: `dPatch`(g+oPos) 를 만든 **뒤에** `patch_embed_bwd` 가 그것을 읽는다.
//
// ══════════════════════════════════════════════════════════════════════════════
// ⭐ **크기 — 그리고 「예산을 무엇으로 세나」를 여기서 정한다**
// ══════════════════════════════════════════════════════════════════════════════
//   `MLT.md` 등록값: **`k = 8` · `N = 1000`**(회차 19 가 512 를 고쳤다 — 서로 다른 8×8 패치 1999개).
//   `D = 128` — ⚠️ **이것은 근거가 아니라 관례다**(본체 `MLTModelCfg::kDim` 과 같은 폭). 활성이
//     `(심볼, 값)` 슬롯으로 들어가므로 `D` 가 `d_model` 과 같아야 할 이유는 **없다**.
//     ⇒ 관례를 근거로 쓰지 않기 위해 **예산 관문**을 아래처럼 둔다.
//
//   `MLT.md` 는 **인코더 ≤ 0.5M** 을 등록했고 근거가 *"두꺼우면 접지가 그 안에 숨는다"* 다.
//   ⚠️⚠️ 그런데 `patch_embed` 의 자리표가 **`64자리 × 256바이트 × D`** 라 그것만으로 2.1M 이다.
//   ★ **그래서 예산을 「움직일 수 있는 파라미터」로 센다** — 근거:
//     이 세계의 바이트 종류는 **6**(A단계 ㉣)이므로 자리표의 대부분 행은 **어떤 입력에도 기울기가
//     정확히 0** 이다(판정 ② 가 그 0 을 실제로 봤다 — `dSlot` 의 |ana| 가 나타난 행에만 있었다).
//     ⇒ 기울기가 항등적으로 0 인 파라미터는 **접지를 숨길 수 없다.** 예산의 근거가 겨누는 것은
//       살아 있는 쪽이고, 죽은 행은 **메모리 비용**일 뿐이다.
//   ⚠️ **그래서 로그가 둘 다 찍는다**(할당 · 살아있음) — 하나만 적으면 다음 사람이 반드시 오독한다.
//   ⚠️ **살아있는 수는 세계에 달렸다** — 다른 세계로 옮기면 **다시 센다**(그 수를 박아 두지 않는다).
//   ⚠️ 그리고 **바이트를 압축된 알파벳으로 다시 매핑하지 않는다** — 그러면 알파벳을 **우리가**
//     고르는 것이고 등록문(*"이 모델의 알파벳은 바이트다"*)에 정면으로 어긋난다.
//
// ══════════════════════════════════════════════════════════════════════════════
// ⭐ **사전 유닛의 크기 정규화 — 왜 이것이 「기제 추가」가 아닌가**
// ══════════════════════════════════════════════════════════════════════════════
//   회차 23·24·25 가 같은 것을 봤다: **사용률이 ~35 에서 안 움직인다**(데이터 16배 → 1.26배 ·
//   `N` 8배 → 1.12배). ⇒ 병목은 **top-k 승자독식**(죽은 코드)이다.
//   ★ 그 승자독식의 한 원인은 **우리 파라미터화의 인공물**이다: `score = patch·Wd` 에서
//     유닛의 **열이 길다는 이유만으로** 이긴다. 그것은 **데이터의 성질이 아니다.**
//   ⇒ 크기를 고르게 맞추는 것은 *"정답의 구조를 우리가 주는 것"*(`mltconcept.md` 의 ㈀ 경고)이
//     아니라 **우리가 만든 잡음을 없애는 것**이다. 구조는 하나도 주지 않는다(방향은 그대로 배운다).
//   ⚠️ 그래도 **모델 변경이므로 A/B 로 등록해서** 쓴다(`mltp2u.cw`) — 조용히 켜지 않는다.
//
//   ⭐ **새 커널이 0개다**: `Wd` 를 **`[N, D]`** 로 놓으면 사전 유닛 하나가 **한 행**이 되고,
//     이미 판정 ①② 를 통과한 **`rmsnorm`** 이 정확히 「행을 단위 RMS 로」 한다.
//     ★ 전치는 gemm 의 `transA`/`transB` 가 공짜로 해 준다(선행차원 인자가 없어도 된다):
//     ```
//     score  = patch[64,D] · Wdᵗ         → transB = 1
//     dPatch = dScore[64,N] · Wd[N,D]    → 전치 없음
//     dWd    = dScoreᵗ · patch           → transA = 1  (M=N, N=D, K=64)
//     ```
//   ⚠️ **제자리로 걸 수 있다** — `rmsnorm` 셰이더는 행마다 스레드 하나이고 **제곱합을 먼저 다 읽은 뒤**
//     쓴다. ⇒ `inOff == outOff` 가 안전하다.
//   ⚠️ 정규화는 **AdamStep 뒤의 사영**이다(Adam 의 `m`/`v` 는 원래 기울기를 그대로 본다).
//   ⚠️⚠️ **이득을 1 로 두면 안 된다** — 크기를 고르게 하는 **동시에** 평균 크기를 **19배**로 키운다
//     (`Wd` 의 초기 RMS 가 0.052 다). 회차 26 의 첫 실행이 그것으로 통째로 무효가 됐다
//     ⇒ 이득은 **`kNormRms`**(= 초기 RMS)다. 그러면 **흩어짐만** 없어지고 평균 크기는 그대로다.
//
// ══════════════════════════════════════════════════════════════════════════════
// ⚠️ **손실 = MSE** 이고 그 예외의 근거는 `mltp2.cw` 등록문에 있다(재구성은 다봉이 아니다).
//   ★ 기울기는 `sub` 이 낸 **합**(`½Σd²` 의 미분)이고 **평균으로 나누지 않는다** — Adam 은 배율
//     불변이라 그 나눗셈이 학습을 바꾸지 않고, 사람이 읽는 수(MSE)만 CPU 에서 나눈다.
//     ⚠️ 그래서 「손실 배율」과 「보고 배율」이 다르다는 것을 여기 적어 둔다(P0 에서 밟은 자리).

using namespace PE;

// ══════════════════════════════════════════════════════════════════════════════
// ⚙️ 설정 — ★ **정본은 이 구조체다**(문서가 아니라 여기가 이긴다).
// ══════════════════════════════════════════════════════════════════════════════
struct MLTP2Cfg
{
	static constexpr uint32 kSide    = 64u;                      // 프레임 한 변
	static constexpr uint32 kPatch   = 8u;                       // 패치 한 변
	static constexpr uint32 kGrid    = kSide / kPatch;            // 8
	static constexpr uint32 kPatches = kGrid * kGrid;             // 64 = 행
	static constexpr uint32 kSlots   = kPatch * kPatch;           // 64 = 패치 안 자리
	static constexpr uint32 kSlotRows = kSlots * 256u;            // 16384 = 자리표의 행
	static constexpr uint32 kPix     = kPatch * kPatch * 3u;      // 192 (RGB)
	static constexpr uint32 kD       = 128u;                      // ⚠️ 관례(본체와 같은 폭)
	static constexpr uint32 kK       = 8u;                        // 등록값(기본)
	// ⭐ **`k` 는 스윕 축이다**(걸음 4) ⇒ 텐서는 상한으로 잡고 **쓰는 만큼만** 쓴다.
	//   ⚠️ 커널이 `r*k + j` 로 색인하므로 배치는 `rows × k` 로 **꽉 차 있고**, 남는 꼬리는
	//     아무도 읽지도 쓰지도 않는다(그래서 아레나를 다시 만들지 않아도 팔이 바뀐다).
	static constexpr uint32 kKMax    = 128u;
	static constexpr uint32 kN       = 1000u;                     // 등록값(회차 19)
	static constexpr uint32 kFootRank = 2u;                       // P3-A1 등록값
	static constexpr uint32 kFootSpan = kGrid * 2u - 1u;          // 상대 dx/dy = [-7,7]

	// 초기 산포 — ⚠️ **코드북을 작게** 둔다: `recon ≈ 0` 이라야 「초기 MSE = 표적의 제곱평균」이
	//   성립하고, 그 등식이 판정 ③ 의 관문 ㉠ 이다(표적이 제자리에 있다는 첫 증거).
	static constexpr float kInitSlot = 0.02f;
	static constexpr float kInitPos  = 0.02f;
	static constexpr float kInitWd   = 0.09f;    // ≈ 1/√D
	// ⭐ **크기 정규화가 목표로 삼는 RMS** — ⚠️ **초기 `Wd` 의 RMS 그 자체**다.
	//   `_Spread` 는 `[-1,1)` 균등이라 RMS 가 `1/√3 = 0.5774` ⇒ 초기 원소 RMS = `kInitWd · 0.5774`.
	//   ★ **왜 1 이 아닌가**(실측으로 밟았다): 이득을 1 로 두면 크기를 고르게 하는 **동시에**
	//     평균 크기를 **19배**로 키운다 ⇒ `score`·`mag` 가 19배가 되어 recon 이 터진다
	//     (회차 26 첫 실행: 학습 MSE 0.0123 → 0.0565 · 시험 0.0398 → 0.3905).
	//     ⇒ 그건 「고르게」를 잰 것이 아니라 「고르게 **하고 19배**」를 잰 것이다.
	//   ⇒ 목표 RMS 를 **초기값 그대로** 두면 사영이 **크기의 흩어짐만** 없애고 평균 크기는 그대로다.
	//   ⚠️ 이것은 **크기를 고정한다**는 뜻이기도 하다(학습 중 커지지 못한다) — 재구성의 크기는
	//     **코드북**이 자유롭게 키울 수 있으므로 막히지 않는다. ★ 「유닛마다 배우는 크기」를 두는 것은
	//     **다른 팔**이고 지금 등록하지 않는다.
	static constexpr float kNormRms  = kInitWd * 0.57735027f;
	static constexpr float kInitCode = 0.05f;
	// ⭐ **코드북** 행 정규화가 목표로 삼는 RMS — 같은 규칙(초기 RMS 그대로).
	//   ★ 회차 27 이 가리킨 자리다: 세기의 뜻은 `mag × 코드북 행` 이라, 행 크기가 흩어져 있으면
	//     같은 `mag` 가 전혀 다른 기여를 낸다.
	//   ⚠️ **`kInitCode` 뒤에 와야 한다** — 클래스 안 `constexpr` 는 **선언 순서**로 보인다
	//     (앞에 두면 `'kInitCode' was not declared in this scope` 로 컴파일이 죽는다 · 실측).
	static constexpr float kNormCodeRms = kInitCode * 0.57735027f;

	// ══════════════════════════════════════════════════════════════════════════
	// ⭐ **은닉 한 겹의 척도 — 초기값이 아니라 RMSNorm 이 맡는다**
	// ══════════════════════════════════════════════════════════════════════════
	//   회차 31 은 초기값 하나로 순전파 척도와 Adam 의 상대 학습률을 동시에 맞출 수 없음을 실측했다.
	//   ⇒ `W1`·`Wd` 는 둘 다 기존 산포로 두고, 은닉 출력만 **기존 패치의 초기 RMS** 로 정규화한다.
	//   ★ 패치 한 원소 = 슬롯 64개의 합 + 위치 한 칸이므로
	//     `kInitSlot · sqrt((kSlots + 1) / 3) = 0.09309...` 이다.
	//   ⚠️ gain 은 학습 파라미터가 아니다 — 두 은닉 팔에 같은 척도를 주는 고정 배관이다.
	static constexpr float kInitW1       = kInitWd;
	static constexpr float kHiddenOutRms = 0.093094f;

	// 🗂 **프레임 풀** — ⚠️ `MLArena::Write` 는 **동기이고 무겁다**(스테이징 + 큐 유휴 대기).
	//   P0 에서 스텝마다 부르다 **40배**를 밟았다 ⇒ 프레임 전부를 **한 번** 올려 두고 고른다.
	//   ⭐ 그리고 **복사가 0 이다** — `patch_embed`/`sub` 가 오프셋을 **인자로** 받으므로
	//     「지금 프레임」은 **오프셋을 바꾸는 것**이지 옮기는 것이 아니다(커널도 gemm-복사도 없다).
	static constexpr uint32 kPool = 40u;          // 기본(회차 21·23 이 쓰는 40 = 학습 32 + 시험 8)

	static constexpr float kLr = 3.0e-3f, kB1 = 0.9f, kB2 = 0.999f;
	static constexpr float kAdamEps = 1.0e-8f, kWd = 0.0f;

	// ⚠️⚠️ **파라미터 배치는 `N` 에 달렸으므로 상수가 아니다** — `MLTP2Enc` 의 멤버가 `Setup` 에서
	//   계산한다(`_oSlot`/`_oPos`/`_oWd`/`_oCode`/`_pCount`). ★ 블록은 여전히 **연속**이라
	//   AdamW 가 디스패치 한 번이다.
	//   ★ 그리고 gemm 에 **선행차원 인자가 없으므로**(H=1 의 그 이유) *"큰 `N` 으로 잡고 앞부분만
	//     쓴다"* 가 불가능하다 — 보폭이 안 맞는다. ⇒ `N` 을 바꾸면 **아레나를 다시 만든다.**
};

class MLTP2Enc
{
public:
	// ══════════════════════════════════════════════════════════════════
	// 🏗 셋업 — 아레나 + 텐서 + 커널 여덟. ⚠️ `Create` 가 먼저 `Destroy` 하므로 **팔마다 다시
	//   불러도 같은 초기값에서 출발한다**(결정적 산포라 비트까지 같다 — A/B 의 전제).
	// ══════════════════════════════════════════════════════════════════
	// ⚠️ `poolCap` = 이 아레나가 담을 프레임 수. **아레나 크기에 들어가므로 인자다** — 늘 최댓값으로
	//   잡으면 항상 도는 조립 검사(판정 ③, 프레임 하나)까지 뚱뚱해진다.
	// ⭐ `hidden` = 은닉 폭. **0 이면 은닉이 없다**(지금까지의 모델 그대로 · `H = D`).
	//   `useSwiglu` = 은닉에 **비선형**을 건다(꺼져 있으면 **선형 두 겹**).
	//   ⚠️ 셋은 **같은 코드**를 탄다 — 팔마다 코드가 갈리면 그 차이가 판정에 섞인다.
	bool Setup(RHI* rhi, uint32 poolCap = MLTP2Cfg::kPool, uint32 nDict = MLTP2Cfg::kN,
		uint32 hidden = 0u, bool useSwiglu = false, uint32 headRank = 0u, bool coupleScore = false,
		bool normHeads = false, bool residualSwap = false, bool coeffSweep = false, bool globalFoot = false)
	{
		typedef MLTP2Cfg C;
		if (rhi == nullptr || poolCap == 0u || nDict == 0u || (headRank != 0u && hidden != 0u) ||
			((residualSwap || coeffSweep) && (headRank != 0u || hidden != 0u)) ||
			(globalFoot && (hidden != 0u || headRank != 0u || residualSwap || coeffSweep))) return false;
		_poolCap = poolCap;
		// ⭐ 사전 크기·은닉 폭과 그것이 정하는 배치 — ⚠️ **여기가 정본**이다(문서가 아니다).
		_n = nDict;
		_hid = hidden;                       // 0 = 은닉 없음
		_swi = useSwiglu && (hidden != 0u);
		_rank = headRank; _couple = coupleScore && (headRank != 0u);
		_headNorm = normHeads && (headRank != 0u);
		_resSwapCap = residualSwap; _resSwap = residualSwap;
		_coeffCap = coeffSweep; _coeff = coeffSweep && !residualSwap;
		_globalFoot = globalFoot;
		_freezeCode = false;
		_headScale = (_rank != 0u) ? (1.73205081f / (C::kInitWd * Sqrt((float)_rank))) : 1.0f;
		_h   = (hidden != 0u) ? hidden : C::kD;   // 사전이 보는 폭
		const uint32 w1 = (_hid != 0u) ? (_h * C::kD) : 0u;
		_oSlot = 0u;
		_oPos  = _oSlot + C::kSlotRows * C::kD;
		_oW1a  = _oPos  + C::kPatches * C::kD;
		_oW1b  = _oW1a  + w1;
		_oWd   = _oW1b  + (_swi ? w1 : 0u);
		_oS1 = _oWd;
		_oS2 = _oS1 + ((_rank != 0u) ? _rank * C::kD : 0u);
		_oC1 = _oS2 + ((_rank != 0u) ? _n * _rank : 0u);
		_oC2 = _oC1 + ((_rank != 0u) ? _rank * C::kD : 0u);
		_oCode = (_rank != 0u) ? (_oC2 + _n * _rank) : (_oWd + _n * _h);
		_oFootX = _oCode + _n * C::kPix;
		_oFootY = _oFootX + (_globalFoot ? _n * C::kFootRank * C::kFootSpan : 0u);
		_pCount = _oFootY + (_globalFoot ? _n * C::kFootRank * C::kFootSpan : 0u);
		const uint32 actRows = _globalFoot ? 1u : C::kPatches;

		const uint32 act =
			  poolCap * C::kSide * C::kSide        // 프레임 풀
			+ poolCap * C::kPatches * C::kPix      // 표적 풀
			+ C::kPatches * C::kPix * 2u           // recon · dRecon
			+ C::kPatches * C::kD            // patch
			+ C::kPatches * _n * 2u       // score · dScore
			+ ((_rank != 0u) ? (C::kPatches * _n * 2u + C::kPatches * _rank * 4u) : 0u)
			                                      // 분리 계수·d계수 + S/C 저랭크 중간·기울기
			+ (_headNorm ? (C::kPatches * _n * 4u + _n + C::kPatches * 2u) : 0u)
			                                      // 정규화 S/C·그 기울기 + 공유 gain + rstd 둘
			+ actRows * C::kKMax * 3u         // ids · mag · dMag (⭐ 상한으로 잡는다)
			+ (_globalFoot ? C::kPatches * C::kD : 0u) // 절대 위치를 뺄 때 쓰는 고정 0 자리표
			+ (_resSwapCap ? C::kPatches * C::kKMax * 2u : 0u) // 잔차 1회 뒤 ids · mag
			+ (_coeffCap ? C::kPatches * C::kKMax : 0u) // 고정 ids 계수 갱신 뒤 mag
			+ actRows * C::kKMax             // ⭐ 회차 67 — **외부 `dMag`**(몸통에서 되돌아온 기울기)
			+ _h + C::kPix + nDict           // ⭐ Wd/코드북 정규화 이득 + rstd
			+ ((hidden != 0u) ? (C::kPatches * hidden * 7u + hidden + C::kPatches) : 0u)
			                                      // ⭐ 은닉 칸 일곱 + 고정 gain(H) + rstd(패치)
			+ 64u;                           // ⚠️ 뒤 패딩(`robustBufferAccess` 가 꺼져 있다)
		const uint32 need = _pCount * 4u + act;

		if (!_ar.Create(rhi, need)) { LogA("[mlt] 👁️ 아레나 생성 실패(need=%u)\n", need); return false; }

		_tP = _ar.Alloc(1, _pCount);
		_tG = _ar.Alloc(1, _pCount);
		_tM = _ar.Alloc(1, _pCount);
		_tV = _ar.Alloc(1, _pCount);

		_tFPool  = _ar.Alloc(_poolCap, C::kSide * C::kSide);
		_tTPool  = _ar.Alloc(_poolCap, C::kPatches * C::kPix);
		_tPatch  = _ar.Alloc(C::kPatches, C::kD);
		_tScore  = _ar.Alloc(C::kPatches, _n);
		_tIds    = _ar.Alloc(actRows, C::kKMax);
		_tMag    = _ar.Alloc(actRows, C::kKMax);
		_tRecon  = _ar.Alloc(C::kPatches, C::kPix);
		_tDRec   = _ar.Alloc(C::kPatches, C::kPix);
		_tDMag   = _ar.Alloc(actRows, C::kKMax);
		_tDScore = _ar.Alloc(C::kPatches, _n);
		if (_globalFoot) _tZeroPos = _ar.Alloc(C::kPatches, C::kD);
		if (_resSwapCap)
		{
			_tIds2 = _ar.Alloc(C::kPatches, C::kKMax);
			_tMag2 = _ar.Alloc(C::kPatches, C::kKMax);
		}
		if (_coeffCap) _tMagC = _ar.Alloc(C::kPatches, C::kKMax);
		if (_rank != 0u)
		{
			_tCoef = _ar.Alloc(C::kPatches, _n); _tDCoef = _ar.Alloc(C::kPatches, _n);
			_tSH = _ar.Alloc(C::kPatches, _rank); _tCH = _ar.Alloc(C::kPatches, _rank);
			_tDSH = _ar.Alloc(C::kPatches, _rank); _tDCH = _ar.Alloc(C::kPatches, _rank);
			if (_headNorm)
			{
				_tScoreN = _ar.Alloc(C::kPatches, _n); _tCoefN = _ar.Alloc(C::kPatches, _n);
				_tDScoreN = _ar.Alloc(C::kPatches, _n); _tDCoefN = _ar.Alloc(C::kPatches, _n);
				_tGainScore = _ar.Alloc(1, _n);
				_tRstdS = _ar.Alloc(1, C::kPatches); _tRstdC = _ar.Alloc(1, C::kPatches);
			}
		}
		_tOnes   = _ar.Alloc(1, _h);          // ⭐ Wd 정규화 이득 — 폭은 은닉 H 를 따른다
		if (_hid != 0u)
		{
			// ⭐ 은닉 한 겹의 칸들 — ⚠️ 모드 0 에서는 **하나도 안 잡는다**(아레나가 그대로다).
			_tA  = _ar.Alloc(C::kPatches, _h); _tB  = _ar.Alloc(C::kPatches, _h);
			_tH  = _ar.Alloc(C::kPatches, _h); _tHN = _ar.Alloc(C::kPatches, _h);
			_tDH = _ar.Alloc(C::kPatches, _h);
			_tDA = _ar.Alloc(C::kPatches, _h); _tDB = _ar.Alloc(C::kPatches, _h);
			_tGainH = _ar.Alloc(1, _h); _tRstdH = _ar.Alloc(1, C::kPatches);
		}
		_tGainPix = _ar.Alloc(1, C::kPix);   // ⭐ 코드북 행 정규화의 이득(픽셀 축)
		_tRstd   = _ar.Alloc(1, _n);         // 그 부산물(사전 유닛마다 하나 — 둘이 같이 쓴다)
		// ⭐ 회차 67 — **몸통에서 되돌아온 기울기**를 담는 자리. ⚠️ **맨 뒤에 잡는다** —
		//   앞의 오프셋이 하나도 안 흔들려야 지난 회차들의 **비트 재현**이 유지된다.
		_tDMagX  = _ar.Alloc(actRows, C::kKMax);
		if (!_tRstd.IsValid())
		{ LogA("[mlt] 👁️ 텐서 할당 실패(need=%u · used=%u)\n", need, _ar.Used()); return false; }

		// ⭐ `dPatch` 를 **`g` 블록의 `pos` 칸**에 겹쳐 둔다 — `dPos == dPatch` 이므로 그 자리가
		//   곧 「자리표2의 기울기」다. ⚠️ 겹치기는 **의도**이고, 아래 `Backward` 의 순서가 그 계약이다.
		_tDPatch.offset = _tG.offset + _oPos;
		_tDPatch.rows = C::kPatches; _tDPatch.cols = C::kD;

		// ── 초기 파라미터를 **한 번 만들어 멤버에 둔다** ─────────────
		//   ⭐ 씨앗마다 다시 만들지 않는다 — `ResetSeed()` 가 이 배열을 다시 올린다.
		_p0.Reset(0);
		for (uint32 i = 0; i < C::kSlotRows * C::kD; ++i) _p0.Add(_Spread(i, 11u) * C::kInitSlot);
		for (uint32 i = 0; i < C::kPatches * C::kD;  ++i) _p0.Add(_Spread(i, 12u) * C::kInitPos);
		if (_hid != 0u)
		{
			// ⭐ 상대 학습률을 맞춘다 — 출력 척도는 아래 RMSNorm 이 맡는다.
			for (uint32 i = 0; i < _h * C::kD; ++i) _p0.Add(_Spread(i, 15u) * C::kInitW1);
			if (_swi) for (uint32 i = 0; i < _h * C::kD; ++i) _p0.Add(_Spread(i, 16u) * C::kInitW1);
		}
		// ⭐ full-rank 기준선은 예전 `Wd`를 그대로 쓴다. 분리 팔은 같은 0.09 산포의 S/C 인수 네 장이다.
		if (_rank == 0u)
			for (uint32 i = 0; i < _h * _n; ++i) _p0.Add(_Spread(i, 13u) * C::kInitWd);
		else
		{
			for (uint32 i = 0; i < _rank * C::kD; ++i) _p0.Add(_Spread(i, 131u) * C::kInitWd);
			for (uint32 i = 0; i < _n * _rank;   ++i) _p0.Add(_Spread(i, 132u) * C::kInitWd);
			for (uint32 i = 0; i < _rank * C::kD; ++i) _p0.Add(_Spread(i, 133u) * C::kInitWd);
			for (uint32 i = 0; i < _n * _rank;   ++i) _p0.Add(_Spread(i, 134u) * C::kInitWd);
		}
		for (uint32 i = 0; i < _n * C::kPix;      ++i) _p0.Add(_Spread(i, 14u) * C::kInitCode);
		if (_globalFoot)
		{
			const uint32 footN = _n * C::kFootRank * C::kFootSpan;
			for (uint32 i = 0; i < footN; ++i)
			{
				const uint32 r = (i / C::kFootSpan) % C::kFootRank;
				const uint32 q = i % C::kFootSpan;
				_p0.Add(_Spread(i, 17u) * 0.02f + ((r == 0u && q == C::kGrid - 1u) ? 1.0f : 0.0f));
			}
			for (uint32 i = 0; i < footN; ++i)
			{
				const uint32 r = (i / C::kFootSpan) % C::kFootRank;
				const uint32 q = i % C::kFootSpan;
				_p0.Add(_Spread(i, 18u) * 0.02f + ((r == 0u && q == C::kGrid - 1u) ? 1.0f : 0.0f));
			}
		}
		if (_p0.Count() != _pCount)
		{ LogA("[mlt] 👁️ 파라미터 수 불일치 %u != %u\n", _p0.Count(), _pCount); return false; }
		if (!_ar.Write(_tP, _p0)) { LogA("[mlt] 👁️ 파라미터 업로드 실패\n"); return false; }
		// ⭐ 이득을 **목표 RMS** 로 채운다 — ⚠️ 1 로 두면 크기를 19배로 키운다(위 `kNormRms` 의 그 실측).
		//   ⚠️ 아레나는 0 으로 시작하므로 **안 채우면 정규화가 0 을 낸다**(조용히).
		{
			Array<float> g; g.Reset(0);
			for (uint32 i = 0; i < _h; ++i) g.Add(C::kNormRms);
			if (!_ar.Write(_tOnes, g)) { LogA("[mlt] 👁️ 이득 업로드 실패\n"); return false; }
		}
		if (_hid != 0u)
		{
			Array<float> g; g.Reset(0);
			for (uint32 i = 0; i < _h; ++i) g.Add(C::kHiddenOutRms);
			if (!_ar.Write(_tGainH, g)) { LogA("[mlt] 👁️ 은닉 정규화 이득 업로드 실패\n"); return false; }
		}
		if (_headNorm)
		{
			Array<float> g; g.Reset(0);
			// 기존 full-rank 점수의 초기 RMS: patchRms·(WdRms)·sqrt(D).
			for (uint32 i = 0; i < _n; ++i) g.Add(0.05473f);
			if (!_ar.Write(_tGainScore, g)) { LogA("[mlt] 👁️ 점수 정규화 이득 업로드 실패\n"); return false; }
		}
		{
			Array<float> g; g.Reset(0);
			for (uint32 i = 0; i < C::kPix; ++i) g.Add(C::kNormCodeRms);
			if (!_ar.Write(_tGainPix, g)) { LogA("[mlt] 👁️ 코드북 이득 업로드 실패\n"); return false; }
		}

		_step = 0u; _nPool = 0u;
		if (_kAct == 0u || _kAct > C::kKMax) _kAct = C::kK;
		SetFrame(0u);
		if (!_LoadAll(rhi)) return false;

		LogA("[mlt] 👁️ 인코더 — 아레나 %u float(%.1f MB) · D=%u k=%u N=%u · rank=%u couple=%u norm=%u foot=%u"
		     " · 패치 %u · 픽셀 %u · 풀 %u프레임\n",
			need, (double)((float)need * 4.0f / 1048576.0f), C::kD, _kAct, _n,
			_rank, _couple ? 1u : 0u, _headNorm ? 1u : 0u, _globalFoot ? 1u : 0u,
			C::kPatches, C::kPix, _poolCap);
		return true;
	}

	// ══════════════════════════════════════════════════════════════════
	// 📤 프레임 하나를 두 배열에 **잇는다**(올리지 않는다) — 부르는 쪽이 풀을 모아 한 번에 올린다.
	//   ⚠️ **표적도 RGB332 를 거친 값**이다(등록문) — 양자화 오차를 대조군과 학습이 똑같이 겪는다.
	//   ★ 표적의 픽셀 색인 = `(y·kPatch + x)·3 + 채널`. `vis_recon` 은 그냥 벡터로 보므로 이 규약은
	//     **우리가 정하는 것**이고, 한 곳(여기)에만 있으면 어긋날 수 없다.
	// ══════════════════════════════════════════════════════════════════
	static void AppendFrame(Array<float>& fr, Array<float>& tg, const uint8* px)
	{
		typedef MLTP2Cfg C;
		if (px == nullptr) return;
		for (uint32 i = 0; i < C::kSide * C::kSide; ++i) fr.Add((float)px[i]);
		for (uint32 gy = 0; gy < C::kGrid; ++gy)
			for (uint32 gx = 0; gx < C::kGrid; ++gx)
				for (uint32 y = 0; y < C::kPatch; ++y)
					for (uint32 x = 0; x < C::kPatch; ++x)
					{
						float c[3];
						Unpack(px[(gy * C::kPatch + y) * C::kSide + (gx * C::kPatch + x)], c);
						tg.Add(c[0]); tg.Add(c[1]); tg.Add(c[2]);
					}
	}

	// 📤 풀을 **한 번에** 올린다 — ⚠️ `Write` 는 이 함수에서 **두 번만** 불린다.
	bool WritePool(const Array<float>& fr, const Array<float>& tg, uint32 n)
	{
		typedef MLTP2Cfg C;
		if (n == 0u || n > _poolCap) { LogA("[mlt] 👁️ 풀 크기 %u (상한 %u)\n", n, _poolCap); return false; }
		if (fr.Count() != n * C::kSide * C::kSide || tg.Count() != n * C::kPatches * C::kPix)
		{ LogA("[mlt] 👁️ 풀 원소 수 불일치 fr=%u tg=%u (n=%u)\n", fr.Count(), tg.Count(), n); return false; }
		// ⚠️ **정확히 그 길이의 텐서**로 쓴다 — `Write` 는 크기가 달라도 `min` 만 올리고 `true` 를 준다.
		MLTensor a; a.offset = _tFPool.offset; a.rows = 1u; a.cols = fr.Count();
		MLTensor b; b.offset = _tTPool.offset; b.rows = 1u; b.cols = tg.Count();
		if (!_ar.Write(a, fr) || !_ar.Write(b, tg)) return false;
		_nPool = n;
		SetFrame(0u);
		return true;
	}

	// 🎯 「지금 프레임」을 고른다 — ⭐ **복사가 0 이다**(오프셋만 바뀐다).
	void SetFrame(uint32 idx) { SetFramePair(idx, idx); }

	// ⭐ **입력 프레임과 표적 프레임을 가른다**(회차 48) — 배관이지 모델이 아니다.
	//   ★ `SetFrame(i)` 는 `SetFramePair(i, i)` 와 **비트 동일**이고, 회차 48 의 팔 ㈀ 이
	//     회차 46 재현으로 그 사실을 **검사한다**(안 검사하면 배관 차이가 판정에 섞인다).
	//   ⚠️ 표적만 옮기는 것이라 `patch_embed` 는 `_curF` 를, `sub`/잔차 커널은 `_curT` 를
	//     본다 — 그 갈림이 이미 코드에 있어서 새 커널이 필요 없다.
	void SetFramePair(uint32 inIdx, uint32 tgtIdx)
	{
		typedef MLTP2Cfg C;
		_curF = _tFPool.offset + inIdx  * (C::kSide * C::kSide);
		_curT = _tTPool.offset + tgtIdx * (C::kPatches * C::kPix);
	}

	uint32 PoolCount() const { return _nPool; }
	void SetResidualSwap(bool on) { _resSwap = on && _resSwapCap; if (_resSwap) _coeff = false; }
	void SetCoeffSweep(bool on) { _coeff = on && _coeffCap; if (_coeff) _resSwap = false; }
	// 🧊 코드북은 파라미터 블록의 마지막 구간이다. AdamW count를 그 직전에서 끊으면
	// gradient뿐 아니라 weight decay와 moment까지 멈춰 진짜 비트 동결이 된다.
	void SetFreezeCode(bool on) { _freezeCode = on; }

	// 프레임 하나만 쓰는 자리(판정 ③)의 편의 — 풀 슬롯 0 에 올린다.
	bool UploadFrame(const uint8* px)
	{
		Array<float> fr, tg; fr.Reset(0); tg.Reset(0);
		AppendFrame(fr, tg, px);
		return WritePool(fr, tg, 1u);
	}

	// ══════════════════════════════════════════════════════════════════
	// ▶ forward — 다섯 걸음(마지막 `sub` 이 곧 손실의 기울기다)
	// ══════════════════════════════════════════════════════════════════
	bool Forward()
	{
		typedef MLTP2Cfg C;
		// ① 패치 임베딩
		{
			MLPatchEmbedParams q{};
			q.frameOff = _curF; q.aOff = _tP.offset + _oSlot;
			// P3-A1은 후보 점수에서 절대 패치 위치를 제거한다. 0 자리표는 고정 activation이다.
			q.bOff = _globalFoot ? _tZeroPos.offset : (_tP.offset + _oPos); q.cOff = _tPatch.offset;
			q.frameW = C::kSide; q.frameH = C::kSide; q.patchK = C::kPatch; q.dim = C::kD;
			if (!_k[kPE].Dispatch(C::kD, q.Patches(), 1u, &q, (uint32)sizeof(q))) return _E("patch_embed");
		}
		// ②a 은닉 한 겹(있으면) — ⭐ `W1a`/`W1b` 는 **[H, D]**(은닉 유닛 = 한 행) ⇒ `transB = 1`.
		uint32 hOff = _tPatch.offset;        // 사전이 보는 것(모드 0 이면 패치 그 자체)
		if (_hid != 0u)
		{
			if (!_Gemm(_tPatch.offset, _tP.offset + _oW1a, _tA.offset,
				C::kPatches, _h, C::kD, 0u, 1u)) return _E("patch·W1aT");
			if (_swi)
			{
				if (!_Gemm(_tPatch.offset, _tP.offset + _oW1b, _tB.offset,
					C::kPatches, _h, C::kD, 0u, 1u)) return _E("patch·W1bT");
				// ⭐ `swiglu` 는 원소별이다 — **판정 ①② 를 이미 통과한 커널**이다.
				MLSwigluParams s{}; s.aOff = _tA.offset; s.bOff = _tB.offset;
				s.outOff = _tH.offset; s.count = C::kPatches * _h;
				if (!_k[kSwi].Dispatch(s.count, 1u, 1u, &s, (uint32)sizeof(s))) return _E("swiglu");
				hOff = _tH.offset;
			}
			else hOff = _tA.offset;          // ⚠️ 선형 투영 — SwiGLU 만 뺀 공유 경로 대조군

			// ⭐ 두 은닉 팔의 출력 척도를 기존 패치 RMS 로 고정한다.
			//   ⚠️ 이 연산 자체는 입력 의존 비선형이므로 ②는 순수 선형/용량 대조가 아니다.
			MLRmsNormParams q{};
			q.inOff = hOff; q.gainOff = _tGainH.offset;
			q.outOff = _tHN.offset; q.rstdOff = _tRstdH.offset;
			q.rows = C::kPatches; q.cols = _h; q.eps = 1.0e-6f;
			if (!_k[kRms].Dispatch(q.rows, 1u, 1u, &q, (uint32)sizeof(q))) return _E("hidden_rmsnorm");
			hOff = _tHN.offset;
		}
		uint32 scoreOut = _tScore.offset, coefOut = _tCoef.offset;
		// ②b 사전 점수. 분리 모드는 같은 patch에서 선택 S와 계수 C를 독립 저랭크 머리로 만든다.
		if (_rank == 0u)
		{
			if (!_Gemm(hOff, _tP.offset + _oWd, _tScore.offset,
				C::kPatches, _n, _h, 0u, 1u)) return _E("h·WdT");
		}
		else
		{
			if (!_Gemm(_tPatch.offset, _tP.offset + _oS1, _tSH.offset,
				C::kPatches, _rank, C::kD, 0u, 1u)) return _E("patch·S1T");
			if (!_Gemm(_tSH.offset, _tP.offset + _oS2, _tScore.offset,
				C::kPatches, _n, _rank, 0u, 1u)) return _E("SH·S2T");
			if (!_Gemm(_tPatch.offset, _tP.offset + _oC1, _tCH.offset,
				C::kPatches, _rank, C::kD, 0u, 1u)) return _E("patch·C1T");
			if (!_Gemm(_tCH.offset, _tP.offset + _oC2, _tCoef.offset,
				C::kPatches, _n, _rank, 0u, 1u)) return _E("CH·C2T");
			if (_headNorm)
			{
				MLRmsNormParams s{}; s.inOff = _tScore.offset; s.gainOff = _tGainScore.offset;
				s.outOff = _tScoreN.offset; s.rstdOff = _tRstdS.offset;
				s.rows = C::kPatches; s.cols = _n; s.eps = 1.0e-6f;
				if (!_k[kRms].Dispatch(s.rows, 1u, 1u, &s, (uint32)sizeof(s))) return _E("score_rmsnorm");
				MLRmsNormParams c = s; c.inOff = _tCoef.offset; c.outOff = _tCoefN.offset; c.rstdOff = _tRstdC.offset;
				if (!_k[kRms].Dispatch(c.rows, 1u, 1u, &c, (uint32)sizeof(c))) return _E("coef_rmsnorm");
				scoreOut = _tScoreN.offset; coefOut = _tCoefN.offset;
			}
		}
		// ③ 활성 k개
		{
			MLActTopkParams q{}; q.scoreOff = scoreOut; q.idsOff = _tIds.offset;
			// 전역 모드는 [64,N]의 연속 score를 [1,64N]으로 본다. id=anchor*N+semantic id.
			q.magOff = _tMag.offset; q.rows = _globalFoot ? 1u : C::kPatches;
			q.dict = _globalFoot ? C::kPatches * _n : _n; q.k = _kAct;
			// ⭐ 선택 기준을 고른다 — `act_topk`(가장 큰 값) ↔ `act_topk_abs`(가장 큰 **절댓값**).
			//   ⚠️ **bwd 는 같다**(`act_topk_bwd`) — 관계가 `mag = z[ids]` 로 글자 그대로 같다.
			const uint32 sel = _absSel ? (uint32)kTopA : (uint32)kTop;
			if (!_k[sel].Dispatch(q.rows, 1u, 1u, &q, (uint32)sizeof(q)))
				return _E(_absSel ? "act_topk_abs" : "act_topk");
		}
		// 분리 팔은 top-k가 쓴 `mag=S[id]`를 별도 계수로 덮는다. 양수 scale이라 선택 순서는 안 바뀐다.
		if (_rank != 0u)
		{
			MLActGatherParams q{}; q.idsOff = _tIds.offset; q.magOff = _tMag.offset;
			q.rows = C::kPatches; q.dict = _n; q.k = _kAct;
			if (_couple)
			{
				q.aOff = scoreOut; q.bOff = coefOut; q.useB = 1u;
				q.scale = (_headNorm ? 1.0f : _headScale) * 0.70710678f;
			}
			else
			{
				q.aOff = coefOut; q.bOff = coefOut; q.useB = 0u;
				q.scale = _headNorm ? 1.0f : _headScale;
			}
			if (!_k[kGather].Dispatch(C::kPatches * _kAct, 1u, 1u, &q, (uint32)sizeof(q)))
				return _E("act_gather");
		}
		// ④ 되만들기
		if (_globalFoot)
		{
			MLFootReconParams q{}; q.idsOff = _tIds.offset; q.magOff = _tMag.offset;
			q.codeOff = _tP.offset + _oCode; q.xOff = _tP.offset + _oFootX;
			q.yOff = _tP.offset + _oFootY; q.outOff = _tRecon.offset;
			q.frames = 1u; q.k = _kAct; q.grid = C::kGrid; q.pixels = C::kPix;
			q.dict = _n; q.rank = C::kFootRank; q.span = C::kFootSpan;
			if (!_k[kFoot].Dispatch(C::kPix, C::kPatches, 1u, &q, (uint32)sizeof(q)))
				return _E("foot_recon");
		}
		else
		{
			MLVisReconParams q{}; q.idsOff = _tIds.offset; q.magOff = _tMag.offset;
			q.tableOff = _tP.offset + _oCode; q.outOff = _tRecon.offset;
			q.rows = C::kPatches; q.k = _kAct; q.pixels = C::kPix; q.dict = _n;
			if (!_k[kVis].Dispatch(C::kPix, C::kPatches, 1u, &q, (uint32)sizeof(q))) return _E("vis_recon");
		}
		// ④′ 잔차를 본 교체 한 번. 선택은 이산/stop-gradient이고 최종 mag=S[id]라 기존 bwd를 재사용한다.
		if (_resSwap)
		{
			MLActResidualSwapParams s{};
			s.targetOff = _curT; s.reconOff = _tRecon.offset; s.scoreOff = scoreOut;
			s.tableOff = _tP.offset + _oCode;
			s.idsInOff = _tIds.offset; s.magInOff = _tMag.offset;
			s.idsOutOff = _tIds2.offset; s.magOutOff = _tMag2.offset;
			s.rows = C::kPatches; s.k = _kAct; s.pixels = C::kPix; s.dict = _n; s.eps = 1.0e-6f;
			if (!_k[kResidualSwap].Dispatch(C::kPatches * 64u, 1u, 1u, &s, (uint32)sizeof(s)))
				return _E("act_residual_swap");

			MLVisReconParams q{}; q.idsOff = _tIds2.offset; q.magOff = _tMag2.offset;
			q.tableOff = _tP.offset + _oCode; q.outOff = _tRecon.offset;
			q.rows = C::kPatches; q.k = _kAct; q.pixels = C::kPix; q.dict = _n;
			if (!_k[kVis].Dispatch(C::kPix, C::kPatches, 1u, &q, (uint32)sizeof(q))) return _E("vis_recon_after_swap");
		}
		else if (_coeff)
		{
			MLActCoeffSweepParams s{};
			s.targetOff = _curT; s.reconOff = _tRecon.offset; s.tableOff = _tP.offset + _oCode;
			s.idsOff = _tIds.offset; s.magInOff = _tMag.offset; s.magOutOff = _tMagC.offset;
			s.rows = C::kPatches; s.k = _kAct; s.pixels = C::kPix; s.dict = _n; s.eps = 1.0e-6f;
			if (!_k[kCoeffSweep].Dispatch(C::kPatches * 64u, 1u, 1u, &s, (uint32)sizeof(s)))
				return _E("act_coeff_sweep");

			MLVisReconParams q{}; q.idsOff = _tIds.offset; q.magOff = _tMagC.offset;
			q.tableOff = _tP.offset + _oCode; q.outOff = _tRecon.offset;
			q.rows = C::kPatches; q.k = _kAct; q.pixels = C::kPix; q.dict = _n;
			if (!_k[kVis].Dispatch(C::kPix, C::kPatches, 1u, &q, (uint32)sizeof(q))) return _E("vis_recon_after_coeff_sweep");
		}
		// ⑤ ⭐ MSE 의 기울기 = `sub`
		{
			MLSubParams q{}; q.aOff = _tRecon.offset; q.bOff = _curT;
			q.outOff = _tDRec.offset; q.count = C::kPatches * C::kPix;
			if (!_k[kSub].Dispatch(q.count, 1u, 1u, &q, (uint32)sizeof(q))) return _E("sub");
		}
		return true;
	}

	// ══════════════════════════════════════════════════════════════════
	// ◀ backward — ⚠️⚠️ **순서가 계약이다**: `dPatch`(= g 의 pos 칸)를 만든 **뒤에**
	//   `patch_embed_bwd` 가 그것을 `dOut` 으로 읽는다.
	// ══════════════════════════════════════════════════════════════════
	bool Backward()
	{
		typedef MLTP2Cfg C;
		if (_globalFoot) return _BackwardFoot();
		const uint32 actIds = _resSwap ? _tIds2.offset : _tIds.offset;
		// 회차 40 계약: δ는 stop-gradient, `dmag0=dmag1` identity STE. ids는 원래 top-k 그대로다.
		const uint32 actMag = _resSwap ? _tMag2.offset : (_coeff ? _tMagC.offset : _tMag.offset);
		// ⑥ 세기의 기울기
		{
			MLVisReconMagBwdParams q{}; q.idsOff = actIds;
			q.tableOff = _tP.offset + _oCode; q.dOutOff = _tDRec.offset; q.dMagOff = _tDMag.offset;
			q.rows = C::kPatches; q.k = _kAct; q.pixels = C::kPix; q.dict = _n;
			if (!_k[kVisM].Dispatch(_kAct, C::kPatches, 1u, &q, (uint32)sizeof(q))) return _E("vis_bwd_mag");
		}
		// ⭐ 회차 67 — **몸통에서 되돌아온 기울기를 여기서 더한다**(`⑥` 바로 뒤).
		//   ★ 자리의 근거: `_tDMag` 는 ⑥ 이 쓰고 ⑧·계수 경로가 **읽기만** 한다 ⇒ 여기서 더하면
		//     점수 머리·계수 머리·`patch_embed` 까지 **전부** 그 기울기를 받는다.
		//   ⚠️ 코드북(⑦)은 `dOut` 을 쓰므로 **안 받는다** — 그것이 회차 63 이 등록한 *"값 경로만"* 이다.
		//   ⚠️⚠️ 새 커널이 **0개**다 — `sub(a,b,out) = a − b` 에 **음수를 넣어** 더한다.
		//     (그래서 `SetExtDMag` 가 받은 값을 **음수화해서** 올린다.)
		if (_extDMag)
		{
			const uint32 n = (_globalFoot ? 1u : C::kPatches) * _kAct;
			MLSubParams q{}; q.aOff = _tDMag.offset; q.bOff = _tDMagX.offset;
			q.outOff = _tDMag.offset; q.count = n;
			if (!_k[kSub].Dispatch(n, 1u, 1u, &q, (uint32)sizeof(q))) return _E("dMag += 몸통");
		}
		// ⑦ 코드북의 기울기 — ⚠️ Y 축이 **dict** 다(행이 아니다)
		{
			MLVisReconTabBwdParams q{}; q.idsOff = actIds; q.magOff = actMag;
			q.dOutOff = _tDRec.offset; q.dTableOff = _tG.offset + _oCode;
			q.rows = C::kPatches; q.k = _kAct; q.pixels = C::kPix; q.dict = _n;
			if (!_k[kVisT].Dispatch(C::kPix, _n, 1u, &q, (uint32)sizeof(q))) return _E("vis_bwd_tab");
		}
		// ⑧ 선택의 기울기(straight-through)
		{
			MLActTopkBwdParams q{}; q.idsOff = actIds; q.dMagOff = _tDMag.offset;
			q.dScoreOff = _headNorm ? _tDScoreN.offset : _tDScore.offset;
			q.rows = C::kPatches; q.dict = _n; q.k = _kAct;
			if (!_k[kTopB].Dispatch(_n, C::kPatches, 1u, &q, (uint32)sizeof(q))) return _E("act_topk_bwd");
		}
		// 분리 머리의 계수 기울기. ㈂는 S의 선택 STE 위에 계수 경로를 결정적으로 더한다.
		if (_rank != 0u)
		{
			const float sc0 = _headNorm ? 1.0f : _headScale;
			const float sc = _couple ? (sc0 * 0.70710678f) : sc0;
			MLActGatherBwdParams q{}; q.idsOff = _tIds.offset; q.dMagOff = _tDMag.offset;
			q.rows = C::kPatches; q.dict = _n; q.k = _kAct; q.scale = sc;
			q.dInOff = _headNorm ? _tDCoefN.offset : _tDCoef.offset; q.add = 0u;
			if (!_k[kGatherB].Dispatch(_n, C::kPatches, 1u, &q, (uint32)sizeof(q))) return _E("gather_bwd_C");
			if (_couple)
			{
				q.dInOff = _headNorm ? _tDScoreN.offset : _tDScore.offset; q.add = 1u;
				if (!_k[kGatherB].Dispatch(_n, C::kPatches, 1u, &q, (uint32)sizeof(q))) return _E("gather_bwd_S(+)");
			}
			if (_headNorm)
			{
				MLRmsNormBwdParams s{}; s.inOff = _tScore.offset; s.gainOff = _tGainScore.offset;
				s.rstdOff = _tRstdS.offset; s.dOutOff = _tDScoreN.offset; s.dInOff = _tDScore.offset;
				s.rows = C::kPatches; s.cols = _n;
				if (!_k[kRmsB].Dispatch(s.rows, 1u, 1u, &s, (uint32)sizeof(s))) return _E("score_rmsnorm_bwd");
				MLRmsNormBwdParams c = s; c.inOff = _tCoef.offset; c.rstdOff = _tRstdC.offset;
				c.dOutOff = _tDCoefN.offset; c.dInOff = _tDCoef.offset;
				if (!_k[kRmsB].Dispatch(c.rows, 1u, 1u, &c, (uint32)sizeof(c))) return _E("coef_rmsnorm_bwd");
			}
		}

		const uint32 hOff  = (_hid == 0u) ? _tPatch.offset : _tHN.offset;
		const uint32 dhOff = (_hid == 0u) ? _tDPatch.offset : _tDH.offset;
		if (_rank == 0u)
		{
			// ⑨ `dH = dScore · Wd` · ⑩ `dWd = dScoreᵗ · h`.
			if (!_Gemm(_tDScore.offset, _tP.offset + _oWd, dhOff,
				C::kPatches, _h, _n, 0u, 0u)) return _E("dScore·Wd");
			if (!_Gemm(_tDScore.offset, hOff, _tG.offset + _oWd,
				_n, _h, C::kPatches, 1u, 0u)) return _E("dScoreT·h");
		}
		else
		{
			// S2/S1 뒤로 선택 경로를 보내고 dPatch를 먼저 쓴다(beta=0).
			if (!_Gemm(_tDScore.offset, _tSH.offset, _tG.offset + _oS2,
				_n, _rank, C::kPatches, 1u, 0u)) return _E("dS2");
			if (!_Gemm(_tDScore.offset, _tP.offset + _oS2, _tDSH.offset,
				C::kPatches, _rank, _n, 0u, 0u)) return _E("dSH");
			if (!_Gemm(_tDSH.offset, _tPatch.offset, _tG.offset + _oS1,
				_rank, C::kD, C::kPatches, 1u, 0u)) return _E("dS1");
			if (!_Gemm(_tDSH.offset, _tP.offset + _oS1, _tDPatch.offset,
				C::kPatches, C::kD, _rank, 0u, 0u)) return _E("dPatch_S");

			// C2/C1 뒤의 계수 경로는 같은 dPatch에 누산한다(beta=1).
			if (!_Gemm(_tDCoef.offset, _tCH.offset, _tG.offset + _oC2,
				_n, _rank, C::kPatches, 1u, 0u)) return _E("dC2");
			if (!_Gemm(_tDCoef.offset, _tP.offset + _oC2, _tDCH.offset,
				C::kPatches, _rank, _n, 0u, 0u)) return _E("dCH");
			if (!_Gemm(_tDCH.offset, _tPatch.offset, _tG.offset + _oC1,
				_rank, C::kD, C::kPatches, 1u, 0u)) return _E("dC1");
			if (!_Gemm(_tDCH.offset, _tP.offset + _oC1, _tDPatch.offset,
				C::kPatches, C::kD, _rank, 0u, 0u, 1.0f)) return _E("dPatch_C(+)");
		}
		// ⑨′ 은닉이 있으면 그 겹을 지나 `dPatch` 까지 간다
		if (_hid != 0u)
		{
			// ⭐ `d(normalized h)` → `d(raw h)`. gain 은 고정 배관이라 `dGain` 은 구하지 않는다.
			const uint32 rawHOff = _swi ? _tH.offset : _tA.offset;
			MLRmsNormBwdParams q{};
			q.inOff = rawHOff; q.gainOff = _tGainH.offset; q.rstdOff = _tRstdH.offset;
			q.dOutOff = _tDH.offset; q.dInOff = _tDA.offset;
			q.rows = C::kPatches; q.cols = _h;
			if (!_k[kRmsB].Dispatch(q.rows, 1u, 1u, &q, (uint32)sizeof(q))) return _E("hidden_rmsnorm_bwd");

			uint32 daOff = _tDA.offset, dbOff = 0u;
			if (_swi)
			{
				MLSwigluBwdParams s{}; s.aOff = _tA.offset; s.bOff = _tB.offset;
				// ⚠️ `_tHN` 은 `dWd` 계산 후 더 쓰지 않아 `dA` 칸으로 재사용한다.
				s.dOutOff = _tDA.offset; s.dAOff = _tHN.offset; s.dBOff = _tDB.offset;
				s.count = C::kPatches * _h;
				if (!_k[kSwiB].Dispatch(s.count, 1u, 1u, &s, (uint32)sizeof(s))) return _E("swiglu_bwd");
				daOff = _tHN.offset; dbOff = _tDB.offset;
			}
			// `dW1a = dAᵗ · patch` (산출 `[H, D]`)
			if (!_Gemm(daOff, _tPatch.offset, _tG.offset + _oW1a,
				_h, C::kD, C::kPatches, 1u, 0u)) return _E("dAT·patch");
			// ⭐ `dPatch = dA · W1a` — **`g` 의 pos 칸**(그것이 `dPos` 다) · `beta = 0`
			if (!_Gemm(daOff, _tP.offset + _oW1a, _tDPatch.offset,
				C::kPatches, C::kD, _h, 0u, 0u)) return _E("dA·W1a");
			if (_swi)
			{
				if (!_Gemm(dbOff, _tPatch.offset, _tG.offset + _oW1b,
					_h, C::kD, C::kPatches, 1u, 0u)) return _E("dBT·patch");
				// ⭐ 둘째 갈래는 **누산**한다(`beta = 1`) — P0 의 그 관용구.
				if (!_Gemm(dbOff, _tP.offset + _oW1b, _tDPatch.offset,
					C::kPatches, C::kD, _h, 0u, 0u, 1.0f)) return _E("dB·W1b(+)");
			}
		}
		// ⑪ 자리표의 기울기 — ⚠️ Y 축이 **표의 행**(자리×256)이다
		{
			MLPatchEmbedParams q{};
			q.frameOff = _curF; q.aOff = _tDPatch.offset; q.bOff = _tG.offset + _oSlot;
			q.frameW = C::kSide; q.frameH = C::kSide; q.patchK = C::kPatch; q.dim = C::kD;
			if (!_k[kPEB].Dispatch(C::kD, q.SlotRows(), 1u, &q, (uint32)sizeof(q)))
				return _E("patch_embed_bwd");
		}
		return true;
	}

	// ⚙️ AdamW — ★ 파라미터가 **한 블록**이라 디스패치가 하나다.
	bool AdamStep(float lrMul = 1.0f)
	{
		typedef MLTP2Cfg C;
		++_step;
		MLAdamWParams q{};
		q.pOff = _tP.offset; q.gOff = _tG.offset; q.mOff = _tM.offset; q.vOff = _tV.offset;
		q.count = _freezeCode ? _oCode : _pCount;
		q.lr = C::kLr * lrMul; q.beta1 = C::kB1; q.beta2 = C::kB2;
		q.eps = C::kAdamEps; q.wd = C::kWd;
		q.bc1 = 1.0f / (1.0f - Pow(C::kB1, (float)_step));
		q.bc2 = 1.0f / (1.0f - Pow(C::kB2, (float)_step));
		return _k[kAdam].Dispatch(q.count, 1u, 1u, &q, (uint32)sizeof(q));
	}

	// ══════════════════════════════════════════════════════════════════
	// ⭐ **사전 유닛의 크기를 고르게 맞춘다**(행마다 단위 RMS). ⚠️ `AdamStep` **뒤에** 부른다.
	//   ★ 이미 판정 ①② 를 통과한 `rmsnorm` 을 **제자리로** 쓴다(새 커널 0개).
	//   ⚠️ 이득이 전부 **같은 수**(`kNormRms`)이므로 **모양은 하나도 안 건드리고 크기만** 맞춘다.
	//     ⚠️⚠️ 그 수가 **1 이 아니어야** 한다 — 1 이면 크기를 19배로 키운다(`kNormRms` 의 그 실측).
	//   ⚠️ 이것은 **모델 변경**이다 ⇒ 부르는 쪽이 A/B 로 등록해서 쓴다(조용히 켜지 않는다).
	// ══════════════════════════════════════════════════════════════════
	bool NormalizeDict()
	{
		typedef MLTP2Cfg C;
		if (_rank != 0u) return true; // 저랭크 머리는 round33에서 정규화하지 않는다.
		MLRmsNormParams q{};
		q.inOff = _tP.offset + _oWd; q.gainOff = _tOnes.offset;
		q.outOff = _tP.offset + _oWd;      // ★ 제자리(셰이더가 제곱합을 먼저 다 읽는다)
		q.rstdOff = _tRstd.offset;
		q.rows = _n; q.cols = _h; q.eps = 1.0e-6f;   // ⚠️ `Wd` 의 폭은 **H** 다(은닉이 있으면 D 가 아니다)
		return _k[kRms].Dispatch(_n, 1u, 1u, &q, (uint32)sizeof(q));
	}

	// ══════════════════════════════════════════════════════════════════
	// 📥 되읽기 — ⚠️⚠️ **이번 프레임에 디스패치한 결과는 안 보인다**(다음 프레임의 값이다).
	//   ★ `dRecon = recon − target` 이므로 **MSE 가 그 제곱평균**이다(따로 커널이 필요 없다).
	// ══════════════════════════════════════════════════════════════════
	bool ReadMse(float& mse, bool& finite) const
	{
		typedef MLTP2Cfg C;
		const uint32 n = C::kPatches * C::kPix;
		Bytes b;
		if (!_ar.Read(_tDRec, b) || b.GetSize() < (uint64)n * sizeof(float)) return false;
		const float* v = (const float*)b.GetData();
		double s = 0.0; finite = true;
		for (uint32 i = 0; i < n; ++i)
		{
			const float d = v[i];
			if (!(d == d) || d > 3.0e38f || d < -3.0e38f) { finite = false; continue; }
			s += (double)d * d;
		}
		mse = (float)(s / (double)n);
		return true;
	}

	// ══════════════════════════════════════════════════════════════════
	// ⭐ **코드북 행의 크기를 고르게 맞춘다**(행마다 목표 RMS). ⚠️ `AdamStep` **뒤에** 부른다.
	//   ★ 회차 27 의 분해가 가리킨 자리다 — 세기는 `mag × 코드북 행` 이므로 **행 크기의 흩어짐**이
	//     같은 `mag` 를 전혀 다른 기여로 만든다.
	//   ★ 코드북은 `[N, pixels]` 라 **유닛 하나 = 한 행**이므로 `rmsnorm` 이 곧바로 붙는다
	//     (전치도 새 커널도 필요 없다). ⚠️ 이득은 **1 이 아니라 초기 RMS**(회차 26 의 그 실측).
	// ══════════════════════════════════════════════════════════════════
	bool NormalizeCode()
	{
		typedef MLTP2Cfg C;
		MLRmsNormParams q{};
		q.inOff = _tP.offset + _oCode; q.gainOff = _tGainPix.offset;
		q.outOff = _tP.offset + _oCode;    // ★ 제자리(행마다 스레드 하나 · 제곱합을 먼저 다 읽는다)
		q.rstdOff = _tRstd.offset;
		q.rows = _n; q.cols = C::kPix; q.eps = 1.0e-6f;
		return _k[kRms].Dispatch(_n, 1u, 1u, &q, (uint32)sizeof(q));
	}

	// ══════════════════════════════════════════════════════════════════
	// 🧮 **「ids 는 그대로 두고 세기만 최적」 MSE**(최소제곱) — ⭐ 회차 27 이 만든 도구이고
	//   ⚠️ **회차 둘이 같은 것을 보므로 여기 한 곳에만 둔다**(복사하면 반드시 어긋난다).
	//   ★ `k × k` 정규방정식을 가우스 소거로 푼다(작은 리지). `k ≤ kKMax` 여야 한다.
	// ══════════════════════════════════════════════════════════════════
	static float LsqMse(const Array<float>& code, uint32 nDict, const Array<float>& tgt,
		const Array<float>& ids, uint32 k, uint32 nPatch, float ridge = 1.0e-6f)
	{
		typedef MLTP2Cfg C;
		if (nPatch == 0u || k == 0u || k > 16u) return 0.0f;
		if (ids.Count() < nPatch * k || tgt.Count() < nPatch * C::kPix) return 0.0f;
		double sq = 0.0;
		float A[16][16], b[16], x[16];
		for (uint32 p = 0; p < nPatch; ++p)
		{
			const float* y = tgt.Data() + p * C::kPix;
			const float* id = ids.Data() + p * k;
			for (uint32 i = 0; i < k; ++i)
			{
				const uint32 vi = (uint32)id[i];
				const float* ui = (vi < nDict) ? (code.Data() + vi * C::kPix) : nullptr;
				for (uint32 j = 0; j < k; ++j)
				{
					const uint32 vj = (uint32)id[j];
					const float* uj = (vj < nDict) ? (code.Data() + vj * C::kPix) : nullptr;
					float s = 0.0f;
					if (ui != nullptr && uj != nullptr)
						for (uint32 d = 0; d < C::kPix; ++d) s += ui[d] * uj[d];
					A[i][j] = s + ((i == j) ? ridge : 0.0f);
				}
				float s = 0.0f;
				if (ui != nullptr) for (uint32 d = 0; d < C::kPix; ++d) s += ui[d] * y[d];
				b[i] = s;
			}
			_SolveK(A, b, x, k);
			for (uint32 d = 0; d < C::kPix; ++d)
			{
				float r = y[d];
				for (uint32 i = 0; i < k; ++i)
				{
					const uint32 vi = (uint32)id[i];
					if (vi < nDict) r -= x[i] * code[vi * C::kPix + d];
				}
				sq += (double)r * r;
			}
		}
		return (float)(sq / (double)(nPatch * C::kPix));
	}

	// ══════════════════════════════════════════════════════════════════
	// 🔧 **현재 ids·모델 계수에서 안전한 좌표 갱신 한 바퀴** — 회차 38 CPU 분해.
	//   각 원자에 남은 잔차를 투영해 `mag += dot(d,r)/(||d||²+ridge)` 하고 즉시 잔차를
	//   갱신한다. ids·코드북은 고정이며 k개를 한 번씩만 지난다. 목표 패치를 직접 보는 진단이므로
	//   모델 성능이 아니고, 고정-id LSQ까지 남은 「계수 반복 깊이」의 몫만 잰다.
	// ══════════════════════════════════════════════════════════════════
	static float CoeffSweepMse(const Array<float>& code, uint32 nDict, const Array<float>& tgt,
		const Array<float>& ids, const Array<float>& mag, uint32 k, uint32 nPatch,
		float ridge = 1.0e-6f)
	{
		typedef MLTP2Cfg C;
		if (nPatch == 0u || k == 0u || nDict == 0u) return 0.0f;
		if (ids.Count() < nPatch * k || mag.Count() < nPatch * k ||
			tgt.Count() < nPatch * C::kPix) return 0.0f;
		double sq = 0.0;
		float r[C::kPix];
		for (uint32 p = 0; p < nPatch; ++p)
		{
			const float* y = tgt.Data() + p * C::kPix;
			const float* pi = ids.Data() + p * k;
			const float* pm = mag.Data() + p * k;
			for (uint32 d = 0; d < C::kPix; ++d)
			{
				float v = y[d];
				for (uint32 j = 0; j < k; ++j)
				{
					const uint32 id = (uint32)pi[j];
					if (id < nDict) v -= pm[j] * code[id * C::kPix + d];
				}
				r[d] = v;
			}
			for (uint32 j = 0; j < k; ++j)
			{
				const uint32 id = (uint32)pi[j];
				if (id >= nDict) continue;
				const float* u = code.Data() + id * C::kPix;
				float dot = 0.0f, norm = ridge;
				for (uint32 d = 0; d < C::kPix; ++d)
				{
					dot += u[d] * r[d]; norm += u[d] * u[d];
				}
				const float delta = dot / norm;
				for (uint32 d = 0; d < C::kPix; ++d) r[d] -= delta * u[d];
			}
			for (uint32 d = 0; d < C::kPix; ++d) sq += (double)r[d] * r[d];
		}
		return (float)(sq / (double)(nPatch * C::kPix));
	}

	// ══════════════════════════════════════════════════════════════════
	// ⭐ **OMP(직교 정합추적) 오라클** — 「선택의 여지」를 정직하게 재는 도구.
	//   ★ 회차 27 의 **평범한 정합추적(greedy)은 상한이 아니었다** — 학습 패치에서 모델보다
	//     **나빴다**(1.79배). 원인은 매 걸음 **고른 것 전체를 다시 풀지 않아서**다(계수가 낡는다).
	//   ⇒ OMP 는 원소를 하나 더할 때마다 **고른 원소 전체에 대해 최소제곱을 다시 푼다** ⇒ 잔차가
	//     선택 부분공간에 **직교**하고, 같은 선택에서 나올 수 있는 **최선의 계수**를 늘 쓴다.
	//   ⚠️ 그래도 **최적 부분집합은 아니다**(그것은 NP-난해다) — 하지만 **모델보다 강해야** 하고,
	//     그 사실 자체가 이 구현의 **검증**이다(모델보다 나쁘면 구현이 약한 것이다).
	//   ★ 고르는 기준은 `|dot(res, u)| / |u|`(정규화한 상관) — 크기가 다른 유닛을 공평히 견준다.
	// ══════════════════════════════════════════════════════════════════
	static float OmpMse(const Array<float>& code, uint32 nDict, const Array<float>& tgt,
		uint32 k, uint32 nPatch, float ridge = 1.0e-6f)
	{
		typedef MLTP2Cfg C;
		if (nPatch == 0u || k == 0u || k > 16u || nDict == 0u) return 0.0f;
		if (tgt.Count() < nPatch * C::kPix) return 0.0f;

		// 유닛 노름을 미리 센다(매 걸음 다시 세지 않게)
		Array<float> nrm; nrm.Reset(0);
		for (uint32 v = 0; v < nDict; ++v)
		{
			const float* u = code.Data() + v * C::kPix;
			float s = 0.0f;
			for (uint32 d = 0; d < C::kPix; ++d) s += u[d] * u[d];
			nrm.Add(s);
		}
		Array<float> res; res.Reset(0);
		for (uint32 d = 0; d < C::kPix; ++d) res.Add(0.0f);
		uint32 pick[16];
		float A[16][16], b[16], x[16];
		double sq = 0.0;
		for (uint32 p = 0; p < nPatch; ++p)
		{
			const float* y = tgt.Data() + p * C::kPix;
			for (uint32 d = 0; d < C::kPix; ++d) res.Data()[d] = y[d];
			uint32 m = 0u;
			for (uint32 i = 0; i < k; ++i)
			{
				// ① 잔차와 가장 잘 맞는 유닛(정규화한 상관) — 이미 고른 것은 건너뛴다
				uint32 best = nDict; float bestScore = 0.0f;
				for (uint32 v = 0; v < nDict; ++v)
				{
					if (nrm[v] <= 1.0e-12f) continue;
					bool dup = false;
					for (uint32 q = 0; q < m; ++q) if (pick[q] == v) { dup = true; break; }
					if (dup) continue;
					const float* u = code.Data() + v * C::kPix;
					float dot = 0.0f;
					for (uint32 d = 0; d < C::kPix; ++d) dot += res[d] * u[d];
					const float sc = Abs(dot) / Sqrt(nrm[v]);
					if (sc > bestScore) { bestScore = sc; best = v; }
				}
				if (best >= nDict) break;
				pick[m++] = best;

				// ② ⭐ **고른 것 전체**에 대해 최소제곱을 다시 푼다(그것이 OMP 다)
				for (uint32 a = 0; a < m; ++a)
				{
					const float* ua = code.Data() + pick[a] * C::kPix;
					for (uint32 bb = 0; bb < m; ++bb)
					{
						const float* ub = code.Data() + pick[bb] * C::kPix;
						float s = 0.0f;
						for (uint32 d = 0; d < C::kPix; ++d) s += ua[d] * ub[d];
						A[a][bb] = s + ((a == bb) ? ridge : 0.0f);
					}
					float s = 0.0f;
					for (uint32 d = 0; d < C::kPix; ++d) s += ua[d] * y[d];
					b[a] = s;
				}
				_SolveK(A, b, x, m);

				// ③ 잔차를 다시 만든다(누적 뺄셈이 아니라 **처음부터** — 계수가 전부 갈렸다)
				for (uint32 d = 0; d < C::kPix; ++d)
				{
					float r = y[d];
					for (uint32 a = 0; a < m; ++a) r -= x[a] * code[pick[a] * C::kPix + d];
					res.Data()[d] = r;
				}
			}
			for (uint32 d = 0; d < C::kPix; ++d) sq += (double)res[d] * res[d];
		}
		return (float)(sq / (double)(nPatch * C::kPix));
	}

	// ══════════════════════════════════════════════════════════════════
	// 🔁 **현재 ids에 잔차 기반 교체 한 번** — 회차 35의 모델 변경 전 CPU 오라클.
	//   ① 현재 k개 LSQ → ② 잔차 상관 최대 새 원자 하나 → ③ k+1 LSQ →
	//   ④ `|계수|·원자노름` 최소 하나 제거 → ⑤ k개 LSQ. 선택 반복의 최소 한 걸음만 잰다.
	// ══════════════════════════════════════════════════════════════════
	static float SwapOneMse(const Array<float>& code, uint32 nDict, const Array<float>& tgt,
		const Array<float>& ids, uint32 k, uint32 nPatch, float ridge = 1.0e-6f)
	{
		typedef MLTP2Cfg C;
		if (nPatch == 0u || k == 0u || k >= 16u || nDict == 0u) return 0.0f;
		if (ids.Count() < nPatch * k || tgt.Count() < nPatch * C::kPix) return 0.0f;

		Array<float> nrm; nrm.Reset(0);
		for (uint32 v = 0; v < nDict; ++v)
		{
			const float* u = code.Data() + v * C::kPix;
			float s = 0.0f; for (uint32 d = 0; d < C::kPix; ++d) s += u[d] * u[d];
			nrm.Add(s);
		}

		uint32 pick[16]; float A[16][16], b[16], x[16], res[C::kPix];
		double sq = 0.0;
		for (uint32 p = 0; p < nPatch; ++p)
		{
			const float* y = tgt.Data() + p * C::kPix;
			for (uint32 i = 0; i < k; ++i) pick[i] = (uint32)ids[p * k + i];
			_FitSubset(code, nDict, y, pick, k, ridge, A, b, x, res);
			double originalSq = 0.0;
			for (uint32 d = 0; d < C::kPix; ++d) originalSq += (double)res[d] * res[d];

			uint32 best = nDict; float bestScore = 0.0f;
			for (uint32 v = 0; v < nDict; ++v)
			{
				if (nrm[v] <= 1.0e-12f) continue;
				bool dup = false; for (uint32 i = 0; i < k; ++i) if (pick[i] == v) { dup = true; break; }
				if (dup) continue;
				const float* u = code.Data() + v * C::kPix;
				float dot = 0.0f; for (uint32 d = 0; d < C::kPix; ++d) dot += res[d] * u[d];
				const float sc = Abs(dot) / Sqrt(nrm[v]);
				if (sc > bestScore) { bestScore = sc; best = v; }
			}

			if (best < nDict)
			{
				pick[k] = best;
				_FitSubset(code, nDict, y, pick, k + 1u, ridge, A, b, x, res);
				uint32 drop = 0u; float least = 3.0e38f;
				for (uint32 i = 0; i <= k; ++i)
				{
					const float nn = (pick[i] < nDict) ? Sqrt(nrm[pick[i]]) : 0.0f;
					const float contribution = Abs(x[i]) * nn;
					if (contribution < least) { least = contribution; drop = i; }
				}
				for (uint32 i = drop; i < k; ++i) pick[i] = pick[i + 1u];
				_FitSubset(code, nDict, y, pick, k, ridge, A, b, x, res);
			}
			double swappedSq = 0.0;
			for (uint32 d = 0; d < C::kPix; ++d) swappedSq += (double)res[d] * res[d];
			// 오라클은 교체를 강제하지 않는다. 나빠지는 후보라면 원래 ids를 그대로 둔다.
			sq += (swappedSq < originalSq) ? swappedSq : originalSq;
		}
		return (float)(sq / (double)(nPatch * C::kPix));
	}

	// ══════════════════════════════════════════════════════════════════
	// 📖 **학습된 코드북을 그대로 읽는다**(`N × pixels`) — ⭐ 오라클 분해의 재료다.
	//   ⚠️ **이번 프레임에 디스패치한 결과는 안 보인다**(다음 프레임의 값이다) — 학습이 끝난 뒤
	//     부르므로 문제가 없지만, 그 규약을 여기 적어 둔다.
	// ══════════════════════════════════════════════════════════════════
	bool ReadCodebook(Array<float>& out) const
	{
		typedef MLTP2Cfg C;
		const uint32 n = _n * C::kPix;
		MLTensor t; t.offset = _tP.offset + _oCode; t.rows = _n; t.cols = C::kPix;
		Bytes b;
		if (!_ar.Read(t, b) || b.GetSize() < (uint64)n * sizeof(float)) return false;
		const float* v = (const float*)b.GetData();
		out.Reset(0);
		for (uint32 i = 0; i < n; ++i) out.Add(v[i]);
		return true;
	}

	// 📖 지금 프레임의 **선택**(ids)과 **세기**(mag) 를 그대로 읽는다(`행 × k`).
	//   ⭐ 오라클 B(「ids 는 그대로 두고 세기만 최적으로」)가 이것을 쓴다.
	// ══════════════════════════════════════════════════════════════════
	// ⭐ 회차 67 — **몸통에서 되돌아온 기울기**를 인코더에 넣는 창구
	// ══════════════════════════════════════════════════════════════════
	//   ⚠️ `x` 는 **더하고 싶은 값** `∂L_몸통/∂mag` 다(부호를 뒤집어 주지 마라 — 여기서 뒤집는다).
	//   ⚠️ 배치는 `ReadAct` 와 **같다**: 색인 `c = 패치·k + 슬롯`, 길이 `kPatches · k`.
	//   ⚠️⚠️ **`Backward()` 마다 다시 넣어야 한다** — 프레임이 바뀌면 뜻이 달라지므로 남겨 두면
	//     조용히 **다른 프레임의 기울기**를 더한다. `Clear` 로 끄는 길을 같이 둔다.
	bool SetExtDMag(const Array<float>& x)
	{
		typedef MLTP2Cfg C;
		const uint32 n = (_globalFoot ? 1u : C::kPatches) * _kAct;
		if (x.Count() < n) return false;
		Array<float> neg; neg.Reset(0);
		for (uint32 i = 0; i < n; ++i) neg.Add(-x[i]);          // `sub` 로 더하려고 뒤집는다
		for (uint32 i = n; i < _tDMagX.Count(); ++i) neg.Add(0.0f);
		if (!_ar.Write(_tDMagX, neg)) return false;
		_extDMag = true;
		return true;
	}
	void ClearExtDMag() { _extDMag = false; }
	bool ExtDMagOn() const { return _extDMag; }

	// ⭐ 회차 69 사다리 — `dScore` 와 **파라미터 기울기 블록**을 날것으로 준다.
	//   ⚠️ 「어디서 끊기나」는 중간 자리를 다 봐야 갈린다(끝점만 보면 범인을 못 짚는다).
	bool ReadDScore(Array<float>& out) const
	{
		typedef MLTP2Cfg C;
		const uint32 n = C::kPatches * _n;
		Bytes b;
		if (!_ar.Read(_tDScore, b) || b.GetSize() < (uint64)n * sizeof(float)) return false;
		const float* v = (const float*)b.GetData();
		out.Reset(0);
		for (uint32 i = 0; i < n; ++i) out.Add(v[i]);
		return true;
	}
	bool ReadGrad(Array<float>& out) const
	{
		Bytes b;
		if (!_ar.Read(_tG, b) || b.GetSize() < (uint64)_pCount * sizeof(float)) return false;
		const float* v = (const float*)b.GetData();
		out.Reset(0);
		for (uint32 i = 0; i < _pCount; ++i) out.Add(v[i]);
		return true;
	}

	// ⭐ 파라미터를 날것으로 준다 — 「경험이 인코딩을 얼마나 바꿨나」의 눈금(회차 67).
	bool ReadParams(Array<float>& out) const
	{
		Bytes b;
		if (!_ar.Read(_tP, b) || b.GetSize() < (uint64)_pCount * sizeof(float)) return false;
		const float* v = (const float*)b.GetData();
		out.Reset(0);
		for (uint32 i = 0; i < _pCount; ++i) out.Add(v[i]);
		return true;
	}

	// 판정 ① 용 — `_tDMag` 를 날것으로 준다(주입 전후를 견주면 「닿았나」가 그 자리에서 보인다).
	bool ReadDMag(Array<float>& out) const
	{
		typedef MLTP2Cfg C;
		const uint32 n = (_globalFoot ? 1u : C::kPatches) * _kAct;
		Bytes b;
		if (!_ar.Read(_tDMag, b) || b.GetSize() < (uint64)n * sizeof(float)) return false;
		const float* v = (const float*)b.GetData();
		out.Reset(0);
		for (uint32 i = 0; i < n; ++i) out.Add(v[i]);
		return true;
	}

	bool ReadAct(Array<float>& ids, Array<float>& mag) const
	{
		typedef MLTP2Cfg C;
		const uint32 n = (_globalFoot ? 1u : C::kPatches) * _kAct;
		Bytes bi, bm;
		const MLTensor& ti = _resSwap ? _tIds2 : _tIds;
		const MLTensor& tm = _resSwap ? _tMag2 : (_coeff ? _tMagC : _tMag);
		if (!_ar.Read(ti, bi) || !_ar.Read(tm, bm)) return false;
		if (bi.GetSize() < (uint64)n * sizeof(float) || bm.GetSize() < (uint64)n * sizeof(float)) return false;
		const float* pi = (const float*)bi.GetData();
		const float* pm = (const float*)bm.GetData();
		ids.Reset(0); mag.Reset(0);
		for (uint32 i = 0; i < n; ++i) { ids.Add(pi[i]); mag.Add(pm[i]); }
		return true;
	}

	// 🔁 현재 프레임에서 잔차 단계가 실제로 바꾼 패치 수. 한 패치당 최대 한 슬롯만 달라진다.
	bool ReadSwapCount(uint32& changed) const
	{
		typedef MLTP2Cfg C;
		changed = 0u;
		if (!_resSwap) return true;
		const uint32 n = C::kPatches * _kAct;
		Bytes b0, b1;
		if (!_ar.Read(_tIds, b0) || !_ar.Read(_tIds2, b1)) return false;
		if (b0.GetSize() < (uint64)n * sizeof(float) || b1.GetSize() < (uint64)n * sizeof(float)) return false;
		const float* a = (const float*)b0.GetData(); const float* b = (const float*)b1.GetData();
		for (uint32 i = 0; i < n; ++i) if ((uint32)a[i] != (uint32)b[i]) ++changed;
		return true;
	}

	// 🔎 **뽑힌 세기에 음수가 몇 개나 나오나** — ⭐ `act_topk_abs` 가 실제로 부호를 쓰는지 본다.
	//   ⚠️ 0 이면 그 스위치가 아무 일도 안 하고 있는 것이고, 그 사실은 손실만 보면 안 보인다.
	bool ReadNegCount(uint32& neg, uint32& total) const
	{
		typedef MLTP2Cfg C;
		const uint32 n = (_globalFoot ? 1u : C::kPatches) * _kAct;
		Bytes bm;
		const MLTensor& tm = _resSwap ? _tMag2 : (_coeff ? _tMagC : _tMag);
		if (!_ar.Read(tm, bm) || bm.GetSize() < (uint64)n * sizeof(float)) return false;
		const float* mg = (const float*)bm.GetData();
		neg = 0u; total = n;
		for (uint32 i = 0; i < n; ++i) if (mg[i] < 0.0f) ++neg;
		return true;
	}

	// 🔎 활성이 실제로 갈리나 — ⚠️ **관문이 아니라 보고**다(사전 사용률 ㉡ 은 판정 라운드의 칸이다).
	//   ★ 전부 같은 id 면 그것이 붕괴의 얼굴이고, 그 사실은 손실만 보면 안 보인다.
	bool ReadActStats(uint32& distinct, uint32& outOfRange, float& magMax) const
	{
		typedef MLTP2Cfg C;
		const uint32 n = (_globalFoot ? 1u : C::kPatches) * _kAct;
		Bytes bi, bm;
		const MLTensor& ti = _resSwap ? _tIds2 : _tIds;
		const MLTensor& tm = _resSwap ? _tMag2 : (_coeff ? _tMagC : _tMag);
		if (!_ar.Read(ti, bi) || !_ar.Read(tm, bm)) return false;
		if (bi.GetSize() < (uint64)n * sizeof(float) || bm.GetSize() < (uint64)n * sizeof(float)) return false;
		const float* id = (const float*)bi.GetData();
		const float* mg = (const float*)bm.GetData();
		// ⚠️ `N = 1000` 이라 비트맵이 싸다(원소 수로 세면 중복을 못 가른다).
		Array<uint8> hit; hit.Reset(0);
		for (uint32 i = 0; i < _n; ++i) hit.Add(0u);
		distinct = 0u; outOfRange = 0u; magMax = 0.0f;
		for (uint32 i = 0; i < n; ++i)
		{
			const float f = id[i];
			const uint32 lim = _globalFoot ? C::kPatches * _n : _n;
			if (!(f >= 0.0f) || f >= (float)lim) { ++outOfRange; continue; }
			const uint32 raw = (uint32)f;
			const uint32 v = _globalFoot ? raw % _n : raw;
			if (hit[v] == 0u) { hit.Data()[v] = 1u; ++distinct; }
			const float a = Abs(mg[i]);
			if (a > magMax) magMax = a;
		}
		return true;
	}

	// ══════════════════════════════════════════════════════════════════
	// 📊 ㉡ 의 재료 — 유닛마다 `Σ|mag|` 를 **누산**한다(시험 프레임 전체에 걸쳐).
	//   ⚠️ 등록된 정의는 *"`Σ mag > 0.01 · 최대` 인 유닛의 개수"* 다 — ★ **절대값**으로 센다
	//     (`mag` 는 점수라 음수가 될 수 있고, 부호가 섞이면 상쇄로 「안 쓴 것」처럼 보인다).
	// ══════════════════════════════════════════════════════════════════
	bool AccumUsage(Array<float>& usage) const
	{
		typedef MLTP2Cfg C;
		const uint32 n = (_globalFoot ? 1u : C::kPatches) * _kAct;
		if (usage.Count() != _n) return false;
		Bytes bi, bm;
		const MLTensor& ti = _resSwap ? _tIds2 : _tIds;
		const MLTensor& tm = _resSwap ? _tMag2 : (_coeff ? _tMagC : _tMag);
		if (!_ar.Read(ti, bi) || !_ar.Read(tm, bm)) return false;
		if (bi.GetSize() < (uint64)n * sizeof(float) || bm.GetSize() < (uint64)n * sizeof(float)) return false;
		const float* id = (const float*)bi.GetData();
		const float* mg = (const float*)bm.GetData();
		for (uint32 i = 0; i < n; ++i)
		{
			const float f = id[i];
			const uint32 lim = _globalFoot ? C::kPatches * _n : _n;
			if (!(f >= 0.0f) || f >= (float)lim) continue;
			const uint32 raw = (uint32)f;
			usage.Data()[_globalFoot ? raw % _n : raw] += Abs(mg[i]);
		}
		return true;
	}

	// ══════════════════════════════════════════════════════════════════
	// ♻️ **씨앗을 갈아탄다 — 아레나도 셰이더도 다시 만들지 않는다.**
	//   ★ 왜 중요한가: 예전엔 씨앗마다 `Setup()` 을 다시 불러 **40MB 디바이스 버퍼 + 40MB
	//     스테이징 0채움 + 셰이더/디스크립터 10장**을 만들고 버렸다(스윕이면 36회) — 그 **churn**
	//     자체가 값이고(씨앗당 셋업이 학습 시간의 큰 몫이었다), 없애면 회차가 짧아진다.
	//   ⚠️⚠️ **「그것이 메모리 압박을 냈다」로 적었다가 고쳤다 — 근거가 없었다.**
	//     `RHI_Vulkan::DestroyRHIBuffer` 는 **무덤**에 넣고 미루지만 TTL 이 ≈20프레임이라
	//     동시에 살아 있는 것은 한둘뿐이다 ⇒ **릭이 아니다.**
	//   ⇒ 되돌려야 하는 것은 셋뿐이다: **파라미터 · Adam 의 `m`/`v` · 스텝 수**.
	//   ⭐ `g`(기울기)는 **0 으로 되돌릴 필요가 없다** — 네 커널이 전부 **쓴다**(더하지 않는다)이고
	//     그 넷이 파라미터 블록 **전체**를 덮는다(그래서 애초에 0채움 커널이 없다).
	//   ⭐ 그리고 `m`/`v` 의 0채움은 **기존 `sub` 커널**이 한다 — `out = a − b` 에 세 오프셋을
	//     **같은 자리**로 주면 그 자리가 0 이 된다. 새 커널이 필요 없다(P0 의 그 관용구).
	//   ⚠️ 결과는 **한 비트도 안 바뀐다**(같은 초기값 · 같은 순서).
	// ══════════════════════════════════════════════════════════════════
	bool ResetSeed()
	{
		typedef MLTP2Cfg C;
		if (!_ar.IsValid() || _p0.Count() != _pCount) return false;
		if (!_ar.Write(_tP, _p0)) { LogA("[mlt] 👁️ 파라미터 되돌리기 실패\n"); return false; }
		if (!_Zero(_tM.offset, _pCount)) return _E("zero(m)");
		if (!_Zero(_tV.offset, _pCount)) return _E("zero(v)");
		_step = 0u;
		return true;
	}

	// ⭐ **선택 기준** — `false` = 가장 큰 값(`act_topk`) · `true` = 가장 큰 **절댓값**(`act_topk_abs`).
	//   ★ 회차 27·28 이 「세기가 확실한 몫(30%)」과 「크기 정규화로는 안 고쳐진다」를 냈고,
	//     그 30% 의 후보가 *"계수가 양수 큰 값들로 묶여 있다"* 였다. 이 스위치가 그 제약을 푼다.
	//   ⚠️ **모델 변경**이므로 부르는 쪽이 A/B 로 등록해서 쓴다(조용히 켜지 않는다).
	void SetSelectAbs(bool on) { _absSel = on; }
	bool SelectAbs() const { return _absSel; }

	// ⭐ 활성 개수 `k` — ⚠️ **`Setup` 뒤에 부른다**(아레나는 상한으로 잡혀 있어 다시 만들 필요가 없다).
	void SetK(uint32 k) { _kAct = (k != 0u && k <= MLTP2Cfg::kKMax) ? k : MLTP2Cfg::kK; }
	uint32 K() const { return _kAct; }

	// ══════════════════════════════════════════════════════════════════
	// 🧮 CPU 통계 둘 — ★ **회차 둘이 같은 것을 본다** ⇒ 여기 한 곳에만 둔다.
	//   ⚠️ 회차마다 복사하면 「A단계와 같은 식」이라는 약속이 반드시 어긋난다.
	// ══════════════════════════════════════════════════════════════════
	// 패치-상수 대조군의 **정확값**(패치 안 분산). ⚠️ A단계와 같은 식이어야 한다.
	static float PatchConstMse(const Array<float>& patch)
	{
		typedef MLTP2Cfg C;
		const uint32 n = patch.Count() / C::kPix;
		if (n == 0u) return 0.0f;
		double sq = 0.0;
		for (uint32 p = 0; p < n; ++p)
		{
			const float* v = patch.Data() + p * C::kPix;
			double m[3] = { 0.0, 0.0, 0.0 };
			for (uint32 i = 0; i < C::kPix; ++i) m[i % 3u] += (double)v[i];
			const double inv = 3.0 / (double)C::kPix;
			for (uint32 j = 0; j < 3u; ++j) m[j] *= inv;
			for (uint32 i = 0; i < C::kPix; ++i)
			{ const double d = (double)v[i] - m[i % 3u]; sq += d * d; }
		}
		return (float)(sq / (double)(n * C::kPix));
	}

	// 패치들이 펼치는 **차원(랭크)** — 수정 그램-슈미트. ⚠️ 상대 문턱이다(절대는 세계가 바뀌면 거짓말).
	//   ★ ㉡ 문턱의 전부다: 쓰인 유닛이 이 차원을 못 펼치면 **오차 0 이 원리적으로 불가**하다.
	static uint32 PatchRank(const Array<float>& patch, float tol = 1.0e-3f)
	{
		typedef MLTP2Cfg C;
		const uint32 n = patch.Count() / C::kPix;
		if (n == 0u) return 0u;
		Array<float> basis; basis.Reset(0);
		uint32 nb = 0u;
		Array<float> v; v.Reset(0);
		for (uint32 i = 0; i < C::kPix; ++i) v.Add(0.0f);
		for (uint32 p = 0; p < n && nb < C::kPix; ++p)
		{
			const float* src = patch.Data() + p * C::kPix;
			float n0 = 0.0f;
			for (uint32 i = 0; i < C::kPix; ++i) { v.Data()[i] = src[i]; n0 += src[i] * src[i]; }
			n0 = Sqrt(n0);
			if (n0 <= 0.0f) continue;
			for (uint32 b = 0; b < nb; ++b)
			{
				const float* e = basis.Data() + b * C::kPix;
				float d = 0.0f;
				for (uint32 i = 0; i < C::kPix; ++i) d += v[i] * e[i];
				for (uint32 i = 0; i < C::kPix; ++i) v.Data()[i] -= d * e[i];
			}
			float r = 0.0f;
			for (uint32 i = 0; i < C::kPix; ++i) r += v[i] * v[i];
			r = Sqrt(r);
			if (r <= tol * n0) continue;
			const float inv = 1.0f / r;
			for (uint32 i = 0; i < C::kPix; ++i) basis.Add(v[i] * inv);
			++nb;
		}
		return nb;
	}

	// ── 파라미터 셈 둘 — ⚠️ **둘 다 적는다**(머리말의 그 이유) ──────
	uint32 AllocParams() const { return _pCount; }
	uint32 N() const { return _n; }
	uint32 Hidden() const { return _hid; }
	uint32 HWidth() const { return _h; }
	bool   Swiglu() const { return _swi; }
	// ⚠️ `N` 을 **인자로** 받는다 — 스윕이 그것을 흔들므로 상수로 두면 조용히 거짓말을 한다.
	// ⚠️ `N`·`H` 를 **인자로** 받는다 — 스윕이 그것을 흔드므로 상수로 두면 조용히 거짓말을 한다.
	//   `hidden = 0` 이면 은닉이 없다(`H = D`).
	static uint32 LiveParams(uint32 liveSlotRows, uint32 nDict, uint32 hidden = 0u, bool swiglu = false)
	{
		typedef MLTP2Cfg C;
		const uint32 h = (hidden != 0u) ? hidden : C::kD;
		const uint32 w1 = (hidden != 0u) ? (h * C::kD * (swiglu ? 2u : 1u)) : 0u;
		return liveSlotRows * C::kD + C::kPatches * C::kD + w1 + h * nDict + nDict * C::kPix;
	}

	static uint32 LiveSplitParams(uint32 liveSlotRows, uint32 nDict, uint32 rank)
	{
		typedef MLTP2Cfg C;
		return liveSlotRows * C::kD + C::kPatches * C::kD
			+ 2u * rank * (C::kD + nDict) + nDict * C::kPix;
	}

	static uint32 GlobalLiveParams(uint32 liveSlotRows, uint32 nDict)
	{
		typedef MLTP2Cfg C;
		return LiveParams(liveSlotRows, nDict)
			+ 2u * nDict * C::kFootRank * C::kFootSpan;
	}

	// RGB332 바이트 → `[0,1]³`. ⚠️ **비트필드**다(스칼라로 쓰면 순서가 거짓말을 한다).
	static void Unpack(uint8 b, float* c)
	{
		c[0] = (float)((b >> 5) & 7u) / 7.0f;
		c[1] = (float)((b >> 2) & 7u) / 7.0f;
		c[2] = (float)(b & 3u) / 3.0f;
	}

	void Destroy() { for (uint32 i = 0; i < kNK; ++i) _k[i].Destroy(); _ar.Destroy(); }

	private:
	enum { kPE, kPEB, kGemm, kTop, kTopA, kTopB, kGather, kGatherB,
	       kResidualSwap, kCoeffSweep, kVis, kVisM, kVisT, kFoot, kFootM, kFootC, kFootS,
	       kSub, kAdam, kRms, kRmsB, kSwi, kSwiB, kNK };
	MLArena  _ar;
	MLKernel _k[kNK];
	uint32   _step = 0u;

	MLTensor _tP, _tG, _tM, _tV;
	MLTensor _tFPool, _tTPool, _tPatch, _tScore, _tIds, _tMag, _tIds2, _tMag2, _tMagC;
	MLTensor _tRecon, _tDRec, _tDMag, _tDScore, _tZeroPos;
	MLTensor _tCoef, _tDCoef, _tSH, _tCH, _tDSH, _tDCH;
	MLTensor _tScoreN, _tCoefN, _tDScoreN, _tDCoefN, _tGainScore, _tRstdS, _tRstdC;
	uint32   _curF = 0u, _curT = 0u, _nPool = 0u;
	uint32   _kAct = MLTP2Cfg::kK;   // ⭐ 지금 쓰는 활성 개수(스윕 축)
	bool     _absSel = false;        // ⭐ 선택 기준(기본은 기존 `act_topk`)
	uint32   _poolCap = MLTP2Cfg::kPool;
	// ⭐ 사전 크기와 그것이 정하는 파라미터 배치(전부 `Setup` 이 정한다)
	uint32   _n = MLTP2Cfg::kN;
	uint32   _oSlot = 0u, _oPos = 0u, _oW1a = 0u, _oW1b = 0u, _oWd = 0u;
	uint32   _oS1 = 0u, _oS2 = 0u, _oC1 = 0u, _oC2 = 0u, _oCode = 0u;
	uint32   _oFootX = 0u, _oFootY = 0u, _pCount = 0u;
	uint32   _hid = 0u, _h = MLTP2Cfg::kD;   // ⭐ 은닉 폭(0 = 없음) · 사전이 보는 폭
	bool     _swi = false;                   // ⭐ 은닉에 비선형을 거나
	uint32   _rank = 0u;
	bool     _couple = false, _headNorm = false, _resSwapCap = false, _resSwap = false;
	bool     _coeffCap = false, _coeff = false;
	bool     _freezeCode = false;
	bool     _globalFoot = false;
	float    _headScale = 1.0f;
	MLTensor _tA, _tB, _tH, _tHN, _tDH, _tDA, _tDB;
	Array<float> _p0;                // 초기 파라미터(씨앗마다 이것으로 되돌린다)
	MLTensor _tDMagX;    // ⭐ 회차 67 — 몸통에서 되돌아온 기울기(음수로 담긴다)
	bool     _extDMag = false;
	MLTensor _tDPatch;   // ⭐ `_tG + kOPos` 와 **겹친다**(의도 — 머리말의 그 자리)
	MLTensor _tOnes, _tGainH, _tGainPix, _tRstdH, _tRstd;   // ⭐ 크기 정규화용 고정 gain · rstd

	static bool _E(const char* n) { LogA("[mlt] 👁️ 디스패치 실패: %s\n", n); return false; }

	// ⭐ 0 채움 = `sub` 에 세 오프셋을 같은 자리로 준다(`x − x = 0`). 새 커널이 없다.
	//   ⚠️ `sub` 은 `[numthreads(256,1,1)]` 이라 2.4M 이면 그룹 9,474개 — 상한(65535)에 안 걸린다.
	bool _Zero(uint32 off, uint32 n)
	{
		MLSubParams q{}; q.aOff = off; q.bOff = off; q.outOff = off; q.count = n;
		return _k[kSub].Dispatch(n, 1u, 1u, &q, (uint32)sizeof(q));
	}

	// ★ 결정적 산포 — ⚠️ 난수를 안 쓴다(시드 스트림을 소비하면 비트 재현이 깨진다).
	static float _Spread(uint32 i, uint32 salt)
	{
		uint32 h = i * 2654435761u + salt * 2246822519u;
		h ^= (h >> 15); h *= 2654435761u; h ^= (h >> 13);
		return ((float)(h & 0xFFFFu) / 32768.0f) - 1.0f;
	}

	// P3-A1의 전역 토큰 역전파. 모든 출력 커널은 자기 파라미터 구간을 덮어쓴다.
	bool _BackwardFoot()
	{
		typedef MLTP2Cfg C;
		{
			MLFootReconMagBwdParams q{}; q.idsOff = _tIds.offset;
			q.codeOff = _tP.offset + _oCode; q.xOff = _tP.offset + _oFootX;
			q.yOff = _tP.offset + _oFootY; q.dOutOff = _tDRec.offset; q.dMagOff = _tDMag.offset;
			q.frames = 1u; q.k = _kAct; q.grid = C::kGrid; q.pixels = C::kPix;
			q.dict = _n; q.rank = C::kFootRank; q.span = C::kFootSpan;
			if (!_k[kFootM].Dispatch(_kAct, 1u, 1u, &q, (uint32)sizeof(q))) return _E("foot_bwd_mag");
		}
		{
			MLFootReconCodeBwdParams q{}; q.idsOff = _tIds.offset; q.magOff = _tMag.offset;
			q.xOff = _tP.offset + _oFootX; q.yOff = _tP.offset + _oFootY;
			q.dOutOff = _tDRec.offset; q.dCodeOff = _tG.offset + _oCode;
			q.frames = 1u; q.k = _kAct; q.grid = C::kGrid; q.pixels = C::kPix;
			q.dict = _n; q.rank = C::kFootRank; q.span = C::kFootSpan;
			if (!_k[kFootC].Dispatch(C::kPix, _n, 1u, &q, (uint32)sizeof(q))) return _E("foot_bwd_code");
		}
		{
			MLFootReconSpaceBwdParams q{}; q.idsOff = _tIds.offset; q.magOff = _tMag.offset;
			q.codeOff = _tP.offset + _oCode; q.xOff = _tP.offset + _oFootX;
			q.yOff = _tP.offset + _oFootY; q.dOutOff = _tDRec.offset;
			q.dXOff = _tG.offset + _oFootX; q.dYOff = _tG.offset + _oFootY;
			q.frames = 1u; q.k = _kAct; q.grid = C::kGrid; q.pixels = C::kPix;
			q.dict = _n; q.rank = C::kFootRank; q.span = C::kFootSpan;
			if (!_k[kFootS].Dispatch(C::kFootSpan, _n * C::kFootRank, 1u, &q, (uint32)sizeof(q)))
				return _E("foot_bwd_space");
		}
		{
			MLActTopkBwdParams q{}; q.idsOff = _tIds.offset; q.dMagOff = _tDMag.offset;
			q.dScoreOff = _tDScore.offset; q.rows = 1u; q.dict = C::kPatches * _n; q.k = _kAct;
			if (!_k[kTopB].Dispatch(q.dict, 1u, 1u, &q, (uint32)sizeof(q))) return _E("global_topk_bwd");
		}
		if (!_Gemm(_tDScore.offset, _tP.offset + _oWd, _tDPatch.offset,
			C::kPatches, C::kD, _n, 0u, 0u)) return _E("global_dScore·Wd");
		if (!_Gemm(_tDScore.offset, _tPatch.offset, _tG.offset + _oWd,
			_n, C::kD, C::kPatches, 1u, 0u)) return _E("global_dWd");
		{
			MLPatchEmbedParams q{}; q.frameOff = _curF; q.aOff = _tDPatch.offset;
			q.bOff = _tG.offset + _oSlot; q.frameW = C::kSide; q.frameH = C::kSide;
			q.patchK = C::kPatch; q.dim = C::kD;
			if (!_k[kPEB].Dispatch(C::kD, q.SlotRows(), 1u, &q, (uint32)sizeof(q)))
				return _E("global_patch_embed_bwd");
		}
		// dPatch가 겹쳐 있던 절대 위치 구간은 이 모델에서 고정 0 파라미터다.
		if (!_Zero(_tG.offset + _oPos, C::kPatches * C::kD)) return _E("zero(global dPos)");
		return true;
	}

	// 고정 부분집합의 LSQ 계수와 잔차를 함께 만든다. `A`/`b`는 _SolveK가 제자리 소거한다.
	static void _FitSubset(const Array<float>& code, uint32 nDict, const float* y,
		const uint32 pick[16], uint32 m, float ridge, float A[16][16], float b[16], float x[16],
		float* res)
	{
		typedef MLTP2Cfg C;
		for (uint32 a = 0; a < m; ++a)
		{
			const float* ua = (pick[a] < nDict) ? (code.Data() + pick[a] * C::kPix) : nullptr;
			for (uint32 bb = 0; bb < m; ++bb)
			{
				const float* ub = (pick[bb] < nDict) ? (code.Data() + pick[bb] * C::kPix) : nullptr;
				float s = 0.0f;
				if (ua != nullptr && ub != nullptr)
					for (uint32 d = 0; d < C::kPix; ++d) s += ua[d] * ub[d];
				A[a][bb] = s + ((a == bb) ? ridge : 0.0f);
			}
			float s = 0.0f;
			if (ua != nullptr) for (uint32 d = 0; d < C::kPix; ++d) s += ua[d] * y[d];
			b[a] = s;
		}
		_SolveK(A, b, x, m);
		for (uint32 d = 0; d < C::kPix; ++d)
		{
			float r = y[d];
			for (uint32 a = 0; a < m; ++a)
				if (pick[a] < nDict) r -= x[a] * code[pick[a] * C::kPix + d];
			res[d] = r;
		}
	}

	// `k × k` 가우스 소거(부분 피벗). ⚠️ 리지가 들어가 있어 특이행렬은 안 나온다.
	static void _SolveK(float A[16][16], float b[16], float x[16], uint32 k)
	{
		for (uint32 c = 0; c < k; ++c)
		{
			uint32 piv = c; float mx = Abs(A[c][c]);
			for (uint32 r = c + 1u; r < k; ++r) { const float v = Abs(A[r][c]); if (v > mx) { mx = v; piv = r; } }
			if (piv != c)
			{
				for (uint32 j = 0; j < k; ++j) { const float t2 = A[c][j]; A[c][j] = A[piv][j]; A[piv][j] = t2; }
				const float t3 = b[c]; b[c] = b[piv]; b[piv] = t3;
			}
			const float d = (Abs(A[c][c]) > 1.0e-20f) ? A[c][c] : 1.0e-20f;
			for (uint32 r = c + 1u; r < k; ++r)
			{
				const float f = A[r][c] / d;
				if (f == 0.0f) continue;
				for (uint32 j = c; j < k; ++j) A[r][j] -= f * A[c][j];
				b[r] -= f * b[c];
			}
		}
		for (int32 r = (int32)k - 1; r >= 0; --r)
		{
			float s = b[r];
			for (uint32 j = (uint32)r + 1u; j < k; ++j) s -= A[r][j] * x[j];
			const float d = (Abs(A[r][r]) > 1.0e-20f) ? A[r][r] : 1.0e-20f;
			x[r] = s / d;
		}
	}

	bool _Gemm(uint32 aOff, uint32 bOff, uint32 cOff,
		uint32 M, uint32 N, uint32 K, uint32 tA = 0u, uint32 tB = 0u, float beta = 0.0f)
	{
		MLGemmParams p{};
		p.aOff = aOff; p.bOff = bOff; p.cOff = cOff;
		p.M = M; p.N = N; p.K = K; p.transA = tA; p.transB = tB; p.beta = beta;
		return _k[kGemm].Dispatch(N, M, 1u, &p, (uint32)sizeof(p));
	}

	bool _Load(RHI* rhi, int idx, const char* path)
	{
		Bytes spv;
		if (!PlatformFile::LoadBytes(path, spv, PlatformFileSource::Package) || spv.GetSize() == 0)
		{ LogA("[mlt] 👁️ %s 를 못 읽었다(쿡 확인)\n", path); return false; }
		if (!_k[idx].Create(rhi, spv.GetData(), spv.GetSize(), _ar))
		{ LogA("[mlt] 👁️ 커널 생성 실패: %s\n", path); return false; }
		return true;
	}

	bool _LoadAll(RHI* rhi)
	{
		return _Load(rhi, kPE,   "shaders/patch_embed.cs.spv")
		    && _Load(rhi, kPEB,  "shaders/patch_embed_bwd.cs.spv")
		    && _Load(rhi, kGemm, "shaders/gemm.cs.spv")
		    && _Load(rhi, kTop,  "shaders/act_topk.cs.spv")
		    // ⭐ 선택은 `|z|` · 세기는 `z`(부호 그대로). 판정 ①② 통과(현재 판정 ① 29/29).
		    && _Load(rhi, kTopA, "shaders/act_topk_abs.cs.spv")
		    && _Load(rhi, kTopB, "shaders/act_topk_bwd.cs.spv")
		    && _Load(rhi, kGather,  "shaders/act_gather.cs.spv")
		    && _Load(rhi, kGatherB, "shaders/act_gather_bwd.cs.spv")
		    && _Load(rhi, kResidualSwap, "shaders/act_residual_swap.cs.spv")
		    && _Load(rhi, kCoeffSweep, "shaders/act_coeff_sweep.cs.spv")
		    && _Load(rhi, kVis,  "shaders/vis_recon.cs.spv")
		    && _Load(rhi, kVisM, "shaders/vis_recon_bwd_mag.cs.spv")
		    && _Load(rhi, kVisT, "shaders/vis_recon_bwd_tab.cs.spv")
		    && _Load(rhi, kFoot,  "shaders/foot_recon.cs.spv")
		    && _Load(rhi, kFootM, "shaders/foot_recon_bwd_mag.cs.spv")
		    && _Load(rhi, kFootC, "shaders/foot_recon_bwd_code.cs.spv")
		    && _Load(rhi, kFootS, "shaders/foot_recon_bwd_space.cs.spv")
		    && _Load(rhi, kSub,  "shaders/sub.cs.spv")
		    && _Load(rhi, kAdam, "shaders/adamw.cs.spv")
		    // ⭐ 사전 유닛의 크기 정규화용 — **이미 판정 통과한 커널**이다(새 커널 0개).
		    && _Load(rhi, kRms,  "shaders/rmsnorm.cs.spv")
		    && _Load(rhi, kRmsB, "shaders/rmsnorm_bwd.cs.spv")
		    // ⭐ 은닉 한 겹의 비선형 — **이미 판정 ①② 를 통과한 커널**이다(새 커널 0개).
		    && _Load(rhi, kSwi,  "shaders/swiglu.cs.spv")
		    && _Load(rhi, kSwiB, "shaders/swiglu_bwd.cs.spv");
	}
};
