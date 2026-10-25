// mltgrad.cw — 🧪 **판정 ② · 수치 미분 vs 해석 기울기** (CPU 레퍼런스만으로 돈다)
//
// ★ **왜 이것이 첫 판정인가** — 이 저장소의 조용한 버그가 전부 *"컴파일되고 안 죽고 숫자만
//   틀린다"* 였고 **학습 곡선으로는 못 본다.** 그리고 GPU 배선(`OnPreGuiRender`)이 아직 없어도
//   **bwd 의 실제 수식 오류는 지금 잡을 수 있다** — 그것이 이 파일이다.
//   ⚠️ 판정 ①(GPU vs CPU)은 `MLT::Tick(RHICommandList*)` 를 연 뒤다. 둘은 **다른 검사**다:
//     ② 는 *"미분이 맞나"*, ① 은 *"셰이더가 CPU 와 같은 수를 내나"*.
//
// ★ **기법** — 스칼라 손실을 하나 세우고 중앙차분과 해석 기울기를 견준다.
//   ```
//   L = ½ Σ (y − t)²      ⇒  dL/dy = (y − t)         ← 이것을 bwd 의 dOut 으로 넣는다
//   수치  = (L(x+ε) − L(x−ε)) / 2ε
//   해석  = bwd(dOut)[i]
//   ```
//   ⚠️ **`ce_logits` 만 이 손실을 쓰지 않는다** — 그 커널의 해석 기울기는 CE 자신의 것이라
//     ½Σ(y−t)² 로 접으면 **정확한 커널이 떨어진다**(초안이 경고한 자리).
//
// ⚠️⚠️ **판정은 정규화 절대오차다** — `MLMaxRelErr` 을 쓰지 않는다. 기울기는 **0 을 지나므로**
//   분모 바닥이 절대오차를 증폭해 **멀쩡한 커널을 떨어뜨린다**(mltkernels.cw 머리말 ㉢).
//
// ⚠️⚠️⚠️ **조건부가 필요한 자리 셋** — 안 적으면 다음 사람이 *"gradcheck 를 못 통과한다"* 로 오진한다:
//   · `act_topk` — 선택이 **이산**이다. ε 로 흔들면 **고르는 것이 바뀌어** 손실이 점프한다
//     ⇒ **「선택 고정 조건부」**: fwd 를 한 번 돌려 `ids` 를 얻고, 흔드는 동안 **그 `ids` 를 재사용**한다.
//   · `val_enc` — `vBias`/`vScale` 이 **러닝 통계**(EMA · 비미분 경로)다
//     ⇒ **「계수 고정 조건부」**: 흔드는 동안 계수를 **다시 계산하지 않는다**(인자로 받으므로 자연히 고정).
//   · `act_coeff_ste` — 잔차 좌표 갱신량 δ는 이번 회차의 stop-gradient 경로다
//     ⇒ **「δ 고정 조건부」**: `mag₁=mag₀+δ`에서 δ를 다시 풀지 않고 `dmag₀=dmag₁`을 검사한다.
//   ★ 로그가 그 사실을 **매번 찍는다** — 조건부인 줄 모르고 인용하면 그 자리가 곧 오독이다.

using namespace PE;

class MLTGrad
{
public:
	// ══════════════════════════════════════════════════════════════════
	// 🚪 전부 돌린다. 반환 = 실패한 검사 수(0 이면 전부 통과).
	// ══════════════════════════════════════════════════════════════════
	static int RunAll()
	{
		LogA("[mlt] ── 판정 ② · 수치 미분 vs 해석 기울기 (CPU 레퍼런스 · 중앙차분 eps=%.0e) ──\n", (double)kEps);
		int fail = 0;
		fail += _RmsNorm();
		fail += _Rope();
		fail += _AttnSoftmax();
		fail += _Swiglu();
		fail += _CeLogits();
		fail += _ValEnc();
		fail += _ActTopk();
		fail += _ActGather();
		fail += _VisRecon();
		fail += _FootRecon();
		fail += _PatchEmbed();
		fail += _Sub();
		fail += _ActTopkAbs();
		fail += _ActCoeffSte();
		if (fail == 0) LogA("[mlt] ✅ 판정 ② — 전부 통과\n");
		else           LogA("[mlt] ⛔ 판정 ② — 실패 %d 건 (위 줄을 읽어라 · 넘기지 마라)\n", fail);
		return fail;
	}

private:
	// ⚠️ **문턱은 한 곳에만 둔다** — 여러 곳에 적으면 반드시 갈린다.
	//   ★ 중앙차분의 절단오차가 `O(ε²)` 이고 float 누산 잡음이 얹히므로 **2e-2** 가 현실적인 자리다
	//     (수식이 틀리면 보통 0.5 를 넘는다 — 이 문턱은 「맞나 틀리나」를 가르기에 충분히 좁다).
	static constexpr float kEps = 1.0e-3f;
	static constexpr float kTol = 2.0e-2f;

	// ── 결정적 산포 ────────────────────────────────────────────────
	// ⚠️ 난수 대신 **결정적 산포**를 쓴다 — 시드 스트림을 소비하면 비트 재현이 깨진다(D119 가 그 자리를
	//   밟았다). 값은 `[-1, 1)` 에 고르게 퍼지고 **부호가 섞인다**(0 을 지나는 출력을 만들어야 판정이 뜻이 있다).
	static float _Spread(uint32 i, uint32 salt)
	{
		uint32 h = i * 2654435761u + salt * 2246822519u;
		h ^= (h >> 15); h *= 2654435761u; h ^= (h >> 13);
		return ((float)(h & 0xFFFFu) / 32768.0f) - 1.0f;
	}

	static void _Fill(Array<float>& v, uint32 n, uint32 salt, float amp = 1.0f)
	{
		v.Reset(0);
		for (uint32 i = 0; i < n; ++i) v.Add(_Spread(i, salt) * amp);
	}

	static void _Zero(Array<float>& v, uint32 n)
	{
		v.Reset(0);
		for (uint32 i = 0; i < n; ++i) v.Add(0.0f);
	}

