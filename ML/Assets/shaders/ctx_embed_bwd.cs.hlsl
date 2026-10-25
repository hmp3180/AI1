// ctx_embed_bwd.cs.hlsl — 🪟◀ **창 임베딩 자리표의 기울기**.
//
//   dSlot[(j·257 + b)][d] = Σ_t ( B(t − (k−1) + j) == b ? dOut[t][d] : 0 )
//
// ★ **흩뿌리지(scatter) 않고 모은다(gather)** — `embed_bwd`·`patch_embed_bwd` 와 **같은 판정**이고
//   이유도 같다: HLSL 의 `InterlockedAdd` 는 정수 전용이고, 무엇보다 **더해지는 순서가 비결정적**이라
//   float 합이 실행마다 달라진다. 이 프로젝트의 판정은 전부 CPU 레퍼런스와의 수치 일치이므로
//   그러면 방법론이 통째로 무너진다.
//   ⇒ 스레드 하나가 `(표의 행 v, 차원 d)` 를 맡고 **자기를 쓴 자리를 훑어 더한다.**
//      atomic 이 필요 없고 · 결정적이고(t 오름차순) · 0 초기화도 필요 없다(**쓴다**).
//
// ★ **표의 행 `v` 가 `(창 자리 j, 바이트값 b)` 를 통째로 가리키므로 `j = v / 257` 이 정해져 있다.**
//   ⇒ 창 루프가 없다. 훑는 길이는 `seqLen` 뿐이고 총 비용은 `k·257·dim·seqLen`.
//
// ⚠️⚠️ **범위·접기 규약을 forward 와 글자 그대로 같게** 지킨다(음수 → 256 · 255 초과 → 0).
//   한쪽만 다르면 기울기가 엉뚱한 행으로 가고, 그 증상은 **"학습이 좀 느리다"** 로만 보인다.

struct CtxEmbedBwdParams
{
    uint tokOff, aOff, bOff, pad0;   // a = dOut · b = dSlotTable
    uint seqLen, ctxK, dim, pad1;
};
[[vk::push_constant]] CtxEmbedBwdParams gP;

RWStructuredBuffer<float> gArena : register(u0);

[numthreads(16, 16, 1)]
void main(uint3 tid : SV_DispatchThreadID)
{
    const uint d = tid.x;   // 임베딩 차원
    const uint v = tid.y;   // 표의 행 = 창 자리 j * 257 + 바이트값 b
    if (d >= gP.dim || v >= gP.ctxK * 257u) return;

    const uint j = v / 257u, b = v % 257u;

    float acc = 0.0;
    for (uint t = 0; t < gP.seqLen; ++t)
    {
        const int i = (int)t - (int)(gP.ctxK - 1u) + (int)j;
        uint tb = 256u;                                 // 없음 — forward 와 **같은 규약**
        if (i >= 0)
        {
            tb = (uint)gArena[gP.tokOff + (uint)i];
            if (tb > 255u) tb = 0u;
        }
        if (tb == b) acc += gArena[gP.aOff + t * gP.dim + d];
    }
    // ★ **쓴다**(더하지 않는다) — 이 칸의 주인이 이 스레드뿐이므로 합이 여기서 완성된다.
    gArena[gP.bOff + v * gP.dim + d] = acc;
}
