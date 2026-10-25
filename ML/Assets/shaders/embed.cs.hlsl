// embed.cs.hlsl — 🔤 **임베딩 조회**: `out[t][d] = table[tok[t]][d]`.
//
// ★ 토큰은 아레나에 **float 로** 저장돼 있다(값은 0..255 정수). float32 는 그 범위를 **정확히** 담으므로
//   손실이 없고, 그 덕에 **아레나가 하나로 유지된다**(정수 버퍼를 따로 두면 바인딩이 둘이 되고
//   그것은 아레나 규약이 없애려던 것이다 → MLCore/mlgpu.cw).
//
// ⚠️ 범위 밖 토큰은 **0 행으로 접는다**(크래시 대신) — 데이터가 더러울 때 조용히 죽지 않게.
//   ★ 그 선택의 대가는 "틀린 토큰이 0 으로 학습된다" 인데, 그것은 로그로 잡을 일이고
//     셰이더가 판정할 일이 아니다(셰이더에는 로그가 없다).

struct EmbedParams
{
    uint tokOff, tableOff, outOff;
    uint seqLen, dim, vocab;
};
[[vk::push_constant]] EmbedParams gP;

RWStructuredBuffer<float> gArena : register(u0);

[numthreads(16, 16, 1)]
void main(uint3 tid : SV_DispatchThreadID)
{
    const uint d = tid.x;   // 임베딩 차원
    const uint t = tid.y;   // 시퀀스 자리
    if (d >= gP.dim || t >= gP.seqLen) return;

    uint v = (uint)gArena[gP.tokOff + t];
    if (v >= gP.vocab) v = 0u;

    gArena[gP.outOff + t * gP.dim + d] = gArena[gP.tableOff + v * gP.dim + d];
}
