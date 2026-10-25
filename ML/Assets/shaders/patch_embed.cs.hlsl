// patch_embed.cs.hlsl — 🧱 **비전 L1 = 2D 패치 임베딩**.
//
//   out[p][d] = Σ_{s} slotTable[(s * 256 + byte(p, s))][d]  +  posTable[p][d]
//
// ★ **왜 이 모양인가 = 인코딩 층을 하나도 만들지 않으려고.**
//   이 프로젝트의 설계 규칙은 *"인코딩 층의 구조는 주고, 분포 층의 구조는 배우게 한다"* 다.
//   비전의 인코딩 사실은 **2D 격자**뿐이므로 L1 이 주는 것은 **패치 격자**이고, 그 안에서
//   "어느 자리에 어떤 바이트가 있나" 는 전부 **배우는 값**이다.
//
// ★ **바이트를 수로 쓰지 않는다 — 조회한다.** 순진한 방향은 패치 64바이트를 float 벡터로 보고
//   선형사영하는 것인데, 그러면 `0x21` 과 `0x22` 가 **가깝다는 가정**이 박힌다. RGB332 는 채널이
//   패킹된 **인덱스**라 그 가정이 틀리고(밴드 경계에서 색이 튄다), 무엇보다 이 모델의 알파벳은
//   **바이트**다. ⇒ `(자리, 바이트값)` 마다 배우는 벡터를 두고 **더한다**.
//
// ★ **자리별 표여야 한다.** `E_value[byte] + P_slot[s]` 로 쪼개면 합이
//   `(Σ E_value) + (Σ P_slot)` 이 되고 **뒤 항이 상수**라 위치 정보가 통째로 사라진다
//   (더하기는 위치와 값을 섞지 못한다). ⇒ 표를 `slot × 256` 으로 두어 **자리와 값이 함께 색인**되게 한다.
//   ⚠️ 그래서 표가 `(patchK² · 256) × dim` 이다 — 8×8 패치면 16384행. 바이트 어휘가 256 뿐이라 감당된다.
//
// ★ **`posTable` 은 어느 패치인가(2D 격자 자리)** — 여기는 패치마다 한 행이므로 위 함정이 없다
//   (슬롯처럼 합쳐지지 않는다). ⚠️ 그래서 **`dPos` 는 곧 `dOut` 이다** → 역전파 커널이 따로 없다.
//
// ⚠️ 프레임은 아레나에 **float 로** 담긴 0..255 정수다(아레나 규약 — 정수 버퍼를 따로 두지 않는다).
// ⚠️ 범위 밖 값은 **0 으로 접는다**(`embed.cs.hlsl` 과 같은 규약) — 셰이더에 로그가 없으므로
//   조용히 죽는 것보다 조용히 접는 편이 낫고, 더러운 데이터는 호스트가 판정한다.

struct PatchEmbedParams
{
    uint frameOff, slotTableOff, posTableOff, outOff;
    uint frameW, frameH, patchK, dim;
};
[[vk::push_constant]] PatchEmbedParams gP;

RWStructuredBuffer<float> gArena : register(u0);

[numthreads(16, 16, 1)]
void main(uint3 tid : SV_DispatchThreadID)
{
    const uint d = tid.x;   // 임베딩 차원
    const uint p = tid.y;   // 패치 번호(격자 행우선)

    const uint gridW = gP.frameW / gP.patchK;
    const uint gridH = gP.frameH / gP.patchK;
    if (d >= gP.dim || p >= gridW * gridH) return;

    const uint py = p / gridW, px = p % gridW;
    const uint slots = gP.patchK * gP.patchK;

    float acc = gArena[gP.posTableOff + p * gP.dim + d];
    for (uint s = 0; s < slots; ++s)
    {
        const uint sy = s / gP.patchK, sx = s % gP.patchK;
        const uint fy = py * gP.patchK + sy, fx = px * gP.patchK + sx;
        uint b = (uint)gArena[gP.frameOff + fy * gP.frameW + fx];
        if (b > 255u) b = 0u;
        acc += gArena[gP.slotTableOff + (s * 256u + b) * gP.dim + d];
    }
    // ★ **쓴다**(더하지 않는다) — 이 칸의 주인이 이 스레드뿐이다.
    gArena[gP.outOff + p * gP.dim + d] = acc;
}
