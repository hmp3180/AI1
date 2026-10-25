// mltp1s.cw — 🎯 **회차 15 · 「같은 축 안에서」 공짜 신뢰가 예고하나** (교란 제거)
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문** — ⚠️ 재기 전에 적는다. 정본은 `mltlog_1.md` 회차 14 의 「회차 15 등록」이다.
// ══════════════════════════════════════════════════════════════════════════════
//
// ★ **왜 이 회차가 필요한가 — 교란을 안 없애면 다음 결론도 걸린다**
//
//   회차 14 가 «공짜 신뢰는 **축 간**으로 예고하지 않는다»(3/12)를 냈다. 그런데 3/12 는 우연(6)보다
//   **낮아서** 반대 방향이 **9/12** 라는 뜻이었고, 거기에 **교란**이 있었다:
//   ```
//   `pitch` 는 |Δ| = 0.048 로 가장 작다
//     ㈀ 예측이 좁게 몰린다 ⇒ **마진이 높다**(0.2751 · 최고)
//     ㈁ 창(베이즈−복사)이 가장 좁다(52.4%p) ⇒ 같은 **절대** 변화가 `R` 로 **더 크게** 보인다
//   ⇒ `|Δ|` 가 「마진」과 「창」 **둘 다의 공통 원인**일 수 있다
//   ```
//   ★ 그것이 **축 간 비교의 구조적 약점**이다. ⇒ ***축을 하나로 고정하면 그 교란이 사라진다.***
//   ⚠️ 등록 분기는 「㉠⛔ ⇒ 실현 채점 헤드의 폭 재기」였지만 **그 전에 이것을 한다** —
//     안 하면 **다음 회차의 결론도 같은 교란에 걸린다**(「한 점으로 판정하지 마라」의 정신).
//
// ══════════════════════════════════════════════════════════════════════════════
// ① 설계 — **축 하나(`pitch`) 고정 · 인스턴스로 표본을 늘린다**
// ══════════════════════════════════════════════════════════════════════════════
//   ```
//   1단계  세 축 함께 300스텝  → **pitch 의 마진**을 읽는다  ⚠️ 표적을 안 본다(접촉 0)
//   2단계  yaw 만 300스텝      → **pitch 의 낙폭**을 읽는다
//   물음   마진이 **낮은** 인스턴스가 **더 많이** 잊히나?
//   ```
//   ★ 인스턴스 = `씨앗 12 × 에피소드 구간 2` = **24**.
//     ⚠️ 「에피소드 구간」이 두 번째 축인 근거: 씨앗이 **12개로 고정**(판정용)이고 개발 씨앗을
//     끌어오면 그것은 판정 표본이 아니다 ⇒ **같은 씨앗의 다른 에피소드**가 정직한 인스턴스다.
//     ★ 구간 0 = 에피소드 1000~ · 구간 1 = 에피소드 60000~ (⚠️ 훈련·시험 구간과 안 겹친다)
//   ⚠️⚠️ **모든 인스턴스가 같은 축을 본다** ⇒ `|Δ|`·창·복사·베이즈가 **전부 같다** ⇒ 교란이 없다.
//
// ══════════════════════════════════════════════════════════════════════════════
// ② 읽는 칸과 문턱
// ══════════════════════════════════════════════════════════════════════════════
//   · 24 인스턴스를 **마진으로 정렬**하고 **순위로 짝짓는다**: `(하위 k, 상위 k)` k=0..11 ⇒ **12쌍**
//     ★ 그래야 이 트랙의 **12/12 척도**가 유지된다(부호검정 표가 같은 자로 읽힌다).
//   · 표제 = 그 12쌍에서 **「마진이 낮은 쪽이 더 많이 잊혔나」**의 부호검정
//   · 같이 읽는 것 = 엔트로피 판 · **짝 안의 마진 차이**(위생) · 마진↔낙폭의 두 그룹 평균
//   **문턱**
//     ㉠ ★ **≥ 10/12** ⇒ ***"같은 축 안에서는 공짜 신뢰가 예고한다"*** ⇒ **헤드를 만들 이유가 줄어든다.**
//        **≤ 8/12** ⇒ ***"양쪽에서 다 바닥이다"*** ⇒ 그때 **실현 채점 헤드의 폭 재기**로 간다.
//        9/12 ⇒ **중간** — 단정하지 않는다.
//     ㉡ ⚠️ **위생** — 짝 안의 마진 차이 평균이 **마진의 10% 이상**. 회차 14 에서 그 여유가
//        `0.0267 vs 0.0262` 로 **간신히**였다 ⇒ 이번엔 그 수를 **명시로 찍는다.**
//     ㉢ **배관** — 낙폭이 **거의 다 음수**(≥ 22/24) · `probs` 합 1.0 · 유한
//     ㉣ ⚠️ **진실 접촉이 회차 14 와 같아야** 한다(313,344/실행) — 신뢰가 접촉을 **안 늘렸다**는 확인.
//
//   ⚠️⚠️ **미리 적는 분기**
//     · ㉠ ✅ ⇒ 공짜 신뢰로 충분하다 ⇒ **헤드를 만들지 않는다.** 다음은 그 값으로 재방문을
//       조건화하는 폐회로이고, ⚠️ **정책은 배워야** 한다(문서의 그 못).
//     · ㉠ ⛔(≤8) ⇒ 공짜 신뢰는 **양쪽에서 바닥**이다 ⇒ 「실현 채점」이 값을 할 여지가 확정된다
//       ⇒ 다음은 **그 헤드의 폭 재기**(만드는 것은 그 뒤).
//     · 9/12 ⇒ **중간** ⇒ 표본을 늘려 한 번 더 잰다(⚠️ 지표를 바꾸지 않는다).
//
// ⚠️ 이 회차도 **아무것도 만들지 않는다.** 비용: 24 실행 × 600스텝 ⇒ **≈2분**.

