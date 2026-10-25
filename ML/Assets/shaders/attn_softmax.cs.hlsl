// attn_softmax.cs.hlsl — 👁️ **인과 마스크가 달린 행 softmax.** `Pr[r][j] = exp(S·scale − max) / Σ`, 단 `j > r + causalOff` 는 **정확히 0**
//
// ★ **왜 이 커널이 필요한가 — 기존 `softmax` 로 안 되는 이유는 마스크 하나다.**
//   어텐션의 `S = Q·Kᵀ` 는 `gemm(transB=1)` 이고 `O = Pr·V` 도 `gemm` 이다. 온도 `1/√Dh` 도 이미
//   `softmax` 의 `scale` 칸이 받는다. **남은 것은 「행 r 은 j ≤ r + causalOff 만 본다」뿐**이고,
//   그것이 기존 커널로 안 되는 유일한 자리라 새 파일은 **이것 하나**다.
//   ⚠️ 그래서 `attn.cs.hlsl`(융합) 도 `attn_bwd.cs.hlsl` 도 **만들지 않는다** — 아래 두 문단이 근거다.
//
// ★ **융합하지 않는다(QKᵗ·마스크·softmax·AV 를 한 커널로 묶지 않는다).** 이유가 셋이다:
//   ㉠ **`Pr`(T×T) 는 어차피 저장해야 한다** — bwd 가 `dPr = dO·Vᵀ` 와 `dS = softmax_bwd(Pr, dPr)` 로
//      그것을 다시 읽는다. ⇒ 융합해도 **아끼는 메모리가 0** 이다(flash-attention 이 얻는 이득이 여기서는
//      학습 그래프 때문에 사라진다).
//   ㉡ **융합은 온라인 softmax 재스케일**을 부른다(부분합을 보면서 최댓값이 바뀔 때마다 누산을 고친다)
//      ⇒ **누산 순서가 CPU 레퍼런스와 갈린다.** 이 트랙의 판정은 「CPU 와의 수치 일치」라 그 순간
//      판정 도구를 잃는다. ⚠️ 그리고 그 오차는 학습이 되는 것처럼 보이면서 조용히 남는다.
//   ㉢ `gemm` 은 이미 `transA`/`transB`/`beta` 로 fwd 6개·bwd 4개 자리를 다 덮는다. 융합 커널은
//      그 루프를 **복제**하는 것이고, 복제된 쪽이 나중에 갈린다(금지 목록의 「되면 만들지 마라」).
//
// ★ **bwd 는 새 커널이 아니다 — 기존 `softmax_bwd` 를 그대로 쓴다.**
//   근거: 마스크 칸은 `p = 0` 이므로 ㉠ 행 내적 `dot = Σ_j p_j·dOut_j` 에 **기여가 0** 이고
//   ㉡ `dIn_i = scale·p_i·(dOut_i − dot)` 도 `p_i = 0` 이라 **정확히 0** 이 나온다.
//   ⇒ 마스크를 아는 bwd 커널이 원리적으로 필요 없다. ⚠️ **단 전제가 「마스크 칸이 정확히 0」**이다 —
//     그것이 아래 ③ 의 `0.0` 대입이 성능이 아니라 **정확성**인 이유다.
//
// ★ **`Dh`(헤드 차원)는 이 커널의 상수가 아니다.** 이 커널은 `S`(T×T)만 만진다 —
//   `Dh` 는 ㉠ 호스트가 계산한 `scale = 1/√Dh` 로 접혀 들어오고 ㉡ `gemm` 의 논리 크기 `N`/`K` 로 들어간다.
//   여기에 `dHead` 필드를 두면 **쓰지 않는 값이 계약에 남아** 다음 사람이 헤드마다 무언가 하는 커널로 읽는다.
//   ⚠️⚠️ `scale` 은 **fwd(이 커널)와 bwd(`softmax_bwd`)에 같은 값**을 준다 — 한쪽만 주면 기울기가
//     `1/√Dh` 배 틀리고 증상이 *"학습이 느리다"* 라서 **버그로 안 읽힌다**.
//
// ★ **왜 `softmax.cs.hlsl` 에 `causalOff` 한 칸을 더하지 않았나**(금지 목록 #23 을 실제로 검토한 결과):
//   마스크는 `scale` 처럼 **곱셈 하나가 아니다** — ㉠ 최댓값·합 루프의 **상한**이 바뀌고 ㉡ 쓰기 루프가
//   「허용 칸 = e·inv / 마스크 칸 = 0」으로 **갈라진다**. 즉 루프 몸통이 다르다.
//   그리고 `softmax` 의 다른 소비자는 **어휘 헤드(rows×V)** 라 인과라는 개념이 아예 없다 —
//   거기에 필드를 두면 모든 호출부가 뜻 없는 값을 옳게 채워야 한다. ⇒ 갈라 두는 것이 맞다.
//
// ★ **`causalOff` = 첫 질의 앞에 이미 있는 키 개수.** 지금은 **0**(질의와 키가 같은 창)이고,
//   KV 캐시가 생기면 `Pr` 이 `T_q × T_k` 로 직사각이 되면서 이 칸이 쓰인다. ★ 지금 0 을 넣어 두면
//   그때 계약을 안 고친다.
//
// ★ **스레드 하나가 한 행을 맡는다** — `softmax.cs.hlsl` 과 **같은 관용구**다(리덕션이 없어 결정적).
//   ⚠️ `T` 가 수천이 되면 다시 볼 자리다(그때는 그룹 리덕션 + 고정 순서).
//
// ⚠️ 누산 순서는 `j` 오름차순 — CPU 레퍼런스(`MLAttnSoftmaxCpu`)와 **같은 순서**여야 견줄 수 있다.
// ⚠️ 최댓값은 **온도를 곱한 뒤**에, 그리고 **허용 칸에서만** 잰다(`softmax` 와 같은 순서 · 마스크 칸이
//   최댓값을 잡으면 안정화가 어긋나 값이 통째로 갈린다).

