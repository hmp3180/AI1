// mltp4e2.cw — 🐛 회차 110 · **평가를 넷으로 쪼갠다** (`-mltp4e2`) ⚠️ **진단 회차**
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 110 이다.** ⭐ **하네스보다 먼저 썼다.**
//
// ── ⭐ 여기까지 좁혀진 것 ─────────────────────────────────────────────────
//   · 회차 108 — 코퍼스 결정적 · **평가 자체는 결백**(파라미터 고정 8회 CE 폭 **0.000000**)
//     그런데 `Setup → 800스텝 → 파라미터 → **평가** → 다음 Setup` 을 반복하면 **반복 2부터 갈린다**
//   · 회차 109 — 같은 씨앗·같은 `S=800` 인데 **평가를 안 끼우면** `S ∈ {0,1,10,100,400,800}` **전부 비트 동일**
//     ★ 그리고 `S=800` 전에 `Setup` 을 **20번** 했는데도 동일 ⇒ ⭐ **`Setup`·버퍼 파기/재생성은 무죄**
//   ⇒ ⭐ ***범인은 「반복 사이에 평가를 끼우는 것」이다.*** 이 회차가 그것을 **넷으로 쪼갠다.**
//
// ── 🔪 팔 넷 — `S=800` 고정 · 반복 `R=4` · **반복 사이에 무엇을 하나**만 다르다 ──
//   | ㈀ 없음      | 아무것도                              | ⚠️ **회차 109 재현**(동일해야 한다) |
//   | ㈁ 평가 온전 | 시험 풀 업로드 + forward 64 + 리드백   | ⚠️ **회차 108 재현**(갈려야 한다) |
//   | ⭐ ㈂ 업로드만 | 시험 풀 **업로드만**(forward 0)        | **버퍼 쓰기**가 범인인가 |
//   | ⭐ ㈃ forward만 | 학습 풀 그대로 **forward 64회**       | **디스패치**가 범인인가 |
//
// ── ✅ 관문 ───────────────────────────────────────────────────────────────
//   **배관** ㈀ 동일 **그리고** ㈁ 갈림 — ⚠️ 안 서면 **판정불가**(두 회차가 재현 안 된 것이다)
//   ㈂ 갈림·㈃ 동일 ⇒ ⭐ **버퍼 쓰기**(스테이징이 인플라이트 컴퓨트와 겹친다)
//   ㈃ 갈림·㈂ 동일 ⇒ ⭐ **디스패치**(평가 forward 가 학습 스크래치를 건드린다)
//   둘 다 갈림 ⇒ 공통 원인(큐 깊이·프레임 경계) · 둘 다 동일 ⇒ **리드백**만 남는다
//
// ── ⭐ 예측 ──────────────────────────────────────────────────────────────
//   **㈃(디스패치)** 를 유력하게 본다 — 평가 forward 가 `_tXs`·`_tLogit` 등 **학습과 같은 스크래치**를
//   쓰므로, 다음 학습이 그 칸을 **0 가정**으로 누산하면(`beta=1` 관용구) 잔류가 섞인다.
//   ⚠️ **회차 109 에서 내 예측이 틀렸다** — 이번에도 틀릴 수 있다.

using namespace PE;

