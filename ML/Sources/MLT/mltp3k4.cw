// mltp3k4.cw — ⏳ 회차 73 · **㉣ 의 표제 — 「차이의 존재」** (`-mltp3k4`)
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 73 이다.**
// ⭐ 상위 = **경험이 인코딩을 바꾸나** · ⭐ **판정 회차다**(회차 64 이후 이 캔버스의 **첫 판정**).
// ══════════════════════════════════════════════════════════════════════════════
//
// ⭐ `MLT.md` 의 P3 ㉣ 이 요구하는 것 그대로:
//   *"㈀ 얼림 ↔ ㈁ 같이 학습. **그 차이가 「경험이 인코딩을 바꾼 양」**이고, **0 이면 경험 학습이
//   아니다**. ⚠️ 이 칸은 **성능 비교가 아니다** — 차이의 **존재**가 판정이다."*
//
// ── 팔 셋 ────────────────────────────────────────────────────────────────
//   ㈀ **얼림**(안 민다) · ㈁ **재구성만**(민다·주입✗) · ㈂ **재구성+몸통**(민다·주입✓)
//   ⚠️ ㈁ 이 없으면 *"몸통 때문"* 과 *"더 밀었기 때문"* 이 안 갈린다.
//
// ── ⚠️⚠️ 생존 관문이 표제보다 먼저다 ─────────────────────────────────────
//   `MSE(㈂) ≤ 2 × MSE(㈀)`(에피소드 **901** — 학습에 안 쓴 것). 회차 40·41 이 이 관문으로 두 번
//   붙잡았다. ***죽은 팔의 숫자는 어느 갈래에서도 효과량으로 안 읽는다.***
//
// ⭐ 배율은 **32프레임 전체 평균**이다 — 회차 72 의 눈금이 *"프레임 0 하나로 잡으면 60배 널뛴다"*
//   를 보였다(그 회차의 표제는 이미 통과했고, 이것은 **다음 회차의 설계**를 고친 것이다).

using namespace PE;

