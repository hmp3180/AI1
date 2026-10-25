// mltp2u.cw — 📏👁️ **P2 걸음 7 · 사전 유닛의 크기 정규화 A/B**. 회차 25 가 부른 자리다.
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문** — ⚠️ 재기 **전에** 적는다.
// ══════════════════════════════════════════════════════════════════════════════
//
// ① **왜 이것인가** — 회차 23·24·25 가 같은 것을 봤다: **사용률이 ~35 에서 안 움직인다**
//    (데이터 16배 → 1.26배 · `N` 8배 → 1.12배 · `k` 4배 → 3.27배지만 그건 *"패치마다 더 쓴다"*).
//    ⇒ 병목은 **top-k 승자독식**(죽은 코드)이다.
//    ★ 그 승자독식의 한 원인은 **우리 파라미터화의 인공물**이다: `score = patch·Wd` 에서 유닛이
//      **열이 길다는 이유만으로** 이긴다 — 데이터의 성질이 아니다.
//    ⇒ 크기를 고르게 맞추는 것은 *"정답의 구조를 우리가 주는 것"*(`mltconcept.md` ㈀ 경고)이 아니라
//      **우리가 만든 잡음을 없애는 것**이다(방향은 그대로 배운다 · 이득은 **전부 같은 수**다).
//      ⚠️ 그 수는 **1 이 아니라 초기 RMS**(`kNormRms`)여야 한다 — 1 이면 평균 크기를 19배로 키운다
//        (아래 ⚠️⚠️⚠️ 절의 실측).
//    ⚠️ 그래도 **모델 변경**이므로 조용히 켜지 않고 **A/B 로 등록**한다.
//
// ② **팔 둘** — ㈀ 정규화 **끔**(지금 모델) · ㈁ 정규화 **켬**(`AdamStep` 뒤에 `rmsnorm` 사영).
//    `k = 8` · `N = 1000` · 학습 프레임 **128** · 4800 스텝 · 시험 **다른 에피소드** 0~7
//    ⇒ 회차 24 의 가운데 팔·회차 25 의 가운데 팔과 **같은 설정**이다.
//    ⚠️⚠️ **다만 절대값을 그 회차들과 직접 비교하지 않는다** — `Wd` 저장을 `[D,N]` → `[N,D]` 로
//      돌렸으므로 **초기값의 배치가 달라졌다**(결정적 산포를 다른 순서로 읽는다). ⇒ 그래서
//      **㈀ 팔을 기준선으로 여기서 다시 잰다.** ★ 그것이 이 회차에 A/B 가 필요한 이유이기도 하다.
//
// ③ ⭐ **표제 판정 — 사용률이 「크게」 뛰나**
//    · 문턱: **㈁ 의 사용률 ≥ 2 × ㈀ 의 사용률**(팔 평균).
//      ★ 근거: 실패한 세 축이 사용률을 움직인 폭이 **≤ 1.26배**였다(데이터 16배가 1.26 · `N` 8배가
//        1.12). ⇒ **2배**는 그 어느 축도 못 낸 폭이고, 임의 절대수가 아니라 **실측된 대조**다.
//    · 그리고 **씨앗별 짝지은 부호검정**: ㈁ 의 사용률 > ㈀ 의 사용률 인 씨앗이 **11/12**
//      (`Q = 2` ⇒ 단측 p < **0.025**. 11/12 의 p = 0.0032 ✅).
//
// ④ **관문 ㉠ 은 그대로** — 표제 `MSE_시험 < 0.01710` · 씨앗별 부호검정 **11/12**. ⚠️ 고치지 않는다.
//
// ⑤ ⭐ **갈래 셋을 미리 등록한다** — ★ 사용률만 보면 안 된다:
//    ```
//    ㈀ 사용률 ≥2배 **그리고** 시험 MSE 도 낮아진다   ⇒ 진단이 맞았고 **고쳐졌다**
//    ㈁ 사용률 ≥2배인데 시험 MSE 는 **안 낮아진다**    ⇒ 사용률은 병목이 **아니었다**(진단 수정)
//                                                       ★ 그러면 rank 를 못 펼치는 것이 문제가 아니다
//    ㈂ 사용률이 2배 **미만**                           ⇒ 크기 문제가 아니었다 ⇒ 다음은
//                                                       **죽은 유닛 재초기화**(= 명백한 비계 · 그때 등록)
//    ```
//    ⚠️ ㈁ 이면 **이 회차가 가설을 죽인다** — 그것도 결과다(사용률을 성과로 읽지 않는다).
//
// ⑥ ⭐ 진단(관문 아님): 시험/학습 비 · 사용률/rank · 대조군보다 나쁜 씨앗 · **씨앗 10 따로**
//    (회차 24·25 의 부채 — 그 씨앗의 시험 에피소드는 학습과 통째로 다르다).
//
// ⑦ ⚠️ 값 — 팔 둘 × 씨앗 12 × 4800 스텝 · `k=8` ⇒ **십 분 안**.
//
// ══════════════════════════════════════════════════════════════════════════════
// ⚠️⚠️⚠️ **첫 실행은 무효였다 — 팔의 버그다(관문은 하나도 안 고쳤다)**
// ══════════════════════════════════════════════════════════════════════════════
//   `rmsnorm` 의 이득을 **1** 로 두었더니 크기를 고르게 하는 **동시에** 평균 크기를 **19배**로 키웠다
//   (`Wd` 의 초기 원소 RMS 가 `0.09/√3 = 0.052` 다). ⇒ `score`·`mag` 가 19배 → recon 이 터졌다:
//   ```
//   ㈀끔  시험 0.03977 · 학습 0.01229 · 비 3.23 · 사용률 39.5
//   ㈁켬  시험 0.39051 · 학습 0.05646 · 비 6.92 · 사용률 19.2   ← ⚠️ **학습까지 나빠졌다**
//   ```
//   ★ **「학습까지 나빠졌다」가 무효의 증거다** — 크기를 고르게 하는 것이 학습 능력을 깎을 이유가
//     없다(모양을 안 건드린다). ⇒ 그것은 **척도 폭주**이고 가설과 무관하다.
//   ⚠️⚠️ 그래서 자동 판정이 낸 **㈂("크기 문제가 아니었다")를 결론으로 쓰지 않는다** — 그 팔은
//     「고르게」가 아니라 「고르게 **하고 19배**」를 쟀다. **가설은 아직 안 재졌다.**
//   ⇒ 고침: 이득을 **`kNormRms`**(= 초기 RMS)로 둔다 ⇒ 사영이 **흩어짐만** 없애고 평균 크기는 그대로.
//   ★ 관문·문턱·갈래는 **하나도 안 바꿨다**(고친 것은 팔의 구현이다).
//
// ══════════════════════════════════════════════════════════════════════════════
// 🧾 **결과(회차 26 · 고친 팔) — ⭐ 가설이 죽었다. 깨끗하게.**
// ══════════════════════════════════════════════════════════════════════════════
//   | 팔 | 시험 | 학습 | 비 | 사용률 | 부호검정 | 대조군보다 나쁨 |
//   |---|---|---|---|---|---|---|
//   | ㈀끔 | 0.03977 | 0.01229 | 3.23 | **39.5** | 1/12 | 3 |
//   | ㈁켬 | 0.04212 | 0.01259 | 3.35 | **37.9** | 1/12 | 4 |
//
//   · 사용률 배율 **0.96배**(문턱 2.0) · 씨앗별 사용률↑ **6/12**(p=0.613) = **우연** ⇒ 등록된 **㈂**.
//   · 시험 MSE↓ 8/12(p=0.194) = 우연. ⇒ **크기 정규화는 아무것도 안 바꿨다.**
//   ★ **이 팔이 유효하다는 증거는 「학습 MSE 가 거의 같다」**(0.01229 ↔ 0.01259)다 —
//     사영이 학습 능력을 깎지 않았으므로 **잰 것이 우리가 재려던 것**이다.
//     ⚠️ 무효였던 첫 실행은 바로 그 칸이 0.01229 → 0.05646 으로 무너져 있었다(척도 폭주).
//     ⇒ 「대조군이 살아 있나」의 비전판이 이 칸이다. **관문에 넣지 않았는데도 판정을 구해 줬다.**
//
//   ⭐ **결론: 승자독식의 원인은 유닛 크기의 불균형이 아니다.** 세 축(데이터·`N`·크기)이 전부
//     사용률을 못 움직였다 ⇒ ⚠️ **「사용률이 병목」이라는 우리 진단 자체를 의심해야 한다.**
//     ★ 사용률 ~38 이라도 유닛 8개의 **선형결합**이면 표현할 수 있는 패치는 매우 많다
//       (35개에서 8개를 고르는 조합만 해도 방대하다). ⇒ 사용률은 **부수현상**일 수 있다.
//
// ══════════════════════════════════════════════════════════════════════════════
// 📌 **다음 후보 — ⚠️ 손잡이를 더 돌리지 말고 「시험 오차가 무엇으로 되어 있나」를 쪼갠다**
// ══════════════════════════════════════════════════════════════════════════════
//   ⭐ **오라클 분해**(전부 CPU · 새 커널 0개): 학습된 **코드북을 그대로** 읽어 와서, 시험 패치마다
//     **가장 잘 맞는 유닛 k개를 CPU 가 골라**(matching pursuit) MSE 를 낸다.
//     ```
//     오라클 MSE ≈ 학습 MSE   ⇒ **코드북은 충분하고 「선택」이 나쁘다**(그러면 선택을 고친다)
//     오라클 MSE ≈ 시험 MSE   ⇒ **코드북 자체가 그 에피소드를 표현 못 한다**(그러면 표현을 고친다)
//     ```
//   ★ 이것은 **손잡이가 아니라 분해**다 — 기제를 넣기 전에 **무엇이 문제인지** 먼저 안다
//     (그것이 `mltconcept.md` 의 비계 경고를 존중하는 순서다).