class MLTP4E2
{
public:
	static void Tick(RHI* rhi)
	{
		if (_done || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltp4e2"))
		{
			LogA("[mlt] 🐛 회차 110(평가를 넷으로 쪼갠다)은 **꺼져 있다**(`-mltp4e2`)\n");
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
		if (_st == kRunInit) { _RunBegin(rhi); return; }
		if (_st == kRun)     { _Run(); return; }
		if (_st == kAfter)   { _After(); return; }
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
	static constexpr uint32 kNCtx = 512u, kTestCtx = 512u;
	static constexpr uint32 kTrainEpi = 1u, kTestEpi = 901u;
	static_assert(kTestEpi >= kTrainEpi + kNCtx, "시험 에피소드가 학습과 겹친다(회차 81)");
	static constexpr uint32 kPoolSteps = kNCtx / kBatch, kTestPool = kTestCtx / kBatch;
	static constexpr uint32 kGroup = kEncF / kTime;
	static constexpr uint32 kPerTick = 4u;
	static constexpr uint32 kNone = MLTP4Ctx::kStateAx + MLTP4Ctx::kActAx + kN;
	static constexpr uint32 kSymVocab = kNone + 1u;
	static constexpr float  kFloorRef = 1.1162f;
	static constexpr uint32 kSteps = 800u, kRep = 4u;
	static constexpr uint32 kArms = 4u;
	static constexpr uint32 kArmNone = 0u, kArmEval = 1u, kArmUp = 2u, kArmFwd = 3u;

	enum { kEncInit, kEncTrain, kGather, kQuiesce, kRunInit, kRun, kAfter, kEnd };

	inline static MLTP2Enc _E;
	inline static MLTModel _M;
	inline static MLTP4Ctx _tr, _te;
	inline static bool _done = false, _banner = false, _encSetup = false;
	inline static uint32 _st = kEncInit, _next = kRunInit, _qWait = 0u;
	inline static uint32 _step = 0u, _cor = 0u, _gGrp = 0u, _gIdx = 0u;
	inline static bool _pending = false;
	inline static Array<float> _code, _norm, _p0;
	inline static float _floorTe = 0.0f;
	inline static uint32 _arm = 0u, _rep = 0u;
	inline static uint32 _diff[kArms][kRep];
	inline static float  _mx[kArms][kRep];
	// 반복 뒤 「무엇을 하나」 루프
	inline static uint32 _ai = 0u, _await = 0u;
	inline static bool   _apend = false;

	static const char* _ArmName()
	{
		switch (_arm)
		{
		case kArmNone: return "㈀ 없음      ";
		case kArmEval: return "㈁ 평가 온전 ";
		case kArmUp:   return "㈂ 업로드만  ";
		default:       return "㈃ forward만 ";
		}
	}

	static void _To(uint32 next) { _qWait = MLTEvalGate::kDelay; _next = next; _st = kQuiesce; }

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🐛 **회차 110 · 평가를 넷으로 쪼갠다**(⚠️ 진단 · 씨앗 %u · S=%u · 반복 %u)\n", kSeed, kSteps, kRep);
		LogA("[mlt] 🐛   ⭐ 여기까지 — 회차 108: 평가를 끼우면 **반복 2부터 갈린다** / 회차 109: 안 끼우면 **전부 비트 동일**\n");
		LogA("[mlt] 🐛     ★ 회차 109 는 `S=800` 전에 `Setup` 을 **20번** 했는데도 동일 ⇒ ⭐ **Setup·버퍼 파기/재생성은 무죄**\n");
		LogA("[mlt] 🐛   🔪 팔 넷 — ㈀ 없음 · ㈁ 평가 온전 · ⭐ ㈂ **업로드만** · ⭐ ㈃ **forward 만**\n");
		LogA("[mlt] 🐛   ⚠️ **배관 관문** — ㈀ 가 동일하고 ㈁ 이 갈려야 한다(두 회차 재현). 안 서면 **판정불가**\n");
		LogA("[mlt] 🐛   ⭐ **예측** — **㈃(디스패치)** 를 유력하게 본다(평가 forward 가 학습과 **같은 스크래치**를 쓴다)\n");
		LogA("[mlt] 🐛     ⚠️ 회차 109 에서 내 예측이 틀렸다 — 이번에도 틀릴 수 있다\n");
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
				LogA("[mlt] 🐛 ⚠️ **배관 관문** — 시험 복사바닥 **%.4f**(눈금 %.4f) → %s\n",
					(double)_floorTe, (double)kFloorRef,
					(Abs(_floorTe - kFloorRef) <= 0.0001f) ? "✅ 코퍼스 동일" : "⛔ 코퍼스가 다르다");
				_arm = 0u; _rep = 0u; _To(kRunInit);
			}
		}
	}

