// mltl1k0.cw — 🎯 회차 149 · **`A1` 파일럿 — 변화 표적의 「내용 축」에 폭이 있나** (`-mlt -mltl1k0`)
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 148b·149 다.** ⭐ **하네스보다 먼저 썼다.**
//   **상위 캔버스: `자기 채널이 손실 가중을 낸다` · 148~149 = 2회차.**
//   ⚠️⚠️ **판정 회차가 아니다 — `A1`(폭 재기) 파일럿**이다. 규율 49 의 둘째 갈래:
//     ***천장이 계산으로 안 나오면, 그것을 가두는 가장 싼 것을 돌린다.***
//
// ── ⭐ 무엇을 묻나 ────────────────────────────────────────────────────
//   `P5`(자기평가가 손실 가중을 낸다)를 열려면 **되먹임을 걸 값이 있는 목적지**가 필요하다.
//   ⛔ 회차 148b 가 **「어느 *지속* 표적을 남길지」를 지웠다** — 146 이 이미 그 폭을 쟀고
//     (Δ = +0.008 / −0.021 / −0.034 · 폭 ≈ 0.042) 143 이 이유를 말한다(지속 42개 CE **0.2649**
//     ⇒ 거의 다 똑같이 쉽다 = **내용으로 가를 것이 원래 없다**).
//   ⭐ 그런데 **변화 표적은 내용으로 갈린다** — 143 실측:
//     **밀림 55.2%**(`H` **1.8621**) ↔ **새 id 44.8%**(`H` **2.5714**) ⇒ 난이도 차 **0.7093**.
//   ⚠️⚠️ 단 `0.7093` 은 **A1 의 폭이 아니다**(그것은 두 부분집합의 **난이도 차**다).
//     A1 이 묻는 것은 *"A 로 학습 ↔ B 로 학습 했을 때 **전체** 결과가 얼마나 갈리나"* 다.
//   ⇒ ★ 그래서 이 회차가 **그 폭을 직접 잰다.**
//
// ── ⚙️ 구현 — ⭐ **커널 0줄**(145 와 같은 `IgnoreTgt` 마스킹) ──────────────
//   ★ **지속 표적은 전부 버린다**(= 145 의 `q=0.00` 자리) ⇒ 갈리는 것이 **변화 표적의 선택뿐**이다.
//   ⭐ **핵심 설계 = 학습은 부분집합 · 채점은 전부.**
//     ⚠️ 안 그러면 *"쉬운 것만 남기고 좋아졌다"* 는 **자명한 승리**가 된다(규율 34 의 얼굴).
//     ★ 그래서 물음이 정직해진다: ***예산을 어디에 쓰면 전체가 좋아지나.***
//   ⭐ **개수를 맞춘다** — ⚠️ 회차 119 가 정확히 이것 때문에 죽었다(*"학습 표적 수가 4배 ⇒ 교란"*).
//     α(밀림 비율)를 **학습 코퍼스에서** 재고(143 의 규율 — 시험에서 재면 훔쳐보는 것이다)
//     `r = min(α, 1−α)` 로 두 갈래를 **같은 개수까지** 솎는다.
//
// ── 🎛️ 팔 넷 ────────────────────────────────────────────────────────────
//   ⭐ ㈀ **밀림만**(비율 `r`) · ⭐ ㈁ **새id만**(비율 `r`)
//   ⭐ ㈂ **무작위 `r`**(내용 무관 · 같은 개수) ← ★ **팔 2 = 판정불가 기준**
//   ⭐ ㈃ **전부**(변화 100%) ← ★ **검산 = 145 의 `q=0.00` 1.7443 ± 0.05**
//
// ── 🚪 관문 ──────────────────────────────────────────────────────────────
//   ⭐ 검산 — ㈃ 가 **1.7443 ± 0.05** (⚠️ 씨앗 3 이상에서만 적용 — 규율 51)
//   ⭐ 개수 — `|n㈀ − n㈁| / n㈃ < 0.02` (맞춰졌나 · 안 맞으면 폭이 개수 효과를 섞는다)
//   ⭐ **A1** — `폭 = |㈀ − ㈁|` 이 **2·SE 를 넘나**
//     ✅ 넘으면 → 회차 150 = 팔 1·2·4·5·10 판정 / ⛔ 못 넘으면 → **이 목적지도 삭제**
//   ⭐ 부산물 — ㈀ 또는 ㈁ 이 **㈂(내용 무관 · 같은 개수)** 를 이기나(회차 150 의 미리보기)
//   ⭐ 그리고 **㈃ 의 밀림/새id 분해**로 D14(146 이 SE 를 안 찍은 부채)를 갚는 배관이 생긴다
//
// ── 🔮 예측(재기 전에 적는다) ─────────────────────────────────────────────
//   ㉠ 검산 ㈃ ✅ (1.70~1.79)
//   ⭐ ㉡ **폭이 2·SE 를 넘을 것**(A1 ✅) — 근거: 난이도 차 0.7093 이 크다
//   ⭐ ㉢ **㈀(밀림만)이 ㈁(새id만)보다 「전체」에서 좋을 것** — 밀림이 규칙적이라(정렬 밀림)
//     그것을 배우면 새 id 쪽에도 *"어디가 안 밀렸나"* 라는 정보가 생긴다
//   ⚠️ ㉣ **㈀·㈁ 둘 다 ㈃(전부)보다 나쁠 것** — 표본이 절반이다
//   ⚠️ ㉤ ㈂(무작위 r)가 ㈀·㈁ 사이에 놓일 것
//   ⚠️ ㉥ 밀림 비율이 **53~57%** 로 143 을 재현할 것
// ══════════════════════════════════════════════════════════════════════════════

