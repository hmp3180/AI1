// mltp0sweep.cw — 🏁 **P0 판정 라운드.** A단계(바닥·천장 확인) → B단계 파일럿(배우나) → **여기**.
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문** — ⚠️ 재기 전에 적었다. 표제 지표·문턱·팔 번호는 `MLT.md` 의 P0 절이 정본이다.
// ══════════════════════════════════════════════════════════════════════════════
//
//   **팔**(번호는 역할에 고정 — 순서를 바꾸면 표본이 바뀐다)
//     · **팔 4 학습** — 세 난이도 × **판정 씨앗 12~23** = 36 회
//     · **팔 5 값 섞기 `[가림]`** — 중간 난이도 × 12 씨앗 = 12 회 ⇒ 관문 ㉣
//     · **팔 6 값 뺌** — 중간 난이도 × 12 씨앗 = 12 회 ⇒ 팔 5 와 **다른 실험**이다
//     합 **60 회** · 파일럿이 604 프레임에 ≈35초였으므로 **≈35분**
//   ⚠️ 대조군을 한 난이도로 줄인 근거: ㉣ 가 묻는 것은 *"값을 가리면 무작위로 떨어지나"* 이고
//     그것은 **난이도의 함수가 아니다**(가리면 어느 난이도에서도 복사조차 못 한다).
//     ★ **조용히 줄이지 않고 여기 적는다.**
//   ⚠️ **팔 0·1·2·3 은 해석**이고 CPU 로 잰다 — 그리고 **씨앗마다·그 시험 에피소드에서** 잰다
//     (A단계는 개발 씨앗이었다 ⇒ 그 수를 그대로 쓰면 `R` 의 바닥·분모가 다른 표본에서 온다).
//   ⚠️ **팔 7 은 없다** — 슬롯을 늘리는 라운드의 대조군이고 P0 은 슬롯을 안 늘렸다(P1 에서 켠다).
//
//   **가림·뺌의 정의**(⚠️ 결정적이어야 한다 — 난수를 쓰면 비트 재현이 깨진다)
//     · 팔 5: `val'[i] = val[(i·313 + 17) mod 512]`. ★ 313 은 홀수 ⇒ 512 와 서로소 ⇒ **순열**이다.
//       ⚠️ 배치 **전체**에 걸쳐 섞으므로 행의 시간 구조가 통째로 깨진다(그것이 「가림」이다).
//     · 팔 6: `val'[i] = 0`. ⇒ 남는 것은 **위치(RoPE)와 심볼**뿐이다.
//
//   **표제와 검정** — ⚠️ 봉우리를 고른 지표와 검정을 건 지표를 같은 줄에 적는다
//     · `R_seed = (학습_seed − 복사_seed) / (베이즈_seed − 복사_seed)` · 난이도마다 **12 씨앗의 평균**
//     · 부호검정은 **`학습_seed − 복사_seed` 의 부호**에 건다 ⇒ **10/12** (p≈0.019 · Q=6 이라 11/12 불필요)
//
//   **관문**
//     ㉠ ★ 세 난이도 전부 **`R̄ ≥ 0.15`** 그리고 **부호검정 10/12**
//     ㉡ **보간** — ⑫ **재등록판**(2026-08-24 회차 3 의 결과). ⚠️ 앞판은 **관문이 틀렸다**:
//        표적이 밴드인 행을 빼면 분류 헤드에서 그 클래스가 **음의 기울기만** 받아 **억압된다**
//        ⇒ 「보간」이 아니라 「클래스 억압」을 재고 있었다(→ `mltlog_1.md` 회차 3 의 증거 셋).
//        ★ 재등록: 홀드아웃을 **「현재값」**에 건다(`y[t] ∈ [0.30, 0.50)` 인 **행의 손실**을 뺀다)
//          ⇒ 모든 출력 버킷이 계속 훈련되고, 묻는 것이
//            *"그 상태에서 **물어본 적이 없는데** 규칙을 옮겨 쓰나"* 가 된다.
//        ★ 그리고 지표를 **연속량**으로 둔다(규율 5): `dist = |argmax − 표적|`(버킷 거리)
//          `D = (복사거리 − 학습거리) / (복사거리 − 베이즈거리)` — 바닥 0 · 천장 1(`R` 과 같은 모양).
//          ⚠️ 이진 정확도는 「버킷 하나 차이」와 「완전히 틀림」을 못 가른다.
//        **문턱 `D̄_band ≥ 0.10`** · 그리고 `D̄_all` 과 비율 `D̄_band / D̄_all` 을 **읽는다**(관문은 아니다).
//        📐 손계산(재기 전에): 복사 거리 `E|k| = 0.975` 버킷 · 베이즈 `(1/h)·0.975`
//          ⇒ 창 = **0.894 / 0.780 / 0.4875**(hold 12/5/2). ⚠️ 반사가 6.6/2.1/0.4% 줄이므로
//          복사는 **0.911 / 0.955 / 0.971** 로 예측한다(A단계 관문 ㉤ 가 그것을 확인한다).
//     ㉢ **기제** — 팔 5·6 이 **떨어지나**(P0 은 축이 하나라 「기울기가 그 축에 몰리나」가 정의되지
//        않는다 ⇒ 값 경로의 발화를 낙폭으로 잰다. 원래 형식은 P1 에서 켠다)
//     ㉣ **대조군** — 팔 5 가 **≤ 8.0%** 인가. ★ 근거: 값을 가리면 최선이 **전역 최빈**(A단계 2.52%)
//        이고 위치로 얻을 구조가 거의 없다 ⇒ 8% 는 그 3배를 넘는 여유다.
//        ⚠️ **안 떨어지면 판정불가**다(성능이 나쁘다는 뜻이 아니라 «아직 못 측정했다»는 뜻).
//     ㉤ **상한** — 학습이 **베이즈를 넘으면 버그**다(누출·표적 어긋남). 난이도마다 본다.

