// mltp3k0.cw — 🔩 회차 67·68 · **인코더 주입 배관 + 판정 ① + 생존 관문** (`-mltp3k0`)
//
// ⛔⛔⛔ **2026-08-26 · 이 하네스에는 미해결 버그가 있다 — 참고하지 마라.**
//   회차 68 에서 `㈂(재구성+몸통)` 이 `㈁(재구성만)` 과 **모든 자리에서 같았다**(id 변화율 0.000).
//   그런데 회차 69·70·71 이 **같은 주입 창구로** 다음을 12/12 로 세웠다:
//     ㈀ 사다리 네 칸(`dMag→dScore→기울기→파라미터`)이 **다 살아 있다**(회차 69)
//     ㈁ 「틱당 여러 번 쓰기」는 범인이 **아니다**(회차 70 · D/C = 1.02)
//     ㈂ 「희소 8칸」도 범인이 **아니다**(회차 71 · E/C = 0.841)
//     ㈃ **32프레임 주입은 파라미터를 12~15% 바꾼다**(회차 70·71 재현)
//   ⇒ ***배관은 작동한다. 버그는 이 파일 안에 있다.*** ⚠️ 다섯 회차를 쓰고도 못 찾았고,
//     회차 71 의 심사가 **이 코드를 버리기로** 했다(→ `mltp3k2.cw` 위에 다시 짓는다).
//   ★ 지우지 않고 남기는 이유: **미해결이라는 사실 자체가 기록**이다.
//
// ⚠️⚠️ **회차 68 은 회차 67 과 「자」만 다르다** — 배관·팔·교대·생존 관문은 **한 글자도 안 바꿨다**.
//   회차 67 은 판정 ① 이 `1.122e-5`(문턱 `1e-5`)로 **12% 초과**해 멈췄는데, 손계산이 그것을
//   **상쇄(cancellation)** 로 정확히 설명했다(`오차 ≈ 2⁻²³·‖d₀‖/‖X‖`, `‖d₀‖/‖X‖ ≈ 190`).
//   ⇒ **배선이 아니라 자가 틀렸다** ⇒ 시험 벡터를 `‖d₀‖` 크기로 맞추고 문턱을 **계산해서** 넣었다.
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 67 이다.**
// ⚠️ 상위 = **경험이 인코딩을 바꾸나** · **판정 회차가 아니다**(배관 — 계수 안 늘린다).
// ══════════════════════════════════════════════════════════════════════════════
//
// ⭐ **이 회차가 처음으로 하는 것: 몸통의 손실이 인코더에 닿는다.**
//   이 트랙에서 한 번도 없던 일이다(회차 63 이 기록을 읽어 확인했다 — 회차 40·41 의 STE 는
//   **인코더 안의** 계수 갱신이었지 몸통→인코더가 아니었다).
//
// ── 교대 최적화(회차 63 설계 · R=1) ──────────────────────────────────────
//   ① 코퍼스 수집 → ② 몸통 400스텝 → ③ dVal 수집 → ④ 인코더를 민다(앞 8그룹) → ⑤ 재수집
//   ⚠️ ④ 를 8그룹(32문맥·256프레임)으로 **좁힌 것은 예산 때문**이고 등록문에 적었다(silent cap 금지).
//
// ── 팔 셋 ────────────────────────────────────────────────────────────────
//   ㈀ 얼림(안 민다) · ㈁ 재구성만 · ㈂ 재구성 + 몸통
//   ⚠️ ㈁ 이 없으면 *"몸통 때문"* 과 *"더 밀었기 때문"* 이 안 갈린다.
//
// ⚠️⚠️ **생존 관문이 표제보다 먼저다** — 회차 40·41 이 그 관문으로 두 번 붙잡았다.
//   **죽은 팔의 숫자는 어느 갈래에서도 효과량으로 안 읽는다.**

using namespace PE;

