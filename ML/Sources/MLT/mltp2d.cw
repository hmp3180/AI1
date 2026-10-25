// mltp2d.cw — 📚👁️ **P2 걸음 5 · 「데이터를 더 준다」 스윕**(학습 프레임 수). 회차 23 이 가리킨 축이다.
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문** — ⚠️ 재기 **전에** 적는다.
// ══════════════════════════════════════════════════════════════════════════════
//
// ① **왜 학습 프레임인가** — 회차 23 이 「병목 = 일반화」를 못 박았다:
//    · 시험/학습 비가 `k` 와 **같이** 커졌다(1.77 → 1.99 → 2.04) ⇒ `k` 는 재구성을 좋게 하면서
//      **외우는 몫을 같이 키운다** ⇒ `k` 로는 ㉠ 이 안 고쳐진다.
//    · k=32 의 **학습**은 문턱의 **45%** 인데 **시험**은 **91%** 다.
//    ★ 일반화 격차의 가장 흔한 원인은 **데이터 부족**이고, 그것을 먼저 배제하지 않으면
//      정규화(지금 **`wd = 0`**)의 효과를 오독한다.
//    ★ 그리고 **이 프로젝트에서 프레임은 공짜다** — 세계가 무한히 낸다. 그것이 이 트랙의
//      근본 강점(*"라벨이 무한하고 정답이 있다"*)이고 **여기서 처음 쓰인다.**
//    ⇒ 팔 셋 **학습 프레임 {32, 128, 512}** · **`k = 8` 고정** · `N` = 1000 고정.
//
// ② ⭐ **`k = 8` 로 돌아가는 이유** — `k·패치/N = 0.51` 로 **희소성이 남는 팔**이다.
//    흔드는 축이 일반화이므로 **우리가 원하는 체제에서** 재야 한다. k=32 의 이득은 어차피
//    「희소성을 버린 값」이라 할인 대상이다(회차 23).
//
// ③ ⚠️⚠️ **시험 집합을 고쳤다 — 「다른 에피소드」다.** 회차 21·23 은 *같은 에피소드의 뒤 8프레임*을
//    시험으로 썼는데, 학습 프레임 수를 흔들면 그 규약이 **깨진다**:
//    · 학습 32 면 시험이 32~39, 학습 512 면 512~519 ⇒ **팔마다 시험 집합이 달라** 짝지은 비교가 무너진다.
//    · 시험을 512~519 로 고정하면 이번엔 **학습과 시험 사이 시간 거리**가 팔마다 달라진다(혼입).
//    ⇒ ⭐ **시험 = `episode 1` 의 프레임 0~7**(학습은 `episode 0`). 그러면 시험 집합이 팔마다
//      **글자 그대로 같고** 시간 거리도 같다(아예 다른 에피소드다).
//    ⚠️ 그래서 **회차 21·23 의 절대값과 직접 비교하지 않는다** — 이 회차 안의 팔 비교가 판정이다.
//      ★ 씨앗별 대조군(그 시험 패치의 패치상수 MSE)은 **여기서 다시 계산**하므로 ㉠ 은 여전히 뜻이 있다.
//
// ④ **스텝 = 에폭 고정**(37.5) ⇒ {1200, 4800, 19200}.
//    ⚠️ **혼입을 적는다**: 데이터 양과 **계산 양**이 같이 는다. 스텝을 고정하면 「프레임을 덜 본다」가
//    섞이므로 어느 쪽이든 혼입이고, 에폭 고정이 *"데이터를 더 주면 일반화가 좋아지나"* 의 정직한
//    형태다. ⇒ 로그가 **프레임 수와 스텝 수를 나란히** 찍는다.
//
// ⑤ **관문 ㉠ 은 그대로** — 표제 `MSE_시험 < 0.01710` · 씨앗별 부호검정(자기 대조군의 절반)
//    **11/12**(`Q = 3` 본페로니 · p=0.0032). ⚠️ **고치지 않는다.**
//
// ⑥ ⭐ **팔 비교는 「짝지은 부호검정」이다 — 이번엔 사전 등록이다.**
//    회차 23 에서 「평균 ± 독립 표준오차」가 **판정불가**를 냈는데 짝지으면 12/12 였다(씨앗이 팔마다
//    같은 짝지은 설계인데 짝짓기를 버린 것이 일탈이었다). ⇒ 쌍 셋 · `Q = 3` ⇒ 단측 p < **0.0167**.
//
// ⑦ ⭐ **갈래 셋을 미리 등록한다** — ★ 판정의 핵은 **시험/학습 비**다(시험 MSE 하나로는 못 가른다):
//    ```
//    ㈀ 프레임↑ ⇒ 시험 MSE↓ **그리고 시험/학습 비도 ↓**  ⇒ **병목은 데이터였다**(그리고 더 주면 된다)
//    ㈁ 프레임↑ ⇒ 시험 MSE↓ 인데 **비는 안 줄거나 커진다** ⇒ 데이터가 아니라 다른 것이다
//                                                          (다음 = 정규화 `wd` · 초기화 · 배치)
//    ㈂ 프레임↑ 인데 **시험 MSE 가 안 낮아진다**            ⇒ 데이터가 아니다 ⇒ 곧바로 정규화로 간다
//    ```
//    ⚠️ ㈀ 이어도 *"그래서 프레임을 무한히 준다"* 로 끝내지 않는다 — **얼마나 주면 문턱을 넘나**가
//      다음 질문이고, 그것은 이 세 점의 기울기가 답한다.
//
// ⑧ ⚠️ 값 — 아레나가 는다(풀 520프레임 ≈ +34MB) · 19,200 스텝 팔이 씨앗당 ~36초
//    ⇒ 회차 전체 **십 분 대**. `k=8` 이라 프레임당 멈춤이 작다(2.3초짜리 팔은 없다).
//
// ══════════════════════════════════════════════════════════════════════════════
// 🧾 **결과(회차 24)** — ⚠️ ㉠ 은 셋 다 ⛔. 그런데 **제일 큰 것은 다른 데서 나왔다.**
// ══════════════════════════════════════════════════════════════════════════════
//   | F | 스텝 | 시험 | 대조군 | 학습 | 비 | 부호검정 | 사용률/rank | 대조군보다 나쁨 |
//   |---|---|---|---|---|---|---|---|---|
//   | 32  | 1200  | 0.04868 | 0.03198 | 0.01192 | **4.09** | 0/12 | 33.6/151.2 | 6 |
//   | 128 | 4800  | 0.04105 | 0.03198 | 0.01264 | **3.25** | 0/12 | 38.8/151.2 | 3 |
//   | 512 | 19200 | **0.03979** | 0.03198 | 0.01330 | **2.99** | 3/12 | 42.2/151.2 | 5 |
//
// ★ **㉠ 이 아니라 이것이 이 회차의 결과다 — 회차 21·23 의 시험 집합이 「새고」 있었다.**
//   같은 `k=8`·같은 학습(에피소드 0 프레임 0~31 · 1200 스텝)에서 **시험 집합만** 바꿨다:
//   ```
//   시험 = 같은 에피소드 뒤 8프레임 (회차 21·23) : 시험 0.02107 · 대조군 0.03137 · 학습 0.01192
//   시험 = **다른 에피소드** 0~7   (이 회차)      : 시험 0.04868 · 대조군 0.03198 · 학습 0.01192
//   ```
//   ⇒ 시험 MSE 가 **2.31배** 나빠졌는데 **대조군은 1.02배**(난이도가 같다)이고 **학습은 동일**하다.
//   ⚠️⚠️ 그러므로 *"시험이 더 어려워서"* 가 아니라 **전이가 안 되는 것**이다. 같은 에피소드의 뒤
//     프레임은 **같은 도형·같은 색**을 담고 있어서(`hold` 가 천천히 바뀐다) 그 시험은 사실상
//     **같은 내용의 계속**이었다. ⇒ 회차 21·23 의 「일반화」 해석은 **그만큼 약해진다**(수치는 유효하다).
//   ★ 이것이 **통제된 비교**다: 학습이 비트 동일하고 대조군이 같다.
//
//   ⚠️ **등록한 판정과 사후 통계가 갈렸다 — 적어 둔다**:
//     · 등록(쌍별 부호검정 + `Q=3`): 세 쌍 모두 **10/12**(p=0.0193 > 0.0167) ⇒ 자동 판정 **㈂**.
//     · ⭐ 사후 **추세** 통계: 씨앗마다 `F=32 > F=128 > F=512` 가 **완전 단조**인 씨앗이 **8/12**
//       (귀무 1/6 ⇒ 단측 p = **0.00016**) · F=512 가 최저인 씨앗 **10/12**.
//     ⇒ 종합하면 **㈁** 이다: 데이터는 확실히 돕고 비도 줄지만(4.09→2.99) **턱없이 느리다**
//       (16배 데이터로 시험 18% 개선 · 문턱까지 2.3배가 더 필요하다).
//     ⚠️ **등록의 결함**: 쌍별 보정은 **추세를 못 본다**(회차 18 에서 밟은 「갈래가 거칠다」의 재발).
//       ⇒ **다음 등록부터 추세 통계를 사전 등록한다**(3팔 완전 단조 · 귀무 1/6).
//
//   ⚠️ **부채**: 씨앗 10 은 시험 MSE 가 **0.2266 → 0.2179** 로 통째로 다른 체제다(대조군의 7배).
//     한 씨앗이 그렇게 튀면 평균이 거짓말을 한다 ⇒ 다음 회차에서 **그 씨앗을 따로** 본다.
//
// ══════════════════════════════════════════════════════════════════════════════
// 📌 **걸음 6 등록 — `N` 스윕**(회차 19 가 이미 등록한 축) ⚠️ ㈂ 갈래가 가리킨 `wd` 보다 먼저다
// ══════════════════════════════════════════════════════════════════════════════
//   · 팔 셋 **`N ∈ {250, 1000, 1999}`** · `k = 8` · **학습 프레임 128 고정** · 시험은 이 회차와 같다.
//   · ⚠️ **갈래가 가리킨 것은 `wd` 였다 — 그것을 먼저 하지 않는 이유를 적는다**(대기열에 남긴다):
//     ⭐ 이 회차가 새 사실을 하나 더 냈다 — **사용률이 데이터 16배에도 33.6 → 42.2 뿐**이다
//     (rank 151 의 28%). 그리고 회차 23 에서 사용률이 오른 유일한 길은 `k` 를 키우는 것이었는데
//     그건 *"패치마다 더 많이 쓴다"* 이지 *"사전이 깨어난다"* 가 아니다.
//     ⇒ 병목은 **죽은 유닛**(top-k 승자독식)이고, `wd` 는 죽은 행을 0 으로 밀 뿐 **깨우지 못한다.**
//   · ⭐ **예측을 미리 적는다**(이것이 이 회차의 핵이다):
//     ```
//     사용률이 `N` 에 거의 무관하다(≈40)  ⇒ 병목은 **사전 크기가 아니라 top-k 동역학**이다
//     사용률이 `N` 에 비례해 늘어난다      ⇒ 사전이 작아서 붐빈 것이었다(그러면 N 을 키운다)
//     N=250 이 시험을 **더 잘** 한다       ⇒ 죽은 유닛이 해로웠다(붐비는 것이 낫다)
//     ```
//   · 관문은 ㉠ 그대로(0.01710 · 씨앗별 11/12) + ⭐ **추세 통계 사전 등록**(완전 단조 · 귀무 1/6).
//   · ⚠️ 값 — `N=1999` 는 `vis_recon_bwd_tab` 의 스레드가 2배(384,000)라 팔 하나가 F=128 에서
//     씨앗당 ~20초 ⇒ 회차 전체 **십 분 안**.