using namespace PE;

class MLTP0Sweep
{
public:
	static bool Done() { return _run >= kRuns; }

	// ══════════════════════════════════════════════════════════════════
	// 🚪 매 프레임. ⚠️ **한 프레임 = 한 스텝**(리드백이 프레임을 넘어야 한다).
	// ══════════════════════════════════════════════════════════════════
	static void Tick(RHI* rhi)
	{
		if (_run >= kRuns || rhi == nullptr) return;
		// ⚠️ **기본에서 껐다** — 회차 3·4 로 두 번 돌았고 표제가 **통계 재현**됐다(`mltlog_1.md`).
		//   ★ 다시 돌리려면 `-mltsweep`. **지운 것이 아니라 끈 것**이다(등록문과 실측이 여기 남아 있다).
		if (!OS::CommandLine::Has("-mltsweep"))
		{
			LogA("[mlt] 🏁 P0 판정 스윕은 **꺼져 있다**(`-mltsweep` 으로 켠다) — 회차 3·4 기록:"
			     " R̄ ≈ 0.70/0.68/0.34 · 부호검정 12·12·12 · ⛔ 보간\n");
			_run = kRuns;
			return;
		}
			// ⚠️⚠️⚠️ **P0 은 `kCtx = 64`(원래 배치)로 등록됐다.** 지금은 P1 의 배치다
			//   ⇒ 이 하네스를 그대로 돌리면 **등록문과 다른 것을 재고** 그 수를 P0 의 수인 것처럼
			//   적게 된다. ★ 그래서 **크게 집고 멈칸다.**
			//   ⇒ 그 회차를 재현하려면 **그 초기 커밋으로 돌아가라**(`mltlog_1.md` 회차 3·4·5).
			if (MLTModelCfg::kAxes != 1u || MLTModelCfg::kCtx != 64u)
			{
				LogA("[mlt] 🏁 ⛔⛔ **이 하네스는 P0 의 배치(kCtx=64 · 원래 1축)를 전제한다** —"
				     " 지금은 kCtx=%u · 축 %u 다. **재현은 그 커밋에서 하라**(회차 3~5)\n",
					MLTModelCfg::kCtx, MLTModelCfg::kAxes);
				_run = kRuns;
				return;
			}
		if (!_banner) { _Banner(); _banner = true; }

		if (_st == kInit)
		{
			const Cfg c = _Plan(_run);
			if (!_M.Setup(rhi))
			{ LogA("[mlt] 🏁 모델 준비 실패(run %u) — 스윕을 접는다\n", _run); _run = kRuns; return; }
			// 씨앗별 바닥·천장 — ⚠️ **모델이 시험할 그 에피소드**에서 잰다
			MLTP0::BaselineSeed(c.seed, c.hold, kEvalEpi0, kEvalEpis, _bCopy, _bBayes);
			_step = 0u; _eval = 0u; _hits = 0u; _n = 0u; _hitsB = 0u; _nB = 0u;
			_sumP = 0.0f; _first = 0.0f; _last = 0.0f; _finite = true;
			_dist = 0.0f; _distB = 0.0f;
			_trValid = 0u; _trBatch = 0u;
			_st = kTrain;
			return;
		}

		if (_st == kTrain)
		{
			const Cfg c = _Plan(_run);
			if (_step > 0u)
			{
				float ls = 0.0f;
				if (!_M.ReadLoss(ls)) { LogA("[mlt] 🏁 손실 리드백 실패(run %u)\n", _run); _run = kRuns; return; }
				if (!(ls == ls) || ls > 1.0e30f) _finite = false;
				if (_step == 1u) _first = ls;
				_last = ls;
			}
			if (_step >= kTrainSteps) { _st = kEvalUp; return; }

			Array<float> val, tgt, band;
			_Batch(c, kTrainEpi0 + _step * MLTModelCfg::kBatch, true, val, tgt, band);
			if (!_M.Upload(val, tgt)) { LogA("[mlt] 🏁 업로드 실패(run %u · step %u)\n", _run, _step); _run = kRuns; return; }
			_trValid += _M.Valid(); ++_trBatch;
			if (!_M.Forward() || !_M.Backward() || !_M.AdamStep())
			{ LogA("[mlt] 🏁 스텝 실패(run %u · step %u)\n", _run, _step); _run = kRuns; return; }
			++_step;
			return;
		}

		if (_st == kEvalUp)
		{
			if (_eval >= kEvalB) { _Finish(); return; }
			const Cfg c = _Plan(_run);
			_Batch(c, kEvalEpi0 + _eval * MLTModelCfg::kBatch, false, _evVal, _evTgt, _evBand);
			if (!_M.Upload(_evVal, _evTgt)) { LogA("[mlt] 🏁 시험 업로드 실패\n"); _run = kRuns; return; }
			if (!_M.Forward()) { LogA("[mlt] 🏁 시험 forward 실패\n"); _run = kRuns; return; }
			_st = kEvalRd;
			return;
		}

		// kEvalRd
		{
			uint32 h = 0u, n = 0u, hb = 0u, nb = 0u; float sp = 0.0f, dd = 0.0f, ddb = 0.0f, ddo = 0.0f;
			if (!_M.ReadHits(_evTgt, _evBand, h, n, hb, nb, sp, dd, ddb, ddo))
			{ LogA("[mlt] 🏁 시험 리드백 실패\n"); _run = kRuns; return; }
			_hits += h; _n += n; _hitsB += hb; _nB += nb; _sumP += sp;
			// ⚠️ `dd`/`ddb` 는 **배치 평균**이다 ⇒ 배치 수로 나눠 합친다(행 수로 가중하면 밴드가 왜곡된다).
			_dist += dd; _distB += ddb;
			++_eval;
			_st = kEvalUp;
		}
	}

private:
	// ── 계획 ────────────────────────────────────────────────────────
	//   ⚠️ 순서를 **팔 4 먼저**로 둔다: 표제가 먼저 서면 대조군을 읽는 뜻이 분명해진다.
	struct Cfg { int arm; int diff; int hold; uint32 seed; };

