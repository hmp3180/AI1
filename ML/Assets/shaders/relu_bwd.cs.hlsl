// relu_bwd.cs.hlsl — 🔀◀ **ReLU 의 기울기**: `dIn[i] = (pre[i] > 0) ? dOut[i] : 0`.
//
// ★ **활성 전 값(`pre`)을 읽는다 — 활성 후 값이 아니다.**
//   ⚠️ 수학적으로는 `out > 0` 과 `pre > 0` 이 같지만, **`out` 을 제자리(in-place)로 덮어썼다면**
//     그 정보가 사라진다. ⇒ 호스트가 `pre` 를 따로 들고 있게 하고 여기서 그것을 읽는다.
//   ★ 그리고 `pre == 0` 을 **0 쪽으로** 보낸다(`>` 이지 `>=` 가 아니다) — CPU 레퍼런스와
//     **글자 그대로 같아야** 하므로 이 경계를 한 곳에서 정한다.
//
// ⚠️ 원소별이라 **쓰기 충돌이 없다** — 이 커널에는 gather/scatter 논쟁이 아예 없다.

// ★ 배치는 호스트(`MLReluParams`)와 같다 — `{ a=pre, b=dOut, c=dIn, count }`.
struct ReluBwdParams
{
    uint aOff, bOff, cOff, count;
};
[[vk::push_constant]] ReluBwdParams gP;

RWStructuredBuffer<float> gArena : register(u0);

[numthreads(256, 1, 1)]
void main(uint3 tid : SV_DispatchThreadID)
{
    const uint i = tid.x;
    if (i >= gP.count) return;
    const float pre = gArena[gP.aOff + i];
    gArena[gP.cOff + i] = (pre > 0.0) ? gArena[gP.bOff + i] : 0.0;
}
