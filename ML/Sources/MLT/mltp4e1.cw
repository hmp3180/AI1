// mltp4e1.cw — 🐛 회차 109 · **갈림이 태어나는 자리를 스텝으로 좁힌다** (`-mltp4e1`) ⚠️ **진단 회차**
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 109 이다.** ⭐ **하네스보다 먼저 썼다.**
//
// ── ⭐ 회차 108 이 세운 것 ────────────────────────────────────────────────
//   · 코퍼스 **결정적**(복사바닥 1.1162 가 세 실행에서 동일)
//   · ⭐ **평가 완전 결백** — 파라미터 고정 8회 반복에서 CE 폭이 **정확히 0.000000**
//   · ⭐ **학습 경로다** — 반복 0·1 은 비트 동일, **2~7 은 830,848/859,136 어긋남**
//   ⇒ ⚠️ 회차 54 의 `R=2` *"비트 동일"* 은 **갈리기 직전에서 멈춘 것**이었다(그 위에 50회차가 얹혔다).
//
// ── 🔬 이 회차 — 회차 54 와 **같은 설계, 다른 것 둘** ────────────────────────
//   ㈀ ⭐ **`S = 0` 을 넣는다**(학습 0스텝 = `Setup` + 파라미터 업로드만)
//   ㈁ **반복 `R = 4`**(회차 54 는 2였고 그 2회가 정확히 「운 좋은 두 회」였다)
//
//   | `S` | 무엇을 가르나 |
//   |---|---|
//   | ⭐ **0** | 여기서 갈리면 **학습 커널이 무죄**이고 범인은 **배관**(버퍼 파기/재생성·스테이징 쓰기) |
//   | 1·10·100 | 회차 53 이 *"1·100 은 폭 0"* 을 본 자리 — **재현되나** |
//   | 400·800 | 회차 53 이 *"여기서 생긴다"* 를 본 자리 |
//
// ── ✅ 관문 — 뜻을 미리 못박았다 ──────────────────────────────────────────
//   | **`S=0` 에서 갈린다** | ⭐ **배관이다** ⇒ 다음 = 파기/재생성·스테이징 쓰기의 **동기화** |
//   | `S=0` 같고 **`S=1` 부터** | ⭐ **커널 한 스텝 안** ⇒ 다음 = `Backward` 의 **축약 순서** |
//   | 큰 `S` 에서만          | ⭐ **누적**이다 ⇒ 회차 53 의 그림 재현 |
//   | 아무 데서도 안 갈림    | ⚠️ **판정불가** ⇒ 팔 사이의 차이(평가를 끼우나)를 다음에 가른다 |
//   **배관 관문**: 복사바닥 **1.1162** 재현.
//
// ── ⭐ 예측 ──────────────────────────────────────────────────────────────
//   ⚠️ 진짜 모른다. ***`S=0` 을 가장 유력하게 본다***(회차 108 의 무늬가 **학습량과 무관한 무엇**을
//   가리킨다). ⚠️ 회차 106·107·108 에서 내 예측이 **둘 틀리고 하나 맞았다.**
//
// ⚠️ 코퍼스 만들기는 회차 108 과 **한 글자도 다르지 않다**(그래야 바닥 눈금이 관문으로 선다).

using namespace PE;

