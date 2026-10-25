// mltp4a0.cw — 🔩 회차 77 · **P4 배관 + 판정 ①** (`-mltp4a0`)
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 77 이다.** (설계 심사 = 회차 76)
// ⚠️ 상위 = **P4 — 행동과 인과** · **배관 회차**(판정 회차가 아니다).
// ══════════════════════════════════════════════════════════════════════════════
//
// ⭐ 회차 76 심사가 세 결정을 했다:
//   ㈀ `MLTWorld::StepWith(act)` 를 더한다 — **행동을 밖에서 준다**(개입의 전제)
//   ㈁ `MLTP4Ctx` 를 **새로** 만든다 — `MLTP3Ctx` 는 P3 정본으로 **얼린다**(회귀가 깨진다)
//   ㈂ ㉠ 을 **2×2 교차**로 짠다(회차 78) — *"갈리나"* 는 약하다, **방향까지** 요구한다
//
// ── ⭐ 판정 ① 이 공짜로 생겼다 ──────────────────────────────────────────
//   `Step()` 이 그 스텝에 고를 행동(`ActAt`)을 `StepWith` 에 그대로 넣으면
//   ***상태열이 비트 동일이어야 한다.*** ⚠️ 순환이 없다 — 두 경로가 **다른 함수**이고
//   비교는 **끝점(상태)** 에서 한다(회차 68 이 밟은 「중간 버퍼로 하는 판정은 순환이다」의 반대).

using namespace PE;

