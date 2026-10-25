// foot_recon_bwd_space.cs.hlsl — 분리 상대 발자국 X/Y 기울기. 한 스레드가 두 출력 칸을 쓴다.
struct FootReconSpaceBwdParams
{
    uint idsOff, magOff, codeOff, xOff, yOff, dOutOff, dXOff, dYOff;
    uint frames, k, grid, pixels, dict, rank, span;
};
[[vk::push_constant]] FootReconSpaceBwdParams gP;
RWStructuredBuffer<float> gArena : register(u0);

[numthreads(16, 16, 1)]
void main(uint3 tid : SV_DispatchThreadID)
{
    const uint q = tid.x, vr = tid.y;
    if (q >= gP.span || vr >= gP.dict * gP.rank) return;
    const uint v = vr / gP.rank, r = vr % gP.rank;
    const uint patches = gP.grid * gP.grid;
    float gx = 0.0, gy = 0.0;
    for (uint f = 0; f < gP.frames; ++f)
        for (uint j = 0; j < gP.k; ++j)
        {
            const uint cand = (uint)gArena[gP.idsOff + f * gP.k + j];
            if (cand >= patches * gP.dict || cand % gP.dict != v) continue;
            const uint a = cand / gP.dict, ax = a % gP.grid, ay = a / gP.grid;
            const float mag = gArena[gP.magOff + f * gP.k + j];
            const int outX = (int)ax + (int)q - (int)(gP.grid - 1u);
            if (outX >= 0 && outX < (int)gP.grid)
                for (uint py = 0; py < gP.grid; ++py)
                {
                    const uint dy = py + (gP.grid - 1u) - ay;
                    float dot = 0.0;
                    const uint db = (f * patches + py * gP.grid + (uint)outX) * gP.pixels;
                    for (uint d = 0; d < gP.pixels; ++d)
                        dot += gArena[gP.dOutOff + db + d] * gArena[gP.codeOff + v * gP.pixels + d];
                    gx += mag * gArena[gP.yOff + vr * gP.span + dy] * dot;
                }
            const int outY = (int)ay + (int)q - (int)(gP.grid - 1u);
            if (outY >= 0 && outY < (int)gP.grid)
                for (uint px = 0; px < gP.grid; ++px)
                {
                    const uint dx = px + (gP.grid - 1u) - ax;
                    float dot = 0.0;
                    const uint db = (f * patches + (uint)outY * gP.grid + px) * gP.pixels;
                    for (uint d = 0; d < gP.pixels; ++d)
                        dot += gArena[gP.dOutOff + db + d] * gArena[gP.codeOff + v * gP.pixels + d];
                    gy += mag * gArena[gP.xOff + vr * gP.span + dx] * dot;
                }
        }
    gArena[gP.dXOff + vr * gP.span + q] = gx;
    gArena[gP.dYOff + vr * gP.span + q] = gy;
}