class MLTP3K4
{
public:
	static void Tick(RHI* rhi)
	{
		if (_done || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltp3k4"))
		{
			LogA("[mlt] ⏳ 회차 73은 **꺼져 있다**(`-mltp3k4`) — ㉣ 의 표제(차이의 존재)\n");
			_done = true; return;
		}
		if (!_banner) { _Banner(); _banner = true; }
		if (_seed >= kSeeds) { _Summary(); return; }
		switch (_st)
		{
		case kEncInit:  _EncBegin(rhi); return;
		case kEncTrain: _EncTrain();    return;
		case kSettle:   if (_wait > 0u) { --_wait; } else _AfterSettle(); return;
		case kGather:   _Gather();      return;
		case kBodyInit: _BodyBegin(rhi); return;
		case kBodyTrain:_BodyTrain();   return;
		case kSweep:    _Sweep();       return;
		case kScale:    _Scale();       return;
		case kPush:     _Push();        return;
		case kAfter:    _After();       return;
		case kMse:      _Mse();         return;
		case kReadP:    _ReadP();       return;
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
	static constexpr uint32 kGroup = kEncF / kTime;                 // 4 문맥
	static constexpr uint32 kAllGrp = 32u;
	static constexpr uint32 kCand = MLTP2Cfg::kPatches * kLocal;    // 512
	static constexpr uint32 kNCtx = 128u, kTrainEpi = 1u, kTestEpi = 901u;
	static constexpr uint32 kPoolSteps = kNCtx / kBatch;
	static constexpr uint32 kSteps = 400u, kPerTick = 4u;
	static constexpr uint32 kArms = 3u;                             // ㈀ ㈁ ㈂
	static constexpr uint32 kSignPass = 10u;
	static constexpr float  kLamRel = 0.5f, kSurvive = 2.0f;

	enum { kEncInit, kEncTrain, kSettle, kGather, kBodyInit, kBodyTrain, kSweep,
	       kScale, kPush, kAfter, kMse, kReadP };

	inline static MLTP2Enc _E;
	inline static MLTModel _M;
	inline static MLTP3Ctx _tr;
	inline static bool _done = false, _banner = false, _encSetup = false, _finite = true;
	inline static bool _pending = false, _ready = false;
	inline static uint32 _seed = 0u, _st = kEncInit, _step = 0u, _arm = 0u, _wait = 0u;
	inline static uint32 _gGrp = 0u, _gIdx = 0u, _pf = 0u, _phase = 0u;
	inline static float  _scale = 1.0f;
	inline static Array<float> _code, _norm, _dv, _ext, _dm, _gslot, _pr[kArms];
	inline static Array<float> _idsRef;         // 그룹 0 의 32프레임 × 512 후보 id(밀기 **전**)
	inline static double _sumD = 0.0, _sumE = 0.0;
	// 결과
	inline static float _mse[kArms][kSeeds], _idch[kArms][kSeeds];
	inline static float _rel[kSeeds], _relA[kSeeds];
	inline static bool  _seedOk[kSeeds];

	static bool _Push2() { return _arm == 2u; }                     // ㈂ 만 주입
	static bool _Moves() { return _arm >= 1u; }                     // ㈁㈂ 는 민다
	static const char* _ArmName()
	{ return (_arm == 0u) ? "㈀ 얼림" : ((_arm == 1u) ? "㈁ 재구성만" : "㈂ 재구성+몸통"); }

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] ⏳ **회차 73 · ㉣ 의 표제 — 「차이의 존재」**(⭐ **판정 회차**)\n");
		LogA("[mlt] ⏳   팔 셋 ㈀ 얼림 · ㈁ 재구성만 · ㈂ 재구성+몸통 · 1그룹 32프레임 · 틱당 1\n");
		LogA("[mlt] ⏳   ★ 표제 = `‖p(㈂)−p(㈁)‖/‖p(㈁)‖ > 0` — ⚠️ **성능 비교가 아니다**(㉣ 의 그 문장)\n");
		LogA("[mlt] ⏳   ⚠️⚠️ **생존 관문이 먼저다** — `MSE(㈂) ≤ %.0f×MSE(㈀)`(에피소드 %u · 회차 40·41 의 교훈)\n",
			(double)kSurvive, kTestEpi);
		LogA("[mlt] ⏳   ⭐ 배율 = **32프레임 평균**(회차 72 의 눈금이 「프레임 0 하나」를 죽였다)\n");
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
		if (!_RenderPool(0u, 0u)) return;
		_step = 0u; _st = kEncTrain;
	}

	// `mode`: 0 = 프리트레인(에피소드 0) · 1 = 코퍼스 그룹 `grp` · 2 = 시험(에피소드 901)
	static bool _RenderPool(uint32 grp, uint32 mode)
	{
		Array<float> fr, tg; fr.Reset(0); tg.Reset(0);
		ImageFormat::Bitmap bmp; Bytes packed;
		if (mode != 1u)
		{
			MLTWorld w; w.Reset(_seed, (mode == 0u) ? 0u : kTestEpi,
				MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
			for (uint32 f = 0; f < kEncF; ++f)
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
					if (!_ready) _tr.StoreState(ctx, t, w.State());
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
		_wait = MLTEvalGate::kDelay; _st = kSettle;
	}

	static void _AfterSettle()
	{
		if (!_ready)                                   // 팔 ㈀ — 코퍼스·몸통·`_gslot` 을 한 번만 만든다
		{
			_tr.SetSortById(true); _tr.Begin(kNCtx, kN);
			_idsRef.Reset(0);
			for (uint32 i = 0; i < kEncF * kCand; ++i) _idsRef.Add(-1.0f);
			_gGrp = 0u; _gIdx = 0u; _pending = false; _st = kGather; return;
		}
		if (!_RenderPool(0u, 1u)) return;              // 그룹 0
		_pf = 0u; _phase = 0u;
		_st = (_arm == 1u) ? kScale : kPush;           // 배율은 ㈁ 에서 한 번 잡는다
	}

	static void _Gather()
	{
		if (_pending)
		{
			Array<float> ids, mag;
			if (!_E.ReadAct(ids, mag) || ids.Count() != kCand) { _Fail("활성 리드백"); return; }
			const uint32 f = _gIdx - 1u;
			_tr.StoreAct(_gGrp * kGroup + f / kTime, f % kTime, ids, mag, _norm);
			// ⭐ 그룹 0 의 id 를 **밀기 전 기준**으로 남긴다(눈금 — 심볼 선택이 바뀌나).
			if (_gGrp == 0u) for (uint32 c = 0; c < kCand; ++c) _idsRef.Data()[f * kCand + c] = ids[c];
			_pending = false;
		}
		if (_gIdx == 0u) { if (!_RenderPool(_gGrp, 1u)) return; }
		if (_gIdx < kEncF)
		{
			_E.SetFrame(_gIdx);
			if (!_E.Forward()) { _Fail("문맥 forward"); return; }
			++_gIdx; _pending = true; return;
		}
		_gIdx = 0u;
		if (++_gGrp < kAllGrp) return;
		_gGrp = 0u; _st = kBodyInit;
	}

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
			_gslot.Reset(0);
			for (uint32 i = 0; i < kNCtx * kTime * kSlots; ++i) _gslot.Add(0.0f);
			_gGrp = 0u; _pending = false; _st = kSweep; return;
		}
		for (uint32 i = 0; i < kPerTick && _step < kSteps; ++i)
		{
			_M.SelectStep(_step % kPoolSteps);
			if (!_M.Forward() || !_M.Backward() || !_M.AdamStep(1.0f)) { _Fail("몸통 스텝"); return; }
			++_step;
		}
	}

	static void _Sweep()
	{
		if (_pending)
		{
			if (_wait > 0u) { --_wait; return; }
			if (!_M.ReadDVal(_dv)) { _Fail("dVal 리드백"); return; }
			for (uint32 b = 0; b < kBatch; ++b)
				for (uint32 t = 0; t < kTime; ++t) _Chain(_gGrp * kBatch + b, b, t);
			_pending = false; ++_gGrp;
		}
		if (_gGrp >= kPoolSteps)
		{
			_ready = true; _gGrp = 0u; _st = kMse; return;    // ㈀ 은 밀지 않는다 ⇒ 곧바로 측정
		}
		_M.SelectStep(_gGrp);
		if (!_M.Forward() || !_M.Backward()) { _Fail("dVal fwd/bwd"); return; }
		_wait = MLTEvalGate::kDelay; _pending = true;
	}

	// ⚠️ 회차 66 이 12/12 로 세운 식 — 고치지 않았다.
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

	static void _BuildRaw(uint32 f)
	{
		_ext.Reset(0);
		for (uint32 c = 0; c < kCand; ++c) _ext.Add(0.0f);
		const uint32 ctx = f / kTime, t = f % kTime;
		if (ctx >= kNCtx) return;
		for (uint32 j = 0; j < kSlots; ++j)
		{
			const uint32 c = _tr.Cand(ctx, t, j);
			if (c >= kCand) continue;
			_ext.Data()[c] += _gslot[(ctx * kTime + t) * kSlots + j];
		}
	}

	// ⭐ 배율 — **32프레임 전체 평균**. ⚠️ `AdamStep` 을 안 부르므로 파라미터를 안 건드린다.
	static void _Scale()
	{
		if (_phase == 0u)
		{
			if (_pf == 0u) { _sumD = 0.0; _sumE = 0.0; }
			if (_pf >= kEncF)
			{
				const double md = _sumD / (double)kEncF, me = _sumE / (double)kEncF;
				_scale = (me > 1.0e-20) ? (float)((double)kLamRel * md / me) : 0.0f;
				LogA("[mlt] ⏳   씨앗 %2u · 32프레임 평균 ‖dMag‖ %.4g · ‖ext_raw‖ %.4g ⇒ 배율 **%.4g**\n",
					_seed, md, me, (double)_scale);
				_pf = 0u; _st = kPush; return;
			}
			_E.SetFrame(_pf); _E.ClearExtDMag();
			if (!_E.Forward() || !_E.Backward()) { _Fail("배율용 fwd/bwd"); return; }
			_wait = MLTEvalGate::kDelay; _phase = 1u; return;
		}
		if (_wait > 0u) { --_wait; return; }
		if (!_E.ReadDMag(_dm)) { _Fail("배율용 dMag"); return; }
		double a = 0.0, e = 0.0;
		_BuildRaw(_pf);
		for (uint32 c = 0; c < kCand; ++c) { a += (double)_dm[c] * _dm[c]; e += (double)_ext[c] * _ext[c]; }
		_sumD += Sqrt((float)a); _sumE += Sqrt((float)e);
		++_pf; _phase = 0u;
	}

	static void _Push()
	{
		if (_pf >= kEncF) { _pf = 0u; _phase = 0u; _st = kAfter; return; }
		_E.SetFrame(_pf);
		if (!_E.Forward()) { _Fail("밀기 forward"); return; }
		if (_Push2())
		{
			_BuildRaw(_pf);
			for (uint32 c = 0; c < kCand; ++c) _ext.Data()[c] *= _scale;
			if (!_E.SetExtDMag(_ext)) { _Fail("주입"); return; }
		}
		else _E.ClearExtDMag();
		if (!_E.Backward() || !_E.AdamStep(1.0f)) { _Fail("밀기 bwd/adam"); return; }
		_E.ClearExtDMag();
		++_pf;                                          // ⚠️ **틱당 1프레임**
	}

	// 눈금 — 민 뒤 그룹 0 을 다시 훑어 **후보 자리의 id 가 바뀐 비율**을 센다.
	//   ⚠️ `_tr` 을 안 건드린다(㈂ 의 밀기가 그것을 쓰므로).
	static void _After()
	{
		if (_phase == 1u)
		{
			if (_wait > 0u) { --_wait; return; }
			Array<float> ids, mag;
			if (!_E.ReadAct(ids, mag) || ids.Count() != kCand) { _Fail("사후 활성 리드백"); return; }
			for (uint32 c = 0; c < kCand; ++c)
			{ ++_chTot; if (ids[c] != _idsRef[_pf * kCand + c]) ++_chDiff; }
			++_pf; _phase = 0u;
		}
		if (_pf >= kEncF)
		{
			_idch[_arm][_seed] = (_chTot == 0u) ? 0.0f : ((float)_chDiff / (float)_chTot);
			_chTot = 0u; _chDiff = 0u; _pf = 0u; _st = kMse; return;
		}
		_E.SetFrame(_pf); _E.ClearExtDMag();
		if (!_E.Forward()) { _Fail("사후 forward"); return; }
		_wait = MLTEvalGate::kDelay; _phase = 1u;
	}
	inline static uint32 _chTot = 0u, _chDiff = 0u;

	static void _Mse()
	{
		if (_pending)
		{
			if (_wait > 0u) { --_wait; return; }
			float mse = 0.0f; bool fin = true;
			if (!_E.ReadMse(mse, fin)) { _Fail("시험 MSE"); return; }
			if (!fin) _finite = false;
			_mse[_arm][_seed] = mse;
			_pending = false;
			_wait = MLTEvalGate::kDelay; _st = kReadP; return;
		}
		if (!_RenderPool(0u, 2u)) return;
		_E.SetFrame(0u); _E.ClearExtDMag();
		if (!_E.Forward()) { _Fail("시험 forward"); return; }
		_wait = MLTEvalGate::kDelay; _pending = true;
	}

	static void _ReadP()
	{
		if (_wait > 0u) { --_wait; return; }
		if (!_E.ReadParams(_pr[_arm])) { _Fail("파라미터 리드백"); return; }
		LogA("[mlt] ⏳   %s 씨앗 %2u · 시험 MSE **%.5f** · id 변화율 **%.4f**\n",
			_ArmName(), _seed, (double)_mse[_arm][_seed], (double)_idch[_arm][_seed]);
		if (++_arm < kArms) { _st = kEncInit; return; }
		_arm = 0u; _Judge();
	}

	static float _Rel(const Array<float>& base, const Array<float>& x)
	{
		const uint32 n = (base.Count() < x.Count()) ? base.Count() : x.Count();
		double d = 0.0, s = 0.0;
		for (uint32 i = 0; i < n; ++i)
		{
			const double e = (double)base[i] - (double)x[i];
			d += e * e; s += (double)base[i] * base[i];
		}
		return (float)(Sqrt((float)d) / (Sqrt((float)s) + 1.0e-20));
	}

	static void _Judge()
	{
		_rel[_seed]  = _Rel(_pr[1], _pr[2]);          // ⭐ 표제 — ㈁ 대비 ㈂
		_relA[_seed] = _Rel(_pr[0], _pr[1]);          // 눈금 — 얼림 대비 ㈁(*"더 밀었기 때문"* 의 크기)
		_seedOk[_seed] = _finite;
		LogA("[mlt] ⏳   씨앗 %2u · ⭐ **‖p㈂−p㈁‖/‖p㈁‖ = %.4g** · 눈금 ‖p㈁−p㈀‖/‖p㈀‖ = %.4g\n",
			_seed, (double)_rel[_seed], (double)_relA[_seed]);
		++_seed; _ready = false; _st = kEncInit;
	}

	static void _Summary()
	{
		uint32 ok = 0u, surv = 0u, pass = 0u;
		double m[kArms], ch[kArms], mr = 0.0, ma = 0.0;
		for (uint32 a = 0; a < kArms; ++a) { m[a] = 0.0; ch[a] = 0.0; }
		for (uint32 s = 0; s < kSeeds; ++s)
		{
			if (!_seedOk[s]) continue;
			++ok;
			for (uint32 a = 0; a < kArms; ++a) { m[a] += _mse[a][s]; ch[a] += _idch[a][s]; }
			mr += _rel[s]; ma += _relA[s];
			if (_mse[2][s] <= kSurvive * _mse[0][s]) ++surv;
			if (_rel[s] > 0.0f) ++pass;
		}
		if (ok > 0u)
		{
			for (uint32 a = 0; a < kArms; ++a) { m[a] /= ok; ch[a] /= ok; }
			mr /= ok; ma /= ok;
		}
		const bool alive = (surv >= kSignPass) && _finite;
		const bool p1 = (pass >= kSignPass);

		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] ⏳ **회차 73 · ㉣ 차이의 존재** — 읽은 씨앗 %u/%u\n", ok, kSeeds);
		LogA("[mlt] ⏳   시험 재구성 MSE — ㈀ **%.5f** · ㈁ **%.5f** · ㈂ **%.5f**\n", m[0], m[1], m[2]);
		LogA("[mlt] ⏳   **생존 관문**(먼저) `MSE(㈂) ≤ %.0f×MSE(㈀)` — **%u/%u**(필요 %u) → %s\n",
			(double)kSurvive, surv, ok, kSignPass, alive ? "통과" : "⛔");
		LogA("[mlt] ⏳   ⭐ **표제** `‖p㈂−p㈁‖/‖p㈁‖ = %.4g` · `> 0` **%u/%u**(필요 %u · 문턱 없음)\n",
			mr, pass, kSeeds, kSignPass);
		LogA("[mlt] ⏳   눈금 — ‖p㈁−p㈀‖/‖p㈀‖ **%.4g**(*더 밀었기 때문*의 크기) · id 변화율 ㈁ **%.4f** ↔ ㈂ **%.4f**\n",
			ma, ch[1], ch[2]);
		if (!alive)
			LogA("[mlt] ⏳   ⭐ 판정 = ⛔ **생존 실패** — `λ` 를 낮춰 **다시 등록**한다(죽은 팔의 눈금은 안 읽는다)\n");
		else if (p1)
			LogA("[mlt] ⏳   ⭐ 판정 = ✅✅ **㉣ 통과 — 경험이 인코딩을 바꾼다**(차이가 존재한다)\n");
		else
			LogA("[mlt] ⏳   ⭐ 판정 = ⛔ **㉣ 실패 — 차이가 0 이다** ⇒ *경험 학습이 아니다*(㉣ 이 적어 둔 그 갈래)\n");
		LogA("[mlt] ⏳   ⚠️ 1그룹 32프레임 · 교대 1회의 진단이다 — 절대 성능으로 인용하지 않는다\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		_E.Destroy(); _done = true;
	}

	static void _Fail(const char* why)
	{
		LogA("[mlt] ⏳ ⛔ %s (씨앗 %u · 팔 %u · 단계 %u · 프레임 %u · 그룹 %u)\n",
			why, _seed, _arm, _st, _pf, _gGrp);
		_E.Destroy(); _done = true;
	}
};
