// mltl1j0.cw — ⚖️ 회차 147 · **에너지 채널 거르기 + 세계 서명** (`-mlt -mltl1j0`)
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 147 이다.** ⭐ **하네스보다 먼저 썼다.**
//   **상위 캔버스: `부호 있는 자기 입력 채널` · 147~ = 1회차**(캔버스를 바꿨으므로 파일럿).
//   ⚠️⚠️ **세계를 고치는 판이다** ⇒ **규율 21** 이 그 자리에 그대로 적용된다.
//
// ── ⭐ 표제 — ***에너지 채널이 변화 표적을 가르나***(눈금 대비 ≥ 0.10) ──
//   회차 142 가 후보 넷(`nOn`·`minEdge`·`maxR`·`minDOn`)을 **전부 바닥**(눈금의 1%)으로 걸렀다.
//   ⇒ ★ 그 넷은 **지금 프레임의 순간 함수**였고, 에너지는 **누적기**다(역사에서 온다).
//   ⚠️ 그러나 그것이 통과를 **보장하지 않는다** — 그래서 거르기 회차다(138·139·142 의 교훈).
//
// ── ⭐ 근거 = `mltconcept.md` 「⚖️ 부호 있는 자기 입력 채널이 최소 하나」 ──
//   ★ 판정 기준 한 줄: ***관측에서 유도되면 라벨, 역사에서 오면 상태.***
//     ⇒ `VisibleShapes` 것들은 앞이고 **에너지는 뒤**다. ⚠️ 그래도 **이름은 안 준다**
//       (슬롯에 놓는 것은 **불투명 스칼라 하나**다 — 매핑 금지).
//
// ── 🎛️ 후보 넷 ───────────────────────────────────────────────────────────
//   ⭐ ㈠ **에너지** 8분위(표제) · ㈡ **섞은 에너지**(⚠️ 이것이 통과하면 **자가 죽은 것**) ·
//   ㈢ `minDOn`(**참조** — 142 의 바닥이 ON 세계에서도 바닥인가) ·
//   ⭐ ㈣ **변화 표적 id**(**눈금** · 규율 16 · ⚠️ ON 세계에서 **다시 잰다**)
//
// ── 🚦 서명 — ⚠️⚠️ **성능보다 먼저 찍는다**(규율 21) ─────────────────────
//   1 `E` 평균·**sd**(≈0 이면 상수) · 2 **자기상관 lag1**(≈1 이면 상수 · ≈0 이면 누적기 아님) ·
//   3 ⭐ **둔화 발동/에피소드**(0 이면 ㈂ 기능적 결과가 죽었다) ·
//   4 ⭐ **변화 표적 수/문맥**(145·146 은 **14.0** — 줄면 *"세계를 조용하게 만든 것"*) ·
//   5 ⭐ **OFF↔ON 상태열이 갈리나**(비트 동일이면 플래그가 안 먹었다)
//
// ── 📏 자 ─────────────────────────────────────────────────────────────────
//   `거르기 = (Î − Î섞음) / 눈금(㈣)` ≥ 0.10 이고 부호 10/12.
//   ⚠️⚠️ **`Î` 는 무조건부다** ⇒ **거르는 자**이지 판정하는 자가 아니다(규율 50).
//   ⚠️ 표적은 **변화 표적만** 센다(141 의 자가 채점하는 그 자리).
//
// ── 🔮 예측(재기 전에 적었다) ────────────────────────────────────────────
//   `E` sd 0.20~0.30 · 자기상관 0.75~0.93 · 둔화 1~4/에피소드 · 변화 표적 11~14
//   ⭐ 표제 = **통과할 것**(눈금 대비 **0.15~0.45**). ★ 근거: 회차 86~100 에서
//     **자기상태 축 `yaw` 의 여유가 0.52**(관측 `minDOn` 은 **0.019**)였고 `E` 도 자기상태 축이다.
//   ㈢ `minDOn` ⛔ 바닥 유지(≤0.03 · 142 재현)
//   ⚠️ 갈래: ㈠ 이 ⛔ 면 **손잡이 넷을 돌린다**(`D`·`G`·`Low`·`Slow`) — 판정 회차를 **안 태운다**.
// ══════════════════════════════════════════════════════════════════════════════

using namespace PE;

