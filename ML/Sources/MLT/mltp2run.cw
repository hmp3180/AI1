// mltp2run.cw — 🏁👁️ **P2 판정 라운드 · ㉠ 재구성 · ㉡ 사전 사용률** (걸음 3)
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문** — ⚠️ 재기 **전에** 적는다. 아래 수를 보고 나서 고치면 판정이 아니다.
// ══════════════════════════════════════════════════════════════════════════════
//
// ① **과제** — 씨앗마다 한 에피소드를 40스텝 굴려 프레임 40장을 얻는다.
//    · **학습 = 프레임 0~31**(32장) · **시험 = 프레임 32~39**(8장) ⇒ ⭐ **뒤에 오는 프레임**이다.
//    ⚠️ 시험을 「같은 프레임」으로 두면 판정 ③ 과 같은 것이 되고 *"외웠다"* 와 *"인코딩했다"* 가
//      갈리지 않는다. ⇒ **시간으로 가른다**(같은 에피소드의 뒤쪽 = 못 본 배치).
//    ★ 학습은 32장을 **돌려가며** 1200 스텝(≈ 37.5 에폭).
//    ⚠️ 프레임 업로드는 **씨앗마다 한 번**(풀) — `Write` 는 동기이고 무겁다(P0 의 40배 함정).
//    ⭐ 그리고 **한 렌더 프레임에 8 스텝**을 돌린다. 근거: 학습 스텝은 **되읽기가 필요 없고**
//      같은 프레임 안에서도 배리어가 걸린다(판정 ③ 이 이미 fwd+bwd+adam 을 한 프레임에 돌린다).
//      ⇒ 곡선은 8 스텝마다 표본된다(그 사실을 로그가 찍는다).
//
// ② **관문 ㉠ — 재구성**
//    · **표제**: 12 씨앗 평균 **시험** MSE `< 0.01710`(= A단계가 고른 문턱 B 0.03420 의 절반).
//    · **부호검정 10/12** — ⚠️ **씨앗마다 자기 대조군**을 쓴다: 그 씨앗의 **시험 프레임**에서
//      계산한 **패치-상수 MSE**(CPU 가 정확값으로 낸다). 씨앗 하나가 통과 = `MSE_시험 < 0.5 · 그 값`.
//      ★ 코퍼스 평균 하나로 부호검정을 하면 그것은 부호검정이 아니다(P0/P1 에서 밟은 자리).
//    · ⓘ **학습 MSE 도 같이** 찍는다(학습 프레임 8장) — 시험과의 차이가 「외운 몫」이다. 관문 아님.
//
// ③ **관문 ㉡ — 사전 사용률** ⭐ 문턱을 **원리에서** 뽑는다(임의 절대수를 박지 않는다)
//    · **정의**(등록문 그대로): 유닛 `n` 이 쓰였다 = 시험 프레임 전체에서 `Σ|mag|` 이
//      **최댓값의 1%** 를 넘는다. ⚠️ **절대값**으로 센다 — `mag` 는 점수라 음수가 될 수 있고
//      부호가 섞이면 상쇄로 「안 쓴 것」처럼 보인다.
//    · ⭐ **문턱 = `rank(시험 패치들)`** — 그 씨앗의 시험 패치 512개(8프레임 × 64)를 192차원
//      벡터로 보고 **차원(랭크)**을 센다(수정 그램-슈미트 · 상대 문턱 1e-3).
//      ★ **왜 이것이 임의가 아닌가**: 패치가 `k=8` 개 유닛의 **선형결합**으로 만들어지므로,
//        모든 시험 패치를 오차 0 으로 만들려면 쓰인 유닛들이 그 패치들의 **부분공간을 펼쳐야** 한다
//        ⇒ `사용률 ≥ rank` 는 **수학적 필요조건**이다. 「바이트 종류의 함수」라는 등록도 만족한다
//        (랭크는 바이트 종류와 도형이 함께 정한다).
//      ⚠️⚠️ 단 ㉠ 의 문턱은 **오차 0 이 아니다** ⇒ 이 문턱은 **엄격한 쪽**이다. 그래서 갈래를 셋으로
//        미리 등록한다(아래). 그러면 「엄격해서 떨어진 것」과 「붕괴」가 섞이지 않는다.
//    ```
//    사용률 ≥ rank        ⇒ ✅ 표현할 수 있는 만큼 쓴다
//    k < 사용률 < rank    ⇒ ⚠️ **부분** — 완벽 재구성은 원리적으로 불가. ㉠ 과 **함께** 읽는다
//    사용률 ≤ k (= 8)     ⇒ ⛔ **붕괴** — 패치 하나가 사전 전부를 쓸 수 있다 = 패치 간 구별이 없다
//    ```
//    · ⚠️ 회차 20 의 부채를 여기서 갚는다: 프레임 **하나**를 외울 때 활성 종류가 108 → 49 로
//      **좁아졌다**. 그것이 여러 프레임에서도 그러면 붕괴 쪽이다.
//
// ④ **㉣(`k`·`N` 스윕 봉우리)는 이 회차에 넣지 않는다** — ⚠️ 조용히 줄이는 것이 아니라 **근거를 적는다**:
//    · 스윕이 `3 × 3 = 9` 팔 × 12 씨앗이라 ㉠㉡ 과 섞으면 **캔버스가 둘**이 된다(규율 6).
//    · 그리고 **㉠ 이 통과한 뒤에만 뜻이 있다** — 문턱을 넘지도 못하는데 봉우리를 찾는 것은
//      「크기로 밀기」의 반대쪽 실수다. ⇒ 걸음 4 로 등록한다.
//    · ㉢(활성이 물체를 가르나)은 **색 대조군과 함께 별 회차**다(회차 19 가 등록했다).
//
// ⑤ **다중비교 `Q`** — 이 회차의 표제 판정은 **둘**(㉠·㉡) ⇒ `Q = 2`.
//    부호검정 10/12 의 단측 p = `(66+12+1)/4096 = 0.0193` < `0.05/2 = 0.025` ✅ (본페로니 통과).
//    ⚠️ ⓘ 로 찍는 것(학습 MSE · 활성 종류)은 **판정이 아니므로 세지 않는다.**
//
// ══════════════════════════════════════════════════════════════════════════════
// 🧾 **결과(회차 21) — ⛔ 실패다. 문턱을 고치지 않았다.**
// ══════════════════════════════════════════════════════════════════════════════
//   · ㉠-표제 **0.02107** ≥ 0.01710 ⛔ · ㉠-부호검정 **6/12**(필요 10) ⛔
//   · ㉡ 사용률 평균 **35.1** / rank 평균 **151.8** ⇒ 12/12 가 **⚠️ 부분**(붕괴 0 · 완전 0)
//   · ⓘ **학습** MSE 평균 **0.01192** — ⭐ **학습으로 재면 문턱을 넘는다**(0.01192 < 0.01710)
//     ⇒ 이 회차가 떨어진 것은 **배선이 아니라 일반화**다(조립 검사는 이미 통과했다).
//     시험/학습 = **1.77배**.
//   · ⚠️⚠️ **씨앗 둘(7·8)은 대조군보다도 나빴다**(0.0652 ↔ 0.0336 · 0.0357 ↔ 0.0334)
//     ⇒ 「덜 배웠다」가 아니라 **못 본 패치에서 크게 틀린다**.
//
//   ⭐ **실패의 얼굴이 둘로 갈린다**(같은 원인의 두 모습이다):
//   ```
//   ㈀ 과적합형  씨앗 7·8·11  학습 ≪ 시험 (7.1배 · 4.8배 · 2.4배)  ← 적은 유닛에 큰 세기
//   ㈁ 미달형    씨앗 3·9·10  학습 ≈ 시험, 둘 다 문턱 위            ← 표현력이 모자라다
//   ```
//   ★ 둘 다 **사용률이 23~47** 이다. ⇒ 「적은 유닛」 하나가 두 얼굴을 낸다:
//     세기를 키우면 학습 프레임은 맞추지만 못 본 패치에서 크게 틀리고(㈀), 못 키우면 학습도 못 맞춘다(㈁).
//   ⚠️ 그리고 회차 20 이 적어 둔 **부채 둘이 그대로 실현됐다**(활성 종류 108→49 · `|mag|` 37배).
//
// ══════════════════════════════════════════════════════════════════════════════
// 📌 **걸음 4 등록 — `k` 를 먼저 흔든다**(재기 전에 적는다)
// ══════════════════════════════════════════════════════════════════════════════
//   · 팔 셋: **`k ∈ {8, 32, 128}`** · `N` 은 1000 고정.
//   · ⭐ **왜 `k` 가 먼저인가**: 사용률(35) ≪ rank(152) 는 병목이 **패치 하나가 쓸 수 있는 유닛 수**
//     임을 가리킨다. `N` 은 이미 1000 인데 **35개만 쓰인다** ⇒ `N` 을 늘리면 죽은 유닛만 는다.
//     ★ 그리고 `k` 는 **패치가 펼칠 수 있는 부분공간의 차원**을 곧바로 올린다(㉡ 문턱의 그 논리).
//   · 관문: ㉠ 을 그대로 다시 잰다(문턱 **0.01710** · 부호검정 **10/12** — ⚠️ **고치지 않는다**).
//   · ⭐ 그리고 **봉우리**를 본다 — `k` 를 키우면 계속 좋아지는지(= 「크기로 밀기」) 아니면
//     중간에서 가장 좋은지. ⚠️ 계속 좋아지면 그것은 손잡이가 아니라 **용량**이고, 그때 볼 것은
//     `mltconcept.md` 의 ㈀ 경고(*"`k` 가 크면 희소성이 뜻을 잃는다"*)다.
//   · ⭐ 진단 채널을 **같이** 찍는다(관문 아님): 사용률 · 시험/학습 비 · 대조군보다 나쁜 씨앗 수.
//   · ⚠️ `N` 스윕({250, 1000, 1999})은 그 **뒤**다 — 한 회차에 축 둘을 흔들면 원인이 안 갈린다.

