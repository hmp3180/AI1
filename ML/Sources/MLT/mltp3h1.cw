// mltp3h1.cw — ⏳ 회차 62 · **학습은 「자기 과제」를 표현에 넣었나** (`-mltp3h1`)
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 62 이다.**
// ⚠️ 상위 캔버스는 회차 61 과 **같다**(표현이 무엇을 담았나) — **둘째**다. 셋째면 규율 6.
// ══════════════════════════════════════════════════════════════════════════════
//
// ⭐ **진단 회차다.** 회차 61 의 ⛔(`㈀ 0.2136` ↔ `㈁ 0.1966`)에는 두 설명이 있고 안 갈렸다:
//   ㈎ **프로브 자리가 틀렸다** · ㈏ **학습이 넣은 것은 「자기 과제」뿐이다**.
//   ⇒ **자(㈁ 대조군 · 분할 반쪽)를 그대로 두고 라벨만 몸통의 표적으로 바꾼다.**
//     · ㈀ 이 ㈁ 을 크게 넘으면 ⇒ 자리는 멀쩡 ⇒ **㈏** ⇒ 회차 61 이 **설명된다**.
//     · ㈀ ≈ ㈁ 이면 ⇒ **㈎** ⇒ ⚠️⚠️ **회차 61 의 판정도 보류로 내린다**(같은 자리로 쟀으니).
//
// ⚠️ **자리를 결과 보고 고른 것이 아니다** — 회차 61 은 라벨이 문맥당 하나(추적 도형 `Δd`)라 행이
//   하나뿐이었고, 이 회차는 라벨이 **행마다** 있다. 라벨의 성질이지 사후 선택이 아니다.

using namespace PE;

