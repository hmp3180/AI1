// mltl1q0.cw — 🎯 회차 162 · **칸 10 의 첫 실측** (`-mlt -mltl1q0` · 델타는 `-mltdelta`)
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 141 이다.** ⭐ **하네스보다 먼저 썼다.**
//   **상위 캔버스: `자의 천장을 올린다` · 141~ = 1회차**(캔버스를 바꿨으므로 **한 회차 파일럿**).
//
// ── ⭐ 표제 — ***천장을 32배 올렸는데 `SE` 도 같이 올라가나*** ────────
//   회차 140 의 처방은 손잡이 둘이고 **곱해진다**:
//     ㈎ 낱말을 **시각당 하나**(×7~8) · ㈏ 채점을 **변화 표적에만**(×4.6)
//   ⚠️ 그런데 ㈏ 는 **CE 절대값을 4배로 올리고 표본을 1/4.6 로 줄인다** ⇒ `SE` 도 따라 오르면
//   이득이 상쇄된다. ★ 그것이 이 파일럿의 물음이고, 답이 곧 **규율 49 를 쓸 수 있느냐**다.
//
// ── 🔬 **1씨앗 진단(114초)이 설계 오류 둘을 잡았다 — 판정 전에 고쳤다** ────
//   ㉠ ⭐ **상수 팔을 바닥으로 쓸 수 없다.** 섞은 낱말(정보 0)이 상수 대비 **−0.117 을 도왔다**
//      (`|d̄|/SE = 9.73`). ⇒ 값이 늘 0 인 축은 **죽은 축**이고, **변동하는 값**이 들어오는 것만으로
//      모델이 달라진다. ★ 138·139 의 「축 개수」 교란의 **새 얼굴**이다(이번엔 **입력의 변동성**).
//      ⇒ ★ **바닥을 ㈂(섞음)으로 바꾸고**, 음성 대조는 **또 다른 섞기**(㈃)로 세운다.
//   ㉡ ⭐ **천장을 넘었다 — 실현율 120.8%.** ⇒ `천장`(규율 49)은 ***관측 `d̄` 의 상한이 아니다***:
//      `d̄ = I(낱말;표적|문맥) + (KL_바닥 − KL_개입)` 이고 우리는 **두 모델을 따로 학습**시키므로
//      **근사 오차의 차**가 더해진다. ⇒ 천장은 *"정보 경로가 닫혔나"*(천장 ≪ SE)를 말할 뿐이다.
//
// ── 🎛️ 팔 넷 — ⚠️ 축·파라미터·걸음이 전부 같다(14축 · 800걸음) ───────────
//   ㈀ **상수**(계급 4 ⇒ 값 0 · **보고용** — 「변동성 효과」의 크기를 준다) ·
//   ⭐ ㈁ **그 시각에 「바뀌는」 슬롯의 표적 id 계급**(⭐ **표제/양성**) ·
//   ⭐ ㈂ ㈁ 을 **전부 섞은 것**(⭐ **바닥** — 같은 주변분포·같은 변동성 · 정보만 0) ·
//   ㈃ **다른 씨앗으로 또 섞은 것**(**음성** — ㈂ 와 구별 안 돼야 한다)
//   ⚠️ **학습 풀은 안 건드린다** — 마스크는 **시험 풀에만**. 바꾸는 것은 **자**이지 **과제**가 아니다.
//   ⚠️ 낱말 축의 표적은 `IgnoreTgt` ⇒ 채점 대상이 팔마다 같다.
//
// ── 📏 자 — ⭐ 무차원 둘 ──────────────────────────────────────────────────
//   ㉠ `천장 ÷ SE` = `(kTime × H(낱말)) / 채점표적수 ÷ SE`   ← ⭐ **규율 49 를 여기서 쓴다**
//   ㉡ `|d̄| / SE`  = 짝지은 `(㈁ − ㈀)` ± SE(**실행 항 포함**)  ← 양성이 실제로 서나
//   ⭐ 기본 장비 넷: `sd_run` 확인 관문 · SE 에 실행 항 · **실행 2회** · 무차원.
//
// ── 🔮 예측(재기 전에 적었다 · 최근 마흔둘 중 스물둘 틀림) ────────────────
//   채점 표적 **12.2/문맥** · D11 지속 CE **0.10~0.25** · 변화 CE **3.0~4.0** ·
//   `SE` **0.024~0.050** · ⭐ **㉠ 25~55(관문 ≥10 통과)** · ⭐ **㉡ > 10 · 12/12** · ㈂ 구별 안 됨
//   ⚠️ 위험: ㈏ 가 `SE` 를 **비례 이상**으로 올리면 ㉠ 이 10 미만 ⇒ ㈎ 만 쓰고 ㈏ 를 버린다.
// ══════════════════════════════════════════════════════════════════════════════

using namespace PE;

