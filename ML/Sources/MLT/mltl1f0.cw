// mltl1f0.cw — 🧮 회차 143 · **변화 표적을 배우나**(계산 회차) (`-mlt -mltl1f0`)
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 143 이다.** ⭐ **하네스보다 먼저 썼다.**
//   **상위 캔버스: `모델이 변화 표적을 배우나` · 143~ = 1회차**(캔버스를 바꿨으므로 파일럿).
//
// ── ⭐ 표제 — ***몸통(2.7666)이 「학습 0 예측기」보다 나은가*** ────────
//   회차 142 가 `H(변화 표적) = 2.2663` 을 냈고 회차 141 의 몸통 변화 CE 는 **2.7666** 이었다.
//   ⚠️ 그런데 `H` 는 **시험 코퍼스 자신의** 주변분포라 그것만으로는 증명이 아니다.
//   ⇒ ★ 예측기를 **여럿** 놓고 나란히 잰다(하나로는 *"나쁘다"* 의 뜻이 안 정해진다 · 규율 16).
//
// ── ⭐ 먼저 — **「변화」가 두 종류다** ────────────────────────────
//   슬롯이 **id 오름차순 정렬**이므로(회차 55) 도형 하나가 사라지면 **슬롯이 전부 밀린다**
//   ⇒ 「그 슬롯의 id 가 바뀐다」가 ***집합이 안 바뀌어도 참***이 된다.
//   ⭐ 회차 140 이 그 틈을 이미 쟀다: **지속(슬롯) 78.3% ↔ 지속(집합) 90.0%**.
//     **(a) 밀림** — 표적 id 가 **지금 활성 8개 안**에 있다 ⇒ 정렬 규칙을 알면 좁혀진다
//     **(b) 새 id** — 지금 활성에 **없다** ⇒ 진짜 새로 들어온 것
//
// ── 📏 자 — 예측기 다섯(전부 **변화 표적당 나트** · 학습 0) ───────────────
//   ㉠a 학습 전체 주변분포 · ㉠b 학습 변화-only 주변분포 · ㉡ 시험 주변분포(**142 검산**) ·
//   ㉢ 그 슬롯의 지금 id 만 배제 · ⭐ ㉣ **밀림 인지**(α 를 **학습에서** 잰 혼합)
//   ⚠️ α 를 시험에서 재면 **훔쳐보는 것**이다.
//
// ── 🔮 예측(재기 전에 적었다) ────────────────────────────────────────────
//   ㉡ 2.266(검산) · ㉠a 2.6~3.2 · ㉠b 2.28~2.40 · ㉢ 2.1~2.35 · ⭐ ㉣ 1.3~1.9 ·
//   (a) 밀림 비율 **약 54%** · ⭐ 표제 = ⛔ **몸통이 ㉠b·㉢·㉣ 보다 나쁠 것**
//   ⚠️ 갈래: ㉠b 보다는 나은데 ㉣ 보다 나쁘면 ⇒ *"조금 배웠지만 **정렬 규칙**은 못 배웠다"*
// ══════════════════════════════════════════════════════════════════════════════

using namespace PE;

