// rmsnorm_bwd.cs.hlsl — 📏◀ **RMSNorm 의 입력 기울기.**
//   `dX[t][i] = rstd[t] · ( dY_i·g_i − x̂_i · (1/D)·Σ_j dY_j·g_j·x̂_j )`,  `x̂ = x·rstd`
//
// ★ **왜 이 커널이 필요한가** — `rstd` 가 **행의 모든 원소에 의존**하므로 야코비안이 대각이 아니다
//   (원소별 커널로는 원리적으로 안 된다). 그리고 `softmax_bwd` 처럼 「출력만으로」 써지지도 않는다 —
//   `x` 와 `g` 를 다시 봐야 한다. ⇒ 기존 커널 조합으로 접히지 않는 자리다.
//
// ★ **야코비안을 행렬로 만들지 않는다** — `∂y_j/∂x_i = g_j(δ_ij·rstd − rstd·x̂_i·x̂_j/D)` 를 그대로
//   곱하면 행마다 `D×D`(=256×256) 가 생기는데, 위 식처럼 **행 내적 하나**(`Σ dY·g·x̂`)로 접힌다.
//   ⇒ 비용 `O(cols)` · 추가 메모리 0. `softmax_bwd` 와 **같은 관용구**다.
//
// ★ **`rstd` 를 다시 계산하지 않고 fwd 가 남긴 것을 읽는다** — 다시 계산하면 fwd 와 정확히 같은
//   값이라는 보장이 없고(누산 순서·컴파일러), 그 미세한 차가 gradcheck 판정을 흐린다.
//   ⚠️ 그래서 호스트는 fwd 의 `rstd` 텐서를 **덮지 말고** 여기까지 들고 와야 한다.
//
// ★ **`gain` 의 기울기는 여기서 내지 않는다** — `dG[d] = Σ_t (…)` 는 **행 방향 리덕션**이라 이 커널의
//   스레드 배정(행 하나 = 스레드 하나)과 축이 어긋난다. 한 커널에 섞으면 여러 스레드가 같은 `dG[d]` 에
//   더해야 하고 그것은 atomic + 비결정적 누산이다(= 이 저장소가 금지한 자리). ⇒ `rmsnorm_gbwd.cs.hlsl`.
//
// ★ **pre-norm 이므로 잔차는 정규화 전 값에 더한다** — 그 배관(잔차 경로의 `beta=1` 누산)은 호스트의 몫이고
//   이 커널은 자기 `dX` 만 **쓴다**(`=`). ⚠️ 잔차 기울기를 여기서 더하지 마라(호스트가 두 번 더한다).
//
// ⚠️ 누산 순서는 `j` 오름차순 — CPU 레퍼런스(`MLRmsNormBwdCpu`)와 **같은 순서**여야 견줄 수 있다.

// ⚠️⚠️ **배치를 호스트(`MLRmsNormBwdParams`)와 글자 그대로 맞춘다** — 어긋나면 크래시가 아니라
//   **조용히 틀린 결과**다(relu 의 `count = 0` 사고 · 모든 축 이득 정확히 +0.00).
//   ★ float 필드가 하나도 없다(`eps` 는 fwd 가 이미 `rstd` 에 접어 넣었다) → 남는 칸은 `pad0` 로 명시한다.
struct RmsNormBwdParams
{
    uint inOff, gainOff, rstdOff, dOutOff;
    uint dInOff, rows, cols, pad0;
};
[[vk::push_constant]] RmsNormBwdParams gP;

RWStructuredBuffer<float> gArena : register(u0);

[numthreads(64, 1, 1)]
void main(uint3 tid : SV_DispatchThreadID)
{
    const uint r = tid.x;
    if (r >= gP.rows) return;          // ⚠️ 범위 검사는 커널의 몫

    const uint base = r * gP.cols;
    const float rstd = gArena[gP.rstdOff + r];   // ★ fwd 가 남긴 값(다시 계산하지 않는다)

    // ① 행 내적 `dot = Σ_j dY_j · g_j · x̂_j` — ⚠️ `j` 오름차순.
    float dot = 0.0;
    for (uint j = 0; j < gP.cols; ++j)
    {
        const float dy = gArena[gP.dOutOff + base + j];
        const float g  = gArena[gP.gainOff + j];
        const float xh = gArena[gP.inOff + base + j] * rstd;
        dot += dy * g * xh;
    }

    // ② `dX_i = rstd · ( dY_i·g_i − x̂_i · dot/D )`
    //   ⚠️ `1/D` 를 **밖으로 빼서** `dot` 에 한 번만 곱한다(원소마다 나누면 반올림이 CPU 와 갈린다).
    const float mean = dot / (float)gP.cols;
    for (uint i = 0; i < gP.cols; ++i)
    {
        const float dy = gArena[gP.dOutOff + base + i];
        const float g  = gArena[gP.gainOff + i];
        const float xh = gArena[gP.inOff + base + i] * rstd;
        gArena[gP.dInOff + base + i] = rstd * (dy * g - xh * mean);
    }
}
