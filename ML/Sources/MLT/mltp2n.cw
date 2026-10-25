// mltp2n.cw — 🗄️👁️ **P2 걸음 6 · `N` 스윕**(사전 크기). 회차 19 가 등록한 축이고 회차 24 가 불렀다.
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문** — ⚠️ 재기 **전에** 적는다.
// ══════════════════════════════════════════════════════════════════════════════
//
// ① **팔 셋 `N ∈ {250, 1000, 1999}`** — 회차 19 의 규칙 `{U/8, U/2, U}` 이 낸 점 그대로다
//    (`U` = 서로 다른 8×8 패치 **1999개**). `k = 8` · **학습 프레임 128 고정** · 시험은 회차 24 와 같다
//    (**다른 에피소드** 0~7). ⚠️ 한 회차에 축 둘을 흔들지 않는다.
//
// ② ⚠️ **회차 24 의 갈래는 `wd` 를 가리켰다 — 그것을 먼저 하지 않는 이유를 적는다**(대기열에 남긴다):
//    ⭐ 회차 24 가 새 사실을 냈다 — **사용률이 데이터 16배에도 33.6 → 42.2 뿐**이다(rank 151 의 28%).
//    그리고 회차 23 에서 사용률이 오른 유일한 길은 `k` 를 키우는 것이었는데 그것은
//    *"패치마다 더 많이 쓴다"* 이지 *"사전이 깨어난다"* 가 아니다.
//    ⇒ 병목은 **죽은 유닛**(top-k 승자독식)이고 `wd` 는 죽은 행을 0 으로 밀 뿐 **깨우지 못한다.**
//    ★ `N` 은 그 죽은 유닛의 **수 자체**를 흔든다 ⇒ 원인을 가르는 쪽이 먼저다.
//
// ③ ⭐ **예측을 미리 적는다 — 이것이 이 회차의 핵이다**
//    ```
//    ㈀ 사용률이 `N` 에 거의 무관하다(≈40)   ⇒ 병목은 **사전 크기가 아니라 top-k 동역학**이다
//    ㈁ 사용률이 `N` 에 비례해 늘어난다        ⇒ 사전이 작아서 붐볐던 것이다(그러면 `N` 을 키운다)
//    ㈂ `N=250` 이 시험을 **더 잘** 한다        ⇒ 죽은 유닛이 **해로웠다**(붐비는 것이 낫다)
//    ```
//    ⚠️ ㈀ 이면 다음 자리는 *"죽은 유닛을 깨우는 기제"* 이고 그것은 **우리가 기제를 넣는 것**이다
//      ⇒ `mltconcept.md` 의 ㈀ 경고(*"우리가 비계를 만든 것"*)를 정면으로 다뤄야 한다.
//      ★ 그 판단을 이 회차에서 하지 않는다(등록만 한다) — 결과를 보고 정하면 그것이 사후 선택이다.
//
// ④ **관문 ㉠ 은 그대로** — 표제 `MSE_시험 < 0.01710` · 씨앗별 부호검정 **11/12**(`Q=3`).
//    ⚠️ **고치지 않는다.** ★ 회차 24 에서 F=128·N=1000 이 **0.04105 · 0/12** 였으니 이 관문은
//      아직 멀다 — 그래도 관문은 관문이고, 이 회차가 보는 것은 **사용률의 반응**이다.
//
// ⑤ ⭐ **추세 통계를 사전 등록한다**(회차 24 의 그 결함을 갚는다)
//    회차 24 에서 **쌍별** 부호검정은 세 쌍 모두 10/12(p=0.0193 > 0.0167 보정선)로 ⛔ 였는데
//    **추세**(씨앗마다 세 값이 완전 단조인가)는 8/12 · p=0.00016 이었다. ⇒ 쌍별 보정은 **추세를 못 본다.**
//    ⇒ **등록**: 팔 셋의 순서에 대해 씨앗마다 **완전 단조**인지 세고, 귀무 **1/6** 이항으로 판정한다
//      (양 방향 각각 · `Q = 2` ⇒ 단측 p < **0.025**). ★ 쌍별 검정도 **같이** 찍는다(둘 다 본다).
//
// ⑥ ⭐ 진단 채널(관문 아님): 사용률/rank · 시험/학습 비 · 대조군보다 나쁜 씨앗 수 ·
//    ⭐ **씨앗 10 을 따로** 찍는다(회차 24 의 부채 — 그 씨앗은 시험 MSE 가 대조군의 7배로 다른 체제다).
//
// ⑦ ⚠️ 값 — `N` 이 배치를 정하므로 **팔마다 아레나를 다시 만든다**(세 번뿐이다 · 씨앗마다는 아니다).
//    `N=1999` 는 `vis_recon_bwd_tab` 스레드가 2배(384,000) ⇒ 회차 전체 **십 분 안**.
//
// ══════════════════════════════════════════════════════════════════════════════
// 🧾 **결과(회차 25) — ⭐ 사전 등록한 예측 ㈀ 이 그대로 맞았다.**
// ══════════════════════════════════════════════════════════════════════════════
//   | N | 시험 | 학습 | 비 | 사용률 | of N | 부호검정 | 대조군보다 나쁨 |
//   |---|---|---|---|---|---|---|---|
//   | 250  | 0.04255 | 0.01587 | 2.68 | **31.8** | 12.7% | 2/12 | 4 |
//   | 1000 | 0.04105 | 0.01264 | 3.25 | **38.8** | 3.9%  | 0/12 | 3 |
//   | 1999 | 0.04272 | 0.01174 | 3.64 | **35.8** | 1.8%  | 1/12 | 3 |
//
//   ⭐ **사용률이 `N` 에 거의 무관하다** — `N` 을 **8배**(250 → 1999) 늘렸는데 사용률은
//     31.8 → 35.8 = **1.12배**다(rank 151 의 21~26%). ⇒ 등록한 ㈀ 이다.
//   · 시험 MSE 에 **추세가 없다**: 사전 등록한 추세 통계가 ↓ **1/12**(p=0.888) · ↑ 3/12 — **우연**이다.
//     쌍별도 6/12 · 6/12 · 4/12 로 전부 우연. ⇒ **`N` 은 축이 아니다.**
//   · ⓘ 그런데 **학습** MSE 는 `N` 과 함께 단조로 내려간다(0.01587 → 0.01264 → 0.01174)
//     ⇒ 비가 **2.68 → 3.25 → 3.64** 로 커진다. ⚠️ 큰 사전은 **외우기만 더 한다**
//     (회차 23 의 `k` 와 **같은 얼굴**이다). ⚠️ 학습 쪽에는 추세 통계를 등록하지 않았으므로
//     그 단조는 **보고**이지 판정이 아니다.
//   · ⚠️ 부채(회차 24 의 씨앗 10)를 따로 찍었다: 시험 **0.221** · 대조군 **0.04506**(평균의 1.4배) ·
//     사용률 32/62/55 — **세 팔에서 모두 같은 자리**다 ⇒ 잡음이 아니라 **그 씨앗의 시험 에피소드가
//     학습과 통째로 다르다**는 뜻이다. ⇒ 그 씨앗은 앞으로 **따로 읽는다**(평균에서 빼지는 않는다).
//
//   ★ **세 회차가 같은 곳을 가리킨다 — 사용률이 ~35 에서 고정된다**
//   ```
//   데이터 16배 (회차 24) : 33.6 → 42.2   (1.26배)
//   `N` 8배    (이 회차)  : 31.8 → 35.8   (1.12배)
//   `k` 4배    (회차 23)  : 35.1 → 114.8  (3.27배) ← ⚠️ 이것은 "패치마다 더 많이 쓴다"이지
//                                                     "사전이 깨어난다"가 아니다
//   ```
//   ⇒ **병목은 top-k 승자독식**이다(고전적 죽은 코드 문제). 점수 함수가 한 번 이긴 유닛에게만
//     기울기를 주므로 나머지는 **영원히 안 뽑힌다** — 데이터도 사전 크기도 그것을 못 바꾼다.
//
// ══════════════════════════════════════════════════════════════════════════════
// 📌 **다음 — ⚠️ 여기서 멈추고 사람과 정한다**(이 회차에서 고르지 않는다)
// ══════════════════════════════════════════════════════════════════════════════
//   다음 자리는 *"죽은 유닛을 깨우는 기제"* 이고 그것은 **우리가 기제를 넣는 것**이다
//   ⇒ `mltconcept.md` 의 ㈀ 경고(*"`k` 가 작으면 우리가 비계를 만든 것"*)를 **정면으로** 다뤄야 한다.
//   ⚠️ 결과를 보고 기제를 고르면 그것이 사후 선택이다 ⇒ **후보를 적어 두고 등록은 다음 회차에** 한다.

