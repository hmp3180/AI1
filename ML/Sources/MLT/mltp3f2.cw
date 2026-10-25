// mltp3f2.cw — ⏳ 회차 85a · **㉠ 을 512 문맥으로 재판정** (`-mltp3f2`) — ⭐ 회차 83 과 `kNCtx` **128→512** 만 다르다
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 83 이다.** ⭐ **하네스보다 먼저 썼다.**
// ⭐ **회차 59 와 한 글자만 다르다: `kTestEpi` 101 → 901.**
//
// ⚠️⚠️ 회차 82 가 **㉡′(회차 60)을 무너뜨렸다** — 깨끗한 시험에서 `㈁>㈀` 이 **12/12 → 7/12**.
//   ㉠(회차 59)도 **같은 누출 대역(101)** 을 썼으므로 **다시 재야 한다**.
//
// ⭐ **미리 적은 예측**(회차 82 의 「효과가 작을수록 위험하다」에서):
//   회차 59 의 효과 — `㈁ 상수0` **+0.167** · `㈂ 무작위` **+0.119**
//   ⇒ ⚠️ ***㈂ 가 더 작으므로 ㈂ 가 먼저 무너져야 한다.***
//   ⚠️⚠️ 그런데 회차 82 에서는 **㈂(효과 큰 쪽)가 살아남고 ㈁(작은 쪽)이 무너졌다** ⇒ 규칙과 맞다.
//   ⇒ ★ 이 회차가 그 규칙을 **한 번 더** 시험한다.
// ══════════════════════════════════════════════════════════════════════════════
//
// ── (아래는 회차 59 의 머리말 원문) ──────────────────────────────────────
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 59 이다.**
// ⭐ 상위 캔버스가 **새것**이다: **잡음을 이기는 판정 형식**.
//   ⚠️ 닫은 캔버스(*"몸통이 다음 활성을 예측하나"*)의 넷째가 아니다 — 회차 58 이 못 넘은 것은
//     **표제가 아니라 위생**이었고, 남은 물음은 한 층 위다: ***"우리 자가 이 잡음을 이길 수 있나?"***
//   ⇒ **이 회차의 표제는 자(형식)이고, ㉠ 은 자가 통과했을 때만 읽는 부산물이다.**
// ══════════════════════════════════════════════════════════════════════════════
//
// ⛔ **최빈값은 죽었다** — 회차 58 이 두 번 다 **최빈빈도 30.6%** 를 냈다(문턱 90%).
// ⭐ **대신 회차 58 이 우연히 보인 것을 미리 등록한다** — 두 **독립 실행**이 같은 결론을 냈다
//   (`㈀ 0.8747↔0.8782` · 표제 `12/12·12/12 ↔ 11/12·12/12`) ⇒ *"오염은 무작위라 평균에서 씻긴다"*.
//   그것을 **한 실행 안에서** 재는 형식이 **분할 반쪽**이다:
//     `R = 6` · 씨앗값 = **6회 평균** · 반쪽 A = 반복 0·2·4 · 반쪽 B = 반복 1·3·5
//     ⇒ 두 반쪽이 **서로 독립 추정**이고, **둘이 각각 같은 결론**을 내면 그 자는 잡음을 이긴 것이다.
//
// ⚠️ 바뀌는 것은 **`R` 과 집계뿐**이다 — 128문맥·800스텝·id 정렬·앵커 없음·팔 넷은 회차 58 그대로.
//   ㈃(`lr=0`)만 `R=1`(갱신이 0이라 평탄성은 결정적이다).

using namespace PE;

