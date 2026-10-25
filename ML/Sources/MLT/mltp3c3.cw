// mltp3c3.cw — ⏳ 회차 52 · **P3-C3: 문맥 수를 늘리면 일반화가 서나** (`-mltp3c3`)
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 52 다.**
// ⚠️ **「크기로 밀기」가 아니다** — 회차 51 이 *"학습에서는 복사를 12/12 넘는데 시험에서는 0/12"*
//   를 냈고, 그 원인 후보 1번이 **표본이 64개**라는 사실이다. 이 회차는 **그 사실을 고친다.**
// ⚠️⚠️ 배치(앵커·슬롯 순서)는 **한 줄도 안 고친다** — 문맥 수와 섞이면 둘 다 못 읽는다.
// ══════════════════════════════════════════════════════════════════════════════
//
// ── 팔 셋(문맥 수) — ⭐ **에폭을 맞춘다**(회차 24 가 등록한 그 형식) ──────────
//   ㈀ **64** 문맥 · 400 스텝   ← ⚠️ **회차 51 재현 검사**(같은 코퍼스 · 같은 걸음)
//   ㈁ **128** 문맥 · 800 스텝
//   ㈂ **512** 문맥 · 3200 스텝
//   ⭐ **조립은 한 번만 한다** — 512 문맥을 모으고 앞에서 잘라 쓴다(에피소드가 결정적이라 ㈀ 는
//     회차 51 과 **글자 그대로 같은 64개**다). ⏱️ 그래서 팔이 셋인데 리드백은 한 벌이다.
//   ⚠️ **시험 코퍼스는 셋이 공유한다**(에피소드 101..164 · 64개 고정).
//
// ── 판정 ──────────────────────────────────────────────────────────────────
//   표제① `CE(㈂ 시험) < 시험 복사바닥` 10/12   ⇒ 일반화가 서나
//   표제②(추세) 시험 CE 가 문맥 수와 **완전 단조 감소** 6/12(귀무 1/6)
//   위생 ㈀ 재현(학습 **0.6989 ±0.02** · 시험 **1.3717 ±0.05**) · 시험 복사바닥 **1.1275 ±0.01**

using namespace PE;

class MLTP3C3
{
public:
	static void Tick(RHI* rhi)
	{
		if (_done || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltp3c3"))
		{
			LogA("[mlt] ⏳ 회차 52는 **꺼져 있다**(`-mltp3c3`) — 문맥 수를 늘리면 일반화가 서나\n");
			_done = true; return;
		}
		if (!_banner) { _Banner(); _banner = true; }
		if (_seed >= kSeeds) { _Summary(); return; }
		if (_st == kEncInit)  { _EncBegin(rhi); return; }
		if (_st == kEncTrain) { _EncTrain(); return; }
		if (_st == kGather)   { _Gather(); return; }
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
	static constexpr uint32 kRows = MLTP3Ctx::kRows;
	static constexpr uint32 kCandidates = MLTP2Cfg::kPatches * kLocal;
	static constexpr uint32 kArms = 3u;
	static constexpr uint32 kNCtx[kArms]  = { 64u, 128u, 512u };
	static constexpr uint32 kSteps[kArms] = { 400u, 800u, 3200u };   // ⭐ 에폭을 맞춘다
	static constexpr uint32 kMaxCtx = 512u, kTestCtx = 64u;
	static constexpr uint32 kTestEpi = 101u, kTrainEpi = 1u;
	static constexpr uint32 kGroup = kEncF / kTime;                  // 한 번에 올리는 문맥 수(4)
	static constexpr uint32 kBodyPerTick = 4u;
	static constexpr uint32 kSignPass = 10u, kTrendPass = 6u;
	// 회차 51 재현 문턱
	static constexpr float kTrExpect = 0.6989f, kTrTol = 0.02f;
	static constexpr float kTeExpect = 1.3717f, kTeTol = 0.05f;
	static constexpr float kFloorExpect = 1.1275f, kFloorTol = 0.01f;

	enum { kEncInit, kEncTrain, kGather, kBodyInit, kBodyTrain, kBodyEval };

	inline static MLTP2Enc _E;
	inline static MLTModel _M;
	inline static MLTP3Ctx _train, _test;
	inline static bool _done = false, _banner = false, _encSetup = false, _finite = true;
	inline static bool _pending = false, _onTest = false;
	inline static uint32 _seed = 0u, _st = kEncInit, _step = 0u, _ev = 0u, _arm = 0u;
	inline static uint32 _cor = 0u, _gGrp = 0u, _gIdx = 0u;
	inline static double _sumCe = 0.0;
	inline static Array<float> _code, _norm;
	inline static float _ceTr[kArms][kSeeds], _ceTe[kArms][kSeeds];
	inline static float _floorTeA[kArms][kSeeds], _floorTrA[kArms][kSeeds];
	inline static float _accSlot[kSeeds], _accSet[kSeeds];
	inline static bool  _seedOk[kSeeds];

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] ⏳ **회차 52 · P3-C3 — 문맥 수를 늘리면 일반화가 서나**\n");
		LogA("[mlt] ⏳   팔 셋(에폭 맞춤): %u문맥/%u스텝 · %u/%u · %u/%u — 조립은 한 번(512)만\n",
			kNCtx[0], kSteps[0], kNCtx[1], kSteps[1], kNCtx[2], kSteps[2]);
		LogA("[mlt] ⏳   시험 코퍼스 %u문맥(ep %u..) 공유 · 배치는 회차 50/51 그대로(앵커 없음)\n",
			kTestCtx, kTestEpi);
		LogA("[mlt] ⏳   표제① ㈂시험 < 시험복사바닥 %u/%u · 표제②(추세) 완전단조 %u/%u(귀무 1/6)\n",
			kSignPass, kSeeds, kTrendPass, kSeeds);
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
		_train.Begin(kMaxCtx, kN);
		_test.Begin(kTestCtx, kN);
		_cor = 0u; _gGrp = 0u; _gIdx = 0u; _pending = false; _st = kGather;
	}

