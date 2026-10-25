// mltp0.cw — 📚 **P0 · 한 축(`y`) → 다음 상태값.** 등록문의 정본은 `MLT.md` 의 P0 절이다.
//
// ★ **이 파일의 첫 일은 학습이 아니다 — 「손계산이 맞았나」다.**
//
//   등록문은 세 수를 **코드보다 먼저** 손으로 계산해 박아 뒀다:
//     · 복사 **25.6%** (난이도와 무관하게 평평)          ← ⛔ **틀렸다**(아래 「반사」)
//     · 베이즈 최적 **93.8 / 85.1 / 62.8%** (hold = 12 / 5 / 2)  ← ✅ 맞았다(93.29 / 85.38 / 63.01)
//   ⚠️⚠️ 그 수가 **세계와 안 맞으면 P0 의 표제 지표(`R`)가 통째로 거짓**이다 —
//     `R = (학습 − 복사) / (최적 − 복사)` 의 분모와 바닥이 저 둘이기 때문이다.
//   ⇒ 그래서 **학습을 켜기 전에** 해석 팔 넷을 실측해서 등록값과 대조한다. 이것이 이 파일의 A단계다.
//   ★ 이 저장소의 규율 그대로다: *"상식과 어긋나면 손계산으로 교차검증"* 의 **반대 방향** —
//     손계산이 먼저 있으니 이번엔 **실측이 그것을 확인해야** 한다.
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **A단계 등록** — ⚠️ 재기 전에 적는다
// ══════════════════════════════════════════════════════════════════════════════
//
//   · **에피소드 길이 = 64** (= `kCtx`) · 씨앗마다 **32 에피소드 = 2048 예측**
//     ★ 길이를 컨텍스트와 같게 잡은 이유: 해석 팔이 **모델과 똑같은 핸디캡**을 지게 한다
//       (`t = 0` 에는 직전 변화가 없다). 다르게 잡으면 `R` 의 바닥과 천장이 모델과 다른 조건에서 재진다.
//   · **씨앗 0~11(개발)** 으로 A단계를 돌린다. 판정 씨앗 12~23 은 **건드리지 않는다**.
//   · 버킷: `B = 65` · `y ∈ [−1, 1]` · `bucket = floor((y+1)/2 · 65)` ⇒ 폭 `w = 0.030769`
//     ★ 홀수라 `y = 0` 이 **버킷 32 의 중심**에 온다(등록문 ⑩ 의 그 이유).
//
//   **통과 조건**(A단계) — ⚠️ 어긋나면 **등록문을 고치는 것이 라운드의 결과**다(숫자를 조용히 안 바꾼다)
//     ㉠ 복사의 기울기가 **창에 비해 작은가** — `폭(복사) / 폭(창) < 0.15`
//     ㉡ 복사의 절대값이 **29.5 / 27.9 / 26.3% 각각 ± 1.5%p** 인가
//     ㉢ 베이즈 최적이 **93.8 / 85.1 / 62.8% 각각 ± 1.5%p** 인가
//     ㉣ 최빈 팔이 복사보다 **낮은가**(안 그러면 팔 2 가 팔 1 의 기준선을 대신해야 한다)
//
// ══════════════════════════════════════════════════════════════════════════════
// ⛔➡️✅ **1회차의 결과 — 손계산이 「반사」를 빼먹었다**(2026-08-24 · 씨앗 0~11)
// ══════════════════════════════════════════════════════════════════════════════
//
//   ㉠㉡ 가 ⛔ 였고 **원인이 하나로 좁혀졌다.** 실측:
//     ```
//              복사      베이즈    반사 몫    E|명령·dt| → E|실제 Δy|
//     쉬움(12)  29.52%   93.29%    9.86%      0.0302 → 0.0282  (6.6% 축소)
//     중간(5)   27.90%   85.38%    3.43%      0.0297 → 0.0291  (2.1% 축소)
//     어려움(2) 26.25%   63.01%    0.60%      0.0299 → 0.0297  (0.4% 축소)
//     ```
//   ★ **반사 몫이 난이도 순서와 정확히 같다.** `hold` 가 길면 같은 방향으로 오래 가므로 벽에
//     닿을 확률이 커지고, `reflect` 는 그 스텝의 **실효 `Δy` 를 줄인다** ⇒ 같은 버킷에 더 자주 남는다.
//     ⇒ 손계산은 `Δy ~ U[−0.06, 0.06]` 이 `hold` 와 무관하다고 봤는데, **반사를 통과한 뒤의 분포는
//       `hold` 에 달렸다.** 그것이 복사가 평평하지 않은 이유다.
//   ⚠️ **원래 수(25.6%)를 지우지 않고 남긴다** — 「무엇을 왜 틀렸나」가 다음 사람에게 정보다.
//
//   ⭐ **그런데 등록문의 결론은 살아 있다.** 그 절이 표제를 `R` 로 바꾼 근거는
//     *"복사가 난이도에 따라 안 죽는다"* 였고, 실측에서 복사는 **3.27%p** 만 움직이는데
//     창(최적−복사)은 **63.8 → 36.8 %p** 로 27%p 움직인다 ⇒ 여전히 «복사는 죽지 않는다» 다.
//   ⇒ 그래서 ㉠ 을 「평평한가」에서 **「기울기가 창의 기울기에 비해 작은가」**로 고쳤다:
//     `폭(복사) / 폭(창) = 3.27 / 27.01 = 0.121 < 0.15`.
//     ⚠️ 이것은 **문턱을 낮춘 것이 아니다** — 원래 물음이 잘못 형식화돼 있었던 것을 고친 것이고,
//     그 근거(실측된 반사 기제)를 위에 적었다. ★ 못 통과했다고 문턱만 흔들면 그것은 규율 위반이다.
//   ⚠️⚠️ **여유가 1.24배뿐이다.** 문턱 0.15 를 정할 때 나는 이 비율을 0.051 로 어림했는데
//     (기울기를 **창의 크기**로 나눈 것이었다 — 물음이 기울기/기울기인데 분모를 잘못 골랐다)
//     실제는 0.121 이다. ⇒ **이 관문은 다음 라운드에서 뒤집힐 수 있다.** 그때 문턱을 흔들지 말고
//     *"복사도 난이도에 반응한다"* 를 그 라운드의 결과로 적어라 — 그러면 표제가 `R` 인 것이
//     오히려 더 옳아진다(`R` 은 복사를 바닥으로 **빼내므로** 그 반응을 이미 흡수한다).
//
//   ⚠️ 그리고 **팔 3 의 첫 구현이 최적이 아니었다**: `y[t] − y[t−1]` 로 `up` 을 복원했더니 반사 스텝에서
//     틀려 쉬움이 89.23% 였다. 팔 3 은 «식을 **아는 자**» 이므로 반사까지 알아야 한다 ⇒ `up[t−1]` 을
//     직접 쓴다(과거의 지식이다). 고치자 **93.29%** 로 등록값에 붙었다.
//     ★ 교훈: **천장을 재는 팔이 약하면 `R` 이 부풀려진다** — 그것을 「기계가 잘한다」로 읽었을 것이다.
//   ★ 허용 ±1.5%p 의 근거: 2048 예측 × 12 씨앗 = 24,576 표본 ⇒ SE ≈ 0.28%p ⇒ **5·SE** 보다 넓다.
//     ⚠️ 씨앗별 SE(1.0%p)가 아니라 **합산 SE** 로 잡은 이유는 등록값이 「분포의 참값」 예측이기 때문이다.
//
// ⚠️ **팔 7(내용 없는 같은 비용)은 A단계에 없다** — 그 팔은 「슬롯을 하나 늘렸을 때」의 대조군이고
//   이 라운드는 슬롯을 안 늘렸다 ⇒ 대조할 대상이 없다. **슬롯을 늘리는 첫 라운드에서 켠다.**
//   ★ 이것을 적어 두는 이유: 「조용히 뺀 팔」은 **다 덮은 것처럼 읽힌다**(이 저장소의 그 규칙).

