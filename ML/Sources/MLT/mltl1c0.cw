// mltl1c0.cw — 📏 회차 140 · **자의 천장을 계산한다** (`-mltl1c0`)
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 140 이다.** ⭐ **하네스보다 먼저 썼다.**
//   **상위 캔버스: `L1 ㉤ 역방향을 판정한다` · 132·138·139·140 = 4회차**
//   ⚠️⚠️ 규율 33 의 3을 넘었다 ⇒ ★ **이 회차가 그 종료 심사를 겸한다.**
//
// ── ⭐ 표제 — ***이 자로 판정하는 것이 원리적으로 가능한가*** ──────────
//   회차 138·139 가 **둘 다 양성 대조 불성립**으로 판정불가였다. 규율 48 이 절반을 설명했지만
//   (*"양성이 id 를 안 흘렸다"*) ⚠️ **나머지 절반을 한 번도 안 쟀다: 자가 낼 수 있는 최대값.**
//
// ── 📏 자 — ⭐ **엄밀한 상한 하나 + 실측 지표 하나** ──────────────────────
//   ㉠ ⭐ **엄밀한 상한** = `H(낱말) / 문맥당 채점 표적 수`
//      근거: 낱말을 넣어 줄어드는 CE 는 정확히 `I(낱말; 표적 | 나머지 문맥)` 이고
//      `I(w;y|r) ≤ H(w|r) ≤ H(w)` 다. 낱말이 **문맥당 스칼라 하나**이므로
//      ⇒ ***채점 표적 전부가 그 한 조각을 나눠 갖는다.***
//   ㉡ **실측 관계량** = `Î(낱말; 표적) − Î(섞은 낱말; 표적)`
//      ⚠️ **상한이 아니다**(조건부 MI 는 무조건부보다 클 수도 있다 — 시너지).
//      0 에 가까우면 *"표적을 거의 안 가른다"* 는 **강한 신호**이지 증명은 아니다.
//      ⚠️ 유한표본 MI 는 위로 치우친다 ⇒ **섞은 팔이 그 편향 바닥**이다.
//   ⭐ 판정자는 **무차원**(규율 31): `천장 ÷ SE`, `SE` = 회차 139 실측 **0.00599**.
//
// ── 🎛️ 낱말 넷 — ⚠️ 팔이 아니라 **재는 대상**이다(몸통을 안 돌린다) ────────
//   ㈁ `minDOn` 3분위(138·139 의 **표제**) · ㈃ `뜻밖임` 9분위(139 의 **양성** ⛔) ·
//   ⭐ ㈄ **다음 시각 슬롯 0 의 id**(규율 48 의 «id 를 흘리는 말» = 컨셉의 **「답을 준 팔」**) ·
//   ㈅ **섞은** `minDOn`(**편향 바닥**)
//
// ── 🔮 예측(재기 전에 적었다 · 최근 서른여덟 중 스물하나 틀림) ────────────
//   채점 표적 = `(kTime−1) × kPersist` = **56/문맥**(`MLTP3Ctx::Targets()` — 상태 축 다섯은 `IgnoreTgt`).
//   ㈁ `ln3/56` = 0.0196 ⇒ `÷SE` **3.3** ⇒ ⭐ 관문(≥3)을 넘으려면 **정보의 91%** 실현 = 거의 불가능
//   ㈃ `ln9/56` = 0.0392 ⇒ **6.5**(139 실측은 천장의 **17%** 였다 ⇒ 그래서 안 섰다)
//   ㈄ `ln250/56` = 0.0986 ⇒ **16.5** — ★ 여기만 여유가 있다
//   ⇒ 전체 예측 = **「3~10 구간」** · 결론은 ***「문맥당 낱말 하나면 천장이 표적 수로 나뉜다」***
// ══════════════════════════════════════════════════════════════════════════════

using namespace PE;

