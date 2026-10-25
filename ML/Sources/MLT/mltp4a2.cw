// mltp4a1.cw — 🔩 회차 79 · **위생을 세운다 — 규약 하나만 바꾼 A/B** (`-mltp4a2`)
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 79 이다.**
// ⭐ **회차 77 과 「규약」 하나만 다르다** — 팔·위생·에피소드·씨앗·스텝이 **전부 같다**.
//   ⇒ `㈀ 이 복사바닥을 넘나`가 **규약 하나로** 갈린다.
//
// ⚠️⚠️ **왜 필요한가** — 회차 78(㉠ 개입 시험)이 **위생②에서 무너졌다**:
//     회차 77(옛 규약) `㈀ 0.8847 < 바닥 1.0847` ✅ **12/12**
//     회차 78(새 규약) `A→A 1.1521 > 바닥 1.0835` ⛔ **3/12**
//   ⇒ 후보 넷 중 ⭐ **규약 변경**이 유력했고 이 회차가 그것을 **직접** 가른다.
//
// ⚠️ 아래는 회차 77 의 하네스(`mltp4a0.cw`) 그대로이고 바뀐 곳은 `_Gather` 의 **세 줄**뿐이다.
// ══════════════════════════════════════════════════════════════════════════════
//
// ── (아래는 회차 77 의 머리말 원문) ──────────────────────────────────────
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 77 이다.** (설계 심사 = 회차 76)
// ⚠️ 상위 = **P4 — 행동과 인과** · **배관 회차**(판정 회차가 아니다).
// ══════════════════════════════════════════════════════════════════════════════
//
// ⭐ 회차 76 심사가 세 결정을 했다:
//   ㈀ `MLTWorld::StepWith(act)` 를 더한다 — **행동을 밖에서 준다**(개입의 전제)
//   ㈁ `MLTP4Ctx` 를 **새로** 만든다 — `MLTP3Ctx` 는 P3 정본으로 **얼린다**(회귀가 깨진다)
//   ㈂ ㉠ 을 **2×2 교차**로 짠다(회차 78) — *"갈리나"* 는 약하다, **방향까지** 요구한다
//
// ── ⭐ 판정 ① 이 공짜로 생겼다 ──────────────────────────────────────────
//   `Step()` 이 그 스텝에 고를 행동(`ActAt`)을 `StepWith` 에 그대로 넣으면
//   ***상태열이 비트 동일이어야 한다.*** ⚠️ 순환이 없다 — 두 경로가 **다른 함수**이고
//   비교는 **끝점(상태)** 에서 한다(회차 68 이 밟은 「중간 버퍼로 하는 판정은 순환이다」의 반대).

using namespace PE;