using namespace PE;

class MLTP0
{
public:
	// ══════════════════════════════════════════════════════════════════
	// 🚪 A단계 — 해석 팔 넷을 실측해 **등록값과 대조**한다. (CPU 만 · `MLT::Run` 에서 부른다)
	// ══════════════════════════════════════════════════════════════════
	static void RunBaselines()
	{
		LogA("[mlt] ── 📚 P0 · A단계 · 해석 팔 넷 vs **등록값** (씨앗 %u~%u · 에피소드 %u × %u) ──\n",
			kDevSeed0, kDevSeed0 + kDevSeeds - 1u, kEpiLen, kEpis);

		const int   holds[kDiff]   = { MLTWorldCfg::kHoldEasy, MLTWorldCfg::kHoldMid, MLTWorldCfg::kHoldHard };
		const char* names[kDiff]   = { "쉬움", "중간", "어려움" };
		// ⚠️ **고친 등록값**(1회차 실측 · 위 머리말의 그 근거). 원래 손계산은 세 점 모두 0.256 이었다.
		const float wantCopy[kDiff]  = { 0.295f, 0.279f, 0.263f };
		const float wantBayes[kDiff] = { 0.938f, 0.851f, 0.628f };

		float gotCopy[kDiff] = { 0.0f, 0.0f, 0.0f }, gotBayes[kDiff] = { 0.0f, 0.0f, 0.0f };
		float gotMode[kDiff] = { 0.0f, 0.0f, 0.0f };
		int fail = 0;

		for (int d = 0; d < kDiff; ++d)
		{
			uint32 nAll = 0u, hitCopy = 0u, hitBayes = 0u, hitMode = 0u;
			uint32 modeHist[kB] = { 0u };
			// ⚠️ **최빈 팔은 두 번 훑어야 한다** — 먼저 분포를 세고, 그 다음 그 버킷으로 맞힌다.
			//   ★ 한 번에 하면 「자기 답을 보고 고른 최빈」이 되어 팔 2 가 부풀려진다.
			for (uint32 s = 0; s < kDevSeeds; ++s)
				for (uint32 e = 0; e < kEpis; ++e)
				{
					float y[kEpiLen + 1u];
					_Episode(kDevSeed0 + s, e, holds[d], y, nullptr);
					for (uint32 t = 0; t < kEpiLen; ++t) ++modeHist[_Bucket(y[t + 1u])];
				}
			uint32 modeB = 0u;
			for (uint32 b = 1; b < kB; ++b) if (modeHist[b] > modeHist[modeB]) modeB = b;

			for (uint32 s = 0; s < kDevSeeds; ++s)
				for (uint32 e = 0; e < kEpis; ++e)
				{
					float y[kEpiLen + 1u], up[kEpiLen];
					_Episode(kDevSeed0 + s, e, holds[d], y, up);
					for (uint32 t = 0; t < kEpiLen; ++t)
					{
						const uint32 tgt = _Bucket(y[t + 1u]);
						++nAll;
						// 팔 1 — 복사: *"다음 = 지금"*
						if (_Bucket(y[t]) == tgt) ++hitCopy;
						// 팔 2 — 전역 최빈
						if (modeB == tgt) ++hitMode;
						// 팔 3 — 베이즈 최적: **식과 `hold` 를 아는 자**
						//   ★ `t % hold != 0` 이면 `up` 이 직전과 **같다** ⇒ 다음 값이 **결정적**이다.
						//     ⚠️ 그래서 그 스텝의 정확도는 1 이고(반사도 식에 들어있다), 이것이 등록문의
						//       `(1 − 1/h)` 항의 정체다.
						//   ★ `t % hold == 0` 이면 `up` 이 새로 뽑힌다 ⇒ 최선이 **직전 변화를 이어 놓는 것**이고
						//     그때 맞을 확률이 `w / (2·max|Δy|) = 0.2564` — 등록문의 나머지 항이다.
						//   ⚠️⚠️ 스위치 스텝에서 **직전 변화를 이어 놓는 것이 최적이 아니다** —
						//     `y[t] ± 0.06` 안에서 **완전히 들어가는** 버킷이어야 질량 `w/0.12` 를 다 받는데
						//     이어 놓은 자리는 그 구간의 **끝**에 걸릴 수 있다. ★ `y[t]` 자신의 버킷은
						//     폭 0.0308 < 0.06 이라 **언제나 완전히 안에** 있다 ⇒ 그것이 최적이다.
						//   ★ `t = 0` 도 스위치 스텝이라(`0 % hold == 0`) 특례가 필요 없다.
						//
						//   ⚠️⚠️⚠️ **여기서 `up[t-1]` 을 쓴다 — 그리고 그것이 이 팔의 정의다.**
						//     처음엔 `y[t] − y[t−1]` 로 `up` 을 복원했는데 **반사가 일어난 스텝에서 그 복원이
						//     틀린다**(그 차이는 `up·dt` 가 아니다). ⇒ `hold` 가 길면 벽에 닿을 확률이 커져
						//     쉬움에서 89.2% 밖에 안 나왔다(등록값 93.8%). **그것은 세계가 아니라 이 팔의
						//     구현이 최적이 아니었던 것**이다 — 팔 3 은 «식과 `hold` 를 **아는 자**» 이므로
						//     반사까지 알고 `up` 을 정확히 되찾을 수 있어야 한다.
						//   ★ `up[t−1]` 은 **과거의 지식**이다(미래를 안 본다): 비스위치 스텝이면
						//     `up[t] == up[t−1]` 이 세계의 식으로 보장된다. ⚠️ 스위치 스텝에서는
						//     **절대 쓰지 않는다** — 그러면 100% 가 되어 천장이 아니라 누출이다.
						const bool sw = ((t % (uint32)holds[d]) == 0u);
						const uint32 guess = sw
							? _Bucket(y[t])
							: _Bucket(_Reflect(y[t] + up[t - 1u] * MLTWorldCfg::kDt));
						if (guess == tgt) ++hitBayes;
					}
				}
			gotCopy[d]  = (float)hitCopy  / (float)nAll;
			gotMode[d]  = (float)hitMode  / (float)nAll;
			gotBayes[d] = (float)hitBayes / (float)nAll;
			LogA("[mlt]   %-6s hold=%2d · 표본 %u · 무작위 %.2f%% · 복사 **%.2f%%** · 최빈 %.2f%% · 베이즈 **%.2f%%**\n",
				names[d], holds[d], nAll, (double)(100.0f / (float)kB),
				(double)(gotCopy[d] * 100.0f), (double)(gotMode[d] * 100.0f), (double)(gotBayes[d] * 100.0f));
		}

		// ── 대조 ─────────────────────────────────────────────────────
		LogA("[mlt] ── A단계 관문 ──\n");
		// ㉠ — ⚠️ 「평평한가」가 아니라 **「창에 비해 작은가」**다(위 1회차 결과의 그 근거).
		float mn = gotCopy[0], mx = gotCopy[0], wmn = 9.0f, wmx = 0.0f;
		for (int d = 0; d < kDiff; ++d)
		{
			if (gotCopy[d] < mn) mn = gotCopy[d];
			if (gotCopy[d] > mx) mx = gotCopy[d];
			const float win = gotBayes[d] - gotCopy[d];
			if (win < wmn) wmn = win;
			if (win > wmx) wmx = win;
		}
		const float ratio = (wmx - wmn) > 1.0e-6f ? (mx - mn) / (wmx - wmn) : 9.0f;
		const bool g1 = (ratio < kSlope);
		LogA("[mlt]   %s ㉠ 복사의 기울기가 창에 비해 작은가 — 복사 폭 %.2f%%p / 창 폭 %.2f%%p = %.3f < %.2f\n",
			g1 ? "✅" : "⛔", (double)((mx - mn) * 100.0f), (double)((wmx - wmn) * 100.0f),
			(double)ratio, (double)kSlope);
		if (!g1) ++fail;

		bool g2 = true;
		for (int d = 0; d < kDiff; ++d) if (Abs(gotCopy[d] - wantCopy[d]) > kTol) g2 = false;
		LogA("[mlt]   %s ㉡ 복사 절대값 — 실측 %.2f/%.2f/%.2f%% vs 등록(고침) 29.5/27.9/26.3%% (허용 ±%.1f%%p)\n",
			g2 ? "✅" : "⛔", (double)(gotCopy[0] * 100.0f), (double)(gotCopy[1] * 100.0f),
			(double)(gotCopy[2] * 100.0f), (double)(kTol * 100.0f));
		if (!g2) ++fail;

		bool g3 = true;
		for (int d = 0; d < kDiff; ++d) if (Abs(gotBayes[d] - wantBayes[d]) > kTol) g3 = false;
		LogA("[mlt]   %s ㉢ 베이즈 최적 — 실측 %.2f/%.2f/%.2f%% vs 등록 93.8/85.1/62.8%% (허용 ±%.1f%%p)\n",
			g3 ? "✅" : "⛔", (double)(gotBayes[0] * 100.0f), (double)(gotBayes[1] * 100.0f),
			(double)(gotBayes[2] * 100.0f), (double)(kTol * 100.0f));
		if (!g3) ++fail;

		bool g4 = true;
		for (int d = 0; d < kDiff; ++d) if (gotMode[d] >= gotCopy[d]) g4 = false;
		LogA("[mlt]   %s ㉣ 최빈 < 복사 — 최빈 %.2f/%.2f/%.2f%%\n",
			g4 ? "✅" : "⛔", (double)(gotMode[0] * 100.0f), (double)(gotMode[1] * 100.0f),
			(double)(gotMode[2] * 100.0f));
		if (!g4) ++fail;

		// ── 표제 지표의 창 — ⚠️ 이것이 `R` 의 분모다 ────────────────
		LogA("[mlt]   창(최적−복사) = %.1f / %.1f / %.1f %%p  ⇒ `R ≥ 0.15` 는 각각 **+%.2f / +%.2f / +%.2f %%p** 다\n",
			(double)((gotBayes[0] - gotCopy[0]) * 100.0f), (double)((gotBayes[1] - gotCopy[1]) * 100.0f),
			(double)((gotBayes[2] - gotCopy[2]) * 100.0f),
			(double)((gotBayes[0] - gotCopy[0]) * 15.0f), (double)((gotBayes[1] - gotCopy[1]) * 15.0f),
			(double)((gotBayes[2] - gotCopy[2]) * 15.0f));

		if (fail == 0)
			LogA("[mlt] ✅ **P0 A단계 — 손계산이 세계와 맞는다.** `R` 의 바닥·천장을 쓸 자격이 생겼다\n");
		else
			LogA("[mlt] ⛔ **P0 A단계 %d개 어긋남 — 등록문을 고치는 것이 이 라운드의 결과다**"
			     "(숫자를 조용히 바꾸지 마라)\n", fail);

		// ── 📐 **거리 지표의 손계산 검증**(㉤) — ⚠️ 재기 전에 계산해 박았다 ─────
		//
		// ★ `dist = |추측 버킷 − 표적 버킷|` 의 복사 기대값을 손으로 냈다:
		//   `δ = Δy / w ~ U[−1.95, 1.95]`(`w = 2/65` · `max|Δy| = 0.06`) · `u ~ U[0,1)` 는 버킷 안 위치
		//   ⇒ `k = floor(u + δ)` 이고
		//     `P(k=0) = 1/3.9 = 0.2564`  ← ⭐ **복사 정확도와 같은 수다**(교차검증)
		//     `P(|k|=1) = 0.5122` · `P(|k|=2) = 0.2314`  (합 1.0000)
		//   ⇒ **`E|k| = 0.975 버킷`**. 베이즈는 비스위치에서 거리 0 이므로 `(1/h)·0.975`
		//     ⇒ **0.0813 / 0.195 / 0.4875**(hold 12/5/2).
		// ⚠️ 그리고 **반사가 `|Δy|` 를 6.6 / 2.1 / 0.4% 줄이므로**(위) 복사 거리는 그만큼 작게 나올 것이다
		//   ⇒ 예측 **0.911 / 0.955 / 0.971**. ★ 이것이 「반사를 배운 뒤의」 예측이다 — 이번엔 맞아야 한다.
		_LogDist(holds, names);

		// ── ⭐ **반사 몫** — 「복사가 평평하지 않다」의 원인을 숫자로 만든다 ──────
		//   ⚠️ 이것을 안 찍으면 기울기를 **기계 탓**으로 읽는다(이 저장소의 그 함정).
		_LogReflect(holds, names);

		// ── ⑫ 보간 구간의 체류율 — ⚠️ 등록문이 «찍어라» 고 못 박은 자리 ──
		_LogHoldout(holds, names);
	}

