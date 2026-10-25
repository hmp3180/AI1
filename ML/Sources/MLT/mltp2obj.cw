// mltp2obj.cw — 🔬 회차 46 · **P2 관문 ㉢: 활성이 물체를 가르나** (`-mltp2obj`)
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 46 이다** — 여기 적는 것은 그 구현 계약뿐이다.
// ⚠️ **판정자(짝 다섯)는 이 파일에 없다** — `mltobjprobe.cw` 의 `MLTObjProbe` 가 정본이고
//   회차 48 이 **같은 것**을 쓴다(등록문이 요구한 「같은 자」).
// ══════════════════════════════════════════════════════════════════════════════
//
// ★ **왜 이 회차가 있나** — 회차 19 가 이 관문을 **색 대조군까지 붙여** 등록하고
//   *"별 회차"* 로 미뤘는데, 회차 20~42 **스물세 회차가 전부 ㉠(재구성 오차)** 이었다.
//   그리고 P3-A1·A2 가 그 ㉠ 이 **원리적으로 id 를 요구하지 않는다**는 것을 실측했다
//   (손실은 절반 이하로 내려가는데 semantic id 는 1종 — 원자 하나를 여러 앵커로 옮기면 된다).
//   ⇒ 지속 표현의 관문은 **재구성 오차가 아니라 기능**이다(`mltconcept.md` 「활성 id 는 **주소**다」).
//
// ⚠️⚠️ **모델·GPU 커널을 한 줄도 안 바꾼다.** 회차 21·24 의 패치 로컬 인코더를 글자 그대로 쓰고
//   (`globalFoot=false` · `N=1000` · `k=8` · 은닉 없음 · `lr=3e-3` · 프레임 32 · 1200 스텝),
//   **판정은 학습 뒤 평가 forward 에서 읽은 `ids` 뿐**이다.
//
// ── 🧾 실측(2026-08-25 · 12씨앗) ────────────────────────────────────────────
//   ㈎상한 **0.8018** · ㈀표제 **0.6886** · ㈁색 **0.5731** · ㈂위치 **0.4227** · ㈃바닥 **0.3336**
//   위생 11/12 · 표제① `㈀>㈂` **11/12** · 표제② `㈀>㈁` **10/12**(딱 문턱) ⇒ **✅ 통과**
//   ⚠️ 모양이 색 위에 더하는 몫은 **+0.1155** 뿐이다 · ㈀ 는 **상한 대비 86%** 로 읽는다.
//
// ── ⚠️ 등록을 고친 자리 둘 — **재기 전에** 적었다(조용히 두지 않는다) ──────────
//   1. **대표 패치를 「도형 중심이 든 칸」에서 「배타적으로 칠한 칸 중 중심에 가장 가까운 것」으로
//      바꿨다.** 근거: `kind=2` 는 **빈 원**이라 반지름이 크면 중심 칸에 **배경만** 있다.
//   2. **모든 칸의 짝을 「프레임을 건너는 것」으로 제한했다.** ㈀ 는 원리적으로 프레임을 건너는데
//      ㈁·㈃ 은 같은 프레임 안에서도 생긴다 ⇒ 안 맞추면 두 원인이 섞인다.
//   ★ 둘 다 **문턱과 갈래는 안 건드린다**(위생 ≥30짝 · 표제 10/12 · `Q=2`). 상세 = 등록문.

using namespace PE;

