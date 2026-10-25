// vis_recon.cs.hlsl — 🖼️ **활성 k개로 프레임을 되만든다.** `recon[r][px] = Σ_j mag[r][j] · Dtab[ ids[r][j] ][px]`
//
// ★ **왜 이 커널이 필요한가 — `embed` 도 `gemm` 도 이 모양이 아니다.**
//   ㉠ `embed` 계열은 행마다 **id 하나**(또는 자리마다 하나)를 조회해 더한다 — 여기는 행마다 `k` 개이고
//      각 항에 **세기 `mag` 가 곱해진다**(가중합이다. 순수 조회가 아니다).
//   ㉡ `gemm` 으로 접으려면 활성을 `rows×N` **밀집 원핫×세기** 행렬로 펼쳐야 하는데, `N`=512·`k`=8 이라
//      **64배 낭비**이고 그 펼치는 커널이 또 필요하다(그래서 새로 만드는 쪽이 더 적다).
//   ⇒ **희소 (id, 세기) → 밀집 프레임**이 이 커널의 정체이고, 저장소에 그 모양이 없다.
//
// ★ **붕괴 감시가 이 커널의 출력을 쓴다.** 인코더가 상수를 내면 다음 스텝 예측이 완벽해지는
//   **붕괴**가 손실로는 성공처럼 보인다 — 그것을 잡는 것은 **재구성 오차 + 사전 사용률**뿐이다.
//   ⇒ 재구성은 "보조 손실" 로 보이지만 **뺄 수 없다**(빼면 붕괴를 못 본다).
//
// ★ **스레드 하나가 `(픽셀 px, 행 r)` 를 맡는다** — 그 칸의 주인이 하나뿐이라 **쓴다**(`=`).
//   atomic 도 0 초기화도 배리어도 없다. ⚠️ `k` 루프는 **`j` 오름차순 고정** — CPU 레퍼런스
//   (`MLVisReconCpu`)와 **같은 순서**여야 float 합이 견줄 수 있다.
//
// ★ **표적은 `frameNorm`(= frame/255)이다** — 원본 바이트 텐서(`frame`, `patch_embed` 가 읽는 것)와
//   **갈라 둔다**. 손실은 `sub(recon, frameNorm)` 로 기존 커널이 낸다(손실 스칼라는 CPU 가 적는다).
//   ⚠️ 여기서 255 로 나누지 마라 — 정규화를 두 곳에 두면 한쪽만 고쳐진다.
//
// ⚠️⚠️ **`ids` 가 `dict` 범위를 벗어나면 그 항을 건너뛴다**(0 행으로 접지 **않는다**) — bwd 두 커널이
//   전부 같은 규약이다. 한쪽만 다르면 기울기가 엉뚱한 코드북 행으로 가고, 증상은
//   *"재구성이 좀 나쁘다"* 로만 보인다.
// ⚠️ `ids` 는 **float 에 담긴 정수**다(아레나 규약 — 정수 버퍼를 따로 두지 않는다). 0..511 은 float32 에 정확하다.

// ⚠️⚠️ **배치를 호스트(`MLVisReconParams`)와 글자 그대로 맞춘다** — 어긋나면 크래시가 아니라
//   **조용히 틀린 결과**다. float 필드는 **없다**(전부 uint).
struct VisReconParams
{
    uint idsOff, magOff, tableOff, outOff;   // 아레나 안 **float 인덱스**(바이트가 아니다)
    uint rows, k, pixels, dict;
};
[[vk::push_constant]] VisReconParams gP;

RWStructuredBuffer<float> gArena : register(u0);

[numthreads(16, 16, 1)]
void main(uint3 tid : SV_DispatchThreadID)
{
    const uint px = tid.x;   // 픽셀(빠른 축)
    const uint r  = tid.y;   // 활성 행(패치/프레임)
    if (px >= gP.pixels || r >= gP.rows) return;   // ⚠️ 범위 검사는 커널의 몫

    const uint kb = r * gP.k;

    // ① 고른 코드 `k` 개를 세기로 가중해 더한다 — ⚠️ `j` 오름차순 고정.
    float acc = 0.0;
    for (uint j = 0; j < gP.k; ++j)
    {
        const uint v = (uint)gArena[gP.idsOff + kb + j];
        if (v >= gP.dict) continue;                // ⚠️ 범위 밖은 **건너뛴다**(bwd 와 같은 규약)
        acc += gArena[gP.magOff + kb + j] * gArena[gP.tableOff + v * gP.pixels + px];
    }

    // ★ **쓴다**(더하지 않는다) — 이 칸의 주인이 이 스레드뿐이므로 합이 여기서 완성된다.
    gArena[gP.outOff + r * gP.pixels + px] = acc;
}
