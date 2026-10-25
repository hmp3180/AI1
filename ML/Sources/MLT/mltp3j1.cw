// mltp3j1.cw — 🔩 회차 66 · **판정 ② 재시도(ε 스윕 + 꺾인점 진단)** (`-mltp3j1`)
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 66 이다.**
// ⚠️ 상위 = **경험이 인코딩을 바꾸나** · **판정 회차가 아니다**(배관·판정 도구 — 계수 안 늘린다).
// ══════════════════════════════════════════════════════════════════════════════
//
// ⭐ **바꾸는 것은 자뿐이다** — 식·자리 해시·씨앗·몸통 학습은 회차 65 **그대로**라 견줄 수 있다.
//   ㈀ **ε 를 셋** 재고(0.2% · 1% · 5%) ㈁ **꺾인점을 직접 센다**.
//
// ── 회차 65 가 남긴 것 ────────────────────────────────────────────────────
//   ⛔ 2/12(중앙값 오차 평균 0.2543). ⭐ 그런데 **`argmax` 자리가 오히려 더 정확했다**(5/5 씨앗)
//     ⇒ 보정항이 **있는** 줄이 맞고 **없는** 줄이 틀린다 = *"보정항이 틀렸다"* 의 정반대.
//   ⇒ 가설: `i ≠ m` 을 `+ε` 흔들면 `argmax` 가 바뀌어 **`maxAbs` 가 바뀐다**(꺾인점) ⇒ 중앙차분이
//     불연속을 가로지른다. ⚠️ 회차 64 의 눈금(값 RMS **0.90**)이 이미 *"슬롯이 최대에 몰려 있다"* 고
//     말하고 있었다 — **눈금은 찍는 것이 아니라 읽는 것이다.**

using namespace PE;

