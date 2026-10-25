// mltkernels.cw — 🪞 **MLT 커널의 호스트 짝** (push struct + CPU 레퍼런스)
//
// ★ **이 파일이 있는 이유** — 커널마다 짝이 **둘** 필요하다:
//   ㈀ 셰이더의 push struct 와 **바이트가 같은** 호스트 struct
//   ㈁ 그 커널의 **CPU 레퍼런스**(GPU 결과를 견줄 오라클)
//   ⇒ `MLCore` 가 자기 역할을 *"텐서 아레나 · 커널 · CPU 레퍼런스"* 로 못 박았으므로 자리는 여기다.
//     조립·세계·러너는 `Sources/MLT/` 다(→ 그 `module.toml` 의 그 절).
//
// ⚠️⚠️ **`mlgpu.cw` 와 갈라 둔 이유** — 그 파일은 780줄이고 **형제 트랙이 계속 고친다.**
//   커널을 늘리는 일이 그 파일을 건드리면 회차마다 병합 충돌이 난다. `.cw` 는 파일이 독립이라
//   갈라 두는 비용이 0 이다.
//
// ⚠️⚠️⚠️ **조용히 틀리는 자리 셋** — 전부 실측으로 밟힌 계열이다:
//   ㉠ **push struct 의 배치가 셰이더와 어긋나면** 크래시가 아니라 **조용히 틀린 결과**다.
//      ⇒ 필드 순서는 **uint 오프셋 → uint 크기 → float 는 반드시 맨 뒤**(중간에 끼운 float 가 함정).
//   ㉡ **누산 순서가 셰이더와 다르면** 정확한 커널이 판정에서 떨어진다 ⇒ 둘 다 **오름차순**.
//   ㉢ **`MLMaxRelErr` 을 0 을 지나는 출력에 쓰면** 분모 바닥이 절대오차를 증폭해 멀쩡한 커널을
//      떨어뜨린다 ⇒ 그런 출력은 **`MLMaxAbsErr / MLMaxAbs`**(정규화 절대오차)로 본다.
//
// ★ 판정 규약과 조건부(⚠️ `act_topk` 의 「선택 고정」 · `val_enc` 의 「계수 고정」 · `stopgrad` 의
//   두 검사 분리)는 `Projects/ML/MLT.md` 의 🪞·🏗 절이 정본이다 — 코드가 갈리면 문서가 이긴다.

using namespace PE;

// ==============================================================================
// 📏 RMSNorm — 행마다 RMS 정규화(평균을 빼지 않는다)
// ==============================================================================

// ─────────────────────────────────────────────────────────────────────────────
// 📏 RMSNorm — 호스트 push struct 3개 + CPU 레퍼런스 3개
//   셰이더: `rmsnorm.cs.hlsl` · `rmsnorm_bwd.cs.hlsl` · `rmsnorm_gbwd.cs.hlsl`
// ─────────────────────────────────────────────────────────────────────────────

// `rmsnorm.cs.hlsl` 의 `RmsNormParams`. ⚠️⚠️ **마지막이 `float` 다**(함정 33).
//   ★ `rstd`(rows×1)를 따로 낸다 — bwd 가 fwd 와 **정확히 같은 값**을 봐야 gradcheck 판정이 흐려지지 않는다.
//   ⚠️ `eps` 는 평균 **안쪽**이다(`1/√(mean+eps)`) — 밖에 두면 스케일이 갈린다.
struct MLRmsNormParams
{
	uint32 inOff = 0, gainOff = 0, outOff = 0, rstdOff = 0;
	uint32 rows = 0, cols = 0;
	float  eps = 1.0e-6f;
};

// `rmsnorm_bwd.cs.hlsl` 의 `RmsNormBwdParams`.
//   ★ float 필드가 없다 — `eps` 는 fwd 가 이미 `rstd` 에 접어 넣었다. 남는 칸은 `pad0` 로 **명시**한다.
struct MLRmsNormBwdParams
{
	uint32 inOff = 0, gainOff = 0, rstdOff = 0, dOutOff = 0;
	uint32 dInOff = 0, rows = 0, cols = 0, pad0 = 0;
};

// `rmsnorm_gbwd.cs.hlsl` 의 `RmsNormGBwdParams`.
//   ★ **왜 별 커널인가**: `dG[d] = Σ_t (…)` 는 **행 방향 리덕션**이라 bwd 의 스레드 배정(행 하나 =
//     스레드 하나)과 축이 정반대다. 섞으면 여러 스레드가 같은 `dG[d]` 에 더해야 하고 그것은
//     float atomic + **비결정적 누산 순서**다 ⇒ CPU 대조 판정이 무너진다. 그래서 갈라서 gather 로 만든다.
struct MLRmsNormGBwdParams
{
	uint32 inOff = 0, rstdOff = 0, dOutOff = 0, dGainOff = 0;
	uint32 rows = 0, cols = 0;
};

// 📏◀ **CPU 레퍼런스 — RMSNorm.** `rstd` 도 낸다(bwd 가 fwd 와 **같은 값**을 봐야 하므로).
//   ★ **평균을 빼지 않는다** — LayerNorm 이 아니다(pre-norm · 바이어스 없음이 이 트랙의 규약).
//   ⚠️ `eps` 는 평균 **안쪽**이다 — 셰이더와 같은 자리.
//   ⚠️ 누산 순서는 `j` 오름차순 — 셰이더와 같아야 견줄 수 있다.
//   ★ 출력이 둘인 예외 사유: 행 `r` 의 두 칸(`out` 행 · `rstd[r]`)의 **유일한 주인이 한 스레드**이고
//     리덕션이 끼지 않는다(§3.2 예외 ㉢).
CW_EXPORT void MLRmsNormCpu(const float* in, const float* gain, float* out, float* rstd,
	uint32 rows, uint32 cols, float eps = 1.0e-6f)
{
	if (in == nullptr || gain == nullptr || out == nullptr || rstd == nullptr) return;
	for (uint32 r = 0; r < rows; ++r)
	{
		const uint32 base = r * cols;
		float ss = 0.0f;
		for (uint32 j = 0; j < cols; ++j) { const float v = in[base + j]; ss += v * v; }
		const float rs = 1.0f / Sqrt(ss / (float)cols + eps);
		rstd[r] = rs;
		for (uint32 i = 0; i < cols; ++i) out[base + i] = in[base + i] * rs * gain[i];
	}
}

// 📏◀ **CPU 레퍼런스 — RMSNorm 의 입력 기울기.**
//   `dIn_i = rstd · ( dOut_i·g_i − x̂_i · (1/D)·Σ_j dOut_j·g_j·x̂_j )`,  `x̂ = x·rstd`
//   ★ 야코비안을 **행렬로 만들지 않는다** — `rstd` 가 행 전체에 의존해 대각이 아니지만,
//     위처럼 **행 내적 하나**(`Σ dOut·g·x̂`)로 접힌다(`softmax_bwd` 와 같은 관용구 · 추가 메모리 0).
//   ★ `rstd` 를 **다시 계산하지 않고 fwd 가 남긴 것을 읽는다** — 다시 계산하면 fwd 와 정확히 같은 값이라는
//     보장이 없고(누산 순서·컴파일러) 그 미세한 차가 gradcheck 판정을 흐린다.
//   ⚠️ `1/D` 를 **밖으로 빼서 `dot` 에 한 번만** 곱한다 — 원소마다 나누면 반올림이 셰이더와 갈린다.
//   ⚠️ `gain` 의 기울기는 여기서 **내지 않는다**(→ `MLRmsNormGainBwdCpu`) · 잔차 누산도 여기가 아니다(호스트).
CW_EXPORT void MLRmsNormBwdCpu(const float* in, const float* gain, const float* rstd,
	const float* dOut, float* dIn, uint32 rows, uint32 cols)
{
	if (in == nullptr || gain == nullptr || rstd == nullptr) return;
	if (dOut == nullptr || dIn == nullptr) return;
	for (uint32 r = 0; r < rows; ++r)
	{
		const uint32 base = r * cols;
		const float rs = rstd[r];
		float dot = 0.0f;
		for (uint32 j = 0; j < cols; ++j)
			dot += dOut[base + j] * gain[j] * (in[base + j] * rs);
		const float mean = dot / (float)cols;
		for (uint32 i = 0; i < cols; ++i)
			dIn[base + i] = rs * (dOut[base + i] * gain[i] - (in[base + i] * rs) * mean);
	}
}

// 📏◀ **CPU 레퍼런스 — RMSNorm 이득의 기울기.** `dGain[d] = Σ_t dOut[t][d] · in[t][d] · rstd[t]`
//   ★ 셰이더와 **같은 방향(gather)**·**같은 순서**(`t` 오름차순) — 열 `d` 의 주인이 하나뿐이라 **쓴다**(`=`).
//   ⚠️ `rstd` 는 **행마다 다르다** — 한 번 읽어 상수처럼 쓰면 조용히 틀린다.
CW_EXPORT void MLRmsNormGainBwdCpu(const float* in, const float* rstd, const float* dOut,
	float* dGain, uint32 rows, uint32 cols)
{
	if (in == nullptr || rstd == nullptr || dOut == nullptr || dGain == nullptr) return;
	for (uint32 d = 0; d < cols; ++d)
	{
		float acc = 0.0f;
		for (uint32 t = 0; t < rows; ++t)
		{
			const uint32 base = t * cols;
			acc += dOut[base + d] * in[base + d] * rstd[t];
		}
		dGain[d] = acc;   // ★ 쓴다(더하지 않는다)
	}
}

