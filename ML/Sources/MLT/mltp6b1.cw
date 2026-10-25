// mltp6b1.cw — ⏳ 회차 120 · **㉠ 재설계: 「참 중간 ↔ 뒤섞은 중간」** (`-mltp6b1`) ⭐ **판정 회차**
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 120 이다.** ⭐ **하네스보다 먼저 썼다.**
//   상위 캔버스: **`P6 ㉠ — 사슬이 먼 예측을 돕나`** · **119~120 = 2회차**(규율 33).
//
// ── ⚠️ 회차 119 가 찾은 결함 **둘을 동시에** 고친다 ────────────────────────
//   ㈀ ⭐ **규율 34** — 회차 118 의 「정답채움」은 정답을 **중간 입력**에 넣었는데 그 시각의
//     **표적이 같은 id** 라 ***자명한 복사***였다(채점을 답으로 옮기자 CE 0.296 → **10.64**).
//     ⇒ ★ 이 회차는 **입력을 안 건드리고 표적만** 흔든다 ⇒ **베낄 자리가 없다.**
//   ㈁ ⭐ **개수 교란** — 회차 119 는 `㈀`(답만 8개) ↔ `㈁㈂`(중간+답 32개)로 **4배 차이**였다.
//     ⇒ ★ 이 회차는 **세 팔 다 ctx당 32개**다(회차 116 의 「개수 관문」을 처음부터 넣었다).
//
// ── ⭐ 팔 셋 — 과제 `TASK1`(4스텝 뒤) 고정 · 채점 **답 시각만** ────────
//   | ㈀ **뒤섞은 중간** | 중간 표적을 **다른 문맥의 것**으로 ⇒ 개수·분포 그대로, **사슬만 없다** |
//   | ㈁ **참 중간**     | 중간 표적 그대로 ⇒ ⭐ **표제** |
//   | ㈂ **답 리허설**   | 중간 표적 = **답과 같은 id** ⇒ ⭐ **양성 대조** |
//   ★ ㈂ 를 고른 근거: 정답을 **표적**에 넣지 **입력**에 안 넣으므로 **규율 34 를 안 어긴다**.
//     그 뜻은 *"중간에서 답을 미리 예측하게 하면 답이 좋아지나"* 이고 **반드시 좋아져야** 한다.
//
// ── ✅ 관문 ───────────────────────────────────────────────────────────────
//   **배관** 씨앗0 바닥 1.1163 · 유한 · ⭐ **개수 관문**(세 팔의 학습 표적 수가 같다)
//   ⭐ **양성 대조**(규율 16) `㈂ < ㈀` — 전부 · ⭐ **표제** `㈁ < ㈀` · `|d̄|/SE ≥ 3`
//
// ── ⭐ 예측 ──────────────────────────────────────────────────────────────
//   ⚠️ **최근 여덟 중 다섯을 틀렸다.**
//   · 양성 대조 통과 예측 · ⭐ **표제는 진짜 모른다(반반)**
//   · ⚠️ 회차 119 가 **CE 10 대**를 봤다 ⇒ 두 팔 다 답을 거의 못 배울 수 있다
//     ⇒ ★ 그러면 **양성 대조가 그것을 잡는다**(판정불가) — 그것도 ⭐ **답이다**(더 기본적인 벽)
//
// ── (아래는 회차 119 의 머리말 원문 — 「같은 과제 안의 A/B」의 근거) ───────
//
// ══════════════════════════════════════════════════════════════════════════════
// mltp6b0.cw — ⏳ 회차 119 · **㉠ 중간을 주면 「먼 예측」이 되나** ⭐ **판정 회차**
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 119 다.** ⭐ **하네스보다 먼저 썼다.**
//   상위 캔버스: **`P6 ㉠ — 사슬이 먼 예측을 돕나`**(회차 118 파일럿 갈래가 지정했다).
//
// ── ⚠️⚠️ 먼저 — **`MLT.md` 의 「N1 > N0」을 그대로 쓰면 안 된다** ────────────
//   `N0 = 1스텝` · `N1 = N스텝` 은 **애초에 다른 과제**다(하나는 쉽고 하나는 어렵다)
//   ⇒ ⛔ CE 를 그냥 비교하면 ***"N0 이 쉬워서"를 재게 된다*** — 그것은 난이도 측정이지 관문이 아니다.
//   ★ 회차 117 심사가 이미 *"N0 을 이 회차 안의 기준선으로 쓴다"* 고 적었고, 여기서 **자로 만든다**.
//
// ── ⭐ 자를 **「같은 과제 안의 A/B」**로 바꾼다 ──────────────────────
//   과제를 **`TASK1`(4스텝 뒤) 하나로 고정**하고 「중간이 있나」만 흔든다:
//   | ㈀ **중간 없음** | 학습에서 중간 표적을 뺀다 ⇒ **기준선** |
//   | ㈁ **중간 있음** | 중간 표적을 둔다(모델이 낸다) ⇒ ⭐ **표제** |
//   | ㈂ **정답채움**   | 중간 **입력**을 정답으로 ⇒ ⭐ **양성 대조**(회차 118 이 −1.035 를 봤다) |
//   ⭐ **채점은 세 팔 모두 「답 시각만」** — ⚠️ 그래야 **같은 질문**에 답한 것을 견준다.
//     ★ 중간 표적을 CE 에 넣으면 ㈁ 이 **더 많은 표적을 채점받아** 평균이 흔들린다(회차 116 의 함정).
//
// ── ✅ 관문 ───────────────────────────────────────────────────────────────
//   **배관** 씨앗0 바닥 **1.1163**(회차 118 눈금) · 유한
//   ⭐ **양성 대조**(규율 16) `㈂ < ㈀` — **12/12** · 안 서면 **판정불가**
//   ⭐ **표제** `㈁ < ㈀` — 짝지은 평균 `d̄` · **`d̄ < 0` 그리고 `|d̄|/SE ≥ 3`**
//
// ── 📏 잡음 세 항(규율 29·32) ────────────────────────────────────────────
//   표본(답 표적 4,032) · 실행 `0.00405×√2 = 0.0057` · ⭐ **씨앗은 짝지음이 없앤다**(회차 118 폭 0.944)
//   ⇒ `SE ≈ 0.0016` ⇒ **문턱 `|d̄| ≥ 0.005`** ⚠️ 자가 **매우 민감**하다 ⇒ **크기도 같이 보고**한다.
//
// ── ⭐ 예측 ──────────────────────────────────────────────────────────────
//   ⚠️ **최근 일곱 중 다섯을 틀렸다.** 그것을 알고 적는다:
//   · ⭐ **양성 대조 통과**(회차 118 이 이미 봤다)
//   · ⭐ **표제는 ⚠️ 진짜 모른다 — 반반**.
//     **될 근거** — 중간을 내면 그 계산이 답의 재료가 된다(사슬의 전제)
//     **안 될 근거** — ⚠️⚠️ **회차 116 의 기제가 정확히 여기 적용된다**(*"더 잘 맞히게는 되지만
//       **더 쓰게**는 안 된다"*) ⇒ 중간 표적을 얹어도 답이 **중간을 안 쓸 수 있다**
//   · ⭐ **어느 쪽이든 값이 있다** — 통과면 사슬이 서고, 실패면 ⭐ **「표현의 문제」가
//     두 단계(P4·P6)에서 독립적으로 재현**된다(그것은 더 강한 결론이다).
//
// ── (아래는 회차 118 의 머리말 원문 — 배치의 근거) ────────────────────────
//
// ══════════════════════════════════════════════════════════════════════════════
// mltp6a0.cw — 🔩 회차 118 · **P6 배관: `MLTP6Ctx` + 판정 ①** ⚠️ **배관 회차**
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 118 이다.** ⭐ **하네스보다 먼저 썼다.**
//   ⭐ 회차 117 설계 심사가 정한 순서의 첫 칸. ⚠️ **판정 회차가 아니다** — 어떤 가설도 안 판정한다.
//
// ── 🧱 무엇을 짓나 ────────────────────────────────────────────────────────
//   `MLTP6Ctx` — `MLT.md` 「배치 최종형」 그대로 `EXP → TASK → EYE → LISTEN → [중간] → PRED → 답`.
//   ⭐ 제어 심볼을 **「축」으로 흡수**했다(`kAxes = 14` · `kTime = 9` ⇒ `kCtx 126` · `kRows 1008`)
//   ⚠️ `MLTP4Ctx` 는 **P4 의 정본으로 얼린다**(회차 76 이 `MLTP3Ctx` 에 한 것과 같은 판정).
//
// ── ✅ 관문 — ⚠️ 전부 배관이다 ────────────────────────────────────────────
//   ⭐ **판정 ①** — **중간 입력을 정답으로 채우면 답 CE 가 「가림」보다 크게 낮아야 한다**
//     ★ 그것이 *"사슬 배치가 실제로 답에 닿는가"* 의 증명이다. ⚠️ 안 서면 배치가 틀린 것이다.
//   ⭐ **판정 ②** — 두 과제가 **실제로 다른 답**을 부르나(`TASK0` 답 ↔ `TASK1` 답이 다른 비율 ≥50%)
//   ⭐ **결정성** — 같은 씨앗 두 번 ⇒ 코퍼스 **비트 동일**
//   ⭐ **누출** — `static_assert`(컴파일 타임)
//   보고 — 복사바닥 · 첫 학습이 그것을 넘나 · ⭐ **씨앗 폭**(다음 회차의 잡음 바닥이 된다)
//
// ── ⭐ 예측 ──────────────────────────────────────────────────────────────
//   · 판정 ① — ⚠️ **한 번에 안 설 것**으로 예측(배치 회차는 대개 그렇다 · 회차 77 도 두 번 걸렸다)
//   · 판정 ② — 통과 · ⚠️ **최근 여섯 중 넷을 틀렸다**

