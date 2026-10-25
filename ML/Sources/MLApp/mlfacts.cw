// mlfacts.cw — ▶️📊 **장면을 실행해서 사실을 읽고, 두 사실을 견주는 도구.**
//
// ★ **왜 파일이 갈렸나 — 소비자가 둘이 됐다.**
//   여태 이 논리는 `mltrainer.cw` 안의 private 함수였다(`_FactVec`·`_FactScore`·`_RenderSceneFacts`·
//   `_Axis*`). 이제 **생명주기 실험**(`mllife.cw` — 기억·가설·시험·정리)이 같은 것을 쓴다.
//   ⇒ 복붙하면 두 벌이 갈라지고(그러면 두 실험의 숫자를 견줄 수 없다) 저장소 규칙에도 어긋난다
//     (*"비슷한 함수·클래스는 묶기"*).
//
// ⚠️⚠️ **여기 있는 것과 없는 것의 경계**: 여기 있는 것은 **장면·사실만 아는 순수 도구**다.
//   학습·가중치·아레나·오라클 회계는 **소비자 쪽**에 남는다. 특히 `Render` 는 **오라클이 아니다** —
//   자기 상상을 실행하는 것이고, *"정답 장면을 만졌나"* 를 세는 것은 부르는 쪽의 몫이다.
//
// ⚠️ **축 번호의 경계도 여기 있다**: 여기는 **0~5**(개수·모양·색·크기·자리·속)만 안다.
//   프로브 단계가 쓰는 **6번(개수깔끔)** 은 그 단계의 사정이므로 `MLTrainer` 가 얹는다.
//   ★ 그것을 안 갈랐다면 `AxisAt(6)` 이 `Fill` 을 돌려주어 **6분류가 조용히 2분류가 됐다**
//     (옮기기 전에 발견했다 — 리팩터가 숫자를 바꾸는 가장 흔한 모양이다).

class MLFacts
{
public:
	// ▶️📊 **사실 벡터의 항목 수.** ★ **이것이 추론의 재료다.**
	//   ⚠️⚠️ 실측으로 밟았다(함정 48): 같은 것을 계산해 놓고 `hit/all` 로 **스칼라로 뭉개서** 썼다 ⇒
	//     모델이 받는 것이 *"0.6점"* 이고 *"**색은 맞고 개수가 틀렸다**"* 가 아니었다.
	//     ⇒ 귀속의 재료를 만들어 놓고 **던져 버린 것**이고, 그것이 자기학습을 **감 찍기**로 만들었다.
	//   ★ 항목: 0 있나/없나 · 1 덩어리 수 · 2 평균색 · 3 잉크 면적 · 4 bbox 중심 · 5 덩어리 채움률.
	// 🔲 **6 + 9 + 9 = 24**(D47) — 원래 여섯 + **프레임 3×3** + **bbox 3×3** 잉크 유무.
	//
	// ★ D45·D46 이 이 자리를 정했다: 겹침 2+ 에서 이진 채널이 **2.8%**(무작위 3.0%)로
	//   붕괴하고(D45), 그 겹침은 **전역 스칼라를 여러 축이 가산으로 미는 것**이다(D46 —
	//   면적을 개수·크기·속이 37.5/47.1/16.0% 로 · 채움을 모양·크기·속이 100/52.9/100% 로).
	// ★ 격자는 그 양에 **「어디서」**를 준다: 개수 → 다른 칸 · 자리 → 칸 이동 ·
	//   모양 → 코너 칸 · 속 → 중앙 칸. ⇒ **질적으로 다른 무늬**가 된다.
	// ⚠️ 그리고 칸별 잉크 유무는 **이산 그 자체**라 「각자 문턱 미달인데 합쳐서 넘는」 사고가
	//   안 생긴다(D43 이 톨러런스로 못 고친 그것). ⚠️ 다만 **정리(定理)는 아니다** —
	//   기하 상호작용으로 유령 칸이 생길 수는 있고, 그것은 `orExact` 가 잰다.
	// ⚠️⚠️ `Vec`·`VecSigned` 는 **안 고쳤다**(🚫) — 둘 다 `kFacts` 루프로 전체를 중립값으로
	//   초기화하고 6칸만 덮으므로 **새 칸이 저절로 중립**이다(`Vec` 1=같다 · `RawDiff` 0=안움직임).
	static constexpr int kFacts = 24;
	static constexpr int kFactsBase = 6;          // 🔲 원래 여섯(격자 앞)
	static constexpr int kTileN = 9;              // 🔲 한 격자의 칸 수(3×3)