	// ── 손실 ½Σ(y−t)² 과 그 dOut ─────────────────────────────────────
	static float _Loss(const float* y, const float* t, uint32 n)
	{
		float s = 0.0f;
		for (uint32 i = 0; i < n; ++i) { const float d = y[i] - t[i]; s += 0.5f * d * d; }
		return s;
	}

	static void _DOut(const float* y, const float* t, float* dOut, uint32 n)
	{
		for (uint32 i = 0; i < n; ++i) dOut[i] = y[i] - t[i];
	}

	// ══════════════════════════════════════════════════════════════════
	// 📊 한 검사의 판정·로그를 **한 자리**에서 한다.
	//   ⚠️ `note` 에 조건부를 적는다 — 로그가 그것을 매번 찍어야 다음 사람이 오독하지 않는다.
	// ══════════════════════════════════════════════════════════════════
	static int _Verdict(const char* name, const char* what, const float* num, const float* ana,
		uint32 n, const char* note)
	{
		const float err = MLMaxAbsErr(num, ana, n);
		const float mag = MLMaxAbs(ana, n);
		// ⚠️ 정규화 절대오차 — 분모가 0 에 가까우면 그 검사는 **뜻이 없다**(흔들어도 손실이 안 변한다)
		//   ⇒ 그것을 통과로 찍지 말고 **판정불가**로 찍는다(조용한 통과가 이 저장소의 함정이다).
		if (mag < 1.0e-6f)
		{
			LogA("[mlt]   ⚠️ %-14s %-8s 판정불가 — 해석 기울기가 전부 0 (|ana|=%.2e)  %s\n",
				name, what, (double)mag, note);
			return 1;
		}
		const float rel = err / mag;
		const bool ok = (rel < kTol);
		LogA("[mlt]   %s %-14s %-8s  수치vs해석 %.2e (|ana|=%.2e · n=%u)  %s\n",
			ok ? "✅" : "⛔", name, what, (double)rel, (double)mag, n, note);
		return ok ? 0 : 1;
	}

	// ══════════════════════════════════════════════════════════════════
	// 📏 RMSNorm — bwd 가 **둘**(dIn · dGain)이라 각각 잰다.
	// ══════════════════════════════════════════════════════════════════
	static int _RmsNorm()
	{
		const uint32 R = 5, C = 7, N = R * C;
		Array<float> x, g, y, rstd, t, dOut, dIn, dG, num;
		_Fill(x, N, 11); _Fill(g, C, 12); _Fill(t, N, 13);
		_Zero(y, N); _Zero(rstd, R); _Zero(dOut, N); _Zero(dIn, N); _Zero(dG, C);

		MLRmsNormCpu(x.Data(), g.Data(), y.Data(), rstd.Data(), R, C);
		_DOut(y.Data(), t.Data(), dOut.Data(), N);
		MLRmsNormBwdCpu(x.Data(), g.Data(), rstd.Data(), dOut.Data(), dIn.Data(), R, C);
		MLRmsNormGainBwdCpu(x.Data(), rstd.Data(), dOut.Data(), dG.Data(), R, C);

		int fail = 0;
		// ── dIn
		_Zero(num, N);
		for (uint32 i = 0; i < N; ++i) num.Data()[i] = _NumIn(x, g, t, R, C, i);
		fail += _Verdict("rmsnorm", "dIn", num.Data(), dIn.Data(), N, "조건부 없음");
		// ── dGain
		_Zero(num, C);
		for (uint32 j = 0; j < C; ++j) num.Data()[j] = _NumGain(x, g, t, R, C, j);
		fail += _Verdict("rmsnorm", "dGain", num.Data(), dG.Data(), C, "조건부 없음");
		return fail;
	}

	static float _NumIn(Array<float>& x, Array<float>& g, Array<float>& t, uint32 R, uint32 C, uint32 i)
	{
		const uint32 N = R * C;
		Array<float> y, rstd; _Zero(y, N); _Zero(rstd, R);
		const float keep = x.Data()[i];
		x.Data()[i] = keep + kEps;
		MLRmsNormCpu(x.Data(), g.Data(), y.Data(), rstd.Data(), R, C);
		const float lp = _Loss(y.Data(), t.Data(), N);
		x.Data()[i] = keep - kEps;
		MLRmsNormCpu(x.Data(), g.Data(), y.Data(), rstd.Data(), R, C);
		const float lm = _Loss(y.Data(), t.Data(), N);
		x.Data()[i] = keep;
		return (lp - lm) / (2.0f * kEps);
	}

	static float _NumGain(Array<float>& x, Array<float>& g, Array<float>& t, uint32 R, uint32 C, uint32 j)
	{
		const uint32 N = R * C;
		Array<float> y, rstd; _Zero(y, N); _Zero(rstd, R);
		const float keep = g.Data()[j];
		g.Data()[j] = keep + kEps;
		MLRmsNormCpu(x.Data(), g.Data(), y.Data(), rstd.Data(), R, C);
		const float lp = _Loss(y.Data(), t.Data(), N);
		g.Data()[j] = keep - kEps;
		MLRmsNormCpu(x.Data(), g.Data(), y.Data(), rstd.Data(), R, C);
		const float lm = _Loss(y.Data(), t.Data(), N);
		g.Data()[j] = keep;
		return (lp - lm) / (2.0f * kEps);
	}

	// ══════════════════════════════════════════════════════════════════
	// 🌀 RoPE — 파라미터가 없다. bwd 는 **같은 회전의 역**(`dirSign = -1`)이다.
	// ══════════════════════════════════════════════════════════════════
	static int _Rope()
	{
		const uint32 R = 4, D = 8, N = R * D;   // ⚠️ D 는 짝수여야 한다(이웃 쌍 회전)
		Array<float> x, pos, y, t, dOut, dIn, num;
		_Fill(x, N, 21); _Fill(t, N, 22);
		pos.Reset(0); for (uint32 r = 0; r < R; ++r) pos.Add((float)r);
		_Zero(y, N); _Zero(dOut, N); _Zero(dIn, N);

		MLRopeCpu(x.Data(), pos.Data(), y.Data(), R, D, 0u);
		_DOut(y.Data(), t.Data(), dOut.Data(), N);
		MLRopeBwdCpu(dOut.Data(), pos.Data(), dIn.Data(), R, D, 0u);

		_Zero(num, N);
		for (uint32 i = 0; i < N; ++i)
		{
			const float keep = x.Data()[i];
			x.Data()[i] = keep + kEps;
			MLRopeCpu(x.Data(), pos.Data(), y.Data(), R, D, 0u);
			const float lp = _Loss(y.Data(), t.Data(), N);
			x.Data()[i] = keep - kEps;
			MLRopeCpu(x.Data(), pos.Data(), y.Data(), R, D, 0u);
			const float lm = _Loss(y.Data(), t.Data(), N);
			x.Data()[i] = keep;
			num.Data()[i] = (lp - lm) / (2.0f * kEps);
		}
		return _Verdict("rope", "dIn", num.Data(), dIn.Data(), N, "조건부 없음 (mode=1D)");
	}

