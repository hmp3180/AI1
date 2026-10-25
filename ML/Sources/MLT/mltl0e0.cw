// mltl0e0.cw — 🧱 회차 92 · **인코더가 깊이를 담나** (`-mltl0e0`) ⚠️ **L0 이 아니다 — 한 층 아래**
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 92 이다.** ⭐ **하네스보다 먼저 썼다.**
//
// ── ⭐ 왜 층을 내렸나 — **규율 19** ────────────────────────────────────
//   회차 86~91 이 낱말 셋을 잇달아 쟀고 패턴이 나왔다:
//     `yaw`(**입력 그 자체**)      ㈀ 0.7766 ✅ · **㈁ 무작위 0.4233 ✅**
//     `|dYaw|`(입력의 **시간차**)  둘 다 ⛔
//     `min d`(비전 입력의 **잠재 원인**) 둘 다 ⛔
//   ⇒ ⭐ ***읽히는 것은 「입력 값 그 자체」뿐이고 「유도해야 하는 것」은 하나도 안 읽힌다.***
//   ★ ㈁ 무작위 몸통은 대략 **입력의 무작위 사영**이다 — 깊이가 입력에 선형으로 있었다면
//     `yaw` 처럼 잡았을 것이다. 못 잡았다 ⇒ ***범인은 몸통이 아니라 그 앞이다.***
//   ⇒ **규율 19**: *"표현 프로브가 연달아 null 이면 「한 층 아래」를 먼저 재라. ㈀⛔·㈁⛔ 이면
//     다음 회차는 낱말 교체가 아니라 **층 내리기**다."*
//
// ── ⚠️⚠️ **이 회차에는 몸통이 없다** ──────────────────────────────────────
//   몸통 학습 코퍼스도 · 800스텝 학습도 · 표현 리드백도 **없다.** 인코더만 학습시키고
//   **코퍼스 입력을 CPU 에서 그대로 읽는다.** ⇒ 회차 91 보다 **싸다**.
//
// ── 읽는 것 = ***몸통이 받는 것 전부*** ────────────────────────────────────
//   ⚠️ 먼저 확인했다 — 몸통에 올라가는 것은 `UploadPool(val)` 과 `UploadSymbolPool(sym)` **둘뿐**이고
//     `MLTP3Ctx::_anc`(2D 앵커)는 **올라가지 않는다** ⇒ 몸통이 보는 것은 **(id, 세기) 쌍**이다.
//   | ㉠ 세기가중 가방(관문 시각) 250 | ㉡ 개수 가방(문맥 전체) 250 | ㉢ 세기 8(내림차순) | 편향 1 | = **509** |
//
//   ⚠️ 특징이 509 개라 **맞춤 표본을 늘린다**: `kPbCtx` 512 → **1536**(맞춤 1408 / 보정 128 = 2.8:1).
//     ★ **자의 개선이고 미리 적었다** — 결과를 보고 늘리는 것이 아니다.
//
// ── 팔 둘 = **특징 집합**(몸통이 없으므로 팔의 뜻이 바뀐다) ────────────────
//   **㈀ 전부**(㉠+㉡+㉢ · 509)  ↔  **㈁ 세기만**(㉢ · 9)
//   ⭐ 깊이가 **세기만으로** 나오면 **id 는 무관**하다는 뜻이다.
//
// ── 사다리 셋 ─────────────────────────────────────────────────────────────
//   **㊀ 표제** `min d` 3분위 — ⭐ ***인코더가 깊이를 담나***
//   **㊁ 현실 양성** 화면 **잉크 비율** 3분위 — 이것도 안 담으면 **아무것도 안 담는 것**이다
//   **㊂ 강한 양성** **최대 세기** 3분위 — ⚠️ ㈁ 특징에 **문자 그대로** 있다 ⇒ 기계 검사
//   ⚠️ 잉크 비율은 **최빈 바이트 비율**로 잰다(`ink = 1 − max(hist)/4096`) — 배경색 상수를
//     하네스가 다시 적지 않으려는 것이다(같은 사실을 두 곳에 두지 않는다).
//
// ── 관문 ──────────────────────────────────────────────────────────────────
//   **배관** ㈃ 균형(순위 3분위 · `sd=0` · ±1표본 · **세 표적 다**) · **㊂ `≥10/12`**(기계 검사)
//   **표제 ㊀** `CE(㈀ · 깊이) < ln3` — `≥10/12`   ⚠️ **㊁ 이 안 서면 판정불가**(규율 16)
//   **잡음 바닥**(규율 9) `ln3 = 1.0986` · `≥10/12 ⇒ p = 0.0193` · 표제 하나 ⇒ **`Q = 0.0193`**
//
// ── ⭐ 예측을 미리 적었다 ─────────────────────────────────────────────────
//   ㊂ = **12/12** · ㊁ = **≥10/12** · **㊀ = ⚠️ 진짜 모른다** ← 그것이 이 회차의 값이다
//
// ── ⭐ 결과의 뜻도 미리 못박았다 ──────────────────────────────────────────
//   | ㊀✅            | ⭐ **인코더는 담는다** ⇒ ***범인은 몸통이다*** |
//   | ㊀⛔ · ㈁ 도 ⛔ | ⭐ **인코더가 안 담는다** ⇒ ***범인은 인코더다*** — 인코딩 층부터 고친다 |
//   | ㊀⛔ · ㈁ 은 ✅ | ⚠️ 509 차원의 **과적합으로 ㈀ 이 진 것** ⇒ 자를 고쳐 다시 잰다 |
//   | ㊁⛔            | ⛔ **판정불가** |
// ══════════════════════════════════════════════════════════════════════════════

