// mltp3k3.cw — 🔩 회차 72 · **몸통 기울기가 인코더를 바꾸나(끝점)** (`-mltp3k3`)
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 72 이다.**
// ⚠️ 상위 = **경험이 인코딩을 바꾸나** · **배관 회차**(연속 계수는 회차 71 심사가 초기화했다).
// ══════════════════════════════════════════════════════════════════════════════
//
// ⭐ 회차 71 의 심사가 `mltp3k0.cw`(회차 67·68)를 **버렸다**. 그 토대 위에 다시 짓는다 —
//   회차 70·71 이 **주입이 파라미터를 12~15% 바꾼다**를 12/12 로 세웠기 때문이다.
//
// ── 회차 67·68 과 무엇이 다른가 ──────────────────────────────────────────
//   팔 **둘**(셋 아님) · **1그룹 32프레임**(8그룹 256 아님) · **재수집 없음** ·
//   ⭐ **판정이 끝점**(`‖p(주입✓) − p(주입✗)‖ > 0`) — 회차 68 은 그것을 **눈금**에 두었고
//   그래서 자동 판정이 ✅ 를 찍었다(사람 심사가 뒤집었다).
//
// ⚠️ 연쇄법칙은 **회차 66 이 12/12 로 세운 그 식** 그대로다(고치지 않았다):
//   `∂L/∂pm_i = inv·g_i` · `i=m` 이면 `inv·(g_m − sign(pm_m)·S)`.
// ⚠️ 문턱이 **없다** — 회차 69·70·71 이 잡음 바닥 `0` 을 각각 12/12 로 세웠다.

using namespace PE;