// ==============================================================================
// 🌀 RoPE — 이웃 쌍 회전. bwd 는 같은 커널의 `dirSign = -1`
// ==============================================================================

// `rope.cs.hlsl` 의 `RopeParams`.
//   ⚠️⚠️ **마지막 둘이 `float` 다**(함정 33) — 셰이더의 그 자리·그 타입과 같아야 한다.
//   ★ `dirSign` = **꼬리에 붙은 중립 기본값**(1.0). 회전은 직교(`Rᵀ = R(−φ)`)라 **`-1.0f` 이 곧 전치**
//     ⇒ **`rope_bwd` 커널이 없다**(같은 `.spv` 를 `dirSign = -1` 로 부른다 · 금지목록 23 의 예시 그 자리).
//   ★ `mode` = 0 이면 1D(시간 위치 · `pos` 는 `rows×1`), 1 이면 2D(앞 절반 채널 = x · 뒤 절반 = y ·
//     `pos` 는 `rows×2`). ⚠️ `mode == 1` 은 **`dim % 4 == 0`** 이 전제다(축마다 쌍이 정수여야 한다).
struct MLRopeParams
{
	uint32 inOff = 0, outOff = 0, posOff = 0, pad0 = 0;
	uint32 rows = 0, dim = 0, mode = 0, pad1 = 0;
	float  theta = 10000.0f, dirSign = 1.0f;

	// 여기서 한 번만 계산한다 — ★ 호출부마다 나누기를 쓰면 셰이더와 어긋난다(`MLPatchEmbedParams` 와 같은 관용구).
	uint32 Pairs() const { return dim >> 1; }                                  // 쌍 개수 = Dispatch 의 X
	uint32 AxisPairs() const { return (mode == 1u) ? (dim >> 2) : Pairs(); }    // 축 하나가 맡는 쌍
	uint32 AxisDim() const { return (mode == 1u) ? (dim >> 1) : dim; }          // 그 축의 채널 폭
	uint32 PosCount() const { return rows * ((mode == 1u) ? 2u : 1u); }         // `pos` 텐서의 원소 수
};

// 🌀 **CPU 레퍼런스 — RoPE.** 쌍 `(2p, 2p+1)` 을 `φ = pos · ω` 로 돌린다.
//   ★ **주파수를 `Exp2(e·Log2(theta))` 로 만든다 — `Pow` 가 아니다.** 근거는 엔진 `PEMath.h` 가 적어 둔
//     그것이다: GPU 의 기본 명령이 `log2`/`exp2` 라 **셰이더와 같은 식**을 써야 값이 맞는다.
//     ⚠️ 초월함수라 오차 0 은 요구하지 않는다 — 임계는 1e-5(금지목록 19).
//   ★ **2D 는 축마다 「전 대역」을 준다**(축 폭을 `dim/2` 로 보고 그 안에서 `ω` 를 편다) ⇒ x·y 가 같은
//     분해능이다. ⚠️ 전역 `p` 로 대역을 매기면 x 는 고주파만, y 는 저주파만 받아 **세로 위치가 뭉개진다**
//     (회전이라 값은 멀쩡해서 조용히 틀린다).
//   ⚠️ 쌍은 **이웃 두 칸**이다(반쪽 갈라 `(p, p+dim/2)` 로 짝짓는 판이 아니다) — 셰이더와 같은 규약.
//   ⚠️ 축 선택을 **나누기 대신 비교**로 한다(`dim < 4` 여도 0 나눗셈이 없다) — 셰이더와 같은 식.
//   ★ 제자리(`in == out`)가 안전하다 — 쌍 두 칸을 **먼저 읽고** 쓴다(셰이더도 같다).
CW_EXPORT void MLRopeCpu(const float* in, const float* pos, float* out,
	uint32 rows, uint32 dim, uint32 mode, float theta = 10000.0f, float dirSign = 1.0f)
{
	if (in == nullptr || pos == nullptr || out == nullptr) return;
	const uint32 pairs = dim >> 1;
	const bool bTwoD = (mode == 1u);
	const uint32 axisPairs = bTwoD ? (dim >> 2) : pairs;
	const uint32 axisDim = bTwoD ? (dim >> 1) : dim;
	if (pairs == 0u || axisDim == 0u) return;
	for (uint32 r = 0; r < rows; ++r)
	{
		for (uint32 p = 0; p < pairs; ++p)
		{
			const uint32 axis = (bTwoD && p >= axisPairs) ? 1u : 0u;   // 0 = x, 1 = y
			const uint32 pl = p - axis * axisPairs;                    // 축 안에서의 쌍 번호
			const float e = -2.0f * (float)pl / (float)axisDim;
			const float w = Exp2(e * Log2(theta));                     // ω = theta^(−2·pl/axisDim)
			const float ang = pos[bTwoD ? (r * 2u + axis) : r] * w;
			const float c = Cos(ang);
			const float s = Sin(ang) * dirSign;                        // ★ 부호만 뒤집으면 전치다
			const uint32 i0 = r * dim + 2u * p, i1 = i0 + 1u;
			const float x0 = in[i0], x1 = in[i1];                      // ★ 먼저 읽는다(제자리 안전)
			out[i0] = x0 * c - x1 * s;
			out[i1] = x0 * s + x1 * c;
		}
	}
}

// 🌀◀ **CPU 레퍼런스 — RoPE 의 기울기.** ★ **식이 하나도 없다 — 회전의 전치는 역회전이다**
//   (`dirSign = -1`). 그래서 이 함수는 위 것을 부르는 것으로 끝이고, **커널도 새 파일이 없다**.
//   ⚠️ **`pos` 의 기울기는 내지 않는다** — 위치는 정수이고 학습 대상이 아니다.
//   ⚠️ nullptr 검사는 `MLRopeCpu` 의 첫 줄이 한다(같은 검사를 두 벌 두지 않는다).
//   ⚠️ `theta`/`mode`/`dim` 은 forward 와 **같은 값**을 줘야 한다 — 한쪽만 바꾸면 대역이 갈려
//     기울기가 조용히 틀리고 증상이 *"학습이 느리다"* 가 된다(`softmax` 의 `scale` 과 같은 계열의 함정).
CW_EXPORT void MLRopeBwdCpu(const float* dOut, const float* pos, float* dIn,
	uint32 rows, uint32 dim, uint32 mode, float theta = 10000.0f)
{
	MLRopeCpu(dOut, pos, dIn, rows, dim, mode, theta, -1.0f);
}

// ==============================================================================
// 🎯 인과 마스크 softmax — QKᵗ·AV 는 기존 `gemm`, bwd 는 기존 `softmax_bwd`
// ==============================================================================

// `attn_softmax.cs.hlsl` 의 `AttnSoftmaxParams` — 👁️ 인과 마스크가 달린 행 softmax.
//   ★ **새 파일이 이것 하나인 이유** = 어텐션에서 기존 커널로 안 되는 자리가 **마스크뿐**이다.
//     `S = Q·Kᵀ` 는 `gemm(transB=1)` · `O = Pr·V` 는 `gemm` · 온도 `1/√Dh` 는 `softmax` 의 `scale` 칸.
//     ⇒ `attn`(융합) 도 `attn_bwd` 도 만들지 않는다.
//   ★ **bwd 는 기존 `MLSoftmaxBwdCpu`/`softmax_bwd.cs.hlsl` 를 그대로 쓴다** — 마스크 칸은 `p = 0` 이라
//     행 내적에 기여가 0 이고 `dIn_i = scale·p_i·(dOut_i − dot)` 도 정확히 0 이 된다.
//     ⚠️ 그 전제가 「마스크 칸이 **정확히 0**」이라 fwd 의 `0.0f` 대입은 성능이 아니라 **정확성**이다.
//   ★ `Dh` 는 **이 계약에 없다** — 호스트가 접은 `scale = 1/√Dh` 와 `gemm` 의 논리 크기로만 들어온다.
//     ⚠️⚠️ `scale` 은 fwd(이 커널)와 bwd(`MLSoftmaxBwdParams::scale`)에 **같은 값**을 준다 —
//       한쪽만 주면 기울기가 `1/√Dh` 배 틀리고 증상이 *"학습이 느리다"* 라서 버그로 안 읽힌다.
//   ★ `causalOff` = 첫 질의 앞에 **이미 있는 키 개수**(지금은 0). KV 캐시가 생기면 `Pr` 이 `T_q × T_k` 로
//     직사각이 되면서 이 칸이 쓰인다 ⇒ 지금 0 을 넣어 두면 그때 계약을 안 고친다.
//   ⚠️⚠️ **마지막이 `float` 다** — 셰이더의 그 자리와 타입이 같아야 한다(함정 33).
struct MLAttnSoftmaxParams
{
	uint32 inOff = 0, outOff = 0, rows = 0, cols = 0;
	uint32 causalOff = 0, pad0 = 0;
	float  scale = 1.0f;
};

