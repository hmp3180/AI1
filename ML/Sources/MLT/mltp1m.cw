// mltp1m.cw — 🔬 **회차 12 · 「A 걸음 수를 맞춘 대조군」.** 순수 덮음이 얼마나 남나
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문** — ⚠️ 재기 전에 적는다. 정본은 `mltlog_1.md` 회차 11 의 「회차 12 등록」이다.
// ══════════════════════════════════════════════════════════════════════════════
//
// ★ **무엇을 가르나 — 그리고 왜 회차 11 로는 부족했나**
//
//   회차 11 이 «재방문이다» 를 확정했다(P +0.639 · Q +0.537 · 12/12). 그런데 그 팔들의
//   **낙폭이 양수**였다(+0.131 / +0.120) — 즉 A 가 **좋아졌다**.
//   ⚠️⚠️ 그것을 «간섭이 사라졌다» 로 읽으면 틀린다: 재방문 팔은 **A 를 150(또는 225)스텝
//     더 배웠다.** ⇒ 양수의 일부는 **「A 를 더 배운 몫」**이다.
//   ⇒ ***「A 걸음 수를 맞춘 대조군」*** 이 없어서 그 둘을 못 갈랐다. 이 회차가 그것이다.
//
// ══════════════════════════════════════════════════════════════════════════════
// ① 팔 넷 — **`A 총 걸음`을 짝마다 고정**하고 **B 를 배우나 안 배우나**만 다르게
// ══════════════════════════════════════════════════════════════════════════════
//   | 팔 | 1단계 | 2단계 | `A 총 걸음` | B 를 배우나 |
//   |---|---|---|---|---|
//   | **M1** | A 300 | B150 + A재방문150 (섞음 · 총 300스텝) | **450** | 예 (`150·lr`) |
//   | **M0** | A 300 | **A 150** (2단계를 **150스텝만** 돈다) | **450** | **아니오** |
//   | **N1** | A 300 | B 75 + A재방문225 (섞음 · 총 300스텝) | **525** | 예 (`75·lr`) |
//   | **N0** | A 300 | **A 225** | **525** | **아니오** |
//
//   ⚠️⚠️ **총 걸음 수가 팔마다 다르다 — 그것이 의도다.** 이번에 맞추는 것은 **A 걸음**이고,
//     「같은 비용(총 걸음)」은 회차 9·10·11 이 이미 봤다. ★ 한 회차가 두 축을 동시에 맞출 수 없다.
//   ⚠️ `M1`/`N1` 은 회차 11 의 `P1`/`Q1` 과 **글자 그대로 같다** ⇒ 그 수가 재현되는지도 같이 본다
//     (배관 재현의 공짜 검사다).
//   ⚠️ 재방문·A단계 모두 **lr ×1** 이고 B 표적 스텝만 ×1 이다(회차 11 과 같은 규약).
//
// ══════════════════════════════════════════════════════════════════════════════
// ② 읽는 칸과 문턱
// ══════════════════════════════════════════════════════════════════════════════
//   · 표제 = **`R_A(M1) − R_A(M0)`** 과 **`R_A(N1) − R_A(N0)`**
//     ★ **음수면 그것이 「순수 덮음」**이다 — A 걸음이 같은데 B 를 배운 쪽이 낮다는 뜻이다.
//   · ⚠️⚠️ **같은 줄에 `R_B`** — `M0`/`N0` 은 B 를 **안 배운다** ⇒ `R_B` 가 낮을 것이고,
//     그것이 **재방문의 대가를 읽는 칸**이다(덮음을 없애는 값을 B 로 치른다).
//   **문턱**
//     · 두 짝 모두 `|차이| < 0.05`(≈3·SE) ⇒ ***"재방문이 덮음을 거의 다 없앤다."***
//     · `차이 ≤ −0.15`(≈9·SE) ⇒ ***"재방문으로도 덮음이 남는다"*** — 그 크기를 적는다.
//     · 그 사이 ⇒ ***"중간"*** — 단정하지 않는다.
//   **부호검정**은 `R_A(M1) − R_A(M0)` 의 부호에 건다(10/12).
//     ★ `M` 짝을 고른 근거: 회차 11 에서 **부호검정을 건 짝**이 `P`(= 이 회차의 `M`)다 ⇒ 같은 자리.
//
//   ⚠️⚠️ **미리 적는 분기**
//     · 「거의 다 없앤다」 ⇒ 다음 물음은 ***"어떻게 **학습 자체**가 그 재방문을 만들게 할까"***
//       이고, 그 전에 **대가(`R_B`)의 크기**를 결론에 같이 싣는다.
//     · 「남는다」 ⇒ 재방문은 **부분 해법**이다 ⇒ 남은 몫이 무엇의 함수인지 **또 폭을 잰다**
//       (⚠️ 여기서도 만들지 않는다).
//   ⚠️ 이 회차도 **아무것도 만들지 않는다.**
//
// ⚠️ 비용: 4팔 × 12씨앗 = **48 실행** · 실행당 450~600 스텝 ⇒ **≈4분**.

