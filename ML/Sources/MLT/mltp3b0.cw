// mltp3b0.cw — ⏳ 회차 47 · **P3-B0: 미래 표적은 다른 것을 남기나** (`-mltp3b0`)
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 47 이다** — 여기 적는 것은 구현 계약뿐이다.
// ══════════════════════════════════════════════════════════════════════════════
//
// ⚠️ **학습 회차가 아니다.** 회차 43 의 학습·탐욕을 **글자 그대로** 다시 돌리고
//   ***표적만*** `t` ↔ `t+Δ` 로 가른다. 새 GPU 커널·새 학습 파라미터·P3 몸통은 **0개**다.
//
// ★ **묻는 것 한 줄** — *"무엇을 남길지를 미래가 정하면 다른 것이 남나?"*
//   회차 43 이 「표적을 본 탐욕으로도 512→8 압축 실패」를, 회차 44·45 가 「프레임 전체 top-k 는
//   붕괴」를, 회차 46 이 「칸막이 안에는 identity 가 있다」를 냈다. 남은 자리가 **표적**이고,
//   학습 표적을 옮기기 **전에** 오라클로 그 표적이 무력하지 않은지부터 판정한다.
//
// ── 표제 지표 = **토큰 등가치 τ** ────────────────────────────────────────────
//   `τ = min{ m ∈ [8,16] : sseSelf[m] ≤ sseFut8 }` (없으면 **17** = `>16`)
//   ⇒ *"미래 표적으로 다시 고르는 것은 토큰 몇 개를 더 주는 것과 같은가?"*
//   ⭐ 그 밑의 연속량이 `ΔG = (sseSelf[8] − sseFut8) / denom` 이고 **추세는 그것에 건다**.
//   ★ `denom > 0` 이므로 `G` 비교는 **SSE 비교와 같다**(나눗셈 없이 판정한다 — 수치가 더 곧다).
//
// ⚠️⚠️ **`_Improvement` 의 표적과 `_Sse` 의 표적이 다르다** — 그것이 이 회차의 **전부**다.
//   선택은 `yPick` 이 하고 채점은 `yEval` 이 한다. 둘을 같게 주면 회차 43 과 **같은 계산**이다
//   (그래서 회귀 검사가 공짜로 붙는다).

using namespace PE;