// 👁️ **CPU 레퍼런스 — 인과 마스크 softmax.** `Pr[r][j] = exp(S·scale − max)/Σ` (단 `j > r + causalOff` 는 **0**)
//   ⚠️ 최댓값은 **온도를 곱한 뒤** · **허용 칸에서만** 잰다(셰이더와 같은 순서 — 마스크 칸이 최댓값을
//     잡으면 안정화가 어긋나 값이 통째로 갈린다).
//   ⚠️ 누산 순서는 `j` 오름차순 — 셰이더와 같아야 견줄 수 있다.
//   ★ 대각(`j == r`)은 언제나 허용이라 **행이 통째로 마스크되는 일이 없다** ⇒ `sum >= 1`, 0 나눗셈이 원리적으로 없다.
//   ⚠️ 이 커널의 짝 bwd 는 **`MLSoftmaxBwdCpu`** 다 — `MLAttnSoftmaxBwdCpu` 를 만들지 마라(위 근거).
CW_EXPORT void MLAttnSoftmaxCpu(const float* in, float* out, uint32 rows, uint32 cols,
	uint32 causalOff, float scale = 1.0f)
{
	if (in == nullptr || out == nullptr || cols == 0u) return;
	for (uint32 r = 0; r < rows; ++r)
	{
		const uint32 base = r * cols;

		// ⓪ 허용 상한 — 열 수를 넘으면 **전부 허용**으로 접는다(셰이더와 같은 규약).
		uint32 last = r + causalOff;
		if (last >= cols) last = cols - 1u;

		// ① 행 최댓값 — 온도를 곱한 뒤 · 허용 칸에서만.
		float mx = in[base] * scale;
		for (uint32 j = 1; j <= last; ++j)
		{ const float z = in[base + j] * scale; if (z > mx) mx = z; }

		// ② exp 합 — 쓰면서 더한다(두 번 계산하지 않는다).
		float sum = 0.0f;
		for (uint32 j = 0; j <= last; ++j)
		{ const float e = Exp(in[base + j] * scale - mx); out[base + j] = e; sum += e; }

		// ③ 정규화 + **마스크 칸에 정확히 0** — 뒤의 `gemm(O = Pr·V)` 은 마스크를 모른다.
		//   ⚠️ 앞 스텝이 남긴 값일 수 있으니 「안 쓰기」가 아니라 **쓴다**.
		const float inv = 1.0f / sum;
		for (uint32 j = 0; j < cols; ++j)
			out[base + j] = (j <= last) ? (out[base + j] * inv) : 0.0f;
	}
}

// ==============================================================================
// 🚪 SwiGLU 의 원소 부분 — 「끄기」가 여기 있다
// ==============================================================================

// `swiglu.cs.hlsl` 의 `SwigluParams` — 원소별 `y = silu(a) ⊙ b`.
//   ★ 입력이 **두 텐서**다(하나로 이어 붙이지 않는다) — `gemm` 에 간격 인자가 없으므로
//     `x·[W1|W3]` 한 방으로 굽고 반씩 잘라 쓰는 길이 애초에 막혀 있다.
//   ⚠️ float 손잡이가 하나도 없다 ⇒ 함정 33(중간에 끼운 float)이 아예 안 생긴다.
//   ★ `count = rows · H`(모양을 몰라도 되는 원소별 커널이라 `rows`/`H` 를 따로 안 받는다).
struct MLSwigluParams
{
	uint32 aOff = 0, bOff = 0, outOff = 0, count = 0;
};

// `swiglu_bwd.cs.hlsl` 의 `SwigluBwdParams` — 출력이 **둘**(`dA`/`dB`)이다.
//   ★ 그 예외의 근거: 원소별이라 스레드 `i` 가 `dA[i]`·`dB[i]` **둘 다의 유일한 필자**이고
//     **리덕션이 끼지 않는다**. 가르면 `a`·`b`·`dOut` 세 텐서를 두 번 읽는다(디스패치도 둘).
//   ⚠️ `MLSwigluParams` 와 **배치가 다르다**(필드가 여섯) — 한 구조체로 묶지 마라.
struct MLSwigluBwdParams
{
	uint32 aOff = 0, bOff = 0, dOutOff = 0, dAOff = 0;
	uint32 dBOff = 0, count = 0;
};

// 🚪 **CPU 레퍼런스 — SwiGLU 의 원소 부분.** `y = silu(a) ⊙ b`, `silu(z) = z·σ(z)`
//   ★ `σ` 는 **`1/(1+Exp(-z))` 한 가지 식**으로 못 박는다 — `0.5·(1+tanh(z/2))` 같은 동등한
//     항등식으로 쓰면 셰이더와 **마지막 비트가 갈린다**. ⚠️ 초월함수가 끼므로 판정 임계는 1e-5 다
//     (`relu` 처럼 오차 0 을 요구할 수 없다).
//   ⚠️ `a` 가 게이트(silu 를 먹는 쪽) · `b` 가 값이다 — 셰이더와 **같은 자리**.
//   ★ `x·W1`/`x·W3`/`·Wd` 는 여기 없다(전부 `gemm` 이다) — 이 함수는 원소 부분만 맡는다.
CW_EXPORT void MLSwigluCpu(const float* a, const float* b, float* out, uint32 count)
{
	if (a == nullptr || b == nullptr || out == nullptr) return;
	for (uint32 i = 0; i < count; ++i)
	{
		const float s = Sigmoid(a[i]);   // ⚠️ 이 식 하나 — 셰이더와 같은 자리(Core 의 그 래퍼)
		out[i] = (a[i] * s) * b[i];
	}
}

// 🚪◀ **CPU 레퍼런스 — SwiGLU 의 기울기.** `dB = dOut·(a·s)` · `dA = dOut·b·s·(1 + a·(1−s))`, `s = σ(a)`
//   ★ **출력 둘의 예외** — 원소별이라 `i` 가 `dA[i]`·`dB[i]` 둘 다의 유일한 주인이고 리덕션이 없다.
//   ★ **활성 전 값 `a` 를 본다**(활성 후가 아니다) — `silu` 는 단조가 아니라(`a ≈ −1.278` 아래로
//     다시 올라간다) 활성 후 값에서 `a` 를 되찾을 수 없다. `relu_bwd` 와 같은 규약이고, 그래서 fwd 가
//     중간 텐서(`silu(a)`)를 남길 이유도 없다.
//   ★ **`silu'(a) = s·(1 + a·(1−s))` 로 접어 쓴다** — `s + a·s·(1−s)` 로 펼치면 부동소수 결과가
//     셰이더와 마지막 비트에서 갈린다. ⚠️ **연산 순서까지** 셰이더와 글자 그대로 같게 둔다.
CW_EXPORT void MLSwigluBwdCpu(const float* a, const float* b, const float* dOut,
	float* dA, float* dB, uint32 count)
{
	if (a == nullptr || b == nullptr || dOut == nullptr || dA == nullptr || dB == nullptr) return;
	for (uint32 i = 0; i < count; ++i)
	{
		const float s  = Sigmoid(a[i]);   // ⚠️ fwd 와 **같은 식**(Core 의 그 래퍼 — 두 자리가 갈리면 안 된다)
		const float dy = dOut[i];
		dB[i] = dy * (a[i] * s);                                       // ∂y/∂b = silu(a)
		dA[i] = dy * b[i] * (s * (1.0f + a[i] * (1.0f - s)));          // ∂y/∂a = b · silu'(a)
	}
}

// ==============================================================================
// 📉 로짓에서 바로 교차엔트로피 — 값·신뢰 채널이 전부 버킷 CE 다
// ==============================================================================

// `ce_logits.cs.hlsl` 의 `CeLogitsParams`.
//   ★ **표적은 「id 하나」다**(밀집 one-hot 이 아니다) — `V = kVocab` 이 1000 을 넘으므로 one-hot 을
//     실체화하면 `R×V` 짜리 0 행렬을 쓰고 또 읽는 짓이 된다. id 는 `R` 개 float 이면 끝이다.
//   ⚠️⚠️ **무효 표적은 「0 행으로 접지」 않는다** — `embed`/`span_embed` 는 더러운 값을 0 으로 접지만
//     CE 에서 그 관용구는 **조용히 틀린 학습**이다(표적 없는 자리마다 *"정답은 0번 심볼"* 을 가르친다).
//     ⇒ 규약은 **행을 빼는 것**: `target ≥ cols` · `target == ignoreIdx` · **음수** ⇒ `loss = 0` · `dLogits = 0`.
//   ⚠️ `ignoreIdx` 를 **0 으로 두지 마라** — 0 은 멀쩡한 심볼 id 다. 끄려면 `0xFFFFFFFFu`.
//   ★ float 필드가 **없다** ⇒ 꼬리는 `pad0` 다(8×uint32 = 32바이트. SPIR-V 로 확인했다).
struct MLCeLogitsParams
{
	uint32 logitsOff = 0, targetOff = 0, probsOff = 0, lossOff = 0;
	uint32 rows = 0, cols = 0, ignoreIdx = 0xFFFFFFFFu, pad0 = 0;
};