	// 그림 크기 — 커리큘럼의 프레임과 같아야 한다(다르면 면적·자리 문턱이 뜻을 잃는다).
	static constexpr uint32 kW = 64, kH = 64;

	// ▶️ **장면을 실제로 실행해서 사실을 읽는다.**
	//   ⚠️ 이것은 **오라클이 아니다** — 자기 상상의 실행이다. 오라클은 **정답 장면**을 만질 때이고
	//     그것을 세는 것은 부르는 쪽이다(`_gnOracle`).
	static bool Render(const MLScene& sc, MLFrameFacts& out)
	{
		DrawProgram prog;
		const String code = MLSense::Code(sc, false);
		if (!prog.Compile(code.View(), kW, kH, NameID("GenExec"))) return false;
		if (!prog.RunStart()) return false;
		MLFrameReader::Read(prog.canvas, out);
		return true;
	}

	// ▶️📊 **항목마다 맞았나(0/1).** ⚠️ 뜻이 없는 항목은 "맞음" 으로 둔다.
	static void Vec(const MLFrameFacts& a, const MLFrameFacts& b, uint8* out)
	{
		for (int i = 0; i < kFacts; ++i) out[i] = 1u;
		out[0] = (a.empty == b.empty) ? 1u : 0u;
		if (a.empty || b.empty) return;                      // 빈 장면이면 나머지는 뜻이 없다
		out[1] = (a.blobs == b.blobs) ? 1u : 0u;
		out[2] = (_ColorDist(a, b) <= 96) ? 1u : 0u;
		out[3] = _AreaClose(a, b) ? 1u : 0u;
		out[4] = _CenterClose(a, b) ? 1u : 0u;
		out[5] = (_FillDist(a, b) <= kFillTol) ? 1u : 0u;
	}

	// ▶️🎞️ **이전과 현재** — 같은 장면의 **프레임 0 과 1**.
	//
	// ★ **왜 필요한가**(D5): 여태 모든 차분은 **반사실**이었다 —
	//   `A → B` 가 *"내가 축을 세워서"* 생긴 것이고 **한 세계의 두 순간이 아니었다.**
	//   ⇒ 그래서 `간다` 는 접지될 수가 없었다: 정지 장면과 움직이는 장면의 **프레임 0 은 똑같다.**
	//     `간다` 의 시각적 흔적은 **시간 차분으로만** 존재하고, 단일 프레임 판독기로는 **원리적으로**
	//     못 잡는다. ⇒ 그것이 *"변하는 세상"* 이 필요한 최소 이유다.
	// ⚠️ **이전과 현재만** 쓴다(진짜 시간 값 `t` 는 다음 단계다) — 지금 t 를 넣으면
	//   **개입/동역학의 갈림**과 **시간 해상도**라는 두 손잡이가 한꺼번에 움직인다.
	// ⚠️ `moves == 0` 이면 두 프레임이 **같아야** 한다(그것이 `안간다` 의 접지다).
	static bool RenderPair(const MLScene& sc, MLFrameFacts& before, MLFrameFacts& after)
	{
		DrawProgram prog;
		const String code = MLSense::Code(sc, false);
		if (!prog.Compile(code.View(), kW, kH, NameID("GenExec"))) return false;
		if (!prog.RunStart()) return false;
		MLFrameReader::Read(prog.canvas, before);
		if (!prog.RunFrame()) return false;
		MLFrameReader::Read(prog.canvas, after);
		return true;
	}