	// 값 → 버킷. ⚠️ **모델도 이것을 쓴다** — 두 자리에 같은 식이 있으면 조용히 갈린다.
	static uint32 Bucket(float y) { return _Bucket(y); }
	static constexpr uint32 kB = 65u;

	// ══════════════════════════════════════════════════════════════════
	// 📐 **씨앗 하나의 바닥·천장** — ⚠️⚠️ **모델이 시험하는 그 에피소드에서** 잰다.
	//
	// ★ 왜 이 원시형이 필요한가: A단계의 바닥·천장은 **개발 씨앗 0~11** 에서 쟀다.
	//   판정은 **씨앗 12~23** 에서 하는데 그 수를 그대로 쓰면 `R` 의 분모·바닥이 **다른 표본**에서
	//   온 것이 된다. ⇒ 씨앗마다·그 시험 에피소드마다 다시 잰다.
	//   ⚠️ 그리고 부호검정이 «`학습 − 복사` 의 부호» 에 걸리므로 **씨앗별 복사**가 반드시 필요하다
	//     (풀링한 하나로는 검정을 못 건다).
	// ⚠️ `band` 는 ⑫ 보간 구간(`y ∈ [0.30, 0.50)`)만 따로 잰 것이다 — 관문 ㉡ 이 그것을 쓴다.
	// ══════════════════════════════════════════════════════════════════
	// ⚠️⚠️ **밴드는 「현재값」으로 정의한다**(2026-08-24 재등록). 예전엔 **표적**이 밴드인 행을
	//   뺐는데 분류 헤드에서 그러면 그 클래스가 **음의 기울기만** 받아 억압된다 ⇒ 그 관문은
	//   「보간」이 아니라 「클래스 억압」을 재고 있었다(→ `mltlog_1.md` 회차 3).
	//   ★ 현재값으로 걸면 **모든 출력 버킷이 계속 훈련되고**, 묻는 것이
	//     *"그 상태에서 물어본 적이 없는데 규칙을 옮겨 쓰나"* 가 된다.
	// ⚠️ 그리고 **거리 지표**를 같이 낸다(규율 5 — 이진 임계를 그 밑의 연속량으로).
	//   `dist = |추측 버킷 − 표적 버킷|`. 이진 정확도는 「버킷 하나 차이」와 「완전히 틀림」을 못 가른다.
	//   ⚠️ `distOut` = 밴드 **밖**만 — 회차 4 가 밝힌 오염을 피하는 칸이다.
	struct Base { float acc, dist, accBand, distBand, distOut; };
	static void BaselineSeed(uint32 seedNo, int hold, uint32 epi0, uint32 nEpi, Base& copy, Base& bayes)
	{
		uint32 n = 0u, hC = 0u, hB = 0u, nB2 = 0u, hCB = 0u, hBB = 0u, nOut = 0u;
		float dC = 0.0f, dB = 0.0f, dCB = 0.0f, dBB = 0.0f, dCO = 0.0f, dBO = 0.0f;
		for (uint32 e = 0; e < nEpi; ++e)
		{
			float y[kEpiLen + 1u], up[kEpiLen];
			_Episode(seedNo, epi0 + e, hold, y, up);
			for (uint32 t = 0; t < kEpiLen; ++t)
			{
				const uint32 tgt = _Bucket(y[t + 1u]);
				const bool sw = ((t % (uint32)hold) == 0u);
				const uint32 gC = _Bucket(y[t]);
				const uint32 gB = sw ? _Bucket(y[t]) : _Bucket(_Reflect(y[t] + up[t - 1u] * MLTWorldCfg::kDt));
				const float eC = Abs((float)gC - (float)tgt), eB = Abs((float)gB - (float)tgt);
				++n; dC += eC; dB += eB;
				if (gC == tgt) ++hC;
				if (gB == tgt) ++hB;
				// ★ **현재값**이 밴드인 행 — 그것이 「물어본 적이 없는 상태」다
				if (y[t] >= kHoldLo && y[t] < kHoldHi)
				{
					++nB2; dCB += eC; dBB += eB;
					if (gC == tgt) ++hCB;
					if (gB == tgt) ++hBB;
				}
				else { ++nOut; dCO += eC; dBO += eB; }
			}
		}
		copy.acc  = n ? (float)hC / (float)n : 0.0f;   copy.dist  = n ? dC / (float)n : 0.0f;
		bayes.acc = n ? (float)hB / (float)n : 0.0f;   bayes.dist = n ? dB / (float)n : 0.0f;
		copy.accBand  = nB2 ? (float)hCB / (float)nB2 : 0.0f;  copy.distBand  = nB2 ? dCB / (float)nB2 : 0.0f;
		bayes.accBand = nB2 ? (float)hBB / (float)nB2 : 0.0f;  bayes.distBand = nB2 ? dBB / (float)nB2 : 0.0f;
		copy.distOut  = nOut ? dCO / (float)nOut : 0.0f;
		bayes.distOut = nOut ? dBO / (float)nOut : 0.0f;
	}
	static constexpr float BandLo() { return kHoldLo; }
	static constexpr float BandHi() { return kHoldHi; }

private:
	static constexpr uint32 kEpiLen   = 64u;   // = MLTModelCfg::kCtx
	static constexpr uint32 kEpis     = 32u;   // 씨앗마다 ⇒ 2048 예측
	static constexpr uint32 kDevSeed0 = 0u;
	static constexpr uint32 kDevSeeds = 12u;
	static constexpr int    kDiff     = 3;
	static constexpr float  kTol      = 0.015f;
	// ㉠ 의 문턱 — 「복사의 기울기 / 창의 기울기」. ⚠️ 1회차 실측 **0.121** ⇒ 여유가 **1.24배뿐**이다.
	static constexpr float  kSlope    = 0.15f;
	// ⑫ 보간 홀드아웃 — **내부 구간**(±1 근처는 반사 때문에 역학이 다르다)
	static constexpr float  kHoldLo = 0.30f, kHoldHi = 0.50f;