// `ce_logits_bwd.cs.hlsl` 의 `CeLogitsBwdParams`. ⚠️ 마지막이 **`float`** 다(함정 33 · 32바이트 자리).
//   ★ `lossScale` 은 **호스트가 계산해 넘긴다**(보통 `1/유효행수`) — 커널은 행을 세지 않는다.
//     세게 하려면 리덕션이 필요하고, 무엇보다 "유효행" 의 정의가 **채널마다 다르다**(값·신뢰·활성이
//     각자 다른 마스크를 쓴다) ⇒ 배관의 판단이지 커널의 판단이 아니다.
//   ⚠️⚠️ fwd 의 `loss[r]` 합에는 이 배율이 **안 들어있다** — 곡선을 찍을 때 호스트가 같은 배율로 나눠야
//     기울기와 **같은 목적함수**를 보는 것이 된다(안 맞추면 "손실은 안 주는데 학습은 된다").
struct MLCeLogitsBwdParams
{
	uint32 probsOff = 0, targetOff = 0, dLogitsOff = 0, pad0 = 0;
	uint32 rows = 0, cols = 0, ignoreIdx = 0xFFFFFFFFu, pad1 = 0;
	float  lossScale = 1.0f;
};

// 🎯 **CPU 레퍼런스 — 로짓에서 바로 교차엔트로피.** `probs = softmax(logits)` · `loss[r] = −log probs[r][target[r]]`
//   ★ **기존 `MLCrossEntropyCpu` 와 다른 물건이다** — 그쪽은 이미 softmax 된 `probs` 를 받아
//     **스칼라 하나**(자리마다 평균)를 내고 무효 표적을 **0 으로 접는다**. 이쪽은 ㉠ **로짓**을 받아
//     softmax 를 직접 하고 ㉡ **행마다** 손실을 내고 ㉢ 무효 표적을 **행째로 뺀다**. 헷갈리면 조용히 틀린다.
//     ⇒ 행별 손실이 필요한 이유: 표적 없는 자리(패딩·아직 안 온 프레임)를 행 단위로 빼야 하고,
//       값·신뢰 채널이 **버킷 CE** 라 채널마다 손실을 갈라 봐야 한다(연속량 MSE 는 다봉을 평균으로 접는다).
//   ★ **출력이 둘인 예외**(계약 §3.2 의 ㉢) — 한 스레드(=한 행)가 `probs` 행과 `loss[r]` 의 **유일한 주인**이고
//     리덕션이 없다. bwd 가 `probs` 를 다시 계산하지 않게 남기는 것이기도 하다(fwd 와 정확히 같은 값을 봐야 한다).
//   ⚠️ 행 최댓값을 먼저 뺀다 — 셰이더와 **같은 순서·같은 안정화**(수학적으로 같아도 부동소수는 다르다).
//     ★ 이 뺄셈은 손실을 정확히 바꾸지 않으므로 **미분에 불연속을 만들지 않는다**(동점에서 argmax 가
//       갈려도 `L` 은 같은 값 ⇒ 이 커널의 gradcheck 에 「조건부」가 없는 근거).
//   ⚠️ 음수를 **`float` 단계에서** 걸러낸다 — 음수 float 의 `(uint32)` 캐스트는 정의가 갈려 GPU 와 CPU 가
//     **다른 값**을 볼 수 있다(그러면 판정이 못 믿을 것이 된다). 셰이더도 같은 순서로 검사한다.
//   ⚠️ `log(0)` 을 막는다 — `p` 가 float 아래로 깎이면 `-inf` 가 되어 곡선이 통째로 못 읽힌다.
//   ⚠️ `ignoreIdx` 에 기본값을 두지 않았다 — 0 이 멀쩡한 id 라 잘못 고르면 **조용히 행이 사라진다**.
//     끄려면 호출부가 `0xFFFFFFFFu` 를 명시한다.
CW_EXPORT void MLCeLogitsCpu(const float* logits, const float* target, float* probs, float* loss,
	uint32 rows, uint32 cols, uint32 ignoreIdx)
{
	if (logits == nullptr || target == nullptr || probs == nullptr || loss == nullptr) return;
	for (uint32 r = 0; r < rows; ++r)
	{
		const uint32 base = r * cols;
		float mx = logits[base];
		for (uint32 v = 1; v < cols; ++v)
		{ const float z = logits[base + v]; if (z > mx) mx = z; }
		float sum = 0.0f;
		for (uint32 v = 0; v < cols; ++v)
		{ const float e = Exp(logits[base + v] - mx); probs[base + v] = e; sum += e; }
		const float inv = 1.0f / sum;
		for (uint32 v = 0; v < cols; ++v) probs[base + v] *= inv;

		// ⚠️ 무효 행은 **손실 0**(0 행으로 접지 않는다) — `probs` 는 그대로 유효한 softmax 다.
		const float tf = target[r];
		const uint32 t = (uint32)tf;
		if (tf < 0.0f || t >= cols || t == ignoreIdx) { loss[r] = 0.0f; continue; }
		float p = probs[base + t];
		if (p < 1.0e-30f) p = 1.0e-30f;
		loss[r] = -Log(p);
	}
}

// 🎯◀ **CPU 레퍼런스 — CE+softmax 의 기울기.** `dLogits[r][v] = ( probs[r][v] − [v == target[r]] ) · lossScale`
//   ★ **야코비안이 통째로 사라진다** — softmax 뒤에 바로 CE 가 오면 `∂L/∂z = p − onehot` 으로 접힌다.
//     ⇒ `MLSoftmaxBwdCpu`(야코비안을 실제로 쓰는 판)와 **다른 물건**이고, 뒤에서 오는 `dOut` 을 받지 않는다.
//     ⚠️ 그러므로 이 둘을 **직렬로 걸지 마라** — 사라져야 할 항을 두 번 곱한다.
//   ★ **`sub(probs, onehot)` 으로 안 되는 이유** = one-hot 텐서를 실체화해야 하고(거의 전부 0 인 `R×V`),
//     무엇보다 `sub` 는 **행을 뺄 줄 모른다**. 여기서는 `v == t` 비교 한 번이 그 텐서를 대신한다.
//   ⚠️⚠️ 무효 행에는 0 을 **쓴다** — 건너뛰면 아레나에 **지난 스텝의 기울기**가 남아 옵티마이저가 그것을
//     먹는다(크래시 없이 조용히 틀린다). 규약은 fwd 와 **글자 그대로 같다**(음수 검사까지).
//   ★ 출력 칸마다 주인이 하나뿐이므로 **쓴다**(`=`) — atomic·0 초기화 디스패치가 필요 없다.
CW_EXPORT void MLCeLogitsBwdCpu(const float* probs, const float* target, float* dLogits,
	uint32 rows, uint32 cols, uint32 ignoreIdx, float lossScale = 1.0f)
{
	if (probs == nullptr || target == nullptr || dLogits == nullptr) return;
	for (uint32 r = 0; r < rows; ++r)
	{
		const uint32 base = r * cols;
		const float tf = target[r];
		const uint32 t = (uint32)tf;
		const bool bad = (tf < 0.0f || t >= cols || t == ignoreIdx);
		for (uint32 v = 0; v < cols; ++v)
		{
			if (bad) { dLogits[base + v] = 0.0f; continue; }   // ⚠️ **쓴다**(건너뛰면 지난 값이 남는다)
			const float oneHot = (v == t) ? 1.0f : 0.0f;
			dLogits[base + v] = (probs[base + v] - oneHot) * lossScale;
		}
	}
}

// ==============================================================================
// 📐 다주파 사인 값 인코딩 Φ(v) — 정규화 계수는 **러닝 통계**(비미분)
// ==============================================================================

// `val_enc.cs.hlsl` 의 `ValEncParams`.
//   ★ **주파수 집합과 정규화 계수가 인자다**(MLT.md 「커널 — 새로 만들 것은 적다」의 `val_enc` 행) —
//     상수로 박으면 분해능(= 주파수 수 `F`)이 **손잡이가 아니게** 되고, 러닝 통계인 `vBias`/`vScale` 을
//     갱신할 길이 없어진다.
//   ⚠️⚠️ **마지막 넷이 `float` 다**(함정 33) — 셰이더의 그 자리·그 타입과 같아야 한다.
//   ⚠️ `vBias`/`vScale` 은 **미분 경로가 아니다**(러닝 통계) → bwd 는 `dV` 만 낸다.
struct MLValEncParams
{
	uint32 inOff = 0, outOff = 0, rows = 0, freqs = 0;
	float  vBias = 0.0f, vScale = 1.0f, freqMin = 1.0f, freqMax = 1000.0f;

	uint32 OutCols() const { return freqs * 2u; }   // ★ 행 길이 = `2F`(sin, cos 쌍)
};

// `val_enc_bwd.cs.hlsl` 의 `ValEncBwdParams`.
//   ⚠️ `pad0` 은 **지우지 않는다** — 남는 칸은 명시로 남긴다(새 필드는 꼬리에만 붙인다).
//   ⚠️⚠️ 계수·주파수는 fwd 와 **같은 값**을 넣는다. 다르면 위상이 갈리고 증상이 크래시가 아니라
//     *"값 채널이 잘 안 배운다"* 다.
struct MLValEncBwdParams
{
	uint32 inOff = 0, dOutOff = 0, dInOff = 0, pad0 = 0;
	uint32 rows = 0, freqs = 0;
	float  vBias = 0.0f, vScale = 1.0f, freqMin = 1.0f, freqMax = 1000.0f;
};

