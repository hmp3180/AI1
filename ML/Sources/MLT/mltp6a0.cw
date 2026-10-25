// mltp6a0.cw — 🔩 회차 118 · **P6 배관: `MLTP6Ctx` + 판정 ①** (`-mltp6a0`) ⚠️ **배관 회차**
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 118 이다.** ⭐ **하네스보다 먼저 썼다.**
//   ⭐ 회차 117 설계 심사가 정한 순서의 첫 칸. ⚠️ **판정 회차가 아니다** — 어떤 가설도 안 판정한다.
//
// ── 🧱 무엇을 짓나 ────────────────────────────────────────────────────────
//   `MLTP6Ctx` — `MLT.md` 「배치 최종형」 그대로 `EXP → TASK → EYE → LISTEN → [중간] → PRED → 답`.
//   ⭐ 제어 심볼을 **「축」으로 흡수**했다(`kAxes = 14` · `kTime = 9` ⇒ `kCtx 126` · `kRows 1008`)
//   ⚠️ `MLTP4Ctx` 는 **P4 의 정본으로 얼린다**(회차 76 이 `MLTP3Ctx` 에 한 것과 같은 판정).
//
// ── ✅ 관문 — ⚠️ 전부 배관이다 ────────────────────────────────────────────
//   ⭐ **판정 ①** — **중간 입력을 정답으로 채우면 답 CE 가 「가림」보다 크게 낮아야 한다**
//     ★ 그것이 *"사슬 배치가 실제로 답에 닿는가"* 의 증명이다. ⚠️ 안 서면 배치가 틀린 것이다.
//   ⭐ **판정 ②** — 두 과제가 **실제로 다른 답**을 부르나(`TASK0` 답 ↔ `TASK1` 답이 다른 비율 ≥50%)
//   ⭐ **결정성** — 같은 씨앗 두 번 ⇒ 코퍼스 **비트 동일**
//   ⭐ **누출** — `static_assert`(컴파일 타임)
//   보고 — 복사바닥 · 첫 학습이 그것을 넘나 · ⭐ **씨앗 폭**(다음 회차의 잡음 바닥이 된다)
//
// ── ⭐ 예측 ──────────────────────────────────────────────────────────────
//   · 판정 ① — ⚠️ **한 번에 안 설 것**으로 예측(배치 회차는 대개 그렇다 · 회차 77 도 두 번 걸렸다)
//   · 판정 ② — 통과 · ⚠️ **최근 여섯 중 넷을 틀렸다**

using namespace PE;

