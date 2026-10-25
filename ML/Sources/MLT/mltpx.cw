// mltpx.cw — 🔗 **회차 17 · 얽힌 축(x·z).** 「규칙이 **다른 형태의** 축에도 서나」 + ⭐ **비대각 기제 예측**
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문** — ⚠️ 재기 전에 적는다
// ══════════════════════════════════════════════════════════════════════════════
//
// ★ **무엇을 묻나**
//
//   P1 의 세 축(y·yaw·pitch)은 전부 **독립 1D** 였다 — 각 축의 다음 값이 그 축과 그 축의 명령만의
//   함수였다. 세계에는 **얽힌 축**이 있다:
//   ```
//   x[t+1] = reflect(x[t] + (fwd·sin(π·yaw[t]) + side·cos(π·yaw[t]))·dt)
//   z[t+1] = reflect(z[t] + (fwd·cos(π·yaw[t]) − side·sin(π·yaw[t]))·dt)
//   ```
//   ⇒ **x 의 다음 값이 yaw 의 「값」에 걸려 있다.** 축이 서로 다른 「형태」다.
//   물음 둘:
//   ㈀ 얽힌 역학도 복사↔베이즈 창의 상당분을 먹나(`R̄ ≥ 0.15`)
//   ㈁ ⭐ **기제가 얽힘을 따라가나** — x 표적의 손실이 **yaw 슬롯의 값**에 민감해야 한다.
//     P1 에서 대각 몫이 99% 였던 그 진단이, 여기서는 **비대각을 예측**한다. 처음으로
//     「기제 관문」이 **양의 비대각**을 요구하는 자리다.
//
// ══════════════════════════════════════════════════════════════════════════════
// ① 축 셋 — ⚠️ 모델은 그대로다(kAxes=3 · kCtx=96 · **모델 변경 0**)
// ══════════════════════════════════════════════════════════════════════════════
//   ```
//   축 0 : x    ← fwd·sy + side·cy   (얽힘)
//   축 1 : z    ← fwd·cy − side·sy   (얽힘 · x 와 같은 명령의 다른 회전)
//   축 2 : yaw  ← dYaw               (순수 1D — P1 에서 이미 섰다 · **닻**)
//   ```
//   ★ yaw 를 넣는 이유 둘: ㈀ x·z 의 규칙이 **yaw 값을 필요**로 한다(컨텍스트에 있어야 한다)
//     ㈁ 순수 1D 축이 하나 있어야 「얽힌 축이 안 서는 것」과 「전부 안 서는 것」이 갈린다.
//
// ══════════════════════════════════════════════════════════════════════════════
// ② 손계산 — ⚠️ **코드보다 먼저.** 그리고 근사가 P0 때보다 거칠다(그 사실도 등록한다)
// ══════════════════════════════════════════════════════════════════════════════
//   `Δx = 0.12·(f·s + 0.7·g·c)`, `f,g ~ U[−1,1)`, `s = sin(πyaw)`, `c = cos(πyaw)`.
//   주어진 yaw 에서 두 균등분포의 합(사다리꼴) ⇒ `p(0) = 1/(2·max(a,b))`,
//   `a = 0.12|s|`, `b = 0.084|c|` ⇒ `P(같은 버킷) ≈ w·p(0)` (`w = 0.030769 ≪ 산포`).
//   **yaw ~ 균등 가정**으로 수치적분(교차점 y₀ = atan(0.7)/π = 0.194):
//     `∫ sec` 항 0.0381 + `∫ csc` 항 0.0471 ⇒ 반구간 0.0851 ⇒ **copy(x) ≈ 17.0%**
//   ⇒ 등록값: **copy(x) = copy(z) ≈ 17.0%**(대칭) · **copy(yaw) ≈ 21.4%**(P1 손계산 그대로)
//     **베이즈 ≈ 0.8 + 0.2·copy = 83.4 / 83.4 / 84.3%**
//   ⚠️ 허용 **±3.0%p**(yaw 균등 가정 + w·p(0) 근사가 P0 의 정확 계산보다 거칠다 — 그 사실을 등록한다.
//     yaw 는 ±2.0%p — P1 실측이 이미 있다).
//   ★ **방향성 예측**: 반사 초과분이 `|Δ|` 순서 ⇒ **excess(x) > excess(yaw)** 그리고
//     **excess(z) > excess(yaw)** (max|Δx| ≈ 0.147 ≫ max|Δyaw| = 0.072).
//
//   **A단계 관문**
//     ㉠ copy 셋이 등록값 안인가(x·z ±3.0 · yaw ±2.0)
//     ㉡ 베이즈 셋이 등록값 ±3.0%p 안인가
//     ㉢ 반사 초과분 방향(x > yaw · z > yaw)
//   ⚠️ 어긋나면 등록문을 고치는 것이 라운드의 결과다(P0 회차 1 과 같은 계약).
//
// ══════════════════════════════════════════════════════════════════════════════
// ③ 판정 — 팔 둘 · 관문 다섯
// ══════════════════════════════════════════════════════════════════════════════
//   팔 4(학습 · 12씨앗) · 팔 5(값 섞기[가림] · 12씨앗 — ㉣ 판정불가 방지) = **24 실행 ≈3분**
//   ㉠ ★ 표제 — 축마다 `R̄ ≥ 0.15` · 부호검정(학습−복사_seed) **10/12**
//   ㉡ ⭐ **기제(비대각)** — 표적을 축 하나만 남긴 진단 패스(회차 7 의 그 배관)로 3×3 질량을 얻고:
//     · **yaw 는 대각** — `diag(yaw) ≥ 50%`(P1 과 같은 형식 · 순수 1D 니까)
//     · ⭐ **x 는 비대각** — `mass(yaw | x표적) > mass(z | x표적)` 부호검정 **10/12**
//       근거: x 의 규칙이 yaw 값을 **필요**로 하고 z 값은 **무관**하다. ⚠️ 우연이면 둘이 같다.
//     · 읽는 칸: `diag(x) < diag(yaw)` 인가(끼리 비교 — 관문 아님)
//   ㉣ 대조군 — 팔 5 ≤ 8.0% ㉤ 상한 — `R > 1` 없음 ㉢′ 배관 — probs 합 1.0 · 유한
//
//   ⚠️⚠️ **미리 적는 분기**
//     · ㉠✅ ㉡✅ ⇒ **규칙이 얽힌 형태에도 서고 기제가 얽힘을 따라간다** ⇒ P1 을 닫고 **P2**(비전)로.
//     · ㉠✅ ㉡⛔ ⇒ 성능은 서는데 기제가 안 보인다 ⇒ **판정불가**(성능이 좋아도 — 그 계약).
//     · ㉠⛔(x·z 만) ⇒ **얽힘이 벽이다** — yaw 대비 x·z 의 `R̄` 격차를 적고, 그것이 P1 의
//       다음 물음이 된다(⚠️ 크기를 키우지 않는다).
//
// ⚠️ 비용: A단계 CPU ≈초 단위 · 판정 24 실행 × 600스텝 ≈ **3분**.

