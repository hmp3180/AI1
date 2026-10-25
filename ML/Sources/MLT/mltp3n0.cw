// mltp3n0.cw — ⏳ 회차 84 · **문맥 수 세 점: 「어떻게 죽나」** (`-mltp3n0`)
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 84 이다.** ⭐ **하네스보다 먼저 썼다.**
// ⭐ 상위 캔버스가 **새것**이다: **왜 일반화가 안 되나**.
// ══════════════════════════════════════════════════════════════════════════════
//
// ⚠️⚠️ 회차 82·83 이 깨끗한 시험(`kTestEpi = 901`)에서 이것을 세웠다:
//   ***이 몸통은 복사바닥을 못 넘는다*** — 회차 82 **2/12** · 회차 83 **5/12**.
//   ⚠️ 회차 52 가 «표본 64개가 병목» 을 고쳐 128 로 늘렸는데도 그렇다(그때는 **누출된 시험**이었다).
//
// ── ⭐ 왜 「세 점」인가 ────────────────────────────────────────────────
//   `mltconcept.md`: *"**한 점으로는 아무 말도 못 한다** — **최소 세 점**. 판정은 **두 감소 속도의 비**다."*
//   그리고 우리 부채 목록의 첫 줄이 *"복사 베이스라인을 **한 점으로만** 넘었다"* 였다.
//   ⇒ ★ **이 회차가 그 부채를 갚는다.**
//
// ── 싸게 만든 방법 ────────────────────────────────────────────────────────
//   ⭐ **코퍼스는 512 를 한 번만 모은다.** `Row(ctx,t,a) = (ctx/8)·kRows + …` 이므로
//     ***앞 128·256 문맥이 그대로 앞 16·32 풀스텝***이다 ⇒ `UploadPool(…, nPool)` 인자만 다르다.
//   ⇒ 세 점이 **같은 데이터의 부분집합**이라 *"데이터가 달라서"* 가 배제된다.

using namespace PE;