class MLTP3K0
{
public:
	static void Tick(RHI* rhi)
	{
		if (_done || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltp3k0"))
		{
			LogA("[mlt] 🔩 회차 67은 **꺼져 있다**(`-mltp3k0`) — 인코더 주입 배관 + 생존 관문\n");
			_done = true; return;
		}
		if (!_banner) { _Banner(); _banner = true; }
		if (_seed >= kSeeds) { _Summary(); return; }
		switch (_st)
		{
		case kEncInit:  _EncBegin(rhi); return;
		case kEncTrain: _EncTrain();    return;
		case kGate1:    _Gate1();       return;
		case kGather:   _Gather();      return;
		case kQuiesce:  if (_qWait > 0u) { --_qWait; } else _st = kBodyInit; return;
		case kBodyInit: _BodyBegin(rhi); return;
		case kBodyTrain:_BodyTrain();   return;
		case kSweep:    _Sweep();       return;
		case kPush:     _Push();        return;
		case kMeasure:  _Measure();     return;
		default: return;
		}
	}

	static bool Done() { return _done; }

private:
	static constexpr uint32 kSeeds = 12u;
	static constexpr uint32 kEncF = 32u, kEncSteps = 1200u, kEncPerTick = 8u;
	static constexpr uint32 kN = 250u, kLocal = 8u;
	static constexpr uint32 kTime = MLTP3Ctx::kTime;
	static constexpr uint32 kBatch = MLTP3Ctx::kBatch;
	static constexpr uint32 kAxes = MLTP3Ctx::kAxes;
	static constexpr uint32 kSlots = MLTP3Ctx::kPersist;
	static constexpr uint32 kStateAx = MLTP3Ctx::kStateAx;
	static constexpr uint32 kCtxRow = MLTP3Ctx::kCtx;
	static constexpr uint32 kCand = MLTP2Cfg::kPatches * kLocal;    // 512
	static constexpr uint32 kNCtx = 128u;
	static constexpr uint32 kTrainEpi = 1u, kTestEpi = 901u;        // ⚠️ 901 = 학습에 안 쓴 에피소드
	static constexpr uint32 kPoolSteps = kNCtx / kBatch;
	static constexpr uint32 kGroup = kEncF / kTime;                 // 4 문맥 / 풀
	static constexpr uint32 kAllGrp = kNCtx / kGroup;               // 32 그룹
	static constexpr uint32 kPushGrp = 8u;                          // ⚠️ 예산 — 등록문에 적었다
	static constexpr uint32 kSteps = 400u, kPerTick = 4u;
	static constexpr uint32 kArms = 3u;
	static constexpr uint32 kSignPass = 10u;
	static constexpr float  kLamRel = 0.5f;                         // 상대 λ
	// ⭐ **문턱을 계산해서 적는다**(회차 67 이 세 번째로 밟은 자리 — *"문턱이 잡음보다 큰지 먼저"*):
	//   `d₁ = d₀ + X` 를 float32 로 만드니 절대 반올림이 `2⁻²³·|d₀| ≈ 1.19e-7·|d₀|` 다.
	//   우리가 재는 것은 `‖(d₁−d₀)−X‖/‖X‖` ⇒ 오차 `≈ 1.19e-7 · ‖d₀‖/‖X‖`.
	//   ⇒ ⭐ **`X` 를 `‖d₀‖` 크기로 맞춰** 그 비를 **1** 로 만들면 예상 오차가 `≈ 1.2e-7`.
	//   ⇒ 안전율 **40배**를 얹어 문턱 **5e-6**. ⚠️ 회차 67 은 `X~1e-3` 을 박아 비가 **190** 이었고
	//     그래서 오차가 `1.12e-5` 로 나왔다(= 배선이 아니라 **자**가 틀린 것이다).
	static constexpr float  kGate1Tol = 5.0e-6f;
	static constexpr float  kSurvive = 2.0f;                        // MSE(㈂) ≤ 2 × MSE(㈀)

	enum { kEncInit, kEncTrain, kGate1, kGather, kQuiesce, kBodyInit, kBodyTrain,
	       kSweep, kPush, kMeasure };

	inline static MLTP2Enc _E;
	inline static MLTModel _M;
	inline static MLTP3Ctx _tr;
	inline static bool _done = false, _banner = false, _encSetup = false, _finite = true;
	inline static bool _pending = false;
	inline static uint32 _seed = 0u, _st = kEncInit, _step = 0u, _arm = 0u;
	inline static uint32 _cor = 0u, _gGrp = 0u, _gIdx = 0u;         // `_cor` = 0 첫 수집 · 1 재수집
	inline static Array<float> _code, _norm, _dv, _ext, _d0, _d1, _pRef, _pNow;
	inline static Array<float> _gslot;      // [ctx][t][j] = ∂L/∂pm
	inline static Array<float> _symRef;     // ㈁ 의 최종 심볼(㈂ 와 견주는 눈금)
	// 밀기 상태
	inline static uint32 _pg = 0u, _pf = 0u, _wait = 0u, _g1 = 0u;
	inline static float  _scale = 1.0f, _ratio = 0.0f;
	inline static bool   _scaleOk = false;
	// 결과
	inline static float _mse[kArms][kSeeds], _dp[kArms][kSeeds], _idch[kArms][kSeeds];
	inline static float _g1err[kSeeds], _ratioS[kSeeds];
	inline static bool  _seedOk[kSeeds];

	inline static uint32 _qWait = 0u;
	static const char* _ArmName()
	{ return (_arm == 0u) ? "㈀ 얼림" : ((_arm == 1u) ? "㈁ 재구성만" : "㈂ 재구성+몸통"); }

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🔩 **회차 67 · 인코더 주입 배관 + 판정 ① + 생존 관문**(⚠️ 판정 회차 아님)\n");
		LogA("[mlt] 🔩   ⭐ **몸통의 손실이 인코더에 닿는다** — 이 트랙에서 처음이다\n");
		LogA("[mlt] 🔩   교대 R=1 · 밀기 %u그룹(%u문맥·%u프레임) · 상대 λ **%.2f** · 팔 셋\n",
			kPushGrp, kPushGrp * kGroup, kPushGrp * kEncF, (double)kLamRel);
		LogA("[mlt] 🔩   ⚠️⚠️ **생존 관문이 먼저다** — MSE(㈂) ≤ %.0f × MSE(㈀)(회차 40·41 의 교훈)\n",
			(double)kSurvive);
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
		_E.SetK(kLocal); _E.SetSelectAbs(false); _E.ClearExtDMag();
		if (!_RenderPool(0u, kEncF, 0u)) return;
		_step = 0u; _st = kEncTrain;
	}

