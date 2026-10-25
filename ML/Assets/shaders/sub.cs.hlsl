// sub.cs.hlsl — ➖ **원소별 `out = a - b`.** MSE 손실의 기울기가 정확히 이것이다.
//
// ★ **`L = ½·Σ(C − T)²` 의 미분이 `dC = C − T` 다.** 그래서 손실 커널이 따로 없다 —
//   학습에 필요한 것은 **손실값이 아니라 기울기**이고, 손실값은 사람이 보는 숫자다(그것은 리덕션 커널의
//   일이고 지금 필요하지 않다).
//   ⚠️ 그래서 이 커널 이름을 `mse_grad` 로 짓지 않았다 — 하는 일은 **뺄셈**이고, "MSE 의 기울기" 는
//     그 쓰임이다. 이름에 쓰임을 박으면 같은 뺄셈이 필요한 다음 자리에서 이름이 거짓말이 된다.
//
// ⚠️ 1D 로 훑는다(`[numthreads(256,1,1)]`) — 원소별 연산은 모양을 몰라도 되므로 **길이만** 안다.
//   ★ 그래서 `M`/`N` 이 인자에 없다: 필요한 것이 `count` 뿐이다.

struct SubParams
{
    uint aOff, bOff, outOff, count;
};
[[vk::push_constant]] SubParams gP;

RWStructuredBuffer<float> gArena : register(u0);

[numthreads(256, 1, 1)]
void main(uint3 tid : SV_DispatchThreadID)
{
    const uint i = tid.x;
    if (i >= gP.count) return;   // ⚠️ 범위 검사는 커널의 몫
    gArena[gP.outOff + i] = gArena[gP.aOff + i] - gArena[gP.bOff + i];
}