class MLTL1C0
{
public:
	static void Tick(RHI* rhi)
	{
		if (_done || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltl1c0"))
		{
			LogA("[mlt] 📏 회차 140(자의 천장을 계산한다)은 **꺼져 있다**(`-mltl1c0`)\n");
			_done = true; return;
		}
		if (!_banner) { _Banner(); _banner = true; }
		if (_seed >= kSeeds) { _Summary(); return; }
		if (_st == kEncInit)  { _EncBegin(rhi); return; }
		if (_st == kEncTrain) { _EncTrain(); return; }
		if (_st == kGather)   { _Gather(); return; }
		_Measure();
	}

	static bool Done() { return _done; }

private:
	// ⭐ 학습이 없으므로 씨앗은 **잡음 폭을 보려고**만 둔다(MI 표본은 씨앗 하나에 28,672쌍).
	static constexpr uint32 kSeeds = 4u;
	static constexpr uint32 kEncF = 32u, kEncSteps = 1200u, kEncPerTick = 8u;
	static constexpr uint32 kN = 250u, kLocal = 8u;
	static constexpr uint32 kTime  = MLTP3Ctx::kTime;      // 8
	static constexpr uint32 kBatch = MLTP3Ctx::kBatch;     // 8
	static constexpr uint32 kSlots = MLTP3Ctx::kPersist;   // 8
	static constexpr uint32 kStateAx = MLTP3Ctx::kStateAx; // 5
	static constexpr uint32 kCandidates = MLTP2Cfg::kPatches * kLocal;
	static constexpr uint32 kGroup = kEncF / kTime;        // 4
	static constexpr uint32 kGateT = kTime - 2u;           // 6

	// ⚠️ **회차 138·139 와 같은 코퍼스**여야 숫자를 견줄 수 있다 ⇒ 상수를 그대로 가져온다.
	static constexpr uint32 kNCtx = 512u, kPbCtx = 512u, kPtCtx = 512u;
	static constexpr uint32 kTrainEpi = 1u, kPbEpi = 2001u, kPtEpi = 5001u;
	static_assert(kPbEpi >= kTrainEpi + kNCtx, "규율 12");
	static_assert(kPtEpi >= kPbEpi + kPbCtx, "규율 12");

	static constexpr float kNoShape = 1.0e6f;

	// ⭐ **회차 139 가 남긴 두 상수** — 이 회차의 자는 그 위에 선다(⚠️ 여기서 새로 재지 않는다).
	static constexpr float kSE139 = 0.00599f;   // 짝지은 차의 SE(`|d̄| 0.00671 ÷ 1.12`)
	static constexpr float kCE139 = 0.889f;     // 표적당 예측 CE(회차 138 실측 0.88469~0.88911)

	// 낱말 넷 — ⚠️ **팔이 아니다**(학습이 없다). `nCls` 는 계급 수.
	static constexpr uint32 kWords = 4u;
	static constexpr uint32 kClsOf[kWords] = { 3u, 9u, kN, 3u };
	static constexpr uint32 kMaxCls = kN;

	enum { kEncInit, kEncTrain, kGather, kMeasure };

	inline static MLTP2Enc _E;
	inline static MLTP3Ctx _trA, _pbA, _ptA;
	inline static bool _done = false, _banner = false, _encSetup = false, _ok = true;
	inline static bool _pending = false;
	inline static uint32 _seed = 0u, _st = kEncInit, _step = 0u;
	inline static uint32 _cor = 0u, _gGrp = 0u, _gIdx = 0u, _noShape = 0u;
	inline static Array<float> _code, _norm;
	inline static Array<float> _mTr[2], _mPt[2];   // [0] 뜻밖임 · [1] minDOn
	inline static Array<uint32> _w[kWords];

	// 씨앗별 측정값
	inline static double _hW[kWords][kSeeds], _mi[kWords][kSeeds], _miS[kWords][kSeeds];
	inline static double _nPer[kSeeds], _keepSlot[kSeeds], _keepSet[kSeeds], _hY[kSeeds];

	static const char* _WordName(uint32 w)
	{
		switch (w)
		{
		case 0u: return "㈁ minDOn 3분위 (표제)  ";
		case 1u: return "㈃ 뜻밖임 9분위 (양성)  ";
		case 2u: return "㈄ 다음 슬롯0 id (답)⭐ ";
		default: return "㈅ 섞은 minDOn (바닥)  ";
		}
	}

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 📏 **회차 140 · 자의 천장을 계산한다**(⭐ 학습 0 — 몸통을 안 돌린다)\n");
		LogA("[mlt] 📏   ⚠️ 138·139 가 둘 다 **양성 대조 불성립**이었다. 규율 48 이 절반을 설명했고,\n");
		LogA("[mlt] 📏      ⭐ **나머지 절반 = 「자가 낼 수 있는 최대값」을 한 번도 안 쟀다**\n");
		LogA("[mlt] 📏   ㉠ **엄밀한 상한** = H(낱말) / 문맥당 채점 표적 수  ← `I(w;y|r) ≤ H(w)` 이므로\n");
		LogA("[mlt] 📏   ㉡ 실측 관계량 = Î(낱말;표적) − Î(섞은낱말;표적)  ⚠️ **상한이 아니다**(시너지 가능)\n");
		LogA("[mlt] 📏   ⭐ 판정자 = **천장 ÷ SE**(무차원 · 규율 31) · SE = 회차 139 실측 **%.5f**\n", (double)kSE139);
		LogA("[mlt] 📏   ⭐ 예측: 표적 56/문맥 ⇒ ㈁ 3.3 · ㈃ 6.5 · ㈄ 16.5 ⇒ **「3~10 구간」**\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

	// ── 인코더(회차 85~98 과 같다 · 138·139 와 **같은 코퍼스**를 만들려고 그대로 둔다) ──
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
		_trA.SetSortById(true); _pbA.SetSortById(true); _ptA.SetSortById(true);
		_trA.Begin(kNCtx, kN); _pbA.Begin(kPbCtx, kN); _ptA.Begin(kPtCtx, kN);
		for (uint32 t = 0; t < 2u; ++t) { _mTr[t].Reset(0); _mPt[t].Reset(0); }
		_cor = 0u; _gGrp = 0u; _gIdx = 0u; _pending = false; _noShape = 0u; _st = kGather;
	}

	static uint32 _NCtxOf(uint32 c) { return (c == 0u) ? kNCtx : ((c == 1u) ? kPbCtx : kPtCtx); }
	static uint32 _EpiOf(uint32 c)  { return (c == 0u) ? kTrainEpi : ((c == 1u) ? kPbEpi : kPtEpi); }
	static MLTP3Ctx& _CorA(uint32 c) { return (c == 0u) ? _trA : ((c == 1u) ? _pbA : _ptA); }

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

					if (t == kGateT && _cor != 1u)
					{
						// `minDOn` — ⚠️ `VisibleShapes` 는 **판정 창구**다(모델 입력에 안 들어간다).
						MLTShapeView vs[MLTWorldCfg::kShapes];
						const int nv = w.VisibleShapes(vs, MLTWorldCfg::kShapes);
						const float SS = (float)MLTWorldCfg::kSide;
						float dOn = kNoShape; bool haveOn = false;
						for (int i = 0; i < nv; ++i)
						{
							if (!(vs[i].sx >= 0.0f && vs[i].sx < SS && vs[i].sy >= 0.0f && vs[i].sy < SS)) continue;
							if (!haveOn || vs[i].d < dOn) { dOn = vs[i].d; haveOn = true; }
						}
						if (!haveOn) ++_noShape;
						if (_cor == 0u) _mTr[1].Add(dOn); else _mPt[1].Add(dOn);
					}
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
		if (++_cor < 3u) return;
		_MakeWords();
		_st = kMeasure;
	}

