// act_residual_swap.cs.hlsl — 🔁 현재 활성의 재구성 잔차를 보고 원자 하나만 바꾼다.
//
// 최종 활성 수는 k 그대로다. 바깥 원자 중 `score[n]` 계수로 더했을 때 SSE 감소가 가장 큰 후보를
// 하나 고르고, 기존 어느 원자와 바꿀지는 실제 SSE로 정한다. 좋아지는 교체가 없으면 no-op 한다.
// 선택은 이산/stop-gradient이고 최종 `mag=score[id]`라 조건부 bwd는 기존 act_topk_bwd를 쓴다.

struct ActResidualSwapParams
{
    uint targetOff, reconOff, scoreOff, tableOff;
    uint idsInOff, magInOff, idsOutOff, magOutOff;
    uint rows, k, pixels, dict;
    float eps;
    uint pad0, pad1, pad2;
};
[[vk::push_constant]] ActResidualSwapParams gP;

RWStructuredBuffer<float> gArena : register(u0);
groupshared float gBestGain[64];
groupshared uint gBestId[64];

// ★ 행마다 워크그룹 하나, lane 64개가 사전 원자를 나눠 훑는다. 그룹 수를 `rows`로 만들기 위해
// 호스트는 threadsX=`rows*64`를 넘긴다. 감산은 gain 최대·동점 낮은 id로 완전히 결정적이다.
[numthreads(64, 1, 1)]
void main(uint3 gid : SV_GroupID, uint3 lane3 : SV_GroupThreadID)
{
    const uint r = gid.x, lane = lane3.x;
    if (r >= gP.rows) return;
    const uint kb = r * gP.k, pb = r * gP.pixels, sb = r * gP.dict;

    if (lane < gP.k)
    {
        gArena[gP.idsOutOff + kb + lane] = gArena[gP.idsInOff + kb + lane];
        gArena[gP.magOutOff + kb + lane] = gArena[gP.magInOff + kb + lane];
    }

    uint best = gP.dict;
    float bestGain = 0.0;
    for (uint n = lane; n < gP.dict; n += 64)
    {
        bool taken = false;
        for (uint j = 0; j < gP.k; ++j)
            if ((uint)gArena[gP.idsInOff + kb + j] == n) { taken = true; break; }
        if (taken) continue;

        const float m = gArena[gP.scoreOff + sb + n];
        float dot = 0.0, nrm = 0.0;
        for (uint px = 0; px < gP.pixels; ++px)
        {
            const float d = gArena[gP.tableOff + n * gP.pixels + px];
            dot += (gArena[gP.targetOff + pb + px] - gArena[gP.reconOff + pb + px]) * d;
            nrm += d * d;
        }
        const float gain = 2.0 * m * dot - m * m * (nrm + gP.eps);
        if (best == gP.dict || gain > bestGain) { best = n; bestGain = gain; }
    }

    gBestId[lane] = best;
    gBestGain[lane] = bestGain;
    GroupMemoryBarrierWithGroupSync();
    for (uint stride = 32; stride > 0; stride >>= 1)
    {
        if (lane < stride)
        {
            const uint oi = gBestId[lane + stride];
            const float og = gBestGain[lane + stride];
            const uint ci = gBestId[lane];
            const float cg = gBestGain[lane];
            if (oi < gP.dict && (ci == gP.dict || og > cg || (og == cg && oi < ci)))
            { gBestId[lane] = oi; gBestGain[lane] = og; }
        }
        GroupMemoryBarrierWithGroupSync();
    }

    if (lane != 0) return;
    best = gBestId[0];

    float sq0 = 0.0;
    for (uint px = 0; px < gP.pixels; ++px)
    {
        const float q = gArena[gP.targetOff + pb + px] - gArena[gP.reconOff + pb + px];
        sq0 += q * q;
    }

    uint bestDrop = gP.k;
    float bestSq = sq0;
    if (best < gP.dict)
    {
        const float nm = gArena[gP.scoreOff + sb + best];
        for (uint j = 0; j < gP.k; ++j)
        {
            const uint old = (uint)gArena[gP.idsInOff + kb + j];
            if (old >= gP.dict) continue;
            const float om = gArena[gP.magInOff + kb + j];
            float sq = 0.0;
            for (uint px = 0; px < gP.pixels; ++px)
            {
                const float q = gArena[gP.targetOff + pb + px] - gArena[gP.reconOff + pb + px]
                    + om * gArena[gP.tableOff + old * gP.pixels + px]
                    - nm * gArena[gP.tableOff + best * gP.pixels + px];
                sq += q * q;
            }
            if (sq < bestSq) { bestSq = sq; bestDrop = j; }
        }
    }
    if (bestDrop < gP.k)
    {
        gArena[gP.idsOutOff + kb + bestDrop] = (float)best;
        gArena[gP.magOutOff + kb + bestDrop] = gArena[gP.scoreOff + sb + best];
    }
}
