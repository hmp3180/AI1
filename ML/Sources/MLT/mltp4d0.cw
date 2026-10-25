// mltp4d0.cw — 🎯 회차 107 · **P4 ㉡ 오귀속률** (`-mltp4d0`) ⭐ **P4 의 마지막 관문**
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 107 이다.** ⭐ **하네스보다 먼저 썼다.**
//   ⚠️ 계보(회차 103~106 의 머리말)는 `mltp4c3.cw` 와 `mltlog_1.md` 에 있다 — 여기 다시 옮기지 않는다.
//
// ── ⭐ 무엇을 묻나 ────────────────────────────────────────────────────────
//   `MLT.md` P4 ㉡ = *"스스로 움직이는 도형의 변화를 **행동 탓**으로 예측하나."*
//   ⇒ mltconcept 「행동값은 주어질 수 있고 **인과는 아니다**」 가 **배우라고 한 그 인과**다.
//
// ── ⚠️ 옛 설계 메모의 후보 셋을 밀어낸다 ───────────────────────────────────
//   `mltlog_1.md` 의 「㉡ 오귀속률의 설계 난점」(2026-08-27)이 안 셋을 적고 **전부에 약점**을 달았다:
//     ㈎ 출처별 교차차 → ⚠️ **문턱이 없다**  ㈏ 자율 속도 개입 → ⚠️ **세계에 길이 없다**
//     ㈐ 대조 세계(자율 0) → ⚠️ **난이도가 같이 달라진다**
//   ⭐ 그리고 그 메모의 핵심 통찰은 이것이었다:
//     *"자율 도형도 **화면에 어떻게 보이는가**는 관측자 이동에 달려 있다 ⇒ 정답은 0 이 아니다."*
//
// ── ⭐ 넷째 안 = **반사실 개입** — 표적마다 「내 행동이 정했나」를 **세계가 답한다** ──
//   ```
//   시각 t 에서 갈라 **한 걸음만** 다르게 굴린다  (⭐ `StepWith` — 회차 77 이 이미 만들었다)
//      실기   : StepWith(a )  → 프레임 t+1 → 인코더 → 표적 id  idReal[j]
//      반사실 : StepWith(a')  → 프레임 t+1 → 인코더 →          idCf  [j]
//   ⭐ 「가름」 = idCf[j] ≠ idReal[j]   ← **내 행동이 이 표적을 정했다**
//   ⭐ 「무관」 = idCf[j] = idReal[j]   ← **뭘 했든 같았다**
//   ```
//   ⇒ ⭐ 자율 유래여도 **관측자 이동으로 바뀌었으면 「가름」**이다 ⇒ 메모의 난점이 **자동으로 풀린다**.
//
// ── ⭐ 표제는 **2×2 의 한 칸**이다 — 회차 106 과 갈리는 자리 ──────────
//   |                | **가름**(행동이 정했다) | **무관**(행동과 무관) |
//   |----------------|------------------------|----------------------|
//   | **비지속**(바뀌었다) | **A** = 올바른 읽기      | ⭐ **B = 오귀속의 자리** |
//   | **지속**(안 바뀌었다) | C                      | D = 안 읽어도 되는 자리 |
//
//   ⚠️⚠️ **회차 106 은 「비지속」 전체(A+B)를 한 덩어리로 봤다.** B 는 *"바뀌었지만 내 행동 탓이
//     아닌"* 칸이고, 거기서 행동을 읽는 것이 곧 **오귀속**이다.
//
//   ⭐ **오귀속률** `M = mean Δ끊음(B) / mean Δ끊음(A)`
//     ★ **난이도가 짝맞춰져 있다**(둘 다 「비지속」) ⇒ *"그 칸이 그냥 쉬워서"* 가 상쇄된다.
//     `M ≈ 0` = 행동이 정한 곳**에서만** 읽는다 · `M ≈ 1` = **완전 무차별** = 완전 오귀속.
//
// ── ⚠️ B 칸이 무엇인지 정확히 못박는다 ────────────────────────────────────
//   B = ***"슬롯이 바뀌었는데, 내가 다른 행동을 했어도 같은 표적이었을 자리"***.
//   ⚠️ **「자율 도형 유래」만이 아니다** — 우연히 같아진 것도 든다. ★ 그래도 정의가 깨끗하다:
//     그 자리에서 **행동을 읽는 것은 정답을 맞히는 데 원리적으로 불필요**하다.
//   ⚠️ 「자율 도형 유래」만 따로 떼는 것(패치→도형 겹침)은 **이 회차에서 안 한다** — 겹침 판정이
//     자기 실패 모드를 갖고, 표제를 둘로 만들면 본페로니가 깨진다 ⇒ **107 이 서면 다음 회차**다.
//
// ── ✅ 관문 ───────────────────────────────────────────────────────────────
//   **배관** ㈃ `lr=0` 평탄 12/12 · ㈀ 이 복사바닥 넘음 ≥10/12 · ㈄ 눈금 팔이 섬 ≥10/12 · 유한
//   ⭐ **판정 ①** — 반사실을 **`a' = a`** 로 돌리면 표적이 ***한 칸도 안 달라야 한다***
//     ★ 회차 77 의 판정 ①(`StepWith(ActAt) ≡ Step()`)과 **같은 꼴**이고, 이번엔 갈래가 더 길다:
//       갈라내기 → `StepWith` → `Render` → `Pack` → 인코더 → `Pick` **전부**를 한 번에 증명한다.
//   ⭐ **분모 관문**(규율 16·26) `mean Δ끊음(A) > 0` **12/12** — ⚠️ 안 서면 비가 뜻이 없다 ⇒ 판정불가
//   ⭐ **세계에 신호가 있나**(규율 26) — 「가름」 비율 · **네 칸의 표적 수**를 찍는다(⚠️ 문턱 없음)
//     ⚠️⚠️ **B 가 전체의 5% 미만이면 판정불가**로 적는다(자가 못 선다)
//   ⭐ **표제** `M < 0.5` — `≥10/12`
//   ⭐ **후퇴선**(미리 등록) `M < 1.0` — `≥10/12`. ⚠️ **표제가 아니다**(순서 있는 둘째 가설)
//
// ── 📏 잡음 바닥(규율 9) — **문턱보다 먼저 계산했다** ──────────────────────
//   표적 28,672 · 표적당 `sd(Δ끊음) ≈ 0.212`(회차 104 실측) ⇒ 칸이 ~7,000 이면 `sd(칸평균) ≈ 0.0025`.
//   회차 103·106 에서 역산: `평균Δ(비지속) ≈ +0.010` · `평균Δ(지속) ≈ −0.016`
//   ⇒ `m_A≈0.015 · m_B≈0.005` 로 두면 **`sd(M) ≈ 0.17`**.
//   ⚠️⚠️ **문턱 0.5 는 잡음의 3배 안쪽이다** ⇒ 씨앗마다 흔들린다 ⇒ **분할 반쪽**도 같이 찍는다.
//
// ── ⭐ 예측을 미리 적었다 ─────────────────────────────────────────────────
//   ⚠️ **회차 106 에서 내 예측이 틀렸다**(*"8/12 로 진다"* → 10/12) — 유리한 쪽으로 틀렸다.
//   · 배관·판정 ① **12/12** · 「가름」 비율 **25~40%**(회차 102 는 32.6% 를 쟀다 — ⚠️ 다른 자였다)
//   · `mean Δ끊음(A) > 0` — ⭐ **선다**(회차 106 이 비지속에서 읽는다고 세웠다)
//   · ⭐ **M** — ⚠️ ***진짜 모른다.*** **0.3~0.7** 예측 · `M<0.5` 는 ***반반*** · `M<1.0` 은 아마 통과
//   · ⚠️ **가장 큰 실패 모드 = B 칸이 너무 작은 것**
//
// ── 🔩 배관 — **새 커널 0개 · 세계 수정 0줄** ─────────────────────────────
//   반사실 한 걸음 = `MLTWorld` **값 복사**(멤버가 전부 POD) → `StepWith(a')` → `Render`/`Pack`.
//   `a'` = ⭐ **다른 에피소드의 행동열**(`kCfEpi`) — ⚠️ **부호 반전을 안 쓴다**(개입이 최대가 되어
//     「가름」이 부풀려진다). ★ `ActAt` 을 쓰므로 `_hold` 규약까지 실기와 같다.
//   표적 선택 = ⭐ **`MLTP4Ctx::Pick`**(회차 107 이 `StoreAct` 에서 뽑아냈다 — 두 벌이면 갈린다).
//
// ⚠️ 회차 104·106 의 자(폭·상관·다섯 축)도 **그대로 돈다** — 회귀 검사를 겸한다.

