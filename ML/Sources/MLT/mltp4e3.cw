// mltp4e3.cw — 🐛 회차 123 · **B3: 비결정성의 범인을 끝낸다** (`-mltp4e3`) ⚠️ **진단 회차**
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 123 이다.** ⭐ **하네스보다 먼저 썼다.**
//   **상위 캔버스: `비결정성의 범인` · 123~ = 1회차**(규율 33) · ⭐ **부채 D4**.
//
// ── ⭐ 지금까지 좁혀진 것(회차 108~111 · 121) ────────────────────────────
//   무죄 — 세계 · 코퍼스 · 인코더 리드백 · **평가**(파라미터 고정 8회 CE 폭 **0.000000**) · `Setup`
//   범인 — **GPU 몸통 학습**(같은 씨앗·같은 800스텝에서 **830,848/859,136** 갈림 · **간헐적**)
//   ⛔ 안 통한 고침 — `RHI::WaitIdle`(계약은 옳아서 남겼다)
//   ⭐ 회차 121 — **CPU 프로브(`SolveSymPD`)는 결정적**(씨앗 2 에서 `sd_run` **비트 0**)
//
// ── ⭐ 이 회차의 물음 — **「간헐적」의 정체** ─────────────────────────
//   회차 110·111 이 남긴 가장 이상한 것: ***같은 팔 안에서도 갈리는 반복과 안 갈리는 반복이 섞인다.***
//   ⇒ ⭐ 경합이라면 **무엇과 무엇의 경합인지**를 가른다 — **축을 「큐 깊이」로** 잡았다:
//   | ㈀ **`S=0`**(양성 대조) | 학습 0스텝 ⇒ **비트 동일이어야** 한다 |
//   | ㈁ **그냥**            | 회차 109 가 **0/3**(안 갈림)을 본 자리 |
//   | ㈂ **빈 틱 32**        | ⭐ 큐를 **확실히** 비운다(디스패치 0) |
//   | ㈃ **forward 64**      | 회차 110 이 **갈림**을 본 자리(디스패치가 쌓인다) |
//
// ── 📏 잡음(규율 29) — ⚠️ **이 회차는 비율이라 이항 잡음이다** ────────────
//   `R = 12` ⇒ 비율의 sd ≈ **0.14** ⇒ ★ **두 팔의 차가 `≥ 0.42`(3 sd)여야 가른다.**
//   ⚠️⚠️ **회차 110·111 은 표본 3개로 가르려다 무늬가 통째로 뒤집혔다**
//     (㈀ 0→1 · ㈁ 1→3 · ㈃ 2→0) ⇒ ***그때 이미 「3개로는 못 가른다」가 드러났다.***
//
// ── ✅ 관문 ───────────────────────────────────────────────────────────────
//   **배관** 파라미터 읽기 성공 · 유한
//   ⭐ **양성 대조**(규율 16) `S=0` 팔이 **비트 동일** — ⚠️ 갈리면 **학습이 범인이 아니다**
//   ⭐ **표제** `㈃ − ㈂` 의 갈림 비율 차가 **≥0.42** 인가
//
// ── ⭐ 예측 ──────────────────────────────────────────────────────────────
//   ⚠️ **최근 열둘 중 여섯을 틀렸다**(반반이다).
//   · ⭐ 양성 대조 통과(회차 109 가 `S=0` 을 4/4 로 봤다)
//   · ⭐ **표제는 ⚠️ 진짜 모른다** — 못 가르면 ⭐ **D4 를 상한으로 닫는다**(규율 26).
//
// ── (아래는 회차 110 의 머리말 원문) ──────────────────────────────────────
//
// ══════════════════════════════════════════════════════════════════════════════
// mltp4e2.cw — 🐛 회차 110 · **평가를 넷으로 쪼갠다** ⚠️ **진단 회차**
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

