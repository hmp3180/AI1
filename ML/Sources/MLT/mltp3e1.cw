// mltp3e1.cw — ⏳ 회차 57 · **앵커가 다음 id 를 설명하나**(CPU 바닥 · 학습 0) (`-mltp3e1`)
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 57 이다.**
// ⭐ **미룬 관문 둘째** — 회차 50 이 앵커를 빼고 그 종료 심사가 「배치 의심 둘」에 올린 뒤 **네 회차** 미뤘다.
// ══════════════════════════════════════════════════════════════════════════════
//
// ⭐ **왜 몸통에 넣기 전에 CPU 로 먼저 묻나** — 앵커의 최소안이 **활성 슬롯마다 두 행**이라
//   `axes 13 → 21` · `ctx 104 → 168` ⇒ **어텐션 2.6배**다. 거기에 「같은 비용 팔」과 회차 56 이 찾은
//   **오염 2/8** 때문의 **반복 최빈값**까지 겹치면 한 회차가 무겁고 위험하다(과몰입 점검의 ㈀).
//   ⇒ ★ 회차 55 가 통한 그 수를 쓴다: **표제를 잡음 없는 CPU 자리에.**
//   *"앵커가 다음 id 를 설명하나"* 는 **학습 없이 코퍼스만으로** 답할 수 있다.
//
// ── 재는 것 ────────────────────────────────────────────────────────────────
//   **C2** 집합 복사(앵커 **무시** · λ 하나) ↔ **C4** 같은 식인데 **λ 를 링마다**(`λ₀..λ₃`)
//   눈금: **링별 지속률** — 그 폭이 곧 「앵커가 가르는 양」
//   ⚠️ `C4 ≤ C2` 는 **자동**이다(λ 하나를 넷으로 쪼갠 것) ⇒ 판정은 **「얼마나」**이고
//     문턱을 **잡음 크기**에서 뽑는다(회차 56 의 CE 폭 **0.019**).

using namespace PE;

class MLTP3E1
{
public:
	static void Tick(RHI* rhi)
	{
		if (_done || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltp3e1"))
		{
			LogA("[mlt] ⏳ 회차 57은 **꺼져 있다**(`-mltp3e1`) — 앵커가 다음 id 를 설명하나\n");
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
	static constexpr uint32 kTime = MLTP3Ctx::kTime;
	static constexpr uint32 kRings = MLTP3Ctx::kRings;
	static constexpr uint32 kCandidates = MLTP2Cfg::kPatches * kLocal;
	static constexpr uint32 kNCtx = 512u, kTestCtx = 64u;
	static constexpr uint32 kTrainEpi = 1u, kTestEpi = 101u;
	static constexpr uint32 kGroup = kEncF / kTime;
	static constexpr uint32 kSignPass = 10u;
	static constexpr float  kGainGate = 0.02f;     // ⭐ 회차 56 의 CE 폭 0.019 에서 뽑았다
	static constexpr float  kRingGate = 0.05f;
	static constexpr float  kSetExpect = 0.885f, kSetTol = 0.02f;   // 위생: 회차 55 재현

	enum { kEncInit, kEncTrain, kGather };

	inline static MLTP2Enc _E;
	inline static MLTP3Ctx _tr, _te;
	inline static bool _done = false, _banner = false, _encSetup = false, _pending = false;
	inline static uint32 _seed = 0u, _st = kEncInit, _step = 0u, _cor = 0u, _gGrp = 0u, _gIdx = 0u;
	inline static Array<float> _code, _norm;
	inline static float _c2[kSeeds], _c4[kSeeds], _setAcc[kSeeds];
	inline static float _ringLo[kSeeds], _ringHi[kSeeds];
	inline static bool  _seedOk[kSeeds];

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] ⏳ **회차 57 · 앵커가 다음 id 를 설명하나**(미룬 관문 둘째 · **학습 0 · CPU 만**)\n");
		LogA("[mlt] ⏳   C2 집합 복사(앵커 무시) ↔ C4 같은 식 + **링마다 λ** · 링 %u개(중심 거리)\n", kRings);
		LogA("[mlt] ⏳   표제② `C2−C4 ≥ %.2f`(시험) %u/%u · 표제③ 링 지속률 폭 `≥ %.2f` %u/%u · Q=2\n",
			(double)kGainGate, kSignPass, kSeeds, (double)kRingGate, kSignPass, kSeeds);
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
			if (++_cor >= 2u) { _Judge(); return; }
		}
	}