	// ══════════════════════════════════════════════════════════════════
	// 🎯 인과 마스크 softmax — bwd 는 **기존 `MLSoftmaxBwdCpu`** 다(새 커널 없음).
	//   ⚠️ 마스크된 칸은 fwd 가 정확히 0 을 쓰므로 그 자리의 기울기도 0 이어야 한다.
	// ══════════════════════════════════════════════════════════════════
	static int _AttnSoftmax()
	{
		const uint32 T = 6, N = T * T;
		Array<float> s, p, t, dOut, dIn, num;
		_Fill(s, N, 31); _Fill(t, N, 32);
		_Zero(p, N); _Zero(dOut, N); _Zero(dIn, N);

		MLAttnSoftmaxCpu(s.Data(), p.Data(), T, T, 0u);
		_DOut(p.Data(), t.Data(), dOut.Data(), N);
		MLSoftmaxBwdCpu(p.Data(), dOut.Data(), dIn.Data(), T, T);

		_Zero(num, N);
		for (uint32 i = 0; i < N; ++i)
		{
			const float keep = s.Data()[i];
			s.Data()[i] = keep + kEps;
			MLAttnSoftmaxCpu(s.Data(), p.Data(), T, T, 0u);
			const float lp = _Loss(p.Data(), t.Data(), N);
			s.Data()[i] = keep - kEps;
			MLAttnSoftmaxCpu(s.Data(), p.Data(), T, T, 0u);
			const float lm = _Loss(p.Data(), t.Data(), N);
			s.Data()[i] = keep;
			num.Data()[i] = (lp - lm) / (2.0f * kEps);
		}
		// ⚠️ **마스크된 칸의 해석 기울기가 0 인지 따로 본다** — 전체 오차에 묻히면 안 보인다.
		float maskMax = 0.0f;
		for (uint32 r = 0; r < T; ++r)
			for (uint32 c = r + 1; c < T; ++c)
			{
				const float a = dIn.Data()[r * T + c];
				const float v = (a < 0.0f) ? -a : a;
				if (v > maskMax) maskMax = v;
			}
		const int f = _Verdict("attn_softmax", "dIn", num.Data(), dIn.Data(), N, "조건부 없음 (causalOff=0)");
		LogA("[mlt]   %s attn_softmax   마스크칸  해석 기울기 최대 |g| = %.2e (0 이어야 한다)\n",
			(maskMax < 1.0e-9f) ? "✅" : "⛔", (double)maskMax);
		return f + ((maskMax < 1.0e-9f) ? 0 : 1);
	}

	// ══════════════════════════════════════════════════════════════════
	// 🚪 SwiGLU — 입력 둘(a=게이트 · b=값), bwd 도 둘(dA · dB).
	// ══════════════════════════════════════════════════════════════════
	static int _Swiglu()
	{
		const uint32 N = 32;
		Array<float> a, b, y, t, dOut, dA, dB, num;
		_Fill(a, N, 41); _Fill(b, N, 42); _Fill(t, N, 43);
		_Zero(y, N); _Zero(dOut, N); _Zero(dA, N); _Zero(dB, N);

		MLSwigluCpu(a.Data(), b.Data(), y.Data(), N);
		_DOut(y.Data(), t.Data(), dOut.Data(), N);
		MLSwigluBwdCpu(a.Data(), b.Data(), dOut.Data(), dA.Data(), dB.Data(), N);

		int fail = 0;
		_Zero(num, N);
		for (uint32 i = 0; i < N; ++i) num.Data()[i] = _NumSw(a, b, t, N, i, true);
		fail += _Verdict("swiglu", "dA", num.Data(), dA.Data(), N, "조건부 없음 (게이트 쪽)");
		_Zero(num, N);
		for (uint32 i = 0; i < N; ++i) num.Data()[i] = _NumSw(a, b, t, N, i, false);
		fail += _Verdict("swiglu", "dB", num.Data(), dB.Data(), N, "조건부 없음 (값 쪽)");
		return fail;
	}

	static float _NumSw(Array<float>& a, Array<float>& b, Array<float>& t, uint32 N, uint32 i, bool wrtA)
	{
		Array<float> y; _Zero(y, N);
		float* p = wrtA ? a.Data() : b.Data();
		const float keep = p[i];
		p[i] = keep + kEps;
		MLSwigluCpu(a.Data(), b.Data(), y.Data(), N);
		const float lp = _Loss(y.Data(), t.Data(), N);
		p[i] = keep - kEps;
		MLSwigluCpu(a.Data(), b.Data(), y.Data(), N);
		const float lm = _Loss(y.Data(), t.Data(), N);
		p[i] = keep;
		return (lp - lm) / (2.0f * kEps);
	}

