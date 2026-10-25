// mltp1o.cw — 🔮 **회차 16 · 오라클 신뢰의 폭 재기 — 「예고」라는 목적지에 천장이 있나**
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문** — ⚠️ 재기 전에 적는다. 정본은 `mltlog_1.md` 회차 15 의 「회차 16 등록」이다.
// ══════════════════════════════════════════════════════════════════════════════
//
// ★ **무엇을 가르나**
//
//   회차 14·15 가 «진실 접촉 0 인 신뢰는 예고하지 않는다»(3/12 · 7/12)를 확정했다.
//   ⇒ 그런데 그것만으로 「실현 채점 헤드를 만들자」로 가면 **한 발 빠르다** — 물어야 할 것이 남았다:
//   ***진실을 완전히 써서 만든 신뢰(= 천장)는 예고하나?***
//   · 천장이 있다 ⇒ 공짜(바닥)와 천장 사이에 **폭**이 있다 ⇒ 헤드를 만들 자격이 생긴다.
//   · 천장이 **바닥이면** ⇒ «1단계 상태로 무엇이 잊힐지 예고한다» 는 목적지 자체가 죽은 것이다
//     ⇒ **그 목적지를 삭제한다**(「폭이 문턱을 못 넘는 목적지는 삭제한다」).
//
// ══════════════════════════════════════════════════════════════════════════════
// ① 설계 — 회차 15 와 같되 ⚠️ **회귀 효과를 설계로 없앤다**
// ══════════════════════════════════════════════════════════════════════════════
//   ```
//   1단계  세 축 함께 300스텝 → pitch 의 **마진 · 엔트로피 · 행별 오차의 분산(오라클)** · R(1)
//   2단계  yaw 만 300스텝     → pitch 의 **R(2)** (⚠️ 절대값 — 낙폭이 아니다)
//   ```
//   ⚠️⚠️ **회귀 효과**: 회차 15 뒤에 알았다 — `낙폭 = R(2) − R(1)` 은 1단계가 높으면 크기 쉽다.
//     인스턴스 간 비교에서 그것이 교란이다. ⇒ **설계로 없앤다**:
//     · 지표 = **R(2) 절대값**
//     · **짝짓기 변수 = R(1)** — R(1) 로 정렬해 **인접 짝**(0,1)(2,3)… **12쌍**을 만든다
//       ⇒ 짝 안에서 1단계 수준이 거의 같다 ⇒ R(1) 의 효과가 통제된다.
//   ★ 인스턴스 = 씨앗 12 × 에피소드 구간 2 = **24**(회차 15 와 같다).
//
//   **예측자 셋** — 짝 안에서 「예측자가 나쁜 쪽이 R(2) 도 낮나」의 부호검정. **표제는 ㈂** 다.
//     ㈀ 마진(낮은 쪽이 나쁘다 · 진실 접촉 0)      — 회차 15 의 **재현 검사**(읽는 칸)
//     ㈁ 엔트로피(높은 쪽이 나쁘다 · 진실 접촉 0)   — 읽는 칸
//     ㈂ ★ **오라클 = 행별 오차의 분산**(높은 쪽이 나쁘다 · 진실 접촉 **최대**)
//       ⚠️ 1단계 `R` 자체를 예측자로 쓰면 **짝짓기 변수와 같아져** 무의미하다 ⇒ 분산을 쓴다
//       (같은 평균 오차인데 **고르게 퍼졌나 몇 행에 몰렸나**를 가른다).
//   **관문**
//     ㉠ ★ ㈂ 가 **≥ 10/12** ⇒ ***천장이 있다*** ⇒ 실현 채점 헤드를 만들 **자격**이 생긴다.
//        **≤ 8/12** ⇒ ***천장이 바닥이다*** ⇒ **「예고」 목적지를 삭제한다** — 자기평가의 자리는
//        예고가 아니라 **다른 것**이 되고, 그것을 이 라운드의 결과로 적는다.
//     ㉡ 위생 — 짝 안에서 **㈂ 의 값이 실제로 갈리나**(차이 평균 > 값 평균의 10%).
//     ㉢ 위생 — 짝 안의 **R(1) 차이가 작나**(짝짓기가 실제로 통제했나 · 차이 평균 < R(1) 평균의 10%).
//     ㉣ 배관 — `probs` 합 1.0 · 유한 · 진실 접촉 313,344/실행(회차 14·15 와 같아야 한다)
//
// ⚠️ 이 회차도 **아무것도 만들지 않는다**(오라클은 **읽기만** 한다 — 학습에 안 들어간다).
// ⚠️ 비용: 24 인스턴스 × 600스텝 ⇒ **≈2분**.

