// act_topk_bwd.cs.hlsl — ⭐◀ **활성 선택의 기울기**: `dZ[r][n] = Σ_j ( ids[r][j] == n ? dMag[r][j] : 0 )`
//
// ★ **선택은 상수로 본다(straight-through)** — top-k 는 이산이라 미분이 없다. 기울기는
//   **세기(`mag`)로만** 흐르고, 그 세기는 `mag[r][j] = z[r][ids[r][j]]` 라 미분이 **정확히 1** 이다
//   ⇒ 고른 자리로만 `dMag` 가 그대로 들어가고 **나머지 사전 자리는 정확히 0** 이다.
//   ⚠️⚠️ 그래서 gradcheck 는 **「선택 고정 조건부」**로만 성립한다 — 중앙차분에서 ±ε 로 `z` 를 흔들 때
//     `ids` 를 **다시 고르면 안 된다**. 흔들다가 순위가 바뀌는 순간 손실이 꺾여서(비연속) 수치기울기가
//     해석기울기와 무한히 갈린다. 이것을 안 적으면 다음 사람이 *"이 커널은 gradcheck 를 못 통과한다"*
//     로 오진한다 — 못 통과하는 것이 아니라 **재는 방법이 틀린 것**이다.
//
// ★ **흩뿌리지(scatter) 않고 모은다(gather)** — 순진한 방향은 "슬롯 j 마다 `dZ[ids[j]]` 에 `+=`"
//   인데 그것은 ㉠ HLSL 의 `InterlockedAdd` 가 정수 전용이고 ㉡ 더해지는 순서가 **비결정적**이라
//   float 합이 실행마다 달라진다 ⇒ CPU 레퍼런스와의 수치 일치라는 판정이 통째로 무너진다.
//   ⇒ 스레드 하나가 `(행 r, 사전 자리 n)` 을 맡고 **자기를 고른 슬롯을 훑어 더한다**(`embed_bwd` 와 같은 판정).
//      atomic 없음 · 결정적(`j` 오름차순) · **0 초기화 불필요**(누적이 아니라 **쓴다**).
//   ★ 훑는 길이가 `k`(=8)뿐이라 이 방향의 대가가 사실상 없다 — 사전 자리별로 8 번만 본다.
//
// ★ **`ids` 의 기울기는 없다** — 정수 색인이다(학습 대상이 아니다). `dMag` 만 받는다.
//
// ⚠️ 중복 `id` 는 fwd 의 「제외」 때문에 원리적으로 안 나오지만, 그래도 **합으로 둔다** —
//   호스트가 다른 경로로 `ids` 를 채워도(캐시·재현) 뜻이 안 깨지고 결정성도 그대로다.
//
// ⚠️ `ids` 가 `dict` 범위를 벗어난 슬롯(`k > dict` 로 남은 자리 · 센티널 `dict`)은 `n < dict` 와
//   절대 같지 않으므로 **저절로 건너뛴다** — fwd 와 같은 규약이고 분기를 따로 안 쓴다.

// ⚠️⚠️ **배치를 호스트(`MLActTopkBwdParams`)와 글자 그대로 맞춘다.** fwd 의 `ActTopkParams` 와
//   **바이트 배치가 같다**(오프셋 셋 + pad + 크기 셋 + pad) — 이름만 방향에 맞게 다르다.
struct ActTopkBwdParams
{
    uint idsOff, dMagOff, dScoreOff, pad0;   // 아레나 안 **float 인덱스**
    uint rows, dict, k, pad1;
};
[[vk::push_constant]] ActTopkBwdParams gP;

RWStructuredBuffer<float> gArena : register(u0);

[numthreads(16, 16, 1)]
void main(uint3 tid : SV_DispatchThreadID)
{
    const uint n = tid.x;   // 사전 자리(빠른 축)
    const uint r = tid.y;   // 행
    if (n >= gP.dict || r >= gP.rows) return;   // ⚠️ 범위 검사는 커널의 몫

    const uint oBase = r * gP.k;

    // ★ `j` 오름차순 — CPU 레퍼런스(`MLActTopkBwdCpu`)와 **같은 순서**여야 견줄 수 있다.
    float acc = 0.0;
    for (uint j = 0; j < gP.k; ++j)
        if ((uint)gArena[gP.idsOff + oBase + j] == n) acc += gArena[gP.dMagOff + oBase + j];

    // ★ **쓴다**(더하지 않는다) — 이 칸의 주인이 이 스레드뿐이므로 합이 여기서 완성된다.
    gArena[gP.dScoreOff + r * gP.dict + n] = acc;
}