using namespace PE;

class MLTP6B1
{
public:
	static void Tick(RHI* rhi)
	{
		if (_done || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltp6b1"))
		{
			LogA("[mlt] ⏳ 회차 120(㉠ 재설계 · 참 중간 ↔ 뒤섞은 중간)은 **꺼져 있다**(`-mltp6b1`)\n");
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
		if (_st == kBodyInit) { _BodyBegin(rhi); return; }
		if (_st == kBodyEval) { _BodyEval(); return; }
		_BodyTrain();
	}

	static bool Done() { return _done; }

private:
	typedef MLTP6Cfg C6;
	// ⭐ **먼저 씨앗 2 로 진단한다**(운영 규약 · ~10분) — 이상 없으면 12 로 올린다.
	//   ★ 이 세션 최대의 단축이 *"12씨앗 돌리기 전에 적은 씨앗으로 먼저"* 였다(회차 119 가 그 값을 했다).
	static constexpr uint32 kSeeds = 2u;
	static constexpr uint32 kEncF = 32u, kEncSteps = 1200u, kEncPerTick = 8u;
	static constexpr uint32 kN = 250u, kLocal = 8u;
	static constexpr uint32 kTime = MLTP6Ctx::kTime;
	static constexpr uint32 kBatch = MLTP6Ctx::kBatch;
	static constexpr uint32 kCandidates = MLTP2Cfg::kPatches * kLocal;
	// ⚠️⚠️ **문맥 수를 그룹으로 맞춘다** — 아래 `kGroup` 이 3 이므로 512 가 아니라 **504**(= 3·8·21).
	//   ★ `kBatch 8` 과 `kGroup 3` 의 **공배수**여야 한다(풀 스텝과 gather 그룹 둘 다 나눠떨어져야 한다).
	//   ⭐ 이것을 **`static_assert` 가 잡았다**(첫 빌드에서 `512 % 3 ≠ 0`) — 컨셉의
	//     *"조용한 버그는 컴파일되고 안 죽고 숫자만 틀린다"* 를 컴파일 타임으로 옮긴 자리다.
	static constexpr uint32 kNCtx = 504u, kTestCtx = 504u;
	static constexpr uint32 kTrainEpi = 1u, kTestEpi = 901u;
	static_assert(kTestEpi >= kTrainEpi + kNCtx,
		"시험 에피소드가 학습과 겹친다 — kTestEpi >= kTrainEpi + kNCtx 여야 한다(회차 81)");
	static constexpr uint32 kPoolSteps = kNCtx / kBatch, kTestPool = kTestCtx / kBatch;
	// ⚠️ 한 문맥이 프레임 `kTime`(9) 장을 쓴다 ⇒ 인코더 풀 32 에 **그룹 = 32/9 = 3 문맥**
	static constexpr uint32 kGroup = kEncF / kTime;                 // 3
	static_assert(kGroup >= 1u, "인코더 풀이 한 문맥의 프레임 수보다 작다");
	static_assert(kNCtx % kGroup == 0u, "문맥 수가 그룹으로 안 나눠진다");
	static_assert(kNCtx % kBatch == 0u, "문맥 수가 배치로 안 나눠진다");
	static_assert(kTestCtx % kGroup == 0u && kTestCtx % kBatch == 0u, "시험 문맥 수가 안 맞는다");
	static_assert(kTestPool <= MLTModelCfg::kPool, "시험 풀 스텝이 kPool 을 넘는다(회차 105 의 그 벽)");
	static constexpr uint32 kSteps = 800u, kPerTick = 4u;
	static constexpr uint32 kRep = 3u;
	// ⭐ **회차 120 의 팔 셋** — ⚠️ 회차 119 의 결함 둘을 **동시에** 고쳤다.
	//   과제는 `TASK1`(4스텝 뒤) 고정 · 채점은 **세 팔 모두 답 시각만**.
	//   | ㈀ **뒤섞은 중간** | 중간 표적을 **다른 문맥의 것**으로 ⇒ ⭐ 기준선(개수 같고 **사슬만 없다**) |
	//   | ㈁ **참 중간**     | 중간 표적 그대로 ⇒ ⭐ **표제** |
	//   | ㈂ **답 리허설**   | 중간 표적 = **답과 같은 id** ⇒ ⭐ **양성 대조**(⚠️ 규율 34 를 안 어긴다) |
	//   ⭐ **세 팔의 학습 표적 수가 정확히 같다**(ctx당 32) ⇒ **개수 교란이 원리적으로 없다**
	//     (회차 119 는 ㈀ 만 8개라 4배 차이였다 — 회차 116 의 「개수 관문」을 안 넣은 실수).
	static constexpr uint32 kArms = 3u, kArmShuf = 0u, kArmMid = 1u, kArmReh = 2u;
	static constexpr uint32 kSymVocab = C6::kSymUnit + kN + C6::kNMark + 1u;

	enum { kEncInit, kEncTrain, kGather, kQuiesce, kBodyInit, kBodyTrain, kBodyEval };

	inline static MLTP2Enc _E;
	inline static MLTModel _M;
	inline static MLTP6Ctx _tr, _te;
	inline static bool _done = false, _banner = false, _encSetup = false, _finite = true;
	inline static bool _pending = false;
	inline static uint32 _seed = 0u, _st = kEncInit, _step = 0u, _arm = 0u, _rep = 0u;
	inline static uint32 _cor = 0u, _gGrp = 0u, _gIdx = 0u, _qWait = 0u;
	inline static Array<float> _code, _norm;
	inline static Array<float> _trVal, _trSym, _teVal, _teSym;
	// ⭐ 회차 119 — 표적도 팔마다 다르다(위 `_MakeTgt`)
	inline static Array<float> _trTgt, _teTgt;
	// ⭐ 회차 120 — **개수 관문**(세 팔의 학습 유효 표적 수)
	inline static uint32 _keptN[kArms][kSeeds];
	inline static float _run[kRep];
	inline static float _ce[kArms][kSeeds];
	inline static float _floorTe[kSeeds];
	inline static bool  _seedOk[kSeeds];
	inline static uint32 _ei = 0u, _ewait = 0u;
	inline static bool   _epend = false;
	inline static double _esum = 0.0;
	// ⭐ 판정 ② — 두 과제의 답이 다른 비율 · ⭐ 결정성 — 코퍼스 해시
	inline static float  _taskDiff[kSeeds];
	inline static uint64 _hash0 = 0u, _hash1 = 0u;
	inline static bool   _detOk[kSeeds];

	static void _ToBody() { _qWait = MLTEvalGate::kDelay; _st = kQuiesce; }
	static const char* _ArmName()
	{
		switch (_arm)
		{
		case kArmShuf: return "㈀ 뒤섞은중간";
		case kArmMid:  return "㈁ 참중간";
		default:       return "㈂ 답리허설(양성)";
		}
	}

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] ⏳ **회차 120 · ㉠ 재설계: 「참 중간 ↔ 뒤섞은 중간」**(⭐ 판정 회차 · 씨앗 %u)\n", kSeeds);
		LogA("[mlt] ⏳   ⚠️ **회차 119 가 찾은 결함 둘을 동시에 고쳤다**:\n");
		LogA("[mlt] ⏳     ㈀ **규율 34** — 118 의 「정답채움」은 정답을 **중간 입력**에 넣었는데 **표적이 같은 id** 라 **자명한 복사**\n");
		LogA("[mlt] ⏳       (채점을 답으로 옮기자 CE **0.296 → 10.64**) ⇒ ★ 이 회차는 **입력을 안 건드리고 표적만** 흔든다\n");
		LogA("[mlt] ⏳     ㈁ **개수 교란** — 119 는 ㈀(8개) ↔ ㈁㈂(32개)로 **4배** 차 ⇒ ★ 이 회차는 **셋 다 32개**\n");
		LogA("[mlt] ⏳   🔬 과제 **`TASK1`(%u스텝 뒤) 고정** · 채점 **답 시각만** · 팔 셋:\n", C6::kMid + 1u);
		LogA("[mlt] ⏳     ㈀ **뒤섞은중간**(다른 문맥의 표적 — 개수·분포 그대로, **사슬만 없다**)\n");
		LogA("[mlt] ⏳     ㈁ **참중간**(그대로) ⇒ ⭐ **표제** │ ㈂ **답리허설**(중간 표적 = 답) ⇒ ⭐ **양성 대조**\n");
		LogA("[mlt] ⏳     ★ ㈂ 는 정답을 **표적**에 넣지 **입력**에 안 넣는다 ⇒ **규율 34 를 안 어긴다**\n");
		LogA("[mlt] ⏳   ⭐ **개수 관문** + ⭐ **양성 대조**(`㈂ < ㈀`) — 둘 다 서야 표제를 읽는다\n");
		LogA("[mlt] ⏳   📏 잡음 세 항 — 표본(답 표적 %u) · 실행 0.0057(짝) · ⭐ **씨앗은 짝지음이 없앤다**(118 폭 0.944)\n",
			kTestCtx * MLTP6Ctx::kPersist);
		LogA("[mlt] ⏳   ⭐ **예측** — 양성 대조 통과 · ⭐ **표제는 ⚠️ 진짜 모른다(반반)**\n");
		LogA("[mlt] ⏳     안 될 근거 = ⚠️⚠️ **회차 116 의 기제**(*\"더 잘 맞히게는 되지만 **더 쓰게**는 안 된다\"*)\n");
		LogA("[mlt] ⏳     ⭐ **어느 쪽이든 값이 있다** — 실패면 **「표현의 문제」가 P4·P6 두 단계에서 재현**된다\n");
		LogA("[mlt] ⏳     ⚠️ 최근 일곱 중 **다섯을 틀렸다**\n");
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
		_cor = 0u; _gGrp = 0u; _gIdx = 0u; _pending = false; _st = kGather;
	}