	// ── 낱말 만들기 — ⚠️ 138·139 와 **같은 식**이어야 한다 ───────────────
	//   `뜻밖임` = 다음 시각 표적 8개의 `−log p_marginal` 평균. ⚠️ 주변분포는 **학습 코퍼스에서만**.
	static void _Surprise(const MLTP3Ctx& C, uint32 nCtx, const Array<float>& marg, Array<float>& out)
	{
		out.Reset(0);
		for (uint32 ctx = 0; ctx < nCtx; ++ctx)
		{
			const uint32 gb = MLTP3Ctx::Row(ctx, kGateT, kStateAx);
			double s = 0.0;
			for (uint32 j = 0; j < kSlots; ++j)
			{
				const float tf = C.Tgt()[gb + j];
				const uint32 tid = (tf >= 0.0f && tf < (float)kN) ? (uint32)tf : 0u;
				float p = marg[tid];
				if (p < 1.0e-9f) p = 1.0e-9f;
				s += -(double)Log(p);
			}
			out.Add((float)(s / (double)kSlots));
		}
	}

	static void _RankClassK(const float* m, uint32 n, uint32 k, Array<uint32>& y)
	{
		y.Reset(0);
		for (uint32 i = 0; i < n; ++i) y.Add(0u);
		for (uint32 i = 0; i < n; ++i)
		{
			uint32 r = 0u;
			for (uint32 j = 0; j < n; ++j)
				if (m[j] < m[i] || (m[j] == m[i] && j < i)) ++r;
			y.Data()[i] = (r * k) / n;
		}
	}