using namespace PE;

class MLTP1S
{
public:
	static bool Done() { return _run >= kRuns; }

	static void Tick(RHI* rhi)
	{
		if (_run >= kRuns || rhi == nullptr) return;
		if (MLTModelCfg::kAxes != MLTP1::kAxes || MLTModelCfg::kTime != MLTP1::kTime)
		{ LogA("[mlt] 🎯 ⛔⛔ 축/시각 전제가 다르다\n"); _run = kRuns; return; }
		// ⚠️ **기본에서 껐다** — 회차 15 로 쟀다. ★ 다시 돌리려면 `-mltsame`.
		if (!OS::CommandLine::Has("-mltsame"))
		{
			LogA("[mlt] 🎯 회차 15(같은 축 안의 예고력)는 **꺼져 있다**(`-mltsame`) — 기록: **7/12**"
			     " · 엔트로피 6/12 = 우연 ⇒ 공짜 신뢰는 양쪽에서 바닥\n");
			_run = kRuns;
			return;
		}
		if (!_banner) { _Banner(); _banner = true; }

		if (_st == kInit)
		{
			if (!_M.Setup(rhi)) { LogA("[mlt] 🎯 준비 실패(run %u)\n", _run); _run = kRuns; return; }
			_M.ResetTruthTouches();
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
				if (!_M.ReadLoss(ls)) { LogA("[mlt] 🎯 손실 리드백 실패\n"); _run = kRuns; return; }
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
					// ⭐ **인스턴스마다 에피소드 구간이 다르다**(그것이 두 번째 표본 축이다).
					_Batch(_Seed(_run), _EpiBase(_run) + _ph * 20000u + (_step + k) * MLTModelCfg::kBatch,
						(_ph == 0u) ? kAll : 1u, v, g);
					for (uint32 i = 0; i < v.Count(); ++i) _pv.Add(v[i]);
					for (uint32 i = 0; i < g.Count(); ++i) _pt.Add(g[i]);
				}
				if (!_M.UploadPool(_pv, _pt, n)) { LogA("[mlt] 🎯 풀 업로드 실패\n"); _run = kRuns; return; }
			}
			_M.SelectStep(slot);
			if (!_M.Forward() || !_M.Backward() || !_M.AdamStep())
			{ LogA("[mlt] 🎯 스텝 실패(ph %u · step %u)\n", _ph, _step); _run = kRuns; return; }
			++_step;
			return;
		}

		if (_st == kEvalUp)
		{
			if (_eb >= kEvalB) { _EvalDone(); return; }
			_Batch(_Seed(_run), kEvalEpi0 + _eb * MLTModelCfg::kBatch, kAll, _ev, _et);
			if (!_M.Upload(_ev, _et)) { LogA("[mlt] 🎯 시험 업로드 실패\n"); _run = kRuns; return; }
			if (!_M.Forward()) { LogA("[mlt] 🎯 시험 forward 실패\n"); _run = kRuns; return; }
			_st = kEvalRd;
			return;
		}

		// kEvalRd — ⭐ **`pitch` 만** 읽는다(축을 고정했다)
		{
			Array<float> m;
			m.Reset(0);
			for (uint32 r = 0; r < MLTModelCfg::kRows; ++r)
				m.Add((((r % MLTModelCfg::kCtx) % MLTP1::kAxes) == kAxis) ? 1.0f : 0.0f);
			uint32 h = 0u, n = 0u, hb = 0u, nb = 0u;
			float sp = 0.0f, dd = 0.0f, ddb = 0.0f, ddo = 0.0f;
			if (!_M.ReadHits(_et, m, h, n, hb, nb, sp, dd, ddb, ddo))
			{ LogA("[mlt] 🎯 리드백 실패\n"); _run = kRuns; return; }
			_hit += hb; _cnt += nb;
			float mg = 0.0f, en = 0.0f; uint32 cn = 0u;
			if (!_M.ReadConf(m, mg, en, cn)) { LogA("[mlt] 🎯 신뢰 리드백 실패\n"); _run = kRuns; return; }
			_mg += mg; _en += en;
			_sumP += sp;
			++_eb;
			_st = kEvalUp;
		}
	}

