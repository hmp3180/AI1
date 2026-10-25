// mltl1s0.cw — 🔬 회차 179 · **㉲ 의 세계 서명** (`-mlt -mltl1s0`)
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 179 다.** ⭐ **하네스보다 먼저 썼다.**
//   **상위 캔버스: `물체를 센서가 나르면 무엇이 달라지나` · 179 = 1회차**
//
// ── ⚠️⚠️ 처방이 아니다 — 규율 21 ──────────────────────────────────────
//   ㉲(센서가 「물체 정체성 + 위치」를 구조로 나르고 표적을 「그 물체의 다음 상태」로)는
//   **표적 정의를 바꾸는 공사**이고 그러면 **회차 1~178 의 자가 다 바뀐다**.
//   ⇒ ★ 그 전에 **싸게 재서 기각할 수 있으면 기각한다.**
//
// ── ⚙️ 세계만 돈다 — 인코더도 몸통도 없다(초 단위) ────────────────────
//   `MLTShapeView` 가 이미 필요한 것을 다 갖고 있다: **`index` = identity** · `sx·sy·r·d·kind·col`.
//   ⚠️ 그 구조체는 *"판정자 전용"* 으로 등록돼 있다(모델에 안 준다) ⇒ ★ **179 는 판정자로
//   재는 회차**라 그 등록을 어기지 않는다(측정이다 · 규율 73 을 미리 훑었다).
//
// ── 📐 새 표적의 정의(㉲ 가 쓸 것) ────────────────────────────────────
//   계급 = 8×8 패치 격자 **64 칸** + 「화면에 없음」 1 = **65**
//   표적 = 「그 물체가 **다음 시각에 어느 칸에 있나**」 · 슬롯 = **물체 하나**
//   ★ 패치 격자를 쓰는 이유: 지금 표현(`kPatch 8`·`kGrid 8`)과 **같은 눈금**이라 견줄 수 있고
//     **위치가 곧 값**이라 코드북이 없다.
//   ⚠️⚠️ 계급이 250 → 65 로 준다 ⇒ `H`·CE 절대값이 1~178 과 **못 견준다**(규율 58)
//     ⇒ ★ **무차원 자**로만 견준다.
//
// ── 📏 재는 것 다섯 ──────────────────────────────────────────────────
//   ⭐   ① **보이는 도형 수**(평균·최소·최대)      ⇒ 표적 상한
//   ⭐  ② **물체당 「칸이 바뀌는」 비율**          ⇒ 변화 표적 수(희석이 사라지나)
//   ⭐ ③ **정지 세계에서 ②**                    ⇒ 회차 165 의 「센서 몫 42%」가 사라지나
//   ⭐  ④ **자율 ↔ 피동을 가를 수 있나**          ⇒ `P4` 오귀속률이 정의되나(칸 3)
//   ⭐ ⑤ `H(다음 칸)` · `H(다음 칸 | 지금 칸)`   ⇒ **학습 0 최선 = 목표선**(규율 49)
//
// ── 🚪 관문 ──────────────────────────────────────────────────────────
//   ⭐   ① 희석      변화 표적 **< 12/문맥**(지금 35.4)
//   ⭐ ② 센서 몫   정지 세계 변화 표적 **< 1/문맥**(지금 8.9)
//   ⭐   ③ 배울 것    `H(다음|지금)` **> 0.3 나트**
//     ⚠️⚠️ **이것이 이 회차의 진짜 위험이다** — ㉲ 가 표적을 **쉽게** 만들면 「도달률」의
//       분모가 사라진다. ★ 회차 178 이 밟은 함정(*"세계가 쉬워졌다"*)의 **큰 판**이다.
//   ⭐     ④ `P4`      자율·피동이 둘 다 화면에 보인다
//
// ── 🔮 예측(재기 전에 적었다) ────────────────────────────────────────
//   ⭐ ㉠ 보이는 도형 **6~11 개**(14 중) ⇒ 표적 상한 48~88 ⚠️ 지금 56 과 **비슷하다**
//   ⚠️ ㉡ ⇒ **희석이 생각만큼 안 줄 수 있다**(물체당 표적 1 이지만 **물체가 많다**)
//   ⭐ ㉢ 정지 세계 변화 표적 **< 0.5/문맥** ✅
//   ⚠️⚠️ ㉣ `H(다음|지금)` **0.2~0.8** ⇒ 관문 0.3 에 **걸친다**(도형이 프레임당 몇 픽셀 ↔ 칸 8픽셀)
//   ⭐ ㉤ ⇒ 그러면 **칸이 너무 굵다** ⇒ 눈금을 4픽셀로 내리거나 표적을 **「이동 방향 8분위」**로
//   ⭐ ㉥ ④ ✅(자율 3 중 1~3 · 피동 11 중 5~8)
// ══════════════════════════════════════════════════════════════════════════════

using namespace PE;