	// ▶️📏 **날 차분의 크기** — 문턱을 **밖에서** 정할 수 있게 원값을 준다.
	//
	// ★ **왜 필요한가**(D4 5차 · 사슬 ⓒ): `Vec` 의 *"같다"* 는 **손으로 박은 상수**다
	//   (`색 ≤ 96` · `면적 2배` · `중심 16px` · `채움 kFillTol`). 그것은 이 사슬에서 **마지막으로
	//   남은 "내가 준 것"** 이다 — ③(겹침을 지운다)의 정의를 내가 쥐고 있는 것이다.
	// ⇒ 원값을 내주면 **다른 채널이 문턱을 정할 수 있다**: *"말이 같다고 한 쌍에서 실제로 얼마나
	//   흔들리나"* 가 곧 *"같다"* 의 경계다(→ `MLDiff::_Calibrate`).
	// ⚠️ 단위를 항목마다 맞춘다(전부 정수 · 클수록 많이 변했다):
	//   `0` 있나(0/1) · `1` 덩어리 개수차 · `2` 색거리(0~765) · `3` 면적 상대차(%) ·
	//   `4` 중심 이동(px) · `5` 채움률 차(×100).
	static void RawDiff(const MLFrameFacts& a, const MLFrameFacts& b, int* out)
	{
		for (int i = 0; i < kFacts; ++i) out[i] = 0;
		out[0] = (a.empty != b.empty) ? 1 : 0;
		if (a.empty || b.empty) return;
		out[1] = (a.blobs > b.blobs) ? (a.blobs - b.blobs) : (b.blobs - a.blobs);
		out[2] = _ColorDist(a, b);
		{
			const int la = (a.litPixels > 0) ? a.litPixels : 1, lb = (b.litPixels > 0) ? b.litPixels : 1;
			const int hi = (la > lb) ? la : lb, d = (la > lb) ? (la - lb) : (lb - la);
			out[3] = (hi > 0) ? (d * 100 / hi) : 0;
		}
		{
			const int acx = (a.minX + a.maxX) / 2, acy = (a.minY + a.maxY) / 2;
			const int bcx = (b.minX + b.maxX) / 2, bcy = (b.minY + b.maxY) / 2;
			const int dx = (acx > bcx) ? acx - bcx : bcx - acx;
			const int dy = (acy > bcy) ? acy - bcy : bcy - acy;
			out[4] = (dx > dy) ? dx : dy;
		}
		out[5] = (int)(_FillDist(a, b) * 100.0f);
		// 🔲 **격자 18칸**(D49) — 단위를 `면적`(out[3])과 **같게** 맞춘다: 그 칸의 잉크 픽셀 수의
		//   **상대 차분 %**. ⇒ `_Calibrate` 가 다른 사실과 같은 규칙으로 문턱을 잡을 수 있다.
		//   ⚠️ **「유무」로 만들지 않는다** — 이산 사실은 교정이 죽인다(`MLFrameFacts` 의 그 ★).
		//     유무가 필요한 소비자는 `count > 0` 을 스스로 본다(`MLDiff::_tileM`).
		//   ★ 둘 다 0 이면 0 이다(빈 칸끼리는 안 변했다) — 분모가 0 이 되는 자리를 그렇게 닫는다.
		for (int k = 0; k < kTileN; ++k)
		{
			const int pa = (int)a.tileF[k], pb = (int)b.tileF[k];
			const int hi = (pa > pb) ? pa : pb, d = (pa > pb) ? (pa - pb) : (pb - pa);
			out[kFactsBase + k] = (hi > 0) ? (d * 100 / hi) : 0;
			const int qa = (int)a.tileB[k], qb = (int)b.tileB[k];
			const int hj = (qa > qb) ? qa : qb, e = (qa > qb) ? (qa - qb) : (qb - qa);
			out[kFactsBase + kTileN + k] = (hj > 0) ? (e * 100 / hj) : 0;
		}
	}

