// mltp3c4.cw — ⏳ 회차 58 · **㉠ 재판정: 상태가 비전 예측을 돕나** (`-mltp3c4`)
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 58 이다.**
// ⚠️⚠️ 상위 캔버스(**몸통이 다음 활성을 예측하나**)의 **세 번째**다(49·50 이 있었다)
//   ⇒ **결과와 무관하게 이 회차가 그 캔버스를 닫는다. 넷째는 없다.**
// ══════════════════════════════════════════════════════════════════════════════
//
// ── 회차 50 이후 무엇이 달라졌나 ────────────────────────────────────────────
//   외운 체제(64문맥)  → **128문맥·800스텝**(회차 52 의 ㈁ 팔 = 일반화가 서는 최소 자리)
//   표적의 결함(순위)  → **id 정렬**(회차 55 의 표준)
//   잡음(폭 0.019)     → **반복 R=5 · 최빈값**(회차 56 의 처방)
//   앵커               → 회차 57 이 **넣을 값 없음**을 쟀다(이득 0.0035) ⇒ 그대로 뺀다
//
// ⭐ **최빈값** — 5회의 시험 CE 중 **정확히 같은 값이 가장 많이 나온 것**.
//   회차 56 이 *"정상들은 비트 동일 · 오염은 매번 다른 값"* 을 보였으므로 그것이 정상값을 집는다.
//   ⚠️ ㈃(`lr=0`)만 `R=1` 이다 — 갱신이 0이라 평탄성은 결정적이고 5회는 낭비다.

using namespace PE;

