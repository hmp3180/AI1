// mltp3d1.cw — 🐛 회차 54 · **비결정성이 태어나는 스텝과 그 기제** (`-mltp3d1`)
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 54 다.**
// ⚠️ **진단 회차**다 — 세계·표현·학습에 대해 **아무 말도 하지 않는다.**
// ══════════════════════════════════════════════════════════════════════════════
//
// ⭐ **지표를 바꿨다: CE 폭 → 파라미터 블록 비트 비교.**
//   회차 53 은 최종 CE 의 폭을 봤는데 CE 는 **스칼라 하나**라 우연히 같을 수 있고 평가 경로가 낀다.
//   ⇒ 파라미터 블록 전체를 비트로 견준다 — 그 스텝까지의 계산이 **전부** 거기 있다.
//
// ── 판정 둘 ────────────────────────────────────────────────────────────────
//   **㈀ 발생 스텝**   `S ∈ {1,10,50,100,200,400,800}` 마다 `Setup → S스텝 → 파라미터` 를 2회
//   **㈁ 틱 경계**     그 `S` 에서 **틱당 스텝** `{4, 1}` 로 같은 비교
//     ⭐ `kPerTick = 1` 에서 어긋남 **0** 이면 경합이 **한 틱 안**(같은 커맨드 버퍼의 디스패치 사이)
//        ⇒ **배리어 누락 확정**이고 고칠 자리가 좁혀진다.

using namespace PE;

class MLTP3D1
{
public:
	static void Tick(RHI* rhi)
	{
		if (_done || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltp3d1"))
		{
			LogA("[mlt] 🐛 회차 54는 **꺼져 있다**(`-mltp3d1`) — 비결정성이 태어나는 스텝\n");
			_done = true; return;
		}
		if (!_banner) { _Banner(); _banner = true; }
		if (_st == kEncInit)  { _EncBegin(rhi); return; }
		if (_st == kEncTrain) { _EncTrain(); return; }
		if (_st == kGather)   { _Gather(); return; }
		if (_st == kRunInit)  { _RunBegin(rhi); return; }
		if (_st == kRunTrain) { _RunTrain(); return; }
		_Summary();
	}

	static bool Done() { return _done; }

private:
	static constexpr uint32 kSeed = 0u;
	static constexpr uint32 kEncF = 32u, kEncSteps = 1200u, kEncPerTick = 8u;
	static constexpr uint32 kN = 250u, kLocal = 8u;
	static constexpr uint32 kTime = MLTP3Ctx::kTime;
	static constexpr uint32 kBatch = MLTP3Ctx::kBatch;
	static constexpr uint32 kCandidates = MLTP2Cfg::kPatches * kLocal;
	static constexpr uint32 kNCtx = 512u, kTrainEpi = 1u;
	static constexpr uint32 kPoolSteps = kNCtx / kBatch;
	static constexpr uint32 kGroup = kEncF / kTime;
	static constexpr uint32 kLens = 7u;
	static constexpr uint32 kLen[kLens] = { 1u, 10u, 50u, 100u, 200u, 400u, 800u };
	// 팔 = (길이칸, 틱당 스텝) — 앞 `kLens` 는 ㈀(틱당 4), 뒤 둘은 ㈁(그 `S` 에서 4 ↔ 1)
	static constexpr uint32 kRuns = kLens + 2u;

	enum { kEncInit, kEncTrain, kGather, kRunInit, kRunTrain, kDone2 };

	inline static MLTP2Enc _E;
	inline static MLTModel _M;
	inline static MLTP3Ctx _C;
	inline static bool _done = false, _banner = false, _pending = false;
	inline static uint32 _st = kEncInit, _step = 0u, _gGrp = 0u, _gIdx = 0u;
	inline static Array<float> _code, _norm, _p0;
	inline static uint32 _run = 0u, _rep = 0u;      // 어느 팔 · 그 팔의 몇 번째 반복
	inline static uint32 _diff[kRuns];
	inline static uint32 _onset = 0u;               // ㈀ 가 찾은 발생 스텝(0 = 없음)

	static uint32 _Steps(uint32 run)
	{
		if (run < kLens) return kLen[run];
		return (_onset != 0u) ? _onset : kLen[kLens - 1u];
	}
	static uint32 _PerTick(uint32 run)
	{
		if (run < kLens) return 4u;
		return (run == kLens) ? 4u : 1u;
	}
	static const char* _RunName(uint32 run)
	{
		if (run < kLens) return "㈀";
		return (run == kLens) ? "㈁ 틱당4" : "㈁ 틱당1";
	}

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🐛 **회차 54 · 비결정성이 태어나는 스텝**(⚠️ **진단 회차**)\n");
		LogA("[mlt] 🐛   지표 = **파라미터 블록 비트 비교**(CE 가 아니다) · 씨앗 %u · %u문맥\n", kSeed, kNCtx);
		LogA("[mlt] 🐛   ㈀ S ∈ {1,10,50,100,200,400,800} 각 2회 · ㈁ 그 S 에서 틱당 {4,1}\n");
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
		_C.Begin(kNCtx, kN);
		_gGrp = 0u; _gIdx = 0u; _pending = false; _st = kGather;
	}