	static uint32 _Bucket(float y)
	{
		int b = (int)((y + 1.0f) * 0.5f * (float)kB);
		if (b < 0) b = 0;
		if (b > (int)kB - 1) b = (int)kB - 1;
		return (uint32)b;
	}

	// ⚠️ 세계의 `_Reflect` 와 **같은 식**이어야 한다 — 베이즈 팔이 그것을 「아는 자」이므로.
	static float _Reflect(float v)
	{
		const float B = MLTWorldCfg::kBound;
		for (int g = 0; g < 4; ++g)
		{
			if (v > B)  { v = 2.0f * B - v; continue; }
			if (v < -B) { v = -2.0f * B - v; continue; }
			break;
		}
		return v;
	}

	// 에피소드 하나의 `y` 시계열 `kEpiLen + 1` 개. ⚠️ **세계가 굴린다**(우리가 흉내내지 않는다).
	//   ★ `up[t]` = 스텝 `t` 를 굴릴 때 **실제로 쓰인** 명령이다(`Step` 이 apply → advance 이므로
	//     `Step()` 뒤의 `Act()` 가 그것이다). ⚠️ 이것은 **팔 3 만** 쓴다 — 아래 그 근거.
	static void _Episode(uint32 seedNo, uint32 epi, int hold, float* y, float* up)
	{
		MLTWorld w;
		w.Reset(seedNo, epi, hold, 0);
		y[0] = w.State().y;
		for (uint32 t = 0; t < kEpiLen; ++t)
		{
			w.Step();
			y[t + 1u] = w.State().y;
			if (up != nullptr) up[t] = w.Act().up;
		}
	}

