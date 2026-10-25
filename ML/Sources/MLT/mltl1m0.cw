// mltl1m0.cw — 🧩 회차 156 · **조합과 이진이 표적을 가르나**(거르는 회차) (`-mlt -mltl1m0`)
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 156 다.** ⭐ **하네스보다 먼저 썼다.**
//   **상위 캔버스: `자의 천장을 올린다` · 141~142 = 2회차**
//
// ── ⭐ 표제 — ***「새지 않으면서 변화 표적을 가르는 낱말」이 하나라도 있나*** ──
//   회차 141 이 세운 자는 **변화 표적**(문맥당 14.0개)을 채점한다. 그 위에 세울 표제 낱말이
//   필요한데 ⛔ `minDOn` 은 회차 140 이 **편향 바닥과 구별 못 함**으로 죽였다.
//   ⇒ ★ **판정 회차를 돌리기 전에 후보를 거른다** — ⚠️⚠️ 138·139 가 그 거르기를 안 하고
//   판정을 두 번 돌렸고 둘 다 판정불가였다.
//
// ── 🎛️ 후보 — ⚠️ **전부 `VisibleShapes`(판정 창구)에서만 뽑는다** ─────────
//   ⚠️⚠️ 상태 축(`x·y·z·yaw·pitch`)에서 유도되는 것은 후보가 아니다 — **이미 모델 입력**이라
//   `Î` 가 커도 **조건부 MI 는 0** 이다.
//   ㈠ `nOn`(화면 안 도형 수) · ⭐ ㈡ `minEdge`(화면 경계까지 최소 픽셀 — **변화의 직접 원인**) ·
//   ㈢ `maxR`(최대 화면 반지름) · ㈣ `minDOn`(⚠️ **회차 140 재현 대조**) ·
//   ⭐ ㈤ **양성 참조** = 회차 141 의 「바뀌는 슬롯의 표적 id」(**눈금** · 규율 16)
//
// ── 📏 자 — ⭐ 무차원 둘(규율 31) ────────────────────────────────────────
//   ㉠ **가림 효율** = `(Î − Î섞음) / H(낱말)`
//   ㉡ **눈금 대비** = `(Î − Î섞음) / (Î − Î섞음)(㈤)`
//   ⚠️⚠️ **`Î` 는 무조건부다** ⇒ **거르는 자**이지 **판정하는 자**가 아니다(규율 50 의 짝).
//   ⚠️ 표적은 **변화 표적만** 센다(141 의 자가 채점하는 그 자리).
//
// ── 🔮 예측(재기 전에 적었다) ────────────────────────────────────────────
//   ⭐ ㈡ **가장 유망**(눈금 대비 0.15~0.4) · ㈠·㈢ 중간(0.05~0.2) · ㈣ ⛔ 바닥(<0.05)
//   ⭐ 표제 = **하나 이상 통과할 것**. ⚠️ 위험: 넷 다 바닥이면 낱말을 **행동**(`MLTAct`)에서 찾아야 한다.
// ══════════════════════════════════════════════════════════════════════════════

using namespace PE;

