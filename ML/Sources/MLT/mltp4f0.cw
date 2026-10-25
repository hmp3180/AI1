// mltp4f0.cw — 📏 회차 112 · **`sd_run` 자를 세운다** (`-mltp4f0`) ⭐ **판정이 아니라 자다**
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

class MLTP4F0
{
public:
	static void Tick(RHI* rhi)
	{
		if (_done || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltp4f0"))
		{
			LogA("[mlt] 📏 회차 112(`sd_run` 자)는 **꺼져 있다**(`-mltp4f0`)\n");
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
	// ⭐ 씨앗 셋 × 바깥 반복 다섯 — ⚠️ 판정 회차가 아니라 **자**라서 12씨앗이 필요 없다.
	static constexpr uint32 kSeeds = 3u, kOut = 5u;
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
		LogA("[mlt] 📏 **회차 112 · `sd_run` 자를 세운다** — ⭐ **판정이 아니라 자다**(사람이 고른 길 ㈁)\n");
		LogA("[mlt] 📏   ⚠️ 회차 108~111 — **몸통 학습이 비결정적**(파라미터 830,848/859,136 갈림 · 간헐적) · 범인 미검거\n");
		LogA("[mlt] 📏   ⇒ ⭐ **잡음 바닥에 「실행」 항을 넣는다**(규율 29) — 그것이 과학을 되살리는 가장 빠른 길\n");
		LogA("[mlt] 📏   🔬 씨앗 %u × **바깥 반복 %u** — ⭐ gather 는 **씨앗당 한 번**(코퍼스가 결정적임이 증명됐다)\n",
			kSeeds, kOut);
		LogA("[mlt] 📏     ⇒ 바깥 반복 하나 = **몸통만**(회차 106 의 5팔 × %u반복을 처음부터 다시)\n", kRep);
		LogA("[mlt] 📏   📐 통계 다섯 — ① 폭비(104 표제①) ② 상관(104 표제②) ③ **㉣**(106 표제) ④ 평균Δ끊음(103) ⑤ CE\n");
		LogA("[mlt] 📏   ⭐ **판정 규칙을 미리 못박았다** — `여유/sd_run` ≥3 ✅ 그대로 / 1~3 ⚠️ `R_out` 필요 / <1 ⛔ 못 잰다\n");
		LogA("[mlt] 📏   ⭐ **예측** — ①② **≥3 산다** · ③ ㉣ **⛔ <1 로 죽는다**(105↔106 짝비교가 이미 sd≈0.035 > 효과 0.026)\n");
		LogA("[mlt] 📏     ⚠️ 회차 109·111 에서 내 예측이 **연달아 틀렸다**\n");
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
		LogA("[mlt] 📏 **회차 112 · `sd_run` 자 결과**(씨앗 %u × 바깥 반복 %u · 문맥 %u)\n", kSeeds, kOut, kNCtx);
		bool plumb = _finite && (Abs(_floorTe[0] - kFloorRef) <= 0.0001f);
		uint32 flatBad = 0u;
		for (uint32 s = 0; s < kSeeds; ++s) for (uint32 o = 0; o < kOut; ++o) if (!_flat[s][o]) ++flatBad;
		if (flatBad != 0u) plumb = false;
		LogA("[mlt] 📏   배관 — 씨앗0 복사바닥 **%.4f**(눈금 %.4f) · `lr=0` 안 평탄 %u회 · 유한 %s → %s\n",
			(double)_floorTe[0], (double)kFloorRef, flatBad, _finite ? "✅" : "⛔", plumb ? "통과" : "⛔");
		// ⭐ 통계마다: 씨앗별 sd → 씨앗 평균 sd_run · 그리고 여유/sd_run
		for (uint32 i = 0; i < kStats; ++i)
		{
			double sdSum = 0.0, mnSum = 0.0;
			LogA("[mlt] 📏   %s\n", _StatName(i));
			for (uint32 s = 0; s < kSeeds; ++s)
			{
				double m = 0.0;
				for (uint32 o = 0; o < kOut; ++o) m += (double)_S[s][o][i];
				m /= (double)kOut;
				double v = 0.0;
				for (uint32 o = 0; o < kOut; ++o)
				{ const double d = (double)_S[s][o][i] - m; v += d * d; }
				const double sd = Sqrt((float)(v / (double)(kOut - 1u)));
				double lo = 1.0e30, hi = -1.0e30;
				for (uint32 o = 0; o < kOut; ++o)
				{ if ((double)_S[s][o][i] < lo) lo = _S[s][o][i]; if ((double)_S[s][o][i] > hi) hi = _S[s][o][i]; }
				LogA("[mlt] 📏     씨앗 %u — 평균 %+.5f · **sd_run %.5f** · 폭 %+.5f ~ %+.5f\n",
					s, m, sd, lo, hi);
				sdSum += sd; mnSum += m;
			}
			const double sdRun = sdSum / (double)kSeeds;
			const double mean  = mnSum / (double)kSeeds;
			if (!kHasThr[i])
			{
				LogA("[mlt] 📏     ⇒ **sd_run %.5f**(씨앗 평균) · 평균 %+.5f — ⚠️ 문턱 없는 보고값\n", sdRun, mean);
				continue;
			}
			const double margin = Abs((double)kRep0[i] - (double)kThr[i]);
			const double ratio = (sdRun > 1.0e-12) ? (margin / sdRun) : 1.0e9;
			const char* verdict = (ratio >= 3.0) ? "✅ **그대로 쓴다**"
				: (ratio >= 1.0) ? "⚠️ **`R_out` 을 넣어야 쓴다**" : "⛔ **그 자로는 못 잰다**";
			LogA("[mlt] 📏     ⇒ **sd_run %.5f** · 보고값 %+.4f · 문턱 %+.2f · 여유 %.4f ⇒ ⭐ **여유/sd_run = %.2f** → %s\n",
				sdRun, (double)kRep0[i], (double)kThr[i], margin, ratio, verdict);
			if (ratio >= 1.0 && ratio < 3.0)
			{
				const double needed = (3.0 / ratio) * (3.0 / ratio);
				LogA("[mlt] 📏       ⇒ `여유/sd ≥ 3` 을 만들려면 **바깥 반복 R_out ≥ %.0f**\n", needed);
			}
		}
		LogA("[mlt] 📏   ⚠️ 이것은 **자**다 — 어떤 가설도 판정하지 않았다. 이 `sd_run` 을 앞으로 **모든 등록문의 잡음 바닥에** 적는다(규율 29)\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		_E.Destroy(); _done = true;
	}

	static void _Fail(const char* why)
	{
		LogA("[mlt] 📏 ⛔ %s (씨앗 %u · 바깥 %u · 팔 %u · 반복 %u · 단계 %u)\n", why, _seed, _out, _arm, _rep, _st);
		_E.Destroy(); _done = true;
	}
};
