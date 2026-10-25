// ce_logits_bwd.cs.hlsl — 🎯◀ **CE+softmax 의 기울기.** `dLogits[r][v] = ( probs[r][v] − [v == target[r]] ) · lossScale`
//
// ★ **야코비안이 통째로 사라진다** — softmax 뒤에 바로 CE 가 오면 `∂L/∂z = p − onehot` 으로 접힌다.
//   그래서 이 커널은 `softmax_bwd`(야코비안을 실제로 쓰는 판)와 **다른 물건**이다. 뒤에서 오는 `dOut` 을
//   받지 않고 **`probs` 와 `target` 만** 본다. ⚠️ 그러므로 이 둘을 **직렬로 걸지 마라** —
//   `softmax → softmax_bwd` 로 흉내내면 사라져야 할 항을 두 번 곱한다.
//
// ★ **왜 `sub` 커널로 안 되나** — 예전 배관은 `sub(probs, onehot)` 이었고 그것은 **`R×V` 짜리 one-hot
//   텐서를 실체화**해야 한다(`V = kVocab` 이 1000 을 넘는다 ⇒ 거의 전부 0 인 행렬을 쓰고 또 읽는다).
//   여기서는 `v == t` **비교 한 번**이 그 텐서를 대신한다. 게다가 `sub` 는 **행을 뺄 줄 모른다**(아래 ⚠️).
//
// ⚠️⚠️ **무효 행에는 0 을 「쓴다」 — 건너뛰지 마라.** 아레나는 재사용되므로 `return` 으로 빠지면
//   그 자리에 **지난 스텝의 기울기**가 그대로 남아 옵티마이저가 그것을 먹는다(크래시 없이 조용히 틀린다).
//   ⇒ 규약은 fwd(`ce_logits`)와 글자 그대로 같다: `target ≥ cols` · `target == ignoreIdx` · **음수** ⇒ 그 행 전부 0.
//   ⚠️ `ignoreIdx` 를 0 으로 두지 마라 — 0 은 멀쩡한 심볼 id 다. 끄려면 `0xFFFFFFFFu`.
//
// ★ **`lossScale` 은 호스트가 계산해 넘긴다**(보통 `1/유효행수`) — 커널은 **행을 세지 않는다**.
//   ⚠️ 세게 하려면 리덕션이 필요하고(§4 가 금지한 자리), 무엇보다 "유효행" 의 정의는 **채널마다 다르다**
//   (값·신뢰·활성이 각자 다른 마스크를 쓴다). 그것은 배관의 판단이지 커널의 판단이 아니다.
//   ⚠️⚠️ fwd 의 `loss[r]` 합에는 이 배율이 **안 들어있다** — 손실 곡선을 찍을 때 호스트가 같은 배율로
//     나눠야 기울기와 **같은 목적함수**를 보는 것이 된다(안 맞추면 "손실은 안 주는데 학습은 된다").
//
// ★ **스레드 하나가 출력 칸 하나의 유일한 주인**이다 ⇒ `=` 로 쓴다(누적하지 않는다).
//   atomic·`groupshared`·0 초기화 디스패치가 **하나도 필요 없다** — 그것이 이 모양을 고른 이유다.
//
// ⚠️ 2D 축 배정은 저장소 고정 규약: **`tid.x` = 어휘(빠른 축)** · **`tid.y` = 행**. `Dispatch(cols, rows, 1)`.

// ⚠️⚠️ **배치를 호스트(`MLCeLogitsBwdParams`)와 글자 그대로 맞춘다** — float 는 **맨 뒤**(함정 33).
//   남는 칸은 지우지 않고 `pad0`/`pad1` 로 남긴다.
struct CeLogitsBwdParams
{
    uint  probsOff, targetOff, dLogitsOff, pad0;
    uint  rows, cols, ignoreIdx, pad1;
    float lossScale;
};
[[vk::push_constant]] CeLogitsBwdParams gP;

RWStructuredBuffer<float> gArena : register(u0);

[numthreads(16, 16, 1)]
void main(uint3 tid : SV_DispatchThreadID)
{
    const uint v = tid.x;   // 어휘(빠른 축)
    const uint r = tid.y;   // 행
    if (v >= gP.cols || r >= gP.rows) return;   // ⚠️ 범위 검사는 커널의 몫

    const uint idx = r * gP.cols + v;

    // ① 표적 판정 — ⚠️ fwd(`ce_logits`)와 **같은 규약·같은 순서**여야 한다(음수 검사까지).
    const float tf = gArena[gP.targetOff + r];
    const uint  t  = (uint)tf;
    if (tf < 0.0 || t >= gP.cols || t == gP.ignoreIdx)
    {
        gArena[gP.dLogitsOff + idx] = 0.0;      // ⚠️⚠️ **쓴다**(건너뛰면 지난 값이 남는다)
        return;
    }

    // ② `p − onehot` 에 배율. ★ one-hot 텐서 없이 비교 한 번으로 접는다.
    const float oneHot = (v == t) ? 1.0 : 0.0;
    gArena[gP.dLogitsOff + idx] = (gArena[gP.probsOff + idx] - oneHot) * gP.lossScale;
}