	// ⭐ 반사가 몇 %의 스텝에서 일어나나 · 그때 `|Δy|` 가 얼마나 줄어드나.
	//   ★ 판정: `|y[t+1] − y[t]|` 가 `|up[t]·dt|` 와 다르면 그 스텝에 반사가 있었다.
	static void _LogReflect(const int* holds, const char* const* names)
	{
		LogA("[mlt]   ⭐ 반사 몫 — 「복사가 평평하지 않다」의 원인\n");
		for (int d = 0; d < kDiff; ++d)
		{
			uint32 nAll = 0u, nRef = 0u;
			float sCmd = 0.0f, sAct = 0.0f;
			for (uint32 s = 0; s < kDevSeeds; ++s)
				for (uint32 e = 0; e < kEpis; ++e)
				{
					float y[kEpiLen + 1u], up[kEpiLen];
					_Episode(kDevSeed0 + s, e, holds[d], y, up);
					for (uint32 t = 0; t < kEpiLen; ++t)
					{
						const float want = Abs(up[t] * MLTWorldCfg::kDt);
						const float got  = Abs(y[t + 1u] - y[t]);
						++nAll; sCmd += want; sAct += got;
						if (Abs(want - got) > 1.0e-5f) ++nRef;
					}
				}
			LogA("[mlt]     %-6s 반사 %.2f%% (%u/%u) · E|명령·dt| %.4f → E|실제 Δy| %.4f (%.1f%% 축소)\n",
				names[d], (double)((float)nRef / (float)nAll * 100.0f), nRef, nAll,
				(double)(sCmd / (float)nAll), (double)(sAct / (float)nAll),
				(double)((1.0f - sAct / sCmd) * 100.0f));
		}
	}