class MLTL1M0
{
public:
	static void Tick(RHI* rhi)
	{
		if (_done || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltl1m0"))
		{
			LogA("[mlt] 🧩 회차 156(조합과 이진이 표적을 가르나)는 **꺼져 있다**(`-mltl1m0`)\n");
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

	// ⭐ **시험 코퍼스만** 모은다(`_trA`·`_pbA` 는 이 회차에서 안 쓴다) ⇒ 회차 140 의 1/3 비용.
	//   ⚠️ `_ptA` 는 같은 씨앗·같은 `epi` 라 **138~141 과 같은 코퍼스**다(인코더도 같은 학습).
	static constexpr uint32 kPtCtx = 512u, kPtEpi = 5001u;
	static constexpr uint32 kWords = kPtCtx * kTime;       // 4096
	static constexpr float  kNoShape = 1.0e6f;

	// 후보 다섯 — 앞 넷은 연속값(8분위 순위), ㈤ 는 141 의 계급(0 = 변화 없음 · 1~8)
	// ⭐ 회차 156 — 후보 여섯. ⚠️ **계급 수가 후보마다 다르다**(그것이 이 회차의 핵심).
	//   ★ 회차 142 는 넷 다 8분위였고, 그것이 `H` 를 키워 `(Î−Î섞음)/H` 의 **분모를 부풀렸다**.
	static constexpr uint32 kCands = 6u, kRawCands = 5u;
	static constexpr uint32 kRefCls = 9u;     // ㈥ 양성 참조(눈금)
	// 후보별 계급 수 — ㈠ 이진 · ㈡ 경계걸침 개수 · ㈢ 조합 2×2 · ㈣ 변화방향 · ㈤ 142 재현
	static constexpr uint32 kClsOf[kRawCands] = { 2u, 3u, 4u, 3u, 8u };

	enum { kEncInit, kEncTrain, kGather, kMeasure };

	inline static MLTP2Enc _E;
	inline static MLTP3Ctx _ptA;
	inline static bool _done = false, _banner = false, _encSetup = false, _ok = true;
	inline static bool _pending = false;
	inline static uint32 _seed = 0u, _st = kEncInit, _step = 0u;
	inline static uint32 _gGrp = 0u, _gIdx = 0u;
	inline static Array<float> _code, _norm;
	inline static Array<float> _raw[kRawCands];      // [ctx*kTime + t]
	inline static Array<uint32> _w[kCands];

	inline static double _mi[kCands][kSeedsMax], _miS[kCands][kSeedsMax], _hW[kCands][kSeedsMax];
	inline static double _nCh[kSeedsMax], _hY[kSeedsMax];
	inline static double _hYlast = 0.0;
	inline static uint32 _pos[kCands];               // `Î−Î섞음 > 0` 인 씨앗 수

	static const char* _Name(uint32 c)
	{
		switch (c)
		{
		case 0u: return "㈠ minEdge 이진(2) ⭐";
		case 1u: return "㈡ 경계걸침 개수(3)⭐";
		case 2u: return "㈢ edge×maxR 조합(4)⭐";
		case 3u: return "㈣ nOn 변화방향(3) ⭐";
		case 4u: return "㈤ minEdge 8분위(142)";
		default: return "㈥ 변화표적id(눈금)⭐";
		}
	}

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🧩 **회차 156 · 조합과 이진이 표적을 가르나**(⭐ 학습 0 · 거르는 회차 · %s)\n",
			(_seeds == 1u) ? "⚠️ 1씨앗 진단" : "씨앗 12");
		LogA("[mlt] 🔍   ⭐ 표제 = ***「새지 않으면서 변화 표적을 가르는 낱말」이 하나라도 있나***\n");
		LogA("[mlt] 🔍   ⚠️⚠️ 후보는 **전부 `VisibleShapes`(판정 창구)에서만** — 상태 축은 이미 모델 입력이다\n");
		LogA("[mlt] 🧩   ⭐ ㈠ minEdge **이진**(2) · ⭐ ㈡ **경계걸침 개수**(3 · `e<r` · 임의 상수 없다) · ⭐ ㈢ edge×maxR **조합**(4)\n");
		LogA("[mlt] 🧩   ⭐ ㈣ nOn **변화방향**(3 · 과거만) · ⭐ ㈤ **142 재현 대조**(minEdge 8분위) · ⭐ ㈥ 눈금\n");
		LogA("[mlt] 🧩   ★ 핵심 짝 = **㈠(2계급) ↔ ㈤(8계급)** — **같은 양**이고 계급만 다르다\n");
		LogA("[mlt] 🧩   ⚠️ 142 의 ⛔ 를 *\"세계에 낱말이 없다\"* 가 아니라 *\"**단일 스칼라의 8분위 계급에는** 없다\"* 로 좁혀 읽는다\n");
		LogA("[mlt] 🔍   ⭐ 자 = **가림 효율** `(Î−Î섞음)/H` · **눈금 대비** `(Î−Î섞음)/(㈤ 의 것)`\n");
		LogA("[mlt] 🔍   ⚠️ `Î` 는 **무조건부** ⇒ **거르는 자**이지 판정하는 자가 아니다(규율 50 의 짝)\n");
		LogA("[mlt] 🔍   ⭐ 관문 = 후보가 `Î−Î섞음>0` **%u/%u** 이고 **눈금 대비 ≥ 0.10**\n",
			(_seeds * 10u + 11u) / 12u, _seeds);
		LogA("[mlt] 🔍   ⭐ 예측 — ㈡ 0.15~0.4(유망) · ㈠㈢ 0.05~0.2 · ㈣ **바닥**(<0.05)\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

	// ── 인코더(138~141 과 같다) ─────────────────────────────────────
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
		_ptA.SetSortById(true); _ptA.Begin(kPtCtx, kN);
		for (uint32 c = 0; c < kRawCands; ++c) _raw[c].Reset(0);
		_gGrp = 0u; _gIdx = 0u; _pending = false; _st = kGather;
	}

	static void _Gather()
	{
		if (_pending)
		{
			Array<float> ids, mag;
			if (!_E.ReadAct(ids, mag) || ids.Count() != kCandidates) { _Fail("활성 리드백"); return; }
			const uint32 cx = _gGrp * kGroup + (_gIdx - 1u) / kTime, tt = (_gIdx - 1u) % kTime;
			_ptA.StoreAct(cx, tt, ids, mag, _norm);
			_pending = false;
		}
		if (_gIdx == 0u)
		{
			Array<float> fr, tg; fr.Reset(0); tg.Reset(0);
			ImageFormat::Bitmap bmp; Bytes packed;
			for (uint32 g = 0; g < kGroup; ++g)
			{
				const uint32 ctx = _gGrp * kGroup + g;
				MLTWorld w; w.Reset(_seed, kPtEpi + ctx, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
				for (uint32 t = 0; t < kTime; ++t)
				{
					w.Step();
					if (!w.Render(bmp) || !MLTWorld::Pack(bmp, nullptr, packed)) { _Fail("Render/Pack(문맥)"); return; }
					MLTP2Enc::AppendFrame(fr, tg, (const uint8*)packed.GetData());
					_ptA.StoreState(ctx, t, w.State());

					// ⭐ **후보 넷을 매 시각 잰다** — ⚠️ `VisibleShapes` 는 **판정 창구**다.
					MLTShapeView vs[MLTWorldCfg::kShapes];
					const int nv = w.VisibleShapes(vs, MLTWorldCfg::kShapes);
					const float SS = (float)MLTWorldCfg::kSide;
					float nOn = 0.0f, minEdge = SS, maxR = 0.0f, minD = kNoShape;
					for (int i = 0; i < nv; ++i)
					{
						if (!(vs[i].sx >= 0.0f && vs[i].sx < SS && vs[i].sy >= 0.0f && vs[i].sy < SS)) continue;
						nOn += 1.0f;
						const float e0 = vs[i].sx, e1 = SS - 1.0f - vs[i].sx;
						const float e2 = vs[i].sy, e3 = SS - 1.0f - vs[i].sy;
						float e = e0; if (e1 < e) e = e1; if (e2 < e) e = e2; if (e3 < e) e = e3;
						if (e < minEdge) minEdge = e;
						if (vs[i].r > maxR) maxR = vs[i].r;
						if (vs[i].d < minD) minD = vs[i].d;
					}
					// ⭐ 회차 156 — **경계에 걸친 도형 수**(`e < r`)를 같이 센다.
					//   ★ ***임의 상수가 없다*** — 가장자리까지 거리가 **자기 반지름**보다 작으면
					//     그 도형은 **지금 잘려 있다** ⇒ *"몇 개가 곧 바뀌나"* 를 직접 말한다.
					float nClip = 0.0f;
					for (int i = 0; i < nv; ++i)
					{
						if (!(vs[i].sx >= 0.0f && vs[i].sx < SS && vs[i].sy >= 0.0f && vs[i].sy < SS)) continue;
						const float f0 = vs[i].sx, f1 = SS - 1.0f - vs[i].sx;
						const float f2 = vs[i].sy, f3 = SS - 1.0f - vs[i].sy;
						float fe = f0; if (f1 < fe) fe = f1; if (f2 < fe) fe = f2; if (f3 < fe) fe = f3;
						if (fe < vs[i].r) nClip += 1.0f;
					}
					_raw[0].Add(minEdge);   // ㈠ 이진 · ㈤ 8분위가 **같은 양**을 쓴다
					_raw[1].Add(nClip);     // ㈡ 경계걸침 개수
					_raw[2].Add(maxR);      // ㈢ 조합의 둘째 축
					_raw[3].Add(nOn);       // ㈣ 변화방향의 원료
					(void)minD;
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
		if (++_gGrp * kGroup < kPtCtx) return;
		_gGrp = 0u;
		_MakeWords();
		_st = kMeasure;
	}

	// ── 낱말 만들기 ────────────────────────────────────────────────
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

	// ⭐ ㈤ — 회차 141 의 낱말(그 시각에 「바뀌는」 첫 슬롯의 표적 id 8분위 +1 · 0 = 변화 없음)
	static void _ChangeWord(Array<uint32>& w)
	{
		w.Reset(0);
		for (uint32 ctx = 0; ctx < kPtCtx; ++ctx)
			for (uint32 t = 0; t < kTime; ++t)
			{
				const uint32 b = MLTP3Ctx::Row(ctx, t, kStateAx);
				uint32 cls = 0u;
				for (uint32 j = 0; j < kSlots; ++j)
				{
					const float tf = _ptA.Tgt()[b + j];
					if (!(tf >= 0.0f && tf < (float)kN)) continue;
					const uint32 tid = (uint32)tf;
					if ((uint32)(_ptA.Sym()[b + j] - (float)kStateAx) == tid) continue;
					cls = 1u + (tid * (kRefCls - 1u)) / kN;
					break;
				}
				w.Add(cls);
			}
	}

	// ⭐ 회차 156 — 후보마다 **다른 방식**으로 낱말을 만든다.
	//   ⚠️ 전부 **과거·현재만** 쓴다(새는 말 금지 — 142 의 그 규칙).
	static void _MakeWords()
	{
		// ㈠ `minEdge` **이진**(가까운 절반 / 먼 절반) — ★ ㈤ 와 **같은 양**이고 계급만 다르다
		_RankClassK(_raw[0].Data(), kWords, 2u, _w[0]);
		// ㈡ **경계에 걸친 도형 수** — 0 · 1 · 2+ (⭐ 임의 상수가 없다)
		_w[1].Reset(0);
		for (uint32 i = 0; i < kWords; ++i)
		{
			const uint32 n = (uint32)(_raw[1][i] + 0.5f);
			_w[1].Add((n >= 2u) ? 2u : n);
		}
		// ㈢ `minEdge`(2) × `maxR`(2) **조합** = 4계급
		{
			Array<uint32> a, b;
			_RankClassK(_raw[0].Data(), kWords, 2u, a);
			_RankClassK(_raw[2].Data(), kWords, 2u, b);
			_w[2].Reset(0);
			for (uint32 i = 0; i < kWords; ++i) _w[2].Add(a[i] * 2u + b[i]);
		}
		// ㈣ `nOn` **변화 방향**(늘 · 줄 · 같) — ⚠️ **과거만** 쓴다(`t=0` 은 「같다」로)
		_w[3].Reset(0);
		for (uint32 i = 0; i < kWords; ++i)
		{
			const uint32 t = i % kTime;
			if (t == 0u) { _w[3].Add(2u); continue; }
			const float d = _raw[3][i] - _raw[3][i - 1u];
			_w[3].Add((d > 0.5f) ? 0u : ((d < -0.5f) ? 1u : 2u));
		}
		// ㈤ **142 재현 대조** — 같은 `minEdge` 를 **8분위**로
		_RankClassK(_raw[0].Data(), kWords, 8u, _w[4]);
		// ㈥ 눈금
		_ChangeWord(_w[5]);
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

	// `Î(w;y)` — ⚠️ **변화 표적만** 센다(141 의 자가 채점하는 자리).
	static double _MI(const Array<uint32>& word, uint32 nc, uint32& outN)
	{
		Array<uint32> joint; joint.Reset(0);
		for (uint32 i = 0; i < nc * kN; ++i) joint.Add(0u);
		Array<uint32> wCnt; wCnt.Reset(0);
		for (uint32 i = 0; i < nc; ++i) wCnt.Add(0u);
		Array<uint32> yCnt; yCnt.Reset(0);
		for (uint32 i = 0; i < kN; ++i) yCnt.Add(0u);
		uint32 nT = 0u;
		for (uint32 ctx = 0; ctx < kPtCtx; ++ctx)
			for (uint32 t = 0; t < kTime; ++t)
			{
				const uint32 c = word[ctx * kTime + t] % nc;
				const uint32 b = MLTP3Ctx::Row(ctx, t, kStateAx);
				for (uint32 j = 0; j < kSlots; ++j)
				{
					const float tf = _ptA.Tgt()[b + j];
					if (!(tf >= 0.0f && tf < (float)kN)) continue;
					const uint32 tid = (uint32)tf;
					if ((uint32)(_ptA.Sym()[b + j] - (float)kStateAx) == tid) continue;   // ⭐ 변화 표적만
					++joint.Data()[c * kN + tid]; ++wCnt.Data()[c]; ++yCnt.Data()[tid]; ++nT;
				}
			}
		outN = nT;
		if (nT == 0u) return 0.0;
		const double hY = _Entropy(yCnt, nT);
		_hYlast = hY;      // ⭐ 해석의 눈금 — 「낱말이 표적 엔트로피의 몇 %를 가르나」
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
			hYgW += ((double)nw / (double)nT) * e;
		}
		return hY - hYgW;
	}

	static void _Measure()
	{
		uint32 nT = 0u;
		for (uint32 c = 0; c < kCands; ++c)
		{
			const uint32 nc = (c == kRawCands) ? kRefCls : kClsOf[c];
			Array<uint32> h; h.Reset(0);
			for (uint32 i = 0; i < nc; ++i) h.Add(0u);
			for (uint32 i = 0; i < _w[c].Count(); ++i) ++h.Data()[_w[c][i] % nc];
			_hW[c][_seed] = _Entropy(h, _w[c].Count());
			_mi[c][_seed] = _MI(_w[c], nc, nT);
			Array<uint32> sh; _Shuffle(_w[c], sh, 700u + c);
			uint32 dummy = 0u;
			_miS[c][_seed] = _MI(sh, nc, dummy);
			if (_mi[c][_seed] - _miS[c][_seed] > 0.0) ++_pos[c];
		}
		_nCh[_seed] = (double)nT / (double)kPtCtx;
		_hY[_seed] = _hYlast;
		LogA("[mlt] 🔍 씨앗 %2u · 변화 표적 **%.1f/문맥**(총 %u) · **H(변화표적) %.4f** 나트\n",
			_seed, _nCh[_seed], nT, _hY[_seed]);
		for (uint32 c = 0; c < kCands; ++c)
			LogA("[mlt] 🔍   %s H %.4f · Î %.5f · Î섞음 %.5f · **차 %+.5f**\n",
				_Name(c), _hW[c][_seed], _mi[c][_seed], _miS[c][_seed], _mi[c][_seed] - _miS[c][_seed]);
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
		double gap[kCands], gsd[kCands], hm[kCands], hsd;
		for (uint32 c = 0; c < kCands; ++c)
		{
			double d[kSeedsMax];
			for (uint32 s = 0; s < _seeds; ++s) d[s] = _mi[c][s] - _miS[c][s];
			_MeanSd(d, gap[c], gsd[c]);
			_MeanSd(_hW[c], hm[c], hsd);
		}
		double nm, nsd; _MeanSd(_nCh, nm, nsd);
		double hym, hysd; _MeanSd(_hY, hym, hysd);
		const uint32 pass = (_seeds * 10u + 11u) / 12u;
		const double ref = gap[kRawCands];   // ⚠️ 회차 156 — 눈금은 **㈥**(색인 kRawCands)이다

		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🧩 **회차 156 · 조합과 이진이 표적을 가르나** (씨앗 %u · 학습 0 · 유한 %s)\n", _seeds, _ok ? "✅" : "⛔");
		LogA("[mlt] 🔍   변화 표적 **%.1f/문맥**(±%.1f) — 회차 141 은 14.0 이었다\n", nm, nsd);
		LogA("[mlt] 🔍   ⭐ **`H(변화 표적)` = %.4f 나트** — 낱말이 가를 수 있는 전부다(균등바닥 `ln250` = 5.52)\n", hym);
		LogA("[mlt] 🔍   ── 후보 표 ── (⭐ **표적몫** = `(Î−Î섞음) / H(변화표적)`)\n");
		LogA("[mlt] 🔍     낱말                 │ H      · **Î−Î섞음**(±sd)      · 표적몫 · **눈금대비** · 부호\n");
		for (uint32 c = 0; c < kCands; ++c)
			LogA("[mlt] 🔍     %s │ %.4f · **%+.5f**(±%.5f) · %.4f · **%+.3f** · %u/%u\n",
				_Name(c), hm[c], gap[c], gsd[c],
				(hym > 1.0e-9) ? gap[c] / hym : 0.0,
				(Abs((float)ref) > 1.0e-12) ? gap[c] / ref : 0.0,
				_pos[c], _seeds);

		// ── 관문 ────────────────────────────────────────────────────
		const bool gRef = (_pos[kRawCands] >= _seeds) && (ref > 0.0);
		LogA("[mlt] 🔍   ── 관문 ──\n");
		LogA("[mlt] 🔍     ⭐ **눈금**(㈥ 가 살아야) — %u/%u · 차 %+.5f → %s\n",
			_pos[kRawCands], _seeds, ref, gRef ? "✅" : "⛔ **눈금이 죽었다 = 판정불가**");
		uint32 nPass = 0u;
		for (uint32 c = 0; c < kRawCands; ++c)
		{
			const double rel = (Abs((float)ref) > 1.0e-12) ? gap[c] / ref : 0.0;
			const bool okc = (_pos[c] >= pass) && (rel >= 0.10);
			if (okc) ++nPass;
			LogA("[mlt] 🔍     %s 부호 %u/%u≥%u · 눈금대비 %+.3f≥0.10 → %s\n",
				_Name(c), _pos[c], _seeds, pass, rel, okc ? "✅ **통과**" : "⛔");
		}

		// ── 판정 ────────────────────────────────────────────────────
		if (!_ok)                LogA("[mlt] 🔍   ⭐ 판정 = ⛔ **판정불가** — 배관이 안 섰다\n");
		else if (_seeds == 1u)   LogA("[mlt] 🔍   ⭐ **1씨앗 진단이다 — 판정하지 않는다**(규율 51)\n");
		else if (!gRef)          LogA("[mlt] 🔍   ⭐ 판정 = ⛔ **판정불가** — ***눈금(양성 참조)이 안 선다***\n");
		else if (nPass > 0u)
			LogA("[mlt] 🔍   ⭐ 판정 = ⭐ ***거르기를 통과한 후보가 %u 개다*** — 그것으로 `mltl1d0` 를 돌린다\n", nPass);
		else
			LogA("[mlt] 🔍   ⭐ 판정 = ⛔ **넷 다 바닥이다** ⇒ ⚠️⚠️ *\"이 세계의 판정 창구가 변화를 안 가른다\"*\n"
			     "[mlt] 🔍      ⇒ ★ 다음은 낱말을 **세계가 아니라 「행동」**(`MLTAct`)에서 찾는 회차다\n");
		LogA("[mlt] 🔍   ⚠️ `Î` 는 **무조건부**다 — 이것은 **거르는 자**이고 판정은 `mltl1d0` 가 한다\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		_E.Destroy(); _done = true;
	}

	static void _Fail(const char* why)
	{
		LogA("[mlt] 🔍 ⛔ %s (씨앗 %u · 단계 %u · 걸음 %u · 그룹 %u)\n", why, _seed, _st, _step, _gGrp);
		_ok = false; _E.Destroy(); _done = true;
	}

	CW_BODY(MLTL1M0)
};
