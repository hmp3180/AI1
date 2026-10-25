// val_enc.cs.hlsl — 🎚️ **값 하나를 다주파 사인으로 펼친다.** `Φ[r][2f] = sin(ω_f·u)` · `Φ[r][2f+1] = cos(ω_f·u)`, `u = (v − vBias)·vScale`
//
// ★ **왜 이 커널이 필요한가** — 기존 커널로는 **안 된다.** `embed`/`span_embed` 계열은 전부
//   **이산 색인 → 표 조회**이고, 여기 들어오는 것은 **연속값**이다. 연속량을 이산 버킷으로 접어 표를
//   조회하면 **버킷 경계에서 거짓 불연속**이 생긴다(MLT.md 「값 입력」 표가 그것을 `⛔` 로 못 박았다).
//   `gemm` 도 아니다 — 필요한 것은 선형사상이 아니라 **주파수 사다리**이고, `sin`/`cos` 를 원소별로
//   내는 커널이 저장소에 하나도 없다. ⇒ 새 파일이 맞다.
//   ★ 그리고 `W_val` 은 **여기 없다** — `Φ` 뒤의 `gemm` 이다(그 기울기는 `gemm(transA=1)`).
//
// ★ **주파수 집합과 정규화 계수를 「상수 인자」로 받는다**(MLT.md 「커널 — 새로 만들 것은 적다」의
//   `val_enc: 주파수 집합·정규화 계수를 인자화`). ⚠️ 상수로 박으면 분해능(= 주파수 수 `F`)이 **손잡이가
//   아니게** 되고, 러닝 통계인 `vBias`/`vScale` 을 갱신할 길이 없어진다.
//   ⚠️⚠️ `vBias`/`vScale` 은 **미분 경로가 아니다** — 러닝 통계(EMA)다. 그래서 bwd 는 `dV` 만 내고
//   gradcheck 는 **「계수 고정 조건부」**로 잰다(`act_topk` 의 「선택 고정」과 같은 관용구).
//
// ★ **스레드 하나가 `(주파수 f, 행 r)` 를 맡아 `sin`/`cos` 두 칸을 함께 쓴다** — 그 두 칸의 **주인이
//   이 스레드뿐**이므로 출력 둘의 예외가 허용된다(리덕션이 없다). 갈라 두면 `ω_f·u` 를 두 번 계산하게
//   되고 그 두 값이 **정확히 같다는 보장이 없다**(컴파일러가 달리 접을 수 있다) ⇒ `sin`/`cos` 가
//   서로 다른 위상에서 나오는 조용한 버그.
//
// ★ **주파수 사다리를 `pow` 가 아니라 `exp2(log2(ratio)·t)` 로 짓는다** — GPU 의 `pow` 는
//   `exp2(y·log2(x))` 로 풀리는데 CPU 의 `powf` 는 더 정밀하게 계산한다 ⇒ **같은 식이 아니게 되어**
//   `ω_f` 가 갈린다. `PEMath.h` 가 `Log2`/`Exp2` 짝을 먼저 둔 이유가 정확히 이것이다
//   (*"셰이더와 같은 식을 쓰려면 CPU 도 그것으로 계산해야 값이 정확히 맞는다"*).
//   ⚠️⚠️ 그래도 마지막 비트는 갈릴 수 있고 그 오차는 **위상에서 `ω` 배로 증폭**된다
//   (`ω=1000`·`|u|=1` 이면 상대오차 1e-7 이 `sin` 에서 1e-4 로 보인다). ⇒ **판정 ①(GPU vs CPU)은
//   `freqMax·|u|` 가 작은 판에서 걸어라.** 큰 `freqMax` 에서 판정이 흔들리면 그것은 커널 버그가 아니다.
//
// ⚠️ `freqs == 1` 이면 `t` 의 분모가 0 이다 ⇒ 그때는 `ω = freqMin` 이다(fwd·bwd·CPU 셋 다 같은 규약).
// ⚠️ 호출부가 `freqMin > 0` 을 보장한다 — 셰이더에는 로그가 없어 0 이면 `log2(0) = -inf` 가 조용히 번진다.
// ⚠️ 누산은 없지만 출력 자리 규약이 `f` 오름차순 = `(sin, cos)` 쌍이다 — CPU 레퍼런스(`MLValEncCpu`)와
//   같은 배치여야 뒤의 `gemm`(`W_val`)이 같은 열을 본다.

// ⚠️⚠️ **배치를 호스트(`MLValEncParams`)와 글자 그대로 맞춘다** — 어긋나면 크래시가 아니라
//   **조용히 틀린 결과**다(relu 의 `count = 0` 사고). float 넷은 **맨 뒤**다(함정 33).
struct ValEncParams
{
    uint  inOff, outOff, rows, freqs;      // 아레나 안 **float 인덱스**(바이트가 아니다)
    float vBias, vScale, freqMin, freqMax; // ⚠️ vBias/vScale = 러닝 통계(비미분) · 주파수 = 등록된 집합
};
[[vk::push_constant]] ValEncParams gP;

RWStructuredBuffer<float> gArena : register(u0);

[numthreads(16, 16, 1)]
void main(uint3 tid : SV_DispatchThreadID)
{
    const uint f = tid.x;   // 주파수 번호(빠른 축)
    const uint r = tid.y;   // 행(토큰/슬롯)
    if (f >= gP.freqs || r >= gP.rows) return;   // ⚠️ 범위 검사는 커널의 몫

    // ① 정규화 — ⚠️ 계수는 **인자**다. 여기서 통계를 갱신하지 않는다(그것은 호스트의 일).
    const float u = (gArena[gP.inOff + r] - gP.vBias) * gP.vScale;

    // ② 주파수 — 기하 사다리. ⚠️ `freqs == 1` 이면 분모가 0 이므로 `freqMin` 을 쓴다.
    //    ⚠️ `pow` 를 쓰지 마라(머리말 ★) — CPU 와 식이 갈린다.
    float w = gP.freqMin;
    if (gP.freqs > 1u)
    {
        const float t = (float)f / (float)(gP.freqs - 1u);
        w = gP.freqMin * exp2(log2(gP.freqMax / gP.freqMin) * t);
    }

    // ③ 두 칸을 함께 쓴다 — ★ 이 스레드가 그 둘의 유일한 주인이다(위상을 두 번 계산하지 않는다).
    const float ph = w * u;
    const uint  o  = gP.outOff + r * (gP.freqs * 2u) + f * 2u;
    gArena[o]      = sin(ph);
    gArena[o + 1u] = cos(ph);
}