using namespace PE;

class MLTL0E0
{
public:
	static void Tick(RHI* rhi)
	{
		if (_done || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltl0e0"))
		{
			LogA("[mlt] 🧱 회차 92(인코더가 깊이를 담나)는 **꺼져 있다**(`-mltl0e0`)\n");
			_done = true; return;
		}
		if (!_banner) { _Banner(); _banner = true; }
		if (_seed >= kSeeds) { _Summary(); return; }
		if (_st == kEncInit)  { _EncBegin(rhi); return; }
		if (_st == kEncTrain) { _EncTrain(); return; }
		_Gather();
	}

	static bool Done() { return _done; }

private:
	static constexpr uint32 kSeeds = 12u;
	static constexpr uint32 kEncF = 32u, kEncSteps = 1200u, kEncPerTick = 8u;
	static constexpr uint32 kN = 250u, kLocal = 8u;
	static constexpr uint32 kTime  = MLTP3Ctx::kTime;      // 8
	static constexpr uint32 kBatch = MLTP3Ctx::kBatch;     // 8
	static constexpr uint32 kSlots = MLTP3Ctx::kPersist;   // 8
	static constexpr uint32 kCandidates = MLTP2Cfg::kPatches * kLocal;
	static constexpr uint32 kGroup = kEncF / kTime;        // 4
	static constexpr uint32 kGateT = kTime - 2u;           // 6 = 관문 시각(회차 88~91 과 같다)

	// ⚠️ 몸통이 없으므로 **몸통 학습 코퍼스가 없다** — 프로브 학습/시험 둘뿐이다.
	static constexpr uint32 kPbCtx = 1536u, kPtCtx = 512u;
	static constexpr uint32 kPbEpi = 2001u, kPtEpi = 5001u;
	static_assert(kPtEpi >= kPbEpi + kPbCtx,
		"프로브 시험이 프로브 학습과 겹친다 — kPtEpi >= kPbEpi + kPbCtx 여야 한다(규율 12)");

	static constexpr uint32 kFitCtx = 1408u;
	static constexpr uint32 kCalCtx = kPbCtx - kFitCtx;    // 128
	static_assert(kCalCtx >= 64u, "보정 분할이 너무 작으면 τ 가 그 자체로 흔들린다");

	// 특징 — ㉠ 세기가중 가방(250) + ㉡ 개수 가방(250) + ㉢ 세기 8 + 편향
	static constexpr uint32 kFeatAll = kN + kN + kSlots + 1u;   // 509
	static constexpr uint32 kFeatMag = kSlots + 1u;             // 9
	static constexpr uint32 kArms = 2u;      // 0 = 전부 · 1 = 세기만
	static constexpr uint32 kTgts = 3u;      // 0 = 깊이(표제) · 1 = 잉크(현실 양성) · 2 = 최대세기(강한 양성)
	static constexpr uint32 kCls = 3u;
	static constexpr uint32 kSignPass = 10u;
	static constexpr float  kUnif = 1.0986123f;
	static constexpr uint32 kBalSlack = 1u;
	static constexpr uint32 kLams = 4u;
	static constexpr float  kLamGrid[kLams] = { 0.1f, 1.0f, 10.0f, 100.0f };
	static constexpr float  kNoShape = 1.0e6f;

	enum { kEncInit, kEncTrain, kGather };

	inline static MLTP2Enc _E;
	inline static MLTP3Ctx _pb, _pt;
	inline static bool _done = false, _banner = false, _encSetup = false, _finite = true;
	inline static bool _pending = false;
	inline static uint32 _seed = 0u, _st = kEncInit, _step = 0u;
	inline static uint32 _cor = 0u, _gGrp = 0u, _gIdx = 0u, _noShape = 0u;
	inline static Array<float> _code, _norm;

	// 특징 — `_X[arm]` 은 `[ctx][kFeatOf(arm)]`
	inline static Array<float> _XpbAll, _XptAll, _XpbMag, _XptMag;
	// 표적 원값과 계급
	inline static Array<float> _mPb[kTgts], _mPt[kTgts];
	inline static Array<uint32> _yPb[kTgts], _yPt[kTgts];
	inline static const uint32* _yTr = nullptr;
	inline static const uint32* _yTe = nullptr;

	inline static float _ce[kArms][kTgts][kSeeds], _acc[kArms][kTgts][kSeeds];
	inline static bool  _seedOk[kSeeds], _balOk[kSeeds];

	static uint32 _FeatOf(uint32 arm) { return (arm == 0u) ? kFeatAll : kFeatMag; }
	static Array<float>& _Xpb(uint32 arm) { return (arm == 0u) ? _XpbAll : _XpbMag; }
	static Array<float>& _Xpt(uint32 arm) { return (arm == 0u) ? _XptAll : _XptMag; }
	static const char* _TgtName(uint32 t)
	{ return (t == 0u) ? "㊀ 깊이(표제)" : ((t == 1u) ? "㊁ 잉크(현실양성)" : "㊂ 최대세기(강한양성)"); }

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🧱 **회차 92 · 인코더가 깊이를 담나**(⚠️ **L0 이 아니다 — 한 층 아래** · 규율 19)\n");
		LogA("[mlt] 🧱   ⚠️⚠️ **이 회차에는 몸통이 없다** — 인코더만 학습시키고 **코퍼스 입력을 그대로** 읽는다\n");
		LogA("[mlt] 🧱   읽는 것 = 몸통이 받는 것 전부 — 세기가중 가방 %u + 개수 가방 %u + 세기 %u + 편향 = **%u**\n",
			kN, kN, kSlots, kFeatAll);
		LogA("[mlt] 🧱   팔 둘 — **㈀ 전부(%u)** ↔ **㈁ 세기만(%u)**(⭐ 세기만으로 나오면 id 는 무관하다는 뜻)\n",
			kFeatAll, kFeatMag);
		LogA("[mlt] 🧱   사다리 셋 — **㊀ 깊이**(표제) · **㊁ 잉크 비율**(현실 양성 · 규율 16) · **㊂ 최대 세기**(강한 양성 = 기계 검사)\n");
		LogA("[mlt] 🧱   프로브 — 맞춤 %u / 보정 %u · λ 격자 {0.1,1,10,100} · 온도 τ · ⚠️ 시험 %u 는 끝까지 안 본다\n",
			kFitCtx, kCalCtx, kPtCtx);
		LogA("[mlt] 🧱   분리 — 프로브학습 %u~%u · 프로브시험 %u~%u(규율 12)\n",
			kPbEpi, kPbEpi + kPbCtx - 1u, kPtEpi, kPtEpi + kPtCtx - 1u);
		LogA("[mlt] 🧱   잡음 바닥 — 균등 CE **%.4f**(ln3) · 부호검정 %u/12 ⇒ **Q = 0.0193**\n",
			(double)kUnif, kSignPass);
		LogA("[mlt] 🧱   ⭐ **예측** — ㊂ 12/12 · ㊁ ≥10/12 · **㊀ 진짜 모른다**(담으면 범인은 몸통 · 안 담으면 인코더)\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

	// ── 인코더(회차 85~91 과 같다) ───────────────────────────────────
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
		_pb.SetSortById(true); _pt.SetSortById(true);
		_pb.Begin(kPbCtx, kN); _pt.Begin(kPtCtx, kN);
		for (uint32 t = 0; t < kTgts; ++t) { _mPb[t].Reset(0); _mPt[t].Reset(0); }
		_cor = 0u; _gGrp = 0u; _gIdx = 0u; _pending = false; _st = kGather;
	}

	// ⚠️ **잉크 비율 = 1 − 최빈 바이트 비율.** 배경색 상수를 여기 다시 적지 않는다.
	static float _Ink(const Bytes& packed)
	{
		uint32 hist[256];
		for (uint32 i = 0; i < 256u; ++i) hist[i] = 0u;
		const uint8* p = (const uint8*)packed.GetData();
		const uint32 n = (uint32)MLTWorldCfg::kPixels;
		for (uint32 i = 0; i < n; ++i) ++hist[p[i]];
		uint32 mx = 0u;
		for (uint32 i = 0; i < 256u; ++i) if (hist[i] > mx) mx = hist[i];
		return 1.0f - (float)mx / (float)n;
	}

	static void _Gather()
	{
		MLTP3Ctx& C = (_cor == 0u) ? _pb : _pt;
		const uint32 nCtx = (_cor == 0u) ? kPbCtx : kPtCtx;
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
			const uint32 epi = (_cor == 0u) ? kPbEpi : kPtEpi;
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
					if (t == kGateT)
					{
						// ㊀ 깊이 — ⚠️ `VisibleShapes` 는 **판정 창구**다(모델 입력에 안 들어간다).
						//   ⚠️ 목록은 **먼 것부터** 정렬돼 있으므로 **마지막이 가장 가깝다**.
						MLTShapeView vs[MLTWorldCfg::kShapes];
						const int nv = w.VisibleShapes(vs, MLTWorldCfg::kShapes);
						const float dmin = (nv > 0) ? vs[nv - 1].d : (++_noShape, kNoShape);
						// ㊁ 잉크 비율 — **같은 프레임**에서 잰다
						const float ink = _Ink(packed);
						if (_cor == 0u) { _mPb[0].Add(dmin); _mPb[1].Add(ink); }
						else            { _mPt[0].Add(dmin); _mPt[1].Add(ink); }
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
		if (++_cor < 2u) return;
		_BuildFeatures();
		_MakeWords();
		_Judge();
	}

	// ── ⭐ 특징을 코퍼스에서 만든다(CPU · 몸통 없음) ──────────────────
	static void _BuildOne(const MLTP3Ctx& C, uint32 nCtx, Array<float>& XA, Array<float>& XM,
		Array<float>& maxMag)
	{
		XA.Reset(0); XM.Reset(0);
		for (uint32 i = 0; i < nCtx * kFeatAll; ++i) XA.Add(0.0f);
		for (uint32 i = 0; i < nCtx * kFeatMag; ++i) XM.Add(0.0f);
		for (uint32 ctx = 0; ctx < nCtx; ++ctx)
		{
			float* a = XA.Data() + (uint64)ctx * kFeatAll;
			float* m = XM.Data() + (uint64)ctx * kFeatMag;
			// ㉡ 개수 가방 — 문맥 전체
			for (uint32 t = 0; t < kTime; ++t)
			{
				const uint32 base = MLTP3Ctx::Row(ctx, t, MLTP3Ctx::kStateAx);
				for (uint32 j = 0; j < kSlots; ++j)
				{
					const int id = (int)(C.Sym()[base + j] - (float)MLTP3Ctx::kStateAx);
					if (id >= 0 && id < (int)kN) a[kN + (uint32)id] += 1.0f;
				}
			}
			// ㉠ 세기가중 가방 + ㉢ 세기 8 — 관문 시각
			const uint32 gb = MLTP3Ctx::Row(ctx, kGateT, MLTP3Ctx::kStateAx);
			float mg[kSlots];
			for (uint32 j = 0; j < kSlots; ++j)
			{
				const int id = (int)(C.Sym()[gb + j] - (float)MLTP3Ctx::kStateAx);
				const float v = C.Val()[gb + j];
				if (id >= 0 && id < (int)kN) a[(uint32)id] += v;
				mg[j] = v;
			}
			// 내림차순 정렬(⚠️ 슬롯 **순서**가 신호가 되지 않게 — 값만 남긴다)
			for (uint32 p = 0; p < kSlots; ++p)
				for (uint32 q = p + 1u; q < kSlots; ++q)
					if (mg[q] > mg[p]) { const float tmp = mg[p]; mg[p] = mg[q]; mg[q] = tmp; }
			for (uint32 j = 0; j < kSlots; ++j) { a[kN + kN + j] = mg[j]; m[j] = mg[j]; }
			a[kFeatAll - 1u] = 1.0f; m[kFeatMag - 1u] = 1.0f;      // 편향
			maxMag.Add(mg[0]);                                      // ㊂ 강한 양성의 표적
			for (uint32 d = 0; d < kFeatAll; ++d)
				if (!(a[d] == a[d]) || Abs(a[d]) > 1.0e30f) _finite = false;
		}
	}

	static void _BuildFeatures()
	{
		_mPb[2].Reset(0); _mPt[2].Reset(0);
		_BuildOne(_pb, kPbCtx, _XpbAll, _XpbMag, _mPb[2]);
		_BuildOne(_pt, kPtCtx, _XptAll, _XptMag, _mPt[2]);
	}

	// ── 순위 계급(회차 87 이 세운 것 — `sd = 0`) ──────────────────────
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
		LogA("[mlt] 🧱 씨앗 %2u · 균형 %s · 도형0 %u회 · 깊이 경계 %.3f~%.3f · 잉크 %.3f~%.3f\n",
			_seed, ok ? "통과" : "⛔", _noShape,
			(double)_mPt[0][0], (double)_mPt[0][kPtCtx - 1u],
			(double)_mPt[1][0], (double)_mPt[1][kPtCtx - 1u]);
	}

	// ── 선형 프로브(회차 88~91 과 같은 절차) ──────────────────────────
	inline static Array<float> _A, _B, _W, _Wb;

	static bool _Fit(uint32 arm, float lamScale, float* W)
	{
		const uint32 F = _FeatOf(arm);
		const float* X = _Xpb(arm).Data();
		_A.Reset(0); _B.Reset(0);
		for (uint32 i = 0; i < F * F; ++i) _A.Add(0.0f);
		for (uint32 i = 0; i < F * kCls; ++i) _B.Add(0.0f);
		float* A = _A.Data(); float* B = _B.Data();
		for (uint32 i = 0; i < kFitCtx; ++i)
		{
			const float* x = X + (uint64)i * F;
			for (uint32 j = 0; j < F; ++j)
			{
				const float xj = x[j];
				if (xj == 0.0f) continue;
				float* row = A + (uint64)j * F;
				for (uint32 k = 0; k <= j; ++k) row[k] += xj * x[k];
				B[(uint64)j * kCls + _yTr[i]] += xj;
			}
		}
		for (uint32 j = 0; j < F; ++j)
			for (uint32 k = 0; k < j; ++k) A[(uint64)k * F + j] = A[(uint64)j * F + k];
		double tr = 0.0;
		for (uint32 j = 0; j < F; ++j) tr += (double)A[(uint64)j * F + j];
		const float lam = (float)(1.0e-2 * (double)lamScale * tr / (double)F);
		for (uint32 j = 0; j < F; ++j) A[(uint64)j * F + j] += lam;
		if (!SolveSymPD(A, B, F, kCls)) return false;
		for (uint32 i = 0; i < F * kCls; ++i) W[i] = B[i];
		return true;
	}

	static double _Ce(const float* X, const uint32* y, uint32 n, uint32 F, const float* W,
		float tau, uint32* hit)
	{
		double s = 0.0; uint32 h = 0u;
		for (uint32 i = 0; i < n; ++i)
		{
			const float* x = X + (uint64)i * F;
			double z[kCls]; double mx = -1.0e30; uint32 arg = 0u;
			for (uint32 c = 0; c < kCls; ++c)
			{
				double v = 0.0;
				for (uint32 j = 0; j < F; ++j) v += (double)x[j] * (double)W[(uint64)j * kCls + c];
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

	static float _FitTau(const float* Xc, const uint32* yc, uint32 F, const float* W)
	{
		float best = 1.0f; double bce = 1.0e30;
		for (int k = -8; k <= 24; ++k)
		{
			const float tau = Pow(2.0f, (float)k * 0.5f);
			const double ce = _Ce(Xc, yc, kCalCtx, F, W, tau, nullptr);
			if (ce < bce) { bce = ce; best = tau; }
		}
		const float lo = best * 0.5f, hi = best * 2.0f;
		for (int k = 0; k <= 16; ++k)
		{
			const float tau = lo + (hi - lo) * ((float)k / 16.0f);
			const double ce = _Ce(Xc, yc, kCalCtx, F, W, tau, nullptr);
			if (ce < bce) { bce = ce; best = tau; }
		}
		return best;
	}

	static bool _Probe(uint32 arm, float& ceOut, float& accOut)
	{
		const uint32 F = _FeatOf(arm);
		const float* Xc = _Xpb(arm).Data() + (uint64)kFitCtx * F;
		const uint32* yc = _yTr + kFitCtx;
		_Wb.Reset(0);
		for (uint32 i = 0; i < F * kCls; ++i) _Wb.Add(0.0f);
		float bestTau = 1.0f; double bce = 1.0e30;
		for (uint32 li = 0; li < kLams; ++li)
		{
			_W.Reset(0);
			for (uint32 i = 0; i < F * kCls; ++i) _W.Add(0.0f);
			if (!_Fit(arm, kLamGrid[li], _W.Data())) continue;
			const float tau = _FitTau(Xc, yc, F, _W.Data());
			const double ce = _Ce(Xc, yc, kCalCtx, F, _W.Data(), tau, nullptr);
			if (ce < bce)
			{
				bce = ce; bestTau = tau;
				for (uint32 i = 0; i < F * kCls; ++i) _Wb.Data()[i] = _W[i];
			}
		}
		if (bce > 1.0e29) return false;
		uint32 hit = 0u;
		ceOut = (float)_Ce(_Xpt(arm).Data(), _yTe, kPtCtx, F, _Wb.Data(), bestTau, &hit);
		accOut = (float)hit / (float)kPtCtx;
		return true;
	}

	static void _Judge()
	{
		for (uint32 t = 0; t < kTgts; ++t)
		{
			_yTr = _yPb[t].Data(); _yTe = _yPt[t].Data();
			for (uint32 a = 0; a < kArms; ++a)
				if (!_Probe(a, _ce[a][t][_seed], _acc[a][t][_seed])) { _Fail("프로브"); return; }
			LogA("[mlt] 🧱   %s 씨앗 %2u · **㈀ 전부 %.5f**(%.1f%%) · ㈁ 세기만 %.5f(%.1f%%)\n",
				_TgtName(t), _seed,
				(double)_ce[0][t][_seed], 100.0 * (double)_acc[0][t][_seed],
				(double)_ce[1][t][_seed], 100.0 * (double)_acc[1][t][_seed]);
		}
		_seedOk[_seed] = _finite;
		++_seed; _st = kEncInit;
	}

	static void _Summary()
	{
		double m[kArms][kTgts], ma[kArms][kTgts];
		uint32 g[kArms][kTgts];
		for (uint32 a = 0; a < kArms; ++a) for (uint32 t = 0; t < kTgts; ++t)
		{ m[a][t] = 0.0; ma[a][t] = 0.0; g[a][t] = 0u; }
		uint32 ok = 0u, bal = 0u;
		for (uint32 s = 0; s < kSeeds; ++s)
		{
			if (!_seedOk[s]) continue;
			++ok; if (_balOk[s]) ++bal;
			for (uint32 a = 0; a < kArms; ++a) for (uint32 t = 0; t < kTgts; ++t)
			{
				m[a][t] += _ce[a][t][s]; ma[a][t] += _acc[a][t][s];
				if (_ce[a][t][s] < kUnif) ++g[a][t];
			}
		}
		if (ok > 0u) for (uint32 a = 0; a < kArms; ++a) for (uint32 t = 0; t < kTgts; ++t)
		{ m[a][t] /= ok; ma[a][t] /= ok; }

		const bool plumb = (bal == ok) && _finite && (ok > 0u) && (g[1][2] >= kSignPass);
		const bool pos = (g[0][1] >= kSignPass);
		const bool p1 = (g[0][0] >= kSignPass);
		const bool magOnly = (g[1][0] >= kSignPass);

		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🧱 **회차 92 · 인코더가 깊이를 담나**(한 층 아래) — 읽은 씨앗 %u/%u\n", ok, kSeeds);
		LogA("[mlt] 🧱   ⚠️ 견줄 것(**회차 91 · 몸통**) — 깊이 ㈀ 1.0997(6/12) · ㈁ 무작위 1.0992(5/12) ⇒ 둘 다 ⛔\n");
		LogA("[mlt] 🧱   배관 — ㈃ 균형 **%u/%u** · ㊂ 강한양성(㈁ 세기만) **%u/%u** · 도형0 **%u회** → %s\n",
			bal, ok, g[1][2], kSeeds, _noShape, plumb ? "통과" : "⛔");
		LogA("[mlt] 🧱   균등바닥 **%.4f**(ln3)\n", (double)kUnif);
		LogA("[mlt] 🧱   **㊂ 최대세기** — ㈀ %.4f(%u/%u · %.1f%%) · **㈁ %.4f(%u/%u · %.1f%%)**\n",
			m[0][2], g[0][2], kSeeds, 100.0 * ma[0][2], m[1][2], g[1][2], kSeeds, 100.0 * ma[1][2]);
		LogA("[mlt] 🧱   **㊁ 잉크 비율** — **㈀ %.4f(%u/%u · %.1f%%)** · ㈁ %.4f(%u/%u · %.1f%%)\n",
			m[0][1], g[0][1], kSeeds, 100.0 * ma[0][1], m[1][1], g[1][1], kSeeds, 100.0 * ma[1][1]);
		LogA("[mlt] 🧱   **㊀ 깊이(표제)** — **㈀ %.4f(%u/%u · %.1f%%)** · ㈁ %.4f(%u/%u · %.1f%%)\n",
			m[0][0], g[0][0], kSeeds, 100.0 * ma[0][0], m[1][0], g[1][0], kSeeds, 100.0 * ma[1][0]);
		LogA("[mlt] 🧱   **표제 ㊀ ≥%u** → %s\n", kSignPass, p1 ? "✅" : "⛔");
		if (!plumb)
			LogA("[mlt] 🧱   ⭐ 판정 = ⛔ **판정불가** — 배관이 안 섰다(균형 또는 강한 양성)\n");
		else if (!pos)
			LogA("[mlt] 🧱   ⭐ 판정 = ⛔ **판정불가** — **잉크 비율조차 못 읽는다**(규율 16) ⇒ 표제를 읽지 않는다\n");
		else if (p1)
			LogA("[mlt] 🧱   ⭐ 판정 = ⭐ **인코더는 깊이를 담는다** ⇒ ***범인은 몸통이다*** — 회차 91 의 null 은 **몸통이 그것을 안 쓴 것**이다\n");
		else if (magOnly)
			LogA("[mlt] 🧱   ⭐ 판정 = ⚠️ **㈁ 세기만은 되는데 ㈀ 전부가 진다** ⇒ **%u 차원의 과적합** — 자를 고쳐 다시 잰다\n", kFeatAll);
		else
			LogA("[mlt] 🧱   ⭐ 판정 = ⭐ **인코더가 깊이를 안 담는다** ⇒ ***범인은 인코더다*** — L0 을 세우려면 **인코딩 층부터** 고친다(`k` · 사전 크기 · 선택자)\n");
		LogA("[mlt] 🧱   ⚠️ 프로브 %u/%u · 3분류의 진단이다 — 절대 성능으로 인용하지 않는다\n", kPbCtx, kPtCtx);
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		_E.Destroy(); _done = true;
	}

	static void _Fail(const char* why)
	{
		LogA("[mlt] 🧱 ⛔ %s (씨앗 %u · 단계 %u · 코퍼스 %u · 그룹 %u/%u)\n",
			why, _seed, _st, _cor, _gGrp, _gIdx);
		_E.Destroy(); _done = true;
	}

	CW_BODY(MLTL0E0)
};
