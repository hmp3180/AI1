// mltp3d0.cw — 🐛 회차 53 · **몸통 GPU 경로의 재현 폭** (`-mltp3d0`)
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 53 이다.**
// ⚠️ **판정 라운드가 아니라 진단 회차**다 — 세계·표현·학습에 대해 **아무 말도 하지 않는다.**
// ══════════════════════════════════════════════════════════════════════════════
//
// ★ **왜 여나** — 회차 52 가 같은 조건에서 **0.6989 / 0.6832 / 0.6794** 를 냈다.
//   그런데 ㉠(상태 개입)의 효과는 회차 50 에서 **`+0.0094`·`−0.0223`** 이었다 ⇒ **잡음과 같은 자리**다.
//   *"문턱이 잡음보다 큰지 먼저 계산한다"* 규율상 **㉠ 을 다시 재기 전에 이것이 먼저**다.
//
// ── 사다리 넷 — ⭐ 자리를 좁힌다 ────────────────────────────────────────────
//   **A 코퍼스**   같은 씨앗으로 2회 조립 → `val`·`tgt`·`sym` **비트 비교**
//   **B forward**  학습 0 · 같은 풀 칸을 16회 forward → 손실 **비트 비교**
//   **B′ 리드백**  같은 틱에 읽기 ↔ 다음 틱에 읽기 — ⭐ 다르면 원인이 **배리어가 아니라 동기**다
//   **C 학습 폭**  `Setup → S스텝 → 평가` × 8회 · `S ∈ {1,100,800,3200}` · 각 `S` 의 **최대−최소 폭**
//
//   ⭐ B 가 흔들리면 forward/리드백 · B 는 같은데 `C(1)` 이 흔들리면 backward/adam ·
//     `C(1)` 도 같은데 `C(3200)` 만 크면 **누적**이다.

using namespace PE;