using namespace PE;

class MLTP2U
{
public:
	static void Tick(RHI* rhi)
	{
		if (_arm >= kArms || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltp2u"))
		{
			LogA("[mlt] 📏 걸음 7(사전 크기 정규화 A/B)는 **꺼져 있다**(`-mltp2u`) — 회차 26 기록:"
			     " ㈀끔 0.03977/사용률 39.5 ↔ ㈁켬 0.04212/사용률 37.9 (배율 **0.96배** · 씨앗별 6/12)"
			     " ⇒ **㈂ 크기 불균형은 원인이 아니다**(가설 사망)\n");
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
	static constexpr uint32 kArms = 2u;              // ㈀ 끔 · ㈁ 켬
	static constexpr uint32 kSeeds = 12u;
	static constexpr uint32 kTrainF = 128u, kTestF = 8u;
	static constexpr uint32 kPoolCap = kTrainF + kTestF;
	static constexpr uint32 kSteps = 4800u;
	static constexpr uint32 kN = 1000u, kK = 8u;
	static constexpr uint32 kPerTick = 4u, kEvalTr = 8u;
	static constexpr float  kHead = 0.01710f, kBeat = 0.5f;
	static constexpr float  kUseFrac = 0.01f, kRankTol = 1.0e-3f;
	static constexpr uint32 kSignPass = 11u;
	static constexpr float  kUseGain = 2.0f;         // ③ 사용률 문턱(실패한 세 축의 최대가 1.26배)
	static constexpr uint32 kTestEpisode = 1u;
	static constexpr uint32 kWatchSeed = 10u;

	enum { kInit, kTrain, kEval };

	inline static MLTP2Enc _E;
	inline static bool   _banner = false, _setup = false;
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

	static bool _NormOn() { return _arm == 1u; }
	static const char* _ArmName() { return (_arm == 0u) ? "㈀끔" : "㈁켬"; }

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 📏👁️ **P2 걸음 7 · 사전 유닛 크기 정규화 A/B** — 씨앗 %u (k=%u N=%u F=%u %u스텝)\n",
			kSeeds, kK, kN, kTrainF, kSteps);
		LogA("[mlt] 📏   팔: ㈀ **끔**(지금 모델) ↔ ㈁ **켬**(`AdamStep` 뒤 `rmsnorm` 사영 ·"
		     " 이득 = **초기 RMS %.5f**)\n", (double)MLTP2Cfg::kNormRms);
		LogA("[mlt] 📏   ⚠️ 이득을 1 로 두면 크기를 **19배**로 키운다(첫 실행이 그것으로 무효가 됐다)\n");
		LogA("[mlt] 📏   ⭐ 표제: ㈁ 사용률 ≥ **%.1f배** × ㈀ (근거: 실패한 세 축의 최대가 **1.26배**)"
		     " + 씨앗별 **%u/%u**\n", (double)kUseGain, kSignPass, kSeeds);
		LogA("[mlt] 📏   갈래: ㈀ 사용률↑ **그리고** MSE↓ = 고쳐졌다 · ㈁ 사용률↑ 인데 MSE 그대로 ="
		     " **가설이 죽는다** · ㈂ 사용률 2배 미만 = 크기 문제가 아니었다\n");
		LogA("[mlt] 📏   ⚠️ `Wd` 를 `[N,D]` 로 돌렸으므로 **초기값 배치가 달라졌다** ⇒ 회차 24·25 의"
		     " 절대값과 직접 비교하지 않는다(㈀ 팔이 기준선이다)\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

	static void _BeginSeed(RHI* rhi)
	{
		if (!_setup)
		{
			if (!_E.Setup(rhi, kPoolCap, kN)) { LogA("[mlt] 📏 준비 실패\n"); _arm = kArms; return; }
			_setup = true;
		}
		else if (!_E.ResetSeed()) { LogA("[mlt] 📏 되돌리기 실패\n"); _arm = kArms; return; }
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
				{ LogA("[mlt] 📏 Render/Pack 실패(학습)\n"); _arm = kArms; return; }
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
				{ LogA("[mlt] 📏 Render/Pack 실패(시험)\n"); _arm = kArms; return; }
				const uint8* px = (const uint8*)packed.GetData();
				MLTP2Enc::AppendFrame(fr, tg, px);
				Array<float> one, dummy; one.Reset(0); dummy.Reset(0);
				MLTP2Enc::AppendFrame(dummy, one, px);
				for (uint32 i = 0; i < one.Count(); ++i) testPatch.Add(one[i]);
			}
		}
		if (!_E.WritePool(fr, tg, kTrainF + kTestF))
		{ LogA("[mlt] 📏 풀 업로드 실패\n"); _arm = kArms; return; }

		_baseB = MLTP2Enc::PatchConstMse(testPatch);
		_rank  = MLTP2Enc::PatchRank(testPatch, kRankTol);

		// ⭐ 켬 팔은 **첫 스텝 전에도 한 번** 사영한다 — 초기 산포의 크기 차이부터 없애는 것이
		//   이 팔의 뜻이다(첫 선택이 이미 크기로 갈리면 그 뒤 사영은 늦다).
		if (_NormOn() && !_E.NormalizeDict())
		{ LogA("[mlt] 📏 초기 정규화 실패\n"); _arm = kArms; return; }

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
			{ LogA("[mlt] 📏 스텝 실패(팔 %s 씨앗 %u 스텝 %u)\n", _ArmName(), _seed, _step); _arm = kArms; return; }
			// ⭐ 사영은 **갱신 뒤**다(Adam 의 `m`/`v` 는 원래 기울기를 본다).
			if (_NormOn() && !_E.NormalizeDict())
			{ LogA("[mlt] 📏 정규화 실패\n"); _arm = kArms; return; }
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
			if (!_E.ReadMse(m, fin)) { LogA("[mlt] 📏 평가 리드백 실패\n"); _arm = kArms; return; }
			if (!fin) _finite = false;
			if (prev < kTestF)
			{
				_sumTest += (double)m; ++_nTest;
				if (!_E.AccumUsage(_usage)) { LogA("[mlt] 📏 사용률 리드백 실패\n"); _arm = kArms; return; }
			}
			else { _sumTrain += (double)m; ++_nTrain; }
		}
		if (_ev < nEv)
		{
			_E.SetFrame((_ev < kTestF) ? (kTrainF + _ev) : (_ev - kTestF));
			if (!_E.Forward()) { LogA("[mlt] 📏 평가 forward 실패\n"); _arm = kArms; return; }
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

		LogA("[mlt] 📏 %s [%2u/%u] 씨앗 %u — 시험 **%.5f** %s %.5f · 학습 %.5f · 사용률 **%u**/rank %u%s\n",
			_ArmName(), _seed + 1u, kSeeds, _seed, (double)mT, _ok[_arm][_seed] ? "<" : "≥",
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
		LogA("[mlt] 📏 ── 팔 %s ── 시험 **%.5f** · 학습 %.5f (비 **%.2f배**) · 부호검정 **%u/%u**"
		     " · 사용률 **%.1f**/rank %.1f · 대조군보다 나쁜 씨앗 **%u**\n",
			_ArmName(), (double)mT, (double)mR, (double)((mR > 1e-9f) ? (mT / mR) : 0.0f),
			sign, kSeeds, (double)((float)sU / (float)kSeeds), (double)((float)sK / (float)kSeeds), worse);
		LogA("[mlt] 📏    ⓘ 씨앗 %u(회차 24·25 의 튀는 씨앗) — 시험 %.5f · 대조군 %.5f · 사용률 %u\n",
			kWatchSeed, (double)_test[_arm][kWatchSeed], (double)_base[_arm][kWatchSeed],
			_use[_arm][kWatchSeed]);
	}

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
		// 짝지은 부호검정 둘
		uint32 wUse = 0u, wMse = 0u;
		for (uint32 i = 0; i < kSeeds; ++i)
		{
			if (_use[1][i] > _use[0][i]) ++wUse;
			if (_test[1][i] < _test[0][i]) ++wMse;
		}
		const float pUse = _BinomP(wUse, kSeeds), pMse = _BinomP(wMse, kSeeds);
		const float gain = (mU[0] > 1.0e-6f) ? (mU[1] / mU[0]) : 0.0f;

		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 📏👁️ **사전 크기 정규화 A/B 결과**\n");
		for (uint32 a = 0; a < kArms; ++a)
			LogA("[mlt] 📏   %s · 시험 **%.5f** · 학습 %.5f · 비 %.2f · 사용률 **%.1f** · 부호검정 %u/%u · %s ㉠\n",
				(a == 0u) ? "㈀끔" : "㈁켬", (double)mT[a], (double)mR[a],
				(double)((mR[a] > 1e-9f) ? (mT[a] / mR[a]) : 0.0f), (double)mU[a], sign[a], kSeeds,
				(mT[a] < kHead && sign[a] >= kSignPass) ? "✅" : "⛔");
		LogA("[mlt] 📏   ⭐ 사용률 배율 **%.2f배** (%.1f → %.1f) — 문턱 %.1f배 %s\n",
			(double)gain, (double)mU[0], (double)mU[1], (double)kUseGain,
			(gain >= kUseGain) ? "✅" : "⛔");
		LogA("[mlt] 📏   ⭐ 씨앗별 짝지은 검정 — 사용률↑ **%u/%u**(p=%.5f %s) · 시험 MSE↓ **%u/%u**(p=%.5f %s)\n",
			wUse, kSeeds, (double)pUse, (pUse < 0.025f) ? "✅" : "⛔",
			wMse, kSeeds, (double)pMse, (pMse < 0.025f) ? "✅" : "⛔");

		// ⭐ 등록한 갈래를 **그대로** 적용한다
		const bool useUp = (gain >= kUseGain) && (wUse >= kSignPass);
		const bool mseDown = (wMse >= kSignPass) && (pMse < 0.025f);
		const char* branch = !useUp
			? "㈂ 사용률이 문턱을 못 넘었다 ⇒ **크기 문제가 아니었다** ⇒ 다음은 죽은 유닛 재초기화(명백한 비계)"
			: (mseDown ? "㈀ 사용률↑ **그리고** 시험 MSE↓ ⇒ **진단이 맞았고 고쳐졌다**"
			           : "㈁ 사용률↑ 인데 시험 MSE 는 그대로 ⇒ **사용률은 병목이 아니었다**(가설이 죽는다)");
		LogA("[mlt] 📏   ⭐ 갈래 판정 = **%s**\n", branch);
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}
};