class MLTP3B0
{
public:
	static void Tick(RHI* rhi)
	{
		if (_done || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltp3b0"))
		{
			LogA("[mlt] ⏳ 회차 47은 **꺼져 있다**(`-mltp3b0`) — 미래 표적의 토큰 등가치 τ\n");
			_done = true; return;
		}
		if (!_banner) { _Banner(); _banner = true; }
		if (_st == kInit)  { _BeginSeed(rhi); return; }
		if (_st == kTrain) { _Train(); return; }
		_Eval();
	}

	static bool Done() { return _done; }

private:
	// ── 회차 43 과 **같은** 학습 설정 ─────────────────────────────
	static constexpr uint32 kSeeds = 12u, kTrainF = 128u, kTestF = 8u;
	static constexpr uint32 kPoolCap = kTrainF + kTestF, kSteps = 4800u, kN = 1000u, kLocal = 8u;
	static constexpr uint32 kPerTick = 8u, kTestEpisode = 1u;
	static constexpr uint32 kCandidates = MLTP2Cfg::kPatches * kLocal;      // 512
	static constexpr uint32 kFrameVals  = MLTP2Cfg::kPatches * MLTP2Cfg::kPix;
	// ── 이 회차의 축 ──────────────────────────────────────────────
	static constexpr uint32 kPersist = 8u, kMaxPick = 16u;
	static constexpr uint32 kDeltas = 3u;
	static constexpr uint32 kDelta[kDeltas] = { 1u, 2u, 4u };
	static constexpr uint32 kTauCap = kMaxPick + 1u;                        // 17 = `>16`
	// ── 위생(회귀 검사) ───────────────────────────────────────────
	static constexpr float kFullExpected = 0.03977f, kFullTol = 0.00005f;
	static constexpr float kSelfExpected = 0.218f,   kSelfTol = 0.010f;
	// ── 관문 ──────────────────────────────────────────────────────
	static constexpr uint32 kTauPass = 9u, kSignPass = 10u, kTrendPass = 6u;

	enum { kInit, kTrain, kEval };

	inline static MLTP2Enc _E;
	inline static bool _done = false, _banner = false;
	inline static uint32 _seed = 0u, _step = 0u, _ev = 0u;
	inline static int _st = kInit;
	inline static double _sumGpu = 0.0;
	inline static Array<float> _tgtTest, _idsAll, _magAll, _code;

	inline static float _mGpu[kSeeds]  = { 0.0f };
	inline static float _mCpu[kSeeds]  = { 0.0f };
	inline static float _gSelf[kSeeds] = { 0.0f };
	inline static float _dg[kDeltas][kSeeds]     = { { 0.0f } };
	inline static float _g8self[kDeltas][kSeeds] = { { 0.0f } };
	inline static float _g8fut[kDeltas][kSeeds]  = { { 0.0f } };
	inline static float _jac[kDeltas][kSeeds]    = { { 0.0f } };
	inline static uint32 _tau[kDeltas][kSeeds]   = { { 0u } };
	inline static bool  _ok[kDeltas][kSeeds]     = { { false } };

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] ⏳ **회차 47 · P3-B0 — 미래 표적은 다른 것을 남기나**(오라클 · 학습 표적 변경 0)\n");
		LogA("[mlt] ⏳   회차 43 과 같은 학습: 씨앗 %u · 학습 %u프레임 · %u스텝 · N=%u local k=%u\n",
			kSeeds, kTrainF, kSteps, kN, kLocal);
		LogA("[mlt] ⏳   표적만 가른다: 선택 `t` ↔ `t+Δ` · Δ ∈ {1,2,4} · 후보 풀은 프레임 `t` 의 %u개\n",
			kCandidates);
		LogA("[mlt] ⏳   표제① τ≥%u 가 %u/%u · 표제②(추세) ΔG 완전단조 %u/%u · Q=2\n",
			kTauPass, kSignPass, kSeeds, kTrendPass, kSeeds);
		LogA("[mlt] ⏳   위생: full **%.5f±%.5f** 재현 · 자기표적 G8 **%.3f±%.3f** 재현 · 양수 분모\n",
			(double)kFullExpected, (double)kFullTol, (double)kSelfExpected, (double)kSelfTol);
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