	static void _Gather()
	{
		if (_pending)
		{
			Array<float> ids, mag;
			if (!_E.ReadAct(ids, mag) || ids.Count() != kCandidates) { _Fail("활성 리드백"); return; }
			_C.StoreAct(_gGrp * kGroup + (_gIdx - 1u) / kTime, (_gIdx - 1u) % kTime, ids, mag, _norm);
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
					_C.StoreState(ctx, t, w.State());
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
			for (uint32 i = 0; i < kRuns; ++i) _diff[i] = 0u;
			_run = 0u; _rep = 0u; _st = kRunInit;
		}
	}

	static void _RunBegin(RHI* rhi)
	{
		if (!_M.Setup(rhi, MLTP3Ctx::kStateAx + kN, kN, MLTP3Ctx::kAxes, kTime)) { _Fail("몸통 준비"); return; }
		if (!_M.UploadPool(_C.Val(), _C.Tgt(), kPoolSteps) || !_M.UploadSymbolPool(_C.Sym(), kPoolSteps))
		{ _Fail("몸통 풀 업로드"); return; }
		_step = 0u; _st = kRunTrain;
	}

	static void _RunTrain()
	{
		const uint32 S = _Steps(_run), P = _PerTick(_run);
		if (_step >= S) { _AfterRun(); return; }
		for (uint32 i = 0; i < P && _step < S; ++i)
		{
			_M.SelectStep(_step % kPoolSteps);
			if (!_M.Forward() || !_M.Backward() || !_M.AdamStep(1.0f)) { _Fail("몸통 스텝"); return; }
			++_step;
		}
	}

	// ⚠️ 파라미터 블록을 통째로 읽는다 — **다음 틱**이 아니라 여기서 읽어도 되는 이유는
	//   `MLArena::Read` 가 스테이징 복사라 **그 자체로 큐를 비운다**(회차 53 의 `ReadLoss` 는
	//   같은 버퍼를 그냥 들여다보는 자리라 달랐다). ⚠️ 그래도 두 팔이 **같은 규약**이라 비교는 성립한다.
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

	static void _AfterRun()
	{
		Array<float> p;
		if (!_ReadParams(p)) { _Fail("파라미터 리드백"); return; }
		if (_rep == 0u)
		{
			_p0.Reset(0);
			for (uint32 i = 0; i < p.Count(); ++i) _p0.Add(p[i]);
			_rep = 1u; _st = kRunInit; return;
		}
		uint32 d = 0u;
		for (uint32 i = 0; i < p.Count(); ++i) if (!(p[i] == _p0[i])) ++d;
		_diff[_run] = d;
		LogA("[mlt] 🐛 %s S=%4u · 틱당 %u — 파라미터 %u개 중 어긋남 **%u**%s\n",
			_RunName(_run), _Steps(_run), _PerTick(_run), p.Count(), d,
			(d == 0u) ? "  ⇒ **비트 동일**" : "");
		if (_run < kLens && d != 0u && _onset == 0u) _onset = kLen[_run];
		_rep = 0u;
		if (++_run >= kRuns) { _st = kDone2; return; }
		// ⚠️ ㈀ 이 끝났는데 어긋난 칸이 하나도 없으면 ㈁ 은 800스텝에서 돈다(그 자리도 0 이면 판정불가).
		_st = kRunInit;
	}

	static void _Summary()
	{
		const uint32 a4 = _diff[kLens], a1 = _diff[kLens + 1u];
		const bool anyA = (_onset != 0u);
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🐛 **회차 54 · 비결정성의 자리 결과**\n");
		for (uint32 r = 0; r < kLens; ++r)
			LogA("[mlt] 🐛   ㈀ S=%4u — 어긋남 **%u**\n", kLen[r], _diff[r]);
		LogA("[mlt] 🐛   ㈁ S=%u — 틱당 4 **%u** ↔ 틱당 1 **%u**\n", _Steps(kLens), a4, a1);
		if (!anyA)
			LogA("[mlt] 🐛   ⭐ 판정 = ⚠️ **판정불가** — 어느 S 에서도 파라미터가 안 갈린다. 회차 53 의 폭(0.047)은\n"
			     "[mlt] 🐛      **평가 경로**(풀 64칸 순회)에서 왔을 수 있다 ⇒ 배리어를 안 건드리고 그쪽을 먼저 본다\n");
		else if (a1 == 0u && a4 != 0u)
			LogA("[mlt] 🐛   ⭐ 판정 = ✅ **배리어 누락 확정**(한 틱 안의 디스패치 사이) — 회차 55 = 배리어를 넣고 폭이 0 이 되는지\n");
		else if (a1 != 0u && a4 != 0u)
			LogA("[mlt] 🐛   ⭐ 판정 = ⚠️ **틱 경계가 아니다** — 다음 후보(아레나 재생성 · 드라이버 스케줄)를 회차 55 에 적는다\n");
		else
			LogA("[mlt] 🐛   ⭐ 판정 = ⚠️ **읽을 수 없다**(틱당 4 가 0 인데 1 이 아니다) — 반복 수를 늘려 다시 등록한다\n");
		LogA("[mlt] 🐛   발생 스텝 = **%u**(0 = 없음) · ⚠️ 진단 결과다\n", _onset);
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		_E.Destroy(); _done = true;
	}

	static void _Fail(const char* why)
	{
		LogA("[mlt] 🐛 ⛔ %s (단계 %u · 팔 %u · 반복 %u)\n", why, _st, _run, _rep);
		_E.Destroy(); _done = true;
	}
};