	// ══════════════════════════════════════════════════════════════════
	// 🔗 **사슬 한 문맥** — ⚠️ 「단계」는 **세계의 스텝**이다(사고 단계가 아니다).
	// ══════════════════════════════════════════════════════════════════
	//   시각 배치: `EXP × kExp` → `EYE`(지금) → `중간 × kMid` → `답`
	//   ⭐ 과제 — `TASK0`(다음 스텝) 이면 **중간이 없다**(전부 「없음」) · `TASK1` 이면 **채운다**
	//   ⚠️ 프레임은 **연속한 스텝**이라 세계를 한 번만 굴린다.
	static void _Gather()
	{
		MLTP6Ctx& C = (_cor == 0u) ? _tr : _te;
		const uint32 nCtx = (_cor == 0u) ? kNCtx : kTestCtx;
		if (_pending)
		{
			Array<float> ids, mag;
			if (!_E.ReadAct(ids, mag) || ids.Count() != kCandidates) { _Fail("활성 리드백"); return; }
			const uint32 f = _gIdx - 1u;
			C.StoreAct(_gGrp * kGroup + f / kTime, f % kTime, ids, mag, _norm);
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
				// ⭐ **회차 119 는 과제를 `TASK1`(4스텝 뒤) 하나로 고정**한다.
				//   ⚠️ 회차 118 은 번갈아 줬다(과제 채널이 사나 = 판정 ②). 여기서는 **다른 물음**이라
				//     과제를 섞으면 *"N0 이 쉬워서"* 가 섞인다 ⇒ 「중간이 있나」만 흔든다.
				C.SetTask(ctx, 1u);
				C.StoreMarks(ctx);
				MLTWorld w; w.Reset(_seed, epi + ctx, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
				for (uint32 t = 0; t < kTime; ++t)
				{
					if (!w.Render(bmp) || !MLTWorld::Pack(bmp, nullptr, packed))
					{ _Fail("Render/Pack(문맥)"); return; }
					MLTP2Enc::AppendFrame(fr, tg, (const uint8*)packed.GetData());
					C.StoreState(ctx, t, w.State());
					w.StepWith(w.ActAt(w.StepNo()));
				}
			}
			if (!_E.WritePool(fr, tg, kGroup * kTime)) { _Fail("문맥 풀 업로드"); return; }
		}
		if (_gIdx < kGroup * kTime)
		{
			_E.SetFrame(_gIdx);
			if (!_E.Forward()) { _Fail("문맥 forward"); return; }
			++_gIdx; _pending = true; return;
		}
		_gIdx = 0;
		if (++_gGrp * kGroup >= nCtx)
		{
			_gGrp = 0u;
			if (++_cor >= 2u)
			{
				Array<float> marg; _tr.Marginal(marg);
				float c1 = 0.0f, c2 = 0.0f, l1 = 0.0f, l2 = 0.0f;
				_tr.BestCopy(marg, c1, c2, l1, l2, MLTP6Ctx::kAllT1);
				const float t1 = (float)_te.CeCopy(marg, l1, false, MLTP6Ctx::kAllT1);
				const float t2 = (float)_te.CeCopy(marg, l2, true, MLTP6Ctx::kAllT1);
				_floorTe[_seed] = (t1 < t2) ? t1 : t2;
				_Checks();
				_arm = 0u; _rep = 0u; _ToBody();
			}
		}
	}

