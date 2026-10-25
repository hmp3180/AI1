// mltp3c1.cw — ⏳ 회차 50 · **P3-C1: 상태가 비전 예측을 돕나**(관문 ㉠) (`-mltp3c1`)
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 50 이다** — 여기 적는 것은 구현 계약뿐이다.
// ══════════════════════════════════════════════════════════════════════════════
//
// ★ **묻는 것 한 줄** — *"상태 슬롯을 끊으면 다음-활성 예측이 나빠지나?"*
//   `MLT.md` P3 ㉠: 그것이 ***"내 움직임이 화면을 이렇게 바꾼다"*** 를 배웠다는 유일한 증거다.
//
// ── 한 시각 = **13 슬롯** ────────────────────────────────────────────────────
//   슬롯 0..4   상태 축 5개    심볼 `0..4`      값 = 관측 상태 ∈ [-1,1]
//   슬롯 5..12  활성 8개       심볼 `5 + id`    값 = `mag / max|mag|`(그 프레임)
//   `axes = 13` · `time = 8` ⇒ `ctx = 104` · `rows = 832` · `V_sym = 5+N` · `V_out = N`
//
// ⚠️ **`EXP` 의 내용은 회차 43 의 `q` 선택자다**(`|mag|·‖code‖₂` 탐욕 8개 · 의미 비의존).
//   ⚠️⚠️ 그것을 쓴다고 **「압축이 풀렸다」로 인용하지 않는다** — 회차 43 이 그 `G` 를 이미 쟀다.
// ⚠️ **앵커(패치 자리)는 안 넣는다** — 2D RoPE 가 새 커널이고 ㉠ 은 앵커 없이도 성립한다.
//
// ── 팔 넷 · 값만 다르고 **행 수·심볼·자리·연산량이 같다** ────────────────────
//   ㈀ 온전(진짜 상태) · ㈁ 상수(0) · ㈂ 무작위(그 스텝과 무관) · ㈃ `lr=0`
//   ⭐ ㈁ 과 ㈂ 은 **다른 대조군**이다(`mltconcept.md` 「내용 없는 같은 비용 팔」이 둘을 요구한다).

using namespace PE;

