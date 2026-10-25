// mltp3g0.cw — ⏳ 회차 60 · **과거 활성이 쓰이나** (`-mltp3g0`)
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 60 이다.**
// ⭐ 상위 캔버스가 **새것**이다: **활성이 시간을 건너 하중을 받나**.
//
// ⚠️⚠️ **먼저 — ㉡(눈감기)은 지금 배관에서 못 잰다.** `MLT.md` 의 ㉡ 은 *"`t` 부터 **프레임을 끊고**
//   활성만 남긴다"* 인데 **우리 컨텍스트에는 원본 패치가 애초에 없다**(상태 5 + 활성 8 뿐)
//   ⇒ **이미 눈을 감은 상태**다. 제대로 재려면 `EYE` 구간에 원본 패치 64개를 넣어야 하고 그것은
//   `ctx` 를 통째로 바꾼다. ⇒ **이 회차는 ㉡ 이 아니라 그 짝**이고, ㉠ 과 **정확히 짝**이다:
//     ㉠ = *상태 채널이 쓰이나* · 이 회차 = ***활성 채널의 과거가 쓰이나***.
// ══════════════════════════════════════════════════════════════════════════════
//
// ⭐ **무엇을 묻나** — 몸통이 **직전 시각만** 보고 있다면 그것은 **복사 + 상태**일 뿐이다.
//   ⇒ 시각 `0..5` 의 활성을 끊고 `6`(마지막 예측자)만 남겼을 때 예측이 나빠지나.
//
// ⚠️⚠️ **채점 자리를 좁힌다** — 시각 `0..5` 를 끊으면 그 시각들의 표적도 당연히 나빠지는데 그것은
//   *"자기 입력이 끊겼다"* 이지 *"과거가 쓰인다"* 가 아니다. ⇒ **평가는 시각 `6` 의 표적만** 센다
//   (그 행의 입력은 **온전**하고 끊긴 것은 **그 앞**뿐이다). **학습은 모든 표적으로** 한다.
//   ★ 복사바닥도 **같은 자리**에서 다시 잰다(`MLTP3Ctx::CeCopy` 의 `t1Only`).
//
// ⭐ 자(형식)는 **회차 59 가 세운 것을 그대로** 쓴다 — `R=6` · 평균 + **분할 반쪽**(A=0·2·4 / B=1·3·5).
// ⚠️ 어휘를 `5 + N + 1` 로 둔다(마지막이 **「없음」 심볼**) — **네 팔 모두** 그 어휘라 파라미터 수가 같다.

using namespace PE;