// 🎚️ **CPU 레퍼런스 — 다주파 사인 인코딩 `Φ(v)`.** `Φ[r][2f] = sin(ω_f·u)` · `Φ[r][2f+1] = cos(ω_f·u)`,
//   `u = (v − vBias)·vScale`, `ω_f = freqMin·(freqMax/freqMin)^(f/(F−1))`.
//   ★ **`Pow` 가 아니라 `Exp2(Log2(ratio)·t)` 로 짓는다** — GPU 의 `pow` 는 `exp2(y·log2(x))` 로
//     풀리는데 `powf` 는 더 정밀하게 계산한다 ⇒ **같은 식이 아니게 되어** `ω_f` 가 갈린다.
//     `PEMath.h` 가 `Log2`/`Exp2` 짝을 먼저 둔 이유가 정확히 이것이다(*"셰이더와 같은 식을 쓰려면
//     CPU 도 그것으로 계산해야 값이 정확히 맞는다"*).
//   ⚠️ `freqs == 1` 이면 `t` 의 분모가 0 이다 ⇒ 그때는 `ω = freqMin`(셰이더와 **같은 규약**).
//   ⚠️ 부르는 쪽이 `freqMin > 0` 을 보장한다 — 0 이면 `Log2(inf)` 가 조용히 번진다(셰이더에는 로그가 없다).
//   ⚠️ 출력 둘의 예외다 — 한 스레드(= 한 `(f, r)`)가 `sin`/`cos` 두 칸의 **유일한 주인**이라 리덕션이 없다.
//     갈라 두면 위상 `ω·u` 를 두 번 계산하게 되고 그 두 값이 **정확히 같다는 보장이 없다**.
CW_EXPORT void MLValEncCpu(const float* in, float* out, uint32 rows, uint32 freqs,
	float vBias = 0.0f, float vScale = 1.0f, float freqMin = 1.0f, float freqMax = 1000.0f)
{
	if (in == nullptr || out == nullptr) return;
	const float lg = (freqs > 1u) ? Log2(freqMax / freqMin) : 0.0f;
	for (uint32 r = 0; r < rows; ++r)
	{
		const float u = (in[r] - vBias) * vScale;
		const uint32 base = r * (freqs * 2u);
		for (uint32 f = 0; f < freqs; ++f)
		{
			float w = freqMin;
			if (freqs > 1u) w = freqMin * Exp2(lg * ((float)f / (float)(freqs - 1u)));
			const float ph = w * u;
			out[base + f * 2u]      = Sin(ph);
			out[base + f * 2u + 1u] = Cos(ph);
		}
	}
}

// 🎚️◀ **CPU 레퍼런스 — 펼친 것을 스칼라로 되돌린다.**
//   `dV[r] = vScale · Σ_f ω_f·( dΦ[2f]·cos(ω_f u) − dΦ[2f+1]·sin(ω_f u) )`  (`f` 오름차순)
//   ★ **`dvBias`/`dvScale` 을 내지 않는다** — 그 둘은 학습 파라미터가 아니라 **러닝 통계**(EMA)다.
//     ⚠️⚠️ 그래서 gradcheck 는 **「계수 고정 조건부」**로 잰다(±ε 로 `v` 를 흔들 때 계수를 다시 계산하지
//     않는다). 안 적으면 다음 사람이 *"gradcheck 를 못 통과한다"* 로 오진한다.
//     ★ 반대로 `vScale` 은 **사슬규칙의 인자로는 반드시 들어간다**(`∂u/∂v = vScale`) — 빼먹으면 기울기가
//     `vScale` 배 틀리고 증상이 *"학습이 느리다"* 라서 버그로 안 읽힌다.
//   ★ **기본값을 주지 않는다**(fwd 와 다른 점) — 계수·주파수가 fwd 와 갈리는 것이 이 커널의 조용한
//     실패 1번이라, 부르는 쪽이 **넷을 반드시 적게** 만든다.
//   ⚠️ 누산 순서는 `f` 오름차순 · `vScale` 은 합 **밖에서** 한 번 곱한다 — 셰이더와 글자 그대로 같다.
//   ⚠️ `W_val` 은 여기 없다 — `Φ` 뒤의 `gemm` 이다(그 기울기는 `gemm(transA=1)`).
CW_EXPORT void MLValEncBwdCpu(const float* in, const float* dOut, float* dIn,
	uint32 rows, uint32 freqs, float vBias, float vScale, float freqMin, float freqMax)
{
	if (in == nullptr || dOut == nullptr || dIn == nullptr) return;
	const float lg = (freqs > 1u) ? Log2(freqMax / freqMin) : 0.0f;
	for (uint32 r = 0; r < rows; ++r)
	{
		const float u = (in[r] - vBias) * vScale;
		const uint32 base = r * (freqs * 2u);
		float acc = 0.0f;
		for (uint32 f = 0; f < freqs; ++f)
		{
			float w = freqMin;
			if (freqs > 1u) w = freqMin * Exp2(lg * ((float)f / (float)(freqs - 1u)));
			const float ph = w * u;
			// ∂sin(ω u)/∂u = ω·cos · ∂cos(ω u)/∂u = −ω·sin
			acc += w * (dOut[base + f * 2u] * Cos(ph) - dOut[base + f * 2u + 1u] * Sin(ph));
		}
		dIn[r] = vScale * acc;   // ★ 쓴다(더하지 않는다)
	}
}

// ==============================================================================
// 👁️ 활성 top-k — 선택은 이산(straight-through)
// ==============================================================================

// `act_topk.cs.hlsl` 의 `ActTopkParams`.
//   ⚠️⚠️ float 필드가 없다 — uint 여덟 칸이고 남는 자리는 `pad0`/`pad1` 로 **명시**한다(지우지 마라).
//   ★ `ids`/`mag` 는 둘 다 `rows × k` 이고 `ids` 는 **float 에 담긴 정수**다(0..511 은 float32 에 정확하다).
struct MLActTopkParams
{
	uint32 scoreOff = 0, idsOff = 0, magOff = 0, pad0 = 0;
	uint32 rows = 0, dict = 0, k = 0, pad1 = 0;

	uint32 SlotCount() const { return rows * k; }      // ids/mag 원소 수
	uint32 ScoreCount() const { return rows * dict; }  // z 원소 수
};

// `act_topk_bwd.cs.hlsl` 의 `ActTopkBwdParams`.
//   ⚠️ fwd 와 **바이트 배치가 같다**(오프셋 셋 + pad + 크기 셋 + pad) — 이름만 방향에 맞게 다르다.
//     `MLEmbedParams` 처럼 하나로 합칠 수도 있지만, 계약(§8.8)이 두 이름을 못 박았으므로 둘로 둔다.
struct MLActTopkBwdParams
{
	uint32 idsOff = 0, dMagOff = 0, dScoreOff = 0, pad0 = 0;
	uint32 rows = 0, dict = 0, k = 0, pad1 = 0;

	uint32 SlotCount() const { return rows * k; }
	uint32 ScoreCount() const { return rows * dict; }
};

// ⭐ **CPU 레퍼런스 — 활성 top-k 선택.** 행마다 상위 `k` 개를 골라 `(ids, mag)` 를 낸다.
//   ★ **출력이 둘인 예외** — 한 행의 `ids`/`mag` 두 칸의 **유일한 주인**이 이 반복이다(리덕션이 없다).
//   ★ **k 번의 argmax + 제외** — 셰이더와 **글자 그대로 같은 순서**(`n` 오름차순)라 동점이 어긋나지 않는다.
//   ⚠️⚠️ **동점은 낮은 색인이 이긴다** — 비교가 `>` 다(`>=` 가 아니다). 초기 파라미터에서는 동점이 실제로
//     나오므로(사전이 아직 안 갈렸다) 이 규칙이 셰이더와 갈리면 `ids` 가 어긋나 **그 뒤 판정 전부가
//     거짓말**이 된다(그런데 `mag` 은 멀쩡해 보인다).
//   ⚠️⚠️ `best == dict` 검사를 빼지 마라 — `bestVal` 초기값이 `0.0f` 라서, 그 검사가 없으면
//     **점수가 전부 음수인 행**에서 아무것도 안 골라진다(실측으로 검산한 함정).
//   ⚠️ `mag` 은 점수를 **그대로** 쓴다(활성 함수를 섞지 않는다 — 필요하면 `relu` 를 따로 건다).
//   ⚠️ `k > dict` 로 남는 슬롯은 `ids = dict`(**범위 밖**) · `mag = 0` 이다 — bwd 는 `n < dict` 만 보므로
//     그 슬롯의 기울기는 저절로 0 이 된다(fwd/bwd **같은 규약**).
CW_EXPORT void MLActTopkCpu(const float* score, float* ids, float* mag,
	uint32 rows, uint32 dict, uint32 k)
{
	if (score == nullptr || ids == nullptr || mag == nullptr) return;
	for (uint32 r = 0; r < rows; ++r)
	{
		const uint32 zBase = r * dict, oBase = r * k;
		for (uint32 j = 0; j < k; ++j)
		{
			uint32 best = dict;          // ★ 센티널 = "없다"(범위 밖)
			float  bestVal = 0.0f;
			for (uint32 n = 0; n < dict; ++n)
			{
				// ★ 「제외」는 방금 자기가 쓴 `ids` 를 되읽어 판정한다(마스크 버퍼를 두지 않는다).
				bool taken = false;
				for (uint32 q = 0; q < j; ++q)
					if ((uint32)ids[oBase + q] == n) taken = true;
				if (taken) continue;

				const float z = score[zBase + n];
				if (best == dict || z > bestVal) { best = n; bestVal = z; }
			}
			ids[oBase + j] = (float)best;
			mag[oBase + j] = (best < dict) ? bestVal : 0.0f;
		}
	}
}

