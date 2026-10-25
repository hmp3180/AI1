// rope.cs.hlsl — 🌀 **쌍을 위치각으로 돌린다.** `[y_2p, y_2p+1] = R(pos·ω_p) · [x_2p, x_2p+1]`, `ω_p = theta^(−2p/dim)`
//
// ★ **왜 이 커널이 필요한가 — 기존 커널로는 「위치가 각도인 곱」을 못 만든다.**
//   `gemm` 으로 하려면 **행마다 다른 회전행렬**이 필요하다(`rows × dim × dim` 짜리 텐서 = `T` 가 512 면
//   34억 float). `embed` 계열은 위치를 **더하는** 것이라 내적에 위치차가 남지 않는다(RoPE 의 요점은
//   `<q_m, k_n>` 이 **`m−n`** 에만 의존하게 되는 것이고, 그것은 더하기로는 안 나온다).
//   ⇒ 쌍 하나를 각 `φ` 로 돌리는 **원소별(쌍별) 커널**이 최소 형태다.
//
// ★ **1D(시간)와 2D(패치 x,y)를 `mode` 한 칸으로 가른다 — 파일을 둘로 쪼개지 않는다**(금지목록 23).
//   두 판의 차이는 **① 각을 어느 pos 에서 읽나 ② 주파수 대역을 어느 폭으로 펴나** 둘뿐이고, 회전식은
//   글자 그대로 같다. 파일을 가르면 그 회전식이 **두 벌**이 되어 한쪽만 고치는 사고가 열린다.
//     · `mode = 0` (1D) — `pos[r]` 하나. 축은 하나(폭 `dim`). rows = 토큰×헤드 · dim = Dh.
//     · `mode = 1` (2D) — 앞 절반 채널은 **x**, 뒤 절반은 **y**. `pos` 는 행마다 float 둘(`rows×2`).
//   ★ **2D 는 축마다 「전 대역」을 준다** — 축 폭을 `dim/2` 로 보고 그 안에서 `ω` 를 펴므로
//     x 와 y 가 **같은 분해능**을 갖는다. ⚠️ 전역 `p` 로 대역을 매기면 x 는 고주파만, y 는 저주파만
//     받아 **가로 위치는 세밀하고 세로 위치는 뭉개진다**(회전이라 값은 멀쩡해서 조용히 틀린다).
//   ⚠️ `mode = 1` 은 **`dim % 4 == 0`** 이 전제다(축마다 쌍이 정수여야 한다) — 호스트가 보증한다.
//
// ★ **bwd 는 새 파일이 아니다 — 이 커널을 `dirSign = -1` 로 돌린다.** 회전은 직교라 `Rᵀ = R(−φ)`
//   이고, `dirSign` 은 `sin` 의 부호만 뒤집는다(= 전치). ⚠️ 그래서 `rope_bwd.cs.hlsl` 을 만들지 마라 —
//   회전식이 두 벌이 되는 순간 fwd/bwd 가 갈릴 수 있고, 그것이 이 파일이 존재하는 이유를 무너뜨린다.
//   ⚠️ `pos` 의 기울기는 **없다**(위치는 정수 · 학습 대상이 아니다).
//
// ★ **주파수를 `exp2(e·log2(theta))` 로 만든다** — `pow` 가 아니다. 엔진 `PEMath.h` 가 적어 둔 근거
//   그대로다: GPU 의 기본 명령이 `log2`/`exp2` 이므로 CPU 도 **그 식으로** 계산해야 값이 맞는다
//   (CPU 는 `Exp2`/`Log2` 래퍼). ⚠️ 초월함수라 오차 0 은 요구하지 않는다 — 임계는 1e-5(금지목록 19).
//
// ★ **제자리(in-place) 가 안전하다** — 스레드 하나가 쌍 두 칸의 **유일한 주인**이고 **읽고 나서 쓴다**.
//   그래서 `inOff == outOff` 로 불러도 된다(⇒ 출력 둘의 예외를 쓰는 근거이기도 하다).
//
// ⚠️ 쌍은 **이웃 두 칸 `(2p, 2p+1)`** 이다(반쪽 갈라 `(p, p+dim/2)` 로 짝짓는 판이 아니다) —
//   CPU 레퍼런스(`MLRopeCpu`)와 이 규약이 같아야 견줄 수 있다.
// ⚠️ 누산이 없다(쌍마다 독립) — 그래서 순서 논쟁이 이 커널에는 없다.

// ⚠️⚠️ **배치를 호스트(`MLRopeParams`)와 글자 그대로 맞춘다** — 어긋나면 크래시가 아니라 조용히 틀린다.
//   ⚠️ float 는 **맨 뒤** 둘이다(함정 33). ★ `dirSign` 은 **꼬리에 붙은 중립 기본값**(1.0)이다.
struct RopeParams
{
    uint  inOff, outOff, posOff, pad0;
    uint  rows, dim, mode, pad1;
    float theta, dirSign;
};
[[vk::push_constant]] RopeParams gP;

RWStructuredBuffer<float> gArena : register(u0);

[numthreads(16, 16, 1)]
void main(uint3 tid : SV_DispatchThreadID)
{
    const uint p = tid.x;   // 쌍 번호(빠른 축) — 채널 `2p`, `2p+1`
    const uint r = tid.y;   // 행(토큰×헤드 · 또는 패치)

    const uint pairs = gP.dim >> 1;
    if (p >= pairs || r >= gP.rows) return;   // ⚠️ 범위 검사는 커널의 몫

    // ① 축을 고른다 — 2D 면 앞 절반이 x, 뒤 절반이 y. ⚠️ **나누기 대신 비교**다(`dim < 4` 여도 0 나눗셈이 없다).
    const bool bTwoD = (gP.mode == 1u);
    const uint axisPairs = bTwoD ? (gP.dim >> 2) : pairs;      // 축 하나가 맡는 쌍 개수
    const uint axis      = (bTwoD && p >= axisPairs) ? 1u : 0u; // 0 = x, 1 = y
    const uint axisDim   = bTwoD ? (gP.dim >> 1) : gP.dim;      // 그 축의 채널 폭
    const uint pl        = p - axis * axisPairs;                // 축 안에서의 쌍 번호

    // ② 주파수 — `ω = theta^(−2·pl/axisDim)`. ★ `exp2·log2` 로 짓는다(CPU 와 같은 식).
    const float e = -2.0 * (float)pl / (float)axisDim;
    const float w = exp2(e * log2(gP.theta));

    // ③ 각 — 1D 는 `pos[r]`, 2D 는 `pos[r*2 + axis]`. ⚠️ pos 는 아레나에 **float 로 담긴 정수**다.
    const float pos = gArena[gP.posOff + (bTwoD ? (r * 2u + axis) : r)];
    const float ang = pos * w;

    // ④ 회전. ★ `dirSign` 이 `sin` 의 부호만 뒤집는다 ⇒ `-1` 이 곧 전치(= bwd).
    const float c = cos(ang);
    const float s = sin(ang) * gP.dirSign;

    const uint i0 = r * gP.dim + 2u * p, i1 = i0 + 1u;
    const float x0 = gArena[gP.inOff + i0];
    const float x1 = gArena[gP.inOff + i1];   // ★ 둘을 **먼저 읽는다** → 제자리 호출이 안전하다

    gArena[gP.outOff + i0] = x0 * c - x1 * s;
    gArena[gP.outOff + i1] = x0 * s + x1 * c;
}