class MLTP3C4
{
public:
	static void Tick(RHI* rhi)
	{
		if (_done || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltp3c4"))
		{
			LogA("[mlt] ⏳ 회차 58은 **꺼져 있다**(`-mltp3c4`) — ㉠ 재판정(상태가 비전 예측을 돕나)\n");
			_done = true; return;
		}
		if (!_banner) { _Banner(); _banner = true; }
		if (_seed >= kSeeds) { _Summary(); return; }
		if (_st == kEncInit)  { _EncBegin(rhi); return; }
		if (_st == kEncTrain) { _EncTrain(); return; }
		if (_st == kGather)   { _Gather(); return; }
		// ⭐ **배관 고침(2026-08-26)** — 반복 사이에 **틱을 비운다**.
		//   ⚠️ 이 엔진은 dispatch 를 `computeCb[frame]` 에 **누적만** 하고 제출은 Present 에서 1회다
		//     (`RHIBuffer_Vulkan.cpp` 의 그 ⚠️⚠️⚠️). 그래서 `Setup`/`UploadPool` 이 곧바로 오면
		//     **아직 제출도 안 된 앞 반복의 디스패치**가 그 버퍼를 나중에 읽는다 ⇒ 엉뚱한 데이터로 학습.
		//   ★ 회차 58 1차가 그 얼굴이다: 오염률이 회차 56(업로드 8회)의 25% 에서 **업로드 240회**일 때
		//     크게 뛰었다(최빈빈도 `≥3/5` 가 30.6%).
		//   ⇒ 고침은 리드백이 아니라 **틱을 넘기는 것**이다(제출은 Present 가 한다).
		if (_st == kQuiesce)
		{
			if (_qWait > 0u) { --_qWait; return; }
			_st = kBodyInit; return;
		}
		if (_st == kBodyInit) { _BodyBegin(rhi); return; }
		if (_st == kBodyEval) { _BodyEval(); return; }
		_BodyTrain();
	}

	static bool Done() { return _done; }

private:
	static constexpr uint32 kSeeds = 12u;
	static constexpr uint32 kEncF = 32u, kEncSteps = 1200u, kEncPerTick = 8u;
	static constexpr uint32 kN = 250u, kLocal = 8u;
	static constexpr uint32 kTime = MLTP3Ctx::kTime;
	static constexpr uint32 kBatch = MLTP3Ctx::kBatch;
	static constexpr uint32 kCandidates = MLTP2Cfg::kPatches * kLocal;
	static constexpr uint32 kNCtx = 128u, kTestCtx = 64u;      // ⭐ 회차 52 의 ㈁ 팔
	static constexpr uint32 kTrainEpi = 1u, kTestEpi = 101u;
	static constexpr uint32 kPoolSteps = kNCtx / kBatch, kTestPool = kTestCtx / kBatch;
	static constexpr uint32 kGroup = kEncF / kTime;
	static constexpr uint32 kSteps = 800u, kPerTick = 4u;      // 에폭 50
	static constexpr uint32 kArms = 4u, kRep = 5u;
	static constexpr uint32 kSignPass = 10u;
	static constexpr float  kFlatRel = 1.0e-6f, kModeFrac = 0.90f;

	enum { kEncInit, kEncTrain, kGather, kQuiesce, kBodyInit, kBodyTrain, kBodyEval };

	inline static MLTP2Enc _E;
	inline static MLTModel _M;
	inline static MLTP3Ctx _tr, _te;
	inline static MLTEvalGate _gate;
	inline static bool _done = false, _banner = false, _encSetup = false, _finite = true;
	inline static bool _pending = false, _pre = false;
	inline static uint32 _seed = 0u, _st = kEncInit, _step = 0u, _arm = 0u, _rep = 0u;
	inline static uint32 _cor = 0u, _gGrp = 0u, _gIdx = 0u;
	inline static Array<float> _code, _norm;
	inline static float _run[kRep];                    // 이 (씨앗,팔)의 반복별 시험 CE
	inline static float _ce[kArms][kSeeds];            // 최빈값
	inline static uint32 _modeCnt[kArms][kSeeds];
	inline static float _pre0[kSeeds];                 // ㈃ 의 학습 전 CE(평탄성)
	inline static float _floorTe[kSeeds];
	inline static bool  _seedOk[kSeeds];

	inline static uint32 _qWait = 0u;
	// ⭐ 몸통을 새로 세우기 전에 **틱을 비운다**(위 배관 고침의 그 자리).
	static void _ToBody() { _qWait = MLTEvalGate::kDelay; _st = kQuiesce; }

	static uint32 _Reps() { return (_arm == 3u) ? 1u : kRep; }
	static const char* _ArmName()
	{
		return (_arm == 0u) ? "㈀ 온전" : ((_arm == 1u) ? "㈁ 상수0" : ((_arm == 2u) ? "㈂ 무작위" : "㈃ lr=0"));
	}

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] ⏳ **회차 58 · ㉠ 재판정 — 상태가 비전 예측을 돕나**(⚠️ 이 캔버스의 **세 번째** — 닫는다)\n");
		LogA("[mlt] ⏳   %u문맥 · %u스텝(에폭 50) · **id 정렬** · 앵커 없음 · 팔 넷 · **반복 R=%u 최빈값**\n",
			kNCtx, kSteps, kRep);
		LogA("[mlt] ⏳   위생: 최빈빈도 ≥3/5 가 ≥%.0f%% · ㈃ 평탄 · ㈀ 이 시험 복사바닥을 넘음 10/12\n",
			(double)(kModeFrac * 100.0f));
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

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
		_tr.SetSortById(true); _te.SetSortById(true);
		_tr.Begin(kNCtx, kN); _te.Begin(kTestCtx, kN);
		_cor = 0u; _gGrp = 0u; _gIdx = 0u; _pending = false; _st = kGather;
	}

	static void _Gather()
	{
		MLTP3Ctx& C = (_cor == 0u) ? _tr : _te;
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
				MLTWorld w; w.Reset(_seed, epi + ctx, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
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
		if (++_gGrp * kGroup >= nCtx)
		{
			_gGrp = 0u;
			if (++_cor >= 2u)
			{
				// 시험 복사 바닥(위생 3) — ⚠️ λ·M 은 **학습 코퍼스**에서 고른다.
				Array<float> marg; _tr.Marginal(marg);
				float c1 = 0.0f, c2 = 0.0f, l1 = 0.0f, l2 = 0.0f;
				_tr.BestCopy(marg, c1, c2, l1, l2);
				const float t1 = (float)_te.CeCopy(marg, l1, false);
				const float t2 = (float)_te.CeCopy(marg, l2, true);
				_floorTe[_seed] = (t1 < t2) ? t1 : t2;
				LogA("[mlt] ⏳ 씨앗 %2u · 시험 복사바닥 **%.4f**\n", _seed, (double)_floorTe[_seed]);
				_arm = 0u; _rep = 0u; _ToBody();
			}
		}
	}

	static void _BodyBegin(RHI* rhi)
	{
		if (!_M.Setup(rhi, MLTP3Ctx::kStateAx + kN, kN, MLTP3Ctx::kAxes, kTime)) { _Fail("몸통 준비"); return; }
		// 상태 슬롯의 **값만** 팔마다 바꾼다.
		Array<float> v; v.Reset(0);
		const uint32 n = kPoolSteps * MLTP3Ctx::kRows;
		for (uint32 i = 0; i < n; ++i) v.Add(_tr.Val()[i]);
		for (uint32 ctx = 0; ctx < kNCtx; ++ctx)
			for (uint32 t = 0; t < kTime; ++t)
			{
				const uint32 base = MLTP3Ctx::Row(ctx, t, 0u);
				for (uint32 a = 0; a < MLTP3Ctx::kStateAx; ++a)
				{
					if (_arm == 0u || _arm == 3u) continue;                 // 진짜 상태 그대로
					float x = 0.0f;
					if (_arm == 2u)
					{
						const uint32 h = MLTWorld::Hash(_seed * 7919u + ctx * 131u + t * 17u + a,
							MLTSalt::Start, 91u);
						x = MLTWorld::Unit(h);
					}
					v.Data()[base + a] = x;
				}
			}
		if (!_M.UploadPool(v, _tr.Tgt(), kPoolSteps) || !_M.UploadSymbolPool(_tr.Sym(), kPoolSteps))
		{ _Fail("학습 풀 업로드"); return; }
		_step = 0u;
		// ㈃ 는 학습 **전** CE 를 먼저 잡는다(평탄성).
		if (_arm == 3u && _rep == 0u) { _pre = true; _SwitchToTest(); return; }
		_pre = false; _st = kBodyTrain;
	}

	static bool _SwitchToTest()
	{
		if (!_M.UploadPool(_te.Val(), _te.Tgt(), kTestPool) || !_M.UploadSymbolPool(_te.Sym(), kTestPool))
		{ _Fail("시험 풀 업로드"); return false; }
		_gate.Begin(kTestPool); _st = kBodyEval;
		return true;
	}

	static void _BodyTrain()
	{
		if (_step >= kSteps) { _SwitchToTest(); return; }
		for (uint32 i = 0; i < kPerTick && _step < kSteps; ++i)
		{
			_M.SelectStep(_step % kPoolSteps);
			if (!_M.Forward() || !_M.Backward() || !_M.AdamStep((_arm == 3u) ? 0.0f : 1.0f))
			{ _Fail("몸통 스텝"); return; }
			++_step;
		}
	}

	static void _BodyEval()
	{
		bool fail = false;
		if (!_gate.Step(_M, fail)) return;
		if (fail) { _Fail("평가 게이트"); return; }
		if (!_gate.Finite()) _finite = false;
		const float ce = _gate.Mean();
		if (_pre)
		{
			// ㈃ 의 학습 전 CE — 학습 풀로 되돌리고 학습을 시작한다.
			_pre0[_seed] = ce; _pre = false;
			if (!_M.UploadPool(_tr.Val(), _tr.Tgt(), kPoolSteps) || !_M.UploadSymbolPool(_tr.Sym(), kPoolSteps))
			{ _Fail("학습 풀 복귀"); return; }
			_step = 0u; _st = kBodyTrain; return;
		}
		_run[_rep] = ce;
		if (++_rep < _Reps()) { _ToBody(); return; }
		_Mode();
	}

	// ⭐ 최빈값 — **정확히 같은 값**이 가장 많이 나온 것(회차 56: 정상은 비트 동일 · 오염은 매번 다르다).
	static void _Mode()
	{
		const uint32 R = _Reps();
		uint32 bestI = 0u, bestC = 0u;
		for (uint32 i = 0; i < R; ++i)
		{
			uint32 c = 0u;
			for (uint32 j = 0; j < R; ++j) if (_run[j] == _run[i]) ++c;
			if (c > bestC) { bestC = c; bestI = i; }
		}
		_ce[_arm][_seed] = _run[bestI];
		_modeCnt[_arm][_seed] = bestC;
		LogA("[mlt] ⏳   %s 씨앗 %2u · 최빈 CE **%.5f**(빈도 %u/%u)\n",
			_ArmName(), _seed, (double)_ce[_arm][_seed], bestC, R);
		_rep = 0u;
		if (++_arm < kArms) { _ToBody(); return; }
		_seedOk[_seed] = _finite;
		++_seed; _st = kEncInit;
	}

	static void _Summary()
	{
		double m[kArms], mf = 0.0;
		for (uint32 a = 0; a < kArms; ++a) m[a] = 0.0;
		uint32 ok = 0u, t1 = 0u, t2 = 0u, beat = 0u, flat = 0u, modeOk = 0u, modeTot = 0u;
		for (uint32 s = 0; s < kSeeds; ++s)
		{
			if (!_seedOk[s]) continue;
			++ok;
			for (uint32 a = 0; a < kArms; ++a) m[a] += _ce[a][s];
			mf += _floorTe[s];
			for (uint32 a = 0; a < 3u; ++a) { ++modeTot; if (_modeCnt[a][s] >= 3u) ++modeOk; }
			if (_ce[0][s] < _floorTe[s]) ++beat;
			if (Abs(_ce[3][s] - _pre0[s]) <= kFlatRel * Abs(_pre0[s])) ++flat;
			if (_ce[1][s] > _ce[0][s]) ++t1;
			if (_ce[2][s] > _ce[0][s]) ++t2;
		}
		if (ok > 0u) { for (uint32 a = 0; a < kArms; ++a) m[a] /= ok; mf /= ok; }
		const float modeRate = (modeTot == 0u) ? 0.0f : ((float)modeOk / (float)modeTot);
		const bool hyg = (modeRate >= kModeFrac) && (flat == ok) && (beat >= kSignPass) && _finite;
		const bool p1 = (t1 >= kSignPass), p2 = (t2 >= kSignPass);

		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] ⏳ **회차 58 · ㉠ 재판정 결과** — 읽은 씨앗 %u/%u\n", ok, kSeeds);
		LogA("[mlt] ⏳   위생① 최빈빈도 ≥3/5 — **%.1f%%**(%u/%u · 회차 56 예측 89.7%%) → %s\n",
			(double)(modeRate * 100.0f), modeOk, modeTot, (modeRate >= kModeFrac) ? "통과" : "⛔");
		LogA("[mlt] ⏳   위생② ㈃ 평탄 **%u/%u** · 위생③ ㈀ 이 바닥을 넘음 **%u/%u**(필요 %u)\n",
			flat, ok, beat, kSeeds, kSignPass);
		LogA("[mlt] ⏳   평균 CE — 시험바닥 **%.4f** · ㈀ **%.4f** · ㈁ **%.4f** · ㈂ **%.4f**\n",
			mf, m[0], m[1], m[2]);
		LogA("[mlt] ⏳   **표제 ㈁>㈀ — %u/%u**(필요 %u) → %s\n", t1, kSeeds, kSignPass, p1 ? "통과" : "⛔");
		LogA("[mlt] ⏳   **표제 ㈂>㈀ — %u/%u**(필요 %u) → %s\n", t2, kSeeds, kSignPass, p2 ? "통과" : "⛔");
		if (!hyg)
			LogA("[mlt] ⏳   ⭐ 판정 = ⛔ **판정불가**(위생) — 배관/체제만 읽는다\n");
		else if (p1 && p2)
			LogA("[mlt] ⏳   ⭐ 판정 = ✅ **㉠ 통과 — 상태가 비전 예측을 돕는다**(P3 의 첫 관문이 섰다)\n");
		else if (p1 || p2)
			LogA("[mlt] ⏳   ⭐ 판정 = ⚠️ **판정불가** — 한 팔만 나빠졌다(상수와 무작위는 뜻이 다르다)\n");
		else
			LogA("[mlt] ⏳   ⭐ 판정 = ⛔ **㉠ 실패 확정** — 외운 체제도 표적 결함도 잡음도 없앴다\n"
			     "[mlt] ⏳      ⇒ 남은 큰 용의자는 **압축(`q` 선택자)** 하나다. 종료 심사에서 그 재질문을 연다\n");
		LogA("[mlt] ⏳   ⚠️ 이 캔버스는 **세 번째라 여기서 닫는다.** 고정 %u문맥의 진단이다\n", kNCtx);
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		_E.Destroy(); _done = true;
	}

	static void _Fail(const char* why)
	{
		LogA("[mlt] ⏳ ⛔ %s (씨앗 %u · 팔 %u · 반복 %u · 단계 %u)\n", why, _seed, _arm, _rep, _st);
		_E.Destroy(); _done = true;
	}
};
