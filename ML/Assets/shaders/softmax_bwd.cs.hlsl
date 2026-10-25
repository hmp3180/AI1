// softmax_bwd.cs.hlsl — 🔢◀ **softmax 의 기울기.**
//   `dIn[r][i] = scale · p[r][i] · ( dOut[r][i] − Σ_j p[r][j]·dOut[r][j] )`
//
// ★ **왜 이 커널이 지금까지 없었나 — 그리고 왜 지금 필요한가.**
//   여태 softmax 는 **늘 손실 바로 앞**에 있었고, `softmax + 교차엔트로피` 의 기울기는 유명하게
//   **`probs − onehot`** 으로 접힌다(야코비안이 통째로 사라진다) ⇒ `sub` 커널 하나로 끝났다.
//   ⚠️ 그런데 **어텐션의 softmax 는 손실 앞이 아니라 망 안쪽**이다 — 뒤에서 오는 `dOut` 이 임의의
//     값이라 접히지 않는다. ⇒ **야코비안을 실제로 써야 하는 첫 자리**다.
//
// ★ **야코비안을 행렬로 만들지 않는다.** `∂p_i/∂z_j = p_i(δ_ij − p_j)` 를 그대로 곱하면
//   행마다 `cols×cols` 짜리 행렬이 생기는데(여기서는 64×64 = 4096) 그것을 만들 필요가 없다:
//     `Σ_j p_i(δ_ij − p_j) dOut_j = p_i·(dOut_i − Σ_j p_j·dOut_j)`
//   ⇒ **행마다 내적 하나**(`dot = Σ p·dOut`)면 끝이다. 비용이 `O(cols)` 이고 메모리가 0 이다.
//
// ★ **`scale` 은 온도의 역전파다.** forward 가 `softmax(S · scale)` 였으므로 사슬규칙이
//   여기서 같은 `scale` 을 한 번 더 곱한다. ⚠️ **한쪽만 넣으면 기울기가 `1/√D` 배 틀린다** —
//   증상이 "학습이 느리다" 라서 버그로 안 읽힌다. ⇒ forward/backward 가 **같은 값을 받는다**.
//
// ★ **활성 후 값(`p`)을 읽는다** — ReLU 와 반대다(그쪽은 활성 **전**). softmax 의 미분은 출력만으로
//   써지므로 입력을 보관할 이유가 없다. ⚠️ 그래서 `p` 를 제자리로 덮으면 안 된다(호스트가 지킨다).
//
// ★ **스레드 하나가 한 행**을 맡는다 — `softmax.cs.hlsl` 과 같은 규약이다(리덕션이 없어 결정적).

// ⚠️⚠️ **호스트(`MLSoftmaxBwdParams`)와 글자 그대로 같은 배치다** — 함정 33 을 밟은 자리다.
//   `{ probOff, dOutOff, dInOff, rows, cols, scale }` — 마지막이 **`float`** 다.
struct SoftmaxBwdParams
{
    uint  probOff, dOutOff, dInOff;
    uint  rows, cols;
    float scale;
};
[[vk::push_constant]] SoftmaxBwdParams gP;

RWStructuredBuffer<float> gArena : register(u0);

[numthreads(64, 1, 1)]
void main(uint3 tid : SV_DispatchThreadID)
{
    const uint r = tid.x;
    if (r >= gP.rows) return;

    const uint base = r * gP.cols;

    // ① 행 내적 `dot = Σ_j p_j · dOut_j` — ⚠️ `j` 오름차순(CPU 레퍼런스와 같은 순서여야 견줄 수 있다).
    float dot = 0.0;
    for (uint j = 0; j < gP.cols; ++j)
        dot += gArena[gP.probOff + base + j] * gArena[gP.dOutOff + base + j];

    // ② `dIn_i = scale · p_i · (dOut_i − dot)`
    for (uint i = 0; i < gP.cols; ++i)
    {
        const float p = gArena[gP.probOff + base + i];
        const float d = gArena[gP.dOutOff + base + i];
        gArena[gP.dInOff + base + i] = gP.scale * p * (d - dot);
    }
}