	static void _RunBegin(RHI* rhi)
	{
		if (!_M.Setup(rhi, kSymVocab, kN, MLTP4Ctx::kAxes, kTime)) { _Fail("몸통 준비"); return; }
		if (!_M.UploadPool(_tr.Val(), _tr.Tgt(), kPoolSteps) || !_M.UploadSymbolPool(_tr.Sym(), kPoolSteps))
		{ _Fail("학습 풀 업로드"); return; }
		_step = 0u; _st = kRun;
	}

	static void _Run()
	{
		if (_step < kSteps)
		{
			for (uint32 i = 0; i < kPerTick && _step < kSteps; ++i)
			{
				_M.SelectStep(_step % kPoolSteps);
				if (!_M.Forward() || !_M.Backward() || !_M.AdamStep(1.0f)) { _Fail("몸통 스텝"); return; }
				++_step;
			}
			return;
		}
		Array<float> p;
		if (!_ReadParams(p)) { _Fail("파라미터 리드백"); return; }
		if (_rep == 0u)
		{
			_p0.Reset(0);
			for (uint32 i = 0; i < p.Count(); ++i) _p0.Add(p[i]);
			_diff[_arm][0] = 0u; _mx[_arm][0] = 0.0f;
		}
		else
		{
			uint32 d = 0u; float mx = 0.0f;
			for (uint32 i = 0; i < p.Count(); ++i)
			{
				if (!(p[i] == _p0[i])) ++d;
				const float e = Abs(p[i] - _p0[i]);
				if (e > mx) mx = e;
			}
			_diff[_arm][_rep] = d; _mx[_arm][_rep] = mx;
		}
		LogA("[mlt] 🐛   %s 반복 %u — 파라미터 %u개 중 **어긋남 %u** · 최대차 %.3e%s\n",
			_ArmName(), _rep, p.Count(), _diff[_arm][_rep], (double)_mx[_arm][_rep],
			(_diff[_arm][_rep] == 0u) ? "  ⇒ 비트 동일" : "  ⚠️");
		// ⭐ 이 팔이 「반복 사이에 하는 일」 — ㈀ 은 아무것도 안 한다.
		if (_arm == kArmNone) { _NextRep(); return; }
		if (_arm == kArmUp)
		{
			// ⭐ 업로드만 — forward 도 리드백도 없다.
			if (!_M.UploadPool(_te.Val(), _te.Tgt(), kTestPool) || !_M.UploadSymbolPool(_te.Sym(), kTestPool))
			{ _Fail("시험 풀 업로드"); return; }
			_NextRep(); return;
		}
		if (_arm == kArmEval)
		{
			if (!_M.UploadPool(_te.Val(), _te.Tgt(), kTestPool) || !_M.UploadSymbolPool(_te.Sym(), kTestPool))
			{ _Fail("시험 풀 업로드"); return; }
		}
		// ㈁·㈃ 는 forward 루프로 간다(㈃ 는 학습 풀 그대로 · 리드백 없음)
		_ai = 0u; _apend = false; _await = 0u; _st = kAfter;
	}

	// ⭐ 평가 forward 루프 — ㈁ 은 리드백까지, ㈃ 는 **디스패치만**.
	static void _After()
	{
		if (_apend)
		{
			if (_await > 0u) { --_await; return; }
			if (_arm == kArmEval)
			{
				float ls = 0.0f;
				if (!_M.ReadLoss(ls)) { _Fail("평가 리드백"); return; }
			}
			_apend = false;
		}
		if (_ai >= kTestPool) { _NextRep(); return; }
		_M.SelectStep(_ai);
		if (!_M.Forward()) { _Fail("평가 forward"); return; }
		++_ai;
		// ⚠️ ㈃ 는 리드백을 안 하므로 대기가 필요 없다 — 그래도 **틱은 넘긴다**(디스패치 리듬을 ㈁ 과 맞춘다).
		_apend = true; _await = (_arm == kArmEval) ? MLTEvalGate::kDelay : 0u;
	}