using namespace PE;

class MLTP4D0
{
public:
	static void Tick(RHI* rhi)
	{
		if (_done || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltp4d0"))
		{
			LogA("[mlt] 🎯 회차 107(P4 ㉡ 오귀속률)은 **꺼져 있다**(`-mltp4d0`)\n");
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
	static constexpr uint32 kNCtx = 512u, kTestCtx = 512u;
	static constexpr uint32 kTrainEpi = 1u, kTestEpi = 901u;
	static_assert(kTestEpi >= kTrainEpi + kNCtx,
		"시험 에피소드가 학습과 겹친다 — kTestEpi >= kTrainEpi + kNCtx 여야 한다(회차 81 이 찾았다)");
	// ⭐ **반사실 행동 `a'` 를 뽑는 에피소드 대역** — ⚠️ 학습/시험 어느 쪽과도 안 겹쳐야 한다.
	//   ★ 세계 상태는 **실기 그대로**이고 여기서 가져오는 것은 **행동열뿐**이다.
	static constexpr uint32 kCfEpi = 5001u;
	static_assert(kCfEpi >= kTestEpi + kTestCtx,
		"반사실 행동열이 시험 에피소드와 겹친다 — kCfEpi >= kTestEpi + kTestCtx 여야 한다");
	static constexpr uint32 kPoolSteps = kNCtx / kBatch, kTestPool = kTestCtx / kBatch;
	static constexpr uint32 kGroup = kEncF / kTime;                 // 4 문맥
	// ⭐ 반사실 프레임 수 — 그룹당 `문맥 4 × 시각 0..6` = **28** (⚠️ 인코더 풀 상한 32 안이다)
	static constexpr uint32 kCfN = kGroup * (kTime - 1u);
	static_assert(kCfN <= kEncF, "반사실 프레임이 인코더 풀 상한을 넘는다");
	static constexpr uint32 kSteps = 800u, kPerTick = 4u;
	static constexpr uint32 kArms = 5u, kRep = 6u;
	static constexpr uint32 kArmWhole = 0u, kArmActCut = 1u, kArmActRnd = 2u,
		kArmLr0 = 3u, kArmPerCut = 4u;
	static constexpr uint32 kSignPass = 10u;
	static constexpr float  kFlatRel = 1.0e-6f;
	static constexpr float  kWidePass = 0.10f;      // 회차 104 의 문턱(회귀)
	static constexpr float  kCorrPass = 0.10f;      // 회차 104 의 문턱(회귀)
	// ⭐ **회차 107 의 문턱 둘** — 순서 있는 가설이다(표제 → 후퇴선). ⚠️ 결과를 보고 안 고친다.
	static constexpr float  kMisPass  = 0.50f;      // ⭐ 표제
	static constexpr float  kMisBack  = 1.00f;      // ⭐ 후퇴선(= 무차별선)
	// ⚠️ B 칸이 이보다 작으면 자가 못 선다 ⇒ **판정불가**로 적는다
	static constexpr float  kCellMin  = 0.05f;
	static constexpr uint32 kActFrom = MLTP4Ctx::kOAct;                    // 5
	static constexpr uint32 kActTo   = MLTP4Ctx::kOAct + MLTP4Ctx::kActAx; // 10
	static constexpr uint32 kNone = MLTP4Ctx::kStateAx + MLTP4Ctx::kActAx + kN;   // 260
	static constexpr uint32 kSymVocab = kNone + 1u;                              // 261
	// ⚠️ 반사실이 아직 안 채운 자리 — 세지 않는다(빈칸이 있으면 요약이 알린다).
	static constexpr uint32 kNoCf = 0xFFFFFFFFu;

	enum { kEncInit, kEncTrain, kGather, kQuiesce, kBodyInit, kBodyTrain, kBodyEval };
	// ⭐ 그룹 안의 **패스** — 0 = 실기 · 1 = 판정①(`a'=a`) · 2 = 반사실(`a'≠a`)
	enum { kPassReal = 0u, kPassCheck = 1u, kPassCf = 2u };

	inline static MLTP2Enc _E;
	inline static MLTModel _M;
	inline static MLTP4Ctx _tr, _te;
	inline static MLTEvalGate _gate;
	inline static bool _done = false, _banner = false, _encSetup = false, _finite = true;
	inline static bool _pending = false, _pre = false;
	inline static uint32 _seed = 0u, _st = kEncInit, _step = 0u, _arm = 0u, _rep = 0u;
	inline static uint32 _cor = 0u, _gGrp = 0u, _gIdx = 0u, _gPass = kPassReal;
	inline static Array<float> _code, _norm;
	inline static Array<float> _trVal, _trSym, _teVal, _teSym;
	inline static float _run[kRep];
	inline static float _ce[kArms][kSeeds];
	inline static float _ceA[kArms][kSeeds], _ceB[kArms][kSeeds];
	inline static float _pre0[kSeeds];
	inline static float _floorTe[kSeeds];
	inline static bool  _seedOk[kSeeds];

	inline static uint32 _qWait = 0u;
	static void _ToBody() { _qWait = MLTEvalGate::kDelay; _st = kQuiesce; }

	static constexpr uint32 kRowN = kTestPool * MLTP4Ctx::kRows;   // 64 × 1152 = 73,728
	inline static Array<float> _rowAcc;
	inline static Array<float> _rows[kArms];
	inline static uint32 _ei = 0u, _ewait = 0u;
	inline static bool   _epend = false;
	inline static double _esum = 0.0;
	inline static float _sdRatio[kSeeds], _corrCut[kSeeds];
	inline static Array<float> _wDYaw, _wANorm, _wMinD;
	static constexpr uint32 kSplits = 5u;
	inline static float _sepCut[kSplits][kSeeds], _sepPer[kSplits][kSeeds];
	inline static float _sepHalf[kSplits][2][kSeeds];

	// ⭐ **회차 107** — 반사실 표적 id(시험 코퍼스) · `MLTP4Ctx::Tix` 로 색인한다.
	inline static Array<uint32> _cfId;
	// 판정 ① — `a'=a` 로 돌린 그룹에서 **다른 칸 수**(0 이어야 한다)와 견준 칸 수
	//   ⚠️ 씨앗마다 비우는 것과 **전 씨앗 누산**을 둘 다 든다 — 요약이 마지막 씨앗만 보면 안 된다.
	inline static uint32 _chkDiff = 0u, _chkSeen = 0u;
	inline static uint32 _chkDiffAll = 0u, _chkSeenAll = 0u;
	// 씨앗별 오귀속 결과
	inline static float  _mis[kSeeds], _misH[2][kSeeds];
	inline static float  _mCutA[kSeeds], _mCutB[kSeeds];
	inline static float  _fracChg[kSeeds];
	inline static uint32 _cell[2][2][kSeeds];   // [지속][가름]

	static const char* _SplitName(uint32 s)
	{
		switch (s)
		{
		case 0u: return "㉠ |dYaw| 회전량     ";
		case 1u: return "㉡ |a|   행동세기   ";
		case 2u: return "㉢ minDOn 가장가까움 ";
		case 3u: return "㉣ 지속 여부(0/1)   ";
		default: return "㉤ 시각 t          ";
		}
	}

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
		LogA("[mlt] 🎯 **회차 107 · P4 ㉡ 오귀속률** — ⭐ **P4 의 마지막 관문**\n");
		LogA("[mlt] 🎯   묻는 것 — *\"스스로 움직이는 것의 변화를 **자기 행동 탓**으로 예측하나\"*\n");
		LogA("[mlt] 🎯   ⭐ **반사실 개입** — 시각 t 에서 갈라 **한 걸음만** 다르게 굴린다(`StepWith(a')`)\n");
		LogA("[mlt] 🎯     「가름」 = 반사실 표적 ≠ 실기 표적 (**내 행동이 정했다**) · 「무관」 = 같다 (**뭘 했든 같았다**)\n");
		LogA("[mlt] 🎯     ⭐ 그래서 옛 메모의 난점이 **자동으로 풀린다** — 자율 유래여도 관측자 이동으로 바뀌면 「가름」이다\n");
		LogA("[mlt] 🎯   ⭐ **표제는 2×2 의 한 칸** — ⚠️ 회차 106 은 「비지속」 전체(A+B)를 한 덩어리로 봤다\n");
		LogA("[mlt] 🎯     A = 비지속&가름(올바른 읽기) · **B = 비지속&무관 = 오귀속의 자리** · C = 지속&가름 · D = 지속&무관\n");
		LogA("[mlt] 🎯   ⭐ **오귀속률 M = 평균Δ끊음(B) / 평균Δ끊음(A)** — ★ 둘 다 「비지속」이라 **난이도가 짝맞는다**\n");
		LogA("[mlt] 🎯     `M≈0` 행동이 정한 곳에서만 읽는다 · `M≈1` **완전 무차별 = 완전 오귀속**\n");
		LogA("[mlt] 🎯   **표제** `M < %.2f` ≥%u/12 · **후퇴선**(미리 등록) `M < %.2f` ≥%u/12 — ⚠️ 후퇴선은 표제가 **아니다**\n",
			(double)kMisPass, kSignPass, (double)kMisBack, kSignPass);
		LogA("[mlt] 🎯   ⭐ **판정 ①** — 반사실을 `a'=a` 로 돌리면 표적이 **한 칸도 안 달라야** 한다(회차 77 과 같은 꼴)\n");
		LogA("[mlt] 🎯   ⭐ **분모 관문**(규율 16·26) — `평균Δ끊음(A) > 0` **12/12** · 안 서면 **판정불가**\n");
		LogA("[mlt] 🎯   ⚠️⚠️ **B 칸이 전체의 %.0f%% 미만이면 판정불가** — 자가 못 선다\n", (double)(kCellMin * 100.0f));
		LogA("[mlt] 🎯   📏 잡음(규율 9) — 칸 ~7,000 이면 `sd(칸평균)≈0.0025` ⇒ **`sd(M)≈0.17`** ⇒ 문턱 0.5 는 **3배 안쪽**\n");
		LogA("[mlt] 🎯   ⭐ **예측** — 배관·판정① 12/12 · 「가름」 25~40%% · 분모 선다 · **M 은 진짜 모른다**(0.3~0.7 · 반반)\n");
		LogA("[mlt] 🎯   ⚠️ 회차 106 에서 내 예측이 **틀렸다**(*\"8/12 로 진다\"* → 10/12) — 유리한 쪽으로 틀렸다\n");
		LogA("[mlt] 🗺️   (회차 104·106 의 자도 그대로 돈다 — **회귀 검사**를 겸한다: 폭 0.1848 · 상관 +0.5145 · ㉣ −0.02592)\n");
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
		_wDYaw.Reset(0); _wANorm.Reset(0); _wMinD.Reset(0);
		for (uint32 i = 0; i < kTestCtx * kTime; ++i)
		{ _wDYaw.Add(0.0f); _wANorm.Add(0.0f); _wMinD.Add(0.0f); }
		// ⭐ 반사실 표적 자리 — `kNoCf` 로 채워 두고 반사실 패스가 덮는다.
		_cfId.Reset(0);
		for (uint32 i = 0; i < kTestCtx * (kTime - 1u) * MLTP4Ctx::kPersist; ++i) _cfId.Add(kNoCf);
		_chkDiff = 0u; _chkSeen = 0u;
		_cor = 0u; _gGrp = 0u; _gIdx = 0u; _gPass = kPassReal; _pending = false; _st = kGather;
	}

	// ⭐ 그룹의 **실기** 32프레임을 만든다(회차 105 의 세계 값 수집도 여기서 한다).
	static bool _BuildReal(MLTP4Ctx& C)
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
				// ⭐ **P4 규약**(회차 79) — 렌더·상태·활성을 **먼저**, **그 다음** 행동을 넣고 굴린다.
				if (!w.Render(bmp) || !MLTWorld::Pack(bmp, nullptr, packed))
				{ _Fail("Render/Pack(문맥)"); return false; }
				MLTP2Enc::AppendFrame(fr, tg, (const uint8*)packed.GetData());
				C.StoreState(ctx, t, w.State());
				const MLTAct a = w.ActAt(w.StepNo());
				if (_cor == 1u)
				{
					double sq = 0.0;
					for (int q = 0; q < MLTAct::kAxes; ++q) sq += (double)a.Axis(q) * (double)a.Axis(q);
					const uint32 wi = ctx * kTime + t;
					_wDYaw.Data()[wi] = Abs(a.dYaw);
					_wANorm.Data()[wi] = (float)Sqrt((float)sq);
					MLTShapeView vs[MLTWorldCfg::kShapes];
					const int nv = w.VisibleShapes(vs, MLTWorldCfg::kShapes);
					const float SS = (float)MLTWorldCfg::kSide;
					float dOn = 1.0e6f; bool haveOn = false;
					for (int q = 0; q < nv; ++q)
					{
						if (!(vs[q].sx >= 0.0f && vs[q].sx < SS && vs[q].sy >= 0.0f && vs[q].sy < SS)) continue;
						if (!haveOn || vs[q].d < dOn) { dOn = vs[q].d; haveOn = true; }
					}
					_wMinD.Data()[wi] = dOn;
				}
				C.StoreAct5(ctx, t, a);
				w.StepWith(a);
			}
		}
		if (!_E.WritePool(fr, tg, kEncF)) { _Fail("문맥 풀 업로드"); return false; }
		return true;
	}

	// ⭐ 그룹의 **반사실** 28프레임을 만든다 — 시각 `t` 에서 갈라 **한 걸음만** 다르게 굴린다.
	//   ⚠️⚠️ 실기와 **같은 세계·같은 상태**에서 갈린다(`MLTWorld` 는 멤버가 전부 POD ⇒ 값 복사가 곧 갈래).
	//   ⚠️ `check` 면 `a' = a` 다 ⇒ **표적이 한 칸도 안 달라야 한다**(판정 ①).
	static bool _BuildCf(bool check)
	{
		Array<float> fr, tg; fr.Reset(0); tg.Reset(0);
		ImageFormat::Bitmap bmp; Bytes packed;
		for (uint32 g = 0; g < kGroup; ++g)
		{
			const uint32 ctx = _gGrp * kGroup + g;
			MLTWorld w;  w.Reset(_seed, kTestEpi + ctx, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
			// ⚠️ **행동열만** 빌려 온다(세계 상태는 실기 그대로다) — `ActAt` 이라 `_hold` 규약까지 같다.
			MLTWorld wa; wa.Reset(_seed, kCfEpi  + ctx, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
			for (uint32 t = 0; t < kTime; ++t)
			{
				const MLTAct a = w.ActAt(w.StepNo());
				if (t + 1u < kTime)
				{
					const MLTAct ap = check ? a : wa.ActAt(t);
					MLTWorld wc = w;                       // ⭐ 갈래 — 값 복사
					wc.StepWith(ap);
					if (!wc.Render(bmp) || !MLTWorld::Pack(bmp, nullptr, packed))
					{ _Fail("Render/Pack(반사실)"); return false; }
					MLTP2Enc::AppendFrame(fr, tg, (const uint8*)packed.GetData());
				}
				w.StepWith(a);
			}
		}
		if (!_E.WritePool(fr, tg, kCfN)) { _Fail("반사실 풀 업로드"); return false; }
		return true;
	}

	static void _Gather()
	{
		MLTP4Ctx& C = (_cor == 0u) ? _tr : _te;
		const uint32 nCtx = (_cor == 0u) ? kNCtx : kTestCtx;
		if (_pending)
		{
			Array<float> ids, mag;
			if (!_E.ReadAct(ids, mag) || ids.Count() != kCandidates) { _Fail("활성 리드백"); return; }
			const uint32 f = _gIdx - 1u;
			if (_gPass == kPassReal)
				C.StoreAct(_gGrp * kGroup + f / kTime, f % kTime, ids, mag, _norm);
			else
			{
				// ⭐ 반사실 프레임 `f` = (문맥 g, 시각 t) — `t+1` 의 활성이 그 표적 자리다.
				const uint32 g = f / (kTime - 1u), t = f % (kTime - 1u);
				const uint32 ctx = _gGrp * kGroup + g;
				uint32 pick[MLTP4Ctx::kPersist]; float pm[MLTP4Ctx::kPersist];
				uint32 pc[MLTP4Ctx::kPersist]; float maxAbs = 0.0f;
				// ⚠️⚠️ **실기와 한 글자도 다르지 않은 선택 식**이어야 한다 ⇒ `MLTP4Ctx::Pick`.
				MLTP4Ctx::Pick(ids, mag, _norm, kN, true, pick, pm, pc, maxAbs);
				for (uint32 j = 0; j < MLTP4Ctx::kPersist; ++j)
				{
					const uint32 ix = MLTP4Ctx::Tix(ctx, t, j);
					if (_gPass == kPassCf) { _cfId.Data()[ix] = pick[j]; continue; }
					// 판정 ① — `a'=a` 면 표적과 **같아야 한다**
					const float tf = _te.Tgt()[MLTP4Ctx::Row(ctx, t, MLTP4Ctx::kOAct2) + j];
					if (!(tf >= 0.0f && tf < (float)kN)) continue;
					++_chkSeen;
					if (pick[j] != (uint32)tf) ++_chkDiff;
				}
			}
			_pending = false;
		}
		if (_gIdx == 0u)
		{
			if (_gPass == kPassReal) { if (!_BuildReal(C)) return; }
			else if (!_BuildCf(_gPass == kPassCheck)) return;
		}
		const uint32 nF = (_gPass == kPassReal) ? kEncF : kCfN;
		if (_gIdx < nF)
		{
			_E.SetFrame(_gIdx);
			if (!_E.Forward()) { _Fail("문맥 forward"); return; }
			++_gIdx; _pending = true; return;
		}
		_gIdx = 0;
		// ⭐ 시험 코퍼스만 반사실을 돈다. **첫 그룹에서만** 판정 ①(`a'=a`)을 한 번 더 돈다.
		if (_cor == 1u)
		{
			if (_gPass == kPassReal)  { _gPass = (_gGrp == 0u) ? kPassCheck : kPassCf; return; }
			if (_gPass == kPassCheck) { _gPass = kPassCf; return; }
		}
		_gPass = kPassReal;
		if (++_gGrp * kGroup >= nCtx)
		{
			_gGrp = 0u;
			if (++_cor >= 2u)
			{
				Array<float> marg; _tr.Marginal(marg);
				float c1 = 0.0f, c2 = 0.0f, l1 = 0.0f, l2 = 0.0f;
				_tr.BestCopy(marg, c1, c2, l1, l2, MLTP4Ctx::kAllT1);
				const float t1 = (float)_te.CeCopy(marg, l1, false, MLTP4Ctx::kAllT1);
				const float t2 = (float)_te.CeCopy(marg, l2, true, MLTP4Ctx::kAllT1);
				_floorTe[_seed] = (t1 < t2) ? t1 : t2;
				LogA("[mlt] ✂️ 씨앗 %2u · 시험 복사바닥(모든 예측 시각 · 표적 %u개) **%.4f**\n",
					_seed, kTestCtx * (kTime - 1u) * MLTP4Ctx::kPersist, (double)_floorTe[_seed]);
				_chkDiffAll += _chkDiff; _chkSeenAll += _chkSeen;
				LogA("[mlt] 🎯 씨앗 %2u · ⭐ **판정 ①**(`a'=a` · 첫 그룹 %u문맥) — 견준 칸 %u · **다른 칸 %u** → %s\n",
					_seed, kGroup, _chkSeen, _chkDiff, (_chkDiff == 0u) ? "✅" : "⛔");
				_arm = 0u; _rep = 0u; _ToBody();
			}
		}
	}

	static void _CutPool(const MLTP4Ctx& C, uint32 nCtx, uint32 cor, Array<float>& val, Array<float>& sym)
	{
		const uint32 n = (nCtx / kBatch) * MLTP4Ctx::kRows;
		val.Reset(0); sym.Reset(0);
		for (uint32 i = 0; i < n; ++i) { val.Add(C.Val()[i]); sym.Add(C.Sym()[i]); }
		if (_arm == kArmWhole || _arm == kArmLr0) return;
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
			for (uint32 t = 0; t < kTime; ++t)
			{
				const uint32 base = MLTP4Ctx::Row(ctx, t, kActFrom);
				for (uint32 i = 0; i < MLTP4Ctx::kActAx; ++i)
				{
					if (_arm == kArmActCut) { sym.Data()[base + i] = (float)kNone; val.Data()[base + i] = 0.0f; }
					else
					{
						const uint32 key = _seed * 7919u + cor * 1000003u + ctx * 131u + t * 17u + i;
						const uint32 h = MLTWorld::Hash(key, MLTSalt::Start, 42u);
						val.Data()[base + i] = MLTWorld::Unit(h);
					}
				}
			}
	}

	static void _BodyBegin(RHI* rhi)
	{
		if (!_M.Setup(rhi, kSymVocab, kN, MLTP4Ctx::kAxes, kTime)) { _Fail("몸통 준비"); return; }
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
			if (!_M.Forward() || !_M.Backward() || !_M.AdamStep((_arm == kArmLr0) ? 0.0f : 1.0f))
			{ _Fail("몸통 스텝"); return; }
			++_step;
		}
	}

	static void _BodyEval()
	{
		if (_epend)
		{
			if (_ewait > 0u) { --_ewait; return; }
			float ls = 0.0f;
			if (!_M.ReadLoss(ls)) { _Fail("평가 리드백"); return; }
			if (!(ls == ls) || ls > 1.0e30f) _finite = false;
			_esum += (double)ls;
			if (_arm != kArmLr0)
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
		_Distribution();     // 회차 104 의 자(회귀)
		_Separate();         // 회차 105·106 의 자(회귀)
		_Misattr();          // ⭐ 회차 107 의 물음
		_seedOk[_seed] = _finite;
		++_seed; _st = kEncInit;
	}

	// ══════════════════════════════════════════════════════════════════
	// ⭐ **회차 107 — 오귀속률.** 표적을 `[지속?][가름?]` 2×2 로 갈라 평균 `Δ끊음` 을 본다.
	// ══════════════════════════════════════════════════════════════════
	//   ⚠️ 재학습이 없다 — 이미 채운 `_rows[]` 와 `_cfId[]` 를 그대로 쓴다.
	static void _Misattr()
	{
		double sum[2][2]; uint32 cnt[2][2];
		double sumH[2][2][2]; uint32 cntH[2][2][2];
		for (uint32 p = 0; p < 2u; ++p)
			for (uint32 c = 0; c < 2u; ++c)
			{
				sum[p][c] = 0.0; cnt[p][c] = 0u;
				for (uint32 h = 0; h < 2u; ++h) { sumH[h][p][c] = 0.0; cntH[h][p][c] = 0u; }
			}
		uint32 i = 0u, noCf = 0u;
		for (uint32 ctx = 0; ctx < kTestCtx; ++ctx)
			for (uint32 t = 0; t + 1u < kTime; ++t)
				for (uint32 j = 0; j < MLTP4Ctx::kPersist; ++j)
				{
					const uint32 r = MLTP4Ctx::Row(ctx, t, MLTP4Ctx::kOAct2) + j;
					const float tf = _te.Tgt()[r];
					if (!(tf >= 0.0f && tf < (float)kN)) continue;
					const uint32 cf = _cfId[MLTP4Ctx::Tix(ctx, t, j)];
					if (cf == kNoCf) { ++noCf; continue; }        // ⚠️ 안 채워진 자리는 안 센다
					const float d = _rows[kArmActCut][r] - _rows[kArmWhole][r];
					const uint32 nowId =
						(uint32)(_te.Sym()[r] - (float)(MLTP4Ctx::kStateAx + MLTP4Ctx::kActAx));
					const uint32 per = (nowId == (uint32)tf) ? 1u : 0u;   // 지속
					const uint32 chg = (cf != (uint32)tf) ? 1u : 0u;      // ⭐ 가름
					const uint32 h = i & 1u;
					sum[per][chg] += (double)d; ++cnt[per][chg];
					sumH[h][per][chg] += (double)d; ++cntH[h][per][chg];
					++i;
				}
		for (uint32 p = 0; p < 2u; ++p)
			for (uint32 c = 0; c < 2u; ++c) _cell[p][c][_seed] = cnt[p][c];
		const uint32 nAll = cnt[0][0] + cnt[0][1] + cnt[1][0] + cnt[1][1];
		_fracChg[_seed] = (nAll == 0u) ? 0.0f : (float)((double)(cnt[0][1] + cnt[1][1]) / (double)nAll);
		const double mA = (cnt[0][1] == 0u) ? 0.0 : (sum[0][1] / (double)cnt[0][1]);   // 비지속 & 가름
		const double mB = (cnt[0][0] == 0u) ? 0.0 : (sum[0][0] / (double)cnt[0][0]);   // 비지속 & 무관
		_mCutA[_seed] = (float)mA; _mCutB[_seed] = (float)mB;
		_mis[_seed] = (mA > 1.0e-9) ? (float)(mB / mA) : 1.0e9f;   // ⚠️ 분모가 안 서면 큰 값(관문이 잡는다)
		for (uint32 h = 0; h < 2u; ++h)
		{
			const double a = (cntH[h][0][1] == 0u) ? 0.0 : (sumH[h][0][1] / (double)cntH[h][0][1]);
			const double b = (cntH[h][0][0] == 0u) ? 0.0 : (sumH[h][0][0] / (double)cntH[h][0][0]);
			_misH[h][_seed] = (a > 1.0e-9) ? (float)(b / a) : 1.0e9f;
		}
		LogA("[mlt] 🎯   씨앗 %2u · 칸 수 — **A 비지속&가름 %u** · **B 비지속&무관 %u** · C 지속&가름 %u · D 지속&무관 %u"
			" (「가름」 %.1f%%%s)\n",
			_seed, cnt[0][1], cnt[0][0], cnt[1][1], cnt[1][0], (double)(_fracChg[_seed] * 100.0f),
			(noCf != 0u) ? " ⚠️ 반사실 빈칸 있음" : "");
		LogA("[mlt] 🎯   씨앗 %2u · 평균Δ끊음 — **A %+.5f**(분모) · **B %+.5f**(오귀속) ⇒ ⭐ **M = %+.4f**"
			" (반쪽 %+.4f / %+.4f)\n",
			_seed, mA, mB, (double)_mis[_seed], (double)_misH[0][_seed], (double)_misH[1][_seed]);
	}

	static float _Quant(const Array<float>& v, uint32 n, float lo, float hi, float frac)
	{
		const uint32 want = (uint32)((double)n * (double)frac + 0.5);
		for (int it = 0; it < 50; ++it)
		{
			const float mid = 0.5f * (lo + hi);
			uint32 c = 0u;
			for (uint32 i = 0; i < n; ++i) if (v[i] < mid) ++c;
			if (c < want) lo = mid; else hi = mid;
		}
		return 0.5f * (lo + hi);
	}

	// 회차 105·106 의 자 — **회귀 검사**로 그대로 돈다.
	static void _Separate()
	{
		static Array<float> key[kSplits], dCut, dPer;
		for (uint32 s = 0; s < kSplits; ++s) key[s].Reset(0);
		dCut.Reset(0); dPer.Reset(0);
		for (uint32 ctx = 0; ctx < kTestCtx; ++ctx)
			for (uint32 t = 0; t + 1u < kTime; ++t)
			{
				const uint32 wi = ctx * kTime + t;
				for (uint32 j = 0; j < MLTP4Ctx::kPersist; ++j)
				{
					const uint32 r = MLTP4Ctx::Row(ctx, t, MLTP4Ctx::kOAct2) + j;
					const float tf = _te.Tgt()[r];
					if (!(tf >= 0.0f && tf < (float)kN)) continue;
					const float w = _rows[kArmWhole][r];
					dCut.Add(_rows[kArmActCut][r] - w);
					dPer.Add(_rows[kArmPerCut][r] - w);
					key[0].Add(_wDYaw[wi]);
					key[1].Add(_wANorm[wi]);
					key[2].Add(_wMinD[wi]);
					const uint32 nowId =
						(uint32)(_te.Sym()[r] - (float)(MLTP4Ctx::kStateAx + MLTP4Ctx::kActAx));
					key[3].Add((nowId == (uint32)tf) ? 1.0f : 0.0f);
					key[4].Add((float)t);
				}
			}
		const uint32 n = dCut.Count();
		if (n == 0u)
		{
			for (uint32 s = 0; s < kSplits; ++s) { _sepCut[s][_seed] = 0.0f; _sepPer[s][_seed] = 0.0f; }
			return;
		}
		for (uint32 s = 0; s < kSplits; ++s)
		{
			float mn = key[s][0], mx = key[s][0];
			for (uint32 i = 0; i < n; ++i)
			{ if (key[s][i] < mn) mn = key[s][i]; if (key[s][i] > mx) mx = key[s][i]; }
			const float t1 = _Quant(key[s], n, mn, mx, 1.0f / 3.0f);
			const float t2 = _Quant(key[s], n, mn, mx, 2.0f / 3.0f);
			double loC = 0.0, hiC = 0.0, loP = 0.0, hiP = 0.0;
			uint32 nLo = 0u, nHi = 0u;
			double loH[2] = { 0.0, 0.0 }, hiH[2] = { 0.0, 0.0 };
			uint32 nLoH[2] = { 0u, 0u }, nHiH[2] = { 0u, 0u };
			for (uint32 i = 0; i < n; ++i)
			{
				const uint32 h = i & 1u;
				if (key[s][i] < t1)
				{ loC += (double)dCut[i]; loP += (double)dPer[i]; ++nLo; loH[h] += (double)dCut[i]; ++nLoH[h]; }
				else if (key[s][i] >= t2)
				{ hiC += (double)dCut[i]; hiP += (double)dPer[i]; ++nHi; hiH[h] += (double)dCut[i]; ++nHiH[h]; }
			}
			_sepCut[s][_seed] = (nLo && nHi) ? (float)(hiC / (double)nHi - loC / (double)nLo) : 0.0f;
			_sepPer[s][_seed] = (nLo && nHi) ? (float)(hiP / (double)nHi - loP / (double)nLo) : 0.0f;
			for (uint32 h = 0; h < 2u; ++h)
				_sepHalf[s][h][_seed] = (nLoH[h] && nHiH[h])
					? (float)(hiH[h] / (double)nHiH[h] - loH[h] / (double)nLoH[h]) : 0.0f;
		}
		LogA("[mlt] 🗺️   씨앗 %2u · (회귀) ㉣ 지속 상위−하위 **Δ끊음 %+.5f**(반쪽 %+.5f/%+.5f) · Δ활성끊음 %+.5f\n",
			_seed, (double)_sepCut[3][_seed], (double)_sepHalf[3][0][_seed],
			(double)_sepHalf[3][1][_seed], (double)_sepPer[3][_seed]);
	}

	// 회차 104 의 자 — **회귀 검사**로 그대로 돈다.
	static void _Distribution()
	{
		double sC = 0.0, sR = 0.0, sP = 0.0;
		double qC = 0.0, qR = 0.0, qP = 0.0, xCR = 0.0;
		uint32 n = 0u;
		for (uint32 k = 0; k < kTestPool; ++k)
			for (uint32 b = 0; b < kBatch; ++b)
			{
				const uint32 ctx = k * kBatch + b;
				for (uint32 t = 0; t + 1u < kTime; ++t)
					for (uint32 j = 0; j < MLTP4Ctx::kPersist; ++j)
					{
						const uint32 r = MLTP4Ctx::Row(ctx, t, MLTP4Ctx::kOAct2) + j;
						const float tf = _te.Tgt()[r];
						if (!(tf >= 0.0f && tf < (float)kN)) continue;
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
		LogA("[mlt] 🔀   씨앗 %2u · (회귀) 평균Δ 끊음 %+.5f · 무작위 %+.5f · 활성끊음 %+.5f │ 폭비 **%.4f** · 상관 **%+.4f**\n",
			_seed, mC, mR, mP, (double)_sdRatio[_seed], (double)_corrCut[_seed]);
	}

	static void _Summary()
	{
		double m[kArms], mf = 0.0;
		for (uint32 a = 0; a < kArms; ++a) m[a] = 0.0;
		uint32 ok = 0u, beat = 0u, flat = 0u, gPer = 0u, gWid = 0u, gCor = 0u;
		double mRatio = 0.0, mCorr = 0.0;
		for (uint32 s = 0; s < kSeeds; ++s)
		{
			if (!_seedOk[s]) continue;
			++ok;
			for (uint32 a = 0; a < kArms; ++a) m[a] += _ce[a][s];
			mf += _floorTe[s];
			if (_ce[kArmWhole][s] < _floorTe[s]) ++beat;
			if (Abs(_ce[kArmLr0][s] - _pre0[s]) <= kFlatRel * Abs(_pre0[s])) ++flat;
			if (_ce[kArmPerCut][s] > _ce[kArmWhole][s]) ++gPer;
			if (_sdRatio[s] >= kWidePass) ++gWid;
			if (_corrCut[s] >= kCorrPass) ++gCor;
			mRatio += (double)_sdRatio[s]; mCorr += (double)_corrCut[s];
		}
		if (ok > 0u) { for (uint32 a = 0; a < kArms; ++a) m[a] /= ok; mf /= ok; mRatio /= ok; mCorr /= ok; }

		// ⭐ 회차 107 — 오귀속률
		uint32 gDen = 0u, gHead = 0u, gBack = 0u, gAgree = 0u, gSmall = 0u;
		double mM = 0.0, mA = 0.0, mB = 0.0, mFrac = 0.0;
		double cA = 0.0, cB = 0.0, cC = 0.0, cD = 0.0;
		for (uint32 s = 0; s < kSeeds; ++s)
		{
			if (!_seedOk[s]) continue;
			if (_mCutA[s] > 0.0f) ++gDen;
			if (_mis[s] < kMisPass) ++gHead;
			if (_mis[s] < kMisBack) ++gBack;
			if ((_misH[0][s] < kMisPass) == (_misH[1][s] < kMisPass)) ++gAgree;
			const double nAll = (double)(_cell[0][0][s] + _cell[0][1][s] + _cell[1][0][s] + _cell[1][1][s]);
			if (nAll > 0.0 && (double)_cell[0][0][s] / nAll < (double)kCellMin) ++gSmall;
			mM += (double)_mis[s]; mA += (double)_mCutA[s]; mB += (double)_mCutB[s];
			mFrac += (double)_fracChg[s];
			cA += (double)_cell[0][1][s]; cB += (double)_cell[0][0][s];
			cC += (double)_cell[1][1][s]; cD += (double)_cell[1][0][s];
		}
		if (ok > 0u)
		{ mM /= ok; mA /= ok; mB /= ok; mFrac /= ok; cA /= ok; cB /= ok; cC /= ok; cD /= ok; }

		// ⚠️ 판정 ① 은 **전 씨앗 누산**으로 본다(씨앗별 값은 로그가 이미 찍었다).
		const bool plumb = (flat == ok) && (beat >= kSignPass) && _finite
			&& (gPer >= kSignPass) && (_chkDiffAll == 0u) && (_chkSeenAll > 0u);
		const bool denOk = (gDen == ok) && (ok > 0u);
		const bool bigOk = (gSmall == 0u);

		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🎯 **회차 107 · P4 ㉡ 오귀속률** — 읽은 씨앗 %u/%u\n", ok, kSeeds);
		LogA("[mlt] 🎯   배관 — ㈃ 평탄 %u/%u · ㈀ 이 바닥 넘음 %u/%u · ㈄ 눈금 팔 %u/%u · ⭐ **판정①(`a'=a`) %u칸 중 다른 칸 %u** → %s\n",
			flat, ok, beat, kSeeds, gPer, kSeeds, _chkSeenAll, _chkDiffAll, plumb ? "통과" : "⛔");
		LogA("[mlt] 🎯   평균 CE — 바닥 %.4f · ㈀ %.4f · ㈁ 끊음 %.4f · ㈂ 무작위 %.4f · ㈄ 활성끊음 %.4f\n",
			mf, m[0], m[1], m[2], m[4]);
		LogA("[mlt] 🎯   (회귀) 회차 104 — 폭비 평균 **%.4f**(%u/12 · 눈금 0.1848) · 상관 평균 **%+.4f**(%u/12 · 눈금 +0.5145)\n",
			mRatio, gWid, mCorr, gCor);
		LogA("[mlt] 🎯   ── **2×2 칸**(씨앗 평균 표적 수) — 「가름」 비율 **%.1f%%** ──\n", mFrac * 100.0);
		LogA("[mlt] 🎯     **A 비지속&가름 %.0f**(분모) │ ⭐ **B 비지속&무관 %.0f**(오귀속) │ C 지속&가름 %.0f │ D 지속&무관 %.0f\n",
			cA, cB, cC, cD);
		LogA("[mlt] 🎯     ⚠️ **B 가 전체의 %.0f%% 미만인 씨앗 %u** → %s\n",
			(double)(kCellMin * 100.0f), gSmall, bigOk ? "✅ 자가 선다" : "⛔ 자가 못 선다");
		LogA("[mlt] 🎯   ⭐ **분모 관문** — `평균Δ끊음(A) > 0` **%u/%u**(필요 %u = 전부) · 평균 **%+.5f** → %s\n",
			gDen, ok, ok, mA, denOk ? "✅" : "⛔");
		LogA("[mlt] 🎯   평균Δ끊음 — A(분모) **%+.5f** · B(오귀속) **%+.5f**\n", mA, mB);
		LogA("[mlt] 🎯   📏 잡음(규율 9) — 칸 %.0f 개면 `sd(칸평균) ≈ %.4f` ⇒ `sd(M)` 은 그 둘의 전파다(등록문 ≈0.17)\n",
			(cA + cB) * 0.5, 0.212 / Sqrt((float)((cA + cB) * 0.5 + 1.0)));
		LogA("[mlt] 🎯   **⭐ 표제 — 오귀속률 `M = Δ(B)/Δ(A)`** 평균 **%+.4f** · `< %.2f` 인 씨앗 **%u/%u**(필요 %u) → %s\n",
			mM, (double)kMisPass, gHead, kSeeds, kSignPass, (gHead >= kSignPass) ? "✅" : "⛔");
		LogA("[mlt] 🎯   **⭐ 후퇴선**(미리 등록 · 표제 아님) — `M < %.2f` **%u/%u** → %s\n",
			(double)kMisBack, gBack, kSeeds, (gBack >= kSignPass) ? "✅" : "⛔");
		LogA("[mlt] 🎯   **⭐ 분할 반쪽** — 두 반쪽이 같은 판정을 내는 씨앗 **%u/%u**(⚠️ 문턱 없음 — 진단이다)\n",
			gAgree, kSeeds);

		if (!plumb)
			LogA("[mlt] 🎯   ⭐ 판정 = ⛔ **판정불가** — 배관이 안 섰다(평탄/바닥/눈금/**판정①**)\n");
		else if (!bigOk)
			LogA("[mlt] 🎯   ⭐ 판정 = ⛔ **판정불가** — **B 칸이 너무 작다**(자가 못 선다) ⇒ `a'` 를 **약하게** 만들어 「무관」을 늘린다\n");
		else if (!denOk)
			LogA("[mlt] 🎯   ⭐ 판정 = ⛔ **판정불가** — **분모가 안 선다**(행동이 정한 곳에서도 안 읽는다 · 규율 16)\n");
		else if (gHead >= kSignPass)
			LogA("[mlt] 🎯   ⭐ 판정 = ⭐ ***오귀속이 낮다*** — **P4 의 마지막 관문이 섰다** ⇒ P4 를 닫고 **P5** 로\n");
		else if (gBack >= kSignPass)
			LogA("[mlt] 🎯   ⭐ 판정 = ⭐ **방향은 맞고 크기가 모자라다** — 오귀속률의 **상한을 `%+.4f` 로 보고**한다(규율 26)\n", mM);
		else
			LogA("[mlt] 🎯   ⭐ 판정 = ⭐ ***오귀속이 있다*** — ⚠️ **P5 를 열면 안 된다**(P5 의 공학 조건) ⇒ 세계·표적을 고친다\n");
		LogA("[mlt] 🎯   ⚠️ 고정 %u문맥 · 채점 표적 %u개의 진단이다 — 절대 성능으로 인용하지 않는다\n",
			kNCtx, kTestCtx * (kTime - 1u) * MLTP4Ctx::kPersist);
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		_E.Destroy(); _done = true;
	}

	static void _Fail(const char* why)
	{
		LogA("[mlt] 🎯 ⛔ %s (씨앗 %u · 코퍼스 %u · 그룹 %u · 패스 %u · 팔 %u · 반복 %u · 단계 %u)\n",
			why, _seed, _cor, _gGrp, _gPass, _arm, _rep, _st);
		_E.Destroy(); _done = true;
	}
};
