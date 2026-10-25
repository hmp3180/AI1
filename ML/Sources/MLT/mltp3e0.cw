// mltp3e0.cw — ⏳ 회차 55 · **슬롯 순서가 표적을 흐리나**(미룬 관문) (`-mltp3e0`)
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 55 다.**
// ⭐ **과몰입 점검이 정한 순서다** — 회차 51 이 *"다음다음 1순위"* 로 등록하고 **세 회차 미룬** 관문이고,
//   근거는 크기다: **표적의 결함 0.240** ↔ **㉠ 의 신호 0.009~0.022** ⇒ **26배**.
// ══════════════════════════════════════════════════════════════════════════════
//
// ⚠️ **무엇이 결함인가** — 표적이 *"시각 `t+1` 의 **슬롯 `j`** 의 활성 id"* 인데 슬롯 `j` 의 뜻이
//   **`q` 선택 순위**다. 회차 51: **슬롯 복사 0.642 ↔ 집합 복사 0.882** ⇒ 같은 8개가 그대로 남는데도
//   **순위가 뒤바뀌어** 슬롯 표적이 틀린다 = **우리가 만든 잡음**이다.
//
// ⭐ **표제를 잡음이 없는 자리에 둔다** — 몸통 CE 에는 미해결 부채(폭 **0.084**)가 있는데,
//   이 물음의 핵심 *"표적 자체가 더 예측 가능해지나"* 는 **CPU 계산이라 잡음이 0** 이다.
//   ⇒ 표제 둘은 CPU(①②), 몸통은 **보조**(③)로 같은 회차에서 함께 낸다.
//
// ── 팔 둘 — ⚠️ **활성 집합은 한 원소도 안 바뀐다. 순서만 바뀐다** ────────────
//   ㈀ **순위**(지금) · ㈁ **id 오름차순**
//   ⭐ **조립은 한 번**이고 **같은 리드백 하나에서 두 코퍼스를 동시에** 만든다(GPU 일 0 증가)
//      ⇒ 두 팔이 **비트 수준으로 같은 활성**을 본다.

using namespace PE;

