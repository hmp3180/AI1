// mltp2dec.cw — 🔬👁️ **P2 걸음 8 · 오라클 분해**. ⚠️ **손잡이가 아니라 분해다.**
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문** — ⚠️ 재기 **전에** 적는다.
// ══════════════════════════════════════════════════════════════════════════════
//
// ① **왜 분해인가** — 손잡이를 넷 돌렸는데 넷 다 안 움직였다:
//    `k`(회차 23) · 데이터 16배(24) · `N` 8배(25) · 유닛 크기 정규화(26).
//    ⚠️ 그리고 그 사이 사용률은 33.6 → 42.2 → 35.8 → 37.9 로 **거의 고정**이었다.
//    ⇒ 「사용률이 병목」이라는 **우리 진단 자체가 의심**된다. 다섯 번째 손잡이를 돌리기 전에
//      **시험 오차가 무엇으로 되어 있는지** 쪼갠다. ★ 기제를 넣기 전에 원인을 아는 것이
//      `mltconcept.md` 의 비계 경고를 존중하는 순서다.
//
// ② **셋을 나란히 잰다**(같은 씨앗 · 같은 코드북 · 같은 시험 패치)
//    ```
//    ㉮ 모델      : 지금 그대로 (ids·mag 를 모델이 낸다)
//    ㉯ 오라클 B  : **ids 는 모델 것 그대로**, 세기만 **최소제곱으로 최적**       ⇒ 「세기」의 몫
//    ㉰ 오라클 A  : ids·세기 **둘 다 최적**(정합추적 greedy matching pursuit)     ⇒ 「선택」의 몫
//    ```
//    ★ ㉰ 의 잔차가 곧 **이 코드북의 표현 한계**다(그 이하로는 못 내려간다).
//    ⚠️ 전부 **CPU** 이고 **새 커널이 0개**다 — 학습된 코드북과 선택을 되읽어 CPU 가 푼다.
//    ⚠️ ㉯ 는 8×8 정규방정식을 푼다(가우스 소거 + 작은 리지 `1e-6`). ㉰ 는 greedy 다
//      (최적이 아니지만 **모델보다 강한 상한**이고, 그게 분해에 필요한 전부다).
//
// ③ ⭐ **갈래를 미리 등록한다** — 비율은 `오라클 / 모델`(시험 MSE)로 본다:
//    ```
//    ㈀ ㉰/㉮ ≥ 0.70  ⇒ **코드북이 표현을 못 한다**(선택을 고쳐도 소용없다) ⇒ 표현을 고친다
//    ㈁ ㉰/㉮ ≤ 0.30  ⇒ **선택·세기가 나쁘다** ⇒ 그 안에서 ㉯ 가 가른다:
//                       · ㉯/㉮ ≤ 0.5 ⇒ **세기**가 큰 몫(점수를 세기로 쓰는 것이 문제다)
//                       · ㉯/㉮ > 0.5 ⇒ **선택**이 큰 몫(top-k 가 엉뚱한 유닛을 고른다)
//    ㈂ 사이(0.30~0.70) ⇒ **둘 다** — 그러면 큰 쪽을 먼저 고친다
//    ```
//    ⚠️ 「0.70/0.30」은 임의다 — 그래서 **비율 자체를 로그에 찍고** 갈래는 방향만 준다.
//      ★ 임의성을 숨기지 않는 것이 이 자리의 정직함이다.
//
// ④ ⭐ **학습 패치에도 같은 분해를 한다** — ㉰(학습) 이 낮고 ㉰(시험) 이 높으면
//    **코드북이 학습 에피소드에만 맞춰졌다**는 뜻이고, 그것이 「전이가 안 된다」의 정확한 형태다.
//
// ⑤ **설정은 회차 26 의 ㈀ 팔과 같다**(k=8 · N=1000 · 학습 128프레임 · 4800스텝 · 시험 다른 에피소드).
//    ⚠️ 정규화는 **끈다**(회차 26 이 아무 효과 없음을 보였으므로 기준 모델로 돌아간다).
//
// ⑥ ⚠️ 값 — 학습은 회차 26 의 한 팔과 같고(십 분 안) 오라클은 CPU 에서 씨앗당 ~1초다
//    (정합추적 = `k · N · 픽셀 · 패치` = 8·1000·192·512 ≈ 786M 곱덧).
//
// ══════════════════════════════════════════════════════════════════════════════
// 🧾 **결과(회차 27) — ⭐ 전이 실패의 자리를 찾았다.**
// ══════════════════════════════════════════════════════════════════════════════
//   | | 시험 | 모델 대비 | 씨앗 |
//   |---|---|---|---|
//   | ㉮ 모델 | **0.03977** | 1.00 | |
//   | ㉯ **ids 그대로 · 세기 최적** | **0.02789** | **0.70** | **12/12 에서 더 낮다** |
//   | ㉰ 둘 다 최적(greedy) | 0.02264 | 0.57 | 9/12 |
//   그리고 **학습** 쪽: 모델 **0.01229** · ㉰ **0.02196**
//
//   ⚠️⚠️⚠️ **먼저 내 오라클의 결함을 적는다 — ㉰(greedy)는 상한이 아니었다.**
//     학습 패치에서 ㉰(0.02196)가 **모델(0.01229)보다 나쁘다**(1.79배). 정합추적은 **탐욕**이라
//     최적 8-부분집합보다 훨씬 나쁠 수 있고, 모델의 선택은 **코드북과 함께 학습된** 것이다.
//     ⇒ 등록문 ③ 의 갈래는 *"㉰ 가 상한이다"* 를 전제했으므로 **그 전제가 깨졌다**
//       ⇒ 자동 판정이 낸 ㈂ 와 「㉰/㉮ = 0.57」을 **「선택의 몫」으로 읽지 않는다**(판정불가).
//     ★ 그래도 ㉰ 는 **한 가지에는 유효하다** — 아래 ⭐ 의 대칭 비교다(같은 절차·같은 코드북).
//
//   ⭐ **유효한 읽기 셋**
//   1. ⭐ **세기가 확실한 몫이다** — ids 를 **그대로 두고 세기만** 최소제곱으로 바꾸면 시험 오차가
//      **30% 준다**(0.70) 그리고 **12/12 씨앗에서** 그렇다(단측 p = 0.00024).
//      ⇒ 모델이 `mag = 점수` 를 계수로 쓰는 것이 **실측으로 나쁘다.**
//   2. ⭐ **코드북은 전이된다** — **같은 절차·같은 코드북**으로 재면
//      ㉰(시험) **0.02264** ↔ ㉰(학습) **0.02196** = **1.03배**다.
//      반면 **모델은 0.01229 → 0.03977 = 3.24배**다.
//      ⇒ ★ **전이 실패는 코드북(표현)이 아니라 「선택·세기」 경로에 있다.**
//        (코드북이 학습 에피소드에만 맞춰졌다면 ㉰ 의 시험/학습 비도 컸어야 한다.)
//   3. ⇒ 그래서 회차 23~26 이 못 움직인 이유가 설명된다: 넷 다 **사전 쪽** 손잡이였고
//      병목은 **사전이 아니었다.**
//
// ══════════════════════════════════════════════════════════════════════════════
// 📌 **다음 후보 — 「세기」를 겨눈다**(⚠️ 등록은 다음 회차에)
// ══════════════════════════════════════════════════════════════════════════════
//   ★ 세기의 뜻은 `mag × 코드북 행` 이다 ⇒ **코드북 행의 크기가 흩어져 있으면 같은 `mag` 가
//     전혀 다른 기여를 낸다.** 최소제곱이 30% 를 벌어들이는 이유가 그것일 수 있다.
//   ⭐ 그리고 회차 26 의 그 관용구를 **코드북에** 그대로 쓸 수 있다 — 코드북은 `[N, pixels]` 로
//     놓여 있어 **유닛 하나 = 한 행**이므로 `rmsnorm` 이 곧바로 붙는다(**새 커널 0개** · 전치도 필요 없다).
//     ⚠️ 회차 26 의 교훈대로 이득은 **1 이 아니라 초기 RMS** 여야 한다.
//   ⚠️ 회차 26 은 **`Wd`**(점수 쪽)를 정규화했고 아무 효과가 없었다. 이번은 **코드북**(계수가 곱해지는
//     쪽)이다 — **다른 자리**이고, 위 분해가 바로 그 자리를 가리킨다.