using namespace PE;

class MLTP2N
{
public:
	static void Tick(RHI* rhi)
	{
		if (_arm >= kArms || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltp2n"))
		{
			LogA("[mlt] 🗄️ 걸음 6(`N` 스윕)는 **꺼져 있다**(`-mltp2n`) — 회차 25 기록: 시험 **0.04255 /"
			     " 0.04105 / 0.04272**(N=250/1000/1999 · 추세 없음) · ⭐ 사용률 **31.8 → 38.8 → 35.8**"
			     " (`N` 8배에 **1.12배**) ⇒ **사전 등록한 예측 ㈀ 확정: 병목은 top-k 동역학**\n");
			_arm = kArms;
			return;
		}
		if (!_banner) { _Banner(); _banner = true; }
		if (_st == kInit)  { _BeginSeed(rhi); return; }
		if (_st == kTrain) { _Train();        return; }
		if (_st == kEval)  { _Eval();         return; }
	}

	static bool Done() { return _arm >= kArms; }

private:
	static constexpr uint32 kArms = 3u;
	static constexpr uint32 kNs[kArms] = { 250u, 1000u, 1999u };   // 회차 19 의 `{U/8, U/2, U}`
	static constexpr uint32 kSeeds = 12u;
	static constexpr uint32 kTrainF = 128u, kTestF = 8u;           // 회차 24 의 가운데 팔
	static constexpr uint32 kPoolCap = kTrainF + kTestF;
	static constexpr uint32 kSteps = 4800u;                        // 에폭 37.5 (회차 24 와 같다)
	static constexpr uint32 kK = 8u;
	static constexpr uint32 kPerTick = 4u, kEvalTr = 8u;
	static constexpr float  kHead = 0.01710f, kBeat = 0.5f;
	static constexpr float  kUseFrac = 0.01f, kRankTol = 1.0e-3f;
	static constexpr uint32 kSignPass = 11u;
	static constexpr uint32 kTestEpisode = 1u;
	static constexpr uint32 kWatchSeed = 10u;   // ⭐ 회차 24 의 부채(따로 본다)

	enum { kInit, kTrain, kEval };

	inline static MLTP2Enc _E;
	inline static bool   _banner = false;
	inline static uint32 _arm = 0u, _seed = 0u;
	inline static int    _st = kInit;
	inline static uint32 _step = 0u, _ev = 0u;
	inline static Array<float> _usage;
	inline static double _sumTest = 0.0, _sumTrain = 0.0;
	inline static uint32 _nTest = 0u, _nTrain = 0u;
	inline static float  _baseB = 0.0f;
	inline static uint32 _rank = 0u;
	inline static bool   _finite = true;

	inline static float  _test[kArms][kSeeds]  = { { 0.0f } };
	inline static float  _train[kArms][kSeeds] = { { 0.0f } };
	inline static uint32 _use[kArms][kSeeds]   = { { 0u } };
	inline static uint32 _rk[kArms][kSeeds]    = { { 0u } };
	inline static bool   _ok[kArms][kSeeds]    = { { false } };
	inline static bool   _worse[kArms][kSeeds] = { { false } };
	inline static float  _base[kArms][kSeeds]  = { { 0.0f } };

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🗄️👁️ **P2 걸음 6 · `N` 스윕** — 팔 %u × 씨앗 %u (k=%u · 학습 %u프레임 · %u스텝)\n",
			kArms, kSeeds, kK, kTrainF, kSteps);
		LogA("[mlt] 🗄️   팔: N = %u / %u / %u (회차 19 의 `{U/8, U/2, U}` · U=1999)"
		     " ⇒ `k·패치/N` = %.2f / %.2f / %.2f\n",
			kNs[0], kNs[1], kNs[2],
			(double)((float)(kK * MLTP2Cfg::kPatches) / (float)kNs[0]),
			(double)((float)(kK * MLTP2Cfg::kPatches) / (float)kNs[1]),
			(double)((float)(kK * MLTP2Cfg::kPatches) / (float)kNs[2]));
		LogA("[mlt] 🗄️   ⭐ 예측: ㈀ 사용률이 `N` 에 무관 = **top-k 동역학** · ㈁ 비례 = 붐빔 ·"
		     " ㈂ N=250 이 더 좋다 = 죽은 유닛이 해롭다\n");
		LogA("[mlt] 🗄️   ㉠ 표제 %.5f · 씨앗별 **%u/%u** · ⭐ **추세 통계 사전 등록**(완전 단조 · 귀무 1/6 · Q=2)\n",
			(double)kHead, kSignPass, kSeeds);
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

