// mltl0k0.cw — 🎚️ 회차 99 · **대역별 풀링으로 앵커 A/B 를 정직하게** (`-mltl0k0`) ⭐ **판정 회차**
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 99 이다.** ⭐ **하네스보다 먼저 썼다.**
//
// ── ⚠️ 회차 98 이 남긴 문제 — **자가 묽어졌다**(규율 23) ────────────────────
//   앵커를 실었더니 ㈀ 이 **1.0775 → 1.0820** 으로 **오히려 약간 나빠졌다.**
//   ⚠️⚠️ 그런데 **양성 대조도 같이 나빠졌다**(`yaw×풀링` ㈀ **0.7911 → 1.0276**).
//   ⇒ ⭐ ***문맥이 104 → 232 로 커지자 전체평균 풀링이 신호를 희석했다*** — 상태 5축의 지분이
//     **4.8% → 2.2%** 다. ⇒ **앵커의 이득과 풀링의 희석이 섞여 있어** 그 비교는 못 쓴다.
//
// ── ⭐ 고침 = **대역별 풀링**(⚠️ 여전히 **선형**) ─────────────────────────
//   상태 5축 · 활성 8축 · 앵커 16축을 **따로 평균해 이어붙인다** ⇒ `3 × 128 + 1 = 385`.
//   ★ 그러면 **문맥이 길어져도 각 대역의 지분이 안 줄어든다.**
//
// ── ⭐ **영(zero) 대역** — A/B 를 공정하게 만드는 자리 ──────────────────
//   ⚠️ 대역별로 이으면 판 A 는 2대역(257) · 판 B 는 3대역(385)로 **차원이 다르다** —
//     회차 89 가 세운 규약(*차원이 다르면 릿지 비교가 불공정하다*)에 걸린다.
//   ⇒ ⭐ **판 A 도 3대역으로 만들고 앵커 대역을 「전부 0」으로 둔다** ⇒ ***둘 다 385차원.***
//   ★ 두 판의 **유일한 차이가 「그 대역이 0이냐 진짜냐」** 뿐이라 A/B 가 **최대로 짝지어진다.**
//
// ── ⭐ **인코더 활성을 한 번만 뽑아 두 코퍼스에 같이 넣는다** ───────────
//   ⚠️ 판 A 와 판 B 가 **다른 활성**을 보면 그것이 교란이다.
//   ⇒ 한 `_Gather` 루프에서 `StoreState`/`StoreAct` 를 **두 코퍼스에 나란히** 부른다.
//
// ── 판·팔 넷 ──────────────────────────────────────────────────────────────
//   | **판 A** 축 13(`MLTP3Ctx`)  · 앵커 대역 **전부 0** | ㈀ 학습 · ㈁ 무작위 |
//   | **판 B** 축 29(`MLTP3ACtx`) · 앵커 대역 **진짜**   | ㈀ 학습 · ㈁ 무작위 |
//
// ── 관문 ──────────────────────────────────────────────────────────────────
//   **배관** ㈃ 균형 · ㈄ 얼림/재현 · ⚠️ **양성(yaw)이 판 A·B 「둘 다」 `≥10/12`**(규율 16 + 23)
//   **표제 ⭐** `CE(판B · ㈀ · minDOn) < CE(판A · ㈀ · minDOn)` — `≥10/12` ← ***앵커가 돕나***
//   부산물: 각 판의 `<ln3` · 각 판의 `㈀ < ㈁`(규율 18)
//
// ── ⭐ 예측을 미리 적었다 ─────────────────────────────────────────────────
//   · 양성 대조가 **두 판에서 비슷해진다**(대역별이라 희석이 없다) ← 규율 23 의 고침이 먹었나
//   · **앵커 A/B 는 ⚠️ 진짜 모른다** — 그것이 이 회차의 값이다
// ══════════════════════════════════════════════════════════════════════════════

using namespace PE;

