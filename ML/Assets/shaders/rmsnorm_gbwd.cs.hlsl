// rmsnorm_gbwd.cs.hlsl — 📏◀ **RMSNorm 이득(`g`)의 기울기.** `dG[d] = Σ_t dY[t][d] · x[t][d] · rstd[t]`
//
// ★ **왜 `rmsnorm_bwd` 와 갈랐나** — `dG` 는 **열마다 행 전체를 훑는 리덕션**이다. `rmsnorm_bwd` 는
//   「행 하나 = 스레드 하나」라 축이 정반대이고, 한 커널에 섞으면 여러 스레드가 같은 `dG[d]` 에 더해야
//   한다 ⇒ atomic(HLSL 은 float atomic 이 없어 CAS 루프) + **비결정적 누산 순서**. 그러면 CPU 레퍼런스
//   대조라는 이 프로젝트의 판정 방법론이 통째로 무너진다. ⇒ **커널을 갈라 gather 로 만든다.**
//   ★ `embed_bwd`·`span_embed_bwd`·`patch_embed_bwd` 와 **같은 판정**이고 이유도 같다.
//
// ★ **스레드 하나가 열 `d` 를 맡고 행을 훑는다** — 그 칸의 주인이 하나뿐이므로
//   atomic 도, 0 초기화 디스패치도, 배리어도 필요 없고 **쓴다**(`=`, 더하지 않는다).
//   ⚠️ 그래서 `dG` 를 여러 층이 공유하게 두지 마라 — 덮어쓴다(층마다 자기 텐서다).
//
// ★ **`x̂ = x·rstd` 가 아니라 `x·rstd` 를 그 자리에서 곱한다** — 수식이 같지만 **행마다 `rstd` 가
//   다르므로** 열 스레드는 행을 훑을 때 `rstd[t]` 를 매번 읽어야 한다(fwd 가 남긴 `rows` 개 float).
//   ⚠️ `rstd` 를 한 번만 읽어 상수처럼 쓰면 조용히 틀린다(행마다 다른 값이다).
//
// ★ 원소별 커널이라 `[numthreads(256,1,1)]` · `Dispatch(cols, 1, 1)` — **스레드 수**로 넘긴다(그룹 수 아님).
//
// ⚠️ 누산 순서는 `t` 오름차순 — CPU 레퍼런스(`MLRmsNormGainBwdCpu`)와 **같은 순서**여야 견줄 수 있다.

// ⚠️⚠️ **배치를 호스트(`MLRmsNormGBwdParams`)와 글자 그대로 맞춘다** — 어긋나면 크래시가 아니라
//   **조용히 틀린 결과**다. float 필드는 없다(`eps` 는 fwd 가 `rstd` 에 접어 넣었다).
struct RmsNormGBwdParams
{
    uint inOff, rstdOff, dOutOff, dGainOff;
    uint rows, cols;
};
[[vk::push_constant]] RmsNormGBwdParams gP;

RWStructuredBuffer<float> gArena : register(u0);

[numthreads(256, 1, 1)]
void main(uint3 tid : SV_DispatchThreadID)
{
    const uint d = tid.x;              // 열(차원) — 이 칸의 유일한 주인
    if (d >= gP.cols) return;          // ⚠️ 범위 검사는 커널의 몫

    // ① `t` 오름차순으로 모은다(gather).
    float acc = 0.0;
    for (uint t = 0; t < gP.rows; ++t)
    {
        const uint base = t * gP.cols;
        acc += gArena[gP.dOutOff + base + d] * gArena[gP.inOff + base + d] * gArena[gP.rstdOff + t];
    }

    // ★ **쓴다**(더하지 않는다) — 이 칸의 주인이 이 스레드뿐이므로 합이 여기서 완성된다.
    gArena[gP.dGainOff + d] = acc;
}
