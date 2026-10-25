// embed_bwd.cs.hlsl — 🔤◀ **임베딩 표의 기울기**: `dTable[v][d] = Σ_t (tok[t]==v ? dOut[t][d] : 0)`.
//
// ★ **흩뿌리지(scatter) 않고 모은다(gather) — 이 프로젝트에서 결정적인 설계 판정이다.**
//   순진한 방향은 "토큰마다 제 임베딩 행에 `+=`" 인데, 같은 바이트가 배치에 여러 번 나오면
//   **여러 스레드가 같은 자리에 더해** race 가 된다. 그것을 막는 길은 atomic 인데:
//     ⚠️ ㉠ HLSL 의 `InterlockedAdd` 는 **정수 전용**이다 — float 은 `InterlockedCompareExchange` 로
//        비트패턴 CAS 루프를 돌려야 한다(길고 느리다).
//     ⚠️⚠️ ㉡ 더 나쁜 것은 **더해지는 순서가 비결정적**이라는 것이다 → float 합이 **실행마다 달라진다**.
//        이 프로젝트의 판정은 전부 **CPU 레퍼런스와의 수치 일치**인데, 그러면 그 방법론이 통째로 무너진다
//        (오차가 "커널이 틀렸나 순서가 달랐나" 로 갈리지 않는다).
//   ⇒ **방향을 뒤집는다**: 스레드 하나가 `(어휘 v, 차원 d)` 를 맡고 **자기를 쓴 토큰을 훑어 더한다.**
//      · atomic 이 **아예 필요 없다**(각 출력 칸의 주인이 하나다)
//      · **결정적**이다(누산 순서가 t 오름차순으로 고정)
//      · **0 초기화도 필요 없다**(누적이 아니라 **쓴다**)
//   ⚠️ 대가는 스레드마다 `seqLen` 을 훑는 것이다 — 총 비용 `vocab·dim·seqLen`. GEMM 과 같은 자릿수이고,
//     어휘가 **256** 뿐인 바이트 모델에서는 특히 값싸다(그것이 이 설계가 여기 맞는 이유다).

struct EmbedBwdParams
{
    uint tokOff, dOutOff, dTableOff;
    uint seqLen, dim, vocab;
};
[[vk::push_constant]] EmbedBwdParams gP;

RWStructuredBuffer<float> gArena : register(u0);

[numthreads(16, 16, 1)]
void main(uint3 tid : SV_DispatchThreadID)
{
    const uint d = tid.x;   // 임베딩 차원
    const uint v = tid.y;   // 어휘(바이트 값)
    if (d >= gP.dim || v >= gP.vocab) return;

    float acc = 0.0;
    for (uint t = 0; t < gP.seqLen; ++t)
    {
        uint tv = (uint)gArena[gP.tokOff + t];
        if (tv >= gP.vocab) tv = 0u;          // forward 와 **같은 규약**(범위 밖은 0 행)
        if (tv == v) acc += gArena[gP.dOutOff + t * gP.dim + d];
    }
    // ★ **쓴다**(더하지 않는다) — 이 칸의 주인이 이 스레드뿐이므로 합이 여기서 완성된다.
    gArena[gP.dTableOff + v * gP.dim + d] = acc;
}
