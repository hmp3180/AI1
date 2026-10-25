// mltp3c2.cw — ⏳ 회차 51 · **P3-C2: 무엇이 다음 활성을 설명하나**(바닥 재기) (`-mltp3c2`)
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 51 이다.**
// ⚠️ **손잡이를 흔드는 회차가 아니다.** 회차 50 이 *"주변분포 1.7487 → ㈀ 0.6969"* 를 냈는데
//   이 저장소의 표준 바닥은 **복사**이고 그것을 안 쟀다 ⇒ `0.6969` 가 무슨 뜻인지 아직 모른다.
//   ★ 배치(앵커·슬롯 순서)는 **한 줄도 안 고친다** — 바닥을 모르고 고치면 두 원인이 섞인다.
// ══════════════════════════════════════════════════════════════════════════════
//
// ── 바닥 셋 · 몸통 둘 ──────────────────────────────────────────────────────
//   **M**  주변분포          `p(v) = 학습 코퍼스의 표적 빈도`
//   **C1** 슬롯 복사         `p(v) = λ·1[v = id(t,j)] + (1−λ)·M`
//   **C2** 집합 복사         `p(v) = λ·(v ∈ {id(t,·)} 이면 1/8) + (1−λ)·M`
//   **㈀ 학습 / ㈀ 시험** — 회차 50 의 ㈀ 팔 하나를 다시 돌리고 두 코퍼스에서 풀 평균 CE.
//
// ⭐ **λ 는 학습 코퍼스에서 고른다**(베이스라인에 **일부러 유리하게** — 바닥은 강해야 뜻이 있다).
// ⚠️⚠️ **`M`·λ 를 시험 라벨로 고르면 그것은 베이스라인이 아니라 오라클이다** ⇒ 둘 다 학습에서 맞춘다.
// ⚠️ **C2 가 있는 이유**: 슬롯이 `q` 선택 **순위**라 순위가 뒤바뀌면 C1 이 억울하게 진다
//   ⇒ **둘 중 낮은 쪽이 진짜 복사 바닥**이다.
//
// ⏱️ **프레임 업로드를 묶는다** — `MLArena::Write` 는 동기이고 무겁다(그 주석의 30~60배 함정).
//   회차 50 은 프레임마다 `WritePool` 을 불렀고 이 회차는 문맥이 **2배**다 ⇒ `kEncF` 장씩 모아 올린다.

using namespace PE;