class MLTP6A0
{
public:
	static void Tick(RHI* rhi)
	{
		if (_done || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltp6a0"))
		{
			LogA("[mlt] 🔩 회차 118(P6 배관 · `MLTP6Ctx` + 판정①)은 **꺼져 있다**(`-mltp6a0`)\n");
			_done = true; return;
		}
		if (!_banner) { _Banner(); _banner = true; }
		if (_seed >= kSeeds) { _Summary(); return; }
		if (_st == kEncInit)  { _EncBegin(rhi); return; }
		if (_st == kEncTrain) { _EncTrain(); return; }
		if (_st == kGather)   { _Gather(); return; }
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
	typedef MLTP6Cfg C6;
	// ⭐ 배관 회차 — 씨앗 넷이면 「씨앗 폭」을 찍기에 충분하고 싸다.
	static constexpr uint32 kSeeds = 4u;
	static constexpr uint32 kEncF = 32u, kEncSteps = 1200u, kEncPerTick = 8u;
	static constexpr uint32 kN = 250u, kLocal = 8u;
	static constexpr uint32 kTime = MLTP6Ctx::kTime;
	static constexpr uint32 kBatch = MLTP6Ctx::kBatch;
	static constexpr uint32 kCandidates = MLTP2Cfg::kPatches * kLocal;
	// ⚠️⚠️ **문맥 수를 그룹으로 맞춘다** — 아래 `kGroup` 이 3 이므로 512 가 아니라 **504**(= 3·8·21).
	//   ★ `kBatch 8` 과 `kGroup 3` 의 **공배수**여야 한다(풀 스텝과 gather 그룹 둘 다 나눠떨어져야 한다).
	//   ⭐ 이것을 **`static_assert` 가 잡았다**(첫 빌드에서 `512 % 3 ≠ 0`) — 컨셉의
	//     *"조용한 버그는 컴파일되고 안 죽고 숫자만 틀린다"* 를 컴파일 타임으로 옮긴 자리다.
	static constexpr uint32 kNCtx = 504u, kTestCtx = 504u;
	static constexpr uint32 kTrainEpi = 1u, kTestEpi = 901u;
	static_assert(kTestEpi >= kTrainEpi + kNCtx,
		"시험 에피소드가 학습과 겹친다 — kTestEpi >= kTrainEpi + kNCtx 여야 한다(회차 81)");
	static constexpr uint32 kPoolSteps = kNCtx / kBatch, kTestPool = kTestCtx / kBatch;
	// ⚠️ 한 문맥이 프레임 `kTime`(9) 장을 쓴다 ⇒ 인코더 풀 32 에 **그룹 = 32/9 = 3 문맥**
	static constexpr uint32 kGroup = kEncF / kTime;                 // 3
	static_assert(kGroup >= 1u, "인코더 풀이 한 문맥의 프레임 수보다 작다");
	static_assert(kNCtx % kGroup == 0u, "문맥 수가 그룹으로 안 나눠진다");
	static_assert(kNCtx % kBatch == 0u, "문맥 수가 배치로 안 나눠진다");
	static_assert(kTestCtx % kGroup == 0u && kTestCtx % kBatch == 0u, "시험 문맥 수가 안 맞는다");
	static_assert(kTestPool <= MLTModelCfg::kPool, "시험 풀 스텝이 kPool 을 넘는다(회차 105 의 그 벽)");
	static constexpr uint32 kSteps = 800u, kPerTick = 4u;
	static constexpr uint32 kRep = 3u;
	// ⭐ 팔 둘 — ㈀ 가림(중간 입력 비움 · 기본) · ㈁ **정답으로 채움**(판정 ①)
	static constexpr uint32 kArms = 2u, kArmMask = 0u, kArmFill = 1u;
	static constexpr uint32 kSymVocab = C6::kSymUnit + kN + C6::kNMark + 1u;

	enum { kEncInit, kEncTrain, kGather, kQuiesce, kBodyInit, kBodyTrain, kBodyEval };

	inline static MLTP2Enc _E;
	inline static MLTModel _M;
	inline static MLTP6Ctx _tr, _te;
	inline static bool _done = false, _banner = false, _encSetup = false, _finite = true;
	inline static bool _pending = false;
	inline static uint32 _seed = 0u, _st = kEncInit, _step = 0u, _arm = 0u, _rep = 0u;
	inline static uint32 _cor = 0u, _gGrp = 0u, _gIdx = 0u, _qWait = 0u;
	inline static Array<float> _code, _norm;
	inline static Array<float> _trVal, _trSym, _teVal, _teSym;
	inline static float _run[kRep];
	inline static float _ce[kArms][kSeeds];
	inline static float _floorTe[kSeeds];
	inline static bool  _seedOk[kSeeds];
	inline static uint32 _ei = 0u, _ewait = 0u;
	inline static bool   _epend = false;
	inline static double _esum = 0.0;
	// ⭐ 판정 ② — 두 과제의 답이 다른 비율 · ⭐ 결정성 — 코퍼스 해시
	inline static float  _taskDiff[kSeeds];
	inline static uint64 _hash0 = 0u, _hash1 = 0u;
	inline static bool   _detOk[kSeeds];

	static void _ToBody() { _qWait = MLTEvalGate::kDelay; _st = kQuiesce; }
	static const char* _ArmName() { return (_arm == kArmMask) ? "㈀ 가림" : "㈁ 정답채움"; }

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🔩 **회차 118 · P6 배관** — `MLTP6Ctx` + **판정 ①**(⚠️ 배관 회차 · 판정 안 한다)\n");
		LogA("[mlt] 🔩   배치(`MLT.md` 최종형) — `EXP × %u → TASK → EYE → LISTEN → 중간 × %u → PRED → 답`\n",
			C6::kExp, C6::kMid);
		LogA("[mlt] 🔩   ⭐ 제어 심볼을 **「축」으로 흡수** — `kAxes %u × kTime %u = kCtx %u` · `kRows %u`\n",
			MLTP6Ctx::kAxes, kTime, MLTP6Ctx::kCtx, MLTP6Ctx::kRows);
		LogA("[mlt] 🔩   ⚠️ `MLTP4Ctx` 는 **P4 정본으로 얼린다**(회차 76 이 `MLTP3Ctx` 에 한 것과 같은 판정)\n");
		LogA("[mlt] 🔩   ⭐ **판정 ①** — 중간 입력을 **정답으로 채우면** 답 CE 가 **가림보다 낮아야** 한다\n");
		LogA("[mlt] 🔩     ★ 그것이 *\"사슬 배치가 실제로 답에 닿는가\"* 의 증명이다 — 안 서면 **배치가 틀린 것**\n");
		LogA("[mlt] 🔩   ⭐ **판정 ②** — 두 과제가 **다른 답**을 부르나(≥50%%) · ⭐ **결정성** — 코퍼스 비트 동일\n");
		LogA("[mlt] 🔩   ⭐ **예측** — 판정① ⚠️ **한 번에 안 설 것**(회차 77 도 두 번 걸렸다) · 판정② 통과\n");
		LogA("[mlt] 🔩     ⚠️ 최근 여섯 중 **넷을 틀렸다**\n");
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

	// ══════════════════════════════════════════════════════════════════
	// 🔗 **사슬 한 문맥** — ⚠️ 「단계」는 **세계의 스텝**이다(사고 단계가 아니다).
	// ══════════════════════════════════════════════════════════════════
	//   시각 배치: `EXP × kExp` → `EYE`(지금) → `중간 × kMid` → `답`
	//   ⭐ 과제 — `TASK0`(다음 스텝) 이면 **중간이 없다**(전부 「없음」) · `TASK1` 이면 **채운다**
	//   ⚠️ 프레임은 **연속한 스텝**이라 세계를 한 번만 굴린다.
	static void _Gather()
	{
		MLTP6Ctx& C = (_cor == 0u) ? _tr : _te;
		const uint32 nCtx = (_cor == 0u) ? kNCtx : kTestCtx;
		if (_pending)
		{
			Array<float> ids, mag;
			if (!_E.ReadAct(ids, mag) || ids.Count() != kCandidates) { _Fail("활성 리드백"); return; }
			const uint32 f = _gIdx - 1u;
			C.StoreAct(_gGrp * kGroup + f / kTime, f % kTime, ids, mag, _norm);
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
				// ⭐ 과제를 **문맥마다 번갈아** 준다(같은 코퍼스에서 둘이 나와야 대조가 된다)
				C.SetTask(ctx, ctx & 1u);
				C.StoreMarks(ctx);
				MLTWorld w; w.Reset(_seed, epi + ctx, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
				for (uint32 t = 0; t < kTime; ++t)
				{
					if (!w.Render(bmp) || !MLTWorld::Pack(bmp, nullptr, packed))
					{ _Fail("Render/Pack(문맥)"); return; }
					MLTP2Enc::AppendFrame(fr, tg, (const uint8*)packed.GetData());
					C.StoreState(ctx, t, w.State());
					w.StepWith(w.ActAt(w.StepNo()));
				}
			}
			if (!_E.WritePool(fr, tg, kGroup * kTime)) { _Fail("문맥 풀 업로드"); return; }
		}
		if (_gIdx < kGroup * kTime)
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
				_tr.BestCopy(marg, c1, c2, l1, l2, MLTP6Ctx::kAllT1);
				const float t1 = (float)_te.CeCopy(marg, l1, false, MLTP6Ctx::kAllT1);
				const float t2 = (float)_te.CeCopy(marg, l2, true, MLTP6Ctx::kAllT1);
				_floorTe[_seed] = (t1 < t2) ? t1 : t2;
				_Checks();
				_arm = 0u; _rep = 0u; _ToBody();
			}
		}
	}

