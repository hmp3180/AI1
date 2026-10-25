// mltp1p.cw — ⚖️ **회차 11 · 쌍 대조군: 「재방문」이냐 「유효 학습률」이냐**
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문** — ⚠️ 재기 전에 적는다. 정본은 `mltlog_1.md` 회차 10 의 「회차 11 등록」이다.
// ══════════════════════════════════════════════════════════════════════════════
//
// ★ **왜 이 회차인가 — 사후 관찰을 등록해서 확인한다**
//
//   회차 10 이 손잡이 둘의 폭을 쟀고 **둘 다 컸다**(lr 0.281 · 리허설 0.674 · 12/12 둘 다).
//   등록문은 그 갈래에 «**반드시 쌍 대조군**으로 가른다» 고 적어 뒀다.
//   ⚠️⚠️ 그런데 그 표를 읽다가 **두 팔이 우연히 같은 총 기울기를 갖는 것**을 알았다:
//   ```
//   리허설 1/2 : B 표적 150스텝 × lr    = 150·lr   → 낙폭 **+0.131**
//   lr×1/2     : B 표적 300스텝 × lr/2  = 150·lr   → 낙폭 **−0.508**
//   ```
//   ⇒ 「재방문이다」로 읽히지만 **그것은 사후 관찰**이다(결과를 보고 나서 알았다).
//   ★ 그래서 이 회차가 **등록해서** 확인한다 — 그리고 **총 기울기 수준을 둘** 둔다
//     (한 수준에서만 성립하면 그것은 「재방문」이 아니라 「그 수준의 성질」이다).
//
// ══════════════════════════════════════════════════════════════════════════════
// ① 팔 넷 — **`B 총 기울기`를 짝마다 고정**하고 **재방문만** 다르게
// ══════════════════════════════════════════════════════════════════════════════
//   | 팔 | B 표적 스텝 | lr 배율 | A 재방문 스텝 | `B 총 기울기` |
//   |---|---|---|---|---|
//   | **P0** | 300 | ×1/2 | **0** | `150·lr` |
//   | **P1** | 150 | ×1 | **150** | `150·lr` |
//   | **Q0** | 300 | ×1/4 | **0** | `75·lr` |
//   | **Q1** | 75 | ×1 | **225** | `75·lr` |
//   ⚠️ 두 번째 단계의 **총 스텝은 언제나 300** 이다(같은 비용). 바뀌는 것은
//     ㈀ 그 중 몇 개가 **B 표적**인가 ㈁ 나머지가 **A 표적(재방문)** 인가 ㈂ lr 배율이다.
//   ⚠️ **A 재방문 스텝의 lr 도 ×1** 이다 — 그 스텝은 「A 를 다시 배우는」 것이고 깎을 이유가 없다.
//   ⚠️ 재방문 스텝은 **B 단계의 에피소드 구간**에서 A 표적을 준다(A 단계의 데이터를 다시 쓰지 않는다)
//     ⇒ **복습이 아니라 「같은 과제를 계속 본다」**다. ★ 그 구분을 적어 둔다.
//
// ══════════════════════════════════════════════════════════════════════════════
// ② 읽는 칸과 문턱
// ══════════════════════════════════════════════════════════════════════════════
//   · 표제 = **`낙폭(P1) − 낙폭(P0)`** 과 **`낙폭(Q1) − 낙폭(Q0)`** (⚠️ 짝 안에서만 견준다)
//   · ⚠️⚠️ **같은 줄에 `R_B(B 뒤)`** — 회차 10 에서 그 칸이 물렸다(리허설은 B 를 덜 배웠다).
//   **문턱**: **두 짝 모두** 차이 **≥ 0.20**(≈12·SE) **그리고** 부호검정 **10/12**
//     ⇒ ***"재방문이다."***
//     ⚠️ **한 짝만** 넘으면 ⇒ ***"총 기울기 수준에 달렸다"*** 로 적는다(재방문이라 단정하지 않는다).
//     ⚠️ **둘 다 못 넘으면** ⇒ 회차 10 의 그 사후 관찰이 **재현되지 않은 것**이고 그렇게 적는다.
//   **부호검정**은 `낙폭(P1) − 낙폭(P0)` 의 부호에 건다(⚠️ 짝 하나에만 — 둘 다 걸면 다중비교가 는다).
//     ★ `P` 짝을 고른 근거: 회차 10 에서 **실제로 관찰된 짝**이 그것이다(`lr×1/2` ↔ `리허설 1/2`).
//
//   ⚠️⚠️ **미리 적는 분기** — *"재방문이다"* 가 나와도 **희소 갱신을 만들지 않는다.**
//     다음 물음은 `mltconcept.md` 가 못 박은 그것이다:
//     ***"어떻게 **학습 자체**가 그 재방문을 만들게 할까?"***
//     (⚠️ semantic 슬롯을 손으로 만드는 것이 **아니다**.) 그리고 그 전에 **`R_B` 의 대가**를 잰다.
//
// ⚠️ 비용: 4팔 × 12씨앗 = **48 실행** · 실행당 `A300 + 300 = 600` 스텝 ⇒ **≈4분**.

