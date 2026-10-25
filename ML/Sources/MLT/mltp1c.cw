// mltp1c.cw — 🎚️ **회차 14 · 「진실 접촉 0 인 신뢰」가 무엇이 잊힐지 예고하나**
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문** — ⚠️ 재기 전에 적는다
// ══════════════════════════════════════════════════════════════════════════════
//
// ★ **왜 이 회차가 「신뢰 헤드를 만들기 전에」 와야 하나**
//
//   회차 13 이 방향을 정했다: 자기평가의 첫 소비자는 「갱신 범위」가 아니라 **「무엇을 다시 볼까」**다.
//   그런데 그것을 만들려면 **신뢰 값**이 필요하고, `mltconcept.md` 가 그 앞에 **관문 하나**를 뒀다:
//   > ★ **진실 접촉 0 인 신뢰**(출력 분포의 엔트로피·마진)를 **기본 대조군**으로 둔다 —
//   > 그것이 같으면 실현 채점은 **접촉만 늘리고 값은 안 한 것**이다.
//
//   ⇒ ★ **공짜 신뢰가 이미 정보를 담고 있으면 헤드를 만들 이유가 없다.**
//     그 공짜 신뢰는 **파라미터 0개 · 진실 접촉 0회**다(출력 분포만 본다).
//   ⇒ 그리고 그것이 **아무 정보도 없으면** 「실현 채점」이 값을 할 여지가 생긴다 — 그때 만든다.
//   ★ 「관문이 손잡이보다 먼저다」 · 「폭을 먼저 재라」의 그 자리다.
//
// ══════════════════════════════════════════════════════════════════════════════
// ① 무엇을 재나 — **예고력**
// ══════════════════════════════════════════════════════════════════════════════
//   ```
//   1단계  세 축을 **함께** 300스텝 배운다 (회차 7 과 같은 배치)
//          → 축마다 **마진**과 **엔트로피**를 읽는다  ← ⚠️ 표적을 안 본다(접촉 0)
//   2단계  **yaw 만** 300스텝 배운다
//          → 축마다 `R` 의 **낙폭**을 읽는다
//   물음   1단계의 신뢰가 낮았던 축이 2단계에서 **더 많이 잊히나?**
//   ```
//   ⚠️ 대상은 **`y` 와 `pitch` 둘**이다(`yaw` 는 2단계에서 계속 배우므로 「잊히는」 쪽이 아니다).
//   ⇒ 씨앗마다 **둘 중 하나**를 고르는 문제 ⇒ **부호검정**이 바로 붙는다.
//
//   **읽는 칸**
//     · 표제 = **`마진`이 낮은 축이 더 많이 잊혔나**(씨앗마다 예/아니오) ⇒ 부호검정
//     · 같이 읽는 것 = **엔트로피** 판(엔트로피가 **높은** 축이 더 잊혔나) · 두 축의 마진 **차이**
//       (⚠️ 차이가 없으면 예고력을 물을 수 없다 — 아래 ㉢)
//     · ⭐ **진실 접촉 계수**를 찍는다(이 회차의 신뢰는 **0 을 늘린다**는 것을 로그로 남긴다)
//   **문턱**
//     ㉠ ★ 부호검정 **≥ 10/12** ⇒ ***"공짜 신뢰가 예고한다."***
//        ⚠️ **8/12 이하면 예고력이 없다**(우연은 6/12) ⇒ 그 대조군이 **바닥**임이 확인된 것이고,
//        그때 「실현 채점」이 값을 할 여지가 있다.
//     ㉡ **엔트로피 판도 같은 방향인가**(읽는 칸 — 관문 아님). ⚠️ 둘이 반대면 **지표가 불안정**하다.
//     ㉢ ⚠️ **위생** — 두 축의 마진 차이가 **잡음보다 큰가**. 씨앗별 `|마진(y) − 마진(pitch)|` 의
//        평균이 **마진 자체의 1/10 보다 커야** 물음이 성립한다. 안 그러면 **판정불가**
//        («둘이 사실상 같은데 어느 쪽이 더 잊혔나» 는 동전 던지기다).
//     ㉣ **배관** — 낙폭이 **둘 다 음수**인가(잊혀야 물음이 성립한다) · `probs` 합 1.0 · 유한
//
//   ⚠️⚠️ **미리 적는 분기**
//     · ㉠ ✅ ⇒ ***"공짜 신뢰로 충분하다"*** ⇒ **신뢰 헤드를 만들지 않는다.** 다음은 그 공짜 값으로
//       재방문을 조건화하는 폐회로다(⚠️ 그래도 **정책은 배워야** 한다 — 문서의 그 못).
//     · ㉠ ⛔ ⇒ ***"공짜 신뢰는 바닥이다"*** ⇒ 「실현 채점」(오차 − 자기가 예상한 오차)이 값을 할
//       여지가 **생긴다.** ⚠️ 그래도 **그 다음 회차는 그 헤드의 폭 재기**이고, 만드는 것은 그 뒤다.
//     · ㉢ ⛔ ⇒ **판정불가** — 지표를 바꿔야 한다(마진이 축을 못 가른다).
//
// ⚠️ 이 회차도 **아무것도 만들지 않는다.** 파라미터가 **0개** 늘고 진실 접촉이 **0회** 는다.
// ⚠️ 비용: 1팔 × 12씨앗 = **12 실행** · 실행당 600스텝 ⇒ **≈1분**.

