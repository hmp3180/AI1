// act_coeff_sweep.cs.hlsl — 🔧 고정 ids에서 잔차 좌표 갱신 한 바퀴.
//
// 현재 재구성의 잔차로 k개 코드북 원자를 오름차순 한 번씩 보정한다. ids·코드북은 그대로고
// mag만 바뀐다. 행마다 워크그룹 하나이며, 64 lane의 고정 감산으로 dot/norm을 결정적으로 센다.

struct ActCoeffSweepParams
{
    uint targetOff, reconOff, tableOff, idsOff;
    uint magInOff, magOutOff, rows, k;
    uint pixels, dict;
    float eps;
    uint pad0, pad1, pad2, pad3, pad4;
};
[[vk::push_constant]] ActCoeffSweepParams gP;

RWStructuredBuffer<float> gArena : register(u0);
groupshared float gResidual[256];
groupshared float gDot[64];
groupshared float gNorm[64];
groupshared float gDelta;

[numthreads(64, 1, 1)]
void main(uint3 gid : SV_GroupID, uint3 lane3 : SV_GroupThreadID)
{
    const uint row = gid.x, lane = lane3.x;
    if (row >= gP.rows || gP.pixels > 256) return;
    const uint kb = row * gP.k, pb = row * gP.pixels;

    if (lane < gP.k)
        gArena[gP.magOutOff + kb + lane] = gArena[gP.magInOff + kb + lane];
    for (uint px = lane; px < gP.pixels; px += 64)
        gResidual[px] = gArena[gP.targetOff + pb + px] - gArena[gP.reconOff + pb + px];
    GroupMemoryBarrierWithGroupSync();

    for (uint j = 0; j < gP.k; ++j)
    {
        const uint id = (uint)gArena[gP.idsOff + kb + j];
        float dot = 0.0, norm = 0.0;
        if (id < gP.dict)
        {
            for (uint px = lane; px < gP.pixels; px += 64)
            {
                const float u = gArena[gP.tableOff + id * gP.pixels + px];
                dot += u * gResidual[px];
                norm += u * u;
            }
        }
        gDot[lane] = dot;
        gNorm[lane] = norm;
        GroupMemoryBarrierWithGroupSync();
        for (uint stride = 32; stride > 0; stride >>= 1)
        {
            if (lane < stride)
            {
                gDot[lane] += gDot[lane + stride];
                gNorm[lane] += gNorm[lane + stride];
            }
            GroupMemoryBarrierWithGroupSync();
        }
        if (lane == 0)
        {
            gDelta = (id < gP.dict) ? (gDot[0] / (gNorm[0] + gP.eps)) : 0.0;
            gArena[gP.magOutOff + kb + j] += gDelta;
        }
        GroupMemoryBarrierWithGroupSync();
        if (id < gP.dict)
            for (uint px = lane; px < gP.pixels; px += 64)
                gResidual[px] -= gDelta * gArena[gP.tableOff + id * gP.pixels + px];
        GroupMemoryBarrierWithGroupSync();
    }
}
