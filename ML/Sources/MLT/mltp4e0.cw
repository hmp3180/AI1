// mltp4e0.cw — 🐛 회차 108 · **비결정성이 사는 곳을 이등분한다** (`-mltp4e0`) ⚠️ **진단 회차**
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 108 이다.** ⭐ **하네스보다 먼저 썼다.**
//
// ── ⚠️⚠️ 이것은 새 발견이 아니라 **등록해 둔 부채**다 ────────────────────────
//   회차 53 : 800스텝 뒤 CE 폭 **0.077**(반복 8회) · ⭐ **1·100스텝은 폭 0**
//   회차 54 : 800스텝 뒤 파라미터 858,368개 **비트 동일** — ⚠️ 반복 **2회**뿐
//   배관     : `MLTEvalGate`(kDelay=3) 넣고 회차 53 재실행 ⇒ ⛔ **폭이 안 사라졌다**(0.077 → 0.084)
//   부채     : ⚠️ *"㉠(효과 0.009~0.022 · **잡음보다 작다**)을 재기 **전에** 반드시 푼다"*
//   ⇒ ⚠️⚠️ ***그 부채를 안 갚은 채 회차 103~107 이 `Δ끊음 ≈ 0.006`(더 작은 효과)을 쟀다.***
//
// ── ⭐ 오늘 범인 후보가 **반으로 줄었다** — 복사바닥이 공짜로 했다 ────────
//   `_floorTe[seed]` 는 ***코퍼스만으로*** 계산된다(학습을 한 번도 안 본다). 세 실행
//   (회차 106 · 107 · 106 재실행)에서 **12씨앗 전부 소수점까지 같다**
//   ⇒ ⭐ **인코더·`ReadAct`·`StoreAct`·세계·코퍼스는 전부 결정적** ⇒ **범인은 몸통 경로**.
//   ⚠️ 그리고 회차 54 가 *"`Arena().Read` 는 스테이징이라 큐를 비운다"* 고 적은 것은 **틀렸다** —
//     `ReadAct`·`ReadLoss`·파라미터 읽기가 **전부 같은 `_ar.Read`**(→ `RHI::ReadbackBuffer`)다.
//
// ── 🔬 무엇을 하나 — **씨앗 하나**로 학습과 평가를 가른다 ────────────────────
//   코퍼스를 **한 번** 만들고(결정적임이 증명됐다) 그 위에서 둘을 잰다:
//   | **㈀ 학습 반복** `R=8`  | 매번 `Setup → 800스텝` → **파라미터 비트 비교** + 평가 1회 |
//   | **㈁ 평가만 반복** `R'=8` | ⭐ **파라미터를 그대로 두고** 평가 루프만 다시 8회 |
//   ★ 둘 다 **행별 손실**(`ReadLossRows`)까지 비교한다 — ⚠️ 회차 103~107 이 **실제로 쓰는 양**이다.
//
// ── ✅ 관문 — 결과의 뜻을 미리 못박았다 ───────────────────────────────────
//   | ㈀ 파라미터 ≠ 0 |            | ⭐ **학습 경로** — 회차 54 의 `R=2` 가 운이었다 |
//   | ㈀ = 0 | ㈁ 폭 ≠ 0          | ⭐ **평가 경로** — `kDelay` 로 안 고쳐진 그 자리 |
//   | ㈀ = 0 | ㈁ = 0             | ⚠️ 둘 다 결정적인데 회차끼리 다르다 ⇒ 범인은 **실행 사이**에만 산다 |
//   **배관 관문**: 복사바닥이 **1.1162**(씨앗 0)와 같아야 한다 — 다르면 이등분이 무효다.
//
// ── ⭐ 예측을 미리 적었다 ────────────────────────────────────────────────
//   · 배관(바닥 1.1162) — 확신 · **㈀ 갈릴 것**(회차 53 이 *"800에서 생긴다"* 를 봤다 ⇒ **누적**된다)
//   · **㈁ 안 갈릴 것**(같은 파라미터·같은 입력·같은 커널) ⇒ 종합 예측 = ***학습 경로***
//   ⚠️ **회차 106·107 에서 내 예측이 각각 틀렸다는 것을 기억한다.**

using namespace PE;

