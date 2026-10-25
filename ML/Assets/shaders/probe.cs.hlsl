// probe.cs.hlsl — 🔧 **P0 배관 검증용 최소 커널.** 학습 커널이 아니다(그건 P1 이다).
//
// ★ **한 커널이 셋을 동시에 재도록 짰다:**
//   · **D**(push constants) — `M`/`N`/`bias` 가 push constant 로 온다. 안 오면 결과가 통째로 틀린다.
//   · **F**(LocalSize) — `[numthreads(16,16,1)]` **2D 타일**이다. 호출부는 스레드 수만 말하고
//     그룹 수는 엔진이 셰이더의 `localSize` 로 나눈다 → 그 계산이 틀리면 **일부 칸이 안 채워진다**.
//   · **G′**(프레임 지연) — 결과를 회수해 봐야 값이 보이는데, 같은 프레임에 회수하면 **디스패치 이전
//     내용**이 나온다(이 엔진은 컴퓨트를 누적해 Present 에서 제출한다).
//
// ★ **검증하기 쉬운 식을 고른 것이 요점이다**: `out[y*N + x] = y*N + x + bias`.
//   ⇒ CPU 가 **한 줄로** 기대값을 만들 수 있고, 어긋난 첫 칸의 index 가 곧 진단이 된다:
//     · 전부 0        = 디스패치가 안 돌았다(또는 회수가 너무 이르다 → G′)
//     · bias 만 빠졌다 = push constants 가 안 왔다(D)
//     · 뒷부분만 0     = 그룹 수가 모자랐다(F — ceil 이 틀렸다)
//   ⚠️ 그래서 세 실패가 **서로 다른 모양**으로 나온다. 하나의 판정으로 뭉개지 않는 것이 이 식의 값이다.
//
// ⚠️ `[numthreads]` 를 엔진 관례(256·1D)와 **일부러 다르게** 뒀다 — 그것이 F 의 시험이다.
//   예전 하드코딩 경로였다면 이 커널은 조용히 틀린 그룹 수로 돌았을 것이다.

// 📦 push constants — HLSL 에서는 `[[vk::push_constant]]` 로 선언한다(DXC → Vulkan).
//   ⚠️ cbuffer(`b#`) 가 아니다: 레지스터를 먹지 않으므로 디스크립터셋 레이아웃에 영향이 없다.
struct ProbeParams
{
    uint  M;      // 행 수(y)
    uint  N;      // 열 수(x)
    uint  bias;   // 결과에 더할 값 — **이것이 오는지가 D 의 판정**이다
    uint  _pad;
};
[[vk::push_constant]] ProbeParams gP;

RWStructuredBuffer<uint> gOut : register(u0);

[numthreads(16, 16, 1)]
void main(uint3 tid : SV_DispatchThreadID)
{
    // ⚠️ **범위 밖 스레드는 스스로 버린다** — `ceil` 로 나눈 그룹 수는 늘 넘치게 잡히므로
    //   이 검사는 커널의 몫이다(엔진이 대신 해 줄 수 없다: 그룹 단위로만 나눌 수 있다).
    if (tid.x >= gP.N || tid.y >= gP.M) return;

    const uint idx = tid.y * gP.N + tid.x;
    gOut[idx] = idx + gP.bias;
}