	// ⭐ 배관 검사 — ⚠️ 몸통을 돌리기 **전에** 본다(싸고, 틀리면 여기서 멈춘다).
	static void _Checks()
	{
		// ⚠️ 회차 118 의 판정②(과제가 다른 답을 부르나)는 **여기서 안 돈다** — 과제를 `TASK1` 로
		//   고정했기 때문이다(위 `SetTask`). ⇒ 그 자리는 **회차 118 이 이미 4/4 로 세웠다**.
		_taskDiff[_seed] = 0.0f;
		// ⭐ 결정성 — 코퍼스 해시(같은 씨앗을 두 번 도는 것은 다음 회차의 일이고, 여기서는
		//   **씨앗 0 을 두 번 모아** 비트 동일을 본다면 비용이 커진다 ⇒ 해시만 찍어 둔다).
		uint64 h = 1469598103934665603ull;
		const Array<float>& v = _te.Val();
		for (uint32 i = 0; i < v.Count(); ++i)
		{ h ^= (uint64)(*(const uint32*)&v[i]); h *= 1099511628211ull; }
		if (_seed == 0u) _hash0 = h; else if (_seed == 1u) _hash1 = h;
		_detOk[_seed] = true;
		LogA("[mlt] ⏳ 씨앗 %u · 복사바닥 **%.4f**(전 표적 %u · ⚠️ 채점은 **답 시각만** %u) · 해시 %016llx\n",
			_seed, (double)_floorTe[_seed], _te.Targets(),
			kTestCtx * MLTP6Ctx::kPersist, (unsigned long long)h);
	}

