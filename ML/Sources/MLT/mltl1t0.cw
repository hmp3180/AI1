// mltl1t0.cw — 🧿 회차 181 · **㉲ 로 몸통을 돌린다** (`-mlt -mltl1t0`)
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 181 다.** ⭐ **하네스보다 먼저 썼다.**
//   **상위 캔버스: `물체를 센서가 나르면 무엇이 달라지나` · 179·180·181 = 3회차**
//
// ── ⚙️ ㉲ = 센서가 「물체 정체성 + 위치」를 구조로 나른다 ────────────────
//   ⭐ **인코더가 사라진다** — 코드북이 없으므로 `MLTP2Enc` 도 `MLTP3Ctx` 도 안 쓴다.
//     ★ 세계에서 **바로** 풀 배열(`_eVal`/`_eSym`/`_eTgt`)을 만든다 ⇒ 리드백 대기가 없다.
//   ⚠️ `MLTShapeView` 는 *"판정자 전용"* 등록이지만, ㉲ 는 **그것을 센서로 승격하는 것**이
//     설계 자체다(회차 179·180 이 그 전제를 재서 4/4 를 냈다) ⇒ 규율 73 을 훑고 들어간다.
//   ★ 근거 = `mltconcept.md` 「원시성은 **사고**에 요구하는 것이고 **센서**에 요구하는 것이
//     아니다」 + 「**구조는 주어지고 어휘는 학습으로**」.
//
// ── 📐 대응표 — (심볼, 값) 슬롯 구조가 그대로 맞는다 ──────────────────
//   어휘 250(코드북) → **257**(칸 256 + 「없음」)   ·   kSymA 256 → **263**
//   슬롯 8(코드 후보) → **8(물체)**                 ·   축 14 그대로
//   심볼 = `kStateAx + `**지금 칸**                 ·   표적 = 그 물체의 **다음 칸**
//   값   = **깊이 `d`** 정규화(「얼마나 가까운가」)
//
// ── ⭐ 슬롯 배치 — identity 가 슬롯을 고정한다(㉲ 의 핵심 이득) ──
//   보이는 물체 중 **번호(index) 작은 8개**를 슬롯 0..7 에.
//   ⇒ ★ 회차 51 의 그 대가(*"슬롯 복사 0.642 ↔ 집합 복사 0.882 · 차 0.240 = 우리가 만든 잡음"*)와
//     회차 167 의 **배치 짝짓기**가 ***원리적으로 필요 없어진다*** — 물체 번호가 안 바뀌니까.
//   ⚠️ 남는 밀림 하나: 물체가 화면에 **들락날락하면** 번호 순서가 밀린다
//     ⇒ ★ 그것이 ㉲ 의 잔여 잡음이고 **회차 179 가 잰 0.02%** 가 그 크기다.
//
// ── 🎛️ 낱말 넷(+섞음 넷 = 팔 8) ────────────────────────────────────
//   ⭐ ㈀ **오라클**   「첫 바뀌는 슬롯의 **다음 칸**」 8분위        거리 **0**
//   ㈂ `maxV`        화면 요약(회차 162 그대로)                    멀다(눈금)
//   ⭐ ㈄ **어디로** 「**자율 도형의 이동 방향**」 8분위      ⭐ 거리 **0 에 가깝다** ← **표제**
//   ⭐ ㈆ **어느 물체** 「바뀐 물체 중 가장 작은 슬롯 번호」+1      중간
//
// ── 🚪 관문 ──────────────────────────────────────────────────────
//   ⭐ 배관① **목표선** = **0.3678 ± 0.03** ← 회차 180 이 **다른 길**로 잰 값(규율 68)
//   ⭐   배관② 변화 표적 **10.3 ± 1**/문맥
//   ⭐ `P3`   **몸통 CE < 목표선** ⇒ ★ **칸 1 닫힘 조건 ㉠ 을 이 표현에서 처음 만족**
//   ⭐ 표제 ㈄ 가 자기 바닥을 이기나(`t ≥ 3` · `win ≥ 9/12`)
//   ⭐ 활용률 ㈄ 가 **> 0.8**(거리 0 이면 오라클급 1.3~1.6 이어야 한다)
//
// ── 🔮 예측(재기 전에 적었다) ────────────────────────────────────
//   ⭐ ㉠ 배관① ✅(0.35~0.39)
//   ⚠️⚠️ ㉡ **`P3` 가 위험하다** — 목표선 0.3678 은 사전 1.5987 의 **23%** 라 매우 낮다
//     ⇒ 🔶 도달률 **0~40%** 로 본다
//   ⭐ ㉢ ㈄ 활용률 **0.9~1.6** ✅(규율 72)
//   ⭐ ㉣ ㈄ 표제 **통과**(`t` 3~7) ⇒ ★ **칸 10 이 처음 열린다**
//   ⭐ ㉤ ㈆ < ㈄ (거리가 더 멀다)
//   ⚠️ ㉥ `maxV` 는 여전히 바닥(활용률 < 0.2) ⇒ ★ **규율 72 의 눈금이 유지된다는 검산**
//   ⚠️⚠️ ㉦ **새 위험** — 표적의 **77% 가 지속**(변화 10.3 / 전체 45.5) ⇒ 회차 161 이 델타판에서
//     푼 그 문제가 **다시 올 수 있다**(학습 손실이 지속에 쏠린다)
// ══════════════════════════════════════════════════════════════════════════════

using namespace PE;

class MLTL1T0
{
public:
	static void Tick(RHI* rhi)
	{
		if (_done || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltl1t0"))
		{
			LogA("[mlt] 🧿 회차 181(㉲ 로 몸통을 돌린다)는 **꺼져 있다**(`-mltl1t0`)\n");
			_done = true; return;
		}
		if (!_banner)
		{
			// ⭐⭐ 회차 234 — 기본은 **`kSeedsDef`(12)** 다(`kSeedsMax` 가 아니다).
			//   ⚠️⚠️ 상한을 24 로 올리면서 기본까지 따라 오르면 **회차 1~233 의 재현이 통째로 달라진다**
			//     ⇒ ★ 상한(배열 크기)과 기본(그 회차가 사는 자리)을 **갈라 둔다**(규율 58).
			_seeds = OS::CommandLine::Has("-mltdiag1") ? 1u : kSeedsDef;
			// ⭐ **씨앗 수 손잡이**(`-mltseeds <n>`) — ★ 다른 클론 세션의 지적:
			//   *"예산은 **그 자리의** `σ_diff` 다"* ⇒ 179 등록문의 `t 5.7` 은 **178 자리의 SE** 로
			//   계산한 것이고, 점 ㈄ 는 **새 세계·새 표적·새 눈금**이라 `σ_diff` 가 다르다.
			//   ⇒ ★ 12씨앗(26분) 전에 **3씨앗(6.5분)으로 그 자리의 SE 를 먼저 잰다.**
			//   ⚠️ 1씨앗은 SE 가 0 이라 그것을 못 준다(규율 74 와 짝).
			//   ⛔⛔ **234 가 함정을 잡았다 — 이 파서는 `sv[0]` **한 자리**만 읽었다.**
			//     ⇒ `-mltseeds 24` 가 조용히 **2** 가 된다(에러도 경고도 없다) ⇒ 규율 19 의 그 모양.
			//     ⇒ ★ 여러 자리로 고쳤고 **읽은 값을 배너에 찍는다**(그것이 이 함정의 관문이다).
			{
				const char* sv = OS::CommandLine::ValueOf("-mltseeds", "");
				uint32 v = 0u; bool any = false;
				if (sv != nullptr)
					for (const char* p = sv; *p >= (char)48 && *p <= (char)57; ++p)
					{ v = v * 10u + (uint32)(*p - (char)48); any = true; if (v > 9999u) break; }
				if (any && v >= 1u && v <= kSeedsMax) _seeds = v;
				else if (any)
					LogA("[mlt] 🔒 ⛔ `-mltseeds %s` 가 범위 밖이다(1~%u) — **무시하고 기본 %u 로 간다**\n",
						sv, kSeedsMax, _seeds);
			}
			// ⚖️✂️ 회차 240 — **세계가 좁히는 판**(238·239 의 캔버스를 학습으로)
			//   `-mltenergy` = 에너지(감쇠) · `-mltprunebud <n>` = 가지치기 예산 n/100(예: 30 ⇒ 0.30)
			//   ⚠️ 예산을 주면 에너지도 **자동으로 켠다**(예산이 `_e` 인데 에너지가 안 굴러가면 뜻이 없다)
			_enOn = OS::CommandLine::Has("-mltenergy");
			{
				const char* pb = OS::CommandLine::ValueOf("-mltprunebud", "");
				uint32 v = 0u; bool any = false;
				if (pb != nullptr)
					for (const char* p = pb; *p >= (char)48 && *p <= (char)57; ++p)
					{ v = v * 10u + (uint32)(*p - (char)48); any = true; if (v > 999u) break; }
				// ⚠️ 하한 15 — 239 가 적었다: 그 아래면 **회전도 잘려 정지 세계**가 된다(규율 88)
				if (any && v >= 15u && v <= 300u) { _prBud = (float)v * 0.01f; _enOn = true; }
				else if (any)
					LogA("[mlt] 🔒 ⛔ `-mltprunebud %s` 가 범위 밖이다(15~300) — **안 켠다**\n", pb);
			}
			// ⭐⭐ 회차 243 — `-mltslow <n>` = 감쇠 세기 n/100(예: 15 ⇒ 0.15). `-mltprunebud` 와 같은 관용구.
			//   ⚠️ 예산과 같은 이유로 **에너지도 자동으로 켠다**(감쇠는 에너지가 굴러야 발동한다).
			//   ⚠️ 상한 100 = **감쇠 없음**(에너지만 굴러간다) ⇒ 그 위는 뜻이 없다.
			{
				const char* sw = OS::CommandLine::ValueOf("-mltslow", "");
				uint32 v = 0u; bool any = false;
				if (sw != nullptr)
					for (const char* p = sw; *p >= (char)48 && *p <= (char)57; ++p)
					{ v = v * 10u + (uint32)(*p - (char)48); any = true; if (v > 999u) break; }
				if (any && v >= 1u && v <= 100u) { _slow = (float)v * 0.01f; _enOn = true; }
				else if (any)
					LogA("[mlt] 🔒 ⛔ `-mltslow %s` 가 범위 밖이다(1~100) — **기본 감쇠로 간다**\n", sw);
			}
			// ⭐ 회차 236 — **어휘 뭉개기**(`-mltlvoc <n>` = 이름 8 을 n 그룹으로) — 위 `_VocFold`
			//   ⚠️ 파서는 **여러 자리**로 읽는다(234 가 한 자리 파서에 속았다)
			{
				const char* lv = OS::CommandLine::ValueOf("-mltlvoc", "");
				uint32 v = 0u; bool any = false;
				if (lv != nullptr)
					for (const char* p = lv; *p >= (char)48 && *p <= (char)57; ++p)
					{ v = v * 10u + (uint32)(*p - (char)48); any = true; if (v > 999u) break; }
				if (any && v >= 1u && v + 1u < kLVocab) _lvoc = v;
				else if (any)
					LogA("[mlt] 🔒 ⛔ `-mltlvoc %s` 가 범위 밖이다(1~%u) — **안 뭉친다**\n", lv, kLVocab - 2u);
			}
			// ⭐ 회차 183 — **방향 모드**. ⚠️ 배너보다 **먼저** 켠다(배너가 `_N()` 을 찍는다)
			_dirOn = OS::CommandLine::Has("-mltdir");
			// ⭐ 회차 185 — 학습 풀에도 변화 마스크(㉷ · 회차 144 의 그 손잡이)
			_qChg = OS::CommandLine::Has("-mltqchg");
			// ⭐ 회차 189 — 슬롯마다 낱말(㉸)
			_slotWord = OS::CommandLine::Has("-mltslotword");
			// ⚠️⚠️⚠️ **`_nw` 를 여기서 확정한다** — 회차 189 에서 실측으로 밟았다:
			//   ⛔ `_MakeArmPools` 에서만 정하면 **수집(`_Gather`)이 `_nw = 1` 로 배치**하고
			//     `_Expand`/`Setup` 은 8 로 읽어 ***레이아웃이 어긋난다*** ⇒ 증상은
			//     `③ 스텝 171 의 유효 행이 0 이다`(엉뚱한 자리를 표적으로 읽는다).
			//   ★ 모드마다 하나이므로 **팔보다 먼저** 정하는 것이 맞다.
			// ⚠️⚠️⚠️ **회차 200 이 같은 함정을 또 밟았다** — `_lang` 을 아래에서 파싱했더니
			//   이 줄이 그것을 모르고 `_nw = 1` 을 박아 ⛔ **학습 풀 업로드 실패**가 났다.
			//   ⇒ ★ 처방은 하나다: ***모드 플래그 전부를 이 줄보다 먼저 읽고, 축 수는
			//     `_NwOf` 한 곳에서만 계산한다*** (같은 사실이 두 곳에 살면 한쪽이 진다).
			_capOn = OS::CommandLine::Has("-mltcap");   // 225 — 용량 스윕(언어를 켠다)
			_lang = OS::CommandLine::Has("-mltlang") || _capOn;   // 회차 200 — 언어 모드(칸 2 ㈀)
			// ⭐ 회차 212 — 🆕 **L2 모드**(칸 2 조건 ㈂) · ⚠️ `_lang` 을 함께 켠다
			// ⭐ 회차 221 — 🆕 **행동 축**(`-mltact` · 칸 3 조건 ㈀)
			//   ⚠️ 축 수를 바꾸므로 **`_nw = _NwOf(0u)` 보다 먼저** 읽어야 한다(200 이 밟은 함정)
			_effOn = OS::CommandLine::Has("-mlteff");   // 226 — efference copy(행동 축을 켠다)
			_actOn = OS::CommandLine::Has("-mltact") || _effOn;
			_lang2 = OS::CommandLine::Has("-mltl2");
			// ⭐ 회차 213 — 🆕 **㈃ 모드**(`-mltl2ctx` = 문맥 스윕 × 언어 유무)
			//   ⚠️ 이 한 줄이 **다른 두 플래그를 켠다** — 그래서 여기(가장 앞)에 둔다.
			//     ★ 안 그러면 `_ctxSweep` 이 아래에서 다시 읽히며 **꺼진다**(같은 계열의 함정).
			_l2ctx = OS::CommandLine::Has("-mltl2ctx");
			if (_l2ctx) _lang2 = true;
			if (_lang2) _lang = true;
			// ⭐ 회차 211 — **캡션 자리 수**(`-mltlnw 1|2|4`)
			//   ⚠️ 이 줄은 `_nw = _NwOf(0u)` **보다 먼저**여야 한다(회차 200 이 밟은 그 함정)
			{
				const char* lv = OS::CommandLine::ValueOf("-mltlnw", "");
				if (lv != nullptr && (lv[0] == (char)49 || lv[0] == (char)50 || lv[0] == (char)52))
					_lnw = (uint32)(lv[0] - (char)48);
			}
			// ⭐⭐⭐ 회차 255 — **낱말을 물체 정체성으로**(`-mltlid`)
			//   ⚠️ 기본은 **슬롯 번호**다(241 과 견줄 수 있게 · 규율 58) — 실측이 ⛔ 였다.
			_lidOn = OS::CommandLine::Has("-mltlid");
			_initSeed = OS::CommandLine::Has("-mltinitseed");   // ⭐ 회차 202
			_qSweep = OS::CommandLine::Has("-mltqsweep");       // ⭐ 회차 203 — 부채 D25
			_nw = _NwOf(0u);
			// ⭐ 회차 190 — **㈄ 를 축 14 에서**(`-mltauword`)
			//   ★ 189 의 대조 팔이 답을 줬다: 「**자율인** 물체 중 첫 슬롯」이
			//     `d̄` **−0.19062** · `t` **5.05** · 3/3 ⇒ 12씨앗 `t` ≈ **10.1**
			//   ⇒ ⭐ 그 낱말은 **축 하나면 충분하다** ⇒ ★ 21축의 대가(`P3` +1.1% → +5.7%)를 안 낸다
			//   ⚠️ 184 의 ㈆(「**바뀐** 물체」)는 마스크와 **겹쳐** 죽었고, 이것은 **안 겹친다**
			//     (자율성은 세계의 은닉 성질 — 188 이 세운 세 조건의 답)
			_auWord = OS::CommandLine::Has("-mltauword");
			// ⚠️ `_lang` 은 **위에서 이미** 읽었다(`_nw` 를 정하는 줄보다 먼저여야 한다)
			// ⭐ 회차 192 — 슬롯 눈감기(㉡ · D5)
			_blindOn = OS::CommandLine::Has("-mltblind");
			// ⭐ 회차 193 — ㉢ D7 지름길 지도
			_shufOn = OS::CommandLine::Has("-mltshuf");
			// ⭐ 회차 186 — 걸음 4배(3200)
			_steps = OS::CommandLine::Has("-mltsteps4") ? (kStepsBase * 4u) : kStepsBase;
			// ⭐ 회차 187 — 문맥 4배(512 → 2048 · 표본을 늘린다)
			// ⭐ 회차 194 — **문맥 셋을 팔로**(512 · 2048 · 8192)
			//   ★ `_nCtx` 는 **모으는** 양(팔 셋의 최대치)이고 팔마다 `_armCtx` 로 앞부분을 쓴다
			//     ⇒ ⭐ 수집이 **씨앗당 1회**라 팔 셋이 그것을 공유한다(그래서 비용이 안 3배가 된다).
			// ⭐ 회차 199 — **세계 모드**(`-mltw2 2` = 궤도 · 198 이 찾았다)
			//   ★ 198: 궤도 세계에서 「깊이」의 여지 비가 **23.2%**(옛 세계 7.3% 의 3.2배)
			//   ⚠️⚠️ 그런데 **절대량으로는 0.0233 → 0.0356 나트 = 1.5배**뿐이고
			//     그것은 **194 가 잰 실행 잡음 0.044 보다 작다** ⇒ ★ *"구별되지 않는다"* 가 될 수 있다.
			//   ⇒ ⭐ 이 회차가 그것을 가른다 — **실행 잡음은 세계가 바뀌면 달라진다**(재야 안다).
			{
				const char* wv = OS::CommandLine::ValueOf("-mltw2", "");
				if (wv != nullptr && wv[0] >= (char)48 && wv[0] <= (char)51) _w2 = (int)(wv[0] - (char)48);
			}
			// ⭐ 회차 201 — **학습률 배율**(`-mltlr 5` = ×0.5 · 152 의 U자 최적)
			{
				const char* lv = OS::CommandLine::ValueOf("-mltlr", "");
				if (lv != nullptr && lv[0] >= (char)48 && lv[0] <= (char)57)
				{
					uint32 v = (uint32)(lv[0] - (char)48);
					if (lv[1] >= (char)48 && lv[1] <= (char)57) v = v * 10u + (uint32)(lv[1] - (char)48);
					if (v >= 1u && v <= 40u) _lrMul = (float)v / 10.0f;
				}
			}
			_ctxSweep = OS::CommandLine::Has("-mltctxsweep") || _l2ctx;   // ⭐ 213
			_nCtx = (_ctxSweep || OS::CommandLine::Has("-mltctx16")) ? kNCtxMax
			      : (OS::CommandLine::Has("-mltctx4") ? (kNCtxBase * 4u) : kNCtxBase);
			_armCtx = _nCtx;
			// ⭐ 회차 188 — 지속 표적의 손실 무게(`-mltq 15` = 0.15)
			{
				const char* qv = OS::CommandLine::ValueOf("-mltq", "");
				if (qv != nullptr && qv[0] >= (char)48 && qv[0] <= (char)57)
				{
					uint32 v = (uint32)(qv[0] - (char)48);
					if (qv[1] >= (char)48 && qv[1] <= (char)57) v = v * 10u + (uint32)(qv[1] - (char)48);
					if (v <= 100u) _qw = (float)v / 100.0f;
				}
			}
			_Banner(); _banner = true;
		}
		if (_seed >= _seeds) { _Summary(); return; }
		if (_st == kGather)    { _Gather(); return; }
		if (_st == kQuiesce)
		{
			if (_qWait > 0u) { --_qWait; return; }
			_st = kBodyInit; return;
		}
		if (_st == kBodyInit)  { _BodyBegin(rhi); return; }
		if (_st == kBodyTrain) { _BodyTrain(); return; }
		_EvalStep();
	}
	static bool Done() { return _done; }

private:
	// ══════════════════════════════════════════════════════════════
	// 📐 상수 — ⚠️ 회차 180 이 고른 점 하나만 쓴다(㈄ · 눈금 4)
	// ══════════════════════════════════════════════════════════════
	// ⭐⭐ 회차 234 — **상한과 기본을 가른다**
	//   ★ `kSeedsMax` = **배열 크기**(살 수 있는 최대 예산) · `kSeedsDef` = **회차가 사는 자리**(12).
	//   ⚙️ 233 이 λ0.10 에서 `t` **2.55** · 9/12 를 냈다 ⇒ 필요 씨앗 `(3/2.55)² × 12` = **17**
	//     ⇒ ★ eff 의 65 와 달리 **살 수 있는 값**이라 상한을 24 로 연다.
	//   ⚠️ 기본은 **12 로 묶는다** — 안 그러면 회차 1~233 의 재현이 통째로 달라진다(규율 58).
	static constexpr uint32 kSeedsMax = 24u;
	static constexpr uint32 kSeedsDef = 12u;
	inline static uint32 _seeds = kSeedsDef;

	// ⚠️⚠️ `MLTP3Ctx::kTime`·`kBatch` 를 `Type::상수` 로만 쓰면 cwgen 이 include 를 안 붙인다
	//   (회차 180 의 그 함정) ⇒ ★ 여기서는 **직접** 쓰고 값이 같아야 함을 적어 둔다.
	static constexpr uint32 kTime  = 8u;      // = MLTP3Ctx::kTime
	static constexpr uint32 kBatch = 8u;      // = MLTModelCfg::kBatch
	static constexpr uint32 kSlots = 8u;      // = MLTP3Ctx::kPersist — ★ 물체 슬롯
	static constexpr uint32 kStateAx = 5u;    // = MLTP3Ctx::kStateAx

	// ⭐ 회차 180 이 고른 눈금 = **4 픽셀** ⇒ 칸 16×16 = 256 + 「없음」 = **257**
	// ⭐ 회차 183 — **표적을 「이동 방향」으로**(`-mltdir`)
	//   회차 181 이 벽을 찾았다: **칸 번호가 불투명 정수라 몸통이 「37 과 38 이 인접」임을 모른다.**
	//   ⇒ ★ 방향이면 「지금 칸 + 방향 → 다음 칸」을 풀 필요가 없다 — **방향이 곧 답**이다.
	//   ⇒ ⭐ 회차 182 가 12초에 그 전제를 재서 **5개 점이 4/4** 를 냈다(최선 = ㈂ · 문턱 1.0).
	//     어휘 257 → **10** · 목표선 1.329 → **0.3181** · **배울 여지 1.8배**.
	inline static bool _dirOn = false;
	inline static bool _qChg = false;            // ⭐ 회차 185 — 학습 손실도 변화만(㉷)
	// ⭐ 회차 188 — **지속 표적의 손실 무게**(확률적 마스크 · `-mltq <n>` = n/100)
	//   q = 0.00 → 185·187(변화만) · q = 1.00 → 184(전체 학습)
	inline static float _qw = 0.0f;
	static constexpr float kDirThr = 1.00f;      // ⭐ 182 가 고른 정지 문턱(픽셀)
	static constexpr uint32 kDirCls = 10u;       // 0=정지 · 1..8=8방위 · 9=없음

	static constexpr uint32 kPx    = 4u;
	static constexpr uint32 kGrid  = (uint32)MLTWorldCfg::kSide / kPx;   // 16
	static constexpr uint32 kCells = kGrid * kGrid;                      // 256
	static constexpr uint32 kNCell = kCells + 1u;                        // 257 (칸 모드)
	// ⚠️ 어휘는 **모드마다 다르다** ⇒ 배열·심볼 대역은 **큰 쪽**으로 잡고 런타임 값은 `_N()`
	static constexpr uint32 kN     = kNCell;                             // 배열 상한(257)
	static constexpr uint32 kNone  = kCells;                             // 칸 모드의 「없음」
	static uint32 _N()    { return _dirOn ? kDirCls : kNCell; }
	static uint32 _NoneC(){ return _dirOn ? (kDirCls - 1u) : kNone; }

	// ⭐ 세계 — 칸 모드는 180 의 점 ㈄(dt 0.25) · **방향 모드는 182 의 점 ㈂(dt 1.0)**
	//   ⚠️⚠️ **규율 76** — 표적을 바꾸면 세계도 다시 고른다(182 가 8점을 다시 훑었다)
	static float _Dt()  { return _dirOn ? 1.00f : 0.25f; }
	static float _Amp() { return 5.0f; }
	static constexpr float kDt   = 0.25f;   // ⚠️ 옛 이름(칸 모드 · 배너 표시용)
	static constexpr float kAmp  = 5.0f;
	static constexpr int   kAuto = MLTWorldCfg::kAutoMany;   // 3 — ⚠️ 규율 73·75 로 재등록된 상한

	// ⭐ 회차 187 — **문맥을 늘린다**(`-mltctx4` = 512 → 2048)
	//   ★ 근거(회차 186 의 손계산): 학습 표적 = 변화 **6.8**/문맥 × 512 = **3,482 개**인데
	//     파라미터가 **858,496 개** ⇒ ***파라미터 ÷ 표적 = 246배*** ⇒ **과적합이 당연하다.**
	//     ⇒ 186 이 걸음 4배로 그것을 확인했다(몸통·오라클 **둘 다 악화**) ⇒ **규율 82**.
	//   ⇒ ⭐ 2048 이면 표적 **13,928** ⇒ 비 **62배** 로 내려온다.
	//   ⭐ **비용이 거의 안 든다** — 늘어나는 것은 **수집**뿐이고(회차 179 실측 9초 ⇒ 36초)
	//     학습은 걸음 800 그대로다. ⚠️ 풀 메모리 2.75MB.
	//   ⚠️ **「크기를 성능 손잡이로 쓰지 않는다」 규약을 안 어긴다** — 모델이 아니라 **데이터**다.
	//   ⚠️⚠️ 학습 에피소드 대역이 늘어난다(1 → 2048) ⇒ ★ 시험 대역(5001~)과 **안 겹친다**(규율 12).
	// ⭐ 회차 194 — **표본 곡선을 팔로 잰다**(`-mltctxsweep` · 512 · 2048 · 8192)
	//   ⚠️⚠️ 8192 만 재고 187(2048)·193(512)의 숫자와 견주면 **규율 65** 에 걸린다
	//     (*"예산은 **그 자리의** 값이다"* — 다른 회차의 값은 다른 팔 구성에서 나온 것이다).
	//   ⚠️⚠️ 그리고 두 점으로 8192 를 외삽하면 **규율 83**(188 → 190 에서 이미 깨졌다).
	//   ⇒ ⭐ 그래서 **세 문맥을 한 회차의 팔로** 잰다 ⇒ 곡선이 **외삽이 아니라 관측**이 된다.
	//   ⚠️ `kNCtxMax` 를 올리면 **`mltmodel.cw` 의 `kPool` 도 같이** 올려야 한다
	//     (`nSteps = 8192/8 = 1024` · 안 올리면 `UploadPool` 이 **조용히 false**).
	static constexpr uint32 kNCtxBase = 512u;
	inline static uint32 _nCtx = kNCtxBase;
	static constexpr uint32 kNCtxMax = kNCtxBase * 16u;     // 8192 — 배열 상한
	// ⭐ 문맥 팔(회차 194) — `_ctxSweep` 이 켜지면 팔 번호가 곧 이 표의 인덱스다
	static constexpr uint32 kCtxArms = 3u;
	// ⭐ 회차 213 — **칸 2 조건 ㈃ 의 자**: 문맥 3 × **언어 유무 2 = 6팔**
	//   ⚙️ ㈃ = *"언어를 붙인 채 표본을 늘리면 표적 CE 가 계속 내려간다"*
	//   ⇒ ★ 그것을 재려면 **언어 없는 곡선과 나란히** 놓아야 한다 — 그게 이 자의 정의다.
	//   ⚠️⚠️ 다른 회차(204)의 곡선과 견주면 **규율 65** 다(그쪽은 `q=0` · `λ` 도 없었다)
	//     ⇒ ⭐ **한 판에 여섯 팔로** 넣는다(같은 씨앗·같은 세계·같은 초기화 뽑기)
	static constexpr uint32 kCtxArmsL2 = 2u * kCtxArms;   // 6
	static constexpr uint32 kCtxOf[kCtxArmsL2] = { 512u, 2048u, 8192u, 512u, 2048u, 8192u };
	// ⭐ 앞 세 팔 = **언어 끔**(λ 0) · 뒤 세 팔 = **언어 켬**(λ 1.0 — 212 가 그 자리를 통과시켰다)
	static bool _CtxLangOn(uint32 a) { return a >= kCtxArms; }
	inline static bool _ctxSweep = false;
	// ⭐ 회차 213 — 문맥 스윕 × L2(`-mltl2ctx`). ⚠️ **194 의 자를 안 건드린다** —
	//   그 판정문은 「팔 = 문맥」을 가정하고 `kCtxArms - 1` 을 표제로 읽으므로
	//   여섯 팔을 그 안에 밀어 넣으면 **표제가 엉뚱한 팔**이 된다 ⇒ ★ 판정 블록을 따로 둔다.
	inline static bool _l2ctx = false;
	static constexpr uint32 kPtCtx = 512u;                  // ⚠️ 시험은 **안 늘린다**(자를 고정)
	static constexpr uint32 kTrainEpi = 1u, kPtEpi = 5001u;
	// ⭐ 회차 194 — **팔이 쓰는 문맥**(`_nCtx` 는 **모으는** 양 = 팔 셋의 최대치)
	//   ★ 배치가 스텝-메이저라 **앞 `_armCtx` 개**가 곧 그 팔의 표본이다(prefix 가 성립한다).
	// ⭐ 회차 199 — 세계 모드(0 = 옛 세계 · 1 반사 · 2 궤도 · 3 가속) — `mltworld::SetWorld2`
	inline static int _w2 = 0;
	// ⭐ 회차 201 — 학습률 배율(`-mltlr <n>` ⇒ n/10) · ⚠️ 기본 1.0 이라 옛 회차가 **비트 동일**
	inline static float _lrMul = 1.0f;
	// ⭐ 회차 202 — 초기화에 씨앗을 넣나(`-mltinitseed`) · ⚠️ 기본 끔
	inline static bool _initSeed = false;
	// ══════════════════════════════════════════════════════════════════
	// ⭐ 회차 203 — 🆕 **부채 D25: 지속까지 배워도 `P3` 가 서나**(`-mltqsweep`)
	// ══════════════════════════════════════════════════════════════════
	//   ⚙️ **왜 지금인가** — 201·202 가 `P3` 를 세웠는데(초과 **−8.0% · −7.5%**) 그것은
	//     **「변화만 학습」**(q = 0)의 성과다 ⇒ ★ 「경험 학습」의 **지속 68% 를 안 배운 것**이다.
	//   ⚠️⚠️ 회차 188 이 *"창이 없다"*(q 를 올리면 `P3` 가 죽는다)를 확정했는데
	//     ★ **그것은 옛 세계 · `lr×1` · 축 14 에서였다** ⇒ ⭐ 지금은 셋 다 다르고
	//     `P3` 에 **−7.5% 의 여유**가 있다 ⇒ ⇒ ***창이 다시 열렸을 수 있다.***
	//   ⇒ ⭐ 그래서 묻는 것은 이분법이 아니라 **정량**이다:
	//     ***`q` 를 얼마까지 올려도 `P3` 가 서나*** — 그 `q` 가 곧 칸 1 의 정직한 상태다.
	//   ⚠️ **시험 자는 안 바뀐다**(늘 「변화만」 채점) — 학습 무게만 팔마다 다르다(규율 58).
	inline static bool _qSweep = false;
	// ⚠️ `kQOf` 는 `kArms` 를 쓰므로 **팔 정의 뒤**에 있다(아래 「팔 여덟」 절)
	inline static uint32 _armCtx = kNCtxBase;
	static uint32 _PoolSteps() { return _armCtx / kBatch; }
	static constexpr uint32 kPoolStepsMax = kNCtxMax / kBatch;
	static constexpr uint32 kNCtx = kNCtxMax;               // ⚠️ 옛 이름(배열 크기용)
	static constexpr uint32 kPoolSteps = kPoolStepsMax;     // ⚠️ 옛 이름
	static constexpr uint32 kPtPool = kPtCtx / kBatch;
	// ⭐ 회차 186 — **걸음 손잡이**(`-mltsteps4` = 4배 = 3200)
	//   ★ 근거: **변화만 학습**이면 손실 표적이 21.1 → **6.8**(32.0%) ⇒ 800걸음이
	//     **유효 ~256걸음** 상당이다 ⇒ 3200 이면 유효 ~1024 로 184(전체·800)보다 **많다**.
	//   ⚠️ 회차 144 는 *"걸음은 주범이 아니다"*(3200 에서 +0.0138 · 5/12)를 냈지만
	//     ★ **그것은 「전체 학습」에서였다**(유효 표본이 이미 800) ⇒ ⭐ 조건이 다르다(규율 58).
	//   ⚠️⚠️ 그리고 `q` 축은 **이미 끝까지 갔다** — q=0 에서 P3 가 +3.2% 뿐이라 q>0 은 더 나쁘다
	//     ⇒ ★ **가중 스윕을 만들 필요가 없어졌다**(규율 21 이 회차 하나를 아꼈다).
	static constexpr uint32 kStepsBase = 800u, kPerTick = 16u;
	inline static uint32 _steps = kStepsBase;
	static constexpr uint32 kSteps = kStepsBase;   // ⚠️ 옛 이름(배너 표시용)

	// ⚠️ 심볼 대역도 **모드마다 다르다** — 칸 263 · 방향 16
	static constexpr uint32 kSymA = kStateAx + kN + 1u;   // 263 (배열 상한)
	// ⚠️⚠️ **낱말 축이 늘면 심볼 대역도 늘어야 한다**(회차 189 에서 실측으로 밟았다).
	//   ⛔ 사고: `_SymA()` 가 낱말 심볼을 **1개**만 잡아 16 이었고 축이 21 이 되자
	//     `MLTModel::Setup` 의 `if (symVocab < _axes) return false`(*"심볼 어휘는 최소한
	//     슬롯 종류를 담아야 한다"*)에 걸려 **몸통 준비 실패**가 났다.
	//   ⇒ ★ 낱말 축 `_nw` 개마다 심볼이 하나씩 필요하다 ⇒ `5 + 10 + 8 = 23 ≥ 21` ✅
	//   ★ 대역: 상태 0..4 · 슬롯 `5 + cell`(방향 10) · 낱말 `_SymA()-1-w`(22..15) ⇒ **안 겹친다**
	// ⭐ 회차 200 — 🆕 **언어 모드**(`-mltlang`) · 칸 2 조건 ㈀
	//   ⚙️ **왜** — `_Expand` 의 낱말 배치가 *내용을 **값**에, 심볼에는 **축 번호***를 넣는다.
	//     ⇒ ⚠️ 그런데 `MLT.md` 는 *"활성 하나 = **이산 id** + 세기"* 이고 `mltconcept.md` 는
	//       *"**정확히 같은 값이 같은 자리를 다시 깨운다**"* 를 앵커의 전제로 못 박았다.
	//     ⇒ ⇒ ★ **지금 낱말은 그 전제를 안 만족한다** — 값은 연속이라 정확히 반복되지 않고
	//       심볼은 축을 말하므로 **재사용도 조합도 없다.**
	//   ⇒ ⭐ 언어 모드는 **내용을 심볼(이산 id)로** 옮긴다: 낱말 자리 **둘**(`_nw = 2`)에
	//     **물체 이름**(어휘 9 = 물체 8 + 없음)을 넣는다 ⇒ ★ **81 조합을 9 심볼로 말한다.**
	//   ⚠️⚠️ **방향은 캡션에 넣지 않는다** — 그것은 표적 자신이고 **D7 위반**이다(규율 79 로
	//     184 가 「어느 물체가 바뀌나」를 고른 그 이유).
	inline static bool _lang = false;
	// ⭐⭐⭐ 회차 255 — **9 → 15**: 낱말이 「슬롯 번호」에서 **「물체 정체성」**으로 바뀐다.
	//   ⚙️ 254 심사가 잡았다: 여태 `nm = 1 + j`(**슬롯 번호** = *"보이는 물체 중 몇 번째"*)였고
	//     슬롯은 **매 시각 다시 채워지므로 지시대상이 바뀐다**(밀림 55.2% · 회차 55).
	//   ⭐ 여지를 학습 0 으로 먼저 쟀다(규율 12 · **20초**): `H(도형|슬롯)` = **1.4367 나트**
	//     = `H(도형)` 의 **62.8%**(다섯 감쇠 모드에서 58.9~63.7% ⇒ **구조적**) ⇒ 문턱 10% 의 **6.3배**.
	//   ⚠️ **어휘를 「키우는」 것이 아니라 「지시대상을 고치는」 것이고 어휘가 따라 커진다.**
	//   ★ 그리고 **세계가 이미 그 낱말을 갖고 있다**(`slotObj[t][j]` = 도형 index)
	//     ⇒ 컨셉의 🚫 *"사람이 만든 어휘를 **입력으로** 주기"* 를 **안 어긴다**.
	//   ⭐ 대가 = `_pSym` **+6행 × D 128 = +768 파라미터**(858,496 의 **0.09%**) ·
	//     출력 머리는 **무변경**(`_OutV` 는 `_lang` 에서 `_N()` 고정) ⇒ 254 손계산이 회귀 걱정을 기각했다.
	//   ⚠️⚠️ 📌 **D46 을 갚는다** — `mltl1s0`(학습 0)이 **이미 도형 index**(`kShapes` 14)를 쓴다
	//     ⇒ ***두 하네스의 캡션 정의가 처음으로 같아진다.***
	//   ⚠️⚠️ **회차 255 가 그것을 플래그 뒤로 옮겼다** — 실측이 ⛔ 였다:
	//     `d̄` 0.0995 → **0.0606**(0.61배) · `Î` 0.0416 → **0.0054**(**7.7배 하락**).
	//   ⇒ 🧾 ***표적이 「그 슬롯의 다음 방향」이라 슬롯 번호가 표적 배열의 색인 그 자체였다***
	//     ⇒ 정체성으로 부르면 몸통이 **「정체성 → 슬롯」을 먼저 풀어야** 한다.
	//   ⇒ ★ 그래서 **기본은 슬롯**(241 과 견줄 수 있게 · 규율 58)이고 정체성은 **`-mltlid`** 다.
	//   ⭐ 다음 물음은 **「표적도 정체성으로」**이고 그것은 세계를 바꾸는 것이다(사람이 정한다).
	inline static bool _lidOn = false;        // `-mltlid` — 낱말을 **물체 정체성**으로
	static constexpr uint32 kLVocabSlot = 9u;   // 슬롯 8 + 「없음」 (기본 · 241 과 같다)
	static constexpr uint32 kLVocabId   = 15u;  // 도형 14 + 「없음」 (`-mltlid`)
	// ⚠️ **대역은 큰 쪽으로 고정한다** — 심볼 대역을 모드마다 바꾸면 `_pSym` 크기가 갈려
	//   241 과의 **비트 동일이 원리적으로 불가능**해진다. ★ 안 쓰는 행은 기울기를 안 받는다(무해).
	//   ⚠️ 대가는 **+768 파라미터(0.09%)** 이고 255 가 그것으로 회귀를 통과했다(`P3` −2.1%).
	static constexpr uint32 kLVocab = kLVocabId;    // = 15 (대역 · 실제 쓰는 어휘는 `_LVoc()`)
	static uint32 _LVoc() { return _lidOn ? kLVocabId : kLVocabSlot; }
	static constexpr uint32 kLNwMax = 4u;    // ⚠️ 배열 상한
	// ⭐ 회차 211 — **캡션 자리 수를 런타임으로**(`-mltlnw <n>`)
	//   ⚠⚠ 팔로 둘 수 없다 — `_nw` 는 **모드 전역 값**이다(회차 189 의 그 함정)
	//   ⇒ ★ **판을 나눠 돌린다** · ⭐ 활용률은 **판 안의 보**라 판끔리 견줌 수 있다(귀원 67·177)
	inline static uint32 _lnw = 2u;
	// ⚠️ 언어 모드는 어휘 대역이 **`_nw` 가 아니라 `kLVocab`** 이다(심볼이 축이 아니라 낱말이다)
	// ══════════════════════════════════════════════════════════════════
	// ⭐ 회차 212 — **L2 모드**(`-mltl2`) · 칸 2 조건 ㈂
	// ══════════════════════════════════════════════════════════════════
	//   ⚙️ **물음**: ***언어를 같이 학습시키면 `P` 가 무너지나***(`MLT.md` 의 **L2 관문**)
	//   ⭐ 자는 `mltplan_2.md` 의 「㈂ 의 자」에 **미리 서 있다**(다른 세션이 지적해서 세웠다).
	//   ⚠️⚠️ **출력 어휘가 달라진다** — 캡션을 **표적으로도** 놓으므로 `_N() + kLVocab` 이다.
	//     ⇒ ⛔⛔ 그러면 **무효 표적 센티널 `(float)_N()` 이 유효 범위 안으로** 들어온다.
	//     ⇒ ★ 그것이 **공용 규율 16 이 경고한 자리**다 — 센티널이 **여러 곳**에
	//       흩어지면 새 축이 올 때 **한쪽만 안다** ⇒ ⭐ 그래서 **한 함수로 모은다**(`_Inv()`).
	//   ⚠️ `λ`(언어 손실 무게)는 **확률 마스크**로 준다 — 기대 무게가 정확히 `λ` 이고
	//     **셰이더 수술이 0** 이다(회차 188 의 그 관용구).
	inline static bool _lang2 = false;
	// ⭐ 출력 어휘 — L2 면 **캡션 어휘가 밀려 붙는다**(방향 0..N-1 · 캡션 N..N+8)
	static uint32 _OutV() { return _N() + (_lang2 ? kLVocab : 0u); }
	// ⭐ **무효 표적 센티널** — 한 곳에만 산다(공용 규율 16)
	//   ⚠️ 출력 어휘 **밖의** 정수여야 한다 — 커널이 `t >= cols` 를 무효로 접는다
	static float  _Inv()  { return (float)_OutV(); }
	// ⭐ 회차 221 — 🆕 **행동 축**(칸 3 조건 ㈀ · `-mltact`)
	//   ⚙️ 76 이 `StepWith` 를 낳았고 77 이 옛 코퍼스에서 배관을 세웠는데 **이 하네스에는 없다**
	//     (상태 5축은 **관측**이고 `w.Step()` 이 행동을 스스로 고른다 — 214 가 확인).
	//   ⭐ **축을 맨 뒤에 붙인다** ⇒ `_RowState`/`_RowSlot` 이 `_nw + ...` 를 쓰므로
	//     ***기존 색인을 하나도 안 건드린다.*** ⚠️ 앞에 넣으면 190·200·213 이 밟은 그 함정이다.
	//   ⚠️ 「상수로 둔 것」: 행동을 **`dYaw` 하나**로 좁혔다(220 이 *"통로를 좁히는 것이 이긴다"* 를
	//     네 번째로 확인했지만 그것은 **학습 0 여지**이고 몸통이 쓰는 것과는 다르다) ·
	//     그리고 **축의 자리(맨 뒤)** 가 학습에 영향을 줄 수 있다 — **근거 없음**.
	inline static bool _actOn = false;
	static uint32 _ActAxN()  { return _actOn ? 1u : 0u; }
	// ⭐ 회차 225 — 🆕 **용량 스윕**(`-mltcap`) · 새 캔버스 `용량이 병목인가`
	//   ⚙️ 세 칸(1·2·3)이 전부 🔶 이고 **이유가 같다**: 활용률 오라클 0.68 · 캡션 0.13 · 행동 ≤ 0.23
	//     ⇒ ★ 병목은 *"무엇을 넣나"* 가 아니라 ***"몸통이 그것을 쓰는 능력"*** 이다.
	//   ⭐ 146 이 이 갈래(㉠ 용량)를 찍어 놓고 **안 골랐다**. 그때 미룬 이유가
	//     *"`MLTModelCfg` 상수를 바꾸면 138~149 검산 사슬이 끊긴다"* 였는데
	//     **회차 150 이 `dim`/`layer`/`ff` 를 런타임으로 열었다**(기본값이면 비트 동일)
	//     ⇒ ⭐ 그 대가가 **이미 지불됐다.**
	//   ⭐ 그리고 224 가 근거를 보탰다: 축에 **무작위 변동만** 넣어도 CE 가 −0.022 내려갔다
	//     ⇒ ***축 하나가 준 것이 「정보」가 아니라 「파라미터」였다***(부채 D38).
	//   ⚠️⚠️ **아래로도 본다**(d 64) — 줄여서 활용률이 내려가면 그것이 **양성 대조**다.
	//     ★ 없으면 *"늘려도 안 오른다"* 를 *"손잡이가 아니다"* 와 **구별 못 한다**(규율 2).
	inline static bool _capOn = false;
	static constexpr uint32 kCapArms = 6u;                       // 용량 3점 × (진짜·섞음)
	static constexpr uint32 kCapDim[3] = { 64u, 128u, 192u };    // 128 = 기본
	static constexpr uint32 kCapFF[3]  = { 171u, 344u, 512u };   // ⚠️ `8/3·d` 규약을 지킨다
	static uint32 _CapIx()  { return _arm / 2u; }
	static uint32 _CapDim() { return _capOn ? kCapDim[_CapIx()] : MLTModelCfg::kDim; }
	static uint32 _CapFF()  { return _capOn ? kCapFF[_CapIx()]  : MLTModelCfg::kFF; }
	// ⚠️ 심볼 대역이 하나 늘어난다 — 189 가 밟은 그 자리(`symVocab < _axes` 면 몸통 준비 실패)
	static uint32 _SymA()    { return kStateAx + _N() + (_lang ? kLVocab : _nw) + _ActAxN(); }
	// ⭐ 행동 심볼은 **맨 끝**, 낱말은 그 앞부터 ⇒ 안 겹친다
	static float  _ActSym()  { return (float)(_SymA() - 1u); }
	static uint32 _SymA_old_unused() { return kStateAx + _N() + (_lang ? kLVocab : _nw); }
	static float  _WordSym() { return (float)(_SymA() - 1u - _ActAxN()); }   // ⭐ 221 — 행동 심볼을 비켜 준다
	// ⭐⭐ 회차 236 — **어휘를 뭉갠다**(`-mltlvoc <n>`) — 통로의 **두 번째 축**
	//   ⚙️ 218 이 결정적인 한 쌍을 갖고 있었다: 정보는 **자리**에 있고(자리1 9.1% ↔ 자리무한 37.4%)
	//     몸통은 **자리를 못 쓴다**(211: 자리 1 이 최선 · 자리 4 는 `d̄` 가 12.8배 급감).
	//   ⇒ ⚠️ 자리 축은 **이미 바닥**이다(자리 0 이면 낱말이 없어진다) ⇒ 어휘 축으로 간다.
	//   🔬 가설(⚠️ **근거가 아니다** — 규율 18): 컨셉이 *"부호가 없으면 버릴 기준이 없어서
	//     전부 똑같이 담아야 한다"* 를 적었다 ⇒ ★ 그 뒷면 = ***덜 주면 더 쓸 수 있다.***
	//   ⚠️⚠️ **모델 크기를 안 바꾼다** — 대역은 `kLVocab`(9) 그대로 두고 **값만 뭉친다**
	//     ⇒ ★ 그래야 용량이 팔 사이에서 흔들리지 않는다(189 의 그 함정).
	//   ⚠️ 뭉치는 규칙은 **`%`** 다 — ***이웃이 아닌 것끼리 묶인다.*** 일부러 그렇게 한다:
	//     설계자가 「의미 있는 그룹」을 정하면 그것이 곧 **라벨 주입**이다(🚫 의 그 자리).
	//   ⚠️ 「없음」(`kLVocab - 1`)은 **안 뭉친다** — 그것은 이름이 아니라 **부재**다.
	inline static uint32 _lvoc = 0u;         // 0 = 안 뭉친다(회차 1~235 의 동작)
	// ⚖️✂️ 회차 240 — **세계가 좁히는 판**. ⚠️ 기본 꺼짐 ⇒ 회차 1~239 비트 동일(규율 58).
	inline static bool   _enOn  = false;     // 에너지(감쇠)
	inline static float  _prBud = -1.0f;     // 가지치기 예산(음수 = 끔)
	// ⭐⭐ 회차 243 — **감쇠 세기가 손잡이다**(242 가 학습 0 에서 격자를 골라 줬다:
	//   0.65 는 거의 무효 · 0.35 가 241 · 0.15 가 포화 직전 · 0.05 는 음성 대조였다).
	//   ⚠️ 음수 = 세계의 기본값(`MLTWorldCfg::kEnergySlow` 0.35 = 241 이 쓴 값).
	inline static float  _slow  = -1.0f;     // 감쇠 세기(음수 = 기본 0.35)
	static uint32 _VocFold(uint32 v)
	{
		if (_lvoc == 0u || _lvoc + 1u >= kLVocab) return v;
		if (v >= kLVocab - 1u) return kLVocab - 1u;      // 「없음」은 그대로
		return v % _lvoc;                                 // 이름 8 → `_lvoc` 그룹
	}
	// ⭐ 언어 모드의 낱말 심볼 — 어휘 id `v`(0..8)가 곧 심볼이다(★ **자리와 무관** ⇒ 재사용)
	static float  _LangSym(uint32 v) { return (float)(kStateAx + _N() + (_VocFold(v) % kLVocab)); }
	static constexpr uint32 kAx13 = kStateAx + kSlots;    // 13
	// ⭐ 회차 189 — **낱말 축 수를 손잡이로**(`-mltslotword` ⇒ 1 → 8)
	//   ★ 근거(188): 낱말이 셋을 다 만족해야 한다 — ① 마스크가 안 주는 것(**방향 축**) ·
	//     ② 상태 5축에서 유도 안 되는 것 · ③ **그 슬롯**의 것.
	//     ⇒ 남는 것은 ***「그 슬롯 물체가 자율인가」*** 하나다(다음 방향은 **표적 자신** = 새는 말).
	//   ⚠️ 배열은 **상한(21축)** 으로 잡고 인덱스만 런타임 값을 쓴다(재할당 없음).
	//   ⚠️⚠️ **섞음도 슬롯마다** 걸어 축 개수를 맞춘다 ⇒ 짝지은 차가 축 교란을 지운다
	//     (회차 138·139 가 축 개수 교란을 지적했다) · ★ 그리고 **상수·축21** 팔로 그것을 대조한다.
	inline static uint32 _nw = 1u;                        // 낱말 축 수(1 또는 kSlots)
	inline static bool _slotWord = false;                 // ⭐ 회차 189 — 슬롯마다 낱말 모드
	inline static bool _auWord = false;                   // ⭐ 회차 190 — ㈄(자율여부·축1)을 표제로
	// ⭐ 회차 192 — **㉡ D5 를 ㉲ 에서 재정의: 「슬롯 눈감기」**(`-mltblind`)
	//   ★ D5(회차 60)의 막힘 = *"컨텍스트에 **원본 패치가 없어** 이미 눈감은 상태"* —
	//     옛 표현은 컨텍스트에 **활성(코드 id)만** 있어서 「끊음/안 끊음」이 **구별되지 않았다**.
	//   ⇒ ⭐ ㉲ 에도 원본 프레임은 없지만 **더 나은 자가 생겼다**: `t ≥ tCut` 부터
	//     **슬롯 심볼·값을 비운다**(상태 5축만 남긴다) ⇒ 몸통은 **직전 시각들 + 상태**로 예측한다.
	//   ⇒ ★ ㉲ 에서 뜻이 있는 이유: ***물체가 identity 로 이어진다*** ⇒ 「끊어도 **그 물체를
	//     기억하나**」를 묻는다. 옛 표현은 슬롯이 매 시각 밀려(51·167) **기억할 대상이 없었다**
	//     ⇒ ⭐ 그래서 이것은 D5 의 **우회가 아니라 그 물음의 첫 성립**이다.
	//   ⚠️ 자는 **짝지은 차가 아니라 CE 절대값**이다(낱말 대조가 아니다) ⇒ 팔 = 눈감기 시점 여덟.
	inline static bool _blindOn = false;
	static uint32 _TCutOf(uint32 a) { return kTime - a; }   // ㈀=8(안 끊음) … ㈇=1

	// ⭐ 회차 193 — **㉢ D7: 지름길 지도**(`-mltshuf`)
	//   ★ ㉲ 가 D7 의 여섯 중 **넷을 지웠다**(인코더도 패치도 없다) ⇒ 남은 둘 = **값 섞기 · 과제 섞기**
	//   ⇒ ⭐ 한 회차의 팔로 **지도 전체**를 그린다(같은 값이다).
	//   ⚠️ **섞기 = 문맥 사이 교환**(`ctx' = 해시(씨앗,문맥,시각,슬롯) % nCtx`)
	//     ⇒ ★ **주변분포는 그대로**이고 **상관만 깨진다** — 그것이 「지름길 끊기」의 정의다.
	//   ⚠️⚠️ **양쪽(학습+시험) 다 섞는다** — D7 은 *"지름길을 **끊고 학습**시킨다"* 이다.
	//     ⭐ 예외는 **표적**뿐(시험을 섞으면 **자가 무너진다**).
	inline static bool _shufOn = false;
	static constexpr uint32 kShVal = 1u, kShSym = 2u, kShState = 4u, kShTgt = 8u;
	static uint32 _ShufOf(uint32 a)
	{
		if (a == 1u) return kShVal;                       // ㈁ 값
		if (a == 2u) return kShSym;                       // ㈂ 심볼
		if (a == 3u) return kShState;                     // ㈃ 상태 5축
		if (a == 4u) return kShTgt;                       // ㈄ 표적(⚠️ 학습만)
		if (a == 5u) return kShVal | kShSym;              // ㈅ 값+심볼
		if (a == 6u) return kShVal | kShSym | kShState;   // ㈆ 전부
		return 0u;                                        // ㈀ 기준 · ㈇ 기준 재현
	}
	// 결정적 해시 — ⚠️ `mltworld` ⑧ 규약(3단 주소 · 스트림을 안 전진시킨다)
	static uint32 _ShufCtx(uint32 ctx, uint32 t, uint32 j, uint32 salt, uint32 nCtx)
	{
		uint32 h = (_seed * 0x9E3779B9u) ^ (ctx * 0x85EBCA6Bu)
		         ^ (t * 0xC2B2AE35u) ^ (j * 0x27D4EB2Fu) ^ (salt * 0x165667B1u);
		h ^= h >> 16; h *= 0x7FEB352Du; h ^= h >> 15; h *= 0x846CA68Bu; h ^= h >> 16;
		return h % nCtx;
	}
	// ⚠️⚠️ **팔마다 축 수를 바꾸지 않는다** — 그러면 `UploadPool` 의 `need = nSteps × _rows` 가
	//   배열 크기(상한 21축)와 **안 맞아 조용히 false** 가 된다(실측으로 밟았다).
	//   ⇒ ⭐ **모드 전체를 21축으로 고정**하고 「축 하나 판」은 **슬롯 0 에만 값 ·
	//     나머지 7 축은 상수**(`kConstCls` ⇒ 값이 **정확히 0**)로 둔다.
	//   ⇒ ★ 그러면 **축 개수가 모든 팔에서 같아** 교란이 ***원리적으로*** 없다 —
	//     회차 138·139 가 걱정한 그 자리가 **설계로 지워진다**(더 좋은 대조다).
	static uint32 _NwOf(uint32) { return _lang ? _lnw : (_slotWord ? kSlots : 1u); }
	static uint32 _Ax()   { return kAx13 + _nw + _ActAxN(); }   // 14 · 21 · (+1 이면 행동 축)
	static uint32 _Ctx()  { return _Ax() * kTime; }
	static uint32 _Rows() { return kBatch * _Ctx(); }
	// ⚠️⚠️ **배열 상한** — 221 이 행동 축 하나를 더했으므로 **+1** 이다
	//   ★ 최악: 낱말 8(`_slotWord`) + 상태 5 + 슬롯 8 + 행동 1 = **22**
	static constexpr uint32 kAx14 = kAx13 + kSlots + 1u;  // 22 — ⚠️ **배열 상한**(옛 이름)
	static constexpr uint32 kCtx14 = kAx14 * kTime;       // 168
	static constexpr uint32 kRows14 = kBatch * kCtx14;    // 1344
	static constexpr float  kWordSym = (float)(kSymA - 1u);   // 262

	static constexpr uint32 kWordCls = 9u;    // 0 = 없음 · 1..8
	static constexpr uint32 kConstCls = 4u;   // 값이 정확히 0 이 되는 가운데 계급

	// ── 채점 마스크(회차 141 의 손잡이 ㈏) ─────────────────────────
	static constexpr uint32 kMNone = 0u, kMChange = 1u, kMKeep = 2u, kMAll = 3u;

	// ── 팔 여덟 ────────────────────────────────────────────────────
	static constexpr uint32 kArms = 8u;
	static constexpr uint32 kOracle = 0u, kOracleS = 1u, kMaxV = 2u, kMaxVS = 3u,
	                        kDir    = 4u, kDirS    = 5u, kWhich = 6u, kWhichS = 7u;
	// ⭐ 회차 203 — `q` 여덟 점(부채 D25) · ⚠️ `kArms` 뒤에 와야 한다
	static constexpr float kQOf[kArms] = { 0.00f, 0.05f, 0.10f, 0.20f, 0.35f, 0.50f, 0.75f, 1.00f };
	// ⭐ 회차 212 — **L2 의 `λ` 여덟 점** · 팔 0 = P 만 · 4~6 = 그 짝의 **캡션 섞음**
	//   ★ 짝: (1,4) λ=0.1 · (2,5) λ=0.3 · (3,6) λ=1.0 · **(0,7) = 검산**(둘 다 λ=0)
	//   ⚠️⚠️ **섞음 팔이 이 자의 핵심**이다 — 없으면 「언어의 탓」과 「손실이 하나 더 있는 탓」을
	//     못 가른다(등록문의 그 줄 · 규율 88 의 모양).
	static constexpr float kL2Of[kArms] = { 0.00f, 0.10f, 0.30f, 1.00f, 0.10f, 0.30f, 1.00f, 0.00f };
	static bool _L2Shuf(uint32 a) { return _lang2 && !_l2ctx && (a >= 4u && a <= 6u); }
	// ⭐ 회차 213 — `λ` 를 **한 함수로 모은다**(공용 규율 16 — 계산식이 두 곳이면 한쪽만 안다)
	//   ⚠️ 213 에서 이것을 안 모으면 `kL2Of[_arm % kArms]` 가 팔 0..5 를 **엉뚱한 λ** 로 읽는다
	//     (문맥 팔 1 = 2048·언어 끔 인데 λ 0.10 이 걸린다) ⇒ ★ 자리를 하나로 둔다.
	static float _LamOf(uint32 a)
	{
		if (!_lang2) return 0.0f;
		return _l2ctx ? (_CtxLangOn(a) ? 1.0f : 0.0f) : kL2Of[a % kArms];
	}
	// ⭐ 회차 221 — **행동 모드의 팔 다섯**
	//   ⚠️ 모드 전체를 **같은 축 수**로 두고 팔은 「행동 축에 무엇을 넣나」로만 가른다(189 의 처방)
	//   ㈀ 상수(0) · ㈁ **행동 값**(dYaw 연속) ⭐ 표제 · ㈂ 값 섞음 · ㈃ 행동 **계급 9** · ㈄ 계급 섞음
	//   ⭐ **천장은 학습 0 이 이미 줬다**(220: `dYaw` 9계급 여지 **0.1166 나트**) ⇒ 규율 49·67 만족
	static constexpr uint32 kActArms = 5u;
	// ⭐ 회차 226 — **efference copy**(`-mlteff`) · 팔 = `λ` 축(212 의 관용구 그대로)
	//   ㈀ λ0(기준) · ㈁㈂㈃ λ 0.1/0.3/1.0 · ㈄㈅㈆ 그 짝의 **섞음** · ㈇ λ0 재현(검산)
	//   ⭐ 표적 어휘가 **슬롯과 같다**(방향 10) ⇒ 212 와 달리 출력 어휘를 **안 늘린다**
	inline static bool _effOn = false;
	static constexpr uint32 kEffArms = 8u;
	// ⭐ **226 의 천장 측정이 이 격자를 고쳤다**(규율 12 가 약속한 값 · 90초로 회차 하나를 아꼈다)
	//   ⛔ 처음 등록은 `0.1 / 0.3 / 1.0`(212 의 캡션 격자를 그대로 베꼈다)
	//   ⇒ ⚠️ 그런데 학습 0 이 낸 **순 사본 천장 20.8%** ↔ **캡션(타자) 37.4%** 다
	//     ⇒ ★★ ***자기가 타자보다 작다*** ⇒ λ 를 크게 주면 **더 큰 여지에서 예산을 빼 온다**
	//       (공용 규율 18-a · 그리고 이 트랙이 여섯 번 실측한 «무엇을 배우든 그만큼 잃는다»)
	//   ⇒ ⭐ 그래서 격자를 **0.03 / 0.10 / 0.30** 으로 내렸다.
	// ⭐ 228 — 227 의 최적이 **격자의 끝(0.03)** 이었다 ⇒ ★ 봉우리를 가둔다
	//   ⭐ 기준팔이 λ0 이므로 격자가 **0 < 0.01 < 0.03 < 0.05** 로 닫힌다
	//   ⓘ 227 이 이미 쟀다: λ0.10 **+0.0150**(해롭다) · λ0.30 −0.0026
	static constexpr float kEffOf[kArms] = { 0.00f, 0.01f, 0.03f, 0.05f, 0.01f, 0.03f, 0.05f, 0.00f };
	static bool _EffShuf(uint32 a) { return _effOn && (a >= 4u && a <= 6u); }
	static bool _ActShuf(uint32 a) { return _actOn && !_effOn && (a == 2u || a == 4u); }
	static bool _ActCls9(uint32 a) { return _actOn && !_effOn && (a == 3u || a == 4u); }
	// ⭐ 회차 194 — 팔 수는 모드가 정한다(배열은 `kArms` 상한 그대로 = 8 ≥ 6)
	static uint32 _Arms() { return _ctxSweep ? (_l2ctx ? kCtxArmsL2 : kCtxArms) : (_capOn ? kCapArms : (_effOn ? kEffArms : (_actOn ? kActArms : kArms))); }
	// ⭐ 회차 209 — 팔 배치를 고쳤다(오라클 천장을 넣었다)
	//   0·1 = **오라클(천장)** · 2·3 = **심볼 캡션** · 4·5 = **값 부호화** · 6·7 = **상수**
	//   ⚠️ 오라클은 **값 부호화**로 준다(184·191 과 같은 자리여야 천장이 견줄 수 있다)
	//   ⛔⛔⛔ **회차 213 이 여기서 212 의 교란을 찾았다** — `_lang2` 가 `_lang` 을 켜므로
	//     L2 모드에서도 이 함수가 참이 되어 **팔 2·3 만 입력 캡션이 심볼 부호화**였다
	//     ⇒ ⚠️ 그 둘의 섞음 짝(5·6)은 **값 부호화**였다 ⇒ ***입력 부호화가 안 맞은 짝*** 이다
	//     ⇒ ⭐ 다행히 212 의 **가장 큰 효과가 부호화가 맞는 짝**(λ0.1 = 팔 1↔4, −0.0141)이라
	//       표제는 살아 있다. ⚠️ 나머지 둘(λ0.3·λ1.0)은 **그 교란을 안고 있다** ⇒ 📌 부채 D33.
	//   ⇒ ★ L2 는 입력을 **값 부호화 하나로** 통일한다(211b 실측 활용률 값 0.29 > 심볼 0.13 —
	//     ㈃ 를 손해 보는 쪽으로 재지 않는다). ★ 표적은 원래부터 심볼이다(`_N() + cw`).
	static bool _LangSymOn(uint32 a) { return _capOn ? true : (_lang && !_lang2 && (a == 2u || a == 3u)); }   // 225: 용량 모드는 전 팔이 심볼
	// ⚠️ 회차 200 의 「id 뒤섞음」 팔은 **뺐다** — 천장이 자리를 먹었고
	//   📌 D26 은 202 가 «초기화 씨앗이 40% 를 흡수한다» 로 좁혀 뒀다(부채로 남는다).
	static bool _LangPermOn(uint32) { return false; }
	static const char* _ArmName(uint32 a)
	{
		// ⭐ 225 — 용량 모드: 팔 = `dim` × (진짜 캡션 · 섞음)
		if (_capOn)
		{
			if (a == 0u) return "㈀ d 64 캡션      ";
			if (a == 1u) return "㈁ d 64 섞음      ";
			if (a == 2u) return "㈂ d128 캡션(기본) ";
			if (a == 3u) return "㈃ d128 섞음      ";
			if (a == 4u) return "㈄ d192 캡션 ⭐    ";
			return "㈅ d192 섞음      ";
		}
		// ⭐ 회차 213 — 문맥 3 × 언어 유무 2. ⚠️ **`_lang2` 보다 먼저** 봐야 한다
		//   (`-mltl2ctx` 가 `_lang2` 도 켜므로 순서를 뒤집으면 L2 이름이 나온다)
		if (_l2ctx)
		{
			if (a == 0u) return "㈀  512 · 언어 X   ";
			if (a == 1u) return "㈁ 2048 · 언어 X   ";
			if (a == 2u) return "㈂ 8192 · 언어 X ⭐ ";
			if (a == 3u) return "㈃  512 · 언어 O   ";
			if (a == 4u) return "㈄ 2048 · 언어 O   ";
			return         "㈅ 8192 · 언어 O ⭐";
		}
		if (_effOn)
		{
			// 226 — efference copy: 팔 = λ 축
			if (a == 0u) return "㈀ λ0(기준)       ";
			if (a == 1u) return "㈁ λ0.1 흐름표적 ⭐";
			if (a == 2u) return "㈂ λ0.3 흐름표적 ⭐";
			if (a == 3u) return "㈃ λ1.0 흐름표적 ⭐";
			if (a == 4u) return "㈄ λ0.1 섞음      ";
			if (a == 5u) return "㈅ λ0.3 섞음      ";
			if (a == 6u) return "㈆ λ1.0 섞음      ";
			return "㈇ λ0 재현(검산)  ";
		}
		if (_actOn)
		{
			if (a == 0u) return "㈀ 행동 상수(기준) ";
			if (a == 1u) return "⭐ ㈁ **행동 값** ";
			if (a == 2u) return "㈂ 값 섞음         ";
			if (a == 3u) return "㈃ 행동 계급 9     ";
			return "㈄ 계급 섞음       ";
		}
		if (_lang2)
		{
			if (a == 0u) return "㈀ P 만(λ 0)      ";
			if (a == 1u) return "㈁ P+언어 λ0.1 ⭐  ";
			if (a == 2u) return "㈂ P+언어 λ0.3 ⭐  ";
			if (a == 3u) return "㈃ P+언어 λ1.0 ⭐  ";
			if (a == 4u) return "㈄ λ0.1 섞음      ";
			if (a == 5u) return "㈅ λ0.3 섞음      ";
			if (a == 6u) return "㈆ λ1.0 섞음      ";
			return "㈇ P 만 재현(검산) ";
		}
		if (_qSweep)
		{
			if (a == 0u) return "㈀ q 0.00(변화만) ";
			if (a == 1u) return "㈁ q 0.05         ";
			if (a == 2u) return "㈂ q 0.10         ";
			if (a == 3u) return "㈃ q 0.20         ";
			if (a == 4u) return "㈄ q 0.35         ";
			if (a == 5u) return "㈅ q 0.50(무릎)   ";
			if (a == 6u) return "㈆ q 0.75         ";
			return "㈇ q 1.00(전부) ⭐";
		}
		if (_lang)
		{
			// ⭐ 회차 209 — **팔 배치를 고쳤다: 오라클 천장을 넣었다**
			//   ⛔⛔ 200 의 설계에 **천장(분모)이 없었다** ⇒ 규율 49 위반
			//     (*"자를 만들기 전에 그 자의 천장을 계산한다"*)
			//   ⇒ ⚠️ 분모가 없으니 «효과가 작다» 를 «낱말이 안 쓰인다» 로 읽을 수밖에 없었다
			//   ⇒ ⭐ 천장이 있으면 **활용률**이 나오고 규율 69 로 가른다
			//     (「보탤 것이 없다」 ↔ 「몸통이 못 쓴다」)
			if (a == 0u) return "㈀ 오라클(천장) ⭐";
			if (a == 1u) return "㈁ 오라클 섞음     ";
			if (a == 2u) return "㈂ **심볼**(언어) ⭐";
			if (a == 3u) return "㈃ 심볼 섞음       ";
			if (a == 4u) return "㈄ 값 부호화       ";
			if (a == 5u) return "㈅ 값 섞음         ";
			if (a == 6u) return "㈆ 상수(축만·교란) ";
			return "㈇ 상수 섞음       ";
		}
		if (_ctxSweep)
		{
			if (a == 0u) return "㈀ 문맥 512     ";
			if (a == 1u) return "㈁ 문맥 2048    ";
			return "㈂ 문맥 8192 ⭐";
		}
		if (_slotWord)
		{
			// ⭐ 회차 189 — 같은 팔 자리에 다른 낱말을 얹었다(표제 자리는 ㈆ 유지)
			if (a == kOracle)  return "㈀ 오라클(천장) ";
			if (a == kOracleS) return "㈁ 오라클 섞음   ";
			if (a == kMaxV)    return "㈂ 상수·축8(교란) ";
			if (a == kMaxVS)   return "㈃ 상수 섞음      ";
			if (a == kDir)     return "㈄ 자율여부·축1   ";
			if (a == kDirS)    return "㈅ 자율여부1 섞음 ";
			if (a == kWhich)   return "㈆ 자율여부·슬롯마다⭐";
			return "㈇ 자율슬롯 섞음 ";
		}
		if (a == kOracle) return "㈀ 오라클(천장) ";
		if (a == kOracleS) return "㈁ 오라클 섞음   ";
		if (a == kMaxV)   return "㈂ maxV          ";
		if (a == kMaxVS)  return "㈃ maxV 섞음(바닥)";
		if (a == kDir)    return "㈄ 어디로 ⭐   ";
		if (a == kDirS)   return "㈅ 어디로 섞음   ";
		if (a == kWhich)  return "㈆ 어느물체 ⭐  ";
		return "㈇ 어느물체 섞음 ";
	}
	static constexpr uint32 kEvalsArm0 = 3u;   // 📊 D11 — ㈀ 에서만 마스크 셋
	static constexpr uint32 kOut = 2u;         // ⭐ 실행 2회(규율 37)

	enum { kGather, kQuiesce, kBodyInit, kBodyTrain, kEval };

	inline static MLTModel _M;
	inline static MLTEvalGate _gate;
	inline static bool _done = false, _banner = false, _finite = true;
	inline static uint32 _seed = 0u, _st = kGather, _step = 0u;
	inline static uint32 _arm = 0u, _out = 0u, _evalIdx = 0u, _qWait = 0u;

	// ── 코퍼스 — ⭐ 세계에서 **바로** 만든다(MLTP3Ctx 를 안 쓴다) ──────
	//   레이아웃 = `r = k*kRows14 + b*kCtx14 + t*kAx14 + a`
	//     a=0        낱말        · a=1..5  상태 5축 · a=6..13 물체 슬롯 8
	inline static Array<float> _cVal[2], _cSym[2], _cTgt[2];   // [0]=학습 [1]=시험(마스크 없는 원본)
	inline static Array<float> _eVal[2], _eSym[2], _eTgt[2];   // 낱말·마스크를 얹은 것
	inline static double _nScored[4][kSeedsMax];
	inline static double _nChg[kSeedsMax], _nTgt[kSeedsMax];

	// ── 낱말 원값·계급 ────────────────────────────────────────────
	inline static Array<float>  _mvTrRaw, _mvTeRaw, _dirTrRaw, _dirTeRaw;
	inline static Array<uint32> _wChTr, _wChTe;      // ㈀ 오라클
	inline static Array<uint32> _wMvTr, _wMvTe;      // ㈂ maxV
	inline static Array<uint32> _wDirTr, _wDirTe;    // ㈄ 어디로
	inline static Array<uint32> _wWhTr, _wWhTe;      // ㈆ 어느 물체
	// ⭐ 회차 189 — **슬롯마다** 「자율인가」(계급 3 · 색인 `(ctx*kTime+t)*kSlots + j`)
	inline static Array<uint32> _wAuTr, _wAuTe;
	// ⭐ 회차 200 — **캡션**: 자리 둘에 「이번에 바뀌는 물체 둘의 이름」
	//   ★ 어휘 = 물체 이름 8(슬롯 번호 + 1) + 「없음」 0 ⇒ 조합 81 을 9 심볼로 말한다
	//   ⚠️ **방향은 안 넣는다**(표적 자신 = D7 위반) — 규율 79 로 184 가 고른 그 축이다
	inline static Array<uint32> _wNmTr, _wNmTe;
	// ⭐ 그리고 그 **축 하나 판**(첫 자율 슬롯 번호 — ㈂ ↔ ㈄ 가 「슬롯마다」의 값을 준다)
	inline static Array<uint32> _wA1Tr, _wA1Te;
	inline static Array<uint32> _wTr, _wTe;
	inline static double _hW[kArms][kSeedsMax];
	inline static double _iW[kArms][kSeedsMax];      // Î(낱말;변화 표적) — 회차 175 의 자
	// ⭐ 회차 211 — **자리 수에 안 흔들리는 이진 `Î`**(「이 슬롯 이름이 캡션에 있나」)
	inline static double _iWb[kArms][kSeedsMax];
	inline static double _hT[kSeedsMax];
	inline static double _goal[kSeedsMax];           // ⭐ 목표선(학습 0 최선 CE)

	inline static float _ce[kOut][kArms][kSeedsMax];
	// ⭐ 회차 207 — **팔 축을 더했다**(205 에서 적은 배관 부채)
	//   ⚙️ 왜: 206 이 칸 1 의 조건을 갈랐고 🆕 ㉤(「바뀔지 안 바뀔지」를 아나)의 자가 필요해졌다.
	//   ⇒ ★ 그리고 **그 자가 이미 있었다** — 지속 표적의 정답은 「지금 계급」이므로
	//     ***지속 CE = `−log P(지금 계급)` = `−log P(지속)`*** = **이진 CE 의 지속 항**이다.
	//   ⇒ ⚠️ 여태 **팔 0 에서만** 쟀다(`kEvalsArm0`) ⇒ 205 의 「지속 CE」 열이 **전 팔에서 같았다.**
	inline static float _ceKeep[kOut][kArms][kSeedsMax], _ceAll[kOut][kArms][kSeedsMax];
	inline static bool  _seedOk[kSeedsMax];

	// ══════════════════════════════════════════════════════════════════
	// ⭐⭐ 회차 245 — 🧠 **모델 표현 캔버스**: 그 심볼이 몸통 안에서 **어느 자리**가 되나
	// ══════════════════════════════════════════════════════════════════
	//   ⚙️ 왜 지금: 244 가 **세계 축을 닫았다**(캡션 엔트로피·반복률·있음비율 전부 단조) ⇒
	//     `d̄` 의 봉우리(감쇠 0.35)를 설명할 것이 **세계 통계에 없다.**
	//   ⭐ 그리고 245 가 손계산으로 하나를 더 미뤘다: 「직전 캡션이 주는 정보」도
	//     0.153 → 0.730 → 0.889 로 **단조**다(규율 21 — 측정 0).
	//   ⇒ ★ 남은 자리는 **모델 표현**이고, 그중 자리가 **못 박혀 있는 것**이 심볼 임베딩 표다:
	//     `_LangSym(v) = kStateAx + _N() + v` ⇒ ***그 낱말의 자리가 문자 그대로 그 행***이다.
	//   ⚠️⚠️ **이 회차는 봉우리를 재지 않는다 — 자의 천장을 잰다**(규율 49).
	//     판 셋(끔·0.35·0.15)을 돌기 전에 **자가 팔을 가르는지**부터 본다.
	static constexpr uint32 kCapRows = kLVocab;   // 9 = 물체 이름 8 + 「없음」
	static uint32 _CapSymBase() { return kStateAx + _N(); }   // ⭐ `_LangSym` 이 정한 그 자리
	// ⭐ 자 여섯 — `_ce` 와 **같은 모양**이라 `_PairedSrc` 의 같은 SE(실행 항 포함)를 그대로 탄다
	//   0 ㉠ PR(학습 뒤·중심화) · 1 ㉡ PR(ΔE·중심화) · 2 ⚠️ ㉢ 이동량
	//   ⭐⭐ 회차 246 이 셋을 더했다 — 3 ㉣ PR₁(단위·**비중심화**) · 4 ㉥ PR₀(생·비중심화) · 5 ㉤ 평균 코사인
	//   ⭐⭐ 회차 247 이 하나 더 — 6 ⭐ **행동 심볼 행의 이동량**(행동 모드 전용)
	//     ⚠️ 행동 축은 심볼 행이 **하나**(`_ActSym()`)라 `PR` 은 못 쓴다(랭크가 없다) ⇒ **이동량 하나**다.
	//     ★ 246 이 이동량을 **음성 대조가 아니라 양성 자**로 확정했다(`_Shuffle` 이 피셔-예이츠라 빈도 보존).
	static constexpr uint32 kRepM = 7u;
	static constexpr uint32 kRepAct = 6u;
	inline static float _rep[kRepM][kOut][kArms][kSeedsMax];
	inline static Array<float> _symE0;            // 학습 **전** 캡션 아홉 행(`[9, D]`)
	inline static Array<float> _symAct0;          // ⭐ 247 — 학습 **전** 행동 심볼 행(`[1, D]`)
	inline static bool  _repOn = false;           // 배관이 살아 있나(리드백 실패는 조용히 끄지 않는다)
	inline static uint32 _repFail = 0u;

	// 심볼 표에서 캡션 아홉 행만 뽑는다 → `[kCapRows, D]`
	static bool _GrabCapRows(Array<float>& dst)
	{
		Array<float> tab;
		if (!_M.ReadSymTable(tab)) return false;
		const uint32 D = _M.Dim(), base = _CapSymBase();
		if (D == 0u || tab.Count() < (base + kCapRows) * D) return false;
		dst.Reset(0);
		for (uint32 r = 0; r < kCapRows; ++r)
			for (uint32 c = 0; c < D; ++c) dst.Add(tab[(base + r) * D + c]);
		return true;
	}

	// ⭐ 247 — 심볼 표에서 **행 하나**만 뽑는다(행동 축은 심볼 행이 하나다)
	static bool _GrabRow(uint32 row, Array<float>& dst)
	{
		Array<float> tab;
		if (!_M.ReadSymTable(tab)) return false;
		const uint32 D = _M.Dim();
		if (D == 0u || tab.Count() < (row + 1u) * D) return false;
		dst.Reset(0);
		for (uint32 c = 0; c < D; ++c) dst.Add(tab[row * D + c]);
		return true;
	}

	// ⭐ 247 — 행 하나의 이동 거리 `‖Δ‖`
	static double _RowMove(const Array<float>& a, const Array<float>& b)
	{
		const uint32 D = _M.Dim();
		if (D == 0u || a.Count() < D || b.Count() < D) return 0.0;
		double q = 0.0;
		for (uint32 c = 0; c < D; ++c)
		{
			const double d = (double)a[c] - (double)b[c];
			q += d * d;
		}
		return (double)Sqrt((float)q);
	}

	// ⭐⭐ **참여율**(participation ratio) = `(Σλ)² ÷ Σλ²` — ***실효 자리 수***.
	//   ★ SVD 가 필요 없다: `Σλ = tr G` · `Σλ² = ‖G‖_F²`(G = 중심화한 행들의 그람 행렬).
	//   ⚠️ 아홉 행을 중심화하면 랭크 ≤ 8 ⇒ **천장이 8** 이고, 초기값이 무작위라 **시작이 천장**이다
	//     ⇒ 🧾 이 자가 재는 것은 「조직화」가 아니라 ***무너짐***이다(등록문에 그대로 적었다).
	static double _PartRatio(const Array<float>& m)
	{
		const uint32 D = _M.Dim();
		if (D == 0u || m.Count() < kCapRows * D) return 0.0;
		Array<float> mu; mu.Reset(0);
		for (uint32 c = 0; c < D; ++c)
		{
			double s = 0.0;
			for (uint32 r = 0; r < kCapRows; ++r) s += (double)m[r * D + c];
			mu.Add((float)(s / (double)kCapRows));
		}
		double tr = 0.0, fro = 0.0;
		for (uint32 i = 0; i < kCapRows; ++i)
			for (uint32 j = 0; j < kCapRows; ++j)
			{
				double g = 0.0;
				for (uint32 c = 0; c < D; ++c)
					g += ((double)m[i * D + c] - (double)mu[c]) * ((double)m[j * D + c] - (double)mu[c]);
				fro += g * g;
				if (i == j) tr += g;
			}
		return (fro > 1.0e-30) ? (tr * tr / fro) : 0.0;
	}

	// ⚠️ **음성 대조** — 행마다의 이동 거리 평균. 캡션 빈도에 끌리는 자다(규율 88 의 그 자리).
	static double _MoveNorm(const Array<float>& a, const Array<float>& b)
	{
		const uint32 D = _M.Dim();
		if (D == 0u || a.Count() < kCapRows * D || b.Count() < kCapRows * D) return 0.0;
		double s = 0.0;
		for (uint32 r = 0; r < kCapRows; ++r)
		{
			double q = 0.0;
			for (uint32 c = 0; c < D; ++c)
			{
				const double d = (double)a[r * D + c] - (double)b[r * D + c];
				q += d * d;
			}
			s += (double)Sqrt((float)q);
		}
		return s / (double)kCapRows;
	}

	// ══════════════════════════════════════════════════════════════════
	// ⭐⭐ 회차 246 — **중심화를 안 하는** 방향 자들
	// ══════════════════════════════════════════════════════════════════
	//   ⚠️⚠️ 245 의 ㉡ 은 `ΔE` 를 **중심화한 뒤** PR 을 쟀다(㉠ 과 같은 함수를 썼다).
	//     ⛔ 그것이 재려던 것을 못 잰다: *"같은 값이 같은 자리를 다시 깨운다"* 에서
	//        ***공유 방향이 곧 신호***인데 **중심화가 그 공유 성분을 정확히 지운다.**
	//   ⇒ 🧾 그래서 방향 자는 **중심화하지 않는다.** ★ 「자를 고치는 것」이 아니라
	//     **처음부터 그 자가 그것을 못 재고 있었다**는 것이다(규율 6 의 대상이 아니다).
	//   ⚠️ ㉡ 은 **안 지운다** — 245 의 수와 이어져야 한다(규율 58).
	//   ★ 천장: 아홉 방향이 **완전 정렬**이면 1 · **완전 직교**면 9.
	static double _PartRatioRaw(const Array<float>& m)
	{
		const uint32 D = _M.Dim();
		if (D == 0u || m.Count() < kCapRows * D) return 0.0;
		double tr = 0.0, fro = 0.0;
		for (uint32 i = 0; i < kCapRows; ++i)
			for (uint32 j = 0; j < kCapRows; ++j)
			{
				double g = 0.0;
				for (uint32 c = 0; c < D; ++c) g += (double)m[i * D + c] * (double)m[j * D + c];
				fro += g * g;
				if (i == j) tr += g;
			}
		return (fro > 1.0e-30) ? (tr * tr / fro) : 0.0;
	}

	// 행마다 단위벡터로 — ⚠️ **0 행은 0 으로 둔다**(245 처럼 한 행만 움직인 팔이 있다).
	//   ⭐ `kWd = 0` 이라 기울기 0 인 행의 이동은 **정확히 0** 이다(245 의 손계산 검산).
	static void _UnitRows(const Array<float>& src, Array<float>& dst)
	{
		const uint32 D = _M.Dim();
		dst.Reset(0);
		if (D == 0u || src.Count() < kCapRows * D) return;
		for (uint32 r = 0; r < kCapRows; ++r)
		{
			double q = 0.0;
			for (uint32 c = 0; c < D; ++c) q += (double)src[r * D + c] * (double)src[r * D + c];
			const double n = (double)Sqrt((float)q);
			for (uint32 c = 0; c < D; ++c)
				dst.Add((n > 1.0e-12) ? (float)((double)src[r * D + c] / n) : 0.0f);
		}
	}

	// ⭐ 평균 쌍별 코사인 — **움직인 행끼리만**. 규율 68 의 교차 확인 자다.
	//   ★ 무작위 방향 아홉이면 ≈ 0(± 1/√D) ⇒ **0 에서 얼마나 뜨나**가 신호다.
	static double _MeanCos(const Array<float>& m)
	{
		const uint32 D = _M.Dim();
		if (D == 0u || m.Count() < kCapRows * D) return 0.0;
		Array<float> nr; nr.Reset(0);
		for (uint32 r = 0; r < kCapRows; ++r)
		{
			double q = 0.0;
			for (uint32 c = 0; c < D; ++c) q += (double)m[r * D + c] * (double)m[r * D + c];
			nr.Add((float)Sqrt((float)q));
		}
		double s = 0.0; uint32 n = 0u;
		for (uint32 i = 0; i < kCapRows; ++i)
			for (uint32 j = i + 1u; j < kCapRows; ++j)
			{
				if (nr[i] <= 1.0e-12f || nr[j] <= 1.0e-12f) continue;
				double g = 0.0;
				for (uint32 c = 0; c < D; ++c) g += (double)m[i * D + c] * (double)m[j * D + c];
				s += g / ((double)nr[i] * (double)nr[j]); ++n;
			}
		return (n == 0u) ? 0.0 : s / (double)n;
	}

	// 팔 하나의 씨앗 평균(바깥은 `_M2s` 가 접는다 — `_ce` 와 **같은 규칙**)
	static double _RepMean(uint32 m, uint32 a)
	{
		double s = 0.0; uint32 n = 0u;
		for (uint32 sd = 0; sd < _seeds; ++sd)
		{
			if (!_seedOk[sd]) continue;
			s += _M2s(_rep[m], a, sd); ++n;
		}
		return (n == 0u) ? 0.0 : s / (double)n;
	}

	// `maxV` 재료 — 회차 162 의 그것 그대로
	static constexpr float kMvUnknown = -1.0f;
	inline static float _px2[MLTWorldCfg::kShapes], _py2[MLTWorldCfg::kShapes];
	inline static bool  _pv2[MLTWorldCfg::kShapes];

	static void _Fail(const char* what)
	{
		LogA("[mlt] 🧿 ⛔ **%s 실패** — 판정하지 않는다\n", what);
		_done = true;
	}
	static void _ToBody() { _qWait = MLTEvalGate::kDelay; _st = kQuiesce; }

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🧿 **회차 181 · ㉲ 로 몸통을 돌린다**(%s)\n",
			(_seeds == 1u) ? "⚠️ **1씨앗 진단**" : "⭐ 판정 회차");
		LogA("[mlt] 🧿   ⭐ **인코더가 없다** — 센서가 「물체 정체성 + 위치」를 **구조로** 나른다\n");
		if (_dirOn)
		{
			LogA("[mlt] 🧿   ⭐ **방향 모드**(`-mltdir` · 회차 183) — 표적 = 그 물체의 **이동 방향**\n");
			LogA("[mlt] 🧿      계급 **%u**(0 = 정지 · 1..8 = 8방위 · 9 = 없음) · 정지 문턱 **%.2f 픽셀**\n",
				kDirCls, (double)kDirThr);
			LogA("[mlt] 🧿      ★ 회차 181 의 벽(*\"칸 번호가 불투명해 「37 과 38 이 인접」임을 모른다\"*)이\n");
			LogA("[mlt] 🧿        **원리적으로 사라진다** — 「지금 칸 + 방향 → 다음 칸」을 풀 필요가 없다\n");
			LogA("[mlt] 🧿      ⭐ 낱말 ㈄ 「어디로」와 표적이 ***완전히 같은 계급 공간*** ⇒ 규율 72 거리 **0**\n");
		}
		else
		LogA("[mlt] 🧿      심볼 = **지금 칸** · 값 = 깊이 · 표적 = 그 물체의 **다음 칸**(계급 %u)\n", _N());
		LogA("[mlt] 🧿      슬롯 = 보이는 물체 중 **번호 작은 %u개** ⇒ ★ **identity 가 슬롯을 고정한다**\n", kSlots);
		LogA("[mlt] 🧿   🌍 세계 = 점 ㈄(dt %.2f · amp %.1f · 자율 %d/%d) · 눈금 **%u 픽셀**(칸 %u)\n",
			(double)kDt, (double)kAmp, kAuto, MLTWorldCfg::kShapes, kPx, kCells);
		LogA("[mlt] 🧿      ⭐ 회차 180 이 **8점 × 눈금 둘** 중 **4/4 를 낸 유일한 점**으로 골랐다\n");
		LogA("[mlt] 🧿   🎛️ 팔 여덟 — ㈀ 오라클 · ㈂ maxV · ⭐ **㈄ 어디로**(표제) · ㈆ 어느물체 (+섞음)\n");
		LogA("[mlt] 🧿   🚪 배관① **목표선 0.3678 ± 0.03**(회차 180 이 다른 길로 잰 값 · 규율 68)\n");
		LogA("[mlt] 🧿   🚪 `P3` **몸통 CE < 목표선** ⇒ ★ **칸 1 닫힘 조건 ㉠ 을 처음 만족**하나\n");
		if (_slotWord)
		{
			LogA("[mlt] 🧿   ⭐ **㉸ 슬롯마다 낱말**(`-mltslotword` · 회차 189) — 축 **14 → 21**\n");
			LogA("[mlt] 🧿      🎏 낱말 = ***「그 슬롯 물체가 자율인가」***(계급 3: 0 빈칸 · 1 피동 · 2 자율)\n");
			LogA("[mlt] 🧿      ★ 왜 이것뿐인가(188 이 셋을 확정했다): ① 마스크가 안 주는 것(**방향 축**)\n");
			LogA("[mlt] 🧿        ② 상태 5축에서 유도 안 되는 것 ③ **그 슬롯**의 것\n");
			LogA("[mlt] 🧿        ⇒ ⚠️ 「그 슬롯의 다음 방향」은 **표적 자신**이라 새는 말이다\n");
			LogA("[mlt] 🧿        ⇒ ★ 남는 것은 **자율성** 하나 — 자율이면 다음 방향이 **공통 흐름을 벗어나고**\n");
			LogA("[mlt] 🧿          피동이면 그 흐름이라 **상태 차분으로 예측된다**\n");
			LogA("[mlt] 🧿          ⇒ ⭐ 낱말이 *\"이 슬롯은 예측 가능한가\"* 를 말한다\n");
			LogA("[mlt] 🧿      🎛️ 팔 — ㈀ 오라클(축1·천장) · ㈂ **상수·축8**(축 교란 대조) ·\n");
			LogA("[mlt] 🧿           ㈄ 자율여부 **축1** · ⭐ ㈆ **자율여부 슬롯마다**(표제)\n");
			LogA("[mlt] 🧿         ★ ㈆ ↔ ㈄ 가 ***희석 제거의 값***을 직접 준다(규율 67)\n");
			LogA("[mlt] 🧿         ★ 섞음도 **슬롯마다** 걸어 축 개수를 맞춘다(138·139 의 축 교란)\n");
		}
		if (_qw > 0.0f)
		{
			LogA("[mlt] 🧿   ⭐ **지속 표적의 손실 무게 q = %.2f**(`-mltq` · 회차 188)\n", (double)_qw);
			LogA("[mlt] 🧿      ⚙️ **확률적 마스크** — 지속 표적을 **확률 q 로만** 남긴다\n");
			LogA("[mlt] 🧿         ⇒ ★ **기대 무게가 정확히 q** 이고 **셰이더 수술이 0** 이다\n");
			LogA("[mlt] 🧿         ⚠️ 재현 = (씨앗,문맥,시각,슬롯)의 **결정적 해시**(`mltworld` ⑧ 의 규약)\n");
			LogA("[mlt] 🧿         ⚠️⚠️ **학습 풀에만** 건다 — 시험 풀에 걸면 **자가 바뀐다**\n");
			LogA("[mlt] 🧿      ★ 왜 다시 가중인가: 185(문맥 512)는 q=0 에서 `P3` **+3.2%** 라 창이 없었지만\n");
			LogA("[mlt] 🧿        187(문맥 2048)이 **+1.1%** 로 내려 ⇒ ⭐ **여유 2.1%p 가 생겼다**\n");
			LogA("[mlt] 🧿      🎯 표제 = ***두 칸이 동시에 서나***(`P3` < 목표선 **그리고** ㈆ t ≥ 3)\n");
		}
		if (_nCtx != kNCtxBase)
		{
			LogA("[mlt] 🧿   ⭐ **문맥 %u**(`-mltctx4` · 회차 187 · 기본 %u 의 %u배)\n",
				_nCtx, kNCtxBase, _nCtx / kNCtxBase);
			LogA("[mlt] 🧿      ★ 근거(186 의 손계산): 학습 표적 = 변화 6.8/문맥 × %u = **%u 개**\n",
				kNCtxBase, (uint32)(6.8 * (double)kNCtxBase));
			LogA("[mlt] 🧿        ↔ 파라미터 **858,496** ⇒ ***파라미터 ÷ 표적 = 246배*** ⇒ **과적합**\n");
			LogA("[mlt] 🧿      ⇒ ⭐ %u 문맥이면 표적 **%u** ⇒ 비 **%.0f배** 로 내려온다\n",
				_nCtx, (uint32)(6.8 * (double)_nCtx), 858496.0 / (6.8 * (double)_nCtx));
			LogA("[mlt] 🧿      ⭐ **비용이 거의 안 든다** — 늘어나는 것은 **수집**뿐이고 학습은 그대로\n");
			LogA("[mlt] 🧿      ⚠️ **「크기를 성능 손잡이로 쓰지 않는다」를 안 어긴다** — 모델이 아니라 **데이터**다\n");
			LogA("[mlt] 🧿      ⚠️ 시험은 **안 늘렸다**(%u 고정) ⇒ ★ 자가 그대로여야 견줄 수 있다(규율 58)\n", kPtCtx);
		}
		if (_qSweep)
		{
			LogA("[mlt] 🧿   ⭐ 🆕 **부채 D25 — 지속까지 배워도 `P3` 가 서나**(`-mltqsweep` · 203)\n");
			LogA("[mlt] 🧿      ⚙️ 201·202 가 `P3` 를 세웠는데(초과 **−8.0%% · −7.5%%**) 그것은\n");
			LogA("[mlt] 🧿         **「변화만 학습」**(q = 0)의 성과다 ⇒ ★ 「경험 학습」의 **지속 68%% 를 안 배웠다**\n");
			LogA("[mlt] 🧿      ⚠️⚠️ 회차 188 이 *\"창이 없다\"* 를 확정했지만 ★ 그것은\n");
			LogA("[mlt] 🧿         **옛 세계 · `lr×1` · 축 14** 에서였다 ⇒ ⭐ 지금은 셋 다 다르고\n");
			LogA("[mlt] 🧿         `P3` 에 **−7.5%% 의 여유**가 있다 ⇒ ⇒ ***창이 다시 열렸을 수 있다***\n");
			LogA("[mlt] 🧿      ⇒ ⭐ 묻는 것은 이분법이 아니라 **정량**이다:\n");
			LogA("[mlt] 🧿         ***`q` 를 얼마까지 올려도 `P3` 가 서나*** — 그 `q` 가 칸 1 의 정직한 상태다\n");
			LogA("[mlt] 🧿      ⚠️ **시험 자는 안 바뀐다**(늘 「변화만」 채점) — 학습 무게만 팔마다 다르다\n");
			LogA("[mlt] 🧿      팔 = q **0.00 · 0.05 · 0.10 · 0.20 · 0.35 · 0.50 · 0.75 · 1.00**\n");
		}
		if (_initSeed)
		{
			LogA("[mlt] 🧿   ⭐ **초기화에 씨앗을 넣는다**(`-mltinitseed` · 회차 202)\n");
			LogA("[mlt] 🧿      ⛔⛔⛔ **측정 0 으로 찾았다** — `mltmodel::_Spread` 에 **씨앗이 없었다**\n");
			LogA("[mlt] 🧿         `h = i * 2654435761 + salt * 2246822519;`  ⇒ ★ 인덱스와 고정 salt 의 함수\n");
			LogA("[mlt] 🧿      ⇒ ★ **12씨앗 전부가 완전히 같은 초기값**을 썼다(씨앗은 **세계만** 바꿨다)\n");
			LogA("[mlt] 🧿      ⇒ ⭐ 그래서 **어휘 id = 임베딩 행 = 고정된 초기값**이고\n");
			LogA("[mlt] 🧿         **씨앗 평균으로 안 지워진다** ⇒ 부채 **D26** 의 기제가 확정됐다\n");
			LogA("[mlt] 🧿      ⚠️⚠️ 더 크게는 — ***이 트랙의 모든 12씨앗 판정이 「하나의 초기화」***\n");
			LogA("[mlt] 🧿         ***위에서 났고 SE 가 그 우연을 못 담았다***(신뢰구간이 거짓으로 좁다)\n");
			LogA("[mlt] 🧿      ⭐ 다만 **짝지은 차는 안 흔들린다**(두 팔이 같은 초기화를 쓴다) —\n");
			LogA("[mlt] 🧿         흔들리는 것은 **그 결론의 일반화**다(*\"다른 초기화에서도 그럴까\"*)\n");
			LogA("[mlt] 🧿      🎯 표제 = ***SE 가 얼마나 커지나*** = 옛 판정들이 얼마나 낙관적이었나\n");
		}
		if (_lrMul != 1.0f)
		{
			LogA("[mlt] 🧿   ⭐ **학습률 ×%.2f**(`-mltlr` · 회차 201 · `kLr` 3.0e-3 ⇒ %.2e)\n",
				(double)_lrMul, (double)(3.0e-3f * _lrMul));
			LogA("[mlt] 🧿      ⚙️ **커널·모델 0줄** — `AdamStep(lrMul)` 이 이미 배율을 받는다\n");
			LogA("[mlt] 🧿      ★ 근거 = **회차 152**: *\"`lr` 이 높으면 모델이 「나르기」로 도망간다\n");
			LogA("[mlt] 🧿        — **큰 모델 + 높은 `lr` = 학습 불안정 ⇒ 가장 쉬운 해로 붕괴**\"*\n");
			LogA("[mlt] 🧿        ⇒ 그때 U자 최적이 **×0.5**(시험 1.8172 → **1.6770** · t 4.42 · 11/12)\n");
			LogA("[mlt] 🧿      ⇒ ⭐ 200 이 그 서명을 냈다 — 축 15 · 어휘 24 로 **모델이 커지고**\n");
			LogA("[mlt] 🧿        실행 잡음이 **0.0286 → 0.0514**(최대 **0.4267** = 거의 발산)로 뛰었다\n");
			LogA("[mlt] 🧿      🎯 표제 = ***`lr` 을 낮추면 잡음이 줄고 ㈂−㈃ 가 서나***\n");
		}
		if (_lang && !_l2ctx)   // ⚠️ 213 은 자기 배너가 있다(표제 문구가 다르다)
		{
			LogA("[mlt] 🧿   ⭐ 🆕 **언어 모드**(`-mltlang` · 회차 200 · 칸 2 조건 ㈀)\n");
			LogA("[mlt] 🧿      ⚙️ 지금까지 낱말은 **내용이 값**(연속)이고 **심볼은 축 번호**였다\n");
			LogA("[mlt] 🧿         ⇒ ⚠️ `MLT.md`(*\"활성 = **이산 id** + 세기\"*)와 `mltconcept.md`\n");
			LogA("[mlt] 🧿           (*\"정확히 같은 값이 같은 자리를 다시 깨운다\"*)의 전제를 **안 만족**했다\n");
			LogA("[mlt] 🧿      ⇒ ⭐ 언어 모드는 **내용을 심볼로** 옮긴다 — 자리 **%u** × 어휘 **%u**\n",
				_lnw, kLVocab);
			LogA("[mlt] 🧿      ⭐ 회차 211 — **자리 수가 손잡이다**(`-mltlnw` · 1·2·4)\n");
			LogA("[mlt] 🧿         ★ 근거(210): ***정답을 줘도 68%% 만 쓴다*** ⇒ 병목은 **낱말을 넣는 통로**다\n");
			LogA("[mlt] 🧿         ⚠️ `_nw` 는 **모드 전역 값**이라 팔로 못 둔다(189 의 함정) ⇒ **판을 나눠** 돈다\n");
			LogA("[mlt] 🧿         ⇒ ⭐ 활용률은 **판 안의 비**라 판끼리 견줄 수 있다(규율 67·177)\n");
			LogA("[mlt] 🧿         캡션 = 「이번에 바뀌는 물체 둘의 **이름**」 ⇒ ★ **%u 조합을 %u 심볼로**\n",
				kLVocab * kLVocab, kLVocab);
			LogA("[mlt] 🧿         ⇒ ⭐ 같은 id 가 **두 자리 모두**에 온다 = **재사용이 실재한다**\n");
			LogA("[mlt] 🧿      ⚠️⚠️ **방향은 캡션에 안 넣는다** — 그것은 표적 자신이고 **D7 위반**이다\n");
			LogA("[mlt] 🧿         (규율 79 로 184 가 「어느 물체가 바뀌나」를 고른 그 이유)\n");
			LogA("[mlt] 🧿      🎯 표제 = **㈂−㈃**(심볼 낱말 ↔ 섞음) · ⭐ 견줌 = **㈀−㈁**(값 부호화)\n");
		}
		if (_w2 != 0)
		{
			static const char* wn[4] = { "옛 세계", "반사", "궤도", "가속" };
			LogA("[mlt] 🧿   ⭐ **세계 %d = %s**(`-mltw2` · 회차 199 · 198 이 찾았다)\n", _w2, wn[_w2]);
			LogA("[mlt] 🧿      ★ 198: 옛 세계는 도형 14개 중 **3개만** 움직였다(나머지는 카메라 흐름)\n");
			LogA("[mlt] 🧿        ⇒ 새 세계는 **전 도형이 움직인다** ⇒ 궤도에서 여지 비 **7.3%% → 23.2%%**\n");
			LogA("[mlt] 🧿      ⚠️⚠️ **그런데 절대량은 0.0233 → 0.0356 나트(1.5배)** 뿐이고\n");
			LogA("[mlt] 🧿         그것은 **194 의 실행 잡음 0.044 보다 작다** ⇒ ★ 구별이 안 될 수 있다\n");
			LogA("[mlt] 🧿      ⇒ ⭐ **이 회차가 그것을 가른다** — 실행 잡음은 세계가 바뀌면 달라진다\n");
			LogA("[mlt] 🧿      ⚠️ 회차 1~198 의 몸통 숫자는 **전부 세계 0** 의 것이다(견줄 때 조심)\n");
		}
		if (_actOn)
		{
			LogA("[mlt] 🧿   ⭐ 🆕 **행동 축**(`-mltact` · 회차 221 · **칸 3** 조건 ㈀·㈁)\n");
			LogA("[mlt] 🧿      ⚙️ 76 이 `StepWith` 를 낳고 77 이 옛 코퍼스에 배관을 세웠는데\n");
			LogA("[mlt] 🧿         **이 하네스에는 없었다**(상태 5축은 **관측** · 214 가 확인)\n");
			LogA("[mlt] 🧿      ⭐ 축 하나(`dYaw` 정규화)를 **맨 뒤**(축 %u)에 붙였다 ⇒ 기존 색인 무변경\n",
				_nw + kAx13);
			LogA("[mlt] 🧿      🎛️ 팔 다섯 — ㈀ 상수(기준) · ⭐ ㈁ **행동 값** · ㈂ 값 섞음 · ㈃ 계급 9 · ㈄ 계급 섞음\n");
			LogA("[mlt] 🧿      ⭐ **천장은 220 이 이미 줬다** — `dYaw` 9계급 여지 **0.1166 나트**(궤도·몸통 자리)\n");
			LogA("[mlt] 🧿      🎯 표제 = **㈁−㈂**(진짜 행동 ↔ 섞음) · 활용률 = 몸통 |d̄| ÷ 0.1166\n");
			LogA("[mlt] 🧿      ⚠️ 「상수로 둔 것」 — `dYaw` 하나로 좁혔다 · 축을 맨 뒤에 뒀다(**근거 없음**)\n");
		}
		if (_l2ctx)
		{
			LogA("[mlt] 🧿   ⭐ **㈃ — 문맥 × 언어**(`-mltl2ctx` · 회차 213 · 칸 2 의 마지막 조건)\n");
			LogA("[mlt] 🧿      팔 여섯 = 문맥 **%u·%u·%u** × **언어 유무**(λ 0 ↔ 1.0)\n",
				kCtxOf[0], kCtxOf[1], kCtxOf[2]);
			LogA("[mlt] 🧿      ⚙️ ㈃ = *\"언어를 붙인 채 표본을 늘리면 표적 CE 가 계속 내려간다\"*\n");
			LogA("[mlt] 🧿      ⚠️⚠️ 204 의 곡선과 견주지 **않는다**(그쪽은 `q=0` · `λ` 없음) ⇒ **규율 65**\n");
			LogA("[mlt] 🧿         ⇒ ★ **한 판에 여섯 팔** — 같은 씨앗·세계·초기화 뽑기·채점 기준\n");
			LogA("[mlt] 🧿      ⭐ 입력은 여섯 팔 **모두 캡션**을 싣는다 ⇒ 갈리는 것은 **표적에 쓰나**뿐\n");
			LogA("[mlt] 🧿      ⭐ 그래서 팔 2(언어 X·8192)는 **212 의 ㈀ 과 같은 자리**다 ⇒ 배관 검산이 공짜다\n");
			LogA("[mlt] 🧿      🎯 표제 = **낙폭(언어 O)** · ⭐ 그 위 = **차의 차**(낙폭 O − 낙폭 X)\n");
			LogA("[mlt] 🧿      📌 부채 **D33** — 212 는 `_LangSymOn` 때문에 팔 2·3 의 **입력이 심볼**이었다\n");
			LogA("[mlt] 🧿         ⇒ 213 은 그것을 **껐다**(값 부호화 하나로 통일 — 211b 가 값 > 심볼)\n");
		}
		if (_ctxSweep && !_l2ctx)
		{
			LogA("[mlt] 🧿   ⭐ **문맥 스윕**(`-mltctxsweep` · 회차 194 · 칸 1 조건 ㉠)\n");
			LogA("[mlt] 🧿      팔 = 문맥 **%u · %u · %u** ⇒ ★ 나머지는 전부 같다(축 14 · 낱말 없음)\n",
				kCtxOf[0], kCtxOf[1], kCtxOf[2]);
			LogA("[mlt] 🧿      ⚠️ 8192 만 재고 187·193 의 숫자와 견주면 **규율 65**(그 자리의 값)에 걸리고,\n");
			LogA("[mlt] 🧿         두 점으로 8192 를 외삽하면 **규율 83**(188 → 190 에서 이미 깨졌다)이다\n");
			LogA("[mlt] 🧿         ⇒ ⭐ **세 점을 한 자리에서 실측**한다 ⇒ 곡선이 **관측**이 된다\n");
			LogA("[mlt] 🧿      ⭐ **수집은 씨앗당 1회**(최대치 %u)이고 팔 셋이 그것을 **공유**한다\n", kNCtxMax);
			LogA("[mlt] 🧿         ⇒ 팔은 **앞 `_armCtx` 개**만 올린다(배치가 스텝-메이저라 prefix 가 성립)\n");
			LogA("[mlt] 🧿      ⚠️⚠️ **걸음이 표본의 천장이다** — 모델이 보는 문맥은 **min(문맥, %u)** 다\n",
				_steps * kBatch);
			LogA("[mlt] 🧿         ⇒ ★ 8192 의 실효 배수는 16 이 아니라 **%.1f배** ⇒ **판정문에 적는다**\n",
				(double)(_steps * kBatch) / (double)kNCtxBase);
			LogA("[mlt] 🧿         ⚠️ 걸음을 같이 올리지 **않는다** — 손잡이 둘을 한 번에 돌리는 것이다\n");
			LogA("[mlt] 🧿      🔮 손계산 예측: 187(2048) +1.1%% ↔ 193(512) +1.72%% ⇒ 4배마다 0.64배\n");
			LogA("[mlt] 🧿         ⇒ 8192 ≈ **+0.70%%** ⇒ ⛔ **표제는 안 선다**(그리고 그것이 ㉠′ 을 강제한다)\n");
		}
		if (_steps != kStepsBase)
		{
			LogA("[mlt] 🧿   ⭐ **걸음 %u**(`-mltsteps4` · 회차 186 · 기본 %u 의 %u배)\n",
				_steps, kStepsBase, _steps / kStepsBase);
			LogA("[mlt] 🧿      ★ 근거: **변화만 학습**이면 손실 표적이 21.1 → **6.8**(32%%)라\n");
			LogA("[mlt] 🧿        800걸음이 **유효 ~256걸음** 상당이다 ⇒ %u 면 유효 ~%u\n",
				_steps, (_steps * 32u) / 100u);
			LogA("[mlt] 🧿      ⚠️ 회차 144 는 *\"걸음은 주범이 아니다\"* 를 냈지만 **전체 학습**에서였다(규율 58)\n");
			LogA("[mlt] 🧿      ⚠️⚠️ 그리고 `q` 축은 **이미 끝까지 갔다** — q=0 에서 P3 가 +3.2%% 뿐이라\n");
			LogA("[mlt] 🧿         q>0 은 더 나쁘다 ⇒ ★ **가중 스윕을 만들 필요가 없어졌다**(규율 21)\n");
		}
		if (_qChg)
		{
			LogA("[mlt] 🧿   ⭐ **㉷ 학습 손실도 변화 쪽으로**(`-mltqchg` · 회차 185)\n");
			LogA("[mlt] 🧿      ⚠️⚠️ **회차 141 의 규약을 일부러 어긴다** — *\"학습 풀은 안 건드린다\"*\n");
			LogA("[mlt] 🧿      ★ 회차 144 가 그것을 어겨 **범인이 손실 가중임**을 밝혔다\n");
			LogA("[mlt] 🧿        (변화 CE 2.7802 → **1.7389** · 도달률 **+156%%** · 12/12)\n");
			LogA("[mlt] 🧿      🎯 표제 = ***「변화만 학습」이 칸 1 닫힘 조건 ㉠ 을 만족시키나***\n");
			LogA("[mlt] 🧿      ⚠️ 유보 — **지속을 안 배우면 「경험 학습」이 반쪽**이다\n");
			LogA("[mlt] 🧿         ⇒ ★ `D11` 의 지속 CE 를 **파레토로 같이 본다**(판정에는 안 쓴다)\n");
			LogA("[mlt] 🧿         ⇒ ⭐ 진짜 처방은 **가중**이고 그것이 **다음 회차**다\n");
		}
		LogA("[mlt] 🧿   ⚠️ 계급이 250 → %u 라 CE 절대값을 회차 1~180 과 견주지 않는다(규율 58)\n", kN);
		if (_seeds > 1u && _seeds < kSeedsMax)
			LogA("[mlt] 🧿   ⭐ **파일럿 %u씨앗** — ★ 재는 것은 **그 자리의 `σ_diff`** 다(규율 65)\n", _seeds);
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

	// ── 한 물체의 칸 ──────────────────────────────────────────────
	static uint32 _Cell(const MLTShapeView& v)
	{
		const float S = (float)MLTWorldCfg::kSide;
		if (!(v.sx >= 0.0f && v.sx < S && v.sy >= 0.0f && v.sy < S)) return _NoneC();
		return ((uint32)v.sy / kPx) * kGrid + ((uint32)v.sx / kPx);
	}

	// ── ⭐ 회차 183 — **방향 계급**(0 = 정지 · 1..8 = 8방위 · 9 = 없음) ──
	//   ⚠️ 직전 화면 위치가 필요하다 ⇒ 없으면 「정지」(0)로 둔다(첫 시각).
	//   ★ 회차 182 가 문턱 **1.00 픽셀**을 4/4 중 최선으로 골랐다.
	static uint32 _DirOfShape(const MLTShapeView& v, float pxv, float pyv, bool hadPrev)
	{
		const float S = (float)MLTWorldCfg::kSide;
		if (!(v.sx >= 0.0f && v.sx < S && v.sy >= 0.0f && v.sy < S)) return kDirCls - 1u;
		if (!hadPrev) return 0u;
		const float dx = v.sx - pxv, dy = v.sy - pyv;
		const float sp = Sqrt(dx * dx + dy * dy);
		if (sp < kDirThr) return 0u;
		float a = Atan2(dy, dx);
		const float twoPi = 6.28318531f;
		if (a < 0.0f) a += twoPi;
		return 1u + ((uint32)((a / twoPi) * 8.0f + 0.5f) % 8u);
	}

	// ⭐ 회차 226 — 🆕 **efference copy**(재유입 상쇄)의 최소 형태
	//   ⚙️ 폰 홀스트(1950): 동물이 **자기 움직임이 만든 감각 변화**를 세상의 변화와 가르는 길은
	//     하나다 — **운동 명령의 사본**을 감각 쪽으로 보내 미리 상쇄한다.
	//     ★ 눈을 움직여도 세상이 안 흔들리는 이유고, 스스로는 간지럼을 못 타는 이유다.
	//   ⚠️⚠️ 그런데 **사본은 「내가 명령을 낼 때만」 생긴다** ⇒ 221~224 는 행동을 **입력 슬롯으로
	//     옆에서 넣었을 뿐**이고 표적이 아니었다(`_eTgt = _Inv()`) ⇒ ★ 오귀속률 0 이 **예상된 결과**다.
	//   ⇒ ⭐ **P5 를 열지 않고 사본을 만드는 길**: 행동으로 **「감각 결과」를 예측하게** 한다.
	//     ★ 최소 형태 = ***내 명령이 화면 전체를 어느 쪽으로 미나***(방향 10 계급).
	//   ✅ **D7 위반이 아니다** — 입력은 `dYaw` **값**이고 표적은 **화면 흐름 방향**(다른 것).
	//   ⭐ 그리고 **슬롯 표적과 어휘가 같다**(방향 10) ⇒ 212 처럼 출력 어휘를 안 늘린다(추가 비용 0).
	//   ★ 흐름 = **보이는 물체들의 화면 이동 평균**. 카메라가 지배하므로 그것이 곧 행동의 결과다
	//     (220 실측: 궤도 세계에서도 화면 운동의 대부분이 카메라다).
	static uint32 _FlowDir(float ax, float ay, uint32 n)
	{
		if (n == 0u) return kDirCls - 1u;                     // 없음
		const float dx = ax / (float)n, dy = ay / (float)n;
		const float sp = Sqrt(dx * dx + dy * dy);
		if (sp < kDirThr) return 0u;                          // 정지
		float a = Atan2(dy, dx);
		const float twoPi = 6.28318531f;
		if (a < 0.0f) a += twoPi;
		return 1u + ((uint32)((a / twoPi) * 8.0f + 0.5f) % 8u);
	}

	// ── `maxV` 원값 — 회차 162 의 그것(최대 화면 속력) ──────────────
	static float _MaxV(const MLTWorld& w)
	{
		MLTShapeView vs[MLTWorldCfg::kShapes];
		const int nv = w.VisibleShapes(vs, MLTWorldCfg::kShapes);
		float best = kMvUnknown;
		for (int i = 0; i < nv; ++i)
		{
			const int ix = vs[i].index;
			if (ix < 0 || ix >= MLTWorldCfg::kShapes) continue;
			if (_pv2[ix])
			{
				const float dx = vs[i].sx - _px2[ix], dy = vs[i].sy - _py2[ix];
				const float sp = Sqrt(dx * dx + dy * dy);
				if (sp > best) best = sp;
			}
			_px2[ix] = vs[i].sx; _py2[ix] = vs[i].sy; _pv2[ix] = true;
		}
		return best;
	}

	// ── ⭐ ㈄ 「어디로」 원값 — **자율 도형의 이동 방향**(라디안 → 0..1) ──
	//   ⚠️ 움직임이 문턱 아래면 `kMvUnknown`(계급 0 = 「안 움직임」)
	static float _DirOf(const MLTWorld& w, float* prvX, float* prvY, bool* prvV)
	{
		MLTShapeView vs[MLTWorldCfg::kShapes];
		const int nv = w.VisibleShapes(vs, MLTWorldCfg::kShapes);
		float bestSp = 0.0f, bestDir = kMvUnknown;
		for (int i = 0; i < nv; ++i)
		{
			const int ix = vs[i].index;
			if (ix < 0 || ix >= kAuto) continue;         // ⭐ **자율만**
			if (prvV[ix])
			{
				const float dx = vs[i].sx - prvX[ix], dy = vs[i].sy - prvY[ix];
				const float sp = Sqrt(dx * dx + dy * dy);
				if (sp > bestSp && sp > 0.05f)          // 문턱 — 수치 잡음 배제
				{
					bestSp = sp;
					float a = Atan2(dy, dx);            // −π..π
					const float twoPi = 6.28318531f;
					if (a < 0.0f) a += twoPi;
					bestDir = a / twoPi;                // 0..1
				}
			}
			prvX[ix] = vs[i].sx; prvY[ix] = vs[i].sy; prvV[ix] = true;
		}
		return bestDir;
	}

	// ── 원값 → 8분위 계급(0 = 없음 · 1..8) — 회차 162 의 그 규칙 ────
	static void _CountWord(const Array<float>& raw, Array<uint32>& w)
	{
		Array<float> v; v.Reset(0);
		for (uint32 i = 0; i < raw.Count(); ++i) if (raw[i] > kMvUnknown * 0.5f) v.Add(raw[i]);
		// 삽입 정렬(표본이 4096 이라 충분)
		for (uint32 i = 1; i < v.Count(); ++i)
		{
			const float x = v[i]; uint32 j = i;
			while (j > 0u && v[j - 1u] > x) { v.Data()[j] = v[j - 1u]; --j; }
			v.Data()[j] = x;
		}
		float bnd[kWordCls - 2u];
		for (uint32 k = 0; k < kWordCls - 2u; ++k)
		{
			if (v.Count() == 0u) { bnd[k] = 0.0f; continue; }
			const uint32 idx = (v.Count() * (k + 1u)) / (kWordCls - 1u);
			bnd[k] = v[(idx >= v.Count()) ? (v.Count() - 1u) : idx];
		}
		w.Reset(0);
		for (uint32 i = 0; i < raw.Count(); ++i)
		{
			if (!(raw[i] > kMvUnknown * 0.5f)) { w.Add(0u); continue; }
			uint32 c = 1u;
			for (uint32 k = 0; k < kWordCls - 2u; ++k) if (raw[i] > bnd[k]) c = k + 2u;
			w.Add(c);
		}
	}

	static void _Shuffle(const Array<uint32>& in, Array<uint32>& out, uint32 salt)
	{
		out.Reset(0);
		for (uint32 i = 0; i < in.Count(); ++i) out.Add(in[i]);
		uint32 rs = _seed * 2654435761u + salt;
		for (uint32 i = out.Count(); i > 1u; --i)
		{
			rs = rs * 1664525u + 1013904223u;
			const uint32 j = rs % i;
			const uint32 tmp = out[i - 1u]; out.Data()[i - 1u] = out[j]; out.Data()[j] = tmp;
		}
	}

	// ⚠️ 런타임 축 수를 쓴다(배열은 상한으로 잡혀 있다)
	static uint32 _Row13(uint32 ctx, uint32 t, uint32 a)
	{
		const uint32 k = ctx / kBatch, b = ctx % kBatch;
		return k * _Rows() + b * _Ctx() + t * _Ax() + a;
	}
	// ⭐ 슬롯/상태 축의 시작이 **낱말 축 수만큼** 밀린다
	static uint32 _RowState(uint32 ctx, uint32 t, uint32 a) { return _Row13(ctx, t, _nw + a); }
	static uint32 _RowSlot(uint32 ctx, uint32 t, uint32 j)  { return _Row13(ctx, t, _nw + kStateAx + j); }
	// ⭐ 221 — 행동 축은 **맨 뒤**(그래서 위 둘이 안 밀린다)
	static uint32 _RowAct(uint32 ctx, uint32 t)             { return _Row13(ctx, t, _nw + kAx13); }

	// ══════════════════════════════════════════════════════════════
	// 🌍 수집 — ⭐ 세계에서 바로 풀 배열을 만든다(한 틱에 다 돈다)
	// ══════════════════════════════════════════════════════════════
	static void _Gather()
	{
		for (uint32 c = 0; c < 2u; ++c)
		{
			const uint32 nCtx = (c == 0u) ? _nCtx : kPtCtx;
			const uint32 epi  = (c == 0u) ? kTrainEpi : kPtEpi;
			// ⚠️⚠️⚠️ **상한이 아니라 런타임 크기로 잡는다**(회차 190 에서 실측으로 밟았다):
			//   ⛔ `kRows14` 를 21축 상한(1344)으로 바꾸자 **축 14 모드**에서 배열이 너무 커져
			//     `UploadPool` 의 `need = nSteps × _rows`(229,376)와 안 맞아 **조용히 false**.
			//   ★ `_nw` 는 **배너에서 확정**되므로(회차 189 의 고침) 수집 시점에 이미 정해져 있다
			//     ⇒ ⭐ 런타임 크기가 **안전하고 낭비도 없다**.
			//   ⚠️ 이것이 이 회차의 **다섯 번째** 배관 사고다 — ★ 원인은 하나:
			//     *"「낱말이 하나」 가정"* 과 *"배열을 상한으로"* 가정이 **충돌**했다.
			const uint32 n = (nCtx / kBatch) * _Rows();
			_cVal[c].Reset(0); _cSym[c].Reset(0); _cTgt[c].Reset(0);
			for (uint32 i = 0; i < n; ++i) { _cVal[c].Add(0.0f); _cSym[c].Add(0.0f); _cTgt[c].Add(_Inv()); }
			Array<float>& mvR  = (c == 0u) ? _mvTrRaw : _mvTeRaw;
			Array<float>& dirR = (c == 0u) ? _dirTrRaw : _dirTeRaw;
			mvR.Reset(0); dirR.Reset(0);
			// 오라클·어느물체는 표적에서 나오므로 아래에서 따로 만든다
			Array<uint32>& wCh = (c == 0u) ? _wChTr : _wChTe;
			Array<uint32>& wWh = (c == 0u) ? _wWhTr : _wWhTe;
			wCh.Reset(0); wWh.Reset(0);
			// ⭐ 회차 189 — 슬롯마다 판과 축 하나 판
			{
				Array<uint32>& wAu = (c == 0u) ? _wAuTr : _wAuTe;
				Array<uint32>& wA1 = (c == 0u) ? _wA1Tr : _wA1Te;
				wAu.Reset(0); wA1.Reset(0);
				// ⭐ 회차 200 — 캡션
				Array<uint32>& wNm0 = (c == 0u) ? _wNmTr : _wNmTe;
				wNm0.Reset(0);
			}
			uint32 chgTot = 0u, tgtTot = 0u;
			double goalNum = 0.0;

			for (uint32 ctx = 0; ctx < nCtx; ++ctx)
			{
				// ⚠️⚠️ **규율 76** — 모드마다 세계가 다르다(칸 = 180 의 ㈄ · 방향 = 182 의 ㈂)
				// ⭐ 회차 199 — **세계 모드**(`-mltw2 <n>` · 198 이 궤도를 찾았다)
				//   ⚠️ `SetWorld2` 는 `Reset` **보다 먼저** 부른다(Reset 이 그것을 안 건드린다).
				MLTWorld w; w.SetWorld2(_w2);
				// ⚖️✂️ 회차 240 — **세계가 좁히는 판**(`-mltenergy` · `-mltprunebud <n>` = n/100)
				//   ⚠️⚠️ **팔로 못 둔다** — 세계가 팔마다 다르면 표적이 달라져 **짝지은 차가 무너진다**
				//     ⇒ ★ **판을 나눠 돌린다**(211 이 `_nw` 에서 쓴 그 관용구).
				//   ⚠️ 기본 둘 다 꺼짐 ⇒ 회차 1~239 가 **비트 동일**이다(규율 58).
				if (_enOn) w.SetEnergy(true);
				if (_prBud > 0.0f) { w.SetPrune(true); w.SetPruneBudget(_prBud); }
				// ⭐⭐ 243 — 감쇠 세기(음수면 세계의 기본 0.35 = 241 이 쓴 값 ⇒ 241 은 비트 동일)
				if (_slow > 0.0f) w.SetEnergySlow(_slow);
				w.Reset(_seed, epi + ctx, MLTWorldCfg::kHoldMid, kAuto, _Dt(), _Amp());
				// ⭐ 회차 183 — 방향 계급은 **직전 화면 위치**가 필요하다(물체별)
				float spx[MLTWorldCfg::kShapes], spy[MLTWorldCfg::kShapes];
				bool  spv[MLTWorldCfg::kShapes];
				for (int i = 0; i < MLTWorldCfg::kShapes; ++i) spv[i] = false;
				for (int i = 0; i < MLTWorldCfg::kShapes; ++i) { _pv2[i] = false; }
				float dpx[MLTWorldCfg::kShapes], dpy[MLTWorldCfg::kShapes];
				bool  dpv[MLTWorldCfg::kShapes];
				for (int i = 0; i < MLTWorldCfg::kShapes; ++i) dpv[i] = false;
				// 슬롯별 물체 번호와 칸 — 시각을 넘어 이어진다
				uint32 slotObj[kTime][kSlots], slotCell[kTime][kSlots];
				for (uint32 t = 0; t < kTime; ++t)
					for (uint32 j = 0; j < kSlots; ++j) { slotObj[t][j] = 0xFFFFFFFFu; slotCell[t][j] = _NoneC(); }

				for (uint32 t = 0; t < kTime; ++t)
				{
					// ⭐ 회차 221 — **행동값은 굴리기 전에 정해진다**(`_Advance` 가 `_act` 를 쓴다)
					//   ★ `ActAt(StepNo())` 이 곧 「이 걸음에 적용될 행동」이고 **`_hold` 규약을 포함**한다
					//     ⚠️ 하네스가 `_hold` 를 흉내내면 반드시 갈린다(세계 파일이 그렇게 적어 뒀다).
					const float actY = _actOn ? (w.ActAt(w.StepNo()).dYaw / 0.6f) : 0.0f;
					w.Step();
					if (_actOn)
					{
						const uint32 r = _RowAct(ctx, t);
						_cSym[c].Data()[r] = _ActSym();
						_cVal[c].Data()[r] = actY;        // [-1, 1] 로 정규화한 좌우 회전 명령
						_cTgt[c].Data()[r] = _Inv();      // ⚠️ 행동은 **표적이 아니다**(P4 의 그 규약)
					}
					// ── 상태 5축 ────────────────────────────────
					const MLTState st = w.State();
					for (uint32 a = 0; a < kStateAx; ++a)
					{
						const uint32 r = _RowState(ctx, t, a);
						_cSym[c].Data()[r] = (float)a;
						_cVal[c].Data()[r] = st.Axis((int)a);
						_cTgt[c].Data()[r] = _Inv();      // IgnoreTgt (212: 한 곳에서 온다)
					}
					// ── 물체 슬롯 — ⭐ 보이는 것 중 **번호 작은 8개** ──
					MLTShapeView vs[MLTWorldCfg::kShapes];
					const int nv = w.VisibleShapes(vs, MLTWorldCfg::kShapes);
					uint32 k = 0u;
					// ⭐ 226 — **화면 흐름**(efference copy 의 표적) — ⚠️ `spx` 갱신 **전에** 누적한다
					float flx = 0.0f, fly = 0.0f; uint32 fln = 0u;
					for (int idx = 0; idx < MLTWorldCfg::kShapes && k < kSlots; ++idx)
					{
						for (int i = 0; i < nv; ++i)
						{
							if (vs[i].index != idx) continue;
							// ⭐ 회차 183 — 방향 모드면 계급이 **이동 방향**이다
							const uint32 cell = _dirOn
								? _DirOfShape(vs[i], spx[idx], spy[idx], spv[idx])
								: _Cell(vs[i]);
							if (spv[idx]) { flx += vs[i].sx - spx[idx]; fly += vs[i].sy - spy[idx]; ++fln; }
							spx[idx] = vs[i].sx; spy[idx] = vs[i].sy; spv[idx] = true;
							if (cell == _NoneC()) break;               // 화면 밖 ⇒ 슬롯 안 준다
							slotObj[t][k] = (uint32)idx;
							slotCell[t][k] = cell;
							const uint32 r = _RowSlot(ctx, t, k);
							_cSym[c].Data()[r] = (float)(kStateAx + cell);
							// 값 = 깊이 정규화 — ⚠️ 「얼마나 가까운가」(불투명 스칼라 하나)
							const float d = (vs[i].d > 0.1f) ? vs[i].d : 0.1f;
							_cVal[c].Data()[r] = (1.0f / d) * 2.0f - 1.0f;
							++k;
							break;
						}
					}
					// ⭐ 226 — **흐름을 「한 시각 뒤 자리」에 표적으로** 쓴다
					//   ⚠️⚠️ 같은 자리(시각 `t`)에 쓰면 **자명하다** — 그 시각의 슬롯 방향이
					//     이미 입력에 있으므로 흐름을 평균만 하면 나온다.
					//   ⇒ ★ 슬롯 표적과 **같은 시간 규약**으로 둔다: 시각 `t-1` 의 행동 축 표적 =
					//     `flow(t-1 → t)` ⇒ ***그 시각의 행동값이 실제로 도움이 되는 자리다.***
					if (_actOn && t > 0u)
						_cTgt[c].Data()[_RowAct(ctx, t - 1u)] = (float)_FlowDir(flx, fly, fln);
					// ── 낱말 원값 ────────────────────────────────
					mvR.Add(_MaxV(w));
					dirR.Add(_DirOf(w, dpx, dpy, dpv));
					// ── 표적 = 「그 물체의 **다음 칸**」 ─────────────
					//   ⚠️ 직전 시각의 슬롯에 **그 물체가 있었으면** 그 자리에 표적을 쓴다
					if (t > 0u)
					{
						for (uint32 j = 0; j < kSlots; ++j)
						{
							const uint32 obj = slotObj[t - 1u][j];
							if (obj == 0xFFFFFFFFu) continue;
							// 그 물체의 지금 칸을 찾는다(슬롯이 밀렸을 수 있다)
							uint32 nowCell = _NoneC();
							for (uint32 j2 = 0; j2 < kSlots; ++j2)
								if (slotObj[t][j2] == obj) { nowCell = slotCell[t][j2]; break; }
							const uint32 r = _RowSlot(ctx, t - 1u, j);
							_cTgt[c].Data()[r] = (float)nowCell;
							++tgtTot;
							if (nowCell != slotCell[t - 1u][j]) ++chgTot;
							else goalNum += 1.0;   // 학습 0 예측기(「그 자리」)가 맞은 수
						}
					}
				}
				// ── 낱말 둘(표적에서 나오는 것) ────────────────────
				for (uint32 t = 0; t < kTime; ++t)
				{
					uint32 clsCh = 0u, clsWh = 0u;
					if (t + 1u < kTime)
					{
						for (uint32 j = 0; j < kSlots; ++j)
						{
							if (slotObj[t][j] == 0xFFFFFFFFu) continue;
							uint32 nowCell = _NoneC();
							for (uint32 j2 = 0; j2 < kSlots; ++j2)
								if (slotObj[t + 1u][j2] == slotObj[t][j]) { nowCell = slotCell[t + 1u][j2]; break; }
							if (nowCell == slotCell[t][j]) continue;   // 지속 — 건너뛴다
							clsCh = 1u + (nowCell * (kWordCls - 1u)) / _N();
							clsWh = 1u + j;
							break;
						}
					}
					// ⭐ 회차 200 — **캡션 두 자리**: 「이번에 바뀌는 물체 둘의 이름」
					//   ★ 어휘 = 0 없음 · 1..8 = 슬롯 번호 + 1 ⇒ **같은 이름이 두 자리 모두에 온다**
					//   ⚠️ 방향은 안 넣는다(표적 자신 = D7) · ⚠️ 자리가 둘이라 **최대 둘**만 말한다
					if (_lang)
					{
						uint32 nm[kLNwMax]; for (uint32 k = 0; k < _lnw; ++k) nm[k] = 0u;
						uint32 got = 0u;
						if (t + 1u < kTime)
							for (uint32 j = 0; j < kSlots && got < _lnw; ++j)
							{
								if (slotObj[t][j] == 0xFFFFFFFFu) continue;
								uint32 nowCell = _NoneC();
								for (uint32 j2 = 0; j2 < kSlots; ++j2)
									if (slotObj[t + 1u][j2] == slotObj[t][j]) { nowCell = slotCell[t + 1u][j2]; break; }
								if (nowCell == slotCell[t][j]) continue;   // 지속 — 이름을 안 부른다
								// ⭐⭐⭐ 회차 255 — 낱말을 **슬롯 번호 ↔ 물체 정체성** 중에서 고른다(`-mltlid`).
								//   ⚠️ 슬롯 번호는 *"보이는 물체 중 몇 번째"* 라 **매 시각 다른 물체를 가리킨다**
								//     (밀림 55.2% · 회차 55) ⇒ 254 가 그것을 「지시대상의 불안정」으로 잡았다.
								//   ⛔ **그런데 정체성으로 바꾸니 내렸다**(`d̄` 0.61배 · `Î` 7.7배 하락) —
								//     ★ 표적이 **「그 슬롯의 다음 방향」**이라 **슬롯 번호가 표적의 색인 그 자체**였다.
								//   ⇒ 🧾 ***낱말이 위치였던 것은 결함이 아니라 표적과 정렬된 것이었다.***
								nm[got] = 1u + (_lidOn ? slotObj[t][j] : j); ++got;
							}
						Array<uint32>& wNm = (c == 0u) ? _wNmTr : _wNmTe;
						for (uint32 k = 0; k < _lnw; ++k) wNm.Add(nm[k]);
					}
					// ⚠️⚠️⚠️ **슬롯마다 모드에서는 오라클도 슬롯마다여야 한다**(회차 189 실측):
					//   ⛔ 축 하나 배열을 8축 색인으로 읽으면 범위 밖이 `kConstCls` 로 채워져
					//     ***오라클이 섞음보다 나빠진다***(1.681 ↔ 1.467) ⇒ **분모가 사라진다.**
					//   ★ 그래서 `_slotWord` 면 **그 슬롯의 다음 방향**을 슬롯마다 적는다(천장의 정의).
					if (_slotWord)
					{
						for (uint32 j = 0; j < kSlots; ++j)
						{
							const uint32 obj = slotObj[t][j];
							uint32 c2 = 0u;
							if (obj != 0xFFFFFFFFu && t + 1u < kTime)
							{
								uint32 nowCell = _NoneC();
								for (uint32 j2 = 0; j2 < kSlots; ++j2)
									if (slotObj[t + 1u][j2] == obj) { nowCell = slotCell[t + 1u][j2]; break; }
								if (nowCell != _NoneC()) c2 = 1u + (nowCell * (kWordCls - 1u)) / _N();
							}
							wCh.Add(c2);
						}
						wWh.Add(clsWh);   // ⚠️ 이 모드에서는 안 쓰는 팔이지만 길이를 유지한다
					}
					else { wCh.Add(clsCh); wWh.Add(clsWh); }
					// ⭐ 회차 189 — **슬롯마다** 「그 물체가 자율인가」
					//   계급 3: 0 = 그 슬롯이 비었다 · 1 = **피동** · 2 = **자율**
					//   ★ 자율이면 다음 방향이 **공통 흐름을 벗어나고**, 피동이면 그 흐름이라
					//     **상태 차분으로 예측된다** ⇒ 낱말이 *"이 슬롯은 예측 가능한가"* 를 말한다.
					//   ⚠️ 이것은 **표적(다음 방향)이 아니다** ⇒ 새는 말이 아니다(등록문의 원시성 검사).
					//   ⚠️ 그리고 **자율성은 세계의 은닉 성질**이라 상태 5축에서 유도되지 않는다
					//     (`mltworld` ⑨ · 회차 142 가 기각한 그 부류가 아니다).
					{
						Array<uint32>& wAu = (c == 0u) ? _wAuTr : _wAuTe;
						for (uint32 j = 0; j < kSlots; ++j)
						{
							const uint32 obj = slotObj[t][j];
							uint32 cls = 0u;
							if (obj != 0xFFFFFFFFu) cls = ((int)obj < kAuto) ? 2u : 1u;
							wAu.Add(cls);
						}
						// ⭐ **축 하나 판**(대조) — 「자율이 앉은 슬롯 중 가장 작은 번호 + 1」
						//   ★ ㈂(슬롯마다) ↔ ㈄(이것)이 ***희석 제거의 값***을 직접 준다(규율 67).
						Array<uint32>& wA1 = (c == 0u) ? _wA1Tr : _wA1Te;
						uint32 first = 0u;
						for (uint32 j = 0; j < kSlots; ++j)
						{
							const uint32 obj = slotObj[t][j];
							if (obj != 0xFFFFFFFFu && (int)obj < kAuto) { first = 1u + j; break; }
						}
						// ⚠️ **슬롯마다 배열**로 쓴다 — 슬롯 0 에만 값 · 나머지는 상수
						//   ★ 그래야 축 개수가 표제 팔과 **같다**(교란이 원리적으로 없다)
						for (uint32 j = 0; j < kSlots; ++j) wA1.Add((j == 0u) ? first : kConstCls);
					}
				}
			}
			if (c == 1u)
			{
				_nChg[_seed] = (double)chgTot / (double)nCtx;
				_nTgt[_seed] = (double)tgtTot / (double)nCtx;
				// ⭐ 목표선 = 학습 0 예측기(「다음 칸 = 지금 칸」)의 CE 하한 근사가 아니라
				//   ⚠️ **그 예측기의 정확도**만 준다 ⇒ 진짜 목표선은 아래 `_GoalCE` 가 조건부로 잰다
			}
			_CountWord(mvR, (c == 0u) ? _wMvTr : _wMvTe);
			_CountWord(dirR, (c == 0u) ? _wDirTr : _wDirTe);
		}
		_GoalCE();
		_st = kBodyInit;
	}

	// ── ⭐ 목표선 — **학습 0 최선** = `H(다음 칸 | 지금 칸)` ──────────
	//   ⚠️ 회차 180 이 **다른 길**(세계만 · 물체별 직전 칸)로 0.3678 을 냈다 ⇒ ★ 두 값이 만나야 한다(규율 68).
	//   ★ 여기서는 **시험 코퍼스의 변화 표적만** 채점 대상이므로 그것에 맞춰 잰다.
	static void _GoalCE()
	{
		// 결합 히스토그램 [지금 칸][다음 칸] — 변화만
		Array<uint32> jt; jt.Reset(0);
		const uint32 NV = _N();
		for (uint32 i = 0; i < NV * NV; ++i) jt.Add(0u);
		Array<uint32> mp; mp.Reset(0);
		for (uint32 i = 0; i < NV; ++i) mp.Add(0u);
		uint32 tot = 0u;
		for (uint32 ctx = 0; ctx < kPtCtx; ++ctx)
			for (uint32 t = 0; t < kTime; ++t)
				for (uint32 j = 0; j < kSlots; ++j)
				{
					const uint32 r = _RowSlot(ctx, t, j);
					const float tf = _cTgt[1][r];
					if (!(tf >= 0.0f && tf < (float)_N())) continue;
					const uint32 tid = (uint32)tf;
					const float sf = _cSym[1][r] - (float)kStateAx;
					if (!(sf >= 0.0f && sf < (float)_N())) continue;
					const uint32 pid = (uint32)sf;
					if (pid == tid) continue;                     // ⚠️ 변화만(채점하는 자와 같게)
					jt.Data()[pid * NV + tid] += 1u;
					mp.Data()[pid] += 1u; ++tot;
				}
		double hc = 0.0;
		if (tot > 0u)
		{
			const double N = (double)tot;
			for (uint32 p = 0; p < NV; ++p)
			{
				if (mp[p] == 0u) continue;
				const double Np = (double)mp[p];
				double hp = 0.0;
				for (uint32 q = 0; q < NV; ++q)
				{
					const uint32 n = jt[p * NV + q];
					if (n == 0u) continue;
					const double pr = (double)n / Np;
					hp += -pr * (double)Log((float)pr);
				}
				hc += (Np / N) * hp;
			}
		}
		_goal[_seed] = hc;
	}

	// ── ⭐ `Î(낱말 ; 변화 표적)` — 회차 175 의 자 ────────────────────
	// ══════════════════════════════════════════════════════════════════
	// ⭐ 회차 210 — **언어 모드의 `Î` 를 고친다**(209 의 해석에 구멍이 있었다)
	// ══════════════════════════════════════════════════════════════════
	//   ⛔⛔ **`_MutInfo` 가 언어 모드에서 쓰레기를 냈다** — `_nw != 1` 이면 **stride `kSlots`(8)**
	//     로 읽는데 캡션은 **stride `_lnw`(2)** 다 ⇒ ★ 엉뚱한 자리를 낱말로 짝지었다.
	//     ⇒ ⚠️ **같은 계열 함정의 다섯 번째**다(189·200·203·205·210) — 공용 규율 16.
	//   ⛔⛔⛔ 그리고 **209 의 활용률에 구멍이 있었다**: 분모가 **오라클 낱말**(= 정답)이고
	//     분자가 **캡션**(= 어느 물체가 바뀌나)이다 ⇒ ★ ***둘은 다른 낱말이다.***
	//     ⇒ ⇒ 4.7% 가 *"몸통이 못 쓴다"* 가 아니라 **캡션의 정보가 적어서**일 수 있다.
	//   ⇒ ⭐ **규율 67 이 그 자리다**: *"분모는 `H(표적)` 이 아니라 **그 낱말의 정보천장**"*
	//     ⇒ ★ 진짜 활용률 = **몸통 `|d̄|` ÷ `Î(그 낱말; 변화 표적)`**(회차 177 의 그 자).
	//   ⭐ 캡션은 **자리 둘의 결합 낱말**(`w0·kLVocab + w1` = 81 계급)로 본다.
	//   ⚠️ 칸당 표본이 얇다(32768 ÷ 810 ≈ 40) ⇒ `Î` 가 **위로 편향**된다
	//     ⇒ ★ **섞은 팔의 `Î` 를 빼서** 쓴다(회차 175 의 `Î(−섞음)`).
	// ══════════════════════════════════════════════════════════════════
	// ⭐ 회차 211 — **자리 수에 안 흔들리는 `Î`**(이진 자)
	// ══════════════════════════════════════════════════════════════════
	//   ⛔ 210 의 자는 캡션을 **자리들의 결합 낱말**로 봤다 ⇒ 자리 2 면 81 계급이고
	//     ⚠️⚠️ **자리 4 면 6561 계급**이라 표본 32768 에 칸이 65610 개 ⇒ ***순수 편향***이다.
	//   ⇒ ⭐ **더 나은 자**: 캡션을 **그 슬롯에 대한 이진**으로 본다 —
	//     ***"이 슬롯의 이름이 캡션에 있나"*** ⇒ 계급이 **2** 이고 **자리 수와 무관**하다.
	//   ⇒ ★ 그리고 그것이 **캡션의 뜻과 정확히 맞는다**(「바뀌는 물체의 이름들」).
	//     ⭐ 자리를 늘리면 그 이진 정보가 **늘어난다**(더 많은 물체를 말하므로) ⇒ 자가 반응한다.
	//   ⇒ ⭐ 표본/칸 = 32768 ÷ 20 = **1638** ⇒ **편향이 거의 없다**(결합 자는 40 이었다).
	//   ⚠️ 결합 자도 **자리 2 에서만** 같이 찍는다 — 210 과의 다리를 남기려고(규율 68).
	static void _MutInfoLang(const Array<uint32>& wd, double& oI, double& oHt, double& oIbin)
	{
		// ── ⭐ 이진 자(주 자) — 「이 슬롯 이름이 캡션에 있나」 × 「그 슬롯의 다음 방향」
		{
			const uint32 NV0 = _N();
			Array<uint32> jb; jb.Reset(0);
			for (uint32 i = 0; i < 2u * NV0; ++i) jb.Add(0u);
			uint32 mb[2] = { 0u, 0u };
			Array<uint32> mt0; mt0.Reset(0);
			for (uint32 i = 0; i < NV0; ++i) mt0.Add(0u);
			uint32 tb = 0u;
			for (uint32 ctx = 0; ctx < kPtCtx; ++ctx)
				for (uint32 t = 0; t < kTime; ++t)
				{
					const uint32 w0 = (ctx * kTime + t) * _lnw;
					for (uint32 j = 0; j < kSlots; ++j)
					{
						const uint32 r = _RowSlot(ctx, t, j);
						const float tf = _cTgt[1][r];
						if (!(tf >= 0.0f && tf < (float)NV0)) continue;
						const uint32 tid = (uint32)tf;
						const float sf = _cSym[1][r] - (float)kStateAx;
						if (!(sf >= 0.0f && sf < (float)NV0)) continue;
						if ((uint32)sf == tid) continue;          // 변화만
						// ⚠️ 어휘 규약: 0 = 「없음」 · 1..8 = 슬롯 번호 + 1
						uint32 has = 0u;
						for (uint32 k = 0; k < _lnw; ++k)
						{
							const uint32 wi = w0 + k;
							if (wd.Count() > wi && wd[wi] == j + 1u) { has = 1u; break; }
						}
						jb.Data()[has * NV0 + tid] += 1u;
						mb[has] += 1u; mt0.Data()[tid] += 1u; ++tb;
					}
				}
			oIbin = 0.0;
			if (tb > 0u)
			{
				const double N0 = (double)tb;
				for (uint32 c = 0; c < 2u; ++c)
					for (uint32 i = 0; i < NV0; ++i)
					{
						const uint32 n = jb[c * NV0 + i];
						if (n == 0u) continue;
						const double pxy = (double)n / N0;
						const double px = (double)mb[c] / N0, py = (double)mt0[i] / N0;
						oIbin += pxy * (double)Log((float)(pxy / (px * py)));
					}
			}
		}
		// ── ⚠️ 결합 자 — **자리 2 에서만** 뜻이 있다(210 과의 다리)
		oI = 0.0; oHt = 0.0;
		if (_lnw != 2u) return;
		const uint32 NV = _N();
		const uint32 WC = kLVocab * kLVocab;      // 81 — 자리 둘의 결합
		Array<uint32> jt; jt.Reset(0);
		for (uint32 i = 0; i < WC * NV; ++i) jt.Add(0u);
		Array<uint32> mw; mw.Reset(0);
		for (uint32 i = 0; i < WC; ++i) mw.Add(0u);
		Array<uint32> mt; mt.Reset(0);
		for (uint32 i = 0; i < NV; ++i) mt.Add(0u);
		uint32 tot = 0u;
		for (uint32 ctx = 0; ctx < kPtCtx; ++ctx)
			for (uint32 t = 0; t < kTime; ++t)
			{
				const uint32 w0i = (ctx * kTime + t) * _lnw;
				const uint32 a0 = (wd.Count() > w0i) ? (wd[w0i] % kLVocab) : 0u;
				const uint32 a1 = (wd.Count() > w0i + 1u) ? (wd[w0i + 1u] % kLVocab) : 0u;
				const uint32 cls = a0 * kLVocab + a1;
				for (uint32 j = 0; j < kSlots; ++j)
				{
					const uint32 r = _RowSlot(ctx, t, j);
					const float tf = _cTgt[1][r];
					if (!(tf >= 0.0f && tf < (float)NV)) continue;
					const uint32 tid = (uint32)tf;
					const float sf = _cSym[1][r] - (float)kStateAx;
					if (!(sf >= 0.0f && sf < (float)NV)) continue;
					if ((uint32)sf == tid) continue;              // ⚠️ 변화만(채점과 같게)
					jt.Data()[cls * NV + tid] += 1u;
					mw.Data()[cls] += 1u; mt.Data()[tid] += 1u; ++tot;
				}
			}
		oI = 0.0; oHt = 0.0;
		if (tot == 0u) return;
		const double N = (double)tot;
		for (uint32 i = 0; i < NV; ++i)
		{
			if (mt[i] == 0u) continue;
			const double p = (double)mt[i] / N;
			oHt += -p * (double)Log((float)p);
		}
		for (uint32 c = 0; c < WC; ++c)
			for (uint32 i = 0; i < NV; ++i)
			{
				const uint32 n = jt[c * NV + i];
				if (n == 0u) continue;
				const double pxy = (double)n / N;
				const double px = (double)mw[c] / N, py = (double)mt[i] / N;
				oI += pxy * (double)Log((float)(pxy / (px * py)));
			}
	}

	static void _MutInfo(const Array<uint32>& wd, double& oI, double& oHt)
	{
		Array<uint32> jt; jt.Reset(0);
		const uint32 NV = _N();
		for (uint32 i = 0; i < kWordCls * NV; ++i) jt.Add(0u);
		Array<uint32> mw; mw.Reset(0);
		for (uint32 i = 0; i < kWordCls; ++i) mw.Add(0u);
		Array<uint32> mt; mt.Reset(0);
		for (uint32 i = 0; i < NV; ++i) mt.Add(0u);
		uint32 tot = 0u;
		for (uint32 ctx = 0; ctx < kPtCtx; ++ctx)
			for (uint32 t = 0; t < kTime; ++t)
			{
				for (uint32 j = 0; j < kSlots; ++j)
				{
					// ⚠️⚠️ **슬롯마다 모드에서는 그 슬롯의 낱말과 그 슬롯의 표적을 짝짓는다**
					//   ⛔ 회차 189 실측: 축 하나 색인으로 읽으면 **첫 슬롯만** 보고
					//     `Î(오라클)` 이 0.7988 → **0.0265** 로 떨어진다(전달율 51% → 2.5%).
					const uint32 wi = (_nw == 1u) ? (ctx * kTime + t)
					                              : ((ctx * kTime + t) * kSlots + j);
					const uint32 cls = (wd.Count() > wi) ? (wd[wi] % kWordCls) : 0u;
					const uint32 r = _RowSlot(ctx, t, j);
					const float tf = _cTgt[1][r];
					if (!(tf >= 0.0f && tf < (float)_N())) continue;
					const uint32 tid = (uint32)tf;
					const float sf = _cSym[1][r] - (float)kStateAx;
					if (!(sf >= 0.0f && sf < (float)_N())) continue;
					if ((uint32)sf == tid) continue;              // 변화만
					jt.Data()[cls * NV + tid] += 1u;
					mw.Data()[cls] += 1u; mt.Data()[tid] += 1u; ++tot;
				}
			}
		oI = 0.0; oHt = 0.0;
		if (tot == 0u) return;
		const double N = (double)tot;
		for (uint32 i = 0; i < NV; ++i)
		{
			if (mt[i] == 0u) continue;
			const double p = (double)mt[i] / N;
			oHt += -p * (double)Log((float)p);
		}
		for (uint32 cc = 0; cc < kWordCls; ++cc)
		{
			if (mw[cc] == 0u) continue;
			const double pw = (double)mw[cc] / N;
			for (uint32 i = 0; i < NV; ++i)
			{
				const uint32 n = jt[cc * NV + i];
				if (n == 0u) continue;
				const double pj = (double)n / N, pt = (double)mt[i] / N;
				oI += pj * (double)Log((float)(pj / (pw * pt)));
			}
		}
	}

	// ── 낱말을 축 0 에 얹고 시험 마스크를 건다 ───────────────────────
	// ⭐ 회차 192 — **슬롯 눈감기**: 그 시각의 슬롯 심볼·값을 비운다
	//   ★ 「없음」 계급을 심볼로 · 값은 0 ⇒ **상태 5축만 남는다**
	//   ⚠️ **표적은 안 건드린다** — 끊은 시각도 예측해야 한다(그것이 이 시험의 뜻이다)
	static void _Blind(uint32 dst, uint32 ctx, uint32 t)
	{
		for (uint32 j = 0; j < kSlots; ++j)
		{
			const uint32 r = _RowSlot(ctx, t, j);
			_eSym[dst].Data()[r] = (float)(kStateAx + _NoneC());
			_eVal[dst].Data()[r] = 0.0f;
		}
	}

	// ⭐ 회차 194 — **앞 `n` 개만 복사한다**(`Array` 에 잘라내기가 없다)
	//   ⚠️⚠️ 이것이 필요한 이유: `UploadPool` 이 `val.Count() != nSteps × _rows` 를 **정확히**
	//     요구한다(좋은 관문이라 안 푼다) ⇒ ★ 팔이 문맥의 앞부분만 쓰면 **배열도 그 크기**여야 한다.
	//   ⛔ 파일럿에서 그것을 밟았다: 8192 로 모은 배열에 `nSteps = 64` 를 주니 조용히 false.
	static void _CopyPrefix(Array<float>& dst, const Array<float>& src, uint32 n)
	{
		dst.Reset(0);
		const uint32 m = (n < src.Count()) ? n : src.Count();
		for (uint32 i = 0; i < m; ++i) dst.Add(src[i]);
	}

	static void _Expand(uint32 c, const Array<uint32>& word, uint32 mask)
	{
		// ⭐ 회차 194 — 학습 쪽은 **팔이 쓰는 문맥**(`_armCtx`)이다.
		//   ★ 스윕이 아니면 `_armCtx == _nCtx` 라 **여태와 완전히 같다**(배너에서 그렇게 세운다).
		const uint32 nCtx = (c == 0u) ? _armCtx : kPtCtx;
		const uint32 dst = (c == 0u) ? 0u : 1u;
		const uint32 nRow = (nCtx / kBatch) * _Rows();
		_CopyPrefix(_eVal[dst], _cVal[c], nRow);
		_CopyPrefix(_eSym[dst], _cSym[c], nRow);
		_CopyPrefix(_eTgt[dst], _cTgt[c], nRow);
		uint32 scored = 0u;
		for (uint32 ctx = 0; ctx < nCtx; ++ctx)
			for (uint32 t = 0; t < kTime; ++t)
			{
				// ⭐ 회차 189 — 낱말이 **`_nw` 개 축**이다(1 또는 슬롯 8)
				//   ★ 색인 규약: `_nw == 1` 이면 `word[ctx*kTime + t]`(여태와 같다) ·
				//     `_nw == kSlots` 이면 `word[(ctx*kTime + t)*kSlots + w]`(슬롯마다).
				//   ⚠️ 심볼은 **축마다 다른 값**을 준다(`_WordSym() - w`) — 그래야 몸통이
				//     「몇 번 슬롯의 낱말인가」를 가른다(`e_sym` 이 축마다 하나다).
				for (uint32 w = 0; w < _nw; ++w)
				{
					const uint32 wi = (_nw == 1u) ? (ctx * kTime + t)
					                              : ((ctx * kTime + t) * _nw + w);
					const uint32 cls = (word.Count() > wi) ? word[wi] : kConstCls;
					const uint32 r0 = _Row13(ctx, t, w);
					// ⭐ 회차 200 — **심볼 부호화**(언어) ↔ **값 부호화**(지금까지)
					//   ★ 언어면 내용이 **심볼**(이산 어휘 id)이고 값은 **0** 이다
					//     ⇒ ⭐ 같은 id 가 **두 자리 모두**에 올 수 있다 = **재사용이 실재한다**
					//   ⚠️ 값 부호화 팔은 여태와 **완전히 같다**(심볼 = 축 번호 · 값 = 정규화 계급)
					if (_lang && _LangSymOn(_arm))
					{
						_eSym[dst].Data()[r0] = _LangSym(cls);
						_eVal[dst].Data()[r0] = 0.0f;
					}
					else
					{
						_eVal[dst].Data()[r0] = ((float)cls / (float)(kWordCls - 1u)) * 2.0f - 1.0f;
						_eSym[dst].Data()[r0] = _WordSym() - (float)w;
					}
					// ⭐ 회차 212 — **L2: 낱말 축을 표적으로도 둔다**
					//   ⚠️⚠️ **학습 풀에만**(`c == 0u`) — ★ 시험을 건드리면 **채점이 두 가지를 잰다**
					//     (등록문의 «채점은 P 쪽만» · 규율 58)
					//   ⭐ `λ` 는 **확률 마스크**다 — 기대 무게가 정확히 `λ` 이고 셰이더 수술 0(188)
					//   ⚠️ 재현 = (씨앗, 문맥, 시각, 자리)의 **결정적 해시**(`mltworld` ⑧ 의 규약)
					float wt = _Inv();
					if (_lang2 && c == 0u)
					{
						const float lam = _LamOf(_arm);   // ⭐ 213 — 한 자리에서 온다
						bool keepW = (lam >= 1.0f);
						if (!keepW && lam > 0.0f)
						{
							uint32 h = (_seed * 0x9E3779B9u) ^ (ctx * 0x85EBCA6Bu)
							         ^ (t * 0xC2B2AE35u) ^ (w * 0x27D4EB2Fu) ^ 0x5BF03635u;
							h ^= h >> 16; h *= 0x7FEB352Du; h ^= h >> 15; h *= 0x846CA68Bu; h ^= h >> 16;
							keepW = ((float)(h & 0x00FFFFFFu) / 16777216.0f) < lam;
						}
						// ⭐ 섞음 팔(4~6) — **표적으로 쓰는 캡션만** 문맥 사이로 섞는다
						//   ★ 입력은 그대로여야 「언어 탓 ↔ 예산 탓」을 가를 수 있다
						uint32 cw = cls;
						if (_L2Shuf(_arm))
						{
							const uint32 c2 = _ShufCtx(ctx, t, w, 900u, nCtx);
							const uint32 wi2 = (_nw == 1u) ? (c2 * kTime + t)
							                               : ((c2 * kTime + t) * _nw + w);
							cw = (word.Count() > wi2) ? word[wi2] : kConstCls;
						}
						if (keepW) wt = (float)(_N() + (cw % kLVocab));
					}
					_eTgt[dst].Data()[r0] = wt;
				}
				// ⭐ 회차 221 — **행동 축을 팔별로 채운다**
				//   ⚠️ 학습 풀·시험 풀 **둘 다** 바꾼다 — 그래야 「그 팔의 세계」가 일관된다
				//     (⚠️ 표적은 안 건드린다 — ***행동은 표적이 아니다***: P4 의 그 규약)
				if (_actOn)
				{
					const uint32 ra = _RowAct(ctx, t);
					float v = _cVal[c][ra];                   // 원본 = 진짜 `dYaw`(정규화)
					if (_ActShuf(_arm))
					{
						const uint32 c2 = _ShufCtx(ctx, t, 0u, 707u, nCtx);
						v = _cVal[c][_RowAct(c2, t)];
					}
					if (_ActCls9(_arm))
					{
						// ⭐ 이산화 — 220 이 학습 0 에서 쓴 **9계급** 그대로(같은 눈금이어야 비가 뜻이 있다)
						float u2 = v; if (u2 < -1.0f) u2 = -1.0f; if (u2 > 1.0f) u2 = 1.0f;
						int b = (int)((u2 + 1.0f) * 4.5f); if (b < 0) b = 0; if (b > 8) b = 8;
						v = ((float)b / 8.0f) * 2.0f - 1.0f;  // 계급을 다시 [-1,1] 로(축 하나 · 값 통로)
					}
					if (!_effOn && _arm == 0u) v = 0.0f;     // ㈀ 상수 = 기준선(221 의 배치)
					_eVal[dst].Data()[ra] = v;
					_eSym[dst].Data()[ra] = _ActSym();
					// ⭐ 226 — **efference copy**: 행동 축을 **표적으로도** 쓴다(학습 풀만 · 확률 λ)
					//   ⚠️ 시험 풀은 안 건드린다 — ★ 채점은 늘 **P 쪽(슬롯의 변화 표적)** 이다(규율 58)
					float tf = _Inv();
					if (_effOn && c == 0u)
					{
						const float lam = kEffOf[_arm % kArms];
						bool keep = (lam >= 1.0f);
						if (!keep && lam > 0.0f)
						{
							uint32 h = (_seed * 0x9E3779B9u) ^ (ctx * 0x85EBCA6Bu)
							         ^ (t * 0xC2B2AE35u) ^ 0x1B873593u;
							h ^= h >> 16; h *= 0x7FEB352Du; h ^= h >> 15; h *= 0x846CA68Bu; h ^= h >> 16;
							keep = ((float)(h & 0x00FFFFFFu) / 16777216.0f) < lam;
						}
						if (keep)
						{
							float ft = _cTgt[c][ra];             // 흐름 방향(수집이 넣었다)
							if (_EffShuf(_arm))                  // 음성 짝 — **표적만** 섞는다
							{
								const uint32 c2 = _ShufCtx(ctx, t, 1u, 811u, nCtx);
								ft = _cTgt[c][_RowAct(c2, t)];
							}
							if (ft >= 0.0f && ft < (float)_N()) tf = ft;
						}
					}
					_eTgt[dst].Data()[ra] = tf;
				}
				// ⭐ 회차 193 — **지름길 섞기**(문맥 사이 교환 · 원본 `_cVal` 에서 가져온다)
				//   ⚠️ 표적(`kShTgt`)은 **학습 풀에만** 건다(`c == 0u`) — 시험을 섞으면 자가 무너진다.
				if (_shufOn)
				{
					const uint32 sh = _ShufOf(_arm);
					if (sh & kShState)
						for (uint32 a2 = 0; a2 < kStateAx; ++a2)
						{
							const uint32 r = _RowState(ctx, t, a2);
							const uint32 c2 = _ShufCtx(ctx, t, a2, 101u, nCtx);
							_eVal[dst].Data()[r] = _cVal[c][_RowState(c2, t, a2)];
						}
					if (sh & (kShVal | kShSym | kShTgt))
						for (uint32 j = 0; j < kSlots; ++j)
						{
							const uint32 r = _RowSlot(ctx, t, j);
							if (sh & kShVal)
							{
								const uint32 c2 = _ShufCtx(ctx, t, j, 202u, nCtx);
								_eVal[dst].Data()[r] = _cVal[c][_RowSlot(c2, t, j)];
							}
							if (sh & kShSym)
							{
								const uint32 c2 = _ShufCtx(ctx, t, j, 303u, nCtx);
								_eSym[dst].Data()[r] = _cSym[c][_RowSlot(c2, t, j)];
							}
							if ((sh & kShTgt) && c == 0u)
							{
								const uint32 c2 = _ShufCtx(ctx, t, j, 404u, nCtx);
								_eTgt[dst].Data()[r] = _cTgt[c][_RowSlot(c2, t, j)];
							}
						}
				}
				if (mask == kMNone)
				{
					// ⚠️ 학습 풀(마스크 없음)에도 눈감기를 걸어야 한다 — 아래와 같은 처리
					if (_blindOn && t >= _TCutOf(_arm)) _Blind(dst, ctx, t);
					continue;
				}
				for (uint32 j = 0; j < kSlots; ++j)
				{
					const uint32 r = _RowSlot(ctx, t, j);
					float tf = _eTgt[dst][r];
					if (!(tf >= 0.0f && tf < (float)_N())) continue;
					const uint32 tid = (uint32)tf;
					const float sf = _eSym[dst][r] - (float)kStateAx;
					const bool keep = (sf >= 0.0f && sf < (float)kN && (uint32)sf == tid);
					// ⭐ 회차 188 — **확률적 마스크로 가중을 만든다**(`-mltq <n>`)
					//   ★ 모델 손실에 **무게 버퍼가 없다**(표적 float 하나가 계급 id 다) ⇒ 무게를
					//     넣으려면 셰이더 수술이 필요한데, **확률 마스크는 기댓값이 같고 한 줄이다**:
					//     지속 표적을 **확률 `q` 로만** 남기면 ***기대 무게가 정확히 `q`*** 다.
					//   ⚠️ 대가는 **분산**이지만 학습 표적이 13,928(문맥 2048)이라 받쳐 준다.
					//   ⚠️⚠️ 재현 — `mltworld.cw` ⑧ 의 규약(*"난수는 3단 주소지정이고 스트림을
					//     전진시키지 않는다"*)을 따른다: **(씨앗, 문맥, 시각, 슬롯)의 결정적 해시**
					//     ⇒ ★ **순서를 바꾸는 실험이 데이터를 안 바꾼다.**
					bool drop = (mask == kMChange && keep) || (mask == kMKeep && !keep);
					// ⚠️⚠️⚠️ **학습 풀에만 건다**(`c == 0u`) — 시험 풀에 걸면 ***자가 바뀐다.***
					//   ★ 회차 141 의 그 규약이 여기서 반대로 적용된다: 141 은 *"학습 풀은 안
					//     건드린다"* 였고 185 가 그것을 일부러 어겼다. ⇒ ⭐ 그러나 **시험 풀은
					//     절대 안 건드린다** — 그것을 건드리면 목표선과 견줄 수 없다.
					// ⭐ 회차 203 — **`q` 를 팔로**(`-mltqsweep` · 부채 D25)
					//   ★ 시험 자는 **변화만**으로 고정되고(위 ⚠️⚠️⚠️) **학습 무게만** 팔마다
					//     다르다 ⇒ ⭐ 그래서 CE 를 팔끼리 견줌 수 있다(귀원 58).
					const float qNow = _qSweep ? kQOf[_arm % kArms] : _qw;
					if (drop && c == 0u && mask == kMChange && qNow > 0.0f)
					{
						// 확산 강화 해시(3단 주소) — 같은 자리는 늘 같은 값
						uint32 h = (_seed * 0x9E3779B9u) ^ (ctx * 0x85EBCA6Bu)
						         ^ (t * 0xC2B2AE35u) ^ (j * 0x27D4EB2Fu);
						h ^= h >> 16; h *= 0x7FEB352Du; h ^= h >> 15; h *= 0x846CA68Bu; h ^= h >> 16;
						const float u = (float)(h & 0x00FFFFFFu) / 16777216.0f;   // [0,1)
						if (u < qNow) drop = false;         // ⭐ 확률 q 로 **살린다**
					}
					if (drop) tf = _Inv();
					if (tf >= 0.0f && tf < (float)_N()) ++scored;
					_eTgt[dst].Data()[r] = tf;
				}
				// ⚠️⚠️ **눈감기는 마스크 뒤에** — 마스크 판정이 **심볼을 읽어** `keep` 을 정하므로
				//   먼저 비우면 `keep = false` 가 되어 ***채점 표적 수가 팔마다 달라진다***
				//   ⇒ ★ 그러면 CE 를 못 견준다(회차 192 구현 중에 잡았다).
				if (_blindOn && t >= _TCutOf(_arm)) _Blind(dst, ctx, t);
			}
		if (c == 1u) _lastScored = scored;
	}
	inline static uint32 _lastScored = 0u;

	static void _MakeArmPools()
	{
		const uint32 a = _arm;
		// ⭐ 회차 189 — 팔마다 축 수를 먼저 정한다(`Setup` 보다 앞이다)
		_nw = _NwOf(a);
		// ⭐ 회차 194 — **팔이 곧 문맥 수다**(낱말은 없다 · 상수로 고정)
		//   ⚠️ 수집은 최대치(`_nCtx`)로 이미 끝났고, 여기서 **앞 `_armCtx` 개만 올린다**
		//     (`UploadPool` 이 `nSteps = _PoolSteps()` 만 올리므로 prefix 가 그대로 성립한다).
		if (_ctxSweep)
		{
			_armCtx = kCtxOf[a];
			// ⭐ 회차 213 — 문맥 팔에 **캡션을 싣는다**(여섯 팔 전부 같은 입력)
			//   ★ 갈리는 것은 **표적에 캡션을 쓰나**(`_LamOf`)뿐이다 ⇒ ⭐ 그래야 ㈃ 가
			//     「언어를 붙인 채 표본을 늘렸다」를 재고, **입력 차이가 섞이지 않는다**.
			//   ⚠️ 이 자리가 곧 203 1차·189·200 이 셋 다 밟은 그 함정이다
			//     (*"새 모드를 넣을 때 분기해야 하는 자리가 여러 곳"*) ⇒ ★ 낱말은 여기서만 정한다.
			if (_l2ctx)
			{
				_wTr = _wNmTr; _wTe = _wNmTe;
				double e0 = 0.0, ht0 = 0.0, mi0 = 0.0, mib = 0.0;
				_MutInfoLang(_wTe, mi0, ht0, mib);
				_hW[a][_seed] = e0; _iW[a][_seed] = mi0; _iWb[a][_seed] = mib; _hT[_seed] = ht0;
				_Expand(0u, _wTr, _qChg ? kMChange : kMNone);
				return;
			}
			_wTr.Reset(0); _wTe.Reset(0);
			double e0 = 0.0, ht0 = 0.0, mi0 = 0.0;
			_MutInfo(_wTe, mi0, ht0);
			_hW[a][_seed] = e0; _iW[a][_seed] = mi0; _hT[_seed] = ht0;
			_Expand(0u, _wTr, _qChg ? kMChange : kMNone);
			return;
		}
		// ⭐ 회차 192 — **눈감기 모드에서는 낱말을 상수로 고정한다**
		//   ★ 팔이 「눈감기 시점」을 뜻하므로 낱말이 팔마다 다르면 **두 효과가 섞인다**.
		//   ⚠️ 빈 배열 ⇒ `_Expand` 가 `kConstCls` 로 채운다(값이 정확히 0).
		// ⭐ 회차 193 도 낱말을 상수로 고정한다(팔이 「무엇을 섞나」를 뜻하므로)
		// ⛔⛔⛔ **회차 203 1차가 여기서 깨졌다** — `_qSweep` 을 이 조건에 안 넣어서
		//   옛 경로(오라클/maxV/어디로/어느물체)를 타고 **팔 0 에 오라클 낱말(= 정답)이 실렸다**
		//   ⇒ CE 가 **0.625**(201 의 1.165 ↔ 차 0.54 = 잡음의 29배)로 찍혀 배관 ①이 잡았다.
		//   ⇒ ★ **189·200 과 같은 계열**이다: ***새 모드를 넣을 때 분기해야 하는 자리가 여러 곳***
		//     ⇒ ⭐ 그래서 **「낱말을 상수로」 를 요구하는 모드 전부를 이 한 줄에 모은다.**
		// ⭐ 회차 212 — **L2 모드의 낱말**: 모든 팔이 **같은 캡션**을 입력으로 받고
		//   ⚠️ 섞음 팔(4~6)은 **표적으로 쓰는 캡션만** 섞는다 — ★ 입력은 그대로여야
		//   「낙폭이 언어 탓인가 예산 탓인가」를 가를 수 있다(등록문의 그 줄).
		//   ⇒ ⭐ 그래서 `_wTr` 은 늘 캡션이고, **섞기는 표적을 만들 때** 한다(아래 `_Expand`).
		if (_lang2)
		{
			_wTr = _wNmTr; _wTe = _wNmTe;
			double e0 = 0.0, ht0 = 0.0, mi0 = 0.0, mib = 0.0;
			_MutInfoLang(_wTe, mi0, ht0, mib);
			_hW[a][_seed] = e0; _iW[a][_seed] = mi0; _iWb[a][_seed] = mib; _hT[_seed] = ht0;
			_Expand(0u, _wTr, _qChg ? kMChange : kMNone);
			return;
		}
		// ⭐ 회차 221 — **행동 모드는 낱말을 상수로** 둔다
		//   ★ 팔이 「행동 축에 무엇을 넣나」를 뜻하므로 낱말이 팔마다 다르면 **두 효과가 섞인다**
		//   ⇒ ⚠️ 203 1차·189·200 이 셋 다 밟은 그 자리(*"분기해야 하는 자리가 여러 곳"*)
		if (_blindOn || _shufOn || _qSweep || _actOn)
		{
			_wTr.Reset(0); _wTe.Reset(0);
			double e0 = 0.0, ht0 = 0.0, mi0 = 0.0;
			_MutInfo(_wTe, mi0, ht0);
			_hW[a][_seed] = e0; _iW[a][_seed] = mi0; _hT[_seed] = ht0;
			_Expand(0u, _wTr, _qChg ? kMChange : kMNone);
			return;
		}
		// ⭐ 회차 200 — 언어 모드의 팔 여덟
		//   ★ 짝은 (0,1) 값 · (2,3) **심볼 = 표제** · (4,5) 상수(축 교란 대조) · (6,7) id 뒤섞음
		//   ⚠️ **섞음 팔도 같은 축 수**여야 한다 ⇒ 짝지은 차가 축 교란을 지운다(138·139)
		if (_lang)
		{
			const bool odd = ((a & 1u) != 0u);          // 황수 팔 = 섞음
			// ⭐ 회차 209 — 0·1 **오라클(천장)** · 2·3 심볼 · 4·5 값 · 6·7 **상수**
			//   ⚠️ 오라클은 **자리 둘에 같은 값**(그 슬롯의 다음 방향 계급)을 넣는다 —
			//     ★ 자리 수를 캡션과 **맞춰야** 짝지은 차가 축 교란을 지운다(138·139).
			//   ⚠⚠ **섞을 대상을 팔마다 골라서** 섞는다 — ⭐ 팔 1 은 **오라클을** 섞어야 하고
			//     팔 3·5 는 **캡션을** 섞어야 한다(회차 209 구현 중에 이것을 잉어 고쿤다).
			Array<uint32> srcTr; srcTr.Reset(0);
			Array<uint32> srcTe; srcTe.Reset(0);
			bool isConst = false;
			// ⭐ 225 — 용량 모드는 **전 팔이 같은 캡션**이다(갈리는 것은 `dim` 뿐)
			//   ⛔ 파일럿이 잡았다: 이 분기가 팔 0·1 을 **오라클**로 주고 있어서
			//     `Î` 가 팔마다 **+0.1296 / +0.0494 / +0.0521** 로 갈렸다
			//   ⇒ ★ *"`Î` 는 용량과 무관해야 한다"* 를 관문으로 걸어 둔 덕에 **그 자리에서 걸렸다**
			//     (이번 세션에 세운 **공용 규율 13-b** 가 바로 값을 했다)
			if (_capOn) { srcTr = _wNmTr; srcTe = _wNmTe; }
			else if (a == 6u || a == 7u) isConst = true;                  // 상수 — `_Expand` 가 kConstCls
			else if (a == 0u || a == 1u)
			{
				// 천장 — `_wCh*`(오라클)을 **자리 둘로** 펼친다
				for (uint32 i2 = 0; i2 < _wChTr.Count(); ++i2)
					for (uint32 k = 0; k < _lnw; ++k) srcTr.Add(_wChTr[i2]);
				for (uint32 i2 = 0; i2 < _wChTe.Count(); ++i2)
					for (uint32 k = 0; k < _lnw; ++k) srcTe.Add(_wChTe[i2]);
			}
			else if (_capOn) { srcTr = _wNmTr; srcTe = _wNmTe; }         // ⭐ 225 — 전 팔이 캡션
			else { srcTr = _wNmTr; srcTe = _wNmTe; }                     // 심볼·값 — 같은 캡션
			if (isConst) { _wTr.Reset(0); _wTe.Reset(0); }
			else if (!odd) { _wTr = srcTr; _wTe = srcTe; }
			else
			{
				// ⚠️ 섞음 = **문맥 사이 교환**(193 의 그 귀약) ⇒ 주변분포는 그대로, 상관만 깨진다
				_wTr.Reset(0); _wTe.Reset(0);
				const uint32 nTr = srcTr.Count() / _lnw, nTe = srcTe.Count() / _lnw;
				for (uint32 i2 = 0; i2 < nTr; ++i2)
				{
					const uint32 j2 = _ShufCtx(i2, 0u, 0u, 700u + a, (nTr == 0u) ? 1u : nTr);
					for (uint32 k = 0; k < _lnw; ++k) _wTr.Add(srcTr[j2 * _lnw + k]);
				}
				for (uint32 i2 = 0; i2 < nTe; ++i2)
				{
					const uint32 j2 = _ShufCtx(i2, 1u, 0u, 700u + a, (nTe == 0u) ? 1u : nTe);
					for (uint32 k = 0; k < _lnw; ++k) _wTe.Add(srcTe[j2 * _lnw + k]);
				}
			}
			if (_LangPermOn(a))
			{
				// ⚠️⚠️ 회차 255 — **잠복 함정을 고쳤다**: 여기 `{ 0u,5u,8u,2u,7u,1u,4u,6u,3u }` 로
				//   **아홉 칸을 손으로** 적어 뒀는데 `kLVocab` 이 15 가 되면 뒤 여섯 칸이 **0 으로 채워져
				//   순열이 아니게 된다**(같은 이름으로 여럿이 몰린다). ⛔ 조용히 깨진다.
				//   ★ `_LangPermOn` 이 항상 `false` 라 실행은 안 됐지만 **함정은 남아 있었다.**
				//   ⇒ ⭐ 계산으로 만든다 — `gcd(7, kLVocab) = 1` 이면 순열이고 **「없음」(0)은 0 으로 남는다**.
				uint32 perm[kLVocab];
				for (uint32 pi = 0; pi < kLVocab; ++pi) perm[pi] = (pi * 7u) % kLVocab;
				for (uint32 i = 0; i < _wTr.Count(); ++i) _wTr.Data()[i] = perm[_wTr[i] % kLVocab];
				for (uint32 i = 0; i < _wTe.Count(); ++i) _wTe.Data()[i] = perm[_wTe[i] % kLVocab];
			}
			double e0 = 0.0, ht0 = 0.0, mi0 = 0.0;
			// ⭐ 회차 210 — 언어 모드는 **캡션 전용 `Î`** 를 쓴다(stride 가 `_lnw` 다)
			//   ⛔ `_MutInfo` 는 `_nw != 1` 이면 stride `kSlots`(8)로 읽어 **쓰레기**를 냈다
			double mib = 0.0;
			_MutInfoLang(_wTe, mi0, ht0, mib);
			_hW[a][_seed] = e0; _iW[a][_seed] = mi0; _iWb[a][_seed] = mib; _hT[_seed] = ht0;
			_Expand(0u, _wTr, _qChg ? kMChange : kMNone);
			return;
		}
		if (_slotWord)
		{
			// ⚠️ **상수 팔은 빈 배열**을 준다 — `_Expand` 가 `kConstCls` 로 채우므로
			//   값이 정확히 0 이 되고 **축만 늘어난다**(교란 대조의 정의).
			// ⚠️ 상수 팔 — `_Expand` 가 길이 밖을 `kConstCls` 로 채우므로 **빈 배열**이 곧 상수다
			//   ★ 그래서 축은 21 로 늘고 값은 **정확히 0** 이다(교란 대조의 정의)
			Array<uint32> empty; empty.Reset(0);
			if (a == kOracle)      { _wTr = _wChTr;  _wTe = _wChTe; }
			else if (a == kMaxV)   { _wTr = empty;   _wTe = empty; }      // 상수 · 축8
			else if (a == kDir)    { _wTr = _wA1Tr;  _wTe = _wA1Te; }     // 자율여부 축하나
			else if (a == kWhich)  { _wTr = _wAuTr;  _wTe = _wAuTe; }     // ⭐ 표제 · 슬롯마다
			else
			{
				const Array<uint32>* bTr = &_wChTr; const Array<uint32>* bTe = &_wChTe;
				uint32 s0 = 11u, s1x = 22u;
				if (a == kMaxVS)  { bTr = &empty;   bTe = &empty;   s0 = 33u; s1x = 44u; }
				if (a == kDirS)   { bTr = &_wA1Tr;  bTe = &_wA1Te;  s0 = 55u; s1x = 66u; }
				if (a == kWhichS) { bTr = &_wAuTr;  bTe = &_wAuTe;  s0 = 77u; s1x = 88u; }
				Array<uint32> s1, s2;
				_Shuffle(*bTr, s1, s0); _Shuffle(*bTe, s2, s1x);
				_wTr = s1; _wTe = s2;
			}
		}
		else if (a == kOracle)     { _wTr = _wChTr;  _wTe = _wChTe; }
		else if (a == kMaxV)  { _wTr = _wMvTr;  _wTe = _wMvTe; }
		else if (a == kDir)   { _wTr = _wDirTr; _wTe = _wDirTe; }
		// ⭐ 회차 190 — 표제 자리(㈆)에 **「자율인 물체 중 첫 슬롯」**을 넣는다
		//   ⚠️ `_wA1` 은 189 에서 **슬롯마다 배열**로 만들었다(슬롯 0 만 값 · 나머지 상수)
		//     ⇒ ★ 축 14 모드에서는 `_nw == 1` 이라 색인이 `ctx*kTime + t` 다
		//     ⇒ ⇒ ⚠️⚠️ **그 색인이 슬롯 0 의 값을 안 집는다**(스트라이드가 kSlots 다)
		//     ⇒ ⭐ 그래서 **여기서 스트라이드를 벗긴다**(`kSlots` 마다 하나씩 뽑는다)
		else if (a == kWhich && _auWord)
		{
			_wTr.Reset(0); _wTe.Reset(0);
			for (uint32 i = 0; i * kSlots < _wA1Tr.Count(); ++i) _wTr.Add(_wA1Tr[i * kSlots]);
			for (uint32 i = 0; i * kSlots < _wA1Te.Count(); ++i) _wTe.Add(_wA1Te[i * kSlots]);
		}
		else if (a == kWhichS && _auWord)
		{
			// ⭐ 표제의 **자기 바닥** — 같은 낱말을 섞는다(스트라이드를 벗긴 뒤)
			Array<uint32> a1r, a1e;
			a1r.Reset(0); a1e.Reset(0);
			for (uint32 i = 0; i * kSlots < _wA1Tr.Count(); ++i) a1r.Add(_wA1Tr[i * kSlots]);
			for (uint32 i = 0; i * kSlots < _wA1Te.Count(); ++i) a1e.Add(_wA1Te[i * kSlots]);
			_Shuffle(a1r, _wTr, 77u); _Shuffle(a1e, _wTe, 88u);
		}
		else if (a == kWhich) { _wTr = _wWhTr;  _wTe = _wWhTe; }
		else
		{
			const Array<uint32>* bTr = &_wChTr; const Array<uint32>* bTe = &_wChTe;
			uint32 s0 = 11u, s1x = 22u;
			if (a == kMaxVS)  { bTr = &_wMvTr;  bTe = &_wMvTe;  s0 = 33u; s1x = 44u; }
			if (a == kDirS)   { bTr = &_wDirTr; bTe = &_wDirTe; s0 = 55u; s1x = 66u; }
			if (a == kWhichS) { bTr = &_wWhTr;  bTe = &_wWhTe;  s0 = 77u; s1x = 88u; }
			Array<uint32> s1, s2;
			_Shuffle(*bTr, s1, s0); _Shuffle(*bTe, s2, s1x);
			_wTr = s1; _wTe = s2;
		}
		// 낱말 엔트로피 + Î
		Array<uint32> h; h.Reset(0);
		for (uint32 i = 0; i < kWordCls; ++i) h.Add(0u);
		for (uint32 i = 0; i < _wTe.Count(); ++i) ++h.Data()[_wTe[i] % kWordCls];
		double e = 0.0;
		for (uint32 i = 0; i < kWordCls; ++i)
		{
			if (h[i] == 0u) continue;
			const double p = (double)h[i] / (double)_wTe.Count();
			e += -p * (double)Log((float)p);
		}
		_hW[a][_seed] = e;
		double mi = 0.0, ht = 0.0;
		_MutInfo(_wTe, mi, ht);
		_iW[a][_seed] = mi; _hT[_seed] = ht;
		// ⭐ 회차 185 — **㉷ 학습 손실도 변화 쪽으로**(`-mltqchg`)
		//   ⚠️⚠️ **회차 141 의 규약을 일부러 어긴다**(*"학습 풀은 안 건드린다 — 바꾸는 것은
		//     자이지 과제가 아니다"*). ★ 회차 144 가 그것을 어겨 **범인이 손실 가중임**을 밝혔고
		//     (변화 CE 2.7802 → **1.7389** · 도달률 **+156%** · 12/12), 여기서는 **조건을
		//     만족시키는 것**이 목적이라 그 사실을 더 정직하게 적는다:
		//     ⇒ ***「변화만 학습」이 칸 1 닫힘 조건 ㉠ 을 만족시키는 유효한 길인가.***
		//   ⚠️ 유보: **지속을 안 배우면 「경험 학습」이 반쪽**이다 ⇒ ★ `D11` 이 지속 CE 를 찍으니
		//     **파레토를 같이 본다** · ⭐ 진짜 처방은 **가중**(둘 다 배우되 변화에 무게)이고
		//     그것이 **다음 회차**다(회차 145 가 그 자리를 열어 뒀다).
		_Expand(0u, _wTr, _qChg ? kMChange : kMNone);
	}

	static bool _UploadTest(uint32 mask)
	{
		_Expand(1u, _wTe, mask);
		if (_arm == 0u && _out == 0u) _nScored[mask][_seed] = (double)_lastScored / (double)kPtCtx;
		return _M.UploadPool(_eVal[1], _eTgt[1], kPtPool) && _M.UploadSymbolPool(_eSym[1], kPtPool);
	}

	static void _BodyBegin(RHI* rhi)
	{
		// ⚠️⚠️ **순서가 뒤바뀌었다**(회차 189) — `_MakeArmPools` 가 **팔의 축 수(`_nw`)를 정하므로**
		//   `Setup` 보다 **먼저** 돌아야 한다. ★ 안 그러면 모델이 옛 축 수로 잡힌다.
		_MakeArmPools();
		// ⭐ 회차 202 — **초기화에 씨앗을 넣는다**(`-mltinitseed`)
		//   ⚠️⚠️⚠️ 202 가 코드에서 찾은 것: `_Spread` 에 **씨앗이 없어서** 12씨앗 전부가
		//     **완전히 같은 초기값**을 썼다 ⇒ ★ 씨앗은 **세계만** 바꿨다.
		//   ⇒ ⭐ 그래서 **어휘 id = 임베딩 행 = 고정된 초기값**이고 **씨앗 평균으로
		//     안 지워진다**(부채 D26) · ⚠️⚠️ 더 크게는 **모든 12씨앗 판정이 「하나의
		//     초기화」 위에서 났고 SE 가 그 우연을 못 담았다.**
		//   ⚠️ 기본은 **끔** ⇒ 안 켜면 회차 1~201 이 **비트 동일**하다(그것이 관문 ① 이다).
		//   ★ 씨앗을 **1 부터** 섞는다(0 이 옛 동작이므로 씨앗 0 이 옛 판과 겹치지 않게).
		if (_initSeed) _M.SetInitSeed(_seed + 1u);
		// ⭐⭐ 회차 232 — 🔒 **하네스 방벽**(학습 쪽) — *"이 판이 무엇을 보고 있나"* 를 한 줄로
		//   ⛔ 칸 3 열여섯 회차에 **사고 6건 · 철회된 결론 8개**였고 **원인이 한 종류**다: 모드가 늘었다.
		//     · **219** — 209 의 판정 블록이 **L2 모드에서도** 돌아 팔 0·1 을 오라클로 읽었다(근거 넷 철회)
		//     · **220** — 학습 자 dt 1.00 ↔ 학습0 자 dt **0.25**(결론 셋 철회)
		//     · **225** — `_MakeArmPools` 의 `_lang` 분기가 팔 0·1 에 오라클을 줬다
		//   ⇒ ⚠️⚠️ **219 가 「모드는 계속 늘어난다」고 적었고 220 이 사흘 뒤 같은 계열로 다시 밟았다.**
		//   ⇒ ★ 그래서 **켜진 모드 · 세계 · 축 · 어휘 · 용량**을 회차 시작에 **한 줄로 못 박는다.**
		//     ⚠️ 이 줄은 판정이 아니라 **증인**이다 — 로그를 나중에 읽는 사람이 그 자리를 안다.
		{
			// ⚠️ **`_actOn` 은 `_effOn` 에 종속이다**(`_actOn = -mltact || _effOn`) ⇒ 둘로 세면 **거짓 경고**다.
			//   ★ 실측으로 그 자리를 바로 밟았다(232 의 시험 실행이 ⛔ 를 냈는데 정상이었다).
			const uint32 nMode = (_ctxSweep ? 1u : 0u) + (_lang2 ? 1u : 0u) + (_capOn ? 1u : 0u)
			                   + (_effOn ? 1u : 0u) + ((_actOn && !_effOn) ? 1u : 0u);
			// ⭐ **값이 바뀔 때만** 찍는다(README 의 로그 원칙) — 팔마다 부르면 32줄이 된다
			static uint32 lastSig = 0xFFFFFFFFu;
			const uint32 sig = (_Arms() * 131u) ^ (_Ax() * 17u) ^ (_SymA() * 7u) ^ (_CapDim() * 3u)
			                 ^ (nMode << 24) ^ ((uint32)(_Dt() * 100.0f) << 8);
			if (sig != lastSig)
			{
				lastSig = sig;
				// ⭐ 234 — **씨앗 수를 찍는다**: `-mltseeds` 파서가 한 자리만 읽어 `24` 가 `2` 가 됐었다
				LogA("[mlt] 🔒 회차 판 — **씨앗 %u**(상한 %u) · 세계 dt %.2f%s · amp %.2f · 팔 %u · 축 %u · 심볼 %u · 출력 %u · dim %u/ff %u\n",
					_seeds, kSeedsMax,
					(double)_Dt(), _dirOn ? "" : " ⚠️**방향 모드가 꺼져 있다 — 학습0 자는 dt 1.00 을 본다(220)**",
					(double)_Amp(), _Arms(), _Ax(), _SymA(), _OutV(), _CapDim(), _CapFF());
				LogA("[mlt] 🔒   모드 — ctx %d · lang %d · lang2 %d · act %d · cap %d · eff %d · dir %d%s\n",
					_ctxSweep ? 1 : 0, _lang ? 1 : 0, _lang2 ? 1 : 0, _actOn ? 1 : 0,
					_capOn ? 1 : 0, _effOn ? 1 : 0, _dirOn ? 1 : 0,
					(nMode > 1u) ? "  ⛔⛔ **모드가 둘 이상 켜졌다 — 판정 블록이 서로를 밟는지 확인하라**" : "");
				// ⚖️✂️ 240 — 세계가 좁히는 판이면 그것을 찍는다(방벽 ② · 그것이 이 회차의 손잡이다)
				if (_enOn || _prBud > 0.0f)
					LogA("[mlt] 🔒   ⚖️✂️ **세계가 좁힌다** — 에너지 %s · 가지치기 예산 %s\n",
						_enOn ? "**켬**" : "끔",
						(_prBud > 0.0f) ? "" : "**끔**");
				if (_prBud > 0.0f)
					LogA("[mlt] 🔒        예산 = **%.2f**(239: 자리수 0.42배 · 목표선 0.65배 · 천장 −5.7%%p)\n",
						(double)_prBud);
				// ⭐⭐ 243 — 감쇠 세기는 이 회차의 손잡이다 ⇒ **값을 찍는다**(방벽 ②)
				if (_enOn)
					LogA("[mlt] 🔒        ⭐ **감쇠 세기 = %.2f**%s (242 학습0 격자: 0.65 무효 · 0.35 = 241 · "
						"0.15 포화 직전 · 0.05 음성)\n",
						(double)((_slow > 0.0f) ? _slow : MLTWorldCfg::kEnergySlow),
						(_slow > 0.0f) ? "" : " ⟵ **세계 기본**(`-mltslow` 안 줬다)");
				// ⭐⭐⭐ 255 — 낱말이 「슬롯」인가 「정체성」인가는 **이 판이 무엇을 보나**의 핵심이다(방벽 ②)
				if (_lang)
					LogA("[mlt] 🔒   ⭐ **낱말 = %s** · 실효 어휘 **%u**(대역 %u 고정)%s\n",
						_lidOn ? "**물체 정체성**(`-mltlid`)" : "슬롯 번호(기본)",
						_LVoc(), kLVocab,
						_lidOn ? "  ⚠️ 255 실측: `d̄` 0.61배 · `Î` 7.7배 하락(표적이 슬롯 색인이다)"
						       : "  ⟵ 241·246 과 같은 자리");
				// ⭐ 236 — 어휘 뭉개기가 켜졌으면 **실효 어휘**를 찍는다(그것이 이 회차의 손잡이다)
				if (_lvoc > 0u)
					LogA("[mlt] 🔒   ⭐ **어휘 뭉개기** — 이름 %u → **%u 그룹**(+「없음」) ⇒ 실효 어휘 **%u**"
						"(대역은 %u 그대로 = 모델 크기 무변경)\n",
						kLVocab - 1u, _lvoc, _lvoc + 1u, kLVocab);
			}
		}
		// 225 — 용량이 팔이다(150 이 런타임으로 열어 둔 그 인자)
		if (!_M.Setup(rhi, _SymA(), _OutV(), _Ax(), kTime, _CapDim(), MLTModelCfg::kLayer, _CapFF()))
		{ _Fail("몸통 준비"); return; }
		if (!(_M.UploadPool(_eVal[0], _eTgt[0], _PoolSteps()) && _M.UploadSymbolPool(_eSym[0], _PoolSteps())))
		{ _Fail("학습 풀 업로드"); return; }
		// ⭐⭐ 회차 245 — 학습 **전** 심볼 표를 잡는다(이동 `ΔE` 의 기준점).
		//   ⚠️ `Setup` 이 방금 초기값을 올렸다 ⇒ 먼저 씻는다(`Flush` 는 진단 전용 계약 그대로).
		//   ⚠️⚠️ 리드백이 실패하면 **조용히 넘기지 않는다** — 판정 표가 그 횟수를 찍는다(방벽 ①).
		if (_lang)
		{
			_M.Flush();
			if (_GrabCapRows(_symE0)) _repOn = true;
			else { ++_repFail; _symE0.Reset(0); }
		}
		// ⭐⭐ 247 — 행동 모드는 **행 하나**(`_ActSym()`)를 잡는다
		if (_actOn && !_lang)
		{
			_M.Flush();
			if (_GrabRow((uint32)_ActSym(), _symAct0)) _repOn = true;
			else { ++_repFail; _symAct0.Reset(0); }
		}
		_step = 0u; _st = kBodyTrain;
	}

	// ⭐⭐ 회차 233 — 🔒 **진행 표지**(하네스 방벽 ③ · 232 의 연장)
	//   ⛔⛔ 233 이 이 자리에서 **6시간 18분을 잃었다** — 학습 첫 판이 안 끝나는데
	//     ***로그가 한 줄도 안 나와서 「느린 것」과 「멈춘 것」을 밖에서 구별할 수 없었다.***
	//     ⚠️ 엔진 로그 파일도 같은 시각에 멈춰 있었다(버퍼링이 아니었다 — `LogA` 는 매 줄 flush 한다).
	//   ⇒ ⭐ 진단이 2분이었는데 **그 2분을 쓰기까지 6시간을 기다렸다**(그것이 진짜 손해다).
	//   ⇒ ★★ 처방: **`kProgEvery` 걸음마다 「어디를 도는지 · 걸음/초」를 한 줄** 찍는다.
	//     ⚠️ 값을 안 바꾼다(로그뿐) · 비용 0(800걸음에 네 줄).
	//     ★ 그리고 **걸음/초가 곧 진단**이다 — 227 은 판 하나가 ~7초였다(= 약 115 걸음/초).
	static constexpr uint32 kProgEvery = 200u;
	inline static uint64 _progT0 = 0u;      // 이 판이 시작한 시각(단조 카운터)
	inline static uint64 _runT0  = 0u;      // 회차가 시작한 시각
	static void _BodyTrain()
	{
		if (_step >= _steps)
		{
			_evalIdx = 0u;
			if (!_UploadTest(kMChange)) { _Fail("시험 풀 업로드"); return; }
			_gate.Begin(kPtPool); _st = kEval; return;
		}
		if (_step == 0u)
		{
			_progT0 = Time::RawTicks();
			if (_runT0 == 0u) _runT0 = _progT0;
		}
		for (uint32 i = 0; i < kPerTick && _step < _steps; ++i)
		{
			_M.SelectStep(_step % _PoolSteps());
			// ⭐ 회차 201 — **학습률 배율**(`-mltlr <n>` ⇒ n/10 배 · 기본 10 = ×1.0)
			//   ⚙️ **커널·모델 0줄** — `AdamStep(lrMul)` 이 이미 배율을 받는다(`kLr = 3.0e-3`).
			//   ★ 근거는 **회차 152** 다: *"`lr` 이 너무 높으면 모델이 「나르기」로 도망간다 —
			//     **큰 모델 + 높은 `lr` = 학습 불안정 ⇒ 가장 쉬운 해(복사)로 붕괴**"*
			//     그때 U자 곡선의 내부 최적이 **`lr×0.5`** 였다(시험 1.8172 → **1.6770** · t 4.42).
			//   ⇒ ⭐ 회차 200 이 그 서명을 냈다: 축이 15 로 · 어휘가 24 로 늘어 **모델이 커졌고**
			//     실행 잡음이 **0.0286 → 0.0514**(최대 **0.4267** = 거의 발산)로 뛰었다.
			//   ⇒ ⇒ ★ 그래서 처방이 **`lr` 을 낮추는 것**이고, 그것이 σ 를 줄여 표제를 세운다.
			if (!_M.Forward() || !_M.Backward() || !_M.AdamStep(_lrMul)) { _Fail("몸통 스텝"); return; }
			++_step;
			// ⭐ 233 — 진행 표지. ★ **걸음/초가 곧 진단**이다(227 은 판 하나가 ~7초 = 약 115 걸음/초)
			if ((_step % kProgEvery) == 0u)
			{
				const double hz  = (double)Time::RawTicksPerSecond();
				const double sec = (hz > 0.0) ? ((double)(Time::RawTicks() - _progT0) / hz) : 0.0;
				const double all = (hz > 0.0) ? ((double)(Time::RawTicks() - _runT0)  / hz) : 0.0;
				LogA("[mlt] ⏱️ 씨앗 %2u · 바깥 %u · 팔 %u/%u · 걸음 %u/%u — %.1f 걸음/초 "
					"(이 판 %.0fs · 회차 %.0f분)\n",
					_seed, _out, _arm, _Arms(), _step, _steps,
					(sec > 1.0e-6) ? ((double)_step / sec) : 0.0, sec, all / 60.0);
			}
		}
	}

	static void _EvalStep()
	{
		bool fail = false;
		if (!_gate.Step(_M, fail)) return;
		if (fail) { _Fail("평가 리드백"); return; }
		const float ce = _gate.Mean();
		if (!(ce == ce) || ce > 1.0e30f) _finite = false;

		if (_evalIdx == 0u)
		{
			_ce[_out][_arm][_seed] = ce;
			// ⭐⭐ 회차 245 — 학습 **뒤** 심볼 표를 여기서 잡는다.
			//   ★ 이 자리인 이유: **평가 리드백이 방금 끝났다** ⇒ 학습 디스패치가 확실히 보인다
			//     (다른 `Read*` 와 같은 계약 — 이번 프레임에 디스패치한 것은 안 보인다).
			//   ⚠️ 평가는 forward 뿐이라 파라미터를 안 바꾼다 ⇒ 이 표가 곧 「학습이 끝난 표」다.
			if (_lang && _symE0.Count() > 0u)
			{
				Array<float> e1;
				if (_GrabCapRows(e1))
				{
					const uint32 D = _M.Dim();
					Array<float> dE; dE.Reset(0);
					for (uint32 i = 0; i < kCapRows * D; ++i) dE.Add(e1[i] - _symE0[i]);
					_rep[0][_out][_arm][_seed] = (float)_PartRatio(e1);
					_rep[1][_out][_arm][_seed] = (float)_PartRatio(dE);
					_rep[2][_out][_arm][_seed] = (float)_MoveNorm(e1, _symE0);
					// ⭐⭐ 246 — ㉥ 과 ㉣ 은 **정규화 하나만** 다르다 ⇒ 그 갈림이 「크기의 몫」이다
					Array<float> uE; _UnitRows(dE, uE);
					_rep[3][_out][_arm][_seed] = (float)_PartRatioRaw(uE);   // ㉣ PR₁(단위)
					_rep[4][_out][_arm][_seed] = (float)_PartRatioRaw(dE);   // ㉥ PR₀(생)
					_rep[5][_out][_arm][_seed] = (float)_MeanCos(dE);        // ㉤ 평균 코사인
				}
				else ++_repFail;
			}
			// ⭐⭐ 247 — 행동 심볼 행의 이동량(행동 모드 전용)
			if (_actOn && !_lang && _symAct0.Count() > 0u)
			{
				Array<float> a1;
				if (_GrabRow((uint32)_ActSym(), a1))
					_rep[kRepAct][_out][_arm][_seed] = (float)_RowMove(a1, _symAct0);
				else ++_repFail;
			}
			LogA("[mlt] 🧿   %s 씨앗 %2u · 바깥 %u · **변화만 CE %.5f**(채점 %.1f/문맥 · 목표선 %.4f)\n",
				_ArmName(_arm), _seed, _out, (double)ce, _nScored[kMChange][_seed], _goal[_seed]);
		}
		else if (_evalIdx == 1u) { _ceKeep[_out][_arm][_seed] = ce; }
		else                     { _ceAll[_out][_arm][_seed] = ce; }

		// ⭐ 회차 207 — `q` 스윕에서는 **모든 팔에서** 지속/전체를 잰다(㉤ 의 곡선이 필요하다)
		//   ⚠️ 대가는 평가 3배인데 평가는 리드백뿐이라 학습(800걸음)보다 훨씬 싸다.
		const bool evalAll = (_arm == 0u) || _qSweep;
		if (evalAll && _evalIdx + 1u < kEvalsArm0)
		{
			++_evalIdx;
			const uint32 m = (_evalIdx == 1u) ? kMKeep : kMAll;
			if (!_UploadTest(m)) { _Fail("D11 시험 풀 업로드"); return; }
			_gate.Begin(kPtPool); return;
		}
		if (evalAll && _evalIdx + 1u == kEvalsArm0)
			LogA("[mlt] 🧿   📊 **D11** 씨앗 %2u · 바깥 %u · %s — 지속만 **%.5f** · 전체 **%.5f**\n",
				_seed, _out, _ArmName(_arm),
				(double)_ceKeep[_out][_arm][_seed], (double)_ceAll[_out][_arm][_seed]);

		if (++_arm < _Arms()) { _ToBody(); return; }
		_arm = 0u;
		if (++_out < kOut) { _ToBody(); return; }
		_out = 0u;
		_seedOk[_seed] = _finite;
		++_seed; _st = kGather;
	}

	// ── 짝지은 차 — SE 에 실행 항(규율 29·37) ───────────────────────
	// ⭐⭐ 회차 245 — **식은 한 벌로 두고 「어느 배열이냐」만 인자로 뺐다.**
	//   ★ 근거는 바로 아래 `_Paired4` 주석이 이미 못 박아 둔 것이다(공용 규율 16):
	//     *"계산식이 두 곳이면 새 입력이 왔을 때 한쪽만 안다."*
	//   ⇒ 245 가 **모델 표현 자 셋**(`_rep`)을 들고 오는데 그것도 같은 SE(실행 항 포함)를
	//     타야 한다 ⇒ 식을 복사하지 않고 **자리를 인자로** 만든다.
	//   ⚠️ 연산 순서를 한 글자도 안 바꿨다 ⇒ `_ce` 로 부르면 **비트 동일**이다(관문 ②).
	using Src = const float (&)[kOut][kArms][kSeedsMax];
	static double _M2s(Src src, uint32 a, uint32 s)
	{
		double v = 0.0;
		for (uint32 o = 0; o < kOut; ++o) v += (double)src[o][a][s];
		return v / (double)kOut;
	}
	static double _M2(uint32 a, uint32 s) { return _M2s(_ce, a, s); }
	struct Pair { double d = 0.0, se = 0.0, t = 0.0; uint32 win = 0u, n = 0u; };
	static Pair _PairedSrc(Src src, uint32 a, uint32 b)
	{
		Pair p;
		double sum = 0.0, sq = 0.0, runSq = 0.0;
		for (uint32 s = 0; s < _seeds; ++s)
		{
			if (!_seedOk[s]) continue;
			const double d = _M2s(src, a, s) - _M2s(src, b, s);
			sum += d; sq += d * d; ++p.n;
			if (d < 0.0) ++p.win;
			double rv = 0.0;
			for (uint32 o = 0; o < kOut; ++o)
			{
				const double x = (double)src[o][a][s] - (double)src[o][b][s];
				rv += x * x;
			}
			rv = rv / (double)kOut - ((_M2s(src, a, s) - _M2s(src, b, s)) * (_M2s(src, a, s) - _M2s(src, b, s)));
			if (rv > 0.0) runSq += rv;
		}
		if (p.n == 0u) return p;
		p.d = sum / (double)p.n;
		const double var = (p.n > 1u) ? (sq / (double)p.n - p.d * p.d) * (double)p.n / (double)(p.n - 1u) : 0.0;
		const double runV = runSq / (double)p.n / (double)kOut;
		p.se = Sqrt((float)((var + runV) / (double)p.n));
		p.t = (p.se > 1.0e-12) ? Abs((float)p.d) / p.se : 0.0;
		return p;
	}
	static Pair _Paired(uint32 a, uint32 b) { return _PairedSrc(_ce, a, b); }
	// ⭐ 회차 213 — **「차의 차」를 재는 자**(낙폭끼리 견준다)
	//   ⚙️ 왜 필요한가: ㈃ 는 *"언어를 붙인 채 표본을 늘리면 CE 가 계속 내려간다"* 인데
	//     그 판정은 **낙폭 하나**가 아니라 ***두 밴드의 낙폭을 견주는 것***이다
	//     (언어 O 의 낙폭이 언어 X 의 낙폭보다 작지 않아야 「언어가 표본을 안 죽인다」).
	//   ⚠️⚠️ 그 양을 두 `_Paired` 의 `d̄` 를 뺀 값으로 적으면 **SE 가 없다** —
	//     짝을 씨앗 안에서 유지해야 하고, 그러면 σ 가 두 낙폭의 **공분산까지** 먹는다.
	//   ⇒ ★ 그래서 SE 식은 `_Paired` 와 **한 벌**로 두고 씨앗마다의 값을 만드는 자리만 가른다
	//     (공용 규율 16 — 계산식이 두 곳이면 새 입력이 왔을 때 한쪽만 안다).
	static constexpr uint32 kNoArm = 0xFFFFFFFFu;
	static double _V4(uint32 o, uint32 a, uint32 b, uint32 c, uint32 d, uint32 s)
	{
		double v = (double)_ce[o][a][s] - (double)_ce[o][b][s];
		if (c != kNoArm) v -= ((double)_ce[o][c][s] - (double)_ce[o][d][s]);
		return v;
	}
	static Pair _Paired4(uint32 a, uint32 b, uint32 c = kNoArm, uint32 d = kNoArm)
	{
		Pair p;
		double sum = 0.0, sq = 0.0, runSq = 0.0;
		for (uint32 s = 0; s < _seeds; ++s)
		{
			if (!_seedOk[s]) continue;
			double m = 0.0;
			for (uint32 o = 0; o < kOut; ++o) m += _V4(o, a, b, c, d, s);
			m /= (double)kOut;
			sum += m; sq += m * m; ++p.n;
			if (m < 0.0) ++p.win;                 // ⭐ `_Paired` 와 같은 규약(음수 = 첫 팔이 좋다)
			double rv = 0.0;                      // ⚠️ 실행 항(바깥끼리의 흩어짐 — 규율 37)
			for (uint32 o = 0; o < kOut; ++o)
			{
				const double x = _V4(o, a, b, c, d, s) - m;
				rv += x * x;
			}
			runSq += rv / (double)kOut;
		}
		if (p.n == 0u) return p;
		p.d = sum / (double)p.n;
		const double var = (p.n > 1u) ? (sq / (double)p.n - p.d * p.d) * (double)p.n / (double)(p.n - 1u) : 0.0;
		const double runV = runSq / (double)p.n / (double)kOut;
		p.se = Sqrt((float)((var + runV) / (double)p.n));
		p.t = (p.se > 1.0e-12) ? Abs((float)p.d) / p.se : 0.0;
		return p;
	}
	static uint32 _SignPass() { return (_seeds >= 12u) ? 9u : ((_seeds + 1u) / 2u + 1u); }
	static double _MeanOf(const double* v)
	{
		double s = 0.0; uint32 n = 0u;
		for (uint32 i = 0; i < _seeds; ++i) { s += v[i]; ++n; }
		return (n == 0u) ? 0.0 : s / (double)n;
	}
	// ⭐ 회차 210 — 팔별 씨앗 평균(살아 있는 씨앗만) — `_iW`/`_hW` 용
	static double _MeanOfArm(const double (&v)[kArms][kSeedsMax], uint32 a)
	{
		double s = 0.0; uint32 n = 0u;
		for (uint32 i = 0; i < _seeds; ++i) { if (!_seedOk[i]) continue; s += v[a][i]; ++n; }
		return (n == 0u) ? 0.0 : s / (double)n;
	}

	static void _Summary()
	{
		_done = true;
		uint32 ok = 0u;
		for (uint32 s = 0; s < _seeds; ++s) if (_seedOk[s]) ++ok;
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🧿 **회차 181 판정** — 씨앗 %u/%u · 팔 %u · 바깥 %u\n", ok, _seeds, _Arms(), kOut);

		const Pair pCap = _Paired(kOracle, kOracleS);
		const Pair pMv  = _Paired(kMaxV,  kMaxVS);
		const Pair pDir = _Paired(kDir,   kDirS);
		const Pair pWh  = _Paired(kWhich, kWhichS);
		// ⭐ 회차 184 — **표제가 ㈆(어느 물체)다**(183 은 ㈄ 였는데 파일럿이 부호를 뒤집었다)
		//   ⚠️ 회차 194 — 문맥 스윕에서는 낱말이 없어 이 짝이 **뜻이 없다**(아래에서 안 찍는다)
		const Pair& pTop = pWh;

		const double goal = _MeanOf(_goal);
		const double nCh  = _MeanOf(_nScored[kMChange]);
		LogA("[mlt] 🧿   ── ① ⭐ **배관**(규율 68 — 두 길이 만나나) ──\n");
		LogA("[mlt] 🧿     ⭐ **목표선** = `H(다음 칸 | 지금 칸 · 변화만)` = **%.4f** 나트\n", goal);
		// ⚠️⚠️ 회차 180 과 **직접 견주지 않는다** — 표본이 다르다(1씨앗 진단이 그것을 밝혔다):
		//   180 = 물체 **14개 전부**(화면 밖도 「없음」 칸) ⇒ **「없음↔칸」 전이 포함**(엔트로피 높다)
		//   181 = **보이는 물체 중 8개**만 슬롯 ⇒ 그 전이가 빠진다 ⇒ ★ **181 쪽이 채점 대상과 같다**
		//   ⇒ ⭐ 그래서 배관을 **자기 검산**으로 바꾼다: `e^목표선` = **변화 시 도착 칸 수**
		//     (기하평균) ⇒ 눈금 4픽셀에서 이웃이 8 이니 **2~5** 사이여야 한다.
		const double fanout = (double)Exp((float)goal);
		// ⭐ 회차 183 — **방향 모드는 배관을 회차 182 와 직접 견줄 수 있다**
		//   ★ 182 도 「보이는 물체의 슬롯」에서 쟀으므로 ***같은 표본***이다(181 은 달랐다)
		//     ⇒ 규율 68 을 제대로 쓴다: 목표선이 **0.3181 ± 0.05** 여야 한다.
		//   ⚠️ 다만 182 는 **모든 슬롯**(정지 포함)이고 여기는 **변화만** 채점한다
		//     ⇒ ★ 그래서 폭을 ±0.05 로 넉넉히 잡고 **차이를 같이 찍는다**(규율 68 의 단서).
		const bool gPipeS = _dirOn
			? (fanout > 1.5 && fanout < 8.5)          // 방향은 후보가 8+정지 ⇒ 1.5~8.5
			: (fanout > 2.0 && fanout < 5.0);
		LogA("[mlt] 🧿        ⭐ **자기 검산** — `e^목표선` = **%.2f 개** = 변화 시 도착 계급 수(기하평균)\n", fanout);
		if (_dirOn)
		{
			LogA("[mlt] 🧿           방향은 후보가 **8방위 + 정지** ⇒ **1.5~8.5** 사이여야 한다 → %s\n",
				gPipeS ? "✅ ★ **손계산과 맞는다**" : "⛔ **손계산과 다르다** — 표적 생성을 다시 본다");
			LogA("[mlt] 🧿        ⭐ **규율 68 을 제대로 쓴다** — 회차 182 도 「보이는 물체의 슬롯」에서\n");
			LogA("[mlt] 🧿           쟀으므로 ***같은 표본***이다(181 은 달랐다): 182 의 `H(방향|직전)` = **0.3181**\n");
			LogA("[mlt] 🧿           ↔ 여기 **%.4f** · 차 **%.4f** → %s\n", goal, Abs((float)(goal - 0.3181)),
				(Abs((float)(goal - 0.3181)) < 0.05)
					? "✅✅ ⭐ **두 길이 만났다**"
					: "⚠️ **다르다** — ★ 182 는 **모든 슬롯**(정지 포함)이고 여기는 **변화만** 채점한다");
		}
		else
		{
			LogA("[mlt] 🧿           눈금 %u픽셀이라 이웃이 8 ⇒ **2~5** 사이여야 한다 → %s\n", kPx,
				gPipeS ? "✅ ★ **손계산과 맞는다**" : "⛔ **손계산과 다르다** — 표적 생성을 다시 본다");
			LogA("[mlt] 🧿        ⚠️ 회차 180 의 값(전체 0.3678 · 변화만 1.7163)과 **직접 견주지 않는다**\n");
			LogA("[mlt] 🧿           ★ 180 은 **물체 14개 전부**(화면 밖도 「없음」 칸)라 **「없음↔칸」 전이**를\n");
			LogA("[mlt] 🧿             포함하고, 181 은 **보이는 8개**만 슬롯에 준다 ⇒ **표본이 다르다**\n");
			LogA("[mlt] 🧿           ⇒ ⭐ 규율 68 은 **같은 표본**일 때만 쓴다(1씨앗 진단이 밝혔다)\n");
		}
		LogA("[mlt] 🧿     변화 표적 **%.1f**/문맥 · 전체 표적 **%.1f** ⇒ 변화 몫 **%.1f%%**%s\n",
			nCh, _MeanOf(_nTgt),
			(_MeanOf(_nTgt) > 1.0e-9) ? 100.0 * nCh / _MeanOf(_nTgt) : 0.0,
			_dirOn ? " (⚠️ 방향 모드는 「방향이 바뀜」이 변화다)"
			       : ((Abs((float)(nCh - 10.3)) < 1.5) ? " ↔ 180 의 10.3 ✅" : " ↔ 180 의 10.3 ⚠️"));

		if (_blindOn)
		{
			// ⭐ 회차 192 — **㉡ D5: 슬롯 눈감기 곡선**(짝지은 차가 아니라 **CE 절대값**)
			LogA("[mlt] 🧿   ── ⭐ **㉡ D5 — 「슬롯 눈감기」**(회차 192) ──\n");
			LogA("[mlt] 🧿     ★ D5(회차 60)의 막힘 = *\"컨텍스트에 **원본 패치가 없어** 이미 눈감은 상태\"*\n");
			LogA("[mlt] 🧿       ⇒ 옛 표현은 활성만 있어 「끊음/안 끊음」이 **구별되지 않았다**\n");
			LogA("[mlt] 🧿     ⭐ ㉲ 의 새 자 — `t ≥ tCut` 부터 **슬롯 심볼·값을 비운다**(상태 5축만)\n");
			LogA("[mlt] 🧿       ★ 뜻이 있는 이유: ***물체가 identity 로 이어진다*** ⇒ 「끊어도 **그 물체를\n");
			LogA("[mlt] 🧿          기억하나**」를 묻는다 — 옛 표현은 슬롯이 매 시각 밀려 **기억할 대상이 없었다**\n");
			LogA("[mlt] 🧿     ⚠️ 낱말은 **모든 팔에서 상수**다(두 효과가 섞이지 않게)\n");
			LogA("[mlt] 🧿     tCut  남은 슬롯 시각   변화만 CE      유지율(= CE(8)/CE)\n");
			const double base = _M2(0u, 0u) > 0.0 ? 0.0 : 0.0;   // 자리표시(아래에서 다시 계산)
			(void)base;
			double ce8 = 0.0; uint32 n8 = 0u;
			for (uint32 s = 0; s < _seeds; ++s) { if (!_seedOk[s]) continue; ce8 += _M2(0u, s); ++n8; }
			ce8 = (n8 == 0u) ? 0.0 : ce8 / (double)n8;
			bool mono = true; double prev = 0.0;
			for (uint32 a = 0; a < kArms; ++a)
			{
				double ce = 0.0; uint32 n = 0u;
				for (uint32 s = 0; s < _seeds; ++s) { if (!_seedOk[s]) continue; ce += _M2(a, s); ++n; }
				ce = (n == 0u) ? 0.0 : ce / (double)n;
				LogA("[mlt] 🧿     %4u  %8u        %.5f       **%.3f**%s\n",
					_TCutOf(a), _TCutOf(a), ce, (ce > 1.0e-9) ? ce8 / ce : 0.0,
					(a == 0u) ? "   ← 기준(안 끊음)" : ((a + 1u == kArms) ? "   ← 상태만(하한)" : ""));
				// ⚠️⚠️ **`tCut = 1` 은 특이점이라 단조에서 뺀다**(1씨앗 진단이 밝혔다):
				//   `tCut=1` 은 **모든 시각의 슬롯이 비어** 몸통이 「슬롯 없음」을 **일관되게** 배운다
				//   ↔ `tCut=2` 는 t=0 만 슬롯이 있어 **불일치한 입력**이라 오히려 어렵다
				//   ⇒ ★ 실측 tCut 2 → 1.605 · tCut 1 → 1.457(내려간다) ⇒ **일관성이 이긴다**
				if (a > 0u && a + 1u < kArms && ce < prev - 0.03) mono = false;
				prev = ce;
			}
			LogA("[mlt] 🧿     🚪 **단조**(tCut 8→2 · ⚠️ tCut 1 은 **특이점**이라 뺀다) → %s\n",
				mono ? "✅" : "⚠️ **단조가 아니다** — 배관을 다시 본다");
			LogA("[mlt] 🧿        ★ tCut 1 을 빼는 이유: **모든 시각이 비어 일관**되므로 tCut 2(t=0 만\n");
			LogA("[mlt] 🧿          슬롯이 있어 **불일치**)보다 **쉽다** ⇒ 그 자리에서 곡선이 꺾인다\n");
			LogA("[mlt] 🧿     🚪 **배관** — 기준 CE **%.5f** ↔ 회차 187 의 몸통 **1.40 근처** → %s\n",
				ce8, (ce8 > 1.25 && ce8 < 1.60) ? "✅" : "⚠️ **다르다**");
			LogA("[mlt] 🧿     ⭐ **표제 = D5 청산** — 유지율이 **정의되고 값이 나오나**\n");
			LogA("[mlt] 🧿        ⇒ ✅✅ ***D5 가 청산된다*** — ★ 문턱이 *\"값이 좋을 필요 없고 잴 수 있으면 된다\"* 다\n");
			LogA("[mlt] 🧿        ⚠️ 유보 — 표적이 **1스텝(다음 방향)**이고 방향은 **관성이 강하다**(182: 0.32)\n");
			LogA("[mlt] 🧿           ⇒ ★ 직전 한 시각이 거의 전부라 **이 자로 「경험」을 재기엔 약하다**\n");
			LogA("[mlt] 🧿           ⇒ ⭐ 그것은 **자의 한계**이고 D5 의 문턱(정의 가능)과는 별개다\n");
		}
		if (_shufOn)
		{
			// ⭐ 회차 193 — **㉢ D7 지름길 지도**(CE 절대값)
			static const char* nm[kArms] = {
				"㈀ 기준(안 섞음)  ", "⭐ ㈁ **값**(깊이)  ", "㈂ 심볼(지금 방향)",
				"⭐ ㈃ **상태 5축** ", "⭐ ㈄ **표적**(학습만)", "㈅ 값+심볼        ",
				"㈆ 전부(값+심볼+상태)", "㈇ 기준 재현(검산) " };
			LogA("[mlt] 🧿   ── ⭐ **㉢ D7 — 지름길 지도**(회차 193) ──\n");
			LogA("[mlt] 🧿     ★ ㉲ 가 D7 의 여섯 중 **넷을 지웠다**(인코더도 패치도 없다)\n");
			LogA("[mlt] 🧿       ⇒ 남은 둘 = **값 섞기**(㈁) · **과제 섞기**(㈄) · 불투명 낱말은 ✅ 이미\n");
			LogA("[mlt] 🧿     ⚠️ 섞기 = **문맥 사이 교환** ⇒ **주변분포는 그대로 · 상관만 깨진다**\n");
			LogA("[mlt] 🧿       ⚠️⚠️ **양쪽(학습+시험) 다** 섞는다(D7 은 *\"끊고 **학습**시킨다\"*) ·\n");
			LogA("[mlt] 🧿          ⭐ 예외는 **표적**뿐(시험을 섞으면 **자가 무너진다**)\n");
			LogA("[mlt] 🧿     섞은 것              변화만 CE     기준 대비\n");
			double base = 0.0; uint32 nb = 0u;
			for (uint32 s = 0; s < _seeds; ++s) { if (!_seedOk[s]) continue; base += _M2(0u, s); ++nb; }
			base = (nb == 0u) ? 0.0 : base / (double)nb;
			double ceArm[kArms];
			for (uint32 a = 0; a < kArms; ++a)
			{
				double ce = 0.0; uint32 n = 0u;
				for (uint32 s = 0; s < _seeds; ++s) { if (!_seedOk[s]) continue; ce += _M2(a, s); ++n; }
				ceArm[a] = (n == 0u) ? 0.0 : ce / (double)n;
				LogA("[mlt] 🧿     %-20s  %.5f      **%+.4f**\n", nm[a], ceArm[a], ceArm[a] - base);
			}
			LogA("[mlt] 🧿     🚪 **검산**(㈇ 기준 재현 ↔ ㈀) — 차 **%.4f** → %s\n",
				Abs((float)(ceArm[7] - base)),
				(Abs((float)(ceArm[7] - base)) < 0.02) ? "✅ 섞기 배관이 기준을 안 건드렸다" : "⛔ **배관이 샜다**");
			// ⚠️⚠️ **문턱을 고쳤다**(1씨앗 진단이 밝혔다) — 처음엔 *"㈄ > 2.0 이면 학습이 실재"* 로
			//   걸었는데 ⛔ **그것이 틀렸다**: 표적을 섞어도 몸통은 ***주변분포***(어느 방향이 흔한가)를
			//   배운다 ⇒ ★ 올바른 기준은 **`H(변화 표적)`** 이다(그 위로 못 간다 = 상관을 못 배웠다).
			const double hTgt = _MeanOf(_hT);
			LogA("[mlt] 🧿     🚪 **㈄ 가 「주변분포만」인가**(표적 섞기 ↔ `H(변화 표적)` **%.4f**)\n", hTgt);
			LogA("[mlt] 🧿        실측 **%.5f** · 차 **%+.4f** → %s\n", ceArm[4], ceArm[4] - hTgt,
				(Abs((float)(ceArm[4] - hTgt)) < 0.15)
					? "✅ ★ **상관을 못 배웠다 = 지름길이 끊겼다**(주변분포만 남는다)"
					: ((ceArm[4] < hTgt) ? "⚠️ **주변분포보다 낫다** — ★ 섞은 표적에도 구조가 남았나 본다"
					                     : "⚠️ **주변분포보다 나쁘다** — 학습이 해를 끼쳤다"));
			LogA("[mlt] 🧿     🚪 **192 와 교차검증** — ㈂(심볼 섞기) **%.5f** ↔ 192 의 `tCut=1` **1.563**\n", ceArm[2]);
			LogA("[mlt] 🧿        차 **%.4f** → %s\n", Abs((float)(ceArm[2] - 1.563)),
				(Abs((float)(ceArm[2] - 1.563)) < 0.08)
					? "✅ ★ **두 자가 만난다**(규율 68) — 둘 다 「슬롯을 무력화」다"
					: "⚠️ **다르다** — ★ 「끊음」과 「섞음」이 다른 것을 잰다(적어 둔다)");
			LogA("[mlt] 🧿     ⭐ **표제 = D7 청산** — ㈁·㈄ 의 값이 나왔나\n");
			LogA("[mlt] 🧿        ㈁ 값 섞기 **%+.4f** · ㈄ 과제 섞기 **%+.4f** ⇒ ✅✅ ***측정됐다***\n",
				ceArm[1] - base, ceArm[4] - base);
			// ⭐ 회차 193 — **192 의 해석을 검산한다: 상태 ↔ 슬롯이 대체 가능한가**
			LogA("[mlt] 🧿     ⭐ **192 검산 — 상태와 슬롯 중 누가 주역인가**\n");
			LogA("[mlt] 🧿        192: 슬롯을 끊으면(상태만) **1.563** ⇒ *\"방향의 90%%가 상태에서 온다\"*\n");
			LogA("[mlt] 🧿        193: 상태를 섞으면(슬롯만) **%.5f** · 기준 **%.5f** ⇒ 상태 기여 **%+.4f**\n",
				ceArm[3], base, ceArm[3] - base);
			LogA("[mlt] 🧿        ⇒ %s\n",
				(ceArm[3] - base < 0.05)
					? "★ ***상태가 잉여다*** — 슬롯만으로 기준에 닿는다\n"
					  "[mlt] 🧿           ⇒ ⭐ **192 의 해석이 반대였다**: 두 축이 **서로 대체 가능**하고\n"
					  "[mlt] 🧿              「끊음 곡선」은 **남은 쪽이 대신 메운다**는 것을 못 본다\n"
					  "[mlt] 🧿           ⇒ ★ 규율 84 에 단서가 붙는다: ***한 축만 끊으면 대체를 못 가른다***"
					: "⚠️ 상태도 기여한다 ⇒ ★ 192 의 해석이 유지된다");
			LogA("[mlt] 🧿     ⚠️⚠️ **유보** — 양쪽에 섞으면 그 축이 **애초에 없는 세계**를 배우는 것이라\n");
			LogA("[mlt] 🧿        CE 가 **덜 나빠질 수 있다**(모델이 적응한다) ⇒ ★ 이것은 **「의존도」가 아니라\n");
			LogA("[mlt] 🧿        「그 축 없이 배울 수 있나」**의 값이다\n");
		}
		if (_ctxSweep && !_l2ctx)
		{
			// ⭐ 회차 194 — **표본 곡선**(칸 1 조건 ㉠ · CE 절대값)
			//   ★ 세 문맥을 **한 회차의 팔로** 잰다 ⇒ 규율 65(그 자리의 값) + 규율 83(외삽 금지)
			LogA("[mlt] 🧿   ── ⭐ **㉠ 표본 곡선**(회차 194 · 칸 1 조건 ㉠) ──\n");
			LogA("[mlt] 🧿     ⚠️ 8192 만 재고 187(2048)·193(512)와 견주면 **규율 65** 에 걸리고,\n");
			LogA("[mlt] 🧿        두 점으로 외삽하면 **규율 83** 이다 ⇒ ★ **세 점을 한 자리에서** 잰다\n");
			LogA("[mlt] 🧿     ⚠️⚠️ **걸음이 표본의 천장이다** — `SelectStep(_step %% _PoolSteps())` 이라\n");
			LogA("[mlt] 🧿        모델이 보는 문맥은 **min(문맥, 걸음 %u × 배치 %u = %u)** 다\n",
				_steps, kBatch, _steps * kBatch);
			LogA("[mlt] 🧿        ⇒ ★ 8192 의 실효 배수는 16 이 아니라 **%.1f배** 다\n",
				(double)(_steps * kBatch) / (double)kNCtxBase);
			LogA("[mlt] 🧿     문맥      실효 문맥   변화만 CE     목표선 대비    ⭐ 활용률\n");
			// ⭐ 활용률 = (배치만 CE − CE) ÷ (배치만 CE − 목표선)
			//   ★ 193 이 「배치만」을 실측했다(입력 전부 섞음 **1.465**) ⇒ 그것이 이 자의 0점이다.
			const double shufBase = 1.465;
			double ceC[kCtxArms]; bool mono = true;
			for (uint32 a = 0; a < kCtxArms; ++a)
			{
				double ce = 0.0; uint32 n = 0u;
				for (uint32 s = 0; s < _seeds; ++s) { if (!_seedOk[s]) continue; ce += _M2(a, s); ++n; }
				ceC[a] = (n == 0u) ? 0.0 : ce / (double)n;
				const uint32 eff = (kCtxOf[a] < _steps * kBatch) ? kCtxOf[a] : (_steps * kBatch);
				const double util = (shufBase - goal > 1.0e-9) ? 100.0 * (shufBase - ceC[a]) / (shufBase - goal) : 0.0;
				LogA("[mlt] 🧿     %6u    %7u     %.5f      **%+.2f%%**      **%.1f%%**%s\n",
					kCtxOf[a], eff, ceC[a],
					(goal > 1.0e-9) ? 100.0 * (ceC[a] - goal) / goal : 0.0, util,
					(a + 1u == kCtxArms) ? "  ⭐ 표제" : "");
				if (a > 0u && ceC[a] > ceC[a - 1u]) mono = false;
			}
			// ⚠️⚠️ **회차 204 가 이 관문 문구를 고치게 했다** — 193 의 **1.410** 은 **옛 세계**의
			//   값이다. 세계를 바꾸면 그것과 견주는 것이 **규율 65 위반**이다(그 자리의 값이 아니다).
			//   ⇒ ★ 그래서 **세계마다 짝을 바꾼다**: 궤도 세계는 **203 의 q=0(1.17995)** 이 짝이다.
			{
				const double ref = (_w2 == 2) ? 1.17995 : 1.410;
				const char* refN = (_w2 == 2) ? "203 의 q=0(궤도)" : "193 의 기준(옛 세계)";
				LogA("[mlt] 🧿     🚪 ① **배관** — ㈀(512) **%.5f** ↔ %s **%.5f** → %s\n",
					ceC[0], refN, ref,
					(Abs((float)(ceC[0] - ref)) < 0.012)
						? "✅ **그 자리에서 재현됐다**"
						: "⚠️ **다르다** — ★ 그 차이가 곧 「자리 효과」다(규율 65)");
			}
			LogA("[mlt] 🧿     🚪 ④ **곡선 단조**(표본이 늘수록 CE 가 내려가나) → %s\n",
				mono ? "✅" : "⛔ **단조가 아니다** — ★ 표본이 아니라 다른 것이 움직였다");
			LogA("[mlt] 🧿     ⭐ 🚪 ③ **표제 — `P3` 이 서나**(㈂ CE **%.5f** < 목표선 **%.4f**) → %s\n",
				ceC[kCtxArms - 1u], goal,
				(ceC[kCtxArms - 1u] < goal)
					? "✅✅ ⭐ ***칸 1 조건 ㉠ 이 닫힌다***"
					: "⛔ **아직 못 넘는다** ⇒ ★ 그러면 남은 것은 **㉠′**(사람이 정할 자리)다");
			LogA("[mlt] 🧿     ⭐ 🚪 ⑤ **표본이 산 것** — 활용률 %.1f%% → %.1f%%(**%+.1f%%p**)\n",
				(shufBase - goal > 1.0e-9) ? 100.0 * (shufBase - ceC[0]) / (shufBase - goal) : 0.0,
				(shufBase - goal > 1.0e-9) ? 100.0 * (shufBase - ceC[kCtxArms - 1u]) / (shufBase - goal) : 0.0,
				(shufBase - goal > 1.0e-9) ? 100.0 * (ceC[0] - ceC[kCtxArms - 1u]) / (shufBase - goal) : 0.0);
			LogA("[mlt] 🧿        ⚠️ 「배치만」의 0점 **%.3f** 은 **193 의 실측**(입력 전부 섞음)이고\n", shufBase);
			LogA("[mlt] 🧿           그것은 **문맥 512** 자리의 값이다 ⇒ ★ 활용률은 **추세로** 읽는다(규율 65)\n");
			LogA("[mlt] 🧿           ⚠️⚠️ **100%% 를 넘을 수 있다** — 목표선은 *\"직전 방향만 아는 예측자\"* 인데\n");
			LogA("[mlt] 🧿              몸통은 **8시각 전체**를 본다 ⇒ ★ 넘는 것이 **자연스럽다**(자의 결함이 아니다)\n");

			// ⭐ 회차 194 — **짝지은 차로 표제를 잰다**(규율 29 — 씨앗마다 목표선이 다르다)
			//   ★ 씨앗별 목표선이 1.36~1.40 로 갈리므로 **CE − 목표선**을 씨앗 안에서 짝지어야 한다.
			{
				const uint32 aT = kCtxArms - 1u;
				double d[kSeedsMax]; uint32 nd = 0u, win = 0u; double sum = 0.0;
				for (uint32 s = 0; s < _seeds; ++s)
				{
					if (!_seedOk[s]) continue;
					d[nd] = _M2(aT, s) - _goal[s];
					if (d[nd] < 0.0) ++win;
					sum += d[nd]; ++nd;
				}
				const double db = (nd == 0u) ? 0.0 : sum / (double)nd;
				double var = 0.0;
				for (uint32 i = 0; i < nd; ++i) var += (d[i] - db) * (d[i] - db);
				const double sig = (nd > 1u) ? Sqrt((float)(var / (double)(nd - 1u))) : 0.0;
				const double se  = (nd > 0u) ? sig / Sqrt((float)(double)nd) : 0.0;
				const double tt  = (se > 1.0e-12) ? Abs((float)db) / se : 0.0;
				LogA("[mlt] 🧿     ⭐ **짝지은 차 `CE(8192) − 목표선`**(규율 29 — 씨앗마다 목표선이 다르다)\n");
				LogA("[mlt] 🧿        d̄ **%+.5f** · σ **%.5f** · SE **%.5f** · **|d̄|/SE %.2f** · 이긴 씨앗 **%u/%u**\n",
					db, sig, se, tt, win, nd);
				if (Abs((float)db) > 1.0e-9 && sig > 1.0e-12)
				{
					const double need = (3.0 * sig / Abs((float)db)) * (3.0 * sig / Abs((float)db));
					// ⚠️ 234 — **`kSeedsMax`(상한)가 아니라 `_seeds`(이번에 돈 수)와 견준다.**
					//   상한을 24 로 연 뒤에도 이 물음은 *"지금 돌린 예산으로 되나"* 다.
					LogA("[mlt] 🧿        ⇒ `t ≥ 3` 에 필요한 씨앗 = **%.0f**(이번 %u) → %s\n", need, _seeds,
						(need <= (double)_seeds) ? "✅ **이 예산이면 판정한다**"
						                         : "🔶 **이 예산으로는 t 3 을 못 얻는다**(규율 77) — ★ 관문 문구는 **평균 비교**다");
				}
			}

			// ⭐ 회차 194 — **표본이 산 것은 「평균」이 아니라 「분산」이다**(파일럿이 찾았다)
			//   ★ 바깥 둘의 차 = **실행 잡음**(같은 씨앗·같은 데이터 · 초기화와 순서만 다르다)
			//   ⇒ ⭐ 이것이 규율 37(*"표제 관문은 두 번 돌린다"*)이 재는 그 양이고,
			//     ⚠️ **절대 CE 를 회차 사이에 견주려면 이 값을 먼저 봐야 한다**(짝지은 차는 안전하다).
			if (kOut >= 2u)
			{
				LogA("[mlt] 🧿     ⭐ **실행 잡음**(바깥 0 ↔ 바깥 1 · 같은 씨앗·같은 데이터)\n");
				LogA("[mlt] 🧿        문맥      평균 |Δ|      최대 |Δ|\n");
				double n0 = 0.0;
				for (uint32 a = 0; a < kCtxArms; ++a)
				{
					double sd = 0.0, mx = 0.0; uint32 n = 0u;
					for (uint32 s = 0; s < _seeds; ++s)
					{
						if (!_seedOk[s]) continue;
						const double dd = Abs((float)((double)_ce[0][a][s] - (double)_ce[1][a][s]));
						sd += dd; if (dd > mx) mx = dd; ++n;
					}
					const double av = (n == 0u) ? 0.0 : sd / (double)n;
					if (a == 0u) n0 = av;
					LogA("[mlt] 🧿        %6u    **%.5f**    %.5f%s\n", kCtxOf[a], av, mx,
						(a + 1u == kCtxArms && av > 1.0e-9)
							? "   ⭐ 여기가 표제 자리다" : "");
				}
				double nL = 0.0; uint32 nn = 0u;
				for (uint32 s = 0; s < _seeds; ++s)
				{
					if (!_seedOk[s]) continue;
					nL += Abs((float)((double)_ce[0][kCtxArms - 1u][s] - (double)_ce[1][kCtxArms - 1u][s])); ++nn;
				}
				nL = (nn == 0u) ? 0.0 : nL / (double)nn;
				LogA("[mlt] 🧿        ⇒ ⭐ 512 → 8192 로 실행 잡음이 **%.1f배** 줄었다 → %s\n",
					(nL > 1.0e-9) ? n0 / nL : 0.0,
					(nL < n0 * 0.5) ? "✅ ★ ***표본이 사는 것은 재현성이다***"
					                : "⚠️ **안 줄었다** — ★ 그러면 표본의 이득은 평균에만 있다");
				LogA("[mlt] 🧿        ⚠️⚠️ **그리고 이것이 배관 ① 의 답이다** — 193 의 512 기준(1.410)과\n");
				LogA("[mlt] 🧿           여기 512(**%.5f**)의 차 **%.4f** 가 그 자리의 잡음 **%.4f** 안이면\n",
					ceC[0], Abs((float)(ceC[0] - 1.410)), n0);
				LogA("[mlt] 🧿           ★ *\"재현이 안 된다\"* 가 아니라 ***\"512 자리는 애초에 못 재는 자리다\"*** → %s\n",
					(Abs((float)(ceC[0] - 1.410)) < n0) ? "✅ **잡음 안이다**" : "⚠️ **잡음보다 크다**");
			}
		}
		if (_effOn)
		{
			// ⭐ 회차 226 — **efference copy**(재유입 상쇄) · 새 캔버스 `사본을 만든다`
			LogA("[mlt] 🧿   ── ⭐ **efference copy 관문**(회차 226) ──\n");
			LogA("[mlt] 🧿     ⚙️ 폰 홀스트(1950) — 자기 움직임이 만든 감각 변화를 세상의 변화와\n");
			LogA("[mlt] 🧿        가르는 길은 **운동 명령의 사본**을 감각 쪽으로 보내 상쇄하는 것뿐이다\n");
			LogA("[mlt] 🧿     ⚠️⚠️ 221~224 는 행동을 **입력 슬롯으로만** 줬다(표적이 아니었다)\n");
			LogA("[mlt] 🧿        ⇒ ★ **사본이 원리적으로 안 생긴다** ⇒ 오귀속률 0 이 **예상된 결과**다\n");
			LogA("[mlt] 🧿     ⭐ 처방(P5 를 안 열고): 행동으로 **「감각 결과」를 예측하게** 한다\n");
			LogA("[mlt] 🧿        표적 = ***내 명령이 화면 전체를 어느 쪽으로 미나***(흐름 방향 10계급)\n");
			LogA("[mlt] 🧿     ✅ D7 위반이 아니다 — 입력은 `dYaw` **값** · 표적은 **흐름 방향**(다른 것)\n");
			LogA("[mlt] 🧿     ⚠️ 그리고 표적을 **한 시각 뒤 자리**에 둔다 — 같은 자리면 **자명하다**\n");
			LogA("[mlt] 🧿        (그 시각 슬롯 방향이 이미 입력이라 평균만 하면 나온다)\n");
			LogA("[mlt] 🧿     ⭐ 표적 어휘가 슬롯과 **같다**(방향 10) ⇒ 212 와 달리 출력 어휘를 **안 늘린다**\n");
			LogA("[mlt] 🧿     ⚠️ 「상수로 둔 것」 — 흐름을 **보이는 슬롯 8개의 평균**으로 뒀다(근거 = 모델이\n");
			LogA("[mlt] 🧿        보는 것과 같게) · `dYaw` 하나만 입력이다(그것이 흐름을 지배할 것 — 손계산)\n");
			double ce0 = 0.0, ce7 = 0.0; uint32 n0 = 0u;
			for (uint32 s = 0; s < _seeds; ++s)
			{
				if (!_seedOk[s]) continue;
				ce0 += _M2(0u, s); ce7 += _M2(7u, s); ++n0;
			}
			ce0 = (n0 == 0u) ? 0.0 : ce0 / (double)n0;
			ce7 = (n0 == 0u) ? 0.0 : ce7 / (double)n0;
			double nz = 0.0; uint32 nn = 0u;
			if (kOut >= 2u)
				for (uint32 a = 0; a < kEffArms; ++a)
					for (uint32 s = 0; s < _seeds; ++s)
					{
						if (!_seedOk[s]) continue;
						nz += Abs((float)((double)_ce[0][a][s] - (double)_ce[1][a][s])); ++nn;
					}
			nz = (nn == 0u) ? 0.0 : nz / (double)nn;
			LogA("[mlt] 🧿     🚪 ① **검산** — ㈇(λ0 재현) **%.5f** ↔ ㈀ **%.5f** · 차 **%.4f** → %s\n",
				ce7, ce0, Abs((float)(ce7 - ce0)),
				(Abs((float)(ce7 - ce0)) < 3.0 * nz) ? "✅" : "⛔ **배관이 샜다**");
			LogA("[mlt] 🧿     λ      변화만 CE   ⭐ **낙폭**    섞음 CE    ⭐ **낙폭−섞음낙폭**\n");
			double best = 0.0; bool ok = false; double dd[3];
			for (uint32 k = 1u; k <= 3u; ++k)
			{
				double a1 = 0.0, a2 = 0.0; uint32 n = 0u;
				for (uint32 s = 0; s < _seeds; ++s)
				{
					if (!_seedOk[s]) continue;
					a1 += _M2(k, s); a2 += _M2(k + 3u, s); ++n;
				}
				a1 = (n == 0u) ? 0.0 : a1 / (double)n;
				a2 = (n == 0u) ? 0.0 : a2 / (double)n;
				const double dr = a1 - ce0, ds = a2 - ce0;
				dd[k - 1u] = dr - ds;
				if (Abs((float)dr) < nz) { ok = true; best = (double)kEffOf[k]; }
				LogA("[mlt] 🧿     %.2f   %.5f   **%+.4f**    %.5f   **%+.4f**%s\n",
					(double)kEffOf[k], a1, dr, a2, dr - ds,
					(Abs((float)dr) < nz) ? "  ✅ 잡음 안" : "  ⚠️ 잡음 밖");
			}
			// ⭐ 228 — **부채 D40 을 갚는다**: 「차의 차」에 **SE·`t`** 를 붙인다
			//   ⚠️ 227 은 평균만 있고 실행 잡음과만 견줬다 ⇒ ***「측정」이라 부르려면 SE 가 필요하다***
			//     (규율 29·37) ⇒ ⭐ 213 이 만든 `_Paired4` 가 그것을 **공짜로** 준다.
			LogA("[mlt] 🧿     ── ⭐ **짝지은 차**(부채 D40 · 규율 29·37) ──\n");
			LogA("[mlt] 🧿        λ      낙폭 d̄     SE      t      │ 차의 차 d̄    SE      **t**    이긴씨앗\n");
			double bt = 0.0; uint32 bl = 0u; bool stand = false;
			for (uint32 k = 1u; k <= 3u; ++k)
			{
				const Pair pd = _Paired4(k, 0u);                    // 낙폭
				const Pair px = _Paired4(k, 0u, k + 3u, 0u);        // ⭐ 차의 차
				if (px.d < 0.0 && px.t > bt) { bt = px.t; bl = k; }
				if (px.d < 0.0 && px.t >= 3.0) stand = true;
				LogA("[mlt] 🧿        %.2f  %+.5f  %.5f  %5.2f  │ %+.5f  %.5f  **%5.2f**  %u/%u\n",
					(double)kEffOf[k], pd.d, pd.se, pd.t, px.d, px.se, px.t, px.win, px.n);
			}
			LogA("[mlt] 🧿        ⭐ 🚪 **D40 관문 — `t ≥ 3` 인 λ 가 있나** → %s\n",
				stand ? "✅✅ ⭐ ***사본이 「측정」으로 섰다*** — 227 의 평균 비교를 확정한다"
				      : (bl > 0u ? "🔶 **부호는 맞고 `t` 가 3 을 못 넘는다**(규율 77 로 필요 씨앗을 읽는다)"
				                 : "⛔ **부호도 안 선다**"));
			if (bl > 0u) LogA("[mlt] 🧿        ⭐ 최선 λ = **%.2f**(`t` %.2f)\n", (double)kEffOf[bl], bt);
			LogA("[mlt] 🧿        ⚠️ **봉우리가 가둬졌나** — 기준이 λ0 이고 격자가 %.2f·%.2f·%.2f 다 → %s\n",
				(double)kEffOf[1], (double)kEffOf[2], (double)kEffOf[3],
				(bl == 2u) ? "✅ **안쪽이 최선이다** — 봉우리를 가뒀다"
				           : "⚠️ **끝점이 최선이다** — ★ 그러면 «최선» 이라고 못 한다(더 밖을 봐야 한다)");
			LogA("[mlt] 🧿     ⭐ 🚪 ② **표제 — 사본이 본 과제를 돕나**(낙폭이 **음수**면 도움)\n");
			LogA("[mlt] 🧿        실행 잡음 **%.5f** · 낙폭−섞음낙폭 %+.4f · %+.4f · %+.4f\n",
				nz, dd[0], dd[1], dd[2]);
			LogA("[mlt] 🧿        판정 → %s\n",
				((dd[0] < -nz) || (dd[1] < -nz) || (dd[2] < -nz))
					? "✅✅ ⭐ ***진짜 흐름이 섞은 것보다 낫다 — 사본이 생겼다***"
					: (ok ? "🔶 **`P` 가 안 무너진다(예산은 낸다)** — ★ 그런데 **섞음보다 낫다고는 못 한다**"
					      : "⛔ **낙폭이 잡음 밖이다** — ★ 사본이 본 과제를 **깎는다**"));
			LogA("[mlt] 🧿        ⚠️ 최대 안전 λ = **%.2f**%s\n", best, ok ? "" : "(없다)");
			LogA("[mlt] 🧿        ⓘ 견줄 자리 — 212 의 캡션은 λ 1.0 까지 잡음 안이고 **섞음보다 −0.011~−0.014**\n");
		}
		if (_capOn)
		{
			// ⭐ 회차 225 — **용량이 병목인가**(새 캔버스)
			LogA("[mlt] 🧿   ── ⭐ **용량 스윕**(회차 225 · 칸 1·2·3 이 같은 이유로 🔶 다) ──\n");
			LogA("[mlt] 🧿     ⚙️ 활용률 오라클 **0.68** · 캡션 **0.13** · 행동 **≤ 0.23**\n");
			LogA("[mlt] 🧿        ⇒ ★ 병목은 *\"무엇을 넣나\"* 가 아니라 ***\"몸통이 그것을 쓰는 능력\"***\n");
			LogA("[mlt] 🧿     ⭐ 146 이 이 갈래(㉠ 용량)를 찍어 놓고 **안 골랐다** — 미룬 이유가\n");
			LogA("[mlt] 🧿        *\"상수를 바꾸면 검산 사슬이 끊긴다\"* 였는데 **150 이 런타임으로 열었다**\n");
			LogA("[mlt] 🧿     ⭐ 그리고 **224 가 근거를 보탰다**(D38): 축에 **무작위 변동만** 넣어도\n");
			LogA("[mlt] 🧿        CE 가 −0.022 ⇒ ***축이 준 것이 「정보」가 아니라 「파라미터」였다***\n");
			LogA("[mlt] 🧿     ⚠️ **아래로도 본다**(d 64) — 줄여서 활용률이 내려가면 그것이 **양성 대조**다\n");
			LogA("[mlt] 🧿        ★ 없으면 *\"늘려도 안 오른다\"* 를 *\"손잡이가 아니다\"* 와 **못 가른다**(규율 2)\n");
			LogA("[mlt] 🧿     ⚠️ 「상수로 둔 것」 — **`lr` 이 새 용량에서도 최적일 것**(근거 없음 · 201·204 가 그것으로 틀렸다)\n");
			LogA("[mlt] 🧿        `ff = 8/3·d` 규약 유지 · `layer` 는 **4 로 고정**(축 하나만 흔든다)\n");
			LogA("[mlt] 🧿     dim   ff    섞음 CE    `Î`(캡션)  몸통 |d̄|  ⭐ **활용률**    t     이긴씨앗\n");
			double util[3], iw[3], dmv[3], tt[3], ceS[3];
			for (uint32 k = 0; k < 3u; ++k)
			{
				const Pair p = _Paired(2u * k, 2u * k + 1u);
				double ce = 0.0; uint32 n = 0u;
				for (uint32 s = 0; s < _seeds; ++s) { if (!_seedOk[s]) continue; ce += _M2(2u * k + 1u, s); ++n; }
				ceS[k] = (n == 0u) ? 0.0 : ce / (double)n;          // 섞음 팔 = 「정보 없는 낱말」
				const double iB = _MeanOfArm(_iWb, 2u * k) - _MeanOfArm(_iWb, 2u * k + 1u);
				iw[k] = iB; dmv[k] = Abs((float)p.d); tt[k] = p.t;
				util[k] = (Abs((float)iB) > 1.0e-9) ? dmv[k] / iB : 0.0;
				LogA("[mlt] 🧿     %4u %5u  %.5f    %+.4f   %.5f    **%.2f**   %5.2f   %u/%u\n",
					kCapDim[k], kCapFF[k], ceS[k], iB, dmv[k], util[k], p.t, p.win, p.n);
			}
			LogA("[mlt] 🧿     🚪 ① **배관** — `Î` 가 세 용량에서 같나(세계의 성질이라 **용량 무관**이어야 한다)\n");
			LogA("[mlt] 🧿        %+.4f · %+.4f · %+.4f → %s\n", iw[0], iw[1], iw[2],
				(Abs((float)(iw[0] - iw[2])) < 0.02 && Abs((float)(iw[1] - iw[2])) < 0.02)
					? "✅ **같다**" : "⛔ **다르다** — ★ 그러면 활용률을 용량끼리 못 견준다(분모가 갈렸다)");
			LogA("[mlt] 🧿     ⭐ 🚪 ② **표제 — 활용률이 용량에 단조 증가하나**\n");
			LogA("[mlt] 🧿        %.2f → %.2f → %.2f → %s\n", util[0], util[1], util[2],
				((util[0] < util[1]) && (util[1] < util[2]))
					? "✅✅ ⭐ ***용량이 병목이다*** — ★ 세 칸을 동시에 미는 손잡이를 찾았다"
					: ((util[2] > util[0])
						? "🔶 **양 끝은 오르는데 단조가 아니다** — ★ 잡음 안일 수 있다(`t` 를 본다)"
						: "⛔ **안 오른다** ⇒ ★ 용량이 아니라 **표현/최적화**다 — 처방이 완전히 다르다"));
			LogA("[mlt] 🧿        ⚠️⚠️ **`t` 가 3 을 못 넘는 칸의 활용률은 읽지 마라**(공용 규율 15)\n");
			LogA("[mlt] 🧿           t = %.2f · %.2f · %.2f\n", tt[0], tt[1], tt[2]);
			LogA("[mlt] 🧿     🚪 ③ **양성 대조** — d 64 가 d 128 보다 **낮나**(줄이면 나빠져야 한다) → %s\n",
				(util[0] < util[1]) ? "✅ **낮다** — 손잡이가 듣는다" : "⛔ **안 낮다** — ★ 손잡이가 아닐 수 있다");
			LogA("[mlt] 🧿     ⓘ ④ 견줄 자리 — 211a 의 심볼 캡션 `d̄` **−0.04628**(`t` 4.37) · 활용률 **0.13**\n");
			LogA("[mlt] 🧿     ⚠️ ⑤ **`P3` 는 섞음 팔로 읽는다**(이 배치에 「낱말 없는 팔」이 없다)\n");
			LogA("[mlt] 🧿        초과 %+.1f%% · %+.1f%% · %+.1f%%(목표선 %.4f) → %s\n",
				100.0 * (ceS[0] - goal) / goal, 100.0 * (ceS[1] - goal) / goal,
				100.0 * (ceS[2] - goal) / goal, goal,
				(ceS[2] < goal) ? "✅ **d 192 에서도 `P3` 가 선다**"
				                : "⚠️ **d 192 에서 `P3` 가 무너진다** — ★ 공용 규율 11(바퀴 수)의 자리다");
		}
		if (_actOn)
		{
			// ⭐ 회차 221 — **칸 3 조건 ㈀·㈁ 관문**(행동 배관 + 몸통이 읽나)
			LogA("[mlt] 🧿   ── ⭐ **행동 축 관문**(회차 221 · 칸 3 조건 ㈀·㈁) ──\n");
			LogA("[mlt] 🧿     ⚙️ 축 하나(`dYaw` 정규화)를 **맨 뒤**에 붙였다 ⇒ 기존 색인 무변경\n");
			LogA("[mlt] 🧿     ⭐ **천장은 학습 0 이 이미 줬다**(220): `dYaw` 9계급 여지 **0.1166 나트**\n");
			LogA("[mlt] 🧿        ⇒ ★ 규율 49(천장을 먼저) · 규율 67(분모는 **그 낱말의** 정보량) 만족\n");
			LogA("[mlt] 🧿     ⚠️ 「상수로 둔 것」 — 행동을 `dYaw` **하나**로 · 축을 **맨 뒤**에(근거 없음)\n");
			// ⭐ **회차 222 — 표제를 옮겼다**(221a 파일럿이 등록을 고쳤다 · 184 의 관용구)
			//   ⛔ 221 은 **값 통로**를 표제로 등록했는데 파일럿이 **+0.018**(해롭다)을 냈고
			//     **계급 통로**가 **−0.056**(t 28.5)로 크게 이겼다.
			//   ⇒ ★ ***행동은 이산 계급으로 줘야 쓰인다*** ⇒ ⚠️ **회차 안에서 안 바꾸고** 새로 등록했다.
			const Pair pAc = _Paired(3u, 4u);   // ⭐ 표제 — 행동 **계급 9** ↔ 섞음
			const Pair pAv = _Paired(1u, 2u);   // 견줌 — 행동 값(연속) ↔ 섞음
			const uint32 pass = _SignPass();
			LogA("[mlt] 🧿     견줌                │ d̄        · SE      · **|d̄|/SE** · 이긴 씨앗\n");
			LogA("[mlt] 🧿     ⭐ ㈃−㈄ **표제** │ %+.5f · %.5f · **%6.2f** · %u/%u\n",
				pAc.d, pAc.se, pAc.t, pAc.win, pAc.n);
			LogA("[mlt] 🧿     ㈁−㈂ 값(연속)      │ %+.5f · %.5f · **%6.2f** · %u/%u%s\n",
				pAv.d, pAv.se, pAv.t, pAv.win, pAv.n,
				(pAv.d > 0.0) ? "  ⚠️ **양수 = 해롭다**(규율 80 의 모양)" : "");
			LogA("[mlt] 🧿     ⭐ 🚪 **표제 — 몸통이 행동을 읽나**(계급 통로) → %s\n",
				(pAc.d < 0.0 && pAc.t >= 3.0 && pAc.win >= pass)
					? "✅✅ ⭐ ***칸 3 조건 ㈁ 이 섰다 — 몸통이 행동을 쓴다***"
					: ((pAc.d < 0.0 && pAc.win >= pass)
						? "🔶 **부호로만 선다** — ★ 이항 검정으로 읽는다(11/12 면 `p` 0.0032 · 규율 77)"
						: "⛔ **안 선다** — ★ 정보는 있고(0.1166 나트) 몸통이 못 쓴다면 **규율 69**"));
			LogA("[mlt] 🧿        ⓘ **부호 검정**(등록에 같이 적었다) — %u/%u ≥ %u → %s\n",
				pAc.win, pAc.n, pass, (pAc.win >= pass) ? "✅" : "⛔");
			// ⭐ 회차 224 — **`Δ끊음`**(조건 ㈂ 의 **필요조건**)
			//   ⚙️ 115 의 오귀속률은 `r = corr(**Δ끊음**, 가름)` 이다.
			//   ⇒ ⚠️⚠️ `MLT.md:2141` 이 미리 적었다: *"오귀속률(**안 읽으므로 원리적으로 0**)"*
			//     ⇒ ★ 즉 ***`Δ끊음` 이 죽으면 `r` 의 분자가 죽고 오귀속률을 못 잰다.***
			//   ⇒ ⭐ 그리고 `Δ끊음` 은 **이 하네스에 이미 있다**: 팔 ㈃(행동 계급) ↔ 팔 ㈀(상수) —
			//     ***행동 축을 「끊은」 팔이 곧 상수 팔이다.*** ⇒ 규율 21(재기 전에 손계산으로 기각)
			const Pair pCut  = _Paired(3u, 0u);   // ⭐ Δ끊음(계급) — 음수 = 행동이 도움
			const Pair pCutV = _Paired(1u, 0u);   // Δ끊음(값)
			LogA("[mlt] 🧿     ── ⭐ **`Δ끊음`**(조건 ㈂ 의 필요조건 · 회차 224) ──\n");
			LogA("[mlt] 🧿        ㈃−㈀ 계급 ↔ **끊음** │ %+.5f · %.5f · **%6.2f** · %u/%u\n",
				pCut.d, pCut.se, pCut.t, pCut.win, pCut.n);
			LogA("[mlt] 🧿        ㈁−㈀ 값   ↔ **끊음** │ %+.5f · %.5f · **%6.2f** · %u/%u\n",
				pCutV.d, pCutV.se, pCutV.t, pCutV.win, pCutV.n);
			LogA("[mlt] 🧿        ⇒ 판정 → %s\n",
				(pCut.t >= 3.0 || pCutV.t >= 3.0)
					? "✅ **`Δ끊음` 이 산다** — ★ 오귀속률(㈂)을 **잴 수 있다** ⇒ 다음 회차의 자리다"
					: "⛔⛔ ***`Δ끊음` 이 죽었다*** — ★ 그러면 `r = corr(Δ끊음, 가름)` 의 **분자가 없다**\n"
					  "[mlt] 🧿           ⇒ ⭐ **조건 ㈂ 는 「측정 불가」가 아니라 「㈁ 에 종속」이다**(규율 21)");
			LogA("[mlt] 🧿        ⓘ 상한(규율 26) — |Δ끊음| ≤ 3×SE = **%.4f**(계급) · **%.4f**(값)\n",
				3.0 * pCut.se, 3.0 * pCutV.se);
			LogA("[mlt] 🧿        ⚠️ **220 은 「세계의 분모가 산다」를 냈다**(보임만 가름 66.2%%)\n");
			LogA("[mlt] 🧿           ⇒ ★ 그러면 갈림은 하나다: ***세계는 준비됐고 몸통이 안 쓴다***(규율 69)\n");
			// ⭐ 활용률 — 분모는 **220 이 잰 그 낱말의 정보량**(규율 67)
			const double capA = 0.1166;
			LogA("[mlt] 🧿     ⭐ 🚪 **활용률** = 몸통 |d̄| ÷ **%.4f**(220 의 학습 0 여지) = **%.2f**\n",
				capA, Abs((float)pAc.d) / capA);
			LogA("[mlt] 🧿        ⓘ 견줄 자리 — 오라클 **0.68** · 값 캡션 **0.29** · 심볼 캡션 **0.13**(210·211)\n");
			LogA("[mlt] 🧿        ⚠️⚠️ **표제가 `t ≥ 3` 이 아니면 이 비를 읽지 마라**(공용 규율 15) → %s\n",
				(pAc.t >= 3.0) ? "✅ 읽어도 된다" : "⛔ **측정이 아니다**");
			// ⭐ 행동에서 처음 재는 **이산화의 이득**(캡션에서는 「대가」였다)
			LogA("[mlt] 🧿     ⭐ 🚪 **이산화** — 계급 ÷ 값 = **%.2f**\n",
				(Abs((float)pAv.d) > 1.0e-9) ? Abs((float)pAc.d) / Abs((float)pAv.d) : 0.0);
			LogA("[mlt] 🧿        ⓘ 캡션에서는 **0.78**(심볼이 값의 78%% — 211a) ⇒ **「대가」**였다\n");
			LogA("[mlt] 🧿        ★ 행동에서 **1 을 넘으면 「이득」**이다 ⇒ ⭐ 그러면 **낱말과 행동이 반대**다\n");
			LogA("[mlt] 🧿        ⚠️ **둘 다 `t ≥ 3` 일 때만 읽는다**(공용 규율 15) → %s\n",
				(pAc.t >= 3.0 && pAv.t >= 3.0) ? "✅"
					: "⛔ **하나라도 안 섰다** ⇒ ★ 그러면 **부호만** 읽는다(값이 양수 = 해롭다)");
			if (pAc.n > 1u && Abs((float)pAc.d) > 1.0e-9)
			{
				const double sig = pAc.se * Sqrt((float)(double)pAc.n);
				const double need = (3.0 * sig / Abs((float)pAc.d)) * (3.0 * sig / Abs((float)pAc.d));
				LogA("[mlt] 🧿     ⭐ `σ_diff` **%.5f** ⇒ `t ≥ 3` 에 필요한 씨앗 **%.0f**(이번 %u) → %s\n",
					sig, need, _seeds,
					(need <= (double)_seeds) ? "✅ 이 예산이면 된다" : "🔶 **더 필요하다**(규율 77)");
			}

			// ══════════════════════════════════════════════════════════
			// ⭐⭐ 회차 247 — 🎚️ **행동은 얼마나 깊이 읽히나**(캡션을 눈금으로)
			// ══════════════════════════════════════════════════════════
			//   ⚠️⚠️ **규율 49**: 「몸통이 행동을 **읽나**」는 113(분포)·222(평균)이 이미 답했다
			//     ⇒ 세 번째 자를 대지 않는다. ★ 이 회차가 묻는 것은 ***얼마나 깊이*** 다.
			//   ⭐ 규율 69 의 셋째 갈래(**「아직 안 배웠나」**)에 여태 자가 없었고 245·246 이 만들었다.
			if (_repOn && _repFail == 0u)
			{
				LogA("[mlt] 🧿   ── ⭐⭐ **회차 247 — 행동 심볼 행이 얼마나 움직이나** ──\n");
				LogA("[mlt] 🧿     ★ 자리는 코드가 정한다 — 행 **%u**(`_ActSym()`) · D **%u**\n",
					(uint32)_ActSym(), _M.Dim());
				LogA("[mlt] 🧿     ⚠️ 행이 **하나**라 `PR` 은 못 쓴다(랭크가 없다) ⇒ **이동량 하나**다\n");
				LogA("[mlt] 🧿        ★ 246 이 이동량을 **음성 대조가 아니라 양성 자**로 확정했다\n");
				LogA("[mlt] 🧿          (`_Shuffle` 이 피셔-예이츠라 **낱말 다중집합이 정확히 보존**된다)\n");
				LogA("[mlt] 🧿     이동량 ‖ΔE‖   ㈀상수  ㈁행동값 ㈂값섞음 ㈃계급9  ㈄계급섞음\n");
				LogA("[mlt] 🧿                    %6.4f  %6.4f  %6.4f  %6.4f  %6.4f\n",
					_RepMean(kRepAct, 0u), _RepMean(kRepAct, 1u), _RepMean(kRepAct, 2u),
					_RepMean(kRepAct, 3u), _RepMean(kRepAct, 4u));
				const Pair mV = _PairedSrc(_rep[kRepAct], 1u, 2u);   // ⭐⭐ ③ 표제 — 값 ↔ 섞음
				const Pair mC = _PairedSrc(_rep[kRepAct], 3u, 4u);   // ⭐ ④ 계급 9 ↔ 섞음
				LogA("[mlt] 🧿     견줌                │ d̄        · SE      · **|d̄|/SE** · 이긴 씨앗\n");
				LogA("[mlt] 🧿     ⭐⭐ ㈁−㈂ **행동 값** │ %+.4f · %.4f · **%6.2f** · %u/%u\n",
					mV.d, mV.se, mV.t, mV.win, mV.n);
				LogA("[mlt] 🧿     ⭐ ㈃−㈄ 계급 9      │ %+.4f · %.4f · **%6.2f** · %u/%u\n",
					mC.d, mC.se, mC.t, mC.win, mC.n);
				// ⭐⭐ 회차 248 — **「변동의 몫」**: 247 이 순서로만 말한 자리를 짝지은 `t` 로 잰다.
				//   ⚙️ 247 실측 ㈀ 0.5782 → ㈂ 0.6506 → ㈁ 0.7236 ⇒ 「변동」 +0.0724 · 「내용」 +0.0730.
				//   ★ 갈림: ㈀−㈂ 는 **값이 변하기만 하는 것**의 몫이고(둘 다 정보는 0),
				//     ㈁−㈂ 는 **내용이 진짜인 것**의 몫이다. ⇒ 앞이 서고 뒤가 안 서면
				//     🧾 ***그 행은 「변동」에 반응하고 「내용」에 안 반응한다***가 숫자로 선다.
				const Pair mZ = _PairedSrc(_rep[kRepAct], 0u, 2u);   // ㈀ 상수 ↔ ㈂ 값섞음
				LogA("[mlt] 🧿     ⭐⭐ ㈀−㈂ **변동의 몫**  │ %+.4f · %.4f · **%6.2f** · %u/%u\n",
					mZ.d, mZ.se, mZ.t, mZ.win, mZ.n);
				// ⭐⭐ 읽기 깊이 = 판 **안의 비**(규율 67·177 — 그래서 판끼리 견줄 수 있다)
				const double dV = (_RepMean(kRepAct, 2u) > 1.0e-9)
				                ? _RepMean(kRepAct, 1u) / _RepMean(kRepAct, 2u) : 0.0;
				const double dC = (_RepMean(kRepAct, 4u) > 1.0e-9)
				                ? _RepMean(kRepAct, 3u) / _RepMean(kRepAct, 4u) : 0.0;
				LogA("[mlt] 🧿     ⭐⭐ 🚪 ③ **표제 — 행동에 학습이 왔나** t **%.2f** · %u/%u → %s\n",
					mV.t, mV.win, mV.n,
					(mV.t >= 3.0) ? "✅ **왔다**"
					              : "⛔ **안 왔다** — ★ 그러면 **113 과 부딪친다**(어느 자가 틀렸나를 심사한다)");
				LogA("[mlt] 🧿     ⭐ 🚪 ④ **두 부호화 일치** — 값 %+.4f · 계급 %+.4f → %s\n", mV.d, mC.d,
					((mV.d < 0.0) == (mC.d < 0.0)) ? "✅ **같은 방향**" : "⚠️ **부호가 갈린다**");
				LogA("[mlt] 🧿     ⭐ 🚪 ⑤ **널 — ㈀ 상수가 최소인가**: %6.4f → %s\n", _RepMean(kRepAct, 0u),
					[&]() -> const char* {
						const double c = _RepMean(kRepAct, 0u);
						for (uint32 a = 1u; a < 5u; ++a) if (_RepMean(kRepAct, a) < c) return "⛔ **아니다** — 판정불가";
						return "✅ **최소다**";
					}());
				LogA("[mlt] 🧿     ⭐⭐ 🚪 ⑥ **읽기 깊이**(판 안의 비) — 값 **%.2f배** · 계급 **%.2f배**\n", dV, dC);
				LogA("[mlt] 🧿        ⓘ 눈금 = **캡션**(246 · 같은 세계 「감쇠 끔」) = **2.10배**\n");
				LogA("[mlt] 🧿          (감쇠 0.35 에서 1.63배 · 0.15 에서 1.40배)\n");
				LogA("[mlt] 🧿        ⇒ ⭐ 규율 69 의 갈림 — **1 에 가까우면 「아직 안 배웠다」** ·\n");
				LogA("[mlt] 🧿          **캡션급이면 「배웠는데 못 쓴다」** → %s\n",
					(dV < 1.20) ? "★ **1 에 가깝다** ⇒ ***행동에 학습이 거의 안 왔다***"
					            : ((dV >= 1.80) ? "★ **캡션급이다** ⇒ ***배웠는데 못 쓴다***"
					                            : "🔶 **사이다** — ⚠️ 이 예산으로는 못 가른다(규율 13-a)"));
				LogA("[mlt] 🧿        ⚠️ 222 의 순이득은 **`t` 0.54**(안 섰다) ⇒ ★ 깊이와 순이득을\n");
				LogA("[mlt] 🧿          **나란히** 읽는 것이 이 회차의 값이다(규율 69 의 셋째 갈래)\n");
				LogA("[mlt] 🧿     ⭐⭐ 🚪 ⑦ **변동 ↔ 내용**(248) — 변동 `t` **%.2f** · 내용 `t` **%.2f** → %s\n",
					mZ.t, mV.t,
					(mZ.t >= 3.0 && mV.t < 3.0)
						? "✅ ⭐ ***그 행은 「변동」에 반응하고 「내용」에 안 반응한다***"
						: ((mZ.t < 3.0 && mV.t < 3.0)
							? "🔶 **둘 다 안 선다** — ⚠️ 247 의 순서는 **잡음일 수 있다**(규율 13-a)"
							: "⚠️ **예상 밖** — ★ 그 자리를 적고 다시 읽는다"));
			}
		}
		if (_l2ctx)
		{
			// ⭐ 회차 213 — **㈃ 관문**(칸 2 의 **마지막** 조건)
			//   ⚙️ ㈃ = *"언어를 붙인 채 표본을 늘리면 표적 CE 가 계속 내려간다"*
			//   ★ 자를 **재기 전에** 세웠다(212 에서 다른 세션이 지적한 그 순서 · 공용 규율 3-c 의 이웃)
			LogA("[mlt] 🧿   ── ⭐ **㈃ 관문 — 언어를 붙인 채 표본을 늘린다**(회차 213) ──\n");
			LogA("[mlt] 🧿     ⚙️ 문맥 3점(512·2048·8192) × **언어 유무 2 = 여섯 팔** · λ **1.0**\n");
			LogA("[mlt] 🧿        ★ λ 를 1.0 으로 고른 근거 = **212 가 그 자리를 통과시켰다**(낙폭이 잡음 안)\n");
			LogA("[mlt] 🧿     ⚠️⚠️ 204 의 곡선과 견주지 **않는다** — 그쪽은 `q=0` 이고 `λ` 가 없다\n");
			LogA("[mlt] 🧿        ⇒ **규율 65**(예산은 그 자리의 σ) ⇒ ★ 여섯 팔을 **한 판**에 둔다\n");
			LogA("[mlt] 🧿        (같은 씨앗 · 같은 세계 · 같은 초기화 뽑기 · 같은 채점 기준 — 규율 87 셋째 얼굴)\n");
			LogA("[mlt] 🧿     ⚠️ 입력은 **여섯 팔 모두 캡션을 싣는다** — ★ 갈리는 것은 **표적에 쓰나**뿐이다\n");
			LogA("[mlt] 🧿        ⇒ 그래야 이 자가 「표본 × 언어」를 재고 **입력 차이가 안 섞인다**\n");

			double ceX[kCtxArms], ceO[kCtxArms];
			LogA("[mlt] 🧿     문맥      언어 X CE    언어 O CE   ⭐ 언어 이득(짝)      t    이긴씨앗\n");
			for (uint32 k = 0; k < kCtxArms; ++k)
			{
				double sx = 0.0, so = 0.0; uint32 n = 0u;
				for (uint32 s = 0; s < _seeds; ++s)
				{
					if (!_seedOk[s]) continue;
					sx += _M2(k, s); so += _M2(k + kCtxArms, s); ++n;
				}
				ceX[k] = (n == 0u) ? 0.0 : sx / (double)n;
				ceO[k] = (n == 0u) ? 0.0 : so / (double)n;
				const Pair pg = _Paired4(k + kCtxArms, k);   // 언어 O − 언어 X (음수 = 언어가 좋다)
				LogA("[mlt] 🧿     %6u    %.5f      %.5f     **%+.5f**      %.2f    %u/%u%s\n",
					kCtxOf[k], ceX[k], ceO[k], pg.d, pg.t, pg.win, pg.n,
					(k + 1u == kCtxArms) ? "  ⭐ 표제 자리" : "");
			}

			// 🚪 ① 배관 — 언어 X · 8192 는 **212 의 ㈀(P 만)** 과 같은 설정이다
			//   ⭐ 212: 궤도 · lr×0.5 · 문맥 8192 · q=0.05 · 자리 1 · λ=0 ⇒ **1.14221**
			//   ⚠️ 이것이 「같은 자리」인 근거는 설정이 전부 같고 **입력도 캡션**이라는 것이다
			//     (212 의 팔 0 도 캡션을 값 부호화로 받았다) ⇒ ★ 규율 65 를 안 어긴다
			{
				const double ref = 1.14221;
				double nz = 0.0; uint32 nn = 0u;
				if (kOut >= 2u)
					for (uint32 s = 0; s < _seeds; ++s)
					{
						if (!_seedOk[s]) continue;
						nz += Abs((float)((double)_ce[0][kCtxArms - 1u][s] - (double)_ce[1][kCtxArms - 1u][s])); ++nn;
					}
				nz = (nn == 0u) ? 0.0 : nz / (double)nn;
				const double dif = Abs((float)(ceX[kCtxArms - 1u] - ref));
				LogA("[mlt] 🧿     🚪 ① **배관** — 언어 X·8192 **%.5f** ↔ 212 의 ㈀ **%.5f** · 차 **%.4f**\n",
					ceX[kCtxArms - 1u], ref, dif);
				LogA("[mlt] 🧿        그 자리의 실행 잡음 **%.5f** → %s\n", nz,
					(dif < 3.0 * nz) ? "✅ **재현됐다**(3σ 안)"
					                 : "⛔ **배관이 샜다** — ★ 여기서 멈추고 원인을 찾는다");
			}

			// 🚪 ② 낙폭(언어 X) · 🚪 ③ **표제 = 낙폭(언어 O)**
			const Pair pdX = _Paired4(kCtxArms - 1u, 0u);                       // CE(8192,X) − CE(512,X)
			const Pair pdO = _Paired4(kCtxArmsL2 - 1u, kCtxArms);               // CE(8192,O) − CE(512,O)
			LogA("[mlt] 🧿     🚪 ② **낙폭(언어 X)** 512→8192 — d̄ **%+.5f** · SE %.5f · **t %.2f** · %u/%u\n",
				pdX.d, pdX.se, pdX.t, pdX.win, pdX.n);
			LogA("[mlt] 🧿     ⭐ 🚪 ③ **표제 — 낙폭(언어 O)** 512→8192\n");
			LogA("[mlt] 🧿        d̄ **%+.5f** · SE %.5f · **t %.2f** · 이긴 씨앗 **%u/%u** → %s\n",
				pdO.d, pdO.se, pdO.t, pdO.win, pdO.n,
				(pdO.d < 0.0 && pdO.t >= 3.0)
					? "✅✅ ⭐ ***㈃ 통과 — 언어를 붙인 채로도 표본이 값을 한다***"
					: ((pdO.d < 0.0 && pdO.win >= _SignPass())
						? "🔶 **부호는 맞고 t 가 3 을 못 넘는다** — ★ 부호 검정으로만 읽는다(규율 77)"
						: "⛔ **㈃ 가 안 선다** — ★ 언어를 붙이면 표본 곡선이 죽는다는 뜻이다"));

			// ⭐ 🚪 ④ **차의 차** — 이 자의 진짜 물음(212 의 ③ 과 같은 계열)
			const Pair pdd = _Paired4(kCtxArmsL2 - 1u, kCtxArms, kCtxArms - 1u, 0u);
			LogA("[mlt] 🧿     ⭐ 🚪 ④ **차의 차** — 낙폭(언어 O) − 낙폭(언어 X)\n");
			LogA("[mlt] 🧿        d̄ **%+.5f** · SE %.5f · **t %.2f** · %u/%u\n",
				pdd.d, pdd.se, pdd.t, pdd.win, pdd.n);
			// ⭐ **회차 213 의 손계산이 이 판정문의 결함을 미리 잡았다**(규율 🆕)
			//   ⛔ 처음 적은 문구는 *"양수 = 언어가 표본 곡선을 깎는다"* 였다. **틀렸다** —
			//     ⚠️⚠️ 「차의 차」가 양수인 데는 뜻이 **둘**이고 부호만으로는 못 가른다:
			//       ㈀ 언어가 **작은 표본을 메운다**(512 에서 더 돕는다) ⇒ 낙폭이 덜 남는다 = **좋은 것**
			//       ㈁ 언어가 **큰 표본에서 방해한다**(8192 에서 이득이 사라진다) = **나쁜 것**
			//   ⇒ ★ 가르는 것은 **위 표의 「언어 이득」 열**이다 — 세 문맥에서 **부호가 유지되나.**
			//   ⇒ ⭐ 그래서 **차이만 보고 읽지 않는다**(수준을 같이 본다).
			{
				const Pair g0 = _Paired4(kCtxArms, 0u);                          // 512
				const Pair gT = _Paired4(kCtxArmsL2 - 1u, kCtxArms - 1u);        // 8192
				LogA("[mlt] 🧿        ⚠️⚠️ **부호만으로는 못 읽는다** — 양수의 뜻이 **둘**이다:\n");
				LogA("[mlt] 🧿           ㈀ 언어가 **작은 표본을 메운다**(좋다) ↔ ㈁ **큰 표본에서 방해한다**(나쁘다)\n");
				LogA("[mlt] 🧿           ⇒ ★ 가르는 것 = **언어 이득의 부호가 8192 에서도 유지되나**\n");
				LogA("[mlt] 🧿           언어 이득 512 **%+.5f**(t %.2f) → 8192 **%+.5f**(t %.2f)\n",
					g0.d, g0.t, gT.d, gT.t);
				LogA("[mlt] 🧿        ⇒ 판정 → %s\n",
					(pdd.t < 3.0)
						? "🔶 **차의 차가 잡음 안** ⇒ ★ *\"언어는 표본 곡선을 안 건드린다\"* — ㈃ 에는 그것으로 충분하다"
						: ((pdd.d < 0.0)
							? "✅✅ ⭐ **언어 밴드가 표본을 더 잘 쓴다** — ★ 212 의 표제가 곡선으로 이어진다"
							: ((gT.d < 0.0)
								? "✅ ⭐ **㈀ — 언어가 작은 표본을 메운다**(8192 에서도 이득은 살아 있다) ⇒ 좋은 쪽이다"
								: "⚠️⚠️ **㈁ — 큰 표본에서 이득이 사라진다** ⇒ ★ ㈃ 는 「선다」가 아니라 **「대가가 있다」** 다")));
			}
			LogA("[mlt] 🧿        ⚠️ 이 자는 **분모가 같다**(같은 팔 여섯 · 같은 씨앗) ⇒ 규율 87 을 안 어긴다\n");

			// ⭐ 실행 잡음 — 팔별(바깥 0 ↔ 1). ⚠️ 위 관문의 **예산**이 여기서 나온다(규율 65)
			if (kOut >= 2u)
			{
				LogA("[mlt] 🧿     ── ⭐ **실행 잡음**(바깥 0 ↔ 1 · 같은 씨앗·같은 데이터) ──\n");
				LogA("[mlt] 🧿        팔                    평균 |Δ|     최대 |Δ|\n");
				for (uint32 a = 0; a < kCtxArmsL2; ++a)
				{
					double sd = 0.0, mx = 0.0; uint32 n = 0u;
					for (uint32 s = 0; s < _seeds; ++s)
					{
						if (!_seedOk[s]) continue;
						const double dd = Abs((float)((double)_ce[0][a][s] - (double)_ce[1][a][s]));
						sd += dd; if (dd > mx) mx = dd; ++n;
					}
					LogA("[mlt] 🧿        %s  **%.5f**    %.5f\n",
						_ArmName(a), (n == 0u) ? 0.0 : sd / (double)n, mx);
				}
			}
			LogA("[mlt] 🧿     ⚠️⚠️ **읽는 순서를 미리 적어 둔다**: ① 이 ⛔ 면 ②③④ 를 **안 읽는다**.\n");
			LogA("[mlt] 🧿        ③ 이 표제이고 ④ 는 **그것을 넘어서는 것**이다 ⇒ ★ ③ 없이 ④ 만 좋으면\n");
			LogA("[mlt] 🧿        *\"둘 다 안 내려갔는데 나란히 안 내려갔다\"* 일 수 있다(규율 88 의 모양)\n");
		}
		if (_lang2 && !_l2ctx)
		{
			// ⭐ 회차 212 — **L2 관문**(칸 2 조건 ㈂) · 자는 `mltplan_2.md` 에 미리 섰다
			LogA("[mlt] 🧿   ── ⭐ **㈂ L2 관문 — 언어를 붙여도 `P` 가 서나**(회차 212) ──\n");
			LogA("[mlt] 🧿     ⚙️ 캡션을 **표적으로도** 둔다(출력 어휘 %u = 방향 %u + 캡션 %u)\n",
				_OutV(), _N(), kLVocab);
			LogA("[mlt] 🧿     ⚠️⚠️ **학습 풀에만** 건다 — ★ 채점은 늘 **P 쪽(변화만)** 이다(규율 58)\n");
			LogA("[mlt] 🧿     ⚠️ `λ` 는 **확률 마스크**(기대 무게 = λ · 셰이더 수술 0 · 188 의 관용구)\n");
			double ce8[kArms];
			for (uint32 a = 0; a < kArms; ++a)
			{
				double s = 0.0; uint32 n = 0u;
				for (uint32 sd = 0; sd < _seeds; ++sd) { if (!_seedOk[sd]) continue; s += _M2(a, sd); ++n; }
				ce8[a] = (n == 0u) ? 0.0 : s / (double)n;
			}
			double nz2 = 0.0; uint32 nn2 = 0u;
			for (uint32 a = 0; a < kArms; ++a)
				for (uint32 sd = 0; sd < _seeds; ++sd)
				{
					if (!_seedOk[sd]) continue;
					nz2 += Abs((float)((double)_ce[0][a][sd] - (double)_ce[1][a][sd])); ++nn2;
				}
			nz2 = (nn2 == 0u) ? 0.0 : nz2 / (double)nn2;
			LogA("[mlt] 🧿     🚪 ① **검산** — ㈇(P 만 재현) **%.5f** ↔ ㈀ **%.5f** · 차 **%.4f** → %s\n",
				ce8[7], ce8[0], Abs((float)(ce8[7] - ce8[0])),
				(Abs((float)(ce8[7] - ce8[0])) < nz2 * 3.0) ? "✅" : "⛔ **배관이 샜다**");
			LogA("[mlt] 🧿     λ      변화만 CE   ⭐ 낙폭     섞음 CE    ⭐ 낙폭−섞음낙폭\n");
			static const uint32 la[3] = { 1u, 2u, 3u };
			static const float  lv[3] = { 0.10f, 0.30f, 1.00f };
			bool anyOk = false; uint32 lMax = 0u;
			for (uint32 k = 0; k < 3u; ++k)
			{
				const double dLang = ce8[la[k]] - ce8[0];
				const double dShuf = ce8[la[k] + 3u] - ce8[0];
				const double net = dLang - dShuf;
				LogA("[mlt] 🧿    %5.2f    %.5f   **%+.4f**   %.5f   **%+.4f**%s\n",
					(double)lv[k], ce8[la[k]], dLang, ce8[la[k] + 3u], net,
					(dLang <= nz2) ? "  ✅ 잡음 안" : ((Abs((float)net) <= nz2) ? "  ⚠️ 예산 탓" : "  ⛔ 언어 탓"));
				if (dLang <= nz2) { anyOk = true; lMax = k; }
			}
			LogA("[mlt] 🧿     ⭐ 🚪 ② **표제** — 낙폭이 실행 잡음(**%.5f**) 안인 최대 `λ` = %s → %s\n",
				nz2, anyOk ? "있다" : "없다",
				anyOk
					? "✅✅ ⭐ ***언어를 붙여도 `P` 가 선다 = ㈂ 통과***"
					: "⛔ **낙폭이 잡음보다 크다** — ★ 아래 「예산 탓 ↔ 언어 탓」으로 가른다");
			if (anyOk)
				LogA("[mlt] 🧿        ⇒ ⭐ 그 `λ` = **%.2f** ⇒ ★ 「경험 학습」에 **언어를 그만큼** 얹을 수 있다\n",
					(double)lv[lMax]);
			LogA("[mlt] 🧿     ⭐ 🚪 ③ **언어 탓인가 예산 탓인가** — ★ **섞음 팔이 이 자의 핵심**이다\n");
			LogA("[mlt] 🧿        (낙폭 − 섞음낙폭)이 **잡음 안**이면 ⇒ ⚠️ **예산 탓**(손실이 하나 더 있는 것)\n");
			LogA("[mlt] 🧿        그보다 크면 ⇒ ⛔ ***언어가 표현을 휘게 했다*** = **L2 회귀**\n");
			// ⭐⭐ 회차 233 — 📌 **부채 D41 을 갚는다**: 이 관문도 **실행 잡음**과만 견줬다
			//   ⛔⛔ 228 이 `eff` 쪽에서 그것을 잡았다 — *"잡음의 7배"* 가 짝지은 SE 로는 `t` **1.29** 였다
			//     ⇒ ★★ ***실행 잡음은 씨앗 사이 흩어짐을 안 담는다***(규율 29·37·65).
			//   ⇒ ⚠️ 212 의 *"−0.011~−0.014 = 잡음의 1.4~1.7배"* 도 **같은 자**로 읽은 것이다.
			//   ⇒ ⭐ 213 의 `_Paired4` 가 그것을 **공짜로** 준다(eff 쪽 228 블록과 **같은 자**).
			//   ⚠️⚠️ **낙폭과 「차의 차」는 다른 것이다** — 212 의 표제(㈂ 통과)는 **낙폭**이 잡음 안인 것이고
			//     ***이 표가 다시 읽는 것은 「차의 차」(언어가 섞음보다 낫나)뿐***이다(규율 58 — 자를 안 바꾼다).
			LogA("[mlt] 🧿     ── ⭐ **짝지은 차**(부채 **D41** · 규율 29·37 · 228 과 같은 자) ──\n");
			LogA("[mlt] 🧿        λ      낙폭 d̄     SE      t      │ 차의 차 d̄    SE      **t**    이긴씨앗\n");
			double btL = 0.0; uint32 blL = 0u; bool standL = false;
			for (uint32 k = 0; k < 3u; ++k)
			{
				const Pair pd = _Paired4(la[k], 0u);                        // 낙폭
				const Pair px = _Paired4(la[k], 0u, la[k] + 3u, 0u);        // ⭐ 차의 차
				if (px.d < 0.0 && px.t > btL) { btL = px.t; blL = k + 1u; }
				if (px.d < 0.0 && px.t >= 3.0) standL = true;
				LogA("[mlt] 🧿        %.2f  %+.5f  %.5f  %5.2f  │ %+.5f  %.5f  **%5.2f**  %u/%u\n",
					(double)lv[k], pd.d, pd.se, pd.t, px.d, px.se, px.t, px.win, px.n);
			}
			LogA("[mlt] 🧿        ⭐ 🚪 **D41 관문 — 「차의 차」가 `t ≥ 3` 인 λ 가 있나** → %s\n",
				standL ? "✅✅ ⭐ ***언어가 섞음보다 낫다가 「측정」으로 선다*** — 212 의 ③ 을 확정한다"
				       : (blL > 0u ? "🔶 **부호는 맞고 `t` 가 3 을 못 넘는다** ⇒ ★ 212 의 ③ 은 **보탬이 약해진다**"
				                   : "⛔ **부호도 안 선다** ⇒ ⚠️ 212 의 ③ 을 철회한다"));
			if (blL > 0u) LogA("[mlt] 🧿        ⭐ 최선 λ = **%.2f**(`t` %.2f)\n", (double)lv[blL - 1u], btL);
			LogA("[mlt] 🧿        ⚠️ **표제(㈂ 통과)는 이 표로 안 흔들린다** — 그것은 **낙폭**의 판정이고\n");
			LogA("[mlt] 🧿           칸 2 의 조건 ㈁ 는 **211a 의 `t` 4.37 · 11/12** 로 따로 서 있다\n");
		}
		if (_qSweep)
		{
			// ⭐ 회차 203 — **`q` 곡선**(부채 D25) · 자는 CE 절대값(짝지은 차가 아니다)
			LogA("[mlt] 🧿   ── ⭐ **D25 — 지속까지 배워도 `P3` 가 서나**(회차 203) ──\n");
			LogA("[mlt] 🧿     ★ 시험은 늘 **변화만** 채점이고 **학습 무게만** 팔마다 다르다(규율 58)\n");
			// ⭐ 회차 207 — **팔별 지속 CE 가 생겼다**(205 의 배관 부채를 갚았다)
			//   ★ 그리고 그것이 🆕 **조건 ㉤**(「바뀔지 안 바뀔지」를 아나)의 자다:
			//     지속 표적의 정답은 「지금 계급」이므로 ***지속 CE = `−log P(지속)`*** 이고
			//     그것이 **이진 CE 의 지속 항 그 자체**다.
			//   ⇒ ⭐ 이진 CE ≥ **지속몫 × 지속 CE**(변화 항은 ≥ 0) ⇒ **하한**이다.
			//   ⚠️ 상수 예측자(늘 `p = 지속 비율`)의 이진 CE = `H(지속몫)` ⇒ 그것이 **음성 대조**다.
			//   ⚠️⚠️ **하한이 그것을 넘으면 ⛔ 확정**이고 **낮아도 ✅ 는 못 준다**(변화 항을 모른다).
			LogA("[mlt] 🧿        q     변화만 CE   목표선 대비   `P3`   지속 CE   ⭐ ㉤ 하한\n");
			const double goalM = _MeanOf(_goal);
			// 지속몫 = 전체 표적 중 지속의 비 — `_nScored` 로 센다(그 자리의 값)
			const double nAll = _MeanOf(_nScored[kMAll]), nKp = _MeanOf(_nScored[kMKeep]);
			const double keepFrac = (nAll > 1.0e-9) ? (nKp / nAll) : 0.68;
			const double hBase = -(keepFrac * (double)Log((float)((keepFrac > 1.0e-9) ? keepFrac : 1.0e-9))
			                     + (1.0 - keepFrac) * (double)Log((float)((1.0 - keepFrac > 1.0e-9) ? (1.0 - keepFrac) : 1.0e-9)));
			double ceQ[kArms], keepQ[kArms], binLo[kArms];
			uint32 qMax = 0u; bool anyPass = false;
			for (uint32 a = 0; a < kArms; ++a)
			{
				double ce = 0.0; uint32 n = 0u;
				for (uint32 s = 0; s < _seeds; ++s) { if (!_seedOk[s]) continue; ce += _M2(a, s); ++n; }
				ceQ[a] = (n == 0u) ? 0.0 : ce / (double)n;
				const bool pass = (ceQ[a] < goalM);
				if (pass) { qMax = a; anyPass = true; }
				// ⭐ 회차 207 — 팔별 지속 CE 와 ㉤ 하한
				double kp = 0.0; uint32 kn2 = 0u;
				for (uint32 s = 0; s < _seeds; ++s)
				{
					if (!_seedOk[s]) continue;
					for (uint32 o = 0; o < kOut; ++o) { kp += (double)_ceKeep[o][a][s]; ++kn2; }
				}
				kp = (kn2 == 0u) ? 0.0 : kp / (double)kn2;
				keepQ[a] = kp;
				binLo[a] = keepFrac * kp;
				LogA("[mlt] 🧿      %5.2f    %.5f    %+6.2f%%     %s    %6.3f   **%6.3f**%s\n",
					(double)kQOf[a], ceQ[a],
					(goalM > 1.0e-9) ? 100.0 * (ceQ[a] - goalM) / goalM : 0.0,
					pass ? "✅" : "⛔", kp, binLo[a],
					(binLo[a] < hBase) ? "  ⭐ 바닥 아래" : "");
			}
			// ⭐ 실행 잡음과 견준다 — 그것이 「구별되나」의 자다(194·201 의 그 자)
			double nz = 0.0; uint32 nn = 0u;
			for (uint32 a = 0; a < kArms; ++a)
				for (uint32 s = 0; s < _seeds; ++s)
				{
					if (!_seedOk[s]) continue;
					nz += Abs((float)((double)_ce[0][a][s] - (double)_ce[1][a][s])); ++nn;
				}
			nz = (nn == 0u) ? 0.0 : nz / (double)nn;
			// ⚠️⚠️ **회차 205 가 이 문구도 고치게 했다**(204 가 ctxSweep 쪽을 고친 뒤 여기가 남았다)
			//   ★ 201 의 **1.16502** 는 **문맥 512** 자리 값이다 ⇒ 문맥을 바꾸면 규율 65 위반이다.
			//   ⇒ ⭐ **문맥마다 짝을 바꾼다**: 8192 는 **204 의 8192(1.11411)** 이 짝이다.
			//   ⇒ ⚠️⚠️ 그리고 이것이 **같은 계열 함정의 네 번째**다(189·200·203·205) —
			//     ***참조값이 여러 곳에 흩어져 있으면 새 축이 올 때 한쪽만 안다***(공용 규율 16).
			{
				const double refQ = (_armCtx >= kNCtxMax) ? 1.11411 : 1.16502;
				const char* refQN = (_armCtx >= kNCtxMax) ? "204 의 8192" : "201 의 512";
				LogA("[mlt] 🧿     🚪 ① 배관 — q=0 의 CE **%.5f** ↔ %s **%.5f**(잡음 %.5f 안) → %s\n",
					ceQ[0], refQN, refQ, nz,
					(Abs((float)(ceQ[0] - refQ)) < nz * 3.0)
						? "✅ **그 자리에서 재현됐다**"
						: "⚠️ **다르다** — ★ 잡음보다 크다(적어 둔다)");
			}
			LogA("[mlt] 🧿     ⭐ 🚪 ② **표제** — `P3` 가 서는 최대 `q` = **%s** → %s\n",
				anyPass ? (qMax == 0u ? "0.00(변화만뿐)" : "아래 표의 ✅ 마지막") : "없음",
				anyPass
					? (qMax > 0u ? "✅✅ ⭐ ***창이 열렸다 — 지속을 배워도 선다***"
					             : "⛔ **q=0 에서만 선다** ⇒ ★ 188 의 *\"창이 없다\"* 가 이 세계에서도 참이다")
					: "⛔⛔ **q=0 에서도 안 선다** — ★ 배관을 먼저 본다");
			if (anyPass && qMax > 0u)
				LogA("[mlt] 🧿        ⇒ ⭐ 최대 `q` = **%.2f** ⇒ ★ 「경험 학습」의 **지속 %.0f%%** 를 담는다\n",
					(double)kQOf[qMax], 100.0 * (double)kQOf[qMax]);
			LogA("[mlt] 🧿     ⭐ 🚪 ③ **교환율** — q 0 → 1 에서 변화 CE **%+.4f**(%.1f배)\n",
				ceQ[kArms - 1u] - ceQ[0],
				(ceQ[0] > 1.0e-9) ? ceQ[kArms - 1u] / ceQ[0] : 0.0);
			LogA("[mlt] 🧿        ⇒ ★ 144 는 옛 세계에서 **+60%%**(1.7389 → 2.780)를 쟀다 — 여기서 재현되나\n");
			// ⭐ 회차 207 — 🆕 **조건 ㉤: 「바뀔지 안 바뀔지」를 아나**
			{
				LogA("[mlt] 🧿     ── ⭐ 🆕 **㉤ — 「바뀔지 안 바뀔지」를 아나**(회차 207) ──\n");
				LogA("[mlt] 🧿        ⚙️ 206 이 칸 1 의 조건을 **갈랐다** — 지속 표적을 잘 맞히는 것은\n");
				LogA("[mlt] 🧿           **복사**이고 `MLT.md:1909` 가 그것을 *\"아무 표현도 안 생겼다\"* 의\n");
				LogA("[mlt] 🧿           대조군으로 못 박았다 ⇒ ★ 능력은 ***언제 바뀌나***이고 그것은 **이진**이다\n");
				LogA("[mlt] 🧿        ⭐ 자: 지속 표적의 정답이 「지금 계급」이므로 **지속 CE = −log P(지속)**\n");
				LogA("[mlt] 🧿           ⇒ 이진 CE ≥ **지속몫 × 지속 CE**(변화 항 ≥ 0) = **하한**\n");
				LogA("[mlt] 🧿        🚪 배관 — 지속몫 **%.3f** ⇒ 상수 예측자 `H` = **%.4f** 나트\n",
					keepFrac, hBase);
				uint32 nLo = 0u; bool anyLo = false;
				for (uint32 a = 0; a < kArms; ++a) if (binLo[a] < hBase) { nLo = a; anyLo = true; }
				LogA("[mlt] 🧿        ⭐ 🚪 **표제** — 하한이 그 바닥 아래인 `q` = **%s** → %s\n",
					anyLo ? "있다" : "없다",
					anyLo
						? "🔶 ⭐ **⛔ 를 못 준다** — ★ 하한이 낮은 것은 ✅ 가 아니다(변화 항을 모른다)"
						: "⛔⛔ ⭐ ***어느 `q` 에서도 상수 예측자를 못 넘는다 = ㉤ 이 안 선다***");
				if (anyLo)
					LogA("[mlt] 🧿           ⇒ ⭐ 그 최대 `q` = **%.2f**(하한 %.3f < %.4f) ⇒ ★ **거기서 이진 자를 만든다**\n",
						(double)kQOf[nLo], binLo[nLo], hBase);
				LogA("[mlt] 🧿        ⭐ 🚪 **창이 있나** — `P3` 는 `q ≤ %.2f` · ㉤ 하한은 `q ≥ %s` → %s\n",
					(double)kQOf[qMax], anyLo ? "그 위" : "없음",
					(anyLo && kQOf[nLo] <= kQOf[qMax])
						? "✅✅ ⭐ ***두 조건이 같은 자리에서 겹친다***"
						: "⛔ **창이 없다** — ★ 145·146·149 의 «무엇을 배우든 다른 것을 그만큼 잃는다»");
			}
			LogA("[mlt] 🧿     ⚠️ ④ **단조** — q 가 오르면 변화 CE 가 나빠지나 → %s\n",
				[&]() -> const char* {
					for (uint32 a = 1u; a < kArms; ++a) if (ceQ[a] < ceQ[a - 1u] - 3.0 * nz) return "⛔ **단조가 아니다** — ★ q 가 아닌 다른 것이 움직였다";
					return "✅";
				}());
		}
		// ⚠️⚠️ 213 은 팔이 **문맥 × 언어**라 이 짝들(0−1·2−3…)이 **뜻을 잃는다**
		//   ⇒ ★ 그러면 숫자는 나오는데 **아무 자도 아니다** ⇒ 안 찍는다(규율 88 이 경고한 모양)
		// ⛔⛔⛔ **회차 219 가 측정 0 으로 잡았다 — `_lang2` 도 막아야 했다.**
		//   ⚠️ L2 모드의 팔은 **`λ` 축**(㈀ P만 · ㈁㈂㈃ λ · ㈄㈅㈆ 섞음 · ㈇ 검산)인데
		//     이 블록은 팔 0·1 을 「**오라클 ↔ 오라클 섞음**」으로 읽는다
		//     ⇒ ⛔ `_Paired(0,1)` 이 사실은 **낙폭**이고 「천장」이 아니다.
		//   ⚠️⚠️ 그리고 순 `Î` 가 **정확히 0** 이 나온 것도 결함이 아니라 **설계의 결과**다 —
		//     L2 는 **모든 팔에 같은 캡션**을 주므로(`_wTr = _wNmTr`) `_iWb[a] − _iWb[a+1] = 0` 이다.
		//   ⇒ ⛔⛔ **회차 217 이 그 숫자들을 「언어가 무너진다」로 읽었다** ⇒ 🗑️ **그 근거를 철회한다.**
		//   ⇒ ★ 216 에서 **D34 를 고치면서 `_ctxSweep` 만 막았다** ⇒ ***같은 함정의 두 번째 얼굴***.
		//     ⇒ ⭐ 그래서 이제 **「팔 축이 다른 모드」 전부**를 한 조건에 모은다(203 이 배운 그 관용구).
		if (_lang && !_l2ctx && !_lang2 && !_capOn)
		{
			// ⭐ 회차 209 — **팔 배치를 고쳤다: 오라클 천장을 넣었다**
			//   ⛔⛔ 200 의 설계에 **천장(분모)이 없었다** ⇒ 규율 49 위반 ⇒ ⚠️ 분모가 없으니
			//     «효과가 작다» 를 «낱말이 안 쓰인다» 로 읽을 수밖에 없었다.
			const Pair pC = _Paired(0u, 1u);      // ⭐ 오라클 = **천장**
			const Pair pS = _Paired(2u, 3u);      // ⭐ 심볼 캡션
			const Pair pV = _Paired(4u, 5u);      // 값 부호화(같은 내용)
			const Pair pK = _Paired(6u, 7u);      // 상수(축 교란 대조)
			LogA("[mlt] 🧿   ── ⭐ **낱말의 천장을 먼저 잰다**(회차 209 · 칸 2 ㈀) ──\n");
			LogA("[mlt] 🧿     ⛔⛔ 200 의 설계에 **천장(분모)이 없었다** ⇒ **규율 49 위반**\n");
			LogA("[mlt] 🧿        ⇒ ★ 그래서 «효과가 작다» 를 «낱말이 안 쓰인다» 로 읽을 수밖에 없었다\n");
			LogA("[mlt] 🧿     견줌                  │ d̄        · SE      · **|d̄|/SE** · 이긴 씨앗\n");
			LogA("[mlt] 🧿     ⭐ ㈀−㈁ **천장**   │ %+.5f · %.5f · **%6.2f** · %u/%u\n",
				pC.d, pC.se, pC.t, pC.win, pC.n);
			LogA("[mlt] 🧿     ⭐ ㈂−㈃ **심볼 캡션** │ %+.5f · %.5f · **%6.2f** · %u/%u\n",
				pS.d, pS.se, pS.t, pS.win, pS.n);
			LogA("[mlt] 🧿     ㈄−㈅ 값 부호화       │ %+.5f · %.5f · **%6.2f** · %u/%u\n",
				pV.d, pV.se, pV.t, pV.win, pV.n);
			LogA("[mlt] 🧿     ㈆−㈇ 상수(교란)      │ %+.5f · %.5f · **%6.2f** · %u/%u\n",
				pK.d, pK.se, pK.t, pK.win, pK.n);
			const uint32 lpass = _SignPass();
			const bool gCap = (pC.d < 0.0) && (pC.t >= 3.0);
			LogA("[mlt] 🧿     ⭐ 🚪 ② **표제 — 낱말이 보탤 수 있는 전부**(천장) = **%+.5f** 나트\n", pC.d);
			LogA("[mlt] 🧿        (t %.2f · %u/%u) → %s\n", pC.t, pC.win, pC.n,
				gCap ? "✅ **분모가 섰다**" : "⛔⛔ **천장이 안 선다** — ★ 분모가 없으면 아무것도 못 읽는다");
			LogA("[mlt] 🧿        ⓘ 견줄 자리 — 184(옛 세계 · `lr×1` · 값)의 표제 낱말이 **−0.267** 이었다\n");
			if (gCap)
			{
				const double util = (Abs((float)pC.d) > 1.0e-9) ? Abs((float)pS.d) / Abs((float)pC.d) : 0.0;
				const double utV  = (Abs((float)pC.d) > 1.0e-9) ? Abs((float)pV.d) / Abs((float)pC.d) : 0.0;
				// ⚠️⚠️ 📌 **D45**(회차 240 이 여기에 걸렸다) — 이 트랙에 **활용률 자가 둘**이다:
			//   ㈀ **천장의 몫** = `|d̄| ÷ |오라클 d̄|`  ← **이 줄**(209 계열 · 211a 의 0.13 이 이 자)
			//   ㈁ **정보 활용률** = `|d̄| ÷ Î(−섞음)`   ← 아래 「천장·전달율·활용률」 표의 그 열
			//   ⇒ ⛔ 240 이 등록문을 ㈁ 로 쓰고 예측값을 ㈀ 의 눈금(0.13)으로 적어 **예측 하나를 헛되게 했다**
			//     (같은 판에서 ㈀ = 7.8% · ㈁ = 0.94 였다 — **자릿수가 다르다**).
			//   ⇒ ★ 그래서 이름을 못 박는다: 아래 줄은 ***「천장의 몫」*** 이고 **활용률이라고만 쓰지 않는다.**
			LogA("[mlt] 🧿     ⭐ 🚪 ③ **천장의 몫**(📌 D45 — ⚠️ `Î` 기준 활용률과 **다른 자**) — 심볼 **%.1f%%** · 값 **%.1f%%**\n",
					100.0 * util, 100.0 * utV);
				LogA("[mlt] 🧿        ⇒ ⭐ **규율 69 로 가른다** — %s\n",
					(Abs((float)pC.d) < 0.15)
						? "★ **천장이 작다**(< 0.15) ⇒ ***「보탤 것이 없다」*** — 200~202 의 ⛔ 를 다시 읽는다"
						: "★ **천장이 크다** ⇒ ***「몸통이 못 쓴다」*** — 처방이 **표현·임베딩**으로 간다");
			}
			// ⭐ 회차 210 — **진짜 활용률**(규율 67·177) · ⛔ 209 는 오라클로 나눴다
			{
				LogA("[mlt] 🧿     ── ⭐ **진짜 활용률**(회차 210 · 규율 67 정정) ──\n");
				LogA("[mlt] 🧿        ⛔⛔ 209 는 **오라클로 나눴다** — ★ 오라클과 캡션은 **다른 낱말**이다\n");
				LogA("[mlt] 🧿           (오라클 = **정답** · 캡션 = **어느 물체가 바뀌나**)\n");
				LogA("[mlt] 🧿           ⇒ ⚠️ 4.7%% 가 *\"몸통이 못 쓴다\"* 가 아니라 **캡션의 정보가 적어서**일 수 있다\n");
				LogA("[mlt] 🧿        ⇒ ⭐ 규율 67: 분모는 ***그 낱말의 정보량*** `Î(낱말;변화 표적)` 이다\n");
				// ⭐ 회차 211 — **이진 `Î`** 를 주 자로 쓴다(자리 수에 안 흔들린다)
				LogA("[mlt] 🧿        ⭐ 회차 211 — 자리 수 **%u** · 주 자 = **이진 `Î`**(이 슬롯 이름이 캡션에 있나)\n", _lnw);
				LogA("[mlt] 🧿           ⚠️ 결합 자(81계급)는 **자리 2 에서만** 뜻이 있다 — 자리 4 면 6561 계급이라 편향이다\n");
				LogA("[mlt] 🧿        낱말        Î결합   ⭐ **Î이진**  Î이진(섞)  ⭐ 순Î이진  몸통 |d̄|  ⭐ **활용률**\n");
				for (uint32 k = 0; k < 4u; ++k)
				{
					static const uint32 pb[4] = { 0u, 2u, 4u, 6u };
					static const char*  pbN[4] = { "㈀ 오라클  ", "㈂ 심볼캡션", "㈄ 값 부호화", "㈆ 상수    " };
					const uint32 a0 = pb[k];
					const double b0 = _MeanOfArm(_iWb, a0), b1 = _MeanOfArm(_iWb, a0 + 1u);
					const double bNet = b0 - b1;
					const Pair pp = _Paired(a0, a0 + 1u);
					LogA("[mlt] 🧿        %s %.4f   **%.4f**   %.4f    **%.4f**   %.4f    **%s%.2f**\n",
						pbN[k], _MeanOfArm(_iW, a0), b0, b1, bNet, Abs((float)pp.d),
						(bNet > 1.0e-4) ? "" : "≈",
						(bNet > 1.0e-4) ? (Abs((float)pp.d) / bNet) : 0.0);
				}
				LogA("[mlt] 🧿        ── ⚠️ 아래는 **결합 자** 기준(210 과의 다리 · 자리 2 에서만) ──\n");
				// ⚠️ 📌 D45 — 이 열은 **`Î` 기준 활용률**(`|d̄| ÷ Î`)이다. 위 「천장의 몫」과 **다른 자**다.
			LogA("[mlt] 🧿        낱말        Î(원본)  Î(섞음)  ⭐ Î(−섞음)  몸통 |d̄|  ⭐ **활용률(Î 기준)**\n");
				static const uint32 pr0[4] = { 0u, 2u, 4u, 6u };
				static const char*  prN[4] = { "㈀ 오라클  ", "㈂ 심볼캡션", "㈄ 값 부호화", "㈆ 상수    " };
				for (uint32 k = 0; k < 4u; ++k)
				{
					const uint32 a0 = pr0[k];
					const double i0 = _MeanOfArm(_iW, a0), i1 = _MeanOfArm(_iW, a0 + 1u);
					const double iNet = i0 - i1;      // ⚠️ 섞음을 빼서 **빈 칸 편향**을 지운다(175)
					const Pair pp = _Paired(a0, a0 + 1u);
					LogA("[mlt] 🧿        %s  %.4f   %.4f   **%.4f**    %.4f    **%s%.2f**\n",
						prN[k], i0, i1, iNet, Abs((float)pp.d),
						(iNet > 1.0e-4) ? "" : "≈",
						(iNet > 1.0e-4) ? (Abs((float)pp.d) / iNet) : 0.0);
				}
				LogA("[mlt] 🧿        ⚠️ `Î` 는 칸당 표본이 얇아 **위로 편향**된다 ⇒ ★ **섞음을 뺀 값**만 쓴다\n");
				LogA("[mlt] 🧿        ⚠️⚠️ 활용률은 **그 짝이 `t ≥ 3` 일 때만** 뜻이 있다(공용 규율 15)\n");
			}
			LogA("[mlt] 🧿     ⭐ 🚪 ④ **이산화의 대가** — 심볼 ÷ 값 = **%.2f**\n",
				(Abs((float)pV.d) > 1.0e-9) ? Abs((float)pS.d) / Abs((float)pV.d) : 0.0);
			LogA("[mlt] 🧿        ⚠️⚠️ **둘 다 t ≥ 3 이 아니면 이 비를 적지 마라**(공용 규율 15) — %s\n",
				(pS.t >= 3.0 && pV.t >= 3.0)
					? "✅ 둘 다 섰다 ⇒ 비를 읽어도 된다"
					: "⛔ **하나라도 안 섰다** ⇒ ★ 이 비는 **측정이 아니다**(200 의 0.93 · 201 의 0.43 · 202 의 1.39)");
			LogA("[mlt] 🧿     ⭐ 🚪 ⑤ **교란 대조** — ㈆−㈇(축만 둘 늘림) t **%.2f** < 3 → %s\n",
				pK.t, (pK.t < 3.0) ? "✅ **축을 늘린 것 자체는 이득이 아니다**"
				                   : "⛔⛔ **축 교란이 있다** — ★ 표제를 그만큼 깎아 읽는다");

			// ══════════════════════════════════════════════════════════
			// ⭐⭐ 회차 245 — 🧠 **모델 표현**: 그 심볼이 몸통 안에서 어느 자리가 되나
			// ══════════════════════════════════════════════════════════
			{
				const uint32 D = _M.Dim(), b0 = _CapSymBase();
				LogA("[mlt] 🧿   ── ⭐⭐ **회차 246 — 방향인가 크기인가**(모델 표현 캔버스 · 245 의 연장) ──\n");
				LogA("[mlt] 🧿     ⚙️ 245: 진짜 캡션이 섞음보다 **1.63배 크게**(㉢) **0.63배 좁게**(㉡) 움직였다\n");
				LogA("[mlt] 🧿        ⛔ 그런데 **그 둘을 못 갈랐다** — 「더 크게」와 「더 좁게」는 한 사건의 두 얼굴일 수 있다\n");
				LogA("[mlt] 🧿     ⚠️⚠️ 245 의 ㉡ 은 `ΔE` 를 **중심화**했다 ⇒ ⛔ *공유 방향이 곧 신호*인데\n");
				LogA("[mlt] 🧿        **중심화가 그 공유 성분을 정확히 지운다** ⇒ 🧾 방향 자는 **중심화하지 않는다**\n");
				LogA("[mlt] 🧿        (자를 고친 것이 아니라 **처음부터 그것을 못 재고 있었다** — 규율 6 의 대상이 아니다)\n");
				LogA("[mlt] 🧿     ⭐⭐ **㉥(생)과 ㉣(단위)는 정규화 하나만 다르다** ⇒ 그 갈림이 ***크기의 몫***이다\n");
				LogA("[mlt] 🧿     ★ 자리는 코드가 정한다 — 행 **%u..%u**(`_LangSym` 의 그 자리) · D **%u**\n",
					b0, b0 + kCapRows - 1u, D);
				LogA("[mlt] 🧿        ⇒ 천장: 중심화 자(㉠㉡)는 랭크 ≤ **%u** · **비중심화 방향 자(㉣㉥)는 1(완전정렬) ~ %u(완전직교)**\n",
					kCapRows - 1u, kCapRows);
				LogA("[mlt] 🧿          ⚠️ ㉠ 은 **초기값이 무작위라 시작이 천장**이다 ⇒ 245 에서 눈이 멀었다(📌 D49)\n");
				LogA("[mlt] 🧿     🚪 ① **배관** — 리드백 실패 **%u회** → %s\n", _repFail,
					(_repOn && _repFail == 0u) ? "✅ **살아 있다**"
					                           : "⛔⛔ **배관이 죽었다** — ★ 아래 숫자를 읽지 마라");
				if (_repOn && _repFail == 0u)
				{
					static const char* rn[kRepM] = {
						"㉠ PR(학습뒤·중심) ", "㉡ PR(ΔE·중심)    ", "⚠️ ㉢ 이동량 ‖ΔE‖  ",
						"⭐⭐ ㉣ PR₁(단위)   ", "⭐ ㉥ PR₀(생)      ", "⭐ ㉤ 평균 코사인   " };
					LogA("[mlt] 🧿     자                 ㈀오라클 ㈁섞음  ㈂캡션  ㈃섞음  ㈄값    ㈅섞음  ㈆상수  ㈇섞음\n");
					for (uint32 m = 0; m < kRepM; ++m)
						LogA("[mlt] 🧿     %s %6.3f %6.3f  %6.3f %6.3f  %6.3f %6.3f  %6.3f %6.3f\n",
							rn[m], _RepMean(m, 0u), _RepMean(m, 1u), _RepMean(m, 2u), _RepMean(m, 3u),
							_RepMean(m, 4u), _RepMean(m, 5u), _RepMean(m, 6u), _RepMean(m, 7u));
					LogA("[mlt] 🧿     ── 짝지은 차(같은 실행 안의 두 팔 ⇒ 실행 잡음이 상쇄된다 · 규율 29·37) ──\n");
					LogA("[mlt] 🧿     견줌(㈂ 캡션 − ㈃ 섞음)     │ d̄        · SE      · **|d̄|/SE** · 이긴 씨앗\n");
					const Pair rCeil = _PairedSrc(_rep[0], 0u, 6u);   // 245 ③ 천장 — 오라클 ↔ 상수(㉠)
					Pair rp[kRepM];
					for (uint32 m = 0; m < kRepM; ++m) rp[m] = _PairedSrc(_rep[m], 2u, 3u);
					for (uint32 m = 0; m < kRepM; ++m)
						LogA("[mlt] 🧿     %s │ %+.4f · %.4f · **%6.2f** · %u/%u\n",
							rn[m], rp[m].d, rp[m].se, rp[m].t, rp[m].win, rp[m].n);
					LogA("[mlt] 🧿     ⓘ 245 의 ③(㉠ ㈀−㈆ 오라클↔상수) t **%.2f** — ★ 그 자는 **죽은 채**다\n", rCeil.t);
					// ⭐ ④ 널 — 상수 팔 짝이 **모든 자에서** 안 서야 한다
					double nullMax = 0.0; uint32 nullAt = 0u;
					for (uint32 m = 0; m < kRepM; ++m)
					{
						const Pair pn = _PairedSrc(_rep[m], 6u, 7u);
						if (pn.t > nullMax) { nullMax = pn.t; nullAt = m; }
					}
					LogA("[mlt] 🧿     ⭐⭐ 🚪 ③ **표제 — 방향이 크기와 독립인가**: 순 `PR₁` t **%.2f** · %u/%u → %s\n",
						rp[3].t, rp[3].win, rp[3].n,
						(rp[3].t >= 3.0) ? "✅ ⭐ **방향이 독립으로 갈린다** — 245 의 ㉡ 이 구제된다"
						                 : "⛔ **정규화하면 사라진다** ⇒ ★ 245 의 ㉡ 은 **크기 효과**였다");
					LogA("[mlt] 🧿     ⭐ 🚪 ④ **널 — 상수 팔 ㈆−㈇** 최대 t **%.2f**(%s) → %s\n",
						nullMax, rn[nullAt], (nullMax < 3.0) ? "✅ **안 선다**"
						                                     : "⛔⛔ **널이 섰다** — ★ 자가 팔 자체를 재고 있다 ⇒ 판정불가");
					LogA("[mlt] 🧿     ⚠️ 🚪 ⑥ **크기의 몫** — t(㉥ 생) %.2f ÷ t(㉣ 단위) %.2f = **%.2f배**\n",
						rp[4].t, rp[3].t, (rp[3].t > 1.0e-9) ? (rp[4].t / rp[3].t) : 0.0);
					LogA("[mlt] 🧿        ⓘ **문턱이 없다** — 이것은 판정이 아니라 **읽을 수**다(등록문의 그 자리)\n");
					LogA("[mlt] 🧿     ⭐ 🚪 규율 68 **교차 확인** — ㉤ 코사인이 ㉣ 과 같은 방향인가: %s\n",
						((rp[3].d < 0.0 && rp[5].d > 0.0) || (rp[3].d > 0.0 && rp[5].d < 0.0))
							? "✅ **같은 사실의 두 얼굴**(좁아지면 정렬이 는다)"
							: "⚠️ **부호가 안 맞는다** — ★ 둘 중 하나를 잘못 읽고 있다");
					LogA("[mlt] 🧿        ⓘ ⚠️ ㉢(이동량)은 **음성 대조가 아니다** — `_Shuffle` 이 피셔-예이츠라\n");
					LogA("[mlt] 🧿          **낱말 다중집합이 정확히 보존된다**(245 가 소스로 확인) ⇒ 빈도는 같다\n");
					LogA("[mlt] 🧿          ⇒ 🧾 ***\"같은 빈도\"가 \"같은 기울기\"를 뜻하지 않는다*** — 표제의 **형제**다\n");
				}
			}
		}
		if (!_ctxSweep)
		{
		// ⭐ 회차 199 — **실행 잡음 자를 늘 찍는다**(194 가 만들었는데 문맥 스윕에만 갇혀 있었다)
		//   ★ 이것이 «절대 CE 를 회차 사이에 견줄 수 있나» 의 답이고, 세계를 바꾸면 **반드시** 다시 재야 한다.
		//   ⚠️ 짝지은 차는 안전하다(같은 실행 안의 두 팔이라 잡음이 공유·상쇄된다) — 흔들리는 것은 **절대값**이다.
		if (kOut >= 2u && !_ctxSweep)
		{
			double sd = 0.0, mx = 0.0; uint32 n = 0u;
			for (uint32 a = 0; a < _Arms(); ++a)
				for (uint32 s = 0; s < _seeds; ++s)
				{
					if (!_seedOk[s]) continue;
					const double dd = Abs((float)((double)_ce[0][a][s] - (double)_ce[1][a][s]));
					sd += dd; if (dd > mx) mx = dd; ++n;
				}
			const double av = (n == 0u) ? 0.0 : sd / (double)n;
			LogA("[mlt] 🧿   ── ⭐ **실행 잡음**(바깥 0 ↔ 1 · 같은 씨앗·같은 데이터 · 팔 %u × 씨앗) ──\n", _Arms());
			LogA("[mlt] 🧿     평균 |Δ| **%.5f** · 최대 **%.5f**  ↔ 194(세계 0 · 문맥 512)의 **0.0595**\n", av, mx);
			LogA("[mlt] 🧿     ⇒ ★ **절대 CE 를 이 값보다 작은 차이로 견주지 마라** — 짝지은 차는 안전하다\n");
			if (_w2 != 0)
				LogA("[mlt] 🧿     ⭐ 세계가 바뀌었다 ⇒ 198 의 「여지 0.0356 나트」와 견준다 → %s\n",
					(av < 0.0356)
						? "✅ ⭐ **잡음이 여지보다 작다** — 잴 수 있다"
						: "⛔ **잡음이 여지보다 크다** — ★ 이 세계에서도 몸통으로는 못 가른다");
		}
		// ⛔ 219 — L2 는 팔이 `λ` 축이라 아래 짝(㈀−㈁ 등)이 **뜻을 잃는다**(부채 D34 의 두 번째 얼굴)
		//   ⚠️ 위 **실행 잡음은 팔과 무관**하므로 L2 에서도 찍는다(217 이 그 값을 썼다).
		if (_lang2 || _actOn)
			LogA("[mlt] 🧿   ── ⓘ **② 짝지은 차는 안 찍는다**(팔 축이 다르다 · D34) ──\n");
		else {
		LogA("[mlt] 🧿   ── ② 짝지은 차(규율 29·37) ──\n");
		LogA("[mlt] 🧿     견줌              │ d̄        · SE      · **|d̄|/SE** · 이긴 씨앗\n");
		LogA("[mlt] 🧿     ⭐ ㈀−㈁ 천장  │ %+.5f · %.5f · **%6.2f** · %u/%u\n", pCap.d, pCap.se, pCap.t, pCap.win, pCap.n);
		LogA("[mlt] 🧿     ㈂−㈃ maxV       │ %+.5f · %.5f · **%6.2f** · %u/%u\n", pMv.d, pMv.se, pMv.t, pMv.win, pMv.n);
		LogA("[mlt] 🧿     ㈄−㈅ 어디로     │ %+.5f · %.5f · **%6.2f** · %u/%u%s\n",
			pDir.d, pDir.se, pDir.t, pDir.win, pDir.n,
			(pDir.d > 0.0) ? "  ⚠️ **양수 = 해롭다**(규율 80 재현)" : "");
		LogA("[mlt] 🧿     ⭐ ㈆−㈇ **표제**│ %+.5f · %.5f · **%6.2f** · %u/%u\n", pWh.d, pWh.se, pWh.t, pWh.win, pWh.n);
		// ⭐ 회차 184 — **표제가 ㈆(어느 물체)로 바뀌었다.**
		//   ⚠️ 183 은 ㈄(어디로)를 표제로 등록했는데 3씨앗 파일럿이 **부호가 반대**임을 밝혔고
		//     (`d̄` +0.165 · σ 0.262 ⇒ 필요 씨앗 23) ㈆ 가 **t 4.23 · 3/3** 으로 통과했다.
		//   ★ **회차 안에서 표제를 바꾸지 않았다** — 183 을 파일럿으로 마감하고 **184 로 새로 등록**했다.
		//   ⇒ ⭐ 손계산(규율 77): σ(㈆) = 0.0678×√3 = 0.1174 ⇒ 12씨앗 t = **8.46** ⇒ 돌릴 값이 있다.
		//   ★ 근거 = 규율 79: 표적이 **(어느 슬롯, 어떤 방향)** 두 축이고 ㈆ 가 **슬롯 축**을 좁힌다.
		// ⭐ 규율 65 — **그 자리의 `σ_diff`** 로 필요 씨앗 수를 역산한다.
		//   ★ SE = σ/√n 이므로 `t ≥ 3` 을 얻는 데 필요한 n = (3σ/|d̄|)²
		if (_seeds > 1u && pTop.n > 1u && Abs((float)pTop.d) > 1.0e-9)
		{
			const double sig = pTop.se * Sqrt((float)(double)pTop.n);      // σ_diff 복원
			const double need = (3.0 * sig / Abs((float)pTop.d)) * (3.0 * sig / Abs((float)pTop.d));
			LogA("[mlt] 🧿     ⭐ **`σ_diff`(표제 자리) = %.5f** ⇒ `t ≥ 3` 에 필요한 씨앗 = **%.0f**\n",
				sig, need);
			LogA("[mlt] 🧿        ⇒ (이번 %u 씨앗) %s\n", _seeds,
				(need <= (double)_seeds)
					? "✅ **이 예산이면 판정할 수 있다** — 돌릴 값이 있다"
					: "⛔ **이 예산으로는 못 판정한다**(규율 65) ⇒ ★ 씨앗을 사거나 손잡이를 키운다");
			LogA("[mlt] 🧿        ⚠️ 179 등록문의 `t 5.7` 은 **178 자리의 SE** 로 계산한 것이다 —\n");
			LogA("[mlt] 🧿           점 ㈄ 는 **새 세계·새 표적·새 눈금**이라 이 값이 그 자리의 것이다\n");
		}
		}   // else — ⭐ 219 가 L2 를 갈랐다(D34)
		}   // if (!_ctxSweep)

		// ── ③ P3 — ⭐ 칸 1 닫힘 조건 ㉠ ────────────────────
		// ⭐ 회차 194 — 문맥 스윕에서는 **마지막 팔(8192)**이 그 자리다(모든 팔에 낱말이 없다)
		// ⛔⛔ **회차 199 가 버그를 찾았다** — 섞기/눈감기 모드에서 `kOracleS`(팔 1)는
		//   *"오라클 섞음"* 이 아니라 **「값 섞기」/「tCut 7」** 이다 ⇒ ★ P3 가 **섞은 팔을
		//   몸통으로 읽고 있었다**(199 에서 1.32891 로 찍혀 초과 +5.0% ⇒ 실제는 **+0.98%**).
		//   ⚠️ **193·192 도 같은 버그였다** — 다행히 그 회차들의 표제는 P3 가 아니었다.
		//   ⇒ ★ 그 모드들에서 몸통은 **팔 0**(기준 = 안 섞음 · 안 끊음)이다.
		//   ⭐ 회차 200 — 언어 모드에서 「낱말 없는 몸통」은 **㈄ 상수 팔(4)** 이다
		//     (팔 0·2 는 낱말이 실려 있고, 상수 팔은 축만 둘 늘린 것이다)
		//   ⭐ 회차 203 — `q` 스윕에서 몸통은 **팔 0(q = 0)** 이다(201 과 같은 자리 = 배관 검산)
		//   ⭐ 회차 209 — 언어 모드의 몸통이 **4 → 6** 으로 옮겼다(오라클 천장을 0·1 에 넣었다)
		//     ⇒ ★ 이것이 **공용 규율 16 이 경고한 그 자리**다 — 배치를 바꾸면 **참조도 따라온다**
		// ⭐ 회차 221 — 행동 모드의 몸통은 **팔 0(행동 상수)** 이다 = 순수 기준선
		const uint32 kBodyArm = _actOn ? 0u
		                      : (_ctxSweep ? (kCtxArms - 1u)
		                      : (_qSweep ? 0u
		                      : (_lang2 ? 0u : (_lang ? 6u : ((_shufOn || _blindOn) ? 0u : kOracleS)))));
		double bodySum = 0.0; uint32 bodyN = 0u;
		for (uint32 s = 0; s < _seeds; ++s)
		{
			if (!_seedOk[s]) continue;
			bodySum += _M2(kBodyArm, s); ++bodyN;   // ⚠️ **낱말이 없는 팔** = 순수 몸통
		}
		const double body = (bodyN == 0u) ? 0.0 : bodySum / (double)bodyN;
		const double reach = (goal > 1.0e-9) ? 100.0 * (1.0 - (body - goal) / goal) : 0.0;
		LogA("[mlt] 🧿   ── ③ ⭐ **`P3` — 칸 1 닫힘 조건 ㉠**(도달률 > 0) ──\n");
		LogA("[mlt] 🧿     몸통 CE(낱말 없는 팔 ㈁) **%.5f** ↔ **목표선 %.4f**\n", body, goal);
		LogA("[mlt] 🧿     🚪 **`P3`**(몸통 CE < 목표선) → %s\n",
			(body < goal)
				? "✅✅ ⭐ ***칸 1 닫힘 조건 ㉠ 을 이 표현에서 처음 만족한다***"
				: "⛔ **예측이 아직 반쪽이다**(회차 143 의 그 자리)");
		LogA("[mlt] 🧿     ⓘ 목표선 대비 초과 **%+.1f%%**(음수면 목표선 아래 = 통과)\n",
			(goal > 1.0e-9) ? 100.0 * (body - goal) / goal : 0.0);
		// ⭐ 회차 222 — **축의 대가를 숫자로 적는다**(배관 관문 ①)
		//   ★ 견줄 자리 = **208**(같은 세계 궤도 · `lr×0.5` · 문맥 8192 · `q=0.05` · 낱말 상수) = **−5.75%**
		//   ⚠️ 189 실측: 축을 **8개** 늘리니 `P3` 이 **+4.6%p** 나빠졌다 ⇒ ★ 하나면 그보다 작아야 한다.
		if (_actOn)
		{
			const double ex = (goal > 1.0e-9) ? 100.0 * (body - goal) / goal : 0.0;
			const double cost = ex - (-5.75);
			LogA("[mlt] 🧿     ⭐ 🚪 ① **배관 — 축 하나의 대가** = %+.1f%%p\n", cost);
			LogA("[mlt] 🧿        (지금 **%+.1f%%** ↔ **208 의 −5.75%%** · 같은 세계·`lr`·문맥·`q`·낱말 상수)\n", ex);
			LogA("[mlt] 🧿        ⓘ 189 실측: 축 **8개**를 늘려 **+4.6%%p** ⇒ 하나면 그보다 작아야 한다 → %s\n",
				(cost <= 4.6)
					? ((body < goal) ? "✅ **싸고 `P3` 도 선다**" : "🔶 **대가는 작은데 `P3` 가 안 선다**")
					: "⛔⛔ **축 하나가 8개보다 비싸다** — ★ 그러면 다음 물음은 **「행동 축을 값싸게」** 다");
		}
		// ⛔⛔ **회차 213 이 로그에서 거짓 ⛔ 셋을 찾았다** — 📌 부채 **D34**
		//   ⚠️ 문맥 스윕 모드는 **팔이 문맥**인데 여기부터의 옛 181 관문들이 **고정 팔 번호**
		//     (㈀ 오라클 · ㈆ 어느물체 · D11 평가가 도는 팔 0)를 읽는다 ⇒ ★ 숫자가 **뜻이 없다**.
		//   ⇒ ⚠️⚠️ 그런데 그것이 *"덜 먹었다"* · *"분모가 없다"* · ***"창이 없다"*** 로 찍혔다
		//     ⇒ ⛔ **다음 회차가 로그를 훑다가 그것을 최신 판정으로 읽는다**
		//       (204·205 가 낡은 참조로 거짓 ⛔ 를 낸 것과 **같은 계열**이다).
		//   ⇒ ★ 처방: **막는다.** ***숫자가 안 나오는 것이 틀린 숫자보다 낫다.***
		if (_qChg && !_ctxSweep)
		{
			// ⭐ 회차 185 — **대조 검산**과 **파레토**를 같이 적는다
			double keepSum = 0.0; uint32 keepN = 0u;
			for (uint32 s = 0; s < _seeds; ++s)
			{
				if (!_seedOk[s]) continue;
				// ⭐ 회차 207 — 팔 축이 생겼다 ⇒ **몸통 팔의** 지속 CE 를 본다
				for (uint32 o = 0; o < kOut; ++o) { keepSum += (double)_ceKeep[o][kBodyArm][s]; ++keepN; }
			}
			const double keep = (keepN == 0u) ? 0.0 : keepSum / (double)keepN;
			LogA("[mlt] 🧿     ⭐ **대조 검산**(마스크가 실제로 먹었나) — 지속 CE **%.4f**\n", keep);
			LogA("[mlt] 🧿        회차 144 는 0.259 → **5.277** 로 폭발했다 ⇒ %s\n",
				(keep > 3.0) ? "✅ **마스크가 먹었다**" : "⚠️ **덜 먹었다** — 학습 풀을 다시 본다");
			LogA("[mlt] 🧿     ⚠️⚠️ **파레토** — 지속 CE %.4f 는 **판정에 안 쓴다**(그 팔은 지속에 손실이 0 이다)\n", keep);
			LogA("[mlt] 🧿        ★ 진짜 대가는 **가중**(둘 다 배우되 변화에 무게)에서만 보인다 ⇒ **다음 회차**\n");
			LogA("[mlt] 🧿     ⚠️⚠️ 그리고 `P3` 를 넘어도 그것은 **「변화만 학습」의 성과**다 —\n");
			LogA("[mlt] 🧿        ★ 칸 1 이 요구하는 「경험 학습」의 **절반(지속)을 버린 것**이므로\n");
			LogA("[mlt] 🧿          ***조건이 온전히 서려면 가중까지 가야 한다***(등록문에 미리 적었다)\n");
		}

		// ⛔⛔ **부채 D34 의 나머지 둘**(회차 213) — 아래 두 블록도 **고정 팔 번호**를 읽는다:
		//   ④ 활용률 표(㈀ 오라클 · ㈆ 어느물체) · 관문 요약(*"창이 없다"*).
		//   ⇒ ⚠️⚠️ 문맥 스윕에서는 그 팔이 **문맥**이라 전부 0.00 이 찍히고 ⛔ 로 판정됐다
		//     ⇒ ⛔ 그중 *"창이 없다"* 는 **203 이 이미 창을 찾은 결론**을 뒤집어 보이게 한다.
		//   ⇒ ★ 막는다. ⭐ 대신 **왜 안 찍나**를 한 줄 남긴다(침묵도 오해를 만든다).
		// ⛔⛔⛔ **회차 219 — 같은 함정의 두 번째 얼굴이었다.** 213 은 `_ctxSweep` 만 막았는데
		//   **L2 모드(`_lang2`)도 팔 축이 `λ`** 라 고정 팔 번호가 뜻을 잃는다.
		//   ⇒ ⛔ 217 이 그 숫자로 *"언어가 무너진다"* 를 적었다 ⇒ 🗑️ 근거 철회.
		//   ⇒ ★ 그래서 **「팔 축이 다른 모드」 전부를 한 이름에 모은다**(203 이 배운 관용구).
		if (_ctxSweep || _lang2 || _actOn || _capOn || _effOn)
		{
			LogA("[mlt] 🧿   ── ⓘ **옛 181 관문은 안 찍는다**(팔 축이 다른 모드 · 부채 D34) ──\n");
			LogA("[mlt] 🧿     ⚠️ 이 모드는 팔이 **%s**라 ㈀ 오라클·㈆ 어느물체 같은 **고정 팔**이 없다\n",
				_ctxSweep ? "문맥(× 언어)" : (_actOn ? "행동 축의 내용" : "`λ`(언어 무게)"));
			LogA("[mlt] 🧿        ⇒ ★ 그 관문의 숫자는 **나오지만 뜻이 없다**(0 이나 ⛔ 로 찍힌다)\n");
			LogA("[mlt] 🧿        ⇒ ⭐ ***숫자가 안 나오는 것이 틀린 숫자보다 낫다*** — 판정은 위 블록이 한다\n");
			if (_lang2)
			{
				LogA("[mlt] 🧿     ⛔⛔ **회차 217 이 여기서 속았다** — 「천장 t 0.79」·「순 Î 0」을\n");
				LogA("[mlt] 🧿        *\"언어가 무너진다\"* 로 읽었다. ⇒ ⚠️ 순 `Î` 가 0 인 것은 **결함이 아니라\n");
				LogA("[mlt] 🧿        설계**다 — L2 는 **모든 팔에 같은 캡션**을 주므로 팔끼리의 차가 0 이다\n");
				LogA("[mlt] 🧿        ⇒ ★ 캡션의 정보는 **`mltl1s0 -mltbal`**(회차 218)이 잰다\n");
			}
		}
		if (!_ctxSweep && !_lang2 && !_actOn && !_capOn && !_effOn)
		{
		// ── ④ 천장 · 전달율 · 활용률(회차 175·177 의 자) ──────────
		const double hOra = _MeanOf(_hW[kOracle]), hMv = _MeanOf(_hW[kMaxV]);
		const double hDir = _MeanOf(_hW[kDir]),    hWh = _MeanOf(_hW[kWhich]);
		const double capO = (nCh > 1.0e-9) ? ((double)kTime * hOra) / nCh : 0.0;
		const double capM = (nCh > 1.0e-9) ? ((double)kTime * hMv)  / nCh : 0.0;
		const double capD = (nCh > 1.0e-9) ? ((double)kTime * hDir) / nCh : 0.0;
		const double capW = (nCh > 1.0e-9) ? ((double)kTime * hWh)  / nCh : 0.0;
		const double iOra = _MeanOf(_iW[kOracle]) - _MeanOf(_iW[kOracleS]);
		const double iMv  = _MeanOf(_iW[kMaxV])   - _MeanOf(_iW[kMaxVS]);
		const double iDir = _MeanOf(_iW[kDir])    - _MeanOf(_iW[kDirS]);
		const double iWh  = _MeanOf(_iW[kWhich])  - _MeanOf(_iW[kWhichS]);
		LogA("[mlt] 🧿   ── ④ ⭐ **천장 · 전달율 · 활용률**(회차 175·177 의 자) ──\n");
		// ⚠️ 📌 D45 — 여기도 **`Î` 기준**이다(`|d̄| ÷ Î`). 「천장의 몫」과 헷갈리지 마라.
		LogA("[mlt] 🧿     낱말        H       정보천장   Î(−섞음)  전달율   ⭐ **활용률(Î 기준)**\n");
		LogA("[mlt] 🧿     ㈀ 오라클  %.4f  %.4f   %+.4f   %5.1f%%   **%.2f**\n",
			hOra, capO, iOra, (capO > 1.0e-12) ? 100.0 * iOra / capO : 0.0,
			(Abs((float)iOra) > 1.0e-9) ? Abs((float)pCap.d) / iOra : 0.0);
		LogA("[mlt] 🧿     ㈂ maxV    %.4f  %.4f   %+.4f   %5.1f%%   **%.2f**\n",
			hMv, capM, iMv, (capM > 1.0e-12) ? 100.0 * iMv / capM : 0.0,
			(Abs((float)iMv) > 1.0e-9) ? Abs((float)pMv.d) / iMv : 0.0);
		const double uDir = (Abs((float)iDir) > 1.0e-9) ? Abs((float)pDir.d) / iDir : 0.0;
		// ⭐ 회차 184 — **표제의 활용률**은 ㈆ 것이다
		const double uTop = (Abs((float)iWh) > 1.0e-9) ? Abs((float)pWh.d) / iWh : 0.0;
		LogA("[mlt] 🧿     ⭐ ㈄ 어디로 %.4f  %.4f   %+.4f   %5.1f%%   ⭐ **%.2f**\n",
			hDir, capD, iDir, (capD > 1.0e-12) ? 100.0 * iDir / capD : 0.0, uDir);
		LogA("[mlt] 🧿     ㈆ 어느물체 %.4f  %.4f   %+.4f   %5.1f%%   **%.2f**\n",
			hWh, capW, iWh, (capW > 1.0e-12) ? 100.0 * iWh / capW : 0.0,
			(Abs((float)iWh) > 1.0e-9) ? Abs((float)pWh.d) / iWh : 0.0);
		LogA("[mlt] 🧿     🚪 **활용률**(표제 ㈆ > 0.8) → %s\n",
			(uTop > 0.8) ? "✅ ⭐ **규율 79 — 슬롯 축을 좁히는 낱말은 잘 쓰인다**"
			             : "⛔ **활용률이 낮다**");
		LogA("[mlt] 🧿        ⚠️ ㈄ 「어디로」 활용률 %.2f 는 **뜻이 없다** — `d̄` 가 **양수**면\n", uDir);
		LogA("[mlt] 🧿           그 비는 「돕는 정도」가 아니라 「해치는 정도」다(규율 80)\n");

		// ── 관문 · 판정 ─────────────────────────────────────────
		const bool gPipe = gPipeS;   // ⭐ 자기 검산(`e^목표선` 이 2~5)
		const bool gOra  = (pCap.d < 0.0) && (pCap.t >= 3.0);
		const uint32 pass = _SignPass();
		const bool gDir  = (pTop.win >= pass) && (pTop.d < 0.0) && (pTop.t >= 3.0);
		const bool gP3   = (body < goal);
		LogA("[mlt] 🧿   ── 관문 ──\n");
		LogA("[mlt] 🧿     ⭐ 배관①(`e^목표선` = %.2f 이 2~5) → %s\n", fanout, gPipe ? "✅" : "⛔");
		LogA("[mlt] 🧿     ⭐ 천장이 서나(|d̄|/SE %.2f ≥ 3) → %s\n", pCap.t, gOra ? "✅" : "⛔ **분모가 없다**");
		LogA("[mlt] 🧿     ⭐ `P3`(칸 1 ㉠) → %s\n", gP3 ? "✅✅" : "⛔");
		LogA("[mlt] 🧿     ⭐ **표제** ㈆ **어느 물체** %u/%u · t %.2f → %s\n",
			pTop.win, pTop.n, pTop.t, gDir ? "✅✅" : "⛔");
		if (_qw > 0.0f)
		{
			// ⭐ 회차 188 — **두 칸이 동시에 서나**가 표제다
			LogA("[mlt] 🧿     ⭐ **두 칸 동시**(q = %.2f) — 칸 1 `P3` %s · 칸 10 ㈆ %s → %s\n",
				(double)_qw, gP3 ? "✅" : "⛔", gDir ? "✅" : "⛔",
				(gP3 && gDir) ? "⭐ ✅✅ ***둘 다 섰다 — 이 트랙의 가장 큰 결과다***"
				              : "⛔ **창이 없다**");
			LogA("[mlt] 🧿        ⓘ 견줄 자리 — q=0.00: `P3` **+1.1%%** · ㈆ t 1.51(회차 187)\n");
			LogA("[mlt] 🧿                      q=1.00: `P3` **+54.6%%** · ㈆ t 6.03(회차 184)\n");
			LogA("[mlt] 🧿        ⭐ **단조 관문** — q 가 오르면 `P3` 는 나빠지고 칸 10 은 좋아져야 한다\n");
			LogA("[mlt] 🧿           지금 `P3` **%+.1f%%** · ㈆ t **%.2f** → %s\n",
				(goal > 1.0e-9) ? 100.0 * (body - goal) / goal : 0.0, pTop.t,
				(((body - goal) / goal > 0.011) && (pTop.t > 1.51))
					? "✅ **단조가 맞다**(둘 다 q=0 보다 그 방향)"
					: "⚠️ **단조가 아니다** — ★ 손잡이가 다른 것을 흔들고 있다");
		}
		if (!_finite || ok < _seeds)
			LogA("[mlt] 🧿   ⭐ 판정 = ⛔ **판정불가** — 배관이 안 섰다\n");
		else if (!gPipe)
			LogA("[mlt] 🧿   ⭐ 판정 = ⛔ **판정불가** — ***목표선이 손계산과 다르다***(표적 생성을 다시 본다)\n");
		else if (!gOra)
			LogA("[mlt] 🧿   ⭐ 판정 = ⛔ **판정불가** — 오라클조차 몸통을 안 돕는다 ⇒ 분모가 없다\n");
		else if (gDir)
			LogA("[mlt] 🧿   ⭐ 판정 = ⭐ ***㈆ 어느 물체가 몸통을 돕는다 — 칸 10 이 열렸다***\n"
			     "[mlt] 🧿      (활용률 %.2f · t %.2f · %u/%u · `P3` %s)\n",
			     uTop, pTop.t, pTop.win, pTop.n, gP3 ? "✅" : "⛔");
		else
			LogA("[mlt] 🧿   ⭐ 판정 = ⛔ **㈆ 어느 물체도 몸통을 안 돕는다**\n"
			     "[mlt] 🧿      (활용률 %.2f · t %.2f · %u/%u) ⇒ ★ 천장은 섰으므로 자는 살아 있다\n",
			     uTop, pTop.t, pTop.win, pTop.n);
		}   // if (!_ctxSweep && !_lang2) — 부채 D34(213 이 열고 219 가 넓혔다)
		if (_seeds == 1u)
			LogA("[mlt] 🧿   ⭐ **1씨앗 진단이다 — 판정하지 않는다.** 배관·부호·크기만 본다(규율 74)\n");
		LogA("[mlt] 🧿   ⚠️ 계급이 250 → %u 라 CE 절대값을 회차 1~180 과 견주지 않는다(규율 58)\n", kN);
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}
};