using namespace PE;

class MLTP2Run
{
public:
	static void Tick(RHI* rhi)
	{
		if (_seed >= kSeeds || rhi == nullptr) return;
		// ⚠️ **기본에서 껐다** — 회차 21 로 돌았고 **⛔ 로 끝났다**(문턱을 고치지 않았다).
		//   ★ 다시 돌리려면 `-mltp2run`.
		if (!OS::CommandLine::Has("-mltp2run"))
		{
			LogA("[mlt] 🏁 P2 판정 라운드는 **꺼져 있다**(`-mltp2run`) — 회차 21 기록: ⛔ 시험 MSE 평균"
			     " **0.02107** ≥ 0.01710 · 부호검정 **6/12** · 사용률 **35.1** ≪ rank **151.8**(⚠️부분 12/12)\n");
			_seed = kSeeds;
			return;
		}
		if (!_banner)
		{
			_Banner(); _banner = true;
		}
		if (_st == kInit)  { _BeginSeed(rhi); return; }
		if (_st == kTrain) { _Train();        return; }
		if (_st == kEval)  { _Eval();         return; }
	}

	static bool Done() { return _seed >= kSeeds; }

private:
	// ── 등록한 수 — ⚠️ **한 곳에만** 둔다 ─────────────────────────
	static constexpr uint32 kSeeds   = 12u;
	static constexpr uint32 kTrainF  = 32u;      // 학습 프레임
	static constexpr uint32 kTestF   = 8u;       // 시험 프레임(뒤에 오는 것)
	static constexpr uint32 kFrames  = kTrainF + kTestF;   // 40 = 풀 상한과 같다
	static constexpr uint32 kSteps   = 1200u;
	static constexpr uint32 kPerTick = 8u;       // 한 렌더 프레임에 도는 스텝
	static constexpr uint32 kEvalTr  = 8u;       // ⓘ 학습 MSE 를 재는 프레임 수
	static constexpr float  kHead    = 0.01710f; // ㉠ 표제 문턱(A단계가 고른 B 의 절반)
	static constexpr float  kBeat    = 0.5f;     // 씨앗 통과 = 자기 대조군의 절반 아래
	static constexpr float  kUseFrac = 0.01f;    // ㉡ 정의의 1%
	static constexpr float  kRankTol = 1.0e-3f;  // 랭크 판정의 상대 문턱
	static constexpr uint32 kSignPass = 10u;     // 부호검정