	// ▶️🔬 **부호까지 든 차분** — `Vec` 이 버리는 **방향**을 되살린다.
	//
	// ★ **왜 생겼나**(D4 1차 · 함정 119): `Vec` 은 *"움직였나"* 만 주므로 차분이 **이진 6비트**이고,
	//   실제로 쓰이는 값이 **2~5종**뿐이었다. 그런데 구별해야 할 낱말차는 **10종**이라
	//   한 마스크에 낱말차가 **최대 6종** 붙었다 ⇒ `비전차 → 말차` 가 **원리적으로** 안 갈렸다.
	//   ★ 즉 학습의 실패가 아니라 **표현의 상한**이었다.
	// ★ **새 상수를 넣지 않는다** — *"같다"* 의 경계는 `Vec` 과 **같은 톨러런스**를 쓰고,
	//   거기서 벗어난 것에 **이미 센서가 주고 있던 부호**만 붙인다. ⇒ 의미 주입이 아니라 **해상도 복구**다.
	// ⚠️ **색은 부호가 없다** — `_ColorDist` 는 3채널 거리이고, 채널 하나를 골라 부호를 만들면
	//   그것은 *"어느 채널이 중요하다"* 는 **의미 주입**이다 ⇒ 2단계로 남긴다(정직한 한계).
	// ⚠️ **자리는 네 방향**이다 — `dx`/`dy` 중 **큰 쪽**으로 정한다. 캡션의 자리 낱말이
	//   `왼쪽/오른쪽/위/아래` 로 **서로 배타**이므로 그 구분과 같은 결이고, 새 상수가 아니다.
	// ⚠️⚠️ **`Vec` 을 고치지 않는다** — D3 의 사슬 전체가 그것에 의존한다(고치면 회차 간 비교가 깨진다).
	//   이 함수는 **추가**이고 소비자는 지금 `mldiff` 뿐이다.
	//
	// 항목별 값의 개수: `있나 3 · 덩어리 3 · 색 2 · 면적 3 · 자리 5 · 채움 3` ⇒ 조합 **810**.
	// 🔲 격자 칸은 **2진**(안바뀜 · 바뀜) — 방향이 없다(유무니까).
	static constexpr int kSignedRadix[kFacts] = { 3, 3, 2, 3, 5, 3,
		2, 2, 2, 2, 2, 2, 2, 2, 2,   2, 2, 2, 2, 2, 2, 2, 2, 2 };
	static constexpr int kSignedCodes = 3 * 3 * 2 * 3 * 5 * 3;
	static void VecSigned(const MLFrameFacts& a, const MLFrameFacts& b, uint8* out)
	{
		for (int i = 0; i < kFacts; ++i) out[i] = 0u;
		if (a.empty != b.empty) out[0] = (uint8)(a.empty ? 1u : 2u);   // 1 = 생겼다 · 2 = 없어졌다
		if (a.empty || b.empty) return;                                // 빈 장면이면 나머지는 뜻이 없다
		if (a.blobs != b.blobs)     out[1] = (uint8)((b.blobs > a.blobs) ? 1u : 2u);
		if (_ColorDist(a, b) > 96)  out[2] = 1u;                       // ⚠️ 부호 없음(3채널 거리)
		if (!_AreaClose(a, b))      out[3] = (uint8)((b.litPixels > a.litPixels) ? 1u : 2u);
		if (!_CenterClose(a, b))
		{
			const int acx = (a.minX + a.maxX) / 2, acy = (a.minY + a.maxY) / 2;
			const int bcx = (b.minX + b.maxX) / 2, bcy = (b.minY + b.maxY) / 2;
			const int dx = bcx - acx, dy = bcy - acy;
			const int ax = (dx < 0) ? -dx : dx, ay = (dy < 0) ? -dy : dy;
			out[4] = (ax >= ay) ? (uint8)((dx < 0) ? 1u : 2u)          // 1 = 왼쪽 · 2 = 오른쪽
				: (uint8)((dy < 0) ? 3u : 4u);                         // 3 = 위 · 4 = 아래
		}
		if (_FillDist(a, b) > kFillTol) out[5] = (uint8)((b.blobFill > a.blobFill) ? 1u : 2u);
	}

