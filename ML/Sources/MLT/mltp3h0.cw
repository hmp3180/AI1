// mltp3h0.cw — ⏳ 회차 61 · **변화가 표현에 있나**(P3 ㉢) (`-mltp3h0`)
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 61 이다.**
// ⭐ 상위 캔버스가 **새것**이다: **표현이 무엇을 담았나**.
//
// ⚠️ **이름 정정** — *"활성이 물체를 가르나"* 는 **P2 의 ㉢** 이고 회차 46 이 이미 통과시켰다.
//   **P3 의 ㉢ 은 「변화가 표현에 있나」**다(`MLT.md` 원문).
// ══════════════════════════════════════════════════════════════════════════════
//
// ⭐ **무엇을 묻나** — 상태는 **수준**으로만 들어간다(`x,y,z,yaw,pitch`). ***차분을 슬롯으로 준 적이
//   한 번도 없다.*** 그런데 다음-활성을 맞히려면 무엇이 어떻게 움직이는지를 알아야 한다.
//   ⇒ **다음 스텝 손실이 요구한 것만으로 「변화」가 표현에 생겼나.**
//
// ⚠️⚠️ **미래가 아니다** — 인과 마스크라 프로브가 읽는 행은 시각 `≤ t` 만 본다.
//   라벨은 `Δ_t = d_t − d_{t−1}` = **이미 일어난 변화**다. P0 이 통과시킨 「예측」과 **다른 물음**이다.
//
// ⚠️ `MLTShapeView` 는 **판정 창구**다 — 인코더 입력·손실·표적 어디에도 안 들어간다.

using namespace PE;