using namespace PE;

class MLTP1O
{
public:
	static bool Done() { return _run >= kRuns; }

	static void Tick(RHI* rhi)
	{
		if (_run >= kRuns || rhi == nullptr) return;
		if (MLTModelCfg::kAxes != MLTP1::kAxes || MLTModelCfg::kTime != MLTP1::kTime)
		{ LogA("[mlt] 🔮 ⛔⛔ 축/시각 전제가 다르다\n"); _run = kRuns; return; }
		// ⚠️ **기본에서 껐다** — 회차 16 은 판정불가로 끝났고 캔버스 3연속으로 「예고」 목적지가
		//   삭제됐다(`mltlog_1.md` 회차 16). ★ 다시 돌리려면 `-mltoracle`.
		if (!OS::CommandLine::Has("-mltoracle"))
		{
			LogA("[mlt] 🔮 회차 16(오라클 천장)은 **꺼져 있다**(`-mltoracle`) — 기록: 판정불가"
			     "(예측자가 안 갈린다) · **잊음이 전면적·균일** ⇒ 「예고」 목적지 삭제\n");
			_run = kRuns;
			return;
		}
		if (!_banner) { _Banner(); _banner = true; }

		if (_st == kInit)
		{
			if (!_M.Setup(rhi)) { LogA("[mlt] 🔮 준비 실패(run %u)\n", _run); _run = kRuns; return; }
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
				if (!_M.ReadLoss(ls)) { LogA("[mlt] 🔮 손실 리드백 실패\n"); _run = kRuns; return; }
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
					_Batch(_Seed(_run), _EpiBase(_run) + _ph * 20000u + (_step + k) * MLTModelCfg::kBatch,
						(_ph == 0u) ? kAll : 1u, v, g);
					for (uint32 i = 0; i < v.Count(); ++i) _pv.Add(v[i]);
					for (uint32 i = 0; i < g.Count(); ++i) _pt.Add(g[i]);
				}
				if (!_M.UploadPool(_pv, _pt, n)) { LogA("[mlt] 🔮 풀 업로드 실패\n"); _run = kRuns; return; }
			}
			_M.SelectStep(slot);
			if (!_M.Forward() || !_M.Backward() || !_M.AdamStep())
			{ LogA("[mlt] 🔮 스텝 실패(ph %u · step %u)\n", _ph, _step); _run = kRuns; return; }
			++_step;
			return;
		}

		if (_st == kEvalUp)
		{
			if (_eb >= kEvalB) { _EvalDone(); return; }
			_Batch(_Seed(_run), kEvalEpi0 + _eb * MLTModelCfg::kBatch, kAll, _ev, _et);
			if (!_M.Upload(_ev, _et)) { LogA("[mlt] 🔮 시험 업로드 실패\n"); _run = kRuns; return; }
			if (!_M.Forward()) { LogA("[mlt] 🔮 시험 forward 실패\n"); _run = kRuns; return; }
			_st = kEvalRd;
			return;
		}

		// kEvalRd — pitch 만: 정확도 + 마진·엔트로피(접촉 0) + ⭐ 오차 분산(오라클 · 접촉 최대)
		{
			Array<float> m;
			m.Reset(0);
			for (uint32 r = 0; r < MLTModelCfg::kRows; ++r)
				m.Add((((r % MLTModelCfg::kCtx) % MLTP1::kAxes) == kAxis) ? 1.0f : 0.0f);
			uint32 h = 0u, n = 0u, hb = 0u, nb = 0u;
			float sp = 0.0f, dd = 0.0f, ddb = 0.0f, ddo = 0.0f;
			if (!_M.ReadHits(_et, m, h, n, hb, nb, sp, dd, ddb, ddo))
			{ LogA("[mlt] 🔮 리드백 실패\n"); _run = kRuns; return; }
			_hit += hb; _cnt += nb;
			float mg = 0.0f, en = 0.0f; uint32 cn = 0u;
			if (!_M.ReadConf(m, mg, en, cn)) { LogA("[mlt] 🔮 신뢰 리드백 실패\n"); _run = kRuns; return; }
			_mg += mg; _en += en;
			float em = 0.0f, ev = 0.0f; uint32 ecn = 0u;
			if (!_M.ReadErrVar(_et, m, em, ev, ecn)) { LogA("[mlt] 🔮 오라클 리드백 실패\n"); _run = kRuns; return; }
			_evar += ev;
			_sumP += sp;
			++_eb;
			_st = kEvalUp;
		}
	}

