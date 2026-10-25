// mltp3d2.cw — 🐛 회차 56 · **모순을 푼다: 파라미터와 CE 를 같은 반복에서** (`-mltp3d2`)
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 56 이다.**
// ⚠️⚠️ **이 캔버스(몸통 GPU 경로의 재현성)의 세 번째 회차다.** 연속은 아니지만 세 번째는 세 번째다
//   — 회차 42 의 선례(*"회차 19~41 이 같은 상위 캔버스였는데 중단 규칙을 **뒤늦게** 발동"*)가
//   정확히 이 자리다. ⇒ **결과와 무관하게 이 회차가 그 캔버스를 닫는다. 넷째는 없다.**
// ══════════════════════════════════════════════════════════════════════════════
//
// ── 모순 ──────────────────────────────────────────────────────────────────
//   회차 54  800스텝 뒤 **파라미터 858,368개 비트 동일**(반복 **2**회)
//   회차 53  800스텝 뒤 **CE 폭 0.077**(반복 **8**회 · 리드백 게이트를 넣은 뒤에도)
//   ⇒ 파라미터가 같으면 평가도 같아야 한다. **한 반복에서 둘을 같이 읽으면 그 자리에서 갈린다.**
//
// ⚠️ **읽는 순서를 고정한다: 파라미터 먼저, CE 나중** — 그래야 두 값이 같은 상태를 본다.
//   ⭐ 그리고 그 순서 자체가 갈래 하나를 만든다: 3.4MB 리드백이 **큐를 비우면** CE 도 결정적이 된다.

using namespace PE;

class MLTP3D2
{
public:
	static void Tick(RHI* rhi)
	{
		if (_done || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltp3d2"))
		{
			LogA("[mlt] 🐛 회차 56은 **꺼져 있다**(`-mltp3d2`) — 파라미터↔CE 모순 풀기\n");
			_done = true; return;
		}
		if (!_banner) { _Banner(); _banner = true; }
		if (_st == kEncInit)  { _EncBegin(rhi); return; }
		if (_st == kEncTrain) { _EncTrain(); return; }
		if (_st == kGather)   { _Gather(); return; }
		if (_st == kRunInit)  { _RunBegin(rhi); return; }
		if (_st == kRunTrain) { _RunTrain(); return; }
		if (_st == kRunEval)  { _RunEval(); return; }
		_Summary();
	}

	static bool Done() { return _done; }

private:
	static constexpr uint32 kSeed = 0u;
	static constexpr uint32 kEncF = 32u, kEncSteps = 1200u, kEncPerTick = 8u;
	static constexpr uint32 kN = 250u, kLocal = 8u;
	static constexpr uint32 kTime = MLTP3Ctx::kTime;
	static constexpr uint32 kBatch = MLTP3Ctx::kBatch;
	static constexpr uint32 kCandidates = MLTP2Cfg::kPatches * kLocal;
	static constexpr uint32 kNCtx = 512u, kTestCtx = 64u;
	static constexpr uint32 kTrainEpi = 1u, kTestEpi = 101u;
	static constexpr uint32 kPoolSteps = kNCtx / kBatch, kTestPool = kTestCtx / kBatch;
	static constexpr uint32 kGroup = kEncF / kTime;
	static constexpr uint32 kSteps = 800u, kPerTick = 4u;
	static constexpr uint32 kRep = 8u;

	enum { kEncInit, kEncTrain, kGather, kRunInit, kRunTrain, kRunEval, kDone2 };

	inline static MLTP2Enc _E;
	inline static MLTModel _M;
	inline static MLTP3Ctx _tr, _te;
	inline static MLTEvalGate _gate;
	inline static bool _done = false, _banner = false, _pending = false;
	inline static uint32 _st = kEncInit, _step = 0u, _gGrp = 0u, _gIdx = 0u, _cor = 0u, _rep = 0u;
	inline static Array<float> _code, _norm, _p0;
	inline static uint32 _pDiff[kRep];
	inline static float _ce[kRep];

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🐛 **회차 56 · 파라미터↔CE 모순 풀기**(⚠️ 이 캔버스의 **세 번째** — 여기서 닫는다)\n");
		LogA("[mlt] 🐛   씨앗 %u · %u문맥 · %u스텝 · **%u회 반복** · 반복마다 파라미터 먼저, CE 나중\n",
			kSeed, kNCtx, kSteps, kRep);
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

	static void _EncBegin(RHI* rhi)
	{
		if (!_E.Setup(rhi, kEncF, kN)) { _Fail("인코더 준비"); return; }
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
		// ⭐ 회차 55 가 표준으로 정한 **id 정렬** 배치를 쓴다.
		_tr.SetSortById(true); _te.SetSortById(true);
		_tr.Begin(kNCtx, kN); _te.Begin(kTestCtx, kN);
		_cor = 0u; _gGrp = 0u; _gIdx = 0u; _pending = false; _st = kGather;
	}

	static void _Gather()
	{
		MLTP3Ctx& C = (_cor == 0u) ? _tr : _te;
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
					w.Step();
					if (!w.Render(bmp) || !MLTWorld::Pack(bmp, nullptr, packed)) { _Fail("Render/Pack(문맥)"); return; }
					MLTP2Enc::AppendFrame(fr, tg, (const uint8*)packed.GetData());
					C.StoreState(ctx, t, w.State());
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
			if (++_cor >= 2u) { _rep = 0u; _st = kRunInit; }
		}
	}