using namespace PE;

class MLTPX
{
public:
	static constexpr uint32 kAxes = 3u;
	// 상태 색인: x=0 · z=2 · yaw=3 (`MLTState::Axis`)
	static constexpr int kStateIdx[kAxes] = { 0, 2, 3 };
	static const char* AxisName(uint32 a) { return (a == 0u) ? "x" : ((a == 1u) ? "z" : "yaw"); }

	// ══════════════════════════════════════════════════════════════════
	// 🚪 **A단계** — 손계산 vs 실측 (CPU 만 · `MLT::Run` 에서 부른다)
	// ══════════════════════════════════════════════════════════════════
	static void RunBaselines()
	{
		LogA("[mlt] ── 🔗 **회차 17 A단계** · 얽힌 축의 바닥·천장 vs 손계산 (씨앗 %u~%u) ──\n",
			kDevSeed0, kDevSeed0 + kDevSeeds - 1u);
		const float wantCopy[kAxes]  = { 0.170f, 0.170f, 0.214f };
		const float wantBayes[kAxes] = { 0.834f, 0.834f, 0.843f };
		const float tolC[kAxes] = { 0.030f, 0.030f, 0.020f };
		float gotC[kAxes] = { 0.0f }, gotB[kAxes] = { 0.0f }, ex[kAxes] = { 0.0f };
		float gotX[kAxes] = { 0.0f };
		for (uint32 a = 0; a < kAxes; ++a)
		{
			Base c{}, b{};
			Baseline(a, kDevSeed0, kDevSeeds, 0u, kEpis, c, b);
			gotC[a] = c.acc; gotB[a] = b.acc; ex[a] = c.acc - wantCopy[a];
			// ⭐ **눈먼 외삽 팔** — `bucket(reflect(v + (v[t] − v[t−1])))` · **yaw 를 안 본다.**
			//   ★ 회차 17 판정이 «x 표적의 yaw 질량 1%» 를 냈을 때 이 팔이 그것을 설명하는지 본다:
			//     모델의 정확도가 이 팔에 붙으면 «모델 = 축-국소 외삽» 이고,
			//     베이즈(=yaw 를 아는 자)와의 격차가 곧 **yaw 를 읽으면 벌 수 있는 몫**이다.
			gotX[a] = _BlindExtrap(a, kDevSeed0, kDevSeeds, 0u, kEpis);
			const float x2 = _BlindExtrap2(a, kDevSeed0, kDevSeeds, 0u, kEpis);
			LogA("[mlt]   %-4s 복사 **%.2f%%**(손계산 %.1f%% · 초과 %+.2f%%p) · ⭐ 눈먼외삽 **%.2f%%**"
			     " · ⭐ 2차눈먼 **%.2f%%** · 베이즈 **%.2f%%**(손계산 %.1f%%)\n",
				AxisName(a), (double)(c.acc * 100.0f), (double)(wantCopy[a] * 100.0f),
				(double)(ex[a] * 100.0f), (double)(gotX[a] * 100.0f), (double)(x2 * 100.0f),
				(double)(b.acc * 100.0f), (double)(wantBayes[a] * 100.0f));
		}
		int fail = 0;
		bool g1 = true;
		for (uint32 a = 0; a < kAxes; ++a) if (Abs(gotC[a] - wantCopy[a]) > tolC[a]) g1 = false;
		LogA("[mlt]   %s ㉠ 복사가 등록값 안인가(x·z ±3.0 · yaw ±2.0)\n", g1 ? "✅" : "⛔");
		if (!g1) ++fail;
		bool g2 = true;
		for (uint32 a = 0; a < kAxes; ++a) if (Abs(gotB[a] - wantBayes[a]) > 0.030f) g2 = false;
		LogA("[mlt]   %s ㉡ 베이즈가 등록값 ±3.0%%p 안인가\n", g2 ? "✅" : "⛔");
		if (!g2) ++fail;
		const bool g3 = (ex[0] > ex[2]) && (ex[1] > ex[2]);
		LogA("[mlt]   %s ㉢ 반사 초과분 방향 — x %+.2f · z %+.2f > yaw %+.2f %%p\n",
			g3 ? "✅" : "⛔", (double)(ex[0] * 100.0f), (double)(ex[1] * 100.0f), (double)(ex[2] * 100.0f));
		if (!g3) ++fail;
		LogA("[mlt]   창(베이즈−복사) = %.1f / %.1f / %.1f %%p\n",
			(double)((gotB[0] - gotC[0]) * 100.0f), (double)((gotB[1] - gotC[1]) * 100.0f),
			(double)((gotB[2] - gotC[2]) * 100.0f));
		if (fail == 0) LogA("[mlt] ✅ **회차 17 A단계 — 얽힌 축의 바닥·천장을 쓸 자격이 생겼다**\n");
		else           LogA("[mlt] ⛔ **회차 17 A단계 %d개 어긋남 — 등록문을 고치는 것이 결과다**\n", fail);
	}