class MLTL1S0
{
public:
	// ⭐⭐ 회차 232 — 🔒 **하네스 방벽 ①**: 게이트가 **조용히** 막지 못하게 한다
	//   ⛔ 229 가 20분을 버렸다 — `-mltflow` 만 주고 **`-mltl1s0` 을 빠뜨리자 기본 학습이 조용히 돌았다**
	//     ⚠️ 에러도 없고 종료 코드도 정상이고, 진단은 ***「판정 표가 안 나온다」뿐***이었다.
	//     ⇒ ★ `Docs/Guide.md` 가 말하는 **「조용한 실패」** 그 자체다.
	//   ⇒ ⭐ **처방: 하위 모드 이름이 하나라도 있으면 게이트를 함축한다** ⇒ 그 사고가 **원리적으로 없다.**
	//     ⚠️ 그리고 **함축했다는 사실을 한 줄 찍는다** — 조용히 고치면 그것도 조용한 성공이다.
	//   ⚠️⚠️ **새 모드를 만들면 이 표에 한 줄을 더한다**(219 가 적었다: *"모드는 계속 늘어난다"*).
	static const char* _SubModeGiven()
	{
		static const char* kSubModes[] = {
			"-mltksweep", "-mltwsweep", "-mltcsweep", "-mltself", "-mltflow",
			"-mltdep2", "-mltdep", "-mltbal", "-mltamp", "-mltacls", "-mltasweep", "-mltw2sweep",
			"-mltprune",     // ⚖️✂️ 238 — 새 모드를 만들면 이 표에 한 줄(방벽 ① 의 유지비)
			"-mltbody"       // ⚖️⚖️ 265 — 칸 15 「유지 비용 있는 몸」의 세계 서명
		};
		for (uint32 i = 0; i < (uint32)(sizeof(kSubModes) / sizeof(kSubModes[0])); ++i)
			if (OS::CommandLine::Has(kSubModes[i])) return kSubModes[i];
		return nullptr;
	}
	static void Tick(RHI* rhi)
	{
		if (_done || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltl1s0"))
		{
			const char* sub = _SubModeGiven();
			if (sub == nullptr)
			{
				LogA("[mlt] 🔬 회차 179(㉲ 의 세계 서명)는 **꺼져 있다**(`-mltl1s0`)\n");
				_done = true; return;
			}
			// ⭐ 하위 모드를 줬는데 게이트가 없다 ⇒ **오타/실수**다. 조용히 지나가지 않는다.
			LogA("[mlt] 🔒 ⚠️⚠️ **게이트 `-mltl1s0` 이 없는데 하위 모드 `%s` 가 있다 — 게이트를 함축한다**\n", sub);
			LogA("[mlt] 🔒   ⇒ ★ 229 가 이 자리에서 **20분을 버렸다**(조용히 기본 학습이 돌았다)\n");
		}
		// ⭐ 회차 195 — `-mltksweep` = **k스텝 표적의 여지**만 잰다
		//   ★ 179/182 의 서명 표와 **섞지 않는다** — 묻는 것이 다르다(규율 76).
		if (OS::CommandLine::Has("-mltksweep"))
		{
			_kSweep = true;
			_RunK();
			_done = true; return;
		}
		// ⭐ 회차 196 — `-mltwsweep` = **세계 점마다 같은 자**를 잰다
		if (OS::CommandLine::Has("-mltwsweep"))
		{
			_wSweep = true;
			_RunW();
			_done = true; return;
		}
		// ⭐ 회차 197 — `-mltcsweep` = **조건을 팔로**(칸 2 의 분모 지도)
		if (OS::CommandLine::Has("-mltcsweep"))
		{
			_cSweep = true;
			_RunC();
			_done = true; return;
		}
		// ⭐ 회차 218 — `-mltbal` = **행동 여지와 언어 여지를 같은 눈금으로**
		// ⭐ 226 — 상쇄의 천장 ↔ 타자의 여지(공용 규율 18-a)
		if (OS::CommandLine::Has("-mltself"))
		{
			_RunSelf();
			_done = true; return;                 // ⛔ 229 가 잡았다 — 아래 그 주석
		}
		// ⭐ 회차 229 — `-mltflow` = **흐름 표적의 형태를 고른다**(228 의 갈래 ㈁)
		//   ⛔⛔ **229 가 배관 결함을 잡았다** — 위 `-mltself`/`-mltbal`/`-mltamp` 는 `return` 만 하고
		//     **`_done` 을 안 세운다** ⇒ 판정 블록이 ***매 프레임 다시 돈다***(같은 표가 계속 찍힌다).
		//     ⚠️ 값은 안 틀리지만 로그를 삼키고 **끝나지 않는다** — 실측으로 두 판을 찍고 있었다.
		//   ⇒ ★ 새 것은 `_done = true` 를 세운다. 옛 것은 아래에서 같이 고쳤다(배관이라 규율 58 밖).
		if (OS::CommandLine::Has("-mltflow"))
		{
			_RunFlow();
			_done = true; return;
		}
		// ⚖️✂️ 회차 238 — `-mltprune` = 🆕 **「버릴 기준을 세계가 만든다」**(학습 0)
		if (OS::CommandLine::Has("-mltprune"))
		{
			_RunPrune();
			_done = true; return;
		}
		// ⚖️⚖️ 회차 265 — `-mltbody` = 🆕 **칸 15 「유지 비용 있는 몸」의 세계 서명**(학습 0)
		//   ⚠️ 성능을 안 읽는다 — 공용 규율 1(세계를 바꾼 판은 서명이 먼저다)
		if (OS::CommandLine::Has("-mltbody"))
		{
			_RunBody();
			_done = true; return;
		}
		// ⭐ 회차 230 — `-mltdep` = **📌 D42 를 갚는다**(깊이 문턱이 다른 세계에서 뽑혔다)
		// ⭐ 회차 231 — `-mltdep2` = **📌 D43** — 눈금을 곱게 해 230 의 「같다」를 시험한다
		if (OS::CommandLine::Has("-mltdep2"))
		{
			_RunDep2();
			_done = true; return;
		}
		if (OS::CommandLine::Has("-mltdep"))
		{
			_RunDep();
			_done = true; return;
		}
		if (OS::CommandLine::Has("-mltbal"))
		{
			_RunBal();
			_done = true; return;
		}
		// ⭐ 회차 216 — `-mltamp` = **손잡이 둘로 「행동 ↔ 자율」 비를 민다**
		if (OS::CommandLine::Has("-mltamp"))
		{
			_RunAmp();
			_done = true; return;
		}
		// ⭐ 회차 215 — `-mltacls` = **계급을 다시 나눈다**(214 의 갈래 ㈂)
		if (OS::CommandLine::Has("-mltacls"))
		{
			_RunA2();
			_done = true; return;
		}
		// ⭐ 회차 214 — `-mltasweep` = **행동의 여지 + 「가름」**(칸 3 · 학습 0)
		if (OS::CommandLine::Has("-mltasweep"))
		{
			_RunA();
			_done = true; return;
		}
		// ⭐ 회차 198 — `-mltw2sweep` = **새 세계 넷 × 조건 여덟**
		if (OS::CommandLine::Has("-mltw2sweep"))
		{
			_cSweep = true;
			_RunW2();
			_done = true; return;
		}
		_Run();
		_done = true;
	}
	static bool Done() { return _done; }

private:
	inline static bool _done = false;

	static constexpr uint32 kSeeds = 12u;         // ⚠️ 규율 74 — 세계 통계는 12씨앗으로만
	static constexpr uint32 kEpi   = 5001u;       // 시험 코퍼스와 같은 대역(규율 12)
	static constexpr uint32 kCtx   = 512u;        // 문맥 수
	// ⚠️⚠️ **`MLTP3Ctx::kTime` 과 같아야 한다** — 그런데 여기서는 **직접 8** 을 쓴다.
	//   ★ 근거(새 함정): **cwgen 은 `Type::상수` 형태의 참조만으로는 include 를 안 붙인다**
	//     ⇒ `MLTP3Ctx::kTime` 이라고 쓰면 `error: 'MLTP3Ctx' has not been declared` 가 난다
	//       (실측 · 회차 180). `MLTP2Cfg`·`MLTWorldCfg` 는 **다른 자리에서 타입으로도** 쓰여서 붙는다.
	//   ⚠️ 그래서 이 줄은 「같은 사실이 두 곳」의 **알려진 예외**다 — 8 이 아니게 되면 여기도 고친다.
	static constexpr uint32 kTime  = 8u;
	static constexpr int    kShapes = MLTWorldCfg::kShapes;
	// ⭐ 회차 180 — **눈금 둘**. 예측 ㉤ 이 *"칸이 너무 굵다"* 를 적었으니 같이 판정한다.
	static constexpr uint32 kPxMin  = 4u;                                    // 4픽셀 ⇒ 16×16 = 256칸
	inline static uint32 _px   = MLTP2Cfg::kPatch;   // 지금 눈금(8 또는 4)
	inline static uint32 _grid = MLTP2Cfg::kGrid;    // 8 또는 16
	inline static uint32 _cls  = MLTP2Cfg::kGrid * MLTP2Cfg::kGrid + 1u;
	static void _SetPx(uint32 px)
	{
		_px = px;
		_grid = (uint32)MLTWorldCfg::kSide / px;
		_cls = _grid * _grid + 1u;
	}
	static uint32 _None() { return _cls - 1u; }      // 마지막 계급 = 「화면에 없음」

	// ── ⭐ 회차 182 — **방향 모드**(`-mltdir`) ──────────────────
	//   회차 181 이 벽을 찾았다: **칸 번호가 불투명 정수라 몸통이 「37 과 38 이 인접」임을 모른다.**
	//   ⇒ ★ 표적을 「다음 **칸**」에서 「**이동 방향**」으로 바꾸면 그 벽이 **원리적으로** 사라진다
	//     (「지금 칸 + 방향 → 다음 칸」을 풀 필요가 없다 — 방향이 곧 답이다).
	//   ⇒ ⭐ 계급 **9**(0 = 정지 · 1..8 = 8방위) + 「없음」 = **10**
	//   ⚠️ **정지 문턱**이 이 모드의 눈금이다(180 에서 패치 눈금이 그랬던 자리).
	inline static bool  _dirOn = false;
	inline static float _dirThr = 0.25f;
	static constexpr uint32 kDirCls = 10u;           // 0=정지 · 1..8=8방위 · 9=없음
	static void _SetDir(bool on, float thr)
	{
		_dirOn = on; _dirThr = thr;
		if (on) { _cls = kDirCls; _px = 0u; _grid = 0u; }
	}
	// 직전 위치에서 방향 계급을 낸다 — ⚠️ 직전이 없으면 「정지」(0)로 둔다
	static uint32 _DirCls(const MLTShapeView& v, float pxv, float pyv, bool hadPrev)
	{
		const float S = (float)MLTWorldCfg::kSide;
		if (!(v.sx >= 0.0f && v.sx < S && v.sy >= 0.0f && v.sy < S)) return kDirCls - 1u;
		if (!hadPrev) return 0u;
		const float dx = v.sx - pxv, dy = v.sy - pyv;
		const float sp = Sqrt(dx * dx + dy * dy);
		if (sp < _dirThr) return 0u;                 // 정지
		float a = Atan2(dy, dx);                     // −π..π
		const float twoPi = 6.28318531f;
		if (a < 0.0f) a += twoPi;
		uint32 oct = (uint32)((a / twoPi) * 8.0f + 0.5f) % 8u;
		return 1u + oct;
	}

	// ══════════════════════════════════════════════════════════════════
	// ⭐ 회차 195 — 새 캔버스 `표적의 여지를 키운다`
	// ══════════════════════════════════════════════════════════════════
	//   ⚙️ **왜 이 자가 필요한가**: 194 가 `P3` 를 원리적으로 못 닫음을 손계산으로 확정했다 —
	//     `σ(CE−목표선) = 0.103` ⇒ 12씨앗 `t≥3` 에 필요한 `|d̄| = 0.089` 나트인데
	//     **입력 전체의 기여가 0.055 나트**(193)다 ⇒ ⛔ **표적에 여지가 없다.**
	//   ⇒ ★ 원인: `H(방향|직전) = 0.32`(182) — ***관성이 너무 강해 예측이 거의 자명하다.***
	//   ⇒ ⭐ 그래서 표적을 **「k스텝 뒤의 방향」**으로 옮긴다(규율 76).
	//
	//   ⭐ **그리고 여태 간접으로만 쟀던 「여지」를 학습 0 으로 직접 잰다**:
	//     ㉡ `H(방향_{t+k} | 방향_t)`            = 목표선(직전 방향만 아는 예측자)
	//     ㉢ `H(방향_{t+k} | 방향_t, 위치_t)`     = 위치까지 아는 예측자
	//     ⇒ ★ **여지 = ㉡ − ㉢** = ***「위치를 알면 더 맞히는 몫」*** = 비전이 기여할 여지
	//   ⇒ ⭐ 이것이 규율 49 를 제대로 하는 것이고, `k=1` 의 값이 **193 의 0.055** 와 만나면
	//     그 자가 **확인된다**(규율 68).
	//
	//   ⚠️⚠️⚠️ **미리 적는 함정** — 조건 칸이 많아지면 히스토그램이 비어서 조건부 `H` 가
	//     **인공적으로 0** 에 간다 ⇒ ⛔ 「여지」가 **가짜로** 커진다(규율 67 이 잡은 그 모양).
	//     ⇒ ★ 처방 둘을 **미리** 넣었다: ⭐ **위치 굵기를 팔로** 두고(굵으면 여지가 줄어야 정상)
	//       ⭐ **칸당 표본 수를 같이 찍는다.**
	inline static bool _kSweep = false;
	static constexpr uint32 kKs = 4u;
	static constexpr uint32 kKOf[kKs] = { 1u, 2u, 4u, 8u };
	static constexpr uint32 kKMax = 8u;
	static constexpr uint32 kGs = 3u;
	static constexpr uint32 kGOf[kGs] = { 2u, 4u, 8u };     // 위치 격자 한 변
	static constexpr uint32 kPosMax = 8u * 8u + 1u;         // 굵기 최대 + 「없음」
	// ⚠️ 세계를 이만큼 굴린다 — ★ 표본을 `t` 로 줄이지 않으려고(k 끼리 **같은 표본**이어야 한다)
	static constexpr uint32 kUMax = kTime + kKMax;          // 16 ⇒ 상태 0..16
	// [k][g][지금방향][지금위치][나중방향]
	inline static Array<uint32> _h3;
	static uint32 _H3Ix(uint32 ki, uint32 gi, uint32 dn, uint32 pn, uint32 df)
	{
		return (((ki * kGs + gi) * kDirCls + dn) * kPosMax + pn) * kDirCls + df;
	}
	// ⭐ 위치 굵은 칸 — 화면 밖이면 마지막 칸(「없음」)
	static uint32 _PosCls(float sx, float sy, uint32 g)
	{
		const float S = (float)MLTWorldCfg::kSide;
		if (!(sx >= 0.0f && sx < S && sy >= 0.0f && sy < S)) return g * g;
		uint32 gx = (uint32)((sx / S) * (float)g); if (gx >= g) gx = g - 1u;
		uint32 gy = (uint32)((sy / S) * (float)g); if (gy >= g) gy = g - 1u;
		return gy * g + gx;
	}
	// ⭐ 방향 계급 — `_DirCls` 와 **같은 식**이어야 한다(같은 사실이 두 곳이면 한쪽이 진다)
	//   ⚠️ 여기서는 뷰가 아니라 **저장한 좌표**에서 낸다(k스텝 뒤를 봐야 하므로).
	static uint32 _DirOf(float sx, float sy, float px0, float py0, bool okNow, bool okPrev)
	{
		if (!okNow) return kDirCls - 1u;               // 화면에 없다
		if (!okPrev) return 0u;                        // 직전이 없으면 「정지」
		const float dx = sx - px0, dy = sy - py0;
		const float sp = Sqrt(dx * dx + dy * dy);
		if (sp < _dirThr) return 0u;
		float a = Atan2(dy, dx);
		const float twoPi = 6.28318531f;
		if (a < 0.0f) a += twoPi;
		const uint32 oct = (uint32)((a / twoPi) * 8.0f + 0.5f) % 8u;
		return 1u + oct;
	}

	// ⭐ 조건부 엔트로피 셋을 한 히스토그램에서 뽑는다
	//   `chgOnly` = **변화만**(나중 ≠ 지금) — 몸통의 채점과 같게 보려면 이쪽이다
	struct KRes
	{
		double h = 0.0;        // ㉠ H(나중)
		double hcD = 0.0;      // ㉡ H(나중 | 지금방향)
		double hcDP = 0.0;     // ㉢ H(나중 | 지금방향, 위치)
		double room = 0.0;     // ⭐ 여지 = ㉡ − ㉢
		double noneFrac = 0.0; // 「없음」계급 몫
		double perCell = 0.0;  // 찬 칸당 표본 수
		uint32 cellsUsed = 0u;
		uint32 tot = 0u;
	};
	static void _KStat(uint32 ki, uint32 gi, bool chgOnly, KRes& r)
	{
		const uint32 g = kGOf[gi];
		const uint32 nPos = g * g + 1u;
		r = KRes();
		// ── 전체 합과 나중 방향 주변분포
		double mF[kDirCls]; for (uint32 i = 0; i < kDirCls; ++i) mF[i] = 0.0;
		uint32 tot = 0u, noneN = 0u;
		for (uint32 dn = 0; dn < kDirCls; ++dn)
			for (uint32 pn = 0; pn < nPos; ++pn)
				for (uint32 df = 0; df < kDirCls; ++df)
				{
					if (chgOnly && df == dn) continue;
					const uint32 n = _h3[_H3Ix(ki, gi, dn, pn, df)];
					if (n == 0u) continue;
					mF[df] += (double)n; tot += n;
					if (df == kDirCls - 1u) noneN += n;
				}
		if (tot == 0u) return;
		r.tot = tot;
		r.noneFrac = (double)noneN / (double)tot;
		const double N = (double)tot;
		for (uint32 i = 0; i < kDirCls; ++i)
		{
			if (mF[i] <= 0.0) continue;
			const double p = mF[i] / N;
			r.h += -p * (double)Log((float)p);
		}
		// ── ㉡ 지금 방향으로만 조건
		for (uint32 dn = 0; dn < kDirCls; ++dn)
		{
			double row[kDirCls]; for (uint32 i = 0; i < kDirCls; ++i) row[i] = 0.0;
			double rs = 0.0;
			for (uint32 pn = 0; pn < nPos; ++pn)
				for (uint32 df = 0; df < kDirCls; ++df)
				{
					if (chgOnly && df == dn) continue;
					const double n = (double)_h3[_H3Ix(ki, gi, dn, pn, df)];
					row[df] += n; rs += n;
				}
			if (rs <= 0.0) continue;
			double hp = 0.0;
			for (uint32 i = 0; i < kDirCls; ++i)
			{
				if (row[i] <= 0.0) continue;
				const double p = row[i] / rs;
				hp += -p * (double)Log((float)p);
			}
			r.hcD += (rs / N) * hp;
		}
		// ── ㉢ 지금 방향 + 위치로 조건 ⚠️ 여기가 표본을 쪼개는 자리다
		uint32 used = 0u;
		for (uint32 dn = 0; dn < kDirCls; ++dn)
			for (uint32 pn = 0; pn < nPos; ++pn)
			{
				double row[kDirCls]; for (uint32 i = 0; i < kDirCls; ++i) row[i] = 0.0;
				double rs = 0.0;
				for (uint32 df = 0; df < kDirCls; ++df)
				{
					if (chgOnly && df == dn) continue;
					const double n = (double)_h3[_H3Ix(ki, gi, dn, pn, df)];
					row[df] += n; rs += n;
				}
				if (rs <= 0.0) continue;
				++used;
				double hp = 0.0;
				for (uint32 i = 0; i < kDirCls; ++i)
				{
					if (row[i] <= 0.0) continue;
					const double p = row[i] / rs;
					hp += -p * (double)Log((float)p);
				}
				r.hcDP += (rs / N) * hp;
			}
		r.cellsUsed = used;
		r.perCell = (used == 0u) ? 0.0 : N / (double)used;
		r.room = r.hcD - r.hcDP;
	}

	// ── 세계 점 — ⭐ 회차 172 의 표 **8점 전부**(`mltl1q0` 의 그 표를 옮긴다) ──
	//   ⚠️ 같은 사실이 두 곳에 살면 한쪽이 진다 ⇒ 값은 그 표와 **같아야 한다**(회차 164·172).
	static constexpr uint32 kPts = 8u;
	static constexpr float kPtDt[kPts]  = { 1.00f, 1.00f, 1.00f, 0.25f, 0.25f, 1.00f, 0.001f, 0.001f };
	static constexpr float kPtAmp[kPts] = { 1.00f, 2.50f, 5.00f, 1.00f, 5.00f, 1.00f, 0.00f,  5.00f  };
	static const char* _PtName(uint32 i)
	{
		if (i == 0u) return "㈀ 기본";
		if (i == 1u) return "㈁ amp2.5";
		if (i == 2u) return "㈂ amp5";
		if (i == 3u) return "㈃ dt.25";
		if (i == 4u) return "㈄ dt.25amp5";
		if (i == 5u) return "㈅ 기본b";
		if (i == 6u) return "㈆ 정지";
		return "㈇ 172세계";
	}
	struct Pt { float dt; float amp; int hold; };
	static Pt _Pt(uint32 i)
	{
		const uint32 k = (i < kPts) ? i : 0u;
		return Pt{ kPtDt[k], kPtAmp[k], MLTWorldCfg::kHoldMid };
	}
	// ⛔⛔⛔ **회차 220 이 측정 0 으로 잡았다 — 두 하네스가 「다른 세계」를 보고 있었다.**
	//   ```
	//   mltl1t0(학습)   `_Dt()` = **1.00**(방향 모드) · `_Amp()` = **5.0**   ← 칸 1·2 가 돈 자리
	//   mltl1s0(학습 0) `_Pt(3)` = dt **0.25** · amp **1.0**                ← 214·215·216·218 이 쓴 자리
	//   ```
	//   ⇒ ⛔ 그래서 214 가 *"궤도의 행동 여지 2.0% ⇒ 거의 0"* 이라고 냈는데
	//     **진짜 자리(dt 1.0)에서는 27.4%** 다 ⇒ ⇒ ***결론 셋이 뒤집혔다***(214·216·218).
	//   ⇒ ★ **규율 65 의 교과서 사례**다(*"예산은 그 자리의 σ"* — 자리가 달랐다).
	//   ⇒ ⭐ **처방은 구조다**: 학습 하네스가 쓰는 값을 **여기 이름으로 박고** 새 자들이 그것을 쓴다.
	//     ⚠️⚠️ **197·198 의 자(`_RunC`/`_RunW2`)는 안 건드린다** — 그쪽은 `_Pt(3)` 로 이미
	//       판정이 났고 바꾸면 **규율 58 위반**(자를 바꾸는 것)이다.
	static constexpr float kTrDt  = 1.00f;   // = `mltl1t0::_Dt()`  (방향 모드)
	static constexpr float kTrAmp = 5.00f;   // = `mltl1t0::_Amp()`
	// ⭐ 새 자(214~)의 기준점 — ***학습 하네스와 같은 세계***
	static Pt _PtTrain() { return Pt{ kTrDt, kTrAmp, MLTWorldCfg::kHoldMid }; }

	// ── 한 물체의 칸 번호 — ⚠️ 화면 밖이면 「없음」 ────────────────────
	static uint32 _Cell(const MLTShapeView& v)
	{
		const float S = (float)MLTWorldCfg::kSide;
		if (!(v.sx >= 0.0f && v.sx < S && v.sy >= 0.0f && v.sy < S)) return _None();
		const uint32 gx = (uint32)v.sx / _px;
		const uint32 gy = (uint32)v.sy / _px;
		return gy * _grid + gx;
	}

	struct Acc
	{
		double visSum = 0.0; uint32 visN = 0u; int visMin = 999, visMax = -1;
		double chgSum = 0.0;              // 문맥당 변화 표적 수
		double tgtSum = 0.0;              // 문맥당 전체 표적 수(보이는 물체 × 시각)
		uint32 autoSeen = 0u, passSeen = 0u;
		// 결합 히스토그램 [지금 칸][다음 칸] — ⑤ 의 재료
		Array<uint32> jt;
		uint32 tot = 0u;
		void Begin()
		{
			jt.Reset(0);
			for (uint32 i = 0; i < _cls * _cls; ++i) jt.Add(0u);
			visSum = 0.0; visN = 0u; visMin = 999; visMax = -1;
			chgSum = 0.0; tgtSum = 0.0; autoSeen = 0u; passSeen = 0u; tot = 0u;
		}
	};

	// ── ⭐ 회차 181 이 요구한 자 — **변화 표적만**의 `H(다음 | 지금)` ──
	//   ⚠️⚠️ 회차 181 이 배관①(규율 68)에서 **1.3341 ↔ 0.3678** 로 어긋났다.
	//     ⇒ ★ 손계산이 답을 줬다: **둘 다 맞고 「다른 것」을 잰다.**
	//        180 의 ⑤ 는 **전체 표적**(지속 87.7 + 변화 10.3)이고 지속은 「다음 = 지금」이라
	//        조건부 엔트로피 기여가 ≈ 0 이다 ⇒ 값이 변화율만큼 **희석된다**.
	//        181 은 **변화만 채점**하므로 목표선도 변화만이어야 한다.
	//   ⇒ ⭐ 그래서 이 함수를 **같이** 찍는다 — 그것이 181 의 배관 문턱이다(규율 68 을 제대로).
	static void _EntChg(const Acc& a, double& oHc)
	{
		oHc = 0.0;
		Array<uint32> mp; mp.Reset(0);
		for (uint32 i = 0; i < _cls; ++i) mp.Add(0u);
		uint32 tot = 0u;
		for (uint32 p = 0; p < _cls; ++p)
			for (uint32 q = 0; q < _cls; ++q)
			{
				if (p == q) continue;                 // ⚠️ 지속 제외 — 채점하는 자와 같게
				const uint32 n = a.jt[p * _cls + q];
				if (n == 0u) continue;
				mp.Data()[p] += n; tot += n;
			}
		if (tot == 0u) return;
		const double N = (double)tot;
		for (uint32 p = 0; p < _cls; ++p)
		{
			if (mp[p] == 0u) continue;
			const double Np = (double)mp[p];
			double hp = 0.0;
			for (uint32 q = 0; q < _cls; ++q)
			{
				if (p == q) continue;
				const uint32 n = a.jt[p * _cls + q];
				if (n == 0u) continue;
				const double pr = (double)n / Np;
				hp += -pr * (double)Log((float)pr);
			}
			oHc += (Np / N) * hp;
		}
	}

	// ── ⑤ `H(다음)` 와 `H(다음 | 지금)` ────────────────────────────────
	static void _Ent(const Acc& a, double& oH, double& oHc)
	{
		oH = 0.0; oHc = 0.0;
		if (a.tot == 0u) return;
		const double N = (double)a.tot;
		Array<uint32> mn; mn.Reset(0);
		for (uint32 i = 0; i < _cls; ++i) mn.Add(0u);
		Array<uint32> mp; mp.Reset(0);
		for (uint32 i = 0; i < _cls; ++i) mp.Add(0u);
		for (uint32 p = 0; p < _cls; ++p)
			for (uint32 q = 0; q < _cls; ++q)
			{
				const uint32 n = a.jt[p * _cls + q];
				if (n == 0u) continue;
				mp.Data()[p] += n; mn.Data()[q] += n;
			}
		for (uint32 q = 0; q < _cls; ++q)
		{
			if (mn[q] == 0u) continue;
			const double p = (double)mn[q] / N;
			oH += -p * (double)Log((float)p);
		}
		for (uint32 p = 0; p < _cls; ++p)
		{
			if (mp[p] == 0u) continue;
			const double Np = (double)mp[p];
			double hp = 0.0;
			for (uint32 q = 0; q < _cls; ++q)
			{
				const uint32 n = a.jt[p * _cls + q];
				if (n == 0u) continue;
				const double pr = (double)n / Np;
				hp += -pr * (double)Log((float)pr);
			}
			oHc += (Np / N) * hp;
		}
	}

	// ══════════════════════════════════════════════════════════════════
	// ⭐ 회차 195 — k스텝 표적의 수집 + 판정
	// ══════════════════════════════════════════════════════════════════
	//   ⚠️ 세계 점은 **㉃ dt.25**(`kPtDt[3]`)로 고정한다 — ★ 몸통(`mltl1t0`)이 방향 모드에서
	//     쓰는 그 세계여야 규율 68·76 으로 견줄 수 있다(`_Dt()` 가 방향 모드에서 0.25 를 준다).
	// ══════════════════════════════════════════════════════════════════
	// ⭐ 회차 197 — 🆕 칸 2 · 상위 캔버스 `칸 2 의 분모를 세운다`
	// ══════════════════════════════════════════════════════════════════
	//   ⚠️⚠️ 195 는 **위치 하나**만 조건에 넣어 여지 3% 를 냈고 196 이 세계 점 8개 전부에서
	//     같음을 확인했다 ⇒ ⛔ *"이 세계에 여지가 없다"* 로 읽었다.
	//   ⚠️⚠️⚠️ **그런데 그 결론은 「위치」에 대한 것이다.** 몸통이 보는 것은 그것만이 아니다 —
	//     ⭐ **여러 시각의 역사** · 깊이 · 다른 물체를 **한 번도 안 쟀다.**
	//   ⇒ ⭐ 그리고 **역사가 가장 유력하다**: 회차 192 가 *"몸통이 최근 **4시각**을 쓴다"* 를
	//     실측했다(`tCut` 8~5 평평 · 4 부터 오름) ⇒ ★ 몸통이 **쓰고 있는데 우리가 안 잰 것**이다.
	//
	//   ⚠️⚠️ **조건을 쌓으면 히스토그램이 빈다**(195 가 미리 적은 함정이 여기서 훨씬 심하다)
	//     ⇒ ★ 처방 셋: ⭐ 역사 팔은 **방향을 4분위로 뭉친다** · ⭐ 위치는 **2×2** ·
	//       ⭐ **음성 대조 팔**(무작위 조건 = 결정적 해시) ⇒ ***그 팔의 여지가 곧 편향 바닥***이다.
	inline static bool _cSweep = false;
	// ⚠️ 회차 229 — 8 → **12**(흐름 표적 스윕이 표적 넷 × 조건 셋을 쓴다).
	//   ★ 늘려도 기존 판은 무변경이다 — `_hc` 배열 크기와 로컬 배열 몇 개만 커진다.
	static constexpr uint32 kCArms = 12u;
	static const char* _CArmName(uint32 a)
	{
		if (a == 0u) return "㈀ 지금방향(분모)        ";
		if (a == 1u) return "㈁ +직전방향(2시각)      ";
		if (a == 2u) return "㈂ +4시각 역사 ⭐      ";
		if (a == 3u) return "㈃ +위치 2x2             ";
		if (a == 4u) return "㈄ +깊이 계급            ";
		if (a == 5u) return "㈅ +가까운 물체의 방향   ";
		if (a == 6u) return "㈆ +4시각 역사 + 위치 ⭐ ";
		return "㉯ 무작위 조건(편향 바닥)";
	}
	// ⭐ 팔마다 조건 칸 수 — ⚠️ 역사 팔은 방향을 **4분위**로 뭉친다(0=정지·1..3)
	static constexpr uint32 kQ4 = 4u;          // 뭉친 방향 계급(정지 + 3 + 없음은 3 에 접는다)
	static uint32 _Q4(uint32 d)
	{
		if (d == 0u) return 0u;                        // 정지
		if (d == kDirCls - 1u) return 3u;              // 없음 ⇒ 3 에 접는다
		return 1u + ((d - 1u) / 3u);                   // 1..8 ⇒ 1·2·3
	}
	// ══════════════════════════════════════════════════════════════════
	// ⭐ 회차 214 — **행동의 여지**(칸 3 · `P4`)를 **학습 0** 으로 먼저 잰다
	// ══════════════════════════════════════════════════════════════════
	//   ⚙️ 공용 **규율 12** 가 이 자리를 가리킨다: *"처방을 돌리기 전에 「여지」를 학습 0 으로 재라."*
	//     ⇒ 행동 축을 하네스에 넣는 것은 **비싸고**(축이 늘면 189 실측으로 `P3` 이 +4.6%p 나빠진다)
	//       ***그 전에 「행동이 표적에 대해 무엇을 아는가」를 재면 헛도는 회차를 막는다.***
	//   ⚠️⚠️ **자를 안 바꾼다**(규율 58) — 197·198 의 `_CStat`(조건 여지)을 **그대로** 쓰고
	//     팔 표만 갈아 끼운다. ⇒ ★ 그래야 「행동의 여지」가 **「깊이의 여지」와 같은 눈금**이 된다.
	//   ⭐ 음성 대조(무작위 조건)를 **같은 칸 수로** 둔다 — 규율 2 · 공용 14.
	inline static bool _aSweep = false;
	// ⭐ 행동 계급 — 화면을 지배하는 두 성분(**좌우 회전** `dYaw` · **전후진** `fwd`)을 3칸씩
	//   ⚠️⚠️ **이것은 「상수로 둔 것」이다**(공용 규율 7-a) — 다섯 성분 중 둘을 고른 근거는
	//     *"화면 흐름을 지배할 것"* 이라는 **손계산이고 측정이 아니다.**
	//   ★ 그래도 둘로 좁힌 근거는 있다: **211a 가 「자리 1」로 `t` 를 1.28 → 4.37 로 세웠다**
	//     (통로를 좁히는 것이 이겼다) · 그리고 칸 수가 늘면 **빈 칸 편향**이 부푼다(위 ⚠️).
	static constexpr uint32 kActCls = 9u;
	static uint32 _ActCls(const MLTAct& a)
	{
		// ⚠️ 성분마다 진폭이 다르다(`_PickAct`: fwd ×1.0 · dYaw ×0.6) ⇒ **자기 진폭의 1/3** 로 나눈다
		const float ty = 0.6f / 3.0f, tf = 1.0f / 3.0f;
		const uint32 by = (a.dYaw < -ty) ? 0u : ((a.dYaw > ty) ? 2u : 1u);
		const uint32 bf = (a.fwd  < -tf) ? 0u : ((a.fwd  > tf) ? 2u : 1u);
		return by * 3u + bf;
	}
	// ⭐ 회차 215 — **계급을 다시 나눈다**(214 의 갈래 ㈂)
	//   ⚙️ 물음: *"「가름 47.5%」와 「여지 2.0%」의 격차가 **계급 탓**인가?"*
	//   ★ 214 의 하네스가 스스로 찍었다: *"「가름」이 크고 「여지」가 작으면 계급을 잘못 나눈 것"*
	//   ⇒ ⭐ **천장을 먼저 계산한다**(규율 49) — 계급을 아무리 쪼개도 안 오르면 계급 탓이 아니다.
	//   ⚠️ 「상수로 둔 것」: 천장을 **54계급**(`dYaw`3 × `fwd`3 × `side`3 × `dPitch`2)으로 끊었다.
	//     `up` 을 뺀 근거는 *"수직 이동이 화면 흐름에 가장 덜 기여할 것"* 이라는 **손계산이다.**
	//     (칸 수 상한 `kCondMax` 800 ⇒ 10 × 54 = 540 이 들어간다. 243 이면 2430 이라 못 넣는다.)
	inline static bool _a2 = false;
	static constexpr uint32 kActFine = 54u;
	static uint32 _ActFine(const MLTAct& a)
	{
		// ⚠️ 성분마다 진폭이 다르다(`_PickAct`) ⇒ **자기 진폭의 1/3** 로 나눈다
		const float ty = 0.6f / 3.0f, tf = 1.0f / 3.0f, ts = 0.7f / 3.0f;
		const uint32 by = (a.dYaw   < -ty) ? 0u : ((a.dYaw   > ty) ? 2u : 1u);
		const uint32 bf = (a.fwd    < -tf) ? 0u : ((a.fwd    > tf) ? 2u : 1u);
		const uint32 bs = (a.side   < -ts) ? 0u : ((a.side   > ts) ? 2u : 1u);
		const uint32 bp = (a.dPitch < 0.0f) ? 0u : 1u;
		return ((by * 3u + bf) * 3u + bs) * 2u + bp;
	}
	// ⭐ `dYaw` 만 아홉으로 — *"좌우 팬이 화면 흐름을 지배할 것"* 을 **좁은 통로로** 시험한다
	//   ★ 211a 의 교훈(자리 1 이 이겼다)이 여기서도 참인지 본다
	static uint32 _ActYaw9(const MLTAct& a)
	{
		float v = a.dYaw / 0.6f;                 // [-1, 1] 로 정규화
		if (v < -1.0f) v = -1.0f; if (v > 1.0f) v = 1.0f;
		int b = (int)((v + 1.0f) * 4.5f);        // 0..9
		if (b < 0) b = 0; if (b > 8) b = 8;
		return (uint32)b;
	}
	static const char* _AArmName(uint32 a)
	{
		if (_a2)
		{
			if (a == 0u) return "㈀ 직전방향만(분모) ";
			if (a == 1u) return "㈁ 행동 9(214 재현) ";
			if (a == 2u) return "㈂ dYaw 만 9        ";
			if (a == 3u) return "⭐ ㈃ **천장** 54  ";
			if (a == 4u) return "⭐ ㈄ **자율만 방향**";
			if (a == 5u) return "㈅ 무작위 54(음성)  ";
			if (a == 6u) return "㈆ 무작위 10(음성)  ";
			return "㈇ 깊이 4(견줌)     ";
		}
		if (a == 0u) return "㈀ 직전방향만(분모)";
		if (a == 1u) return "⭐ ㈁ +**행동**    ";
		if (a == 2u) return "㈂ +무작위(음성)  ";
		if (a == 3u) return "㈃ +깊이(198 최고)";
		if (a == 4u) return "㈄ +행동+깊이     ";
		return "㈅ +직전직전(2시각)";
	}
	// ══════════════════════════════════════════════════════════════════
	// ⭐ 회차 218 — **행동 여지와 언어 여지를 같은 눈금으로 한 판에**
	// ══════════════════════════════════════════════════════════════════
	//   ⚙️ 217 이 냈다: 가속 세계에서 **캡션의 순 `Î` = 0.0000** ⇒ ***언어가 죽는다.***
	//     ⇒ ⛔ 그런데 216 은 **행동 여지만** 재고 처방을 냈다 ⇒ 🧾 ***한 축을 키우려고 세계를
	//       고치면 다른 축이 그만큼 죽는지 먼저 재라.*** ⇒ ⭐ 이 회차가 그것을 갚는다.
	//   ⭐ **캡션의 정의는 `mltl1t0` 그대로다**(규율 58 — 자를 안 바꾼다):
	//     *"다음 시각에 **계급이 바뀌는** 슬롯 번호"*(번호 작은 순 · 자리 수만큼 · 방향값은 **안 넣는다**)
	//   ⚠️ 「상수로 둔 것」: 학습 하네스는 **보이는 것 중 번호 작은 8개**를 슬롯으로 쓰는데
	//     여기서는 **도형 번호 그대로** 쓴다(근사). ★ 자리 1 의 「첫 바뀌는 것」 모양은 같다.
	inline static bool _a3 = false;
	// ⭐ 회차 226 — **상쇄의 천장**을 학습 0 으로 먼저 잰다(`-mltself`)
	//   ⚙️ 사람이 잡았다: *"과도한 자기 사본 처리가 오히려 **타자와 엮어야 할 것**을 방해할까"*
	//     ⇒ ★ 표적이 **타자(자율 물체)의 방향**인데 **자기 성분 예측**에 손실을 주면 예산을 먹는다
	//     ⇒ ⭐ 공용 규율 **18-a** 가 그것이다 — ***자기 처리를 늘리면 타자 처리 예산이 준다***
	//   ⇒ ★★ 그래서 손실을 넣기 전에 **천장**을 잰다(규율 12·49) — 그리고
	//     ***타자 쪽 자를 같은 분모로 같은 판에*** 둔다(규율 13).
	//   ⭐ 팔: ㈀ 분모 · ㈁ **미래 흐름**(사본의 천장) · ㈂ **과거 흐름**(공짜로 아는 것) ·
	//     ㈃ 음성10 · ㈄ 깊이(타자) · ㈅ 캡션천장(타자) · ㈆ 음성4 · ㈇ 음성2
	//   ⇒ ⭐⭐ **순 사본 천장 = ㈁ − ㈂** ⇒ *"내 행동이 만들 흐름을 **미리** 아는 것의 순 가치"*
	//     ⚠️ ㈁ 은 **미래를 안다**고 가정한 것이라 **천장**이다(실제 모델은 행동값에서 추정해야 한다).
	inline static bool _a4 = false;
	// ⭐ 회차 229 — **흐름 표적의 형태를 고른다**(`-mltflow` · 228 의 갈래 ㈁)
	//   ⚙️ 228 이 λ0.03 에서 `t` 1.29 · 8/12 로 **판정불가**를 냈고 필요 씨앗이 **65** 였다
	//     ⇒ 씨앗은 **선형**으로 비싸고 효과는 **제곱**으로 싸다(`d̄` 2배 ⇒ 씨앗 1/4)
	//     ⇒ ★ 그래서 **효과를 키우는 쪽**이 싸다. ⚠️ 그런데 어느 형태가 큰지 **모르고 고르면**
	//       다른 자리에서 또 판정불가다 ⇒ 규율 **49·12**: 재기 전에 **천장을 학습 0 으로**.
	//   🔬 가설(⚠️ **근거가 아니다** — 공용 규율 18): 지금 흐름 표적은 **방향 10 계급**이고
	//     **크기를 버린다**. 그런데 `dYaw` 는 연속이고 흐름 **속력**과 거의 선형이다
	//     ⇒ ⭐ ***지금 표적이 행동값의 「부호」만 쓰고 있을 수 있다.***
	//   🎯 표적 넷 — ⭐ **전부 10칸**으로 맞춘다(빈 칸 편향을 같게 ⇒ 규율 13):
	//     Ⓐ 흐름 **방향**(지금 것) · Ⓑ 흐름 **속력**(8분위) · Ⓒ **방향4 × 속력2** ·
	//     Ⓓ **자율 물체 방향**(⭐ **타자** 자 — 규율 18-a ㈁ · 218 의 그 표적 그대로)
	//   📐 자 = 순 여지 비 `( H(T|음성9) − H(T|dYaw9) ) ÷ H(T)`
	//     ⚠️ 음성 짝은 **같은 칸 수**(규율 14) · 분모는 **그 표적 자신의 정보량**(규율 67)
	//   ⚠️⚠️ ***여지가 있다고 몸통이 쓴다는 뜻이 아니다***(규율 69) — 이 판은 **상한만** 준다.
	inline static bool _a5 = false;
	static uint32 _CondN(uint32 a)
	{
		// ⭐ 229 — 표적 넷 × 조건 셋(무 · `dYaw` 9 · 음성 9). ★ 조건 칸 수는 표적과 무관하다
		if (_a5) return ((a % 3u) == 0u) ? 1u : 9u;
		// ⭐ 226 — 자기(흐름) ↔ 타자(깊이·캡션)를 **같은 분모**로
		if (_a4)
		{
			if (a == 0u) return kDirCls;                 // 10  — 분모
			if (a == 1u) return kDirCls * kDirCls;       // 100 — ⭐ 미래 흐름(사본 천장)
			if (a == 2u) return kDirCls * kDirCls;       // 100 — 과거 흐름(공짜)
			if (a == 3u) return kDirCls * kDirCls;       // 100 — ★ ㈁·㈂ 의 음성 짝
			if (a == 4u) return kDirCls * 4u;            // 40  — 깊이(타자)
			if (a == 5u) return kDirCls * 2u;            // 20  — 캡션 천장(타자)
			if (a == 6u) return kDirCls * 4u;            // 40  — ★ ㈄ 의 음성 짝
			return kDirCls * 2u;                         // 20  — ★ ㈅ 의 음성 짝
		}
		// ⭐ 218 — 행동 ↔ 언어를 **같은 분모**로(공용 규율 87)
		if (_a3)
		{
			if (a == 0u) return kDirCls;             // 10  — 분모
			if (a == 1u) return kDirCls * 9u;        // 90  — ⭐ 행동(`dYaw` 9 · 215 가 최고라고 냈다)
			if (a == 2u) return kDirCls * 9u;        // 90  — ★ ㈁ 의 음성 짝
			if (a == 3u) return kDirCls * 2u;        // 20  — ⭐ 캡션 자리 1(첫 바뀌는 물체인가)
			if (a == 4u) return kDirCls * 2u;        // 20  — ⭐ 캡션 천장(바뀌나 · 자리 무한)
			if (a == 5u) return kDirCls * 2u;        // 20  — ★ ㈃·㈄ 의 음성 짝
			return kDirCls * 4u;                     // 40  — 깊이(견줌)
		}
		// ⭐ 215 — 계급 스윕. ⚠️ **음성 대조는 짝과 「같은 칸 수」여야 한다**(공용 규율 14)
		if (_a2)
		{
			if (a == 0u) return kDirCls;                       // 10
			if (a == 1u) return kDirCls * kActCls;             // 90  — 214 재현(배관)
			if (a == 2u) return kDirCls * 9u;                  // 90  — dYaw 만
			if (a == 3u) return kDirCls * kActFine;            // 540 — ⭐ 천장
			if (a == 4u) return kDirCls * kDirCls;             // 100 — ⭐ 자율만 방향
			if (a == 5u) return kDirCls * kActFine;            // 540 — ★ ㈃ 의 음성 짝
			if (a == 6u) return kDirCls * kDirCls;             // 100 — ★ ㈄ 의 음성 짝
			return kDirCls * 4u;                               // 40  — 깊이
		}
		// ⭐ 214 — 행동 스윕은 **팔 표만** 다르다(자는 같다)
		if (_aSweep)
		{
			if (a == 0u) return kDirCls;                       // 10
			if (a == 1u) return kDirCls * kActCls;             // 90  — (d0, 행동)
			if (a == 2u) return kDirCls * kActCls;             // 90  — ★ ㈁ 과 **같은 칸 수**
			if (a == 3u) return kDirCls * 4u;                  // 40  — (d0, 깊이)
			if (a == 4u) return kDirCls * kActCls * 4u;        // 360 — (d0, 행동, 깊이)
			return kDirCls * kQ4;                              // 40  — (d0, q1)
		}
		// ⚠️ **칸 수를 정확히 쓴다** — 남는 칸이 있으면 「빈 칸 편향」이 그만큼 부푼다
		//   ⛔ 처음에 ㈂ 를 640(= 10×4³)으로 잡았는데 조건은 **(d0, q1, q2) = 160** 이다
		//     (4시각 역사 = 방향 **셋**이고 그것이 위치 넷을 덮는다) ⇒ 빈 칸이 4배였다.
		if (a == 0u) return kDirCls;                  // 10
		if (a == 1u) return kDirCls * kQ4;            // 40   — (d0, q1)
		if (a == 2u) return kDirCls * kQ4 * kQ4;      // 160  — (d0, q1, q2) = 4시각
		if (a == 3u) return kDirCls * 5u;             // 50   — (d0, 위치 2x2+없음)
		if (a == 4u) return kDirCls * 4u;             // 40   — (d0, 깊이 4분위)
		if (a == 5u) return kDirCls * kQ4;            // 40   — (d0, 가까운 물체 방향)
		if (a == 6u) return kDirCls * kQ4 * kQ4 * 5u; // 800  — (d0, q1, q2, 위치)
		return kDirCls * kQ4 * kQ4;                   // ㉯ 160 — ★ ㈂ 와 **같은 칸 수**여야 한다
	}
	static constexpr uint32 kCondMax = 800u;
	// [팔][조건][나중방향]
	inline static Array<uint32> _hc;
	static uint32 _HcIx(uint32 a, uint32 cn, uint32 df)
	{
		return (a * kCondMax + cn) * kDirCls + df;
	}
	// ⭐ 깊이 4분위 — ⚠️ **문턱을 손으로 박지 않는다**(깊이 범위를 모른다 ⇒ 분위가 무너진다)
	//   ★ 데이터에서 뽑는다: 사전 스캔으로 히스토그램을 만들고 25/50/75 백분위를 문턱으로 쓴다.
	//   ⚠️ 문턱은 **판정문에 찍는다** — 그것이 이 팔의 눈금이다(180 의 패치 눈금과 같은 자리).
	static constexpr uint32 kDepBins = 1024u;
	static constexpr float  kDepMax  = 512.0f;
	inline static float _depThr[3] = { 0.0f, 0.0f, 0.0f };
	static uint32 _DepCls(float dep)
	{
		if (dep < _depThr[0]) return 0u;
		if (dep < _depThr[1]) return 1u;
		if (dep < _depThr[2]) return 2u;
		return 3u;
	}
	// ⭐⭐ 회차 230 — 📌 **D42 를 갚는 인자 둘**(⚠️ 기본값은 **옛 동작 그대로**다 — 규율 58)
	//   ⛔ 229 가 잡았다: 이 함수는 `_Pt(3)`(dt 0.25 · amp 1.0)로 문턱을 뽑는데
	//     `_FillA` 는 **`_PtTrain()`(dt 1.00 · amp 5.0)** 을 쓰고 `SetWorld2` 도 부른다
	//     ⇒ ⚠️⚠️ ***깊이 계급의 눈금이 「그 판이 도는 세계」가 아닌 곳에서 정해졌다.***
	//     ⇒ ★ **220 이 고친 바로 그 사고**이고(그때 결론 셋이 뒤집혔다) 여기 한 자리에 남아 있었다.
	//   ⇒ ⭐ `trainPt` 를 켜면 **그 판이 도는 세계**에서 뽑는다. `w2 >= 0` 이면 세계 종류도 맞춘다.
	//     ⚠️ 옛 호출은 인자를 안 주므로 **218·226 은 재실행해도 같은 값**이 나온다.
	// ⭐⭐ 회차 231 — 📌 **D43**: 눈금이 실제 범위보다 **~170배** 크다
	//   ⛔ 230 이 손계산으로 잡았다: `kDepMax` 512 ÷ `kDepBins` 1024 = **bin 폭 0.5px** 인데
	//     문턱이 **1.00/2.00/2.50** 이다 ⇒ ★★ ***1024칸 중 여섯 칸만 쓴다.***
	//   ⇒ ⚠️⚠️ 그래서 230 의 *"두 문턱이 같다"* 가 **「같다」인지 「못 가른다」인지 구별이 안 된다**
	//     (공용 규율 **13-a** — 「같다」를 주장할 때는 **예산을 효과와 견주어라**. 예산이 20~50% 였다).
	//   ⇒ ⭐ `fine` 이면 **2패스**로 간다: 1패스가 **옛 눈금 그대로** 돌아 관측 최대값을 읽고
	//     2패스가 **그 범위에** 히스토그램을 다시 깐다 ⇒ ***자가 데이터를 따라간다***(손으로 안 박는다).
	//   ★ 그리고 1패스가 옛 동작이라 **배관 확인이 저절로 된다**(거친 문턱이 재현돼야 한다).
	inline static float  _depObsMax = 0.0f;   // 관측 최대 깊이(판정문에 찍는다)
	inline static uint32 _depTot    = 0u;     // 스캔 표본 수
	static void _DepQuartiles(uint32 ptIx, int autoN, bool trainPt = false, int w2 = -1, bool fine = false)
	{
		const Pt pt = trainPt ? _PtTrain() : _Pt(ptIx);
		const float useDt  = trainPt ? (((_dtOv  >= 0.0f) ? _dtOv  : pt.dt))  : pt.dt;
		const float useAmp = trainPt ? (((_ampOv >= 0.0f) ? _ampOv : pt.amp)) : pt.amp;
		Array<uint32> h;
		float scale = kDepMax;
		const uint32 nPass = fine ? 2u : 1u;
		for (uint32 pass = 0; pass < nPass; ++pass)
		{
			h.Reset(0);
			for (uint32 i = 0; i < kDepBins; ++i) h.Add(0u);
			uint32 tot = 0u;
			// ⚠️ 씨앗 둘만 스캔한다 — 문턱은 **분포의 모양**이라 전수가 필요 없다
			for (uint32 s = 0; s < 2u && s < kSeeds; ++s)
				for (uint32 c = 0; c < 64u && c < kCtx; ++c)
				{
					MLTWorld w;
					if (w2 >= 0) w.SetWorld2(w2);            // ⚠️ `Reset` 보다 **먼저**
					w.Reset(s, kEpi + c, pt.hold, autoN, useDt, useAmp);
					for (uint32 t = 0; t < kTime; ++t)
					{
						MLTShapeView vs[kShapes];
						const int nv = w.VisibleShapes(vs, kShapes);
						for (int i = 0; i < nv; ++i)
						{
							float v = vs[i].d; if (v < 0.0f) v = 0.0f;
							if (v >= scale) v = scale - (scale / (float)kDepBins) * 0.001f;
							h.Data()[(uint32)((v / scale) * (float)kDepBins)] += 1u; ++tot;
						}
						w.Step();
					}
				}
			if (tot == 0u) { _depThr[0] = 1.0f; _depThr[1] = 2.0f; _depThr[2] = 3.0f; return; }
			const uint32 q[3] = { tot / 4u, tot / 2u, (tot * 3u) / 4u };
			uint32 run = 0u, qi = 0u;
			for (uint32 b = 0; b < kDepBins && qi < 3u; ++b)
			{
				run += h[b];
				while (qi < 3u && run >= q[qi]) { _depThr[qi] = ((float)b / (float)kDepBins) * scale; ++qi; }
			}
			if (pass == 0u)
			{
				// ⭐ 관측 최대 = **마지막 비지 않은 칸**(거친 눈금이라 ±1 bin 근사지만 배율을 정하기엔 충분하다)
				uint32 last = 0u;
				for (uint32 b = kDepBins; b-- > 0u; ) if (h[b] > 0u) { last = b; break; }
				_depObsMax = ((float)(last + 1u) / (float)kDepBins) * scale;
				_depTot = tot;
				if (fine && _depObsMax > 1.0e-6f) scale = _depObsMax;
			}
		}
	}
	// ⭐⭐ 회차 229 — 흐름 **속력**의 8분위 문턱(Ⓑ 계급의 눈금)
	//   ⚠️ **손으로 박지 않는다** — 바로 위 `_DepQuartiles` 와 **같은 관용구**다.
	//   ⚠️ **정지 문턱 위의 값들로만** 뽑는다 — 그 아래는 계급 0(정지)이라 이미 갈려 있다.
	//   ⛔⛔ 📌 **D42 — 위 `_DepQuartiles` 는 아직 `_Pt(3)`(dt 0.25 · amp 1.0)를 쓴다.**
	//     그런데 `_FillA` 는 **`_PtTrain()`(dt 1.00 · amp 5.0)** 을 쓴다 ⇒ ***깊이 4분위 문턱이
	//     다른 세계의 분포로 정해졌다.*** ⇒ ⚠️ 220 이 고친 그 사고가 **여기 한 자리에 남아 있었다**
	//     (그리고 `SetWorld2` 도 안 부른다 ⇒ 세계 종류도 안 맞는다).
	//     ⇒ ★ 이 새 자는 **`_PtTrain()` + `SetWorld2`** 를 쓴다. 옛 자는 **안 건드린다**(규율 58)
	//       — 대신 229 의 판정문이 **옛 문턱 ↔ 새 문턱**을 나란히 찍어 흔들림을 숫자로 남긴다.
	static constexpr uint32 kFlowBins = 2048u;
	static constexpr float  kFlowMax  = 64.0f;
	inline static float _flowThr[7] = { 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f };
	static uint32 _FlowSpCls(float sp)
	{
		if (sp < _dirThr) return 0u;                        // 정지
		for (uint32 i = 0; i < 7u; ++i) if (sp < _flowThr[i]) return 1u + i;
		return 8u;                                          // ⚠️ 9 는 「없음」이 쓴다
	}
	static void _FlowOctiles(int w2)
	{
		const Pt pt = _PtTrain();
		Array<uint32> h; h.Reset(0);
		for (uint32 i = 0; i < kFlowBins; ++i) h.Add(0u);
		uint32 tot = 0u;
		// ⚠️ 씨앗 둘만 스캔한다 — 문턱은 **분포의 모양**이라 전수가 필요 없다(위와 같은 근거)
		for (uint32 s = 0; s < 2u && s < kSeeds; ++s)
			for (uint32 c = 0; c < 64u && c < kCtx; ++c)
			{
				MLTWorld w;
				w.SetWorld2(w2);                            // ⚠️ `Reset` 보다 **먼저**
				w.Reset(s, kEpi + c, pt.hold, MLTWorldCfg::kAutoMany,
					(_dtOv  >= 0.0f) ? _dtOv  : pt.dt,
					(_ampOv >= 0.0f) ? _ampOv : pt.amp);
				static float px[kShapes], py[kShapes]; static bool pv[kShapes];
				for (int i = 0; i < kShapes; ++i) pv[i] = false;
				for (uint32 t = 0; t <= kUMax; ++t)
				{
					MLTShapeView vs[kShapes];
					const int nv = w.VisibleShapes(vs, kShapes);
					float ax = 0.0f, ay = 0.0f; uint32 nn = 0u;
					for (int i = 0; i < nv; ++i)
					{
						const int ix = vs[i].index;
						if (ix < 0 || ix >= kShapes) continue;
						if (pv[ix]) { ax += vs[i].sx - px[ix]; ay += vs[i].sy - py[ix]; ++nn; }
						px[ix] = vs[i].sx; py[ix] = vs[i].sy; pv[ix] = true;
					}
					if (nn > 0u)
					{
						const float mx = ax / (float)nn, my = ay / (float)nn;
						float sp = Sqrt(mx * mx + my * my);
						if (sp >= _dirThr)
						{
							if (sp >= kFlowMax) sp = kFlowMax - 0.001f;
							h.Data()[(uint32)((sp / kFlowMax) * (float)kFlowBins)] += 1u; ++tot;
						}
					}
					w.Step();
				}
			}
		if (tot == 0u) { for (uint32 i = 0; i < 7u; ++i) _flowThr[i] = (float)(i + 1u); return; }
		uint32 run = 0u, qi = 0u;
		for (uint32 b = 0; b < kFlowBins && qi < 7u; ++b)
		{
			run += h[b];
			while (qi < 7u && run >= (tot * (qi + 1u)) / 8u)
			{ _flowThr[qi] = ((float)b / (float)kFlowBins) * kFlowMax; ++qi; }
		}
		while (qi < 7u) { _flowThr[qi] = kFlowMax; ++qi; }
	}
	// ⭐ 무작위 조건 — 같은 칸 수의 **결정적 해시**(음성 대조)
	//   ⛔⛔ **첫 판을 틀렸다**(197 1차): `d0` 를 **안 담은** 순수 무작위로 만들었더니
	//     `H(나중|무작위)` 가 **무조건부 1.2643** 이 되고 여지가 **−0.9452** 로 나왔다
	//     ⇒ 관문 ③ 이 그것을 빼서 **303.9%** 라는 헛소리를 냈다(**규율 88 의 재발**).
	//   ⇒ ★ 올바른 음성 대조는 **`(d0, 무작위)`** 다 — ***`d0` 는 그대로 두고 추가 조건만***
	//     무작위로 바꾼다 ⇒ 그러면 그 팔의 여지가 정확히 **「빈 칸 편향」**이 된다.
	static uint32 _RandCond(uint32 s, uint32 c, uint32 t, uint32 i, uint32 n)
	{
		uint32 h = 0x9E3779B9u ^ (s * 2654435761u) ^ (c * 40503u) ^ (t * 2246822519u) ^ (i * 3266489917u);
		h ^= h >> 15; h *= 0x2C1B3C6Du; h ^= h >> 12; h *= 0x297A2D39u; h ^= h >> 15;
		return h % n;
	}
	// ⭐ 그 팔의 「여지」 = H(나중|지금방향) − H(나중|그 팔의 조건)
	//   ★ 분모(㈀)는 **모든 팔에서 같다** ⇒ 비를 견줄 수 있다(규율 87)
	static void _CStat(uint32 a, double& oHc, double& oRoom, double base, uint32& oUsed, double& oPer)
	{
		const uint32 n = _CondN(a);
		double tot = 0.0;
		for (uint32 cn = 0; cn < n; ++cn)
			for (uint32 df = 0; df < kDirCls; ++df) tot += (double)_hc[_HcIx(a, cn, df)];
		oHc = 0.0; oUsed = 0u; oPer = 0.0;
		if (tot <= 0.0) { oRoom = 0.0; return; }
		for (uint32 cn = 0; cn < n; ++cn)
		{
			double row[kDirCls]; for (uint32 i = 0; i < kDirCls; ++i) row[i] = 0.0;
			double rs = 0.0;
			for (uint32 df = 0; df < kDirCls; ++df)
			{
				const double v = (double)_hc[_HcIx(a, cn, df)];
				row[df] = v; rs += v;
			}
			if (rs <= 0.0) continue;
			++oUsed;
			double hp = 0.0;
			for (uint32 i = 0; i < kDirCls; ++i)
			{
				if (row[i] <= 0.0) continue;
				const double p = row[i] / rs;
				hp += -p * (double)Log((float)p);
			}
			oHc += (rs / tot) * hp;
		}
		oPer = (oUsed == 0u) ? 0.0 : tot / (double)oUsed;
		oRoom = base - oHc;
	}

	// ══════════════════════════════════════════════════════════════════
	// ⭐ 회차 198 — **새 세계 넷에서 같은 지도를 잰다**
	// ══════════════════════════════════════════════════════════════════
	//   ★ 197 이 *"이 세계는 「직전 방향」이 거의 전부다"*(전부 알아도 7.3%)를 냈고
	//     그 원인이 `mltworld` 의 `_ShapeWorld` 에 있음을 코드에서 확인했다
	//     (14개 중 11개가 **월드 정지** ⇒ 화면 이동이 **전부 카메라**).
	//   ⇒ ⭐ `SetWorld2(1|2|3)` = 반사 · 궤도 · 가속(전 도형이 움직인다)
	//   ⚠️ **자를 안 바꾼다**(규율 58) — 197 의 조건 팔 여덟 그대로. 세계만 감는다.
	//   ⚠️⚠️ **P 를 돌리기 전에 이것부터** 잰다(공용 규율 12) — 세계를 바꾸면 `P0~P3` 이
	//     전부 다시이므로, **2.5분짜리 회차 하나**로 헛도는 위험을 막는다.
	// ⭐ 조건 히스토그램을 채운다 — ★ 197 과 198 이 **같은 자**를 쓰게 하려고 뺐다(규율 58)
	static void _FillC(int w2, uint32 kKUse)
	{
		const Pt pt = _Pt(3u);                     // ㉃ dt.25 — 몸통이 쓰는 세계
		const int autoN = MLTWorldCfg::kAutoMany;
		_hc.Reset(0);
		for (uint32 i = 0; i < kCArms * kCondMax * kDirCls; ++i) _hc.Add(0u);
		for (uint32 s = 0; s < kSeeds; ++s)
			for (uint32 c = 0; c < kCtx; ++c)
			{
				MLTWorld w;
				w.SetWorld2(w2);                   // ⚠️ `Reset` 보다 **먼저** — Reset 이 이것을 안 건드린다
				w.Reset(s, kEpi + c, pt.hold, autoN, pt.dt, pt.amp);
				static float sxT[kUMax + 1u][kShapes];
				static float syT[kUMax + 1u][kShapes];
				static float szT[kUMax + 1u][kShapes];
				static bool  okT[kUMax + 1u][kShapes];
				for (uint32 u = 0; u <= kUMax; ++u)
				{
					for (int i = 0; i < kShapes; ++i) okT[u][i] = false;
					MLTShapeView vs[kShapes];
					const int nv = w.VisibleShapes(vs, kShapes);
					for (int i = 0; i < nv; ++i)
					{
						const int ix = vs[i].index;
						if (ix < 0 || ix >= kShapes) continue;
						sxT[u][ix] = vs[i].sx; syT[u][ix] = vs[i].sy;
						szT[u][ix] = vs[i].d; okT[u][ix] = true;
					}
					if (u < kUMax) w.Step();
				}
				for (uint32 t = 3u; t < kTime; ++t)
					for (int i = 0; i < kShapes; ++i)
					{
						const uint32 d0 = _DirOf(sxT[t][i], syT[t][i], sxT[t - 1u][i], syT[t - 1u][i],
						                         okT[t][i], okT[t - 1u][i]);
						const uint32 d1 = _DirOf(sxT[t - 1u][i], syT[t - 1u][i], sxT[t - 2u][i], syT[t - 2u][i],
						                         okT[t - 1u][i], okT[t - 2u][i]);
						const uint32 d2 = _DirOf(sxT[t - 2u][i], syT[t - 2u][i], sxT[t - 3u][i], syT[t - 3u][i],
						                         okT[t - 2u][i], okT[t - 3u][i]);
						const uint32 u = t + kKUse;
						const uint32 df = _DirOf(sxT[u][i], syT[u][i], sxT[u - 1u][i], syT[u - 1u][i],
						                         okT[u][i], okT[u - 1u][i]);
						const uint32 pos2 = okT[t][i] ? _PosCls(sxT[t][i], syT[t][i], 2u) : 4u;
						const uint32 dep  = okT[t][i] ? _DepCls(szT[t][i]) : 0u;
						uint32 nearD = kDirCls - 1u;
						if (okT[t][i])
						{
							float best = 1.0e30f;
							for (int j = 0; j < kShapes; ++j)
							{
								if (j == i || !okT[t][j]) continue;
								const float dx = sxT[t][j] - sxT[t][i], dy = syT[t][j] - syT[t][i];
								const float dd = dx * dx + dy * dy;
								if (dd < best)
								{
									best = dd;
									nearD = _DirOf(sxT[t][j], syT[t][j], sxT[t - 1u][j], syT[t - 1u][j],
									               okT[t][j], okT[t - 1u][j]);
								}
							}
						}
						const uint32 q1 = _Q4(d1), q2 = _Q4(d2), qn = _Q4(nearD);
						const uint32 h3 = (d0 * kQ4 + q1) * kQ4 + q2;
						_hc.Data()[_HcIx(0u, d0, df)] += 1u;
						_hc.Data()[_HcIx(1u, d0 * kQ4 + q1, df)] += 1u;
						_hc.Data()[_HcIx(2u, h3, df)] += 1u;
						_hc.Data()[_HcIx(3u, d0 * 5u + pos2, df)] += 1u;
						_hc.Data()[_HcIx(4u, d0 * 4u + dep, df)] += 1u;
						_hc.Data()[_HcIx(5u, d0 * kQ4 + qn, df)] += 1u;
						_hc.Data()[_HcIx(6u, h3 * 5u + pos2, df)] += 1u;
						_hc.Data()[_HcIx(7u, d0 * kQ4 * kQ4
							+ _RandCond(s, c, t, (uint32)i, kQ4 * kQ4), df)] += 1u;
					}
			}
	}

	// ══════════════════════════════════════════════════════════════════
	// ⭐ 회차 214 — 「행동의 여지」 + **「가름」 반사실**(학습 0)
	// ══════════════════════════════════════════════════════════════════
	//   ⭐ **「가름」이 이 회차의 진짜 물음**이다 — 회차 107 의 반사실 자 그대로:
	//     같은 자리에서 **행동만 바꿔** 한 걸음 굴리고 표적(이동 방향)이 **달라지나**.
	//     ⇒ 그 몫이 **오귀속률의 분모**다(115 는 옛 세계에서 **28.2%** 를 썼다).
	//   ⚠️⚠️ **그것이 0 이면 ㈁ 이 원리적으로 못 서고**(행동이 표적을 안 정한다)
	//     **1 이면 ㈂ 가 원리적으로 정의 불가**다(모든 변화가 내 행동이다 — `mltworld` ⑨ 의 거울).
	//   ⇒ ★ 그래서 이 한 숫자가 ***칸 3 이 어느 세계에서 성립하는가***를 정한다(규율 76).
	//   ⚠️ 세계를 복제해서 갈린다 — `MLTWorld` 는 **전부 값 멤버**라 기본 복사가 성립한다
	//     (배열·포인터가 없다. ⭐ `_ShapeWorld` 가 **무상태**라 그것이 유지된다).
	inline static double _splitFrac = 0.0;   // 「가름」 몫(부호 반전)
	inline static double _zsplitFrac = 0.0;  // ⭐ 215 — 「0-행동 가름」 몫
	inline static double _splitVis  = 0.0;   // ⭐ 215 — **보이는 것만** 센 가름(진짜 분모)
	inline static double _zsplitVis = 0.0;
	inline static double _noneFrac  = 0.0;
	// ⭐ 회차 216 — **행동 몫**(연속량). ⚠️ 규율 31 이 가리킨 처방이다:
	//   ***이진(「갈리나」)은 크기가 없다*** ⇒ 215 에서 그것이 **100% 로 포화**했다.
	//   ⇒ ★ 화면 이동 벡터를 분해한다: `Δ전체 = Δ자율 + Δ행동`
	//     · `Δ자율` = **카메라를 세운** 반사실의 이동(행동 0)
	//     · `Δ행동` = `Δ전체 − Δ자율`
	//   ⇒ ⭐ **행동 몫 = |Δ행동| ÷ (|Δ행동| + |Δ자율|)** — 포화하지 않는다.
	//   ⚠️ **선형 분해는 근사다**(투영이 비선형이다) ⇒ 「상수로 둔 것」으로 적는다.
	inline static double _actShare = 0.0;
	// ⚖️✂️ 회차 238 — 🆕 캔버스 **「버릴 기준을 세계가 만든다」**(👤 사람이 준 자매 문서 · 237 심사)
	//   ⚠️⚠️ **둘 다 기본 꺼짐** ⇒ 회차 1~237 이 **비트 동일**이다(규율 58).
	//   ★ `_enOn` = 에너지(감쇠) · `_prOn` = **가지치기**(축별 비용 · 비싼 축이 먼저 잘린다)
	inline static bool   _enOn = false, _prOn = false;
	inline static float  _prBud = -1.0f;      // ⭐ 239 — 예산(음수 = 세계 기본 1.25)
	inline static float  _slowOv = -1.0f;     // ⭐ 242 — 감쇠 세기(음수 = 세계 기본 0.35)
	// ⭐ 242 — **이어짐** = 한 물체가 **연속으로 보이는** 시각 수(241 의 기제 가설을 재는 자)
	inline static double _runSum = 0.0;  inline static uint32 _runN = 0u;
	// ⭐⭐ 회차 244 — **캡션 심볼 열 자체의 성질**(243 이 후보를 여기로 좁혔다:
	//   값 부호화 `d̄` 는 0.966배로 안 변하고 **심볼만** 0.834배로 내렸다 ⇒ 기제는 이산 심볼에 특유하다).
	//   ⚠️⚠️ 242 의 「이어짐」과 **다른 자**다 — 그것은 「보임」의 연속이고 이것은 **캡션에 실린 이름**이다
	//     (물체가 보여도 **안 바뀌면 캡션에 안 실린다** ⇒ 캡션 = `firstChg`).
	inline static uint32 _capHist[MLTWorldCfg::kShapes + 1u] = { 0u };  // 마지막 칸 = 「없음」
	inline static uint32 _capTot = 0u;      // 캡션을 잰 시각 수(없음 포함)
	inline static uint32 _capRep = 0u;      // 직전 시각과 **같은 심볼**이 실린 횟수
	inline static uint32 _capPairN = 0u;    // 그 분모(직전도 있음 · 지금도 있음)
	inline static int    _capPrev = -2;     // 직전 시각의 캡션(−1 = 없음 · −2 = 에피소드 시작)
	// ⭐⭐⭐ 회차 254 — **「도형 identity ↔ 슬롯 번호」의 결합 히스토그램**
	//   ★ 학습 하네스(`mltl1t0`)가 쓰는 낱말이 **슬롯 번호**이고 이 하네스는 **도형 index** 다(📌 D46).
	//   ⇒ `H(도형 | 슬롯)` = ***낱말을 identity 로 바꿔서 얻을 여지***(규율 12).
	static constexpr uint32 kIdSlots = 8u;   // = `mltl1t0::kSlots`
	inline static uint32 _idJoint[MLTWorldCfg::kShapes][kIdSlots + 1u] = { { 0u } };
	inline static uint32 _idTot = 0u;
	// ⭐ 「그 시각에 바뀌는 물체 수」 = 캡션의 **자리 수 유효값**(236 이 「통로는 자리다」를 냈다)
	inline static double _chgSum = 0.0;  inline static uint32 _chgN = 0u;
	inline static double _slowSum = 0.0, _cutSum = 0.0;  inline static uint32 _epiN = 0u;
	// ⚖️⚖️ 회차 264 — **몸의 서명**(⚠️ 성능보다 **먼저** 읽는다 · 공용 규율 1)
	//   `_biasSum` = 반사 발동/에피 · `_fwAllSum` = 먹이 가중 평균 · `_fwLowMSum` = `_e` 낮을 때
	inline static double _biasSum = 0.0, _pickSum = 0.0, _fwAllSum = 0.0, _fwLowMSum = 0.0, _pwAllSum = 0.0;
	inline static uint32 _fwAllN = 0u, _fwLowMN = 0u;
	inline static bool   _bodyGain = false, _bodyRefl = false;   // ⚠️ 둘 다 기본 꺼짐
	inline static bool   _bodySigOn = false;   // ⭐ 서명만(몸 꺼진 팔의 **기준선** · ML 규율 74)
	inline static float  _ampOv = -1.0f;     // 216 — 세계 인자 덮어쓰기(음수 = 안 덮는다)
	inline static float  _dtOv  = -1.0f;
	// ⭐ 232 — **손잡이를 일부러 미는 판**(`_RunAmp`·`_RunBal`)이 켠다 ⇒ 방벽 ② 의 거짓 경고를 막는다
	//   ⚠️ ***이것을 켜는 것은 "그 판은 학습 자와 다른 자리를 본다"는 선언***이다 — 아무 데나 켜지 마라.
	inline static bool   _ptIntent = false;
	static void _FillA(int w2)
	{
		// ⛔⛔ **220 이 고쳤다** — 여기 있던 `_Pt(3u)`(dt 0.25 · amp 1.0)는 ***몸통이 쓰는 세계가
		//   아니었다***. 몸통(방향 모드)은 **dt 1.00 · amp 5.0** 이다 ⇒ 위 `_PtTrain()` 의 그 주석.
		//   ⚠️ 그 한 줄 때문에 214·216·218 의 결론 셋이 뒤집혔다(규율 65).
		const Pt pt = _PtTrain();                  // ⭐ **학습 하네스와 같은 세계**
		const int autoN = MLTWorldCfg::kAutoMany;
		// ⭐⭐ 회차 232 — 🔒 **하네스 방벽 ②**: 이 판이 **무엇을 보고 있는지** 매 판 한 줄로 찍는다
		//   ⛔ 세 사고가 전부 이 줄이면 **그 자리에서** 보였다:
		//     · **220** — 학습 자 dt 1.00 ↔ 학습0 자 dt **0.25**(결론 셋이 뒤집혔다 · 사흘)
		//     · **225** — 팔 0·1 이 오라클을 받고 있었다(`Î` 가 용량마다 달랐다)
		//     · **230** — 깊이 눈금이 실제 범위보다 **~100배** 거칠었다(여지를 1.3~1.8%p 과대평가)
		//   ⇒ ★ 그래서 **세계 · dt · amp · 깊이문턱 · 분해능 · 표본 · 모드**를 한 줄에 모은다.
		//   ⚠️ 그리고 **모드가 둘 이상 켜지면 ⛔** — 219 가 적었다: *"모드는 계속 늘어난다."*
		//   ⚠️ `_RunAmp`/`_RunBal` 은 손잡이를 **일부러** 민다 ⇒ `_ptIntent` 로 거짓 경고를 막는다.
		{
			const float useDt  = (_dtOv  >= 0.0f) ? _dtOv  : pt.dt;
			const float useAmp = (_ampOv >= 0.0f) ? _ampOv : pt.amp;
			const bool  dtOk   = _ptIntent || (Abs(useDt  - kTrDt)  < 1.0e-6f);
			const bool  ampOk  = _ptIntent || (Abs(useAmp - kTrAmp) < 1.0e-6f);
			const uint32 nMode = (_a2 ? 1u : 0u) + (_a3 ? 1u : 0u) + (_a4 ? 1u : 0u) + (_a5 ? 1u : 0u);
			LogA("[mlt] 🔒 _FillA 세계 %d · dt %.3f%s · amp %.3f%s · 깊이문턱 %.4f/%.4f/%.4f"
				"(관측최대 %.2f · 표본 %u) · 모드 %s%s%s\n",
				w2,
				(double)useDt,  dtOk  ? "" : " ⛔**학습 자와 다르다**",
				(double)useAmp, ampOk ? "" : " ⛔**학습 자와 다르다**",
				(double)_depThr[0], (double)_depThr[1], (double)_depThr[2],
				(double)_depObsMax, _depTot,
				_a5 ? "a5" : (_a4 ? "a4" : (_a3 ? "a3" : (_a2 ? "a2" : (_aSweep ? "aSweep" : "기본")))),
				(nMode > 1u) ? " ⛔⛔**모드가 둘 이상 켜졌다**" : "",
				_ptIntent ? " (손잡이 스윕 — 어긋남은 의도됨)" : "");
		}
		_hc.Reset(0);
		for (uint32 i = 0; i < kCArms * kCondMax * kDirCls; ++i) _hc.Add(0u);
		uint32 splitN = 0u, splitTot = 0u, noneN = 0u, noneTot = 0u;
		uint32 zsplitN = 0u, zsplitTot = 0u;
		uint32 visTot = 0u, splitVisN = 0u, zsplitVisN = 0u;   // ⭐ 215 — **보이는 것만**
		double shareSum = 0.0; uint32 shareN = 0u;             // ⭐ 216 — 행동 몫
		// ⚖️✂️ 회차 238 — **바뀌는 물체 수** · 둔화/가지치기 발동(새 캔버스의 자)
		_chgSum = 0.0; _chgN = 0u; _slowSum = 0.0; _cutSum = 0.0; _epiN = 0u;
		// ⚖️⚖️ 264 — 몸의 서명도 판마다 비운다(안 비우면 앞 모드가 섞인다 — 244 의 그 함정)
		_biasSum = 0.0; _pickSum = 0.0; _fwAllSum = 0.0; _fwLowMSum = 0.0; _pwAllSum = 0.0;
		_fwAllN = 0u; _fwLowMN = 0u;
		for (uint32 s = 0; s < kSeeds; ++s)
			for (uint32 c = 0; c < kCtx; ++c)
			{
				MLTWorld w;
				w.SetWorld2(w2);                   // ⚠️ `Reset` 보다 **먼저**
				// ⚖️✂️ 회차 238 — 에너지/가지치기를 켠다(⚠️ 기본 둘 다 꺼짐 ⇒ 회차 1~237 무변경)
				//   ⚠️ `Reset` 이 이 플래그들을 안 건드리므로 앞에서 켜도 된다(`SetWorld2` 와 같은 규약).
				if (_enOn) { w.SetEnergy(true); w.SetEnergySlow(_slowOv); }   // ⭐ 242 — 감쇠 세기 손잡이
				if (_prOn) { w.SetPrune(true); w.SetPruneBudget(_prBud); }   // ⭐ 239 — 예산 손잡이
				// ⚖️⚖️ 264 — **몸**(이득 ↔ 반사를 따로 켠다 ⇒ 컨셉의 팔 넷째·다섯째)
				if (_bodyGain || _bodyRefl) w.SetBodyParts(_bodyGain, _bodyRefl);
				if (_bodySigOn) w.SetBodySig(true);   // ⭐ 기준선을 이 자리에서 직접 잰다(ML 규율 74)
				// ⭐ 216 — 손잡이 둘을 덮어쓴다(`dtMul` = 카메라 몫 · `amp` = 자율 진폭)
				w.Reset(s, kEpi + c, pt.hold, autoN,
					(_dtOv  >= 0.0f) ? _dtOv  : pt.dt,
					(_ampOv >= 0.0f) ? _ampOv : pt.amp);
				static float sxT[kUMax + 1u][kShapes];
				static float syT[kUMax + 1u][kShapes];
				static float szT[kUMax + 1u][kShapes];
				static bool  okT[kUMax + 1u][kShapes];
				// ⭐ 반사실 — **같은 자리에서 행동만 바꾼** 다음 화면
				static float cxT[kUMax + 1u][kShapes];
				static float cyT[kUMax + 1u][kShapes];
				static bool  cokT[kUMax + 1u][kShapes];
				static uint32 actT[kUMax + 1u];
				static uint32 finT[kUMax + 1u];    // ⭐ 215 — 천장 54계급
				static uint32 yawT[kUMax + 1u];    // ⭐ 215 — dYaw 만 9계급
				// ⭐ 215 — **행동 0 반사실**: 카메라를 세우고 굴리면 **자율 운동만** 남는다
				//   ⇒ ★ 그 방향이 ***"내가 아무것도 안 했다면 이 물체가 어디로 갔을까"*** 다
				//   ⚠️ 이것은 **세계만 아는 값**이다(모델 입력이 아니다) ⇒ **천장 자**로만 쓴다
				static float zxT[kUMax + 1u][kShapes];
				static float zyT[kUMax + 1u][kShapes];
				static bool  zokT[kUMax + 1u][kShapes];
				// ⛔⛔⛔ **회차 216 이 여기서 배관 결함을 잡았다** — 반사실 배열은 `u` 에서 **`u+1`**
				//   을 채우는데 초기화가 `u` 루프 **안**에 있었다 ⇒ ***다음 반복이 방금 쓴 것을 지웠다.***
				//   ⇒ ⛔ `cokT`·`zokT` 가 **항상 false** ⇒ `dfc`·`dz` 가 **항상 「없음」**
				//   ⇒ ⇒ ⛔⛔ 그래서 「가름」이 `P(df ≠ 없음) = 1 − 「없음」 = 47.5%` 로 나왔다
				//     (214 의 표제 · 215 의 「보임만 100%」가 **둘 다 이 버그의 산물**이다)
				//   ⇒ ★ **처방: 루프 밖에서 한 번만 지운다.** ⚠️ 실제 방향(`okT`)은 `u` 에서
				//     `u` 를 쓰므로 안 걸렸다 — ***그래서 표의 절반만 죽어 있었고 안 보였다.***
				for (uint32 u = 0; u <= kUMax; ++u)
					for (int i = 0; i < kShapes; ++i) { cokT[u][i] = false; zokT[u][i] = false; }
				for (uint32 u = 0; u <= kUMax; ++u)
				{
					for (int i = 0; i < kShapes; ++i) okT[u][i] = false;   // ⚠️ 반사실은 위에서 지웠다
					MLTShapeView vs[kShapes];
					const int nv = w.VisibleShapes(vs, kShapes);
					for (int i = 0; i < nv; ++i)
					{
						const int ix = vs[i].index;
						if (ix < 0 || ix >= kShapes) continue;
						sxT[u][ix] = vs[i].sx; syT[u][ix] = vs[i].sy;
						szT[u][ix] = vs[i].d; okT[u][ix] = true;
					}
					if (u < kUMax)
					{
						// ⚠️ 행동은 **굴리기 전에** 정해진다(`_Advance` 가 `_act` 를 쓴다)
						//   ⇒ ★ `ActAt(step)` 이 곧 「이 걸음에 적용될 행동」이다(`_hold` 를 반영)
						const MLTAct aReal = w.ActAt(w.StepNo());
						actT[u + 1u] = _ActCls(aReal);
						finT[u + 1u] = _ActFine(aReal);
						yawT[u + 1u] = _ActYaw9(aReal);
						// ⭐ 반사실: **부호를 뒤집은** 행동(같은 크기 · 다른 방향)
						//   ★ 크기를 유지해야 「행동이 있고 없고」가 아니라 ***방향이 갈리나***를 잰다
						MLTAct aAlt = aReal;
						aAlt.dYaw = -aReal.dYaw; aAlt.fwd = -aReal.fwd;
						aAlt.side = -aReal.side; aAlt.up = -aReal.up; aAlt.dPitch = -aReal.dPitch;
						MLTWorld wc = w;                       // 값 복사(전부 값 멤버)
						wc.StepWith(aAlt);
						MLTShapeView cvs[kShapes];
						const int cnv = wc.VisibleShapes(cvs, kShapes);
						for (int i = 0; i < cnv; ++i)
						{
							const int ix = cvs[i].index;
							if (ix < 0 || ix >= kShapes) continue;
							cxT[u + 1u][ix] = cvs[i].sx; cyT[u + 1u][ix] = cvs[i].sy;
							cokT[u + 1u][ix] = true;
						}
						// ⭐ 215 — **행동 0 반사실**(카메라를 세운다 ⇒ 자율 운동만 남는다)
						{
							MLTAct aZero;   // 기본 생성 = 전부 0
							aZero.fwd = 0.0f; aZero.up = 0.0f; aZero.side = 0.0f;
							aZero.dYaw = 0.0f; aZero.dPitch = 0.0f;
							MLTWorld wz = w;
							wz.StepWith(aZero);
							MLTShapeView zvs[kShapes];
							const int znv = wz.VisibleShapes(zvs, kShapes);
							for (int i = 0; i < znv; ++i)
							{
								const int ix = zvs[i].index;
								if (ix < 0 || ix >= kShapes) continue;
								zxT[u + 1u][ix] = zvs[i].sx; zyT[u + 1u][ix] = zvs[i].sy;
								zokT[u + 1u][ix] = true;
							}
						}
						w.Step();
					}
				}
				// ⭐⭐ 244 — 에피소드 경계에서 **반복률의 사슬을 끊는다**
				//   ⚠️ 안 끊으면 앞 에피소드의 마지막과 이 에피소드의 첫 시각이 **한 쌍**이 된다(가짜 반복).
				_capPrev = -2;
				for (uint32 t = 3u; t < kTime; ++t)
				{
					// ⭐ 218 — **캡션을 먼저 만든다**(i 전체를 봐야 「첫 바뀌는 것」이 정해진다)
					//   ★ `mltl1t0` 의 정의 그대로: *"다음 시각에 **계급이 바뀌는**"* = `다음 방향 ≠ 지금 방향`
					//   ⚠️ **방향값은 안 넣는다**(D7) — **이진**(바뀌나)만 준다
					int firstChg = -1;
					static bool chgT[kShapes];
					// ⭐ 226 — **화면 흐름**(보이는 물체들의 이동 평균)을 시각마다 미리 만든다
					//   ★ `flowT[u]` = `flow(u-1 → u)` ⇒ 시각 `t` 에서 **미래**는 `flowT[t+1]`
					static uint32 flowT[kUMax + 1u];
					// ⭐ 229 — 같은 흐름을 **세 형태**로 계급한다(⚠️ 셋 다 **10칸** — 규율 13)
					static uint32 flowB[kUMax + 1u];    // Ⓑ 속력(0=정지 · 1..8=8분위 · 9=없음)
					static uint32 flowC[kUMax + 1u];    // Ⓒ 방향4 × 속력2(0=정지 · 1..8 · 9=없음)
					if (_a4 || _a5)
					{
						for (uint32 u2 = 0; u2 <= kUMax; ++u2)
						{
							if (u2 == 0u)
							{ flowT[0] = kDirCls - 1u; flowB[0] = kDirCls - 1u; flowC[0] = kDirCls - 1u; continue; }
							float ax = 0.0f, ay = 0.0f; uint32 nn2 = 0u;
							for (int i2 = 0; i2 < kShapes; ++i2)
							{
								if (!(okT[u2][i2] && okT[u2 - 1u][i2])) continue;
								ax += sxT[u2][i2] - sxT[u2 - 1u][i2];
								ay += syT[u2][i2] - syT[u2 - 1u][i2];
								++nn2;
							}
							if (nn2 == 0u)
							{ flowT[u2] = kDirCls - 1u; flowB[u2] = kDirCls - 1u; flowC[u2] = kDirCls - 1u; continue; }
							const float mx = ax / (float)nn2, my = ay / (float)nn2;
							const float sp = Sqrt(mx * mx + my * my);
							flowB[u2] = _FlowSpCls(sp);           // ⭐ Ⓑ — 크기를 **버리지 않는다**
							if (sp < _dirThr) { flowT[u2] = 0u; flowC[u2] = 0u; continue; }
							float ang = Atan2(my, mx);
							const float twoPi = 6.28318531f;
							if (ang < 0.0f) ang += twoPi;
							const uint32 d8 = 1u + ((uint32)((ang / twoPi) * 8.0f + 0.5f) % 8u);
							flowT[u2] = d8;
							// ⭐ Ⓒ — 방위를 **넷으로 뭉치고** 남는 칸에 속력 상/하를 넣는다
							//   ★ 그래야 Ⓐ·Ⓑ 와 **같은 10칸**이 되어 빈 칸 편향이 같다
							flowC[u2] = 1u + ((d8 - 1u) / 2u) * 2u + ((flowB[u2] >= 5u) ? 1u : 0u);
						}
					}
					// ⭐⭐ 229 — 흐름 표적 셋은 **시각별**이다 ⇒ 물체 루프 **밖**에서 한 번만 센다
					//   ⚠️ 안에서 세면 같은 시각을 `kShapes` 번 세는 것뿐이고(비는 같다) 표본이 부푼 것처럼 보인다
					if (_a5)
					{
						const uint32 uF = t + 1u;
						const uint32 yw = yawT[uF];                       // ⭐ 조건 = `dYaw` 9계급
						const uint32 rn = _RandCond(s, c, t, 911u, 9u);   // ★ 음성 짝 — **같은 칸 수**
						_hc.Data()[_HcIx(0u, 0u, flowT[uF])] += 1u;       // Ⓐ 분모
						_hc.Data()[_HcIx(1u, yw, flowT[uF])] += 1u;       // Ⓐ + dYaw
						_hc.Data()[_HcIx(2u, rn, flowT[uF])] += 1u;       // Ⓐ 음성
						_hc.Data()[_HcIx(3u, 0u, flowB[uF])] += 1u;       // Ⓑ 분모
						_hc.Data()[_HcIx(4u, yw, flowB[uF])] += 1u;       // Ⓑ + dYaw
						_hc.Data()[_HcIx(5u, rn, flowB[uF])] += 1u;       // Ⓑ 음성
						_hc.Data()[_HcIx(6u, 0u, flowC[uF])] += 1u;       // Ⓒ 분모
						_hc.Data()[_HcIx(7u, yw, flowC[uF])] += 1u;       // Ⓒ + dYaw
						_hc.Data()[_HcIx(8u, rn, flowC[uF])] += 1u;       // Ⓒ 음성
					}
					if (_a3 || _a4)
					{
						const uint32 uu = t + 1u;
						uint32 nChg = 0u;
						for (int i = 0; i < kShapes; ++i)
						{
							chgT[i] = false;
							if (!(okT[t][i] && okT[t - 1u][i] && okT[uu][i])) continue;
							const uint32 a0 = _DirOf(sxT[t][i], syT[t][i], sxT[t - 1u][i], syT[t - 1u][i], true, true);
							const uint32 a1 = _DirOf(sxT[uu][i], syT[uu][i], sxT[t][i], syT[t][i], true, true);
							if (a1 != a0) { chgT[i] = true; ++nChg; if (firstChg < 0) firstChg = i; }
						}
						// ⭐⭐ 238 — **「그 시각에 바뀌는 물체 수」** = 캡션의 **자리 수 유효값**
						//   ★ 236 이 *"통로는 자리의 수다"* 를 냈으므로 ***이것이 이 캔버스의 기제 자다.***
						_chgSum += (double)nChg; ++_chgN;
						// ⭐⭐ 244 — **캡션 심볼 열**을 여기서 센다(`firstChg` 가 곧 자리 1 캡션이다)
						//   ⚠️ `firstChg` 는 **인덱스 순서로 첫 번째**다 ⇒ 바뀌는 물체가 늘수록
						//     작은 인덱스로 **몰린다** ⇒ ★ 그것이 봉우리를 낼 수 있는 이유다.
						{
							const int cs = firstChg;                       // −1 = 없음
							const uint32 slot = (cs < 0) ? (uint32)kShapes : (uint32)cs;
							++_capHist[slot]; ++_capTot;
							// 반복률 — ⚠️ **둘 다 있을 때만** 센다(「없음 → 없음」은 반복이 아니다)
							if (_capPrev >= 0 && cs >= 0)
							{ ++_capPairN; if (_capPrev == cs) ++_capRep; }
							_capPrev = cs;
							// ══════════════════════════════════════════════
							// ⭐⭐⭐ 회차 254 — **「슬롯 번호」가 정체성을 얼마나 잃나**
							// ══════════════════════════════════════════════
							//   ⚙️ 254 심사가 잡았다: **학습 하네스(`mltl1t0`)의 캡션은 「슬롯 번호」**다
							//     (`nm = 1 + j` · `j` = *"보이는 물체 중 몇 번째"*) — **도형 index 가 아니다.**
							//     ⇒ 🧾 그런데 슬롯은 **매 시각 다시 채워지므로 지시대상이 바뀐다**(밀림 55.2% · 회차 55).
							//   ⭐ 이 하네스는 **도형 index** 를 쓴다(`firstChg` = `i`) ⇒ 📌 **D46 이 확정됐다.**
							//   ⇒ ⭐⭐ **규율 12**(*처방 전에 여지를 학습 0 으로 재라*)의 자리:
							//     ***`H(도형 | 슬롯)` 이 곧 「낱말을 identity 로 바꿔서 얻을 여지」다.***
							//   ★ 손계산 천장: `H(도형)` ≤ `ln 14` = **2.639**(244 실측 2.2886)
							//     · 슬롯이 정체성을 다 담으면 **0** · 다 잃으면 `H(도형)`.
							//   ⚠️ 슬롯 순위는 **그 시각의 보임**으로 센다(학습 하네스가 그렇게 채운다) ·
							//     8칸을 넘으면 **슬롯에 없다**(그때 학습 하네스는 그 물체를 못 부른다).
							if (cs >= 0)
							{
								uint32 rank = 0u;
								for (int i2 = 0; i2 < cs; ++i2) if (okT[t][i2]) ++rank;
								const uint32 sb = (rank < kIdSlots) ? rank : kIdSlots;   // 마지막 칸 = 「슬롯 없음」
								++_idJoint[cs][sb]; ++_idTot;
							}
						}
					}
					for (int i = 0; i < kShapes; ++i)
					{
						const uint32 d0 = _DirOf(sxT[t][i], syT[t][i], sxT[t - 1u][i], syT[t - 1u][i],
						                         okT[t][i], okT[t - 1u][i]);
						const uint32 d1 = _DirOf(sxT[t - 1u][i], syT[t - 1u][i], sxT[t - 2u][i], syT[t - 2u][i],
						                         okT[t - 1u][i], okT[t - 2u][i]);
						const uint32 u = t + 1u;                 // k = 1 (197·198 과 같다)
						const uint32 df = _DirOf(sxT[u][i], syT[u][i], sxT[u - 1u][i], syT[u - 1u][i],
						                         okT[u][i], okT[u - 1u][i]);
						// ⭐ 「가름」 — **같은 출발점**에서 행동만 바꾼 다음 방향
						const uint32 dfc = _DirOf(cxT[u][i], cyT[u][i], sxT[u - 1u][i], syT[u - 1u][i],
						                          cokT[u][i], okT[u - 1u][i]);
						// ⭐ 자율만 방향 — *"내가 아무것도 안 했다면 어디로 갔을까"*
						const uint32 dz = _DirOf(zxT[u][i], zyT[u][i], sxT[u - 1u][i], syT[u - 1u][i],
						                         zokT[u][i], okT[u - 1u][i]);
						++splitTot; if (df != dfc) ++splitN;
						++zsplitTot; if (df != dz) ++zsplitN;   // ⭐ 215 — **0-행동 가름**
						++noneTot; if (df == kDirCls - 1u) ++noneN;
						// ⛔⛔ **215 의 손계산이 잡았다** — 「가름」 + 「없음」 = **정확히 100%**(네 세계)
						//   ⇒ ★ 그 자는 ***"물체가 보이나"*** 를 재고 있었다(규율 87 의 분모 자리).
						//   ⇒ ⭐ **보이는 것만**으로 다시 센다 — 그것이 진짜 분모다.
						if (df != kDirCls - 1u)
						{
							++visTot;
							if (df != dfc) ++splitVisN;
							if (df != dz)  ++zsplitVisN;
						}
						// ⭐ 216 — **행동 몫**(연속량 · 규율 31 이 가리킨 처방)
						//   ⚠️ 셋이 다 보일 때만 — 안 보이면 이동 벡터가 **정의되지 않는다**
						if (okT[u][i] && okT[u - 1u][i] && zokT[u][i])
						{
							const float ax = sxT[u][i] - sxT[u - 1u][i];
							const float ay = syT[u][i] - syT[u - 1u][i];
							const float zx = zxT[u][i] - sxT[u - 1u][i];
							const float zy = zyT[u][i] - syT[u - 1u][i];
							const float cx = ax - zx, cy = ay - zy;      // Δ행동 = Δ전체 − Δ자율
							const double mA = (double)Sqrt(cx * cx + cy * cy);
							const double mZ = (double)Sqrt(zx * zx + zy * zy);
							if (mA + mZ > 1.0e-9) { shareSum += mA / (mA + mZ); ++shareN; }
						}
						const uint32 dep = okT[t][i] ? _DepCls(szT[t][i]) : 0u;
						const uint32 ac  = actT[u];
						const uint32 q1  = _Q4(d1);
						if (_a5)
						{
							// ⭐ 229 — Ⓓ **타자 자**(자율 물체의 다음 방향) — 규율 18-a ㈁
							//   ★ **같은 조건**(`dYaw` 9)으로 **다른 표적**을 설명하는 여지 ⇒ 견줄 수 있다
							//   ⚠️ 이쪽은 **물체별**이라 표본이 흐름 팔보다 많다 — 각 팔이 자기 분모로
							//     정규화되므로 비는 견줄 수 있고 표본 차는 **잡음 크기**에만 든다
							_hc.Data()[_HcIx(9u,  0u, df)] += 1u;
							_hc.Data()[_HcIx(10u, yawT[u], df)] += 1u;
							_hc.Data()[_HcIx(11u, _RandCond(s, c, t, (uint32)i + 911u, 9u), df)] += 1u;
							continue;
						}
						if (_a4)
						{
							// ⭐ 226 — 흐름(자기) ↔ 깊이·캡션(타자)를 같은 분모로
							//   ⚠️ **미래 흐름**은 「완벽한 사본」을 가정한 것이라 **천장**이다
							const uint32 fF = flowT[u];        // flow(t → t+1) — 미래
							const uint32 fP = flowT[t];        // flow(t-1 → t) — 과거(공짜)
							const uint32 r10 = _RandCond(s, c, t, (uint32)i + 41u, kDirCls);
							_hc.Data()[_HcIx(0u, d0, df)] += 1u;
							_hc.Data()[_HcIx(1u, d0 * kDirCls + fF, df)] += 1u;
							_hc.Data()[_HcIx(2u, d0 * kDirCls + fP, df)] += 1u;
							_hc.Data()[_HcIx(3u, d0 * kDirCls + r10, df)] += 1u;
							_hc.Data()[_HcIx(4u, d0 * 4u + dep, df)] += 1u;
							_hc.Data()[_HcIx(5u, d0 * 2u + (chgT[i] ? 1u : 0u), df)] += 1u;
							_hc.Data()[_HcIx(6u, d0 * 4u
								+ _RandCond(s, c, t, (uint32)i + 77u, 4u), df)] += 1u;
							_hc.Data()[_HcIx(7u, d0 * 2u
								+ _RandCond(s, c, t, (uint32)i + 313u, 2u), df)] += 1u;
							continue;
						}
						if (_a3)
						{
							// ⭐ 218 — **행동 ↔ 언어를 같은 눈금으로**
							const uint32 capF = (firstChg >= 0 && i == firstChg) ? 1u : 0u;
							const uint32 capA = chgT[i] ? 1u : 0u;
							const uint32 rnd2 = _RandCond(s, c, t, (uint32)i + 313u, 2u);
							_hc.Data()[_HcIx(0u, d0, df)] += 1u;
							_hc.Data()[_HcIx(1u, d0 * 9u + yawT[u], df)] += 1u;                 // ⭐ 행동
							_hc.Data()[_HcIx(2u, d0 * 9u
								+ _RandCond(s, c, t, (uint32)i, 9u), df)] += 1u;                // 음성(9)
							_hc.Data()[_HcIx(3u, d0 * 2u + capF, df)] += 1u;                    // ⭐ 캡션 자리1
							_hc.Data()[_HcIx(4u, d0 * 2u + capA, df)] += 1u;                    // ⭐ 캡션 천장
							_hc.Data()[_HcIx(5u, d0 * 2u + rnd2, df)] += 1u;                    // 음성(2)
							_hc.Data()[_HcIx(6u, d0 * 4u + dep, df)] += 1u;                     // 견줌
							continue;
						}
						if (_a2)
						{
							// ⭐ 215 — 계급을 다시 나눈다(214 의 갈래 ㈂)
							_hc.Data()[_HcIx(0u, d0, df)] += 1u;
							_hc.Data()[_HcIx(1u, d0 * kActCls + ac, df)] += 1u;               // 214 재현
							_hc.Data()[_HcIx(2u, d0 * 9u + yawT[u], df)] += 1u;               // dYaw 만
							_hc.Data()[_HcIx(3u, d0 * kActFine + finT[u], df)] += 1u;         // ⭐ 천장
							_hc.Data()[_HcIx(4u, d0 * kDirCls + dz, df)] += 1u;               // ⭐ 자율만
							_hc.Data()[_HcIx(5u, d0 * kActFine
								+ _RandCond(s, c, t, (uint32)i, kActFine), df)] += 1u;        // 음성(54)
							_hc.Data()[_HcIx(6u, d0 * kDirCls
								+ _RandCond(s, c, t, (uint32)i + 977u, kDirCls), df)] += 1u;  // 음성(10)
							_hc.Data()[_HcIx(7u, d0 * 4u + dep, df)] += 1u;                   // 견줌
							continue;
						}
						_hc.Data()[_HcIx(0u, d0, df)] += 1u;
						_hc.Data()[_HcIx(1u, d0 * kActCls + ac, df)] += 1u;
						_hc.Data()[_HcIx(2u, d0 * kActCls
							+ _RandCond(s, c, t, (uint32)i, kActCls), df)] += 1u;
						_hc.Data()[_HcIx(3u, d0 * 4u + dep, df)] += 1u;
						_hc.Data()[_HcIx(4u, (d0 * kActCls + ac) * 4u + dep, df)] += 1u;
						_hc.Data()[_HcIx(5u, d0 * kQ4 + q1, df)] += 1u;
					}
				}   // for t — ⭐ 218 이 캡션 사전계산을 넣으며 블록이 됐다
				// ⚖️✂️ 238 — **발동 수**(에피소드 하나가 끝난 자리에서 센다) ⇒ 배관 관문
				_slowSum += (double)w.SlowHits();
				_cutSum  += (double)w.CutHits();
				++_epiN;
				// ⚖️⚖️ 264 — **몸의 서명**(에피소드 하나가 끝난 자리에서 센다)
				//   ㉡ 반사 발동 수 · ㉢ 먹이 가중(전체 ↔ `_e` 낮을 때) · 독 가중
				//   ⚠️ ㉢ 이 **낮을 때 더 작으면 반사의 부호가 틀린 것**이다(그것을 이 자로 잡는다)
				_biasSum += (double)w.BiasHits();
				_pickSum += (double)w.PickCount();      // ⭐ 📌 D71 — 발동 수의 분모
				if (w.FoodWN() > 0u)    { _fwAllSum += w.FoodWMean();    ++_fwAllN; }
				if (w.FoodWLowN() > 0u) { _fwLowMSum += w.FoodWMeanLow(); ++_fwLowMN; }
				if (w.FoodWN() > 0u)    { _pwAllSum += w.PoisWMean(); }
				// ⭐⭐ 242 — **이어짐** = 한 물체가 연속으로 보이는 시각 수(241 의 기제 가설)
				//   ⚙️ 241: *"느리면 한 물체가 여러 시각에 걸쳐 이어진다"* ⇒ ★ 그것을 여기서 잰다.
				//   ⚠️ 239 는 반대를 냈다(감쇠가 **바뀌는 물체를 1.55배 늘린다**) ⇒ 둘이 어긋난다
				//     ⇒ ⭐ **이 자가 그것을 가른다** — 「보임의 이어짐」과 「방향의 바뀜」은 다른 것이다.
				for (int i = 0; i < kShapes; ++i)
				{
					uint32 run = 0u;
					for (uint32 u = 0; u <= kUMax; ++u)
					{
						if (okT[u][i]) { ++run; continue; }
						if (run > 0u) { _runSum += (double)run; ++_runN; }
						run = 0u;
					}
					if (run > 0u) { _runSum += (double)run; ++_runN; }
				}
			}
		_splitFrac  = (splitTot  == 0u) ? 0.0 : (double)splitN  / (double)splitTot;
		_zsplitFrac = (zsplitTot == 0u) ? 0.0 : (double)zsplitN / (double)zsplitTot;
		_noneFrac   = (noneTot   == 0u) ? 0.0 : (double)noneN   / (double)noneTot;
		_splitVis   = (visTot == 0u) ? 0.0 : (double)splitVisN  / (double)visTot;
		_zsplitVis  = (visTot == 0u) ? 0.0 : (double)zsplitVisN / (double)visTot;
		_actShare   = (shareN == 0u) ? 0.0 : shareSum / (double)shareN;
	}

	static void _RunA()
	{
		_SetDir(true, _dirThr);
		_aSweep = true;
		_DepQuartiles(3u, MLTWorldCfg::kAutoMany);
		LogA("[mlt] 🧭 ══════════════════════════════════════════════\n");
		LogA("[mlt] 🧭 **회차 214 · 행동의 여지** — 칸 3(`P4`)을 짓기 전에 **학습 0** 으로 잰다\n");
		LogA("[mlt] 🧭   ⚙️ 공용 **규율 12**: *\"처방을 돌리기 전에 「여지」를 학습 0 으로 재라.\"*\n");
		LogA("[mlt] 🧭   ⚠️⚠️ 행동 축을 넣는 것은 **비싸다** — 189 실측으로 축을 늘리면 `P3` 이 +4.6%%p 나빠졌다\n");
		LogA("[mlt] 🧭   ⚠️ **자를 안 바꾼다**(규율 58) — 197·198 의 `_CStat` 그대로 · **팔 표만** 갈았다\n");
		LogA("[mlt] 🧭      ⇒ ★ 그래야 「행동의 여지」가 **「깊이의 여지」와 같은 눈금**이 된다\n");
		LogA("[mlt] 🧭   ⭐ 그리고 ***「가름」이 이 회차의 진짜 물음***이다(회차 107 의 반사실 자):\n");
		LogA("[mlt] 🧭      같은 자리에서 **행동만 뒤집어** 한 걸음 굴리면 표적이 **달라지나**\n");
		LogA("[mlt] 🧭      ⚠️ 0 이면 ㈁(행동을 읽는다)이 **원리적으로 못 서고**\n");
		LogA("[mlt] 🧭      ⚠️ 1 이면 ㈂(오귀속률)이 **원리적으로 정의 불가**다(`mltworld` ⑨ 의 거울)\n");
		LogA("[mlt] 🧭      ⇒ ★ 이 한 숫자가 ***칸 3 이 어느 세계에서 성립하는가***를 정한다(규율 76)\n");
		LogA("[mlt] 🧭      ⓘ 견줄 자리 = **115 의 28.2%%**(옛 세계 · 옛 표적)\n");
		LogA("[mlt] 🧭   ⚠️ 「상수로 둔 것」 — 행동 계급을 `dYaw`×`fwd` **둘**로 좁혔다(3×3=9)\n");
		LogA("[mlt] 🧭      ★ 근거는 *\"화면 흐름을 지배할 것\"* 이라는 **손계산이고 측정이 아니다**\n");
		LogA("[mlt] 🧭   📏 깊이 4분위 문턱 %.2f · %.2f · %.2f\n",
			(double)_depThr[0], (double)_depThr[1], (double)_depThr[2]);
		LogA("[mlt] 🧭   ── 📊 세계 × 조건 — ⭐ **순 여지 비**(음성 대조를 뺀 값 ÷ 분모) ──\n");
		LogA("[mlt] 🧭     세계        분모H    ⭐**행동**  +깊이   행동+깊이  2시각   ⭐**가름**  「없음」\n");
		static const char* wn[4] = { "0 옛 세계", "1 반사   ", "2 궤도   ", "3 가속   " };
		double bestR = -1.0e9; int bestW = 0; double split[4], room1[4], base0 = 0.0;
		for (int w2 = 0; w2 < 4; ++w2)
		{
			_FillA(w2);
			double base = 0.0, dm = 0.0, per = 0.0; uint32 used = 0u;
			_CStat(0u, base, dm, 0.0, used, per);
			if (w2 == 0) base0 = base;
			double rm[6];
			for (uint32 a = 1u; a < 6u; ++a)
			{
				double hc = 0.0, r = 0.0, p2 = 0.0; uint32 u2 = 0u;
				_CStat(a, hc, r, base, u2, p2); rm[a] = r;
			}
			// ⭐ 음성 대조(㈂)를 뺀 **순** 여지 — 규율 2 · 공용 14
			const double bias = rm[2];
			const double netA = rm[1] - bias;
			room1[w2] = (base > 1.0e-9) ? 100.0 * netA / base : 0.0;
			split[w2] = _splitFrac;
			if (room1[w2] > bestR) { bestR = room1[w2]; bestW = w2; }
			LogA("[mlt] 🧭     %s  %.4f  %6.1f%%  %5.1f%%  %7.1f%%  %5.1f%%   %6.1f%%   %5.1f%%\n",
				wn[w2], base, room1[w2],
				(base > 1.0e-9) ? 100.0 * (rm[3] - bias) / base : 0.0,
				(base > 1.0e-9) ? 100.0 * (rm[4] - bias) / base : 0.0,
				(base > 1.0e-9) ? 100.0 * (rm[5] - bias) / base : 0.0,
				100.0 * _splitFrac, 100.0 * _noneFrac);
		}
		LogA("[mlt] 🧭   ── 🚪 관문 ──\n");
		// ⚠️ **220 이 짝을 바꿨다** — 197·198 의 **0.3191** 은 `_Pt(3)`(dt 0.25) 자리이고
		//   이 자는 이제 **몸통의 자리**(dt 1.0 · amp 5.0)에서 돈다 ⇒ **규율 65**(그 자리의 값).
		LogA("[mlt] 🧭     ⭐ ① **배관** — 세계 0 분모 **%.4f** ↔ **220 의 0.4321**(몸통 자리) → %s\n",
			base0, (Abs((float)(base0 - 0.4321)) < 0.005)
				? "✅ **같은 자다** — ★ 팔 표만 갈았고 자는 안 건드렸다"
				: "⛔⛔ **자가 달라졌다** — ★ 여기서 멈추고 원인을 찾는다");
		LogA("[mlt] 🧭     ⭐ ② **표제(가름)** — 궤도 세계 **%.1f%%**\n", 100.0 * split[2]);
		LogA("[mlt] 🧭        판정 → %s\n",
			(split[2] < 0.05)
				? "⛔⛔ **행동이 표적을 거의 안 정한다** ⇒ ㈁ 이 **원리적으로 못 선다** — 세계를 골라야 한다"
				: ((split[2] > 0.95)
					? "⛔⛔ **행동이 전부를 정한다** ⇒ ㈂(오귀속률)이 **정의 불가** — 자율 몫을 살려야 한다"
					: "✅ ⭐ **분모가 산다** — ★ 칸 3 을 이 세계에서 잴 수 있다"));
		LogA("[mlt] 🧭     ⭐ ③ **행동의 여지**(궤도) **%.1f%%** ↔ 198 의 최고 **23.2%%** → %s\n",
			room1[2], (room1[2] >= 15.0)
				? "✅✅ ⭐ **행동이 깊이만큼 나른다** ⇒ 축을 더할 값이 있다"
				: ((room1[2] >= 5.0)
					? "🔶 **작다** — ⚠️ 축 하나의 대가(189: `P3` +4.6%%p)와 견줘 사람이 정한다"
					: "⛔ **거의 0** ⇒ ★ 행동 축을 더해도 몸통이 쓸 것이 없다"));
		LogA("[mlt] 🧭        ⚠️⚠️ 이 둘은 **다른 것을 잰다** — 「가름」은 **세계가 아는 것**이고\n");
		LogA("[mlt] 🧭           「여지」는 ***행동값 아홉 계급이 나르는 것***이다(양자화의 대가가 들어 있다)\n");
		LogA("[mlt] 🧭           ⇒ ★ 「가름」이 크고 「여지」가 작으면 그것은 **계급을 잘못 나눈 것**이다\n");
		LogA("[mlt] 🧭     ⭐ ④ **음성 대조** — 무작위 조건의 여지를 뺐다(규율 2 · 공용 14)\n");
		LogA("[mlt] 🧭        ⚠️ 순 여지가 **음수**로 나오면 그 팔은 **편향보다도 못한 것**이다\n");
		LogA("[mlt] 🧭     ⓘ ⑤ 최고 = 세계 **%s** 비 **%.1f%%**\n", wn[bestW], bestR);
		LogA("[mlt] 🧭 ══════════════════════════════════════════════\n");
		_aSweep = false;
	}

	// ══════════════════════════════════════════════════════════════════
	// ⭐ 회차 215 — **계급을 다시 나눈다**(214 의 갈래 ㈂ · 사람이 골랐다)
	// ══════════════════════════════════════════════════════════════════
	static void _RunA2()
	{
		_SetDir(true, _dirThr);
		_aSweep = true; _a2 = true;
		_DepQuartiles(3u, MLTWorldCfg::kAutoMany);
		LogA("[mlt] 🧭 ══════════════════════════════════════════════\n");
		LogA("[mlt] 🧭 **회차 215 · 계급을 다시 나눈다** — 214 의 갈래 ㈂(학습 0)\n");
		LogA("[mlt] 🧭   ⚙️ 물음: *\"「가름 47.5%%」와 「여지 2.0%%」의 격차가 **계급 탓**인가?\"*\n");
		LogA("[mlt] 🧭      ★ 214 의 하네스가 스스로 찍었다: *\"「가름」이 크고 「여지」가 작으면\n");
		LogA("[mlt] 🧭        **계급을 잘못 나눈 것**\"* ⇒ ⭐ **천장을 먼저 계산한다**(규율 49)\n");
		LogA("[mlt] 🧭   🔮 **주 예측**(⚠️ 214 는 이것을 안 적고 돌렸다 — 규율 7 위반을 갚는다)\n");
		LogA("[mlt] 🧭      ㉠ 팔 ㈁(현행 9) = **2.0%%** 재현 ⇒ ⚠️ 같은 코드라 **비트 동일**이어야 한다\n");
		LogA("[mlt] 🧭      ⭐ ㉡ **천장(54계급)도 ≤ 5%%** — ★ 「가름」은 *\"뒤집으면 달라지나\"*(큰 변화)이고\n");
		LogA("[mlt] 🧭         「여지」는 *\"값을 알면 더 맞히나\"* 다 ⇒ 궤도는 **자율이 화면 흐름을 지배**한다\n");
		LogA("[mlt] 🧭      ⭐ ㉢ **자율만 방향**(궤도) **≥ 30%%** — 자율이 지배적이면 그것이 곧 답에 가깝다\n");
		LogA("[mlt] 🧭      ㉣ **옛 세계는 반대** — 자율만 방향 ≤ 10%%(도형 14 중 3 만 자율)\n");
		LogA("[mlt] 🧭      ㉤ 음성 대조 raw 가 **칸 수에 비례**(54칸 > 10칸 · 빈 칸 편향)\n");
		LogA("[mlt] 🧭   ⚠️ 「상수로 둔 것」 — 천장을 **54**(`dYaw`3×`fwd`3×`side`3×`dPitch`2)로 끊었다\n");
		LogA("[mlt] 🧭      ★ `up` 을 뺀 근거는 *\"수직이 화면 흐름에 가장 덜 기여할 것\"* = **손계산이다**\n");
		LogA("[mlt] 🧭      ⚠️ 243계급이면 칸이 2430 이라 상한(%u)을 넘는다 ⇒ **못 넣는다**\n", kCondMax);
		LogA("[mlt] 🧭   ── 📊 세계 × 계급 — ⭐ **순 여지 비**(음성 짝을 뺀 값 ÷ 분모) ──\n");
		LogA("[mlt] 🧭     세계        분모H   ㈁행동9  ㈂dYaw9  ⭐㈃천장54  ⭐㈄자율만  ㈇깊이  가름  ⭐보임만  0행동\n");
		static const char* wn[4] = { "0 옛 세계", "1 반사   ", "2 궤도   ", "3 가속   " };
		double base0 = 0.0, cap[4], aut[4], raw5 = 0.0, raw6 = 0.0, a9[4], sv[4], zv[4];
		for (int w2 = 0; w2 < 4; ++w2)
		{
			_FillA(w2);
			double base = 0.0, dm = 0.0, per = 0.0; uint32 used = 0u;
			_CStat(0u, base, dm, 0.0, used, per);
			if (w2 == 0) base0 = base;
			double rm[8];
			for (uint32 a = 1u; a < 8u; ++a)
			{
				double hc = 0.0, r = 0.0, p2 = 0.0; uint32 u2 = 0u;
				_CStat(a, hc, r, base, u2, p2); rm[a] = r;
			}
			if (w2 == 2) { raw5 = rm[5]; raw6 = rm[6]; }
			// ⚠️⚠️ **음성 짝이 다르다** — ㈃·㈅ 는 54칸 · ㈄·㈆ 는 10칸(공용 규율 14)
			const double nA9   = rm[1] - rm[6];      // 9칸 ↔ 10칸(가장 가까운 짝)
			const double nYaw  = rm[2] - rm[6];
			const double nCap  = rm[3] - rm[5];      // ⭐ 54 ↔ 54
			const double nAuto = rm[4] - rm[6];      // ⭐ 10 ↔ 10
			const double nDep  = rm[7] - rm[6];
			const double d = (base > 1.0e-9) ? 100.0 / base : 0.0;
			cap[w2] = nCap * d; aut[w2] = nAuto * d; a9[w2] = nA9 * d;
			sv[w2] = _splitVis; zv[w2] = _zsplitVis;
			LogA("[mlt] 🧭     %s  %.4f  %6.1f%%  %6.1f%%  %8.1f%%  %8.1f%%  %5.1f%%  %4.1f%%  **%5.1f%%**  %4.1f%%\n",
				wn[w2], base, nA9 * d, nYaw * d, nCap * d, nAuto * d, nDep * d,
				100.0 * _splitFrac, 100.0 * _splitVis, 100.0 * _zsplitVis);
		}
		LogA("[mlt] 🧭   ── 🚪 관문 ──\n");
		// ⚠️ 220 이 짝을 바꿨다(위 ① 과 같은 이유 — 규율 65)
		LogA("[mlt] 🧭     ⭐ ① **배관** — 세계 0 분모 **%.4f** ↔ **220 의 0.4321**(몸통 자리) → %s\n",
			base0, (Abs((float)(base0 - 0.4321)) < 0.005)
				? "✅ **같은 자다**"
				: "⛔⛔ **자가 달라졌다** — ★ 여기서 멈춘다");
		LogA("[mlt] 🧭     ⭐ ② **표제 — 천장(궤도) %.1f%%**\n", cap[2]);
		LogA("[mlt] 🧭        판정 → %s\n",
			(cap[2] >= 15.0)
				? "⛔⛔ **계급 탓이었다** — ★ 214 의 2.0%% 는 **자를 잘못 나눈 것**이다"
				: ((cap[2] >= 5.0)
					? "🔶 **일부는 계급 탓** — ⚠️ 그래도 깊이(23.3%%)에 못 미친다"
					: "✅ ⭐ **계급 탓이 아니다** — ★ ***궤도에서 행동은 정말로 안 나른다***"));
		LogA("[mlt] 🧭        ⓘ 214 의 현행 9계급(궤도) **%.1f%%** ↔ 천장 54계급 **%.1f%%**\n", a9[2], cap[2]);
		LogA("[mlt] 🧭     ⭐ ③ **자율만 방향** — 궤도 **%.1f%%** ↔ 옛 세계 **%.1f%%**\n", aut[2], aut[0]);
		LogA("[mlt] 🧭        ⇒ %s\n",
			(aut[2] > aut[0])
				? "✅ ⭐ **궤도에서 자율이 지배한다** — ★ 214 의 그림이 **다른 길로 확인됐다**(규율 68)"
				: "⚠️ **예상과 다르다** — ★ 자율/행동 분해를 다시 본다");
		// ⛔⛔⛔ **215 의 손계산이 214 의 표제를 흔들었다** — 「가름」 + 「없음」 = **정확히 100%**
		//   ⇒ ★ 그 자는 ***"물체가 보이나"*** 를 재고 있었다(규율 87 의 분모 자리 · 규율 88 의 형제).
		//   ⇒ ⭐ **보이는 것만** 센 것이 진짜 분모다 — 아래가 그 값이다.
		LogA("[mlt] 🧭     ⭐ ④ **214 의 「가름」이 무엇을 재고 있었나**\n");
		LogA("[mlt] 🧭        ⚠️⚠️ 네 세계에서 **가름 + 「없음」 = 정확히 100%%** 였다\n");
		LogA("[mlt] 🧭           ⇒ ★ 그 자는 ***\"물체가 보이나\"*** 를 재고 있었다(규율 87 의 분모)\n");
		LogA("[mlt] 🧭        ⭐ **보이는 것만** 센 가름 — 궤도 **%.1f%%** · 옛 **%.1f%%** · 가속 **%.1f%%**\n",
			100.0 * sv[2], 100.0 * sv[0], 100.0 * sv[3]);
		LogA("[mlt] 🧭        판정 → %s\n",
			(sv[2] > 0.95)
				? "⛔⛔ **포화했다** — ★ ***㈂(오귀속률)이 정의 불가에 가깝다*** ⇒ 214 의 ② 가 뒤집힌다"
				: ((sv[2] < 0.05)
					? "⛔ **행동이 표적을 거의 안 정한다** ⇒ ㈁ 이 원리적으로 못 선다"
					: "✅ ⭐ **분모가 산다** — ★ 214 의 ② 가 (다른 숫자로) 유지된다"));
		LogA("[mlt] 🧭        ⓘ 0-행동 기준(보임만) — 궤도 **%.1f%%** · 옛 **%.1f%%**\n",
			100.0 * zv[2], 100.0 * zv[0]);
		LogA("[mlt] 🧭        ⚠️ 0-행동 가름은 **더 작아야** 한다(뒤집기가 0 보다 큰 개입이다) → %s\n",
			(zv[2] <= sv[2] + 1.0e-9) ? "✅" : "⛔ **더 크다** — ★ 배관을 다시 본다");
		LogA("[mlt] 🧭     ⭐ ⑤ **음성 대조가 칸 수에 비례하나**(궤도) — 54칸 raw **%.4f** ↔ 10칸 raw **%.4f** → %s\n",
			raw5, raw6, (raw5 > raw6) ? "✅ **비례한다**(빈 칸 편향)" : "⚠️ **안 그렇다**");
		LogA("[mlt] 🧭 ══════════════════════════════════════════════\n");
		_aSweep = false; _a2 = false;
	}

	// ══════════════════════════════════════════════════════════════════
	// ⭐ 회차 216 — **손잡이 둘로 「행동 ↔ 자율」 비를 민다**(캔버스 3회차 · 규율 33)
	// ══════════════════════════════════════════════════════════════════
	//   ⭐ `mltworld` 가 직접 적어 뒀다: *"`dtMul` = **카메라 몫을 줄이는 유일한 손잡이**"*
	//     ⇒ ★ 그러니 손잡이가 **둘**이다: `amp`(자율 진폭) · `dtMul`(카메라 몫)
	//   ⚠️⚠️ 215 가 「가름」이 **100% 로 포화**함을 확정했다(부호 반전 = 최대 개입)
	//     ⇒ ⭐ 그래서 **연속량 자**(행동 몫)를 새로 넣었다 — **규율 31** 이 가리킨 그 처방이다.
	static void _RunAmp()
	{
		_ptIntent = true;      // ⭐ 232 — 이 판은 **손잡이를 일부러 민다**(방벽 ② 의 거짓 경고를 막는다)
		_SetDir(true, _dirThr);
		_aSweep = true; _a2 = true;
		_DepQuartiles(3u, MLTWorldCfg::kAutoMany);
		LogA("[mlt] 🧭 ══════════════════════════════════════════════\n");
		LogA("[mlt] 🧭 **회차 216 · 손잡이 둘로 「행동 ↔ 자율」 비를 민다**(학습 0 · 궤도 세계)\n");
		LogA("[mlt] 🧭   ⭐ `mltworld` 가 적어 뒀다: *\"`dtMul` = **카메라 몫을 줄이는 유일한 손잡이**\"*\n");
		LogA("[mlt] 🧭   ⚠️⚠️ 215: 「가름」이 **100%% 로 포화**했다(부호 반전 = 최대 개입)\n");
		LogA("[mlt] 🧭      ⇒ ⭐ **연속량 자**를 새로 넣었다 — **규율 31**(*이진은 크기가 없다*)의 처방\n");
		LogA("[mlt] 🧭      ⚙️ **행동 몫** = |Δ행동| / (|Δ행동| + |Δ자율|) · Δ자율 = **카메라를 세운** 반사실\n");
		LogA("[mlt] 🧭   🔮 **주 예측**\n");
		LogA("[mlt] 🧭      ㉠ 기준점(amp 1 · dt .25) **행동 몫 ≥ 95%%**(215 의 그 관찰)\n");
		LogA("[mlt] 🧭      ⭐ ㉡ 행동 몫이 **양쪽 손잡이로 단조**하고 극단에서 **≤ 50%%**\n");
		LogA("[mlt] 🧭      ⭐ ㉢ **「보임만 가름」은 안 내려온다(≥ 95%% 유지)** — 부호 반전이 최대 개입이라\n");
		LogA("[mlt] 🧭         ⇒ ★ 맞으면 ***처방은 손잡이가 아니라 「반사실의 크기」다***\n");
		LogA("[mlt] 🧭      ㉣ 분모 H 가 행동 몫이 낮을수록 **커진다** · ㉤ 행동 여지가 행동 몫과 **같은 방향**\n");
		LogA("[mlt] 🧭   ⚠️ 「상수로 둔 것」 — **선형 분해**(Δ전체 = Δ자율 + Δ행동)는 **근사**다(투영이 비선형)\n");
		LogA("[mlt] 🧭      그리고 격자를 `amp`{1,5,25} × `dtMul`{1, .25, .0625} 로 끊은 것도 **손계산**이다\n");
		// ⛔⛔ **216 1차가 잡은 결함 ②** — `_ShapeWorld` 의 **궤도 가지(`_w2 == 2`)는 `amp` 를 안 쓴다**
		//   (`ang2 = ang + w*t` 만 쓴다 · `amp` 는 **반사(1)·가속(3)** 에서만 산다)
		//   ⇒ ⚠️ 그래서 1차의 `amp` 세 행이 **소수 4자리까지 동일**했다 ⇒ ★ 축을 잘못 골랐던 것이다.
		//   ⇒ ⭐ **축을 「세계 × `dtMul`」 로 바꾼다** — `dtMul` 이 세계 파일이 말한 **유일한 손잡이**다.
		//   ⚠️ 세계 코드는 **안 고친다**(검산 사슬).
		static const int   ws[3]  = { 2, 3, 3 };            // 궤도 · 가속 · 가속(amp 25)
		static const float amps[3] = { 1.0f, 1.0f, 25.0f };
		static const float dts[3]  = { 1.0f, 0.25f, 0.0625f };
		static const char* rn[3] = { "궤도       ", "가속 amp1  ", "가속 amp25 " };
		LogA("[mlt] 🧭   ── 📊 격자(세계 × `dtMul`) ──\n");
		LogA("[mlt] 🧭     세계        dtMul   분모H   ⭐**행동몫**  ⭐가름(보임만)  ㈂dYaw9여지  「없음」\n");
		double sh[3][3], sp[3][3], hh[3][3], rm2[3][3];
		for (uint32 ia = 0; ia < 3u; ++ia)
			for (uint32 id = 0; id < 3u; ++id)
			{
				_ampOv = amps[ia]; _dtOv = dts[id];
				_FillA(ws[ia]);
				double base = 0.0, dm = 0.0, per = 0.0; uint32 used = 0u;
				_CStat(0u, base, dm, 0.0, used, per);
				double r2 = 0.0, r6 = 0.0, hc = 0.0, p2 = 0.0; uint32 u2 = 0u;
				_CStat(2u, hc, r2, base, u2, p2);
				_CStat(6u, hc, r6, base, u2, p2);      // 음성 짝(10칸)
				const double net = (base > 1.0e-9) ? 100.0 * (r2 - r6) / base : 0.0;
				sh[ia][id] = _actShare; sp[ia][id] = _splitVis; hh[ia][id] = base; rm2[ia][id] = net;
				LogA("[mlt] 🧭     %s %6.4f  %.4f     **%5.1f%%**       %6.1f%%       %6.1f%%     %5.1f%%\n",
					rn[ia], (double)dts[id], base,
					100.0 * _actShare, 100.0 * _splitVis, net, 100.0 * _noneFrac);
			}
		_ampOv = -1.0f; _dtOv = -1.0f;
		LogA("[mlt] 🧭   ── 🚪 관문 ──\n");
		// ⚠️ 기준점 = amp 1 · dt .25 (= `_Pt(3)` 이고 칸 1·2 가 돌던 자리)
		LogA("[mlt] 🧭     ⭐ ① **배관** — 기준점(amp 1 · dt .25) 분모 **%.4f** ↔ 214·215 의 **0.1534** → %s\n",
			hh[0][1], (Abs((float)(hh[0][1] - 0.1534)) < 0.005)
				? "✅ **그 자리다**" : "⛔⛔ **다르다** — ★ 손잡이 덮어쓰기가 샜다");
		LogA("[mlt] 🧭     ⭐ ② **㉠** 기준점 행동 몫 **%.1f%%** ≥ 95%% → %s\n",
			100.0 * sh[0][1], (sh[0][1] >= 0.95) ? "✅ **215 의 관찰이 숫자가 됐다**" : "⛔");
		LogA("[mlt] 🧭     ⭐ ③ **㉡ 손잡이가 듣나**(궤도) — 행동 몫 `dtMul` 1.0 **%.1f%%** → .0625 **%.1f%%**\n",
			100.0 * sh[0][0], 100.0 * sh[0][2]);
		LogA("[mlt] 🧭        판정 → %s\n",
			(sh[0][2] <= 0.50)
				? "✅✅ ⭐ **손잡이가 듣는다** — ★ 「행동 ↔ 자율」 비를 우리가 정할 수 있다"
				: ((sh[0][2] < sh[0][0] - 0.05)
					? "🔶 **움직이지만 50%% 를 못 넘긴다** — ★ 더 극단이 필요하다"
					: "⛔⛔ **손잡이가 안 듣는다** — ★ 그러면 이 세계로는 칸 3 을 못 연다"));
		LogA("[mlt] 🧭     ⭐ ④ **㉢ 「가름」이 따라오나**(궤도) — 1.0 **%.1f%%** → .0625 **%.1f%%**\n",
			100.0 * sp[0][0], 100.0 * sp[0][2]);
		LogA("[mlt] 🧭        판정 → %s\n",
			(sp[0][2] >= 0.95)
				? "⭐ **안 내려온다 — 예측 ㉢ 적중** ⇒ ★ ***처방은 손잡이가 아니라 「반사실의 크기」다***"
				: "⛔ **내려온다** — ★ 그러면 ㉢ 이 틀렸고 손잡이만으로 ㈂ 가 산다");
		LogA("[mlt] 🧭     ⭐ ⑤ **표제 — 카메라 몫이 행동 여지를 정한다**(궤도)\n");
		LogA("[mlt] 🧭        `dtMul` 1.0 여지 **%.1f%%** × 분모 **%.4f** = **%.4f 나트**\n",
			rm2[0][0], hh[0][0], rm2[0][0] * hh[0][0] / 100.0);
		LogA("[mlt] 🧭        `dtMul` .25 여지 **%.1f%%** × 분모 **%.4f** = **%.4f 나트**(칸 1·2 가 돌던 자리)\n",
			rm2[0][1], hh[0][1], rm2[0][1] * hh[0][1] / 100.0);
		LogA("[mlt] 🧭        가속 amp1 · 1.0 = **%.4f 나트** · 가속 amp25 · 1.0 = **%.4f 나트**\n",
			rm2[1][0] * hh[1][0] / 100.0, rm2[2][0] * hh[2][0] / 100.0);
		LogA("[mlt] 🧭        ⇒ %s\n",
			(rm2[0][0] * hh[0][0] > rm2[1][0] * hh[1][0])
				? "⭐ **궤도 + `dtMul` 1.0 이 가속보다 낫다** ⇒ ★ ***세계를 안 바꿔도 된다***"
				: "⚠️ **가속이 낫다** — ★ 세계를 옮기는 값을 다시 잰다");
		LogA("[mlt] 🧭     ⚠️ ⑥ **대가** — 분모 H 가 %.4f(.25) → %.4f(1.0) = **%.1f배**\n",
			hh[0][1], hh[0][0], (hh[0][1] > 1.0e-9) ? hh[0][0] / hh[0][1] : 0.0);
		LogA("[mlt] 🧭        ★ 표적이 그만큼 **어려워진다** ⇒ ⚠️ 칸 1·2 의 `P3` 를 그 자리에서 다시 재야 한다\n");
		LogA("[mlt] 🧭 ══════════════════════════════════════════════\n");
		_aSweep = false; _a2 = false; _ptIntent = false;   // ⚠️ 232 — 안 되돌리면 **방벽이 조용히 꺼진다**
	}

	// ══════════════════════════════════════════════════════════════════
	// ⭐ 회차 218 — **균형점이 있나**(217 의 갈래 ㈁ · 216 의 실수를 갚는다)
	// ══════════════════════════════════════════════════════════════════
	// ⭐ 회차 226 — **상쇄의 천장 ↔ 타자의 여지**(사람이 잡은 그 물음 · 공용 규율 18-a)
	static void _RunSelf()
	{
		_SetDir(true, _dirThr);
		_aSweep = true; _a4 = true;
		_DepQuartiles(3u, MLTWorldCfg::kAutoMany);
		LogA("[mlt] 🧭 ══════════════════════════════════════════════\n");
		LogA("[mlt] 🧭 **회차 226 · 상쇄의 천장을 먼저 잰다**(학습 0 · 90초)\n");
		LogA("[mlt] 🧭   ⚙️ 👤 사람이 잡았다: *\"과도한 자기 사본 처리가 오히려 **타자와 엮어야 할 것**을\n");
		LogA("[mlt] 🧭      방해할까\"* ⇒ ★ 표적이 **타자(자율 물체)의 방향**인데 자기 성분 예측에\n");
		LogA("[mlt] 🧭      손실을 주면 그것이 예산을 먹는다 ⇒ ⭐ **공용 규율 18-a**\n");
		LogA("[mlt] 🧭   ⚠️ **「상쇄」와 「분리」는 다른 것**이다 — 상쇄는 자기를 **지우고** 분리는 **각각 표현**한다\n");
		LogA("[mlt] 🧭   ⇒ ★★ 그래서 손실을 넣기 **전에** 천장을 재고 **타자 자를 같은 분모로 같은 판에** 둔다\n");
		LogA("[mlt] 🧭   ⭐ **순 사본 천장 = 미래 흐름 − 과거 흐름**\n");
		LogA("[mlt] 🧭      ⚠️ 「미래 흐름」은 **완벽한 사본**을 가정한 것이라 **천장**이다\n");
		LogA("[mlt] 🧭        (실제 모델은 행동값에서 그것을 **추정**해야 한다 ⇒ 실제는 이보다 작다)\n");
		LogA("[mlt] 🧭   ⚠️ 「상수로 둔 것」 — 흐름을 **보이는 물체 이동 평균**으로 뒀다 · 문턱 %.2f 픽셀\n",
			(double)_dirThr);
		LogA("[mlt] 🧭   ── 📊 세계 × (자기 ↔ 타자) — ⭐ **순 여지 비**(음성 짝을 뺀 값 ÷ 분모) ──\n");
		LogA("[mlt] 🧭     세계        분모H   ⭐**미래흐름**  과거흐름  ⭐**순사본**   깊이   캡션천장\n");
		static const int   ws[2]  = { 2, 3 };
		static const char* wn2[2] = { "궤도", "가속" };
		for (uint32 iw = 0; iw < 2u; ++iw)
		{
			_ampOv = kTrAmp; _dtOv = kTrDt;      // ⭐ 220 — **몸통의 자리**
			_FillA(ws[iw]);
			double base = 0.0, dm = 0.0, per = 0.0; uint32 used = 0u;
			_CStat(0u, base, dm, 0.0, used, per);
			double r[8]; for (uint32 a = 1u; a < 8u; ++a)
			{ double hc = 0.0, rr = 0.0, p2 = 0.0; uint32 u2 = 0u; _CStat(a, hc, rr, base, u2, p2); r[a] = rr; }
			const double d = (base > 1.0e-9) ? 100.0 / base : 0.0;
			const double fF = (r[1] - r[3]) * d;      // 미래 흐름(음성 10 짝)
			const double fP = (r[2] - r[3]) * d;      // 과거 흐름(같은 짝)
			const double net = fF - fP;               // ⭐ 순 사본 천장
			const double dp = (r[4] - r[6]) * d;      // 깊이(타자)
			const double cp = (r[5] - r[7]) * d;      // 캡션 천장(타자)
			LogA("[mlt] 🧭     %s %6.4f  %9.1f%%  %7.1f%%  %8.1f%%  %5.1f%%  %7.1f%%\n",
				wn2[iw], base, fF, fP, net, dp, cp);
			if (iw == 0u)
			{
				LogA("[mlt] 🧭   ── 🚪 관문(궤도 = 몸통이 도는 세계) ──\n");
				LogA("[mlt] 🧭     ⭐ ① **표제 — 순 사본 천장이 타자 여지보다 크나**\n");
				LogA("[mlt] 🧭        순 사본 **%.1f%%** ↔ 깊이 **%.1f%%** · 캡션 **%.1f%%**\n", net, dp, cp);
				LogA("[mlt] 🧭        판정 → %s\n",
					(net > dp && net > cp)
						? "✅ ⭐ **사본이 타자보다 크다** — ★ 손실로 넣을 값이 있다"
						: ((net > 5.0)
							? "🔶 **작지 않지만 타자보다 작다** — ⚠️ 예산을 뺏길 위험이 실재한다(규율 18-a)"
							: "⛔ **거의 0** ⇒ ★★ ***사본을 손실로 넣을 이유가 없다*** — 회차 하나를 아꼈다"));
				LogA("[mlt] 🧭     ⚠️ ② **과거 흐름이 이미 크면** 사본의 순 가치가 작다(공짜로 아는 것이다)\n");
				LogA("[mlt] 🧭        미래 %.1f%% − 과거 %.1f%% = **%.1f%%** ⇒ %s\n", fF, fP, net,
					(fP > fF * 0.5) ? "★ **절반 이상이 이미 공짜다**" : "★ 미래를 아는 것이 실제로 보탠다");
				LogA("[mlt] 🧭     ⓘ ③ 견줄 자리 — 218 의 행동(`dYaw` 9) 여지 **27.4%%** · 깊이 **10.4%%**\n");
			}
		}
		_ampOv = -1.0f; _dtOv = -1.0f;
		LogA("[mlt] 🧭 ══════════════════════════════════════════════\n");
		_aSweep = false; _a4 = false;
	}

	// ══════════════════════════════════════════════════════════════════
	// ⚖️✂️ 회차 238 — 🆕 **「버릴 기준을 세계가 만든다」**(학습 0 · 237 심사의 처방)
	// ══════════════════════════════════════════════════════════════════
	//   ⚙️ 👤 사람의 지적: *"지금 MLT 는 **유리군**이다(손실이 예측 오차뿐). 자매 문서 실측에서
	//     유리군 단독은 전 항목 **0/10** — 확장 잉여 없이는 아무것도 못 한다. 확장군을 만드는 건
	//     「유지 비용 있는 몸 + 효용 기울기」 하나뿐이고 그것을 **세계 쪽에서** 만들어
	//     무작위 0/10 → **6/10** 으로 실증했다. ⇒ 호/불호 채널은 **입장권**이다."*
	//   ⚠️⚠️ **학습을 먼저 안 돌린다**(규율 12·49) — 세계를 고치는 회차이므로 **여지를 학습 0** 으로 먼저.
	//   ⚠️⚠️⚠️ **가장 위험한 자리**(237 심사 ④): 행동이 좁아지면 CE 가 **그냥** 내려간다
	//     ⇒ ★ 그래서 **목표선**(`H(다음|지금)`)을 같이 찍는다 — ***그것이 「쉬워진 양」이다.***
	static void _RunPrune()
	{
		_SetDir(true, _dirThr);
		_aSweep = true; _a3 = true;               // ★ 218 의 캡션 판을 재사용한다(자를 안 만든다)
		_ptIntent = true;                          // ⚠️ 세계를 일부러 바꾼다(방벽 ② 의 거짓 경고 방지)
		LogA("[mlt] ⚖️ ══════════════════════════════════════════════\n");
		LogA("[mlt] ⚖️ **회차 238 · 「버릴 기준을 세계가 만든다」**(학습 0 · 새 캔버스)\n");
		LogA("[mlt] ⚖️   ⚙️ 👤 *\"MLT 는 유리군이다 — 손실이 예측 오차뿐\"* ⇒ 자매 문서에서 유리군 단독은 **0/10**\n");
		LogA("[mlt] ⚖️      ⇒ ★ 확장군을 만드는 건 「**유지 비용 있는 몸 + 효용 기울기**」 하나뿐이다(2.3)\n");
		LogA("[mlt] ⚖️   ⭐ 237 심사: 에너지 채널이 **이미 있다**(조건 넷 만족 · 기본 꺼짐)\n");
		LogA("[mlt] ⚖️      ⛔ 그런데 지금 형태는 **감쇠**다(선택은 그대로 · 결과만 둔해진다)\n");
		LogA("[mlt] ⚖️      ⇒ ✂️ **가지치기 = 축별 비용**(병진 1.00 ↔ 회전 0.30) ⇒ 비싼 축이 먼저 **잘린다**\n");
		LogA("[mlt] ⚖️        ⚠️ 정책이 아니라 **법칙**이다 — *\"병진이 비싸다\"* 는 물리이고\n");
		LogA("[mlt] ⚖️          *\"배고프면 저 물체로 가라\"* 를 적으면 그것이 **정책 주입**이다\n");
		LogA("[mlt] ⚖️   🔬 기제 가설(⚠️ **근거가 아니다** — 규율 18): 236 이 *\"통로는 **자리의 수**\"* 를 냈다\n");
		LogA("[mlt] ⚖️      ⇒ 가지치기가 켜지면 카메라가 제자리에서 돈다 ⇒ **바뀌는 물체가 줄어든다**\n");
		LogA("[mlt] ⚖️      ⇒ ⭐ ***자리 수를 세계가 줄인다*** ⇒ 손으로 좁힌 211 과의 **대조**가 표제다\n");
		LogA("[mlt] ⚖️   ⚠️⚠️ **표제는 「Î」가 아니라 「목표선과 함께 읽은 Î」다** — 행동이 좁아지면\n");
		LogA("[mlt] ⚖️      CE 가 그냥 내려간다 ⇒ ★ 그것을 「좋아졌다」로 적으면 **세계를 쉽게 만든 것**이다\n");
		// ⭐⭐ 239 — **예산 스윕**(238 이 「닫힘이 좁힘을 제한한다」를 표 안에 냈다)
		//   ⚠️ 격자는 **손계산**이다(규율 21·83): `E[병진] = 1.10` · `E[회전] = 0.15`
		//     1.25 = 전부 산다 · 0.60 = 병진 하나만 · 0.30 = **회전만**(제자리 회전)
		//   ⚠️⚠️ 0.15 아래로 안 내린다 — 그것은 좁힘이 아니라 **정지 세계**다(규율 88).
		// ⭐⭐ 회차 242 — **감쇠 세기 스윕**(241 이 0.35 에서 활용률 2.54배를 냈는데 **격자의 끝**이다)
		//   ⚠️ 손계산: `sc` 는 **속도 배율**이다 ⇒ 1.0 = 감쇠 없음 · 0.05 = 거의 정지
		//     ★ 0.05 는 **정지 세계에 가깝다** ⇒ 규율 88 의 그 자리이므로 **음성 대조로** 둔다.
		//   ⚠️⚠️ 가지치기 팔(239)은 **뺐다** — 240·241 이 그 축을 답했고(감쇠가 이긴다)
		//     팔을 늘리면 판이 길어진다. ★ 지금 물음은 **감쇠의 봉우리**다.
		static const char* mn[5] = {
			"㈀ 지금(끔)         ", "㈁ 감쇠 0.65        ",
			"㈂ 감쇠 0.35(241)   ", "㈃ 감쇠 0.15        ", "㈄ 감쇠 0.05(음성)  " };
		static const float bud[5] = { -1.0f, -1.0f, -1.0f, -1.0f, -1.0f };
		// ⚠️ 이름을 `slwOf` 로 둔다 — 아래 루프 안에 `slw`(둔화 발동률)가 이미 있다
		static const float slwOf[5] = { -1.0f, 0.65f, 0.35f, 0.15f, 0.05f };
		LogA("[mlt] ⚖️   ── 📊 **궤도**(몸통이 도는 세계) ──\n");
		LogA("[mlt] ⚖️     모드                  목표선H  캡션자리1  캡션천장   바뀌는물체수  ⭐이어짐  둔화/에피\n");
		double base0 = 0.0, cap0 = 0.0, chg0 = 0.0;
		double chgOf[5] = { 0,0,0,0,0 }, basOf[5] = { 0,0,0,0,0 }, capOf[5] = { 0,0,0,0,0 }, cutOf[5] = { 0,0,0,0,0 };
		double runOf[5] = { 0,0,0,0,0 };
		// ⭐⭐ 244 — 캡션 심볼 열의 자 셋
		double capHOf[5] = { 0,0,0,0,0 }, capRepOf[5] = { 0,0,0,0,0 }, capOnOf[5] = { 0,0,0,0,0 };
		// ⭐⭐⭐ 254 — `H(도형)` · `H(슬롯)` · `H(도형|슬롯)`
		double idHOf[5] = { 0,0,0,0,0 }, idSOf[5] = { 0,0,0,0,0 }, idCOf[5] = { 0,0,0,0,0 };
		for (uint32 m = 0; m < 5u; ++m)
		{
			_enOn = (m >= 1u);
			_prOn = false;                 // ⭐ 242 — 가지치기는 뺐다(240·241 이 그 축을 답했다)
			_prBud = bud[m];
			_slowOv = slwOf[m];
			_runSum = 0.0; _runN = 0u;
			// ⭐⭐ 244 — 캡션 심볼 열의 자 셋을 모드마다 **비운다**(안 비우면 앞 모드가 섞인다)
			for (uint32 s = 0; s <= (uint32)kShapes; ++s) _capHist[s] = 0u;
			_capTot = 0u; _capRep = 0u; _capPairN = 0u; _capPrev = -2;
			// ⭐ 254 — 결합 히스토그램도 모드마다 비운다(감쇠가 보임을 바꾸므로 모드별 값이 맞다)
			for (uint32 i = 0; i < (uint32)kShapes; ++i)
				for (uint32 s = 0; s <= kIdSlots; ++s) _idJoint[i][s] = 0u;
			_idTot = 0u;
			_ampOv = kTrAmp; _dtOv = kTrDt;       // ⭐ 220 — 몸통의 자리
			_DepQuartiles(3u, MLTWorldCfg::kAutoMany, true, 2, true);   // ⭐ 231 의 고운 눈금
			_FillA(2);
			double base = 0.0, dm = 0.0, per = 0.0; uint32 used = 0u;
			_CStat(0u, base, dm, 0.0, used, per);
			double r[7]; for (uint32 a = 1u; a < 7u; ++a)
			{ double hc = 0.0, rr = 0.0, p2 = 0.0; uint32 u2 = 0u; _CStat(a, hc, rr, base, u2, p2); r[a] = rr; }
			const double d = (base > 1.0e-9) ? 100.0 / base : 0.0;
			const double capF = (r[3] - r[5]) * d;        // 캡션 자리 1(음성2 를 뺀다)
			const double capA = (r[4] - r[5]) * d;        // 캡션 천장
			const double chg  = (_chgN == 0u) ? 0.0 : _chgSum / (double)_chgN;
			const double slw  = (_epiN == 0u) ? 0.0 : _slowSum / (double)_epiN;
			const double cut  = (_epiN == 0u) ? 0.0 : _cutSum  / (double)_epiN;
			const double run = (_runN == 0u) ? 0.0 : _runSum / (double)_runN;   // ⭐ 242 — 이어짐
			// ⭐⭐ 244 — 캡션 심볼 열의 자 셋(㉠ 엔트로피 · ㉡ 반복률 · ㉢ 있음 비율)
			//   ⚠️ 엔트로피는 **「없음」을 뺀 조건부**다 — 「없음」은 이름이 아니라 **부재**이고
			//     그 비율은 ㉢ 이 따로 잰다(한 자에 두 가지를 섞으면 봉우리를 못 읽는다).
			double capH = 0.0; uint32 capOn = 0u;
			for (uint32 s = 0; s < (uint32)kShapes; ++s) capOn += _capHist[s];
			if (capOn > 0u)
				for (uint32 s = 0; s < (uint32)kShapes; ++s)
					if (_capHist[s] > 0u)
					{
						const double p = (double)_capHist[s] / (double)capOn;
						capH += -p * (double)Log((float)p);
					}
			const double capRep = (_capPairN == 0u) ? 0.0 : (double)_capRep / (double)_capPairN;
			const double capOnF = (_capTot == 0u) ? 0.0 : (double)capOn / (double)_capTot;
			if (m == 0u) { base0 = base; cap0 = capA; chg0 = chg; }
			chgOf[m] = chg; basOf[m] = base; capOf[m] = capA; cutOf[m] = cut; runOf[m] = run;
			capHOf[m] = capH; capRepOf[m] = capRep; capOnOf[m] = capOnF;
			// ⭐⭐⭐ 회차 254 — `H(도형)` · `H(슬롯)` · `H(도형|슬롯)` (규율 12 의 「여지」)
			{
				double hId = 0.0, hSl = 0.0, hJo = 0.0;
				if (_idTot > 0u)
				{
					const double N = (double)_idTot;
					uint32 mi[MLTWorldCfg::kShapes] = { 0u };
					uint32 ms[kIdSlots + 1u] = { 0u };
					for (uint32 i = 0; i < (uint32)MLTWorldCfg::kShapes; ++i)
						for (uint32 s = 0; s <= kIdSlots; ++s)
						{
							const uint32 c = _idJoint[i][s];
							if (c == 0u) continue;
							mi[i] += c; ms[s] += c;
							const double p = (double)c / N;
							hJo += -p * (double)Log((float)p);
						}
					for (uint32 i = 0; i < (uint32)MLTWorldCfg::kShapes; ++i)
						if (mi[i] > 0u)
						{ const double p = (double)mi[i] / N; hId += -p * (double)Log((float)p); }
					for (uint32 s = 0; s <= kIdSlots; ++s)
						if (ms[s] > 0u)
						{ const double p = (double)ms[s] / N; hSl += -p * (double)Log((float)p); }
				}
				idHOf[m] = hId; idSOf[m] = hSl; idCOf[m] = hJo - hSl;   // H(도형|슬롯)
			}
			LogA("[mlt] ⚖️     %s  %6.4f  %7.1f%%  %7.1f%%  %11.3f  %8.3f  %8.1f\n",
				mn[m], base, capF, capA, chg, run, slw);
		}
		// ⭐ 242 — **㈀ 대비 배율**로 다시 읽는다. ★ 절대값이 아니라 배율이 손잡이의 깊이다
		LogA("[mlt] ⚖️     ── ⭐ **㈀ 대비 배율** ──\n");
		LogA("[mlt] ⚖️        모드                자리수배  목표선배  ⭐이어짐배  천장차(%%p)\n");
		for (uint32 m = 1u; m < 5u; ++m)
			LogA("[mlt] ⚖️        %s  %7.2f  %8.2f  %9.2f  %8.1f\n", mn[m],
				(chg0 > 1.0e-9) ? chgOf[m] / chg0 : 0.0,
				(base0 > 1.0e-9) ? basOf[m] / base0 : 0.0,
				(runOf[0] > 1.0e-9) ? runOf[m] / runOf[0] : 0.0,
				capOf[m] - cap0);
		// ══════════════════════════════════════════════════════════════
		// ⭐⭐⭐ **회차 254 — 「슬롯 번호」가 정체성을 얼마나 잃나**(규율 12 의 「여지」)
		// ══════════════════════════════════════════════════════════════
		{
			LogA("[mlt] ⚖️   ── ⭐⭐⭐ **회차 254 — 낱말을 identity 로 바꿔서 얻을 여지** ──\n");
			LogA("[mlt] ⚖️     ⚙️ 254 심사: 학습 하네스(`mltl1t0`)의 캡션은 **「슬롯 번호」**다(`nm = 1 + j`)\n");
			LogA("[mlt] ⚖️        ⇒ *\"보이는 물체 중 몇 번째\"* ⇒ ⚠️ **매 시각 다시 채워져 지시대상이 바뀐다**(밀림 55.2%% · 회차 55)\n");
			LogA("[mlt] ⚖️     ⭐ 이 하네스는 **도형 index** 를 쓴다 ⇒ 📌 **D46 이 확정됐다**(두 하네스가 다른 낱말을 썼다)\n");
			LogA("[mlt] ⚖️     ⭐⭐ **규율 12** — 처방(낱말을 identity 로) 전에 **여지**를 학습 0 으로 잰다\n");
			LogA("[mlt] ⚖️        ★ 손계산 천장: `H(도형)` ≤ `ln 14` = **2.639** · 슬롯이 정체성을 다 담으면 **0**\n");
			LogA("[mlt] ⚖️     모드      H(도형)   H(슬롯)  ⭐⭐ **H(도형|슬롯)**   비(여지/천장)\n");
			for (uint32 m = 0; m < 5u; ++m)
				LogA("[mlt] ⚖️     %s  %7.4f  %7.4f      **%7.4f**        **%5.1f%%**\n", mn[m],
					idHOf[m], idSOf[m], idCOf[m],
					100.0 * ((idHOf[m] > 1.0e-9) ? idCOf[m] / idHOf[m] : 0.0));
			const double r0 = (idHOf[0] > 1.0e-9) ? idCOf[0] / idHOf[0] : 0.0;
			LogA("[mlt] ⚖️     ⭐⭐ 🚪 **표제** — ㈀(끔)의 여지 비 **%.1f%%** ≥ 10%% → %s\n", 100.0 * r0,
				(r0 >= 0.10)
					? "✅ ⭐ **여지가 있다** — ★ 낱말을 identity 로 바꾸면 그만큼 얻는다"
					: "⛔ **여지가 없다** — ★ 슬롯 번호가 정체성을 거의 다 담는다 ⇒ **처방을 안 돌린다**(규율 12)");
			LogA("[mlt] ⚖️        ⓘ 문턱 10%% 는 244 가 세계 자 셋을 기각할 때 쓴 그 문턱이다\n");
			LogA("[mlt] ⚖️        ⚠️ `H(슬롯)` 이 `H(도형)` 보다 **크면** 「슬롯 없음」 칸이 무게를 먹은 것이다(8칸 상한)\n");
		}
		{
			// ⭐⭐ 242 관문 ① — **기제 가설**: 241 은 *"느리면 한 물체가 이어진다"* 로 적었고
			//   239 는 *"감쇠가 바뀌는 물체를 1.55배 늘린다"* 를 냈다 ⇒ ★ 이 표가 그것을 가른다.
			LogA("[mlt] ⚖️     ⭐ 🚪 ① **기제 — 감쇠가 「이어짐」을 늘리나**(241 의 가설)\n");
			LogA("[mlt] ⚖️        ㈂(241 의 자리) 이어짐 **%.3f** ↔ ㈀ **%.3f** = **%.2f배** → %s\n",
				runOf[2], runOf[0], (runOf[0] > 1.0e-9) ? runOf[2] / runOf[0] : 0.0,
				(runOf[0] > 1.0e-9 && runOf[2] / runOf[0] > 1.05)
					? "✅ ⭐ **늘었다** — 241 의 가설이 이 자에서 산다"
					: "⛔ **안 늘었다** ⇒ ★ 241 의 이득은 「이어짐」이 아니다(다른 기제다)");
			// ⭐⭐⭐ 회차 244 관문 — **0.35 에서 봉우리인 세계 통계가 있나**
			//   ⚙️ 근거: `d̄` 가 끔 0.0463 → 0.35 **0.0995** → 0.15 0.0830 으로 **0.35 에서 봉우리**다
			//     ⇒ ★ 기제도 같은 모양이어야 한다. 242 가 잰 넷은 **전부 단조**라 전부 후보가 아니었다.
			//   ⚠️⚠️ 문턱은 **`d̄` 의 봉우리 깊이에서 역산**한다(242 가 손으로 정했다가 값을 치렀다):
			//     ⓐ 끔 → 0.35 로 **잡음(≈0.01배)보다 크게** 변한다
			//     ⓑ 0.35 → 0.15 에서 **반대로 ≥ 10%** 되돌아간다
			//        ★ 10% 의 근거 = `d̄` 가 그 구간에서 **16.6%** 되돌아갔다 ⇒ 그보다 훨씬 작으면 설명 못 한다.
			{
				static const char* cn[3] = { "㉠ 캡션 엔트로피", "㉡ 캡션 반복률  ", "㉢ 캡션 있음비율" };
				const double* cv[3] = { capHOf, capRepOf, capOnOf };
				LogA("[mlt] ⚖️     ⭐⭐ 🚪 **회차 244 — 캡션 심볼 열**(243: 값은 0.966배 불변 · **심볼만** 0.834배)\n");
				LogA("[mlt] ⚖️        자              끔      0.65    0.35    0.15    0.05  │ 끔→0.35  0.35→0.15\n");
				uint32 nCand = 0u;
				for (uint32 c = 0; c < 3u; ++c)
				{
					const double* v = cv[c];
					const double rA = (v[0] > 1.0e-9) ? v[2] / v[0] : 0.0;    // ⓐ 끔 → 0.35
					const double rB = (v[2] > 1.0e-9) ? v[3] / v[2] : 0.0;    // ⓑ 0.35 → 0.15
					// ⭐ 봉우리 = ⓐ 로 간 방향과 ⓑ 로 가는 방향이 **반대**이고 ⓑ 가 10% 이상이다
					const bool upA  = (rA > 1.01);
					const bool dnA  = (rA < 0.99);
					const bool okA  = (upA || dnA);
					const bool okB  = (upA && rB <= 0.90) || (dnA && rB >= 1.10);
					const bool cand = okA && okB;
					if (cand) ++nCand;
					LogA("[mlt] ⚖️        %s %7.4f %7.4f %7.4f %7.4f %7.4f │ %7.2f배 %8.2f배  %s\n",
						cn[c], v[0], v[1], v[2], v[3], v[4], rA, rB,
						cand ? "⭐ **봉우리 — 후보다**"
						     : (okA ? "⛔ 단조(안 되돌아온다)" : "⛔ 안 변한다"));
				}
				LogA("[mlt] ⚖️        ⇒ 🚪 **표제** — 후보 **%u개** → %s\n", nCand,
					(nCand > 0u)
						? "⭐⭐ **세계 통계에 기제 후보가 있다** ⇒ 다음 회차가 그것을 학습으로 검증한다"
						: "⛔⛔ **없다** ⇒ ★ 기제는 **세계에 없고 모델 표현에 있다** ⇒ 세계 축을 닫는다");
				LogA("[mlt] ⚖️        ⚠️⚠️ **📌 D46** — 이 표는 **세계·캡션의 사실**까지다.\n");
				LogA("[mlt] ⚖️           ***학습 0 자로 「그래서 `d̄` 가 오른다」로 잇지 않는다***(243 이 그 값을 치렀다)\n");
			}
			// ⭐ 관문 ② — 봉우리가 가둬졌나(격자 안쪽이 최선이어야 한다)
			LogA("[mlt] ⚖️     ⭐ 🚪 ② **봉우리** — 목표선/자리수가 감쇠 세기에 **단조**인가\n");
			LogA("[mlt] ⚖️        자리수배 %.2f → %.2f → %.2f → %.2f (0.65 · 0.35 · 0.15 · 0.05)\n",
				(chg0 > 1.0e-9) ? chgOf[1] / chg0 : 0.0, (chg0 > 1.0e-9) ? chgOf[2] / chg0 : 0.0,
				(chg0 > 1.0e-9) ? chgOf[3] / chg0 : 0.0, (chg0 > 1.0e-9) ? chgOf[4] / chg0 : 0.0);
			LogA("[mlt] ⚖️        ⇒ ★ **단조면 학습 격자를 그 방향으로** 짠다 · 꺾이면 **거기가 봉우리**다\n");
			// ⚠️ 관문 ③ — 음성 대조(0.05)가 정지 세계인가
			LogA("[mlt] ⚖️     ⚠️ 🚪 ③ **음성 대조** — ㈄(0.05)의 자리수배 **%.2f** → %s\n",
				(chg0 > 1.0e-9) ? chgOf[4] / chg0 : 0.0,
				((chg0 > 1.0e-9) && (chgOf[4] / chg0 < 0.25))
					? "⚠️ **정지 세계에 가깝다** — 그 팔이 이기면 관문이 틀린 것이다(규율 88)"
					: "✅ 정지 세계는 아니다");
		}
		LogA("[mlt] ⚖️   ── 🚪 관문 ──\n");
		LogA("[mlt] ⚖️     ⭐ ① **배관** — ㈂ 의 「잘린축/에피」가 **0 이면 안 된다**(위 표 마지막 칸)\n");
		LogA("[mlt] ⚖️        ⚠️ 0 이면 `kPruneBudget`(1.25)을 손계산으로 다시 잡는다 — 147 이 그 자리에서 그랬다\n");
		LogA("[mlt] ⚖️     ⭐ ② **기제** — 「바뀌는 물체 수」가 ㈀ %.3f 에서 줄었나(줄면 자리 수가 좁아진 것)\n", chg0);
		LogA("[mlt] ⚖️     ⭐ ③ **쉬워진 양** — 목표선H 가 ㈀ %.4f 에서 얼마나 내려갔나\n", base0);
		LogA("[mlt] ⚖️        ⚠️⚠️ ***이것이 내려간 만큼은 「통로가 열린 것」이 아니다*** ⇒ 학습 회차는 `P3` 로 본다\n");
		LogA("[mlt] ⚖️     ⭐ ④ **여지** — 캡션천장이 ㈀ %.1f%% 에서 올랐나 내렸나(⚠️ 예측을 안 걸었다)\n", cap0);
		LogA("[mlt] ⚖️        ⇒ ★ 오르면 ⭐ **세계가 좁힌 것이 정보를 늘렸다**(가설 지지) ·\n");
		LogA("[mlt] ⚖️          내리면 ⛔ **좁힌 것이 정보를 깎았다**(236 의 어휘 축과 같은 모양)\n");
		_enOn = false; _prOn = false; _ampOv = -1.0f; _dtOv = -1.0f;
		LogA("[mlt] ⚖️ ══════════════════════════════════════════════\n");
		_aSweep = false; _a3 = false; _ptIntent = false;
	}

	// ══════════════════════════════════════════════════════════════════
	// ⚖️⚖️ 회차 265 — 🆕 **칸 15 의 세계 서명**: 「유지 비용 있는 몸」(`-mltbody`)
	// ══════════════════════════════════════════════════════════════════
	//   ⚙️ 264(설계 심사)가 정한 것: **이득을 외형 `kind` 에 건다**(0 먹이 · 1 독 · 2 중립) ·
	//     **반사**는 `_e` 가 낮을 때 먹이 쪽으로 `dYaw` 를 돌린다(가지치기보다 앞).
	//   ⚠️⚠️ **이 판은 성능을 안 읽는다** — 공용 규율 1: *세계를 바꾼 판에서는 세계의 서명을
	//     성능보다 먼저 읽는다.* ⇒ 표제는 **닫힘이 실제로 도는가**다.
	//   ⚠️ 그리고 ⭐⭐ **ML 규율 74**(자매 트랙이 닫히며 넘긴 것): 무작위 기준선도 **자리마다
	//     직접** 재야 한다 ⇒ ★ 그래서 **몸 꺼진 팔에서도 먹이 가중을 잰다**(`SetBodySig`).
	static void _RunBody()
	{
		_SetDir(true, _dirThr);
		_aSweep = true; _a3 = true;                // ★ 218 의 캡션 판을 재사용한다(자를 안 만든다)
		_ptIntent = true;                          // ⚠️ 세계를 일부러 바꾼다(방벽 ② 의 거짓 경고 방지)
		LogA("[mlt] ⚖️ ══════════════════════════════════════════════\n");
		LogA("[mlt] ⚖️ **회차 265 · 칸 15 — 「유지 비용 있는 몸」의 세계 서명**(학습 0)\n");
		LogA("[mlt] ⚖️   ⚙️ 264 가 찾은 것: `kEnergyGain` 이 **상수**여서 ***이 세계엔 좋은 것도 나쁜 것도 없었다***\n");
		LogA("[mlt] ⚖️      ⇒ ⭐ 이득을 **외형**(`kind`)에 건다 — 0 찬원 = 먹이(+) · 1 찬사각 = 독(−) · 2 중립\n");
		LogA("[mlt] ⚖️      ⚠️ **도형 번호에 안 건다** — `Addr(_seedNo, _epi, 0)` 이 외형을 정하므로\n");
		LogA("[mlt] ⚖️        ***번호는 에피소드마다 뜻이 바뀐다***(정체성이 아니라 에피소드-지역 주소다)\n");
		LogA("[mlt] ⚖️      ⭐⭐ 그 대가로 얻는 것: 모델은 **번호 암기로 먹이를 못 찾고 외형으로 배워야** 한다\n");
		LogA("[mlt] ⚖️   ⚠️⚠️ **이 판은 성능을 안 읽는다**(공용 규율 1) — 표제는 **닫힘이 도는가**다\n");
		LogA("[mlt] ⚖️      ★ 그리고 ⭐⭐ **ML 규율 74** — 기준선(먹이 가중)을 **몸 꺼진 팔에서도** 직접 잰다\n");
		// ⭐ 팔 다섯 — 컨셉이 요구한 그 다섯 중 **세계 쪽 네 개 + 음성 하나**
		//   ⚠️ 「상수 채널」·「무작위 채널」은 **모델 입력**의 팔이라 학습 판의 몫이다(여기선 세계만 본다).
		static const char* mn[5] = {
			"㈀ 몸 끔(감쇠 0.35) ", "㈁ 이득만           ",
			"㈂ 반사만           ", "㈃ 둘 다(닫힘)      ", "㈄ 에너지도 끔(음성)" };
		static const bool  gOf[5] = { false, true,  false, true,  false };
		static const bool  rOf[5] = { false, false, true,  true,  false };
		static const bool  eOf[5] = { true,  true,  true,  true,  false };
		double chgOf[5] = { 0,0,0,0,0 }, basOf[5] = { 0,0,0,0,0 }, capOf[5] = { 0,0,0,0,0 };
		double biasOf[5] = { 0,0,0,0,0 }, pickOf[5] = { 0,0,0,0,0 };
		double fwOf[5] = { 0,0,0,0,0 }, fwLoOf[5] = { 0,0,0,0,0 };
		double pwOf[5] = { 0,0,0,0,0 }, slwOf2[5] = { 0,0,0,0,0 };
		LogA("[mlt] ⚖️   ── 📊 **궤도**(몸통이 도는 세계) ──\n");
		LogA("[mlt] ⚖️     모드                  목표선H  캡션천장  바뀌는물체수  둔화/에피  ⭐반사/에피  먹이가중  ⭐낮을때  독가중\n");
		for (uint32 m = 0; m < 5u; ++m)
		{
			_enOn = eOf[m];
			_prOn = false;
			_prBud = -1.0f;
			_slowOv = eOf[m] ? 0.35f : -1.0f;      // ⭐ 246 의 자리(감쇠 0.35)를 기준선으로 쓴다
			_bodyGain = gOf[m]; _bodyRefl = rOf[m];
			_bodySigOn = eOf[m];                   // ⭐ ML 규율 74 — 꺼진 팔에서도 기준선을 잰다
			_runSum = 0.0; _runN = 0u;
			for (uint32 s = 0; s <= (uint32)kShapes; ++s) _capHist[s] = 0u;
			_capTot = 0u; _capRep = 0u; _capPairN = 0u; _capPrev = -2;
			for (uint32 i = 0; i < (uint32)kShapes; ++i)
				for (uint32 s = 0; s <= kIdSlots; ++s) _idJoint[i][s] = 0u;
			_idTot = 0u;
			_ampOv = kTrAmp; _dtOv = kTrDt;        // ⭐ 220 — 몸통의 자리
			_DepQuartiles(3u, MLTWorldCfg::kAutoMany, true, 2, true);
			_FillA(2);
			double base = 0.0, dm = 0.0, per = 0.0; uint32 used = 0u;
			_CStat(0u, base, dm, 0.0, used, per);
			double r[7]; for (uint32 a = 1u; a < 7u; ++a)
			{ double hc = 0.0, rr = 0.0, p2 = 0.0; uint32 u2 = 0u; _CStat(a, hc, rr, base, u2, p2); r[a] = rr; }
			const double d = (base > 1.0e-9) ? 100.0 / base : 0.0;
			const double capA = (r[4] - r[5]) * d;
			chgOf[m]  = (_chgN == 0u) ? 0.0 : _chgSum / (double)_chgN;
			basOf[m]  = base; capOf[m] = capA;
			slwOf2[m] = (_epiN == 0u) ? 0.0 : _slowSum / (double)_epiN;
			biasOf[m] = (_epiN == 0u) ? 0.0 : _biasSum / (double)_epiN;
			pickOf[m] = (_epiN == 0u) ? 0.0 : _pickSum / (double)_epiN;   // ⭐ D71 — 분모
			fwOf[m]   = (_fwAllN  == 0u) ? 0.0 : _fwAllSum  / (double)_fwAllN;
			fwLoOf[m] = (_fwLowMN == 0u) ? 0.0 : _fwLowMSum / (double)_fwLowMN;
			pwOf[m]   = (_fwAllN  == 0u) ? 0.0 : _pwAllSum  / (double)_fwAllN;
			LogA("[mlt] ⚖️     %s  %6.4f  %7.1f%%  %11.3f  %8.1f  %10.1f  %8.4f  %8.4f  %6.4f\n",
				mn[m], base, capA, chgOf[m], slwOf2[m], biasOf[m], fwOf[m], fwLoOf[m], pwOf[m]);
		}
		LogA("[mlt] ⚖️   ── 🚪 관문 ──\n");
		// ⭐ ① 배관 — 반사가 실제로 돌았나
		// ⚠️ 📌 **D71** — 「반사/에피」는 **호출 수에 딸리는 수**다(하네스가 다르면 못 견준다)
		//   ⛔ 265 가 이 수(6.3)를 다른 하네스와 견줘 문턱을 뽑았고 그것이 무효였다 ⇒ ML 규율 74.
		//   ⇒ ★ **반사 ÷ 호출**을 같이 찍는다 · ⚠️ **문턱은 여기서 안 정한다**(그 세계에서 뽑는다).
		LogA("[mlt] ⚖️     ⭐ ① **배관** — ㈃(둘 다) 반사 **%.1f**/에피 · 호출 **%.1f**/에피 · ⭐ **반사÷호출 %.3f** → %s\n",
			biasOf[3], pickOf[3], (pickOf[3] > 1.0e-9) ? biasOf[3] / pickOf[3] : 0.0,
			(biasOf[3] > 0.0)
				? "✅ **돌았다** ⚠️ 문턱은 이 세계에서 뽑는다(D71)"
				: "⛔⛔ **0 이다** — ★ `kEnergyLow`(0.35) 아래로 안 내려가거나 먹이가 안 보인다 ⇒ 배관을 고친다");
		// ⭐⭐⭐ ② 닫힘 — 「_e 가 낮을 때 먹이 가중이 더 큰가」 · ⚠️ 반사의 **부호**도 이 자가 잡는다
		//   ⛔⛔ **회차 265 가 이 관문의 짝을 틀렸다** — 처음엔 ㈃ ↔ ㈀ 으로 읽었는데
		//     ***㈀ 은 손잡이가 둘 다른 팔***이다(이득도 반사도 없다) ⇒ 공용 규율 6(안 흔든 손잡이가
		//     교란이 된다)에 걸린다. ★ 실측이 그것을 보여 줬다: **반사가 없는 ㈁(이득만)도 비가
		//     0.830 으로 내려간다** ⇒ 🧾 ***그 하락은 반사가 아니라 이득 규칙의 「선택 효과」다***
		//     (먹이가 보이면 `_e` 가 오르므로 *"`_e` 가 낮다"* = *"최근에 먹이를 못 봤다"*).
		//   ⇒ ★ 그래서 **손잡이 하나만 다른 짝**으로 읽는다: ㈁ → ㈃(이득 고정 · 반사만 켠다) ·
		//     ㈀ → ㈂(이득 없음 고정 · 반사만 켠다). ⚠️ 두 짝이 같은 방향이어야 부호가 산다.
		//   ⚠️⚠️ **ML 규율 77 대로 「고치면 무엇이 닫히나」를 먼저 적는다**: 이 수정은 ②의 판정을
		//     ⛔(부호가 뒤집혔다) → 🔶(부호는 맞고 크기가 작다) 로 **바꾼다**. 그것을 알고 고친다.
		{
			const double qG = (fwOf[1] > 1.0e-9) ? fwLoOf[1] / fwOf[1] : 0.0;   // ㈁ 이득만
			const double qB = (fwOf[3] > 1.0e-9) ? fwLoOf[3] / fwOf[3] : 0.0;   // ㈃ 둘 다
			const double qN = (fwOf[0] > 1.0e-9) ? fwLoOf[0] / fwOf[0] : 0.0;   // ㈀ 아무것도
			const double qR = (fwOf[2] > 1.0e-9) ? fwLoOf[2] / fwOf[2] : 0.0;   // ㈂ 반사만
			LogA("[mlt] ⚖️     ⭐⭐⭐ ② **닫힘**(조건 넷의 넷째) — ⚠️ **짝은 손잡이 하나만** 다르다(규율 6)\n");
			LogA("[mlt] ⚖️        ⚙️ 뜻: `_e` 가 낮을 때 **먹이가 더 크게·가운데 보이나** = 반사가 실제로 데려오나\n");
			LogA("[mlt] ⚖️        짝 ①(이득 고정)  ㈁ %.4f → ㈃ %.4f = **%+.1f%%**\n",
				qG, qB, 100.0 * ((qG > 1.0e-9) ? qB / qG - 1.0 : 0.0));
			LogA("[mlt] ⚖️        짝 ②(이득 없음)  ㈀ %.4f → ㈂ %.4f = **%+.1f%%**\n",
				qN, qR, 100.0 * ((qN > 1.0e-9) ? qR / qN - 1.0 : 0.0));
			const double e1 = (qG > 1.0e-9) ? qB / qG - 1.0 : 0.0;
			const double e2 = (qN > 1.0e-9) ? qR / qN - 1.0 : 0.0;
			LogA("[mlt] ⚖️        ⇒ 🚪 **표제** — %s\n",
				(e1 > 0.0 && e2 > 0.0)
					? "🔶 ⭐ **부호가 맞다 — 두 짝이 같은 방향**이다(반사가 먹이를 데려온다) ⚠️ 크기는 작다"
					: ((e1 < 0.0 && e2 < 0.0)
						? "⛔⛔ **부호가 뒤집혔다 — 두 짝 모두** ⇒ ★ `dYaw` 부호를 뒤집는다"
						: "⛔ **두 짝이 갈린다** ⇒ ★ 판정하지 않는다(교란이 남아 있다)"));
			LogA("[mlt] ⚖️        ⚠️ 크기 문턱은 **안 정했다** — 이 판은 서명이고 크기는 학습 판이 판정한다\n");
		}
		// ⭐ ③ 부호가 실제로 갈렸나 — 먹이 ↔ 독
		LogA("[mlt] ⚖️     ⭐ ③ **부호** — ㈃ 먹이 **%.4f** ↔ 독 **%.4f** (차 %.4f)\n",
			fwOf[3], pwOf[3], fwOf[3] - pwOf[3]);
		LogA("[mlt] ⚖️        ⚙️ 이득 배율은 `1 + %.2f·(먹이 − 독)` 이므로 이 차가 **부호의 크기**다\n",
			(double)MLTWorldCfg::kBodyAmp);
		LogA("[mlt] ⚖️        ⚠️ 차가 0 에 가까우면 **평균 예산이 안 바뀐 것**이고(설계 의도) 부호는 **분산**에 있다\n");
		// ⚠️ ④ 세계를 조용하게 만들었나 — ⭐ 중단 갈래의 그 자
		{
			const double rc = (chgOf[0] > 1.0e-9) ? chgOf[3] / chgOf[0] : 0.0;
			LogA("[mlt] ⚖️     ⚠️⚠️ ④ **변화 표적 수/문맥** — ㈃ **%.3f** ↔ ㈀ **%.3f** = **%.2f배** → %s\n",
				chgOf[3], chgOf[0], rc,
				(rc < 0.90)
					? "⛔⛔ **세계를 조용하게 만들었다** ⇒ ★ CE 가 좋아져도 **성과가 아니다**(중단 갈래)"
					: "✅ 안 조용해졌다 ⇒ 성능을 읽을 자격이 생긴다");
			LogA("[mlt] ⚖️        ⚙️ 145·146 이 **14.0/문맥**이었다 — 컨셉 선행조건 ⭐2 가 요구한 그 자다\n");
		}
		// ⭐ ⑤ 쉬워진 양과 여지
		LogA("[mlt] ⚖️     ⭐ ⑤ **쉬워진 양** — 목표선H ㈀ %.4f → ㈃ %.4f (%.2f배)\n",
			basOf[0], basOf[3], (basOf[0] > 1.0e-9) ? basOf[3] / basOf[0] : 0.0);
		LogA("[mlt] ⚖️        ⚠️⚠️ ***내려간 만큼은 「통로가 열린 것」이 아니다*** ⇒ 학습 회차는 `P3` 로 본다\n");
		LogA("[mlt] ⚖️     ⭐ ⑥ **여지** — 캡션천장 ㈀ %.1f%% → ㈃ %.1f%% (차 %.1f%%p)\n",
			capOf[0], capOf[3], capOf[3] - capOf[0]);
		LogA("[mlt] ⚖️     ⚠️ ⑦ **음성 대조** — ㈄(에너지도 끔)이 어느 자에서도 1등이면 관문이 틀린 것이다(규율 88)\n");
		_enOn = false; _prOn = false; _ampOv = -1.0f; _dtOv = -1.0f;
		_bodyGain = false; _bodyRefl = false; _bodySigOn = false;
		LogA("[mlt] ⚖️ ══════════════════════════════════════════════\n");
		_aSweep = false; _a3 = false; _ptIntent = false;
	}

	// ══════════════════════════════════════════════════════════════════
	// ⭐ 회차 230 — 📌 **D42 를 갚는다**(깊이 문턱이 다른 세계에서 뽑혔다)
	// ══════════════════════════════════════════════════════════════════
	//   ★ **226 의 판(`_a4`)을 문턱 둘로 돌린다** — 그 판에는 깊이 팔(㈄ 40칸)과
	//     **그 음성 짝**(㈆ 40칸)이 짝지어 있다(규율 14). ⚠️ 218 의 `_a3` 에는 짝이 없다.
	//   ⭐ 그리고 **깊이와 무관한 칸**(순 사본 천장 = 미래흐름 − 과거흐름)이 두 모드에서
	//     **같아야 한다** ⇒ ***그것이 이 회차의 배관 확인***이다(다르면 문턱 말고 다른 것을 바꾼 것).
	static void _RunDep()
	{
		_SetDir(true, _dirThr);
		_aSweep = true; _a4 = true;
		LogA("[mlt] 📏 ══════════════════════════════════════════════\n");
		LogA("[mlt] 📏 **회차 230 · 📌 D42 를 갚는다**(학습 0 · ~5분)\n");
		LogA("[mlt] 📏   ⛔ 229 가 잡았다: `_DepQuartiles` 는 **`_Pt(3)`(dt 0.25 · amp 1.0)** 로 문턱을 뽑는데\n");
		LogA("[mlt] 📏      `_FillA` 는 **`_PtTrain()`(dt 1.00 · amp 5.0)** 이고 `SetWorld2` 도 부른다\n");
		LogA("[mlt] 📏      ⇒ ⚠️⚠️ ***깊이 눈금이 「그 판이 도는 세계」가 아닌 곳에서 정해졌다***\n");
		LogA("[mlt] 📏      ⇒ ★ **220 이 고친 그 사고**(결론 셋을 뒤집었다)가 **한 자리에 남아 있었다**\n");
		LogA("[mlt] 📏   ⚠️ **옛 자는 안 고친다**(규율 58) — 기본 인자가 옛 동작이라 218·226 은 그대로 재현된다\n");
		static const int   ws[2]  = { 2, 3 };
		static const char* wn2[2] = { "궤도", "가속" };
		static const char* mn[2]  = { "㈀ 옛(_Pt3·세계무시)", "㈁ 새(_PtTrain·세계맞춤)" };
		for (uint32 iw = 0; iw < 2u; ++iw)
		{
			double depOf[2] = { 0.0, 0.0 };
			double netOf[2] = { 0.0, 0.0 };
			LogA("[mlt] 📏   ── 📊 **%s** ──\n", wn2[iw]);
			LogA("[mlt] 📏     눈금                     문턱(px)              깊이 순여지  순사본천장(배관)\n");
			for (uint32 m = 0; m < 2u; ++m)
			{
				_ampOv = kTrAmp; _dtOv = kTrDt;      // ⭐ 220 — **몸통의 자리**
				if (m == 0u) _DepQuartiles(3u, MLTWorldCfg::kAutoMany);                       // 옛
				else         _DepQuartiles(3u, MLTWorldCfg::kAutoMany, true, ws[iw]);         // ⭐ 새
				_FillA(ws[iw]);
				double base = 0.0, dm = 0.0, per = 0.0; uint32 used = 0u;
				_CStat(0u, base, dm, 0.0, used, per);
				double r[8]; for (uint32 a = 1u; a < 8u; ++a)
				{ double hc = 0.0, rr = 0.0, p2 = 0.0; uint32 u2 = 0u; _CStat(a, hc, rr, base, u2, p2); r[a] = rr; }
				const double d = (base > 1.0e-9) ? 100.0 / base : 0.0;
				depOf[m] = (r[4] - r[6]) * d;                 // 깊이 순 여지(음성 짝을 뺀 값)
				netOf[m] = (r[1] - r[2]) * d;                 // ⭐ 순 사본 천장 — **깊이와 무관**
				LogA("[mlt] 📏     %s  %.2f/%.2f/%.2f  %8.1f%%  %11.1f%%\n",
					mn[m], (double)_depThr[0], (double)_depThr[1], (double)_depThr[2],
					depOf[m], netOf[m]);
			}
			const double dd = depOf[1] - depOf[0];
			const double nd = netOf[1] - netOf[0];
			LogA("[mlt] 📏     ⭐ ① **표제 — 깊이 순여지가 %.1f%%p 달라진다**(㈀ %.1f%% → ㈁ %.1f%%)\n",
				dd, depOf[0], depOf[1]);
			LogA("[mlt] 📏        판정 → %s\n",
				(Abs((float)nd) > 0.5f)
					? "⛔⛔ **배관 확인이 깨졌다** — 순 사본 천장이 달라졌다 ⇒ ★ 표제를 읽지 마라"
					: ((Abs((float)dd) < 1.0)
						? "🔶 **차가 1%p 미만** ⇒ ★ D42 는 **「무해」로 닫는다**(부채는 갚였다)"
						: ((dd > 0.0)
							? "✅ ⭐ **진짜 자리가 더 크다** — 옛 눈금이 여지를 **과소평가**하고 있었다"
							: "⚠️ ⭐ **진짜 자리가 더 작다** — 예측 ㉡ 이 뒤집혔다(원인을 적어라)")));
			LogA("[mlt] 📏     ⭐ ② **배관 확인** — 순 사본 천장 차 **%.2f%%p**(문턱 0.5%%p) → %s\n",
				nd, (Abs((float)nd) <= 0.5f) ? "✅ 같다(문턱만 바뀌었다)" : "⛔ 다르다");
			if (iw == 0u)
				LogA("[mlt] 📏     ⓘ ③ 견줄 자리 — 218 의 「깊이」 = **10.4%%** · 226 의 깊이(타자) 칸\n");
		}
		_ampOv = -1.0f; _dtOv = -1.0f;
		LogA("[mlt] 📏 ══════════════════════════════════════════════\n");
		_aSweep = false; _a4 = false;
	}

	// ══════════════════════════════════════════════════════════════════
	// ⭐ 회차 231 — 📌 **D43 을 갚아 230 의 「같다」를 시험한다**
	// ══════════════════════════════════════════════════════════════════
	//   ★ 순서가 있다: ① **문턱만** 뽑아 찍는다(스캔은 싸다 — 2씨앗 × 64문맥)
	//     ⇒ 관문 ①(가를 수 있나)은 **`_FillA` 없이** 답이 나온다
	//     ② 그 다음 **고운 눈금으로만** `_FillA` 를 돌려 순 여지를 견준다(거친 쪽은 230 이 이미 쟀다)
	static void _RunDep2()
	{
		_SetDir(true, _dirThr);
		_aSweep = true; _a4 = true;
		LogA("[mlt] 📐 ══════════════════════════════════════════════\n");
		LogA("[mlt] 📐 **회차 231 · 📌 D43 을 갚아 230 의 「같다」를 시험한다**(학습 0)\n");
		LogA("[mlt] 📐   ⛔ 230: 두 문턱이 **바이트 단위로 같았다**(1.00/2.00/2.50)\n");
		LogA("[mlt] 📐      ⚠️⚠️ 그런데 **bin 폭이 0.5px** 이고 문턱은 1.0~2.5px 다\n");
		LogA("[mlt] 📐      ⇒ ★★ 1024칸 중 **여섯 칸**만 쓴다 ⇒ ***「같다」와 「못 가른다」가 구별이 안 된다***\n");
		LogA("[mlt] 📐      ⇒ ⭐ **공용 규율 13-a** — 「같다」를 주장할 때는 **예산을 효과와 견주어라**\n");
		LogA("[mlt] 📐        (예산 0.5px ÷ 문턱 1.0~2.5px = **20~50%%** ⇒ ⚠️ 예산이 너무 크다)\n");
		LogA("[mlt] 📐   ⇒ 📐 처방: `fine` 2패스 — 1패스가 **옛 눈금 그대로** 돌아 관측 최대를 읽고\n");
		LogA("[mlt] 📐      2패스가 **그 범위에** 다시 깐다(⚠️ 손으로 안 박는다) ⇒ ★ 1패스가 곧 **배관 확인**이다\n");
		static const int   ws[2]  = { 2, 3 };
		static const char* wn2[2] = { "궤도", "가속" };
		LogA("[mlt] 📐   ── ① 📊 **문턱만**(가를 수 있나 — `_FillA` 없이) ──\n");
		LogA("[mlt] 📐     세계  눈금·세계설정            문턱(px)                  관측최대  표본  bin폭\n");
		float fineThr[2][2][3];
		for (uint32 iw = 0; iw < 2u; ++iw)
		{
			_ampOv = kTrAmp; _dtOv = kTrDt;      // ⭐ 220 — **몸통의 자리**
			// ㉠ 배관 확인 — **거친 눈금 · 옛 세계설정** = 230 의 ㈀ 가 그대로 나와야 한다
			_DepQuartiles(3u, MLTWorldCfg::kAutoMany);
			LogA("[mlt] 📐     %s  ㉠ 거친·옛(230 의 ㈀)   %8.4f/%8.4f/%8.4f  %7.2f  %6u  %.4f\n",
				wn2[iw], (double)_depThr[0], (double)_depThr[1], (double)_depThr[2],
				(double)_depObsMax, _depTot, (double)(kDepMax / (float)kDepBins));
			// ㈀ 고운 눈금 · **옛** 세계설정(`_Pt(3)` · 세계 무시)
			_DepQuartiles(3u, MLTWorldCfg::kAutoMany, false, -1, true);
			for (uint32 k = 0; k < 3u; ++k) fineThr[iw][0][k] = _depThr[k];
			LogA("[mlt] 📐     %s  ㈀ 고운·옛(_Pt3)        %8.4f/%8.4f/%8.4f  %7.2f  %6u  %.4f\n",
				wn2[iw], (double)_depThr[0], (double)_depThr[1], (double)_depThr[2],
				(double)_depObsMax, _depTot, (double)(_depObsMax / (float)kDepBins));
			// ㈁ 고운 눈금 · **새** 세계설정(`_PtTrain` · 세계 맞춤)
			_DepQuartiles(3u, MLTWorldCfg::kAutoMany, true, ws[iw], true);
			for (uint32 k = 0; k < 3u; ++k) fineThr[iw][1][k] = _depThr[k];
			LogA("[mlt] 📐     %s  ㈁ 고운·새(_PtTrain)    %8.4f/%8.4f/%8.4f  %7.2f  %6u  %.4f\n",
				wn2[iw], (double)_depThr[0], (double)_depThr[1], (double)_depThr[2],
				(double)_depObsMax, _depTot, (double)(_depObsMax / (float)kDepBins));
			double dsum = 0.0;
			for (uint32 k = 0; k < 3u; ++k) dsum += (double)Abs(fineThr[iw][1][k] - fineThr[iw][0][k]);
			LogA("[mlt] 📐       ⭐ 관문 ① 문턱 차 합 **%.4f px** → %s\n", dsum,
				(dsum > 1.0e-4) ? "✅ **갈린다** — 자가 가를 수 있다 ⇒ ② 로 간다"
				                : "⛔ **안 갈린다** ⇒ ⚠️ 인자가 안 먹었을 수 있다(규율 13-b)");
		}
		LogA("[mlt] 📐   ── ② 📊 **고운 눈금에서 깊이 순 여지**(거친 쪽은 230 이 쟀다: 궤도 10.4%% · 가속 9.2%%) ──\n");
		LogA("[mlt] 📐     세계  세계설정      깊이 순여지  순사본천장(배관)\n");
		for (uint32 iw = 0; iw < 2u; ++iw)
		{
			double depOf[2] = { 0.0, 0.0 }, netOf[2] = { 0.0, 0.0 };
			for (uint32 m = 0; m < 2u; ++m)
			{
				_ampOv = kTrAmp; _dtOv = kTrDt;
				if (m == 0u) _DepQuartiles(3u, MLTWorldCfg::kAutoMany, false, -1,     true);
				else         _DepQuartiles(3u, MLTWorldCfg::kAutoMany, true, ws[iw], true);
				_FillA(ws[iw]);
				double base = 0.0, dm = 0.0, per = 0.0; uint32 used = 0u;
				_CStat(0u, base, dm, 0.0, used, per);
				double r[8]; for (uint32 a = 1u; a < 8u; ++a)
				{ double hc = 0.0, rr = 0.0, p2 = 0.0; uint32 u2 = 0u; _CStat(a, hc, rr, base, u2, p2); r[a] = rr; }
				const double d = (base > 1.0e-9) ? 100.0 / base : 0.0;
				depOf[m] = (r[4] - r[6]) * d;
				netOf[m] = (r[1] - r[2]) * d;             // ⭐ 깊이와 **무관**한 칸
				LogA("[mlt] 📐     %s  %s  %8.1f%%  %11.1f%%\n",
					wn2[iw], (m == 0u) ? "㈀ 옛(_Pt3) " : "㈁ 새(_Train)", depOf[m], netOf[m]);
			}
			const double dd = depOf[1] - depOf[0];
			const double nd = netOf[1] - netOf[0];
			LogA("[mlt] 📐       ⭐ 관문 ② **%.1f%%p**(㈀ %.1f%% → ㈁ %.1f%%) · 배관 %.2f%%p → %s\n",
				dd, depOf[0], depOf[1], nd,
				(Abs((float)nd) > 0.5f)
					? "⛔⛔ **배관이 깨졌다** — 표제를 읽지 마라"
					: ((Abs((float)dd) < 1.0)
						? "🔶 **1%p 미만** ⇒ ★★ ***자는 갈랐고 결론은 안 흔들린다*** ⇒ D42·D43 을 함께 닫는다"
						: "⚠️ ⭐ **흔들린다** — 218·226 의 깊이 칸을 그만큼 고쳐 적는다"));
		}
		_ampOv = -1.0f; _dtOv = -1.0f;
		LogA("[mlt] 📐 ══════════════════════════════════════════════\n");
		_aSweep = false; _a4 = false;
	}

	// ══════════════════════════════════════════════════════════════════
	// ⭐ 회차 229 — **흐름 표적의 형태를 고른다**(228 의 갈래 ㈁ · 학습 0)
	// ══════════════════════════════════════════════════════════════════
	static void _RunFlow()
	{
		_SetDir(true, _dirThr);
		_aSweep = true; _a5 = true;
		LogA("[mlt] 🌊 ══════════════════════════════════════════════\n");
		LogA("[mlt] 🌊 **회차 229 · 흐름 표적의 형태를 고른다**(학습 0 · ~90초)\n");
		LogA("[mlt] 🌊   ⚙️ 228: λ0.03 의 차의 차 −0.0191 · `t` **1.29** · 8/12 ⇒ **판정불가**\n");
		LogA("[mlt] 🌊      ⇒ 필요 씨앗 **65**(~2시간). 씨앗은 **선형**으로 비싸고 효과는 **제곱**으로 싸다\n");
		LogA("[mlt] 🌊      ⇒ ★ 그런데 **어느 형태가 큰지 모르고 고르면 또 판정불가**다(규율 49·12)\n");
		LogA("[mlt] 🌊   🔬 가설(⚠️ **근거가 아니다** — 규율 18): 지금 표적은 **방향 10 계급**이고\n");
		LogA("[mlt] 🌊      **크기를 버린다**. `dYaw` 는 연속이고 흐름 **속력**과 거의 선형이다\n");
		LogA("[mlt] 🌊      ⇒ ⭐ ***지금 표적이 행동값의 「부호」만 쓰고 있을 수 있다.***\n");
		LogA("[mlt] 🌊   📐 자 = 순 여지 비 `( H(T|음성9) − H(T|dYaw9) ) ÷ H(T)`\n");
		LogA("[mlt] 🌊      ⚠️ 음성 짝은 **같은 칸 수**(규율 14) · 분모는 **그 표적 자신의 정보량**(규율 67)\n");
		LogA("[mlt] 🌊   ⚠️⚠️ ***여지가 있다고 몸통이 쓴다는 뜻이 아니다***(규율 69) — **상한만** 준다\n");
		static const int   ws[2]  = { 2, 3 };
		static const char* wn2[2] = { "궤도", "가속" };
		static const char* tn[4]  = { "Ⓐ 방향(지금)", "Ⓑ 속력(8분위)", "Ⓒ 방향4×속력2", "Ⓓ 자율방향(타자)" };
		double ratA[2] = { 0.0, 0.0 };
		for (uint32 iw = 0; iw < 2u; ++iw)
		{
			_ampOv = kTrAmp; _dtOv = kTrDt;      // ⭐ 220 — **몸통의 자리**
			_FlowOctiles(ws[iw]);                // ⭐ 세계마다 속력 눈금을 다시 뽑는다
			_DepQuartiles(3u, MLTWorldCfg::kAutoMany);
			_FillA(ws[iw]);
			LogA("[mlt] 🌊   ── 📊 **%s** · 속력 8분위 문턱 %.2f/%.2f/%.2f/%.2f/%.2f/%.2f/%.2f px ──\n",
				wn2[iw], (double)_flowThr[0], (double)_flowThr[1], (double)_flowThr[2],
				(double)_flowThr[3], (double)_flowThr[4], (double)_flowThr[5], (double)_flowThr[6]);
			LogA("[mlt] 🌊     표적               분모H    +dYaw9   음성9   ⭐**순 여지 비**\n");
			for (uint32 k = 0; k < 4u; ++k)
			{
				const uint32 a0 = k * 3u;
				double base = 0.0, dm = 0.0, per = 0.0; uint32 used = 0u;
				_CStat(a0, base, dm, 0.0, used, per);
				double hY = 0.0, rY = 0.0, pY = 0.0; uint32 uY = 0u;
				double hR = 0.0, rR = 0.0, pR = 0.0; uint32 uR = 0u;
				_CStat(a0 + 1u, hY, rY, base, uY, pY);
				_CStat(a0 + 2u, hR, rR, base, uR, pR);
				// ⭐ 순 여지 비 = (음성 조건부 H − dYaw 조건부 H) ÷ 분모 H
				const double net = (base > 1.0e-9) ? ((hR - hY) / base) : 0.0;
				if (k == 0u) ratA[iw] = net;
				LogA("[mlt] 🌊     %s %6.4f  %6.4f  %6.4f  %8.3f  (칸당 %.0f)\n",
					tn[k], base, hY, hR, net, pY);
			}
			if (iw == 0u)
			{
				// ⭐ 관문은 **궤도**(몸통이 도는 세계)에서만 본다
				double bestNet = 0.0; uint32 bestK = 0u;
				for (uint32 k = 1u; k < 3u; ++k)
				{
					const uint32 a0 = k * 3u;
					double base = 0.0, dm = 0.0, per = 0.0; uint32 used = 0u;
					_CStat(a0, base, dm, 0.0, used, per);
					double hY = 0.0, rY = 0.0, pY = 0.0; uint32 uY = 0u;
					double hR = 0.0, rR = 0.0, pR = 0.0; uint32 uR = 0u;
					_CStat(a0 + 1u, hY, rY, base, uY, pY);
					_CStat(a0 + 2u, hR, rR, base, uR, pR);
					const double net = (base > 1.0e-9) ? ((hR - hY) / base) : 0.0;
					if (net > bestNet) { bestNet = net; bestK = k; }
				}
				const double gain = (ratA[0] > 1.0e-9) ? (bestNet / ratA[0]) : 0.0;
				LogA("[mlt] 🌊   ── 🚪 관문(궤도 = 몸통이 도는 세계) ──\n");
				LogA("[mlt] 🌊     ⭐ ① **표제 — 최선이 Ⓐ 의 1.5배 이상인가**\n");
				LogA("[mlt] 🌊        Ⓐ **%.3f** ↔ 최선 **%s %.3f** ⇒ **%.2f배**\n",
					ratA[0], tn[bestK], bestNet, gain);
				LogA("[mlt] 🌊        판정 → %s\n",
					(gain >= 1.5)
						? "✅ ⭐ **형태를 바꿀 값이 있다** — 그 형태로 다음 회차의 격자를 짠다"
						: "⛔ **못 키운다** ⇒ ★ ㈁ 을 접고 **씨앗(㈀)** 또는 **D41(㈂)** 로 간다");
				LogA("[mlt] 🌊     ⚠️ ② 음성 짝은 **위 표의 「음성9」가 분모H 와 같아야** 한다(규율 88)\n");
				LogA("[mlt] 🌊     ⓘ ③ 타자 자 Ⓓ 를 같은 판에 뒀다(규율 18-a ㈁) — 218 의 그 값 = **0.274**\n");
				LogA("[mlt] 🌊     ⚠️⚠️ ④ **`d̄` 는 이 비에 비례하지 않는다**(규율 69) — 이것은 **상한**이다\n");
			}
		}
		_ampOv = -1.0f; _dtOv = -1.0f;
		LogA("[mlt] 🌊   📌 **D42** — `_DepQuartiles` 가 아직 `_Pt(3)`(dt 0.25)를 쓴다(`_FillA` 는 dt 1.00)\n");
		LogA("[mlt] 🌊      ⇒ ⚠️ 220 이 고친 사고가 **깊이 문턱 한 자리에 남아 있다**. 옛 자는 안 건드렸다(규율 58)\n");
		LogA("[mlt] 🌊 ══════════════════════════════════════════════\n");
		_aSweep = false; _a5 = false;
	}

	static void _RunBal()
	{
		_ptIntent = true;      // ⭐ 232 — 이 판도 `dtMul` 을 **일부러** 스윕한다
		_SetDir(true, _dirThr);
		_aSweep = true; _a3 = true;
		_DepQuartiles(3u, MLTWorldCfg::kAutoMany);
		LogA("[mlt] 🧭 ══════════════════════════════════════════════\n");
		LogA("[mlt] 🧭 **회차 218 · 균형점이 있나** — 행동 여지와 **언어 여지를 같은 눈금으로**(학습 0)\n");
		LogA("[mlt] 🧭   ⚙️ 217: 가속에서 캡션의 **순 `Î` = 0.0000** ⇒ ***언어가 죽는다***\n");
		LogA("[mlt] 🧭      ⛔ 그런데 **216 은 행동 여지만 재고 처방을 냈다**\n");
		LogA("[mlt] 🧭      ⇒ 🧾 ***한 축을 키우려고 세계를 고치면 다른 축이 그만큼 죽는지 먼저 재라***\n");
		LogA("[mlt] 🧭      ⇒ ⭐ 이 회차가 그것을 갚는다 — **둘을 한 표에** 놓는다\n");
		LogA("[mlt] 🧭   ⭐ 캡션 정의는 `mltl1t0` **그대로**(규율 58): *\"다음 시각에 **계급이 바뀌는**\n");
		LogA("[mlt] 🧭      슬롯 번호\"*(번호 작은 순 · 방향값은 **안 넣는다** = D7)\n");
		LogA("[mlt] 🧭   🔮 **주 예측**\n");
		LogA("[mlt] 🧭      ㉠ 배관 — 행동 여지가 216 재현(궤도 dt.25 **2.7%%** · 가속 dt.25 **24.2%%**)\n");
		LogA("[mlt] 🧭      ⭐ ㉡ **언어 여지가 행동 여지와 반대로 간다**(`dtMul` ↑ ⇒ 언어 ↓)\n");
		LogA("[mlt] 🧭      ⭐ ㉢ **균형점이 있다** — 둘 다 각자 최대의 **50%% 이상**인 `dtMul` 이 있다\n");
		LogA("[mlt] 🧭      ㉣ 궤도 dt.25 언어 여지 **> 0** · ㉤ 가속 dt.25 언어 여지 **≈ 0**(217)\n");
		LogA("[mlt] 🧭   ⚠️ 「상수로 둔 것」 — 학습 하네스는 **보이는 것 중 번호 작은 8개**를 슬롯으로 쓰는데\n");
		LogA("[mlt] 🧭      여기서는 **도형 번호 그대로** 쓴다(근사) · 자리 1 의 「첫 바뀌는 것」 모양은 같다\n");
		static const int   ws[2]  = { 2, 3 };
		static const float dts[4] = { 1.0f, 0.5f, 0.25f, 0.125f };
		static const char* wn2[2] = { "궤도", "가속" };
		LogA("[mlt] 🧭   ── 📊 세계 × `dtMul` — ⭐ **순 여지 비**(음성 짝을 뺀 값 ÷ 분모) ──\n");
		LogA("[mlt] 🧭     세계  dtMul   분모H   ⭐**행동**  ⭐**캡션자리1**  ⭐**캡션천장**  깊이   행동몫\n");
		double ra[2][4], rc[2][4], rk[2][4], hh2[2][4];
		for (uint32 iw = 0; iw < 2u; ++iw)
			for (uint32 id = 0; id < 4u; ++id)
			{
				_ampOv = 1.0f; _dtOv = dts[id];
				_FillA(ws[iw]);
				double base = 0.0, dm = 0.0, per = 0.0; uint32 used = 0u;
				_CStat(0u, base, dm, 0.0, used, per);
				double r[7]; for (uint32 a = 1u; a < 7u; ++a)
				{ double hc = 0.0, rr = 0.0, p2 = 0.0; uint32 u2 = 0u; _CStat(a, hc, rr, base, u2, p2); r[a] = rr; }
				const double d = (base > 1.0e-9) ? 100.0 / base : 0.0;
				ra[iw][id] = (r[1] - r[2]) * d;      // 행동  (음성 짝 = 9칸)
				rc[iw][id] = (r[3] - r[5]) * d;      // 캡션 자리 1 (음성 짝 = 2칸)
				rk[iw][id] = (r[4] - r[5]) * d;      // 캡션 천장  (음성 짝 = 2칸)
				hh2[iw][id] = base;
				LogA("[mlt] 🧭     %s %6.4f  %.4f  %8.1f%%  %10.1f%%  %11.1f%%  %5.1f%%  %5.1f%%\n",
					wn2[iw], (double)dts[id], base, ra[iw][id], rc[iw][id], rk[iw][id],
					(r[6] - r[5]) * d, 100.0 * _actShare);
			}
		_ampOv = -1.0f; _dtOv = -1.0f;
		LogA("[mlt] 🧭   ── 🚪 관문 ──\n");
		LogA("[mlt] 🧭     ⭐ ① **배관** — 궤도 dt.25 분모 **%.4f** ↔ 214~216 의 **0.1534** → %s\n",
			hh2[0][2], (Abs((float)(hh2[0][2] - 0.1534)) < 0.005) ? "✅" : "⛔⛔ **다르다**");
		// ⭐ 균형점 — 각 축의 최대 대비 몫이 둘 다 0.5 를 넘는 점
		double bestMin = -1.0; uint32 bw = 0u, bd = 0u;
		double maxA = 1.0e-9, maxK = 1.0e-9;
		for (uint32 iw = 0; iw < 2u; ++iw) for (uint32 id = 0; id < 4u; ++id)
		{ if (ra[iw][id] > maxA) maxA = ra[iw][id]; if (rk[iw][id] > maxK) maxK = rk[iw][id]; }
		for (uint32 iw = 0; iw < 2u; ++iw) for (uint32 id = 0; id < 4u; ++id)
		{
			const double fa = ra[iw][id] / maxA, fk = rk[iw][id] / maxK;
			const double m = (fa < fk) ? fa : fk;
			if (m > bestMin) { bestMin = m; bw = iw; bd = id; }
		}
		LogA("[mlt] 🧭     ⭐ ② **표제 — 균형점이 있나**\n");
		LogA("[mlt] 🧭        최대 행동 **%.1f%%** · 최대 캡션천장 **%.1f%%**\n", maxA, maxK);
		LogA("[mlt] 🧭        최선 = **%s · dtMul %.4f** — 행동 **%.1f%%**(최대의 %.0f%%) ·\n",
			wn2[bw], (double)dts[bd], ra[bw][bd], 100.0 * ra[bw][bd] / maxA);
		LogA("[mlt] 🧭           캡션천장 **%.1f%%**(최대의 %.0f%%) ⇒ **약한 쪽 %.0f%%**\n",
			rk[bw][bd], 100.0 * rk[bw][bd] / maxK, 100.0 * bestMin);
		LogA("[mlt] 🧭        판정 → %s\n",
			(bestMin >= 0.50)
				? "✅✅ ⭐ ***균형점이 있다*** — ★ 그 자리에서 칸 3 을 연다"
				: ((bestMin >= 0.25)
					? "🔶 **약한 균형점** — ⚠️ 한 축을 절반 이상 잃는다 ⇒ 사람이 정한다"
					: "⛔⛔ **균형점이 없다** — ★ ***두 축이 정말로 배타적이다*** ⇒ 캡션을 다시 정의해야 한다"));
		LogA("[mlt] 🧭     ⭐ ③ **㉡ 반대로 가나** — 궤도에서 `dtMul` 1.0 → .125\n");
		LogA("[mlt] 🧭        행동 %.1f%% → %.1f%% · 캡션천장 %.1f%% → %.1f%% → %s\n",
			ra[0][0], ra[0][3], rk[0][0], rk[0][3],
			((ra[0][0] > ra[0][3]) && (rk[0][0] < rk[0][3]))
				? "✅ **반대로 간다 — ㉡ 적중**"
				: "⚠️ **같이 간다** — ★ 그러면 배타가 아니고 다른 설명이 필요하다");
		LogA("[mlt] 🧭     ⓘ ④ 217 의 두 자리 — 궤도 dt.25 캡션천장 **%.1f%%** · 가속 dt.25 **%.1f%%**\n",
			rk[0][2], rk[1][2]);
		LogA("[mlt] 🧭 ══════════════════════════════════════════════\n");
		_aSweep = false; _a3 = false; _ptIntent = false;   // ⚠️ 232 — 안 되돌리면 **방벽이 조용히 꺼진다**
	}

	static void _RunW2()
	{
		_SetDir(true, _dirThr);
		const int autoN = MLTWorldCfg::kAutoMany;
		LogA("[mlt] 🧭 ══════════════════════════════════════════════\n");
		LogA("[mlt] 🧭 **회차 198 · 세계를 바꾼다** — 새 세계 넷에서 같은 여지 지도(학습 0)\n");
		LogA("[mlt] 🧭   ⚙️ 197: 전부 알아도 **7.3%%** ⇒ ★ *\"이 세계는 「직전 방향」이 거의 전부\"*\n");
		LogA("[mlt] 🧭   ⭐ **원인을 코드에서 찾았다**(`mltworld::_ShapeWorld`)\n");
		LogA("[mlt] 🧭      ㈀ 도형 14개 중 **3개만** 움직이고 11개는 **월드에서 정지**다\n");
		LogA("[mlt] 🧭        ⇒ 그 11개의 화면 이동은 **전부 카메라** 때문이다\n");
		LogA("[mlt] 🧭      ㈁ 움직이는 3개도 **정현파**라 꺾임이 없다\n");
		LogA("[mlt] 🧭      ⇒ ★ 화면 방향 = **카메라의 공통 흐름** ⇒ 전 화면이 같이 흐른다\n");
		LogA("[mlt] 🧭      ⇒ ⭐ 그것이 **192 의 «상태 5축이 90%%»** 와 같은 사실이다\n");
		LogA("[mlt] 🧭   ⇒ ⭐ 처방 = 도형이 **자기 운동**을 갖고 그것이 ***관측 가능한 사건으로 꺾인다***\n");
		LogA("[mlt] 🧭   ⚠️ 자를 안 바꿨다(규율 58) — 197 의 조건 팔 여덟 그대로 · 세계만 감았다\n");
		_DepQuartiles(3u, autoN);
		LogA("[mlt] 🧭   ⭐ 깊이 문턱 = **%.2f · %.2f · %.2f**\n",
			(double)_depThr[0], (double)_depThr[1], (double)_depThr[2]);

		static const char* wn[4] = { "0 옛 세계", "1 반사   ", "2 궤도   ", "3 가속   " };
		LogA("[mlt] 🧭   ── 📊 세계 × 조건 — ⭐ **순 여지 비**(편향 ㉯ 를 뺀 값 ÷ 분모) ──\n");
		LogA("[mlt] 🧭     세계        분모H    ㈁2시각  ㈂역사   ㈃위치   ㈄깊이   ㈅다른물체 ㈆역사+위치  ㉯편향\n");
		double bestRatio = 0.0; int bestW = 0; uint32 bestA = 0u;
		double base0 = 0.0;
		for (int w2 = 0; w2 < 4; ++w2)
		{
			_FillC(w2, 1u);
			double base = 0.0, dm = 0.0, per = 0.0; uint32 used = 0u;
			_CStat(0u, base, dm, 0.0, used, per);
			if (w2 == 0) base0 = base;
			double net[kCArms];
			double bias = 0.0;
			{
				double hc = 0.0, rm = 0.0; uint32 u2 = 0u; double p2 = 0.0;
				_CStat(7u, hc, rm, base, u2, p2); bias = rm;
			}
			for (uint32 a = 1u; a < 7u; ++a)
			{
				double hc = 0.0, rm = 0.0, p2 = 0.0; uint32 u2 = 0u;
				_CStat(a, hc, rm, base, u2, p2);
				net[a] = rm - bias;
				const double r = (base > 1.0e-9) ? 100.0 * net[a] / base : 0.0;
				if (r > bestRatio) { bestRatio = r; bestW = w2; bestA = a; }
			}
			LogA("[mlt] 🧭     %s  %.4f  %5.1f%%  %5.1f%%  %5.1f%%  %5.1f%%  %5.1f%%   %6.1f%%   %.4f\n",
				wn[w2], base,
				(base > 1.0e-9) ? 100.0 * net[1] / base : 0.0,
				(base > 1.0e-9) ? 100.0 * net[2] / base : 0.0,
				(base > 1.0e-9) ? 100.0 * net[3] / base : 0.0,
				(base > 1.0e-9) ? 100.0 * net[4] / base : 0.0,
				(base > 1.0e-9) ? 100.0 * net[5] / base : 0.0,
				(base > 1.0e-9) ? 100.0 * net[6] / base : 0.0,
				bias);
		}
		LogA("[mlt] 🧭   ── 🚪 관문 ──\n");
		LogA("[mlt] 🧭     ① 배관 — 세계 0 의 분모 **%.4f** ↔ 197 의 **0.3191** → %s\n", base0,
			(Abs((float)(base0 - 0.3191)) < 0.005)
				? "✅ **비트 동일** — ★ 새 모드가 옛 세계를 안 건드렸다"
				: "⛔⛔ **옛 세계가 바뀌었다** — ★ 그러면 회차 1~197 이 전부 흔들린다");
		LogA("[mlt] 🧭     ⭐ ② **표제** — 최고 = **세계 %s · %s** 비 **%.1f%%**(≥ 15%%) → %s\n",
			wn[bestW], _CArmName(bestA), bestRatio,
			(bestRatio >= 15.0)
				? "✅✅ ⭐ ***여지가 있는 세계를 찾았다*** ⇒ `P` 를 그 세계에서 다시 돈다"
				: "⛔⛔ **셋 다 안 연다** ⇒ ★ 처방이 틀렸다 — 원인을 다시 본다");
		LogA("[mlt] 🧭        ⓘ 지금 자리(세계 0 · ㈆)는 **7.3%%** 다 ⇒ 최고가 그 **%.1f배**\n",
			bestRatio / 7.3);
		LogA("[mlt] 🧭     ⚠️ ③ 「없음」 — 새 세계에서 물체가 화면 밖으로 나가면 표적이 변질된다\n");
		LogA("[mlt] 🧭        ★ 아래 표에 「없음」 몫을 같이 찍는다(< 60%% 여야 한다)\n");
		for (int w2 = 0; w2 < 4; ++w2)
		{
			_FillC(w2, 1u);
			uint32 noneN = 0u, tot = 0u;
			for (uint32 cn = 0; cn < kDirCls; ++cn)
				for (uint32 df = 0; df < kDirCls; ++df)
				{
					const uint32 n = _hc[_HcIx(0u, cn, df)];
					tot += n; if (df == kDirCls - 1u) noneN += n;
				}
			const double nf = (tot == 0u) ? 0.0 : 100.0 * (double)noneN / (double)tot;
			LogA("[mlt] 🧭        세계 %s 「없음」 **%.1f%%** → %s\n", wn[w2], nf,
				(nf < 60.0) ? "✅" : "⛔ **표적이 변질된다**(규율 78)");
		}
		LogA("[mlt] 🧭 ══════════════════════════════════════════════\n");
	}

	static void _RunC()
	{
		_SetDir(true, _dirThr);
		const Pt pt = _Pt(3u);                     // ㉃ dt.25 — 몸통이 쓰는 세계
		const int autoN = MLTWorldCfg::kAutoMany;
		const uint32 kKUse = 1u;                   // ⚠️ 표적은 **다음 방향**(k=1) — 195 가 k 를 이미 기각했다

		LogA("[mlt] 🧭 ══════════════════════════════════════════════\n");
		LogA("[mlt] 🧭 **회차 197 · 칸 2 의 분모를 세운다** — 🆕 칸 2 첫 회차(학습 0)\n");
		LogA("[mlt] 🧭   ⚠️⚠️ 195 는 **위치 하나**만 조건에 넣어 여지 3%% 를 냈다\n");
		LogA("[mlt] 🧭      ⇒ ⛔ 그것을 *\"세계에 여지가 없다\"* 로 읽었는데 ★ **위치만 없는 것일 수 있다**\n");
		LogA("[mlt] 🧭   ⭐ 몸통이 보는데 **한 번도 안 잰 것 셋**: 역사 · 깊이 · 다른 물체\n");
		LogA("[mlt] 🧭      ★ 회차 192 가 *\"몸통이 최근 **4시각**을 쓴다\"* 를 실측했다 ⇒ **쓸 것이 있어서 쓴다**\n");
		LogA("[mlt] 🧭   ⚠️⚠️ 조건을 쌓으면 칸이 빈다 ⇒ ★ 역사 팔은 방향을 **4분위**로 뭉치고\n");
		LogA("[mlt] 🧭      ⭐ **음성 대조 팔 ㉯**(무작위 조건 · ㈂ 와 **같은 칸 수 640**)를 둔다\n");
		LogA("[mlt] 🧭      ⇒ ★ ***그 팔의 여지가 곧 「빈 칸 편향」의 크기다***(규율 88)\n");
		LogA("[mlt] 🧭   씨앗 %u × 문맥 %u × 시각 %u~%u · 표적 = **다음 방향**(k=1) · 세계 ㉃\n",
			kSeeds, kCtx, 3u, kTime - 1u);
		_DepQuartiles(3u, autoN);
		LogA("[mlt] 🧭   ⭐ 깊이 문턱(데이터에서 뽑은 4분위) = **%.2f · %.2f · %.2f**\n",
			(double)_depThr[0], (double)_depThr[1], (double)_depThr[2]);

		_FillC(0, kKUse);   // ⭐ 197 · 198 이 **같은 자**를 쓴다(귀원 58)

		// ── 📊 표 ─────────────────────────────────────────────────
		double base = 0.0, dummy = 0.0; uint32 u0 = 0u; double p0 = 0.0;
		_CStat(0u, base, dummy, 0.0, u0, p0);      // ㈀ 의 조건부 H 가 분모다
		LogA("[mlt] 🧭   ── 📊 여지 지도 — 분모 `H(다음|지금방향)` = **%.4f** ──\n", base);
		LogA("[mlt] 🧭      팔                        조건칸  찬칸   칸당표본   H(·|조건)  ⭐ 여지   비\n");
		double room[kCArms]; double ratio[kCArms];
		for (uint32 a = 0; a < kCArms; ++a)
		{
			double hc = 0.0, rm = 0.0, per = 0.0; uint32 used = 0u;
			_CStat(a, hc, rm, base, used, per);
			room[a] = rm;
			ratio[a] = (base > 1.0e-9) ? 100.0 * rm / base : 0.0;
			LogA("[mlt] 🧭      %s %6u %6u %9.0f   %.4f   **%.4f**  %5.1f%%%s\n",
				_CArmName(a), _CondN(a), used, per, hc, rm, ratio[a],
				(a == 7u) ? "  ← 편향 바닥" : "");
		}
		// ── 🚪 관문 ───────────────────────────────────────────────
		const double bias = room[7];
		uint32 bestA = 0u; double bestNet = 0.0;
		for (uint32 a = 1u; a < 7u; ++a)
		{
			const double net = room[a] - bias;
			if (net > bestNet) { bestNet = net; bestA = a; }
		}
		const double bestRatio = (base > 1.0e-9) ? 100.0 * bestNet / base : 0.0;
		LogA("[mlt] 🧭   ── 🚪 관문 ──\n");
		// ⭐ 회차 197 1차가 자를 고치게 했다 — **182 가 맞는 짝이다**
		//   ★ 182 의 `H(방향|직전)` = **0.3181** ↔ 197 = 0.3191 ⇒ 규율 68 로 만난다.
		//   ⚠️ 195 의 **0.2747** 이 이상값이었다 — 그쪽은 `t ≥ 1` 이라 **첫 시각의 「정지」 채움**이
		//     표적에 들어가 엔트로피를 낮췄다(197 은 역사 팔 때문에 `t ≥ 3` 이다).
		LogA("[mlt] 🧭     ① 배관 — ㈀ 의 분모 **%.4f** ↔ **182 의 0.3181** → %s\n", base,
			(Abs((float)(base - 0.3181)) < 0.02)
				? "✅✅ ⭐ **두 길이 만났다**(규율 68) — ★ 195 의 0.2747 이 이상값이었다(`t≥1` 채움)"
				: "⚠️ **다르다** — ★ 표본을 다시 본다");
		LogA("[mlt] 🧭     ⭐ ② **음성 대조** — ㉯ 무작위 조건(칸 640)의 여지 **%.4f** = **편향 바닥**\n", bias);
		LogA("[mlt] 🧭        ⇒ ★ 다른 팔은 **이 위로** 올라야 뜻이 있다(규율 88) → %s\n",
			(bias < 0.05) ? "✅ 바닥이 낮다 — 자를 쓸 수 있다"
			              : "⚠️ **바닥이 높다** — ★ 계급을 더 뭉쳐 다시 잰다");
		LogA("[mlt] 🧭     ⭐ ③ **표제** — 편향을 뺀 최고 = **%s** 순 여지 **%.4f**(비 **%.1f%%**) → %s\n",
			_CArmName(bestA), bestNet, bestRatio,
			(bestRatio >= 15.0)
				? "✅✅ ⭐ ***이 세계에 여지가 있다*** ⇒ 칸 2 가 열린다"
				: "⛔⛔ **전부 편향 바닥 근처** ⇒ ★ **세계 교체가 강제된다**(사람과 정한다)");
		LogA("[mlt] 🧭     ⭐ ④ **역사** — ㈀ %.4f → ㈁ %.4f → ㈂ %.4f(단조 %s)\n",
			room[0], room[1], room[2], (room[2] >= room[1] && room[1] >= room[0]) ? "✅" : "⛔");
		LogA("[mlt] 🧭        ⇒ ★ 192 의 *\"몸통이 최근 4시각을 쓴다\"* 와 만나나 → %s\n",
			(room[2] - bias > 0.02) ? "✅ ⭐ **역사에 실제로 정보가 있다**"
			                        : "⛔ **역사도 편향 바닥이다** — ★ 그러면 192 는 **다른 것**을 봤다");
		LogA("[mlt] 🧭     ⚠️ ⑤ 상한 — ㈆(역사+위치) **%.4f** 가 최대인가 → %s\n", room[6],
			(room[6] >= room[2] && room[6] >= room[3]) ? "✅" : "⚠️ **조건이 서로 간섭한다**(적어 둔다)");
		LogA("[mlt] 🧭        ⓘ ㈆ − ㈂ = **%+.4f**(위치가 역사에 보태는 몫)\n", room[6] - room[2]);
		LogA("[mlt] 🧭 ══════════════════════════════════════════════\n");
	}

	// ⭐ 회차 196 — **세계 점을 팔로**(195 가 순서를 뒤집었다)
	//   ★ 195: 여지 ÷ ㉡ 가 k 에 **평평**(2.4~3.0%) ⇒ ***표적을 옮겨도 여지가 안 열린다***
	//   ⇒ ⭐ 그러면 손잡이는 **세계**다 — 여지 = `I(위치 ; 나중방향 | 지금방향)` 이 크려면
	//     ***위치가 방향을 바꾸는 사건***(= 화면 경계)이 있어야 하고 그 손잡이는 **`dt × amp`** 다.
	//   ⚠️ **자를 안 바꾼다**(규율 58) — `_KStat` 그대로, 점 루프만 감는다.
	inline static bool _wSweep = false;

	static void _FillK(uint32 ptIx, int autoN)
	{
		const Pt pt = _Pt(ptIx);
		_h3.Reset(0);
		for (uint32 i = 0; i < kKs * kGs * kDirCls * kPosMax * kDirCls; ++i) _h3.Add(0u);
		for (uint32 s = 0; s < kSeeds; ++s)
			for (uint32 c = 0; c < kCtx; ++c)
			{
				MLTWorld w;
				w.Reset(s, kEpi + c, pt.hold, autoN, pt.dt, pt.amp);
				static float sxT[kUMax + 1u][kShapes];
				static float syT[kUMax + 1u][kShapes];
				static bool  okT[kUMax + 1u][kShapes];
				for (uint32 u = 0; u <= kUMax; ++u)
				{
					for (int i = 0; i < kShapes; ++i) okT[u][i] = false;
					MLTShapeView vs[kShapes];
					const int nv = w.VisibleShapes(vs, kShapes);
					for (int i = 0; i < nv; ++i)
					{
						const int ix = vs[i].index;
						if (ix < 0 || ix >= kShapes) continue;
						sxT[u][ix] = vs[i].sx; syT[u][ix] = vs[i].sy; okT[u][ix] = true;
					}
					if (u < kUMax) w.Step();
				}
				for (uint32 t = 1u; t < kTime; ++t)
					for (int i = 0; i < kShapes; ++i)
					{
						const uint32 dn = _DirOf(sxT[t][i], syT[t][i], sxT[t - 1u][i], syT[t - 1u][i],
						                         okT[t][i], okT[t - 1u][i]);
						for (uint32 ki = 0; ki < kKs; ++ki)
						{
							const uint32 u = t + kKOf[ki];
							const uint32 df = _DirOf(sxT[u][i], syT[u][i], sxT[u - 1u][i], syT[u - 1u][i],
							                         okT[u][i], okT[u - 1u][i]);
							for (uint32 gi = 0; gi < kGs; ++gi)
							{
								const uint32 pn = okT[t][i] ? _PosCls(sxT[t][i], syT[t][i], kGOf[gi])
								                            : (kGOf[gi] * kGOf[gi]);
								_h3.Data()[_H3Ix(ki, gi, dn, pn, df)] += 1u;
							}
						}
					}
			}
	}

	static void _RunW()
	{
		_SetDir(true, _dirThr);
		const int autoN = MLTWorldCfg::kAutoMany;
		LogA("[mlt] 🧭 ══════════════════════════════════════════════\n");
		LogA("[mlt] 🧭 **회차 196 · 세계를 고른다** — 같은 캔버스 2회차(학습 0)\n");
		LogA("[mlt] 🧭   ⭐ 195 가 순서를 뒤집었다: 여지 ÷ ㉡ 가 k 에 **평평**(2.4~3.0%)\n");
		LogA("[mlt] 🧭      ⇒ ★ ***표적을 옮겨도 여지가 안 열린다*** ⇒ 손잡이는 **세계**다\n");
		LogA("[mlt] 🧭   ⭐ 손계산: 여지 = `I(위치 ; 나중방향 | 지금방향)` 이 크려면\n");
		LogA("[mlt] 🧭      ***위치가 방향을 바꾸는 사건***(= 화면 경계)이 있어야 한다\n");
		LogA("[mlt] 🧭      ⇒ 그 손잡이는 **`dt × amp`**(한 스텝에 얼마나 움직이나)\n");
		LogA("[mlt] 🧭   ⚠️ 그런데 **반대 벽**이 있다 — 너무 빠르면 화면을 통째로 지나쳐\n");
		LogA("[mlt] 🧭      「없음」이 지배하고 방향이 무작위가 된다 ⇒ ★ **최적점이 중간**이다\n");
		LogA("[mlt] 🧭   ⚠️ **자를 안 바꿨다**(규율 58) — 195 의 `_KStat` 그대로 · 점 루프만 감았다\n");
		LogA("[mlt] 🧭   ── 📊 여지(굵기 4×4) — ⭐ **비**를 표제로 읽는다(규율 87) ──\n");
		LogA("[mlt] 🧭     점            dt×amp   k=1 ㉡    k=1 여지  비     k=8 ㉡    k=8 여지  ⭐ 비    「없음」\n");
		double best = 0.0; uint32 bestIx = 0u; double pt3r = 0.0, stillR = 0.0;
		for (uint32 p = 0; p < kPts; ++p)
		{
			const Pt pp = _Pt(p);
			_FillK(p, autoN);
			KRes r1, r8; _KStat(0u, 1u, false, r1); _KStat(kKs - 1u, 1u, false, r8);
			const double b1 = (r1.hcD > 1.0e-9) ? 100.0 * r1.room / r1.hcD : 0.0;
			const double b8 = (r8.hcD > 1.0e-9) ? 100.0 * r8.room / r8.hcD : 0.0;
			LogA("[mlt] 🧭     %-12s  %6.3f   %.4f   %.4f  %4.1f%%  %.4f   %.4f  **%4.1f%%**  %5.1f%%%s\n",
				_PtName(p), (double)(pp.dt * pp.amp), r1.hcD, r1.room, b1, r8.hcD, r8.room, b8,
				100.0 * r8.noneFrac, (p == 3u) ? "  ← 195 의 점" : "");
			if (p == 3u) pt3r = r1.room;
			if (p == 6u) stillR = r8.room;
			if (b8 > best && r8.noneFrac < 0.60) { best = b8; bestIx = p; }
		}
		LogA("[mlt] 🧭   ── 🚪 관문 ──\n");
		LogA("[mlt] 🧭     ① 배관 — ㈃ 의 `k=1` 여지 **%.4f** ↔ 195 의 **0.0076** → %s\n",
			pt3r, (Abs((float)(pt3r - 0.0076)) < 0.0005) ? "✅ **비트 동일**"
			                                             : "⛔ **다르다** — ★ 자가 바뀌었다");
		LogA("[mlt] 🧭     ⭐ ② 배관(음성 대조) — ㈆ 정지 세계의 `k=8` 여지 **%.4f**(< 0.005) → %s\n",
			stillR, (stillR < 0.005) ? "✅ **자가 안 샌다**"
			                         : "⛔⛔ **자가 샌다** — ★ 여지 값 전부를 못 쓴다(195 결론도 보류)");
		LogA("[mlt] 🧭     ⭐ ③ **표제** — 「없음」< 60%% 인 점 중 최고 비 = **%s %.1f%%**(≥ 15%%) → %s\n",
			_PtName(bestIx), best,
			(best >= 15.0) ? "✅✅ ⭐ ***세계를 옮길 값이 있다***"
			               : "⛔⛔ **세계 축도 닫힌다** ⇒ ★ 갈래 ①(인정) — 칸 1 을 🔶 로 닫고 칸 2 를 연다");
		LogA("[mlt] 🧭        ⓘ 지금 자리(㈃)는 **3.0%%** 다 ⇒ 최고가 그 **%.1f배**\n", best / 3.0);
		LogA("[mlt] 🧭 ══════════════════════════════════════════════\n");
	}

	static void _RunK()
	{
		_SetDir(true, _dirThr);
		const Pt pt = _Pt(3u);                       // ㉃ dt.25
		const int autoN = MLTWorldCfg::kAutoMany;
		_h3.Reset(0);
		for (uint32 i = 0; i < kKs * kGs * kDirCls * kPosMax * kDirCls; ++i) _h3.Add(0u);

		LogA("[mlt] 🧭 ══════════════════════════════════════════════\n");
		LogA("[mlt] 🧭 **회차 195 · 표적의 여지를 키운다** — 🆕 새 캔버스(학습 0)\n");
		LogA("[mlt] 🧭   ⚙️ 194 가 `P3` 를 **원리적으로** 못 닫음을 확정했다:\n");
		LogA("[mlt] 🧭      σ(CE−목표선) **0.103** ⇒ 12씨앗 t≥3 에 필요한 |d̄| **0.089** 나트\n");
		LogA("[mlt] 🧭      ↔ 입력 전체의 기여 **0.055** 나트(193) ⇒ ⛔ **표적에 여지가 없다**\n");
		LogA("[mlt] 🧭   ⇒ ★ 원인은 `H(방향|직전) = 0.32`(182) — ***관성이 너무 강하다***\n");
		LogA("[mlt] 🧭   ⇒ ⭐ 표적을 **k스텝 뒤의 방향**으로 옮긴다(규율 76)\n");
		LogA("[mlt] 🧭   ⭐ **그리고 「여지」를 학습 0 으로 직접 잰다**\n");
		LogA("[mlt] 🧭      ㉡ `H(방향_{t+k} | 방향_t)`         = 목표선(직전 방향만)\n");
		LogA("[mlt] 🧭      ㉢ `H(방향_{t+k} | 방향_t, 위치_t)`  = 위치까지 아는 예측자\n");
		LogA("[mlt] 🧭      ⇒ ★ **여지 = ㉡ − ㉢** = 「위치를 알면 더 맞히는 몫」\n");
		LogA("[mlt] 🧭   ⚠️⚠️ 조건 칸이 많으면 `H` 가 **가짜로** 내려간다 ⇒ ★ **굵기를 팔로** 둔다\n");
		LogA("[mlt] 🧭      (굵기를 올릴수록 여지가 **줄어야** 정상 — 커지면 그건 **편향**이다)\n");
		LogA("[mlt] 🧭   씨앗 %u × 문맥 %u × 시각 1~%u · 세계 ㉃ dt %.2f amp %.2f · 자율 %d\n",
			kSeeds, kCtx, kTime - 1u, (double)pt.dt, (double)pt.amp, autoN);

		for (uint32 s = 0; s < kSeeds; ++s)
			for (uint32 c = 0; c < kCtx; ++c)
			{
				MLTWorld w;
				w.Reset(s, kEpi + c, pt.hold, autoN, pt.dt, pt.amp);
				// ⭐ 상태 0..kUMax 의 물체별 화면 좌표(index 가 identity 라 추적이 공짜다)
				static float sxT[kUMax + 1u][kShapes];
				static float syT[kUMax + 1u][kShapes];
				static bool  okT[kUMax + 1u][kShapes];
				for (uint32 u = 0; u <= kUMax; ++u)
				{
					for (int i = 0; i < kShapes; ++i) okT[u][i] = false;
					MLTShapeView vs[kShapes];
					const int nv = w.VisibleShapes(vs, kShapes);
					for (int i = 0; i < nv; ++i)
					{
						const int ix = vs[i].index;
						if (ix < 0 || ix >= kShapes) continue;
						sxT[u][ix] = vs[i].sx; syT[u][ix] = vs[i].sy; okT[u][ix] = true;
					}
					if (u < kUMax) w.Step();
				}
				// ⭐ 표적을 채운다 — `t` 는 1..kTime-1(방향_t 가 직전을 필요로 한다)
				for (uint32 t = 1u; t < kTime; ++t)
					for (int i = 0; i < kShapes; ++i)
					{
						const uint32 dn = _DirOf(sxT[t][i], syT[t][i], sxT[t - 1u][i], syT[t - 1u][i],
						                         okT[t][i], okT[t - 1u][i]);
						for (uint32 ki = 0; ki < kKs; ++ki)
						{
							const uint32 u = t + kKOf[ki];
							const uint32 df = _DirOf(sxT[u][i], syT[u][i], sxT[u - 1u][i], syT[u - 1u][i],
							                         okT[u][i], okT[u - 1u][i]);
							for (uint32 gi = 0; gi < kGs; ++gi)
							{
								const uint32 pn = okT[t][i] ? _PosCls(sxT[t][i], syT[t][i], kGOf[gi])
								                            : (kGOf[gi] * kGOf[gi]);
								_h3.Data()[_H3Ix(ki, gi, dn, pn, df)] += 1u;
							}
						}
					}
			}

		// ── 📊 표 — 전체 채점 기준 ────────────────────────────────
		double room1 = 0.0, roomLast = 0.0, hcD1 = 0.0, noneLast = 0.0;
		bool mono = true, biasOk = true;
		LogA("[mlt] 🧭   ── 📊 **전체 표적** — 굵기 4×4 기준(가운데) ──\n");
		LogA("[mlt] 🧭      k    ㉠ H(나중)  ㉡ H(·|방향)  ㉢ H(·|방향,위치)  ⭐ 여지    여지÷㉡   「없음」\n");
		for (uint32 ki = 0; ki < kKs; ++ki)
		{
			KRes r; _KStat(ki, 1u, false, r);
			LogA("[mlt] 🧭     %2u     %.4f      %.4f         %.4f        **%.4f**   %5.1f%%   %5.1f%%\n",
				kKOf[ki], r.h, r.hcD, r.hcDP, r.room,
				(r.hcD > 1.0e-9) ? 100.0 * r.room / r.hcD : 0.0, 100.0 * r.noneFrac);
			if (ki == 0u) { room1 = r.room; hcD1 = r.hcD; }
			if (ki > 0u && r.room < roomLast - 1.0e-6) mono = false;
			roomLast = r.room; noneLast = r.noneFrac;
		}
		// ── 📊 변화만(몸통의 채점과 같게) ────────────────────────
		LogA("[mlt] 🧭   ── 📊 **변화만**(나중 ≠ 지금 · 몸통의 채점과 같다) ──\n");
		LogA("[mlt] 🧭      k    ㉡ H(·|방향)  ㉢ H(·|방향,위치)  ⭐ 여지    여지÷㉡\n");
		double roomChg1 = 0.0, roomChgLast = 0.0;
		for (uint32 ki = 0; ki < kKs; ++ki)
		{
			KRes r; _KStat(ki, 1u, true, r);
			LogA("[mlt] 🧭     %2u     %.4f         %.4f        **%.4f**   %5.1f%%\n",
				kKOf[ki], r.hcD, r.hcDP, r.room,
				(r.hcD > 1.0e-9) ? 100.0 * r.room / r.hcD : 0.0);
			if (ki == 0u) roomChg1 = r.room;
			roomChgLast = r.room;
		}
		// ── ⚠️ 굵기 팔 — **편향 관문** ───────────────────────────
		LogA("[mlt] 🧭   ── ⚠️ **편향 관문** — 굵기를 올릴수록 여지가 **줄어야** 정상이다 ──\n");
		LogA("[mlt] 🧭      굵기    찬 칸    칸당 표본     k=1 여지    k=8 여지\n");
		for (uint32 gi = 0; gi < kGs; ++gi)
		{
			KRes r1, r8; _KStat(0u, gi, false, r1); _KStat(kKs - 1u, gi, false, r8);
			LogA("[mlt] 🧭      %ux%u   %6u   %8.0f     %.4f      **%.4f**%s\n",
				kGOf[gi], kGOf[gi], r8.cellsUsed, r8.perCell, r1.room, r8.room,
				(gi == 1u) ? "   ← 표의 기준" : "");
			if (gi > 0u)
			{
				KRes rp; _KStat(kKs - 1u, gi - 1u, false, rp);
				if (r8.room > rp.room + 0.02) biasOk = false;
			}
		}
		// ── 🚪 관문 ─────────────────────────────────────────────
		LogA("[mlt] 🧭   ── 🚪 관문 ──\n");
		LogA("[mlt] 🧭     ① 배관 — `k=1` 의 ㉡ **%.4f** ↔ 182 의 **0.3181**(0.30~0.34) → %s\n",
			hcD1, (hcD1 > 0.30 && hcD1 < 0.34) ? "✅ **재현**" : "⚠️ **다르다** — ★ 조건·표본을 다시 본다");
		LogA("[mlt] 🧭     ⭐ ② 배관 — `k=1` 변화만 여지 **%.4f** ↔ 193 의 **0.055**(0.03~0.09) → %s\n",
			roomChg1, (roomChg1 > 0.03 && roomChg1 < 0.09)
				? "✅✅ ⭐ **두 길이 만났다**(규율 68) — 이 새 자가 확인된다"
				: "⚠️ **안 만난다** — ★ 그러면 두 자가 다른 것을 잰다(적어 둔다)");
		LogA("[mlt] 🧭     ⭐ ③ **표제** — 여지가 k 와 함께 커지고 `k=8` 에서 ≥ 0.20 나트\n");
		LogA("[mlt] 🧭        단조 %s · `k=8` 여지 **%.4f**(전체) · **%.4f**(변화만) → %s\n",
			mono ? "✅" : "⛔", roomLast, roomChgLast,
			(mono && roomLast >= 0.20)
				? "✅✅ ⭐ ***표적을 옮길 값이 있다***"
				: "⛔ **표적 축으로도 안 열린다** ⇒ ★ 갈래 ①(인정)로 돌아간다");
		LogA("[mlt] 🧭        ⓘ `k=1` 여지 **%.4f** → `k=8` **%.4f** = **%.1f배**\n",
			room1, roomLast, (room1 > 1.0e-9) ? roomLast / room1 : 0.0);
		LogA("[mlt] 🧭     ⭐ ④ **편향** — 굵기를 올려도 여지가 안 커지나 → %s\n",
			biasOk ? "✅ **여지가 진짜다**" : "⛔ **편향이다** — ★ 여지 값을 믿지 않는다(굵기를 더 굵게)");
		LogA("[mlt] 🧭     ⚠️ ⑤ 「없음」 — `k=8` 의 「없음」 몫 **%.1f%%**(< 60%%) → %s\n",
			100.0 * noneLast,
			(noneLast < 0.60) ? "✅" : "⛔ **표적이 *\"화면에 있나\"* 로 변질된다**(규율 78)");
		LogA("[mlt] 🧭 ══════════════════════════════════════════════\n");
	}

	static void _Gather(uint32 ptIx, int autoN, Acc& a)
	{
		const Pt pt = _Pt(ptIx);
		a.Begin();
		uint32 chgTot = 0u, tgtTot = 0u, ctxTot = 0u;
		for (uint32 s = 0; s < kSeeds; ++s)
			for (uint32 c = 0; c < kCtx; ++c)
			{
				MLTWorld w;
				w.Reset(s, kEpi + c, pt.hold, autoN, pt.dt, pt.amp);
				// 물체별 직전 칸 — ⭐ `index` 가 identity 라 **추적이 공짜다**(그것이 ㉲ 의 값이다)
				uint32 prev[kShapes];
				for (int i = 0; i < kShapes; ++i) prev[i] = _None();
				bool have[kShapes];
				for (int i = 0; i < kShapes; ++i) have[i] = false;
				// ⭐ 회차 182 — 방향 모드는 **직전 화면 위치**가 필요하다
				float ppx[kShapes], ppy[kShapes];
				bool  ppv[kShapes];
				for (int i = 0; i < kShapes; ++i) ppv[i] = false;
				for (uint32 t = 0; t < kTime; ++t)
				{
					MLTShapeView vs[kShapes];
					const int nv = w.VisibleShapes(vs, kShapes);
					if (t == 0u)
					{
						a.visSum += (double)nv; ++a.visN;
						if (nv < a.visMin) a.visMin = nv;
						if (nv > a.visMax) a.visMax = nv;
						for (int i = 0; i < nv; ++i)
						{
							if (vs[i].index < autoN) ++a.autoSeen; else ++a.passSeen;
						}
					}
					// 지금 칸을 물체 번호로 흩는다
					uint32 cur[kShapes];
					for (int i = 0; i < kShapes; ++i) cur[i] = _None();
					for (int i = 0; i < nv; ++i)
					{
						const int ix = vs[i].index;
						if (ix < 0 || ix >= kShapes) continue;
						// ⭐ 회차 182 — 방향 모드면 계급이 **이동 방향**이다
						cur[ix] = _dirOn ? _DirCls(vs[i], ppx[ix], ppy[ix], ppv[ix]) : _Cell(vs[i]);
						ppx[ix] = vs[i].sx; ppy[ix] = vs[i].sy; ppv[ix] = true;
					}
					for (int i = 0; i < kShapes; ++i)
					{
						// ⚠️ 표적은 **직전이 있는 물체**에만 있다(첫 시각은 표적이 아니다)
						if (have[i])
						{
							++tgtTot;
							if (cur[i] != prev[i]) ++chgTot;
							a.jt.Data()[prev[i] * _cls + cur[i]] += 1u;
							++a.tot;
						}
						prev[i] = cur[i];
						have[i] = true;
					}
					w.Step();
				}
				++ctxTot;
			}
		a.chgSum = (ctxTot == 0u) ? 0.0 : (double)chgTot / (double)ctxTot;
		a.tgtSum = (ctxTot == 0u) ? 0.0 : (double)tgtTot / (double)ctxTot;
	}


	// ── ⭐ 회차 180 — **한 점 한 눈금의 결과** ──────────────────────
	struct Row
	{
		uint32 pt = 0u, px = 0u;
		double vis = 0.0, tgt = 0.0, chg = 0.0, h = 0.0, hc = 0.0;
		double hcChg = 0.0;                 // ⭐ 회차 181 의 배관 문턱 — **변화만**
		uint32 aSeen = 0u, pSeen = 0u;
		bool g1 = false, g2 = false, g3 = false, g4 = false;
		uint32 pass = 0u;
		// ⭐ 회차 182 — 방향 모드의 것
		double still = 0.0;      // 「정지」계급 비중
		bool g3b = false;        // `H(방향|직전) < 1.5` — 관성이 있나
	};

	// ── ⭐ 회차 182 — 「정지」계급(0) 의 비중 ────────────────────────
	static double _StillFrac(const Acc& a)
	{
		if (a.tot == 0u) return 0.0;
		uint32 n0 = 0u;
		for (uint32 p = 0; p < _cls; ++p) n0 += a.jt[p * _cls + 0u];
		return (double)n0 / (double)a.tot;
	}

	static Row _One(uint32 ptIx, uint32 px, double sensorChg)
	{
		if (_dirOn) _SetDir(true, _dirThr); else _SetPx(px);
		Acc a;
		_Gather(ptIx, MLTWorldCfg::kAutoMany, a);
		Row r;
		r.pt = ptIx; r.px = px;
		r.vis = (a.visN == 0u) ? 0.0 : a.visSum / (double)a.visN;
		r.tgt = a.tgtSum; r.chg = a.chgSum;
		r.aSeen = a.autoSeen; r.pSeen = a.passSeen;
		_Ent(a, r.h, r.hc);
		_EntChg(a, r.hcChg);
		r.g4 = (r.aSeen > 0u && r.pSeen > 0u);
		if (_dirOn)
		{
			// ⭐ 회차 182 — 관문을 **다시 정의한다**(표적이 바뀌었으니)
			//   ① 「변화 표적 수」가 아니라 **정지 비중** — 방향 표적은 모든 슬롯이 표적이다
			//   ③b **상한**도 본다: `H(방향|직전)` 이 `ln8 = 2.079` 에 가까우면 **관성이 없다** = 잡음
			r.still = _StillFrac(a);
			r.g1 = (r.still < 0.70);
			// ⚠️⚠️ **자를 고쳤다**(같은 회차 안 · 1차 실행이 그것을 밝혔다) —
			//   1차는 정지 세계의 **`H(방향)`**(무조건부)로 걸었고 **0.5292** 가 나와 ⛔ 였다.
			//   ★ 그런데 그 값의 대부분이 ***「없음」계급(52.5%)과 「정지」(22.2%)의 구분***에서 온다
			//     — 물체가 **화면에 있나 없나**는 센서 잡음이 아니라 **세계의 사실**이다.
			//   ⇒ ★ 같은 줄의 **`H(방향|직전)` 은 0.0005** 였다 ⇒ ***센서 몫은 실제로 0 이다.***
			//   ⇒ ⭐ 그래서 ② 를 **조건부**로 잰다 — 그것이 「직전을 알면 잡음이 남나」다.
			r.g2 = (sensorChg < 0.05);       // ⚠️ 정지 세계의 **`H(방향|직전)`** 로 잰다
			r.g3 = (r.hc > 0.3);
			r.g3b = (r.hc < 1.5);
			r.pass = (r.g1 ? 1u : 0u) + (r.g2 ? 1u : 0u) + ((r.g3 && r.g3b) ? 1u : 0u) + (r.g4 ? 1u : 0u);
			return r;
		}
		r.g1 = (r.chg < 12.0);
		r.g2 = (sensorChg < 1.0);        // ⚠️ 센서 몫은 **점 ㈆(고정 대조)** 로 잰다
		r.g3 = (r.hc > 0.3);
		r.pass = (r.g1 ? 1u : 0u) + (r.g2 ? 1u : 0u) + (r.g3 ? 1u : 0u) + (r.g4 ? 1u : 0u);
		return r;
	}

	// ══════════════════════════════════════════════════════════════
	// 🧭 회차 182 — **방향 모드 스윕**(세계 8점 × 정지 문턱 둘)
	// ══════════════════════════════════════════════════════════════
	static void _RunDir()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🧭 **회차 182 · ㉳ 의 세계 서명 — 표적을 「이동 방향」으로**\n");
		LogA("[mlt] 🧭    ⚠️ 처방이 아니다(규율 21·77) — **12초**에 재서 기각할 수 있으면 기각한다\n");
		LogA("[mlt] 🧭    ⭐ 회차 181 의 벽 = *\"칸 번호가 불투명 정수라 「37 과 38 이 인접」임을 모른다\"*\n");
		LogA("[mlt] 🧭       ⇒ ★ 표적을 「다음 **칸**」에서 「**이동 방향**」으로 ⇒ 그 벽이 **원리적으로** 사라진다\n");
		LogA("[mlt] 🧭    📐 계급 **%u**(0 = 정지 · 1..8 = 8방위 · 9 = 없음) ⇒ 어휘 257 → **9**\n", kDirCls);
		LogA("[mlt] 🧭    ⚠️⚠️ **규율 76** — 표적을 바꿨으니 **세계도 다시 고른다**(문턱이 이 모드의 눈금이다)\n");

		Row rows[kPts * 2u];
		uint32 n = 0u;
		for (uint32 k = 0; k < 2u; ++k)
		{
			const float thr = (k == 0u) ? 0.25f : 1.00f;
			_SetDir(true, thr);
			// ② 센서 몫의 고정 대조 = 점 ㈆(완전 정지)에서의 `H(방향)`
			Acc st;
			_Gather(6u, MLTWorldCfg::kAutoMany, st);
			double hSt = 0.0, hcSt = 0.0;
			_Ent(st, hSt, hcSt);
			LogA("[mlt] 🧭   ── 정지 문턱 **%.2f 픽셀** ──\n", (double)thr);
			LogA("[mlt] 🧭     ② 센서 몫(점 ㈆ 완전 정지) — ⭐ **`H(방향|직전)` = %.4f** 나트 → %s\n",
				hcSt, (hcSt < 0.05) ? "✅✅ ⭐ **직전을 알면 잡음이 0 이다**" : "⛔ **정지 세계인데 방향이 생긴다**");
			LogA("[mlt] 🧭        ⓘ 무조건부 `H(방향)` = %.4f · 정지 비중 %.1f%% · 보임 %.2f/%d\n",
				hSt, 100.0 * _StillFrac(st), (st.visN == 0u) ? 0.0 : st.visSum / (double)st.visN, kShapes);
			LogA("[mlt] 🧭        ⚠️ 무조건부로 걸면 안 된다 — 그 값의 대부분이 **「없음」계급**(화면 밖)에서 온다\n");
			LogA("[mlt] 🧭     점            dt    amp   보임   정지비중   H(방향)  H(방향|직전)  관문\n");
			for (uint32 p = 0; p < kPts; ++p)
			{
				_SetDir(true, thr);
				rows[n] = _One(p, 0u, hcSt);   // ⭐ 조건부로 넘긴다(자를 고친 그 자리)
				const Pt pt = _Pt(p);
				LogA("[mlt] 🧭     %-12s %5.3f %5.2f  %5.2f   %6.1f%%   %7.4f  %10.4f   **%u/4** %s%s%s%s%s\n",
					_PtName(p), (double)pt.dt, (double)pt.amp, rows[n].vis, 100.0 * rows[n].still,
					rows[n].h, rows[n].hc, rows[n].pass,
					rows[n].g1 ? "①" : "·", rows[n].g2 ? "②" : "·",
					rows[n].g3 ? "③" : "·", rows[n].g3b ? "b" : "·", rows[n].g4 ? "④" : "·");
				++n;
			}
		}
		// ── 판정 ────────────────────────────────────────────────
		uint32 best = 0u; uint32 bestPass = 0u; double bestHc = -1.0;
		uint32 four = 0u;
		for (uint32 i = 0; i < n; ++i)
		{
			if (rows[i].pass == 4u) ++four;
			if (rows[i].pass > bestPass || (rows[i].pass == bestPass && rows[i].hc > bestHc))
			{ best = i; bestPass = rows[i].pass; bestHc = rows[i].hc; }
		}
		LogA("[mlt] 🧭   ── 판정 ──\n");
		LogA("[mlt] 🧭     **4/4 를 낸 점 = %u개** · 가장 좋은 점 = **%s**(%u/4 · 정지 %.1f%% · `H(방향|직전)` %.4f)\n",
			four, _PtName(rows[best].pt), rows[best].pass, 100.0 * rows[best].still, rows[best].hc);
		LogA("[mlt] 🧭     ⚠️⚠️ **①과 ③ 이 서로 당긴다** — 문턱이 크면 정지가 많고, 작으면 방향이 **잡음**이 된다\n");
		LogA("[mlt] 🧭        ⇒ ★ 그래서 ③ 에 **상한**(③b `H(방향|직전) < 1.5`)도 본다 —\n");
		LogA("[mlt] 🧭          `ln 8 = %.4f` 에 가까우면 **직전 방향이 아무것도 안 말한다** = 관성이 없다\n",
			(double)Log(8.0f));
		if (four > 0u)
			LogA("[mlt] 🧭     ⭐ 판정 = ⭐ ***㉳ 가 설 자리가 있다*** — 넷을 다 넘는 점이 **%u개**\n"
			     "[mlt] 🧭        ⇒ ★ 다음은 **그 점에서 몸통을 돌린다**(`mltl1t0` 의 표적 생성만 갈아 끼운다)\n", four);
		else if (bestPass == 3u && !rows[best].g3b)
			LogA("[mlt] 🧭     ⭐ 판정 = ⛔⛔ ***관성이 없다*** — `H(방향|직전)` 이 상한에 붙었다\n"
			     "[mlt] 🧭        ⇒ ★ 방향만으로는 표적이 **잡음**이다 ⇒ ⭐ 처방 = **「방향 + 속력 계급」** 또는\n"
			     "[mlt] 🧭          **직전 방향을 심볼로 주기**(그러면 몸통이 관성을 쓸 수 있다)\n");
		else if (bestPass == 3u && !rows[best].g1)
			LogA("[mlt] 🧭     ⭐ 판정 = ⛔ **정지 비중이 너무 높다** ⇒ ★ 문턱을 더 내리거나 `dt` 큰 세계로\n");
		else
			LogA("[mlt] 🧭     ⭐ 판정 = ⛔ **㉳ 의 전제가 안 선다** — 위 표의 ⛔ 가 그 이유다\n");
		LogA("[mlt] 🧭   ⚠️ 계급이 257 → %u 라 `H`·CE 절대값을 회차 181 과 견주지 않는다(규율 58)\n", kDirCls);
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

	static void _Run()
	{
		if (OS::CommandLine::Has("-mltdir")) { _RunDir(); return; }
		const bool all = OS::CommandLine::Has("-mltptall");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		if (!all)
		{
			LogA("[mlt] 🔬 **회차 179 · ㉲ 의 세계 서명**(⚠️ 처방이 아니다 — 규율 21)\n");
			LogA("[mlt]    ⚠️ 스윕(회차 180)은 **꺼져 있다** — `-mltptall` 로 켠다\n");
		}
		else
			LogA("[mlt] 🗺️ **회차 180 · ㉲ 가 서는 세계를 찾는다**(세계 %u점 × 눈금 둘)\n", kPts);
		LogA("[mlt]    ⚙️ 세계만 돈다 — 인코더도 몸통도 없다 · 씨앗 %u × 문맥 %u × 시각 %u\n",
			kSeeds, kCtx, kTime);
		LogA("[mlt]    📐 표적 = 「그 물체가 **다음 시각에 어느 칸**에 있나」 · 슬롯 = **물체 하나**\n");
		LogA("[mlt]    ⭐ `MLTShapeView::index` 가 **identity** 라 추적이 **공짜다** — 그것이 ㉲ 의 값이다\n");

		// ── ② 센서 몫의 **고정 대조** = 점 ㈆(완전 정지) ────────────────
		//   ⚠️ 회차 179 는 그 점을 「정지 세계」로 따로 돌렸다 ⇒ 스윕에서도 **같은 자**를 쓴다.
		_SetPx(MLTP2Cfg::kPatch);
		Acc st;
		_Gather(6u, MLTWorldCfg::kAutoMany, st);
		LogA("[mlt] 🔬   ── ② ⭐ **센서 몫**(고정 대조 = 점 ㈆ 완전 정지 · 눈금 8) ──\n");
		LogA("[mlt] 🔬     전체 표적 **%.1f**/문맥 · **변화 %.2f**/문맥(**%.2f%%**)\n",
			st.tgtSum, st.chgSum,
			(st.tgtSum > 1.0e-9) ? 100.0 * st.chgSum / st.tgtSum : 0.0);
		LogA("[mlt] 🔬     🚪 **관문 ②**(< 1/문맥 · 지금 표현은 **8.9**) → %s\n",
			(st.chgSum < 1.0)
				? "✅✅ ⭐ **회차 165 의 42%% 부산물이 사라진다** — 정체성이 지속되니까"
				: "⛔⛔ **정지 세계인데도 표적이 있다** — 정체성만으로는 안 지워진다");

		if (!all)
		{
			// 회차 179 의 한 점(㈇)만 — 옛 결과를 그대로 재현한다
			const Row r = _One(7u, MLTP2Cfg::kPatch, st.chgSum);
			_Line(r, true);
			_Verdict(&r, 1u);
			LogA("[mlt] ══════════════════════════════════════════════════\n");
			return;
		}

		Row rows[kPts * 2u];
		uint32 n = 0u;
		for (uint32 k = 0; k < 2u; ++k)
		{
			const uint32 px = (k == 0u) ? MLTP2Cfg::kPatch : kPxMin;   // 8 → 4
			LogA("[mlt] 🗺️   ── 눈금 **%u 픽셀**(칸 %u) ──\n", px, ((uint32)MLTWorldCfg::kSide / px) * ((uint32)MLTWorldCfg::kSide / px));
			LogA("[mlt] 🗺️     점            dt    amp   보임   표적    변화   H(다음)  H(다음|지금)  ⭐H|지금,변화만  관문\n");
			for (uint32 p = 0; p < kPts; ++p)
			{
				rows[n] = _One(p, px, st.chgSum);
				_Line(rows[n], false);
				++n;
			}
		}
		_Verdict(rows, n);
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

	static void _Line(const Row& r, bool solo)
	{
		if (solo)
		{
			LogA("[mlt] 🔬   ── 점 %s · 눈금 %u 픽셀 ──\n", _PtName(r.pt), r.px);
			LogA("[mlt] 🔬     ① 보임 **%.2f**/%d ⇒ 표적 상한 **%.1f**/문맥(지금 표현 56.0)\n",
				r.vis, kShapes, r.vis * (double)(kTime - 1u));
			LogA("[mlt] 🔬     ② 전체 표적 **%.1f**/문맥 · **변화 %.1f**(%.1f%%) → 관문① %s\n",
				r.tgt, r.chg, (r.tgt > 1.0e-9) ? 100.0 * r.chg / r.tgt : 0.0, r.g1 ? "✅" : "⛔");
			LogA("[mlt] 🔬     ④ 자율 **%u** · 피동 **%u** → 관문④ %s\n", r.aSeen, r.pSeen, r.g4 ? "✅" : "⛔");
			LogA("[mlt] 🔬     ⑤ `H(다음)` **%.4f** · `H(다음|지금)` **%.4f** → 관문③ %s\n",
				r.h, r.hc, r.g3 ? "✅" : "⛔ **표적이 너무 쉽다**");
			LogA("[mlt] 🔬     ⑤b ⭐ **`H(다음|지금)` 변화만** = **%.4f** ← ★ **회차 181 의 배관 문턱**\n", r.hcChg);
			return;
		}
		const Pt pt = _Pt(r.pt);
		LogA("[mlt] 🗺️     %-12s %5.3f %5.2f  %5.2f %6.1f %6.1f  %7.4f  %10.4f  %10.4f   **%u/4** %s%s%s%s\n",
			_PtName(r.pt), (double)pt.dt, (double)pt.amp, r.vis, r.tgt, r.chg, r.h, r.hc, r.hcChg,
			r.pass, r.g1 ? "①" : "·", r.g2 ? "②" : "·", r.g3 ? "③" : "·", r.g4 ? "④" : "·");
	}

	static void _Verdict(const Row* rows, uint32 n)
	{
		uint32 best = 0u; double bestHc = -1.0; uint32 bestPass = 0u;
		for (uint32 i = 0; i < n; ++i)
		{
			if (rows[i].pass > bestPass || (rows[i].pass == bestPass && rows[i].hc > bestHc))
			{ best = i; bestPass = rows[i].pass; bestHc = rows[i].hc; }
		}
		uint32 four = 0u;
		for (uint32 i = 0; i < n; ++i) if (rows[i].pass == 4u) ++four;
		LogA("[mlt] 🔬   ── 판정 ──\n");
		LogA("[mlt] 🔬     **4/4 를 낸 점 = %u개** · 가장 좋은 점 = **%s · 눈금 %u** (%u/4 · `H(다음|지금)` %.4f)\n",
			four, _PtName(rows[best].pt), rows[best].px, rows[best].pass, rows[best].hc);
		if (four > 0u)
			LogA("[mlt] 🔬     ⭐ 판정 = ⭐ ***㉲ 가 설 자리가 있다*** — 넷을 다 넘는 점이 **%u개**\n"
			     "[mlt] 🔬        ⇒ ★ 다음은 **그 점에서 표적을 바꾸고 몸통을 돌린다**(회차 1~178 의 자를 새로 세운다)\n", four);
		else if (bestPass == 3u && rows[best].g3)
			LogA("[mlt] 🔬     ⭐ 판정 = 🔶 **③(배울 것)은 섰는데 다른 하나가 깨졌다** — ①③ 이 서로 당긴다\n"
			     "[mlt] 🔬        ⇒ ★ 관문 ① 의 문턱(12/문맥)이 **㉲ 에 맞나**를 다시 봐야 한다(자를 옛 표현에서 가져왔다)\n");
		else if (bestPass == 3u)
			LogA("[mlt] 🔬     ⭐ 판정 = ⛔⛔ ***어느 점에서도 ③ 이 안 선다*** — 「칸」은 표적으로 못 쓴다\n"
			     "[mlt] 🔬        ⇒ ★ 표적을 **「이동 방향 8분위」**로 바꾼다 ⇒ 그것이 다음 회차다\n");
		else
			LogA("[mlt] 🔬     ⭐ 판정 = ⛔ **㉲ 의 전제가 안 선다** — 위 표의 ⛔ 가 그 이유다\n");
		LogA("[mlt] 🔬   ⚠️ 계급이 250 → %u 로 준다 ⇒ `H`·CE 절대값을 1~178 과 견주지 않는다(규율 58)\n", _cls);
		LogA("[mlt] 🔬   ⚠️ 관문 ①③ 은 **서로 반대로 당긴다** — 변화가 적으면 ① 이 쉽고 ③ 이 어렵다\n");
	}
};