class MLTP3J1
{
public:
	static void Tick(RHI* rhi)
	{
		if (_done || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltp3j1"))
		{
			LogA("[mlt] 🔩 회차 66은 **꺼져 있다**(`-mltp3j1`) — 판정 ② 재시도(ε 스윕 + 꺾인점)\n");
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
	static constexpr uint32 kProbes = 8u;
	static constexpr uint32 kNEps = 3u;
	static constexpr uint32 kMinClean = 3u;     // 위생 — 꺾임 아닌 쓸 자리의 하한
	static constexpr float  kTol = 0.10f;
	static constexpr float  kDead = 1.0e-6f;
	static constexpr float  kEpsMin = 1.0e-3f;
	// ⭐ 표제는 **가장 작은 ε**(색인 0)에서만 읽는다 ⇒ 다중비교가 없다.
	static float Rel(uint32 e) { return (e == 0u) ? 0.002f : ((e == 1u) ? 0.01f : 0.05f); }
	static constexpr uint32 kTitleEps = 0u, kKinkEps = 2u;

	enum { kEncInit, kEncTrain, kGather, kQuiesce, kBodyInit, kBodyTrain, kGrad, kCheck };

	inline static MLTP2Enc _E;
	inline static MLTModel _M;
	inline static MLTP3Ctx _tr;
	inline static bool _done = false, _banner = false, _encSetup = false, _finite = true;
	inline static bool _pending = false;
	inline static uint32 _seed = 0u, _st = kEncInit, _step = 0u;
	inline static uint32 _gGrp = 0u, _gIdx = 0u;
	inline static Array<float> _code, _norm, _dv;
	inline static uint32 _pk[kProbes], _pb[kProbes], _pt[kProbes], _pj[kProbes];
	inline static float  _ana[kProbes];
	inline static uint8  _use[kProbes], _isArg[kProbes];
	inline static float  _err[kNEps][kProbes];
	inline static uint8  _ok[kNEps][kProbes], _kink[kNEps][kProbes];
	inline static uint32 _pi = 0u, _ei = 0u, _phase = 0u, _wait = 0u;
	inline static float  _plus = 0.0f, _saveMag = 0.0f, _eps = 0.0f;
	// 결과 — ε 별 (전체 중앙값 · 꺾임제외 중앙값 · 꺾임 비율)
	inline static float _medAll[kNEps][kSeeds], _medClean[kNEps][kSeeds], _kinkR[kNEps][kSeeds];
	inline static uint32 _nClean[kSeeds];
	inline static bool  _seedOk[kSeeds];

	inline static uint32 _qWait = 0u;
	static void _ToBody() { _qWait = MLTEvalGate::kDelay; _st = kQuiesce; }

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🔩 **회차 66 · 판정 ② 재시도 — ε 스윕 + 꺾인점 진단**(⚠️ 판정 회차 아님)\n");
		LogA("[mlt] 🔩   ε 상대 **0.2%% · 1%% · 5%%** — ⭐ **표제는 가장 작은 것에서만**(다중비교 없음)\n");
		LogA("[mlt] 🔩   표제① `ε=0.2%%` 꺾임제외 중앙값 ≤ %.2f · 표제② `ε=5%%` 꺾임제외 < 전체\n", (double)kTol);
		LogA("[mlt] 🔩   ⚠️ 식·자리·씨앗·학습은 회차 65 **그대로** — 자만 바뀐다\n");
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

	// ⚠️ **회차 65 와 같은 해시**다 — 같은 자리를 잰다(견줄 수 있어야 한다).
	static void _PickProbes()
	{
		for (uint32 p = 0; p < kProbes; ++p)
		{
			const uint32 h = MLTWorld::Hash(_seed * 3571u + p * 97u, MLTSalt::Start, 77u);
			_pk[p] = h % kPoolSteps;
			_pb[p] = (h >> 5) % kBatch;
			_pt[p] = (h >> 9) % kTime;
			_pj[p] = (h >> 13) % kSlots;
			_use[p] = 0u; _ana[p] = 0.0f; _isArg[p] = 0u;
			for (uint32 e = 0; e < kNEps; ++e) { _err[e][p] = 0.0f; _ok[e][p] = 0u; _kink[e][p] = 0u; }
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
		if (_step >= kSteps) { _pi = 0u; _phase = 0u; _st = kGrad; return; }
		for (uint32 i = 0; i < kPerTick && _step < kSteps; ++i)
		{
			_M.SelectStep(_step % kPoolSteps);
			if (!_M.Forward() || !_M.Backward() || !_M.AdamStep(1.0f)) { _Fail("몸통 스텝"); return; }
			++_step;
		}
	}

	static void _GradPass()
	{
		if (_phase == 1u)
		{
			if (_wait > 0u) { --_wait; return; }
			if (!_M.ReadDVal(_dv)) { _Fail("dVal 리드백"); return; }
			_Analytic(_pi);
			_phase = 0u;
			if (++_pi >= kProbes) { _pi = 0u; _ei = 0u; _phase = 0u; _st = kCheck; return; }
			return;
		}
		_M.SelectStep(_pk[_pi]);
		if (!_M.Forward() || !_M.Backward()) { _Fail("dVal forward/backward"); return; }
		_wait = MLTEvalGate::kDelay; _phase = 1u;
	}

	// 해석값 — ⚠️ 회차 65 와 **같은 식**이다(고치지 않았다).
	static void _Analytic(uint32 p)
	{
		const uint32 ctx = _pk[p] * kBatch + _pb[p], t = _pt[p], j = _pj[p];
		if (_tr.Cand(ctx, t, j) == MLTP3Ctx::kNoCand) { _use[p] = 0u; return; }
		const float inv = _tr.Inv(ctx, t);
		double S = 0.0;
		const uint32 m = _ArgMax(ctx, t, kSlots, 0.0f);
		for (uint32 q = 0; q < kSlots; ++q)
		{
			const uint32 row = _pb[p] * kCtxRow + t * kAxes + (kStateAx + q);
			const float g = (row < _dv.Count()) ? _dv[row] : 0.0f;
			const float v = _tr.Val()[MLTP3Ctx::Row(ctx, t, kStateAx + q)];
			S += (double)g * (double)v;
		}
		const uint32 rowJ = _pb[p] * kCtxRow + t * kAxes + (kStateAx + j);
		const float gj = (rowJ < _dv.Count()) ? _dv[rowJ] : 0.0f;
		const float pmj = _tr.RawMag(ctx, t, j);
		_isArg[p] = (j == m) ? 1u : 0u;
		if (j == m)
		{
			const float sg = (pmj >= 0.0f) ? 1.0f : -1.0f;
			_ana[p] = inv * (gj - sg * (float)S);
		}
		else _ana[p] = inv * gj;
		_use[p] = 1u;
	}

	// ⭐ 슬롯 `bump` 에 `d` 를 더한 상태의 `argmax`. `bump >= kSlots` 면 원래 상태다.
	static uint32 _ArgMax(uint32 ctx, uint32 t, uint32 bump, float d)
	{
		uint32 m = 0u; float best = -1.0f;
		for (uint32 q = 0; q < kSlots; ++q)
		{
			float v = _tr.RawMag(ctx, t, q);
			if (q == bump) v += d;
			const float a = Abs(v);
			if (a > best) { best = a; m = q; }
		}
		return m;
	}

	// ── 중앙차분 — 자리마다 ε 셋을 연달아 재고 **마지막에 한 번만** 되돌린다 ──
	static void _Check()
	{
		if (_pi >= kProbes) { _Judge(); return; }
		if (_use[_pi] == 0u) { ++_pi; _ei = 0u; return; }
		const uint32 ctx = _pk[_pi] * kBatch + _pb[_pi], t = _pt[_pi], j = _pj[_pi];
		if (_phase == 0u)
		{
			_saveMag = _tr.RawMag(ctx, t, j);
			_eps = Abs(_saveMag) * Rel(_ei);
			if (_eps < kEpsMin) _eps = kEpsMin;
			// ⭐ **꺾인점을 CPU 로 먼저 센다** — `±ε` 가 `argmax` 를 바꾸나.
			const uint32 m0 = _ArgMax(ctx, t, kSlots, 0.0f);
			const uint32 mp = _ArgMax(ctx, t, j, +_eps);
			const uint32 mm = _ArgMax(ctx, t, j, -_eps);
			_kink[_ei][_pi] = (mp != m0 || mm != m0) ? 1u : 0u;
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
		const float num = (_plus - minus) / (2.0f * _eps);
		const float a = Abs(_ana[_pi]), n = Abs(num);
		if (a < kDead && n < kDead) _ok[_ei][_pi] = 0u;
		else { _ok[_ei][_pi] = 1u; _err[_ei][_pi] = Abs(_ana[_pi] - num) / (a + n + 1.0e-8f); }
		_phase = 0u;
		if (++_ei < kNEps) return;                     // 다음 ε — 되돌리지 않는다(어차피 덮어쓴다)
		// 마지막 ε 를 마쳤다 ⇒ **되돌린다**(⚠️ 안 되돌리면 다음 자리가 오염된다).
		_tr.SetRawMag(ctx, t, j, _saveMag);
		_tr.RewriteVals(ctx, t);
		if (!_UploadTrain()) return;
		_ei = 0u; ++_pi;
	}

	static float _Median(const float* e, uint32 n)
	{
		if (n == 0u) return 1.0f;
		float v[kProbes];
		for (uint32 i = 0; i < n; ++i) v[i] = e[i];
		for (uint32 a = 1; a < n; ++a)
		{
			const float x = v[a]; uint32 b = a;
			while (b > 0u && v[b - 1u] > x) { v[b] = v[b - 1u]; --b; }
			v[b] = x;
		}
		return (n % 2u == 1u) ? v[n / 2u] : (0.5f * (v[n / 2u - 1u] + v[n / 2u]));
	}

	static void _Judge()
	{
		for (uint32 e = 0; e < kNEps; ++e)
		{
			float all[kProbes], cln[kProbes];
			uint32 na = 0u, nc = 0u, nk = 0u;
			for (uint32 p = 0; p < kProbes; ++p)
			{
				if (_ok[e][p] == 0u) continue;
				all[na++] = _err[e][p];
				if (_kink[e][p] != 0u) ++nk; else cln[nc++] = _err[e][p];
			}
			_medAll[e][_seed] = _Median(all, na);
			_medClean[e][_seed] = _Median(cln, nc);
			_kinkR[e][_seed] = (na == 0u) ? 0.0f : ((float)nk / (float)na);
			if (e == kTitleEps) _nClean[_seed] = nc;
		}
		_seedOk[_seed] = _finite;
		LogA("[mlt] 🔩   씨앗 %2u · ε0.2%% 전체 %.4f / 꺾임제외 **%.4f**(깨끗 %u) · ε1%% %.4f/%.4f · ε5%% %.4f/**%.4f** · 꺾임률 %.2f/%.2f/**%.2f**\n",
			_seed, (double)_medAll[0][_seed], (double)_medClean[0][_seed], _nClean[_seed],
			(double)_medAll[1][_seed], (double)_medClean[1][_seed],
			(double)_medAll[2][_seed], (double)_medClean[2][_seed],
			(double)_kinkR[0][_seed], (double)_kinkR[1][_seed], (double)_kinkR[2][_seed]);
		++_seed; _st = kEncInit;
	}

	static void _Summary()
	{
		uint32 ok = 0u, hyg = 0u, p1 = 0u, p2 = 0u;
		double mA[kNEps], mC[kNEps], mK[kNEps];
		for (uint32 e = 0; e < kNEps; ++e) { mA[e] = 0.0; mC[e] = 0.0; mK[e] = 0.0; }
		for (uint32 s = 0; s < kSeeds; ++s)
		{
			if (!_seedOk[s]) continue;
			++ok;
			for (uint32 e = 0; e < kNEps; ++e)
			{ mA[e] += _medAll[e][s]; mC[e] += _medClean[e][s]; mK[e] += _kinkR[e][s]; }
			if (_nClean[s] >= kMinClean) ++hyg;
			if (_medClean[kTitleEps][s] <= kTol) ++p1;
			if (_medClean[kKinkEps][s] < _medAll[kKinkEps][s]) ++p2;
		}
		if (ok > 0u) for (uint32 e = 0; e < kNEps; ++e) { mA[e] /= ok; mC[e] /= ok; mK[e] /= ok; }
		const bool hOk = (hyg >= kSignPass) && _finite;
		const bool t1 = (p1 >= kSignPass), t2 = (p2 >= kSignPass);

		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🔩 **회차 66 · 판정 ② 재시도** — 읽은 씨앗 %u/%u\n", ok, kSeeds);
		LogA("[mlt] 🔩   ε 스윕(전체 / 꺾임제외 / 꺾임률) — 0.2%%: %.4f / **%.4f** / %.2f\n", mA[0], mC[0], mK[0]);
		LogA("[mlt] 🔩                                      1%%: %.4f / %.4f / %.2f\n", mA[1], mC[1], mK[1]);
		LogA("[mlt] 🔩                                      5%%: %.4f / %.4f / **%.2f**  (⚠️ 회차 65 전체 = 0.2543)\n",
			mA[2], mC[2], mK[2]);
		LogA("[mlt] 🔩   위생 — 깨끗한 자리 ≥%u 인 씨앗 **%u/%u** · 유한 %s → %s\n",
			kMinClean, hyg, ok, _finite ? "예" : "⛔", hOk ? "통과" : "⛔");
		LogA("[mlt] 🔩   **표제① 식이 맞나**(ε0.2%% 꺾임제외 ≤ %.2f) — **%u/%u**(필요 %u)\n",
			(double)kTol, p1, kSeeds, kSignPass);
		LogA("[mlt] 🔩   **표제② 꺾인점 가설**(ε5%% 꺾임제외 < 전체) — **%u/%u**(필요 %u)\n",
			p2, kSeeds, kSignPass);
		if (!hOk)
			LogA("[mlt] 🔩   ⭐ 판정 = ⛔ **판정불가** — 깨끗한 자리가 부족하거나 유한하지 않다\n");
		else if (t1 && t2)
			LogA("[mlt] 🔩   ⭐ 판정 = ✅ **연쇄법칙이 맞고 회차 65 의 실패가 꺾인점으로 설명된다** ⇒ 회차 67 = 배관 + **정규화 교체 심사**\n");
		else if (t1 && !t2)
			LogA("[mlt] 🔩   ⭐ 판정 = ⚠️ **식은 맞고 꺾인점 가설은 안 섰다**(회차 65 는 절단오차) ⇒ 정규화 교체 심사를 **열지 않는다**\n");
		else
			LogA("[mlt] 🔩   ⭐ 판정 = ⛔⛔ **식이 틀렸다** ⇒ 배관을 안 짓고 `dVal` 자체의 판정을 먼저 등록한다\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		_E.Destroy(); _done = true;
	}

	static void _Fail(const char* why)
	{
		LogA("[mlt] 🔩 ⛔ %s (씨앗 %u · 자리 %u · ε %u · 단계 %u · 국면 %u)\n", why, _seed, _pi, _ei, _st, _phase);
		_E.Destroy(); _done = true;
	}
};
