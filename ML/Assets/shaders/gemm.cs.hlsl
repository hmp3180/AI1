// gemm.cs.hlsl — 🧮 **C = op(A) · op(B)** (행 우선, `op` = 그대로 또는 전치). 학습 커널의 일꾼이다.
//
// ★ **전치 플래그가 있어서 커널 하나가 forward 와 backward 를 다 한다.**
//   `C = A·B` 의 미분이 둘 다 GEMM 이기 때문이다:
//     · `dA = dC · Bᵀ`  →  `gemm(dC, B, transB=1)`
//     · `dB = Aᵀ · dC`  →  `gemm(A, dC, transA=1)`
//   ⇒ 셰이더를 셋으로 늘리지 않는다. **같은 식의 같은 루프**이고 색인만 다르다.
//
// ★ **아레나 하나에 전부 산다 — 위치는 push constants 의 오프셋이 말한다.**
//   근거(→ `MLCore/mlgpu.cw` 의 아레나 규약): ㉠ 파이프라인 캐시 키에 디스크립터셋 **포인터**가 들어
//   버퍼를 갈아 바인딩하면 같은 셰이더가 여러 파이프라인으로 갈린다 ㉡ **한 커맨드버퍼 안에서 셋을 다시
//   `Update` 하면 앞 디스패치까지 그 값을 본다**. ⇒ 버퍼는 하나를 한 번 바인딩하고 오프셋으로 말한다.
//   그래서 **한 프레임에 gemm 을 몇 번이든 서로 다른 텐서로** 돌릴 수 있다(= 학습 한 스텝).
//
// ⚠️⚠️ **전치는 "논리 모양" 이 아니라 "저장 모양" 을 뒤집는다.** 계산은 늘 `(M×K)·(K×N)` 이고,
//   `transA=1` 은 **A 가 `K×M` 로 저장돼 있다**는 뜻이다(`transB=1` 은 B 가 `N×K`).
//   ⇒ `M`/`N`/`K` 는 **언제나 논리 크기**다. 이 규약을 헷갈리면 색인이 밀려 **크래시 없이 조용히 틀린다**.
//
// ⚠️ **일부러 순진한(naive) 구현이다** — 타일링/`groupshared` 가 없다. 정확성이 먼저이고, 타일링은
//   그 자체로 버그가 있는 최적화라 정확성을 잠근 뒤에 한다. ★ 그때 이 판이 **레퍼런스**가 된다.
// ⚠️ 누산 순서는 `k` 오름차순 — CPU 레퍼런스도 **같은 순서**여야 오차가 최소가 된다(비교 가능성).

// ⚠️⚠️ **마지막이 `float` 다** — 호스트(`MLGemmParams`)와 그 자리·그 타입이 같아야 한다(함정 33).
struct GemmParams
{
    uint  aOff, bOff, cOff;  // 아레나 안 **float 인덱스**(바이트가 아니다)
    uint  M, N, K;           // ★ **논리** 크기: 결과는 M×N, 축약 길이는 K
    uint  transA, transB;    // 0 = 그대로 · 1 = 그 입력이 전치되어 저장돼 있다
    float beta;              // ★ `C = A·B + beta·C`. **기본 0** = 예전과 글자 그대로 같다
};
[[vk::push_constant]] GemmParams gP;

RWStructuredBuffer<float> gArena : register(u0);

[numthreads(16, 16, 1)]
void main(uint3 tid : SV_DispatchThreadID)
{
    const uint col = tid.x;
    const uint row = tid.y;
    // ⚠️ 범위 밖 스레드는 **스스로 버린다** — 엔진은 그룹 단위로만 나눌 수 있다.
    if (row >= gP.M || col >= gP.N) return;

    float acc = 0.0;
    for (uint k = 0; k < gP.K; ++k)
    {
        // A 의 (row, k) — 그대로면 M×K, 전치면 K×M 저장이다.
        const uint ai = (gP.transA != 0u) ? (k * gP.M + row) : (row * gP.K + k);
        // B 의 (k, col) — 그대로면 K×N, 전치면 N×K 저장이다.
        const uint bi = (gP.transB != 0u) ? (col * gP.K + k) : (k * gP.N + col);
        acc += gArena[gP.aOff + ai] * gArena[gP.bOff + bi];
    }

    // ★ **`beta` 로 누산한다** — `C = A·B + beta·C`(BLAS 규약 그대로).
    //   ⚠️⚠️ **왜 필요해졌나**: 어텐션의 `dPatch = dQ·Wqᵀ + dK·Wkᵀ + dV·Wvᵀ` 처럼 **한 텐서에 여러
    //     기울기가 모이는** 자리가 생겼다. 그때 선택은 셋이었다 — ㉠ `add` 커널을 새로 만든다
    //     ㉡ Q/K/V 를 한 행렬로 이어 붙인다(⚠️ 그러면 `Q` 가 행 간격 `3D` 인 조각이 되어 이 커널이
    //     못 읽는다 — 간격 인자가 없다) ㉢ **여기에 `beta` 한 칸.** ㉢이 가장 작고, 그리고 이것은
    //     BLAS 가 60년 전에 같은 이유로 넣은 필드다.
    //   ★ `beta == 0` 을 **곱하지 않고 분기**한다 — `C` 가 초기화 전 쓰레기(NaN/inf)일 수 있고
    //     `0 * NaN = NaN` 이라 곱셈으로 두면 **0 으로 덮는 것이 실패한다**(조용히 NaN 이 번진다).
    const uint ci = gP.cOff + row * gP.N + col;
    gArena[ci] = (gP.beta != 0.0) ? (acc + gP.beta * gArena[ci]) : acc;
}
