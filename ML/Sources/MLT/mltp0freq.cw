// mltp0freq.cw — 🔍 **P0 회차 5 · 「분해력의 대가로 보간을 잃었나」** (`kFreqMax` 8 vs 32)
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문** — ⚠️ 재기 전에 적었다. 정본은 `mltlog_1.md` 회차 4 의 「회차 5 등록」이다.
// ══════════════════════════════════════════════════════════════════════════════
//
// ★ **무엇을 가르나**
//
//   회차 4 가 낸 것: 표제 `R̄` ≈ 0.70/0.68/0.34 은 **통계 재현**됐는데 **보간이 통째로 실패**했다
//   (`D̄_band` = −15.5 / −9.9 / −11.8 · 밴드에서 평균 버킷 거리 10~15 · 무작위 ≈22).
//   그리고 **밴드 밖은 잘한다.** ⇒ *"규칙이 아니라 구간 표가 섰다."*
//
//   그 원인으로 가설이 **둘** 있고, 이 라운드가 그 둘을 가른다:
//   ```
//   ㈀ 고주파 인코딩이 일반화를 막았다
//      `kFreqMax` 를 8 → 32 로 올려 **분해력을 얻은 대가로 보간을 잃었다.**
//      근거: ω=32 면 [−1,1] 에 10주기 ⇒ 밴드(폭 0.2)가 그 주파수에서 **1주기 이상**이다
//            ⇒ Φ 가 밴드 안에서 이웃과 위상을 안 나눠 갖고 **국소적으로 고유**해진다 ⇒ 룩업.
//      예측: `kFreqMax = 8` 에서 `D_band` 가 **오른다.** 그리고 정확도는 **내려간다.**
//   ㈁ 주파수와 무관하다
//      안 물어본 구간의 조건부는 어차피 학습을 못 받는다.
//      예측: 8 에서도 `D_band` 가 **안 오른다.**
//   ```
//   ⚠️⚠️ **「㈀ 이 맞다」로 읽으려면 둘 다여야 한다** — `D_band` 상승 **그리고** 정확도 하락.
//     `D_band` 만 오르고 정확도가 안 내려가면 그것은 「대가」가 아니라 **`kFreqMax = 32` 로 둔
//     등록이 그냥 틀렸던 것**이고, 그렇게 적는다. ★ 이 구분을 미리 박아 두는 것이 이 등록문의 핵이다.
//
//   **설계**: `kFreqMax ∈ {8, 32}` × **중간 난이도만**(hold=5) × 판정 씨앗 **12~23** = **24회**
//     · 훈련 600스텝(에피소드 1000~) · 시험 에피소드 0~31(2048예측) · 홀드아웃은 **현재값** 밴드
//     · ⚠️ 그 밖의 모든 것은 회차 4 와 **같다**(같은 씨앗·같은 에피소드·같은 스텝 수)
//   ⚠️ 중간 한 점으로 줄인 근거: ㉠(표제)이 **두 회차 연속 재현**됐으므로 이 라운드가 묻는 것은
//     난이도 곡선이 아니라 **인코딩의 함수로서의 보간**이다. ★ 조용히 줄이지 않고 적는다.
//
//   **읽는 칸**(⚠️ 봉우리를 고른 지표와 검정을 건 지표를 같은 줄에)
//     · 표제 = **`D̄_band`** · 같이 읽는 것 = **`D̄_out`(밴드 밖)** · 정확도 · `R̄`
//     · 부호검정은 **`D_band(8) − D_band(32)` 의 부호**에 건다 ⇒ **10/12**
//     ⚠️ `D̄_all` 은 **안 읽는다** — 회차 4 에서 밴드(표본 10%)가 전체를 오염시켜 음수가 됐다.
//
//   **관문**
//     ㉠ `D̄_band(8) > D̄_band(32)` **그리고** 부호검정 **≥ 10/12**
//     ㉡ 「대가」가 실제로 있나 — `정확도(8) < 정확도(32)`
//     ㉢ 배관 — 두 팔 다 `D̄_out > 0`(밴드 **밖**에서는 복사보다 좋다). ⚠️ 이것이 깨지면
//        그 팔은 통째로 못 배운 것이고 `D_band` 비교가 뜻을 잃는다 ⇒ **판정불가**
//     ㉣ 배관 — `probs` 행 합 1.0 ± 0.01 · 전 구간 유한