// ⭐ **CPU 레퍼런스 — 선택은 `|z|` · 세기는 `z`.** `act_topk_abs.cs.hlsl` 의 짝.
//   ⚠️ `MLActTopkCpu` 와 **다른 곳은 비교 한 줄뿐**이다(`z > bestVal` → `|z| > |bestVal|`).
//     ⇒ 동점 규약(낮은 색인이 이긴다) · 센티널(`best == dict`) · `taken` 되읽기는 **같아야 한다**.
//   ★ **기울기 커널은 새로 없다** — `mag[r][j] = z[r][ids[r][j]]` 라는 관계가 글자 그대로 같으므로
//     `MLActTopkBwdCpu`(그리고 `act_topk_bwd`)를 **그대로** 쓴다.
CW_EXPORT void MLActTopkAbsCpu(const float* score, float* ids, float* mag,
	uint32 rows, uint32 dict, uint32 k)
{
	if (score == nullptr || ids == nullptr || mag == nullptr) return;
	for (uint32 r = 0; r < rows; ++r)
	{
		const uint32 zBase = r * dict, oBase = r * k;
		for (uint32 j = 0; j < k; ++j)
		{
			uint32 best = dict;          // ★ 센티널 = "없다"(범위 밖)
			float  bestVal = 0.0f;       // ★ **부호 있는** 값(비교만 절댓값으로)
			for (uint32 n = 0; n < dict; ++n)
			{
				bool taken = false;
				for (uint32 q = 0; q < j; ++q)
					if ((uint32)ids[oBase + q] == n) taken = true;
				if (taken) continue;

				const float z = score[zBase + n];
				if (best == dict || Abs(z) > Abs(bestVal)) { best = n; bestVal = z; }
			}
			ids[oBase + j] = (float)best;
			mag[oBase + j] = (best < dict) ? bestVal : 0.0f;
		}
	}
}

// ⭐◀ **CPU 레퍼런스 — 활성 선택의 기울기.** `dScore[r][n] = Σ_j ( ids[r][j] == n ? dMag[r][j] : 0 )`
//   ★ **선택은 상수다(straight-through)** — `mag[r][j] = z[r][ids[r][j]]` 의 미분이 정확히 1 이라
//     고른 자리로만 `dMag` 가 그대로 들어가고 **나머지 사전 자리는 정확히 0** 이다.
//     ⚠️ 그래서 gradcheck 는 **「선택 고정 조건부」**로만 성립한다(±ε 로 흔들 때 `ids` 를 다시 고르지 않는다).
//   ★ 셰이더와 **같은 방향(gather)**·**같은 순서**(`j` 오름차순)이고 **쓴다**(더하지 않는다) —
//     atomic 도 0 초기화도 필요 없다. ⚠️ 순서를 다르게 두면 float 합이 갈려 비교가 무의미해진다.
//   ⚠️ `ids` 의 기울기는 없다(정수 색인 · 학습 대상 아님). 범위 밖 `ids` 는 `n < dict` 와 절대 같지
//     않으므로 저절로 건너뛴다(fwd 와 같은 규약).
CW_EXPORT void MLActTopkBwdCpu(const float* ids, const float* dMag, float* dScore,
	uint32 rows, uint32 dict, uint32 k)
{
	if (ids == nullptr || dMag == nullptr || dScore == nullptr) return;
	for (uint32 r = 0; r < rows; ++r)
	{
		const uint32 oBase = r * k;
		for (uint32 n = 0; n < dict; ++n)
		{
			float acc = 0.0f;
			for (uint32 j = 0; j < k; ++j)
				if ((uint32)ids[oBase + j] == n) acc += dMag[oBase + j];
			dScore[r * dict + n] = acc;   // ★ 쓴다(더하지 않는다)
		}
	}
}

// ── 선택 id 고정 · 별도 계수 gather ────────────────────────────────────
// ⚠️ float 필드 `scale` 은 맨 뒤다. 앞의 uint 열한 칸과 셀이더 배치를 글자 그대로 맞춘다.
struct MLActGatherParams
{
	uint32 aOff = 0, bOff = 0, idsOff = 0, magOff = 0;
	uint32 rows = 0, dict = 0, k = 0, useB = 0;
	uint32 pad0 = 0, pad1 = 0, pad2 = 0;
	float scale = 1.0f;
};

struct MLActGatherBwdParams
{
	uint32 idsOff = 0, dMagOff = 0, dInOff = 0, add = 0;
	uint32 rows = 0, dict = 0, k = 0, pad0 = 0;
	uint32 pad1 = 0, pad2 = 0, pad3 = 0;
	float scale = 1.0f;
};

// 🧲 **CPU 레퍼런스 — 고른 id 에서 별도 계수를 읽는다.**
//   `useB=0`: `mag = scale·a[id]` · `useB=1`: `mag = scale·(a[id]+b[id])`.
//   ⚠️ ids 는 입력이다 — 선택을 다시 하지 않는다. 범위 밖 센티널은 0.
CW_EXPORT void MLActGatherCpu(const float* a, const float* b, const float* ids, float* mag,
	uint32 rows, uint32 dict, uint32 k, bool useB, float scale)
{
	if (a == nullptr || ids == nullptr || mag == nullptr || (useB && b == nullptr)) return;
	for (uint32 r = 0; r < rows; ++r)
		for (uint32 j = 0; j < k; ++j)
		{
			const uint32 sl = r * k + j, n = (uint32)ids[sl];
			float v = 0.0f;
			if (n < dict) { v = a[r * dict + n]; if (useB) v += b[r * dict + n]; }
			mag[sl] = v * scale;
		}
}

// 🧲◀ **CPU 레퍼런스 — gather 의 입력 기울기.**
//   `(r,n)` 칸이 슬롯을 오름차순으로 모아 결정적으로 쓴다. `add` 면 기존 값에 누산.
CW_EXPORT void MLActGatherBwdCpu(const float* ids, const float* dMag, float* dIn,
	uint32 rows, uint32 dict, uint32 k, float scale, bool add)
{
	if (ids == nullptr || dMag == nullptr || dIn == nullptr) return;
	for (uint32 r = 0; r < rows; ++r)
		for (uint32 n = 0; n < dict; ++n)
		{
			float acc = 0.0f;
			for (uint32 j = 0; j < k; ++j)
				if ((uint32)ids[r * k + j] == n) acc += dMag[r * k + j];
			const uint32 at = r * dict + n;
			const float v = acc * scale;
			dIn[at] = add ? (dIn[at] + v) : v;
		}
}

// ── 🔁 잔차를 본 원자 교체 한 번 ───────────────────────────────────
// `act_residual_swap.cs.hlsl` 과 64바이트 배치를 글자 그대로 맞춘다.
// 첫 12칸은 uint, 마지막 네 칸은 float eps + pad 셋이다.
struct MLActResidualSwapParams
{
	uint32 targetOff = 0, reconOff = 0, scoreOff = 0, tableOff = 0;
	uint32 idsInOff = 0, magInOff = 0, idsOutOff = 0, magOutOff = 0;
	uint32 rows = 0, k = 0, pixels = 0, dict = 0;
	float eps = 1.0e-6f;
	uint32 pad0 = 0, pad1 = 0, pad2 = 0;
};

