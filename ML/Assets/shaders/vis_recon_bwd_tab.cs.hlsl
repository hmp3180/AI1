// vis_recon_bwd_tab.cs.hlsl — 🖼️◀ **디코더 코드북의 기울기**.
//
//   dDtab[v][px] = Σ_r Σ_j ( ids[r][j] == v ? mag[r][j] · dRecon[r][px] : 0 )
//
// ★ **흩뿌리지(scatter) 않고 모은다(gather)** — 이 저장소의 다섯 번째 같은 판정이고 이유도 같다:
//   순진한 방향은 "활성마다 제 코드북 행에 `+=`" 인데 같은 코드가 여러 행에서 뽑히면 **여러 스레드가
//   같은 자리에 더해** race 가 된다. 막는 길은 atomic 인데 ㉠ HLSL 의 `InterlockedAdd` 는 **정수 전용**이고
//   ㉡ 더 나쁜 것은 **더해지는 순서가 비결정적**이라 float 합이 실행마다 달라진다 ⇒ CPU 레퍼런스와의
//   수치 일치라는 이 트랙의 판정 방법론이 통째로 무너진다.
//   ⇒ **방향을 뒤집는다**: 스레드 하나가 `(코드 v, 픽셀 px)` 를 맡고 **자기를 고른 행을 훑어 더한다.**
//      atomic 없음 · 결정적(`r` → `j` 오름차순) · 0 초기화 불필요(**쓴다**).
//   ⚠️ 대가는 스레드마다 `rows·k` 를 훑는 것이다 — 총 비용 `dict·pixels·rows·k`. `k`=8 이라 값싸다
//      (희소가 이 설계를 여기 맞게 만든 자리다).
//
// ★ **디코더 표는 배우는 값이다** — 이것이 안 배워지면 재구성이 못 내려가고, 그러면 붕괴 감시가
//   **거짓 경보**를 낸다("사전이 상수를 낸다" 가 아니라 "디코더가 못 읽는다" 인데 지표가 같다).
//   ⚠️ 그래서 사전 사용률과 **반드시 함께** 본다.
//
// ★ **`px` 를 빠른 축에 둔다** — 코드북이 `dict × pixels` 행 우선이라 그래야 이웃 스레드가
//   이웃 float 을 쓴다(`dRecon` 읽기도 같은 방향). 축을 바꾸면 결과는 같고 속도만 잃는다.
//
// ⚠️⚠️ **`ids` 범위 밖은 fwd 와 같은 규약(건너뛴다)** — `v` 로 등호가 성립하지 않으므로 자연히 빠진다.
//   ⚠️ 한 행이 같은 코드를 **두 번** 골랐다면 fwd 도 두 번 더했으므로 여기도 두 번 더한다(같은 규약).
// ⚠️ `mag`/`dRecon` 곱의 순서를 CPU 레퍼런스와 같게 둔다(`mag * dRecon`) — 부동소수는 그것도 본다.

// ⚠️⚠️ **배치를 호스트(`MLVisReconTabBwdParams`)와 글자 그대로 맞춘다.** float 필드는 **없다**.
struct VisReconTabBwdParams
{
    uint idsOff, magOff, dOutOff, dTableOff;   // dOut = dRecon(rows×pixels) · dTable = dDtab(dict×pixels)
    uint rows, k, pixels, dict;
};
[[vk::push_constant]] VisReconTabBwdParams gP;

RWStructuredBuffer<float> gArena : register(u0);

[numthreads(16, 16, 1)]
void main(uint3 tid : SV_DispatchThreadID)
{
    const uint px = tid.x;   // 픽셀(빠른 축)
    const uint v  = tid.y;   // 코드북 행 = 사전 유닛
    if (px >= gP.pixels || v >= gP.dict) return;   // ⚠️ 범위 검사는 커널의 몫

    // ① 이 코드를 고른 행만 모은다 — ⚠️ `r` → `j` 오름차순 고정(CPU 레퍼런스와 같은 순서).
    float acc = 0.0;
    for (uint r = 0; r < gP.rows; ++r)
    {
        const uint kb = r * gP.k;
        const float dr = gArena[gP.dOutOff + r * gP.pixels + px];
        for (uint j = 0; j < gP.k; ++j)
        {
            if ((uint)gArena[gP.idsOff + kb + j] != v) continue;
            acc += gArena[gP.magOff + kb + j] * dr;
        }
    }

    // ★ **쓴다**(더하지 않는다) — 이 칸의 주인이 이 스레드뿐이므로 합이 여기서 완성된다.
    gArena[gP.dTableOff + v * gP.pixels + px] = acc;
}
