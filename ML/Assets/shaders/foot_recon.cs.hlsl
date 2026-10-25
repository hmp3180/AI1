// foot_recon.cs.hlsl — 프레임 전역 top-k 후보를 이동 가능한 상대 발자국으로 되만든다.
// token = (anchor patch, learned id, mag), candidate = anchor*dict+id.
struct FootReconParams
{
    uint idsOff, magOff, codeOff, xOff, yOff, outOff;
    uint frames, k, grid, pixels, dict, rank, span;
};
[[vk::push_constant]] FootReconParams gP;
RWStructuredBuffer<float> gArena : register(u0);

[numthreads(16, 16, 1)]
void main(uint3 tid : SV_DispatchThreadID)
{
    const uint d = tid.x, row = tid.y;
    const uint patches = gP.grid * gP.grid;
    if (d >= gP.pixels || row >= gP.frames * patches) return;
    const uint f = row / patches, p = row % patches;
    const uint px = p % gP.grid, py = p / gP.grid;
    float outv = 0.0;
    for (uint j = 0; j < gP.k; ++j)
    {
        const uint cand = (uint)gArena[gP.idsOff + f * gP.k + j];
        if (cand >= patches * gP.dict) continue;
        const uint a = cand / gP.dict, v = cand % gP.dict;
        const uint ax = a % gP.grid, ay = a / gP.grid;
        const uint dx = px + (gP.grid - 1u) - ax;
        const uint dy = py + (gP.grid - 1u) - ay;
        float space = 0.0;
        for (uint r = 0; r < gP.rank; ++r)
        {
            const uint b = (v * gP.rank + r) * gP.span;
            space += gArena[gP.xOff + b + dx] * gArena[gP.yOff + b + dy];
        }
        outv += gArena[gP.magOff + f * gP.k + j] * space * gArena[gP.codeOff + v * gP.pixels + d];
    }
    gArena[gP.outOff + row * gP.pixels + d] = outv;
}