	static void _BeginSeed(RHI* rhi)
	{
		// ⚠️ `N` 이 파라미터 배치를 정하므로 **팔이 바뀌면 아레나를 다시 만든다**(씨앗마다는 아니다).
		if (_seed == 0u)
		{
			if (!_E.Setup(rhi, kPoolCap, kNs[_arm]))
			{ LogA("[mlt] 🗄️ 준비 실패(N=%u)\n", kNs[_arm]); _arm = kArms; return; }
		}
		else if (!_E.ResetSeed()) { LogA("[mlt] 🗄️ 되돌리기 실패\n"); _arm = kArms; return; }
		_E.SetK(kK);

		Array<float> fr, tg, testPatch;
		fr.Reset(0); tg.Reset(0); testPatch.Reset(0);
		ImageFormat::Bitmap bmp;
		Bytes packed;
		{
			MLTWorld w;
			w.Reset(_seed, 0u, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
			for (uint32 f = 0; f < kTrainF; ++f)
			{
				w.Step();
				if (!w.Render(bmp) || !MLTWorld::Pack(bmp, nullptr, packed))
				{ LogA("[mlt] 🗄️ Render/Pack 실패(학습)\n"); _arm = kArms; return; }
				MLTP2Enc::AppendFrame(fr, tg, (const uint8*)packed.GetData());
			}
		}
		{
			MLTWorld w;
			w.Reset(_seed, kTestEpisode, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
			for (uint32 f = 0; f < kTestF; ++f)
			{
				w.Step();
				if (!w.Render(bmp) || !MLTWorld::Pack(bmp, nullptr, packed))
				{ LogA("[mlt] 🗄️ Render/Pack 실패(시험)\n"); _arm = kArms; return; }
				const uint8* px = (const uint8*)packed.GetData();
				MLTP2Enc::AppendFrame(fr, tg, px);
				Array<float> one, dummy; one.Reset(0); dummy.Reset(0);
				MLTP2Enc::AppendFrame(dummy, one, px);
				for (uint32 i = 0; i < one.Count(); ++i) testPatch.Add(one[i]);
			}
		}
		if (!_E.WritePool(fr, tg, kTrainF + kTestF))
		{ LogA("[mlt] 🗄️ 풀 업로드 실패\n"); _arm = kArms; return; }

		_baseB = MLTP2Enc::PatchConstMse(testPatch);
		_rank  = MLTP2Enc::PatchRank(testPatch, kRankTol);

		_usage.Reset(0);
		for (uint32 i = 0; i < _E.N(); ++i) _usage.Add(0.0f);
		_step = 0u; _ev = 0u; _sumTest = 0.0; _sumTrain = 0.0; _nTest = 0u; _nTrain = 0u;
		_finite = true;
		_st = kTrain;
	}

	static void _Train()
	{
		for (uint32 i = 0; i < kPerTick && _step < kSteps; ++i)
		{
			_E.SetFrame(_step % kTrainF);
			if (!_E.Forward() || !_E.Backward() || !_E.AdamStep(1.0f))
			{ LogA("[mlt] 🗄️ 스텝 실패(N=%u 씨앗 %u 스텝 %u)\n", kNs[_arm], _seed, _step); _arm = kArms; return; }
			++_step;
		}
		if (_step >= kSteps) { _st = kEval; _ev = 0u; }
	}

	static void _Eval()
	{
		const uint32 nEv = kTestF + kEvalTr;
		if (_ev > 0u)
		{
			const uint32 prev = _ev - 1u;
			float m = 0.0f; bool fin = true;
			if (!_E.ReadMse(m, fin)) { LogA("[mlt] 🗄️ 평가 리드백 실패\n"); _arm = kArms; return; }
			if (!fin) _finite = false;
			if (prev < kTestF)
			{
				_sumTest += (double)m; ++_nTest;
				if (!_E.AccumUsage(_usage)) { LogA("[mlt] 🗄️ 사용률 리드백 실패\n"); _arm = kArms; return; }
			}
			else { _sumTrain += (double)m; ++_nTrain; }
		}
		if (_ev < nEv)
		{
			_E.SetFrame((_ev < kTestF) ? (kTrainF + _ev) : (_ev - kTestF));
			if (!_E.Forward()) { LogA("[mlt] 🗄️ 평가 forward 실패\n"); _arm = kArms; return; }
			++_ev;
			return;
		}
		_JudgeSeed();
	}

	static void _JudgeSeed()
	{
		const float mT = (_nTest  != 0u) ? (float)(_sumTest  / (double)_nTest)  : 0.0f;
		const float mR = (_nTrain != 0u) ? (float)(_sumTrain / (double)_nTrain) : 0.0f;
		float mx = 0.0f;
		for (uint32 i = 0; i < _E.N(); ++i) if (_usage[i] > mx) mx = _usage[i];
		uint32 use = 0u;
		if (mx > 0.0f) { const float th = kUseFrac * mx; for (uint32 i = 0; i < _E.N(); ++i) if (_usage[i] > th) ++use; }

		_test[_arm][_seed] = mT; _train[_arm][_seed] = mR; _base[_arm][_seed] = _baseB;
		_use[_arm][_seed] = use; _rk[_arm][_seed] = _rank;
		_ok[_arm][_seed] = (mT < kBeat * _baseB) && _finite;
		_worse[_arm][_seed] = (mT >= _baseB);

		LogA("[mlt] 🗄️ N=%4u [%2u/%u] 씨앗 %u — 시험 **%.5f** %s %.5f · 학습 %.5f · 사용률 **%u**(%.1f%% of N)/rank %u%s\n",
			kNs[_arm], _seed + 1u, kSeeds, _seed, (double)mT, _ok[_arm][_seed] ? "<" : "≥",
			(double)(kBeat * _baseB), (double)mR, use,
			(double)(100.0f * (float)use / (float)kNs[_arm]), _rank,
			_worse[_arm][_seed] ? " ⚠️대조군보다 나쁘다" : "");

		++_seed;
		if (_seed >= kSeeds)
		{
			_ArmSummary();
			_seed = 0u; ++_arm;
			if (_arm >= kArms) { _Summary(); _E.Destroy(); return; }
		}
		_st = kInit;
	}

	static void _ArmSummary()
	{
		double sT = 0.0, sR = 0.0; uint32 sign = 0u, sU = 0u, sK = 0u, worse = 0u;
		for (uint32 i = 0; i < kSeeds; ++i)
		{
			sT += (double)_test[_arm][i]; sR += (double)_train[_arm][i];
			sU += _use[_arm][i]; sK += _rk[_arm][i];
			if (_ok[_arm][i]) ++sign;
			if (_worse[_arm][i]) ++worse;
		}
		const float mT = (float)(sT / (double)kSeeds), mR = (float)(sR / (double)kSeeds);
		const float mU = (float)sU / (float)kSeeds;
		LogA("[mlt] 🗄️ ── 팔 N=%u ── 시험 **%.5f** · 학습 %.5f (비 **%.2f배**) · 부호검정 **%u/%u**"
		     " · 사용률 **%.1f**(%.1f%% of N · rank %.1f) · 대조군보다 나쁜 씨앗 **%u**\n",
			kNs[_arm], (double)mT, (double)mR, (double)((mR > 1e-9f) ? (mT / mR) : 0.0f),
			sign, kSeeds, (double)mU, (double)(100.0f * mU / (float)kNs[_arm]),
			(double)((float)sK / (float)kSeeds), worse);
		// ⭐ 회차 24 의 부채 — 그 씨앗을 따로 적는다
		LogA("[mlt] 🗄️    ⓘ 씨앗 %u(회차 24 의 튀는 씨앗) — 시험 %.5f · 대조군 %.5f · 사용률 %u\n",
			kWatchSeed, (double)_test[_arm][kWatchSeed], (double)_base[_arm][kWatchSeed],
			_use[_arm][kWatchSeed]);
	}

	// 단측 이항 꼬리 `P(X >= w)` (성공확률 `p0`). ⚠️ n=12 라 정확히 센다.
	static float _BinomP(uint32 w, uint32 n, float p0)
	{
		double tot = 0.0;
		for (uint32 i = w; i <= n; ++i)
		{
			double c = 1.0;
			for (uint32 j = 0; j < i; ++j) c = c * (double)(n - j) / (double)(j + 1u);
			tot += c * Pow(p0, (float)i) * Pow(1.0f - p0, (float)(n - i));
		}
		return (float)tot;
	}

	static void _Summary()
	{
		float mT[kArms] = { 0.0f }, mR[kArms] = { 0.0f }, mU[kArms] = { 0.0f };
		uint32 sign[kArms] = { 0u };
		for (uint32 a = 0; a < kArms; ++a)
		{
			double sT = 0.0, sR = 0.0; uint32 sU = 0u;
			for (uint32 i = 0; i < kSeeds; ++i)
			{ sT += (double)_test[a][i]; sR += (double)_train[a][i]; sU += _use[a][i]; if (_ok[a][i]) ++sign[a]; }
			mT[a] = (float)(sT / (double)kSeeds); mR[a] = (float)(sR / (double)kSeeds);
			mU[a] = (float)sU / (float)kSeeds;
		}

		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🗄️👁️ **`N` 스윕 결과**\n");
		for (uint32 a = 0; a < kArms; ++a)
			LogA("[mlt] 🗄️   N=%4u · 시험 **%.5f** · 학습 %.5f · 비 %.2f · 사용률 **%.1f**(%.1f%% of N)"
			     " · 부호검정 %u/%u · %s ㉠\n",
				kNs[a], (double)mT[a], (double)mR[a],
				(double)((mR[a] > 1e-9f) ? (mT[a] / mR[a]) : 0.0f),
				(double)mU[a], (double)(100.0f * mU[a] / (float)kNs[a]), sign[a], kSeeds,
				(mT[a] < kHead && sign[a] >= kSignPass) ? "✅" : "⛔");

		// ⭐ 쌍별(회차 23 부터의 통계) — 둘 다 본다
		LogA("[mlt] 🗄️   ── 쌍별 짝지은 부호검정(Q=3 보정선 0.0167) ──\n");
		for (uint32 a = 0; a < kArms; ++a)
			for (uint32 b = a + 1u; b < kArms; ++b)
			{
				uint32 w = 0u;
				for (uint32 i = 0; i < kSeeds; ++i) if (_test[b][i] < _test[a][i]) ++w;
				const float p = _BinomP((w >= kSeeds - w) ? w : (kSeeds - w), kSeeds, 0.5f);
				LogA("[mlt] 🗄️     N=%-4u vs N=%-4u → 뒤가 더 낮은 씨앗 **%u/%u** · p=%.5f %s\n",
					kNs[a], kNs[b], w, kSeeds, (double)p, (p < 0.0167f) ? "✅" : "⛔");
			}

		// ⭐ 추세(사전 등록) — 씨앗마다 세 값이 완전 단조인가. 귀무 1/6 · 양방향 Q=2 ⇒ 0.025
		uint32 dn = 0u, up = 0u, dnU = 0u, upU = 0u;
		for (uint32 i = 0; i < kSeeds; ++i)
		{
			if (_test[0][i] > _test[1][i] && _test[1][i] > _test[2][i]) ++dn;
			if (_test[0][i] < _test[1][i] && _test[1][i] < _test[2][i]) ++up;
			if (_use[0][i] < _use[1][i] && _use[1][i] < _use[2][i]) ++upU;
			if (_use[0][i] > _use[1][i] && _use[1][i] > _use[2][i]) ++dnU;
		}
		LogA("[mlt] 🗄️   ── ⭐ 추세 통계(**사전 등록** · 완전 단조 · 귀무 1/6 · Q=2 ⇒ p<0.025) ──\n");
		LogA("[mlt] 🗄️     시험 MSE: `N`↑ 이면 ↓ **%u/%u**(p=%.5f %s) · ↑ %u/%u(p=%.5f %s)\n",
			dn, kSeeds, (double)_BinomP(dn, kSeeds, 1.0f / 6.0f), (_BinomP(dn, kSeeds, 1.0f/6.0f) < 0.025f) ? "✅" : "⛔",
			up, kSeeds, (double)_BinomP(up, kSeeds, 1.0f / 6.0f), (_BinomP(up, kSeeds, 1.0f/6.0f) < 0.025f) ? "✅" : "⛔");
		LogA("[mlt] 🗄️     사용률: `N`↑ 이면 ↑ **%u/%u**(p=%.5f %s) · ↓ %u/%u\n",
			upU, kSeeds, (double)_BinomP(upU, kSeeds, 1.0f / 6.0f),
			(_BinomP(upU, kSeeds, 1.0f/6.0f) < 0.025f) ? "✅" : "⛔", dnU, kSeeds);

		// ⭐ 등록한 예측을 **그대로** 적용한다
		const float ratioU = (mU[0] > 1.0e-6f) ? (mU[2] / mU[0]) : 0.0f;   // N 8배 대비 사용률 배율
		const bool useFlat = (ratioU < 2.0f);            // 8배 늘렸는데 2배도 안 되면 「거의 무관」
		const bool smallBest = (mT[0] < mT[1] && mT[0] < mT[2]);
		const char* pred = smallBest
			? "㈂ **N=250 이 시험을 가장 잘한다** ⇒ 죽은 유닛이 해로웠다(붐비는 것이 낫다)"
			: (useFlat ? "㈀ **사용률이 `N` 에 거의 무관하다** ⇒ 병목은 사전 크기가 아니라 **top-k 동역학**"
			           : "㈁ 사용률이 `N` 에 따라 는다 ⇒ 사전이 작아서 붐볐던 것이다");
		LogA("[mlt] 🗄️   ⭐ 예측 판정 = **%s**\n", pred);
		LogA("[mlt] 🗄️     ⓘ `N` 을 **8배**(250→1999) 늘렸을 때 사용률 배율 = **%.2f배** (%.1f → %.1f)\n",
			(double)ratioU, (double)mU[0], (double)mU[2]);
		if (useFlat && !smallBest)
			LogA("[mlt] 🗄️     ⚠️ 다음 자리는 *\"죽은 유닛을 깨우는 기제\"* 이고 그것은 **우리가 기제를 넣는**"
			     " 것이다 ⇒ `mltconcept.md` 의 ㈀ 경고를 정면으로 다뤄야 한다\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}
};