using namespace PE;

class MLTP1C
{
public:
	static bool Done() { return _run >= kRuns; }

	static void Tick(RHI* rhi)
	{
		if (_run >= kRuns || rhi == nullptr) return;
		if (MLTModelCfg::kAxes != MLTP1::kAxes || MLTModelCfg::kTime != MLTP1::kTime)
		{ LogA("[mlt] 🎚️ ⛔⛔ 축/시각 전제가 다르다\n"); _run = kRuns; return; }
		// ⚠️ **기본에서 껐다** — 회차 14 로 쟀다. ★ 다시 돌리려면 `-mltconf`.
		if (!OS::CommandLine::Has("-mltconf"))
		{
			LogA("[mlt] 🎚️ 회차 14(공짜 신뢰의 축 간 예고력)는 **꺼져 있다**(`-mltconf`) — 기록:"
			     " **3/12**(우연 6) ⇒ 바닥 · 진실 접촉 313,344/실행(신뢰는 0 늘렸다)\n");
			_run = kRuns;
			return;
		}
		if (!_banner) { _Banner(); _banner = true; }

		if (_st == kInit)
		{
			if (!_M.Setup(rhi)) { LogA("[mlt] 🎚️ 준비 실패(run %u)\n", _run); _run = kRuns; return; }
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
				if (!_M.ReadLoss(ls)) { LogA("[mlt] 🎚️ 손실 리드백 실패\n"); _run = kRuns; return; }
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
					// ⭐ 1단계 = **세 축 함께** · 2단계 = **yaw 만**
					_Batch(_Seed(_run), 1000u + _ph * 20000u + (_step + k) * MLTModelCfg::kBatch,
						(_ph == 0u) ? kAll : 1u, v, g);
					for (uint32 i = 0; i < v.Count(); ++i) _pv.Add(v[i]);
					for (uint32 i = 0; i < g.Count(); ++i) _pt.Add(g[i]);
				}
				if (!_M.UploadPool(_pv, _pt, n)) { LogA("[mlt] 🎚️ 풀 업로드 실패\n"); _run = kRuns; return; }
			}
			_M.SelectStep(slot);
			if (!_M.Forward() || !_M.Backward() || !_M.AdamStep())
			{ LogA("[mlt] 🎚️ 스텝 실패(ph %u · step %u)\n", _ph, _step); _run = kRuns; return; }
			++_step;
			return;
		}

		if (_st == kEvalUp)
		{
			if (_eb >= kEvalB) { _EvalDone(); return; }
			_Batch(_Seed(_run), kEvalEpi0 + _eb * MLTModelCfg::kBatch, kAll, _ev, _et);
			if (!_M.Upload(_ev, _et)) { LogA("[mlt] 🎚️ 시험 업로드 실패\n"); _run = kRuns; return; }
			if (!_M.Forward()) { LogA("[mlt] 🎚️ 시험 forward 실패\n"); _run = kRuns; return; }
			_st = kEvalRd;
			return;
		}

		// kEvalRd — 정확도(진실 필요) **와** 신뢰(진실 불필요)를 함께 읽는다
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
				{ LogA("[mlt] 🎚️ 리드백 실패\n"); _run = kRuns; return; }
				_hit[a] += hb; _cnt[a] += nb;
				// ⭐ **진실 접촉 0 인 신뢰** — 표적을 안 본다.
				float mg = 0.0f, en = 0.0f; uint32 cn = 0u;
				if (!_M.ReadConf(m, mg, en, cn))
				{ LogA("[mlt] 🎚️ 신뢰 리드백 실패\n"); _run = kRuns; return; }
				_mg[a] += mg; _en[a] += en;
			}
			_sumP += sp;
			++_eb;
			_st = kEvalUp;
		}
	}