	// ══════════════════════════════════════════════════════════════════
	// 📉 ce_logits — ⚠️⚠️ **손실이 다르다.** 여기서는 CE 자신이 손실이다
	//   (½Σ(y−t)² 로 접으면 **정확한 커널이 떨어진다**).
	// ══════════════════════════════════════════════════════════════════
	static int _CeLogits()
	{
		const uint32 R = 5, V = 9, N = R * V;
		const uint32 kIgnore = 0xFFFFFFFFu;   // ⚠️ 기본값을 안 준다(0 이 멀쩡한 id 다)
		Array<float> z, tgt, probs, loss, dz, num;
		_Fill(z, N, 51);
		tgt.Reset(0); for (uint32 r = 0; r < R; ++r) tgt.Add((float)(r % V));
		_Zero(probs, N); _Zero(loss, R); _Zero(dz, N);

		MLCeLogitsCpu(z.Data(), tgt.Data(), probs.Data(), loss.Data(), R, V, kIgnore);
		MLCeLogitsBwdCpu(probs.Data(), tgt.Data(), dz.Data(), R, V, kIgnore);

		_Zero(num, N);
		for (uint32 i = 0; i < N; ++i)
		{
			const float keep = z.Data()[i];
			z.Data()[i] = keep + kEps;
			MLCeLogitsCpu(z.Data(), tgt.Data(), probs.Data(), loss.Data(), R, V, kIgnore);
			const float lp = _Sum(loss.Data(), R);
			z.Data()[i] = keep - kEps;
			MLCeLogitsCpu(z.Data(), tgt.Data(), probs.Data(), loss.Data(), R, V, kIgnore);
			const float lm = _Sum(loss.Data(), R);
			z.Data()[i] = keep;
			num.Data()[i] = (lp - lm) / (2.0f * kEps);
		}
		// fwd 를 원래 값으로 되돌려 놓는다(아래 로그가 그것을 안 쓰지만 관례다)
		MLCeLogitsCpu(z.Data(), tgt.Data(), probs.Data(), loss.Data(), R, V, kIgnore);
		return _Verdict("ce_logits", "dLogits", num.Data(), dz.Data(), N,
			"조건부 없음 · 손실은 CE 자신(½Σ(y−t)² 아님)");
	}

	static float _Sum(const float* v, uint32 n)
	{
		float s = 0.0f;
		for (uint32 i = 0; i < n; ++i) s += v[i];
		return s;
	}

	// ══════════════════════════════════════════════════════════════════
	// 📐 val_enc — ⚠️ **「계수 고정 조건부」**. `vBias`/`vScale` 은 러닝 통계라 비미분 경로이고,
	//   흔드는 동안 다시 계산하면 수치 기울기에 계수 변화분이 섞여 **정확한 커널이 떨어진다.**
	//   ★ 인자로 받으므로 여기서는 자연히 고정된다 — 그래도 로그에 찍는다.
	// ⚠️ 판정용 `freqMax` 는 **학습용과 다르다**(64 ↔ 1000) — 1000 에서는 `ω·u` 가 커서
	//   `sin` 위상 오차가 임계를 넘길 수 있다(정확한 커널인데도). 초안이 그 값을 권고했다.
	// ══════════════════════════════════════════════════════════════════
	static int _ValEnc()
	{
		const uint32 R = 6, F = 4, N = R * 2 * F;
		const float vB = 0.0f, vS = 1.0f, fMin = 1.0f, fMax = 64.0f;
		Array<float> v, phi, t, dOut, dV, num;
		_Fill(v, R, 61); _Fill(t, N, 62);
		_Zero(phi, N); _Zero(dOut, N); _Zero(dV, R);

		MLValEncCpu(v.Data(), phi.Data(), R, F, vB, vS, fMin, fMax);
		_DOut(phi.Data(), t.Data(), dOut.Data(), N);
		MLValEncBwdCpu(v.Data(), dOut.Data(), dV.Data(), R, F, vB, vS, fMin, fMax);

		_Zero(num, R);
		for (uint32 r = 0; r < R; ++r)
		{
			const float keep = v.Data()[r];
			v.Data()[r] = keep + kEps;
			MLValEncCpu(v.Data(), phi.Data(), R, F, vB, vS, fMin, fMax);
			const float lp = _Loss(phi.Data(), t.Data(), N);
			v.Data()[r] = keep - kEps;
			MLValEncCpu(v.Data(), phi.Data(), R, F, vB, vS, fMin, fMax);
			const float lm = _Loss(phi.Data(), t.Data(), N);
			v.Data()[r] = keep;
			num.Data()[r] = (lp - lm) / (2.0f * kEps);
		}
		return _Verdict("val_enc", "dIn", num.Data(), dV.Data(), R,
			"⚠️ 계수 고정 조건부 (vBias/vScale 은 러닝 통계 · freqMax=64 판정용)");
	}

	// ══════════════════════════════════════════════════════════════════
	// 👁️ act_topk — ⚠️⚠️ **「선택 고정 조건부」**. 선택이 이산이라 ε 로 흔들면 고르는 것이 바뀌어
	//   손실이 **점프**한다 ⇒ 그대로 재면 정확한 커널이 반드시 떨어진다.
	//   ★ 그래서 fwd 를 한 번 돌려 `ids` 를 얻고, 흔드는 동안 **그 `ids` 를 재사용**한다
	//     (= straight-through 가 실제로 가정하는 것과 같은 조건).
	// ══════════════════════════════════════════════════════════════════
	static int _ActTopk()
	{
		const uint32 R = 4, DICT = 12, K = 3, NM = R * K;
		Array<float> z, ids, mag, t, dMag, dZ, num;
		_Fill(z, R * DICT, 71); _Fill(t, NM, 72);
		_Zero(ids, NM); _Zero(mag, NM); _Zero(dMag, NM); _Zero(dZ, R * DICT);

		MLActTopkCpu(z.Data(), ids.Data(), mag.Data(), R, DICT, K);
		_DOut(mag.Data(), t.Data(), dMag.Data(), NM);
		MLActTopkBwdCpu(ids.Data(), dMag.Data(), dZ.Data(), R, DICT, K);

		// ⚠️ 선택을 고정한 조건부 fwd — `ids` 를 다시 안 고른다. `mag[j] = z[row][ids[j]]`.
		_Zero(num, R * DICT);
		for (uint32 i = 0; i < R * DICT; ++i)
		{
			const float keep = z.Data()[i];
			z.Data()[i] = keep + kEps;
			const float lp = _TopkFixedLoss(z, ids, t, R, DICT, K);
			z.Data()[i] = keep - kEps;
			const float lm = _TopkFixedLoss(z, ids, t, R, DICT, K);
			z.Data()[i] = keep;
			num.Data()[i] = (lp - lm) / (2.0f * kEps);
		}
		return _Verdict("act_topk", "dScore", num.Data(), dZ.Data(), R * DICT,
			"⚠️⚠️ 선택 고정 조건부 (이산 선택 · straight-through)");
	}