using namespace PE;

class MLTP1M
{
public:
	static bool Done() { return _run >= kRuns; }

	static void Tick(RHI* rhi)
	{
		if (_run >= kRuns || rhi == nullptr) return;
		if (MLTModelCfg::kAxes != MLTP1::kAxes || MLTModelCfg::kTime != MLTP1::kTime)
		{ LogA("[mlt] 🔬 ⛔⛔ 축/시각 전제가 다르다\n"); _run = kRuns; return; }
		// ⚠️ **기본에서 껐다** — 회차 12 로 쟀다. ★ 다시 돌리려면 `-mltmatch`.
		if (!OS::CommandLine::Has("-mltmatch"))
		{
			LogA("[mlt] 🔬 회차 12(A 걸음 맞춘 대조군)는 **꺼져 있다**(`-mltmatch`) — 기록:"
			     " M +0.028(7/12) · N −0.043 ⇒ 「재방문이 덮음을 거의 다 없앤다」\n");
			_run = kRuns;
			return;
		}
		if (!_banner) { _Banner(); _banner = true; }

		if (_st == kInit)
		{
			if (!_M.Setup(rhi)) { LogA("[mlt] 🔬 준비 실패(run %u)\n", _run); _run = kRuns; return; }
			for (uint32 a = 0; a < MLTP1::kAxes; ++a)
				MLTP1::_Baseline(a, kHold, _Seed(_run), 1u, kEvalEpi0, kEvalEpis, _bC[a], _bB[a]);
			_ph = 0u; _step = 0u; _finite = true;
			_st = kTrain;
			return;
		}

		if (_st == kTrain)
		{
			if (_step > 0u)
			{
				float ls = 0.0f;
				if (!_M.ReadLoss(ls)) { LogA("[mlt] 🔬 손실 리드백 실패\n"); _run = kRuns; return; }
				if (!(ls == ls) || ls > 1.0e30f) _finite = false;
			}
			if (_ph >= 2u) { _Finish(); return; }
			const uint32 want = (_ph == 0u) ? kStage1 : _Stage2Steps(_run);
			if (_step >= want) { _StartEval(); return; }

			const uint32 K = MLTModelCfg::kPool;
			const uint32 slot = _step % K;
			if (slot == 0u)
			{
				const uint32 n = ((want - _step) < K) ? (want - _step) : K;
				_pv.Reset(0); _pt.Reset(0);
				for (uint32 k = 0; k < n; ++k)
				{
					Array<float> v, g;
					_Batch(_Seed(_run), 1000u + _ph * 20000u + (_step + k) * MLTModelCfg::kBatch,
						_step + k, false, v, g);
					for (uint32 i = 0; i < v.Count(); ++i) _pv.Add(v[i]);
					for (uint32 i = 0; i < g.Count(); ++i) _pt.Add(g[i]);
				}
				if (!_M.UploadPool(_pv, _pt, n)) { LogA("[mlt] 🔬 풀 업로드 실패\n"); _run = kRuns; return; }
			}
			_M.SelectStep(slot);
			// ⚠️ 이 회차는 **lr 배율을 안 쓴다**(모든 스텝 ×1) — 맞추는 것이 A 걸음이다.
			if (!_M.Forward() || !_M.Backward() || !_M.AdamStep())
			{ LogA("[mlt] 🔬 스텝 실패(ph %u · step %u)\n", _ph, _step); _run = kRuns; return; }
			++_step;
			return;
		}

		if (_st == kEvalUp)
		{
			if (_eb >= kEvalB) { _EvalDone(); return; }
			_Batch(_Seed(_run), kEvalEpi0 + _eb * MLTModelCfg::kBatch, 0u, true, _ev, _et);
			if (!_M.Upload(_ev, _et)) { LogA("[mlt] 🔬 시험 업로드 실패\n"); _run = kRuns; return; }
			if (!_M.Forward()) { LogA("[mlt] 🔬 시험 forward 실패\n"); _run = kRuns; return; }
			_st = kEvalRd;
			return;
		}

		// kEvalRd
		{
			Array<float> m;
			float sp = 0.0f;
			for (uint32 a = 0; a < MLTP1::kAxes; ++a)
			{
				m.Reset(0);
				for (uint32 r = 0; r < MLTModelCfg::kRows; ++r)
					m.Add((((r % MLTModelCfg::kCtx) % MLTP1::kAxes) == a) ? 1.0f : 0.0f);
				uint32 h = 0u, n = 0u, hb = 0u, nb = 0u;
				float dd = 0.0f, ddb = 0.0f, ddo = 0.0f;
				if (!_M.ReadHits(_et, m, h, n, hb, nb, sp, dd, ddb, ddo))
				{ LogA("[mlt] 🔬 리드백 실패\n"); _run = kRuns; return; }
				_hit[a] += hb; _cnt[a] += nb;
			}
			_sumP += sp;
			++_eb;
			_st = kEvalUp;
		}
	}

private:
	static constexpr uint32 kSeed0 = 12u, kSeeds = 12u;
	static constexpr uint32 kArms = 4u;                  // M1 · M0 · N1 · N0
	static constexpr uint32 kRuns = kArms * kSeeds;      // 48
	static constexpr int    kHold = MLTWorldCfg::kHoldMid;
	static constexpr uint32 kStage1 = 300u;
	static constexpr uint32 kEvalEpi0 = 0u, kEvalB = 4u;
	static constexpr uint32 kEvalEpis = kEvalB * MLTModelCfg::kBatch;
	static constexpr float  kSmall = 0.05f;              // ② 「거의 다 없앤다」
	static constexpr float  kBig   = 0.15f;              // ② 「남는다」
	static constexpr uint32 kSignNeed = 10u;