class MLTP4E0
{
public:
	static void Tick(RHI* rhi)
	{
		if (_done || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltp4e0"))
		{
			LogA("[mlt] 🐛 회차 108(비결정성 이등분)은 **꺼져 있다**(`-mltp4e0`)\n");
			_done = true; return;
		}
		if (!_banner) { _Banner(); _banner = true; }
		if (_st == kEncInit)  { _EncBegin(rhi); return; }
		if (_st == kEncTrain) { _EncTrain(); return; }
		if (_st == kGather)   { _Gather(); return; }
		if (_st == kQuiesce)
		{
			if (_qWait > 0u) { --_qWait; return; }
			_st = _next; return;
		}
		if (_st == kTrainInit) { _TrainBegin(rhi); return; }
		if (_st == kTrain)     { _Train(); return; }
		if (_st == kEval)      { _Eval(); return; }
		_Summary();
	}

	static bool Done() { return _done; }

private:
	static constexpr uint32 kSeed = 0u;
	static constexpr uint32 kEncF = 32u, kEncSteps = 1200u, kEncPerTick = 8u;
	static constexpr uint32 kN = 250u, kLocal = 8u;
	static constexpr uint32 kTime = MLTP4Ctx::kTime;
	static constexpr uint32 kBatch = MLTP4Ctx::kBatch;
	static constexpr uint32 kCandidates = MLTP2Cfg::kPatches * kLocal;
	// ⚠️ 회차 103~107 과 **한 글자도 다르지 않은** 배치여야 진단이 그쪽에 옮겨진다.
	static constexpr uint32 kNCtx = 512u, kTestCtx = 512u;
	static constexpr uint32 kTrainEpi = 1u, kTestEpi = 901u;
	static_assert(kTestEpi >= kTrainEpi + kNCtx, "시험 에피소드가 학습과 겹친다(회차 81)");
	static constexpr uint32 kPoolSteps = kNCtx / kBatch, kTestPool = kTestCtx / kBatch;
	static constexpr uint32 kGroup = kEncF / kTime;
	static constexpr uint32 kSteps = 800u, kPerTick = 4u;
	static constexpr uint32 kNone = MLTP4Ctx::kStateAx + MLTP4Ctx::kActAx + kN;
	static constexpr uint32 kSymVocab = kNone + 1u;
	// ⭐ 반복 수 — 회차 54 는 `R=2` 였다. 그것이 이 회차가 늘리는 유일한 손잡이다.
	static constexpr uint32 kRepA = 8u, kRepB = 8u;
	// ⚠️ 배관 눈금 — 회차 106·107 이 찍은 씨앗 0 의 시험 복사바닥
	static constexpr float  kFloorRef = 1.1162f;

	enum { kEncInit, kEncTrain, kGather, kQuiesce, kTrainInit, kTrain, kEval, kEnd };

	inline static MLTP2Enc _E;
	inline static MLTModel _M;
	inline static MLTP4Ctx _tr, _te;
	inline static bool _done = false, _banner = false, _encSetup = false;
	inline static uint32 _st = kEncInit, _next = kTrainInit, _qWait = 0u;
	inline static uint32 _step = 0u, _cor = 0u, _gGrp = 0u, _gIdx = 0u;
	inline static bool _pending = false;
	inline static Array<float> _code, _norm;
	inline static float _floorTe = 0.0f;

	// ⭐ 팔 — 0..kRepA-1 = ㈀ 학습 반복 · kRepA.. = ㈁ 평가만 반복
	inline static uint32 _rep = 0u;
	inline static bool   _phaseB = false;
	inline static Array<float> _p0, _rows0;
	inline static float  _ce[kRepA + kRepB];
	inline static uint32 _dParam[kRepA];      // 파라미터 어긋난 칸 수
	inline static uint32 _dRows[kRepA + kRepB];  // 행별 손실 어긋난 칸 수
	inline static float  _mxRow[kRepA + kRepB];  // 행별 손실 최대 절대차

	// 평가 루프
	inline static uint32 _ei = 0u, _ewait = 0u;
	inline static bool   _epend = false;
	inline static double _esum = 0.0;
	inline static Array<float> _rowsCur;

	static void _To(uint32 next) { _qWait = MLTEvalGate::kDelay; _next = next; _st = kQuiesce; }

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🐛 **회차 108 · 비결정성이 사는 곳을 이등분한다**(⚠️ 진단 회차 · 씨앗 %u 하나)\n", kSeed);
		LogA("[mlt] 🐛   ⚠️⚠️ 새 발견이 아니라 **회차 53·54 가 등록해 둔 부채**다:\n");
		LogA("[mlt] 🐛     회차 53 — 800스텝 CE 폭 **0.077**(1·100스텝은 **0**) · 회차 54 — 파라미터 비트 동일(⚠️ **R=2**뿐)\n");
		LogA("[mlt] 🐛     배관 — `kDelay=3` 넣었는데 **폭이 안 사라졌다**(0.077→0.084) ⇒ 리드백 가설 **미확인**\n");
		LogA("[mlt] 🐛     부채 — *\"작은 효과(0.009~0.022)를 재기 **전에** 반드시 푼다\"* ⚠️ 회차 103~107 이 **0.006** 을 쟀다\n");
		LogA("[mlt] 🐛   ⭐ 오늘 범인이 **반으로 줄었다** — 복사바닥(코퍼스만의 함수)이 세 실행에서 **12씨앗 전부 동일**\n");
		LogA("[mlt] 🐛     ⇒ 인코더·`ReadAct`·`StoreAct`·세계·코퍼스는 **전부 결정적** ⇒ **범인은 몸통 경로**\n");
		LogA("[mlt] 🐛   🔬 **㈀ 학습 반복 R=%u** — 매번 `Setup→%u스텝` → 파라미터 **비트 비교** + 평가\n", kRepA, kSteps);
		LogA("[mlt] 🐛   🔬 **㈁ 평가만 반복 R'=%u** — ⭐ **파라미터를 그대로 두고** 평가 루프만 다시\n", kRepB);
		LogA("[mlt] 🐛     ⇒ ⭐ ***파라미터가 안 변하는데 갈리면 「읽는 길」이고, 안 갈리면 「학습」이다***\n");
		LogA("[mlt] 🐛   ★ 둘 다 **행별 손실**(`ReadLossRows`)까지 본다 — ⚠️ 회차 103~107 이 **실제로 쓰는 양**\n");
		LogA("[mlt] 🐛   ⚠️ 배관 관문 — 복사바닥이 **%.4f**(회차 106·107 의 씨앗 0)와 같아야 한다\n", (double)kFloorRef);
		LogA("[mlt] 🐛   ⭐ **예측** — ㈀ **갈린다**(회차 53 이 *\"800에서 생긴다\"* 를 봤다 ⇒ 누적) · ㈁ **안 갈린다** ⇒ **학습 경로**\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

	static void _EncBegin(RHI* rhi)
	{
		if (!_encSetup)
		{
			if (!_E.Setup(rhi, kEncF, kN)) { _Fail("인코더 준비"); return; }
			_encSetup = true;
		}
		_E.SetK(kLocal); _E.SetSelectAbs(false);
		Array<float> fr, tg; fr.Reset(0); tg.Reset(0);
		ImageFormat::Bitmap bmp; Bytes packed;
		MLTWorld w; w.Reset(kSeed, 0u, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
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

	// ⚠️ 회차 103~107 의 `_BuildReal` 과 **한 글자도 다르지 않다**(세계 값 수집만 뺐다 — 안 쓴다).
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
				MLTWorld w; w.Reset(kSeed, epi + ctx, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
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
				_floorTe = (t1 < t2) ? t1 : t2;
				const bool ok = Abs(_floorTe - kFloorRef) <= 0.0001f;
				LogA("[mlt] 🐛 ⚠️ **배관 관문** — 시험 복사바닥 **%.4f**(눈금 %.4f) → %s\n",
					(double)_floorTe, (double)kFloorRef, ok ? "✅ 코퍼스 동일" : "⛔ 코퍼스가 다르다 — 이등분 무효");
				_rep = 0u; _phaseB = false; _To(kTrainInit);
			}
		}
	}

	static void _TrainBegin(RHI* rhi)
	{
		// ⚠️ ㈁ 는 `Setup` 을 **안 부른다** — 파라미터를 그대로 두는 것이 이 팔의 정의다.
		if (!_phaseB)
		{
			if (!_M.Setup(rhi, kSymVocab, kN, MLTP4Ctx::kAxes, kTime)) { _Fail("몸통 준비"); return; }
			if (!_M.UploadPool(_tr.Val(), _tr.Tgt(), kPoolSteps) || !_M.UploadSymbolPool(_tr.Sym(), kPoolSteps))
			{ _Fail("학습 풀 업로드"); return; }
			_step = 0u; _st = kTrain; return;
		}
		_SwitchToTest();
	}

	static bool _SwitchToTest()
	{
		if (!_M.UploadPool(_te.Val(), _te.Tgt(), kTestPool) || !_M.UploadSymbolPool(_te.Sym(), kTestPool))
		{ _Fail("시험 풀 업로드"); return false; }
		_ei = 0u; _epend = false; _ewait = 0u; _esum = 0.0;
		_rowsCur.Reset(0);
		for (uint32 i = 0; i < kTestPool * MLTP4Ctx::kRows; ++i) _rowsCur.Add(0.0f);
		_st = kEval;
		return true;
	}

	static void _Train()
	{
		if (_step >= kSteps)
		{
			// ⭐ ㈀ 의 핵심 — 파라미터 블록을 통째로 읽어 **비트 비교**한다.
			Array<float> p;
			if (!_ReadParams(p)) { _Fail("파라미터 리드백"); return; }
			if (_rep == 0u)
			{
				_p0.Reset(0);
				for (uint32 i = 0; i < p.Count(); ++i) _p0.Add(p[i]);
				_dParam[0] = 0u;
			}
			else
			{
				uint32 d = 0u;
				for (uint32 i = 0; i < p.Count(); ++i) if (!(p[i] == _p0[i])) ++d;
				_dParam[_rep] = d;
			}
			LogA("[mlt] 🐛   ㈀ 반복 %u — 파라미터 %u개 중 **어긋남 %u**%s\n",
				_rep, p.Count(), _dParam[_rep], (_dParam[_rep] == 0u) ? "  ⇒ 비트 동일" : "  ⚠️");
			_SwitchToTest();
			return;
		}
		for (uint32 i = 0; i < kPerTick && _step < kSteps; ++i)
		{
			_M.SelectStep(_step % kPoolSteps);
			if (!_M.Forward() || !_M.Backward() || !_M.AdamStep(1.0f)) { _Fail("몸통 스텝"); return; }
			++_step;
		}
	}

	static bool _ReadParams(Array<float>& out)
	{
		MLTensor t; t.offset = 0u; t.rows = 1u; t.cols = _M.ParamTotal();
		Bytes b;
		if (!_M.Arena().Read(t, b)) return false;
		if (b.GetSize() < (uint64)t.cols * sizeof(float)) return false;
		const float* p = (const float*)b.GetData();
		out.Reset(0);
		for (uint32 i = 0; i < t.cols; ++i) out.Add(p[i]);
		return true;
	}

	static void _Eval()
	{
		if (_epend)
		{
			if (_ewait > 0u) { --_ewait; return; }
			float ls = 0.0f;
			if (!_M.ReadLoss(ls)) { _Fail("평가 리드백"); return; }
			_esum += (double)ls;
			Array<float> rows;
			if (!_M.ReadLossRows(rows) || rows.Count() < MLTP4Ctx::kRows) { _Fail("행별 손실"); return; }
			const uint32 base = (_ei - 1u) * MLTP4Ctx::kRows;
			for (uint32 i = 0; i < MLTP4Ctx::kRows; ++i) _rowsCur.Data()[base + i] = rows[i];
			_epend = false;
		}
		if (_ei >= kTestPool)
		{
			const uint32 slot = _phaseB ? (kRepA + _rep) : _rep;
			_ce[slot] = (float)(_esum / (double)kTestPool);
			// ⭐ 행별 손실도 비트 비교 — ⚠️ 회차 103~107 이 실제로 쓰는 양이다.
			if (slot == 0u)
			{
				_rows0.Reset(0);
				for (uint32 i = 0; i < _rowsCur.Count(); ++i) _rows0.Add(_rowsCur[i]);
				_dRows[0] = 0u; _mxRow[0] = 0.0f;
			}
			else
			{
				uint32 d = 0u; float mx = 0.0f;
				for (uint32 i = 0; i < _rowsCur.Count(); ++i)
				{
					if (!(_rowsCur[i] == _rows0[i])) ++d;
					const float e = Abs(_rowsCur[i] - _rows0[i]);
					if (e > mx) mx = e;
				}
				_dRows[slot] = d; _mxRow[slot] = mx;
			}
			LogA("[mlt] 🐛   %s 반복 %u — CE **%.6f** · 행별 %u칸 중 **어긋남 %u** · 최대차 **%.3e**\n",
				_phaseB ? "㈁(평가만)" : "㈀(학습)  ", _rep, (double)_ce[slot],
				_rowsCur.Count(), _dRows[slot], (double)_mxRow[slot]);
			if (!_phaseB)
			{
				if (++_rep < kRepA) { _To(kTrainInit); return; }
				// ⭐ ㈁ 로 넘어간다 — ⚠️ `Setup` 을 안 부른다(파라미터를 그대로 둔다).
				_phaseB = true; _rep = 0u; _To(kTrainInit); return;
			}
			if (++_rep < kRepB) { _To(kTrainInit); return; }
			_st = kEnd; return;
		}
		_M.SelectStep(_ei);
		if (!_M.Forward()) { _Fail("평가 forward"); return; }
		++_ei; _epend = true; _ewait = MLTEvalGate::kDelay;
	}

	static void _Summary()
	{
		uint32 pDiff = 0u, rDiffA = 0u, rDiffB = 0u;
		float mxA = 0.0f, mxB = 0.0f;
		double loA = 1.0e30, hiA = -1.0e30, loB = 1.0e30, hiB = -1.0e30;
		for (uint32 r = 0; r < kRepA; ++r)
		{
			if (_dParam[r] != 0u) ++pDiff;
			if (_dRows[r] != 0u) ++rDiffA;
			if (_mxRow[r] > mxA) mxA = _mxRow[r];
			if ((double)_ce[r] < loA) loA = _ce[r];
			if ((double)_ce[r] > hiA) hiA = _ce[r];
		}
		for (uint32 r = 0; r < kRepB; ++r)
		{
			const uint32 s = kRepA + r;
			if (_dRows[s] != 0u) ++rDiffB;
			if (_mxRow[s] > mxB) mxB = _mxRow[s];
			if ((double)_ce[s] < loB) loB = _ce[s];
			if ((double)_ce[s] > hiB) hiB = _ce[s];
		}
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🐛 **회차 108 · 비결정성 이등분 결과**(씨앗 %u · %u스텝 · 문맥 %u)\n", kSeed, kSteps, kNCtx);
		LogA("[mlt] 🐛   배관 — 시험 복사바닥 **%.4f**(눈금 %.4f) → %s\n",
			(double)_floorTe, (double)kFloorRef,
			(Abs(_floorTe - kFloorRef) <= 0.0001f) ? "✅ 코퍼스 동일" : "⛔ 이등분 무효");
		LogA("[mlt] 🐛   **㈀ 학습 반복 %u회** — 파라미터가 첫 회와 **다른 반복 %u/%u** · CE 폭 **%.6f**(%.6f~%.6f)\n",
			kRepA, pDiff, kRepA - 1u, hiA - loA, loA, hiA);
		LogA("[mlt] 🐛     행별 손실이 다른 반복 **%u/%u** · 최대차 **%.3e**\n", rDiffA, kRepA - 1u, (double)mxA);
		LogA("[mlt] 🐛   **㈁ 평가만 반복 %u회**(파라미터 고정) — CE 폭 **%.6f**(%.6f~%.6f)\n",
			kRepB, hiB - loB, loB, hiB);
		LogA("[mlt] 🐛     행별 손실이 다른 반복 **%u/%u** · 최대차 **%.3e**\n", rDiffB, kRepB - 1u, (double)mxB);
		if (pDiff != 0u)
			LogA("[mlt] 🐛   ⭐ 판정 = ⭐ **학습 경로다** — 회차 54 의 `R=2` 가 운이었다 ⇒ 다음 = `Backward`/`AdamStep` 의 축약 순서\n");
		else if (rDiffB != 0u || (hiB - loB) > 0.0)
			LogA("[mlt] 🐛   ⭐ 판정 = ⭐ **평가 경로다** — 파라미터가 같은데 손실이 갈린다 ⇒ 다음 = **읽기 전 큐 비우기**(`kDelay` 로는 안 됐다)\n");
		else if (rDiffA != 0u)
			LogA("[mlt] 🐛   ⭐ 판정 = ⚠️ **파라미터는 같은데 학습 반복의 손실만 갈린다** ⇒ `UploadPool`/`SelectStep` 쪽을 본다\n");
		else
			LogA("[mlt] 🐛   ⭐ 판정 = ⚠️ **한 실행 안에서는 전부 결정적이다** ⇒ 범인은 **실행 사이**에만 산다\n"
			     "[mlt] 🐛      (후보: `Setup` 의 아레나 잔류 · 드라이버/파이프라인 캐시 상태) ⇒ 다음은 **앱을 두 번 띄워** 비교한다\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		_E.Destroy(); _done = true;
	}

	static void _Fail(const char* why)
	{
		LogA("[mlt] 🐛 ⛔ %s (단계 %u · 팔 %s · 반복 %u)\n", why, _st, _phaseB ? "㈁" : "㈀", _rep);
		_E.Destroy(); _done = true;
	}
};