	// 선택(`ids`)을 고정한 채 세기만 다시 읽어 손실을 낸다.
	static float _TopkFixedLoss(Array<float>& z, Array<float>& ids, Array<float>& t,
		uint32 R, uint32 DICT, uint32 K)
	{
		float s = 0.0f;
		for (uint32 r = 0; r < R; ++r)
			for (uint32 j = 0; j < K; ++j)
			{
				const uint32 sl = r * K + j;
				const uint32 n = (uint32)ids.Data()[sl];
				// ⚠️ 범위 밖(`ids == dict`)은 세기 0 — fwd 규약과 같은 자리.
				const float m = (n < DICT) ? z.Data()[r * DICT + n] : 0.0f;
				const float d = m - t.Data()[sl];
				s += 0.5f * d * d;
			}
		return s;
	}

	// ══════════════════════════════════════════════════════════════════
	// 🧲 act_gather — 선택은 이미 끝난 뒤다. `ids` 를 고정하고 A/B 에서 같은 자리를
	//   읽으므로 두 입력의 해석 기울기를 각각 중앙차분과 견준다.
	// ══════════════════════════════════════════════════════════════════
	static int _ActGather()
	{
		const uint32 R = 4, DICT = 11, K = 3;
		const uint32 NZ = R * DICT, NS = R * K;
		const float scale = 1.731f;
		Array<float> sel, a, b, ids, mag, t, dMag, dA, dB, num;
		_Fill(sel, NZ, 141); _Fill(a, NZ, 142); _Fill(b, NZ, 143); _Fill(t, NS, 144);
		_Zero(ids, NS); _Zero(mag, NS); _Zero(dMag, NS);
		_Zero(dA, NZ); _Zero(dB, NZ); _Zero(num, NZ);

		MLActTopkCpu(sel.Data(), ids.Data(), mag.Data(), R, DICT, K);
		MLActGatherCpu(a.Data(), b.Data(), ids.Data(), mag.Data(), R, DICT, K, true, scale);
		_DOut(mag.Data(), t.Data(), dMag.Data(), NS);
		MLActGatherBwdCpu(ids.Data(), dMag.Data(), dA.Data(), R, DICT, K, scale, false);
		MLActGatherBwdCpu(ids.Data(), dMag.Data(), dB.Data(), R, DICT, K, scale, false);

		for (uint32 i = 0; i < NZ; ++i)
			num.Data()[i] = _NumGather(a, b, ids, t, i, true, R, DICT, K, scale);
		int fail = _Verdict("act_gather", "dA", num.Data(), dA.Data(), NZ, "ids 고정 · A+B");
		for (uint32 i = 0; i < NZ; ++i)
			num.Data()[i] = _NumGather(a, b, ids, t, i, false, R, DICT, K, scale);
		fail += _Verdict("act_gather", "dB", num.Data(), dB.Data(), NZ, "ids 고정 · A+B");
		return fail;
	}

	static float _NumGather(Array<float>& a, Array<float>& b, Array<float>& ids, Array<float>& t,
		uint32 at, bool perturbA, uint32 R, uint32 DICT, uint32 K, float scale)
	{
		Array<float>& x = perturbA ? a : b;
		const float keep = x.Data()[at];
		Array<float> mag;
		_Zero(mag, R * K);
		x.Data()[at] = keep + kEps;
		MLActGatherCpu(a.Data(), b.Data(), ids.Data(), mag.Data(), R, DICT, K, true, scale);
		const float lp = _Loss(mag.Data(), t.Data(), R * K);
		x.Data()[at] = keep - kEps;
		MLActGatherCpu(a.Data(), b.Data(), ids.Data(), mag.Data(), R, DICT, K, true, scale);
		const float lm = _Loss(mag.Data(), t.Data(), R * K);
		x.Data()[at] = keep;
		return (lp - lm) / (2.0f * kEps);
	}

	// ══════════════════════════════════════════════════════════════════
	// 🧩 vis_recon — bwd 가 **둘**(dMag · dTable). `ids` 는 이 커널의 **입력**이라
	//   흔들어도 선택이 다시 안 일어난다 ⇒ **조건부가 필요 없다**.
	// ══════════════════════════════════════════════════════════════════
	// ══════════════════════════════════════════════════════════════════
	// ⭐ act_topk_abs — 선택은 `|z|` · 세기는 `z`. ⚠️ **조건부가 `act_topk` 과 같다**
	//   (선택이 **이산**이라 ε 로 흔들면 고르는 것이 바뀐다 ⇒ `ids` 를 고정한 채 세기만 다시 읽는다).
	//   ★ 그리고 **해석 기울기는 `act_topk_bwd` 그대로**다 — 그 사실 자체가 이 검사의 내용이다
	//     (관계가 `mag = z[ids]` 로 같으므로 bwd 를 새로 만들 이유가 없다).
	//   ⭐ **부호 있는 계수가 실제로 나오는지**도 여기서 본다 — 뽑힌 `mag` 에 음수가 하나도 없으면
	//     이 커널이 `act_topk` 과 다를 바가 없고 검사가 뜻을 잃는다(로그가 그 수를 찍는다).
	// ══════════════════════════════════════════════════════════════════
	static int _ActTopkAbs()
	{
		const uint32 R = 4, DICT = 12, K = 3;
		const uint32 NZ = R * DICT, NS = R * K;
		Array<float> z, ids, mag, t2, dMag, dZ, num;
		_Fill(z, NZ, 131); _Fill(t2, NS, 132);
		_Zero(ids, NS); _Zero(mag, NS); _Zero(dMag, NS); _Zero(dZ, NZ);

		MLActTopkAbsCpu(z.Data(), ids.Data(), mag.Data(), R, DICT, K);
		uint32 neg = 0;
		for (uint32 i = 0; i < NS; ++i) if (mag[i] < 0.0f) ++neg;
		_DOut(mag.Data(), t2.Data(), dMag.Data(), NS);
		// ★ 기울기는 **기존 커널**이 낸다(그것이 요점이다)
		MLActTopkBwdCpu(ids.Data(), dMag.Data(), dZ.Data(), R, DICT, K);

		_Zero(num, NZ);
		for (uint32 i = 0; i < NZ; ++i)
		{
			// 선택 고정 조건부 — `ids` 를 다시 고르지 않고 세기만 다시 읽는다.
			const float keep = z[i];
			z.Data()[i] = keep + kEps;
			const float lp = _TopkFixedLoss(z, ids, t2, R, DICT, K);
			z.Data()[i] = keep - kEps;
			const float lm = _TopkFixedLoss(z, ids, t2, R, DICT, K);
			z.Data()[i] = keep;
			num.Data()[i] = (lp - lm) / (2.0f * kEps);
		}
		LogA("[mlt]   ⓘ act_topk_abs   뽑힌 세기 %u개 중 **음수 %u개**"
		     " (0 이면 `act_topk` 과 다를 바가 없다)\n", NS, neg);
		return _Verdict("act_topk_abs", "dScore", num.Data(), dZ.Data(), NZ,
			"⚠️⚠️ 선택 고정 조건부 · 해석 기울기는 **`act_topk_bwd` 그대로**");
	}