// 🔁 **CPU 레퍼런스 — 현재 활성에서 잔차를 보고 원자 하나만 바꾼다.**
//   ① 바깥 원자마다 현재 모델 계수 `score[n]` 로 더했을 때의 SSE 감소량을 잰다.
//   ② 가장 큰 후보 하나만 잡고, 기존 k칸 중 어느 칸과 바꿀지 실제 SSE 로 고른다.
//   ③ 아무 교체도 원래 재구성보다 낫지 않으면 no-op 한다.
// 최종 `mag = score[ids]` 관계는 그대로라, 선택 고정 조건부 역전파는 기존 `act_topk_bwd`가 정확하다.
CW_EXPORT void MLActResidualSwapCpu(const float* target, const float* recon, const float* score,
	const float* table, const float* idsIn, const float* magIn, float* idsOut, float* magOut,
	uint32 rows, uint32 k, uint32 pixels, uint32 dict, float eps = 1.0e-6f)
{
	if (target == nullptr || recon == nullptr || score == nullptr || table == nullptr ||
		idsIn == nullptr || magIn == nullptr || idsOut == nullptr || magOut == nullptr) return;
	for (uint32 r = 0; r < rows; ++r)
	{
		const uint32 kb = r * k, pb = r * pixels, sb = r * dict;
		for (uint32 j = 0; j < k; ++j) { idsOut[kb + j] = idsIn[kb + j]; magOut[kb + j] = magIn[kb + j]; }

		float sq0 = 0.0f;
		for (uint32 px = 0; px < pixels; ++px)
		{
			const float q = target[pb + px] - recon[pb + px];
			sq0 += q * q;
		}

		uint32 best = dict; float bestGain = 0.0f;
		for (uint32 n = 0; n < dict; ++n)
		{
			bool taken = false;
			for (uint32 j = 0; j < k; ++j) if ((uint32)idsIn[kb + j] == n) { taken = true; break; }
			if (taken) continue;
			const float m = score[sb + n];
			float dot = 0.0f, nrm = 0.0f;
			for (uint32 px = 0; px < pixels; ++px)
			{
				const float d = table[n * pixels + px];
				dot += (target[pb + px] - recon[pb + px]) * d;
				nrm += d * d;
			}
			const float gain = 2.0f * m * dot - m * m * (nrm + eps);
			if (best == dict || gain > bestGain) { best = n; bestGain = gain; }
		}

		uint32 bestDrop = k; float bestSq = sq0;
		if (best < dict)
		{
			const float nm = score[sb + best];
			const float* nd = table + best * pixels;
			for (uint32 j = 0; j < k; ++j)
			{
				const uint32 old = (uint32)idsIn[kb + j];
				if (old >= dict) continue;
				const float om = magIn[kb + j];
				const float* od = table + old * pixels;
				float sq = 0.0f;
				for (uint32 px = 0; px < pixels; ++px)
				{
					const float q = target[pb + px] - recon[pb + px] + om * od[px] - nm * nd[px];
					sq += q * q;
				}
				if (sq < bestSq) { bestSq = sq; bestDrop = j; }
			}
		}
		if (bestDrop < k) { idsOut[kb + bestDrop] = (float)best; magOut[kb + bestDrop] = score[sb + best]; }
	}
}

// ── 🔧 고정 ids의 계수 좌표 갱신 한 바퀴 ───────────────────────────
// `act_coeff_sweep.cs.hlsl` 과 64바이트 배치를 글자 그대로 맞춘다.
struct MLActCoeffSweepParams
{
	uint32 targetOff = 0, reconOff = 0, tableOff = 0, idsOff = 0;
	uint32 magInOff = 0, magOutOff = 0, rows = 0, k = 0;
	uint32 pixels = 0, dict = 0;
	float eps = 1.0e-6f;
	uint32 pad0 = 0, pad1 = 0, pad2 = 0, pad3 = 0, pad4 = 0;
};

// 🔧 CPU 정본. 입력 recon에서 시작해 k개 원자를 순서대로 정확히 한 번씩 보정한다.
// `pixels <= 256`은 셰이더의 groupshared 잔차 상한과 같은 계약이다.
CW_EXPORT void MLActCoeffSweepCpu(const float* target, const float* recon, const float* table,
	const float* ids, const float* magIn, float* magOut, uint32 rows, uint32 k,
	uint32 pixels, uint32 dict, float eps = 1.0e-6f)
{
	if (target == nullptr || recon == nullptr || table == nullptr || ids == nullptr ||
		magIn == nullptr || magOut == nullptr || pixels > 256u) return;
	float res[256];
	for (uint32 row = 0; row < rows; ++row)
	{
		const uint32 kb = row * k, pb = row * pixels;
		for (uint32 px = 0; px < pixels; ++px) res[px] = target[pb + px] - recon[pb + px];
		for (uint32 j = 0; j < k; ++j) magOut[kb + j] = magIn[kb + j];
		for (uint32 j = 0; j < k; ++j)
		{
			const uint32 id = (uint32)ids[kb + j];
			if (id >= dict) continue;
			const float* u = table + id * pixels;
			float dot = 0.0f, norm = eps;
			for (uint32 px = 0; px < pixels; ++px) { dot += u[px] * res[px]; norm += u[px] * u[px]; }
			const float delta = dot / norm;
			magOut[kb + j] += delta;
			for (uint32 px = 0; px < pixels; ++px) res[px] -= delta * u[px];
		}
	}
}

// ==============================================================================
// 🧩 활성 → 프레임 되만들기 — 붕괴 감시가 이 오차를 쓴다
// ==============================================================================

// ─────────────────────────────────────────────────────────────────────────────
// 🖼️ vis_recon — 활성 k개 (id, 세기) → 프레임 되만들기. 호스트 struct 셋 + CPU 레퍼런스 셋.
//   ⚠️ 셰이더(`vis_recon.cs.hlsl` · `vis_recon_bwd_mag.cs.hlsl` · `vis_recon_bwd_tab.cs.hlsl`)의
//     `VisRecon*Params` 와 **필드 이름·순서·타입이 글자 그대로 같다**. float 필드는 **없다**(전부 uint32).
// ─────────────────────────────────────────────────────────────────────────────

// `vis_recon.cs.hlsl` 의 `VisReconParams`.
//   ★ `table` = 디코더 코드북(`dict × pixels`) — **배우는 값**이다.
//   ⚠️ 표적은 `frameNorm`(= frame/255)이고 원본 바이트 텐서 `frame`(`patch_embed` 가 읽는 것)과 **갈라 둔다**.
//     손실 기울기는 기존 `sub(recon, frameNorm)` 이 낸다(손실 스칼라는 회수해서 CPU 가 적는다).
struct MLVisReconParams
{
	uint32 idsOff = 0, magOff = 0, tableOff = 0, outOff = 0;
	uint32 rows = 0, k = 0, pixels = 0, dict = 0;

	uint32 ActCount() const { return rows * k; }        // ids/mag 의 원소 수
	uint32 ReconCount() const { return rows * pixels; } // recon/dRecon 의 원소 수
	uint32 TableCount() const { return dict * pixels; } // 코드북/그 기울기의 원소 수
};

// `vis_recon_bwd_mag.cs.hlsl` 의 `VisReconMagBwdParams`. (출력 `dMag` = `rows × k`)
//   ★ 이 기울기가 `act_topk_bwd` 의 입력이다 — **재구성이 인코더까지 흐르는 유일한 길**.
struct MLVisReconMagBwdParams
{
	uint32 idsOff = 0, tableOff = 0, dOutOff = 0, dMagOff = 0;
	uint32 rows = 0, k = 0, pixels = 0, dict = 0;
};

// `vis_recon_bwd_tab.cs.hlsl` 의 `VisReconTabBwdParams`. (출력 `dDtab` = `dict × pixels`)
//   ⚠️ gather 다 — 스레드가 `(코드 v, 픽셀 px)` 를 맡고 자기를 고른 행을 훑어 더한 뒤 **쓴다**.
struct MLVisReconTabBwdParams
{
	uint32 idsOff = 0, magOff = 0, dOutOff = 0, dTableOff = 0;
	uint32 rows = 0, k = 0, pixels = 0, dict = 0;
};

// 🖼️ **CPU 레퍼런스 — 활성으로 프레임 되만들기.** `recon[r][px] = Σ_j mag[r][j] · table[ids[r][j]][px]`
//   ⚠️ 누산 순서는 셰이더와 같은 **`j` 오름차순**이고 곱의 순서도 같다(`mag * table`).
//   ⚠️ `ids` 가 `dict` 범위를 벗어나면 **그 항을 건너뛴다**(0 행으로 접지 **않는다**) — bwd 둘과 같은 규약.
CW_EXPORT void MLVisReconCpu(const float* ids, const float* mag, const float* table, float* out,
	uint32 rows, uint32 k, uint32 pixels, uint32 dict)
{
	if (ids == nullptr || mag == nullptr || table == nullptr || out == nullptr) return;
	for (uint32 r = 0; r < rows; ++r)
	{
		const uint32 kb = r * k;
		for (uint32 px = 0; px < pixels; ++px)
		{
			float acc = 0.0f;
			for (uint32 j = 0; j < k; ++j)
			{
				const uint32 v = (uint32)ids[kb + j];
				if (v >= dict) continue;              // 셰이더와 **같은 규약**
				acc += mag[kb + j] * table[v * pixels + px];
			}
			out[r * pixels + px] = acc;               // ★ 쓴다(더하지 않는다)
		}
	}
}

// 🖼️◀ **CPU 레퍼런스 — 세기의 기울기.** `dMag[r][j] = Σ_px dOut[r][px] · table[ids[r][j]][px]`
//   ⚠️ `px` 오름차순 · 곱의 순서도 셰이더와 같다(`dOut * table`).
//   ⚠️ 범위 밖 id 는 fwd 의 합에 없었으므로 **0 을 쓴다**(건너뛰고 끝내면 옛 값이 남는다).
//   ★ `ids` 는 상수다(`act_topk` 의 straight-through) — 선택의 기울기는 없다.
CW_EXPORT void MLVisReconMagBwdCpu(const float* ids, const float* table, const float* dOut, float* dMag,
	uint32 rows, uint32 k, uint32 pixels, uint32 dict)
{
	if (ids == nullptr || table == nullptr || dOut == nullptr || dMag == nullptr) return;
	for (uint32 r = 0; r < rows; ++r)
	{
		const uint32 kb = r * k, db = r * pixels;
		for (uint32 j = 0; j < k; ++j)
		{
			const uint32 v = (uint32)ids[kb + j];
			float acc = 0.0f;
			if (v < dict)
			{
				const uint32 tb = v * pixels;
				for (uint32 px = 0; px < pixels; ++px) acc += dOut[db + px] * table[tb + px];
			}
			dMag[kb + j] = acc;                       // ★ 쓴다(더하지 않는다)
		}
	}
}