class MLTP3F2
{
public:
	static void Tick(RHI* rhi)
	{
		if (_done || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltp3f2"))
		{
			LogA("[mlt] ⏳ 회차 59은 **꺼져 있다**(`-mltp3f2`) — ㉠ 재판정(상태가 비전 예측을 돕나)\n");
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
		//   ★ 회차 59 1차가 그 얼굴이다: 오염률이 회차 56(업로드 8회)의 25% 에서 **업로드 240회**일 때
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
	static constexpr uint32 kNCtx = 512u, kTestCtx = 64u;      // ⭐ 회차 52 의 ㈁ 팔
	// ⭐ **회차 83 이 고친 유일한 것** — `kTestEpi` 101 → **901**(회차 59 는 누출 대역이었다).
	static constexpr uint32 kTrainEpi = 1u, kTestEpi = 901u;
	static_assert(kTestEpi >= kTrainEpi + kNCtx,
		"시험 에피소드가 학습과 겹친다 — kTestEpi >= kTrainEpi + kNCtx 여야 한다(규율 12)");
	static constexpr uint32 kPoolSteps = kNCtx / kBatch, kTestPool = kTestCtx / kBatch;
	static constexpr uint32 kGroup = kEncF / kTime;
	static constexpr uint32 kSteps = 800u, kPerTick = 4u;      // 에폭 50
	static constexpr uint32 kArms = 4u, kRep = 6u;   // ⭐ 짝수 — 분할 반쪽(회차 59)
	static constexpr uint32 kSignPass = 10u;
	static constexpr float  kFlatRel = 1.0e-6f;
	// 회차 58 재현 문턱(1차 0.8747·2차 0.8782 / 1.0562·1.0507 / 0.9956·1.0126)
	static constexpr float  kR58A = 0.876f, kR58B = 1.053f, kR58C = 1.004f;
	static constexpr float  kTolA = 0.02f, kTolC = 0.03f;

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
	inline static float _ceA[kArms][kSeeds], _ceB[kArms][kSeeds];   // 분할 반쪽
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
		LogA("[mlt] ⏳ **회차 85a · ㉠ 을 512 문맥으로**(⭐ 판정 · `kNCtx` 128→**512**)\n");
		LogA("[mlt] ⏳   %u문맥 · %u스텝 · id 정렬 · 팔 넷 — 회차 58 과 **집계만** 다르다(R=%u · **평균 + 분할 반쪽**)\n",
			kNCtx, kSteps, kRep);
		LogA("[mlt] ⏳   표제① **분할 반쪽 일치**(A·B 가 각각 %u/%u) · 표제② 회차 58 재현 · ㉠ 은 **부산물**\n",
			kSignPass, kSeeds);
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

	// ⭐ **평균 + 분할 반쪽**(회차 59) — ⚠️ 최빈값은 회차 58 이 죽였다(빈도 30.6%).
	//   회차 58 의 **두 독립 실행이 같은 결론**을 냈다 ⇒ *"오염은 무작위라 평균에서 씻긴다"*.
	//   그것을 **한 실행 안에서 미리 등록해 검증**하는 형식이 **분할 반쪽**이다:
	//     반쪽 A = 반복 0·2·4 의 평균 · 반쪽 B = 반복 1·3·5 의 평균 ⇒ 서로 **독립 추정**이다.
	static void _Mode()
	{
		const uint32 R = _Reps();
		double s = 0.0, sA = 0.0, sB = 0.0; uint32 nA = 0u, nB = 0u;
		for (uint32 i = 0; i < R; ++i)
		{
			s += (double)_run[i];
			if ((i % 2u) == 0u) { sA += (double)_run[i]; ++nA; } else { sB += (double)_run[i]; ++nB; }
		}
		_ce[_arm][_seed]  = (float)(s / (double)R);
		_ceA[_arm][_seed] = (nA == 0u) ? _ce[_arm][_seed] : (float)(sA / (double)nA);
		_ceB[_arm][_seed] = (nB == 0u) ? _ce[_arm][_seed] : (float)(sB / (double)nB);
		LogA("[mlt] ⏳   %s 씨앗 %2u · 평균 CE **%.5f**(반쪽 A %.5f · B %.5f · R=%u)\n",
			_ArmName(), _seed, (double)_ce[_arm][_seed],
			(double)_ceA[_arm][_seed], (double)_ceB[_arm][_seed], R);
		_rep = 0u;
		if (++_arm < kArms) { _ToBody(); return; }
		_seedOk[_seed] = _finite;
		++_seed; _st = kEncInit;
	}

	static void _Summary()
	{
		double m[kArms], mf = 0.0;
		for (uint32 a = 0; a < kArms; ++a) m[a] = 0.0;
		uint32 ok = 0u, t1 = 0u, t2 = 0u, beat = 0u, flat = 0u;
		uint32 a1 = 0u, a2 = 0u, b1 = 0u, b2 = 0u;      // 반쪽 A/B 의 부호검정
		for (uint32 s = 0; s < kSeeds; ++s)
		{
			if (!_seedOk[s]) continue;
			++ok;
			for (uint32 a = 0; a < kArms; ++a) m[a] += _ce[a][s];
			mf += _floorTe[s];
			if (_ce[0][s] < _floorTe[s]) ++beat;
			if (Abs(_ce[3][s] - _pre0[s]) <= kFlatRel * Abs(_pre0[s])) ++flat;
			if (_ce[1][s] > _ce[0][s]) ++t1;
			if (_ce[2][s] > _ce[0][s]) ++t2;
			// ⭐ 분할 반쪽 — 두 **독립 추정**이 각각 같은 결론을 내나
			if (_ceA[1][s] > _ceA[0][s]) ++a1;
			if (_ceA[2][s] > _ceA[0][s]) ++a2;
			if (_ceB[1][s] > _ceB[0][s]) ++b1;
			if (_ceB[2][s] > _ceB[0][s]) ++b2;
		}
		if (ok > 0u) { for (uint32 a = 0; a < kArms; ++a) m[a] /= ok; mf /= ok; }
		// 표제① — **자가 잡음을 이기나**: 반쪽 A·B 가 **각각** 두 문턱을 넘는다.
		const bool split = (a1 >= kSignPass) && (a2 >= kSignPass) && (b1 >= kSignPass) && (b2 >= kSignPass);
		// 표제② — 회차 58 재현.
		const bool repro = (Abs((float)m[0] - kR58A) <= kTolA)
			&& (Abs((float)m[1] - kR58B) <= kTolA)
			&& (Abs((float)m[2] - kR58C) <= kTolC);
		const bool plumb = (flat == ok) && (beat >= kSignPass) && _finite;
		const bool p1 = (t1 >= kSignPass), p2 = (t2 >= kSignPass);

		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] ⏳ **회차 85a · ㉠ 512 문맥** — 읽은 씨앗 %u/%u\n", ok, kSeeds);
		LogA("[mlt] ⏳   배관 — ㈃ 평탄 **%u/%u** · ㈀ 이 바닥을 넘음 **%u/%u** → %s\n",
			flat, ok, beat, kSeeds, plumb ? "통과" : "⛔");
		LogA("[mlt] ⏳   평균 CE — 시험바닥 **%.4f** · ㈀ **%.4f** · ㈁ **%.4f** · ㈂ **%.4f**\n",
			mf, m[0], m[1], m[2]);
		LogA("[mlt] ⏳   **표제① 분할 반쪽 일치** — A(㈁>㈀ %u · ㈂>㈀ %u) · B(%u · %u) · 각 필요 %u → %s\n",
			a1, a2, b1, b2, kSignPass, split ? "통과" : "⛔");
		LogA("[mlt] ⏳   **표제② 회차 58 재현** — ㈀ %.4f(%.3f±%.2f) · ㈁ %.4f(%.3f±%.2f) · ㈂ %.4f(%.3f±%.2f) → %s\n",
			m[0], (double)kR58A, (double)kTolA, m[1], (double)kR58B, (double)kTolA,
			m[2], (double)kR58C, (double)kTolC, repro ? "통과" : "⛔");
		LogA("[mlt] ⏳   ㉠(부산물) — ㈁>㈀ **%u/%u** · ㈂>㈀ **%u/%u**\n", t1, kSeeds, t2, kSeeds);
		if (!plumb || !repro)
			LogA("[mlt] ⏳   ⭐ 판정 = ⛔ **판정불가** — 배관/체제가 회차 58 과 다르다. ㉠ 을 읽지 않는다\n");
		else if (!split)
			LogA("[mlt] ⏳   ⭐ 판정 = ⛔ **자가 아직 못 미덥다**(반쪽이 안 맞는다) — ㉠ 미결 유지 ⇒ 다음은 **오염의 진짜 원인**\n");
		else if (p1 && p2)
			LogA("[mlt] ⏳   ⭐ 판정 = ✅✅ **자가 섰고 ㉠ 통과 — 상태가 비전 예측을 돕는다**(P3 의 첫 관문이 섰다)\n");
		else if (p1 || p2)
			LogA("[mlt] ⏳   ⭐ 판정 = ⚠️ 자는 섰는데 **한 팔만** 나빠졌다 ⇒ **판정불가**(상수와 무작위는 뜻이 다르다)\n");
		else
			LogA("[mlt] ⏳   ⭐ 판정 = ⛔ **자는 섰고 ㉠ 은 실패 확정** ⇒ **압축(`q` 선택자) 재질문**을 연다(약속한 자리)\n");
		LogA("[mlt] ⏳   ⚠️ 고정 %u문맥의 진단이다 — 절대 성능으로 인용하지 않는다\n", kNCtx);
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		_E.Destroy(); _done = true;
	}

	static void _Fail(const char* why)
	{
		LogA("[mlt] ⏳ ⛔ %s (씨앗 %u · 팔 %u · 반복 %u · 단계 %u)\n", why, _seed, _arm, _rep, _st);
		_E.Destroy(); _done = true;
	}
};