private:
	static constexpr uint32 kSeeds = 12u, kSeed0 = 12u;
	static constexpr uint32 kSpans = 2u;
	static constexpr uint32 kRuns = kSeeds * kSpans;     // 24
	static constexpr uint32 kPairs = kRuns / 2u;         // 12
	static constexpr uint32 kAxis = 2u;                  // pitch 고정(회차 15 와 같다)
	static constexpr int    kHold = MLTWorldCfg::kHoldMid;
	static constexpr uint32 kSteps = 300u;
	static constexpr uint32 kEvalEpi0 = 0u, kEvalB = 4u;
	static constexpr uint32 kEvalEpis = kEvalB * MLTModelCfg::kBatch;
	static constexpr uint32 kAll = 0xFFFFFFFFu;
	static constexpr uint32 kSignNeed = 10u, kSignFloor = 8u;
	static constexpr float  kSepFrac = 0.10f;

	static uint32 _Seed(uint32 r) { return kSeed0 + (r % kSeeds); }
	static uint32 _EpiBase(uint32 r) { return (r < kSeeds) ? 1000u : 60000u; }

	enum { kInit = 0, kTrain, kEvalUp, kEvalRd };

	inline static MLTModel _M;
	inline static bool _banner = false;
	inline static uint32 _run = 0u, _ph = 0u, _step = 0u, _eb = 0u;
	inline static int _st = kInit;
	inline static bool _finite = true;
	inline static float _sumP = 0.0f, _mg = 0.0f, _en = 0.0f, _evar = 0.0f;
	inline static uint32 _hit = 0u, _cnt = 0u;
	inline static MLTP1::Base _bC[MLTP1::kAxes], _bB[MLTP1::kAxes];
	inline static float _phR[2] = { 0.0f, 0.0f };
	inline static float _phMg[2] = { 0.0f, 0.0f }, _phEn[2] = { 0.0f, 0.0f }, _phVar[2] = { 0.0f, 0.0f };
	inline static Array<float> _ev, _et, _pv, _pt;

	inline static float _rR1[kRuns] = { 0.0f }, _rR2[kRuns] = { 0.0f };
	inline static float _rMg[kRuns] = { 0.0f }, _rEn[kRuns] = { 0.0f }, _rVar[kRuns] = { 0.0f };
	inline static bool  _rOk[kRuns] = { false };
	inline static uint64 _rTruth[kRuns] = { 0ull };

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🔮 **회차 16 · 오라클 신뢰의 폭 재기** — 「예고」 목적지에 **천장**이 있나 · %u 인스턴스\n",
			kRuns);
		LogA("[mlt] 🔮   짝짓기 변수 = **R(1)**(인접 짝 %u쌍 · 회귀 효과 통제) · 지표 = **R(2) 절대값**\n",
			kPairs);
		LogA("[mlt] 🔮   예측자: ㈀ 마진(접촉 0 · 재현) ㈁ 엔트로피(접촉 0) ㈂ ★ **오차 분산(접촉 최대)**\n");
		LogA("[mlt] 🔮   문턱: ㈂ ≥%u ⇒ 천장 있음(헤드 자격) · ≤%u ⇒ **「예고」 목적지 삭제**\n",
			kSignNeed, kSignFloor);
		LogA("[mlt] 🔮   ⚠️ 이 회차도 **아무것도 만들지 않는다**(오라클은 읽기만 한다)\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

	static void _StartEval()
	{
		_eb = 0u; _sumP = 0.0f; _hit = 0u; _cnt = 0u; _mg = 0.0f; _en = 0.0f; _evar = 0.0f;
		_st = kEvalUp;
	}

	static void _EvalDone()
	{
		const float acc = _cnt ? (float)_hit / (float)_cnt : 0.0f;
		const float w = _bB[kAxis].acc - _bC[kAxis].acc;
		_phR[_ph] = (w > 1.0e-4f) ? (acc - _bC[kAxis].acc) / w : 0.0f;
		_phMg[_ph] = _mg / (float)_eb;
		_phEn[_ph] = _en / (float)_eb;
		_phVar[_ph] = _evar / (float)_eb;
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
		_rR1[_run] = _phR[0]; _rR2[_run] = _phR[1];
		_rMg[_run] = _phMg[0]; _rEn[_run] = _phEn[0]; _rVar[_run] = _phVar[0];   // ★ 1단계 직후의 값
		_rOk[_run] = _finite && (Abs(sp - 1.0f) <= 0.01f);
		_rTruth[_run] = _M.TruthTouches();
		LogA("[mlt] 🔮 [%2u/%u] 씨앗%2u 구간%u · R(1) %.3f · 마진 %.4f · 분산 **%.2f** → R(2) **%.3f**%s\n",
			_run + 1u, kRuns, _Seed(_run), (_run < kSeeds) ? 0u : 1u,
			(double)_rR1[_run], (double)_rMg[_run], (double)_rVar[_run], (double)_rR2[_run],
			_rOk[_run] ? "" : "  ⛔배관");
		++_run;
		_st = kInit;
		if (_run >= kRuns) _Judge();
	}

	// 짝 안에서 「예측자가 나쁜 쪽이 R(2) 도 낮나」를 센다.
	//   `worseIsHigh` — 예측자가 **높을수록** 나쁘다(엔트로피·분산). 마진은 false.
	static uint32 _CountSign(const uint32* ord, const float* pred, bool worseIsHigh, float* sepOut, float* avgOut)
	{
		uint32 sign = 0u;
		float sep = 0.0f, avg = 0.0f;
		for (uint32 k = 0; k < kPairs; ++k)
		{
			const uint32 a = ord[k * 2u], b = ord[k * 2u + 1u];
			const bool aWorse = worseIsHigh ? (pred[a] > pred[b]) : (pred[a] < pred[b]);
			const uint32 w = aWorse ? a : b, g = aWorse ? b : a;
			if (_rR2[w] < _rR2[g]) ++sign;
			sep += Abs(pred[a] - pred[b]);
			avg += 0.5f * (Abs(pred[a]) + Abs(pred[b]));
		}
		if (sepOut != nullptr) *sepOut = sep / (float)kPairs;
		if (avgOut != nullptr) *avgOut = avg / (float)kPairs;
		return sign;
	}

	static void _Judge()
	{
		// ★ **R(1) 로 정렬**하고 **인접 짝**을 만든다 — 그것이 회귀 효과의 통제다.
		uint32 ord[kRuns];
		for (uint32 i = 0; i < kRuns; ++i) ord[i] = i;
		for (uint32 i = 1; i < kRuns; ++i)
		{
			const uint32 key = ord[i];
			uint32 j = i;
			while (j > 0u && _rR1[ord[j - 1u]] > _rR1[key]) { ord[j] = ord[j - 1u]; --j; }
			ord[j] = key;
		}
		bool plumb = true;
		bool truthSame = true;
		for (uint32 i = 0; i < kRuns; ++i)
		{
			if (!_rOk[i]) plumb = false;
			if (_rTruth[i] != 313344ull) truthSame = false;
		}

		float sepVar = 0.0f, avgVar = 0.0f, sepR1 = 0.0f, avgR1 = 0.0f;
		const uint32 sMg = _CountSign(ord, _rMg, false, nullptr, nullptr);
		const uint32 sEn = _CountSign(ord, _rEn, true, nullptr, nullptr);
		const uint32 sVar = _CountSign(ord, _rVar, true, &sepVar, &avgVar);
		// 짝 안의 R(1) 차이(㉢ 위생)
		for (uint32 k = 0; k < kPairs; ++k)
		{
			const uint32 a = ord[k * 2u], b = ord[k * 2u + 1u];
			sepR1 += Abs(_rR1[a] - _rR1[b]);
			avgR1 += 0.5f * (_rR1[a] + _rR1[b]);
		}
		sepR1 /= (float)kPairs; avgR1 /= (float)kPairs;

		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🔮 **회차 16 결과 — 「예고」 목적지의 천장**\n");
		if (!plumb) LogA("[mlt] 🔮   ⛔ ㉣ 배관이 깨진 인스턴스가 있다 — **판정불가**\n");
		else        LogA("[mlt] 🔮   ✅ ㉣ 배관 — probs 합 1.0 · 전 구간 유한\n");
		LogA("[mlt] 🔮   %s ㉣ 진실 접촉 %s(313,344/실행)\n",
			truthSame ? "✅" : "⚠️", truthSame ? "회차 14·15 와 같다" : "**다르다**");
		const bool g3 = (sepR1 < kSepFrac * avgR1);
		LogA("[mlt] 🔮   %s ㉢ 위생 — 짝 안의 R(1) 차이 %.4f < 10%% × %.4f = %.4f (짝짓기가 통제했나)\n",
			g3 ? "✅" : "⛔", (double)sepR1, (double)avgR1, (double)(kSepFrac * avgR1));
		const bool g2 = (sepVar > kSepFrac * avgVar);
		LogA("[mlt] 🔮   %s ㉡ 위생 — 짝 안의 분산 차이 %.3f > 10%% × %.3f = %.3f (예측자가 갈리나)\n",
			g2 ? "✅" : "⛔", (double)sepVar, (double)avgVar, (double)(kSepFrac * avgVar));

		LogA("[mlt] 🔮   ── 예측자별 부호검정(짝 %u쌍 · 우연 6) ──\n", kPairs);
		LogA("[mlt] 🔮   ㈀ 마진(접촉 0 · 재현)   : %u/%u\n", sMg, kPairs);
		LogA("[mlt] 🔮   ㈁ 엔트로피(접촉 0)      : %u/%u\n", sEn, kPairs);
		LogA("[mlt] 🔮   ㈂ ★ **오차 분산(접촉 최대)** : **%u/%u**   ← 표제\n", sVar, kPairs);

		LogA("[mlt] ══════════════════════════════════════════════════\n");
		if (!plumb || !g2 || !g3)
			LogA("[mlt] 🔮 ⛔ **위생/배관이 깨졌다 — 판정불가**\n");
		else if (sVar >= kSignNeed)
			LogA("[mlt] 🔮 ⇒ ✅ **천장이 있다**(%u/%u) — 공짜(바닥)와 오라클(천장) 사이에 폭이 있다"
			     " ⇒ 실현 채점 헤드를 만들 **자격**이 생겼다. ⚠️ 다음은 그 헤드의 등록이지 구현이 아니다\n",
				sVar, kPairs);
		else if (sVar <= kSignFloor)
			LogA("[mlt] 🔮 ⇒ ⚠️⚠️ **천장이 바닥이다**(%u/%u) ⇒ **「1단계 상태로 무엇이 잊힐지 예고한다」"
			     " 목적지를 삭제한다.** 진실을 다 써도 안 되는 것을 헤드가 배울 수는 없다."
			     " ⇒ 자기평가의 자리는 예고가 아니라 **다른 것**이다 — 그것을 이 라운드의 결과로 적는다\n",
				sVar, kPairs);
		else
			LogA("[mlt] 🔮 ⇒ ⚠️ **중간**(%u/%u) ⇒ 표본을 늘려 한 번 더 잰다(지표를 바꾸지 않는다)\n",
				sVar, kPairs);
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}
};