class MLTP4A0
{
public:
	static void Tick(RHI* rhi)
	{
		if (_done || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltp4a0"))
		{
			LogA("[mlt] 🔩 회차 77은 **꺼져 있다**(`-mltp4a0`) — P4 배관 + 판정 ①\n");
			_done = true; return;
		}
		if (!_banner) { _Banner(); _banner = true; }
		if (!_gate1) { _Gate1(); return; }              // CPU 만 — 즉시 끝난다
		if (_seed >= kSeeds) { _Summary(); return; }
		switch (_st)
		{
		case kEncInit:  _EncBegin(rhi); return;
		case kEncTrain: _EncTrain();    return;
		case kGather:   _Gather();      return;
		case kQuiesce:  if (_qWait > 0u) { --_qWait; } else _st = kBodyInit; return;
		case kBodyInit: _BodyBegin(rhi); return;
		case kBodyTrain:_BodyTrain();   return;
		case kBodyEval: _BodyEval();    return;
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
	static constexpr uint32 kAxes = MLTP4Ctx::kAxes;          // 18
	static constexpr uint32 kSlots = MLTP4Ctx::kPersist;
	static constexpr uint32 kStateAx = MLTP4Ctx::kStateAx;
	static constexpr uint32 kActAx = MLTP4Ctx::kActAx;
	static constexpr uint32 kCand = MLTP2Cfg::kPatches * kLocal;
	static constexpr uint32 kNCtx = 128u, kTestCtx = 64u;
	static constexpr uint32 kTrainEpi = 1u, kTestEpi = 101u;
	static constexpr uint32 kPoolSteps = kNCtx / kBatch, kTestPool = kTestCtx / kBatch;
	static constexpr uint32 kGroup = kEncF / kTime;
	static constexpr uint32 kSteps = 800u, kPerTick = 4u;
	static constexpr uint32 kArms = 3u;   // ㈀ 온전 · ㈁ 행동 상수0 · ㈃ lr=0
	static constexpr uint32 kSignPass = 10u;
	static constexpr float  kFlatRel = 1.0e-6f;

	enum { kEncInit, kEncTrain, kGather, kQuiesce, kBodyInit, kBodyTrain, kBodyEval };

	inline static MLTP2Enc _E;
	inline static MLTModel _M;
	inline static MLTP4Ctx _tr, _te;
	inline static MLTEvalGate _gate;
	inline static bool _done = false, _banner = false, _encSetup = false, _finite = true;
	inline static bool _pending = false, _pre = false, _gate1 = false;
	inline static uint32 _seed = 0u, _st = kEncInit, _step = 0u, _arm = 0u;
	inline static uint32 _cor = 0u, _gGrp = 0u, _gIdx = 0u;
	inline static Array<float> _code, _norm, _val, _sym;
	inline static float _ce[kArms][kSeeds], _pre0[kSeeds], _floorTe[kSeeds];
	inline static bool  _seedOk[kSeeds];
	inline static uint32 _g1Bad = 0u;
	inline static uint32 _qWait = 0u;

	static void _ToBody() { _qWait = MLTEvalGate::kDelay; _st = kQuiesce; }
	static const char* _ArmName()
	{ return (_arm == 0u) ? "㈀ 온전" : ((_arm == 1u) ? "㈁ 행동 상수0" : "㈃ lr=0"); }

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🔩 **회차 77 · P4 배관 + 판정 ①**(⚠️ 배관 회차 · 상위 = **행동과 인과**)\n");
		LogA("[mlt] 🔩   대역 `[상태5][**행동5**][활성8]` × 시각 %u ⇒ kAxes **%u** · kCtx **%u**\n",
			kTime, kAxes, MLTP4Ctx::kCtx);
		LogA("[mlt] 🔩   ⭐ **판정 ①** — `StepWith(ActAt(t))` 가 `Step()` 과 **비트 동일**인가(끝점 · 순환 없음)\n");
		LogA("[mlt] 🔩   위생 셋 — ㈃ lr=0 평탄 · ㈀ 이 복사바닥을 넘음 · ⭐ ㈀≠㈁(배관이 행동을 나른다)\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

	// ══════════════════════════════════════════════════════════════════
	// ⭐ 판정 ① — `StepWith` 가 `Step()` 과 같은 세계를 만드나 (CPU 만)
	// ══════════════════════════════════════════════════════════════════
	static void _Gate1()
	{
		_g1Bad = 0u;
		uint32 worst = 0u;
		for (uint32 s = 0; s < kSeeds; ++s)
			for (uint32 e = 0; e < 4u; ++e)
			{
				MLTWorld a, b;
				a.Reset(s, kTrainEpi + e, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
				b.Reset(s, kTrainEpi + e, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
				for (uint32 t = 0; t < 32u; ++t)
				{
					const uint32 n = b.StepNo();
					a.Step();
					b.StepWith(b.ActAt(n));               // ⭐ 「같은 행동」을 밖에서 준다
					const MLTState& sa = a.State();
					const MLTState& sb = b.State();
					for (int k = 0; k < MLTState::kAxes; ++k)
						if (sa.Axis(k) != sb.Axis(k)) { ++_g1Bad; ++worst; }
				}
			}
		LogA("[mlt] 🔩   **판정 ①** — 씨앗 %u × 문맥 4 × 32스텝 × 축 5 = **%u 칸** 중 다른 칸 **%u** → %s\n",
			kSeeds, kSeeds * 4u * 32u * 5u, _g1Bad, (_g1Bad == 0u) ? "✅ 비트 동일" : "⛔");
		if (_g1Bad != 0u)
		{
			LogA("[mlt] 🔩 ⛔ **판정 ① 실패 — `StepWith` 가 `Step()` 과 다른 세계를 만든다**. 여기서 멈춘다\n");
			_done = true; return;
		}
		_gate1 = true;
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
					// ⭐ 행동을 **먼저 정해** 슬롯에 넣고, 그 행동으로 굴린다(`StepWith`).
					//   ⚠️ 그래야 컨텍스트의 행동과 세계의 행동이 **정확히 같다**.
					const MLTAct a = w.ActAt(w.StepNo());
					C.StoreAct5(ctx, t, a);
					w.StepWith(a);
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
			if (++_cor >= 2u)
			{
				Array<float> marg; _tr.Marginal(marg);
				float c1 = 0.0f, c2 = 0.0f, l1 = 0.0f, l2 = 0.0f;
				_tr.BestCopy(marg, c1, c2, l1, l2);
				const float t1 = (float)_te.CeCopy(marg, l1, false);
				const float t2 = (float)_te.CeCopy(marg, l2, true);
				_floorTe[_seed] = (t1 < t2) ? t1 : t2;
				LogA("[mlt] 🔩 씨앗 %2u · 시험 복사바닥 **%.4f**\n", _seed, (double)_floorTe[_seed]);
				_arm = 0u; _ToBody();
			}
		}
	}

	// ══════════════════════════════════════════════════════════════════
	static void _BodyBegin(RHI* rhi)
	{
		// ⚠️ 심볼 어휘 = 상태 5 + 행동 5 + 활성 N.
		if (!_M.Setup(rhi, kStateAx + kActAx + kN, kN, kAxes, kTime)) { _Fail("몸통 준비"); return; }
		_MakeArm(_tr, kNCtx, kPoolSteps);
		if (!_M.UploadPool(_val, _tr.Tgt(), kPoolSteps) || !_M.UploadSymbolPool(_sym, kPoolSteps))
		{ _Fail("학습 풀 업로드"); return; }
		_step = 0u;
		if (_arm == 2u) { _pre = true; _SwitchToTest(); return; }
		_pre = false; _st = kBodyTrain;
	}

	// ⭐ ㈁ 은 **행동 슬롯의 값만 0** 으로 만든다(심볼·자리·연산량은 같다).
	static void _MakeArm(const MLTP4Ctx& C, uint32 nCtx, uint32 nPool)
	{
		const uint32 n = nPool * MLTP4Ctx::kRows;
		_val.Reset(0); _sym.Reset(0);
		for (uint32 i = 0; i < n; ++i) { _val.Add(C.Val()[i]); _sym.Add(C.Sym()[i]); }
		if (_arm != 1u) return;
		for (uint32 ctx = 0; ctx < nCtx; ++ctx)
			for (uint32 t = 0; t < kTime; ++t)
			{
				const uint32 base = MLTP4Ctx::Row(ctx, t, MLTP4Ctx::kOAct);
				for (uint32 i = 0; i < kActAx; ++i) _val.Data()[base + i] = 0.0f;
			}
	}

	static bool _SwitchToTest()
	{
		_MakeArm(_te, kTestCtx, kTestPool);
		if (!_M.UploadPool(_val, _te.Tgt(), kTestPool) || !_M.UploadSymbolPool(_sym, kTestPool))
		{ _Fail("시험 풀 업로드"); return false; }
		_gate.Begin(kTestPool); _st = kBodyEval;
		return true;
	}

	static void _BodyTrain()
	{
		if (_step >= kSteps) { _SwitchToTest(); return; }
		for (uint32 i = 0; i < kPerTick && _step < kSteps; ++i)
		{
			_M.SelectStep(_step % kPoolSteps);
			if (!_M.Forward() || !_M.Backward() || !_M.AdamStep((_arm == 2u) ? 0.0f : 1.0f))
			{ _Fail("몸통 스텝"); return; }
			++_step;
		}
	}

	static void _BodyEval()
	{
		bool fail = false;
		if (!_gate.Step(_M, fail)) return;
		if (fail) { _Fail("평가 게이트"); return; }
		if (!_gate.Finite()) _finite = false;
		const float ce = _gate.Mean();
		if (_pre)
		{
			_pre0[_seed] = ce; _pre = false;
			_MakeArm(_tr, kNCtx, kPoolSteps);
			if (!_M.UploadPool(_val, _tr.Tgt(), kPoolSteps) || !_M.UploadSymbolPool(_sym, kPoolSteps))
			{ _Fail("학습 풀 복귀"); return; }
			_step = 0u; _st = kBodyTrain; return;
		}
		_ce[_arm][_seed] = ce;
		LogA("[mlt] 🔩   %s 씨앗 %2u · 시험 CE **%.5f**\n", _ArmName(), _seed, (double)ce);
		if (++_arm < kArms) { _ToBody(); return; }
		_seedOk[_seed] = _finite;
		++_seed; _arm = 0u; _st = kEncInit;
	}

	static void _Summary()
	{
		double m[kArms], mf = 0.0;
		for (uint32 a = 0; a < kArms; ++a) m[a] = 0.0;
		uint32 ok = 0u, flat = 0u, beat = 0u, diff = 0u;
		for (uint32 s = 0; s < kSeeds; ++s)
		{
			if (!_seedOk[s]) continue;
			++ok;
			for (uint32 a = 0; a < kArms; ++a) m[a] += _ce[a][s];
			mf += _floorTe[s];
			if (Abs(_ce[2][s] - _pre0[s]) <= kFlatRel * Abs(_pre0[s])) ++flat;
			if (_ce[0][s] < _floorTe[s]) ++beat;
			if (_ce[0][s] != _ce[1][s]) ++diff;
		}
		if (ok > 0u) { for (uint32 a = 0; a < kArms; ++a) m[a] /= ok; mf /= ok; }
		const bool h1 = (flat == ok) && _finite;
		const bool h2 = (beat >= kSignPass);
		const bool h3 = (diff >= kSignPass);

		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🔩 **회차 77 · P4 배관** — 읽은 씨앗 %u/%u · 판정 ① **%s**\n",
			ok, kSeeds, (_g1Bad == 0u) ? "✅" : "⛔");
		LogA("[mlt] 🔩   평균 CE — 시험바닥 **%.4f** · ㈀ 온전 **%.4f** · ㈁ 행동0 **%.4f** · ㈃ lr=0 %.4f\n",
			mf, m[0], m[1], m[2]);
		LogA("[mlt] 🔩   위생① ㈃ 평탄 **%u/%u** → %s\n", flat, ok, h1 ? "통과" : "⛔");
		LogA("[mlt] 🔩   위생② ㈀ 이 바닥을 넘음 **%u/%u**(필요 %u) → %s\n", beat, ok, kSignPass, h2 ? "통과" : "⛔");
		LogA("[mlt] 🔩   ⭐ 위생③ ㈀ ≠ ㈁ **%u/%u**(배관이 행동을 나른다) → %s\n", diff, ok, h3 ? "통과" : "⛔");
		if (_g1Bad == 0u && h1 && h2 && h3)
			LogA("[mlt] 🔩   ⭐ 판정 = ✅ **P4 배관이 섰다** ⇒ 회차 78 = **㉠ 개입 시험**(2×2 교차)\n");
		else
			LogA("[mlt] 🔩   ⭐ 판정 = ⛔ **배관이 안 섰다** — 위에서 깨진 칸을 고친다(㉠ 을 열지 않는다)\n");
		LogA("[mlt] 🔩   ⚠️ 이것은 **배관 확인**이다 — `㈀≠㈁` 은 「갈리나」의 약한 판이고 **판정이 아니다**\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		_E.Destroy(); _done = true;
	}

	static void _Fail(const char* why)
	{
		LogA("[mlt] 🔩 ⛔ %s (씨앗 %u · 팔 %u · 단계 %u)\n", why, _seed, _arm, _st);
		_E.Destroy(); _done = true;
	}
};