	// ⚠️ **입력은 세 팔이 전부 같다** — ⭐ 회차 120 은 **표적만** 흔든다(규율 34).
	//   ★ 그래서 `FillMidInputs`(회차 118 이 쓴 것)를 **안 부른다** — 그 자는 무효다.
	static void _MakePool(const MLTP6Ctx& C, uint32 nCtx, Array<float>& val, Array<float>& sym)
	{
		const uint32 n = (nCtx / kBatch) * MLTP6Ctx::kRows;
		val.Reset(0); sym.Reset(0);
		for (uint32 i = 0; i < n; ++i) { val.Add(C.Val()[i]); sym.Add(C.Sym()[i]); }
	}

	// ⭐ **표적을 만든다 — 이 회차의 핵심**
	//   **학습** — ㈀ **뒤섞기** · ㈁ **그대로** · ㈂ **답과 같은 id** (⭐ 셋 다 **개수가 같다**)
	//   **시험** — ⭐ **세 팔 모두 답만** 채점(*"같은 질문으로 견준다"*)
	static void _MakeTgt(const MLTP6Ctx& C, uint32 nCtx, Array<float>& tgt, bool isTest)
	{
		const uint32 n = (nCtx / kBatch) * MLTP6Ctx::kRows;
		tgt.Reset(0);
		for (uint32 i = 0; i < n; ++i) tgt.Add(C.Tgt()[i]);
		if (isTest)
		{
			for (uint32 ctx = 0; ctx < nCtx; ++ctx) C.DropMidTargets(ctx, tgt);
			return;
		}
		if (_arm == kArmShuf)
			for (uint32 ctx = 0; ctx < nCtx; ++ctx) C.ShuffleMidTargets(ctx, nCtx, tgt);
		else if (_arm == kArmReh)
			for (uint32 ctx = 0; ctx < nCtx; ++ctx) C.MidTargetsToAnswer(ctx, tgt);
		// ㈁ 참중간 = 그대로
	}

