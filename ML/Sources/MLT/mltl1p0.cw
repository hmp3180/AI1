// mltl1p0.cw — 📐 회차 160 · **델타판의 목표선을 세운다** (`-mlt -mltl1p0` · 델타는 `-mltdelta`)
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 160 이다.** ⭐ **하네스보다 먼저 썼다.**
//   **상위 캔버스: `모델이 변화 표적을 배우나` · 143~ = 1회차**(캔버스를 바꿨으므로 파일럿).
//
// ── ⭐ 표제 — ***몸통(2.7666)이 「학습 0 예측기」보다 나은가*** ────────
//   회차 142 가 `H(변화 표적) = 2.2663` 을 냈고 회차 141 의 몸통 변화 CE 는 **2.7666** 이었다.
//   ⚠️ 그런데 `H` 는 **시험 코퍼스 자신의** 주변분포라 그것만으로는 증명이 아니다.
//   ⇒ ★ 예측기를 **여럿** 놓고 나란히 잰다(하나로는 *"나쁘다"* 의 뜻이 안 정해진다 · 규율 16).
//
// ── ⭐ 먼저 — **「변화」가 두 종류다** ────────────────────────────
//   슬롯이 **id 오름차순 정렬**이므로(회차 55) 도형 하나가 사라지면 **슬롯이 전부 밀린다**
//   ⇒ 「그 슬롯의 id 가 바뀐다」가 ***집합이 안 바뀌어도 참***이 된다.
//   ⭐ 회차 140 이 그 틈을 이미 쟀다: **지속(슬롯) 78.3% ↔ 지속(집합) 90.0%**.
//     **(a) 밀림** — 표적 id 가 **지금 활성 8개 안**에 있다 ⇒ 정렬 규칙을 알면 좁혀진다
//     **(b) 새 id** — 지금 활성에 **없다** ⇒ 진짜 새로 들어온 것
//
// ── 📏 자 — 예측기 다섯(전부 **변화 표적당 나트** · 학습 0) ───────────────
//   ㉠a 학습 전체 주변분포 · ㉠b 학습 변화-only 주변분포 · ㉡ 시험 주변분포(**142 검산**) ·
//   ㉢ 그 슬롯의 지금 id 만 배제 · ⭐ ㉣ **밀림 인지**(α 를 **학습에서** 잰 혼합)
//   ⚠️ α 를 시험에서 재면 **훔쳐보는 것**이다.
//
// ── 🔮 예측(재기 전에 적었다) ────────────────────────────────────────────
//   ㉡ 2.266(검산) · ㉠a 2.6~3.2 · ㉠b 2.28~2.40 · ㉢ 2.1~2.35 · ⭐ ㉣ 1.3~1.9 ·
//   (a) 밀림 비율 **약 54%** · ⭐ 표제 = ⛔ **몸통이 ㉠b·㉢·㉣ 보다 나쁠 것**
//   ⚠️ 갈래: ㉠b 보다는 나은데 ㉣ 보다 나쁘면 ⇒ *"조금 배웠지만 **정렬 규칙**은 못 배웠다"*
// ══════════════════════════════════════════════════════════════════════════════

using namespace PE;