class MLTL1F0
{
public:
	static void Tick(RHI* rhi)
	{
		if (_done || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltl1f0"))
		{
			LogA("[mlt] 🧮 회차 143(변화 표적을 배우나)은 **꺼져 있다**(`-mltl1f0`)\n");
			_done = true; return;
		}
		if (!_banner) { _seeds = OS::CommandLine::Has("-mltdiag1") ? 1u : kSeedsMax; _Banner(); _banner = true; }
		if (_seed >= _seeds) { _Summary(); return; }
		if (_st == kEncInit)  { _EncBegin(rhi); return; }
		if (_st == kEncTrain) { _EncTrain(); return; }
		if (_st == kGather)   { _Gather(); return; }
		_Measure();
	}

	static bool Done() { return _done; }

private:
	static constexpr uint32 kSeedsMax = 12u;
	inline static uint32 _seeds = kSeedsMax;

	static constexpr uint32 kEncF = 32u, kEncSteps = 1200u, kEncPerTick = 8u;
	static constexpr uint32 kN = 250u, kLocal = 8u;
	static constexpr uint32 kTime  = MLTP3Ctx::kTime;      // 8
	static constexpr uint32 kBatch = MLTP3Ctx::kBatch;     // 8
	static constexpr uint32 kSlots = MLTP3Ctx::kPersist;   // 8
	static constexpr uint32 kStateAx = MLTP3Ctx::kStateAx; // 5
	static constexpr uint32 kCandidates = MLTP2Cfg::kPatches * kLocal;
	static constexpr uint32 kGroup = kEncF / kTime;        // 4

	// ⚠️ 138~142 와 **같은 코퍼스**(같은 씨앗·epi·인코더). `_pbA` 는 이 회차가 안 쓴다.
	static constexpr uint32 kNCtx = 512u, kPtCtx = 512u;
	static constexpr uint32 kTrainEpi = 1u, kPtEpi = 5001u;

	// ⭐ 회차 141 이 남긴 값 — ⚠️ 여기서 새로 재지 않는다(견주는 상대다).
	static constexpr float kCE141 = 2.7666f;   // 몸통의 변화 표적 CE(씨앗 12 평균)
	static constexpr float kH142  = 2.2663f;   // 회차 142 의 H(변화 표적) — ㉡ 의 검산 상대

	static constexpr uint32 kPreds = 5u;       // ㉠a ㉠b ㉡ ㉢ ㉣
	enum { kEncInit, kEncTrain, kGather, kMeasure };

	inline static MLTP2Enc _E;
	inline static MLTP3Ctx _trA, _ptA;
	inline static bool _done = false, _banner = false, _encSetup = false, _ok = true;
	inline static bool _pending = false;
	inline static uint32 _seed = 0u, _st = kEncInit, _step = 0u;
	inline static uint32 _cor = 0u, _gGrp = 0u, _gIdx = 0u;
	inline static Array<float> _code, _norm;

	inline static double _ce[kPreds][kSeedsMax];
	// ⭐ 1씨앗 진단이 요구한 것 — **밀림/새id 로 갈라 본다**(㉣ 가 ㉢ 보다 나쁜 이유가 거기 있다)
	inline static double _ceS[kPreds][kSeedsMax], _ceN[kPreds][kSeedsMax];
	inline static double _nCh[kSeedsMax], _shiftTe[kSeedsMax], _shiftTr[kSeedsMax];
	inline static double _hAll[kSeedsMax], _hShift[kSeedsMax], _hNew[kSeedsMax];
	inline static double _branch[kSeedsMax];   // ⭐ 갈래 엔트로피 `H(α)` — ㉣ 가 무는 비용

	static const char* _PName(uint32 p)
	{
		switch (p)
		{
		case 0u: return "㉠a 학습 전체 주변분포   ";
		case 1u: return "㉠b 학습 변화-only 주변  ";
		case 2u: return "㉡  시험 주변(142 검산)  ";
		case 3u: return "㉢  슬롯 id 배제         ";
		default: return "㉣  밀림 인지 혼합 ⭐    ";
		}
	}

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🧮 **회차 143 · 변화 표적을 배우나**(⭐ 학습 0 · 계산 회차 · %s)\n",
			(_seeds == 1u) ? "⚠️ 1씨앗 진단" : "씨앗 12");
		LogA("[mlt] 🧮   ⭐ 표제 = ***몸통(회차 141 · CE **%.4f**)이 「학습 0 예측기」보다 나은가***\n", (double)kCE141);
		LogA("[mlt] 🧮   ⭐ 먼저 — **「변화」가 두 종류다**: 슬롯이 **id 오름차순**이라(회차 55)\n");
		LogA("[mlt] 🧮      도형 하나가 사라지면 **슬롯이 전부 밀린다** ⇒ 집합이 안 바뀌어도 「변화」가 된다\n");
		LogA("[mlt] 🧮      **(a) 밀림** = 표적 id 가 지금 활성 8개 **안** · **(b) 새 id** = **밖**\n");
		LogA("[mlt] 🧮   예측기 다섯 — ㉠a 학습전체 · ㉠b 학습변화only · ㉡ 시험주변(검산) · ㉢ 슬롯배제 · ⭐ ㉣ 밀림인지\n");
		LogA("[mlt] 🧮   ⚠️ ㉣ 의 α(밀림 비율)는 **학습 코퍼스에서** 잰다 — 시험에서 재면 훔쳐보는 것이다\n");
		LogA("[mlt] 🧮   ⭐ 예측 — ㉡ 2.266(검산) · ㉠a 2.6~3.2 · ㉠b 2.28~2.40 · ㉢ 2.1~2.35 · ㉣ **1.3~1.9**\n");
		LogA("[mlt] 🧮   ⭐ 표제 예측 = ⛔ **몸통이 ㉠b·㉢·㉣ 보다 나쁠 것** · 밀림 비율 **약 54%%**\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

	// ── 인코더 · 코퍼스(138~142 와 같다) ────────────────────────────
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
		_trA.SetSortById(true); _ptA.SetSortById(true);
		_trA.Begin(kNCtx, kN); _ptA.Begin(kPtCtx, kN);
		_cor = 0u; _gGrp = 0u; _gIdx = 0u; _pending = false; _st = kGather;
	}