	// ⭐ **개수 관문**(회차 116 의 그것) — 학습 유효 표적 수를 센다. ⚠️ 세 팔이 같아야 한다.
	static uint32 _CountValid(const Array<float>& tgt)
	{
		uint32 c = 0u;
		for (uint32 i = 0; i < tgt.Count(); ++i)
			if (tgt[i] >= 0.0f && tgt[i] < (float)kN) ++c;
		return c;
	}

	static void _BodyBegin(RHI* rhi)
	{
		if (!_M.Setup(rhi, kSymVocab, kN, MLTP6Ctx::kAxes, kTime)) { _Fail("몸통 준비"); return; }
		_MakePool(_tr, kNCtx, _trVal, _trSym);
		_MakePool(_te, kTestCtx, _teVal, _teSym);
		_MakeTgt(_tr, kNCtx, _trTgt, false);
		_MakeTgt(_te, kTestCtx, _teTgt, true);
		_keptN[_arm][_seed] = _CountValid(_trTgt);      // ⭐ 개수 관문
		if (!_M.UploadPool(_trVal, _trTgt, kPoolSteps) || !_M.UploadSymbolPool(_trSym, kPoolSteps))
		{ _Fail("학습 풀 업로드"); return; }
		_step = 0u; _st = kBodyTrain;
	}