	static uint32 _Arm(uint32 r)  { return r / kSeeds; }   // 0=M1 · 1=M0 · 2=N1 · 3=N0
	static uint32 _Seed(uint32 r) { return kSeed0 + (r % kSeeds); }
	// 2단계의 스텝 수 — ⭐ `M0`/`N0` 은 **A 걸음만큼만** 돈다(그래서 짧다).
	static uint32 _Stage2Steps(uint32 r)
	{
		switch (_Arm(r)) { case 0: return 300u; case 1: return 150u; case 2: return 300u; default: return 225u; }
	}
	// 2단계에서 B 표적을 주는 스텝 수(나머지는 A 재방문). `M0`/`N0` 은 0 이다.
	static uint32 _BSteps(uint32 r)
	{
		switch (_Arm(r)) { case 0: return 150u; case 1: return 0u; case 2: return 75u; default: return 0u; }
	}
	// ⭐ B 스텝을 **고르게 섞는다**(몰아 두면 순서 효과가 섞인다 — 회차 11 과 같은 관용구).
	static bool _IsRevisitStep(uint32 r, uint32 step)
	{
		const uint32 nb = _BSteps(r);
		if (nb == 0u) return true;                        // 전부 재방문(= A)
		const uint32 tot = _Stage2Steps(r);
		if (nb >= tot) return false;
		return ((step * nb) / tot) == (((step + 1u) * nb) / tot);
	}
	static const char* _ArmName(uint32 r)
	{
		switch (_Arm(r))
		{
			case 0: return "M1 (A총450 · B150 배움)";
			case 1: return "M0 (A총450 · B  0 배움)";
			case 2: return "N1 (A총525 · B 75 배움)";
			default: return "N0 (A총525 · B  0 배움)";
		}
	}

	enum { kInit = 0, kTrain, kEvalUp, kEvalRd };