class MLTP3H0
{
public:
	static void Tick(RHI* rhi)
	{
		if (_done || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltp3h0"))
		{
			LogA("[mlt] ⏳ 회차 61은 **꺼져 있다**(`-mltp3h0`) — 변화가 표현에 있나(P3 ㉢)\n");
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
		if (_st == kSweepTr)
		{
			if (!_Sweep(kPoolSteps, _xTr)) return;
			// 시험 풀로 갈아 끼우고 다시 훑는다.
			if (!_M.UploadPool(_te.Val(), _te.Tgt(), kTestPool) || !_M.UploadSymbolPool(_te.Sym(), kTestPool))
			{ _Fail("시험 풀 업로드"); return; }
			_rk = 0u; _rw = 0u; _rpend = false; _xTe.Reset(0); _st = kSweepTe; return;
		}
		if (_st == kSweepTe)
		{
			if (!_Sweep(kTestPool, _xTe)) return;
			_ScoreArm(MLTModel::RepDim());
			return;
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
	static constexpr uint32 kCtxRow = MLTP3Ctx::kCtx;
	static constexpr uint32 kCandidates = MLTP2Cfg::kPatches * kLocal;
	static constexpr uint32 kNCtx = 128u, kTestCtx = 64u;
	static constexpr uint32 kTrainEpi = 1u, kTestEpi = 101u;
	static constexpr uint32 kPoolSteps = kNCtx / kBatch, kTestPool = kTestCtx / kBatch;
	static constexpr uint32 kGroup = kEncF / kTime;
	static constexpr uint32 kSteps = 800u, kPerTick = 4u;
	static constexpr uint32 kArms = 3u, kRep = 6u;
	static constexpr uint32 kSignPass = 10u;
	static constexpr float  kRidge = 1.0e-3f;
	static constexpr float  kFloorMax = 0.20f;     // 위생① — ㈂ 바닥의 상한
	static constexpr float  kKeepMin  = 0.50f;     // 위생② — 유효 표본 비율의 하한
	// ⭐ 표본 하나 = `(문맥, 시각 t≥1)`. 시각 0 은 `t−1` 이 없어 라벨이 없다.
	static constexpr uint32 kPerCtx = kTime - 1u;
	static constexpr uint32 kSampTr = kNCtx * kPerCtx, kSampTe = kTestCtx * kPerCtx;

	enum { kEncInit, kEncTrain, kGather, kQuiesce, kBodyInit, kBodyTrain, kSweepTr, kSweepTe };

	inline static MLTP2Enc _E;
	inline static MLTModel _M;
	inline static MLTP3Ctx _tr, _te;
	inline static bool _done = false, _banner = false, _encSetup = false;
	inline static bool _pending = false;
	inline static uint32 _seed = 0u, _st = kEncInit, _step = 0u, _arm = 0u, _rep = 0u;
	inline static uint32 _cor = 0u, _gGrp = 0u, _gIdx = 0u;
	inline static Array<float> _code, _norm;
	// 판정 창구 — 추적 도형의 깊이(⚠️ 모델은 이것을 절대 못 본다)
	inline static Array<float> _dTr, _dTe;
	inline static Array<uint8> _vTr, _vTe;
	inline static Array<float> _yTr, _yTe;
	inline static Array<uint8> _okTr, _okTe;
	// 특징
	inline static Array<float> _xTr, _xTe, _mu, _sd, _w;
	inline static uint32 _rk = 0u, _rw = 0u; inline static bool _rpend = false;
	// 결과
	inline static float _run[kRep];
	inline static float _R[kArms][kSeeds], _RA[kArms][kSeeds], _RB[kArms][kSeeds];
	inline static float _acc[kArms][kSeeds], _keep[kSeeds];
	inline static bool  _seedOk[kSeeds];

	inline static uint32 _qWait = 0u;
	static void _ToBody() { _qWait = MLTEvalGate::kDelay; _st = kQuiesce; }

	static uint32 _Reps() { return (_arm == 0u) ? kRep : 1u; }
	static const char* _ArmName()
	{
		return (_arm == 0u) ? "㈀ 학습된 몸통" : ((_arm == 1u) ? "㈁ 초기화 몸통" : "㈂ 입력 슬롯");
	}

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] ⏳ **회차 61 · 변화가 표현에 있나**(P3 ㉢ · ⭐ **새 상위 캔버스**)\n");
		LogA("[mlt] ⏳   라벨 = 「가까워지나/멀어지나」 Δd = d(t) − d(t−1) — ⚠️ **이미 일어난 변화**(예측 아님)\n");
		LogA("[mlt] ⏳   프로브 = 마지막 norm 뒤 표현의 행 (b,t,%u) → 능형 회귀(λ=%.0e) → **R**\n",
			kAxes - 1u, (double)kRidge);
		LogA("[mlt] ⏳   팔 셋 — ㈀ 학습된 몸통 · ㈁ **초기화 몸통**(학습이 넣은 것) · ㈂ **입력 슬롯**(이미 주어진 것)\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

	// ══════════════════════════════════════════════════════════════════
	// 인코더 — 회차 60 과 같다.
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
		_dTr.Reset(0); _vTr.Reset(0); _dTe.Reset(0); _vTe.Reset(0);
		for (uint32 i = 0; i < kNCtx * kTime; ++i) { _dTr.Add(0.0f); _vTr.Add(0u); }
		for (uint32 i = 0; i < kTestCtx * kTime; ++i) { _dTe.Add(0.0f); _vTe.Add(0u); }
		_cor = 0u; _gGrp = 0u; _gIdx = 0u; _pending = false; _st = kGather;
	}

	// ══════════════════════════════════════════════════════════════════
	// 코퍼스 + ⭐ **판정 창구**(추적 도형의 깊이)
	// ══════════════════════════════════════════════════════════════════
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
			Array<float>& dst = (_cor == 0u) ? _dTr : _dTe;
			Array<uint8>& vis = (_cor == 0u) ? _vTr : _vTe;
			for (uint32 g = 0; g < kGroup; ++g)
			{
				const uint32 ctx = _gGrp * kGroup + g;
				MLTWorld w; w.Reset(_seed, epi + ctx, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
				int track = -1;
				for (uint32 t = 0; t < kTime; ++t)
				{
					w.Step();
					// ⭐ 판정 창구 — **시각 0 의 최근접 도형**을 잡아 `index` 로 문맥 내내 추적한다.
					//   ⚠️ `VisibleShapes` 는 먼 것부터라 마지막이 가장 가깝다.
					MLTShapeView sv[MLTWorldCfg::kShapes];
					const int n = w.VisibleShapes(sv, MLTWorldCfg::kShapes);
					if (t == 0u && n > 0) track = sv[n - 1].index;
					const uint32 ix = ctx * kTime + t;
					vis.Data()[ix] = 0u; dst.Data()[ix] = 0.0f;
					for (int i = 0; i < n; ++i)
						if (sv[i].index == track) { dst.Data()[ix] = sv[i].d; vis.Data()[ix] = 1u; break; }
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
				_MakeLabels(kNCtx, _dTr, _vTr, _yTr, _okTr);
				_MakeLabels(kTestCtx, _dTe, _vTe, _yTe, _okTe);
				uint32 kept = 0u;
				for (uint32 i = 0; i < kSampTe; ++i) if (_okTe[i] != 0u) ++kept;
				_keep[_seed] = (float)kept / (float)kSampTe;
				LogA("[mlt] ⏳ 씨앗 %2u · 유효 표본 **%.1f%%**(시험 %u/%u)\n",
					_seed, (double)(_keep[_seed] * 100.0f), kept, kSampTe);
				_arm = 0u; _rep = 0u; _ToBody();
			}
		}
	}

	// 라벨 `Δ_t = d_t − d_{t−1}` — ⚠️ 두 시각 다 보여야 유효하다.
	static void _MakeLabels(uint32 nCtx, const Array<float>& d, const Array<uint8>& vis,
		Array<float>& y, Array<uint8>& ok)
	{
		y.Reset(0); ok.Reset(0);
		for (uint32 ctx = 0; ctx < nCtx; ++ctx)
			for (uint32 t = 1; t < kTime; ++t)
			{
				const uint32 a = ctx * kTime + t, b = a - 1u;
				const bool good = (vis[a] != 0u) && (vis[b] != 0u);
				y.Add(good ? (d[a] - d[b]) : 0.0f);
				ok.Add(good ? 1u : 0u);
			}
	}

	// ══════════════════════════════════════════════════════════════════
	// 몸통 — ㈀ 는 학습, ㈁ 은 학습 0, ㈂ 는 GPU 를 안 쓴다.
	// ══════════════════════════════════════════════════════════════════
	static void _BodyBegin(RHI* rhi)
	{
		if (_arm == 2u) { _InputFeatures(); _ScoreArm(kAxes); return; }
		if (!_M.Setup(rhi, MLTP3Ctx::kStateAx + kN, kN, kAxes, kTime)) { _Fail("몸통 준비"); return; }
		if (!_M.UploadPool(_tr.Val(), _tr.Tgt(), kPoolSteps) || !_M.UploadSymbolPool(_tr.Sym(), kPoolSteps))
		{ _Fail("학습 풀 업로드"); return; }
		_step = 0u;
		if (_arm == 1u) { _rk = 0u; _rw = 0u; _rpend = false; _xTr.Reset(0); _st = kSweepTr; return; }
		_st = kBodyTrain;
	}

	static void _BodyTrain()
	{
		if (_step >= kSteps)
		{ _rk = 0u; _rw = 0u; _rpend = false; _xTr.Reset(0); _st = kSweepTr; return; }
		for (uint32 i = 0; i < kPerTick && _step < kSteps; ++i)
		{
			_M.SelectStep(_step % kPoolSteps);
			if (!_M.Forward() || !_M.Backward() || !_M.AdamStep(1.0f)) { _Fail("몸통 스텝"); return; }
			++_step;
		}
	}

	// 풀 한 바퀴를 돌며 표현을 모은다. ⚠️ `ReadRep` 은 **한 프레임 뒤**라 매 스텝 기다린다.
	static bool _Sweep(uint32 nPool, Array<float>& out)
	{
		if (_rpend)
		{
			if (_rw > 0u) { --_rw; return false; }
			Array<float> rep;
			if (!_M.ReadRep(rep)) { _Fail("표현 리드백"); return false; }
			const uint32 D = MLTModel::RepDim();
			for (uint32 b = 0; b < kBatch; ++b)
				for (uint32 t = 1; t < kTime; ++t)
				{
					const uint32 row = b * kCtxRow + t * kAxes + (kAxes - 1u);
					for (uint32 d = 0; d < D; ++d) out.Add(rep[row * D + d]);
				}
			_rpend = false; ++_rk;
		}
		if (_rk >= nPool) return true;
		_M.SelectStep(_rk);
		if (!_M.Forward()) { _Fail("표현 forward"); return false; }
		_rw = MLTEvalGate::kDelay; _rpend = true;
		return false;
	}

	// ㈂ — **그 시각 입력 슬롯 13개**. ⚠️ 한 시각뿐이라 **차분을 만들 수 없다**(그것이 바닥의 뜻이다).
	static void _InputFeatures()
	{
		_xTr.Reset(0); _xTe.Reset(0);
		for (uint32 ctx = 0; ctx < kNCtx; ++ctx)
			for (uint32 t = 1; t < kTime; ++t)
				for (uint32 a = 0; a < kAxes; ++a) _xTr.Add(_tr.Val()[MLTP3Ctx::Row(ctx, t, a)]);
		for (uint32 ctx = 0; ctx < kTestCtx; ++ctx)
			for (uint32 t = 1; t < kTime; ++t)
				for (uint32 a = 0; a < kAxes; ++a) _xTe.Add(_te.Val()[MLTP3Ctx::Row(ctx, t, a)]);
	}

	// ══════════════════════════════════════════════════════════════════
	// 🧮 프로브 — 열 표준화(학습 통계) → 능형 회귀 → 시험에서 `R`
	// ══════════════════════════════════════════════════════════════════
	static void _Stats(const Array<float>& X, uint32 dim, const Array<uint8>& ok, uint32 nSamp)
	{
		_mu.Reset(0); _sd.Reset(0);
		for (uint32 d = 0; d < dim; ++d) { _mu.Add(0.0f); _sd.Add(0.0f); }
		uint32 n = 0u;
		for (uint32 i = 0; i < nSamp; ++i)
		{
			if (ok[i] == 0u) continue;
			++n;
			for (uint32 d = 0; d < dim; ++d) _mu.Data()[d] += X[i * dim + d];
		}
		if (n == 0u) { for (uint32 d = 0; d < dim; ++d) _sd.Data()[d] = 1.0f; return; }
		for (uint32 d = 0; d < dim; ++d) _mu.Data()[d] /= (float)n;
		for (uint32 i = 0; i < nSamp; ++i)
		{
			if (ok[i] == 0u) continue;
			for (uint32 d = 0; d < dim; ++d)
			{ const float z = X[i * dim + d] - _mu[d]; _sd.Data()[d] += z * z; }
		}
		for (uint32 d = 0; d < dim; ++d)
		{ const float v = _sd[d] / (float)n; _sd.Data()[d] = (v > 1.0e-12f) ? Sqrt(v) : 1.0f; }
	}

	static bool _Fit(const Array<float>& X, uint32 dim, const Array<float>& y,
		const Array<uint8>& ok, uint32 nSamp)
	{
		const uint32 n = dim + 1u;
		Array<float> A, b, x;
		A.Reset(0); b.Reset(0); x.Reset(0);
		for (uint32 i = 0; i < n * n; ++i) A.Add(0.0f);
		for (uint32 i = 0; i < n; ++i) { b.Add(0.0f); x.Add(0.0f); }
		uint32 cnt = 0u;
		for (uint32 s = 0; s < nSamp; ++s)
		{
			if (ok[s] == 0u) continue;
			for (uint32 d = 0; d < dim; ++d) x.Data()[d] = (X[s * dim + d] - _mu[d]) / _sd[d];
			x.Data()[dim] = 1.0f;
			for (uint32 i = 0; i < n; ++i)
			{
				const float xi = x[i];
				for (uint32 j = 0; j <= i; ++j) A.Data()[i * n + j] += xi * x[j];
				b.Data()[i] += xi * y[s];
			}
			++cnt;
		}
		if (cnt <= n) return false;
		const float inv = 1.0f / (float)cnt;
		for (uint32 i = 0; i < n; ++i)
		{
			for (uint32 j = 0; j <= i; ++j) { A.Data()[i * n + j] *= inv; A.Data()[j * n + i] = A[i * n + j]; }
			b.Data()[i] *= inv;
		}
		// ⚠️ **절편에는 능형을 안 건다**(평균을 줄이는 것은 규제의 뜻이 아니다).
		for (uint32 i = 0; i < dim; ++i) A.Data()[i * n + i] += kRidge;
		if (!SolveSymPD(A.Data(), b.Data(), n)) return false;
		_w.Reset(0);
		for (uint32 i = 0; i < n; ++i) _w.Add(b[i]);
		return true;
	}

	static bool _EvalR(const Array<float>& X, uint32 dim, const Array<float>& y,
		const Array<uint8>& ok, uint32 nSamp, float& R, float& acc)
	{
		double sp = 0.0, sy = 0.0; uint32 n = 0u, hit = 0u;
		Array<float> pred; pred.Reset(0);
		for (uint32 s = 0; s < nSamp; ++s)
		{
			if (ok[s] == 0u) { pred.Add(0.0f); continue; }
			double p = (double)_w[dim];
			for (uint32 d = 0; d < dim; ++d) p += (double)_w[d] * (double)((X[s * dim + d] - _mu[d]) / _sd[d]);
			pred.Add((float)p);
			sp += p; sy += (double)y[s]; ++n;
			if ((p >= 0.0) == (y[s] >= 0.0f)) ++hit;
		}
		if (n < 2u) return false;
		const double mp = sp / (double)n, my = sy / (double)n;
		double cpp = 0.0, cyy = 0.0, cpy = 0.0;
		for (uint32 s = 0; s < nSamp; ++s)
		{
			if (ok[s] == 0u) continue;
			const double a = (double)pred[s] - mp, c = (double)y[s] - my;
			cpp += a * a; cyy += c * c; cpy += a * c;
		}
		if (cpp <= 1.0e-20 || cyy <= 1.0e-20) return false;
		R = (float)(cpy / Sqrt((float)(cpp * cyy)));
		acc = (float)hit / (float)n;
		return true;
	}

	static void _ScoreArm(uint32 dim)
	{
		_Stats(_xTr, dim, _okTr, kSampTr);
		float R = 0.0f, acc = 0.0f;
		if (!_Fit(_xTr, dim, _yTr, _okTr, kSampTr) || !_EvalR(_xTe, dim, _yTe, _okTe, kSampTe, R, acc))
		{ _Fail("프로브 적합/평가"); return; }
		_run[_rep] = R;
		_acc[_arm][_seed] = acc;
		if (++_rep < _Reps()) { _ToBody(); return; }
		_Agg();
	}

	static void _Agg()
	{
		const uint32 Rn = _Reps();
		double s = 0.0, sA = 0.0, sB = 0.0; uint32 nA = 0u, nB = 0u;
		for (uint32 i = 0; i < Rn; ++i)
		{
			s += (double)_run[i];
			if ((i % 2u) == 0u) { sA += (double)_run[i]; ++nA; } else { sB += (double)_run[i]; ++nB; }
		}
		_R[_arm][_seed]  = (float)(s / (double)Rn);
		_RA[_arm][_seed] = (nA == 0u) ? _R[_arm][_seed] : (float)(sA / (double)nA);
		_RB[_arm][_seed] = (nB == 0u) ? _R[_arm][_seed] : (float)(sB / (double)nB);
		LogA("[mlt] ⏳   %s 씨앗 %2u · **R %.4f**(반쪽 A %.4f · B %.4f · 부호 %.1f%% · R=%u)\n",
			_ArmName(), _seed, (double)_R[_arm][_seed], (double)_RA[_arm][_seed],
			(double)_RB[_arm][_seed], (double)(_acc[_arm][_seed] * 100.0f), Rn);
		_rep = 0u;
		if (++_arm < kArms) { _ToBody(); return; }
		_seedOk[_seed] = true;
		++_seed; _st = kEncInit;
	}

	static void _Summary()
	{
		double m[kArms];
		for (uint32 a = 0; a < kArms; ++a) m[a] = 0.0;
		uint32 ok = 0u, t1 = 0u, t2 = 0u, lowFloor = 0u, keptOk = 0u;
		uint32 a1 = 0u, a2 = 0u, b1 = 0u, b2 = 0u;
		double mk = 0.0;
		for (uint32 s = 0; s < kSeeds; ++s)
		{
			if (!_seedOk[s]) continue;
			++ok;
			for (uint32 a = 0; a < kArms; ++a) m[a] += _R[a][s];
			mk += _keep[s];
			if (_R[2][s] < kFloorMax) ++lowFloor;
			if (_keep[s] >= kKeepMin) ++keptOk;
			if (_R[0][s] > _R[1][s]) ++t1;
			if (_R[0][s] > _R[2][s]) ++t2;
			if (_RA[0][s] > _R[1][s]) ++a1;
			if (_RA[0][s] > _R[2][s]) ++a2;
			if (_RB[0][s] > _R[1][s]) ++b1;
			if (_RB[0][s] > _R[2][s]) ++b2;
		}
		if (ok > 0u) { for (uint32 a = 0; a < kArms; ++a) m[a] /= ok; mk /= ok; }
		const bool hyg1 = (lowFloor >= kSignPass);
		const bool hyg2 = (keptOk >= kSignPass);
		const bool split = (a1 >= kSignPass) && (a2 >= kSignPass) && (b1 >= kSignPass) && (b2 >= kSignPass);
		const bool p1 = (t1 >= kSignPass), p2 = (t2 >= kSignPass);

		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] ⏳ **회차 61 · 변화가 표현에 있나**(P3 ㉢) — 읽은 씨앗 %u/%u\n", ok, kSeeds);
		LogA("[mlt] ⏳   위생① ㈂ 바닥 < %.2f — **%u/%u** → %s\n", (double)kFloorMax, lowFloor, ok, hyg1 ? "통과" : "⛔");
		LogA("[mlt] ⏳   위생② 유효 표본 ≥ %.0f%% — **%u/%u**(평균 %.1f%%) → %s\n",
			(double)(kKeepMin * 100.0f), keptOk, ok, (double)(mk * 100.0f), hyg2 ? "통과" : "⛔");
		LogA("[mlt] ⏳   평균 R — ㈀ 학습됨 **%.4f** · ㈁ 초기화 **%.4f** · ㈂ 입력 **%.4f**\n", m[0], m[1], m[2]);
		LogA("[mlt] ⏳   위생③ 분할 반쪽 — A(>㈁ %u · >㈂ %u) · B(%u · %u) · 각 필요 %u → %s\n",
			a1, a2, b1, b2, kSignPass, split ? "통과" : "⛔");
		LogA("[mlt] ⏳   **표제** — ㈀>㈁ **%u/%u** · ㈀>㈂ **%u/%u**(각 필요 %u)\n",
			t1, kSeeds, t2, kSeeds, kSignPass);
		if (!hyg1)
			LogA("[mlt] ⏳   ⭐ 판정 = ⛔ **판정불가** — 라벨이 입력에 샌다(㈂ 바닥이 높다)\n");
		else if (!hyg2)
			LogA("[mlt] ⏳   ⭐ 판정 = ⛔ **판정불가** — 추적이 안 된다(유효 표본 부족)\n");
		else if (p1 && p2 && split)
			LogA("[mlt] ⏳   ⭐ 판정 = ✅ **㉢ 통과 — 변화가 표현에 있고 학습이 그것을 넣었다**\n");
		else if (p2 && !p1)
			LogA("[mlt] ⏳   ⭐ 판정 = ⛔ **통과로 부르지 않는다** — 변화는 읽히는데 **무작위 특징으로도 된다**(학습의 몫 0)\n");
		else if (!p1 && !p2)
			LogA("[mlt] ⏳   ⭐ 판정 = ⛔ **㉢ 실패** — 변화가 표현에 없다 ⇒ 회차 60 과 **모순**이라 프로브 자리를 의심한다\n");
		else
			LogA("[mlt] ⏳   ⭐ 판정 = ⚠️ **판정불가**(위생③ 또는 한 표제만 섰다)\n");
		LogA("[mlt] ⏳   ⚠️ 고정 %u문맥의 진단이다 — 절대 성능으로 인용하지 않는다\n", kNCtx);
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		_E.Destroy(); _done = true;
	}

	static void _Fail(const char* why)
	{
		LogA("[mlt] ⏳ ⛔ %s (씨앗 %u · 팔 %u · 반복 %u · 단계 %u)\n", why, _seed, _arm, _rep, _st);
		_E.Destroy(); _done = true;
	}
};