class MLTP2Obj
{
public:
	static void Tick(RHI* rhi)
	{
		if (_done || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltp2obj"))
		{
			LogA("[mlt] 🔬 회차 46은 **꺼져 있다**(`-mltp2obj`) — 기록: ㈎0.8018 ㈀**0.6886** ㈁0.5731 ㈂0.4227 ㈃0.3336 · 위생 11/12 · ㈀>㈂ **11/12** · ㈀>㈁ **10/12** ⇒ ✅ 관문 ㉢ 통과\n");
			_done = true; return;
		}
		if (!_banner) { _Banner(); _banner = true; }
		if (_seed >= kSeeds) { _Summary(); return; }
		if (_st == kSetup) { _Begin(rhi); return; }
		if (_st == kTrain) { _Train(); return; }
		_Eval();
	}

	static bool Done() { return _done; }

private:
	// ── 등록값 — ⚠️ 회차 21·24 의 `F=32` 팔과 **글자 그대로 같다** ────────────
	static constexpr uint32 kSeeds  = 12u;      // ⚠️ P2 판정 라운드와 같은 벌(0..11)
	static constexpr uint32 kFrames = 32u;
	static constexpr uint32 kSteps  = 1200u;
	static constexpr uint32 kN      = 1000u;
	static constexpr uint32 kK      = 8u;
	static constexpr uint32 kPerTick = 8u;      // 한 렌더 프레임에 도는 학습 스텝
	static constexpr uint32 kCells   = MLTObjProbe::kCells;
	static constexpr uint32 kSignPass = 10u;    // 12 중 · `Q=2` 본페로니

	enum { kSetup, kTrain, kEval };

	inline static MLTP2Enc _E;
	inline static MLTObjProbe _P;
	inline static bool _done = false, _banner = false, _setup = false;
	inline static uint32 _seed = 0u, _st = kSetup, _step = 0u, _ev = 0u;

	inline static float  _seedCell[kSeeds][kCells];
	inline static uint32 _seedPairs[kSeeds][kCells];
	inline static bool   _seedOk[kSeeds];

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🔬 **회차 46 · P2 관문 ㉢ — 활성이 물체를 가르나**\n");
		LogA("[mlt] 🔬   씨앗 0..%u · 에피소드 0 · 프레임 %u · %u스텝 · N=%u k=%u (회차 24 `F=32` 팔)\n",
			kSeeds - 1u, kFrames, kSteps, kN, kK);
		LogA("[mlt] 🔬   짝 다섯: ㈎상한 ㈀표제 ㈁색대조 ㈂위치대조 ㈃바닥 · 전부 프레임을 건넌다\n");
		LogA("[mlt] 🔬   관문: 위생 ㈎>㈃ 10/12 · 표제① ㈀>㈂ 10/12 · 표제② ㈀>㈁ 10/12 · 짝 ≥%u\n",
			MLTObjProbe::kMinPairs);
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

	static void _Begin(RHI* rhi)
	{
		if (!_setup)
		{
			if (!_E.Setup(rhi, kFrames, kN)) { _Fail("준비 실패"); return; }
			_setup = true;
		}
		else if (!_E.ResetSeed()) { _Fail("되돌리기 실패"); return; }
		_E.SetK(kK); _E.SetSelectAbs(false);

		Array<float> fr, tg; fr.Reset(0); tg.Reset(0);
		_P.Reset(kK);
		ImageFormat::Bitmap bmp; Bytes packed;
		MLTWorld w; w.Reset(_seed, 0u, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
		for (uint32 f = 0; f < kFrames; ++f)
		{
			w.Step();
			if (!w.Render(bmp) || !MLTWorld::Pack(bmp, nullptr, packed)) { _Fail("Render/Pack 실패"); return; }
			MLTP2Enc::AppendFrame(fr, tg, (const uint8*)packed.GetData());
			_P.AddFrame(w);   // ⚠️ **판정 창구** — 그린 그 상태의 은닉 목록(학습 입력이 아니다)
		}
		if (!_E.WritePool(fr, tg, kFrames)) { _Fail("풀 업로드 실패"); return; }
		_step = 0u; _st = kTrain;
	}

	static void _Train()
	{
		for (uint32 i = 0; i < kPerTick && _step < kSteps; ++i)
		{
			_E.SetFrame(_step % kFrames);
			if (!_E.Forward() || !_E.Backward() || !_E.AdamStep(1.0f)) { _Fail("학습 디스패치 실패"); return; }
			++_step;
		}
		if (_step >= kSteps) { _ev = 0u; _st = kEval; }
	}

	// ⚠️ 디스패치와 되읽기는 **한 틱 떨어진다**(회차 45 와 같은 관용구).
	static void _Eval()
	{
		if (_ev > 0u)
		{
			Array<float> ids, mag;
			if (!_E.ReadAct(ids, mag)) { _Fail("활성 리드백 실패"); return; }
			if (!_P.FillIds(_ev - 1u, ids, kN)) { _Fail("활성 채우기 실패"); return; }
		}
		if (_ev < kFrames)
		{
			_E.SetFrame(_ev);
			if (!_E.Forward()) { _Fail("평가 forward 실패"); return; }
			++_ev; return;
		}
		_Score();
	}

	static void _Score()
	{
		_seedOk[_seed] = _P.Score(_seedCell[_seed], _seedPairs[_seed]);
		LogA("[mlt] 🔬 씨앗 %2u · 출현 %3u · ㈎%.4f(%u) ㈀%.4f(%u) ㈁%.4f(%u) ㈂%.4f(%u) ㈃%.4f(%u) %s\n",
			_seed, _P.Occurrences(),
			(double)_seedCell[_seed][MLTObjProbe::cUp],    _seedPairs[_seed][MLTObjProbe::cUp],
			(double)_seedCell[_seed][MLTObjProbe::cSame],  _seedPairs[_seed][MLTObjProbe::cSame],
			(double)_seedCell[_seed][MLTObjProbe::cCol],   _seedPairs[_seed][MLTObjProbe::cCol],
			(double)_seedCell[_seed][MLTObjProbe::cPos],   _seedPairs[_seed][MLTObjProbe::cPos],
			(double)_seedCell[_seed][MLTObjProbe::cFloor], _seedPairs[_seed][MLTObjProbe::cFloor],
			_seedOk[_seed] ? "" : "⚠️ 짝 부족");
		++_seed; _st = kSetup;
	}

	static void _Summary()
	{
		double mean[kCells]; uint32 readable = 0u;
		for (uint32 c = 0; c < kCells; ++c) mean[c] = 0.0;
		uint32 hyg = 0u, t1 = 0u, t2 = 0u;
		for (uint32 s = 0; s < kSeeds; ++s)
		{
			if (!_seedOk[s]) continue;
			++readable;
			for (uint32 c = 0; c < kCells; ++c) mean[c] += (double)_seedCell[s][c];
			if (_seedCell[s][MLTObjProbe::cUp]   > _seedCell[s][MLTObjProbe::cFloor]) ++hyg;
			if (_seedCell[s][MLTObjProbe::cSame] > _seedCell[s][MLTObjProbe::cPos])   ++t1;
			if (_seedCell[s][MLTObjProbe::cSame] > _seedCell[s][MLTObjProbe::cCol])   ++t2;
		}
		if (readable > 0u) for (uint32 c = 0; c < kCells; ++c) mean[c] /= (double)readable;

		const bool hygOk = (hyg >= kSignPass);
		const bool p1 = (t1 >= kSignPass), p2 = (t2 >= kSignPass);
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🔬 **회차 46 · P2 ㉢ 결과** — 읽은 씨앗 %u/%u\n", readable, kSeeds);
		LogA("[mlt] 🔬   평균 겹침 — ㈎상한 **%.4f** · ㈀표제 **%.4f** · ㈁색 **%.4f** · ㈂위치 **%.4f** · ㈃바닥 **%.4f**\n",
			mean[MLTObjProbe::cUp], mean[MLTObjProbe::cSame], mean[MLTObjProbe::cCol],
			mean[MLTObjProbe::cPos], mean[MLTObjProbe::cFloor]);
		LogA("[mlt] 🔬   위생 ㈎>㈃ **%u/%u** (필요 %u) → %s\n", hyg, kSeeds, kSignPass, hygOk ? "통과" : "⛔");
		if (!hygOk)
			LogA("[mlt] 🔬   ⛔ **판정불가** — 재현성이 바닥을 못 넘으면 표제를 읽지 않는다(등록 그대로).\n");
		else
		{
			LogA("[mlt] 🔬   표제① ㈀>㈂ **%u/%u** (필요 %u) → %s  ⇐ 위치가 대신하나\n",
				t1, kSeeds, kSignPass, p1 ? "통과" : "⛔");
			LogA("[mlt] 🔬   표제② ㈀>㈁ **%u/%u** (필요 %u) → %s  ⇐ 색만 가르나\n",
				t2, kSeeds, kSignPass, p2 ? "통과" : "⛔");
			LogA("[mlt] 🔬 **관문 ㉢ — %s**\n", (p1 && p2) ? "✅ 통과(활성이 물체를 가른다)" : "⛔ 실패");
		}
		LogA("[mlt] 🔬   ⚠️ 고정 32프레임 **학습 코퍼스**의 진단이다 — 일반화·P3 경험 성공으로 인용하지 않는다.\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		_E.Destroy(); _done = true;
	}

	static void _Fail(const char* why)
	{
		LogA("[mlt] 🔬 ⛔ %s (씨앗 %u)\n", why, _seed);
		_E.Destroy(); _done = true;
	}
};