	enum { kInit, kTrain, kEval };

	inline static MLTP2Enc _E;
	inline static bool   _banner = false;
	inline static uint32 _seed = 0u;
	inline static int    _st = kInit;
	inline static uint32 _step = 0u;
	inline static uint32 _ev = 0u;              // 평가 파이프라인 진행
	inline static Array<float> _usage;
	inline static double _sumTest = 0.0, _sumTrain = 0.0;
	inline static uint32 _nTest = 0u, _nTrain = 0u;
	inline static float  _baseB = 0.0f;          // 이 씨앗의 시험 대조군(패치 상수)
	inline static uint32 _rank = 0u;             // 이 씨앗의 시험 패치 랭크
	inline static float  _lastCurve = 0.0f;
	inline static bool   _finite = true;

	// 결과 — ⚠️ **씨앗마다** 남긴다(부호검정이 그것을 요구한다)
	inline static float  _rTest[kSeeds] = { 0.0f }, _rTrain[kSeeds] = { 0.0f }, _rBase[kSeeds] = { 0.0f };
	inline static uint32 _rUse[kSeeds] = { 0u }, _rRank[kSeeds] = { 0u };
	inline static bool   _rOk[kSeeds] = { false };

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🏁👁️ **P2 판정 라운드** — ㉠ 재구성 · ㉡ 사전 사용률 (씨앗 %u)\n", kSeeds);
		LogA("[mlt] 🏁   학습 %u프레임 × %u스텝(%u/렌더프레임) · 시험 **뒤 %u프레임**\n",
			kTrainF, kSteps, kPerTick, kTestF);
		LogA("[mlt] 🏁   ㉠ 표제 `MSE_시험 < %.5f` · 씨앗 통과 = 자기 패치상수 대조군의 %.0f%% 아래"
		     " · 부호검정 **%u/%u**\n", (double)kHead, (double)(kBeat * 100.0f), kSignPass, kSeeds);
		LogA("[mlt] 🏁   ㉡ 문턱 = **rank(시험 패치)** — 필요조건이다(선형결합이 그 부분공간을 펼쳐야 한다)\n");
		LogA("[mlt] 🏁   갈래: 사용률 ≥ rank ✅ · k < 사용률 < rank ⚠️부분 · 사용률 ≤ k ⛔붕괴\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

	// ══════════════════════════════════════════════════════════════════
	// 🏗 씨앗 하나를 시작한다 — 프레임 40장을 만들어 **한 번** 올리고, CPU 가 대조군·랭크를 낸다.
	// ══════════════════════════════════════════════════════════════════
	static void _BeginSeed(RHI* rhi)
	{
		typedef MLTP2Cfg C;
		if (!_E.Setup(rhi)) { LogA("[mlt] 🏁 준비 실패(씨앗 %u)\n", _seed); _seed = kSeeds; return; }

		Array<float> fr, tg; fr.Reset(0); tg.Reset(0);
		Array<float> testPatch; testPatch.Reset(0);     // 랭크·대조군의 재료(시험 프레임만)
		ImageFormat::Bitmap bmp;
		Bytes packed;
		MLTWorld w;
		w.Reset(_seed, 0u, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
		for (uint32 f = 0; f < kFrames; ++f)
		{
			w.Step();
			if (!w.Render(bmp) || !MLTWorld::Pack(bmp, nullptr, packed))
			{ LogA("[mlt] 🏁 Render/Pack 실패(씨앗 %u · 프레임 %u)\n", _seed, f); _seed = kSeeds; return; }
			const uint8* px = (const uint8*)packed.GetData();
			MLTP2Enc::AppendFrame(fr, tg, px);
			if (f >= kTrainF)
			{
				// ★ 시험 패치를 그대로 모은다 — 대조군과 랭크가 **같은 배열**을 본다(어긋날 수 없다).
				Array<float> one; one.Reset(0); Array<float> dummy; dummy.Reset(0);
				MLTP2Enc::AppendFrame(dummy, one, px);
				for (uint32 i = 0; i < one.Count(); ++i) testPatch.Add(one[i]);
			}
		}
		if (!_E.WritePool(fr, tg, kFrames))
		{ LogA("[mlt] 🏁 풀 업로드 실패(씨앗 %u)\n", _seed); _seed = kSeeds; return; }

		_baseB = MLTP2Enc::PatchConstMse(testPatch);
		_rank  = MLTP2Enc::PatchRank(testPatch, kRankTol);

		_usage.Reset(0);
		for (uint32 i = 0; i < _E.N(); ++i) _usage.Add(0.0f);
		_step = 0u; _ev = 0u; _sumTest = 0.0; _sumTrain = 0.0; _nTest = 0u; _nTrain = 0u;
		_finite = true; _lastCurve = 0.0f;
		_st = kTrain;

		if (_seed == 0u)
			LogA("[mlt] 🏁   ⓘ 파라미터 — 할당 %u(%.2fM) · 살아있음은 회차 20 이 쟀다(0.38M ≤ 0.5M)\n",
				_E.AllocParams(), (double)((float)_E.AllocParams() / 1.0e6f));
		LogA("[mlt] 🏁 [%2u/%u] 씨앗 %u — 시험 대조군(패치상수) **%.5f** ⇒ 통과선 %.5f · 시험 랭크 **%u**\n",
			_seed + 1u, kSeeds, _seed, (double)_baseB, (double)(kBeat * _baseB), _rank);
	}

	// ── 학습 — ⭐ 한 렌더 프레임에 `kPerTick` 스텝 ────────────────
	static void _Train()
	{
		for (uint32 i = 0; i < kPerTick && _step < kSteps; ++i)
		{
			_E.SetFrame(_step % kTrainF);
			if (!_E.Forward() || !_E.Backward() || !_E.AdamStep(1.0f))
			{ LogA("[mlt] 🏁 스텝 실패(씨앗 %u · 스텝 %u)\n", _seed, _step); _seed = kSeeds; return; }
			++_step;
		}
		// ⚠️ 여기서 읽는 것은 **직전 프레임**의 `dRecon` 이다(곡선의 표본 · 관문 아님)
		{
			float mse = 0.0f; bool fin = true;
			if (_E.ReadMse(mse, fin)) { _lastCurve = mse; if (!fin) _finite = false; }
		}
		if (_step % 400u == 0u || _step >= kSteps)
			LogA("[mlt] 🏁   씨앗 %u · 스텝 %4u · 학습 MSE(표본) %.5f · ⏱️ 렌더CPU %.1fms\n",
				_seed, _step, (double)_lastCurve, (double)FrameStats::renderCpuMs);
		if (_step >= kSteps) { _st = kEval; _ev = 0u; }
	}

	// ══════════════════════════════════════════════════════════════════
	// 📊 평가 — ⚠️ **디스패치와 회수가 한 프레임 어긋난다** ⇒ 파이프라인으로 돈다.
	//   순서: 시험 8장 → 학습 8장. ★ 사용률은 **시험 장에서만** 누산한다(등록된 정의).
	// ══════════════════════════════════════════════════════════════════
	static void _Eval()
	{
		const uint32 nEv = kTestF + kEvalTr;
		// ① 직전 장의 결과를 거둔다
		if (_ev > 0u)
		{
			const uint32 prev = _ev - 1u;
			float mse = 0.0f; bool fin = true;
			if (!_E.ReadMse(mse, fin)) { LogA("[mlt] 🏁 평가 리드백 실패\n"); _seed = kSeeds; return; }
			if (!fin) _finite = false;
			if (prev < kTestF)
			{
				_sumTest += (double)mse; ++_nTest;
				if (!_E.AccumUsage(_usage)) { LogA("[mlt] 🏁 사용률 리드백 실패\n"); _seed = kSeeds; return; }
			}
			else { _sumTrain += (double)mse; ++_nTrain; }
		}
		// ② 다음 장을 디스패치한다(역전파도 갱신도 없다 — 평가다)
		if (_ev < nEv)
		{
			const uint32 idx = (_ev < kTestF) ? (kTrainF + _ev) : (_ev - kTestF);
			_E.SetFrame(idx);
			if (!_E.Forward()) { LogA("[mlt] 🏁 평가 forward 실패\n"); _seed = kSeeds; return; }
			++_ev;
			return;
		}
		_JudgeSeed();
	}

	static void _JudgeSeed()
	{
		typedef MLTP2Cfg C;
		const float mseT = (_nTest  != 0u) ? (float)(_sumTest  / (double)_nTest)  : 0.0f;
		const float mseR = (_nTrain != 0u) ? (float)(_sumTrain / (double)_nTrain) : 0.0f;

		// ㉡ — 최댓값의 1% 를 넘는 유닛의 개수
		float mx = 0.0f;
		for (uint32 i = 0; i < _E.N(); ++i) if (_usage[i] > mx) mx = _usage[i];
		uint32 use = 0u;
		if (mx > 0.0f) { const float th = kUseFrac * mx; for (uint32 i = 0; i < _E.N(); ++i) if (_usage[i] > th) ++use; }

		const bool ok = (mseT < kBeat * _baseB) && _finite;
		_rTest[_seed] = mseT; _rTrain[_seed] = mseR; _rBase[_seed] = _baseB;
		_rUse[_seed] = use; _rRank[_seed] = _rank; _rOk[_seed] = ok;

		LogA("[mlt] 🏁 [%2u/%u] 씨앗 %u — 시험 **%.5f** %s %.5f · 학습 %.5f(ⓘ) · 사용률 **%u** / rank %u%s\n",
			_seed + 1u, kSeeds, _seed, (double)mseT, ok ? "<" : "≥", (double)(kBeat * _baseB),
			(double)mseR, use, _rank, _finite ? "" : " ⚠️비유한");

		++_seed;
		if (_seed >= kSeeds) { _Summary(); _E.Destroy(); return; }
		_st = kInit;
	}

	static void _Summary()
	{
		double sT = 0.0, sR = 0.0, sB = 0.0; uint32 sign = 0u, sU = 0u, sK = 0u;
		uint32 full = 0u, part = 0u, coll = 0u;
		for (uint32 i = 0; i < kSeeds; ++i)
		{
			sT += (double)_rTest[i]; sR += (double)_rTrain[i]; sB += (double)_rBase[i];
			sU += _rUse[i]; sK += _rRank[i];
			if (_rOk[i]) ++sign;
			if (_rUse[i] >= _rRank[i]) ++full;
			else if (_rUse[i] > MLTP2Cfg::kK) ++part;
			else ++coll;
		}
		const float mT = (float)(sT / (double)kSeeds);
		const bool g1head = (mT < kHead);
		const bool g1sign = (sign >= kSignPass);

		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🏁👁️ **P2 판정 라운드 결과**\n");
		LogA("[mlt] 🏁   시험 MSE 평균 **%.5f** · 대조군(패치상수) 평균 %.5f · 학습 MSE 평균 %.5f(ⓘ)\n",
			(double)mT, (double)(sB / (double)kSeeds), (double)(sR / (double)kSeeds));
		LogA("[mlt] 🏁   %s ㉠-표제 %.5f < %.5f\n", g1head ? "✅" : "⛔", (double)mT, (double)kHead);
		LogA("[mlt] 🏁   %s ㉠-부호검정 **%u/%u** (필요 %u · 단측 p=0.0193 < 0.025 = 0.05/Q · Q=2)\n",
			g1sign ? "✅" : "⛔", sign, kSeeds, kSignPass);
		LogA("[mlt] 🏁   ㉡ 사용률 평균 **%.1f** / rank 평균 %.1f — 갈래: ✅%u(≥rank) ⚠️%u(부분) ⛔%u(붕괴)\n",
			(double)((float)sU / (float)kSeeds), (double)((float)sK / (float)kSeeds), full, part, coll);
		// ⭐ 등록한 갈래를 **그대로** 적용한다(결과를 보고 고르지 않는다)
		const char* verdict = (coll > 0u) ? "⛔ 붕괴한 씨앗이 있다"
			: (full == kSeeds) ? "✅ 표현할 수 있는 만큼 쓴다" : "⚠️ 부분 — ㉠ 과 함께 읽어라";
		LogA("[mlt] 🏁   ㉡ 판정 = **%s**\n", verdict);
		LogA("[mlt] 🏁   ⓘ 씨앗별 시험/사용률: ");
		for (uint32 i = 0; i < kSeeds; ++i) LogA("%.4f/%u ", (double)_rTest[i], _rUse[i]);
		LogA("\n");
		LogA("[mlt] 🏁   📌 다음 = 걸음 4(`k`·`N` 스윕 봉우리) · ㉢ 은 색 대조군과 함께 별 회차\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

	// ⚠️ CPU 통계 둘(`PatchConstMse` · `PatchRank`)은 **`MLTP2Enc` 로 옮겼다** — 회차 둘이
	//   같은 것을 보므로 복사하면 「A단계와 같은 식」이라는 약속이 반드시 어긋난다.
};
