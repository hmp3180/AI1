// act_gather.cs.hlsl — 🧲 **고른 id 에서 별도 계수를 읽는다.**
//
// `act_topk` 가 낸 `ids[rows,k]` 를 고정한 채 별도 점수 `a[rows,dict]`를 읽는다.
// `useB != 0`이면 같은 자리의 `b`도 더한다. 출력은 `(a + useB·b) · scale`.
// ★ 선택과 계수를 갈라 재는 커널이므로 **선택은 절대 다시 하지 않는다**.
// ⚠️ 범위 밖 id 는 top-k 센티널 규약과 같게 0 을 낸다.
// ⚠️ 스레드 하나가 슬롯 하나의 유일한 주인이라 리덕션·atomic 이 없다.

struct ActGatherParams
{
    uint aOff, bOff, idsOff, magOff;
    uint rows, dict, k, useB;
    uint pad0, pad1, pad2;
    float scale;
};
[[vk::push_constant]] ActGatherParams gP;

RWStructuredBuffer<float> gArena : register(u0);

[numthreads(64, 1, 1)]
void main(uint3 tid : SV_DispatchThreadID)
{
    const uint i = tid.x;
    const uint count = gP.rows * gP.k;
    if (i >= count) return;
    const uint r = i / gP.k;
    const uint n = (uint)gArena[gP.idsOff + i];
    float v = 0.0;
    if (n < gP.dict)
    {
        v = gArena[gP.aOff + r * gP.dict + n];
        if (gP.useB != 0) v += gArena[gP.bOff + r * gP.dict + n];
    }
    gArena[gP.magOff + i] = v * gP.scale;
}