	static void _RunBegin(RHI* rhi)
	{
		if (!_M.Setup(rhi, MLTP3Ctx::kStateAx + kN, kN, MLTP3Ctx::kAxes, kTime)) { _Fail("몸통 준비"); return; }
		if (!_M.UploadPool(_tr.Val(), _tr.Tgt(), kPoolSteps) || !_M.UploadSymbolPool(_tr.Sym(), kPoolSteps))
		{ _Fail("학습 풀 업로드"); return; }
		_step = 0u; _st = kRunTrain;
	}

	static void _RunTrain()
	{
		if (_step >= kSteps)
		{
			// ⚠️ **파라미터 먼저** — 두 값이 같은 상태를 봐야 한다.
			Array<float> p;
			MLTensor t; t.offset = 0u; t.rows = 1u; t.cols = _M.ParamTotal();
			Bytes b;
			if (!_M.Arena().Read(t, b) || b.GetSize() < (uint64)t.cols * sizeof(float))
			{ _Fail("파라미터 리드백"); return; }
			const float* q = (const float*)b.GetData();
			if (_rep == 0u)
			{
				_p0.Reset(0);
				for (uint32 i = 0; i < t.cols; ++i) _p0.Add(q[i]);
				_pDiff[0] = 0u;
			}
			else
			{
				uint32 d = 0u;
				for (uint32 i = 0; i < t.cols; ++i) if (!(q[i] == _p0[i])) ++d;
				_pDiff[_rep] = d;
			}
			// 그 다음 CE — 시험 코퍼스로 갈아끼운다.
			if (!_M.UploadPool(_te.Val(), _te.Tgt(), kTestPool) || !_M.UploadSymbolPool(_te.Sym(), kTestPool))
			{ _Fail("시험 풀 업로드"); return; }
			_gate.Begin(kTestPool); _st = kRunEval; return;
		}
		for (uint32 i = 0; i < kPerTick && _step < kSteps; ++i)
		{
			_M.SelectStep(_step % kPoolSteps);
			if (!_M.Forward() || !_M.Backward() || !_M.AdamStep(1.0f)) { _Fail("몸통 스텝"); return; }
			++_step;
		}
	}

	static void _RunEval()
	{
		bool fail = false;
		if (!_gate.Step(_M, fail)) return;
		if (fail) { _Fail("평가 게이트"); return; }
		_ce[_rep] = _gate.Mean();
		LogA("[mlt] 🐛   반복 %u — 파라미터 어긋남 **%u** · 시험 CE **%.6f**\n",
			_rep, _pDiff[_rep], (double)_ce[_rep]);
		if (++_rep >= kRep) { _st = kDone2; return; }
		_st = kRunInit;
	}

	static void _Summary()
	{
		uint32 pd = 0u;
		for (uint32 r = 1; r < kRep; ++r) pd += _pDiff[r];
		float lo = _ce[0], hi = _ce[0];
		for (uint32 r = 0; r < kRep; ++r) { if (_ce[r] < lo) lo = _ce[r]; if (_ce[r] > hi) hi = _ce[r]; }
		const float w = hi - lo;
		const bool aOk = (pd == 0u), bOk = (w == 0.0f);

		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🐛 **회차 56 · 모순 풀기 결과** — %u회 반복 · %u스텝\n", kRep, kSteps);
		LogA("[mlt] 🐛   **A 파라미터** — 반복 0 대비 어긋남 합계 **%u**(파라미터 %u개) → %s\n",
			pd, _M.ParamTotal(), aOk ? "**비트 동일**" : "⛔ 갈린다");
		LogA("[mlt] 🐛   **B 시험 CE** — 최소 %.6f · 최대 %.6f · **폭 %.6f** → %s\n",
			(double)lo, (double)hi, (double)w, bOk ? "**완전 동일**" : "⚠️ 흔들린다");
		if (!aOk)
			LogA("[mlt] 🐛   ⭐ 판정 = **범인은 학습 경로다**(회차 54 의 2회가 운이 좋았다) ⇒ 더 파지 않는다.\n"
			     "[mlt] 🐛      ㉠ 은 **반복 평균**으로 우회한다(표준오차 = 폭/√R) — 그 설계를 ㉠ 등록문에 넣는다\n");
		else if (!bOk)
			LogA("[mlt] 🐛   ⭐ 판정 = **범인은 평가 경로다**(파라미터는 같다) ⇒ ⭐ **평가를 CPU 로 옮기면 끝난다**\n"
			     "[mlt] 🐛      (로짓/확률을 읽어 CE 를 CPU 에서) — 그것은 **배관**이고 회차가 아니다\n");
		else
			LogA("[mlt] 🐛   ⭐ 판정 = ⭐ **폭이 사라졌다** — 회차 53 재실행(0.077)과의 차이는 **평가 직전에\n"
			     "[mlt] 🐛      파라미터를 읽은 것**(3.4MB 리드백이 **큐를 비운다**)뿐이다 ⇒ **그 비움이 곧 고침**이다\n");
		LogA("[mlt] 🐛   ⚠️ 이 캔버스는 **여기서 닫는다**(세 번째다) — 다음은 **앵커**(미룬 관문 둘째)\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		_E.Destroy(); _done = true;
	}

	static void _Fail(const char* why)
	{
		LogA("[mlt] 🐛 ⛔ %s (단계 %u · 반복 %u)\n", why, _st, _rep);
		_E.Destroy(); _done = true;
	}
};