// 🖼️◀ **CPU 레퍼런스 — 디코더 코드북의 기울기.**
//   `dTable[v][px] = Σ_r Σ_j ( ids[r][j] == v ? mag[r][j] · dOut[r][px] : 0 )`
//   ★ 셰이더와 **같은 방향(gather)** 이고 **같은 순서**(`r` → `j` 오름차순) · 곱도 `mag * dOut`.
//   ⚠️ 한 행이 같은 코드를 두 번 골랐으면 fwd 도 두 번 더했으므로 여기도 두 번 더한다.
CW_EXPORT void MLVisReconTabBwdCpu(const float* ids, const float* mag, const float* dOut, float* dTable,
	uint32 rows, uint32 k, uint32 pixels, uint32 dict)
{
	if (ids == nullptr || mag == nullptr || dOut == nullptr || dTable == nullptr) return;
	for (uint32 v = 0; v < dict; ++v)
		for (uint32 px = 0; px < pixels; ++px)
		{
			float acc = 0.0f;
			for (uint32 r = 0; r < rows; ++r)
			{
				const uint32 kb = r * k;
				const float dr = dOut[r * pixels + px];
				for (uint32 j = 0; j < k; ++j)
				{
					if ((uint32)ids[kb + j] != v) continue;
					acc += mag[kb + j] * dr;
				}
			}
			dTable[v * pixels + px] = acc;            // ★ 쓴다(더하지 않는다)
		}
}

// ==============================================================================
// 🌐 이동 가능한 전역 발자국 — candidate=anchor*dict+id, space=Σ X(dx)Y(dy)
// ==============================================================================

struct MLFootReconParams
{
	uint32 idsOff = 0, magOff = 0, codeOff = 0, xOff = 0, yOff = 0, outOff = 0;
	uint32 frames = 0, k = 0, grid = 0, pixels = 0, dict = 0, rank = 0, span = 0;
};

struct MLFootReconMagBwdParams
{
	uint32 idsOff = 0, codeOff = 0, xOff = 0, yOff = 0, dOutOff = 0, dMagOff = 0;
	uint32 frames = 0, k = 0, grid = 0, pixels = 0, dict = 0, rank = 0, span = 0;
};

struct MLFootReconCodeBwdParams
{
	uint32 idsOff = 0, magOff = 0, xOff = 0, yOff = 0, dOutOff = 0, dCodeOff = 0;
	uint32 frames = 0, k = 0, grid = 0, pixels = 0, dict = 0, rank = 0, span = 0;
};

struct MLFootReconSpaceBwdParams
{
	uint32 idsOff = 0, magOff = 0, codeOff = 0, xOff = 0, yOff = 0, dOutOff = 0, dXOff = 0, dYOff = 0;
	uint32 frames = 0, k = 0, grid = 0, pixels = 0, dict = 0, rank = 0, span = 0;
};

static float _MLFootSpace(const float* x, const float* y, uint32 v, uint32 dx, uint32 dy,
	uint32 rank, uint32 span)
{
	float s = 0.0f;
	for (uint32 r = 0; r < rank; ++r)
	{
		const uint32 b = (v * rank + r) * span;
		s += x[b + dx] * y[b + dy];
	}
	return s;
}

CW_EXPORT void MLFootReconCpu(const float* ids, const float* mag, const float* code,
	const float* x, const float* y, float* out, uint32 frames, uint32 k, uint32 grid,
	uint32 pixels, uint32 dict, uint32 rank, uint32 span)
{
	if (ids == nullptr || mag == nullptr || code == nullptr || x == nullptr || y == nullptr || out == nullptr) return;
	const uint32 patches = grid * grid;
	for (uint32 f = 0; f < frames; ++f)
		for (uint32 p = 0; p < patches; ++p)
		{
			const uint32 px = p % grid, py = p / grid;
			for (uint32 d = 0; d < pixels; ++d)
			{
				float z = 0.0f;
				for (uint32 j = 0; j < k; ++j)
				{
					const uint32 cand = (uint32)ids[f * k + j];
					if (cand >= patches * dict) continue;
					const uint32 a = cand / dict, v = cand % dict;
					const uint32 dx = px + grid - 1u - a % grid, dy = py + grid - 1u - a / grid;
					z += mag[f * k + j] * _MLFootSpace(x, y, v, dx, dy, rank, span) * code[v * pixels + d];
				}
				out[(f * patches + p) * pixels + d] = z;
			}
		}
}

CW_EXPORT void MLFootReconMagBwdCpu(const float* ids, const float* code, const float* x, const float* y,
	const float* dOut, float* dMag, uint32 frames, uint32 k, uint32 grid, uint32 pixels,
	uint32 dict, uint32 rank, uint32 span)
{
	if (ids == nullptr || code == nullptr || x == nullptr || y == nullptr || dOut == nullptr || dMag == nullptr) return;
	const uint32 patches = grid * grid;
	for (uint32 f = 0; f < frames; ++f)
		for (uint32 j = 0; j < k; ++j)
		{
			const uint32 cand = (uint32)ids[f * k + j]; float g = 0.0f;
			if (cand < patches * dict)
			{
				const uint32 a = cand / dict, v = cand % dict;
				for (uint32 p = 0; p < patches; ++p)
				{
					const uint32 dx = p % grid + grid - 1u - a % grid;
					const uint32 dy = p / grid + grid - 1u - a / grid;
					const float s = _MLFootSpace(x, y, v, dx, dy, rank, span);
					for (uint32 d = 0; d < pixels; ++d)
						g += dOut[(f * patches + p) * pixels + d] * s * code[v * pixels + d];
				}
			}
			dMag[f * k + j] = g;
		}
}

CW_EXPORT void MLFootReconCodeBwdCpu(const float* ids, const float* mag, const float* x, const float* y,
	const float* dOut, float* dCode, uint32 frames, uint32 k, uint32 grid, uint32 pixels,
	uint32 dict, uint32 rank, uint32 span)
{
	if (ids == nullptr || mag == nullptr || x == nullptr || y == nullptr || dOut == nullptr || dCode == nullptr) return;
	const uint32 patches = grid * grid;
	for (uint32 v = 0; v < dict; ++v) for (uint32 d = 0; d < pixels; ++d)
	{
		float g = 0.0f;
		for (uint32 f = 0; f < frames; ++f) for (uint32 j = 0; j < k; ++j)
		{
			const uint32 cand = (uint32)ids[f * k + j];
			if (cand >= patches * dict || cand % dict != v) continue;
			const uint32 a = cand / dict;
			for (uint32 p = 0; p < patches; ++p)
			{
				const uint32 dx = p % grid + grid - 1u - a % grid;
				const uint32 dy = p / grid + grid - 1u - a / grid;
				g += mag[f * k + j] * _MLFootSpace(x, y, v, dx, dy, rank, span)
					* dOut[(f * patches + p) * pixels + d];
			}
		}
		dCode[v * pixels + d] = g;
	}
}

CW_EXPORT void MLFootReconSpaceBwdCpu(const float* ids, const float* mag, const float* code,
	const float* x, const float* y, const float* dOut, float* dX, float* dY,
	uint32 frames, uint32 k, uint32 grid, uint32 pixels, uint32 dict, uint32 rank, uint32 span)
{
	if (ids == nullptr || mag == nullptr || code == nullptr || x == nullptr || y == nullptr ||
		dOut == nullptr || dX == nullptr || dY == nullptr) return;
	const uint32 patches = grid * grid;
	for (uint32 v = 0; v < dict; ++v) for (uint32 r = 0; r < rank; ++r) for (uint32 q = 0; q < span; ++q)
	{
		float gx = 0.0f, gy = 0.0f;
		for (uint32 f = 0; f < frames; ++f) for (uint32 j = 0; j < k; ++j)
		{
			const uint32 cand = (uint32)ids[f * k + j];
			if (cand >= patches * dict || cand % dict != v) continue;
			const uint32 a = cand / dict, ax = a % grid, ay = a / grid;
			const float m = mag[f * k + j];
			const int32 ox = (int32)ax + (int32)q - (int32)(grid - 1u);
			if (ox >= 0 && ox < (int32)grid) for (uint32 py = 0; py < grid; ++py)
			{
				float dot = 0.0f; const uint32 ob = (f * patches + py * grid + (uint32)ox) * pixels;
				for (uint32 d = 0; d < pixels; ++d) dot += dOut[ob + d] * code[v * pixels + d];
				gx += m * y[(v * rank + r) * span + py + grid - 1u - ay] * dot;
			}
			const int32 oy = (int32)ay + (int32)q - (int32)(grid - 1u);
			if (oy >= 0 && oy < (int32)grid) for (uint32 px = 0; px < grid; ++px)
			{
				float dot = 0.0f; const uint32 ob = (f * patches + (uint32)oy * grid + px) * pixels;
				for (uint32 d = 0; d < pixels; ++d) dot += dOut[ob + d] * code[v * pixels + d];
				gy += m * x[(v * rank + r) * span + px + grid - 1u - ax] * dot;
			}
		}
		const uint32 at = (v * rank + r) * span + q; dX[at] = gx; dY[at] = gy;
	}
}