class MLTL1P0
{
public:
	static void Tick(RHI* rhi)
	{
		if (_done || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltl1p0"))
		{
			LogA("[mlt] 🧮 회차 160(변화 표적을 배우나)은 **꺼져 있다**(`-mltl1p0`)\n");
			_done = true; return;
		}
		if (!_banner)
		{
			_seeds = OS::CommandLine::Has("-mltdiag1") ? 1u : kSeedsMax;
			_deltaOn = OS::CommandLine::Has("-mltdelta");   // ⭐ 회차 160
			_matchOn = OS::CommandLine::Has("-mltmatch");   // ⭐ 회차 167
			{   // ⭐ 회차 168 — `-mlthys <n>`
				const char* hv = OS::CommandLine::ValueOf("-mlthys", "");
				if (hv != nullptr && hv[0] >= (char)48 && hv[0] <= (char)57)
				{
					const uint32 v = (uint32)(hv[0] - (char)48);
					if (v < kHyss) _hys = v;
				}
				_liveOn = OS::CommandLine::Has("-mltlive");   // ⭐ 171
				const char* fv = OS::CommandLine::ValueOf("-mltfloor", "");   // ⭐ 170
				if (fv != nullptr && fv[0] >= (char)48 && fv[0] <= (char)57)
				{
					const uint32 v = (uint32)(fv[0] - (char)48);
					if (v < kFloors) _flr = v;
				}
			}
			{   // ⭐ 회차 165 — `-mltpt <n>`
				const char* pv = OS::CommandLine::ValueOf("-mltpt", "");
				if (pv != nullptr && pv[0] >= (char)48 && pv[0] <= (char)57)
				{
					const uint32 v = (uint32)(pv[0] - (char)48);
					if (v < kPts) _pt = v;
				}
				const char* sv = OS::CommandLine::ValueOf("-mltsup", "");   // ⭐ 회차 166
				if (sv != nullptr && sv[0] >= (char)48 && sv[0] <= (char)57)
				{
					const uint32 v = (uint32)(sv[0] - (char)48);
					if (v < kSups) _sup = v;
				}
			}
			_Banner(); _banner = true;
		}
		if (_seed >= _seeds) { _Summary(); return; }
		if (_st == kEncInit)  { _EncBegin(rhi); return; }
		if (_st == kEncTrain) { _EncTrain(); return; }
		if (_st == kGather)   { _Gather(); return; }
		_Measure();
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

	// ⚠️ 138~142 와 **같은 코퍼스**(같은 씨앗·epi·인코더). `_pbA` 는 이 회차가 안 쓴다.
	static constexpr uint32 kNCtx = 512u, kPtCtx = 512u;
	static constexpr uint32 kTrainEpi = 1u, kPtEpi = 5001u;

	// ⭐ 회차 141 이 남긴 값 — ⚠️ 여기서 새로 재지 않는다(견주는 상대다).
	static constexpr float kCE141 = 2.7666f;   // 몸통의 변화 표적 CE(씨앗 12 평균)
	static constexpr float kH142  = 2.2663f;   // 회차 142 의 H(변화 표적) — ㉡ 의 검산 상대
	// ⭐ 회차 160 — **델타판의 검산 상대**(회차 159 가 재 값) · ★ 사슬의 새 고리다
	static constexpr float kH159d = 3.2574f;   // 델타판 H(변화 표적)
	static constexpr float kNd159 = 42.2f;     // 델타판 변화 표적/문맥
	// ⚠️⚠️ **몸통 CE 는 절대판에서만 있다** — 델타판은 안 재서 141 상수를 쓰면 안 된다.
	static bool _BodyKnown() { return !_deltaOn; }

	static constexpr uint32 kPreds = 5u;       // ㉠a ㉠b ㉡ ㉢ ㉣
	enum { kEncInit, kEncTrain, kGather, kMeasure };

	// ⭐ 회차 160 — **델타 표현**(`-mltdelta`) · ⚠️ 세계 코드 0줄
	inline static bool _deltaOn = false;
	// ⭐ 회차 165 — **세계 손잡이 점**(회차 164 의 표를 그대로 옮긴다 · `-mltpt <n>`)
	//   ★ 이 하네스는 **밀림/새id 를 이미 가른다** ⇒ 점만 주면 「센서가 지울 몫」이 갈린다.
	//   ⚠️ 세계 코드 0줄 — 164 가 `dtMul`/`autoAmp` 를 런타임으로 열었다.
	static constexpr uint32 kPts = 8u;
	static constexpr float kPtDt[kPts]   = { 1.00f, 1.00f, 1.00f, 0.25f, 0.25f, 1.00f, 0.001f, 0.001f };
	static constexpr float kPtAmp[kPts]  = { 1.00f, 2.50f, 5.00f, 1.00f, 5.00f, 1.00f, 0.00f,  5.00f  };
	static constexpr int   kPtHold[kPts] = { MLTWorldCfg::kHoldMid, MLTWorldCfg::kHoldMid,
	                                         MLTWorldCfg::kHoldMid, MLTWorldCfg::kHoldMid,
	                                         MLTWorldCfg::kHoldMid, MLTWorldCfg::kHoldEasy,
	                                         MLTWorldCfg::kHoldMid, MLTWorldCfg::kHoldMid };
	inline static uint32 _pt = 0u;
	// ⭐ 회차 166 — **미세 변화 억제**(`-mltsup <n>`)
	//   ★ 지금 표적 판정은 **id 동일성**뿐이라 미세 이동이 양자화 경계를 넘으면 「변화」가 된다
	//     (회차 165: 정지 세계에서 표적 **8.9** — 그것이 이 처방의 대상이다).
	//   ⚠️ 문턱은 **값이 아니라 규칙**이다(규율 54):
	//     문턱 = θ × median_a( min_{b≠a} ‖code_a − code_b‖ )   ← **등장하는 코드만**
	//     ⇒ *"가장 가까운 이웃만큼 가까우면 같은 것"* — 코드북 자신의 해상도로 정한다.
	static constexpr uint32 kSups = 4u;
	static constexpr float kSupTheta[kSups] = { 0.0f, 0.5f, 1.0f, 2.0f };
	// ⭐ 회차 167 — **배치 짝짓기**(`-mltmatch`) · 기본 꺼짐 ⇒ 기존 회차 보전
	inline static bool   _matchOn = false;
	// ⭐ 회차 168 — **선택 히스테리시스**(`-mlthys <n>`)
	//   ★ 회차 166 이 지목한 원인(*"경계의 하나가 들락날락"*)을 **직접** 막는다.
	//   ⚠️ β=1 은 끔 ⇒ 기존과 비트 동일.
	static constexpr uint32 kHyss = 4u;
	static constexpr float kHysBeta[kHyss] = { 1.0f, 1.3f, 2.0f, 4.0f };
	inline static uint32 _hys = 0u;
	// ⭐ 회차 170 — **빈 슬롯을 허용한다**(`-mltfloor <n>`)
	//   ★ 회차 169 가 등록한 「슬롯 수 16」의 **싼 대체** — `kPersist` 수술(276 곳)이 없다.
	//   문턱 = alpha × (그 프레임의 최고 점수) ⇒ 그 아래는 **뽑지 않고 슬롯을 비운다**.
	//   ⚠️ alpha=0 은 끔 ⇒ 기존과 비트 동일.
	static constexpr uint32 kFloors = 4u;
	static constexpr float kFloorA[kFloors] = { 0.0f, 0.05f, 0.15f, 0.35f };
	inline static uint32 _flr = 0u;
	inline static double _fillS[kSeedsMax];   // ⭐ 서명 — 채운 슬롯 수(평균)
	// ⭐ 회차 171 — **죽은 패치를 슬롯에서 뺀다**(`-mltlive`)
	//   ★ 규율 65 가 가리킨 자리 = **인코더 앞단**(패킹 바이트).
	//     패치의 델타 바이트가 **전부 0** 이면 그 패치에서 온 후보를 슬롯에 안 넣는다.
	//   ⭐ 하네스는 이미 `packed` 를 보고 희소성을 잰다 ⇒ **새 계산 0**.
	inline static bool _liveOn = false;
	//   그룹 하나의 프레임 수 = kGroup(4) × kTime(8) = 32 · 패치 64
	inline static Array<uint8> _liveBuf;   // [프레임 * kPatches + 패치]
	inline static Array<uint8> _liveOne;   // 한 프레임 몫(StoreAct 에 넘긴다)
	inline static double _liveS[kSeedsMax];   // ⭐ 서명 — 산 패치 수(평균 · /64)
	inline static uint32 _sup = 0u;      // 팔 색인
	inline static float  _supTh = 0.0f;  // 실제 문턱(씨앗마다 다시 계산)
	inline static float  _supNN = 0.0f;  // 최근접 이웃 거리 중앙값(보고용)
	inline static uint32 _supUsed = 0u;  // 등장한 코드 수(보고용)
	inline static double _supThS[kSeedsMax], _supNNS[kSeedsMax], _supUsedS[kSeedsMax];
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
	inline static MLTP2Enc _E;
	inline static MLTP3Ctx _trA, _ptA;
	inline static bool _done = false, _banner = false, _encSetup = false, _ok = true;
	inline static bool _pending = false;
	inline static uint32 _seed = 0u, _st = kEncInit, _step = 0u;
	inline static uint32 _cor = 0u, _gGrp = 0u, _gIdx = 0u;
	inline static Array<float> _code, _norm;

	inline static double _ce[kPreds][kSeedsMax];
	// ⭐ 1씨앗 진단이 요구한 것 — **밀림/새id 로 갈라 본다**(㉣ 가 ㉢ 보다 나쁜 이유가 거기 있다)
	inline static double _ceS[kPreds][kSeedsMax], _ceN[kPreds][kSeedsMax];
	inline static double _nCh[kSeedsMax], _shiftTe[kSeedsMax], _shiftTr[kSeedsMax];
	inline static double _hAll[kSeedsMax], _hShift[kSeedsMax], _hNew[kSeedsMax];
	inline static double _branch[kSeedsMax];   // ⭐ 갈래 엔트로피 `H(α)` — ㉣ 가 무는 비용

	static const char* _PName(uint32 p)
	{
		switch (p)
		{
		case 0u: return "㉠a 학습 전체 주변분포   ";
		case 1u: return "㉠b 학습 변화-only 주변  ";
		case 2u: return "㉡  시험 주변(142 검산)  ";
		case 3u: return "㉢  슬롯 id 배제         ";
		default: return "㉣  밀림 인지 혼합 ⭐    ";
		}
	}

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🧮 **회차 160 · 변화 표적을 배우나**(⭐ 학습 0 · 계산 회차 · %s)\n",
			(_seeds == 1u) ? "⚠️ 1씨앗 진단" : "씨앗 12");
		if (_deltaOn)
			LogA("[mlt] 🧮   ⭐ 표제 = ***델타판의 「학습 0 예측기 최선」이 얼마인가*** = ★ **새 목표선**\n"
			     "[mlt] 🧮      ⚠️⚠️ 몸통은 **안 잰다** — 141 의 2.7666 은 **절대판 값**이라 못 쓴다\n");
		else
			LogA("[mlt] 🧮   ⭐ 표제 = ***몸통(회차 141 · CE **%.4f**)이 「학습 0 예측기」보다 나은가***\n", (double)kCE141);
		LogA("[mlt] 🧮   🎞️ 표현 = **%s** · 🎛️ 점 **%s**(`dt` ×%.3f · 자율진폭 ×%.2f · `hold` %d)\n",
			_deltaOn ? "델타(`-mltdelta`)" : "절대(기본)", _PtName(_pt),
			(double)kPtDt[_pt], (double)kPtAmp[_pt], kPtHold[_pt]);
		LogA("[mlt] 🩻   ⭐ **죽은 패치를 뺀다** = **%s**\n",
			_liveOn ? "켬(`-mltlive`)" : "꺼짐 — 기존과 **비트 동일**");
		if (_liveOn)
		{
			LogA("[mlt] 🩻      ★ 규율 65 가 가리킨 자리 = **인코더 앞단**(패킹 바이트)\n");
			LogA("[mlt] 🩻         패치의 델타 바이트가 **전부 0** 이면 그 패치 후보를 슬롯에 안 넣는다\n");
			LogA("[mlt] 🩻      ★ 회차 158 이 설계한 그 불변식이다 — 「안 움직였다 = 델타 전부 0」\n");
			LogA("[mlt] 🩻      ⭐ **절대적**이다 — 바이트가 0 인가는 규모에도 씨앗에도 무관하다\n");
			LogA("[mlt] 🩻      ⭐ 선택적일 이유가 구조에 있다(회차 159 서명):\n");
			LogA("[mlt] 🩻         정지 희소성 **0.006** ⇒ 패치당 비영 ≈ **0.4** 개 ⇒ 대부분 패치가 죽는다\n");
			LogA("[mlt] 🩻         기본 희소성 **0.271** ⇒ 패치당 비영 ≈ **17** 개 ⇒ 거의 다 산다\n");
			LogA("[mlt] 🩻      📏 자 = **잡음 비율**(규율 64) · 관문 **< 15%%** · 기제 = **산 패치 수**\n");
		}
		LogA("[mlt] 🕳️   ⭐ **빈 슬롯 허용**(세기 문턱) α = **%.2f**%s\n",
			(double)kFloorA[_flr], (_flr == 0u) ? "(꺼짐 — 기존과 **비트 동일**)" : "");
		if (_flr != 0u)
		{
			LogA("[mlt] 🕳️      ⚠️ 지금 선택 루프는 ***무조건 여덟을 채운다*** ⇒ 정지 세계에서\n"
			     "[mlt] 🕳️         세기가 거의 0 인 후보까지 억지로 뽑히고 **들락날락**한다\n");
			LogA("[mlt] 🕳️      ★ 처방 = `sc < α × scMax` 이면 **뽑지 않고 슬롯을 비운다**\n");
			LogA("[mlt] 🕳️         ⭐ 상대 문턱이라 프레임 규모에 무관 · scMax 는 **그 프레임 안에서**(훔쳐보기 없음)\n");
			LogA("[mlt] 🕳️      ★ 이것이 회차 169 의 「슬롯 수 16」의 **싼 대체**다 — `kPersist` 수술(276 곳)이 없다\n");
			LogA("[mlt] 🕳️      📏 자 = **잡음 비율**(규율 64) · 지금 21.1%%(끔) · 최선 20.0%% ⇒ 관문 **< 15%%**\n");
			LogA("[mlt] 🕳️         ⭐ 기제 증거 = **채운 슬롯 수** — 정지에서 8 → ≤5 · 기본은 ≥7 유지\n");
		}
		LogA("[mlt] 🧲   ⭐ **선택 히스테리시스** β = **%.2f**%s\n",
			(double)kHysBeta[_hys], (_hys == 0u) ? "(꺼짐 — 기존과 **보전**)" : "");
		if (_hys != 0u)
		{
			LogA("[mlt] 🧲      ★ `sc = |mag| × norm × (직전에 뽑혔으면 β)` ⇒ **선택이 붙잡힌다**(추적)\n");
			LogA("[mlt] 🧲      ⚠️ id 로 판정한다 — 같은 코드가 **다른 패치**에서 나와도 「같은 것」이다\n");
			LogA("[mlt] 🧲      ⭐ 이 처방이 왜 다를 수 있나 — **세 처방이 서로 다른 축을 건드린다**\n");
			LogA("[mlt] 🧲         166 값(코드 거리) **0.88** · 167 자리(배치) **0.70** · ⭐ 168 **집합(선택)**\n");
			LogA("[mlt] 🧲         ★ 정지 세계는 코드 **8.9** vs 슬롯 **8** ⇒ 경계에 **딱 하나** ⇒ 붙잡으면 표적이 거의 0\n");
			LogA("[mlt] 🧲         ★ 기본 세계는 코드 **51.7** vs 8(6.5배) ⇒ 경계에 여럿이 ⇒ 덜 붙잡힌다\n");
			LogA("[mlt] 🧲         ⇒ ★ ***선택성 > 1 이 나올 이유가 구조에 있다***\n");
			LogA("[mlt] 🧲      ⚠️⚠️ 위험(예상 ㉧) — **지속이 너무 쉬워질** 수 있다(복사로 도망갈 길 — 152 의 축)\n");
			LogA("[mlt] 🧲         ⇒ ★ **지속 표적 수와 지속 CE 를 같이 본다**\n");
		}
		LogA("[mlt] 🔗   ⭐ **배치 짝짓기**(물체 항등성) = **%s**\n",
			_matchOn ? "켬(`-mltmatch`)" : "꺼짐 — 기존과 **보전**");
		if (_matchOn)
		{
			LogA("[mlt] 🔗      ★ 직전 슬롯과 **같은 id 는 그 자리**에 ⇒ 「밀림」이 **정의상 사라진다**\n");
			LogA("[mlt] 🔗      ⚠️⚠️ 못 막는 것 — **id 집합 자체가 바뀌는 것**(= 새id)은 그대로다\n");
			LogA("[mlt] 🔗         (166: 정지 세계 표적의 **77.7%% 가 새id**) ⇒ ★ 그것은 **선택 규칙**의 일이다\n");
			LogA("[mlt] 🔗      ⭐ 손계산 예상(규율 21) — 기본 42.2 → **31.1** · 정지 8.9 → **6.9** · 선택성 **0.85**\n");
			LogA("[mlt] 🔗      ★ 그 예상이 맞으면 166 의 「하나가 둘 다 푼다」를 **철회**하고 ㉠b(선택 히스테리시스)로 간다\n");
		}
		LogA("[mlt] 🧽   ⭐ **미세 변화 억제** θ = **%.2f**%s\n",
			(double)kSupTheta[_sup], (_sup == 0u) ? "(꺼짐 — 지금과 **비트 동일**)" : "");
		if (_sup != 0u)
		{
			LogA("[mlt] 🧽      ⚠️ 문턱은 **값이 아니라 규칙**이다(규율 54):\n");
			LogA("[mlt] 🧽         문턱 = θ × median_a( min_b ‖code_a − code_b‖ )  ← **등장하는 코드만**\n");
			LogA("[mlt] 🧽         ★ *\"가장 가까운 이웃만큼 가까우면 같은 것\"* — 코드북 자신의 해상도로 정한다\n");
			LogA("[mlt] 🧽      ⚠️ **학습 코퍼스에서만** 계산해 시험에 적용한다(훔쳐보기 금지)\n");
			LogA("[mlt] 🧽      ⭐ 자 = **선택성** = (정지에서 지운 비율) ÷ (기본에서 지운 비율)\n");
			LogA("[mlt] 🧽         > 2 = 잡음을 **선택적으로** 지운다 ✅  ·  ≈ 1 = **무차별** ⛔\n");
		}
		if (_pt != 0u)
		{
			LogA("[mlt] 🧮   ⭐ **회차 165** = ***센서가 지워야 할 몫을 가른다***\n");
			LogA("[mlt] 🧮      ⚠️ 밀림 **26.2%%**(160) + 정지 세계 표적 **15.8/64 = 25%%**(164) — **겹치나**\n");
			LogA("[mlt] 🧮      ★ 겹치면 **물체 항등성 하나로 둘 다** 풀린다 · 아니면 **미세 억제도** 필요\n");
			LogA("[mlt] 🧮      ⚠️⚠️ 점 %u 는 **세계가 다르다** ⇒ 141·142·143 의 검산 상대가 **없다**(규율 57)\n", _pt);
		}
		LogA("[mlt] 🧮   ⭐ 먼저 — **「변화」가 두 종류다**: 슬롯이 **id 오름차순**이라(회차 55)\n");
		LogA("[mlt] 🧮      도형 하나가 사라지면 **슬롯이 전부 밀린다** ⇒ 집합이 안 바뀌어도 「변화」가 된다\n");
		LogA("[mlt] 🧮      **(a) 밀림** = 표적 id 가 지금 활성 8개 **안** · **(b) 새 id** = **밖**\n");
		LogA("[mlt] 🧮   예측기 다섯 — ㉠a 학습전체 · ㉠b 학습변화only · ㉡ 시험주변(검산) · ㉢ 슬롯배제 · ⭐ ㉣ 밀림인지\n");
		LogA("[mlt] 🧮   ⚠️ ㉣ 의 α(밀림 비율)는 **학습 코퍼스에서** 잰다 — 시험에서 재면 훔쳐보는 것이다\n");
		LogA("[mlt] 🧮   ⭐ 예측 — ㉡ 2.266(검산) · ㉠a 2.6~3.2 · ㉠b 2.28~2.40 · ㉢ 2.1~2.35 · ㉣ **1.3~1.9**\n");
		LogA("[mlt] 🧮   ⭐ 표제 예측 = ⛔ **몸통이 ㉠b·㉢·㉣ 보다 나쁠 것** · 밀림 비율 **약 54%%**\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

	// ── 인코더 · 코퍼스(138~142 와 같다) ────────────────────────────
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
		ImageFormat::Bitmap bmpA, bmpB; Bytes packed;
		MLTWorld w; w.Reset(_seed, 0u, kPtHold[_pt], MLTWorldCfg::kAutoFew, kPtDt[_pt], kPtAmp[_pt]);
		for (uint32 f = 0; f < kEncF; ++f)
		{
			w.Step();
			// ⚠️ 인코더도 **같은 표현**으로 학습해야 한다
			ImageFormat::Bitmap& cur = (f % 2u == 0u) ? bmpA : bmpB;
			ImageFormat::Bitmap& prv = (f % 2u == 0u) ? bmpB : bmpA;
			if (!w.Render(cur)) { _Fail("Render(인코더)"); return; }
			const ImageFormat::Bitmap* pp = (_deltaOn && f > 0u) ? &prv : nullptr;
			if (!MLTWorld::Pack(cur, pp, packed)) { _Fail("Pack(인코더)"); return; }
			ImageFormat::Bitmap& bmp = cur;
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
		_trA.SetSortById(true); _ptA.SetSortById(true);
		// ⭐ 회차 167 — 배치 짝짓기를 **두 코퍼스 모두**에 걸어야 한다
		_trA.SetMatchPrev(_matchOn); _ptA.SetMatchPrev(_matchOn);
		// ⭐ 회차 168 — 히스테리시스도 **두 코퍼스 모두**에
		_trA.SetHysteresis(kHysBeta[_hys]); _ptA.SetHysteresis(kHysBeta[_hys]);
		// ⭐ 회차 170 — 문턱도 두 코퍼스 모두에 · 서명 누적을 씨앗마다 초기화
		_trA.SetFloor(kFloorA[_flr]); _ptA.SetFloor(kFloorA[_flr]);
		_trA.SetLiveOnly(_liveOn); _ptA.SetLiveOnly(_liveOn);   // ⭐ 171
		_trA.ResetFilled(); _ptA.ResetFilled();
		_trA.Begin(kNCtx, kN); _ptA.Begin(kPtCtx, kN);
		_cor = 0u; _gGrp = 0u; _gIdx = 0u; _pending = false; _st = kGather;
	}

	static uint32 _NCtxOf(uint32 c) { return (c == 0u) ? kNCtx : kPtCtx; }
	static uint32 _EpiOf(uint32 c)  { return (c == 0u) ? kTrainEpi : kPtEpi; }
	static MLTP3Ctx& _CorA(uint32 c) { return (c == 0u) ? _trA : _ptA; }

	static void _Gather()
	{
		const uint32 nCtx = _NCtxOf(_cor);
		if (_pending)
		{
			Array<float> ids, mag;
			if (!_E.ReadAct(ids, mag) || ids.Count() != kCandidates) { _Fail("활성 리드백"); return; }
			const uint32 cx = _gGrp * kGroup + (_gIdx - 1u) / kTime, tt = (_gIdx - 1u) % kTime;
			// ⭐ 회차 171 — 그 프레임의 patchLive 를 잘라 넘긴다
			if (_liveOn && _liveBuf.Count() > 0u)
			{
				const uint32 fr2 = _gIdx - 1u;   // 그룹 안 프레임 색인
				_liveOne.Reset(0);
				for (uint32 p = 0; p < MLTP2Cfg::kPatches; ++p)
					_liveOne.Add(_liveBuf[fr2 * MLTP2Cfg::kPatches + p]);
				_CorA(_cor).StoreAct(cx, tt, ids, mag, _norm, &_liveOne);
			}
			else _CorA(_cor).StoreAct(cx, tt, ids, mag, _norm);
			_pending = false;
		}
		if (_gIdx == 0u)
		{
			Array<float> fr, tg; fr.Reset(0); tg.Reset(0);
			ImageFormat::Bitmap bmpA, bmpB; Bytes packed;
			const uint32 epi = _EpiOf(_cor);
			// ⭐ 회차 171 — 이 그룹의 **패치별 비영 여부**를 미리 채운다
			//   ⚠️ StoreAct 는 나중(`_pending` 처리)에 불리므로 저장해 둬야 한다.
			if (_liveOn)
			{
				_liveBuf.Reset(0);
				for (uint32 i = 0; i < kGroup * kTime * MLTP2Cfg::kPatches; ++i) _liveBuf.Add(0u);
			}
			uint32 liveSum = 0u, liveN = 0u;
			for (uint32 g = 0; g < kGroup; ++g)
			{
				const uint32 ctx = _gGrp * kGroup + g;
				MLTWorld w; w.Reset(_seed, epi + ctx, kPtHold[_pt], MLTWorldCfg::kAutoFew, kPtDt[_pt], kPtAmp[_pt]);
				for (uint32 t = 0; t < kTime; ++t)
				{
					w.Step();
					// ⭐ 회차 160 — 에피소드 첫 프레임은 **키프레임**이다
					ImageFormat::Bitmap& cur = (t % 2u == 0u) ? bmpA : bmpB;
					ImageFormat::Bitmap& prv = (t % 2u == 0u) ? bmpB : bmpA;
					if (!w.Render(cur)) { _Fail("Render(문맥)"); return; }
					const ImageFormat::Bitmap* pp = (_deltaOn && t > 0u) ? &prv : nullptr;
					if (!MLTWorld::Pack(cur, pp, packed)) { _Fail("Pack(문맥)"); return; }
					ImageFormat::Bitmap& bmp = cur;
					// ⭐ 회차 171 — 패치별 비영 여부(패치 순서는 `AppendFrame` 과 같다)
					if (_liveOn)
					{
						const uint8* pb = (const uint8*)packed.GetData();
						const uint32 fbase = (g * kTime + t) * MLTP2Cfg::kPatches;
						for (uint32 gy = 0; gy < MLTP2Cfg::kGrid; ++gy)
							for (uint32 gx = 0; gx < MLTP2Cfg::kGrid; ++gx)
							{
								uint8 live = 0u;
								for (uint32 y = 0; y < MLTP2Cfg::kPatch && live == 0u; ++y)
									for (uint32 x = 0; x < MLTP2Cfg::kPatch; ++x)
										if (pb[(gy * MLTP2Cfg::kPatch + y) * MLTP2Cfg::kSide
										       + (gx * MLTP2Cfg::kPatch + x)] != 0u) { live = 1u; break; }
								_liveBuf.Data()[fbase + gy * MLTP2Cfg::kGrid + gx] = live;
								liveSum += (uint32)live; ++liveN;
							}
					}
					MLTP2Enc::AppendFrame(fr, tg, (const uint8*)packed.GetData());
					_CorA(_cor).StoreState(ctx, t, w.State());
				}
			}
			// ⚠️ 이 하네스의 코퍼스는 **둘**(_trA=0 · _ptA=1)이다 — 처음엔 `_cor == 2u` 로 잘못 걸어
			//   서명이 0.00 으로 찍혔다. 시험 코퍼스는 **1** 이다.
			if (_liveOn && liveN > 0u && _cor == 1u)
				_liveS[_seed] = (double)liveSum / (double)liveN * 64.0;
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
		if (++_cor < 2u) return;
		_st = kMeasure;
	}

	// ── 📊 헤아리기 ────────────────────────────────────────────────
	//   ⚠️ 「변화 표적」 = 그 슬롯의 표적 id 가 **지금 그 슬롯의 id 와 다르다**.
	//   ⚠️ 「밀림」 = 그 표적 id 가 **지금 활성 8개 안**에 있다(집합은 그대로인데 자리가 밀린 것).
	// ⭐ 두 코드 사이 거리(코드북 벡터 · kPix = 192 차원)
	static float _CodeDist(uint32 a, uint32 b2)
	{
		if (a >= kN || b2 >= kN) return 1.0e30f;
		const float* pa = _code.Data() + a * MLTP2Cfg::kPix;
		const float* pb = _code.Data() + b2 * MLTP2Cfg::kPix;
		double sq = 0.0;
		for (uint32 d = 0; d < MLTP2Cfg::kPix; ++d)
		{ const double e = (double)pa[d] - (double)pb[d]; sq += e * e; }
		return (float)Sqrt((float)sq);
	}

	// ⭐ 회차 166 — 문턱을 **규칙으로** 계산한다(코퍼스를 보기 전이 아니라
	//   *"등장하는 코드만"* 이라 코퍼스의 **id 집합**은 쓴다 — ⚠️ 표적 분포는 안 쓴다).
	static void _SupThreshold(const MLTP3Ctx& C, uint32 nCtx)
	{
		_supTh = 0.0f; _supNN = 0.0f; _supUsed = 0u;
		Array<uint8> seen; seen.Reset(0);
		for (uint32 i = 0; i < kN; ++i) seen.Add(0u);
		for (uint32 ctx = 0; ctx < nCtx; ++ctx)
			for (uint32 tt = 0; tt < kTime; ++tt)
			{
				const uint32 b = MLTP3Ctx::Row(ctx, tt, kStateAx);
				for (uint32 j = 0; j < kSlots; ++j)
				{
					const uint32 id = (uint32)(C.Sym()[b + j] - (float)kStateAx);
					if (id < kN) seen.Data()[id] = 1u;
					const float tf = C.Tgt()[b + j];
					if (tf >= 0.0f && tf < (float)kN) seen.Data()[(uint32)tf] = 1u;
				}
			}
		Array<uint32> ids; ids.Reset(0);
		for (uint32 i = 0; i < kN; ++i) if (seen[i] != 0u) ids.Add(i);
		_supUsed = ids.Count();
		if (ids.Count() < 2u) return;
		// 각 코드의 최근접 이웃 거리
		Array<float> nn; nn.Reset(0);
		for (uint32 a = 0; a < ids.Count(); ++a)
		{
			float best = 1.0e30f;
			for (uint32 b2 = 0; b2 < ids.Count(); ++b2)
			{
				if (a == b2) continue;
				const float d = _CodeDist(ids[a], ids[b2]);
				if (d < best) best = d;
			}
			nn.Add(best);
		}
		// 중앙값(셸 정렬 — n ≈ 50)
		for (uint32 gap = nn.Count() / 2u; gap > 0u; gap /= 2u)
			for (uint32 i = gap; i < nn.Count(); ++i)
			{
				const float key = nn[i]; uint32 k = i;
				while (k >= gap && nn[k - gap] > key) { nn.Data()[k] = nn[k - gap]; k -= gap; }
				nn.Data()[k] = key;
			}
		_supNN = nn[nn.Count() / 2u];
		_supTh = kSupTheta[_sup] * _supNN;
	}

	static bool _IsChange(const MLTP3Ctx& C, uint32 b, uint32 j, uint32& outTid)
	{
		const float tf = C.Tgt()[b + j];
		if (!(tf >= 0.0f && tf < (float)kN)) return false;
		outTid = (uint32)tf;
		const uint32 now = (uint32)(C.Sym()[b + j] - (float)kStateAx);
		if (now == outTid) return false;                     // 같은 id ⇒ 지속
		// ⭐ 회차 166 — **미세 변화 억제**: 두 코드가 문턱보다 가까우면 **지속**으로 센다
		if (_supTh > 0.0f && _CodeDist(now, outTid) < _supTh) return false;
		return true;
	}

	static bool _InActive(const MLTP3Ctx& C, uint32 b, uint32 tid)
	{
		for (uint32 q = 0; q < kSlots; ++q)
			if ((uint32)(C.Sym()[b + q] - (float)kStateAx) == tid) return true;
		return false;
	}

	// 변화 표적의 히스토그램 + 밀림 비율. `hist` 는 kN 길이.
	static void _Hist(const MLTP3Ctx& C, uint32 nCtx, Array<uint32>& hist,
		uint32& outN, uint32& outShift, Array<uint32>* histShift, Array<uint32>* histNew)
	{
		hist.Reset(0);
		for (uint32 i = 0; i < kN; ++i) hist.Add(0u);
		if (histShift) { histShift->Reset(0); for (uint32 i = 0; i < kN; ++i) histShift->Add(0u); }
		if (histNew)   { histNew->Reset(0);   for (uint32 i = 0; i < kN; ++i) histNew->Add(0u); }
		outN = 0u; outShift = 0u;
		for (uint32 ctx = 0; ctx < nCtx; ++ctx)
			for (uint32 t = 0; t < kTime; ++t)
			{
				const uint32 b = MLTP3Ctx::Row(ctx, t, kStateAx);
				for (uint32 j = 0; j < kSlots; ++j)
				{
					uint32 tid = 0u;
					if (!_IsChange(C, b, j, tid)) continue;
					++outN; ++hist.Data()[tid];
					if (_InActive(C, b, tid))
					{
						++outShift;
						if (histShift) ++histShift->Data()[tid];
					}
					else if (histNew) ++histNew->Data()[tid];
				}
			}
	}

	static double _Entropy(const Array<uint32>& h, uint32 n)
	{
		if (n == 0u) return 0.0;
		double e = 0.0;
		for (uint32 i = 0; i < h.Count(); ++i)
		{
			if (h[i] == 0u) continue;
			const double p = (double)h[i] / (double)n;
			e += -p * (double)Log((float)p);
		}
		return e;
	}

	static void _Normalize(const Array<uint32>& h, uint32 n, Array<double>& p)
	{
		p.Reset(0);
		for (uint32 i = 0; i < kN; ++i) p.Add((n == 0u) ? 0.0 : (double)h[i] / (double)n);
	}

	static double _Clamp(double p) { return (p < 1.0e-9) ? 1.0e-9 : p; }

	static void _Measure()
	{
		// ⭐ 회차 166 — **문턱을 학습 코퍼스에서만** 계산한다(시험에서 잡으면 훔쳐보기).
		//   ⚠️ `_IsChange` 가 이 값을 쓰므로 **모든 히스토그램보다 먼저** 불려야 한다.
		// ⭐ 170 서명 — 시험 코퍼스에서 실제로 채운 슬롯 수(평균)
		_fillS[_seed] = (_ptA.FilledN() == 0u) ? 0.0
			: (double)_ptA.FilledSum() / (double)_ptA.FilledN();
		_SupThreshold(_trA, kNCtx);
		_supThS[_seed] = (double)_supTh; _supNNS[_seed] = (double)_supNN;
		_supUsedS[_seed] = (double)_supUsed;
		// ── 학습 코퍼스에서: 전체 주변분포 · 변화-only 주변분포 · 밀림 비율 α ──
		Array<float> margAllF;
		_trA.Marginal(margAllF);                       // 전체 표적 주변분포(kN)
		Array<uint32> hTr; uint32 nTr = 0u, sTr = 0u;
		_Hist(_trA, kNCtx, hTr, nTr, sTr, nullptr, nullptr);
		Array<double> pTrCh; _Normalize(hTr, nTr, pTrCh);
		const double alpha = (nTr == 0u) ? 0.0 : (double)sTr / (double)nTr;
		_shiftTr[_seed] = alpha;

		// ── 시험 코퍼스에서: 변화 표적 히스토그램(오라클) + 분해 ──
		Array<uint32> hPt, hSh, hNw; uint32 nPt = 0u, sPt = 0u;
		_Hist(_ptA, kPtCtx, hPt, nPt, sPt, &hSh, &hNw);
		Array<double> pPtCh; _Normalize(hPt, nPt, pPtCh);
		_nCh[_seed]    = (double)nPt / (double)kPtCtx;
		_shiftTe[_seed] = (nPt == 0u) ? 0.0 : (double)sPt / (double)nPt;
		_hAll[_seed]   = _Entropy(hPt, nPt);
		_hShift[_seed] = _Entropy(hSh, sPt);
		_hNew[_seed]   = _Entropy(hNw, nPt - sPt);

		// ── 예측기 다섯의 CE(변화 표적당 나트) ──
		double sum[kPreds], sumS[kPreds], sumN[kPreds];
		for (uint32 p = 0; p < kPreds; ++p) { sum[p] = 0.0; sumS[p] = 0.0; sumN[p] = 0.0; }
		uint32 cnt = 0u, cntS = 0u, cntN = 0u;
		for (uint32 ctx = 0; ctx < kPtCtx; ++ctx)
			for (uint32 t = 0; t < kTime; ++t)
			{
				const uint32 b = MLTP3Ctx::Row(ctx, t, kStateAx);
				for (uint32 j = 0; j < kSlots; ++j)
				{
					uint32 tid = 0u;
					if (!_IsChange(_ptA, b, j, tid)) continue;
					++cnt;
					const uint32 cur = (uint32)(_ptA.Sym()[b + j] - (float)kStateAx);
					const bool isShift = _InActive(_ptA, b, tid);
					if (isShift) ++cntS; else ++cntN;
					double one[kPreds];

					// ㉠a 학습 전체 주변분포
					one[0] = -Log((float)_Clamp((double)margAllF[tid]));
					// ㉠b 학습 변화-only 주변분포
					one[1] = -Log((float)_Clamp(pTrCh[tid]));
					// ㉡ 시험 주변분포(오라클 · 142 검산)
					one[2] = -Log((float)_Clamp(pPtCh[tid]));

					// ㉢ 그 슬롯의 지금 id 만 배제하고 재정규화(늘 유효하다)
					{
						const double z = 1.0 - pTrCh[cur];
						one[3] = -Log((float)_Clamp((z > 1.0e-9) ? pTrCh[tid] / z : pTrCh[tid]));
					}

					// ⭐ ㉣ 밀림 인지 — α 로 「지금 활성(그 슬롯 제외)」 ↔ 「밖」 혼합
					{
						double zIn = 0.0, zOut = 0.0;
						for (uint32 q = 0; q < kSlots; ++q)
						{
							const uint32 aid = (uint32)(_ptA.Sym()[b + q] - (float)kStateAx);
							if (aid == cur) continue;
							zIn += pTrCh[aid];
						}
						for (uint32 y = 0; y < kN; ++y)
							if (!_InActive(_ptA, b, y)) zOut += pTrCh[y];
						double p = 0.0;
						if (isShift && zIn > 1.0e-12)     p += alpha * (pTrCh[tid] / zIn);
						if (!isShift && zOut > 1.0e-12)   p += (1.0 - alpha) * (pTrCh[tid] / zOut);
						one[4] = -Log((float)_Clamp(p));
					}
					for (uint32 p = 0; p < kPreds; ++p)
					{
						sum[p] += one[p];
						if (isShift) sumS[p] += one[p]; else sumN[p] += one[p];
					}
				}
			}
		for (uint32 p = 0; p < kPreds; ++p)
		{
			_ce[p][_seed]  = (cnt  == 0u) ? 0.0 : sum[p]  / (double)cnt;
			_ceS[p][_seed] = (cntS == 0u) ? 0.0 : sumS[p] / (double)cntS;
			_ceN[p][_seed] = (cntN == 0u) ? 0.0 : sumN[p] / (double)cntN;
		}
		// ⭐ 갈래 엔트로피 — ㉣ 가 「밀림인가 새id인가」를 모르는 채 섞느라 무는 비용
		_branch[_seed] = -alpha * (double)Log((float)_Clamp(alpha))
			- (1.0 - alpha) * (double)Log((float)_Clamp(1.0 - alpha));

		LogA("[mlt] 🧮 씨앗 %2u · 변화 표적 **%.1f/문맥**(%u) · 밀림 **시험 %.1f%% / 학습 %.1f%%(=α)**\n",
			_seed, _nCh[_seed], cnt, 100.0 * _shiftTe[_seed], 100.0 * alpha);
		LogA("[mlt] 🧮   H — 전체 **%.4f** · 밀림 %.4f · 새id %.4f\n", _hAll[_seed], _hShift[_seed], _hNew[_seed]);
		for (uint32 p = 0; p < kPreds; ++p)
			LogA("[mlt] 🧮   %s CE **%.4f**(밀림 %.4f · 새id %.4f)\n",
				_PName(p), _ce[p][_seed], _ceS[p][_seed], _ceN[p][_seed]);
		LogA("[mlt] 🧮   ⭐ 갈래 엔트로피 H(α) = **%.4f** 나트 — ㉣ 가 무는 비용\n", _branch[_seed]);
		++_seed; _st = kEncInit;
	}

	static void _MeanSd(const double* v, double& m, double& sd)
	{
		m = 0.0; for (uint32 s = 0; s < _seeds; ++s) m += v[s];
		m /= (double)_seeds;
		double q = 0.0;
		for (uint32 s = 0; s < _seeds; ++s) { const double e = v[s] - m; q += e * e; }
		sd = (_seeds > 1u) ? Sqrt((float)(q / (double)(_seeds - 1u))) : 0.0;
	}

	static void _Summary()
	{
		double nm, nsd, stm, stsd, sam, sasd, ham, hasd, hsm, hssd, hnm, hnsd;
		_MeanSd(_nCh, nm, nsd); _MeanSd(_shiftTe, stm, stsd); _MeanSd(_shiftTr, sam, sasd);
		_MeanSd(_hAll, ham, hasd); _MeanSd(_hShift, hsm, hssd); _MeanSd(_hNew, hnm, hnsd);

		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🧮 **회차 160 · 변화 표적을 배우나** (씨앗 %u · 학습 0 · 유한 %s)\n", _seeds, _ok ? "✅" : "⛔");
		LogA("[mlt] 🧮   ── ① 변화 표적의 정체 ──\n");
		LogA("[mlt] 🧮     변화 표적 **%.1f/문맥**(±%.1f) — 기대 **%.1f**(%s)\n",
			nm, nsd, _deltaOn ? (double)kNd159 : 14.0, _deltaOn ? "159 델타" : "141·142 절대");
		{   // ⭐ 회차 166 — 억제 서명(성능보다 먼저 · 규율 21)
			double thm, ths, nnm, nns, usm, uss;
			_MeanSd(_supThS, thm, ths); _MeanSd(_supNNS, nnm, nns); _MeanSd(_supUsedS, usm, uss);
			LogA("[mlt] 🧽     🧽 **억제** θ **%.2f** · 이웃거리 중앙값 **%.4f**(±%.4f) · 문턱 **%.4f** · 등장 코드 **%.1f** 개\n",
				(double)kSupTheta[_sup], nnm, nns, thm, usm);
			double lim, lis; _MeanSd(_liveS, lim, lis);
			if (_liveOn)
				LogA("[mlt] 🩻     🩻 **산 패치 수** **%.2f**/64(±%.2f)\n", lim, lis);
			double fim, fis; _MeanSd(_fillS, fim, fis);
			LogA("[mlt] 🕳️     🕳️ **채운 슬롯 수** α **%.2f** → **%.2f**/8(±%.2f) · 등장 코드/슬롯 비 **%.2f**\n",
				(double)kFloorA[_flr], fim, fis, usm / 8.0);
		}
		LogA("[mlt] 🧮     ⭐ **밀림 비율** — 시험 **%.1f%%**(±%.1f) · 학습 **%.1f%%**(=α) · 예측은 54%%였다\n",
			100.0 * stm, 100.0 * stsd, 100.0 * sam);
		LogA("[mlt] 🧮     H — 전체 **%.4f** · **밀림 %.4f** · **새id %.4f** 나트\n", ham, hsm, hnm);
		LogA("[mlt] 🧮   ── ② ⭐ **예측기 다섯 vs 몸통**(변화 표적당 나트) ──\n");
		double m[kPreds], sd[kPreds], mS[kPreds], mN[kPreds], dmy;
		for (uint32 p = 0; p < kPreds; ++p)
		{
			_MeanSd(_ce[p], m[p], sd[p]);
			_MeanSd(_ceS[p], mS[p], dmy); _MeanSd(_ceN[p], mN[p], dmy);
			if (_BodyKnown())
				LogA("[mlt] 🧮     %s │ **%.4f**(±%.4f) │ 밀림 %.4f · 새id %.4f │ 몸통(%.4f) 대비 %s **%+.4f**\n",
					_PName(p), m[p], sd[p], mS[p], mN[p], (double)kCE141,
					((double)kCE141 > m[p]) ? "⛔ 몸통이 나쁘다" : "✅ 몸통이 낫다",
					(double)kCE141 - m[p]);
			else
				LogA("[mlt] 🧮     %s │ **%.4f**(±%.4f) │ 밀림 %.4f · 새id %.4f │ ⚠️ 몸통 미측정\n",
					_PName(p), m[p], sd[p], mS[p], mN[p]);
		}
		double brm, brsd; _MeanSd(_branch, brm, brsd);
		LogA("[mlt] 🧮     ⭐ **갈래 엔트로피 `H(α)` = %.4f 나트** — ㉣ 가 「밀림인가 새id인가」를\n", brm);
		LogA("[mlt] 🧮        모르는 채 섞느라 무는 비용이다(㉢ 대비 %+.4f 만큼 좁혔는지 견준다)\n", m[3] - m[4] + brm);

		// ── 관문 ────────────────────────────────────────────────────
		//   ⚠️⚠️ **검산은 씨앗 3 이상에서만** — 1씨앗 진단이 이 관문을 ⛔ 로 찍었는데
		//     그것은 **12씨앗 평균(회차 142)과 1씨앗 값을 견준** 것이었다(규율 51 의 또 다른 얼굴).
		//     ★ 코퍼스 동일성의 진짜 증거는 **변화 표적 수**이고 그것은 씨앗 0 에서 12.4 로 같았다.
		const double href = _deltaOn ? (double)kH159d : (double)kH142;   // ⭐ 팔마다 상대가 다르다
		const double chk = Abs((float)(m[2] - href));
		// ⚠️⚠️ 회차 165 — **점 0(기본 세계)에서만** 검산한다(다른 점은 세계가 다르다 · 규율 57)
		// ⚠️⚠️ 회차 166 — **억제가 켜지면 표적 정의가 바뀐다** ⇒ 검산 상대가 없다(규율 57)
		// ⚠️⚠️ 회차 167 — 짝짓기가 켜지면 **표적 정의가 바뀐다** ⇒ 검산 상대가 없다(규율 57)
		// ⚠️⚠️ 회차 168 — 히스테리시스도 **표적 정의를 바꾼다**(규율 57)
		const bool chkApply = (_seeds >= 3u) && (_pt == 0u) && (_sup == 0u)
			&& !_matchOn && (_hys == 0u) && (_flr == 0u) && !_liveOn;   // ⭐ 170·171
		const bool gChk = !chkApply || (chk <= 0.02);
		LogA("[mlt] 🧮   ── 관문 ──\n");
		LogA("[mlt] 🧮     ⭐ **검산**(㉡ 가 회차 %s 의 %.4f ± 0.02) — %.4f · 차 %.4f → %s\n",
			_deltaOn ? "159(델타)" : "142(절대)", href, m[2], chk,
			!chkApply ? "⚠️ 건너뜀(씨앗 3 이상에서만 — 규율 51)" : (gChk ? "✅" : "⛔ **코퍼스가 다르다**"));
		// ⭐ 목표선 = 예측기 다섯 중 **최선**(= 학습 0 이 닿는 가장 낮은 CE)
		uint32 best = 0u;
		for (uint32 p = 1; p < kPreds; ++p) if (m[p] < m[best]) best = p;
		LogA("[mlt] 🧮     ⭐ **목표선** = %s · **%.4f** 나트 (%s)\n",
			_PName(best), m[best], _deltaOn ? "★ 델타판 새 값" : "143 은 2.1111 이었다");
		uint32 worse = 0u;
		for (uint32 p = 0; p < kPreds; ++p) if ((double)kCE141 > m[p]) ++worse;
		if (_BodyKnown())
			LogA("[mlt] 🧮     ⭐ **표제** — 몸통이 예측기 **%u/%u** 보다 나쁘다\n", worse, kPreds);

		// ── 판정 ────────────────────────────────────────────────────
		if (!_ok)                LogA("[mlt] 🧮   ⭐ 판정 = ⛔ **판정불가** — 배관이 안 섰다\n");
		else if (!gChk)          LogA("[mlt] 🧮   ⭐ 판정 = ⛔ **판정불가** — ***검산이 깨졌다***(같은 코퍼스가 아니다)\n");
		else if (_seeds == 1u)   LogA("[mlt] 🧮   ⭐ **1씨앗 진단이다 — 판정하지 않는다**(규율 51)\n");
		else if (!_BodyKnown())
			LogA("[mlt] 🧮   ⭐ 판정 = ✅ **델타판 목표선을 세웠다** — %.4f 나트(절대판은 2.1111)\n"
			     "[mlt] 🧮      ⚠️ **몸통은 안 잰다** ⇒ ★ 다음 회차가 141 의 자(`mltl1d0`)를 델타판으로 돌린다\n", m[best]);
		else if ((double)kCE141 > m[1] && (double)kCE141 > m[3] && (double)kCE141 > m[4])
			LogA("[mlt] 🧮   ⭐ 판정 = ⛔⛔⛔ ***몸통은 변화 표적을 못 배웠다*** — 학습 0 예측기 셋보다 나쁘다\n"
			     "[mlt] 🧮      ⇒ ★ 다음 물음 = ***왜 못 배우나***(용량 · 손실 가중 · **지속 표적이 손실을 먹나**)\n");
		else if ((double)kCE141 > m[4])
			LogA("[mlt] 🧮   ⭐ 판정 = ⚠️ **조금 배웠지만 「정렬 규칙」은 못 배웠다** — ㉣ 보다 나쁘다\n"
			     "[mlt] 🧮      ⇒ ★ 다음은 **밀림(a)과 새id(b)를 갈라** 어느 쪽을 못 하는지 본다\n");
		else
			LogA("[mlt] 🧮   ⭐ 판정 = ✅ **몸통이 학습 0 예측기 전부보다 낫다** ⇒ ⚠️ 회차 142 의 해석을 철회한다\n");
		if (_BodyKnown())
			LogA("[mlt] 🧮   ⚠️ 몸통 CE 는 **회차 141 의 값**이고 여기서 새로 재지 않았다(같은 코퍼스·같은 마스크)\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		_E.Destroy(); _done = true;
	}

	static void _Fail(const char* why)
	{
		LogA("[mlt] 🧮 ⛔ %s (씨앗 %u · 단계 %u · 코퍼스 %u · 걸음 %u)\n", why, _seed, _st, _cor, _step);
		_ok = false; _E.Destroy(); _done = true;
	}

	CW_BODY(MLTL1P0)
};