	// ▶️🎨 **색의 분해능을 여는 자리**(D33) — ***`VecSigned` 를 고치지 않고 진법만 늘린다.***
	//
	// ★ **왜 필요한가**(D26 실측): 색 축은 팔레트 5색이라 낱말차가 `C(5,2) = 10` 종인데
	//   `VecSigned` 의 색 자리는 **값이 둘**(안바뀜/바뀜)이다 ⇒ **열 종이 벡터에서 전부 같다.**
	//   그래서 세계후보 3.8개 중 **2.84개가 참벡터로도 구별 불가**였고, 그것이 ② 의 벽이었다.
	// ★ **새 상수를 넣지 않는다** — 문턱은 그대로(`_ColorDist > 96` 또는 교정값)이고, 바뀐 것에
	//   **이미 센서가 주고 있던 「어느 채널이 가장 크게 변했나」**만 붙인다. 그것은 `자리` 가 쓰는
	//   관용구와 **같은 결**이다(`자리` = `dx`/`dy` 중 **큰 쪽** → 4방향).
	// ⚠️ **방향은 안 담는다** — 3채널 × 2방향 = 6 이고 `+안바뀜` 이면 7 이라 표의 `kMaxVals = 5` 를
	//   넘는다. 채널만 담으면 **4칸**이라 들어간다. ⇒ 정직한 한계이고, 방향은 다음 손잡이다.
	// ⚠️ 타이는 **R > G > B 고정 순서**로 깬다(결정적이어야 재현이 안 깨진다 · 새 상수가 아니다).
	static constexpr int kSignedRadixFine[kFacts] = { 3, 3, 4, 3, 5, 3,
		2, 2, 2, 2, 2, 2, 2, 2, 2,   2, 2, 2, 2, 2, 2, 2, 2, 2 };
	static constexpr int kSignedCodesFine = 3 * 3 * 4 * 3 * 5 * 3;
	// 🎨 **어느 채널이 가장 크게 변했나** — 1 = R · 2 = G · 3 = B(0 은 부르는 쪽이 정한다).
	static uint8 DomChannel(const MLFrameFacts& a, const MLFrameFacts& b)
	{
		const int dr = (a.avgR > b.avgR) ? a.avgR - b.avgR : b.avgR - a.avgR;
		const int dg = (a.avgG > b.avgG) ? a.avgG - b.avgG : b.avgG - a.avgG;
		const int db = (a.avgB > b.avgB) ? a.avgB - b.avgB : b.avgB - a.avgB;
		if (dr >= dg && dr >= db) return 1u;
		if (dg >= db) return 2u;
		return 3u;
	}

	// 🔢 그 여섯을 **하나의 코드**로 접는다(혼합 진법 — 자리마다 값의 개수가 다르다).
	// ⚠️ `fine` 이면 색 자리의 진법이 **4** 다(위 🎨) — 두 코드는 **서로 다른 공간**이다.
	static int SignedCodeR(const uint8* v, const int* radix)
	{
		int code = 0, mul = 1;
		for (int i = 0; i < kFacts; ++i)
		{
			int x = (int)v[i];
			if (x >= radix[i]) x = radix[i] - 1;
			code += x * mul;
			mul *= radix[i];
		}
		return code;
	}
	static int SignedCodeFine(const uint8* v) { return SignedCodeR(v, kSignedRadixFine); }

	static int SignedCode(const uint8* v)
	{
		int code = 0, mul = 1;
		for (int i = 0; i < kFacts; ++i)
		{
			int x = (int)v[i];
			if (x >= kSignedRadix[i]) x = kSignedRadix[i] - 1;
			code += x * mul;
			mul *= kSignedRadix[i];
		}
		return code;
	}

	// ▶️ **사실 일치 점수** ∈ [0,1] — 판독기가 주는 것이 **벡터**라 축별로 센다.
	//   ★ 그것이 이 프로젝트가 희소 보상 문제를 피하는 자리다: *"어디가 틀렸나"* 를 채점이 직접 준다.
	//   ⚠️ 문턱은 관대하게 둔다 — 묻는 것은 *"의미가 같나"* 이고 픽셀 동일성이 아니다.
	//   ⚠️ **`Vec` 과 같은 문턱을 쓴다** — 두 함수가 어긋나면 *"벡터로는 틀렸는데 점수는 맞다"* 가 되어
	//     귀속이 조용히 깨진다(그 둘을 한 파일에 둔 이유 중 하나다).
	static float Score(const MLFrameFacts& a, const MLFrameFacts& b)
	{
		uint8 v[kFacts];
		Vec(a, b, v);
		// ⚠️ 빈 장면이면 항목 0 만 뜻이 있다 — `Vec` 이 나머지를 1 로 채우므로 여기서 분모를 줄인다.
		const int all = (a.empty || b.empty) ? 1 : kFacts;
		int hit = 0;
		for (int i = 0; i < all; ++i) if (v[i] != 0u) hit++;
		return (float)hit / (float)all;
	}

	// 🔷 덩어리 채움률의 문턱. ⚠️ **결과를 보고 정한 것이 아니다**: 동그라미 꽉 `π/4 ≈ 0.785` vs
	//   네모 꽉 `≈ 1.0` 이라 차이가 **0.215** 다 ⇒ 0.10 이면 그 둘을 가르고 잡음은 안 잡는다.
	static constexpr float kFillTol = 0.10f;