using namespace PE;

class MLTP0Freq
{
public:
	static bool Done() { return _run >= kRuns; }

	static void Tick(RHI* rhi)
	{
		if (_run >= kRuns || rhi == nullptr) return;
		// ⚠️ **기본에서 껐다** — 회차 5 가 끝났고 결론이 `kFreqMax = 8`(기본값)에 반영됐다.
		//   ★ 다시 돌리려면 `-mltfreq`. **지운 것이 아니라 끈 것**이다.
		if (!OS::CommandLine::Has("-mltfreq"))
		{
			LogA("[mlt] 🔍 회차 5(`kFreqMax` 8 vs 32)는 **꺼져 있다**(`-mltfreq` 로 켠다) — 결과:"
			     " D̄_band **−0.546(8) vs −9.883(32)** · 부호검정 12/12 ⇒ 기본값을 **8** 로 내렸다\n");
			_run = kRuns;
			return;
		}
			// ⚠️⚠️⚠️ **P0 은 `kCtx = 64`(원래 배치)로 등록됐다.** 지금은 P1 의 배치다
			//   ⇒ 이 하네스를 그대로 돌리면 **등록문과 다른 것을 재고** 그 수를 P0 의 수인 것처럼
			//   적게 된다. ★ 그래서 **크게 집고 멈칸다.**
			//   ⇒ 그 회차를 재현하려면 **그 초기 커밋으로 돌아가라**(`mltlog_1.md` 회차 3·4·5).
			if (MLTModelCfg::kAxes != 1u || MLTModelCfg::kCtx != 64u)
			{
				LogA("[mlt] 🔍 ⛔⛔ **이 하네스는 P0 의 배치(kCtx=64 · 원래 1축)를 전제한다** —"
				     " 지금은 kCtx=%u · 축 %u 다. **재현은 그 커밋에서 하라**(회차 3~5)\n",
					MLTModelCfg::kCtx, MLTModelCfg::kAxes);
				_run = kRuns;
				return;
			}
		if (!_banner) { _Banner(); _banner = true; }

		if (_st == kInit)
		{
			if (!_M.Setup(rhi))
			{ LogA("[mlt] 🔍 모델 준비 실패(run %u)\n", _run); _run = kRuns; return; }
			// ★ **여기가 이 라운드의 유일한 손잡이다.**
			_M.SetFreqMax(_FreqOf(_run));
			MLTP0::BaselineSeed(_SeedOf(_run), kHold, kEvalEpi0, kEvalEpis, _bCopy, _bBayes);
			_step = 0u; _eval = 0u; _hits = 0u; _n = 0u; _hitsB = 0u; _nB = 0u;
			_sumP = 0.0f; _first = 0.0f; _last = 0.0f; _finite = true;
			_dist = 0.0f; _distB = 0.0f; _distO = 0.0f;
			_st = kTrain;
			return;
		}

		if (_st == kTrain)
		{
			if (_step > 0u)
			{
				float ls = 0.0f;
				if (!_M.ReadLoss(ls)) { LogA("[mlt] 🔍 손실 리드백 실패\n"); _run = kRuns; return; }
				if (!(ls == ls) || ls > 1.0e30f) _finite = false;
				if (_step == 1u) _first = ls;
				_last = ls;
			}
			if (_step >= kTrainSteps) { _st = kEvalUp; return; }

			Array<float> val, tgt, band;
			_Batch(_SeedOf(_run), kTrainEpi0 + _step * MLTModelCfg::kBatch, true, val, tgt, band);
			if (!_M.Upload(val, tgt)) { LogA("[mlt] 🔍 업로드 실패\n"); _run = kRuns; return; }
			if (!_M.Forward() || !_M.Backward() || !_M.AdamStep())
			{ LogA("[mlt] 🔍 스텝 실패(run %u · step %u)\n", _run, _step); _run = kRuns; return; }
			++_step;
			return;
		}

		if (_st == kEvalUp)
		{
			if (_eval >= kEvalB) { _Finish(); return; }
			_Batch(_SeedOf(_run), kEvalEpi0 + _eval * MLTModelCfg::kBatch, false, _evVal, _evTgt, _evBand);
			if (!_M.Upload(_evVal, _evTgt)) { LogA("[mlt] 🔍 시험 업로드 실패\n"); _run = kRuns; return; }
			if (!_M.Forward()) { LogA("[mlt] 🔍 시험 forward 실패\n"); _run = kRuns; return; }
			_st = kEvalRd;
			return;
		}

		{
			uint32 h = 0u, n = 0u, hb = 0u, nb = 0u;
			float sp = 0.0f, dd = 0.0f, ddb = 0.0f, ddo = 0.0f;
			if (!_M.ReadHits(_evTgt, _evBand, h, n, hb, nb, sp, dd, ddb, ddo))
			{ LogA("[mlt] 🔍 시험 리드백 실패\n"); _run = kRuns; return; }
			_hits += h; _n += n; _hitsB += hb; _nB += nb; _sumP += sp;
			_dist += dd; _distB += ddb; _distO += ddo;
			++_eval;
			_st = kEvalUp;
		}
	}

private:
	static constexpr uint32 kSeed0 = 12u, kSeeds = 12u;
	static constexpr uint32 kRuns  = kSeeds * 2u;      // 8 팔 12 + 32 팔 12
	static constexpr int    kHold  = MLTWorldCfg::kHoldMid;
	static constexpr uint32 kTrainSteps = 600u;
	static constexpr uint32 kTrainEpi0  = 1000u;
	static constexpr uint32 kEvalEpi0   = 0u;
	static constexpr uint32 kEvalB      = 4u;
	static constexpr uint32 kEvalEpis   = kEvalB * MLTModelCfg::kBatch;
	static constexpr uint32 kSignNeed   = 10u;