class MLTP4E3
{
public:
	static void Tick(RHI* rhi)
	{
		if (_done || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltp4e3"))
		{
			LogA("[mlt] 🐛 회차 123(B3 · 비결정성의 범인)은 **꺼져 있다**(`-mltp4e3`)\n");
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
	static constexpr uint32 kSteps = 800u;
	// ⭐ **회차 123 — `R` 을 4 → 12 로 올린다.**
	//   ⚠️ 회차 110·111 이 **표본 3개**로 팔을 가르려다 **무늬가 통째로 뒤집혔다**
	//     (㈀ 0→1 · ㈁ 1→3 · ㈃ 2→0) ⇒ ★ ***그때 이미 「3개로는 못 가른다」가 드러났다.***
	//   📏 `R=12` 면 비율의 sd ≈ **0.14** ⇒ 두 팔의 차가 **≥0.42**(3 sd)여야 가른다(규율 29).
	static constexpr uint32 kRep = 12u;
	// ⭐ 팔 넷 — ⚠️ **축을 「큐 깊이」로 다시 골랐다**(회차 110 은 「무엇을 하나」 축이었다).
	//   ㈀ **`S=0`**(양성 대조 · 학습 0스텝 ⇒ 비트 동일이어야 한다) · ㈁ **그냥**(109 가 0/3) ·
	//   ㈂ **빈 틱 32**(큐를 확실히 비운다) · ㈃ **forward 64**(110 이 갈림을 본 자리)
	static constexpr uint32 kArms = 4u;
	static constexpr uint32 kArmZero = 0u, kArmNone = 1u, kArmIdle = 2u, kArmFwd = 3u;
	static constexpr uint32 kIdleTicks = 32u;

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
	inline static uint32 _idle = 0u;      // ⭐ 회차 123 — ㈂ 의 빈 틱 카운터

	static const char* _ArmName()
	{
		switch (_arm)
		{
		case kArmZero: return "㈀ S=0(양성)  ";
		case kArmNone: return "㈁ 그냥       ";
		case kArmIdle: return "㈂ 빈 틱 32   ";
		default:       return "㈃ forward 64 ";
		}
	}

	static void _To(uint32 next) { _qWait = MLTEvalGate::kDelay; _next = next; _st = kQuiesce; }

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🐛 **회차 123 · B3 — 비결정성의 범인을 끝낸다**(⚠️ 진단 · 씨앗 %u · S=%u · **R=%u**)\n",
			kSeed, kSteps, kRep);
		LogA("[mlt] 🐛   ⭐ 좁혀진 것 — 무죄: 세계·코퍼스·평가(CE 폭 0.000000)·`Setup` · ⭐ **CPU 프로브도 결정적**(121)\n");
		LogA("[mlt] 🐛     범인: **GPU 몸통 학습**(830,848/859,136 갈림 · **간헐적**) · ⛔ `WaitIdle` 로는 안 고쳐졌다\n");
		LogA("[mlt] 🐛   🔪 축을 **「큐 깊이」**로 — ㈀ `S=0`(양성) · ㈁ 그냥 · ㈂ **빈 틱 %u** · ㈃ **forward %u**\n",
			kIdleTicks, kTestPool);
		LogA("[mlt] 🐛   📏 잡음(규율 29) — `R=%u` ⇒ 비율 sd ≈ **0.14** ⇒ 가르려면 차가 **≥0.42**(3 sd)\n", kRep);
		LogA("[mlt] 🐛     ⚠️⚠️ **회차 110·111 은 표본 3개로 가르려다 무늬가 통째로 뒤집혔다** — 그것을 `R=12` 로 다시 묻는다\n");
		LogA("[mlt] 🐛   ⭐ **예측** — 양성 통과 · **표제는 진짜 모른다** · 못 가르면 ⭐ **D4 를 상한으로 닫는다**\n");
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

	// ⭐ 이 팔의 학습 스텝 수 — ⚠️ **㈀ 는 0**(양성 대조: 학습을 안 하면 비트 동일이어야 한다).
	static uint32 _StepsOf() { return (_arm == kArmZero) ? 0u : kSteps; }

	static void _Run()
	{
		const uint32 kSteps = _StepsOf();      // ⚠️ 이 함수 안에서만 가린다
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
		// ⭐ **회차 123 — 팔이 「반복 사이에 GPU 가 얼마나 바빴나」다**(큐 깊이 축).
		if (_arm == kArmZero || _arm == kArmNone) { _NextRep(); return; }
		// ⭐ ㈂ 빈 틱 — 아무 디스패치도 안 하고 **틱만 넘긴다**(큐가 확실히 비워진다).
		if (_arm == kArmIdle) { _idle = kIdleTicks; _st = kAfter; return; }
		// ㈃ — 학습 풀 그대로 **forward 만**(리드백 없음 ⇒ 디스패치가 쌓인다)
		_ai = 0u; _apend = false; _await = 0u; _idle = 0u; _st = kAfter;
	}

	// ⭐ **반복 사이의 「바쁨」** — ㈂ 는 **빈 틱만**, ㈃ 는 **forward 만**(리드백 없음).
	static void _After()
	{
		// ⭐ ㈂ — 아무 디스패치도 안 하고 틱만 흘린다(큐가 비워지는 것만 본다).
		if (_idle > 0u) { --_idle; if (_idle == 0u) _NextRep(); return; }
		if (_apend) { if (_await > 0u) { --_await; return; } _apend = false; }
		if (_ai >= kTestPool) { _NextRep(); return; }
		_M.SelectStep(_ai);
		if (!_M.Forward()) { _Fail("평가 forward"); return; }
		++_ai;
		// ⚠️ 리드백을 안 하므로 대기가 없다 — **틱만** 넘긴다(디스패치가 쌓이는 것이 이 팔의 요점).
		_apend = true; _await = 0u;
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
		double rate[kArms];
		for (uint32 a = 0; a < kArms; ++a)
		{
			uint32 b = 0u; float mx = 0.0f;
			for (uint32 r = 1; r < kRep; ++r)
			{ if (_diff[a][r] != 0u) ++b; if (_mx[a][r] > mx) mx = _mx[a][r]; }
			bad[a] = b;
			rate[a] = (double)b / (double)(kRep - 1u);
			const char* nm = (a == kArmZero) ? "㈀ S=0(양성)  " : (a == kArmNone) ? "㈁ 그냥       "
				: (a == kArmIdle) ? "㈂ 빈 틱 32   " : "㈃ forward 64 ";
			LogA("[mlt] 🐛   %s — 갈린 반복 **%u/%u**(비율 **%.2f**) · 최대차 %.3e%s\n",
				nm, b, kRep - 1u, rate[a], (double)mx, (b == 0u) ? "  ⇒ 비트 동일" : "  ⚠️");
		}
		// ⭐ 양성 대조 — `S=0`(학습 0스텝)은 **비트 동일**이어야 한다.
		const bool posOk = (bad[kArmZero] == 0u);
		// 📏 잡음(규율 29) — `R=12` 면 비율의 sd ≈ 0.14 ⇒ **차가 0.42(3 sd) 이상**이어야 가른다.
		const double kSep = 0.42;
		const double dQ = rate[kArmFwd] - rate[kArmIdle];
		LogA("[mlt] 🐛   ⭐ **양성 대조**(`S=0` 비트 동일) — %s\n",
			posOk ? "✅" : "⛔ **학습 밖에 원인이 있다**");
		LogA("[mlt] 🐛   📏 잡음(규율 29) — `R=%u` ⇒ 비율 sd ≈ **%.2f** ⇒ 가르려면 차가 **≥%.2f**(3 sd)\n",
			kRep, Sqrt((float)(0.25 / (double)(kRep - 1u))), kSep);
		LogA("[mlt] 🐛   ⭐ **표제** — ㈃(forward) − ㈂(빈 틱) = **%+.2f** → %s\n",
			dQ, (Abs((float)dQ) >= (float)kSep) ? "⭐ **가른다**" : "⚠️ **못 가른다**");
		if (!posOk)
			LogA("[mlt] 🐛   ⭐ 판정 = ⛔ **판정불가** — **양성 대조가 죽었다**(`S=0` 인데 갈린다 ⇒ 학습이 범인이 아니다)\n");
		else if (Abs((float)dQ) < (float)kSep)
			LogA("[mlt] 🐛   ⭐ 판정 = ⭐ ***큐 깊이로는 안 갈린다*** — 네 팔의 갈림 비율이 자를 못 넘는다\n"
			     "[mlt] 🐛      ⇒ ⭐ **D4 를 상한으로 닫는다**(규율 26): 반복 사이의 「바쁨」이 만드는 차이 < %.2f\n"
			     "[mlt] 🐛      ⇒ ⚠️ 남는 후보는 **드라이버/스케줄러**이고 그것은 **엔진 밖**이다\n", kSep);
		else if (dQ > 0.0)
			LogA("[mlt] 🐛   ⭐ 판정 = ⭐ **큐 깊이가 범인이다** — 앞선 디스패치가 쌓이면 갈린다\n"
			     "[mlt] 🐛      ⇒ ★ 고침 = **학습 전에 큐를 비운다**(빈 틱 또는 명시적 대기)\n");
		else
			LogA("[mlt] 🐛   ⭐ 판정 = ⚠️⚠️ **거꾸로다**(빈 틱이 더 갈린다) — 설계를 다시 본다\n");
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
