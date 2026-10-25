// swiglu.cs.hlsl — 🚪 **게이트 하나.** `y = silu(a) ⊙ b`, `silu(z) = z·σ(z)`, `σ(z) = 1/(1+exp(-z))`
//
// ★ **왜 이 커널이 필요한가** — 기존 원소별 커널로는 안 된다. `relu` 는 입력이 **하나**이고
//   `sub` 는 뺄셈이다. SwiGLU 의 원소 부분은 **입력 둘(게이트 `a` · 값 `b`)이 한 자리에서 곱해지는**
//   모양이라 두 커널을 이어 붙여도 중간 텐서(`silu(a)`)를 위한 자리와 디스패치가 하나 더 든다.
//   ⚠️ 그리고 그 중간 텐서는 bwd 가 **쓰지 않는다**(bwd 는 활성 전 `a` 를 본다) ⇒ 순전히 낭비다.
//
// ★ **`x·W1`/`x·W3` 는 여기 없다 — 그건 `gemm` 이다.** 이 커널은 **원소 부분만** 맡는다.
//   그래서 입력이 **두 텐서**다(하나로 이어 붙이지 않는다 — `gemm` 에 간격 인자가 없으므로
//   `x·[W1|W3]` 한 방으로 굽고 반씩 잘라 쓰는 길이 애초에 막혀 있다).
//   ⚠️ 뒤의 `·Wd`(내림 투사)도 `gemm` 이다. 여기에 섞지 마라.
//
// ★ **`σ` 는 `1.0/(1.0+exp(-z))` 한 가지 식으로 못 박는다** — `0.5·(1+tanh(z/2))` 같은 동등한
//   항등식으로 쓰면 CPU 레퍼런스(`MLSwigluCpu`)와 **마지막 비트가 갈린다**. ⚠️ 초월함수가 끼므로
//   판정 임계는 1e-5 다(오차 0 을 요구하지 않는다 — `relu` 와 다른 자리).
//
// ⚠️ 원소별이라 누산이 없다 — 훑는 순서 논쟁도, 쓰기 충돌도 없다. `i` 하나가 자기 칸만 쓴다.

// ⚠️⚠️ **배치를 호스트(`MLSwigluParams`)와 글자 그대로 맞춘다** — `{ aOff, bOff, outOff, count }`.
//   어긋나면 크래시가 아니라 **조용히 틀린 결과**다(relu 의 `count = 0` 사고 · 모든 축 이득 정확히 +0.00).
//   ★ float 필드가 하나도 없다(손잡이가 없는 커널이다) ⇒ 함정 33 이 아예 안 생긴다.
struct SwigluParams
{
    uint aOff, bOff, outOff, count;   // 아레나 안 **float 인덱스**(바이트가 아니다) · `count = rows·H`
};
[[vk::push_constant]] SwigluParams gP;

RWStructuredBuffer<float> gArena : register(u0);

[numthreads(256, 1, 1)]
void main(uint3 tid : SV_DispatchThreadID)
{
    const uint i = tid.x;
    if (i >= gP.count) return;          // ⚠️ 범위 검사는 커널의 몫

    const float a = gArena[gP.aOff + i];        // 게이트(활성 전)
    const float b = gArena[gP.bOff + i];        // 값
    const float s = 1.0 / (1.0 + exp(-a));      // ⚠️ 이 식 하나 — CPU 레퍼런스와 같은 자리

    gArena[gP.outOff + i] = (a * s) * b;        // silu(a) ⊙ b
}