	// ── 장면의 축 (0 개수 · 1 모양 · 2 색 · 3 크기 · 4 자리 · 5 속) ───────────
	//   ⚠️ `AxisGet` 과 `AxisSet` 은 **짝**이다 — 둘이 어긋나면 조용히 틀린다.
	static int AxisGet(const MLScene& sc, int axis)
	{
		const MLAxis a = MLSense::AxisAt(axis);
		if (a == MLAxis::Count) return sc.count - 1;
		if (a == MLAxis::Shape) return sc.shape;
		if (a == MLAxis::Color) return sc.color;
		if (a == MLAxis::Size)  return sc.big;
		if (a == MLAxis::Pos)   return sc.pos;
		return sc.filled;
	}

	// 그 축의 값을 장면에 **덮어쓴다**(균등 분포 + 다른 축과 독립).
	static void AxisSet(MLScene& sc, int axis, int value)
	{
		const MLAxis a = MLSense::AxisAt(axis);
		if (a == MLAxis::Count)      sc.count = value + 1;
		else if (a == MLAxis::Shape) sc.shape = value;
		else if (a == MLAxis::Color) sc.color = value;
		else if (a == MLAxis::Size)  sc.big = value;
		else if (a == MLAxis::Pos)   sc.pos = value;
		else                         sc.filled = value;
	}

	static uint32 AxisClasses(int axis)
	{
		const MLAxis a = MLSense::AxisAt(axis);
		if (a == MLAxis::Count) return 6;                            // 1..6("여럿" 포함)
		if (a == MLAxis::Color) return (uint32)MLEpisodeGen::PaletteCount();
		if (a == MLAxis::Pos)   return 5;
		return 2;                                                    // 모양 · 크기 · 속
	}

	// 🔤 축의 이름 — 로그가 사람에게 읽히게.
	static const char* AxisName(int axis) { return MLSense::AxisName(MLSense::AxisAt(axis)); }

	// 🔤 사실 항목의 이름.
	static const char* FactName(int f)
	{
		static const char* n[kFacts] = { "있나", "덩어리", "색", "면적", "자리", "채움",
			// 🔲 격자 — 틀 3x3 · 몸 3x3 (⚠️ 안 채우면 `Name()` 이 nullptr 를 준다)
			"틀00", "틀01", "틀02", "틀10", "틀11", "틀12", "틀20", "틀21", "틀22",
			"몸00", "몸01", "몸02", "몸10", "몸11", "몸12", "몸20", "몸21", "몸22" };
		return (f >= 0 && f < kFacts) ? n[f] : "?";
	}

private:
	static int _ColorDist(const MLFrameFacts& a, const MLFrameFacts& b)
	{
		return ((a.avgR > b.avgR) ? a.avgR - b.avgR : b.avgR - a.avgR)
			+ ((a.avgG > b.avgG) ? a.avgG - b.avgG : b.avgG - a.avgG)
			+ ((a.avgB > b.avgB) ? a.avgB - b.avgB : b.avgB - a.avgB);
	}
	// 잉크 면적이 2배 안인가.
	static bool _AreaClose(const MLFrameFacts& a, const MLFrameFacts& b)
	{
		const int la = (a.litPixels > 0) ? a.litPixels : 1, lb = (b.litPixels > 0) ? b.litPixels : 1;
		return (la * 2 >= lb && lb * 2 >= la);
	}
	// bbox 중심이 16px 안인가.
	static bool _CenterClose(const MLFrameFacts& a, const MLFrameFacts& b)
	{
		const int acx = (a.minX + a.maxX) / 2, acy = (a.minY + a.maxY) / 2;
		const int bcx = (b.minX + b.maxX) / 2, bcy = (b.minY + b.maxY) / 2;
		const int dx = (acx > bcx) ? acx - bcx : bcx - acx;
		const int dy = (acy > bcy) ? acy - bcy : bcy - acy;
		return (dx <= 16 && dy <= 16);
	}
	static float _FillDist(const MLFrameFacts& a, const MLFrameFacts& b)
	{
		return (a.blobFill > b.blobFill) ? (a.blobFill - b.blobFill) : (b.blobFill - a.blobFill);
	}
};
