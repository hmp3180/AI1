// mltp4b3.cw — 🔊 회차 102 · **개입을 키우고 표적을 늘린다** (`-mltp4b3`) ⭐ **판정 회차**
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 102 이다.** ⭐ **하네스보다 먼저 썼다.**
//
// ⚠️⚠️ **자를 한 글자도 안 바꾼다** — 2×2 교차 · 표제 · 위생 셋 · 문턱 · 씨앗 12 **그대로**.
//   바꾸는 것은 **「신호」와 「표본」**뿐이라 규율에 안 걸린다.
//
// ── ⚠️ 회차 101 이 남긴 자리 ──────────────────────────────────────────────
//   위생①② **12/12** ✅(문맥 512 가 고쳤다) · **위생③ 분할 반쪽 5/12·5/12** ⛔ ⇒ **판정불가**.
//   `D = +0.00149` 는 **잡음과 구별되지 않는다**. ⇒ ⭐ ***병이 「학습 실패」에서 「측정 감도」로
//   옮겨졌다*** — 고칠 수 있는 자리다.
//
// ── ⭐ 코드를 열어 확인한 것(규율 21 — 추론하지 않고 읽었다) ────────────────
//   `_Other` 가 `k = 0.6 + Unit·0.3`(**0.3~0.9** · 평균 0.6)로 **부호를 뒤집고 크기를 줄였다**
//   ⇒ 차이 `|a_A − a_B| = |a|·(1+k)` ≈ **1.6배**.
//
// ── 바꾸는 것 셋 ──────────────────────────────────────────────────────────
//   **㈀ 신호** — `k` 를 **1.0 고정** ⇒ **정확한 부호 뒤집기**(차이 **2.0배** · +25%).
//     ★ **분포 안에 남는다**(`_PickAct` 의 `Unit` 이 대칭이라 `−a` 는 **본 적 있는 행동**).
//     ⛔ *"최대값으로 밀기"* 는 **분포 밖**이라 안 쓴다 — 그러면 예측이 나쁜 이유가
//       「슬롯을 안 읽어서」가 아니라 **「본 적 없어서」**가 되어 판정이 뒤섞인다.
//   **㈁ 표본** — `kTestCtx` **64 → 512** ⇒ 채점 표적 **512 → 4096**(8배)
//     ⇒ `D` 의 잡음이 **`√8 ≈ 2.8배`** 줄어든다.
//   **㈂ 눈금** — ⭐ **개입 크기**(축별 `|a_A−a_B|` 평균/최대)와 ⭐ **그것이 만든 「표적 차이」**
//     (A·B 의 시각 `kSplit` 표적이 몇 칸 다른가)를 **찍는다**.
//     ⚠️ 표적이 안 갈리면 **개입이 세계에 안 닿은 것**이고 그건 **완전히 다른 병**이다.
//
// ── ⭐ 예측을 미리 적었다 ─────────────────────────────────────────────────
//   · 위생①② **12/12** 재현 · **위생③ ⚠️ 모른다**(표적 8배라 설 가능성이 크지만 그것이 이 회차의 물음)
//   · **표제 ⚠️ 진짜 모른다** — 회차 101 의 `D = +0.0015`(**부호가 반대**)가 잡음이면 뒤집히고
//     진짜면 8배 표본에서 **더 또렷하게 +** 로 남는다 ⇒ ★ **어느 쪽이든 읽힌다.**
//
// ── (아래는 회차 101 의 머리말 원문) ───────────────────────────────────────
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **회차 101 등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 101 이다.**
//
// ── ⭐ **하네스를 열어 보니 원인이 그 자리에 있었다** ────────────────────
//   회차 81 은 `kNCtx = 128` 이었다 — ***회차 84 가 「문맥 수가 병목」을 12/12 로 세운 바로 그 값.***
//   그리고 회차 78·81 이 멈춘 이유는 **위생②**(`A→A 1.1521 > 복사바닥 1.0835`)였다.
//   ⇒ ⭐ ***P3 가 회차 82·83 에서 겪은 것과 「똑같은 병」이다*** — 128 에서는 복사바닥을 못 넘고
//     (2~5/12), **512 로 올리자 12/12** 가 됐다(회차 84 · 85a **5→12** · 85b **2→12**).
//   ⇒ ⭐ **회차 85 가 P3 에 한 수술을 P4 에 그대로 한다.**
//
// ── ⚠️⚠️ **자·팔·문턱은 한 글자도 안 바꾼다** ────────────────────────────
//   2×2 교차 · 표제(`CE(A→A)+CE(B→B) < CE(A→B)+CE(B→A)`) · 위생 셋 · 씨앗 12 · `kSteps 800`
//   **전부 그대로**다. 바꾸는 것은 **`kNCtx`(128→512) 와 `kTestEpi`(201→901) 둘뿐**이다.
//   ★ 회차 85 의 그 규약 — ***자를 안 바꿔야 회차 78·81 과 견줄 수 있다.***
//
// ── ⭐ 예측을 미리 적었다 ─────────────────────────────────────────────────
//   · **위생②가 살아난다**(`3/12 → ≥10`) — 회차 85a/85b 의 근거
//   · **표제(2×2 교차)는 ⚠️ 진짜 모른다.** 회차 78 의 눈금(*"CE 가 컨텍스트가 아니라 표적에만
//     달려 있다"*)은 **위생이 안 선 판의 숫자**라 **믿을 수 없다** ⇒ 위생이 서면 **처음으로 읽힌다**.
//   ⚠️ 회차 78 의 `D = −0.0033 · 8/12` 도 같은 이유로 **인용하지 않는다.**
//
// ── ⭐ 결과의 뜻도 미리 못박았다 ──────────────────────────────────────────
//   | 위생✅ 표제✅ | ⭐ ***P4 ㉠ 이 선다*** — 같은 상태에서 **행동값만 바꾸면 예측이 갈린다**(방향까지)
//     ⇒ *"내 행동이 화면을 바꾼다"* 를 **처음으로** 말할 수 있다 |
//   | 위생✅ 표제⛔ | ⭐ **행동 슬롯을 안 읽는다** — 이번엔 **위생이 서므로 판정으로 부를 수 있다**.
//     ⚠️ 행동값이 **다음 상태를 결정**하는데 안 읽는다면 그것이 **큰 사실**이다 |
//   | 위생⛔       | ⛔ **판정불가** — 문맥이 범인이 아니었다 ⇒ 다른 후보(㈏ 채점 자리 · ㈑ `kAxes 18` × 시각 6)로 |
//
// ── (아래는 회차 81 의 머리말 원문) ────────────────────────────────────────
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **회차 81 등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 81 이다.**
// ⭐ **회차 78 과 한 곳만 다르다** — `_Cross` 에서 조합을 넘기기 전에 **틱을 비운다**(`kSwap`).
//   설계·팔·교차·씨앗·규약·채점 자리·관문은 **한 글자도 안 바꿨다**.
//
// ⚠️⚠️ **왜** — 회차 78 은 조합 넷을 **곧바로 이어서** 업로드했다. 이 엔진은 dispatch 를
//   `computeCb` 에 **누적만** 하고 제출은 **Present 1회**다(회차 59 의 그 함정) ⇒ 오염.
//   ★ 그것이 회차 78 의 두 관측을 **둘 다** 설명한다:
//     ㈀ CE 가 전반적으로 높다(1.1521 ↔ 회차 80 의 0.86 대)
//     ㈁ **CE 가 컨텍스트에 안 달렸다** — 업로드가 씻겨서 네 조합이 사실상 같은 것을 봤다.
//   ⇒ ⚠️ 회차 78 의 그 눈금(*"행동 슬롯이 영향이 없다"*)을 **인용하지 않는다**.
// ══════════════════════════════════════════════════════════════════════════════
//
// ── (아래는 회차 78 의 머리말 원문) ──────────────────────────────────────
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 78 이다.** ⭐ **하네스보다 먼저 썼다**
//   (회차 77 이 어긴 절차를 지킨다).
// ⭐ **판정 회차다** — 상위 = **P4 · 행동과 인과**.
// ══════════════════════════════════════════════════════════════════════════════
//
// ⚠️⚠️⚠️ **규약을 바꿨다** — 회차 78 등록이 찾은 설계 결함:
//   회차 77: 시각 `t` 슬롯 = `[상태(t 이동 후)][행동(t 에 쓴 것)][활성(t 이동 후)]`
//     ⇒ 행동을 바꾸면 **같은 시각의 상태·활성도 같이 갈린다** ⇒ 「같은 상태에서 행동만」이 깨진다.
//   **회차 78**: 시각 `t` 슬롯 = `[상태(t)][행동(t → t+1 에 쓸 것)][활성(t)]`
//     ⇒ ⭐ 시각 6 의 **상태·활성이 A/B 에서 같고 행동만 다르다** ⇒ 개입이 성립한다.
//   ★ 근거 셋: ㈀ `MLT.md` 의 `[ACT]` 는 **지금 할 행동**이다 ㈁ 개입이 성립한다
//     ㈂ **P5 로 가는 길과 맞는다**(모델이 낼 것은 「다음에 할 행동」이다).
//
// ── 교차 ────────────────────────────────────────────────────────────────
//   시각 0..5 **공통** · 시각 6 에서 행동만 `a_A`/`a_B` ⇒ 시각 7 의 활성이 갈린다
//   채점 = **시각 6 의 활성 표적 8칸만**(회차 60 과 같은 형식)
//     `D = [CE(A→A) + CE(B→B)] − [CE(A→B) + CE(B→A)]` · **표제: `D < 0`**
//   ⚠️ 학습은 **별도의 온전한 코퍼스**로 한다 — A 로 학습하면 A 에 유리해진다(대칭이 깨진다).

