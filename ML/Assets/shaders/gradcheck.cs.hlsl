// gradcheck.cs.hlsl — 📏 **수치 그래디언트**(중앙차분)로 backward 를 검산한다. `∂L/∂B[j]` 를 j 마다.
//
//   모델: `C = A · B` · 손실 `L = ½·Σ(C − T)²`
//   ⇒ 해석적으로는 `dC = C − T`, `dB = Aᵀ · dC` 다. 이 커널은 그것을 **믿지 않고** 손실을 두 번 재서
//     `(L₊ − L₋) / 2ε` 를 낸다. 두 값이 맞으면 backward 가 맞다.
//
// ★ **스레드 하나가 파라미터 하나를 맡고, 섭동을 아레나에 쓰지 않는다.**
//   ⇒ `B` 를 읽는 자리에서 **그 인덱스가 내 j 일 때만** ±ε 를 더한다. 그래서
//     ㉠ 스레드끼리 간섭이 없다(아무도 남의 데이터를 안 고친다 → 배리어도 순서도 필요 없다)
//     ㉡ **한 디스패치로 전부 끝난다** → 이 엔진의 **프레임 지연을 한 번만** 낸다.
//   ⚠️⚠️ 순차로 하면(파라미터마다 섭동→디스패치→회수) **파라미터 수 × 2 프레임**이 든다. 프레임 지연이
//     구조라서 그 비용은 안 줄어든다 — 그래서 병렬화가 선택이 아니라 **유일한 실용적 방법**이다.
//
// ⚠️⚠️ **일부러 아주 작은 문제로 돈다.** 스레드마다 forward 를 **두 번** 하므로 비용이 `2·M·N·K` 다.
//   이 커널의 목적은 **정확성**이고 처리량이 아니다 — 크게 돌리면 느려지기만 하고 판정은 안 세진다.
//
// ⚠️ `ε` 고르기가 이 검산의 전부다: 너무 작으면 **부동소수 상쇄**로 분자가 0 이 되고, 너무 크면
//   **2차 오차**가 섞인다. float32 에서는 1e-2 ~ 1e-3 이 실전 범위다(호스트가 정한다).

struct GradCheckParams
{
    uint  aOff, bOff, tOff, outOff;   // A · B · T(정답) · 결과(수치 기울기, B 와 같은 모양)
    uint  M, N, K;
    float eps;
};
[[vk::push_constant]] GradCheckParams gP;

RWStructuredBuffer<float> gArena : register(u0);

// `B[j] += delta` 였다면 손실이 얼마인가. ⚠️ **아레나를 고치지 않는다** — 읽는 자리에서 더한다.
float LossWithPerturb(uint j, float delta)
{
    float loss = 0.0;
    for (uint r = 0; r < gP.M; ++r)
    {
        for (uint c = 0; c < gP.N; ++c)
        {
            float acc = 0.0;
            for (uint k = 0; k < gP.K; ++k)
            {
                const uint bi = k * gP.N + c;
                float bv = gArena[gP.bOff + bi];
                if (bi == j) bv += delta;          // ★ 내가 맡은 파라미터만 흔든다
                acc += gArena[gP.aOff + r * gP.K + k] * bv;
            }
            const float d = acc - gArena[gP.tOff + r * gP.N + c];
            loss += 0.5 * d * d;
        }
    }
    return loss;
}

[numthreads(64, 1, 1)]
void main(uint3 tid : SV_DispatchThreadID)
{
    const uint j = tid.x;
    const uint total = gP.K * gP.N;    // B 는 K×N
    if (j >= total) return;            // ⚠️ 범위 검사는 커널의 몫

    const float lp = LossWithPerturb(j,  gP.eps);
    const float lm = LossWithPerturb(j, -gP.eps);
    gArena[gP.outOff + j] = (lp - lm) / (2.0 * gP.eps);
}