	static void _Shuffle(const Array<uint32>& in, Array<uint32>& out, uint32 salt)
	{
		out.Reset(0);
		for (uint32 i = 0; i < in.Count(); ++i) out.Add(in[i]);
		uint32 rs = _seed * 2654435761u + salt;
		for (uint32 i = out.Count(); i > 1u; --i)
		{
			rs = rs * 1664525u + 1013904223u;
			const uint32 j = rs % i;
			const uint32 tmp = out[i - 1u]; out.Data()[i - 1u] = out[j]; out.Data()[j] = tmp;
		}
	}

	static void _MakeWords()
	{
		Array<float> marg;
		_trA.Marginal(marg);
		_Surprise(_trA, kNCtx,  marg, _mTr[0]);
		_Surprise(_ptA, kPtCtx, marg, _mPt[0]);
		_RankClassK(_mPt[1].Data(), kPtCtx, 3u, _w[0]);      // ㈁ minDOn 3분위
		_RankClassK(_mPt[0].Data(), kPtCtx, 9u, _w[1]);      // ㈃ 뜻밖임 9분위
		// ⭐ ㈄ — **다음 시각 슬롯 0 의 id 그 자체**(규율 48 의 «id 를 흘리는 말»)
		_w[2].Reset(0);
		for (uint32 ctx = 0; ctx < kPtCtx; ++ctx)
		{
			const float tf = _ptA.Tgt()[MLTP3Ctx::Row(ctx, kGateT, kStateAx)];
			_w[2].Add((tf >= 0.0f && tf < (float)kN) ? (uint32)tf : 0u);
		}
		_Shuffle(_w[0], _w[3], 11u);                          // ㈅ 편향 바닥
	}