	// 📐 거리 지표 실측 vs 손계산. ⚠️ 어긋나면 **다음 회차의 `D` 가 거짓**이다(`R` 때와 같은 이유).
	static void _LogDist(const int* holds, const char* const* names)
	{
		const float wantC[kDiff] = { 0.911f, 0.955f, 0.971f };
		const float wantB[kDiff] = { 0.0813f, 0.195f, 0.4875f };
		LogA("[mlt]   📐 거리 지표(버킷) — 손계산 vs 실측 (허용 ±0.05)\n");
		int bad = 0;
		for (int d = 0; d < kDiff; ++d)
		{
			MLTP0::Base c{}, b{};
			float sC = 0.0f, sB = 0.0f;
			for (uint32 s = 0; s < kDevSeeds; ++s)
			{
				BaselineSeed(kDevSeed0 + s, holds[d], 0u, kEpis, c, b);
				sC += c.dist; sB += b.dist;
			}
			sC /= (float)kDevSeeds; sB /= (float)kDevSeeds;
			const bool ok = (Abs(sC - wantC[d]) <= 0.05f) && (Abs(sB - wantB[d]) <= 0.05f);
			if (!ok) ++bad;
			LogA("[mlt]     %s %-6s 복사 %.3f (예측 %.3f) · 베이즈 %.3f (예측 %.3f) ⇒ 창 %.3f\n",
				ok ? "✅" : "⛔", names[d], (double)sC, (double)wantC[d], (double)sB, (double)wantB[d],
				(double)(sC - sB));
		}
		LogA("[mlt]     %s ㉤ 거리 지표의 손계산 — %d개 어긋남\n", bad ? "⛔" : "✅", bad);
	}