	struct Base { float acc; };

	// ⭐ **2차 눈먼 외삽** — 여전히 그 축의 값만 보되 **곡률까지** 잇는다:
	//   `v + Δ + (Δ − Δ_prev)` (= 2차 외삽). ★ 회차 18 에서 씨앗 13 이 1차 천장을 넘자 잰 팔이다:
	//   yaw 드리프트가 hold 안에서 선형이라 `Δx` 가 **선형으로 흐르고**, 그 흐름은 **x 자신의
	//   역사에 있다** ⇒ yaw 를 안 읽고도 1차 천장을 넘을 수 있다. 이 팔이 그 상한을 잰다.
	static float _BlindExtrap2(uint32 axis, uint32 seed0, uint32 nSeed, uint32 epi0, uint32 nEpi)
	{
		uint32 n = 0u, hit = 0u;
		for (uint32 s = 0; s < nSeed; ++s)
			for (uint32 e = 0; e < nEpi; ++e)
			{
				Ep ep;
				_Episode(seed0 + s, epi0 + e, ep);
				const float* v = (axis == 0u) ? ep.x : ((axis == 1u) ? ep.z : ep.yw);
				for (uint32 t = 0; t < kTime; ++t)
				{
					const uint32 tgt = MLTP0::Bucket(v[t + 1u]);
					uint32 g;
					if (t == 0u)      g = MLTP0::Bucket(v[0]);
					else if (t == 1u) g = MLTP0::Bucket(_Refl(v[1] + (v[1] - v[0])));
					else
					{
						const float d1 = v[t] - v[t - 1u], d0 = v[t - 1u] - v[t - 2u];
						g = MLTP0::Bucket(_Refl(v[t] + d1 + (d1 - d0)));
					}
					++n;
					if (g == tgt) ++hit;
				}
			}
		return n ? (float)hit / (float)n : 0.0f;
	}