class MLTL1J0
{
public:
	static void Tick(RHI* rhi)
	{
		if (_done || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltl1j0"))
		{
			LogA("[mlt] ⚖️ 회차 147(에너지 채널 거르기 + 세계 서명)은 **꺼져 있다**(`-mltl1j0`)\n");
			_done = true; return;
		}
		// ⚖️⚖️ **회차 266(칸 15)** — `-mltjbody` = **몸을 켠 채로 같은 거르기를 다시 잰다**
		//   ★ 규율 6·49: **새 자를 만들지 않는다** — 147 의 이 자를 그대로 쓴다.
		//     ⇒ 그러면 147 의 「눈금 대비 0.5%」와 **같은 자에서** 견줄 수 있다(ML 규율 74).
		//   ⚠️ 기본 꺼짐이므로 `-mltl1j0` 단독은 **147 그대로**다(그것이 이번 판의 기준선 팔이다).
		if (!_banner)
		{
			_seeds = OS::CommandLine::Has("-mltdiag1") ? 1u : kSeedsMax;
			_bodyOn = OS::CommandLine::Has("-mltjbody");
			_w2on   = OS::CommandLine::Has("-mltjw2");
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
	// ⚖️⚖️ 266 — **몸**(`-mltjbody`) · ⚠️ 기본 꺼짐 ⇒ 단독 실행은 147 과 **같은 세계**다
	inline static bool _bodyOn = false;
	inline static double _biasSum = 0.0;  inline static uint32 _biasN = 0u;
	inline static double _pickSum = 0.0;                      // ⭐ 📌 D71 — 발동 수의 분모
	inline static double _sgBias[kSeedsMax] = { 0.0 };
	inline static double _sgPick[kSeedsMax] = { 0.0 };
	// ⚖️⚖️ 267 — **학습 자의 세계**(`-mltjw2`) · ⚠️ 기본 꺼짐 ⇒ 단독은 147 의 세계 그대로
	//   ⛔⛔ **266 이 그 대가를 치렀다**: 147 의 세계는 **옛 세계(`w2`=0) · 자율 1개**라
	//     *"도형 14 중 1개만 움직이고 나머지는 월드에서 정지"*(198 의 진단) ⇒ **먹이가 거의 안 보인다**
	//     ⇒ 반사÷둔화가 **0.12** 였다(265 의 세계는 0.75) ⇒ 몸이 거의 없는 세계에서 거르기를 쟀다.
	//   ⭐ 그리고 **220 의 교훈이 그것**이다(*"학습 자와 같은 세계에서 재라"*) —
	//     ⚠️ `mltl1j0` 은 **147 에 만들어져 220 보다 먼저**다 ⇒ 그 세계가 낡은 것이다.
	//   ⇒ ★ 학습 자의 자리 = `SetWorld2(2)` 궤도 · `kAutoMany`(3) · `dt` **1.00** · `amp` **5.00**
	//     (= `mltl1s0::kTrDt`/`kTrAmp` · `mltl1t0` 의 방향 모드 그 자리)
	inline static bool _w2on = false;
	static constexpr float kTrDt  = 1.00f;
	static constexpr float kTrAmp = 5.00f;

	static constexpr uint32 kEncF = 32u, kEncSteps = 1200u, kEncPerTick = 8u;
	static constexpr uint32 kN = 250u, kLocal = 8u;
	static constexpr uint32 kTime  = MLTP3Ctx::kTime;      // 8
	static constexpr uint32 kBatch = MLTP3Ctx::kBatch;     // 8
	static constexpr uint32 kSlots = MLTP3Ctx::kPersist;   // 8
	static constexpr uint32 kStateAx = MLTP3Ctx::kStateAx; // 5
	static constexpr uint32 kCandidates = MLTP2Cfg::kPatches * kLocal;
	static constexpr uint32 kGroup = kEncF / kTime;        // 4

	// ⭐ **시험 코퍼스만** 모은다(`_trA`·`_pbA` 는 이 회차에서 안 쓴다) ⇒ 회차 140 의 1/3 비용.
	//   ⚠️ `_ptA` 는 같은 씨앗·같은 `epi` 라 **138~141 과 같은 코퍼스**다(인코더도 같은 학습).
	static constexpr uint32 kPtCtx = 512u, kPtEpi = 5001u;
	static constexpr uint32 kWords = kPtCtx * kTime;       // 4096
	static constexpr float  kNoShape = 1.0e6f;

	// 후보 다섯 — 앞 넷은 연속값(8분위 순위), ㈤ 는 141 의 계급(0 = 변화 없음 · 1~8)
	// 후보 넷 — `[0]` ⭐ 에너지(연속 · 8분위) · `[1]` 섞은 에너지 · `[2]` `minDOn`(참조) ·
	//   `[3]` 눈금(변화 표적 id · 9계급). ⚠️ 앞 **셋**만 순위 계급을 매긴다.
	static constexpr uint32 kCands = 4u, kRawCands = 2u;
	// ⭐ 밖에서 온 눈금 — ⚠️ 여기서 새로 재지 않는다.
	static constexpr double kChTgt145 = 14.0;   // 회차 145·146 의 변화 표적 수/문맥(서명 4 의 상대)
	static constexpr uint32 kCls = 8u;        // 연속 후보의 계급 수
	static constexpr uint32 kRefCls = 9u;     // ㈤ 양성 참조

	enum { kEncInit, kEncTrain, kGather, kMeasure };

	inline static MLTP2Enc _E;
	inline static MLTP3Ctx _ptA;
	inline static bool _done = false, _banner = false, _encSetup = false, _ok = true;
	inline static bool _pending = false;
	inline static uint32 _seed = 0u, _st = kEncInit, _step = 0u;
	inline static uint32 _gGrp = 0u, _gIdx = 0u;
	inline static Array<float> _code, _norm;
	inline static Array<float> _raw[kRawCands];      // [ctx*kTime + t]
	inline static Array<uint32> _w[kCands];

	inline static double _mi[kCands][kSeedsMax], _miS[kCands][kSeedsMax], _hW[kCands][kSeedsMax];
	inline static double _nCh[kSeedsMax], _hY[kSeedsMax];
	inline static double _hYlast = 0.0, _hCntLast = 0.0;
	// ⭐ 「변화의 **양**」 자 — `Î(낱말 ; 바뀌는 슬롯 개수)` 와 그 섞음 바닥
	inline static double _miC[kCands][kSeedsMax], _miCS[kCands][kSeedsMax], _hCnt[kSeedsMax];
	inline static uint32 _posC[kCands];
	inline static uint32 _pos[kCands];               // `Î−Î섞음 > 0` 인 씨앗 수

	// ── 🚦 **세계의 서명**(규율 21) — ⚠️ 성능보다 먼저 찍는다 ────────────
	inline static double _eSum = 0.0, _eSq = 0.0, _acXY = 0.0, _divSum = 0.0, _slowSum = 0.0;
	inline static uint32 _eN = 0u, _acN = 0u, _divN = 0u, _divZero = 0u, _slowN = 0u;
	inline static float  _eMin = 1.0e9f, _eMax = -1.0e9f, _ePrev = 0.0f, _divMax = 0.0f;
	// 씨앗별 서명(평균±sd 로 보고한다)
	inline static double _sgMean[kSeedsMax], _sgSd[kSeedsMax], _sgAc[kSeedsMax],
	                     _sgSlow[kSeedsMax], _sgDiv[kSeedsMax];
	inline static uint32 _sgZero[kSeedsMax];

	static void _SigReset()
	{
		_eSum = 0.0; _eSq = 0.0; _acXY = 0.0; _divSum = 0.0; _slowSum = 0.0;
		_eN = 0u; _acN = 0u; _divN = 0u; _divZero = 0u; _slowN = 0u;
		_biasSum = 0.0; _biasN = 0u; _pickSum = 0.0;   // ⚖️⚖️ 266·267 — 몸의 서명도 씨앗마다 비운다
		_eMin = 1.0e9f; _eMax = -1.0e9f; _ePrev = 0.0f; _divMax = 0.0f;
	}

	static const char* _Name(uint32 c)
	{
		switch (c)
		{
		case 0u: return "㈠ 에너지 ⭐       ";
		case 1u: return "㈡ 섞은 에너지(바닥) ";
		case 2u: return "㈢ minDOn (142 참조) ";
		default: return "㈣ 변화표적id(눈금)⭐";
		}
	}

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] ⚖️ **회차 147 · 에너지 채널 거르기 + 세계 서명**(⭐ 학습 0 · %s)\n",
			(_seeds == 1u) ? "⚠️ 1씨앗 진단" : "씨앗 12");
		LogA("[mlt] ⚖️   ⭐ 표제 = ***에너지 채널이 변화 표적을 가르나***(눈금 대비 ≥ 0.10)\n");
		LogA("[mlt] ⚖️   ⭐ 근거 = 컨셉의 판정 기준 한 줄 — ***관측에서 유도되면 라벨, 역사에서 오면 상태***\n");
		LogA("[mlt] ⚖️      ⇒ 142 의 후보 넷은 **프레임의 순간 함수**(앞)였고 **에너지는 누적기**(뒤)다\n");
		LogA("[mlt] ⚖️      ⚠️ 그래도 **이름은 안 준다** — 슬롯에 놓는 것은 **불투명 스칼라 하나**다(매핑 금지)\n");
		LogA("[mlt] ⚖️   후보 넷 — ⭐ ㈠ **에너지**(표제) · ㈡ 섞은 에너지(⚠️ 통과하면 **자가 죽었다**) ·\n");
		LogA("[mlt] ⚖️      ㈢ minDOn(**참조** — 142 재현) · ⭐ ㈣ 변화 표적 id(**눈금** · ON 세계에서 다시 잰다)\n");
		LogA("[mlt] ⚖️   🚦 ⚠️⚠️ **서명을 성능보다 먼저 찍는다**(규율 21) — sd · 자기상관 · **둔화 발동** ·\n");
		LogA("[mlt] ⚖️      ⭐ **변화 표적 수/문맥**(145·146 은 %.1f · 줄면 *\"세계를 조용하게 만든 것\"*) · OFF↔ON 갈림\n",
			kChTgt145);
		LogA("[mlt] ⚖️   ⭐ 관문 = 후보가 `Î−Î섞음>0` **%u/%u** 이고 **눈금 대비 ≥ 0.10**\n",
			(_seeds * 10u + 11u) / 12u, _seeds);
		LogA("[mlt] ⚖️   ⭐ 예측 — E sd 0.20~0.30 · 자기상관 0.75~0.93 · 둔화 1~4 · 변화표적 11~14\n");
		LogA("[mlt] ⚖️      ⭐ 표제 **통과할 것**(0.15~0.45) · ㈢ 바닥 유지(≤0.03)\n");
		// ⚖️⚖️ 266(칸 15) — 🔒 **방벽 ②**: 이 판이 **무엇을 보고 있는지** 한 줄로 찍는다
		//   ⛔ D61 이 그 값을 치렀다(옛 바이너리를 45초 만에 잡은 것이 이 줄이다).
		// ⚖️⚖️ 267 — 🔒 **방벽 ② 의 나머지 반쪽**: **세계 인자**를 찍는다(📌 D70 의 ㈀)
		//   ⛔ 266 은 「몸 켬/꺼짐」만 찍고 세계를 안 찍어서 ***다른 세계에서 쟀다는 것을 판정 뒤에 알았다.***
		LogA("[mlt] ⚖️   🔒 ⭐ **세계** — `w2` **%d**%s · 자율 **%d** · dt **%.2f** · amp **%.2f**\n",
			_w2on ? 2 : 0, _w2on ? "(궤도 · 전 도형이 움직인다)" : "(⚠️ 옛 세계 · 147 의 자리)",
			_w2on ? MLTWorldCfg::kAutoMany : MLTWorldCfg::kAutoFew,
			(double)kTrDt, (double)(_w2on ? kTrAmp : 1.00f));
		if (_w2on)
			LogA("[mlt] ⚖️      ⇒ ★ **학습 자와 같은 세계**다(`mltl1s0::kTrDt`/`kTrAmp` · 220 의 교훈)\n");
		else
			LogA("[mlt] ⚖️      ⚠️ **147 의 세계**다 — 학습 자와 다르다(`-mltjw2` 로 맞춘다 · 220 의 교훈)\n");
		LogA("[mlt] ⚖️   🔒 ⭐ **몸 = %s**%s\n",
			_bodyOn ? "**켬**(이득이 외형에 · 반사 돈다)" : "꺼짐(147 그대로 = 기준선 팔)",
			_bodyOn
				? "  ⇒ 🔮 **회차 266 의 예측 ②**: 147 의 **0.5%** 에서 오른다"
				  "(근거 — 이번엔 「어디로 갈지」를 바꾼다)"
				: "  ⇒ ★ 이 팔이 **이 자리의 기준선**이다(ML 규율 74 — 빌리지 않는다)");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

	// ── 인코더(138~141 과 같다) ─────────────────────────────────────
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
		_ptA.SetSortById(true); _ptA.Begin(kPtCtx, kN);
		for (uint32 c = 0; c < kRawCands; ++c) _raw[c].Reset(0);
		_SigReset();                     // 🚦 서명 누산기 — ⚠️ 씨앗마다 비운다
		_gGrp = 0u; _gIdx = 0u; _pending = false; _st = kGather;
	}