using namespace PE;

class MLTP1P
{
public:
	static bool Done() { return _run >= kRuns; }

	static void Tick(RHI* rhi)
	{
		if (_run >= kRuns || rhi == nullptr) return;
		if (MLTModelCfg::kAxes != MLTP1::kAxes || MLTModelCfg::kTime != MLTP1::kTime)
		{ LogA("[mlt] ⚖️ ⛔⛔ 축/시각 전제가 다르다\n"); _run = kRuns; return; }
		// ⚠️ **기본에서 껐다** — 회차 11 로 쟀다. ★ 다시 돌리려면 `-mltpair`.
		if (!OS::CommandLine::Has("-mltpair"))
		{
			LogA("[mlt] ⚖️ 회차 11(쌍 대조군)은 **꺼져 있다**(`-mltpair`) — 기록: P 짝 **+0.639**"
			     " · Q 짝 **+0.537** · 12/12 ⇒ 「재방문이다」\n");
			_run = kRuns;
			return;
		}
		if (!_banner) { _Banner(); _banner = true; }

		if (_st == kInit)
		{
			if (!_M.Setup(rhi)) { LogA("[mlt] ⚖️ 준비 실패(run %u)\n", _run); _run = kRuns; return; }
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
				if (!_M.ReadLoss(ls)) { LogA("[mlt] ⚖️ 손실 리드백 실패\n"); _run = kRuns; return; }
				if (!(ls == ls) || ls > 1.0e30f) _finite = false;
			}
			if (_ph >= 2u) { _Finish(); return; }
			if (_step >= kSteps) { _StartEval(); return; }

			const uint32 K = MLTModelCfg::kPool;
			const uint32 slot = _step % K;
			if (slot == 0u)
			{
				const uint32 n = ((kSteps - _step) < K) ? (kSteps - _step) : K;
				_pv.Reset(0); _pt.Reset(0);
				for (uint32 k = 0; k < n; ++k)
				{
					Array<float> v, g;
					_Batch(_Seed(_run), 1000u + _ph * 20000u + (_step + k) * MLTModelCfg::kBatch,
						_step + k, false, v, g);
					for (uint32 i = 0; i < v.Count(); ++i) _pv.Add(v[i]);
					for (uint32 i = 0; i < g.Count(); ++i) _pt.Add(g[i]);
				}
				if (!_M.UploadPool(_pv, _pt, n)) { LogA("[mlt] ⚖️ 풀 업로드 실패\n"); _run = kRuns; return; }
			}
			_M.SelectStep(slot);
			// ⭐ 두 번째 단계에서만 배율을 건다. ⚠️ **재방문 스텝(A 표적)은 언제나 ×1** 이다.
			float lrMul = 1.0f;
			if (_ph == 1u && !_IsRevisitStep(_run, _step)) lrMul = _LrMul(_run);
			if (!_M.Forward() || !_M.Backward() || !_M.AdamStep(lrMul))
			{ LogA("[mlt] ⚖️ 스텝 실패(ph %u · step %u)\n", _ph, _step); _run = kRuns; return; }
			++_step;
			return;
		}