	// ⭐ 눈먼 외삽 — 그 축의 값 **만** 본다(직전 차이를 잇는다 · yaw 도 명령도 안 본다).
	static float _BlindExtrap(uint32 axis, uint32 seed0, uint32 nSeed, uint32 epi0, uint32 nEpi)
	{
		uint32 n = 0u, hit = 0u;
		for (uint32 s = 0; s < nSeed; ++s)
			for (uint32 e = 0; e < nEpi; ++e)
			{
				Ep ep;
				_Episode(seed0 + s, epi0 + e, ep);
				const float* v = (axis == 0u) ? ep.x : ((axis == 1u) ? ep.z : ep.yw);
				for (uint32 t = 0; t < kTime; ++t)
				{
					const uint32 tgt = MLTP0::Bucket(v[t + 1u]);
					const uint32 g = (t == 0u) ? MLTP0::Bucket(v[0])
						: MLTP0::Bucket(_Refl(v[t] + (v[t] - v[t - 1u])));
					++n;
					if (g == tgt) ++hit;
				}
			}
		return n ? (float)hit / (float)n : 0.0f;
	}

	// 축 하나의 바닥·천장. ⚠️ 오라클은 「식과 명령을 아는 자」다 — 비스위치 스텝에서
	//   `x[t+1]` 이 **완전히 결정적**이다(yaw[t] 는 관측값 · fwd/side 는 지난 명령이 유지된다).
	static void Baseline(uint32 axis, uint32 seed0, uint32 nSeed, uint32 epi0, uint32 nEpi,
		Base& copy, Base& bayes)
	{
		uint32 n = 0u, hC = 0u, hB = 0u;
		for (uint32 s = 0; s < nSeed; ++s)
			for (uint32 e = 0; e < nEpi; ++e)
			{
				Ep ep;
				_Episode(seed0 + s, epi0 + e, ep);
				const float* v = (axis == 0u) ? ep.x : ((axis == 1u) ? ep.z : ep.yw);
				for (uint32 t = 0; t < kTime; ++t)
				{
					const uint32 tgt = MLTP0::Bucket(v[t + 1u]);
					const uint32 gC = MLTP0::Bucket(v[t]);
					const bool sw = ((t % (uint32)kHold) == 0u);
					uint32 gB;
					if (sw) gB = gC;
					else if (axis == 2u)
						gB = MLTP0::Bucket(_Refl(v[t] + ep.dyw[t - 1u] * MLTWorldCfg::kDt));
					else
					{
						// ⭐ 얽힌 축의 오라클 — `yaw[t]`(관측) + 지난 명령으로 다음 값이 결정된다.
						const float sy = Sin(ep.yw[t] * 3.14159265f), cy = Cos(ep.yw[t] * 3.14159265f);
						const float d = (axis == 0u)
							? (ep.fw[t - 1u] * sy + ep.sd[t - 1u] * cy)
							: (ep.fw[t - 1u] * cy - ep.sd[t - 1u] * sy);
						gB = MLTP0::Bucket(_Refl(v[t] + d * MLTWorldCfg::kDt));
					}
					++n;
					if (gC == tgt) ++hC;
					if (gB == tgt) ++hB;
				}
			}
		copy.acc  = n ? (float)hC / (float)n : 0.0f;
		bayes.acc = n ? (float)hB / (float)n : 0.0f;
	}

	// ══════════════════════════════════════════════════════════════════
	// 🏁 판정(팔 4 · 5) — 매 프레임
	// ══════════════════════════════════════════════════════════════════
	static bool Done() { return _run >= kRuns; }