	static constexpr uint32 kSeed0 = 12u, kSeeds = 12u;   // ⚠️ **판정 씨앗**(개발은 0~11)
	static constexpr int    kDiffs = 3;
	static constexpr uint32 kA4 = (uint32)kDiffs * kSeeds;    // 36
	static constexpr uint32 kA5 = kSeeds;                     // 12 (중간만)
	static constexpr uint32 kA6 = kSeeds;                     // 12 (중간만)
	static constexpr uint32 kRuns = kA4 + kA5 + kA6;          // 60

	static constexpr uint32 kTrainSteps = 600u;
	static constexpr uint32 kTrainEpi0  = 1000u;
	static constexpr uint32 kEvalEpi0   = 0u;
	static constexpr uint32 kEvalB      = 4u;
	static constexpr uint32 kEvalEpis   = kEvalB * MLTModelCfg::kBatch;   // 32
	static constexpr float  kThreshR    = 0.15f;
	static constexpr float  kThreshBand = 0.10f;
	static constexpr uint32 kSignNeed   = 10u;
	static constexpr float  kArm5Max    = 0.080f;

	static Cfg _Plan(uint32 r)
	{
		Cfg c{};
		const int mid = MLTWorldCfg::kHoldMid;
		if (r < kA4)      { c.arm = 4; c.diff = (int)(r / kSeeds); c.seed = kSeed0 + (r % kSeeds); }
		else if (r < kA4 + kA5) { c.arm = 5; c.diff = 1; c.seed = kSeed0 + (r - kA4); }
		else              { c.arm = 6; c.diff = 1; c.seed = kSeed0 + (r - kA4 - kA5); }
		const int holds[kDiffs] = { MLTWorldCfg::kHoldEasy, mid, MLTWorldCfg::kHoldHard };
		c.hold = holds[c.diff];
		return c;
	}
	static const char* _DiffName(int d) { return (d == 0) ? "쉬움" : ((d == 1) ? "중간" : "어려움"); }