		if (_st == kEvalUp)
		{
			if (_eb >= kEvalB) { _EvalDone(); return; }
			_Batch(_Seed(_run), kEvalEpi0 + _eb * MLTModelCfg::kBatch, 0u, true, _ev, _et);
			if (!_M.Upload(_ev, _et)) { LogA("[mlt] ⚖️ 시험 업로드 실패\n"); _run = kRuns; return; }
			if (!_M.Forward()) { LogA("[mlt] ⚖️ 시험 forward 실패\n"); _run = kRuns; return; }
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
				{ LogA("[mlt] ⚖️ 리드백 실패\n"); _run = kRuns; return; }
				_hit[a] += hb; _cnt[a] += nb;
			}
			_sumP += sp;
			++_eb;
			_st = kEvalUp;
		}
	}

private:
	static constexpr uint32 kSeed0 = 12u, kSeeds = 12u;
	static constexpr uint32 kArms = 4u;                  // P0 · P1 · Q0 · Q1
	static constexpr uint32 kRuns = kArms * kSeeds;      // 48
	static constexpr int    kHold = MLTWorldCfg::kHoldMid;
	static constexpr uint32 kSteps = 300u;
	static constexpr uint32 kEvalEpi0 = 0u, kEvalB = 4u;
	static constexpr uint32 kEvalEpis = kEvalB * MLTModelCfg::kBatch;
	static constexpr float  kDiffMin = 0.20f;            // ② 의 문턱(≈12·SE)
	static constexpr uint32 kSignNeed = 10u;

	static uint32 _Arm(uint32 r)  { return r / kSeeds; }   // 0=P0 · 1=P1 · 2=Q0 · 3=Q1
	static uint32 _Seed(uint32 r) { return kSeed0 + (r % kSeeds); }
	// B 표적 스텝 수 — 나머지 스텝은 **A 재방문**이다(총 300).
	static uint32 _BSteps(uint32 r)
	{
		switch (_Arm(r)) { case 0: return 300u; case 1: return 150u; case 2: return 300u; default: return 75u; }
	}
	static float _LrMul(uint32 r)
	{
		switch (_Arm(r)) { case 0: return 0.5f; case 1: return 1.0f; case 2: return 0.25f; default: return 1.0f; }
	}
	// ⭐ 스텝을 **앞쪽에 B, 뒤쪽에 재방문**으로 두지 않는다 — **고르게 섞는다**.
	//   ⚠️ 몰아 두면 「B 를 배운 뒤 A 를 다시 배웠다」가 되어 **순서 효과**가 섞인다.
	//   ★ `floor(step · B/300)` 이 바뀌는 스텝을 B 로 준다 ⇒ 균등 분포.
	static bool _IsRevisitStep(uint32 r, uint32 step)
	{
		const uint32 nb = _BSteps(r);
		if (nb >= kSteps) return false;
		const uint32 a = (step * nb) / kSteps;
		const uint32 b = ((step + 1u) * nb) / kSteps;
		return (a == b);          // 진행이 없으면 그 스텝은 **재방문**이다
	}
	static const char* _ArmName(uint32 r)
	{
		switch (_Arm(r))
		{
			case 0: return "P0 (B300·lr½·재방문0  )";
			case 1: return "P1 (B150·lr1 ·재방문150)";
			case 2: return "Q0 (B300·lr¼·재방문0  )";
			default: return "Q1 (B 75·lr1 ·재방문225)";
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
		LogA("[mlt] ⚖️ **회차 11 · 쌍 대조군** — 「재방문」이냐 「유효 학습률」이냐 · 씨앗 %u~%u · %u 실행\n",
			kSeed0, kSeed0 + kSeeds - 1u, kRuns);
		LogA("[mlt] ⚖️   `B 총 기울기`를 짝마다 **고정**하고 재방문만 다르게:"
		     " P짝 = 150·lr · Q짝 = 75·lr\n");
		LogA("[mlt] ⚖️   문턱: **두 짝 모두** 차이 ≥ %.2f 그리고 부호검정 %u/12 ⇒ 「재방문이다」\n",
			(double)kDiffMin, kSignNeed);
		LogA("[mlt] ⚖️   ⚠️⚠️ 「재방문이다」가 나와도 **희소 갱신을 만들지 않는다**"
		     " — 다음 물음은 «학습 자체가 그 재방문을 만들게 할까» 다\n");
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

	// 표적 축: 1단계=y(A) · 2단계=yaw(B) 단 **재방문 스텝은 y** · 시험이면 전부
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
			LogA("[mlt] ⚖️ [%2u/%u] %s 마지막 씨앗 · R_A %.3f→%.3f (낙폭 %+.3f) · R_B %.3f%s\n",
				_run + 1u, kRuns, _ArmName(_run), (double)_rA0[_run], (double)_rA1[_run],
				(double)(_rA1[_run] - _rA0[_run]), (double)_rB1[_run], _rOk[_run] ? "" : "  ⛔배관");
		++_run;
		_st = kInit;
		if (_run >= kRuns) _Judge();
	}

	static void _Judge()
	{
		float drop[kArms] = { 0.0f }, rb[kArms] = { 0.0f };
		bool plumb = true;
		for (uint32 m = 0; m < kArms; ++m)
		{
			float d = 0.0f, b = 0.0f;
			for (uint32 i = 0; i < kSeeds; ++i)
			{
				const uint32 r = m * kSeeds + i;
				d += (_rA1[r] - _rA0[r]); b += _rB1[r];
				if (!_rOk[r]) plumb = false;
			}
			drop[m] = d / (float)kSeeds; rb[m] = b / (float)kSeeds;
		}
		uint32 sign = 0u;
		for (uint32 i = 0; i < kSeeds; ++i)
		{
			const float p0 = _rA1[i] - _rA0[i];
			const float p1 = _rA1[kSeeds + i] - _rA0[kSeeds + i];
			if (p1 > p0) ++sign;   // ★ 검정은 **P 짝**에만 건다
		}
		const float dP = drop[1] - drop[0];
		const float dQ = drop[3] - drop[2];

		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] ⚖️ **회차 11 결과 — 재방문이냐 유효 학습률이냐**\n");
		for (uint32 m = 0; m < kArms; ++m)
			LogA("[mlt] ⚖️   %s · 낙폭 **%+.3f** · R_B %.3f\n",
				_ArmName(m * kSeeds), (double)drop[m], (double)rb[m]);
		if (!plumb) LogA("[mlt] ⚖️   ⛔ 배관이 깨진 실행이 있다 — **판정불가**\n");
		else        LogA("[mlt] ⚖️   ✅ 배관 — probs 합 1.0 · 전 구간 유한\n");

		LogA("[mlt] ⚖️   ── 짝 안의 차이(재방문의 몫) ──\n");
		LogA("[mlt] ⚖️   **P 짝**(B 총 기울기 150·lr) : %+.3f − %+.3f = **%+.3f**"
		     " · 부호검정 **%u/12** (문턱 %.2f)\n",
			(double)drop[1], (double)drop[0], (double)dP, sign, (double)kDiffMin);
		LogA("[mlt] ⚖️   **Q 짝**(B 총 기울기  75·lr) : %+.3f − %+.3f = **%+.3f** (읽는 칸)\n",
			(double)drop[3], (double)drop[2], (double)dQ);

		const bool okP = (dP >= kDiffMin) && (sign >= kSignNeed);
		const bool okQ = (dQ >= kDiffMin);
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		if (!plumb)
			LogA("[mlt] ⚖️ ⛔ 판정불가\n");
		else if (okP && okQ)
			LogA("[mlt] ⚖️ ✅✅ **「재방문이다」 — 두 총 기울기 수준에서 모두 성립한다.**"
			     " 회차 10 의 사후 관찰이 **등록 뒤에 재현됐다**\n");
		else if (okP || okQ)
			LogA("[mlt] ⚖️ ⚠️ **「총 기울기 수준에 달렸다」** — 한 짝만 넘었다(P %s · Q %s)"
			     " ⇒ 「재방문이다」로 단정하지 않는다\n", okP ? "✅" : "⛔", okQ ? "✅" : "⛔");
		else
			LogA("[mlt] ⚖️ ⚠️⚠️ **회차 10 의 사후 관찰이 재현되지 않았다**(P %+.3f · Q %+.3f)"
			     " ⇒ 그것을 이 회차의 결과로 적는다\n", (double)dP, (double)dQ);
		LogA("[mlt] ⚖️   ⚠️ **`R_B` 의 대가를 같이 읽어라** — 재방문 팔이 B 를 덜 배우면 그것이 값이다\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}
};
