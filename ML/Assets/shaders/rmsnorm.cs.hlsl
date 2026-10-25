// rmsnorm.cs.hlsl — 📏 **행마다 RMS 정규화.** `y[t][d] = x[t][d] · rstd[t] · g[d]`, `rstd[t] = 1/√(mean(x²)+eps)`
//
// ★ **평균을 빼지 않는다** — LayerNorm 이 아니다. 뺄 것이 없으면 bwd 에 항이 하나 줄고
//   `Σx` 를 저장할 자리도 안 생긴다. pre-norm · 바이어스 없음이 이 트랙의 규약이라 이득이 그대로 남는다.
//
// ★ **스레드 하나가 한 행을 맡는다**(softmax 와 같은 관용구) — 행을 나누면 `Σx²` 에 리덕션이
//   필요하고 그 리덕션은 **누산 순서가 비결정적**이 될 수 있다. 판정이 CPU 레퍼런스와의 수치 일치라
//   결정성이 성능보다 값지다. ⚠️ `cols` 가 수천이 되면 다시 볼 자리다(그때는 그룹 리덕션 + 고정 순서).
//
// ★ **`rstd` 를 아레나에 남긴다** — bwd 가 그것을 다시 계산하면 fwd 와 **정확히 같은 값**이 나온다는
//   보장이 없고(순서·컴파일러), 그 미세한 차가 gradcheck 의 판정을 흐린다. `rows` 개 float 이 값싸다.
//   ⚠️ 그래서 이 커널은 **출력 칸이 둘**이다(`y`·`rstd`) — 허용되는 예외는 「한 스레드가 두 칸의 유일한
//   주인」일 때뿐이고 여기가 정확히 그것이다(행 `r` 의 주인은 이 스레드 하나 · 리덕션이 끼지 않는다).
//
// ⚠️ 누산 순서는 `j` 오름차순 — CPU 레퍼런스(`MLRmsNormCpu`)와 **같은 순서**여야 견줄 수 있다.

// ⚠️⚠️ **마지막이 `float` 다** — 호스트(`MLRmsNormParams`)와 그 자리·그 타입이 같아야 한다(함정 33).
struct RmsNormParams
{
    uint  inOff, gainOff, outOff, rstdOff;
    uint  rows, cols;
    float eps;
};
[[vk::push_constant]] RmsNormParams gP;

RWStructuredBuffer<float> gArena : register(u0);

[numthreads(64, 1, 1)]
void main(uint3 tid : SV_DispatchThreadID)
{
    const uint r = tid.x;
    if (r >= gP.rows) return;          // ⚠️ 범위 검사는 커널의 몫

    const uint base = r * gP.cols;

    // ① 제곱합 — `j` 오름차순.
    float ss = 0.0;
    for (uint j = 0; j < gP.cols; ++j)
    {
        const float v = gArena[gP.inOff + base + j];
        ss += v * v;
    }

    // ② `rstd` — ⚠️ `eps` 는 **평균 안쪽**이다(`1/√(mean+eps)`). 밖에 두면 스케일이 갈린다.
    const float rstd = 1.0 / sqrt(ss / (float)gP.cols + gP.eps);
    gArena[gP.rstdOff + r] = rstd;      // ★ bwd 가 이것을 읽는다(다시 계산하지 않는다)

    // ③ 정규화 + 이득. ⚠️ `gain` 은 행이 아니라 **열(차원)** 색인이다.
    for (uint i = 0; i < gP.cols; ++i)
        gArena[gP.outOff + base + i] = gArena[gP.inOff + base + i] * rstd * gArena[gP.gainOff + i];
}