class MLTP3C1
{
public:
	static void Tick(RHI* rhi)
	{
		if (_done || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltp3c1"))
		{
			LogA("[mlt] ⏳ 회차 50은 **꺼져 있다**(`-mltp3c1`) — 상태가 비전 예측을 돕나(관문 ㉠)\n");
			_done = true; return;
		}
		if (!_banner) { _Banner(); _banner = true; }
		if (_seed >= kSeeds) { _Summary(); return; }
		if (_st == kEncInit) { _EncBegin(rhi); return; }
		if (_st == kEncTrain) { _EncTrain(); return; }
		if (_st == kGather) { _Gather(); return; }
		if (_st == kBodyInit) { _BodyBegin(rhi); return; }
		if (_st == kBodyEval) { _BodyEval(); return; }
		_BodyTrain();
	}

	static bool Done() { return _done; }

private:
	// ── 등록값 ────────────────────────────────────────────────────
	static constexpr uint32 kSeeds = 12u;
	static constexpr uint32 kEncF = 32u, kEncSteps = 1200u, kEncPerTick = 8u;
	static constexpr uint32 kN = 250u;            // ⚠️ 헤드 비용 때문에 고른 값(회차 25: N 은 축이 아니다)
	static constexpr uint32 kLocal = 8u;          // 패치마다 top-k
	static constexpr uint32 kPersist = 8u;        // 프레임 전체 활성 슬롯
	static constexpr uint32 kStateAx = 5u;
	static constexpr uint32 kAxes = kStateAx + kPersist;      // 13
	static constexpr uint32 kTime = 8u;
	static constexpr uint32 kCtx  = kAxes * kTime;            // 104
	static constexpr uint32 kBatch = MLTModelCfg::kBatch;     // 8
	static constexpr uint32 kRows = kBatch * kCtx;            // 832
	static constexpr uint32 kPoolN = 8u;          // 풀 스텝(= 배치 묶음) 수 ⇒ 문맥 64개
	static constexpr uint32 kBodySteps = 400u, kBodyPerTick = 4u;
	static constexpr uint32 kCandidates = MLTP2Cfg::kPatches * kLocal;   // 512
	static constexpr uint32 kArms = 4u;
	static constexpr uint32 kSignPass = 10u;
	static constexpr float  kFlatRel = 1.0e-6f, kDrop = 0.5f;

	enum { kEncInit, kEncTrain, kGather, kBodyInit, kBodyTrain, kBodyEval };

	inline static MLTP2Enc _E;
	inline static MLTModel _M;
	inline static bool _done = false, _banner = false, _encSetup = false, _finite = true, _post = false;
	inline static uint32 _seed = 0u, _st = kEncInit, _step = 0u, _arm = 0u, _ev = 0u;
	inline static double _sumCe = 0.0;
	inline static uint32 _gCtx = 0u, _gStep = 0u;     // 문맥 조립 진행
	inline static Array<float> _code, _norm;
	inline static Array<float> _val, _tgt, _sym;      // 풀 전체(`kPoolN × kRows`)
	inline static Array<float> _stateReal;            // 진짜 상태(팔마다 다시 쓴다) — `kPoolN × kRows`
	inline static float _first[kArms], _last[kArms];
	inline static float _ce[kArms][kSeeds];
	inline static float _marg[kSeeds];                // 주변분포 CE(선행 관문 4)
	inline static bool  _seedOk[kSeeds];
	inline static uint32 _actHist[kN];                // 표적 id 히스토그램(주변분포용)

	static const char* _ArmName()
	{
		return (_arm == 0u) ? "㈀ 온전" : ((_arm == 1u) ? "㈁ 상수0" : ((_arm == 2u) ? "㈂ 무작위" : "㈃ lr=0"));
	}

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] ⏳ **회차 50 · P3-C1 — 상태가 비전 예측을 돕나**(관문 ㉠)\n");
		LogA("[mlt] ⏳   한 시각 %u슬롯(상태 %u + 활성 %u) · time %u · ctx %u · rows %u\n",
			kAxes, kStateAx, kPersist, kTime, kCtx, kRows);
		LogA("[mlt] ⏳   N=%u · V_sym=%u · V_out=%u · 문맥 %u개 · 몸통 %u스텝 · 씨앗 %u\n",
			kN, kStateAx + kN, kN, kPoolN * kBatch, kBodySteps, kSeeds);
		LogA("[mlt] ⏳   팔 넷: ㈀ 온전 · ㈁ 상수0 · ㈂ 무작위 · ㈃ lr=0 — 값만 다르고 비용은 같다\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

	// ══════════════════════════════════════════════════════════════════
	// 👁️ ① 인코더 — 회차 46/24 의 `F=32` 팔 그대로(사전만 `N=250`).
	// ══════════════════════════════════════════════════════════════════
	static void _EncBegin(RHI* rhi)
	{
		if (!_encSetup)
		{
			if (!_E.Setup(rhi, kEncF, kN)) { _Fail("인코더 준비 실패"); return; }
			_encSetup = true;
		}
		else if (!_E.ResetSeed()) { _Fail("인코더 되돌리기 실패"); return; }
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
		if (!_E.WritePool(fr, tg, kEncF)) { _Fail("인코더 풀 업로드 실패"); return; }
		_step = 0u; _st = kEncTrain;
	}

	static void _EncTrain()
	{
		for (uint32 i = 0; i < kEncPerTick && _step < kEncSteps; ++i)
		{
			_E.SetFrame(_step % kEncF);
			if (!_E.Forward() || !_E.Backward() || !_E.AdamStep(1.0f)) { _Fail("인코더 학습 실패"); return; }
			++_step;
		}
		if (_step < kEncSteps) return;
		// 코드북과 그 행 노름 — `q` 선택자의 재료다.
		if (!_E.ReadCodebook(_code) || _code.Count() != kN * MLTP2Cfg::kPix) { _Fail("코드북 리드백"); return; }
		_norm.Reset(0);
		for (uint32 id = 0; id < kN; ++id)
		{
			double sq = 0.0; const float* a = _code.Data() + id * MLTP2Cfg::kPix;
			for (uint32 d = 0; d < MLTP2Cfg::kPix; ++d) sq += (double)a[d] * (double)a[d];
			_norm.Add((float)Sqrt((float)sq));
		}
		_val.Reset(0); _tgt.Reset(0); _sym.Reset(0); _stateReal.Reset(0);
		for (uint32 i = 0; i < kPoolN * kRows; ++i)
		{ _val.Add(0.0f); _tgt.Add(0.0f); _sym.Add(0.0f); _stateReal.Add(0.0f); }
		for (uint32 i = 0; i < kN; ++i) _actHist[i] = 0u;
		_gCtx = 0u; _gStep = 0u; _st = kGather;
	}

	// ══════════════════════════════════════════════════════════════════
	// 🧩 ② 문맥 조립 — 한 문맥 = 한 에피소드를 `kTime` 스텝 굴린 것.
	//   ⚠️ 인코더 forward 는 **디스패치 → 다음 틱 리드백**이라 스텝 하나가 틱 하나다.
	// ══════════════════════════════════════════════════════════════════
	static void _Gather()
	{
		const uint32 nCtx = kPoolN * kBatch;
		if (_gStep > 0u)
		{
			Array<float> ids, mag;
			if (!_E.ReadAct(ids, mag) || ids.Count() != kCandidates) { _Fail("활성 리드백"); return; }
			_Fill(_gCtx, _gStep - 1u, ids, mag);
		}
		if (_gCtx >= nCtx) { _AfterGather(); return; }
		if (_gStep >= kTime) { ++_gCtx; _gStep = 0u; if (_gCtx >= nCtx) { _AfterGather(); return; } }

		// ⚠️ 그 문맥의 세계를 `_gStep + 1` 번 굴린 상태를 만든다(에피소드는 결정적이라 재현된다).
		MLTWorld w; w.Reset(_seed, 1u + _gCtx, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
		for (uint32 s = 0; s <= _gStep; ++s) w.Step();
		ImageFormat::Bitmap bmp; Bytes packed;
		if (!w.Render(bmp) || !MLTWorld::Pack(bmp, nullptr, packed)) { _Fail("Render/Pack(문맥)"); return; }
		Array<float> fr, tg; fr.Reset(0); tg.Reset(0);
		MLTP2Enc::AppendFrame(fr, tg, (const uint8*)packed.GetData());
		if (!_E.WritePool(fr, tg, 1u) || !_E.Forward()) { _Fail("문맥 인코더 forward"); return; }
		// 상태는 CPU 에서 바로 적는다(GPU 와 무관하다).
		_Store(_gCtx, _gStep, w.State());
		++_gStep;
	}

	// 그 문맥·시각의 **상태 다섯**을 적는다.
	static void _Store(uint32 ctx, uint32 t, const MLTState& s)
	{
		const uint32 base = _Row(ctx, t, 0u);
		for (uint32 a = 0; a < kStateAx; ++a)
		{
			_sym.Data()[base + a] = (float)a;
			_stateReal.Data()[base + a] = s.Axis((int)a);
			_tgt.Data()[base + a] = (float)kN;      // ⚠️ 상태 슬롯은 손실에서 뺀다(IgnoreTgt)
		}
	}

	// 그 문맥·시각의 **활성 여덟**을 적는다(회차 43 의 `q` 선택자).
	static void _Fill(uint32 ctx, uint32 t, const Array<float>& ids, const Array<float>& mag)
	{
		uint32 pick[kPersist]; float pm[kPersist];
		Array<uint8> used; used.Reset(0);
		for (uint32 c = 0; c < kCandidates; ++c) used.Add(0u);
		float maxAbs = 0.0f;
		for (uint32 j = 0; j < kPersist; ++j)
		{
			bool found = false; float best = 0.0f; uint32 bp = 0u;
			for (uint32 c = 0; c < kCandidates; ++c)
			{
				if (used[c] != 0u) continue;
				const float f = ids[c];
				if (!(f >= 0.0f) || f >= (float)kN) continue;
				const float sc = Abs(mag[c]) * _norm[(uint32)f];
				if (!found || sc > best) { found = true; best = sc; bp = c; }
			}
			if (!found) { pick[j] = 0u; pm[j] = 0.0f; continue; }
			used.Data()[bp] = 1u; pick[j] = (uint32)ids[bp]; pm[j] = mag[bp];
			const float a = Abs(pm[j]); if (a > maxAbs) maxAbs = a;
		}
		const float inv = (maxAbs > 1.0e-12f) ? (1.0f / maxAbs) : 0.0f;
		const uint32 base = _Row(ctx, t, kStateAx);
		for (uint32 j = 0; j < kPersist; ++j)
		{
			_sym.Data()[base + j] = (float)(kStateAx + pick[j]);
			_val.Data()[base + j] = pm[j] * inv;
			_tgt.Data()[base + j] = (float)kN;     // 뒤에서 **직전 시각**의 표적으로 되메운다
		}
		// ⭐ 표적은 **직전 시각의 같은 슬롯**이 이번 시각의 id 를 맞히는 것이다.
		if (t > 0u)
		{
			const uint32 prev = _Row(ctx, t - 1u, kStateAx);
			for (uint32 j = 0; j < kPersist; ++j)
			{
				_tgt.Data()[prev + j] = (float)pick[j];
				++_actHist[pick[j]];
			}
		}
	}

	// 풀 배치는 `[poolStep][batch][t][axis]` — 몸통의 행 규약(`r = b·ctx + t·axes + a`) 그대로다.
	static uint32 _Row(uint32 ctx, uint32 t, uint32 a)
	{
		const uint32 k = ctx / kBatch, b = ctx % kBatch;
		return k * kRows + b * kCtx + t * kAxes + a;
	}

	static void _AfterGather()
	{
		// 선행 관문 ④ — 주변분포 CE(표적 id 의 경험 분포로만 예측할 때).
		uint32 tot = 0u;
		for (uint32 i = 0; i < kN; ++i) tot += _actHist[i];
		double ce = 0.0;
		for (uint32 i = 0; i < kN; ++i)
			if (_actHist[i] > 0u)
			{
				const double p = (double)_actHist[i] / (double)tot;
				ce += -(double)_actHist[i] * Log((float)p);
			}
		_marg[_seed] = (tot > 0u) ? (float)(ce / (double)tot) : 0.0f;
		LogA("[mlt] ⏳ 씨앗 %2u · 문맥 %u · 유효표적 %u · 주변분포 CE **%.4f**\n",
			_seed, kPoolN * kBatch, tot, (double)_marg[_seed]);
		_arm = 0u; _st = kBodyInit;
	}

	// ══════════════════════════════════════════════════════════════════
	// 🧠 ③ 몸통 — 팔마다 `Setup` 을 다시 불러 **같은 초기값**에서 출발한다.
	// ══════════════════════════════════════════════════════════════════
	static void _BodyBegin(RHI* rhi)
	{
		if (!_M.Setup(rhi, kStateAx + kN, kN, kAxes, kTime)) { _Fail("몸통 준비 실패"); return; }
		if (_M.Rows() != kRows) { _Fail("몸통 행 수 불일치"); return; }

		// 상태 슬롯의 값을 팔마다 다르게 채운다 — ⚠️ **값만** 다르다.
		Array<float> v = _val;
		for (uint32 ctx = 0; ctx < kPoolN * kBatch; ++ctx)
			for (uint32 t = 0; t < kTime; ++t)
			{
				const uint32 base = _Row(ctx, t, 0u);
				for (uint32 a = 0; a < kStateAx; ++a)
				{
					float x = 0.0f;
					if (_arm == 0u || _arm == 3u) x = _stateReal[base + a];
					else if (_arm == 2u)
					{
						// 무작위 — 그 스텝과 **무관**하지만 같은 분포(관측 상태의 범위 ±1)다.
						const uint32 h = MLTWorld::Hash(_seed * 7919u + ctx * 131u + t * 17u + a,
							MLTSalt::Start, 91u);
						x = MLTWorld::Unit(h);
					}
					v.Data()[base + a] = x;
				}
			}
		if (!_M.UploadPool(v, _tgt, kPoolN)) { _Fail("몸통 풀 업로드 실패"); return; }
		if (!_M.UploadSymbolPool(_sym, kPoolN)) { _Fail("심볼 풀 업로드 실패"); return; }
		_step = 0u; _first[_arm] = 0.0f; _last[_arm] = 0.0f;
		_BeginEval(false);
	}

	// ⚠️⚠️ **CE 는 풀 전체를 forward 한 평균이다** — 학습 스트림의 한 칸으로 읽으면 「처음」과
	//   「마지막」이 **서로 다른 배치**의 값이라 `lr=0` 팔이 갱신 0번에도 움직인다(실측 5.8272→5.7348).
	static void _BeginEval(bool post) { _st = kBodyEval; _ev = 0u; _post = post; _sumCe = 0.0; }

	static void _BodyEval()
	{
		if (_ev > 0u)
		{
			float ls = 0.0f;
			if (!_M.ReadLoss(ls)) { _Fail("몸통 손실 리드백"); return; }
			if (!(ls == ls) || ls > 1.0e30f) _finite = false;
			_sumCe += (double)ls;
		}
		if (_ev < kPoolN)
		{
			_M.SelectStep(_ev);
			if (!_M.Forward()) { _Fail("몸통 평가 forward"); return; }
			++_ev; return;
		}
		const float mean = (float)(_sumCe / (double)kPoolN);
		if (!_post) { _first[_arm] = mean; _step = 0u; _st = kBodyTrain; return; }
		_last[_arm] = mean;
		_ArmDone();
	}

	// ⭐ 학습 중에는 손실을 **안 읽는다**(리드백 스톨이 사라진다 — 판정은 평가 패스가 한다).
	static void _BodyTrain()
	{
		if (_step >= kBodySteps) { _BeginEval(true); return; }
		for (uint32 i = 0; i < kBodyPerTick && _step < kBodySteps; ++i)
		{
			_M.SelectStep(_step % kPoolN);
			if (!_M.Forward() || !_M.Backward() || !_M.AdamStep((_arm == 3u) ? 0.0f : 1.0f))
			{ _Fail("몸통 스텝 실패"); return; }
			++_step;
		}
	}

	static void _ArmDone()
	{
		_ce[_arm][_seed] = _last[_arm];
		LogA("[mlt] ⏳   %s 씨앗 %2u · CE %.4f → **%.4f**\n",
			_ArmName(), _seed, (double)_first[_arm], (double)_last[_arm]);
		if (++_arm < kArms) { _st = kBodyInit; return; }

		const bool learn = _ce[0][_seed] < kDrop * _first[0];
		const bool beat  = _ce[0][_seed] < _marg[_seed];
		const bool flat  = Abs(_ce[3][_seed] - _first[3]) <= kFlatRel * Abs(_first[3]);
		_seedOk[_seed] = learn && beat && flat && _finite;
		LogA("[mlt] ⏳ 씨앗 %2u 선행 — 학습 %s · 주변분포 넘음 %s · lr=0 평탄 %s\n",
			_seed, learn ? "✅" : "⛔", beat ? "✅" : "⛔", flat ? "✅" : "⛔");
		++_seed; _st = kEncInit;
	}

	static void _Summary()
	{
		uint32 ok = 0u, t1 = 0u, t2 = 0u;
		double m0 = 0.0, m1 = 0.0, m2 = 0.0, mm = 0.0;
		for (uint32 s = 0; s < kSeeds; ++s)
		{
			if (!_seedOk[s]) continue;
			++ok;
			m0 += _ce[0][s]; m1 += _ce[1][s]; m2 += _ce[2][s]; mm += _marg[s];
			if (_ce[1][s] > _ce[0][s]) ++t1;
			if (_ce[2][s] > _ce[0][s]) ++t2;
		}
		if (ok > 0u) { m0 /= ok; m1 /= ok; m2 /= ok; mm /= ok; }
		const bool p1 = (t1 >= kSignPass), p2 = (t2 >= kSignPass);

		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] ⏳ **회차 50 · P3-C1 결과** — 선행을 통과한 씨앗 %u/%u\n", ok, kSeeds);
		LogA("[mlt] ⏳   평균 CE — 주변분포 **%.4f** · ㈀ 온전 **%.4f** · ㈁ 상수 **%.4f** · ㈂ 무작위 **%.4f**\n",
			mm, m0, m1, m2);
		LogA("[mlt] ⏳   **표제 ㈁>㈀ — %u/%u**(필요 %u) → %s\n", t1, kSeeds, kSignPass, p1 ? "통과" : "⛔");
		LogA("[mlt] ⏳   **표제 ㈂>㈀ — %u/%u**(필요 %u) → %s\n", t2, kSeeds, kSignPass, p2 ? "통과" : "⛔");
		if (ok < kSignPass)
			LogA("[mlt] ⏳   ⭐ 판정 = ⛔ **판정불가**(선행 관문) — 배관/과제만 읽고 손잡이를 훑지 않는다\n");
		else if (p1 && p2)
			LogA("[mlt] ⏳   ⭐ 판정 = ✅ **관문 ㉠ 통과 — 상태가 비전 예측을 돕는다**\n");
		else if (p1 || p2)
			LogA("[mlt] ⏳   ⭐ 판정 = ⚠️ **판정불가** — 한 팔만 나빠졌다(상수와 무작위는 뜻이 다르다)\n");
		else
			LogA("[mlt] ⏳   ⭐ 판정 = ⛔ **상태 채널이 안 읽힌다** — 크기/스텝을 늘리지 않고 배치를 의심한다\n");
		LogA("[mlt] ⏳   ⚠️ 진실 접촉 **%llu** · 고정 문맥 %u개의 진단이다(일반화·경험 학습으로 인용하지 않는다)\n",
			(unsigned long long)_M.TruthTouches(), kPoolN * kBatch);
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		_E.Destroy(); _done = true;
	}

	static void _Fail(const char* why)
	{
		LogA("[mlt] ⏳ ⛔ %s (씨앗 %u · 팔 %u · 단계 %u)\n", why, _seed, _arm, _st);
		_E.Destroy(); _done = true;
	}
};
