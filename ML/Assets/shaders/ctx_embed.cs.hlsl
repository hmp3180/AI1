// ctx_embed.cs.hlsl — 🪟 **인과적 창 임베딩**: 앞 `k` 바이트를 자리별로 조회해 더한다.
//
//   out[t][d] = Σ_{j=0..k-1} slot[(j·257 + B(t − (k−1) + j))][d]      B(i) = (i < 0) ? 256 : byte[i]
//
// ★ **인과적이다 — 미래를 절대 안 본다.** 창이 `t` 에서 **끝나고** 예측 대상은 `byte[t+1]` 이다.
//   ⚠️⚠️ 이것이 함정 1 의 자리다: 학습에서 미래를 보면 생성 시점과 어긋나고, 증상이 원인과 안 닮아
//     제일 오래 헤맨다. ⇒ 색인이 `t` 를 넘지 않는 것이 **이 커널의 유일한 불변식**이다.
//
// ★ **`k` 하나로 "바이그램 vs 접두사" 가 갈린다.**
//   `k = 1` 이면 `out[t] = slot[byte[t]]` 로 **정확히 바이그램**이다(P1 의 그 모델).
//   `k > 1` 이면 접두사(창)를 함께 본다. ⇒ **함정 4**(*"pairwise 점수로는 낱말 경계를 못 찾는다"*)를
//     같은 코드에서 **한 파라미터**로 대비할 수 있다 — 두 구현을 만들면 그 비교가 구현 차이에 오염된다.
//   ⚠️ 이것은 *"덩어리 시작부터"* 의 **고정 길이 근사**다(→ ML.md). 진짜 접두사는 경계를 알아야 하고
//     경계는 이걸로 정하므로 순환이다 — 창이 그 순환을 끊는 발판이다.
//
// ★ **자리별 표여야 한다**(`patch_embed` 와 같은 근거). `E[byte] + P[j]` 로 쪼개면 합의 뒤 항이
//   상수가 되어 **어느 자리의 바이트인지가 사라진다**. ⇒ 표를 `자리 × 257` 로 둔다.
//
// ⚠️⚠️ **행이 256 이 아니라 `257` 이다** — 마지막 행(`256`)이 **"없음"**(창이 코퍼스 앞을 넘어감)이다.
//   실제 바이트값 하나를 빌려 쓰면 *"앞이 없다"* 와 *"그 바이트였다"* 가 구별되지 않는다.
//
// ⚠️ 토큰은 아레나에 **float 로** 담긴 0..255 정수다(아레나 규약 — 정수 버퍼를 따로 두지 않는다).

struct CtxEmbedParams
{
    uint tokOff, aOff, bOff, pad0;   // a = slotTable · b = out
    uint seqLen, ctxK, dim, pad1;
};
[[vk::push_constant]] CtxEmbedParams gP;

RWStructuredBuffer<float> gArena : register(u0);

[numthreads(16, 16, 1)]
void main(uint3 tid : SV_DispatchThreadID)
{
    const uint d = tid.x;   // 임베딩 차원
    const uint t = tid.y;   // 시퀀스 자리(창이 여기서 끝난다)
    if (d >= gP.dim || t >= gP.seqLen) return;

    float acc = 0.0;
    for (uint j = 0; j < gP.ctxK; ++j)
    {
        // ⚠️ 부호 있는 계산을 int 로 한다 — uint 로 하면 음수가 거대한 값으로 감겨 경계 검사가 무력해진다.
        const int i = (int)t - (int)(gP.ctxK - 1u) + (int)j;
        uint b = 256u;                                  // 없음(코퍼스 앞을 넘어감)
        if (i >= 0)
        {
            b = (uint)gArena[gP.tokOff + (uint)i];
            if (b > 255u) b = 0u;                       // 더러운 값은 0 으로 접는다(로그가 없으므로)
        }
        acc += gArena[gP.aOff + (j * 257u + b) * gP.dim + d];
    }
    // ★ **쓴다**(더하지 않는다) — 이 칸의 주인이 이 스레드뿐이다.
    gArena[gP.bOff + t * gP.dim + d] = acc;
}