class MLTP3G0
{
public:
	static void Tick(RHI* rhi)
	{
		if (_done || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltp3g0"))
		{
			LogA("[mlt] ⏳ 회차 60은 **꺼져 있다**(`-mltp3g0`) — 과거 활성이 하중을 받나\n");
			_done = true; return;
		}
		if (!_banner) { _Banner(); _banner = true; }
		if (_seed >= kSeeds) { _Summary(); return; }
		if (_st == kEncInit)  { _EncBegin(rhi); return; }
		if (_st == kEncTrain) { _EncTrain(); return; }
		if (_st == kGather)   { _Gather(); return; }
		// ⚠️ 반복 사이에 **틱을 비운다**(회차 59 의 그 배관 고침 — 제출은 Present 가 한다).
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
	static constexpr uint32 kNCtx = 128u, kTestCtx = 64u;
	static constexpr uint32 kTrainEpi = 1u, kTestEpi = 101u;
	static constexpr uint32 kPoolSteps = kNCtx / kBatch, kTestPool = kTestCtx / kBatch;
	static constexpr uint32 kGroup = kEncF / kTime;
	static constexpr uint32 kSteps = 800u, kPerTick = 4u;
	static constexpr uint32 kArms = 4u, kRep = 6u;
	static constexpr uint32 kSignPass = 10u;
	static constexpr float  kFlatRel = 1.0e-6f;
	// ⭐ **가르는 자리** — 시각 `< kKeepFrom` 을 끊고, 채점은 시각 `kKeepFrom` 하나로 한다.
	//   ⚠️ 마지막 시각(`kTime-1`)에는 표적이 없으므로 마지막 **예측** 시각이 `kTime-2` 다.
	static constexpr uint32 kKeepFrom = kTime - 2u;      // 6
	// 「없음」 심볼 — 활성 심볼이 `kStateAx + id` 라 그 바로 뒤 칸이다.
	static constexpr uint32 kNone = MLTP3Ctx::kStateAx + kN;
	static constexpr uint32 kSymVocab = kNone + 1u;

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
	inline static Array<float> _trVal, _trSym, _teVal, _teSym, _teTgt;
	inline static float _run[kRep];
	inline static float _ce[kArms][kSeeds];
	inline static float _ceA[kArms][kSeeds], _ceB[kArms][kSeeds];
	inline static float _pre0[kSeeds];
	inline static float _floorTe[kSeeds];
	inline static bool  _seedOk[kSeeds];

	inline static uint32 _qWait = 0u;
	static void _ToBody() { _qWait = MLTEvalGate::kDelay; _st = kQuiesce; }

	static uint32 _Reps() { return (_arm == 3u) ? 1u : kRep; }
	static const char* _ArmName()
	{
		return (_arm == 0u) ? "㈀ 온전" : ((_arm == 1u) ? "㈁ 끊음" : ((_arm == 2u) ? "㈂ 무작위" : "㈃ lr=0"));
	}

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] ⏳ **회차 60 · 과거 활성이 쓰이나**(⭐ **새 상위 캔버스**)\n");
		LogA("[mlt] ⏳   시각 0..%u 의 활성을 끊고 %u 만 남긴다 — **채점은 시각 %u 의 표적뿐**(학습은 전부)\n",
			kKeepFrom - 1u, kKeepFrom, kKeepFrom);
		LogA("[mlt] ⏳   자는 회차 59 그대로(R=%u · 평균 + 분할 반쪽) · 어휘 %u(마지막 = 「없음」)\n",
			kRep, kSymVocab);
		LogA("[mlt] ⏳   ⚠️ ㉡(눈감기)이 **아니다** — 컨텍스트에 원본 패치가 없어 이미 눈감은 상태다\n");
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
				// ⭐ 시험 복사바닥 — ⚠️ **채점과 같은 자리**(시각 `kKeepFrom` 하나)에서 잰다.
				//   λ·M 은 여전히 **학습 코퍼스**에서 고른다(바닥에 일부러 유리하게).
				Array<float> marg; _tr.Marginal(marg);
				float c1 = 0.0f, c2 = 0.0f, l1 = 0.0f, l2 = 0.0f;
				_tr.BestCopy(marg, c1, c2, l1, l2, kKeepFrom);
				const float t1 = (float)_te.CeCopy(marg, l1, false, kKeepFrom);
				const float t2 = (float)_te.CeCopy(marg, l2, true, kKeepFrom);
				_floorTe[_seed] = (t1 < t2) ? t1 : t2;
				_MaskTgt();
				LogA("[mlt] ⏳ 씨앗 %2u · 시험 복사바닥(시각 %u) **%.4f**\n",
					_seed, kKeepFrom, (double)_floorTe[_seed]);
				_arm = 0u; _rep = 0u; _ToBody();
			}
		}
	}

	// ⚠️ **평가용 표적** — 시각 `kKeepFrom` 밖의 활성 표적을 전부 무효로 만든다.
	//   ★ `ReadLoss` 는 **유효 표적 수로 나눈다**(`_valid`)므로 평균의 뜻이 안 흔들린다.
	static void _MaskTgt()
	{
		const uint32 n = kTestPool * MLTP3Ctx::kRows;
		_teTgt.Reset(0);
		for (uint32 i = 0; i < n; ++i) _teTgt.Add(_te.Tgt()[i]);
		const float ign = (float)kN;
		for (uint32 ctx = 0; ctx < kTestCtx; ++ctx)
			for (uint32 t = 0; t < kTime; ++t)
			{
				if (t == kKeepFrom) continue;
				const uint32 base = MLTP3Ctx::Row(ctx, t, MLTP3Ctx::kStateAx);
				for (uint32 j = 0; j < MLTP3Ctx::kPersist; ++j) _teTgt.Data()[base + j] = ign;
			}
	}

	// ⭐ 이 팔의 입력을 만든다 — **시각 `< kKeepFrom` 의 활성 슬롯만** 바꾼다.
	//   ⚠️ 상태 슬롯 전부와 시각 `kKeepFrom` 이후는 **네 팔에서 손대지 않는다**.
	static void _CutPool(const MLTP3Ctx& C, uint32 nCtx, uint32 cor, Array<float>& val, Array<float>& sym)
	{
		const uint32 n = (nCtx / kBatch) * MLTP3Ctx::kRows;
		val.Reset(0); sym.Reset(0);
		for (uint32 i = 0; i < n; ++i) { val.Add(C.Val()[i]); sym.Add(C.Sym()[i]); }
		if (_arm == 0u || _arm == 3u) return;                  // 온전 · `lr=0` 은 그대로
		for (uint32 ctx = 0; ctx < nCtx; ++ctx)
			for (uint32 t = 0; t < kKeepFrom; ++t)
			{
				const uint32 base = MLTP3Ctx::Row(ctx, t, MLTP3Ctx::kStateAx);
				for (uint32 j = 0; j < MLTP3Ctx::kPersist; ++j)
				{
					if (_arm == 1u) { sym.Data()[base + j] = (float)kNone; val.Data()[base + j] = 0.0f; }
					else
					{
						// ⚠️ 코퍼스마다 다른 난수여야 한다(학습·시험이 같은 열을 쓰면 그것이 신호가 된다).
						const uint32 key = _seed * 7919u + cor * 1000003u + ctx * 131u + t * 17u + j;
						const uint32 h1 = MLTWorld::Hash(key, MLTSalt::Start, 41u);
						const uint32 h2 = MLTWorld::Hash(key, MLTSalt::Start, 42u);
						sym.Data()[base + j] = (float)(MLTP3Ctx::kStateAx + (h1 % kN));
						val.Data()[base + j] = MLTWorld::Unit(h2);
					}
				}
			}
	}

	static void _BodyBegin(RHI* rhi)
	{
		if (!_M.Setup(rhi, kSymVocab, kN, MLTP3Ctx::kAxes, kTime)) { _Fail("몸통 준비"); return; }
		_CutPool(_tr, kNCtx, 0u, _trVal, _trSym);
		_CutPool(_te, kTestCtx, 1u, _teVal, _teSym);
		if (!_M.UploadPool(_trVal, _tr.Tgt(), kPoolSteps) || !_M.UploadSymbolPool(_trSym, kPoolSteps))
		{ _Fail("학습 풀 업로드"); return; }
		_step = 0u;
		if (_arm == 3u && _rep == 0u) { _pre = true; _SwitchToTest(); return; }
		_pre = false; _st = kBodyTrain;
	}

	static bool _SwitchToTest()
	{
		if (!_M.UploadPool(_teVal, _teTgt, kTestPool) || !_M.UploadSymbolPool(_teSym, kTestPool))
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
			_pre0[_seed] = ce; _pre = false;
			if (!_M.UploadPool(_trVal, _tr.Tgt(), kPoolSteps) || !_M.UploadSymbolPool(_trSym, kPoolSteps))
			{ _Fail("학습 풀 복귀"); return; }
			_step = 0u; _st = kBodyTrain; return;
		}
		_run[_rep] = ce;
		if (++_rep < _Reps()) { _ToBody(); return; }
		_Agg();
	}

	// 평균 + 분할 반쪽(회차 59 가 세운 자 — 그대로 쓴다).
	static void _Agg()
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
		uint32 a1 = 0u, a2 = 0u, b1 = 0u, b2 = 0u;
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
			if (_ceA[1][s] > _ceA[0][s]) ++a1;
			if (_ceA[2][s] > _ceA[0][s]) ++a2;
			if (_ceB[1][s] > _ceB[0][s]) ++b1;
			if (_ceB[2][s] > _ceB[0][s]) ++b2;
		}
		if (ok > 0u) { for (uint32 a = 0; a < kArms; ++a) m[a] /= ok; mf /= ok; }
		const bool split = (a1 >= kSignPass) && (a2 >= kSignPass) && (b1 >= kSignPass) && (b2 >= kSignPass);
		const bool plumb = (flat == ok) && (beat >= kSignPass) && _finite;
		const bool p1 = (t1 >= kSignPass), p2 = (t2 >= kSignPass);

		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] ⏳ **회차 60 · 과거 활성이 쓰이나** — 읽은 씨앗 %u/%u\n", ok, kSeeds);
		LogA("[mlt] ⏳   배관 — ㈃ 평탄 **%u/%u** · ㈀ 이 바닥을 넘음 **%u/%u** → %s\n",
			flat, ok, beat, kSeeds, plumb ? "통과" : "⛔");
		LogA("[mlt] ⏳   평균 CE(시각 %u 만) — 시험바닥 **%.4f** · ㈀ **%.4f** · ㈁ **%.4f** · ㈂ **%.4f**\n",
			kKeepFrom, mf, m[0], m[1], m[2]);
		LogA("[mlt] ⏳   **위생 분할 반쪽** — A(㈁>㈀ %u · ㈂>㈀ %u) · B(%u · %u) · 각 필요 %u → %s\n",
			a1, a2, b1, b2, kSignPass, split ? "통과" : "⛔");
		LogA("[mlt] ⏳   **표제** — ㈁ 끊음>㈀ **%u/%u** · ㈂ 무작위>㈀ **%u/%u**(각 필요 %u)\n",
			t1, kSeeds, t2, kSeeds, kSignPass);
		if (!plumb)
			LogA("[mlt] ⏳   ⭐ 판정 = ⛔ **판정불가** — 배관이 안 섰다(평탄/바닥)\n");
		else if (!split)
			LogA("[mlt] ⏳   ⭐ 판정 = ⛔ **판정불가** — 이 표본 수(시각 하나)에서는 **자가 안 통한다**\n");
		else if (p1 && p2)
			LogA("[mlt] ⏳   ⭐ 판정 = ✅ **활성이 시간을 건너 하중을 받는다** — 몸통은 직전 시각만 보는 것이 아니다\n");
		else if (!p1 && !p2)
			LogA("[mlt] ⏳   ⭐ 판정 = ⭐ **몸통은 「직전 시각 + 상태」만 쓴다** — 큰 발견이다 ⇒ **압축(`q`) 재질문**을 연다\n");
		else
			LogA("[mlt] ⏳   ⭐ 판정 = ⚠️ **한 팔만** 나빠졌다 ⇒ **판정불가**(끊음과 무작위는 뜻이 다르다)\n");
		LogA("[mlt] ⏳   ⚠️ 고정 %u문맥 · 채점 표적 %u개의 진단이다 — 절대 성능으로 인용하지 않는다\n",
			kNCtx, kTestCtx * MLTP3Ctx::kPersist);
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		_E.Destroy(); _done = true;
	}

	static void _Fail(const char* why)
	{
		LogA("[mlt] ⏳ ⛔ %s (씨앗 %u · 팔 %u · 반복 %u · 단계 %u)\n", why, _seed, _arm, _rep, _st);
		_E.Destroy(); _done = true;
	}
};