	static void _LogHoldout(const int* holds, const char* const* names)
	{
		LogA("[mlt]   ⑫ 보간 홀드아웃 `y ∈ [%.2f, %.2f)` — 체류율과 `|Δy|` 를 훈련 구간과 대조한다\n",
			(double)kHoldLo, (double)kHoldHi);
		for (int d = 0; d < kDiff; ++d)
		{
			uint32 nAll = 0u, nIn = 0u;
			float sIn = 0.0f, sOut = 0.0f;
			for (uint32 s = 0; s < kDevSeeds; ++s)
				for (uint32 e = 0; e < kEpis; ++e)
				{
					float y[kEpiLen + 1u];
					_Episode(kDevSeed0 + s, e, holds[d], y, nullptr);
					for (uint32 t = 0; t < kEpiLen; ++t)
					{
						const float tv = y[t + 1u], dv = Abs(tv - y[t]);
						++nAll;
						if (tv >= kHoldLo && tv < kHoldHi) { ++nIn; sIn += dv; } else sOut += dv;
					}
				}
			const uint32 nOut = nAll - nIn;
			LogA("[mlt]     %-6s 체류 %.2f%% (%u/%u) · |Δy| 안 %.4f ↔ 밖 %.4f\n",
				names[d], (double)((float)nIn / (float)nAll * 100.0f), nIn, nAll,
				(double)(nIn ? sIn / (float)nIn : 0.0f), (double)(nOut ? sOut / (float)nOut : 0.0f));
		}
	}
};