	enum { kInit = 0, kTrain, kEvalUp, kEvalRd };

	inline static MLTModel _M;
	inline static bool   _banner = false;
	inline static uint32 _run = 0u;
	inline static int    _st = kInit;
	inline static uint32 _step = 0u, _eval = 0u, _hits = 0u, _n = 0u, _hitsB = 0u, _nB = 0u;
	inline static uint32 _trValid = 0u, _trBatch = 0u;
	inline static float  _sumP = 0.0f, _first = 0.0f, _last = 0.0f;
	inline static MLTP0::Base _bCopy{}, _bBayes{};
	inline static float  _dist = 0.0f, _distB = 0.0f;
	inline static bool   _finite = true;
	static float _copy()  { return _bCopy.acc; }
	static float _bayes() { return _bBayes.acc; }
	inline static Array<float> _evVal, _evTgt, _evBand;

	// 결과 표 — 실행마다 한 줄
	inline static float _rAcc[kRuns] = { 0.0f };
	inline static float _rR[kRuns]   = { 0.0f };
	inline static float _rD[kRuns]   = { 0.0f };   // 거리 기반 D (전체)
	inline static float _rDB[kRuns]  = { 0.0f };   // 거리 기반 D (밴드 = 물어본 적 없는 상태)
	inline static float _rCopy[kRuns]  = { 0.0f };
	inline static float _rBayes[kRuns] = { 0.0f };
	inline static bool  _rOk[kRuns]  = { false };

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🏁 **P0 판정 라운드** — 팔 4(%u) + 팔 5(%u) + 팔 6(%u) = **%u 회**\n", kA4, kA5, kA6, kRuns);
		LogA("[mlt] 🏁   판정 씨앗 %u~%u · 훈련 %u스텝 · 시험 %u에피소드(%u예측)\n",
			kSeed0, kSeed0 + kSeeds - 1u, kTrainSteps, kEvalEpis, kEvalEpis * MLTModelCfg::kCtx);
		LogA("[mlt] 🏁   문턱: R̄ ≥ %.2f · 부호검정 %u/12 · 보간 R̄ ≥ %.2f · 팔5 ≤ %.1f%%\n",
			(double)kThreshR, kSignNeed, (double)kThreshBand, (double)(kArm5Max * 100.0f));
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

	// ── 배치 ────────────────────────────────────────────────────────
	static void _Batch(const Cfg& c, uint32 epi0, bool holdout,
		Array<float>& val, Array<float>& tgt, Array<float>& band)
	{
		typedef MLTModelCfg M;
		val.Reset(0); tgt.Reset(0); band.Reset(0);
		float y[M::kCtx + 1u];
		for (uint32 b = 0; b < M::kBatch; ++b)
		{
			MLTWorld w;
			w.Reset(c.seed, epi0 + b, c.hold, 0);
			y[0] = w.State().y;
			for (uint32 t = 0; t < M::kCtx; ++t) { w.Step(); y[t + 1u] = w.State().y; }
			for (uint32 t = 0; t < M::kCtx; ++t) val.Add(y[t]);
			for (uint32 t = 0; t < M::kCtx; ++t)
			{
				// ⚠️⚠️ **밴드는 「현재값」이다**(⑫ 재등록) — 표적으로 걸면 그 클래스가 억압된다.
				const bool inBand = (y[t] >= MLTP0::BandLo() && y[t] < MLTP0::BandHi());
				tgt.Add((holdout && inBand) ? M::kIgnoreTgt : (float)MLTP0::Bucket(y[t + 1u]));
				band.Add(inBand ? 1.0f : 0.0f);
			}
		}
		// ── 팔 5·6 — ⚠️ **값만** 바꾼다(표적·위치·심볼은 그대로) ⇒ 「같은 비용, 내용만 없앰」
		if (c.arm == 5)
		{
			Array<float> src = val;
			for (uint32 i = 0; i < val.Count(); ++i) val[i] = src[(i * 313u + 17u) % M::kRows];
		}
		else if (c.arm == 6)
		{
			for (uint32 i = 0; i < val.Count(); ++i) val[i] = 0.0f;
		}
	}