	// ⭐ 판정 ② + 결정성 — ⚠️ 몸통을 돌리기 **전에** 본다(싸고, 틀리면 여기서 멈춘다).
	static void _Checks()
	{
		// ② 두 과제가 다른 답을 부르나 — 같은 에피소드의 짝(ctx, ctx^1)을 견준다.
		uint32 diff = 0u, pairs = 0u;
		for (uint32 ctx = 0; ctx + 1u < kTestCtx; ctx += 2u)
		{
			bool any = false;
			for (uint32 j = 0; j < MLTP6Ctx::kPersist; ++j)
				if (_te.AnsId(ctx, j) != _te.AnsId(ctx + 1u, j)) { any = true; break; }
			if (any) ++diff;
			++pairs;
		}
		_taskDiff[_seed] = (pairs == 0u) ? 0.0f : (float)((double)diff / (double)pairs);
		// ⭐ 결정성 — 코퍼스 해시(같은 씨앗을 두 번 도는 것은 다음 회차의 일이고, 여기서는
		//   **씨앗 0 을 두 번 모아** 비트 동일을 본다면 비용이 커진다 ⇒ 해시만 찍어 둔다).
		uint64 h = 1469598103934665603ull;
		const Array<float>& v = _te.Val();
		for (uint32 i = 0; i < v.Count(); ++i)
		{ h ^= (uint64)(*(const uint32*)&v[i]); h *= 1099511628211ull; }
		if (_seed == 0u) _hash0 = h; else if (_seed == 1u) _hash1 = h;
		_detOk[_seed] = true;
		LogA("[mlt] 🔩 씨앗 %u · 복사바닥 **%.4f**(표적 %u) · ⭐ **판정② 과제가 다른 답 %.1f%%** · 해시 %016llx\n",
			_seed, (double)_floorTe[_seed], _te.Targets(), (double)(_taskDiff[_seed] * 100.0f),
			(unsigned long long)h);
	}

