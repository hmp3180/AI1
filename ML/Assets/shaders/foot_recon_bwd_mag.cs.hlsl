// foot_recon_bwd_mag.cs.hlsl — 선택 고정 조건부 세기 기울기.
struct FootReconMagBwdParams
{
    uint idsOff, codeOff, xOff, yOff, dOutOff, dMagOff;
    uint frames, k, grid, pixels, dict, rank, span;
};
[[vk::push_constant]] FootReconMagBwdParams gP;
RWStructuredBuffer<float> gArena : register(u0);

[numthreads(16, 16, 1)]
void main(uint3 tid : SV_DispatchThreadID)
{
    const uint j = tid.x, f = tid.y;
    if (j >= gP.k || f >= gP.frames) return;
    const uint patches = gP.grid * gP.grid;
    const uint cand = (uint)gArena[gP.idsOff + f * gP.k + j];
    float grad = 0.0;
    if (cand < patches * gP.dict)
    {
        const uint a = cand / gP.dict, v = cand % gP.dict;
        const uint ax = a % gP.grid, ay = a / gP.grid;
        for (uint p = 0; p < patches; ++p)
        {
            const uint px = p % gP.grid, py = p / gP.grid;
            const uint dx = px + (gP.grid - 1u) - ax;
            const uint dy = py + (gP.grid - 1u) - ay;
            float space = 0.0;
            for (uint r = 0; r < gP.rank; ++r)
            {
                const uint b = (v * gP.rank + r) * gP.span;
                space += gArena[gP.xOff + b + dx] * gArena[gP.yOff + b + dy];
            }
            const uint db = (f * patches + p) * gP.pixels;
            const uint cb = v * gP.pixels;
            for (uint d = 0; d < gP.pixels; ++d)
                grad += gArena[gP.dOutOff + db + d] * space * gArena[gP.codeOff + cb + d];
        }
    }
    gArena[gP.dMagOff + f * gP.k + j] = grad;
}