	// ── 실행 하나를 마감한다 ─────────────────────────────────────────
	static void _Finish()
	{
		const Cfg c = _Plan(_run);
		const float acc  = (_n  > 0u) ? (float)_hits  / (float)_n  : 0.0f;
		const float dAll = (_eval > 0u) ? _dist  / (float)_eval : 0.0f;
		const float dBnd = (_eval > 0u) ? _distB / (float)_eval : 0.0f;
		const float win  = _bayes() - _copy();
		const float R  = (win > 1.0e-4f) ? (acc - _copy()) / win : 0.0f;
		// ★ 거리는 **작을수록 좋다** ⇒ 분자의 부호가 정확도와 반대다.
		const float wD  = _bCopy.dist     - _bBayes.dist;
		const float wDB = _bCopy.distBand - _bBayes.distBand;
		const float D  = (wD  > 1.0e-4f) ? (_bCopy.dist     - dAll) / wD  : 0.0f;
		const float DB = (wDB > 1.0e-4f) ? (_bCopy.distBand - dBnd) / wDB : 0.0f;
		const float sp = (_eval > 0u) ? _sumP / (float)_eval : 0.0f;

		_rAcc[_run] = acc; _rR[_run] = R; _rD[_run] = D; _rDB[_run] = DB;
		_rCopy[_run] = _copy(); _rBayes[_run] = _bayes();
		_rOk[_run] = _finite && (Abs(sp - 1.0f) <= 0.01f);

		LogA("[mlt] 🏁 [%2u/%u] 팔%d %-6s 씨앗%2u · 손실 %.3f→%.3f · 정확도 %.2f%% ⇒ **R=%.3f**"
		     " · 거리 %.3f(복사 %.3f/베이즈 %.3f) **D=%.3f** · 밴드 %.3f(복사 %.3f) **D=%.3f**%s\n",
			_run + 1u, kRuns, c.arm, _DiffName(c.diff), c.seed,
			(double)_first, (double)_last, (double)(acc * 100.0f), (double)R,
			(double)dAll, (double)_bCopy.dist, (double)_bBayes.dist, (double)D,
			(double)dBnd, (double)_bCopy.distBand, (double)DB,
			_rOk[_run] ? "" : "  ⛔배관");

		++_run;
		_st = kInit;
		if (_run >= kRuns) _Judge();
	}

	// ══════════════════════════════════════════════════════════════════
	// ⚖️ 판정 — ⚠️ 관문 다섯. 하나라도 깨지면 표제를 인용하지 않는다.
	// ══════════════════════════════════════════════════════════════════
	static void _Judge()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🏁 **P0 판정 결과**\n");

		int fail = 0;
		bool plumbing = true;
		for (uint32 r = 0; r < kRuns; ++r) if (!_rOk[r]) plumbing = false;
		if (!plumbing) { LogA("[mlt] 🏁   ⛔ **배관이 깨진 실행이 있다**(probs 합 ≠ 1 또는 비유한) — 판정불가\n"); ++fail; }

		// ── ㉠ 표제 ─────────────────────────────────────────────────
		float rBar[kDiffs] = { 0.0f, 0.0f, 0.0f };
		uint32 sign[kDiffs] = { 0u, 0u, 0u };
		bool ceilOk = true;
		for (int d = 0; d < kDiffs; ++d)
		{
			float s = 0.0f;
			for (uint32 i = 0; i < kSeeds; ++i)
			{
				const uint32 r = (uint32)d * kSeeds + i;
				s += _rR[r];
				if (_rAcc[r] > _rCopy[r]) ++sign[d];
				if (_rAcc[r] > _rBayes[r]) ceilOk = false;   // ㉤
			}
			rBar[d] = s / (float)kSeeds;
		}
		bool g1 = true;
		for (int d = 0; d < kDiffs; ++d) if (rBar[d] < kThreshR || sign[d] < kSignNeed) g1 = false;
		LogA("[mlt] 🏁   %s ㉠ 표제 — R̄ = %.3f / %.3f / %.3f (문턱 %.2f) · 부호검정 %u·%u·%u /12 (필요 %u)\n",
			g1 ? "✅" : "⛔", (double)rBar[0], (double)rBar[1], (double)rBar[2], (double)kThreshR,
			sign[0], sign[1], sign[2], kSignNeed);
		if (!g1) ++fail;