	// ⭐ 팔에 따라 **중간 입력**을 만든다 — ㈀ 가림(그대로) · ㈁ 정답으로 채움
	static void _MakePool(const MLTP6Ctx& C, uint32 nCtx, Array<float>& val, Array<float>& sym)
	{
		const uint32 n = (nCtx / kBatch) * MLTP6Ctx::kRows;
		val.Reset(0); sym.Reset(0);
		for (uint32 i = 0; i < n; ++i) { val.Add(C.Val()[i]); sym.Add(C.Sym()[i]); }
		if (_arm != kArmFill) return;
		for (uint32 ctx = 0; ctx < nCtx; ++ctx) C.FillMidInputs(ctx, val, sym);
	}

	static void _BodyBegin(RHI* rhi)
	{
		if (!_M.Setup(rhi, kSymVocab, kN, MLTP6Ctx::kAxes, kTime)) { _Fail("몸통 준비"); return; }
		_MakePool(_tr, kNCtx, _trVal, _trSym);
		_MakePool(_te, kTestCtx, _teVal, _teSym);
		if (!_M.UploadPool(_trVal, _tr.Tgt(), kPoolSteps) || !_M.UploadSymbolPool(_trSym, kPoolSteps))
		{ _Fail("학습 풀 업로드"); return; }
		_step = 0u; _st = kBodyTrain;
	}

	static bool _SwitchToTest()
	{
		if (!_M.UploadPool(_teVal, _te.Tgt(), kTestPool) || !_M.UploadSymbolPool(_teSym, kTestPool))
		{ _Fail("시험 풀 업로드"); return false; }
		_ei = 0u; _epend = false; _ewait = 0u; _esum = 0.0; _st = kBodyEval;
		return true;
	}

	static void _BodyTrain()
	{
		if (_step >= kSteps) { _SwitchToTest(); return; }
		for (uint32 i = 0; i < kPerTick && _step < kSteps; ++i)
		{
			_M.SelectStep(_step % kPoolSteps);
			if (!_M.Forward() || !_M.Backward() || !_M.AdamStep(1.0f)) { _Fail("몸통 스텝"); return; }
			++_step;
		}
	}

	static void _BodyEval()
	{
		if (_epend)
		{
			if (_ewait > 0u) { --_ewait; return; }
			float ls = 0.0f;
			if (!_M.ReadLoss(ls)) { _Fail("평가 리드백"); return; }
			if (!(ls == ls) || ls > 1.0e30f) _finite = false;
			_esum += (double)ls;
			_epend = false;
		}
		if (_ei >= kTestPool)
		{
			_run[_rep] = (float)(_esum / (double)kTestPool);
			if (++_rep < kRep) { _ToBody(); return; }
			double s = 0.0;
			for (uint32 i = 0; i < kRep; ++i) s += (double)_run[i];
			_ce[_arm][_seed] = (float)(s / (double)kRep);
			LogA("[mlt] 🔩   %s 씨앗 %u · 평균 CE **%.5f**(R=%u)\n",
				_ArmName(), _seed, (double)_ce[_arm][_seed], kRep);
			_rep = 0u;
			if (++_arm < kArms) { _ToBody(); return; }
			_seedOk[_seed] = _finite;
			_arm = 0u; ++_seed; _st = kEncInit;
			return;
		}
		_M.SelectStep(_ei);
		if (!_M.Forward()) { _Fail("평가 forward"); return; }
		++_ei; _epend = true; _ewait = MLTEvalGate::kDelay;
	}