class MLTP3D0
{
public:
	static void Tick(RHI* rhi)
	{
		if (_done || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltp3d0"))
		{
			LogA("[mlt] 🐛 회차 53은 **꺼져 있다**(`-mltp3d0`) — 몸통 GPU 경로의 재현 폭\n");
			_done = true; return;
		}
		if (!_banner) { _Banner(); _banner = true; }
		if (_st == kEncInit)  { _EncBegin(rhi); return; }
		if (_st == kEncTrain) { _EncTrain(); return; }
		if (_st == kGather)   { _Gather(); return; }
		if (_st == kFwdInit)  { _FwdBegin(rhi); return; }
		if (_st == kFwd)      { _Fwd(); return; }
		if (_st == kRunInit)  { _RunBegin(rhi); return; }
		if (_st == kRunTrain) { _RunTrain(); return; }
		if (_st == kRunEval)  { _RunEval(); return; }
		_Summary();
	}

	static bool Done() { return _done; }

private:
	static constexpr uint32 kSeed = 0u;
	static constexpr uint32 kEncF = 32u, kEncSteps = 1200u, kEncPerTick = 8u;
	static constexpr uint32 kN = 250u, kLocal = 8u;
	static constexpr uint32 kTime = MLTP3Ctx::kTime;
	static constexpr uint32 kBatch = MLTP3Ctx::kBatch;
	static constexpr uint32 kRows = MLTP3Ctx::kRows;
	static constexpr uint32 kCandidates = MLTP2Cfg::kPatches * kLocal;
	static constexpr uint32 kNCtx = 512u, kTrainEpi = 1u;
	static constexpr uint32 kPoolSteps = kNCtx / kBatch;      // 64
	static constexpr uint32 kGroup = kEncF / kTime;
	static constexpr uint32 kFwdRep = 16u;                    // 판정 B
	static constexpr uint32 kRep = 8u;                        // 판정 C 반복
	static constexpr uint32 kLens = 4u;
	static constexpr uint32 kLen[kLens] = { 1u, 100u, 800u, 3200u };
	static constexpr uint32 kPerTick = 4u;
	static constexpr float  kOpenGate = 0.005f;               // ㉠ 를 열 수 있는 폭

	enum { kEncInit, kEncTrain, kGather, kFwdInit, kFwd, kRunInit, kRunTrain, kRunEval, kDone2 };

	inline static MLTP2Enc _E;
	inline static MLTModel _M;
	inline static MLTP3Ctx _c0, _c1;                          // 판정 A — 두 벌을 따로 조립한다
	inline static bool _done = false, _banner = false, _pending = false;
	inline static uint32 _st = kEncInit, _step = 0u, _gGrp = 0u, _gIdx = 0u, _pass = 0u;
	inline static Array<float> _code, _norm;
	inline static uint32 _bitDiff = 0u;                       // A 의 어긋난 원소 수
	inline static float _fwdSame[kFwdRep], _fwdNext[kFwdRep]; // B / B′
	inline static uint32 _fwdI = 0u;
	inline static float _ce[kLens][kRep];
	inline static uint32 _li = 0u, _ri = 0u;
	inline static MLTEvalGate _gate;

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🐛 **회차 53 · 몸통 GPU 경로의 재현 폭**(⚠️ 판정 라운드가 아니라 **진단 회차**)\n");
		LogA("[mlt] 🐛   A 코퍼스 비트동일 · B forward 16회 비트동일 · B′ 리드백 시점 · C 학습 폭 8회\n");
		LogA("[mlt] 🐛   씨앗 %u 하나 · %u문맥 · 스텝 {1,100,800,3200} · 여는 문턱 W ≤ %.3f\n",
			kSeed, kNCtx, (double)kOpenGate);
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

	static void _EncBegin(RHI* rhi)
	{
		if (!_E.Setup(rhi, kEncF, kN)) { _Fail("인코더 준비"); return; }
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
		_c0.Begin(kNCtx, kN); _c1.Begin(kNCtx, kN);
		_pass = 0u; _gGrp = 0u; _gIdx = 0u; _pending = false; _st = kGather;
	}

	// 판정 A — **같은 조립을 두 벌** 한다(`_pass` 0 → `_c0`, 1 → `_c1`).
	static void _Gather()
	{
		MLTP3Ctx& C = (_pass == 0u) ? _c0 : _c1;
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
			for (uint32 g = 0; g < kGroup; ++g)
			{
				const uint32 ctx = _gGrp * kGroup + g;
				MLTWorld w; w.Reset(kSeed, kTrainEpi + ctx, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
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
		if (++_gGrp * kGroup >= kNCtx)
		{
			_gGrp = 0u;
			if (++_pass < 2u) return;              // 두 번째 벌
			_JudgeA();
		}
	}

	static void _JudgeA()
	{
		_bitDiff = 0u;
		const uint32 n = _c0.Val().Count();
		for (uint32 i = 0; i < n; ++i)
		{
			if (!(_c0.Val()[i] == _c1.Val()[i])) ++_bitDiff;
			if (!(_c0.Tgt()[i] == _c1.Tgt()[i])) ++_bitDiff;
			if (!(_c0.Sym()[i] == _c1.Sym()[i])) ++_bitDiff;
		}
		LogA("[mlt] 🐛 **판정 A 코퍼스** — 원소 %u×3 중 어긋남 **%u** → %s\n",
			n, _bitDiff, (_bitDiff == 0u) ? "**비트 동일**" : "⛔");
		_st = kFwdInit;
	}

	// 판정 B / B′ — 학습 0. 같은 풀 칸을 반복 forward 하고 **같은 틱**과 **다음 틱**에서 읽는다.
	static void _FwdBegin(RHI* rhi)
	{
		if (!_M.Setup(rhi, MLTP3Ctx::kStateAx + kN, kN, MLTP3Ctx::kAxes, kTime)) { _Fail("몸통 준비"); return; }
		if (!_M.UploadPool(_c0.Val(), _c0.Tgt(), kPoolSteps) || !_M.UploadSymbolPool(_c0.Sym(), kPoolSteps))
		{ _Fail("몸통 풀 업로드"); return; }
		_M.SelectStep(0u);
		_fwdI = 0u; _st = kFwd;
	}

	static void _Fwd()
	{
		if (_fwdI > 0u)
		{
			float ls = 0.0f;
			if (!_M.ReadLoss(ls)) { _Fail("다음 틱 손실 리드백"); return; }
			_fwdNext[_fwdI - 1u] = ls;              // B′ — **다음 틱**에 읽은 값
		}
		if (_fwdI < kFwdRep)
		{
			if (!_M.Forward()) { _Fail("forward"); return; }
			float ls = 0.0f;
			if (!_M.ReadLoss(ls)) { _Fail("같은 틱 손실 리드백"); return; }
			_fwdSame[_fwdI] = ls;                   // B — **같은 틱**에 읽은 값
			++_fwdI; return;
		}
		_JudgeB();
	}

	static void _JudgeB()
	{
		uint32 dSame = 0u, dNext = 0u, dCross = 0u;
		for (uint32 i = 1; i < kFwdRep; ++i)
		{
			if (!(_fwdSame[i] == _fwdSame[0])) ++dSame;
			if (!(_fwdNext[i] == _fwdNext[0])) ++dNext;
		}
		for (uint32 i = 0; i < kFwdRep; ++i) if (!(_fwdSame[i] == _fwdNext[i])) ++dCross;
		LogA("[mlt] 🐛 **판정 B forward** — 같은틱 %u회 중 어긋남 **%u** · 다음틱 어긋남 **%u**\n",
			kFwdRep, dSame, dNext);
		LogA("[mlt] 🐛 **판정 B′ 리드백** — 같은틱↔다음틱 어긋남 **%u/%u** · 첫 값 %.8f ↔ %.8f\n",
			dCross, kFwdRep, (double)_fwdSame[0], (double)_fwdNext[0]);
		_bDiffSame = dSame; _bDiffNext = dNext; _bDiffCross = dCross;
		_li = 0u; _ri = 0u; _st = kRunInit;
	}
	inline static uint32 _bDiffSame = 0u, _bDiffNext = 0u, _bDiffCross = 0u;

	// 판정 C — `Setup → S스텝 → 평가` 를 반복한다.
	static void _RunBegin(RHI* rhi)
	{
		if (!_M.Setup(rhi, MLTP3Ctx::kStateAx + kN, kN, MLTP3Ctx::kAxes, kTime)) { _Fail("몸통 재준비"); return; }
		if (!_M.UploadPool(_c0.Val(), _c0.Tgt(), kPoolSteps) || !_M.UploadSymbolPool(_c0.Sym(), kPoolSteps))
		{ _Fail("몸통 풀 재업로드"); return; }
		_step = 0u; _st = kRunTrain;
	}

	static void _RunTrain()
	{
		if (_step >= kLen[_li]) { _gate.Begin(kPoolSteps); _st = kRunEval; return; }
		for (uint32 i = 0; i < kPerTick && _step < kLen[_li]; ++i)
		{
			_M.SelectStep(_step % kPoolSteps);
			if (!_M.Forward() || !_M.Backward() || !_M.AdamStep(1.0f)) { _Fail("몸통 스텝"); return; }
			++_step;
		}
	}

	// ⚠️ 평가는 **풀 전체 평균**(회차 50 이 등록한 그 자)이다.
	//   ⭐ **2026-08-26 배관 고침** — 평가 리드백을 `MLTEvalGate` 로 옮겼다(디스패치 → `kDelay` 틱
	//     대기 → 읽기). 이 회차의 원래 실측(폭 `0.017`/`0.047`)은 **한 틱만 기다렸을 때**의 값이고,
	//     회차 54 가 **파라미터는 비트 동일**임을 보였으므로 그 폭은 **리드백 경합**이었다.
	//     ⇒ 고친 뒤 이 회차를 그대로 다시 돌려 **폭이 0 이 되는지**가 그 고침의 관문이다.
	static void _RunEval()
	{
		bool fail = false;
		if (!_gate.Step(_M, fail)) return;
		if (fail) { _Fail("평가 리드백 게이트"); return; }
		_ce[_li][_ri] = _gate.Mean();
		if (++_ri >= kRep)
		{
			float lo = _ce[_li][0], hi = _ce[_li][0]; double s = 0.0;
			for (uint32 r = 0; r < kRep; ++r)
			{ const float v = _ce[_li][r]; if (v < lo) lo = v; if (v > hi) hi = v; s += (double)v; }
			LogA("[mlt] 🐛 **판정 C** — %4u스텝 × %u회 — 평균 **%.5f** · 최소 %.5f · 최대 %.5f · **폭 %.5f**\n",
				kLen[_li], kRep, s / (double)kRep, (double)lo, (double)hi, (double)(hi - lo));
			_ri = 0u;
			if (++_li >= kLens) { _st = kDone2; return; }
		}
		_st = kRunInit;
	}

	static void _Summary()
	{
		float w[kLens];
		for (uint32 l = 0; l < kLens; ++l)
		{
			float lo = _ce[l][0], hi = _ce[l][0];
			for (uint32 r = 0; r < kRep; ++r) { const float v = _ce[l][r]; if (v < lo) lo = v; if (v > hi) hi = v; }
			w[l] = hi - lo;
		}
		const bool aOk = (_bitDiff == 0u);
		const bool bOk = (_bDiffSame == 0u && _bDiffNext == 0u);
		const bool sync = (_bDiffCross != 0u);
		const bool c1Ok = (w[0] == 0.0f);
		const bool open = aOk && bOk && (w[kLens - 1u] <= kOpenGate);

		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🐛 **회차 53 · 재현 폭 결과**\n");
		LogA("[mlt] 🐛   A 코퍼스 비트동일 → %s · B forward 비트동일 → %s · B′ 리드백 시점차 → %s\n",
			aOk ? "✅" : "⛔", bOk ? "✅" : "⛔", sync ? "⚠️ **있다**" : "없다");
		for (uint32 l = 0; l < kLens; ++l)
			LogA("[mlt] 🐛   C %4u스텝 폭 **%.5f**%s\n", kLen[l], (double)w[l], (l == 0u && !c1Ok) ? "  ⇐ 1스텝에서 이미 갈린다" : "");
		if (!aOk)
			LogA("[mlt] 🐛   ⭐ 판정 = ⛔⛔ **조립이 비결정** — 여기서 멈춘다(회차 46 이후 전부가 흔들린다)\n");
		else if (sync)
			LogA("[mlt] 🐛   ⭐ 판정 = ⚠️ **원인은 리드백 동기다**(같은틱↔다음틱이 다르다) — 배리어보다 먼저 이것을 고친다\n");
		else if (!bOk)
			LogA("[mlt] 🐛   ⭐ 판정 = ⛔ **forward 가 비결정** — 회차 54 를 안 연다. 배리어를 고친다\n");
		else if (!c1Ok)
			LogA("[mlt] 🐛   ⭐ 판정 = ⛔ **backward/adam 이 비결정**(1스텝에서 갈린다) — 회차 54 를 안 연다\n");
		else if (open)
			LogA("[mlt] 🐛   ⭐ 판정 = ✅ **누적형이고 폭 %.5f ≤ %.3f** ⇒ 회차 54 를 연다(이 폭을 잡음 문턱으로)\n",
				(double)w[kLens - 1u], (double)kOpenGate);
		else
			LogA("[mlt] 🐛   ⭐ 판정 = ⚠️ **폭 %.5f > %.3f** — 이 배관 위에서 ㉠ 을 못 잰다. 원인을 고치거나 씨앗 설계를 바꾼다\n",
				(double)w[kLens - 1u], (double)kOpenGate);
		LogA("[mlt] 🐛   ⚠️ **진단 결과다** — 세계·표현에 대해 아무 말도 하지 않는다.\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		_E.Destroy(); _done = true;
	}

	static void _Fail(const char* why)
	{
		LogA("[mlt] 🐛 ⛔ %s (단계 %u · 길이칸 %u · 반복 %u)\n", why, _st, _li, _ri);
		_E.Destroy(); _done = true;
	}
};