	// ══════════════════════════════════════════════════════════════════
	// 🌱 씨앗 하나 — ⚠️ 회차 43 의 `_BeginSeed` 와 **같은 코퍼스**다.
	// ══════════════════════════════════════════════════════════════════
	static void _BeginSeed(RHI* rhi)
	{
		if (_seed == 0u)
		{
			if (!_E.Setup(rhi, kPoolCap, kN)) { _Fail("준비 실패"); return; }
		}
		else if (!_E.ResetSeed()) { _Fail("되돌리기 실패"); return; }
		_E.SetK(kLocal); _E.SetSelectAbs(false); _E.SetResidualSwap(false); _E.SetCoeffSweep(false);

		Array<float> fr, tg; fr.Reset(0); tg.Reset(0); _tgtTest.Reset(0);
		ImageFormat::Bitmap bmp; Bytes packed;
		{
			MLTWorld w; w.Reset(_seed, 0u, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
			for (uint32 f = 0; f < kTrainF; ++f)
			{
				w.Step();
				if (!w.Render(bmp) || !MLTWorld::Pack(bmp, nullptr, packed)) { _Fail("Render/Pack(학습)"); return; }
				MLTP2Enc::AppendFrame(fr, tg, (const uint8*)packed.GetData());
			}
		}
		{
			// ⚠️ 시험 프레임은 **같은 에피소드의 이어지는 스텝**이다 ⇒ `f` 와 `f+Δ` 가 시간 경계다.
			MLTWorld w; w.Reset(_seed, kTestEpisode, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
			for (uint32 f = 0; f < kTestF; ++f)
			{
				w.Step();
				if (!w.Render(bmp) || !MLTWorld::Pack(bmp, nullptr, packed)) { _Fail("Render/Pack(시험)"); return; }
				const uint8* px = (const uint8*)packed.GetData();
				MLTP2Enc::AppendFrame(fr, tg, px);
				Array<float> one, dummy; one.Reset(0); dummy.Reset(0);
				MLTP2Enc::AppendFrame(dummy, one, px);
				for (uint32 i = 0; i < one.Count(); ++i) _tgtTest.Add(one[i]);
			}
		}
		if (!_E.WritePool(fr, tg, kPoolCap)) { _Fail("풀 업로드 실패"); return; }
		_idsAll.Reset(0); _magAll.Reset(0); _sumGpu = 0.0; _step = 0u; _ev = 0u; _st = kTrain;
	}

	static void _Train()
	{
		for (uint32 i = 0; i < kPerTick && _step < kSteps; ++i)
		{
			_E.SetFrame(_step % kTrainF);
			if (!_E.Forward() || !_E.Backward() || !_E.AdamStep(1.0f)) { _Fail("학습 디스패치"); return; }
			++_step;
		}
		if (_step >= kSteps) { _st = kEval; _ev = 0u; }
	}

	static void _Eval()
	{
		if (_ev > 0u)
		{
			float m = 0.0f; bool fin = true;
			if (!_E.ReadMse(m, fin) || !fin) { _Fail("평가 MSE 리드백"); return; }
			_sumGpu += (double)m;
			Array<float> id, mg;
			if (!_E.ReadAct(id, mg) || id.Count() != kCandidates || mg.Count() != kCandidates)
			{ _Fail("활성 리드백/크기"); return; }
			for (uint32 i = 0; i < kCandidates; ++i) { _idsAll.Add(id[i]); _magAll.Add(mg[i]); }
		}
		if (_ev < kTestF)
		{
			_E.SetFrame(kTrainF + _ev);
			if (!_E.Forward()) { _Fail("평가 forward"); return; }
			++_ev; return;
		}
		_JudgeSeed();
	}

	// ══════════════════════════════════════════════════════════════════
	// 🧮 CPU 진단 원시형 — ⚠️ 회차 43 의 것과 **같은 식**이다(재구성은 패치 로컬이다).
	// ══════════════════════════════════════════════════════════════════
	static void _Zero(Array<float>& r) { r.Reset(0); for (uint32 i = 0; i < kFrameVals; ++i) r.Add(0.0f); }

	static bool _Candidate(uint32 frame, uint32 c, uint32& patch, uint32& id, float& mag)
	{
		if (frame >= kTestF || c >= kCandidates) return false;
		const uint32 at = frame * kCandidates + c;
		const float fid = _idsAll[at];
		if (!(fid >= 0.0f) || fid >= (float)kN) return false;
		patch = c / kLocal; id = (uint32)fid; mag = _magAll[at];
		return true;
	}

	static bool _Add(Array<float>& r, uint32 frame, uint32 c)
	{
		uint32 patch = 0u, id = 0u; float mag = 0.0f;
		if (!_Candidate(frame, c, patch, id, mag)) return false;
		const float* atom = _code.Data() + id * MLTP2Cfg::kPix;
		float* out = r.Data() + patch * MLTP2Cfg::kPix;
		for (uint32 d = 0; d < MLTP2Cfg::kPix; ++d) out[d] += mag * atom[d];
		return true;
	}

	static double _Sse(const Array<float>& r, const float* y)
	{
		double s = 0.0;
		for (uint32 i = 0; i < kFrameVals; ++i) { const double d = (double)y[i] - (double)r[i]; s += d * d; }
		return s;
	}

	static double _Improvement(const Array<float>& r, const float* y, uint32 frame, uint32 c)
	{
		uint32 patch = 0u, id = 0u; float mag = 0.0f;
		if (!_Candidate(frame, c, patch, id, mag)) return -1.0e300;
		const float* atom = _code.Data() + id * MLTP2Cfg::kPix;
		const float* cur  = r.Data() + patch * MLTP2Cfg::kPix;
		const float* tgt  = y + patch * MLTP2Cfg::kPix;
		double gain = 0.0;
		for (uint32 d = 0; d < MLTP2Cfg::kPix; ++d)
		{
			const double oldD = (double)tgt[d] - (double)cur[d];
			const double newD = oldD - (double)mag * (double)atom[d];
			gain += oldD * oldD - newD * newD;
		}
		return gain;
	}

	// ⭐ **이 회차의 심장** — 선택은 `yPick`, 채점은 `yEval`.
	//   `sse[m]` = 앞 `m` 개를 더한 뒤의 `yEval` 기준 SSE(`m = 0..kMaxPick`).
	//   `picked[m]` = `m` 번째로 고른 후보(못 고르면 `kCandidates`).
	//   ⚠️ 정지 조건은 회차 43 의 오라클 그대로(개선 ≤ 0 이면 멈추고 그 값을 뒤로 이어 채운다).
	static bool _GreedyCurve(uint32 frame, const float* yPick, const float* yEval,
		double* sse, uint32* picked)
	{
		Array<float> r; _Zero(r);
		Array<uint8> used; used.Reset(0);
		for (uint32 c = 0; c < kCandidates; ++c) used.Add(0u);
		sse[0] = _Sse(r, yEval);
		for (uint32 step = 0; step < kMaxPick; ++step)
		{
			uint32 pick = 0u; bool found = false; double best = 0.0;
			for (uint32 c = 0; c < kCandidates; ++c)
			{
				if (used[c] != 0u) continue;
				const double score = _Improvement(r, yPick, frame, c);
				// 엄격 비교라 동점은 후보 순서(patch → local slot)가 이긴다 — 회차 43 과 같다.
				if (!found || score > best) { best = score; pick = c; found = true; }
			}
			if (!found || best <= 0.0)
			{
				for (uint32 m = step; m < kMaxPick; ++m) { sse[m + 1u] = sse[step]; picked[m] = kCandidates; }
				return true;
			}
			used.Data()[pick] = 1u;
			if (!_Add(r, frame, pick)) return false;
			picked[step] = pick;
			sse[step + 1u] = _Sse(r, yEval);
		}
		return true;
	}

	static void _JudgeSeed()
	{
		if (!_E.ReadCodebook(_code) || _code.Count() != kN * MLTP2Cfg::kPix) { _Fail("코드북 리드백/크기"); return; }
		if (_idsAll.Count() != kTestF * kCandidates || _tgtTest.Count() != kTestF * kFrameVals)
		{ _Fail("CPU 진단 입력 크기"); return; }

		double selfSse[kMaxPick + 1u]; uint32 selfPick[kMaxPick];
		double futSse[kMaxPick + 1u];  uint32 futPick[kMaxPick];

		// ── 위생 ①: 회차 43 재현(표적 = 자기 자신 · 8프레임 전부) ─────────────
		{
			double zero = 0.0, full = 0.0, sse8 = 0.0;
			for (uint32 f = 0; f < kTestF; ++f)
			{
				const float* y = _tgtTest.Data() + f * kFrameVals;
				Array<float> r0; _Zero(r0); zero += _Sse(r0, y);
				Array<float> rf; _Zero(rf);
				for (uint32 c = 0; c < kCandidates; ++c)
					if (!_Add(rf, f, c)) { _Fail("full CPU 재구성"); return; }
				full += _Sse(rf, y);
				if (!_GreedyCurve(f, y, y, selfSse, selfPick)) { _Fail("자기표적 탐욕"); return; }
				sse8 += selfSse[kPersist];
			}
			const double denom = zero - full;
			_mGpu[_seed]  = (float)(_sumGpu / (double)kTestF);
			_mCpu[_seed]  = (float)(full / (double)(kTestF * kFrameVals));
			_gSelf[_seed] = (denom > 0.0) ? (float)((zero - sse8) / denom) : 0.0f;
		}

		// ── 본 측정: Δ 마다 「선택 t」 ↔ 「선택 t+Δ」 ───────────────────────
		for (uint32 di = 0; di < kDeltas; ++di)
		{
			const uint32 d = kDelta[di];
			double zero = 0.0, full = 0.0, curve[kMaxPick + 1u], fut8 = 0.0;
			for (uint32 m = 0; m <= kMaxPick; ++m) curve[m] = 0.0;
			uint32 pairs = 0u, inter = 0u;
			for (uint32 f = 0; f + d < kTestF; ++f)
			{
				const float* yEval = _tgtTest.Data() + (f + d) * kFrameVals;   // 표적 = 미래 프레임
				Array<float> r0; _Zero(r0); zero += _Sse(r0, yEval);
				Array<float> rf; _Zero(rf);
				for (uint32 c = 0; c < kCandidates; ++c)
					if (!_Add(rf, f, c)) { _Fail("full CPU 재구성(Δ)"); return; }
				full += _Sse(rf, yEval);

				const float* yPickSelf = _tgtTest.Data() + f * kFrameVals;     // ㈀ 선택 표적 = 지금
				if (!_GreedyCurve(f, yPickSelf, yEval, selfSse, selfPick)) { _Fail("㈀ 탐욕"); return; }
				if (!_GreedyCurve(f, yEval,     yEval, futSse,  futPick))  { _Fail("㈁ 탐욕"); return; }
				for (uint32 m = 0; m <= kMaxPick; ++m) curve[m] += selfSse[m];
				fut8 += futSse[kPersist];

				for (uint32 a = 0; a < kPersist; ++a)
				{
					if (selfPick[a] >= kCandidates) continue;
					for (uint32 b = 0; b < kPersist; ++b)
						if (futPick[b] == selfPick[a]) { ++inter; break; }
				}
				++pairs;
			}
			const double denom = zero - full;
			_ok[di][_seed] = (denom > 0.0) && (pairs > 0u);
			if (!_ok[di][_seed]) continue;
			_g8self[di][_seed] = (float)((zero - curve[kPersist]) / denom);
			_g8fut[di][_seed]  = (float)((zero - fut8) / denom);
			_dg[di][_seed]     = (float)((curve[kPersist] - fut8) / denom);
			// ★ `denom > 0` 이라 `G` 비교 = SSE 비교다(나눗셈 없이 τ 를 정한다).
			uint32 tau = kTauCap;
			for (uint32 m = kPersist; m <= kMaxPick; ++m)
				if (curve[m] <= fut8) { tau = m; break; }
			_tau[di][_seed] = tau;
			_jac[di][_seed] = (float)inter / (float)(pairs * kPersist);
		}

		LogA("[mlt] ⏳ [%2u/%u] 씨앗 %u — full GPU/CPU **%.5f/%.5f** · 자기표적 G8 **%.3f**\n",
			_seed + 1u, kSeeds, _seed, (double)_mGpu[_seed], (double)_mCpu[_seed], (double)_gSelf[_seed]);
		for (uint32 di = 0; di < kDeltas; ++di)
		{
			if (!_ok[di][_seed]) { LogA("[mlt] ⏳        Δ=%u — ⚠️ 분모 비양수 ⇒ 이 칸은 안 읽는다\n", kDelta[di]); continue; }
			LogA("[mlt] ⏳        Δ=%u — G8 지금표적 **%.3f** ↔ 미래표적 **%.3f** · ΔG **%+.4f** · **τ %s%u** · 자카드 %.3f\n",
				kDelta[di], (double)_g8self[di][_seed], (double)_g8fut[di][_seed], (double)_dg[di][_seed],
				(_tau[di][_seed] >= kTauCap) ? ">" : "", (_tau[di][_seed] >= kTauCap) ? kMaxPick : _tau[di][_seed],
				(double)_jac[di][_seed]);
		}
		++_seed;
		if (_seed >= kSeeds) { _Summary(); return; }
		_st = kInit;
	}

	static void _Summary()
	{
		// ── 위생 ① 회귀 검사 ──────────────────────────────────────
		double sg = 0.0, sc = 0.0, ss = 0.0; float maxDiff = 0.0f;
		for (uint32 s = 0; s < kSeeds; ++s)
		{
			sg += _mGpu[s]; sc += _mCpu[s]; ss += _gSelf[s];
			const float df = Abs(_mGpu[s] - _mCpu[s]); if (df > maxDiff) maxDiff = df;
		}
		const float mg = (float)(sg / kSeeds), mc = (float)(sc / kSeeds), ms = (float)(ss / kSeeds);
		const bool fullOk = Abs(mg - kFullExpected) <= kFullTol;
		const bool selfOk = Abs(ms - kSelfExpected) <= kSelfTol;

		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] ⏳ **회차 47 · P3-B0 결과**\n");
		LogA("[mlt] ⏳   회귀 — full GPU/CPU **%.5f/%.5f**(최대 |차| %.8f · 등록 %.5f±%.5f) → %s\n",
			(double)mg, (double)mc, (double)maxDiff, (double)kFullExpected, (double)kFullTol,
			fullOk ? "통과" : "⛔");
		LogA("[mlt] ⏳   회귀 — 자기표적 평균 G8 **%.3f**(등록 %.3f±%.3f) → %s\n",
			(double)ms, (double)kSelfExpected, (double)kSelfTol, selfOk ? "통과" : "⛔");

		for (uint32 di = 0; di < kDeltas; ++di)
		{
			double a = 0.0, b = 0.0, g = 0.0, j = 0.0; uint32 n = 0u, tsum = 0u, cap = 0u, pass = 0u;
			for (uint32 s = 0; s < kSeeds; ++s)
			{
				if (!_ok[di][s]) continue;
				++n; a += _g8self[di][s]; b += _g8fut[di][s]; g += _dg[di][s]; j += _jac[di][s];
				tsum += _tau[di][s]; if (_tau[di][s] >= kTauCap) ++cap;
				if (_tau[di][s] >= kTauPass) ++pass;
			}
			if (n == 0u) { LogA("[mlt] ⏳   Δ=%u — 읽은 씨앗 0 ⇒ 판정불가\n", kDelta[di]); continue; }
			LogA("[mlt] ⏳   Δ=%u (읽은 씨앗 %u/%u) — G8 지금 **%.3f** ↔ 미래 **%.3f** · ΔG **%+.4f** · 평균 τ **%.1f**(상한도달 %u) · 자카드 **%.3f** · τ≥%u **%u/%u**\n",
				kDelta[di], n, kSeeds, a / n, b / n, g / n, (double)tsum / (double)n, cap, j / n,
				kTauPass, pass, kSeeds);
		}

		// ── 표제② 추세: ΔG 완전 단조 (귀무 1/6) — ⚠️ 세 Δ 가 다 읽히는 씨앗만 ────
		uint32 trend = 0u, trendN = 0u;
		for (uint32 s = 0; s < kSeeds; ++s)
		{
			if (!_ok[0][s] || !_ok[1][s] || !_ok[2][s]) continue;
			++trendN;
			if (_dg[0][s] < _dg[1][s] && _dg[1][s] < _dg[2][s]) ++trend;
		}
		uint32 head = 0u;
		for (uint32 s = 0; s < kSeeds; ++s) if (_ok[0][s] && _tau[0][s] >= kTauPass) ++head;

		const bool hyg = fullOk && selfOk;
		const bool p1 = (head >= kSignPass), p2 = (trend >= kTrendPass);
		LogA("[mlt] ⏳   **표제① Δ=1 · τ≥%u — %u/%u**(필요 %u) → %s\n",
			kTauPass, head, kSeeds, kSignPass, p1 ? "통과" : "⛔");
		LogA("[mlt] ⏳   **표제② 추세 · ΔG 완전단조 — %u/%u**(읽은 %u · 필요 %u · 귀무 1/6) → %s\n",
			trend, kSeeds, trendN, kTrendPass, p2 ? "통과" : "⛔");
		if (!hyg)
			LogA("[mlt] ⏳   ⭐ 판정 = ⛔ **판정불가** — 회귀 검사가 깨졌다(모델이 그 모델이 아니다). 손잡이를 훑지 않는다.\n");
		else if (p1)
			LogA("[mlt] ⏳   ⭐ 판정 = ✅ **미래 표적은 다른 것을 남긴다** ⇒ 회차 48 = 학습 표적을 시간 너머로 옮긴다\n");
		else
			LogA("[mlt] ⏳   ⭐ 판정 = ⛔ **표적을 바꾸는 것만으로는 다른 것이 안 남는다** ⇒ 재구성 표적 계열을 닫고 회차 48 = P3 몸통\n");
		LogA("[mlt] ⏳   ⚠️ 오라클 상한 진단이다 — *\"학습이 그것을 찾는다\"* 로 인용하지 않는다.\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		_E.Destroy(); _done = true;
	}

	static void _Fail(const char* why)
	{
		LogA("[mlt] ⏳ ⛔ %s (씨앗 %u)\n", why, _seed);
		_E.Destroy(); _done = true;
	}
};