using namespace PE;

class MLTP4B3
{
public:
	static void Tick(RHI* rhi)
	{
		if (_done || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltp4b3"))
		{
			LogA("[mlt] ⏳ 회차 78은 **꺼져 있다**(`-mltp4b3`) — P4 ㉠ 개입 시험(2×2 교차)\n");
			_done = true; return;
		}
		if (!_banner) { _Banner(); _banner = true; }
		if (_seed >= kSeeds) { _Summary(); return; }
		switch (_st)
		{
		case kEncInit:  _EncBegin(rhi); return;
		case kEncTrain: _EncTrain();    return;
		case kGather:   _Gather();      return;
		case kQuiesce:  if (_qWait > 0u) { --_qWait; } else _st = kBodyInit; return;
		case kBodyInit: _BodyBegin(rhi); return;
		case kBodyTrain:_BodyTrain();   return;
		case kCross:    _Cross();       return;
		case kSwap:     if (_qWait > 0u) { --_qWait; } else _SwitchToCross(_combo); return;
		default: return;
		}
	}

	static bool Done() { return _done; }

private:
	static constexpr uint32 kSeeds = 12u;
	static constexpr uint32 kEncF = 32u, kEncSteps = 1200u, kEncPerTick = 8u;
	static constexpr uint32 kN = 250u, kLocal = 8u;
	static constexpr uint32 kTime = MLTP4Ctx::kTime;
	static constexpr uint32 kBatch = MLTP4Ctx::kBatch;
	static constexpr uint32 kAxes = MLTP4Ctx::kAxes;
	static constexpr uint32 kSlots = MLTP4Ctx::kPersist;
	static constexpr uint32 kStateAx = MLTP4Ctx::kStateAx;
	static constexpr uint32 kActAx = MLTP4Ctx::kActAx;
	static constexpr uint32 kCand = MLTP2Cfg::kPatches * kLocal;
	// ⭐ **회차 101 이 고친 유일한 것 둘** — `kNCtx` **128 → 512** · `kTestEpi` **201 → 901**.
	//   ⚠️⚠️ 회차 78·81 이 멈춘 이유는 **위생②**(`A→A 1.1521 > 복사바닥 1.0835`)였고,
	//     ***그것은 P3 가 회차 82·83 에서 겪은 것과 「똑같은 병」이다*** — **회차 84 가 12/12 로
	//     「문맥 수가 병목」을 세웠고**, 512 로 올리자 회차 85a 는 **5/12 → 12/12**,
	//     85b 는 **2/12 → 12/12** 가 됐다. ⇒ ★ **그 수술을 P4 에 그대로 한다.**
	//   ⚠️ 그리고 **규율 12** — `kNCtx` 를 512 로 올리면 학습이 **1~512** 라 `kTestEpi = 201` 은
	//     ***시험이 통째로 누출된다.*** ⇒ **901** 로 올린다(회차 82 가 P3 에 한 것과 같다).
	// ⭐ **회차 102 의 고침 ㈁** — `kTestCtx` **64 → 512** ⇒ 채점 표적 **512 → 4096**(8배)
	//   ⇒ `D` 의 잡음이 **`√8 ≈ 2.8배`** 줄어든다. 회차 101 의 위생③(분할 반쪽 5/12·5/12)이
	//     **표본 때문**이었다면 이것이 고친다. ⚠️ 자는 한 글자도 안 바꿨다 — **표본만** 늘렸다.
	static constexpr uint32 kNCtx = 512u, kTestCtx = 512u;
	static constexpr uint32 kTrainEpi = 1u, kTestEpi = 901u;
	static_assert(kTestEpi >= kTrainEpi + kNCtx,
		"시험 에피소드가 학습과 겹친다 — kTestEpi >= kTrainEpi + kNCtx 여야 한다(규율 12)");
	static constexpr uint32 kPoolSteps = kNCtx / kBatch, kTestPool = kTestCtx / kBatch;
	static constexpr uint32 kGroup = kEncF / kTime;
	static constexpr uint32 kSteps = 800u, kPerTick = 4u;
	static constexpr uint32 kRep = 6u, kSignPass = 10u;
	static constexpr float  kFlatRel = 1.0e-6f;
	static constexpr uint32 kSplit = kTime - 2u;            // ⭐ 시각 6 에서 가른다
	// 네 조합 — 컨텍스트(0=A,1=B) × 표적(0=A,1=B)
	enum { kAA = 0u, kAB = 1u, kBA = 2u, kBB = 3u, kCombos = 4u };

	// ⭐ `kSwap` — 조합을 넘기기 전에 **틱을 비우는** 자리(회차 81 이 더한 것).
	enum { kEncInit, kEncTrain, kGather, kQuiesce, kBodyInit, kBodyTrain, kCross, kSwap };

	inline static MLTP2Enc _E;
	inline static MLTModel _M;
	inline static MLTP4Ctx _tr, _cA, _cB;                   // 학습 · 시험 A · 시험 B
	inline static MLTEvalGate _gate;
	inline static bool _done = false, _banner = false, _encSetup = false, _finite = true;
	inline static bool _pending = false, _pre = false, _lr0 = false;
	inline static uint32 _seed = 0u, _st = kEncInit, _step = 0u, _rep = 0u;
	inline static uint32 _cor = 0u, _gGrp = 0u, _gIdx = 0u, _combo = 0u;
	inline static Array<float> _code, _norm, _tgtMask[2];   // 시각 6 만 남긴 표적(A·B)
	inline static float _run[kCombos][kRep];
	inline static float _ce[kCombos][kSeeds], _dA[kSeeds], _dB[kSeeds], _dAll[kSeeds];
	inline static float _pre0[kSeeds], _lr0After[kSeeds], _floor[kSeeds];
	// ⭐ **㈂ 눈금**(규율 21) — 개입 크기와 **그것이 만든 표적 차이**
	inline static double _dSum[MLTAct::kAxes] = { 0.0, 0.0, 0.0, 0.0, 0.0 };
	inline static float  _dMax[MLTAct::kAxes] = { 0.0f, 0.0f, 0.0f, 0.0f, 0.0f };
	inline static uint32 _dN = 0u;
	inline static uint64 _tgtDiff = 0u, _tgtTot = 0u;   // A·B 의 시각 kSplit 표적이 몇 칸 다른가
	inline static bool  _seedOk[kSeeds];
	inline static uint32 _qWait = 0u;

	static void _ToBody() { _qWait = MLTEvalGate::kDelay; _st = kQuiesce; }
	static const char* _ComboName()
	{
		return (_combo == kAA) ? "A→A" : ((_combo == kAB) ? "A→B" : ((_combo == kBA) ? "B→A" : "B→B"));
	}

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🔊 **회차 102 · 개입을 키우고 표적을 늘린다**(⭐ 판정 회차 · ⚠️ **자는 한 글자도 안 바꾼다**)\n");
		LogA("[mlt] 🔊   ⚠️ 회차 101 — 위생①② **12/12** ✅(문맥 512 가 고쳤다) · **위생③ 5/12·5/12** ⛔ ⇒ 판정불가 · `D = +0.00149`(잡음과 구별 안 됨)\n");
		LogA("[mlt] 🔊   ⇒ ⭐ 병이 **「학습 실패」에서 「측정 감도」로** 옮겨졌다 — 고칠 수 있는 자리다\n");
		LogA("[mlt] 🔊   **㈀ 신호** — `_Other` 의 `k` 를 **1.0 고정**(부호 뒤집기) ⇒ 차이 `1.6배 → 2.0배`\n");
		LogA("[mlt] 🔊     ★ **분포 안에 남는다**(`Unit` 이 대칭이라 `−a` 는 본 적 있는 행동) · ⛔ *최대값으로 밀기* 는 **분포 밖**이라 안 쓴다\n");
		LogA("[mlt] 🔊   **㈁ 표본** — `kTestCtx` 64 → **%u** ⇒ 채점 표적 512 → **%u**(8배) ⇒ `D` 잡음이 **√8 ≈ 2.8배** 준다\n",
			kTestCtx, kTestCtx * MLTP4Ctx::kPersist);
		LogA("[mlt] 🔊   **㈂ 눈금**(규율 21) — **개입 크기**와 ⭐ **개입이 세계에 닿았나**(표적이 갈린 칸 %%)를 찍는다\n");
		LogA("[mlt] 🔊   ⭐ **예측** — 위생①② 12/12 재현 · **위생③ ⚠️ 모른다**(그것이 물음) · **표제 ⚠️ 진짜 모른다**(어느 쪽이든 읽힌다)\n");
		LogA("[mlt] ⏳   ⭐ 회차 78 과 **한 곳만** 다르다 — 조합을 넘기기 전에 **틱을 비운다**\n");
		LogA("[mlt] ⏳   ⚠️ 눈금(회차 78) — A→A **1.1521** · 바닥 **1.0835** · 넘음 **3/12** ⛔\n");
		LogA("[mlt] ⏳   ⚠️ **규약 변경** — 행동 슬롯 = 「이 시각에서 **다음으로** 갈 때 쓸 행동」\n");
		LogA("[mlt] ⏳   시각 0..%u 공통 · 시각 %u 에서 **행동만** 갈린다 · 채점 = 시각 %u 의 표적 8칸\n",
			kSplit - 1u, kSplit, kSplit);
		LogA("[mlt] ⏳   ★ 표제 `D = [CE(A→A)+CE(B→B)] − [CE(A→B)+CE(B→A)] < 0` — ⭐ **문턱 없음**(부호)\n");
		LogA("[mlt] ⏳   ⚠️ 학습은 **별도 코퍼스** — A 로 학습하면 A 에 유리해진다(대칭이 깨진다)\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

	// ══════════════════════════════════════════════════════════════════
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
		_tr.SetSortById(true); _cA.SetSortById(true); _cB.SetSortById(true);
		_tr.Begin(kNCtx, kN); _cA.Begin(kTestCtx, kN); _cB.Begin(kTestCtx, kN);
		_cor = 0u; _gGrp = 0u; _gIdx = 0u; _pending = false; _st = kGather;
	}

	// `_cor`: 0 = 학습(128) · 1 = 시험 A(64) · 2 = 시험 B(64)
	static void _Gather()
	{
		MLTP4Ctx& C = (_cor == 0u) ? _tr : ((_cor == 1u) ? _cA : _cB);
		const uint32 nCtx = (_cor == 0u) ? kNCtx : kTestCtx;
		if (_pending)
		{
			Array<float> ids, mag;
			if (!_E.ReadAct(ids, mag) || ids.Count() != kCand) { _Fail("활성 리드백"); return; }
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
				MLTWorld w; w.Reset(_seed, epi + ctx, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
				for (uint32 t = 0; t < kTime; ++t)
				{
					// ⭐ **새 규약** — 렌더·상태·활성을 **먼저** 넣고, **그 다음** 행동을 넣고 굴린다.
					if (!w.Render(bmp) || !MLTWorld::Pack(bmp, nullptr, packed)) { _Fail("Render/Pack(문맥)"); return; }
					MLTP2Enc::AppendFrame(fr, tg, (const uint8*)packed.GetData());
					C.StoreState(ctx, t, w.State());
					// ⭐ 시각 `kSplit` 에서 **행동만** 가른다(그 앞은 공통이라 A·B 가 비트 동일이다).
					MLTAct a = w.ActAt(w.StepNo());
					if (_cor == 2u && t == kSplit)
					{
						// ⭐ **㈂ 눈금**(규율 21) — 개입이 실제로 얼마나 큰지 **찍는다**(추론하지 않는다).
						const MLTAct o = _Other(a, _seed, ctx);
						for (int q = 0; q < MLTAct::kAxes; ++q)
						{
							const float d = Abs(a.Axis(q) - o.Axis(q));
							_dSum[q] += (double)d;
							if (d > _dMax[q]) _dMax[q] = d;
						}
						++_dN;
						a = o;
					}
					C.StoreAct5(ctx, t, a);
					w.StepWith(a);
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
			if (++_cor >= 3u)
			{
				_MakeMasks();
				Array<float> marg; _tr.Marginal(marg);
				float c1 = 0.0f, c2 = 0.0f, l1 = 0.0f, l2 = 0.0f;
				_tr.BestCopy(marg, c1, c2, l1, l2, kSplit);
				const float f1 = (float)_cA.CeCopy(marg, l1, false, kSplit);
				const float f2 = (float)_cA.CeCopy(marg, l2, true, kSplit);
				_floor[_seed] = (f1 < f2) ? f1 : f2;
				// ⭐ **㈂ 눈금** — 개입이 **세계에 닿았나**: A·B 의 시각 `kSplit` 표적이 몇 칸 다른가.
				//   ⚠️ 이것이 0 에 가까우면 **개입이 세계에 안 닿은 것**이고, 그건 완전히 다른 병이다.
				uint32 dif = 0u, tot = 0u;
				for (uint32 ctx = 0; ctx < kTestCtx; ++ctx)
					for (uint32 j = 0; j < MLTP4Ctx::kPersist; ++j)
					{
						const uint32 r = MLTP4Ctx::Row(ctx, kSplit, MLTP4Ctx::kStateAx + MLTP4Ctx::kActAx) + j;
						++tot;
						if (_cA.Tgt()[r] != _cB.Tgt()[r]) ++dif;
					}
				_tgtDiff += dif; _tgtTot += tot;
				LogA("[mlt] 🔊 씨앗 %2u · 시험 복사바닥(시각 %u) **%.4f** · ⭐ **표적이 갈린 칸 %.1f%%**(%u/%u)\n",
					_seed, kSplit, (double)_floor[_seed], 100.0 * (double)dif / (double)tot, dif, tot);
				_combo = 0u; _rep = 0u; _lr0 = true; _ToBody();     // ⭐ 먼저 `lr=0` 위생
			}
		}
	}

	// ⭐ **다른 행동** — ⭐ **회차 102 의 고침 ㈀**: `k` 를 **1.0 으로 고정** ⇒ **정확한 부호 뒤집기**.
	//   ⚠️ 회차 101 까지는 `k = 0.6 + Unit·0.3` 이라 **0.3~0.9**(평균 0.6)였다 ⇒ 차이가 `|a|·1.6` 였다.
	//     이제 `|a_A − a_B| = 2·|a|` 로 **+25%** 다.
	//   ★ **분포 안에 남는다** — `_PickAct` 의 `Unit` 이 **대칭**이라 `−a` 는 모델이 **본 적 있는 행동**이다.
	//   ⛔ *"최대값으로 밀기"* 는 **분포 밖**이라 안 쓴다 — 그러면 예측이 나쁜 이유가
	//     「슬롯을 안 읽어서」가 아니라 **「본 적 없어서」**가 되어 판정이 뒤섞인다.
	static MLTAct _Other(const MLTAct& a, uint32 seed, uint32 ctx)
	{
		(void)seed; (void)ctx;                        // ⚠️ 더 이상 난수를 안 쓴다(결정적 · 부호 뒤집기)
		MLTAct v;
		v.fwd = -a.fwd; v.up = -a.up; v.side = -a.side;
		v.dYaw = -a.dYaw; v.dPitch = -a.dPitch;
		return v;
	}

	// 채점 자리를 **시각 `kSplit` 의 활성 8칸**으로 좁힌 표적 두 벌.
	static void _MakeMasks()
	{
		for (uint32 s = 0; s < 2u; ++s)
		{
			const MLTP4Ctx& C = (s == 0u) ? _cA : _cB;
			const uint32 n = kTestPool * MLTP4Ctx::kRows;
			_tgtMask[s].Reset(0);
			for (uint32 i = 0; i < n; ++i) _tgtMask[s].Add(C.Tgt()[i]);
			const float ign = (float)kN;
			for (uint32 ctx = 0; ctx < kTestCtx; ++ctx)
				for (uint32 t = 0; t < kTime; ++t)
				{
					if (t == kSplit) continue;
					const uint32 base = MLTP4Ctx::Row(ctx, t, MLTP4Ctx::kOAct2);
					for (uint32 j = 0; j < kSlots; ++j) _tgtMask[s].Data()[base + j] = ign;
				}
		}
	}

	// ══════════════════════════════════════════════════════════════════
	static void _BodyBegin(RHI* rhi)
	{
		if (!_M.Setup(rhi, kStateAx + kActAx + kN, kN, kAxes, kTime)) { _Fail("몸통 준비"); return; }
		if (!_M.UploadPool(_tr.Val(), _tr.Tgt(), kPoolSteps) || !_M.UploadSymbolPool(_tr.Sym(), kPoolSteps))
		{ _Fail("학습 풀 업로드"); return; }
		_step = 0u;
		if (_lr0) { _pre = true; _SwitchToCross(kAA); return; }   // `lr=0` 은 학습 전 CE 부터
		_pre = false; _st = kBodyTrain;
	}

	// 조합 `c` 의 시험 풀을 올린다 — 컨텍스트(A/B) × 표적(A/B).
	static bool _SwitchToCross(uint32 c)
	{
		const MLTP4Ctx& ctxSrc = (c == kAA || c == kAB) ? _cA : _cB;
		const uint32 tgtSel = (c == kAA || c == kBA) ? 0u : 1u;
		if (!_M.UploadPool(ctxSrc.Val(), _tgtMask[tgtSel], kTestPool)
			|| !_M.UploadSymbolPool(ctxSrc.Sym(), kTestPool))
		{ _Fail("시험 풀 업로드"); return false; }
		_gate.Begin(kTestPool); _st = kCross;
		return true;
	}

	static void _BodyTrain()
	{
		if (_step >= kSteps) { _SwitchToCross(_combo); return; }
		for (uint32 i = 0; i < kPerTick && _step < kSteps; ++i)
		{
			_M.SelectStep(_step % kPoolSteps);
			if (!_M.Forward() || !_M.Backward() || !_M.AdamStep(_lr0 ? 0.0f : 1.0f))
			{ _Fail("몸통 스텝"); return; }
			++_step;
		}
	}

	static void _Cross()
	{
		bool fail = false;
		if (!_gate.Step(_M, fail)) return;
		if (fail) { _Fail("평가 게이트"); return; }
		if (!_gate.Finite()) _finite = false;
		const float ce = _gate.Mean();
		if (_pre)
		{
			_pre0[_seed] = ce; _pre = false;
			if (!_M.UploadPool(_tr.Val(), _tr.Tgt(), kPoolSteps) || !_M.UploadSymbolPool(_tr.Sym(), kPoolSteps))
			{ _Fail("학습 풀 복귀"); return; }
			_step = 0u; _st = kBodyTrain; return;
		}
		if (_lr0)                                     // 위생① — 학습 후 CE(평탄해야 한다)
		{
			_lr0After[_seed] = ce;                    // ⚠️ **`_ce` 와 자리를 나눈다**(덮어쓰면 못 센다)
			LogA("[mlt] ⏳   위생 `lr=0` 씨앗 %2u · 전 %.5f → 후 %.5f\n",
				_seed, (double)_pre0[_seed], (double)ce);
			_lr0 = false; _combo = 0u; _rep = 0u; _ToBody(); return;
		}
		_run[_combo][_rep] = ce;
		// ⭐ **회차 81 이 고친 유일한 곳** — 조합을 넘기기 전에 **틱을 비운다**.
		//   ⚠️ 회차 78 은 여기서 `_SwitchToCross` 를 **곧바로** 불렀다. 이 엔진은 dispatch 를
		//     `computeCb` 에 **누적만** 하고 제출은 **Present 1회**이므로(회차 59 의 그 함정),
		//     곧바로 업로드하면 **아직 제출도 안 된 앞 디스패치가 그 버퍼를 나중에 읽는다** ⇒ 오염.
		//   ★ 그것이 회차 78 의 두 관측(CE 가 전반적으로 높다 · 컨텍스트에 안 달렸다)을 설명한다.
		if (++_combo < kCombos) { _qWait = MLTEvalGate::kDelay; _st = kSwap; return; }
		_combo = 0u;
		if (++_rep < kRep) { _ToBody(); return; }                     // 반복마다 몸통을 새로
		_Agg();
	}

	static void _Agg()
	{
		double s[kCombos], sA[kCombos], sB[kCombos];
		for (uint32 c = 0; c < kCombos; ++c) { s[c] = 0.0; sA[c] = 0.0; sB[c] = 0.0; }
		for (uint32 i = 0; i < kRep; ++i)
			for (uint32 c = 0; c < kCombos; ++c)
			{
				s[c] += (double)_run[c][i];
				if ((i % 2u) == 0u) sA[c] += (double)_run[c][i]; else sB[c] += (double)_run[c][i];
			}
		for (uint32 c = 0; c < kCombos; ++c)
		{
			_ce[c][_seed] = (float)(s[c] / (double)kRep);
			sA[c] /= (double)(kRep / 2u); sB[c] /= (double)(kRep / 2u);
		}
		_dAll[_seed] = (_ce[kAA][_seed] + _ce[kBB][_seed]) - (_ce[kAB][_seed] + _ce[kBA][_seed]);
		_dA[_seed] = (float)((sA[kAA] + sA[kBB]) - (sA[kAB] + sA[kBA]));
		_dB[_seed] = (float)((sB[kAA] + sB[kBB]) - (sB[kAB] + sB[kBA]));
		_seedOk[_seed] = _finite;
		LogA("[mlt] ⏳   씨앗 %2u · A→A %.5f · A→B %.5f · B→A %.5f · B→B %.5f | ⭐ **D %.5f**(반쪽 %.5f / %.5f)\n",
			_seed, (double)_ce[kAA][_seed], (double)_ce[kAB][_seed],
			(double)_ce[kBA][_seed], (double)_ce[kBB][_seed],
			(double)_dAll[_seed], (double)_dA[_seed], (double)_dB[_seed]);
		++_seed; _st = kEncInit;
	}

	static void _Summary()
	{
		double m[kCombos], md = 0.0, mf = 0.0;
		for (uint32 c = 0; c < kCombos; ++c) m[c] = 0.0;
		uint32 ok = 0u, flat = 0u, beat = 0u, pass = 0u, pa = 0u, pb = 0u;
		for (uint32 s = 0; s < kSeeds; ++s)
		{
			if (!_seedOk[s]) continue;
			++ok;
			for (uint32 c = 0; c < kCombos; ++c) m[c] += _ce[c][s];
			md += _dAll[s]; mf += _floor[s];
			if (Abs(_lr0After[s] - _pre0[s]) <= kFlatRel * Abs(_pre0[s])) ++flat;
			if (_ce[kAA][s] < _floor[s]) ++beat;
			if (_dAll[s] < 0.0f) ++pass;
			if (_dA[s] < 0.0f) ++pa;
			if (_dB[s] < 0.0f) ++pb;
		}
		if (ok > 0u) { for (uint32 c = 0; c < kCombos; ++c) m[c] /= ok; md /= ok; mf /= ok; }
		const bool split = (pa >= kSignPass) && (pb >= kSignPass);
		const bool h1 = (flat == ok) && _finite;
		const bool h2 = (beat >= kSignPass);
		const bool p1 = (pass >= kSignPass);

		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🔊 **회차 102 · 개입을 키우고 표적을 늘린다**(`kTestCtx %u` ⇒ 표적 **%u개** · 부호 뒤집기 k=1.0) — 읽은 씨앗 %u/%u\n",
			kTestCtx, kTestCtx * MLTP4Ctx::kPersist, ok, kSeeds);
		LogA("[mlt] 🔊   ⚠️ 견줄 것(**회차 101** · 표적 512) — 위생①② **12/12** ✅ · 위생③ **5/12·5/12** ⛔ · `D = +0.00149` · `D<0` **5/12**\n");
		{
			// ⭐ **㈂ 눈금**(규율 21) — 개입 크기와 그것이 만든 표적 차이
			const double n = (_dN > 0u) ? (double)_dN : 1.0;
			LogA("[mlt] 🔊   ⭐ **개입 크기** |a_A−a_B| 평균/최대 — fwd %.3f/%.3f · up %.3f/%.3f · side %.3f/%.3f · dYaw %.3f/%.3f · dPitch %.3f/%.3f\n",
				_dSum[0] / n, (double)_dMax[0], _dSum[1] / n, (double)_dMax[1],
				_dSum[2] / n, (double)_dMax[2], _dSum[3] / n, (double)_dMax[3],
				_dSum[4] / n, (double)_dMax[4]);
			LogA("[mlt] 🔊   ⭐ **개입이 세계에 닿았나** — A·B 의 시각 %u 표적이 갈린 칸 **%.1f%%**(%llu/%llu)\n",
				kSplit, (_tgtTot > 0u) ? 100.0 * (double)_tgtDiff / (double)_tgtTot : 0.0,
				(unsigned long long)_tgtDiff, (unsigned long long)_tgtTot);
		}
		LogA("[mlt] ⏳   ⚠️ 견줄 것(회차 78 · 오염판) — A→A **1.1521** / 바닥 **1.0835** / 넘음 **3/12**\n");
		LogA("[mlt] ⏳   평균 CE — A→A **%.4f** · A→B **%.4f** · B→A **%.4f** · B→B **%.4f**\n",
			m[kAA], m[kAB], m[kBA], m[kBB]);
		LogA("[mlt] ⏳   위생① `lr=0` 평탄 **%u/%u** → %s\n", flat, ok, h1 ? "통과" : "⛔");
		LogA("[mlt] ⏳   시험 복사바닥 **%.4f** · 위생② A→A 가 넘음 **%u/%u** → %s\n",
			mf, beat, ok, h2 ? "통과" : "⛔");
		LogA("[mlt] ⏳   위생③ **분할 반쪽** — A %u/%u · B %u/%u(각 필요 %u) → %s\n",
			pa, ok, pb, ok, kSignPass, split ? "통과" : "⛔");
		LogA("[mlt] ⏳   ⭐ **표제** `D = %.5f` · `D < 0` **%u/%u**(필요 %u · **문턱 없음**)\n",
			md, pass, kSeeds, kSignPass);
		if (!h1 || !h2)
			LogA("[mlt] ⏳   ⭐ 판정 = ⛔ **판정불가** — 위생(평탄·바닥)이 안 섰다\n");
		else if (!split)
			LogA("[mlt] ⏳   ⭐ 판정 = ⚠️ **판정불가** — 이 표본 수에서 자가 안 통한다(분할 반쪽)\n");
		else if (p1)
			LogA("[mlt] ⏳   ⭐ 판정 = ✅✅ **㉠ 통과 — 행동값이 「맞는 미래」를 가리킨다**\n");
		else
			LogA("[mlt] ⏳   ⭐ 판정 = ⛔ **㉠ 실패 — 행동을 안 읽는다** ⇒ 채점 자리와 규약부터 다시 읽는다\n");
		LogA("[mlt] ⏳   ⚠️ 시각 %u 한 칸 · 시험 표적 %u개의 진단이다 — 절대 성능으로 인용하지 않는다\n",
			kSplit, kTestCtx * kSlots);
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		_E.Destroy(); _done = true;
	}

	static void _Fail(const char* why)
	{
		LogA("[mlt] ⏳ ⛔ %s (씨앗 %u · 조합 %u · 반복 %u · 단계 %u)\n", why, _seed, _combo, _rep, _st);
		_E.Destroy(); _done = true;
	}
};
