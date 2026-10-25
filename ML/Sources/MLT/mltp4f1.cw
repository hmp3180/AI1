// mltp4f1.cw — 📊 회차 113 · **㉣ 를 「모은 평균 ± SE」로 · 회차 104 를 12씨앗으로 굳힌다** (`-mltp4f1`)
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 113 이다.** ⭐ **하네스보다 먼저 썼다.**
//   ⭐ 사람이 고른 ㄱ(자 고치기)과 ㄴ(회차 104 굳히기)을 **한 실행으로 합쳤다**(추가 비용 0).
//
// ── ⚠️ 먼저 — 내가 제안한 「정규화」가 **틀렸고 등록 전에 닫았다** ────────────
//   회차 112 로그가 그것을 숫자로 말했다:
//     씨앗 0 · 폭비  0.1470 0.1405 0.1442 0.1342 0.1451  ← ⭐ 거의 일정(`sd(Δ끊음)` 이 안정)
//     씨앗 0 · ㉣   −0.0125 +0.0576 −0.0028 −0.0084 −0.0312 ← ⚠️ 이것만 흔들린다
//   ⇒ ⭐ 불안정한 것은 **척도(분모)가 아니라 구간 평균차(분자)** ⇒ `㉣/sd` 는 폭이 **그대로**다.
//   ⚠️ 상관으로 바꿔도 같다(점이연 `r ≈ 0.061` · 잡음 `≈ 0.072` ⇒ 비 0.85 그대로) ⇒ **규율 20 대로 닫았다.**
//
// ── ⭐ 진짜 병은 **「부호검정」**이었다 ─────────────────────────────
//   부호검정은 **크기를 버리고 부호만** 본다 ⇒ ***씨앗별 잡음이 효과만 할 때 가장 약한 자***다.
//   ⚠️⚠️ 실제로 **회차 106 의 12씨앗 평균 −0.026 은 잡음(0.031/√12 = 0.0089)의 `2.9배`였다**
//     — ***부호검정이 그 정보를 버렸고 그래서 문턱에 걸렸다.***
//   ⇒ ⭐ **③ 만 자를 바꾼다**: `모은 평균 ± SE`(씨앗을 단위로 `SE = sd_씨앗/√12`).
//   ⚠️ **①② 는 부호검정 그대로** — 회차 112 가 그 자리는 `여유/sd_run = 11.4·7.6` 라
//     ***부호가 안 뒤집힌다***고 이미 쟀다(규율 29 를 지킨 것이지 관성이 아니다).
//
// ── ✅ 관문 ───────────────────────────────────────────────────────────────
//   **배관** 씨앗0 바닥 1.1162 · `lr=0` 평탄 24/24 · 유한
//   ⭐ **① 폭비** 씨앗별 ≥0.10 — **12/12**(회차 104 표제① **정본화**)
//   ⭐ **② 상관** 씨앗별 ≥0.10 — **12/12**(회차 104 표제② **정본화**)
//   ⭐ **③ ㉣** `|m̄| ≥ 3·SE` — ⭐ **그리고 부호를 보고한다**
//
// ── 📏 잡음 바닥(규율 29 · 회차 112 실측) ────────────────────────────────
//   `sd_run(①)=0.0074` · `sd_run(②)=0.0544` · `sd_run(③)=0.0307`
//
// ── ⭐ 예측 ──────────────────────────────────────────────────────────────
//   ①② **12/12 통과** ⇒ ⭐ **회차 104 가 정본이 된다**
//   ⭐ ③ 은 ⚠️ **부호가 뒤집힐 것**(회차 112 의 씨앗 0·1·2 바깥평균이 **셋 다 양수**였다)
//     ⇒ `m̄ > 0` 이면 ***"행동을 더 읽는 자리는 「바뀌는 표적」이 아니라 「지속하는 표적」"*** 이 된다.
//   ⚠️ 3씨앗으로 12씨앗을 점치는 것이라 틀릴 수 있고, `|m̄| < 3·SE` 면 **판정불가**로 적는다.
//
// ── (아래는 회차 112 의 머리말 원문 — 자의 근거는 거기 있다) ──────────────
//
// ══════════════════════════════════════════════════════════════════════════════
// mltp4f0.cw — 📏 회차 112 · **`sd_run` 자를 세운다** ⭐ **판정이 아니라 자다**
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 112 다.** ⭐ **하네스보다 먼저 썼다.**
//   ⭐ 사람이 고른 길 = ㈁ *"비결정성을 인정하고 자를 그 위에 세운다"*(2026-08-28).
//
// ── ⚠️ 왜 필요한가 ───────────────────────────────────────────────────────
//   회차 108~111 이 **몸통 학습이 비결정적**임을 세웠다(같은 씨앗·같은 800스텝에서 파라미터
//   859,136개 중 **830,848개**가 갈리고 **간헐적**이다). 범인은 아직 못 잡았다.
//   ⇒ ⭐ 그러면 **잡음 바닥에 「실행」 항을 넣는 것**이 과학을 되살리는 가장 빠른 길이다(규율 29).
//
// ── 🔬 무엇을 하나 ───────────────────────────────────────────────────────
//   ```
//   씨앗마다:  인코더 + gather   ← ⭐ **한 번만**(코퍼스가 결정적임을 회차 108~111 이 증명했다)
//      바깥 반복 out = 0..R−1 :  회차 106 의 **몸통 전체**(5팔 × 6반복)를 처음부터 다시
//                                → `_rows[팔]` → 통계 다섯
//      ⇒ 그 다섯 각각의 **바깥 반복 사이 sd = `sd_run`**
//   ```
//   ⭐ **비용을 줄인 자리** — gather 재사용으로 바깥 반복 하나가 **몸통만**이다.
//
// ── 📐 재는 통계 다섯 — ⚠️ 전부 **기존 회차가 표제/보고로 쓴 것** ────────────
//   ① 폭비 `sd(Δ끊음)/sd(Δ활성끊음)` — 회차 104 표제① (보고 0.185 · 문턱 0.10)
//   ② 상관 `corr(Δ끊음, Δ무작위)`    — 회차 104 표제② (보고 +0.51 · 문턱 0.10)
//   ③ **㉣** `평균Δ끊음(지속)−(비지속)` — 회차 106 표제 (보고 −0.026 · 문턱 0)
//   ④ 평균 Δ끊음 — 회차 103 (보고 −0.0004)   ⑤ CE(㈀ 온전) — 공통
//
// ── ✅ 관문 — ⚠️ **이 회차는 표제가 「가설」이 아니라 「자」다** ────────────
//   **배관** 씨앗 0 의 복사바닥 **1.1162** 재현 · 전 구간 유한
//   ⭐ **산출물** = 통계마다 `sd_run` 과 ***`여유 / sd_run`***(여유 = |보고값 − 문턱|)
//   ⭐ **판정 규칙을 미리 못박았다**(규율 29 의 배관):
//     | ≥ 3 | ✅ 그대로 쓴다 |
//     | 1~3 | ⚠️ **바깥 반복 `R_out`** 을 넣어야 쓴다(평균의 잡음 = `sd_run/√R_out`) |
//     | < 1 | ⛔ **그 자로는 못 잰다** |
//
// ── ⭐ 예측 ──────────────────────────────────────────────────────────────
//   ① ≥3 산다 · ② ≥3 산다 · ③ ⛔ **<1 로 죽는다**(회차 105↔106 짝비교가 이미 `sd≈0.035 > 효과 0.026`)
//   ⚠️ **회차 109·111 에서 내 예측이 연달아 틀렸다** — 이번 것도 그럴 수 있다.
//
// ⚠️⚠️ 몸통·팔·문턱·자는 **회차 106 과 한 글자도 다르지 않다** — 다른 것은 **바깥 반복뿐**이다.