	// ══════════════════════════════════════════════════════════════════
	// 🔧 계수 갱신 STE — ids와 보정량 δ를 고정하고 `mag₁=mag₀+δ`만 미분한다.
	//   최종 재구성까지 통과시킨 dMag를 중앙차분과 견주므로, 회차 40의 실제 합성 경로를 검사한다.
	//   δ 자체와 δ를 만든 target/table 경로는 의도적으로 stop-gradient다.
	// ══════════════════════════════════════════════════════════════════
	static int _ActCoeffSte()
	{
		const uint32 R = 3, K = 3, P = 7, DICT = 8, NS = R * K, NY = R * P;
		Array<float> ids, mag, delta, table, target, finalMag, y, dOut, ana, num;
		_Zero(ids, NS); _Fill(mag, NS, 451, 0.6f); _Fill(delta, NS, 452, 0.35f);
		_Fill(table, DICT * P, 453, 0.5f); _Fill(target, NY, 454, 0.4f);
		_Zero(finalMag, NS); _Zero(y, NY); _Zero(dOut, NY); _Zero(ana, NS); _Zero(num, NS);
		for (uint32 r = 0; r < R; ++r)
			for (uint32 j = 0; j < K; ++j) ids.Data()[r * K + j] = (float)((r * K + j * 2u + 1u) % DICT);
		for (uint32 i = 0; i < NS; ++i) finalMag.Data()[i] = mag.Data()[i] + delta.Data()[i];
		MLVisReconCpu(ids.Data(), finalMag.Data(), table.Data(), y.Data(), R, K, P, DICT);
		_DOut(y.Data(), target.Data(), dOut.Data(), NY);
		MLVisReconMagBwdCpu(ids.Data(), table.Data(), dOut.Data(), ana.Data(), R, K, P, DICT);
		for (uint32 i = 0; i < NS; ++i)
		{
			const float keep = mag.Data()[i];
			mag.Data()[i] = keep + kEps;
			for (uint32 q = 0; q < NS; ++q) finalMag.Data()[q] = mag.Data()[q] + delta.Data()[q];
			MLVisReconCpu(ids.Data(), finalMag.Data(), table.Data(), y.Data(), R, K, P, DICT);
			const float lp = _Loss(y.Data(), target.Data(), NY);
			mag.Data()[i] = keep - kEps;
			for (uint32 q = 0; q < NS; ++q) finalMag.Data()[q] = mag.Data()[q] + delta.Data()[q];
			MLVisReconCpu(ids.Data(), finalMag.Data(), table.Data(), y.Data(), R, K, P, DICT);
			const float lm = _Loss(y.Data(), target.Data(), NY);
			mag.Data()[i] = keep;
			num.Data()[i] = (lp - lm) / (2.0f * kEps);
		}
		return _Verdict("act_coeff_ste", "dMag0", num.Data(), ana.Data(), NS,
			"⚠️ δ·ids 고정 조건부 · dmag0=dmag1 · δ 경로 stop-gradient");
	}

	static int _VisRecon()
	{
		const uint32 R = 3, K = 2, P = 5, DICT = 6;
		const uint32 NR = R * P, NM = R * K, NT = DICT * P;
		Array<float> ids, mag, tab, y, t, dOut, dMag, dTab, num;
		_Fill(mag, NM, 81); _Fill(tab, NT, 82); _Fill(t, NR, 83);
		ids.Reset(0); for (uint32 i = 0; i < NM; ++i) ids.Add((float)((i * 5u + 1u) % DICT));
		_Zero(y, NR); _Zero(dOut, NR); _Zero(dMag, NM); _Zero(dTab, NT);

		MLVisReconCpu(ids.Data(), mag.Data(), tab.Data(), y.Data(), R, K, P, DICT);
		_DOut(y.Data(), t.Data(), dOut.Data(), NR);
		MLVisReconMagBwdCpu(ids.Data(), tab.Data(), dOut.Data(), dMag.Data(), R, K, P, DICT);
		MLVisReconTabBwdCpu(ids.Data(), mag.Data(), dOut.Data(), dTab.Data(), R, K, P, DICT);

		int fail = 0;
		_Zero(num, NM);
		for (uint32 i = 0; i < NM; ++i) num.Data()[i] = _NumVis(ids, mag, tab, t, R, K, P, DICT, i, true);
		fail += _Verdict("vis_recon", "dMag", num.Data(), dMag.Data(), NM, "조건부 없음 (ids 는 입력)");
		_Zero(num, NT);
		for (uint32 i = 0; i < NT; ++i) num.Data()[i] = _NumVis(ids, mag, tab, t, R, K, P, DICT, i, false);
		fail += _Verdict("vis_recon", "dTable", num.Data(), dTab.Data(), NT, "조건부 없음 (ids 는 입력)");
		return fail;
	}

