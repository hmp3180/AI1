// mltp3a0.cw — 🛑 **회차 43 · P2→P3 지속 병목 상한 진단** (`-mltp3a0`)
//
// ⚠️ 모델을 더 학습시키는 회차가 아니다. 안정한 P2 기준선의 로컬 활성 64×8개 가운데
// 프레임 전체에 남길 8개(순차 예비 16개)가 현재 재구성 이득을 얼마나 보존하는지만 CPU에서 잰다.
// 팔·집계·갈래는 측정 전에 `mltlog_1.md` 회차 43에 고정했다.

using namespace PE;

class MLTP3A0
{
public:
	static void Tick(RHI* rhi)
	{
		if (_done || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltp3a0"))
		{
			LogA("[mlt] 🛑 회차 43은 **꺼져 있다**(`-mltp3a0`) — 상한 G≥0.50: k=8 **0/12**, k=16 **1/12** ⇒ 현재 로컬 표현은 지속 재료 아님\n");
			_done = true; return;
		}
		if (!_banner) { _Banner(); _banner = true; }
		if (_st == kInit)  { _BeginSeed(rhi); return; }
		if (_st == kTrain) { _Train(); return; }
		if (_st == kEval)  { _Eval(); return; }
	}

	static bool Done() { return _done; }

private:
	static constexpr uint32 kSeeds = 12u, kTrainF = 128u, kTestF = 8u;
	static constexpr uint32 kPoolCap = kTrainF + kTestF, kSteps = 4800u, kN = 1000u, kLocal = 8u;
	static constexpr uint32 kPerTick = 4u, kTestEpisode = 1u;
	static constexpr uint32 kCandidates = MLTP2Cfg::kPatches * kLocal;
	static constexpr uint32 kFrameVals = MLTP2Cfg::kPatches * MLTP2Cfg::kPix;
	static constexpr uint32 kCaps = 2u;
	static constexpr uint32 kPersist[kCaps] = { 8u, 16u };
	static constexpr float kFullExpected = 0.03977f, kFullTol = 0.00005f;
	static constexpr float kGainGate = 0.50f, kSelectorFrac = 0.75f;
	enum { kInit, kTrain, kEval };
	enum { kFixed, kQ, kOracle };

	inline static MLTP2Enc _E;
	inline static bool _done = false, _banner = false;
	inline static uint32 _seed = 0u, _step = 0u, _ev = 0u;
	inline static int _st = kInit;
	inline static double _sumGpu = 0.0;
	inline static Array<float> _tgtTest, _idsAll, _magAll, _code;
	inline static float _mGpu[kSeeds] = { 0.0f }, _mCpu[kSeeds] = { 0.0f };
	inline static float _gFixed[kCaps][kSeeds] = { { 0.0f } };
	inline static float _gQ[kCaps][kSeeds] = { { 0.0f } };
	inline static float _gOracle[kCaps][kSeeds] = { { 0.0f } };
	inline static bool _denomOk[kSeeds] = { false };

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] ⏳ **회차 43 · P3-A0 지속 병목 상한** — 씨앗 %u · local %u×%u=%u → persist 8(예비 16)\n",
			kSeeds, MLTP2Cfg::kPatches, kLocal, kCandidates);
		LogA("[mlt] ⏳   full · 고정 전단사 · |mag|·||code||₂ · 표적 탐욕 상한 · 8프레임 SSE 선합산\n");
		LogA("[mlt] ⏳   새 학습 파라미터/GPU 커널/P3 몸통 0 · 측정 뒤 종료 심사\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

	static void _BeginSeed(RHI* rhi)
	{
		if (_seed == 0u)
		{
			if (!_E.Setup(rhi, kPoolCap, kN))
			{ LogA("[mlt] ⏳ 준비 실패\n"); _done = true; return; }
		}
		else if (!_E.ResetSeed()) { LogA("[mlt] ⏳ 되돌리기 실패\n"); _done = true; return; }
		_E.SetK(kLocal); _E.SetSelectAbs(false); _E.SetResidualSwap(false); _E.SetCoeffSweep(false);

		Array<float> fr, tg; fr.Reset(0); tg.Reset(0); _tgtTest.Reset(0);
		ImageFormat::Bitmap bmp; Bytes packed;
		{
			MLTWorld w; w.Reset(_seed, 0u, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
			for (uint32 f = 0; f < kTrainF; ++f)
			{
				w.Step();
				if (!w.Render(bmp) || !MLTWorld::Pack(bmp, nullptr, packed))
				{ LogA("[mlt] ⏳ Render/Pack 실패(학습)\n"); _done = true; return; }
				MLTP2Enc::AppendFrame(fr, tg, (const uint8*)packed.GetData());
			}
		}
		{
			MLTWorld w; w.Reset(_seed, kTestEpisode, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
			for (uint32 f = 0; f < kTestF; ++f)
			{
				w.Step();
				if (!w.Render(bmp) || !MLTWorld::Pack(bmp, nullptr, packed))
				{ LogA("[mlt] ⏳ Render/Pack 실패(시험)\n"); _done = true; return; }
				const uint8* px = (const uint8*)packed.GetData();
				MLTP2Enc::AppendFrame(fr, tg, px);
				Array<float> one, dummy; one.Reset(0); dummy.Reset(0);
				MLTP2Enc::AppendFrame(dummy, one, px);
				for (uint32 i = 0; i < one.Count(); ++i) _tgtTest.Add(one[i]);
			}
		}
		if (!_E.WritePool(fr, tg, kPoolCap)) { LogA("[mlt] ⏳ 풀 업로드 실패\n"); _done = true; return; }
		_idsAll.Reset(0); _magAll.Reset(0); _sumGpu = 0.0; _step = 0u; _ev = 0u; _st = kTrain;
	}

	static void _Train()
	{
		for (uint32 i = 0; i < kPerTick && _step < kSteps; ++i)
		{
			_E.SetFrame(_step % kTrainF);
			if (!_E.Forward() || !_E.Backward() || !_E.AdamStep(1.0f))
			{ LogA("[mlt] ⏳ 학습 실패(씨앗 %u 스텝 %u)\n", _seed, _step); _done = true; return; }
			++_step;
		}
		if (_step >= kSteps) { _st = kEval; _ev = 0u; }
	}

	static void _Eval()
	{
		if (_ev > 0u)
		{
			float m = 0.0f; bool fin = true;
			if (!_E.ReadMse(m, fin) || !fin) { LogA("[mlt] ⏳ 평가 MSE 리드백 실패/비유한\n"); _done = true; return; }
			_sumGpu += (double)m;
			Array<float> id, mg;
			if (!_E.ReadAct(id, mg) || id.Count() != kCandidates || mg.Count() != kCandidates)
			{ LogA("[mlt] ⏳ 활성 리드백 실패/크기 불일치\n"); _done = true; return; }
			for (uint32 i = 0; i < kCandidates; ++i) { _idsAll.Add(id[i]); _magAll.Add(mg[i]); }
		}
		if (_ev < kTestF)
		{
			_E.SetFrame(kTrainF + _ev);
			if (!_E.Forward()) { LogA("[mlt] ⏳ 평가 forward 실패\n"); _done = true; return; }
			++_ev; return;
		}
		_JudgeSeed();
	}

	static void _Zero(Array<float>& r)
	{
		r.Reset(0); for (uint32 i = 0; i < kFrameVals; ++i) r.Add(0.0f);
	}

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
		for (uint32 i = 0; i < kFrameVals; ++i)
		{ const double d = (double)y[i] - (double)r[i]; s += d * d; }
		return s;
	}

	static double _Improvement(const Array<float>& r, const float* y, uint32 frame, uint32 c)
	{
		uint32 patch = 0u, id = 0u; float mag = 0.0f;
		if (!_Candidate(frame, c, patch, id, mag)) return -1.0e300;
		const float* atom = _code.Data() + id * MLTP2Cfg::kPix;
		const float* cur = r.Data() + patch * MLTP2Cfg::kPix;
		const float* tgt = y + patch * MLTP2Cfg::kPix;
		double gain = 0.0;
		for (uint32 d = 0; d < MLTP2Cfg::kPix; ++d)
		{
			const double oldD = (double)tgt[d] - (double)cur[d];
			const double newD = oldD - (double)mag * (double)atom[d];
			gain += oldD * oldD - newD * newD;
		}
		return gain;
	}

	static bool _Subset(uint32 frame, const float* y, const Array<float>& norm, int mode,
		double& sse8, double& sse16)
	{
		Array<float> r; _Zero(r);
		Array<uint8> used; used.Reset(0); for (uint32 c = 0; c < kCandidates; ++c) used.Add(0u);
		bool got8 = false;
		for (uint32 step = 0; step < kPersist[1]; ++step)
		{
			uint32 pick = 0u; bool found = false; double best = 0.0;
			if (mode == kFixed)
			{
				pick = (73u * step + 19u) % kCandidates; found = true;
			}
			else
			{
				for (uint32 c = 0; c < kCandidates; ++c)
				{
					if (used[c] != 0u) continue;
					double score = 0.0;
					if (mode == kQ)
					{
						uint32 patch = 0u, id = 0u; float mag = 0.0f;
						if (!_Candidate(frame, c, patch, id, mag)) return false;
						score = (double)Abs(mag) * (double)norm[id];
					}
					else score = _Improvement(r, y, frame, c);
					// 엄격 비교라 동점은 후보 순서(patch → local slot → id)가 이긴다.
					if (!found || score > best) { best = score; pick = c; found = true; }
				}
				if (mode == kOracle && (!found || best <= 0.0)) found = false;
			}
			if (!found)
			{
				const double now = _Sse(r, y);
				if (!got8) { sse8 = now; got8 = true; }
				sse16 = now; return true;
			}
			used.Data()[pick] = 1u;
			if (!_Add(r, frame, pick)) return false;
			if (step + 1u == kPersist[0]) { sse8 = _Sse(r, y); got8 = true; }
		}
		sse16 = _Sse(r, y);
		return got8;
	}

	static void _JudgeSeed()
	{
		if (!_E.ReadCodebook(_code) || _code.Count() != kN * MLTP2Cfg::kPix)
		{ LogA("[mlt] ⏳ 코드북 리드백 실패/크기 불일치\n"); _done = true; return; }
		if (_idsAll.Count() != kTestF * kCandidates || _tgtTest.Count() != kTestF * kFrameVals)
		{ LogA("[mlt] ⏳ CPU 진단 입력 크기 불일치\n"); _done = true; return; }

		Array<float> norm; norm.Reset(0);
		for (uint32 id = 0; id < kN; ++id)
		{
			double sq = 0.0; const float* a = _code.Data() + id * MLTP2Cfg::kPix;
			for (uint32 d = 0; d < MLTP2Cfg::kPix; ++d) sq += (double)a[d] * (double)a[d];
			norm.Add((float)Sqrt((float)sq));
		}

		double zero = 0.0, full = 0.0;
		double fixed[kCaps] = { 0.0, 0.0 }, q[kCaps] = { 0.0, 0.0 }, oracle[kCaps] = { 0.0, 0.0 };
		for (uint32 f = 0; f < kTestF; ++f)
		{
			const float* y = _tgtTest.Data() + f * kFrameVals;
			Array<float> r0; _Zero(r0); zero += _Sse(r0, y);
			Array<float> rf; _Zero(rf);
			for (uint32 c = 0; c < kCandidates; ++c)
				if (!_Add(rf, f, c)) { LogA("[mlt] ⏳ full CPU 재구성 실패\n"); _done = true; return; }
			full += _Sse(rf, y);
			double f8 = 0.0, f16 = 0.0, q8 = 0.0, q16 = 0.0, o8 = 0.0, o16 = 0.0;
			if (!_Subset(f, y, norm, kFixed, f8, f16) || !_Subset(f, y, norm, kQ, q8, q16) ||
				!_Subset(f, y, norm, kOracle, o8, o16))
			{ LogA("[mlt] ⏳ 부분집합 CPU 재구성 실패\n"); _done = true; return; }
			fixed[0] += f8; fixed[1] += f16; q[0] += q8; q[1] += q16; oracle[0] += o8; oracle[1] += o16;
		}

		const double count = (double)(kTestF * kFrameVals);
		const double denom = zero - full;
		_mGpu[_seed] = (float)(_sumGpu / (double)kTestF);
		_mCpu[_seed] = (float)(full / count);
		_denomOk[_seed] = denom > 0.0;
		for (uint32 cap = 0; cap < kCaps; ++cap)
		{
			_gFixed[cap][_seed] = (denom > 0.0) ? (float)((zero - fixed[cap]) / denom) : 0.0f;
			_gQ[cap][_seed] = (denom > 0.0) ? (float)((zero - q[cap]) / denom) : 0.0f;
			_gOracle[cap][_seed] = (denom > 0.0) ? (float)((zero - oracle[cap]) / denom) : 0.0f;
		}
		LogA("[mlt] ⏳ [%2u/%u] 씨앗 %u — full GPU/CPU **%.5f/%.5f** · G8 고정/q/상한 **%.3f/%.3f/%.3f** · 분모 %s\n",
			_seed + 1u, kSeeds, _seed, (double)_mGpu[_seed], (double)_mCpu[_seed],
			(double)_gFixed[0][_seed], (double)_gQ[0][_seed], (double)_gOracle[0][_seed],
			_denomOk[_seed] ? "양수" : "비양수");
		++_seed;
		if (_seed >= kSeeds) { _Summary(); _E.Destroy(); _done = true; return; }
		_st = kInit;
	}

	static void _ReportCap(uint32 cap)
	{
		double sf = 0.0, sq = 0.0, so = 0.0;
		uint32 upper = 0u, wins = 0u;
		for (uint32 s = 0; s < kSeeds; ++s)
		{
			sf += _gFixed[cap][s]; sq += _gQ[cap][s]; so += _gOracle[cap][s];
			if (_gOracle[cap][s] >= kGainGate) ++upper;
			if (_gQ[cap][s] > _gFixed[cap][s]) ++wins;
		}
		const float mf = (float)(sf / kSeeds), mq = (float)(sq / kSeeds), mo = (float)(so / kSeeds);
		const float frac = (mo > 1.0e-9f) ? mq / mo : 0.0f;
		LogA("[mlt] ⏳   k=%u — 평균 G 고정/q/상한 **%.3f/%.3f/%.3f** · 상한 G≥%.2f %u/%u\n",
			kPersist[cap], (double)mf, (double)mq, (double)mo, (double)kGainGate, upper, kSeeds);
		LogA("[mlt] ⏳          q>고정 %u/%u · 평균 Gq/G상한 **%.1f%%** (문턱 10/12 · %.0f%%)\n",
			wins, kSeeds, (double)(100.0f * frac), (double)(100.0f * kSelectorFrac));
	}

	static void _Summary()
	{
		double sg = 0.0, sc = 0.0; float maxDiff = 0.0f; uint32 denom = 0u;
		for (uint32 s = 0; s < kSeeds; ++s)
		{
			sg += _mGpu[s]; sc += _mCpu[s]; if (_denomOk[s]) ++denom;
			const float d = Abs(_mGpu[s] - _mCpu[s]); if (d > maxDiff) maxDiff = d;
		}
		const float mg = (float)(sg / kSeeds), mc = (float)(sc / kSeeds);
		const bool fullOk = Abs(mg - kFullExpected) <= kFullTol && denom == kSeeds;
		LogA("[mlt] ══════════════════════════════════════════════════\n[mlt] ⏳ **회차 43 · P3-A0 결과**\n");
		LogA("[mlt] ⏳   full GPU/CPU **%.5f/%.5f** · 최대 |차| %.8f · 등록범위 %.5f±%.5f · 양수 분모 %u/%u\n",
			(double)mg, (double)mc, (double)maxDiff, (double)kFullExpected, (double)kFullTol, denom, kSeeds);
		_ReportCap(0u);
		if (!fullOk)
		{
			LogA("[mlt] ⏳   ⭐ 판정 = ⛔ 기준선 재현/분모 관문 실패 — 병목 효과 판정불가\n");
			LogA("[mlt] ══════════════════════════════════════════════════\n"); return;
		}

		uint32 cap = 0u, upper = 0u;
		for (uint32 s = 0; s < kSeeds; ++s) if (_gOracle[0][s] >= kGainGate) ++upper;
		if (upper < 10u)
		{
			_ReportCap(1u); cap = 1u; upper = 0u;
			for (uint32 s = 0; s < kSeeds; ++s) if (_gOracle[1][s] >= kGainGate) ++upper;
		}
		if (upper < 10u)
			LogA("[mlt] ⏳   ⭐ 판정 = ⛔ k=8·16 상한 실패 — 현재 패치 로컬 표현은 P3 지속 재료가 아님\n");
		else
		{
			double q = 0.0, o = 0.0; uint32 wins = 0u;
			for (uint32 s = 0; s < kSeeds; ++s)
			{
				q += _gQ[cap][s]; o += _gOracle[cap][s];
				if (_gQ[cap][s] > _gFixed[cap][s]) ++wins;
			}
			const float frac = (o > 1.0e-9) ? (float)(q / o) : 0.0f;
			if (wins >= 10u && frac >= kSelectorFrac)
				LogA("[mlt] ⏳   ⭐ 판정 = ✅ k=%u 지속 병목·의미 비의존 선택 통과 — 종료 심사 뒤 P3-A 등록 후보\n", kPersist[cap]);
			else
				LogA("[mlt] ⏳   ⭐ 판정 = ⛔ k=%u 상한은 통과, q 선택은 실패 — 선택 규칙의 자리(이번 회차 확장 없음)\n", kPersist[cap]);
		}
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}
};