	static void _NextRep()
	{
		if (++_rep < kRep) { _To(kRunInit); return; }
		_rep = 0u;
		if (++_arm < kArms) { _To(kRunInit); return; }
		_st = kEnd;
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

	static void _Summary()
	{
		uint32 bad[kArms];
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🐛 **회차 110 · 평가를 넷으로 쪼갠 결과**(씨앗 %u · S=%u · 반복 %u)\n", kSeed, kSteps, kRep);
		LogA("[mlt] 🐛   배관 — 복사바닥 **%.4f**(눈금 %.4f) → %s\n",
			(double)_floorTe, (double)kFloorRef,
			(Abs(_floorTe - kFloorRef) <= 0.0001f) ? "✅" : "⛔");
		for (uint32 a = 0; a < kArms; ++a)
		{
			uint32 b = 0u; float mx = 0.0f;
			for (uint32 r = 1; r < kRep; ++r)
			{ if (_diff[a][r] != 0u) ++b; if (_mx[a][r] > mx) mx = _mx[a][r]; }
			bad[a] = b;
			const char* nm = (a == kArmNone) ? "㈀ 없음      " : (a == kArmEval) ? "㈁ 평가 온전 "
				: (a == kArmUp) ? "㈂ 업로드만  " : "㈃ forward만 ";
			LogA("[mlt] 🐛   %s — 첫 회와 다른 반복 **%u/%u** · 최대차 %.3e%s\n",
				nm, b, kRep - 1u, (double)mx, (b == 0u) ? "  ⇒ 비트 동일" : "  ⚠️");
		}
		const bool plumb = (bad[kArmNone] == 0u) && (bad[kArmEval] != 0u);
		LogA("[mlt] 🐛   ⚠️ **배관 관문** — ㈀ 동일(%s) **그리고** ㈁ 갈림(%s) → %s\n",
			(bad[kArmNone] == 0u) ? "✅" : "⛔", (bad[kArmEval] != 0u) ? "✅" : "⛔",
			plumb ? "통과" : "⛔ 판정불가");
		if (!plumb)
			LogA("[mlt] 🐛   ⭐ 판정 = ⛔ **판정불가** — 회차 108·109 가 재현되지 않았다\n");
		else if (bad[kArmUp] != 0u && bad[kArmFwd] == 0u)
			LogA("[mlt] 🐛   ⭐ 판정 = ⭐ **버퍼 쓰기다** — `UploadPool` 의 스테이징 쓰기가 **인플라이트 컴퓨트와 겹친다**\n");
		else if (bad[kArmFwd] != 0u && bad[kArmUp] == 0u)
			LogA("[mlt] 🐛   ⭐ 판정 = ⭐ **디스패치다** — 평가 forward 가 **학습이 쓰는 칸**을 건드린다(스크래치 공유)\n");
		else if (bad[kArmUp] != 0u && bad[kArmFwd] != 0u)
			LogA("[mlt] 🐛   ⭐ 판정 = ⭐ **둘 다 충분조건이다** ⇒ 공통 원인(큐 깊이·프레임 경계)을 다음에 본다\n");
		else
			LogA("[mlt] 🐛   ⭐ 판정 = ⚠️ **리드백만 남는다**(`ReadLoss`) — ㈂·㈃ 둘 다 동일한데 ㈁ 만 갈렸다\n");
		LogA("[mlt] 🐛   ⚠️ 씨앗 하나의 진단이다 — 성능/판정 숫자로 인용하지 않는다\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		_E.Destroy(); _done = true;
	}

	static void _Fail(const char* why)
	{
		LogA("[mlt] 🐛 ⛔ %s (단계 %u · 팔 %u · 반복 %u)\n", why, _st, _arm, _rep);
		_E.Destroy(); _done = true;
	}
};