class MLTL0K0
{
public:
	static void Tick(RHI* rhi)
	{
		if (_done || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltl0k0"))
		{
			LogA("[mlt] 🎚️ 회차 99(대역별 풀링 · 앵커 A/B)는 **꺼져 있다**(`-mltl0k0`)\n");
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
		if (_st == kBodyInit)  { _BodyBegin(rhi); return; }
		if (_st == kBodyTrain) { _BodyTrain(); return; }
		_RepStep();
	}

	static bool Done() { return _done; }

private:
	static constexpr uint32 kSeeds = 12u;
	static constexpr uint32 kEncF = 32u, kEncSteps = 1200u, kEncPerTick = 8u;
	static constexpr uint32 kN = 250u, kLocal = 8u;
	static constexpr uint32 kTime  = MLTP3Ctx::kTime;      // 8
	static constexpr uint32 kBatch = MLTP3Ctx::kBatch;     // 8
	static constexpr uint32 kSlots = MLTP3Ctx::kPersist;   // 8
	static constexpr uint32 kStateAx = MLTP3Ctx::kStateAx; // 5
	static constexpr uint32 kCandidates = MLTP2Cfg::kPatches * kLocal;
	static constexpr uint32 kGroup = kEncF / kTime;        // 4
	static constexpr uint32 kGateT = kTime - 2u;           // 6

	static constexpr uint32 kNCtx = 512u, kPbCtx = 512u, kPtCtx = 512u;
	static constexpr uint32 kTrainEpi = 1u, kPbEpi = 2001u, kPtEpi = 5001u;
	static_assert(kPbEpi >= kTrainEpi + kNCtx, "규율 12");
	static_assert(kPtEpi >= kPbEpi + kPbCtx, "규율 12");
	static constexpr uint32 kPoolSteps = kNCtx / kBatch;
	static constexpr uint32 kPbPool = kPbCtx / kBatch, kPtPool = kPtCtx / kBatch;
	static constexpr uint32 kSteps = 800u, kPerTick = 4u;

	// ⭐ **대역 셋** — 상태 · 활성 · 앵커. 판 A 는 앵커 대역이 **전부 0** 이다.
	static constexpr uint32 kD = MLTModel::RepDim();       // 128
	static constexpr uint32 kBands = 3u;
	static constexpr uint32 kFeat = kBands * kD + 1u;      // 385
	static constexpr uint32 kCls = 3u;
	static constexpr uint32 kFitCtx = 384u;
	static constexpr uint32 kCalCtx = kPbCtx - kFitCtx;    // 128
	static constexpr uint32 kSignPass = 10u;
	static constexpr float  kUnif = 1.0986123f;
	static constexpr uint32 kBalSlack = 1u;
	static constexpr uint32 kLams = 4u;
	static constexpr float  kLamGrid[kLams] = { 0.1f, 1.0f, 10.0f, 100.0f };
	static constexpr float  kNoShape = 1.0e6f;

	// 판 둘 × 팔 둘 = 넷 · 표적 둘(0 = minDOn 표제 · 1 = yaw 양성)
	static constexpr uint32 kPlates = 2u, kArms = 2u, kTgts = 2u;
	static constexpr uint32 kSymA = MLTP3Ctx::kStateAx + kN + 1u;    // 256
	static constexpr uint32 kSymB = MLTP3ACtx::kSymVocab;            // 272

	enum { kEncInit, kEncTrain, kGather, kQuiesce, kBodyInit, kBodyTrain, kRep };

	inline static MLTP2Enc _E;
	inline static MLTModel _M;
	inline static MLTP3Ctx  _trA, _pbA, _ptA;    // 판 A — 축 13
	inline static MLTP3ACtx _trB, _pbB, _ptB;    // 판 B — 축 29
	inline static bool _done = false, _banner = false, _encSetup = false, _finite = true;
	inline static bool _pending = false;
	inline static uint32 _seed = 0u, _st = kEncInit, _step = 0u;
	inline static uint32 _plate = 0u, _arm = 0u;
	inline static uint32 _cor = 0u, _gGrp = 0u, _gIdx = 0u, _qWait = 0u, _noShape = 0u;
	inline static Array<float> _code, _norm;

	inline static Array<float> _fPb, _fPt, _fPt2;
	inline static Array<float> _mPb[kTgts], _mPt[kTgts];
	inline static Array<uint32> _yPb[kTgts], _yPt[kTgts];
	inline static const uint32* _yTr = nullptr;
	inline static const uint32* _yTe = nullptr;

	inline static float _ce[kPlates][kArms][kTgts][kSeeds];
	inline static float _acc[kPlates][kArms][kTgts][kSeeds];
	inline static bool  _seedOk[kSeeds], _balOk[kSeeds], _repOk[kSeeds];

	inline static uint32 _rw = 0u, _ri = 0u, _rwait = 0u;
	inline static bool   _rpend = false;

	static void _ToBody() { _qWait = MLTEvalGate::kDelay; _st = kQuiesce; }
	static uint32 _AxOf(uint32 p) { return (p == 0u) ? MLTP3Ctx::kAxes : MLTP3ACtx::kAxes; }
	static uint32 _CtxOf(uint32 p) { return (p == 0u) ? MLTP3Ctx::kCtx : MLTP3ACtx::kCtx; }
	static uint32 _SymOf(uint32 p) { return (p == 0u) ? kSymA : kSymB; }
	static const char* _PlateName(uint32 p) { return (p == 0u) ? "판A 축13(앵커0)" : "판B 축29(앵커진짜)"; }
	static const char* _ArmName(uint32 a) { return (a == 0u) ? "㈀ 학습" : "㈁ 무작위"; }
	static const char* _TgtName(uint32 t) { return (t == 0u) ? "㊀ minDOn(표제)" : "㊁ yaw(양성)"; }

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🎚️ **회차 99 · 대역별 풀링으로 앵커 A/B 를 정직하게**(⭐ 판정 회차 · 규율 23 의 고침)\n");
		LogA("[mlt] 🎚️   ⚠️ 회차 98 은 **자가 묽어졌다** — 앵커를 실으니 양성 대조도 같이 나빠졌다(0.7911 → 1.0276)\n");
		LogA("[mlt] 🎚️   ⭐ **대역별 풀링** — 상태 %u축 · 활성 %u축 · 앵커 %u축을 **따로 평균해 이어붙인다** = %u차원(⚠️ 여전히 선형)\n",
			kStateAx, kSlots, MLTP3ACtx::kAncAx, kFeat);
		LogA("[mlt] 🎚️   ⭐ **영 대역** — 판A 도 3대역으로 만들고 앵커 대역을 **전부 0** 으로 ⇒ **둘 다 %u차원**(공정)\n", kFeat);
		LogA("[mlt] 🎚️   ⭐ **인코더 활성을 한 번만 뽑아 두 코퍼스에 같이 넣는다** ⇒ 완전히 짝지어진다\n");
		LogA("[mlt] 🎚️   판·팔 넷 — **판A 축 %u**(앵커 0) ↔ **판B 축 %u**(앵커 진짜) × ㈀ 학습 ↔ ㈁ 무작위\n",
			MLTP3Ctx::kAxes, MLTP3ACtx::kAxes);
		LogA("[mlt] 🎚️   ⭐ **표제** — `CE(판B·㈀·minDOn) < CE(판A·㈀·minDOn)` ≥%u/12(짝지은 A/B)\n", kSignPass);
		LogA("[mlt] 🎚️   ⚠️ **양성(yaw)이 판 A·B 「둘 다」 서야 한다**(규율 16 + 23) — 아니면 판정불가\n");
		LogA("[mlt] 🎚️   ⭐ **예측** — 양성이 **두 판에서 비슷해진다** · **앵커 A/B 는 진짜 모른다**(그것이 이 회차의 값)\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

	// ── 인코더(회차 85~98 과 같다) ───────────────────────────────────
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
		_trB.SetSortById(true); _pbB.SetSortById(true); _ptB.SetSortById(true);
		_trA.Begin(kNCtx, kN); _pbA.Begin(kPbCtx, kN); _ptA.Begin(kPtCtx, kN);
		_trB.Begin(kNCtx, kN); _pbB.Begin(kPbCtx, kN); _ptB.Begin(kPtCtx, kN);
		for (uint32 t = 0; t < kTgts; ++t) { _mPb[t].Reset(0); _mPt[t].Reset(0); }
		_cor = 0u; _gGrp = 0u; _gIdx = 0u; _pending = false; _st = kGather;
	}

	static uint32 _NCtxOf(uint32 c) { return (c == 0u) ? kNCtx : ((c == 1u) ? kPbCtx : kPtCtx); }
	static uint32 _EpiOf(uint32 c)  { return (c == 0u) ? kTrainEpi : ((c == 1u) ? kPbEpi : kPtEpi); }
	static MLTP3Ctx&  _CorA(uint32 c) { return (c == 0u) ? _trA : ((c == 1u) ? _pbA : _ptA); }
	static MLTP3ACtx& _CorB(uint32 c) { return (c == 0u) ? _trB : ((c == 1u) ? _pbB : _ptB); }

	// ⭐ **한 루프에서 두 코퍼스에 나란히** 넣는다 — 활성이 같아야 A/B 가 짝지어진다.
	static void _Gather()
	{
		const uint32 nCtx = _NCtxOf(_cor);
		if (_pending)
		{
			Array<float> ids, mag;
			if (!_E.ReadAct(ids, mag) || ids.Count() != kCandidates) { _Fail("활성 리드백"); return; }
			const uint32 cx = _gGrp * kGroup + (_gIdx - 1u) / kTime, tt = (_gIdx - 1u) % kTime;
			_CorA(_cor).StoreAct(cx, tt, ids, mag, _norm);
			_CorB(_cor).StoreAct(cx, tt, ids, mag, _norm);
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
					_CorB(_cor).StoreState(ctx, t, w.State());
					if (t == kGateT)
					{
						// ㊀ `minDOn` — ⚠️ `VisibleShapes` 는 **판정 창구**다(모델 입력에 안 들어간다).
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
						if (_cor == 1u) { _mPb[0].Add(dOn); _mPb[1].Add(w.State().yaw); }
						else if (_cor == 2u) { _mPt[0].Add(dOn); _mPt[1].Add(w.State().yaw); }
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
		_plate = 0u; _arm = 0u; _ToBody();
	}

	// ── 순위 계급(회차 87 · `sd = 0`) ────────────────────────────────
	static void _RankClass(const float* m, uint32 n, Array<uint32>& y)
	{
		y.Reset(0);
		for (uint32 i = 0; i < n; ++i) y.Add(0u);
		for (uint32 i = 0; i < n; ++i)
		{
			uint32 r = 0u;
			for (uint32 j = 0; j < n; ++j)
				if (m[j] < m[i] || (m[j] == m[i] && j < i)) ++r;
			y.Data()[i] = (r * kCls) / n;
		}
	}

	static void _MakeWords()
	{
		bool ok = true;
		const uint32 tgt = (kPtCtx + kCls / 2u) / kCls;
		for (uint32 t = 0; t < kTgts; ++t)
		{
			_RankClass(_mPb[t].Data(), kPbCtx, _yPb[t]);
			_RankClass(_mPt[t].Data(), kPtCtx, _yPt[t]);
			uint32 cnt[kCls] = { 0u, 0u, 0u };
			for (uint32 i = 0; i < kPtCtx; ++i) ++cnt[_yPt[t][i]];
			for (uint32 c = 0; c < kCls; ++c)
			{
				const uint32 d = (cnt[c] > tgt) ? (cnt[c] - tgt) : (tgt - cnt[c]);
				if (d > kBalSlack) ok = false;
			}
		}
		_balOk[_seed] = ok;
		LogA("[mlt] 🎚️ 씨앗 %2u · 균형 %s · 화면안 도형0 %u회 · minDOn 경계 %.3f~%.3f\n",
			_seed, ok ? "통과" : "⛔", _noShape, (double)_mPt[0][0], (double)_mPt[0][kPtCtx - 1u]);
	}

	// ── 몸통 ──────────────────────────────────────────────────────────
	static void _BodyBegin(RHI* rhi)
	{
		if (!_M.Setup(rhi, _SymOf(_plate), kN, _AxOf(_plate), kTime)) { _Fail("몸통 준비"); return; }
		if (_arm == 1u) { _RepBegin(0u); return; }        // ㈁ = 학습 0
		const bool okUp = (_plate == 0u)
			? (_M.UploadPool(_trA.Val(), _trA.Tgt(), kPoolSteps) && _M.UploadSymbolPool(_trA.Sym(), kPoolSteps))
			: (_M.UploadPool(_trB.Val(), _trB.Tgt(), kPoolSteps) && _M.UploadSymbolPool(_trB.Sym(), kPoolSteps));
		if (!okUp) { _Fail("학습 풀 업로드"); return; }
		_step = 0u; _st = kBodyTrain;
	}

	static void _BodyTrain()
	{
		if (_step >= kSteps) { _RepBegin(0u); return; }
		for (uint32 i = 0; i < kPerTick && _step < kSteps; ++i)
		{
			_M.SelectStep(_step % kPoolSteps);
			if (!_M.Forward() || !_M.Backward() || !_M.AdamStep(1.0f)) { _Fail("몸통 스텝"); return; }
			++_step;
		}
	}

	// ── 표현 모으기 — `_rw` 0=프로브학습 · 1=프로브시험① · 2=프로브시험②(재현) ────
	static Array<float>& _FeatOf(uint32 rw) { return (rw == 0u) ? _fPb : ((rw == 1u) ? _fPt : _fPt2); }
	static uint32 _FeatCtx(uint32 rw) { return (rw == 0u) ? kPbCtx : kPtCtx; }

	static void _RepBegin(uint32 rw)
	{
		_rw = rw; _ri = 0u; _rpend = false; _rwait = 0u;
		const uint32 c = (rw == 0u) ? 1u : 2u;
		const uint32 nPool = (rw == 0u) ? kPbPool : kPtPool;
		const bool okUp = (_plate == 0u)
			? (_M.UploadPool(_CorA(c).Val(), _CorA(c).Tgt(), nPool) && _M.UploadSymbolPool(_CorA(c).Sym(), nPool))
			: (_M.UploadPool(_CorB(c).Val(), _CorB(c).Tgt(), nPool) && _M.UploadSymbolPool(_CorB(c).Sym(), nPool));
		if (!okUp) { _Fail("프로브 풀 업로드"); return; }
		Array<float>& F = _FeatOf(rw);
		F.Reset(0);
		const uint32 need = _FeatCtx(rw) * kFeat;
		for (uint32 i = 0; i < need; ++i) F.Add(0.0f);
		_st = kRep;
	}

	// ⭐ **대역별 평균 풀링** — 상태 · 활성 · 앵커를 **따로** 평균해 이어붙인다.
	//   ⚠️ 판 A 는 앵커 축이 없으므로 그 대역이 **전부 0** 으로 남는다(영 대역).
	static void _RepStep()
	{
		if (_rpend)
		{
			if (_rwait > 0u) { --_rwait; return; }
			Array<float> rep;
			if (!_M.ReadRep(rep)) { _Fail("표현 리드백"); return; }
			Array<float>& F = _FeatOf(_rw);
			const uint32 A = _AxOf(_plate), C = _CtxOf(_plate);
			const uint32 nAnc = (_plate == 0u) ? 0u : MLTP3ACtx::kAncAx;
			for (uint32 b = 0; b < kBatch; ++b)
			{
				const uint32 ctx = (_ri - 1u) * kBatch + b;
				float* dst = F.Data() + (uint64)ctx * kFeat;
				for (uint32 d = 0; d < kFeat; ++d) dst[d] = 0.0f;
				for (uint32 t = 0; t < kTime; ++t)
					for (uint32 a = 0; a < A; ++a)
					{
						// 대역 = 0(상태 `a < 5`) · 1(활성 `5 ≤ a < 13`) · 2(앵커 `a ≥ 13`)
						const uint32 band = (a < kStateAx) ? 0u : ((a < kStateAx + kSlots) ? 1u : 2u);
						const float* src = rep.Data() + (uint64)(b * C + t * A + a) * kD;
						float* acc = dst + band * kD;
						for (uint32 d = 0; d < kD; ++d) acc[d] += src[d];
					}
				const float i0 = 1.0f / (float)(kTime * kStateAx);
				const float i1 = 1.0f / (float)(kTime * kSlots);
				for (uint32 d = 0; d < kD; ++d) { dst[d] *= i0; dst[kD + d] *= i1; }
				if (nAnc > 0u)
				{
					const float i2 = 1.0f / (float)(kTime * nAnc);
					for (uint32 d = 0; d < kD; ++d) dst[2u * kD + d] *= i2;
				}
				dst[kFeat - 1u] = 1.0f;                    // 편향
				for (uint32 d = 0; d < kFeat; ++d)
					if (!(dst[d] == dst[d]) || Abs(dst[d]) > 1.0e30f) _finite = false;
			}
			_rpend = false;
		}
		const uint32 nPool = (_rw == 0u) ? kPbPool : kPtPool;
		if (_ri >= nPool) { _RepDone(); return; }
		_M.SelectStep(_ri);
		if (!_M.Forward()) { _Fail("표현 forward"); return; }
		++_ri; _rpend = true; _rwait = MLTEvalGate::kDelay;
	}

	static void _RepDone()
	{
		if (_rw == 0u) { _RepBegin(1u); return; }
		if (_rw == 1u) { _RepBegin(2u); return; }
		bool same = true;
		const uint32 n = kPtCtx * kFeat;
		for (uint32 i = 0; i < n; ++i) if (_fPt[i] != _fPt2[i]) { same = false; break; }
		if (_plate == 0u && _arm == 0u) _repOk[_seed] = same; else _repOk[_seed] = _repOk[_seed] && same;
		_Judge();
	}

	// ── 선형 프로브(회차 88~98 과 같은 절차) ──────────────────────────
	inline static Array<float> _A, _B, _W, _Wb;

	static bool _Fit(float lamScale, float* W)
	{
		const float* X = _fPb.Data();
		_A.Reset(0); _B.Reset(0);
		for (uint32 i = 0; i < kFeat * kFeat; ++i) _A.Add(0.0f);
		for (uint32 i = 0; i < kFeat * kCls; ++i) _B.Add(0.0f);
		float* A = _A.Data(); float* B = _B.Data();
		for (uint32 i = 0; i < kFitCtx; ++i)
		{
			const float* x = X + (uint64)i * kFeat;
			for (uint32 j = 0; j < kFeat; ++j)
			{
				const float xj = x[j];
				if (xj == 0.0f) continue;
				float* row = A + (uint64)j * kFeat;
				for (uint32 k = 0; k <= j; ++k) row[k] += xj * x[k];
				B[(uint64)j * kCls + _yTr[i]] += xj;
			}
		}
		for (uint32 j = 0; j < kFeat; ++j)
			for (uint32 k = 0; k < j; ++k) A[(uint64)k * kFeat + j] = A[(uint64)j * kFeat + k];
		double tr = 0.0;
		for (uint32 j = 0; j < kFeat; ++j) tr += (double)A[(uint64)j * kFeat + j];
		const float lam = (float)(1.0e-2 * (double)lamScale * tr / (double)kFeat);
		for (uint32 j = 0; j < kFeat; ++j) A[(uint64)j * kFeat + j] += lam;
		if (!SolveSymPD(A, B, kFeat, kCls)) return false;
		for (uint32 i = 0; i < kFeat * kCls; ++i) W[i] = B[i];
		return true;
	}

	static double _Ce(const float* X, const uint32* y, uint32 n, const float* W, float tau, uint32* hit)
	{
		double s = 0.0; uint32 h = 0u;
		for (uint32 i = 0; i < n; ++i)
		{
			const float* x = X + (uint64)i * kFeat;
			double z[kCls]; double mx = -1.0e30; uint32 arg = 0u;
			for (uint32 c = 0; c < kCls; ++c)
			{
				double v = 0.0;
				for (uint32 j = 0; j < kFeat; ++j) v += (double)x[j] * (double)W[(uint64)j * kCls + c];
				z[c] = v * (double)tau;
				if (z[c] > mx) { mx = z[c]; arg = c; }
			}
			double se = 0.0;
			for (uint32 c = 0; c < kCls; ++c) se += (double)Exp((float)(z[c] - mx));
			s += (mx + (double)Log((float)se)) - z[y[i]];
			if (arg == y[i]) ++h;
		}
		if (hit != nullptr) *hit = h;
		return (n == 0u) ? 0.0 : (s / (double)n);
	}

	static float _FitTau(const float* Xc, const uint32* yc, const float* W)
	{
		float best = 1.0f; double bce = 1.0e30;
		for (int k = -8; k <= 24; ++k)
		{
			const float tau = Pow(2.0f, (float)k * 0.5f);
			const double ce = _Ce(Xc, yc, kCalCtx, W, tau, nullptr);
			if (ce < bce) { bce = ce; best = tau; }
		}
		const float lo = best * 0.5f, hi = best * 2.0f;
		for (int k = 0; k <= 16; ++k)
		{
			const float tau = lo + (hi - lo) * ((float)k / 16.0f);
			const double ce = _Ce(Xc, yc, kCalCtx, W, tau, nullptr);
			if (ce < bce) { bce = ce; best = tau; }
		}
		return best;
	}

	static bool _Probe(float& ceOut, float& accOut)
	{
		const float* Xc = _fPb.Data() + (uint64)kFitCtx * kFeat;
		const uint32* yc = _yTr + kFitCtx;
		_Wb.Reset(0);
		for (uint32 i = 0; i < kFeat * kCls; ++i) _Wb.Add(0.0f);
		float bestTau = 1.0f; double bce = 1.0e30;
		for (uint32 li = 0; li < kLams; ++li)
		{
			_W.Reset(0);
			for (uint32 i = 0; i < kFeat * kCls; ++i) _W.Add(0.0f);
			if (!_Fit(kLamGrid[li], _W.Data())) continue;
			const float tau = _FitTau(Xc, yc, _W.Data());
			const double ce = _Ce(Xc, yc, kCalCtx, _W.Data(), tau, nullptr);
			if (ce < bce)
			{
				bce = ce; bestTau = tau;
				for (uint32 i = 0; i < kFeat * kCls; ++i) _Wb.Data()[i] = _W[i];
			}
		}
		if (bce > 1.0e29) return false;
		uint32 hit = 0u;
		ceOut = (float)_Ce(_fPt.Data(), _yTe, kPtCtx, _Wb.Data(), bestTau, &hit);
		accOut = (float)hit / (float)kPtCtx;
		return true;
	}

	static void _Judge()
	{
		for (uint32 t = 0; t < kTgts; ++t)
		{
			_yTr = _yPb[t].Data(); _yTe = _yPt[t].Data();
			if (!_Probe(_ce[_plate][_arm][t][_seed], _acc[_plate][_arm][t][_seed]))
			{ _Fail("프로브"); return; }
		}
		LogA("[mlt] 🎚️   %s · %s 씨앗 %2u · **㊀ minDOn %.5f(%.1f%%)** · ㊁ yaw %.5f(%.1f%%)\n",
			_PlateName(_plate), _ArmName(_arm), _seed,
			(double)_ce[_plate][_arm][0][_seed], 100.0 * (double)_acc[_plate][_arm][0][_seed],
			(double)_ce[_plate][_arm][1][_seed], 100.0 * (double)_acc[_plate][_arm][1][_seed]);
		if (++_arm < kArms) { _ToBody(); return; }
		_arm = 0u;
		if (++_plate < kPlates) { _ToBody(); return; }
		_seedOk[_seed] = _finite;
		++_seed; _st = kEncInit;
	}

	static void _Summary()
	{
		double m[kPlates][kArms][kTgts], ma[kPlates][kArms][kTgts];
		uint32 g[kPlates][kArms][kTgts];
		for (uint32 p = 0; p < kPlates; ++p) for (uint32 a = 0; a < kArms; ++a) for (uint32 t = 0; t < kTgts; ++t)
		{ m[p][a][t] = 0.0; ma[p][a][t] = 0.0; g[p][a][t] = 0u; }
		uint32 ok = 0u, bal = 0u, rep = 0u, head = 0u, beatA = 0u, beatB = 0u;
		double gap = 0.0;
		for (uint32 s = 0; s < kSeeds; ++s)
		{
			if (!_seedOk[s]) continue;
			++ok; if (_balOk[s]) ++bal; if (_repOk[s]) ++rep;
			for (uint32 p = 0; p < kPlates; ++p) for (uint32 a = 0; a < kArms; ++a) for (uint32 t = 0; t < kTgts; ++t)
			{
				m[p][a][t] += _ce[p][a][t][s]; ma[p][a][t] += _acc[p][a][t][s];
				if (_ce[p][a][t][s] < kUnif) ++g[p][a][t];
			}
			// ⭐ **표제** — 판B 가 판A 를 넘나(짝지은 A/B · 같은 씨앗 · 같은 활성)
			if (_ce[1][0][0][s] < _ce[0][0][0][s]) ++head;
			gap += (double)(_ce[0][0][0][s] - _ce[1][0][0][s]);
			if (_ce[0][0][0][s] < _ce[0][1][0][s]) ++beatA;   // 판A 의 ㈀<㈁
			if (_ce[1][0][0][s] < _ce[1][1][0][s]) ++beatB;   // 판B 의 ㈀<㈁
		}
		if (ok > 0u)
		{
			for (uint32 p = 0; p < kPlates; ++p) for (uint32 a = 0; a < kArms; ++a) for (uint32 t = 0; t < kTgts; ++t)
			{ m[p][a][t] /= ok; ma[p][a][t] /= ok; }
			gap /= ok;
		}
		const bool plumb = (bal == ok) && (rep == ok) && _finite && (ok > 0u);
		const bool pos = (g[0][0][1] >= kSignPass) && (g[1][0][1] >= kSignPass);
		const bool p1 = (head >= kSignPass);

		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🎚️ **회차 99 · 대역별 풀링 · 앵커 A/B** — 읽은 씨앗 %u/%u\n", ok, kSeeds);
		LogA("[mlt] 🎚️   ⚠️ 견줄 것(**전체 풀링**) — 회차 97 ㈀ 1.0775 · 회차 98 ㈀ 1.0820 │ 양성 0.7911 → **1.0276**(묽어졌다)\n");
		LogA("[mlt] 🎚️   배관 — ㈃ 균형 **%u/%u** · ㈄ 얼림/재현 **%u/%u** · 화면안 도형0 **%u회** → %s\n",
			bal, ok, rep, ok, _noShape, plumb ? "통과" : "⛔");
		LogA("[mlt] 🎚️   균등바닥 **%.4f**(ln3) · 특징 **%u**(대역 %u × %u + 편향)\n",
			(double)kUnif, kFeat, kBands, kD);
		for (uint32 p = 0; p < kPlates; ++p)
			LogA("[mlt] 🎚️   **%s** — ㊀ minDOn ㈀ **%.4f**(%u/%u·%.1f%%) · ㈁ %.4f(%u) │ ㊁ yaw ㈀ **%.4f**(%u/%u·%.1f%%) · ㈁ %.4f(%u)\n",
				_PlateName(p),
				m[p][0][0], g[p][0][0], kSeeds, 100.0 * ma[p][0][0], m[p][1][0], g[p][1][0],
				m[p][0][1], g[p][0][1], kSeeds, 100.0 * ma[p][0][1], m[p][1][1], g[p][1][1]);
		LogA("[mlt] 🎚️   **⭐ 표제 — 판B < 판A(㈀·minDOn) %u/%u ≥%u** → %s   ·   차이 **%+.4f**\n",
			head, kSeeds, kSignPass, p1 ? "✅" : "⛔", gap);
		LogA("[mlt] 🎚️   부산물 — 규율 18(`㈀<㈁`): 판A **%u/%u** · 판B **%u/%u**\n",
			beatA, kSeeds, beatB, kSeeds);
		if (!plumb)
			LogA("[mlt] 🎚️   ⭐ 판정 = ⛔ **판정불가** — 배관이 안 섰다(균형/재현)\n");
		else if (!pos)
			LogA("[mlt] 🎚️   ⭐ 판정 = ⛔ **판정불가** — **양성이 두 판에서 다 서지 않는다**(규율 16 + 23) ⇒ 자가 아직 묽다\n");
		else if (p1)
			LogA("[mlt] 🎚️   ⭐ 판정 = ⭐ ***앵커가 돕는다*** — 같은 활성·같은 차원·같은 절차에서 **판B 가 판A 를 넘는다** ⇒ 회차 50 의 결정을 **뒤집는 것이 옳았다**\n");
		else
			LogA("[mlt] 🎚️   ⭐ 판정 = ⭐ **앵커를 줘도 몸통이 안 쓴다** — 자를 고쳤는데도 안 넘는다 ⇒ 물음이 *몸통은 무엇을 더하나* 로 남는다\n");
		LogA("[mlt] 🎚️   ⚠️ 문맥 %u · 프로브 %u/%u · 3분류의 진단이다 — 절대 성능으로 인용하지 않는다\n",
			kNCtx, kPbCtx, kPtCtx);
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		_E.Destroy(); _done = true;
	}

	static void _Fail(const char* why)
	{
		LogA("[mlt] 🎚️ ⛔ %s (씨앗 %u · 판 %u · 팔 %u · 단계 %u · 코퍼스 %u · 표현 %u/%u)\n",
			why, _seed, _plate, _arm, _st, _cor, _rw, _ri);
		_E.Destroy(); _done = true;
	}

	CW_BODY(MLTL0K0)
};
