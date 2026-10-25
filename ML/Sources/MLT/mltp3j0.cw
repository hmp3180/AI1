// mltp3j0.cw — ⏳ 회차 65 · **판정 ② · `dVal → dMag` 연쇄법칙이 맞나** (`-mltp3j0`)
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 65 이다.**
// ⚠️ 상위 캔버스 = **경험이 인코딩을 바꾸나**. ⚠️⚠️ **판정 회차가 아니다**(배관·판정 도구를
//   세우는 회차) — 규율 6 의 계수 규칙을 이 회차를 **열기 전에** 등록문에 못 박았다.
// ══════════════════════════════════════════════════════════════════════════════
//
// ⭐ 회차 63 이 설계한 배관의 심장은 **CPU 연쇄법칙 한 줄**이다. 그것이 틀리면 그 뒤가 전부 틀린다.
//   ★ 이 저장소의 계약: ***판정 ①② 가 선 커밋에서만 학습을 켠다***(회차 33·34 의 순서).
//   ⚠️ 그리고 회차 40 이 덧붙인 것: **판정 ② 통과 ≠ 안정적 학습 방향**(그것은 회차 66 의 생존 관문).
//
// ── 계약(등록문과 같은 식) ────────────────────────────────────────────────
//   `inv = 1/maxAbs` · `val_j = pm_j · inv` · `g_j = ∂L/∂val_j`(몸통의 `dVal`) · `m = argmax |pm_j|`
//     `S = Σ_j g_j · val_j`
//     `∂L/∂pm_i = inv · g_i`                           (i ≠ m)
//     `∂L/∂pm_m = inv · ( g_m − sign(pm_m) · S )`      (i = m)
//   ⚠️⚠️ **선택(`q`)과 id 정렬은 stop-gradient** — 미분하지 않는다(회차 63 의 *"값 경로만"*).
//   ★ 그래도 **선택은 간접적으로 바뀐다**(다음 수집에서 `q` 가 다른 후보를 고른다).

using namespace PE;