class MLTP3H1
{
public:
	static void Tick(RHI* rhi)
	{
		if (_done || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltp3h1"))
		{
			LogA("[mlt] ⏳ 회차 62는 **꺼져 있다**(`-mltp3h1`) — 학습이 자기 과제를 표현에 넣었나\n");
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
			if (!_M.UploadPool(_te.Val(), _te.Tgt(), kTestPool) || !_M.UploadSymbolPool(_te.Sym(), kTestPool))
			{ _Fail("시험 풀 업로드"); return; }
			_rk = 0u; _rw = 0u; _rpend = false; _xTe.Reset(0); _st = kSweepTe; return;
		}
		if (_st == kSweepTe)
		{
			if (!_Sweep(kTestPool, _xTe)) return;
			_ScoreArm();
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
	static constexpr uint32 kSlots = MLTP3Ctx::kPersist;       // 8
	static constexpr uint32 kStateAx = MLTP3Ctx::kStateAx;     // 5
	static constexpr uint32 kCtxRow = MLTP3Ctx::kCtx;
	static constexpr uint32 kCandidates = MLTP2Cfg::kPatches * kLocal;
	static constexpr uint32 kNCtx = 128u, kTestCtx = 64u;
	static constexpr uint32 kTrainEpi = 1u, kTestEpi = 101u;
	static constexpr uint32 kPoolSteps = kNCtx / kBatch, kTestPool = kTestCtx / kBatch;
	static constexpr uint32 kGroup = kEncF / kTime;
	static constexpr uint32 kSteps = 800u, kPerTick = 4u;
	static constexpr uint32 kArms = 2u, kRep = 6u;
	static constexpr uint32 kSignPass = 10u;
	static constexpr float  kRidge = 1.0e-3f;
	// ⭐ 표본 = `(문맥, 시각 0..kTime−2, 활성 슬롯 0..7)` — **활성 행마다 하나**.
	static constexpr uint32 kPerCtx = (kTime - 1u) * kSlots;   // 56
	static constexpr uint32 kSampTr = kNCtx * kPerCtx;         // 7168
	static constexpr uint32 kSampTe = kTestCtx * kPerCtx;      // 3584

	enum { kEncInit, kEncTrain, kGather, kQuiesce, kBodyInit, kBodyTrain, kSweepTr, kSweepTe };

	inline static MLTP2Enc _E;
	inline static MLTModel _M;
	inline static MLTP3Ctx _tr, _te;
	inline static bool _done = false, _banner = false, _encSetup = false;
	inline static bool _pending = false;
	inline static uint32 _seed = 0u, _st = kEncInit, _step = 0u, _arm = 0u, _rep = 0u;
	inline static uint32 _cor = 0u, _gGrp = 0u, _gIdx = 0u;
	inline static Array<float> _code, _norm;
	inline static Array<uint32> _cTr, _cTe;        // 표본별 클래스(다음 활성 id)
	inline static Array<float> _xTr, _xTe, _mu, _sd, _w;
	inline static uint32 _rk = 0u, _rw = 0u; inline static bool _rpend = false;
	inline static float _run[kRep], _runTr[kRep];
	inline static float _ac[kArms][kSeeds], _acA[kArms][kSeeds], _acB[kArms][kSeeds];
	inline static float _acTrain[kArms][kSeeds];
	inline static float _fMode[kSeeds], _fCopy[kSeeds];
	inline static bool  _seedOk[kSeeds];

	inline static uint32 _qWait = 0u;
	static void _ToBody() { _qWait = MLTEvalGate::kDelay; _st = kQuiesce; }

	static uint32 _Reps() { return (_arm == 0u) ? kRep : 1u; }
	static const char* _ArmName() { return (_arm == 0u) ? "㈀ 학습된 몸통" : "㈁ 초기화 몸통"; }

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] ⏳ **회차 62 · 학습은 「자기 과제」를 표현에 넣었나**(⚠️ 회차 61 과 **같은 상위** · 둘째)\n");
		LogA("[mlt] ⏳   라벨 = **그 행 자신의 표적**(다음 활성 id) · 표본 학습 %u · 시험 %u\n", kSampTr, kSampTe);
		LogA("[mlt] ⏳   프로브 = one-hot 능형(V=%u · λ=%.0e · nrhs 한 번 인수분해) → **top-1 정확도**\n",
			kN, (double)kRidge);
		LogA("[mlt] ⏳   팔 둘 — ㈀ 학습된 몸통 · ㈁ **초기화 몸통**(회차 61 과 **같은 대조군**)\n");
		LogA("[mlt] ⏳   ⭐ 가르는 것: ㈀≫㈁ ⇒ 자리 멀쩡·「자기 과제뿐」 / ㈀≈㈁ ⇒ **자리가 틀렸다**(회차 61 보류)\n");
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
				MLTWorld w; w.Reset(_seed, epi + ctx, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
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
			if (++_cor >= 2u)
			{
				_Classes(_tr, kNCtx, _cTr);
				_Classes(_te, kTestCtx, _cTe);
				_Floors();
				LogA("[mlt] ⏳ 씨앗 %2u · 바닥 — 최빈 **%.1f%%** · 슬롯 복사 **%.1f%%**(눈금)\n",
					_seed, (double)(_fMode[_seed] * 100.0f), (double)(_fCopy[_seed] * 100.0f));
				_arm = 0u; _rep = 0u; _ToBody();
			}
		}
	}

	// 표본별 클래스 = **그 행 자신의 표적**(다음 활성 id).
	static void _Classes(const MLTP3Ctx& C, uint32 nCtx, Array<uint32>& out)
	{
		out.Reset(0);
		for (uint32 ctx = 0; ctx < nCtx; ++ctx)
			for (uint32 t = 0; t + 1u < kTime; ++t)
				for (uint32 j = 0; j < kSlots; ++j)
					out.Add((uint32)C.Tgt()[MLTP3Ctx::Row(ctx, t, kStateAx + j)]);
	}

	// 바닥 둘 — ⓐ 최빈 클래스(위생) · ⓑ 슬롯 복사(눈금).
	//   ⚠️ 복사 예측 = *"그 슬롯의 **지금** id 를 그대로 답한다"* = 그 행 자신의 심볼이다.
	static void _Floors()
	{
		Array<uint32> h; h.Reset(0);
		for (uint32 i = 0; i < kN; ++i) h.Add(0u);
		for (uint32 i = 0; i < kSampTe; ++i) if (_cTe[i] < kN) ++h.Data()[_cTe[i]];
		uint32 best = 0u;
		for (uint32 i = 0; i < kN; ++i) if (h[i] > best) best = h[i];
		_fMode[_seed] = (float)best / (float)kSampTe;
		uint32 hit = 0u, s = 0u;
		for (uint32 ctx = 0; ctx < kTestCtx; ++ctx)
			for (uint32 t = 0; t + 1u < kTime; ++t)
				for (uint32 j = 0; j < kSlots; ++j)
				{
					const uint32 r = MLTP3Ctx::Row(ctx, t, kStateAx + j);
					const uint32 now = (uint32)(_te.Sym()[r] - (float)kStateAx);
					if (now == _cTe[s]) ++hit;
					++s;
				}
		_fCopy[_seed] = (float)hit / (float)kSampTe;
	}

	// ══════════════════════════════════════════════════════════════════
	static void _BodyBegin(RHI* rhi)
	{
		if (!_M.Setup(rhi, kStateAx + kN, kN, kAxes, kTime)) { _Fail("몸통 준비"); return; }
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

	// 풀 한 바퀴 — **활성 행 8개 전부**를 모은다(회차 61 은 행 하나였다).
	static bool _Sweep(uint32 nPool, Array<float>& out)
	{
		if (_rpend)
		{
			if (_rw > 0u) { --_rw; return false; }
			Array<float> rep;
			if (!_M.ReadRep(rep)) { _Fail("표현 리드백"); return false; }
			const uint32 D = MLTModel::RepDim();
			for (uint32 b = 0; b < kBatch; ++b)
				for (uint32 t = 0; t + 1u < kTime; ++t)
					for (uint32 j = 0; j < kSlots; ++j)
					{
						const uint32 row = b * kCtxRow + t * kAxes + (kStateAx + j);
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

	// ══════════════════════════════════════════════════════════════════
	// 🧮 one-hot 능형 — ⭐ `SolveSymPD(nrhs = V)` 로 **인수분해 한 번**을 250 우변이 나눠 쓴다.
	// ══════════════════════════════════════════════════════════════════
	static void _Stats(const Array<float>& X, uint32 dim, uint32 nSamp)
	{
		_mu.Reset(0); _sd.Reset(0);
		for (uint32 d = 0; d < dim; ++d) { _mu.Add(0.0f); _sd.Add(0.0f); }
		for (uint32 i = 0; i < nSamp; ++i)
			for (uint32 d = 0; d < dim; ++d) _mu.Data()[d] += X[i * dim + d];
		for (uint32 d = 0; d < dim; ++d) _mu.Data()[d] /= (float)nSamp;
		for (uint32 i = 0; i < nSamp; ++i)
			for (uint32 d = 0; d < dim; ++d)
			{ const float z = X[i * dim + d] - _mu[d]; _sd.Data()[d] += z * z; }
		for (uint32 d = 0; d < dim; ++d)
		{ const float v = _sd[d] / (float)nSamp; _sd.Data()[d] = (v > 1.0e-12f) ? Sqrt(v) : 1.0f; }
	}

	static bool _Fit(const Array<float>& X, uint32 dim, const Array<uint32>& cls, uint32 nSamp)
	{
		const uint32 n = dim + 1u;
		Array<float> A, x;
		A.Reset(0); x.Reset(0);
		for (uint32 i = 0; i < n * n; ++i) A.Add(0.0f);
		for (uint32 i = 0; i < n; ++i) x.Add(0.0f);
		_w.Reset(0);
		for (uint32 i = 0; i < n * kN; ++i) _w.Add(0.0f);
		uint32 cnt = 0u;
		for (uint32 s = 0; s < nSamp; ++s)
		{
			const uint32 c = cls[s];
			if (c >= kN) continue;                       // ⚠️ 무효 표적은 안 센다
			for (uint32 d = 0; d < dim; ++d) x.Data()[d] = (X[s * dim + d] - _mu[d]) / _sd[d];
			x.Data()[dim] = 1.0f;
			for (uint32 i = 0; i < n; ++i)
			{
				const float xi = x[i];
				for (uint32 j = 0; j <= i; ++j) A.Data()[i * n + j] += xi * x[j];
				_w.Data()[i * kN + c] += xi;             // one-hot 이라 그 열만
			}
			++cnt;
		}
		if (cnt <= n) return false;
		const float inv = 1.0f / (float)cnt;
		for (uint32 i = 0; i < n; ++i)
		{
			for (uint32 j = 0; j <= i; ++j) { A.Data()[i * n + j] *= inv; A.Data()[j * n + i] = A[i * n + j]; }
			for (uint32 c = 0; c < kN; ++c) _w.Data()[i * kN + c] *= inv;
		}
		for (uint32 i = 0; i < dim; ++i) A.Data()[i * n + i] += kRidge;   // ⚠️ 절편에는 안 건다
		return SolveSymPD(A.Data(), _w.Data(), n, kN);
	}

	static float _Acc(const Array<float>& X, uint32 dim, const Array<uint32>& cls, uint32 nSamp)
	{
		const uint32 n = dim + 1u;
		Array<float> x, sc;
		x.Reset(0); sc.Reset(0);
		for (uint32 i = 0; i < n; ++i) x.Add(0.0f);
		for (uint32 i = 0; i < kN; ++i) sc.Add(0.0f);
		uint32 hit = 0u, used = 0u;
		for (uint32 s = 0; s < nSamp; ++s)
		{
			const uint32 c = cls[s];
			if (c >= kN) continue;
			for (uint32 d = 0; d < dim; ++d) x.Data()[d] = (X[s * dim + d] - _mu[d]) / _sd[d];
			x.Data()[dim] = 1.0f;
			for (uint32 k = 0; k < kN; ++k) sc.Data()[k] = 0.0f;
			for (uint32 i = 0; i < n; ++i)
			{
				const float xi = x[i];
				if (xi == 0.0f) continue;
				const float* wr = _w.Data() + i * kN;
				for (uint32 k = 0; k < kN; ++k) sc.Data()[k] += xi * wr[k];
			}
			uint32 arg = 0u; float best = sc[0];
			for (uint32 k = 1; k < kN; ++k) if (sc[k] > best) { best = sc[k]; arg = k; }
			if (arg == c) ++hit;
			++used;
		}
		return (used == 0u) ? 0.0f : ((float)hit / (float)used);
	}

	static void _ScoreArm()
	{
		const uint32 D = MLTModel::RepDim();
		_Stats(_xTr, D, kSampTr);
		if (!_Fit(_xTr, D, _cTr, kSampTr)) { _Fail("프로브 적합"); return; }
		_runTr[_rep] = _Acc(_xTr, D, _cTr, kSampTr);
		_run[_rep] = _Acc(_xTe, D, _cTe, kSampTe);
		if (++_rep < _Reps()) { _ToBody(); return; }
		_Agg();
	}

	static void _Agg()
	{
		const uint32 Rn = _Reps();
		double s = 0.0, sA = 0.0, sB = 0.0, st = 0.0; uint32 nA = 0u, nB = 0u;
		for (uint32 i = 0; i < Rn; ++i)
		{
			s += (double)_run[i]; st += (double)_runTr[i];
			if ((i % 2u) == 0u) { sA += (double)_run[i]; ++nA; } else { sB += (double)_run[i]; ++nB; }
		}
		_ac[_arm][_seed]  = (float)(s / (double)Rn);
		_acA[_arm][_seed] = (nA == 0u) ? _ac[_arm][_seed] : (float)(sA / (double)nA);
		_acB[_arm][_seed] = (nB == 0u) ? _ac[_arm][_seed] : (float)(sB / (double)nB);
		_acTrain[_arm][_seed] = (float)(st / (double)Rn);
		LogA("[mlt] ⏳   %s 씨앗 %2u · 시험 **%.2f%%**(반쪽 A %.2f · B %.2f) · 학습 %.2f%% · R=%u\n",
			_ArmName(), _seed, (double)(_ac[_arm][_seed] * 100.0f),
			(double)(_acA[_arm][_seed] * 100.0f), (double)(_acB[_arm][_seed] * 100.0f),
			(double)(_acTrain[_arm][_seed] * 100.0f), Rn);
		_rep = 0u;
		if (++_arm < kArms) { _ToBody(); return; }
		_seedOk[_seed] = true;
		++_seed; _st = kEncInit;
	}

	static void _Summary()
	{
		double m[kArms], mt[kArms], mMode = 0.0, mCopy = 0.0;
		for (uint32 a = 0; a < kArms; ++a) { m[a] = 0.0; mt[a] = 0.0; }
		uint32 ok = 0u, beatMode = 0u, t1 = 0u, a1 = 0u, b1 = 0u, beatCopy = 0u;
		for (uint32 s = 0; s < kSeeds; ++s)
		{
			if (!_seedOk[s]) continue;
			++ok;
			for (uint32 a = 0; a < kArms; ++a) { m[a] += _ac[a][s]; mt[a] += _acTrain[a][s]; }
			mMode += _fMode[s]; mCopy += _fCopy[s];
			if (_ac[0][s] > _fMode[s]) ++beatMode;
			if (_ac[0][s] > _fCopy[s]) ++beatCopy;
			if (_ac[0][s] > _ac[1][s]) ++t1;
			if (_acA[0][s] > _ac[1][s]) ++a1;
			if (_acB[0][s] > _ac[1][s]) ++b1;
		}
		if (ok > 0u)
		{
			for (uint32 a = 0; a < kArms; ++a) { m[a] /= ok; mt[a] /= ok; }
			mMode /= ok; mCopy /= ok;
		}
		const bool hyg1 = (beatMode >= kSignPass);
		const bool split = (a1 >= kSignPass) && (b1 >= kSignPass);
		const bool p1 = (t1 >= kSignPass);

		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] ⏳ **회차 62 · 학습은 자기 과제를 표현에 넣었나** — 읽은 씨앗 %u/%u\n", ok, kSeeds);
		LogA("[mlt] ⏳   바닥 — 최빈 **%.2f%%** · 슬롯 복사 **%.2f%%**(눈금 · ㈀ 이 넘은 씨앗 %u/%u)\n",
			mMode * 100.0, mCopy * 100.0, beatCopy, ok);
		LogA("[mlt] ⏳   위생① ㈀ > 최빈 — **%u/%u** → %s\n", beatMode, ok, hyg1 ? "통과" : "⛔");
		LogA("[mlt] ⏳   시험 정확도 — ㈀ 학습됨 **%.2f%%** · ㈁ 초기화 **%.2f%%**(학습 %.2f%% ↔ %.2f%%)\n",
			m[0] * 100.0, m[1] * 100.0, mt[0] * 100.0, mt[1] * 100.0);
		LogA("[mlt] ⏳   위생② 분할 반쪽 — A(>㈁ %u) · B(%u) · 각 필요 %u → %s\n",
			a1, b1, kSignPass, split ? "통과" : "⛔");
		LogA("[mlt] ⏳   **표제** — ㈀>㈁ **%u/%u**(필요 %u)\n", t1, kSeeds, kSignPass);
		if (!hyg1)
			LogA("[mlt] ⏳   ⭐ 판정 = ⛔ **판정불가** — 프로브가 아예 안 붙었다(최빈 바닥도 못 넘는다)\n");
		else if (p1 && split)
			LogA("[mlt] ⏳   ⭐ 판정 = ✅ **자리는 멀쩡하고 학습은 「자기 과제」를 표현에 넣었다** ⇒ 회차 61 이 설명된다\n");
		else if (!p1)
			LogA("[mlt] ⏳   ⭐ 판정 = ⛔⛔ **프로브 자리가 틀렸다** ⇒ **회차 61 의 판정을 「보류」로 내린다**\n");
		else
			LogA("[mlt] ⏳   ⭐ 판정 = ⚠️ **판정불가** — 표제는 섰는데 분할 반쪽이 안 맞는다\n");
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