private:
	static constexpr uint32 kSeed0 = 12u, kSeeds = 12u;
	static constexpr uint32 kRuns = kSeeds;              // 팔 하나
	static constexpr int    kHold = MLTWorldCfg::kHoldMid;
	static constexpr uint32 kSteps = 300u;
	static constexpr uint32 kEvalEpi0 = 0u, kEvalB = 4u;
	static constexpr uint32 kEvalEpis = kEvalB * MLTModelCfg::kBatch;
	static constexpr uint32 kAll = 0xFFFFFFFFu;
	static constexpr uint32 kSignNeed = 10u;
	static constexpr float  kSepFrac = 0.10f;            // ㉢ 위생 — 마진 차이가 마진의 1/10 이상

	static uint32 _Seed(uint32 r) { return kSeed0 + r; }

	enum { kInit = 0, kTrain, kEvalUp, kEvalRd };

	inline static MLTModel _M;
	inline static bool _banner = false;
	inline static uint32 _run = 0u, _ph = 0u, _step = 0u, _eb = 0u;
	inline static int _st = kInit;
	inline static bool _finite = true;
	inline static float _sumP = 0.0f;
	inline static uint32 _hit[MLTP1::kAxes] = { 0u }, _cnt[MLTP1::kAxes] = { 0u };
	inline static float _mg[MLTP1::kAxes] = { 0.0f }, _en[MLTP1::kAxes] = { 0.0f };
	inline static MLTP1::Base _bC[MLTP1::kAxes], _bB[MLTP1::kAxes];
	inline static float _phR[2][MLTP1::kAxes] = { { 0.0f } };
	inline static float _phMg[2][MLTP1::kAxes] = { { 0.0f } }, _phEn[2][MLTP1::kAxes] = { { 0.0f } };
	inline static Array<float> _ev, _et, _pv, _pt;

	inline static float _rDrop[kRuns][MLTP1::kAxes] = { { 0.0f } };
	inline static float _rMg[kRuns][MLTP1::kAxes] = { { 0.0f } };
	inline static float _rEn[kRuns][MLTP1::kAxes] = { { 0.0f } };
	inline static bool  _rOk[kRuns] = { false };
	inline static uint64 _rTruth[kRuns] = { 0ull };

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🎚️ **회차 14 · 「진실 접촉 0 인 신뢰」가 무엇이 잊힐지 예고하나** · %u 실행\n", kRuns);
		LogA("[mlt] 🎚️   1단계 세 축 함께 300 → 축별 **마진·엔트로피**(표적을 안 본다)"
		     " · 2단계 **yaw 만** 300 → 축별 **낙폭**\n");
		LogA("[mlt] 🎚️   물음: **마진이 낮았던 축이 더 많이 잊히나**(`y` vs `pitch`) ⇒ 부호검정 %u/12\n",
			kSignNeed);
		LogA("[mlt] 🎚️   ⚠️ 이 회차는 파라미터를 **0개** 늘리고 진실 접촉을 **0회** 늘린다"
		     " — 그것이 「기본 대조군」의 뜻이다\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

	static void _StartEval()
	{
		_eb = 0u; _sumP = 0.0f;
		for (uint32 a = 0; a < MLTP1::kAxes; ++a)
		{ _hit[a] = 0u; _cnt[a] = 0u; _mg[a] = 0.0f; _en[a] = 0.0f; }
		_st = kEvalUp;
	}

	static void _EvalDone()
	{
		for (uint32 a = 0; a < MLTP1::kAxes; ++a)
		{
			const float acc = _cnt[a] ? (float)_hit[a] / (float)_cnt[a] : 0.0f;
			const float w = _bB[a].acc - _bC[a].acc;
			_phR[_ph][a] = (w > 1.0e-4f) ? (acc - _bC[a].acc) / w : 0.0f;
			_phMg[_ph][a] = _mg[a] / (float)_eb;
			_phEn[_ph][a] = _en[a] / (float)_eb;
		}
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
		for (uint32 a = 0; a < MLTP1::kAxes; ++a)
		{
			_rDrop[_run][a] = _phR[1][a] - _phR[0][a];
			_rMg[_run][a] = _phMg[0][a];      // ★ **1단계 직후**의 신뢰(예고를 물으므로)
			_rEn[_run][a] = _phEn[0][a];
		}
		_rOk[_run] = _finite && (Abs(sp - 1.0f) <= 0.01f);
		_rTruth[_run] = _M.TruthTouches();
		LogA("[mlt] 🎚️ [%2u/%u] 씨앗%2u · 1단계 마진 %.4f/%.4f/%.4f · 엔트로피 %.3f/%.3f/%.3f"
		     " → 낙폭 %+.3f/%+.3f/%+.3f · 진실접촉 %llu%s\n",
			_run + 1u, kRuns, _Seed(_run),
			(double)_rMg[_run][0], (double)_rMg[_run][1], (double)_rMg[_run][2],
			(double)_rEn[_run][0], (double)_rEn[_run][1], (double)_rEn[_run][2],
			(double)_rDrop[_run][0], (double)_rDrop[_run][1], (double)_rDrop[_run][2],
			(unsigned long long)_rTruth[_run], _rOk[_run] ? "" : "  ⛔배관");
		++_run;
		_st = kInit;
		if (_run >= kRuns) _Judge();
	}

	static void _Judge()
	{
		// 대상은 **y(0) 와 pitch(2)** — yaw(1) 은 2단계에서 계속 배운다.
		uint32 signMg = 0u, signEn = 0u, nBoth = 0u;
		float sepSum = 0.0f, mgSum = 0.0f;
		bool plumb = true;
		for (uint32 i = 0; i < kSeeds; ++i)
		{
			if (!_rOk[i]) plumb = false;
			const float m0 = _rMg[i][0], m2 = _rMg[i][2];
			const float e0 = _rEn[i][0], e2 = _rEn[i][2];
			const float d0 = _rDrop[i][0], d2 = _rDrop[i][2];
			sepSum += Abs(m0 - m2);
			mgSum += 0.5f * (m0 + m2);
			// ⚠️ 낙폭이 **둘 다 음수**여야 「어느 쪽이 더 잊혔나」가 성립한다.
			if (d0 < 0.0f && d2 < 0.0f) ++nBoth;
			// ★ 마진이 **낮은** 축이 **더 많이** 잊혔나(낙폭이 더 음수)
			const bool mgLowIsWorse = (m0 < m2) ? (d0 < d2) : (d2 < d0);
			if (mgLowIsWorse) ++signMg;
			// ★ 엔트로피가 **높은** 축이 더 많이 잊혔나
			const bool enHighIsWorse = (e0 > e2) ? (d0 < d2) : (d2 < d0);
			if (enHighIsWorse) ++signEn;
		}
		const float sep = sepSum / (float)kSeeds;
		const float mgAvg = mgSum / (float)kSeeds;

		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🎚️ **회차 14 결과 — 공짜 신뢰의 예고력**\n");
		float dm[MLTP1::kAxes] = { 0.0f }, mm[MLTP1::kAxes] = { 0.0f }, em[MLTP1::kAxes] = { 0.0f };
		for (uint32 a = 0; a < MLTP1::kAxes; ++a)
		{
			float d = 0.0f, m = 0.0f, e = 0.0f;
			for (uint32 i = 0; i < kSeeds; ++i) { d += _rDrop[i][a]; m += _rMg[i][a]; e += _rEn[i][a]; }
			dm[a] = d / (float)kSeeds; mm[a] = m / (float)kSeeds; em[a] = e / (float)kSeeds;
			LogA("[mlt] 🎚️   %-5s 1단계 마진 **%.4f** · 엔트로피 **%.3f** → 낙폭 **%+.3f**\n",
				MLTP1::AxisName(a), (double)mm[a], (double)em[a], (double)dm[a]);
		}
		LogA("[mlt] 🎚️   ⭐ **진실 접촉** %llu 회/실행 — 이 회차의 신뢰는 그것을 **0 늘렸다**\n",
			(unsigned long long)_rTruth[0]);

		if (!plumb) LogA("[mlt] 🎚️   ⛔ ㉣ 배관이 깨진 실행이 있다 — **판정불가**\n");
		else        LogA("[mlt] 🎚️   ✅ ㉣ 배관 — probs 합 1.0 · 전 구간 유한\n");
		const bool g4 = (nBoth >= kSeeds - 1u);
		LogA("[mlt] 🎚️   %s ㉣ 낙폭이 둘 다 음수인 실행 **%u/12** (잊혀야 물음이 성립한다)\n",
			g4 ? "✅" : "⛔", nBoth);

		const bool g3 = (sep > kSepFrac * Abs(mgAvg));
		LogA("[mlt] 🎚️   %s ㉢ 위생 — |마진(y) − 마진(pitch)| 평균 **%.4f** > %.0f%% × 마진 %.4f = %.4f\n",
			g3 ? "✅" : "⛔", (double)sep, (double)(kSepFrac * 100.0f), (double)mgAvg,
			(double)(kSepFrac * Abs(mgAvg)));

		LogA("[mlt] 🎚️   ── ㉠ 표제 ──\n");
		LogA("[mlt] 🎚️   **마진이 낮은 축이 더 많이 잊혔나 — %u/12** (필요 %u · 우연 6)\n",
			signMg, kSignNeed);
		LogA("[mlt] 🎚️   ㉡ 엔트로피 판(높은 축이 더 잊혔나) — %u/12 (읽는 칸)%s\n",
			signEn, ((signMg >= kSignNeed) != (signEn >= kSignNeed)) ? "  ⚠️ **두 지표가 갈린다**" : "");

		LogA("[mlt] ══════════════════════════════════════════════════\n");
		if (!plumb || !g3 || !g4)
			LogA("[mlt] 🎚️ ⛔ **위생/배관이 깨졌다 — 판정불가.** 지표를 바꿔야 한다\n");
		else if (signMg >= kSignNeed)
			LogA("[mlt] 🎚️ ⇒ ✅✅ **공짜 신뢰가 예고한다**(%u/12) ⇒ ***신뢰 헤드를 만들지 않는다.***"
			     " 다음은 그 공짜 값으로 재방문을 조건화하는 폐회로다"
			     "(⚠️ 그래도 **정책은 배워야** 한다)\n", signMg);
		else
			LogA("[mlt] 🎚️ ⇒ ⚠️ **공짜 신뢰는 바닥이다**(%u/12 · 우연 6 · 필요 %u)"
			     " ⇒ 「실현 채점」(오차 − 자기가 예상한 오차)이 값을 할 여지가 **생긴다.**"
			     " ⚠️ 그래도 다음 회차는 **그 헤드의 폭 재기**이고 만드는 것은 그 뒤다\n",
				signMg, kSignNeed);
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}
};