	static void Tick(RHI* rhi)
	{
		if (_run >= kRuns || rhi == nullptr) return;
		if (MLTModelCfg::kAxes != kAxes || MLTModelCfg::kTime != kTime)
		{ LogA("[mlt] 🔗 ⛔⛔ 축/시각 전제가 다르다\n"); _run = kRuns; return; }
		// ⚠️ **기본에서 껐다** — 회차 17 로 쟀다(판정불가 · 눈먼 외삽이 이유를 설명).
		//   ★ 다시 돌리려면 `-mltx`. A단계(CPU)는 계속 돈다(값싸고 회귀 검사 역할).
		if (!OS::CommandLine::Has("-mltx"))
		{
			LogA("[mlt] 🔗 회차 17 판정은 **꺼져 있다**(`-mltx`) — 기록: R̄ 0.587/0.587/0.678 ·"
			     " yaw 질량 **1%%**(비대각 ⛔) · 눈먼외삽 66%% 가 이유를 설명\n");
			_run = kRuns;
			return;
		}
		if (!_banner) { _Banner(); _banner = true; }

		if (_st == kInit)
		{
			if (!_M.Setup(rhi)) { LogA("[mlt] 🔗 준비 실패(run %u)\n", _run); _run = kRuns; return; }
			for (uint32 a = 0; a < kAxes; ++a)
			{
				Base c{}, b{};
				Baseline(a, _Seed(_run), 1u, kEvalEpi0, kEvalEpis, c, b);
				_cop[a] = c.acc; _bay[a] = b.acc;
			}
			_step = 0u; _finite = true; _diag = 0u;
			_st = kTrain;
			return;
		}

		if (_st == kTrain)
		{
			if (_step > 0u)
			{
				float ls = 0.0f;
				if (!_M.ReadLoss(ls)) { LogA("[mlt] 🔗 손실 리드백 실패\n"); _run = kRuns; return; }
				if (!(ls == ls) || ls > 1.0e30f) _finite = false;
			}
			if (_step >= kSteps) { _eb = 0u; _sumP = 0.0f;
				for (uint32 a = 0; a < kAxes; ++a) { _hit[a] = 0u; _cnt[a] = 0u; }
				_st = kEvalUp; return; }

			const uint32 K = MLTModelCfg::kPool;
			const uint32 slot = _step % K;
			if (slot == 0u)
			{
				const uint32 n = ((kSteps - _step) < K) ? (kSteps - _step) : K;
				_pv.Reset(0); _pt.Reset(0);
				for (uint32 k = 0; k < n; ++k)
				{
					Array<float> v, g;
					_Batch(_Seed(_run), 1000u + (_step + k) * MLTModelCfg::kBatch, _Arm(_run), kAll, v, g);
					for (uint32 i = 0; i < v.Count(); ++i) _pv.Add(v[i]);
					for (uint32 i = 0; i < g.Count(); ++i) _pt.Add(g[i]);
				}
				if (!_M.UploadPool(_pv, _pt, n)) { LogA("[mlt] 🔗 풀 업로드 실패\n"); _run = kRuns; return; }
			}
			_M.SelectStep(slot);
			if (!_M.Forward() || !_M.Backward() || !_M.AdamStep())
			{ LogA("[mlt] 🔗 스텝 실패(%u)\n", _step); _run = kRuns; return; }
			++_step;
			return;
		}

		if (_st == kEvalUp)
		{
			if (_eb >= kEvalB) { _st = kDiagUp; return; }
			_Batch(_Seed(_run), kEvalEpi0 + _eb * MLTModelCfg::kBatch, 4, kAll, _ev, _et);
			if (!_M.Upload(_ev, _et)) { LogA("[mlt] 🔗 시험 업로드 실패\n"); _run = kRuns; return; }
			if (!_M.Forward()) { LogA("[mlt] 🔗 시험 forward 실패\n"); _run = kRuns; return; }
			_st = kEvalRd;
			return;
		}

		if (_st == kEvalRd)
		{
			Array<float> m;
			float sp = 0.0f;
			for (uint32 a = 0; a < kAxes; ++a)
			{
				m.Reset(0);
				for (uint32 r = 0; r < MLTModelCfg::kRows; ++r)
					m.Add((((r % MLTModelCfg::kCtx) % kAxes) == a) ? 1.0f : 0.0f);
				uint32 h = 0u, n = 0u, hb = 0u, nb = 0u;
				float dd = 0.0f, ddb = 0.0f, ddo = 0.0f;
				if (!_M.ReadHits(_et, m, h, n, hb, nb, sp, dd, ddb, ddo))
				{ LogA("[mlt] 🔗 리드백 실패\n"); _run = kRuns; return; }
				_hit[a] += hb; _cnt[a] += nb;
			}
			_sumP += sp;
			++_eb;
			_st = kEvalUp;
			return;
		}

		// ── ㉡ 진단 — 표적을 축 하나만 남기고 fwd+bwd(AdamStep 없음) → `ReadAxisMass`
		if (_st == kDiagUp)
		{
			if (_diag >= kAxes) { _Finish(); return; }
			Array<float> v, g;
			_Batch(_Seed(_run), kEvalEpi0, 4, _diag, v, g);
			if (!_M.Upload(v, g)) { LogA("[mlt] 🔗 진단 업로드 실패\n"); _run = kRuns; return; }
			if (!_M.Forward() || !_M.Backward()) { LogA("[mlt] 🔗 진단 실패\n"); _run = kRuns; return; }
			_st = kDiagRd;
			return;
		}

		// kDiagRd
		{
			float m[kAxes] = { 0.0f };
			if (!_M.ReadAxisMass(m, kAxes)) { LogA("[mlt] 🔗 진단 리드백 실패\n"); _run = kRuns; return; }
			for (uint32 j = 0; j < kAxes; ++j) _mass[_diag][j] = m[j];
			++_diag;
			_st = kDiagUp;
		}
	}