class MLTP3J0
{
public:
	static void Tick(RHI* rhi)
	{
		if (_done || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltp3j0"))
		{
			LogA("[mlt] ⏳ 회차 65는 **꺼져 있다**(`-mltp3j0`) — 판정 ②: dVal→dMag 연쇄법칙\n");
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
		if (_st == kBodyTrain) { _BodyTrain(); return; }
		if (_st == kGrad)     { _GradPass(); return; }
		if (_st == kCheck)    { _Check(); return; }
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
	static constexpr uint32 kCandidates = MLTP2Cfg::kPatches * kLocal;
	static constexpr uint32 kNCtx = 128u;
	static constexpr uint32 kTrainEpi = 1u;
	static constexpr uint32 kPoolSteps = kNCtx / kBatch;
	static constexpr uint32 kGroup = kEncF / kTime;
	static constexpr uint32 kSteps = 800u, kPerTick = 4u;
	static constexpr uint32 kSignPass = 10u;
	static constexpr uint32 kProbes = 8u;         // 씨앗마다 재는 자리
	static constexpr uint32 kMinUse = 4u;         // 쓸 수 있는 자리의 하한
	static constexpr float  kTol = 0.10f;         // 정규화 오차 문턱(중앙값)
	static constexpr float  kDead = 1.0e-6f;      // 둘 다 이보다 작으면 버린다
	static constexpr float  kEpsRel = 0.05f, kEpsMin = 1.0e-3f;

	enum { kEncInit, kEncTrain, kGather, kQuiesce, kBodyInit, kBodyTrain, kGrad, kCheck };

	inline static MLTP2Enc _E;
	inline static MLTModel _M;
	inline static MLTP3Ctx _tr;
	inline static bool _done = false, _banner = false, _encSetup = false, _finite = true;
	inline static bool _pending = false;
	inline static uint32 _seed = 0u, _st = kEncInit, _step = 0u;
	inline static uint32 _gGrp = 0u, _gIdx = 0u;
	inline static Array<float> _code, _norm, _dv;
	// 재는 자리
	inline static uint32 _pk[kProbes], _pb[kProbes], _pt[kProbes], _pj[kProbes];
	inline static float  _ana[kProbes], _num[kProbes], _err[kProbes];
	inline static uint8  _use[kProbes];
	inline static uint32 _pi = 0u, _phase = 0u, _wait = 0u;
	inline static float  _plus = 0.0f, _saveMag = 0.0f, _eps = 0.0f;
	inline static uint32 _mArg[kProbes];          // 그 자리가 `argmax` 였나(눈금)
	// 결과
	inline static float _med[kSeeds];
	inline static uint32 _used[kSeeds];
	inline static bool  _seedOk[kSeeds];

	inline static uint32 _qWait = 0u;
	static void _ToBody() { _qWait = MLTEvalGate::kDelay; _st = kQuiesce; }

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] ⏳ **회차 65 · 판정 ② — `dVal → dMag` 연쇄법칙이 맞나**\n");
		LogA("[mlt] ⏳   ⚠️ **판정 회차가 아니다**(배관/판정 도구) — 규율 6 계수 규칙은 등록문에 못 박았다\n");
		LogA("[mlt] ⏳   해석값 ↔ **중앙차분**(ε = max(%.2f·|pm|, %.0e)) · 자리 %u개 · 문턱 중앙값 %.2f\n",
			(double)kEpsRel, (double)kEpsMin, kProbes, (double)kTol);
		LogA("[mlt] ⏳   ⚠️ 선택(`q`)과 id 정렬은 **stop-gradient** — STE 를 쓰지 않는다\n");
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
		_tr.SetSortById(true); _tr.Begin(kNCtx, kN);
		_gGrp = 0u; _gIdx = 0u; _pending = false; _st = kGather;
	}

	static void _Gather()
	{
		if (_pending)
		{
			Array<float> ids, mag;
			if (!_E.ReadAct(ids, mag) || ids.Count() != kCandidates) { _Fail("활성 리드백"); return; }
			_tr.StoreAct(_gGrp * kGroup + (_gIdx - 1u) / kTime, (_gIdx - 1u) % kTime, ids, mag, _norm);
			_pending = false;
		}
		if (_gIdx == 0u)
		{
			Array<float> fr, tg; fr.Reset(0); tg.Reset(0);
			ImageFormat::Bitmap bmp; Bytes packed;
			for (uint32 g = 0; g < kGroup; ++g)
			{
				const uint32 ctx = _gGrp * kGroup + g;
				MLTWorld w; w.Reset(_seed, kTrainEpi + ctx, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
				for (uint32 t = 0; t < kTime; ++t)
				{
					w.Step();
					if (!w.Render(bmp) || !MLTWorld::Pack(bmp, nullptr, packed)) { _Fail("Render/Pack(문맥)"); return; }
					MLTP2Enc::AppendFrame(fr, tg, (const uint8*)packed.GetData());
					_tr.StoreState(ctx, t, w.State());
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
		if (++_gGrp * kGroup >= kNCtx) { _gGrp = 0u; _PickProbes(); _ToBody(); }
	}

	// ⚠️ 자리는 **정해진 해시**로 고른다(무작위가 아니다 — 재현된다).
	static void _PickProbes()
	{
		for (uint32 p = 0; p < kProbes; ++p)
		{
			const uint32 h = MLTWorld::Hash(_seed * 3571u + p * 97u, MLTSalt::Start, 77u);
			_pk[p] = h % kPoolSteps;
			_pb[p] = (h >> 5) % kBatch;
			_pt[p] = (h >> 9) % kTime;
			_pj[p] = (h >> 13) % kSlots;
			_use[p] = 0u; _ana[p] = 0.0f; _num[p] = 0.0f; _err[p] = 0.0f; _mArg[p] = 0u;
		}
	}

	// ══════════════════════════════════════════════════════════════════
	static void _BodyBegin(RHI* rhi)
	{
		if (!_M.Setup(rhi, kStateAx + kN, kN, kAxes, kTime)) { _Fail("몸통 준비"); return; }
		if (!_UploadTrain()) return;
		_step = 0u; _st = kBodyTrain;
	}

	static bool _UploadTrain()
	{
		if (!_M.UploadPool(_tr.Val(), _tr.Tgt(), kPoolSteps) || !_M.UploadSymbolPool(_tr.Sym(), kPoolSteps))
		{ _Fail("학습 풀 업로드"); return false; }
		return true;
	}

	static void _BodyTrain()
	{
		if (_step >= kSteps)
		{
			// ⭐ 학습이 끝났다 — 이제 자리마다 `dVal` 을 읽어야 한다. 풀스텝별로 한 번씩.
			_pi = 0u; _phase = 0u; _st = kGrad; return;
		}
		for (uint32 i = 0; i < kPerTick && _step < kSteps; ++i)
		{
			_M.SelectStep(_step % kPoolSteps);
			if (!_M.Forward() || !_M.Backward() || !_M.AdamStep(1.0f)) { _Fail("몸통 스텝"); return; }
			++_step;
		}
	}

	// ── 해석값: 그 자리 풀스텝의 `dVal` 을 읽어 연쇄법칙을 적용한다 ──────────
	static void _GradPass()
	{
		if (_phase == 1u)
		{
			if (_wait > 0u) { --_wait; return; }
			if (!_M.ReadDVal(_dv)) { _Fail("dVal 리드백"); return; }
			_Analytic(_pi);
			_phase = 0u;
			if (++_pi >= kProbes) { _pi = 0u; _phase = 0u; _st = kCheck; return; }
			return;
		}
		_M.SelectStep(_pk[_pi]);
		if (!_M.Forward() || !_M.Backward()) { _Fail("dVal forward/backward"); return; }
		_wait = MLTEvalGate::kDelay; _phase = 1u;
	}

	static void _Analytic(uint32 p)
	{
		const uint32 ctx = _pk[p] * kBatch + _pb[p], t = _pt[p], j = _pj[p];
		if (_tr.Cand(ctx, t, j) == MLTP3Ctx::kNoCand) { _use[p] = 0u; return; }
		const float inv = _tr.Inv(ctx, t);
		// `S = Σ_j g_j · val_j` · `m = argmax |pm_j|`
		double S = 0.0; uint32 m = 0u; float best = -1.0f;
		for (uint32 q = 0; q < kSlots; ++q)
		{
			const uint32 row = _pb[p] * kCtxRow + t * kAxes + (kStateAx + q);
			const float g = (row < _dv.Count()) ? _dv[row] : 0.0f;
			const float v = _tr.Val()[MLTP3Ctx::Row(ctx, t, kStateAx + q)];
			S += (double)g * (double)v;
			const float a = Abs(_tr.RawMag(ctx, t, q));
			if (a > best) { best = a; m = q; }
		}
		const uint32 rowJ = _pb[p] * kCtxRow + t * kAxes + (kStateAx + j);
		const float gj = (rowJ < _dv.Count()) ? _dv[rowJ] : 0.0f;
		const float pmj = _tr.RawMag(ctx, t, j);
		_mArg[p] = (j == m) ? 1u : 0u;
		if (j == m)
		{
			const float sg = (pmj >= 0.0f) ? 1.0f : -1.0f;
			_ana[p] = inv * (gj - sg * (float)S);
		}
		else _ana[p] = inv * gj;
		_use[p] = 1u;
	}

	// ── 수치값: `pm_j` 를 ±ε 흔들고 그 (문맥,시각)을 다시 정규화해 손실을 두 번 잰다 ──
	static void _Check()
	{
		if (_pi >= kProbes) { _Judge(); return; }
		if (_use[_pi] == 0u) { ++_pi; return; }
		const uint32 ctx = _pk[_pi] * kBatch + _pb[_pi], t = _pt[_pi], j = _pj[_pi];
		if (_phase == 0u)
		{
			_saveMag = _tr.RawMag(ctx, t, j);
			_eps = Abs(_saveMag) * kEpsRel;
			if (_eps < kEpsMin) _eps = kEpsMin;
			_tr.SetRawMag(ctx, t, j, _saveMag + _eps);
			_tr.RewriteVals(ctx, t);
			if (!_UploadTrain()) return;
			_M.SelectStep(_pk[_pi]);
			if (!_M.Forward()) { _Fail("중앙차분 forward(+)"); return; }
			_wait = MLTEvalGate::kDelay; _phase = 1u; return;
		}
		if (_phase == 1u)
		{
			if (_wait > 0u) { --_wait; return; }
			if (!_M.ReadLoss(_plus)) { _Fail("중앙차분 손실(+)"); return; }
			if (!(_plus == _plus) || _plus > 1.0e30f) _finite = false;
			_tr.SetRawMag(ctx, t, j, _saveMag - _eps);
			_tr.RewriteVals(ctx, t);
			if (!_UploadTrain()) return;
			_M.SelectStep(_pk[_pi]);
			if (!_M.Forward()) { _Fail("중앙차분 forward(−)"); return; }
			_wait = MLTEvalGate::kDelay; _phase = 2u; return;
		}
		if (_wait > 0u) { --_wait; return; }
		float minus = 0.0f;
		if (!_M.ReadLoss(minus)) { _Fail("중앙차분 손실(−)"); return; }
		if (!(minus == minus) || minus > 1.0e30f) _finite = false;
		// 되돌린다 — ⚠️ 안 되돌리면 다음 자리가 오염된다.
		_tr.SetRawMag(ctx, t, j, _saveMag);
		_tr.RewriteVals(ctx, t);
		if (!_UploadTrain()) return;
		_num[_pi] = (_plus - minus) / (2.0f * _eps);
		const float a = Abs(_ana[_pi]), n = Abs(_num[_pi]);
		if (a < kDead && n < kDead) _use[_pi] = 0u;          // 뜻이 없는 자리는 버린다
		else _err[_pi] = Abs(_ana[_pi] - _num[_pi]) / (a + n + 1.0e-8f);
		_phase = 0u; ++_pi;
	}

	static void _Judge()
	{
		float e[kProbes]; uint32 n = 0u, nArg = 0u;
		double eArg = 0.0, eOth = 0.0; uint32 cArg = 0u, cOth = 0u;
		for (uint32 p = 0; p < kProbes; ++p)
		{
			if (_use[p] == 0u) continue;
			e[n++] = _err[p];
			if (_mArg[p] != 0u) { eArg += (double)_err[p]; ++cArg; ++nArg; }
			else { eOth += (double)_err[p]; ++cOth; }
		}
		_used[_seed] = n;
		if (n == 0u) { _med[_seed] = 1.0f; }
		else
		{
			for (uint32 a = 1; a < n; ++a)           // 삽입 정렬(n ≤ 8)
			{
				const float v = e[a]; uint32 b = a;
				while (b > 0u && e[b - 1u] > v) { e[b] = e[b - 1u]; --b; }
				e[b] = v;
			}
			_med[_seed] = (n % 2u == 1u) ? e[n / 2u] : (0.5f * (e[n / 2u - 1u] + e[n / 2u]));
		}
		_seedOk[_seed] = _finite;
		LogA("[mlt] ⏳   씨앗 %2u · 쓸 자리 **%u/%u** · **중앙값 오차 %.4f** · argmax 자리 %u(평균 %.4f) · 그 밖 평균 %.4f\n",
			_seed, n, kProbes, (double)_med[_seed], nArg,
			(cArg == 0u) ? 0.0 : (eArg / (double)cArg), (cOth == 0u) ? 0.0 : (eOth / (double)cOth));
		++_seed; _st = kEncInit;
	}

	static void _Summary()
	{
		uint32 ok = 0u, pass = 0u, enough = 0u;
		double mm = 0.0;
		for (uint32 s = 0; s < kSeeds; ++s)
		{
			if (!_seedOk[s]) continue;
			++ok; mm += _med[s];
			if (_used[s] >= kMinUse) ++enough;
			if (_med[s] <= kTol) ++pass;
		}
		if (ok > 0u) mm /= ok;
		const bool hyg = (enough >= kSignPass) && _finite;
		const bool p1 = (pass >= kSignPass);

		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] ⏳ **회차 65 · 판정 ② dVal→dMag** — 읽은 씨앗 %u/%u\n", ok, kSeeds);
		LogA("[mlt] ⏳   위생 — 쓸 자리 ≥%u 인 씨앗 **%u/%u** · 유한 %s → %s\n",
			kMinUse, enough, ok, _finite ? "예" : "⛔", hyg ? "통과" : "⛔");
		LogA("[mlt] ⏳   **표제** 중앙값 오차 ≤ %.2f — **%u/%u**(필요 %u · 전체 평균 %.4f)\n",
			(double)kTol, pass, kSeeds, kSignPass, mm);
		if (!hyg)
			LogA("[mlt] ⏳   ⭐ 판정 = ⛔ **판정불가** — 쓸 자리가 부족하거나 유한하지 않다\n");
		else if (p1)
			LogA("[mlt] ⏳   ⭐ 판정 = ✅ **연쇄법칙이 맞다** ⇒ 회차 66 = **인코더 주입 배관 + 생존 관문**\n");
		else
			LogA("[mlt] ⏳   ⭐ 판정 = ⛔ **연쇄법칙이 틀렸다** — ⚠️ 위 눈금(argmax 자리 ↔ 그 밖)이 어느 줄인지 말한다\n");
		LogA("[mlt] ⏳   ⚠️ 판정 ② 통과는 **구현이 맞다**는 뜻이지 **안정적 학습 방향**이라는 뜻이 아니다(회차 40)\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		_E.Destroy(); _done = true;
	}

	static void _Fail(const char* why)
	{
		LogA("[mlt] ⏳ ⛔ %s (씨앗 %u · 자리 %u · 단계 %u · 국면 %u)\n", why, _seed, _pi, _st, _phase);
		_E.Destroy(); _done = true;
	}
};
