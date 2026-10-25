// span_embed.cs.hlsl — 🧷 **덩어리(구간) → 심볼 하나**. L2 인코더의 최소판.
//
//   out[c][d] = Σ_{j=0..maxLen-1} slot[(j·257 + B(c, j))][d]
//     B(c, j) = (j < len[c]) ? tok[start[c] + j] : 256        ← 256 = **"끝/없음"**
//
// ★ **이것이 L2 다** — 경계망이 정한 구간을 **하나의 심볼**로 접는다. 그리고 그 심볼에서
//   바이트를 되펴는 것이 `local decoder` 다(함정 2: *"정답이 있는 유일한 자리가 바이트다"*).
//
// ★ **구간 상대 자리별 표**여야 한다(`patch_embed`·`ctx_embed` 와 같은 근거).
//   `E[byte] + P[j]` 로 쪼개면 합의 뒤 항이 상수가 되어 **몇 번째 바이트인지가 사라진다**
//   ⇒ `왼쪽`과 `쪽왼`이 같은 심볼이 된다. 그래서 표가 `자리 × 257` 이다.
//
// ⚠️⚠️ **길이가 가변이라 `256`("끝") 이 필요하다.** 짧은 구간을 0 으로 메우면 *"바이트 0 이 있었다"* 와
//   *"거기서 끝났다"* 가 구별되지 않고, 그러면 디코더가 길이를 배울 수 없다.
//   ★ 그리고 디코더의 출력 어휘도 **257**(마지막이 "끝")이라 **인코더와 디코더가 같은 알파벳**을 쓴다.
//
// ⚠️ `start`/`len` 은 아레나에 **float 로** 담긴 정수다(아레나 규약 — 정수 버퍼를 따로 두지 않는다).
//   float32 는 이 범위를 정확히 담는다.
// ⚠️ `len[c] > maxLen` 이면 **앞 `maxLen` 바이트만** 담는다(잘린다). 호출부가 그것을 로그로 알린다 —
//   셰이더에는 로그가 없고, 조용히 죽는 것보다 조용히 자르고 호스트가 판정하는 편이 낫다.

struct SpanEmbedParams
{
    uint tokOff, startOff, lenOff, aOff;   // a = slotTable
    uint bOff, spans, maxLen, dim;         // b = out
};
[[vk::push_constant]] SpanEmbedParams gP;

RWStructuredBuffer<float> gArena : register(u0);

[numthreads(16, 16, 1)]
void main(uint3 tid : SV_DispatchThreadID)
{
    const uint d = tid.x;   // 심볼 차원
    const uint c = tid.y;   // 구간 번호
    if (d >= gP.dim || c >= gP.spans) return;

    const uint st = (uint)gArena[gP.startOff + c];
    const uint ln = (uint)gArena[gP.lenOff + c];

    float acc = 0.0;
    for (uint j = 0; j < gP.maxLen; ++j)
    {
        uint b = 256u;                     // 끝/없음
        if (j < ln)
        {
            b = (uint)gArena[gP.tokOff + st + j];
            if (b > 255u) b = 0u;          // 더러운 값은 0 으로 접는다(로그가 없으므로)
        }
        acc += gArena[gP.aOff + (j * 257u + b) * gP.dim + d];
    }
    // ★ **쓴다**(더하지 않는다) — 이 칸의 주인이 이 스레드뿐이다.
    gArena[gP.bOff + c * gP.dim + d] = acc;
}