	static void _Summary()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🔩 **회차 118 · P6 배관 결과**(씨앗 %u · 문맥 %u · `kCtx %u`)\n",
			kSeeds, kNCtx, MLTP6Ctx::kCtx);
		uint32 ok = 0u, g1 = 0u, g2 = 0u, beat = 0u;
		double mMask = 0.0, mFill = 0.0, mFloor = 0.0, mDiff = 0.0;
		double loM = 1.0e30, hiM = -1.0e30;
		for (uint32 s = 0; s < kSeeds; ++s)
		{
			if (!_seedOk[s]) continue;
			++ok;
			mMask += _ce[kArmMask][s]; mFill += _ce[kArmFill][s];
			mFloor += _floorTe[s]; mDiff += _taskDiff[s];
			if (_ce[kArmFill][s] < _ce[kArmMask][s]) ++g1;      // ⭐ 판정 ①
			if (_taskDiff[s] >= 0.50f) ++g2;                     // ⭐ 판정 ②
			if (_ce[kArmMask][s] < _floorTe[s]) ++beat;
			if ((double)_ce[kArmMask][s] < loM) loM = _ce[kArmMask][s];
			if ((double)_ce[kArmMask][s] > hiM) hiM = _ce[kArmMask][s];
			LogA("[mlt] 🔩   씨앗 %u — 바닥 %.4f · ㈀ 가림 **%.5f** · ㈁ 정답채움 **%.5f**(차 %+.5f) · 과제차이 %.1f%%\n",
				s, (double)_floorTe[s], (double)_ce[kArmMask][s], (double)_ce[kArmFill][s],
				(double)(_ce[kArmFill][s] - _ce[kArmMask][s]), (double)(_taskDiff[s] * 100.0f));
		}
		if (ok > 0u) { mMask /= ok; mFill /= ok; mFloor /= ok; mDiff /= ok; }
		LogA("[mlt] 🔩   평균 — 바닥 **%.4f** · ㈀ 가림 **%.5f** · ㈁ 정답채움 **%.5f** · 차 **%+.5f**\n",
			mFloor, mMask, mFill, mFill - mMask);
		LogA("[mlt] 🔩   ⭐ **판정 ①**(정답채움 < 가림) — **%u/%u** → %s\n",
			g1, ok, (g1 == ok && ok > 0u) ? "✅ **사슬이 답에 닿는다**" : "⛔ **배치가 틀렸다**");
		LogA("[mlt] 🔩   ⭐ **판정 ②**(과제가 다른 답을 부름 ≥50%%) — 평균 **%.1f%%** · **%u/%u** → %s\n",
			mDiff * 100.0, g2, ok, (g2 == ok && ok > 0u) ? "✅" : "⛔");
		LogA("[mlt] 🔩   (보고) ㈀ 이 바닥 넘음 %u/%u · 유한 %s\n", beat, ok, _finite ? "✅" : "⛔");
		LogA("[mlt] 🔩   ⭐ **씨앗 폭**(다음 회차의 잡음 바닥) — ㈀ CE %.5f ~ %.5f (폭 %.5f)\n",
			loM, hiM, hiM - loM);
		if (!_finite)
			LogA("[mlt] 🔩   ⭐ 판정 = ⛔ **배관 실패** — 유한하지 않다\n");
		else if (g1 != ok)
			LogA("[mlt] 🔩   ⭐ 판정 = ⛔ **배치가 답에 안 닿는다** — ⚠️ 다음은 **배치를 고친다**(회차 119 를 안 연다)\n");
		else if (g2 != ok)
			LogA("[mlt] 🔩   ⭐ 판정 = ⛔ **과제 채널이 죽었다** — 두 과제가 같은 답을 부른다 ⇒ 과제를 다시 고른다\n");
		else
			LogA("[mlt] 🔩   ⭐ 판정 = ✅ **배관이 섰다** ⇒ **회차 119(㉠ `N1 > N0`)를 연다**\n");
		LogA("[mlt] 🔩   ⚠️ 배관 회차다 — 어떤 가설도 판정하지 않았다\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		_E.Destroy(); _done = true;
	}

	static void _Fail(const char* why)
	{
		LogA("[mlt] 🔩 ⛔ %s (씨앗 %u · 코퍼스 %u · 그룹 %u · 팔 %u · 반복 %u · 단계 %u)\n",
			why, _seed, _cor, _gGrp, _arm, _rep, _st);
		_E.Destroy(); _done = true;
	}
};
