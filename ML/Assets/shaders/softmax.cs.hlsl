// softmax.cs.hlsl — 🔢 **행마다 softmax.** `probs[t][v] = exp(z−max) / Σexp(z−max)`.
//
// ★ **행 최댓값을 먼저 빼는 것이 선택이 아니다** — `exp(z)` 는 `z ≈ 89` 에서 float32 를 넘겨 `inf` 가
//   되고, 그러면 `inf/inf = NaN` 이 되어 **손실이 NaN 으로 죽는다**. 학습 초반 로짓은 작지만 학습이
//   진행되면 커지므로, 이 뺄셈이 없으면 **한참 뒤에** 터진다(원인과 안 닮은 자리에서).
//   ★ 그리고 뺄셈은 결과를 바꾸지 않는다(분자·분모에 같은 상수가 곱해질 뿐이다) — **공짜 안전장치**다.
//
// ★ **스레드 하나가 한 행을 맡는다** — 행을 여러 스레드가 나누면 최댓값/합에 리덕션이 필요하고
//   그 리덕션은 **누산 순서가 비결정적**이 될 수 있다. 어휘가 256 뿐이라 한 스레드로 충분하고,
//   결정적인 것이 이 프로젝트에서는 성능보다 값지다(CPU 레퍼런스와 정확히 견주는 것이 판정이므로).
//   ⚠️ 어휘가 5만이면 다시 생각할 자리다(그때는 그룹 리덕션 + 고정 순서).

// ⚠️⚠️ **마지막이 `float` 다** — 호스트(`MLSoftmaxParams`)와 그 자리·그 타입이 같아야 한다(함정 33).
//   ★ `scale` = **온도**다(`softmax(z · scale)`). 기본은 `1.0` 이고 그때 예전과 글자 그대로 같다.
//     어텐션이 `1/√D` 를 여기로 넘긴다 — 점수를 따로 곱하는 커널을 만들지 않으려는 것이고,
//     **온도가 softmax 의 성질**이라 자리도 여기가 맞다(⚠️ 짝은 `softmax_bwd` 가 같은 값을 받는 것).
struct SoftmaxParams
{
    uint  inOff, outOff, rows, cols;
    float scale;
};
[[vk::push_constant]] SoftmaxParams gP;

RWStructuredBuffer<float> gArena : register(u0);

[numthreads(64, 1, 1)]
void main(uint3 tid : SV_DispatchThreadID)
{
    const uint r = tid.x;
    if (r >= gP.rows) return;

    const uint base = r * gP.cols;

    // ① 행 최댓값 — ⚠️ **온도를 곱한 뒤**에 잰다(곱하기 전에 재면 안정화가 어긋난다).
    float mx = gArena[gP.inOff + base] * gP.scale;
    for (uint v = 1; v < gP.cols; ++v)
    {
        const float z = gArena[gP.inOff + base + v] * gP.scale;
        if (z > mx) mx = z;
    }

    // ② exp 합 — ⚠️ 지수를 **쓰면서** 더한다(두 번 계산하지 않는다).
    float sum = 0.0;
    for (uint v2 = 0; v2 < gP.cols; ++v2)
    {
        const float e = exp(gArena[gP.inOff + base + v2] * gP.scale - mx);
        gArena[gP.outOff + base + v2] = e;
        sum += e;
    }

    // ③ 정규화. ⚠️ `sum` 은 최소 1 이다(자기 항이 `exp(0)=1`) → 0 나눗셈이 원리적으로 없다.
    const float inv = 1.0 / sum;
    for (uint v3 = 0; v3 < gP.cols; ++v3)
        gArena[gP.outOff + base + v3] *= inv;
}