using namespace PE;

class MLTP4F1
{
public:
	static void Tick(RHI* rhi)
	{
		if (_done || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltp4f1"))
		{
			LogA("[mlt] 📊 회차 113(㉣ 를 모은 평균 ± SE 로)은 **꺼져 있다**(`-mltp4f1`)\n");
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
	// ⭐ **회차 113** — 씨앗 **12** × 바깥 반복 **2**(회차 112 는 3×5 였다).
	//   ⚠️ 이번엔 **판정 회차**다 ⇒ 12씨앗이 필요하고, 바깥 반복 2 로 씨앗 평균의 실행잡음을 `1/√2` 로 줄인다.
	static constexpr uint32 kSeeds = 12u, kOut = 2u;
	static constexpr uint32 kEncF = 32u, kEncSteps = 1200u, kEncPerTick = 8u;
	static constexpr uint32 kN = 250u, kLocal = 8u;
	static constexpr uint32 kTime = MLTP4Ctx::kTime;
	static constexpr uint32 kBatch = MLTP4Ctx::kBatch;
	static constexpr uint32 kCandidates = MLTP2Cfg::kPatches * kLocal;
	static constexpr uint32 kNCtx = 512u, kTestCtx = 512u;
	static constexpr uint32 kTrainEpi = 1u, kTestEpi = 901u;
	static_assert(kTestEpi >= kTrainEpi + kNCtx, "시험 에피소드가 학습과 겹친다(회차 81)");
	static constexpr uint32 kPoolSteps = kNCtx / kBatch, kTestPool = kTestCtx / kBatch;
	static constexpr uint32 kGroup = kEncF / kTime;
	static constexpr uint32 kSteps = 800u, kPerTick = 4u;
	static constexpr uint32 kArms = 5u, kRep = 6u;
	static constexpr uint32 kArmWhole = 0u, kArmActCut = 1u, kArmActRnd = 2u,
		kArmLr0 = 3u, kArmPerCut = 4u;
	static constexpr uint32 kActFrom = MLTP4Ctx::kOAct;
	static constexpr uint32 kNone = MLTP4Ctx::kStateAx + MLTP4Ctx::kActAx + kN;
	static constexpr uint32 kSymVocab = kNone + 1u;
	static constexpr float  kFloorRef = 1.1162f;   // 씨앗 0 의 눈금(회차 106·107·108)

	// 📐 통계 다섯 — 보고값과 문턱을 **소스에 박아 둔다**(여유를 자동으로 낸다)
	static constexpr uint32 kStats = 5u;
	static constexpr float kRep0[kStats] = { 0.1848f, 0.5145f, -0.02592f, -0.0004f, 0.9119f };
	static constexpr float kThr [kStats] = { 0.10f,   0.10f,    0.0f,      0.0f,     0.0f };
	static constexpr bool  kHasThr[kStats] = { true, true, true, false, false };
	static const char* _StatName(uint32 s)
	{
		switch (s)
		{
		case 0u: return "① 폭비   sd(Δ끊음)/sd(Δ활성끊음)";
		case 1u: return "② 상관   corr(Δ끊음, Δ무작위)   ";
		case 2u: return "③ ㉣    Δ끊음(지속)−(비지속)   ";
		case 3u: return "④ 평균 Δ끊음                  ";
		default: return "⑤ CE(㈀ 온전)                 ";
		}
	}

	enum { kEncInit, kEncTrain, kGather, kQuiesce, kBodyInit, kBodyTrain, kBodyEval };

	inline static MLTP2Enc _E;
	inline static MLTModel _M;
	inline static MLTP4Ctx _tr, _te;
	inline static bool _done = false, _banner = false, _encSetup = false, _finite = true;
	inline static bool _pending = false, _pre = false;
	inline static uint32 _seed = 0u, _out = 0u, _st = kEncInit, _step = 0u, _arm = 0u, _rep = 0u;
	inline static uint32 _cor = 0u, _gGrp = 0u, _gIdx = 0u, _qWait = 0u;
	inline static Array<float> _code, _norm;
	inline static Array<float> _trVal, _trSym, _teVal, _teSym;
	inline static float _run[kRep], _ce[kArms];
	inline static float _floorTe[kSeeds];
	inline static bool  _seedOk[kSeeds];
	inline static float _pre0 = 0.0f;
	inline static bool  _flat[kSeeds][kOut];

	static constexpr uint32 kRowN = kTestPool * MLTP4Ctx::kRows;
	inline static Array<float> _rowAcc;
	inline static Array<float> _rows[kArms];
	inline static uint32 _ei = 0u, _ewait = 0u;
	inline static bool   _epend = false;
	inline static double _esum = 0.0;
	// ⭐ 씨앗 × 바깥 반복 × 통계
	inline static float _S[kSeeds][kOut][kStats];

	static void _ToBody() { _qWait = MLTEvalGate::kDelay; _st = kQuiesce; }
	static uint32 _Reps() { return (_arm == kArmLr0) ? 1u : kRep; }
	static const char* _ArmName()
	{
		switch (_arm)
		{
		case kArmWhole:  return "㈀ 온전";
		case kArmActCut: return "㈁ 행동끊음";
		case kArmActRnd: return "㈂ 행동무작위";
		case kArmLr0:    return "㈃ lr=0";
		default:         return "㈄ 활성끊음";
		}
	}

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 📊 **회차 113 · ㉣ 를 「모은 평균 ± SE」로 · 회차 104 를 12씨앗으로 굳힌다**(사람이 고른 ㄱ+ㄴ)\n");
		LogA("[mlt] 📊   ⚠️ 내가 제안한 **「정규화」는 등록 전에 닫았다** — 회차 112 로그가 숫자로 반증했다:\n");
		LogA("[mlt] 📊     씨앗0 폭비 0.1470/0.1405/0.1442/0.1342/0.1451 (**거의 일정**) ↔ ㉣ −0.013/+0.058/−0.003/−0.008/−0.031\n");
		LogA("[mlt] 📊     ⇒ ⭐ 불안정한 건 **척도(분모)가 아니라 구간 평균차(분자)** ⇒ 나눠도 폭이 그대로다(규율 20 대로 닫았다)\n");
		LogA("[mlt] 📊   ⭐ **진짜 병은 「부호검정」**이었다 — 크기를 버리고 부호만 보니 잡음≈효과일 때 가장 약하다\n");
		LogA("[mlt] 📊     ⚠️⚠️ 실제로 **회차 106 의 12씨앗 평균 −0.026 은 잡음(0.031/√12=0.0089)의 2.9배**였다 — 그 정보를 버렸다\n");
		LogA("[mlt] 📊   🔬 씨앗 **%u** × 바깥 반복 **%u** — ⭐ gather 는 씨앗당 한 번(코퍼스 결정적)\n", kSeeds, kOut);
		LogA("[mlt] 📊   ⭐ **① 폭비 12/12** · ⭐ **② 상관 12/12**(회차 104 **정본화** · ⚠️ 부호검정 **그대로** — 여유/sd=11.4·7.6)\n");
		LogA("[mlt] 📊   ⭐ **③ ㉣ 는 자를 바꾼다** — `|m̄| ≥ 3·SE`(`SE = sd_씨앗/√%u`) **그리고 부호를 보고한다**\n", kSeeds);
		LogA("[mlt] 📊   📏 잡음 바닥(규율 29 · 회차 112 실측) — sd_run ① 0.0074 · ② 0.0544 · ③ 0.0307\n");
		LogA("[mlt] 📊   ⭐ **예측** — ①② 12/12 통과 · ⭐ **③ 은 부호가 뒤집힐 것**(112 의 씨앗 0·1·2 바깥평균이 **셋 다 양수**)\n");
		LogA("[mlt] 📊     ⇒ 그러면 ***\"행동을 더 읽는 자리는 「바뀌는 표적」이 아니라 「지속하는 표적」\"*** 이 된다\n");
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

	static void _Gather()
	{
		MLTP4Ctx& C = (_cor == 0u) ? _tr : _te;
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
				MLTWorld w; w.Reset(_seed, epi + ctx, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
				for (uint32 t = 0; t < kTime; ++t)
				{
					if (!w.Render(bmp) || !MLTWorld::Pack(bmp, nullptr, packed))
					{ _Fail("Render/Pack(문맥)"); return; }
					MLTP2Enc::AppendFrame(fr, tg, (const uint8*)packed.GetData());
					C.StoreState(ctx, t, w.State());
					const MLTAct a = w.ActAt(w.StepNo());
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
		_gIdx = 0;
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
				LogA("[mlt] ✂️ 씨앗 %2u · 시험 복사바닥 **%.4f**%s\n", _seed, (double)_floorTe[_seed],
					(_seed == 0u) ? ((Abs(_floorTe[0] - kFloorRef) <= 0.0001f)
						? "  ⇒ ⚠️ 배관 관문 ✅(눈금 1.1162)" : "  ⇒ ⛔ 배관 관문 실패") : "");
				_out = 0u; _arm = 0u; _rep = 0u; _ToBody();
			}
		}
	}

	// ⚠️ 회차 106 의 `_CutPool` 과 **한 글자도 다르지 않다**.
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
				_pre0 = ce; _pre = false;
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
		double s = 0.0;
		for (uint32 i = 0; i < R; ++i) s += (double)_run[i];
		_ce[_arm] = (float)(s / (double)R);
		if (_arm != kArmLr0)
		{
			_rows[_arm].Reset(0);
			const float inv = 1.0f / (float)R;
			for (uint32 i = 0; i < kRowN; ++i) _rows[_arm].Add(_rowAcc[i] * inv);
		}
		_rep = 0u;
		if (++_arm < kArms) { _ToBody(); return; }
		_Stats();
		_arm = 0u;
		if (++_out < kOut) { _ToBody(); return; }
		_seedOk[_seed] = _finite;
		_out = 0u; ++_seed; _st = kEncInit;
	}

	// 📐 통계 다섯을 낸다 — ⚠️ 식은 회차 104·105·106 것 그대로다.
	static void _Stats()
	{
		double sC = 0.0, sR = 0.0, sP = 0.0, qC = 0.0, qR = 0.0, qP = 0.0, xCR = 0.0;
		double perS = 0.0, nonS = 0.0; uint32 perN = 0u, nonN = 0u, n = 0u;
		for (uint32 ctx = 0; ctx < kTestCtx; ++ctx)
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
					const uint32 nowId =
						(uint32)(_te.Sym()[r] - (float)(MLTP4Ctx::kStateAx + MLTP4Ctx::kActAx));
					if (nowId == (uint32)tf) { perS += dC; ++perN; } else { nonS += dC; ++nonN; }
					++n;
				}
		float* S = _S[_seed][_out];
		if (n == 0u) { for (uint32 i = 0; i < kStats; ++i) S[i] = 0.0f; return; }
		const double N = (double)n;
		const double mC = sC / N, mR = sR / N, mP = sP / N;
		const double vC = qC / N - mC * mC, vR = qR / N - mR * mR, vP = qP / N - mP * mP;
		const double sdC = Sqrt((float)((vC > 0.0) ? vC : 0.0));
		const double sdR = Sqrt((float)((vR > 0.0) ? vR : 0.0));
		const double sdP = Sqrt((float)((vP > 0.0) ? vP : 0.0));
		const double cov = xCR / N - mC * mR;
		S[0] = (sdP > 1.0e-12) ? (float)(sdC / sdP) : 0.0f;
		S[1] = (sdC > 1.0e-12 && sdR > 1.0e-12) ? (float)(cov / (sdC * sdR)) : 0.0f;
		S[2] = (perN && nonN) ? (float)(perS / (double)perN - nonS / (double)nonN) : 0.0f;
		S[3] = (float)mC;
		S[4] = _ce[kArmWhole];
		_flat[_seed][_out] = (Abs(_ce[kArmLr0] - _pre0) <= 1.0e-6f * Abs(_pre0));
		LogA("[mlt] 📏   씨앗 %u · 바깥 %u — ① 폭비 **%.4f** · ② 상관 **%+.4f** · ③ ㉣ **%+.5f** · ④ 평균Δ %+.5f · ⑤ CE %.5f%s\n",
			_seed, _out, (double)S[0], (double)S[1], (double)S[2], (double)S[3], (double)S[4],
			_flat[_seed][_out] ? "" : "  ⚠️ lr=0 안 평탄");
	}

	static void _Summary()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 📊 **회차 113 결과**(씨앗 %u × 바깥 반복 %u · 문맥 %u)\n", kSeeds, kOut, kNCtx);
		bool plumb = _finite && (Abs(_floorTe[0] - kFloorRef) <= 0.0001f);
		uint32 flatBad = 0u;
		for (uint32 s = 0; s < kSeeds; ++s) for (uint32 o = 0; o < kOut; ++o) if (!_flat[s][o]) ++flatBad;
		if (flatBad != 0u) plumb = false;
		LogA("[mlt] 📊   배관 — 씨앗0 복사바닥 **%.4f**(눈금 %.4f) · `lr=0` 안 평탄 %u/%u · 유한 %s → %s\n",
			(double)_floorTe[0], (double)kFloorRef, flatBad, kSeeds * kOut, _finite ? "✅" : "⛔",
			plumb ? "통과" : "⛔ 판정불가");
		// ⭐ 씨앗별 바깥 평균을 먼저 낸다(씨앗이 판정의 단위다).
		double sm[kStats][kSeeds];
		for (uint32 i = 0; i < kStats; ++i)
			for (uint32 s = 0; s < kSeeds; ++s)
			{
				double m = 0.0;
				for (uint32 o = 0; o < kOut; ++o) m += (double)_S[s][o][i];
				sm[i][s] = m / (double)kOut;
			}
		// ⭐ ①② — 부호검정 **그대로**(회차 112 가 그 자리의 여유/sd 를 11.4·7.6 로 쟀다)
		uint32 pass1 = 0u, pass2 = 0u;
		double mean1 = 0.0, mean2 = 0.0;
		for (uint32 s = 0; s < kSeeds; ++s)
		{
			if (sm[0][s] >= (double)kThr[0]) ++pass1;
			if (sm[1][s] >= (double)kThr[1]) ++pass2;
			mean1 += sm[0][s]; mean2 += sm[1][s];
		}
		mean1 /= (double)kSeeds; mean2 /= (double)kSeeds;
		LogA("[mlt] 📊   ⭐ **① 폭비**(회차 104 표제① 정본화) — 씨앗 평균 **%.4f** · `≥%.2f` 인 씨앗 **%u/%u** → %s\n",
			mean1, (double)kThr[0], pass1, kSeeds, (pass1 == kSeeds) ? "✅" : "⛔");
		LogA("[mlt] 📊   ⭐ **② 상관**(회차 104 표제② 정본화) — 씨앗 평균 **%+.4f** · `≥%.2f` 인 씨앗 **%u/%u** → %s\n",
			mean2, (double)kThr[1], pass2, kSeeds, (pass2 == kSeeds) ? "✅" : "⛔");
		// ⭐ ③ ㉣ — **모은 평균 ± SE**(씨앗이 단위)
		double m3 = 0.0;
		for (uint32 s = 0; s < kSeeds; ++s) m3 += sm[2][s];
		m3 /= (double)kSeeds;
		double v3 = 0.0;
		for (uint32 s = 0; s < kSeeds; ++s) { const double d = sm[2][s] - m3; v3 += d * d; }
		const double sd3 = Sqrt((float)(v3 / (double)(kSeeds - 1u)));
		const double se3 = sd3 / Sqrt((float)kSeeds);
		const double t3 = (se3 > 1.0e-12) ? (Abs(m3) / se3) : 0.0;
		uint32 pos3 = 0u;
		for (uint32 s = 0; s < kSeeds; ++s) if (sm[2][s] > 0.0) ++pos3;
		LogA("[mlt] 📊   ⭐ **③ ㉣**(Δ끊음(지속)−(비지속)) — 씨앗별 바깥평균:\n");
		for (uint32 s = 0; s < kSeeds; ++s)
			LogA("[mlt] 📊       씨앗 %2u  %+.5f\n", s, sm[2][s]);
		LogA("[mlt] 📊     ⇒ **모은 평균 m̄ = %+.5f** · sd_씨앗 %.5f · **SE %.5f** ⇒ ⭐ **|m̄|/SE = %.2f**(필요 3) → %s\n",
			m3, sd3, se3, t3, (t3 >= 3.0) ? "✅ 잰다" : "⛔ 판정불가");
		LogA("[mlt] 📊     (참고) 부호가 **양수**인 씨앗 %u/%u — ⚠️ 회차 106 은 **음수**를 주장했다\n", pos3, kSeeds);
		// ④⑤ 보고
		for (uint32 i = 3; i < kStats; ++i)
		{
			double m = 0.0;
			for (uint32 s = 0; s < kSeeds; ++s) m += sm[i][s];
			m /= (double)kSeeds;
			LogA("[mlt] 📊   %s — 씨앗 평균 %+.5f (⚠️ 문턱 없는 보고값)\n", _StatName(i), m);
		}
		// ⭐ 판정
		if (!plumb)
			LogA("[mlt] 📊   ⭐ 판정 = ⛔ **판정불가** — 배관이 안 섰다\n");
		else
		{
			LogA("[mlt] 📊   ⭐ 판정 ①② = %s — %s\n",
				(pass1 == kSeeds && pass2 == kSeeds) ? "✅✅ **회차 104 가 정본이 된다**" : "⛔",
				(pass1 == kSeeds && pass2 == kSeeds)
					? "***몸통은 행동 슬롯을 「선택적으로」 읽는다***(12씨앗 · 바깥반복 2)"
					: "회차 104 를 12씨앗에서 못 굳혔다");
			if (t3 < 3.0)
				LogA("[mlt] 📊   ⭐ 판정 ③ = ⛔ **판정불가**(|m̄|/SE = %.2f < 3) — ⚠️ 회차 106 의 물음은 **여전히 못 잰다**\n", t3);
			else if (m3 < 0.0)
				LogA("[mlt] 📊   ⭐ 판정 ③ = ⭐ ***바뀌는 표적에서 행동을 읽는다*** — 회차 106 의 주장이 **제대로 된 자로 선다**\n");
			else
				LogA("[mlt] 📊   ⭐ 판정 ③ = ⭐ ***반대다*** — **지속하는 표적에서 행동을 더 읽는다** ⇒ 회차 106 의 그림을 **뒤집는다**\n");
		}
		LogA("[mlt] 📊   📏 잡음 바닥(회차 112 실측) — sd_run ① 0.0074 · ② 0.0544 · ③ 0.0307 (바깥반복 %u ⇒ 씨앗평균의 실행잡음 %.4f)\n",
			kOut, 0.0307 / Sqrt((float)kOut));
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		_E.Destroy(); _done = true;
	}

	static void _Fail(const char* why)
	{
		LogA("[mlt] 📏 ⛔ %s (씨앗 %u · 바깥 %u · 팔 %u · 반복 %u · 단계 %u)\n", why, _seed, _out, _arm, _rep, _st);
		_E.Destroy(); _done = true;
	}
};
