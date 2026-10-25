// mltp3d3.cw — 📉 회차 122 · **B1: P 를 「어떻게 죽나」로 판정한다** (`-mltp3d3`) ⭐ **판정 회차**
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 122 다.** ⭐ **하네스보다 먼저 썼다.**
//   **상위 캔버스: `P 를 「어떻게 죽나」로 판정한다` · 122~ = 1회차**(규율 33 · L0 에서 바뀌었다).
//   ⭐ **회차 74 부터 열린 부채 D1** — 컨셉이 **P 의 성공 조건**으로 못박은 유일한 미해결.
//
// ── ⚠️ 컨셉이 요구한 자의 **정확한 형태**(원문을 다시 읽고 옮겼다) ──────────
//   > *"무작위는 **경우의 수에 비례해서** 죽는다 · 학습이 **비례보다 느리게** 죽으면 기능 역할은 한다"*
//   > *"⚠️ 한 점으로는 아무 말도 못 한다 — **최소 세 점**"*
//   > *"기록은 차가 아니라 **배율**로. ⚠️ 단 배율만 보면 안 된다 ⇒ ***판정은 두 감소 속도의 비***"*
//   ⇒ ⭐ **표제는 「넘었나」가 아니라 「기울기의 비」다.**
//
// ── ⚠️⚠️ **1차 시도(전환율)는 진단에서 실패했다** — 그 기록을 남긴다 ────────
//   `MLTWorldCfg` 가 *"③ 난이도 = 전환율"* 이라 적었고 컨셉도 그것을 물려받았다. 그런데
//   **복사바닥이 단조가 아니었다**(씨앗 2 진단 · **0/2**):
//     씨앗0 `1.0473 → 1.0673 → 1.0396`(오르다 내린다) · 씨앗1 `1.5834 → 1.5177 → 1.5832`
//   ★ 기제: `hold↑` 면 카메라가 **한 방향으로 멀리 표류**해 화면이 크게 바뀌고,
//     `hold↓` 면 **제자리에서 흔들려** 덜 바뀐다 ⇒ ⭐ **두 효과가 반대로 싸운다.**
//   ⚠️⚠️ **회차 114 가 이미 그것을 봤다**(*"hold=1 은 표류 대신 제자리 흔들림이라 오히려 쉽다"*)
//     — **적어 놓고 이 회차 설계에 안 썼다.** ⇒ ★ **규율 35**: 「난이도 축」은 **선언이 아니라 실측**이다.
//
// ── 🔬 설계(2차) — ⭐ **축을 `kN`(사전 크기)으로** ────────────────────
//   ★ 표적이 **`N` 개 중 하나**이므로 ***「경우의 수」가 문자 그대로 `N`*** 이고,
//     무작위 바닥이 **`ln N` 으로 정확히 비례해서** 죽는다 — 컨셉의 그 문장 그대로다.
//   세 점 = **64 / 250 / 1000**(⚠️ 250 은 지금까지 모든 회차가 쓴 한 점 ⇒ 가운데).
//   ```
//   점마다  ⓐ 복사바닥(= 무작위/관성이 죽는 속도)  ⓑ 학습 CE(= 학습이 죽는 속도)
//   ⭐ 표제 = **기울기의 비** `r = slope(ⓑ)/slope(ⓐ)`(축 = `ln N`)
//        `r < 1` 이면 **비례보다 느리게 죽는다** = 컨셉이 「기능 역할」이라 부른 것
//   ```
//   ⚠️ **씨앗 안에서 세 점을 다 돈다** ⇒ 씨앗 잡음이 **기울기 안에서 상쇄**된다(규율 32).
//   ⚠️⚠️ **사전이 곧 표현이라 팔마다 인코더를 새로 학습한다** — 그래서 이 회차는
//     *"같은 표현에서 난이도만"* 이 아니라 ***"각 경우의 수에서 각자 최선으로 배운 뒤
//     죽는 속도를 견주는 것"*** 이다(⭐ 컨셉이 요구한 형태 그대로).
//
// ── ✅ 관문 ───────────────────────────────────────────────────────────────
//   **배관** 유한 · ⭐ **단조 관문**(축을 따라 복사바닥이 **단조** · ⚠️ **방향 무관** · 규율 16) — 전부
//   ⭐ **표제** `r̄ < 1` 그리고 `|1−r̄|/SE ≥ 3`
//
// ── ⭐ 예측 ──────────────────────────────────────────────────────────────
//   ⚠️ **최근 열 중 다섯을 틀렸다.**
//   · 단조 관문 통과 · ⭐ **`r < 1`** 로 예측(회차 85b 가 `바닥 1.054 → CE 0.878` 을 세웠고
//     **쉬운 세계에서는 복사가 강해 이득이 작을 것**이므로 기울기가 완만해야 한다)
//   · ⚠️ **뒤집힐 근거**: 어려운 세계에서 학습이 **더 크게 무너지면** `r > 1` ⇒ ⭐ 그러면
//     ***"기능 역할이 아니라 복사의 그림자였다"*** 가 되고 **P 전체의 판정이 바뀐다**
//   · ⭐ **어느 쪽이든 값이 크다** — 컨셉이 「P 의 성공」이라 부른 그 자다.
//
// ── (아래는 회차 85a 의 머리말 원문 — 배관·자의 계보) ─────────────────────
//
// ══════════════════════════════════════════════════════════════════════════════
// mltp3f2.cw — ⏳ 회차 85a · **㉠ 을 512 문맥으로 재판정** — ⭐ 회차 83 과 `kNCtx` **128→512** 만 다르다
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 83 이다.** ⭐ **하네스보다 먼저 썼다.**
// ⭐ **회차 59 와 한 글자만 다르다: `kTestEpi` 101 → 901.**
//
// ⚠️⚠️ 회차 82 가 **㉡′(회차 60)을 무너뜨렸다** — 깨끗한 시험에서 `㈁>㈀` 이 **12/12 → 7/12**.
//   ㉠(회차 59)도 **같은 누출 대역(101)** 을 썼으므로 **다시 재야 한다**.
//
// ⭐ **미리 적은 예측**(회차 82 의 「효과가 작을수록 위험하다」에서):
//   회차 59 의 효과 — `㈁ 상수0` **+0.167** · `㈂ 무작위` **+0.119**
//   ⇒ ⚠️ ***㈂ 가 더 작으므로 ㈂ 가 먼저 무너져야 한다.***
//   ⚠️⚠️ 그런데 회차 82 에서는 **㈂(효과 큰 쪽)가 살아남고 ㈁(작은 쪽)이 무너졌다** ⇒ 규칙과 맞다.
//   ⇒ ★ 이 회차가 그 규칙을 **한 번 더** 시험한다.
// ══════════════════════════════════════════════════════════════════════════════
//
// ── (아래는 회차 59 의 머리말 원문) ──────────────────────────────────────
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 59 이다.**
// ⭐ 상위 캔버스가 **새것**이다: **잡음을 이기는 판정 형식**.
//   ⚠️ 닫은 캔버스(*"몸통이 다음 활성을 예측하나"*)의 넷째가 아니다 — 회차 58 이 못 넘은 것은
//     **표제가 아니라 위생**이었고, 남은 물음은 한 층 위다: ***"우리 자가 이 잡음을 이길 수 있나?"***
//   ⇒ **이 회차의 표제는 자(형식)이고, ㉠ 은 자가 통과했을 때만 읽는 부산물이다.**
// ══════════════════════════════════════════════════════════════════════════════
//
// ⛔ **최빈값은 죽었다** — 회차 58 이 두 번 다 **최빈빈도 30.6%** 를 냈다(문턱 90%).
// ⭐ **대신 회차 58 이 우연히 보인 것을 미리 등록한다** — 두 **독립 실행**이 같은 결론을 냈다
//   (`㈀ 0.8747↔0.8782` · 표제 `12/12·12/12 ↔ 11/12·12/12`) ⇒ *"오염은 무작위라 평균에서 씻긴다"*.
//   그것을 **한 실행 안에서** 재는 형식이 **분할 반쪽**이다:
//     `R = 6` · 씨앗값 = **6회 평균** · 반쪽 A = 반복 0·2·4 · 반쪽 B = 반복 1·3·5
//     ⇒ 두 반쪽이 **서로 독립 추정**이고, **둘이 각각 같은 결론**을 내면 그 자는 잡음을 이긴 것이다.
//
// ⚠️ 바뀌는 것은 **`R` 과 집계뿐**이다 — 128문맥·800스텝·id 정렬·앵커 없음·팔 넷은 회차 58 그대로.
//   ㈃(`lr=0`)만 `R=1`(갱신이 0이라 평탄성은 결정적이다).