	// ⚠️ 팔 순서: **앞 12회가 `kFreqMax = 8`**, 뒤 12회가 32. 번호를 역할에 고정한다.
	static float  _FreqOf(uint32 r) { return (r < kSeeds) ? 8.0f : 32.0f; }
	static uint32 _SeedOf(uint32 r) { return kSeed0 + (r % kSeeds); }

	enum { kInit = 0, kTrain, kEvalUp, kEvalRd };

	inline static MLTModel _M;
	inline static bool   _banner = false;
	inline static uint32 _run = 0u;
	inline static int    _st = kInit;
	inline static uint32 _step = 0u, _eval = 0u, _hits = 0u, _n = 0u, _hitsB = 0u, _nB = 0u;
	inline static float  _sumP = 0.0f, _first = 0.0f, _last = 0.0f;
	inline static float  _dist = 0.0f, _distB = 0.0f, _distO = 0.0f;
	inline static MLTP0::Base _bCopy{}, _bBayes{};
	inline static bool   _finite = true;
	inline static Array<float> _evVal, _evTgt, _evBand;

	inline static float _rAcc[kRuns] = { 0.0f };
	inline static float _rR[kRuns]   = { 0.0f };
	inline static float _rDB[kRuns]  = { 0.0f };
	inline static float _rDO[kRuns]  = { 0.0f };
	inline static bool  _rOk[kRuns]  = { false };

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🔍 **P0 회차 5 — `kFreqMax` 8 vs 32** · 중간(hold=%d) · 씨앗 %u~%u · **%u회**\n",
			kHold, kSeed0, kSeed0 + kSeeds - 1u, kRuns);
		LogA("[mlt] 🔍   묻는 것: **분해력의 대가로 보간을 잃었나** — 「㈀ 맞다」는 `D_band` 상승"
		     " **그리고** 정확도 하락이 **둘 다** 있어야 한다\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

	static void _Batch(uint32 seed, uint32 epi0, bool holdout,
		Array<float>& val, Array<float>& tgt, Array<float>& band)
	{
		typedef MLTModelCfg M;
		val.Reset(0); tgt.Reset(0); band.Reset(0);
		float y[M::kCtx + 1u];
		for (uint32 b = 0; b < M::kBatch; ++b)
		{
			MLTWorld w;
			w.Reset(seed, epi0 + b, kHold, 0);
			y[0] = w.State().y;
			for (uint32 t = 0; t < M::kCtx; ++t) { w.Step(); y[t + 1u] = w.State().y; }
			for (uint32 t = 0; t < M::kCtx; ++t) val.Add(y[t]);
			for (uint32 t = 0; t < M::kCtx; ++t)
			{
				const bool inBand = (y[t] >= MLTP0::BandLo() && y[t] < MLTP0::BandHi());
				tgt.Add((holdout && inBand) ? M::kIgnoreTgt : (float)MLTP0::Bucket(y[t + 1u]));
				band.Add(inBand ? 1.0f : 0.0f);
			}
		}
	}

	static void _Finish()
	{
		const float acc  = (_n > 0u) ? (float)_hits / (float)_n : 0.0f;
		const float dBnd = (_eval > 0u) ? _distB / (float)_eval : 0.0f;
		const float dOut = (_eval > 0u) ? _distO / (float)_eval : 0.0f;
		const float win  = _bBayes.acc - _bCopy.acc;
		const float R    = (win > 1.0e-4f) ? (acc - _bCopy.acc) / win : 0.0f;
		const float wB   = _bCopy.distBand - _bBayes.distBand;
		const float wO   = _bCopy.distOut  - _bBayes.distOut;
		const float DB   = (wB > 1.0e-4f) ? (_bCopy.distBand - dBnd) / wB : 0.0f;
		const float DO   = (wO > 1.0e-4f) ? (_bCopy.distOut  - dOut) / wO : 0.0f;
		const float sp   = (_eval > 0u) ? _sumP / (float)_eval : 0.0f;

		_rAcc[_run] = acc; _rR[_run] = R; _rDB[_run] = DB; _rDO[_run] = DO;
		_rOk[_run] = _finite && (Abs(sp - 1.0f) <= 0.01f);

		LogA("[mlt] 🔍 [%2u/%u] freq=%2.0f 씨앗%2u · 손실 %.3f→%.3f · 정확도 %.2f%% (R=%.3f)"
		     " · 밴드거리 %.3f(복사 %.3f) **D_band=%.3f** · 밴드밖 %.3f(복사 %.3f) **D_out=%.3f**%s\n",
			_run + 1u, kRuns, (double)_FreqOf(_run), _SeedOf(_run),
			(double)_first, (double)_last, (double)(acc * 100.0f), (double)R,
			(double)dBnd, (double)_bCopy.distBand, (double)DB,
			(double)dOut, (double)_bCopy.distOut, (double)DO,
			_rOk[_run] ? "" : "  ⛔배관");

		++_run;
		_st = kInit;
		if (_run >= kRuns) _Judge();
	}

	static void _Judge()
	{
		float a8 = 0.0f, a32 = 0.0f, b8 = 0.0f, b32 = 0.0f, o8 = 0.0f, o32 = 0.0f, r8 = 0.0f, r32 = 0.0f;
		uint32 sign = 0u;
		bool plumbing = true;
		for (uint32 i = 0; i < kSeeds; ++i)
		{
			a8 += _rAcc[i]; a32 += _rAcc[kSeeds + i];
			b8 += _rDB[i];  b32 += _rDB[kSeeds + i];
			o8 += _rDO[i];  o32 += _rDO[kSeeds + i];
			r8 += _rR[i];   r32 += _rR[kSeeds + i];
			if (_rDB[i] > _rDB[kSeeds + i]) ++sign;
			if (!_rOk[i] || !_rOk[kSeeds + i]) plumbing = false;
		}
		const float k = 1.0f / (float)kSeeds;
		a8 *= k; a32 *= k; b8 *= k; b32 *= k; o8 *= k; o32 *= k; r8 *= k; r32 *= k;

		int fail = 0;
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🔍 **P0 회차 5 결과** — `kFreqMax` 8 vs 32 (중간 난이도 · 씨앗 12~23)\n");
		LogA("[mlt] 🔍   freq= 8 : 정확도 %.2f%% · R̄ %.3f · **D̄_band %.3f** · D̄_out %.3f\n",
			(double)(a8 * 100.0f), (double)r8, (double)b8, (double)o8);
		LogA("[mlt] 🔍   freq=32 : 정확도 %.2f%% · R̄ %.3f · **D̄_band %.3f** · D̄_out %.3f\n",
			(double)(a32 * 100.0f), (double)r32, (double)b32, (double)o32);

		if (!plumbing) { LogA("[mlt] 🔍   ⛔ ㉣ 배관이 깨진 실행이 있다 — **판정불가**\n"); ++fail; }
		else             LogA("[mlt] 🔍   ✅ ㉣ 배관 — probs 합 1.0 · 전 구간 유한\n");

		const bool g3 = (o8 > 0.0f && o32 > 0.0f);
		LogA("[mlt] 🔍   %s ㉢ 배관 — 두 팔 다 밴드 **밖**에서 복사보다 좋다 (D̄_out %.3f · %.3f > 0)\n",
			g3 ? "✅" : "⛔", (double)o8, (double)o32);
		if (!g3) ++fail;

		const bool g1 = (b8 > b32) && (sign >= kSignNeed);
		LogA("[mlt] 🔍   %s ㉠ `D̄_band(8) > D̄_band(32)` — %.3f vs %.3f · 부호검정 **%u/12** (필요 %u)\n",
			g1 ? "✅" : "⛔", (double)b8, (double)b32, sign, kSignNeed);

		const bool g2 = (a8 < a32);
		LogA("[mlt] 🔍   %s ㉡ 「대가」가 있나 — 정확도 %.2f%%(8) < %.2f%%(32)\n",
			g2 ? "✅" : "⛔", (double)(a8 * 100.0f), (double)(a32 * 100.0f));

		LogA("[mlt] ══════════════════════════════════════════════════\n");
		// ⚠️⚠️ **읽는 규칙을 미리 박아 뒀다** — 여기서 정하지 않는다.
		if (fail > 0)
			LogA("[mlt] 🔍 ⛔ **배관 관문이 깨졌다 — 이 라운드는 판정불가다**\n");
		else if (g1 && g2)
			LogA("[mlt] 🔍 ✅ **㈀ 가 맞다: 분해력의 대가로 보간을 잃었다.**"
			     " `kFreqMax` 는 정확도↔일반화의 **손잡이**다 ⇒ 등록에 그렇게 적는다\n");
		else if (g1 && !g2)
			LogA("[mlt] 🔍 ⚠️ **「대가」가 아니다 — `kFreqMax = 32` 로 둔 등록이 그냥 틀렸던 것이다.**"
			     " 8 이 보간도 좋고 정확도도 안 나쁘다 ⇒ 32 를 고른 근거를 기록에서 정정하라\n");
		else
			LogA("[mlt] 🔍 ⚠️ **㈁ 가 맞다: 주파수와 무관하다.** 안 물어본 구간의 조건부는 어차피"
			     " 학습을 못 받는다 ⇒ 다음 물음은 **인코딩이 아니라 구조**다(축을 늘려 규칙을 강제하는 P1)\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}
};