class MLTP4A2
{
public:
	static void Tick(RHI* rhi)
	{
		if (_done || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltp4a2"))
		{
			LogA("[mlt] 🔩 회차 77은 **꺼져 있다**(`-mltp4a2`) — P4 배관 + 판정 ①\n");
			_done = true; return;
		}
		if (!_banner) { _Banner(); _banner = true; }
		if (!_gate1) { _Gate1(); return; }              // CPU 만 — 즉시 끝난다
		if (_seed >= kSeeds) { _Summary(); return; }
		switch (_st)
		{
		case kEncInit:  _EncBegin(rhi); return;
		case kEncTrain: _EncTrain();    return;
		case kGather:   _Gather();      return;
		case kQuiesce:  if (_qWait > 0u) { --_qWait; } else _st = kBodyInit; return;
		case kBodyInit: _BodyBegin(rhi); return;
		case kBodyTrain:_BodyTrain();   return;
		case kBodyEval: _BodyEval();    return;
		default: return;
		}
	}

	static bool Done() { return _done; }

private:
	static constexpr uint32 kSeeds = 12u;
	static constexpr uint32 kEncF = 32u, kEncSteps = 1200u, kEncPerTick = 8u;
	static constexpr uint32 kN = 250u, kLocal = 8u;
	static constexpr uint32 kTime = MLTP4Ctx::kTime;
	static constexpr uint32 kBatch = MLTP4Ctx::kBatch;
	static constexpr uint32 kAxes = MLTP4Ctx::kAxes;          // 18
	static constexpr uint32 kSlots = MLTP4Ctx::kPersist;
	static constexpr uint32 kStateAx = MLTP4Ctx::kStateAx;
	static constexpr uint32 kActAx = MLTP4Ctx::kActAx;
	static constexpr uint32 kCand = MLTP2Cfg::kPatches * kLocal;
	static constexpr uint32 kNCtx = 128u, kTestCtx = 64u;
	static constexpr uint32 kTrainEpi = 1u, kTestEpi = 101u;
	static constexpr uint32 kPoolSteps = kNCtx / kBatch, kTestPool = kTestCtx / kBatch;
	static constexpr uint32 kGroup = kEncF / kTime;
	static constexpr uint32 kSteps = 800u, kPerTick = 4u;
	// ⭐ **회차 80** — 팔의 뜻이 바뀌었다: **채점 자리**를 가른다.
	//   X 전 시각(= 회차 79 의 ㈀ · **재현 검사**) · Y **시각 kSplit 하나**(회차 78 의 그 자리) · ㈃ lr=0
	static constexpr uint32 kArms = 3u;
	static constexpr uint32 kSplit = kTime - 2u;      // 6
	static constexpr uint32 kSignPass = 10u;
	static constexpr float  kFlatRel = 1.0e-6f;

	enum { kEncInit, kEncTrain, kGather, kQuiesce, kBodyInit, kBodyTrain, kBodyEval };

	inline static MLTP2Enc _E;
	inline static MLTModel _M;
	inline static MLTP4Ctx _tr, _te;
	inline static MLTEvalGate _gate;
	inline static bool _done = false, _banner = false, _encSetup = false, _finite = true;
	inline static bool _pending = false, _pre = false, _gate1 = false;
	inline static uint32 _seed = 0u, _st = kEncInit, _step = 0u, _arm = 0u;
	inline static uint32 _cor = 0u, _gGrp = 0u, _gIdx = 0u;
	inline static Array<float> _code, _norm, _val, _sym;
	inline static float _ce[kArms][kSeeds], _pre0[kSeeds], _floorTe[kSeeds], _floorSp[kSeeds];
	inline static Array<float> _tgtSplit;
	inline static bool  _seedOk[kSeeds];
	inline static uint32 _g1Bad = 0u;
	inline static uint32 _qWait = 0u;

	static void _ToBody() { _qWait = MLTEvalGate::kDelay; _st = kQuiesce; }
	static const char* _ArmName()
	{ return (_arm == 0u) ? "X 전 시각" : ((_arm == 1u) ? "Y 시각6 만" : "㈃ lr=0"); }

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🔩 **회차 80 · 채점 자리를 가른다**(⚠️ 배관·진단 회차)\n");
		LogA("[mlt] 🔩   ⭐ 같은 몸통·같은 코퍼스·같은 에피소드 — **채점 자리만** 바꾼다\n");
		LogA("[mlt] 🔩   X = **전 시각**(회차 79 재현) · Y = **시각 %u 하나**(회차 78 의 그 자리)\n", kSplit);
		LogA("[mlt] 🔩   ★ 표제 = `Y 가 그 자리의 복사바닥을 넘나` — ⭐ **문턱 없음**(부호검정)\n");
		LogA("[mlt] 🔩   대역 `[상태5][**행동5**][활성8]` × 시각 %u ⇒ kAxes **%u** · kCtx **%u**\n",
			kTime, kAxes, MLTP4Ctx::kCtx);
		LogA("[mlt] 🔩   ⭐ **판정 ①** — `StepWith(ActAt(t))` 가 `Step()` 과 **비트 동일**인가(끝점 · 순환 없음)\n");
		LogA("[mlt] 🔩   위생 셋 — ㈃ lr=0 평탄 · ㈀ 이 복사바닥을 넘음 · ⭐ ㈀≠㈁(배관이 행동을 나른다)\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

	// ══════════════════════════════════════════════════════════════════
	// ⭐ 판정 ① — `StepWith` 가 `Step()` 과 같은 세계를 만드나 (CPU 만)
	// ══════════════════════════════════════════════════════════════════
	static void _Gate1()
	{
		_g1Bad = 0u;
		uint32 worst = 0u;
		for (uint32 s = 0; s < kSeeds; ++s)
			for (uint32 e = 0; e < 4u; ++e)
			{
				MLTWorld a, b;
				a.Reset(s, kTrainEpi + e, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
				b.Reset(s, kTrainEpi + e, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
				for (uint32 t = 0; t < 32u; ++t)
				{
					const uint32 n = b.StepNo();
					a.Step();
					b.StepWith(b.ActAt(n));               // ⭐ 「같은 행동」을 밖에서 준다
					const MLTState& sa = a.State();
					const MLTState& sb = b.State();
					for (int k = 0; k < MLTState::kAxes; ++k)
						if (sa.Axis(k) != sb.Axis(k)) { ++_g1Bad; ++worst; }
				}
			}
		LogA("[mlt] 🔩   **판정 ①** — 씨앗 %u × 문맥 4 × 32스텝 × 축 5 = **%u 칸** 중 다른 칸 **%u** → %s\n",
			kSeeds, kSeeds * 4u * 32u * 5u, _g1Bad, (_g1Bad == 0u) ? "✅ 비트 동일" : "⛔");
		if (_g1Bad != 0u)
		{
			LogA("[mlt] 🔩 ⛔ **판정 ① 실패 — `StepWith` 가 `Step()` 과 다른 세계를 만든다**. 여기서 멈춘다\n");
			_done = true; return;
		}
		_gate1 = true;
	}

	// ══════════════════════════════════════════════════════════════════
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
		MLTP4Ctx& C = (_cor == 0u) ? _tr : _te;
		const uint32 nCtx = (_cor == 0u) ? kNCtx : kTestCtx;
		if (_pending)
		{
			Array<float> ids, mag;
			if (!_E.ReadAct(ids, mag) || ids.Count() != kCand) { _Fail("활성 리드백"); return; }
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
					// ⭐ **회차 79 의 새 규약** — 렌더·상태·활성을 **먼저** 넣고, **그 다음** 행동을 넣고 굴린다.
					//   ⇒ 시각 `t` 슬롯 = `[상태(t)][행동(t → t+1 에 쓸 것)][활성(t)]`
					//   ⚠️ 회차 77 은 그 반대였다(`[상태(t 이동 후)][행동(t 에 쓴 것)][활성(t 이동 후)]`).
					//   ★ **이 회차는 그 규약 하나만 다르다** — 팔·위생·에피소드·씨앗이 전부 같다.
					if (!w.Render(bmp) || !MLTWorld::Pack(bmp, nullptr, packed)) { _Fail("Render/Pack(문맥)"); return; }
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
		_gIdx = 0u;
		if (++_gGrp * kGroup >= nCtx)
		{
			_gGrp = 0u;
			if (++_cor >= 2u)
			{
				Array<float> marg; _tr.Marginal(marg);
				float c1 = 0.0f, c2 = 0.0f, l1 = 0.0f, l2 = 0.0f;
				// ⭐ **두 자리에서 각각** — 전 시각(X) 과 시각 `kSplit`(Y). ⚠️ λ 도 그 자리에서 고른다.
				_tr.BestCopy(marg, c1, c2, l1, l2);
				const float t1 = (float)_te.CeCopy(marg, l1, false);
				const float t2 = (float)_te.CeCopy(marg, l2, true);
				_floorTe[_seed] = (t1 < t2) ? t1 : t2;
				float d1 = 0.0f, d2 = 0.0f, m1 = 0.0f, m2 = 0.0f;
				_tr.BestCopy(marg, d1, d2, m1, m2, kSplit);
				const float s1 = (float)_te.CeCopy(marg, m1, false, kSplit);
				const float s2 = (float)_te.CeCopy(marg, m2, true, kSplit);
				_floorSp[_seed] = (s1 < s2) ? s1 : s2;
				_MakeSplitTgt();
				LogA("[mlt] 🔩 씨앗 %2u · 복사바닥 — 전 시각 **%.4f** · 시각%u **%.4f**\n",
					_seed, (double)_floorTe[_seed], kSplit, (double)_floorSp[_seed]);
				_arm = 0u; _ToBody();
			}
		}
	}

	// ══════════════════════════════════════════════════════════════════
	static void _BodyBegin(RHI* rhi)
	{
		// ⚠️ 심볼 어휘 = 상태 5 + 행동 5 + 활성 N.
		if (!_M.Setup(rhi, kStateAx + kActAx + kN, kN, kAxes, kTime)) { _Fail("몸통 준비"); return; }
		_MakeArm(_tr, kNCtx, kPoolSteps);
		if (!_M.UploadPool(_val, _tr.Tgt(), kPoolSteps) || !_M.UploadSymbolPool(_sym, kPoolSteps))
		{ _Fail("학습 풀 업로드"); return; }
		_step = 0u;
		if (_arm == 2u) { _pre = true; _SwitchToTest(); return; }
		_pre = false; _st = kBodyTrain;
	}

	// ⭐ **회차 80 — 값은 팔에 안 의존한다.** 바뀌는 것은 **채점 자리(표적)** 뿐이다.
	//   ⚠️ 그래야 *"행동을 껐다"* 와 *"채점 자리를 좁혔다"* 가 안 섞인다.
	static void _MakeArm(const MLTP4Ctx& C, uint32 nCtx, uint32 nPool)
	{
		const uint32 n = nPool * MLTP4Ctx::kRows;
		_val.Reset(0); _sym.Reset(0);
		for (uint32 i = 0; i < n; ++i) { _val.Add(C.Val()[i]); _sym.Add(C.Sym()[i]); }
	}

	// 시각 `kSplit` 의 활성 표적만 남긴 판(회차 60·78 과 같은 형식).
	static void _MakeSplitTgt()
	{
		const uint32 n = kTestPool * MLTP4Ctx::kRows;
		_tgtSplit.Reset(0);
		for (uint32 i = 0; i < n; ++i) _tgtSplit.Add(_te.Tgt()[i]);
		const float ign = (float)kN;
		for (uint32 ctx = 0; ctx < kTestCtx; ++ctx)
			for (uint32 t = 0; t < kTime; ++t)
			{
				if (t == kSplit) continue;
				const uint32 base = MLTP4Ctx::Row(ctx, t, MLTP4Ctx::kOAct2);
				for (uint32 j = 0; j < MLTP4Ctx::kPersist; ++j) _tgtSplit.Data()[base + j] = ign;
			}
	}

	static bool _SwitchToTest()
	{
		_MakeArm(_te, kTestCtx, kTestPool);
		// ⭐ 팔 Y 만 **시각 6 하나**로 채점한다.
		const Array<float>& tgt = (_arm == 1u) ? _tgtSplit : _te.Tgt();
		if (!_M.UploadPool(_val, tgt, kTestPool) || !_M.UploadSymbolPool(_sym, kTestPool))
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
			if (!_M.Forward() || !_M.Backward() || !_M.AdamStep((_arm == 2u) ? 0.0f : 1.0f))
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
			_MakeArm(_tr, kNCtx, kPoolSteps);
			if (!_M.UploadPool(_val, _tr.Tgt(), kPoolSteps) || !_M.UploadSymbolPool(_sym, kPoolSteps))
			{ _Fail("학습 풀 복귀"); return; }
			_step = 0u; _st = kBodyTrain; return;
		}
		_ce[_arm][_seed] = ce;
		LogA("[mlt] 🔩   %s 씨앗 %2u · 시험 CE **%.5f**\n", _ArmName(), _seed, (double)ce);
		if (++_arm < kArms) { _ToBody(); return; }
		_seedOk[_seed] = _finite;
		++_seed; _arm = 0u; _st = kEncInit;
	}

	static void _Summary()
	{
		double m[kArms], mf = 0.0, ms = 0.0;
		for (uint32 a = 0; a < kArms; ++a) m[a] = 0.0;
		uint32 ok = 0u, flat = 0u, beatX = 0u, beatY = 0u;
		for (uint32 s = 0; s < kSeeds; ++s)
		{
			if (!_seedOk[s]) continue;
			++ok;
			for (uint32 a = 0; a < kArms; ++a) m[a] += _ce[a][s];
			mf += _floorTe[s]; ms += _floorSp[s];
			if (Abs(_ce[2][s] - _pre0[s]) <= kFlatRel * Abs(_pre0[s])) ++flat;
			if (_ce[0][s] < _floorTe[s]) ++beatX;      // X 가 **전 시각** 바닥을 넘나(재현 검사)
			if (_ce[1][s] < _floorSp[s]) ++beatY;      // ⭐ Y 가 **시각6** 바닥을 넘나(이 회차의 표제)
		}
		if (ok > 0u) { for (uint32 a = 0; a < kArms; ++a) m[a] /= ok; mf /= ok; ms /= ok; }
		const bool h1 = (flat == ok) && _finite;
		const bool hX = (beatX >= kSignPass);
		const bool p1 = (beatY >= kSignPass);

		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🔩 **회차 80 · 채점 자리를 가른다** — 읽은 씨앗 %u/%u · 판정 ① **%s**\n",
			ok, kSeeds, (_g1Bad == 0u) ? "✅" : "⛔");
		LogA("[mlt] 🔩   ⚠️ 견줄 것 — 회차 79(전 시각) ㈀ **0.8800**/바닥 **1.0779** ✅12/12 · 회차 78(시각6) **1.1521**/**1.0835** ⛔3/12\n");
		LogA("[mlt] 🔩   **X 전 시각** CE **%.4f** ↔ 바닥 **%.4f** · 넘음 **%u/%u** → %s(재현)\n",
			m[0], mf, beatX, ok, hX ? "통과" : "⛔");
		LogA("[mlt] 🔩   ⭐ **Y 시각%u 만** CE **%.4f** ↔ 바닥 **%.4f** · 넘음 **%u/%u**(필요 %u)\n",
			kSplit, m[1], ms, beatY, ok, kSignPass);
		LogA("[mlt] 🔩   위생① ㈃ 평탄 **%u/%u** → %s\n", flat, ok, h1 ? "통과" : "⛔");
		if (!h1 || !hX)
			LogA("[mlt] 🔩   ⭐ 판정 = ⛔ **판정불가** — 위생(평탄) 또는 X 의 재현이 안 선다\n");
		else if (p1)
			LogA("[mlt] 🔩   ⭐ 판정 = ⚠️ **채점 자리는 범인이 아니다** — 시각%u 로도 넘는다 ⇒ 남은 후보는 **에피소드**뿐\n", kSplit);
		else
			LogA("[mlt] 🔩   ⭐ 판정 = ✅ **채점 자리가 범인이다** — `kAxes 18` 에서 시각%u 채점이 원래 어렵다 ⇒ ㉠ 의 **채점 자리를 넓힌다**\n", kSplit);
		LogA("[mlt] 🔩   ⚠️ 이것은 **배관 확인**이다 — `㈀≠㈁` 은 「갈리나」의 약한 판이고 **판정이 아니다**\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		_E.Destroy(); _done = true;
	}

	static void _Fail(const char* why)
	{
		LogA("[mlt] 🔩 ⛔ %s (씨앗 %u · 팔 %u · 단계 %u)\n", why, _seed, _arm, _st);
		_E.Destroy(); _done = true;
	}
};