	inline static MLTModel _M;
	inline static bool _banner = false;
	inline static uint32 _run = 0u, _ph = 0u, _step = 0u, _eb = 0u;
	inline static int _st = kInit;
	inline static bool _finite = true;
	inline static float _sumP = 0.0f;
	inline static uint32 _hit[MLTP1::kAxes] = { 0u }, _cnt[MLTP1::kAxes] = { 0u };
	inline static MLTP1::Base _bC[MLTP1::kAxes], _bB[MLTP1::kAxes];
	inline static float _phR[2][MLTP1::kAxes] = { { 0.0f } };
	inline static Array<float> _ev, _et, _pv, _pt;

	inline static float _rA0[kRuns] = { 0.0f }, _rA1[kRuns] = { 0.0f }, _rB1[kRuns] = { 0.0f };
	inline static bool  _rOk[kRuns] = { false };

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🔬 **회차 12 · A 걸음 수를 맞춘 대조군** — 순수 덮음이 얼마나 남나 · %u 실행\n", kRuns);
		LogA("[mlt] 🔬   `A 총 걸음`을 짝마다 고정: M짝 = 450 · N짝 = 525 ·"
		     " **B 를 배우나 안 배우나**만 다르게\n");
		LogA("[mlt] 🔬   읽는 칸 = `R_A(1) − R_A(0)` ★ **음수면 그것이 「순수 덮음」**이다"
		     " · 문턱 |차이|<%.2f 거의없음 / ≤−%.2f 남는다 · 부호검정 %u/12\n",
			(double)kSmall, (double)kBig, kSignNeed);
		LogA("[mlt] 🔬   ⚠️ 총 걸음 수가 팔마다 다른 것은 **의도**다(맞추는 것은 A 걸음이다)"
		     " · ⚠️ 이 회차도 **아무것도 만들지 않는다**\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

	static void _StartEval()
	{
		_eb = 0u; _sumP = 0.0f;
		for (uint32 a = 0; a < MLTP1::kAxes; ++a) { _hit[a] = 0u; _cnt[a] = 0u; }
		_st = kEvalUp;
	}

	static void _EvalDone()
	{
		for (uint32 a = 0; a < MLTP1::kAxes; ++a)
		{
			const float acc = _cnt[a] ? (float)_hit[a] / (float)_cnt[a] : 0.0f;
			const float w = _bB[a].acc - _bC[a].acc;
			_phR[_ph][a] = (w > 1.0e-4f) ? (acc - _bC[a].acc) / w : 0.0f;
		}
		++_ph;
		_step = 0u;
		_st = kTrain;
	}

	static void _Batch(uint32 seed, uint32 epi0, uint32 stepNo, bool isEval,
		Array<float>& val, Array<float>& tgt)
	{
		typedef MLTModelCfg M;
		const uint32 A = MLTP1::kAxes, T = MLTP1::kTime;
		const uint32 kAll = 0xFFFFFFFFu;
		uint32 tgtAxis;
		if (isEval)         tgtAxis = kAll;
		else if (_ph == 0u) tgtAxis = 0u;
		else                tgtAxis = _IsRevisitStep(_run, stepNo) ? 0u : 1u;
		val.Reset(0); tgt.Reset(0);
		float v[MLTP1::kAxes][MLTP1::kTime + 1u];
		for (uint32 b = 0; b < M::kBatch; ++b)
		{
			for (uint32 a = 0; a < A; ++a) MLTP1::_Episode(a, seed, epi0 + b, kHold, v[a], nullptr);
			for (uint32 t = 0; t < T; ++t)
				for (uint32 a = 0; a < A; ++a)
				{
					val.Add(v[a][t]);
					const bool on = (tgtAxis == kAll) || (a == tgtAxis);
					tgt.Add(on ? (float)MLTP0::Bucket(v[a][t + 1u]) : M::kIgnoreTgt);
				}
		}
	}

	static void _Finish()
	{
		const float sp = (_eb > 0u) ? _sumP / (float)_eb : 0.0f;
		_rA0[_run] = _phR[0][0]; _rA1[_run] = _phR[1][0]; _rB1[_run] = _phR[1][1];
		_rOk[_run] = _finite && (Abs(sp - 1.0f) <= 0.01f);
		if ((_run % kSeeds) == kSeeds - 1u)
			LogA("[mlt] 🔬 [%2u/%u] %s 마지막 씨앗 · R_A %.3f→**%.3f** · R_B %.3f%s\n",
				_run + 1u, kRuns, _ArmName(_run), (double)_rA0[_run], (double)_rA1[_run],
				(double)_rB1[_run], _rOk[_run] ? "" : "  ⛔배관");
		++_run;
		_st = kInit;
		if (_run >= kRuns) _Judge();
	}

	static void _Judge()
	{
		float ra[kArms] = { 0.0f }, rb[kArms] = { 0.0f };
		bool plumb = true;
		for (uint32 m = 0; m < kArms; ++m)
		{
			float a = 0.0f, b = 0.0f;
			for (uint32 i = 0; i < kSeeds; ++i)
			{
				const uint32 r = m * kSeeds + i;
				a += _rA1[r]; b += _rB1[r];
				if (!_rOk[r]) plumb = false;
			}
			ra[m] = a / (float)kSeeds; rb[m] = b / (float)kSeeds;
		}
		uint32 sign = 0u;   // ★ 검정은 **M 짝**에 건다(회차 11 과 같은 자리)
		for (uint32 i = 0; i < kSeeds; ++i)
			if (_rA1[i] > _rA1[kSeeds + i]) ++sign;
		const float dM = ra[0] - ra[1];
		const float dN = ra[2] - ra[3];

		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🔬 **회차 12 결과 — 순수 덮음**\n");
		for (uint32 m = 0; m < kArms; ++m)
			LogA("[mlt] 🔬   %s · R_A **%.3f** · R_B %.3f\n",
				_ArmName(m * kSeeds), (double)ra[m], (double)rb[m]);
		if (!plumb) LogA("[mlt] 🔬   ⛔ 배관이 깨진 실행이 있다 — **판정불가**\n");
		else        LogA("[mlt] 🔬   ✅ 배관 — probs 합 1.0 · 전 구간 유한\n");

		LogA("[mlt] 🔬   ── 짝 안의 차이(음수 = 순수 덮음) ──\n");
		LogA("[mlt] 🔬   **M 짝**(A 총 450): %.3f − %.3f = **%+.3f** · 부호검정(M1>M0) **%u/12**\n",
			(double)ra[0], (double)ra[1], (double)dM, sign);
		LogA("[mlt] 🔬   **N 짝**(A 총 525): %.3f − %.3f = **%+.3f** (읽는 칸)\n",
			(double)ra[2], (double)ra[3], (double)dN);
		LogA("[mlt] 🔬   ⚠️ **대가**: B 를 배운 쪽의 R_B %.3f/%.3f ↔ 안 배운 쪽 %.3f/%.3f\n",
			(double)rb[0], (double)rb[2], (double)rb[1], (double)rb[3]);

		const bool smallBoth = (Abs(dM) < kSmall) && (Abs(dN) < kSmall);
		const bool bigAny = (dM <= -kBig) || (dN <= -kBig);
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		if (!plumb)
			LogA("[mlt] 🔬 ⛔ 판정불가\n");
		else if (smallBoth)
			LogA("[mlt] 🔬 ✅✅ **재방문이 덮음을 거의 다 없앤다**(|%+.3f| · |%+.3f| < %.2f)"
			     " ⇒ 다음 물음은 «어떻게 **학습 자체**가 그 재방문을 만들게 할까» 이고,"
			     " ⚠️ **대가(R_B)를 결론에 같이 싣는다**\n", (double)dM, (double)dN, (double)kSmall);
		else if (bigAny)
			LogA("[mlt] 🔬 ⚠️⚠️ **재방문으로도 덮음이 남는다**(M %+.3f · N %+.3f)"
			     " ⇒ 재방문은 **부분 해법**이다. 남은 몫이 무엇의 함수인지 **또 폭을 잰다**"
			     "(⚠️ 여기서도 만들지 않는다)\n", (double)dM, (double)dN);
		else
			LogA("[mlt] 🔬 ⚠️ **중간**(M %+.3f · N %+.3f) ⇒ 단정하지 않는다\n", (double)dM, (double)dN);
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}
};