		// ── ㉡ 보간 — ⑫ **재등록판**: 현재값 밴드 + **거리 지표** ─────────
		float dBar[kDiffs] = { 0.0f, 0.0f, 0.0f }, dbBar[kDiffs] = { 0.0f, 0.0f, 0.0f };
		for (int d = 0; d < kDiffs; ++d)
		{
			float s = 0.0f, sb = 0.0f;
			for (uint32 i = 0; i < kSeeds; ++i)
			{ s += _rD[(uint32)d * kSeeds + i]; sb += _rDB[(uint32)d * kSeeds + i]; }
			dBar[d] = s / (float)kSeeds; dbBar[d] = sb / (float)kSeeds;
		}
		bool g2 = true;
		for (int d = 0; d < kDiffs; ++d) if (dbBar[d] < kThreshBand) g2 = false;
		LogA("[mlt] 🏁   %s ㉡ 보간(**현재값** 밴드 · 훈련 표본 0 · 거리 지표)"
		     " — D̄_band = %.3f / %.3f / %.3f (문턱 %.2f)\n",
			g2 ? "✅" : "⛔", (double)dbBar[0], (double)dbBar[1], (double)dbBar[2], (double)kThreshBand);
		LogA("[mlt] 🏁     ↳ 읽는 칸(관문 아님): D̄_all = %.3f / %.3f / %.3f"
		     " ⇒ 밴드/전체 = %.2f / %.2f / %.2f\n",
			(double)dBar[0], (double)dBar[1], (double)dBar[2],
			(double)(dBar[0] > 1e-4f ? dbBar[0] / dBar[0] : 0.0f),
			(double)(dBar[1] > 1e-4f ? dbBar[1] / dBar[1] : 0.0f),
			(double)(dBar[2] > 1e-4f ? dbBar[2] / dBar[2] : 0.0f));
		if (!g2) ++fail;

		// ── ㉢㉣ 대조군 ─────────────────────────────────────────────
		float a5 = 0.0f, a6 = 0.0f, a4mid = 0.0f;
		for (uint32 i = 0; i < kSeeds; ++i)
		{
			a4mid += _rAcc[kSeeds + i];          // 중간 난이도의 팔 4
			a5    += _rAcc[kA4 + i];
			a6    += _rAcc[kA4 + kA5 + i];
		}
		a4mid /= (float)kSeeds; a5 /= (float)kSeeds; a6 /= (float)kSeeds;
		const bool g4 = (a5 <= kArm5Max);
		const bool g3 = (a5 < a4mid && a6 < a4mid);
		LogA("[mlt] 🏁   %s ㉢ 기제 — 팔4 %.2f%% ↔ 팔5[가림] %.2f%% ↔ 팔6[뺌] %.2f%% (낙폭 %.1f / %.1f %%p)\n",
			g3 ? "✅" : "⛔", (double)(a4mid * 100.0f), (double)(a5 * 100.0f), (double)(a6 * 100.0f),
			(double)((a4mid - a5) * 100.0f), (double)((a4mid - a6) * 100.0f));
		LogA("[mlt] 🏁   %s ㉣ 대조군 — 팔5 %.2f%% ≤ %.1f%% (안 떨어지면 **판정불가**)\n",
			g4 ? "✅" : "⛔", (double)(a5 * 100.0f), (double)(kArm5Max * 100.0f));
		if (!g3) ++fail;
		if (!g4) ++fail;

		// ── ㉤ 상한 ─────────────────────────────────────────────────
		LogA("[mlt] 🏁   %s ㉤ 상한 — 학습이 베이즈를 넘은 실행 %s\n",
			ceilOk ? "✅" : "⛔", ceilOk ? "없다" : "**있다 = 누출이다**");
		if (!ceilOk) ++fail;

		LogA("[mlt] ══════════════════════════════════════════════════\n");
		if (fail == 0)
			LogA("[mlt] 🏁 ✅✅ **P0 통과.** 사전학습 0 · 토크나이저 0 으로 축 하나의 역학을 배웠다 ⇒ P1 로 간다\n");
		else
			LogA("[mlt] 🏁 ⛔ **P0 관문 %d개 실패 — 표제를 인용하지 않는다.** 라운드 기록을 `mltlog_1.md` 에 잇는다\n", fail);
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}
};
