// patch_embed_bwd.cs.hlsl — 🧱◀ **패치 임베딩 자리표의 기울기**.
//
//   dSlotTable[(s*256 + b)][d] = Σ_p ( byte(p, s) == b ? dOut[p][d] : 0 )
//
// ★ **흩뿌리지(scatter) 않고 모은다(gather)** — `embed_bwd.cs.hlsl` 과 **같은 판정**이고 이유도 같다:
//   HLSL 의 `InterlockedAdd` 는 정수 전용이고, 무엇보다 **더해지는 순서가 비결정적**이라 float 합이
//   실행마다 달라진다. 이 프로젝트의 판정은 전부 CPU 레퍼런스와의 수치 일치이므로 그러면
//   방법론이 통째로 무너진다(오차가 "커널이 틀렸나 순서가 달랐나" 로 갈리지 않는다).
//   ⇒ 스레드 하나가 `(표의 행 v, 차원 d)` 를 맡고 **자기를 쓴 패치를 훑어 더한다.**
//      atomic 이 필요 없고 · 결정적이고(p 오름차순) · 0 초기화도 필요 없다(**쓴다**).
//
// ★ **여기서는 훑는 길이가 `patches` 뿐이다.** 표의 행 `v` 는 `(자리 s, 바이트값 b)` 를 통째로
//   가리키므로 `s = v / 256` 이 **정해져 있고**, 그 자리에서 각 패치는 바이트를 **정확히 하나** 낸다.
//   ⇒ 슬롯 루프가 없다. 총 비용 `slots·256·dim·patches`.
//
// ★ **`posTable` 의 기울기는 만들지 않는다 — `dOut` 이 그것이다.** forward 가 `+ posTable[p][d]` 로
//   그냥 더하므로 미분이 1 이고, `posTable` 의 배치가 `dOut` 과 **글자 그대로 같다**(패치×dim).
//   ⇒ 옵티마이저에 `dOut` 의 오프셋을 그대로 넘기면 된다. 커널도 복사도 없다.
//   ⚠️ 그래서 **`posTable` 의 행 수는 패치 수와 같아야** 한다(다르면 이 지름길이 조용히 깨진다).
//
// ⚠️ 범위 밖 바이트를 **0 으로 접는 규약을 forward 와 똑같이** 지킨다 — 한쪽만 접으면
//   기울기가 엉뚱한 행으로 간다(그리고 그 증상은 "학습이 좀 느리다" 로만 보인다).

struct PatchEmbedBwdParams
{
    uint frameOff, dOutOff, dSlotTableOff, pad0;
    uint frameW, frameH, patchK, dim;
};
[[vk::push_constant]] PatchEmbedBwdParams gP;

RWStructuredBuffer<float> gArena : register(u0);

[numthreads(16, 16, 1)]
void main(uint3 tid : SV_DispatchThreadID)
{
    const uint d = tid.x;   // 임베딩 차원
    const uint v = tid.y;   // 표의 행 = 자리 s * 256 + 바이트값 b

    const uint gridW = gP.frameW / gP.patchK;
    const uint gridH = gP.frameH / gP.patchK;
    const uint patches = gridW * gridH;
    const uint slots = gP.patchK * gP.patchK;
    if (d >= gP.dim || v >= slots * 256u) return;

    const uint s = v / 256u, b = v % 256u;
    const uint sy = s / gP.patchK, sx = s % gP.patchK;

    float acc = 0.0;
    for (uint p = 0; p < patches; ++p)
    {
        const uint py = p / gridW, px = p % gridW;
        const uint fy = py * gP.patchK + sy, fx = px * gP.patchK + sx;
        uint fb = (uint)gArena[gP.frameOff + fy * gP.frameW + fx];
        if (fb > 255u) fb = 0u;          // forward 와 **같은 규약**
        if (fb == b) acc += gArena[gP.dOutOff + p * gP.dim + d];
    }
    // ★ **쓴다**(더하지 않는다) — 이 칸의 주인이 이 스레드뿐이므로 합이 여기서 완성된다.
    gArena[gP.dSlotTableOff + v * gP.dim + d] = acc;
}