	// ── 📏 측정 ────────────────────────────────────────────────────────
	//   ⚠️ 표적은 **시험 코퍼스**의 것이고, `Tgt >= kN` 은 `IgnoreTgt`(상태 축 · 마지막 시각).
	static void _Measure()
	{
		const Array<float>& T = _ptA.Tgt();
		const Array<float>& S = _ptA.Sym();

		// ① 채점 표적 수 · 지속 비율 둘(슬롯 기준 · 집합 기준)
		uint32 nTgt = 0u, keepSlot = 0u, keepSet = 0u;
		Array<uint32> yHist; yHist.Reset(0);
		for (uint32 i = 0; i < kN; ++i) yHist.Add(0u);
		for (uint32 ctx = 0; ctx < kPtCtx; ++ctx)
			for (uint32 t = 0; t < kTime; ++t)
			{
				const uint32 b = MLTP3Ctx::Row(ctx, t, kStateAx);
				for (uint32 j = 0; j < kSlots; ++j)
				{
					const float tf = T[b + j];
					if (!(tf >= 0.0f && tf < (float)kN)) continue;   // IgnoreTgt
					const uint32 tid = (uint32)tf;
					++nTgt; ++yHist.Data()[tid];
					if ((uint32)(S[b + j] - (float)kStateAx) == tid) ++keepSlot;
					for (uint32 q = 0; q < kSlots; ++q)
						if ((uint32)(S[b + q] - (float)kStateAx) == tid) { ++keepSet; break; }
				}
			}
		_nPer[_seed]     = (double)nTgt / (double)kPtCtx;
		_keepSlot[_seed] = (nTgt == 0u) ? 0.0 : (double)keepSlot / (double)nTgt;
		_keepSet[_seed]  = (nTgt == 0u) ? 0.0 : (double)keepSet / (double)nTgt;
		_hY[_seed]       = _Entropy(yHist, nTgt);

		// ② 낱말별 — H(낱말) · Î(낱말;표적)
		for (uint32 w = 0; w < kWords; ++w)
		{
			const uint32 nc = kClsOf[w];
			Array<uint32> wHist; wHist.Reset(0);
			for (uint32 i = 0; i < nc; ++i) wHist.Add(0u);
			for (uint32 ctx = 0; ctx < kPtCtx; ++ctx) ++wHist.Data()[_w[w][ctx] % nc];
			_hW[w][_seed] = _Entropy(wHist, kPtCtx);
			_mi[w][_seed] = _MI(_w[w], nc, nTgt);
			Array<uint32> sh; _Shuffle(_w[w], sh, 700u + w);
			_miS[w][_seed] = _MI(sh, nc, nTgt);
		}

		LogA("[mlt] 📏 씨앗 %u · 채점 표적 **%.1f/문맥**(총 %u) · 지속 슬롯 %.1f%% · 집합 %.1f%% · H(표적) %.3f\n",
			_seed, _nPer[_seed], nTgt, 100.0 * _keepSlot[_seed], 100.0 * _keepSet[_seed], _hY[_seed]);
		for (uint32 w = 0; w < kWords; ++w)
			LogA("[mlt] 📏   %s H %.4f · Î %.5f · Î섞음 %.5f · 차 %+.5f\n",
				_WordName(w), _hW[w][_seed], _mi[w][_seed], _miS[w][_seed], _mi[w][_seed] - _miS[w][_seed]);

		++_seed; _st = kEncInit;
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

	// `Î(w;y) = Ĥ(y) − Ĥ(y|w)` — 표적을 **모든 채점 자리**에 걸쳐 모은다(그것이 CE 가 재는 것이다).
	static double _MI(const Array<uint32>& word, uint32 nc, uint32 nTgt)
	{
		if (nTgt == 0u) return 0.0;
		const Array<float>& T = _ptA.Tgt();
		Array<uint32> joint; joint.Reset(0);
		for (uint32 i = 0; i < nc * kN; ++i) joint.Add(0u);
		Array<uint32> wCnt; wCnt.Reset(0);
		for (uint32 i = 0; i < nc; ++i) wCnt.Add(0u);
		Array<uint32> yCnt; yCnt.Reset(0);
		for (uint32 i = 0; i < kN; ++i) yCnt.Add(0u);

		for (uint32 ctx = 0; ctx < kPtCtx; ++ctx)
		{
			const uint32 c = word[ctx] % nc;
			for (uint32 t = 0; t < kTime; ++t)
			{
				const uint32 b = MLTP3Ctx::Row(ctx, t, kStateAx);
				for (uint32 j = 0; j < kSlots; ++j)
				{
					const float tf = T[b + j];
					if (!(tf >= 0.0f && tf < (float)kN)) continue;
					const uint32 tid = (uint32)tf;
					++joint.Data()[c * kN + tid]; ++wCnt.Data()[c]; ++yCnt.Data()[tid];
				}
			}
		}
		const double hY = _Entropy(yCnt, nTgt);
		double hYgW = 0.0;
		for (uint32 c = 0; c < nc; ++c)
		{
			const uint32 nw = wCnt[c];
			if (nw == 0u) continue;
			double e = 0.0;
			for (uint32 y = 0; y < kN; ++y)
			{
				const uint32 v = joint[c * kN + y];
				if (v == 0u) continue;
				const double p = (double)v / (double)nw;
				e += -p * (double)Log((float)p);
			}
			hYgW += ((double)nw / (double)nTgt) * e;
		}
		return hY - hYgW;
	}

	static void _Mean(const double* v, double& m, double& sd)
	{
		m = 0.0; for (uint32 s = 0; s < kSeeds; ++s) m += v[s];
		m /= (double)kSeeds;
		double q = 0.0;
		for (uint32 s = 0; s < kSeeds; ++s) { const double e = v[s] - m; q += e * e; }
		sd = (kSeeds > 1u) ? Sqrt((float)(q / (double)(kSeeds - 1u))) : 0.0;
	}

	static void _Summary()
	{
		double nm, ns, ksm, kss, kem, kes, hym, hys;
		_Mean(_nPer, nm, ns); _Mean(_keepSlot, ksm, kss); _Mean(_keepSet, kem, kes); _Mean(_hY, hym, hys);

		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 📏 **회차 140 · 자의 천장** (씨앗 %u · 학습 0 · 유한 %s)\n", kSeeds, _ok ? "✅" : "⛔");
		LogA("[mlt] 📏   ── ① 채점 자리 ──\n");
		LogA("[mlt] 📏     문맥당 채점 표적 **%.2f** (±%.2f) — 등록문의 손계산 **56** 과 대조\n", nm, ns);
		LogA("[mlt] 📏     지속(같은 슬롯) **%.1f%%** · 지속(집합 안) **%.1f%%** · H(표적) **%.4f** 나트\n",
			100.0 * ksm, 100.0 * kem, hym);
		LogA("[mlt] 📏     ⚠️ 회차 138 의 예측 CE 는 **%.3f** 였다 ⇒ 남은 불확실성이 H(표적)의 **%.0f%%** 뿐이다\n",
			(double)kCE139, (hym > 1.0e-9) ? 100.0 * (double)kCE139 / hym : 0.0);

		LogA("[mlt] 📏   ── ② ⭐ **천장 표**(나트/표적) ──\n");
		LogA("[mlt] 📏     낱말                    │ H(낱말) · ㉠천장=H/N · **㉠÷SE** · Î−Î섞음 · 139실현\n");
		for (uint32 w = 0; w < kWords; ++w)
		{
			double hm, hsd, mm, msd, sm, ssd;
			_Mean(_hW[w], hm, hsd); _Mean(_mi[w], mm, msd); _Mean(_miS[w], sm, ssd);
			const double cap = (nm > 1.0e-9) ? hm / nm : 0.0;
			LogA("[mlt] 📏     %s │ %.4f · %.5f · **%6.2f** · %+.5f\n",
				_WordName(w), hm, cap, cap / (double)kSE139, mm - sm);
		}

		// ── ③ ⭐ 이 회차의 급소 ─────────────────────────────────
		const double one = (nm > 1.0e-9) ? (double)kCE139 / nm : 0.0;
		LogA("[mlt] 📏   ── ③ ⭐ **「한 표적을 통째로 흘려도」** ──\n");
		LogA("[mlt] 📏     문맥당 표적이 %.1f 개이고 표적당 CE 가 %.3f 이므로,\n", nm, (double)kCE139);
		LogA("[mlt] 📏     ***그중 하나를 완전히 맞혀 줘도*** d̄ 는 최대 **%.5f** 나트 = **%.2f × SE** 다\n",
			one, one / (double)kSE139);
		LogA("[mlt] 📏     %s\n", (one / (double)kSE139 >= 3.0)
			? "⇒ 관문(≥3)을 넘는다 — 「id 를 흘리는 말」로 양성을 세울 수 있다"
			: "⇒ ⛔⛔ **관문(≥3)을 못 넘는다** — ***양성 대조가 산수로 이미 죽어 있었다***");

		// ── ④ 관문 — 등록문의 세 갈래 ───────────────────────────────
		double h0, d0; _Mean(_hW[0], h0, d0);
		const double capTop = (nm > 1.0e-9) ? h0 / nm : 0.0;
		const double r = capTop / (double)kSE139;
		LogA("[mlt] 📏   ── ④ 관문(등록문) — **표제 낱말 ㈁ 의 `천장 ÷ SE` = %.2f** ──\n", r);
		if (r >= 10.0)
			LogA("[mlt] 📏     ✅ **≥10 — 자는 충분하다** ⇒ 회차 141 = ㈄ 로 양성을 세우고 ㉤ 를 판정\n");
		else if (r >= 3.0)
			LogA("[mlt] 📏     ⚠️ **3~10 — 아슬아슬** ⇒ 관문(≥3)을 넘으려면 낱말이 제 정보의 **%.0f%%** 를\n"
			     "[mlt] 📏        실현해야 한다 ⇒ ⭐ **천장을 올린다**(낱말을 **시각당 하나**로 · 계급 수 ↑)\n",
			     100.0 * 3.0 / r);
		else
			LogA("[mlt] 📏     ⛔ **<3 — 이 자로는 원리적으로 못 잰다** ⇒ 자를 바꾼다(채점을 **변화 표적에만**)\n");

		LogA("[mlt] 📏   ⚠️ 이 회차는 **몸통을 안 돌렸다** — 성능이 아니라 **자의 성질**만 말한다\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		_E.Destroy(); _done = true;
	}

	static void _Fail(const char* why)
	{
		LogA("[mlt] 📏 ⛔ %s (씨앗 %u · 단계 %u · 코퍼스 %u · 걸음 %u)\n", why, _seed, _st, _cor, _step);
		_ok = false; _E.Destroy(); _done = true;
	}

	CW_BODY(MLTL1C0)
};