	static float _NumVis(Array<float>& ids, Array<float>& mag, Array<float>& tab, Array<float>& t,
		uint32 R, uint32 K, uint32 P, uint32 DICT, uint32 i, bool wrtMag)
	{
		const uint32 NR = R * P;
		Array<float> y; _Zero(y, NR);
		float* p = wrtMag ? mag.Data() : tab.Data();
		const float keep = p[i];
		p[i] = keep + kEps;
		MLVisReconCpu(ids.Data(), mag.Data(), tab.Data(), y.Data(), R, K, P, DICT);
		const float lp = _Loss(y.Data(), t.Data(), NR);
		p[i] = keep - kEps;
		MLVisReconCpu(ids.Data(), mag.Data(), tab.Data(), y.Data(), R, K, P, DICT);
		const float lm = _Loss(y.Data(), t.Data(), NR);
		p[i] = keep;
		return (lp - lm) / (2.0f * kEps);
	}

	// ══════════════════════════════════════════════════════════════════
	// 🌐 이동 가능한 전역 발자국 — candidate(anchor,id)는 고정하고 mag/code/X/Y 네 경로를 잰다.
	// ══════════════════════════════════════════════════════════════════
	static int _FootRecon()
	{
		const uint32 F = 2, K = 3, G = 3, P = 5, DICT = 4, RANK = 2, SPAN = 5;
		const uint32 NM = F * K, NY = F * G * G * P, NC = DICT * P, NS = DICT * RANK * SPAN;
		Array<float> ids, mag, code, x, y, out, tgt, dOut, dMag, dCode, dX, dY, num;
		_Fill(mag, NM, 461, 0.5f); _Fill(code, NC, 462, 0.4f);
		_Fill(x, NS, 463, 0.6f); _Fill(y, NS, 464, 0.6f); _Fill(tgt, NY, 465, 0.5f);
		ids.Reset(0);
		for (uint32 i = 0; i < NM; ++i)
		{
			const uint32 anchor = (i * 5u + 1u) % (G * G), v = (i * 2u + 1u) % DICT;
			ids.Add((float)(anchor * DICT + v));
		}
		_Zero(out, NY); _Zero(dOut, NY); _Zero(dMag, NM); _Zero(dCode, NC); _Zero(dX, NS); _Zero(dY, NS);
		MLFootReconCpu(ids.Data(), mag.Data(), code.Data(), x.Data(), y.Data(), out.Data(),
			F, K, G, P, DICT, RANK, SPAN);
		_DOut(out.Data(), tgt.Data(), dOut.Data(), NY);
		MLFootReconMagBwdCpu(ids.Data(), code.Data(), x.Data(), y.Data(), dOut.Data(), dMag.Data(),
			F, K, G, P, DICT, RANK, SPAN);
		MLFootReconCodeBwdCpu(ids.Data(), mag.Data(), x.Data(), y.Data(), dOut.Data(), dCode.Data(),
			F, K, G, P, DICT, RANK, SPAN);
		MLFootReconSpaceBwdCpu(ids.Data(), mag.Data(), code.Data(), x.Data(), y.Data(), dOut.Data(),
			dX.Data(), dY.Data(), F, K, G, P, DICT, RANK, SPAN);

		int fail = 0;
		_Zero(num, NM); for (uint32 i = 0; i < NM; ++i)
			num.Data()[i] = _NumFoot(ids, mag, code, x, y, tgt, F, K, G, P, DICT, RANK, SPAN, 0u, i);
		fail += _Verdict("foot_recon", "dMag", num.Data(), dMag.Data(), NM, "⚠️ candidate(top-k) 고정 조건부");
		_Zero(num, NC); for (uint32 i = 0; i < NC; ++i)
			num.Data()[i] = _NumFoot(ids, mag, code, x, y, tgt, F, K, G, P, DICT, RANK, SPAN, 1u, i);
		fail += _Verdict("foot_recon", "dCode", num.Data(), dCode.Data(), NC, "candidate 고정");
		_Zero(num, NS); for (uint32 i = 0; i < NS; ++i)
			num.Data()[i] = _NumFoot(ids, mag, code, x, y, tgt, F, K, G, P, DICT, RANK, SPAN, 2u, i);
		fail += _Verdict("foot_recon", "dX", num.Data(), dX.Data(), NS, "rank=2 · 상대좌표");
		_Zero(num, NS); for (uint32 i = 0; i < NS; ++i)
			num.Data()[i] = _NumFoot(ids, mag, code, x, y, tgt, F, K, G, P, DICT, RANK, SPAN, 3u, i);
		fail += _Verdict("foot_recon", "dY", num.Data(), dY.Data(), NS, "rank=2 · 상대좌표");
		return fail;
	}

	static float _NumFoot(Array<float>& ids, Array<float>& mag, Array<float>& code, Array<float>& x,
		Array<float>& y, Array<float>& tgt, uint32 F, uint32 K, uint32 G, uint32 P, uint32 DICT,
		uint32 RANK, uint32 SPAN, uint32 which, uint32 i)
	{
		Array<float> out; _Zero(out, F * G * G * P);
		float* a = (which == 0u) ? mag.Data() : ((which == 1u) ? code.Data() : ((which == 2u) ? x.Data() : y.Data()));
		const float keep = a[i];
		a[i] = keep + kEps;
		MLFootReconCpu(ids.Data(), mag.Data(), code.Data(), x.Data(), y.Data(), out.Data(),
			F, K, G, P, DICT, RANK, SPAN);
		const float lp = _Loss(out.Data(), tgt.Data(), out.Count());
		a[i] = keep - kEps;
		MLFootReconCpu(ids.Data(), mag.Data(), code.Data(), x.Data(), y.Data(), out.Data(),
			F, K, G, P, DICT, RANK, SPAN);
		const float lm = _Loss(out.Data(), tgt.Data(), out.Count());
		a[i] = keep;
		return (lp - lm) / (2.0f * kEps);
	}

