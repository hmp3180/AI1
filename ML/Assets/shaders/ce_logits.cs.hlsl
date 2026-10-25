// ce_logits.cs.hlsl — 🎯 **로짓에서 바로 교차엔트로피.** `probs = softmax(logits)` · `loss[r] = −log probs[r][target[r]]`
//
// ★ **왜 `softmax` + CPU 손실로 안 되나** — 여태 손실은 `probs` 를 회수해 CPU 가 적었다
//   (`MLCrossEntropyCpu`). 그것은 **손실이 곡선용 숫자 하나**일 때만 되는 이야기다. 이제 손실이
//   **행마다** 필요하다: ㉠ 표적이 없는 자리(패딩·아직 안 온 프레임)를 **행 단위로 빼야** 하고,
//   ㉡ 값·신뢰 채널이 **버킷 CE** 라 채널마다 손실을 갈라 봐야 하고(계약 §8.6: *값 예측도 이 커널을
//   쓴다* — 연속량 MSE 는 다봉을 평균으로 접는다), ㉢ 회수는 **다음 프레임**이라 "CPU 가 적는다" 는
//   길이 채널 수만큼의 왕복이 된다. ⇒ **행별 손실은 GPU 가 낸다.**
//
// ★ **표적은 「id 하나」다**(밀집 one-hot 이 아니다). `V = kVocab` 이 1000 을 넘으므로 one-hot 을
//   실체화하면 `R×V` 짜리 0 행렬을 쓰고 읽는 짓이 된다. id 는 `R` 개 float 이면 끝이고,
//   bwd 의 `− onehot` 도 **`v == t` 비교 한 번**으로 접힌다(⇒ `ce_logits_bwd`).
//
// ⚠️⚠️ **무효 표적을 「0 행으로 접지」 마라** — `embed`/`span_embed` 는 더러운 값을 0 으로 접는데,
//   CE 에서 그 관용구는 **조용히 틀린 학습**이다: 표적 없는 자리마다 *"정답은 0번 심볼"* 을 가르치게 된다.
//   ⇒ 규약은 **행을 빼는 것**이다: `target ≥ cols` 또는 `target == ignoreIdx` 또는 **음수** ⇒ `loss = 0`
//   (그리고 bwd 는 그 행의 `dLogits` 를 **전부 0** 으로 쓴다 — 같은 규약을 두 파일이 글자 그대로 공유한다).
//   ⚠️ `ignoreIdx` 를 **0 으로 두지 마라** — 0 은 멀쩡한 심볼 id 다. 끄려면 `0xFFFFFFFFu`.
//
// ★ **행 최댓값 빼기는 선택이 아니다** — `exp(z)` 는 `z ≈ 89` 에서 float32 를 넘겨 `inf` 가 되고
//   `inf/inf = NaN` 이 손실을 죽인다. 학습 초반 로짓은 작아서 **한참 뒤에** 터진다(원인과 안 닮은 자리에서).
//   ★ 그리고 이 뺄셈은 **손실을 정확히 바꾸지 않는다**(분자·분모에 같은 상수) ⇒ 공짜 안전장치이고,
//     **미분에도 불연속을 만들지 않는다**(그래서 이 커널의 gradcheck 에 「조건부」가 없다 — 동점에서
//     argmax 가 갈려도 `L` 은 글자 그대로 같은 값이다).
//
// ★ **`probs` 를 남긴다** — bwd 가 `probs − onehot` 을 쓰므로 다시 softmax 하지 않는다(fwd 와 정확히
//   같은 값을 봐야 하고, 다시 계산하면 순서·컴파일러 때문에 마지막 비트가 갈려 판정이 흐려진다).
//
// ★ **스레드 하나가 한 행**(`softmax.cs.hlsl` 과 같은 규약) — 행을 나누면 `max`·`Σexp` 에 리덕션이 필요하고
//   그 리덕션은 **누산 순서가 비결정적**이 된다. 판정이 CPU 레퍼런스와의 수치 일치라 결정성이 성능보다 값지다.
//   ⚠️ `cols` 가 수만이 되면 다시 볼 자리다(그때는 그룹 리덕션 + 고정 순서).
//
// ★ **출력이 둘인 예외**(`probs`·`loss`) — 계약 §3.2 의 예외 ㉢: **한 스레드(=한 행)가 두 출력 칸의
//   유일한 주인**이고 리덕션이 없다. `lossScale`(1/유효행수)은 여기 없다 — 그것은 **bwd 의 손잡이**다.
//
// ⚠️ 누산 순서는 `v` 오름차순 — CPU 레퍼런스(`MLCeLogitsCpu`)와 **같은 순서**여야 견줄 수 있다.