private:
	static constexpr uint32 kSeeds = 12u, kSeed0 = 12u;
	static constexpr uint32 kSpans = 2u;                 // 에피소드 구간 둘
	static constexpr uint32 kRuns = kSeeds * kSpans;     // 24 인스턴스
	static constexpr uint32 kPairs = kRuns / 2u;         // 12 쌍
	static constexpr uint32 kAxis = 2u;                  // ⭐ **pitch 로 고정**
	static constexpr int    kHold = MLTWorldCfg::kHoldMid;
	static constexpr uint32 kSteps = 300u;
	static constexpr uint32 kEvalEpi0 = 0u, kEvalB = 4u;
	static constexpr uint32 kEvalEpis = kEvalB * MLTModelCfg::kBatch;
	static constexpr uint32 kAll = 0xFFFFFFFFu;
	static constexpr uint32 kSignNeed = 10u, kSignFloor = 8u;
	static constexpr float  kSepFrac = 0.10f;

	static uint32 _Seed(uint32 r) { return kSeed0 + (r % kSeeds); }
	// ⚠️ 구간 1 은 60000 부터 — 훈련(1000~)·시험(0~31)과 **안 겹친다**.
	static uint32 _EpiBase(uint32 r) { return (r < kSeeds) ? 1000u : 60000u; }

	enum { kInit = 0, kTrain, kEvalUp, kEvalRd };

	inline static MLTModel _M;
	inline static bool _banner = false;
	inline static uint32 _run = 0u, _ph = 0u, _step = 0u, _eb = 0u;
	inline static int _st = kInit;
	inline static bool _finite = true;
	inline static float _sumP = 0.0f, _mg = 0.0f, _en = 0.0f;
	inline static uint32 _hit = 0u, _cnt = 0u;
	inline static MLTP1::Base _bC[MLTP1::kAxes], _bB[MLTP1::kAxes];
	inline static float _phR[2] = { 0.0f, 0.0f }, _phMg[2] = { 0.0f, 0.0f }, _phEn[2] = { 0.0f, 0.0f };
	inline static Array<float> _ev, _et, _pv, _pt;

	inline static float _rMg[kRuns] = { 0.0f }, _rEn[kRuns] = { 0.0f }, _rDrop[kRuns] = { 0.0f };
	inline static bool  _rOk[kRuns] = { false };
	inline static uint64 _rTruth[kRuns] = { 0ull };

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🎯 **회차 15 · 「같은 축 안에서」 공짜 신뢰가 예고하나**(교란 제거) · %u 인스턴스\n",
			kRuns);
		LogA("[mlt] 🎯   축을 **%s 로 고정** ⇒ |Δ|·창·복사·베이즈가 **전부 같다**"
		     " · 표본 = 씨앗 %u × 에피소드 구간 %u\n", MLTP1::AxisName(kAxis), kSeeds, kSpans);
		LogA("[mlt] 🎯   마진으로 정렬해 **순위로 짝짓고**(12쌍) 「낮은 쪽이 더 잊혔나」 부호검정"
		     " · ≥%u 예고 / ≤%u 바닥\n", kSignNeed, kSignFloor);
		LogA("[mlt] 🎯   ⚠️ 이 회차도 **아무것도 만들지 않는다**(파라미터 0 · 진실 접촉 0 증가)\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

	static void _StartEval()
	{
		_eb = 0u; _sumP = 0.0f; _hit = 0u; _cnt = 0u; _mg = 0.0f; _en = 0.0f;
		_st = kEvalUp;
	}

	static void _EvalDone()
	{
		const float acc = _cnt ? (float)_hit / (float)_cnt : 0.0f;
		const float w = _bB[kAxis].acc - _bC[kAxis].acc;
		_phR[_ph] = (w > 1.0e-4f) ? (acc - _bC[kAxis].acc) / w : 0.0f;
		_phMg[_ph] = _mg / (float)_eb;
		_phEn[_ph] = _en / (float)_eb;
		++_ph;
		_step = 0u;
		_st = kTrain;
	}

	static void _Batch(uint32 seed, uint32 epi0, uint32 tgtAxis, Array<float>& val, Array<float>& tgt)
	{
		typedef MLTModelCfg M;
		const uint32 A = MLTP1::kAxes, T = MLTP1::kTime;
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
		_rMg[_run] = _phMg[0];               // ★ **1단계 직후**의 마진(예고를 묻는다)
		_rEn[_run] = _phEn[0];
		_rDrop[_run] = _phR[1] - _phR[0];
		_rOk[_run] = _finite && (Abs(sp - 1.0f) <= 0.01f);
		_rTruth[_run] = _M.TruthTouches();
		LogA("[mlt] 🎯 [%2u/%u] 씨앗%2u 구간%u · 마진 **%.4f** · 엔트로피 %.3f → 낙폭 **%+.3f**"
		     " · 진실접촉 %llu%s\n",
			_run + 1u, kRuns, _Seed(_run), (_run < kSeeds) ? 0u : 1u,
			(double)_rMg[_run], (double)_rEn[_run], (double)_rDrop[_run],
			(unsigned long long)_rTruth[_run], _rOk[_run] ? "" : "  ⛔배관");
		++_run;
		_st = kInit;
		if (_run >= kRuns) _Judge();
	}

	static void _Judge()
	{
		// 마진으로 정렬(오름차순) — ⚠️ 삽입정렬(표본이 24개다)
		uint32 ord[kRuns];
		for (uint32 i = 0; i < kRuns; ++i) ord[i] = i;
		for (uint32 i = 1; i < kRuns; ++i)
		{
			const uint32 key = ord[i];
			uint32 j = i;
			while (j > 0u && _rMg[ord[j - 1u]] > _rMg[key]) { ord[j] = ord[j - 1u]; --j; }
			ord[j] = key;
		}
		// ★ **순위로 짝짓는다**: 하위 k ↔ 상위 k
		uint32 signMg = 0u, signEn = 0u, nNeg = 0u;
		float sepSum = 0.0f, mgSum = 0.0f;
		bool plumb = true;
		for (uint32 i = 0; i < kRuns; ++i) { if (!_rOk[i]) plumb = false; if (_rDrop[i] < 0.0f) ++nNeg; }
		for (uint32 k = 0; k < kPairs; ++k)
		{
			const uint32 lo = ord[k];                  // 마진 낮은 쪽
			const uint32 hi = ord[kRuns - 1u - k];     // 마진 높은 쪽
			sepSum += (_rMg[hi] - _rMg[lo]);
			mgSum += 0.5f * (_rMg[hi] + _rMg[lo]);
			// 「마진이 낮은 쪽이 **더 많이** 잊혔나」 = 낙폭이 더 음수
			if (_rDrop[lo] < _rDrop[hi]) ++signMg;
			// 엔트로피 판: 엔트로피가 **높은** 쪽이 더 잊혔나
			if (_rEn[lo] > _rEn[hi]) { if (_rDrop[lo] < _rDrop[hi]) ++signEn; }
			else                     { if (_rDrop[hi] < _rDrop[lo]) ++signEn; }
		}
		const float sep = sepSum / (float)kPairs;
		const float mgAvg = mgSum / (float)kPairs;

		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🎯 **회차 15 결과 — 같은 축(%s) 안에서의 예고력**\n", MLTP1::AxisName(kAxis));
		// 두 그룹 평균
		float mgLo = 0.0f, mgHi = 0.0f, dLo = 0.0f, dHi = 0.0f;
		for (uint32 k = 0; k < kPairs; ++k)
		{
			mgLo += _rMg[ord[k]]; dLo += _rDrop[ord[k]];
			mgHi += _rMg[ord[kRuns - 1u - k]]; dHi += _rDrop[ord[kRuns - 1u - k]];
		}
		const float kk = 1.0f / (float)kPairs;
		LogA("[mlt] 🎯   마진 **낮은** 12개: 평균 마진 %.4f → 평균 낙폭 **%+.3f**\n",
			(double)(mgLo * kk), (double)(dLo * kk));
		LogA("[mlt] 🎯   마진 **높은** 12개: 평균 마진 %.4f → 평균 낙폭 **%+.3f**\n",
			(double)(mgHi * kk), (double)(dHi * kk));

		if (!plumb) LogA("[mlt] 🎯   ⛔ ㉢ 배관이 깨진 인스턴스가 있다 — **판정불가**\n");
		else        LogA("[mlt] 🎯   ✅ ㉢ 배관 — probs 합 1.0 · 전 구간 유한\n");
		const bool g3 = (nNeg >= kRuns - 2u);
		LogA("[mlt] 🎯   %s ㉢ 낙폭이 음수인 인스턴스 **%u/%u** (잊혀야 물음이 성립한다)\n",
			g3 ? "✅" : "⛔", nNeg, kRuns);
		const bool g4 = (_rTruth[0] == 313344ull);
		LogA("[mlt] 🎯   %s ㉣ 진실 접촉 **%llu**/실행 — 회차 14 와 %s(신뢰가 접촉을 **안 늘렸다**)\n",
			g4 ? "✅" : "⚠️", (unsigned long long)_rTruth[0], g4 ? "같다" : "**다르다**");
		const bool g2 = (sep > kSepFrac * Abs(mgAvg));
		LogA("[mlt] 🎯   %s ㉡ 위생 — 짝 안의 마진 차이 평균 **%.4f** > 10%% × %.4f = %.4f"
		     " (여유 **%.2f배**)\n",
			g2 ? "✅" : "⛔", (double)sep, (double)mgAvg, (double)(kSepFrac * Abs(mgAvg)),
			(double)(sep / (kSepFrac * Abs(mgAvg) + 1.0e-9f)));

		LogA("[mlt] 🎯   ── ㉠ 표제 ──\n");
		LogA("[mlt] 🎯   **마진이 낮은 쪽이 더 많이 잊혔나 — %u/%u** (예고 ≥%u · 바닥 ≤%u · 우연 6)\n",
			signMg, kPairs, kSignNeed, kSignFloor);
		LogA("[mlt] 🎯   ㉡ 엔트로피 판 — %u/%u (읽는 칸)\n", signEn, kPairs);

		LogA("[mlt] ══════════════════════════════════════════════════\n");
		if (!plumb || !g2 || !g3)
			LogA("[mlt] 🎯 ⛔ **위생/배관이 깨졌다 — 판정불가**\n");
		else if (signMg >= kSignNeed)
			LogA("[mlt] 🎯 ⇒ ✅✅ **같은 축 안에서는 공짜 신뢰가 예고한다**(%u/%u)"
			     " ⇒ ***헤드를 만들지 않는다.*** 다음은 그 값으로 재방문을 조건화하는 폐회로이고"
			     " ⚠️ **정책은 배워야** 한다\n", signMg, kPairs);
		else if (signMg <= kSignFloor)
			LogA("[mlt] 🎯 ⇒ ⚠️ **공짜 신뢰는 양쪽에서 바닥이다**(축 간 3/12 · 축 안 %u/%u)"
			     " ⇒ 「실현 채점」이 값을 할 여지가 **확정된다**. 다음은 **그 헤드의 폭 재기**\n",
				signMg, kPairs);
		else
			LogA("[mlt] 🎯 ⇒ ⚠️ **중간**(%u/%u) ⇒ 표본을 늘려 한 번 더 잰다"
			     "(⚠️ 지표를 바꾸지 않는다)\n", signMg, kPairs);
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}
};