	// ⚠️ **학습 0** — 여기가 이 회차의 전부다(CPU 계산이라 잡음이 0).
	static void _Judge()
	{
		Array<float> marg;
		_tr.Marginal(marg);
		// C2 — λ 하나(집합 복사). ⚠️ λ 는 **학습 코퍼스**에서 고르고 **시험**에서 평가한다.
		float c1 = 0.0f, c2 = 0.0f, l1 = 0.0f, l2 = 0.0f;
		_tr.BestCopy(marg, c1, c2, l1, l2);
		_c2[_seed] = (float)_te.CeCopy(marg, l2, true);
		// C4 — λ 를 **링마다**.
		float lam[kRings];
		_tr.BestCopyRing(marg, lam);
		_c4[_seed] = (float)_te.CeCopyRing(marg, lam);
		// 눈금 — 링별 지속률(학습 코퍼스)과 전역 집합 정확도(위생).
		float rate[kRings]; uint32 cnt[kRings];
		_tr.PersistByRing(rate, cnt);
		float lo = rate[0], hi = rate[0];
		for (uint32 r = 0; r < kRings; ++r) { if (rate[r] < lo) lo = rate[r]; if (rate[r] > hi) hi = rate[r]; }
		_ringLo[_seed] = lo; _ringHi[_seed] = hi;
		float slot = 0.0f;
		_tr.CopyAcc(slot, _setAcc[_seed]);
		_seedOk[_seed] = true;

		LogA("[mlt] ⏳ 씨앗 %2u · C2 **%.4f** → C4 **%.4f**(이득 **%+.4f**) · 링 지속률 %.3f/%.3f/%.3f/%.3f(폭 **%.3f**) · λ %.2f/%.2f/%.2f/%.2f\n",
			_seed, (double)_c2[_seed], (double)_c4[_seed], (double)(_c2[_seed] - _c4[_seed]),
			(double)rate[0], (double)rate[1], (double)rate[2], (double)rate[3], (double)(hi - lo),
			(double)lam[0], (double)lam[1], (double)lam[2], (double)lam[3]);
		++_seed; _st = kEncInit;
	}

	static void _Summary()
	{
		double mc2 = 0.0, mc4 = 0.0, mset = 0.0, mw = 0.0;
		uint32 ok = 0u, t2 = 0u, t3 = 0u;
		for (uint32 s = 0; s < kSeeds; ++s)
		{
			if (!_seedOk[s]) continue;
			++ok;
			mc2 += _c2[s]; mc4 += _c4[s]; mset += _setAcc[s]; mw += (_ringHi[s] - _ringLo[s]);
			if ((_c2[s] - _c4[s]) >= kGainGate) ++t2;
			if ((_ringHi[s] - _ringLo[s]) >= kRingGate) ++t3;
		}
		if (ok > 0u) { mc2 /= ok; mc4 /= ok; mset /= ok; mw /= ok; }
		const bool hyg = Abs((float)mset - kSetExpect) <= kSetTol;
		const bool p2 = (t2 >= kSignPass), p3 = (t3 >= kSignPass);

		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] ⏳ **회차 57 · 앵커 결과** — 읽은 씨앗 %u/%u\n", ok, kSeeds);
		LogA("[mlt] ⏳   위생 집합 지속률 **%.3f**(회차 55 의 %.3f±%.2f) → %s\n",
			mset, (double)kSetExpect, (double)kSetTol, hyg ? "통과" : "⛔");
		LogA("[mlt] ⏳   시험 CE — C2 **%.4f** → C4 **%.4f** · **평균 이득 %+.4f**\n", mc2, mc4, mc2 - mc4);
		LogA("[mlt] ⏳   **표제② 이득 ≥ %.2f — %u/%u**(필요 %u) → %s\n",
			(double)kGainGate, t2, kSeeds, kSignPass, p2 ? "통과" : "⛔");
		LogA("[mlt] ⏳   **표제③ 링 지속률 폭 ≥ %.2f — %u/%u**(평균 폭 **%.3f**) → %s\n",
			(double)kRingGate, t3, kSeeds, mw, p3 ? "통과" : "⛔");
		if (!hyg)
			LogA("[mlt] ⏳   ⭐ 판정 = ⛔ **판정불가**(위생) — 코퍼스가 회차 55 와 다르다\n");
		else if (p2 && p3)
			LogA("[mlt] ⏳   ⭐ 판정 = ✅ **앵커에 정보가 있고 잡음보다 크다** ⇒ 회차 58 = 몸통에 앵커(두 행 · 같은 비용 팔 · 반복 최빈값)\n");
		else if (p3)
			LogA("[mlt] ⏳   ⭐ 판정 = ⛔ **정보는 있는데 잡음보다 작다** — 2.6배 비용을 낼 값이 없다 ⇒ **배치를 안 늘린다**. 다음은 **㉠ 재판정**\n");
		else
			LogA("[mlt] ⏳   ⭐ 판정 = ⛔ **링이 안 갈린다** ⇒ 다른 앵커 분해로 갈아타지 **않는다**(손잡이 훑기다). 닫고 **㉠ 재판정**\n");
		LogA("[mlt] ⏳   ⚠️ 학습 0 · CPU 만이라 **잡음이 0** 이다.\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		_E.Destroy(); _done = true;
	}

	static void _Fail(const char* why)
	{
		LogA("[mlt] ⏳ ⛔ %s (씨앗 %u · 코퍼스 %u · 단계 %u)\n", why, _seed, _cor, _st);
		_E.Destroy(); _done = true;
	}
};
