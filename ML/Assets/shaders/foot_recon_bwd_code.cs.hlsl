// foot_recon_bwd_code.cs.hlsl — 코드북 기울기. scatter 대신 (id,pixel) gather다.
struct FootReconCodeBwdParams
{
    uint idsOff, magOff, xOff, yOff, dOutOff, dCodeOff;
    uint frames, k, grid, pixels, dict, rank, span;
};
[[vk::push_constant]] FootReconCodeBwdParams gP;
RWStructuredBuffer<float> gArena : register(u0);

[numthreads(16, 16, 1)]
void main(uint3 tid : SV_DispatchThreadID)
{
    const uint d = tid.x, v = tid.y;
    if (d >= gP.pixels || v >= gP.dict) return;
    const uint patches = gP.grid * gP.grid;
    float grad = 0.0;
    for (uint f = 0; f < gP.frames; ++f)
        for (uint j = 0; j < gP.k; ++j)
        {
            const uint cand = (uint)gArena[gP.idsOff + f * gP.k + j];
            if (cand >= patches * gP.dict || cand % gP.dict != v) continue;
            const uint a = cand / gP.dict, ax = a % gP.grid, ay = a / gP.grid;
            const float mag = gArena[gP.magOff + f * gP.k + j];
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
                grad += mag * space * gArena[gP.dOutOff + (f * patches + p) * gP.pixels + d];
            }
        }
    gArena[gP.dCodeOff + v * gP.pixels + d] = grad;
}