class MLTP3N0
{
public:
	static void Tick(RHI* rhi)
	{
		if (_done || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltp3n0"))
		{
			LogA("[mlt] ⏳ 회차 84는 **꺼져 있다**(`-mltp3n0`) — 문맥 수 세 점(어떻게 죽나)\n");
			_done = true; return;
		}
		if (!_banner) { _Banner(); _banner = true; }
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
	static constexpr uint32 kTime = MLTP3Ctx::kTime;
	static constexpr uint32 kBatch = MLTP3Ctx::kBatch;
	static constexpr uint32 kCandidates = MLTP2Cfg::kPatches * kLocal;
	// ⭐ 세 점 — ⚠️ **512 가 상한**이다(`MLTModelCfg::kPool = 64` × 배치 8).
	static constexpr uint32 kPts = 3u;
	static constexpr uint32 kMaxCtx = 512u, kTestCtx = 64u;
	static uint32 CtxOf(uint32 p) { return (p == 0u) ? 128u : ((p == 1u) ? 256u : 512u); }
	static constexpr uint32 kTrainEpi = 1u, kTestEpi = 901u;
	static_assert(kTestEpi >= kTrainEpi + kMaxCtx,
		"시험 에피소드가 학습과 겹친다 — kTestEpi >= kTrainEpi + kMaxCtx 여야 한다(규율 12)");
	static constexpr uint32 kTestPool = kTestCtx / kBatch;
	static constexpr uint32 kGroup = kEncF / kTime;
	static constexpr uint32 kSteps = 800u, kPerTick = 4u;
	static constexpr uint32 kRep = 4u, kSignPass = 10u;
	static constexpr float  kFlatRel = 1.0e-6f;

	enum { kEncInit, kEncTrain, kGather, kQuiesce, kBodyInit, kBodyTrain, kBodyEval };

	inline static MLTP2Enc _E;
	inline static MLTModel _M;
	inline static MLTP3Ctx _tr, _te;
	inline static MLTEvalGate _gate;
	inline static bool _done = false, _banner = false, _encSetup = false, _finite = true;
	inline static bool _pending = false, _pre = false, _lr0 = false;
	inline static uint32 _seed = 0u, _st = kEncInit, _step = 0u, _pt = 0u, _rep = 0u;
	inline static uint32 _cor = 0u, _gGrp = 0u, _gIdx = 0u;
	inline static Array<float> _code, _norm;
	inline static float _run[kRep];
	inline static float _ce[kPts][kSeeds], _floor[kPts][kSeeds];
	inline static float _gainA[kPts][kSeeds], _gainB[kPts][kSeeds];   // 분할 반쪽의 이득
	inline static float _pre0[kSeeds], _lr0After[kSeeds];
	inline static bool  _seedOk[kSeeds];
	inline static uint32 _qWait = 0u;

	static void _ToBody() { _qWait = MLTEvalGate::kDelay; _st = kQuiesce; }
	static uint32 _NCtx() { return CtxOf(_pt); }
	static uint32 _Pool() { return _NCtx() / kBatch; }

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] ⏳ **회차 84 · 문맥 수 세 점(어떻게 죽나)**(⭐ **새 상위: 왜 일반화가 안 되나**)\n");
		LogA("[mlt] ⏳   점 **128 · 256 · 512**(512 = `kPool` 상한) · 시험은 **같은 64문맥**(에피소드 %u)\n", kTestEpi);
		LogA("[mlt] ⏳   ⭐ 코퍼스는 **512 를 한 번만** 모은다 — 앞 128·256 이 그대로 앞 16·32 풀스텝이다\n");
		LogA("[mlt] ⏳   ★ 지표 = **이득 = 복사바닥 − CE** · 표제① `이득(512) > 이득(128)` · ② `이득(512) > 0`\n");
		LogA("[mlt] ⏳   ⚠️ 학습 스텝 **800 고정**(같은 비용) ⇒ 에폭은 **50 / 25 / 12.5** 로 갈린다\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
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
		_tr.Begin(kMaxCtx, kN); _te.Begin(kTestCtx, kN);      // ⭐ 512 를 한 번만
		_cor = 0u; _gGrp = 0u; _gIdx = 0u; _pending = false; _st = kGather;
	}

	static void _Gather()
	{
		MLTP3Ctx& C = (_cor == 0u) ? _tr : _te;
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
				_Floors();
				_pt = 0u; _rep = 0u; _lr0 = true; _ToBody();
			}
		}
	}

	// ⭐ 점마다 복사바닥 — ⚠️ λ 는 **그 점의 학습 문맥 수**에서 고른다(`SetActive`).
	//   ★ 그래야 *"바닥이 유리해서"* 가 배제된다.
	static void _Floors()
	{
		for (uint32 p = 0; p < kPts; ++p)
		{
			_tr.SetActive(CtxOf(p));
			Array<float> marg; _tr.Marginal(marg);
			float c1 = 0.0f, c2 = 0.0f, l1 = 0.0f, l2 = 0.0f;
			_tr.BestCopy(marg, c1, c2, l1, l2);
			const float t1 = (float)_te.CeCopy(marg, l1, false);
			const float t2 = (float)_te.CeCopy(marg, l2, true);
			_floor[p][_seed] = (t1 < t2) ? t1 : t2;
		}
		_tr.SetActive(kMaxCtx);
		LogA("[mlt] ⏳ 씨앗 %2u · 복사바닥 — 128 **%.4f** · 256 **%.4f** · 512 **%.4f**\n",
			_seed, (double)_floor[0][_seed], (double)_floor[1][_seed], (double)_floor[2][_seed]);
	}

	// ══════════════════════════════════════════════════════════════════
	// ⚠️⚠️ **`UploadPool` 은 크기가 「정확히」 맞아야 한다**(`val.Count() != nSteps*_rows` 면 거절).
	//   ⇒ 512 코퍼스의 **앞부분만** 쓰려면 **잘라서** 넘겨야 한다.
	//   ★ 회차 84 1차가 그 자리에서 멈췄다(`⛔ 학습 풀 업로드 · 씨앗 0 · 점 0`) — ⭐ 하네스가
	//     **잘못된 숫자를 내지 않고 그 자리에서 죽은 것**이 옳았다.
	inline static Array<float> _sv, _stg, _ss;
	static void _Slice(uint32 nPool)
	{
		const uint32 n = nPool * MLTP3Ctx::kRows;
		_sv.Reset(0); _stg.Reset(0); _ss.Reset(0);
		for (uint32 i = 0; i < n; ++i)
		{ _sv.Add(_tr.Val()[i]); _stg.Add(_tr.Tgt()[i]); _ss.Add(_tr.Sym()[i]); }
	}

	static bool _UploadTrain()
	{
		_Slice(_Pool());
		if (!_M.UploadPool(_sv, _stg, _Pool()) || !_M.UploadSymbolPool(_ss, _Pool()))
		{ _Fail("학습 풀 업로드"); return false; }
		return true;
	}

	static void _BodyBegin(RHI* rhi)
	{
		if (!_M.Setup(rhi, MLTP3Ctx::kStateAx + kN, kN, MLTP3Ctx::kAxes, kTime)) { _Fail("몸통 준비"); return; }
		// ⭐ 같은 코퍼스의 **앞 `_Pool()` 풀스텝만** 잘라서 올린다.
		if (!_UploadTrain()) return;
		_step = 0u;
		if (_lr0) { _pre = true; _SwitchToTest(); return; }
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
			_M.SelectStep(_step % _Pool());
			if (!_M.Forward() || !_M.Backward() || !_M.AdamStep(_lr0 ? 0.0f : 1.0f))
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
			if (!_UploadTrain()) return;
			_step = 0u; _st = kBodyTrain; return;
		}
		if (_lr0)
		{
			_lr0After[_seed] = ce;
			LogA("[mlt] ⏳   위생 `lr=0` 씨앗 %2u · 전 %.5f → 후 %.5f\n",
				_seed, (double)_pre0[_seed], (double)ce);
			_lr0 = false; _pt = 0u; _rep = 0u; _ToBody(); return;
		}
		_run[_rep] = ce;
		if (++_rep < kRep) { _ToBody(); return; }
		_Agg();
	}

	static void _Agg()
	{
		double s = 0.0, sA = 0.0, sB = 0.0;
		for (uint32 i = 0; i < kRep; ++i)
		{
			s += (double)_run[i];
			if ((i % 2u) == 0u) sA += (double)_run[i]; else sB += (double)_run[i];
		}
		_ce[_pt][_seed] = (float)(s / (double)kRep);
		const float f = _floor[_pt][_seed];
		_gainA[_pt][_seed] = f - (float)(sA / (double)(kRep / 2u));
		_gainB[_pt][_seed] = f - (float)(sB / (double)(kRep / 2u));
		LogA("[mlt] ⏳   문맥 %3u · 씨앗 %2u · CE **%.5f** · 바닥 %.4f · **이득 %+.5f**(반쪽 %+.5f / %+.5f) · 에폭 %.1f\n",
			_NCtx(), _seed, (double)_ce[_pt][_seed], (double)f,
			(double)(f - _ce[_pt][_seed]), (double)_gainA[_pt][_seed], (double)_gainB[_pt][_seed],
			(double)kSteps / (double)_Pool());
		_rep = 0u;
		if (++_pt < kPts) { _ToBody(); return; }
		_seedOk[_seed] = _finite;
		++_seed; _pt = 0u; _st = kEncInit;
	}

	static void _Summary()
	{
		double mc[kPts], mf[kPts], mg[kPts];
		for (uint32 p = 0; p < kPts; ++p) { mc[p] = 0.0; mf[p] = 0.0; mg[p] = 0.0; }
		uint32 ok = 0u, flat = 0u, t1 = 0u, t2 = 0u, a1 = 0u, b1 = 0u;
		for (uint32 s = 0; s < kSeeds; ++s)
		{
			if (!_seedOk[s]) continue;
			++ok;
			for (uint32 p = 0; p < kPts; ++p)
			{
				mc[p] += _ce[p][s]; mf[p] += _floor[p][s];
				mg[p] += (double)(_floor[p][s] - _ce[p][s]);
			}
			if (Abs(_lr0After[s] - _pre0[s]) <= kFlatRel * Abs(_pre0[s])) ++flat;
			const float g128 = _floor[0][s] - _ce[0][s], g512 = _floor[2][s] - _ce[2][s];
			if (g512 > g128) ++t1;
			if (g512 > 0.0f) ++t2;
			if (_gainA[2][s] > _gainA[0][s]) ++a1;
			if (_gainB[2][s] > _gainB[0][s]) ++b1;
		}
		if (ok > 0u) for (uint32 p = 0; p < kPts; ++p) { mc[p] /= ok; mf[p] /= ok; mg[p] /= ok; }
		const bool h1 = (flat == ok) && _finite;
		const bool split = (a1 >= kSignPass) && (b1 >= kSignPass);
		const bool p1 = (t1 >= kSignPass), p2 = (t2 >= kSignPass);

		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] ⏳ **회차 84 · 문맥 수 세 점** — 읽은 씨앗 %u/%u\n", ok, kSeeds);
		for (uint32 p = 0; p < kPts; ++p)
			LogA("[mlt] ⏳   문맥 **%3u** — CE **%.4f** · 바닥 **%.4f** · ⭐ **이득 %+.4f** · 에폭 %.1f\n",
				CtxOf(p), mc[p], mf[p], mg[p], (double)kSteps / (double)(CtxOf(p) / kBatch));
		LogA("[mlt] ⏳   위생① ㈃ 평탄 **%u/%u** → %s\n", flat, ok, h1 ? "통과" : "⛔");
		LogA("[mlt] ⏳   위생② 분할 반쪽 — A **%u/%u** · B **%u/%u**(각 필요 %u) → %s\n",
			a1, ok, b1, ok, kSignPass, split ? "통과" : "⛔");
		LogA("[mlt] ⏳   ⭐ **표제①** `이득(512) > 이득(128)` — **%u/%u**(필요 %u)\n", t1, kSeeds, kSignPass);
		LogA("[mlt] ⏳   ⭐ **표제②** `이득(512) > 0` — **%u/%u**(필요 %u)\n", t2, kSeeds, kSignPass);
		if (!h1)
			LogA("[mlt] ⏳   ⭐ 판정 = ⛔ **판정불가** — `lr=0` 이 안 평탄하다\n");
		else if (p1 && p2 && split)
			LogA("[mlt] ⏳   ⭐ 판정 = ✅✅ **문맥 수가 병목이었다** ⇒ P3 를 **512 문맥**으로 다시 잰다\n");
		else if (p1 && !p2)
			LogA("[mlt] ⏳   ⭐ 판정 = ⭐ **방향은 맞는데 512 로도 부족하다** ⇒ 추세로 「몇 문맥이 필요한가」를 외삽한다\n");
		else if (!p1)
			LogA("[mlt] ⏳   ⭐ 판정 = ⛔ **문맥 수는 축이 아니다** ⇒ 다음은 **몸통 크기**(빌드가 갈린다) 또는 세계\n");
		else
			LogA("[mlt] ⏳   ⭐ 판정 = ⚠️ **판정불가**(분할 반쪽이 안 맞는다)\n");
		LogA("[mlt] ⏳   ⚠️ 학습 스텝 **%u 고정**이라 에폭이 갈린다 — 「같은 비용」의 대가다\n", kSteps);
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		_E.Destroy(); _done = true;
	}

	static void _Fail(const char* why)
	{
		LogA("[mlt] ⏳ ⛔ %s (씨앗 %u · 점 %u · 반복 %u · 단계 %u)\n", why, _seed, _pt, _rep, _st);
		_E.Destroy(); _done = true;
	}
};