// ⚠️⚠️ **호스트(`MLAttnSoftmaxParams`)와 글자 그대로 같은 배치다** — 어긋나면 크래시가 아니라
//   **조용히 틀린 결과**다(relu 의 `count = 0` 사고). ⚠️ 마지막이 **`float`** 다(함정 33).
struct AttnSoftmaxParams
{
    uint  inOff, outOff, rows, cols;   // 아레나 안 **float 인덱스**(바이트가 아니다). `S`/`Pr` 은 rows×cols
    uint  causalOff, pad0;             // ★ pad0 = 남는 칸(지우지 않는다 — 꼬리에만 붙인다)
    float scale;                       // ★ 온도 = `1/√Dh`. ⚠️ `softmax_bwd` 에 **같은 값**을 준다
};
[[vk::push_constant]] AttnSoftmaxParams gP;

RWStructuredBuffer<float> gArena : register(u0);

[numthreads(64, 1, 1)]
void main(uint3 tid : SV_DispatchThreadID)
{
    const uint r = tid.x;
    if (r >= gP.rows) return;          // ⚠️ 범위 검사는 커널의 몫
    if (gP.cols == 0u) return;         // ⚠️ 아래 `cols - 1` 이 감싸 돌지 않게(0 이면 할 일도 없다)

    const uint base = r * gP.cols;

    // ⓪ 허용 상한 — 행 `r` 은 `j <= r + causalOff` 만 본다. 열 수를 넘으면 **전부 허용**으로 접는다.
    //   ★ 대각(`j == r`)은 언제나 허용이므로 **행이 통째로 마스크되는 일이 없다** ⇒ `sum >= 1`, 0 나눗셈이 원리적으로 없다.
    uint last = r + gP.causalOff;
    if (last >= gP.cols) last = gP.cols - 1u;

    // ① 행 최댓값 — ⚠️ **온도를 곱한 뒤** · **허용 칸에서만**.
    float mx = gArena[gP.inOff + base] * gP.scale;
    for (uint j = 1u; j <= last; ++j)
    {
        const float z = gArena[gP.inOff + base + j] * gP.scale;
        if (z > mx) mx = z;
    }

    // ② exp 합 — ⚠️ 지수를 **쓰면서** 더한다(두 번 계산하지 않는다). 허용 칸만 채운다.
    float sum = 0.0;
    for (uint j2 = 0u; j2 <= last; ++j2)
    {
        const float e = exp(gArena[gP.inOff + base + j2] * gP.scale - mx);
        gArena[gP.outOff + base + j2] = e;
        sum += e;
    }

    // ③ 정규화 + **마스크 칸에 정확히 0**.
    //   ⚠️⚠️ 이 `0.0` 이 정확성이다 — 뒤의 `gemm(O = Pr·V)` 은 마스크를 모르므로 쓰레기가 남아 있으면
    //     미래를 훔쳐본다(그리고 그것은 손실이 **더 잘** 내려가는 모양으로 나타나 버그로 안 읽힌다).
    //     ⚠️ 앞 스텝이 남긴 값일 수도 있으니 「안 쓰기」가 아니라 **쓴다**.
    const float inv = 1.0 / sum;
    for (uint j3 = 0u; j3 < gP.cols; ++j3)
        gArena[gP.outOff + base + j3] = (j3 <= last) ? (gArena[gP.outOff + base + j3] * inv) : 0.0;
}