	// ⏱️ 그룹(`kGroup` 문맥 = `kEncF` 프레임)씩 **한 번에** 올린다 — `Write` 는 동기이고 무겁다.
	static void _Gather()
	{
		MLTP3Ctx& C = (_cor == 0u) ? _train : _test;
		const uint32 nCtx = (_cor == 0u) ? kMaxCtx : kTestCtx;
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
					// ⭐ 상태는 GPU 와 무관하다 — 그린 그 자리에서 바로 적는다.
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
			if (++_cor >= 2u) { _AfterGather(); return; }
		}
	}

	// ⚠️⚠️ **바닥은 팔마다 따로 맞춘다**(회차 52 1차가 밟은 자리 · 등록을 고쳤다) —
	//   팔 `a` 의 `M`·λ 는 **그 팔이 실제로 본 앞 `nCtx` 문맥**에서 고르고, 그 `M`·λ 로 **공유
	//   시험 코퍼스**를 평가한다. ⇒ ㈀ 의 바닥이 정의상 회차 51 과 같아져 재현 검사가 뜻을 갖는다.
	static void _AfterGather()
	{
		for (uint32 a = 0; a < kArms; ++a)
		{
			_train.SetActive(kNCtx[a]);
			Array<float> marg;
			_train.Marginal(marg);
			float c1 = 0.0f, c2 = 0.0f, l1 = 0.0f, l2 = 0.0f;
			_train.BestCopy(marg, c1, c2, l1, l2);
			_floorTrA[a][_seed] = (c1 < c2) ? c1 : c2;
			// ⚠️ 시험은 **학습에서 고른** `M`·λ 로 평가한다(시험 라벨로 고르면 오라클이다).
			const float t1 = (float)_test.CeCopy(marg, l1, false);
			const float t2 = (float)_test.CeCopy(marg, l2, true);
			_floorTeA[a][_seed] = (t1 < t2) ? t1 : t2;
			LogA("[mlt] ⏳ 씨앗 %2u · %4u문맥 바닥 — 학습 **%.4f**(λ%.2f/%.2f) · 시험 **%.4f**\n",
				_seed, kNCtx[a], (double)_floorTrA[a][_seed], (double)l1, (double)l2,
				(double)_floorTeA[a][_seed]);
		}
		_train.SetActive(kNCtx[0]);   // 눈금(복사 정확도)은 ㈀ 기준 — 회차 51 과 같은 자다
		_train.CopyAcc(_accSlot[_seed], _accSet[_seed]);
		_arm = 0u; _st = kBodyInit;
	}

	static void _BodyBegin(RHI* rhi)
	{
		if (!_M.Setup(rhi, MLTP3Ctx::kStateAx + kN, kN, MLTP3Ctx::kAxes, kTime)) { _Fail("몸통 준비"); return; }
		if (_M.Rows() != kRows) { _Fail("몸통 행 수 불일치"); return; }
		if (!_UploadTrain()) return;
		// ⚠️ 학습 전 평가를 안 한다 — 이 회차의 관문은 전부 **절대 CE**(복사 바닥과의 비교)다.
		_step = 0u; _onTest = false; _st = kBodyTrain;
	}

	// ⭐ 팔마다 **앞에서 잘라** 쓴다 — 조립은 한 벌이고 ㈀ 는 회차 51 과 같은 64개다.
	static bool _UploadTrain()
	{
		const uint32 nSteps = kNCtx[_arm] / kBatch;
		Array<float> v, t, s; v.Reset(0); t.Reset(0); s.Reset(0);
		const uint32 n = nSteps * kRows;
		for (uint32 i = 0; i < n; ++i) { v.Add(_train.Val()[i]); t.Add(_train.Tgt()[i]); s.Add(_train.Sym()[i]); }
		if (!_M.UploadPool(v, t, nSteps) || !_M.UploadSymbolPool(s, nSteps))
		{ _Fail("학습 풀 업로드"); return false; }
		return true;
	}

	static bool _UploadTest()
	{
		const uint32 nSteps = kTestCtx / kBatch;
		Array<float> v, t, s; v.Reset(0); t.Reset(0); s.Reset(0);
		const uint32 n = nSteps * kRows;
		for (uint32 i = 0; i < n; ++i) { v.Add(_test.Val()[i]); t.Add(_test.Tgt()[i]); s.Add(_test.Sym()[i]); }
		if (!_M.UploadPool(v, t, nSteps) || !_M.UploadSymbolPool(s, nSteps))
		{ _Fail("시험 풀 업로드"); return false; }
		return true;
	}

	static void _BeginEval() { _st = kBodyEval; _ev = 0u; _sumCe = 0.0; }

	static void _BodyEval()
	{
		const uint32 nSteps = _onTest ? (kTestCtx / kBatch) : (kNCtx[_arm] / kBatch);
		if (_ev > 0u)
		{
			float ls = 0.0f;
			if (!_M.ReadLoss(ls)) { _Fail("손실 리드백"); return; }
			if (!(ls == ls) || ls > 1.0e30f) _finite = false;
			_sumCe += (double)ls;
		}
		if (_ev < nSteps)
		{
			_M.SelectStep(_ev);
			if (!_M.Forward()) { _Fail("평가 forward"); return; }
			++_ev; return;
		}
		const float mean = (float)(_sumCe / (double)nSteps);
		if (!_onTest)
		{
			_ceTr[_arm][_seed] = mean;
			_onTest = true;
			if (!_UploadTest()) return;
			_BeginEval(); return;
		}
		_ceTe[_arm][_seed] = mean;
		_ArmDone();
	}

	static void _BodyTrain()
	{
		if (_step >= kSteps[_arm]) { _onTest = false; _BeginEval(); return; }
		for (uint32 i = 0; i < kBodyPerTick && _step < kSteps[_arm]; ++i)
		{
			_M.SelectStep(_step % (kNCtx[_arm] / kBatch));
			if (!_M.Forward() || !_M.Backward() || !_M.AdamStep(1.0f)) { _Fail("몸통 스텝"); return; }
			++_step;
		}
	}

	static void _ArmDone()
	{
		LogA("[mlt] ⏳   씨앗 %2u · %4u문맥/%4u스텝 — 학습 **%.4f** / 시험 **%.4f** (시험바닥 %.4f) %s\n",
			_seed, kNCtx[_arm], kSteps[_arm], (double)_ceTr[_arm][_seed], (double)_ceTe[_arm][_seed],
			(double)_floorTeA[_arm][_seed], (_ceTe[_arm][_seed] < _floorTeA[_arm][_seed]) ? "✅" : "⛔");
		if (++_arm < kArms) { _st = kBodyInit; return; }
		_seedOk[_seed] = _finite;
		++_seed; _st = kEncInit;
	}

	static void _Summary()
	{
		double tr[kArms], te[kArms], fA[kArms], fT0 = 0.0, fR = 0.0, as = 0.0, ae = 0.0;
		for (uint32 a = 0; a < kArms; ++a) { tr[a] = 0.0; te[a] = 0.0; fA[a] = 0.0; }
		uint32 ok = 0u, pass = 0u, trend = 0u;
		for (uint32 s = 0; s < kSeeds; ++s)
		{
			if (!_seedOk[s]) continue;
			++ok;
			for (uint32 a = 0; a < kArms; ++a)
			{ tr[a] += _ceTr[a][s]; te[a] += _ceTe[a][s]; fA[a] += _floorTeA[a][s]; }
			// ⚠️ 회귀 검사는 **㈀ 의 바닥**(64문맥에서 맞춘 것)으로 한다 — 회차 51 의 정의와 같아야 한다.
			fT0 += _floorTeA[0][s]; fR += _floorTrA[0][s]; as += _accSlot[s]; ae += _accSet[s];
			if (_ceTe[kArms - 1u][s] < _floorTeA[kArms - 1u][s]) ++pass;
			if (_ceTe[0][s] > _ceTe[1][s] && _ceTe[1][s] > _ceTe[2][s]) ++trend;
		}
		if (ok > 0u)
		{
			for (uint32 a = 0; a < kArms; ++a) { tr[a] /= ok; te[a] /= ok; fA[a] /= ok; }
			fT0 /= ok; fR /= ok; as /= ok; ae /= ok;
		}
		const double fT = fT0;
		const bool repro = (Abs((float)tr[0] - kTrExpect) <= kTrTol)
			&& (Abs((float)te[0] - kTeExpect) <= kTeTol)
			&& (Abs((float)fT0 - kFloorExpect) <= kFloorTol);
		const bool p1 = (pass >= kSignPass), p2 = (trend >= kTrendPass);

		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] ⏳ **회차 52 · P3-C3 결과** — 읽은 씨앗 %u/%u\n", ok, kSeeds);
		LogA("[mlt] ⏳   위생 ㈀ 회차 51 재현 — 학습 **%.4f**(%.4f±%.2f) · 시험 **%.4f**(%.4f±%.2f) · 시험바닥 **%.4f**(%.4f±%.2f) → %s\n",
			tr[0], (double)kTrExpect, (double)kTrTol, te[0], (double)kTeExpect, (double)kTeTol,
			fT, (double)kFloorExpect, (double)kFloorTol, repro ? "통과" : "⛔");
		for (uint32 a = 0; a < kArms; ++a)
			LogA("[mlt] ⏳   %4u문맥/%4u스텝 — 학습 **%.4f** · 시험 **%.4f** · **그 팔의 시험바닥 %.4f** → %s\n",
				kNCtx[a], kSteps[a], tr[a], te[a], fA[a], (te[a] < fA[a]) ? "넘음" : "못넘음");
		LogA("[mlt] ⏳   ㈀ 바닥 — 학습 복사 **%.4f** · 시험 복사 **%.4f** · 정확도 슬롯 %.3f 집합 %.3f\n",
			fR, fT, as, ae);
		LogA("[mlt] ⏳   **표제① ㈂시험 < 시험바닥 — %u/%u**(필요 %u) → %s\n", pass, kSeeds, kSignPass, p1 ? "통과" : "⛔");
		LogA("[mlt] ⏳   **표제②(추세) 시험 CE 완전단조 감소 — %u/%u**(필요 %u) → %s\n", trend, kSeeds, kTrendPass, p2 ? "통과" : "⛔");
		if (!repro)
			LogA("[mlt] ⏳   ⭐ 판정 = ⛔ **판정불가**(㈀ 재현 실패) — 코퍼스/배관이 회차 51 과 다르다\n");
		else if (p1)
			LogA("[mlt] ⏳   ⭐ 판정 = ✅ **일반화가 섰다** ⇒ 회차 53 = ㉠ 을 그 체제에서 다시 잰다(회차 50 보류 해제)\n");
		else if (p2)
			LogA("[mlt] ⏳   ⭐ 판정 = ⚠️ **돕지만 턱없이 느리다**(회차 24 와 같은 얼굴) ⇒ 회차 53 = **표적**(슬롯 순서)\n");
		else
			LogA("[mlt] ⏳   ⭐ 판정 = ⛔ **표본 수가 축이 아니다** ⇒ 회차 53 = 표적/배치(슬롯 순서·앵커)\n");
		LogA("[mlt] ⏳   ⚠️ 어느 갈래든 **크기(층·폭)를 안 늘린다.**\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		_E.Destroy(); _done = true;
	}

	static void _Fail(const char* why)
	{
		LogA("[mlt] ⏳ ⛔ %s (씨앗 %u · 팔 %u · 코퍼스 %u · 단계 %u)\n", why, _seed, _arm, _cor, _st);
		_E.Destroy(); _done = true;
	}
};
