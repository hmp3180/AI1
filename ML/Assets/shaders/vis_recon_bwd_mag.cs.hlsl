// vis_recon_bwd_mag.cs.hlsl — 🖼️◀ **세기의 기울기**. `dMag[r][j] = Σ_px dRecon[r][px] · Dtab[ ids[r][j] ][px]`
//
// ★ **왜 bwd 가 두 파일인가 — 감산 축이 다르다.** `dMag` 는 **픽셀**을 감산하고(출력 `rows×k`),
//   `dDtab` 는 **행×활성**을 감산한다(출력 `dict×pixels`). 출력 모양도 디스패치 모양도 갈리므로
//   「한 스레드가 두 출력 칸의 주인」예외를 쓸 수 없다 — 스타일 계약이 못 박은 자리다:
//   **리덕션이 끼면 커널을 갈라라.** (합치면 어느 한쪽이 scatter 가 되고 그 순간 결정성이 죽는다.)
//
// ★ **이 기울기가 인코더까지 흐르는 유일한 길이다.** `dMag` 는 그대로 `act_topk_bwd` 의 입력이 되고,
//   거기서 `dZ` 로, 다시 사전 점수를 만든 층으로 흐른다. ⚠️ **끊으면 인코더가 정적 압축기로 남는다**
//   ("경험으로 학습되는 인코딩" 이라는 이 트랙의 정의가 그 경로다 — 「인코더 얼림 대조군」이 재는 차이).
//
// ★ **`ids` 는 상수다**(`act_topk` 의 straight-through) — 선택 자체의 기울기는 없다.
//   ⇒ 이 커널은 고른 자리로만 기울기를 내고 나머지는 **정확히 0** 이다.
//   ⚠️ 그래서 gradcheck 는 **「선택 고정 조건부」**로 잰다(±ε 로 흔들 때 ids 를 다시 고르지 않는다).
//
// ★ **스레드 하나가 `(활성자리 j, 행 r)` 를 맡는다** — 그 칸의 주인이 하나뿐이라 **쓴다**(`=`).
//   ⚠️ 누산 순서는 `px` 오름차순 — CPU 레퍼런스(`MLVisReconMagBwdCpu`)와 **같은 순서**.
//
// ⚠️⚠️ **`ids` 범위 밖은 fwd 와 같은 규약(건너뛴다)** ⇒ 그 자리의 `dMag` 는 **0** 이다.
//   그 항이 fwd 의 합에 없었으므로 기울기도 0 이어야 한다(0 을 안 쓰면 지난 프레임 값이 남는다).

// ⚠️⚠️ **배치를 호스트(`MLVisReconMagBwdParams`)와 글자 그대로 맞춘다.** float 필드는 **없다**.
struct VisReconMagBwdParams
{
    uint idsOff, tableOff, dOutOff, dMagOff;   // dOut = dRecon(rows×pixels)
    uint rows, k, pixels, dict;
};
[[vk::push_constant]] VisReconMagBwdParams gP;

RWStructuredBuffer<float> gArena : register(u0);

[numthreads(16, 16, 1)]
void main(uint3 tid : SV_DispatchThreadID)
{
    const uint j = tid.x;   // 활성 자리(빠른 축)
    const uint r = tid.y;   // 활성 행
    if (j >= gP.k || r >= gP.rows) return;   // ⚠️ 범위 검사는 커널의 몫

    const uint v = (uint)gArena[gP.idsOff + r * gP.k + j];

    // ① 그 코드의 프레임 전체와 `dRecon` 의 내적 — ⚠️ `px` 오름차순 고정.
    //    ⚠️ 범위 밖 id 는 fwd 에서 그 항이 없었다 ⇒ 0 을 쓴다(건너뛰고 끝내면 옛 값이 남는다).
    float acc = 0.0;
    if (v < gP.dict)
    {
        const uint tb = v * gP.pixels;
        const uint db = r * gP.pixels;
        for (uint px = 0; px < gP.pixels; ++px)
            acc += gArena[gP.dOutOff + db + px] * gArena[gP.tableOff + tb + px];
    }

    // ★ **쓴다**(더하지 않는다) — 이 칸의 주인이 이 스레드뿐이다.
    gArena[gP.dMagOff + r * gP.k + j] = acc;
}
