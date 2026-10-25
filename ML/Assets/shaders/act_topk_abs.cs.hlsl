// act_topk_abs.cs.hlsl — ⭐ **선택은 `|z|` · 세기는 `z`(부호 그대로).** `act_topk` 의 형제다.
//
// ══════════════════════════════════════════════════════════════════════════════
// ★ **왜 이것이 있나 — 회차 27·28 이 낸 결함 하나 때문이다**
// ══════════════════════════════════════════════════════════════════════════════
//   `act_topk` 은 **가장 큰 점수 k개**를 골라 **그 값을 그대로 재구성 계수**로 쓴다.
//   ⇒ 뽑힌 계수는 사실상 **전부 양수이고 크기도 서로 비슷하다**(어떤 행의 상위 8개니까).
//   ⚠️ 그런데 실측(회차 27): **ids 를 그대로 두고 세기만 최소제곱으로** 바꾸면 시험 오차가
//     **30% 준다**(12/12 씨앗 · p=0.00024). 최소제곱의 계수는 **부호도 크기도 자유롭다.**
//   ⇒ ★ 그 30% 의 정체 후보가 **「계수가 양수 큰 값들로 묶여 있다」**는 제약이다.
//     (크기 정규화로는 안 고쳐졌다 — 회차 26 `Wd` · 회차 28 코드북, 둘 다 아무 효과 없음.)
//
//   ⭐ **그래서 「크면 뽑힌다」와 「맞으면 좋다」를 가른다**: 뽑는 기준은 **기여의 크기**(`|z|`)이고
//     계수는 **부호 있는 값**(`z`) 그대로 쓴다. 그러면 같은 선형사영이 **음의 계수**를 낼 수 있다.
//
//   ★ **bwd 는 새로 만들지 않는다 — `act_topk_bwd` 를 그대로 쓴다.**
//     `mag[r][j] = z[r][ids[r][j]]` 라는 관계가 **글자 그대로 같고**, 선택은 상수(straight-through)라
//     기울기는 `ids` 로 흩뿌리는 것 하나뿐이다. ⇒ **fwd 한 장만 새로 판정한다.**
//
// ⚠️ `act_topk` 과 **다른 곳은 비교 한 줄뿐**이다(`z > bestVal` → `|z| > |bestVal|`).
//   그래서 이 파일을 고칠 때는 **반드시 그쪽도 같이 본다** — 동점 규약·센티널·`taken` 되읽기가
//   갈라지면 판정이 두 곳에서 서로를 못 잡는다.
// ⚠️ 파라미터 구조체는 `ActTopkParams` 와 **같은 배치**다(호스트가 `MLActTopkParams` 하나로 쓴다).

struct ActTopkAbsParams
{
    uint scoreOff, idsOff, magOff, pad0;   // 아레나 안 **float 인덱스**(바이트가 아니다)
    uint rows, dict, k, pad1;
};
[[vk::push_constant]] ActTopkAbsParams gP;

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
        // ① 아직 안 뽑힌 자리 중 **|z| 가 최대**. ⚠️ `n` **오름차순** + `>` ⇒ 동점은 **낮은 색인**이 이긴다
        //   (`act_topk` 과 같은 규약 — 갈라지면 두 커널의 판정이 서로를 못 잡는다).
        uint  best = gP.dict;          // ★ 센티널 = "없다"(범위 밖) — `k > dict` 인 슬롯이 여기 남는다
        float bestVal = 0.0;           // ★ **부호 있는** 값을 담는다(비교만 절댓값으로 한다)
        for (uint n = 0; n < gP.dict; ++n)
        {
            // ★ 「제외」를 별 버퍼로 두지 않는다 — 방금 **자기가 쓴** `ids` 를 되읽는다.
            bool taken = false;
            for (uint q = 0; q < j; ++q)
                if ((uint)gArena[gP.idsOff + oBase + q] == n) taken = true;
            if (taken) continue;

            const float z = gArena[gP.scoreOff + zBase + n];
            if (best == gP.dict || abs(z) > abs(bestVal)) { best = n; bestVal = z; }
        }

        // ② 두 칸을 함께 쓴다 — 이 슬롯의 주인이 이 스레드뿐이다.
        //   ⚠️ `mag` 은 **점수 그대로**(부호 포함)다 — 그것이 이 커널의 요점이다.
        gArena[gP.idsOff + oBase + j] = (float)best;
        gArena[gP.magOff + oBase + j] = (best < gP.dict) ? bestVal : 0.0;
    }
}