class MLTP3C2
{
public:
	static void Tick(RHI* rhi)
	{
		if (_done || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltp3c2"))
		{
			LogA("[mlt] ⏳ 회차 51은 **꺼져 있다**(`-mltp3c2`) — 복사 바닥과 외움 몫\n");
			_done = true; return;
		}
		if (!_banner) { _Banner(); _banner = true; }
		if (_seed >= kSeeds) { _Summary(); return; }
		if (_st == kEncInit)  { _EncBegin(rhi); return; }
		if (_st == kEncTrain) { _EncTrain(); return; }
		if (_st == kGather)   { _Gather(); return; }
		if (_st == kBodyInit) { _BodyBegin(rhi); return; }
		if (_st == kBodyEval) { _BodyEval(); return; }
		_BodyTrain();
	}

	static bool Done() { return _done; }

private:
	// ── 회차 50 과 **같은** 값들 ──────────────────────────────────
	static constexpr uint32 kSeeds = 12u;
	static constexpr uint32 kEncF = 32u, kEncSteps = 1200u, kEncPerTick = 8u;
	static constexpr uint32 kN = 250u, kLocal = 8u, kPersist = 8u, kStateAx = 5u;
	static constexpr uint32 kAxes = kStateAx + kPersist;      // 13
	static constexpr uint32 kTime = 8u;
	static constexpr uint32 kCtx  = kAxes * kTime;            // 104
	static constexpr uint32 kBatch = MLTModelCfg::kBatch;     // 8
	static constexpr uint32 kRows = kBatch * kCtx;            // 832
	static constexpr uint32 kPoolN = 8u;                      // 코퍼스마다 문맥 64개
	static constexpr uint32 kBodySteps = 400u, kBodyPerTick = 4u;
	static constexpr uint32 kCandidates = MLTP2Cfg::kPatches * kLocal;
	static constexpr uint32 kCorpora = 2u;                    // 0 = 학습(ep 1..) · 1 = 시험(ep 101..)
	static constexpr uint32 kEpiBase[kCorpora] = { 1u, 101u };
	static constexpr uint32 kNCtx = kPoolN * kBatch;          // 64
	static constexpr uint32 kFrames = kNCtx * kTime;          // 512 — 코퍼스 하나의 프레임 수
	static constexpr uint32 kGroup = kEncF / kTime;           // 한 번에 올리는 문맥 수(4)
	static constexpr uint32 kLam = 11u;
	static constexpr uint32 kSignPass = 10u;
	static constexpr float  kMargExpect = 1.7487f, kMargTol = 0.01f;

	enum { kEncInit, kEncTrain, kGather, kBodyInit, kBodyTrain, kBodyEval };

	inline static MLTP2Enc _E;
	inline static MLTModel _M;
	inline static bool _done = false, _banner = false, _encSetup = false, _finite = true, _post = false;
	inline static uint32 _seed = 0u, _st = kEncInit, _step = 0u, _ev = 0u;
	inline static double _sumCe = 0.0;
	inline static uint32 _cor = 0u, _gGrp = 0u, _gIdx = 0u;   // 조립 진행(코퍼스 · 그룹 · 그룹 안 프레임)
	inline static Array<float> _code, _norm;
	// 코퍼스마다 풀 하나 — `[kPoolN × kRows]`
	inline static Array<float> _val[kCorpora], _tgt[kCorpora], _sym[kCorpora];
	// CPU 바닥의 재료: 표적 id 와 그 시각의 활성 집합
	inline static Array<uint32> _tid[kCorpora], _prevId[kCorpora];   // 표적 · 직전 시각의 8개(슬롯순)
	inline static uint32 _hist[kN];
	inline static float _lam[kSeeds];
	inline static float _mCe[kSeeds], _c1[kSeeds], _c2[kSeeds], _c1t[kSeeds], _c2t[kSeeds];
	inline static float _accSlot[kSeeds], _accSet[kSeeds];
	inline static float _bodyTr[kSeeds], _bodyTe[kSeeds], _firstCe = 0.0f;
	inline static bool  _seedOk[kSeeds];

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] ⏳ **회차 51 · P3-C2 — 무엇이 다음 활성을 설명하나**(바닥 재기)\n");
		LogA("[mlt] ⏳   바닥 셋: M 주변분포 · C1 슬롯복사 · C2 집합복사(λ 는 **학습**에서 고른다)\n");
		LogA("[mlt] ⏳   몸통 둘: ㈀ 학습(ep 1..%u) · ㈀ 시험(ep %u..%u) — 배치는 회차 50 그대로\n",
			kEpiBase[0] + kNCtx - 1u, kEpiBase[1], kEpiBase[1] + kNCtx - 1u);
		LogA("[mlt] ⏳   표제① ㈀학습 < min(C1*,C2*) 10/12 · 표제② ㈀시험 < min(C1*,C2*)(시험) 10/12\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

	// ══════════════════════════════════════════════════════════════════
	// 👁️ ① 인코더 — 회차 50 과 같다.
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
		for (uint32 c = 0; c < kCorpora; ++c)
		{
			_val[c].Reset(0); _tgt[c].Reset(0); _sym[c].Reset(0);
			for (uint32 i = 0; i < kPoolN * kRows; ++i) { _val[c].Add(0.0f); _tgt[c].Add(0.0f); _sym[c].Add(0.0f); }
			_tid[c].Reset(0); _prevId[c].Reset(0);
			// 표적은 문맥마다 `(kTime-1) × kPersist` 개다.
			for (uint32 i = 0; i < kNCtx * (kTime - 1u) * kPersist; ++i) { _tid[c].Add(0u); _prevId[c].Add(0u); }
		}
		_cor = 0u; _gGrp = 0u; _gIdx = 0u; _st = kGather;
		_pending = false;
	}

	// ══════════════════════════════════════════════════════════════════
	// 🧩 ② 문맥 조립 — ⏱️ **`kEncF` 장씩 모아 올린다**(문맥 `kGroup` 개 = 32 프레임).
	// ══════════════════════════════════════════════════════════════════
	inline static bool _pending = false;
	inline static float _st5[kEncF][kStateAx];