class MLTP3E0
{
public:
	static void Tick(RHI* rhi)
	{
		if (_done || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltp3e0"))
		{
			LogA("[mlt] ⏳ 회차 55는 **꺼져 있다**(`-mltp3e0`) — 슬롯 순서가 표적을 흐리나\n");
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
	static constexpr uint32 kCandidates = MLTP2Cfg::kPatches * kLocal;
	static constexpr uint32 kNCtx = 512u, kTestCtx = 64u;
	static constexpr uint32 kTrainEpi = 1u, kTestEpi = 101u;
	static constexpr uint32 kPoolSteps = kNCtx / kBatch, kTestPool = kTestCtx / kBatch;
	static constexpr uint32 kGroup = kEncF / kTime;
	static constexpr uint32 kBodySteps = 3200u, kBodyPerTick = 4u;
	static constexpr uint32 kArms = 2u;
	static constexpr uint32 kSignPass = 10u;
	// 위생 — 회차 51 재현(㈀ 팔)
	static constexpr float kAccSlot51 = 0.642f, kAccSet51 = 0.882f, kAccTol = 0.02f;

	enum { kEncInit, kEncTrain, kGather, kBodyInit, kBodyTrain, kBodyEval };

	inline static MLTP2Enc _E;
	inline static MLTModel _M;
	inline static MLTP3Ctx _tr[kArms], _te[kArms];   // 0 = ㈀ 순위 · 1 = ㈁ id 정렬
	inline static MLTEvalGate _gate;
	inline static bool _done = false, _banner = false, _encSetup = false, _finite = true;
	inline static bool _pending = false, _onTest = false;
	inline static uint32 _seed = 0u, _st = kEncInit, _step = 0u, _arm = 0u;
	inline static uint32 _cor = 0u, _gGrp = 0u, _gIdx = 0u;
	inline static Array<float> _code, _norm;
	inline static float _accSlot[kArms][kSeeds], _accSet[kArms][kSeeds];
	inline static float _c1[kArms][kSeeds], _floorTe[kArms][kSeeds];
	inline static float _ceTe[kArms][kSeeds];
	inline static bool  _seedOk[kSeeds];

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] ⏳ **회차 55 · 슬롯 순서가 표적을 흐리나**(미룬 관문 · 회차 51 이 3회차 전에 등록)\n");
		LogA("[mlt] ⏳   팔 둘: ㈀ `q` 순위 ↔ ㈁ id 오름차순 — **활성 집합은 그대로, 순서만**\n");
		LogA("[mlt] ⏳   표제(CPU · 잡음 0): ① 슬롯 복사 정확도 ↑ · ② 슬롯 복사 바닥 ↓ · 각 %u/%u\n",
			kSignPass, kSeeds);
		LogA("[mlt] ⏳   보조(몸통 · 잡음 0.084): ③ 바닥 대비 이득 — **판정이 아니라 보고**\n");
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
		for (uint32 a = 0; a < kArms; ++a)
		{
			_tr[a].SetSortById(a == 1u); _te[a].SetSortById(a == 1u);
			_tr[a].Begin(kNCtx, kN); _te[a].Begin(kTestCtx, kN);
		}
		_cor = 0u; _gGrp = 0u; _gIdx = 0u; _pending = false; _st = kGather;
	}

	// ⭐ **같은 리드백 하나로 두 코퍼스를 동시에** 채운다 — GPU 일이 0 만큼 는다.
	static void _Gather()
	{
		const uint32 nCtx = (_cor == 0u) ? kNCtx : kTestCtx;
		if (_pending)
		{
			Array<float> ids, mag;
			if (!_E.ReadAct(ids, mag) || ids.Count() != kCandidates) { _Fail("활성 리드백"); return; }
			const uint32 ctx = _gGrp * kGroup + (_gIdx - 1u) / kTime;
			const uint32 t = (_gIdx - 1u) % kTime;
			for (uint32 a = 0; a < kArms; ++a)
				((_cor == 0u) ? _tr[a] : _te[a]).StoreAct(ctx, t, ids, mag, _norm);
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
					for (uint32 a = 0; a < kArms; ++a)
						((_cor == 0u) ? _tr[a] : _te[a]).StoreState(ctx, t, w.State());
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
			if (++_cor >= 2u) { _JudgeCpu(); return; }
		}
	}

	// 표제 ①② — **CPU 라 잡음이 0 이다.**
	static void _JudgeCpu()
	{
		for (uint32 a = 0; a < kArms; ++a)
		{
			_tr[a].CopyAcc(_accSlot[a][_seed], _accSet[a][_seed]);
			Array<float> marg;
			_tr[a].Marginal(marg);
			float c1 = 0.0f, c2 = 0.0f, l1 = 0.0f, l2 = 0.0f;
			_tr[a].BestCopy(marg, c1, c2, l1, l2);
			_c1[a][_seed] = c1;
			const float t1 = (float)_te[a].CeCopy(marg, l1, false);
			const float t2 = (float)_te[a].CeCopy(marg, l2, true);
			_floorTe[a][_seed] = (t1 < t2) ? t1 : t2;
		}
		LogA("[mlt] ⏳ 씨앗 %2u · 슬롯정확도 ㈀ **%.3f** → ㈁ **%.3f**(집합 %.3f) · C1* ㈀ **%.4f** → ㈁ **%.4f**\n",
			_seed, (double)_accSlot[0][_seed], (double)_accSlot[1][_seed], (double)_accSet[0][_seed],
			(double)_c1[0][_seed], (double)_c1[1][_seed]);
		_arm = 0u; _st = kBodyInit;
	}

	static void _BodyBegin(RHI* rhi)
	{
		if (!_M.Setup(rhi, MLTP3Ctx::kStateAx + kN, kN, MLTP3Ctx::kAxes, kTime)) { _Fail("몸통 준비"); return; }
		if (!_M.UploadPool(_tr[_arm].Val(), _tr[_arm].Tgt(), kPoolSteps)
			|| !_M.UploadSymbolPool(_tr[_arm].Sym(), kPoolSteps)) { _Fail("학습 풀 업로드"); return; }
		_step = 0u; _onTest = false; _st = kBodyTrain;
	}

	static void _BodyTrain()
	{
		if (_step >= kBodySteps)
		{
			// 시험 코퍼스로 갈아끼우고 **한 번만** 평가한다(학습 CE 는 이 회차의 판정이 아니다).
			if (!_M.UploadPool(_te[_arm].Val(), _te[_arm].Tgt(), kTestPool)
				|| !_M.UploadSymbolPool(_te[_arm].Sym(), kTestPool)) { _Fail("시험 풀 업로드"); return; }
			_onTest = true; _gate.Begin(kTestPool); _st = kBodyEval; return;
		}
		for (uint32 i = 0; i < kBodyPerTick && _step < kBodySteps; ++i)
		{
			_M.SelectStep(_step % kPoolSteps);
			if (!_M.Forward() || !_M.Backward() || !_M.AdamStep(1.0f)) { _Fail("몸통 스텝"); return; }
			++_step;
		}
	}

	static void _BodyEval()
	{
		bool fail = false;
		if (!_gate.Step(_M, fail)) return;
		if (fail) { _Fail("평가 게이트"); return; }
		if (!_gate.Finite()) _finite = false;
		_ceTe[_arm][_seed] = _gate.Mean();
		LogA("[mlt] ⏳   %s 씨앗 %2u · 시험 CE **%.4f** · 시험바닥 %.4f · **이득 %+.4f**\n",
			(_arm == 0u) ? "㈀ 순위" : "㈁ id정렬", _seed, (double)_ceTe[_arm][_seed],
			(double)_floorTe[_arm][_seed], (double)(_floorTe[_arm][_seed] - _ceTe[_arm][_seed]));
		if (++_arm < kArms) { _st = kBodyInit; return; }
		_seedOk[_seed] = _finite;
		++_seed; _st = kEncInit;
	}

	static void _Summary()
	{
		double as[kArms], ae[kArms], c1[kArms], ce[kArms], gn[kArms];
		for (uint32 a = 0; a < kArms; ++a) { as[a] = 0.0; ae[a] = 0.0; c1[a] = 0.0; ce[a] = 0.0; gn[a] = 0.0; }
		uint32 ok = 0u, t1 = 0u, t2 = 0u, t3 = 0u;
		for (uint32 s = 0; s < kSeeds; ++s)
		{
			if (!_seedOk[s]) continue;
			++ok;
			for (uint32 a = 0; a < kArms; ++a)
			{
				as[a] += _accSlot[a][s]; ae[a] += _accSet[a][s]; c1[a] += _c1[a][s];
				ce[a] += _ceTe[a][s]; gn[a] += (_floorTe[a][s] - _ceTe[a][s]);
			}
			if (_accSlot[1][s] > _accSlot[0][s]) ++t1;
			if (_c1[1][s] < _c1[0][s]) ++t2;
			if ((_floorTe[1][s] - _ceTe[1][s]) > (_floorTe[0][s] - _ceTe[0][s])) ++t3;
		}
		if (ok > 0u)
			for (uint32 a = 0; a < kArms; ++a)
			{ as[a] /= ok; ae[a] /= ok; c1[a] /= ok; ce[a] /= ok; gn[a] /= ok; }

		const bool hyg = (Abs((float)as[0] - kAccSlot51) <= kAccTol)
			&& (Abs((float)ae[0] - kAccSet51) <= kAccTol);
		const bool p1 = (t1 >= kSignPass), p2 = (t2 >= kSignPass);

		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] ⏳ **회차 55 · 슬롯 순서 결과** — 읽은 씨앗 %u/%u\n", ok, kSeeds);
		LogA("[mlt] ⏳   위생 ㈀ 회차 51 재현 — 슬롯 **%.3f**(%.3f±%.2f) · 집합 **%.3f**(%.3f±%.2f) → %s\n",
			as[0], (double)kAccSlot51, (double)kAccTol, ae[0], (double)kAccSet51, (double)kAccTol,
			hyg ? "통과" : "⛔");
		LogA("[mlt] ⏳   ① 슬롯 복사 정확도 — ㈀ **%.3f** → ㈁ **%.3f**(집합 상한 %.3f) · **%u/%u** → %s\n",
			as[0], as[1], ae[0], t1, kSeeds, p1 ? "통과" : "⛔");
		LogA("[mlt] ⏳   ② 슬롯 복사 바닥 C1* — ㈀ **%.4f** → ㈁ **%.4f** · **%u/%u** → %s\n",
			c1[0], c1[1], t2, kSeeds, p2 ? "통과" : "⛔");
		LogA("[mlt] ⏳   ③(보고) 시험 CE ㈀ **%.4f** ↔ ㈁ **%.4f** · 바닥 대비 이득 **%+.4f** ↔ **%+.4f** · %u/%u\n",
			ce[0], ce[1], gn[0], gn[1], t3, kSeeds);
		if (!hyg)
			LogA("[mlt] ⏳   ⭐ 판정 = ⛔ **판정불가**(위생) — 코퍼스가 회차 51 과 다르다\n");
		else if (p1 && p2)
			LogA("[mlt] ⏳   ⭐ 판정 = ✅ **표적의 결함이 확인됐다** ⇒ 회차 56 부터 **id 정렬이 표준 배치**(회차 51·52 재측정)\n");
		else if (p1)
			LogA("[mlt] ⏳   ⭐ 판정 = ⚠️ 정확도는 오르는데 **CE 바닥은 안 좋아진다** ⇒ 배치를 안 바꾼다. 다음은 **앵커**\n");
		else
			LogA("[mlt] ⏳   ⭐ 판정 = ⛔ **슬롯 배치는 축이 아니다**(id 정렬도 안 안정적이다) ⇒ 다음은 **앵커**\n");
		LogA("[mlt] ⏳   ⚠️ ③ 은 **보고**다(잡음 0.084 이 실린다) — 판정에 안 쓴다.\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		_E.Destroy(); _done = true;
	}

	static void _Fail(const char* why)
	{
		LogA("[mlt] ⏳ ⛔ %s (씨앗 %u · 팔 %u · 코퍼스 %u · 단계 %u)\n", why, _seed, _arm, _cor, _st);
		_E.Destroy(); _done = true;
	}
};
