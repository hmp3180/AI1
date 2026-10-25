// swiglu_bwd.cs.hlsl — 🚪◀ **게이트의 기울기.** `dB = dY·(a·s)` · `dA = dY·b·s·(1 + a·(1−s))`, `s = σ(a)`
//
// ★ **왜 출력이 둘인가 — 「한 스레드가 두 출력 칸의 유일한 주인」 예외다.**
//   원소별이라 스레드 `i` 가 `dA[i]`·`dB[i]` **둘 다의 유일한 필자**이고 **리덕션이 끼지 않는다**
//   ⇒ 커널을 가르면 `a`·`b`·`dY` 세 텐서를 **두 번 읽는다**(디스패치도 둘). 예외를 쓸 자리가 맞다.
//   ⚠️ 리덕션이 끼는 자리에서는 이 예외를 쓰지 마라 — 그때는 커널을 가른다.
//
// ★ **활성 전 값 `a` 를 읽는다 — `silu(a)` 를 저장해 두고 재사용하지 않는다.**
//   `silu` 는 단조가 아니라(`a ≈ −1.278` 아래로 다시 올라간다) **활성 후 값에서 `a` 를 되찾을 수 없다**
//   ⇒ `relu_bwd` 와 **같은 규약**(활성 전을 본다)이고, 그래서 fwd 가 중간 텐서를 남길 이유도 없다.
//   ★ `s` 는 여기서 **다시 계산한다** — fwd 와 같은 한 가지 식(`1/(1+exp(-a))`)을 쓰므로 같은 값이 나오고,
//     `rmsnorm` 의 `rstd` 처럼 아레나에 남길 이유가 없다(그쪽은 리덕션 결과라 순서가 걸려 있었다).
//
// ★ **`dA` 의 식을 곱셈으로 접는다** — `silu'(a) = s + a·s·(1−s) = s·(1 + a·(1−s))`.
//   ⚠️ 두 항으로 펼쳐 쓰면 부동소수 결과가 CPU 레퍼런스와 **마지막 비트에서 갈린다** ⇒ 접은 이 모양을
//     `MLSwigluBwdCpu` 와 **글자 그대로** 같게 둔다(연산 순서까지).
//
// ⚠️ 원소별이라 gather/scatter 논쟁이 없다 — 자기 칸에 `=` 로 쓴다(더하지 않는다).

// ⚠️⚠️ **배치를 호스트(`MLSwigluBwdParams`)와 글자 그대로 맞춘다** — `{ aOff, bOff, dOutOff, dAOff, dBOff, count }`.
//   ★ 새 필드는 **꼬리에만** 붙인다(앞에 끼우면 조용히 밀린다) · float 손잡이는 없다.
struct SwigluBwdParams
{
    uint aOff, bOff, dOutOff, dAOff;
    uint dBOff, count;                // `count = rows·H`
};
[[vk::push_constant]] SwigluBwdParams gP;

RWStructuredBuffer<float> gArena : register(u0);

[numthreads(256, 1, 1)]
void main(uint3 tid : SV_DispatchThreadID)
{
    const uint i = tid.x;
    if (i >= gP.count) return;          // ⚠️ 범위 검사는 커널의 몫

    const float a  = gArena[gP.aOff + i];       // ⚠️ 활성 **전** 게이트
    const float b  = gArena[gP.bOff + i];
    const float dy = gArena[gP.dOutOff + i];
    const float s  = 1.0 / (1.0 + exp(-a));     // ⚠️ fwd 와 **같은 식**

    // ① 값 쪽: `∂y/∂b = silu(a) = a·s`
    gArena[gP.dBOff + i] = dy * (a * s);

    // ② 게이트 쪽: `∂y/∂a = b · silu'(a)`, `silu'(a) = s·(1 + a·(1−s))` — ⚠️ 접은 이 모양 그대로.
    gArena[gP.dAOff + i] = dy * b * (s * (1.0 + a * (1.0 - s)));
}
