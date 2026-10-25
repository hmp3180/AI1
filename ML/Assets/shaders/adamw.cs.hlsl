// adamw.cs.hlsl — ⚙️ **AdamW 파라미터 갱신.** 원소별이므로 모양을 모르고 `count` 만 안다.
//
//   m = β₁·m + (1−β₁)·g
//   v = β₂·v + (1−β₂)·g²
//   p = p − lr·(m·bc1) / (√(v·bc2) + ε) − lr·wd·p
//
// ★ **AdamW 는 Adam 과 감쇠(weight decay)의 자리가 다르다** — Adam(+L2)은 감쇠를 **기울기에** 섞고,
//   AdamW 는 **갱신에서 따로 뺀다**(decoupled). 그래서 감쇠가 적응적 스케일(√v)에 나눠지지 않는다.
//   ⚠️ 이것을 헷갈려 `g += wd·p` 로 짜면 **돌아가긴 하는데 AdamW 가 아니다**(그리고 증상이 "정규화가
//     약하다" 라서 버그로 안 읽힌다).
//
// ★ **편향보정을 호스트가 미리 계산해 넘긴다**(`bc1 = 1/(1−β₁ᵗ)`, `bc2 = 1/(1−β₂ᵗ)`).
//   ⇒ 셰이더가 `pow` 를 부르지 않고 스텝 수 `t` 를 알 필요도 없다. **스텝을 세는 것은 호스트의 일**이고
//     커널은 "이번에 이만큼 보정하라" 만 받는다(같은 사실이 두 곳에 살지 않는다).
//
// ⚠️ 이 커널은 **네 텐서를 동시에 만진다**(p 읽고 쓰기 · g 읽기 · m/v 읽고 쓰기) — 전부 같은 아레나의
//   다른 오프셋이다. 겹치는 오프셋을 주면 조용히 틀리므로 **할당은 호스트가 갈라서** 한다.

struct AdamWParams
{
    uint  pOff, gOff, mOff, vOff, count;
    float lr, beta1, beta2, eps, wd;
    float bc1, bc2;          // 1/(1−β₁ᵗ) · 1/(1−β₂ᵗ) — 호스트가 계산한다
};
[[vk::push_constant]] AdamWParams gP;

RWStructuredBuffer<float> gArena : register(u0);

[numthreads(256, 1, 1)]
void main(uint3 tid : SV_DispatchThreadID)
{
    const uint i = tid.x;
    if (i >= gP.count) return;   // ⚠️ 범위 검사는 커널의 몫

    const float g = gArena[gP.gOff + i];
    float p = gArena[gP.pOff + i];

    const float m = gP.beta1 * gArena[gP.mOff + i] + (1.0 - gP.beta1) * g;
    const float v = gP.beta2 * gArena[gP.vOff + i] + (1.0 - gP.beta2) * g * g;
    gArena[gP.mOff + i] = m;
    gArena[gP.vOff + i] = v;

    const float mhat = m * gP.bc1;
    const float vhat = v * gP.bc2;
    // ★ 적응 항과 **감쇠 항이 따로다**(AdamW 의 정의) — 감쇠를 √v 로 나누지 않는다.
    p -= gP.lr * (mhat / (sqrt(vhat) + gP.eps));
    p -= gP.lr * gP.wd * p;

    gArena[gP.pOff + i] = p;
}