using namespace PE;

class MLTP2Dec
{
public:
	static void Tick(RHI* rhi)
	{
		if (_done || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltp2dec"))
		{
			LogA("[mlt] 🔬 걸음 8(오라클 분해)는 **꺼져 있다**(`-mltp2dec`) — 회차 27 기록:"
			     " ㉯(세기만 최적) **0.02789 = 모델의 0.70 · 12/12** ⇒ **세기가 확실한 몫** ·"
			     " ⭐ 코드북은 학습↔시험이 **1.03배**인데 모델은 **3.24배** ⇒ **전이 실패는 코드북이"
			     " 아니라 선택·세기 경로다** · ⚠️ ㉰(greedy)는 상한이 아니었다(학습에서 모델보다 나쁘다)\n");
			_done = true;
			return;
		}
		if (!_banner) { _Banner(); _banner = true; }
		if (_st == kInit)  { _BeginSeed(rhi); return; }
		if (_st == kTrain) { _Train();        return; }
		if (_st == kEval)  { _Eval();         return; }
	}

	static bool Done() { return _done; }

private:
	static constexpr uint32 kSeeds = 12u;
	static constexpr uint32 kTrainF = 128u, kTestF = 8u;
	static constexpr uint32 kPoolCap = kTrainF + kTestF;
	static constexpr uint32 kSteps = 4800u;
	static constexpr uint32 kN = 1000u, kK = 8u;
	static constexpr uint32 kPerTick = 4u;
	static constexpr uint32 kEvalTr = 8u;
	static constexpr uint32 kTestEpisode = 1u;
	static constexpr float  kRidge = 1.0e-6f;
	static constexpr float  kHiRatio = 0.70f, kLoRatio = 0.30f;

	enum { kInit, kTrain, kEval };

	inline static MLTP2Enc _E;
	inline static bool   _banner = false, _setup = false, _done = false;
	inline static uint32 _seed = 0u;
	inline static int    _st = kInit;
	inline static uint32 _step = 0u, _ev = 0u;
	inline static double _sumTest = 0.0, _sumTrain = 0.0;
	inline static uint32 _nTest = 0u, _nTrain = 0u;

	// 시험/학습 패치(표적)와 그 프레임에서 모델이 고른 것
	inline static Array<float> _tgtTest, _tgtTrain, _idsTest, _magTest;
	inline static Array<float> _code;

	// 결과 — 씨앗마다
	inline static float _mModel[kSeeds] = { 0.0f };     // ㉮ 모델(시험)
	inline static float _mOracB[kSeeds] = { 0.0f };     // ㉯ ids 그대로 · 세기 최적
	inline static float _mOracA[kSeeds] = { 0.0f };     // ㉰ 둘 다 최적
	inline static float _mTrain[kSeeds] = { 0.0f };     // 모델(학습)
	inline static float _mOracATr[kSeeds] = { 0.0f };   // ㉰(학습)

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🔬👁️ **P2 걸음 8 · 오라클 분해** — 씨앗 %u (k=%u N=%u F=%u %u스텝 · 정규화 끔)\n",
			kSeeds, kK, kN, kTrainF, kSteps);
		LogA("[mlt] 🔬   ㉮ 모델 ↔ ㉯ **ids 그대로·세기 최적** ↔ ㉰ **둘 다 최적**(정합추적)\n");
		LogA("[mlt] 🔬   갈래: ㉰/㉮ ≥ %.2f = **코드북이 표현 못 한다** · ≤ %.2f = **선택·세기가 나쁘다**"
		     " (그 안은 ㉯ 가 가른다)\n", (double)kHiRatio, (double)kLoRatio);
		LogA("[mlt] 🔬   ⚠️ 문턱 0.70/0.30 은 **임의다** — 그래서 비율 자체를 찍는다(갈래는 방향만 준다)\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

	static void _BeginSeed(RHI* rhi)
	{
		if (!_setup)
		{
			if (!_E.Setup(rhi, kPoolCap, kN)) { LogA("[mlt] 🔬 준비 실패\n"); _done = true; return; }
			_setup = true;
		}
		else if (!_E.ResetSeed()) { LogA("[mlt] 🔬 되돌리기 실패\n"); _done = true; return; }
		_E.SetK(kK);

		Array<float> fr, tg;
		fr.Reset(0); tg.Reset(0);
		_tgtTest.Reset(0); _tgtTrain.Reset(0);
		ImageFormat::Bitmap bmp;
		Bytes packed;
		{
			MLTWorld w;
			w.Reset(_seed, 0u, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
			for (uint32 f = 0; f < kTrainF; ++f)
			{
				w.Step();
				if (!w.Render(bmp) || !MLTWorld::Pack(bmp, nullptr, packed))
				{ LogA("[mlt] 🔬 Render/Pack 실패(학습)\n"); _done = true; return; }
				const uint8* px = (const uint8*)packed.GetData();
				MLTP2Enc::AppendFrame(fr, tg, px);
				// ★ 학습 쪽 분해는 **앞 8프레임**으로 한다(평가와 같은 장수 · 비용도 같다)
				if (f < kEvalTr)
				{
					Array<float> one, dummy; one.Reset(0); dummy.Reset(0);
					MLTP2Enc::AppendFrame(dummy, one, px);
					for (uint32 i = 0; i < one.Count(); ++i) _tgtTrain.Add(one[i]);
				}
			}
		}
		{
			MLTWorld w;
			w.Reset(_seed, kTestEpisode, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
			for (uint32 f = 0; f < kTestF; ++f)
			{
				w.Step();
				if (!w.Render(bmp) || !MLTWorld::Pack(bmp, nullptr, packed))
				{ LogA("[mlt] 🔬 Render/Pack 실패(시험)\n"); _done = true; return; }
				const uint8* px = (const uint8*)packed.GetData();
				MLTP2Enc::AppendFrame(fr, tg, px);
				Array<float> one, dummy; one.Reset(0); dummy.Reset(0);
				MLTP2Enc::AppendFrame(dummy, one, px);
				for (uint32 i = 0; i < one.Count(); ++i) _tgtTest.Add(one[i]);
			}
		}
		if (!_E.WritePool(fr, tg, kTrainF + kTestF))
		{ LogA("[mlt] 🔬 풀 업로드 실패\n"); _done = true; return; }

		_idsTest.Reset(0); _magTest.Reset(0);
		_step = 0u; _ev = 0u; _sumTest = 0.0; _sumTrain = 0.0; _nTest = 0u; _nTrain = 0u;
		_st = kTrain;
	}

	static void _Train()
	{
		for (uint32 i = 0; i < kPerTick && _step < kSteps; ++i)
		{
			_E.SetFrame(_step % kTrainF);
			if (!_E.Forward() || !_E.Backward() || !_E.AdamStep(1.0f))
			{ LogA("[mlt] 🔬 스텝 실패(씨앗 %u 스텝 %u)\n", _seed, _step); _done = true; return; }
			++_step;
		}
		if (_step >= kSteps) { _st = kEval; _ev = 0u; }
	}

	// ⚠️ 평가는 회차 24~26 과 같은 파이프라인이고, **시험 장의 ids·mag 를 모아 둔다**(㉯ 의 재료).
	static void _Eval()
	{
		const uint32 nEv = kTestF + kEvalTr;
		if (_ev > 0u)
		{
			const uint32 prev = _ev - 1u;
			float m = 0.0f; bool fin = true;
			if (!_E.ReadMse(m, fin)) { LogA("[mlt] 🔬 평가 리드백 실패\n"); _done = true; return; }
			if (prev < kTestF)
			{
				_sumTest += (double)m; ++_nTest;
				Array<float> id, mg;
				if (!_E.ReadAct(id, mg)) { LogA("[mlt] 🔬 선택 리드백 실패\n"); _done = true; return; }
				for (uint32 i = 0; i < id.Count(); ++i) { _idsTest.Add(id[i]); _magTest.Add(mg[i]); }
			}
			else { _sumTrain += (double)m; ++_nTrain; }
		}
		if (_ev < nEv)
		{
			_E.SetFrame((_ev < kTestF) ? (kTrainF + _ev) : (_ev - kTestF));
			if (!_E.Forward()) { LogA("[mlt] 🔬 평가 forward 실패\n"); _done = true; return; }
			++_ev;
			return;
		}
		_Decompose();
	}

	// ══════════════════════════════════════════════════════════════════
	// 🔬 분해 — 전부 CPU. ⚠️ 코드북을 **되읽어** 쓴다(모델이 실제로 가진 것 그대로).
	// ══════════════════════════════════════════════════════════════════
	static void _Decompose()
	{
		typedef MLTP2Cfg C;
		if (!_E.ReadCodebook(_code)) { LogA("[mlt] 🔬 코드북 리드백 실패\n"); _done = true; return; }

		_mModel[_seed] = (_nTest  != 0u) ? (float)(_sumTest  / (double)_nTest)  : 0.0f;
		_mTrain[_seed] = (_nTrain != 0u) ? (float)(_sumTrain / (double)_nTrain) : 0.0f;

		const uint32 nPatchT = _tgtTest.Count() / C::kPix;
		_mOracB[_seed] = MLTP2Enc::LsqMse(_code, kN, _tgtTest, _idsTest, kK, nPatchT, kRidge);
		_mOracA[_seed] = _Pursuit(_tgtTest, nPatchT);
		_mOracATr[_seed] = _Pursuit(_tgtTrain, _tgtTrain.Count() / C::kPix);

		const float md = _mModel[_seed];
		LogA("[mlt] 🔬 [%2u/%u] 씨앗 %u — ㉮모델 **%.5f** · ㉯세기최적 **%.5f**(%.2f) ·"
		     " ㉰둘다최적 **%.5f**(%.2f) │ 학습: 모델 %.5f · ㉰ %.5f\n",
			_seed + 1u, kSeeds, _seed, (double)md, (double)_mOracB[_seed],
			(double)((md > 1e-9f) ? (_mOracB[_seed] / md) : 0.0f),
			(double)_mOracA[_seed], (double)((md > 1e-9f) ? (_mOracA[_seed] / md) : 0.0f),
			(double)_mTrain[_seed], (double)_mOracATr[_seed]);

		++_seed;
		if (_seed >= kSeeds) { _Summary(); _E.Destroy(); _done = true; return; }
		_st = kInit;
	}

	// ⚠️ 「ids 그대로·세기 최적」은 **`MLTP2Enc::LsqMse` 로 올렸다** — 회차 둘이 같은 것을 보므로
	//   복사하면 반드시 어긋난다(README 의 「비슷한 함수는 묶기」).

	// ㉰ — 정합추적(greedy). ⚠️ 최적은 아니지만 **모델보다 강한 상한**이고 분해에는 그것으로 족하다.
	//   ★ 매 걸음 잔차와 가장 잘 맞는 유닛을 고르고 **그 자리에서 최적 계수**로 뺀다.
	static float _Pursuit(const Array<float>& tgt, uint32 nPatch)
	{
		typedef MLTP2Cfg C;
		if (nPatch == 0u) return 0.0f;
		// 유닛 제곱노름을 미리 센다(매 걸음 다시 세지 않게)
		Array<float> nrm; nrm.Reset(0);
		for (uint32 v = 0; v < kN; ++v)
		{
			const float* u = _code.Data() + v * C::kPix;
			float s = 0.0f;
			for (uint32 d = 0; d < C::kPix; ++d) s += u[d] * u[d];
			nrm.Add(s);
		}
		Array<float> res; res.Reset(0);
		for (uint32 d = 0; d < C::kPix; ++d) res.Add(0.0f);
		double sq = 0.0;
		Array<uint32> taken; taken.Reset(0);
		for (uint32 i = 0; i < kK; ++i) taken.Add(kN);
		for (uint32 p = 0; p < nPatch; ++p)
		{
			const float* y = tgt.Data() + p * C::kPix;
			for (uint32 d = 0; d < C::kPix; ++d) res.Data()[d] = y[d];
			for (uint32 i = 0; i < kK; ++i) taken.Data()[i] = kN;
			for (uint32 i = 0; i < kK; ++i)
			{
				uint32 best = kN; float bestGain = 0.0f, bestCoef = 0.0f;
				for (uint32 v = 0; v < kN; ++v)
				{
					if (nrm[v] <= 1.0e-12f) continue;
					bool dup = false;
					for (uint32 q = 0; q < i; ++q) if (taken[q] == v) { dup = true; break; }
					if (dup) continue;
					const float* u = _code.Data() + v * C::kPix;
					float dot = 0.0f;
					for (uint32 d = 0; d < C::kPix; ++d) dot += res[d] * u[d];
					// ★ 최적 계수 `dot/|u|²` 을 쓸 때 줄어드는 제곱오차 = `dot²/|u|²`
					const float gain = dot * dot / nrm[v];
					if (gain > bestGain) { bestGain = gain; best = v; bestCoef = dot / nrm[v]; }
				}
				if (best >= kN) break;
				taken.Data()[i] = best;
				const float* u = _code.Data() + best * C::kPix;
				for (uint32 d = 0; d < C::kPix; ++d) res.Data()[d] -= bestCoef * u[d];
			}
			for (uint32 d = 0; d < C::kPix; ++d) sq += (double)res[d] * res[d];
		}
		return (float)(sq / (double)(nPatch * C::kPix));
	}

	static void _Summary()
	{
		double sM = 0.0, sB = 0.0, sA = 0.0, sT = 0.0, sAT = 0.0;
		uint32 nB = 0u, nA = 0u;   // 씨앗별로 오라클이 모델보다 낮은 횟수
		for (uint32 i = 0; i < kSeeds; ++i)
		{
			sM += (double)_mModel[i]; sB += (double)_mOracB[i]; sA += (double)_mOracA[i];
			sT += (double)_mTrain[i]; sAT += (double)_mOracATr[i];
			if (_mOracB[i] < _mModel[i]) ++nB;
			if (_mOracA[i] < _mModel[i]) ++nA;
		}
		const float mM = (float)(sM / kSeeds), mB = (float)(sB / kSeeds), mA = (float)(sA / kSeeds);
		const float mT = (float)(sT / kSeeds), mAT = (float)(sAT / kSeeds);
		const float rB = (mM > 1.0e-9f) ? (mB / mM) : 0.0f;
		const float rA = (mM > 1.0e-9f) ? (mA / mM) : 0.0f;

		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🔬👁️ **오라클 분해 결과**(씨앗 %u 평균)\n", kSeeds);
		LogA("[mlt] 🔬   ㉮ 모델(시험)            **%.5f**\n", (double)mM);
		LogA("[mlt] 🔬   ㉯ ids 그대로·세기 최적   **%.5f**  (모델의 **%.2f**) · 씨앗 %u/%u 에서 더 낮다\n",
			(double)mB, (double)rB, nB, kSeeds);
		LogA("[mlt] 🔬   ㉰ 둘 다 최적(정합추적)   **%.5f**  (모델의 **%.2f**) · 씨앗 %u/%u 에서 더 낮다\n",
			(double)mA, (double)rA, nA, kSeeds);
		LogA("[mlt] 🔬   ─ 학습 쪽: 모델 %.5f · ㉰ **%.5f** (그 비 %.2f)\n",
			(double)mT, (double)mAT, (double)((mT > 1e-9f) ? (mAT / mT) : 0.0f));
		LogA("[mlt] 🔬   ⭐ 코드북의 표현 한계(㉰) 대비 — 시험 **%.5f** ↔ 학습 **%.5f** (시험/학습 %.2f배)\n",
			(double)mA, (double)mAT, (double)((mAT > 1e-9f) ? (mA / mAT) : 0.0f));

		// ⭐ 등록한 갈래를 **그대로** 적용한다
		const char* branch;
		if (rA >= kHiRatio) branch = "㈀ **코드북이 표현을 못 한다**(선택을 고쳐도 소용없다)";
		else if (rA <= kLoRatio)
			branch = (rB <= 0.5f) ? "㈁-세기 **세기가 큰 몫**(점수를 세기로 쓰는 것이 문제다)"
			                      : "㈁-선택 **선택이 큰 몫**(top-k 가 엉뚱한 유닛을 고른다)";
		else branch = "㈂ **둘 다** — 큰 쪽을 먼저 고친다";
		LogA("[mlt] 🔬   ⭐ 갈래 판정 = **%s**  (㉰/㉮ = %.2f · ㉯/㉮ = %.2f)\n",
			branch, (double)rA, (double)rB);
		LogA("[mlt] 🔬   ⚠️ 문턱 0.70/0.30 은 임의다 — 비율을 보고 읽어라(갈래는 방향만 준다)\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}
};