using namespace PE;

class MLTP2D
{
public:
	static void Tick(RHI* rhi)
	{
		if (_arm >= kArms || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltp2d"))
		{
			LogA("[mlt] 📚 걸음 5(데이터 스윕)는 **꺼져 있다**(`-mltp2d`) — 회차 24 기록: 시험 **0.04868 /"
			     " 0.04105 / 0.03979**(F=32/128/512) · ㉠ 셋 다 ⛔ · 비 4.09→3.25→2.99 ·"
			     " ⭐ **회차 21·23 의 시험 집합이 새고 있었다**(같은 학습에서 2.31배)\n");
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
	static constexpr uint32 kArms  = 3u;
	static constexpr uint32 kTrainF[kArms] = { 32u, 128u, 512u };   // 등록한 팔
	static constexpr uint32 kEpochs = 375u;                          // 37.5 (×10 정수)
	static constexpr uint32 kSeeds = 12u;
	static constexpr uint32 kTestF = 8u;
	static constexpr uint32 kPoolCap = 512u + kTestF;                // 아레나가 담을 프레임
	static constexpr uint32 kK = 8u;                                 // ⭐ 고정(희소성이 남는 팔)
	static constexpr uint32 kPerTick = 4u;
	static constexpr uint32 kEvalTr = 8u;
	static constexpr float  kHead = 0.01710f, kBeat = 0.5f;
	static constexpr float  kUseFrac = 0.01f, kRankTol = 1.0e-3f;
	static constexpr uint32 kSignPass = 11u;   // Q=3 보정
	static constexpr uint32 kTestEpisode = 1u; // ⭐ 시험은 **다른 에피소드**다(등록문 ③)

	enum { kInit, kTrain, kEval };

	inline static MLTP2Enc _E;
	inline static bool   _banner = false, _setup = false;
	inline static uint32 _arm = 0u, _seed = 0u;
	inline static int    _st = kInit;
	inline static uint32 _step = 0u, _ev = 0u, _steps = 0u;
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

	static uint32 _Steps(uint32 arm) { return kTrainF[arm] * kEpochs / 10u; }

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 📚👁️ **P2 걸음 5 · 「데이터를 더 준다」** — 팔 %u × 씨앗 %u (k=%u·N=%u 고정)\n",
			kArms, kSeeds, kK, MLTP2Cfg::kN);
		LogA("[mlt] 📚   팔: 학습 프레임 %u / %u / %u · 스텝 %u / %u / %u (**에폭 고정 %.1f**)\n",
			kTrainF[0], kTrainF[1], kTrainF[2], _Steps(0), _Steps(1), _Steps(2),
			(double)((float)kEpochs / 10.0f));
		LogA("[mlt] 📚   ⚠️ 데이터 양과 **계산 양**이 같이 는다(등록문 ④ 의 그 혼입) — 둘 다 적는다\n");
		LogA("[mlt] 📚   ⭐ 시험 = **에피소드 %u 의 프레임 0~%u** (팔마다 **글자 그대로 같다**)\n",
			kTestEpisode, kTestF - 1u);
		LogA("[mlt] 📚   ㉠ 표제 %.5f · 씨앗별 부호검정 **%u/%u** · 팔 비교는 ⭐ **짝지은** 부호검정(사전 등록)\n",
			(double)kHead, kSignPass, kSeeds);
		LogA("[mlt] 📚   갈래: ㈀ 비도 ↓ = **병목은 데이터** · ㈁ 비가 안 줄면 = 다른 것 · ㈂ MSE 가 안 줄면 = 정규화로\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

	static void _BeginSeed(RHI* rhi)
	{
		typedef MLTP2Cfg C;
		if (!_setup)
		{
			// ⭐ 풀 상한을 **가장 큰 팔** 기준으로 한 번만 잡는다(아레나는 다시 만들지 않는다).
			if (!_E.Setup(rhi, kPoolCap)) { LogA("[mlt] 📚 준비 실패\n"); _arm = kArms; return; }
			_setup = true;
		}
		else if (!_E.ResetSeed()) { LogA("[mlt] 📚 되돌리기 실패\n"); _arm = kArms; return; }
		_E.SetK(kK);

		const uint32 tf = kTrainF[_arm];
		Array<float> fr, tg, testPatch;
		fr.Reset(0); tg.Reset(0); testPatch.Reset(0);
		ImageFormat::Bitmap bmp;
		Bytes packed;

		// ── 학습: 에피소드 0 의 프레임 0..tf-1 ──────────────────────
		{
			MLTWorld w;
			w.Reset(_seed, 0u, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
			for (uint32 f = 0; f < tf; ++f)
			{
				w.Step();
				if (!w.Render(bmp) || !MLTWorld::Pack(bmp, nullptr, packed))
				{ LogA("[mlt] 📚 Render/Pack 실패(학습)\n"); _arm = kArms; return; }
				MLTP2Enc::AppendFrame(fr, tg, (const uint8*)packed.GetData());
			}
		}
		// ── 시험: **다른 에피소드**의 프레임 0..7 (등록문 ③) ────────
		{
			MLTWorld w;
			w.Reset(_seed, kTestEpisode, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
			for (uint32 f = 0; f < kTestF; ++f)
			{
				w.Step();
				if (!w.Render(bmp) || !MLTWorld::Pack(bmp, nullptr, packed))
				{ LogA("[mlt] 📚 Render/Pack 실패(시험)\n"); _arm = kArms; return; }
				const uint8* px = (const uint8*)packed.GetData();
				MLTP2Enc::AppendFrame(fr, tg, px);
				// ★ 대조군·랭크는 **같은 배열**을 본다(어긋날 수 없다)
				Array<float> one, dummy; one.Reset(0); dummy.Reset(0);
				MLTP2Enc::AppendFrame(dummy, one, px);
				for (uint32 i = 0; i < one.Count(); ++i) testPatch.Add(one[i]);
			}
		}
		if (!_E.WritePool(fr, tg, tf + kTestF))
		{ LogA("[mlt] 📚 풀 업로드 실패(%u프레임)\n", tf + kTestF); _arm = kArms; return; }

		_baseB = MLTP2Enc::PatchConstMse(testPatch);
		_rank  = MLTP2Enc::PatchRank(testPatch, kRankTol);

		_usage.Reset(0);
		for (uint32 i = 0; i < _E.N(); ++i) _usage.Add(0.0f);
		_step = 0u; _ev = 0u; _steps = _Steps(_arm);
		_sumTest = 0.0; _sumTrain = 0.0; _nTest = 0u; _nTrain = 0u; _finite = true;
		_st = kTrain;
	}

	static void _Train()
	{
		const uint32 tf = kTrainF[_arm];
		for (uint32 i = 0; i < kPerTick && _step < _steps; ++i)
		{
			_E.SetFrame(_step % tf);
			if (!_E.Forward() || !_E.Backward() || !_E.AdamStep(1.0f))
			{ LogA("[mlt] 📚 스텝 실패(팔 %u 씨앗 %u 스텝 %u)\n", _arm, _seed, _step); _arm = kArms; return; }
			++_step;
		}
		if (_step >= _steps) { _st = kEval; _ev = 0u; }
	}

	static void _Eval()
	{
		const uint32 tf = kTrainF[_arm];
		const uint32 nEv = kTestF + kEvalTr;
		if (_ev > 0u)
		{
			const uint32 prev = _ev - 1u;
			float m = 0.0f; bool fin = true;
			if (!_E.ReadMse(m, fin)) { LogA("[mlt] 📚 평가 리드백 실패\n"); _arm = kArms; return; }
			if (!fin) _finite = false;
			if (prev < kTestF)
			{
				_sumTest += (double)m; ++_nTest;
				if (!_E.AccumUsage(_usage)) { LogA("[mlt] 📚 사용률 리드백 실패\n"); _arm = kArms; return; }
			}
			else { _sumTrain += (double)m; ++_nTrain; }
		}
		if (_ev < nEv)
		{
			// ★ 시험 프레임은 풀에서 **학습 뒤**에 놓여 있다(`tf + i`)
			_E.SetFrame((_ev < kTestF) ? (tf + _ev) : (_ev - kTestF));
			if (!_E.Forward()) { LogA("[mlt] 📚 평가 forward 실패\n"); _arm = kArms; return; }
			++_ev;
			return;
		}
		_JudgeSeed();
	}

	static void _JudgeSeed()
	{
		typedef MLTP2Cfg C;
		const float mT = (_nTest  != 0u) ? (float)(_sumTest  / (double)_nTest)  : 0.0f;
		const float mR = (_nTrain != 0u) ? (float)(_sumTrain / (double)_nTrain) : 0.0f;
		float mx = 0.0f;
		for (uint32 i = 0; i < _E.N(); ++i) if (_usage[i] > mx) mx = _usage[i];
		uint32 use = 0u;
		if (mx > 0.0f) { const float th = kUseFrac * mx; for (uint32 i = 0; i < _E.N(); ++i) if (_usage[i] > th) ++use; }

		_test[_arm][_seed] = mT; _train[_arm][_seed] = mR;
		_use[_arm][_seed] = use; _rk[_arm][_seed] = _rank;
		_ok[_arm][_seed] = (mT < kBeat * _baseB) && _finite;
		_worse[_arm][_seed] = (mT >= _baseB);

		LogA("[mlt] 📚 F=%3u [%2u/%u] 씨앗 %u — 시험 **%.5f** %s %.5f · 학습 %.5f · 사용률 **%u**/rank %u%s\n",
			kTrainF[_arm], _seed + 1u, kSeeds, _seed, (double)mT, _ok[_arm][_seed] ? "<" : "≥",
			(double)(kBeat * _baseB), (double)mR, use, _rank,
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
		LogA("[mlt] 📚 ── 팔 F=%u(스텝 %u) ── 시험 **%.5f** · 학습 %.5f (시험/학습 **%.2f배**)"
		     " · 부호검정 **%u/%u** · 사용률 %.1f/rank %.1f · 대조군보다 나쁜 씨앗 **%u**\n",
			kTrainF[_arm], _Steps(_arm), (double)mT, (double)mR,
			(double)((mR > 1e-9f) ? (mT / mR) : 0.0f), sign, kSeeds,
			(double)((float)sU / (float)kSeeds), (double)((float)sK / (float)kSeeds), worse);
	}

	// 단측 이항 꼬리 `P(X >= w)`(p=0.5). ⚠️ n=12 라 정확히 센다.
	static float _BinomP(uint32 w, uint32 n)
	{
		double tot = 0.0;
		for (uint32 i = w; i <= n; ++i)
		{
			double c = 1.0;
			for (uint32 j = 0; j < i; ++j) c = c * (double)(n - j) / (double)(j + 1u);
			tot += c;
		}
		return (float)(tot / Pow(2.0f, (float)n));
	}

	static void _Summary()
	{
		float mT[kArms] = { 0.0f }, mR[kArms] = { 0.0f }, ratio[kArms] = { 0.0f };
		uint32 sign[kArms] = { 0u };
		for (uint32 a = 0; a < kArms; ++a)
		{
			double sT = 0.0, sR = 0.0;
			for (uint32 i = 0; i < kSeeds; ++i)
			{ sT += (double)_test[a][i]; sR += (double)_train[a][i]; if (_ok[a][i]) ++sign[a]; }
			mT[a] = (float)(sT / (double)kSeeds); mR[a] = (float)(sR / (double)kSeeds);
			ratio[a] = (mR[a] > 1.0e-9f) ? (mT[a] / mR[a]) : 0.0f;
		}

		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 📚👁️ **「데이터를 더 준다」 스윕 결과**\n");
		for (uint32 a = 0; a < kArms; ++a)
			LogA("[mlt] 📚   F=%3u(스텝 %5u) · 시험 **%.5f** · 학습 %.5f · **비 %.2f배** · 부호검정 %u/%u · %s ㉠\n",
				kTrainF[a], _Steps(a), (double)mT[a], (double)mR[a], (double)ratio[a], sign[a], kSeeds,
				(mT[a] < kHead && sign[a] >= kSignPass) ? "✅" : "⛔");

		// ⭐ 사전 등록된 통계 — 짝지은 부호검정(팔 쌍마다)
		LogA("[mlt] 📚   ── ⭐ 짝지은 부호검정(같은 씨앗끼리 · **사전 등록**) ──\n");
		bool down[kArms][kArms] = { { false } };
		for (uint32 a = 0; a < kArms; ++a)
			for (uint32 b = a + 1u; b < kArms; ++b)
			{
				uint32 w = 0u;
				for (uint32 i = 0; i < kSeeds; ++i) if (_test[b][i] < _test[a][i]) ++w;
				const float p = _BinomP((w >= kSeeds - w) ? w : (kSeeds - w), kSeeds);
				down[a][b] = (w * 2u > kSeeds) && (p < 0.0167f);
				LogA("[mlt] 📚     F=%-3u vs F=%-3u → 뒤가 더 낮은 씨앗 **%u/%u** · 단측 p=%.5f %s\n",
					kTrainF[a], kTrainF[b], w, kSeeds, (double)p, (p < 0.0167f) ? "✅" : "⛔");
			}

		// ⭐ 등록한 갈래를 **그대로** 적용한다 — 핵은 **시험/학습 비**다
		const bool mseDown = down[0][2];                       // 시험 MSE 가 확실히 낮아졌나
		const bool ratioDown = (ratio[2] < ratio[0]);          // 비가 줄었나
		const char* branch = !mseDown
			? "㈂ 시험 MSE 가 안 낮아졌다 ⇒ **데이터가 아니다** ⇒ 다음은 정규화(`wd`)"
			: (ratioDown ? "㈀ MSE↓ **그리고 비↓** ⇒ **병목은 데이터였다**"
			             : "㈁ MSE↓ 인데 **비가 안 줄었다** ⇒ 데이터가 아니라 다른 것이다");
		LogA("[mlt] 📚   ⭐ 갈래 판정 = **%s**\n", branch);
		LogA("[mlt] 📚   ⓘ 시험/학습 비: %.2f → %.2f → %.2f (F=%u→%u→%u)\n",
			(double)ratio[0], (double)ratio[1], (double)ratio[2],
			kTrainF[0], kTrainF[1], kTrainF[2]);
		LogA("[mlt] 📚   ⚠️ 데이터 양과 계산 양이 같이 늘었다(등록문 ④) — 이 결과를 「데이터만의 효과」로 읽지 마라\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}
};