using namespace PE;

class MLTP3D3
{
public:
	static void Tick(RHI* rhi)
	{
		if (_done || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltp3d3"))
		{
			LogA("[mlt] 📉 회차 122(B1 · P 를 「어떻게 죽나」로)는 **꺼져 있다**(`-mltp3d3`)\n");
			_done = true; return;
		}
		if (!_banner) { _Banner(); _banner = true; }
		if (_seed >= kSeeds) { _Summary(); return; }
		if (_st == kEncInit)  { _EncBegin(rhi); return; }
		if (_st == kEncTrain) { _EncTrain(); return; }
		if (_st == kGather)   { _Gather(); return; }
		// ⭐ **배관 고침(2026-08-26)** — 반복 사이에 **틱을 비운다**.
		//   ⚠️ 이 엔진은 dispatch 를 `computeCb[frame]` 에 **누적만** 하고 제출은 Present 에서 1회다
		//     (`RHIBuffer_Vulkan.cpp` 의 그 ⚠️⚠️⚠️). 그래서 `Setup`/`UploadPool` 이 곧바로 오면
		//     **아직 제출도 안 된 앞 반복의 디스패치**가 그 버퍼를 나중에 읽는다 ⇒ 엉뚱한 데이터로 학습.
		//   ★ 회차 59 1차가 그 얼굴이다: 오염률이 회차 56(업로드 8회)의 25% 에서 **업로드 240회**일 때
		//     크게 뛰었다(최빈빈도 `≥3/5` 가 30.6%).
		//   ⇒ 고침은 리드백이 아니라 **틱을 넘기는 것**이다(제출은 Present 가 한다).
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
	// ⭐ 씨앗 2 진단을 **두 번** 돌렸다: ㈀ 전환율 축 ⛔(단조 아님) → ㈁ `kN` 축 ✅(단조 · **내려간다**)
	//   ⇒ ★ 이제 **판정용 12씨앗**.
	static constexpr uint32 kSeeds = 12u;
	static constexpr uint32 kEncF = 32u, kEncSteps = 1200u, kEncPerTick = 8u;
	// ⚠️ `kN`(사전 크기)은 **회차 122 에서 팔마다 바뀐다** ⇒ `constexpr` 이 아니다(아래 `kDicts`).
	static constexpr uint32 kLocal = 8u;
	static constexpr uint32 kTime = MLTP3Ctx::kTime;
	static constexpr uint32 kBatch = MLTP3Ctx::kBatch;
	static constexpr uint32 kCandidates = MLTP2Cfg::kPatches * kLocal;
	static constexpr uint32 kNCtx = 512u, kTestCtx = 64u;      // ⭐ 회차 52 의 ㈁ 팔
	// ⭐ **회차 83 이 고친 유일한 것** — `kTestEpi` 101 → **901**(회차 59 는 누출 대역이었다).
	static constexpr uint32 kTrainEpi = 1u, kTestEpi = 901u;
	static_assert(kTestEpi >= kTrainEpi + kNCtx,
		"시험 에피소드가 학습과 겹친다 — kTestEpi >= kTrainEpi + kNCtx 여야 한다(규율 12)");
	static constexpr uint32 kPoolSteps = kNCtx / kBatch, kTestPool = kTestCtx / kBatch;
	static constexpr uint32 kGroup = kEncF / kTime;
	static constexpr uint32 kSteps = 800u, kPerTick = 4u;      // 에폭 50
	// ⭐ **회차 122 — 팔이 「절제」가 아니라 「세계 난이도 세 점」이다**
	//   ⚠️ 컨셉: *"한 점으로는 아무 말도 못 한다 — **최소 세 점**"* · *"난이도는 ③ 전환율"*
	//   ★ 세계에 그 축이 **이미 있다**(새 상수 0개):
	//     `kHoldEasy 12`(복사가 강하다) · `kHoldMid 5`(지금까지 **모든 회차가 쓴 한 점**) · `kHoldHard 2`
	static constexpr uint32 kArms = 3u, kRep = 6u;   // ⭐ 짝수 — 분할 반쪽(회차 59)
	// ⚠️⚠️ **1차 시도(전환율)는 실패했다** — 복사바닥이 **단조가 아니었다**(회차 122 진단 0/2).
	//   기제: `hold↑` 면 카메라가 **멀리 표류**해 화면이 크게 바뀌고, `hold↓` 면 **제자리 흔들림**이라
	//   덜 바뀐다 ⇒ **두 효과가 반대로 싸운다**(회차 114 가 이미 봤다 — 그때 안 읽고 설계했다).
	//   ⇒ ★ **규율 35**: 「난이도 축」은 **선언이 아니라 실측**이다.
	// ⭐ **2차 — 축을 `kN`(사전 크기)으로 바꾼다.**
	//   ★ 표적이 **`N` 개 중 하나**이므로 ***「경우의 수」가 문자 그대로 `N`*** 이고,
	//     무작위 바닥이 **`ln N` 으로 정확히 비례해서** 죽는다(컨셉의 그 문장 그대로).
	//   ⚠️ 250 은 **지금까지 모든 회차가 쓴 한 점**이다(가운데에 둔다).
	static constexpr uint32 kDicts[kArms] = { 64u, 250u, 1000u };
	inline static uint32 kN = kDicts[0];               // ⚠️ 팔마다 바뀐다(`_EncBegin` 이 세운다)
	// ⭐ 「경우의 수」 축 — `ln N`(무작위 바닥이 정확히 이것이다)
	static float _Diff(uint32 a) { return Log((float)kDicts[a]); }
	static constexpr uint32 kSignPass = (kSeeds * 10u + 11u) / 12u;   // ⚠️ 씨앗 수에 비례(회차 121)
	static constexpr float  kFlatRel = 1.0e-6f;
	// 회차 58 재현 문턱(1차 0.8747·2차 0.8782 / 1.0562·1.0507 / 0.9956·1.0126)
	static constexpr float  kR58A = 0.876f, kR58B = 1.053f, kR58C = 1.004f;
	static constexpr float  kTolA = 0.02f, kTolC = 0.03f;

	enum { kEncInit, kEncTrain, kGather, kQuiesce, kBodyInit, kBodyTrain, kBodyEval };

	inline static MLTP2Enc _E;
	inline static MLTModel _M;
	inline static MLTP3Ctx _tr, _te;
	inline static MLTEvalGate _gate;
	inline static bool _done = false, _banner = false, _encSetup = false, _finite = true;
	inline static bool _pending = false, _pre = false;
	inline static uint32 _seed = 0u, _st = kEncInit, _step = 0u, _arm = 0u, _rep = 0u;
	inline static uint32 _cor = 0u, _gGrp = 0u, _gIdx = 0u;
	inline static Array<float> _code, _norm;
	inline static float _run[kRep];                    // 이 (씨앗,팔)의 반복별 시험 CE
	inline static float _ce[kArms][kSeeds];            // 최빈값
	inline static float _ceA[kArms][kSeeds], _ceB[kArms][kSeeds];   // 분할 반쪽
	inline static float _pre0[kSeeds];                 // ㈃ 의 학습 전 CE(평탄성)
	inline static float _floorTe[kSeeds];
	// ⭐ 회차 122 — 복사바닥이 **난이도마다** 다르다(표제의 분모)
	inline static float _floorArm[kArms][kSeeds];
	inline static bool  _seedOk[kSeeds];

	inline static uint32 _qWait = 0u;
	// ⭐ 몸통을 새로 세우기 전에 **틱을 비운다**(위 배관 고침의 그 자리).
	static void _ToBody() { _qWait = MLTEvalGate::kDelay; _st = kQuiesce; }

	// ⚠️ **회차 122 는 `lr=0` 팔이 없다**(팔이 절제가 아니라 난이도다) ⇒ 반복은 늘 `kRep`.
	static uint32 _Reps() { return kRep; }
	static const char* _ArmName()
	{
		return (_arm == 0u) ? "㈀ N=64" : ((_arm == 1u) ? "㈁ N=250" : "㈂ N=1000");
	}

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 📉 **회차 122 · B1 — P 를 「어떻게 죽나」로 판정한다**(씨앗 %u · 난이도 **세 점**)\n", kSeeds);
		LogA("[mlt] 📉   ⭐ **회차 74 부터 열린 부채 D1** — 컨셉이 **P 의 성공 조건**으로 못박은 유일한 미해결\n");
		LogA("[mlt] 📉   ⚠️ 컨셉: *\"한 점으로는 아무 말도 못 한다 — **최소 세 점**\"* · *\"판정은 **두 감소 속도의 비**\"*\n");
		LogA("[mlt] 📉   ⚠️⚠️ **1차(전환율)는 실패했다** — 복사바닥이 **단조가 아니었다**(진단 0/2 · 규율 35)\n");
		LogA("[mlt] 📉     기제: `hold↑` 면 카메라가 **멀리 표류**(화면 크게 변함) · `hold↓` 면 **제자리 흔들림** ⇒ **반대로 싸운다**\n");
		LogA("[mlt] 📉   ⭐ **2차 — 축을 `kN`(사전 크기)으로**: %u / %u / %u\n",
			kDicts[0], kDicts[1], kDicts[2]);
		LogA("[mlt] 📉     ★ 표적이 **N 개 중 하나**라 ***「경우의 수」가 문자 그대로 N*** 이고 무작위 바닥이 **`ln N` 으로 정확히 비례**해 죽는다\n");
		LogA("[mlt] 📉   ⭐ **표제 = 기울기 비 `r = slope(CE)/slope(바닥)`**(축 = `ln N`) · `r<1` 이면 **비례보다 느리게 죽는다**\n");
		LogA("[mlt] 📉   ⭐ **단조 관문**(축을 따라 바닥이 단조 · **방향 무관**) 없으면 판정불가 · ⚠️ 팔마다 **인코더를 새로**(사전이 곧 표현이다)\n");
		LogA("[mlt] 📉   ⭐ **예측** — 단조 통과 · **`r<1`** · ⚠️ 뒤집히면 ***\"기능 역할이 아니라 복사의 그림자\"*** 가 된다\n");
		LogA("[mlt] ⏳   %u문맥 · %u스텝 · id 정렬 · 팔 넷 — 회차 58 과 **집계만** 다르다(R=%u · **평균 + 분할 반쪽**)\n",
			kNCtx, kSteps, kRep);
		LogA("[mlt] ⏳   표제① **분할 반쪽 일치**(A·B 가 각각 %u/%u) · 표제② 회차 58 재현 · ㉠ 은 **부산물**\n",
			kSignPass, kSeeds);
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

	static void _EncBegin(RHI* rhi)
	{
		// ⭐ **회차 122** — 팔이 **사전 크기**다 ⇒ 팔이 바뀌면 인코더를 **새로 만든다**.
		kN = kDicts[_arm];
		if (!_encSetup)
		{
			_E.Destroy();                    // ⚠️ 이전 팔의 아레나를 놓는다(크기가 다르다)
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
		_cor = 0u; _gGrp = 0u; _gIdx = 0u; _pending = false; _st = kGather;
	}

	static void _Gather()
	{
		MLTP3Ctx& C = (_cor == 0u) ? _tr : _te;
		const uint32 nCtx = (_cor == 0u) ? kNCtx : kTestCtx;
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
			const uint32 epi = (_cor == 0u) ? kTrainEpi : kTestEpi;
			for (uint32 g = 0; g < kGroup; ++g)
			{
				const uint32 ctx = _gGrp * kGroup + g;
				// ⭐ **회차 122 의 유일한 세계 변경** — 팔이 곧 **난이도(전환율)** 다.
				//   ⚠️ 인코더는 `_EncBegin` 이 `kHoldMid` 로 **한 번만** 학습한다 = **세 점이 같은 사전**(대조).
				MLTWorld w; w.Reset(_seed, epi + ctx, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
				for (uint32 t = 0; t < kTime; ++t)
				{
					w.Step();
					if (!w.Render(bmp) || !MLTWorld::Pack(bmp, nullptr, packed)) { _Fail("Render/Pack(문맥)"); return; }
					MLTP2Enc::AppendFrame(fr, tg, (const uint8*)packed.GetData());
					C.StoreState(ctx, t, w.State());
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
		if (++_gGrp * kGroup >= nCtx)
		{
			_gGrp = 0u;
			if (++_cor >= 2u)
			{
				// 시험 복사 바닥(위생 3) — ⚠️ λ·M 은 **학습 코퍼스**에서 고른다.
				Array<float> marg; _tr.Marginal(marg);
				float c1 = 0.0f, c2 = 0.0f, l1 = 0.0f, l2 = 0.0f;
				_tr.BestCopy(marg, c1, c2, l1, l2);
				const float t1 = (float)_te.CeCopy(marg, l1, false);
				const float t2 = (float)_te.CeCopy(marg, l2, true);
				// ⭐ **회차 122** — 복사바닥이 **팔(난이도)마다** 다르다. 그것이 표제의 **분모**다
				//   (= 「무작위/관성이 죽는 속도」).
				_floorTe[_seed] = (t1 < t2) ? t1 : t2;
				_floorArm[_arm][_seed] = _floorTe[_seed];
				LogA("[mlt] 📉 씨앗 %2u · **N=%u**(축 lnN %.3f) 시험 복사바닥 **%.4f**\n",
					_seed, kN, (double)_Diff(_arm), (double)_floorTe[_seed]);
				_rep = 0u; _ToBody();
			}
		}
	}

	static void _BodyBegin(RHI* rhi)
	{
		if (!_M.Setup(rhi, MLTP3Ctx::kStateAx + kN, kN, MLTP3Ctx::kAxes, kTime)) { _Fail("몸통 준비"); return; }
		// ⭐ **회차 122 는 값을 절제하지 않는다** — 팔이 **난이도**이므로 세 점 다 **온전**이다.
		//   ⚠️ 다른 것은 **사전 크기 `N`** 이다(인코더가 팔마다 새로 학습됐다).
		Array<float> v; v.Reset(0);
		const uint32 n = kPoolSteps * MLTP3Ctx::kRows;
		for (uint32 i = 0; i < n; ++i) v.Add(_tr.Val()[i]);
		if (!_M.UploadPool(v, _tr.Tgt(), kPoolSteps) || !_M.UploadSymbolPool(_tr.Sym(), kPoolSteps))
		{ _Fail("학습 풀 업로드"); return; }
		_step = 0u;
		// ㈃ 는 학습 **전** CE 를 먼저 잡는다(평탄성).
		// ⚠️ 회차 122 는 `lr=0` 팔이 없다(팔이 난이도다) ⇒ 학습 전 CE 를 안 잰다.
		_pre = false; _st = kBodyTrain;
	}

	static bool _SwitchToTest()
	{
		if (!_M.UploadPool(_te.Val(), _te.Tgt(), kTestPool) || !_M.UploadSymbolPool(_te.Sym(), kTestPool))
		{ _Fail("시험 풀 업로드"); return false; }
		_gate.Begin(kTestPool); _st = kBodyEval;
		return true;
	}

	static void _BodyTrain()
	{
		if (_step >= kSteps) { _SwitchToTest(); return; }
		for (uint32 i = 0; i < kPerTick && _step < kSteps; ++i)
		{
			_M.SelectStep(_step % kPoolSteps);
			// ⚠️ 회차 122 는 **세 점 다 온전히 학습**한다(`lr=0` 팔이 없다).
			if (!_M.Forward() || !_M.Backward() || !_M.AdamStep(1.0f))
			{ _Fail("몸통 스텝"); return; }
			++_step;
		}
	}

	static void _BodyEval()
	{
		bool fail = false;
		if (!_gate.Step(_M, fail)) return;
		if (fail) { _Fail("평가 게이트"); return; }
		if (!_gate.Finite()) _finite = false;
		const float ce = _gate.Mean();
		if (_pre)
		{
			// ㈃ 의 학습 전 CE — 학습 풀로 되돌리고 학습을 시작한다.
			_pre0[_seed] = ce; _pre = false;
			if (!_M.UploadPool(_tr.Val(), _tr.Tgt(), kPoolSteps) || !_M.UploadSymbolPool(_tr.Sym(), kPoolSteps))
			{ _Fail("학습 풀 복귀"); return; }
			_step = 0u; _st = kBodyTrain; return;
		}
		_run[_rep] = ce;
		if (++_rep < _Reps()) { _ToBody(); return; }
		_Mode();
	}

	// ⭐ **평균 + 분할 반쪽**(회차 59) — ⚠️ 최빈값은 회차 58 이 죽였다(빈도 30.6%).
	//   회차 58 의 **두 독립 실행이 같은 결론**을 냈다 ⇒ *"오염은 무작위라 평균에서 씻긴다"*.
	//   그것을 **한 실행 안에서 미리 등록해 검증**하는 형식이 **분할 반쪽**이다:
	//     반쪽 A = 반복 0·2·4 의 평균 · 반쪽 B = 반복 1·3·5 의 평균 ⇒ 서로 **독립 추정**이다.
	static void _Mode()
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
		LogA("[mlt] ⏳   %s 씨앗 %2u · 평균 CE **%.5f**(반쪽 A %.5f · B %.5f · R=%u)\n",
			_ArmName(), _seed, (double)_ce[_arm][_seed],
			(double)_ceA[_arm][_seed], (double)_ceB[_arm][_seed], R);
		_rep = 0u;
		// ⭐ **회차 122** — 팔이 **사전 크기 `N`** 이라 **인코더부터** 다시 세운다.
		//   ⚠️ 사전이 곧 표현이므로 **같은 사전을 쓸 수 없다**(전환율 축이었을 때와 다르다).
		//   ★ 그래서 이 회차는 *"같은 표현에서 난이도만"* 이 아니라
		//     ***"각 경우의 수에서 각자 최선으로 배운 뒤 죽는 속도를 견주는 것"*** 이다
		//     — ⭐ 컨셉의 *"무작위는 경우의 수에 비례해 죽는다"* 가 요구하는 형태 그대로다.
		if (++_arm < kArms)
		{
			_encSetup = false;              // ⚠️ 사전 크기가 바뀐다 ⇒ 인코더를 새로 만든다
			_st = kEncInit; return;
		}
		_arm = 0u;
		_encSetup = false;                  // ⚠️ 다음 씨앗은 팔 0(사전 64)부터 ⇒ 다시 만든다
		_seedOk[_seed] = _finite;
		++_seed; _st = kEncInit;
	}

	// ══════════════════════════════════════════════════════════════════
	// ⭐ 씨앗 안에서 **난이도 축에 대한 선형 기울기**를 낸다(최소제곱 · 세 점).
	// ══════════════════════════════════════════════════════════════════
	static double _Slope(const float* y, uint32 s, uint32 stride)
	{
		double sx = 0.0, sy = 0.0, sxx = 0.0, sxy = 0.0;
		for (uint32 a = 0; a < kArms; ++a)
		{
			const double x = (double)_Diff(a), v = (double)y[a * stride + s];
			sx += x; sy += v; sxx += x * x; sxy += x * v;
		}
		const double n = (double)kArms;
		const double den = n * sxx - sx * sx;
		return (Abs((float)den) < 1.0e-12f) ? 0.0 : ((n * sxy - sx * sy) / den);
	}

	static void _Summary()
	{
		double m[kArms], mfa[kArms];
		for (uint32 a = 0; a < kArms; ++a) { m[a] = 0.0; mfa[a] = 0.0; }
		uint32 ok = 0u, mono = 0u, beat = 0u, rLess = 0u;
		double rs = 0.0; double rv[kSeeds];
		for (uint32 s = 0; s < kSeeds; ++s)
		{
			if (!_seedOk[s]) continue;
			for (uint32 a = 0; a < kArms; ++a) { m[a] += _ce[a][s]; mfa[a] += _floorArm[a][s]; }
			// ⭐ 단조 관문 — 축을 따라 **복사바닥이 단조로 움직이나**(ⓐ 가 실제로 축인가)
			//   ⚠️⚠️ **방향을 「오른다」로 걸었던 것이 틀렸다**(회차 122 v2 진단):
			//     `N` 이 커지면 사전이 세밀해 **활성이 더 잘 지속**되고 **복사가 더 잘 맞는다**
			//     ⇒ 바닥이 **내려간다**(1.256 → 1.067 → 0.802). ★ 실측이 방향을 정한다(규율 35).
			//   ⇒ ★ 관문은 **단조이기만 하면 된다**(오르든 내리든) — 기울기의 비는 부호에 무관하다.
			if ((_floorArm[0][s] > _floorArm[1][s] && _floorArm[1][s] > _floorArm[2][s])
				|| (_floorArm[0][s] < _floorArm[1][s] && _floorArm[1][s] < _floorArm[2][s])) ++mono;
			// 보고 — 세 점 다 바닥을 넘나
			if (_ce[0][s] < _floorArm[0][s] && _ce[1][s] < _floorArm[1][s]
				&& _ce[2][s] < _floorArm[2][s]) ++beat;
			// ⭐ 표제 — **기울기의 비** `r = slope(CE) / slope(바닥)`
			const double sC = _Slope(&_ce[0][0], s, kSeeds);
			const double sF = _Slope(&_floorArm[0][0], s, kSeeds);
			const double r = (Abs((float)sF) < 1.0e-9f) ? 1.0e9 : (sC / sF);
			rv[ok] = r; rs += r; if (r < 1.0) ++rLess;
			LogA("[mlt] 📉   씨앗 %2u — 바닥 %.4f/%.4f/%.4f │ CE %.4f/%.4f/%.4f │ 기울기 %+.3f / %+.3f ⇒ **r = %+.3f**\n",
				s, (double)_floorArm[0][s], (double)_floorArm[1][s], (double)_floorArm[2][s],
				(double)_ce[0][s], (double)_ce[1][s], (double)_ce[2][s], sC, sF, r);
			++ok;
		}
		if (ok > 0u)
		{ for (uint32 a = 0; a < kArms; ++a) { m[a] /= ok; mfa[a] /= ok; } rs /= (double)ok; }
		double vv = 0.0;
		for (uint32 i = 0; i < ok; ++i) { const double d = rv[i] - rs; vv += d * d; }
		const double rsd = (ok > 1u) ? Sqrt((float)(vv / (double)(ok - 1u))) : 0.0;
		const double rse = (ok > 0u) ? (rsd / Sqrt((float)ok)) : 0.0;
		const double tt = (rse > 1.0e-12) ? (Abs(1.0 - rs) / rse) : 0.0;
		const bool plumb = _finite && (ok > 0u);
		const bool monoOk = (mono == ok) && (ok > 0u);

		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 📉 **회차 122 · B1 — P 를 「어떻게 죽나」로 판정한다**(씨앗 %u · 난이도 세 점)\n", ok);
		LogA("[mlt] 📉   ⚠️ 컨셉: *\"한 점으로는 아무 말도 못 한다 — 최소 세 점\"* · *\"판정은 **두 감소 속도의 비**\"*\n");
		LogA("[mlt] 📉   난이도(전환율) — 쉬움 %.3f(hold %d) · 중간 %.3f(hold %d) · 어려움 %.3f(hold %d)\n",
			(double)_Diff(0), kDicts[0], (double)_Diff(1), kDicts[1], (double)_Diff(2), kDicts[2]);
		LogA("[mlt] 📉   평균 복사바닥 — **%.4f / %.4f / %.4f**\n", mfa[0], mfa[1], mfa[2]);
		LogA("[mlt] 📉   평균 학습 CE — **%.4f / %.4f / %.4f**(이득 %+.4f / %+.4f / %+.4f)\n",
			m[0], m[1], m[2], mfa[0] - m[0], mfa[1] - m[1], mfa[2] - m[2]);
		LogA("[mlt] 📉   ⭐ **단조 관문**(축을 따라 바닥이 **단조** · ⚠️ 방향 무관) — **%u/%u** → %s\n",
			mono, ok, monoOk ? "✅" : "⛔ **축이 아니다**");
		LogA("[mlt] 📉   (보고) 세 점 다 바닥을 넘음 **%u/%u** · 유한 %s\n", beat, ok, _finite ? "✅" : "⛔");
		LogA("[mlt] 📉   ⭐ **표제 — 기울기 비 `r = slope(CE)/slope(바닥)`** 평균 **%+.4f** · sd %.4f · **SE %.4f**\n",
			rs, rsd, rse);
		LogA("[mlt] 📉     ⇒ ⭐ **|1−r̄|/SE = %.2f**(필요 3) · `r<1` 인 씨앗 **%u/%u**\n", tt, rLess, ok);
		if (!plumb)
			LogA("[mlt] 📉   ⭐ 판정 = ⛔ **판정불가** — 유한하지 않다\n");
		else if (!monoOk)
			LogA("[mlt] 📉   ⭐ 판정 = ⛔ **판정불가** — **단조 관문이 안 섰다**(그 축이 경우의 수 축이 아니다 · 규율 16)\n");
		else if (tt >= 3.0 && rs < 1.0)
			LogA("[mlt] 📉   ⭐ 판정 = ⭐ ***학습이 비례보다 느리게 죽는다*** — 컨셉이 **「P 의 성공」**이라 부른 그것\n"
			     "[mlt] 📉      ⇒ **회차 74 부터의 부채 D1 을 갚았다** · 크기 `r = %+.4f ± %.4f`\n", rs, rse);
		else if (tt >= 3.0)
			LogA("[mlt] 📉   ⭐ 판정 = ⚠️⚠️ ***학습이 비례보다 **빨리** 죽는다***(`r = %+.4f > 1`) ⇒ **P 의 판정이 바뀐다**\n"
			     "[mlt] 📉      ⇒ ★ *\"기능 역할이 아니라 복사의 그림자였다\"* — ⚠️ 큰 결론이므로 재현을 먼저 본다\n", rs);
		else
			LogA("[mlt] 📉   ⭐ 판정 = ⭐ ***비례와 구별되지 않는다*** (|1−r̄| < %.4f)\n"
			     "[mlt] 📉      ⇒ ⭐ **상한으로 보고한다**(규율 26) — 세 점으로는 「비례보다 느리다」를 못 세운다\n", 3.0 * rse);
		LogA("[mlt] 📉   ⚠️ 고정 %u문맥 · 세 점의 진단이다 — 절대 성능으로 인용하지 않는다\n", kNCtx);
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		_E.Destroy(); _done = true;
	}

	static void _Fail(const char* why)
	{
		LogA("[mlt] ⏳ ⛔ %s (씨앗 %u · 팔 %u · 반복 %u · 단계 %u)\n", why, _seed, _arm, _rep, _st);
		_E.Destroy(); _done = true;
	}
};