	// 에피소드 `epi` 의 문맥 `base..` 를 렌더해 풀에 올린다(`nFrames` 는 `kEncF` 고정).
	//   `mode`: 0 = 인코더 프리트레인(에피소드 0 하나) · 1 = 코퍼스 그룹 · 2 = 시험 프레임
	static bool _RenderPool(uint32 grp, uint32 nFrames, uint32 mode)
	{
		Array<float> fr, tg; fr.Reset(0); tg.Reset(0);
		ImageFormat::Bitmap bmp; Bytes packed;
		if (mode == 0u || mode == 2u)
		{
			MLTWorld w; w.Reset(_seed, (mode == 0u) ? 0u : kTestEpi,
				MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
			for (uint32 f = 0; f < nFrames; ++f)
			{
				w.Step();
				if (!w.Render(bmp) || !MLTWorld::Pack(bmp, nullptr, packed)) { _Fail("Render/Pack"); return false; }
				MLTP2Enc::AppendFrame(fr, tg, (const uint8*)packed.GetData());
			}
		}
		else
		{
			for (uint32 g = 0; g < kGroup; ++g)
			{
				const uint32 ctx = grp * kGroup + g;
				MLTWorld w; w.Reset(_seed, kTrainEpi + ctx, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
				for (uint32 t = 0; t < kTime; ++t)
				{
					w.Step();
					if (!w.Render(bmp) || !MLTWorld::Pack(bmp, nullptr, packed)) { _Fail("Render/Pack"); return false; }
					MLTP2Enc::AppendFrame(fr, tg, (const uint8*)packed.GetData());
					if (_cor == 0u) _tr.StoreState(ctx, t, w.State());
				}
			}
		}
		if (!_E.WritePool(fr, tg, kEncF)) { _Fail("풀 업로드"); return false; }
		return true;
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
		// ⭐ 얼린 팔의 파라미터를 기준으로 잡는다(눈금 `‖Δp‖/‖p‖`).
		if (_arm == 0u && !_E.ReadParams(_pRef)) { _Fail("파라미터 리드백"); return; }
		if (_arm == 0u) { _g1 = 0u; _st = kGate1; return; }        // 판정 ① 은 씨앗마다 한 번
		_StartGather();
	}

	static void _StartGather()
	{
		_tr.SetSortById(true);
		if (_cor == 0u) _tr.Begin(kNCtx, kN);
		_gGrp = 0u; _gIdx = 0u; _pending = false; _st = kGather;
	}

	// ══════════════════════════════════════════════════════════════════
	// 판정 ① — **주입이 닿나**. `Backward`(주입 없음) ↔ `Backward`(주입) 의 `_tDMag` 차이가 `X` 인가.
	// ══════════════════════════════════════════════════════════════════
	static void _Gate1()
	{
		if (_g1 == 0u)
		{
			_E.SetFrame(0u); _E.ClearExtDMag();
			if (!_E.Forward() || !_E.Backward()) { _Fail("판정① fwd/bwd(민)"); return; }
			_wait = MLTEvalGate::kDelay; _g1 = 1u; return;
		}
		if (_g1 == 1u)
		{
			if (_wait > 0u) { --_wait; return; }
			if (!_E.ReadDMag(_d0)) { _Fail("판정① dMag(민)"); return; }
			// ⚠️ 결정적인 시험 벡터(난수 스트림을 안 쓴다) — ⭐ **크기를 `‖d₀‖` 에 맞춘다**.
			//   ★ 그래야 상쇄가 안 생긴다(위 `kGate1Tol` 의 그 계산).
			_ext.Reset(0);
			double su = 0.0, sd = 0.0;
			for (uint32 c = 0; c < kCand; ++c)
			{
				const float u = MLTWorld::Unit(MLTWorld::Hash(_seed * 613u + c, MLTSalt::Start, 31u));
				_ext.Add(u); su += (double)u * u; sd += (double)_d0[c] * _d0[c];
			}
			const float nu = Sqrt((float)su), nd = Sqrt((float)sd);
			const float sc = (nu > 1.0e-20f) ? (nd / nu) : 1.0f;
			// 눈금 — 회차 67 이 손계산으로 얻은 **190** 을 실측으로 확인한다.
			LogA("[mlt] 🔩   씨앗 %2u · 눈금 **‖d₀‖/‖X_raw‖ = %.4g**(회차 67 손계산 ≈ 190)\n",
				_seed, (double)((nu > 1.0e-20f) ? (nd / (nu * 1.0e-3f)) : 0.0f));
			for (uint32 c = 0; c < kCand; ++c) _ext.Data()[c] *= sc;
			_E.SetFrame(0u);
			if (!_E.Forward() || !_E.SetExtDMag(_ext) || !_E.Backward()) { _Fail("판정① fwd/bwd(주입)"); return; }
			_E.ClearExtDMag();
			_wait = MLTEvalGate::kDelay; _g1 = 2u; return;
		}
		if (_wait > 0u) { --_wait; return; }
		if (!_E.ReadDMag(_d1)) { _Fail("판정① dMag(주입)"); return; }
		double num = 0.0, den = 0.0;
		for (uint32 c = 0; c < kCand; ++c)
		{
			const double d = (double)(_d1[c] - _d0[c]) - (double)_ext[c];
			num += d * d; den += (double)_ext[c] * (double)_ext[c];
		}
		_g1err[_seed] = (float)(Sqrt((float)num) / (Sqrt((float)den) + 1.0e-8f));
		LogA("[mlt] 🔩   씨앗 %2u · **판정① 주입 오차 %.3e**(문턱 %.0e) → %s\n",
			_seed, (double)_g1err[_seed], (double)kGate1Tol,
			(_g1err[_seed] <= kGate1Tol) ? "통과" : "⛔");
		if (_g1err[_seed] > kGate1Tol) { _Fail("판정① 실패 — 주입이 안 닿는다"); return; }
		_StartGather();
	}

	// ══════════════════════════════════════════════════════════════════
	static void _Gather()
	{
		if (_pending)
		{
			Array<float> ids, mag;
			if (!_E.ReadAct(ids, mag) || ids.Count() != kCand) { _Fail("활성 리드백"); return; }
			_tr.StoreAct(_gGrp * kGroup + (_gIdx - 1u) / kTime, (_gIdx - 1u) % kTime, ids, mag, _norm);
			_pending = false;
		}
		if (_gIdx == 0u) { if (!_RenderPool(_gGrp, kEncF, 1u)) return; }
		if (_gIdx < kEncF)
		{
			_E.SetFrame(_gIdx);
			if (!_E.Forward()) { _Fail("문맥 forward"); return; }
			++_gIdx; _pending = true; return;
		}
		_gIdx = 0u;
		if (++_gGrp * kGroup < kNCtx) return;
		_gGrp = 0u;
		if (_cor == 1u) { _st = kMeasure; return; }               // 재수집이 끝났다
		_qWait = MLTEvalGate::kDelay; _st = kQuiesce;
	}

	// ══════════════════════════════════════════════════════════════════
	static void _BodyBegin(RHI* rhi)
	{
		if (!_M.Setup(rhi, kStateAx + kN, kN, kAxes, kTime)) { _Fail("몸통 준비"); return; }
		if (!_M.UploadPool(_tr.Val(), _tr.Tgt(), kPoolSteps) || !_M.UploadSymbolPool(_tr.Sym(), kPoolSteps))
		{ _Fail("학습 풀 업로드"); return; }
		_step = 0u; _st = kBodyTrain;
	}

	static void _BodyTrain()
	{
		if (_step >= kSteps)
		{
			if (_arm == 0u) { _cor = 1u; _st = kMeasure; return; }   // 얼림은 밀 것도 재수집도 없다
			_gslot.Reset(0);
			for (uint32 i = 0; i < kNCtx * kTime * kSlots; ++i) _gslot.Add(0.0f);
			_gGrp = 0u; _wait = 0u; _pending = false; _st = kSweep; return;
		}
		for (uint32 i = 0; i < kPerTick && _step < kSteps; ++i)
		{
			_M.SelectStep(_step % kPoolSteps);
			if (!_M.Forward() || !_M.Backward() || !_M.AdamStep(1.0f)) { _Fail("몸통 스텝"); return; }
			++_step;
		}
	}

	// ── ③ 학습 풀 한 바퀴 · `dVal` → 연쇄법칙(회차 66 이 12/12 로 세운 식) ──
	static void _Sweep()
	{
		if (_pending)
		{
			if (_wait > 0u) { --_wait; return; }
			if (!_M.ReadDVal(_dv)) { _Fail("dVal 리드백"); return; }
			for (uint32 b = 0; b < kBatch; ++b)
			{
				const uint32 ctx = _gGrp * kBatch + b;
				for (uint32 t = 0; t < kTime; ++t) _Chain(ctx, b, t);
			}
			_pending = false; ++_gGrp;
		}
		if (_gGrp >= kPoolSteps)
		{ _gGrp = 0u; _pg = 0u; _pf = 0u; _scaleOk = false; _st = kPush; return; }
		_M.SelectStep(_gGrp);
		if (!_M.Forward() || !_M.Backward()) { _Fail("dVal fwd/bwd"); return; }
		_wait = MLTEvalGate::kDelay; _pending = true;
	}

	// `∂L/∂pm_i = inv·g_i` · `i=m` 이면 `inv·(g_m − sign(pm_m)·S)` (회차 66 판정 ② 통과 식)
	static void _Chain(uint32 ctx, uint32 b, uint32 t)
	{
		const float inv = _tr.Inv(ctx, t);
		double S = 0.0; uint32 m = 0u; float best = -1.0f;
		for (uint32 q = 0; q < kSlots; ++q)
		{
			const uint32 row = b * kCtxRow + t * kAxes + (kStateAx + q);
			const float g = (row < _dv.Count()) ? _dv[row] : 0.0f;
			const float v = _tr.Val()[MLTP3Ctx::Row(ctx, t, kStateAx + q)];
			S += (double)g * (double)v;
			const float a = Abs(_tr.RawMag(ctx, t, q));
			if (a > best) { best = a; m = q; }
		}
		for (uint32 j = 0; j < kSlots; ++j)
		{
			const uint32 row = b * kCtxRow + t * kAxes + (kStateAx + j);
			const float g = (row < _dv.Count()) ? _dv[row] : 0.0f;
			float d = inv * g;
			if (j == m)
			{
				const float pm = _tr.RawMag(ctx, t, m);
				d = inv * (g - ((pm >= 0.0f) ? 1.0f : -1.0f) * (float)S);
			}
			_gslot.Data()[(ctx * kTime + t) * kSlots + j] = d;
		}
	}

	// ── ④ 인코더를 민다(앞 `kPushGrp` 그룹) ────────────────────────────
	static void _Push()
	{
		if (_pending)                                    // 배율을 잡는 중
		{
			if (_wait > 0u) { --_wait; return; }
			if (!_E.ReadDMag(_d0)) { _Fail("배율용 dMag"); return; }
			double a = 0.0, e = 0.0;
			_BuildExt(0u, 0u);
			for (uint32 c = 0; c < kCand; ++c)
			{ a += (double)_d0[c] * _d0[c]; e += (double)_ext[c] * _ext[c]; }
			const double na = Sqrt((float)a), ne = Sqrt((float)e);
			_ratio = (ne > 1.0e-20) ? (float)(na / ne) : 0.0f;
			_scale = (ne > 1.0e-20) ? (float)((double)kLamRel * na / ne) : 0.0f;
			_ratioS[_seed] = _ratio;
			LogA("[mlt] 🔩   씨앗 %2u · 눈금 **‖d재구성‖/‖d몸통‖ = %.4g** ⇒ 배율 %.4g\n",
				_seed, (double)_ratio, (double)_scale);
			_scaleOk = true; _pending = false; return;
		}
		if (_pg >= kPushGrp)
		{
			// ⑤ 재수집 — ⚠️ 코퍼스를 **새 인코더로** 다시 만든다(그것이 「바뀌었나」의 얼굴이다).
			_cor = 1u; _StartGather(); return;
		}
		if (_pf == 0u) { if (!_RenderPool(_pg, kEncF, 1u)) return; }
		// ⭐ 배율은 **씨앗마다 한 번** — 첫 그룹 첫 프레임에서 잡는다(등록문의 그 결정).
		if (_arm == 2u && !_scaleOk)
		{
			_E.SetFrame(0u); _E.ClearExtDMag();
			if (!_E.Forward() || !_E.Backward()) { _Fail("배율용 fwd/bwd"); return; }
			_wait = MLTEvalGate::kDelay; _pending = true; return;
		}
		for (uint32 i = 0; i < kEncPerTick && _pf < kEncF; ++i)
		{
			_E.SetFrame(_pf);
			if (!_E.Forward()) { _Fail("밀기 forward"); return; }
			if (_arm == 2u)
			{
				_BuildExt(_pg, _pf);
				for (uint32 c = 0; c < kCand; ++c) _ext.Data()[c] *= _scale;
				if (!_E.SetExtDMag(_ext)) { _Fail("dMag 주입"); return; }
			}
			else _E.ClearExtDMag();
			if (!_E.Backward() || !_E.AdamStep(1.0f)) { _Fail("밀기 bwd/adam"); return; }
			_E.ClearExtDMag();
			++_pf;
		}
		if (_pf >= kEncF) { _pf = 0u; ++_pg; }
	}

	// 그 프레임의 후보 기울기 벡터를 만든다. 프레임 `f` = `(ctx = grp·kGroup + f/kTime, t = f%kTime)`.
	static void _BuildExt(uint32 grp, uint32 f)
	{
		_ext.Reset(0);
		for (uint32 c = 0; c < kCand; ++c) _ext.Add(0.0f);
		const uint32 ctx = grp * kGroup + f / kTime, t = f % kTime;
		if (ctx >= kNCtx) return;
		for (uint32 j = 0; j < kSlots; ++j)
		{
			const uint32 c = _tr.Cand(ctx, t, j);
			if (c >= kCand) continue;                    // `kNoCand` 포함
			_ext.Data()[c] += _gslot[(ctx * kTime + t) * kSlots + j];
		}
	}

	// ══════════════════════════════════════════════════════════════════
	// 측정 — 인코더 **시험 재구성 MSE**(에피소드 901) + 눈금 둘
	// ══════════════════════════════════════════════════════════════════
	static void _Measure()
	{
		if (_pending)
		{
			if (_wait > 0u) { --_wait; return; }
			float mse = 0.0f; bool fin = true;
			if (!_E.ReadMse(mse, fin)) { _Fail("시험 MSE 리드백"); return; }
			if (!fin) _finite = false;
			_mse[_arm][_seed] = mse;
			if (!_E.ReadParams(_pNow)) { _Fail("파라미터 리드백"); return; }
			double dn = 0.0, pn = 0.0;
			for (uint32 i = 0; i < _pRef.Count() && i < _pNow.Count(); ++i)
			{
				const double d = (double)_pNow[i] - (double)_pRef[i];
				dn += d * d; pn += (double)_pRef[i] * (double)_pRef[i];
			}
			_dp[_arm][_seed] = (pn > 1.0e-20) ? (float)(Sqrt((float)dn) / Sqrt((float)pn)) : 0.0f;
			// 눈금 — ㈁ 의 최종 심볼과 견준다(㈂ 만 뜻이 있다).
			if (_arm == 1u) { _symRef.Reset(0); for (uint32 i = 0; i < _tr.Sym().Count(); ++i) _symRef.Add(_tr.Sym()[i]); }
			float ch = 0.0f;
			if (_arm == 2u && _symRef.Count() == _tr.Sym().Count())
			{
				uint32 diff = 0u, tot = 0u;
				for (uint32 ctx = 0; ctx < kNCtx; ++ctx)
					for (uint32 t = 0; t < kTime; ++t)
						for (uint32 j = 0; j < kSlots; ++j)
						{
							const uint32 r = MLTP3Ctx::Row(ctx, t, kStateAx + j);
							if (_symRef[r] != _tr.Sym()[r]) ++diff;
							++tot;
						}
				ch = (tot == 0u) ? 0.0f : ((float)diff / (float)tot);
			}
			_idch[_arm][_seed] = ch;
			LogA("[mlt] 🔩   %s 씨앗 %2u · 시험 MSE **%.5f** · ‖Δp‖/‖p‖ **%.4g** · ㈁대비 id변화 **%.3f**\n",
				_ArmName(), _seed, (double)mse, (double)_dp[_arm][_seed], (double)ch);
			_pending = false;
			_cor = 0u;
			if (++_arm < kArms) { _st = kEncInit; return; }
			_arm = 0u; _seedOk[_seed] = _finite; ++_seed; _st = kEncInit; return;
		}
		if (!_RenderPool(0u, kEncF, 2u)) return;
		_E.SetFrame(0u); _E.ClearExtDMag();
		if (!_E.Forward()) { _Fail("시험 forward"); return; }
		_wait = MLTEvalGate::kDelay; _pending = true;
	}

	static void _Summary()
	{
		double m[kArms], dp[kArms], mr = 0.0, mch = 0.0, g1 = 0.0;
		for (uint32 a = 0; a < kArms; ++a) { m[a] = 0.0; dp[a] = 0.0; }
		uint32 ok = 0u, surv = 0u;
		for (uint32 s = 0; s < kSeeds; ++s)
		{
			if (!_seedOk[s]) continue;
			++ok;
			for (uint32 a = 0; a < kArms; ++a) { m[a] += _mse[a][s]; dp[a] += _dp[a][s]; }
			mr += _ratioS[s]; mch += _idch[2][s]; g1 += _g1err[s];
			if (_mse[2][s] <= kSurvive * _mse[0][s]) ++surv;
		}
		if (ok > 0u)
		{
			for (uint32 a = 0; a < kArms; ++a) { m[a] /= ok; dp[a] /= ok; }
			mr /= ok; mch /= ok; g1 /= ok;
		}
		const bool alive = (surv >= kSignPass) && _finite;

		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🔩 **회차 67 · 인코더 주입 배관** — 읽은 씨앗 %u/%u\n", ok, kSeeds);
		LogA("[mlt] 🔩   **판정① 주입이 닿나** — 평균 오차 **%.3e**(문턱 %.0e) → %s\n",
			g1, (double)kGate1Tol, (g1 <= kGate1Tol) ? "통과" : "⛔");
		LogA("[mlt] 🔩   시험 재구성 MSE — ㈀ 얼림 **%.5f** · ㈁ 재구성만 **%.5f** · ㈂ **%.5f**\n",
			m[0], m[1], m[2]);
		LogA("[mlt] 🔩   **생존 관문** MSE(㈂) ≤ %.0f×MSE(㈀) — **%u/%u**(필요 %u) → %s\n",
			(double)kSurvive, surv, ok, kSignPass, alive ? "통과" : "⛔");
		LogA("[mlt] 🔩   눈금 — ‖Δp‖/‖p‖ ㈁ **%.4g** · ㈂ **%.4g** · ‖d재구성‖/‖d몸통‖ **%.4g**\n",
			dp[1], dp[2], mr);
		LogA("[mlt] 🔩   눈금 — ⭐ **㈁ 대비 ㈂ 의 활성 id 변화율 %.3f**(경험이 심볼 선택을 바꾼 몫)\n", mch);
		if (!alive)
			LogA("[mlt] 🔩   ⭐ 판정 = ⛔ **생존 실패** — `λ` 를 낮춰 **다시 등록**한다(죽은 팔의 눈금은 안 읽는다)\n");
		else
			LogA("[mlt] 🔩   ⭐ 판정 = ✅ **배관이 섰다** ⇒ 회차 68 = ㉣ 의 **표제**(차이의 존재)를 12씨앗·분할 반쪽으로\n");
		LogA("[mlt] 🔩   ⚠️ 밀기를 **%u그룹(%u문맥)**으로 좁혔다 — 등록문에 적은 예산이다\n", kPushGrp, kPushGrp * kGroup);
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		_E.Destroy(); _done = true;
	}

	static void _Fail(const char* why)
	{
		LogA("[mlt] 🔩 ⛔ %s (씨앗 %u · 팔 %u · 단계 %u · 그룹 %u/%u)\n", why, _seed, _arm, _st, _pg, _gGrp);
		_E.Destroy(); _done = true;
	}
};
