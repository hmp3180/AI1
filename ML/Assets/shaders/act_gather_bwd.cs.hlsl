// act_gather_bwd.cs.hlsl — 🧲◀ **고른 계수의 기울기를 점수 행렬로 보낸다.**
//
// 흘뿌리기 대신 `(r,n)` 스레드가 자기를 고른 슬롯 `j` 를 오름차순으로 모은다.
// ⇒ float atomic 없음 · 결정적 누산 · 0 초기화 불필요.
// `add != 0`은 기존 선택 STE 기울기 뒤에 계수 기울기를 누산하는 ㈂ 전용 규약이다.

struct ActGatherBwdParams
{
    uint idsOff, dMagOff, dInOff, add;
    uint rows, dict, k, pad0;
    uint pad1, pad2, pad3;
    float scale;
};
[[vk::push_constant]] ActGatherBwdParams gP;

RWStructuredBuffer<float> gArena : register(u0);

[numthreads(16, 16, 1)]
void main(uint3 tid : SV_DispatchThreadID)
{
    const uint n = tid.x;
    const uint r = tid.y;
    if (n >= gP.dict || r >= gP.rows) return;
    const uint oBase = r * gP.k;
    float acc = 0.0;
    for (uint j = 0; j < gP.k; ++j)
        if ((uint)gArena[gP.idsOff + oBase + j] == n)
            acc += gArena[gP.dMagOff + oBase + j];
    const uint at = gP.dInOff + r * gP.dict + n;
    const float v = acc * gP.scale;
    gArena[at] = (gP.add != 0) ? (gArena[at] + v) : v;
}