	static constexpr uint32 kTime = 32u;

private:
	static constexpr uint32 kDevSeed0 = 0u, kDevSeeds = 12u, kEpis = 32u;
	static constexpr uint32 kSeed0 = 12u, kSeeds = 12u;
	static constexpr uint32 kRuns = kSeeds * 2u;          // 팔 4 + 팔 5
	static constexpr int    kHold = MLTWorldCfg::kHoldMid;
	static constexpr uint32 kSteps = 600u;
	static constexpr uint32 kEvalEpi0 = 0u, kEvalB = 4u;
	static constexpr uint32 kEvalEpis = kEvalB * MLTModelCfg::kBatch;
	static constexpr uint32 kAll = 0xFFFFFFFFu;
	static constexpr float  kThreshR = 0.15f, kArm5Max = 0.080f, kDiagMin = 0.50f;
	static constexpr uint32 kSignNeed = 10u;

	static int    _Arm(uint32 r)  { return (r < kSeeds) ? 4 : 5; }
	static uint32 _Seed(uint32 r) { return kSeed0 + (r % kSeeds); }

	struct Ep
	{
		float x[kTime + 1u], z[kTime + 1u], yw[kTime + 1u];
		float fw[kTime], sd[kTime], dyw[kTime];
	};

	static void _Episode(uint32 seed, uint32 epi, Ep& ep)
	{
		MLTWorld w;
		w.Reset(seed, epi, kHold, 0);
		ep.x[0] = w.State().x; ep.z[0] = w.State().z; ep.yw[0] = w.State().yaw;
		for (uint32 t = 0; t < kTime; ++t)
		{
			w.Step();
			ep.x[t + 1u] = w.State().x; ep.z[t + 1u] = w.State().z; ep.yw[t + 1u] = w.State().yaw;
			ep.fw[t] = w.Act().fwd; ep.sd[t] = w.Act().side; ep.dyw[t] = w.Act().dYaw;
		}
	}

	static float _Refl(float v)
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

	enum { kInit = 0, kTrain, kEvalUp, kEvalRd, kDiagUp, kDiagRd };

	inline static MLTModel _M;
	inline static bool _banner = false;
	inline static uint32 _run = 0u, _step = 0u, _eb = 0u, _diag = 0u;
	inline static int _st = kInit;
	inline static bool _finite = true;
	inline static float _sumP = 0.0f;
	inline static uint32 _hit[kAxes] = { 0u }, _cnt[kAxes] = { 0u };
	inline static float _cop[kAxes] = { 0.0f }, _bay[kAxes] = { 0.0f };
	inline static float _mass[kAxes][kAxes] = { { 0.0f } };
	inline static Array<float> _ev, _et, _pv, _pt;