class MLTP3K3
{
public:
	static void Tick(RHI* rhi)
	{
		if (_done || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltp3k3"))
		{
			LogA("[mlt] 🔩 회차 72는 **꺼져 있다**(`-mltp3k3`) — 몸통 기울기가 인코더를 바꾸나(끝점)\n");
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
	static constexpr uint32 kAllGrp = 32u;                          // 128문맥 / 4
	static constexpr uint32 kCand = MLTP2Cfg::kPatches * kLocal;    // 512
	static constexpr uint32 kNCtx = 128u, kTrainEpi = 1u;
	static constexpr uint32 kPoolSteps = kNCtx / kBatch;
	static constexpr uint32 kSteps = 400u, kPerTick = 4u;
	static constexpr uint32 kArms = 2u;                             // A 주입✗ · F 주입✓
	static constexpr uint32 kSignPass = 10u;

	enum { kEncInit, kEncTrain, kSettle, kGather, kBodyInit, kBodyTrain, kSweep, kScale, kPush, kReadP };

	inline static MLTP2Enc _E;
	inline static MLTModel _M;
	inline static MLTP3Ctx _tr;
	inline static bool _done = false, _banner = false, _encSetup = false;
	inline static bool _pending = false;
	inline static uint32 _seed = 0u, _st = kEncInit, _step = 0u, _arm = 0u, _wait = 0u;
	inline static uint32 _gGrp = 0u, _gIdx = 0u, _pf = 0u, _phase = 0u;
	inline static float  _scale = 1.0f, _gnorm = 0.0f;
	inline static bool   _ready = false;                            // `_gslot` 이 준비됐나
	inline static Array<float> _code, _norm, _dv, _ext, _dm, _gslot, _pr[kArms];
	inline static float _rel[kSeeds], _gn[kSeeds], _sc[kSeeds];
	inline static bool  _seedOk[kSeeds];

	static bool _Inject() { return _arm == 1u; }

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🔩 **회차 72 · 몸통 기울기가 인코더를 바꾸나(끝점)**(⚠️ 배관 회차)\n");
		LogA("[mlt] 🔩   팔 둘(주입✗ · 주입✓) · **1그룹 32프레임** · 재수집 없음 · 틱당 1프레임\n");
		LogA("[mlt] 🔩   ★ 표제 = `‖p_F − p_A‖ / ‖p_A‖ > 0` — ⭐ **끝점**(회차 68 은 이것을 눈금에 뒀다)\n");
		LogA("[mlt] 🔩   ⚠️ 문턱 없음 — 회차 69·70·71 이 잡음 바닥 0 을 각각 12/12 로 세웠다\n");
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
		if (!_RenderPool(0u, true)) return;
		_step = 0u; _st = kEncTrain;
	}

	// `pretrain` → 에피소드 0 · 아니면 코퍼스 그룹 `grp`(문맥 `grp·4 .. +3`)
	static bool _RenderPool(uint32 grp, bool pretrain)
	{
		Array<float> fr, tg; fr.Reset(0); tg.Reset(0);
		ImageFormat::Bitmap bmp; Bytes packed;
		if (pretrain)
		{
			MLTWorld w; w.Reset(_seed, 0u, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
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
		_wait = MLTEvalGate::kDelay; _st = kSettle;       // ⚠️ 리드백 규약
	}

	static void _AfterSettle()
	{
		// ⭐ `_gslot` 은 **팔 A 에서 한 번만** 만든다 — 인코더가 프리트레인 직후로 **같으므로**
		//   코퍼스도 몸통도 팔에 안 의존한다(다시 만들면 낭비다).
		if (!_ready)
		{
			_tr.SetSortById(true); _tr.Begin(kNCtx, kN);
			_gGrp = 0u; _gIdx = 0u; _pending = false; _st = kGather; return;
		}
		if (!_RenderPool(0u, false)) return;
		_phase = 0u; _st = kScale;
	}

	static void _Gather()
	{
		if (_pending)
		{
			Array<float> ids, mag;
			if (!_E.ReadAct(ids, mag) || ids.Count() != kCand) { _Fail("활성 리드백"); return; }
			_tr.StoreAct(_gGrp * kGroup + (_gIdx - 1u) / kTime, (_gIdx - 1u) % kTime, ids, mag, _norm);
			_pending = false;
		}
		if (_gIdx == 0u) { if (!_RenderPool(_gGrp, false)) return; }
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
			// ⭐ 눈금 — `‖_gslot‖`. ⚠️ 실패했을 때 *"정말 0 이었나"* 를 **바로 읽히게** 찍어 둔다.
			double s = 0.0;
			for (uint32 i = 0; i < _gslot.Count(); ++i) s += (double)_gslot[i] * _gslot[i];
			_gnorm = (float)Sqrt((float)s);
			_gn[_seed] = _gnorm;
			LogA("[mlt] 🔩   씨앗 %2u · 눈금 **‖_gslot‖ = %.4g**(0 이면 연쇄법칙이 아무것도 안 냈다)\n",
				_seed, (double)_gnorm);
			_ready = true; _gGrp = 0u;
			if (!_RenderPool(0u, false)) return;
			_phase = 0u; _st = kScale; return;
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

	// 그 프레임의 후보 기울기(주입 전 · 배율 없음). 프레임 `f` = `(ctx = f/kTime, t = f%kTime)`(그룹 0).
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

	// 배율 — 팔 A 의 **프레임 0** 에서 `0.5·‖dMag‖/‖ext_raw‖`(회차 70·71 과 같은 방식).
	static void _Scale()
	{
		if (_arm != 0u) { _pf = 0u; _st = kPush; return; }        // 팔 F 는 A 의 배율을 쓴다
		if (_phase == 0u)
		{
			_E.SetFrame(0u); _E.ClearExtDMag();
			if (!_E.Forward() || !_E.Backward()) { _Fail("배율용 fwd/bwd"); return; }
			_wait = MLTEvalGate::kDelay; _phase = 1u; return;
		}
		if (_wait > 0u) { --_wait; return; }
		if (!_E.ReadDMag(_dm)) { _Fail("배율용 dMag"); return; }
		_BuildRaw(0u);
		double a = 0.0, e = 0.0;
		for (uint32 c = 0; c < kCand; ++c) { a += (double)_dm[c] * _dm[c]; e += (double)_ext[c] * _ext[c]; }
		const float na = Sqrt((float)a), ne = Sqrt((float)e);
		_scale = (ne > 1.0e-20f) ? (0.5f * na / ne) : 0.0f;
		_sc[_seed] = _scale;
		LogA("[mlt] 🔩   씨앗 %2u · ‖dMag‖ %.4g · ‖ext_raw(f0)‖ %.4g ⇒ 배율 **%.4g**\n",
			_seed, (double)na, (double)ne, (double)_scale);
		_pf = 0u; _st = kPush;
	}

	static void _Push()
	{
		if (_pf >= kEncF) { _wait = MLTEvalGate::kDelay; _st = kReadP; return; }
		_E.SetFrame(_pf);
		if (!_E.Forward()) { _Fail("밀기 forward"); return; }
		if (_Inject())
		{
			_BuildRaw(_pf);
			for (uint32 c = 0; c < kCand; ++c) _ext.Data()[c] *= _scale;
			if (!_E.SetExtDMag(_ext)) { _Fail("주입"); return; }
		}
		else _E.ClearExtDMag();
		if (!_E.Backward() || !_E.AdamStep(1.0f)) { _Fail("밀기 bwd/adam"); return; }
		_E.ClearExtDMag();
		++_pf;                                                    // ⚠️ **틱당 1프레임**
	}

	static void _ReadP()
	{
		if (_wait > 0u) { --_wait; return; }
		if (!_E.ReadParams(_pr[_arm])) { _Fail("파라미터 리드백"); return; }
		if (++_arm < kArms) { _st = kEncInit; return; }
		_arm = 0u;
		double d = 0.0, s = 0.0;
		const uint32 n = (_pr[0].Count() < _pr[1].Count()) ? _pr[0].Count() : _pr[1].Count();
		for (uint32 i = 0; i < n; ++i)
		{
			const double e = (double)_pr[0][i] - (double)_pr[1][i];
			d += e * e; s += (double)_pr[0][i] * _pr[0][i];
		}
		_rel[_seed] = (float)(Sqrt((float)d) / (Sqrt((float)s) + 1.0e-20));
		_seedOk[_seed] = true;
		LogA("[mlt] 🔩   씨앗 %2u · ⭐ **‖p_F − p_A‖/‖p_A‖ = %.4g**(회차 71 의 시험벡터 판 = 0.1253)\n",
			_seed, (double)_rel[_seed]);
		++_seed; _ready = false; _st = kEncInit;
	}

	static void _Summary()
	{
		uint32 ok = 0u, pass = 0u;
		double mr = 0.0, mg = 0.0, ms = 0.0;
		for (uint32 s = 0; s < kSeeds; ++s)
		{
			if (!_seedOk[s]) continue;
			++ok; mr += _rel[s]; mg += _gn[s]; ms += _sc[s];
			if (_rel[s] > 0.0f) ++pass;
		}
		if (ok > 0u) { mr /= ok; mg /= ok; ms /= ok; }
		const bool p1 = (pass >= kSignPass);

		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🔩 **회차 72 · 몸통 기울기가 인코더를 바꾸나** — 읽은 씨앗 %u/%u\n", ok, kSeeds);
		LogA("[mlt] 🔩   눈금 — ‖_gslot‖ **%.4g** · 배율 **%.4g**\n", mg, ms);
		LogA("[mlt] 🔩   ⭐ **‖p_F − p_A‖/‖p_A‖ 평균 %.4g**(회차 71 의 시험벡터 판 **0.1253**, 비 **%.3g**)\n",
			mr, (mr > 0.0) ? (mr / 0.1253) : 0.0);
		LogA("[mlt] 🔩   **표제** `> 0` — **%u/%u**(필요 %u · ⭐ 문턱 없음)\n", pass, kSeeds, kSignPass);
		if (p1)
			LogA("[mlt] 🔩   ⭐ 판정 = ✅ **몸통 기울기가 인코더를 실제로 바꾼다** ⇒ 회차 73 = 생존 관문 + ㉣ 표제\n");
		else
			LogA("[mlt] 🔩   ⭐ 판정 = ⛔⛔ **몸통 기울기만 유독 0 이다**(시험 벡터는 12/12 로 된다) ⇒ 위 `‖_gslot‖` 을 읽어라\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		_E.Destroy(); _done = true;
	}

	static void _Fail(const char* why)
	{
		LogA("[mlt] 🔩 ⛔ %s (씨앗 %u · 팔 %u · 단계 %u · 프레임 %u · 그룹 %u)\n",
			why, _seed, _arm, _st, _pf, _gGrp);
		_E.Destroy(); _done = true;
	}
};