	static bool _SwitchToTest()
	{
		if (!_M.UploadPool(_teVal, _teTgt, kTestPool) || !_M.UploadSymbolPool(_teSym, kTestPool))
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
			if (!_M.Forward() || !_M.Backward() || !_M.AdamStep(1.0f)) { _Fail("몸통 스텝"); return; }
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
			_epend = false;
		}
		if (_ei >= kTestPool)
		{
			_run[_rep] = (float)(_esum / (double)kTestPool);
			if (++_rep < kRep) { _ToBody(); return; }
			double s = 0.0;
			for (uint32 i = 0; i < kRep; ++i) s += (double)_run[i];
			_ce[_arm][_seed] = (float)(s / (double)kRep);
			LogA("[mlt] 🔩   %s 씨앗 %u · 평균 CE **%.5f**(R=%u)\n",
				_ArmName(), _seed, (double)_ce[_arm][_seed], kRep);
			_rep = 0u;
			if (++_arm < kArms) { _ToBody(); return; }
			_seedOk[_seed] = _finite;
			_arm = 0u; ++_seed; _st = kEncInit;
			return;
		}
		_M.SelectStep(_ei);
		if (!_M.Forward()) { _Fail("평가 forward"); return; }
		++_ei; _epend = true; _ewait = MLTEvalGate::kDelay;
	}

	static void _Summary()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] ⏳ **회차 120 · ㉠ 재설계: 참 중간 ↔ 뒤섞은 중간**(씨앗 %u · `TASK1` 고정 · 채점 **답 시각만**)\n",
			kSeeds);
		uint32 ok = 0u, pos = 0u, up = 0u, cntOk = 0u;
		double mNo = 0.0, mMid = 0.0, mFill = 0.0, mFloor = 0.0, dsum = 0.0;
		for (uint32 s = 0; s < kSeeds; ++s)
		{
			if (!_seedOk[s]) continue;
			++ok;
			mNo += _ce[kArmShuf][s]; mMid += _ce[kArmMid][s]; mFill += _ce[kArmReh][s];
			mFloor += _floorTe[s];
			// ⭐ 개수 관문 — 세 팔의 학습 유효 표적 수가 같나(회차 116 의 그것)
			if (_keptN[kArmShuf][s] == _keptN[kArmMid][s] && _keptN[kArmMid][s] == _keptN[kArmReh][s])
				++cntOk;
			// ⭐ 양성 대조 — 답 리허설이 뒤섞은중간보다 좋아야 한다
			if (_ce[kArmReh][s] < _ce[kArmShuf][s]) ++pos;
			// ⭐ 표제 — 참중간 < 뒤섞은중간
			const double d = (double)_ce[kArmMid][s] - (double)_ce[kArmShuf][s];
			if (d < 0.0) ++up;
			dsum += d;
			LogA("[mlt] ⏳   씨앗 %2u — 바닥 %.4f │ ㈀ 뒤섞 **%.5f** → ㈁ 참중간 **%.5f** (**Δ %+.5f**) │ ㈂ 리허설 %.5f │ 표적 %u/%u/%u\n",
				s, (double)_floorTe[s], (double)_ce[kArmShuf][s], (double)_ce[kArmMid][s],
				d, (double)_ce[kArmReh][s],
				_keptN[kArmShuf][s], _keptN[kArmMid][s], _keptN[kArmReh][s]);
		}
		if (ok > 0u) { mNo /= ok; mMid /= ok; mFill /= ok; mFloor /= ok; }
		const double dbar = (ok > 0u) ? (dsum / (double)ok) : 0.0;
		double dv = 0.0;
		for (uint32 s = 0; s < kSeeds; ++s)
		{
			if (!_seedOk[s]) continue;
			const double d = (double)_ce[kArmMid][s] - (double)_ce[kArmShuf][s] - dbar;
			dv += d * d;
		}
		const double dsd = (ok > 1u) ? Sqrt((float)(dv / (double)(ok - 1u))) : 0.0;
		const double dse = (ok > 0u) ? (dsd / Sqrt((float)ok)) : 0.0;
		const double tt = (dse > 1.0e-12) ? (Abs(dbar) / dse) : 0.0;
		LogA("[mlt] ⏳   평균 — 바닥 **%.4f** │ ㈀ 뒤섞 **%.5f** · ㈁ 참중간 **%.5f** · ㈂ 리허설 **%.5f**\n",
			mFloor, mNo, mMid, mFill);
		LogA("[mlt] ⏳   ⭐ **개수 관문**(세 팔의 학습 표적 수가 같다) — **%u/%u** → %s\n",
			cntOk, ok, (cntOk == ok && ok > 0u) ? "✅" : "⛔ **개수 교란이 남는다**");
		LogA("[mlt] ⏳   ⭐ **양성 대조**(규율 16 · ㈂ 리허설 < ㈀ 뒤섞) — **%u/%u** · 차 **%+.5f** → %s\n",
			pos, ok, mFill - mNo, (pos == ok && ok > 0u) ? "✅" : "⛔ **자가 죽었다**");
		LogA("[mlt] ⏳   ⭐ **표제**(㈁ 참중간 < ㈀ 뒤섞) — 짝지은 평균 `d̄ = %+.5f` · sd_짝 %.5f · **SE %.5f**\n",
			dbar, dsd, dse);
		LogA("[mlt] ⏳     ⇒ ⭐ **|d̄|/SE = %.2f**(필요 3) · `㈁<㈀` **%u/%u** · 문턱 `|d̄| ≥ %.5f`\n",
			tt, up, ok, 3.0 * dse);
		LogA("[mlt] ⏳   📏 잡음 세 항(규율 29·32) — 표본(답 표적 %u) · 실행 0.0057(짝) · ⭐ **씨앗은 짝지음이 없앤다**\n",
			kTestCtx * MLTP6Ctx::kPersist);
		const bool posOk = (pos == ok) && (ok > 0u);
		const bool cOk = (cntOk == ok) && (ok > 0u);
		if (!_finite)
			LogA("[mlt] ⏳   ⭐ 판정 = ⛔ **판정불가** — 유한하지 않다\n");
		else if (!cOk)
			LogA("[mlt] ⏳   ⭐ 판정 = ⛔ **판정불가** — **개수 관문이 안 섰다**(회차 119 가 밟은 그 교란)\n");
		else if (!posOk)
			LogA("[mlt] ⏳   ⭐ 판정 = ⛔ **판정불가** — **양성 대조가 안 섰다**(중간에서 답을 리허설해도 안 좋아진다)\n"
			     "[mlt] ⏳      ⇒ ⚠️ 그러면 ***이 배치가 4스텝을 못 배우는 것***이다(더 기본적인 벽) · 규율 16\n");
		else if (tt >= 3.0 && dbar < 0.0)
			LogA("[mlt] ⏳   ⭐ 판정 = ⭐ ***참 사슬이 먼 예측을 돕는다*** — **㉠ 통과** ⇒ 다음은 ㉡(가림)\n");
		else if (tt >= 3.0)
			LogA("[mlt] ⏳   ⭐ 판정 = ⚠️⚠️ **거꾸로다**(`d̄ > 0`) — **참 사슬이 뒤섞은 것보다 나쁘다** ⇒ 설계를 다시 본다\n");
		else
			LogA("[mlt] ⏳   ⭐ 판정 = ⭐ ***참 사슬이 뒤섞은 것과 다르지 않다*** (|d̄| < %.5f)\n"
			     "[mlt] ⏳      ⇒ ⚠️ **회차 116 의 기제가 여기서 재현된다** — *\"더 잘 맞히게는 되지만 더 쓰게는 안 된다\"*\n"
			     "[mlt] ⏳      ⇒ ⭐ **「표현의 문제」가 두 단계(P4·P6)에서 독립적으로 확인된다**\n", 3.0 * dse);
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		_E.Destroy(); _done = true;
	}

	static void _Fail(const char* why)
	{
		LogA("[mlt] 🔩 ⛔ %s (씨앗 %u · 코퍼스 %u · 그룹 %u · 팔 %u · 반복 %u · 단계 %u)\n",
			why, _seed, _cor, _gGrp, _arm, _rep, _st);
		_E.Destroy(); _done = true;
	}
};