	static void _Gather()
	{
		if (_pending)
		{
			Array<float> ids, mag;
			if (!_E.ReadAct(ids, mag) || ids.Count() != kCandidates) { _Fail("활성 리드백"); return; }
			const uint32 ctx = _gGrp * kGroup + (_gIdx - 1u) / kTime;
			const uint32 t   = (_gIdx - 1u) % kTime;
			_Fill(_cor, ctx, t, ids, mag);
			_pending = false;
		}
		if (_gIdx == 0u)
		{
			// 그룹 하나(문맥 `kGroup` 개 = `kEncF` 프레임)를 CPU 에서 만들고 **한 번에** 올린다.
			Array<float> fr, tg; fr.Reset(0); tg.Reset(0);
			ImageFormat::Bitmap bmp; Bytes packed;
			for (uint32 g = 0; g < kGroup; ++g)
			{
				const uint32 ctx = _gGrp * kGroup + g;
				MLTWorld w; w.Reset(_seed, kEpiBase[_cor] + ctx, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
				for (uint32 t = 0; t < kTime; ++t)
				{
					w.Step();
					if (!w.Render(bmp) || !MLTWorld::Pack(bmp, nullptr, packed)) { _Fail("Render/Pack(문맥)"); return; }
					MLTP2Enc::AppendFrame(fr, tg, (const uint8*)packed.GetData());
					const MLTState& s = w.State();
					for (uint32 a = 0; a < kStateAx; ++a) _st5[g * kTime + t][a] = s.Axis((int)a);
				}
			}
			if (!_E.WritePool(fr, tg, kEncF)) { _Fail("문맥 풀 업로드"); return; }
			// 상태 슬롯은 GPU 와 무관하다 — 지금 적는다.
			for (uint32 g = 0; g < kGroup; ++g)
				for (uint32 t = 0; t < kTime; ++t)
				{
					const uint32 base = _Row(_gGrp * kGroup + g, t, 0u);
					for (uint32 a = 0; a < kStateAx; ++a)
					{
						_sym[_cor].Data()[base + a] = (float)a;
						_val[_cor].Data()[base + a] = _st5[g * kTime + t][a];
						_tgt[_cor].Data()[base + a] = (float)kN;      // IgnoreTgt
					}
				}
		}
		if (_gIdx < kEncF)
		{
			_E.SetFrame(_gIdx);
			if (!_E.Forward()) { _Fail("문맥 forward"); return; }
			++_gIdx; _pending = true; return;
		}
		// 그룹 끝
		_gIdx = 0u;
		if (++_gGrp * kGroup >= kNCtx)
		{
			_gGrp = 0u;
			if (++_cor >= kCorpora) { _AfterGather(); return; }
		}
	}

	static uint32 _Row(uint32 ctx, uint32 t, uint32 a)
	{
		const uint32 k = ctx / kBatch, b = ctx % kBatch;
		return k * kRows + b * kCtx + t * kAxes + a;
	}
	// 표적 배열의 자리 — `(ctx, t-1, j)`(표적은 `t ≥ 1` 에서만 생긴다)
	static uint32 _Tix(uint32 ctx, uint32 t1, uint32 j) { return (ctx * (kTime - 1u) + t1) * kPersist + j; }

	static void _Fill(uint32 cor, uint32 ctx, uint32 t, const Array<float>& ids, const Array<float>& mag)
	{
		uint32 pick[kPersist]; float pm[kPersist];
		Array<uint8> used; used.Reset(0);
		for (uint32 c = 0; c < kCandidates; ++c) used.Add(0u);
		float maxAbs = 0.0f;
		for (uint32 j = 0; j < kPersist; ++j)
		{
			bool found = false; float best = 0.0f; uint32 bp = 0u;
			for (uint32 c = 0; c < kCandidates; ++c)
			{
				if (used[c] != 0u) continue;
				const float f = ids[c];
				if (!(f >= 0.0f) || f >= (float)kN) continue;
				const float sc = Abs(mag[c]) * _norm[(uint32)f];
				if (!found || sc > best) { found = true; best = sc; bp = c; }
			}
			if (!found) { pick[j] = 0u; pm[j] = 0.0f; continue; }
			used.Data()[bp] = 1u; pick[j] = (uint32)ids[bp]; pm[j] = mag[bp];
			const float a = Abs(pm[j]); if (a > maxAbs) maxAbs = a;
		}
		const float inv = (maxAbs > 1.0e-12f) ? (1.0f / maxAbs) : 0.0f;
		const uint32 base = _Row(ctx, t, kStateAx);
		for (uint32 j = 0; j < kPersist; ++j)
		{
			_sym[cor].Data()[base + j] = (float)(kStateAx + pick[j]);
			_val[cor].Data()[base + j] = pm[j] * inv;
			_tgt[cor].Data()[base + j] = (float)kN;
		}
		if (t > 0u)
		{
			const uint32 prev = _Row(ctx, t - 1u, kStateAx);
			for (uint32 j = 0; j < kPersist; ++j)
			{
				_tgt[cor].Data()[prev + j] = (float)pick[j];
				_tid[cor].Data()[_Tix(ctx, t - 1u, j)] = pick[j];
				// ⭐ 복사 바닥의 재료 = **직전 시각의 그 슬롯 id**(그리고 그 시각의 8개 집합).
				_prevId[cor].Data()[_Tix(ctx, t - 1u, j)] = (uint32)(_sym[cor][prev + j] - (float)kStateAx);
			}
		}
	}

	// ══════════════════════════════════════════════════════════════════
	// 🧮 ③ CPU 바닥 — M · C1 · C2 (λ 는 **학습 코퍼스**에서 고른다)
	// ══════════════════════════════════════════════════════════════════
	static void _AfterGather()
	{
		const uint32 nT = kNCtx * (kTime - 1u) * kPersist;
		for (uint32 i = 0; i < kN; ++i) _hist[i] = 0u;
		for (uint32 i = 0; i < nT; ++i) ++_hist[_tid[0][i]];
		Array<float> marg; marg.Reset(0);
		for (uint32 i = 0; i < kN; ++i) marg.Add((float)((double)_hist[i] / (double)nT));

		_mCe[_seed] = (float)_CeM(0u, marg);
		// λ 스윕 — 학습 코퍼스에서 C1·C2 각각의 최적을 고른다.
		float bl1 = 0.1f, bl2 = 0.1f; double b1 = 1.0e30, b2 = 1.0e30;
		for (uint32 i = 0; i < kLam; ++i)
		{
			const float lam = _Lam(i);
			const double e1 = _CeCopy(0u, marg, lam, false);
			const double e2 = _CeCopy(0u, marg, lam, true);
			if (e1 < b1) { b1 = e1; bl1 = lam; }
			if (e2 < b2) { b2 = e2; bl2 = lam; }
		}
		_c1[_seed] = (float)b1; _c2[_seed] = (float)b2;
		_lam[_seed] = (b1 <= b2) ? bl1 : bl2;
		// 시험 코퍼스는 **학습에서 고른** `M`·λ 로 평가한다.
		_c1t[_seed] = (float)_CeCopy(1u, marg, bl1, false);
		_c2t[_seed] = (float)_CeCopy(1u, marg, bl2, true);
		// 눈금 — 복사 정확도 둘.
		uint32 hitSlot = 0u, hitSet = 0u;
		for (uint32 ctx = 0; ctx < kNCtx; ++ctx)
			for (uint32 t1 = 0; t1 + 1u < kTime; ++t1)
				for (uint32 j = 0; j < kPersist; ++j)
				{
					const uint32 ix = _Tix(ctx, t1, j);
					if (_tid[0][ix] == _prevId[0][ix]) ++hitSlot;
					for (uint32 q = 0; q < kPersist; ++q)
						if (_tid[0][ix] == _prevId[0][_Tix(ctx, t1, q)]) { ++hitSet; break; }
				}
		_accSlot[_seed] = (float)hitSlot / (float)nT;
		_accSet[_seed]  = (float)hitSet  / (float)nT;

		LogA("[mlt] ⏳ 씨앗 %2u · M **%.4f** · C1* **%.4f**(λ%.2f) · C2* **%.4f**(λ%.2f) · 복사정확도 슬롯 **%.3f** 집합 **%.3f**\n",
			_seed, (double)_mCe[_seed], (double)_c1[_seed], (double)bl1, (double)_c2[_seed], (double)bl2,
			(double)_accSlot[_seed], (double)_accSet[_seed]);
		_st = kBodyInit;
	}

	static float _Lam(uint32 i)
	{
		if (i < 9u) return 0.1f * (float)(i + 1u);
		return (i == 9u) ? 0.95f : 0.99f;
	}

	static double _CeM(uint32 cor, const Array<float>& marg)
	{
		const uint32 nT = kNCtx * (kTime - 1u) * kPersist;
		double s = 0.0;
		for (uint32 i = 0; i < nT; ++i)
		{
			float p = marg[_tid[cor][i]];
			if (p < 1.0e-9f) p = 1.0e-9f;
			s += -(double)Log(p);
		}
		return s / (double)nT;
	}

	// `useSet == false` → C1(슬롯) · `true` → C2(집합)
	static double _CeCopy(uint32 cor, const Array<float>& marg, float lam, bool useSet)
	{
		double s = 0.0; uint32 n = 0u;
		for (uint32 ctx = 0; ctx < kNCtx; ++ctx)
			for (uint32 t1 = 0; t1 + 1u < kTime; ++t1)
				for (uint32 j = 0; j < kPersist; ++j)
				{
					const uint32 ix = _Tix(ctx, t1, j);
					const uint32 v = _tid[cor][ix];
					float p = (1.0f - lam) * marg[v];
					if (!useSet) { if (_prevId[cor][ix] == v) p += lam; }
					else
					{
						uint32 c = 0u;
						for (uint32 q = 0; q < kPersist; ++q) if (_prevId[cor][_Tix(ctx, t1, q)] == v) ++c;
						if (c > 0u) p += lam * ((float)c / (float)kPersist);
					}
					if (p < 1.0e-9f) p = 1.0e-9f;
					s += -(double)Log(p); ++n;
				}
		return (n == 0u) ? 0.0 : (s / (double)n);
	}

	// ══════════════════════════════════════════════════════════════════
	// 🧠 ④ 몸통 — ㈀ 팔 하나. 학습 코퍼스로 배우고 **두 코퍼스**에서 평가한다.
	// ══════════════════════════════════════════════════════════════════
	static void _BodyBegin(RHI* rhi)
	{
		if (!_M.Setup(rhi, kStateAx + kN, kN, kAxes, kTime)) { _Fail("몸통 준비"); return; }
		if (_M.Rows() != kRows) { _Fail("몸통 행 수 불일치"); return; }
		if (!_M.UploadPool(_val[0], _tgt[0], kPoolN) || !_M.UploadSymbolPool(_sym[0], kPoolN))
		{ _Fail("몸통 학습 풀 업로드"); return; }
		_step = 0u; _cor = 0u;
		_BeginEval(false);
	}

	static void _BeginEval(bool post) { _st = kBodyEval; _ev = 0u; _post = post; _sumCe = 0.0; }

	static void _BodyEval()
	{
		if (_ev > 0u)
		{
			float ls = 0.0f;
			if (!_M.ReadLoss(ls)) { _Fail("몸통 손실 리드백"); return; }
			if (!(ls == ls) || ls > 1.0e30f) _finite = false;
			_sumCe += (double)ls;
		}
		if (_ev < kPoolN)
		{
			_M.SelectStep(_ev);
			if (!_M.Forward()) { _Fail("몸통 평가 forward"); return; }
			++_ev; return;
		}
		const float mean = (float)(_sumCe / (double)kPoolN);
		if (!_post) { _firstCe = mean; _step = 0u; _st = kBodyTrain; return; }
		if (_cor == 0u)
		{
			_bodyTr[_seed] = mean;
			// 시험 코퍼스로 갈아끼우고 다시 평가한다(⚠️ **학습은 안 한다**).
			if (!_M.UploadPool(_val[1], _tgt[1], kPoolN) || !_M.UploadSymbolPool(_sym[1], kPoolN))
			{ _Fail("몸통 시험 풀 업로드"); return; }
			_cor = 1u; _BeginEval(true); return;
		}
		_bodyTe[_seed] = mean;
		_SeedDone();
	}

	static void _BodyTrain()
	{
		if (_step >= kBodySteps) { _BeginEval(true); return; }
		for (uint32 i = 0; i < kBodyPerTick && _step < kBodySteps; ++i)
		{
			_M.SelectStep(_step % kPoolN);
			if (!_M.Forward() || !_M.Backward() || !_M.AdamStep(1.0f)) { _Fail("몸통 스텝"); return; }
			++_step;
		}
	}

	static void _SeedDone()
	{
		const float floorTr = (_c1[_seed] < _c2[_seed]) ? _c1[_seed] : _c2[_seed];
		const float floorTe = (_c1t[_seed] < _c2t[_seed]) ? _c1t[_seed] : _c2t[_seed];
		_seedOk[_seed] = _finite && (_firstCe > 0.0f);
		LogA("[mlt] ⏳   씨앗 %2u · ㈀ %.4f → 학습 **%.4f** / 시험 **%.4f** · 복사바닥 학습 **%.4f** 시험 **%.4f** · %s%s\n",
			_seed, (double)_firstCe, (double)_bodyTr[_seed], (double)_bodyTe[_seed],
			(double)floorTr, (double)floorTe,
			(_bodyTr[_seed] < floorTr) ? "학습 ✅" : "학습 ⛔",
			(_bodyTe[_seed] < floorTe) ? " · 시험 ✅" : " · 시험 ⛔");
		++_seed; _st = kEncInit;
	}

	static void _Summary()
	{
		double mM = 0.0, mC1 = 0.0, mC2 = 0.0, mTr = 0.0, mTe = 0.0, mFt = 0.0, mAs = 0.0, mAe = 0.0;
		uint32 t1 = 0u, t2 = 0u, ok = 0u;
		for (uint32 s = 0; s < kSeeds; ++s)
		{
			if (!_seedOk[s]) continue;
			++ok;
			mM += _mCe[s]; mC1 += _c1[s]; mC2 += _c2[s]; mTr += _bodyTr[s]; mTe += _bodyTe[s];
			mAs += _accSlot[s]; mAe += _accSet[s];
			const float fTr = (_c1[s] < _c2[s]) ? _c1[s] : _c2[s];
			const float fTe = (_c1t[s] < _c2t[s]) ? _c1t[s] : _c2t[s];
			mFt += fTe;
			if (_bodyTr[s] < fTr) ++t1;
			if (_bodyTe[s] < fTe) ++t2;
		}
		if (ok > 0u) { mM /= ok; mC1 /= ok; mC2 /= ok; mTr /= ok; mTe /= ok; mFt /= ok; mAs /= ok; mAe /= ok; }
		const bool regr = Abs((float)mM - kMargExpect) <= kMargTol;
		const bool p1 = (t1 >= kSignPass), p2 = (t2 >= kSignPass);

		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] ⏳ **회차 51 · P3-C2 결과** — 읽은 씨앗 %u/%u\n", ok, kSeeds);
		LogA("[mlt] ⏳   회귀 — M(학습) 평균 **%.4f**(회차 50 의 %.4f ±%.2f) → %s\n",
			mM, (double)kMargExpect, (double)kMargTol, regr ? "통과" : "⛔");
		LogA("[mlt] ⏳   바닥 — C1* **%.4f** · C2* **%.4f** ⇒ **복사바닥 %.4f** · 시험 복사바닥 **%.4f**\n",
			mC1, mC2, (mC1 < mC2) ? mC1 : mC2, mFt);
		LogA("[mlt] ⏳   몸통 — ㈀ 학습 **%.4f** · ㈀ 시험 **%.4f**\n", mTr, mTe);
		LogA("[mlt] ⏳   눈금 — 복사 정확도 슬롯 **%.3f** · 집합 **%.3f**(차 = 순위가 흔드는 몫)\n", mAs, mAe);
		LogA("[mlt] ⏳   **표제① ㈀학습 < 복사바닥 — %u/%u**(필요 %u) → %s\n", t1, kSeeds, kSignPass, p1 ? "통과" : "⛔");
		LogA("[mlt] ⏳   **표제② ㈀시험 < 복사바닥 — %u/%u**(필요 %u) → %s\n", t2, kSeeds, kSignPass, p2 ? "통과" : "⛔");
		if (!regr)
			LogA("[mlt] ⏳   ⭐ 판정 = ⛔ **판정불가**(회귀) — 회차 50 과 같은 코퍼스가 아니다\n");
		else if (p1 && p2)
			LogA("[mlt] ⏳   ⭐ 판정 = ✅ **복사 이상을 배웠고 일반화도 한다** ⇒ 회차 52 = 배치 수정(앵커)\n");
		else if (p1)
			LogA("[mlt] ⏳   ⭐ 판정 = ⚠️ **외운 것이다**(학습은 넘고 시험은 못 넘는다) ⇒ 회차 52 = 문맥 수\n");
		else
			LogA("[mlt] ⏳   ⭐ 판정 = ⛔⛔ **회차 50 의 「배웠다」가 무너진다** — 복사 흉내다 ⇒ 회차 52 = **과제**를 바꾼다\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		_E.Destroy(); _done = true;
	}

	static void _Fail(const char* why)
	{
		LogA("[mlt] ⏳ ⛔ %s (씨앗 %u · 코퍼스 %u · 단계 %u)\n", why, _seed, _cor, _st);
		_E.Destroy(); _done = true;
	}
};