// ⚠️⚠️ **배치를 호스트(`MLCeLogitsParams`)와 글자 그대로 맞춘다** — 어긋나면 크래시가 아니라
//   **조용히 틀린 결과**다(relu 의 `count = 0` 사고). float 필드가 **없으므로** 꼬리는 `pad0` 다.
struct CeLogitsParams
{
    uint  logitsOff, targetOff, probsOff, lossOff;
    uint  rows, cols, ignoreIdx, pad0;
};
[[vk::push_constant]] CeLogitsParams gP;

RWStructuredBuffer<float> gArena : register(u0);

[numthreads(64, 1, 1)]
void main(uint3 tid : SV_DispatchThreadID)
{
    const uint r = tid.x;
    if (r >= gP.rows) return;          // ⚠️ 범위 검사는 커널의 몫

    const uint base = r * gP.cols;

    // ① 행 최댓값 — ⚠️ 온도가 없다(이 커널은 로짓을 그대로 본다. 온도가 필요하면 `softmax` 쪽이다).
    float mx = gArena[gP.logitsOff + base];
    for (uint v = 1; v < gP.cols; ++v)
    {
        const float z = gArena[gP.logitsOff + base + v];
        if (z > mx) mx = z;
    }

    // ② exp 합 — ⚠️ 지수를 **쓰면서** 더한다(두 번 계산하지 않는다).
    float sum = 0.0;
    for (uint v2 = 0; v2 < gP.cols; ++v2)
    {
        const float e = exp(gArena[gP.logitsOff + base + v2] - mx);
        gArena[gP.probsOff + base + v2] = e;
        sum += e;
    }

    // ③ 정규화. ⚠️ `sum` 은 최소 1 이다(최댓값 항이 `exp(0)=1`) → 0 나눗셈이 원리적으로 없다.
    const float inv = 1.0 / sum;
    for (uint v3 = 0; v3 < gP.cols; ++v3)
        gArena[gP.probsOff + base + v3] *= inv;

    // ④ 표적 판정 — ⚠️ **무효 행은 손실 0**(0 행으로 접지 않는다. 머리말의 그 이유).
    //   ⚠️ 음수를 먼저 `float` 로 걸러낸다 — 음수 float 의 `(uint)` 캐스트는 정의가 갈려서
    //     GPU 와 CPU 레퍼런스가 **다른 값**을 볼 수 있다(그러면 판정이 못 믿을 것이 된다).
    const float tf = gArena[gP.targetOff + r];
    const uint  t  = (uint)tf;
    if (tf < 0.0 || t >= gP.cols || t == gP.ignoreIdx)
    {
        gArena[gP.lossOff + r] = 0.0;
        return;                        // ★ `probs` 는 이미 썼다 — softmax 자체는 유효하다(bwd 가 0 으로 지운다)
    }

    // ⑤ `−log p[target]`. ⚠️ 바닥을 깐다 — `p` 가 float 아래로 깎이면 `-inf` 가 되어 곡선이 통째로 못 읽힌다.
    float p = gArena[gP.probsOff + base + t];
    if (p < 1.0e-30) p = 1.0e-30;
    gArena[gP.lossOff + r] = -log(p);
}
