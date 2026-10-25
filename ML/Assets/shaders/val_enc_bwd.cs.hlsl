// val_enc_bwd.cs.hlsl — 🎚️◀ **펼친 것을 스칼라로 되돌린다.** `dV[r] = vScale · Σ_f ω_f·( dΦ[2f]·cos(ω_f u) − dΦ[2f+1]·sin(ω_f u) )`
//
// ★ **왜 이 커널이 필요한가** — 기존 커널로 **안 된다.** 이것은 `2F → 1` 의 **행 감산**이고
//   가중치가 `ω_f·cos`/`−ω_f·sin` 이라 **입력 `v` 에 의존**한다 ⇒ `gemm` 으로 접을 수 없다
//   (행렬이 행마다 다르다). `softmax_bwd` 도 아니다(그것은 야코비안이 `p` 인 정사각 꼴이다).
//
// ★ **`dvBias`/`dvScale` 을 내지 않는다** — 그 둘은 학습 파라미터가 아니라 **러닝 통계**(EMA)다.
//   ⚠️⚠️ 그래서 gradcheck 는 **「계수 고정 조건부」**로 잰다 — ±ε 로 `v` 를 흔들 때 `vBias`/`vScale` 을
//   **다시 계산하지 않는다.** 이것을 로그에 안 적으면 다음 사람이 *"gradcheck 를 못 통과한다"* 로
//   오진한다(MLT.md 가 이 오진을 미리 등록해 둔 자리다).
//   ★ 반대로 `vScale` 은 **사슬규칙의 인자로는 반드시 들어간다**(`∂u/∂v = vScale`) — 빼먹으면 기울기가
//   `vScale` 배 틀리고 증상이 *"학습이 느리다"* 라서 버그로 안 읽힌다.
//
// ★ **스레드 하나가 한 행(= 값 하나)을 맡는다**(`softmax`·`rmsnorm` 과 같은 관용구) — 주파수를 나누면
//   합에 리덕션이 필요하고 그 리덕션은 **누산 순서가 비결정적**이 된다. 판정이 CPU 레퍼런스와의 수치
//   일치라 결정성이 성능보다 값지다. `F` 는 십 단위라 한 스레드로 충분하다.
//
// ★ **주파수 사다리를 fwd 와 글자 그대로 같은 세 줄로 짓는다**(`exp2(log2(ratio)·t)` · `freqs==1` → `freqMin`).
//   ⚠️⚠️ 한쪽만 `pow` 로 쓰거나 `freqs==1` 규약이 갈리면 **기울기가 엉뚱한 주파수에 실린다** — 증상은
//   크래시가 아니라 *"값 채널이 잘 안 배운다"* 다.
//
// ⚠️ 누산 순서는 `f` 오름차순 — CPU 레퍼런스(`MLValEncBwdCpu`)와 **같은 순서**여야 견줄 수 있다.
// ⚠️ `vScale` 은 합 **밖에서** 한 번 곱한다(합 안에서 항마다 곱하면 부동소수 마지막 비트가 갈린다).
// ⚠️ `dΦ` 의 배치는 fwd 와 같은 `(sin, cos)` 쌍이다 — 행 길이가 `2F` 다.

// ⚠️⚠️ **배치를 호스트(`MLValEncBwdParams`)와 글자 그대로 맞춘다.** float 넷은 **맨 뒤**(함정 33)이고
//   `pad0` 은 **지우지 않는다**(남는 칸은 명시로 남긴다).
struct ValEncBwdParams
{
    uint  inOff, dOutOff, dInOff, pad0;    // in = v(rows×1) · dOut = dΦ(rows×2F) · dIn = dV(rows×1)
    uint  rows, freqs;
    float vBias, vScale, freqMin, freqMax; // ⚠️ fwd 와 **같은 값**을 받는다(다르면 위상이 갈린다)
};
[[vk::push_constant]] ValEncBwdParams gP;

RWStructuredBuffer<float> gArena : register(u0);

[numthreads(64, 1, 1)]
void main(uint3 tid : SV_DispatchThreadID)
{
    const uint r = tid.x;
    if (r >= gP.rows) return;              // ⚠️ 범위 검사는 커널의 몫

    // ① 정규화 — fwd 와 **같은 식**(계수도 같은 값이어야 한다).
    const float u    = (gArena[gP.inOff + r] - gP.vBias) * gP.vScale;
    const uint  base = r * (gP.freqs * 2u);

    // ② 주파수 사다리의 비(比)를 한 번만 잰다 — ⚠️ fwd 의 그 식과 글자 그대로 같아야 한다.
    const float lg = (gP.freqs > 1u) ? log2(gP.freqMax / gP.freqMin) : 0.0;

    // ③ `f` 오름차순으로 훑어 스칼라를 만든다.
    float acc = 0.0;
    for (uint f = 0; f < gP.freqs; ++f)
    {
        float w = gP.freqMin;
        if (gP.freqs > 1u)
            w = gP.freqMin * exp2(lg * ((float)f / (float)(gP.freqs - 1u)));

        const float ph = w * u;
        // ∂sin(ω u)/∂u = ω·cos · ∂cos(ω u)/∂u = −ω·sin
        acc += w * (gArena[gP.dOutOff + base + f * 2u] * cos(ph)
                  - gArena[gP.dOutOff + base + f * 2u + 1u] * sin(ph));
    }

    // ④ `∂u/∂v = vScale` — ★ 합 **밖에서** 한 번 곱한다. **쓴다**(더하지 않는다 — 이 칸의 주인이 이 스레드뿐).
    gArena[gP.dInOff + r] = gP.vScale * acc;
}