	static uint32 _NCtxOf(uint32 c) { return (c == 0u) ? kNCtx : kPtCtx; }
	static uint32 _EpiOf(uint32 c)  { return (c == 0u) ? kTrainEpi : kPtEpi; }
	static MLTP3Ctx& _CorA(uint32 c) { return (c == 0u) ? _trA : _ptA; }

	static void _Gather()
	{
		const uint32 nCtx = _NCtxOf(_cor);
		if (_pending)
		{
			Array<float> ids, mag;
			if (!_E.ReadAct(ids, mag) || ids.Count() != kCandidates) { _Fail("활성 리드백"); return; }
			const uint32 cx = _gGrp * kGroup + (_gIdx - 1u) / kTime, tt = (_gIdx - 1u) % kTime;
			_CorA(_cor).StoreAct(cx, tt, ids, mag, _norm);
			_pending = false;
		}
		if (_gIdx == 0u)
		{
			Array<float> fr, tg; fr.Reset(0); tg.Reset(0);
			ImageFormat::Bitmap bmp; Bytes packed;
			const uint32 epi = _EpiOf(_cor);
			for (uint32 g = 0; g < kGroup; ++g)
			{
				const uint32 ctx = _gGrp * kGroup + g;
				MLTWorld w; w.Reset(_seed, epi + ctx, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
				for (uint32 t = 0; t < kTime; ++t)
				{
					w.Step();
					if (!w.Render(bmp) || !MLTWorld::Pack(bmp, nullptr, packed)) { _Fail("Render/Pack(문맥)"); return; }
					MLTP2Enc::AppendFrame(fr, tg, (const uint8*)packed.GetData());
					_CorA(_cor).StoreState(ctx, t, w.State());
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
		if (++_gGrp * kGroup < nCtx) return;
		_gGrp = 0u;
		if (++_cor < 2u) return;
		_st = kMeasure;
	}

	// ── 📊 헤아리기 ────────────────────────────────────────────────
	//   ⚠️ 「변화 표적」 = 그 슬롯의 표적 id 가 **지금 그 슬롯의 id 와 다르다**.
	//   ⚠️ 「밀림」 = 그 표적 id 가 **지금 활성 8개 안**에 있다(집합은 그대로인데 자리가 밀린 것).
	static bool _IsChange(const MLTP3Ctx& C, uint32 b, uint32 j, uint32& outTid)
	{
		const float tf = C.Tgt()[b + j];
		if (!(tf >= 0.0f && tf < (float)kN)) return false;
		outTid = (uint32)tf;
		return (uint32)(C.Sym()[b + j] - (float)kStateAx) != outTid;
	}

	static bool _InActive(const MLTP3Ctx& C, uint32 b, uint32 tid)
	{
		for (uint32 q = 0; q < kSlots; ++q)
			if ((uint32)(C.Sym()[b + q] - (float)kStateAx) == tid) return true;
		return false;
	}

	// 변화 표적의 히스토그램 + 밀림 비율. `hist` 는 kN 길이.
	static void _Hist(const MLTP3Ctx& C, uint32 nCtx, Array<uint32>& hist,
		uint32& outN, uint32& outShift, Array<uint32>* histShift, Array<uint32>* histNew)
	{
		hist.Reset(0);
		for (uint32 i = 0; i < kN; ++i) hist.Add(0u);
		if (histShift) { histShift->Reset(0); for (uint32 i = 0; i < kN; ++i) histShift->Add(0u); }
		if (histNew)   { histNew->Reset(0);   for (uint32 i = 0; i < kN; ++i) histNew->Add(0u); }
		outN = 0u; outShift = 0u;
		for (uint32 ctx = 0; ctx < nCtx; ++ctx)
			for (uint32 t = 0; t < kTime; ++t)
			{
				const uint32 b = MLTP3Ctx::Row(ctx, t, kStateAx);
				for (uint32 j = 0; j < kSlots; ++j)
				{
					uint32 tid = 0u;
					if (!_IsChange(C, b, j, tid)) continue;
					++outN; ++hist.Data()[tid];
					if (_InActive(C, b, tid))
					{
						++outShift;
						if (histShift) ++histShift->Data()[tid];
					}
					else if (histNew) ++histNew->Data()[tid];
				}
			}
	}

	static double _Entropy(const Array<uint32>& h, uint32 n)
	{
		if (n == 0u) return 0.0;
		double e = 0.0;
		for (uint32 i = 0; i < h.Count(); ++i)
		{
			if (h[i] == 0u) continue;
			const double p = (double)h[i] / (double)n;
			e += -p * (double)Log((float)p);
		}
		return e;
	}

	static void _Normalize(const Array<uint32>& h, uint32 n, Array<double>& p)
	{
		p.Reset(0);
		for (uint32 i = 0; i < kN; ++i) p.Add((n == 0u) ? 0.0 : (double)h[i] / (double)n);
	}

	static double _Clamp(double p) { return (p < 1.0e-9) ? 1.0e-9 : p; }

	static void _Measure()
	{
		// ── 학습 코퍼스에서: 전체 주변분포 · 변화-only 주변분포 · 밀림 비율 α ──
		Array<float> margAllF;
		_trA.Marginal(margAllF);                       // 전체 표적 주변분포(kN)
		Array<uint32> hTr; uint32 nTr = 0u, sTr = 0u;
		_Hist(_trA, kNCtx, hTr, nTr, sTr, nullptr, nullptr);
		Array<double> pTrCh; _Normalize(hTr, nTr, pTrCh);
		const double alpha = (nTr == 0u) ? 0.0 : (double)sTr / (double)nTr;
		_shiftTr[_seed] = alpha;

		// ── 시험 코퍼스에서: 변화 표적 히스토그램(오라클) + 분해 ──
		Array<uint32> hPt, hSh, hNw; uint32 nPt = 0u, sPt = 0u;
		_Hist(_ptA, kPtCtx, hPt, nPt, sPt, &hSh, &hNw);
		Array<double> pPtCh; _Normalize(hPt, nPt, pPtCh);
		_nCh[_seed]    = (double)nPt / (double)kPtCtx;
		_shiftTe[_seed] = (nPt == 0u) ? 0.0 : (double)sPt / (double)nPt;
		_hAll[_seed]   = _Entropy(hPt, nPt);
		_hShift[_seed] = _Entropy(hSh, sPt);
		_hNew[_seed]   = _Entropy(hNw, nPt - sPt);

		// ── 예측기 다섯의 CE(변화 표적당 나트) ──
		double sum[kPreds], sumS[kPreds], sumN[kPreds];
		for (uint32 p = 0; p < kPreds; ++p) { sum[p] = 0.0; sumS[p] = 0.0; sumN[p] = 0.0; }
		uint32 cnt = 0u, cntS = 0u, cntN = 0u;
		for (uint32 ctx = 0; ctx < kPtCtx; ++ctx)
			for (uint32 t = 0; t < kTime; ++t)
			{
				const uint32 b = MLTP3Ctx::Row(ctx, t, kStateAx);
				for (uint32 j = 0; j < kSlots; ++j)
				{
					uint32 tid = 0u;
					if (!_IsChange(_ptA, b, j, tid)) continue;
					++cnt;
					const uint32 cur = (uint32)(_ptA.Sym()[b + j] - (float)kStateAx);
					const bool isShift = _InActive(_ptA, b, tid);
					if (isShift) ++cntS; else ++cntN;
					double one[kPreds];

					// ㉠a 학습 전체 주변분포
					one[0] = -Log((float)_Clamp((double)margAllF[tid]));
					// ㉠b 학습 변화-only 주변분포
					one[1] = -Log((float)_Clamp(pTrCh[tid]));
					// ㉡ 시험 주변분포(오라클 · 142 검산)
					one[2] = -Log((float)_Clamp(pPtCh[tid]));

					// ㉢ 그 슬롯의 지금 id 만 배제하고 재정규화(늘 유효하다)
					{
						const double z = 1.0 - pTrCh[cur];
						one[3] = -Log((float)_Clamp((z > 1.0e-9) ? pTrCh[tid] / z : pTrCh[tid]));
					}

					// ⭐ ㉣ 밀림 인지 — α 로 「지금 활성(그 슬롯 제외)」 ↔ 「밖」 혼합
					{
						double zIn = 0.0, zOut = 0.0;
						for (uint32 q = 0; q < kSlots; ++q)
						{
							const uint32 aid = (uint32)(_ptA.Sym()[b + q] - (float)kStateAx);
							if (aid == cur) continue;
							zIn += pTrCh[aid];
						}
						for (uint32 y = 0; y < kN; ++y)
							if (!_InActive(_ptA, b, y)) zOut += pTrCh[y];
						double p = 0.0;
						if (isShift && zIn > 1.0e-12)     p += alpha * (pTrCh[tid] / zIn);
						if (!isShift && zOut > 1.0e-12)   p += (1.0 - alpha) * (pTrCh[tid] / zOut);
						one[4] = -Log((float)_Clamp(p));
					}
					for (uint32 p = 0; p < kPreds; ++p)
					{
						sum[p] += one[p];
						if (isShift) sumS[p] += one[p]; else sumN[p] += one[p];
					}
				}
			}
		for (uint32 p = 0; p < kPreds; ++p)
		{
			_ce[p][_seed]  = (cnt  == 0u) ? 0.0 : sum[p]  / (double)cnt;
			_ceS[p][_seed] = (cntS == 0u) ? 0.0 : sumS[p] / (double)cntS;
			_ceN[p][_seed] = (cntN == 0u) ? 0.0 : sumN[p] / (double)cntN;
		}
		// ⭐ 갈래 엔트로피 — ㉣ 가 「밀림인가 새id인가」를 모르는 채 섞느라 무는 비용
		_branch[_seed] = -alpha * (double)Log((float)_Clamp(alpha))
			- (1.0 - alpha) * (double)Log((float)_Clamp(1.0 - alpha));

		LogA("[mlt] 🧮 씨앗 %2u · 변화 표적 **%.1f/문맥**(%u) · 밀림 **시험 %.1f%% / 학습 %.1f%%(=α)**\n",
			_seed, _nCh[_seed], cnt, 100.0 * _shiftTe[_seed], 100.0 * alpha);
		LogA("[mlt] 🧮   H — 전체 **%.4f** · 밀림 %.4f · 새id %.4f\n", _hAll[_seed], _hShift[_seed], _hNew[_seed]);
		for (uint32 p = 0; p < kPreds; ++p)
			LogA("[mlt] 🧮   %s CE **%.4f**(밀림 %.4f · 새id %.4f)\n",
				_PName(p), _ce[p][_seed], _ceS[p][_seed], _ceN[p][_seed]);
		LogA("[mlt] 🧮   ⭐ 갈래 엔트로피 H(α) = **%.4f** 나트 — ㉣ 가 무는 비용\n", _branch[_seed]);
		++_seed; _st = kEncInit;
	}

	static void _MeanSd(const double* v, double& m, double& sd)
	{
		m = 0.0; for (uint32 s = 0; s < _seeds; ++s) m += v[s];
		m /= (double)_seeds;
		double q = 0.0;
		for (uint32 s = 0; s < _seeds; ++s) { const double e = v[s] - m; q += e * e; }
		sd = (_seeds > 1u) ? Sqrt((float)(q / (double)(_seeds - 1u))) : 0.0;
	}

	static void _Summary()
	{
		double nm, nsd, stm, stsd, sam, sasd, ham, hasd, hsm, hssd, hnm, hnsd;
		_MeanSd(_nCh, nm, nsd); _MeanSd(_shiftTe, stm, stsd); _MeanSd(_shiftTr, sam, sasd);
		_MeanSd(_hAll, ham, hasd); _MeanSd(_hShift, hsm, hssd); _MeanSd(_hNew, hnm, hnsd);

		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🧮 **회차 143 · 변화 표적을 배우나** (씨앗 %u · 학습 0 · 유한 %s)\n", _seeds, _ok ? "✅" : "⛔");
		LogA("[mlt] 🧮   ── ① 변화 표적의 정체 ──\n");
		LogA("[mlt] 🧮     변화 표적 **%.1f/문맥**(±%.1f) — 141·142 는 14.0 이었다\n", nm, nsd);
		LogA("[mlt] 🧮     ⭐ **밀림 비율** — 시험 **%.1f%%**(±%.1f) · 학습 **%.1f%%**(=α) · 예측은 54%%였다\n",
			100.0 * stm, 100.0 * stsd, 100.0 * sam);
		LogA("[mlt] 🧮     H — 전체 **%.4f** · **밀림 %.4f** · **새id %.4f** 나트\n", ham, hsm, hnm);
		LogA("[mlt] 🧮   ── ② ⭐ **예측기 다섯 vs 몸통**(변화 표적당 나트) ──\n");
		double m[kPreds], sd[kPreds], mS[kPreds], mN[kPreds], dmy;
		for (uint32 p = 0; p < kPreds; ++p)
		{
			_MeanSd(_ce[p], m[p], sd[p]);
			_MeanSd(_ceS[p], mS[p], dmy); _MeanSd(_ceN[p], mN[p], dmy);
			LogA("[mlt] 🧮     %s │ **%.4f**(±%.4f) │ 밀림 %.4f · 새id %.4f │ 몸통(%.4f) 대비 %s **%+.4f**\n",
				_PName(p), m[p], sd[p], mS[p], mN[p], (double)kCE141,
				((double)kCE141 > m[p]) ? "⛔ 몸통이 나쁘다" : "✅ 몸통이 낫다",
				(double)kCE141 - m[p]);
		}
		double brm, brsd; _MeanSd(_branch, brm, brsd);
		LogA("[mlt] 🧮     ⭐ **갈래 엔트로피 `H(α)` = %.4f 나트** — ㉣ 가 「밀림인가 새id인가」를\n", brm);
		LogA("[mlt] 🧮        모르는 채 섞느라 무는 비용이다(㉢ 대비 %+.4f 만큼 좁혔는지 견준다)\n", m[3] - m[4] + brm);

		// ── 관문 ────────────────────────────────────────────────────
		//   ⚠️⚠️ **검산은 씨앗 3 이상에서만** — 1씨앗 진단이 이 관문을 ⛔ 로 찍었는데
		//     그것은 **12씨앗 평균(회차 142)과 1씨앗 값을 견준** 것이었다(규율 51 의 또 다른 얼굴).
		//     ★ 코퍼스 동일성의 진짜 증거는 **변화 표적 수**이고 그것은 씨앗 0 에서 12.4 로 같았다.
		const double chk = Abs((float)(m[2] - (double)kH142));
		const bool chkApply = (_seeds >= 3u);
		const bool gChk = !chkApply || (chk <= 0.02);
		LogA("[mlt] 🧮   ── 관문 ──\n");
		LogA("[mlt] 🧮     ⭐ **검산**(㉡ 가 회차 142 의 %.4f ± 0.02) — %.4f · 차 %.4f → %s\n",
			(double)kH142, m[2], chk,
			!chkApply ? "⚠️ 건너뜀(씨앗 3 이상에서만 — 규율 51)" : (gChk ? "✅" : "⛔ **코퍼스가 다르다**"));
		uint32 worse = 0u;
		for (uint32 p = 0; p < kPreds; ++p) if ((double)kCE141 > m[p]) ++worse;
		LogA("[mlt] 🧮     ⭐ **표제** — 몸통이 예측기 **%u/%u** 보다 나쁘다\n", worse, kPreds);

		// ── 판정 ────────────────────────────────────────────────────
		if (!_ok)                LogA("[mlt] 🧮   ⭐ 판정 = ⛔ **판정불가** — 배관이 안 섰다\n");
		else if (!gChk)          LogA("[mlt] 🧮   ⭐ 판정 = ⛔ **판정불가** — ***검산이 깨졌다***(같은 코퍼스가 아니다)\n");
		else if (_seeds == 1u)   LogA("[mlt] 🧮   ⭐ **1씨앗 진단이다 — 판정하지 않는다**(규율 51)\n");
		else if ((double)kCE141 > m[1] && (double)kCE141 > m[3] && (double)kCE141 > m[4])
			LogA("[mlt] 🧮   ⭐ 판정 = ⛔⛔⛔ ***몸통은 변화 표적을 못 배웠다*** — 학습 0 예측기 셋보다 나쁘다\n"
			     "[mlt] 🧮      ⇒ ★ 다음 물음 = ***왜 못 배우나***(용량 · 손실 가중 · **지속 표적이 손실을 먹나**)\n");
		else if ((double)kCE141 > m[4])
			LogA("[mlt] 🧮   ⭐ 판정 = ⚠️ **조금 배웠지만 「정렬 규칙」은 못 배웠다** — ㉣ 보다 나쁘다\n"
			     "[mlt] 🧮      ⇒ ★ 다음은 **밀림(a)과 새id(b)를 갈라** 어느 쪽을 못 하는지 본다\n");
		else
			LogA("[mlt] 🧮   ⭐ 판정 = ✅ **몸통이 학습 0 예측기 전부보다 낫다** ⇒ ⚠️ 회차 142 의 해석을 철회한다\n");
		LogA("[mlt] 🧮   ⚠️ 몸통 CE 는 **회차 141 의 값**이고 여기서 새로 재지 않았다(같은 코퍼스·같은 마스크)\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		_E.Destroy(); _done = true;
	}

	static void _Fail(const char* why)
	{
		LogA("[mlt] 🧮 ⛔ %s (씨앗 %u · 단계 %u · 코퍼스 %u · 걸음 %u)\n", why, _seed, _st, _cor, _step);
		_ok = false; _E.Destroy(); _done = true;
	}

	CW_BODY(MLTL1F0)
};
