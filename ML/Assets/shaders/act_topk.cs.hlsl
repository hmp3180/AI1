// act_topk.cs.hlsl — ⭐ **행마다 사전 점수의 상위 k 개를 고른다.** `mag[r][j] = z[r][ ids[r][j] ]`
//
// ★ **왜 이 커널이 필요한가** — `softmax` 도 `relu` 도 **자리를 고르지 않는다**(사전 전체에 값을
//   남긴다). 이 트랙의 활성은 *"사전 N 중 지금 켜진 것 k 개"* 라는 **희소한 이산 선택**이고, 그 선택
//   자체가 본체 트랜스포머의 입력 심볼이 된다 ⇒ `(id, 세기)` 두 텐서를 내는 커널이 따로 있어야 한다.
//   ⚠️ 정렬 커널로 흉내내지 마라 — `N=512 · k=8` 이라 전 정렬은 통째로 낭비이고, 무엇보다
//     비토닉/부분정렬은 **비교 순서가 스레드 배치에 매인다** ⇒ 동점 처리가 실행마다 갈린다.
//
// ★ **k 번의 argmax + 제외**로 고른다 — 비용 `k²·N`(8·8·512 ≈ 32K/행)이라 값싸고, 무엇보다
//   **완전히 결정적**이다(비교 순서가 `n` 오름차순으로 못 박혀 있다). 이 저장소의 판정은 전부
//   CPU 레퍼런스와의 수치 일치라, **결정성이 성능보다 값지다**(`softmax`·`rmsnorm` 과 같은 판정).
//
// ★ **동점은 낮은 색인이 이긴다** — `n` 을 오름차순으로 훑고 비교를 `>`(`>=` 가 **아니다**)로 두면
//   저절로 그렇게 된다. ⚠️⚠️ CPU 레퍼런스(`MLActTopkCpu`)가 **글자 그대로 같은 규칙**이어야 한다 —
//   초기 파라미터에서는 동점이 실제로 나오고(사전이 아직 안 갈렸다), 규칙이 갈리면 `ids` 가 어긋나
//   **그 뒤의 모든 판정이 통째로 거짓말**이 된다(그리고 `mag` 은 멀쩡해 보인다).
//
// ★ **`mag` 은 점수를 그대로 쓴다** — 활성 함수를 섞지 않는다(필요하면 `relu` 를 따로 건다).
//   섞으면 「세기」의 뜻이 커널 이름에 안 적힌 채 바뀌고, bwd 의 straight-through 도 같이 흐려진다.
//
// ★ **출력이 둘인 예외** — 스레드 하나가 행 `r` 의 `ids`/`mag` **두 칸의 유일한 주인**이다(계약 §3.2 ㉢).
//   ⚠️ 리덕션이 끼면 이 예외를 쓸 수 없지만, 여기는 행이 스레드 하나에 통째로 속하므로 성립한다.
//
// ⚠️⚠️ **선택은 미분이 안 된다** — bwd(`act_topk_bwd`)는 **세기로만** 기울기를 흘리고 선택은 상수로
//   본다(straight-through). 그래서 gradcheck 는 **「선택 고정 조건부」**로만 성립한다 —
//   ±ε 로 흔들 때 `ids` 를 다시 고르면 안 된다(그 자리에서 손실이 꺾인다). 이것을 안 적으면
//   다음 사람이 *"gradcheck 를 못 통과한다"* 로 오진한다.
//
// ⚠️ `k > dict` 면 남는 슬롯은 `ids = dict`(**범위 밖**) · `mag = 0` 이다 — bwd 는 `n < dict` 만
//   보므로 그 슬롯의 기울기는 저절로 0 이 된다(fwd/bwd **같은 규약**).
//
// ⚠️ 누산이랄 것이 없지만 **훑는 순서는 `n` 오름차순**이다 — CPU 레퍼런스와 같은 순서여야 동점이 맞는다.

// ⚠️⚠️ **배치를 호스트(`MLActTopkParams`)와 글자 그대로 맞춘다** — 어긋나면 크래시가 아니라
//   **조용히 틀린 결과**다(relu 의 `count = 0` 사고). float 필드가 없으니 자리는 uint 여덟 칸이다.
struct ActTopkParams
{
    uint scoreOff, idsOff, magOff, pad0;   // 아레나 안 **float 인덱스**(바이트가 아니다)
    uint rows, dict, k, pad1;
};
[[vk::push_constant]] ActTopkParams gP;

RWStructuredBuffer<float> gArena : register(u0);

[numthreads(64, 1, 1)]
void main(uint3 tid : SV_DispatchThreadID)
{
    const uint r = tid.x;
    if (r >= gP.rows) return;          // ⚠️ 범위 검사는 커널의 몫

    const uint zBase = r * gP.dict;    // 점수 행
    const uint oBase = r * gP.k;       // ids/mag 행

    for (uint j = 0; j < gP.k; ++j)
    {
        // ① 아직 안 뽑힌 자리 중 최대. ⚠️ `n` **오름차순** + `>` ⇒ 동점은 **낮은 색인**이 이긴다.
        uint  best = gP.dict;          // ★ 센티널 = "없다"(범위 밖) — `k > dict` 인 슬롯이 여기 남는다
        float bestVal = 0.0;
        for (uint n = 0; n < gP.dict; ++n)
        {
            // ★ 「제외」를 별 버퍼(마스크)로 두지 않는다 — 방금 **자기가 쓴** `ids` 를 되읽는다.
            //   같은 스레드의 읽기-쓰기라 가시성이 보장되고, 아레나에 임시 칸이 안 생긴다.
            bool taken = false;
            for (uint q = 0; q < j; ++q)
                if ((uint)gArena[gP.idsOff + oBase + q] == n) taken = true;
            if (taken) continue;

            const float z = gArena[gP.scoreOff + zBase + n];
            if (best == gP.dict || z > bestVal) { best = n; bestVal = z; }
        }

        // ② 두 칸을 함께 쓴다 — 이 슬롯의 주인이 이 스레드뿐이다(위 ★).
        //   ⚠️ `mag` 은 **점수 그대로**다(활성 함수 없음).
        gArena[gP.idsOff + oBase + j] = (float)best;
        gArena[gP.magOff + oBase + j] = (best < gP.dict) ? bestVal : 0.0;
    }
}