	inline static float _rR[kRuns][kAxes] = { { 0.0f } };
	inline static float _rAcc[kRuns][kAxes] = { { 0.0f } };
	inline static float _rCopy[kRuns][kAxes] = { { 0.0f } };
	inline static float _rMassYawX[kRuns] = { 0.0f };   // mass(yaw | x표적) 몫
	inline static float _rMassZX[kRuns]   = { 0.0f };   // mass(z   | x표적) 몫
	inline static float _rDiag[kRuns][kAxes] = { { 0.0f } };
	inline static bool  _rOk[kRuns] = { false };

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🔗 **회차 17 판정 · 얽힌 축(x·z·yaw)** — 씨앗 %u~%u · %u 실행\n",
			kSeed0, kSeed0 + kSeeds - 1u, kRuns);
		LogA("[mlt] 🔗   ⭐ 기제가 **비대각을 예측**한다: `mass(yaw|x표적) > mass(z|x표적)` %u/12\n",
			kSignNeed);
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

	// 값 슬롯 = x·z·yaw. `tgtAxis` = kAll(전부) 또는 축 하나.
	static void _Batch(uint32 seed, uint32 epi0, int arm, uint32 tgtAxis,
		Array<float>& val, Array<float>& tgt)
	{
		typedef MLTModelCfg M;
		val.Reset(0); tgt.Reset(0);
		Ep ep;
		for (uint32 b = 0; b < M::kBatch; ++b)
		{
			_Episode(seed, epi0 + b, ep);
			const float* vs[kAxes] = { ep.x, ep.z, ep.yw };
			for (uint32 t = 0; t < kTime; ++t)
				for (uint32 a = 0; a < kAxes; ++a)
				{
					val.Add(vs[a][t]);
					const bool on = (tgtAxis == kAll) || (a == tgtAxis);
					tgt.Add(on ? (float)MLTP0::Bucket(vs[a][t + 1u]) : M::kIgnoreTgt);
				}
		}
		if (arm == 5)
		{
			Array<float> src = val;
			for (uint32 i = 0; i < val.Count(); ++i) val[i] = src[(i * 313u + 17u) % M::kRows];
		}
	}

	static void _Finish()
	{
		const float sp = (_eb > 0u) ? _sumP / (float)_eb : 0.0f;
		for (uint32 a = 0; a < kAxes; ++a)
		{
			const float acc = _cnt[a] ? (float)_hit[a] / (float)_cnt[a] : 0.0f;
			const float w = _bay[a] - _cop[a];
			_rAcc[_run][a] = acc;
			_rR[_run][a] = (w > 1.0e-4f) ? (acc - _cop[a]) / w : 0.0f;
			_rCopy[_run][a] = _cop[a];
			float tot = 0.0f;
			for (uint32 j = 0; j < kAxes; ++j) tot += _mass[a][j];
			_rDiag[_run][a] = (tot > 1.0e-12f) ? _mass[a][a] / tot : 0.0f;
		}
		{
			float tot = 0.0f;
			for (uint32 j = 0; j < kAxes; ++j) tot += _mass[0][j];
			_rMassYawX[_run] = (tot > 1.0e-12f) ? _mass[0][2] / tot : 0.0f;
			_rMassZX[_run]   = (tot > 1.0e-12f) ? _mass[0][1] / tot : 0.0f;
		}
		_rOk[_run] = _finite && (Abs(sp - 1.0f) <= 0.01f);
		LogA("[mlt] 🔗 [%2u/%u] 팔%d 씨앗%2u · R **%.3f/%.3f/%.3f** · x표적 질량(x/z/yaw)"
		     " %.0f/%.0f/%.0f%%%s\n",
			_run + 1u, kRuns, _Arm(_run), _Seed(_run),
			(double)_rR[_run][0], (double)_rR[_run][1], (double)_rR[_run][2],
			(double)(_rDiag[_run][0] * 100.0f), (double)(_rMassZX[_run] * 100.0f),
			(double)(_rMassYawX[_run] * 100.0f), _rOk[_run] ? "" : "  ⛔배관");
		++_run;
		_st = kInit;
		if (_run >= kRuns) _Judge();
	}

	static void _Judge()
	{
		float rBar[kAxes] = { 0.0f }, diag[kAxes] = { 0.0f };
		uint32 sign[kAxes] = { 0u }, signX = 0u;
		float a5 = 0.0f;
		bool plumb = true, ceilOk = true;
		for (uint32 i = 0; i < kSeeds; ++i)
		{
			for (uint32 a = 0; a < kAxes; ++a)
			{
				rBar[a] += _rR[i][a];
				diag[a] += _rDiag[i][a];
				if (_rAcc[i][a] > _rCopy[i][a]) ++sign[a];
				if (_rR[i][a] > 1.0f) ceilOk = false;
				a5 += _rAcc[kSeeds + i][a];
			}
			if (_rMassYawX[i] > _rMassZX[i]) ++signX;   // ⭐ 비대각 예측
			if (!_rOk[i] || !_rOk[kSeeds + i]) plumb = false;
		}
		const float k = 1.0f / (float)kSeeds;
		for (uint32 a = 0; a < kAxes; ++a) { rBar[a] *= k; diag[a] *= k; }
		a5 /= (float)(kSeeds * kAxes);
		float myx = 0.0f, mzx = 0.0f;
		for (uint32 i = 0; i < kSeeds; ++i) { myx += _rMassYawX[i]; mzx += _rMassZX[i]; }
		myx *= k; mzx *= k;

		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🔗 **회차 17 결과 — 얽힌 축**\n");
		if (!plumb) LogA("[mlt] 🔗   ⛔ ㉢′ 배관이 깨진 실행이 있다 — **판정불가**\n");
		else        LogA("[mlt] 🔗   ✅ ㉢′ 배관 — probs 합 1.0 · 전 구간 유한\n");

		bool g1 = true;
		for (uint32 a = 0; a < kAxes; ++a) if (rBar[a] < kThreshR || sign[a] < kSignNeed) g1 = false;
		LogA("[mlt] 🔗   %s ㉠ 표제 — R̄ = **%.3f(x) / %.3f(z) / %.3f(yaw)** (문턱 %.2f)"
		     " · 부호검정 %u·%u·%u /12\n",
			g1 ? "✅" : "⛔", (double)rBar[0], (double)rBar[1], (double)rBar[2], (double)kThreshR,
			sign[0], sign[1], sign[2]);

		const bool g2a = (diag[2] >= kDiagMin);
		const bool g2b = (myx > mzx) && (signX >= kSignNeed);
		LogA("[mlt] 🔗   %s ㉡ 기제(대각) — diag(yaw) %.0f%% ≥ 50%% (순수 1D 의 닻)\n",
			g2a ? "✅" : "⛔", (double)(diag[2] * 100.0f));
		LogA("[mlt] 🔗   %s ㉡ ⭐ 기제(**비대각**) — x표적의 질량: yaw **%.0f%%** > z **%.0f%%**"
		     " · 부호검정 **%u/12**\n",
			g2b ? "✅" : "⛔", (double)(myx * 100.0f), (double)(mzx * 100.0f), signX);
		LogA("[mlt] 🔗   ⓘ 읽는 칸 — diag(x) %.0f%% ↔ diag(yaw) %.0f%% (얽힌 축은 대각이 낮아야 이치다)\n",
			(double)(diag[0] * 100.0f), (double)(diag[2] * 100.0f));

		const bool g4 = (a5 <= kArm5Max);
		LogA("[mlt] 🔗   %s ㉣ 대조군 — 팔5[가림] %.2f%% ≤ %.1f%%\n",
			g4 ? "✅" : "⛔", (double)(a5 * 100.0f), (double)(kArm5Max * 100.0f));
		LogA("[mlt] 🔗   %s ㉤ 상한 — R > 1 인 실행 %s\n", ceilOk ? "✅" : "⛔", ceilOk ? "없다" : "**있다**");

		LogA("[mlt] ══════════════════════════════════════════════════\n");
		if (!plumb || !g4)
			LogA("[mlt] 🔗 ⛔ **배관/대조군이 깨졌다 — 판정불가**\n");
		else if (g1 && g2a && g2b)
			LogA("[mlt] 🔗 ✅✅ **규칙이 얽힌 형태에도 서고, 기제가 얽힘을 따라간다**"
			     "(x 의 손실이 yaw 슬롯을 읽는다) ⇒ **P1 을 닫고 P2(비전)로 간다**\n");
		else if (g1 && !(g2a && g2b))
			LogA("[mlt] 🔗 ⚠️ **성능은 서는데 기제가 안 보인다 ⇒ 판정불가**(그 계약 — 성능이 좋아도)\n");
		else
			LogA("[mlt] 🔗 ⚠️⚠️ **얽힘이 벽이다** — yaw 대비 x·z 의 격차가 그 크기다"
			     "(⚠️ 크기를 키우지 않는다). 그것이 이 라운드의 결과다\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}
};