using namespace PE;

class MLTL1K0
{
public:
	static void Tick(RHI* rhi)
	{
		if (_done || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltl1k0"))
		{
			LogA("[mlt] 🎯 회차 149(A1 파일럿 — 변화 표적의 내용 축)는 **꺼져 있다**(`-mltl1k0`)\n");
			_done = true; return;
		}
		if (!_banner) { _seeds = OS::CommandLine::Has("-mltdiag1") ? 1u : kSeedsMax; _Banner(); _banner = true; }
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
	// ⚠️⚠️ **씨앗 12 다 — 3 이 아니다.** 1씨앗 진단이 그 이유를 실측으로 냈다(2026-08-31):
	//   145 를 `-mltdiag1` 로 돌려 **씨앗 0** 값을 얻어 보니 12씨앗 평균과 크게 갈렸다
	//     `q=1.00` 씨앗0 **3.3635** ↔ 12씨앗 **2.7742**(차 0.589)
	//     `q=0.00` 씨앗0 **2.0286** ↔ 12씨앗 **1.7443**(차 0.284)
	//   ⇒ ⭐ **검산이 「12씨앗 눈금」이라 같은 씨앗 집합이어야 성립한다.**
	//     3씨앗이면 평균의 SE 가 ~0.17 이라 **±0.05 관문을 원리적으로 통과할 수 없다.**
	//   ★ 그리고 1씨앗 진단이 이미 A1 을 **11.75배**로 보였으므로(폭 0.331 / 2·SE 0.028)
	//     12씨앗은 그것을 **확정**하고 **검산까지** 세운다.
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

	static constexpr uint32 kNCtx = 512u, kPtCtx = 512u;
	static constexpr uint32 kTrainEpi = 1u, kPtEpi = 5001u;
	static constexpr uint32 kPoolSteps = kNCtx / kBatch;
	static constexpr uint32 kPtPool = kPtCtx / kBatch;
	static constexpr uint32 kSteps = 800u, kPerTick = 16u;

	static constexpr uint32 kSymA = MLTP3Ctx::kStateAx + kN + 1u;
	static constexpr uint32 kAx13 = MLTP3Ctx::kAxes;                 // 13
	static constexpr uint32 kAx14 = kAx13 + 1u;                      // 14
	static constexpr uint32 kCtx14 = kAx14 * kTime;                  // 112
	static constexpr uint32 kRows14 = kBatch * kCtx14;               // 896
	static constexpr float  kWordSym = 255.0f;
	static constexpr uint32 kWordCls = 9u, kConstCls = 4u;

	// ⭐ 밖에서 온 눈금 — ⚠️ 여기서 새로 재지 않는다.
	static constexpr float kTarget  = 2.1111f;   // 회차 143 · 학습 0 예측기의 최선
	static constexpr float kCE145E  = 1.7443f;   // 회차 145 · q=0.00 (= ㈃ 검산)
	static constexpr float kH143Sh  = 1.8621f;   // 회차 143 · H(밀림)
	static constexpr float kH143New = 2.5714f;   // 회차 143 · H(새 id)
	static constexpr float kAlpha143 = 0.554f;   // 회차 143 · 학습 α

	// 🎛️ 팔 넷
	static constexpr uint32 kArms = 4u;
	enum { kAShift = 0u, kANew = 1u, kARand = 2u, kAAll = 3u };

	// 시험 채점 마스크 셋 — ⚠️ **전부 「채점은 전부」의 갈래**다(학습과 무관).
	enum { kMTrain = 0u, kMChange = 1u, kMShift = 2u, kMNew = 3u };
	static constexpr uint32 kEvals = 3u;
	static constexpr uint32 kOut = 2u;
	enum { kEncInit, kEncTrain, kGather, kQuiesce, kBodyInit, kBodyTrain, kEval };

	inline static MLTP2Enc _E;
	inline static MLTModel _M;
	inline static MLTP3Ctx _trA, _ptA;
	inline static bool _done = false, _banner = false, _encSetup = false, _finite = true;
	inline static bool _pending = false;
	inline static uint32 _seed = 0u, _st = kEncInit, _step = 0u;
	inline static uint32 _arm = 0u, _out = 0u, _evalIdx = 0u;
	inline static uint32 _cor = 0u, _gGrp = 0u, _gIdx = 0u, _qWait = 0u;
	inline static Array<float> _code, _norm;
	inline static Array<float> _eVal[2], _eSym[2], _eTgt[2];
	inline static MLTEvalGate _gate;

	// [평가갈래][팔][씨앗] — 갈래 0 = 전체 변화 · 1 = 밀림 · 2 = 새 id
	inline static float _ce[kEvals][kOut][kArms][kSeedsMax];
	inline static bool  _seedOk[kSeedsMax];
	inline static double _nTrain[kArms];
	inline static double _alpha[kSeedsMax], _rKeep[kSeedsMax];
	inline static uint32 _lastScored = 0u;
	// ⭐ 이 씨앗의 솎기 문턱(천분율) — `_AlphaOf` 가 채운다.
	inline static uint32 _thShift = 1000u, _thNew = 1000u, _thRand = 1000u;

	static void _ToBody() { _qWait = MLTEvalGate::kDelay; _st = kQuiesce; }
	static const char* _ArmName(uint32 a)
	{
		switch (a)
		{
		case kAShift: return "㈀ 밀림만 ⭐        ";
		case kANew:   return "㈁ 새id만 ⭐        ";
		case kARand:  return "㈂ 무작위(내용0) ⭐ ";
		default:      return "㈃ 전부(검산)       ";
		}
	}
	static const char* _EvalName(uint32 e)
	{
		switch (e)
		{
		case 0u: return "전체변화";
		case 1u: return "밀림    ";
		default: return "새id    ";
		}
	}
	static uint32 _SignPass() { return (_seeds * 10u + 11u) / 12u; }

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🎯 **회차 149 · `A1` 파일럿 — 변화 표적의 「내용 축」에 폭이 있나**(%s)\n",
			(_seeds == 1u) ? "⚠️ 1씨앗 진단" : "⭐ 씨앗 12 — 검산이 12씨앗 눈금이라 같은 집합이어야 한다");
		LogA("[mlt] 🎯   ⚠️⚠️ **판정 회차가 아니다** — 규율 49 의 둘째 갈래(천장이 계산으로 안 나오면 가장 싼 것을 돌린다)\n");
		LogA("[mlt] 🎯   ⛔ 148b 가 「어느 **지속** 표적을 남길지」를 지웠다(146 이 폭 0.042 를 이미 쟀다 · 이유는 143 의 지속 CE 0.2649)\n");
		LogA("[mlt] 🎯   ⭐ 그런데 **변화 표적은 내용으로 갈린다** — 143: 밀림 %.1f%% (H %.4f) ↔ 새id (H %.4f) · 차 **%.4f**\n",
			100.0 * (double)kAlpha143, (double)kH143Sh, (double)kH143New,
			(double)(kH143New - kH143Sh));
		LogA("[mlt] 🎯   ⚠️⚠️ 단 그 차는 **A1 의 폭이 아니다**(부분집합의 난이도 차다) ⇒ ★ 이 회차가 **폭을 직접 잰다**\n");
		LogA("[mlt] 🎯   ⚙️ 구현 — **지속은 전부 버린다**(145 의 q=0.00 자리) ⇒ 갈리는 것이 **변화 표적의 선택뿐**\n");
		LogA("[mlt] 🎯   ⭐ **학습은 부분집합 · 채점은 전부** — ⚠️ 안 그러면 *\"쉬운 것만 남기고 좋아졌다\"* 는 자명한 승리다\n");
		LogA("[mlt] 🎯   ⭐ **개수를 맞춘다**(r = min(α,1−α)) — ⚠️ 회차 119 가 정확히 이 교란으로 죽었다\n");
		LogA("[mlt] 🎯   ⭐ 검산 = ㈃ 가 **%.4f ± 0.05**(145 의 q=0.00) · 관문 = **폭 > 2·SE**\n", (double)kCE145E);
		LogA("[mlt] 🎯   🔮 예측 — 폭이 2·SE 를 넘고(A1 ✅) · **㈀(밀림만)이 ㈁ 보다 전체에서 좋고** · 둘 다 ㈃ 보다 나쁘다\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

	// ── 인코더 · 코퍼스(138~148 과 **비트 동일**) ────────────────────
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
		_trA.SetSortById(true); _ptA.SetSortById(true);
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
			_CorA(_cor).StoreAct(cx, tt, ids, mag, _norm);
			_pending = false;
		}
		if (_gIdx == 0u)
		{
			Array<float> fr, tg; fr.Reset(0); tg.Reset(0);
			ImageFormat::Bitmap bmp; Bytes packed;
			const uint32 epi = _EpiOf(_cor);
			for (uint32 g = 0; g < kGroup; ++g)
			{
				const uint32 ctx = _gGrp * kGroup + g;
				MLTWorld w; w.Reset(_seed, epi + ctx, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
				for (uint32 t = 0; t < kTime; ++t)
				{
					w.Step();
					if (!w.Render(bmp) || !MLTWorld::Pack(bmp, nullptr, packed)) { _Fail("Render/Pack(문맥)"); return; }
					MLTP2Enc::AppendFrame(fr, tg, (const uint8*)packed.GetData());
					_CorA(_cor).StoreState(ctx, t, w.State());
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
		if (++_cor < 2u) return;
		_AlphaOf();          // ⭐ 학습 코퍼스에서 α 를 재고 문턱 셋을 정한다
		_arm = 0u; _ToBody();
	}

	// ⭐ 결정적 해시 — 팔에 **의존하지 않는다**(짝지음이 성립하게).
	static uint32 _Hash(uint32 ctx, uint32 t, uint32 a)
	{
		uint32 h = ((ctx * 131u + t * 17u + a) * 2654435761u) ^ (_seed * 97u + 12345u);
		h ^= h >> 15; h *= 2246822519u; h ^= h >> 13; h *= 3266489917u; h ^= h >> 16;
		return h % 1000u;
	}

	// ⚠️ 「밀림」 = 그 표적 id 가 **지금 활성 8개 안**에 있다(회차 143 과 같은 정의).
	static bool _InActive(const MLTP3Ctx& C, uint32 src, uint32 tid)
	{
		for (uint32 q = 0; q < kSlots; ++q)
			if ((uint32)(C.Sym()[src + kStateAx + q] - (float)kStateAx) == tid) return true;
		return false;
	}

	// ⭐ α(밀림 비율)를 **학습 코퍼스에서** 잰다 — ⚠️ 시험에서 재면 훔쳐보는 것이다(143 의 규율).
	//   그리고 `r = min(α, 1−α)` 로 두 갈래의 **개수를 맞추는** 문턱 셋을 정한다.
	static void _AlphaOf()
	{
		uint32 nCh = 0u, nSh = 0u;
		for (uint32 ctx = 0; ctx < kNCtx; ++ctx)
			for (uint32 t = 0; t < kTime; ++t)
			{
				const uint32 src = MLTP3Ctx::Row(ctx, t, 0u);
				for (uint32 a = kStateAx; a < kAx13; ++a)
				{
					const float tf = _trA.Tgt()[src + a];
					if (!(tf >= 0.0f && tf < (float)kN)) continue;
					const uint32 tid = (uint32)tf;
					if ((uint32)(_trA.Sym()[src + a] - (float)kStateAx) == tid) continue;   // 지속
					++nCh;
					if (_InActive(_trA, src, tid)) ++nSh;
				}
			}
		const double al = (nCh == 0u) ? 0.5 : (double)nSh / (double)nCh;
		const double r  = (al < 1.0 - al) ? al : (1.0 - al);
		_alpha[_seed] = al; _rKeep[_seed] = r;
		// 문턱(천분율) — 해시가 `< 문턱` 이면 남긴다.
		_thShift = (al > 1.0e-9) ? (uint32)(1000.0 * (r / al) + 0.5) : 0u;
		_thNew   = (1.0 - al > 1.0e-9) ? (uint32)(1000.0 * (r / (1.0 - al)) + 0.5) : 0u;
		_thRand  = (uint32)(1000.0 * r + 0.5);
		if (_thShift > 1000u) _thShift = 1000u;
		if (_thNew   > 1000u) _thNew   = 1000u;
		LogA("[mlt] 🎯   씨앗 %2u · 변화 표적 %u(%.1f/문맥) · **밀림 %.1f%%(=α)** · r %.3f · 문턱 밀림 %u‰ · 새id %u‰ · 무작위 %u‰\n",
			_seed, nCh, (double)nCh / (double)kNCtx, 100.0 * al, r, _thShift, _thNew, _thRand);
	}

	// ── 13축 → 14축(낱말은 상수 0) + 마스크 ─────────────────────────
	//   `mask == kMTrain` 이면 **학습**이고 `arm` 이 변화 표적의 선택을 정한다
	//     (⚠️ **지속 표적은 언제나 버린다** — 145 의 q=0.00 자리).
	//   `kMChange`/`kMShift`/`kMNew` 는 **시험 채점** 마스크다(`arm` 무시 · **전부** 채점한다).
	static void _Expand(const MLTP3Ctx& C, uint32 nCtx, uint32 mask, uint32 arm,
		Array<float>& oVal, Array<float>& oSym, Array<float>& oTgt)
	{
		const uint32 steps = nCtx / kBatch;
		const uint32 n = steps * kRows14;
		oVal.Reset(0); oSym.Reset(0); oTgt.Reset(0);
		for (uint32 i = 0; i < n; ++i) { oVal.Add(0.0f); oSym.Add(0.0f); oTgt.Add((float)kN); }
		uint32 scored = 0u;
		const float wv = ((float)kConstCls / (float)(kWordCls - 1u)) * 2.0f - 1.0f;   // = 0
		for (uint32 ctx = 0; ctx < nCtx; ++ctx)
		{
			const uint32 k = ctx / kBatch, b = ctx % kBatch;
			for (uint32 t = 0; t < kTime; ++t)
			{
				const uint32 src = MLTP3Ctx::Row(ctx, t, 0u);
				const uint32 dst = k * kRows14 + b * kCtx14 + t * kAx14;
				oVal.Data()[dst] = wv;
				oSym.Data()[dst] = kWordSym;
				oTgt.Data()[dst] = (float)kN;
				for (uint32 a = 0; a < kAx13; ++a)
				{
					oVal.Data()[dst + 1u + a] = C.Val()[src + a];
					oSym.Data()[dst + 1u + a] = C.Sym()[src + a];
					float tf = C.Tgt()[src + a];
					if (a >= kStateAx && tf >= 0.0f && tf < (float)kN)
					{
						const uint32 tid = (uint32)tf;
						const bool persist = ((uint32)(C.Sym()[src + a] - (float)kStateAx) == tid);
						if (persist)
						{
							// ⭐ 지속은 **어느 경우에도** 채점/학습에서 뺀다.
							tf = (float)kN;
						}
						else
						{
							const bool sh = _InActive(C, src, tid);
							if (mask == kMShift)      { if (!sh) tf = (float)kN; }
							else if (mask == kMNew)   { if (sh)  tf = (float)kN; }
							else if (mask == kMTrain)
							{
								const uint32 h = _Hash(ctx, t, a);
								bool keep = true;
								if (arm == kAShift)     keep = sh && (h < _thShift);
								else if (arm == kANew)  keep = !sh && (h < _thNew);
								else if (arm == kARand) keep = (h < _thRand);
								if (!keep) tf = (float)kN;
							}
							// kMChange = 변화 전부 채점(손대지 않는다)
						}
					}
					if (tf >= 0.0f && tf < (float)kN) ++scored;
					oTgt.Data()[dst + 1u + a] = tf;
				}
			}
		}
		_lastScored = scored;
	}

	static bool _UploadTest(uint32 mask)
	{
		_Expand(_ptA, kPtCtx, mask, kAAll, _eVal[1], _eSym[1], _eTgt[1]);
		return _M.UploadPool(_eVal[1], _eTgt[1], kPtPool) && _M.UploadSymbolPool(_eSym[1], kPtPool);
	}

	static void _BodyBegin(RHI* rhi)
	{
		if (!_M.Setup(rhi, kSymA, kN, kAx14, kTime)) { _Fail("몸통 준비"); return; }
		_Expand(_trA, kNCtx, kMTrain, _arm, _eVal[0], _eSym[0], _eTgt[0]);
		if (_seed == 0u && _out == 0u) _nTrain[_arm] = (double)_lastScored / (double)kNCtx;
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
		_ce[_evalIdx][_out][_arm][_seed] = ce;

		if (++_evalIdx < kEvals)
		{
			const uint32 m = (_evalIdx == 1u) ? (uint32)kMShift : (uint32)kMNew;
			if (!_UploadTest(m)) { _Fail("갈래 시험 풀 업로드"); return; }
			_gate.Begin(kPtPool); return;
		}

		LogA("[mlt] 🎯   %s 씨앗 %2u · 바깥 %u · **전체변화 %.5f** · 밀림 %.5f · 새id %.5f · 학습표적 %.1f\n",
			_ArmName(_arm), _seed, _out,
			(double)_ce[0][_out][_arm][_seed], (double)_ce[1][_out][_arm][_seed],
			(double)_ce[2][_out][_arm][_seed], _nTrain[_arm]);

		if (++_arm < kArms) { _ToBody(); return; }
		_arm = 0u;
		if (++_out < kOut) { _ToBody(); return; }
		_out = 0u;
		_seedOk[_seed] = _finite;
		++_seed; _st = kEncInit;
	}

	static double _M2(uint32 e, uint32 a, uint32 s)
	{
		double v = 0.0;
		for (uint32 o = 0; o < kOut; ++o) v += (double)_ce[e][o][a][s];
		return v / (double)kOut;
	}
	static double _ArmMean(uint32 e, uint32 a)
	{
		double m = 0.0; uint32 n = 0u;
		for (uint32 s = 0; s < _seeds; ++s)
		{
			if (!_seedOk[s]) continue;
			m += _M2(e, a, s); ++n;
		}
		return (n == 0u) ? 0.0 : m / (double)n;
	}

	struct Pair { double d; double se; double t; double sdSeed; double sdRun; uint32 n; uint32 win; };
	static Pair _Paired(uint32 e, uint32 aX, uint32 aY)
	{
		Pair p{}; p.d = 0.0; p.se = 0.0; p.t = 0.0; p.sdSeed = 0.0; p.sdRun = 0.0; p.n = 0u; p.win = 0u;
		double dv[kSeedsMax]; double rs = 0.0;
		for (uint32 s = 0; s < _seeds; ++s)
		{
			if (!_seedOk[s]) continue;
			const double d = _M2(e, aX, s) - _M2(e, aY, s);
			dv[p.n] = d; p.d += d; ++p.n;
			if (d < 0.0) ++p.win;
			const double r0 = (double)_ce[e][0][aX][s] - (double)_ce[e][0][aY][s];
			const double r1 = (double)_ce[e][1][aX][s] - (double)_ce[e][1][aY][s];
			rs += Abs((float)(r1 - r0)) / 1.414213562;
		}
		if (p.n == 0u) return p;
		p.d /= (double)p.n;
		double vv = 0.0;
		for (uint32 i = 0; i < p.n; ++i) { const double e2 = dv[i] - p.d; vv += e2 * e2; }
		p.sdSeed = (p.n > 1u) ? Sqrt((float)(vv / (double)(p.n - 1u))) : 0.0;
		p.sdRun = rs / (double)p.n;
		const double v = (p.sdSeed * p.sdSeed) / (double)p.n
			+ (p.sdRun * p.sdRun) / ((double)p.n * (double)kOut);
		p.se = Sqrt((float)v);
		p.t = (p.se > 1.0e-12) ? (Abs(p.d) / p.se) : 0.0;
		return p;
	}

	static void _Summary()
	{
		uint32 ok = 0u;
		for (uint32 s = 0; s < _seeds; ++s) if (_seedOk[s]) ++ok;
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🎯 **회차 149 · `A1` 파일럿 — 변화 표적의 「내용 축」에 폭이 있나** (씨앗 %u/%u · 유한 %s)\n",
			ok, _seeds, _finite ? "✅" : "⛔");

		// ── ⓪ 세계·코퍼스 서명(규율 21 — 성능보다 먼저) ─────────────
		double am = 0.0, rm = 0.0; uint32 an = 0u;
		for (uint32 s = 0; s < _seeds; ++s) { if (!_seedOk[s]) continue; am += _alpha[s]; rm += _rKeep[s]; ++an; }
		if (an > 0u) { am /= (double)an; rm /= (double)an; }
		LogA("[mlt] 🎯   ── ⓪ **서명** — 밀림 비율 α **%.1f%%**(143 은 %.1f%%) · 맞춘 비율 r **%.3f**\n",
			100.0 * am, 100.0 * (double)kAlpha143, rm);

		// ── ① 팔별 CE(갈래 셋) ─────────────────────────────────────
		LogA("[mlt] 🎯   ── ① **팔별 CE**(⭐ 채점은 **늘 전부** — 학습만 부분집합이다) ──\n");
		LogA("[mlt] 🎯     팔                    │ 학습표적 │ **전체변화** · 밀림 · 새id\n");
		double all4[kArms];
		for (uint32 a = 0; a < kArms; ++a)
		{
			all4[a] = _ArmMean(0u, a);
			LogA("[mlt] 🎯     %s │ %6.1f  │ **%.4f** · %.4f · %.4f\n",
				_ArmName(a), _nTrain[a], all4[a], _ArmMean(1u, a), _ArmMean(2u, a));
		}

		// ── ② 짝지은 차 ────────────────────────────────────────────
		LogA("[mlt] 🎯   ── ② **짝지은 차**(전체변화 · 음수 = 왼쪽이 낫다) · SE 에 실행 항 ──\n");
		const Pair pW = _Paired(0u, kAShift, kANew);
		LogA("[mlt] 🎯     ⭐ ㈀−㈁ (**A1 의 폭**) │ d̄ %+.5f · SE %.5f · **|d̄|/SE %6.2f** · %u/%u\n",
			pW.d, pW.se, pW.t, pW.win, pW.n);
		const Pair pSR = _Paired(0u, kAShift, kARand);
		LogA("[mlt] 🎯     ㈀−㈂ (내용 vs 내용0)     │ d̄ %+.5f · SE %.5f · |d̄|/SE %6.2f · %u/%u\n",
			pSR.d, pSR.se, pSR.t, pSR.win, pSR.n);
		const Pair pNR = _Paired(0u, kANew, kARand);
		LogA("[mlt] 🎯     ㈁−㈂ (내용 vs 내용0)     │ d̄ %+.5f · SE %.5f · |d̄|/SE %6.2f · %u/%u\n",
			pNR.d, pNR.se, pNR.t, pNR.win, pNR.n);
		const Pair pRA = _Paired(0u, kARand, kAAll);
		LogA("[mlt] 🎯     ㈂−㈃ (절반 vs 전부)      │ d̄ %+.5f · SE %.5f · |d̄|/SE %6.2f · %u/%u\n",
			pRA.d, pRA.se, pRA.t, pRA.win, pRA.n);

		// ── ③ 자가 결정적인가 ──────────────────────────────────────
		double runSum = 0.0; uint32 runN = 0u, runZero = 0u;
		for (uint32 s = 0; s < _seeds; ++s)
		{
			if (!_seedOk[s]) continue;
			for (uint32 a = 0; a < kArms; ++a)
			{
				const double d = Abs((float)((double)_ce[0][1][a][s] - (double)_ce[0][0][a][s]));
				runSum += d; ++runN; if (d == 0.0) ++runZero;
			}
		}
		LogA("[mlt] 🎯   ── ③ **`sd_run` 확인**(규율 47) — 비트 동일 **%u/%u** · 평균 |Δ| **%.3e**\n",
			runZero, runN, (runN == 0u) ? 0.0 : runSum / (double)runN);

		// ── 관문 ───────────────────────────────────────────────────
		const bool apply = (_seeds >= 3u);
		const double cE = Abs((float)(all4[kAAll] - (double)kCE145E));
		const bool gChk = !apply || (cE <= 0.05);
		const double nGap = (_nTrain[kAAll] > 1.0e-9)
			? Abs((float)(_nTrain[kAShift] - _nTrain[kANew])) / _nTrain[kAAll] : 1.0;
		const bool gCnt = (nGap < 0.02);
		const double width = Abs((float)pW.d);
		const bool gA1 = (width > 2.0 * pW.se);
		LogA("[mlt] 🎯   ── 관문 ──\n");
		LogA("[mlt] 🎯     ⭐ **검산** — ㈃ %.4f (↔ 145 의 %.4f · 차 %.4f) → %s\n",
			all4[kAAll], (double)kCE145E, cE,
			!apply ? "⚠️ 건너뜀(씨앗 3 이상 — 규율 51)" : (gChk ? "✅" : "⛔ **배치가 다르다**"));
		LogA("[mlt] 🎯     ⭐ **개수 맞음** — |n㈀−n㈁|/n㈃ = **%.4f** (<0.02) → %s\n",
			nGap, gCnt ? "✅" : "⛔ **폭이 개수 효과를 섞는다**");
		LogA("[mlt] 🎯     ⭐ **A1** — 폭 **%.5f** ↔ 2·SE **%.5f** ⇒ 배수 **%.2f** → %s\n",
			width, 2.0 * pW.se, (pW.se > 1.0e-12) ? width / (2.0 * pW.se) : 0.0,
			gA1 ? "✅ **폭이 있다**" : "⛔ **폭이 없다**");

		// ── 판정 ───────────────────────────────────────────────────
		if (!_finite || ok < _seeds)
			LogA("[mlt] 🎯   ⭐ 판정 = ⛔ **판정불가** — 배관이 안 섰다\n");
		else if (!gChk)
			LogA("[mlt] 🎯   ⭐ 판정 = ⛔ **판정불가** — ***검산이 깨졌다***(145 와 배치가 다르다)\n");
		else if (_seeds == 1u)
			LogA("[mlt] 🎯   ⭐ **1씨앗 진단이다 — 판정하지 않는다**(규율 51)\n");
		else if (!gCnt)
			LogA("[mlt] 🎯   ⭐ 판정 = ⛔ **판정불가** — 개수가 안 맞았다(회차 119 의 그 교란)\n");
		else if (gA1)
			LogA("[mlt] 🎯   ⭐ 판정 = ⭐ ***A1 통과 — 변화 표적의 내용 축에 폭이 있다***(폭 %.4f = 2·SE 의 %.2f배)\n"
			     "[mlt] 🎯      ⇒ ★ 회차 150 = 팔 1·2·4·5·10 판정(엔트로피·마진 ↔ NLL ↔ 오라클)\n",
			     width, width / (2.0 * pW.se));
		else
			LogA("[mlt] 🎯   ⭐ 판정 = ⛔ **A1 탈락 — 이 목적지도 폭이 없다**(폭 %.4f ≤ 2·SE %.5f)\n"
			     "[mlt] 🎯      ⇒ ⚠️ 그러면 등록해 둔 갈림이 열린다: ***이 세계에서 자기평가가 값을 낼 수 있는\n"
			     "[mlt] 🎯         유일한 손잡이가 전역 스칼라(`q`)뿐인가***\n",
			     width, pW.se);
		LogA("[mlt] 🎯   ⚠️ 문맥 학습 %u · 시험 %u · %u걸음 · **파일럿이다** — 절대 성능으로 인용하지 않는다\n",
			kNCtx, kPtCtx, kSteps);
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		_E.Destroy(); _done = true;
	}

	static void _Fail(const char* why)
	{
		LogA("[mlt] 🎯 ⛔ %s (씨앗 %u · 팔 %u · 바깥 %u · 평가 %u · 단계 %u · 코퍼스 %u · 걸음 %u)\n",
			why, _seed, _arm, _out, _evalIdx, _st, _cor, _step);
		_E.Destroy(); _done = true;
	}

	CW_BODY(MLTL1K0)
};