	// ══════════════════════════════════════════════════════════════════
	// 🧱 patch_embed — bwd 가 **둘**인데 커널은 **하나**다:
	//   `dSlotTable` 은 `patch_embed_bwd` 가 내고, ⭐ **`dPosTable` 은 `dOut` 자체**다
	//   (forward 가 그냥 더하므로 미분이 1 이고 배치가 글자 그대로 같다).
	//   ⭐ **그 지름길을 여기서 검사한다** — 주석으로만 있는 주장은 검사가 아니고, 틀리면 증상이
	//     *"자리를 좀 못 배운다"* 라서 **학습 곡선으로 절대 안 보인다.**
	// ⚠️ 프레임 값에 **300 을 한 칸 섞는다** — `b > 255 → 0` 접기 규약을 fwd/bwd 가 **같이** 지키는지
	//   보는 자리다(한쪽만 접으면 기울기가 엉뚱한 행으로 가고 증상은 "학습이 좀 느리다" 뿐이다).
	// ⚠️ 바이트를 **다섯 종류**로 좁힌다 — gather 가 맞는지는 **같은 자리에 같은 값이 여러 패치에서**
	//   나올 때만 드러난다(합이 한 항뿐이면 순서도 누락도 티가 안 난다).
	// ══════════════════════════════════════════════════════════════════
	static int _PatchEmbed()
	{
		const uint32 W = 6, H = 4, K = 2, D = 3;
		const uint32 P = (W / K) * (H / K), SR = K * K * 256u;
		const uint32 NO = P * D, NS = SR * D, NP = P * D;
		Array<float> frame, slot, pos, y, t, dOut, dSlot, num;
		_Fill(slot, NS, 91, 0.5f); _Fill(pos, NP, 92); _Fill(t, NO, 93);
		frame.Reset(0);
		for (uint32 i = 0; i < W * H; ++i) frame.Add((float)((i * 7u + 1u) % 5u));
		frame.Data()[W * H / 2u] = 300.0f;   // ⚠️ 접기 분기(→ 0 행)
		_Zero(y, NO); _Zero(dOut, NO); _Zero(dSlot, NS);

		MLPatchEmbedCpu(frame.Data(), slot.Data(), pos.Data(), y.Data(), W, H, K, D);
		_DOut(y.Data(), t.Data(), dOut.Data(), NO);
		MLPatchEmbedBwdCpu(frame.Data(), dOut.Data(), dSlot.Data(), W, H, K, D);

		int fail = 0;
		_Zero(num, NS);
		for (uint32 i = 0; i < NS; ++i) num.Data()[i] = _NumPE(frame, slot, pos, t, W, H, K, D, i, true);
		fail += _Verdict("patch_embed", "dSlot", num.Data(), dSlot.Data(), NS,
			"조건부 없음 (frame 은 입력) · 300 한 칸 = 접기 분기 포함");
		_Zero(num, NP);
		for (uint32 i = 0; i < NP; ++i) num.Data()[i] = _NumPE(frame, slot, pos, t, W, H, K, D, i, false);
		// ⭐ 여기서 「해석 기울기」로 넣는 것이 **`dOut` 그 자체**다 — 커널이 없다는 주장을 그대로 검사한다.
		fail += _Verdict("patch_embed", "dPos", num.Data(), dOut.Data(), NP,
			"⭐ 커널 없음 — `dPos == dOut` 주장을 검사한다");
		return fail;
	}

	static float _NumPE(Array<float>& frame, Array<float>& slot, Array<float>& pos, Array<float>& t,
		uint32 W, uint32 H, uint32 K, uint32 D, uint32 i, bool wrtSlot)
	{
		const uint32 NO = (W / K) * (H / K) * D;
		Array<float> y; _Zero(y, NO);
		float* p = wrtSlot ? slot.Data() : pos.Data();
		const float keep = p[i];
		p[i] = keep + kEps;
		MLPatchEmbedCpu(frame.Data(), slot.Data(), pos.Data(), y.Data(), W, H, K, D);
		const float lp = _Loss(y.Data(), t.Data(), NO);
		p[i] = keep - kEps;
		MLPatchEmbedCpu(frame.Data(), slot.Data(), pos.Data(), y.Data(), W, H, K, D);
		const float lm = _Loss(y.Data(), t.Data(), NO);
		p[i] = keep;
		return (lp - lm) / (2.0f * kEps);
	}

	// ══════════════════════════════════════════════════════════════════
	// ➖ sub — ⚠️⚠️ **이 검사의 내용은 「뺄셈이 맞나」가 아니다**(그것은 판정 ① 의 일이다).
	//   ★ `sub` 는 **해석 기울기 자체**인 커널이라 ② 가 볼 것은 그 **동일시**다:
	//     *"`½Σ(a−t)²` 의 미분이 정말 `a − t` 인가"*. P2 가 MSE 로 학습하는 근거가 그 한 줄이고,
	//     그것이 어긋나면(예: 인자 순서) **부호가 뒤집혀 손실이 올라간다.**
	//   ⚠️ 그래서 `dB` 도 같이 본다 — **인자 순서 사고를 잡는 자리는 거기**다(`dB == −dA`).
	//   ⚠️ 손실을 내는 `_Loss` 와 기울기를 내는 `MLSubCpu` 는 **다른 코드**다 ⇒ 자기참조가 아니다.
	// ══════════════════════════════════════════════════════════════════
	static int _Sub()
	{
		const uint32 N = 37;
		Array<float> a, t, g, num, neg;
		_Fill(a, N, 101); _Fill(t, N, 102); _Zero(g, N);
		MLSubCpu(a.Data(), t.Data(), g.Data(), N);   // = 해석 기울기 dA

		int fail = 0;
		_Zero(num, N);
		for (uint32 i = 0; i < N; ++i) num.Data()[i] = _NumSub(a, t, N, i, true);
		fail += _Verdict("sub", "dA", num.Data(), g.Data(), N,
			"⭐ MSE 기울기의 **동일시** 검사(뺄셈 자체는 ①)");
		_Zero(neg, N);
		for (uint32 i = 0; i < N; ++i) neg.Data()[i] = -g.Data()[i];
		_Zero(num, N);
		for (uint32 i = 0; i < N; ++i) num.Data()[i] = _NumSub(a, t, N, i, false);
		fail += _Verdict("sub", "dB", num.Data(), neg.Data(), N, "인자 순서 사고를 잡는 자리");
		return fail;
	}

	static float _NumSub(Array<float>& a, Array<float>& t, uint32 N, uint32 i, bool wrtA)
	{
		float* p = wrtA ? a.Data() : t.Data();
		const float keep = p[i];
		p[i] = keep + kEps; const float lp = _Loss(a.Data(), t.Data(), N);
		p[i] = keep - kEps; const float lm = _Loss(a.Data(), t.Data(), N);
		p[i] = keep;
		return (lp - lm) / (2.0f * kEps);
	}
};