	static void _Gather()
	{
		if (_pending)
		{
			Array<float> ids, mag;
			if (!_E.ReadAct(ids, mag) || ids.Count() != kCandidates) { _Fail("활성 리드백"); return; }
			const uint32 cx = _gGrp * kGroup + (_gIdx - 1u) / kTime, tt = (_gIdx - 1u) % kTime;
			_ptA.StoreAct(cx, tt, ids, mag, _norm);
			_pending = false;
		}
		if (_gIdx == 0u)
		{
			Array<float> fr, tg; fr.Reset(0); tg.Reset(0);
			ImageFormat::Bitmap bmp; Bytes packed;
			for (uint32 g = 0; g < kGroup; ++g)
			{
				const uint32 ctx = _gGrp * kGroup + g;
				// ⚖️⚖️ 267 — **세계를 학습 자의 자리로**(`-mltjw2`) · ⚠️ 꺼지면 옛 인자와 **비트 동일**
				//   (`Reset` 의 기본 인자가 `dtMul = 1.0f · autoAmp = 1.0f` 이므로 값이 같다)
				const int   jAuto = _w2on ? MLTWorldCfg::kAutoMany : MLTWorldCfg::kAutoFew;
				const float jAmp  = _w2on ? kTrAmp : 1.00f;
				MLTWorld w;
				if (_w2on) w.SetWorld2(2);                 // ⚠️ `Reset` 보다 **먼저**
				w.Reset(_seed, kPtEpi + ctx, MLTWorldCfg::kHoldMid, jAuto, kTrDt, jAmp);
				// ⚖️⚖️ **자기상태 채널을 켠다** — ⚠️ `Reset` **뒤**, 첫 `Step` **앞**이어야 한다
				//   (`Reset` 은 `_energyOn` 을 안 건드리므로 여기 한 줄이면 에피소드 내내 켜져 있다).
				w.SetEnergy(true);
				// ⚖️⚖️ 266 — **몸**(이득이 외형에 걸리고 반사가 돈다) · ⚠️ 기본 꺼짐
				//   ⚠️ `w0`(짝)는 **안 켠다** — 서명 5 가 「몸이 상태열을 갈랐나」를 재게 된다.
				if (_bodyOn) w.SetBody(true);
				// ⭐ 서명 5 — **OFF ↔ ON 상태열이 실제로 갈리나**(안 갈리면 채널이 아무 일도 안 했다)
				MLTWorld w0;
				if (_w2on) w0.SetWorld2(2);                // ⚠️ 짝도 **같은 세계**여야 갈림이 뜻을 갖는다
				w0.Reset(_seed, kPtEpi + ctx, MLTWorldCfg::kHoldMid, jAuto, kTrDt, jAmp);
				for (uint32 t = 0; t < kTime; ++t)
				{
					w.Step();
					w0.Step();                       // ⚠️ 에너지 **꺼진** 짝(렌더는 안 한다 — 상태만)
					{
						const MLTState& a = w.State(); const MLTState& b = w0.State();
						const float d = Abs(a.x - b.x) + Abs(a.y - b.y) + Abs(a.z - b.z)
						              + Abs(a.yaw - b.yaw) + Abs(a.pitch - b.pitch);
						if (d > _divMax) _divMax = d;
						_divSum += (double)d; ++_divN;
						if (d == 0.0f) ++_divZero;
					}
					if (!w.Render(bmp) || !MLTWorld::Pack(bmp, nullptr, packed)) { _Fail("Render/Pack(문맥)"); return; }
					MLTP2Enc::AppendFrame(fr, tg, (const uint8*)packed.GetData());
					_ptA.StoreState(ctx, t, w.State());

					// ⭐ 후보를 매 시각 잰다.
					//   ⭐ `[0]` = **에너지**(⚠️ `VisibleShapes` 가 아니다 — **역사에서 오는** 자기상태 채널)
					//   `[1]` = `minDOn`(**참조** — 142 가 바닥으로 판정한 것이 ON 세계에서도 바닥인가)
					MLTShapeView vs[MLTWorldCfg::kShapes];
					const int nv = w.VisibleShapes(vs, MLTWorldCfg::kShapes);
					const float SS = (float)MLTWorldCfg::kSide;
					float minD = kNoShape;
					for (int i = 0; i < nv; ++i)
					{
						if (!(vs[i].sx >= 0.0f && vs[i].sx < SS && vs[i].sy >= 0.0f && vs[i].sy < SS)) continue;
						if (vs[i].d < minD) minD = vs[i].d;
					}
					const float e = w.Energy();
					_raw[0].Add(e); _raw[1].Add(minD);
					// ⭐ 서명 1·2 — 평균·sd·범위와 **자기상관**(lag 1 · 문맥 안에서만 잇는다)
					_eSum += (double)e; _eSq += (double)e * (double)e; ++_eN;
					if (e < _eMin) _eMin = e;
					if (e > _eMax) _eMax = e;
					if (t > 0u) { _acXY += (double)e * (double)_ePrev; ++_acN; }
					_ePrev = e;
				}
				// ⭐ 서명 3 — **둔화 발동 횟수**(0 이면 ㈂ 기능적 결과가 죽었다)
				_slowSum += (double)w.SlowHits(); ++_slowN;
				// ⚖️⚖️ 266 — **반사 발동 횟수**(0 이면 몸의 닫힘이 이 판에서 안 돈 것이다)
				_biasSum += (double)w.BiasHits(); ++_biasN;
				_pickSum += (double)w.PickCount();      // ⭐ 📌 D71 — 발동 수의 분모
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
		if (++_gGrp * kGroup < kPtCtx) return;
		_gGrp = 0u;
		_MakeWords();
		_st = kMeasure;
	}

	// ── 낱말 만들기 ────────────────────────────────────────────────
	static void _RankClassK(const float* m, uint32 n, uint32 k, Array<uint32>& y)
	{
		y.Reset(0);
		for (uint32 i = 0; i < n; ++i) y.Add(0u);
		for (uint32 i = 0; i < n; ++i)
		{
			uint32 r = 0u;
			for (uint32 j = 0; j < n; ++j)
				if (m[j] < m[i] || (m[j] == m[i] && j < i)) ++r;
			y.Data()[i] = (r * k) / n;
		}
	}

	// ⭐ ㈤ — 회차 141 의 낱말(그 시각에 「바뀌는」 첫 슬롯의 표적 id 8분위 +1 · 0 = 변화 없음)
	static void _ChangeWord(Array<uint32>& w)
	{
		w.Reset(0);
		for (uint32 ctx = 0; ctx < kPtCtx; ++ctx)
			for (uint32 t = 0; t < kTime; ++t)
			{
				const uint32 b = MLTP3Ctx::Row(ctx, t, kStateAx);
				uint32 cls = 0u;
				for (uint32 j = 0; j < kSlots; ++j)
				{
					const float tf = _ptA.Tgt()[b + j];
					if (!(tf >= 0.0f && tf < (float)kN)) continue;
					const uint32 tid = (uint32)tf;
					if ((uint32)(_ptA.Sym()[b + j] - (float)kStateAx) == tid) continue;
					cls = 1u + (tid * (kRefCls - 1u)) / kN;
					break;
				}
				w.Add(cls);
			}
	}

	static void _MakeWords()
	{
		// `[0]` 에너지 · `[2]` minDOn — 둘 다 연속값이라 **순위 8분위**로
		_RankClassK(_raw[0].Data(), kWords, kCls, _w[0]);
		_RankClassK(_raw[1].Data(), kWords, kCls, _w[2]);
		// ⭐ `[1]` = **섞은 에너지** — ⚠️ 이것이 「자기 편향 바닥」이다(㈠ 의 `Î섞음` 과 나란히 봐야 한다)
		_Shuffle(_w[0], _w[1], 909u);
		_ChangeWord(_w[3]);
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

	// `Î(w;y)` — ⚠️ **변화 표적만** 센다(141 의 자가 채점하는 자리).
	static double _MI(const Array<uint32>& word, uint32 nc, uint32& outN)
	{
		Array<uint32> joint; joint.Reset(0);
		for (uint32 i = 0; i < nc * kN; ++i) joint.Add(0u);
		Array<uint32> wCnt; wCnt.Reset(0);
		for (uint32 i = 0; i < nc; ++i) wCnt.Add(0u);
		Array<uint32> yCnt; yCnt.Reset(0);
		for (uint32 i = 0; i < kN; ++i) yCnt.Add(0u);
		uint32 nT = 0u;
		for (uint32 ctx = 0; ctx < kPtCtx; ++ctx)
			for (uint32 t = 0; t < kTime; ++t)
			{
				const uint32 c = word[ctx * kTime + t] % nc;
				const uint32 b = MLTP3Ctx::Row(ctx, t, kStateAx);
				for (uint32 j = 0; j < kSlots; ++j)
				{
					const float tf = _ptA.Tgt()[b + j];
					if (!(tf >= 0.0f && tf < (float)kN)) continue;
					const uint32 tid = (uint32)tf;
					if ((uint32)(_ptA.Sym()[b + j] - (float)kStateAx) == tid) continue;   // ⭐ 변화 표적만
					++joint.Data()[c * kN + tid]; ++wCnt.Data()[c]; ++yCnt.Data()[tid]; ++nT;
				}
			}
		outN = nT;
		if (nT == 0u) return 0.0;
		const double hY = _Entropy(yCnt, nT);
		_hYlast = hY;      // ⭐ 해석의 눈금 — 「낱말이 표적 엔트로피의 몇 %를 가르나」
		double hYgW = 0.0;
		for (uint32 c = 0; c < nc; ++c)
		{
			const uint32 nw = wCnt[c];
			if (nw == 0u) continue;
			double e = 0.0;
			for (uint32 y = 0; y < kN; ++y)
			{
				const uint32 v = joint[c * kN + y];
				if (v == 0u) continue;
				const double p = (double)v / (double)nw;
				e += -p * (double)Log((float)p);
			}
			hYgW += ((double)nw / (double)nT) * e;
		}
		return hY - hYgW;
	}

	// ⭐ **1씨앗 진단이 요구한 것** — `Î(낱말 ; 「그 시각에 바뀌는 슬롯 **개수**」)`.
	//   ⚠️ 위 `_MI` 는 표적을 **250-way id**(변화의 **내용**)로 본다. 그런데 에너지는
	//     **변화의 「양」**을 가를 뿐이다(서명 4 가 그것을 보였다: 변화 표적 14.0 → 10.7).
	//   ⇒ ★ 두 자를 나란히 두면 ⛔ 의 뜻이 정해진다: ***양은 가르고 내용은 안 가른다.***
	//   ⚠️ 표본은 (문맥 × 시각) = 4096 이고 표적 어휘는 **9**(0~8개)다.
	static double _MICount(const Array<uint32>& word, uint32 nc)
	{
		const uint32 kC = kSlots + 1u;                 // 0..8
		Array<uint32> joint; joint.Reset(0);
		for (uint32 i = 0; i < nc * kC; ++i) joint.Add(0u);
		Array<uint32> wC; wC.Reset(0);
		for (uint32 i = 0; i < nc; ++i) wC.Add(0u);
		Array<uint32> yC; yC.Reset(0);
		for (uint32 i = 0; i < kC; ++i) yC.Add(0u);
		uint32 n = 0u;
		for (uint32 ctx = 0; ctx < kPtCtx; ++ctx)
			for (uint32 t = 0; t < kTime; ++t)
			{
				const uint32 c = word[ctx * kTime + t] % nc;
				const uint32 b = MLTP3Ctx::Row(ctx, t, kStateAx);
				uint32 cnt = 0u;
				for (uint32 j = 0; j < kSlots; ++j)
				{
					const float tf = _ptA.Tgt()[b + j];
					if (!(tf >= 0.0f && tf < (float)kN)) continue;
					if ((uint32)(_ptA.Sym()[b + j] - (float)kStateAx) != (uint32)tf) ++cnt;
				}
				++joint.Data()[c * kC + cnt]; ++wC.Data()[c]; ++yC.Data()[cnt]; ++n;
			}
		if (n == 0u) return 0.0;
		const double hY = _Entropy(yC, n);
		double hYgW = 0.0;
		for (uint32 c = 0; c < nc; ++c)
		{
			const uint32 nw = wC[c];
			if (nw == 0u) continue;
			double e = 0.0;
			for (uint32 y = 0; y < kC; ++y)
			{
				const uint32 v = joint[c * kC + y];
				if (v == 0u) continue;
				const double p = (double)v / (double)nw;
				e += -p * (double)Log((float)p);
			}
			hYgW += ((double)nw / (double)n) * e;
		}
		_hCntLast = hY;
		return hY - hYgW;
	}

	static void _Measure()
	{
		uint32 nT = 0u;
		for (uint32 c = 0; c < kCands; ++c)
		{
			const uint32 nc = (c == 3u) ? kRefCls : kCls;   // `[3]` = 눈금(9계급)
			Array<uint32> h; h.Reset(0);
			for (uint32 i = 0; i < nc; ++i) h.Add(0u);
			for (uint32 i = 0; i < _w[c].Count(); ++i) ++h.Data()[_w[c][i] % nc];
			_hW[c][_seed] = _Entropy(h, _w[c].Count());
			_mi[c][_seed] = _MI(_w[c], nc, nT);
			Array<uint32> sh; _Shuffle(_w[c], sh, 700u + c);
			uint32 dummy = 0u;
			_miS[c][_seed] = _MI(sh, nc, dummy);
			if (_mi[c][_seed] - _miS[c][_seed] > 0.0) ++_pos[c];
			// ⭐ 같은 낱말로 **「양」**도 잰다(1씨앗 진단이 요구했다)
			_miC[c][_seed]  = _MICount(_w[c], nc);
			_miCS[c][_seed] = _MICount(sh, nc);
			if (_miC[c][_seed] - _miCS[c][_seed] > 0.0) ++_posC[c];
		}
		_hCnt[_seed] = _hCntLast;
		_nCh[_seed] = (double)nT / (double)kPtCtx;
		_hY[_seed] = _hYlast;

		// ── 🚦 **서명을 먼저 접는다**(규율 21 — 성능보다 위에 찍는다) ────
		const double m  = (_eN == 0u) ? 0.0 : _eSum / (double)_eN;
		const double v  = (_eN == 0u) ? 0.0 : (_eSq / (double)_eN) - m * m;
		_sgMean[_seed] = m;
		_sgSd[_seed]   = (v > 0.0) ? Sqrt((float)v) : 0.0;
		// 자기상관(lag 1) — 문맥 안에서만 이었다. `(E[xy] − m²) / var`
		_sgAc[_seed]   = (_acN == 0u || v <= 1.0e-12) ? 0.0 : ((_acXY / (double)_acN) - m * m) / v;
		_sgSlow[_seed] = (_slowN == 0u) ? 0.0 : _slowSum / (double)_slowN;
		_sgDiv[_seed]  = (_divN == 0u) ? 0.0 : _divSum / (double)_divN;
		_sgZero[_seed] = _divZero;
		LogA("[mlt] 🔍 씨앗 %2u · 🚦 **서명** — E 평균 %.4f · **sd %.4f** · 범위 %.3f~%.3f · **자기상관 %.4f**\n",
			_seed, m, _sgSd[_seed], (double)_eMin, (double)_eMax, _sgAc[_seed]);
		LogA("[mlt] 🔍   🚦 **둔화 발동 %.2f/에피소드** · OFF↔ON 갈림 평균 **%.4f**(최대 %.4f · 비트동일 %u/%u)\n",
			_sgSlow[_seed], _sgDiv[_seed], (double)_divMax, _divZero, _divN);
		// ⚖️⚖️ 266 — 몸의 서명(꺼져 있으면 0 이 찍혀야 한다 = 방벽)
		_sgBias[_seed] = (_biasN == 0u) ? 0.0 : _biasSum / (double)_biasN;
		_sgPick[_seed] = (_biasN == 0u) ? 0.0 : _pickSum / (double)_biasN;
		// ⭐ 📌 D71 — 정규화한 자는 **반사 ÷ `_PickAct` 호출 수**다(반사÷둔화가 아니다)
		LogA("[mlt] 🔍   ⚖️ **몸 %s** · 반사 **%.2f**/에피 · 호출 **%.2f**/에피 · ⭐ **반사÷호출 %.3f**\n",
			_bodyOn ? "켬" : "꺼짐", _sgBias[_seed], _sgPick[_seed],
			(_sgPick[_seed] > 1.0e-9) ? _sgBias[_seed] / _sgPick[_seed] : 0.0);
		LogA("[mlt] 🔍   🚦 **변화 표적 %.1f/문맥**(총 %u · 145·146 은 %.1f) · H(변화표적) %.4f 나트\n",
			_nCh[_seed], nT, kChTgt145, _hY[_seed]);
		for (uint32 c = 0; c < kCands; ++c)
			LogA("[mlt] 🔍   %s H %.4f · Î %.5f · Î섞음 %.5f · **차 %+.5f**\n",
				_Name(c), _hW[c][_seed], _mi[c][_seed], _miS[c][_seed], _mi[c][_seed] - _miS[c][_seed]);
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
		double gap[kCands], gsd[kCands], hm[kCands], hsd;
		for (uint32 c = 0; c < kCands; ++c)
		{
			double d[kSeedsMax];
			for (uint32 s = 0; s < _seeds; ++s) d[s] = _mi[c][s] - _miS[c][s];
			_MeanSd(d, gap[c], gsd[c]);
			_MeanSd(_hW[c], hm[c], hsd);
		}
		double nm, nsd; _MeanSd(_nCh, nm, nsd);
		double hym, hysd; _MeanSd(_hY, hym, hysd);
		const uint32 pass = (_seeds * 10u + 11u) / 12u;
		const double ref = gap[3];                     // ⭐ 눈금 = `[3]` 변화 표적 id

		double sgM, sgMs, sgS, sgSs, sgA, sgAs, sgL, sgLs, sgD, sgDs;
		_MeanSd(_sgMean, sgM, sgMs); _MeanSd(_sgSd, sgS, sgSs); _MeanSd(_sgAc, sgA, sgAs);
		_MeanSd(_sgSlow, sgL, sgLs); _MeanSd(_sgDiv, sgD, sgDs);
		uint32 zTot = 0u;
		for (uint32 s = 0; s < _seeds; ++s) zTot += _sgZero[s];

		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🔍 **회차 147 · 에너지 채널 거르기 + 세계 서명** (씨앗 %u · 학습 0 · 유한 %s)\n",
			_seeds, _ok ? "✅" : "⛔");

		// ── 🚦 서명 — ⚠️⚠️ **성능보다 먼저**(규율 21) ─────────────────
		LogA("[mlt] 🔍   ── 🚦 ⭐ **세계의 서명**(⚠️ 성능보다 먼저 · 규율 21) ──\n");
		LogA("[mlt] 🔍     1 `E` 평균 **%.4f** · **sd %.4f**(±%.4f)          → %s\n",
			sgM, sgS, sgSs, (sgS > 0.05) ? "✅" : "⛔ **채널이 상수다**");
		LogA("[mlt] 🔍     2 `E` **자기상관(lag1) %.4f**(±%.4f)             → %s\n",
			sgA, sgAs, (sgA > 0.3 && sgA < 0.995) ? "✅ 누적기다"
			         : ((sgA >= 0.995) ? "⛔ **상수에 가깝다**" : "⛔ **누적기가 아니다**"));
		LogA("[mlt] 🔍     3 ⭐ **둔화 발동 %.2f/에피소드**(±%.2f)           → %s\n",
			sgL, sgLs, (sgL > 0.0) ? "✅ ㈂ 기능적 결과가 발화한다" : "⛔ **㈂ 가 죽었다**");
		LogA("[mlt] 🔍     4 ⭐ **변화 표적 %.1f/문맥**(±%.1f) ↔ 145·146 **%.1f** → %s\n",
			nm, nsd, kChTgt145,
			(nm >= kChTgt145 * 0.7) ? "✅ 세계가 조용해지지 않았다"
			                        : "⚠️⚠️ **줄었다 — CE 개선을 「배웠다」로 읽으면 안 된다**");
		LogA("[mlt] 🔍     5 ⭐ **OFF↔ON 갈림** 평균 **%.4f** · 비트동일 **%u/%u**  → %s\n",
			sgD, zTot, kPtCtx * kTime * _seeds,
			(sgD > 0.0) ? "✅ 채널이 세계를 바꾼다" : "⛔ **플래그가 안 먹었다**");
		// ⚖️⚖️ 267 — **6 몸의 배관**(⚠️ 266 이 이것을 판정 **뒤에** 읽어 판정불가가 됐다 · 📌 D70)
		//   ★ 정규화한 자는 **반사 ÷ 둔화**다 — *"저에너지 틱 중 반사가 실제로 돈 비율"*
		//     실측: 265 의 세계 **0.75**(6.3/8.4) ↔ 266 의 옛 세계 **0.12**(0.47/3.77) ⇒ 6배 차.
		//   ⇒ ⚠️ **문턱 0.25 를 등록한다**(그 아래면 「몸이 거의 없는 세계」 ⇒ 표제를 읽지 않는다).
		double sgB, sgBs, sgP, sgPs; _MeanSd(_sgBias, sgB, sgBs); _MeanSd(_sgPick, sgP, sgPs);
		// ⭐⭐ 📌 **D71 이 이 자를 고쳤다** — 옛 자는 **반사÷둔화**였고 문턱 0.25 를 265 의 수에서
		//   역산했는데 ⛔ **그 수가 부풀려진 것**이었다(반사 6.3 > 손계산 상한 4.4) ⇒ ML 규율 74.
		//   ⇒ ★ 정규화는 **반사 ÷ `_PickAct` 호출 수**로 한다 · ⚠️⚠️ **문턱을 여기서 안 정한다**
		//     (*"문턱은 그 세계에서 뽑는다"* — 얇은 세계의 수를 시즌2 로 빌려주지 않는다).
		const double biasRatio = (sgP > 1.0e-9) ? sgB / sgP : 0.0;
		LogA("[mlt] 🔍     6 ⚖️ **몸 %s** · 반사 **%.2f**(±%.2f)/에피 · 호출 **%.2f**/에피 · ⭐ **반사÷호출 %.3f** → %s\n",
			_bodyOn ? "켬" : "꺼짐", sgB, sgBs, sgP, biasRatio,
			(!_bodyOn) ? "ⓘ 몸 꺼짐(0 이어야 한다 = 방벽)"
			           : ((sgB > 0.0) ? "✅ 반사가 돈다 ⚠️ **문턱은 이 세계에서 뽑는다**(D71)"
			                          : "⛔⛔ **반사가 한 번도 안 돌았다** ⇒ 표제를 읽지 않는다"));
		LogA("[mlt] 🔍   ⭐ `H(변화 표적)` = **%.4f** 나트(균등바닥 `ln250` = 5.52)\n", hym);
		LogA("[mlt] 🔍   ── 후보 표 ── (⭐ **표적몫** = `(Î−Î섞음) / H(변화표적)`)\n");
		LogA("[mlt] 🔍     낱말                 │ H      · **Î−Î섞음**(±sd)      · 표적몫 · **눈금대비** · 부호\n");
		for (uint32 c = 0; c < kCands; ++c)
			LogA("[mlt] 🔍     %s │ %.4f · **%+.5f**(±%.5f) · %.4f · **%+.3f** · %u/%u\n",
				_Name(c), hm[c], gap[c], gsd[c],
				(hym > 1.0e-9) ? gap[c] / hym : 0.0,
				(Abs((float)ref) > 1.0e-12) ? gap[c] / ref : 0.0,
				_pos[c], _seeds);

		// ── ①′ ⭐ **「변화의 양」 자** — 1씨앗 진단이 요구한 그것 ──────
		//   ⚠️ 위 표는 표적을 **250-way id**(변화의 **내용**)로 본다. 여기는 **개수**(0~8)다.
		double gapC[kCands], gcsd, hcm, hcsd;
		_MeanSd(_hCnt, hcm, hcsd);
		LogA("[mlt] 🔍   ── ①′ ⭐ **「변화의 양」**(표적 = 바뀌는 슬롯 **개수** 0~8 · `H = %.4f` 나트) ──\n", hcm);
		LogA("[mlt] 🔍     낱말                 │ **Î−Î섞음**(양)      · **양 몫** · 부호\n");
		for (uint32 c = 0; c < kCands; ++c)
		{
			double d[kSeedsMax];
			for (uint32 s = 0; s < _seeds; ++s) d[s] = _miC[c][s] - _miCS[c][s];
			_MeanSd(d, gapC[c], gcsd);
			LogA("[mlt] 🔍     %s │ **%+.5f**(±%.5f) · **%.4f** · %u/%u\n",
				_Name(c), gapC[c], gcsd, (hcm > 1.0e-9) ? gapC[c] / hcm : 0.0, _posC[c], _seeds);
		}
		LogA("[mlt] 🔍     ⭐ **읽는 법** — ㈠ 이 여기서 **크고** 위 표에서 **바닥**이면\n");
		LogA("[mlt] 🔍        ***에너지는 「양」을 가르고 「내용」을 안 가른다*** ⇒ ★ **자가 틀렸다**(손잡이가 아니다)\n");

		// ── 관문 ────────────────────────────────────────────────────
		const bool gRef  = (_pos[3] >= _seeds) && (ref > 0.0);
		const bool gPipeA = (sgD > 0.0);                                   // 배관 A — 채널이 세계를 바꾼다
		const bool gPipeB = (sgS > 0.05) && (sgA > 0.3) && (sgA < 0.995) && (sgL > 0.0);
		LogA("[mlt] 🔍   ── 관문 ──\n");
		LogA("[mlt] 🔍     ⭐ **배관 A**(OFF↔ON 이 갈린다) → %s\n", gPipeA ? "✅" : "⛔");
		LogA("[mlt] 🔍     ⭐ **배관 B**(sd>0.05 · 자기상관 0.3~0.995 · 둔화>0) → %s\n", gPipeB ? "✅" : "⛔");
		LogA("[mlt] 🔍     ⭐ **눈금**(㈣ 가 살아야) — %u/%u · 차 %+.5f → %s\n",
			_pos[3], _seeds, ref, gRef ? "✅" : "⛔ **눈금이 죽었다 = 판정불가**");
		uint32 nPass = 0u; bool gTop = false;
		for (uint32 c = 0; c < 3u; ++c)      // ㈠ 에너지 · ㈡ 섞은 에너지(바닥) · ㈢ minDOn(참조)
		{
			const double rel = (Abs((float)ref) > 1.0e-12) ? gap[c] / ref : 0.0;
			const bool okc = (_pos[c] >= pass) && (rel >= 0.10);
			if (okc) { ++nPass; if (c == 0u) gTop = true; }
			LogA("[mlt] 🔍     %s 부호 %u/%u≥%u · 눈금대비 %+.3f≥0.10 → %s%s\n",
				_Name(c), _pos[c], _seeds, pass, rel, okc ? "✅ **통과**" : "⛔",
				(c == 1u) ? "  ⚠️ **이 팔이 통과하면 자가 죽은 것이다**(섞음은 정보 0)" : "");
		}

		// ── 판정 ────────────────────────────────────────────────────
		//   ⚠️ **배관이 먼저다**(규율 21) — 서명이 안 서면 후보 숫자를 읽지 않는다.
		if (!_ok)                LogA("[mlt] 🔍   ⭐ 판정 = ⛔ **판정불가** — 배관이 안 섰다\n");
		else if (!gPipeA)
			LogA("[mlt] 🔍   ⭐ 판정 = ⛔ **판정불가** — ***OFF↔ON 이 안 갈린다***(플래그가 안 먹었다)\n");
		else if (!gPipeB)
			LogA("[mlt] 🔍   ⭐ 판정 = ⛔ **판정불가** — ***채널의 서명이 죽었다*** ⇒ ★ 손잡이 넷을 돌린다\n"
			     "[mlt] 🔍      (`kEnergyDrain`·`kEnergyGain`·`kEnergyLow`·`kEnergySlow`) ⚠️ **판정 회차를 안 태운다**\n");
		// ⚖️⚖️ 267 — **몸의 배관이 먼저다**(📌 D70 · 266 이 이것을 판정 뒤에 읽어 한 회차를 잃었다)
		//   ⚠️ 📌 **D71 이 문턱을 뗐다** — 남은 것은 **「한 번도 안 돌았나」** 하나다(그것만 확실하다)
		else if (_bodyOn && sgB <= 0.0)
			LogA("[mlt] 🔍   ⭐ 판정 = ⛔ **판정불가** — ***반사가 한 번도 안 돌았다***"
			     "(반사 %.2f/에피 · 호출 %.2f/에피)\n"
			     "[mlt] 🔍      ⇒ ★ `Î` 가 안 오른 것이 **부호가 정보를 못 줘서**인지"
			     " **부호가 발생 안 해서**인지 **구별 불가**다\n",
			     sgB, sgP);
		else if (_seeds == 1u)   LogA("[mlt] 🔍   ⭐ **1씨앗 진단이다 — 판정하지 않는다**(규율 51 · 서명만 읽는다)\n");
		else if (!gRef)          LogA("[mlt] 🔍   ⭐ 판정 = ⛔ **판정불가** — ***눈금(양성 참조)이 안 선다***\n");
		else if (_pos[1] >= pass && gap[1] / ref >= 0.10)
			LogA("[mlt] 🔍   ⭐ 판정 = ⛔ **판정불가** — ***섞은 에너지도 통과한다 = 자가 죽었다***\n");
		else if (gTop)
			LogA("[mlt] 🔍   ⭐ 판정 = ⭐ ***에너지 채널이 변화 표적을 가른다*** — 눈금 대비 %+.3f\n"
			     "[mlt] 🔍      ⇒ ★ 다음은 이것을 **낱말로 얹어** `mltl1d0` 의 자로 판정한다\n"
			     "[mlt] 🔍      ⭐ 그리고 **팔 하나만 더하면**(값은 세계가 굴리는데 **모델은 못 보는 팔**)\n"
			     "[mlt] 🔍         *\"대응이 없으면 몇 배 더 필요한가\"* 도 같이 답한다(컨셉의 그 빈자리)\n",
			     gap[0] / ref);
		else
			LogA("[mlt] 🔍   ⭐ 판정 = ⛔ **에너지도 바닥이다**(눈금 대비 %+.3f)\n"
			     "[mlt] 🔍      ⇒ ★ 먼저 **손잡이 넷을 돌린다** — ⚠️ 판정 회차를 안 태운다(138·139·142 의 교훈)\n"
			     "[mlt] 🔍      ⇒ 그것도 ⛔ 면 ⇒ ⚠️⚠️ *\"누적기여도 이 표적을 안 가른다\"* ⇒ **표적을 바꾼다**\n",
			     gap[0] / ref);
		LogA("[mlt] 🔍   ⚠️ `Î` 는 **무조건부**다 — 이것은 **거르는 자**이고 판정은 `mltl1d0` 가 한다\n");
		LogA("[mlt] 🔍   ⚠️ ㈢ `minDOn` 은 **참조**다(142 가 바닥으로 쟀다) — ON 세계에서도 바닥이면 재현이다\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		_E.Destroy(); _done = true;
	}

	static void _Fail(const char* why)
	{
		LogA("[mlt] 🔍 ⛔ %s (씨앗 %u · 단계 %u · 걸음 %u · 그룹 %u)\n", why, _seed, _st, _step, _gGrp);
		_ok = false; _E.Destroy(); _done = true;
	}

	CW_BODY(MLTL1J0)
};