class MLTL1Q0
{
public:
	static void Tick(RHI* rhi)
	{
		if (_done || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltl1q0"))
		{
			LogA("[mlt] 🎯 회차 162(칸 10 의 첫 실측)는 **꺼져 있다**(`-mltl1q0`)\n");
			_done = true; return;
		}
		if (!_banner)
		{
			// ⭐ 규약 — **12씨앗 전에 1씨앗 진단**. `-mltdiag1` 이 그 스위치다.
			_seeds = OS::CommandLine::Has("-mltdiag1") ? 1u : kSeedsMax;
			_deltaOn = OS::CommandLine::Has("-mltdelta");   // ⭐ 회차 162
			{   // ⭐ 회차 163 — `-mltauto <n>`(기본은 여태와 같은 1)
				const char* av = OS::CommandLine::ValueOf("-mltauto", "");
				if (av != nullptr && av[0] >= (char)48 && av[0] <= (char)57)
					_autoN = (int)(av[0] - (char)48);
				const char* pv = OS::CommandLine::ValueOf("-mltpt", "");   // ⭐ 회차 172
				if (pv != nullptr && pv[0] >= (char)48 && pv[0] <= (char)57)
				{
					const uint32 v = (uint32)(pv[0] - (char)48);
					if (v < kPts) _pt = v;
				}
				// ⭐ 회차 176 — **사상 가설을 판정하는 손잡이**.
				//   ★ 오라클 낱말의 계급을 **고정 치환**으로 뒤섞는다 ⇒ 정보량은 **정확히 불변**이고
				//     낱말→표적 사상만 **단조 → 임의**가 된다(규율 60 이 요구하는 그 조건).
				_permOn = OS::CommandLine::Has("-mltperm");
			}
			_Banner(); _banner = true;
		}
		if (_seed >= _seeds) { _Summary(); return; }
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
		_EvalStep();
	}

	static bool Done() { return _done; }

private:
	static constexpr uint32 kSeedsMax = 12u;
	inline static uint32 _seeds = kSeedsMax;

	static constexpr uint32 kEncF = 32u, kEncSteps = 1200u, kEncPerTick = 8u;
	static constexpr uint32 kN = 250u, kLocal = 8u;
	static constexpr uint32 kTime  = MLTP3Ctx::kTime;      // 8
	static constexpr uint32 kBatch = MLTP3Ctx::kBatch;     // 8
	static constexpr uint32 kSlots = MLTP3Ctx::kPersist;   // 8
	static constexpr uint32 kStateAx = MLTP3Ctx::kStateAx; // 5
	static constexpr uint32 kCandidates = MLTP2Cfg::kPatches * kLocal;
	static constexpr uint32 kGroup = kEncF / kTime;        // 4

	// ⚠️ **138·139·140 과 같은 코퍼스**여야 견줄 수 있다.
	static constexpr uint32 kNCtx = 512u, kPbCtx = 512u, kPtCtx = 512u;
	static constexpr uint32 kTrainEpi = 1u, kPbEpi = 2001u, kPtEpi = 5001u;
	static_assert(kPbEpi >= kTrainEpi + kNCtx, "규율 12");
	static_assert(kPtEpi >= kPbEpi + kPbCtx, "규율 12");
	static constexpr uint32 kPoolSteps = kNCtx / kBatch;
	static constexpr uint32 kPtPool = kPtCtx / kBatch;
	static constexpr uint32 kSteps = 800u, kPerTick = 16u;

	static constexpr uint32 kSymA = MLTP3Ctx::kStateAx + kN + 1u;    // 256
	static constexpr uint32 kAx13 = MLTP3Ctx::kAxes;                 // 13
	static constexpr uint32 kAx14 = kAx13 + 1u;                      // 14
	static constexpr uint32 kCtx14 = kAx14 * kTime;                  // 112
	static constexpr uint32 kRows14 = kBatch * kCtx14;               // 896
	static constexpr float  kWordSym = 255.0f;
	// ⭐ 회차 162 — **델타 표현**(`-mltdelta`) · ⚠️ 세계 코드 0줄
	inline static bool _deltaOn = false;
	// ⭐ `maxV` 낱말 — **과거만** 쓰는 프레임 차분(회차 157·159 와 같은 정의)
	//   ⚠️ `t = 0` 은 이전 프레임이 없어 **계급 0 = 「모름」**(오라클 낱말의 0 = 「없음」과 같은 관용구)
	static constexpr float kMvUnknown = -1.0f;
	inline static float _px[MLTWorldCfg::kShapes], _py[MLTWorldCfg::kShapes];
	inline static bool  _pv[MLTWorldCfg::kShapes];
	inline static Array<float>  _mvTrRaw, _mvTeRaw;   // 원값(문맥×시각)
	inline static Array<uint32> _wMvTr,  _wMvTe;      // ⭐ `maxV` 8분위 계급
	// ⭐ 회차 163 — **자율 몫**(`-mltauto <n>` · 기본은 여태와 같은 `kAutoFew` = 1)
	//   ⚠️⚠️ 이 값을 바꾸면 **세계가 바뀐다** ⇒ 기존 회차와 코퍼스가 다르다(검산 상대가 없다).
	inline static int _autoN = MLTWorldCfg::kAutoFew;
	// ⭐ 회차 172 — **세계 점 표**(회차 164 의 표를 그대로 옮긴다 · `-mltpt <n>`)
	//   ★ 사람이 갈래 「세계를 고른다」를 골랐고, 고른 세계가 점 7(㈇ 자율만)이다:
	//     dt x0.001 · 자율 진폭 x5 ⇒ 변화 표적 19.8 중 **자율 몫 55%**(기본 세계는 약 0%).
	//   ⚠️⚠️ 그러나 **지목은 그대로 없다**(회차 163) — 낱말은 여전히 시각당 스칼라 하나다.
	//     ⇒ ★ 그래서 이 회차가 「**몫이 병목인가 지목이 병목인가**」를 가른다.
	//   ⚠️ 세계 코드 0줄 — 164 가 dtMul/autoAmp 를 런타임으로 열었다. 점 0 은 비트 동일.
	static constexpr uint32 kPts = 8u;
	static constexpr float kPtDt[kPts]   = { 1.00f, 1.00f, 1.00f, 0.25f, 0.25f, 1.00f, 0.001f, 0.001f };
	static constexpr float kPtAmp[kPts]  = { 1.00f, 2.50f, 5.00f, 1.00f, 5.00f, 1.00f, 0.00f,  5.00f  };
	static constexpr int   kPtHold[kPts] = { MLTWorldCfg::kHoldMid, MLTWorldCfg::kHoldMid,
	                                         MLTWorldCfg::kHoldMid, MLTWorldCfg::kHoldMid,
	                                         MLTWorldCfg::kHoldMid, MLTWorldCfg::kHoldEasy,
	                                         MLTWorldCfg::kHoldMid, MLTWorldCfg::kHoldMid };
	inline static uint32 _pt = 0u;
	inline static bool _permOn = false;   // ⭐ 회차 176 — 표는 `kWordCls` 뒤에 산다(아래)
	static const char* _PtName(uint32 p)
	{
		switch (p)
		{
		case 0u: return "\u3200 \uae30\ubcf8(\uac80\uc0b0)";
		case 1u: return "\u3201 \uc9c4\ud3ed x2.5";
		case 2u: return "\u3202 \uc9c4\ud3ed x5";
		case 3u: return "\u3203 dt x0.25";
		case 4u: return "\u3204 dt x0.25+\uc9c4\ud3ed x5";
		case 5u: return "\u3205 hold 12";
		case 6u: return "\u3206 \uc815\uc9c0(\uac70\uc758)";
		default: return "\u3207 \uc790\uc728\ub9cc";
		}
	}
	// ⭐ **자율 낱말 둘** — 문맥이 8프레임으로 알기 어려운 **세계의 숨은 라벨**
	//   ⭐ ㈂ 화면에 보이는 **자율 도형 수**(계급 0..autoN) — *"살아있는 게 몇 개 보이나"*
	//   ⭐ ㈄ **자율 최대속력** 8분위(모름 = 0) — `maxV` 와 같은 식인데 **자율에만** 적용
	inline static Array<float>  _anTrRaw, _anTeRaw;   // 자율 개수(원값)
	inline static Array<float>  _asTrRaw, _asTeRaw;   // (회차 163 의 자율속력 — 173 이 안 쓴다)
	// ⭐ 회차 173 — **지목**: 자율 도형이 앉은 **슬롯 번호**를 낱말로.
	//   ★ 172 가 「지목 효율 13.3%」를 냈다 ⇒ 병목의 **86.7%** 가 여기다.
	//   길: 슬롯 j 의 **앵커 패치**(`Anc` · 회차 57)  ↔  자율 도형의 **화면 패치**
	//       (sy/kPatch)*kGrid + (sx/kPatch)   ← VisibleShapes 가 sx·sy 를 준다
	//   ⚠️ 자율이 여럿이어도 **가장 작은 슬롯 번호 하나**만 말한다 — 그것이 이 낱말의 상한이다.
	// ⭐ 회차 174 — **덮는 패치 전부**를 담는다(중심 하나로는 87% 가 「없음」이었다).
	//   손계산: 도형 화면 반경 r = (1.25/d)x32 · d ~ 3.45 ⇒ r ~ 11.6 픽셀
	//           패치 한 변 8 ⇒ 도형이 덮는 패치 ~8.4 개 · 자율 3 개 ⇒ ~25 개
	static constexpr uint32 kAutoMax = 32u;           // 자율 도형이 덮는 패치 상한
	static constexpr uint32 kNoPatch = 0xFFFFFFFFu;
	inline static Array<uint32> _apTr, _apTe;         // [ (ctx*kTime+t)*kAutoMax + i ] = 패치 번호
	inline static Array<uint32> _wSlTr, _wSlTe;       // ⭐ 자율 슬롯 번호 계급
	inline static Array<uint32> _wAnTr, _wAnTe, _wAsTr, _wAsTe;

	// ⭐ 낱말 계급 **9** — 0 = 「변화 없음」 · 1~8 = 그 표적 id 의 8분위.
	//   ★ 9 로 잡은 이유: 값이 `(cls/8)*2−1` 이라 **가운데 계급 4 가 정확히 0** ⇒ 상수 팔의 입력이 0.
	static constexpr uint32 kWordCls = 9u;
	// ── ⭐ 회차 176 — **고정 치환**(`-mltperm`) ────────────────────
	//   ★ 계급 0 은 **그대로 둔다** — 0 = *"그 시각에 바뀌는 슬롯이 없다"* 라
	//     사상이 아니라 **구조**다(그것까지 섞으면 손잡이가 둘이 된다).
	//   ⚠️ 1..8 만 뒤섞는다 ⇒ ★ 계급 히스토그램이 **치환**될 뿐이라 `H(낱말)` 과 `Î` 가 **불변**이다.
	//   ⚠️ 씨앗과 무관한 **상수 표**여야 한다 — 씨앗마다 다르면 「사상」이 아니라 「잡음」을 잰다.
	static constexpr uint32 kPerm[kWordCls] = { 0u, 5u, 1u, 7u, 3u, 8u, 2u, 4u, 6u };
	static constexpr uint32 kConstCls = 4u;

	// ⭐ 회차 162 — **낱말마다 자기 바닥을 갖는 두 쌍**이다.
	//   ⚠️ 141 이 잡은 함정(*"정보 0 인 낱말도 상수보다 낫다"* = 변동성 효과) 때문에
	//     바닥은 언제나 **그 낱말의 섞음**이지 상수가 아니다.
	//   ⭐ 회차 163 — 낱말 **셋** × (그 낱말 + 그 낱말의 섞음) = 팔 여섯
	static constexpr uint32 kArms = 8u;
	static constexpr uint32 kOracle = 0u, kOracleS = 1u, kMaxV = 2u, kMaxVS = 3u,
	                        kAutoN  = 4u, kAutoNS  = 5u, kAutoS = 6u, kAutoSS = 7u;
	// 시험 채점 마스크 — ⚠️ 판정은 **변화만**이고 나머지 둘은 **D11 보고용**이다.
	enum { kMChange = 0u, kMKeep = 1u, kMAll = 2u, kMNone = 3u };
	static constexpr uint32 kEvalsArm0 = 3u;

	static constexpr uint32 kOut = 2u;   // ⭐ 실행 2회(규율 37)

	enum { kEncInit, kEncTrain, kGather, kQuiesce, kBodyInit, kBodyTrain, kEval };

	inline static MLTP2Enc _E;
	inline static MLTModel _M;
	inline static MLTP3Ctx _trA, _pbA, _ptA;
	inline static bool _done = false, _banner = false, _encSetup = false, _finite = true;
	inline static bool _pending = false;
	inline static uint32 _seed = 0u, _st = kEncInit, _step = 0u;
	inline static uint32 _arm = 0u, _out = 0u, _evalIdx = 0u;
	inline static uint32 _cor = 0u, _gGrp = 0u, _gIdx = 0u, _qWait = 0u;
	inline static Array<float> _code, _norm;

	inline static Array<uint32> _wChTr, _wChTe;      // ⭐ ㈁ 「바뀌는 슬롯의 표적 id」 계급
	inline static Array<uint32> _wTr, _wTe;          // 지금 팔의 낱말
	inline static Array<float> _eVal[2], _eSym[2], _eTgt[2];
	inline static MLTEvalGate _gate;

	inline static float _ce[kOut][kArms][kSeedsMax];          // ⭐ 판정용(변화만)
	inline static float _ceKeep[kOut][kSeedsMax], _ceAll[kOut][kSeedsMax];   // 📊 D11
	inline static bool  _seedOk[kSeedsMax];
	inline static double _hW[kArms][kSeedsMax];               // 낱말 엔트로피(시험 코퍼스)
	// ⭐ 회차 175 — **조건부 천장**. 규율 66 의 진단법을 숫자로 만든다.
	inline static double _iW[kArms][kSeedsMax];               // Î(낱말 ; 변화 표적) — 학습 0
	inline static double _hT[kSeedsMax];                      // H(변화 표적) — 팔과 무관(검산)
	// ⭐ 회차 177 — 부채 D22. **같은 뭉갠 자**로 무조건부·조건부를 나란히.
	inline static double _iQu[kArms][kSeedsMax];              // Î(낱말;표적8)      — 문맥 없음
	inline static double _iQc[kArms][kSeedsMax];              // Î(낱말;표적8|직전8) — 문맥 있음
	inline static double _nScored[3][kSeedsMax];              // 마스크별 문맥당 채점 표적 수
	inline static uint32 _lastScored = 0u;

	static void _ToBody() { _qWait = MLTEvalGate::kDelay; _st = kQuiesce; }
	static const char* _ArmName(uint32 a)
	{
		switch (a)
		{
		case 0u: return "㈀ 오라클(천장)  ";
		case 1u: return "㈁ 오라클 섞음    ";
		case 2u: return "㈂ maxV           ";
		case 3u: return "㈃ maxV 섞음(바닥)";
		case 4u: return "㈄ 자율개수 ⭐ ";
		case 5u: return "㈅ 자율개수 섞음  ";
		case 6u: return "㈆ 자율슬롯 ⭐";
		default: return "㈇ 자율슬롯 섞음  ";
		}
	}
	static const char* _MaskName(uint32 m)
	{
		switch (m) { case kMChange: return "변화만"; case kMKeep: return "지속만"; default: return "전체"; }
	}
	static uint32 _SignPass() { return (_seeds * 10u + 11u) / 12u; }

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🎯 **회차 162 · 칸 10 의 첫 실측**(%s)\n", (_seeds == 1u) ? "⚠️ **1씨앗 진단**" : "⭐ 판정 회차");
		LogA("[mlt] 🎯   ⭐ 표제 = ***천장을 32배 올렸는데 `SE` 도 같이 올라가나***\n");
		LogA("[mlt] 🎯   손잡이 둘 — ㈎ 낱말을 **시각당 하나**(×8) · ㈏ 채점을 **변화 표적에만**(×4.6)\n");
		LogA("[mlt] 🎯   ⚠️ ㈏ 는 CE 를 4배로 올리고 표본을 1/4.6 로 줄인다 ⇒ **`SE` 가 따라 오르면 상쇄**된다\n");
		LogA("[mlt] 🎯   🎞️ 표현 = **%s** · 🌍 점 **%s**(`dt` ×%.3f · 자율진폭 ×%.2f · `hold` %d)\n",
			_deltaOn ? "델타(`-mltdelta`)" : "절대(기본)", _PtName(_pt),
			(double)kPtDt[_pt], (double)kPtAmp[_pt], kPtHold[_pt]);
		if (_pt == 7u)
		{
			LogA("[mlt] 🌍   ⭐ **회차 172 — 사람이 고른 세계 ㈇ 다**\n");
			LogA("[mlt] 🌍      변화 표적 **19.8** 중 **자율 몫 55%%**(기본 세계는 약 **0%%**)\n");
			LogA("[mlt] 🌍      ⚠️⚠️ 그러나 **지목은 그대로 없다**(회차 163) — 낱말은 시각당 **스칼라 하나**다\n");
			LogA("[mlt] 🌍      ⇒ ★ 그래서 이 회차가 가른다: ***몫이 병목인가 지목이 병목인가***\n");
			LogA("[mlt] 🌍         ⭐ 자율 낱말이 **서면** ⇒ 몫이 병목이었다 ⇒ 칸 10 이 열린다\n");
			LogA("[mlt] 🌍         ⛔ 여전히 **안 서면** ⇒ **지목**이 병목이다 ⇒ 낱말의 **모양**을 바꿔야 한다\n");
			LogA("[mlt] 🌍      ⚠️ 위험 — 잡음이 **45%%**(8.9/19.8)라 SE 가 커져 `t` 가 낮게 나올 수 있다\n");
		}
		LogA("[mlt] 🎯   ⭐ 표제 = ***문맥이 못 아는 낱말은 몸통이 쓰나*** (자율 몫 **%d/%d**)\n",
			_autoN, MLTWorldCfg::kShapes);
		LogA("[mlt] 🎯      ⚠️⚠️ 규율 59 — 회차 162 가 `maxV` 로 ⛔ 를 냈고 이유는 **낱말이 문맥의 요약**이어서다\n");
		LogA("[mlt] 🎯      ⭐ 그래서 이 회차는 **세계의 숨은 라벨**을 쓴다: `index < autoN` 이면 **자율**이다\n");
		LogA("[mlt] 🎯         ★ 화면에는 *\"카메라 운동 + 자기 원운동\"* 의 **합**만 나오고, 궤도 주기 37 스텝 중\n");
		LogA("[mlt] 🎯           문맥은 **8 프레임(21.6%%)** 만 본다 ⇒ 문맥이 가르기 어렵다 · ✅ **새는 말이 아니다**\n");
		LogA("[mlt] 🎯   팔 여덟 = **낱말 넷 × (그 낱말 + 그 낱말의 섞음)**\n");
		LogA("[mlt] 🎯      ㈀ **오라클**(표적 id 8분위 · ⚠️ 새는 말) · ㈁ 그 **섞음**  ⇒ **천장**\n");
		LogA("[mlt] 🎯      ㈂ **`maxV` 8분위** · ㈃ 그 **섞음**  ⇒ **162 재현**(절대 3.3%% · 델타 3.8%%)\n");
		LogA("[mlt] 🎯      ⭐ ㈄ **자율 개수**(화면에 보이는 자율 도형 수) · ㈅ 그 **섞음**  ⇒ **표제**\n");
		LogA("[mlt] 🎯      ⭐ ㈆ **자율 최대속력** 8분위(`maxV` 와 같은 식인데 **자율에만**) · ㈇ 그 **섞음**\n");
		LogA("[mlt] 🎯   ⚠️ 손계산(규율 21) — 작은 효과의 SE ≈ 0.0083 이므로 예상 `t`:\n");
		LogA("[mlt] 🎯      autoN=1(7.1%%) → **2.56**(아슬) · ⭐ autoN=3(21.4%%) → **7.69**(넉넉)\n");
		LogA("[mlt] 🎯   ⚠️⚠️ **바닥은 언제나 「그 낱말의 섞음」**이다 — 141 이 *\"정보 0 인 낱말도 상수보다 낫다\"*(변동성 효과)를 잡았다\n");
		LogA("[mlt] 🎯   ⚠️ `maxV` 8분위 경계는 **학습 코퍼스에서** 잡아 시험에 적용한다(시험에서 잡으면 훔쳐보기)\n");
		LogA("[mlt] 🎯   📏 자 = ⭐ **실현율 = (㈂−㈃) ÷ (㈀−㈁)** — 무차원이라 절대 ↔ 델타를 견준다\n");
		LogA("[mlt] 🎯      (`㈂−㈀ = −0.117` · `|d̄|/SE 9.73`) ⇒ **값이 늘 0 인 축은 죽은 축**이고 변동만으로 모델이 달라진다\n");
		LogA("[mlt] 🎯   ⚠️ **학습 풀은 안 건드린다** — 마스크는 **시험 풀에만**(바꾸는 것은 자이지 과제가 아니다)\n");
		LogA("[mlt] 🎯   ⭐ 관문 = **천장÷SE ≥ 10**(규율 49) · 표제 %u/%u 이고 |d̄|/SE ≥ 3 · 음성(㈃↔㈂) 구별 안 됨\n", _SignPass(), _seeds);
		LogA("[mlt] 🎯   ⭐ 예측 — 채점 12.4/문맥 · **천장÷SE ≫ 10** · 표제 |d̄| ≈ 1.07 나트(1씨앗 진단)\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

	// ── 인코더 · 코퍼스 (138~140 과 같다) ────────────────────────────
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
		MLTWorld w; w.Reset(_seed, 0u, kPtHold[_pt], _autoN, kPtDt[_pt], kPtAmp[_pt]);
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
		_cor = 0u; _gGrp = 0u; _gIdx = 0u; _pending = false; _st = kGather;
	}

	static uint32 _NCtxOf(uint32 c) { return (c == 0u) ? kNCtx : ((c == 1u) ? kPbCtx : kPtCtx); }
	static uint32 _EpiOf(uint32 c)  { return (c == 0u) ? kTrainEpi : ((c == 1u) ? kPbEpi : kPtEpi); }
	static MLTP3Ctx& _CorA(uint32 c) { return (c == 0u) ? _trA : ((c == 1u) ? _pbA : _ptA); }

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
			ImageFormat::Bitmap bmpA, bmpB; Bytes packed;
			const uint32 epi = _EpiOf(_cor);
			// ⭐ 원값 모음은 문맥 순서대로 쌓는다(이 블록이 그룹당 정확히 한 번 돈다)
			Array<float>* mvOut = (_cor == 0u) ? &_mvTrRaw : ((_cor == 2u) ? &_mvTeRaw : nullptr);
			Array<float>* anOut = (_cor == 0u) ? &_anTrRaw : ((_cor == 2u) ? &_anTeRaw : nullptr);
			Array<float>* asOut = (_cor == 0u) ? &_asTrRaw : ((_cor == 2u) ? &_asTeRaw : nullptr);
			// ⭐ 회차 173 — 자율 도형의 화면 패치를 모은다(슬롯 앵커와 맞추려고)
			Array<uint32>* apOut = (_cor == 0u) ? &_apTr : ((_cor == 2u) ? &_apTe : nullptr);
			if (apOut != nullptr && _gGrp == 0u) apOut->Reset(0);
			if (mvOut != nullptr && _gGrp == 0u) { mvOut->Reset(0); anOut->Reset(0); asOut->Reset(0); }
			for (uint32 g = 0; g < kGroup; ++g)
			{
				const uint32 ctx = _gGrp * kGroup + g;
				MLTWorld w; w.Reset(_seed, epi + ctx, kPtHold[_pt], _autoN, kPtDt[_pt], kPtAmp[_pt]);   // ⭐ 163
				for (int i = 0; i < MLTWorldCfg::kShapes; ++i) _pv[i] = false;   // ⚠️ 문맥마다 초기화
				for (uint32 t = 0; t < kTime; ++t)
				{
					w.Step();
					// ⭐ 회차 162 — 에피소드 첫 프레임은 **키프레임**이다
					ImageFormat::Bitmap& cur = (t % 2u == 0u) ? bmpA : bmpB;
					ImageFormat::Bitmap& prv = (t % 2u == 0u) ? bmpB : bmpA;
					if (!w.Render(cur)) { _Fail("Render(문맥)"); return; }
					const ImageFormat::Bitmap* pp = (_deltaOn && t > 0u) ? &prv : nullptr;
					if (!MLTWorld::Pack(cur, pp, packed)) { _Fail("Pack(문맥)"); return; }
					MLTP2Enc::AppendFrame(fr, tg, (const uint8*)packed.GetData());
					_CorA(_cor).StoreState(ctx, t, w.State());
					if (mvOut != nullptr)
					{
						float mv, an, as2;
						_WordStep(w, t, mv, an, as2);
						mvOut->Add(mv); anOut->Add(an); asOut->Add(as2);
						// ⭐ 회차 173 — 자율 도형의 화면 패치(없으면 kNoPatch)
						uint32 ap[kAutoMax];
						for (uint32 i = 0; i < kAutoMax; ++i) ap[i] = kNoPatch;
						{
							MLTShapeView vs[MLTWorldCfg::kShapes];
							const int nv = w.VisibleShapes(vs, MLTWorldCfg::kShapes);
							const float SS = (float)MLTWorldCfg::kSide;
							uint32 k = 0u;
							for (int i = 0; i < nv && k < kAutoMax; ++i)
							{
								if (vs[i].index < 0 || vs[i].index >= _autoN) continue;   // 자율만
								if (!(vs[i].sx >= 0.0f && vs[i].sx < SS
								   && vs[i].sy >= 0.0f && vs[i].sy < SS)) continue;
								// ⭐ 회차 174 — **덮는 패치를 전부** 담는다.
								//   ★ 도형 내부는 단색이라 델타가 **경계에만** 생긴다
								//     ⇒ 슬롯은 경계 패치에서 뽑히는데 중심 하나만 보면 안 맞는다.
								const float r = (vs[i].r > 0.5f) ? vs[i].r : 0.5f;
								float x0 = vs[i].sx - r, x1 = vs[i].sx + r;
								float y0 = vs[i].sy - r, y1 = vs[i].sy + r;
								if (x0 < 0.0f) x0 = 0.0f;  if (y0 < 0.0f) y0 = 0.0f;
								if (x1 > SS - 1.0f) x1 = SS - 1.0f;
								if (y1 > SS - 1.0f) y1 = SS - 1.0f;
								const uint32 gx0 = (uint32)x0 / MLTP2Cfg::kPatch;
								const uint32 gx1 = (uint32)x1 / MLTP2Cfg::kPatch;
								const uint32 gy0 = (uint32)y0 / MLTP2Cfg::kPatch;
								const uint32 gy1 = (uint32)y1 / MLTP2Cfg::kPatch;
								for (uint32 gy = gy0; gy <= gy1 && k < kAutoMax; ++gy)
									for (uint32 gx = gx0; gx <= gx1 && k < kAutoMax; ++gx)
										ap[k++] = gy * MLTP2Cfg::kGrid + gx;
							}
						}
						for (uint32 i = 0; i < kAutoMax; ++i) apOut->Add(ap[i]);
					}
					else { float a1, a2, a3; _WordStep(w, t, a1, a2, a3); }   // ⚠️ 차분 상태를 잇는다
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
		_ChangeWord(_trA, kNCtx,  _wChTr);
		_ChangeWord(_ptA, kPtCtx, _wChTe);
		_MaxVWords();   // ⭐ 회차 162
		_arm = 0u; _ToBody();
	}

	// ── ⭐ `maxV` — **최대속력**(프레임 차분 · 과거만) ────────────────
	//   ★ `MLTShapeView::index` 가 **도형 identity** 라 프레임 사이를 그것으로 짝지으면
	//     **세계를 한 줄도 안 고치고** 속도가 나온다(회차 157 이 만든 길).
	//   ⭐ 회차 163 — 낱말 **셋**을 한 번에 낸다(같은 차분을 두 번 하지 않는다).
	//     ⚠️ `index < _autoN` 이 곧 **자율**이다(`mltworld.cw` 의 `if (i < _autoN)`) ⇒ 세계 코드 0줄.
	static void _WordStep(MLTWorld& w, uint32 t, float& oMaxV, float& oAutoN, float& oAutoS)
	{
		MLTShapeView vs[MLTWorldCfg::kShapes];
		const int nv = w.VisibleShapes(vs, MLTWorldCfg::kShapes);
		const float SS = (float)MLTWorldCfg::kSide;
		float maxV = 0.0f, autoS = 0.0f; bool any = false, anyA = false;
		uint32 nAuto = 0u;
		for (int i = 0; i < nv; ++i)
		{
			if (!(vs[i].sx >= 0.0f && vs[i].sx < SS && vs[i].sy >= 0.0f && vs[i].sy < SS)) continue;
			const int id = vs[i].index;
			if (id < 0 || id >= MLTWorldCfg::kShapes) continue;
			const bool isAuto = (id < _autoN);
			if (isAuto) ++nAuto;                             // ⭐ ㈂ 자율 개수(차분 없이도 센다)
			if (t == 0u || !_pv[id]) continue;               // ⚠️ 이전 프레임이 없다
			const float vx = vs[i].sx - _px[id];
			const float vy = vs[i].sy - _py[id];
			const float spd = Sqrt(vx * vx + vy * vy);
			if (spd > maxV) maxV = spd;
			any = true;
			if (isAuto) { if (spd > autoS) autoS = spd; anyA = true; }   // ⭐ ㈄ 자율 최대속력
		}
		for (int i = 0; i < MLTWorldCfg::kShapes; ++i) _pv[i] = false;
		for (int i = 0; i < nv; ++i)
		{
			const int id = vs[i].index;
			if (id < 0 || id >= MLTWorldCfg::kShapes) continue;
			_px[id] = vs[i].sx; _py[id] = vs[i].sy; _pv[id] = true;
		}
		oMaxV  = any  ? maxV  : kMvUnknown;
		oAutoN = (float)nAuto;                             // ⚠️ 「모름」이 없다 — 늘 셀 수 있다
		oAutoS = anyA ? autoS : kMvUnknown;
	}

	// ⭐ 8분위 경계는 **학습 코퍼스에서** 잡는다(시험에서 잡으면 훔쳐보기다)
	static void _MaxVWords()
	{
		float bnd[kWordCls - 2u];   // 8계급 ⇒ 경계 7개
		_Quantiles(_mvTrRaw, bnd);
		_Classify(_mvTrRaw, bnd, _wMvTr);
		_Classify(_mvTeRaw, bnd, _wMvTe);
		// ⭐ ㈂ 자율 개수 — **값이 곧 계급**이다(0..autoN · 계급이 적어 `H` 가 작다)
		_CountWord(_anTrRaw, _wAnTr);
		_CountWord(_anTeRaw, _wAnTe);
		// ⭐ ㈄ 자율 최대속력 — `maxV` 와 **같은 식**(경계는 자기 학습 분포에서)
		_Quantiles(_asTrRaw, bnd);
		_Classify(_asTrRaw, bnd, _wAsTr);
		_Classify(_asTeRaw, bnd, _wAsTe);
		// ⭐ 회차 173 — **자율 슬롯 번호**(지목) · 0 = 없음 · 1..kSlots
		_SlotWord(_trA, kNCtx,  _apTr, _wSlTr);
		_SlotWord(_ptA, kPtCtx, _apTe, _wSlTe);
	}

	// ⭐ 회차 173 — **지목 낱말**: 자율 도형이 앉은 슬롯 중 **가장 작은 번호** + 1.
	//   ★ 슬롯 j 의 앵커 패치(`Anc`)가 자율 도형의 화면 패치와 같으면 그 슬롯이 자율이다.
	//   ⚠️ 계급 9(0 = 없음 · 1..8) ⇒ `kWordCls` 와 딱 맞아 **축도 계급도 안 는다**.
	static void _SlotWord(const MLTP3Ctx& C, uint32 nCtx,
		const Array<uint32>& ap, Array<uint32>& w)
	{
		w.Reset(0);
		for (uint32 ctx = 0; ctx < nCtx; ++ctx)
			for (uint32 tt = 0; tt < kTime; ++tt)
			{
				const uint32 fb = (ctx * kTime + tt) * kAutoMax;
				uint32 cls = 0u;
				for (uint32 j = 0; j < kSlots && cls == 0u; ++j)
				{
					const uint32 anc = C.Anc(ctx, tt, j);
					for (uint32 i = 0; i < kAutoMax; ++i)
					{
						if (fb + i >= ap.Count()) break;
						if (ap[fb + i] == kNoPatch) continue;
						if (ap[fb + i] == anc) { cls = j + 1u; break; }
					}
				}
				w.Add(cls);
			}
	}

	static void _CountWord(const Array<float>& raw, Array<uint32>& w)
	{
		w.Reset(0);
		for (uint32 i = 0; i < raw.Count(); ++i)
		{
			int c = (int)raw[i];
			if (c < 0) c = 0;
			if (c > (int)(kWordCls - 1u)) c = (int)(kWordCls - 1u);
			w.Add((uint32)c);
		}
	}

	// ⭐ 8분위 경계 — **학습 코퍼스에서만** 잡는다(시험에서 잡으면 훔쳐보기)
	static void _Quantiles(const Array<float>& trRaw, float* bnd)
	{
		Array<float> v; v.Reset(0);
		for (uint32 i = 0; i < trRaw.Count(); ++i)
			if (trRaw[i] > kMvUnknown * 0.5f) v.Add(trRaw[i]);
		// 셸 정렬(한 씨앗에 한 번 · n ≈ 4천)
		for (uint32 gap = v.Count() / 2u; gap > 0u; gap /= 2u)
			for (uint32 i = gap; i < v.Count(); ++i)
			{
				const float key = v[i]; uint32 j = i;
				while (j >= gap && v[j - gap] > key) { v.Data()[j] = v[j - gap]; j -= gap; }
				v.Data()[j] = key;
			}
		for (uint32 k = 0; k < kWordCls - 2u; ++k)
		{
			const uint32 idx = (v.Count() * (k + 1u)) / (kWordCls - 1u);
			bnd[k] = (v.Count() == 0u) ? 0.0f : v[(idx >= v.Count()) ? (v.Count() - 1u) : idx];
		}
	}

	static void _Classify(const Array<float>& raw, const float* bnd, Array<uint32>& w)
	{
		w.Reset(0);
		for (uint32 i = 0; i < raw.Count(); ++i)
		{
			if (!(raw[i] > kMvUnknown * 0.5f)) { w.Add(0u); continue; }   // 모름
			uint32 c = 1u;
			for (uint32 k = 0; k < kWordCls - 2u; ++k) if (raw[i] > bnd[k]) c = k + 2u;
			w.Add(c);
		}
	}

	// ── ⭐ 낱말 — **시각당 하나**. 「그 시각에 바뀌는 첫 슬롯의 표적 id」의 8분위(+1). ──
	//   ⚠️ 0 = 「그 시각에 바뀌는 슬롯이 없다」 ⇒ 그 자체도 정보다(그리고 그 시각엔 채점거리가 없다).
	static void _ChangeWord(const MLTP3Ctx& C, uint32 nCtx, Array<uint32>& w)
	{
		w.Reset(0);
		for (uint32 ctx = 0; ctx < nCtx; ++ctx)
			for (uint32 t = 0; t < kTime; ++t)
			{
				const uint32 b = MLTP3Ctx::Row(ctx, t, kStateAx);
				uint32 cls = 0u;
				for (uint32 j = 0; j < kSlots; ++j)
				{
					const float tf = C.Tgt()[b + j];
					if (!(tf >= 0.0f && tf < (float)kN)) continue;
					const uint32 tid = (uint32)tf;
					if ((uint32)(C.Sym()[b + j] - (float)kStateAx) == tid) continue;   // 지속 — 건너뛴다
					cls = 1u + (tid * (kWordCls - 1u)) / kN;
					break;
				}
				// ⭐ 회차 176 — 사상만 단조 → 임의로. **정보량은 불변**이다.
				if (_permOn) cls = kPerm[cls];
				w.Add(cls);
			}
	}

	// ── ⭐ 회차 175 — **조건부 천장** `Î(낱말 ; 변화 표적)` ────────────
	//   ★ 규율 66 의 진단법: *"이 낱말이 결정되면 표적 후보가 몇 개로 줄나"* 를 숫자로.
	//   ⚠️ **문맥 없이** 재므로 상한이다(규율 59) — 작으면 그것으로 끝이고, 크면 몸통 문제다.
	//   ⚠️ 표본 부족 편향(칸 9x250)은 **섞음 팔이 그대로 재 준다** ⇒ 짝을 빼면 남는 것이 정보다.
	//   ⚠️ 지속 표적은 뺀다 — **판정하는 자(`kMChange`)와 같은 표적**이어야 뜻이 맞는다.
	// ── ⭐ 회차 177 — **조건부** `Î(낱말 ; 표적 | 문맥)` (부채 D22) ──────
	//   ⚠️ 규율 59 가 **회차 162** 에 요구한 자인데 175 까지 잰 것은 전부 **무조건부**였다.
	//   ⭐ 문맥의 대리 = **직전 시각의 그 슬롯 id** — 그것이 「지속인가 변화인가」와
	//     「무엇에서」를 이미 안다(몸통은 그보다 더 알지만, 이것이 **가장 싼 하한**이다).
	//   ⚠️ 표본: 9 × 250 × 250 은 못 쓴다(칸 56만 · 표본 1.8만) ⇒ ★ 표적과 직전을
	//     **8분위로 뭉갠다**(9 × 8 × 8 = 576 칸 ⇒ 칸당 31개) ⇒ 편향은 섞음 짝이 뺀다.
	//   ⚠️⚠️ **뭉개면 `Î` 의 절대값이 줄어든다**(표적이 250 → 8) ⇒ ★ 그래서 판정은
	//     **같은 뭉갠 자로 잰 무조건부와의 비**로 한다(규율 58 — 무차원).
	static constexpr uint32 kQ = 8u;                 // 뭉개는 칸 수
	static uint32 _Q(uint32 tid) { return (tid * kQ) / kN; }
	static void _MutInfoCond(const MLTP3Ctx& C, uint32 nCtx, const Array<uint32>& w,
		double& oIuc, double& oIc)
	{
		// jt[cls][prevQ][tgtQ] · 문맥 없는 짝은 prevQ 를 합친다
		Array<uint32> jt; jt.Reset(0);
		for (uint32 i = 0; i < kWordCls * kQ * kQ; ++i) jt.Add(0u);
		uint32 tot = 0u;
		for (uint32 ctx = 0; ctx < nCtx; ++ctx)
			for (uint32 t = 0; t < kTime; ++t)
			{
				const uint32 wi = ctx * kTime + t;
				const uint32 cls = (w.Count() > wi) ? (w[wi] % kWordCls) : 0u;
				const uint32 b = MLTP3Ctx::Row(ctx, t, kStateAx);
				for (uint32 j = 0; j < kSlots; ++j)
				{
					const float tf = C.Tgt()[b + j];
					if (!(tf >= 0.0f && tf < (float)kN)) continue;
					const uint32 tid = (uint32)tf;
					// ⭐ 문맥의 대리 = **지금 그 슬롯에 있는 id**(= 직전 시각의 표적)
					const float sf = C.Sym()[b + j] - (float)kStateAx;
					if (!(sf >= 0.0f && sf < (float)kN)) continue;
					const uint32 pid = (uint32)sf;
					if (pid == tid) continue;                       // 지속 제외(판정하는 자와 같게)
					jt.Data()[(cls * kQ + _Q(pid)) * kQ + _Q(tid)] += 1u;
					++tot;
				}
			}
		oIuc = 0.0; oIc = 0.0;
		if (tot == 0u) return;
		const double N = (double)tot;
		// ① 무조건부 — 같은 **뭉갠** 자로(규율 58: 비교는 같은 자 안에서만)
		{
			Array<uint32> mw; mw.Reset(0);
			for (uint32 i = 0; i < kWordCls; ++i) mw.Add(0u);
			Array<uint32> mt; mt.Reset(0);
			for (uint32 i = 0; i < kQ; ++i) mt.Add(0u);
			Array<uint32> j2; j2.Reset(0);
			for (uint32 i = 0; i < kWordCls * kQ; ++i) j2.Add(0u);
			for (uint32 c = 0; c < kWordCls; ++c)
				for (uint32 p = 0; p < kQ; ++p)
					for (uint32 q = 0; q < kQ; ++q)
					{
						const uint32 n = jt[(c * kQ + p) * kQ + q];
						if (n == 0u) continue;
						j2.Data()[c * kQ + q] += n; mw.Data()[c] += n; mt.Data()[q] += n;
					}
			for (uint32 c = 0; c < kWordCls; ++c)
			{
				if (mw[c] == 0u) continue;
				const double pw = (double)mw[c] / N;
				for (uint32 q = 0; q < kQ; ++q)
				{
					const uint32 n = j2[c * kQ + q];
					if (n == 0u) continue;
					const double pj = (double)n / N, pt = (double)mt[q] / N;
					oIuc += pj * (double)Log((float)(pj / (pw * pt)));
				}
			}
		}
		// ② 조건부 — 문맥(직전 분위)마다 따로 재고 그 무게로 섞는다
		for (uint32 p = 0; p < kQ; ++p)
		{
			uint32 np = 0u;
			Array<uint32> mw; mw.Reset(0);
			for (uint32 i = 0; i < kWordCls; ++i) mw.Add(0u);
			Array<uint32> mt; mt.Reset(0);
			for (uint32 i = 0; i < kQ; ++i) mt.Add(0u);
			for (uint32 c = 0; c < kWordCls; ++c)
				for (uint32 q = 0; q < kQ; ++q)
				{
					const uint32 n = jt[(c * kQ + p) * kQ + q];
					if (n == 0u) continue;
					mw.Data()[c] += n; mt.Data()[q] += n; np += n;
				}
			if (np == 0u) continue;
			const double Np = (double)np;
			double ip = 0.0;
			for (uint32 c = 0; c < kWordCls; ++c)
			{
				if (mw[c] == 0u) continue;
				const double pw = (double)mw[c] / Np;
				for (uint32 q = 0; q < kQ; ++q)
				{
					const uint32 n = jt[(c * kQ + p) * kQ + q];
					if (n == 0u) continue;
					const double pj = (double)n / Np, pt = (double)mt[q] / Np;
					ip += pj * (double)Log((float)(pj / (pw * pt)));
				}
			}
			oIc += (Np / N) * ip;
		}
	}

	static void _MutInfo(const MLTP3Ctx& C, uint32 nCtx, const Array<uint32>& w,
		double& oI, double& oHt)
	{
		Array<uint32> jt; jt.Reset(0);
		for (uint32 i = 0; i < kWordCls * kN; ++i) jt.Add(0u);
		Array<uint32> mw; mw.Reset(0);
		for (uint32 i = 0; i < kWordCls; ++i) mw.Add(0u);
		Array<uint32> mt; mt.Reset(0);
		for (uint32 i = 0; i < kN; ++i) mt.Add(0u);
		uint32 tot = 0u;
		for (uint32 ctx = 0; ctx < nCtx; ++ctx)
			for (uint32 t = 0; t < kTime; ++t)
			{
				const uint32 wi = ctx * kTime + t;
				const uint32 cls = (w.Count() > wi) ? (w[wi] % kWordCls) : 0u;
				const uint32 b = MLTP3Ctx::Row(ctx, t, kStateAx);
				for (uint32 j = 0; j < kSlots; ++j)
				{
					const float tf = C.Tgt()[b + j];
					if (!(tf >= 0.0f && tf < (float)kN)) continue;
					const uint32 tid = (uint32)tf;
					if ((uint32)(C.Sym()[b + j] - (float)kStateAx) == tid) continue;   // 지속 제외
					++jt.Data()[cls * kN + tid];
					++mw.Data()[cls];
					++mt.Data()[tid];
					++tot;
				}
			}
		oI = 0.0; oHt = 0.0;
		if (tot == 0u) return;
		const double N = (double)tot;
		for (uint32 i = 0; i < kN; ++i)
		{
			if (mt[i] == 0u) continue;
			const double p = (double)mt[i] / N;
			oHt += -p * (double)Log((float)p);
		}
		for (uint32 c = 0; c < kWordCls; ++c)
		{
			if (mw[c] == 0u) continue;
			const double pw = (double)mw[c] / N;
			for (uint32 i = 0; i < kN; ++i)
			{
				const uint32 n = jt[c * kN + i];
				if (n == 0u) continue;
				const double pj = (double)n / N;
				const double pt = (double)mt[i] / N;
				oI += pj * (double)Log((float)(pj / (pw * pt)));
			}
		}
	}

	static void _Shuffle(const Array<uint32>& in, Array<uint32>& out, uint32 salt)
	{
		out.Reset(0);
		for (uint32 i = 0; i < in.Count(); ++i) out.Add(in[i]);
		uint32 rs = _seed * 2654435761u + salt;
		for (uint32 i = out.Count(); i > 1u; --i)
		{
			rs = rs * 1664525u + 1013904223u;
			const uint32 j = rs % i;
			const uint32 tmp = out[i - 1u]; out.Data()[i - 1u] = out[j]; out.Data()[j] = tmp;
		}
	}

	// ── 13축 → 14축(낱말을 **축 0** 에) + ⭐ 시험 채점 마스크 ────────────
	//   ⚠️ 낱말은 **축 0** 이어야 한다 — 몸통이 causal 이고 행 순서가 `t*축 + a` 다(회차 132 의 진단).
	//   ⚠️ 낱말 색인이 **`ctx*kTime + t`** 다(회차 141 의 손잡이 ㈎ — 138·139 는 `ctx` 였다).
	static void _Expand(const MLTP3Ctx& C, uint32 nCtx, const Array<uint32>& word, uint32 mask,
		Array<float>& oVal, Array<float>& oSym, Array<float>& oTgt)
	{
		const uint32 steps = nCtx / kBatch;
		const uint32 n = steps * kRows14;
		oVal.Reset(0); oSym.Reset(0); oTgt.Reset(0);
		for (uint32 i = 0; i < n; ++i) { oVal.Add(0.0f); oSym.Add(0.0f); oTgt.Add((float)kN); }
		uint32 scored = 0u;
		for (uint32 ctx = 0; ctx < nCtx; ++ctx)
		{
			const uint32 k = ctx / kBatch, b = ctx % kBatch;
			for (uint32 t = 0; t < kTime; ++t)
			{
				const uint32 src = MLTP3Ctx::Row(ctx, t, 0u);
				const uint32 dst = k * kRows14 + b * kCtx14 + t * kAx14;
				const uint32 wi = ctx * kTime + t;
				const uint32 cls = (word.Count() > wi) ? word[wi] : kConstCls;
				oVal.Data()[dst] = ((float)cls / (float)(kWordCls - 1u)) * 2.0f - 1.0f;
				oSym.Data()[dst] = kWordSym;
				oTgt.Data()[dst] = (float)kN;                       // IgnoreTgt
				for (uint32 a = 0; a < kAx13; ++a)
				{
					oVal.Data()[dst + 1u + a] = C.Val()[src + a];
					oSym.Data()[dst + 1u + a] = C.Sym()[src + a];
					float tf = C.Tgt()[src + a];
					// ⭐ 손잡이 ㈏ — **시험 채점 마스크**(학습에는 안 건다)
					if (mask != kMNone && a >= kStateAx && tf >= 0.0f && tf < (float)kN)
					{
						const uint32 tid = (uint32)tf;
						const bool keep = ((uint32)(C.Sym()[src + a] - (float)kStateAx) == tid);
						if ((mask == kMChange && keep) || (mask == kMKeep && !keep)) tf = (float)kN;
					}
					if (tf >= 0.0f && tf < (float)kN) ++scored;
					oTgt.Data()[dst + 1u + a] = tf;
				}
			}
		}
		_lastScored = scored;
	}

	static void _MakeArmPools()
	{
		const uint32 a = _arm;
		if (a == kOracle)      { _wTr = _wChTr; _wTe = _wChTe; }
		else if (a == kMaxV)   { _wTr = _wMvTr; _wTe = _wMvTe; }
		else if (a == kAutoN)  { _wTr = _wAnTr; _wTe = _wAnTe; }
		else if (a == kAutoS)  { _wTr = _wSlTr; _wTe = _wSlTe; }   // ⭐ 173 — 지목 낱말
		else
		{
			// ⭐ 각 낱말의 **자기 바닥** — 같은 주변분포 · 같은 변동성 · 정보만 0
			const Array<uint32>* bTr = &_wChTr; const Array<uint32>* bTe = &_wChTe;
			uint32 s0 = 11u, s1x = 22u;
			if (a == kMaxVS)  { bTr = &_wMvTr; bTe = &_wMvTe; s0 = 33u; s1x = 44u; }
			if (a == kAutoNS) { bTr = &_wAnTr; bTe = &_wAnTe; s0 = 55u; s1x = 66u; }
			if (a == kAutoSS) { bTr = &_wSlTr; bTe = &_wSlTe; s0 = 77u; s1x = 88u; }   // ⭐ 173
			Array<uint32> s1, s2;
			_Shuffle(*bTr, s1, s0); _Shuffle(*bTe, s2, s1x);
			_wTr = s1; _wTe = s2;
		}
		// 낱말 엔트로피(시험 코퍼스) — ⭐ 천장의 분자다
		Array<uint32> h; h.Reset(0);
		for (uint32 i = 0; i < kWordCls; ++i) h.Add(0u);
		for (uint32 i = 0; i < _wTe.Count(); ++i) ++h.Data()[_wTe[i] % kWordCls];
		double e = 0.0;
		for (uint32 i = 0; i < kWordCls; ++i)
		{
			if (h[i] == 0u) continue;
			const double p = (double)h[i] / (double)_wTe.Count();
			e += -p * (double)Log((float)p);
		}
		_hW[a][_seed] = e;
		// ⭐ 회차 175 — **조건부 천장**(학습 0 · 재는 데 몸통이 필요 없다)
		double mi = 0.0, ht = 0.0;
		_MutInfo(_ptA, kPtCtx, _wTe, mi, ht);
		_iW[a][_seed] = mi;
		_hT[_seed] = ht;                                                    // 팔과 무관 — 덮어써도 같다
		// ⭐ 회차 177 — 부채 D22. 같은 pass 라 값이 0 이다.
		double iqu = 0.0, iqc = 0.0;
		_MutInfoCond(_ptA, kPtCtx, _wTe, iqu, iqc);
		_iQu[a][_seed] = iqu; _iQc[a][_seed] = iqc;
		_Expand(_trA, kNCtx, _wTr, kMNone, _eVal[0], _eSym[0], _eTgt[0]);   // ⚠️ 학습은 마스크 없음
	}

	static bool _UploadTest(uint32 mask)
	{
		_Expand(_ptA, kPtCtx, _wTe, mask, _eVal[1], _eSym[1], _eTgt[1]);
		if (_arm == 0u && _out == 0u) _nScored[mask][_seed] = (double)_lastScored / (double)kPtCtx;
		return _M.UploadPool(_eVal[1], _eTgt[1], kPtPool) && _M.UploadSymbolPool(_eSym[1], kPtPool);
	}

	static void _BodyBegin(RHI* rhi)
	{
		if (!_M.Setup(rhi, kSymA, kN, kAx14, kTime)) { _Fail("몸통 준비"); return; }
		_MakeArmPools();
		if (!(_M.UploadPool(_eVal[0], _eTgt[0], kPoolSteps) && _M.UploadSymbolPool(_eSym[0], kPoolSteps)))
		{ _Fail("학습 풀 업로드"); return; }
		_step = 0u; _st = kBodyTrain;
	}

	static void _BodyTrain()
	{
		if (_step >= kSteps)
		{
			_evalIdx = 0u;
			if (!_UploadTest(kMChange)) { _Fail("시험 풀 업로드"); return; }
			_gate.Begin(kPtPool); _st = kEval; return;
		}
		for (uint32 i = 0; i < kPerTick && _step < kSteps; ++i)
		{
			_M.SelectStep(_step % kPoolSteps);
			if (!_M.Forward() || !_M.Backward() || !_M.AdamStep(1.0f)) { _Fail("몸통 스텝"); return; }
			++_step;
		}
	}

	static void _EvalStep()
	{
		bool fail = false;
		if (!_gate.Step(_M, fail)) return;
		if (fail) { _Fail("평가 리드백"); return; }
		const float ce = _gate.Mean();
		if (!(ce == ce) || ce > 1.0e30f) _finite = false;

		if (_evalIdx == 0u)
		{
			_ce[_out][_arm][_seed] = ce;
			LogA("[mlt] 🎯   %s 씨앗 %2u · 바깥 %u · **변화만 CE %.5f**(채점 %.1f/문맥)\n",
				_ArmName(_arm), _seed, _out, (double)ce, _nScored[kMChange][_seed]);
		}
		else if (_evalIdx == 1u) { _ceKeep[_out][_seed] = ce; }
		else                      { _ceAll[_out][_seed] = ce; }

		// 📊 D11 — ㈀ 팔에서만 마스크 셋을 다 잰다
		if (_arm == 0u && _evalIdx + 1u < kEvalsArm0)
		{
			++_evalIdx;
			const uint32 m = (_evalIdx == 1u) ? kMKeep : kMAll;
			if (!_UploadTest(m)) { _Fail("D11 시험 풀 업로드"); return; }
			_gate.Begin(kPtPool); return;
		}
		if (_arm == 0u && _evalIdx + 1u == kEvalsArm0)
			LogA("[mlt] 🎯   📊 **D11** 씨앗 %2u · 바깥 %u — 지속만 **%.5f**(%.1f/문맥) · 전체 **%.5f**(%.1f/문맥)\n",
				_seed, _out, (double)_ceKeep[_out][_seed], _nScored[kMKeep][_seed],
				(double)_ceAll[_out][_seed], _nScored[kMAll][_seed]);

		if (++_arm < kArms) { _ToBody(); return; }
		_arm = 0u;
		if (++_out < kOut) { _ToBody(); return; }
		_out = 0u;
		_seedOk[_seed] = _finite;
		++_seed; _st = kEncInit;
	}

	// ── 짝지은 차 — ⭐ SE 에 **실행 잡음 항**(규율 29·37) ─────────────
	static double _M2(uint32 a, uint32 s)
	{
		double v = 0.0;
		for (uint32 o = 0; o < kOut; ++o) v += (double)_ce[o][a][s];
		return v / (double)kOut;
	}

	struct Pair { double d; double se; double t; double sdSeed; double sdRun; uint32 n; uint32 win; };

	static Pair _Paired(uint32 aX, uint32 aY)
	{
		Pair p{}; p.d = 0.0; p.se = 0.0; p.t = 0.0; p.sdSeed = 0.0; p.sdRun = 0.0; p.n = 0u; p.win = 0u;
		double dv[kSeedsMax]; double rs = 0.0;
		for (uint32 s = 0; s < _seeds; ++s)
		{
			if (!_seedOk[s]) continue;
			const double d = _M2(aX, s) - _M2(aY, s);
			dv[p.n] = d; p.d += d; ++p.n;
			if (d < 0.0) ++p.win;
			const double r0 = (double)_ce[0][aX][s] - (double)_ce[0][aY][s];
			const double r1 = (double)_ce[1][aX][s] - (double)_ce[1][aY][s];
			rs += Abs((float)(r1 - r0)) / 1.414213562;
		}
		if (p.n == 0u) return p;
		p.d /= (double)p.n;
		double vv = 0.0;
		for (uint32 i = 0; i < p.n; ++i) { const double e = dv[i] - p.d; vv += e * e; }
		p.sdSeed = (p.n > 1u) ? Sqrt((float)(vv / (double)(p.n - 1u))) : 0.0;
		p.sdRun = rs / (double)p.n;
		const double v = (p.sdSeed * p.sdSeed) / (double)p.n
			+ (p.sdRun * p.sdRun) / ((double)p.n * (double)kOut);
		p.se = Sqrt((float)v);
		p.t = (p.se > 1.0e-12) ? (Abs(p.d) / p.se) : 0.0;
		return p;
	}

	static double _MeanOf(const double* v)
	{
		double m = 0.0; uint32 n = 0u;
		for (uint32 s = 0; s < _seeds; ++s) { if (!_seedOk[s]) continue; m += v[s]; ++n; }
		return (n == 0u) ? 0.0 : m / (double)n;
	}

	static void _Summary()
	{
		uint32 ok = 0u;
		for (uint32 s = 0; s < _seeds; ++s) if (_seedOk[s]) ++ok;
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🎯 **회차 162 · 칸 10 의 첫 실측** (씨앗 %u/%u · 유한 %s)\n", ok, _seeds, _finite ? "✅" : "⛔");

		// ① 채점 자리 + D11
		double nCh = 0.0, nKe = 0.0, nAl = 0.0; uint32 nn = 0u;
		for (uint32 s = 0; s < _seeds; ++s)
		{
			if (!_seedOk[s]) continue;
			nCh += _nScored[kMChange][s]; nKe += _nScored[kMKeep][s]; nAl += _nScored[kMAll][s]; ++nn;
		}
		if (nn > 0u) { nCh /= (double)nn; nKe /= (double)nn; nAl /= (double)nn; }
		double ceK = 0.0, ceA = 0.0; uint32 mm = 0u;
		for (uint32 s = 0; s < _seeds; ++s)
		{
			if (!_seedOk[s]) continue;
			for (uint32 o = 0; o < kOut; ++o) { ceK += (double)_ceKeep[o][s]; ceA += (double)_ceAll[o][s]; }
			mm += kOut;
		}
		if (mm > 0u) { ceK /= (double)mm; ceA /= (double)mm; }
		double ceCh = 0.0; uint32 cc = 0u;
		for (uint32 s = 0; s < _seeds; ++s) { if (!_seedOk[s]) continue; ceCh += _M2(0u, s); ++cc; }
		if (cc > 0u) ceCh /= (double)cc;

		LogA("[mlt] 🎯   ── ① 채점 자리 + 📊 **D11**(㈀ 팔) ──\n");
		LogA("[mlt] 🎯     문맥당 채점 표적 — **변화만 %.1f** · 지속만 %.1f · 전체 %.1f\n", nCh, nKe, nAl);
		LogA("[mlt] 🎯     ㈀ 팔 CE       — **변화만 %.4f** · 지속만 **%.4f** · 전체 **%.4f**\n", ceCh, ceK, ceA);
		LogA("[mlt] 🎯     ⭐ 검산: `지속몫×지속CE + 변화몫×변화CE` = %.4f (전체 %.4f 와 맞아야)\n",
			(nAl > 1.0e-9) ? (nKe / nAl) * ceK + (nCh / nAl) * ceCh : 0.0, ceA);

		// ② 짝지은 차
		// ⚠️ **바닥은 ㈂(섞음A)이다** — 1씨앗 진단이 *"상수 팔 대비로 재면 정보 0 인 낱말도 돕는다"* 를 잡았다.
		// ⭐ 회차 162 — 두 쌍이다. **천장**(오라클) ↔ **표제**(`maxV`)
		const Pair pCap = _Paired(kOracle, kOracleS);   // ⭐ ㈀ − ㈁ : **천장**
		const Pair pMv  = _Paired(kMaxV,   kMaxVS);     // ㈂ − ㈃ : `maxV`(162 재현 상대)
		const Pair pTop = _Paired(kAutoN,  kAutoNS);    // ⭐ ㈄ − ㈅ : **표제**(자율 개수)
		const Pair pAs  = _Paired(kAutoS,  kAutoSS);    // ⭐ ㈆ − ㈇ : 자율 최대속력(예측 ㉣)
		const Pair pMix = _Paired(kMaxVS,  kOracleS);   // ⓘ 두 섞음끼리(보고 — 주변분포가 다르다)
		LogA("[mlt] 🎯   ── ② **짝지은 차**(음수 = 왼쪽이 낫다) · SE 에 **실행 항** 포함 ──\n");
		LogA("[mlt] 🎯     견줌                │ d̄        · sd_씨앗 · sd_run  · SE      · **|d̄|/SE** · 이긴 씨앗\n");
		LogA("[mlt] 🎯     ⭐ ㈀−㈁ **천장**   │ %+.5f · %.5f · %.5f · %.5f · **%6.2f** · %u/%u\n",
			pCap.d, pCap.sdSeed, pCap.sdRun, pCap.se, pCap.t, pCap.win, pCap.n);
		LogA("[mlt] 🎯     ㈂−㈃ `maxV`         │ %+.5f · %.5f · %.5f · %.5f · **%6.2f** · %u/%u\n",
			pMv.d, pMv.sdSeed, pMv.sdRun, pMv.se, pMv.t, pMv.win, pMv.n);
		LogA("[mlt] 🎯     ⭐ ㈄−㈅ **표제** │ %+.5f · %.5f · %.5f · %.5f · **%6.2f** · %u/%u\n",
			pTop.d, pTop.sdSeed, pTop.sdRun, pTop.se, pTop.t, pTop.win, pTop.n);
		LogA("[mlt] 🎯     ⭐ ㈆−㈇ **자율슬롯**│ %+.5f · %.5f · %.5f · %.5f · **%6.2f** · %u/%u\n",
			pAs.d, pAs.sdSeed, pAs.sdRun, pAs.se, pAs.t, pAs.win, pAs.n);
		LogA("[mlt] 🎯     ⓘ ㈃−㈁ 두 섞음     │ %+.5f · %.5f · %.5f · %.5f · **%6.2f** · %u/%u  ⚠️ 주변분포가 다르니 갈릴 수 있다(보고)\n",
			pMix.d, pMix.sdSeed, pMix.sdRun, pMix.se, pMix.t, pMix.win, pMix.n);
		// ⚠️⚠️ **검산은 씨앗 3 이상에서만**(규율 51) — 1씨앗 값을 **12씨앗 평균**에 대면
		//   회차 143 이 밟은 그 함정이다(씨앗 분산이 0.28~0.59 나트다).
		// ⚠️ 회차 172 — 점 0(기본 세계)에서만 검산한다(다른 점은 세계가 다르다 · 규율 57)
		const bool chkApply = (_seeds >= 3u) && !_deltaOn && (_pt == 0u);
		const double cChk = Abs((float)(pCap.d + 0.81680));
		const bool gChk = !chkApply || (cChk <= 0.08);
		if (_deltaOn)
			LogA("[mlt] 🎯     ⚠️⚠️ **검산 건너뜀** — 141 의 −0.8168 은 **절대판 값**이다(규율 57)\n");
		else
			LogA("[mlt] 🎯     ⭐ **검산** — 천장 d̄ **%+.5f** ↔ 141 의 **−0.81680 ± 0.08** · 차 %.4f → %s\n",
				pCap.d, cChk,
				!chkApply ? "⚠️ 건너뜀(씨앗 3 이상에서만 — 규율 51)"
					: (gChk ? "✅" : "⛔ **141 과 다르다**"));

		// ③ ⭐ 천장(규율 49)
		const double hOra = _MeanOf(_hW[kOracle]);
		const double hMv  = _MeanOf(_hW[kMaxV]);
		const double hAn  = _MeanOf(_hW[kAutoN]);
		const double hAs  = _MeanOf(_hW[kAutoS]);
		const double capO = (nCh > 1.0e-9) ? ((double)kTime * hOra) / nCh : 0.0;
		const double capM = (nCh > 1.0e-9) ? ((double)kTime * hMv)  / nCh : 0.0;
		const double capSE = (pCap.se > 1.0e-12) ? capO / pCap.se : 0.0;
		// ⭐ **실현율** = 표제 d̄ ÷ 천장 d̄ ⇒ ★ 칸 10 의 자(무차원 · 표현 사이를 견줄 수 있다)
		const double realz = (Abs((float)pCap.d) > 1.0e-9)
			? 100.0 * Abs((float)pTop.d) / Abs((float)pCap.d) : 0.0;
		LogA("[mlt] 🎯   ── ③ ⭐ **천장과 실현율**(규율 49) ──\n");
		LogA("[mlt] 🎯     H(㈀ 오라클) **%.4f** × 시각 %u ÷ 채점 %.1f = 정보천장 **%.4f** 나트\n", hOra, kTime, nCh, capO);
		LogA("[mlt] 🎯     H(㈂ `maxV`) **%.4f** × 시각 %u ÷ 채점 %.1f = 정보천장 **%.4f** 나트\n", hMv, kTime, nCh, capM);
		LogA("[mlt] 🎯     H(㈄ 자율개수) **%.4f** × 시각 %u ÷ 채점 %.1f = 정보천장 **%.4f** 나트\n",
			hAn, kTime, nCh, (nCh > 1.0e-9) ? ((double)kTime * hAn) / nCh : 0.0);
		LogA("[mlt] 🎯     H(㈆ 자율슬롯) **%.4f** × 시각 %u ÷ 채점 %.1f = 정보천장 **%.4f** 나트\n",
			hAs, kTime, nCh, (nCh > 1.0e-9) ? ((double)kTime * hAs) / nCh : 0.0);
		LogA("[mlt] 🎯     **천장 ÷ SE = %.1f**(관문 ≥10 · 옛 자는 3.28 — 회차 140)\n", capSE);
		LogA("[mlt] 🎯     ⓘ 오라클 자신의 실현율 = |천장 d̄| / 정보천장 = **%.1f%%**(141 은 93.0%%)\n",
			(capO > 1.0e-12) ? 100.0 * Abs((float)pCap.d) / capO : 0.0);
		const double realzMv = (Abs((float)pCap.d) > 1.0e-9)
			? 100.0 * Abs((float)pMv.d) / Abs((float)pCap.d) : 0.0;
		LogA("[mlt] 🎯     ⭐ **칸 10 의 자 — 실현율 = 그 낱말 ÷ 천장**\n");
		LogA("[mlt] 🎯        ㈂ `maxV`      **%.1f%%**  (162 = 절대 3.3%% · 델타 3.8%%)\n", realzMv);
		const double realzAs = (Abs((float)pCap.d) > 1.0e-9)
			? 100.0 * Abs((float)pAs.d) / Abs((float)pCap.d) : 0.0;
		LogA("[mlt] 🎯        ⭐ ㈄ **자율개수 %.1f%%**  ⇒ %s\n", realz,
			(realz > realzMv * 2.0) ? "⭐ **자율 라벨이 몫이다**" : "⛔ `maxV` 와 다를 바 없다");
		LogA("[mlt] 🎯        ⭐ ㈆ **자율슬롯(지목) %.1f%%**  ⇒ %s\n", realzAs,
			(realzAs > realz) ? "⚠️ 속력이 개수보다 낫다(예측 ㉣ 이 틀렸다)" : "✅ 개수가 낫다(예측 ㉣)");
		LogA("[mlt] 🎯        ★ 무차원이라 **절대 ↔ 델타를 견줄 수 있다**(규율 31·58)\n");
		LogA("[mlt] 🎯     ⚠️⚠️ **100%% 를 넘을 수 있다** — 천장은 **정보 항**만 묶는다(1씨앗 진단 실측 120.8%%):\n");
		LogA("[mlt] 🎯        `d̄ = I(낱말;표적|문맥) + (KL_바닥 − KL_개입)` — 두 모델을 **따로 학습**시키므로\n");
		LogA("[mlt] 🎯        **근사 오차의 차**가 더해진다 ⇒ 천장이 말하는 것은 *\"정보 경로가 닫혔나\"* 뿐이다\n");

		// ③-b ⭐ 조건부 천장(회차 175 · 규율 66 의 진단법)
		const double hT = _MeanOf(_hT);
		const double iOra = _MeanOf(_iW[kOracle]) - _MeanOf(_iW[kOracleS]);
		const double iMv  = _MeanOf(_iW[kMaxV])   - _MeanOf(_iW[kMaxVS]);
		const double iAn  = _MeanOf(_iW[kAutoN])  - _MeanOf(_iW[kAutoNS]);
		const double iAs  = _MeanOf(_iW[kAutoS])  - _MeanOf(_iW[kAutoSS]);
		// ⚠️ 이름은 `q*` 다 — `p*` 는 이 함수의 **짝지은 Pair** 다(빌드가 그 자리에서 잡았다)
		// ⭐ 회차 175 — **분모는 `H(변화 표적)` 이 아니라 「정보천장」이다.**
		//   ⚠️ 1씨앗 진단이 그것을 가르쳐 줬다: `Î(오라클)/H(표적)` 은 10.5% 여서 ⛔ 로 찍혔는데
		//     **오라클은 원리적으로 그만큼 못 낸다** — 낱말이 **시각당 하나**이고 표적이
		//     **시각당 `채점/시각` 개**라 그 비만큼 **희석**되기 때문이다.
		//   ★ 그 희석을 이미 담고 있는 자가 ③ 의 **정보천장** = `H(낱말) × 시각 ÷ 채점` 이다.
		//   ⇒ ⭐ 그래서 이 회차는 **검산이 두 겹**이 됐다: 결합 히스토그램(③-b)과
		//     회차 140 의 손계산 천장(③)이 **독립적으로 같은 값**을 내야 한다.
		const double capA = (nCh > 1.0e-9) ? ((double)kTime * hAn) / nCh : 0.0;
		const double capS = (nCh > 1.0e-9) ? ((double)kTime * hAs) / nCh : 0.0;
		// ⭐ **전달율** = Î ÷ 정보천장 — *"이론상 나를 수 있는 것 중 실제로 표적과 상관된 몫"*
		const double qOra = (capO > 1.0e-12) ? 100.0 * iOra / capO : 0.0;
		const double qMv  = (capM > 1.0e-12) ? 100.0 * iMv  / capM : 0.0;
		const double qAn  = (capA > 1.0e-12) ? 100.0 * iAn  / capA : 0.0;
		const double qAs  = (capS > 1.0e-12) ? 100.0 * iAs  / capS : 0.0;
		LogA("[mlt] 🎯   ── ③-b ⭐ **전달율** `Î(낱말 ; 변화 표적)`(회차 175 · 규율 66) ──\n");
		LogA("[mlt] 🎯     ⭐ 묻는 것 = *\"이 낱말이 결정되면 표적 후보가 몇 개로 줄나\"*\n");
		LogA("[mlt] 🎯     **H(변화 표적) = %.4f** 나트 (코드 %u ⇒ 상한 ln %u = %.4f)\n",
			hT, kN, kN, (double)Log((float)kN));
		LogA("[mlt] 🎯     낱말          Î(생)    Î(섞음)   ⭐ Î−섞음   정보천장   ⭐ **전달율**\n");
		LogA("[mlt] 🎯     ㈀ 오라클     %.4f   %.4f    **%+.4f**   %.4f    **%.1f%%**\n",
			_MeanOf(_iW[kOracle]), _MeanOf(_iW[kOracleS]), iOra, capO, qOra);
		LogA("[mlt] 🎯     ㈂ `maxV`     %.4f   %.4f    **%+.4f**   %.4f    **%.1f%%**\n",
			_MeanOf(_iW[kMaxV]), _MeanOf(_iW[kMaxVS]), iMv, capM, qMv);
		LogA("[mlt] 🎯     ㈄ 자율개수   %.4f   %.4f    **%+.4f**   %.4f    **%.1f%%**\n",
			_MeanOf(_iW[kAutoN]), _MeanOf(_iW[kAutoNS]), iAn, capA, qAn);
		LogA("[mlt] 🎯     ㈆ 자율슬롯   %.4f   %.4f    **%+.4f**   %.4f    **%.1f%%**\n",
			_MeanOf(_iW[kAutoS]), _MeanOf(_iW[kAutoSS]), iAs, capS, qAs);
		// ⭐ 검산 둘 — 두 자가 만나야 하고(오라클), 섞음은 0 이어야 한다
		const bool gMiO = (qOra >= 70.0);
		double shMax = 0.0;
		{
			const double sh[4] = { _MeanOf(_iW[kOracleS]), _MeanOf(_iW[kMaxVS]),
			                       _MeanOf(_iW[kAutoNS]),  _MeanOf(_iW[kAutoSS]) };
			for (uint32 i = 0; i < 4u; ++i) if (Abs((float)sh[i]) > shMax) shMax = Abs((float)sh[i]);
		}
		LogA("[mlt] 🎯     ⭐ **검산 — 두 자가 만나나**: Î(오라클) %.4f ↔ 정보천장 %.4f\n",
			iOra, capO);
		LogA("[mlt] 🎯        ⇒ **%.1f%%**(관문 ≥70%%) → %s\n", qOra,
			gMiO ? "✅ ★ 회차 140 의 손계산 천장이 **독립으로 확인됐다**"
			     : "⛔ **두 자가 다르다** — 어느 쪽이 틀렸는지부터 본다");
		LogA("[mlt] 🎯     ⭐ **배관** — 섞음 최대 **%.4f** 나트(편향 · 짝을 빼서 지운다)\n", shMax);
		// ⭐ 갈림 — **전달율**과 **몸통 실현율**을 나란히 둔다
		//   ★ 오라클은 표적과 **같은 공간**(표적 id 의 8분위)이고 나머지는 **세계 값**이다
		//     ⇒ 그 갈림이 두 칸의 비에 나타나야 한다(규율 66 의 정확한 형태).
		LogA("[mlt] 🎯     ⭐ **갈림 — 전달율 ↔ 몸통 실현율**(정보가 없나 · 못 쓰나)\n");
		LogA("[mlt] 🎯        낱말        전달율    몸통 실현율   ⭐ 몸통 ÷ 전달\n");
		LogA("[mlt] 🎯        ㈂ `maxV`   %.1f%%     %.1f%%        **%.2f**\n",
			qMv, realzMv, (qMv > 1.0e-9) ? realzMv / qMv : 0.0);
		LogA("[mlt] 🎯        ㈄ 자율개수 %.1f%%     %.1f%%        **%.2f**\n",
			qAn, realz, (qAn > 1.0e-9) ? realz / qAn : 0.0);
		LogA("[mlt] 🎯        ㈆ 자율슬롯 %.1f%%     %.1f%%        **%.2f**\n",
			qAs, realzAs, (qAs > 1.0e-9) ? realzAs / qAs : 0.0);
		const double qAuto = (qAn > qAs) ? qAn : qAs;
		const double rAuto = (qAn > qAs) ? realz : realzAs;
		LogA("[mlt] 🎯        ⇒ %s\n",
			(qAuto < 5.0)
				? "⭐ ***규율 66 확정*** — 세계 낱말이 코드 id 를 **원리적으로 못 좁힌다**\n"
				  "[mlt] 🎯           ⇒ ★ **㉠ 정렬이 유일한 길**이고, 그것 없이는 어떤 낱말도 안 선다"
				: ((rAuto < qAuto * 0.6)
					? "⭐ ***정보는 있는데 몸통이 그것을 못 쓴다*** — 규율 66 이 **과했다**\n"
					  "[mlt] 🎯           ⇒ ★ 벽은 **원리**가 아니라 **사상**이다: 오라클은 낱말→id 가\n"
					  "[mlt] 🎯              **단조**(분위→id 구간)라 쉽고, 세계 값은 **임의 사상**이라\n"
					  "[mlt] 🎯              문맥 512 · 800걸음으로 못 배운다\n"
					  "[mlt] 🎯           ⇒ ⭐ **㉠ 정렬이 바로 그 사상을 쉽게 만드는 처방**이다 — 진단이 확인했다"
					: "⚠️ **몸통이 전달율만큼 쓴다** ⇒ 병목이 낱말의 **정보량**이다 ⇒ ㉠ 이 그것을 키운다"));
		LogA("[mlt] 🎯     ⚠️ 규율 59 — 이것은 **문맥 없이** 잰 값이라 **상한**이다(몸통은 문맥을 이미 안다)\n");

		// ③-c ⭐ 회차 177 — **부채 D22**. 규율 59 가 요구한 자를 드디어 만든다.
		{
			const double uO = _MeanOf(_iQu[kOracle]) - _MeanOf(_iQu[kOracleS]);
			const double cO = _MeanOf(_iQc[kOracle]) - _MeanOf(_iQc[kOracleS]);
			const double uM = _MeanOf(_iQu[kMaxV])   - _MeanOf(_iQu[kMaxVS]);
			const double cM = _MeanOf(_iQc[kMaxV])   - _MeanOf(_iQc[kMaxVS]);
			const double uN = _MeanOf(_iQu[kAutoN])  - _MeanOf(_iQu[kAutoNS]);
			const double cN = _MeanOf(_iQc[kAutoN])  - _MeanOf(_iQc[kAutoNS]);
			const double uS = _MeanOf(_iQu[kAutoS])  - _MeanOf(_iQu[kAutoSS]);
			const double cS = _MeanOf(_iQc[kAutoS])  - _MeanOf(_iQc[kAutoSS]);
			// ⭐ **남는 비** = 조건부 ÷ 무조건부 = *"문맥이 모르는 몫"*
			const double kO = (Abs((float)uO) > 1.0e-9) ? 100.0 * cO / uO : 0.0;
			const double kM = (Abs((float)uM) > 1.0e-9) ? 100.0 * cM / uM : 0.0;
			const double kNn = (Abs((float)uN) > 1.0e-9) ? 100.0 * cN / uN : 0.0;
			const double kS = (Abs((float)uS) > 1.0e-9) ? 100.0 * cS / uS : 0.0;
			LogA("[mlt] 🎯   ── ③-c ⭐ **조건부** `Î(낱말;표적|문맥)`(회차 177 · 부채 D22) ──\n");
			LogA("[mlt] 🎯     ⚙️ 문맥의 대리 = **지금 그 슬롯의 id**(= 직전 표적) · 표적·직전을 **%u분위로 뭉갠다**\n", kQ);
			LogA("[mlt] 🎯        ⇒ 칸 %u×%u×%u = **%u** (표본 ~1.8만 ⇒ 칸당 ~31개) · 편향은 섞음 짝이 뺀다\n",
				kWordCls, kQ, kQ, kWordCls * kQ * kQ);
			LogA("[mlt] 🎯        ⚠️ 뭉개면 `Î` 절대값이 준다(표적 250→%u) ⇒ ★ 판정은 **같은 자 안의 비**로(규율 58)\n", kQ);
			LogA("[mlt] 🎯     낱말        무조건부   조건부    ⭐ **남는 비**(문맥이 모르는 몫)\n");
			LogA("[mlt] 🎯     ㈀ 오라클   %+.4f   %+.4f    **%.1f%%**\n", uO, cO, kO);
			LogA("[mlt] 🎯     ㈂ `maxV`   %+.4f   %+.4f    **%.1f%%**\n", uM, cM, kM);
			LogA("[mlt] 🎯     ㈄ 자율개수 %+.4f   %+.4f    **%.1f%%**\n", uN, cN, kNn);
			LogA("[mlt] 🎯     ㈆ 자율슬롯 %+.4f   %+.4f    **%.1f%%**\n", uS, cS, kS);
			const double kAuto = (kNn > kS) ? kNn : kS;
			LogA("[mlt] 🎯     ⭐ **검산** — 오라클은 **표적의 함수**라 문맥이 못 안다 ⇒ 남는 비 ≥70%%\n");
			LogA("[mlt] 🎯        실측 **%.1f%%** → %s\n", kO,
				(kO >= 70.0) ? "✅" : "⛔ **오라클조차 문맥과 겹친다** — 자를 못 믿는다");
			LogA("[mlt] 🎯     ⭐ **표제** — 세계 낱말의 남는 비 %.1f%% ⇒ %s\n", kAuto,
				(kAuto < 30.0)
					? "⭐ ✅ ***겹침이 원인이다*** — 문맥이 세계 낱말의 70%% 이상을 이미 안다\n"
					  "[mlt] 🎯           ⇒ ★ 처방은 ㉠(정렬)이 아니라 ***낱말을 바깥 채널로***(㉢)\n"
					  "[mlt] 🎯              — 화면에 보이는 것으로 만든 낱말은 **원리적으로** 막힌다"
					: ((kAuto >= 60.0)
						? "⛔⛔ ***겹침이 원인이 아니다*** — 문맥이 그것을 모른다\n"
						  "[mlt] 🎯           ⇒ ⚠️ 남은 후보는 ㈎ **분포 모양**(하드 배제 ↔ 얇은 기울기)과\n"
						  "[mlt] 🎯              ㈏ **학습 부족**(800걸음) ⇒ ★ 둘 다 **몸통 쪽** 처방이다"
						: "⚠️ **가운데다**(30~60%%) — 겹침이 절반쯤이다 ⇒ ★ 오라클 대비로 읽어라"));
			LogA("[mlt] 🎯     ⚠️ 이것은 **하한**이다 — 몸통은 직전 id 하나보다 **더 많이** 안다\n");
			LogA("[mlt] 🎯        ⇒ ★ 그래서 남는 비가 작게 나오면 그것은 **확실한** 겹침이다\n");
		}

		// ③-d ⭐ 회차 177 — **활용률** = 몸통 이득 ÷ 낱말 정보. **둘이 같은 단위(나트)다.**
		//   ⚠️⚠️ 왜 이 줄이 필요한가 — 175 의 「몸통 ÷ 전달」은 **분모가 둘이었다**:
		//     전달율의 분모 = **자기** 정보천장 · 실현율의 분모 = **오라클** 천장 `d̄`
		//     ⇒ ★ 그래서 그 비의 비가 갈림을 **부풀렸다**(4.7배로 읽혔다).
		//   ⭐ 여기서는 **한 낱말 안에서** 나눈다: `|d̄|` 와 `Î` 가 둘 다 나트라 그냥 나뉜다.
		//     1 = 몸통이 정보를 다 쓴다 · <1 = 못 쓴다 · >1 = 근사 오차의 차가 더해졌다(규율 49).
		{
			const double uO = (Abs((float)iOra) > 1.0e-9) ? Abs((float)pCap.d) / iOra : 0.0;
			const double uM = (Abs((float)iMv)  > 1.0e-9) ? Abs((float)pMv.d)  / iMv  : 0.0;
			const double uN = (Abs((float)iAn)  > 1.0e-9) ? Abs((float)pTop.d) / iAn  : 0.0;
			const double uS = (Abs((float)iAs)  > 1.0e-9) ? Abs((float)pAs.d)  / iAs  : 0.0;
			const double uAuto = (uN > uS) ? uN : uS;
			LogA("[mlt] 🎯   ── ③-d ⭐ **활용률** = 몸통 `|d̄|` ÷ 낱말 `Î`(회차 177 · 둘 다 나트) ──\n");
			LogA("[mlt] 🎯     ⚠️⚠️ 175 의 「몸통 ÷ 전달」은 **분모가 둘**이었다(자기 천장 ↔ 오라클 천장)\n");
			LogA("[mlt] 🎯        ⇒ ★ 그 비의 비가 갈림을 **부풀렸다** ⇒ ⭐ 여기서는 **한 낱말 안에서** 나눈다\n");
			LogA("[mlt] 🎯     낱말        몸통 |d̄|   낱말 Î    ⭐ **활용률**\n");
			LogA("[mlt] 🎯     ㈀ 오라클   %.5f    %.5f    **%.2f**\n", Abs((float)pCap.d), iOra, uO);
			LogA("[mlt] 🎯     ㈂ `maxV`   %.5f    %.5f    **%.2f**\n", Abs((float)pMv.d),  iMv,  uM);
			LogA("[mlt] 🎯     ㈄ 자율개수 %.5f    %.5f    **%.2f**\n", Abs((float)pTop.d), iAn,  uN);
			LogA("[mlt] 🎯     ㈆ 자율슬롯 %.5f    %.5f    **%.2f**\n", Abs((float)pAs.d),  iAs,  uS);
			LogA("[mlt] 🎯     ⭐ **진짜 갈림 = 오라클 ÷ 자율** = **%.2f배**  ⇒ %s\n",
				(uAuto > 1.0e-9) ? uO / uAuto : 0.0,
				((uAuto > 1.0e-9) ? uO / uAuto : 0.0) < 3.5
					? "★ **175 가 읽은 4.7배보다 작다** — 분모가 하나가 되니 갈림이 줄었다"
					: "⚠️ 여전히 크다 — 분모 문제가 아니었다");
			// ⚠️⚠️ **낡은 상수**(규율 57 의 넓힌 형태) — 176 의 1.10 은 **자율 3 세계**의 값이다.
			//   ★ 자율 몫이 다르면 사상 몫을 다시 재야 한다(`-mltperm` 을 그 세계에서 한 번 더).
			if (_autoN == 3)
			{
				LogA("[mlt] 🎯     ⇒ ⭐ **사상의 몫 재계산**(176: 활용률 1.57 → 1.42 = −9.6%%)\n");
				LogA("[mlt] 🎯        갈림 %.2f배 중 사상이 **1.10배** ⇒ 사상 = **%.0f%%**\n",
					(uAuto > 1.0e-9) ? uO / uAuto : 0.0,
					((uAuto > 1.0e-9) && (uO / uAuto > 1.0001))
						? 100.0 * (double)Log(1.10f) / (double)Log((float)(uO / uAuto)) : 0.0);
			}
			else
				LogA("[mlt] 🎯     ⚠️ **사상 몫은 안 적는다** — 176 의 1.10 은 **자율 3** 세계의 값이다(규율 57)\n");
		}

		// ④ 자가 결정적인가(기본 장비)
		double runSum = 0.0; uint32 runN = 0u, runZero = 0u;
		for (uint32 s = 0; s < _seeds; ++s)
		{
			if (!_seedOk[s]) continue;
			for (uint32 a = 0; a < kArms; ++a)
			{
				const double d = Abs((float)((double)_ce[1][a][s] - (double)_ce[0][a][s]));
				runSum += d; ++runN; if (d == 0.0) ++runZero;
			}
		}
		LogA("[mlt] 🎯   ── ④ **`sd_run` 확인**(규율 47) — 비트 동일 **%u/%u** · 평균 |Δ| **%.3e**\n",
			runZero, runN, (runN == 0u) ? 0.0 : runSum / (double)runN);

		// ── 관문 ────────────────────────────────────────────────────
		const uint32 pass = _SignPass();
		const bool gCap = (capSE >= 10.0);
		// ⭐ 표제 = `maxV` 가 자기 바닥을 이기나
		// ⭐ 표제 = **자율 낱말 둘 중 하나**가 자기 바닥을 이기나
		const bool gAn = (pTop.win >= pass) && (pTop.d < 0.0) && (pTop.t >= 3.0);
		const bool gAs = (pAs.win  >= pass) && (pAs.d  < 0.0) && (pAs.t  >= 3.0);
		const bool gPos = gAn || gAs;
		// ⭐ 천장 자체가 서야 표제의 분모가 뜻을 갖는다
		const bool gOra = (pCap.d < 0.0) && (pCap.t >= 3.0);
		LogA("[mlt] 🎯   ── 관문 ──\n");
		LogA("[mlt] 🎯     ⭐ **천장 ÷ SE**(≥10) — %.1f → %s\n", capSE, gCap ? "✅" : "⛔ **SE 가 같이 올랐다**");
		LogA("[mlt] 🎯     ⭐ **천장이 서나**(㈀<㈁ · |d̄|/SE %.2f≥3) → %s\n",
			pCap.t, gOra ? "✅" : "⛔ **오라클도 안 돕는다 = 분모가 없다**");
		LogA("[mlt] 🎯     ⭐ **표제**(둘 중 하나가 통과) — ㈄ 개수 %u/%u·%.2f %s · ㈆ 속력 %u/%u·%.2f %s → %s\n",
			pTop.win, pTop.n, pTop.t, gAn ? "✅" : "⛔",
			pAs.win,  pAs.n,  pAs.t,  gAs ? "✅" : "⛔",
			gPos ? "✅ **자율 낱말이 몸통을 돕는다**" : "⛔ **자율 낱말도 안 돕는다**");
		// ⭐ 회차 176 — 치환 손잡이의 자리. **정보가 불변인지부터** 적는다.
		if (_permOn)
		{
			LogA("[mlt] 🎯   ── ⑤ ⭐ **사상 가설 판정**(`-mltperm` · 회차 176) ──\n");
			LogA("[mlt] 🎯     ⚙️ 손잡이 = 오라클 낱말의 계급 1..8 을 **고정 치환**(0 = 없음은 그대로)\n");
			LogA("[mlt] 🎯        ⇒ ★ 정보량 **불변** · 사상만 **단조 → 임의**\n");
			// ⚠️⚠️ **씨앗 수마다 상수가 다르다** — 175 의 1씨앗 값과 12씨앗 값을 **둘 다** 든다.
			//   ★ 회차 162 에서 밟은 그 함정의 **또 다른 얼굴**이다(그때는 `chkApply` 에 씨앗 조건이 없었다)
			//     ⇒ 규율 57 을 넓힌다: **재는 조건이 바뀌면**(표현 · 씨앗 수 · 세계) 상수를 전부 훑어라.
			const bool d1 = (_seeds == 1u);
			// ⚠️⚠️ 이 상수 넷은 **자율 3 세계**의 것이다 — 다른 세계면 검산이 뜻을 잃는다(규율 57)
			if (_autoN != 3)
				LogA("[mlt] 🎯     ⚠️⚠️ **검산 건너뜀** — 아래 상수는 **자율 3** 세계의 값이다(지금 %d · 규율 57)\n", _autoN);
			const double chkI = d1 ? 0.3724 : 0.2830;
			const double chkH = d1 ? 1.6190 : 1.5379;
			const double chkR = d1 ? 1.28   : 1.57;    // 175 의 `몸통 ÷ 전달`
			const double ratio = (qOra > 1.0e-9)
				? ((capO > 1.0e-12) ? 100.0 * Abs((float)pCap.d) / capO : 0.0) / qOra : 0.0;
			LogA("[mlt] 🎯     ⭐ **배관 검산** — `Î(오라클)` 이 175 의 **%.4f** 와 같아야 한다(%s)\n",
				chkI, d1 ? "1씨앗" : "12씨앗");
			LogA("[mlt] 🎯        실측 **%+.4f** · 차 %.4f → %s\n", iOra, Abs((float)(iOra - chkI)),
				(Abs((float)(iOra - chkI)) < 0.02) ? "✅ 정보는 안 흔들렸다"
					: "⛔ **정보도 바뀌었다** — 손잡이가 둘이라 판정 못 한다");
			LogA("[mlt] 🎯     ⭐ **`H(오라클)` 검산** — 175 의 **%.4f** ↔ 실측 **%.4f** → %s\n",
				chkH, hOra, (Abs((float)(hOra - chkH)) < 0.02) ? "✅ 치환은 H 를 안 바꾼다" : "⛔ **H 가 달라졌다**");
			LogA("[mlt] 🎯     ⭐ **표제** — 오라클 `몸통 ÷ 전달`\n");
			LogA("[mlt] 🎯        175(단조) **%.2f** → 176(임의) **%.2f**  ⇒ %s\n", chkR, ratio,
				(ratio < chkR * 0.6)
					? "⭐ ✅ ***사상이 벽이다*** — 세계 낱말의 0.32~0.35 로 내려왔다\n"
					  "[mlt] 🎯           ⇒ ★ **㉠ 정렬**(사상을 단조로 만드는 것)이 처방으로 확정된다"
					: "⛔⛔ ***사상 가설 기각*** — 치환해도 몸통이 그대로 쓴다\n"
					  "[mlt] 🎯           ⇒ ⚠️ 4.7배의 원인이 사상이 아니다 ⇒ 다시 찾는다(그것도 큰 정보다)\n"
					  "[mlt] 🎯           ⇒ ⭐ 남은 후보 = **조건부 분포의 모양**: 오라클은 `P(T|W)` 가\n"
					  "[mlt] 🎯              **219/250 을 정확히 0 으로 배제**하고 세계 낱말은 250 에 얇게 퍼진다\n"
					  "[mlt] 🎯              ⇒ ★ 소프트맥스 CE 에서 **배제는 「조금 낮춤」보다 값이 크다**\n"
					  "[mlt] 🎯              ⇒ ⚠️ 그러면 `Î` 는 **불충분한 자**다(같은 나트가 같은 CE 이득이 아니다)");
			LogA("[mlt] 🎯        ⓘ 오라클 실현율 = **%.1f%%**(175 = %s) · 전달율 %.1f%%\n",
				(capO > 1.0e-12) ? 100.0 * Abs((float)pCap.d) / capO : 0.0,
				d1 ? "135.1%%" : "127.8%%", qOra);
		}
		LogA("[mlt] 🎯     ⓘ 자율 몫 = **%d/%d**(`-mltauto`) · 표현 = %s\n",
			_autoN, MLTWorldCfg::kShapes, _deltaOn ? "델타" : "절대");

		// ── 판정 ────────────────────────────────────────────────────
		if (!_finite || ok < _seeds)
			LogA("[mlt] 🎯   ⭐ 판정 = ⛔ **판정불가** — 배관이 안 섰다\n");
		else if (!gChk)
			LogA("[mlt] 🎯   ⭐ 판정 = ⛔ **판정불가** — ***검산이 깨졌다***(천장이 141 과 다르다)\n");
		else if (_seeds == 1u)
			LogA("[mlt] 🎯   ⭐ **1씨앗 진단이다 — 판정하지 않는다.** 배관·부호·크기만 본다\n");
		else if (!gOra)
			LogA("[mlt] 🎯   ⭐ 판정 = ⛔ **판정불가** — ***오라클(천장)조차 몸통을 안 돕는다*** ⇒ 분모가 없다\n"
			     "[mlt] 🎯      ⇒ ★ 그것은 낱말의 문제가 아니라 **자의 문제**다(141 은 이 자리를 통과했다)\n");
		else if (gPos)
			LogA("[mlt] 🎯   ⭐ 판정 = ⭐ ***자율 낱말이 몸통을 돕는다 — 실현율 %.1f%%***\n"
			     "[mlt] 🎯      (자율 몫 %d/%d · %s · |d̄|/SE %.2f · %u/%u · `maxV` 는 %.1f%%)\n"
			     "[mlt] 🎯      ⇒ ★ **칸 10 이 열렸다** — ***문맥이 못 아는 낱말은 몸통이 쓴다***\n"
			     "[mlt] 🎯      ⇒ ⭐ 규율 59 를 피하는 길이 확인됐다: **낱말은 세계의 숨은 라벨이어야 한다**\n",
				realz, _autoN, MLTWorldCfg::kShapes, _deltaOn ? "델타" : "절대",
				pTop.t, pTop.win, pTop.n, realzMv);
		else
			LogA("[mlt] 🎯   ⭐ 판정 = ⛔ **자율 낱말도 몸통을 안 돕는다**\n"
			     "[mlt] 🎯      (자율 몫 %d/%d · %s · 실현율 %.1f%% · |d̄|/SE %.2f · %u/%u)\n"
			     "[mlt] 🎯      ⇒ ★ 천장은 섰으므로(%.2f) **자는 살아 있다**\n"
			     "[mlt] 🎯      ⇒ ⚠️ 그러면 **화면에 보이는 것으로 만든 낱말은 전부 막힌다**(규율 59 의 강한 형태)\n",
				_autoN, MLTWorldCfg::kShapes, _deltaOn ? "델타" : "절대",
				realz, pTop.t, pTop.win, pTop.n, pCap.t);
		LogA("[mlt] 🎯   ⚠️ 문맥 학습 %u · 시험 %u · %u걸음 — 절대 성능으로 인용하지 않는다\n", kNCtx, kPtCtx, kSteps);
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		_E.Destroy(); _done = true;
	}

	static void _Fail(const char* why)
	{
		LogA("[mlt] 🎯 ⛔ %s (씨앗 %u · 팔 %u · 바깥 %u · 평가 %u · 단계 %u · 코퍼스 %u · 걸음 %u)\n",
			why, _seed, _arm, _out, _evalIdx, _st, _cor, _step);
		_E.Destroy(); _done = true;
	}

	CW_BODY(MLTL1Q0)
};
