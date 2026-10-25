// span_embed_bwd.cs.hlsl — 🧷◀ **구간 임베딩 자리표의 기울기**.
//
//   dSlot[(j·257 + b)][d] = Σ_c ( B(c, j) == b ? dOut[c][d] : 0 )
//
// ★ **흩뿌리지(scatter) 않고 모은다(gather)** — 이 프로젝트의 네 번째 같은 판정이고 이유도 같다:
//   HLSL 의 `InterlockedAdd` 는 정수 전용이고, 무엇보다 **더해지는 순서가 비결정적**이라 float 합이
//   실행마다 달라진다 ⇒ CPU 레퍼런스와의 수치 일치라는 판정 방법론이 통째로 무너진다.
//   ⇒ 스레드 하나가 `(표의 행 v, 차원 d)` 를 맡고 **자기를 쓴 구간을 훑어 더한다.**
//      atomic 없음 · 결정적(c 오름차순) · 0 초기화 불필요(**쓴다**).
//
// ★ 표의 행 `v` 가 `(구간자리 j, 바이트값 b)` 를 통째로 가리키므로 `j = v / 257` 이 **정해져 있다.**
//   ⇒ 자리 루프가 없다. 훑는 길이는 `spans` 뿐이고 총 비용은 `maxLen·257·dim·spans`.
//
// ⚠️⚠️ **길이·접기 규약을 forward 와 글자 그대로 같게** 지킨다(`j >= len` → 256 · 255 초과 → 0).
//   한쪽만 다르면 기울기가 엉뚱한 행으로 가고, 그 증상은 **"복원이 좀 나쁘다"** 로만 보인다.

struct SpanEmbedBwdParams
{
    uint tokOff, startOff, lenOff, aOff;   // a = dOut
    uint bOff, spans, maxLen, dim;         // b = dSlotTable
};
[[vk::push_constant]] SpanEmbedBwdParams gP;

RWStructuredBuffer<float> gArena : register(u0);

[numthreads(16, 16, 1)]
void main(uint3 tid : SV_DispatchThreadID)
{
    const uint d = tid.x;   // 심볼 차원
    const uint v = tid.y;   // 표의 행 = 구간자리 j * 257 + 바이트값 b
    if (d >= gP.dim || v >= gP.maxLen * 257u) return;

    const uint j = v / 257u, b = v % 257u;

    float acc = 0.0;
    for (uint c = 0; c < gP.spans; ++c)
    {
        const uint st = (uint)gArena[gP.startOff + c];
        const uint ln = (uint)gArena[gP.lenOff + c];
        uint cb = 256u;                     // 끝/없음 — forward 와 **같은 규약**
        if (j < ln)
        {
            cb = (uint)gArena[gP.tokOff + st + j];
            if (cb > 255u) cb = 0u;
        }
        if (cb == b) acc += gArena[gP.aOff + c * gP.dim + d];
    }
    // ★ **쓴다**(더하지 않는다) — 이 칸의 주인이 이 스레드뿐이므로 합이 여기서 완성된다.
    gArena[gP.bOff + v * gP.dim + d] = acc;
}