class MLTP4E1
{
public:
	static void Tick(RHI* rhi)
	{
		if (_done || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltp4e1"))
		{
			LogA("[mlt] 🐛 회차 109(갈림이 태어나는 스텝)는 **꺼져 있다**(`-mltp4e1`)\n");
			_done = true; return;
		}
		if (!_banner) { _Banner(); _banner = true; }
		if (_st == kEncInit)  { _EncBegin(rhi); return; }
		if (_st == kEncTrain) { _EncTrain(); return; }
		if (_st == kGather)   { _Gather(); return; }
		if (_st == kQuiesce)
		{
			if (_qWait > 0u) { --_qWait; return; }
			_st = kRunInit; return;
		}
		if (_st == kRunInit) { _RunBegin(rhi); return; }
		if (_st == kRun)     { _Run(); return; }
		_Summary();
	}

	static bool Done() { return _done; }

private:
	static constexpr uint32 kSeed = 0u;
	static constexpr uint32 kEncF = 32u, kEncSteps = 1200u, kEncPerTick = 8u;
	static constexpr uint32 kN = 250u, kLocal = 8u;
	static constexpr uint32 kTime = MLTP4Ctx::kTime;
	static constexpr uint32 kBatch = MLTP4Ctx::kBatch;
	static constexpr uint32 kCandidates = MLTP2Cfg::kPatches * kLocal;
	static constexpr uint32 kNCtx = 512u, kTestCtx = 512u;
	static constexpr uint32 kTrainEpi = 1u, kTestEpi = 901u;
	static_assert(kTestEpi >= kTrainEpi + kNCtx, "시험 에피소드가 학습과 겹친다(회차 81)");
	static constexpr uint32 kPoolSteps = kNCtx / kBatch, kTestPool = kTestCtx / kBatch;
	static constexpr uint32 kGroup = kEncF / kTime;
	static constexpr uint32 kPerTick = 4u;
	static constexpr uint32 kNone = MLTP4Ctx::kStateAx + MLTP4Ctx::kActAx + kN;
	static constexpr uint32 kSymVocab = kNone + 1u;
	static constexpr float  kFloorRef = 1.1162f;

	// ⭐ 스텝 점 여섯 — **`0` 이 이 회차가 더한 것**이다.
	static constexpr uint32 kLens = 6u;
	static constexpr uint32 kLen[kLens] = { 0u, 1u, 10u, 100u, 400u, 800u };
	static constexpr uint32 kRep = 4u;    // ⚠️ 회차 54 는 2였다

	enum { kEncInit, kEncTrain, kGather, kQuiesce, kRunInit, kRun, kEnd };

	inline static MLTP2Enc _E;
	inline static MLTModel _M;
	inline static MLTP4Ctx _tr, _te;
	inline static bool _done = false, _banner = false, _encSetup = false;
	inline static uint32 _st = kEncInit, _qWait = 0u;
	inline static uint32 _step = 0u, _cor = 0u, _gGrp = 0u, _gIdx = 0u;
	inline static bool _pending = false;
	inline static Array<float> _code, _norm, _p0;
	inline static float _floorTe = 0.0f;
	inline static uint32 _len = 0u, _rep = 0u;
	inline static uint32 _diff[kLens][kRep];       // 첫 반복과 어긋난 칸 수
	inline static float  _mx[kLens][kRep];         // 최대 절대차

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🐛 **회차 109 · 갈림이 태어나는 자리를 스텝으로 좁힌다**(⚠️ 진단 · 씨앗 %u 하나)\n", kSeed);
		LogA("[mlt] 🐛   ⭐ 회차 108 이 세운 것 — 코퍼스 결정적 · **평가 폭 0.000000** · ⇒ **학습 경로**\n");
		LogA("[mlt] 🐛     ⚠️ 회차 54 의 `R=2` *\"비트 동일\"* 은 **갈리기 직전에서 멈춘 것**이었다(반복 0·1 은 실제로 같다)\n");
		LogA("[mlt] 🐛   🔬 `S ∈ {0,1,10,100,400,800}` × 반복 %u — ⭐ **`S=0`(학습 0스텝)이 이 회차가 더한 것**\n", kRep);
		LogA("[mlt] 🐛     ⭐ **`S=0` 에서 갈리면 학습 커널은 무죄이고 범인은 배관이다**(파기/재생성·스테이징 쓰기)\n");
		LogA("[mlt] 🐛   ⚠️ 배관 관문 — 복사바닥이 **%.4f** 와 같아야 한다\n", (double)kFloorRef);
		LogA("[mlt] 🐛   ⭐ **예측** — ⚠️ 진짜 모른다. **`S=0` 을 가장 유력**하게 본다(무늬가 학습량과 무관한 무엇을 가리킨다)\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

	static void _EncBegin(RHI* rhi)
	{
		if (!_encSetup)
		{
			if (!_E.Setup(rhi, kEncF, kN)) { _Fail("인코더 준비"); return; }
			_encSetup = true;
		}
		_E.SetK(kLocal); _E.SetSelectAbs(false);
		Array<float> fr, tg; fr.Reset(0); tg.Reset(0);
		ImageFormat::Bitmap bmp; Bytes packed;
		MLTWorld w; w.Reset(kSeed, 0u, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
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
		MLTP4Ctx& C = (_cor == 0u) ? _tr : _te;
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
				MLTWorld w; w.Reset(kSeed, epi + ctx, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
				for (uint32 t = 0; t < kTime; ++t)
				{
					if (!w.Render(bmp) || !MLTWorld::Pack(bmp, nullptr, packed))
					{ _Fail("Render/Pack(문맥)"); return; }
					MLTP2Enc::AppendFrame(fr, tg, (const uint8*)packed.GetData());
					C.StoreState(ctx, t, w.State());
					const MLTAct a = w.ActAt(w.StepNo());
					C.StoreAct5(ctx, t, a);
					w.StepWith(a);
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
		_gIdx = 0;
		if (++_gGrp * kGroup >= nCtx)
		{
			_gGrp = 0u;
			if (++_cor >= 2u)
			{
				Array<float> marg; _tr.Marginal(marg);
				float c1 = 0.0f, c2 = 0.0f, l1 = 0.0f, l2 = 0.0f;
				_tr.BestCopy(marg, c1, c2, l1, l2, MLTP4Ctx::kAllT1);
				const float t1 = (float)_te.CeCopy(marg, l1, false, MLTP4Ctx::kAllT1);
				const float t2 = (float)_te.CeCopy(marg, l2, true, MLTP4Ctx::kAllT1);
				_floorTe = (t1 < t2) ? t1 : t2;
				LogA("[mlt] 🐛 ⚠️ **배관 관문** — 시험 복사바닥 **%.4f**(눈금 %.4f) → %s\n",
					(double)_floorTe, (double)kFloorRef,
					(Abs(_floorTe - kFloorRef) <= 0.0001f) ? "✅ 코퍼스 동일" : "⛔ 코퍼스가 다르다");
				_len = 0u; _rep = 0u; _qWait = MLTEvalGate::kDelay; _st = kQuiesce;
			}
		}
	}

	static void _RunBegin(RHI* rhi)
	{
		if (!_M.Setup(rhi, kSymVocab, kN, MLTP4Ctx::kAxes, kTime)) { _Fail("몸통 준비"); return; }
		if (!_M.UploadPool(_tr.Val(), _tr.Tgt(), kPoolSteps) || !_M.UploadSymbolPool(_tr.Sym(), kPoolSteps))
		{ _Fail("학습 풀 업로드"); return; }
		_step = 0u; _st = kRun;
	}

	static void _Run()
	{
		const uint32 S = kLen[_len];
		if (_step < S)
		{
			for (uint32 i = 0; i < kPerTick && _step < S; ++i)
			{
				_M.SelectStep(_step % kPoolSteps);
				if (!_M.Forward() || !_M.Backward() || !_M.AdamStep(1.0f)) { _Fail("몸통 스텝"); return; }
				++_step;
			}
			return;
		}
		Array<float> p;
		if (!_ReadParams(p)) { _Fail("파라미터 리드백"); return; }
		if (_rep == 0u)
		{
			_p0.Reset(0);
			for (uint32 i = 0; i < p.Count(); ++i) _p0.Add(p[i]);
			_diff[_len][0] = 0u; _mx[_len][0] = 0.0f;
		}
		else
		{
			uint32 d = 0u; float mx = 0.0f;
			for (uint32 i = 0; i < p.Count(); ++i)
			{
				if (!(p[i] == _p0[i])) ++d;
				const float e = Abs(p[i] - _p0[i]);
				if (e > mx) mx = e;
			}
			_diff[_len][_rep] = d; _mx[_len][_rep] = mx;
		}
		LogA("[mlt] 🐛   S=%3u · 반복 %u — 파라미터 %u개 중 **어긋남 %u** · 최대차 %.3e%s\n",
			S, _rep, p.Count(), _diff[_len][_rep], (double)_mx[_len][_rep],
			(_diff[_len][_rep] == 0u) ? "  ⇒ 비트 동일" : "  ⚠️");
		if (++_rep < kRep) { _qWait = MLTEvalGate::kDelay; _st = kQuiesce; return; }
		_rep = 0u;
		if (++_len < kLens) { _qWait = MLTEvalGate::kDelay; _st = kQuiesce; return; }
		_st = kEnd;
	}

	static bool _ReadParams(Array<float>& out)
	{
		MLTensor t; t.offset = 0u; t.rows = 1u; t.cols = _M.ParamTotal();
		Bytes b;
		if (!_M.Arena().Read(t, b)) return false;
		if (b.GetSize() < (uint64)t.cols * sizeof(float)) return false;
		const float* p = (const float*)b.GetData();
		out.Reset(0);
		for (uint32 i = 0; i < t.cols; ++i) out.Add(p[i]);
		return true;
	}

	static void _Summary()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🐛 **회차 109 · 갈림이 태어나는 자리 결과**(씨앗 %u · 반복 %u · 문맥 %u)\n", kSeed, kRep, kNCtx);
		LogA("[mlt] 🐛   배관 — 시험 복사바닥 **%.4f**(눈금 %.4f) → %s\n",
			(double)_floorTe, (double)kFloorRef,
			(Abs(_floorTe - kFloorRef) <= 0.0001f) ? "✅" : "⛔ 이 회차의 진단은 무효다");
		uint32 firstBad = kLens;
		for (uint32 l = 0; l < kLens; ++l)
		{
			uint32 bad = 0u; float mx = 0.0f;
			for (uint32 r = 1; r < kRep; ++r)
			{ if (_diff[l][r] != 0u) ++bad; if (_mx[l][r] > mx) mx = _mx[l][r]; }
			LogA("[mlt] 🐛   S=%3u — 첫 회와 다른 반복 **%u/%u** · 최대차 %.3e%s\n",
				kLen[l], bad, kRep - 1u, (double)mx, (bad == 0u) ? "  ⇒ 비트 동일" : "  ⚠️");
			if (bad != 0u && firstBad == kLens) firstBad = l;
		}
		if (firstBad == kLens)
			LogA("[mlt] 🐛   ⭐ 판정 = ⚠️ **판정불가** — 어느 `S` 에서도 안 갈린다 ⇒ 다음은 **팔 사이의 차이**(평가를 끼우나)를 가른다\n");
		else if (kLen[firstBad] == 0u)
			LogA("[mlt] 🐛   ⭐ 판정 = ⭐ **배관이다** — 학습을 **0스텝** 해도 갈린다 ⇒ 학습 커널 무죄.\n"
			     "[mlt] 🐛      다음 = 버퍼 **파기/재생성**과 스테이징 쓰기의 **동기화**(`MLArena::Create` 의 `Destroy`+`MemZero`)\n");
		else if (kLen[firstBad] == 1u)
			LogA("[mlt] 🐛   ⭐ 판정 = ⭐ **커널 한 스텝 안이다** ⇒ 다음 = `Backward` 의 **축약 순서**(원자 덧셈)\n");
		else
			LogA("[mlt] 🐛   ⭐ 판정 = ⭐ **누적이다**(S=%u 부터) — 한 스텝의 미세차가 자란다 ⇒ 회차 53 의 그림 재현\n",
				kLen[firstBad]);
		LogA("[mlt] 🐛   ⚠️ 씨앗 하나의 진단이다 — 성능/판정 숫자로 인용하지 않는다\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		_E.Destroy(); _done = true;
	}

	static void _Fail(const char* why)
	{
		LogA("[mlt] 🐛 ⛔ %s (단계 %u · S=%u · 반복 %u)\n", why, _st, kLen[_len], _rep);
		_E.Destroy(); _done = true;
	}
};
