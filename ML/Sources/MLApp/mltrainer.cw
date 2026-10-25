#include "mltrainer.gen.h"    // IDE 인식용(빌드는 gen.h #pragma once 로 중복 skip). cwgen 생성 헤더.
#include "drawprogram.gen.h"  // `domain draw` 호스트
#include "episodegen.gen.h"   // 에피소드 생성기
// mltrainer.cw — 🧠 **학습기의 창 서브시스템.** 학습 루프가 사는 자리.
//
// ★ **왜 `GUIWindowSubsystem` 파생인가** — 이 베이스가 GUI·폰트·텍스트 머티리얼과 **매 프레임 펌프**를
//   갖고 파생은 훅만 채운다. 그리고 훅 하나가 정확히 우리가 필요한 자리다:
//     · `OnGuiUpdate(dt)`   — 입력 뒤 · 레이아웃 앞 = **CPU 쪽 본체**(에피소드 생성 · 배치 · 판정)
//     · `OnPreGuiRender(cmd)` — 렌더패스 **밖** = **컴퓨트의 자리**(학습 스텝의 GPU 커널 전부)
//   ⚠️ `Init`/`OnUpdate`/`OnRenderThread` 는 베이스에서 `final` 이다 — 이어받으려 하지 마라.
//
// 🚧 **지금 하는 일 셋**:
//   · **P-1** — 커리큘럼 5칸을 만들고 실행해 **격자 PNG 한 장**으로 떨어뜨린다(`OnGuiUpdate` 1회).
//   · **P1 검산** — forward/backward 를 CPU 레퍼런스와 견주고 **수치 그래디언트**로 backward 식을 검산한다.
//   · **P1 학습** — 그 검산이 통과한 **뒤에** AdamW 로 실제로 학습시키고, CPU 레퍼런스와 파라미터를 견준다.
//     ★ 순서가 뜻이 있다 — 기울기가 틀린 채로 학습시키면 "손실이 안 내려간다" 를 옵티마이저 탓으로 오진한다.
//   ★ GUI 위젯을 만들지 않는 이유 = 판정에 필요 없다(그림과 로그로 끝난다). 시각화는 P2 다.
//   ★ **모델/학습의 몸통은 `MLCore` 에 있다** — 이 파일은 앱 껍데기다(창·프로브·시각화).
//     그렇게 가른 이유: 모델이 창을 몰라야 하고, P5 의 headless 트레이너가 같은 몸통을 써야 한다.
using namespace PE;

class MLTrainer : public GUIWindowSubsystem
{
public:
	// 지금까지 돈 학습 스텝. ⚠️ **프레임 수가 아니다** — 한 프레임에 여러 스텝을 돌릴 수도 있고
	//   커널이 준비 안 된 프레임은 한 스텝도 안 돈다.
	int step = 0;

protected:
	bool OnGuiInit() override
	{
		LogA("[ml] MLTrainer 붙었다 — P-1(데이터 생성기) 프로브를 한 번 돌린다\n");
		return true;
	}

	// ══════════════════════════════════════════════════════════════════
	// 🔒 **상위 게이트 `-mlt` 를 함축한다**(2026-09-07 · 회차 265 가 대가를 치렀다)
	// ══════════════════════════════════════════════════════════════════
	//   ⛔⛔ **실측**: `-mltl1s0 -mltbody` 만 주고 **`-mlt` 를 빠뜨리자 ML 의 기본 하네스가
	//     조용히 돌았다** — 에러도, 종료 코드 이상도 없고 진단은 *"`[mlt]` 줄이 하나도 없다"* 뿐이었다.
	//     ⇒ ★ 5분과 판 하나를 버렸다(그리고 로그 378KB 를 읽어야 원인이 보였다).
	//   ⚠️⚠️ 그리고 **이것은 새 병이 아니다** — `mltl1s0.cw` 가 회차 229 에서 **한 칸 아래**의 같은
	//     병(하위 모드만 주고 `-mltl1s0` 을 빠뜨림 · 20분)에 대해 이미 처방을 세웠다:
	//     ***「하위 모드 이름이 하나라도 있으면 게이트를 함축한다」***.
	//   ⇒ 🧾 ★ 그 처방을 **상위 게이트에도** 둔다 ⇒ 그 사고가 **원리적으로 없어진다.**
	//   ⚠️ 그리고 **함축했다는 사실을 한 줄 찍는다** — 조용히 고치면 그것도 조용한 성공이다
	//     (229 가 적어 둔 그 단서 그대로).
	// ══════════════════════════════════════════════════════════════════
	// 🛑 **2026-09-07 · ML 이 닫혔다(D203) ⇒ 기본이 MLT 다**(👤 사람이 정했다)
	// ══════════════════════════════════════════════════════════════════
	//   ⚙️ 근거: ML 트랙은 `main` 에 머지하고 얼렸다(태그 `ml-closed-D203`).
	//     ⇒ ★ 얼린 트랙이 **기본값**이면 `-mlt` 누락이 곧 **조용한 오작동**이다
	//       (실측: 회차 265 가 그것으로 5분과 판 하나를 버렸다 · 📌 D68).
	//   ⇒ 🧾 **기본을 뒤집는다** — 아무 것도 안 주면 **MLT** 다.
	//   ★ 규칙 셋(위에서 아래로):
	//     ㈀ `-mlt` 로 시작하는 인자가 있다 ⇒ **MLT**(하위 모드만 줘도 된다)
	//     ㈁ `-ml` 로 시작하는 **다른** 인자가 있다 ⇒ **ML**(얼린 트랙을 일부러 부른 것이다)
	//        ⚠️ `-mlg`·`-mll`·`-mld`·`-mls`·`-mlv`·`-mlw`·`-mlr`·`-mlb`·`-mla` … 목록을 안 쓴다
	//     ㈂ 둘 다 없다 ⇒ **MLT**(새 기본값)
	//   ⚠️ 그리고 **고른 결과를 한 줄 찍는다** — 조용히 고르면 그것도 조용한 성공이다(229 의 단서).
	// ⚠️⚠️ **도구 모드에서는 아무 트랙도 안 돈다** — 쿡 파이프라인이 이 exe 를 부른다
	//   (`--dump-script-api` = 창·RHI 없이 표면만 쓰고 끝난다 · `--cook-gen` = 생성 스크립트를 돈다)
	//   ⇒ ★ 기본을 MLT 로 뒤집는 김에 그 자리를 **막는다** — 옛 기본값에서는 거기서 **ML 프로브가
	//     돌 수 있었고**, 새 기본값이면 **MLT 의 gradcheck·베이스라인**이 돌아 더 무겁다.
	static bool _ToolMode()
	{
		return OS::CommandLine::Has("--dump-script-api") || OS::CommandLine::Has("--cook-gen");
	}

	static bool _MltGate()
	{
		static bool cached = false, val = true;
		if (cached) return val;
		cached = true;
		bool sawMlt = false;
		const char* mlArg = nullptr;
		const int n = (int)OS::CommandLine::Count();
		for (int i = 0; i < n; ++i)
		{
			const char* a = OS::CommandLine::At(i);
			if (a == nullptr) continue;
			if (a[0] != '-' || a[1] != 'm' || a[2] != 'l') continue;
			if (a[3] == 't') { sawMlt = true; continue; }        // `-mlt`·`-mlt*`
			if (a[3] == '\0') continue;                          // `-ml` 자체 = 얼린 트랙 호출
			if (mlArg == nullptr) mlArg = a;                     // `-mlg`·`-mls`… (ML 하위 모드)
		}
		if (sawMlt) { val = true; }
		else if (mlArg != nullptr || OS::CommandLine::Has("-ml"))
		{
			val = false;
			LogA("[ml] 🔒 ⚠️ **얼린 ML 트랙을 부른다**(`%s`) — 기본은 MLT 다(ML 은 D203 에서 닫혔다)\n",
				(mlArg != nullptr) ? mlArg : "-ml");
		}
		else
		{
			val = true;
			LogA("[mlt] 🔒 ⭐ **기본 트랙 = MLT** (`-ml*` 인자가 없다 · ML 은 D203 에서 닫혔다)\n");
		}
		return val;
	}

	// 입력 뒤 · 레이아웃 앞 = 이 서브시스템의 본체(CPU 쪽).
	void OnGuiUpdate(float /*dt*/) override
	{
		// ⚠️ **첫 `OnGuiUpdate` 에서 1회**다(`OnGuiInit` 이 아니다) — 서브시스템이 서로를 필요로 하는
		//   시작 작업은 그 자리가 안전하다는 규약을 따른다(→ Docs/Guide.md 의 그 함정 4).
		if (_probed) return;
		_probed = true;
		if (_ToolMode()) return;          // ⚠️ 쿡·API 덤프에서는 아무 트랙도 안 돈다
		// 🪞 **트랜스포머 트랙의 CPU 쪽 판정은 여기다** — 판정 ②(수치 vs 해석)와 🚧 배관 관문.
		//   ⚠️⚠️ GPU 판정 ①(디스패치·회수)은 `OnPreGuiRender` 다. **둘을 한 자리에 두면 안 된다.**
		//   ⚠️⚠️⚠️ 실측으로 밟았다: 이것을 `_TickGemmProbe()` 안에 뒀는데 `OnPreGuiRender` 가
		//     `-mlt` 에서 early return 하게 되자 **그 함수가 아예 안 돌아 배너와 판정 ② 가 조용히
		//     사라졌다.** 그리고 판정 ① 만 grep 해서 「통과」로 읽었다 ⇒ **없어진 줄은 grep 으로 안 보인다.**
		if (_MltGate()) { MLT::Run(); return; }
		_RunProbe();
		_RunPairProbe();   // 🧿 감각 어휘 최소대립쌍(줄마다 축 하나)
	}

	// ★ 렌더패스 **밖** = 컴퓨트의 자리. 학습 스텝의 GPU 커널이 전부 여기서 돈다.
	//   ⚠️ 렌더 스레드다 — 여기서 CPU 리드백을 하면 그 프레임이 멈춘다(스칼라 몇 개만 꺼낸다).
	void OnPreGuiRender(RHICommandList* cmd) override
	{
		// 🪞 **트랜스포머 트랙은 자기 훅으로 간다** — `_TickGemmProbe()` 의 서명을 **안 건드린다**
		//   (형제 트랙의 코드다). ⇒ `-mlt` 모드가 이 GPU 훅을 **온전히 소유**하고 서로 간섭이 없다.
		//   ⚠️ `MLT::Tick` 은 **RHI\*** 만 필요하다 — `MLKernel::Dispatch` 는 커맨드리스트를 안 받고
		//     프레임 컴퓨트 커맨드버퍼에 누적한다(제출은 Present 1회). 렌더 스레드이기만 하면 된다.
		if (_ToolMode()) return;          // ⚠️ 쿡·API 덤프에서는 아무 트랙도 안 돈다
		if (_MltGate()) { MLT::Tick(cmd != nullptr ? cmd->GetRHI() : nullptr); return; }
		_TickGemmProbe();
	}

private:
	bool _probed = false;

	// ── 🧮 P1 판정 — **backward 가 맞나**(수치 그래디언트로 검산) ──────────────────────
	//   모델: `C = A·B` · 손실 `L = ½·Σ(C − T)²` ⇒ `dC = C − T`, `dB = Aᵀ·dC`.
	//   ★ **한 프레임에 커널 넷을 순서대로 돌린다**(gemm → sub → gemm → gradcheck) —
	//     아레나 하나를 한 번 바인딩했으므로 오프셋만 바꿔 계속 부른다(= 학습 한 스텝의 모양).
	//     ⚠️ 디스패치 사이 메모리 배리어는 **RHI 가 자동으로** 넣는다(같은 프레임의 두 번째 디스패치부터).
	//   ⚠️⚠️⚠️ **회수는 다음 프레임**이다(G′) → 상태 기계: 0 아직 · 1 디스패치했다 · 2 판정 끝.
	//   ★ 크기를 **아주 작게** 잡는다 — gradcheck 스레드마다 forward 를 두 번 하므로 비용이 `2·M·N·K` 다.
	//     이 판정의 목적은 정확성이고 처리량이 아니다.
	//   ⚠️ 그래도 **16 의 배수는 피한다**(`ceil`·범위검사가 실제로 필요해지게).
	int      _gStage = 0;
	MLArena  _arena;
	MLKernel _kGemm, _kSub, _kGrad, _kAdam;
	MLTensor _tA, _tB, _tT, _tC, _tDC, _tDB, _tNum, _tM, _tV;
	static constexpr uint32 kGM = 5, kGN = 3, kGK = 4;

	// ── ⚙️ 학습 루프 상태 ─────────────────────────────────────────────────────────
	//   ★ **손실은 한 스텝 늦게 읽는다**(G′) — 이 엔진은 dispatch 를 누적해 Present 에서 제출하므로
	//     "이번 프레임에 디스패치하고 이번 프레임에 읽기" 가 불가능하다. 그래서 루프가 이 모양이다:
	//        프레임 N: (지난 스텝의 dC 를 읽어 손실을 적는다) → 이번 스텝을 디스패치한다
	//     ⇒ **손실 곡선이 한 스텝 뒤처진다**(버그가 아니라 파이프라인이다).
	//   ★ 손실은 **CPU 가 dC 로 계산한다** — `L = ½·Σ(C−T)² = ½·Σ dC²` 이므로 리덕션 커널이 필요 없다.
	//     ⇒ 커널을 하나 안 만들고 얻는다(리덕션은 학습 곡선을 GPU 에 남길 때 필요해진다).
	int   _step = 0;
	int   _trainStage = 0;    // 0 = 아직 · 1 = 학습 중 · 2 = 끝(판정 완료)
	float _loss0 = 0.0f;      // 첫 손실(내려갔나를 재는 기준)
	static constexpr int   kSteps = 60;
	static constexpr float kLr = 5.0e-2f;
	static constexpr float kB1 = 0.9f, kB2 = 0.999f, kAdamEps = 1.0e-8f, kWd = 0.0f;
	// CPU 레퍼런스 학습의 상태(같은 초기값에서 같은 식으로 함께 학습한다).
	Array<float> _cpuB, _cpuM, _cpuV;
	// ⚠️ `eps` 가 이 검산의 전부다: 너무 작으면 **부동소수 상쇄**로 분자가 0 이 되고, 너무 크면
	//   **2차 오차**가 섞인다. float32 에서 1e-2 가 실전 범위의 안전한 쪽이다.
	static constexpr float kEps = 1.0e-2f;

	void _TickGemmProbe()
	{
		if (rhi == nullptr) return;
		// 🚩 **`-mlgen` — 생성 단계로 직행한다.**
		//   ⚠️⚠️ **왜 필요한가**(우회가 아니라 계측 기반이다):
		//     ㉠ 재려는 것이 체인 **맨 끝**(D2-b 생성)인데 앞 단계 전부를 돌면 **50분**이다
		//       ⇒ 손잡이 하나 바꿔 다시 재는 일이 사실상 불가능하다(반복 없는 실험은 실험이 아니다).
		//     ㉡ 그리고 지금 **P3-b 의 간헐 APPCRASH** 가 그 뒤 단계의 측정을 **인질로** 잡고 있다
		//       (오늘만 3회 · `ucrtbase` 0xc0000005 · 같은 버킷).
		//   ★ 그리고 **이것 자체가 크래시 진단**이다: 건너뛰면 아레나 일곱 개가 **공존하지 않는다**
		//     ⇒ 여기서 안 죽으면 원인이 **앞쪽의 자원 압박/힙 훼손** 쪽이라는 단서가 된다.
		//   ⚠️ 안전한 근거: `_SetupGen` 은 **자립적**이다 — 자기 코퍼스를 만들고 자기 아레나(`_gn`)를
		//     `rhi` 만으로 잡는다(앞 단계의 산출을 하나도 안 읽는다). 그래서 건너뛰어도 뜻이 안 바뀐다.
		//   ⚠️ **기본은 전체 체인이다** — 플래그를 줄 때만 건너뛴다(측정 기록에 그것을 남긴다).
		if (OS::CommandLine::Has("-mlgen")) { _TickGen(); return; }
		// 🌱 **`-mllife` — 생명주기 실험으로 직행한다**(`-mlgen` 과 같은 이유 · `mllife.cw`).
		//   ⚠️ 이 실험은 **가중치를 아예 안 쓴다**(기억·가설·시험·정리만) ⇒ 앞 체인과 완전히 독립이다.
		if (OS::CommandLine::Has("-mllife")) { _TickLife(); return; }
		// 🔀 **`-mldiff` — 차분 짝지음 실험**(`mldiff.cw`). D3 의 반성에서 나왔다(함정 115·118):
		//   생명주기는 **심볼 표를 손으로 준 것** 위에서 돌았다 ⇒ 심볼이 **차분에서 생기나**를 먼저 묻는다.
		if (OS::CommandLine::Has("-mldiff")) { MLDiff::Run(); return; }
		// 🪞 **`-mlt` — 트랜스포머 트랙**(`Sources/MLT/`). 기계를 바꾼 자매 트랙이다:
		//   셈 표와 선형 합이 못 담은 셋(**심볼을 놓을 자리 · 비교 · 끄기**)이 이 트랙의 존재 이유이고,
		//   그 판정은 이 저장소가 이미 실측으로 내놨다 — *"조건화되는 기계는 취향이 아니라 요구다"*.
		//   ⚠️ 정본은 `Projects/ML/MLT.md`(단계·관문) · `mltconcept.md`(원리·경계)다.
		//   ★ `MLT::Run()` 은 자기 안에 **1회 가드**가 있다(아래 `-mlstuck` 의 그 이유 · 62MB 실측).
		//   ⚠️⚠️ **`-mlt` 는 이 함수에 없다** — 이 함수(`_TickGemmProbe`)는 `OnPreGuiRender` 에서
		//     불리고 그쪽은 `-mlt` 에서 `MLT::Tick(rhi)` 로 갈라져 **여기까지 오지 않는다.**
		//     ⇒ 트랜스포머 트랙의 CPU 판정은 `OnGuiUpdate` 에 있다(위쪽 그 줄).
		// 🍎 **`-mlstuck` — 코딩 세계의 첫 진단**(D56). 트랙을 바꿨다(→ ML.md 의 「트랙을 바꿨다」):
		//   셈 표는 **순서를 표현 못 한다**(누적이 교환법칙을 만족한다) ⇒ 목표·막힘·성공은 그 위에서
		//   원리적으로 안 된다. 새 트랙의 판정은 하나다 — ***코드가 몸이고, 목표 그림이 욕구이고,***
		//   ***목표거리의 부호가 호/불호다.*** 이 라운드는 그 세계를 **짓기 전에 재는** 것이다.
		//   ⚠️⚠️ **1회 가드가 필요하다** — 이 함수는 `OnUpdate` 라 매 프레임 돈다. 실측으로 밟았다:
		//     가드 없이 돌리니 진단이 **끝없이 반복**되어 stdout 이 **62MB** 가 됐고, 프로브의 대기
		//     조건(크기 안정)이 **원리적으로 성립하지 않아** 600초 상한까지 갔다.
		//   ★ `MLDiff::Run()` 은 자기 안에 가드가 있어서 위 줄에는 이것이 없다 — 그래서 안 보였다.
		if (OS::CommandLine::Has("-mlstuck"))
		{
			static bool sDone = false;
			if (!sDone) { sDone = true; _RunStuck(); }
			return;
		}
		// 🗣️ **`-mlval` — 호/불호 낱말의 분포**(D58). ⚠️ 1회 가드는 **함정 205** 다.
		if (OS::CommandLine::Has("-mlval"))
		{
			static bool sDoneV = false;
			if (!sDoneV) { sDoneV = true; _RunValence(); }
			return;
		}
		// 🗣️ **`-mlword` — 낱말을 학습에 붙인다**(D61). ⚠️ 1회 가드는 **함정 205** 다.
		if (OS::CommandLine::Has("-mlword"))
		{
			static bool sDoneW = false;
			if (!sDoneW) { sDoneW = true; _RunWord(); }
			return;
		}
		// 🪜 **`-mlrung` — 사다리 커버리지**(D62). ⚠️ 1회 가드는 **함정 205** 다.
		if (OS::CommandLine::Has("-mlrung"))
		{
			static bool sDoneR = false;
			if (!sDoneR) { sDoneR = true; _RunRungs(); }
			return;
		}
		// 📐 **`-mlwho` — 목표거리를 대상별로**(D65). ⚠️ 1회 가드는 **함정 205** 다.
		if (OS::CommandLine::Has("-mlwho"))
		{
			static bool sDoneH = false;
			if (!sDoneH) { sDoneH = true; _RunWho(); }
			return;
		}
		// 🎚️ **`-mlsparse` — 희소 갱신**(D92). ⚠️ 1회 가드는 **함정 205** 다.
		// 📏 **`-mlleak` — 누수를 단계로 가른다**(D128). ⚠️ 1회 가드는 **함정 205** 다.
		if (OS::CommandLine::Has("-mlleak"))
		{
			static bool sDoneLk = false;
			if (!sDoneLk) { sDoneLk = true; _RunLeak(); }
			return;
		}
		// 🔗 **`-mlbind` — 묶임(binding)**(D137) · **`-mlsame` — 같은 색 방해자 둘**(D153).
		//   ★ 라운드를 **세계별로 가른다**(D153) — 팔 표의 `kBRnd` 비트가 그 팔이 도는 라운드다.
		//   ⚠️ 1회 가드는 **함정 205** 다.
		if (OS::CommandLine::Has("-mlbind") || OS::CommandLine::Has("-mlsame"))
		{
			static bool sDoneBd = false;
			if (!sDoneBd) { sDoneBd = true; _RunBind(OS::CommandLine::Has("-mlsame") ? 2 : 1); }
			return;
		}
		if (OS::CommandLine::Has("-mlsparse"))
		{
			static bool sDoneG2 = false;
			if (!sDoneG2) { sDoneG2 = true; _RunSparse(); }
			return;
		}
		// 🧠 **`-mllearn` — 고리 위에 학습을 얹는다**(D76). ⚠️ 1회 가드는 **함정 205** 다.
		if (OS::CommandLine::Has("-mllearn"))
		{
			static bool sDoneL = false;
			if (!sDoneL) { sDoneL = true; _RunLearn(); }
			return;
		}
		// 🔗 **`-mlanchor` — 낱말이 앵커로 쓰이나**(D72). ⚠️ 1회 가드는 **함정 205** 다.
		if (OS::CommandLine::Has("-mlanchor"))
		{
			static bool sDoneK = false;
			if (!sDoneK) { sDoneK = true; _RunAnchor(); }
			return;
		}
		// 🖐️ **`-mlact` — 모델이 행동한다**(D66). ⚠️ 1회 가드는 **함정 205** 다.
		if (OS::CommandLine::Has("-mlact"))
		{
			static bool sDoneA = false;
			if (!sDoneA) { sDoneA = true; _RunAct(); }
			return;
		}
		// ⚠️ **여기서 `_gStage >= 2` 로 조기 반환하면 안 된다** — 그러면 검산이 끝난 뒤의 학습 루프에
		//   영영 못 닿는다(실측으로 밟았다: "학습 시작" 만 찍히고 스텝이 하나도 안 돌았다).
		//   ★ 단계가 하나 늘 때 맨 위 가드를 같이 고치는 것을 잊는 것이 이 모양의 함정이다.
		if (_gStage >= 2)
		{
			// ⚠️ **단계를 붙일 때 이 분기를 같이 고쳐야 한다** — 앞서 학습 루프를 못 닿게 만든 그 함정이다.
			if (_trainStage < 2) { _TickTraining(); return; }
			if (_eStage < 2)      { _TickEmbed();    return; }
			if (_lmStage < 3)     { _TickLM();       return; }
			if (_vStage < 5)      { _TickVision();   return; }
			if (_bStage < 5)      { _TickBoundary(); return; }
			if (_cStage < 4)      { _TickCodec();    return; }
			if (_mStage < 1)      { _TickMdl();      return; }
			if (_pbStage < 4)     { _TickBeta();     return; }
			if (_hStage < 4)      { _TickHead();     return; }
			if (_xStage < 4)      { _TickCross();    return; }
			if (_gnStage < 3)     { _TickGen();      return; }
			_TickLife();
			return;
		}

		if (_gStage == 0)
		{
			_gStage = 1;   // ★ 성공이든 실패든 한 번만 시도한다
			if (!_SetupP1()) { _gStage = 2; return; }
			if (!_DispatchStep()) { _gStage = 2; return; }
			return;   // ⚠️ **여기서 반환** — 회수는 다음 프레임이다(G′)
		}

		if (_gStage == 1)
		{
			_gStage = 2;
			_Judge();
			// ★ 그래디언트가 맞다는 것을 확인한 **뒤에** 학습을 시작한다 — 순서가 뜻이 있다:
			//   기울기가 틀린 채로 학습시키면 "손실이 안 내려간다" 를 옵티마이저 탓으로 오진한다.
			_trainStage = 1;
			_StartTraining();
			return;
		}
	}

	// ── ⚙️ 학습 — 파이프라인이라 프레임마다 "읽고 → 디스패치" 다 ───────────────────────
	void _StartTraining()
	{
		// ★ 옵티마이저 상태를 0 으로 시작한다(아레나가 0 으로 채워져 있으므로 할 일이 없다).
		//   CPU 레퍼런스도 **같은 초기값**에서 출발해야 비교가 성립한다.
		Array<float> a, b, t;
		_FillInputs(a, b, t);
		_cpuB.Reset(kGK * kGN);
		_cpuM.Reset(kGK * kGN);
		_cpuV.Reset(kGK * kGN);
		for (uint32 i = 0; i < kGK * kGN; ++i)
		{
			_cpuB.Data()[i] = b.Data()[i];
			_cpuM.Data()[i] = 0.0f;
			_cpuV.Data()[i] = 0.0f;
		}
		// ⚠️ GPU 의 B 도 **초기값으로 되돌린다** — 위 gradcheck 단계에서 갱신은 안 했지만, 학습의 시작이
		//   레퍼런스와 같은 자리임을 코드로 못 박아 둔다(암묵 가정을 남기지 않는다).
		_arena.Write(_tB, b);
		_step = 0;
		LogA("[ml] 학습 시작 — %d스텝 · lr=%.2g · AdamW(b1=%.2g b2=%.4g wd=%.2g)\n",
			kSteps, (double)kLr, (double)kB1, (double)kB2, (double)kWd);
	}

	void _TickTraining()
	{
		if (_trainStage != 1) return;

		// ① **지난 스텝의 결과를 먼저 읽는다** — 이번 프레임 디스패치는 아직 제출되지 않았으므로
		//   여기서 보이는 것은 **직전 스텝**의 dC 다(G′). 그것으로 손실을 적는다.
		if (_step > 0)
		{
			Bytes bDC;
			if (_arena.Read(_tDC, bDC) && bDC.GetSize() == (uint64)(kGM * kGN) * sizeof(float))
			{
				const float* d = (const float*)bDC.GetData();
				float loss = 0.0f;
				for (uint32 i = 0; i < kGM * kGN; ++i) loss += 0.5f * d[i] * d[i];
				if (_step == 1) _loss0 = loss;
				// ⚠️ 매 스텝 찍으면 로그를 먹는다 — 처음/끝과 10스텝마다만(→ Docs/Guide.md 의 로그 원칙).
				if (_step == 1 || _step == kSteps || (_step % 10) == 0)
					LogA("[ml] step %3d  loss %.6f\n", _step - 1, (double)loss);
			}
		}

		if (_step >= kSteps) { _trainStage = 2; _JudgeTraining(); return; }   // ★ 다음 프레임부터 _TickEmbed

		// ② 이번 스텝을 디스패치한다(forward → dC → dB → AdamW). 네 커널이 한 프레임에 들어간다.
		if (!_DispatchTrainStep()) { _trainStage = 2; return; }

		// ③ CPU 레퍼런스도 **같은 한 스텝**을 돈다(같은 입력·같은 식).
		_CpuTrainStep();
		_step++;
	}

	bool _DispatchTrainStep()
	{
		MLGemmParams g;
		g.aOff = _tA.offset; g.bOff = _tB.offset; g.cOff = _tC.offset;
		g.M = kGM; g.N = kGN; g.K = kGK;
		if (!_kGemm.Dispatch(kGN, kGM, 1u, &g, (uint32)sizeof(g))) return _Fail("train forward");

		MLSubParams s;
		s.aOff = _tC.offset; s.bOff = _tT.offset; s.outOff = _tDC.offset; s.count = _tC.Count();
		if (!_kSub.Dispatch(s.count, 1u, 1u, &s, (uint32)sizeof(s))) return _Fail("train sub");

		MLGemmParams gb;
		gb.aOff = _tA.offset; gb.bOff = _tDC.offset; gb.cOff = _tDB.offset;
		gb.M = kGK; gb.N = kGN; gb.K = kGM; gb.transA = 1;
		if (!_kGemm.Dispatch(gb.N, gb.M, 1u, &gb, (uint32)sizeof(gb))) return _Fail("train backward");

		MLAdamWParams ap;
		ap.pOff = _tB.offset; ap.gOff = _tDB.offset; ap.mOff = _tM.offset; ap.vOff = _tV.offset;
		ap.count = _tB.Count();
		ap.lr = kLr; ap.beta1 = kB1; ap.beta2 = kB2; ap.eps = kAdamEps; ap.wd = kWd;
		_BiasCorr(_step + 1, ap.bc1, ap.bc2);
		if (!_kAdam.Dispatch(ap.count, 1u, 1u, &ap, (uint32)sizeof(ap))) return _Fail("adamw");
		return true;
	}

	// 편향보정 — `1/(1−βᵗ)`. ★ 호스트가 계산해 넘기므로 셰이더는 `t` 를 모른다(같은 사실이 한 곳에만).
	void _BiasCorr(int t, float& bc1, float& bc2) const
	{
		bc1 = 1.0f / (1.0f - Pow(kB1, (float)t));
		bc2 = 1.0f / (1.0f - Pow(kB2, (float)t));
	}

	void _CpuTrainStep()
	{
		Array<float> a, b0, t;
		_FillInputs(a, b0, t);
		Array<float> c, dc, db;
		c.Reset(kGM * kGN);
		MLGemmCpuT(a.Data(), _cpuB.Data(), c.Data(), kGM, kGN, kGK, false, false);
		dc.Reset(kGM * kGN);
		MLSubCpu(c.Data(), t.Data(), dc.Data(), kGM * kGN);   // ➖ 레퍼런스로(인라인 for 문 아니다)
		db.Reset(kGK * kGN);
		MLGemmCpuT(a.Data(), dc.Data(), db.Data(), kGK, kGN, kGM, true, false);
		float bc1 = 1.0f, bc2 = 1.0f;
		_BiasCorr(_step + 1, bc1, bc2);
		MLAdamWCpu(_cpuB.Data(), db.Data(), _cpuM.Data(), _cpuV.Data(), kGK * kGN,
			kLr, kB1, kB2, kAdamEps, kWd, bc1, bc2);
	}

	void _JudgeTraining()
	{
		Bytes bB, bDC;
		if (!_arena.Read(_tB, bB) || !_arena.Read(_tDC, bDC))
		{
			LogA("[ml] P1 학습 판정: ★실패★ — 회수가 안 됐다\n");
			return;
		}
		const float* d = (const float*)bDC.GetData();
		float lossN = 0.0f;
		for (uint32 i = 0; i < kGM * kGN; ++i) lossN += 0.5f * d[i] * d[i];

		// ★ **판정 둘 — 그리고 뒤쪽이 본 판정이다.**
		//   ㉠ 손실이 내려갔나 = 학습이 **돌긴 하나**(약한 검사 — 옵티마이저가 틀려도 내려간다)
		//   ㉡ **CPU 레퍼런스와 파라미터가 같나** = AdamW 가 **정확히 그 식인가**(강한 검사)
		const float errB = MLMaxRelErr((const float*)bB.GetData(), _cpuB.Data(), kGK * kGN);
		const bool down = (lossN < _loss0 * 0.5f);
		const bool same = (errB < 1.0e-4f);
		LogA("[ml] P1 학습 판정: 손실 %.6f -> %.6f (%s) · CPU 레퍼런스 대비 파라미터 %.3e (%s)\n",
			(double)_loss0, (double)lossN, down ? "내려갔다" : "★안 내려갔다★",
			(double)errB, same ? "일치" : "★불일치★");
		if (!same)
			LogA("[ml]   ⚠️ 볼 곳: ① 감쇠를 기울기에 섞었나(그건 Adam+L2 다) ② 편향보정 t 가 1부터인가"
				" ③ m/v 오프셋이 겹쳤나\n");
	}

	// ① forward → ② dC = C − T → ③ dB = Aᵀ·dC → ④ 수치 기울기. 네 디스패치가 한 프레임에 들어간다.
	bool _DispatchStep()
	{
		// ① C = A·B
		MLGemmParams g;
		g.aOff = _tA.offset; g.bOff = _tB.offset; g.cOff = _tC.offset;
		g.M = kGM; g.N = kGN; g.K = kGK;
		if (!_kGemm.Dispatch(kGN, kGM, 1u, &g, (uint32)sizeof(g))) return _Fail("forward gemm");

		// ② dC = C − T (원소별 — 길이만 안다)
		MLSubParams s;
		s.aOff = _tC.offset; s.bOff = _tT.offset; s.outOff = _tDC.offset; s.count = _tC.Count();
		if (!_kSub.Dispatch(s.count, 1u, 1u, &s, (uint32)sizeof(s))) return _Fail("sub");

		// ③ dB = Aᵀ · dC — ⚠️ **논리 크기가 바뀐다**: 결과가 K×N 이므로 M←K, N←N, K←M 이다.
		//   ★ 그리고 A 는 M×K 로 저장돼 있는데 Aᵀ 로 쓰고 싶으므로 `transA = 1` 이다(저장 모양을 말한다).
		MLGemmParams gb;
		gb.aOff = _tA.offset; gb.bOff = _tDC.offset; gb.cOff = _tDB.offset;
		gb.M = kGK; gb.N = kGN; gb.K = kGM;
		gb.transA = 1;
		if (!_kGemm.Dispatch(gb.N, gb.M, 1u, &gb, (uint32)sizeof(gb))) return _Fail("backward gemm");

		// ④ 수치 기울기 — 스레드 하나가 B 의 파라미터 하나를 맡는다(한 디스패치로 전부).
		MLGradCheckParams gc;
		gc.aOff = _tA.offset; gc.bOff = _tB.offset; gc.tOff = _tT.offset; gc.outOff = _tNum.offset;
		gc.M = kGM; gc.N = kGN; gc.K = kGK; gc.eps = kEps;
		if (!_kGrad.Dispatch(kGK * kGN, 1u, 1u, &gc, (uint32)sizeof(gc))) return _Fail("gradcheck");

		LogA("[ml] P1 스텝 디스패치 — C=(%ux%u) dB=(%ux%u) 파라미터 %u개, eps=%.0e\n",
			kGM, kGN, kGK, kGN, kGK * kGN, (double)kEps);
		return true;
	}

	bool _Fail(const char* what)
	{
		LogA("[ml] P1: '%s' 디스패치 실패\n", what);
		return false;
	}

	// 🧪 **음성 대조 — 이 시험이 「틀린 것을 잡을 수 있나」.**
	//   ★ **여태 판정부는 「오차가 문턱 아래다」만 찍었다.** 그런데 그 줄은 **문턱이 무엇이든**
	//     **참일 수 있다** — 문턱이 느슨하거나 지표가 칸을 평균으로 접으면 **틀린 커널도 같은 줄을**
	//     **찍는다.** ⇒ 그것이 이 저장소의 규율 13(*원리적으로 못 틀리는 시험은 판정에서 뺀다*)의
	//     **짝**이고, 여태 그 짝이 없었다. ⇒ 일부러 틀린 것을 넣어 **반드시 잡히는지** 본다.
	//   세 주입은 이 저장소가 **실제로 밟은** 실패 모양이다:
	//     ㉠ **부호 뒤집기** — `dC = T − C` 로 짠 실수(입력을 부호 섞어 둔 이유가 그것이다)
	//     ㉡ **색인 뒤집기** — 색인이 밀리는 모드(**크래시 없이 조용히 틀린다**)
	//     ㉢ **한 칸만 문턱의 3배** — 지표가 **칸 단위**인가(평균으로 접히면 한 칸은 안 잡힌다)
	//   ⚠️ **이것이 재는 것은 「지표와 문턱의 분해능」이고 GPU 경로가 아니다** — 그쪽은 CPU 레퍼런스
	//     대비 오차가 본다. 둘을 섞지 않는다(함정 169 · 손잡이를 섞지 마라).
	//   ⚠️⚠️ 주입이 원본과 **비트 동일**하면(회문 · 전부 0) 그 주입은 **무효**다 ⇒ 조용히 통과시키지
	//     **않고** 판정불가로 떨어뜨린다 — 그것이 규율 13 자체다.
	bool _NegCtl(const float* want, uint32 n, float tol, const char* what)
	{
		if (want == nullptr || n == 0u) return false;
		Array<float> bad;
		bad.Reset(n);
		uint32 nOk = 0u, nVoid = 0u;
		for (int inj = 0; inj < 3; ++inj)
		{
			for (uint32 k = 0; k < n; ++k) bad.Data()[k] = want[k];
			if (inj == 0)
				for (uint32 k = 0; k < n; ++k) bad.Data()[k] = -want[k];
			else if (inj == 1)
				for (uint32 k = 0; k < n; ++k) bad.Data()[k] = want[n - 1u - k];
			else
			{
				// ★ **가장 큰 칸**을 골라 흔든다 — 0 근처 칸은 `MLMaxRelErr` 의 분모 바닥(1e-6)에 걸려
				//   엉뚱한 배율이 나온다(그 바닥의 이유는 `MLMaxAbsErr` 의 ★ 주석에 있다).
				uint32 j = 0u; float best = 0.0f;
				for (uint32 k = 0; k < n; ++k)
				{
					const float m = (want[k] < 0.0f) ? -want[k] : want[k];
					if (m > best) { best = m; j = k; }
				}
				bad.Data()[j] = want[j] * (1.0f + 3.0f * tol);
			}
			bool same = true;
			for (uint32 k = 0; k < n; ++k) if (bad.Data()[k] != want[k]) { same = false; break; }
			if (same)
			{
				++nVoid;
				LogA("[ml]   ⚠️ 음성 대조 %s · 주입 %d 이 **비트 동일** = 무효다(이 주입은 틀릴 수 없다)\n",
					what, inj);
				continue;
			}
			const float e = MLMaxRelErr(bad.Data(), want, n);
			if (e > tol) ++nOk;
			else
				LogA("[ml]   ⚠️⚠️ 음성 대조 %s · 주입 %d 이 **안 잡혔다** — %.3e ≤ 문턱 %.3e\n",
					what, inj, (double)e, (double)tol);
		}
		LogA("[ml] 음성 대조 %s(문턱 %.0e): 잡은 주입 %u/3 · 무효 %u — %s\n",
			what, (double)tol, nOk, nVoid,
			(nOk == 3u) ? "시험이 있다" : "⛔ 이 시험은 틀린 것을 못 잡는다");
		return (nOk == 3u);
	}
	
	void _Judge()
	{
		Bytes bDC, bDB, bNum;
		if (!_arena.Read(_tDC, bDC) || !_arena.Read(_tDB, bDB) || !_arena.Read(_tNum, bNum))
		{
			LogA("[ml] P1 판정: ★실패★ — 회수가 안 됐다\n");
			return;
		}

		// 🧮 CPU 레퍼런스로 같은 사슬을 다시 계산한다(같은 입력·같은 순서).
		Array<float> a, b, t, c, dc, db;
		_FillInputs(a, b, t);
		c.Reset(kGM * kGN);
		MLGemmCpuT(a.Data(), b.Data(), c.Data(), kGM, kGN, kGK, false, false);
		dc.Reset(kGM * kGN);
		MLSubCpu(c.Data(), t.Data(), dc.Data(), kGM * kGN);   // ➖ 레퍼런스로(인라인 for 문 아니다)
		db.Reset(kGK * kGN);
		MLGemmCpuT(a.Data(), dc.Data(), db.Data(), kGK, kGN, kGM, true, false);

		const float eDC = MLMaxRelErr((const float*)bDC.GetData(), dc.Data(), kGM * kGN);
		const float eDB = MLMaxRelErr((const float*)bDB.GetData(), db.Data(), kGK * kGN);
		// ★ **이것이 P1 의 본 판정**이다 — 해석적 기울기 vs **수치 기울기**(중앙차분).
		//   ⚠️ 여기만 관대하다(1e-4 대신 2e-2): 중앙차분 자체가 `O(ε²)` 오차를 갖고 float32 에서 상쇄가
		//     섞이므로, 이 숫자는 "backward 식이 맞나" 를 보는 것이고 커널 정확도를 보는 것이 아니다.
		//     ★ 커널 정확도는 위 `eDC`/`eDB`(CPU 레퍼런스 대비)가 본다 — **두 판정이 다른 것을 잰다**.
		const float eNum = MLMaxRelErr((const float*)bNum.GetData(), db.Data(), kGK * kGN);

		// 🧪 **음성 대조를 관문으로 건다** — 시험이 「틀린 것을 못 잡는다」면 그 문턱은 판정을 못 한다.
		//   ⚠️ 문턱을 **그 판정과 같은 것**으로 넣는다(다른 문턱을 시험하면 아무것도 보장하지 않는다).
		//   ⚠️ `&&` 가 아니라 `&` 다 — 단단락되면 둘째 줄이 **안 찍힌다**(진단이 반쪽이 된다).
		const bool negK = _NegCtl(dc.Data(), kGM * kGN, 1.0e-5f, "dC")
			& _NegCtl(db.Data(), kGK * kGN, 1.0e-5f, "dB");
		const bool negG = _NegCtl(db.Data(), kGK * kGN, 2.0e-2f, "수치");
		const bool passK = (eDC < 1.0e-5f) && (eDB < 1.0e-5f);
		const bool passG = (eNum < 2.0e-2f);
		LogA("[ml] P1 커널 판정: %s — dC %.3e · dB %.3e (CPU 레퍼런스 대비)\n",
			negK ? (passK ? "통과" : "★실패★") : "⚠️ 판정불가 — 음성 대조가 안 잡혔다", (double)eDC, (double)eDB);
		LogA("[ml] P1 그래디언트 판정: %s — 수치 vs 해석 %.3e (중앙차분, eps=%.0e)\n",
			negG ? (passG ? "통과" : "★실패★") : "⚠️ 판정불가 — 음성 대조가 안 잡혔다", (double)eNum, (double)kEps);
		if (!passG)
			LogA("[ml]   ⚠️ 볼 곳: ① `dB = Aᵀ·dC` 의 M/N/K 가 바뀐 것을 반영했나 ② transA 가 '저장 모양' 인가"
				" ③ eps 가 너무 작아 상쇄됐나\n");
	}

	// 🎲 입력을 **결정적으로** 만든다 — 같은 값을 CPU 레퍼런스도 써야 비교가 성립한다.
	//   ★ 부호가 섞이게 둔다(전부 양수면 부호 실수가 안 잡힌다).
	void _FillInputs(Array<float>& a, Array<float>& b, Array<float>& t)
	{
		a.Reset(kGM * kGK);
		b.Reset(kGK * kGN);
		t.Reset(kGM * kGN);
		for (uint32 i = 0; i < kGM * kGK; ++i) a.Data()[i] = ((float)(i % 7) - 3.0f) * 0.25f + 0.125f;
		for (uint32 i = 0; i < kGK * kGN; ++i) b.Data()[i] = ((float)(i % 5) - 2.0f) * 0.5f - 0.0625f;
		for (uint32 i = 0; i < kGM * kGN; ++i) t.Data()[i] = ((float)(i % 3) - 1.0f) * 0.75f;
	}

	bool _LoadKernel(MLKernel& k, const char* path)
	{
		Bytes spv;
		if (!PlatformFile::LoadBytes(path, spv, PlatformFileSource::Package) || spv.GetSize() == 0)
		{
			LogA("[ml] P1: %s 를 못 읽었다(쿡 확인)\n", path);
			return false;
		}
		if (!k.Create(rhi, spv.GetData(), spv.GetSize(), _arena))
		{
			LogA("[ml] P1: %s 커널 생성 실패\n", path);
			return false;
		}
		return true;
	}

	bool _SetupP1()
	{
		// ★ 아레나 하나에 텐서 일곱이 다 산다 — 위치는 push constants 의 오프셋이 말한다.
		// ★ 아레나 하나에 P1 텐서와 임베딩 텐서가 **같이** 산다(오프셋으로 갈린다).
		const uint32 need = kGM * kGK + kGM * kGN * 3u + kGK * kGN * 5u
			+ kSeq + kVocab * kDim * 2u + kSeq * kDim * 2u;
		if (!_arena.Create(rhi, need)) { LogA("[ml] P1: 아레나 생성 실패\n"); return false; }

		_tA   = _arena.Alloc(kGM, kGK);   // 입력
		_tB   = _arena.Alloc(kGK, kGN);   // 파라미터(이것의 기울기를 검산한다)
		_tT   = _arena.Alloc(kGM, kGN);   // 정답
		_tC   = _arena.Alloc(kGM, kGN);   // forward 결과
		_tDC  = _arena.Alloc(kGM, kGN);   // dL/dC
		_tDB  = _arena.Alloc(kGK, kGN);   // dL/dB (해석적)
		_tNum = _arena.Alloc(kGK, kGN);   // dL/dB (수치)
		_tM   = _arena.Alloc(kGK, kGN);   // AdamW 1차 모멘트
		_tV   = _arena.Alloc(kGK, kGN);   // AdamW 2차 모멘트
		if (!_tV.IsValid()) { LogA("[ml] P1: 텐서 할당 실패\n"); return false; }

		Array<float> a, b, t;
		_FillInputs(a, b, t);
		if (!_arena.Write(_tA, a) || !_arena.Write(_tB, b) || !_arena.Write(_tT, t))
		{
			LogA("[ml] P1: 입력 업로드 실패\n");
			return false;
		}

		// ★ 커널마다 아레나를 **한 번** 바인딩한다(아레나 규약 ㉡ — 그 뒤로 `Update` 를 다시 안 부른다).
		if (!_LoadKernel(_kGemm, "shaders/gemm.cs.spv"))      return false;
		if (!_LoadKernel(_kSub,  "shaders/sub.cs.spv"))       return false;
		if (!_LoadKernel(_kGrad, "shaders/gradcheck.cs.spv")) return false;
		if (!_LoadKernel(_kAdam, "shaders/adamw.cs.spv"))     return false;

		// 🔢 **C 가드는 값싸니 남긴다** — 조용한 성공(2GB 오버플로)을 막는 자리라 회귀가 무섭다.
		{
			MLArena huge;
			if (!huge.Create(rhi, 1500000000u))   // × 4바이트 = 60억 바이트
				LogA("[ml] 아레나 상한 가드: 통과 — 60억 바이트 요청이 거절됐다\n");
			else
				LogA("[ml] 아레나 상한 가드: ★실패★ — 거절되지 않았다\n");
		}
		return true;
	}










	// ── 🌫️ **흐림 판정** — *"이거 같은데 아직은 잘 모르겠네"* 가 쓸모가 되나 ──────────────────
	//
	// ★ **판정 셋이 서로 다른 것을 묻는다.**
	//   ㉠ **흐림이 내용어와 기능어를 가르나** — 문턱이 전혀 안 들어간다(AUC).
	//      ★ 이것이 *"흐림이 뜻이 있나"* 의 판정이다. 정답 라벨은 **낱말 단위**(생성기가 낸다).
	//   ㉡ **흐림을 쓰면 경계 정밀도가 오르나** — 재현율 1.0 을 지키면서 걸러낼 수 있나.
	//      ⚠️ 문턱을 스윕한 **곡선**으로 보고한다(최대 F1 만 보고하면 문턱을 결과에 맞춘 것이다).
	//   ㉢ **`위` 의 선택 흐림이 높나** — 진짜 중의성(자리 vs 방향)을 흐림이 잡나.
	void _JudgeFuzz(const Array<int>& pointAx, const Array<float>& fuzzAmt,
		const Array<float>& fuzzSel)
	{
		// 후보(음절 경계) — ⚠️ 판정과 **같은 규칙**으로 여기서 만든다.
		Array<uint32> cand;
		for (uint32 t = 0; t + 1u < (uint32)_xEvTok.Count(); ++t)
			if (_IsLead((uint8)_xEvTok.Data()[t + 1u])) cand.Add(t);
		// ── ㉠ AUC — 내용어(축을 말한다) vs 기능어 ──
		//   ⚠️ 종결 부호가 붙은 음절과 라벨이 없는 자리는 **뺀다**(라벨이 오염된 자리다).
		Array<float> posF, negF;   // 내용어의 흐림 / 기능어의 흐림
		for (uint32 c = 0; c < _xEvSpans; ++c)
		{
			const uint32 s0 = (uint32)_xEvS.Data()[c];
			if (s0 >= (uint32)_xEvWordAx.Count()) continue;
			const uint8 b0 = (uint8)_xEvTok.Data()[s0];
			if (b0 == (uint8)'.' || b0 == (uint8)'!') continue;   // 종결 부호 자리는 뺀다
			const int wa = _xEvWordAx.Data()[s0];
			if (wa == -1)      negF.Add(fuzzAmt.Data()[c]);       // 기능어
			else if (wa >= 0)  posF.Add(fuzzAmt.Data()[c]);       // 축을 말하는 내용어
			// ⚠️ `-2`(존재를 말한다)는 **양쪽 다 아니다** — 지금 데이터에 존재 축이 없어서
			//   접지가 원리적으로 약하다(함정 25 의 그 자리) ⇒ 판정에서 뺀다.
		}
		float auc = 0.0f;
		if (posF.Count() > 0u && negF.Count() > 0u)
		{
			// ★ AUC = **기능어가 내용어보다 흐릴 확률**. 쌍을 다 세는 정직한 계산(표본이 수백이라 값싸다).
			uint64 win = 0, tie = 0, tot = 0;
			for (uint32 i = 0; i < (uint32)posF.Count(); ++i)
				for (uint32 j = 0; j < (uint32)negF.Count(); ++j)
				{
					tot++;
					if (negF.Data()[j] > posF.Data()[i]) win++;
					else if (negF.Data()[j] == posF.Data()[i]) tie++;
				}
			auc = (tot > 0ull) ? ((float)win + 0.5f * (float)tie) / (float)tot : 0.0f;
		}
		float mPos = 0.0f, mNeg = 0.0f;
		for (uint32 i = 0; i < (uint32)posF.Count(); ++i) mPos += posF.Data()[i];
		for (uint32 i = 0; i < (uint32)negF.Count(); ++i) mNeg += negF.Data()[i];
		if (posF.Count() > 0u) mPos /= (float)posF.Count();
		if (negF.Count() > 0u) mNeg /= (float)negF.Count();

		LogA("\n[ml] 🌫️ **흐림 판정** — *\"이거 같은데 아직은 잘 모르겠네\"* 가 쓸모가 되나\n"
			"[ml]   ㉠ 내용어 %u개 흐림 평균 **%.3f** · 기능어 %u개 흐림 평균 **%.3f** · **AUC %.4f**\n"
			"[ml]      ★ AUC = *기능어가 내용어보다 흐릴 확률*. 0.5 = 못 가른다 · 1.0 = 완벽히 가른다.\n"
			"[ml]      ⚠️ 문턱이 **하나도** 안 들어간다 — 그래서 이것이 흐림 자체의 판정이다.\n",
			(uint32)posF.Count(), (double)mPos, (uint32)negF.Count(), (double)mNeg, (double)auc);

		// ── ㉡ 흐림으로 경계를 걸러낸다 — 문턱 스윕 곡선 ──
		//   ★ 규칙: 축이 바뀌어도 **뒤 음절이 흐리면 새 단위를 시작하지 못한다**(머리가 될 수 없다).
		//     지금은 `없음 → 앞에 붙임` 이라는 **이진 규칙**인데, 이것의 **연속판**이다.
		LogA("[ml]   ㉡ 흐림으로 걸러낸다(축이 바뀌어도 **흐린 음절은 머리가 못 된다**) — 문턱 스윕:\n"
			"[ml]      %-8s %9s %9s %9s\n", "흐림<", "정밀도", "재현율", "F1");
		const float taus[6] = { 1.01f, 0.9f, 0.8f, 0.7f, 0.6f, 0.5f };
		float bestF1 = 0.0f; float bestTau = 0.0f;
		for (uint32 t = 0; t < 6u; ++t)
		{
			Array<uint8> m;
			m.Reset(_xEvTok.Count());
			for (uint32 i = 0; i < (uint32)m.Count(); ++i) m.Data()[i] = 0u;
			int cur = -1;
			for (uint32 c = 0; c < _xEvSpans; ++c)
			{
				const int a = pointAx.Data()[c];
				const bool clear = (fuzzAmt.Data()[c] < taus[t]);
				if (a >= 0 && clear && cur >= 0 && a != cur)
				{
					const uint32 prevEnd = (uint32)_xEvS.Data()[c] - 1u;
					if (prevEnd < (uint32)m.Count()) m.Data()[prevEnd] = 1u;
				}
				if (a >= 0 && clear) cur = a;
			}
			// 캡션 끝은 늘 경계다(채널과 무관한 사실).
			for (uint32 i = 0; i + 1u < (uint32)_xEvCap.Count(); ++i)
				if (_xEvCap.Data()[i] != _xEvCap.Data()[i + 1u]) m.Data()[i] = 1u;
			if (m.Count() > 0) m.Data()[m.Count() - 1] = 1u;

			uint32 tp = 0, pd = 0, gt = 0;
			for (uint32 i = 0; i < (uint32)cand.Count(); ++i)
			{
				const uint32 pos = cand.Data()[i];
				const bool pp = (m.Data()[pos] != 0u), gg = (_xEvBnd.Data()[pos] != 0u);
				if (pp) pd++; if (gg) gt++; if (pp && gg) tp++;
			}
			const float pr2 = (pd > 0u) ? ((float)tp / (float)pd) : 0.0f;
			const float rc2 = (gt > 0u) ? ((float)tp / (float)gt) : 0.0f;
			const float f12 = ((pr2 + rc2) > 0.0f) ? (2.0f * pr2 * rc2 / (pr2 + rc2)) : 0.0f;
			LogA("[ml]      %-8.2f %9.4f %9.4f %9.4f%s\n", (double)taus[t],
				(double)pr2, (double)rc2, (double)f12, (t == 0u) ? "  ← 흐림 안 씀(기준선)" : "");
			if (f12 > bestF1) { bestF1 = f12; bestTau = taus[t]; }
		}
		LogA("[ml]      ⚠️ **최대 F1 %.4f(흐림<%.2f)은 상한이다** — 문턱을 결과에 맞춘 값이므로\n"
			"[ml]         그 자체로는 판정이 아니다. 곡선이 **기준선보다 위에 있나**가 판정이다.\n",
			(double)bestF1, (double)bestTau);

		// ── 🎯 **낱말별 흐림 — 모델이 "내가 뭘 모르는지" 를 낱말 이름으로 말한다** ──
		//   ★ 이것이 **자가 커리큘럼의 입력**이다: 흐림이 높은 낱말을 시스템이 **지목**하면
		//     생성기가 그것에 **대조를 준다**. 그리고 흐림이 내려가는지로 배움을 잰다.
		//   ⚠️ 낱말 묶기는 **정답 경계**(공백)로 한다 — 평가용 집계이므로 정답을 써도 된다
		//     (경계 판정에는 안 쓴다).
		_ShowWordFuzz(fuzzAmt);

		// ── ㉢ `위` 의 선택 흐림 ──
		//   ★ `위`·`왼쪽`·`오른쪽`·`아래` 는 **자리 낱말이자 방향 낱말**이다(일부러 같게 뒀다).
		//     ⇒ 그 음절들의 **선택 흐림**이 다른 내용어보다 높아야 한다 — 진짜 중의성이니까.
		float selAmb = 0.0f, selOther = 0.0f;
		uint32 nAmb = 0, nOther = 0;
		for (uint32 c = 0; c < _xEvSpans; ++c)
		{
			const uint32 s0 = (uint32)_xEvS.Data()[c];
			if (s0 >= (uint32)_xEvWordAx.Count()) continue;
			const int wa = _xEvWordAx.Data()[s0];
			if (wa < 0) continue;                     // 내용어만 본다
			if (wa == 4 || wa == 7) { selAmb += fuzzSel.Data()[c]; nAmb++; }   // 자리 · 방향
			else                    { selOther += fuzzSel.Data()[c]; nOther++; }
		}
		if (nAmb > 0u) selAmb /= (float)nAmb;
		if (nOther > 0u) selOther /= (float)nOther;
		LogA("[ml]   ㉢ **선택의 흐림** — 자리·방향 낱말(중의적) %.3f vs 나머지 내용어 %.3f\n"
			"[ml]      ★ `위`·`왼쪽` 은 **자리 낱말이자 방향 낱말**이다(일부러 같게 뒀다) ⇒ 선택이 흐려야 맞다.\n"
			"[ml]      ⚠️ 그것은 **틀린 게 아니라 진짜 중의성**이고, argmax 로 하나를 고르면 **숨겨진다**.\n",
			(double)selAmb, (double)selOther);

		// ★ **기준은 측정 전에 정했다.**
		//   ㉠ AUC > 0.65 — 흐림이 내용어/기능어를 **가른다**(0.5 = 못 가른다)
		//   ㉡ 흐림 곡선의 최대 F1 이 **기준선(흐림 안 씀)보다 높다**
		//   ㉢ 자리·방향의 선택 흐림이 나머지보다 **높다**
		const bool okAuc = (auc > 0.65f);
		const bool okAmb = (selAmb > selOther);
		LogA("[ml] 🌫️ 흐림 판정: ㉠ AUC %.4f (기준 >0.65) → %s · ㉢ 중의성 %s\n"
			"[ml]   ★ 그리고 **쓸모의 진짜 자리는 자가 커리큘럼**이다: 모델이 *\"이건 아직 모르겠어\"*\n"
			"[ml]      를 내놓으면 생성기가 **그것을 더 가르친다**. 그것이 *\"문서 1개 주면 알아서\n"
			"[ml]      자가학습\"* 의 핵이고 **자기가 무엇을 모르는지 아는 것**이 self-play 의 전제다.\n",
			(double)auc, okAuc ? "통과" : "★실패★", okAmb ? "통과" : "★실패★");
	}



	// ── 🔢 **적용 판정** — 셈낱말이 *"어느 축의 이야기인가"* 를 아나 ────────────────────────
	//
	// ★ **기능어는 값을 말하지 않는다 — 그래서 "양의 흐림" 으로는 잡히지 않는다.**
	//   `개` 는 항상 숫자 뒤에 오고 **값은 숫자가 준다**. `개` 자체는 *"몇 개인지"* 를 모르므로
	//   값 확신으로 재면 **흐릴 수밖에 없다** — 그리고 그것이 **정직한 결과**다(실측: 0.705).
	//   ⇒ 기능어가 아는 것은 ***"어느 축에 대한 이야기인가"*** 이고, `P(그 축 해당있음)` 으로 나타난다.
	//
	// ⚠️⚠️⚠️ **부호를 살려야 한다.** `개` 는 *"개수 높고 횟수 낮음"*(양수) · `번` 은 **반대**(음수)다.
	//   절댓값을 씌우면 그 구별이 사라지고, 개수 축이 늘 해당있으므로 **모든 낱말이 커 보인다**
	//   (실측: 셈낱말 0.4154 vs 나머지 0.4521 — 오히려 낮았다).
	void _JudgeApply(const Array<float>& applyGap, const Array<float>& fuzzAmt)
	{
		float gGae = 0.0f, gBeon = 0.0f, gOther = 0.0f, amtCnt = 0.0f;
		uint32 nGae = 0, nBeon = 0, nOther = 0;
		for (uint32 c = 0; c < _xEvSpans; ++c)
		{
			const uint32 s0 = (uint32)_xEvS.Data()[c], l0 = (uint32)_xEvL.Data()[c];
			if (s0 >= (uint32)_xEvWordAx.Count() || l0 < 3u) continue;
			const uint8 b0 = (uint8)_xEvTok.Data()[s0];
			const uint8 b1 = (uint8)_xEvTok.Data()[s0 + 1u], b2 = (uint8)_xEvTok.Data()[s0 + 2u];
			// `개` = EA B0 9C · `번` = EB B2 88
			const bool isGae = (b0 == 0xEAu) && (b1 == 0xB0u) && (b2 == 0x9Cu);
			const bool isBeon = (b0 == 0xEBu) && (b1 == 0xB2u) && (b2 == 0x88u);
			if (isGae)       { gGae += applyGap.Data()[c]; amtCnt += fuzzAmt.Data()[c]; nGae++; }
			else if (isBeon) { gBeon += applyGap.Data()[c]; amtCnt += fuzzAmt.Data()[c]; nBeon++; }
			else             { gOther += applyGap.Data()[c]; nOther++; }
		}
		if (nGae > 0u)  gGae /= (float)nGae;
		if (nBeon > 0u) gBeon /= (float)nBeon;
		if (nOther > 0u) gOther /= (float)nOther;
		if ((nGae + nBeon) > 0u) amtCnt /= (float)(nGae + nBeon);

		LogA("\n[ml] 🔢 **적용 판정** — 셈낱말이 *\"어느 축의 이야기인가\"* 를 아나\n"
			"[ml]   적용 변별력 `P(개수) − P(횟수)`  ★ **부호가 뜻이다**(양수 = 개수 쪽 · 음수 = 횟수 쪽)\n"
			"[ml]      `개`  %2u개  **%+.4f**   ← 양수여야 한다\n"
			"[ml]      `번`  %2u개  **%+.4f**   ← `개` 보다 작아야 한다\n"
			"[ml]      나머지 %3u개  %+.4f   (배경)\n"
			"[ml]   셈낱말의 **양의 흐림** %.3f\n",
			nGae, (double)gGae, nBeon, (double)gBeon, nOther, (double)gOther, (double)amtCnt);

		// ★ **기준은 측정 전에 정했다 — 그리고 예측을 미리 적었다.**
		//   ㉠ **`개` 의 적용값이 `번` 보다 크다** — 둘이 서로 다른 축의 셈낱말임을 안다
		//   ㉡ **셈낱말의 양의 흐림은 여전히 높다(>0.6)** — **값**은 모른다(예측대로면 확인)
		const bool okOrder = (nGae > 0u) && (nBeon > 0u) && (gGae > gBeon);
		const bool okAmt = (amtCnt > 0.6f);
		LogA("[ml] 🔢 적용 판정: ㉠ `개`(%+.4f) > `번`(%+.4f) → %s\n"
			"[ml]   ㉡ **예측 확인**: 셈낱말의 양의 흐림이 여전히 높다(%.3f > 0.6) → %s\n"
			"[ml]      ★ 두 판정이 함께 말한다: ***기능어는 \"어느 축의 이야기인가\" 를 알고\n"
			"[ml]        \"값\" 은 모른다.*** ⇒ 흐림을 **세 갈래**로 봐야 한다:\n"
			"[ml]        양(값) · 선택(어느 축) · **적용(그 축이 해당되나)**.\n",
			(double)gGae, (double)gBeon, okOrder ? "통과" : "★실패★",
			(double)amtCnt, okAmt ? "확인됐다" : "★안 맞았다★");
	}

	// 🎯 **낱말별 흐림 표.** 흐림이 높은 낱말 = *"아직 잘 모르겠는 것"* = **다음에 가르칠 것**.
	void _ShowWordFuzz(const Array<float>& fuzzAmt)
	{
		// 낱말 = 음절을 정답 경계로 묶은 것. 대표 문자열은 **바이트 범위**로 들고 있는다
		//   (⚠️ `String` 에 바이트를 하나씩 붙이면 안 된다 — 함정 22).
		Array<uint32> wStart, wLen;      // 대표 낱말의 바이트 범위
		Array<float>  wSum;              // 흐림 합
		Array<uint32> wCnt;              // 음절 수
		Array<int>    wAx;               // 그 낱말의 축(정답 라벨)

		uint32 s0 = 0, nSyl = 0;
		float acc = 0.0f;
		for (uint32 c = 0; c < _xEvSpans; ++c)
		{
			const uint32 st = (uint32)_xEvS.Data()[c], ln = (uint32)_xEvL.Data()[c];
			if (nSyl == 0u) s0 = st;
			acc += fuzzAmt.Data()[c];
			nSyl++;
			const uint32 endByte = st + ln - 1u;
			const bool isEnd = (endByte < (uint32)_xEvBnd.Count()) && (_xEvBnd.Data()[endByte] != 0u);
			if (!isEnd) continue;

			const uint32 wl = endByte + 1u - s0;
			// 같은 낱말이 이미 있나(바이트로 비교).
			int hit = -1;
			for (uint32 k = 0; k < (uint32)wStart.Count() && hit < 0; ++k)
			{
				if (wLen.Data()[k] != wl) continue;
				bool same = true;
				for (uint32 j = 0; j < wl && same; ++j)
					if (_xEvTok.Data()[s0 + j] != _xEvTok.Data()[wStart.Data()[k] + j]) same = false;
				if (same) hit = (int)k;
			}
			if (hit >= 0) { wSum.Data()[(uint32)hit] += acc; wCnt.Data()[(uint32)hit] += nSyl; }
			else
			{
				wStart.Add(s0); wLen.Add(wl); wSum.Add(acc); wCnt.Add(nSyl);
				wAx.Add((s0 < (uint32)_xEvWordAx.Count()) ? _xEvWordAx.Data()[s0] : -1);
			}
			nSyl = 0; acc = 0.0f;
		}

		// 흐림 평균 내림차순으로 상위 12개.
		const uint32 nw = (uint32)wStart.Count();
		Array<uint8> taken;
		taken.Reset(nw > 0u ? nw : 1u);
		for (uint32 i = 0; i < nw; ++i) taken.Data()[i] = 0u;
		const uint32 top = (nw < 12u) ? nw : 12u;
		LogA("[ml]   🎯 **낱말별 흐림**(높은 것 = 아직 모르는 것 = 다음에 가르칠 것) · 낱말 %u종:\n"
			"[ml]      %-12s %8s %6s %s\n", nw, "낱말", "흐림", "빈도", "축(정답)");
		for (uint32 r = 0; r < top; ++r)
		{
			int best = -1; float bestV = 0.0f;
			for (uint32 i = 0; i < nw; ++i)
			{
				if (taken.Data()[i] != 0u) continue;
				const float v = wSum.Data()[i] / (float)wCnt.Data()[i];
				if (best < 0 || v > bestV) { bestV = v; best = (int)i; }
			}
			if (best < 0) break;
			taken.Data()[(uint32)best] = 1u;

			// 낱말 문자열 — `Bytes` 로 모아 한 번에(함정 22).
			Bytes buf;
			buf.Reset((uint64)wLen.Data()[(uint32)best] + 1ull);
			uint8* q = (uint8*)buf.GetData();
			for (uint32 j = 0; j < wLen.Data()[(uint32)best]; ++j)
				q[j] = (uint8)_xEvTok.Data()[wStart.Data()[(uint32)best] + j];
			q[wLen.Data()[(uint32)best]] = 0u;

			const int a = wAx.Data()[(uint32)best];
			const char* axName = (a == -1) ? "기능어" : ((a == -2) ? "존재" : _XName((uint32)a));
			LogA("[ml]      %-12s %8.3f %6u %s\n", (const char*)q, (double)bestV,
				wCnt.Data()[(uint32)best], axName);
		}
	}

	// ── 🎞️ **이동 접지 판정** — `안간다` 는 델타가 0 이고 `간다` 는 0 이 아니다 ─────────────
	//
	// ★ **정당화 사슬을 잇는 판정이다.** 교차채널 실험은 *"축 값을 프레임의 대리로 쓴다"* 를
	//   **P2 가 "축이 픽셀에서 읽힌다" 를 재 두었으므로 정당하다**로 정당화한다.
	//   ⚠️⚠️ 그런데 **이동 축은 그것이 안 재져 있었다** — 대리를 쓰려면 먼저 *"간다/안간다가 프레임에서
	//     읽히나"* 를 재야 한다. 안 재고 쓰면 **정당화 없이 라벨을 쓰는 것**이다.
	//   ⇒ ★ 그리고 그 측정이 거의 공짜다: **델타가 이미 그 대조다.**
	//     `안간다` → `OnFrame` 을 아예 내지 않으므로 프레임이 안 바뀐다 ⇒ **델타 전부 0**
	//     `간다`   → 매 프레임 `self.ox` 가 누적되어 옮겨진다 ⇒ **델타가 0 이 아니다**
	//   ★ 이것은 **우리가 심은 신호가 아니라 코드가 낸 결과**다 — 그것이 이 프로젝트의 접지 방식이다.
	void _JudgeMotion()
	{
		const int cell = MLSense::kSize;
		const int kFrames = 6;

		// 같은 장면에서 **이동만** 바꾼다 — ★ 최소대립쌍의 시간판이다.
		MLScene stat = MLSense::BaseScene(24680u);
		stat.exists = 1; stat.moves = 0;
		MLScene move = stat;
		move.moves = 1; move.moveDir = 1;   // 오른쪽

		uint64 dStat = 0, dMove = 0;
		bool ok = true;
		for (int arm = 0; arm < 2 && ok; ++arm)
		{
			const MLScene& sc = (arm == 0) ? stat : move;
			DrawProgram prog;
			const String code = MLSense::Code(sc, false);
			if (!prog.Compile(code.View(), (uint32)cell, (uint32)cell, NameID("Motion")))
			{ LogA("[ml] 이동 판정: 컴파일 실패(%s)\n", (arm == 0) ? "안간다" : "간다"); ok = false; break; }

			ImageFormat::Bitmap prev;
			bool hasPrev = false;
			Bytes packed;
			packed.Reset((uint64)cell * (uint64)cell);
			uint64 changed = 0;
			for (int f = 0; f < kFrames && ok; ++f)
			{
				if (!((f == 0) ? prog.RunStart() : prog.RunFrame()))
				{ LogA("[ml] 이동 판정: 실행 실패(프레임 %d)\n", f); ok = false; break; }
				if (!ImageFormat::PackRGB332Delta(prog.canvas, hasPrev ? &prev : nullptr,
					(uint8*)packed.GetData(), packed.GetSize()))
				{ LogA("[ml] 이동 판정: 델타 팩 실패\n"); ok = false; break; }
				if (f > 0)
				{
					const uint8* q = (const uint8*)packed.GetData();
					for (uint64 i = 0; i < packed.GetSize(); ++i) if (q[i] != 0u) changed++;
				}
				if (!ImageFormat::CreateRGBA8(prev, (uint32)cell, (uint32)cell)) { ok = false; break; }
				ImageFormat::FitIntoRect(prog.canvas, prev, 0, 0, cell, cell, Vector4(0, 0, 0, 1));
				hasPrev = true;
			}
			if (arm == 0) dStat = changed; else dMove = changed;
		}
		if (!ok) return;

		// ★ **기준은 측정 전에 정했다.**
		//   ㉠ `안간다` 의 델타가 **정확히 0** 이다(하나라도 바뀌면 `안간다` 가 거짓이다)
		//   ㉡ `간다` 의 델타가 **0 이 아니다**(안 바뀌면 `간다` 가 거짓이다)
		//   ★ 정확히 0 을 요구할 수 있는 이유: 델타는 **332 로 깎은 값끼리** 견주므로 결정적이고,
		//     `안간다` 는 `OnFrame` 이 아예 없어 프레임이 **비트 단위로 같다**.
		const bool pass = (dStat == 0ull) && (dMove > 0ull);
		LogA("[ml] 🎞️ 이동 접지 판정: %s — `안간다` 델타 **%llu** 바이트(0 이어야 한다) · "
			"`간다` 델타 **%llu** 바이트(0 이 아니어야 한다)\n"
			"[ml]   ★ 이것이 교차채널이 이동 라벨을 **대리로 쓸 수 있는 근거**다 —\n"
			"[ml]     `간다/안간다` 가 프레임에서 읽힌다는 것을 여기서 재고 그 다음에 쓴다.\n",
			pass ? "통과" : "★실패★",
			(unsigned long long)dStat, (unsigned long long)dMove);
		if (!pass)
			LogA("[ml]   ⚠️ 볼 곳: ① `안간다` 에 `OnFrame` 이 안 나갔나 ② `self.ox` 가 **누적**되나"
				"(상수면 둘째 프레임부터 0 이다) ③ `kStep`(%d)이 RGB332 로 깎인 뒤에도 보이나\n",
				MLSense::kStep);
	}

	// ── 🔀 **P4′ · 교차채널 응집** — 경계를 **다른 채널**이 가르쳐 준다 ─────────────────────────
	//
	// ★ **1채널의 천장이 숫자로 드러났다.** 바이그램 0.4767(≈우연) → 접두사 엔트로피 0.7276 →
	//   MDL 문턱 **0.8309** → DP 0.4059(실패). **같은 채널 안에서 0.83 이 천장이었다.**
	//   ⚠️ 이유가 구조적이다: 응집의 단서가 될 것들이 **대상과 같은 알파벳**이다. `샤인머스캣은 …` 에서
	//     모든 바이트가 서로에게 단서라, *"무엇이 한 덩어리인가"* 를 가르는 **바깥의 기준이 없다.**
	//
	// ★ **그래서 기준을 다른 채널에서 가져온다.** 두 채널은 **값의 종류가 아예 다르고**
	//   서로를 침범하지 않으므로, *"이 바이트 덩어리가 프레임의 무엇을 가리키나"* 가
	//   **바이트 통계로는 얻을 수 없는 종류의 단서**다.
	//   ⇒ 판정: **음절이 가리키는 축이 바뀌는 자리**를 경계로 본다.
	//     · `붉`(색) `은`(없음→색) | `빈`(속) — 축이 바뀌므로 **경계**
	//     · `동`(모양) `그`(모양) `라`(모양) `미`(모양) — 안 바뀌므로 **한 덩어리**
	//   ★ **`없음` 은 앞에 붙인다** — 시각 내용이 없는 음절(조사)은 **새 단위를 시작할 수 없다.**
	//     그것이 조사가 하는 일과 정확히 같고, 문턱이 아니라 **규칙**이다.
	//
	// ⚠️⚠️ **바이트 통계를 하나도 쓰지 않는다** — 엔트로피도, 빈도도, MDL 도 없다. 감독은
	//   **(음절, 그 캡션이 묘사한 프레임의 축 값)** 짝뿐이고 그것은 **동시성**이다.
	// ⚠️ 축 값을 **프레임의 대리**로 쓴다 — P2 가 *"축이 픽셀에서 읽힌다"* 를 이미 재 두었으므로
	//   정당하다(`색` 이득 +0.90 · `자리` +1.00 …). ★ 그것이 없었으면 이 대리는 반칙이었을 것이다.
	//
	// ⚠️⚠️⚠️ **예측을 미리 적어 둔다: `있다` 는 못 찾을 것이다.** 시각 내용이 없는 낱말이라
	//   교차채널이 **원리적으로** 그 경계를 못 만든다. ★ 그것이 이 프로젝트의 출발 통찰
	//   (*"`맛있다` 는 매달린 기호"*)의 그 자리이고, **틀린 예측이면 그것도 배울 것이 있다.**
	int      _xStage = 0;

	// ══════════════════════════════════════════════════════════════════════════
	// ✍️ **D2-b — 생성 경로.** `프레임 → 캡션 바이트 열`을 **이어서 생성**한다.
	//
	// ★ **왜 이것이 병목인가 — "스스로 생각해서 배우는" 루프의 네 조각 중 ①만 없었다:**
	//     ① 모델이 자기 답을 낸다(샘플링)        ← **없다. 이 단계가 그것이다.**
	//     ② 실행이 채점한다(코드→프레임→판독)     ✅ 있다(결정성 5/5)
	//     ③ 틀림/맞음을 무엇 때문인가로 귀속       ✅ 있다(흐림 · AUC 0.8814)
	//     ④ 그 귀속을 저장해 다음 경험을 고른다     ✅ 있다(자가 커리큘럼)
	//   ⇒ ①이 없으면 나머지 셋이 다 놀고 있다. 그래서 여기가 먼저다.
	//
	// ★ **그리고 이것이 "암기 안 하면 스스로 연결 안 한다" 를 깨는 자리다.**
	//   티쳐포싱은 **같은 채널**에서 답을 준다 ⇒ 암기. 여기서는 시도가 **텍스트 채널**에서 나오고
	//   조건은 **비전 채널**에서 온다 ⇒ **연결이 강제되고, 그 연결은 아무도 암기시켜 준 적이 없다.**
	//   (교차채널이 같은채널을 이긴 P4′ 의 결과가 그 물리적 근거다.)
	//
	// ★ **새 커널이 0개다.** 전부 있는 부품이다:
	//     조건: `프레임 → patch_embed → patch(P×D) 를 1×(P·D) 로 → Wc → cw(1×257)`
	//     역사: `바이트 → ctx_embed(인과 창 k) → h(T×D) → Wh → logits(T×257)`
	//     결합: `logits += onesT(T×1) · cw(1×257)`  ← **gemm 의 `beta=1`** 로 브로드캐스트한다
	//   ⚠️ 조건 경로를 **자리보존**으로 시작한다(어텐션 아님) — D2-a 표에서 자리보존이 6축 중
	//     5축에서 최고였다(모양만 약하다). ★ **한 번에 하나만 바꾼다**: 지금 묻는 것은
	//     *"생성 경로가 나오나"* 이고 *"어텐션이 필요하나"* 가 아니다.
	//
	// ★ **생성은 CPU 에서 한다**(가중치를 회수해서). 근거 셋:
	//   ㉠ G′ 를 안 문다 — 한 바이트마다 프레임을 기다리지 않는다.
	//   ㉡ CPU 레퍼런스가 **이미 다 있다**(`MLPatchEmbedCpu`·`MLCtxEmbedCpu`·`MLGemmCpuT`).
	//   ㉢ ★ 그래서 **GPU forward 와 오차 0 으로 검산**할 수 있다(전부 곱덧이다) — 생성이 학습과
	//     다른 계산을 하고 있으면 그것이 함정 1(생성/학습 어긋남)이고 제일 오래 헤매는 자리다.
	int      _gnStage = 0;
	static constexpr uint32 kGnW = 64, kGnH = 64, kGnK = 8;   // 프레임(D2-a 와 같다)
	// ★ **조건/역사 차원.** 16 → 48: 앞 실행에서 비선형이 방향은 맞고(유사도 이득 +0.05 → +0.09)
	//   크기가 모자랐다. 남은 후보가 **조건 용량**이다 — 캡션이 최대 6낱말 × log2(어휘 44) ≈ 33 bit
	//   인데 조건 벡터가 `1×16` 이고 그것도 **평균풀링을 통과한 뒤**다.
	//   ⚠️⚠️ 이것은 함정 42(파라미터/표본 비)와 **반대 방향**이다(늘리면 암기 위험이 는다)
	//     ⇒ 판정에서 **학습일치를 같이 본다** — 이득이 암기에서 온 것이면 학습일치가 함께 뛴다.
	static constexpr uint32 kGnD = 48;        // 임베딩 차원
	static constexpr uint32 kGnCtx = 4;       // 인과 창(경계망의 k=4 최선)
	static constexpr uint32 kGnVoc = 257;     // ★ 256 = **"끝"** — 길이를 어휘 안에 담는다(함정 2)
	// ★ **학습 캡션 60 → 240** — 어텐션+풀링(Wc 64배 ↓)이 시험 이득을 0.05 → 0.11 로
	//   올렸지만 기준(+0.15) 미달이었다. 남은 가설이 **표본 수**다: 첫 낱말 종류가 ~10개라
	//   종류당 표본이 ~6개뿐이다(P2-b1 프로브는 종류당 20~50개였고 일반화했다).
	//   ⚠️ 스텝(3000)은 그대로 둔다 — 같은 계산량에서 **데이터 다양성만** 바꾼다(손잡이 하나).
	//     에포크가 50 → 12.5 로 주는 것은 이 손잡이의 **일부**다(캡션당 노출이 줄어 암기가 힘들어진다).
	static constexpr uint32 kGnTrain = 240, kGnEval = 40;
	static constexpr uint32 kGnMaxLen = 48;   // 캡션 최대 바이트
	// ★ **티칭 횟수 = 정답 캡션에 노출된 횟수.** 그것이 이 실험의 **유일한 공정한 축**이다.
	//   ⚠️⚠️ **앞 실행의 비교는 불공정했다**: 두 팔이 **똑같이 12000번 티칭**받고 자기학습 팔만
	//     자기 타깃 480스텝을 **더** 돌았다 ⇒ *"적은 티칭으로 되나"* 를 **아예 안 재고 있었다.**
	//     ★ 티쳐포싱이 케이스가 적고 스텝이 많으면 이기는 것은 **당연하다** — 그것은 그 문제를
	//       **암기한 것**이고, 암기한 것 이상의 연결·확장은 **하지 못한다.**
	//   ⇒ 두 팔의 **티칭을 같게**(3000) 두고 자기학습만 손잡이로 둔다.
	//     · 팔 0 = 티칭 3000 **만**(대조군 — 이것이 없었다)
	//     · 팔 1 = 티칭 3000 **+ 자기학습**(정답을 안 쓰는 라운드)
	//   ⚠️ 왜 3000 인가: 더 낮추면 모델이 **유효한 캡션을 아예 못 내서** 자기학습이 쓸 재료가 없다
	//     (12.5에포크에서 UTF-8 47.5%였다) ⇒ *"최소 티칭"* 의 실질 하한이 그 근처다.
	//   ★ 앞서 얻은 티칭 12000 의 숫자는 **참고 천장**으로만 쓴다(비교 대상이 아니다).
	static constexpr int    kGnSteps = 3000, kGnPerFrame = 4;
	static constexpr float  kGnLr = 0.01f;

	MLArena  _gn;
	MLKernel _gnPE, _gnPEB, _gnCtx, _gnCtxB, _gnGemm, _gnSoft, _gnSub, _gnAdam;
	MLKernel _gnSoftB;   // 어텐션 조건 경로의 softmax 역전파(망 안쪽이라 야코비안이 접히지 않는다)
	MLKernel _gnRelu, _gnReluB;   // 🔀 비선형 머리(D1′ 에서 만든 커널 그대로)
	// 코퍼스(CPU) — 캡션마다 바이트 구간 + 그 장면의 프레임.
	Array<float>  _gnBytes;                  // 이어붙인 캡션 바이트
	Array<uint32> _gnStart, _gnLen;
	Array<float>  _gnFrameBytes;             // [캡션][64×64] — CPU 생성에도 쓴다
	Array<String> _gnCaps;                   // 정답 캡션(판정용)
	uint32 _gnTotal = 0;
	int    _gnStep = 0;
	int    _gnLastCap = -1;
	int    _gnPlumbCap = -1;   // 배관 검산용으로 forward 만 돌린 캡션

	// ══════════════════════════════════════════════════════════════════════════
	// 🕳️ **창 드롭아웃 — 두 팔 최소대립쌍.** `p = 0`(대조군 = 앞 실행) vs `p = 0.5`.
	//
	// ★ **왜 이 조치인가 — "못 하는 것" 이 아니라 "안 하는 것" 임을 이미 쟀다.**
	//   실측(앞 실행): 첫 바이트 정확도 실제 52.5% vs 섞음 **50.0%** ⇒ 조건의 순 기여 **2.5%p**.
	//   ★ **첫 바이트는 조건이 혼자서 결정할 수 있는 자리다** — 창이 `[BOS]` 뿐이고 자리도 하나라
	//     *"조건이 자리별 상호작용을 못 한다"*(덧셈 바이어스의 한계)로는 **설명되지 않는다.**
	//   ⇒ 그러므로 원인은 **표현력이 아니라 학습 유인**이다: 창 4바이트만 보면 캡션이 거의 결정되니
	//     (`없`→`다`→`.`) **조건이 놀아도 손실이 내려간다**(0.03 nat/바이트) ⇒ 쓸 이유가 없다.
	//   ⇒ 조치: 학습 중 일부 스텝에서 **창을 지운다** ⇒ 그 스텝은 **조건만으로** 맞혀야 한다.
	//
	// ⚠️ **제대로 된 드롭아웃은 forward 와 backward 둘 다 막는다.** 여기서는 `h` 를 0 으로 쓰고
	//   `Wh`·`CSlot` 의 갱신을 **건너뛴다**(기울기가 없으므로) — 안 그러면 지난 스텝의 기울기가
	//   한 번 더 적용된다(조용히 틀린다).
	//   ⚠️ 그래서 그 둘의 편향보정 스텝이 전체 스텝과 어긋난다 — 초반 100스텝에만 영향이 있어
	//     결론이 안 바뀐다(적어 두고 넘어간다).
	// ⚠️ 드롭 여부는 **결정적**이다(같은 실행이 같은 결과) — 이 저장소의 규약이다.
	// ★ **팔을 [선형 / 비선형] 로 바꾼다 — 손잡이가 하나여야 하므로 드롭아웃은 둘 다 0.5.**
	//   ⚠️ `p = 0` 대조군은 앞 커밋(`2fe7a41`)에 이미 기록됐고 **이번 질문에는 불필요**하다:
	//     지금 묻는 것은 *"조건이 자리마다 이기게 하려면 결합이 곱셈이어야 하나"* 다.
	//
	// ★ **왜 비선형인가 — 남은 한계가 정확히 "덧셈" 이다.**
	//   지금 `logits[t] = h[t]·Wh + cw` 이고 `cw` 는 **모든 자리에 같은 값**이다 ⇒ 조건은 출력
	//   분포를 **한 방향으로 밀 뿐** *"이 자리에서는 `노란`, 저 자리에서는 `동그라미`"* 를 못 한다.
	//   ⇒ 실측이 그 모양이다: 첫바이트는 접지됐는데(+0.19) **캡션 전체 일치는 2.5%** 이고
	//     생성이 `아래 작은 노란 동그라미 있다!`(문법 완벽 · 장면 무관)로 나온다.
	//   ⇒ 조건과 창이 **relu 를 함께 통과**하면 곱셈 상호작용이 생긴다:
	//       `hid[t] = relu(h[t]·W1 + cwHid)` · `logits[t] = hid[t]·W2`
	//   ★ `relu`/`relu_bwd` 커널이 **이미 있다**(D1′ 에서 만들었다) ⇒ **새 커널 0개.**
	//   ⚠️ D1′ 의 교훈을 같이 적용한다: 2층은 **He 초기화**가 필요했다(그것 없이는 안 배웠다).
	static constexpr int kGnArms = 2;
	static constexpr uint32 kGnHid = 64;
	int    _gnArm = 0;
	static float _GnDropP(int arm) { (void)arm; return 0.5f; }
	// ★ **팔을 [티쳐포싱만 / 티쳐포싱 + 자기학습] 로 바꾼다 — 둘 다 비선형.**
	//   ⚠️ 선형/비선형 비교는 앞 커밋들(`cd46af7`·`cffc0f5`)에 기록됐고 이번 질문에 불필요하다:
	//     지금 묻는 것은 *"자기 시도 + 실행 채점으로 배우면 티쳐포싱만보다 나은가"* 다.
	static bool  _GnNonlin(int arm) { (void)arm; return true; }
	static bool  _GnSelf(int arm) { return arm == 1; }

	// ══════════════════════════════════════════════════════════════════════════
	// 🔁 **자기학습 루프 — 라운드로 돈다.**
	//   ⚠️⚠️ **왜 라운드인가 = 비용이다.** 샘플을 만들려면 가중치를 **CPU 로 회수**해야 하는데
	//     매 스텝 회수는 감당이 안 된다 ⇒ 라운드마다 **한 번** 회수하고 그 가중치로 배치를 만든다.
	//     ★ 타깃이 살짝 낡는다(off-policy) — 실제 RL 구현들이 하는 것과 같은 절충이고,
	//       라운드 안에서만 낡으므로 그 크기가 통제된다.
	//   ★ **함정 11 을 구조로 지킨다**: 최선 점수가 문턱 미달이면 그 캡션을 **건너뛴다**
	//     ⇒ 나쁜 시도를 타깃으로 쓰지 않는다(*"틀린 상상을 강화"* 가 원리적으로 없다).
	//   ⚠️ 그리고 **정답 캡션을 안 쓴다** — 타깃이 전부 **모델 자신의 출력**이다(그것이 자기학습이다).
	static constexpr uint32 kGnRounds = 8;        // 라운드 수
	static constexpr uint32 kGnSelfCaps = 60;     // 라운드당 캡션
	// ⚠️⚠️ **문턱 0.60 은 함정 11 을 못 막았다.** 채점이 5항목이라 `0.60 = 3/5` 이고,
	//   *"있다/없다 + 색 + 면적"* 만 맞은 **어설픈 캡션이 채택률 83%** 로 대량 통과했다
	//   ⇒ 자기학습이 모델을 망가뜨렸다(학습일치 20.8% → **0.0%**).
	//   ★ 그래서 **거의 만점**을 요구한다(`0.95` = 5항목 전부). ⇒ 채택률이 크게 떨어지는 것이
	//     정상이고, **적지만 옳은 타깃**이 함정 11 이 요구하는 것이다.
	static constexpr float  kGnSelfMin = 0.95f;   // 채점 문턱(미달이면 건너뛴다)
	int    _gnRound = 0;
	int    _gnSelfStep = 0;                       // 라운드 안의 GPU 스텝
	uint32 _gnSelfN = 0;                          // 이번 라운드에 담긴 타깃 수
	Array<uint32> _gnSelfCap, _gnSelfStart, _gnSelfLen;   // 타깃의 캡션 · 구간
	uint32 _gnSelfKept = 0, _gnSelfTried = 0;     // 통계(문턱을 넘긴 비율)
	float  _gnSelfScore = 0.0f;
	// ★ **팔별 lr — D1′ 의 교훈을 이번엔 "전부" 가져온다.**
	//   ⚠️⚠️ 실측으로 밟았다: He 초기화는 가져왔는데 **lr 을 안 낮춰서** 비선형 팔이 **죽었다** —
	//     손실이 `ln(257) = 5.549` 에 **완전히 고정**(로짓 전부 0 = `relu` 가 은닉을 다 죽였다),
	//     학습일치 0.0% · 생성이 빈 문자열. ★ D1′ 은 `0.02 → 0.002`(1/10)였고 여기도 같은 비율이다.
	//   ★ 근거는 D1′ 에 적은 그대로: 층이 늘면 같은 파라미터 이동이 활성값에 **곱해져** 전달된다.
	static constexpr float kGnLr2 = 0.001f;
	// ⚠️⚠️ **선형 머리의 lr 은 차원에 매인다.** 실측: `kGnD` 16 → 48 로 키우자 **선형 팔이 죽었다**
	//   (손실 5.590 ≈ `ln(257)` · UTF-8 22.5%) ⇒ 대조군이 죽어 그 실행의 접지 판정을 **쓸 수 없었다.**
	//   ★ 기제는 D1′·함정 36 과 같다: AdamW 는 스케일 불변이라 파라미터가 매 스텝 `lr` 씩 움직이는데
	//     로짓이 `Σ_D` 라 **차원이 커지면 그 이동이 D 배로 증폭**된다 ⇒ lr 을 차원에 반비례로 잡는다.
	//   ⚠️ **비선형 팔은 안 건드린다**(살아 있었다 · 손실 0.112) — 같이 바꾸면 못 가른다(함정 34).
	static constexpr float kGnLr1 = 0.01f * 16.0f / (float)kGnD;
	float _GnLr() const { return _GnNonlin(_gnArm) ? kGnLr2 : kGnLr1; }
	bool _GnDropped(int step) const
	{
		if (_GnDropP(_gnArm) <= 0.0f) return false;
		const uint32 h = (uint32)step * 2654435761u;   // Knuth 승수 — 결정적 해시
		return ((h >> 16) & 0xFFFFu) < 32768u;         // ≈ 0.5
	}
	// 팔마다의 결과(판정에서 견준다).
	float _gnUtf[kGnArms] = {}, _gnEx[kGnArms] = {}, _gnShf[kGnArms] = {};
	float _gnExTr[kGnArms] = {}, _gnF1st[kGnArms] = {}, _gnF1stShf[kGnArms] = {};
	// 🔬 **학습 캡션에서의** 첫바이트(실/섞) — 두 실패를 가른다.
	float _gnF1stTr[kGnArms] = {}, _gnF1stTrShf[kGnArms] = {};
	// ★ **바이트 일치율** — 캡션 전체 일치(n=40 이라 1개가 2.5%p)보다 **훨씬 안정적인** 지표다.
	float _gnByte[kGnArms] = {};
	// ★ **죽음 신호** — 손실이 `ln(어휘)` 에 고정되면 **로짓이 전부 0** 이다(균등 분포).
	//   ⚠️ UTF-8 비율은 이것을 못 잡는다: *"같은 것만 반복"* 해도 100% 가 나온다(실측으로 밟았다).
	float _gnLoss[kGnArms] = {};
	// 📏 **주 지표** — 정렬 유사도(실제 / 섞음).
	float _gnSim[kGnArms] = {}, _gnSimShf[kGnArms] = {};
	// ▶️ **실행 채점**(생성 캡션 → 파싱 → 코드 실행 → 판독 → 원본 사실과 비교).
	float _gnExec[kGnArms] = {}, _gnExecShf[kGnArms] = {};
	// 🎲 **자기 시도의 가치** — 샘플 N개의 best / mean(실행 채점). argmax 와 견준다.
	static constexpr uint32 kGnBoN = 8;
	static constexpr float  kGnTemp = 0.8f;
	float _gnBest[kGnArms] = {}, _gnMean[kGnArms] = {};
	// ⚠️ **자기강화 붕괴의 지표** — 시험 생성물의 **서로 다른 종류 수**.
	//   ★ 이것을 안 재면 *"가장 안전한 캡션만 낸다"* 를 성공으로 읽는다(함정 11 의 사촌).
	uint32 _gnDiv[kGnArms] = {};
	// 🧠 **지시된 수정** — 랜덤 best-of-N 과 **같은 실행 예산**에서 견준다.
	float _gnDir[kGnArms] = {};
	float _gnDirV[kGnArms] = {};   // 💗🚫 호/불호를 쓴 지시된 수정
	float _gnDirF[kGnArms] = {};   // 🔮 오라클 **없이** 호/불호만으로 고른 것
	uint32 _gnOrcA[kGnArms] = {}, _gnOrcF[kGnArms] = {};   // 오라클 접촉(A / 오라클프리)
	Array<MLScene> _gnScenes;   // 캡션마다의 실제 장면(채점의 정답 쪽)

	MLTensor _tGnFrames, _tGnBytes, _tGnOne;
	MLTensor _tGnSlot, _tGnDSlot, _tGnMS, _tGnVS;      // 패치 표
	MLTensor _tGnPos, _tGnMP, _tGnVP;                  // 자리 표(기울기 = dPatch 그대로)
	MLTensor _tGnPatch, _tGnDPatch;
	MLTensor _tGnCSlot, _tGnDCSlot, _tGnMC, _tGnVC;    // 인과 창 표
	MLTensor _tGnH, _tGnDH;
	MLTensor _tGnWh, _tGnDWh, _tGnMWh, _tGnVWh;
	MLTensor _tGnWc, _tGnDWc, _tGnMWc, _tGnVWc;
	MLTensor _tGnCw, _tGnDCw, _tGnOnesT;
	MLTensor _tGnLogit, _tGnProb, _tGnDLogit;
	// 🔭 **조건 경로 = 어텐션+풀링** (D2-a 가 검증한 그 블록 · 잔차 포함).
	//   ★ **왜 자리보존을 버렸나 — 함정 42 가 확정됐다.** 자리보존 조건은 `Wc` 가
	//     `1024 × 257 = 263,168` 개인데 학습 캡션이 60개다 ⇒ 학습 첫바이트 이득 **+0.69**(조건을
	//     쓴다) vs 시험 **+0.05**(순수 암기). ⇒ 유인이 아니라 **크기**가 문제였다.
	//   ⇒ 어텐션+풀링이면 조건 벡터가 `1×16` 이고 `Wc = 4,112` 개(**64배** ↓).
	//     그리고 D2-a 실측으로 6축 중 5축을 잘 읽는다(모양 +0.76 · 색 +1.00 · 크기 +0.88 …).
	MLTensor _tGnWq, _tGnDWq, _tGnMWq, _tGnVWq;
	MLTensor _tGnWk, _tGnDWk, _tGnMWk, _tGnVWk;
	MLTensor _tGnWv, _tGnDWv, _tGnMWv, _tGnVWv;
	MLTensor _tGnQ, _tGnK, _tGnV, _tGnO;
	MLTensor _tGnDQ, _tGnDK, _tGnDV, _tGnDO;
	MLTensor _tGnS, _tGnA, _tGnDA, _tGnDS;
	MLTensor _tGnEye, _tGnPOnes, _tGnPool, _tGnDPool;
	// 🔀 **비선형 머리**(팔 1 만 쓴다) — `hid = relu(h·W1 + cwHid)` · `logits = hid·W2`
	MLTensor _tGnW1, _tGnDW1, _tGnMW1, _tGnVW1;      // D × Hid
	MLTensor _tGnW2, _tGnDW2, _tGnMW2, _tGnVW2;      // Hid × Voc
	MLTensor _tGnWc1, _tGnDWc1, _tGnMWc1, _tGnVWc1;  // D × Hid (조건 → 은닉)
	MLTensor _tGnHpre, _tGnHact, _tGnDHact, _tGnDHpre;
	MLTensor _tGnCwH, _tGnDCwH;                      // 1 × Hid
	// 🔁 자기학습 타깃 — **모델 자신의 출력**을 코퍼스처럼 올린다(`[BOS, b0…]` 같은 형식).
	MLTensor _tGnSelfTok, _tGnSelfOne;

	// ★ 온도 — forward/backward/CPU 가 **이 한 곳**에서 같은 값을 받는다(한쪽만 넣으면 기울기가 틀린다).
	static float _GnAttnScale() { return 1.0f / Sqrt((float)kGnD); }
	MLArena  _xA;
	MLKernel _xSpan, _xSpanB, _xGemm, _xSoft, _xSub, _xAdam;

	// ⚠️⚠️ **분류마다 "해당없음" 자리가 하나 더 필요하다** — `없다` 장면(빈 프레임)은 색·모양·개수가
	//   **아예 없다**. 그때 아무 값이나 라벨로 주면 **거짓 감독**이 된다(빈 프레임에 `붉은` 이라고 가르치는 셈).
	//   ⇒ 축마다 `해당없음 = AxisClassCount(축)` 번째 분류를 둔다.
	//   ★ 그리고 그것이 곧 `없다` 의 **접지**다: `없` 은 *"모든 축이 해당없음"* 을 예측하게 되고,
	//     그건 다른 어떤 음절과도 다른 뚜렷한 예측이다 — 별도의 존재 축을 만들 필요가 없다.
	// ★ **축이 여덟이다**: 외양 여섯 + **이동**(간다/안간다) + **방향**(왼쪽·오른쪽·위·아래).
	//   ⚠️ 이동·방향은 `MLAxis` 에 **안 넣는다** — 존재와 같은 이유로 **최소대립쌍이 성립하지 않는다**
	//     (안 가는데 방향만 바꿀 수 없다). ⇒ 대립쌍 기계는 외양 여섯만 쓰고, 교차채널만 여덟을 본다.
	// ★ **축이 아홉이다**: 외양 6 + 이동 + 방향 + **존재**.
	//   ⚠️⚠️ **존재를 축으로 넣는 것은 앞선 판단을 뒤집는 것이 아니다 — 두 기계가 다른 것을 원한다.**
	//     · **최소대립쌍 기계**에는 존재가 **전제**여야 한다(없으면 다른 축이 통째로 사라져
	//       *"한 낱말만 다른 짝"* 을 만들 수 없다) ⇒ `MLAxis` 에 넣지 않는다.
	//     · **교차채널**에는 존재가 **축**이어야 한다 — 축이 없으면 `있다`/`없다` 가 이득 계산에
	//       **나타날 자리가 없다**. 실측: 낱말별 흐림에서 `없다` 0.97 · `있다` 0.96 으로 **가장 흐렸다**.
	//   ⇒ ★ 그리고 **그것을 시스템이 스스로 지목했다** — 자가 커리큘럼의 1차 조치가 이것이다.
	// ★ **축이 열이다**: 외양 6 + 이동 + 방향 + 존재 + **이동횟수**.
	static constexpr uint32 kXDim = 16, kXLmax = 4, kXAx = 10, kXCls = 7;

	// 축 `a` 의 실제 값 개수(해당없음은 뺀 수). ★ 여기 한 곳에서 정한다.
	static uint32 _XCls(uint32 a)
	{
		if (a < 6u) return MLSense::AxisClassCount((int)a);
		if (a == 6u) return 2u;                 // 이동
		if (a == 7u) return 4u;                 // 방향
		if (a == 8u) return 2u;                 // 존재
		return 4u;                              // 이동횟수(1..4)
	}
	static const char* _XName(uint32 a)
	{
		if (a < 6u) return MLSense::AxisName(MLSense::AxisAt((int)a));
		if (a == 6u) return "이동";
		if (a == 7u) return "방향";
		if (a == 8u) return "존재";
		return "횟수";
	}
	static constexpr uint32 kXOut = kXAx * kXCls;          // 36 = 축 6 × 분류 6
	static constexpr uint32 kXTrainCaps = 140, kXEvalCaps = 90, kXMaxSpans = 2400;
	static constexpr int    kXSteps = 900, kXPerFrame = 4;
	static constexpr float  kXLr = 0.05f;

	MLTensor _xTok, _xStart, _xLen, _xOne, _xSlot, _xW, _xSym;
	MLTensor _xLogit, _xProb, _xDLogit, _xDSym, _xDSlot, _xDW, _xMS, _xVS, _xMW, _xVW;
	MLTensor _xETok, _xEStart, _xELen, _xESym, _xELogit, _xEProb;

	Array<float> _xTrTok, _xEvTok;
	Array<uint8> _xTrBnd, _xEvBnd;
	Array<int>   _xTrAx, _xEvAx;          // 캡션마다 축 값(캡션 인덱스 × kXAx)
	Array<int>   _xTrCap, _xEvCap;        // 바이트마다 캡션 인덱스
	// ★ **바이트마다 "그 낱말이 무슨 축을 말하나"**(정답 · **평가에만** 쓴다).
	//   `0..7` = 축 · `-1` = 기능어 · `-2` = 존재를 말한다.
	//   ⇒ *"흐림이 내용어와 기능어를 가르나"* 를 재는 라벨이다.
	//   ⚠️ 음절 단위 라벨은 **원리적으로 불가능**하다(`다` 가 `있다`·`간다` 에 다 나온다) ⇒ **낱말 단위**다.
	Array<int>   _xEvWordAx;
	Array<float> _xTrS, _xTrL, _xEvS, _xEvL;
	uint32 _xTrSpans = 0, _xEvSpans = 0;
	int    _xStep = 0;
	float  _xF1 = 0.0f, _xPrec = 0.0f, _xRec = 0.0f;
	uint32 _xNone = 0, _xSyl = 0;

	void _TickCross()
	{
		if (_xStage >= 4) return;

		if (_xStage == 0)
		{
			_xStage = 1;
			if (!_SetupCross()) { _xStage = 4; return; }
			_xStep = 0;
			_xStage = 2;
			return;
		}

		if (_xStage == 2)
		{
			if (_xStep >= kXSteps)
			{
				_xStage = 3;
				if (!_DispatchCrossEval()) _xStage = 4;
				return;
			}
			for (int i = 0; i < kXPerFrame && _xStep < kXSteps; ++i)
			{
				if (!_DispatchCrossStep()) { _xStage = 4; return; }
				_xStep++;
			}
			return;
		}

		_xStage = 4;
		_JudgeCross();
	}

	// 📜 캡션 코퍼스 + **캡션마다 축 6개** + 바이트마다 캡션 인덱스.
	//   ★ 공백을 지우고 그 자리를 경계 라벨로 옮긴다(P2-b2 와 같은 규칙) — 라벨은 **평가에만** 쓴다.
	void _XBuild(uint32 baseSeed, uint32 caps, Array<float>& tok, Array<uint8>& bnd,
		Array<int>& ax, Array<int>& capOf, Array<int>& wordAx) const
	{
		tok.Reset(0); bnd.Reset(0); ax.Reset(0); capOf.Reset(0); wordAx.Reset(0);
		for (uint32 i = 0; i < caps; ++i)
		{
			// 🎓 **수업 하나 = (장면, 캡션) 한 쌍** — 커리큘럼이므로 둘을 함께 고른다.
			//   ★ 낱말마다 고른 단독 노출 · 사다리(없다 → 1칸 → 2칸 → 3칸)가 여기서 나온다.
			MLScene sc;
			String cap;
			Array<int> wax;
			MLSense::MakeLesson(baseSeed + i, sc, cap, wax);

			// 축 값 여덟 — ⚠️ 앞 여섯은 `MLSense::AxisAt` 순서(개수·모양·색·크기·자리·속) · 뒤 둘은 이동·방향.
			//   ⚠️⚠️ **`없다` 장면은 전부 "해당없음"** 이다(빈 프레임에 `붉은` 이라 가르치면 거짓 감독이다).
			//   ⚠️⚠️ 그리고 **`안간다` 면 방향도 "해당없음"** 이다 — 안 가는데 왼쪽으로 안 간다고 말할 수 없다.
			//   ⚠️⚠️⚠️ **존재 축은 `없다` 일 때도 "해당없음" 이 아니다** — 존재는 **늘 정의된다**
			//     (없다는 것도 존재 축의 값이다). 그것이 이 축을 넣는 이유이고, 여기서 틀리면
			//     `없다` 가 다시 접지를 잃는다.
			if (sc.exists == 0)
			{
				for (uint32 a = 0; a < 8u; ++a) ax.Add((int)_XCls(a));   // 외양·이동·방향은 해당없음
				ax.Add(0);                                              // 존재 = 없다
				ax.Add((int)_XCls(9u));                                 // 횟수 = 해당없음
			}
			else
			{
				ax.Add(sc.count - 1); ax.Add(sc.shape); ax.Add(sc.color);
				ax.Add(sc.big);       ax.Add(sc.pos);   ax.Add(sc.filled);
				ax.Add(sc.moves);
				ax.Add((sc.moves != 0) ? sc.moveDir : (int)_XCls(7u));
				ax.Add(1);                                              // 존재 = 있다
				// ⚠️ 안 가면 횟수도 **해당없음**이다(함정 27) — 안 가는데 두 번 안 갔다고 말할 수 없다.
				ax.Add((sc.moves != 0) ? (sc.moveSteps - 1) : (int)_XCls(9u));
			}
			const char* c = cap.ptr();
			if (c == nullptr) continue;
			// ★ 공백을 세며 **낱말 축을 바이트마다** 펼친다(정답 라벨).
			//   ⚠️ 종결 부호는 마지막 낱말에 **붙어 있으므로** 그 낱말의 축을 물려받는다 —
			//     낱말이 하나라 어쩔 수 없고, 그래서 종결 부호 자리는 판정에서 **뺀다**(아래).
			uint32 wi = 0;
			for (uint32 j = 0; c[j] != 0; ++j)
			{
				if (c[j] == ' ')
				{
					if (bnd.Count() > 0) bnd.Data()[bnd.Count() - 1] = 1u;
					wi++;
					continue;
				}
				tok.Add((float)(uint8)c[j]);
				bnd.Add(0u);
				capOf.Add((int)i);
				wordAx.Add((wi < (uint32)wax.Count()) ? wax.Data()[wi] : -1);
			}
			if (bnd.Count() > 0) bnd.Data()[bnd.Count() - 1] = 1u;
		}
	}

	// 🔤 **음절 구간** — L1 발판이 주는 단위. 선두 바이트에서 시작해 다음 선두 바이트 앞까지.
	void _XSyllables(const Array<float>& tok, Array<float>& st, Array<float>& ln) const
	{
		st.Reset(0); ln.Reset(0);
		const uint32 n = (uint32)tok.Count();
		uint32 i = 0;
		while (i < n)
		{
			uint32 e = i + 1u;
			while (e < n && !_IsLead((uint8)tok.Data()[e])) e++;
			uint32 l0 = e - i;
			if (l0 > kXLmax) l0 = kXLmax;
			st.Add((float)i); ln.Add((float)l0);
			i = e;
		}
	}

	bool _SetupCross()
	{
		// ⚠️ 씨앗이 앞 단계들과 겹치지 않는다.
		Array<int> junkAx;
		_XBuild(41000u, kXTrainCaps, _xTrTok, _xTrBnd, _xTrAx, _xTrCap, junkAx);
		_XBuild(83000u, kXEvalCaps,  _xEvTok, _xEvBnd, _xEvAx, _xEvCap, _xEvWordAx);
		_XSyllables(_xTrTok, _xTrS, _xTrL);
		_XSyllables(_xEvTok, _xEvS, _xEvL);
		_xTrSpans = (uint32)_xTrS.Count();
		_xEvSpans = (uint32)_xEvS.Count();
		if (_xTrSpans == 0u || _xEvSpans == 0u
			|| _xTrSpans > kXMaxSpans || _xEvSpans > kXMaxSpans)
		{ LogA("[ml] 교차: 음절 수가 이상하다(%u / %u)\n", _xTrSpans, _xEvSpans); return false; }

		const uint32 n1 = (uint32)_xTrTok.Count(), n2 = (uint32)_xEvTok.Count();
		const uint32 need =
			n1 + n2 + kXMaxSpans * 4u
			+ kXMaxSpans * kXOut * 3u                  // onehot · logits · probs(학습)
			+ kXMaxSpans * kXOut                       // dLogits
			+ kXMaxSpans * kXOut * 2u                  // logits · probs(평가)
			+ kXLmax * 257u * kXDim * 4u               // slot · dSlot · m · v
			+ kXDim * kXOut * 4u                       // W · dW · m · v
			+ kXMaxSpans * kXDim * 3u + 256u;
		if (!_xA.Create(rhi, need))
		{ LogA("[ml] 교차: 아레나 생성 실패(%u floats)\n", need); return false; }

		_xTok    = _xA.Alloc(1, n1);
		_xETok   = _xA.Alloc(1, n2);
		_xStart  = _xA.Alloc(1, kXMaxSpans);
		_xLen    = _xA.Alloc(1, kXMaxSpans);
		_xEStart = _xA.Alloc(1, kXMaxSpans);
		_xELen   = _xA.Alloc(1, kXMaxSpans);
		_xSlot   = _xA.Alloc(kXLmax * 257u, kXDim);
		_xW      = _xA.Alloc(kXDim, kXOut);
		_xSym    = _xA.Alloc(kXMaxSpans, kXDim);
		_xOne    = _xA.Alloc(kXMaxSpans * kXAx, kXCls);
		_xLogit  = _xA.Alloc(kXMaxSpans * kXAx, kXCls);
		_xProb   = _xA.Alloc(kXMaxSpans * kXAx, kXCls);
		_xDLogit = _xA.Alloc(kXMaxSpans * kXAx, kXCls);
		_xDSym   = _xA.Alloc(kXMaxSpans, kXDim);
		_xDSlot  = _xA.Alloc(kXLmax * 257u, kXDim);
		_xDW     = _xA.Alloc(kXDim, kXOut);
		_xMS     = _xA.Alloc(kXLmax * 257u, kXDim);
		_xVS     = _xA.Alloc(kXLmax * 257u, kXDim);
		_xMW     = _xA.Alloc(kXDim, kXOut);
		_xVW     = _xA.Alloc(kXDim, kXOut);
		_xESym   = _xA.Alloc(kXMaxSpans, kXDim);
		_xELogit = _xA.Alloc(kXMaxSpans * kXAx, kXCls);
		_xEProb  = _xA.Alloc(kXMaxSpans * kXAx, kXCls);
		if (!_xEProb.IsValid()) { LogA("[ml] 교차: 텐서 할당 실패\n"); return false; }

		// onehot — 음절마다 **그 캡션의 축 6개**. ★ 감독이 전부 **동시성**이다(경계 라벨이 아니다).
		Array<float> one;
		one.Reset((uint64)_xTrSpans * kXOut);
		for (uint64 i = 0; i < one.Count(); ++i) one.Data()[i] = 0.0f;
		for (uint32 c = 0; c < _xTrSpans; ++c)
		{
			const int cap = _xTrCap.Data()[(uint32)_xTrS.Data()[c]];
			for (uint32 a = 0; a < kXAx; ++a)
			{
				uint32 v = (uint32)_xTrAx.Data()[(uint32)cap * kXAx + a];
				if (v >= kXCls) v = 0u;
				one.Data()[((uint64)c * kXAx + a) * kXCls + v] = 1.0f;
			}
		}

		SeedRand(MLEpisodeGen::ScrambleSeed(6600u));
		Array<float> slot, w;
		slot.Reset((uint64)kXLmax * 257u * kXDim);
		for (uint64 i = 0; i < slot.Count(); ++i)
			slot.Data()[i] = ((float)RandInt(0, 2001) * 0.001f - 1.0f) * (0.4f / (float)kXLmax);
		w.Reset((uint64)kXDim * kXOut);
		for (uint64 i = 0; i < w.Count(); ++i)
			w.Data()[i] = ((float)RandInt(0, 2001) * 0.001f - 1.0f) * (0.4f / (float)kXDim);

		if (!_xA.Write(_xTok, _xTrTok) || !_xA.Write(_xETok, _xEvTok)
			|| !_xA.Write(_xStart, _xTrS) || !_xA.Write(_xLen, _xTrL)
			|| !_xA.Write(_xEStart, _xEvS) || !_xA.Write(_xELen, _xEvL)
			|| !_xA.Write(MLTensor{ _xOne.offset, _xTrSpans * kXAx, kXCls }, one)
			|| !_xA.Write(_xSlot, slot) || !_xA.Write(_xW, w))
		{ LogA("[ml] 교차: 업로드 실패\n"); return false; }

		if (!_LoadKernelIn(_xSpan,  "shaders/span_embed.cs.spv",     _xA)) return false;
		if (!_LoadKernelIn(_xSpanB, "shaders/span_embed_bwd.cs.spv", _xA)) return false;
		if (!_LoadKernelIn(_xGemm,  "shaders/gemm.cs.spv",           _xA)) return false;
		if (!_LoadKernelIn(_xSoft,  "shaders/softmax.cs.spv",        _xA)) return false;
		if (!_LoadKernelIn(_xSub,   "shaders/sub.cs.spv",            _xA)) return false;
		if (!_LoadKernelIn(_xAdam,  "shaders/adamw.cs.spv",          _xA)) return false;

		LogA("\n[ml] 🔀 **P4′ 교차채널 응집** — 음절 → 프레임 축 6개 · dim %u · %d스텝\n"
			"[ml]   학습 캡션 %u(음절 %u) / 평가 캡션 %u(음절 %u) · ⚠️ **바이트 통계를 하나도 안 쓴다**\n",
			kXDim, kXSteps, kXTrainCaps, _xTrSpans, kXEvalCaps, _xEvSpans);
		return true;
	}

	// 한 스텝 = 디스패치 여덟.
	bool _DispatchCrossStep()
	{
		MLSpanEmbedParams e;
		e.tokOff = _xTok.offset; e.startOff = _xStart.offset; e.lenOff = _xLen.offset;
		e.aOff = _xSlot.offset; e.bOff = _xSym.offset;
		e.spans = _xTrSpans; e.maxLen = kXLmax; e.dim = kXDim;
		if (!_xSpan.Dispatch(kXDim, _xTrSpans, 1u, &e, (uint32)sizeof(e))) return _Fail("x sym");

		MLGemmParams g;
		g.aOff = _xSym.offset; g.bOff = _xW.offset; g.cOff = _xLogit.offset;
		g.M = _xTrSpans; g.N = kXOut; g.K = kXDim;
		if (!_xGemm.Dispatch(kXOut, _xTrSpans, 1u, &g, (uint32)sizeof(g))) return _Fail("x logits");

		// ★ softmax 의 행이 `(음절, 축)` · 열이 분류 6 — 배치가 그대로 맞는다(reshape 없음).
		MLSoftmaxParams sm;
		sm.inOff = _xLogit.offset; sm.outOff = _xProb.offset;
		sm.rows = _xTrSpans * kXAx; sm.cols = kXCls;
		if (!_xSoft.Dispatch(sm.rows, 1u, 1u, &sm, (uint32)sizeof(sm))) return _Fail("x softmax");

		MLSubParams sb;
		sb.aOff = _xProb.offset; sb.bOff = _xOne.offset; sb.outOff = _xDLogit.offset;
		sb.count = _xTrSpans * kXOut;
		if (!_xSub.Dispatch(sb.count, 1u, 1u, &sb, (uint32)sizeof(sb))) return _Fail("x dlogits");

		MLGemmParams gw;
		gw.aOff = _xSym.offset; gw.bOff = _xDLogit.offset; gw.cOff = _xDW.offset;
		gw.M = kXDim; gw.N = kXOut; gw.K = _xTrSpans; gw.transA = 1;
		if (!_xGemm.Dispatch(kXOut, kXDim, 1u, &gw, (uint32)sizeof(gw))) return _Fail("x dW");

		MLGemmParams gs;
		gs.aOff = _xDLogit.offset; gs.bOff = _xW.offset; gs.cOff = _xDSym.offset;
		gs.M = _xTrSpans; gs.N = kXDim; gs.K = kXOut; gs.transB = 1;
		if (!_xGemm.Dispatch(kXDim, _xTrSpans, 1u, &gs, (uint32)sizeof(gs))) return _Fail("x dSym");

		MLSpanEmbedParams eb;
		eb.tokOff = _xTok.offset; eb.startOff = _xStart.offset; eb.lenOff = _xLen.offset;
		eb.aOff = _xDSym.offset; eb.bOff = _xDSlot.offset;
		eb.spans = _xTrSpans; eb.maxLen = kXLmax; eb.dim = kXDim;
		if (!_xSpanB.Dispatch(kXDim, eb.SlotRows(), 1u, &eb, (uint32)sizeof(eb)))
			return _Fail("x dSlot");

		float bc1 = 1.0f, bc2 = 1.0f;
		_BiasCorr(_xStep + 1, bc1, bc2);
		MLAdamWParams aw;
		aw.lr = kXLr; aw.beta1 = kB1; aw.beta2 = kB2; aw.eps = kAdamEps; aw.wd = kWd;
		aw.bc1 = bc1; aw.bc2 = bc2;
		aw.pOff = _xSlot.offset; aw.gOff = _xDSlot.offset;
		aw.mOff = _xMS.offset;   aw.vOff = _xVS.offset;   aw.count = _xSlot.Count();
		if (!_xAdam.Dispatch(aw.count, 1u, 1u, &aw, (uint32)sizeof(aw))) return _Fail("x adamw slot");
		MLAdamWParams ax = aw;
		ax.pOff = _xW.offset;  ax.gOff = _xDW.offset;
		ax.mOff = _xMW.offset; ax.vOff = _xVW.offset; ax.count = _xW.Count();
		if (!_xAdam.Dispatch(ax.count, 1u, 1u, &ax, (uint32)sizeof(ax))) return _Fail("x adamw W");
		return true;
	}

	bool _DispatchCrossEval()
	{
		MLSpanEmbedParams e;
		e.tokOff = _xETok.offset; e.startOff = _xEStart.offset; e.lenOff = _xELen.offset;
		e.aOff = _xSlot.offset; e.bOff = _xESym.offset;
		e.spans = _xEvSpans; e.maxLen = kXLmax; e.dim = kXDim;
		if (!_xSpan.Dispatch(kXDim, _xEvSpans, 1u, &e, (uint32)sizeof(e))) return _Fail("x eval sym");

		MLGemmParams g;
		g.aOff = _xESym.offset; g.bOff = _xW.offset; g.cOff = _xELogit.offset;
		g.M = _xEvSpans; g.N = kXOut; g.K = kXDim;
		if (!_xGemm.Dispatch(kXOut, _xEvSpans, 1u, &g, (uint32)sizeof(g))) return _Fail("x eval logits");

		MLSoftmaxParams sm;
		sm.inOff = _xELogit.offset; sm.outOff = _xEProb.offset;
		sm.rows = _xEvSpans * kXAx; sm.cols = kXCls;
		if (!_xSoft.Dispatch(sm.rows, 1u, 1u, &sm, (uint32)sizeof(sm))) return _Fail("x eval softmax");
		return true;
	}

	void _JudgeCross()
	{
		Bytes bp;
		const uint64 want = (uint64)_xEvSpans * kXOut * sizeof(float);
		if (!_xA.Read(_xEProb, bp) || bp.GetSize() < want)
		{ LogA("[ml] 교차: 평가 회수가 안 됐다\n"); return; }
		const float* pr = (const float*)bp.GetData();

		// ★ **이득의 기준선은 균등이 아니라 데이터의 실제 marginal 분포다.**
		//   ⚠️⚠️ 실측으로 밟았다: 균등을 기준선으로 쓰니 **정보가 하나도 없는 음절도 양의 이득**을 얻었다.
		//     `개수` 를 6분류로 뒀는데 데이터에는 1~5만 나오므로, 아무 정보 없는 음절도
		//     *"6은 절대 안 나온다"* 만 배워서 `log 6 − log 5 = 0.18 nat` 을 벌었다.
		//     ⇒ argmax 가 **가장 편향된 축**(개수)으로 쏠려 `에`·`있다`·`큰` 이 전부 `개수` 로 찍혔고
		//       **`없음` 이 0개**가 됐다(그 0 이 의심해야 할 신호였다).
		//   ⇒ ★ 정확한 정의를 쓴다: `I = H(축) − H(축|음절)` 에서 `H(축)` 는 **marginal** 이다.
		//     그러면 *"아무것도 안 가리킨다"* 가 정확히 **이득 0** 이 된다.
		//   ⚠️ marginal 은 **학습 캡션**에서 센다(평가 라벨을 쓰면 누출이다).
		//   ⚠️⚠️⚠️ **그리고 "음절 가중"으로 세야 한다 — 캡션당 1표로 세면 또 공짜 이득이 생긴다.**
		//     실측으로 두 번째로 밟았다: 캡션 가중으로 재니 `에`·`있`·`다`·`가` 가 여전히 뭔가를
		//     가리켰고 **`없음` 이 0개**였다(정밀도 0.6897 로 눌렸다).
		//     ★ 이유: 캡션 길이가 축 값에 따라 다르다(`동그라미` 4음절 vs `네모` 2음절)
		//       ⇒ **음절 가중 marginal ≠ 캡션 가중 marginal**. 모델은 **음절마다 한 번** 손실을 받으므로
		//       모델이 최적화하는 사전은 **음절 가중**이다. 기준선이 그것과 달라지면 그 차이가
		//       **정보 없는 음절의 공짜 이득**으로 나타난다.
		//     ⇒ ★ 판정 규칙: ***"기준선은 모델이 실제로 최소화하는 그 분포여야 한다."***
		// ⚠️ **분류 수 = 실제 값 개수 + 1**(해당없음).
		uint32 cls[kXAx];
		for (uint32 a = 0; a < kXAx; ++a) cls[a] = _XCls(a) + 1u;
		float priorH[kXAx];
		for (uint32 a = 0; a < kXAx; ++a)
		{
			uint32 cnt[kXCls];
			for (uint32 v = 0; v < kXCls; ++v) cnt[v] = 0u;
			// ★ **음절마다** 한 표 — 그 음절이 속한 캡션의 축 값을 센다.
			for (uint32 c = 0; c < _xTrSpans; ++c)
			{
				const int cap = _xTrCap.Data()[(uint32)_xTrS.Data()[c]];
				uint32 v = (uint32)_xTrAx.Data()[(uint32)cap * kXAx + a];
				if (v >= kXCls) v = 0u;
				cnt[v]++;
			}
			// ⚠️⚠️⚠️ **`해당없음` 을 빼고 재정규화해서 잰다.**
			//   실측으로 밟았다: 해당없음을 섞어 재니 **`방향` 축이 쓰레기통**이 됐다 —
			//   방향은 이동 칸(5/16)에서만 정의되므로 대부분 해당없음이고, `있`·`작은` 처럼
			//   **외양 문장에만 나오는 음절**이 *"방향 = 해당없음"* 을 강하게 예측해서
			//   **큰 이득**을 얻었다(그래서 `있(방향)`·`작(방향)` 이 찍혔다).
			//   ★ 우리가 묻는 것은 *"이 음절이 어떤 시각 **값**을 가리키나"* 이고
			//     *"해당없음"* 은 **가리키는 게 없다는 뜻**이다 ⇒ 이득으로 세면 안 된다.
			//   ⇒ 실제 값들만 남겨 재정규화한 분포의 엔트로피를 쓴다(모델 쪽도 같은 방식 — 아래).
			const uint32 realN = _XCls(a);
			uint32 tot = 0;
			for (uint32 v = 0; v < realN; ++v) tot += cnt[v];
			float h = 0.0f;
			if (tot > 0u)
				for (uint32 v = 0; v < realN; ++v)
				{
					if (cnt[v] == 0u) continue;
					const float pv = (float)cnt[v] / (float)tot;
					h -= pv * Log(pv);
				}
			priorH[a] = h;
		}
		for (uint32 a = 0; a < kXAx; ++a)
			LogA("[ml]   축 %-4s marginal %.3f nat (균등이면 %.3f · 분류 %u)\n",
				_XName(a), (double)priorH[a], (double)Log((float)cls[a]), cls[a]);

		// ★ **흐림을 값으로 갖는다 — 이진 결정을 강제하지 않는다.**
		//   ⚠️⚠️ 나는 `있`·`개`·`에` 를 `없음` 으로 **강제하려고 세 번 고쳤다**(함정 24·27·28) 그리고
		//     **`없음` 이 0개인 것이 세 번 반복됐다.** 매번 원인은 *"유한 표본이라 이득이 정확히 0 이
		//     안 된다"* 였고, 나는 계속 **문턱**을 찾고 있었다.
		//   ★ 그런데 **문턱은 정보를 버린다**: `개` 의 이득이 0.03 이고 `동그라미` 가 0.9 라면
		//     그 **0.03 이 "흐리다" 는 정보**인데 `없음` 이라는 한 낱말로 뭉개진다.
		//   ⇒ ★ 흐림을 **두 종류의 연속값**으로 남긴다:
		//       · **양의 흐림**   `1 − 최대이득/그 축의 marginal H` — *"얼마나 아나"*
		//       · **선택의 흐림** `2위이득 / 1위이득`               — *"무엇을 아는지 헷갈리나"*
		//     ★ 둘이 다른 것을 잡는다: `개` 는 **양**이 흐리고, **`위`** 는 양은 뚜렷한데
		//       `자리`인지 `방향`인지 **선택**이 흐리다 — 그리고 그것은 **틀린 게 아니라 진짜 중의성**이다
		//       (방향 낱말을 자리 낱말과 같게 뒀으므로). argmax 로 하나를 고르면 그 중의성을 **숨긴다.**
		Array<int> pointAx;
		// ★ **세 번째 흐림 — "적용" 이다. 그리고 이것이 기능어가 아는 것이다.**
		//   ⚠️⚠️ 예측을 **미리 적는다**: `개`·`번` 의 **양의 흐림은 높게 유지될 것이다.**
		//     `개` 는 항상 숫자 뒤에 오고 **값은 숫자가 준다** — `개` 자체는 *"몇 개인지"* 를 모른다.
		//     ⇒ 지금 이득 정의(**값** 확신)로는 흐릴 수밖에 없고, **그것이 기능어의 본질**이다:
		//       기능어는 *"어느 축에 대한 이야기인가"* 를 말하고 **값은 안 말한다.**
		//   ⇒ ★ 그래서 `P(해당있음)` 을 얼마나 확신하나를 따로 잰다:
		//     `개` 는 *"개수는 해당있음 · 횟수는 해당없음"*, `번` 은 **반대**여야 한다.
		//     ★ 그것이 **셈낱말이 하는 일**이고, `개`/`번` 이 짝이 되어야 비로소 뜻을 가진다.
		Array<float> fuzzAmt, fuzzSel, applyGap;
		pointAx.Reset(_xEvSpans);
		fuzzAmt.Reset(_xEvSpans);
		fuzzSel.Reset(_xEvSpans);
		// 적용 변별력 = `|P(개수 해당있음) − P(횟수 해당있음)|`. 셈낱말이면 커야 한다.
		applyGap.Reset(_xEvSpans);
		_xNone = 0;
		for (uint32 c = 0; c < _xEvSpans; ++c)
		{
			int best = -1; float bestG = 0.0f, secondG = 0.0f;
			for (uint32 a = 0; a < kXAx; ++a)
			{
				const float* q = pr + ((uint64)c * kXAx + a) * kXCls;
				const uint32 realN = _XCls(a);
				// ★ `해당있음` 확률과 그 조건부 분포를 갈라 본다.
				float pApply = 0.0f;
				for (uint32 v = 0; v < realN; ++v) pApply += q[v];
				float h = 0.0f;
				if (pApply > 1.0e-9f)
					for (uint32 v = 0; v < realN; ++v)
					{
						const float pv = q[v] / pApply;
						if (pv > 0.0f) h -= pv * Log(pv);
					}
				// ★ **이득 = P(해당있음) × (값을 얼마나 좁혔나).**
				//   ⚠️ 문턱이 없다 — `있` 은 `방향` 축에서 `P(해당있음) ≈ 0` 이라 **저절로 0** 이 된다.
				//   ★ 그리고 이것이 정확한 뜻이다: *"그 축이 적용될 때 그 값을 아는가"* 를
				//     **적용될 확률로 가중**한 것 = 기대 정보이득.
				const float gain = pApply * (priorH[a] - h);
				if (best < 0 || gain > bestG) { secondG = bestG; bestG = gain; best = (int)a; }
				else if (gain > secondG) secondG = gain;
			}
			pointAx.Data()[c] = (bestG > 0.0f) ? best : -1;
			if (pointAx.Data()[c] < 0) _xNone++;

			// 양의 흐림 — 그 축에서 **알 수 있는 것 중 얼마나 알았나**의 여집합.
			const float room = (best >= 0) ? priorH[(uint32)best] : 1.0f;
			float fa = (room > 1.0e-6f) ? (1.0f - bestG / room) : 1.0f;
			if (fa < 0.0f) fa = 0.0f;
			if (fa > 1.0f) fa = 1.0f;
			fuzzAmt.Data()[c] = fa;
			// 선택의 흐림 — 1위와 2위가 비슷할수록 1 에 가깝다.
			float fs = (bestG > 1.0e-6f) ? (secondG / bestG) : 1.0f;
			if (fs < 0.0f) fs = 0.0f;
			if (fs > 1.0f) fs = 1.0f;
			fuzzSel.Data()[c] = fs;

			// 적용 변별력 — 개수 축(0)과 횟수 축(9)의 `해당있음` 확률 차.
			{
				const float* q0 = pr + ((uint64)c * kXAx + 0u) * kXCls;
				const float* q9 = pr + ((uint64)c * kXAx + 9u) * kXCls;
				float p0 = 0.0f, p9 = 0.0f;
				for (uint32 v = 0; v < _XCls(0u); ++v) p0 += q0[v];
				for (uint32 v = 0; v < _XCls(9u); ++v) p9 += q9[v];
				// ⚠️⚠️⚠️ **절댓값을 씌우면 안 된다 — 방향이 정보다.**
				//   실측으로 밟았다: `|P(개수) − P(횟수)|` 로 재니 셈낱말 0.4154 vs 나머지 0.4521 로
				//   **오히려 낮았다.** 개수 축은 `exists = 1` 이면 **항상** 해당있으므로
				//   **모든 낱말이 gap 이 크다** — 절댓값은 그 배경과 셈낱말을 구별하지 못한다.
				//   ★ `개` 는 *"개수 높고 횟수 낮음"*(**양수**) · `번` 은 **반대**(음수)여야 한다
				//     ⇒ **부호가 곧 "어느 축의 셈낱말인가"** 다.
				applyGap.Data()[c] = p0 - p9;
			}
		}

		_JudgeApply(applyGap, fuzzAmt);
		_xSyl = _xEvSpans;

		// ★ **경계 규칙**: 가리키는 축이 **바뀌는 자리**. `없음` 은 **앞 축을 물려받는다**
		//   (시각 내용이 없는 음절은 새 단위를 시작할 수 없다 — 조사가 하는 일과 같다).
		Array<uint8> mask;
		mask.Reset(_xEvTok.Count());
		for (uint32 i = 0; i < (uint32)mask.Count(); ++i) mask.Data()[i] = 0u;
		int cur = -1;
		for (uint32 c = 0; c < _xEvSpans; ++c)
		{
			const int a = pointAx.Data()[c];
			if (a >= 0 && cur >= 0 && a != cur)
			{
				// 앞 음절의 **마지막 바이트** 뒤가 경계다.
				const uint32 prevEnd = (uint32)_xEvS.Data()[c] - 1u;
				if (prevEnd < (uint32)mask.Count()) mask.Data()[prevEnd] = 1u;
			}
			if (a >= 0) cur = a;
		}
		// 캡션 끝은 늘 경계다(다음 캡션이 이어붙으므로). ⚠️ 그것은 채널과 무관한 **사실**이다.
		for (uint32 i = 0; i + 1u < (uint32)_xEvCap.Count(); ++i)
			if (_xEvCap.Data()[i] != _xEvCap.Data()[i + 1u]) mask.Data()[i] = 1u;
		if (mask.Count() > 0) mask.Data()[mask.Count() - 1] = 1u;

		// F1 — 후보(음절 경계) 안에서만 견준다.
		uint32 tp = 0, pd = 0, gt = 0;
		for (uint32 t = 0; t + 1u < (uint32)_xEvTok.Count(); ++t)
		{
			if (!_IsLead((uint8)_xEvTok.Data()[t + 1u])) continue;
			const bool p = (mask.Data()[t] != 0u), g = (_xEvBnd.Data()[t] != 0u);
			if (p) pd++; if (g) gt++; if (p && g) tp++;
		}
		_xPrec = (pd > 0u) ? ((float)tp / (float)pd) : 0.0f;
		_xRec  = (gt > 0u) ? ((float)tp / (float)gt) : 0.0f;
		_xF1 = ((_xPrec + _xRec) > 0.0f) ? (2.0f * _xPrec * _xRec / (_xPrec + _xRec)) : 0.0f;

		// 👁️ 그림 — 음절마다 가리키는 축을 붙여 본다(무엇을 배웠나가 눈으로 보인다).
		{
			Bytes buf;
			buf.Reset(600ull);
			uint8* q = (uint8*)buf.GetData();
			uint64 w = 0;
			for (uint32 c = 0; c < _xEvSpans && w < 520ull; ++c)
			{
				const uint32 s0 = (uint32)_xEvS.Data()[c], l0 = (uint32)_xEvL.Data()[c];
				for (uint32 j = 0; j < l0; ++j) q[w++] = (uint8)_xEvTok.Data()[s0 + j];
				const int a = pointAx.Data()[c];
				q[w++] = (uint8)'(';
				if (a < 0) { q[w++] = (uint8)'-'; }
				else
				{
					const char* nm = _XName((uint32)a);
					for (uint32 k = 0; nm[k] != 0; ++k) q[w++] = (uint8)nm[k];
				}
				q[w++] = (uint8)')';
				if (mask.Data()[s0 + l0 - 1u] != 0u) q[w++] = (uint8)'|';
			}
			q[w] = 0u;
			LogA("[ml]\n[ml] 👁️ **음절이 가리키는 축**(`|` = 교차채널이 낸 경계 · `-` = 없음):\n[ml]   %s\n",
				(const char*)q);
		}

		LogA("\n[ml] 🔀 **P4′ 표** — 경계를 **다른 채널**이 가르쳐 준다\n"
			"[ml]   %-26s %9s %9s %9s\n", "방법", "정밀도", "재현율", "F1");
		LogA("[ml]   %-26s %9.4f %9.4f %9.4f  ← 바이트 통계 **0**\n",
			"교차채널(축이 바뀌는 자리)", (double)_xPrec, (double)_xRec, (double)_xF1);
		// ⚠️⚠️ **비교값을 하드코딩하지 않는다 — 이번 실행의 실제 값을 쓴다.**
		//   실측으로 밟았다: 생성기를 고쳐 데이터가 바뀌자 하드코딩해 둔 `0.8309`·`0.7276` 이
		//   **옛 데이터의 숫자**가 되어 표가 거짓말을 했다(그 실행에서 P2-b2·P3-a 는 실패였다).
		//   ★ 판정 규칙: *"같은 실행에서 나온 숫자끼리만 나란히 놓는다."*
		const float cmpMdl = _mBest[kBArms - 1u].f1;   // P3-a 문턱 최선(같은 채널)
		const float cmpH   = _bF1[kBArms - 1u];        // P2-b2 접두사 엔트로피(상위 M개)
		const float cmpBi  = _bF1[0];                  // 바이그램
		LogA("[ml]   %-26s %9s %9s %9.4f  (같은 채널 최선 · P3-a · **이번 실행**)\n",
			"MDL 문턱", "-", "-", (double)cmpMdl);
		LogA("[ml]   %-26s %9s %9s %9.4f  (접두사 엔트로피 · P2-b2)\n", "H 상위 M개", "-", "-", (double)cmpH);
		LogA("[ml]   %-26s %9s %9s %9.4f  (바이그램 · 함정 4)\n", "바이그램", "-", "-", (double)cmpBi);
		LogA("[ml]   음절 %u개 중 **아무것도 안 가리키는 것 %u개**(%.1f%%) — 조사·`있다` 같은 것\n",
			_xSyl, _xNone, 100.0 * (double)_xNone / (double)_xSyl);

		// ★ **기준은 측정 전에 정했다.**
		//   ㉠ **교차채널이 같은 채널 최선을 넘는다**(F1 > 0.8309) ⇒ *"다른 종류의 단서"* 라는 주장이 확인된다
		//   ㉡ **바이트 통계 없이** 우연을 크게 넘는다(F1 > 0.6) ⇒ 동시성만으로 응집이 생긴다
		const bool okBeat = (_xF1 > cmpMdl);
		const bool okAlone = (_xF1 > 0.6f);
		LogA("[ml] P4′ 판정: %s\n"
			"[ml]   ㉠ **같은 채널 최선을 넘는다**: F1 %.4f vs %.4f → %s\n"
			"[ml]   ㉡ **바이트 통계 없이 된다**: F1 %.4f > 0.6 → %s\n"
			"[ml]      ★ 감독이 전부 **동시성**이다 — 엔트로피도 빈도도 MDL 도 쓰지 않았다.\n",
			(okBeat && okAlone) ? "통과" : (okAlone ? "부분 통과" : "★실패★"),
			(double)_xF1, (double)cmpMdl, okBeat ? "통과" : "★실패★",
			(double)_xF1, okAlone ? "통과" : "★실패★");
		_JudgeFuzz(pointAx, fuzzAmt, fuzzSel);

		LogA("[ml]   ⚠️ **미리 적어 둔 예측**: 시각 내용이 없는 낱말(`있다`·조사)은 교차채널이\n"
			"[ml]      **원리적으로** 경계를 못 만든다 — 위 그림에서 `-` 로 찍힌 자리가 그것이다.\n"
			"[ml]      ★ 그것이 이 프로젝트의 출발 통찰(*\"`맛있다` 는 매달린 기호\"*)의 그 자리다.\n"
			"[ml]      ⇒ **재현율의 상한이 거기서 정해진다**(정밀도가 아니라 재현율을 보라).\n");
	}

	// ── 🧠 **P3-c · 경계를 문턱이 아니라 목적함수와 학습으로 정한다** ───────────────────────
	//
	// ★ **straight-through 대신 DP 를 골랐다 — 근사보다 정확한 것이 있으면 그걸 쓴다.**
	//   `L_recon` 의 **경계에 대한** 기울기는 조합적이라(경계를 옮기면 어느 바이트가 어느 덩어리에
	//   드는지가 통째로 바뀐다) straight-through 는 근사다. 그런데 비용이 **덩어리마다 더해지는 꼴**이면
	//   **동적계획법이 최적 분할을 정확히** 찾는다 — 문턱도, 개수도, 오라클도 안 준다.
	//   ⇒ ★ 기록된 판정(*"경계를 문턱이 아니라 학습으로 정하고도 절충이 재현되나"*)을 **더 센 방법으로** 만족시킨다.
	//   ⚠️ 대신 DP 는 **전체를 본다**(인과적이 아니다) → 그래서 ㉣ 에서 **인과적 머리**가 그것을 배우는지 잰다.
	//
	// ★ **비용은 두 부분 코드 그대로다**(P3-a 에서 확인한 그 설계):
	//     · 사전에 있는 덩어리   → `-log2 P(덩어리)`  (본문에서 지목하는 비용 = `L_pred` 자리)
	//     · 사전에 없는 덩어리   → `(len + 1) × 8`     (사전에 새로 적는 비용 = `β·N_symbols` 자리)
	//     · 그리고 **심볼마다 `β` bit** (개수에 매기는 값 — 손잡이)
	//   ★ `β = 0` 이 **원칙적 기본값**이다 — 두 부분 코드가 이미 모든 비용을 매기고 있으므로.
	//     β sweep 은 **민감도 확인**이다(P3-b 가 잰 그 손잡이가 여기서도 사나).
	//
	// ⚠️⚠️⚠️⚠️ **결론: 이 시도는 실패했다. DP 로 두 부분 코드를 최소화하는 것은 원리적으로 안 된다.**
	//   세 번 고쳤고 세 실패가 **같은 뿌리**를 가리킨다 — **사전 비용은 `Σ_types` 이라 전역인데
	//   DP 의 비용은 덩어리마다 독립(국소)이어야 한다.** 종류가 몇 가지인지는 **전체 분할을 봐야** 안다.
	//     ① **아래→위 EM**(음절 사전에서 확장): 6바이트 덩어리를 새로 적는 값이 `(6+1)×8 = 56 bit`,
	//        음절 둘로 쪼개면 `2×log2(38) ≈ 10.5 bit` ⇒ **새 덩어리가 5배 비싸 절대 안 생긴다.**
	//        실측: 614심볼(= 음절 전부) · F1 0.6256 에 갇혔다.
	//     ② **위→아래 EM**(후보 전체 사전 + `-log2 P_uni`): 사전 비용이 **아예 없으므로** 긴 유니크
	//        덩어리(11.5 bit)가 음절 5개(26 bit)보다 싸다 ⇒ **최대 길이로 붙인다.**
	//        실측: 126심볼(평균 14.6바이트) · 종류 72 · **DL 9681 bit**(정답 2649 의 3.7배) · F1 0.4059.
	//     ③ **길이 벌점 `γ·len`**: ⚠️⚠️ **수학적으로 무효다** — 모든 바이트가 정확히 한 덩어리에 속하므로
	//        `Σ_chunks γ·len = γ·n` 이 **분할과 무관한 상수**다. 실측으로 γ 8값이 **전부 같은 결과**였다.
	//        ★ 국소 벌점으로 전역 비용을 근사하려는 시도가 **원리적으로 막히는 자리**다.
	//   ⇒ ★ **다음 방향은 바깥 루프 가지치기다**: 사전을 **고정하면 그 비용은 상수**이므로 DP 는
	//     본문만 최소화하면 되고, 그 다음 **진짜 DL 을 재서 사전에서 후보를 빼고** 반복한다
	//     (그것이 unigram LM 학습의 실제 알고리즘이다). 지금은 **P3-a 의 문턱 족(F1 0.8309)이 최선**이다.
	//   ★ 그리고 ㉢(인과적 머리)의 실패는 **타깃의 실패에 종속**이다 — 첫 시도(DP = 음절 전부)에서
	//     머리는 **일치 100%** 였다. 머리는 작동한다; 배울 것이 나빴을 뿐이다.
	//
	// ★ ⚠️⚠️⚠️ **EM 은 위에서 아래로 가야 한다 — 거꾸로 했다가 갇혔다(실측).**
	//   처음엔 *"음절 사전에서 시작해 DP 가 낱말을 만들게"* 했다. **작동하지 않았다**: β=0~16 에서
	//   DP 가 **614심볼(음절 전부)** 을 골랐고 F1 0.6256 에 머물렀다.
	//   ★ 이유가 구조적이다: 사전에 없는 6바이트 덩어리를 새로 적는 비용이 `(6+1)×8 = 56 bit` 인데
	//     음절 둘로 쪼개면 `2 × log2(38) ≈ 10.5 bit` 다 ⇒ **새 덩어리가 5배 비싸서 절대 안 생긴다.**
	//   ★ 근본 원인: **사전 비용은 전역이다**(여러 번 쓰이면 갚아진다) 그런데 **DP 는 한 번의 사용만 본다.**
	//     비용을 덩어리마다 독립으로 쪼갠 순간 *"자주 나오니까 사전에 넣을 만하다"* 를 표현할 수 없다.
	//   ⇒ ★ 그래서 방향을 뒤집는다: **모든 후보 부분문자열을 빈도와 함께 사전에 넣고 시작해 가지치기**한다
	//     (표준 unigram LM 학습의 그 방향이다). 자주 쓰이는 것은 `-log2 P` 가 작아 **살아남는다**.
	//   ⚠️ 가지치기가 붕괴하지 않게 **add-one 스무딩**으로 후보를 전부 살려 둔다(확률만 낮아진다).
	int _hStage = 0;
	static constexpr int kHSteps = 600, kHPerFrame = 4;
	static constexpr float kHLr = 0.05f;
	static constexpr uint32 kHIters = 8, kHLmax = 15;   // EM 반복 · 덩어리 최대 바이트

	Array<uint8> _hDpMask;                  // DP 가 고른 경계
	uint32 _hDpSpans = 0, _hDpTypes = 0;
	float  _hDpF1 = 0.0f, _hDpBits = 0.0f;
	int    _hStep = 0;
	float  _hHeadF1Dp = 0.0f, _hHeadF1Truth = 0.0f, _hHeadAcc = 0.0f;
	uint32 _hBetaN[6] = {}; float _hBetaF1[6] = {};

	void _TickHead()
	{
		if (_hStage >= 4) return;

		if (_hStage == 0)
		{
			_hStage = 1;
			// ① DP+EM 으로 분할한다(β 는 심볼당 벌점).
			{
				Array<uint8> m = _DpSegment(0.0f);
				uint32 sp = 0, ty = 0; float bits = 0.0f;
				const float f1 = _MaskStats(m, sp, ty, bits);
				_hDpMask = m; _hDpSpans = sp; _hDpTypes = ty; _hDpBits = bits; _hDpF1 = f1;
			}

			// ② β sweep — 손잡이가 DP 안에서도 사나.
			const float betas[6] = { 0.0f, 2.0f, 4.0f, 8.0f, 16.0f, 32.0f };
			for (uint32 b = 0; b < 6u; ++b)
			{
				Array<uint8> m = _DpSegment(betas[b]);
				uint32 sp = 0, ty = 0; float bits = 0.0f;
				_hBetaF1[b] = _MaskStats(m, sp, ty, bits);
				_hBetaN[b] = sp;
				LogA("[ml]   β=%-5.1f bit → 심볼 %4u · 종류 %3u · DL %7.0f bit · F1 %.4f\n",
					(double)betas[b], sp, ty, (double)bits, (double)_hBetaF1[b]);
			}
			if (!_SetupHead()) { _hStage = 4; return; }
			_hStep = 0;
			_hStage = 2;
			LogA("[ml]   🧠 인과적 머리 학습 시작 — ctx(dim %u · 표는 **얼린다**) → 2분류 · %d스텝\n",
				kBDim, kHSteps);
			return;
		}

		if (_hStage == 2)
		{
			if (_hStep >= kHSteps)
			{
				_hStage = 3;
				if (!_DispatchHeadEval()) _hStage = 4;
				return;
			}
			for (int i = 0; i < kHPerFrame && _hStep < kHSteps; ++i)
			{
				if (!_DispatchHeadStep()) { _hStage = 4; return; }
				_hStep++;
			}
			return;
		}

		_hStage = 4;
		_JudgeHead();
	}

	// 🧮 **DP — 비용이 가장 작은 분할을 정확히 찾는다.** 후보(음절 경계)에서만 자른다.
	//   `f[k] = min_{j<k} ( f[j] + cost(node j → node k) )`
	//   ⚠️ 덩어리 길이를 `kHLmax` 로 제한한다(그러지 않으면 O(n²)이고, 낱말이 그보다 길지도 않다).
	Array<uint8> _DpSegment(float beta) const
	{
		const uint32 n = (uint32)_bEvalTok.Count();
		// 노드 = 자를 수 있는 자리. `nodes[0] = -1`(시작 앞) · 마지막은 `n-1`(끝).
		Array<int> nodes;
		nodes.Add(-1);
		Array<uint32> cand; _Candidates(cand);
		for (uint32 i = 0; i < (uint32)cand.Count(); ++i) nodes.Add((int)cand.Data()[i]);
		if (nodes.Data()[nodes.Count() - 1] != (int)(n - 1u)) nodes.Add((int)(n - 1u));
		const uint32 K = (uint32)nodes.Count();

		// 사전 = **모든 후보 부분문자열**(음절 경계에서 시작·끝 · `kHLmax` 이하) + 실제 빈도.
		//   ★ 여기서 시작해 EM 이 **가지치기**한다(위 ⚠️⚠️⚠️ 의 근거).
		Array<uint32> dS, dL, dC;
		_CountAllSpans(nodes, dS, dL, dC);

		Array<uint8> best;
		for (uint32 it = 0; it < kHIters; ++it)
		{
			// DP
			Array<float> f; f.Reset(K);
			Array<int> back; back.Reset(K);
			for (uint32 k = 0; k < K; ++k) { f.Data()[k] = 0.0f; back.Data()[k] = -1; }
			uint32 total = 0;
			for (uint32 i = 0; i < (uint32)dC.Count(); ++i) total += dC.Data()[i];
			if (total == 0u) total = 1u;

			for (uint32 k = 1; k < K; ++k)
			{
				float bestC = 0.0f; int bestJ = -1;
				for (uint32 j = 0; j < k; ++j)
				{
					const uint32 s0 = (uint32)(nodes.Data()[j] + 1);
					const uint32 l0 = (uint32)(nodes.Data()[k] - nodes.Data()[j]);
					if (l0 == 0u || l0 > kHLmax) continue;
					if (back.Data()[j] < 0 && j > 0u) continue;   // 닿을 수 없는 노드
					const float c = f.Data()[j] + _ChunkCost(s0, l0, dS, dL, dC, total) + beta;
					if (bestJ < 0 || c < bestC) { bestC = c; bestJ = (int)j; }
				}
				f.Data()[k] = bestC;
				back.Data()[k] = bestJ;
			}

			// 되짚어 마스크를 만든다.
			Array<uint8> m; m.Reset(n);
			for (uint32 i = 0; i < n; ++i) m.Data()[i] = 0u;
			int k = (int)K - 1;
			while (k > 0 && back.Data()[(uint32)k] >= 0)
			{
				m.Data()[(uint32)nodes.Data()[(uint32)k]] = 1u;
				k = back.Data()[(uint32)k];
			}
			best = m;
			// 재추정 — ★ **후보 목록은 그대로 두고 빈도만** 갈아 끼운다(+1 스무딩으로 전부 살려 둔다).
			//   ⚠️ 쓰인 것만 남기면 다음 반복에서 그것들만 고를 수 있어 **붕괴**한다.
			Array<uint32> uS, uL, uC;
			_CountFrom(m, uS, uL, uC);
			for (uint32 i = 0; i < (uint32)dC.Count(); ++i)
			{
				uint32 used = 0;
				for (uint32 k2 = 0; k2 < (uint32)uS.Count(); ++k2)
				{
					if (uL.Data()[k2] != dL.Data()[i]) continue;
					bool same = true;
					for (uint32 j2 = 0; j2 < dL.Data()[i] && same; ++j2)
						if (_bEvalTok.Data()[uS.Data()[k2] + j2]
							!= _bEvalTok.Data()[dS.Data()[i] + j2]) same = false;
					if (same) { used = uC.Data()[k2]; break; }
				}
				dC.Data()[i] = used + 1u;
			}
		}
		return best;
	}

	// 📚 **모든 후보 부분문자열 + 실제 빈도.** 음절 경계에서 시작하고 끝나며 길이 ≤ `kHLmax`.
	//   ★ 이것이 EM 의 **출발 사전**이다 — 낱말이 여기 이미 들어 있고, 가지치기가 나머지를 걷어낸다.
	//   ⚠️ 손으로 훑어 중복을 합친다(후보 수천 개라 감당된다 · 결정적이어야 한다).
	void _CountAllSpans(const Array<int>& nodes, Array<uint32>& oS, Array<uint32>& oL,
		Array<uint32>& oC) const
	{
		oS.Reset(0); oL.Reset(0); oC.Reset(0);
		const uint32 K = (uint32)nodes.Count();
		for (uint32 j = 0; j + 1u < K; ++j)
			for (uint32 k = j + 1u; k < K; ++k)
			{
				const uint32 s0 = (uint32)(nodes.Data()[j] + 1);
				const uint32 l0 = (uint32)(nodes.Data()[k] - nodes.Data()[j]);
				if (l0 == 0u) continue;
				if (l0 > kHLmax) break;
				int hit = -1;
				for (uint32 i = 0; i < (uint32)oS.Count() && hit < 0; ++i)
				{
					if (oL.Data()[i] != l0) continue;
					bool same = true;
					for (uint32 j2 = 0; j2 < l0 && same; ++j2)
						if (_bEvalTok.Data()[s0 + j2] != _bEvalTok.Data()[oS.Data()[i] + j2]) same = false;
					if (same) hit = (int)i;
				}
				if (hit >= 0) oC.Data()[(uint32)hit]++;
				else { oS.Add(s0); oL.Add(l0); oC.Add(1u); }
			}
	}

	// 덩어리 하나의 비용(bit). 사전에 있으면 `-log2 P`, 없으면 `(len+1)×8`(사전에 새로 적는다).
	float _ChunkCost(uint32 s0, uint32 l0, const Array<uint32>& dS, const Array<uint32>& dL,
		const Array<uint32>& dC, uint32 total) const
	{
		for (uint32 i = 0; i < (uint32)dS.Count(); ++i)
		{
			if (dL.Data()[i] != l0) continue;
			bool same = true;
			for (uint32 j = 0; j < l0 && same; ++j)
				if (_bEvalTok.Data()[s0 + j] != _bEvalTok.Data()[dS.Data()[i] + j]) same = false;
			if (same)
			{
				const float pr = (float)dC.Data()[i] / (float)total;
				return -Log(pr) / Log(2.0f);
			}
		}
		return (float)(l0 + 1u) * 8.0f;
	}

	// 마스크 → 사전(대표 시작·길이·개수).
	void _CountFrom(const Array<uint8>& mask, Array<uint32>& oS, Array<uint32>& oL,
		Array<uint32>& oC) const
	{
		oS.Reset(0); oL.Reset(0); oC.Reset(0);
		const uint32 n = (uint32)_bEvalTok.Count();
		uint32 s0 = 0;
		for (uint32 t = 0; t < n; ++t)
		{
			if (mask.Data()[t] == 0u && t + 1u < n) continue;
			const uint32 l0 = t + 1u - s0;
			int hit = -1;
			for (uint32 i = 0; i < (uint32)oS.Count() && hit < 0; ++i)
			{
				if (oL.Data()[i] != l0) continue;
				bool same = true;
				for (uint32 j = 0; j < l0 && same; ++j)
					if (_bEvalTok.Data()[s0 + j] != _bEvalTok.Data()[oS.Data()[i] + j]) same = false;
				if (same) hit = (int)i;
			}
			if (hit >= 0) oC.Data()[(uint32)hit]++;
			else { oS.Add(s0); oL.Add(l0); oC.Add(1u); }
			s0 = t + 1u;
		}
	}

	// 마스크의 심볼수·종류·DL(bit)·F1(정답 낱말 대비).
	float _MaskStats(const Array<uint8>& mask, uint32& spans, uint32& types, float& bits) const
	{
		const MdlPoint pt = _MdlOf(mask, 0.0f);
		spans = pt.spans; types = pt.types; bits = pt.dl;
		return pt.f1;
	}

	bool _SetupHead()
	{
		if (_hDpMask.Count() == 0u) { LogA("[ml] 머리: DP 마스크가 없다\n"); return false; }
		// onehot(2분류) — `[0]=아니다 · [1]=경계다`. ⚠️ 학습 구간은 앞 반쪽이 아니라 **전체 시퀀스**의
		//   ctx 를 쓰지만(`_tBCtx` 가 그것이다) 평가는 **다른 코퍼스**(`_tBECtx`)라 누출이 없다.
		Array<float> one;
		one.Reset((uint64)_bSeq * 2ull);
		for (uint32 t = 0; t < _bSeq; ++t)
		{
			// ⚠️ 학습 라벨은 **학습 코퍼스**의 DP 경계여야 한다 → 학습 코퍼스에도 DP 를 돌린다.
			one.Data()[(uint64)t * 2ull + 0ull] = 1.0f;
			one.Data()[(uint64)t * 2ull + 1ull] = 0.0f;
		}
		Array<uint8> trMask = _DpSegmentOn(_bTrainTok, 0.0f);
		for (uint32 t = 0; t < _bSeq && t < (uint32)trMask.Count(); ++t)
			if (trMask.Data()[t] != 0u)
			{ one.Data()[(uint64)t * 2ull + 0ull] = 0.0f; one.Data()[(uint64)t * 2ull + 1ull] = 1.0f; }

		SeedRand(MLEpisodeGen::ScrambleSeed(8800u));
		Array<float> w;
		w.Reset((uint64)kBDim * 2ull);
		for (uint64 i = 0; i < w.Count(); ++i)
			w.Data()[i] = ((float)RandInt(0, 2001) * 0.001f - 1.0f) * (0.4f / (float)kBDim);
		if (!_bnd.Write(_tHOne, one) || !_bnd.Write(_tHW, w))
		{ LogA("[ml] 머리: 업로드 실패\n"); return false; }
		if (!_ZeroB(_tHMW) || !_ZeroB(_tHVW))
		{ LogA("[ml] 머리: 모멘트 초기화 실패\n"); return false; }
		return true;
	}

	// 학습 코퍼스에도 같은 DP 를 돌린다(라벨용). ⚠️ 코퍼스가 달라 함수를 나눈다 — 같은 비용식이다.
	Array<uint8> _DpSegmentOn(const Array<float>& tok, float beta) const
	{
		// ★ `_DpSegment` 와 같은 알고리즘을 다른 코퍼스에 적용한다. 구현을 나누지 않으려고
		//   임시로 코퍼스를 바꿔 끼우는 대신, 여기서는 **간단한 판**을 쓴다: 평가 코퍼스에서 얻은
		//   사전으로 학습 코퍼스를 DP 한다(사전은 낱말 목록이라 코퍼스가 달라도 통한다).
		Array<uint32> dS, dL, dC;
		_CountFrom(_hDpMask, dS, dL, dC);
		uint32 total = 0;
		for (uint32 i = 0; i < (uint32)dC.Count(); ++i) total += dC.Data()[i];
		if (total == 0u) total = 1u;

		const uint32 n = (uint32)tok.Count();
		Array<int> nodes;
		nodes.Add(-1);
		for (uint32 t = 0; t + 1u < n; ++t)
			if (_IsLead((uint8)tok.Data()[t + 1u])) nodes.Add((int)t);
		if (nodes.Data()[nodes.Count() - 1] != (int)(n - 1u)) nodes.Add((int)(n - 1u));
		const uint32 K = (uint32)nodes.Count();

		Array<float> f; f.Reset(K);
		Array<int> back; back.Reset(K);
		for (uint32 k = 0; k < K; ++k) { f.Data()[k] = 0.0f; back.Data()[k] = -1; }
		for (uint32 k = 1; k < K; ++k)
		{
			float bestC = 0.0f; int bestJ = -1;
			for (uint32 j = 0; j < k; ++j)
			{
				const uint32 s0 = (uint32)(nodes.Data()[j] + 1);
				const uint32 l0 = (uint32)(nodes.Data()[k] - nodes.Data()[j]);
				if (l0 == 0u || l0 > kHLmax) continue;
				if (back.Data()[j] < 0 && j > 0u) continue;
				// 사전 조회는 **평가 코퍼스의 바이트**로 견주므로, 여기서는 학습 코퍼스 조각을 직접 비교한다.
				float cost = (float)(l0 + 1u) * 8.0f;
				for (uint32 i = 0; i < (uint32)dS.Count(); ++i)
				{
					if (dL.Data()[i] != l0) continue;
					bool same = true;
					for (uint32 j2 = 0; j2 < l0 && same; ++j2)
						if (tok.Data()[s0 + j2] != _bEvalTok.Data()[dS.Data()[i] + j2]) same = false;
					if (same) { cost = -Log((float)dC.Data()[i] / (float)total) / Log(2.0f); break; }
				}
				const float c = f.Data()[j] + cost + beta;
				if (bestJ < 0 || c < bestC) { bestC = c; bestJ = (int)j; }
			}
			f.Data()[k] = bestC;
			back.Data()[k] = bestJ;
		}
		Array<uint8> m; m.Reset(n);
		for (uint32 i = 0; i < n; ++i) m.Data()[i] = 0u;
		int k = (int)K - 1;
		while (k > 0 && back.Data()[(uint32)k] >= 0)
		{
			m.Data()[(uint32)nodes.Data()[(uint32)k]] = 1u;
			k = back.Data()[(uint32)k];
		}
		return m;
	}

	// 한 스텝 = 디스패치 다섯. ★ 표를 **얼렸으므로** `ctx_embed_bwd` 가 없다(선형 판독만 배운다).
	bool _DispatchHeadStep()
	{
		MLGemmParams g;
		g.aOff = _tBCtx.offset; g.bOff = _tHW.offset; g.cOff = _tHLogit.offset;
		g.M = _bSeq; g.N = 2u; g.K = kBDim;
		if (!_bGemm.Dispatch(2u, _bSeq, 1u, &g, (uint32)sizeof(g))) return _Fail("head logits");

		MLSoftmaxParams sm;
		sm.inOff = _tHLogit.offset; sm.outOff = _tHProb.offset; sm.rows = _bSeq; sm.cols = 2u;
		if (!_bSoft.Dispatch(_bSeq, 1u, 1u, &sm, (uint32)sizeof(sm))) return _Fail("head softmax");

		MLSubParams sb;
		sb.aOff = _tHProb.offset; sb.bOff = _tHOne.offset; sb.outOff = _tHDLogit.offset;
		sb.count = _bSeq * 2u;
		if (!_bSub.Dispatch(sb.count, 1u, 1u, &sb, (uint32)sizeof(sb))) return _Fail("head dlogits");

		MLGemmParams gw;
		gw.aOff = _tBCtx.offset; gw.bOff = _tHDLogit.offset; gw.cOff = _tHDW.offset;
		gw.M = kBDim; gw.N = 2u; gw.K = _bSeq; gw.transA = 1;
		if (!_bGemm.Dispatch(2u, kBDim, 1u, &gw, (uint32)sizeof(gw))) return _Fail("head dW");

		float bc1 = 1.0f, bc2 = 1.0f;
		_BiasCorr(_hStep + 1, bc1, bc2);
		MLAdamWParams aw;
		aw.lr = kHLr; aw.beta1 = kB1; aw.beta2 = kB2; aw.eps = kAdamEps; aw.wd = kWd;
		aw.bc1 = bc1; aw.bc2 = bc2;
		aw.pOff = _tHW.offset;  aw.gOff = _tHDW.offset;
		aw.mOff = _tHMW.offset; aw.vOff = _tHVW.offset; aw.count = _tHW.Count();
		if (!_bAdam.Dispatch(aw.count, 1u, 1u, &aw, (uint32)sizeof(aw))) return _Fail("head adamw");
		return true;
	}

	// 📏 평가 — **다른 코퍼스**(`_tBECtx`)에 forward 만.
	bool _DispatchHeadEval()
	{
		MLGemmParams g;
		g.aOff = _tBECtx.offset; g.bOff = _tHW.offset; g.cOff = _tHELogit.offset;
		g.M = _bESeq; g.N = 2u; g.K = kBDim;
		if (!_bGemm.Dispatch(2u, _bESeq, 1u, &g, (uint32)sizeof(g))) return _Fail("head eval logits");

		MLSoftmaxParams sm;
		sm.inOff = _tHELogit.offset; sm.outOff = _tHEProb.offset;
		sm.rows = _bESeq; sm.cols = 2u;
		if (!_bSoft.Dispatch(_bESeq, 1u, 1u, &sm, (uint32)sizeof(sm))) return _Fail("head eval softmax");
		return true;
	}

	void _JudgeHead()
	{
		Bytes bp;
		if (!_bnd.Read(_tHEProb, bp) || bp.GetSize() < (uint64)_bESeq * 2ull * sizeof(float))
		{ LogA("[ml] 머리: 평가 회수가 안 됐다\n"); return; }
		const float* pr = (const float*)bp.GetData();

		// 머리가 고른 경계 = `p(경계) > 0.5` 인 **후보** 자리. ★ 문턱이 아니라 **분류 결정**이다
		//   (0.5 는 두 분류의 자연스러운 경계이고 조절값이 아니다).
		Array<uint8> hm; hm.Reset(_bEvalTok.Count());
		for (uint32 i = 0; i < (uint32)hm.Count(); ++i) hm.Data()[i] = 0u;
		Array<uint32> cand; _Candidates(cand);
		uint32 agree = 0, nAgree = 0;
		for (uint32 i = 0; i < (uint32)cand.Count(); ++i)
		{
			const uint32 t = cand.Data()[i];
			if (t >= _bESeq) continue;
			const bool p = (pr[(uint64)t * 2ull + 1ull] > 0.5f);
			if (p) hm.Data()[t] = 1u;
			nAgree++;
			if (p == (_hDpMask.Data()[t] != 0u)) agree++;
		}
		_hHeadAcc = (nAgree > 0u) ? (100.0f * (float)agree / (float)nAgree) : 0.0f;
		uint32 sp = 0, ty = 0; float bits = 0.0f;
		_hHeadF1Truth = _MaskStats(hm, sp, ty, bits);

		// DP 대비 F1(머리가 DP 를 얼마나 재현하나).
		{
			uint32 tp = 0, pd = 0, gt = 0;
			for (uint32 i = 0; i < (uint32)cand.Count(); ++i)
			{
				const uint32 t = cand.Data()[i];
				const bool p = (hm.Data()[t] != 0u), g = (_hDpMask.Data()[t] != 0u);
				if (p) pd++; if (g) gt++; if (p && g) tp++;
			}
			const float pc = (pd > 0u) ? ((float)tp / (float)pd) : 0.0f;
			const float rc = (gt > 0u) ? ((float)tp / (float)gt) : 0.0f;
			_hHeadF1Dp = ((pc + rc) > 0.0f) ? (2.0f * pc * rc / (pc + rc)) : 0.0f;
		}

		LogA("\n[ml] 🧠 **P3-c 표** — 경계를 **문턱 없이** 정한다\n"
			"[ml]   %-22s %8s %7s %10s %8s\n", "방법", "심볼수", "종류", "DL(bit)", "F1(정답)");
		LogA("[ml]   %-22s %8u %7u %10.0f %8.4f  ← 목적함수가 정함(오라클 없음)\n",
			"DP+EM (β=0)", _hDpSpans, _hDpTypes, (double)_hDpBits, (double)_hDpF1);
		LogA("[ml]   %-22s %8u %7u %10.0f %8.4f  ← **인과적** 머리(과거만 본다)\n",
			"학습된 경계 머리", sp, ty, (double)bits, (double)_hHeadF1Truth);
		LogA("[ml]   %-22s %8s %7s %10s %8.4f  (참고: P3-a 의 문턱 최선)\n",
			"H 문턱 최선(P3-a)", "201", "23", "2797", 0.8309);
		LogA("[ml]   머리 vs DP: 일치 %.1f%% · F1 %.4f\n", (double)_hHeadAcc, (double)_hHeadF1Dp);

		LogA("[ml]\n[ml]   β 손잡이(DP 안에서) — 심볼 수가 움직여야 한다\n"
			"[ml]   %-10s %9s %9s\n", "β(bit)", "심볼수", "F1");
		const float betas[6] = { 0.0f, 2.0f, 4.0f, 8.0f, 16.0f, 32.0f };
		bool monoN = true, moved = false;
		for (uint32 b = 0; b < 6u; ++b)
		{
			LogA("[ml]   %-10.1f %9u %9.4f\n", (double)betas[b], _hBetaN[b], (double)_hBetaF1[b]);
			if (b > 0u)
			{
				if (_hBetaN[b] > _hBetaN[b - 1u]) monoN = false;
				if (_hBetaN[b] != _hBetaN[b - 1u]) moved = true;
			}
		}

		// ★ **기준은 측정 전에 정했다.**
		//   ㉠ DP 가 문턱보다 낫다: DP 의 F1 > P3-a 의 문턱 최선(0.8309)
		//   ㉡ 개수를 스스로 정한다: DP 심볼 수가 정답(141)의 ±25% 안
		//   ㉢ **인과적 머리가 DP 를 배운다**: 머리 vs DP 일치 ≥ 90%
		//   ㉣ β 손잡이가 DP 안에서도 산다(심볼 수가 뒤집히지 않고 움직인다)
		uint32 truthSp = 0;
		{
			const uint32 n2 = (uint32)_bEvalTok.Count();
			uint32 s1 = 0;
			for (uint32 t = 0; t < n2; ++t)
				if (_bEvalBnd.Data()[t] != 0u) { truthSp++; s1 = t + 1u; }
			if (s1 < n2) truthSp++;
		}
		const float ratio = (truthSp > 0u) ? ((float)_hDpSpans / (float)truthSp) : 0.0f;
		const bool okDp = (_hDpF1 > 0.8309f);
		const bool okCnt = (ratio > 0.75f) && (ratio < 1.25f);
		const bool okHead = (_hHeadAcc >= 90.0f);
		const bool okBeta = monoN && moved;
		LogA("[ml] P3-c 판정: %s\n"
			"[ml]   ㉠ **DP 가 문턱보다 낫다**: F1 %.4f vs 문턱 최선 0.8309 → %s\n"
			"[ml]      ★ 문턱은 **1파라미터 족**만 훑는다. DP 는 **모든 분할**에서 최소를 찾는다.\n"
			"[ml]   ㉡ **개수를 스스로 정한다**: 심볼 %u개 vs 정답 %u개(비 %.2f) → %s\n"
			"[ml]   ㉢ ★ **인과적 머리가 DP 를 배운다**: 일치 %.1f%% (기준 ≥90) → %s\n"
			"[ml]      ★ DP 는 **전체를 보고** 머리는 **과거만 본다** — 그래서 이것이 *\"생성 시점에도\n"
			"[ml]        같은 경계를 낼 수 있나\"*(함정 1)의 답이다.\n"
			"[ml]   ㉣ **β 손잡이가 DP 안에서도 산다**: 뒤집힘 %s · 움직임 %s\n",
			(okDp && okCnt && okHead && okBeta) ? "통과" : "★실패★",
			(double)_hDpF1, okDp ? "통과" : "★실패★",
			_hDpSpans, truthSp, (double)ratio, okCnt ? "통과" : "★실패★",
			(double)_hHeadAcc, okHead ? "통과" : "★실패★",
			monoN ? "통과" : "★실패★", moved ? "통과" : "★실패★");
		LogA("[ml]   ⚠️ **범위**: 머리는 **선형 판독**이고 표(ctx)는 **얼렸다** — 표현을 같이 학습시키면\n"
			"[ml]      더 오를 수 있다. 여기서 잰 것은 *\"이미 있는 표현에서 DP 경계가 인과적으로 읽히나\"* 다.\n");
	}

	// ── ⚖️ **P3-b · β 손잡이** — 압축항이 두 항을 정말 움직이나 ──────────────────────────────
	//
	// ★ **부호를 먼저 못박는다.** `L = L_recon + β·N` 에서 `β↑ ⇒ N↓ ⇒ L_recon↑` 이 성립하려면
	//   **심볼 용량이 걸려야** 한다 — 심볼 dim 이 고정인데 덩어리가 길어지면 담을 것이 늘어나니까.
	//   ⚠️⚠️ P2-c 는 dim 24 에서 **복원 100%** 였다 = **용량이 안 걸렸다** ⇒ 그 설정으로는 절충이
	//     아예 안 보인다(β 를 어떻게 줘도 `L_recon` 이 안 움직인다). ★ 그래서 여기서는 **dim 을 작게** 둔다.
	//   ★ 이것이 이 실험의 전제이고, 전제가 틀리면 판정이 무의미해지므로 **용량이 걸렸는지도 같이 찍는다.**
	//
	// ⚠️⚠️ **범위를 분명히 한다 — 이것은 미분 가능한 경계망이 아니다.**
	//   경계는 여전히 `H` 문턱 τ 로 정하고, 여기서 재는 것은 *"MDL 손잡이가 두 항을 움직이나"* 다
	//   (= P3 의 기록된 판정 그대로). 미분 가능판(경계 확률 머리 + `N = Σpᵢ` + straight-through)은
	//   그 다음이고, ★ **그 전에 손잡이가 작동하는지 보는 것이 순서다**(P3-a 와 같은 이유).
	//
	// ★ τ 는 **경계 개수로** 고른다(균등 τ 격자보다 N 범위를 통제하기 쉽다) — 후보의 H 를 내림차순으로
	//   정렬해 `n_k` 번째 값을 τ 로 쓴다.
	int      _pbStage = 0;
	MLArena  _mdlA;
	MLKernel _pbSpan, _pbSpanB, _pbGemm, _pbSoft, _pbSub, _pbAdam;

	// ⚠️ 용량을 **걸리게** 만드는 값이다(P2-c 의 24 가 아니다).
	static constexpr uint32 kEDim = 6, kEMaxLen = 16, kEVoc = 257, kEMaxSpans = 400;
	// ⚠️ 300스텝에서는 변동이 **"용량 압박"인지 "덜 배움"인지 안 갈렸다**(실측) → 늘리고 수렴을 잰다.
	static constexpr int    kESteps = 700, kEPerFrame = 4;
	static constexpr float  kELr = 0.05f;
	static constexpr uint32 kETaus = 8;

	MLTensor _uTok, _uStart, _uLen, _uOne, _uSlot, _uW, _uSym;
	MLTensor _uLogit, _uProb, _uDLogit, _uDSym, _uDSlot, _uDW, _uMS, _uVS, _uMW, _uVW;
	MLTensor _uEStart, _uELen, _uESym, _uELogit, _uEProb;

	Array<float> _uTrS, _uTrL, _uEvS, _uEvL;
	uint32 _uTrSpans = 0, _uEvSpans = 0, _uEvBytes = 0, _uHalf = 0;
	int    _pbPoint = 0, _pbStep = 0;
	// ★ **척도는 `바이트 오류율(%)`이다 — CE 가 아니다.**
	//   ⚠️⚠️ 실측으로 **함정 19 를 또 밟았다**: CE 로 재니 바이트 92.7% 인 점이 `0.99`, 95.6% 인 점이
	//     `0.59` 로 **정확도와 순서가 뒤집혔다**(포화된 소수 오답이 평균 CE 를 지배한다).
	//   ⇒ `L_recon` = **못 맞힌 바이트 비율**. 포화에 안 흔들리고 "몇 바이트를 잃었나" 라는 뜻이 분명하다.
	//   ★ 그리고 **학습 오류율도 같이** 잰다 — 그것이 없으면 곡선의 울퉁불퉁이 용량 압박인지
	//     수렴 부족인지 안 갈린다(P2-b1 에서 세운 그 세 갈래 판정).
	float  _pbTau[kETaus] = {}, _pbRecon[kETaus] = {}, _pbTrErr[kETaus] = {};
	uint32 _pbN[kETaus] = {}, _pbTypes[kETaus] = {}, _pbTrunc[kETaus] = {};

	void _TickBeta()
	{
		if (_pbStage >= 4) return;

		if (_pbStage == 0)
		{
			_pbStage = 1;
			if (!_SetupBeta()) { _pbStage = 4; return; }
			_pbPoint = 0;
			if (!_StartBetaPoint(0)) { _pbStage = 4; return; }
			_pbStage = 2;
			return;
		}

		if (_pbStage == 2)
		{
			if (_pbStep >= kESteps)
			{
				_pbStage = 3;
				if (!_DispatchBetaEval()) _pbStage = 4;
				return;
			}
			// ⚠️ 스텝 마커는 **덩어리마다 한 번**만 찍는다(라인 flush 라 매 스텝은 디스크를 때린다).
			for (int i = 0; i < kEPerFrame && _pbStep < kESteps; ++i)
			{
				if (!_DispatchBetaStep()) { _pbStage = 4; return; }
				_pbStep++;
			}
			return;
		}

		if (!_RecordBetaPoint()) { _pbStage = 4; return; }
		if (_pbPoint + 1 < (int)kETaus)
		{
			_pbPoint++;
			if (!_StartBetaPoint(_pbPoint)) { _pbStage = 4; return; }
			_pbStage = 2;
			return;
		}
		_pbStage = 4;
		_JudgeBeta();
	}

	// 🔢 후보의 H 를 내림차순으로 봤을 때 `want` 번째 값 = 경계가 `want` 개 되는 문턱.
	float _TauForCount(uint32 want) const
	{
		const Array<float>& H = _bH[kBArms - 1u];
		Array<float> v;
		Array<uint32> cand; _Candidates(cand);
		for (uint32 i = 0; i < (uint32)cand.Count(); ++i)
		{
			const uint32 t = cand.Data()[i];
			if (t < (uint32)H.Count()) v.Add(H.Data()[t]);
		}
		if (v.Count() == 0u) return 0.0f;
		// 내림차순 선택(부분 정렬). ⚠️ 후보가 수백 개라 이 단순함이 값싸다.
		uint32 lim = (want < (uint32)v.Count()) ? want : (uint32)v.Count();
		if (lim == 0u) lim = 1u;
		for (uint32 a = 0; a < lim; ++a)
		{
			uint32 best = a;
			for (uint32 b = a + 1u; b < (uint32)v.Count(); ++b)
				if (v.Data()[b] > v.Data()[best]) best = b;
			const float tmp = v.Data()[a]; v.Data()[a] = v.Data()[best]; v.Data()[best] = tmp;
		}
		return v.Data()[lim - 1u];
	}

	// τ 로 `[lo, hi)` 를 자른다.
	void _ChunkByTau(float tau, uint32 lo, uint32 hi, Array<float>& st, Array<float>& ln) const
	{
		const Array<float>& H = _bH[kBArms - 1u];
		st.Reset(0); ln.Reset(0);
		uint32 s0 = lo;
		for (uint32 t = lo; t < hi; ++t)
		{
			if (t + 1u >= hi) break;
			if (!_IsLead((uint8)_bEvalTok.Data()[t + 1u])) continue;
			if (t >= (uint32)H.Count() || H.Data()[t] < tau) continue;
			st.Add((float)s0); ln.Add((float)(t + 1u - s0)); s0 = t + 1u;
		}
		if (s0 < hi) { st.Add((float)s0); ln.Add((float)(hi - s0)); }
	}

	bool _SetupBeta()
	{
		const uint32 n = (uint32)_bEvalTok.Count();
		if (n < 64u || _bH[kBArms - 1u].Count() == 0u)
		{ LogA("[ml] β: 경계망 결과가 없다\n"); return false; }
		_uHalf = n / 2u;
		while (_uHalf + 1u < n && _bEvalBnd.Data()[_uHalf] == 0u) _uHalf++;
		_uHalf++;
		_uEvBytes = n - _uHalf;

		const uint32 outW = kEMaxLen * kEVoc;
		const uint32 need =
			n + kEMaxSpans * 4u
			+ kEMaxSpans * outW * 4u              // onehot · logits · probs · dLogits(학습)
			+ kEMaxSpans * outW * 2u              // logits · probs(평가)
			+ kEMaxLen * kEVoc * kEDim * 4u       // slot · dSlot · m · v
			+ kEDim * outW * 4u                   // W · dW · m · v
			+ kEMaxSpans * kEDim * 3u + 256u;
		if (!_mdlA.Create(rhi, need))
		{ LogA("[ml] β: 아레나 생성 실패(%u floats)\n", need); return false; }

		_uTok    = _mdlA.Alloc(1, n);
		_uStart  = _mdlA.Alloc(1, kEMaxSpans);
		_uLen    = _mdlA.Alloc(1, kEMaxSpans);
		_uEStart = _mdlA.Alloc(1, kEMaxSpans);
		_uELen   = _mdlA.Alloc(1, kEMaxSpans);
		_uSlot   = _mdlA.Alloc(kEMaxLen * kEVoc, kEDim);
		_uW      = _mdlA.Alloc(kEDim, outW);
		_uSym    = _mdlA.Alloc(kEMaxSpans, kEDim);
		_uOne    = _mdlA.Alloc(kEMaxSpans * kEMaxLen, kEVoc);
		_uLogit  = _mdlA.Alloc(kEMaxSpans * kEMaxLen, kEVoc);
		_uProb   = _mdlA.Alloc(kEMaxSpans * kEMaxLen, kEVoc);
		_uDLogit = _mdlA.Alloc(kEMaxSpans * kEMaxLen, kEVoc);
		_uDSym   = _mdlA.Alloc(kEMaxSpans, kEDim);
		_uDSlot  = _mdlA.Alloc(kEMaxLen * kEVoc, kEDim);
		_uDW     = _mdlA.Alloc(kEDim, outW);
		_uMS     = _mdlA.Alloc(kEMaxLen * kEVoc, kEDim);
		_uVS     = _mdlA.Alloc(kEMaxLen * kEVoc, kEDim);
		_uMW     = _mdlA.Alloc(kEDim, outW);
		_uVW     = _mdlA.Alloc(kEDim, outW);
		_uESym   = _mdlA.Alloc(kEMaxSpans, kEDim);
		_uELogit = _mdlA.Alloc(kEMaxSpans * kEMaxLen, kEVoc);
		_uEProb  = _mdlA.Alloc(kEMaxSpans * kEMaxLen, kEVoc);
		if (!_uEProb.IsValid()) { LogA("[ml] β: 텐서 할당 실패(아레나 부족)\n"); return false; }
		if (!_mdlA.Write(_uTok, _bEvalTok))
		{ LogA("[ml] β: 코퍼스 업로드 실패\n"); return false; }

		if (!_LoadKernelIn(_pbSpan,  "shaders/span_embed.cs.spv",     _mdlA)) return false;
		if (!_LoadKernelIn(_pbSpanB, "shaders/span_embed_bwd.cs.spv", _mdlA)) return false;
		if (!_LoadKernelIn(_pbGemm,  "shaders/gemm.cs.spv",           _mdlA)) return false;
		if (!_LoadKernelIn(_pbSoft,  "shaders/softmax.cs.spv",        _mdlA)) return false;
		if (!_LoadKernelIn(_pbSub,   "shaders/sub.cs.spv",            _mdlA)) return false;
		if (!_LoadKernelIn(_pbAdam,  "shaders/adamw.cs.spv",          _mdlA)) return false;

		LogA("\n[ml] ⚖️ **P3-b · β 손잡이** — 심볼 dim **%u**(용량이 걸리게 작다) · 자리 최대 %u\n"
			"[ml]   ⚠️ P2-c 는 dim 24 에서 복원 100%% 였다 = 용량이 안 걸렸다 → 그 설정으론 절충이 안 보인다\n"
			"[ml]   τ 격자 %u개(경계 개수로 고른다) · 점마다 %d스텝 · 평가는 안 본 뒤 반쪽(%u바이트)\n",
			kEDim, kEMaxLen, kETaus, kESteps, _uEvBytes);
		return true;
	}

	bool _StartBetaPoint(int idx)
	{
		// 경계 개수 격자 — 많이 자르는 쪽부터 적게 자르는 쪽으로.
		const uint32 wants[kETaus] = { 600u, 460u, 380u, 300u, 250u, 200u, 165u, 130u };
		const uint32 n = (uint32)_bEvalTok.Count();
		_pbStep = 0;
		_pbTau[idx] = _TauForCount(wants[idx]);
		_ChunkByTau(_pbTau[idx], 0u, _uHalf, _uTrS, _uTrL);
		_ChunkByTau(_pbTau[idx], _uHalf, n, _uEvS, _uEvL);
		_uTrSpans = (uint32)_uTrS.Count();
		_uEvSpans = (uint32)_uEvS.Count();
		if (_uTrSpans == 0u || _uEvSpans == 0u
			|| _uTrSpans > kEMaxSpans || _uEvSpans > kEMaxSpans)
		{ LogA("[ml] β: 구간 수가 이상하다(%u / %u)\n", _uTrSpans, _uEvSpans); return false; }
		_pbN[idx] = _uEvSpans;

		// ⚠️ `kEMaxLen` 을 넘는 구간은 **잘린다** — 세서 표에 적는다(조용히 넘기지 않는다).
		_pbTrunc[idx] = 0u;
		for (uint32 c = 0; c < _uEvSpans; ++c) if ((uint32)_uEvL.Data()[c] > kEMaxLen) _pbTrunc[idx]++;
		_pbTypes[idx] = _BetaTypes();

		if (!_mdlA.Write(_uStart, _uTrS) || !_mdlA.Write(_uLen, _uTrL)
			|| !_mdlA.Write(_uEStart, _uEvS) || !_mdlA.Write(_uELen, _uEvL))
		{ LogA("[ml] β: 구간 업로드 실패\n"); return false; }

		Array<float> one;
		one.Reset((uint64)_uTrSpans * kEMaxLen * kEVoc);
		for (uint64 i = 0; i < one.Count(); ++i) one.Data()[i] = 0.0f;
		for (uint32 c = 0; c < _uTrSpans; ++c)
		{
			const uint32 s0 = (uint32)_uTrS.Data()[c];
			uint32 l0 = (uint32)_uTrL.Data()[c];
			if (l0 > kEMaxLen) l0 = kEMaxLen;
			for (uint32 j = 0; j < kEMaxLen; ++j)
			{
				uint32 v = (j < l0) ? (uint32)_bEvalTok.Data()[s0 + j] : 256u;
				if (v >= kEVoc) v = 0u;
				one.Data()[((uint64)c * kEMaxLen + j) * kEVoc + v] = 1.0f;
			}
		}
		if (!_mdlA.Write(MLTensor{ _uOne.offset, _uTrSpans * kEMaxLen, kEVoc }, one))
		{ LogA("[ml] β: onehot 업로드 실패\n"); return false; }

		SeedRand(MLEpisodeGen::ScrambleSeed(7700u + (uint32)idx));
		Array<float> slot, w;
		slot.Reset((uint64)kEMaxLen * kEVoc * kEDim);
		for (uint64 i = 0; i < slot.Count(); ++i)
			slot.Data()[i] = ((float)RandInt(0, 2001) * 0.001f - 1.0f) * (0.4f / (float)kEMaxLen);
		w.Reset((uint64)kEDim * kEMaxLen * kEVoc);
		for (uint64 i = 0; i < w.Count(); ++i)
			w.Data()[i] = ((float)RandInt(0, 2001) * 0.001f - 1.0f) * (0.4f / (float)kEDim);
		if (!_mdlA.Write(_uSlot, slot) || !_mdlA.Write(_uW, w))
		{ LogA("[ml] β: 가중치 업로드 실패\n"); return false; }
		if (!_ZeroU(_uMS) || !_ZeroU(_uVS) || !_ZeroU(_uMW) || !_ZeroU(_uVW))
		{ LogA("[ml] β: 모멘트 초기화 실패\n"); return false; }

		LogA("[ml]   τ점 %d: τ=%.4f · 구간 학습 %u / 평가 %u · 종류 %u · 잘림 %u\n",
			idx, (double)_pbTau[idx], _uTrSpans, _uEvSpans, _pbTypes[idx], _pbTrunc[idx]);
		return true;
	}

	uint32 _BetaTypes() const
	{
		Array<uint32> rs, rl;
		for (int side = 0; side < 2; ++side)
		{
			const Array<float>& st = (side == 0) ? _uTrS : _uEvS;
			const Array<float>& ln = (side == 0) ? _uTrL : _uEvL;
			const uint32 nsp = (side == 0) ? _uTrSpans : _uEvSpans;
			for (uint32 c = 0; c < nsp; ++c)
			{
				const uint32 s0 = (uint32)st.Data()[c], l0 = (uint32)ln.Data()[c];
				bool dup = false;
				for (uint32 k = 0; k < (uint32)rs.Count() && !dup; ++k)
				{
					if (rl.Data()[k] != l0) continue;
					bool same = true;
					for (uint32 j = 0; j < l0 && same; ++j)
						if (_bEvalTok.Data()[s0 + j] != _bEvalTok.Data()[rs.Data()[k] + j]) same = false;
					if (same) dup = true;
				}
				if (!dup) { rs.Add(s0); rl.Add(l0); }
			}
		}
		return (uint32)rs.Count();
	}

	bool _ZeroU(const MLTensor& t)
	{
		Array<float> z;
		z.Reset(t.Count());
		for (uint32 i = 0; i < t.Count(); ++i) z.Data()[i] = 0.0f;
		return _mdlA.Write(t, z);
	}

	bool _DispatchBetaStep()
	{
		const uint32 outW = kEMaxLen * kEVoc;
		MLSpanEmbedParams e;
		e.tokOff = _uTok.offset; e.startOff = _uStart.offset; e.lenOff = _uLen.offset;
		e.aOff = _uSlot.offset; e.bOff = _uSym.offset;
		e.spans = _uTrSpans; e.maxLen = kEMaxLen; e.dim = kEDim;
		if (!_pbSpan.Dispatch(kEDim, _uTrSpans, 1u, &e, (uint32)sizeof(e))) return _Fail("beta sym");

		MLGemmParams g;
		g.aOff = _uSym.offset; g.bOff = _uW.offset; g.cOff = _uLogit.offset;
		g.M = _uTrSpans; g.N = outW; g.K = kEDim;
		if (!_pbGemm.Dispatch(outW, _uTrSpans, 1u, &g, (uint32)sizeof(g))) return _Fail("beta logits");

		MLSoftmaxParams sm;
		sm.inOff = _uLogit.offset; sm.outOff = _uProb.offset;
		sm.rows = _uTrSpans * kEMaxLen; sm.cols = kEVoc;
		if (!_pbSoft.Dispatch(sm.rows, 1u, 1u, &sm, (uint32)sizeof(sm))) return _Fail("beta softmax");

		MLSubParams sb;
		sb.aOff = _uProb.offset; sb.bOff = _uOne.offset; sb.outOff = _uDLogit.offset;
		sb.count = _uTrSpans * outW;
		if (!_pbSub.Dispatch(sb.count, 1u, 1u, &sb, (uint32)sizeof(sb))) return _Fail("beta dlogits");

		MLGemmParams gw;
		gw.aOff = _uSym.offset; gw.bOff = _uDLogit.offset; gw.cOff = _uDW.offset;
		gw.M = kEDim; gw.N = outW; gw.K = _uTrSpans; gw.transA = 1;
		if (!_pbGemm.Dispatch(outW, kEDim, 1u, &gw, (uint32)sizeof(gw))) return _Fail("beta dW");

		MLGemmParams gs;
		gs.aOff = _uDLogit.offset; gs.bOff = _uW.offset; gs.cOff = _uDSym.offset;
		gs.M = _uTrSpans; gs.N = kEDim; gs.K = outW; gs.transB = 1;
		if (!_pbGemm.Dispatch(kEDim, _uTrSpans, 1u, &gs, (uint32)sizeof(gs))) return _Fail("beta dSym");

		MLSpanEmbedParams eb;
		eb.tokOff = _uTok.offset; eb.startOff = _uStart.offset; eb.lenOff = _uLen.offset;
		eb.aOff = _uDSym.offset; eb.bOff = _uDSlot.offset;
		eb.spans = _uTrSpans; eb.maxLen = kEMaxLen; eb.dim = kEDim;
		if (!_pbSpanB.Dispatch(kEDim, eb.SlotRows(), 1u, &eb, (uint32)sizeof(eb)))
			return _Fail("beta dSlot");

		float bc1 = 1.0f, bc2 = 1.0f;
		_BiasCorr(_pbStep + 1, bc1, bc2);
		MLAdamWParams aw;
		aw.lr = kELr; aw.beta1 = kB1; aw.beta2 = kB2; aw.eps = kAdamEps; aw.wd = kWd;
		aw.bc1 = bc1; aw.bc2 = bc2;
		aw.pOff = _uSlot.offset; aw.gOff = _uDSlot.offset;
		aw.mOff = _uMS.offset;   aw.vOff = _uVS.offset;   aw.count = _uSlot.Count();
		if (!_pbAdam.Dispatch(aw.count, 1u, 1u, &aw, (uint32)sizeof(aw))) return _Fail("beta adamw slot");
		MLAdamWParams ax = aw;
		ax.pOff = _uW.offset;  ax.gOff = _uDW.offset;
		ax.mOff = _uMW.offset; ax.vOff = _uVW.offset; ax.count = _uW.Count();
		if (!_pbAdam.Dispatch(ax.count, 1u, 1u, &ax, (uint32)sizeof(ax))) return _Fail("beta adamw W");
		return true;
	}

	bool _DispatchBetaEval()
	{
		const uint32 outW = kEMaxLen * kEVoc;
		MLSpanEmbedParams e;
		e.tokOff = _uTok.offset; e.startOff = _uEStart.offset; e.lenOff = _uELen.offset;
		e.aOff = _uSlot.offset; e.bOff = _uESym.offset;
		e.spans = _uEvSpans; e.maxLen = kEMaxLen; e.dim = kEDim;
		if (!_pbSpan.Dispatch(kEDim, _uEvSpans, 1u, &e, (uint32)sizeof(e))) return _Fail("beta eval sym");

		MLGemmParams g;
		g.aOff = _uESym.offset; g.bOff = _uW.offset; g.cOff = _uELogit.offset;
		g.M = _uEvSpans; g.N = outW; g.K = kEDim;
		if (!_pbGemm.Dispatch(outW, _uEvSpans, 1u, &g, (uint32)sizeof(g))) return _Fail("beta eval logits");

		MLSoftmaxParams sm;
		sm.inOff = _uELogit.offset; sm.outOff = _uEProb.offset;
		sm.rows = _uEvSpans * kEMaxLen; sm.cols = kEVoc;
		if (!_pbSoft.Dispatch(sm.rows, 1u, 1u, &sm, (uint32)sizeof(sm))) return _Fail("beta eval softmax");
		return true;
	}

	// 📥 이 τ 점의 **바이트 오류율(%)** — ★ 이것이 `L_recon` 이다(CE 가 아니다 · 위 주석의 근거).
	//   ⚠️ **바이트 자리만** 센다("끝" 자리를 세면 짧은 덩어리가 유리해져 절충이 왜곡된다).
	bool _RecordBetaPoint()
	{
		Bytes be, bt;
		const uint64 wantE = (uint64)_uEvSpans * kEMaxLen * kEVoc * sizeof(float);
		const uint64 wantT = (uint64)_uTrSpans * kEMaxLen * kEVoc * sizeof(float);
		if (!_mdlA.Read(_uEProb, be) || be.GetSize() < wantE)
		{ LogA("[ml] β: 평가 회수가 안 됐다(점 %d)\n", _pbPoint); return false; }
		// ★ 학습 오류율 — `_uProb` 는 **마지막 학습 스텝의 forward** 다(회수는 그 다음 프레임이라 읽힌다).
		const bool haveTr = _mdlA.Read(_uProb, bt) && bt.GetSize() >= wantT;

		_pbRecon[_pbPoint] = _ErrRate((const float*)be.GetData(), _uEvS, _uEvL, _uEvSpans);
		_pbTrErr[_pbPoint] = haveTr
			? _ErrRate((const float*)bt.GetData(), _uTrS, _uTrL, _uTrSpans) : -1.0f;
		LogA("[ml]     → 심볼 %u개 · 평균길이 %.2f · **오류율 학습 %.2f%% → 평가 %.2f%%**\n",
			_pbN[_pbPoint], (double)_uEvBytes / (double)_pbN[_pbPoint],
			(double)_pbTrErr[_pbPoint], (double)_pbRecon[_pbPoint]);
		return true;
	}

	// 못 맞힌 바이트 비율(%).
	float _ErrRate(const float* pr, const Array<float>& st, const Array<float>& ln, uint32 spans) const
	{
		uint32 cnt = 0, bad = 0;
		for (uint32 c = 0; c < spans; ++c)
		{
			const uint32 s0 = (uint32)st.Data()[c];
			uint32 l0 = (uint32)ln.Data()[c];
			if (l0 > kEMaxLen) l0 = kEMaxLen;
			for (uint32 j = 0; j < l0; ++j)
			{
				const float* q = pr + ((uint64)c * kEMaxLen + j) * kEVoc;
				uint32 v = (uint32)_bEvalTok.Data()[s0 + j];
				if (v >= kEVoc) v = 0u;
				uint32 arg = 0;
				for (uint32 u = 1; u < kEVoc; ++u) if (q[u] > q[arg]) arg = u;
				cnt++;
				if (arg != v) bad++;
			}
		}
		return (cnt > 0u) ? (100.0f * (float)bad / (float)cnt) : 0.0f;
	}

	void _JudgeBeta()
	{
		LogA("\n[ml] ⚖️ **β 손잡이 표** — `L = L_recon + β·(심볼수/바이트수)` · 심볼 dim %u · %d스텝\n"
			"[ml]   L_recon = **못 맞힌 바이트 비율(%%)** — CE 가 아니다(포화에 안 흔들리게)\n"
			"[ml]   %-4s %9s %7s %9s %6s %9s %9s %s\n",
			kEDim, kESteps, "점", "τ", "심볼수", "평균길이", "종류", "학습오류%", "평가오류%", "판정");
		for (uint32 i = 0; i < kETaus; ++i)
			LogA("[ml]   %-4u %9.4f %7u %9.2f %6u %9.2f %9.2f %s\n",
				i, (double)_pbTau[i], _pbN[i], (double)_uEvBytes / (double)_pbN[i],
				_pbTypes[i], (double)_pbTrErr[i], (double)_pbRecon[i],
				(_pbTrErr[i] > 2.0f) ? "★수렴안됨★" : "");

		// ★ **전제 둘을 먼저 검사한다 — 통과했다고 곡선을 믿으면 안 된다.**
		//   ㉠ **수렴**: 모든 점의 **학습 오류율이 낮다**. 아니면 곡선의 울퉁불퉁이 용량 압박인지
		//      수렴 부족인지 안 갈린다(실측으로 그 함정을 밟았다).
		//   ㉡ **단조**: 심볼 수가 줄면 평가 오류율이 **뒤집히지 않고** 오른다. 톱니면 절충 곡선이 아니다.
		bool conv = true;
		for (uint32 i = 0; i < kETaus; ++i) if (_pbTrErr[i] > 2.0f) conv = false;

		// 심볼 수 내림차순으로 훑어 뒤집힘을 센다(격자가 이산이라 작은 요동은 봐준다).
		uint32 inv = 0;
		for (uint32 i = 1; i < kETaus; ++i)
			if (_pbRecon[i] < _pbRecon[i - 1u] - 1.0f) inv++;   // 1%p 넘게 뒤집히면 센다
		const bool mono = (inv <= 1u);

		float rMin = _pbRecon[0], rMax = _pbRecon[0];
		for (uint32 i = 1; i < kETaus; ++i)
		{ if (_pbRecon[i] < rMin) rMin = _pbRecon[i]; if (_pbRecon[i] > rMax) rMax = _pbRecon[i]; }
		const bool bound = (rMax - rMin) > 1.0f;

		// β sweep — `argmin_i [ L_recon_i + β · (N_i / bytes) ]`
		LogA("[ml]\n[ml]   β 를 훑는다(단위: %%p per 심볼/바이트) — 고른 점의 심볼수와 오류율이 **둘 다** 움직여야 한다\n"
			"[ml]   %-10s %8s %10s %12s\n", "β", "고른점", "심볼수", "평가오류%");
		const float betas[7] = { 0.0f, 2.0f, 5.0f, 10.0f, 20.0f, 40.0f, 80.0f };
		uint32 pickN[7] = {}; float pickR[7] = {}; int pickI[7] = {};
		for (uint32 b = 0; b < 7u; ++b)
		{
			int best = 0;
			float bestL = 0.0f;
			for (uint32 i = 0; i < kETaus; ++i)
			{
				const float L = _pbRecon[i] + betas[b] * (float)_pbN[i] / (float)_uEvBytes;
				if (i == 0u || L < bestL) { bestL = L; best = (int)i; }
			}
			pickI[b] = best; pickN[b] = _pbN[best]; pickR[b] = _pbRecon[best];
			LogA("[ml]   %-10.1f %8d %10u %12.2f\n",
				(double)betas[b], best, pickN[b], (double)pickR[b]);
		}

		bool monoN = true, monoR = true, moved = false;
		for (uint32 b = 1; b < 7u; ++b)
		{
			if (pickN[b] > pickN[b - 1u]) monoN = false;
			if (pickR[b] < pickR[b - 1u] - 1.0e-3f) monoR = false;
			if (pickN[b] != pickN[b - 1u]) moved = true;
		}
		// ★ **정답 낱말 개수와 견준다** — 이것이 이 실험의 가장 센 결과다.
		//   `β` 를 넓은 범위로 줘도 MDL 이 **"오류 0 인 가장 적은 심볼수"** 를 고르는데, 그 수가
		//   **정답 낱말 수와 거의 같으면** 압축 손잡이가 낱말을 고른 것이다.
		uint32 truthSp = 0;
		{
			const uint32 n2 = (uint32)_bEvalTok.Count();
			uint32 s1 = _uHalf;
			for (uint32 t = _uHalf; t < n2; ++t)
				if (_bEvalBnd.Data()[t] != 0u) { truthSp++; s1 = t + 1u; }
			if (s1 < n2) truthSp++;
		}
		// β 가 넓은 범위에서 고른 점(중간값 β=10 자리)을 대표로 본다.
		const uint32 nMid = pickN[3];
		const float ratio = (truthSp > 0u) ? ((float)nMid / (float)truthSp) : 0.0f;
		const bool okNear = (ratio > 0.85f) && (ratio < 1.25f);

		// ⚠️ 잘린 구간이 있는 점은 **오염됐다** — 용량 압박이 아니라 `kEMaxLen` 한계다.
		uint32 dirty = 0;
		for (uint32 i = 0; i < kETaus; ++i) if (_pbTrunc[i] > 0u) dirty++;

		const bool pass = conv && mono && bound && monoN && monoR && moved && okNear;
		LogA("[ml] P3-b 판정: %s\n"
			"[ml]   ㉠ **수렴**: 모든 점의 학습 오류율 ≤ 2%% → %s\n"
			"[ml]      ⚠️ 이것이 전제다 — 안 되면 곡선의 요동이 **용량 압박인지 덜 배움인지 안 갈린다.**\n"
			"[ml]   ㉡ **절충 곡선이 단조다**: 심볼수↓ 일 때 오류율이 뒤집힌 곳 %u군데(허용 1) → %s\n"
			"[ml]      ⚠️ 톱니면 절충 곡선이 아니고 β 판정이 **우연히** 통과한다(실측으로 그랬다).\n"
			"[ml]   ㉢ **용량이 걸렸다**: 오류율이 %.2f%%~%.2f%% 로 움직인다(기준 >1%%p) → %s\n"
			"[ml]   ㉣ **β 가 심볼 수를 줄이고**(→ %s · 움직였나 %s) **그 대가로 오류율이 오른다**(→ %s)\n"
			"[ml]      ★ 기록된 판정 그대로다: *\"β 를 키우면 심볼 수가 줄고 손실이 오른다 — **둘 다** 움직여야 한다.\"*\n",
			pass ? "통과" : "★실패★",
			conv ? "통과" : "★실패★", inv, mono ? "통과" : "★실패★",
			(double)rMin, (double)rMax, bound ? "통과" : "★실패★",
			monoN ? "통과" : "★실패★", moved ? "통과" : "★실패★", monoR ? "통과" : "★실패★");
		LogA("[ml]   ㉤ ★ **β 가 낱말 개수를 골랐다**: 심볼 %u개 vs 정답 낱말 %u개 (비 %.2f · 기준 0.85~1.25) → %s\n"
			"[ml]      ★ β 를 **2~40 의 넓은 범위**로 줘도 MDL 은 *\"오류 0 인 가장 적은 심볼수\"* 를 고르는데,\n"
			"[ml]        그 수가 정답 낱말 수와 거의 같다. ⇒ **압축이 낱말을 고른다**(P3-a 의 비 0.72 보다 정확하다).\n"
			"[ml]      ★ 그리고 그 자리가 곧 *\"더 압축하면 정보를 잃기 시작하는 문턱\"* 이다 —\n"
			"[ml]        심볼 %u개(평균 6.06바이트)까지 오류 0 이고, 127개(7.20바이트)부터 7%%대로 뛴다.\n",
			nMid, truthSp, (double)ratio, okNear ? "통과" : "★실패★", nMid);
		LogA("[ml]   ⚠️ **곡선이 매끄럽지 않다 — 두 오염원을 적어 둔다.**\n"
			"[ml]      ① 심볼수가 줄어도 **종류가 늘 줄지 않는다**(43·39·42·37·31·25·27·34) — 경계를 덜\n"
			"[ml]         자르면 더 다양한 조합이 생긴다. 그래서 오류율이 톱니가 된다.\n"
			"[ml]      ② **`kEMaxLen`(%u) 을 넘어 잘린 구간이 있는 점이 %u개**다 — 그 점의 오류는 용량 압박이\n"
			"[ml]         아니라 **자름** 때문이다(따로 세서 표에 적었다). ⇒ 그 점들은 곡선의 증거로 쓰지 않는다.\n",
			kEMaxLen, dirty);
		LogA("[ml]   ⚠️⚠️ **범위**: 이것은 **미분 가능한 경계망이 아니다** — 경계는 `H` 문턱 τ 로 정하고\n"
			"[ml]      여기서 잰 것은 *\"MDL 손잡이가 두 항을 움직이나\"* 다. 다음은 경계 확률 머리 +\n"
			"[ml]      `N = Σpᵢ`(기대 개수) + forward hard / backward soft 이고, ★ **손잡이가 작동함을\n"
			"[ml]      확인한 뒤에** 그것을 짜는 것이 순서다(P3-a 와 같은 이유).\n");
	}

	// ── 🔤 **P2-c · Local Codec** — 심볼을 **바이트로 되편다** ───────────────────────────
	//
	// ★ **함정 2 의 자리다**: *"정답이 있는 유일한 자리가 바이트다. 로컬 디코더가 없으면
	//   생성 경로 자체가 없다."* ⇒ 여기서 그 길을 낸다.
	//     인코더 `span_embed`: 덩어리(구간) → 심볼 하나
	//     디코더:             심볼 → **자리마다 257분류**(256 = "끝") = 바이트열 되펴기
	//   ★ 인코더와 디코더가 **같은 알파벳(257)** 을 쓴다 — 길이를 값으로 담아야 하므로.
	//
	// ★ **판정을 세 팔로 둔다 — 그러면 "경계가 뜻이 있나" 가 측정된다.**
	//   ① **정답 낱말 경계**            — 상한(생성기가 아는 그 자리)
	//   ② **경계망(k=4)이 찾은 경계**   ← ★ 관심사: P2-b2 의 결과가 **쓸 만한가**
	//   ③ **어긋난 고정 5바이트**       — 대조. 5 는 3(음절)의 배수가 아니라 **음절도 낱말도 가른다**
	//   ⇒ ①≈② 면 경계망이 쓸 만하고, ③ 이 뚜렷히 낮으면 **경계가 정보다**(무엇으로 잘라도 같지 않다).
	//   ⚠️ 팔마다 **자기 청킹으로 학습까지** 한다 — 학습은 정답 경계로 하고 평가만 바꾸면 그것은
	//     "분포 이동" 검사이지 "경계가 뜻이 있나" 검사가 아니다.
	//
	// ⚠️⚠️ **코퍼스는 경계망의 평가 코퍼스**다(경계망이 학습에 안 쓴 것) → 그 H 가 뜻이 있다.
	//   그리고 그것을 **반으로 갈라** 앞은 디코더 학습 · 뒤는 디코더 평가로 쓴다(디코더에게도 안 본 것).
	int      _cStage = 0;
	MLArena  _cod;
	MLKernel _cSpan, _cSpanB, _cGemm, _cSoft, _cSub, _cAdam;

	static constexpr uint32 kDDim = 24, kDMaxLen = 12, kDVoc = 257, kDMaxSpans = 400;
	static constexpr int    kDSteps = 400, kDPerFrame = 4;
	static constexpr float  kDLr = 0.05f;
	static constexpr uint32 kDArms = 3;
	static const char* _DArmName(int a)
	{
		if (a == 0) return "정답경계";
		if (a == 1) return "경계망k4";
		return "고정5바이트";
	}

	MLTensor _tDTok, _tDStart, _tDLen, _tDOne, _tDSlot, _tDW;
	MLTensor _tDSym, _tDLogit, _tDProb, _tDDLogit, _tDDSym, _tDDSlot, _tDDW;
	MLTensor _tDMS, _tDVS, _tDMW, _tDVW;
	MLTensor _tEStart, _tELen, _tESym, _tELogit, _tEProb;

	Array<float> _dStart, _dLen, _eStart, _eLen;   // 학습/평가 구간
	uint32 _dSpans = 0, _eSpans = 0, _dHalf = 0;
	int    _cArm = 0, _cStep = 0;
	float  _cByteAcc[kDArms] = {}, _cLenAcc[kDArms] = {}, _cWordAcc[kDArms] = {};
	uint32 _cTruncated[kDArms] = {};
	// ★ **구간 종류 수** — 같은 바이트열이 몇 가지나 나오나. 이것이 MDL 의 `N_symbols` 이고,
	//   *"왜 경계가 정보인가"* 의 답이다: 경계가 어긋나면 **종류가 폭발**해서 같은 용량으로 못 담는다.
	uint32 _cTypes[kDArms] = {};
	float  _cAvgLen[kDArms] = {};
	float  _cLossEnd[kDArms] = {};

	void _TickCodec()
	{
		if (_cStage >= 4) return;

		if (_cStage == 0)
		{
			_cStage = 1;
			if (!_SetupCodec()) { _cStage = 4; return; }
			_cArm = 0;
			if (!_StartCodecArm(0)) { _cStage = 4; return; }
			_cStage = 2;
			return;
		}

		if (_cStage == 2)
		{
			if (_cStep > 0)
			{
				Bytes bp;
				const uint64 want = (uint64)_dSpans * kDMaxLen * kDVoc * sizeof(float);
				if (_cod.Read(_tDProb, bp) && bp.GetSize() >= want)
				{
					Array<float> tgt; _CodecTargets(_dStart, _dLen, _dSpans, tgt);
					const float loss = MLCrossEntropyCpu((const float*)bp.GetData(), tgt.Data(),
						_dSpans * kDMaxLen, kDVoc);
					if ((_cStep % 100) == 0 || _cStep >= kDSteps)
						LogA("[ml]   step %4d  loss %.6f nat\n", _cStep, (double)loss);
					if (_cStep >= kDSteps) _cLossEnd[_cArm] = loss;
				}
			}
			if (_cStep >= kDSteps)
			{
				_cStage = 3;
				if (!_DispatchCodecEval()) _cStage = 4;
				return;
			}
			for (int i = 0; i < kDPerFrame && _cStep < kDSteps; ++i)
			{
				if (!_DispatchCodecStep()) { _cStage = 4; return; }
				_cStep++;
			}
			return;
		}

		if (!_RecordCodecArm()) { _cStage = 4; return; }
		if (_cArm + 1 < (int)kDArms)
		{
			_cArm++;
			if (!_StartCodecArm(_cArm)) { _cStage = 4; return; }
			_cStage = 2;
			return;
		}
		_cStage = 4;
		_JudgeCodec();
	}

	// 🔧 청킹 셋 — 같은 바이트열을 **다르게 자른다**. `[lo, hi)` 안에서만.
	//   ⚠️ 구간이 `kDMaxLen` 보다 길면 **잘린다**(호출부가 센다) — 셰이더는 로그가 없으므로 호스트가 판정한다.
	void _ChunkTruth(uint32 lo, uint32 hi, Array<float>& st, Array<float>& ln) const
	{
		uint32 s0 = lo;
		for (uint32 t = lo; t < hi; ++t)
			if (_bEvalBnd.Data()[t] != 0u) { st.Add((float)s0); ln.Add((float)(t + 1u - s0)); s0 = t + 1u; }
		if (s0 < hi) { st.Add((float)s0); ln.Add((float)(hi - s0)); }
	}

	// ② 경계망이 찾은 경계 — **판정과 같은 규칙**(음절 후보 중 정답 개수만큼 상위 H).
	//   ★ 개수만 알려주고 **어디인지는 모델이 정한다** — 임계값을 두지 않는 그 규칙 그대로다.
	void _ChunkPredicted(uint32 lo, uint32 hi, Array<float>& st, Array<float>& ln) const
	{
		Array<uint32> cand;
		uint32 truth = 0;
		for (uint32 t = lo; t + 1u < hi; ++t)
		{
			if (!_IsLead((uint8)_bEvalTok.Data()[t + 1u])) continue;
			cand.Add(t);
			if (_bEvalBnd.Data()[t] != 0u) truth++;
		}
		Array<uint8> pick;
		pick.Reset(hi);
		for (uint32 i = 0; i < hi; ++i) pick.Data()[i] = 0u;
		Array<uint8> taken;
		taken.Reset(cand.Count() > 0u ? cand.Count() : 1u);
		for (uint32 i = 0; i < (uint32)cand.Count(); ++i) taken.Data()[i] = 0u;
		for (uint32 m = 0; m < truth; ++m)
		{
			int best = -1;
			for (uint32 i = 0; i < (uint32)cand.Count(); ++i)
			{
				if (taken.Data()[i] != 0u) continue;
				if (best < 0 || _bEvalH.Data()[cand.Data()[i]]
					> _bEvalH.Data()[cand.Data()[(uint32)best]]) best = (int)i;
			}
			if (best < 0) break;
			taken.Data()[best] = 1u;
			pick.Data()[cand.Data()[(uint32)best]] = 1u;
		}
		uint32 s0 = lo;
		for (uint32 t = lo; t < hi; ++t)
			if (pick.Data()[t] != 0u) { st.Add((float)s0); ln.Add((float)(t + 1u - s0)); s0 = t + 1u; }
		if (s0 < hi) { st.Add((float)s0); ln.Add((float)(hi - s0)); }
	}

	// ③ 어긋난 고정 길이 — ★ **5 는 3(음절)의 배수가 아니다** → 음절도 낱말도 가른다.
	void _ChunkFixed(uint32 lo, uint32 hi, Array<float>& st, Array<float>& ln) const
	{
		for (uint32 t = lo; t < hi; t += 5u)
		{
			const uint32 e = ((t + 5u) < hi) ? (t + 5u) : hi;
			st.Add((float)t);
			ln.Add((float)(e - t));
		}
	}

	void _Chunk(int arm, uint32 lo, uint32 hi, Array<float>& st, Array<float>& ln) const
	{
		st.Reset(0); ln.Reset(0);
		if (arm == 0)      _ChunkTruth(lo, hi, st, ln);
		else if (arm == 1) _ChunkPredicted(lo, hi, st, ln);
		else               _ChunkFixed(lo, hi, st, ln);
	}

	// 자리마다 정답 — 바이트이거나 **256("끝")**.
	void _CodecTargets(const Array<float>& st, const Array<float>& ln, uint32 spans,
		Array<float>& tgt) const
	{
		tgt.Reset((uint64)spans * kDMaxLen);
		for (uint32 c = 0; c < spans; ++c)
		{
			const uint32 s0 = (uint32)st.Data()[c], l0 = (uint32)ln.Data()[c];
			for (uint32 j = 0; j < kDMaxLen; ++j)
				tgt.Data()[(uint64)c * kDMaxLen + j] =
					(j < l0) ? _bEvalTok.Data()[s0 + j] : 256.0f;
		}
	}

	bool _SetupCodec()
	{
		const uint32 n = (uint32)_bEvalTok.Count();
		if (n < 64u || _bEvalH.Count() == 0u)
		{ LogA("[ml] 코덱: 코퍼스나 엔트로피가 없다(경계망이 실패했나)\n"); return false; }

		// ★ 반으로 가르되 **낱말 경계에서** 자른다(구간이 반쪽에 걸치지 않게).
		_dHalf = n / 2u;
		while (_dHalf + 1u < n && _bEvalBnd.Data()[_dHalf] == 0u) _dHalf++;
		_dHalf++;

		const uint32 need =
			n                                              // tok
			+ kDMaxSpans * 4u                              // start/len × 학습·평가
			+ kDMaxSpans * kDMaxLen * kDVoc * 4u           // onehot · logits · probs · dLogits(학습)
			+ kDMaxSpans * kDMaxLen * kDVoc * 2u           // logits · probs(평가)
			+ kDMaxLen * kDVoc * kDDim * 4u                // slot · dSlot · m · v
			+ kDDim * (kDMaxLen * kDVoc) * 4u              // W · dW · m · v
			+ kDMaxSpans * kDDim * 3u                      // sym · dSym · evalSym
			+ 256u;
		if (!_cod.Create(rhi, need))
		{ LogA("[ml] 코덱: 아레나 생성 실패(%u floats)\n", need); return false; }

		_tDTok    = _cod.Alloc(1, n);
		_tDStart  = _cod.Alloc(1, kDMaxSpans);
		_tDLen    = _cod.Alloc(1, kDMaxSpans);
		_tEStart  = _cod.Alloc(1, kDMaxSpans);
		_tELen    = _cod.Alloc(1, kDMaxSpans);
		_tDSlot   = _cod.Alloc(kDMaxLen * kDVoc, kDDim);
		_tDW      = _cod.Alloc(kDDim, kDMaxLen * kDVoc);
		_tDSym    = _cod.Alloc(kDMaxSpans, kDDim);
		_tDOne    = _cod.Alloc(kDMaxSpans * kDMaxLen, kDVoc);
		_tDLogit  = _cod.Alloc(kDMaxSpans * kDMaxLen, kDVoc);
		_tDProb   = _cod.Alloc(kDMaxSpans * kDMaxLen, kDVoc);
		_tDDLogit = _cod.Alloc(kDMaxSpans * kDMaxLen, kDVoc);
		_tDDSym   = _cod.Alloc(kDMaxSpans, kDDim);
		_tDDSlot  = _cod.Alloc(kDMaxLen * kDVoc, kDDim);
		_tDDW     = _cod.Alloc(kDDim, kDMaxLen * kDVoc);
		_tDMS     = _cod.Alloc(kDMaxLen * kDVoc, kDDim);
		_tDVS     = _cod.Alloc(kDMaxLen * kDVoc, kDDim);
		_tDMW     = _cod.Alloc(kDDim, kDMaxLen * kDVoc);
		_tDVW     = _cod.Alloc(kDDim, kDMaxLen * kDVoc);
		_tESym    = _cod.Alloc(kDMaxSpans, kDDim);
		_tELogit  = _cod.Alloc(kDMaxSpans * kDMaxLen, kDVoc);
		_tEProb   = _cod.Alloc(kDMaxSpans * kDMaxLen, kDVoc);
		if (!_tEProb.IsValid()) { LogA("[ml] 코덱: 텐서 할당 실패(아레나 부족)\n"); return false; }

		if (!_cod.Write(_tDTok, _bEvalTok))
		{ LogA("[ml] 코덱: 코퍼스 업로드 실패\n"); return false; }

		if (!_LoadKernelIn(_cSpan,  "shaders/span_embed.cs.spv",     _cod)) return false;
		if (!_LoadKernelIn(_cSpanB, "shaders/span_embed_bwd.cs.spv", _cod)) return false;
		if (!_LoadKernelIn(_cGemm,  "shaders/gemm.cs.spv",           _cod)) return false;
		if (!_LoadKernelIn(_cSoft,  "shaders/softmax.cs.spv",        _cod)) return false;
		if (!_LoadKernelIn(_cSub,   "shaders/sub.cs.spv",            _cod)) return false;
		if (!_LoadKernelIn(_cAdam,  "shaders/adamw.cs.spv",          _cod)) return false;

		LogA("\n[ml] 🔤 로컬 코덱 — 코퍼스 %u바이트(경계망이 **안 배운** 것) · 학습 [0,%u) / 평가 [%u,%u)\n"
			"[ml]   심볼 dim %u · 자리 최대 %u · 출력 어휘 %u(마지막이 \"끝\")\n",
			n, _dHalf, _dHalf, n, kDDim, kDMaxLen, kDVoc);
		return true;
	}

	bool _StartCodecArm(int arm)
	{
		const uint32 n = (uint32)_bEvalTok.Count();
		_cStep = 0;
		_Chunk(arm, 0u, _dHalf, _dStart, _dLen);
		_Chunk(arm, _dHalf, n, _eStart, _eLen);
		_dSpans = (uint32)_dStart.Count();
		_eSpans = (uint32)_eStart.Count();
		if (_dSpans == 0u || _eSpans == 0u || _dSpans > kDMaxSpans || _eSpans > kDMaxSpans)
		{ LogA("[ml] 코덱: 구간 수가 이상하다(%u / %u · 상한 %u)\n", _dSpans, _eSpans, kDMaxSpans); return false; }

		// ⚠️ `kDMaxLen` 보다 긴 구간은 **잘린다** — 몇 개인지 세서 판정에 같이 적는다(조용히 넘기지 않는다).
		_cTruncated[arm] = 0u;
		for (uint32 c = 0; c < _dSpans; ++c) if ((uint32)_dLen.Data()[c] > kDMaxLen) _cTruncated[arm]++;
		for (uint32 c = 0; c < _eSpans; ++c) if ((uint32)_eLen.Data()[c] > kDMaxLen) _cTruncated[arm]++;

		if (!_cod.Write(_tDStart, _dStart) || !_cod.Write(_tDLen, _dLen)
			|| !_cod.Write(_tEStart, _eStart) || !_cod.Write(_tELen, _eLen))
		{ LogA("[ml] 코덱: 구간 업로드 실패\n"); return false; }

		// onehot(학습) — 자리마다 정답 바이트 또는 256("끝")
		Array<float> tgt; _CodecTargets(_dStart, _dLen, _dSpans, tgt);
		Array<float> one;
		one.Reset((uint64)_dSpans * kDMaxLen * kDVoc);
		for (uint64 i = 0; i < one.Count(); ++i) one.Data()[i] = 0.0f;
		for (uint64 r = 0; r < (uint64)_dSpans * kDMaxLen; ++r)
		{
			uint32 v = (uint32)tgt.Data()[r];
			if (v >= kDVoc) v = 0u;
			one.Data()[r * kDVoc + v] = 1.0f;
		}
		if (!_cod.Write(MLTensor{ _tDOne.offset, _dSpans * kDMaxLen, kDVoc }, one))
		{ LogA("[ml] 코덱: onehot 업로드 실패\n"); return false; }

		SeedRand(MLEpisodeGen::ScrambleSeed(5500u + (uint32)arm));
		Array<float> slot, w;
		slot.Reset((uint64)kDMaxLen * kDVoc * kDDim);
		for (uint64 i = 0; i < slot.Count(); ++i)
			slot.Data()[i] = ((float)RandInt(0, 2001) * 0.001f - 1.0f) * (0.4f / (float)kDMaxLen);
		w.Reset((uint64)kDDim * kDMaxLen * kDVoc);
		for (uint64 i = 0; i < w.Count(); ++i)
			w.Data()[i] = ((float)RandInt(0, 2001) * 0.001f - 1.0f) * (0.4f / (float)kDDim);
		if (!_cod.Write(_tDSlot, slot) || !_cod.Write(_tDW, w))
		{ LogA("[ml] 코덱: 가중치 업로드 실패\n"); return false; }
		if (!_ZeroC(_tDMS) || !_ZeroC(_tDVS) || !_ZeroC(_tDMW) || !_ZeroC(_tDVW))
		{ LogA("[ml] 코덱: 모멘트 초기화 실패\n"); return false; }

		// 평균 구간 길이 = **심볼 하나가 몇 바이트를 접었나**(압축률의 재료 · P3 로 이어진다).
		float avg = 0.0f;
		for (uint32 c = 0; c < _eSpans; ++c) avg += _eLen.Data()[c];
		avg /= (float)_eSpans;
		_cAvgLen[arm] = avg;
		_cTypes[arm] = _CountSpanTypes();
		LogA("\n[ml] ── 🔤 [%s] 구간 학습 %u개 / 평가 %u개 · 평균 길이 %.2f바이트 · 잘림 %u개"
			" · **종류 %u가지**\n",
			_DArmName(arm), _dSpans, _eSpans, (double)avg, _cTruncated[arm], _cTypes[arm]);
		return true;
	}

	// 🔢 **서로 다른 바이트열이 몇 가지인가**(학습+평가 전체). ⚠️ 손으로 훑는다 — 해시맵을 끌어올 만큼
	//   크지 않고(구간 300여 개), 이 숫자는 **판정의 재료**라 결정적이어야 한다.
	uint32 _CountSpanTypes() const
	{
		Array<uint32> repStart, repLen;
		for (int side = 0; side < 2; ++side)
		{
			const Array<float>& st = (side == 0) ? _dStart : _eStart;
			const Array<float>& ln = (side == 0) ? _dLen : _eLen;
			const uint32 nsp = (side == 0) ? _dSpans : _eSpans;
			for (uint32 c = 0; c < nsp; ++c)
			{
				const uint32 s0 = (uint32)st.Data()[c], l0 = (uint32)ln.Data()[c];
				bool dup = false;
				for (uint32 r = 0; r < (uint32)repStart.Count() && !dup; ++r)
				{
					if (repLen.Data()[r] != l0) continue;
					bool same = true;
					for (uint32 j = 0; j < l0 && same; ++j)
						if (_bEvalTok.Data()[s0 + j] != _bEvalTok.Data()[repStart.Data()[r] + j])
							same = false;
					if (same) dup = true;
				}
				if (!dup) { repStart.Add(s0); repLen.Add(l0); }
			}
		}
		return (uint32)repStart.Count();
	}

	bool _ZeroC(const MLTensor& t)
	{
		Array<float> z;
		z.Reset(t.Count());
		for (uint32 i = 0; i < t.Count(); ++i) z.Data()[i] = 0.0f;
		return _cod.Write(t, z);
	}

	// 한 스텝 = 디스패치 여덟.
	bool _DispatchCodecStep()
	{
		const uint32 outW = kDMaxLen * kDVoc;

		// ① sym = Σ_j slot[(j, byte)]   (구간 → 심볼)
		MLSpanEmbedParams e;
		e.tokOff = _tDTok.offset; e.startOff = _tDStart.offset; e.lenOff = _tDLen.offset;
		e.aOff = _tDSlot.offset; e.bOff = _tDSym.offset;
		e.spans = _dSpans; e.maxLen = kDMaxLen; e.dim = kDDim;
		if (!_cSpan.Dispatch(kDDim, _dSpans, 1u, &e, (uint32)sizeof(e))) return _Fail("codec sym");

		// ② logits = sym · W   ★ `W` 가 `dim × (자리·257)` 이라 **한 GEMM 이 자리 전부**를 낸다
		MLGemmParams g;
		g.aOff = _tDSym.offset; g.bOff = _tDW.offset; g.cOff = _tDLogit.offset;
		g.M = _dSpans; g.N = outW; g.K = kDDim;
		if (!_cGemm.Dispatch(outW, _dSpans, 1u, &g, (uint32)sizeof(g))) return _Fail("codec logits");

		// ③ probs = softmax — ★ 행이 `(구간, 자리)` 이고 열이 257 이다(배치가 그대로 맞는다)
		MLSoftmaxParams sm;
		sm.inOff = _tDLogit.offset; sm.outOff = _tDProb.offset;
		sm.rows = _dSpans * kDMaxLen; sm.cols = kDVoc;
		if (!_cSoft.Dispatch(sm.rows, 1u, 1u, &sm, (uint32)sizeof(sm))) return _Fail("codec softmax");

		// ④ dLogits = probs − onehot
		MLSubParams sb;
		sb.aOff = _tDProb.offset; sb.bOff = _tDOne.offset; sb.outOff = _tDDLogit.offset;
		sb.count = _dSpans * outW;
		if (!_cSub.Dispatch(sb.count, 1u, 1u, &sb, (uint32)sizeof(sb))) return _Fail("codec dlogits");

		// ⑤ dW = symᵀ · dLogits
		MLGemmParams gw;
		gw.aOff = _tDSym.offset; gw.bOff = _tDDLogit.offset; gw.cOff = _tDDW.offset;
		gw.M = kDDim; gw.N = outW; gw.K = _dSpans; gw.transA = 1;
		if (!_cGemm.Dispatch(outW, kDDim, 1u, &gw, (uint32)sizeof(gw))) return _Fail("codec dW");

		// ⑥ dSym = dLogits · Wᵀ — ⚠️ W 는 `dim × outW` 저장이므로 `transB = 1`
		MLGemmParams gs;
		gs.aOff = _tDDLogit.offset; gs.bOff = _tDW.offset; gs.cOff = _tDDSym.offset;
		gs.M = _dSpans; gs.N = kDDim; gs.K = outW; gs.transB = 1;
		if (!_cGemm.Dispatch(kDDim, _dSpans, 1u, &gs, (uint32)sizeof(gs))) return _Fail("codec dSym");

		// ⑦ dSlot — **gather**
		MLSpanEmbedParams eb;
		eb.tokOff = _tDTok.offset; eb.startOff = _tDStart.offset; eb.lenOff = _tDLen.offset;
		eb.aOff = _tDDSym.offset; eb.bOff = _tDDSlot.offset;
		eb.spans = _dSpans; eb.maxLen = kDMaxLen; eb.dim = kDDim;
		if (!_cSpanB.Dispatch(kDDim, eb.SlotRows(), 1u, &eb, (uint32)sizeof(eb)))
			return _Fail("codec dSlot");

		// ⑧ AdamW × 2
		float bc1 = 1.0f, bc2 = 1.0f;
		_BiasCorr(_cStep + 1, bc1, bc2);
		MLAdamWParams aw;
		aw.lr = kDLr; aw.beta1 = kB1; aw.beta2 = kB2; aw.eps = kAdamEps; aw.wd = kWd;
		aw.bc1 = bc1; aw.bc2 = bc2;
		aw.pOff = _tDSlot.offset; aw.gOff = _tDDSlot.offset;
		aw.mOff = _tDMS.offset;   aw.vOff = _tDVS.offset;   aw.count = _tDSlot.Count();
		if (!_cAdam.Dispatch(aw.count, 1u, 1u, &aw, (uint32)sizeof(aw))) return _Fail("codec adamw slot");

		MLAdamWParams ax = aw;
		ax.pOff = _tDW.offset;  ax.gOff = _tDDW.offset;
		ax.mOff = _tDMW.offset; ax.vOff = _tDVW.offset; ax.count = _tDW.Count();
		if (!_cAdam.Dispatch(ax.count, 1u, 1u, &ax, (uint32)sizeof(ax))) return _Fail("codec adamw W");
		return true;
	}

	// 📏 평가 = **안 본 뒤 반쪽**에 forward 만.
	bool _DispatchCodecEval()
	{
		const uint32 outW = kDMaxLen * kDVoc;
		MLSpanEmbedParams e;
		e.tokOff = _tDTok.offset; e.startOff = _tEStart.offset; e.lenOff = _tELen.offset;
		e.aOff = _tDSlot.offset; e.bOff = _tESym.offset;
		e.spans = _eSpans; e.maxLen = kDMaxLen; e.dim = kDDim;
		if (!_cSpan.Dispatch(kDDim, _eSpans, 1u, &e, (uint32)sizeof(e))) return _Fail("codec eval sym");

		MLGemmParams g;
		g.aOff = _tESym.offset; g.bOff = _tDW.offset; g.cOff = _tELogit.offset;
		g.M = _eSpans; g.N = outW; g.K = kDDim;
		if (!_cGemm.Dispatch(outW, _eSpans, 1u, &g, (uint32)sizeof(g))) return _Fail("codec eval logits");

		MLSoftmaxParams sm;
		sm.inOff = _tELogit.offset; sm.outOff = _tEProb.offset;
		sm.rows = _eSpans * kDMaxLen; sm.cols = kDVoc;
		if (!_cSoft.Dispatch(sm.rows, 1u, 1u, &sm, (uint32)sizeof(sm))) return _Fail("codec eval softmax");
		return true;
	}

	// 📥 팔 하나의 복원 결과.
	bool _RecordCodecArm()
	{
		Bytes bp;
		const uint64 want = (uint64)_eSpans * kDMaxLen * kDVoc * sizeof(float);
		if (!_cod.Read(_tEProb, bp) || bp.GetSize() < want)
		{ LogA("[ml] 코덱: 평가 회수가 안 됐다(%s)\n", _DArmName(_cArm)); return false; }
		const float* pr = (const float*)bp.GetData();

		uint32 byteHit = 0, byteAll = 0, lenHit = 0, wordHit = 0;
		for (uint32 c = 0; c < _eSpans; ++c)
		{
			const uint32 s0 = (uint32)_eStart.Data()[c];
			uint32 l0 = (uint32)_eLen.Data()[c];
			if (l0 > kDMaxLen) l0 = kDMaxLen;   // 잘린 구간(개수는 위에서 셌다)
			bool whole = true;
			int firstEnd = -1;
			for (uint32 j = 0; j < kDMaxLen; ++j)
			{
				const float* q = pr + ((uint64)c * kDMaxLen + j) * kDVoc;
				uint32 arg = 0;
				for (uint32 v = 1; v < kDVoc; ++v) if (q[v] > q[arg]) arg = v;
				if (firstEnd < 0 && arg == 256u) firstEnd = (int)j;
				if (j < l0)
				{
					// ★ **바이트 자리만 센다** — "끝" 자리를 세면 길이가 짧을수록 점수가 올라가 부풀려진다.
					byteAll++;
					if (arg == (uint32)_bEvalTok.Data()[s0 + j]) byteHit++;
					else whole = false;
				}
			}
			if (firstEnd >= 0 && (uint32)firstEnd == l0) lenHit++;
			else if (firstEnd < 0 && l0 == kDMaxLen) lenHit++;
			if (whole) wordHit++;
		}
		_cByteAcc[_cArm] = (byteAll > 0u) ? (100.0f * (float)byteHit / (float)byteAll) : 0.0f;
		_cLenAcc[_cArm]  = 100.0f * (float)lenHit / (float)_eSpans;
		_cWordAcc[_cArm] = 100.0f * (float)wordHit / (float)_eSpans;
		LogA("[ml]   → 바이트 %.1f%% (%u/%u) · 길이 %.1f%% · **덩어리 통째로 %.1f%%**\n",
			(double)_cByteAcc[_cArm], byteHit, byteAll,
			(double)_cLenAcc[_cArm], (double)_cWordAcc[_cArm]);
		return true;
	}

	// ㉢ **코덱 판정 — 표 하나로.**
	void _JudgeCodec()
	{
		LogA("\n[ml] 🔤 **로컬 코덱 표** — 심볼(dim %u) → 바이트 되펴기 · 평가는 **안 본 뒤 반쪽**\n"
			"[ml]   %-11s %7s %7s %8s %7s %8s %14s %6s\n",
			kDDim, "청킹", "종류", "평균길이", "학습손실", "바이트%", "길이%", "덩어리통째로%", "잘림");
		for (uint32 a = 0; a < kDArms; ++a)
			LogA("[ml]   %-11s %7u %8.2f %8.4f %7.1f %8.1f %14.1f %6u\n",
				_DArmName((int)a), _cTypes[a], (double)_cAvgLen[a], (double)_cLossEnd[a],
				(double)_cByteAcc[a], (double)_cLenAcc[a], (double)_cWordAcc[a], _cTruncated[a]);
		LogA("[ml]   ★ **`종류` 가 곧 MDL 의 `N_symbols` 다** — 경계가 어긋나면 같은 바이트열을 여러\n"
			"[ml]      가지로 쪼개게 되어 종류가 불어나고, **같은 용량(dim %u)으로 못 담는다.**\n"
			"[ml]      ⇒ 그것이 `L = L_pred + λ·L_recon + β·N_symbols` 의 `β·N` 항이 재는 것이다(P3).\n",
			kDDim);

		// ★ **기준은 측정 전에 정했다.**
		//   ㉠ **함정 2 해소**: 정답 경계에서 덩어리를 **통째로** 90% 이상 되편다
		//      (바이트 정확도가 아니라 **통째로**를 본다 — 한 바이트만 틀려도 그 낱말은 못 쓴다)
		//   ㉡ **경계망이 쓸 만하다**: 예측 경계가 정답 경계의 **80% 이상**을 낸다
		//   ㉢ **경계가 정보다**: 어긋난 고정 5바이트가 정답 경계보다 **뚜렷히 낮다**(20%p 이상)
		const bool okRecon = (_cWordAcc[0] >= 90.0f);
		const bool okPred  = (_cWordAcc[0] > 0.0f) && (_cWordAcc[1] >= _cWordAcc[0] * 0.8f);
		const bool okInfo  = (_cWordAcc[0] - _cWordAcc[2] >= 20.0f);
		LogA("[ml] P2-c 판정: %s\n"
			"[ml]   ㉠ **함정 2 해소**: 정답 경계에서 덩어리 통째로 %.1f%% (기준 ≥90) → %s\n"
			"[ml]      ★ 바이트가 아니라 **통째로**를 본다 — 한 바이트만 틀려도 그 낱말은 못 쓴다.\n"
			"[ml]   ㉡ 경계망이 쓸 만한가: 예측 %.1f%% vs 정답 %.1f%% (기준 ≥80%%) → %s\n"
			"[ml]   ㉢ **경계가 정보다**: 어긋난 고정5 %.1f%% vs 정답 %.1f%% (기준 20%%p 이상 낮다) → %s\n"
			"[ml]      ★ 무엇으로 잘라도 같으면 경계망은 쓸모가 없다 — 이 대조가 그것을 막는다.\n",
			(okRecon && okPred && okInfo) ? "통과" : "★실패★",
			(double)_cWordAcc[0], okRecon ? "통과" : "★실패★",
			(double)_cWordAcc[1], (double)_cWordAcc[0], okPred ? "통과" : "★실패★",
			(double)_cWordAcc[2], (double)_cWordAcc[0], okInfo ? "통과" : "★실패★");
		LogA("[ml]   ⚠️⚠️ **이 판정의 범위를 분명히 한다** — 평가는 *안 본 캡션*이지만 *안 본 낱말*은 아니다.\n"
			"[ml]      캡션 어휘가 %u가지뿐이라 뒤 반쪽의 낱말이 앞 반쪽에도 다 나온다.\n"
			"[ml]      ⇒ ㉠ 이 증명하는 것은 **\"되펴는 길이 있다\"**(함정 2)이고 **어휘 일반화가 아니다.**\n"
			"[ml]      ★ 그런데 ㉢ 이 그 한계 안에서도 뜻을 지킨다: **외우기조차 경계가 어긋나면 안 된다**\n"
			"[ml]        (종류가 %u → %u가지로 불어나므로). 그것이 이 실험의 실제 값어치다.\n",
			_cTypes[0], _cTypes[0], _cTypes[2]);
		if (!okRecon)
			LogA("[ml]   ⚠️ 볼 곳: ① dim 이 모자라나(덩어리 종류 수보다 작으면 못 담는다)"
				" ② `256`(\"끝\")이 fwd/bwd/타깃 셋에서 같은가 ③ softmax 행이 `(구간,자리)` 인가\n");
	}

	// ── 🧩 **P2-b2 · 경계망** — 낱말 경계를 **엔트로피에서** 읽는다 ──────────────────────────
	//
	// ★ **경계 라벨로 학습하지 않는다.** 배우는 것은 **다음 바이트 예측**뿐이고, 경계는
	//   `H(다음 | 창)` 이 높은 자리로 **읽어낸다**. 정답 경계는 **평가에만** 쓴다.
	//   ⇒ 라벨 누출이 **원리적으로** 없다. 그것이 이 실험의 미덕이다.
	//
	// ★ **정답 경계가 공짜다** — 캡션 생성기가 낱말을 조립하므로 우리가 그 자리를 안다.
	//   `왼쪽에 작은 붉은 빈 동그라미 셋이 있다` 의 **공백 자리**가 곧 낱말 경계다.
	//   ⚠️⚠️ **그래서 공백을 지운 코퍼스로 문제를 낸다.** 공백을 남기면 과제가 *"공백을 찾아라"* 가 되어
	//     **아무것도 검증하지 못한다**(함정 8 과 같은 성격 — 문제가 자명해지면 검증력이 0 이다).
	//     ⇒ `왼쪽에작은붉은빈동그라미셋이있다` 에서 경계를 찾는 것이 진짜 문제이고,
	//       이것이 이 프로젝트가 시작한 그 문제다: `샤인머스캣은맛있다` 를 어디서 자르나.
	//
	// ★ **경계 후보를 음절(코드포인트) 자리로 제한한다 — 그것이 `L1 = 발판`이다.**
	//   한글 한 글자가 UTF-8 3바이트라, 바이트마다 판정하면 *"높은 엔트로피"* 가 대부분 **음절 경계**로
	//   가서 낱말 신호가 묻힌다. ⇒ L1(UTF-8 선두비트)이 음절을 주고, **L2 가 그 중에서 낱말을 고른다.**
	//   ⚠️ 이것은 언어 지식이 아니라 **인코딩 자신의 규칙**이다(설계 규칙 그대로).
	//
	// ★ **`k` 하나로 함정 4 가 갈린다.** `k = 1` 은 **정확히 바이그램**이고(`out[t] = slot[byte[t]]`),
	//   `k > 1` 은 접두사(창)를 함께 본다. 두 구현을 만들면 비교가 구현 차이에 오염되므로 **한 커널**이다.
	//   ⚠️ 이것은 *"덩어리 시작부터"* 의 **고정 길이 근사**다 — 진짜 접두사는 경계를 알아야 하고
	//     경계는 이걸로 정하므로 순환이다. 창이 그 순환을 끊는 발판이다.
	//
	// ⚠️⚠️⚠️ **과적합이 경계 신호를 죽인다.** 코퍼스를 외우면 엔트로피가 전부 0 이 되어 경계가 사라진다.
	//   ⇒ **학습 캡션과 다른 캡션에서** 엔트로피를 잰다(씨앗을 나눈다). 외운 것으로는 못 한다.
	int      _bStage = 0;
	MLArena  _bnd;
	MLKernel _bCtx, _bCtxB, _bGemm, _bSoft, _bSub, _bAdam;

	static constexpr uint32 kBDim = 32, kBVoc = 256, kBKMax = 4;
	static constexpr uint32 kBTrainCaps = 60, kBEvalCaps = 40;
	static constexpr int    kBSteps = 400, kBPerFrame = 4;
	static constexpr float  kBLr = 0.05f;
	// 세 팔 — ★ `1` 이 바이그램 기준선이다.
	static constexpr uint32 kBArms = 3;
	static uint32 _BK(int arm) { const uint32 k[kBArms] = { 1u, 2u, 4u }; return k[arm]; }

	MLTensor _tBTok, _tBOne, _tBSlot, _tBW, _tBCtx, _tBLogit, _tBProb;
	MLTensor _tBDLogit, _tBDCtx, _tBDSlot, _tBDW, _tBMS, _tBVS, _tBMW, _tBVW;
	MLTensor _tBETok, _tBECtx, _tBELogit, _tBEProb;
	// P3-c 경계 머리(2분류) — ★ `_tBCtx`/`_tBECtx` 를 **그대로** 입력으로 쓴다(표는 얼린다).
	MLTensor _tHOne, _tHLogit, _tHProb, _tHDLogit, _tHELogit, _tHEProb;
	MLTensor _tHW, _tHDW, _tHMW, _tHVW;
	// 커널 검증용(작게)
	MLTensor _tCTok, _tCSlot, _tCOut, _tCDOut, _tCDSlot;
	static constexpr uint32 kCSeq = 12, kCK = 3, kCDim = 3;

	Array<float> _bTrainTok, _bEvalTok;
	Array<uint8> _bTrainBnd, _bEvalBnd;      // `i` 뒤가 낱말 경계인가
	// 🌉 **교차채널 쓸모용** — 바이트마다 어느 캡션인지 + 그 캡션 장면의 축 값 6개.
	//   ★ 이것이 있어야 *"이 단위가 비전 축을 가리키나"* 를 물을 수 있다(압축은 그것을 못 묻는다).
	Array<uint32> _bEvalCapOf;               // 바이트 → 캡션 번호
	Array<int>    _bEvalCapAx;               // [캡션 * 6 + 축] → 그 축의 값
	uint32        _bEvalNCaps = 0;
	uint32 _bSeq = 0, _bESeq = 0;            // 예측 자리 수 = (바이트 수 − 1)
	int    _bArm = 0, _bStep = 0;
	float  _bLoss0 = 0.0f;
	float  _bF1[kBArms] = {}, _bChance = 0.0f;
	// ★ 엔트로피를 **팔마다 남긴다** — P2-c 가 k=4 를 쓰고, P3(MDL)이 셋 다 sweep 한다.
	//   ⚠️ 평가 코퍼스는 경계망이 **학습에 쓰지 않은** 것이라 그 H 가 뜻이 있다.
	Array<float> _bEvalH;                 // 마지막 팔(k=4)
	Array<float> _bH[kBArms];
	float  _bHb[kBArms] = {}, _bHn[kBArms] = {};   // 경계/비경계 평균 엔트로피
	float  _bLossEnd[kBArms] = {};

	void _TickBoundary()
	{
		if (_bStage >= 5) return;

		// ── 0: 셋업 + 커널 검증 디스패치 ──
		if (_bStage == 0)
		{
			_bStage = 1;
			if (!_SetupBoundary()) { _bStage = 5; return; }

			MLCtxEmbedParams f;
			f.tokOff = _tCTok.offset; f.aOff = _tCSlot.offset; f.bOff = _tCOut.offset;
			f.seqLen = kCSeq; f.ctxK = kCK; f.dim = kCDim;
			if (!_bCtx.Dispatch(kCDim, kCSeq, 1u, &f, (uint32)sizeof(f)))
			{ LogA("[ml] 창임베딩: forward 디스패치 실패\n"); _bStage = 5; return; }

			MLCtxEmbedParams b;
			b.tokOff = _tCTok.offset; b.aOff = _tCDOut.offset; b.bOff = _tCDSlot.offset;
			b.seqLen = kCSeq; b.ctxK = kCK; b.dim = kCDim;
			// ⚠️ 스레드 배치가 forward 와 다르다: y 축이 **표의 행**(창자리×257)이다.
			if (!_bCtxB.Dispatch(kCDim, b.SlotRows(), 1u, &b, (uint32)sizeof(b)))
			{ LogA("[ml] 창임베딩: backward 디스패치 실패\n"); _bStage = 5; return; }

			LogA("\n[ml] 🧩 창임베딩 디스패치 — seq %u · k %u · dim %u · 표 %u행(= k×257, 마지막이 '없음')\n",
				kCSeq, kCK, kCDim, b.SlotRows());
			return;   // ⚠️ 회수는 다음 프레임(G′)
		}

		// ── 1: 커널 판정 → 통과면 팔 0 시작 ──
		if (_bStage == 1)
		{
			if (!_JudgeCtxKernel()) { _bStage = 5; return; }
			_bArm = 0;
			if (!_StartBoundaryArm(0)) { _bStage = 5; return; }
			_bStage = 2;
			return;
		}

		// ── 2: 학습 ──
		if (_bStage == 2)
		{
			if (_bStep > 0)
			{
				Bytes bp;
				if (_bnd.Read(_tBProb, bp) && bp.GetSize() == (uint64)_bSeq * kBVoc * sizeof(float))
				{
					Array<float> tgt; _BTargets(_bTrainTok, tgt);
					const float loss = MLCrossEntropyCpu((const float*)bp.GetData(), tgt.Data(),
						_bSeq, kBVoc);
					if (_bStep <= kBPerFrame) _bLoss0 = loss;
					if ((_bStep % 100) == 0 || _bStep >= kBSteps)
						LogA("[ml]   step %4d  loss %.6f nat\n", _bStep, (double)loss);
					if (_bStep >= kBSteps) _bLossEnd[_bArm] = loss;
				}
			}
			if (_bStep >= kBSteps)
			{
				_bStage = 3;
				if (!_DispatchBoundaryEval()) _bStage = 5;
				return;
			}
			for (int i = 0; i < kBPerFrame && _bStep < kBSteps; ++i)
			{
				if (!_DispatchBoundaryStep()) { _bStage = 5; return; }
				_bStep++;
			}
			return;
		}

		// ── 3: 평가 회수 → 다음 팔 or 최종 판정 ──
		if (!_RecordBoundaryArm()) { _bStage = 5; return; }
		if (_bArm + 1 < (int)kBArms)
		{
			_bArm++;
			if (!_StartBoundaryArm(_bArm)) { _bStage = 5; return; }
			_bStage = 2;
			return;
		}
		_bStage = 5;
		_JudgeBoundary();
	}

	// ㉠ **창임베딩 커널 vs CPU 레퍼런스** — 오차 0 을 요구한다.
	bool _JudgeCtxKernel()
	{
		MLCtxEmbedParams q;
		q.seqLen = kCSeq; q.ctxK = kCK; q.dim = kCDim;

		Bytes bOut, bDS;
		if (!_bnd.Read(_tCOut, bOut) || !_bnd.Read(_tCDSlot, bDS))
		{ LogA("[ml] 창임베딩 판정: ★실패★ — 회수가 안 됐다\n"); return false; }

		Array<float> tok, slot, dOut, wantOut, wantDS;
		_FillCtxInputs(tok, slot, dOut);
		wantOut.Reset(kCSeq * kCDim);
		MLCtxEmbedCpu(tok.Data(), slot.Data(), wantOut.Data(), kCSeq, kCK, kCDim);
		wantDS.Reset(q.SlotRows() * kCDim);
		MLCtxEmbedBwdCpu(tok.Data(), dOut.Data(), wantDS.Data(), kCSeq, kCK, kCDim);

		const float eF = MLMaxRelErr((const float*)bOut.GetData(), wantOut.Data(), kCSeq * kCDim);
		const float eB = MLMaxRelErr((const float*)bDS.GetData(), wantDS.Data(), q.SlotRows() * kCDim);
		const bool pass = (eF == 0.0f) && (eB == 0.0f);
		LogA("[ml] 창임베딩 판정: %s — forward %.3e · backward %.3e (CPU 레퍼런스 대비, 오차 0 을 요구)\n",
			pass ? "통과" : "★실패★", (double)eF, (double)eB);
		if (!pass)
			LogA("[ml]   ⚠️ 볼 곳: ① `i < 0` 이 **256 행**으로 가나(fwd/bwd 같은 규약) ② 창이 `t` 를 넘지"
				" 않나(인과성) ③ backward 의 y 축이 표의 행인가 ④ 행 간격이 257 인가\n");
		return pass;
	}

	// 🎲 커널 검증 입력. ★ **같은 값이 여러 자리에서** 나오게 만든다(gather 검증의 전제) ·
	//   그리고 앞 `k−1` 자리는 **'없음' 행**을 타므로 그 규약까지 같이 검산된다.
	void _FillCtxInputs(Array<float>& tok, Array<float>& slot, Array<float>& dOut) const
	{
		MLCtxEmbedParams q;
		q.seqLen = kCSeq; q.ctxK = kCK; q.dim = kCDim;
		tok.Reset(kCSeq);
		const float kT[kCSeq] = { 7, 3, 7, 1, 3, 7, 0, 1, 7, 3, 1, 7 };   // 7 이 다섯 번
		for (uint32 i = 0; i < kCSeq; ++i) tok.Data()[i] = kT[i];

		slot.Reset(q.SlotRows() * kCDim);
		for (uint32 i = 0; i < q.SlotRows() * kCDim; ++i)
			slot.Data()[i] = ((float)(i % 13) - 6.0f) * 0.25f;

		dOut.Reset(kCSeq * kCDim);
		for (uint32 i = 0; i < kCSeq * kCDim; ++i)
			dOut.Data()[i] = ((float)(i % 7) - 3.0f) * 0.125f;
	}

	// 📜 **공백을 지운 캡션 코퍼스 + 정답 경계.**
	//   ★ 공백 자리를 **경계 라벨로 옮기고** 공백 자체는 버린다 — 그것이 문제를 진짜 문제로 만든다.
	//   ⚠️ 캡션의 끝도 경계다(다음 캡션의 첫 낱말이 이어붙기 때문).
	// ★ `capOf`/`capAx` 는 **선택**이다(학습 코퍼스는 안 쓴다) — nullptr 이면 안 채운다.
	void _BuildBoundaryCorpus(uint32 baseSeed, uint32 caps,
		Array<float>& tok, Array<uint8>& bnd,
		Array<uint32>* capOf = nullptr, Array<int>* capAx = nullptr) const
	{
		Array<float> t; Array<uint8> b;
		Array<uint32> co; Array<int> ca;
		for (uint32 i = 0; i < caps; ++i)
		{
			// 🎓 경계망도 **같은 커리큘럼**을 본다(같은 데이터에서 두 채널을 견주려면 같아야 한다).
			MLScene sc;
			String cap;
			Array<int> waxIgnored;   // 경계망은 축 라벨을 안 쓴다(경계만 본다)
			MLSense::MakeLesson(baseSeed + i, sc, cap, waxIgnored);
			const char* c = cap.ptr();
			if (c == nullptr) continue;
			// ⚠️ **캡션 번호는 "실제로 담긴 캡션" 의 순서**여야 한다(빈 캡션을 건너뛰면 `i` 와 어긋난다).
			const uint32 capIdx = (uint32)(ca.Count() / 6u);
			for (int a = 0; a < 6; ++a) ca.Add(_AxisGet(sc, a));
			for (uint32 j = 0; c[j] != 0; ++j)
			{
				if (c[j] == ' ')
				{
					// ★ 방금 넣은 바이트 뒤가 경계다(공백은 버린다).
					if (b.Count() > 0) b.Data()[b.Count() - 1] = 1u;
					continue;
				}
				t.Add((float)(uint8)c[j]);
				b.Add(0u);
				co.Add(capIdx);
			}
			if (b.Count() > 0) b.Data()[b.Count() - 1] = 1u;   // 캡션 끝(종결 부호 뒤)
		}
		tok = t;
		bnd = b;
		if (capOf != nullptr) *capOf = co;
		if (capAx != nullptr) *capAx = ca;
	}

	// 장면에서 그 축의 값을 읽는다 — `_AxisSet` 의 짝이다(둘이 어긋나면 조용히 틀린다).
	static int _AxisGet(const MLScene& sc, int axis)
	{ return MLFacts::AxisGet(sc, axis); }

	// 다음 바이트(정답). ★ 입력은 `[0..n−2]`, 정답은 `[1..n−1]`.
	void _BTargets(const Array<float>& tok, Array<float>& tgt) const
	{
		const uint32 n = (uint32)tok.Count();
		tgt.Reset((n > 0u) ? (n - 1u) : 0u);
		for (uint32 i = 1; i < n; ++i) tgt.Data()[i - 1u] = tok.Data()[i];
	}

	bool _SetupBoundary()
	{
		_BuildBoundaryCorpus(31000u, kBTrainCaps, _bTrainTok, _bTrainBnd);
		// ⚠️⚠️ **씨앗이 겹치지 않는다** — 겹치면 외운 것으로 경계를 찍고 판정이 무의미해진다.
		_BuildBoundaryCorpus(77000u, kBEvalCaps, _bEvalTok, _bEvalBnd,
			&_bEvalCapOf, &_bEvalCapAx);
		_bEvalNCaps = (uint32)(_bEvalCapAx.Count() / 6u);
		const uint32 n1 = (uint32)_bTrainTok.Count(), n2 = (uint32)_bEvalTok.Count();
		if (n1 < 8u || n2 < 8u) { LogA("[ml] 경계망: 코퍼스가 비었다\n"); return false; }
		_bSeq  = n1 - 1u;
		_bESeq = n2 - 1u;

		MLCtxEmbedParams q;
		q.ctxK = kBKMax; q.dim = kBDim;
		const uint32 need =
			n1 + n2                                  // tok · evalTok
			+ _bSeq * kBVoc * 4u                     // onehot · logits · probs · dLogits
			+ _bSeq * kBDim * 2u                     // ctx · dCtx
			+ q.SlotRows() * kBDim * 4u              // slot · dSlot · m · v
			+ kBDim * kBVoc * 4u                     // W · dW · m · v
			+ _bESeq * (kBVoc * 2u + kBDim)          // 평가: logits · probs · ctx
			+ kCSeq + (kCK * 257u) * kCDim * 2u + kCSeq * kCDim * 2u   // 커널 검증
			// ★ P3-c 경계 머리 — `ctx` 를 **그대로 재사용**하므로 작은 것만 더 잡는다.
			//   ⚠️ 슬롯 표는 **얼려 둔다**(이미 바이트 LM 으로 학습된 표현) → `ctx_embed_bwd` 가 없다.
			+ (_bSeq + _bESeq) * 2u * 3u             // onehot · logits · probs (학습·평가)
			+ _bSeq * 2u                             // dLogits
			+ kBDim * 2u * 4u                        // W · dW · m · v
			+ 256u;
		if (!_bnd.Create(rhi, need))
		{ LogA("[ml] 경계망: 아레나 생성 실패(%u floats)\n", need); return false; }

		// 커널 검증용 — ★ 같은 아레나·같은 커널 인스턴스를 검산한다.
		_tCTok   = _bnd.Alloc(1, kCSeq);
		_tCSlot  = _bnd.Alloc(kCK * 257u, kCDim);
		_tCOut   = _bnd.Alloc(kCSeq, kCDim);
		_tCDOut  = _bnd.Alloc(kCSeq, kCDim);
		_tCDSlot = _bnd.Alloc(kCK * 257u, kCDim);

		_tBTok    = _bnd.Alloc(1, n1);
		_tBETok   = _bnd.Alloc(1, n2);
		_tBOne    = _bnd.Alloc(_bSeq, kBVoc);
		_tBSlot   = _bnd.Alloc(q.SlotRows(), kBDim);
		_tBW      = _bnd.Alloc(kBDim, kBVoc);
		_tBCtx    = _bnd.Alloc(_bSeq, kBDim);
		_tBLogit  = _bnd.Alloc(_bSeq, kBVoc);
		_tBProb   = _bnd.Alloc(_bSeq, kBVoc);
		_tBDLogit = _bnd.Alloc(_bSeq, kBVoc);
		_tBDCtx   = _bnd.Alloc(_bSeq, kBDim);
		_tBDSlot  = _bnd.Alloc(q.SlotRows(), kBDim);
		_tBDW     = _bnd.Alloc(kBDim, kBVoc);
		_tBMS     = _bnd.Alloc(q.SlotRows(), kBDim);
		_tBVS     = _bnd.Alloc(q.SlotRows(), kBDim);
		_tBMW     = _bnd.Alloc(kBDim, kBVoc);
		_tBVW     = _bnd.Alloc(kBDim, kBVoc);
		_tBECtx   = _bnd.Alloc(_bESeq, kBDim);
		_tBELogit = _bnd.Alloc(_bESeq, kBVoc);
		_tBEProb  = _bnd.Alloc(_bESeq, kBVoc);
		// P3-c 경계 머리 — **2분류**(경계다/아니다). ⚠️ softmax 2열 = sigmoid 와 같다(새 커널이 없다).
		_tHOne    = _bnd.Alloc(_bSeq, 2);
		_tHLogit  = _bnd.Alloc(_bSeq, 2);
		_tHProb   = _bnd.Alloc(_bSeq, 2);
		_tHDLogit = _bnd.Alloc(_bSeq, 2);
		_tHELogit = _bnd.Alloc(_bESeq, 2);
		_tHEProb  = _bnd.Alloc(_bESeq, 2);
		_tHW      = _bnd.Alloc(kBDim, 2);
		_tHDW     = _bnd.Alloc(kBDim, 2);
		_tHMW     = _bnd.Alloc(kBDim, 2);
		_tHVW     = _bnd.Alloc(kBDim, 2);
		if (!_tHVW.IsValid()) { LogA("[ml] 경계망: 텐서 할당 실패(아레나 부족)\n"); return false; }

		// 커널 검증 입력
		Array<float> ctok, cslot, cdout;
		_FillCtxInputs(ctok, cslot, cdout);
		if (!_bnd.Write(_tCTok, ctok) || !_bnd.Write(_tCSlot, cslot)
			|| !_bnd.Write(_tCDOut, cdout))
		{ LogA("[ml] 경계망: 검증 입력 업로드 실패\n"); return false; }

		// 코퍼스 + onehot(다음 바이트)
		Array<float> one;
		one.Reset((uint64)_bSeq * kBVoc);
		for (uint64 i = 0; i < (uint64)_bSeq * kBVoc; ++i) one.Data()[i] = 0.0f;
		for (uint32 t = 0; t < _bSeq; ++t)
		{
			uint32 v = (uint32)_bTrainTok.Data()[t + 1u];
			if (v >= kBVoc) v = 0u;
			one.Data()[(uint64)t * kBVoc + v] = 1.0f;
		}
		if (!_bnd.Write(_tBTok, _bTrainTok) || !_bnd.Write(_tBETok, _bEvalTok)
			|| !_bnd.Write(_tBOne, one))
		{ LogA("[ml] 경계망: 코퍼스 업로드 실패\n"); return false; }

		if (!_LoadKernelIn(_bCtx,  "shaders/ctx_embed.cs.spv",     _bnd)) return false;
		if (!_LoadKernelIn(_bCtxB, "shaders/ctx_embed_bwd.cs.spv", _bnd)) return false;
		if (!_LoadKernelIn(_bGemm, "shaders/gemm.cs.spv",          _bnd)) return false;
		if (!_LoadKernelIn(_bSoft, "shaders/softmax.cs.spv",       _bnd)) return false;
		if (!_LoadKernelIn(_bSub,  "shaders/sub.cs.spv",           _bnd)) return false;
		if (!_LoadKernelIn(_bAdam, "shaders/adamw.cs.spv",         _bnd)) return false;

		// 정답 경계가 전부 **음절 경계**인지 확인한다(그렇지 않으면 후보 제한이 정답을 잘라 먹는다).
		uint32 truth = 0, cand = 0, offCand = 0;
		for (uint32 t = 0; t + 1u < (uint32)_bEvalTok.Count(); ++t)
		{
			const bool isCand = _IsLead((uint8)_bEvalTok.Data()[t + 1u]);
			if (isCand) cand++;
			if (_bEvalBnd.Data()[t] != 0u) { truth++; if (!isCand) offCand++; }
		}
		_bChance = (cand > 0u) ? ((float)truth / (float)cand) : 0.0f;
		LogA("[ml] 🧩 경계망 코퍼스 — 학습 %u바이트(캡션 %u) · 평가 %u바이트(캡션 %u) · 공백 지움\n"
			"[ml]   평가: 음절 후보 %u · 정답 경계 %u ⇒ **우연 F1 = %.4f** (후보에서 무작위로 %u개 고를 때)\n"
			"[ml]   ⚠️ 후보 밖 정답 %u개 (0 이어야 한다 — 낱말 경계는 늘 음절 경계다)\n",
			(uint32)_bTrainTok.Count(), kBTrainCaps, (uint32)_bEvalTok.Count(), kBEvalCaps,
			cand, truth, (double)_bChance, truth, offCand);
		return true;
	}

	// UTF-8 **선두 바이트**인가(계속 바이트 `10xxxxxx` 가 아닌가). ★ 이것이 L1 발판이다.
	static bool _IsLead(uint8 b) { return (b & 0xC0u) != 0x80u; }

	// 🔁 팔 하나(창 길이 `k`) 를 처음부터 — 가중치와 모멘트를 갈아 끼운다.
	bool _StartBoundaryArm(int arm)
	{
		const uint32 k = _BK(arm);
		_bStep = 0;

		MLCtxEmbedParams q;
		q.ctxK = kBKMax; q.dim = kBDim;
		SeedRand(MLEpisodeGen::ScrambleSeed(9100u + (uint32)arm));
		Array<float> slot, w;
		slot.Reset((uint64)q.SlotRows() * kBDim);
		// ⚠️ 이 팔이 안 쓰는 행(`k×257` 이후)은 **0** 으로 둔다 — 함정 18(안 쓰는 칸) 예방.
		for (uint64 i = 0; i < (uint64)q.SlotRows() * kBDim; ++i)
			slot.Data()[i] = (i < (uint64)k * 257u * kBDim)
				? (((float)RandInt(0, 2001) * 0.001f - 1.0f) * (0.4f / (float)k)) : 0.0f;
		w.Reset((uint64)kBDim * kBVoc);
		for (uint64 i = 0; i < (uint64)kBDim * kBVoc; ++i)
			w.Data()[i] = ((float)RandInt(0, 2001) * 0.001f - 1.0f) * (0.4f / (float)kBDim);

		if (!_bnd.Write(_tBSlot, slot) || !_bnd.Write(_tBW, w))
		{ LogA("[ml] 경계망: 가중치 업로드 실패\n"); return false; }
		if (!_ZeroB(_tBMS) || !_ZeroB(_tBVS) || !_ZeroB(_tBMW) || !_ZeroB(_tBVW))
		{ LogA("[ml] 경계망: 모멘트 초기화 실패\n"); return false; }

		LogA("\n[ml] ── 🧩 창 k=%u %s (표 %u행 · dim %u · %d스텝)\n",
			k, (k == 1u) ? "← **바이그램 기준선**(함정 4)" : "", k * 257u, kBDim, kBSteps);
		return true;
	}

	bool _ZeroB(const MLTensor& t)
	{
		Array<float> z;
		z.Reset(t.Count());
		for (uint32 i = 0; i < t.Count(); ++i) z.Data()[i] = 0.0f;
		return _bnd.Write(t, z);
	}

	// 한 스텝 = 디스패치 여덟(전체 시퀀스 배치). ★ P1 바이트 LM 과 **같은 모양**이고 임베딩만 창이다.
	bool _DispatchBoundaryStep()
	{
		const uint32 k = _BK(_bArm);

		// ① ctx = Σ_j slot[(j, byte(t−k+1+j))]   ★ 인과적(창이 `t` 에서 끝난다)
		MLCtxEmbedParams e;
		e.tokOff = _tBTok.offset; e.aOff = _tBSlot.offset; e.bOff = _tBCtx.offset;
		e.seqLen = _bSeq; e.ctxK = k; e.dim = kBDim;
		if (!_bCtx.Dispatch(kBDim, _bSeq, 1u, &e, (uint32)sizeof(e))) return _Fail("bnd ctx");

		// ② logits = ctx · W
		MLGemmParams g;
		g.aOff = _tBCtx.offset; g.bOff = _tBW.offset; g.cOff = _tBLogit.offset;
		g.M = _bSeq; g.N = kBVoc; g.K = kBDim;
		if (!_bGemm.Dispatch(kBVoc, _bSeq, 1u, &g, (uint32)sizeof(g))) return _Fail("bnd logits");

		// ③ probs = softmax(logits)
		MLSoftmaxParams sm;
		sm.inOff = _tBLogit.offset; sm.outOff = _tBProb.offset; sm.rows = _bSeq; sm.cols = kBVoc;
		if (!_bSoft.Dispatch(_bSeq, 1u, 1u, &sm, (uint32)sizeof(sm))) return _Fail("bnd softmax");

		// ④ dLogits = probs − onehot
		MLSubParams sb;
		sb.aOff = _tBProb.offset; sb.bOff = _tBOne.offset; sb.outOff = _tBDLogit.offset;
		sb.count = _bSeq * kBVoc;
		if (!_bSub.Dispatch(sb.count, 1u, 1u, &sb, (uint32)sizeof(sb))) return _Fail("bnd dlogits");

		// ⑤ dW = ctxᵀ · dLogits
		MLGemmParams gw;
		gw.aOff = _tBCtx.offset; gw.bOff = _tBDLogit.offset; gw.cOff = _tBDW.offset;
		gw.M = kBDim; gw.N = kBVoc; gw.K = _bSeq; gw.transA = 1;
		if (!_bGemm.Dispatch(kBVoc, kBDim, 1u, &gw, (uint32)sizeof(gw))) return _Fail("bnd dW");

		// ⑥ dCtx = dLogits · Wᵀ — ⚠️ W 는 D×V 저장이므로 `transB = 1`
		MLGemmParams gc;
		gc.aOff = _tBDLogit.offset; gc.bOff = _tBW.offset; gc.cOff = _tBDCtx.offset;
		gc.M = _bSeq; gc.N = kBDim; gc.K = kBVoc; gc.transB = 1;
		if (!_bGemm.Dispatch(kBDim, _bSeq, 1u, &gc, (uint32)sizeof(gc))) return _Fail("bnd dCtx");

		// ⑦ dSlot — **gather**
		MLCtxEmbedParams eb;
		eb.tokOff = _tBTok.offset; eb.aOff = _tBDCtx.offset; eb.bOff = _tBDSlot.offset;
		eb.seqLen = _bSeq; eb.ctxK = k; eb.dim = kBDim;
		if (!_bCtxB.Dispatch(kBDim, eb.SlotRows(), 1u, &eb, (uint32)sizeof(eb)))
			return _Fail("bnd dSlot");

		// ⑧ AdamW × 2. ⚠️ 표는 **이 팔이 쓰는 `k×257` 행만** 갱신한다(나머지는 0 이고 안 읽힌다).
		float bc1 = 1.0f, bc2 = 1.0f;
		_BiasCorr(_bStep + 1, bc1, bc2);
		MLAdamWParams aw;
		aw.lr = kBLr; aw.beta1 = kB1; aw.beta2 = kB2; aw.eps = kAdamEps; aw.wd = kWd;
		aw.bc1 = bc1; aw.bc2 = bc2;
		aw.pOff = _tBSlot.offset; aw.gOff = _tBDSlot.offset;
		aw.mOff = _tBMS.offset;   aw.vOff = _tBVS.offset;   aw.count = k * 257u * kBDim;
		if (!_bAdam.Dispatch(aw.count, 1u, 1u, &aw, (uint32)sizeof(aw))) return _Fail("bnd adamw slot");

		MLAdamWParams ax = aw;
		ax.pOff = _tBW.offset;  ax.gOff = _tBDW.offset;
		ax.mOff = _tBMW.offset; ax.vOff = _tBVW.offset; ax.count = _tBW.Count();
		if (!_bAdam.Dispatch(ax.count, 1u, 1u, &ax, (uint32)sizeof(ax))) return _Fail("bnd adamw W");
		return true;
	}

	// 📏 **평가 = 안 본 캡션에 forward 만.** ⚠️ 역전파도 옵티마이저도 없다(손대면 판정이 무의미해진다).
	bool _DispatchBoundaryEval()
	{
		const uint32 k = _BK(_bArm);
		MLCtxEmbedParams e;
		e.tokOff = _tBETok.offset; e.aOff = _tBSlot.offset; e.bOff = _tBECtx.offset;
		e.seqLen = _bESeq; e.ctxK = k; e.dim = kBDim;
		if (!_bCtx.Dispatch(kBDim, _bESeq, 1u, &e, (uint32)sizeof(e))) return _Fail("eval ctx");

		MLGemmParams g;
		g.aOff = _tBECtx.offset; g.bOff = _tBW.offset; g.cOff = _tBELogit.offset;
		g.M = _bESeq; g.N = kBVoc; g.K = kBDim;
		if (!_bGemm.Dispatch(kBVoc, _bESeq, 1u, &g, (uint32)sizeof(g))) return _Fail("eval logits");

		MLSoftmaxParams sm;
		sm.inOff = _tBELogit.offset; sm.outOff = _tBEProb.offset;
		sm.rows = _bESeq; sm.cols = kBVoc;
		if (!_bSoft.Dispatch(_bESeq, 1u, 1u, &sm, (uint32)sizeof(sm))) return _Fail("eval softmax");
		return true;
	}

	// 📥 팔 하나의 결과 — **엔트로피에서 경계를 읽고** 정답과 견준다.
	bool _RecordBoundaryArm()
	{
		Bytes bp;
		if (!_bnd.Read(_tBEProb, bp) || bp.GetSize() != (uint64)_bESeq * kBVoc * sizeof(float))
		{ LogA("[ml] 경계망: 평가 회수가 안 됐다(k=%u)\n", _BK(_bArm)); return false; }

		Array<float> H;
		H.Reset(_bESeq);
		MLRowEntropyCpu((const float*)bp.GetData(), H.Data(), _bESeq, kBVoc);
		_bH[_bArm] = H;                             // ★ 팔마다 남긴다(P3 이 셋 다 쓴다)
		if (_bArm + 1 == (int)kBArms) _bEvalH = H;   // ★ 마지막 팔(k=4) = P2-c 가 쓰는 것

		// 후보 = **음절 경계**(다음 바이트가 UTF-8 선두 바이트) — L1 발판.
		Array<uint32> cand;
		uint32 truth = 0;
		for (uint32 t = 0; t + 1u < (uint32)_bEvalTok.Count(); ++t)
		{
			if (!_IsLead((uint8)_bEvalTok.Data()[t + 1u])) continue;
			cand.Add(t);
			if (_bEvalBnd.Data()[t] != 0u) truth++;
		}
		if (truth == 0u || cand.Count() == 0u)
		{ LogA("[ml] 경계망: 후보/정답이 없다\n"); return false; }

		// ★ **상위 M개를 고른다**(M = 정답 개수) ⇒ precision = recall = F1 이 되어 한 숫자다.
		//   ⚠️ 임계값을 두지 않는 이유: 결과를 보고 임계값을 맞추면 판정이 아니다. 개수만 알려주고
		//     **어디인지는 모델이 정한다**.
		Array<uint8> taken;
		taken.Reset(cand.Count());
		for (uint32 i = 0; i < (uint32)cand.Count(); ++i) taken.Data()[i] = 0u;
		uint32 hit = 0;
		for (uint32 m = 0; m < truth; ++m)
		{
			int best = -1;
			for (uint32 i = 0; i < (uint32)cand.Count(); ++i)
			{
				if (taken.Data()[i] != 0u) continue;
				if (best < 0 || H.Data()[cand.Data()[i]] > H.Data()[cand.Data()[(uint32)best]]) best = (int)i;
			}
			if (best < 0) break;
			taken.Data()[best] = 1u;
			if (_bEvalBnd.Data()[cand.Data()[(uint32)best]] != 0u) hit++;
		}
		_bF1[_bArm] = (float)hit / (float)truth;

		// ★ 임계값 없는 둘째 증거 — 경계/비경계 후보의 **평균 엔트로피**.
		float hb = 0.0f, hn = 0.0f;
		uint32 nb = 0, nn = 0;
		for (uint32 i = 0; i < (uint32)cand.Count(); ++i)
		{
			const uint32 t = cand.Data()[i];
			if (_bEvalBnd.Data()[t] != 0u) { hb += H.Data()[t]; nb++; }
			else                           { hn += H.Data()[t]; nn++; }
		}
		_bHb[_bArm] = (nb > 0u) ? (hb / (float)nb) : 0.0f;
		_bHn[_bArm] = (nn > 0u) ? (hn / (float)nn) : 0.0f;

		LogA("[ml]   → 경계 %u/%u 적중 · **F1 %.4f** (우연 %.4f) · 평균 H: 경계 %.4f vs 비경계 %.4f\n",
			hit, truth, (double)_bF1[_bArm], (double)_bChance,
			(double)_bHb[_bArm], (double)_bHn[_bArm]);
		return true;
	}

	// ★ **경계 F1 의 자도 `정규화 이득`이다** `(F1 − 우연) / (1 − 우연)`.
	//   ⚠️⚠️ **처음에 잡은 기준(*"우연의 2배"*)이 잘못 설계돼 있었다.** 이 과제의 우연 F1 이 **0.4551**
	//     이라(음절 경계의 절반 가까이가 낱말 경계다) *"2배"* 가 `0.9102` = **이득 0.835** 를 요구하는
	//     셈이었고, 그것은 다른 판정에서 쓰는 문턱(**이득 0.5**)보다 훨씬 세다.
	//   ★ 교훈: **우연이 높은 지표에 "배수" 를 쓰면 문턱이 폭주한다.** 배수는 우연이 작을 때만 뜻이 있다.
	//   ⇒ P2-b1 에서 이미 쓰는 자로 통일한다 — 결과를 보고 만든 새 문턱이 아니라 **이미 쓰던 문턱**이다.
	static float _BGain(float f1, float chance)
	{
		if (chance >= 1.0f) return 0.0f;
		return (f1 - chance) / (1.0f - chance);
	}

	// ㉡ **경계 판정 — 표 하나로.**
	void _JudgeBoundary()
	{
		LogA("\n[ml] 🧩 **경계망 표** — 안 본 캡션(공백 지움)에서 `H(다음|창)` 상위 M개를 경계로 고른다\n"
			"[ml]   후보는 음절 경계뿐(L1 발판) · M = 정답 개수 ⇒ precision = recall = F1\n"
			"[ml]   이득 = (F1 − 우연)/(1 − 우연) · 우연 F1 = **%.4f**\n"
			"[ml]   %-5s %9s %8s %7s %10s %11s %9s\n",
			(double)_bChance, "창 k", "학습손실", "F1", "이득", "H(경계)", "H(비경계)", "H 비율");
		for (uint32 a = 0; a < kBArms; ++a)
		{
			const float ratio = (_bHn[a] > 1.0e-6f) ? (_bHb[a] / _bHn[a]) : 0.0f;
			LogA("[ml]   %-5u %9.4f %8.4f %+7.3f %10.4f %11.4f %9.1f%s\n",
				_BK(a), (double)_bLossEnd[a], (double)_bF1[a],
				(double)_BGain(_bF1[a], _bChance), (double)_bHb[a], (double)_bHn[a], (double)ratio,
				(_BK(a) == 1u) ? "  ← 바이그램" : "");
		}

		const float f1big = _bF1[kBArms - 1u], f1bi = _bF1[0];
		const float gBig = _BGain(f1big, _bChance), gBi = _BGain(f1bi, _bChance);
		const float rBig = (_bHn[kBArms - 1u] > 1.0e-6f) ? (_bHb[kBArms - 1u] / _bHn[kBArms - 1u]) : 0.0f;
		const float rBi  = (_bHn[0] > 1.0e-6f) ? (_bHb[0] / _bHn[0]) : 0.0f;
		// ★ 기준은 다른 판정과 **같은 것**을 쓴다: 이득 > 0.5 = "우연과 완벽 사이의 절반을 메웠다".
		const bool okAbs = (gBig > 0.5f);
		const bool okTrap = (gBig > gBi + 0.20f);
		LogA("[ml] P2-b2 판정: %s\n"
			"[ml]   ㉠ 절대: k=%u 의 이득 %+.3f (F1 %.4f · 우연 %.4f · 기준 > 0.5) → %s\n"
			"[ml]   ㉡ **함정 4 가 실물로 확인됐다**: 바이그램 이득 %+.3f vs 접두사 %+.3f → %s\n"
			"[ml]      ★ 그리고 더 뚜렷한 증거는 **H 비율**(임계값이 안 들어간다):\n"
			"[ml]        바이그램 **%.2f배**(경계와 낱말 안의 엔트로피가 거의 같다 = 신호가 없다)\n"
			"[ml]        접두사   **%.1f배**(낱말 안은 H≈%.4f 로 거의 0 · 경계에서만 솟는다)\n"
			"[ml]      ⇒ *\"쌍(bigram) 점수로는 그럴싸한 숫자가 나오지만 접두사 정보가 없어 낱말 경계를\n"
			"[ml]        못 찾는다\"* 가 **숫자로** 나왔다.\n",
			(okAbs && okTrap) ? "통과" : "★실패★",
			_BK((int)kBArms - 1), (double)gBig, (double)f1big, (double)_bChance,
			okAbs ? "통과" : "★실패★",
			(double)gBi, (double)gBig, okTrap ? "통과" : "★실패★",
			(double)rBi, (double)rBig, (double)_bHn[kBArms - 1u]);

		// ⚠️ F1 의 상한이 왜 막히나 — 원인을 적어 둔다(다음 단계의 근거가 된다).
		LogA("[ml]   ⚠️ **F1 이 1.0 에 못 가는 이유는 엔트로피 단독의 한계다.** 캡션 템플릿에서 어떤 낱말\n"
			"[ml]      경계는 **다음 슬롯의 후보가 하나뿐**이어서 그 자리 H 가 낮다(예: 속낱말 뒤에 모양이\n"
			"[ml]      두 가지뿐). 경계인데 예측이 되는 것이다.\n"
			"[ml]      ⇒ ★ 그래서 경계를 **엔트로피 하나로** 정하면 안 되고 **압축 이득**(MDL · P3)이 필요하다:\n"
			"[ml]        `L = L_pred + λ·L_recon + β·N_symbols` 의 `β·N` 항이 *\"덩어리로 묶으면 심볼이\n"
			"[ml]        줄어든다\"* 를 보상하므로, 예측이 되는 경계도 **묶는 이득**으로 잡힌다.\n");
		if (!okAbs)
			LogA("[ml]   ⚠️ 볼 곳: ① 과적합으로 H 가 전부 0 이 됐나(학습손실을 보라) ② 창이 인과적인가\n"
				"[ml]      ③ 후보가 음절 경계인가 ④ 공백이 정말 지워졌나(남아 있으면 오히려 쉬워진다)\n");
		if (!okTrap)
			LogA("[ml]   ⚠️ 바이그램이 비슷하게 잘하면 **이 코퍼스가 너무 규칙적**이라는 뜻이다 —\n"
				"[ml]      같은 음절이 **여러 문맥**에 오는 코퍼스가 필요하다(코드를 섞거나 어순 변형).\n");
		_ShowBoundaries(280u);
	}

	// 👁️ **경계를 그려 본다** — 숫자만으로는 "어디서 잘못 잘랐나" 를 못 본다.
	//   `|` 맞음 · `?` 헛경계(없는 데 잘랐다) · `!` 놓침(있는데 안 잘랐다)
	//   ⚠️ 표시를 **음절 경계에만** 꽂으므로 UTF-8 이 깨지지 않는다(낱말 경계는 늘 음절 경계다).
	void _ShowBoundaries(uint32 maxBytes)
	{
		if (_bEvalH.Count() == 0u) { LogA("[ml]   (엔트로피가 없어 경계를 못 그린다)\n"); return; }
		const uint32 n = (uint32)_bEvalTok.Count();

		// 앞부분에 대해 후보와 정답을 모으고 **정답 개수만큼** 상위 H 를 고른다(판정과 같은 규칙).
		Array<uint32> cand;
		uint32 truth = 0;
		const uint32 lim = (maxBytes < n - 1u) ? maxBytes : (n - 1u);
		for (uint32 t = 0; t + 1u < lim; ++t)
		{
			if (!_IsLead((uint8)_bEvalTok.Data()[t + 1u])) continue;
			cand.Add(t);
			if (_bEvalBnd.Data()[t] != 0u) truth++;
		}
		if (cand.Count() == 0u || truth == 0u) return;

		Array<uint8> pred;
		pred.Reset(n);
		for (uint32 i = 0; i < n; ++i) pred.Data()[i] = 0u;
		Array<uint8> taken;
		taken.Reset(cand.Count());
		for (uint32 i = 0; i < (uint32)cand.Count(); ++i) taken.Data()[i] = 0u;
		for (uint32 m = 0; m < truth; ++m)
		{
			int best = -1;
			for (uint32 i = 0; i < (uint32)cand.Count(); ++i)
			{
				if (taken.Data()[i] != 0u) continue;
				if (best < 0 || _bEvalH.Data()[cand.Data()[i]]
					> _bEvalH.Data()[cand.Data()[(uint32)best]]) best = (int)i;
			}
			if (best < 0) break;
			taken.Data()[best] = 1u;
			pred.Data()[cand.Data()[(uint32)best]] = 1u;
		}

		// ⚠️⚠️⚠️ **`String` 에 바이트를 한 개씩 붙이면 안 된다 — 한글은 multi-byte 라 계속 바이트 하나가
		//   유효한 UTF-8 이 아니고 `String` 이 그것을 **거절**한다.** 결과가 무섭다: 마커만 남고
		//   글자가 통째로 사라진다(실측 — 이 세션에서 `_SplitWords` 로 **한 번 밟고 또 밟았다**).
		//   ⇒ **`Bytes` 로 모아 한 번에** 넘긴다(경계 마커는 ASCII 라 UTF-8 경계를 안 깬다).
		Bytes buf;
		buf.Reset((uint64)lim * 2ull + 8ull);
		uint8* q = (uint8*)buf.GetData();
		uint64 w = 0;
		for (uint32 t = 0; t < lim; ++t)
		{
			q[w++] = (uint8)_bEvalTok.Data()[t];
			const bool p = (pred.Data()[t] != 0u), g = (_bEvalBnd.Data()[t] != 0u);
			if (p && g)       q[w++] = (uint8)'|';
			else if (p)       q[w++] = (uint8)'?';
			else if (g)       q[w++] = (uint8)'!';
		}
		q[w] = 0u;
		LogA("[ml]\n[ml] 👁️ **경계 그림**(k=%u · `|`맞음 `?`헛경계 `!`놓침) — 앞 %u바이트:\n[ml]   %s\n",
			_BK((int)kBArms - 1), lim, (const char*)q);
	}

	// ── ⚖️ **P3-a · MDL** — 압축 비용이 **경계를 고른다**(개수를 안 알려준다) ─────────────────
	//
	// ★ **왜 이것이 먼저인가**: `N_symbols` 는 이산 개수라 **미분이 안 된다**. 미분 가능한 판
	//   (기대 개수 · straight-through)을 짜기 전에 **손실 설계 자체가 맞는지**를 확인해야 한다 —
	//   *"압축을 넣으면 최적점이 낱말 경계에 생기나?"* 아니면 `β·N` 항이 애초에 틀린 것이다.
	//   ⇒ 그래서 먼저 **완전히 결정적인 CPU 계산**으로 잰다(이 프로젝트의 CPU-레퍼런스-먼저 관용구).
	//
	// ★ **이것이 P2-b2 의 약점을 고친다.** 거기서는 **경계 개수를 알려줬다**(`M` = 정답 개수) —
	//   그건 오라클이다. MDL 은 *"몇 개로 자를까"* 까지 **목적함수가 정한다.**
	//
	// ★ **두 부분 코드(two-part code)** — 서술 길이를 **bit 로** 센다:
	//     ㉠ **사전**: 종류마다 그 바이트열 = `Σ_types (len + 1) × 8` bit  (+1 = 끝 표시)
	//     ㉡ **본문**: 심볼 열      = `심볼 개수 × log2(종류 수)` bit
	//     ⇒ `DL = 사전 + 본문`. ★ 잔차가 **0** 이다 — 사전이 바이트열을 그대로 담으므로 완전 복원이다.
	//   ★ 그래서 `L = L_pred + λ·L_recon + β·N_symbols` 의 세 항이 여기서 **한 단위(bit)로 만난다**:
	//     `본문`이 `L_pred` 자리 · `사전`이 `β·N_symbols` 자리 · `잔차 0` 이 `L_recon` 자리다.
	//   ⚠️ 사전 크기 `T` 자체를 적는 비용은 뺐다(수십 bit 라 결론이 안 바뀐다) — 적어 두고 넘어간다.
	//
	// ★ **팔마다 sweep 한다**: `H` 문턱 τ 를 훑어 `DL(τ)` 의 **최소**를 찾는다. 그리고 그 자리의
	//   경계 개수·F1 을 정답과 견준다. ⚠️ k=1(바이그램)도 같이 훑어 **함정 4 의 MDL 판**을 본다.
	// ══════════════════════════════════════════════════════════════════════════
	// 🔮 **P3-a′ — 기준을 "압축" 에서 "예측" 으로 옮긴다.**
	//
	// ★ **왜**: 옛 본문 항이 `심볼수 × log2(종류수)` 였다 — 즉 심볼이 **i.i.d. 균등**이라고 가정한다.
	//   ⇒ **심볼끼리 서로를 예측하는지 아예 묻지 않는다.** 그래서 어휘가 작은 `음절 전부` 가 이긴다
	//     (커리큘럼 코퍼스에서 실제로 부호가 뒤집혔다: 정답 2956 > 음절전부 2764).
	//   ★ 그리고 옛 사전 항 `(len+1)×8` 도 **바이트를 날로 8bit** 에 적는다 = 최대한 비예측적이다.
	//     `사과` 처럼 **예측 가능한 음절 조합**이 싸게 적혀야 하는데 길이에만 비례해 벌을 받는다.
	//   ⇒ **두 항 모두 예측적으로** 바꾼다:
	//       사전 = Σ_types [ 그 바이트열을 **프리퀀셜 바이트 바이그램**으로 코딩 + 8bit 종료표시 ]
	//       본문 = Σ_i −log2 P̂(s_i | s_{i−1})   (**프리퀀셜 심볼 바이그램**)
	//   ★ **프리퀀셜**(앞에서 본 것만으로 다음을 코딩 · add-½ = KT 추정)이라 별도 모델 비용도,
	//     held-out 분할도 필요 없다 — **암기는 스스로 벌받는다**(처음 보는 종류는 최대 놀람이다).
	//
	// ⚠️⚠️⚠️ **예측을 미리 적는다(반증 가능하게).**
	//   **사슬규칙 때문에 완전히 예측적인 코딩은 분할에 거의 불변일 것이다**:
	//     `−log2 P(사과|·) = −log2 P(사|·) − log2 P(과|사,·)`
	//   ⇒ 낱말로 묶어도 음절로 쪼개도 **총 bit 가 거의 같다.** 신호를 만드는 것은 **문맥의 양**뿐이다
	//     (order-1 에서 낱말 하나는 음절 하나보다 더 많은 과거를 조건으로 준다).
	//   ★ 그러므로 **결과 셋 중 하나가 나온다:**
	//     ㉠ 낱말이 이긴다 ⇒ 예측 기준이 답이다(옛 기준이 틀렸을 뿐).
	//     ㉡ 거의 같다(±3% 안) ⇒ **코드 길이로는 경계를 정할 수 없다**(사슬규칙). 그러면 다음 기준은
	//        **교차채널 쓸모**다 — *"이 단위가 비전 축을 예측하나"*(낱말이 낱말인 이유는 압축이 되기
	//        때문이 아니라 **세계의 무언가를 가리키기 때문**이다).
	//     ㉢ 음절이 더 이긴다 ⇒ 내 구현이 틀렸다(사전 항을 의심한다).
	//   ⇒ ★ **어느 쪽이든 정보다.** ㉡ 이 나오는 것이 실패가 아니라 **MDL 을 놓아야 하는 증명**이다.
	int _mStage = 0;
	static constexpr uint32 kMSteps = 48;      // τ 격자
	static constexpr float  kMAlpha = 0.5f;    // add-½ (KT) — 프리퀀셜의 표준
	struct MdlPoint
	{
		float tau = 0.0f;
		uint32 spans = 0, types = 0;
		float dl = 0.0f, f1 = 0.0f;            // 옛 기준(무조건부)
		float dictOld = 0.0f, bodyOld = 0.0f;
		float dlPred = 0.0f;                   // 새 기준(예측적)
		float dictPred = 0.0f, bodyPred = 0.0f;
		// 🌉 교차채널 쓸모 — 섞음 기준선을 뺀 정규화 상호정보(6축 합).
		float utilSpan = 0.0f;                 // **span 당**: 정보를 몇 조각으로 나눴나에 민감하다
		float utilCap = 0.0f;                  // **캡션 당**(단일 심볼 최선): 조각 수에 중립인 대조군
	};
	MdlPoint _mBest[kBArms];                   // 옛 기준의 최소
	MdlPoint _mBestP[kBArms];                  // **새 기준**의 최소
	MdlPoint _mTruth, _mSyll, _mNone;
	// ⚠️⚠️ **표를 멤버로 올려 재사용한다 — 호출마다 새로 잡으면 큰 churn 이다.**
	//   실측: `_DictPredBits` 가 호출마다 `257×256` uint32(**263KB**)를, `_BodyPredBits` 가
	//   `종류²`(최대 **250KB**)를 잡았고 τ 48점 × 3팔 ≈ **147회** ⇒ ~75MB 를 잡았다 버렸다.
	//   ★ 그리고 그 뒤 단계(P3-b)에서 **간헐 APPCRASH**(`ucrtbase` 0xc0000005)가 났다 —
	//     단편화가 유력한 후보라 먼저 이것을 없앤다(어차피 옳은 개선이다).
	//   ⚠️ `mutable` 인 이유: `_MdlOf`/`_SweepTau` 가 `const` 이고 그 사슬을 다 풀면 변경이 커진다.
	mutable Array<uint32> _mCb, _mCt, _mCs, _mCp;

	void _TickMdl()
	{
		if (_mStage >= 1) return;
		_mStage = 1;
		if (_bEvalTok.Count() == 0u || _bH[0].Count() == 0u)
		{ LogA("[ml] MDL: 경계망 결과가 없다\n"); return; }

		// 기준점 셋 — 문턱과 무관한 청킹들.
		_mTruth = _MdlOf(_TruthMask(), 0.0f);
		_mSyll  = _MdlOf(_SyllMask(),  0.0f);
		_mNone  = _MdlOf(_NoneMask(),  0.0f);

		for (uint32 a = 0; a < kBArms; ++a) _mBest[a] = _SweepTau(a, _mBestP[a]);
		_JudgeMdl();
	}

	// 후보(음절 경계) 목록.
	void _Candidates(Array<uint32>& out) const
	{
		out.Reset(0);
		const uint32 n = (uint32)_bEvalTok.Count();
		for (uint32 t = 0; t + 1u < n; ++t)
			if (_IsLead((uint8)_bEvalTok.Data()[t + 1u])) out.Add(t);
	}

	Array<uint8> _TruthMask() const
	{
		Array<uint8> m; m.Reset(_bEvalTok.Count());
		for (uint32 i = 0; i < (uint32)m.Count(); ++i) m.Data()[i] = _bEvalBnd.Data()[i];
		return m;
	}
	Array<uint8> _SyllMask() const
	{
		Array<uint8> m; m.Reset(_bEvalTok.Count());
		for (uint32 i = 0; i < (uint32)m.Count(); ++i) m.Data()[i] = 0u;
		Array<uint32> cand; _Candidates(cand);
		for (uint32 i = 0; i < (uint32)cand.Count(); ++i) m.Data()[cand.Data()[i]] = 1u;
		return m;
	}
	Array<uint8> _NoneMask() const
	{
		Array<uint8> m; m.Reset(_bEvalTok.Count());
		for (uint32 i = 0; i < (uint32)m.Count(); ++i) m.Data()[i] = 0u;
		return m;
	}

	// ⚖️ 경계 마스크 하나의 **서술 길이(bit)** 와 F1.
	MdlPoint _MdlOf(const Array<uint8>& mask, float tau) const
	{
		MdlPoint r;
		r.tau = tau;
		const uint32 n = (uint32)_bEvalTok.Count();

		// 구간을 만든다(마지막은 끝까지).
		Array<uint32> st, ln;
		uint32 s0 = 0;
		for (uint32 t = 0; t < n; ++t)
			if (mask.Data()[t] != 0u) { st.Add(s0); ln.Add(t + 1u - s0); s0 = t + 1u; }
		if (s0 < n) { st.Add(s0); ln.Add(n - s0); }
		r.spans = (uint32)st.Count();
		if (r.spans == 0u) return r;

		// 종류 수 + 사전 비용. ⚠️ 손으로 훑는다(구간 수가 수백이라 감당된다 · 결정적이어야 한다).
		//   ★ 그리고 **구간마다 종류 번호**(`typeOf`)를 남긴다 — 예측 항이 그것을 쓴다.
		//     ⚠️ 번호는 **처음 나온 순서**로 붙는다 ⇒ `i` 번째까지 본 종류 수 = `(지금까지 최대 번호)+1`.
		Array<uint32> repS, repL, typeOf;
		typeOf.Reset(r.spans);
		float dict = 0.0f;
		for (uint32 c = 0; c < r.spans; ++c)
		{
			const uint32 a0 = st.Data()[c], l0 = ln.Data()[c];
			uint32 found = 0xFFFFFFFFu;
			for (uint32 k = 0; k < (uint32)repS.Count() && found == 0xFFFFFFFFu; ++k)
			{
				if (repL.Data()[k] != l0) continue;
				bool same = true;
				for (uint32 j = 0; j < l0 && same; ++j)
					if (_bEvalTok.Data()[a0 + j] != _bEvalTok.Data()[repS.Data()[k] + j]) same = false;
				if (same) found = k;
			}
			if (found == 0xFFFFFFFFu)
			{
				found = (uint32)repS.Count();
				repS.Add(a0); repL.Add(l0);
				dict += (float)(l0 + 1u) * 8.0f;   // 바이트열 + 끝 표시(옛 기준: 날바이트 8bit)
			}
			typeOf.Data()[c] = found;
		}
		r.types = (uint32)repS.Count();
		// 본문 = 심볼 개수 × log2(종류 수). ★ 종류가 하나면 지목 비용이 0 이다(맞다).
		const float bits = (r.types > 1u) ? (Log((float)r.types) / Log(2.0f)) : 0.0f;
		r.dictOld = dict;
		r.bodyOld = (float)r.spans * bits;
		r.dl = r.dictOld + r.bodyOld;

		// ── 🔮 **예측적 서술 길이** ────────────────────────────────────────────
		r.dictPred = _DictPredBits(repS, repL);
		r.bodyPred = _BodyPredBits(typeOf, r.types);
		r.dlPred = r.dictPred + r.bodyPred;

		// ── 🌉 **교차채널 쓸모** ──────────────────────────────────────────────
		_UtilOf(st, typeOf, r.types, r.utilSpan, r.utilCap);

		// F1 — 후보 안에서만 견준다(정답 경계는 늘 음절 경계다).
		Array<uint32> cand; _Candidates(cand);
		uint32 tp = 0, pred = 0, truth = 0;
		for (uint32 i = 0; i < (uint32)cand.Count(); ++i)
		{
			const uint32 t = cand.Data()[i];
			const bool p = (mask.Data()[t] != 0u), g = (_bEvalBnd.Data()[t] != 0u);
			if (p) pred++;
			if (g) truth++;
			if (p && g) tp++;
		}
		const float prec = (pred > 0u) ? ((float)tp / (float)pred) : 0.0f;
		const float rec  = (truth > 0u) ? ((float)tp / (float)truth) : 0.0f;
		r.f1 = ((prec + rec) > 0.0f) ? (2.0f * prec * rec / (prec + rec)) : 0.0f;
		return r;
	}

	// 🌉 **교차채널 쓸모** — *"이 단위가 비전 축을 가리키나"* 를 상호정보로 센다.
	//
	// ★ **왜 지표가 둘인가 — 하나는 교란되어 있고 그것을 알고 있다.**
	//   ㉠ **span 당** `I(심볼종류 ; 그 캡션의 축값)` — 분포가 **span 위**에 있다. ⇒ 같은 정보를
	//      **적은 조각**에 담으면 조각당 정보가 커진다 ⇒ **낱말이 병합비(2.15배)만큼 유리하다.**
	//      ⚠️ 그런데 그것은 예측 본문 bit 가 낱말을 고른 것과 **같은 현상**이다(정보를 몇 조각으로
	//        나누나) ⇒ **독립 증거가 아니다.**
	//   ㉡ **캡션 당**(대조군) — 심볼을 *"이 캡션에 나왔나"* 라는 **이진 특징**으로 보고 캡션 위에서
	//      `I(t∈캡션 ; 축값)` 을 재어 **축마다 최선의 심볼 하나**를 쓴다. ⇒ 조각 수에 **중립**이다.
	//      ★ `3개` 를 `3`+`개` 로 쪼개도 `3` 이 여전히 개수를 완전히 가리킨다 ⇒ **거의 같아야 한다.**
	//
	// ⚠️⚠️ **예상을 미리 적는다(이번엔 내 앞 예상을 뒤집은 것이다):**
	//   `utilSpan`: 낱말이 음절보다 **1.5~2.5배** 높다(병합비 2.15 근처).
	//   `utilCap` : 낱말 ≈ 음절 (**±15% 안**) — 이 코퍼스의 음절은 **이미 낱낱이 접지되어 있다**.
	//   ⇒ ★ 그 둘이 다 맞으면 결론은 **"낱말성은 접지가 아니라 예측에서만 온다"** 다.
	//     ⚠️ 그리고 그것이 *"쓸모가 낱말을 고를 것"* 이라던 내 앞 예상의 **반증**이다 — 지표를 만들어
	//       놓고 원하는 답이 나오길 기대하는 것이 함정 19·21·26 의 뿌리이므로, 뒤집힌 예상을 적어 둔다.
	//
	// ★ **섞음 기준선**을 뺀다 — 종류가 많으면 상호정보가 위로 치우친다(추정 편향). 캡션→축 대응을
	//   결정적 순열(`(i*13+5) mod N`, 13 과 40 이 서로소)로 흩어 그 편향의 바닥을 재고 뺀다.
	void _UtilOf(const Array<uint32>& st, const Array<uint32>& typeOf, uint32 types,
		float& outSpan, float& outCap) const
	{
		outSpan = 0.0f; outCap = 0.0f;
		const uint32 nSp = (uint32)typeOf.Count();
		const uint32 nCap = _bEvalNCaps;
		if (nSp == 0u || nCap == 0u || types == 0u || _bEvalCapOf.Count() == 0u) return;

		// span 마다 그 캡션 번호 — ⚠️ **첫 바이트 기준**이다(문턱 분할은 캡션을 넘을 수 있다).
		Array<uint32> capOfSpan;
		capOfSpan.Reset(nSp);
		for (uint32 i = 0; i < nSp; ++i)
		{
			const uint32 b0 = st.Data()[i];
			capOfSpan.Data()[i] = (b0 < (uint32)_bEvalCapOf.Count()) ? _bEvalCapOf.Data()[b0] : 0u;
		}

		for (int ax = 0; ax < 6; ++ax)
		{
			const uint32 V = _AxisClasses(ax);
			if (V < 2u) continue;
			for (int shuf = 0; shuf < 2; ++shuf)
			{
				// ㉠ span 당 상호정보
				Array<uint32> nTV, nT, nV;
				nTV.Reset((uint64)types * V);  nT.Reset(types);  nV.Reset(V);
				for (uint64 i = 0; i < nTV.Count(); ++i) nTV.Data()[i] = 0u;
				for (uint32 i = 0; i < types; ++i) nT.Data()[i] = 0u;
				for (uint32 i = 0; i < V; ++i) nV.Data()[i] = 0u;
				for (uint32 i = 0; i < nSp; ++i)
				{
					const uint32 c = _ShufCap(capOfSpan.Data()[i], nCap, shuf != 0);
					int v = _bEvalCapAx.Data()[(uint64)c * 6u + (uint32)ax];
					if (v < 0 || v >= (int)V) continue;
					nTV.Data()[(uint64)typeOf.Data()[i] * V + (uint32)v]++;
					nT.Data()[typeOf.Data()[i]]++;
					nV.Data()[(uint32)v]++;
				}
				const float mi = _MiNorm(nTV.Data(), nT.Data(), nV.Data(), types, V);

				// ㉡ 캡션 당 — 심볼을 이진 특징으로, **축마다 최선의 심볼 하나**
				Array<uint8> has;
				has.Reset((uint64)types * nCap);
				for (uint64 i = 0; i < has.Count(); ++i) has.Data()[i] = 0u;
				for (uint32 i = 0; i < nSp; ++i)
					has.Data()[(uint64)typeOf.Data()[i] * nCap + capOfSpan.Data()[i]] = 1u;
				float bestCap = 0.0f;
				Array<uint32> b2, bT, bV;
				b2.Reset(2u * V);  bT.Reset(2u);  bV.Reset(V);
				for (uint32 t = 0; t < types; ++t)
				{
					for (uint32 i = 0; i < 2u * V; ++i) b2.Data()[i] = 0u;
					bT.Data()[0] = 0u; bT.Data()[1] = 0u;
					for (uint32 i = 0; i < V; ++i) bV.Data()[i] = 0u;
					for (uint32 c0 = 0; c0 < nCap; ++c0)
					{
						const uint32 c = _ShufCap(c0, nCap, shuf != 0);
						int v = _bEvalCapAx.Data()[(uint64)c * 6u + (uint32)ax];
						if (v < 0 || v >= (int)V) continue;
						const uint32 f = has.Data()[(uint64)t * nCap + c0] ? 1u : 0u;
						b2.Data()[(uint64)f * V + (uint32)v]++;
						bT.Data()[f]++;
						bV.Data()[(uint32)v]++;
					}
					const float m2 = _MiNorm(b2.Data(), bT.Data(), bV.Data(), 2u, V);
					if (m2 > bestCap) bestCap = m2;
				}

				if (shuf == 0) { outSpan += mi; outCap += bestCap; }
				else           { outSpan -= mi; outCap -= bestCap; }
			}
		}
	}

	// 캡션→축 대응을 결정적으로 흩는다(편향 바닥용). ⚠️ 13 과 캡션 수 40 이 서로소 = 진짜 순열.
	static uint32 _ShufCap(uint32 c, uint32 n, bool on)
	{ return on ? ((c * 13u + 5u) % n) : c; }

	// 상호정보를 `H(축값)` 으로 나눈 값(불확실성 계수 · [0,1]). ★ 축마다 분류 수가 달라도 견줄 수 있다.
	static float _MiNorm(const uint32* nTV, const uint32* nT, const uint32* nV,
		uint32 T, uint32 V)
	{
		float N = 0.0f;
		for (uint32 v = 0; v < V; ++v) N += (float)nV[v];
		if (N <= 0.0f) return 0.0f;
		const float inv = 1.0f / Log(2.0f);
		float hV = 0.0f;
		for (uint32 v = 0; v < V; ++v)
		{
			const float pv = (float)nV[v] / N;
			if (pv > 0.0f) hV += -pv * Log(pv) * inv;
		}
		if (hV <= 0.0f) return 0.0f;
		float mi = 0.0f;
		for (uint32 t = 0; t < T; ++t)
		{
			if (nT[t] == 0u) continue;
			const float pt = (float)nT[t] / N;
			for (uint32 v = 0; v < V; ++v)
			{
				const uint32 c = nTV[(uint64)t * V + v];
				if (c == 0u) continue;
				const float ptv = (float)c / N, pv = (float)nV[v] / N;
				mi += ptv * Log(ptv / (pt * pv)) * inv;
			}
		}
		return mi / hV;
	}

	// 🔮 **사전을 예측적으로 코딩한다** — 종류의 바이트열을 **프리퀀셜 바이트 바이그램**으로.
	//   ★ 왜: 옛 항은 `(len+1)×8` 로 **바이트를 날로** 적었다. 그러면 `사과` 처럼 예측 가능한 음절
	//     조합이 랜덤한 조합과 **같은 값**을 낸다 — 즉 사전 항이 예측성을 아예 안 본다.
	//   ⚠️ 종료 표시는 **8bit 로 남긴다** — 종류마다 붙는 상수 비용이고, 그것이 곧 `β·N_symbols` 항이다.
	//   ⚠️ 순서는 **처음 나온 순서**(결정적) · 시작 문맥은 `256`(문장 시작 기호 자리).
	float _DictPredBits(const Array<uint32>& repS, const Array<uint32>& repL) const
	{
		const uint32 V = 256u;
		// ★ 재사용: 모자랄 때만 잡고, 매번 **쓰는 만큼만** 0 으로 되돌린다.
		Array<uint32>& cb = _mCb; Array<uint32>& ct = _mCt;
		if (cb.Count() < (uint64)(V + 1u) * V) cb.Reset((uint64)(V + 1u) * V);
		if (ct.Count() < (uint64)(V + 1u)) ct.Reset(V + 1u);
		for (uint64 i = 0; i < (uint64)(V + 1u) * V; ++i) cb.Data()[i] = 0u;
		for (uint32 i = 0; i <= V; ++i) ct.Data()[i] = 0u;

		const float inv = 1.0f / Log(2.0f);
		float bitsOut = 0.0f;
		for (uint32 k = 0; k < (uint32)repS.Count(); ++k)
		{
			uint32 prev = V;   // 시작 기호
			for (uint32 j = 0; j < repL.Data()[k]; ++j)
			{
				const uint32 b = (uint32)_bEvalTok.Data()[repS.Data()[k] + j];
				const float num = (float)cb.Data()[(uint64)prev * V + b] + kMAlpha;
				const float den = (float)ct.Data()[prev] + kMAlpha * (float)V;
				bitsOut += -Log(num / den) * inv;
				cb.Data()[(uint64)prev * V + b]++;
				ct.Data()[prev]++;
				prev = b;
			}
			bitsOut += 8.0f;   // 종료 표시 = 종류마다 붙는 상수(= β·N 자리)
		}
		return bitsOut;
	}

	// 🔮 **본문을 예측적으로 코딩한다** — 심볼 열을 **프리퀀셜 심볼 바이그램**으로.
	//   `L = Σ_i −log2 P̂_i(s_i | s_{i−1})` · `P̂` 는 **`i` 앞에서 본 것만**으로 세운다(add-½).
	//   ★ 처음 나온 종류는 **"새것" 칸**으로 코딩한다(어휘가 `T_i + 1` 이다) — 사전이 이미 철자를
	//     냈으므로 여기서는 *"새것이 왔다"* 만 알리면 된다.
	//   ⚠️ 그래서 긴 유니크 심볼을 많이 만드는 분할은 **사전에서도 본문에서도** 벌을 받는다.
	float _BodyPredBits(const Array<uint32>& typeOf, uint32 types) const
	{
		const uint32 n = (uint32)typeOf.Count();
		if (n <= 1u || types == 0u) return 0.0f;
		// 전이 표(종류×종류) — 종류 수가 수백이라 감당된다.
		Array<uint32>& cs = _mCs; Array<uint32>& cp = _mCp;
		if (cs.Count() < (uint64)types * types) cs.Reset((uint64)types * types);
		if (cp.Count() < (uint64)types) cp.Reset(types);
		for (uint64 i = 0; i < (uint64)types * types; ++i) cs.Data()[i] = 0u;
		for (uint32 i = 0; i < types; ++i) cp.Data()[i] = 0u;

		const float inv = 1.0f / Log(2.0f);
		float bitsOut = 0.0f;
		uint32 maxId = typeOf.Data()[0];
		for (uint32 i = 1; i < n; ++i)
		{
			const uint32 pv = typeOf.Data()[i - 1u], cu = typeOf.Data()[i];
			const uint32 T = maxId + 1u;                 // 지금까지 본 종류 수
			const bool novel = (cu > maxId);
			const float num = novel ? kMAlpha : ((float)cs.Data()[(uint64)pv * types + cu] + kMAlpha);
			const float den = (float)cp.Data()[pv] + kMAlpha * (float)(T + 1u);   // +1 = "새것" 칸
			bitsOut += -Log(num / den) * inv;
			cs.Data()[(uint64)pv * types + cu]++;
			cp.Data()[pv]++;
			if (cu > maxId) maxId = cu;
		}
		return bitsOut;
	}

	// 🔎 문턱 τ 를 훑어 `DL` 이 **최소**인 자리를 찾는다. ★ 개수를 안 알려준다 — 목적함수가 정한다.
	MdlPoint _SweepTau(uint32 arm, MdlPoint& outPred) const
	{
		const Array<float>& H = _bH[arm];
		Array<uint32> cand; _Candidates(cand);
		// τ 범위 = 후보들의 H 최소~최대.
		float lo = 0.0f, hi = 0.0f;
		bool first = true;
		for (uint32 i = 0; i < (uint32)cand.Count(); ++i)
		{
			const uint32 t = cand.Data()[i];
			if (t >= (uint32)H.Count()) continue;
			const float h = H.Data()[t];
			if (first) { lo = h; hi = h; first = false; }
			else { if (h < lo) lo = h; if (h > hi) hi = h; }
		}
		MdlPoint best, bestP;
		bool any = false;
		for (uint32 s = 0; s <= kMSteps; ++s)
		{
			const float tau = lo + (hi - lo) * ((float)s / (float)kMSteps);
			Array<uint8> m; m.Reset(_bEvalTok.Count());
			for (uint32 i = 0; i < (uint32)m.Count(); ++i) m.Data()[i] = 0u;
			for (uint32 i = 0; i < (uint32)cand.Count(); ++i)
			{
				const uint32 t = cand.Data()[i];
				if (t < (uint32)H.Count() && H.Data()[t] >= tau) m.Data()[t] = 1u;
			}
			const MdlPoint pt = _MdlOf(m, tau);
			if (pt.spans == 0u) continue;
			if (!any || pt.dl < best.dl) best = pt;
			// ★ **두 기준의 최소를 따로 찾는다** — 같은 sweep 을 두 번 돌지 않는다(그리고
			//   두 기준이 **다른 τ** 를 고르는지가 이 실험의 관심사다).
			if (!any || pt.dlPred < bestP.dlPred) bestP = pt;
			any = true;
		}
		outPred = bestP;
		return best;
	}

	void _JudgeMdl()
	{
		const uint32 truthSpans = _mTruth.spans;
		LogA("\n[ml] ⚖️ **MDL 표** — 서술 길이(bit). 낮을수록 좋다. **두 기준을 나란히 둔다.**\n"
			"[ml]   옛(무조건부) = 사전 `(len+1)×8` + 본문 `심볼수 × log2 종류수`\n"
			"[ml]   🔮 새(예측적)  = 사전 **바이트 바이그램** + 본문 **심볼 바이그램**(둘 다 프리퀀셜 add-½)\n"
			"[ml]   🌉 쓸모 = 교차채널 상호정보(6축 합 · 섞음 기준선을 뺐다) — **높을수록** 좋다\n"
			"[ml]   %-16s %7s %6s %10s %10s %8s %8s %8s %8s %6s\n",
			"청킹", "심볼수", "종류", "옛DL", "🔮새DL", "새사전", "새본문",
			"🌉span당", "🌉캡션당", "F1");
		const MdlPoint* rows[3] = { &_mTruth, &_mSyll, &_mNone };
		static const char* rname[3] = { "정답 낱말 경계", "음절 전부", "경계 없음" };
		for (int i = 0; i < 3; ++i)
			LogA("[ml]   %-16s %7u %6u %10.0f %10.0f %8.0f %8.0f %8.3f %8.3f %6.4f%s\n",
				rname[i], rows[i]->spans, rows[i]->types, (double)rows[i]->dl,
				(double)rows[i]->dlPred, (double)rows[i]->dictPred, (double)rows[i]->bodyPred,
				(double)rows[i]->utilSpan, (double)rows[i]->utilCap,
				(double)rows[i]->f1, (i == 0) ? "  ← 오라클" : "");
		for (uint32 a = 0; a < kBArms; ++a)
			LogA("[ml]   옛최소 k=%-7u %7u %6u %10.0f %10.0f %8.0f %8.0f %8.3f %8.3f %6.4f%s\n",
				_BK((int)a), _mBest[a].spans, _mBest[a].types, (double)_mBest[a].dl,
				(double)_mBest[a].dlPred, (double)_mBest[a].dictPred, (double)_mBest[a].bodyPred,
				(double)_mBest[a].utilSpan, (double)_mBest[a].utilCap,
				(double)_mBest[a].f1, (_BK((int)a) == 1u) ? "  ← 바이그램" : "");
		for (uint32 a = 0; a < kBArms; ++a)
			LogA("[ml]   🔮새최소 k=%-6u %7u %6u %10.0f %10.0f %8.0f %8.0f %8.3f %8.3f %6.4f\n",
				_BK((int)a), _mBestP[a].spans, _mBestP[a].types, (double)_mBestP[a].dl,
				(double)_mBestP[a].dlPred, (double)_mBestP[a].dictPred, (double)_mBestP[a].bodyPred,
				(double)_mBestP[a].utilSpan, (double)_mBestP[a].utilCap,
				(double)_mBestP[a].f1);

		// ══════════════════════════════════════════════════════════════════════
		// 🔮 **P3-a′ 판정 — 예측 기준이 낱말을 고르나.** ⚠️ 기준과 **세 결과의 해석을 미리 적었다.**
		{
			const float tp = _mTruth.dlPred, sp = _mSyll.dlPred, np = _mNone.dlPred;
			const float rel = (sp > 0.0f) ? ((tp - sp) / sp) : 0.0f;   // 음절 대비 상대차
			const bool wordWin = (tp < sp) && (tp < np);
			const bool nearTie = (rel > -0.03f) && (rel < 0.03f);
			LogA("[ml]\n[ml]   🔮 **P3-a′ 판정 = 예측 기준이 낱말을 고르나**\n"
				"[ml]      정답 %.0f bit vs 음절전부 %.0f (상대차 %+.1f%%) vs 경계없음 %.0f\n",
				(double)tp, (double)sp, (double)(100.0f * rel), (double)np);
			if (wordWin && !nearTie)
				LogA("[ml]      ⇒ **㉠ 낱말이 이긴다** — 예측 기준이 답이었다(옛 무조건부 항이 틀렸을 뿐이다).\n"
					"[ml]        ★ 그러면 `β·N` 설계는 멀쩡하고, 본문 항만 조건부로 두면 된다.\n");
			else if (nearTie)
				LogA("[ml]      ⇒ **㉡ 거의 같다(±3%% 안) — 예측대로다. 코드 길이로는 경계를 정할 수 없다.**\n"
					"[ml]        ★ 이것은 실패가 아니라 **증명**이다: 사슬규칙 때문에\n"
					"[ml]          `−log2 P(사과|·) = −log2 P(사|·) − log2 P(과|사,·)` 라 **분할에 불변**이다.\n"
					"[ml]        ⇒ 다음 기준은 **교차채널 쓸모**다 — *\"이 단위가 비전 축을 예측하나\"*.\n"
					"[ml]          낱말이 낱말인 이유는 압축이 되기 때문이 아니라 **세계의 무언가를 가리키기** 때문이다.\n");
			else
				LogA("[ml]      ⇒ **㉢ 음절이 더 이긴다** — 구현을 의심한다(사전 항의 종료 표시·프리퀀셜 순서).\n"
					"[ml]        ⚠️ 결론으로 쓰지 않는다. 사전/본문 분해를 보고 어느 항이 결정했는지 먼저 본다.\n");
			// ══════════════════════════════════════════════════════════════════
			// 🌉 **교차채널 쓸모 판정 — 예상을 미리 못박았고, 그 예상은 내 앞 예상의 반증이다.**
			//   `utilSpan`: 낱말이 음절보다 **1.5~2.5배**(병합비 2.15 근처) — 조각 수에 민감하므로
			//     이것은 **예측 본문 bit 와 같은 현상**이고 **독립 증거가 아니다.**
			//   `utilCap` : 낱말 ≈ 음절 (**±15% 안**) — 조각 수에 중립인 대조군.
			//     `3개` 를 `3`+`개` 로 쪼개도 `3` 이 개수를 완전히 가리키므로 접지가 안 나빠진다.
			//   ⇒ 둘 다 맞으면 결론은 **"낱말성은 접지가 아니라 예측에서만 온다"** 다.
			{
				const float uw = _mTruth.utilSpan, us = _mSyll.utilSpan;
				const float cw = _mTruth.utilCap,  cs2 = _mSyll.utilCap;
				const float rSpan = (us > 0.0f) ? (uw / us) : 0.0f;
				const float rCap  = (cs2 > 0.0f) ? (cw / cs2) : 0.0f;
				const bool okSpan = (rSpan > 1.5f) && (rSpan < 2.5f);
				const bool okCap  = (rCap > 0.85f) && (rCap < 1.15f);
				LogA("[ml]\n[ml]      🌉 **교차채널 쓸모** — 낱말/음절 비\n"
					"[ml]        span당 %.3f / %.3f = **%.2f배** (예상 1.5~2.5배) → %s\n"
					"[ml]        캡션당 %.3f / %.3f = **%.2f배** (예상 0.85~1.15배 = 무차별) → %s\n",
					(double)uw, (double)us, (double)rSpan, okSpan ? "예상대로" : "★예상과 다르다★",
					(double)cw, (double)cs2, (double)rCap, okCap ? "예상대로" : "★예상과 다르다★");
				if (okSpan && okCap)
					LogA("[ml]        ⇒ ★ **결론: 낱말성은 접지가 아니라 예측에서만 온다.**\n"
						"[ml]          접지는 단위 크기에 **중립**이다(음절도 이미 낱낱이 가리킨다) —\n"
						"[ml]          그러니 `β` 를 정해 주는 것은 **쓸모가 아니라 예측(문맥의 양)** 이다.\n"
						"[ml]          ⚠️ 이것은 *\"쓸모가 낱말을 고를 것\"* 이라던 앞 예상의 **반증**이다.\n");
				else if (!okCap && rCap > 1.15f)
					LogA("[ml]        ⇒ **캡션당에서도 낱말이 이긴다** — 접지가 단위 크기에 중립이 아니다.\n"
						"[ml]          ★ 그러면 `β` 를 쓸모로 정할 수 있다(앞 예상이 맞았다는 뜻이다).\n");
				else
					LogA("[ml]        ⇒ ⚠️ 예상과 다르다 — 결론을 내지 않고 지표를 먼저 검산한다\n"
						"[ml]          (섞음 기준선이 제대로 빠졌나 · 캡션 번호가 span 과 맞나).\n");
				// ★ **검산 결과를 남긴다(2026-08-18 실측)** — 두 지표가 **둘 다** 조각 크기에
				//   교란되어 있고 **방향이 반대**다. 그래서 어느 쪽도 접지의 순수 측정이 아니다.
				//     `utilCap` ∝ **종류당 span**(= 캡션 커버리지): 낱말 2.61→0.254 · k=1 4.52→0.396 ·
				//        음절 5.26→0.572 ⇒ 비가 0.097/0.088/0.109 로 **거의 정비례**다.
				//        ★ 이진 특징의 상호정보는 **빈도**에 민감하다 — 캡션 40개 중 2.6개에만 나오는
				//          특징은 거의 늘 0 이라 정보를 낼 수 없다. ⇒ **짧은 단위가 구조적으로 유리하다.**
				//     `utilSpan` 은 반대다 — 조각이 **크면** 조각당 정보가 커진다(병합비 방향).
				//   ⇒ ⚠️⚠️ **내가 만든 "조각 수 중립 대조군" 이 중립이 아니었다.** 상호정보는 분포를
				//     **어느 사건 공간 위에** 두느냐에 달려 있고, 분할을 바꾸면 그 공간이 바뀐다.
				//   ★ 그래서 **bit 가 유일하게 공통 단위다** — 같은 코퍼스를 복원하는 총 비용이라
				//     사건 공간에 무관하다. ⇒ 낱말성의 판정은 **예측 코드 길이**로 한다(441 bit).
				//   ★ 지표는 **지우지 않고 진단으로 남긴다**(계측은 자산이다 — `-perf` 와 같은 원칙).
				LogA("[ml]        🔎 검산 — 종류당 span(캡션 커버리지): 낱말 %.2f · 음절 %.2f\n"
					"[ml]          ★ `캡션당` 은 커버리지에 거의 **정비례**한다(실측 비 0.097/0.088/0.109)\n"
					"[ml]            ⇒ 접지가 아니라 **빈도**를 재고 있다. `span당` 은 반대로 큰 조각에 유리.\n"
					"[ml]          ⇒ ⚠️ 두 지표 다 조각 크기에 교란 — **접지 쓸모의 크기 중립 측정은 실패했다.**\n"
					"[ml]            ★ 그러므로 판정은 **bit**로 한다(같은 코퍼스를 복원하는 총 비용이라\n"
					"[ml]              사건 공간에 무관하다) — 거기서 **본문(예측)이 낱말을 441 bit 로 골랐다.**\n",
					(_mTruth.types > 0u) ? ((double)_mTruth.spans / (double)_mTruth.types) : 0.0,
					(_mSyll.types > 0u) ? ((double)_mSyll.spans / (double)_mSyll.types) : 0.0);
			}

			// ★ 어느 항이 결정했나 — 분해를 명시한다(신호의 출처를 숨기지 않는다).
			LogA("[ml]      분해: 정답 사전 %.0f + 본문 %.0f · 음절 사전 %.0f + 본문 %.0f\n"
				"[ml]        ★ 사전 차가 지배하면 이 기준은 사실상 *\"긴 유니크 심볼 벌주기\"* 이고\n"
				"[ml]          본문 차가 지배하면 진짜 **예측성**을 재고 있는 것이다.\n",
				(double)_mTruth.dictPred, (double)_mTruth.bodyPred,
				(double)_mSyll.dictPred, (double)_mSyll.bodyPred);
		}

		// ★ **기준은 측정 전에 정했다.**
		//   ㉠ **MDL 이 낱말을 선호한다**: 정답 경계의 DL 이 `음절 전부`·`경계 없음` 보다 낮다
		//      ⇒ `β·N` 항의 설계가 맞다(아니면 그 항을 미분 가능하게 만들 이유가 없다)
		//   ㉡ **개수를 스스로 정한다**: k=4 의 DL-최소에서 심볼 수가 정답의 ±30% 안이다
		//   ㉢ **함정 4 의 MDL 판**: k=4 의 최소 DL 이 바이그램(k=1)의 최소 DL 보다 낮다
		const bool okPrefer = (_mTruth.dl < _mSyll.dl) && (_mTruth.dl < _mNone.dl);
		const uint32 kBest = kBArms - 1u;
		const float ratio = (truthSpans > 0u)
			? ((float)_mBest[kBest].spans / (float)truthSpans) : 0.0f;
		const bool okCount = (ratio > 0.7f) && (ratio < 1.3f);
		const bool okTrap = (_mBest[kBest].dl < _mBest[0].dl);

		LogA("[ml] P3-a 판정(**옛 무조건부 기준**): %s\n"
			"[ml]   ㉠ **MDL 이 낱말을 선호한다**: 정답 %.0f bit < 음절전부 %.0f · 경계없음 %.0f → %s\n"
			"[ml]      ★ 이것이 `β·N_symbols` 항의 근거다 — 압축을 넣으면 최적점이 **낱말 자리**에 생긴다.\n"
			"[ml]   ㉡ **개수를 스스로 정한다**: DL최소 심볼 %u개 vs 정답 %u개 (비 %.2f · 기준 0.7~1.3) → %s\n"
			"[ml]      ★ P2-b2 는 개수를 **알려줬다**(오라클 M). 여기서는 **목적함수가 정한다.**\n"
			"[ml]   ㉢ **함정 4 의 MDL 판**: k=4 %.0f bit < 바이그램 %.0f bit → %s\n",
			(okPrefer && okCount && okTrap) ? "통과" : "★실패★",
			(double)_mTruth.dl, (double)_mSyll.dl, (double)_mNone.dl, okPrefer ? "통과" : "★실패★",
			_mBest[kBest].spans, truthSpans, (double)ratio, okCount ? "통과" : "★실패★",
			(double)_mBest[kBest].dl, (double)_mBest[0].dl, okTrap ? "통과" : "★실패★");
		LogA("[ml]   📌 다음(P3-b): 이 `N` 을 **미분 가능**하게 만든다 — 경계 확률 `p_i` 를 내는 머리를 붙여\n"
			"[ml]      `N = Σ p_i`(기대 개수)로 쓰고, 청킹은 forward hard / backward soft(straight-through).\n"
			"[ml]      판정은 이미 정해져 있다: **β 를 키우면 심볼 수가 줄고 예측 손실이 오른다(둘 다 움직여야 한다).**\n");
		if (!okPrefer)
			LogA("[ml]   ⚠️⚠️ ㉠ 이 실패하면 **`β·N` 설계가 틀린 것**이다 — 미분 가능판을 짜기 전에 여기서 멈춰야 한다.\n");
	}

	// ── 🧱 **P2-a · 비전 패치 임베딩** ──────────────────────────────────────────────────
	//
	// ★ **여기서 처음으로 모델이 픽셀을 본다.** P1 까지는 전부 텍스트였다.
	//   구조는 `ML.md` 의 L1(비전) 그대로다:
	//     `프레임 바이트 → 8×8 패치 → 자리별 임베딩 합 + 패치자리 임베딩 → 패치 벡터`
	//
	// ★ **새 커널이 둘뿐이다**(`patch_embed`, `patch_embed_bwd`) — 나머지가 전부 이미 있는 것으로
	//   조립된다. 그것이 **아레나 규약이 갚아 주는 값**이다:
	//     · 평균 풀링 = `ones(1×P)/P · patch(P×D)` ⇒ **`gemm`**(전용 커널 필요 없음)
	//     · 풀링 역전파 = `onesᵀ(P×1) · dPooled(1×D)` ⇒ **`gemm` + `transA`**
	//     · 분류기 = `gemm` · `softmax` · 기울기 = **`sub`**(교차엔트로피+softmax 의 미분이 그 뺄셈이다)
	//   ⇒ ★ *"커널을 하나 더 만들까"* 싶을 때 먼저 **GEMM 으로 표현되나**를 본다.
	//
	// ⚠️⚠️ **판정이 둘이고 서로 다른 것을 잡는다.**
	//   ㉠ **커널 vs CPU 레퍼런스(오차 0)** — 배선이 맞나. gather 라 결정적이므로 여유를 줄 이유가 없다.
	//   ㉡ **접지 프로브** — 그 표현에서 낱말이 **정말 읽히나**. ㉠ 이 통과해도 ㉡ 이 실패할 수 있고
	//      그때 원인은 배선이 아니라 표현/학습이다. ⇒ 두 판정이 원인을 **갈라 준다**.
	int      _vStage = 0;
	MLArena  _vis;                      // ★ 비전 전용 아레나
	MLKernel _vPE, _vPEB, _vGemm, _vSoft, _vSub, _vAdam;

	// ㉠ 커널 검증용 — **작게**(CPU 레퍼런스가 `slotRows·dim·patches` 를 도는 삼중 루프다).
	//   ⚠️ 프레임 바이트에 **같은 자리에 같은 값이 여러 패치에서** 나오게 만든다 — gather 가 맞는지는
	//     **중복이 있을 때만** 드러난다(`embed_bwd` 검증과 같은 이유).
	static constexpr uint32 kVW = 16, kVH = 16, kVK = 4, kVD = 3;
	MLTensor _tVFrame, _tVSlot, _tVPos, _tVOut, _tVDOut, _tVDSlot;

	// ㉡ 접지 프로브 — 64² 프레임에서 **색 낱말 5분류**.
	//   ★ **왜 색인가**: 판독기가 이미 "평균색 → 팔레트" 로 되짚는 축이라 **그림에 정말 있다는 것이
	//     증명된 낱말**이다. ⇒ 실패하면 원인이 "그 낱말이 그림에 없다" 가 아니라 **표현/배선**임이 확정된다.
	//     (개수·모양 같은 축으로 시작하면 실패했을 때 원인이 갈리지 않는다.)
	//   ⚠️⚠️ **색을 다른 축과 독립으로 만든다** — 색이 모양/자리와 상관되면 프로브가 **딴 길로 맞힌다**
	//     (최소대립쌍과 같은 규율을 데이터셋에 적용하는 것이다).
	//   ⚠️⚠️⚠️ **학습/시험을 씨앗으로 분리한다** — 표가 `16384×16` 이라 100장은 그냥 외운다.
	//     외운 것은 접지가 아니다. ⇒ **시험 손실만이 주장이고**, 학습 손실은 배선이 도는지의 확인일 뿐이다.
	//
	// ★ **여섯 축을 전부 돈다 — 색 하나만 재면 판정이 과장된다.**
	//   ⚠️ 실측으로 확인했다: 색만 재니 시험 손실 `0.0003 nat` · 정확도 `100%` 가 나왔는데, 팔레트 색
	//     하나가 RGB332 **바이트 하나**로 떨어지므로 그 축은 사실상 **조회**다. 통과가 쉬운 축으로
	//     "접지가 됐다" 고 말하면 안 된다.
	//   ⇒ ★ 판정을 **둘로 가른다**: `색` 은 **배선 게이트**(반드시 통과 — 판독기가 그림에 있음을 이미
	//     증명한 축이다), 나머지 다섯은 **측정**이다. 무엇이 안 읽히는지가 곧 L2/경계망의 할 일 목록이다.
	// ★ **P2-b1 — 판독을 둘로 두고 나란히 잰다: `자루`(평균풀링) vs `자리 보존`.**
	//   ⚠️ 처음에는 평균풀링을 **지우고** 자리 보존으로 갈았는데, 그러면 이전 숫자가 문서에만 남아
	//     **같은 실행에서 견줄 수 없다**. 두 판독은 서로 다른 편향을 갖고 그 **트레이드오프가 결론**이므로,
	//     둘 다 살려 두는 것이 맞다(호환 유지가 아니라 **비교 팔**이다 — 둘 다 쓰인다).
	//   ★ 같은 데이터·같은 씨앗·같은 스텝으로 돌려야 비교가 성립한다.
	//   ⚠️⚠️ 팔마다 **W 와 모멘트를 따로** 잡는다 — 큰 것으로 잡고 앞부분만 쓰면 함정 18(안 쓰는 칸)이다.
	//   P2-a 에서 `자리` 22%(우연 20%) · `모양` 54%(우연 50%) 였고, 그 원인을 **구조로 설명**해 두었다:
	//     `pooled[d] = (1/P)[ Σ_p Σ_s slot[(s,byte)][d] + Σ_p pos[p][d] ]`
	//     첫 항은 **패치 사이 순서가 없는 히스토그램** · 둘째 항은 **입력과 무관한 상수**.
	//   ⇒ 그러면 판독을 `patch(P×D)` 를 **1×(P·D) 한 줄로 보고** 선형층에 그대로 넣으면(=패치 자리를
	//     보존하면) `자리` 가 살아나야 한다. **그 예측을 재는 것이 이 단계다** —
	//     ★ 구조에서 예측한 것을 측정으로 확인하는 것이 이 프로젝트에서 가장 센 검증이다.
	//   ⚠️ **이것은 아키텍처가 아니라 진단이다.** 진짜 L2 는 패치 토큰에 **어텐션**을 얹는 것이고(→ P4),
	//     여기서는 *"정보가 패치 토큰에 있나"* 를 **풀링과 분리해서** 보는 것이 목적이다.
	//   ★ 부수 효과: `posTable` 이 이제 **살아난다**(합이 상수가 아니게 되므로).
	//   ⚠️ 그리고 `ones` 텐서가 필요 없어져 **지웠다** — 평균풀링 숫자는 커밋과 ML.md 에 남아 있다.
	//   ⚠️ 숫자는 "이 프로브 설정에서(dim 16 · 자리 보존 판독 · 선형 1층 · 800스텝)" 의 값이다 —
	//     절대적인 난이도가 아니다. 표현을 키우면 달라질 수 있고, **그것을 재는 것이 이 표의 쓸모다**.
	static constexpr uint32 kPW = 64, kPH = 64, kPK = 8, kPD = 16;
	static constexpr uint32 kPCMax = 6;                  // 축 중 가장 많은 분류 수(개수 = 1..6)
	static constexpr uint32 kPTrain = 100, kPTest = 50;
	// ⚠️⚠️ **스텝이 모자라면 "못 읽는다" 와 "덜 배웠다" 가 구별되지 않는다.**
	//   실측으로 밟았다: 800스텝에서 자루 팔의 `크기` 가 학습 62% / 시험 52% 였는데, 그것은 판독 실패가
	//   아니라 **수렴 실패**였다(학습에서도 못 맞히고 있었다). ⇒ 스텝을 늘리고, 아래 판정이 둘을 가른다.
	static constexpr int    kPSteps = 1600;
	// ★ **한 프레임에 여러 스텝을 돈다.** G′ 는 **회수**를 한 프레임 늦추는 제약이고 **디스패치 속도**를
	//   묶는 제약이 아니다 — 바이트 LM 이 1스텝/프레임이었던 이유는 스텝마다 손실을 **읽었기** 때문이다.
	//   ⇒ 읽을 필요가 없으면 프레임 하나에 여러 스텝을 쌓을 수 있다(1200스텝이 300프레임 = 5초).
	//   ★ 순서는 보장된다 — 같은 커맨드버퍼에 순서대로 쌓이고, 그 사실은 P1 이 **CPU 와 오차 0** 으로
	//     맞은 것이 이미 증명했다(8개 디스패치가 한 프레임에 있었다).
	static constexpr int    kPPerFrame = 4;
	static constexpr float  kPLr = 0.02f;
	MLTensor _tPFrames, _tPOne, _tPSlot, _tPPos;
	MLTensor _tPPatch, _tPLogit, _tPProb, _tPDLogit, _tPDPatch;
	MLTensor _tPDSlot, _tPMS, _tPVS, _tPMP, _tPVP, _tPProbAll;
	// 자루 팔 — 평균풀링용. `ones` 값이 `1/P` 라 GEMM 이 곧 평균이다.
	MLTensor _tPOnes, _tPPool, _tPDPool, _tPWb, _tPDWb, _tPMWb, _tPVWb;
	// 자리 보존 팔 — `patch` 를 `1×(P·D)` 한 줄로 읽는다(복사 없음 · 자리가 W 의 행에 남는다).
	MLTensor _tPWp, _tPDWp, _tPMWp, _tPVWp;
	// 비선형 팔 — `patch(1×P·D) → W1 → ReLU → W2 → C`. ★ 은닉 폭은 `kPHid`.
	//   ⚠️ **활성 전 값(`_tPHpre`)을 따로 둔다** — `relu_bwd` 가 그것을 읽는다(제자리로 덮으면 사라진다).
	static constexpr uint32 kPHid = 32;
	MLTensor _tPW1, _tPDW1, _tPMW1, _tPVW1;
	MLTensor _tPW2, _tPDW2, _tPMW2, _tPVW2;
	MLTensor _tPHpre, _tPHact, _tPDHact, _tPDHpre;
	// 🔭 **어텐션 팔** — `Wq/Wk/Wv` 는 `D×D` 이고 **자리를 모른다**(그것이 가중치 공유다).
	//   ⚠️ `_tPA`(softmax 결과)를 제자리로 덮지 않는다 — `softmax_bwd` 가 **활성 후 값**을 읽는다.
	MLTensor _tPWq, _tPDWq, _tPMWq, _tPVWq;
	MLTensor _tPWk, _tPDWk, _tPMWk, _tPVWk;
	MLTensor _tPWv, _tPDWv, _tPMWv, _tPVWv;
	MLTensor _tPQ, _tPK, _tPV, _tPO;
	MLTensor _tPDQ, _tPDK, _tPDV, _tPDO;
	MLTensor _tPS, _tPA, _tPDA, _tPDS;
	MLTensor _tPWo, _tPDWo, _tPMWo, _tPVWo;
	// ★ **잔차 연결용 항등행렬**(`D×D`) — 상수다. `gemm` 만으로 `O = patch + A·V` 를 쓰기 위한 것이다
	//   (`patch` 를 `O` 자리에 **복사**하는 것이 `patch·I` 이고, 그 뒤 `beta = 1` 로 `A·V` 를 더한다).
	//   ⚠️ `add` 커널을 만들지 않는다 — `beta` 를 넣은 이유가 정확히 이런 자리다.
	MLTensor _tPEye;
	// 🔬 **어텐션 커널 판정용**(작다) — `softmax(scale)` · `softmax_bwd` · `gemm(beta)`.
	//   ★ **왜 이것을 만드나 = 함정 33 이 정확히 이 구멍이었다.** `relu`/`relu_bwd` 는 CPU
	//     레퍼런스를 만들어 두고 **판정 디스패치를 안 붙였고**, 그래서 push constant 배치가 어긋나
	//     `count = 0` 이 넘어간 것을 **커널이 조용히 아무 일도 안 하는** 형태로 한참 뒤에 발견했다.
	//   ⇒ 규칙: **커널을 새로 만들거나 배치를 고쳤으면 그 자리에서 판정을 붙인다**(레퍼런스만으론 안 된다).
	static constexpr uint32 kAcR = 4, kAcC = 5;      // softmax 계열: 4행 × 5열
	static constexpr uint32 kAcM = 3, kAcK = 5, kAcN = 4;   // gemm: (3×5)·(5×4)
	MLTensor _tAcIn, _tAcP, _tAcDO, _tAcDS, _tAcA, _tAcB, _tAcC;
	MLKernel _vRelu, _vReluB;
	// 🔢◀ 어텐션의 softmax 는 **망 안쪽**이라 야코비안이 접히지 않는다 → 전용 역전파 커널이 필요하다.
	MLKernel _vSoftB;
	Array<int> _pLabels;                // 표본 i 의 정답(학습 kPTrain 개 + 시험 kPTest 개)
	int    _pStep = 0;
	int    _pLastSample = -1;
	int    _pAxis = 0;                  // 지금 재고 있는 축(0..5 = `MLSense::AxisAt`)
	// ★ **팔이 셋이다**: `자루`(평균풀링) · `자리보존`(선형) · **`비선형`**(자리보존 + 은닉층).
	//   ⚠️ 세 번째 팔을 넣는 이유가 **측정에서 나왔다**: P2-b1 에서 `모양`(동그라미/네모)이
	//     **선형 1층으로는 학습 집합조차 못 갈렸다**(학습 이득 +0.58) — 패치 안에서
	//     *"각이냐 곡이냐"* 는 **곱셈 관계**이고 선형은 그것을 만들 수 없다.
	//   ★ 그리고 봉우리 실패(*"합은 우겨넣기를 벌하지 않는다"*)도 같은 곳을 가리켰다.
	// ★ **네 번째 팔 = `어텐션+풀링`, 그리고 그것은 D1′ 의 실패가 지목한 것이다.**
	//   D1′ 실측: 비선형이 `모양` 을 **학습 집합에서는 완전히 갈랐다**(+0.58 → +1.00) —
	//   즉 *"각이냐 곡이냐"* 는 표현이 된다. ⚠️ 그런데 **시험은 0.44 → 0.36 으로 내려갔다**(과적합).
	//   ★ 원인이 용량이 아니다: `모양` 은 **도형이 어디 있어도 같은 모양**이어야 하는데
	//     자리보존/비선형은 **자리마다 독립 가중치**라 **평행이동 불변성이 없다** ⇒ 한 자리에서 배운
	//     "동그라미" 를 옆자리로 옮길 수 없고, 64자리 × 2모양을 각각 외우는 수밖에 없다.
	//   ⇒ 필요한 것은 파라미터가 아니라 **가중치 공유**다. 어텐션이 정확히 그것이다
	//     (같은 `Wq`/`Wk`/`Wv` 가 **모든 자리에** 쓰인다).
	//
	// ★ **비교가 통제되어 있다 — 자루 팔과 머리가 글자 그대로 같다.**
	//   자루: `patch → 평균풀링 → W(D×C)`  /  어텐션: `patch → 어텐션 → 평균풀링 → W(D×C)`
	//   ⇒ 머리·팬인·초기값 규칙·lr 이 전부 같고 **중간의 어텐션 블록 하나만** 다르다.
	//   ★ 게다가 `Wq/Wk/Wv` 가 작게 시작하면 `S ≈ 0` → `A ≈ 균등` → `O ≈ 평균(V)` 이라
	//     **어텐션 팔은 자루 팔에서 출발한다.** ⇒ 이득이 있다면 그것은 전부 *"관계를 배운 것"* 이다.
	//   ⚠️ **lr 은 일부러 선형 팔과 같은 `kPLr` 로 둔다**(함정 34: 한 번에 하나만 바꾼다) —
	//     여기서 lr 도 같이 바꾸면 "어텐션이 되나" 와 "lr 이 맞았나" 를 못 가른다.
	int    _pArm = 0;                   // 0 = 자루 · 1 = 자리보존(선형) · 2 = 비선형 · 3 = 어텐션
	uint32 _pClasses = 0;               // 그 축의 분류 수
	static constexpr int kPArms = 4;
	// ★ **프로브 전용 7번째 축 = `개수깔끔`** — `개수` 와 **최소대립쌍**이다(다른 축을 고정한다).
	//
	// ⚠️⚠️⚠️ **`개수` 만 유독 안 되는 이유가 세 겹이고, 셋이 서로 다른 층에 있다.**
	//   ㉠ **채널 충돌(데이터/커리큘럼)**: 풀링은 *잉크 면적*만 보는데 `개수`(1~6 = **6배**)와
	//      `크기`((7/4)² = **3.1배**) · `속`(테두리 vs 꽉찬 = **~1.8배**)이 **같은 채널**을 쓴다.
	//      ⇒ 잡음의 곱 3.1×1.8 ≈ **5.4배**가 신호 6배와 거의 같다 ⇒ **원리적으로 못 가른다.**
	//      ★ 그것이 자루 열 전체를 설명한다 — 면적을 공유하는 축(개수·크기·속)만 죽고
	//        방향/곡률을 쓰는 축(색 +1.00)은 산다.
	//   ㉡ **절차 부재(판독기)**: 세는 것은 **순차 과정**이다(짚고 → 더하고 → 다음). 사람도 4개까지는
	//      한눈에(subitizing) 알고 그 이상은 하나씩 센다. 이 판독기는 **상태도 반복도 없는 한 번의
	//      전진**이라 **통계**만 낸다. ★ 실제로 **네 팔 중 아무도 세지 않는다** — 자루는 면적 ·
	//      자리보존/비선형은 *"이 칸들이 켜진 패턴"* 을 외운 조회표 · 어텐션+풀링은 면적 + 한 패치.
	//   ㉢ ★ **순서 없는 라벨(목적함수)** — 그리고 이것이 ㉡ 의 **전제**다.
	//      `개수` 는 **6분류 one-hot** 으로 학습된다 ⇒ 손실이 `-log p(정답)` 이라
	//      **`1` 과 `2` 가 `사과` 와 `바나나` 만큼 무관하다.** 정답이 4인데 3을 골라도 `여럿` 을
	//      골라도 **벌이 똑같다** ⇒ *"다음 수"* 라는 구조가 목적함수에 **아예 없다.**
	//      ⚠️⚠️ 그리고 그것은 이 프로젝트의 창립 규칙을 **어긴 것**이다 —
	//        *"인코딩 층의 구조는 주고, 분포 층의 구조는 배우게 한다"*.
	//        숫자에 one-hot 을 준 것은 **숫자가 가진 구조(계승)를 지운 것**이다.
	//        ★ 결정해 둔 것과도 어긋난다: *"숫자는 한동안 아라비아숫자쓰자. 숫자배우게"* —
	//          숫자는 **바이트 열**로 배워야 하고 그때 `2` 가 `1` 다음에 온다.
	//
	// ★ **셋이 서로 다른 것을 예측하므로 한 실행으로 갈린다:**
	//   | 가설 | 잡음 고정하면 | 개수별 정확도 | 인접(±1) 오차 비율 |
	//   | ㉠ 채널 충돌 | **크게** 오른다 | 고르게 오른다 | 높다(이웃끼리 헷갈린다) |
	//   | ㉡ 절차 부재 | 조금만 | **1~3 높고 4~6 무너진다** | 큰 수에서만 |
	//   | ㉢ 순서 부재 | 조금만 | 들쭉날쭉 | **낮다**(아무 데나 틀린다) |
	static constexpr int kPAxes = 7;             // MLSense 6축 + `개수깔끔`
	static constexpr int kPAxCountClean = 6;     // 그 자리
	float  _pCeTr[kPArms][kPAxes] = {}, _pCeTe[kPArms][kPAxes] = {};
	float  _pAccTr[kPArms][kPAxes] = {}, _pAccTe[kPArms][kPAxes] = {};
	// 📊 개수계 축의 지표 — `[팔][0=개수 1=개수깔끔]`
	float  _pPerCls[kPArms][2][6] = {};   // 참값별 시험 정확도
	float  _pOrdErr[kPArms][2] = {};      // 평균 |예측−정답|
	float  _pAdjFrac[kPArms][2] = {};     // 오답 중 ±1 인 비율
	// ⚠️⚠️⚠️ **오답 수를 남긴다 — 오답이 0개면 "오답의 분포" 는 정의되지 않는다.**
	//   실측으로 밟았다: 완벽한 팔 셋이 `±1 비율 0%` 로 찍혀 **"순서를 못 배웠다" 로 읽혔다**(거짓 양성).
	//   실제로는 **틀린 것이 아예 없어서** 분모가 0 이었을 뿐이다. ⇒ 그런 자리는 **`판정불가`** 를 낸다.
	//   ★ 함정 29(*"모름을 이진 결정에 밀어넣는다"*)·18(*"안 쓰는 칸이 옛 값을 들고 있다"*)과 같은 계열.
	int    _pWrong[kPArms][2] = {};       // 시험 오답 수

	// ★ 프로브 축 이름/종류 — 7번째는 MLSense 에 없으므로 여기서 준다.
	static const char* _PAxisName(int axis)
	{
		if (axis == kPAxCountClean) return "개수깔끔";
		return MLSense::AxisName(MLSense::AxisAt(axis));
	}
	static MLAxis _PAxisKind(int axis)
	{
		if (axis == kPAxCountClean) return MLAxis::Count;
		return MLSense::AxisAt(axis);
	}
	// ★ 개수계 축인가(그러면 순서 지표를 찍는다) → 슬롯 번호(-1 = 아님)
	static int _PCountSlot(int axis)
	{
		if (axis == 0) return 0;
		return (axis == kPAxCountClean) ? 1 : -1;
	}
	static const char* _ArmName(int arm)
	{
		if (arm == 0) return "자루";
		if (arm == 1) return "자리보존";
		return (arm == 2) ? "비선형" : "어텐션";
	}
	// ★ 어텐션 팔은 자루 팔과 **꼬리를 공유**한다(풀링 → `W(D×C)`) — 이 술어로 한 곳에서 판단한다.
	bool _ArmPools() const { return _pArm == 0 || _pArm == 3; }

	void _TickVision()
	{
		if (_vStage >= 5) return;

		// ── 0: 셋업 + ㉠ 커널 검증 디스패치 ──
		if (_vStage == 0)
		{
			_vStage = 1;
			if (!_SetupVision()) { _vStage = 5; return; }

			MLPatchEmbedParams f;
			f.frameOff = _tVFrame.offset; f.aOff = _tVSlot.offset;
			f.bOff = _tVPos.offset; f.cOff = _tVOut.offset;
			f.frameW = kVW; f.frameH = kVH; f.patchK = kVK; f.dim = kVD;
			if (!_vPE.Dispatch(kVD, f.Patches(), 1u, &f, (uint32)sizeof(f)))
			{ LogA("[ml] 패치임베딩: forward 디스패치 실패\n"); _vStage = 5; return; }

			MLPatchEmbedParams b;
			b.frameOff = _tVFrame.offset; b.aOff = _tVDOut.offset; b.bOff = _tVDSlot.offset;
			b.frameW = kVW; b.frameH = kVH; b.patchK = kVK; b.dim = kVD;
			// ⚠️ 스레드 배치가 forward 와 다르다: y 축이 **표의 행**(자리×256)이다.
			if (!_vPEB.Dispatch(kVD, b.SlotRows(), 1u, &b, (uint32)sizeof(b)))
			{ LogA("[ml] 패치임베딩: backward 디스패치 실패\n"); _vStage = 5; return; }

			// 🔬 어텐션 커널 셋도 **같은 프레임에** 디스패치한다 — 회수가 한 번이라 G′ 를 한 번만 문다.
			if (!_DispatchAttnCheck()) { _vStage = 5; return; }

			LogA("[ml] 패치임베딩 디스패치 — 프레임 %ux%u · 패치 %u · 자리 %u · 표 %u행 · dim %u\n",
				kVW, kVH, f.Patches(), f.Slots(), f.SlotRows(), kVD);
			return;   // ⚠️ 회수는 다음 프레임(G′)
		}

		// ── 1: ㉠ 판정 → 통과면 프로브 시작 ──
		if (_vStage == 1)
		{
			if (!_JudgePatchKernel()) { _vStage = 5; return; }
			// ★ 어텐션 팔을 돌리기 **전에** 그 커널들이 맞다는 것을 확인한다 — 순서가 뜻이 있다.
			if (!_JudgeAttnKernels()) { _vStage = 5; return; }
			// ★ 배선이 맞다는 것을 확인한 **뒤에** 프로브를 돈다 — 순서가 뜻이 있다:
			//   커널이 틀린 채로 프로브를 돌리면 "접지가 안 된다" 로 오진한다.
			if (!_SetupProbe()) { _vStage = 5; return; }
			LogA("[ml] 🧿 접지 프로브 시작 — **여섯 축** · 학습 %u장 / 시험 %u장 · dim %u"
				" · 축마다 %d스텝(프레임당 %d)\n"
				"[ml]   구조: 프레임 → 8×8 패치 임베딩 → **자리 보존 판독**(patch 를 1×(P·D) 로)"
			" → 선형 1층 → softmax\n",
				kPTrain, kPTest, kPD, kPSteps, kPPerFrame);
			_pArm = 0;
			_pAxis = 0;
			if (!_StartAxis(0)) { _vStage = 5; return; }
			_vStage = 2;
			return;
		}

		// ── 2: 학습 루프 ──
		if (_vStage == 2)
		{
			// 지난 프레임 마지막 스텝의 `probs` 를 읽는다(G′). ⚠️ **표본 하나의 손실**이라 흔들린다 —
			//   진짜 숫자는 아래 평가 패스가 낸다. 여기서는 "돌고 있나" 만 본다.
			if (_pLastSample >= 0)
			{
				Bytes bp;
				// ⚠️ `_tPProb` 는 `kPCMax` 칸이지만 이 축이 쓰는 것은 앞 `_pClasses` 칸뿐이다.
				if (_vis.Read(_tPProb, bp) && bp.GetSize() == (uint64)kPCMax * sizeof(float))
				{
					const float loss = _CeOne((const float*)bp.GetData(), _pLabels.Data()[_pLastSample]);
					if ((_pStep % 400) == 0 || _pStep >= kPSteps)
						LogA("[ml]   step %4d  loss %.6f nat (표본 1개 — 흔들린다)\n",
							_pStep, (double)loss);
				}
			}
			// 🔬🔭 **어텐션 진단 — 고치기 전에 먼저 잰다**(함정 34: 진단이 A/B 의 A 다).
			//   ★ **재려는 가설이 정확히 하나다: `A` 가 뾰족해졌나.**
			//     ⚠️ 실측이 논리적으로 불가능한 것을 냈다 — 어텐션이 **자루보다 나빴다**
			//       (`개수` +0.38 → −0.01 · `모양` +0.44 → +0.00). 그런데:
			//         `pool = Σ_q c_q·V[q]`(`c_q` = `A` 의 열평균) → `A` 균등이면 `pool = mean(patch)·Wv`
			//         ⇒ `Wv = I, Wo = W` 로 두면 **어텐션 ⊇ 자루**다(표현력이 진부분집합일 수 없다).
			//     ⇒ 그러므로 원인은 표현력이 아니라 **최적화**다. 유력한 기제:
			//       **AdamW 는 스케일 불변**이라 기울기가 아무리 작아도 파라미터를 `lr` 씩 움직인다.
			//       `Wq/Wk` 의 기울기는 `softmax_bwd` 에서 `p ≈ 1/64` 와 `1/√D` 가 곱해져 아주 작은데,
			//       AdamW 가 그것을 정규화해 **1600스텝 동안 계속 밀어** `S` 가 커지고 `A` 가 one-hot 이
			//       된다 ⇒ 평균이 사라지고(자루로 돌아갈 길이 막히고) 기울기도 죽는다.
			//   ★ 지표: **행 엔트로피**(균등이면 `log 64 = 4.159`, one-hot 이면 0) · `max A` · `max|S|`.
			//     ⇒ 엔트로피가 내려가고 `max A` 가 1 로 가면 가설이 확인된다. **아직 아무것도 안 고쳤다.**
			if (_pArm == 3 && (_pStep == kPPerFrame || _pStep == kPSteps / 4
				|| _pStep == kPSteps / 2 || _pStep >= kPSteps))
			{
				MLPatchEmbedParams rr;
				rr.frameW = kPW; rr.frameH = kPH; rr.patchK = kPK; rr.dim = kPD;
				const uint32 PP = rr.Patches();
				Bytes ba, bs, bq;
				if (_vis.Read(_tPA, ba) && _vis.Read(_tPS, bs) && _vis.Read(_tPWq, bq))
				{
					const float* A = (const float*)ba.GetData();
					const float* S = (const float*)bs.GetData();
					const float* Wq = (const float*)bq.GetData();
					// 행 엔트로피의 평균 — ★ `MLRowEntropyCpu` 가 이미 있다(P3 에서 만든 것).
					Array<float> hh;
					hh.Reset(PP);
					MLRowEntropyCpu(A, hh.Data(), PP, PP);
					float hsum = 0.0f, maxA = 0.0f;
					for (uint32 i = 0; i < PP; ++i) hsum += hh.Data()[i];
					for (uint32 i = 0; i < PP * PP; ++i) if (A[i] > maxA) maxA = A[i];
					const float mS = MLMaxAbs(S, PP * PP), mQ = MLMaxAbs(Wq, kPD * kPD);
					LogA("[ml]   🔭 [어텐션] step %4d  행엔트로피 %.4f / %.4f(균등)"
						" · maxA %.4f · max|S| %.3f · max|Wq| %.3f\n",
						_pStep, (double)(hsum / (float)PP), (double)Log((float)PP),
						(double)maxA, (double)mS, (double)mQ);
				}
			}
			// 🔬 **가설을 추측으로 두지 않는다** — 2층 팔에서 은닉·로짓 크기를 찍어 폭주를 확인한다.
			//   ⚠️ 회수는 지난 프레임의 것이다(G′) — 크기만 보므로 한 스텝 늦어도 무해하다.
			if (_pArm == 2 && (_pStep == kPPerFrame || _pStep == kPSteps / 4
				|| _pStep == kPSteps / 2 || _pStep >= kPSteps))
			{
				Bytes bh, bl;
				if (_vis.Read(_tPHpre, bh) && _vis.Read(_tPLogit, bl))
				{
					const float* h = (const float*)bh.GetData();
					const float* l = (const float*)bl.GetData();
					float mh = 0.0f, ml = 0.0f;
					for (uint32 i = 0; i < kPHid; ++i)
					{ const float v = (h[i] < 0.0f) ? -h[i] : h[i]; if (v > mh) mh = v; }
					for (uint32 i = 0; i < kPCMax; ++i)
					{ const float v = (l[i] < 0.0f) ? -l[i] : l[i]; if (v > ml) ml = v; }
					LogA("[ml]   🔬 [비선형] step %4d  max|h_pre| %.4f · max|logit| %.4f"
						"  (폭주면 로짓이 커지고 기울기가 사라진다)\n", _pStep, (double)mh, (double)ml);
				}
			}
			if (_pStep >= kPSteps)
			{
				_vStage = 3;
				if (!_DispatchEval()) _vStage = 5;
				return;
			}
			for (int k = 0; k < kPPerFrame && _pStep < kPSteps; ++k)
			{
				const int sample = _pStep % (int)kPTrain;
				if (!_DispatchProbeStep(sample)) { _vStage = 5; return; }
				_pLastSample = sample;
				_pStep++;
			}
			return;
		}

		// ── 3: 평가 회수 → 다음 축 or 최종 판정 ──
		if (!_RecordAxis()) { _vStage = 5; return; }
		if (_pAxis + 1 < kPAxes)
		{
			_pAxis++;
			if (!_StartAxis(_pAxis)) { _vStage = 5; return; }
			_vStage = 2;
			return;
		}
		if (_pArm + 1 < kPArms)
		{
			// ★ 팔을 바꿔 **같은 데이터·같은 씨앗·같은 스텝**으로 처음부터 다시 돈다.
			_pArm++;
			_pAxis = 0;
			if (!_StartAxis(0)) { _vStage = 5; return; }
			_vStage = 2;
			return;
		}
		_vStage = 5;
		_JudgeProbe();
	}

	// 🔁 축 하나를 처음부터 — **데이터도 가중치도 갈아 끼운다.**
	//   ⚠️⚠️ 모멘트까지 0 으로 되돌린다 — 안 하면 앞 축의 관성이 다음 축의 초기 학습을 밀어
	//     축끼리 비교가 안 된다(그리고 그 증상은 "뒤 축이 더 잘 배운다" 로만 보인다).
	bool _StartAxis(int axis)
	{
		_pClasses = _AxisClasses(axis);
		_pStep = 0;
		_pLastSample = -1;
		if (!_SetupProbeData(axis)) return false;
		LogA("\n[ml] ── 🧿 [%s] 축 '%s' (%u분류 · 균등 하한 %.6f nat · 우연 %.1f%%)\n",
			_ArmName(_pArm), _PAxisName(axis), _pClasses,
			(double)Log((float)_pClasses), 100.0 / (double)_pClasses);
		return true;
	}

	static uint32 _AxisClasses(int axis)
	{
		// ⚠️ 위와 같은 이유 — 6번은 개수계 축이므로 **6분류**다(공용은 그 축을 모른다).
		if (axis == kPAxCountClean) return 6;
		return MLFacts::AxisClasses(axis);
	}

	// 그 축의 값을 장면에 **덮어쓴다**(균등 분포 + 다른 축과 독립).
	static void _AxisSet(MLScene& sc, int axis, int value)
	{
		// ⚠️ **프로브 전용 축 6번(개수깔끔)은 여기가 맡는다** — 공용(`MLFacts`)은 0~5 만 안다.
		//   ★ 안 갈랐다면 `AxisAt(6)` 이 `Fill` 을 돌려주어 **개수가 조용히 속으로** 쓰였을 것이다.
		if (axis == kPAxCountClean) { sc.count = value + 1; return; }
		MLFacts::AxisSet(sc, axis, value);
	}

	// 🔬 커널 판정 입력 — 호스트/GPU 가 **같은 것**을 보게 한 곳에서 만든다.
	//   ⚠️ `_tAcC` 는 **미리 값을 채운다** — `beta` 가 그것을 섞는지 봐야 하므로 0 이면 검사가 무의미하다.
	static void _FillAttnCheckInputs(Array<float>& in, Array<float>& dOut,
		Array<float>& a, Array<float>& b, Array<float>& c)
	{
		in.Reset(kAcR * kAcC);
		for (uint32 i = 0; i < kAcR * kAcC; ++i) in.Data()[i] = ((float)(i % 7) - 3.0f) * 0.75f;
		dOut.Reset(kAcR * kAcC);
		for (uint32 i = 0; i < kAcR * kAcC; ++i) dOut.Data()[i] = ((float)(i % 5) - 2.0f) * 0.5f;
		a.Reset(kAcM * kAcK);
		for (uint32 i = 0; i < kAcM * kAcK; ++i) a.Data()[i] = ((float)(i % 4) - 1.5f) * 0.5f;
		b.Reset(kAcK * kAcN);
		for (uint32 i = 0; i < kAcK * kAcN; ++i) b.Data()[i] = ((float)(i % 6) - 2.5f) * 0.25f;
		c.Reset(kAcM * kAcN);
		for (uint32 i = 0; i < kAcM * kAcN; ++i) c.Data()[i] = ((float)(i % 3) - 1.0f) * 2.0f;
	}

	// 🔬 **어텐션이 쓰는 커널 셋을 디스패치**한다(회수는 다음 프레임 — G′).
	bool _DispatchAttnCheck()
	{
		MLSoftmaxParams sm;
		sm.inOff = _tAcIn.offset; sm.outOff = _tAcP.offset;
		sm.rows = kAcR; sm.cols = kAcC; sm.scale = _AttnScale();
		if (!_vSoft.Dispatch(kAcR, 1u, 1u, &sm, (uint32)sizeof(sm))) return _Fail("check softmax");

		// ⚠️ **앞 디스패치의 결과를 입력으로 쓴다** — 한 커맨드버퍼 안에서 순서가 보장된다는 것은
		//   P1 이 "오차 0" 으로 증명한 사실이다(그것이 아레나 규약의 근거이기도 하다).
		MLSoftmaxBwdParams sb;
		sb.probOff = _tAcP.offset; sb.dOutOff = _tAcDO.offset; sb.dInOff = _tAcDS.offset;
		sb.rows = kAcR; sb.cols = kAcC; sb.scale = _AttnScale();
		if (!_vSoftB.Dispatch(kAcR, 1u, 1u, &sb, (uint32)sizeof(sb))) return _Fail("check softmax bwd");

		MLGemmParams g;
		g.aOff = _tAcA.offset; g.bOff = _tAcB.offset; g.cOff = _tAcC.offset;
		g.M = kAcM; g.N = kAcN; g.K = kAcK; g.beta = 0.5f;
		if (!_vGemm.Dispatch(kAcN, kAcM, 1u, &g, (uint32)sizeof(g))) return _Fail("check gemm beta");
		return true;
	}

	// 🔬 **판정** — CPU 레퍼런스와 견준다.
	//   ★ **허용오차가 커널마다 다르고, 그 갈림에 근거가 있다:**
	//     · `gemm`(+`beta`) 은 곱·덧뿐이라 **오차 0** 을 요구한다(ReLU 와 같은 급).
	//     · `softmax` 계열은 **`exp` 가 초월함수**라 GPU/CPU 의 마지막 비트가 갈린다 ⇒ 0 을 요구할 수
	//       없다. 그래서 `1e-6` 을 쓴다. ⚠️ **이 완화를 다른 커널에 번지게 하면 안 된다** — 초월함수가
	//       없는 커널이 0 을 못 맞히면 그것은 정밀도가 아니라 **버그**다.
	bool _JudgeAttnKernels()
	{
		Bytes bP, bDS, bC;
		if (!_vis.Read(_tAcP, bP) || !_vis.Read(_tAcDS, bDS) || !_vis.Read(_tAcC, bC))
		{ LogA("[ml] 어텐션 커널 판정: ★실패★ — 회수가 안 됐다\n"); return false; }

		Array<float> in, dOut, a, b, c;
		_FillAttnCheckInputs(in, dOut, a, b, c);
		const float sc = _AttnScale();

		Array<float> wantP;   wantP.Reset(kAcR * kAcC);
		MLSoftmaxCpu(in.Data(), wantP.Data(), kAcR, kAcC, sc);
		Array<float> wantDS;  wantDS.Reset(kAcR * kAcC);
		MLSoftmaxBwdCpu(wantP.Data(), dOut.Data(), wantDS.Data(), kAcR, kAcC, sc);
		// ⚠️ `beta` 는 **제자리 누산**이라 CPU 쪽도 `c` 를 그대로 받아 덮는다(같은 순서·같은 분기).
		MLGemmCpuT(a.Data(), b.Data(), c.Data(), kAcM, kAcN, kAcK, false, false, 0.5f);

		// ★ **지표를 골라야 한다 — 원소별 상대오차는 0 을 지나는 출력에서 거짓말을 한다.**
		//   `softmax_bwd` 의 `dIn = scale·p·(dOut − dot)` 는 `dOut_i ≈ dot` 인 원소에서 **0 을 지난다.**
		//   `MLMaxRelErr` 은 분모에 `1e-6` 바닥이 있어 그 자리의 절대오차 `~1e-12` 가 **`1e-6` 으로
		//   증폭**되어 찍힌다 ⇒ 완벽한 커널이 실패로 보인다(실측으로 밟았다: rel 1.104e-06).
		//   ⇒ **정규화 절대오차**(`최대절대오차 / 참값최대크기`)로 판정하고, **둘 다 찍어** 다음 사람이
		//     그 갈림을 눈으로 확인할 수 있게 둔다. ★ 함정 19 와 같은 계열(값이 아니라 척도의 문제).
		const float rS = MLMaxRelErr((const float*)bP.GetData(), wantP.Data(), kAcR * kAcC);
		const float rB = MLMaxRelErr((const float*)bDS.GetData(), wantDS.Data(), kAcR * kAcC);
		const float sP = MLMaxAbs(wantP.Data(), kAcR * kAcC);
		const float sB = MLMaxAbs(wantDS.Data(), kAcR * kAcC);
		const float eS = MLMaxAbsErr((const float*)bP.GetData(), wantP.Data(), kAcR * kAcC)
			/ ((sP > 0.0f) ? sP : 1.0f);
		const float eB = MLMaxAbsErr((const float*)bDS.GetData(), wantDS.Data(), kAcR * kAcC)
			/ ((sB > 0.0f) ? sB : 1.0f);
		// ⚠️ `gemm` 은 곱·덧뿐이라 **정확히 0** 을 요구한다 — 초월함수의 완화를 여기에 번지게 하지 않는다.
		const float eG = MLMaxRelErr((const float*)bC.GetData(), c.Data(), kAcM * kAcN);
		const bool pass = (eS < 1.0e-6f) && (eB < 1.0e-6f) && (eG == 0.0f);
		LogA("[ml] 🔬 어텐션 커널 판정: %s\n"
			"[ml]   softmax(온도) 정규화절대 %.3e (원소별상대 %.3e) · softmax_bwd 정규화절대 %.3e (원소별상대 %.3e)"
			" · gemm(beta) %.3e\n"
			"[ml]   기준: gemm 은 **오차 0**(곱·덧뿐) · softmax 계열은 정규화 절대오차 `1e-6`\n"
			"[ml]     ★ `exp` 가 초월함수라 0 을 못 요구하고, **0 을 지나는 출력**이라 원소별 상대오차도\n"
			"[ml]       못 쓴다(분모 바닥 `1e-6` 이 `1e-12` 를 `1e-6` 으로 증폭한다) — 괄호가 그 증거다.\n",
			pass ? "통과" : "★실패★",
			(double)eS, (double)rS, (double)eB, (double)rB, (double)eG);
		if (!pass)
			LogA("[ml]   ⚠️ 볼 곳: ① push constant 배치가 셰이더와 같은가(**함정 33** — 특히 마지막 `float`)\n"
				"[ml]      ② 온도를 fwd/bwd 가 **같은 값**으로 받았나 ③ `beta` 가 0 일 때 곱하지 않고 분기하나\n"
				"[ml]      ④ softmax 가 최댓값을 **온도 곱한 뒤** 재는가\n"
				"[ml]      ★ 오차가 **정확히 0.00 이 아니라 크게 틀리면** 식이 문제이고,\n"
				"[ml]        **결과가 통째로 0 이면** 배관이 끊긴 것이다(함정 33 의 서명).\n");
		return pass;
	}

	// ㉠ **커널 vs CPU 레퍼런스** — 오차 0 을 요구한다.
	bool _JudgePatchKernel()
	{
		Bytes bOut, bDS;
		if (!_vis.Read(_tVOut, bOut) || !_vis.Read(_tVDSlot, bDS))
		{
			LogA("[ml] 패치임베딩 판정: ★실패★ — 회수가 안 됐다\n");
			return false;
		}
		MLPatchEmbedParams q;
		q.frameW = kVW; q.frameH = kVH; q.patchK = kVK; q.dim = kVD;

		Array<float> frame, slot, pos, dOut, wantOut, wantDS;
		_FillPatchInputs(frame, slot, pos, dOut);
		wantOut.Reset(q.Patches() * kVD);
		MLPatchEmbedCpu(frame.Data(), slot.Data(), pos.Data(), wantOut.Data(), kVW, kVH, kVK, kVD);
		wantDS.Reset(q.SlotRows() * kVD);
		MLPatchEmbedBwdCpu(frame.Data(), dOut.Data(), wantDS.Data(), kVW, kVH, kVK, kVD);

		const float eF = MLMaxRelErr((const float*)bOut.GetData(), wantOut.Data(), q.Patches() * kVD);
		const float eB = MLMaxRelErr((const float*)bDS.GetData(), wantDS.Data(), q.SlotRows() * kVD);
		const bool pass = (eF == 0.0f) && (eB == 0.0f);
		LogA("[ml] 패치임베딩 판정: %s — forward %.3e · backward %.3e (CPU 레퍼런스 대비, 오차 0 을 요구)\n",
			pass ? "통과" : "★실패★", (double)eF, (double)eB);
		if (!pass)
			LogA("[ml]   ⚠️ 볼 곳: ① 자리→픽셀 매핑이 fwd/bwd 에서 같은가 ② backward 의 y 축이 표의 행인가"
				" ③ `pos` 를 누산 **시작값**으로 넣었나 ④ 범위 밖 바이트 규약이 같은가\n");
		return pass;
	}

	// 🎲 커널 검증 입력. ★ **같은 자리에 같은 바이트가 여러 패치에서** 나오게 만든다(gather 검증의 전제).
	//   ⚠️ 값이 전부 다르면 "중복을 한 번만 더한" 버그가 통과한다.
	void _FillPatchInputs(Array<float>& frame, Array<float>& slot, Array<float>& pos,
		Array<float>& dOut) const
	{
		MLPatchEmbedParams q;
		q.frameW = kVW; q.frameH = kVH; q.patchK = kVK; q.dim = kVD;

		frame.Reset(kVW * kVH);
		// 바이트값을 **7가지**로만 쓴다 → 같은 자리에서 여러 패치가 같은 값을 낸다.
		for (uint32 i = 0; i < kVW * kVH; ++i) frame.Data()[i] = (float)((i * 5u + i / 7u) % 7u);

		slot.Reset(q.SlotRows() * kVD);
		for (uint32 i = 0; i < q.SlotRows() * kVD; ++i)
			slot.Data()[i] = ((float)(i % 11) - 5.0f) * 0.25f;

		pos.Reset(q.Patches() * kVD);
		for (uint32 i = 0; i < q.Patches() * kVD; ++i)
			pos.Data()[i] = ((float)(i % 5) - 2.0f) * 0.5f;

		dOut.Reset(q.Patches() * kVD);
		for (uint32 i = 0; i < q.Patches() * kVD; ++i)
			dOut.Data()[i] = ((float)(i % 9) - 4.0f) * 0.125f;
	}

	bool _SetupVision()
	{
		MLPatchEmbedParams q;
		q.frameW = kVW; q.frameH = kVH; q.patchK = kVK; q.dim = kVD;
		MLPatchEmbedParams r;
		r.frameW = kPW; r.frameH = kPH; r.patchK = kPK; r.dim = kPD;

		// ★ 검증용과 프로브가 **같은 아레나**를 쓴다 — 그러면 판정이 프로브가 실제로 쓰는 **그 커널
		//   인스턴스**를 검산하게 된다(다른 아레나면 커널도 다른 바인딩이라 검산의 뜻이 약해진다).
		const uint32 needCheck = kVW * kVH + q.SlotRows() * kVD * 2u + q.Patches() * kVD * 3u
			+ kAcR * kAcC * 4u + kAcM * kAcK + kAcK * kAcN + kAcM * kAcN + 64u;   // 🔬 커널 판정용
		const uint32 needProbe =
			(kPTrain + kPTest) * (kPW * kPH)          // 프레임(키프레임 · float 로 담는다)
			+ (kPTrain + kPTest) * kPCMax * 2u        // onehot · probsAll
			+ r.SlotRows() * kPD * 4u                // slot · dSlot · m · v
			+ r.Patches() * kPD * 3u                 // pos · m · v  (dPos = dPatch 를 그대로 쓴다)
			+ (kPW / kPK) * (kPH / kPK) * kPD * kPCMax * 4u   // 자리보존 팔: W·dW·m·v ((P·D)×C)
			+ (kPW / kPK) * (kPH / kPK) * kPD * kPHid * 4u    // 비선형 팔: W1·dW1·m·v
			+ kPHid * kPCMax * 4u + kPHid * 4u                // W2·dW2·m·v + hpre·hact·dhact·dhpre
			+ kPD * kPCMax * 4u                      // 자루 팔: W·dW·m·v (D×C)
			+ (kPW / kPK) * (kPH / kPK)              // ones
			+ kPD * 2u                               // pool · dPool
			+ r.Patches() * kPD * 2u                 // patch · dPatch
			+ kPCMax * 3u                            // logits · probs · dLogits
			// 🔭 어텐션 팔 — `Wq/Wk/Wv`(×4) · `Q/K/V/O`+기울기(×8) · `S/A/dA/dS`(×4) · `Wo`(×4)
			+ kPD * kPD * 12u
			+ (kPW / kPK) * (kPH / kPK) * kPD * 8u
			+ (kPW / kPK) * (kPH / kPK) * (kPW / kPK) * (kPH / kPK) * 4u
			+ kPD * kPCMax * 4u
			+ kPD * kPD                              // 잔차용 항등행렬(상수)
			+ 256u;                                  // 여유
		if (!_vis.Create(rhi, needCheck + needProbe))
		{ LogA("[ml] 비전: 아레나 생성 실패(%u floats)\n", needCheck + needProbe); return false; }

		_tVFrame = _vis.Alloc(1, kVW * kVH);
		_tVSlot  = _vis.Alloc(q.SlotRows(), kVD);
		_tVPos   = _vis.Alloc(q.Patches(), kVD);
		_tVOut   = _vis.Alloc(q.Patches(), kVD);
		_tVDOut  = _vis.Alloc(q.Patches(), kVD);
		_tVDSlot = _vis.Alloc(q.SlotRows(), kVD);
		_tAcIn = _vis.Alloc(kAcR, kAcC);   _tAcP  = _vis.Alloc(kAcR, kAcC);
		_tAcDO = _vis.Alloc(kAcR, kAcC);   _tAcDS = _vis.Alloc(kAcR, kAcC);
		_tAcA  = _vis.Alloc(kAcM, kAcK);   _tAcB  = _vis.Alloc(kAcK, kAcN);
		_tAcC  = _vis.Alloc(kAcM, kAcN);
		if (!_tVDSlot.IsValid() || !_tAcC.IsValid())
		{ LogA("[ml] 비전: 검증 텐서 할당 실패\n"); return false; }

		Array<float> frame, slot, pos, dOut;
		_FillPatchInputs(frame, slot, pos, dOut);
		if (!_vis.Write(_tVFrame, frame) || !_vis.Write(_tVSlot, slot)
			|| !_vis.Write(_tVPos, pos) || !_vis.Write(_tVDOut, dOut))
		{ LogA("[ml] 비전: 검증 입력 업로드 실패\n"); return false; }

		// 🔬 커널 판정 입력 — **결정적**이고 **부호가 섞여** 있다(양수만이면 부호 버그를 못 잡는다).
		Array<float> ain, ado, aa, ab, ac;
		_FillAttnCheckInputs(ain, ado, aa, ab, ac);
		if (!_vis.Write(_tAcIn, ain) || !_vis.Write(_tAcDO, ado)
			|| !_vis.Write(_tAcA, aa) || !_vis.Write(_tAcB, ab)
			|| !_vis.Write(_tAcC, ac))
		{ LogA("[ml] 비전: 커널 판정 입력 업로드 실패\n"); return false; }

		if (!_LoadKernelIn(_vPE,   "shaders/patch_embed.cs.spv",     _vis)) return false;
		if (!_LoadKernelIn(_vPEB,  "shaders/patch_embed_bwd.cs.spv", _vis)) return false;
		if (!_LoadKernelIn(_vGemm, "shaders/gemm.cs.spv",            _vis)) return false;
		if (!_LoadKernelIn(_vSoft, "shaders/softmax.cs.spv",         _vis)) return false;
		if (!_LoadKernelIn(_vSub,  "shaders/sub.cs.spv",             _vis)) return false;
		if (!_LoadKernelIn(_vAdam, "shaders/adamw.cs.spv",           _vis)) return false;
		if (!_LoadKernelIn(_vRelu,  "shaders/relu.cs.spv",            _vis)) return false;
		if (!_LoadKernelIn(_vReluB, "shaders/relu_bwd.cs.spv",        _vis)) return false;
		if (!_LoadKernelIn(_vSoftB, "shaders/softmax_bwd.cs.spv",     _vis)) return false;
		return true;
	}

	// 🎯 텐서 자리만 잡는다(한 번). ★ 분류 수는 축마다 다르지만 자리는 **가장 큰 축**으로 잡아 두고
	//   축마다 앞부분만 쓴다 — 아레나가 범프 할당이라 축마다 다시 잡으면 계속 자란다.
	bool _SetupProbe()
	{
		MLPatchEmbedParams r;
		r.frameW = kPW; r.frameH = kPH; r.patchK = kPK; r.dim = kPD;
		const uint32 nAll = kPTrain + kPTest, plane = kPW * kPH;

		_tPFrames  = _vis.Alloc(nAll, plane);
		_tPOne     = _vis.Alloc(nAll, kPCMax);
		_tPProbAll = _vis.Alloc(nAll, kPCMax);
		_tPSlot    = _vis.Alloc(r.SlotRows(), kPD);
		_tPPos     = _vis.Alloc(r.Patches(), kPD);
		_tPPatch   = _vis.Alloc(r.Patches(), kPD);
		_tPLogit   = _vis.Alloc(1, kPCMax);
		_tPProb    = _vis.Alloc(1, kPCMax);
		_tPDLogit  = _vis.Alloc(1, kPCMax);
		_tPDPatch  = _vis.Alloc(r.Patches(), kPD);
		_tPDSlot   = _vis.Alloc(r.SlotRows(), kPD);
		_tPMS      = _vis.Alloc(r.SlotRows(), kPD);
		_tPVS      = _vis.Alloc(r.SlotRows(), kPD);
		_tPMP      = _vis.Alloc(r.Patches(), kPD);
		_tPVP      = _vis.Alloc(r.Patches(), kPD);
		// 자루 팔
		_tPOnes    = _vis.Alloc(1, r.Patches());
		_tPPool    = _vis.Alloc(1, kPD);
		_tPDPool   = _vis.Alloc(1, kPD);
		_tPWb      = _vis.Alloc(kPD, kPCMax);
		_tPDWb     = _vis.Alloc(kPD, kPCMax);
		_tPMWb     = _vis.Alloc(kPD, kPCMax);
		_tPVWb     = _vis.Alloc(kPD, kPCMax);
		// 자리 보존 팔 — ★ W 가 `(P·D) × C` 다(**패치 자리마다 자기 가중치**).
		_tPWp      = _vis.Alloc(r.Patches() * kPD, kPCMax);
		_tPDWp     = _vis.Alloc(r.Patches() * kPD, kPCMax);
		_tPMWp     = _vis.Alloc(r.Patches() * kPD, kPCMax);
		_tPVWp     = _vis.Alloc(r.Patches() * kPD, kPCMax);
		// 비선형 팔
		_tPW1      = _vis.Alloc(r.Patches() * kPD, kPHid);
		_tPDW1     = _vis.Alloc(r.Patches() * kPD, kPHid);
		_tPMW1     = _vis.Alloc(r.Patches() * kPD, kPHid);
		_tPVW1     = _vis.Alloc(r.Patches() * kPD, kPHid);
		_tPW2      = _vis.Alloc(kPHid, kPCMax);
		_tPDW2     = _vis.Alloc(kPHid, kPCMax);
		_tPMW2     = _vis.Alloc(kPHid, kPCMax);
		_tPVW2     = _vis.Alloc(kPHid, kPCMax);
		_tPHpre    = _vis.Alloc(1, kPHid);
		_tPHact    = _vis.Alloc(1, kPHid);
		_tPDHact   = _vis.Alloc(1, kPHid);
		_tPDHpre   = _vis.Alloc(1, kPHid);
		// 🔭 어텐션 팔
		_tPWq      = _vis.Alloc(kPD, kPD);   _tPDWq = _vis.Alloc(kPD, kPD);
		_tPMWq     = _vis.Alloc(kPD, kPD);   _tPVWq = _vis.Alloc(kPD, kPD);
		_tPWk      = _vis.Alloc(kPD, kPD);   _tPDWk = _vis.Alloc(kPD, kPD);
		_tPMWk     = _vis.Alloc(kPD, kPD);   _tPVWk = _vis.Alloc(kPD, kPD);
		_tPWv      = _vis.Alloc(kPD, kPD);   _tPDWv = _vis.Alloc(kPD, kPD);
		_tPMWv     = _vis.Alloc(kPD, kPD);   _tPVWv = _vis.Alloc(kPD, kPD);
		_tPQ       = _vis.Alloc(r.Patches(), kPD);   _tPK  = _vis.Alloc(r.Patches(), kPD);
		_tPV       = _vis.Alloc(r.Patches(), kPD);   _tPO  = _vis.Alloc(r.Patches(), kPD);
		_tPDQ      = _vis.Alloc(r.Patches(), kPD);   _tPDK = _vis.Alloc(r.Patches(), kPD);
		_tPDV      = _vis.Alloc(r.Patches(), kPD);   _tPDO = _vis.Alloc(r.Patches(), kPD);
		_tPS       = _vis.Alloc(r.Patches(), r.Patches());
		_tPA       = _vis.Alloc(r.Patches(), r.Patches());
		_tPDA      = _vis.Alloc(r.Patches(), r.Patches());
		_tPDS      = _vis.Alloc(r.Patches(), r.Patches());
		_tPWo      = _vis.Alloc(kPD, kPCMax);   _tPDWo = _vis.Alloc(kPD, kPCMax);
		_tPMWo     = _vis.Alloc(kPD, kPCMax);   _tPVWo = _vis.Alloc(kPD, kPCMax);
		_tPEye     = _vis.Alloc(kPD, kPD);
		if (!_tPVWp.IsValid() || !_tPVWo.IsValid())
		{ LogA("[ml] 프로브: 텐서 할당 실패(아레나 부족)\n"); return false; }

		// 평균 풀링용 `ones` — 값이 `1/P` 다. ★ 팔·축과 무관하므로 한 번만.
		Array<float> ones;
		ones.Reset(r.Patches());
		for (uint32 i = 0; i < r.Patches(); ++i) ones.Data()[i] = 1.0f / (float)r.Patches();
		if (!_vis.Write(_tPOnes, ones))
		{ LogA("[ml] 프로브: ones 업로드 실패\n"); return false; }
		// 잔차용 항등행렬 — 상수라 한 번만.
		Array<float> eye;
		eye.Reset((uint64)kPD * kPD);
		for (uint32 i = 0; i < kPD * kPD; ++i) eye.Data()[i] = 0.0f;
		for (uint32 i = 0; i < kPD; ++i) eye.Data()[i * kPD + i] = 1.0f;
		if (!_vis.Write(_tPEye, eye))
		{ LogA("[ml] 프로브: 항등행렬 업로드 실패\n"); return false; }
		return true;
	}

	// 팔에 따라 달라지는 자리들 — ★ 한 곳에서 고른다(분기를 흩뿌리면 하나를 빼먹는다).
	const MLTensor& _ArmW()   const
	{ return (_pArm == 3) ? _tPWo : ((_pArm == 0) ? _tPWb : ((_pArm == 1) ? _tPWp : _tPW1)); }
	const MLTensor& _ArmDW()  const
	{ return (_pArm == 3) ? _tPDWo : ((_pArm == 0) ? _tPDWb : ((_pArm == 1) ? _tPDWp : _tPDW1)); }
	const MLTensor& _ArmMW()  const
	{ return (_pArm == 3) ? _tPMWo : ((_pArm == 0) ? _tPMWb : ((_pArm == 1) ? _tPMWp : _tPMW1)); }
	const MLTensor& _ArmVW()  const
	{ return (_pArm == 3) ? _tPVWo : ((_pArm == 0) ? _tPVWb : ((_pArm == 1) ? _tPVWp : _tPVW1)); }

	// ★ **팔별 lr — 2층은 단층보다 훨씬 민감하다.**
	//   ⚠️⚠️ **왜 단층은 되는데 2층은 안 되나**: 단층은 출력이 **곧 로짓**이라 CE 기울기
	//     (`probs − onehot`, 크기 1 이하)가 **스스로 제한**한다. 2층은 은닉이 커지면 ReLU 가 그대로
	//     통과시켜 로짓이 포화하고 `dLogits → 0` ⇒ **조금 움직이고 얼어붙는다.**
	//   ⇒ 그리고 AdamW 는 **스케일 불변**이라 첫 스텝부터 파라미터가 `lr` 씩 움직인다 —
	//     `W1` 이 32768개면 `h_pre = Σ_1024` 가 금방 커진다.
	//   ★ 그래서 2층 팔의 `lr` 을 낮춘다. ⚠️ 이것이 하이퍼파라미터 손질로 보이지만 **근거가 있다**:
	//     층이 늘면 같은 파라미터 이동이 활성값에 **곱해져** 전달된다.
	static constexpr float kPLr2 = 0.002f;
	float _ArmLr() const { return (_pArm == 2) ? kPLr2 : kPLr; }

	// 🎨 축 하나의 데이터셋 + 초기 가중치 + **모멘트 0**.
	bool _SetupProbeData(int axis)
	{
		MLPatchEmbedParams r;
		r.frameW = kPW; r.frameH = kPH; r.patchK = kPK; r.dim = kPD;
		const uint32 nAll = kPTrain + kPTest, plane = kPW * kPH;

		// 🎨 데이터셋 — 프레임을 실제로 그려서 담는다.
		Array<float> frames, onehot, slot, pos, w;
		frames.Reset((uint64)nAll * plane);
		onehot.Reset((uint64)nAll * kPCMax);
		for (uint64 i = 0; i < (uint64)nAll * kPCMax; ++i) onehot.Data()[i] = 0.0f;
		_pLabels.Reset(nAll);

		for (uint32 i = 0; i < nAll; ++i)
		{
			// ⚠️ **학습/시험 씨앗이 겹치지 않는다** — 겹치면 시험 손실이 의미를 잃는다.
			const bool test = (i >= kPTrain);
			const uint32 base = (test ? 90000u : 20000u) + (i - (test ? kPTrain : 0u)) * 7919u;
			// ★ **그 축의 값을 균등하게 덮어쓴다** — 하한이 정확히 `ln C` 가 되고, 그 축이 다른 축과
			//   독립이 된다(상관되어 있으면 프로브가 **딴 길로 맞힌다**).
			const int value = (int)(i % _pClasses);
			// ⚠️⚠️ 덮어쓰면 `Fits` 가 깨질 수 있다(큰 것 다섯 개 등) → **씨앗을 굴려** 들어가는 것을 찾는다.
			//   ★ 축 값은 고정한 채 나머지만 다시 뽑는다 — 그래야 균등 분포가 유지된다.
			MLScene sc;
			bool ok = false;
			for (uint32 t = 0; t < 64u && !ok; ++t)
			{
				sc = MLSense::BaseScene(base + t * 104729u);
				_AxisSet(sc, axis, value);
				// ★ **`개수깔끔` = *"같은 사과를 N개"*** — 잡음 축을 **전부 고정**한다.
				//   ⚠️ 이것은 상관을 만드는 것이 아니라 **분산을 없애는 것**이다(딴 길로 맞힐 여지가
				//     늘지 않는다) → 원래의 "축끼리 독립" 근거를 깨지 않는다.
				//   ★ 그리고 이것이 사람이 가르치는 방식이다 — 세는 법을 가르칠 때
				//     크기·색·모양이 같이 변하는 것을 세라고 하지 않는다(*"사과 1개" "사과 2개"*).
				//   ⚠️⚠️ **`자리` 는 일부러 고정하지 않는다** — ㉠ 가설이 말하는 것은 **면적 채널**이고
				//     자리는 면적에 영향이 없다 ⇒ **가설이 말하는 것만** 고정하는 것이 옳은 설계다.
				//   ★ 실용적 이유도 있다: 전부 고정하면 이 64회 재시도 루프가 **같은 장면만** 뽑게 되어
				//     `Fits` 가 거절하면 빠져나갈 길이 없다(자리가 흔들리면 들어가는 것을 찾아낸다).
				if (axis == kPAxCountClean)
				{
					sc.big = 0; sc.filled = 1; sc.shape = 0; sc.color = 0;
				}
				ok = MLSense::Fits(sc);
			}
			if (!ok)
			{
				LogA("[ml] 프로브: %u번 표본이 캔버스에 안 들어간다(축 %s · 값 %d)\n",
					i, _PAxisName(axis), value);
				return false;
			}
			_pLabels.Data()[i] = value;
			onehot.Data()[(uint64)i * kPCMax + (uint32)value] = 1.0f;

			if (!_RenderSceneBytes(sc, frames.Data() + (uint64)i * plane))
			{ LogA("[ml] 프로브: %u번 프레임 렌더 실패\n", i); return false; }
		}

		// 초기 가중치 — 결정적이고 작다. ⚠️ 0 이면 대칭이 안 깨진다.
		SeedRand(MLEpisodeGen::ScrambleSeed(4242u));
		slot.Reset((uint64)r.SlotRows() * kPD);
		for (uint64 i = 0; i < (uint64)r.SlotRows() * kPD; ++i)
			slot.Data()[i] = ((float)RandInt(0, 2001) * 0.001f - 1.0f) * 0.02f;
		pos.Reset((uint64)r.Patches() * kPD);
		for (uint64 i = 0; i < (uint64)r.Patches() * kPD; ++i)
			pos.Data()[i] = ((float)RandInt(0, 2001) * 0.001f - 1.0f) * 0.02f;
		// ⚠️ **팬인에 맞춰 초기값을 줄인다** — 자리 보존 팔은 팬인이 `P·D` 라 안 줄이면 로짓이
		//   처음부터 포화한다. ★ 두 팔의 초기값 규모를 팬인으로 맞추는 것이 공정한 비교의 조건이다.
		// ★ 어텐션 팔의 **머리는 자루와 같다**(`D×C`) → 팬인도 초기값 규칙도 같아진다.
		//   그것이 통제된 비교의 조건이다 — 다른 것은 중간의 어텐션 블록뿐이어야 한다.
		const uint32 fanIn = _ArmPools() ? kPD : (r.Patches() * kPD);
		// ★ **비선형 팔은 He 초기화**(`sqrt(2/fanIn)`) — ReLU 가 절반을 죽이므로 분산을 2배로 잡는다.
		//   ⚠️ 선형 팔은 기존 규칙(`0.4/fanIn`)을 그대로 둔다 — **이미 잘 배우고 있고**, 바꾸면
		//     committed 된 그 팔의 숫자가 흔들려 비교가 깨진다(같은 실행에서 견주는 것이 규칙이다).
		const float wScale = (_pArm == 2)
			? Sqrt(2.0f / (float)fanIn) : (0.4f / (float)fanIn);
		const uint32 outW = (_pArm == 2) ? kPHid : kPCMax;   // 비선형 팔의 첫 층은 은닉으로 간다
		const uint64 wN = (uint64)fanIn * outW;
		w.Reset(wN);
		for (uint64 i = 0; i < wN; ++i)
			w.Data()[i] = ((float)RandInt(0, 2001) * 0.001f - 1.0f) * wScale;

		if (!_vis.Write(_tPFrames, frames) || !_vis.Write(_tPOne, onehot)
			|| !_vis.Write(_tPSlot, slot)
			|| !_vis.Write(_tPPos, pos) || !_vis.Write(_ArmW(), w))
		{ LogA("[ml] 프로브: 데이터 업로드 실패\n"); return false; }

		// ⚠️⚠️ **모멘트를 0 으로 되돌린다** — 앞 축의 관성이 남으면 축끼리 비교가 안 되고,
		//   그 증상은 "뒤 축이 더 잘 배운다" 로만 보여서 데이터 버그로 안 읽힌다.
		if (!_ZeroTensor(_tPMS) || !_ZeroTensor(_tPVS) || !_ZeroTensor(_tPMP)
			|| !_ZeroTensor(_tPVP) || !_ZeroTensor(_ArmMW()) || !_ZeroTensor(_ArmVW()))
		{ LogA("[ml] 프로브: 모멘트 초기화 실패\n"); return false; }
		// 비선형 팔은 둘째 층도 초기화한다.
		if (_pArm == 2)
		{
			Array<float> w2;
			w2.Reset((uint64)kPHid * kPCMax);
			const float s2 = Sqrt(2.0f / (float)kPHid);
			for (uint64 i = 0; i < w2.Count(); ++i)
				w2.Data()[i] = ((float)RandInt(0, 2001) * 0.001f - 1.0f) * s2;
			if (!_vis.Write(_tPW2, w2)) { LogA("[ml] 프로브: W2 업로드 실패\n"); return false; }
			if (!_ZeroTensor(_tPMW2) || !_ZeroTensor(_tPVW2))
			{ LogA("[ml] 프로브: W2 모멘트 초기화 실패\n"); return false; }
		}
		// 🔭 어텐션 팔 — `Wq/Wk/Wv`(D×D) 셋.
		//   ★ **작게 시작하는 것이 설계다.** `Wq`·`Wk` 가 작으면 `S ≈ 0` → `A ≈ 균등` →
		//     `O ≈ 평균(V)` 이라 이 팔은 **자루 팔에서 출발한다**. ⇒ 나중에 나오는 이득은 전부
		//     *"관계를 배워서 얻은 것"* 이고, "초기값이 좋아서" 로 설명될 수 없다.
		//   ⚠️ 반대로 크게 시작하면 softmax 가 처음부터 뾰족해져 **한 패치만 보는 데서 못 벗어난다**
		//     (기울기가 그 자리에만 흐른다) — 어텐션에서 잘 알려진 실패 모양이다.
		if (_pArm == 3)
		{
			Array<float> wa;
			wa.Reset((uint64)kPD * kPD);
			const float sa = Sqrt(1.0f / (float)kPD);   // Xavier 결 — 팬인이 `D` 다
			const MLTensor* ws[3] = { &_tPWq, &_tPWk, &_tPWv };
			const MLTensor* ms[3] = { &_tPMWq, &_tPMWk, &_tPMWv };
			const MLTensor* vs[3] = { &_tPVWq, &_tPVWk, &_tPVWv };
			for (int t = 0; t < 3; ++t)
			{
				for (uint64 i = 0; i < wa.Count(); ++i)
					wa.Data()[i] = ((float)RandInt(0, 2001) * 0.001f - 1.0f) * sa;
				if (!_vis.Write(*ws[t], wa) || !_ZeroTensor(*ms[t]) || !_ZeroTensor(*vs[t]))
				{ LogA("[ml] 프로브: 어텐션 가중치 초기화 실패\n"); return false; }
			}
		}
		return true;
	}

	// 🔭 **어텐션 블록 한 번** — `patch(P×D) → Q,K,V → S → A → O → pool(1×D)`.
	//   ★ **새 커널이 하나도 없다** — `gemm` 에 전치 플래그가 있어서 일곱 단계가 전부 `gemm`
	//     + `softmax` 다. 평균풀링도 상수 `1/P` 벡터와의 `gemm` 이다(자루 팔이 쓰던 관용구 그대로).
	//   ★ `scale = 1/√D` 를 **softmax 의 온도로** 넘긴다 — 점수를 곱하는 커널을 따로 만들지 않는다.
	//     ⚠️ 역전파도 **같은 값**을 받아야 한다(사슬규칙) — 한쪽만 넣으면 기울기가 `1/√D` 배 틀리고
	//       증상이 *"학습이 느리다"* 라서 버그로 안 읽힌다.
	//   ⚠️ 학습 스텝과 평가가 **같은 이 함수**를 쓴다 — forward 를 두 벌로 적으면 반드시 갈린다
	//     (이 저장소가 여러 번 밟은 자리다).
	bool _DispatchAttn(uint32 P)
	{
		// ① Q = patch·Wq  ② K = patch·Wk  ③ V = patch·Wv — ★ 같은 `W` 가 **모든 자리에** 쓰인다.
		const MLTensor* src[3] = { &_tPWq, &_tPWk, &_tPWv };
		const MLTensor* dst[3] = { &_tPQ,  &_tPK,  &_tPV  };
		for (int t = 0; t < 3; ++t)
		{
			MLGemmParams g;
			g.aOff = _tPPatch.offset; g.bOff = src[t]->offset; g.cOff = dst[t]->offset;
			g.M = P; g.N = kPD; g.K = kPD;
			if (!_vGemm.Dispatch(kPD, P, 1u, &g, (uint32)sizeof(g))) return _Fail("attn qkv");
		}

		// ④ S = Q·Kᵀ — ⚠️ `K` 는 `P×D` 로 저장돼 있으므로 `transB = 1`.
		MLGemmParams gs;
		gs.aOff = _tPQ.offset; gs.bOff = _tPK.offset; gs.cOff = _tPS.offset;
		gs.M = P; gs.N = P; gs.K = kPD; gs.transB = 1;
		if (!_vGemm.Dispatch(P, P, 1u, &gs, (uint32)sizeof(gs))) return _Fail("attn scores");

		// ⑤ A = softmax(S · 1/√D) — 행마다(패치마다 "누구를 보나")
		MLSoftmaxParams sa;
		sa.inOff = _tPS.offset; sa.outOff = _tPA.offset;
		sa.rows = P; sa.cols = P; sa.scale = _AttnScale();
		if (!_vSoft.Dispatch(P, 1u, 1u, &sa, (uint32)sizeof(sa))) return _Fail("attn softmax");

		// ⑥ **O = patch + A·V — 잔차 연결.**
		//   ★ **왜 이것이 필요한가 — 진단이 그것을 지목했다(추측이 아니다).**
		//     실측: `A` 의 행엔트로피가 **400스텝 안에 4.14 → 0.00**, `maxA → 1.0000`,
		//     `max|S|` 가 **12 → 253,467** 로 폭발했다(여섯 축 전부 같은 모양).
		//   ★ 기제: **AdamW 는 스케일 불변**이라 `Wq/Wk` 의 기울기가 아무리 작아도 파라미터를 `lr` 씩
		//     계속 민다 → `S` 폭발 → softmax 포화 → `A` 가 one-hot ⇒ ㉠ 평균이 사라져 **자루로
		//     돌아갈 길이 막히고** ㉡ `softmax_bwd` 가 `p(1−p) ≈ 0` 을 곱하니 **기울기도 죽는다.**
		//     ⇒ **되돌아올 수 없는 함정문**이다(그래서 초기값을 작게 두는 것만으로는 안 된다).
		//   ★ 그리고 그것이 표를 한 줄씩 설명했다: 패치 **하나**로 답이 나오는 축(색·크기·속)은
		//     살고, 패치 **여럿을 모아야** 하는 축(개수·모양·자리)만 죽었다.
		//   ⇒ 잔차는 그 함정문을 **구조로** 막는다: `A` 가 어떻게 무너져도 `patch` 가 그대로 통과하므로
		//     **어텐션 팔이 학습 내내 자루 팔을 포함한다**(초기값에서만이 아니다).
		//   ⚠️ 잔차가 `S` 의 폭발을 **막지는 않는다** — 폭발을 **무해하게** 만드는 것이다.
		//     ★ 그것이 이 실험을 날카롭게 한다: `A` 가 그래도 무너지는데 팔이 자루를 이기면,
		//       *"잔차가 어텐션을 학습 가능하게 만든다"* 가 **분리되어** 증명된다.
		MLGemmParams gr;
		gr.aOff = _tPPatch.offset; gr.bOff = _tPEye.offset; gr.cOff = _tPO.offset;
		gr.M = P; gr.N = kPD; gr.K = kPD;
		if (!_vGemm.Dispatch(kPD, P, 1u, &gr, (uint32)sizeof(gr))) return _Fail("attn residual");

		MLGemmParams go;
		go.aOff = _tPA.offset; go.bOff = _tPV.offset; go.cOff = _tPO.offset;
		go.M = P; go.N = kPD; go.K = P; go.beta = 1.0f;   // ★ `+= A·V`
		if (!_vGemm.Dispatch(kPD, P, 1u, &go, (uint32)sizeof(go))) return _Fail("attn out");

		// ⑦ pool = (ones/P) · O — ★ **자리를 여기서 버린다.** 그래서 `모양` 을 맞히려면
		//   어텐션이 **자리와 무관한** 모양 특징을 만들어야 한다(그것이 이 실험의 질문이다).
		MLGemmParams gp;
		gp.aOff = _tPOnes.offset; gp.bOff = _tPO.offset; gp.cOff = _tPPool.offset;
		gp.M = 1; gp.N = kPD; gp.K = P;
		if (!_vGemm.Dispatch(kPD, 1u, 1u, &gp, (uint32)sizeof(gp))) return _Fail("attn pool");
		return true;
	}

	// ★ 온도 `1/√D` — forward 와 backward 가 **이 한 곳**에서 값을 받는다(두 곳에 적으면 갈린다).
	static float _AttnScale() { return 1.0f / Sqrt((float)kPD); }

	bool _ZeroTensor(const MLTensor& t)
	{
		Array<float> z;
		z.Reset(t.Count());
		for (uint32 i = 0; i < t.Count(); ++i) z.Data()[i] = 0.0f;
		return _vis.Write(t, z);
	}

	// 🖼️ 장면 하나를 그려 **RGB332 키프레임**을 float 로 담는다.
	//   ★ 절대 프레임이다(`prev = nullptr`) — 한 장짜리 프로브이므로 델타가 아니다.
	bool _RenderSceneBytes(const MLScene& sc, float* out)
	{
		DrawProgram prog;
		const String code = MLSense::Code(sc, false);
		if (!prog.Compile(code.View(), kPW, kPH, NameID("Probe"))) return false;
		if (!prog.RunStart()) return false;

		Bytes packed;
		packed.Reset((uint64)kPW * kPH);
		if (!ImageFormat::PackRGB332Delta(prog.canvas, nullptr,
			(uint8*)packed.GetData(), packed.GetSize())) return false;
		const uint8* q = (const uint8*)packed.GetData();
		for (uint64 i = 0; i < (uint64)kPW * kPH; ++i) out[i] = (float)q[i];
		return true;
	}

	// ★ **머리(분류기)는 늘 `kPCMax` 폭으로 돈다 — 축마다 폭을 줄이지 않는다.**
	//   ⚠️⚠️ 실측으로 밟았다: 폭을 `_pClasses` 로 줄였더니 **아레나의 "안 쓰는 칸" 에 앞 축의 값이 남아**
	//     `dPool = Σ_c dLogit[c]·W[d][c]` 에 유령 항이 섞였다. `개수`(6분류)가 `dLogit[5]` 를 쓴 뒤
	//     2·5분류 축이 그 칸을 안 건드렸기 때문이다.
	//     ★ 증상이 무서웠다: `색` 축이 **시험 0.0003 nat / 100% → 17.6 nat / 34%** 로 무너졌고,
	//       커널 판정(CPU 오차 0)은 **그대로 통과**했다 — 커널은 멀쩡했고 **호스트가 부르는 폭**이 문제였다.
	//   ★ 이것이 아레나 규약의 날카로운 쪽이다: **텐서가 오프셋으로 살면 "안 쓰는 칸" 이 조용히 남는다.**
	//     ⇒ 판정 규칙: *"이번에 안 쓰는 칸이 생기면, 그 칸을 0 으로 만들거나 아예 폭을 고정한다."*
	//     여기서는 **폭 고정**이 맞다 — 없는 분류는 모델이 스스로 확률 0 으로 밀어 버리므로 과제가 안 바뀐다.
	//
	// 한 스텝 = 디스패치 열하나. ★ 표본 하나(배치 1) — 그래서 **누적이 없고** 전부 "쓴다" 로 유지된다.
	//   ⚠️ 배치를 키우면 `dSlot` 이 누적이 되어야 하고 그러면 `+=` 가 필요해진다(= atomic 논쟁이 돌아온다).
	//     ⇒ 배치 1 은 게으름이 아니라 **결정성을 지키는 선택**이다.
	bool _DispatchProbeStep(int sample)
	{
		MLPatchEmbedParams r;
		r.frameW = kPW; r.frameH = kPH; r.patchK = kPK; r.dim = kPD;
		const uint32 plane = kPW * kPH, P = r.Patches();
		const uint32 frameOff = _tPFrames.offset + (uint32)sample * plane;

		// ① patch = Σ slot[(s,byte)] + pos
		MLPatchEmbedParams f = r;
		f.frameOff = frameOff; f.aOff = _tPSlot.offset;
		f.bOff = _tPPos.offset; f.cOff = _tPPatch.offset;
		if (!_vPE.Dispatch(kPD, P, 1u, &f, (uint32)sizeof(f))) return _Fail("probe patch");

		// ② 판독 → logits.
		//   · **자루**: `pool = ones(1×P)/P · patch(P×D)` 뒤 `logits = pool · W(D×C)`
		//   · **자리보존**: ★ `patch` 를 **그대로 한 줄로** 읽는다(아레나에 `P×D` 로 이어져 있어 복사 없음).
		//     자리 정보가 **W 의 행**에 남는다.
		if (_pArm == 0)
		{
			MLGemmParams gp;
			gp.aOff = _tPOnes.offset; gp.bOff = _tPPatch.offset; gp.cOff = _tPPool.offset;
			gp.M = 1; gp.N = kPD; gp.K = P;
			if (!_vGemm.Dispatch(kPD, 1u, 1u, &gp, (uint32)sizeof(gp))) return _Fail("probe pool");
		}
		// 🔭 **어텐션 팔**: 자루와 같은 자리에 풀링이 나오지만 **푸는 대상이 `O`** 다(패치가 아니다).
		else if (_pArm == 3 && !_DispatchAttn(P)) return false;
		const uint32 headIn = _ArmPools() ? kPD : (P * kPD);
		const uint32 headOff = _ArmPools() ? _tPPool.offset : _tPPatch.offset;

		// ★ **비선형 팔**: `patch → W1 → ReLU → W2 → logits`.
		//   ⚠️ **활성 전 값을 따로 둔다**(`_tPHpre`) — `relu_bwd` 가 그것을 읽는다.
		if (_pArm == 2)
		{
			MLGemmParams g1;
			g1.aOff = headOff; g1.bOff = _tPW1.offset; g1.cOff = _tPHpre.offset;
			g1.M = 1; g1.N = kPHid; g1.K = headIn;
			if (!_vGemm.Dispatch(kPHid, 1u, 1u, &g1, (uint32)sizeof(g1))) return _Fail("probe h1");

			MLReluParams rl;
			rl.aOff = _tPHpre.offset; rl.bOff = _tPHact.offset; rl.count = kPHid;
			if (!_vRelu.Dispatch(kPHid, 1u, 1u, &rl, (uint32)sizeof(rl))) return _Fail("probe relu");
		}
		const uint32 lastIn = (_pArm == 2) ? kPHid : headIn;
		const uint32 lastOff = (_pArm == 2) ? _tPHact.offset : headOff;
		const MLTensor& lastW = (_pArm == 2) ? _tPW2 : _ArmW();

		MLGemmParams gl;
		gl.aOff = lastOff; gl.bOff = lastW.offset; gl.cOff = _tPLogit.offset;
		gl.M = 1; gl.N = kPCMax; gl.K = lastIn;
		if (!_vGemm.Dispatch(kPCMax, 1u, 1u, &gl, (uint32)sizeof(gl))) return _Fail("probe logits");

		// ④ probs = softmax(logits)
		MLSoftmaxParams sm;
		sm.inOff = _tPLogit.offset; sm.outOff = _tPProb.offset; sm.rows = 1; sm.cols = kPCMax;
		if (!_vSoft.Dispatch(1u, 1u, 1u, &sm, (uint32)sizeof(sm))) return _Fail("probe softmax");

		// ⑤ dLogits = probs − onehot[sample]
		MLSubParams sb;
		sb.aOff = _tPProb.offset; sb.bOff = _tPOne.offset + (uint32)sample * kPCMax;
		sb.outOff = _tPDLogit.offset; sb.count = kPCMax;
		if (!_vSub.Dispatch(sb.count, 1u, 1u, &sb, (uint32)sizeof(sb))) return _Fail("probe dlogits");

		// ⑥ 마지막 층의 기울기 — `dW_last = 마지막입력ᵀ · dLogits`
		MLGemmParams gw;
		gw.aOff = lastOff; gw.bOff = _tPDLogit.offset;
		gw.cOff = (_pArm == 2) ? _tPDW2.offset : _ArmDW().offset;
		gw.M = lastIn; gw.N = kPCMax; gw.K = 1; gw.transA = 1;
		if (!_vGemm.Dispatch(kPCMax, lastIn, 1u, &gw, (uint32)sizeof(gw))) return _Fail("probe dW");

		// ⑦ 마지막 층의 입력 기울기 — ⚠️ W 는 `입력 × C` 저장이므로 `transB = 1`
		const uint32 dHeadOff = _ArmPools() ? _tPDPool.offset : _tPDPatch.offset;
		MLGemmParams gd;
		gd.aOff = _tPDLogit.offset; gd.bOff = lastW.offset;
		gd.cOff = (_pArm == 2) ? _tPDHact.offset : dHeadOff;
		gd.M = 1; gd.N = lastIn; gd.K = kPCMax; gd.transB = 1;
		if (!_vGemm.Dispatch(lastIn, 1u, 1u, &gd, (uint32)sizeof(gd))) return _Fail("probe dHead");

		// ⑦b 비선형 팔 — ReLU 역전파 + 첫 층
		if (_pArm == 2)
		{
			MLReluParams rb;
			rb.aOff = _tPHpre.offset; rb.bOff = _tPDHact.offset; rb.cOff = _tPDHpre.offset;
			rb.count = kPHid;
			if (!_vReluB.Dispatch(kPHid, 1u, 1u, &rb, (uint32)sizeof(rb))) return _Fail("probe relu bwd");

			MLGemmParams gw1;
			gw1.aOff = headOff; gw1.bOff = _tPDHpre.offset; gw1.cOff = _tPDW1.offset;
			gw1.M = headIn; gw1.N = kPHid; gw1.K = 1; gw1.transA = 1;
			if (!_vGemm.Dispatch(kPHid, headIn, 1u, &gw1, (uint32)sizeof(gw1))) return _Fail("probe dW1");

			MLGemmParams gd1;
			gd1.aOff = _tPDHpre.offset; gd1.bOff = _tPW1.offset; gd1.cOff = dHeadOff;
			gd1.M = 1; gd1.N = headIn; gd1.K = kPHid; gd1.transB = 1;
			if (!_vGemm.Dispatch(headIn, 1u, 1u, &gd1, (uint32)sizeof(gd1))) return _Fail("probe dPatch2");
		}

		// ⑧ 풀링 팔 — `dO = onesᵀ · dPool`(평균 풀링의 역전파가 `dPool/P` 라는 사실).
		//   ★ 자루는 그 결과가 곧 `dPatch` 이고, 어텐션은 `dO` 다(어텐션 블록을 더 거슬러야 한다).
		if (_ArmPools())
		{
			MLGemmParams gq;
			gq.aOff = _tPOnes.offset; gq.bOff = _tPDPool.offset;
			gq.cOff = (_pArm == 3) ? _tPDO.offset : _tPDPatch.offset;
			gq.M = P; gq.N = kPD; gq.K = 1; gq.transA = 1;
			if (!_vGemm.Dispatch(kPD, P, 1u, &gq, (uint32)sizeof(gq))) return _Fail("probe dPatch");
		}

		// ⑧b 🔭 **어텐션 블록의 역전파** — 전부 `gemm` 이고 새 커널은 `softmax_bwd` 하나뿐이다.
		if (_pArm == 3)
		{
			// dA = dO · Vᵀ
			MLGemmParams ga;
			ga.aOff = _tPDO.offset; ga.bOff = _tPV.offset; ga.cOff = _tPDA.offset;
			ga.M = P; ga.N = P; ga.K = kPD; ga.transB = 1;
			if (!_vGemm.Dispatch(P, P, 1u, &ga, (uint32)sizeof(ga))) return _Fail("attn dA");

			// dV = Aᵀ · dO
			MLGemmParams gv;
			gv.aOff = _tPA.offset; gv.bOff = _tPDO.offset; gv.cOff = _tPDV.offset;
			gv.M = P; gv.N = kPD; gv.K = P; gv.transA = 1;
			if (!_vGemm.Dispatch(kPD, P, 1u, &gv, (uint32)sizeof(gv))) return _Fail("attn dV");

			// dS = softmax_bwd(A, dA) — ⚠️ **온도를 여기서 한 번 더 곱한다**(forward 와 같은 값).
			MLSoftmaxBwdParams sb2;
			sb2.probOff = _tPA.offset; sb2.dOutOff = _tPDA.offset; sb2.dInOff = _tPDS.offset;
			sb2.rows = P; sb2.cols = P; sb2.scale = _AttnScale();
			if (!_vSoftB.Dispatch(P, 1u, 1u, &sb2, (uint32)sizeof(sb2))) return _Fail("attn dS");

			// dQ = dS · K   ·   dK = dSᵀ · Q   (`S = Q·Kᵀ` 의 두 미분)
			MLGemmParams gq2;
			gq2.aOff = _tPDS.offset; gq2.bOff = _tPK.offset; gq2.cOff = _tPDQ.offset;
			gq2.M = P; gq2.N = kPD; gq2.K = P;
			if (!_vGemm.Dispatch(kPD, P, 1u, &gq2, (uint32)sizeof(gq2))) return _Fail("attn dQ");
			MLGemmParams gk2;
			gk2.aOff = _tPDS.offset; gk2.bOff = _tPQ.offset; gk2.cOff = _tPDK.offset;
			gk2.M = P; gk2.N = kPD; gk2.K = P; gk2.transA = 1;
			if (!_vGemm.Dispatch(kPD, P, 1u, &gk2, (uint32)sizeof(gk2))) return _Fail("attn dK");

			// dW* = patchᵀ · d*  — ★ **자리마다 더해진다**(그것이 곧 가중치 공유의 역전파다).
			const MLTensor* dW[3] = { &_tPDWq, &_tPDWk, &_tPDWv };
			const MLTensor* dX[3] = { &_tPDQ,  &_tPDK,  &_tPDV  };
			for (int t = 0; t < 3; ++t)
			{
				MLGemmParams gwq;
				gwq.aOff = _tPPatch.offset; gwq.bOff = dX[t]->offset; gwq.cOff = dW[t]->offset;
				gwq.M = kPD; gwq.N = kPD; gwq.K = P; gwq.transA = 1;
				if (!_vGemm.Dispatch(kPD, kPD, 1u, &gwq, (uint32)sizeof(gwq))) return _Fail("attn dW");
			}

			// dPatch = **dO**(잔차) + dQ·Wqᵀ + dK·Wkᵀ + dV·Wvᵀ
			//   ★ **`beta` 로 누산한다**(`add` 커널이 없다) — 첫 항만 `beta = 0`, 나머지는 `beta = 1`.
			//   ★ **잔차 항이 여기 있는 것이 핵심이다** — `A` 가 one-hot 으로 무너져 어텐션 경로의
			//     기울기가 죽어도 **`dO` 가 그대로 `dPatch` 로 흐른다** ⇒ 패치 임베딩은 계속 배운다.
			MLGemmParams gr2;
			gr2.aOff = _tPDO.offset; gr2.bOff = _tPEye.offset; gr2.cOff = _tPDPatch.offset;
			gr2.M = P; gr2.N = kPD; gr2.K = kPD;
			if (!_vGemm.Dispatch(kPD, P, 1u, &gr2, (uint32)sizeof(gr2))) return _Fail("attn dPatch res");

			const MLTensor* wT[3] = { &_tPWq, &_tPWk, &_tPWv };
			for (int t = 0; t < 3; ++t)
			{
				MLGemmParams gx;
				gx.aOff = dX[t]->offset; gx.bOff = wT[t]->offset; gx.cOff = _tPDPatch.offset;
				gx.M = P; gx.N = kPD; gx.K = kPD; gx.transB = 1;
				gx.beta = 1.0f;
				if (!_vGemm.Dispatch(kPD, P, 1u, &gx, (uint32)sizeof(gx))) return _Fail("attn dPatch");
			}
		}

		// ⑨ dSlot — **gather**(atomic 없이 결정적으로)
		MLPatchEmbedParams pb = r;
		pb.frameOff = frameOff; pb.aOff = _tPDPatch.offset; pb.bOff = _tPDSlot.offset;
		if (!_vPEB.Dispatch(kPD, pb.SlotRows(), 1u, &pb, (uint32)sizeof(pb)))
			return _Fail("probe dSlot");

		// ⑩⑪⑫ AdamW × 3. ★ `posTable` 의 기울기는 **`dPatch` 그 자체**다(forward 가 그냥 더하므로
		//   미분이 1 이고 배치가 같다) — 커널도 복사도 없다.
		float bc1 = 1.0f, bc2 = 1.0f;
		_BiasCorr(_pStep + 1, bc1, bc2);
		MLAdamWParams aw;
		aw.lr = _ArmLr(); aw.beta1 = kB1; aw.beta2 = kB2; aw.eps = kAdamEps; aw.wd = kWd;
		aw.bc1 = bc1; aw.bc2 = bc2;

		aw.pOff = _tPSlot.offset; aw.gOff = _tPDSlot.offset;
		aw.mOff = _tPMS.offset;   aw.vOff = _tPVS.offset;   aw.count = _tPSlot.Count();
		if (!_vAdam.Dispatch(aw.count, 1u, 1u, &aw, (uint32)sizeof(aw))) return _Fail("probe adamw slot");

		MLAdamWParams ap = aw;
		ap.pOff = _tPPos.offset;  ap.gOff = _tPDPatch.offset;
		ap.mOff = _tPMP.offset;   ap.vOff = _tPVP.offset;   ap.count = _tPPos.Count();
		if (!_vAdam.Dispatch(ap.count, 1u, 1u, &ap, (uint32)sizeof(ap))) return _Fail("probe adamw pos");

		MLAdamWParams ax = aw;
		ax.pOff = _ArmW().offset;  ax.gOff = _ArmDW().offset;
		ax.mOff = _ArmMW().offset; ax.vOff = _ArmVW().offset; ax.count = _ArmW().Count();
		if (!_vAdam.Dispatch(ax.count, 1u, 1u, &ax, (uint32)sizeof(ax))) return _Fail("probe adamw W");

		if (_pArm == 2)
		{
			MLAdamWParams a2 = aw;
			a2.pOff = _tPW2.offset;  a2.gOff = _tPDW2.offset;
			a2.mOff = _tPMW2.offset; a2.vOff = _tPVW2.offset; a2.count = _tPW2.Count();
			if (!_vAdam.Dispatch(a2.count, 1u, 1u, &a2, (uint32)sizeof(a2))) return _Fail("probe adamw W2");
		}
		// 🔭 어텐션 팔 — `Wq/Wk/Wv` 셋도 같은 옵티마이저로 민다(`Wo` 는 위 `_ArmW()` 가 이미 밀었다).
		if (_pArm == 3)
		{
			const MLTensor* pw[3] = { &_tPWq,  &_tPWk,  &_tPWv  };
			const MLTensor* gw2[3] = { &_tPDWq, &_tPDWk, &_tPDWv };
			const MLTensor* mw[3] = { &_tPMWq, &_tPMWk, &_tPMWv };
			const MLTensor* vw[3] = { &_tPVWq, &_tPVWk, &_tPVWv };
			for (int t = 0; t < 3; ++t)
			{
				MLAdamWParams aq = aw;
				aq.pOff = pw[t]->offset;  aq.gOff = gw2[t]->offset;
				aq.mOff = mw[t]->offset;  aq.vOff = vw[t]->offset;  aq.count = pw[t]->Count();
				if (!_vAdam.Dispatch(aq.count, 1u, 1u, &aq, (uint32)sizeof(aq)))
					return _Fail("probe adamw attn");
			}
		}
		return true;
	}

	// 📏 **평가 패스 — 한 프레임에 150장을 다 전진시킨다.**
	//   ★ 회수가 한 번뿐이라 G′ 를 딱 한 번만 문다. 스크래치(`patch`/`pool`/`logits`)를 표본마다
	//     덮어쓰지만 **디스패치가 순서대로 돌므로** 안전하다 — 그 순서 보장이 P1 의 "오차 0" 이 증명한 것이다.
	//   ⚠️ 학습을 하지 않는다(역전파·옵티마이저 없음) — 시험 표본에 손을 대면 판정이 무의미해진다.
	bool _DispatchEval()
	{
		MLPatchEmbedParams r;
		r.frameW = kPW; r.frameH = kPH; r.patchK = kPK; r.dim = kPD;
		const uint32 plane = kPW * kPH, P = r.Patches(), nAll = kPTrain + kPTest;

		for (uint32 i = 0; i < nAll; ++i)
		{
			MLPatchEmbedParams f = r;
			f.frameOff = _tPFrames.offset + i * plane; f.aOff = _tPSlot.offset;
			f.bOff = _tPPos.offset; f.cOff = _tPPatch.offset;
			if (!_vPE.Dispatch(kPD, P, 1u, &f, (uint32)sizeof(f))) return _Fail("eval patch");

			if (_pArm == 0)
			{
				MLGemmParams gp;
				gp.aOff = _tPOnes.offset; gp.bOff = _tPPatch.offset; gp.cOff = _tPPool.offset;
				gp.M = 1; gp.N = kPD; gp.K = P;
				if (!_vGemm.Dispatch(kPD, 1u, 1u, &gp, (uint32)sizeof(gp))) return _Fail("eval pool");
			}
			// ★ 학습과 **같은 함수**를 쓴다 — forward 를 두 벌로 적으면 반드시 갈린다.
			else if (_pArm == 3 && !_DispatchAttn(P)) return false;
			const uint32 hIn = _ArmPools() ? kPD : (P * kPD);
			const uint32 hOff = _ArmPools() ? _tPPool.offset : _tPPatch.offset;
			if (_pArm == 2)
			{
				MLGemmParams g1;
				g1.aOff = hOff; g1.bOff = _tPW1.offset; g1.cOff = _tPHpre.offset;
				g1.M = 1; g1.N = kPHid; g1.K = hIn;
				if (!_vGemm.Dispatch(kPHid, 1u, 1u, &g1, (uint32)sizeof(g1))) return _Fail("eval h1");
				MLReluParams rl;
				rl.aOff = _tPHpre.offset; rl.bOff = _tPHact.offset; rl.count = kPHid;
				if (!_vRelu.Dispatch(kPHid, 1u, 1u, &rl, (uint32)sizeof(rl))) return _Fail("eval relu");
			}
			MLGemmParams gl;
			gl.aOff = (_pArm == 2) ? _tPHact.offset : hOff;
			gl.bOff = (_pArm == 2) ? _tPW2.offset : _ArmW().offset;
			gl.cOff = _tPLogit.offset;
			gl.M = 1; gl.N = kPCMax; gl.K = (_pArm == 2) ? kPHid : hIn;
			if (!_vGemm.Dispatch(kPCMax, 1u, 1u, &gl, (uint32)sizeof(gl))) return _Fail("eval logits");

			// ★ 표본마다 **자기 자리**에 확률을 쓴다 → 회수는 마지막에 한 번.
			MLSoftmaxParams sm;
			sm.inOff = _tPLogit.offset; sm.outOff = _tPProbAll.offset + i * kPCMax;
			sm.rows = 1; sm.cols = kPCMax;
			if (!_vSoft.Dispatch(1u, 1u, 1u, &sm, (uint32)sizeof(sm))) return _Fail("eval softmax");
		}
		LogA("[ml] 프로브 평가 디스패치 — %u장(학습 %u + 시험 %u) · 회수는 다음 프레임\n",
			nAll, kPTrain, kPTest);
		return true;
	}

	// ✍️ **D2-b 셋업** — 코퍼스(캡션 100개 + 그 프레임)를 만들고 텐서를 잡는다.
	bool _SetupGen()
	{
		MLPatchEmbedParams r;
		r.frameW = kGnW; r.frameH = kGnH; r.patchK = kGnK; r.dim = kGnD;
		const uint32 P = r.Patches(), plane = kGnW * kGnH, nAll = kGnTrain + kGnEval;
		const uint32 cRow = P * kGnD;              // 자리보존 조건 벡터의 길이

		// ── 코퍼스 ──
		//   ⚠️ **공백을 지우지 않는다** — 생성은 캡션을 **글자 그대로** 내야 하고, 공백도 그 일부다
		//     (경계망은 경계를 찾는 것이 목적이라 공백을 지웠다 — 목적이 다르면 전처리도 다르다).
		_gnBytes.Reset(0); _gnStart.Reset(0); _gnLen.Reset(0);
		_gnFrameBytes.Reset((uint64)nAll * plane);
		_gnCaps.Reset(nAll);
		_gnScenes.Reset(nAll);
		for (uint32 i = 0; i < nAll; ++i)
		{
			MLScene sc; String cap; Array<int> waxIgnored;
			// ⚠️ 학습/시험 씨앗이 겹치지 않는다.
			const uint32 seed = (i < kGnTrain) ? (310000u + i) : (920000u + (i - kGnTrain));
			MLSense::MakeLesson(seed, sc, cap, waxIgnored);
			_gnCaps.Data()[i] = cap;
			_gnScenes.Data()[i] = sc;   // ▶️ 실행 채점의 정답 쪽
			const char* c = cap.ptr();
			const uint32 st = (uint32)_gnBytes.Count();
			// ★ **캡션마다 앞에 `BOS`(바이트 0) 를 둔다 — 이것이 함정 1 의 자리다.**
			//   ⚠️⚠️ 실측으로 밟았다: BOS 없이 두면 학습은 위치 `t` 에서 `byte[t+1]` 을 맞히는데
			//     **생성은 아무것도 없는 상태에서 `byte[0]` 을 내야 한다** ⇒ 그 자리를 **한 번도
			//     학습하지 않는다** ⇒ 생성이 **첫 스텝에서 즉시 "끝"** 을 골라 **빈 문자열**이 나왔다.
			//   ★ 증상이 *"모델이 덜 배웠다"* 처럼 보여서 원인과 안 닮는다(손실은 0.03 까지 내려갔다!).
			//   ⇒ BOS 를 두면 `h[t]` 가 `[BOS, b0..b_{t-1}]` 를 보고 **`b_t`** 를 맞힌다 ⇒ 생성과 정렬된다.
			//   ★ `0` 을 쓰는 근거: 캡션 바이트에 0 이 없고(UTF-8 문자열이다) 창 표가 자리별이라
			//     `자리 0 의 바이트 0` 이 다른 것과 안 섞인다. ⚠️ 커널은 `>255` 를 0 으로 접으므로
			//     256 을 BOS 로 쓸 수 없다(그래서 0 이다).
			_gnBytes.Add(0.0f);
			uint32 ln = 0;
			for (uint32 j = 0; c != nullptr && c[j] != 0 && ln < kGnMaxLen - 2u; ++j)
			{ _gnBytes.Add((float)(uint8)c[j]); ln++; }
			_gnStart.Add(st); _gnLen.Add(ln);
			if (!_RenderSceneBytes(sc, _gnFrameBytes.Data() + (uint64)i * plane))
			{ LogA("[ml] 생성: %u번 프레임 렌더 실패\n", i); return false; }
		}
		_gnTotal = (uint32)_gnBytes.Count();
		if (_gnTotal == 0u) { LogA("[ml] 생성: 코퍼스가 비었다\n"); return false; }

		// ── 아레나 ──
		const uint32 need =
			nAll * plane                            // 프레임
			+ _gnTotal                              // 바이트
			+ _gnTotal * kGnVoc                     // onehot(다음 바이트 · 마지막은 "끝")
			+ r.SlotRows() * kGnD * 4u              // 패치 표 · d · m · v
			+ P * kGnD * 3u                         // 자리 표 · m · v
			+ cRow * 2u                             // patch · dPatch
			+ (kGnCtx * kGnVoc) * kGnD * 4u         // 창 표 · d · m · v
			+ kGnMaxLen * kGnD * 2u                 // h · dH
			+ kGnD * kGnVoc * 4u                    // Wh · d · m · v
			+ kGnD * kGnVoc * 4u                    // Wc · d · m · v (🔭 조건 벡터가 1×D 로 줄었다)
			+ kGnD * kGnD * 13u                     // Wq/Wk/Wv(각 4벌) + Eye
			+ P * kGnD * 8u                         // Q/K/V/O + 기울기
			+ P * P * 4u                            // S/A/dA/dS
			+ P + kGnD * 2u                         // 풀링 ones + pool·dPool
			+ kGnD * kGnHid * 8u                    // W1 · Wc1 (각 4벌)
			+ kGnHid * kGnVoc * 4u                  // W2 · d · m · v
			+ kGnMaxLen * kGnHid * 4u               // hpre · hact · dHact · dHpre
			+ kGnHid * 2u                           // cwHid · dCwHid
			+ kGnSelfCaps * kGnMaxLen * (1u + kGnVoc)   // 🔁 자기학습 타깃 + onehot
			+ kGnVoc * 2u + kGnMaxLen               // cw · dCw · onesT
			+ kGnMaxLen * kGnVoc * 3u               // logit · prob · dLogit
			+ 1024u;
		if (!_gn.Create(rhi, need))
		{ LogA("[ml] 생성: 아레나 생성 실패(%u floats)\n", need); return false; }

		_tGnFrames = _gn.Alloc(nAll, plane);
		_tGnBytes  = _gn.Alloc(1, _gnTotal);
		_tGnOne    = _gn.Alloc(_gnTotal, kGnVoc);
		_tGnSlot   = _gn.Alloc(r.SlotRows(), kGnD);
		_tGnDSlot  = _gn.Alloc(r.SlotRows(), kGnD);
		_tGnMS     = _gn.Alloc(r.SlotRows(), kGnD);
		_tGnVS     = _gn.Alloc(r.SlotRows(), kGnD);
		_tGnPos    = _gn.Alloc(P, kGnD);
		_tGnMP     = _gn.Alloc(P, kGnD);
		_tGnVP     = _gn.Alloc(P, kGnD);
		_tGnPatch  = _gn.Alloc(P, kGnD);
		_tGnDPatch = _gn.Alloc(P, kGnD);
		_tGnCSlot  = _gn.Alloc(kGnCtx * kGnVoc, kGnD);
		_tGnDCSlot = _gn.Alloc(kGnCtx * kGnVoc, kGnD);
		_tGnMC     = _gn.Alloc(kGnCtx * kGnVoc, kGnD);
		_tGnVC     = _gn.Alloc(kGnCtx * kGnVoc, kGnD);
		_tGnH      = _gn.Alloc(kGnMaxLen, kGnD);
		_tGnDH     = _gn.Alloc(kGnMaxLen, kGnD);
		_tGnWh     = _gn.Alloc(kGnD, kGnVoc);
		_tGnDWh    = _gn.Alloc(kGnD, kGnVoc);
		_tGnMWh    = _gn.Alloc(kGnD, kGnVoc);
		_tGnVWh    = _gn.Alloc(kGnD, kGnVoc);
		_tGnWc     = _gn.Alloc(kGnD, kGnVoc);
		_tGnDWc    = _gn.Alloc(kGnD, kGnVoc);
		_tGnMWc    = _gn.Alloc(kGnD, kGnVoc);
		_tGnVWc    = _gn.Alloc(kGnD, kGnVoc);
		// 🔭 어텐션 조건 경로
		_tGnWq     = _gn.Alloc(kGnD, kGnD);   _tGnDWq = _gn.Alloc(kGnD, kGnD);
		_tGnMWq    = _gn.Alloc(kGnD, kGnD);   _tGnVWq = _gn.Alloc(kGnD, kGnD);
		_tGnWk     = _gn.Alloc(kGnD, kGnD);   _tGnDWk = _gn.Alloc(kGnD, kGnD);
		_tGnMWk    = _gn.Alloc(kGnD, kGnD);   _tGnVWk = _gn.Alloc(kGnD, kGnD);
		_tGnWv     = _gn.Alloc(kGnD, kGnD);   _tGnDWv = _gn.Alloc(kGnD, kGnD);
		_tGnMWv    = _gn.Alloc(kGnD, kGnD);   _tGnVWv = _gn.Alloc(kGnD, kGnD);
		_tGnQ      = _gn.Alloc(P, kGnD);   _tGnK  = _gn.Alloc(P, kGnD);
		_tGnV      = _gn.Alloc(P, kGnD);   _tGnO  = _gn.Alloc(P, kGnD);
		_tGnDQ     = _gn.Alloc(P, kGnD);   _tGnDK = _gn.Alloc(P, kGnD);
		_tGnDV     = _gn.Alloc(P, kGnD);   _tGnDO = _gn.Alloc(P, kGnD);
		_tGnS      = _gn.Alloc(P, P);      _tGnA  = _gn.Alloc(P, P);
		_tGnDA     = _gn.Alloc(P, P);      _tGnDS = _gn.Alloc(P, P);
		_tGnEye    = _gn.Alloc(kGnD, kGnD);
		_tGnPOnes  = _gn.Alloc(1, P);
		_tGnPool   = _gn.Alloc(1, kGnD);
		_tGnDPool  = _gn.Alloc(1, kGnD);
		// 🔀 비선형 머리
		_tGnW1     = _gn.Alloc(kGnD, kGnHid);     _tGnDW1  = _gn.Alloc(kGnD, kGnHid);
		_tGnMW1    = _gn.Alloc(kGnD, kGnHid);     _tGnVW1  = _gn.Alloc(kGnD, kGnHid);
		_tGnW2     = _gn.Alloc(kGnHid, kGnVoc);   _tGnDW2  = _gn.Alloc(kGnHid, kGnVoc);
		_tGnMW2    = _gn.Alloc(kGnHid, kGnVoc);   _tGnVW2  = _gn.Alloc(kGnHid, kGnVoc);
		_tGnWc1    = _gn.Alloc(kGnD, kGnHid);     _tGnDWc1 = _gn.Alloc(kGnD, kGnHid);
		_tGnMWc1   = _gn.Alloc(kGnD, kGnHid);     _tGnVWc1 = _gn.Alloc(kGnD, kGnHid);
		_tGnHpre   = _gn.Alloc(kGnMaxLen, kGnHid);
		_tGnHact   = _gn.Alloc(kGnMaxLen, kGnHid);
		_tGnDHact  = _gn.Alloc(kGnMaxLen, kGnHid);
		_tGnDHpre  = _gn.Alloc(kGnMaxLen, kGnHid);
		_tGnCwH    = _gn.Alloc(1, kGnHid);        _tGnDCwH = _gn.Alloc(1, kGnHid);
		_tGnSelfTok = _gn.Alloc(1, kGnSelfCaps * kGnMaxLen);
		_tGnSelfOne = _gn.Alloc(kGnSelfCaps * kGnMaxLen, kGnVoc);
		_tGnCw     = _gn.Alloc(1, kGnVoc);
		_tGnDCw    = _gn.Alloc(1, kGnVoc);
		_tGnOnesT  = _gn.Alloc(kGnMaxLen, 1);
		_tGnLogit  = _gn.Alloc(kGnMaxLen, kGnVoc);
		_tGnProb   = _gn.Alloc(kGnMaxLen, kGnVoc);
		_tGnDLogit = _gn.Alloc(kGnMaxLen, kGnVoc);
		if (!_tGnDLogit.IsValid())
		{ LogA("[ml] 생성: 텐서 할당 실패(아레나 부족)\n"); return false; }

		// ── onehot(다음 바이트) ──
		//   ★ 캡션의 **마지막 자리**의 정답이 `256`("끝") 이다 ⇒ 길이를 어휘 안에 담는다(함정 2).
		Array<float> one;
		one.Reset((uint64)_gnTotal * kGnVoc);
		for (uint64 i = 0; i < one.Count(); ++i) one.Data()[i] = 0.0f;
		//   ★ 저장은 `[BOS, b0 … b_{ln−1}]`(길이 `ln+1`) 이고 예측 자리는 그 **전부**다:
		//     `t = 0 … ln−1` → `b_t` · `t = ln` → **256("끝")**. ⇒ 첫 바이트도 배우고 끝도 배운다.
		for (uint32 i = 0; i < nAll; ++i)
		{
			const uint32 st = _gnStart.Data()[i], ln = _gnLen.Data()[i];
			for (uint32 t = 0; t <= ln; ++t)
			{
				const uint32 v = (t < ln) ? (uint32)_gnBytes.Data()[st + 1u + t] : 256u;
				one.Data()[(uint64)(st + t) * kGnVoc + v] = 1.0f;
			}
		}

		Array<float> onesT;
		onesT.Reset(kGnMaxLen);
		for (uint32 i = 0; i < kGnMaxLen; ++i) onesT.Data()[i] = 1.0f;

		// 🔭 상수 둘 — 잔차용 항등행렬 + 평균 풀링용 `1/P` 벡터(팔과 무관하므로 한 번만).
		Array<float> eye, pones;
		eye.Reset((uint64)kGnD * kGnD);
		for (uint32 i = 0; i < kGnD * kGnD; ++i) eye.Data()[i] = 0.0f;
		for (uint32 i = 0; i < kGnD; ++i) eye.Data()[(uint64)i * kGnD + i] = 1.0f;
		pones.Reset(P);
		for (uint32 i = 0; i < P; ++i) pones.Data()[i] = 1.0f / (float)P;

		if (!_gn.Write(_tGnFrames, _gnFrameBytes) || !_gn.Write(_tGnBytes, _gnBytes)
			|| !_gn.Write(_tGnOne, one) || !_gn.Write(_tGnOnesT, onesT)
			|| !_gn.Write(_tGnEye, eye) || !_gn.Write(_tGnPOnes, pones))
		{ LogA("[ml] 생성: 업로드 실패\n"); return false; }

		if (!_LoadKernelIn(_gnPE,   "shaders/patch_embed.cs.spv",     _gn)) return false;
		if (!_LoadKernelIn(_gnPEB,  "shaders/patch_embed_bwd.cs.spv", _gn)) return false;
		if (!_LoadKernelIn(_gnCtx,  "shaders/ctx_embed.cs.spv",       _gn)) return false;
		if (!_LoadKernelIn(_gnCtxB, "shaders/ctx_embed_bwd.cs.spv",   _gn)) return false;
		if (!_LoadKernelIn(_gnGemm, "shaders/gemm.cs.spv",            _gn)) return false;
		if (!_LoadKernelIn(_gnSoft, "shaders/softmax.cs.spv",         _gn)) return false;
		if (!_LoadKernelIn(_gnSoftB, "shaders/softmax_bwd.cs.spv",    _gn)) return false;
		if (!_LoadKernelIn(_gnRelu,  "shaders/relu.cs.spv",            _gn)) return false;
		if (!_LoadKernelIn(_gnReluB, "shaders/relu_bwd.cs.spv",        _gn)) return false;
		if (!_LoadKernelIn(_gnSub,  "shaders/sub.cs.spv",             _gn)) return false;
		if (!_LoadKernelIn(_gnAdam, "shaders/adamw.cs.spv",           _gn)) return false;

		if (!_InitGenWeights()) return false;

		LogA("\n[ml] ✍️ **D2-b 생성 경로** — 프레임 → 캡션 바이트를 **이어서 생성**한다\n"
			"[ml]   조건: 프레임 → 8×8 패치 → 🔭**어텐션+풀링**(1×%u) → Wc → cw · 역사: ctx_embed(창 %u) → Wh\n"
			"[ml]   어휘 %u(**256 = \"끝\"** — 길이를 어휘 안에 담는다) · 캡션 학습 %u / 시험 %u · %u바이트\n"
			"[ml]   ★ 새 커널 0개 — 조건 브로드캐스트도 `onesT · cw` gemm + `beta=1` 이다\n"
			"[ml]   🔁 **두 팔**: 티쳐포싱만 vs **티쳐포싱 + 자기학습**(둘 다 비선형 은닉 %u · 드롭 p=%.2f)\n"
			"[ml]      자기학습 = 라운드 %u × 캡션 %u × 샘플 %u → **실행 채점** → 최선을 타깃으로\n"
			"[ml]      ⚠️ 채점 %.2f 미달이면 건너뛴다(함정 11) · **정답 캡션을 안 쓴다**\n",
			kGnD, kGnCtx, kGnVoc, kGnTrain, kGnEval, _gnTotal, kGnHid, (double)_GnDropP(1),
			kGnRounds, kGnSelfCaps, kGnBoN, (double)kGnSelfMin);
		return true;
	}

	// ✍️ 팔마다 가중치·모멘트를 **처음부터** 다시 잡는다(같은 씨앗 = 공정한 비교).
	bool _InitGenWeights()
	{
		MLPatchEmbedParams r;
		r.frameW = kGnW; r.frameH = kGnH; r.patchK = kGnK; r.dim = kGnD;
		const uint32 P = r.Patches(), cRow = P * kGnD;
		//   ⚠️ **팬인에 맞춘다.** 🔭 조건 벡터가 `1×D` 로 줄어 `Wc` 팬인이 `D = 16` 이다.
		SeedRand(MLEpisodeGen::ScrambleSeed(5151u));
		Array<float> slot, pos, csl, wh, wc;
		slot.Reset((uint64)r.SlotRows() * kGnD);
		for (uint64 i = 0; i < slot.Count(); ++i)
			slot.Data()[i] = ((float)RandInt(0, 2001) * 0.001f - 1.0f) * 0.02f;
		pos.Reset((uint64)P * kGnD);
		for (uint64 i = 0; i < pos.Count(); ++i)
			pos.Data()[i] = ((float)RandInt(0, 2001) * 0.001f - 1.0f) * 0.02f;
		csl.Reset((uint64)kGnCtx * kGnVoc * kGnD);
		for (uint64 i = 0; i < csl.Count(); ++i)
			csl.Data()[i] = ((float)RandInt(0, 2001) * 0.001f - 1.0f) * 0.02f;
		wh.Reset((uint64)kGnD * kGnVoc);
		for (uint64 i = 0; i < wh.Count(); ++i)
			wh.Data()[i] = ((float)RandInt(0, 2001) * 0.001f - 1.0f) * (0.4f / (float)kGnD);
		wc.Reset((uint64)kGnD * kGnVoc);
		for (uint64 i = 0; i < wc.Count(); ++i)
			wc.Data()[i] = ((float)RandInt(0, 2001) * 0.001f - 1.0f) * (0.4f / (float)kGnD);
		// 🔭 `Wq/Wk/Wv` — **작게 시작하는 것이 설계다**(D2-a 와 같은 근거): `S ≈ 0` → `A ≈ 균등`
		//   → `O ≈ patch + 평균(V)` 이라 **평균풀링 조건에서 출발**하고, 이득은 관계를 배운 것이 된다.
		Array<float> wq, wk2, wv;
		const float sa = Sqrt(1.0f / (float)kGnD);
		wq.Reset((uint64)kGnD * kGnD);  wk2.Reset((uint64)kGnD * kGnD);  wv.Reset((uint64)kGnD * kGnD);
		for (uint64 i = 0; i < wq.Count(); ++i)
			wq.Data()[i] = ((float)RandInt(0, 2001) * 0.001f - 1.0f) * sa;
		for (uint64 i = 0; i < wk2.Count(); ++i)
			wk2.Data()[i] = ((float)RandInt(0, 2001) * 0.001f - 1.0f) * sa;
		for (uint64 i = 0; i < wv.Count(); ++i)
			wv.Data()[i] = ((float)RandInt(0, 2001) * 0.001f - 1.0f) * sa;

		// 🔀 비선형 머리 — **He 초기화**(`sqrt(2/fanIn)`): D1′ 에서 이것 없이는 2층이 안 배웠다.
		Array<float> w1, w2, wc1;
		w1.Reset((uint64)kGnD * kGnHid);
		const float s1 = Sqrt(2.0f / (float)kGnD);
		for (uint64 i = 0; i < w1.Count(); ++i)
			w1.Data()[i] = ((float)RandInt(0, 2001) * 0.001f - 1.0f) * s1;
		wc1.Reset((uint64)kGnD * kGnHid);
		for (uint64 i = 0; i < wc1.Count(); ++i)
			wc1.Data()[i] = ((float)RandInt(0, 2001) * 0.001f - 1.0f) * s1;
		w2.Reset((uint64)kGnHid * kGnVoc);
		const float s2b = Sqrt(2.0f / (float)kGnHid);
		for (uint64 i = 0; i < w2.Count(); ++i)
			w2.Data()[i] = ((float)RandInt(0, 2001) * 0.001f - 1.0f) * s2b;

		if (!_gn.Write(_tGnSlot, slot) || !_gn.Write(_tGnPos, pos)
			|| !_gn.Write(_tGnCSlot, csl)
			|| !_gn.Write(_tGnWh, wh) || !_gn.Write(_tGnWc, wc)
			|| !_gn.Write(_tGnWq, wq) || !_gn.Write(_tGnWk, wk2)
			|| !_gn.Write(_tGnWv, wv)
			|| !_gn.Write(_tGnW1, w1) || !_gn.Write(_tGnW2, w2)
			|| !_gn.Write(_tGnWc1, wc1))
		{ LogA("[ml] 생성: 가중치 업로드 실패\n"); return false; }
		// ⚠️⚠️ **모멘트를 0 으로 되돌린다** — 앞 팔의 관성이 남으면 팔끼리 비교가 안 되고,
		//   그 증상은 "뒤 팔이 더 잘 배운다" 로만 보여서 데이터 버그로 안 읽힌다(P2-b1 의 그 교훈).
		const MLTensor* zs[22] = { &_tGnMS, &_tGnVS, &_tGnMP, &_tGnVP, &_tGnMC, &_tGnVC,
			&_tGnMWh, &_tGnVWh, &_tGnMWc, &_tGnVWc,
			&_tGnMWq, &_tGnVWq, &_tGnMWk, &_tGnVWk, &_tGnMWv, &_tGnVWv,
			&_tGnMW1, &_tGnVW1, &_tGnMW2, &_tGnVW2, &_tGnMWc1, &_tGnVWc1 };
		for (int i = 0; i < 22; ++i) if (!_ZeroTensorIn(_gn, *zs[i]))
		{ LogA("[ml] 생성: 모멘트 초기화 실패\n"); return false; }
		return true;
	}

	// ✍️ **D2-b 단계 기계** — 0 셋업 · 1 학습 · 2 판정.
	void _TickGen()
	{
		if (_gnStage >= 4 && _gnStage != 5) return;

		if (_gnStage == 0)
		{
			_gnStage = 1;
			if (!_SetupGen()) { _gnStage = 3; return; }
			return;   // ⚠️ 다음 프레임부터 학습(G′ 와 무관하지만 셋업 프레임을 비운다)
		}

		if (_gnStage == 1)
		{
			// ★ 손실은 지난 프레임의 `probs` 로 본다(G′) — "돌고 있나" 만 본다.
			if (_gnLastCap >= 0 && ((_gnStep % 400) == 0 || _gnStep >= kGnSteps))
			{
				Bytes bp;
				const uint32 ln = _gnLen.Data()[(uint32)_gnLastCap], T = ln + 1u;
				if (ln > 0u && _gn.Read(_tGnProb, bp)
					&& bp.GetSize() >= (uint64)T * kGnVoc * sizeof(float))
				{
					const float* pr = (const float*)bp.GetData();
					const uint32 st = _gnStart.Data()[(uint32)_gnLastCap];
					float ce = 0.0f;
					for (uint32 t = 0; t < T; ++t)
					{
						const uint32 v = (t < ln) ? (uint32)_gnBytes.Data()[st + 1u + t] : 256u;
						ce += _CeOne(pr + (uint64)t * kGnVoc, (int)v);
					}
					_gnLoss[_gnArm] = ce / (float)T;
					LogA("[ml]   step %4d  loss %.6f nat/바이트 (캡션 1개 — 흔들린다)\n",
						_gnStep, (double)_gnLoss[_gnArm]);
				}
			}
			if (_gnStep >= kGnSteps)
			{
				// 🔁 **자기학습 팔이면 여기서 라운드로 넘어간다**(티쳐포싱만 팔은 바로 판정으로).
				if (_GnSelf(_gnArm))
				{
					_gnStage = 5;
					_gnRound = 0; _gnSelfStep = 0; _gnSelfN = 0;
					LogA("\n[ml] 🔁 **자기학습 시작** — 정답 캡션을 **안 쓴다**"
						"(타깃이 전부 모델 자신의 출력이다)\n");
					return;
				}
				// ★ **배관 검산용 forward 를 따로 한 번 돌린다** — 학습 스텝은 forward 뒤에
				//   AdamW 를 돌리므로 그 로짓은 **회수할 가중치가 만든 것이 아니다**(실측으로 밟았다).
				_gnStage = 2;
				_gnPlumbCap = 0;
				if (!_DispatchGenFwd((uint32)_gnPlumbCap)) { _gnStage = 4; return; }
				return;   // ⚠️ 회수는 다음 프레임(G′)
			}
			for (int k = 0; k < kGnPerFrame && _gnStep < kGnSteps; ++k)
			{
				const uint32 cap = (uint32)(_gnStep % (int)kGnTrain);
				if (!_DispatchGenStep(cap)) { _gnStage = 4; return; }
				_gnLastCap = (int)cap;
				_gnStep++;
			}
			return;
		}

		// ── 5: 🔁 자기학습 라운드 ──
		if (_gnStage == 5)
		{
			if (_gnSelfStep == 0)
			{
				if (_gnRound >= (int)kGnRounds)
				{
					LogA("[ml]   🔁 자기학습 끝 — 채택 %u/%u 캡션(%.0f%%) · 평균 채점 %.3f\n",
						_gnSelfKept, _gnSelfTried,
						(_gnSelfTried > 0u) ? (100.0 * (double)_gnSelfKept / (double)_gnSelfTried) : 0.0,
						(double)_gnSelfScore);
					_gnStage = 2;
					_gnPlumbCap = 0;
					if (!_DispatchGenFwd((uint32)_gnPlumbCap)) { _gnStage = 4; return; }
					return;   // ⚠️ 회수는 다음 프레임(G′)
				}
				if (!_GnCollectRound()) { _gnStage = 4; return; }
				if (_gnSelfN == 0u) { _gnRound++; return; }   // 이 라운드는 건질 것이 없었다
			}
			// ★ 라운드의 타깃들로 GPU 티쳐포싱 — **타깃만 자기 것**이고 나머지는 전부 같다.
			for (int k = 0; k < kGnPerFrame && _gnSelfStep < (int)_gnSelfN; ++k)
			{
				if (!_DispatchGenSelfStep((uint32)_gnSelfStep)) { _gnStage = 4; return; }
				_gnSelfStep++;
				_gnStep++;   // ⚠️ AdamW 의 편향보정 스텝을 이어서 센다
			}
			if (_gnSelfStep >= (int)_gnSelfN) { _gnRound++; _gnSelfStep = 0; }
			return;
		}

		if (_gnStage == 2)
		{
			_JudgeGen();
			// 🕳️ 팔을 바꿔 **같은 데이터·같은 씨앗·같은 스텝**으로 처음부터 다시 돈다.
			if (_gnArm + 1 < kGnArms)
			{
				_gnArm++;
				_gnStep = 0;
				_gnLastCap = -1;
				_gnPlumbCap = -1;
				if (!_InitGenWeights()) { _gnStage = 4; return; }
				_gnRound = 0; _gnSelfStep = 0; _gnSelfN = 0;
				_gnSelfKept = 0; _gnSelfTried = 0; _gnSelfScore = 0.0f;
				LogA("\n[ml] 🔁 ── **%s** 로 다시 돈다\n",
					_GnSelf(_gnArm) ? "티쳐포싱 + 자기학습" : "티쳐포싱만");
				_gnStage = 1;
				return;
			}
			_gnStage = 3;
			_JudgeGenAll();
			_gnStage = 4;
			return;
		}
		_gnStage = 4;
	}

	// ✍️🖨️ **CPU 생성** — 가중치를 회수해 한 바이트씩 이어서 낸다(argmax).
	//   ★ **왜 CPU 인가**: ㉠ G′ 를 안 문다 ㉡ CPU 레퍼런스가 **이미 다 있다**
	//     ㉢ 그래서 **GPU forward 와 오차 0 으로 검산**할 수 있다(전부 곱덧이다).
	//   ⚠️ 학습과 **글자 그대로 같은 식**이어야 한다 — 어긋나면 함정 1(생성/학습 불일치)이고
	//     증상이 "생성이 이상하다" 라서 원인과 안 닮는다.
	//   ⚠️⚠️ `frame` 은 **인자로 받는다** — 섞음 대조군이 *다른 캡션의 프레임*을 넣기 때문이다.
	//   ⚠️ 출력은 **`Array<uint8>`** 다 — `Bytes` 는 스트림 API 라 한 바이트씩 붙이기에 안 맞고,
	//     그리고 문자열을 `String::AppendFormat("%c", …)` 로 조립하면 **한글이 통째로 사라진다**(함정 22).
	// 🔭 **CPU 조건 경로** — GPU forward 와 **글자 그대로 같은 식**(생성과 배관 검산이 **공유**한다 —
	//   두 벌로 적으면 반드시 갈린다). ⚠️ 누산 순서까지 GPU gemm 과 같다(k 오름차순 · 잔차는 복사 뒤
	//   `beta=1` 누산 · 풀링은 `1/P` 를 **곱하면서** 더한다).
	void _GnCondCpu(const float* frame, const Array<float>& slot, const Array<float>& pos,
		const Array<float>& wq, const Array<float>& wk, const Array<float>& wv,
		const Array<float>& wc, const Array<float>& wc1,
		Array<float>& outCw, Array<float>& outCwH) const
	{
		MLPatchEmbedParams r;
		r.frameW = kGnW; r.frameH = kGnH; r.patchK = kGnK; r.dim = kGnD;
		const uint32 P = r.Patches();
		Array<float> patch, q, k, v, sc, a, o, pool;
		patch.Reset((uint64)P * kGnD);
		MLPatchEmbedCpu(frame, slot.Data(), pos.Data(), patch.Data(), kGnW, kGnH, kGnK, kGnD);
		q.Reset((uint64)P * kGnD);  k.Reset((uint64)P * kGnD);  v.Reset((uint64)P * kGnD);
		MLGemmCpuT(patch.Data(), wq.Data(), q.Data(), P, kGnD, kGnD, false, false);
		MLGemmCpuT(patch.Data(), wk.Data(), k.Data(), P, kGnD, kGnD, false, false);
		MLGemmCpuT(patch.Data(), wv.Data(), v.Data(), P, kGnD, kGnD, false, false);
		sc.Reset((uint64)P * P);
		MLGemmCpuT(q.Data(), k.Data(), sc.Data(), P, P, kGnD, false, true);
		a.Reset((uint64)P * P);
		MLSoftmaxCpu(sc.Data(), a.Data(), P, P, _GnAttnScale());
		// O = patch + A·V — GPU 와 같은 순서(복사 뒤 beta=1 누산).
		o.Reset((uint64)P * kGnD);
		for (uint32 i = 0; i < P * kGnD; ++i) o.Data()[i] = patch.Data()[i];
		MLGemmCpuT(a.Data(), v.Data(), o.Data(), P, kGnD, P, false, false, 1.0f);
		// pool = Σ_p (1/P)·O[p] — ⚠️ GPU gemm 과 같은 식(합친 뒤 나누지 않는다 — 부동소수가 갈린다).
		pool.Reset(kGnD);
		const float invP = 1.0f / (float)P;
		for (uint32 d = 0; d < kGnD; ++d)
		{
			float acc = 0.0f;
			for (uint32 pi = 0; pi < P; ++pi) acc += invP * o.Data()[(uint64)pi * kGnD + d];
			pool.Data()[d] = acc;
		}
		outCw.Reset(kGnVoc);
		MLGemmCpuT(pool.Data(), wc.Data(), outCw.Data(), 1u, kGnVoc, kGnD, false, false);
		// 🔀 비선형 팔의 조건→은닉 투영(선형 팔은 안 쓴다 — 계산은 싸다).
		outCwH.Reset(kGnHid);
		MLGemmCpuT(pool.Data(), wc1.Data(), outCwH.Data(), 1u, kGnHid, kGnD, false, false);
	}

	void _GenDecode(const float* frame, const Array<float>& slot, const Array<float>& pos,
		const Array<float>& csl, const Array<float>& wh,
		const Array<float>& wq, const Array<float>& wk, const Array<float>& wv,
		const Array<float>& wc, const Array<float>& wc1,
		const Array<float>& w1, const Array<float>& w2, Array<uint8>& out,
		float temp = 0.0f, uint32 sampleId = 0u) const
	{
		// 🎲 `temp > 0` 이면 **확률 추출**, `0` 이면 argmax(기존 동작 그대로).
		// 조건 — 🔭 어텐션+풀링(GPU 와 같은 헬퍼)
		Array<float> cw, cwH;
		_GnCondCpu(frame, slot, pos, wq, wk, wv, wc, wc1, cw, cwH);

		// 한 바이트씩 — ⚠️ 창이 **지금까지 낸 것**에서 끝난다(인과적).
		//   ★ **학습과 글자 그대로 같은 정렬**이다: 시퀀스가 `[BOS, 낸 것들…]` 이고
		//     `h[마지막]` 이 **다음 바이트**를 낸다. ⇒ 첫 바이트는 `[BOS]` 만 보고 낸다(학습에 그 자리가 있다).
		Array<float> gen, h, logit, seq;
		out.Reset(0);
		for (uint32 step = 0; step + 1u < kGnMaxLen; ++step)
		{
			const uint32 rows = 1u + (uint32)gen.Count();   // BOS + 지금까지
			seq.Reset(rows);
			seq.Data()[0] = 0.0f;                           // BOS
			for (uint32 i = 0; i + 1u < rows; ++i) seq.Data()[i + 1u] = gen.Data()[i];
			h.Reset((uint64)rows * kGnD);
			MLCtxEmbedCpu(seq.Data(), csl.Data(), h.Data(), rows, kGnCtx, kGnD);
			const uint32 tLast = rows - 1u;
			logit.Reset(kGnVoc);
			int arg = 0;
			bool haveLogits = true;
			if (_GnNonlin(_gnArm))
			{
				// 🔀 `hid = relu(h·W1 + cwHid)` → `logits = hid·W2` (GPU 와 글자 그대로 같은 식)
				Array<float> hp, ha;
				hp.Reset(kGnHid);
				MLGemmCpuT(h.Data() + (uint64)tLast * kGnD, w1.Data(), hp.Data(),
					1u, kGnHid, kGnD, false, false);
				for (uint32 i = 0; i < kGnHid; ++i) hp.Data()[i] += cwH.Data()[i];
				ha.Reset(kGnHid);
				MLReluCpu(hp.Data(), ha.Data(), kGnHid);
				MLGemmCpuT(ha.Data(), w2.Data(), logit.Data(), 1u, kGnVoc, kGnHid, false, false);
				for (uint32 v = 0; v < kGnVoc; ++v)
					if (logit.Data()[v] > logit.Data()[arg]) arg = (int)v;
			}
			else
			{
				MLGemmCpuT(h.Data() + (uint64)tLast * kGnD, wh.Data(), logit.Data(),
					1u, kGnVoc, kGnD, false, false);
				for (uint32 v = 0; v < kGnVoc; ++v)
				{
					logit.Data()[v] += cw.Data()[v];
					if (logit.Data()[v] > logit.Data()[arg]) arg = (int)v;
				}
			}
			// 🎲 온도가 있으면 로짓에서 뽑는다(argmax 를 버린다).
			if (temp > 0.0f && haveLogits)
			{
				// 안정화(행 최댓값) → exp → 누적합에서 추출. ⚠️ CPU softmax 와 같은 순서.
				float mx = logit.Data()[0];
				for (uint32 v = 1; v < kGnVoc; ++v) if (logit.Data()[v] > mx) mx = logit.Data()[v];
				float sum = 0.0f;
				for (uint32 v = 0; v < kGnVoc; ++v)
				{
					const float e = Exp((logit.Data()[v] - mx) / temp);
					logit.Data()[v] = e; sum += e;
				}
				const uint32 hh = _GnHash(sampleId, step, (uint32)out.Count() + 1u);
				const float r = ((float)(hh & 0xFFFFFFu) / 16777216.0f) * sum;
				float acc = 0.0f; arg = (int)kGnVoc - 1;
				for (uint32 v = 0; v < kGnVoc; ++v)
				{ acc += logit.Data()[v]; if (r <= acc) { arg = (int)v; break; } }
			}
			if (arg == 256) break;                       // "끝"
			out.Add((uint8)arg);
			gen.Add((float)arg);
		}
	}

	// ✍️ **캡션 하나의 티쳐포싱 스텝.** ★ 배치 1 이라 누적이 없고 전부 "쓴다" 로 유지된다(결정성).
	//   ⚠️⚠️ **인과성이 이 함수의 유일한 불변식이다**(함정 1): `ctx_embed` 의 창이 `t` 에서 **끝나고**
	//     정답은 `byte[t+1]` 이다. 미래를 보면 생성 시점과 어긋나고 증상이 원인과 안 닮는다.
	// 🔁 **라운드 수집** — 가중치를 한 번 회수해 캡션마다 `N` 개 시도를 만들고
	//   **실행 채점으로 최선을 골라** 타깃으로 올린다. ⚠️ 문턱 미달은 **버린다**(함정 11).
	bool _GnCollectRound()
	{
		MLPatchEmbedParams r;
		r.frameW = kGnW; r.frameH = kGnH; r.patchK = kGnK; r.dim = kGnD;
		const uint32 plane = kGnW * kGnH;

		// ① 가중치 회수 — **라운드당 한 번**(매 스텝은 감당이 안 된다).
		Bytes bS, bP2, bC, bWh, bWc, bWq, bWk, bWv, bW1, bW2, bWc1;
		if (!_gn.Read(_tGnSlot, bS) || !_gn.Read(_tGnPos, bP2) || !_gn.Read(_tGnCSlot, bC)
			|| !_gn.Read(_tGnWh, bWh) || !_gn.Read(_tGnWc, bWc)
			|| !_gn.Read(_tGnWq, bWq) || !_gn.Read(_tGnWk, bWk) || !_gn.Read(_tGnWv, bWv)
			|| !_gn.Read(_tGnW1, bW1) || !_gn.Read(_tGnW2, bW2) || !_gn.Read(_tGnWc1, bWc1))
		{ LogA("[ml] 자기학습: 가중치 회수 실패\n"); return false; }
		Array<float> slot, pos, csl, wh, wc, wq, wk, wv, w1, w2, wc1;
		_CopyF(bS, slot);  _CopyF(bP2, pos);  _CopyF(bC, csl);
		_CopyF(bWh, wh);   _CopyF(bWc, wc);
		_CopyF(bWq, wq);   _CopyF(bWk, wk);   _CopyF(bWv, wv);
		_CopyF(bW1, w1);   _CopyF(bW2, w2);   _CopyF(bWc1, wc1);

		// ② 캡션마다 `N` 개 시도 → 실행 채점 → 최선을 타깃으로.
		//   ★ 라운드마다 **다른 캡션 묶음**을 본다(학습 집합 전체를 덮는다).
		Array<float> tok;
		Array<float> one;
		tok.Reset((uint64)kGnSelfCaps * kGnMaxLen);
		one.Reset((uint64)kGnSelfCaps * kGnMaxLen * kGnVoc);
		for (uint64 i = 0; i < one.Count(); ++i) one.Data()[i] = 0.0f;
		_gnSelfCap.Reset(0); _gnSelfStart.Reset(0); _gnSelfLen.Reset(0);
		uint32 cursor = 0;
		float scoreSum = 0.0f;

		for (uint32 j = 0; j < kGnSelfCaps; ++j)
		{
			const uint32 cap = ((uint32)_gnRound * kGnSelfCaps + j) % kGnTrain;
			MLFrameFacts fT;
			if (!_RenderSceneFacts(_gnScenes.Data()[cap], fT)) continue;

			// 🧠 **지시된 수정으로 타깃을 만든다**(랜덤 best-of-N 이 아니다 — 0.660 vs 0.855).
			//   ★ 타깃 캡션은 **첫 시도의 문법**을 쓰고 **낱말만** 채점이 지시한 대로 바꾼다.
			//     ⇒ **문법이 모델 자신의 출력에서 오므로** 함정 47(*"채점기가 안 보는 것은 흘러내린다"*)이
			//       동시에 막힌다 — 채점기에 문법 항을 넣는 대신 **문법을 원래 잘 하던 쪽에 맡긴다.**
			Array<uint8> best, firstCap;
			MLScene bestScene, firstScene;
			const float dirSc = _GnDirected(cap, slot, pos, csl, wh, wq, wk, wv, wc, wc1, w1, w2,
				kGnBoN, (uint32)_gnRound * 100003u + cap, bestScene, &firstCap, &firstScene);
			float bestSc = -1.0f;
			if (firstCap.Count() > 0u && _IsValidUtf8(firstCap))
			{
				// ★ 축마다 **바뀐 것만** 낱말을 갈아 끼운다(안 바뀐 축은 손대지 않는다).
				Array<uint8> tgt = firstCap;
				bool ok = true;
				for (int ax = 0; ax < 6 && ok; ++ax)
				{
					const int a0 = _AxisGet(firstScene, ax), a1 = _AxisGet(bestScene, ax);
					if (a0 == a1) continue;
					if (!_ReplaceWord(tgt, _WordOfAxis(firstScene, ax), _WordOfAxis(bestScene, ax)))
						ok = false;   // 그 낱말이 캡션에 없다 ⇒ 이 타깃은 만들 수 없다
				}
				// ⚠️ **문법 항**(함정 47 의 조치): 타깃이 유효한 UTF-8 이어야 한다.
				if (ok && _IsValidUtf8(tgt))
				{
					// ⚠️ 치환한 캡션을 **다시 채점**한다 — 치환이 뜻을 정말 바꿨는지는 실행만이 안다.
					MLScene st2; MLFrameFacts ft2;
					_ParseCaption(tgt, st2);
					if (_RenderSceneFacts(st2, ft2))
					{ bestSc = _FactScore(fT, ft2); best = tgt; }
				}
			}
			(void)dirSc;
			_gnSelfTried++;
			// ⚠️ **문턱 미달은 버린다** — 나쁜 시도를 강화하지 않는다(함정 11).
			if (bestSc < kGnSelfMin || best.Count() == 0u) continue;
			if (cursor + best.Count() + 2u > kGnSelfCaps * kGnMaxLen) break;
			_gnSelfKept++;
			scoreSum += bestSc;

			// `[BOS, b0 … b_{L−1}]` 로 올린다(코퍼스와 **같은 형식** — 정렬이 어긋나면 함정 40 이다).
			const uint32 st = cursor;
			tok.Data()[cursor++] = 0.0f;                       // BOS
			for (uint32 t = 0; t < (uint32)best.Count(); ++t)
				tok.Data()[cursor++] = (float)best.Data()[t];
			const uint32 ln = (uint32)best.Count();
			for (uint32 t = 0; t <= ln; ++t)
			{
				const uint32 v = (t < ln) ? (uint32)best.Data()[t] : 256u;
				one.Data()[(uint64)(st + t) * kGnVoc + v] = 1.0f;
			}
			_gnSelfCap.Add(cap); _gnSelfStart.Add(st); _gnSelfLen.Add(ln);
		}
		_gnSelfN = (uint32)_gnSelfCap.Count();
		// ⚠️⚠️ **분모는 "이번 라운드에 채택한 수" 다.** 실측으로 밟았다: `_gnSelfKept`(전체 누적)로
		//   나눠서 라운드마다 `0.821 → 0.083` 으로 **떨어지는 것처럼** 찍혔고, 그것을 하마터면
		//   *"자기학습이 무너진다"* 로 읽을 뻔했다(손으로 되짚으니 실제는 0.82 → 0.70 이었다).
		//   ★ 판정 규칙: ***"비율을 찍을 때 분자와 분모의 범위가 같은지 본다."***
		_gnSelfScore = (_gnSelfN > 0u) ? (scoreSum / (float)_gnSelfN) : 0.0f;
		if (!_gn.Write(_tGnSelfTok, tok) || !_gn.Write(_tGnSelfOne, one))
		{ LogA("[ml] 자기학습: 타깃 업로드 실패\n"); return false; }
		LogA("[ml]   🔁 라운드 %d — 시도 %u캡션 · **채택 %u개**(문턱 %.2f) · 평균 채점 %.3f\n",
			_gnRound, kGnSelfCaps, _gnSelfN, (double)kGnSelfMin, (double)_gnSelfScore);
		return true;
	}

	// 🔁 **자기 타깃으로 한 스텝** — 코퍼스 대신 `_tGnSelfTok/_tGnSelfOne` 를 쓴다.
	//   ★ 그 밖의 모든 것(조건 경로 · 창 · 머리 · 옵티마이저)은 **티쳐포싱과 똑같다** —
	//     달라지는 것은 **타깃이 어디서 왔나**뿐이다(그것이 이 실험의 손잡이다).
	bool _DispatchGenSelfStep(uint32 idx)
	{
		if (idx >= _gnSelfN) return true;
		_gnSelfBytesOff = _tGnSelfTok.offset + _gnSelfStart.Data()[idx];
		_gnSelfOneOff = _tGnSelfOne.offset + _gnSelfStart.Data()[idx] * kGnVoc;
		_gnSelfLenCur = _gnSelfLen.Data()[idx];
		_gnSelfOn = true;
		const bool ok = _DispatchGenStep(_gnSelfCap.Data()[idx]);
		_gnSelfOn = false;
		return ok;
	}
	// ★ 자기 타깃을 쓰는 동안만 켜지는 조준기(스텝 함수를 두 벌로 만들지 않으려는 것).
	bool   _gnSelfOn = false;
	uint32 _gnSelfBytesOff = 0, _gnSelfOneOff = 0, _gnSelfLenCur = 0;

	// ✍️ **forward 만** — ★ 배관 검산이 **그 로짓을 만든 가중치**로 재려면 이것이 따로 있어야 한다.
	//   ⚠️⚠️ 실측으로 밟았다: 학습 스텝은 forward **뒤에 AdamW** 를 돌리므로, 학습이 끝난 뒤 회수한
	//     가중치는 `_tGnLogit` 을 만든 그것이 **아니다** ⇒ 멀쩡한 배관이 오차 1.8e-02 로 찍혔다.
	//   ★ 판정 규칙: ***"CPU/GPU 를 견줄 때는 그 사이에 파라미터가 안 움직였는지 먼저 확인한다."***
	bool _DispatchGenFwd(uint32 cap, bool drop = false)
	{
		MLPatchEmbedParams r;
		r.frameW = kGnW; r.frameH = kGnH; r.patchK = kGnK; r.dim = kGnD;
		const uint32 P = r.Patches(), plane = kGnW * kGnH, cRow = P * kGnD;
		// 🔁 자기학습이면 **타깃 열이 다른 곳**에 있다(그 외는 전부 같다).
		const uint32 st = _gnSelfOn ? 0u : _gnStart.Data()[cap];
		const uint32 T = (_gnSelfOn ? _gnSelfLenCur : _gnLen.Data()[cap]) + 1u;   // ★ +1 = BOS 자리
		const uint32 tokBase = _gnSelfOn ? _gnSelfBytesOff : (_tGnBytes.offset + st);
		if (T <= 1u) return true;

		// ① 조건 — 프레임 → 패치
		MLPatchEmbedParams f = r;
		f.frameOff = _tGnFrames.offset + cap * plane;
		f.aOff = _tGnSlot.offset; f.bOff = _tGnPos.offset; f.cOff = _tGnPatch.offset;
		if (!_gnPE.Dispatch(kGnD, P, 1u, &f, (uint32)sizeof(f))) return _Fail("gen patch");

		// ② 🔭 **어텐션+풀링 조건** — D2-a 가 검증한 블록 그대로(잔차 포함 · 새 커널 0개).
		//   ②a Q,K,V = patch·W*
		{
			const MLTensor* srcW[3] = { &_tGnWq, &_tGnWk, &_tGnWv };
			const MLTensor* dstX[3] = { &_tGnQ,  &_tGnK,  &_tGnV  };
			for (int t2 = 0; t2 < 3; ++t2)
			{
				MLGemmParams g;
				g.aOff = _tGnPatch.offset; g.bOff = srcW[t2]->offset; g.cOff = dstX[t2]->offset;
				g.M = P; g.N = kGnD; g.K = kGnD;
				if (!_gnGemm.Dispatch(kGnD, P, 1u, &g, (uint32)sizeof(g))) return _Fail("gen qkv");
			}
		}
		//   ②b S = Q·Kᵀ  ·  ②c A = softmax(S · 1/√D)
		{
			MLGemmParams gs;
			gs.aOff = _tGnQ.offset; gs.bOff = _tGnK.offset; gs.cOff = _tGnS.offset;
			gs.M = P; gs.N = P; gs.K = kGnD; gs.transB = 1;
			if (!_gnGemm.Dispatch(P, P, 1u, &gs, (uint32)sizeof(gs))) return _Fail("gen scores");
			MLSoftmaxParams sa;
			sa.inOff = _tGnS.offset; sa.outOff = _tGnA.offset;
			sa.rows = P; sa.cols = P; sa.scale = _GnAttnScale();
			if (!_gnSoft.Dispatch(P, 1u, 1u, &sa, (uint32)sizeof(sa))) return _Fail("gen attn soft");
		}
		//   ②d O = patch + A·V — **잔차**(D2-a: `A` 가 무너져도 평균 조건으로 돌아갈 길을 남긴다)
		{
			MLGemmParams gr;
			gr.aOff = _tGnPatch.offset; gr.bOff = _tGnEye.offset; gr.cOff = _tGnO.offset;
			gr.M = P; gr.N = kGnD; gr.K = kGnD;
			if (!_gnGemm.Dispatch(kGnD, P, 1u, &gr, (uint32)sizeof(gr))) return _Fail("gen res");
			MLGemmParams go;
			go.aOff = _tGnA.offset; go.bOff = _tGnV.offset; go.cOff = _tGnO.offset;
			go.M = P; go.N = kGnD; go.K = P; go.beta = 1.0f;
			if (!_gnGemm.Dispatch(kGnD, P, 1u, &go, (uint32)sizeof(go))) return _Fail("gen attn out");
		}
		//   ②e pool = (1/P 벡터)·O  ·  ②f cw = pool·Wc — ★ 조건 벡터가 `1×D`(함정 42 의 조치)
		{
			MLGemmParams gp;
			gp.aOff = _tGnPOnes.offset; gp.bOff = _tGnO.offset; gp.cOff = _tGnPool.offset;
			gp.M = 1; gp.N = kGnD; gp.K = P;
			if (!_gnGemm.Dispatch(kGnD, 1u, 1u, &gp, (uint32)sizeof(gp))) return _Fail("gen pool");
			MLGemmParams gc;
			gc.aOff = _tGnPool.offset; gc.bOff = _tGnWc.offset; gc.cOff = _tGnCw.offset;
			gc.M = 1; gc.N = kGnVoc; gc.K = kGnD;
			if (!_gnGemm.Dispatch(kGnVoc, 1u, 1u, &gc, (uint32)sizeof(gc))) return _Fail("gen cw");
			// 🔀 비선형 팔: 조건을 **은닉으로도** 투영한다(거기서 창과 곱셈 상호작용이 생긴다).
			if (_GnNonlin(_gnArm))
			{
				MLGemmParams gch;
				gch.aOff = _tGnPool.offset; gch.bOff = _tGnWc1.offset; gch.cOff = _tGnCwH.offset;
				gch.M = 1; gch.N = kGnHid; gch.K = kGnD;
				if (!_gnGemm.Dispatch(kGnHid, 1u, 1u, &gch, (uint32)sizeof(gch)))
					return _Fail("gen cwHid");
			}
		}

		// ③ 역사 — h = ctx_embed(바이트 창). ⚠️ `tokOff` 가 **이 캡션의 시작**이라 캡션 앞은
		//    커널이 자동으로 `256`("없음")으로 본다 ⇒ 앞 캡션의 문맥이 새지 않는다.
		//   🕳️ **드롭이면 창을 지운다** — `h = 0` 이라 그 스텝은 **조건만으로** 맞혀야 한다.
		if (drop)
		{
			if (!_ZeroTensorIn(_gn, _tGnH)) return _Fail("gen h zero");
		}
		else
		{
			MLCtxEmbedParams e;
			e.tokOff = tokBase; e.aOff = _tGnCSlot.offset; e.bOff = _tGnH.offset;
			e.seqLen = T; e.ctxK = kGnCtx; e.dim = kGnD;
			if (!_gnCtx.Dispatch(kGnD, T, 1u, &e, (uint32)sizeof(e))) return _Fail("gen ctx");
		}

		if (_GnNonlin(_gnArm))
		{
			// 🔀 ④' hpre = h·W1 + onesT·cwHid  →  hact = relu(hpre)  →  logits = hact·W2
			//   ★ 조건(`cwHid`)과 창(`h·W1`)이 **relu 를 함께 통과**한다 ⇒ 자리마다 다른 상호작용.
			//   🕳️ 드롭이면 `h = 0` 이므로 창 항을 건너뛰고 조건만 남긴다(`beta = 0`).
			if (!drop)
			{
				MLGemmParams g1;
				g1.aOff = _tGnH.offset; g1.bOff = _tGnW1.offset; g1.cOff = _tGnHpre.offset;
				g1.M = T; g1.N = kGnHid; g1.K = kGnD;
				if (!_gnGemm.Dispatch(kGnHid, T, 1u, &g1, (uint32)sizeof(g1))) return _Fail("gen h1");
			}
			MLGemmParams gbh;
			gbh.aOff = _tGnOnesT.offset; gbh.bOff = _tGnCwH.offset; gbh.cOff = _tGnHpre.offset;
			gbh.M = T; gbh.N = kGnHid; gbh.K = 1; gbh.beta = drop ? 0.0f : 1.0f;
			if (!_gnGemm.Dispatch(kGnHid, T, 1u, &gbh, (uint32)sizeof(gbh))) return _Fail("gen h1c");

			MLReluParams rl;
			rl.aOff = _tGnHpre.offset; rl.bOff = _tGnHact.offset; rl.count = T * kGnHid;
			if (!_gnRelu.Dispatch(rl.count, 1u, 1u, &rl, (uint32)sizeof(rl))) return _Fail("gen relu");

			MLGemmParams g2;
			g2.aOff = _tGnHact.offset; g2.bOff = _tGnW2.offset; g2.cOff = _tGnLogit.offset;
			g2.M = T; g2.N = kGnVoc; g2.K = kGnHid;
			if (!_gnGemm.Dispatch(kGnVoc, T, 1u, &g2, (uint32)sizeof(g2))) return _Fail("gen logit2");
		}
		else
		{
			// ④ logits = h · Wh                      (beta 0 = 덮어쓴다)
			//   🕳️ 드롭이면 `h = 0` 이라 이 gemm 을 **건너뛰고** ⑤에서 `beta = 0` 으로 덮는다.
			if (!drop)
			{
				MLGemmParams gh;
				gh.aOff = _tGnH.offset; gh.bOff = _tGnWh.offset; gh.cOff = _tGnLogit.offset;
				gh.M = T; gh.N = kGnVoc; gh.K = kGnD;
				if (!_gnGemm.Dispatch(kGnVoc, T, 1u, &gh, (uint32)sizeof(gh))) return _Fail("gen logit h");
			}
			// ⑤ logits += onesT(T×1) · cw(1×257)     ★ **조건 브로드캐스트 = `beta = 1`**
			MLGemmParams gb;
			gb.aOff = _tGnOnesT.offset; gb.bOff = _tGnCw.offset; gb.cOff = _tGnLogit.offset;
			gb.M = T; gb.N = kGnVoc; gb.K = 1; gb.beta = drop ? 0.0f : 1.0f;
			if (!_gnGemm.Dispatch(kGnVoc, T, 1u, &gb, (uint32)sizeof(gb))) return _Fail("gen logit c");
		}

		// ⑥ probs = softmax(logits)  · ⑦ dLogit = probs − onehot
		MLSoftmaxParams sm;
		sm.inOff = _tGnLogit.offset; sm.outOff = _tGnProb.offset; sm.rows = T; sm.cols = kGnVoc;
		if (!_gnSoft.Dispatch(T, 1u, 1u, &sm, (uint32)sizeof(sm))) return _Fail("gen softmax");

		return true;
	}

	bool _DispatchGenStep(uint32 cap)
	{
		// 🕳️ 드롭 여부는 **스텝 번호**로 결정한다(결정적).
		const bool drop = _GnDropped(_gnStep);
		if (!_DispatchGenFwd(cap, drop)) return false;

		MLPatchEmbedParams r;
		r.frameW = kGnW; r.frameH = kGnH; r.patchK = kGnK; r.dim = kGnD;
		const uint32 P = r.Patches(), plane = kGnW * kGnH, cRow = P * kGnD;
		// 🔁 자기학습이면 **타깃 열이 다른 곳**에 있다(그 외는 전부 같다).
		const uint32 st = _gnSelfOn ? 0u : _gnStart.Data()[cap];
		const uint32 T = (_gnSelfOn ? _gnSelfLenCur : _gnLen.Data()[cap]) + 1u;
		const uint32 tokBase = _gnSelfOn ? _gnSelfBytesOff : (_tGnBytes.offset + st);
		if (T <= 1u) return true;

		// ⑦ dLogit = probs − onehot
		MLSubParams sb;
		// 🔁 자기학습이면 **자기 타깃**의 onehot 을 쓴다.
		sb.aOff = _tGnProb.offset;
		sb.bOff = _gnSelfOn ? _gnSelfOneOff : (_tGnOne.offset + st * kGnVoc);
		sb.outOff = _tGnDLogit.offset; sb.count = T * kGnVoc;
		if (!_gnSub.Dispatch(sb.count, 1u, 1u, &sb, (uint32)sizeof(sb))) return _Fail("gen dlogit");

		// ⑧⑨ 머리의 역전파 — 팔에 따라 갈린다.
		//   🕳️ **드롭이면 창 쪽(dW1/dWh · dH)을 건너뛴다** — 제대로 된 드롭아웃은 forward 와
		//     backward 를 **둘 다** 막는다. ⚠️ 그리고 AdamW 에서 그 파라미터도 건너뛴다(안 그러면
		//     지난 스텝의 기울기가 한 번 더 적용된다).
		if (_GnNonlin(_gnArm))
		{
			// dW2 = hactᵀ·dLogit · dHact = dLogit·W2ᵀ · dHpre = relu_bwd(hpre, dHact)
			MLGemmParams gw2;
			gw2.aOff = _tGnHact.offset; gw2.bOff = _tGnDLogit.offset; gw2.cOff = _tGnDW2.offset;
			gw2.M = kGnHid; gw2.N = kGnVoc; gw2.K = T; gw2.transA = 1;
			if (!_gnGemm.Dispatch(kGnVoc, kGnHid, 1u, &gw2, (uint32)sizeof(gw2))) return _Fail("gen dW2");

			MLGemmParams gda;
			gda.aOff = _tGnDLogit.offset; gda.bOff = _tGnW2.offset; gda.cOff = _tGnDHact.offset;
			gda.M = T; gda.N = kGnHid; gda.K = kGnVoc; gda.transB = 1;
			if (!_gnGemm.Dispatch(kGnHid, T, 1u, &gda, (uint32)sizeof(gda))) return _Fail("gen dHact");

			MLReluParams rb;
			rb.aOff = _tGnHpre.offset; rb.bOff = _tGnDHact.offset; rb.cOff = _tGnDHpre.offset;
			rb.count = T * kGnHid;
			if (!_gnReluB.Dispatch(rb.count, 1u, 1u, &rb, (uint32)sizeof(rb)))
				return _Fail("gen relu bwd");

			// dCwHid = onesTᵀ·dHpre  (조건은 모든 자리에 같은 것이 더해졌다 ⇒ 합)
			MLGemmParams gdc2;
			gdc2.aOff = _tGnOnesT.offset; gdc2.bOff = _tGnDHpre.offset; gdc2.cOff = _tGnDCwH.offset;
			gdc2.M = 1; gdc2.N = kGnHid; gdc2.K = T; gdc2.transA = 1;
			if (!_gnGemm.Dispatch(kGnHid, 1u, 1u, &gdc2, (uint32)sizeof(gdc2))) return _Fail("gen dCwH");

			// dWc1 = poolᵀ·dCwHid · dPool += dCwHid·Wc1ᵀ (아래 ⑪에서 `beta` 로 합친다)
			MLGemmParams gwc1;
			gwc1.aOff = _tGnPool.offset; gwc1.bOff = _tGnDCwH.offset; gwc1.cOff = _tGnDWc1.offset;
			gwc1.M = kGnD; gwc1.N = kGnHid; gwc1.K = 1; gwc1.transA = 1;
			if (!_gnGemm.Dispatch(kGnHid, kGnD, 1u, &gwc1, (uint32)sizeof(gwc1))) return _Fail("gen dWc1");

			if (!drop)
			{
				MLGemmParams gw1;
				gw1.aOff = _tGnH.offset; gw1.bOff = _tGnDHpre.offset; gw1.cOff = _tGnDW1.offset;
				gw1.M = kGnD; gw1.N = kGnHid; gw1.K = T; gw1.transA = 1;
				if (!_gnGemm.Dispatch(kGnHid, kGnD, 1u, &gw1, (uint32)sizeof(gw1))) return _Fail("gen dW1");

				MLGemmParams gdh2;
				gdh2.aOff = _tGnDHpre.offset; gdh2.bOff = _tGnW1.offset; gdh2.cOff = _tGnDH.offset;
				gdh2.M = T; gdh2.N = kGnD; gdh2.K = kGnHid; gdh2.transB = 1;
				if (!_gnGemm.Dispatch(kGnD, T, 1u, &gdh2, (uint32)sizeof(gdh2))) return _Fail("gen dH2");
			}
		}
		else if (!drop)
		{
			MLGemmParams gwh;
			gwh.aOff = _tGnH.offset; gwh.bOff = _tGnDLogit.offset; gwh.cOff = _tGnDWh.offset;
			gwh.M = kGnD; gwh.N = kGnVoc; gwh.K = T; gwh.transA = 1;
			if (!_gnGemm.Dispatch(kGnVoc, kGnD, 1u, &gwh, (uint32)sizeof(gwh))) return _Fail("gen dWh");

			MLGemmParams gdh;
			gdh.aOff = _tGnDLogit.offset; gdh.bOff = _tGnWh.offset; gdh.cOff = _tGnDH.offset;
			gdh.M = T; gdh.N = kGnD; gdh.K = kGnVoc; gdh.transB = 1;
			if (!_gnGemm.Dispatch(kGnD, T, 1u, &gdh, (uint32)sizeof(gdh))) return _Fail("gen dH");
		}

		// ⑩ dCw = onesTᵀ · dLogit — ★ 조건은 **모든 자리에 같은 것**이 더해졌으므로 기울기가 **합**이다
		MLGemmParams gdc;
		gdc.aOff = _tGnOnesT.offset; gdc.bOff = _tGnDLogit.offset; gdc.cOff = _tGnDCw.offset;
		gdc.M = 1; gdc.N = kGnVoc; gdc.K = T; gdc.transA = 1;
		if (!_gnGemm.Dispatch(kGnVoc, 1u, 1u, &gdc, (uint32)sizeof(gdc))) return _Fail("gen dCw");

		// ⑪ 🔭 **어텐션 조건의 역전파** — D2-a 와 같은 사슬(전부 gemm + softmax_bwd 하나).
		//   dWc = poolᵀ·dCw  ·  dPool = dCw·Wcᵀ  ·  dO = (1/P 벡터)ᵀ·dPool
		{
			MLGemmParams gwc;
			gwc.aOff = _tGnPool.offset; gwc.bOff = _tGnDCw.offset; gwc.cOff = _tGnDWc.offset;
			gwc.M = kGnD; gwc.N = kGnVoc; gwc.K = 1; gwc.transA = 1;
			if (!_gnGemm.Dispatch(kGnVoc, kGnD, 1u, &gwc, (uint32)sizeof(gwc))) return _Fail("gen dWc");
			MLGemmParams gdp;
			gdp.aOff = _tGnDCw.offset; gdp.bOff = _tGnWc.offset; gdp.cOff = _tGnDPool.offset;
			gdp.M = 1; gdp.N = kGnD; gdp.K = kGnVoc; gdp.transB = 1;
			if (!_gnGemm.Dispatch(kGnD, 1u, 1u, &gdp, (uint32)sizeof(gdp))) return _Fail("gen dPool");
			// 🔀 비선형 팔은 조건이 **두 곳**(출력·은닉)으로 갔으므로 `dPool` 이 **합**이다(`beta = 1`).
			if (_GnNonlin(_gnArm))
			{
				MLGemmParams gdp2;
				gdp2.aOff = _tGnDCwH.offset; gdp2.bOff = _tGnWc1.offset; gdp2.cOff = _tGnDPool.offset;
				gdp2.M = 1; gdp2.N = kGnD; gdp2.K = kGnHid; gdp2.transB = 1; gdp2.beta = 1.0f;
				if (!_gnGemm.Dispatch(kGnD, 1u, 1u, &gdp2, (uint32)sizeof(gdp2)))
					return _Fail("gen dPool2");
			}
			MLGemmParams gdo;
			gdo.aOff = _tGnPOnes.offset; gdo.bOff = _tGnDPool.offset; gdo.cOff = _tGnDO.offset;
			gdo.M = P; gdo.N = kGnD; gdo.K = 1; gdo.transA = 1;
			if (!_gnGemm.Dispatch(kGnD, P, 1u, &gdo, (uint32)sizeof(gdo))) return _Fail("gen dO");
		}
		//   dA = dO·Vᵀ · dV = Aᵀ·dO · dS = softmax_bwd(A, dA)·1/√D · dQ = dS·K · dK = dSᵀ·Q
		{
			MLGemmParams ga;
			ga.aOff = _tGnDO.offset; ga.bOff = _tGnV.offset; ga.cOff = _tGnDA.offset;
			ga.M = P; ga.N = P; ga.K = kGnD; ga.transB = 1;
			if (!_gnGemm.Dispatch(P, P, 1u, &ga, (uint32)sizeof(ga))) return _Fail("gen dA");
			MLGemmParams gv;
			gv.aOff = _tGnA.offset; gv.bOff = _tGnDO.offset; gv.cOff = _tGnDV.offset;
			gv.M = P; gv.N = kGnD; gv.K = P; gv.transA = 1;
			if (!_gnGemm.Dispatch(kGnD, P, 1u, &gv, (uint32)sizeof(gv))) return _Fail("gen dV");
			MLSoftmaxBwdParams sb2;
			sb2.probOff = _tGnA.offset; sb2.dOutOff = _tGnDA.offset; sb2.dInOff = _tGnDS.offset;
			sb2.rows = P; sb2.cols = P; sb2.scale = _GnAttnScale();
			if (!_gnSoftB.Dispatch(P, 1u, 1u, &sb2, (uint32)sizeof(sb2))) return _Fail("gen dS");
			MLGemmParams gq2;
			gq2.aOff = _tGnDS.offset; gq2.bOff = _tGnK.offset; gq2.cOff = _tGnDQ.offset;
			gq2.M = P; gq2.N = kGnD; gq2.K = P;
			if (!_gnGemm.Dispatch(kGnD, P, 1u, &gq2, (uint32)sizeof(gq2))) return _Fail("gen dQ");
			MLGemmParams gk2;
			gk2.aOff = _tGnDS.offset; gk2.bOff = _tGnQ.offset; gk2.cOff = _tGnDK.offset;
			gk2.M = P; gk2.N = kGnD; gk2.K = P; gk2.transA = 1;
			if (!_gnGemm.Dispatch(kGnD, P, 1u, &gk2, (uint32)sizeof(gk2))) return _Fail("gen dK");
		}
		//   dW* = patchᵀ·d*  ·  dPatch = dO(잔차) + dQ·Wqᵀ + dK·Wkᵀ + dV·Wvᵀ (`beta` 누산)
		{
			const MLTensor* dW3[3] = { &_tGnDWq, &_tGnDWk, &_tGnDWv };
			const MLTensor* dX3[3] = { &_tGnDQ,  &_tGnDK,  &_tGnDV  };
			const MLTensor* w3[3]  = { &_tGnWq,  &_tGnWk,  &_tGnWv  };
			for (int t2 = 0; t2 < 3; ++t2)
			{
				MLGemmParams gw3;
				gw3.aOff = _tGnPatch.offset; gw3.bOff = dX3[t2]->offset; gw3.cOff = dW3[t2]->offset;
				gw3.M = kGnD; gw3.N = kGnD; gw3.K = P; gw3.transA = 1;
				if (!_gnGemm.Dispatch(kGnD, kGnD, 1u, &gw3, (uint32)sizeof(gw3)))
					return _Fail("gen dWqkv");
			}
			MLGemmParams gr2;
			gr2.aOff = _tGnDO.offset; gr2.bOff = _tGnEye.offset; gr2.cOff = _tGnDPatch.offset;
			gr2.M = P; gr2.N = kGnD; gr2.K = kGnD;
			if (!_gnGemm.Dispatch(kGnD, P, 1u, &gr2, (uint32)sizeof(gr2))) return _Fail("gen dPatch r");
			for (int t2 = 0; t2 < 3; ++t2)
			{
				MLGemmParams gx;
				gx.aOff = dX3[t2]->offset; gx.bOff = w3[t2]->offset; gx.cOff = _tGnDPatch.offset;
				gx.M = P; gx.N = kGnD; gx.K = kGnD; gx.transB = 1; gx.beta = 1.0f;
				if (!_gnGemm.Dispatch(kGnD, P, 1u, &gx, (uint32)sizeof(gx))) return _Fail("gen dPatch a");
			}
		}

		// ⑬ 표 두 개의 기울기 — **gather**(atomic 없이 결정적으로)
		if (!drop)
		{
			MLCtxEmbedParams eb;
			eb.tokOff = tokBase; eb.aOff = _tGnDH.offset; eb.bOff = _tGnDCSlot.offset;
			eb.seqLen = T; eb.ctxK = kGnCtx; eb.dim = kGnD;
			if (!_gnCtxB.Dispatch(kGnD, eb.SlotRows(), 1u, &eb, (uint32)sizeof(eb)))
				return _Fail("gen dCSlot");
		}

		MLPatchEmbedParams pb = r;
		pb.frameOff = _tGnFrames.offset + cap * plane;
		pb.aOff = _tGnDPatch.offset; pb.bOff = _tGnDSlot.offset;
		if (!_gnPEB.Dispatch(kGnD, pb.SlotRows(), 1u, &pb, (uint32)sizeof(pb)))
			return _Fail("gen dSlot");

		// ⑭ AdamW × 5. ★ `posTable` 의 기울기는 **`dPatch` 그 자체**다(forward 가 그냥 더한다).
		float bc1 = 1.0f, bc2 = 1.0f;
		_BiasCorr(_gnStep + 1, bc1, bc2);
		MLAdamWParams aw;
		aw.lr = _GnLr(); aw.beta1 = kB1; aw.beta2 = kB2; aw.eps = kAdamEps; aw.wd = kWd;
		aw.bc1 = bc1; aw.bc2 = bc2;
		// ★ i=2 는 `CSlot`, i=3 은 **창 쪽 머리**(선형=Wh · 비선형=W1) — 드롭이면 둘 다 기울기가 없다.
		const MLTensor* headW = _GnNonlin(_gnArm) ? &_tGnW1  : &_tGnWh;
		const MLTensor* headD = _GnNonlin(_gnArm) ? &_tGnDW1 : &_tGnDWh;
		const MLTensor* headM = _GnNonlin(_gnArm) ? &_tGnMW1 : &_tGnMWh;
		const MLTensor* headV = _GnNonlin(_gnArm) ? &_tGnVW1 : &_tGnVWh;
		const MLTensor* pp[11] = { &_tGnSlot,  &_tGnPos,    &_tGnCSlot,  headW,   &_tGnWc,
			&_tGnWq,  &_tGnWk,  &_tGnWv,  &_tGnW2,  &_tGnWc1,  &_tGnWh };
		const MLTensor* gg[11] = { &_tGnDSlot, &_tGnDPatch, &_tGnDCSlot, headD,   &_tGnDWc,
			&_tGnDWq, &_tGnDWk, &_tGnDWv, &_tGnDW2, &_tGnDWc1, &_tGnDWh };
		const MLTensor* mm[11] = { &_tGnMS,    &_tGnMP,     &_tGnMC,     headM,   &_tGnMWc,
			&_tGnMWq, &_tGnMWk, &_tGnMWv, &_tGnMW2, &_tGnMWc1, &_tGnMWh };
		const MLTensor* vv[11] = { &_tGnVS,    &_tGnVP,     &_tGnVC,     headV,   &_tGnVWc,
			&_tGnVWq, &_tGnVWk, &_tGnVWv, &_tGnVW2, &_tGnVWc1, &_tGnVWh };
		const int nParam = _GnNonlin(_gnArm) ? 10 : 8;   // 비선형은 W2·Wc1 을 더 밀고 `Wh` 는 안 쓴다
		for (int i = 0; i < nParam; ++i)
		{
			// 🕳️ 드롭이면 `CSlot`(i=2)·창 쪽 머리(i=3) 는 **기울기가 없다** ⇒ 갱신하지 않는다.
			if (drop && (i == 2 || i == 3)) continue;
			MLAdamWParams a2 = aw;
			a2.pOff = pp[i]->offset; a2.gOff = gg[i]->offset;
			a2.mOff = mm[i]->offset; a2.vOff = vv[i]->offset; a2.count = pp[i]->Count();
			if (!_gnAdam.Dispatch(a2.count, 1u, 1u, &a2, (uint32)sizeof(a2)))
				return _Fail("gen adamw");
		}
		return true;
	}

	// ✍️⚖️ **D2-b 판정** — 기준을 **미리 못박았다**(함정 19·21).
	//   ㉠ **배관**: CPU 생성이 GPU forward 와 같은 계산인가 — 같은 캡션의 로짓 **오차 0**
	//   ㉡ **구조**: 생성한 바이트 열이 **유효한 UTF-8** 인가 (≥95%)
	//   ㉢ **접지**: **안 본 장면**에서 생성한 캡션이 정답과 **정확히 일치** (≥50%)
	//   ㉣ ★ **정말 프레임을 보고 있나**: 프레임을 **섞어** 넣으면 일치율이 무너진다
	//       (섞음 대비 정규화 이득 > 0.5) — ★ 이것이 없으면 ㉢ 은 *"캡션 분포를 외웠다"* 로도 설명된다.
	void _JudgeGen()
	{
		MLPatchEmbedParams r;
		r.frameW = kGnW; r.frameH = kGnH; r.patchK = kGnK; r.dim = kGnD;
		const uint32 P = r.Patches(), plane = kGnW * kGnH, cRow = P * kGnD;

		// 가중치 회수
		Bytes bS, bP2, bC, bWh, bWc, bWq, bWk, bWv, bW1, bW2, bWc1;
		if (!_gn.Read(_tGnSlot, bS) || !_gn.Read(_tGnPos, bP2) || !_gn.Read(_tGnCSlot, bC)
			|| !_gn.Read(_tGnWh, bWh) || !_gn.Read(_tGnWc, bWc)
			|| !_gn.Read(_tGnWq, bWq) || !_gn.Read(_tGnWk, bWk) || !_gn.Read(_tGnWv, bWv)
			|| !_gn.Read(_tGnW1, bW1) || !_gn.Read(_tGnW2, bW2) || !_gn.Read(_tGnWc1, bWc1))
		{ LogA("[ml] 생성 판정: ★실패★ — 가중치 회수가 안 됐다\n"); return; }
		Array<float> slot, pos, csl, wh, wc, wq, wk, wv, w1, w2, wc1;
		_CopyF(bS, slot);  _CopyF(bP2, pos);  _CopyF(bC, csl);
		_CopyF(bWh, wh);   _CopyF(bWc, wc);
		_CopyF(bWq, wq);   _CopyF(bWk, wk);   _CopyF(bWv, wv);
		_CopyF(bW1, w1);   _CopyF(bW2, w2);   _CopyF(bWc1, wc1);

		// ── ㉠ 배관: 마지막으로 학습한 캡션의 GPU 로짓 vs CPU 로짓(첫 자리) ──
		// ── ㉠ 배관 — **별도 forward** 의 로짓(= 회수한 가중치가 만든 것)과 CPU 를 견준다 ──
		//   ★ `t = 0` 자리를 본다: 창이 `[없음,없음,없음, BOS]` 이므로 CPU 도 `seq = [BOS]` 다.
		float ePlumb = -1.0f;
		if (_gnPlumbCap >= 0)
		{
			Bytes bL;
			if (_gn.Read(_tGnLogit, bL) && bL.GetSize() >= (uint64)kGnVoc * sizeof(float))
			{
				const float* gpu = (const float*)bL.GetData();
				// ★ **생성과 같은 헬퍼**로 조건을 계산한다 — 두 벌로 적으면 반드시 갈린다.
				Array<float> cw, cwH, h, lg, seq;
				_GnCondCpu(_gnFrameBytes.Data() + (uint64)_gnPlumbCap * plane,
					slot, pos, wq, wk, wv, wc, wc1, cw, cwH);
				seq.Reset(1); seq.Data()[0] = 0.0f;   // BOS
				h.Reset(kGnD);
				MLCtxEmbedCpu(seq.Data(), csl.Data(), h.Data(), 1u, kGnCtx, kGnD);
				lg.Reset(kGnVoc);
				if (_GnNonlin(_gnArm))
				{
					Array<float> hp, ha;
					hp.Reset(kGnHid);
					MLGemmCpuT(h.Data(), w1.Data(), hp.Data(), 1u, kGnHid, kGnD, false, false);
					for (uint32 i = 0; i < kGnHid; ++i) hp.Data()[i] += cwH.Data()[i];
					ha.Reset(kGnHid);
					MLReluCpu(hp.Data(), ha.Data(), kGnHid);
					MLGemmCpuT(ha.Data(), w2.Data(), lg.Data(), 1u, kGnVoc, kGnHid, false, false);
				}
				else
				{
					MLGemmCpuT(h.Data(), wh.Data(), lg.Data(), 1u, kGnVoc, kGnD, false, false);
					for (uint32 v = 0; v < kGnVoc; ++v) lg.Data()[v] += cw.Data()[v];
				}
				const float sc2 = MLMaxAbs(lg.Data(), kGnVoc);
				ePlumb = MLMaxAbsErr(gpu, lg.Data(), kGnVoc) / ((sc2 > 0.0f) ? sc2 : 1.0f);
			}
		}

		// ── 🔬 **진단: 조건을 쓰는가** ────────────────────────────────────────
		//   ★ **첫 바이트가 결정적 자리다.** 그 자리의 창은 `[BOS]` 뿐이므로 **조건만이 정보**다.
		//     ⇒ 첫 바이트 정확도가 우연 수준이면 *"조건을 아예 안 쓴다"* 가 확정된다.
		//   ★ 그리고 **학습 캡션의 일치율**을 같이 잰다 — *"조건을 안 쓴다"* 와
		//     *"조건을 쓰지만 일반화가 안 된다"* 는 **다른 실패**이고 조치가 다르다.
		//   ⚠️ 가설(아직 안 쟀다): **shortcut** — 캡션 어휘 44개 · 템플릿 16종류라 창 4바이트만 보면
		//     다음이 거의 결정된다(`없`→`다`→`.`) ⇒ **조건이 놀아도 손실이 내려간다**(0.03 까지 갔다)
		//     ⇒ 학습이 조건을 쓸 **이유가 없다**. 함정 11 계열(보상이 다른 경로로 얻어지면 원하는
		//     경로를 안 배운다 = shortcut learning).
		uint32 firstHit = 0, firstHitShuf = 0, firstAll = 0;
		uint32 exTr = 0, nTr = 0;
		// 💗🚫 **호/불호 워밍업 — 학습 캡션에서만 쌓는다**(시험 캡션의 정답을 안 쓴다).
		//   ★ 이것이 *"경험이 쌓인다"* 의 구현이다: 표가 캡션을 넘어 **누적**되므로
		//     시험에서는 **이미 겪은 것**을 단서로 쓴다(매번 처음부터가 아니다).
		//   ⚠️ 쓰는 것은 **실행 채점**뿐이다 — 정답 캡션을 안 본다.
		for (int f = 0; f < kGnFacts; ++f) for (int a = 0; a < 6; ++a)
		{ _gnLikeF[f][a] = 0u; _gnDisF[f][a] = 0u; }
		for (int a = 0; a < 6; ++a) for (int v = 0; v < 8; ++v)
		{ _gnLikeV[a][v] = 0u; _gnDisV[a][v] = 0u; }
		_gnValN = 0; _gnSrcExec = 0; _gnLearnMiss = 0;
		// 🔬 **인과 표를 먼저 배운다** — 그것을 쓰려면 워밍업보다 앞서야 한다.
		//   ⚠️ 앞서는 *"가중치를 안 보는 실험이라 마지막에 한 번"* 이라 뒤에 뒀다. 이제 **쓰는 것**이
		//     되었으므로 자리가 바뀐다(개입 551회 — 값싸다).
		if (!_gnCauseOk) _GnLearnCausal();
		// 💗 ㉠ **소스가 먼저 호를 깔아 준다** — 오라클을 **한 번도 안 쓴다**(티칭 재료만 본다).
		//   ★ 앞 실행은 이 단계가 없어서 표가 `면적→크기` 하나만 찼다(함정 50).
		_GnValenceFromSource();
		_gnFillSrc = _GnValFill();
		// 💗🚫 ㉡㉢ **그 다음에** 맞았다(강렬 호) / 틀렸다(불호) 가 얹힌다.
		const uint32 orc0 = _gnOracle;
		for (uint32 i = 0; i < kGnTrain; ++i)
		{
			MLScene sw;
			_GnDirected(i, slot, pos, csl, wh, wq, wk, wv, wc, wc1, w1, w2,
				kGnBoN, i * 104729u + 7u, sw, nullptr, nullptr, false, true);
		}
		_gnOrcWarm = _gnOracle - orc0;
		_gnFillAll = _GnValFill();

		// ★ **학습 캡션에서도 첫바이트를 잰다 — 이것이 두 실패를 가른다.**
		//   ㉠ 학습에서 이득이 **높다** ⇒ 조건을 **쓰긴 쓰는데 일반화가 안 된다**(함정 42 확인)
		//      ⇒ 조치는 **조건 경로를 줄이는 것**(어텐션+풀링: `Wc` 가 64배 작아진다).
		//   ㉡ 학습에서도 **0** ⇒ 정말 안 쓰는 것 ⇒ 유인/구조를 다시 봐야 한다.
		//   ★ 그리고 ㉠ 을 **미리 예측한다**: 학습 일치가 55% 인데 첫 바이트의 창은 `[BOS]` 뿐이고
		//     **모든 캡션에서 똑같다** ⇒ 학습 캡션을 55% 재현했다면 첫 바이트는 **조건을 통해서만**
		//     맞힌 것이다 ⇒ **학습 이득 > 0.4** 여야 한다. 아니면 내 인과 이해가 틀린 것이다.
		uint32 firstHitTr = 0, firstHitTrShuf = 0, firstAllTr = 0;
		for (uint32 i = 0; i < kGnTrain; ++i)
		{
			Array<uint8> g2, g2s;
			_GenDecode(_gnFrameBytes.Data() + (uint64)i * plane, slot, pos, csl, wh, wq, wk, wv, wc, wc1, w1, w2, g2);
			// ⚠️ 섞음은 **학습 안에서** 다른 장면(13 과 60 이 서로소 = 진짜 순열).
			const uint32 j = (i * 13u + 5u) % kGnTrain;
			_GenDecode(_gnFrameBytes.Data() + (uint64)j * plane, slot, pos, csl, wh, wq, wk, wv, wc, wc1, w1, w2, g2s);
			nTr++;
			if (_SameBytes(g2, _gnCaps.Data()[i])) exTr++;
			const char* w2 = _gnCaps.Data()[i].ptr();
			if (w2 != nullptr && w2[0] != 0)
			{
				firstAllTr++;
				if (g2.Count() > 0u && g2.Data()[0] == (uint8)w2[0]) firstHitTr++;
				if (g2s.Count() > 0u && g2s.Data()[0] == (uint8)w2[0]) firstHitTrShuf++;
			}
		}

		// ── ㉡㉢㉣ 생성 ──
		uint32 okUtf = 0, exact = 0, exactShuf = 0, nEv = 0;
		uint32 byteHit = 0, byteAll = 0;
		float simSum = 0.0f, simShufSum = 0.0f;   // 📏 주 지표
		float exSum = 0.0f, exShufSum = 0.0f;     // ▶️ 실행 채점
		float bestSum = 0.0f, meanSum = 0.0f;     // 🎲 best-of-N / mean-of-N
		float dirSum = 0.0f;                      // 🧠 지시된 수정(같은 예산)
		float dirVSum = 0.0f;                     // 💗🚫 호/불호를 쓴 지시된 수정
		float dirFSum = 0.0f;                     // 🔮 오라클 없이
		float dirLSum = 0.0f;                     // 🔬 배운 인과표로 축을 고름
		Array<uint8> divBuf;   Array<uint32> divStart, divLen;   // ⚠️ 다양성(붕괴 반증)
		String sample, sampleWant;
		for (uint32 i = kGnTrain; i < kGnTrain + kGnEval; ++i)
		{
			Array<uint8> gen, genShuf;
			_GenDecode(_gnFrameBytes.Data() + (uint64)i * plane, slot, pos, csl, wh, wq, wk, wv, wc, wc1, w1, w2, gen);
			// ⚠️ 섞음 = **다른 장면의 프레임**(13 과 40 이 서로소 = 진짜 순열).
			const uint32 j = kGnTrain + (((i - kGnTrain) * 13u + 5u) % kGnEval);
			_GenDecode(_gnFrameBytes.Data() + (uint64)j * plane, slot, pos, csl, wh, wq, wk, wv, wc, wc1, w1, w2, genShuf);

			nEv++;
			if (_IsValidUtf8(gen)) okUtf++;
			const String& want = _gnCaps.Data()[i];
			if (_SameBytes(gen, want)) exact++;
			if (_SameBytes(genShuf, want)) exactShuf++;
			// 바이트 단위 일치(앞에서부터 겹치는 만큼)
			const char* w = want.ptr();
			const uint32 wl = (w != nullptr) ? _CStrLen(w) : 0u;
			const uint32 gl = (uint32)gen.Count();
			const uint32 mn = (wl < gl) ? wl : gl;
			for (uint32 t = 0; t < mn; ++t)
				if ((uint8)w[t] == gen.Data()[t]) byteHit++;
			byteAll += (wl > gl) ? wl : gl;
			// 📏 정렬 유사도(주 지표) — 실제 프레임 vs 섞은 프레임
			simSum += _AlignSim(gen, want);
			simShufSum += _AlignSim(genShuf, want);
			// ▶️ **실행 채점** — 생성 캡션을 장면으로 읽고 **코드를 실제로 돌려** 사실을 견준다.
			//   ★ `없다!` vs `없다.` 처럼 문자열로는 오답인데 **의미로는 정답**인 것을 맞다고 센다.
			{
				MLFrameFacts fT, fG, fS;
				MLScene sG, sS;
				_ParseCaption(gen, sG);
				_ParseCaption(genShuf, sS);
				if (_RenderSceneFacts(_gnScenes.Data()[i], fT))
				{
					if (_RenderSceneFacts(sG, fG)) exSum += _FactScore(fT, fG);
					if (_RenderSceneFacts(sS, fS)) exShufSum += _FactScore(fT, fS);
					// 🎲 **자기 시도 N개** — 온도 샘플링으로 뽑아 각각 실행 채점한다.
					//   ★ best 가 argmax 보다 크게 높으면 *"그 최선을 타깃으로 쓰면 배울 게 있다"* 다.
					//   ⚠️ 그리고 mean 도 같이 본다 — best 만 오르고 mean 이 낮으면 **운**이지
					//     모델이 좋은 것을 자주 내는 것이 아니다(그 갈림이 자기학습의 난이도다).
					float bst = 0.0f, msum = 0.0f;
					for (uint32 k = 0; k < kGnBoN; ++k)
					{
						Array<uint8> gk;
						MLScene sk; MLFrameFacts fk;
						_GenDecode(_gnFrameBytes.Data() + (uint64)i * plane, slot, pos, csl, wh,
							wq, wk, wv, wc, wc1, w1, w2, gk, kGnTemp, i * kGnBoN + k);
						_ParseCaption(gk, sk);
						float sc3 = 0.0f;
						if (_RenderSceneFacts(sk, fk)) sc3 = _FactScore(fT, fk);
						if (sc3 > bst) bst = sc3;
						msum += sc3;
					}
					bestSum += bst;
					meanSum += msum / (float)kGnBoN;
					// 🧠 **지시된 수정** — 실행 예산을 랜덤과 **똑같이** `kGnBoN` 으로 맞춘다.
					{
						MLScene sd;
						dirSum += _GnDirected(i, slot, pos, csl, wh, wq, wk, wv, wc, wc1, w1, w2,
							kGnBoN, i * 7919u + 13u, sd);
						// 💗🚫 같은 예산 · 같은 씨앗 — **다른 것은 축·값을 고르는 방식뿐**이다.
						MLScene sv;
						dirVSum += _GnDirected(i, slot, pos, csl, wh, wq, wk, wv, wc, wc1, w1, w2,
							kGnBoN, i * 7919u + 13u, sv, nullptr, nullptr, true, false);
						// 🔮 **오라클 없이** — 고르는 데 정답을 안 쓴다(마지막 보고용 1회만).
						MLScene sf;
						const uint32 o0 = _gnOracle;
						dirFSum += _GnDirected(i, slot, pos, csl, wh, wq, wk, wv, wc, wc1, w1, w2,
							kGnBoN, i * 7919u + 13u, sf, nullptr, nullptr, true, false, true);
						(void)o0;
						// 🔬 **배운 인과표로 축을 고른다** — 손으로 준 표를 안 쓴다.
						//   ⚠️ 같은 예산 · 같은 씨앗 · 호/불호도 같이 쓴다 ⇒ **다른 것은 인과표의 출처뿐**이다.
						MLScene sL;
						dirLSum += _GnDirected(i, slot, pos, csl, wh, wq, wk, wv, wc, wc1, w1, w2,
							kGnBoN, i * 7919u + 13u, sL, nullptr, nullptr, true, false, false, 1.0f,
							nullptr, true);
					}
				}
			}
			// 🔬 첫 바이트 — 조건만이 정보인 자리
			if (w != nullptr && wl > 0u)
			{
				firstAll++;
				if (gen.Count() > 0u && gen.Data()[0] == (uint8)w[0]) firstHit++;
				if (genShuf.Count() > 0u && genShuf.Data()[0] == (uint8)w[0]) firstHitShuf++;
			}
			// ⚠️ 다양성 — 지금까지 나온 것과 같은 것이 있나(바이트 구간을 직접 견준다).
			{
				bool dup = false;
				for (uint32 d = 0; d < (uint32)divStart.Count() && !dup; ++d)
				{
					if (divLen.Data()[d] != (uint32)gen.Count()) continue;
					bool same = true;
					for (uint32 t = 0; t < divLen.Data()[d] && same; ++t)
						if (divBuf.Data()[divStart.Data()[d] + t] != gen.Data()[t]) same = false;
					if (same) dup = true;
				}
				if (!dup)
				{
					divStart.Add((uint32)divBuf.Count());
					divLen.Add((uint32)gen.Count());
					for (uint32 t = 0; t < (uint32)gen.Count(); ++t) divBuf.Add(gen.Data()[t]);
				}
			}
			if (nEv == 1u) { _BytesToString(gen, sample); sampleWant = want; }
		}

		// ══════════════════════════════════════════════════════════════════════
		// 🎭 **성격 훑기** — 같은 표 · 같은 예산 · 같은 씨앗에서 **λ 만** 바꾼다.
		//   ★ 그러면 나오는 것이 **성격 곡선**이다: 낮으면 무모, 높으면 소심.
		//   ★ 소심함을 **예산 소진율**로 같이 잰다 — 점수만 보면 *"왜 나빠졌나"* 를 모른다
		//     (안 피해서 나쁜 것과 **아예 시도를 포기해서** 나쁜 것은 다른 실패다).
		for (int L = 0; L < kGnLam; ++L)
		{
			const float lam = _GnLamOf(L);
			float lsum = 0.0f; uint32 uSum = 0u, uAll = 0u, lN = 0u;
			for (uint32 i = kGnTrain; i < kGnTrain + kGnEval; ++i)
			{
				MLScene sl; uint32 uu = 0u;
				// 🔮 ★ **오라클 없는 모드로 훑는다 — 거기가 λ 가 실제로 결정을 바꾸는 자리다.**
				//   ⚠️⚠️ 1차 실측에서 λ 곡선이 **완전히 평평**했고 나는 그것을 *"포화"* 로 읽었다.
				//     **틀렸다**: 정직한 출력이 **사실마다 아는 축이 1개**임을 보였다(인과가 희소하니
				//     당연하다) ⇒ 후보가 하나면 λ 를 뭘로 놔도 **같은 축이 뽑힌다.**
				//     ★ 즉 포화가 아니라 **λ 가 고를 것이 없었다**(진단이 통째로 달랐다).
				//   ★ 반면 **오라클 없는 모드**에서는 선호의 **부호**가 채택/거부를 **직접** 정한다
				//     ⇒ λ 가 곧 *"얼마나 확신해야 움직이나"* 이고 그것이 **성격**이다.
				//     ⇒ λ 높으면 아무것도 안 채택한다 = *"확신 전엔 모르겠어요"* ⇒ **소진율이 떨어진다.**
				// 🎲 **확률적 선택 + 배운 인과표**로 훑는다 — 성격이 정도로 나타날 수 있는 유일한 설정이다.
				lsum += _GnDirected(i, slot, pos, csl, wh, wq, wk, wv, wc, wc1, w1, w2,
					kGnBoN, i * 7919u + 13u, sl, nullptr, nullptr, true, false, true, lam, &uu,
					true, true);
				lN++;
				if (uu > 0u) { uSum += uu; uAll += kGnBoN; }
			}
			_gnLamScore[_gnArm][L] = (lN > 0u) ? (lsum / (float)lN) : 0.0f;
			_gnLamUse[_gnArm][L] = (uAll > 0u) ? ((float)uSum / (float)uAll) : 0.0f;
		}

		const float pUtf = (nEv > 0u) ? (100.0f * (float)okUtf / (float)nEv) : 0.0f;
		const float pEx  = (nEv > 0u) ? (100.0f * (float)exact / (float)nEv) : 0.0f;
		const float pShf = (nEv > 0u) ? (100.0f * (float)exactShuf / (float)nEv) : 0.0f;
		const float pByte = (byteAll > 0u) ? (100.0f * (float)byteHit / (float)byteAll) : 0.0f;
		// ★ 섞음 대비 정규화 이득 — 이 저장소의 보편 척도(`(값−우연)/(상한−우연)`).
		const float gain = (100.0f - pShf > 0.0f) ? ((pEx - pShf) / (100.0f - pShf)) : 0.0f;

		const bool okPlumb = (ePlumb >= 0.0f) && (ePlumb < 1.0e-6f);
		const bool okUtfP  = (pUtf >= 95.0f);
		const bool okEx    = (pEx >= 50.0f);
		const bool okCond  = (gain > 0.5f);

		// 팔 결과를 남긴다(마지막에 견준다).
		_gnUtf[_gnArm] = pUtf;  _gnEx[_gnArm] = pEx;  _gnShf[_gnArm] = pShf;
		_gnExTr[_gnArm] = (nTr > 0u) ? (100.0f * (float)exTr / (float)nTr) : 0.0f;
		_gnF1st[_gnArm] = (firstAll > 0u) ? (100.0f * (float)firstHit / (float)firstAll) : 0.0f;
		_gnF1stShf[_gnArm] = (firstAll > 0u)
			? (100.0f * (float)firstHitShuf / (float)firstAll) : 0.0f;
		_gnF1stTr[_gnArm] = (firstAllTr > 0u)
			? (100.0f * (float)firstHitTr / (float)firstAllTr) : 0.0f;
		_gnF1stTrShf[_gnArm] = (firstAllTr > 0u)
			? (100.0f * (float)firstHitTrShuf / (float)firstAllTr) : 0.0f;
		_gnByte[_gnArm] = pByte;
		_gnSim[_gnArm] = (nEv > 0u) ? (simSum / (float)nEv) : 0.0f;
		_gnSimShf[_gnArm] = (nEv > 0u) ? (simShufSum / (float)nEv) : 0.0f;
		_gnExec[_gnArm] = (nEv > 0u) ? (exSum / (float)nEv) : 0.0f;
		_gnExecShf[_gnArm] = (nEv > 0u) ? (exShufSum / (float)nEv) : 0.0f;
		_gnBest[_gnArm] = (nEv > 0u) ? (bestSum / (float)nEv) : 0.0f;
		_gnMean[_gnArm] = (nEv > 0u) ? (meanSum / (float)nEv) : 0.0f;
		_gnDiv[_gnArm] = (uint32)divStart.Count();
		_gnDir[_gnArm] = (nEv > 0u) ? (dirSum / (float)nEv) : 0.0f;
		_gnDirV[_gnArm] = (nEv > 0u) ? (dirVSum / (float)nEv) : 0.0f;
		_gnDirF[_gnArm] = (nEv > 0u) ? (dirFSum / (float)nEv) : 0.0f;
		_gnDirL[_gnArm] = (nEv > 0u) ? (dirLSum / (float)nEv) : 0.0f;

		LogA("\n[ml] ✍️ **D2-b 생성 판정** [%s 머리 · 드롭아웃 p=%.2f]: %s\n"
			"[ml]   ㉠ 배관(CPU 생성 = GPU forward): 정규화절대 %.3e (기준 <1e-6) → %s\n"
			"[ml]      ★ 이것이 함정 1 의 자리다 — 생성이 학습과 다른 계산을 하면 증상이 원인과 안 닮는다.\n"
			"[ml]   ㉡ 구조(유효한 UTF-8): %.1f%% (기준 ≥95) → %s\n"
			"[ml]   ㉢ 접지(**안 본 장면**에서 캡션 정확히 일치): %.1f%% · 바이트 %.1f%% (기준 ≥50) → %s\n"
			"[ml]   ㉣ **정말 프레임을 보고 있나**: 섞은 프레임 %.1f%% ⇒ 이득 %+.2f (기준 >0.5) → %s\n"
			"[ml]      ★ 이것이 없으면 ㉢ 은 *\"캡션 분포를 외웠다\"* 로도 설명된다.\n",
			_GnNonlin(_gnArm) ? "비선형" : "선형", (double)_GnDropP(_gnArm),
			(okPlumb && okUtfP && okEx && okCond) ? "통과" : "★실패★",
			(double)ePlumb, okPlumb ? "통과" : "★실패★",
			(double)pUtf, okUtfP ? "통과" : "★실패★",
			(double)pEx, (double)pByte, okEx ? "통과" : "★실패★",
			(double)pShf, (double)gain, okCond ? "통과" : "★실패★");
		LogA("[ml]   🔬 진단 — **조건을 쓰는가**\n"
			"[ml]      학습 캡션 일치 %.1f%% vs 시험 %.1f%%\n"
			"[ml]        ★ 학습만 높으면 **과적합** · 둘 다 낮으면 **조건을 안 쓴다**(다른 실패다)\n"
			"[ml]      **첫 바이트** 정확도(실제/섞음): **학습 %.1f%%/%.1f%%** · 시험 %.1f%%/%.1f%%\n"
			"[ml]        ★ 첫 바이트의 창은 `[BOS]` 뿐이라 **조건만이 정보**다.\n"
			"[ml]        ⇒ **학습에서 실제≫섞음** 이면 조건을 **쓰긴 쓰는데 일반화가 안 되는** 것이고\n"
			"[ml]          (파라미터/표본 비 문제 — 함정 42), **학습에서도 같으면** 정말 안 쓰는 것이다.\n",
			(nTr > 0u) ? (100.0 * (double)exTr / (double)nTr) : 0.0, (double)pEx,
			(double)_gnF1stTr[_gnArm], (double)_gnF1stTrShf[_gnArm],
			(double)_gnF1st[_gnArm], (double)_gnF1stShf[_gnArm]);
		LogA("[ml]   👁️ 보기 — 생성 `%s` / 정답 `%s`\n",
			(sample.ptr() != nullptr) ? sample.ptr() : "",
			(sampleWant.ptr() != nullptr) ? sampleWant.ptr() : "");
		LogA("[ml]   📌 다음: 여기에 ②실행 채점(코드→프레임→판독)을 붙이면 **자기 시도 루프**가 닫힌다\n"
			"[ml]      — 시도는 텍스트 채널에서 나오고 채점은 **비전 채널**에서 온다(암기가 아니다).\n");
	}

	// 🔁⚖️ **자기학습 판정 — 정답 없이 자기 시도로 배우면 티쳐포싱만보다 나은가.**
	//   ⚠️ 기준을 **미리 못박았다**(함정 19·21):
	//   (1) **실행 채점 이득**이 티쳐포싱만보다 **+0.05 이상** 높다.
	//      ★ 실행 채점을 주 지표로 쓰는 근거는 앞 실행에 있다 — 문자열 채점의 **2배 센 신호**였고
	//        (`+0.25` vs `+0.13`) 자기학습이 최적화하는 것이 바로 **그 채점**이다.
	//   (2) ⚠️⚠️ **자기강화 붕괴가 없다**(반증 조건): 유효 UTF-8 ≥ 90% **그리고**
	//      손실이 `ln(V)` 근처가 아니다 **그리고** 생성 다양성이 유지된다(서로 다른 것 ≥ 5종).
	//      ★ 그것이 자기 출력으로 배울 때의 고유한 위험이다: 분포가 한 점으로 좁아지면
	//        채점 점수는 오를 수 있는데(가장 안전한 캡션만 낸다) **모델은 망가진다.**
	//        ⇒ 다양성을 안 재면 그 붕괴를 "성공" 으로 읽는다(함정 11 의 사촌).
	void _JudgeGenAll()
	{
		const float dead = Log((float)kGnVoc);   // 균등 분포의 손실 = 죽음의 서명
		LogA("\n[ml] 🔁 **자기학습 판정** — **같은 티칭 횟수(%d)** 에서 자기학습이 이득을 내나\n"
			"[ml]   ★ 티칭 = 정답 캡션에 노출된 횟수. **두 팔이 같다** — 다른 것은 자기학습뿐이다.\n"
			"[ml]   ⚠️ 티쳐포싱을 스텝 많이 준 것과 견주면 안 된다(그건 **암기**이고 확장이 없다).\n"
			"[ml]   ★ 죽음 기준: 손실이 `ln(%u) = %.3f` 근처면 **로짓이 전부 0**(균등) = 안 배운 것이다\n"
			"[ml]   %-8s %8s %8s %14s %7s %7s %8s %8s\n",
			kGnSteps, kGnVoc, (double)dead,
			"머리", "학습일치", "시험일치", "📏유사도(실/섞)", "📏이득", "UTF-8", "첫바이득", "손실");
		float b0 = 0.0f, b1 = 0.0f, gf1 = 0.0f;
		for (int a = 0; a < kGnArms; ++a)
		{
			const float base = _gnF1stShf[a];
			const float g = (100.0f - base > 0.0f) ? ((_gnF1st[a] - base) / (100.0f - base)) : 0.0f;
			const float sb = _gnSimShf[a];
			const float sg = (1.0f - sb > 0.0f) ? ((_gnSim[a] - sb) / (1.0f - sb)) : 0.0f;
			if (a == 0) b0 = sg; else { b1 = sg; gf1 = g; }
			LogA("[ml]   %-10s %7.1f%% %7.1f%% %6.3f/%-6.3f %+7.2f %6.1f%% %+7.2f %7.3f%s\n",
				_GnSelf(a) ? "+자기학습" : "티쳐포싱만",
				(double)_gnExTr[a], (double)_gnEx[a],
				(double)_gnSim[a], (double)sb, (double)sg,
				(double)_gnUtf[a], (double)g, (double)_gnLoss[a],
				(_gnLoss[a] > dead - 0.05f) ? "  ← **죽었다**" : "");
		}
		const bool okByte = (b1 > b0 + 0.10f);
		const bool okKeep = (gf1 >= 0.15f);
		// ⚠️ **반증 조건을 손실로 바꿨다** — UTF-8 은 "같은 것만 반복" 을 통과시켰다(실측).
		const bool alive = (_gnLoss[1] < dead - 0.05f);
		const bool okGram = (_gnUtf[1] >= 95.0f) && alive;
		LogA("[ml]   ㉠ **자리마다 접지되나**: 📏유사도 이득 %+.2f → %+.2f (기준 +0.10) → %s\n"
			"[ml]      ★ 덧셈 바이어스(`cw`)는 **모든 자리에 같은 값**이라 낱말 선택을 못 바꾼다.\n"
			"[ml]        비선형은 조건과 창이 relu 를 함께 통과해 **곱셈 상호작용**이 생긴다.\n"
			"[ml]      ⚠️ 주 지표를 **정렬 편집거리**로 바꿨다(함정 44) — 바이트 일치율은 긴 오답을 안 벌했다.\n"
			"[ml]   ㉡ **첫바이트 접지를 지켰나**: 이득 %+.2f (기준 ≥+0.15) → %s\n"
			"[ml]   ㉢ **살아 있나**(반증): 유효 UTF-8 %.1f%% (≥95) **그리고 손실 %.3f < %.3f** → %s\n"
			"[ml]      ⚠️⚠️ UTF-8 단독으로는 못 잡는다 — *\"같은 것만 반복\"* 해도 100%% 가 나온다(실측).\n"
			"[ml]      ★ 손실이 `ln(V)` 면 로짓이 전부 0 = 2층이 **수렴하지 못한** 것이다\n"
			"[ml]        (D1′ 처럼 He 초기화 **+ 낮은 lr** — 조치가 다르다).\n"
			"[ml]   ⇒ 바이트별 접지 판정: %s\n",
			(double)b0, (double)b1, okByte ? "통과" : "★실패★",
			(double)gf1, okKeep ? "통과" : "★실패★",
			(double)_gnUtf[1], (double)_gnLoss[1], (double)dead, okGram ? "통과" : "★실패★",
			(okByte && okKeep && okGram) ? "통과" : "★실패★");
		if (!okByte)
			LogA("[ml]   ⚠️⚠️ 안 올랐으면 볼 곳:\n"
				"[ml]      ① ㉢ 이 깨졌나 = 2층이 안 배운 것(D1′ 과 같은 자리)\n"
				"[ml]      ② 조건이 **은닉으로만** 들어가 출력 쪽 신호가 약해졌나(`Wc` 를 같이 쓴다)\n"
				"[ml]      ③ 곱셈이 있어도 **조건 벡터가 1×16** 이라 담을 수 있는 낱말 정보가 모자라나\n"
				"[ml]        ⇒ 그때는 조건 차원(kGnD)이 손잡이다\n");
		// ══════════════════════════════════════════════════════════════════════
		// ▶️ **실행 채점 — 루프 ②가 닫혔다.** ⚠️ 이것은 **학습에 아직 안 쓴다**(측정만) —
		//   채점기를 믿을 수 있는지 먼저 보는 것이 이 저장소의 CPU-레퍼런스-먼저 관용구다.
		//   ★ 기준을 미리 못박았다: **실행 채점의 섞음 대비 이득이 문자열(정렬 유사도)의 것보다 크다.**
		//     ⇒ 그러면 *"같은 뜻의 다른 표면을 하나로 묶어 주므로 신호가 더 세다"* 가 확인된다.
		LogA("\n[ml] ▶️ **실행 채점** — 생성 캡션 → 장면 파싱 → **코드 실행** → 판독 → 원본 사실과 비교\n"
			"[ml]   ★ 시도는 **텍스트 채널**에서 나오고 채점은 **비전 채널**에서 온다(루프 ②).\n"
			"[ml]   %-8s %16s %8s %16s %8s\n",
			"머리", "▶️실행(실/섞)", "▶️이득", "📏문자열(실/섞)", "📏이득");
		float xg[kGnArms] = {}, sg2[kGnArms] = {};
		for (int a = 0; a < kGnArms; ++a)
		{
			const float xb = _gnExecShf[a];
			xg[a] = (1.0f - xb > 0.0f) ? ((_gnExec[a] - xb) / (1.0f - xb)) : 0.0f;
			const float sb2 = _gnSimShf[a];
			sg2[a] = (1.0f - sb2 > 0.0f) ? ((_gnSim[a] - sb2) / (1.0f - sb2)) : 0.0f;
			LogA("[ml]   %-10s %7.3f/%-7.3f %+7.2f %7.3f/%-7.3f %+7.2f\n",
				_GnSelf(a) ? "+자기학습" : "티쳐포싱만",
				(double)_gnExec[a], (double)xb, (double)xg[a],
				(double)_gnSim[a], (double)sb2, (double)sg2[a]);
		}
		// 🔁 **자기학습 판정** — 기준을 미리 못박았다.
		const bool okSelf = (xg[1] > xg[0] + 0.05f);
		const bool noCollapse = (_gnUtf[1] >= 90.0f) && (_gnDiv[1] >= 5u)
			&& (_gnLoss[1] < Log((float)kGnVoc) - 0.05f);
		LogA("[ml]   🔁 **자기학습 판정**: 실행 이득 %+.2f → %+.2f (기준 +0.05) → %s\n"
			"[ml]      ★ 타깃이 전부 **모델 자신의 출력**이다(정답 캡션을 안 썼다).\n"
			"[ml]      ⚠️ **붕괴 반증**: UTF-8 %.1f%%(≥90) · 다양성 %u종(≥5) · 손실 %.3f → %s\n"
			"[ml]        ★ 다양성을 안 재면 *\"가장 안전한 캡션만 낸다\"* 를 성공으로 읽는다\n"
			"[ml]          (채점은 오르는데 모델은 망가진 상태 — 함정 11 의 사촌).\n"
			"[ml]   ⇒ 자기학습 판정: %s\n",
			(double)xg[0], (double)xg[1], okSelf ? "통과" : "★실패★",
			(double)_gnUtf[1], _gnDiv[1], (double)_gnLoss[1],
			noCollapse ? "붕괴 없음" : "★붕괴★",
			(okSelf && noCollapse) ? "통과" : "★실패★");
		const bool okExec = (xg[1] > sg2[1]);
		LogA("[ml]   ▶️ 판정(비선형 팔): 실행 이득 %+.2f vs 문자열 이득 %+.2f → %s\n"
			"[ml]      ★ 근거가 실측에 있다: 생성 `없다!` / 정답 `없다.` 는 **문자열로는 오답**인데\n"
			"[ml]        **의미로는 정답**이다(둘 다 빈 장면) ⇒ 티쳐포싱은 벌하고 실행 채점은 맞다고 센다.\n"
			"[ml]      ⇒ *\"표면 형태가 아니라 가리키는 것으로 채점한다\"* — 그래서 같은 뜻의 여러 표면이\n"
			"[ml]        한 경험으로 묶이고, 그것이 **적은 경험으로 인과를 배우는** 길이다.\n"
			"[ml]   ⚠️ **아직 학습에 안 쓴다** — 채점기를 믿을 수 있는지 먼저 재는 것이 순서다.\n"
			"[ml]   📌 다음: 이 채점을 손실로 쓴다(⚠️ 함정 11 — 상상 출력에 **예측 손실**을 걸면 안 된다.\n"
			"[ml]      실행 결과와의 **차이**에만 손실을 건다).\n",
			(double)xg[1], (double)sg2[1], okExec ? "통과(실행 채점이 더 센 신호다)" : "★실패★");

		// ══════════════════════════════════════════════════════════════════════
		// 🎲 **자기 시도의 가치 — 자기학습을 짓기 전에 반드시 재야 하는 것.**
		//   ★ 묻는 것: *"N개 시도 중 최선이 argmax 1개보다 나은가?"*
		//     · 크게 낫다 ⇒ **그 최선을 타깃으로 쓰면 배울 게 있다**(자기학습이 성립한다).
		//     · 비슷하다 ⇒ 샘플링이 다양성을 못 내거나 채점이 못 가른다 ⇒ **자기학습이 무의미**하다.
		//   ⚠️ 기준을 미리 못박았다: **best-of-%u 가 argmax 보다 +0.10 이상** 높다.
		//   ★ `mean` 도 같이 본다 — best 만 오르고 mean 이 낮으면 그것은 **운**이고,
		//     모델이 좋은 것을 자주 내는 것이 아니다(그 갈림이 자기학습의 난이도를 말해 준다).
		LogA("\n[ml] 🎲 **자기 시도의 가치** — 샘플 %u개(온도 %.2f)를 실행 채점한다\n"
			"[ml]   %-8s %9s %9s %9s %11s\n",
			kGnBoN, (double)kGnTemp,
			"머리", "argmax", "🎲mean", "🎲best", "best−argmax");
		for (int a = 0; a < kGnArms; ++a)
			LogA("[ml]   %-10s %8.3f %8.3f %8.3f %+10.3f\n",
				_GnSelf(a) ? "+자기학습" : "티쳐포싱만",
				(double)_gnExec[a], (double)_gnMean[a], (double)_gnBest[a],
				(double)(_gnBest[a] - _gnExec[a]));
		// ══════════════════════════════════════════════════════════════════════
		// 🧠 **지시된 수정 판정 — "이유있는 추론" 이 랜덤 찍기보다 나은가.**
		//   ⚠️ 기준을 미리 못박았다: **같은 실행 예산**(%u회)에서 지시된 수정의 점수가
		//     랜덤 best-of-N 보다 **+0.10 이상** 높다.
		//   ★ 이것이 *"학습량이 아니라 추론이다"* 의 직접 측정이다 — 예산이 같으므로
		//     차이는 **오직 탐색을 어떻게 하나**에서 온다(곱 vs 합).
		LogA("\n[ml] 🧠 **지시된 수정 vs 랜덤 찍기** — **같은 실행 예산 %u회**\n"
			"[ml]   ★ 랜덤: %u번 샘플 → 최선 · 지시된: 1번 샘플 → **틀린 축만** %u번 순회 수정\n"
			"[ml]   ⚠️ 축마다 커서를 들어 **같은 값을 두 번 시도하지 않는다**(\"이미 확인한 데는 안 간다\")\n"
			"[ml]   %-10s %10s %10s %12s\n",
			kGnBoN, kGnBoN, kGnBoN - 1u,
			"머리", "🎲랜덤best", "🧠지시된", "지시−랜덤");
		for (int a = 0; a < kGnArms; ++a)
			LogA("[ml]   %-10s %9.3f %9.3f %+11.3f\n",
				_GnSelf(a) ? "+자기학습" : "티쳐포싱만",
				(double)_gnBest[a], (double)_gnDir[a], (double)(_gnDir[a] - _gnBest[a]));
		// ══════════════════════════════════════════════════════════════════════
		// 💗🚫 **호/불호 판정 — 틀린 경험이 다음의 단서가 되나.**
		//   ⚠️ 기준을 미리 못박았다: **같은 예산 · 같은 씨앗**에서 호/불호를 쓴 쪽이 커서만 쓰는
		//     쪽보다 **+0.05 이상** 높다(다른 것은 **축·값을 고르는 방식뿐**이다).
		//   ★ 워밍업은 **학습 캡션에서만** 쌓았다 — 시험 캡션의 정답을 안 본다.
		LogA("\n[ml] 💗🚫 **호/불호** — **호는 소스에 붙어 있다**(오라클이 주는 것이 아니다)\n"
			"[ml]   ★ 규칙 세 줄: ㉠ **티칭에서 온 것 → 호 +%u**(맞든 틀리든 · 불호 0)\n"
			"[ml]     ㉡ **맞았다 → 호** ㉢ **틀렸다 → 불호** — 둘 다 **+%u/+%u**(사실축/값 층) **같은 무게**\n"
			"[ml]     ★ *\"기록은 편향 없이, 편향은 선택에서\"* — 무게는 소스 규모에서 **도출**했다(상수 아님).\n"
			"[ml]       소스 = **넓고 약한 사전** · 결과 관측 = **좁고 강한 증거**(두 번이면 사전과 맞먹는다).\n"
			"[ml]     ⇒ 우리는 *\"하면 안돼\"* 를 가르치는 중이 아니다 — **엄마 표정이 밝다** ⇒ 기본이 호다.\n"
			"[ml]   표 채움률: 소스만 **%.0f%%** → +맞음/틀림 **%.0f%%**(앞 실행은 사실상 **1칸**이었다)\n"
			"[ml]     ★ **100%% 가 목표가 아니다** — 인과표의 비영 칸이 6개이고 그것이 24칸의 25%%다\n"
			"[ml]       ⇒ 채워야 할 것은 **인과가 있는 칸**이고 나머지는 **정말로 미지**다(빼는 것이 맞다).\n"
			"[ml]   소스에서 쓴 **자기 실행** %u회(오라클 아님) · 워밍업 오라클 %u회 · 기록 %u회\n"
			"[ml]   %-10s %11s %11s %11s\n",
			kValSrc, _gnWRecF, _gnWRecV,
			(double)(100.0f * _gnFillSrc), (double)(100.0f * _gnFillAll),
			_gnSrcExec, _gnOrcWarm,
			_gnValN, "머리", "🧠커서만", "💗🚫호불호", "🔮오라클없이");
		for (int a = 0; a < kGnArms; ++a)
			LogA("[ml]   %-10s %10.3f %10.3f %11.3f\n",
				_GnSelf(a) ? "+자기학습" : "티쳐포싱만",
				(double)_gnDir[a], (double)_gnDirV[a], (double)_gnDirF[a]);
		const float vgain = _gnDirV[0] - _gnDir[0];
		const bool okVal = (vgain > 0.05f);
		LogA("[ml]   💗🚫 판정(티쳐포싱만 팔): 호불호−커서 = %+.3f (기준 +0.05) → %s\n",
			(double)vgain, okVal ? "통과(틀린 경험이 단서가 된다)" : "★실패★");
		// 🔬 **배운 인과표 판정** — 손으로 준 표를 뗄 수 있나.
		//   ⚠️ 기준을 미리 못박았다: 손으로 준 표의 **95% 이상**을 낸다(동등하면 뗀다).
		//     ★ *"더 낫다"* 가 아니라 *"같다"* 가 기준인 이유: 목적은 성능이 아니라 **손으로 준 것을
		//       없애는 것**이고, 같은 성능이면 배운 쪽이 이긴다(창립 규칙).
		{
			const float keepL = (_gnDirV[0] > 0.0f) ? (_gnDirL[0] / _gnDirV[0]) : 0.0f;
			const bool okL = (keepL >= 0.95f);
			LogA("[ml]   🔬 **배운 인과표로 축을 고른다** — 손으로 준 `_FactToAxis` 를 안 쓴다\n"
				"[ml]      손으로 준 표 %.3f → **배운 표 %.3f**(유지율 %.0f%%) · 기준 95%% → %s\n"
				"[ml]      후보를 못 낸 횟수 %u (그때는 손으로 준 표로 떨어진다 — 조용히 실패하지 않는다)\n"
				"[ml]      ★ 크기가 아니라 **특이성**으로 고른다(함정 49): `C[축][사실] / Σ_f C[축][f]`\n"
				"[ml]        ⇒ 여러 사실을 흔드는 축(개수)은 특이성이 낮아 밀린다.\n"
				"[ml]      ★ 그리고 배운 표는 **반응한 축 전부**를 주므로 🎭 성격(λ)이 고를 후보가 생긴다.\n",
				(double)_gnDirV[0], (double)_gnDirL[0], (double)(100.0f * keepL),
				okL ? "통과(손으로 준 표를 뗄 수 있다)" : "★실패★",
				_gnLearnMiss);
		}
		// 🔮 **오라클 비용을 명시한다** — 이것이 알파고와 생명체를 가르는 축이다.
		//   ★ *"정답 캡션을 안 쓴다"* 는 **반쪽 주장**이었다: 정답 **장면**을 시도마다 만졌다.
		//     ⇒ 공정한 축은 **"외부 진실에 닿은 횟수"**(티칭 + 오라클 채점)이고,
		//       자가학습의 가치는 **그 횟수를 줄이면서 성능을 유지하는 것**이다.
		//   ⚠️ 기준을 미리 못박았다: 오라클 없이 고른 쪽이 오라클로 고른 쪽의 **80% 이상**을 낸다.
		const float keep = (_gnDirV[0] > 0.0f) ? (_gnDirF[0] / _gnDirV[0]) : 0.0f;
		const bool okFree = (keep >= 0.80f);
		LogA("[ml]   🔮 **오라클 비용** — 총 접촉 %u회(캡션마다 1회로 재사용한다)\n"
			"[ml]      오라클로 고름 %.3f → **오라클 없이 호불호로만 고름 %.3f**(유지율 %.0f%%)\n"
			"[ml]      기준: 80%% 이상 → %s\n"
			"[ml]      ★ 알파고는 시뮬 때 **늘 명확한 승패**를 받는다. 생명체는 그렇지 않다 —\n"
			"[ml]        소수의 접지 경험으로 **호/불호를 쌓고** 그 뒤로는 그것으로 판단한다.\n"
			"[ml]        ⇒ 유지율이 높으면 **오라클을 8배 덜 만지고도** 같은 일을 한다는 뜻이다.\n"
			"[ml]      ⚠️ 유지율이 낮으면 호/불호가 아직 **오라클의 대체품이 못 된다**는 뜻이고,\n"
			"[ml]        그때 필요한 것은 더 많은 접지 경험(워밍업)이거나 더 나은 선호 표현이다.\n",
			_gnOracle, (double)_gnDirV[0], (double)_gnDirF[0], (double)(100.0f * keep),
			okFree ? "통과(호/불호가 오라클을 대체한다)" : "★실패★");
		// ══════════════════════════════════════════════════════════════════════
		// 🎭 **성격 곡선** — 같은 기억에서 λ 만 바꾼다.
		LogA("[ml]   🎭 **성격**(λ = 선택에서 불호를 몇 배로 보나) — **기억은 그대로**, 쓰는 법만 바뀐다\n"
			"[ml]      🎲 **확률적 선택**으로 훑는다: `w = 호/(호 + λ·불호 + 1)` 에 비례해 축을 뽑고\n"
			"[ml]        **`max w` 의 확률로만 움직인다**(그 밖에는 **포기**) — 추가 상수가 없다.\n"
			"[ml]        ⚠️ 앞서 `argmax` 로 훑을 때는 곡선이 **계단**뿐이었다 — λ 는 연속인데 그것이\n"
			"[ml]          조종하는 것이 **이산 순위**여서, 기피의 **정도**가 나타날 자리가 없었다(함정 60).\n"
			"[ml]        ★ 그리고 이 형태에서 두 병리가 **λ 의 연속 함수**가 된다:\n"
			"[ml]          λ=0 → `w≈1` → 안 포기 = **무모함** · λ 큼 → `w→0` → 자주 포기 = **소심함**\n"
			"[ml]      %-10s %7s %7s %7s %7s %7s %7s %7s %7s\n",
			"머리/λ", "0", "0.02", "0.05", "0.1", "0.25", "0.5", "1", "2");
		for (int a = 0; a < kGnArms; ++a)
		{
			LogA("[ml]      %-10s %7.3f %7.3f %7.3f %7.3f %7.3f %7.3f %7.3f %7.3f  (점수)\n",
				_GnSelf(a) ? "+자기학습" : "티쳐포싱만",
				(double)_gnLamScore[a][0], (double)_gnLamScore[a][1], (double)_gnLamScore[a][2],
				(double)_gnLamScore[a][3], (double)_gnLamScore[a][4], (double)_gnLamScore[a][5],
				(double)_gnLamScore[a][6], (double)_gnLamScore[a][7]);
			LogA("[ml]      %-10s %6.0f%% %6.0f%% %6.0f%% %6.0f%% %6.0f%% %6.0f%% %6.0f%% %6.0f%%  (예산 소진율)\n", "",
				(double)(100.0f * _gnLamUse[a][0]), (double)(100.0f * _gnLamUse[a][1]),
				(double)(100.0f * _gnLamUse[a][2]), (double)(100.0f * _gnLamUse[a][3]),
				(double)(100.0f * _gnLamUse[a][4]), (double)(100.0f * _gnLamUse[a][5]),
				(double)(100.0f * _gnLamUse[a][6]), (double)(100.0f * _gnLamUse[a][7]));
		}
		{
			int bL = 0; for (int L = 1; L < kGnLam; ++L)
				if (_gnLamScore[0][L] > _gnLamScore[0][bL]) bL = L;
			const bool interior = (bL > 0 && bL < kGnLam - 1);
			const float drop = _gnLamUse[0][0] - _gnLamUse[0][kGnLam - 1];
			// ⚠️ **포화 검사** — 위쪽 λ 들이 서로 완전히 같으면 그것은 곡선이 아니라 **천장**이다.
			//   ★ 1차 실측에서 λ 0.5~8 이 소수 셋째 자리까지 같았다 ⇒ 순위가 이미 고정된 것이다.
			bool sat = true;
			for (int L = kGnLam - 3; L < kGnLam - 1 && sat; ++L)
				if (_gnLamScore[0][L] != _gnLamScore[0][L + 1]) sat = false;
			// ⚠️⚠️ **"값이 같다" 의 원인이 셋이고 조치가 전부 다르다** — 로그가 하나로 뭉개면 오진한다.
			//   실측으로 세 번 다른 진단을 냈다(함정 55): ㉠ 포화 ㉡ 아는 축이 1개 ㉢ **불호가 없다**.
			//   ⇒ 그래서 로그가 **어느 쪽인지 세어서** 말해야 한다(서사를 고르는 것은 숫자여야 한다).
			uint64 disTot = 0; int multi = 0;
			for (int f = 1; f < kGnFacts; ++f)
			{
				int known = 0;
				for (int a = 0; a < 6; ++a)
				{
					if (_AxisClasses(a) < 2u) continue;
					if (_gnLikeF[f][a] + _gnDisF[f][a] == 0u) continue;
					known++; disTot += _gnDisF[f][a];
				}
				if (known >= 2) multi++;
			}
			LogA("[ml]      🎭 최대점 λ = **%.2f**%s · 소진율 낙폭(λ 0→8) = %+.0f%%p\n"
				"[ml]      ⚠️ 기준(미리 못박음): 최대점이 **내부**에 있어야 λ 가 성격 축이다 → %s\n"
				"[ml]      ★ 그리고 이것이 성격의 두 병리를 **관측량으로** 가른다:\n"
				"[ml]        λ 낮 = **무모함**(안 피하니 같은 데 또 간다) ·\n"
				"[ml]        λ 높 = **소심함**(*\"확신 전엔 모르겠어요\"*) ⇒ **소진율이 떨어진다**\n"
				"[ml]          = 고를 축이 없어 **조기 포기**한다. 점수만 보면 두 실패를 못 가른다.\n"
				"[ml]      ★ 다음: **기분** — 같은 표에서 λ 를 **상태로** 흔든다(기억은 안 바뀐다).\n"
				"[ml]        ⇒ 그것이 λ 를 기록에 접지 않은 이유다(기분 나쁜 날이 기억을 다시 쓰면 안 된다).\n",
				(double)_GnLamOf(bL), interior ? "(내부)" : "(**끝점** — 격자를 넓혀야 한다)",
				(double)(100.0f * drop),
				interior ? "통과(성격 축이다)" : "★판정 보류★(끝점이면 최적을 못 봤다)");
			if (sat)
			{
				// ★ 원인을 **숫자로** 가른다 — 셋 중 어느 것인지에 따라 조치가 정반대다.
				LogA("[ml]      ⚠️⚠️ **λ 가 아무것도 안 바꾼다** — 원인을 숫자로 가른다:\n"
					"[ml]        · 불호 총량 = **%llu** · 아는 축이 2개 이상인 사실 = **%d개**\n",
					(unsigned long long)disTot, multi);
				if (disTot == 0ull)
					LogA("[ml]        ⇒ ㉢ **불호가 없다** ⇒ λ 는 **곱할 것이 없다**(포화가 아니다).\n"
						"[ml]          ★ 귀속을 엄격히 한 대가다 — 성능은 올랐고 손잡이는 죽었다.\n"
						"[ml]          ⇒ 조치: λ 를 만지는 것이 아니라 **불호가 실재하는 상황**을 만드는 것.\n");
				else if (multi == 0)
					LogA("[ml]        ⇒ ㉡ **사실마다 아는 축이 1개** ⇒ 후보가 하나면 λ 가 **고를 것이 없다**.\n"
						"[ml]          ⇒ 조치: 무게를 줄이는 것이 아니라 **후보를 만드는 것**이다.\n");
				else
					LogA("[ml]        ⇒ ㉠ **포화**(불호가 아는 칸을 다 음수로 눌러 순위가 고정) ⇒ **아래를 본다**.\n");
				LogA("[ml]        ★ 정리: 🎭 성격이 뜻을 가지려면 **둘 다** 필요하다 —\n"
					"[ml]          **불호가 실재하고**(㉢ 아님) **고를 후보가 둘 이상**(㉡ 아님).\n"
					"[ml]          ⚠️ 그리고 그 둘은 **상충한다**: 귀속을 느슨히 하면 불호가 생기지만\n"
					"[ml]            무죄인 축을 벌해 성능이 떨어진다(함정 54) ⇒ 손잡이를 살리려면\n"
					"[ml]            **인과가 겹치는 사실**(축 후보가 여럿인 자리)을 먼저 만들어야 한다.\n");
			}
		}
		// 💗🚫 배운 선호 — 사실마다 **가장 끌리는 축**과 그 갈등.
		static const char* fn[kGnFacts] = { "있나", "덩어리", "색", "면적", "자리", "채움" };
		static const char* an2[6] = { "개수", "모양", "색", "크기", "자리", "속" };
		// ⚠️⚠️ **이 출력이 나를 속였다 — 함정으로 적어 둔다.**
		//   앞 실행은 `사실 덩어리 → 모양 (호 0 / 불호 0)` 을 찍었고 나는 그것을 *"표가 비었다"* 로
		//   읽었다. **틀렸다**: 채움률은 25%(6칸)였고, 찍힌 0/0 은 **승자가 미지 축**이었다는 뜻이다
		//   (아는 축들이 전부 음수라 0.00 인 미지가 이겼다).
		//   ⇒ ★ **선택 규칙과 출력 규칙이 달라서** 생긴 오독이다(선택은 미지를 빼는데 출력은 안 뺐다).
		//     ★ 판정 규칙: ***"표를 찍을 때는 선택이 쓰는 것과 똑같은 규칙으로 찍는다."***
		for (int fi = 1; fi < kGnFacts; ++fi)
		{
			int bA = -1; float bP = -2.0f; int unk = 0, known = 0;
			for (int a = 0; a < 6; ++a)
			{
				if (_AxisClasses(a) < 2u) continue;
				if (_gnLikeF[fi][a] + _gnDisF[fi][a] == 0u) { unk++; continue; }   // 미지
				known++;
				const float pr = _Pref(_gnLikeF[fi][a], _gnDisF[fi][a]);
				if (pr > bP) { bP = pr; bA = a; }
			}
			if (bA < 0)
			{
				LogA("[ml]      사실 `%s` → 🌫️ **아는 축이 없다**(미지 %d축) — 인과가 없는 사실이다\n",
					fn[fi], unk);
				continue;
			}
			LogA("[ml]      사실 `%s` → 💗 **%s**(선호 %+.2f · 호 %u / 불호 %u · 갈등 %.2f) "
				"· 아는 축 %d · 🌫️미지 %d\n",
				fn[fi], an2[bA], (double)bP, _gnLikeF[fi][bA], _gnDisF[fi][bA],
				(double)_Conflict(_gnLikeF[fi][bA], _gnDisF[fi][bA]), known, unk);
		}
		LogA("[ml]      ★ **갈등**(호·불호가 둘 다 높다)은 *\"그 축이 그 사실만 흔들지 않는다\"* 는\n"
			"[ml]        신호다 ⇒ 나중에 **쪼개기/재조합**의 단서로 쓴다(연결 확장의 축).\n"
			"[ml]      ★ 소스가 호를 **넓게** 깔고 *\"틀렸다\"* 가 **좁게** 깎는다 — 그 분업이 설계다.\n"
			"[ml]        ⇒ 커플링(개수를 바꾸면 면적도 움직인다) 때문에 호는 넓을 수밖에 없고,\n"
			"[ml]          그것을 가르는 정보는 **불호에만** 있다.\n"
			"[ml]      ⚠️ **빈 칸은 이제 \"미지\"** 라 선호 경쟁에서 **빠진다**(선호 0 이 아니다) —\n"
			"[ml]        그 한 줄이 없어서 앞 실행은 `덩어리 → 모양` 처럼 인과 없는 쌍을 골랐다.\n");

		const float dgain = _gnDir[0] - _gnBest[0];
		const bool okDir = (dgain > 0.10f);
		LogA("[ml]   🧠 판정(티쳐포싱만 팔 기준): 지시−랜덤 = %+.3f (기준 +0.10) → %s\n"
			"[ml]      ★ 탐색이 **곱에서 합으로** 바뀐다: 랜덤은 `2^5 = 32` 방향을 뒤져야 하는데\n"
			"[ml]        지시된 수정은 틀린 축만 하나씩 고쳐 `5` 방향이다. ⇒ **데이터가 아니라 구조**다.\n"
			"[ml]      ⚠️ 인과 표(사실 → 고칠 축)는 **배운 것이 아니라 판독기 규약이 준 것**이다 —\n"
			"[ml]        창립 규칙과 맞는다(*\"인코딩 층의 구조는 주고 분포 층은 배우게 한다\"*).\n"
			"[ml]      ⚠️ 통과해도 그것만으로 자기학습이 되는 것은 아니다 — 다음은 **이 수정 결과를\n"
			"[ml]        타깃으로** 쓰는 것이고, 그때 문법 항(함정 47)을 같이 넣어야 한다.\n",
			(double)dgain, okDir ? "통과(추론이 찍기를 이긴다)" : "★실패★");

		const float lift = _gnBest[1] - _gnExec[1];
		const bool okBoN = (lift > 0.10f);
		LogA("[ml]   🎲 판정(비선형 팔): best−argmax = %+.3f (기준 +0.10) → %s\n"
			"[ml]      ★ 통과면 **자기학습이 성립한다**: 채점이 좋은 시도를 타깃으로 티쳐포싱하면\n"
			"[ml]        정답 캡션 없이도 배울 것이 남아 있다는 뜻이다.\n"
			"[ml]      ★ 그리고 그것이 **함정 11 을 구조로 지킨다** — 채점이 좋은 것만 타깃으로 쓰므로\n"
			"[ml]        *\"틀린 상상을 강화\"* 하는 일이 원리적으로 없다.\n"
			"[ml]      ⚠️ mean 이 argmax 보다 낮은 것은 정상이다(온도가 다양성의 대가를 낸다) —\n"
			"[ml]        중요한 것은 **최선이 얼마나 위에 있나**다.\n",
			(double)lift, okBoN ? "통과(자기학습에 쓸 신호가 있다)" : "★실패★(자기학습이 무의미하다)");


		// 🔬 **인과 표 학습** — ★ 가중치를 안 보는 실험이므로(장면 + 판독기만 쓴다)
		//   마지막에 한 번만 돌린다.
		_GnLearnCausal();
		if (_gnCauseOk) _JudgeCausal();
	}

	// ══════════════════════════════════════════════════════════════════════════
	// 🌱 **D3 · 생명주기 단계** — 세 팔을 차례로 100틱씩 돌린다.
	//   ⚠️ 틱마다 장면을 실행하므로(컴파일 + 그리기) 한 프레임에 다 돌리면 프레임이 길어진다
	//     ⇒ 프레임마다 몇 틱만 돈다(이 저장소의 관용구 — 렌더 스레드를 굶기지 않는다).
	int    _lfStage = 0, _lfArm = 0;
	MLLife _lfLife;
	MLLife::Acc _lfIn[MLLife::kArms] = {}, _lfTr[MLLife::kArms] = {};
	float  _lfInf[MLLife::kArms] = {};
	uint32 _lfInfN[MLLife::kArms] = {}, _lfExt[MLLife::kArms] = {};
	uint32 _lfLearn[MLLife::kArms] = {}, _lfEval[MLLife::kArms] = {};
	uint32 _lfTruthW[MLLife::kArms] = {}, _lfInferred[MLLife::kArms] = {};
	// 🔎 진단 — 표에 무엇이 들었나(`아는 칸` 이 설명 안 됐다 ⇒ 서사 대신 센다).
	uint32 _lfCExp[MLLife::kArms] = {}, _lfCGuess[MLLife::kArms] = {};
	uint32 _lfCAvF[MLLife::kArms] = {}, _lfCObs[MLLife::kArms] = {};
	// 🌫️ **의심 문턱 훑기** — 얼마나 의심스러운 것까지 답에 쓰나.
	//   ★ `신뢰` 를 버렸다: 그것은 칸마다 **같은 값**이라 좋은 상상과 나쁜 상상이 **무작위로** 섞였다
	//     (실측: 신뢰를 훑어도 여유가 1.3~1.4 로 평평했다 ⇒ 손잡이가 아니라 **볼륨**이었다).
	//   ⇒ 의심은 **칸마다 다른 값**이므로 문턱을 낮추면 **약한 근거부터** 빠진다.
	//   ⚠️ 0.7 이하 = 겪은 것 · 0.8~1.0 = 상상(근거가 약할수록 1 에 가깝다).
	static constexpr int kLfTrust = 5;
	// 🌫️ **갈림 문턱** `dSplit = flips / (flips + 2)` ⇒ 0 · 0.33 · 0.50 · 0.60 · 0.67 ...
	//   ★ 값의 뜻이 분명하다: 0.00 = 한 번도 안 갈렸다 · 0.33 = 한 번 · 0.50 = 두 번 · 0.60 = 세 번.
	//   ⚠️ 16차의 합산 문턱은 0.95~0.98 에 몰려 **분해능이 없었다**(함정 80) — 이쪽은 퍼져 있다.
	static float _LfTrustOf(int i)
	{
		const float v[kLfTrust] = { 0.0f, 0.33f, 0.50f, 0.60f, 1.0f };
		return v[(i >= 0 && i < kLfTrust) ? i : 0];
	}
	MLLife::Acc _lfTrTr[MLLife::kArms][kLfTrust] = {};
	// ══════════════════════════════════════════════════════════════════════════
	// 🌱 **씨앗 재현** — 같은 실행에서 고른 문턱은 **증거가 아니다.**
	//
	// ⚠️⚠️ 18차에서 곡선의 최대점(갈림 ≤ 0.50)을 보고 문턱을 정하고 **그 문턱으로 판정**했다
	//   ⇒ 손잡이를 고른 데이터와 판정한 데이터가 같다(과적합의 가장 흔한 모양이다).
	// ★ 그래서 문턱을 **0.50 으로 못박고** 씨앗을 바꿔 **여러 번** 돌린다.
	//   ⇒ 재현되면 그때 증거가 되고, 안 되면 18차의 2.3 은 **그 씨앗의 우연**이다.
	// ⚠️ 그리고 이것을 **먼저** 한다 — 재현이 안 되면 귀속(①/②)을 가리는 일이 무의미하다.
	static constexpr int kLfSeeds = 4;
	static constexpr int kLfFixIdx = 2;      // 고정 문턱 = `_LfTrustOf(2)` = 0.50
	static uint32 _LfSeedOf(int i)
	{
		const uint32 v[kLfSeeds] = { 424242u, 918273u, 553311u, 707070u };
		return v[(i >= 0 && i < kLfSeeds) ? i : 0];
	}
	// ══════════════════════════════════════════════════════════════════════════
	// 📐 **경험 규모 × 배운 유사** — *"몇 번의 경험부터 배운 유사가 값을 하나"*
	//
	// ⚠️ 20차에서 안 것은 *"20회 경험으로는 유사를 배울 수 없다"* 뿐이다(함정 84).
	//   그것이 **영원히**인지 **규모의 문제**인지는 안 쟀다.
	// ★ 그래서 규모를 훑고 **각 규모에서 on/off 를 둘 다** 잰다 — 차이가 좁혀지면
	//   그 규모가 **배운 유사의 하한**이고, 그것이 곧 **적은 티칭의 실제 하한**이다.
	// ⚠️ **피드백 예산은 10회로 고정**한다 — 경험만 늘려야 질문이 성립한다.
	//   ★ 그리고 그것이 이 프로젝트의 목표와 맞는다(*"최소 티칭"* 은 피드백 쪽이다).
	static constexpr int kLfScales = 3;
	static int _LfScaleOf(int i)
	{
		const int v[kLfScales] = { 2, 4, 8 };     // 틱당 경험 ⇒ 총 20 · 40 · 80
		return v[(i >= 0 && i < kLfScales) ? i : 0];
	}
	// ⚖️ **유사의 출처 세 갈래를 나란히** — 끔 · 개입 · 상관.
	//   ★ `상관` 은 **함정 90 판정용**이다: 26차와 다른 것이 **강도를 안 주는 것뿐**이므로
	//     맞춘 칸의 부호가 그 진단을 직접 답한다.
	// 🧩 **네 번째 갈래 `조합`** — 허가의 **단위**를 짝에서 **(짝 + 사실)** 로 바꾼 것이다.
	//   ★ 그것이 묻는 것: *"인코딩 유사의 무조건 통과가 **검사 안 된 허가증**이었나."*
	//     · 여유가 유지되면 그 통과는 실제로 **범위 안**이었다
	//     · 여유가 떨어지면 인코딩 팔이 거기에 **무임승차**했던 것이고,
	//       `개입 ≥ 끔의 80%` 라는 기준은 **두 겹으로 잘못된 질문**이었다
	static constexpr int kLfSims = 10;
	static constexpr int kLfCfgs = kLfScales * kLfSims;   // + 전이기억 · 다른 구조화 5축의 사건앵커
	// 🌱 **씨앗 4개** — 재현 판정을 이 축에 걸기 위해서다.
	//   ⚠️⚠️ 앞서 2개로 줄인 것은 회차 수 때문이었고, 그 상태에서 `조합` 이 기준을 통과했다.
	//     그런데 그 기준은 **네 번째 기제**에서 통과했으므로 다중 비교의 여지가 있고, 게다가
	//     **평균**으로 판정하면 씨앗 편차가 가려진다(실측: 경험 80 에서 22.0 vs 4.8 — 4.6배).
	//   ⇒ 씨앗을 늘리고 **씨앗마다** 기준을 재서 *"4개 중 몇 개"* 를 센다.
	static constexpr int kLfSeedsUse = kLfSeeds;           // 3규모 × 8갈래 × 4씨앗 × 2팔 = 192회
	static int _LfCfgScale(int c) { return _LfScaleOf(c / kLfSims); }
	static int _LfCfgSim(int c) { return c % kLfSims; }
	int    _lfCfg = 0;
	float  _lfCfgMar[kLfCfgs] = {};      // 설정마다의 순이득 여유(씨앗 평균)
	float  _lfCfgHit[kLfCfgs] = {}, _lfCfgMiss[kLfCfgs] = {};
	// 🎯 절대 성능 — 정리의 증분과 **별개**다. 시험에서 이미 학습하는 구조는 증분이 0이어도 잘할 수 있다.
	float  _lfCfgMacro[kLfCfgs] = {}, _lfCfgMemMacro[kLfCfgs] = {};
	float  _lfCfgMoveP[kLfCfgs] = {}, _lfCfgMoveR[kLfCfgs] = {};
	float  _lfCfgMacroS[kLfCfgs][kLfSeeds] = {};
	int    _lfCfgAbsN[kLfCfgs] = {};
	int    _lfCfgN[kLfCfgs] = {};        // 비율이 정의되는 경우의 수
	// 🌱 **(설정, 씨앗) 마다의 여유** — 평균이 가리는 것을 보려고 남긴다.
	//   ⚠️ `999`(정의되지 않음)는 넣지 않는다 — 그것이 거짓 양성을 만든 값이다(함정 38 계열).
	//     ★ 그래서 *"정의됐나"* 를 따로 든다.
	float  _lfCfgMarS[kLfCfgs][kLfSeeds] = {};
	bool   _lfCfgMarSOk[kLfCfgs][kLfSeeds] = {};
	// 🔎 **기제가 발화했나** — 설정마다 만들어진 유사 변 수. ⚠️ 0 이면 그 팔은 **다른 실험**이다.
	//   ★ 실측으로 밟았다(35차): `엄선` 이 유사 변을 **0개** 만들었는데 판정문이 그 합계를
	//     *"선별이 값을 안 한다"* 로 읽었다 — 기제가 안 돈 팔의 숫자를 기제의 판정으로 쓴 것이다.
	uint32 _lfCfgSimE[kLfCfgs] = {};
	uint32 _lfCfgTransitionCells[kLfCfgs] = {};
	// 🙈 **가린 전이에서의 성능** — 이것이 *"안 본 연결을 연결이 만들었나"* 의 자리다.
	float  _lfCfgF1Seen[kLfCfgs] = {}, _lfCfgF1Hid[kLfCfgs] = {};
	float  _lfCfgF1HidS[kLfCfgs][kLfSeeds] = {};
	uint32 _lfCfgHidN[kLfCfgs] = {};
	// 🔬 **74% 천장을 쪼갠다** — 기권(길이 없다) vs 틀림(옮겼는데 틀렸다) · 형제 있음 vs 고아.
	uint32 _lfCfgHidAbst[kLfCfgs] = {}, _lfCfgHidWrong[kLfCfgs] = {};
	uint32 _lfCfgOrphN[kLfCfgs] = {};
	float  _lfCfgF1Sib[kLfCfgs] = {}, _lfCfgF1Orph[kLfCfgs] = {};
	// 🔍 **틀림이 어디에 몰리나** — 전 규모·전 씨앗 합(⚠️ `상관` 은 뺀다: 기권 95%라 잡음만 준다).
	uint32 _lfAxOk[MLLife::kAxes] = {}, _lfAxBad[MLLife::kAxes] = {};
	uint32 _lfDOk[MLLife::kVals] = {}, _lfDBad[MLLife::kVals] = {};
	uint32 _lfCfgSimSame[kLfCfgs] = {}, _lfCfgSimCross[kLfCfgs] = {};
	int    _lfMaskedActs = 0;
	uint32 _lfCfgContextN[kLfCfgs] = {}, _lfCfgContextHit[kLfCfgs] = {};
	// 🧬 형제 폴백의 발화량 — 0 이면 *"공유를 잰 것이 아니다"*(함정 101).
	uint32 _lfCfgSibFired[kLfCfgs] = {}, _lfCfgSibRead[kLfCfgs] = {};
	// 🪙 **설정마다의 개입 렌더** — 배분 판정의 **전제**다(비용이 다르면 판정불가).
	uint32 _lfCfgInterv[kLfCfgs] = {}; int _lfCfgIntervN[kLfCfgs] = {};
	uint32 _lfCfgCtx2[kLfCfgs] = {};     // 🧩 조합 앵커가 답한 수(발화 검사 · 함정 101)
	int    _lfCfgFree[kLfCfgs] = {};     // 틀림이 안 늘고 맞춤이 늘었다(비율 무한 — 좋은 쪽)
	int    _lfCfgBad[kLfCfgs] = {};      // 맞춤도 안 늘었다(비율 0 — 나쁜 쪽)
	int    _lfSeedIdx = 0;
	float  _lfRepMargin[kLfSeeds] = {};      // 씨앗마다의 여유(고정 문턱에서)
	float  _lfRepHit[kLfSeeds] = {}, _lfRepMiss[kLfSeeds] = {};
	float  _lfBad[MLLife::kArms] = {};
	uint32 _lfInterv[MLLife::kArms] = {};
	uint32 _lfJudgeOracle = 0;   // ⚠️ **평가용 오라클** — 실험의 외부 접촉과 **안 섞는다**
	static constexpr int kLfPerFrame = 6;

	void _TickLife()
	{
		if (_lfStage >= 2) return;
		if (_lfStage == 0)
		{
			_lfStage = 1;
			_lfCfg = 0; _lfSeedIdx = 0; _lfArm = MLLife::kArmMemTest;
			// ⚠️ `암기만` 팔은 늘 판정불가다(시험이 없으면 방향이 안 생긴다) ⇒ 24회를 아끼려 뺀다.
			//   ★ 그 팔의 뜻(*"기억만으로는 예측이 성립하지 않는다"*)은 20차까지 확인됐다.
			_lfLife.Reset(_lfArm, _LfSeedOf(0), _LfCfgScale(0), _LfCfgSim(0));
			LogA("\n[ml] 🌱 **D3 · 생명주기** — 기억 → 가설 → 예측 → (일부만) 외부 평가 → 내부 재생\n"
				"[ml]   시간 배분 %d틱: 학습 **%d** · 시험 **%d** · 정리 **%d**\n"
				"[ml]   ★ 정리가 가장 크다 — 그 시간을 **재학습이 아니라** 가설 생성·모순 탐색·\n"
				"[ml]     연결 재조합에 쓴다. 그것이 *\"연결이 연결을 만든다\"* 의 본체다.\n"
				"[ml]   ⚠️ 외부 평가는 **부분적·지연·인색**하다: 그 항목 하나만 · 다음 틱에 · 최대 %u번\n"
				"[ml]   ⚠️⚠️ **가중치를 안 쓴다** — 이 실험이 묻는 것은 학습량이 아니라 **생명주기의 구조**다\n",
				MLLife::kTicks, MLLife::kLearnTicks, MLLife::kTestTicks, MLLife::kConsolidTicks,
				MLLife::kEvalBudget);
			return;
		}

		for (int i = 0; i < kLfPerFrame; ++i)
		{
			if (_lfLife.Tick()) continue;
			// ── 이 팔이 끝났다 → 재고 다음 팔로 ──
			_lfIn[_lfArm] = _lfLife.InSample(_lfJudgeOracle, 1.0f);
			_lfTr[_lfArm] = _lfLife.Transfer(12u, _lfJudgeOracle, 1.0f);
			// 🌗 **신뢰를 훑는다** — 표는 그대로 두고 **쓰는 법만** 바꾼다(성격 λ 와 같은 구조).
			for (int q = 0; q < kLfTrust; ++q)
				_lfTrTr[_lfArm][q] = _lfLife.Transfer(12u, _lfJudgeOracle, _LfTrustOf(q));
			_lfInf[_lfArm] = _lfLife.InferredAcc(_lfJudgeOracle, _lfInfN[_lfArm]);
			_lfExt[_lfArm] = _lfLife.ExtTouch();
			_lfLearn[_lfArm] = _lfLife.LearnTouch();
			_lfEval[_lfArm] = _lfLife.EvalTouch();
			_lfTruthW[_lfArm] = _lfLife.ConsolidTruthWrites();
			_lfInferred[_lfArm] = _lfLife.Inferred();
			_lfBad[_lfArm] = _lfLife.BadAmplify();
			_lfCfgSimE[_lfCfg] += _lfLife.SimMade();
			_lfCfgCtx2[_lfCfg] += _lfLife.Ctx2Fired();
			_lfCfgInterv[_lfCfg] += _lfLife.Interv();
			_lfCfgIntervN[_lfCfg]++;
			_lfCfgSibFired[_lfCfg] += _lfLife.CtxSibFired();
			_lfCfgSibRead[_lfCfg] += _lfLife.CtxSibRead();
			_lfCfgSimSame[_lfCfg] += _lfLife.SimSameAxis();
			_lfCfgSimCross[_lfCfg] += _lfLife.SimCrossAxis();
			_lfMaskedActs = _lfLife.MaskedActs();
			_lfCfgTransitionCells[_lfCfg] += _lfLife.TransitionKinds();
			_lfInterv[_lfArm] = _lfLife.Interv();
			_lfLife.Census(_lfCExp[_lfArm], _lfCGuess[_lfArm], _lfCAvF[_lfArm], _lfCObs[_lfArm]);
			LogA("[ml]   %-16s 일화 %llu · 외부접촉 %u(경험 %u + 피드백 %u) · 가설 %u · 재생 %u\n"
				"[ml]      🔎 (축값→사실) %u칸 — 겪음 **%u** · 가설만 **%u** · 상태있음 %u · Observed 전체 %u\n",
				MLLife::ArmName(_lfArm), (unsigned long long)_lfLife.Episodes(),
				_lfExt[_lfArm], _lfLearn[_lfArm], _lfEval[_lfArm],
				_lfInferred[_lfArm], _lfLife.Replays(),
				(uint32)(MLLife::kAV * MLFacts::kFacts),
				_lfCExp[_lfArm], _lfCGuess[_lfArm], _lfCAvF[_lfArm], _lfCObs[_lfArm]);
			// 손잡이가 실제로 도는지 센다. 앞 실행에서 `kRecallPerTick` 을 3 으로 올렸는데
			//   모든 숫자가 완전히 동일했다 -> argmax 가 셋을 같은 노드로 접었다(함정 60 재발).
			//   그때 이 수치가 없어서 "왜 안 늘었나" 를 추론으로 좁혀야 했다.
			LogA("[ml]      🚶 걸음 %u회 · 외부평가 맞다 %u / 아니다 %u · 되돌리기 스캔 %u회 → 되돌린 결론 %u개\n",
				_lfLife.Walks(), _lfLife.EvalYes(), _lfLife.EvalNo(),
				_lfLife.UndoScans(), _lfLife.Undone());
			// 🔬 **개입 회계** — 자기 실행이지만 공짜가 아니다 ⇒ 외부 접촉과 **따로** 찍는다.
			//   ⚠️ 유사 변 수만 찍으면 *"몇 번 돌려서 얻은 것인가"* 가 안 보인다(함정 69 의 규칙).
			LogA("[ml]      🔬 개입 유사 %u개(되돌림 %u) · 전이기억 **고유칸 %u/사실관측 %u** · **개입 성공렌더 %u회**(사건 %u) · 🌫️ 의심 올림 %u\n"
				"[ml]      🔗 잇게해준것 조건: 막음 %u(그중 **인코딩 조합 %u**) · 통과 %u"
				" · 무조건통과 %u · 안재봄 %u → **막은 비율 %.1f%%**\n",
				_lfLife.SimMade(), _lfLife.SimDropped(), _lfLife.TransitionKinds(), _lfLife.TransitionObs(),
				_lfLife.Interv(), _lfLife.IntervPairs(), _lfLife.DoubtRaised(),
				_lfLife.ViaBlock(), _lfLife.ViaBlockEnc(), _lfLife.ViaPass(),
				_lfLife.ViaSkip(), _lfLife.ViaUnmeas(),
				(double)(100.0 * (double)_lfLife.ViaBlock()
					/ (double)((_lfLife.ViaBlock() + _lfLife.ViaPass()) > 0u
						? (_lfLife.ViaBlock() + _lfLife.ViaPass()) : 1u)));
			// 🌫️ **흐림 패턴 분포** — *흐림 세 갈래* 의 실측판. ⚠️ "모순" 이라는 이름은 쓰지 않는다:
			//   그것은 기술의 성질이지 세계의 성질이 아니고, 이름이 코드에 특별 분기를 만들었다.
			//   ★ 남는 것은 데이터 모양뿐이고, **조치가 다른 것이 패턴을 가르는 이유**다:
			//     겪음없음 → 자기 실행 · 겪음적음 → 더 겪는다 · 갈림 → 물음이 덜 좁다(믿지 말 것) ·
			//     상상만 → **외부에 묻는다**(나로는 절대 못 안다) · 굳음 → 쓴다
			{
				uint32 hz[5] = {};
				_lfLife.HazeCensus(hz);
				LogA("[ml]      🌫️ 흐림: 겪음없음 %u · 겪음적음 %u · 갈림 %u · 상상만 %u · 굳음 %u\n",
					hz[0], hz[1], hz[2], hz[3], hz[4]);
				// 🌫️ **상상 칸이 몇 번씩 갈렸나** — 문턱이 가를 수 있는지를 눈으로 본다.
				uint32 sp[5] = {};
				_lfLife.SplitCensus(sp);
				LogA("[ml]      🌫️ 상상의 갈림 횟수: 0회 %u · 1회 %u · 2~3회 %u · 4~10회 %u · 11회+ %u\n",
					sp[0], sp[1], sp[2], sp[3], sp[4]);
			}
			_lfArm++;
			if (_lfArm >= MLLife::kArms)
			{
				// 📐 이 (설정, 씨앗) 의 순이득 여유를 적는다(고정 문턱에서).
				{
					const int q = kLfFixIdx;
					_lfCfgMacro[_lfCfg] += _lfTrTr[MLLife::kArmFull][q].macroF1;
					_lfCfgF1Seen[_lfCfg] += _lfTrTr[MLLife::kArmFull][q].seen.f1;
					_lfCfgF1Hid[_lfCfg] += _lfTrTr[MLLife::kArmFull][q].hidden.f1;
					{
						const MLLife::Acc& fa = _lfTrTr[MLLife::kArmFull][q];
						_lfCfgHidN[_lfCfg] += fa.hidden.all;
						_lfCfgHidAbst[_lfCfg] += fa.hidden.unknownMove + fa.hidden.unknownStay;
						_lfCfgHidWrong[_lfCfg] += fa.hidden.bySign[1] + fa.hidden.bySign[3];
						_lfCfgOrphN[_lfCfg] += fa.hiddenOrph.all;
						_lfCfgF1Sib[_lfCfg] += fa.hiddenSib.f1;
						_lfCfgF1Orph[_lfCfg] += fa.hiddenOrph.f1;
						// 🔍 축별·거리별 — 세계의 성질을 묻는 칸이라 갈래를 합친다(상관만 뺀다).
						if (_LfCfgSim(_lfCfg) != MLLife::kSimHub)
						{
							for (int ax = 0; ax < MLLife::kAxes; ++ax)
							{ _lfAxOk[ax] += fa.hidAxOk[ax]; _lfAxBad[ax] += fa.hidAxBad[ax]; }
							for (int dd = 0; dd < MLLife::kVals; ++dd)
							{ _lfDOk[dd] += fa.hidDOk[dd]; _lfDBad[dd] += fa.hidDBad[dd]; }
						}
					}
					if (_lfSeedIdx >= 0 && _lfSeedIdx < kLfSeeds)
						_lfCfgF1HidS[_lfCfg][_lfSeedIdx] = _lfTrTr[MLLife::kArmFull][q].hidden.f1;
					_lfCfgMemMacro[_lfCfg] += _lfTrTr[MLLife::kArmMemTest][q].macroF1;
					_lfCfgMoveP[_lfCfg] += _lfTrTr[MLLife::kArmFull][q].movePrecision;
					_lfCfgMoveR[_lfCfg] += _lfTrTr[MLLife::kArmFull][q].moveRecall;
					_lfCfgContextN[_lfCfg] += _lfTrTr[MLLife::kArmFull][q].contextN;
					_lfCfgContextHit[_lfCfg] += _lfTrTr[MLLife::kArmFull][q].contextHit;
					_lfCfgAbsN[_lfCfg]++;
					if (_lfSeedIdx >= 0 && _lfSeedIdx < kLfSeeds)
						_lfCfgMacroS[_lfCfg][_lfSeedIdx] = _lfTrTr[MLLife::kArmFull][q].macroF1;
					const float bh = _lfTrTr[MLLife::kArmMemTest][q].hits;
					const float bm = (float)_lfTrTr[MLLife::kArmMemTest][q].n - bh;
					const float h = _lfTrTr[MLLife::kArmFull][q].hits;
					const float m = (float)_lfTrTr[MLLife::kArmFull][q].n - h;
					const float dh = h - bh, dm = m - bm;
					// ⚠️⚠️ **정의되지 않는 여유를 임의 수로 누르지 않는다.**
					//   실측으로 거짓 양성을 만들었다: `맞춘 +25 · 틀린 −1` 은 `dm > 0` 이 아니라
					//   `999` 가 됐고 그것을 평균에 **20** 으로 눌러 넣어 문턱을 넘겨 **"통과"** 로 찍혔다.
					//   ★ `틀린 −1` 은 *"틀린 칸이 줄었다"* 는 좋은 결과이지만 **비율이 정의되지 않는다**
					//     (분모가 0 이하다) ⇒ **개수를 밝히고 평균에서 뺀다**(함정 38 계열).
					//   ⚠️ 그리고 그것이 판정을 뒤집었으므로 **결과보다 계측을 먼저 고친다.**
					_lfCfgHit[_lfCfg] += dh; _lfCfgMiss[_lfCfg] += dm;
					if (_lfSeedIdx >= 0 && _lfSeedIdx < kLfSeeds && dm > 0.0f)
					{
						_lfCfgMarS[_lfCfg][_lfSeedIdx] = dh / dm;
						_lfCfgMarSOk[_lfCfg][_lfSeedIdx] = true;
					}
					if (dm > 0.0f)
					{
						_lfCfgMar[_lfCfg] += dh / dm;
						_lfCfgN[_lfCfg]++;
					}
					else if (dh > 0.0f) _lfCfgFree[_lfCfg]++;   // 틀림이 안 늘고 맞춤이 늘었다(공짜)
					else _lfCfgBad[_lfCfg]++;                   // 맞춤도 안 늘었다
					const float mg = (dm > 0.0f) ? (dh / dm) : ((dh > 0.0f) ? 999.0f : 0.0f);
					// 📊 **부호로 쪼갠 증가** — *"움직인다"* 를 새로 맞힌 것이 진짜 새 인과다.
					//   ⚠️ *"안 움직인다"* 는 **다수 클래스(83%)** 라 퍼뜨리면 거의 공짜로 맞는다.
					{
						const uint32* bb = _lfTrTr[MLLife::kArmMemTest][q].bySign;
						const uint32* ff = _lfTrTr[MLLife::kArmFull][q].bySign;
						LogA("[ml]      📊 부호별 증가 — 움직인다 맞춘 %+d / 틀린 %+d ·"
							" 안움직인다 맞춘 %+d / 틀린 %+d\n",
							(int)ff[0] - (int)bb[0], (int)ff[1] - (int)bb[1],
							(int)ff[2] - (int)bb[2], (int)ff[3] - (int)bb[3]);
						LogA("[ml]      🎯 TP/FP/TN/FN %u/%u/%u/%u → %u/%u/%u/%u ·"
							" move 재현 %.1f%%→%.1f%% · macro-F1 %.1f%%→%.1f%%\n",
							bb[0], bb[1], bb[2], bb[3], ff[0], ff[1], ff[2], ff[3],
							(double)(100.0f * _lfTrTr[MLLife::kArmMemTest][q].moveRecall),
							(double)(100.0f * _lfTrTr[MLLife::kArmFull][q].moveRecall),
							(double)(100.0f * _lfTrTr[MLLife::kArmMemTest][q].macroF1),
							(double)(100.0f * _lfTrTr[MLLife::kArmFull][q].macroF1));
					}
					LogA("[ml]   📐 경험 %d · 갈래 %s · 씨앗 %u → 맞춘 %+.1f · 틀린 %+.1f → **%.1f : 1**\n",
						_LfCfgScale(_lfCfg) * MLLife::kLearnTicks,
						MLLife::SimName(_LfCfgSim(_lfCfg)),
						_LfSeedOf(_lfSeedIdx), (double)dh, (double)dm, (double)mg);
				}
				_lfSeedIdx++;
				if (_lfSeedIdx >= kLfSeedsUse)
				{
					_lfSeedIdx = 0; _lfCfg++;
					if (_lfCfg >= kLfCfgs) { _lfStage = 2; _JudgeLife(); return; }
				}
				_lfArm = MLLife::kArmMemTest;
				_lfLife.Reset(_lfArm, _LfSeedOf(_lfSeedIdx), _LfCfgScale(_lfCfg), _LfCfgSim(_lfCfg));
				return;
			}
			// ★ **씨앗과 설정을 같게 준다** — 팔끼리 다른 것은 **모드뿐**이어야 한다.
			_lfLife.Reset(_lfArm, _LfSeedOf(_lfSeedIdx), _LfCfgScale(_lfCfg), _LfCfgSim(_lfCfg));
			return;
		}
	}

	void _JudgeLife()
	{
		// ⚠️⚠️ **우연은 50%가 아니다** — 예측 기본값이 *"안 움직인다"* 이고 인과가 희소해서
		//   **전부 안 움직인다고 답하면 83%** 였다(1차 실측). ⇒ **정규화 이득**으로 판정한다:
		//   `(값 − 다수클래스) / (1 − 다수클래스)` — 이 저장소의 보편 척도다.
		//   ★ 그리고 **아는 칸만** 골라 잰다(모름을 밀어넣으면 다수 클래스로 붕괴한다) ⇒ 커버리지를 같이 찍는다.
		LogA("\n[ml] 🌱 **마지막 실행 진단** — 집계표가 아니다(경험 %d · %s · 씨앗 %u)\n"
			"[ml]   *\"연결이 연결을 만들었나\"* 는 아래 규모×갈래×씨앗 집계와 따로 읽는다.\n"
			"[ml]   ⚠️ 우연은 50%%가 아니다 — 답한 부분집합의 다수 클래스가 **%.0f%%** 다 ⇒ **정규화 이득**으로 본다.\n"
			"[ml]   %-16s %18s %18s %7s %7s %8s %7s %7s %7s\n",
			_LfCfgScale(kLfCfgs - 1) * MLLife::kLearnTicks,
			MLLife::SimName(_LfCfgSim(kLfCfgs - 1)), _LfSeedOf(kLfSeedsUse - 1),
			(double)(100.0f * _lfTr[MLLife::kArmMemTest].base),
			"팔", "암기(이득·아는칸)", "전이(이득·아는칸)", "맞춘칸", "틀린칸", "새연결", "접촉", "가설", "증폭");
		// ⚠️⚠️ **분모가 0 이면 값을 찍지 않는다 — `판정불가` 다.**
		//   실측으로 밟았다(2차): 아는 칸이 **0/624** 인 팔에 `−494.3%` 가 찍혔고 그것이
		//   *"아주 나쁘다"* 로 읽혔다. 실제로는 **예측을 하나도 안 한 것**이다(시험을 안 하는 팔이니 당연하다).
		//   ★ 함정 38 과 같은 부류(*"오답 0개면 오답의 분포는 정의되지 않는다"*).
		for (int a = 0; a < MLLife::kArms; ++a)
		{
			LogA("[ml]   %-16s", MLLife::ArmName(a));
			if (_lfIn[a].n > 0u) LogA(" %+7.1f%%", (double)(100.0f * _lfIn[a].norm));
			else                 LogA("  판정불가");
			LogA(" %4u/%-5u", _lfIn[a].n, _lfIn[a].all);
			if (_lfTr[a].n > 0u) LogA(" %+7.1f%%", (double)(100.0f * _lfTr[a].norm));
			else                 LogA("  판정불가");
			LogA(" %4u/%-5u %7.1f %7.1f %6.1f%% %7u %7u %6.1f%%\n",
				_lfTr[a].n, _lfTr[a].all, (double)_lfTr[a].hits,
				(double)((float)_lfTr[a].n - _lfTr[a].hits),
				(double)(100.0f * _lfInf[a]), _lfExt[a], _lfInfN[a],
				(double)(100.0f * _lfBad[a]));
		}
		LogA("[ml]   ★ `이득` = 정규화 이득(0%% = 다수 클래스와 같다 · 100%% = 완벽) · `아는칸` = 예측한/전체\n"
			"[ml]   ★ `가설` = **평가 가능한** 가설 수(축값→사실 형태) — 1차엔 123개 중 **0개**였다\n"
			"[ml]     ⚠️ 쓸 수 없는 가설을 세는 것은 *\"많이 생각했다\"* 는 착각만 준다.\n"
			"[ml]   ⚠️ 평가용 오라클 %u회는 **실험의 외부 접촉과 따로** 센다(섞으면 팔 비교가 거짓이 된다).\n",
			_lfJudgeOracle);

		// ── ⓵ 환각 안전장치 ─────────────────────────────────────────────
		//   ⚠️⚠️⚠️ 기준을 미리 못박았다: **정리가 `truth` 를 올린 횟수 = 0.**
		//     ★ 규칙을 주석에만 적으면 다음 사람이 깬다 — 세어서 보여야 지켜진다.
		uint32 tw = 0;
		for (int a = 0; a < MLLife::kArms; ++a) tw += _lfTruthW[a];
		LogA("[ml]   ⛔ **환각 안전장치**: 정리가 **의심을 내린** 횟수 = **%u** (0 이어야 한다) → %s\n"
			"[ml]      ★ 내부에서 여러 번 생각했다고 **의심이 내려가면 안 된다.**\n"
			"[ml]        정리에서 오를 수 있는 것은 **기억의 접근성/연결 강도**뿐이고,\n"
			"[ml]        의심은 **새로운 외부 증거**를 받아야 내려간다.\n"
			"[ml]        ⇒ 안 그러면 %d%%의 정리 시간이 **자기 확신을 증폭하는 환각 루프**가 된다.\n"
			"[ml]      ★ 그리고 **뒤집으면 표현이 하나 늘어난다**: 정리는 의심을 **올릴 수 있다** —\n"
			"[ml]        걷다가 반대 결론을 만나면 **의문이 커지는 것**이 실제 사유의 모습이고,\n"
			"[ml]        `truth` 로는 그 자리가 아예 없었다(올리면 환각 · 내리는 것은 뜻이 없다).\n",
			tw, (tw == 0u) ? "통과" : "★실패★", MLLife::kConsolidTicks);

		// ── ⓶ 잘못된 연쇄 증폭률 ────────────────────────────────────────
		LogA("[ml]   🧪 **잘못된 연쇄 증폭률** — 반증된 연결이 쥔 강도의 비율\n"
			"[ml]      암기+시험 %.1f%% → 정리까지 %.1f%%\n"
			"[ml]      ⚠️ 강도가 오르는 것 자체는 잘못이 아니다(접근성이다) — 문제는 **틀린 것에 쏠리는 것**이다.\n",
			(double)(100.0f * _lfBad[MLLife::kArmMemTest]), (double)(100.0f * _lfBad[MLLife::kArmFull]));

		// ── ⓷ 본 판정 ───────────────────────────────────────────────────
		//   ⚠️ 기준을 미리 못박았다(설계가 준 것): **마지막 팔만 적은 외부 접촉으로
		//     새로운 관계를 더 잘 맞히면** 그때 *"연결이 연결을 만들었다"* 고 말할 수 있다.
		//   ★ 그래서 두 조건을 **동시에** 본다 — 하나만 보면 *"더 많이 물어서 더 잘 맞혔다"* 와 구별이 안 된다.
		// ★ **정규화 이득으로** 견준다(원값으로 견주면 다수 클래스가 차이를 삼킨다).
		// ⚠️ 두 팔 다 예측을 했어야 견줄 수 있다(하나가 0이면 비교 자체가 뜻이 없다).
		const bool cmpOk = (_lfTr[MLLife::kArmFull].n > 0u && _lfTr[MLLife::kArmMemTest].n > 0u);
		const float dT = cmpOk
			? (_lfTr[MLLife::kArmFull].norm - _lfTr[MLLife::kArmMemTest].norm) : 0.0f;
		const bool sameCost = (_lfExt[MLLife::kArmFull] <= _lfExt[MLLife::kArmMemTest])
			&& (_lfInterv[MLLife::kArmFull] == _lfInterv[MLLife::kArmMemTest]);
		const bool okChain = (dT > 0.02f) && sameCost;
		// ══════════════════════════════════════════════════════════════════════
		// 🌗 **신뢰 곡선** — 검증 못 한 상상을 얼마나 믿나. **표는 그대로, 쓰는 법만 바뀐다.**
		//   ⚠️ 실측이 요구했다: 외부가 상상에 대해 `맞다 1 / 아니다 9` 라고 했는데 예측은 그것을
		//     **겪은 것과 같은 무게**로 썼다 ⇒ 커버리지 2.76배인데 틀린 칸이 10 → 124 였다.
		//   ★ 기준을 미리 못박는다: **여유(맞춘 증가 / 틀린 증가)의 최대점이 내부**에 있어야
		//     `trust` 가 성격 축이다. 끝점이면 *"상상은 늘 믿어라/늘 버려라"* 이고 손잡이가 아니다.
		LogA("[ml]   🌫️ **갈림 문턱**(결론이 몇 번까지 갈린 것을 답에 쓰나) — 표는 그대로, **쓰는 법만** 바뀐다\n"
			"[ml]      ★ 의심의 출처를 **갈랐다**: ① 근거가 약해서(*\"잘 모르겠음\"*) ·\n"
			"[ml]        ② **결론이 갈려서**(*\"의문\"* · 16차에 143,620회) — 조치가 다르므로 다른 값이다:\n"
			"[ml]        ① 높으면 **더 겪어라** · ② 높으면 **쓰지 마라**(경로가 서로 안 맞는다).\n"
			"[ml]      ⚠️ 하나로 뭉갠 문턱은 0.95~0.98 에 몰려 분해능이 없었다(함정 80).\n"
			"[ml]      ★ `truth`(진실 확신도)를 걷어냈다 — 그 이름은 **세계에 대한 주장**이고 기계는\n"
			"[ml]        그것을 가질 수 없다. 가질 수 있는 것은 **나에 대한 기술**(의심)뿐이다.\n"
			"[ml]        그리고 생명체에게 믿음은 별개 값이 아니다 — **의심이 없는 상태**가 믿음이다.\n"
			"[ml]      %-14s %8s %8s %8s %8s %8s\n", "갈림≤", "0(0회)", "0.33(1)", "0.50(2)", "0.60(3)", "1.00(전부)");
		for (int a = MLLife::kArmMemTest; a < MLLife::kArms; ++a)
		{
			LogA("[ml]      %-14s", MLLife::ArmName(a));
			for (int q = 0; q < kLfTrust; ++q) LogA(" %8.1f", (double)_lfTrTr[a][q].hits);
			LogA("   (맞춘 칸)\n[ml]      %-14s", "");
			for (int q = 0; q < kLfTrust; ++q)
				LogA(" %8.1f", (double)((float)_lfTrTr[a][q].n - _lfTrTr[a][q].hits));
			LogA("   (틀린 칸)\n");
		}
		{
			// ★ 여유 = (맞춘 증가) / (틀린 증가) — 기준선은 정리 없는 팔의 신뢰 무관 값이다.
			const float bh = _lfTrTr[MLLife::kArmMemTest][0].hits;
			const float bm = (float)_lfTrTr[MLLife::kArmMemTest][0].n - bh;
			int bq = 0; float bestM = -1.0f;
			LogA("[ml]      여유(맞춘증가/틀린증가):");
			for (int q = 0; q < kLfTrust; ++q)
			{
				const float h = _lfTrTr[MLLife::kArmFull][q].hits;
				const float m = (float)_lfTrTr[MLLife::kArmFull][q].n - h;
				const float dh = h - bh, dm = m - bm;
				const float mg = (dm > 0.0f) ? (dh / dm) : ((dh > 0.0f) ? 999.0f : 0.0f);
				LogA(" %.1f", (double)mg);
				if (mg > bestM && mg < 900.0f) { bestM = mg; bq = q; }
			}
			const bool interior = (bq > 0 && bq < kLfTrust - 1);
			LogA("\n[ml]      🌫️ 최대 여유 갈림문턱 = **%.2f**%s · 기준: 최대점이 **내부** → %s\n"
				"[ml]      ★ 이것이 *\"검증 못 한 상상을 어떻게 쓸까\"* 의 답이다 —\n"
				"[ml]        검증 예산이 생성량을 못 따라가는 것은 **기제의 결함이 아니다**\n"
				"[ml]        (생명체도 대부분의 추측을 평생 검증하지 못한다) ⇒ 남는 문제는 **쓰는 법**이다.\n"
				"[ml]      ⚠️ 문턱 1.00 = 갈린 것도 다 쓴다(넓지만 틀림 많음) ·\n"
				"[ml]        0.00 = 한 번도 안 갈린 것만 쓴다(좁지만 정확). ★ 그 사이가 **의문의 값**이다.\n",
				(double)_LfTrustOf(bq), interior ? "(내부)" : "(**끝점** — 손잡이가 아니다)",
				interior ? "통과(신뢰가 성격 축이다)" : "★판정 보류★");
		}

		// ══════════════════════════════════════════════════════════════════════
		// 🎯 **절대 인과 성능** — 증분 여유와 갈라 센다.
		//   시험에서 관측을 즉시 보존하는 팔은 `정리−시험`이 0이어도 이미 높은 성능일 수 있다.
		LogA("[ml]   🎯 **절대 전이 성능**(4씨앗 평균 · 모름도 miss인 macro-F1)\n"
			"[ml]      🙈 가린 전이 **%d개**(유효 22개 중) — 테이프·시험·외부질문·짝개입이 안 만진다\n"
			"[ml]      %-8s %-12s %9s %9s %9s %9s %10s %10s\n",
			_lfMaskedActs,
			"경험", "갈래", "시험 F1", "정리 F1", "move P", "move R", "본행동 F1", "**가린 F1**");
		for (int sc = 0; sc < kLfScales; ++sc)
			for (int k = 0; k < kLfSims; ++k)
			{
				const int c = sc * kLfSims + k;
				const float n = (float)((_lfCfgAbsN[c] > 0) ? _lfCfgAbsN[c] : 1);
				LogA("[ml]      %-8d %-12s %8.1f%% %8.1f%% %8.1f%% %8.1f%% %9.1f%% %9.1f%%\n",
					_LfScaleOf(sc) * MLLife::kLearnTicks, MLLife::SimName(k),
					(double)(100.0f * _lfCfgMemMacro[c] / n),
					(double)(100.0f * _lfCfgMacro[c] / n),
					(double)(100.0f * _lfCfgMoveP[c] / n),
					(double)(100.0f * _lfCfgMoveR[c] / n),
					(double)(100.0f * _lfCfgF1Seen[c] / n),
					(double)(100.0f * _lfCfgF1Hid[c] / n));
			}

		// ══════════════════════════════════════════════════════════════════════
		// 🌱 **재현 판정** — 문턱을 못박고 씨앗을 바꿔도 여유가 유지되나.
		//   ⚠️ 기준을 미리 못박았다: **씨앗 4개 중 3개 이상**에서 여유가 **2:1 이상**.
		//     ★ 근거: 하나만 넘으면 그 씨앗의 우연과 구별되지 않는다(18차가 그 상태다).
		// ══════════════════════════════════════════════════════════════════════
		// ⚖️ **주 판정 = 순이득**(함정 85 의 조치).
		//   ⚠️ 앞서는 `전이 이득률` 을 주 판정으로 뒀는데 그것은 **비율**이라
		//     커버리지가 3.5배로 늘면 상대 정확도가 내려가 **적용 범위 확장을 벌한다.**
		//     20차에서 순이득 8:1 · 재현 4/4 인데 주 판정만 −25.1%p 로 실패였다.
		//   ★ 이득률은 **참고**로 남긴다(정확도가 무너지는 것을 잡아 주는 역할은 있다).
		LogA("[ml]   📐 **경험 규모 × 갈래** — *\"몇 번의 경험부터 배운 유사가 값을 하나\"*\n"
			"[ml]      ⚠️ 피드백 예산은 **10회로 고정**했다 — 경험만 늘려야 질문이 성립한다.\n"
			"[ml]      ⚠️ 비율이 정의되는 경우만 평균한다(`틀림 증가 > 0`) — 나머지는 개수로 적는다:\n"
			"[ml]        `공짜` = 틀림이 안 늘고 맞춤이 늘었다(좋은 쪽) · `헛` = 맞춤도 안 늘었다(나쁜 쪽)\n"
			"[ml]        ★ 앞서 무한을 **20 으로 눌러** 평균에 넣었더니 **거짓 양성**이 나왔다(함정 38 계열).\n"
			"[ml]      %-8s  (평균 : 공짜/헛)  ⇒  %s · %s · %s · %s · %s · %s · %s · %s\n", "경험",
			MLLife::SimName(MLLife::kSimNone), MLLife::SimName(MLLife::kSimInterv),
			MLLife::SimName(MLLife::kSimHub), MLLife::SimName(MLLife::kSimComb),
			MLLife::SimName(MLLife::kSimDilute), MLLife::SimName(MLLife::kSimStrict),
			MLLife::SimName(MLLife::kSimTransition), MLLife::SimName(MLLife::kSimEvent));
		for (int sc = 0; sc < kLfScales; ++sc)
		{
			LogA("[ml]      %-8d", _LfScaleOf(sc) * MLLife::kLearnTicks);
			for (int k = 0; k < kLfSims; ++k)
			{
				const int c = sc * kLfSims + k;
				const float m = (_lfCfgN[c] > 0) ? (_lfCfgMar[c] / (float)_lfCfgN[c]) : 0.0f;
				LogA(" %8.1f:%2d/%-2d", (double)m, _lfCfgFree[c], _lfCfgBad[c]);
			}
			LogA("\n");
		}
		// ══════════════════════════════════════════════════════════════════════
		// ⚖️⚖️ **함정 90 의 판정** — *"쓰지 않는 연결도 비용이다"* 가 맞았나.
		//   26차의 상관 루트는 맞춘 칸이 **6/6 음수**였고(−16 −14 −45 −22 −23 −32),
		//   그때와 지금 다른 것은 **강도를 주지 않는 것뿐**이다.
		//   ⇒ **양수로 돌면** 표 오염이 기제였다(함정 90 이 맞다) ·
		//     **그대로 음수면** 진단이 틀렸고 원인은 **전이의 질**이다.
		// ⚠️ 여기서 보는 것은 비율이 아니라 **맞춘 칸의 부호**다 — 26차와 견줄 수 있는 값이 그것이다.
		// ══════════════════════════════════════════════════════════════════════
		LogA("[ml]      ⚖️ **정리로 늘어난 맞춘 사건(4씨앗 합)** — 절대 맞춤이 아니라 Full−MemTest 증분이다\n"
			"[ml]         같은 관계를 여러 probe에서 재므로 고유 칸 수는 아니다\n"
			"[ml]         %-8s %10s %10s %10s %10s %10s %10s %12s %12s\n",
			"경험", "끔 증분", "개입차", "상관차", "조합차", "희석차", "엄선차",
			"전이기억차", "사건앵커차");
		{
			bool hubPos = false;
			float combSum = 0.0f, ivSum = 0.0f, dilSum = 0.0f, strSum = 0.0f;
			for (int sc = 0; sc < kLfScales; ++sc)
			{
				const float off = _lfCfgHit[sc * kLfSims];
				const float dIv = _lfCfgHit[sc * kLfSims + 1] - off;
				const float dHb = _lfCfgHit[sc * kLfSims + 2] - off;
				const float dCb = _lfCfgHit[sc * kLfSims + 3] - off;
				const float dDl = _lfCfgHit[sc * kLfSims + 4] - off;
				const float dSt = _lfCfgHit[sc * kLfSims + 5] - off;
				const float dTr = _lfCfgHit[sc * kLfSims + MLLife::kSimTransition] - off;
				const float dEv = _lfCfgHit[sc * kLfSims + MLLife::kSimEvent] - off;
				if (dHb > 0.0f) hubPos = true;
				ivSum += dIv; combSum += dCb; dilSum += dDl; strSum += dSt;
				LogA("[ml]         %-8d %10.1f %+10.1f %+10.1f %+10.1f %+10.1f %+10.1f %+12.1f %+12.1f\n",
					_LfScaleOf(sc) * MLLife::kLearnTicks, (double)off,
					(double)dIv, (double)dHb, (double)dCb, (double)dDl, (double)dSt, (double)dTr, (double)dEv);
			}
			LogA("[ml]         ⇒ 함정 90: %s\n",
				hubPos
					? "상관도 강도를 빼면 맞춘 칸이 늘었다 → **함정 90 이 맞다**(표 오염이 기제였다)"
					: "강도를 빼도 상관은 여전히 맞춘 칸을 줄인다 → **함정 90 의 진단은 틀렸다**"
					  "(원인은 표 오염이 아니라 **전이의 질**이다)");
			// ══════════════════════════════════════════════════════════════════
			// 🧩 **조합 판정** — 인코딩 유사의 **무조건 통과**가 검사 안 된 허가증이었나.
			//   ⚠️ 두 방향 다 뜻이 있다(어느 쪽이든 배운다):
			//     · 조합이 **개입(짝)보다 낫다** ⇒ 무조건 통과가 **범위 밖 전이를 실어 주고 있었다**
			//       ⇒ 허가의 단위는 **조합**이 맞다(그리고 `끔` 팔의 여유는 그만큼 부풀어 있었다)
			//     · 조합이 **더 나쁘다** ⇒ 채널이 준 통과는 실제로 범위 안이었고,
			//       개입 3장면이 그것을 **좁히기만** 했다 ⇒ 인코딩의 권위가 실측으로 확인된다
			// ══════════════════════════════════════════════════════════════════
			// 🔎 **이득을 둘로 쪼갠다** — `희석` 이 대조군이다.
			//   ㉡ 예산 희석(채널간 유사 변이 줄었다) = `희석 − 개입(짝)`
			//   ㉠ 인코딩 게이트(무조건 통과를 없앴다) = `조합 − 희석`
			// ⚠️⚠️⚠️ **몫을 쪼개기 전에 효과가 있는지 본다** — 함정 101 의 형제다.
			//   ★ 실측으로 밟았다(37차): 학습/평가의 전이 불일치를 고치자 이 세 값이
			//     `개입 +1112 · 희석 +1027 · 조합 +998` 로 뒤집혀 두 몫이 **둘 다 음수**
			//     (희석 −85 · 게이트 −29)가 됐는데, 큰 쪽을 고르는 비교(`−29 > −85`)가
			//     *"게이트가 주된 몫이다 → 조합 논지가 실측으로 선다"* 를 그대로 찍었다.
			//   ⇒ **음수를 쪼개면 "덜 나쁜 쪽" 이 "주된 공로" 로 읽힌다.**
			//   ★ 판정 규칙: ***총 효과의 부호를 먼저 보고, 양수가 아니면 몫을 귀속하지 않는다.***
			//     (함정 100 이 *"씨앗이 모자라면 몫이 잡음이다"* 였고, 이것은 그 앞 단계다 —
			//      **쪼갤 효과가 있는지**를 안 봤다.)
			const float pkgTotal = combSum - ivSum;    // 묶음 총효과(조합 = 개입 + 희석 + 게이트)
			const float shDil = dilSum - ivSum, shGate = combSum - dilSum;
			LogA("[ml]      🧩 **조합 판정** — 허가의 단위를 짝 → (짝+사실) 로 바꿨다\n"
				"[ml]         개입(짝) %+.1f · 희석 %+.1f · 조합 %+.1f → **묶음 총효과 %+.1f**\n"
				"[ml]         ⇒ 예산 희석의 몫 **%+.1f** · 인코딩 게이트의 몫 **%+.1f**\n"
				"[ml]         ⇒ %s\n"
				"[ml]         ★ 유사는 원래 삼자 관계다(**A · B · 잇게 해준 것**) — 짝으로만 물으면\n"
				"[ml]           *\"과일이 함께 있을 때만 유사\"* 를 물어볼 자리가 없다.\n",
				(double)ivSum, (double)dilSum, (double)combSum, (double)pkgTotal,
				(double)shDil, (double)shGate,
				(pkgTotal <= 0.0f)
					? "⛔ **반증** — 조합이 개입(짝)보다 **나쁘다**(총효과 ≤ 0) ⇒ 몫 귀속은 뜻이 없다"
					: ((shGate > shDil)
						? "**게이트가 주된 몫이다** → 허가의 단위가 조합이라는 것이 실측으로 선다"
						: "**예산 희석이 주된 몫이다** → 조합의 통과를 게이트의 공로로 읽으면 틀린다"));
			if (pkgTotal > 0.0f && (shDil < 0.0f || shGate < 0.0f))
				LogA("[ml]         ⚠️ 총효과는 양수인데 **한 몫이 음수**다 —"
					" *\"둘 다 값을 한다\"* 로 읽으면 틀린다.\n");
			// ══════════════════════════════════════════════════════════════════
			// 🎯 **선별 판정** — *"양이 관건인가 선별이 관건인가."*
			//   `엄선` = `조합` 과 **비용·짝·장면이 같고 수락만 엄격**하다
			//   (*"둘 다 가만있었다"* 만으로는 변을 만들지 않는다).
			//   ⇒ `엄선 − 조합` 이 **선별의 몫**이고, 그것이 크면 처방은 *"예산을 줄여라"* 가 아니라
			//     ***"수락을 엄하게 하라"*** 다. ⚠️ 둘은 다른 처방이므로 갈라야 한다.
			// ══════════════════════════════════════════════════════════════════
			// ⚠️⚠️ **기제가 발화했는지 먼저 본다.** 유사 변이 0개면 그 팔은 선별을 잰 것이 아니라
			//   **다른 실험**(인코딩 게이트 단독)이고, 그 합계를 선별의 판정으로 쓰면 거짓이 된다.
			//   ★ 함정 97 을 **판정문에서** 또 밟은 자리다(값이 안 움직이면 손잡이가 안 물린 것이다).
			{
				uint32 strE = 0, combE = 0;
				for (int sc = 0; sc < kLfScales; ++sc)
				{
					strE += _lfCfgSimE[sc * kLfSims + MLLife::kSimStrict];
					combE += _lfCfgSimE[sc * kLfSims + MLLife::kSimComb];
				}
				LogA("[ml]      🎯 **선별 판정** — 같은 비용, 수락만 엄격하게(`viaMove` 가 비면 안 만든다)\n"
					"[ml]         유사 변: 조합 %u개 · 엄선 %u개 ← **기제가 발화했나**\n"
					"[ml]         (엄선의 축 구성은 아래 🙈 판정에 찍는다 — 채널간인지가 관건이다)\n"
					"[ml]         맞춘 칸: 조합 %+.1f · 엄선 %+.1f\n",
					combE, strE, (double)combSum, (double)strSum);
				if (strE == 0u)
					LogA("[ml]         ⇒ ⚠️ **판정불가** — 엄선의 유사 변이 **0개**다. 이것은 세계의 직교성\n"
						"[ml]            증거가 아니다: 이 팔은 여전히 3문맥 보편-AND와 희소 pair 표본을 요구한다.\n"
						"[ml]            따라서 정확한 뜻은 **그 추정기를 통과한 짝이 0**이라는 것뿐이다.\n");
				else
					LogA("[ml]         ⇒ %s\n"
						"[ml]         ⚠️ 이것은 **맞춘 칸의 합** 하나로 본 것이다 — 아래 씨앗별 판정과\n"
						"[ml]            어긋날 수 있다(실측 37차: 맞춘 칸은 조합 > 엄선인데 씨앗 판정은\n"
						"[ml]            엄선만 통과했다). ★ 둘이 어긋나면 **재현되는 쪽**을 믿는다.\n",
						(strSum > combSum)
							? "**선별이 값을 한다** → 처방은 *\"수락을 엄하게\"* 다"
							: "**선별이 값을 안 한다** → 이 척도에서는 이득이 **양**(예산) 쪽이다");
			}
			{
				LogA("[ml]      🧭 **전이기억 판정** — pair 유사를 만들지 않고 균등 자기실행의 결과를 직접 보존한다\n"
					"[ml]         ⚠️ 효과 앵커나 안 본 전이의 연쇄를 검증하는 팔이 아니다.\n");
				for (int sc = 0; sc < kLfScales; ++sc)
				{
					const int ce = sc * kLfSims + MLLife::kSimTransition;
					const float ne = (float)((_lfCfgAbsN[ce] > 0) ? _lfCfgAbsN[ce] : 1);
					const float ef = _lfCfgMacro[ce] / ne;
					float best = 0.0f;
					for (int k = 0; k < MLLife::kSimTransition; ++k)
					{
						const int c = sc * kLfSims + k;
						const float n = (float)((_lfCfgAbsN[c] > 0) ? _lfCfgAbsN[c] : 1);
						const float v = _lfCfgMacro[c] / n;
						if (v > best) best = v;
					}
					int win = 0;
					for (int q = 0; q < kLfSeedsUse; ++q)
					{
						float sb = 0.0f;
						for (int k = 0; k < MLLife::kSimTransition; ++k)
						{
							const float v = _lfCfgMacroS[sc * kLfSims + k][q];
							if (v > sb) sb = v;
						}
						if (_lfCfgMacroS[ce][q] > sb) win++;
					}
					const float cells = (float)_lfCfgTransitionCells[ce]
						/ (float)(MLLife::kArms - 1) / (float)kLfSeedsUse;
					LogA("[ml]         경험 %d: macro-F1 %.1f%% vs 기존 최고평균 %.1f%% (%+.1f%%p) · 씨앗별 최고 승리 %d/4 · 실행당 고유칸 %.1f\n",
						_LfScaleOf(sc) * MLLife::kLearnTicks, (double)(100.0f * ef), (double)(100.0f * best),
						(double)(100.0f * (ef - best)), win, (double)cells);
				}
				LogA("[ml]         ★ 이 팔의 주 이득은 정리 증분이 아니라 **시험 결과를 버리지 않는 것**에서 난다.\n");
			}
			{
				LogA("[ml]      🌐 **사건앵커 판정** — 전이기억과 같은 고정 테이프, 회수만 다르다\n"
					"[ml]         모든 동시 활성 채널값을 똑같이 기록하고, 반복 지지 ≥3인 가장 일관된 값만 쓴다.\n");
				// 🧬 **형제 폴백이 발화했나** — 함정 101: 기제가 안 돈 팔의 숫자를 기제의 판정으로 쓰지 않는다.
				{
					uint32 fired = 0, readd = 0;
					for (int sc = 0; sc < kLfScales; ++sc)
					{
						fired += _lfCfgSibFired[sc * kLfSims + MLLife::kSimEvent];
						readd += _lfCfgSibRead[sc * kLfSims + MLLife::kSimEvent];
					}
					LogA("[ml]         🧬 형제 폴백: 트리거 %u회 · 문맥표 읽기 %u회 ← **기제가 발화했나**\n",
						fired, readd);
					if (fired == 0u && readd == 0u)
						LogA("[ml]            ⇒ ⚠️ **판정불가** — 형제 공유가 **한 번도 안 돌았다**\n");
				}
				for (int sc = 0; sc < kLfScales; ++sc)
				{
					const int ct = sc * kLfSims + MLLife::kSimTransition;
					const int ce = sc * kLfSims + MLLife::kSimEvent;
					const float nt = (float)((_lfCfgAbsN[ct] > 0) ? _lfCfgAbsN[ct] : 1);
					const float ne = (float)((_lfCfgAbsN[ce] > 0) ? _lfCfgAbsN[ce] : 1);
					const float tr = _lfCfgMacro[ct] / nt, ev = _lfCfgMacro[ce] / ne;
					int win = 0;
					for (int q = 0; q < kLfSeedsUse; ++q)
						if (_lfCfgMacroS[ce][q] > _lfCfgMacroS[ct][q]) win++;
					const float ctxAcc = (_lfCfgContextN[ce] > 0u)
						? (float)_lfCfgContextHit[ce] / (float)_lfCfgContextN[ce] : 0.0f;
					LogA("[ml]         경험 %d: F1 %.1f%% → %.1f%% (%+.1f%%p) · 씨앗 승리 %d/4 · 앵커답 %u개 중 %.1f%% 맞음\n",
						_LfScaleOf(sc) * MLLife::kLearnTicks, (double)(100.0f * tr), (double)(100.0f * ev),
						(double)(100.0f * (ev - tr)), win, _lfCfgContextN[ce], (double)(100.0f * ctxAcc));
				}
			}
			// ══════════════════════════════════════════════════════════════════
			// 🙈 **가린 전이 판정** — *"안 본 연결을 연결이 만들었나."*
			//
			// ★ 이것이 이 실험이 처음부터 물으려던 것이다. 여태 못 물은 이유는
			//   테이프·시험·외부질문이 **132칸을 다 밟아서** *"열거"* 와 *"일반화"* 가 한 숫자에
			//   섞여 있었기 때문이다(함정 106).
			// ⚠️ 가린 행동에 남는 길은 **인코딩 유사 + 정리 걷기**뿐이다:
			//     `색-2 --(인코딩 유사)-- 색-0 --(겪은 전이)--> 사실·색`
			//   ⇒ 그래서 `전이기억`·`사건앵커` 는 여기서 **이길 수단이 없다**(문맥표가 행동으로
			//     색인되므로 가린 행동의 앵커는 비어 있다) — 그것이 **바닥**이고 그게 요점이다.
			// ══════════════════════════════════════════════════════════════════
			{
				LogA("[ml]      🙈 **가린 전이 판정** — 테이프가 못 밟은 행동에서의 macro-F1\n"
					"[ml]         ⚠️ 여기서만 *\"안 본 연결\"* 이 질문이 된다. 씨앗별로 최고를 센다.\n"
					"[ml]         %-8s", "경험");
				for (int k = 0; k < kLfSims; ++k) LogA(" %10s", MLLife::SimName(k));
				LogA("   최고\n");
				for (int sc = 0; sc < kLfScales; ++sc)
				{
					LogA("[ml]         %-8d", _LfScaleOf(sc) * MLLife::kLearnTicks);
					int best = 0; float bestV = -1.0f;
					for (int k = 0; k < kLfSims; ++k)
					{
						const int c = sc * kLfSims + k;
						const float n = (float)((_lfCfgAbsN[c] > 0) ? _lfCfgAbsN[c] : 1);
						const float v = _lfCfgF1Hid[c] / n;
						LogA(" %9.1f%%", (double)(100.0f * v));
						if (v > bestV) { bestV = v; best = k; }
					}
					LogA("   **%s**\n", MLLife::SimName(best));
				}
				// 🌱 씨앗마다 누가 이기나 — 평균이 가리는 것을 본다(함정 99).
				LogA("[ml]         🌱 씨앗별 최고(4중):");
				for (int k = 0; k < kLfSims; ++k)
				{
					int wins = 0;
					for (int sc = 0; sc < kLfScales; ++sc)
						for (int q = 0; q < kLfSeedsUse; ++q)
						{
							float top = -1.0f; int who = -1;
							for (int j = 0; j < kLfSims; ++j)
								if (_lfCfgF1HidS[sc * kLfSims + j][q] > top)
								{ top = _lfCfgF1HidS[sc * kLfSims + j][q]; who = j; }
							if (who == k) wins++;
						}
					LogA(" %s %d/12", MLLife::SimName(k), wins);
				}
				// ══════════════════════════════════════════════════════════════
				// 🪙 **배분 판정** — *"같은 비용을 한 기제에 다 쓰나, 둘로 쪼개 쓰나."*
				//   `사건앵커` = 테이프 **전액**(문맥 앵커만) · `둘다` = 테이프 **절반** + 짝 개입 **절반**
				//   (배운 유사 + 문맥 앵커). ⇒ 렌더 총량이 같으므로 **배분의 효과만** 남는다.
				// ★ 43차에서 둘은 **다른 기제**로 보였다: 배운 유사가 가린 전이에서 `+16.8%p`(끔 대비),
				//   문맥 앵커가 `+5.0%p`(전이기억 대비). 더해지나 겹치나는 **안 쟀다.**
				// ══════════════════════════════════════════════════════════════
				{
					LogA("[ml]         🪙 **배분 판정** — 같은 렌더 예산, 한 기제 전액 vs 둘로 반씩\n"
						"[ml]            %-8s %12s %12s %10s\n",
						"경험", "사건앵커(전액)", "둘다(반씩)", "차");
					int win = 0, tot = 0;
					float rEv = 0.0f, rBo = 0.0f;
					for (int sc = 0; sc < kLfScales; ++sc)
					{
						const int ce = sc * kLfSims + MLLife::kSimEvent;
						const int cb = sc * kLfSims + MLLife::kSimBoth;
						const float ne = (float)((_lfCfgAbsN[ce] > 0) ? _lfCfgAbsN[ce] : 1);
						const float nb = (float)((_lfCfgAbsN[cb] > 0) ? _lfCfgAbsN[cb] : 1);
						const float ev = _lfCfgF1Hid[ce] / ne, bo = _lfCfgF1Hid[cb] / nb;
						rEv += (float)_lfCfgInterv[ce] / (float)((_lfCfgIntervN[ce] > 0) ? _lfCfgIntervN[ce] : 1);
						rBo += (float)_lfCfgInterv[cb] / (float)((_lfCfgIntervN[cb] > 0) ? _lfCfgIntervN[cb] : 1);
						for (int q = 0; q < kLfSeedsUse; ++q)
						{ tot++; if (_lfCfgF1HidS[cb][q] > _lfCfgF1HidS[ce][q]) win++; }
						LogA("[ml]            %-8d %11.1f%% %11.1f%% %+9.1f%%p\n",
							_LfScaleOf(sc) * MLLife::kLearnTicks,
							(double)(100.0f * ev), (double)(100.0f * bo),
							(double)(100.0f * (bo - ev)));
					}
					// ⚠️⚠️⚠️ **판정문이 자기 전제를 검사한다** — 이 비교는 *"같은 예산"* 이 전제다.
					//   ★ 실측으로 밟았다(47차): 두 기제의 렌더 단가가 달라서 `둘다` 가 `사건앵커` 의
					//     **69%** 만 쓰고 있었고, 그 상태로 *"전액이 낫다"* 가 찍혔다 — **근거 없는 문장**이다.
					//   ⇒ 렌더가 10% 넘게 다르면 **판정불가**를 찍는다(함정 101·105 와 같은 계열: 발화 →
					//     효과의 부호 → **전제의 성립**).
					rEv /= (float)kLfScales; rBo /= (float)kLfScales;
					const float lo = (rEv < rBo) ? rEv : rBo, hi = (rEv < rBo) ? rBo : rEv;
					const bool costOk = (hi <= lo * 1.10f);
					LogA("[ml]            🧾 개입 렌더(실행당 평균): 사건앵커 **%.0f** vs 둘다 **%.0f**"
						" → %s\n",
						(double)rEv, (double)rBo,
						costOk ? "비용 일치(±10%%) ✅" : "⚠️ **비용 불일치**");
					if (!costOk)
						LogA("[ml]            ⇒ ⚠️ **판정불가** — 예산이 다르면 *\"쪼개는 것이 나쁘다\"* 와\n"
							"[ml]               *\"연산을 덜 썼다\"* 가 구별되지 않는다.\n");
					else
						LogA("[ml]            ⇒ 씨앗별 `둘다` 승리 **%d/%d** · %s\n",
							win, tot,
							(win * 3 >= tot * 2)
								? "**쪼개는 것이 낫다** → 두 기제가 겹치지 않는다(더해진다)"
								: "**전액이 낫다** → 두 기제가 겹친다(또는 반액이 문턱을 못 넘긴다)");
				}
				// ══════════════════════════════════════════════════════════════
				// 🧩 **조합앵커 판정** — 문맥의 단위를 `채널값 하나 → 둘의 조합`으로 넓혔다.
				//   ★ `사건앵커` 와 **테이프·쓰기·렌더가 같고 읽기만 다르다**(비용 동일) ⇒
				//     단일 앵커가 **못 정한 자리에서만** 조합을 읽는다(순서가 안전장치다).
				//   ⚠️ 조합은 지지가 10갈래로 흩어지므로 문턱을 `2` 로 낮췄다 — **발화 수를 먼저 본다.**
				// ══════════════════════════════════════════════════════════════
				{
					uint32 fired2 = 0;
					for (int sc = 0; sc < kLfScales; ++sc)
						fired2 += _lfCfgCtx2[sc * kLfSims + MLLife::kSimPairCtx];
					LogA("[ml]         🧩 **조합앵커 판정** — 문맥 단위 = 채널값 **둘**\n"
						"[ml]            🧾 조합 앵커가 답한 수 **%u** ← **기제가 발화했나**\n", fired2);
					if (fired2 == 0u)
						LogA("[ml]            ⇒ ⚠️ **판정불가** — 조합이 **한 번도 안 답했다**"
							"(단일 앵커가 늘 먼저 정한다 · 문턱이 높다 · 지지가 희박하다 중 하나)\n");
					else
					{
						int win = 0, tot = 0;
						for (int sc = 0; sc < kLfScales; ++sc)
						{
							const int ce = sc * kLfSims + MLLife::kSimEvent;
							const int cp = sc * kLfSims + MLLife::kSimPairCtx;
							const float ne = (float)((_lfCfgAbsN[ce] > 0) ? _lfCfgAbsN[ce] : 1);
							const float np = (float)((_lfCfgAbsN[cp] > 0) ? _lfCfgAbsN[cp] : 1);
							for (int q = 0; q < kLfSeedsUse; ++q)
							{ tot++; if (_lfCfgF1HidS[cp][q] > _lfCfgF1HidS[ce][q]) win++; }
							LogA("[ml]            경험 %d: 사건앵커 %.1f%% → 조합앵커 %.1f%% (%+.1f%%p)\n",
								_LfScaleOf(sc) * MLLife::kLearnTicks,
								(double)(100.0f * _lfCfgF1Hid[ce] / ne),
								(double)(100.0f * _lfCfgF1Hid[cp] / np),
								(double)(100.0f * (_lfCfgF1Hid[cp] / np - _lfCfgF1Hid[ce] / ne)));
						}
						LogA("[ml]            ⇒ 씨앗별 `조합앵커` 승리 **%d/%d** · %s\n", win, tot,
							(win * 3 >= tot * 2)
								? "**조합이 값을 한다** → 상호작용이 실재한다"
								: "**조합이 값을 안 한다** → 주변값 둘로 충분하다(또는 지지가 모자라다)");
					}
				}
				LogA("\n[ml]         🔎 가린 칸 수(설정당) %u\n",
					(_lfCfgAbsN[0] > 0) ? _lfCfgHidN[0] / (uint32)_lfCfgAbsN[0] : 0u);
				// ══════════════════════════════════════════════════════════════
				// 🔬 **천장을 쪼갠다** — *"74% 가 왜 74% 인가."*
				//   ㉠ **기권**(모름) = 2홉 길이 없었다 ⇒ 원인이 **구조/커리큘럼**이다
				//   ㉡ **틀림** = 길이 있어 옮겼는데 답이 틀렸다 ⇒ 원인이 **전이의 질**이다
				//   그리고 가린 것을 또 가른다: **형제 있음**(길이 원리적으로 있다) vs
				//   **고아**(그 채널이 통째로 가려져 기권이 정답인 칸).
				// ⚠️ 고아 칸을 천장에 넣으면 걷기를 억울하게 벌한다 — 그래서 갈라 찍는다.
				// ══════════════════════════════════════════════════════════════
				LogA("[ml]         🔬 **가린 74%%의 속** — 기권이면 구조 · 틀림이면 전이의 질\n"
					"[ml]            %-8s %-12s %8s %8s %8s %9s %9s\n",
					"경험", "갈래", "가린F1", "기권%", "틀림%", "형제F1", "고아F1");
				for (int sc = 0; sc < kLfScales; ++sc)
					for (int k = 0; k < kLfSims; ++k)
					{
						const int c = sc * kLfSims + k;
						const float nn = (float)((_lfCfgAbsN[c] > 0) ? _lfCfgAbsN[c] : 1);
						const float tot = (float)((_lfCfgHidN[c] > 0u) ? _lfCfgHidN[c] : 1u);
						LogA("[ml]            %-8d %-12s %7.1f%% %7.1f%% %7.1f%% %8.1f%% %8.1f%%\n",
							_LfScaleOf(sc) * MLLife::kLearnTicks, MLLife::SimName(k),
							(double)(100.0f * _lfCfgF1Hid[c] / nn),
							(double)(100.0f * (float)_lfCfgHidAbst[c] / tot),
							(double)(100.0f * (float)_lfCfgHidWrong[c] / tot),
							(double)(100.0f * _lfCfgF1Sib[c] / nn),
							(double)(100.0f * _lfCfgF1Orph[c] / nn));
					}
				// ══════════════════════════════════════════════════════════════
				// 🔍 **틀림이 어디에 몰리나** — *"채널 내 교환가능성은 어디서 깨지나."*
				//   ★ 가설: 인코딩 유사가 **모든** 축에 `0.30/값거리` 를 주는데, 그 식은
				//     **순서형**(개수·크기)에서만 뜻이 있고 **범주형**(색·자리·모양·속)에서는
				//     거리가 아무것도 아니다 ⇒ 틀림이 범주형 다중값 축에 몰릴 것이다.
				//   ⇒ 그러면 처방은 커리큘럼이 아니라 **인코딩 유사에 축의 종류를 알려주는 것**이다.
				// ══════════════════════════════════════════════════════════════
				LogA("[ml]            🔍 **틀림이 어디에 몰리나**(가렸고 형제 있고 답한 칸 · 상관 제외)\n"
					"[ml]               %-10s %8s %8s %8s %8s\n", "축", "값수", "맞음", "틀림", "틀림률");
				for (int ax = 0; ax < MLLife::kAxes; ++ax)
				{
					const uint32 tt = _lfAxOk[ax] + _lfAxBad[ax];
					if (tt == 0u) continue;
					LogA("[ml]               %-10s %8u %8u %8u %7.1f%%\n",
						MLLife::AxName(ax), MLLife::AxClasses(ax), _lfAxOk[ax], _lfAxBad[ax],
						(double)(100.0f * (float)_lfAxBad[ax] / (float)tt));
				}
				LogA("[ml]               %-10s %8s %8s %8s %8s\n", "값거리", "", "맞음", "틀림", "틀림률");
				for (int dd = 0; dd < MLLife::kVals; ++dd)
				{
					const uint32 tt = _lfDOk[dd] + _lfDBad[dd];
					if (tt == 0u) continue;
					LogA("[ml]               d=%-8d %8s %8u %8u %7.1f%%\n",
						dd, "", _lfDOk[dd], _lfDBad[dd],
						(double)(100.0f * (float)_lfDBad[dd] / (float)tt));
				}
				LogA("[ml]               ★ 순서형 = 개수·크기 · 범주형 = 색·자리·모양·속.\n"
					"[ml]                 ⛔ 44차에 이 가설은 **기각**됐다(색 5값 = 0.0%%) — 범인은 `크기` 하나다.\n");
				// ══════════════════════════════════════════════════════════════
				// 🔬 **전이 프로필** — *"형제의 전이가 정말 다른 일을 하나."*
				//   ★ 44차 가설: 2값 축에서 `from→(from+1)%n` 이 **서로의 역**이라 상태 유사가
				//     행동 전이를 잘못 허가한다 ⇒ 그러면 **두 형제의 프로필이 달라야 한다.**
				//   ⇒ 축 안 **최대 형제 거리**가 틀림률 순서(`크기` > `자리` > `속` > 0)와 맞으면 닫힌다.
				// ⚠️ 진단 전용이다 — 렌더를 **평가용 오라클**로 세고 실험 회계와 안 섞는다.
				// ══════════════════════════════════════════════════════════════
				{
					LogA("[ml]            🔬 **전이 프로필**(진단 · 축마다 canonical 전이가 움직이는 사실 %%)\n"
						"[ml]               %-8s %4s", "축", "값");
					for (int f = 0; f < MLFacts::kFacts; ++f) LogA(" %8s", MLFacts::FactName(f));
					LogA("  장면\n");
					uint32 dOracle = 0;
					for (int ax = 0; ax < MLLife::kAxes; ++ax)
					{
						const int nc = (int)MLLife::AxClasses(ax);
						float prof[MLLife::kVals][MLFacts::kFacts] = {};
						for (int v = 0; v < nc && v < MLLife::kVals; ++v)
						{
							const uint32 got = _lfLife.TransitionProfile(
								MLLife::EntAV(ax, v), 48u, 777001u, dOracle, prof[v]);
							LogA("[ml]               %-8s %4d", MLLife::AxName(ax), v);
							for (int f = 0; f < MLFacts::kFacts; ++f)
								LogA(" %7.0f%%", (double)(100.0f * prof[v][f]));
							LogA(" %5u\n", got);
						}
						// 형제끼리의 최대 평균절대차 — 이 값이 곧 *"행동으로는 얼마나 다른가"* 다.
						float worst = 0.0f; int wi = 0, wj = 0;
						for (int a = 0; a < nc && a < MLLife::kVals; ++a)
							for (int b = a + 1; b < nc && b < MLLife::kVals; ++b)
							{
								float d = 0.0f;
								for (int f = 0; f < MLFacts::kFacts; ++f)
								{
									const float e = prof[a][f] - prof[b][f];
									d += (e < 0.0f) ? -e : e;
								}
								d /= (float)MLFacts::kFacts;
								if (d > worst) { worst = d; wi = a; wj = b; }
							}
						LogA("[ml]                  ⇒ %s 의 **최대 형제 거리 %.1f%%p**(값 %d ↔ %d)\n",
							MLLife::AxName(ax), (double)(100.0f * worst), wi, wj);
					}
					_lfJudgeOracle += dOracle;
					LogA("[ml]               ★ 이 표의 렌더 %u회는 **평가용 오라클**이다(실험 회계와 안 섞는다).\n"
						"[ml]               ⇒ 최대 형제 거리가 틀림률 순서(크기 14.1%% > 자리 5.1%% > 속 3.0%%\n"
						"[ml]                 > 개수·모양·색 0.0%%)와 맞으면 **역전이 가설이 닫힌다**.\n", dOracle);
				}
				LogA("[ml]            🔎 가린 칸 중 **고아**(채널이 통째로 가려졌다) %u / %u = **%.1f%%**\n"
					"[ml]               ★ 고아 칸은 **기권이 정답**이다 — 그 몫은 천장의 원인이 아니라 **마스크의 몫**이다.\n",
					_lfCfgOrphN[0], _lfCfgHidN[0],
					(double)((_lfCfgHidN[0] > 0u)
						? (100.0f * (float)_lfCfgOrphN[0] / (float)_lfCfgHidN[0]) : 0.0f));
				// 🔎 **배운 유사 변의 축 구성** — 갈래마다 세 규모를 합쳐 센다.
				//   ★ *"세계에 채널간 공유 효과가 있다"* 는 **이 칸으로만** 닫힌다(코드를 읽은 논증이 아니라).
				//   ⚠️ 한 설정의 3개로는 아무것도 못 닫는다 — 그래서 합계를 찍는다.
				LogA("[ml]         🔎 **배운 유사의 축 구성**(전 규모 합) —");
				for (int k = 1; k < kLfSims; ++k)
				{
					uint32 sa = 0, cr = 0;
					for (int sc = 0; sc < kLfScales; ++sc)
					{ sa += _lfCfgSimSame[sc * kLfSims + k]; cr += _lfCfgSimCross[sc * kLfSims + k]; }
					if (sa + cr == 0u) continue;
					LogA(" %s 같은축 %u/채널간 **%u** ·", MLLife::SimName(k), sa, cr);
				}
				LogA("\n[ml]            ★ 채널간이 0 이면 *\"세계에 채널간 공유 효과가 있다\"* 는 안 닫힌다.\n");
			}
		}
		{
			// ★ 기준을 미리 못박았다: **배운 유사를 켠 쪽이 끈 쪽의 80% 이상**이 되는 규모가 있으면
			//   그 규모가 **배운 유사의 하한**이다(같아지면 배울 수 있게 된 것이다).
			// ⚠️ 판정도 정직하게: **`헛`(맞춤도 안 늘었다)이 있으면 그 설정은 통과할 수 없다.**
			//   ★ 평균만 보면 `공짜` 하나가 `헛` 여럿을 가린다(그것이 거짓 양성의 모양이었다).
			// ══════════════════════════════════════════════════════════════════════
			// 🌱 **재현 판정 — 평균이 아니라 씨앗마다 잰다.**
			//   ⚠️⚠️ 평균으로 판정하면 **한 씨앗의 큰 값이 다른 씨앗의 실패를 가린다**
			//     (실측: 경험 80 에서 22.0 vs 4.8 — 4.6배 차이가 평균 13.4 로 접혔다).
			//   ★ 기준을 미리 못박았다(이 저장소의 재현 규율 그대로): **씨앗 4개 중 3개 이상**에서
			//     그 갈래의 여유가 **같은 씨앗의 `끔` 여유의 80% 이상**이어야 한다.
			//   ⚠️ `헛` 이 하나라도 있으면 그 설정은 통과할 수 없다(평균이 가리는 그 자리다).
			// ══════════════════════════════════════════════════════════════════════
			LogA("[ml]      🌱 **씨앗마다 기준을 잰다**(같은 씨앗의 `끔` 대비 80%%) — 기준: **4중 3**\n"
				"[ml]         %-8s %-10s %6s %6s %6s %6s   판정\n",
				"경험", "갈래", "씨앗0", "씨앗1", "씨앗2", "씨앗3");
			int firstOk = -1, okSim = -1;
			for (int sc = 0; sc < kLfScales; ++sc)
				for (int k = 1; k < kLfSims; ++k)
				{
					if (k == MLLife::kSimHub || k == MLLife::kSimTransition
						|| k == MLLife::kSimEvent || k == MLLife::kSimBoth
						|| k == MLLife::kSimPairCtx) continue;
					// 상관은 반증됐고, 뒤 두 팔은 배운 유사가 아니어서 이 하한 판정의 후보가 아니다.
					const int cOff = sc * kLfSims, cOn = sc * kLfSims + k;
					if (_lfCfgSimE[cOn] == 0u)
					{
						LogA("[ml]         %-8d %-10s     ·     ·     ·     ·   기제 미발화\n",
							_LfScaleOf(sc) * MLLife::kLearnTicks, MLLife::SimName(k));
						continue;
					}
					int win = 0, def = 0;
					LogA("[ml]         %-8d %-10s", _LfScaleOf(sc) * MLLife::kLearnTicks,
						MLLife::SimName(k));
					for (int q = 0; q < kLfSeedsUse; ++q)
					{
						if (!_lfCfgMarSOk[cOff][q] || !_lfCfgMarSOk[cOn][q]) { LogA("     ·"); continue; }
						def++;
						const float r = _lfCfgMarS[cOn][q] / _lfCfgMarS[cOff][q];
						if (r >= 0.8f) win++;
						LogA(" %5.0f%%", (double)(100.0f * r));
					}
					const bool pass = (win >= 3) && (_lfCfgBad[cOn] == 0);
					LogA("   %d/%d %s%s\n", win, def, pass ? "**통과**" : "실패",
						(_lfCfgBad[cOn] > 0) ? " (헛 있음)" : "");
					if (pass && firstOk < 0) { firstOk = sc; okSim = k; }
				}
			if (okSim >= 0) LogA("[ml]      📐 통과한 갈래 = **%s**(경험 %d)\n",
				MLLife::SimName(okSim), _LfScaleOf(firstOk) * MLLife::kLearnTicks);
			if (firstOk >= 0)
				LogA("[ml]      📐 판정: 경험 **%d회**부터 배운 유사가 끈 것의 80%% 이상을 낸다 → 통과\n"
					"[ml]        ★ 그것이 **적은 티칭의 실제 하한**이다 — 그 아래에서는 유사를 못 배운다.\n",
					_LfScaleOf(firstOk) * MLLife::kLearnTicks);
			else
				LogA("[ml]      📐 판정: 잰 규모(최대 %d회) 안에서는 배운 유사가 **끈 것을 못 따라간다** → ★실패★\n"
					"[ml]        ⇒ 20차의 결론이 규모 문제가 아니라 **더 근본적**이라는 뜻이다:\n"
					"[ml]          유사는 **인코딩 층**이고, 경험을 늘려도 그 자리를 대신하지 못한다.\n"
					"[ml]        ⚠️ 단 잰 범위 안에서의 결론이다 — 더 큰 규모는 안 쟀다.\n",
					_LfScaleOf(kLfScales - 1) * MLLife::kLearnTicks);
		}

		// ══════════════════════════════════════════════════════════════════════
		// ⚖️ **척도를 다시 못박는다 — 이득률 *과* 맞춘 칸 수(함정 68).**
		//   ⚠️ 6차에서 이득률은 거의 안 움직였는데(+48.1 → +50.0) **예측 칸이 81 → 120** 이었다
		//     ⇒ 비율만 재면 *"더 많은 것에 답하게 된 것"* 이 판정에 안 들어간다.
		//   ★ 문턱 **+20%** 의 근거: *"같은 외부 접촉으로 **5분의 1 더** 답한다"* 는 뜻이 있는 선
		//     (관측값 +49% 에서 거꾸로 고른 것이 아니다).
		//   ⚠️⚠️ **정직한 유보**: 이 기준은 6차 수치를 **이미 아는 상태**에서 넣었으므로
		//     이번 통과는 **독립 증거가 아니다.** 진짜 시험은 표본을 바꾼 **다음 실행**이다.
		{
			const float hA = _lfTr[MLLife::kArmMemTest].hits;
			const float hB = _lfTr[MLLife::kArmFull].hits;
			const float ratio = (hA > 0.0f) ? (hB / hA) : 0.0f;
			const bool okHits = (ratio >= 1.20f) && sameCost;
			// ══════════════════════════════════════════════════════════════════
			// ⚖️ **세 축으로 본다 — 이득률 · 맞춘 칸 · 틀린 칸**(함정 70).
			//   ⚠️ 8차에서 두 척도가 **정반대**를 말했다: 맞춘 칸 2.46배(통과) vs 이득률 −20.6%p(실패).
			//     모순이 아니었다 — `맞은 것 +108 · 틀린 것 +18`(맞는 쪽이 6배 빠르다).
			//   ⇒ 비율만 재면 *"넓어진 것"* 과 *"나빠진 것"* 이 갈리지 않는다 ⇒ **틀린 칸을 같이 센다.**
			// ★ 문턱 **2:1** 의 근거: *"틀린 것 하나를 얻는 대가로 맞은 것 둘 이상"* 이어야
			//   순이득이라 부를 수 있다(뜻이 있는 선이다).
			//   ⚠️⚠️ 정직한 유보: 지금 값이 약 6:1 인 것을 **알고** 이 선을 넣었다 ⇒
			//     이번 통과는 독립 증거가 아니다. 진짜 시험은 **강도 문턱을 넣은 다음 실행**이다.
			const float mA = (float)_lfTr[MLLife::kArmMemTest].n - hA;
			const float mB = (float)_lfTr[MLLife::kArmFull].n - hB;
			const float dHit = hB - hA, dMiss = mB - mA;
			const float margin = (dMiss > 0.0f) ? (dHit / dMiss) : ((dHit > 0.0f) ? 999.0f : 0.0f);
			const bool okMargin = (margin >= 2.0f);
			LogA("[ml]   ⚖️ **맞춘 칸 수 판정**: 시험 %.1f → 정리 %.1f (배율 **%.2f배**) · 기준 1.20배 → %s\n"
				"[ml]      ★ 이것이 *\"적은 외부 접촉으로 새로운 관계를 더 잘 맞힌다\"* 의 직접 형태다 —\n"
				"[ml]        정확도가 아니라 **답할 수 있는 것의 수**가 늘어나는 것이 정리가 하는 일이다.\n"
				"[ml]   ⚖️ **순이득 판정**: 늘어난 맞춘 칸 %+.1f · 늘어난 틀린 칸 %+.1f → **%.1f : 1**\n"
				"[ml]      기준 2:1 이상(틀린 것 하나 대가로 맞은 것 둘 이상) → %s\n"
				"[ml]      ⚠️ 두 기준 다 지금 값을 **알고** 넣었다 ⇒ **이번 통과는 독립 증거가 아니다.**\n"
				"[ml]        진짜 시험은 손잡이를 바꾼 **다음 실행**이다.\n",
				(double)hA, (double)hB, (double)ratio,
				okHits ? "통과" : "★실패★",
				(double)dHit, (double)dMiss, (double)margin,
				okMargin ? "통과" : "★실패★");
		}
		LogA("[ml]   ⚖️ **마지막 실행 연쇄 진단**: 전이 **이득**(정리) − 전이 이득(시험) = %+.1f%%p\n"
			"[ml]      외부접촉 %u vs %u · 개입 성공렌더 %u vs %u\n"
			"[ml]      기준: 전이 이득 > +2%%p **그리고** 두 비용이 늘지 않았다 → %s\n"
			"[ml]      ★ 두 조건을 **동시에** 본다 — 하나만 보면 *\"더 많이 물어서 더 잘 맞혔다\"* 와\n"
			"[ml]        구별되지 않는다. 자가학습의 값은 **접촉을 늘리지 않고 나아지는 것**이다.\n"
			"[ml]      ⚠️ 실패면 다음은 모델을 더 학습시키는 것이 **아니다** — 정리 규칙(조합·모순·감쇠)이\n"
			"[ml]        무엇을 만드는지 세어 보는 것이다(가설 수 대비 새연결 정확도).\n",
			(double)(100.0f * dT), _lfExt[MLLife::kArmFull], _lfExt[MLLife::kArmMemTest],
			_lfInterv[MLLife::kArmFull], _lfInterv[MLLife::kArmMemTest],
			(!cmpOk) ? "★판정불가★(한쪽이 예측을 0회 했다)"
				: (okChain ? "통과(연결이 연결을 만들었다)" : "★실패★"));
	}

	static void _CopyF(const Bytes& b, Array<float>& out)
	{
		const uint32 n = (uint32)(b.GetSize() / sizeof(float));
		out.Reset(n);
		const float* p = (const float*)b.GetData();
		for (uint32 i = 0; i < n; ++i) out.Data()[i] = p[i];
	}
	// ══════════════════════════════════════════════════════════════════════════
	// 🎲 **자기 시도 — 온도 있는 샘플링 decode.**
	//
	// ★ **왜 샘플링이 필요한가**: argmax 는 **결정적**이라 N번 뽑아도 다 같다 ⇒
	//   *"여러 시도 중 채점이 좋은 것을 골라 배운다"* 가 성립하지 않는다.
	// ★ **그리고 그것이 함정 11 을 구조로 지키는 길이다**: 채점이 좋은 것만 타깃으로 쓰면
	//   *"틀린 상상을 강화"* 하는 일이 원리적으로 없다(예측 손실을 상상 출력에 걸지 않는다).
	// ⚠️ **결정적이어야 한다**(이 저장소의 규약) ⇒ 씨앗을 `(캡션, 샘플번호, 자리)` 로 짜서
	//   같은 실행이 같은 결과를 낸다. `SeedRand` 를 쓰지 않는다(전역 상태를 건드리면 다른 단계가 흔들린다).
	static uint32 _GnHash(uint32 a, uint32 b, uint32 c)
	{
		uint32 h = a * 0x9E3779B1u;
		h ^= (b + 0x85EBCA6Bu + (h << 6) + (h >> 2));
		h ^= (c + 0xC2B2AE35u + (h << 6) + (h >> 2));
		h ^= (h >> 15); h *= 0x2545F491u; h ^= (h >> 13);
		return h;
	}

	// ══════════════════════════════════════════════════════════════════════════
	// ▶️ **실행 채점 — 자기 시도 루프의 ②.**
	//
	// ★ **왜 이것이 문자열 채점과 다른 신호인가 — 실측이 그 예를 이미 냈다.**
	//   생성 `없다!` / 정답 `없다.` — **문자열로는 오답**(마지막 부호가 다르다)인데
	//   **의미로는 정답**이다(둘 다 빈 장면). ⇒ 티쳐포싱 손실은 그것을 벌하고,
	//   실행 채점은 **맞다고 센다.** ⇒ *"표면 형태가 아니라 가리키는 것으로 채점한다."*
	//   ★ 그리고 그것이 *"적은 경험으로 인과를 배운다"* 의 물리적 근거다 — 같은 뜻의 다른 표면을
	//     하나로 묶어 주므로 한 경험이 여러 표면을 덮는다.
	//
	// ★ **이것이 "루프가 닫혔다" 의 증거다**: 시도는 **텍스트 채널**에서 나오고(생성),
	//   채점은 **비전 채널**에서 온다(코드를 실제로 돌려 만든 프레임을 판독기가 읽는다).
	//   ⇒ 아무도 그 연결을 암기시켜 준 적이 없다.
	//
	// ⚠️ **파싱은 축마다 "그 축의 낱말이 들어 있나" 로 한다**(순서 무관 · 부분 생성에 강건).
	//   ⚠️⚠️ 순서가 중요한 자리가 하나 있다: **`간다` 는 `안간다` 의 부분문자열**이므로
	//     `안간다` 를 **먼저** 본다(안 그러면 "안 간다" 가 "간다" 로 읽힌다).
	static bool _HasWord(const Array<uint8>& b, const char* w)
	{
		const uint32 n = (uint32)b.Count();
		uint32 m = 0; while (w[m] != 0) m++;
		if (m == 0u || m > n) return false;
		for (uint32 i = 0; i + m <= n; ++i)
		{
			bool same = true;
			for (uint32 j = 0; j < m && same; ++j)
				if (b.Data()[i + j] != (uint8)w[j]) same = false;
			if (same) return true;
		}
		return false;
	}

	// 생성 바이트열 → 장면. ★ 못 읽은 축은 **기본값**으로 둔다(그것도 하나의 시도다).
	static void _ParseCaption(const Array<uint8>& b, MLScene& out)
	{
		out = MLScene();
		// 존재 — `없다` 가 있으면 빈 장면이다(그 경우 나머지 축은 뜻이 없다).
		if (_HasWord(b, "없다")) { out.exists = 0; return; }
		out.exists = 1;
		if (_HasWord(b, "네모")) out.shape = 1;
		else if (_HasWord(b, "동그라미")) out.shape = 0;
		if (_HasWord(b, "큰")) out.big = 1;
		else if (_HasWord(b, "작은")) out.big = 0;
		if (_HasWord(b, "찬")) out.filled = 1;
		else if (_HasWord(b, "빈")) out.filled = 0;
		for (int c = 0; c < MLEpisodeGen::PaletteCount(); ++c)
			if (_HasWord(b, MLEpisodeGen::Palette(c).name)) { out.color = c; break; }
		for (int n = 1; n <= 5; ++n)
			if (_HasWord(b, MLSense::WordCount(n))) { out.count = n; break; }
		// ⚠️ **자리는 방향과 같은 낱말**을 쓴다 — 이동 낱말이 없으면 자리로 읽는다.
		const bool moving = _HasWord(b, "간다") || _HasWord(b, "갔다");
		const bool notMoving = _HasWord(b, "안간다");
		out.moves = (moving && !notMoving) ? 1 : 0;
		for (int d = 0; d < 5; ++d)
			if (_HasWord(b, MLSense::WordPos(d)))
			{
				if (out.moves != 0) { if (d < 4) out.moveDir = d; }
				else out.pos = d;
				break;
			}
	}

	// ▶️ **장면을 실제로 실행해** 프레임 사실을 얻는다(코드 → 실행 → 판독).
	// ⚠️ 이 함수 자체는 **자기 상상의 실행**이다(오라클이 아니다) — 오라클은 **정답 장면**을 만질 때다.
	bool _RenderSceneFacts(const MLScene& sc, MLFrameFacts& out) const
	{ return MLFacts::Render(sc, out); }

	// ▶️📊 **사실 벡터** — 항목마다 맞았나(0/1). ★ **이것이 추론의 재료다.**
	//   ⚠️⚠️ 실측으로 밟았다: 같은 것을 계산해 놓고 `hit/all` 로 **스칼라로 뭉개서** 썼다 ⇒
	//     모델이 받는 것이 *"0.6점"* 이고 *"**색은 맞고 개수가 틀렸다**"* 가 아니었다.
	//     ⇒ 귀속의 재료를 만들어 놓고 **던져 버린 것**이고, 그것이 자기학습을 **감 찍기**로 만든 원인이다.
	//   ★ 항목: 0 있나/없나 · 1 덩어리 수 · 2 평균색 · 3 잉크 면적 · 4 bbox 중심 · **5 덩어리 채움률**.
	// 🔷 **5번(덩어리 채움률)이 왜 늘었나 — 모양이 채점기에 안 보였다**(함정 47·49 의 자리):
	//   `_FactScore` 가 모양을 못 보면 자기학습에서 모양은 **흘러내리고** 인과표의 모양 행이 **전부 0** 이다.
	//   ★ 그리고 그것이 🎭 성격(λ)이 죽어 있던 이유이기도 하다: 사실마다 **아는 축이 1개**여서
	//     선호 스케일이 고를 것이 없었다. 덩어리 채움률은 **모양과 속 둘 다** 움직이므로
	//     *"사실 하나에 축 후보가 둘"* 을 처음으로 만든다.
	//   ⚠️ 문턱 **0.10** 의 근거(결과를 보고 정한 것이 아니다): 동그라미 꽉 `π/4 ≈ 0.785` vs
	//     네모 꽉 `≈ 1.0` 이라 차이가 **0.215** 다 ⇒ 0.10 이면 그 둘을 가르고 잡음은 안 잡는다.
	// ★ 정의는 `mlfacts.cw` 로 갔다 — 소비자가 둘이 됐기 때문이다(생명주기 실험이 같은 것을 쓴다).
	//   ⚠️ 이름은 여기 남긴다: 호출부가 수십 곳이고, 이름을 바꾸는 것은 이 리팩터의 목적이 아니다
	//     (한 번에 한 가지만 바꾼다 — 그러면 숫자가 달라졌을 때 원인이 하나다).
	static constexpr int kGnFacts = MLFacts::kFacts;
	static void _FactVec(const MLFrameFacts& a, const MLFrameFacts& b, uint8* out)
	{ MLFacts::Vec(a, b, out); }

	// ★ **사실 → 그것을 고칠 장면 축.** ⚠️ 이 표가 곧 *"무엇이 틀렸으면 무엇을 바꿔야 하나"* 다
	//   (인과 지식이고, 이 프로젝트에서는 **판독기 규약**이 그것을 준다 — 배우는 것이 아니다).
	//   ⇒ `-1` = 존재(`exists`) 토글 · 그 밖은 프로브 축 번호(0 개수 · 2 색 · 3 크기 · 4 자리 · 5 속).
	static int _FactToAxis(int fact, int cursor)
	{
		if (fact == 0) return -1;                 // 있나/없다
		if (fact == 1) return 0;                  // 덩어리 수 → 개수
		if (fact == 2) return 2;                  // 평균색 → 색
		if (fact == 3) return (cursor % 2 == 0) ? 3 : 5;   // 잉크 면적 → 크기 · 속
		if (fact == 4) return 4;                  // bbox 중심 → 자리
		// 🔷 덩어리 채움률 → **모양** 또는 **속**. ⚠️ 둘 다 진짜로 움직인다(그것이 이 항의 요점이다).
		return (cursor % 2 == 0) ? 1 : 5;
	}

	// ▶️ **사실 일치 점수** ∈ [0,1] — 판독기가 주는 것이 **벡터**라 축별로 센다.
	//   ★ 그것이 이 프로젝트가 희소 보상 문제를 피하는 자리다: *"어디가 틀렸나"* 를 채점이 직접 준다.
	//   ⚠️ 임계값은 관대하게 둔다 — 지금 묻는 것은 *"의미가 같나"* 이고 픽셀 동일성이 아니다.
	static float _FactScore(const MLFrameFacts& a, const MLFrameFacts& b)
	{ return MLFacts::Score(a, b); }

	// ══════════════════════════════════════════════════════════════════════════
	// 🔬🧠 **인과 표를 개입으로 배운다 — "주지 말고 배우게" 의 실제 구현.**
	//
	// ⚠️⚠️ **왜 이것이 필요한가**: 지시된 수정이 쓰는 표(`_FactToAxis` — *"면적이 틀렸으면 크기를
	//   바꿔라"*)는 **내가 손으로 준 것**이다. 그것이 있으면 추론이 이기지만(0.660 → 0.855),
	//   *"왜 틀렸나"* 를 **모델이 스스로 안 것은 아니다.**
	// ★ **개입으로 배운다**: 장면의 축 하나를 **일부러 바꿔** 실행하고 **어느 사실이 달라지나**
	//   관찰한다 ⇒ `C[축][사실] += 바뀌었나`. 그것이 곧 인과 표이고 **아무도 안 알려줬다.**
	//   ★ 그리고 그것이 갓 태어난 동물이 하는 것이다: **발로 건드려 보고 무엇이 바뀌는지 본다.**
	//     ⇒ 상관이 아니라 **개입**이라 인과가 나온다(관찰만으로는 색과 면적이 섞인다).
	// ⚠️ 지금은 **CPU 카운팅**으로 배운다 — 이 저장소의 CPU-레퍼런스-먼저 관용구다.
	//   그것이 되면 신경망으로 옮긴다(먼저 "배울 수 있나" 를 확인한다).
	// ⚠️ **결정적**이다(씨앗 해시) — 같은 실행이 같은 표를 낸다.
	// ══════════════════════════════════════════════════════════════════════════
	// 💗🚫 **호/불호 — 두 채널을 동시에 든다.**
	//
	// ★ **왜 부호 하나(±)로 합치지 않나**: 합치면 *"강하게 끌리는데 동시에 강하게 피한다"*
	//   = **갈등**이 0 이 되어 **무지**(정보 없음)와 **구별이 안 된다.** 두 채널이면 갈라진다.
	//   ⇒ 이 저장소의 2채널 원칙(*"값 종류가 아예 달라야 한다"*)·흐림 세 갈래와 **같은 논리**다.
	//
	// ★ **흐림과 다른 축이다**:
	//   흐림낮 + 호높 = 확신하고 끌린다(실행) · 흐림낮 + 불호높 = 확신하고 피한다(배제)
	//   흐림높 + 둘다낮 = **모른다**(탐험 — 자가 커리큘럼이 지목)
	//   **둘 다 높음 = 갈등** ⇒ ★ 그 단위가 **두 가지를 섞고 있다**는 신호이고 **쪼개야 한다**
	//   (재조합의 단서 — "생각정리" 에서 인과·유사성 연결을 넓히는 축이 될 자리다).
	//
	// ⚠️⚠️ **지금 코드의 결함이 이것을 요구했다**: 지시된 수정의 **커서**는 조잡한 불호
	//   (*"이미 해봤다"*)인데 **캡션마다 리셋**된다 ⇒ 매번 처음부터다.
	//   ⇒ 호/불호는 **누적**되므로 *"틀린 경험이 다른 답을 찾는 단서로 쓰인다"* 가 그때 성립한다.
	//
	// ★ **두 층에 든다**:
	//   ㉠ `[사실][축]` — *"그 사실이 틀렸을 때 그 축을 바꿔서 좋아졌나"*(= 인과 표의 호/불호판)
	//   ㉡ `[축][값]`   — *"그 축의 그 값이 좋았나"*(= 값 선택의 호/불호)
	// ⚠️ **맞은 것도 틀린 것도 다 기록한다**(한쪽만 세면 빈도에 휩쓸린다).
	uint32 _gnLikeF[kGnFacts][6] = {}, _gnDisF[kGnFacts][6] = {};
	uint32 _gnLikeV[6][8] = {}, _gnDisV[6][8] = {};
	uint32 _gnValN = 0;
	mutable uint32 _gnLearnMiss = 0;   // 🔬 배운 표가 후보를 못 낸 횟수(손으로 준 표로 떨어진 횟수)
	float  _gnDirL[kGnArms] = {};      // 🔬 배운 표로 고른 결과
	// ══════════════════════════════════════════════════════════════════════════
	// 🔮 **오라클 접촉 계수 — 숨어 있던 비용을 센다.**
	//   ⚠️⚠️ *"정답 캡션을 안 쓴다"* 고 했지만 **정답 장면을 시도마다 만졌다**
	//     (`_RenderSceneFacts(_gnScenes[cap])`) ⇒ 그것이 **알파고의 승패 오라클**이다.
	//   ★ 그래서 공정한 축은 **"외부 진실에 닿은 횟수"** 다 — 티칭 + 오라클 채점 **둘 다**.
	//     생명체는 승패 신호가 없다 ⇒ **소수의 접지 경험으로 호/불호를 쌓고 그 뒤로는
	//     오라클 없이 자기 선호로 고른다.** 그것이 알파고와 다른 지점이고, 여기서 그것을 잰다.
	mutable uint32 _gnOracle = 0;

	// 💗🚫 **선호도** = `(호 − 불호) / (호 + 불호 + 1)` ∈ (−1, 1).
	//   ⚠️ 분모에 `+1` 을 둔다 — **경험이 없으면 0**(무지)이고, 한 번 겪은 것이 열 번 겪은 것과
	//     같은 무게를 갖지 않는다(적은 경험을 과신하지 않는다).
	// ⚠️ `lam` = 🎭 **성격**(선택에서 불호를 몇 배로 보나). **기록에는 안 걸린다.**
	static float _Pref(uint32 like, uint32 dis, float lam = 1.0f)
	{
		const float d = lam * (float)dis;
		const float n = (float)like + d + 1.0f;
		return ((float)like - d) / n;
	}
	// ⚠️ **갈등** = `min/max` — 둘 다 높으면 1 에 가깝다(그 단위가 뭉쳐 있다는 신호).
	static float _Conflict(uint32 like, uint32 dis)
	{
		const uint32 mn = (like < dis) ? like : dis, mx = (like > dis) ? like : dis;
		return (mx > 0u) ? ((float)mn / (float)mx) : 0.0f;
	}

	// ══════════════════════════════════════════════════════════════════════════
	// 💗 **호는 소스에 붙어 있다 — 오라클이 주는 것이 아니다.**
	//
	// ⚠️⚠️ **앞 실행이 실패한 진짜 뿌리가 이것이다**(함정 50 의 원인): 호를 *"오라클이 좋아졌다고
	//   할 때"* 만 붙였다 ⇒ **호가 승패 신호에 의존**했고, 오라클이 안 가 본 칸은 **영원히 0** 이다.
	//   ⇒ 표가 비고, 빈 칸의 선호 0 이 타이브레이크를 이겨 성능을 **깎았다**(0.845 → 0.565).
	// ★ **생명체는 그렇게 안 한다** — 호/불호의 상당 부분은 **소스 자체에 원시적으로** 붙어
	//   있고(소리·표정·냄새·촉감) 사람도 **태생적으로 가진 호/불호가 매우 많다.**
	//   ⇒ 음식은 **맞히지 않아도** 냄새·맛이 이미 호다. 우리는 음식이 아니므로 그 자리에 오는 것이
	//     **출제자의 표정과 소리**다: **엄마가 밝은 표정으로 알려주는 동안 소스에 붙는 것은 기본이 호**다.
	//     ★ 지금 우리는 *"하면 안돼"* 를 가르치는 중이 **아니다** ⇒ 티칭에서 온 것은 **다 호**다.
	// ★ 그래서 규칙이 세 줄로 닫힌다:
	//   ㉠ **티칭 소스에서 온 것 → 호 +1**(맞았든 틀렸든 · 불호는 0)
	//   ㉡ **맞았다 → 호 +4**(강렬 호)
	//   ㉢ **틀렸다 → 불호 +1**(불호가 생기는 자리는 **여기뿐**이다)
	// ⇒ 결과적으로 **호는 넓게 깔리고 불호가 깎아낸다.** 그 분업이 요점이다.
	//   ★ 그리고 이것이 무작위 탐험보다 낫다: **오라클을 한 번도 더 안 쓴다**(티칭 재료만 본다).
	static constexpr uint32 kValSrc = 1u;    // 소스에서 옴 — **사건 하나당** 1
	// ══════════════════════════════════════════════════════════════════════════
	// 🎭 **손잡이가 둘이다 — 그리고 합치면 안 된다.**
	//
	// ㉠ **불호가 얼마나 붙나**(기록) — 이것은 **기억**이다.
	// ㉡ **선택할 때 불호를 얼마나 크게 보나**(스케일 λ) — 이것은 **성격**이다.
	// ★ **왜 갈라야 하나**: ㉡ 을 ㉠ 에 접으면 **기분 나쁜 날이 기억을 다시 쓴다.**
	//   기분이 바뀌어도 기억은 그대로여야 하므로 λ 는 **선택에만** 걸려야 한다.
	//   ⇒ 그리고 그때 **같은 표에서 λ 만 흔들면 그것이 "기분"** 이다(다음 단계 · 설계는 여기 적어 둔다).
	// ★ 그래서 원칙: ***"기록은 편향 없이, 편향은 선택에서."***
	//   ⇒ 맞음과 틀림을 **같은 무게로** 기록한다. *"맞으면 강렬 호"* 의 **강렬은 소스(+1) 대비**다:
	//     소스는 **넓고 약한 사전**, 결과 관측(맞음·틀림)은 **좁고 강한 증거**다.
	//
	// ⚠️⚠️ **그 무게를 상수로 박으면 안 된다 — 소스의 호는 코퍼스 크기에 비례해 쌓인다.**
	//   `[사실][축]` 은 장면 80 × 축마다 개입 3 ⇒ 셀당 **수백**, `[축][값]` 은 캡션 240/값 4 ⇒ **수십**.
	//   거기에 `+1` 짜리 결과 관측을 얹으면 큰 상수가 `_Pref` 를 +1 쪽으로 **압축**해
	//   셀끼리의 **분해능이 사라진다**(고를 수가 없다) — 앞 실패의 나머지 절반이 이것이다.
	// ★ ⇒ **소스가 실제로 깐 규모에서 도출**한다(스케일 프리 — `kGnTrain` 이 바뀌어도 안 흔들린다):
	//   `결과 관측 무게 = 셀당 평균 소스 호 / kValRecDiv` ⇒ *"**두 번**의 관측이 사전과 맞먹는다"*.
	//   분모는 마법 숫자가 아니라 **뜻이 있는 선택**이고 규모는 **실측**에서 온다.
	static constexpr uint32 kValRecDiv = 2u;
	uint32 _gnWRecF = 1u, _gnWRecV = 1u;     // 층마다 도출한 결과-관측 무게
	// 🎭 **성격 λ 격자** — 선택에서 불호를 몇 배로 보나.
	//   ⚠️ 기준을 미리 못박았다(결과 보고 고르지 않는다):
	//     · λ 가 **낮으면 무모함** — 안 피하니 커서만과 차이가 없다
	//     · λ 가 **높으면 소심함** — *"확신 전엔 모르겠어요"* ⇒ ★ **예산 소진율이 떨어진다**
	//       (고를 축이 없어 조기 포기한다) ⇒ 소심함은 **추측이 아니라 관측량**이다
	//     · 그 사이에 **최대점**이 있어야 한다. 없으면 λ 는 성격 축이 아니라 그냥 잡음이다.
	//   ⚠️⚠️ 반대 예측도 적어 둔다: 워밍업이 커서 모드라 **불호는 티칭이 지목한 칸에만** 붙는다
	//     ⇒ λ 를 올리면 **그 칸만 깎여** 오히려 나빠질 수 있다. 그러면 다음 조치는 λ 가 아니라
	//     **워밍업의 불호 커버리지**다(그것까지 미리 갈라 둔다).
	// ⚠️ **실측(1차)에서 최대점이 끝점 λ=0 이었다** ⇒ 미리 못박은 대응대로 **격자를 넓힌다**.
	//   ★ 그리고 **아래로** 넓힌다 — 위쪽 λ 0.5~8 이 **점수·소진율 모두 완전히 동일**했다 =
	//     **포화**다(불호가 이미 아는 칸을 다 음수로 눌러 순위가 안 바뀐다) ⇒ 위는 정보가 없다.
	//   ⚠️⚠️ 그리고 그것이 앞 판정의 해석을 바꾼다: 호/불호 이득 **+0.085** 는 사실 **호의 이득**이고
	//     불호는 그 설정에서 **−0.03 깎았다**(λ=0 이 0.960, λ=1 이 0.930, 커서만 0.845).
	//     ⇒ 지금 물어야 할 것은 *"불호를 얼마나 **작게**"* 다.
	static constexpr int kGnLam = 8;
	static float _GnLamOf(int i)
	{
		const float v[kGnLam] = { 0.0f, 0.02f, 0.05f, 0.1f, 0.25f, 0.5f, 1.0f, 2.0f };
		return v[(i >= 0 && i < kGnLam) ? i : 0];
	}
	float _gnLamScore[kGnArms][kGnLam] = {};   // λ 마다 점수
	float _gnLamUse[kGnArms][kGnLam] = {};     // λ 마다 예산 소진율(소심함의 관측량)
	mutable uint32 _gnSrcExec = 0;           // 소스에서 호를 뽑을 때 쓴 **자기 실행** 횟수
	float  _gnFillSrc = 0.0f, _gnFillAll = 0.0f;   // 표 채움률(소스만 / 전부)
	uint32 _gnOrcWarm = 0;                   // 워밍업이 쓴 오라클 접촉

	// 💗 **소스에서 호를 뽑는다** — 소스는 티칭 캡션의 정답 장면이다(이미 지불된 티칭 재료).
	void _GnValenceFromSource()
	{
		const uint32 nS = (uint32)_gnScenes.Count();
		const uint32 nT = (nS < (uint32)kGnTrain) ? nS : (uint32)kGnTrain;
		// ㉠ **[축][값] 층 — 실행이 아예 필요 없다.** 엄마가 보여준 값이 곧 끌리는 값이다.
		for (uint32 i = 0; i < nT; ++i)
		{
			const MLScene& tr = _gnScenes.Data()[i];
			for (int a = 0; a < 6; ++a)
			{
				const int v = _AxisGet(tr, a);
				if (v >= 0 && v < 8) _gnLikeV[a][v] += kValSrc;
			}
		}
		// ㉡ **[사실][축] 층 — 개입으로 뽑는다.** *"이 축을 만지면 이 사실이 움직인다"* ⇒ 그 사실을
		//   고치고 싶을 때 **끌리는 축**이다.
		//   ⚠️ **정답과 견주지 않는다**(두 자기 실행을 서로 견준다) ⇒ **오라클이 아니다.**
		//     그리고 티칭이 이미 보여준 장면을 재료로 쓰므로 **티칭 횟수도 안 늘어난다.**
		//   ⚠️ 커플링은 실재한다(개수를 바꾸면 면적도 움직인다) ⇒ 호가 **넓게** 붙는다.
		//     그것을 깎는 것은 ㉢ 의 불호이고, **넓은 호 + 좁은 불호**가 이 설계의 분업이다.
		const uint32 nI = (nT < 80u) ? nT : 80u;
		for (uint32 i = 0; i < nI; ++i)
		{
			MLScene base = _gnScenes.Data()[i];
			if (base.exists == 0) continue;          // 빈 장면은 개입해도 사실이 안 뜬다
			MLFrameFacts f0;
			_gnSrcExec++;
			if (!_RenderSceneFacts(base, f0)) continue;
			for (int ax = 0; ax < 6; ++ax)
			{
				const uint32 nv = _AxisClasses(ax);
				if (nv < 2u) continue;
				const int cur = _AxisGet(base, ax);
				for (uint32 d = 1; d < nv; ++d)
				{
					MLScene t2 = base;
					_AxisSet(t2, ax, (int)(((uint32)cur + d) % nv));
					if (!MLSense::Fits(t2)) continue;
					MLFrameFacts f1;
					_gnSrcExec++;
					if (!_RenderSceneFacts(t2, f1)) continue;
					uint8 v[kGnFacts];
					_FactVec(f0, f1, v);
					for (int fi = 0; fi < kGnFacts; ++fi)
						if (v[fi] == 0u) _gnLikeF[fi][ax] += kValSrc;
				}
			}
		}
		// 🚫 **결과-관측 무게를 여기서 도출한다** — 소스가 실제로 깐 규모를 재고 나서 정한다.
		//   ⚠️ 두 층의 규모가 **다르므로**(개입 층이 훨씬 크다) 층마다 따로 잡는다 —
		//     하나로 묶으면 작은 층이 큰 층의 무게에 짓눌린다.
		_gnWRecF = _DeriveRecW(&_gnLikeF[0][0], kGnFacts * 6);
		_gnWRecV = _DeriveRecW(&_gnLikeV[0][0], 6 * 8);
	}

	// 🚫 **찬 칸의 평균에서 결과-관측 무게를 뽑는다.** ⚠️ 빈 칸은 평균에서 뺀다(미지는 규모가 아니다).
	static uint32 _DeriveRecW(const uint32* tbl, int n)
	{
		uint64 sum = 0; uint32 cnt = 0;
		for (int i = 0; i < n; ++i) if (tbl[i] > 0u) { sum += tbl[i]; cnt++; }
		if (cnt == 0u) return 1u;
		const uint32 w = (uint32)(sum / cnt) / kValRecDiv;
		return (w > 0u) ? w : 1u;
	}

	// 💗🚫 **표가 얼마나 찼나** — 함정 50 이 실제로 풀렸는지 **숫자로** 본다(서사로 판정하지 않는다).
	float _GnValFill() const
	{
		uint32 fill = 0, all = 0;
		for (int f = 1; f < kGnFacts; ++f) for (int a = 0; a < 6; ++a)
		{
			if (_AxisClasses(a) < 2u) continue;
			all++;
			if (_gnLikeF[f][a] + _gnDisF[f][a] > 0u) fill++;
		}
		return (all > 0u) ? ((float)fill / (float)all) : 0.0f;
	}

	uint32 _gnCause[6][kGnFacts] = {};     // 배운 표: 축 → 사실
	uint32 _gnCauseN = 0;                  // 개입 횟수
	bool   _gnCauseOk = false;

	// ══════════════════════════════════════════════════════════════════════════
	// 🔬 **배운 표로 축을 고른다 — 손으로 준 표(`_FactToAxis`)를 뗀다.**
	//
	// ★ **왜 이제 할 수 있나**: 개입으로 배운 표가 **4/5 일치**했다(사실→축).
	//   ⇒ 창립 규칙(*"인코딩 층의 구조는 주고 분포 층은 배우게 한다"*)에서 **인과는 분포 층**이었고,
	//     그것을 손으로 주고 있었다는 것이 정직하지 않은 지점이었다(주석에 그렇게 적어 뒀다).
	// ★ 그리고 **부수 효과가 목표와 맞는다**: 손으로 준 표는 사실마다 축을 **하나**(또는 둘) 주지만
	//   배운 표는 **반응한 축 전부**를 준다 ⇒ 🎭 성격(λ)이 **고를 후보**가 생긴다.
	//
	// ⚠️ **크기로 고르면 안 된다(함정 49)**: `개수` 를 바꾸면 `면적` 도 크게 움직여서
	//   `면적 → 개수` 로 잘못 귀속됐다. ⇒ **특이성**으로 고른다:
	//     `spec(축,사실) = C[축][사실] / Σ_f C[축][f]` = *"그 축이 그 사실에만 반응하나"*
	//   ★ 그러면 여러 사실을 흔드는 축(개수)은 특이성이 낮아 밀린다.
	float _CauseSpec(int fact, int axis) const
	{
		if (axis < 0 || axis >= 6 || fact < 0 || fact >= kGnFacts) return 0.0f;
		uint32 tot = 0;
		for (int f = 0; f < kGnFacts; ++f) tot += _gnCause[axis][f];
		if (tot == 0u) return 0.0f;
		return (float)_gnCause[axis][fact] / (float)tot;
	}

	void _GnLearnCausal()
	{
		for (int a = 0; a < 6; ++a) for (int f = 0; f < kGnFacts; ++f) _gnCause[a][f] = 0u;
		_gnCauseN = 0;
		// 장면 여럿에서 축마다 여러 값으로 개입한다.
		for (uint32 t = 0; t < 40u; ++t)
		{
			MLScene base = MLSense::BaseScene(770000u + t * 7919u);
			if (base.exists == 0) base.exists = 1;
			MLFrameFacts f0;
			if (!_RenderSceneFacts(base, f0)) continue;
			for (int ax = 0; ax < 6; ++ax)
			{
				const uint32 nv = _AxisClasses(ax);
				if (nv < 2u) continue;
				const int cur = _AxisGet(base, ax);
				// ★ 그 축의 **다른 값 전부**로 개입한다(한 값만 보면 우연에 흔들린다).
				for (uint32 d = 1; d < nv; ++d)
				{
					MLScene t2 = base;
					_AxisSet(t2, ax, (int)(((uint32)cur + d) % nv));
					if (!MLSense::Fits(t2)) continue;
					MLFrameFacts f1;
					if (!_RenderSceneFacts(t2, f1)) continue;
					// ⚠️ **두 실행을 서로 견준다**(원본 장면과 견주지 않는다) — 우리가 바꾼 것이
					//   축 하나뿐이므로 달라진 사실은 **그 축이 일으킨 것**이다(개입의 정의).
					uint8 v[kGnFacts];
					_FactVec(f0, f1, v);
					for (int fi = 0; fi < kGnFacts; ++fi) if (v[fi] == 0u) _gnCause[ax][fi]++;
					_gnCauseN++;
				}
			}
		}
		_gnCauseOk = (_gnCauseN > 0u);
	}

	// ⚖️ **배운 표가 손으로 준 표와 맞나** — 판정. ⚠️ 기준을 미리 못박았다:
	//   사실마다 **가장 강하게 반응한 축**이 `_FactToAxis` 가 말하는 축과 같다(5항목 중 **4개 이상**).
	//   ★ 그리고 `없나/있나`(사실 0)는 어느 축으로도 안 바뀌는 것이 정상이다(존재는 축이 아니다) ⇒ 제외.
	void _JudgeCausal()
	{
		LogA("\n[ml] 🔬 **인과 표를 개입으로 배웠다** — 축을 일부러 바꿔 **어느 사실이 달라지나** 봤다\n"
			"[ml]   개입 %u회 · ★ 아무도 안 알려줬다(상관이 아니라 **개입**이라 인과가 나온다)\n"
			"[ml]   %-8s %8s %8s %8s %8s %8s %8s\n",
			_gnCauseN, "축", "있나", "덩어리", "색", "면적", "자리", "채움");
		static const char* an[6] = { "개수", "모양", "색", "크기", "자리", "속" };
		for (int a = 0; a < 6; ++a)
			LogA("[ml]   %-8s %7u%% %7u%% %7u%% %7u%% %7u%% %7u%%\n", an[a],
				_gnCause[a][0] * 100u / ((_gnCauseN > 0u) ? _gnCauseN / 6u + 1u : 1u),
				_gnCause[a][1] * 100u / ((_gnCauseN > 0u) ? _gnCauseN / 6u + 1u : 1u),
				_gnCause[a][2] * 100u / ((_gnCauseN > 0u) ? _gnCauseN / 6u + 1u : 1u),
				_gnCause[a][3] * 100u / ((_gnCauseN > 0u) ? _gnCauseN / 6u + 1u : 1u),
				_gnCause[a][4] * 100u / ((_gnCauseN > 0u) ? _gnCauseN / 6u + 1u : 1u),
				_gnCause[a][5] * 100u / ((_gnCauseN > 0u) ? _gnCauseN / 6u + 1u : 1u));
		// 사실마다 최강 축을 뽑아 손으로 준 표와 견준다(사실 0 = 존재는 제외).
		int hit = 0, all = 0;
		for (int fi = 1; fi < kGnFacts; ++fi)
		{
			int bestAx = 0; uint32 bestC = 0u;
			for (int a = 0; a < 6; ++a) if (_gnCause[a][fi] > bestC) { bestC = _gnCause[a][fi]; bestAx = a; }
			const int want = _FactToAxis(fi, 0);
			const int want2 = _FactToAxis(fi, 1);
			all++;
			const bool ok = (bestAx == want) || (bestAx == want2);
			if (ok) hit++;
			LogA("[ml]   사실 %d → 배운 축 **%s**(%u) · 손으로 준 축 %s%s → %s\n",
				fi, an[bestAx], bestC, an[(want >= 0) ? want : 0],
				(want2 != want) ? "/(또는 다른 하나)" : "", ok ? "일치" : "★다름★");
		}
		// ⚠️ 항목이 4개(사실 1~4) → **5개**(1~5)로 늘었으므로 기준도 **비율을 유지**해 올린다
		//   (3/4 = 75% ⇒ 4/5 = 80%). ★ 결과를 보고 기준을 고르지 않으려고 여기 근거를 적는다.
		const bool okC = (hit >= 4);
		LogA("[ml]   ⚖️ 인과 학습 판정: %d/%d 일치 (기준 4 이상) → %s\n"
			"[ml]      ★ 통과면 **\"왜 틀렸나\" 를 줄 필요가 없다** — 개입으로 배운다.\n"
			"[ml]        ⇒ 지시된 수정의 표를 **배운 것으로 갈아 끼울 수 있다**(다음 단계).\n"
			"[ml]      ⚠️ 지금은 CPU 카운팅으로 배운다(CPU-레퍼런스-먼저) — 되면 신경망으로 옮긴다.\n",
			hit, all, okC ? "통과" : "★실패★");
	}

	// 🔤 **축의 낱말** — 장면의 그 축 값에 해당하는 낱말(생성기와 **같은 표**를 본다).
	static const char* _WordOfAxis(const MLScene& sc, int axis)
	{
		if (axis == 0) return MLSense::WordCount(sc.count);
		if (axis == 1) return MLSense::WordShape(sc.shape);
		if (axis == 2) return MLSense::WordColor(sc.color);
		if (axis == 3) return MLSense::WordSize(sc.big);
		if (axis == 4) return MLSense::WordPos(sc.pos);
		return MLSense::WordFill(sc.filled);
	}

	// 🔤 바이트열에서 낱말 하나를 갈아 끼운다. ⚠️ 없으면 `false`(그 축은 못 고친다 — 정직한 한계).
	static bool _ReplaceWord(Array<uint8>& b, const char* from, const char* to)
	{
		uint32 nf = 0; while (from[nf] != 0) nf++;
		uint32 nt = 0; while (to[nt] != 0) nt++;
		if (nf == 0u) return false;
		const uint32 n = (uint32)b.Count();
		for (uint32 i = 0; i + nf <= n; ++i)
		{
			bool same = true;
			for (uint32 j = 0; j < nf && same; ++j)
				if (b.Data()[i + j] != (uint8)from[j]) same = false;
			if (!same) continue;
			Array<uint8> out;
			for (uint32 k = 0; k < i; ++k) out.Add(b.Data()[k]);
			for (uint32 k = 0; k < nt; ++k) out.Add((uint8)to[k]);
			for (uint32 k = i + nf; k < n; ++k) out.Add(b.Data()[k]);
			b = out;
			return true;
		}
		return false;
	}

	// ══════════════════════════════════════════════════════════════════════════
	// 🧠 **지시된 수정(directed revision) — "이유있는 추론" 의 최소 형태.**
	//
	// ★ **왜 이것이 랜덤 샘플링과 근본적으로 다른가 — 탐색이 곱에서 합으로 바뀐다.**
	//   랜덤 재시도: 5축을 맞히려면 `2^5 = 32` 방향을 뒤진다 (**곱**)
	//   지시된 수정: 틀린 축만 하나씩 고친다 → `5` 방향 (**합**)
	//   ⇒ *"적은 경험으로 많은 인과 연결"* 이 정확히 **곱을 합으로 바꾸는 것**이고,
	//     그것은 **데이터가 아니라 구조**다(학습량의 문제가 아니다).
	//
	// ★ **그리고 이것이 갓 태어난 동물이 하는 것이다**: *"여기 없네"* 를 **기억하고
	//   거기 다시 안 간다.** 랜덤 재시도는 같은 데를 또 뒤진다.
	//   ⇒ 그래서 **축마다 커서**를 든다(`cursor[]`) — 실패해도 커서가 전진하므로 **같은 값을 두 번
	//     시도하지 않는다.** 그 한 줄이 "기억" 이고, 그것이 없으면 제자리를 맴돈다.
	//
	// ⚠️ **인과 표(`_FactToAxis`)는 배운 것이 아니라 판독기 규약이 준 것**이다 — 정직하게 적어 둔다.
	//   ★ 이 프로젝트의 창립 규칙과 맞는다: *"인코딩 층의 구조는 주고, 분포 층은 배우게 한다."*
	//     *"무엇이 틀렸으면 무엇을 바꿔야 하나"* 는 **채점기의 구조**이고, 무엇을 말할지는 모델이 배운다.
	//
	// ⚠️ **예산을 랜덤과 같게 맞춘다**(실행 횟수 `budget`) — 안 그러면 비교가 무의미하다.
	float _GnDirected(uint32 cap, const Array<float>& slot, const Array<float>& pos,
		const Array<float>& csl, const Array<float>& wh,
		const Array<float>& wq, const Array<float>& wk, const Array<float>& wv,
		const Array<float>& wc, const Array<float>& wc1,
		const Array<float>& w1, const Array<float>& w2,
		uint32 budget, uint32 seed, MLScene& outBest,
		Array<uint8>* outFirstCap = nullptr, MLScene* outFirstScene = nullptr,
		bool useValence = false, bool learnValence = false, bool oracleFree = false,
		float disScale = 1.0f, uint32* outUsed = nullptr, bool useLearned = false,
		bool stochastic = false)
	{
		const uint32 plane = kGnW * kGnH;
		MLFrameFacts fT;
		// 🔮 **여기가 오라클이다** — 정답 장면을 만진다. 캡션마다 **한 번**만 만지고 재사용한다.
		_gnOracle++;
		if (!_RenderSceneFacts(_gnScenes.Data()[cap], fT)) return 0.0f;

		// ① 첫 시도 — 감이어도 된다(추론은 **그 다음**에 일어난다).
		Array<uint8> g0;
		_GenDecode(_gnFrameBytes.Data() + (uint64)cap * plane, slot, pos, csl, wh,
			wq, wk, wv, wc, wc1, w1, w2, g0, kGnTemp, seed);
		MLScene sc;
		_ParseCaption(g0, sc);
		MLFrameFacts f;
		if (!_RenderSceneFacts(sc, f)) return 0.0f;
		// ★ 타깃을 만들려면 **첫 시도의 캡션과 장면**이 필요하다(낱말 치환의 기준점).
		if (outFirstCap != nullptr) *outFirstCap = g0;
		if (outFirstScene != nullptr) *outFirstScene = sc;
		float best = _FactScore(fT, f);
		outBest = sc;
		uint32 used = 1u;
		if (outUsed != nullptr) *outUsed = used;

		// ② 지시된 수정 — **맞은 축은 그대로 두고 틀린 축만** 다음 값으로.
		int cursor[6] = { 0, 0, 0, 0, 0, 0 };
		uint8 tried[6][8] = {};        // 💗🚫 값마다 써봤나(호/불호 선택이 이것을 본다)
		int lastAx = -1, lastV = -1;   // 방금 무엇을 바꿨나(기록에 쓴다)
		int existTried = 0;
		while (used < budget && best < 1.0f)
		{
			uint8 v[kGnFacts];
			_FactVec(fT, f, v);
			// ⚠️⚠️ **뒤쪽 사실이 굶는다 — 실측(함정 59)**: *"첫 번째 틀린 사실"* 만 고르니
			//   마지막 항목(채움)의 기록이 **호 25** 인데 앞 항목은 **10968** 이었다(400배).
			//   ⇒ 그 항목의 호/불호는 **배울 기회 자체가 없었다.**
			// ★ 조치: 틀린 항목들 중에서 **돌려 고른다**(라운드 로빈) — 시도마다 시작점을 옮긴다.
			//   ⚠️ 랜덤이 아니라 회전이다 — 결정성을 지킨다(같은 실행이 같은 표를 낸다).
			int wrong = -1;
			for (int k = 0; k < kGnFacts; ++k)
			{
				const int i = (int)(((uint32)k + used) % (uint32)kGnFacts);
				if (v[i] == 0u) { wrong = i; break; }
			}
			if (wrong < 0) break;                     // 다 맞았다

			MLScene t = sc;
			// 💗🚫 **호/불호로 축을 고른다** — 그 사실이 틀렸을 때 **좋았던 축**부터.
			//   ⚠️ 경험이 없으면 `_Pref` 가 0 이라 **손으로 준 표로 떨어진다**(무지 = 기존 동작).
			int ax = _FactToAxis(wrong, cursor[3]);
			// 🔬 **배운 표로 후보를 낸다** — 특이성 순으로, 커서가 그 안에서 돈다.
			//   ⚠️ 배운 표가 그 사실에 아무 축도 안 주면(전부 0) **손으로 준 표로 떨어진다** —
			//     조용히 실패하지 않게 하고, 그 경우가 몇 번인지도 센다.
			if (useLearned && _gnCauseOk)
			{
				int cand[6]; int nc = 0;
				for (int a2 = 0; a2 < 6; ++a2)
				{
					if (_AxisClasses(a2) < 2u) continue;
					if (_gnCause[a2][wrong] == 0u) continue;      // 그 축은 그 사실을 안 흔든다
					cand[nc++] = a2;
				}
				// 특이성 내림차순(후보가 6개 이하라 단순 선택 정렬이 값싸다).
				for (int i2 = 0; i2 < nc; ++i2)
					for (int j2 = i2 + 1; j2 < nc; ++j2)
						if (_CauseSpec(wrong, cand[j2]) > _CauseSpec(wrong, cand[i2]))
						{ const int t2 = cand[i2]; cand[i2] = cand[j2]; cand[j2] = t2; }
				if (nc > 0) ax = cand[cursor[3] % nc];
				else _gnLearnMiss++;
			}
			// ══════════════════════════════════════════════════════════════════════
			// 🎲🎭 **확률적 선택 — λ 가 조종하는 것을 이산 순위에서 연속 분포로 바꾼다.**
			//
			// ⚠️⚠️ **실측이 요구했다(함정 60)**: λ 를 `{0 … 8}` 로 훑어도 곡선이 **계단 두 개**뿐이었다.
			//   원인은 λ 가 **연속 손잡이인데 그것이 조종하는 것이 `argmax`(이산 순위)** 인 것이다 —
			//   순위가 한 번 뒤집히면 λ 를 더 키워도 **아무 일도 안 일어난다.**
			//   ★ 그래서 *"기피가 얼마나 강한가"* 가 **정도로 나타날 자리가 없었다.**
			// ★ 그래서 **선호 비례 샘플링**으로 바꾼다:
			//     `w_a = 호_a / (호_a + λ·불호_a + 1)`  ∈ (0, 1)
			//   ⇒ λ 에 **연속적으로** 반응하고, `+1` 은 경험이 적은 칸을 과신하지 않게 한다(`_Pref` 와 같은 이유).
			// ★ 그리고 **포기가 공짜로 따라온다** — 추가 상수가 없다:
			//     `움직일 확률 = max_a w_a`  ⇒  `1 − max w` 의 확률로 **아무것도 안 한다**
			//   · λ=0   → `w ≈ 1` → 거의 안 포기 = **무모함**(안 피하니 같은 데 또 간다)
			//   · λ 큼  → 불호 있는 축의 `w → 0` → 자주 포기 = **소심함**(*"확신 전엔 모르겠어요"*)
			//   ⇒ 두 병리가 **λ 의 연속 함수**가 되고, 소심함은 **예산 소진율**로 직접 보인다.
			// ⚠️ **결정적이다** — 씨앗 해시로 뽑는다(같은 실행이 같은 결과를 낸다). `used` 가 섞여 있어
			//   같은 캡션 안에서도 스텝마다 다른 뽑기가 나온다.
			if (stochastic && useValence)
			{
				float wts[6] = {}; float tot = 0.0f, wmax = 0.0f; int nc2 = 0;
				for (int a2 = 0; a2 < 6; ++a2)
				{
					if (_AxisClasses(a2) < 2u) continue;
					if ((uint32)cursor[a2] + 1u >= _AxisClasses(a2)) continue;
					if (_gnLikeF[wrong][a2] + _gnDisF[wrong][a2] == 0u) continue;   // 미지는 뺀다
					const float lk = (float)_gnLikeF[wrong][a2];
					const float ds = disScale * (float)_gnDisF[wrong][a2];
					const float w = lk / (lk + ds + 1.0f);
					wts[a2] = w; tot += w; nc2++;
					if (w > wmax) wmax = w;
				}
				if (nc2 > 0 && tot > 0.0f)
				{
					const uint32 h1 = _GnHash(seed, used, 17u);
					const float u1 = (float)(h1 % 100000u) * 0.00001f;
					// ★ 확신이 없으면 **안 움직인다**(포기) — 그것이 소심함의 관측 가능한 형태다.
					if (u1 > wmax) break;
					const uint32 h2 = _GnHash(seed, used, 91u);
					float r = (float)(h2 % 100000u) * 0.00001f * tot;
					int pick = -1;
					for (int a2 = 0; a2 < 6; ++a2)
					{
						if (wts[a2] <= 0.0f) continue;
						r -= wts[a2];
						if (r <= 0.0f) { pick = a2; break; }
					}
					if (pick >= 0) ax = pick;
				}
			}
			else if (useValence)
			{
				float bestP = -2.0f; int bestA = ax;
				for (int a2 = 0; a2 < 6; ++a2)
				{
					if (_AxisClasses(a2) < 2u) continue;
					if ((uint32)cursor[a2] + 1u >= _AxisClasses(a2)) continue;   // 그 축은 다 돌았다
					// ⚠️⚠️ **빈 칸은 "미지" 다 — 선호 0 이 아니다**(함정 50 의 둘째 뿌리).
					//   ★ 선호 0 으로 두면 *"아무 경험도 없다"* 가 *"겪었는데 호와 불호가 같다"* 를
					//     이기고 타이브레이크를 **아무 축이나** 가져간다(실측: `덩어리 → 모양`).
					//   ⇒ **흐림과 호/불호가 다른 축**이라는 설계가 여기서 실제로 필요해진다:
					//     미지는 **선호가 아니라 흐림**이므로 선호 최대값 경쟁에서 **빠져야** 한다.
					if (_gnLikeF[wrong][a2] + _gnDisF[wrong][a2] == 0u) continue;
					const float pr = _Pref(_gnLikeF[wrong][a2], _gnDisF[wrong][a2], disScale);
					if (pr > bestP) { bestP = pr; bestA = a2; }
				}
				// ★ 경험이 있으면 그것을 따르고(양수든 음수든 **가장 덜 나쁜** 축), 없으면 준 표를 쓴다.
				if (bestP > -2.0f) ax = bestA;
			}
			if (ax < 0)
			{
				if (existTried > 0) break;            // 존재는 값이 둘뿐이다
				existTried++;
				t.exists = (sc.exists != 0) ? 0 : 1;
				if (t.exists != 0 && t.count < 1) t.count = 1;
			}
			else
			{
				// ★ **커서가 전진한다** ⇒ 같은 값을 다시 시도하지 않는다("이미 확인한 데는 안 간다").
				const uint32 nv = _AxisClasses(ax);
				if (nv < 2u) break;
				cursor[ax]++;
				if ((uint32)cursor[ax] >= nv) break;  // 그 축을 다 돌았다
				const int cur = _AxisGet(sc, ax);
				int nextV = (int)(((uint32)cur + (uint32)cursor[ax]) % nv);
				// 💗🚫 **호/불호로 값을 고른다** — 아직 안 써본 값 중 **가장 좋았던 것**.
				//   ★ 이것이 커서(*"이미 해봤다"*)를 **"나쁜 데는 안 가고 좋은 데를 먼저"** 로 승격한다.
				if (useValence && nv <= 8u)
				{
					float bestP = -2.0f;
					for (uint32 d = 1; d < nv; ++d)
					{
						const int cand = (int)(((uint32)cur + d) % nv);
						if (tried[ax][cand] != 0u) continue;       // 이미 써봤다
						// ⚠️ 미지는 빼낸다(위와 같은 이유) — 커서가 그 자리를 대신 맡는다.
						if (_gnLikeV[ax][cand] + _gnDisV[ax][cand] == 0u) continue;
						const float pr = _Pref(_gnLikeV[ax][cand], _gnDisV[ax][cand], disScale);
						if (pr > bestP) { bestP = pr; nextV = cand; }
					}
				}
				if (nextV >= 0 && nextV < 8) tried[ax][nextV] = 1u;
				_AxisSet(t, ax, nextV);
				lastAx = ax; lastV = nextV;
			}

			MLFrameFacts f2;
			if (!_RenderSceneFacts(t, f2)) break;
			used++;
			// 🔮 **오라클 없는 모드**: 정답과 견주지 않고 **내 호/불호가 좋아하나**로 고른다.
			//   ★ 그것이 생명체 쪽이다 — 승패를 못 받으니 **쌓아 둔 선호**로 판단한다.
			//   ⚠️ 그리고 그 판단은 틀릴 수 있다(오라클이 아니니까) — 그 대가를 재는 것이 이 실험이다.
			//   ⚠️ `f2` 는 **자기 상상의 실행 결과**다(오라클이 아니다) — 오라클은 `fT` 쪽이다.
			float sc2;
			if (oracleFree)
			{
				// 선호 = 방금 바꾼 (사실→축) 과 (축→값) 의 호/불호 합. ★ 오라클을 안 본다.
				const float pf = (lastAx >= 0)
					? _Pref(_gnLikeF[wrong][lastAx], _gnDisF[wrong][lastAx], disScale) : 0.0f;
				const float pv = (lastAx >= 0 && lastV >= 0 && lastV < 8)
					? _Pref(_gnLikeV[lastAx][lastV], _gnDisV[lastAx][lastV], disScale) : 0.0f;
				// ⚠️ 점수 축이 다르므로(선호 vs 사실 일치율) **best 와 직접 못 견준다** ⇒
				//   선호가 양수면 채택한다(끌리면 간다 · 불호면 안 간다).
				sc2 = (pf + pv > 0.0f) ? (best + 0.001f) : (best - 0.001f);
			}
			else sc2 = _FactScore(fT, f2);
			// 💗🚫 **겪은 것을 양쪽 다 기록한다**(맞은 것도 틀린 것도) — 한쪽만 세면 빈도에 휩쓸린다.
			//   ★ 그리고 이 표는 **캡션과 라운드를 넘어 누적**되므로 *"틀린 경험이 다음의 단서"* 가 된다.
			if (learnValence && lastAx >= 0)
			{
				// ㉡ **맞았다 → 강렬 호**(+4) · ㉢ **틀렸다 → 불호**(+1).
				//   ★ 기본 호(+1)는 이미 **소스**가 깔았다(`_GnValenceFromSource`) ⇒ 여기서 또 안 붙인다.
				//   ★ 비대칭이 의도다: 맞은 것을 **강하게** 끌어야 소스가 넓게 깔아 둔 호 중에서
				//     **실제로 되는 것**이 위로 올라온다(안 그러면 넓은 호가 다 비슷해 못 고른다).
				//   ⚠️ 불호가 생기는 자리는 **여기뿐**이다 — *"틀렸다"* 는 말을 들을 때.
				//   ★ **같은 무게**다 — 편향은 기록이 아니라 **선택(λ)** 이 준다.
				//
				// ══════════════════════════════════════════════════════════════════
				// 🎯 **귀속(credit assignment) — 축이 무죄인데 벌받지 않게 한다.**
				//
				// ⚠️⚠️ **실측이 이것을 요구했다**(함정 54): 정직한 출력이 인과 매핑은 **다 맞았는데**
				//   (덩어리→개수 · 색→색 · 자리→자리) 그 칸들의 **선호가 음수**임을 보였다
				//   (−0.26 / −0.13 / −0.23 · 갈등 0.59~0.77). ★ 이유: 축은 **제대로 골랐는데
				//   값을 틀리면** 그 실패가 **축 앞으로** 기록됐다 ⇒ 축이 무죄인데 벌을 받았다.
				// ★ 그리고 그것을 **갈등 채널이 잡아냈다** — 두 채널로 든 설계의 값이다:
				//   *"둘 다 높음 = 그 단위가 두 가지를 섞고 있다 ⇒ 쪼개야 한다"* 가 그대로 발화했고,
				//   섞인 두 가지가 **축 선택**과 **값 선택**이었다.
				//
				// ㉠ ★ **불호를 `[축][값]` 층에서 뺀다** — 그 층은 **문맥이 없다.**
				//   *"이 장면에서 그 값이 안 맞았다"* 는 **그 장면의 사정**이고, 값에 누적하면
				//   **빈도 편향**만 배운다(그래서 실측에서 해로웠다: λ=0 이 0.960, λ>0 이 0.930).
				//   ⇒ 판정 규칙: ***"호는 문맥 없이도 뜻이 있고(사전), 불호는 문맥이 있어야 뜻이 있다."***
				//   ★ 호는 남긴다 — 소스가 깐 **값의 사전**은 문맥 없이도 유용하다(엄마가 보여준 값).
				// ㉡ ★ **`[사실][축]` 불호는 그 축을 다 써봤는데도 안 고쳐졌을 때만.**
				//   그 층은 *"그 사실이 틀렸다"* 가 **문맥 그 자체**라 불호가 뜻을 갖는다. 다만
				//   **값이 남아 있으면 아직 축을 반증한 것이 아니다** ⇒ 소진했을 때만 축에 붙인다.
				const bool good = (sc2 > best);
				if (good)
				{
					_gnLikeF[wrong][lastAx] += _gnWRecF;
					if (lastV >= 0 && lastV < 8) _gnLikeV[lastAx][lastV] += _gnWRecV;
				}
				else
				{
					// ══════════════════════════════════════════════════════════════
					// 🚫 **불호의 뜻을 좁힌다 — "무관" 만 센다(함정 58).**
					//
					// ⚠️⚠️ **실측이 요구했다**: 귀속을 고친 뒤에도 λ=0(불호 무시)이 가장 좋았다
					//   (0.825 vs 0.725). 원인은 **불호가 두 가지를 섞고 있는 것**이다:
					//     ㉠ *"그 축은 그 사실과 **무관**하다"* ← 정보다
					//     ㉡ *"그 축 **혼자로는 부족**하다"* ← 다원인 사실에서는 **모든 축에** 붙으므로 정보가 0이다
					//   ★ `면적` 의 아는 축이 **3개**(개수·크기·속)이고 **셋 다 진짜로 영향**을 준다 ⇒
					//     한 축을 소진해도 그것은 무관의 증거가 아니다. 그런데 앞 코드는 그것을 불호로 셌다.
					// ★ **가르는 정보가 이미 있다**: `_FactVec` 이 *"그 사실이 **움직였나**"* 를 말한다.
					//   ⇒ **안 움직였을 때만** 불호(무관). 움직였는데 점수가 안 오른 것은 **불호가 아니다.**
					//   ⚠️ 여기서 "움직였다" 는 **그 사실 항목의 맞음/틀림이 뒤집혔나**가 아니라
					//     *"그 축을 건드려 그 사실이 달라졌나"* 다 ⇒ 개입 전후의 사실 벡터를 견준다.
					uint8 vb[kGnFacts];
					_FactVec(f, f2, vb);                       // f = 바꾸기 전 · f2 = 바꾼 뒤
					const bool moved = (vb[wrong] == 0u);      // 그 항목이 **달라졌다** = 이 축이 그것을 흔든다
					if (!moved) _gnDisF[wrong][lastAx] += _gnWRecF;
					// ⚠️ `_gnDisV` 에는 안 붙인다 — 문맥이 없는 자리다(앞 절).
				}
				_gnValN++;
			}
			// ★ 나아졌으면 **채택**(그 축은 이제 "맞은 것" 이 되어 다음 수정의 대상에서 빠진다).
			if (sc2 > best) { best = sc2; sc = t; f = f2; outBest = t; }
			if (outUsed != nullptr) *outUsed = used;
		}
		// 🔮 오라클 없는 모드는 **마지막에 한 번** 진짜 점수를 낸다(보고용 — 고르는 데는 안 썼다).
		if (oracleFree)
		{
			MLFrameFacts fEnd;
			if (_RenderSceneFacts(sc, fEnd)) best = _FactScore(fT, fEnd);
		}
		return best;
	}

	// 📏 **정렬 유사도** = `1 − 편집거리 / max(길이)` ∈ [0,1]. 레벤슈타인(삽입·삭제·치환 1).
	//   ★ **왜 이것이 주 지표인가 — 바이트 일치율이 실패 모드를 안 벌했다**(함정 44):
	//     `byteAll = max(정답, 생성)` 로 나누니 **긴 오답**의 분모만 커졌다 ⇒
	//     `아래 작은 노란 동그라미 있다!`(정답 `없다.`)가 7%대를 받았다.
	//   ★ 편집거리는 그 삽입들을 **전부 비용으로** 센다 ⇒ 손으로 검산했다(함정 44 의 규칙):
	//     `없다.` vs `없다.` → 거리 0 → 유사도 **1.00** · 위 긴 오답 → 유사도 **낮음**. ✅
	//   ⚠️ 그리고 **섞음 대비 이득**으로 정규화한다(이 저장소의 보편 척도) — 캡션 분포를 외운
	//     것만으로도 어느 정도 겹치므로, 그 바닥을 빼야 *"프레임을 봤나"* 가 남는다.
	static float _AlignSim(const Array<uint8>& gen, const String& want)
	{
		const char* w = want.ptr();
		const uint32 n = (uint32)gen.Count();
		const uint32 m = (w != nullptr) ? _CStrLen(w) : 0u;
		if (n == 0u && m == 0u) return 1.0f;
		if (n == 0u || m == 0u) return 0.0f;
		// DP 한 줄만 든다(캡션이 48바이트 이하라 넉넉하다).
		Array<uint32> prev, cur;
		prev.Reset(m + 1u);  cur.Reset(m + 1u);
		for (uint32 j = 0; j <= m; ++j) prev.Data()[j] = j;
		for (uint32 i = 1; i <= n; ++i)
		{
			cur.Data()[0] = i;
			for (uint32 j = 1; j <= m; ++j)
			{
				const uint32 cost = (gen.Data()[i - 1u] == (uint8)w[j - 1u]) ? 0u : 1u;
				uint32 best = prev.Data()[j - 1u] + cost;      // 치환/일치
				const uint32 del = prev.Data()[j] + 1u;        // 삭제
				const uint32 ins = cur.Data()[j - 1u] + 1u;    // 삽입
				if (del < best) best = del;
				if (ins < best) best = ins;
				cur.Data()[j] = best;
			}
			for (uint32 j = 0; j <= m; ++j) prev.Data()[j] = cur.Data()[j];
		}
		const uint32 dist = prev.Data()[m];
		const uint32 mx = (n > m) ? n : m;
		return 1.0f - ((float)dist / (float)mx);
	}

	static uint32 _CStrLen(const char* s2)
	{ uint32 n = 0; while (s2[n] != 0) n++; return n; }
	// ⚠️ **문자열은 바이트 버퍼로 조립한다**(함정 22: `AppendFormat("%c", …)` 는 한글을 버린다) —
	//   `Bytes::Reset(n+1)` 뒤 `GetData()` 에 직접 쓰는 것이 이 저장소의 관용구다.
	static void _BytesToString(const Array<uint8>& b, String& out)
	{
		const uint32 n = (uint32)b.Count();
		Bytes z;
		z.Reset((uint64)n + 1ull);
		uint8* q = (uint8*)z.GetData();
		for (uint32 i = 0; i < n; ++i) q[i] = b.Data()[i];
		q[n] = 0u;
		out = String((const char*)q);
	}
	static bool _SameBytes(const Array<uint8>& b, const String& s2)
	{
		const char* p = s2.ptr();
		if (p == nullptr) return false;
		const uint32 n = _CStrLen(p);
		if (n != (uint32)b.Count()) return false;
		for (uint32 i = 0; i < n; ++i) if ((uint8)p[i] != b.Data()[i]) return false;
		return true;
	}
	// 유효한 UTF-8 인가 — ★ 이어짐 바이트가 선행 바이트 뒤에만 오나. ⚠️ 잘린 문자도 거절한다.
	static bool _IsValidUtf8(const Array<uint8>& b)
	{
		const uint32 n = (uint32)b.Count();
		if (n == 0u) return false;
		uint32 i = 0;
		while (i < n)
		{
			const uint8 c = b.Data()[i];
			uint32 need = 0;
			if (c < 0x80u) need = 0;
			else if ((c & 0xE0u) == 0xC0u) need = 1;
			else if ((c & 0xF0u) == 0xE0u) need = 2;
			else if ((c & 0xF8u) == 0xF0u) need = 3;
			else return false;                       // 이어짐 바이트가 선행 자리에 왔다
			if (i + need >= n) return false;         // 잘렸다
			for (uint32 k = 1; k <= need; ++k)
				if ((b.Data()[i + k] & 0xC0u) != 0x80u) return false;
			i += need + 1u;
		}
		return true;
	}

	bool _ZeroTensorIn(MLArena& a, const MLTensor& t)
	{
		Array<float> z;
		z.Reset(t.Count());
		for (uint32 i = 0; i < t.Count(); ++i) z.Data()[i] = 0.0f;
		return a.Write(t, z);
	}

	// 📥 한 (팔, 축) 의 평가 결과를 기록한다.
	bool _RecordAxis()
	{
		const uint32 nAll = kPTrain + kPTest;
		Bytes bp;
		if (!_vis.Read(_tPProbAll, bp) || bp.GetSize() != (uint64)nAll * kPCMax * sizeof(float))
		{
			LogA("[ml] 접지 프로브: 평가 회수가 안 됐다([%s] 축 %s)\n",
				_ArmName(_pArm), _PAxisName(_pAxis));
			return false;
		}
		const float* pr = (const float*)bp.GetData();
		float ceTr = 0.0f, ceTe = 0.0f;
		int hitTr = 0, hitTe = 0;
		// 📊 개수계 축이면 **틀리는 모양**을 센다 — 세 가설이 여기서 갈린다.
		//   ★ 참값별 정확도(㉡ subitizing) · 평균 |예측−정답|(㉢ 순서) · 오답 중 ±1 비율(㉢).
		const int cslot = _PCountSlot(_pAxis);
		int clsHit[6] = {}, clsAll[6] = {};
		int ordSum = 0, wrong = 0, adj = 0;
		for (uint32 i = 0; i < nAll; ++i)
		{
			const float* q = pr + (uint64)i * kPCMax;   // ⚠️ 행 간격은 kPCMax
			const int label = _pLabels.Data()[i];
			int arg = 0;
			// ★ **없는 분류까지 포함해 argmax** 한다 — 그것이 모델의 실제 예측이고, 없는 것을 골랐다면
			//   그건 봐줄 일이 아니라 오답이다.
			for (uint32 c = 1; c < kPCMax; ++c) if (q[c] > q[arg]) arg = (int)c;
			const float ce = _CeOne(q, label);
			if (i < kPTrain) { ceTr += ce; if (arg == label) hitTr++; }
			else
			{
				ceTe += ce; if (arg == label) hitTe++;
				if (cslot >= 0 && label >= 0 && label < 6)
				{
					clsAll[label]++;
					if (arg == label) clsHit[label]++;
					const int d = (arg > label) ? (arg - label) : (label - arg);
					ordSum += d;
					if (d != 0) { wrong++; if (d == 1) adj++; }
				}
			}
		}
		if (cslot >= 0)
		{
			String line;
			static const char* nm[6] = { "1", "2", "3", "4", "5", "여럿" };
			for (int c = 0; c < 6; ++c)
			{
				const float a = (clsAll[c] > 0)
					? (100.0f * (float)clsHit[c] / (float)clsAll[c]) : 0.0f;
				_pPerCls[_pArm][cslot][c] = a;
				line.AppendFormat("  %s=%.0f%%", nm[c], (double)a);
			}
			_pOrdErr[_pArm][cslot] = (kPTest > 0u) ? ((float)ordSum / (float)kPTest) : 0.0f;
			_pAdjFrac[_pArm][cslot] = (wrong > 0) ? ((float)adj / (float)wrong) : 0.0f;
			_pWrong[_pArm][cslot] = wrong;
			LogA("[ml]   📊 개수별 시험 정확도 —%s\n"
				"[ml]      평균 |예측−정답| **%.2f** · 오답 %d개 중 ±1 인 비율 **%.0f%%**\n"
				"[ml]      ★ 작은 개수만 맞고 큰 개수가 무너지면 **subitizing 서명**(절차가 없다).\n"
				"[ml]      ★ ±1 비율이 **낮으면** 모델이 숫자를 **순서 없는 이름**으로 배운 것이다\n"
				"[ml]        (one-hot 이 계승을 지웠다) — 높으면 **크기(면적)로 재는 중**이다.\n",
				line.ptr(), (double)_pOrdErr[_pArm][cslot], wrong,
				(double)(100.0f * _pAdjFrac[_pArm][cslot]));
		}
		_pCeTr[_pArm][_pAxis]  = ceTr / (float)kPTrain;
		_pCeTe[_pArm][_pAxis]  = ceTe / (float)kPTest;
		_pAccTr[_pArm][_pAxis] = 100.0f * (float)hitTr / (float)kPTrain;
		_pAccTe[_pArm][_pAxis] = 100.0f * (float)hitTe / (float)kPTest;
		LogA("[ml]   → 학습 %.4f nat / %.1f%%   ·   시험 %.4f nat / %.1f%%   (이득 %+.2f)\n",
			(double)_pCeTr[_pArm][_pAxis], (double)_pAccTr[_pArm][_pAxis],
			(double)_pCeTe[_pArm][_pAxis], (double)_pAccTe[_pArm][_pAxis],
			(double)_Gain(_pAccTe[_pArm][_pAxis], _pClasses));
		return true;
	}

	// ★ **판독 척도 = 우연 대비 정규화 이득** `(정확도 − 우연) / (100 − 우연)`.
	//   `0` = 우연 · `1` = 완벽. ⇒ **분류 수가 다른 축끼리 견줄 수 있다**(2분류와 6분류를 같은 자로 본다).
	static float _Gain(float accPct, uint32 classes)
	{
		const float chance = 100.0f / (float)classes;
		return (accPct - chance) / (100.0f - chance);
	}

	// 확률 벡터 하나의 교차엔트로피(정답 하나). ⚠️ `log(0)` 을 막는다.
	static float _CeOne(const float* probs, int label)
	{
		float pr = probs[label];
		if (pr < 1.0e-12f) pr = 1.0e-12f;
		return -Log(pr);
	}

	// ㉡ **접지 판정 — 두 판독을 나란히.**
	//
	// ★ **판정 척도를 CE 에서 정확도(정규화 이득)로 옮겼다 — 그 근거를 남긴다.**
	//   ⚠️⚠️ 처음에는 *"시험 CE < 균등 하한/2"* 를 기준으로 잡았다(측정 전에 정한 기준이다).
	//     그런데 자리 보존 팔에서 **학습 CE 가 0.0000** 인 축이 여럿 나왔다 = **로짓이 포화**했다는 뜻이고,
	//     그러면 소수의 오답이 CE 를 통째로 지배한다(오답 하나가 `-log(1e-12) = 27.6` 을 낸다).
	//     실측: `색` 축이 **정확도 96%** 인데 CE `1.105` 로 기준을 못 넘었다 — 잘 읽히는데 "실패" 로 찍힌다.
	//   ⇒ ★ **바뀐 것은 목표가 아니라 자다.** 이 프로브가 묻는 것은 *"그 낱말이 표현에서 읽히나"* =
	//     **판독 가능성**이고, CE 는 거기에 **확신의 정도**까지 섞는다(그리고 그것은 정규화 설정의 함수다 —
	//     이 실험의 관심사가 아니다). 정확도는 그 섞임이 없다.
	//   ⚠️ 문턱은 여전히 **원리에서** 나온다: 정규화 이득 `> 0.5` = *"우연과 완벽 사이의 절반을 메웠다."*
	//     ★ CE 도 계속 찍는다 — 포화를 보는 창이기 때문이다(학습 CE 가 0 이면 그 숫자를 믿지 마라).
	void _JudgeProbe()
	{
		const int n = kPAxes;
		LogA("\n[ml] 🧿 **접지 프로브 표** — 프레임 → 8×8 패치 임베딩 → 판독 → softmax\n"
			"[ml]   (dim %u · 은닉 %u · 축마다 %d스텝 · 학습 %u / 시험 %u)\n"
			"[ml]   이득 = (정확도−우연)/(100−우연) · `학습→시험` 을 같이 본다"
			" (학습이 낮으면 **수렴 안 됨**이고 판독 실패가 아니다)\n"
			"[ml]   %-6s %5s │ %-20s │ %-20s │ %-20s │ %-20s\n",
			kPD, kPHid, kPSteps, kPTrain, kPTest, "축", "우연",
			"자루(평균풀링)", "자리보존(선형)", "**비선형**", "**어텐션+풀링**");
		int gate = -1, shapeAx = -1;
		for (int i = 0; i < n; ++i)
		{
			const uint32 c = _AxisClasses(i);
			if (_PAxisKind(i) == MLAxis::Color) gate = i;
			if (_PAxisKind(i) == MLAxis::Shape) shapeAx = i;
			const float tb = _Gain(_pAccTr[0][i], c), gb = _Gain(_pAccTe[0][i], c);
			const float tp = _Gain(_pAccTr[1][i], c), gp = _Gain(_pAccTe[1][i], c);
			const float tn = _Gain(_pAccTr[2][i], c), gn = _Gain(_pAccTe[2][i], c);
			const float ta = _Gain(_pAccTr[3][i], c), ga = _Gain(_pAccTe[3][i], c);
			LogA("[ml]   %-6s %4.1f%% │ %+5.2f→%+5.2f %-9s │ %+5.2f→%+5.2f %-9s │ %+5.2f→%+5.2f %-9s"
				" │ %+5.2f→%+5.2f %-9s\n",
				_PAxisName(i), 100.0 / (double)c,
				(double)tb, (double)gb, _Verdict1(tb, gb),
				(double)tp, (double)gp, _Verdict1(tp, gp),
				(double)tn, (double)gn, _Verdict1(tn, gn),
				(double)ta, (double)ga, _Verdict1(ta, ga));
		}
		// ★ **비선형의 판정은 `모양` 축이다.**
		//   ⚠️ 그 축이 선형 1층으로는 **학습 집합조차 못 갈렸다**(P2-b1 실측: 학습 이득 +0.58) —
		//     패치 안에서 *"각이냐 곡이냐"* 는 **곱셈 관계**이고 선형은 그것을 만들 수 없다.
		//   ⇒ 비선형이 그 축을 **학습에서라도** 갈라야 한다. 못 하면 원인은 다른 데 있다.
		if (shapeAx >= 0)
		{
			const uint32 sc2 = _AxisClasses(shapeAx);
			const float lt = _Gain(_pAccTr[1][shapeAx], sc2), lv = _Gain(_pAccTe[1][shapeAx], sc2);
			const float nt = _Gain(_pAccTr[2][shapeAx], sc2), nv = _Gain(_pAccTe[2][shapeAx], sc2);
			const bool okShape = (nt > lt + 0.15f);
			LogA("[ml]   ⛓️ **비선형 판정 = `모양` 축**: 선형 %+.2f→%+.2f vs 비선형 %+.2f→%+.2f"
				" (기준: 학습 이득 +0.15 이상) → %s\n"
				"[ml]      ★ `모양` 을 고른 이유: 선형 1층으로는 **학습 집합조차 못 갈렸다** —\n"
				"[ml]        *\"각이냐 곡이냐\"* 는 **곱셈 관계**이고 선형은 그것을 만들 수 없다.\n"
				"[ml]      ⚠️ 못 오르면 원인이 비선형 부재가 아니다(패치 정렬·해상도 쪽을 봐야 한다).\n",
				(double)lt, (double)lv, (double)nt, (double)nv, okShape ? "통과" : "★실패★");

			// ★ **어텐션의 판정 = `모양` 축의 시험 이득이다**(학습이 아니다).
			//   ⚠️⚠️ **기준을 미리 못박는다** — 결과를 보고 고르면 그것은 판정이 아니다(이 저장소가
			//     함정 19·21 에서 두 번 밟은 자리다). 기준: **세 팔의 시험 최댓값 + 0.15**.
			//   ★ 근거: D1′ 이 *"비선형은 `모양` 을 학습에서 완전히 갈랐지만(+1.00) 시험에서 졌다
			//     (+0.36 < 선형 +0.44)"* 를 실측했고, 그 원인을 **평행이동 불변성 부재**로 지목했다.
			//     ⇒ 어텐션은 `Wq/Wk/Wv` 를 **모든 자리에 공유**하므로 그 지목이 맞다면 **시험이 올라야** 한다.
			//   ⚠️⚠️ **반증 조건도 미리 적는다**(그래야 실패가 정보가 된다):
			//     · 학습은 높은데 시험이 안 오른다 ⇒ **가중치 공유만으로는 부족**하다. 그러면 다음은
			//       "지역성"(합성곱) 또는 표본 수이고, 어텐션 탓이 아니다.
			//     · **학습 자체가 낮다** ⇒ 수렴 실패다(D1 이 밟은 자리) — 판독 능력의 문제가 아니라
			//       lr/초기값 문제이고, 그때는 **판정을 유보**하고 그것부터 잡는다.
			const float at = _Gain(_pAccTr[3][shapeAx], sc2), av = _Gain(_pAccTe[3][shapeAx], sc2);
			const float bt = _Gain(_pAccTr[0][shapeAx], sc2), bv = _Gain(_pAccTe[0][shapeAx], sc2);
			float bestV = bv; if (lv > bestV) bestV = lv; if (nv > bestV) bestV = nv;
			const bool attnConverged = (at > 0.5f);
			const bool attnOk = attnConverged && (av > bestV + 0.15f);
			LogA("[ml]   🔭 **어텐션 판정 = `모양` 축의 시험 이득**: 자루 %+.2f · 선형 %+.2f · 비선형 %+.2f"
				" vs **어텐션 %+.2f** (학습 %+.2f)\n"
				"[ml]      기준: 세 팔의 시험 최댓값(%+.2f) + 0.15 이상 → %s\n"
				"[ml]      ★ 왜 시험인가: D1′ 이 비선형은 **학습에서 완전히 갈랐지만**(+1.00) 시험에서\n"
				"[ml]        졌다는 것을 쟀다 ⇒ 남은 문제는 표현력이 아니라 **일반화**다.\n"
				"[ml]      ★ 어텐션만 `Wq/Wk/Wv` 를 **모든 자리에 공유**한다 —\n"
				"[ml]        한 자리에서 배운 \"동그라미\" 가 옆자리로 **옮겨간다**는 것이 이 가설이다.\n",
				(double)bv, (double)lv, (double)nv, (double)av, (double)at,
				(double)bestV, attnOk ? "통과" : (attnConverged ? "★실패★" : "★판정 유보(수렴 안 됨)★"));
			(void)bt;
		}
		if (gate < 0) { LogA("[ml] P2-b1 판정: ★실패★ — 게이트 축(색)을 못 찾았다\n"); return; }

		// ㉠ 게이트 = `색` 축이 **어느 판독으로든** 읽힌다(배선 판정).
		const uint32 gc = _AxisClasses(gate);
		const bool gateOk = (_Gain(_pAccTe[0][gate], gc) > 0.5f) || (_Gain(_pAccTe[1][gate], gc) > 0.5f);
		// ㉡ P2-b1 의 **예측**: 자리 보존이 `자리` 축을 살린다(자루는 원리적으로 못 한다).
		int posAx = -1;
		for (int i = 0; i < n; ++i) if (_PAxisKind(i) == MLAxis::Pos) posAx = i;
		const uint32 pc = (posAx >= 0) ? _AxisClasses(posAx) : 1u;
		const float gposB = (posAx >= 0) ? _Gain(_pAccTe[0][posAx], pc) : 0.0f;
		const float gposP = (posAx >= 0) ? _Gain(_pAccTe[1][posAx], pc) : 0.0f;
		const bool predOk = (gposB < 0.2f) && (gposP > 0.5f);

		LogA("[ml] P2-b1 판정: %s\n"
			"[ml]   ㉠ 배선(게이트 `색`): %s — 어느 판독으로든 읽히면 픽셀 경로가 정직하다\n"
			"[ml]   ㉡ **예측 확인**: 자루가 `자리` 를 못 읽고(이득 %+.2f) 자리 보존은 읽는다(이득 %+.2f) → %s\n"
			"[ml]      ★ 이것이 P2-a 에서 **구조로 예측한 것**이다: 평균풀링은 `Σ_p pos[p]` 가 상수이고\n"
			"[ml]        `Σ_p Σ_s slot[(s,byte)]` 는 패치 사이 순서가 없는 히스토그램이라 자리를 버린다.\n",
			(gateOk && predOk) ? "통과" : "★실패★",
			gateOk ? "통과" : "★실패★", (double)gposB, (double)gposP,
			predOk ? "확인됐다" : "★안 맞았다★");
		// ⚠️⚠️ **여기서 앞선 주장을 정정한다.** 800스텝 표에서는 *"자리 보존이 자리를 얻고 평행이동
		//   불변성을 잃는다"* 는 트레이드오프가 보였는데, **1600스텝에서는 남지 않았다** —
		//   자루의 유일한 우위가 `색`(1.00 vs 0.90)이고 그것은 과적합 차이 수준이다.
		//   ★ 짧은 학습에서 본 차이를 구조적 트레이드오프로 읽으면 안 된다는 실측 교훈이다.
		LogA("[ml]   ⚠️ **트레이드오프는 이 측정에서 확인되지 않았다** — 자리 보존이 거의 전면적으로 낫다\n"
			"[ml]      (자루의 유일한 우위는 `색` 1.00 vs 0.90 이고 과적합 차이 수준이다).\n"
			"[ml]      ★ 800스텝에서는 트레이드오프처럼 보였는데 1600스텝에서 사라졌다 —\n"
			"[ml]        **짧은 학습의 차이를 구조로 읽으면 안 된다**(그럴 뻔했다).\n"
			"[ml]   ⇒ 그래서 계층(L2)의 근거는 다른 데서 온다:\n"
			"[ml]      ① **`모양` 을 둘 다 학습조차 못 한다** — 8×8 패치 + 자리별 표 + **선형 1층**으로는\n"
			"[ml]         동그라미와 네모가 안 갈린다(비선형·계층이 필요하다는 뚜렷한 표적이다).\n"
			"[ml]      ② **자리 보존은 확장이 안 된다** — 판독 폭이 `패치수 × dim` 이라 해상도가 커지면\n"
			"[ml]         가중치가 폭발하고, 자리마다 독립이라 배운 것이 옆자리로 옮겨가지 않는다.\n"
			"[ml]         ⇒ 자리를 **값으로** 갖고 가중치는 **공유**하는 것이 어텐션이 하는 일이다.\n");

		// ★ **어텐션 팔이 통제된 비교인 이유를 표 옆에 남긴다** — 나중에 이 숫자를 읽는 사람이
		//   "어텐션이 좋은 건 파라미터가 많아서겠지" 로 오독하는 것을 막는다.
		LogA("[ml]   🔭 **어텐션 팔은 자루 팔과 머리가 글자 그대로 같다** — `풀링 → W(D×C)`.\n"
			"[ml]      ⇒ 팬인·초기값 규칙·lr 이 전부 같고 **중간의 어텐션 블록 하나만** 다르다.\n"
			"[ml]      ★ 그리고 `Wq/Wk` 가 작게 시작하면 `S≈0 → A≈균등 → O≈평균(V)` 이라\n"
			"[ml]        **어텐션 팔은 자루 팔에서 출발한다** — 이득이 있다면 전부 *관계를 배운 것*이다.\n"
			"[ml]      ⚠️ 파라미터는 자루보다 `3·D·D = %u` 개 많다(자리보존의 `%u` 에 비하면 미미하다).\n",
			3u * kPD * kPD, (kPW / kPK) * (kPH / kPK) * kPD * kPCMax);
		// ══════════════════════════════════════════════════════════════════════════
		// 🔢 **`개수` 세 가설 판정** — 셋이 서로 다른 것을 예측하므로 한 실행으로 갈린다.
		//   ⚠️⚠️ **기준을 미리 못박는다**(함정 19·21) — 결과를 보고 고르면 판정이 아니다.
		//     ㉠ **채널 충돌**: `개수깔끔` 의 이득이 `개수` 보다 **+0.15 이상** 높다
		//        (잉크 면적을 공유하는 잡음 축 `크기`·`속` 을 없애면 오른다).
		//     ㉡ **절차 부재**: 참값별 정확도가 **작은 수 ≫ 큰 수** — `1·2·3` 평균이 `4·5·여럿` 평균보다
		//        **20%p 이상** 높다(subitizing 서명).
		//     ㉢ **순서 부재**: 오답 중 `±1` 인 비율이 **낮다**. ★ 우연 기준을 계산한다 —
		//        6분류에서 무작위 오답이 `±1` 일 확률은 `Σ_c (인접 수)/(C−1) / C` = `10/6/5` ≈ **33%**.
		//        ⇒ 그보다 **낮거나 비슷하면** 순서를 못 배운 것이고, **크게 높으면** 크기(면적)로 재는 중이다.
		{
			const uint32 cc = _AxisClasses(0);
			LogA("[ml]\n[ml]   🔢 **`개수` 세 가설 판정** — 왜 `개수` 만 유독 안 되나\n"
				"[ml]      우연 %.1f%% · 오답이 무작위일 때 `±1` 비율의 기대값 **33%%**(6분류)\n",
				100.0 / (double)cc);
			for (int arm = 0; arm < kPArms; ++arm)
			{
				const float gRaw = _Gain(_pAccTe[arm][0], cc);
				const float gCln = _Gain(_pAccTe[arm][kPAxCountClean], cc);
				// ㉡ 작은 수 vs 큰 수
				float lo = 0.0f, hi = 0.0f;
				for (int c = 0; c < 3; ++c) lo += _pPerCls[arm][1][c];
				for (int c = 3; c < 6; ++c) hi += _pPerCls[arm][1][c];
				lo /= 3.0f; hi /= 3.0f;
				const bool okA = (gCln > gRaw + 0.15f);
				const bool okB = (lo > hi + 20.0f);
				// ⚠️⚠️ **오답이 없으면 ㉢ 은 판정할 수 없다** — 분모가 0 이다(거짓 양성을 막는다).
				//   ★ 그리고 그것이 정보이기도 하다: 오답 0개는 *"이 설정에서는 완전히 읽힌다"* 다.
				const int wr = _pWrong[arm][1];
				const bool judgeC = (wr >= 3);
				const bool okC = judgeC && (_pAdjFrac[arm][1] < 0.40f);
				// ⚠️ `개수` 가 이미 천장(+0.85 이상)이면 ㉠ 도 **+0.15 를 낼 자리가 없다**(천장 효과).
				const bool ceil0 = (gRaw > 0.85f);
				LogA("[ml]      [%-8s] 개수 %+.2f → 개수깔끔 %+.2f (%s㉠ 채널충돌%s)\n"
					"[ml]                 깔끔판: 작은수(1·2·3) %.0f%% vs 큰수(4·5·여럿) %.0f%%"
					" (%s㉡ 절차부재) · 오답 %d개%s (%s㉢ 순서부재)\n",
					_ArmName(arm), (double)gRaw, (double)gCln,
					okA ? "✅" : (ceil0 ? "➖" : "❌"), ceil0 ? " · 천장" : "",
					(double)lo, (double)hi, okB ? "✅" : "❌",
					wr, judgeC ? "" : " → **판정불가**",
					judgeC ? (okC ? "✅" : "❌") : "➖");
				if (judgeC)
					LogA("[ml]                 (오답 중 ±1 인 비율 %.0f%% · 무작위 기대 33%%)\n",
						(double)(100.0f * _pAdjFrac[arm][1]));
			}
			LogA("[ml]      ★ 읽는 법: ㉠ 만 켜지면 **커리큘럼 문제**(면적 채널을 공유했다)\n"
				"[ml]        ㉡ 이 켜지면 **절차가 필요하다**(한 번의 전진으로는 못 센다 → 자기 추론)\n"
				"[ml]        ㉢ 이 켜지면 **숫자를 순서 없는 이름으로 배웠다** — one-hot 이 계승을 지웠다\n"
				"[ml]        ⇒ ㉢ 은 목적함수의 문제라 **판독기를 바꿔도 안 고쳐진다**(숫자를 바이트로\n"
				"[ml]          배우게 하는 것이 원래 결정이었다: *\"숫자는 한동안 아라비아숫자쓰자\"*).\n");
		}

		// 🔎 부수 관찰(판정 아님) — `자리` 축: 풀링이 자리를 버린다는 P2-a 예측과 어텐션의 관계.
		if (posAx >= 0)
		{
			const float paB = _Gain(_pAccTe[0][posAx], pc);
			const float paA = _Gain(_pAccTe[3][posAx], pc);
			LogA("[ml]   🔎 부수 관찰 — `자리` 축: 자루 %+.2f vs 어텐션 %+.2f\n"
				"[ml]      ★ 둘 다 **같은 평균풀링**으로 끝나는데 어텐션이 읽으면, 그것은 P2-a 예측을\n"
				"[ml]        깨는 것이 **아니다** — 어텐션이 자리를 **값으로 실어** 풀링을 통과시킨 것이다\n"
				"[ml]        (`A` 가 내용에 따라 달라지므로 `Σ_p` 가 더 이상 자리에 대해 상수가 아니다).\n"
				"[ml]      ⚠️ 판정이 아니라 관찰이다 — 기준을 미리 못박지 않았으므로 결론으로 쓰지 않는다.\n",
				(double)paB, (double)paA);
		}
	}

	// ★ **판정이 세 갈래여야 한다 — "못 읽는다" 를 한 낱말로 두면 원인이 뭉개진다.**
	//   · **학습도못함** — 학습 집합조차 못 가른다. ⚠️⚠️ 원인이 **둘**이고 이 프로브는 그것을 **못 가른다**:
	//       ㉠ 스텝/lr 이 모자라다   ㉡ 표현이 그 축을 애초에 담지 못한다(용량·불변성)
	//     ★ 다만 같은 설정에서 **다른 축이 +1.00 으로 배워졌다면** ㉠ 은 상당히 배제된다 —
	//       실측: 자루 팔은 `색` 을 학습 +1.00 으로 배우면서 `크기` 는 **+0.04** 였다 ⇒ ㉡ 쪽이다.
	//   · **일반화실패** — 학습은 맞히는데 시험이 안 된다. 표현이 그 낱말을 **불변하게** 담지 못한다
	//   · **읽힌다** — 둘 다 맞힌다
	//   ⚠️ 이 구별이 없으면 "표현이 나쁘다" 와 "학습이 덜 됐다" 를 같은 칸에 적게 되고, 그러면
	//     다음 단계를 엉뚱한 쪽으로 고치게 된다(실측으로 그럴 뻔했다 — 위 kPSteps 주석).
	static const char* _Verdict1(float gainTr, float gainTe)
	{
		if (gainTr < 0.7f)  return "학습도못함";
		if (gainTe < 0.5f)  return "일반화실패";
		return "읽힌다";
	}

	// ── 🔤 임베딩 검증 — **gather 방향이 맞나** ────────────────────────────────────────
	//   ★ **이것이 atomic 을 피한 설계의 판정이다.** scatter + atomic 이면 누산 순서가 비결정적이라
	//     CPU 레퍼런스와 **정확히** 비교할 수 없다. gather 는 결정적이므로 **오차 0 을 요구할 수 있다** —
	//     그리고 오차 0 을 요구할 수 있다는 것이 곧 판정 능력이다.
	//   ⚠️ **같은 토큰을 일부러 여러 번** 넣는다(`tok = {3,1,3,0,3,1,2,3}`) — 그것이 scatter 라면 race 가
	//     났을 자리이고, gather 가 맞는지는 **중복이 있을 때만** 드러난다.
	int      _eStage = 0;
	MLKernel _kEmb, _kEmbB;
	MLTensor _tTok, _tTable, _tEOut, _tDEOut, _tDTable;
	static constexpr uint32 kSeq = 8, kDim = 5, kVocab = 4;

	void _TickEmbed()
	{
		if (_eStage >= 2) return;

		if (_eStage == 0)
		{
			_eStage = 1;
			if (!_SetupEmbed()) { _eStage = 2; return; }

			MLEmbedParams f;
			f.tokOff = _tTok.offset; f.aOff = _tTable.offset; f.bOff = _tEOut.offset;
			f.seqLen = kSeq; f.dim = kDim; f.vocab = kVocab;
			if (!_kEmb.Dispatch(kDim, kSeq, 1u, &f, (uint32)sizeof(f)))
			{
				LogA("[ml] 임베딩: forward 디스패치 실패\n"); _eStage = 2; return;
			}

			MLEmbedParams b;
			b.tokOff = _tTok.offset; b.aOff = _tDEOut.offset; b.bOff = _tDTable.offset;
			b.seqLen = kSeq; b.dim = kDim; b.vocab = kVocab;
			// ⚠️ 스레드 배치가 forward 와 다르다: y 축이 **어휘**다(forward 는 시퀀스).
			if (!_kEmbB.Dispatch(kDim, kVocab, 1u, &b, (uint32)sizeof(b)))
			{
				LogA("[ml] 임베딩: backward 디스패치 실패\n"); _eStage = 2; return;
			}
			LogA("[ml] 임베딩 디스패치 — seq %u · dim %u · vocab %u (토큰에 중복 있음)\n",
				kSeq, kDim, kVocab);
			return;   // ⚠️ 회수는 다음 프레임(G′)
		}

		_eStage = 2;
		Bytes bOut, bDT;
		if (!_arena.Read(_tEOut, bOut) || !_arena.Read(_tDTable, bDT))
		{
			LogA("[ml] 임베딩 판정: ★실패★ — 회수가 안 됐다\n");
			return;
		}

		Array<float> tok, table, dOut, wantOut, wantDT;
		_FillEmbedInputs(tok, table, dOut);
		wantOut.Reset(kSeq * kDim);
		MLEmbedCpu(tok.Data(), table.Data(), wantOut.Data(), kSeq, kDim, kVocab);
		wantDT.Reset(kVocab * kDim);
		MLEmbedBwdCpu(tok.Data(), dOut.Data(), wantDT.Data(), kSeq, kDim, kVocab);

		const float eF = MLMaxRelErr((const float*)bOut.GetData(), wantOut.Data(), kSeq * kDim);
		const float eB = MLMaxRelErr((const float*)bDT.GetData(), wantDT.Data(), kVocab * kDim);
		// ★ **오차 0 을 요구한다** — gather 라 결정적이고 조회/합이 정확하므로 여유를 줄 이유가 없다.
		//   ⚠️ 여기에 여유를 주면 "중복 토큰이 한 번만 더해진" 종류의 버그가 통과한다.
		const bool pass = (eF == 0.0f) && (eB == 0.0f);
		LogA("[ml] 임베딩 판정: %s — forward %.3e · backward %.3e (CPU 레퍼런스 대비, 오차 0 을 요구)\n",
			pass ? "통과" : "★실패★", (double)eF, (double)eB);
		if (!pass)
			LogA("[ml]   ⚠️ 볼 곳: ① backward 의 y 축이 어휘인가(시퀀스가 아니다) ② 중복 토큰이 다 더해졌나"
				" ③ 범위 밖 토큰 규약이 fwd/bwd 에서 같은가\n");
	}

	// 🎲 **중복이 있는** 토큰과 결정적 입력. ★ 중복이 없으면 gather 검증이 아무것도 증명하지 못한다.
	void _FillEmbedInputs(Array<float>& tok, Array<float>& table, Array<float>& dOut)
	{
		tok.Reset(kSeq);
		const float kToks[kSeq] = { 3, 1, 3, 0, 3, 1, 2, 3 };   // 3 이 네 번, 1 이 두 번
		for (uint32 i = 0; i < kSeq; ++i) tok.Data()[i] = kToks[i];

		table.Reset(kVocab * kDim);
		for (uint32 i = 0; i < kVocab * kDim; ++i)
			table.Data()[i] = ((float)(i % 6) - 2.5f) * 0.5f;

		dOut.Reset(kSeq * kDim);
		for (uint32 i = 0; i < kSeq * kDim; ++i)
			dOut.Data()[i] = ((float)(i % 9) - 4.0f) * 0.25f;
	}

	bool _SetupEmbed()
	{
		_tTok    = _arena.Alloc(1, kSeq);
		_tTable  = _arena.Alloc(kVocab, kDim);
		_tEOut   = _arena.Alloc(kSeq, kDim);
		_tDEOut  = _arena.Alloc(kSeq, kDim);
		_tDTable = _arena.Alloc(kVocab, kDim);
		if (!_tDTable.IsValid()) { LogA("[ml] 임베딩: 텐서 할당 실패(아레나 부족)\n"); return false; }

		Array<float> tok, table, dOut;
		_FillEmbedInputs(tok, table, dOut);
		if (!_arena.Write(_tTok, tok) || !_arena.Write(_tTable, table)
			|| !_arena.Write(_tDEOut, dOut))
		{
			LogA("[ml] 임베딩: 입력 업로드 실패\n");
			return false;
		}
		if (!_LoadKernel(_kEmb,  "shaders/embed.cs.spv"))     return false;
		if (!_LoadKernel(_kEmbB, "shaders/embed_bwd.cs.spv")) return false;
		return true;
	}

	// ── 🔠 **바이트 LM** — P1 의 마지막 조각 ────────────────────────────────────────────
	//   `바이트 → embed(V×D) → linear(D×V) → softmax → 교차엔트로피(다음 바이트)`
	//   ★ **이 모델은 정확히 바이그램이다** — 조회와 선형 사이에 비선형이 없으므로 "현재 바이트 하나로
	//     다음을 고르는 표" 와 같다. ⇒ 도달 하한이 **경험적 조건부 엔트로피 `H(다음|현재)`** 이고,
	//     그것을 CPU 가 계산해 **절대 목표**로 쓴다. *"손실이 내려갔다"* 보다 훨씬 센 판정이다.
	//   ★ 코퍼스는 **`샤인머스캣은 맛있다`** — 이 프로젝트가 시작한 그 문장이고, UTF-8 바이트에 반복이 있다.
	//     ⚠️ 한글 음절은 3바이트라 **선두 바이트가 여러 음절에서 겹친다**(EA~ED) → 같은 문맥에 다른 다음
	//       바이트가 오므로 `H > 0` 이다. 그것이 이 코퍼스가 시시하지 않은 이유다.
	//   ⚠️⚠️ 회수는 **다음 프레임**(G′) — 그래서 여기도 "읽고 → 디스패치" 순서다.
	int      _lmStage = 0;
	int      _lmStep = 0;
	float    _lmLoss0 = 0.0f, _lmTarget = 0.0f;
	MLKernel _kSoftmax;
	MLArena  _lm;                       // ★ LM 전용 아레나(위 검증용과 섞지 않는다 — 오프셋 사고를 막는다)
	MLKernel _lmEmb, _lmEmbB, _lmGemm, _lmSub, _lmSoft, _lmAdam;
	MLTensor _lTok, _lTgt, _lOne, _lTable, _lW, _lEmb, _lLogit, _lProb;
	MLTensor _lDLogit, _lDW, _lDEmb, _lDTable, _lMW, _lVW, _lMT, _lVT;
	static constexpr uint32 kVoc = 256, kDimL = 8;
	static constexpr int    kLmSteps = 400;
	static constexpr float  kLmLr = 2.0e-1f;
	uint32 _seq = 0;                    // 코퍼스 길이 − 1(= 예측 쌍의 수)

	// 📜 코퍼스 — ⚠️ **`.cw` 는 BOM 없는 UTF-8** 이라 이 리터럴이 곧 그 바이트다.
	static const char* LmCorpus() { return "샤인머스캣은 맛있다"; }

	void _TickLM()
	{
		if (_lmStage >= 3) return;

		if (_lmStage == 0)
		{
			_lmStage = 1;
			if (!_SetupLM()) { _lmStage = 3; return; }
			_lmStep = 0;
			LogA("[ml] 바이트 LM 시작 — 코퍼스 %u바이트 · seq %u · dim %u · vocab %u\n"
				"[ml]   목표(경험적 H(다음|현재)) = %.6f nat — 바이그램이 도달할 수 있는 하한\n",
				_seq + 1u, _seq, kDimL, kVoc, (double)_lmTarget);
			return;
		}

		// ① 지난 스텝의 `probs` 를 읽어 손실을 적는다(G′ — 이번 프레임 디스패치는 아직 제출 전이다).
		if (_lmStep > 0)
		{
			Bytes bp;
			if (_lm.Read(_lProb, bp) && bp.GetSize() == (uint64)(_seq * kVoc) * sizeof(float))
			{
				Array<float> tgt; _LmTargets(tgt);
				const float loss = MLCrossEntropyCpu((const float*)bp.GetData(), tgt.Data(), _seq, kVoc);
				if (_lmStep == 1) _lmLoss0 = loss;
				if (_lmStep == 1 || (_lmStep % 50) == 0 || _lmStep == kLmSteps)
					LogA("[ml] LM step %4d  loss %.6f nat\n", _lmStep - 1, (double)loss);
				if (_lmStep >= kLmSteps) { _lmStage = 3; _JudgeLM(loss); return; }
			}
		}

		if (!_DispatchLmStep()) { _lmStage = 3; return; }
		_lmStep++;
	}

	// 한 스텝 = 디스패치 여덟. ★ 아레나 하나를 한 번 바인딩했으므로 오프셋만 바꿔 계속 부른다.
	bool _DispatchLmStep()
	{
		// forward ① emb = table[tok]
		MLEmbedParams e;
		e.tokOff = _lTok.offset; e.aOff = _lTable.offset; e.bOff = _lEmb.offset;
		e.seqLen = _seq; e.dim = kDimL; e.vocab = kVoc;
		if (!_lmEmb.Dispatch(kDimL, _seq, 1u, &e, (uint32)sizeof(e))) return _Fail("lm embed");

		// ② logits = emb · W   (T×V = (T×D)·(D×V))
		MLGemmParams g;
		g.aOff = _lEmb.offset; g.bOff = _lW.offset; g.cOff = _lLogit.offset;
		g.M = _seq; g.N = kVoc; g.K = kDimL;
		if (!_lmGemm.Dispatch(kVoc, _seq, 1u, &g, (uint32)sizeof(g))) return _Fail("lm logits");

		// ③ probs = softmax(logits)
		MLSoftmaxParams sm;
		sm.inOff = _lLogit.offset; sm.outOff = _lProb.offset; sm.rows = _seq; sm.cols = kVoc;
		if (!_lmSoft.Dispatch(_seq, 1u, 1u, &sm, (uint32)sizeof(sm))) return _Fail("lm softmax");

		// backward ④ dLogits = probs − onehot  ★ 교차엔트로피+softmax 의 기울기가 **정확히 이 뺄셈**이다
		//   ⇒ 그래서 `sub` 커널을 그대로 쓴다(전용 커널을 만들 이유가 없다).
		MLSubParams s;
		s.aOff = _lProb.offset; s.bOff = _lOne.offset; s.outOff = _lDLogit.offset;
		s.count = _seq * kVoc;
		if (!_lmSub.Dispatch(s.count, 1u, 1u, &s, (uint32)sizeof(s))) return _Fail("lm dlogits");

		// ⑤ dW = embᵀ · dLogits  (D×V = (D×T)·(T×V))
		MLGemmParams gw;
		gw.aOff = _lEmb.offset; gw.bOff = _lDLogit.offset; gw.cOff = _lDW.offset;
		gw.M = kDimL; gw.N = kVoc; gw.K = _seq; gw.transA = 1;
		if (!_lmGemm.Dispatch(kVoc, kDimL, 1u, &gw, (uint32)sizeof(gw))) return _Fail("lm dW");

		// ⑥ dEmb = dLogits · Wᵀ  (T×D = (T×V)·(V×D)) — ⚠️ W 는 D×V 저장이므로 `transB = 1`
		MLGemmParams ge;
		ge.aOff = _lDLogit.offset; ge.bOff = _lW.offset; ge.cOff = _lDEmb.offset;
		ge.M = _seq; ge.N = kDimL; ge.K = kVoc; ge.transB = 1;
		if (!_lmGemm.Dispatch(kDimL, _seq, 1u, &ge, (uint32)sizeof(ge))) return _Fail("lm dEmb");

		// ⑦ dTable — **gather**(atomic 없이 결정적으로)
		MLEmbedParams eb;
		eb.tokOff = _lTok.offset; eb.aOff = _lDEmb.offset; eb.bOff = _lDTable.offset;
		eb.seqLen = _seq; eb.dim = kDimL; eb.vocab = kVoc;
		if (!_lmEmbB.Dispatch(kDimL, kVoc, 1u, &eb, (uint32)sizeof(eb))) return _Fail("lm dTable");

		// ⑧ AdamW × 2(W 와 표) — ⚠️ 모멘트 텐서가 **파라미터마다 따로**여야 한다(섞이면 조용히 틀린다).
		float bc1 = 1.0f, bc2 = 1.0f;
		_BiasCorr(_lmStep + 1, bc1, bc2);
		MLAdamWParams aw;
		aw.pOff = _lW.offset; aw.gOff = _lDW.offset; aw.mOff = _lMW.offset; aw.vOff = _lVW.offset;
		aw.count = _lW.Count();
		aw.lr = kLmLr; aw.beta1 = kB1; aw.beta2 = kB2; aw.eps = kAdamEps; aw.wd = kWd;
		aw.bc1 = bc1; aw.bc2 = bc2;
		if (!_lmAdam.Dispatch(aw.count, 1u, 1u, &aw, (uint32)sizeof(aw))) return _Fail("lm adamw W");

		MLAdamWParams at = aw;
		at.pOff = _lTable.offset; at.gOff = _lDTable.offset;
		at.mOff = _lMT.offset; at.vOff = _lVT.offset;
		at.count = _lTable.Count();
		if (!_lmAdam.Dispatch(at.count, 1u, 1u, &at, (uint32)sizeof(at))) return _Fail("lm adamw table");
		return true;
	}

	void _JudgeLM(float lossN)
	{
		// ★ **절대 목표 대비로 판정한다** — 바이그램의 하한(`H(다음|현재)`)에 얼마나 다가갔나.
		//   ⚠️ 하한보다 **아래로** 내려가면 그것도 이상하다(외울 것이 없는데 외웠다는 뜻 → 목표 계산이 틀렸다).
		//     그래서 위아래를 다 본다.
		const float slack = lossN - _lmTarget;
		const bool pass = (lossN < _lmLoss0 * 0.35f) && (slack < 0.35f) && (slack > -0.05f);
		LogA("[ml] P1 바이트 LM 판정: %s\n"
			"[ml]   손실 %.6f -> %.6f nat · 목표 %.6f · 여유 %+.6f\n",
			pass ? "통과" : "★실패★", (double)_lmLoss0, (double)lossN,
			(double)_lmTarget, (double)slack);
		if (!pass)
			LogA("[ml]   ⚠️ 볼 곳: ① dEmb 의 transB(W 는 D×V 저장) ② onehot 이 정답 바이트에 서 있나"
				" ③ 두 AdamW 의 모멘트가 섞였나 ④ lr 이 너무 크거나 작은가\n");
	}

	// 코퍼스 바이트 → 입력/정답. ★ 입력은 `[0..n−2]`, 정답은 `[1..n−1]`(다음 바이트 예측).
	void _LmTokens(Array<float>& cur) const
	{
		const char* c = LmCorpus();
		uint32 n = 0; while (c[n] != 0) n++;
		cur.Reset(n - 1u);
		for (uint32 i = 0; i + 1u < n; ++i) cur.Data()[i] = (float)(uint8)c[i];
	}
	void _LmTargets(Array<float>& tgt) const
	{
		const char* c = LmCorpus();
		uint32 n = 0; while (c[n] != 0) n++;
		tgt.Reset(n - 1u);
		for (uint32 i = 1; i < n; ++i) tgt.Data()[i - 1u] = (float)(uint8)c[i];
	}

	bool _SetupLM()
	{
		Array<float> cur, tgt;
		_LmTokens(cur);
		_LmTargets(tgt);
		_seq = (uint32)cur.Count();
		if (_seq == 0u) { LogA("[ml] LM: 코퍼스가 비었다\n"); return false; }
		_lmTarget = MLBigramEntropyCpu(cur.Data(), tgt.Data(), _seq, kVoc);

		// ★ LM 전용 아레나 — 위 검증용과 섞지 않는다(오프셋 사고를 구조로 막는다).
		const uint32 need = _seq * 2u                    // tok, (여유)
			+ _seq * kVoc * 4u                           // onehot, logits, probs, dLogits
			+ kVoc * kDimL * 4u                          // table, dTable, mT, vT
			+ kDimL * kVoc * 4u                          // W, dW, mW, vW
			+ _seq * kDimL * 2u                          // emb, dEmb
			+ 64u;
		if (!_lm.Create(rhi, need)) { LogA("[ml] LM: 아레나 생성 실패\n"); return false; }

		_lTok    = _lm.Alloc(1, _seq);
		_lTgt    = _lm.Alloc(1, _seq);
		_lOne    = _lm.Alloc(_seq, kVoc);
		_lTable  = _lm.Alloc(kVoc, kDimL);
		_lW      = _lm.Alloc(kDimL, kVoc);
		_lEmb    = _lm.Alloc(_seq, kDimL);
		_lLogit  = _lm.Alloc(_seq, kVoc);
		_lProb   = _lm.Alloc(_seq, kVoc);
		_lDLogit = _lm.Alloc(_seq, kVoc);
		_lDW     = _lm.Alloc(kDimL, kVoc);
		_lDEmb   = _lm.Alloc(_seq, kDimL);
		_lDTable = _lm.Alloc(kVoc, kDimL);
		_lMW     = _lm.Alloc(kDimL, kVoc);
		_lVW     = _lm.Alloc(kDimL, kVoc);
		_lMT     = _lm.Alloc(kVoc, kDimL);
		_lVT     = _lm.Alloc(kVoc, kDimL);
		if (!_lVT.IsValid()) { LogA("[ml] LM: 텐서 할당 실패(아레나 부족)\n"); return false; }

		// 🎯 onehot — 정답 바이트 자리에 1. ★ 정답이 고정이므로 **한 번만** 올린다(스텝마다 만들지 않는다).
		Array<float> one; one.Reset(_seq * kVoc);
		for (uint32 i = 0; i < _seq * kVoc; ++i) one.Data()[i] = 0.0f;
		for (uint32 t = 0; t < _seq; ++t)
		{
			uint32 v = (uint32)tgt.Data()[t];
			if (v >= kVoc) v = 0u;
			one.Data()[t * kVoc + v] = 1.0f;
		}

		// 🎲 파라미터 초기화 — ⚠️ **0 으로 두면 안 된다**: 표가 0 이면 임베딩이 전부 같아 기울기도 같고
		//   대칭이 안 깨진다(모든 바이트가 같은 예측을 낸다). 결정적인 작은 값으로 흔든다.
		Array<float> tbl; tbl.Reset(kVoc * kDimL);
		for (uint32 i = 0; i < kVoc * kDimL; ++i)
			tbl.Data()[i] = ((float)((i * 2654435761u) % 1000u) / 1000.0f - 0.5f) * 0.2f;
		Array<float> w; w.Reset(kDimL * kVoc);
		for (uint32 i = 0; i < kDimL * kVoc; ++i)
			w.Data()[i] = ((float)((i * 40503u + 7u) % 997u) / 997.0f - 0.5f) * 0.2f;

		if (!_lm.Write(_lTok, cur) || !_lm.Write(_lTgt, tgt)
			|| !_lm.Write(_lOne, one) || !_lm.Write(_lTable, tbl)
			|| !_lm.Write(_lW, w))
		{
			LogA("[ml] LM: 업로드 실패\n");
			return false;
		}

		// ⚠️ 커널은 **그 아레나에** 바인딩된다 → LM 전용 아레나용으로 따로 만든다(같은 셰이더라도).
		if (!_LoadKernelIn(_lmEmb,  "shaders/embed.cs.spv",     _lm)) return false;
		if (!_LoadKernelIn(_lmEmbB, "shaders/embed_bwd.cs.spv", _lm)) return false;
		if (!_LoadKernelIn(_lmGemm, "shaders/gemm.cs.spv",      _lm)) return false;
		if (!_LoadKernelIn(_lmSub,  "shaders/sub.cs.spv",       _lm)) return false;
		if (!_LoadKernelIn(_lmSoft, "shaders/softmax.cs.spv",   _lm)) return false;
		if (!_LoadKernelIn(_lmAdam, "shaders/adamw.cs.spv",     _lm)) return false;
		return true;
	}

	bool _LoadKernelIn(MLKernel& k, const char* path, const MLArena& arena)
	{
		Bytes spv;
		if (!PlatformFile::LoadBytes(path, spv, PlatformFileSource::Package) || spv.GetSize() == 0)
		{
			LogA("[ml] %s 를 못 읽었다(쿡 확인)\n", path);
			return false;
		}
		if (!k.Create(rhi, spv.GetData(), spv.GetSize(), arena))
		{
			LogA("[ml] %s 커널 생성 실패\n", path);
			return false;
		}
		return true;
	}

	// 🧿 **최소대립쌍 격자** — 줄마다 축 하나, 칸 둘(A | B).
	//   ★ **이 그림이 곧 어휘 감사다.** 한 줄을 보면 **정확히 하나만** 달라야 하고, 캡션도 **한 낱말만**
	//     달라야 한다. 둘 중 하나라도 어긋나면 그 축은 아직 가르칠 수 없는 상태다.
	//   ⚠️ 캡션을 로그에 나란히 찍는다 — 그림만으로는 "낱말이 하나만 달랐나" 를 볼 수 없다.
	void _RunPairProbe()
	{
		const int cell = MLSense::kSize;
		const int rows = MLSense::AxisCount();

		ImageFormat::Bitmap grid;
		if (!ImageFormat::CreateRGBA8(grid, (uint32)(cell * 2), (uint32)(cell * rows)))
		{
			LogA("[ml] 대립쌍 격자를 못 만들었다\n");
			return;
		}
		ImageFormat::Fill(grid, Vector4(0.16f, 0.16f, 0.20f, 1.0f));

		int okAxes = 0, captionLies = 0;
		for (int i = 0; i < rows; ++i)
		{
			MLEpisode a, b;
			// ⚠️ 64² 는 좁아서 **그 축을 흔들 수 없는 사례**가 있다(큰 도형 다섯 개 등) → 시끄럽게 넘긴다.
			if (!MLSense::BuildPair(i, (uint32)(7000u + (uint32)i * 13u), true, a, b))
			{
				LogA("[ml] %s 축: 대립쌍을 못 만들었다(캔버스에 안 들어간다)\n",
					MLSense::AxisName(MLSense::AxisAt(i)));
				continue;
			}

			// ★ 캡션이 **한 낱말만** 다른지 센다 — 그것이 이 축이 최소대립쌍인가의 판정이다.
			const int diff = _CaptionWordDiff(a.caption, b.caption);
			const bool ok = (diff == 1);
			if (ok) okAxes++;
			LogA("\n[ml] ── 축 '%s' %s(다른 낱말 %d개)\n[ml]   A: %s\n[ml]   B: %s\n",
				MLSense::AxisName(MLSense::AxisAt(i)), ok ? "" : "★대립쌍 아님★ ",
				diff, a.caption.ptr(), b.caption.ptr());

			// ⚠️ 두 판을 **각각 임시 비트맵에** 그린다 — `_RunEpisode` 는 프레임을 `f * cell` 에 깔므로
			//   한 프레임짜리 에피소드는 늘 0열이다. 그리고 그 임시 비트맵이 **판독 대상**이 된다.
			Bytes junk;
			ImageFormat::Bitmap fa, fb;
			if (!ImageFormat::CreateRGBA8(fa, (uint32)cell, (uint32)cell)) continue;
			if (!ImageFormat::CreateRGBA8(fb, (uint32)cell, (uint32)cell)) continue;
			if (!_RunEpisode(a, fa, 0, cell, junk)) continue;
			if (!_RunEpisode(b, fb, 0, cell, junk)) continue;
			ImageFormat::FitIntoRect(fa, grid, 0,    i * cell, cell, cell, Vector4(0, 0, 0, 1));
			ImageFormat::FitIntoRect(fb, grid, cell, i * cell, cell, cell, Vector4(0, 0, 0, 1));

			// 👁️ **캡션 vs 프레임** — 캡션이 말한 개수가 그림에 정말 그만큼 있나.
			//   ★ **캡션 감사만으로는 이것을 못 잡는다.** 실측으로 밟았다: 캡션은 `셋이` 인데
			//     그림에는 하나뿐이었고(격자 오프셋이 0 이 되어 겹쳤다) 낱말 감사는 **통과했다.**
			//     ⇒ **말과 그림을 서로 견주는 검사가 따로** 있어야 한다.
			MLFrameFacts ka, kb;
			MLFrameReader::Read(fa, ka);
			MLFrameReader::Read(fb, kb);

			// ㉠ **개수** — 덩어리 수(절대 판정).
			const int wantA = _CaptionCount(a.caption), wantB = _CaptionCount(b.caption);
			// ⚠️ -1 = "여럿이"(6 이상) — 정확한 수를 말하지 않으므로 개수 검사를 건너뛴다.
			const bool cntOk = (wantA < 0 || ka.blobs == wantA) && (wantB < 0 || kb.blobs == wantB);

			// ㉡ **자리** — bbox 중심을 낱말로 되돌려 캡션과 견준다(절대 판정).
			//   ★ **이 축이 실제로 거짓말을 하고 있었다.** 예전 `Center` 는 고정 좌표를 쓰고 넘치면
			//     중심을 접었는데, 그 접기가 왼쪽/가운데/오른쪽을 몇 픽셀 차로 뭉갰다(128² 에서 56/64/71).
			//     캡션은 `왼쪽` 이라 말하고 그림은 가운데였고 — **낱말 감사도 개수 감사도 통과했다.**
			//   ⇒ 축을 하나 늘릴 때마다 **그 축의 되짚기도 같이** 늘려야 한다는 뜻이다.
			const bool posOk = _PosMatches(a.caption, ka) && _PosMatches(b.caption, kb);

			// ㉢ **색** — 켜진 픽셀의 평균색에 가장 가까운 팔레트가 캡션의 색 낱말인가(절대 판정).
			const bool colOk = _ColorMatches(a.caption, ka) && _ColorMatches(b.caption, kb);

			// ㉣ **크기·속** — ★ **대립쌍이라 절대 임계값이 필요 없다.**
			//   그 축만 다르므로 **물리량의 순서**만 보면 된다: 큰 쪽 bbox 가 더 넓고, 찬 쪽이 더 빽빽하다.
			//   ⚠️ 임계값을 박으면 해상도를 바꿀 때마다 조용히 썩는다 — 방금 그 종류의 버그를 고쳤다.
			//   ⚠️ 그 축을 흔든 줄에서만 본다(다른 줄에서는 두 값이 같아야 정상이라 순서가 없다).
			const MLAxis ax = MLSense::AxisAt(i);
			bool ordOk = true;
			if (ax == MLAxis::Size)
			{
				const int bigSide = _CaptionBig(a.caption);   // 1 = A 가 큰 쪽
				const int areaA = _BoxArea(ka), areaB = _BoxArea(kb);
				ordOk = (bigSide == 1) ? (areaA > areaB) : (areaB > areaA);
			}
			else if (ax == MLAxis::Fill)
			{
				const int fullSide = _CaptionFilled(a.caption);   // 1 = A 가 찬 쪽
				ordOk = (fullSide == 1) ? (ka.fillRatio > kb.fillRatio)
				                        : (kb.fillRatio > ka.fillRatio);
			}

			if (!cntOk || !posOk || !colOk || !ordOk) captionLies++;
			LogA("[ml]   판독: 덩어리 %d/%d(캡션 %d/%d) · 자리 %s · 색 %s · 순서 %s%s\n",
				ka.blobs, kb.blobs, wantA, wantB,
				posOk ? "맞다" : "★틀렸다★", colOk ? "맞다" : "★틀렸다★",
				ordOk ? "맞다" : "★틀렸다★",
				(cntOk && posOk && colOk && ordOk) ? "" : " ← ★캡션이 프레임과 다르다★");
		}

		Bytes png;
		if (ImageFormat::Save(grid, ImageFormat::ImageFileType::PNG, png))
		{
			if (PlatformFile::SaveBytes("ml_pairs.png", png, PlatformFileSource::External))
				LogA("\n[ml] 대립쌍 격자 저장: <bin_dev>/ml_pairs.png (%llu bytes)\n",
					(unsigned long long)png.GetSize());
		}
		_JudgeMotion();

		// ★ **판정이 둘이다 — 그리고 둘이 다른 것을 잡는다.**
		//   ㉠ 캡션이 한 낱말만 다른가 = 대립쌍의 **구조**
		//   ㉡ 캡션이 프레임과 맞는가  = 대립쌍의 **진실성**(㉠ 이 통과해도 여기서 걸릴 수 있다)
		LogA("[ml] 감각 어휘 판정: 최소대립쌍 %d/%d · 캡션이 거짓인 축 %d개 %s\n",
			okAxes, rows, captionLies, (okAxes == rows && captionLies == 0) ? "— 통과" : "— ★실패★");
	}

	// bbox 의 넓이(크기 축의 물리량).
	static int _BoxArea(const MLFrameFacts& k)
	{
		if (k.empty) return 0;
		return (k.maxX - k.minX + 1) * (k.maxY - k.minY + 1);
	}

	// 📍 캡션의 **자리 낱말**이 그림의 bbox 중심에서 다시 나오는가.
	//   ★ 경계 숫자는 `MLEpisodeGen::WordH/WordV` 안에만 있다 — 여기 복사해 두면 조용히 어긋난다.
	static bool _PosMatches(const String& cap, const MLFrameFacts& k)
	{
		if (k.empty) return false;
		const int cx = (k.minX + k.maxX) / 2, cy = (k.minY + k.maxY) / 2;
		const char* gotH = MLEpisodeGen::WordH(cx);
		const char* gotV = MLEpisodeGen::WordV(cy);
		const int p = _CaptionPos(cap);
		if (p < 0) return false;
		const bool horiz = (p == 0 || p == 1);
		const char* want = (p == 4) ? nullptr : MLSense::WordPos(p);
		return MLSense::_SameWord(gotH, horiz ? want : nullptr)
		    && MLSense::_SameWord(gotV, horiz ? nullptr : want);
	}

	// 🎨 캡션의 **색 낱말**이 평균색에 가장 가까운 팔레트와 같은가.
	//   ★ 가장 가까운 것을 고른다(임계값 없음) — 팔레트가 서로 충분히 떨어져 있는지도 이 판정이 지킨다.
	static bool _ColorMatches(const String& cap, const MLFrameFacts& k)
	{
		if (k.empty) return false;
		int best = -1, bestD = 0;
		for (int c = 0; c < MLEpisodeGen::PaletteCount(); ++c)
		{
			const MLPalette& pal = MLEpisodeGen::Palette(c);
			const int dr = k.avgR - pal.r, dg = k.avgG - pal.g, db = k.avgB - pal.b;
			const int d = dr * dr + dg * dg + db * db;
			if (best < 0 || d < bestD) { best = c; bestD = d; }
		}
		if (best < 0) return false;
		return _Contains(cap.ptr(), MLEpisodeGen::Palette(best).name);
	}

	// 캡션의 자리 낱말 → 인덱스(`MLScene::pos` 와 같은 뜻). 못 찾으면 -1.
	static int _CaptionPos(const String& cap)
	{
		const char* p = cap.ptr();
		if (p == nullptr) return -1;
		// ⚠️ 조사가 떨어졌으므로 낱말만 찾는다. ★ `오른쪽` 이 `왼쪽` 을 **안 포함**하므로 순서가 안전하다.
		if (_Contains(p, "왼쪽"))   return 0;
		if (_Contains(p, "오른쪽")) return 1;
		if (_Contains(p, "위"))     return 2;
		if (_Contains(p, "아래"))   return 3;
		if (_Contains(p, "가운데")) return 4;
		return -1;
	}
	// 1 = 큰 · 0 = 작은 · -1 = 그 낱말이 없다.
	static int _CaptionBig(const String& cap)
	{
		const char* p = cap.ptr();
		if (p == nullptr) return -1;
		if (_Contains(p, "큰"))   return 1;
		if (_Contains(p, "작은")) return 0;
		return -1;
	}
	// 1 = 찬 · 0 = 빈 · -1 = 그 낱말이 없다.
	static int _CaptionFilled(const String& cap)
	{
		const char* p = cap.ptr();
		if (p == nullptr) return -1;
		if (_Contains(p, "찬")) return 1;
		if (_Contains(p, "빈")) return 0;
		return -1;
	}

	// 캡션의 **개수 낱말**을 수로 되돌린다(판독 결과와 견주기 위해).
	//   ⚠️ "여럿이" 는 6 이상을 뜻하므로 정확한 수가 아니다 → -1 을 돌려주고 호출부가 봐준다.
	static int _CaptionCount(const String& cap)
	{
		const char* p = cap.ptr();
		if (p == nullptr) return -1;
		// ⚠️ 개수를 **아라비아 숫자**로 쓴다(생성기 주석 참조). ★ 캡션에서 숫자는 개수 자리에만 나오므로
		//   한 글자만 찾아도 안전하다.
		if (_Contains(p, "1")) return 1;
		if (_Contains(p, "2")) return 2;
		if (_Contains(p, "3")) return 3;
		if (_Contains(p, "4")) return 4;
		if (_Contains(p, "5")) return 5;
		return -1;   // 여럿 — 세지 않는다
	}
	static bool _Contains(const char* hay, const char* needle)
	{
		for (uint32 i = 0; hay[i] != 0; ++i)
		{
			uint32 k = 0;
			while (needle[k] != 0 && hay[i + k] == needle[k]) k++;
			if (needle[k] == 0) return true;
		}
		return false;
	}

	// 두 캡션에서 **다른 낱말의 수**. ⚠️ 공백으로 자른다 — 캡션이 평행 구조라 낱말 수가 같다.
	//   ★ 낱말 수가 다르면 그것부터 대립쌍 위반이다(구조가 안 평행하다) → 큰 수를 돌려준다.
	//
	// ⚠️⚠️ **낱말을 `String` 으로 만들지 않는다 — 바이트 구간을 직접 견준다.**
	//   실측으로 밟았다: 한 바이트씩 `AppendFormat("%c", ...)` 로 낱말을 조립했더니 **낱말이 하나도
	//   안 생겼다**(비교가 늘 0 을 냈다). 한글은 멀티바이트라 **홀로 있는 이어짐 바이트가 유효한 UTF-8 이
	//   아니고**, `String` 은 UTF-8 을 알아서 그것을 받지 않는다.
	//   ★ 그래서 여기서는 문자열을 만들 이유가 없다 — 필요한 것은 "구간이 같나" 뿐이다.
	static int _CaptionWordDiff(const String& a, const String& b)
	{
		const char* pa = a.ptr();
		const char* pb = b.ptr();
		if (pa == nullptr || pb == nullptr) return 99;

		uint32 ia = 0, ib = 0;
		int diff = 0;
		for (;;)
		{
			while (pa[ia] == ' ') ia++;
			while (pb[ib] == ' ') ib++;
			if (pa[ia] == 0 && pb[ib] == 0) break;
			if (pa[ia] == 0 || pb[ib] == 0) return 99;   // 낱말 수가 다르다 = 구조가 안 평행하다

			// 이 낱말의 구간을 잡는다(공백 또는 끝까지).
			uint32 ea = ia; while (pa[ea] != 0 && pa[ea] != ' ') ea++;
			uint32 eb = ib; while (pb[eb] != 0 && pb[eb] != ' ') eb++;

			bool same = ((ea - ia) == (eb - ib));
			if (same)
				for (uint32 k = 0; k < ea - ia; ++k)
					if (pa[ia + k] != pb[ib + k]) { same = false; break; }
			if (!same) diff++;

			ia = ea; ib = eb;
		}
		return diff;
	}

	// ══════════════════════════════════════════════════════════════════
	// 🖐️ **D66 · 모델이 행동한다** — 1인칭이 처음 생기는 자리.
	//
	// ★ 대화에서 나온 고리 그대로다:
	//   `목표` → `뭘할까(후보)` → **예측을 겸한 해결책 설계** → `시도` → `결과` →
	//   `실패면 어디가 틀렸나` → `고친다` → 다시.
	//   ⇒ 그리고 *"코딩 때 잘됐나 자기 검사도 비전으로"* — **결과를 프레임에서 읽어** 무엇이
	//     틀렸는지 스스로 안다. 생성기의 파라미터는 **한 번도 안 본다**.
	//
	// ★ 세계: 축 셋(색 5 · 자리 3 · 크기 3 = **45 후보**)의 값을 고르면 프로그램이 되고,
	//   실행하면 프레임이 나온다(`MLEpisodeGen::TaskCode`). 목표도 같은 방식으로 만든 프레임이다.
	// ★ **자기 검사는 비전으로만** 한다:
	//   · 색  — 잉크 **바이트값**이 목표와 같나(다르면 그 축이 틀렸다. ⚠️ 방향은 없다)
	//   · 자리 — 무게중심 x 가 목표보다 왼쪽인가 오른쪽인가 ⇒ **부호**가 나온다
	//   · 크기 — 잉크량이 목표보다 적은가 많은가 ⇒ **부호**가 나온다
	//   ⇒ 그것이 **호/불호의 부호 있는 판**이고, `concept.md` 가 자기상태의 1순위로 적은
	//     **기대 위반**(어느 믿음을 고칠지 가리킨다)이다.
	//
	// ★ **미리 등록**(작동 판정):
	//   ㉠ **도달** — 신호 팔이 45 후보 중 정답에 **늘 닿나**(100%).
	//   ㉡ ★ **자리 지목이 맞나** — 「이 축이 틀렸다」고 지목한 것이 **실제로 틀린 축**인가.
	//      ⇒ 이것이 *"기대 위반이 관련된 믿음을 선택적으로 고친다"* 를 재는 자리다.
	//   ㉢ ★ **몇 배 싸나** — 신호 팔 ↔ 무작위 팔의 평균 시도 수. `concept.md` 의 전이 기록이
	//      요구하는 형태가 「몇 %」가 아니라 **「같은 곳에 닿기까지 몇 배」**다.
	//   ⚠️ 대조군은 **같은 비용**이다 — 같은 시도 상한 · 같은 시작 상태 · 축 하나만 바꾼다.
	//
	// ⚠️⚠️ **이 고리는 탐색이고 「배웠다」가 아니다.** 얻는 것은 하나다 —
	//   ***호/불호가 실제로 다음 시도를 바꾸는 고리가 도는가.*** 그것이 돌면 그 위에 학습을
	//   얹을 자리가 생긴다(지금은 표가 없다).
	// ══════════════════════════════════════════════════════════════════
	void _RunAct()
	{
		const int cell = MLEpisodeGen::kSize;
		const uint64 plane = (uint64)cell * (uint64)cell;
		const int kTask = 120, kCap = 60;          // 과제 수 · 시도 상한
		LogA("[ml] ── 🖐️ **D66 · 모델이 행동한다** — 1인칭이 처음 생기는 자리 ──────────────\n"
			"[ml]   ★ 고리: 목표 → 후보 → **시도** → 결과 → **비전으로 어디가 틀렸나** → 고친다\n"
			"[ml]   ★ 자기 검사는 **프레임에서만** — 색(바이트값) · 자리(중심 x 부호) ·"
			" 크기(잉크량 부호). 생성기의 파라미터는 **한 번도 안 본다**\n"
			"[ml]   ★ 작동 판정: ㉠ **도달 100%%** · ㉡ ★ **자리 지목이 맞나** ·"
			" ㉢ ★ **몇 배 싸나**(대조군 = 무작위 축 · **같은 비용**)\n"
			"[ml]   ⚠️⚠️ 이 고리는 **탐색**이고 「배웠다」가 아니다 — 얻는 것은"
			" *호/불호가 실제로 다음 시도를 바꾸는 고리가 도는가* 하나다\n"
			"[ml]   ⚠️ 후보 %d개(색 %d × 자리 3 × 크기 3) · 과제 %d개 · 시도 상한 %d\n",
			MLEpisodeGen::PaletteCount() * 9, MLEpisodeGen::PaletteCount(), kTask, kCap);
		SeedRand(MLEpisodeGen::ScrambleSeed(66000u));
		// 🖼️ 한 상태를 실행해 (바이트값, 중심x, 잉크) 를 낸다 — **비전이 주는 전부**다.
		ImageFormat::Bitmap junk;
		if (!ImageFormat::CreateRGBA8(junk, (uint32)cell, (uint32)cell))
			{ LogA("[ml]   ⛔ 비트맵을 못 만들었다\n"); return; }
		int okA = 0, okB = 0, nA = 0, nB = 0;
		double trA = 0.0, trB = 0.0;
		int pickN = 0, pickOk = 0;
		int firstWrong[4] = {};
		// ★ **확신의 크기** — 틀린 축이 k개일 때의 평균 확신(Top)과 여유(Margin).
		//   ⇒ 「기대 위반의 무게」가 갈리는지를 처음 잰다(D67).
		int cfN[4] = {}; double cfS[4] = {}, cfM[4] = {};
		for (int q = 0; q < kTask; ++q)
		{
			const int nc = MLEpisodeGen::PaletteCount();
			const int gc = RandInt(0, nc), gx = RandInt(0, 3), gs = RandInt(0, 3);
			// 🎯 목표를 실행해 그 지표를 얻는다(프레임만 본다).
			uint8 gv = 0; int64 gcx = 0; uint64 gink = 0;
			{
				DrawProgram gp;
				// 📎 `TaskCode(...)` 의 결과를 **지역 변수로 받는다** — 가독성 때문이다.
				//   ⚠️⚠️ **주석을 정정한다**(2026-08-24): 처음에 이것을 「크래시 가설」로 적었는데
				//   **반증됐다** — ㉠ 실측: 수명을 늘려도 죽었다 ㉡ 원리: `ScriptRunner::Compile` 은
				//   `source` 를 `CompileSource` 에 넘기고 **보관하지 않는다**(`_program` 에 컴파일
				//   결과만 저장한다 · Engine/Script/ScriptRunner.cpp:32) ⇒ **원래 코드도 안전했다.**
				//   ★ 되돌리지 않고 남기는 이유는 **지역 변수가 더 명확해서**이고 그것뿐이다.
				const String src0 = MLEpisodeGen::TaskCode(gc, gx, gs);
				if (!gp.Compile(src0.View(),
					(uint32)cell, (uint32)cell, NameID("ActG"))) continue;
				if (!gp.RunStart()) continue;
				Bytes b; b.Reset(plane);
				if (!ImageFormat::PackRGB332Delta(gp.canvas, nullptr, (uint8*)b.GetData(), plane))
					continue;
				const uint8* p = (const uint8*)b.GetData();
				const uint8 bg = _BgByte(p, plane);
				Blob bl[8]; const int n = _Blobs(p, cell, bg, bl, 8);
				if (n != 1) continue;
				gv = bl[0].v; gcx = bl[0].cx16; gink = bl[0].ink;
			}
			// 두 팔이 **같은 시작 상태**에서 출발한다(같은 비용 · 함정 135).
			const int s0c = RandInt(0, nc), s0x = RandInt(0, 3), s0s = RandInt(0, 3);
			for (int arm = 0; arm < 2; ++arm)
			{
				int cc = s0c, cx = s0x, cs = s0s;
				bool hit = false; int tries = 0;
				for (; tries < kCap; ++tries)
				{
					// 🖐️ **시도** — 지금 고른 것을 실제로 실행한다.
					DrawProgram pr;
					// 📎 `TaskCode(...)` 의 결과를 **지역 변수로 받는다** — 가독성 때문이다.
					//   ⚠️⚠️ **주석을 정정한다**(2026-08-24): 처음에 이것을 「크래시 가설」로 적었는데
					//   **반증됐다** — ㉠ 실측: 수명을 늘려도 죽었다 ㉡ 원리: `ScriptRunner::Compile` 은
					//   `source` 를 `CompileSource` 에 넘기고 **보관하지 않는다**(`_program` 에 컴파일
					//   결과만 저장한다 · Engine/Script/ScriptRunner.cpp:32) ⇒ **원래 코드도 안전했다.**
					//   ★ 되돌리지 않고 남기는 이유는 **지역 변수가 더 명확해서**이고 그것뿐이다.
					const String src1 = MLEpisodeGen::TaskCode(cc, cx, cs);
					if (!pr.Compile(src1.View(),
						(uint32)cell, (uint32)cell, NameID("Act"))) break;
					if (!pr.RunStart()) break;
					Bytes b; b.Reset(plane);
					if (!ImageFormat::PackRGB332Delta(pr.canvas, nullptr, (uint8*)b.GetData(), plane))
						break;
					const uint8* p = (const uint8*)b.GetData();
					const uint8 bg = _BgByte(p, plane);
					Blob bl[8]; const int n = _Blobs(p, cell, bg, bl, 8);
					if (n != 1) break;
					// 👁️ **비전으로 자기 검사** — 축마다 틀렸나(그리고 부호가 있으면 방향까지).
					// 👁️ **비전으로 자기 검사** — 축마다 **얼마나** 틀렸나(이진이 아니다 · D67).
					//   ⚠️ **색은 이산이라 크기가 없다** — 1.0 은 「완전히 틀렸다」는 뜻이다. 그래서 색이 틀리면
					//     늘 먼저 고쳐진다(정규화된 자리·크기 오차는 1 보다 작다) ⇒ D66 의 정책과 **같다**.
					//     그것은 우연이 아니라 **이산 축이 연속 축보다 오차가 크기 때문**이다.
					MLChoice ax3; ax3.Reset(3);
					ax3.Set(0, (bl[0].v != gv) ? 1.0 : 0.0);
					{
						const int64 dx = (bl[0].cx16 > gcx) ? (bl[0].cx16 - gcx) : (gcx - bl[0].cx16);
						ax3.Set(1, (double)dx / (double)((int64)cell * 16));
						const uint64 hi = (bl[0].ink > gink) ? bl[0].ink : gink;
						const uint64 lo = (bl[0].ink > gink) ? gink : bl[0].ink;
						ax3.Set(2, (hi > 0u) ? ((double)(hi - lo) / (double)hi) : 0.0);
					}
					// ✅ **도달** — 점수가 하나도 안 살아 있으면 다 맞았다. ⚠️ 정규화 **전에** 묻는다.
					if (!ax3.Any()) { hit = true; break; }
					ax3.Normalize();
					const int wax = ax3.Argmax();
					// 📏 ㉡ **자리 지목이 맞나** — 지목한 축이 실제로 틀린 축인가(채점 전용).
					if (arm == 1)
					{
						if (tries == 0)
						{
							int k = 0;
							if (cc != gc) k++;
							if (cx != gx) k++;
							if (cs != gs) k++;
							firstWrong[k]++;
						}
						// 📏 ㉡ 자리 지목이 맞나 + ★ **확신의 크기**(D67 이 처음 잴 수 있게 됐다).
						const bool truly = (wax == 0) ? (cc != gc) : ((wax == 1) ? (cx != gx) : (cs != gs));
						pickN++; if (truly) pickOk++;
						{
							int kw = 0;
							if (cc != gc) kw++;
							if (cx != gx) kw++;
							if (cs != gs) kw++;
							if (kw >= 1 && kw <= 3) { cfN[kw]++; cfS[kw] += ax3.Top(); cfM[kw] += ax3.Margin(); }
						}
					}
					// 🔁 **고친다.**
					if (arm == 1)
					{
						// 신호 팔 — 틀렸다고 **비전이 말한** 축을 고친다. 부호가 있으면 그 방향으로.
						if (wax == 0) cc = (cc + 1) % nc;         // 색은 방향이 없다 ⇒ 다음 값
						else if (wax == 1) cx += (bl[0].cx16 > gcx) ? -1 : 1;
						else cs += (bl[0].ink > gink) ? -1 : 1;
						if (cx < 0) cx = 0; if (cx > 2) cx = 2;
						if (cs < 0) cs = 0; if (cs > 2) cs = 2;
					}
					else
					{
						// 🚪 대조군 — **무작위 축**을 무작위 값으로. 같은 비용, 신호만 안 쓴다.
						const int ax = RandInt(0, 3);
						if (ax == 0) cc = RandInt(0, nc);
						else if (ax == 1) cx = RandInt(0, 3);
						else cs = RandInt(0, 3);
					}
				}
				if (arm == 1) { nA++; if (hit) { okA++; trA += (double)(tries + 1); } }
				else          { nB++; if (hit) { okB++; trB += (double)(tries + 1); } }
			}
		}
		if (nA == 0) { LogA("[ml]   🖐️ ⚠️ **판정불가**\n"); return; }
		const double rA = 100.0 * (double)okA / (double)nA;
		const double rB = 100.0 * (double)okB / (double)nB;
		const double mA = (okA > 0) ? (trA / (double)okA) : 0.0;
		const double mB = (okB > 0) ? (trB / (double)okB) : 0.0;
		const double pk = (pickN > 0) ? (100.0 * (double)pickOk / (double)pickN) : 0.0;
		const double ratio = (mA > 0.0) ? (mB / mA) : 0.0;
		LogA("[ml]      🚪 대조군(무작위 축) — 도달 %.1f%% · 닿은 것의 평균 시도 **%.1f**\n"
			"[ml]      👁️ 신호 팔(비전 지목) — 도달 %.1f%% · 닿은 것의 평균 시도 **%.1f**\n"
			"[ml]      ㉠ **도달** %.1f%% ⇒ %s\n"
			"[ml]      ㉡ ★ **자리 지목이 맞나** %d/%d = **%.1f%%** ⇒ %s\n"
			"[ml]      ㉢ ★ **몇 배 싸나** — %.1f → %.1f 시도 = **%.2f배** ⇒ %s\n"
			"[ml]         └ 첫 시도에서 틀린 축이 0/1/2/3개인 과제 수 — %d / %d / %d / %d\n"
			"[ml]      ㉤ 🎲 **확신의 크기**(D67 — 분포라서 처음 잴 수 있다) — 틀린 축 1/2/3개일 때"
			" 확신 %.2f / %.2f / %.2f · 여유 %.2f / %.2f / %.2f ⇒ %s\n"
			"[ml]      ⇒ %s\n",
			rB, mB, rA, mA,
			rA, (rA >= 99.95) ? "✅ **늘 닿는다**" : "⛔ **못 닿는 과제가 있다**(고리가 갇힌다)",
			pickOk, pickN, pk,
			(pk >= 99.95) ? "✅✅ **늘 맞는다** — 기대 위반이 **고칠 자리를 정확히** 가리킨다"
				: ((pk >= 90.0) ? "✅ 거의 맞는다" : "⛔ **어긋난다** — 비전 지표가 축과 안 맞는다"),
			mB, mA, ratio,
			(ratio >= 2.0) ? "✅✅ **신호가 값을 한다**(2배 이상)"
				: ((ratio > 1.05) ? "⚠️ **싸지긴 하는데 작다**" : "⛔ **안 싸다** — 신호가 값을 안 한다"),
			firstWrong[0], firstWrong[1], firstWrong[2], firstWrong[3],
			(cfN[1] > 0) ? (cfS[1] / cfN[1]) : 0.0, (cfN[2] > 0) ? (cfS[2] / cfN[2]) : 0.0,
			(cfN[3] > 0) ? (cfS[3] / cfN[3]) : 0.0,
			(cfN[1] > 0) ? (cfM[1] / cfN[1]) : 0.0, (cfN[2] > 0) ? (cfM[2] / cfN[2]) : 0.0,
			(cfN[3] > 0) ? (cfM[3] / cfN[3]) : 0.0,
			(cfN[1] > 0 && cfN[2] > 0 && (cfS[1] / cfN[1]) > (cfS[2] / cfN[2]))
				? "✅ **틀린 축이 많으면 확신이 낮다** — 기대 위반의 무게가 갈린다"
				: "⚠️ **안 갈린다** — 점수의 크기가 뜻을 못 낸다(축의 오차 척도를 본다)",
			(rA >= 99.95 && pk >= 99.95 && ratio >= 2.0)
				? "✅✅✅ ***호/불호가 다음 시도를 바꾼다*** — 고리가 돌고, 기대 위반이 고칠 자리를"
				  " 가리키고, 무작위보다 싸다. ⇒ **1인칭 자기상태가 생겼다**(그 위에 학습을 얹을 자리다)"
				: "⛔ **아직 고리가 아니다** — 위 셋 중 어느 것이 미달인지 보고 그것부터 고친다");
	}
	// ══════════════════════════════════════════════════════════════════
	// 📐 **D65 · 목표거리를 「누구의」 것으로** — 함정 212 의 처방.
	//
	// ★ D64 가 실측했다: 대상이 둘이면 **합친 무게중심**이 관계 변화를 못 잰다 —
	//   11칸은 둘이 대칭으로 움직여(+step/−step) 중심이 **고정**되고 낱말이 「됐다」 **100%** 였다.
	//   ⚠️ 10칸은 80/0/20 으로 **정상처럼 보이는데** 그것도 평균이라 *"누가 가까워졌나"* 를
	//     안 말한다 — **더 위험한 쪽**이다(틀린 값이 그럴듯하다).
	//
	// ★ **대상은 색(바이트값)으로 가른다.** `ImageOps` 는 **AA 가 없으므로**(그 모듈의 규약)
	//   한 도형 = **한 바이트값**이고, 두 대상은 색이 다르다(`_TwoColors` 가 보장한다).
	//   ⚠️ **오라클이 아니다** — 색은 프레임에 있는 값이고 「같은 값끼리 묶는다」는
	//     `concept.md` 가 줄 수 있다고 적은 것(*"같은 채널 안에서 센서가 직접 정의하는 유사"*)이다.
	//     생성기의 숨은 상태(어느 도형이 몇 번째인가)는 한 번도 안 본다.
	//
	// ★ 재는 것 둘:
	//   · **대상별 목표거리** — 같은 바이트값끼리 짝지어 중심 사이 거리. ⇒ 대상마다 호/불호가 생긴다.
	//   · **관계 거리** — 지금 장에서 두 중심 사이 거리. 그 변화가 `가까워진다`·`멀어진다` 다.
	//
	// ★ **미리 등록**(작동 판정 · 문턱이 아니다):
	//   ㉠ **회귀** — 대상이 하나인 4~7칸은 대상별 = 합친 것과 **같아야** 한다(D59 의 80/80/30.8/46.7).
	//   ㉡ 11칸의 **관계 낱말이 갈리나** — `가까워진다`와 `멀어진다`가 **둘 다** 나오나.
	//   ㉢ ★ **캡션 일치율 100%** — 세계가 캡션에 쓴 낱말과 우리가 잰 부호가 **같아야** 한다.
	//      같은 사실이므로 하나라도 어긋나면 **측정이 틀린 것**이다(가장 강한 검사다).
	//   ㉣ 11칸의 **대상별** 낱말이 「됐다」 100% 를 벗어나나 ⇒ 함정 212 가 고쳐졌나.
	// ══════════════════════════════════════════════════════════════════
	// ══════════════════════════════════════════════════════════════════
	// 🎲 **MLChoice — 판단은 분포로 들고 다닌다**(D67)
	//
	// ★ **설계선 하나**: 학습자의 판단은 **분포** · 세계의 법칙은 **확정** · 판정문은 **문턱**.
	//   굳히는 자리는 **세계 경계 하나**다(`Argmax`). 그 앞은 늘 점수/분포로 들고 다닌다.
	//
	// ★ **왜 지금인가 — `concept.md` 가 이미 세 곳에서 요구한다**:
	//   *"가능성을 너무 일찍 하나로 접지도 않는다"* · *"기대 위반을 그 예측에 실제로 참여한
	//   활성 경로와 함께 기록한다"* · *"각 경로의 **책임 무게**가 갈리게 한다"*.
	//   ⇒ 「책임 무게」는 **분포가 없으면 쓸 수 없는 말**이다. 지금까지 argmax 로 굳혀서 못 썼다.
	//
	// ⚠️⚠️ **성능을 위한 것이 아니다.** 우리 실측이 오히려 반대를 말한다 — D20·D21 에서 soft
	//   무게가 hard 계층을 **못 이겼고**(1/12 · 5/12) D18 에서 후보 좁힘 자체는 값이 없었다.
	//   ⇒ 이것은 **계약**을 위한 것이고 판정에 **성능 향상을 등록하지 않는다**(배관 라운드).
	//
	// ★ 얻는 것은 **기대 위반의 크기**다 — `0.51 대 0.46` 으로 틀린 것과 `0.99 대 0.01` 로 틀린
	//   것은 같은 「틀림」이 아니다. 지금까지 그 둘이 **구별되지 않았다**.
	//
	// ⚠️ **문턱을 안에 두지 않는다** — 값을 계속 들고 다니고 문턱은 **판정문(로그)에서만** 쓴다.
	//   `mldiff` 의 문턱 튜닝이 그 교훈이다(함정 122·123).
	// ⚠️ **지수(softmax)를 안 쓴다** — 점수가 이미 「크기」라 비율이 뜻을 갖는다. softmax 를 쓰면
	//   **온도**라는 손잡이가 하나 더 생기고 그것은 지금 근거가 없다(함정 127: 미리 등록할 수 없다).
	// ⚠️ 소비자가 늘면 `MLCore` 로 올린다(지금은 이 파일의 두 자리뿐이다).
	// ══════════════════════════════════════════════════════════════════
	struct MLChoice
	{
		static constexpr int kMax = 8;
		int n = 0;
		double s[kMax] = {};          // 점수 → (`Normalize` 뒤) 확률
		bool flat = false;            // ⚠️ 점수가 전부 0 이라 균등으로 떨어졌다(= 아무것도 모른다)

		void Reset(int k)
		{
			n = (k < kMax) ? k : kMax;
			for (int i = 0; i < kMax; ++i) s[i] = 0.0;
			flat = false;
		}
		void Set(int i, double v) { if (i >= 0 && i < n) s[i] = v; }
		// 📏 점수가 하나라도 살아 있나 — **정규화 전에** 물어야 한다(뒤에는 균등이 되어 안 갈린다).
		bool Any() const
		{
			for (int i = 0; i < n; ++i) if (s[i] > 0.0) return true;
			return false;
		}
		void Normalize()
		{
			double z = 0.0;
			for (int i = 0; i < n; ++i) { if (s[i] < 0.0) s[i] = 0.0; z += s[i]; }
			if (z <= 0.0)
			{
				flat = true;
				const double u = 1.0 / (double)((n > 0) ? n : 1);
				for (int i = 0; i < n; ++i) s[i] = u;
				return;
			}
			for (int i = 0; i < n; ++i) s[i] /= z;
		}
		// 🚪 **여기가 세계 경계다** — 이 앞까지는 분포로 들고 다닌다.
		int Argmax() const
		{
			int b = 0;
			for (int i = 1; i < n; ++i) if (s[i] > s[b]) b = i;
			return b;
		}
		double Top() const { return (n > 0) ? s[Argmax()] : 0.0; }
		// 📏 **확신의 크기** = 최대 − 둘째. **기대 위반의 무게**가 여기서 나온다.
		double Margin() const
		{
			const int b = Argmax();
			double m = -1.0;
			for (int i = 0; i < n; ++i) if (i != b && s[i] > m) m = s[i];
			return (m < 0.0) ? s[b] : (s[b] - m);
		}
	};

	// ══════════════════════════════════════════════════════════════════
	// 🧠 **D76 · 고리 위에 학습을 얹는다** — 📌 2번. **탐색을 학습으로 바꾼다.**
	//
	// ★ **왜 표가 아니라 가중치인가** — D72~D75 가 셈 표의 천장을 쟀다(함정 220):
	//   표에는 심볼을 놓을 자리가 없다(**좌표는 곱셈 중복** · **분할은 표본 쪼갬**).
	//   ⇒ 여기서는 **선형 점수 + 가중치 갱신**이다. 가중치는 **모든 상태가 공유**하므로
	//     표본을 쪼개지 않고, 곱이 아니라 **어느 방향을 보는가**가 배워진다.
	//
	// ★ **보상이 곧 낱말이다** — 시도 뒤에 목표거리가 줄었으면 「**나아짐**」(+),
	//   아니면 「**막힘**」(−). ⇒ D58~D71 이 배운 그 심볼이 **새 능력의 학습 신호**로 쓰인다.
	//   ★ 이것은 D72~D75 가 물은 것과 **다른 뜻의 「앵커로 쓰인다」** 다 —
	//     거기서는 낱말을 **입력**으로 줬고(안 올랐다), 여기서는 **보상**으로 쓴다.
	//   ⚠️ 그래서 끊는 검사가 자연히 생긴다: **부호를 무작위로 하면 학습이 사라져야 한다.**
	//
	// ★ **행동 다섯**(축과 방향을 합쳤다) — 색+1 · 자리−1 · 자리+1 · 크기−1 · 크기+1.
	//   ⚠️ 범위를 벗어나는 행동은 **아무 일도 안 한다** ⇒ 세계가 「막힘」을 준다.
	//     ★ 그것도 배워야 하는 것이다(손으로 막지 않는다).
	// ★ **특징 27개** — 격자 셋(3x3):
	//   · `f[0..8]`   지금 장을 **목표의 색**으로 센 격자 ⇒ 색이 틀리면 **전부 0** 이 된다
	//     ★ 그것이 「색이 틀렸다」를 **프레임에서만** 읽는 길이다(생성기를 안 본다)
	//   · `f[9..17]`  지금 장을 **자기 색**으로 센 격자 ⇒ 색이 틀려도 자리·크기가 남는다
	//   · `f[18..26]` 목표 장
	//   ⚠️⚠️ **축별 오차를 주지 않는다**(함정 154) — 손 신호 팔이 읽는 그 세 수는 학습 팔에
	//     **한 번도 안 들어간다**. 학습 팔이 받는 것은 시도 **뒤의 한 비트**(나아짐/막힘)뿐이다.
	//
	// ★ 팔 넷(**같은 시작 상태 · 같은 행동 공간 · 같은 시도 상한** — 같은 비용):
	//   · 🚪 **무작위** — 다섯 중 하나(대조군)
	//   · 👁️ **손 신호** — D66 의 정책을 다섯 행동으로 적은 것(지금까지의 최고 · 4.6 시도)
	//   · 🧠 **배우는 정책** — 가중치. 보상 = 낱말
	//   · 🎲 **가짜 보상** — 부호를 무작위로(끊는다 · 갱신 횟수는 같다)
	//
	// ★ **미리 등록**(작동 판정):
	//   ㉠ **배우나** — 배우는 정책이 **전반 → 후반**으로 **1.5배 이상** 싸진다
	//   ㉡ **낱말이 값을 하나** — 가짜 보상은 그 개선이 **1.2배 미만**이다
	//   ㉢ **도달이 안 무너진다** — 배우는 정책의 도달률 **95% 이상**
	//   ★ 크기 예측: 무작위 **~25~40 시도**(안 변한다) · 손 신호 **~4.6**(안 변한다) ·
	//     배우는 정책 전반 **~15** → 후반 **~7**
	//   ⚠️ 갈릴 수 있는 자리: 선형 점수로는 「범위 밖 행동」을 못 배울 수 있다(상태에 따라
	//     같은 행동이 좋기도 나쁘기도 하다) ⇒ 그러면 개선이 작게 나온다. 그러면 그렇게 적는다.
	//
	// ══════ 🔗 **D77 — 함정 208 이 재발했다**(D76 의 실측이 시킨 것) ══════
	// ⛔ **D76 은 안 배웠다** — 전반 26.2 → 후반 25.2 시도(**1.04배**) · 도달 **62.2%**.
	//   ✅ 배관은 멀쩡했다: 손 신호 팔이 **도달 100% · 4.9 시도**로 D66(4.6)을 재현했고,
	//     가짜 보상 팔이 도달 **7%** 로 무너졌다 ⇒ **가중치가 행동을 바꾸기는 한다.**
	// ★ **기제 ① 함정 208 의 형제 — 선형 합은 「비교」를 못 담는다.**
	//   D69 에서 *"독립 곱이 관계를 원리적으로 못 담는다"* 를 밟았고, 처방은 **관계를 한 특징**
	//   **안에 인코딩하는 것**이었다(삼중). 그런데 D76 은 「지금 격자」와 「목표 격자」를 **따로**
	//   줬다 ⇒ `score[a] = Σ w[a][k]·f[k]` 는 *"지금이 목표보다 오른쪽"* 을 표현할 수 없다.
	//   합은 각 칸을 **독립으로** 더할 뿐이고, 「오른쪽에 있다」는 두 블록의 **비교**다.
	//   ⇒ ★ 처방은 D69 와 **같다**: 칸마다 **(지금 − 목표)** 를 준다. 비교가 특징 안에 있다.
	//     ⚠️ **답을 주는 것이 아니다** — 세 축이 여전히 같은 9개 수에 얽혀 있고, 「어느 축이
	//       틀렸나」도 「어느 방향인가」도 안 준다. 어느 칸이 어느 행동을 뜻하는지는 배워야 한다.
	// ★ **기제 ② 탐험이 없어 잠긴다.**
	//   여유가 0 보다 크면 **순수 탐욕**이라 무효 행동(범위 밖)을 되풀이한다. 가짜 보상 팔의
	//   도달 **7%** 가 그 증거다 — 나쁜 가중치가 고리를 **가둔다**. ⇒ ε 탐험을 **10%** 둔다.
	//   ⚠️ 이것은 학습 규칙이 아니라 **고리가 갇히지 않게 하는 것**이다.
	// ★ ⚠️ **둘을 한꺼번에 바꾸면 귀속이 안 된다** ⇒ **팔을 갈라** 각각 잰다:
	//   · 팔 2 🧠 학습(**블록 특징** = D76 그대로) + ε · 팔 3 🧠 학습(**관계 인코딩**) + ε
	//   ⇒ 팔 3 ↔ 팔 2 가 **인코딩만** 다르다(규칙·탐험·보상 전부 같다) ⇒ 함정 208 의 재발을 잰다.
	//   ⇒ ε 은 둘 다에 있으므로 confound 가 아니다.
	// ★ **미리 등록**:
	//   ㉠ 팔 3(관계 인코딩)이 전반→후반 **1.5배 이상** 싸진다 · 도달 **95%** 이상
	//   ㉡ 팔 2(블록 특징)는 개선이 **1.3배 미만** ⇒ 함정 208 의 재발이 맞았다
	//   ㉢ 팔 4(가짜 보상)는 개선이 **1.2배 미만**
	//   ★ 크기 예측: 팔 2 도달 ~85% · 전반 ~15 → 후반 ~13 │ 팔 3 도달 ~97% ·
	//     전반 **~14** → 후반 **~6~9**
	//
	// ══════ 🎨 **D78 — 색 축을 부분집단으로 확인한다**(D77 의 실측이 시킨 것) ══════
	// ✅ **관계 인코딩이 값을 했다** — 1.27배 ↔ 블록 특징 1.06배 · 후반 시도 **17.2 ↔ 25.3**.
	//   ⇒ 함정 208 의 재발이 맞았다(비교를 특징 안에 넣어야 배운다).
	// ⛔ **그런데 도달이 63%** 에 갇혔고 등록(1.5배)에 미달이다. 남은 벽을 짚는다.
	// ★ **기제 가설 — 색 축은 즉시 보상으로 배울 수 없다.**
	//   · 색 행동은 `색+1` **순환** 하나뿐이다 ⇒ 8색이면 최악 7걸음.
	//   · **D68 이 지름길을 막으려고 「색 자체」를 특징에서 뺐다**(함정 216: 막으면 숫자가
	//     내려가고 그것이 정직한 숫자다). ⇒ 그 대가가 여기서 드러난다 — 「몇 번 더 눌러야
	//     하나」가 **원리적으로 관측 불가**다(틀린 색 일곱이 특징에서 **똑같이 보인다**).
	//   · ⇒ 같은 상태에서 색+1 이 대개 「막힘」(−1), 아주 드물게 「나아짐」(+1)
	//     ⇒ **기대값이 음수** ⇒ 정책은 색을 **안 누르게** 배운다 ⇒ 색이 틀린 과제는 못 닿는다.
	// ★ **작업 규율 11번대로 부분집단을 미리 정해 두고 그 안에서도 본다** —
	//   `s0c == gc`(색이 **맞게** 시작) ↔ `s0c != gc`(**틀리게** 시작). 입력으로 정해지는
	//   부분집단이라 라벨을 안 본다.
	// ★ **미리 등록**: 색이 **맞게** 시작한 과제의 도달률이 **95% 이상**이고,
	//   **틀리게** 시작한 과제는 **70% 미만**이다 ⇒ ✅ 가설이 맞다(벽은 색 축이다).
	//   ⚠️ 둘이 비슷하면 가설이 틀린 것이고 벽은 다른 자리다(그러면 그렇게 적는다).
	//   ★ 크기 예측: 색 맞음 도달 **~97%** · 색 틀림 도달 **~58%**(전체 63.2% 와 8:1 비율에서 맞다)
	//
	// ══════ 🪜 **D79 — 신용을 뒤로 흘린다**(D78 이 벽을 짚어 준 대로) ══════
	// ✅✅ D78 이 등록 예측 97/58 을 **둘 다 맞혔다**(실측 96.8 / 57.0) ⇒ 벽은 **색 축**이다.
	// ★ **처방은 튜닝이 아니라 보상을 바꾸는 것이다** — 함정 224 의 기제가 그것을 지목한다:
	//   「나아짐」은 **즉시** 낱말이라 *지금* 좋아지는 축만 가르친다. 색+1 은 순환이라
	//   마지막 걸음 전까지 전부 「막힘」이고, 색이 특징에 없어 **몇 번 남았나가 관측 불가**다.
	//   ⇒ 필요한 것은 **「됐다」를 뒤로 흘리는 것**이다(적격성 흔적).
	//   ★ 한 문장: ***세 낱말 중 어느 것을 보상으로 쓰나가 무엇을 배울 수 있나를 정한다.***
	//
	// ★ 팔 다섯 — 0 🚪 무작위 · 1 👁️ 손 신호 · 2 🔗 **즉시 「나아짐」**(D77 의 최고 팔) ·
	//   3 🪜 **「됐다」 흔적** · 4 🎲 **가짜 흔적**(같은 갱신 · 부호 무작위 = 끊는다).
	//   ⇒ 2 ↔ 3 이 **보상만** 다르다(특징·탐험·행동·상한 전부 같다) ⇒ 귀속이 된다.
	// ★ **흔적** — 걸음마다 (특징, 행동)을 쌓고 **끝에서** 한 낱말로 흘린다:
	//   도달이면 「됐다」(+1) · 상한을 다 쓰면 (−1). 감쇠 λ = **0.95**.
	//   ⚠️ **λ 를 크게 잡은 이유**: 색 누름은 에피소드의 **이른** 걸음이라 멀리 흘려야 닿는다
	//     (0.95^20 = 0.36 · 0.9^20 = 0.12). ★ 미리 정하고 안 만진다.
	//   ⚠️⚠️ **같은 비용으로 맞춘다** — 감쇠 무게의 합을 걸음 수로 정규화한다. 안 하면 흔적 팔이
	//     즉시 팔보다 **적게** 갱신되어 불공정해진다(그러면 「흔적이 나쁘다」로 잘못 읽는다).
	//
	// ⚠️⚠️ **과제 집합을 팔의 난수와 분리한다** — 예전에는 팔 루프가 난수를 쓰는 만큼 다음
	//   과제의 뽑기가 밀렸다 ⇒ **팔을 고칠 때마다 과제가 달라져** 회귀가 성립하지 않았다
	//   (함정 213). ⇒ 이제 400개 과제를 **먼저 전부 뽑아** 둔다.
	//   ★ 그래서 이번 판은 D76~D78 과 **직접 비교가 아니다**(과제 집합이 다르다) —
	//     **한 판 안에서** 팔들을 견준다. 즉시 팔이 그 판의 기준선이다.
	//
	// ★ **미리 등록**:
	//   ㉠ **신용이 뒤로 흘렀나** — 흔적 팔의 **색 틀림** 부분집단 도달이 **90% 이상**
	//     (즉시 팔은 ~57%) ⇒ ✅ 여러 걸음 축이 열렸다
	//   ㉡ **즉시 축이 안 흐려졌나** — 흔적 팔의 **색 맞음** 도달이 **90% 이상**
	//     ⚠️ 흔적은 **쓸데없는 행동도 같이 강화**하므로 여기서 나빠질 수 있다. 그러면 그렇게 적고
	//       다음은 **둘을 합치는 것**이 된다(즉시 + 종단).
	//   ㉢ **끊으면 사라지나** — 가짜 흔적의 도달이 **40% 미만**
	//   ★ 크기 예측: 흔적 팔 색 맞음 **~93%** · 색 틀림 **~92%** · 후반 시도 **~10~14**
	//
	// ══════ 🎨 **D80 — 앨리어싱인가 선형성인가**(D79 의 실측이 시킨 것) ══════
	// ⛔⛔ **D79 는 크게 나빠졌다** — 색 틀림 65.8 → **32.6%** · 색 맞음 98.8 → **50.6%**.
	//   예측(92/93%)이 **반대 방향으로** 틀렸다. 기제는 명확하다: **종단 보상은 신용을 「그 판에서**
	//   **한 모든 행동」에 똑같이 준다** ⇒ 쓸데없는 행동까지 강화된다. 즉시 보상은 걸음마다
	//   신호가 있어 표본이 **~20배**(판 400 ↔ 걸음 ~8000)인데 종단은 판마다 하나다 ⇒ **분산이 이긴다.**
	//
	// ★ **그런데 더 깊은 것이 보인다 — 색 축은 상태가 앨리어싱됐다.**
	//   틀린 색 넷이 특징에서 **똑같이 보인다**(색을 특징에서 뺐으니까 · D68·함정 216).
	//   ⇒ `색+1` 은 **자기루프**이고, 어떤 보상 규칙(즉시·종단·TD)에서도 그 루프의 값은 음수다.
	//     ⚠️ 즉 **신용 규칙 문제가 아니라 정보가 관측에 없는 것**이다.
	//     ★ `concept.md` 의 「빈 곳 다섯」 중 **인식(epistemic)** 이다 — 관측만으로는 못 가른다.
	//
	// ★ ⇒ **팔 둘로 가른다**(둘은 **같은 특징 개수**라 비교가 공정하다):
	//   · 팔 5 🎨 **절대 색 둘**(자기 색 one-hot + 목표 색 one-hot) — **정직한 인코딩**이다
	//     (보는 것을 준다). ⚠️ 그런데 선형은 `w_i + w_j` 밖에 못 만들어 **(j−i) mod n 을 못 낸다**
	//     ⇒ 함정 223 이 **또** 온다. **정보는 있는데 못 쓰는** 자리다.
	//   · 팔 6 🔓 **색 차이 one-hot**(`(gc−cc) mod n`) — ⚠️⚠️ **이것은 답을 준 팔이다**
	//     (「몇 번 눌러야 하나」를 그대로 준다). ★ 학습이 아니라 **천장을 재는 팔**이다.
	//
	// ★ **미리 등록**:
	//   ㉠ 팔 5(절대 색): 색 틀림 도달 **65~72%**(즉시 팔과 비슷) ⇒ 선형은 상호작용을 못 만든다
	//   ㉡ 팔 6(색 차이): 색 틀림 도달 **90% 이상** ⇒ 모양만 맞으면 열린다
	//   ⇒ 그러면 결론은 하나다: **벽은 정보 부족이 아니라 선형성**이다.
	//     ★ 그리고 우회할 인코딩이 **답이 되어 버리므로 더 이상 우회할 수 없다** ⇒
	//       **곱셈적 상호작용을 가진 기계**(임베딩·어텐션)가 필요하다(📌 2번을 실측이 불러온다).
	//   ⚠️ 갈릴 수 있는 자리: 팔 5 가 열리면 **선형으로도 됐다**는 뜻이고, 그러면 벽은 앨리어싱
	//     하나였다(그러면 그렇게 적는다).
	//
	// ══════ 📐 **D81 — 벽은 「보상의 단조성」이었다**(D80 이 내 진단을 깼다) ══════
	// ⛔⛔ **D80 은 답을 줘도 안 열렸다** — 색 차이 one-hot(= 몇 번 눌러야 하나를 그대로 준 팔)의
	//   색 틀림 도달이 **66.1%** 로 즉시 팔(64.9%)과 **같았다**. ⇒ 내 진단(앨리어싱)이 **틀렸다.**
	// ★ **왜 틀렸는지가 즉시 보인다 — 특징을 줘도 보상이 여전히 처벌한다.**
	//   목표거리의 색 항은 **이진**이다(`badC ? 1 : 0`). 색 차이가 4→3 으로 줄어도 그 항은
	//   여전히 1.0 ⇒ `d` 가 안 줄고 「**막힘**」(−1)이다. ⇒ 정책이 **아무리 잘 봐도** 색+1 은
	//   벌을 받는다. **정보가 아니라 보상이 벽이었다.**
	// ★ ⇒ 이 트랙의 문장이 하나 더 선다:
	//   ***「나아짐/막힘」은 목표거리의 정의가 정하는 것이고, 그 정의가 어떤 축을 단조로***
	//   ***만드는지가 무엇을 배울 수 있는지를 정한다.*** 색은 이진이라 **단조가 아니다**.
	// ★ 팔 7 🧭 **즉시 + 색을 순환 거리로** — 색 항을 `((gc−cc) mod n) / n` 으로 바꾼다.
	//   ⚠️ **특징은 27개 그대로**(색 블록 없이)다 ⇒ 이 팔이 열리면 벽은 **정보가 아니라 보상**임이
	//     확정된다(같은 특징·같은 규칙·같은 탐험, **보상의 단조성만** 다르다).
	//   ★ 이것이 답을 주는 것인가 — **아니다.** 「색+1 로 목표 색까지 몇 칸인가」는 행동 공간이
	//     정하는 **자연한 거리**이고(색+1 하나뿐이니 방향 선택도 없다), 어느 축을 언제 고칠지는
	//     여전히 배워야 한다. ⚠️ 그러나 정직하게 적을 것: 이것은 **세계의 거리 정의를 고친 것**이다.
	//   ★ 미리 등록: 팔 7 의 **색 틀림 도달 95% 이상** · 후반 시도 **~6~9**
	//     ⇒ ✅ 벽은 보상의 단조성이었다. ⚠️ 안 열리면 벽이 더 근본적인 자리다(그러면 그렇게 적는다).
	//
	// ══════ 🔀 **D82 — 둘이 동시에 필요했나**(D81 이 또 내 진단을 깼다) ══════
	// ⛔⛔⛔ **D81 은 오히려 붕괴했다** — 색 틀림 62.1 → **32.6%**. 그런데 **결정적 단서**가 있다:
	//   색이 **맞게** 시작한 과제도 98.8 → **43.2%** 로 무너졌다. 색이 맞으면 순환 거리도 0 이라
	//   즉시 팔과 **똑같아야** 하는데 그렇지 않았다 ⇒ 원인은 **배운 가중치**다.
	// ★ **기제 — 편향이 「색+1 은 대체로 좋다」를 배우고, 맞은 상태에서도 누른다.**
	//   순환 거리로 바꾸자 색+1 이 과제마다 4번씩 보상받는다(과제의 80%가 색 틀림이다).
	//   ⇒ `b[색+1]` 이 크게 양수가 된다. 색이 맞으면 `f[0..8] ≈ 0` 이라 그 항이 **사라지고**
	//     점수는 편향으로 떨어진다 ⇒ **그래도 누른다** ⇒ 맞춰 놓은 색을 깬다.
	//   ★ 그것이 **게이팅이 필요한 자리**다: 「이 축은 됐다 ⇒ 끈다」는 **0 을 곱하는 것**이고,
	//     선형 합은 **더할 수만** 있다. `f ≈ 0` 은 「없음」이지 「끄기」가 아니다.
	// ★ ⇒ 그러면 **둘이 동시에** 필요하다는 가설이 선다:
	//   ① **보상이 그 축에서 단조**여야 한다(안 그러면 배울 신호가 없다) — D81 이 준 것
	//   ② 정책이 「그 축은 됐다」를 **끌 수** 있어야 한다 — D80 의 색 차이 특징이 준 것
	//     (차이 0 칸에 음수 가중치를 실으면 **끌 수 있다** — 실제로 D80 은 색 맞음 96.3% 를 지켰다)
	//   ⇒ D80 은 ②만, D81 은 ①만 줬다. **각각으로는 둘 다 실패했다.**
	// ★ 팔 8 🔀 **순환 거리 보상 + 색 차이 특징** — 둘을 같이 준다.
	//   ⚠️⚠️ **이 팔은 「배웠다」의 증거가 아니다** — 색 차이는 답이므로 **천장**이다.
	//     재는 것은 하나다: ***무엇이 동시에 있어야 이 축이 열리는가.***
	//   ★ 미리 등록: 색 틀림 **95% 이상** **그리고** 색 맞음 **95% 이상**
	//     ⇒ ✅ 둘이 동시에 필요했다(그리고 그것이 **게이팅이 필요하다**의 실측 근거다).
	//     ⚠️ 안 열리면 벽은 **선형 정책 자체**다(그러면 그렇게 적고 학습기를 바꾼다).
	// ══════════════════════════════════════════════════════════════════
	static constexpr int kCN = 8;                   // 색 one-hot 칸(색 수 상한 · 지금 5)
	static constexpr int kLF = 27 + kCN * 2;       // 격자 셋 + **색 블록 둘**(D80)
	static constexpr int kLA = 5;                  // 행동: 색+1 · 자리∓1 · 크기∓1
	// 🎲 **행동 배열 상한**(D106) — 「경우의 수」 축을 위해 **쓸모없는 행동**(no-op)을
	//   더한다. ★ 무작위는 `~1/A` 로 **정확히 비례해** 죽고 **깊이·관측 구별력은 안 변한다**
	//   ⇒ 축이 **하나만** 움직인다(함정 272 를 안 밟는다).
	//   ⚠️ 활성 개수는 `nAct` 변수다 — 이 상수는 **배열 크기**일 뿐이고 옛 회차는 `kLA` 를 쓴다.
	static constexpr int kLAX = 17;                // 5 · 9 · 13 · 17
	// 🧠 **선형 정책** — 표가 아니라 가중치다. ⚠️ 은닉층이 없다(그것은 다음 칸이다).
	struct LPol
	{
		double w[kLA][kLF] = {};
		double b[kLA] = {};
		MLChoice Score(const double* f, int nf) const
		{
			double s[kLA] = {}; double lo = 0.0;
			for (int a = 0; a < kLA; ++a)
			{
				s[a] = b[a];
				for (int k = 0; k < nf; ++k) s[a] += w[a][k] * f[k];
				if (a == 0 || s[a] < lo) lo = s[a];
			}
			// ⚠️ **지수(softmax)를 안 쓴다** — `MLChoice` 의 규약이다(온도 손잡이가 생긴다).
			//   ★ 최소값을 0 으로 옮긴다: 단조라 argmax 가 보존되고, 전부 같으면 **여유 0** 이
			//     되어 「모름」이 그대로 읽힌다 ⇒ 그때는 탐험한다.
			MLChoice ch; ch.Reset(kLA);
			for (int a = 0; a < kLA; ++a) ch.Set(a, s[a] - lo + 1e-9);
			ch.Normalize();
			return ch;
		}
		// 🗣️ **낱말로 배운다** — `sign` = +1(나아짐) / −1(막힘).
		void Learn(const double* f, int a, double sign, double lr, int nf)
		{
			for (int k = 0; k < nf; ++k) w[a][k] += lr * sign * f[k];
			b[a] += lr * sign;
		}
	};

	// 🔗 **특징 — 관계 인코딩**(D77 · 함정 223 의 처방). 칸마다 **(지금 − 목표)** 를 준다.
	//   ⚠️ D76 은 절대값 블록을 따로 줬고 **1.06배**밖에 안 나왔다(선형 합은 비교를 못 담는다).
	//     그 팔은 D77 이 재고 기록했으므로 여기서는 **남기지 않는다**.
	static void _LFeat(const uint8* q0, const uint8* q1, const uint8* g9, double* f)
	{
		for (int k = 0; k < 9; ++k)
		{
			// ★ 색이 틀리면 `q0` 이 전부 0 이라 이 블록이 **크게 음수**가 된다
			//   ⇒ 「색이 틀렸다」가 선형으로 읽힌다.
			f[k] = ((double)q0[k] - (double)g9[k]) / 3.0;
			// ★ 자기 색 기준의 차 — **색이 틀려도** 자리·크기 관계가 남는다.
			f[9 + k] = ((double)q1[k] - (double)g9[k]) / 3.0;
			f[18 + k] = (double)g9[k] / 3.0;         // 목표(절대) — 「어디로」의 바탕
		}
	}

	// 🪜 **적격성 흔적**(D79) — 걸음마다 (특징, 행동)을 쌓아 두고 **끝에서** 신용을 흘린다.
	//   ★ 이것이 「즉시 나아짐」과 「나아질 수 있는 상태」를 가르는 자리다.
	static constexpr int kTr = 64;                 // 흔적 길이 상한(= 시도 상한)
	struct LTrace
	{
		double f[kTr][kLF] = {};
		int a[kTr] = {};
		int n = 0;
		void Reset() { n = 0; }
		void Push(const double* ff, int aa)
		{
			if (n >= kTr) return;
			for (int k = 0; k < kLF; ++k) f[n][k] = ff[k];
			a[n] = aa; n++;
		}
		// 🗣️ 끝에서 **한 낱말**로 흘린다 — 「됐다」면 +1, 상한을 다 썼으면 −1.
		void Flush(LPol& p, double sign, double lam, double lr, int nf)
		{
			if (n == 0) return;
			// ⚠️ **같은 비용** — 감쇠 무게의 합을 걸음 수로 정규화한다(안 하면 적게 갱신된다).
			double s = 0.0, w = 1.0;
			for (int t = 0; t < n; ++t) { s += w; w *= lam; }
			const double g = (s > 0.0) ? ((double)n / s) : 1.0;
			w = 1.0;
			// ★ **최근 걸음이 더 큰 신용**을 받는다(뒤에서 앞으로 감쇠).
			for (int t = n - 1; t >= 0; --t)
				{ p.Learn(f[t], a[t], sign * g * w, lr, nf); w *= lam; }
		}
	};

	void _RunLearn()
	{
		const int cell = MLEpisodeGen::kSize;
		const uint64 plane = (uint64)cell * (uint64)cell;
		// 🚪 팔 다섯(D77) — 0 무작위 · 1 손 신호 · 2 학습(블록) · 3 학습(관계) · 4 가짜 보상.
		// 🚪 팔 일곱(D80) — 0 무작위 · 1 손 신호 · 2 즉시 · 3 흔적 · 4 가짜 흔적 ·
		//   5 즉시+**절대 색**(정직) · 6 즉시+**색 차이**(⚠️ 답 · 천장 측정용).
		//   7 즉시+**색을 순환 거리로**(보상의 단조성만 다르다 · D81).
		//   8 **순환 거리 보상 + 색 차이 특징**(둘을 같이 · D82 · 천장 측정용).
		const int kTask = 400, kCap = 60, kArm = 9;
		const int kEps = 10;                       // 🎲 ε 탐험(%) — 고리가 갇히지 않게
		const double lam = 0.95;                   // 🪜 흔적 감쇠 — 미리 정하고 안 만진다
		const double lr = 0.05;
		LogA("[ml] ── 🧠 **D76 · 고리 위에 학습을 얹는다** — 탐색을 학습으로 ──────────────\n"
			"[ml]   ★ **보상이 곧 낱말이다** — 시도 뒤에 목표거리가 줄면 「나아짐」(+) 아니면"
			" 「막힘」(−). D58~D71 의 심볼이 **새 능력의 학습 신호**로 쓰인다\n"
			"[ml]   ★ **표가 아니라 가중치**다 — 함정 220 이 표의 천장을 쟀다(좌표는 곱셈 중복 ·"
			" 분할은 표본 쪼갬). 가중치는 **모든 상태가 공유**한다\n"
			"[ml]   ★ 행동 **%d개**(색+1 · 자리∓1 · 크기∓1) · 특징 **%d개**(격자 셋) ·"
			" 과제 **%d개** · 시도 상한 %d · 학습률 %.2f\n"
			"[ml]   ⚠️⚠️ **축별 오차를 학습 팔에 주지 않는다**(함정 154) — 받는 것은 시도 **뒤의"
			" 한 비트**뿐이다. 손 신호 팔이 읽는 세 수는 한 번도 안 들어간다\n"
			"[ml]   ★ ***세 낱말 중 어느 것을 보상으로 쓰나가 무엇을 배울 수 있나를 정한다.***"
			" 「나아짐」은 **즉시** 축만 · 「됐다」를 흔적으로 흘리면 **여러 걸음** 축이 열린다\n"
			"[ml]   ★ 미리 등록: ㉠ 흔적 팔의 **색 틀림** 도달 **90%%** 이상(즉시 팔은 ~57%%) ·"
			" ㉡ **색 맞음**도 **90%%** 이상(흐려지지 않았나) · ㉢ 가짜 흔적 도달 **40%% 미만**\n"
			"[ml]   ★ 크기 예측: 흔적 팔 색 맞음 **~93%%** · 색 틀림 **~92%%** · 후반 시도 **~10~14**"
			" · 흔적 감쇠 λ = %.2f(미리 정하고 안 만진다)\n",
			kLA, kLF, kTask, kCap, lr, lam);
		SeedRand(MLEpisodeGen::ScrambleSeed(76000u));
		// ⚠️⚠️ **과제 집합을 팔의 난수와 분리한다**(함정 213) — 팔을 고쳐도 과제가 안 바뀐다.
		Array<int> tq;
		tq.Reset(0);
		for (int q = 0; q < kTask; ++q)
		{
			tq.Add(RandInt(0, MLEpisodeGen::PaletteCount()));
			tq.Add(RandInt(0, 3)); tq.Add(RandInt(0, 3));
			tq.Add(RandInt(0, MLEpisodeGen::PaletteCount()));
			tq.Add(RandInt(0, 3)); tq.Add(RandInt(0, 3));
		}
		LPol pol[kArm];
		LTrace tr;                                 // 🪜 흔적(재사용 — 스택이 크다)
		int hitN[kArm] = {}, taskN[kArm] = {};
		double trH[kArm][2] = {}; int hitH[kArm][2] = {};
		// 🎨 **부분집단**(D78) — `[arm][색이 맞게 시작했나]`. 입력으로 정해지므로 라벨을 안 본다.
		int hitC[kArm][2] = {}, taskC[kArm][2] = {};
		double trC[kArm][2] = {};
		const int nc = MLEpisodeGen::PaletteCount();
		for (int q = 0; q < kTask; ++q)
		{
			const int gc = tq.Data()[q * 6 + 0] % nc, gx = tq.Data()[q * 6 + 1], gs = tq.Data()[q * 6 + 2];
			// 🎯 목표를 실행한다 — **프레임만** 본다.
			uint8 gv = 0; int64 gcx = 0; uint64 gink = 0; uint8 g9[9] = {};
			{
				DrawProgram gp;
				// 📎 `TaskCode(...)` 의 결과를 **지역 변수로 받는다** — 가독성 때문이다.
				//   ⚠️⚠️ **주석을 정정한다**(2026-08-24): 처음에 이것을 「크래시 가설」로 적었는데
				//   **반증됐다** — ㉠ 실측: 수명을 늘려도 죽었다 ㉡ 원리: `ScriptRunner::Compile` 은
				//   `source` 를 `CompileSource` 에 넘기고 **보관하지 않는다**(`_program` 에 컴파일
				//   결과만 저장한다 · Engine/Script/ScriptRunner.cpp:32) ⇒ **원래 코드도 안전했다.**
				//   ★ 되돌리지 않고 남기는 이유는 **지역 변수가 더 명확해서**이고 그것뿐이다.
				const String src2 = MLEpisodeGen::TaskCode(gc, gx, gs);
				if (!gp.Compile(src2.View(),
					(uint32)cell, (uint32)cell, NameID("LrnG"))) continue;
				if (!gp.RunStart()) continue;
				Bytes gb; gb.Reset(plane);
				if (!ImageFormat::PackRGB332Delta(gp.canvas, nullptr, (uint8*)gb.GetData(), plane))
					continue;
				const uint8* p = (const uint8*)gb.GetData();
				const uint8 bg = _BgByte(p, plane);
				Blob bl[8]; const int n = _Blobs(p, cell, bg, bl, 8);
				if (n != 1) continue;
				gv = bl[0].v; gcx = bl[0].cx16; gink = bl[0].ink;
				_Grid9v(p, cell, gv, g9, nullptr);
			}
			// 🚪 네 팔이 **같은 시작 상태**에서 출발한다(같은 비용 · 함정 135).
			const int s0c = tq.Data()[q * 6 + 3] % nc, s0x = tq.Data()[q * 6 + 4], s0s = tq.Data()[q * 6 + 5];
			const int half = (q < kTask / 2) ? 0 : 1;
			const int cok = (s0c == gc) ? 1 : 0;      // 🎨 색이 맞게 시작했나
			for (int arm = 0; arm < kArm; ++arm)
			{
				int cc = s0c, cx = s0x, cs = s0s;
				bool hit = false; int tries = 0;
				double pf[kLF] = {}; int pa = -1; double pd = 0.0;
				tr.Reset();
				for (; tries < kCap; ++tries)
				{
					// 🖐️ **시도** — 지금 고른 것을 실제로 실행한다.
					DrawProgram pr;
					// 📎 `TaskCode(...)` 의 결과를 **지역 변수로 받는다** — 가독성 때문이다.
					//   ⚠️⚠️ **주석을 정정한다**(2026-08-24): 처음에 이것을 「크래시 가설」로 적었는데
					//   **반증됐다** — ㉠ 실측: 수명을 늘려도 죽었다 ㉡ 원리: `ScriptRunner::Compile` 은
					//   `source` 를 `CompileSource` 에 넘기고 **보관하지 않는다**(`_program` 에 컴파일
					//   결과만 저장한다 · Engine/Script/ScriptRunner.cpp:32) ⇒ **원래 코드도 안전했다.**
					//   ★ 되돌리지 않고 남기는 이유는 **지역 변수가 더 명확해서**이고 그것뿐이다.
					const String src3 = MLEpisodeGen::TaskCode(cc, cx, cs);
					if (!pr.Compile(src3.View(),
						(uint32)cell, (uint32)cell, NameID("Lrn"))) break;
					if (!pr.RunStart()) break;
					Bytes b; b.Reset(plane);
					if (!ImageFormat::PackRGB332Delta(pr.canvas, nullptr, (uint8*)b.GetData(), plane))
						break;
					const uint8* p = (const uint8*)b.GetData();
					const uint8 bg = _BgByte(p, plane);
					Blob bl[8]; const int n = _Blobs(p, cell, bg, bl, 8);
					if (n != 1) break;
					// 👁️ **비전 지표 셋** — D66 과 **같은 수**다(색 · 중심 x · 잉크량).
					const bool badC = (bl[0].v != gv);
					const int64 dx16 = (bl[0].cx16 > gcx) ? (bl[0].cx16 - gcx) : (gcx - bl[0].cx16);
					const uint64 hi = (bl[0].ink > gink) ? bl[0].ink : gink;
					const uint64 loI = (bl[0].ink > gink) ? gink : bl[0].ink;
					// ✅ **도달** — 셋이 다 0 이다(부동소수로 견주지 않는다).
					if (!badC && dx16 == 0 && bl[0].ink == gink) { hit = true; break; }
					// 🗣️ **목표거리** — 그 셋의 합. ⚠️ 학습 팔은 이 값을 **못 본다**(부호만 받는다).
					const double eX = (double)dx16 / (double)((int64)cell * 16);
					const double eS = (hi > 0u) ? ((double)(hi - loI) / (double)hi) : 0.0;
					// 🧭 **색 항의 두 정의**(D81) — 이진이냐 **순환 거리**냐.
					//   ★ 이진이면 색+1 이 목표 쪽으로 가도 `d` 가 안 줄어 「막힘」이다(단조가 아니다).
					const double eC = badC ? 1.0 : 0.0;
					const double eCcyc = (double)((gc - cc + nc) % nc) / (double)nc;
					const double d = ((arm == 7 || arm == 8) ? eCcyc : eC) + eX + eS;
					// 🧮 특징 — 격자 셋. ★ 지금 장을 **목표 색**으로도, **자기 색**으로도 센다.
					double f[kLF] = {};
					{
						uint8 q0[9] = {}, q1[9] = {};
						_Grid9v(p, cell, gv, q0, nullptr);
						_Grid9v(p, cell, bl[0].v, q1, nullptr);
						_LFeat(q0, q1, g9, f);
						// 🎨 **색 블록**(D80) — 팔 5·6 만 쓴다(나머지는 0 이고 `nf` 로 잘린다).
						if (arm == 5)
						{
							f[27 + cc] = 1.0;                     // 자기 색(보는 것)
							f[27 + kCN + gc] = 1.0;               // 목표 색(보는 것)
						}
						else if (arm == 6 || arm == 8)
							// ⚠️⚠️ **답이다** — 「몇 번 눌러야 하나」를 그대로 준다(천장 측정용).
							f[27 + ((gc - cc + nc) % nc)] = 1.0;
					}
					// 🗣️ **낱말로 배운다**(둘째 시도부터) — 직전 행동이 나아짐이었나 막힘이었나.
					// 🗣️ **즉시 낱말로 배운다**(팔 2 만) — 직전 행동이 나아짐이었나 막힘이었나.
					// 🎨 색 블록은 팔 5·6 만 쓴다 — 팔 7 은 **27개 그대로**다(보상만 다르다).
					const int nf = (arm == 5 || arm == 6 || arm == 8) ? kLF : 27;
					if ((arm == 2 || arm >= 5) && pa >= 0)          // 즉시 보상 팔들
						pol[arm].Learn(pf, pa, (d < pd) ? 1.0 : -1.0, lr, nf);
					// 🚪 **행동을 고른다.**
					int a = 0;
					if (arm == 0) a = RandInt(0, kLA);           // 대조군
					else if (arm == 1)
					{
						// 👁️ 손 신호 — D66 의 정책 그대로(색이 틀리면 색 · 아니면 큰 오차의 축).
						if (badC) a = 0;
						else if (eX >= eS) a = (bl[0].cx16 > gcx) ? 1 : 2;
						else a = (bl[0].ink > gink) ? 3 : 4;
					}
					else
					{
						// 🚪 분포를 받아 **여기서만** 굳힌다(세계 경계). 여유가 0 이면 **모름** ⇒ 탐험.
						// 🎲 **ε 탐험** — 나쁜 가중치가 고리를 가두지 않게(D76 실측: 탐험 없이 도달 7%).
						const MLChoice ch = pol[arm].Score(f, nf);
						a = (RandInt(0, 100) < kEps || ch.Margin() <= 0.0)
							? RandInt(0, kLA) : ch.Argmax();
					}
					// 🔁 **고친다.** ⚠️ 범위 밖은 아무 일도 안 한다 ⇒ 세계가 「막힘」을 준다.
					if (a == 0) cc = (cc + 1) % nc;
					else if (a == 1) { if (cx > 0) cx--; }
					else if (a == 2) { if (cx < 2) cx++; }
					else if (a == 3) { if (cs > 0) cs--; }
					else             { if (cs < 2) cs++; }
					// 🪜 **흔적에 쌓는다**(팔 3·4) — 신용은 **끝에서** 흘린다.
					if (arm == 3 || arm == 4) tr.Push(f, a);
					for (int k = 0; k < kLF; ++k) pf[k] = f[k];
					pa = a; pd = d;
				}
				// 🪜 **끝에서 한 낱말로 흘린다** — 「됐다」(+1) / 상한을 다 썼다(−1).
				if (arm == 3 || arm == 4)
				{
					// 🎲 **끊는다** — 갱신 총량은 같고 **부호만 뜻이 없다**(같은 비용).
					const double sg = (arm == 4)
						? ((RandInt(0, 2) == 0) ? 1.0 : -1.0) : (hit ? 1.0 : -1.0);
					tr.Flush(pol[arm], sg, lam, lr, 27);
				}
				taskN[arm]++;
				taskC[arm][cok]++;
				if (hit)
				{
					hitN[arm]++;
					hitH[arm][half]++; trH[arm][half] += (double)(tries + 1);
					hitC[arm][cok]++; trC[arm][cok] += (double)(tries + 1);
				}
			}
		}
		if (taskN[3] == 0) { LogA("[ml]   🧠 ⚠️ **판정불가**\n"); return; }
		double rc[kArm] = {}, h0[kArm] = {}, h1[kArm] = {}, gain[kArm] = {};
		for (int a = 0; a < kArm; ++a)
		{
			rc[a] = 100.0 * (double)hitN[a] / (double)taskN[a];
			h0[a] = (hitH[a][0] > 0) ? (trH[a][0] / (double)hitH[a][0]) : 0.0;
			h1[a] = (hitH[a][1] > 0) ? (trH[a][1] / (double)hitH[a][1]) : 0.0;
			gain[a] = (h1[a] > 0.0) ? (h0[a] / h1[a]) : 0.0;
		}
		LogA("[ml]      🚪 무작위(5행동)        — 도달 **%.1f%%** · 전반 **%.1f** → 후반 **%.1f**(%.2f배)\n"
			"[ml]      👁️ 손 신호(D66 정책)     — 도달 **%.1f%%** · 전반 **%.1f** → 후반 **%.1f**(%.2f배)\n"
			"[ml]      🔗 즉시 「나아짐」        — 도달 **%.1f%%** · 전반 **%.1f** → 후반 **%.1f**(%.2f배)  ⇐ D77 의 최고 팔\n"
			"[ml]      🪜 **「됐다」 흔적**       — 도달 **%.1f%%** · 전반 **%.1f** → 후반 **%.1f**(**%.2f배**)  ⇐ 신용을 뒤로\n"
			"[ml]      🎲 가짜 흔적(끊는다)      — 도달 **%.1f%%** · 전반 **%.1f** → 후반 **%.1f**(%.2f배)\n",
			rc[0], h0[0], h1[0], gain[0], rc[1], h0[1], h1[1], gain[1],
			rc[2], h0[2], h1[2], gain[2], rc[3], h0[3], h1[3], gain[3],
			rc[4], h0[4], h1[4], gain[4]);
		LogA("[ml]      🎨 즉시 + **절대 색 둘**   — 도달 **%.1f%%** · 전반 **%.1f** → 후반 **%.1f**(%.2f배)  ⇐ 정직한 인코딩\n"
			"[ml]      🔓 즉시 + 색 차이(**답**)   — 도달 **%.1f%%** · 전반 **%.1f** → 후반 **%.1f**(%.2f배)  ⇐ **천장 측정용**\n",
			rc[5], h0[5], h1[5], gain[5], rc[6], h0[6], h1[6], gain[6]);
		LogA("[ml]      🧭 즉시 + **순환 거리**    — 도달 **%.1f%%** · 전반 **%.1f** → 후반 **%.1f**(%.2f배)  ⇐ 특징 27개 · **보상만** 다르다\n",
			rc[7], h0[7], h1[7], gain[7]);
		LogA("[ml]      🔀 **순환 거리 + 색 차이** — 도달 **%.1f%%** · 전반 **%.1f** → 후반 **%.1f**(%.2f배)  ⇐ 둘을 같이(**천장**)\n",
			rc[8], h0[8], h1[8], gain[8]);
		// 🎨 **부분집단 — 색이 맞게 시작했나**(D78). ★ 여러 걸음 축이 열렸는지 여기서 갈린다.
		//   ⚠️ **도달률로 본다** — 「닿은 것의 평균 시도」는 도달률이 100% 가 아니면 편향이다(함정 222).
		double cr[kArm][2] = {}, ct[kArm][2] = {};
		for (int a = 0; a < kArm; ++a)
			for (int c = 0; c < 2; ++c)
			{
				cr[a][c] = (taskC[a][c] > 0)
					? (100.0 * (double)hitC[a][c] / (double)taskC[a][c]) : 0.0;
				ct[a][c] = (hitC[a][c] > 0) ? (trC[a][c] / (double)hitC[a][c]) : 0.0;
			}
		LogA("[ml]      ── 🎨 **부분집단: 색이 맞게 시작했나**(과제 %d ↔ %d)\n"
			"[ml]         👁️ 손 신호        — 맞음 **%.1f%%**(%.1f 시도) │ 틀림 **%.1f%%**(%.1f)\n"
			"[ml]         🔗 즉시 「나아짐」 — 맞음 **%.1f%%**(%.1f 시도) │ 틀림 **%.1f%%**(%.1f)\n"
			"[ml]         🪜 **「됐다」 흔적** — 맞음 **%.1f%%**(%.1f 시도) │ 틀림 **%.1f%%**(%.1f)\n"
			"[ml]         🎲 가짜 흔적      — 맞음 **%.1f%%**(%.1f 시도) │ 틀림 **%.1f%%**(%.1f)\n",
			taskC[3][1], taskC[3][0],
			cr[1][1], ct[1][1], cr[1][0], ct[1][0],
			cr[2][1], ct[2][1], cr[2][0], ct[2][0],
			cr[3][1], ct[3][1], cr[3][0], ct[3][0],
			cr[4][1], ct[4][1], cr[4][0], ct[4][0]);
		LogA("[ml]         🎨 절대 색 둘      — 맞음 **%.1f%%**(%.1f 시도) │ 틀림 **%.1f%%**(%.1f)\n"
			"[ml]         🔓 색 차이(**답**)   — 맞음 **%.1f%%**(%.1f 시도) │ 틀림 **%.1f%%**(%.1f)\n",
			cr[5][1], ct[5][1], cr[5][0], ct[5][0],
			cr[6][1], ct[6][1], cr[6][0], ct[6][0]);
		LogA("[ml]         🧭 **순환 거리**     — 맞음 **%.1f%%**(%.1f 시도) │ 틀림 **%.1f%%**(%.1f)\n",
			cr[7][1], ct[7][1], cr[7][0], ct[7][0]);
		LogA("[ml]         🔀 **둘을 같이**     — 맞음 **%.1f%%**(%.1f 시도) │ 틀림 **%.1f%%**(%.1f)\n",
			cr[8][1], ct[8][1], cr[8][0], ct[8][0]);
		const bool back = (cr[3][0] >= 90.0);      // 여러 걸음 축이 열렸나
		const bool keep = (cr[3][1] >= 90.0);      // 즉시 축이 안 흐려졌나
		const bool cut = (rc[4] < 40.0);           // 끊으면 사라지나
		LogA("[ml]      ㉠ **신용이 뒤로 흘렀나** — 색 틀림 도달: 즉시 %.1f%% → 흔적 **%.1f%%**(**%+.1f%%p**) ⇒ %s\n"
			"[ml]      ㉡ **즉시 축이 안 흐려졌나** — 색 맞음 도달: 즉시 %.1f%% → 흔적 **%.1f%%**(%+.1f%%p) ⇒ %s\n"
			"[ml]      ㉢ **끊으면 사라지나** — 가짜 흔적 도달 **%.1f%%** ⇒ %s\n"
			"[ml]      📏 **어디까지 왔나** — 흔적 팔 후반 **%.1f** 시도 ↔ 손 신호 %.1f ↔"
			" 무작위 %.1f ⇒ 손 신호까지 **%.2f배** 남았다\n"
			"[ml]      ⇒ %s\n",
			cr[2][0], cr[3][0], cr[3][0] - cr[2][0],
			back ? "✅✅ **흘렀다** — 「됐다」를 뒤로 흘리자 **여러 걸음 축**이 열렸다"
				: ((cr[3][0] - cr[2][0] >= 10.0)
					? "⚠️ **올랐는데 90%p 에 못 닿았다** — 방향은 맞다"
					: "⛔ **안 흘렀다** — 종단 보상만으로는 색 축이 안 열린다"),
			cr[2][1], cr[3][1], cr[3][1] - cr[2][1],
			keep ? "✅ **안 흐려졌다**"
				: "⛔ **흐려졌다** — 흔적이 쓸데없는 행동도 같이 강화한다 ⇒ 다음은 **둘을 합치는 것**이다",
			rc[4],
			cut ? "✅ **끊으면 사라진다** — 값을 한 것은 **낱말**이다"
				: "⛔ **가짜 흔적도 닿는다** — 좋아진 것이 낱말 때문이 아니다",
			h1[3], h1[1], h1[0], (h1[1] > 0.0) ? (h1[3] / h1[1]) : 0.0,
			(back && keep && cut)
				? "✅✅✅ ***신용이 뒤로 흘렀다*** — 「됐다」가 **당장 좋아지지 않는 선행 행동**을"
				  " 가르쳤다. ⇒ **깊이 2 의 첫 칸이 섰다**"
				: ((back && !keep)
					? "⚠️ **여러 걸음 축은 열렸는데 즉시 축이 흐려졌다** — 다음은 둘을 합치는 것이다"
					: "⛔ **아직 안 섰다** — 어느 판정이 미달인지 보고 그것부터 고친다"));
		// 🎨 **㉣ 앨리어싱인가 선형성인가**(D80) — 둘은 **같은 특징 개수**라 공정하다.
		const bool abs5 = (cr[5][0] >= 90.0);      // 절대 색만으로 열리나
		const bool top6 = (cr[6][0] >= 90.0);      // 답을 주면 열리나(천장)
		LogA("[ml]      ㉣ **정보가 없나 · 선형이 못 쓰나** — 색 틀림 도달:"
			" 즉시 %.1f%% │ **절대 색 %.1f%%** │ 색 차이(답) **%.1f%%**\n"
			"[ml]      ⇒ %s\n",
			cr[2][0], cr[5][0], cr[6][0],
			(top6 && !abs5)
				? "✅✅✅ ***벽은 정보 부족이 아니라 선형성이다*** — 같은 정보를 **모양만** 바꿔"
				  " 주면 열린다. ⚠️ 그런데 그 모양이 **답**이라 우회로 쓸 수 없다 ⇒ **곱셈적"
				  " 상호작용을 가진 기계**(임베딩·어텐션)가 필요하다"
				: (abs5
					? "✅ **절대 색만으로도 열린다** — 벽은 앨리어싱 하나였다(선형으로 충분하다)"
					: "⛔ **답을 줘도 안 열린다** — 벽이 색 축이 아니거나 정책이 더 근본적으로 모자라다"));
		// 📐 **㉤ 벽은 보상의 단조성인가**(D81) — 같은 특징(27개) · **보상만** 다르다.
		const bool mono = (cr[7][0] >= 95.0);
		LogA("[ml]      ㉤ **벽이 보상의 단조성인가** — 색 틀림 도달: 이진 %.1f%% →"
			" **순환 거리 %.1f%%**(**%+.1f%%p**) · 후반 시도 %.1f ↔ 손 신호 %.1f ⇒ %s\n",
			cr[2][0], cr[7][0], cr[7][0] - cr[2][0], h1[7], h1[1],
			mono
				? "✅✅✅ ***벽은 보상의 단조성이었다*** — 특징도 정보도 그대로인데 **거리의 정의**만"
				  " 고치자 열렸다. ⇒ 「나아짐/막힘」이 **무엇을 배울 수 있나**를 정한다"
				: ((cr[7][0] - cr[2][0] >= 15.0)
					? "⚠️ **크게 올랐는데 95% 에 못 닿았다** — 단조성이 큰 몫이지만 전부는 아니다"
					: "⛔ **안 열린다** — 벽이 더 근본적인 자리다(정책의 표현력 자체를 봐야 한다)"));
		// 🔀 **㉥ 둘이 동시에 필요했나**(D82) — 하나만 주면 둘 다 실패했다.
		const bool both = (cr[8][0] >= 95.0 && cr[8][1] >= 95.0);
		LogA("[ml]      ㉥ **둘이 동시에 필요했나** — 색 틀림 도달: 아무것도 %.1f%% │"
			" 특징만 %.1f%% │ 보상만 %.1f%% │ **둘 다 %.1f%%**(색 맞음 %.1f%%)\n"
			"[ml]      ⇒ %s\n",
			cr[2][0], cr[6][0], cr[7][0], cr[8][0], cr[8][1],
			both
				? "✅✅✅ ***둘이 동시에 필요했다*** — ① 보상이 그 축에서 **단조**여야 배울 신호가"
				  " 생기고 ② 정책이 「그 축은 됐다」를 **끌 수** 있어야 한다. ⇒ ②는 **0 을 곱하는**"
				  " 것이고 선형 합은 **더할 수만** 있다 ⇒ ***게이팅(곱셈적 상호작용)이 필요하다***"
				: ((cr[8][0] >= 95.0)
					? "⚠️ **색 틀림은 열렸는데 색 맞음이 무너진다** — 끄는 힘이 아직 모자라다"
					: "⛔ **둘을 같이 줘도 안 열린다** — 벽은 **선형 정책 자체**다(학습기를 바꿔야 한다)"));
	}

	// ══════════════════════════════════════════════════════════════════
	// 🔀 **D83 · 게이팅(라우팅) + 지속** — 📌 1번. **판정은 성능이 아니라 간섭이다.**
	//
	// ★ **왜 이것인가 — 세 천장이 이름을 갖고 섰다**:
	//   · 셈 표는 심볼을 놓을 자리가 없다(함정 220) · 선형 합은 **비교**를 못 담고(함정 223 ·
	//     인코딩으로 우회했다) **끄기**를 못 담는다(함정 225 · **우회로가 없다**).
	//   · 그리고 D81 의 붕괴(색 맞음 98.8 → **34.6%**)는 **적응 B가 적응 A를 덮은 것**이다 —
	//     「끄기를 못 담는다」와 「간섭」은 **같은 현상의 두 이름**이고 원인은 하나다:
	//     ***적응에 주소가 없다.***
	//
	// ★ **설계의 핵심 한 줄 — 게이트의 질의에 하나, 특징에 다른 하나를 두면 곱이 생긴다.**
	//   D80 은 자기 색·목표 색 one-hot 을 **둘 다 특징으로** 줬다 ⇒ 선형은 `w_i + w_j` 밖에
	//   못 만들어 `(j−i) mod n` 을 못 냈다(63.9% · 안 움직였다).
	//   ⇒ 여기서는 **자기 색을 문맥(질의)** 에, **목표 색을 특징**에 둔다. 그러면 점수에
	//     `g(자기색) × w(목표색)` 이 생긴다 — **그것이 곱이고, 어텐션이 하는 일과 같은 모양**이다.
	//   ⚠️ **답을 주는 것이 아니다** — 어느 것도 「몇 번 눌러야 하나」가 아니고, 그 곱을 어디에
	//     쓸지는 배워야 한다. ★ D80 과 **같은 정보 · 같은 특징 수**이고 **모양만** 다르다.
	//
	// ★ **특징 묶음 넷**(`kGF` = 35) · 게이트가 묶음마다 무게를 준다:
	//   0: `f[0..8]`  목표 색으로 센 (지금 − 목표) · 1: `f[9..17]` 자기 색으로 센 (지금 − 목표)
	//   2: `f[18..26]` 목표(절대) · 3: `f[27..34]` **목표 색 one-hot**
	// ★ **문맥(질의)** `kGC` = 14 — 지속 흔적 5 + **자기 색 one-hot 8** + 편향 1.
	//
	// ★ **지속 상태 = 행동마다 최근 결과의 감쇠 흔적**(5개).
	//   ⚠️ **이름이 없다** — 코어는 그것이 「의심」인지 「피로」인지 모른다(concept.md 의 그 요구).
	//   ★ 자기상태 네 조건을 다 만족한다: **내생적**(결과에서 온다) · **지속**(감쇠하며 남는다) ·
	//     **기능적 결과**(게이트를 통해 행동을 바꾼다) · **닫힘**(행동→결과→흔적→행동).
	//   ⇒ 이 저장소에 없던 것이 「지속」 하나였고, 그것을 여기서 붙인다.
	//
	// ★ **팔 다섯 — 두 자리를 격리한다**:
	//   0 🚪 무작위 · 1 👁️ 손 신호(배관 검산) ·
	//   2 🔗 **선형**(같은 35특징 · **곱이 없다**) ·
	//   3 🔀 **게이팅 + 책임 무게**(갱신을 `g[j]` 로 나눈다 = **주소가 있다**) ·
	//   4 🎯 **게이팅인데 주소 없음**(게이트로 **읽기만** 하고 갱신은 **전역**).
	//   ⇒ **2↔3 = 곱이 있나** · **3↔4 = 주소가 있나**. 특징·탐험·보상·상한이 전부 같다.
	//
	// ★ **과제군을 순서로 배운다 — 그것이 간섭 검사다**(세계 공사가 필요 없다):
	//   `A`(색만 틀림) → `B`(자리만 틀림) → `A'`(색만 틀림 다시) → `AB`(**처음 보는 조합**).
	//   각 100과제. ⚠️ 크기 축은 늘 맞게 시작한다(정직하게 적는다 — 축 셋을 다 쓰지 않았다).
	//
	// ★ **미리 등록**(작동 판정 — 크기가 아니라 **비교**가 판정이다):
	//   ㉠ **간섭** — 게이팅 팔의 `A'` 가 `A` 보다 **−5%p 이내** (대조군 = 선형 팔의 낙폭)
	//   ㉡ **곱이 값을 하나** — 게이팅 팔의 `A` 가 선형 팔의 `A` + **15%p 이상**
	//   ㉢ **주소가 값을 하나** — 주소 없는 게이팅 팔이 `A'` 에서 **더 크게** 떨어진다
	//   ㉣ **새 조합** — `AB` 에서 게이팅 팔이 선형 팔보다 높다
	//   ★ 크기 예측(자신 없다 — 이 트랙은 크기 예측이 계속 틀렸다):
	//     선형 A ~45% · B ~99% · A' ~35% · AB ~30% │ 게이팅 A ~75% · A' ~72% · AB ~60%
	//
	// ══════ 🕰️ **D84 — A' 의 상승이 전이인가 시간인가**(D83 이 남긴 혼동) ══════
	// ⚠️⚠️ **새 혼동을 하나 봤다.** `A → B → A'` 에서 A' 가 올랐다는 것은 **「안 덮였다」의**
	//   **증거이지 「B 가 도왔다」의 증거가 아니다** — 그냥 **시간이 더 지나** A 를 더 배운
	//   것일 수도 있다. 두 해석이 같은 숫자를 낸다.
	// ★ 팔을 더하지 않고 가를 수 있다: **각 과제군을 반씩 갈라** 궤적을 본다.
	//   · `A 후반` ↔ `A' 전반` 이 **이어지면** ⇒ 그냥 시간이다(학습이 계속된 것).
	//   · `A' 전반` 이 `A 후반` 보다 **뛰면** ⇒ B 를 거친 것이 도왔다(전이).
	//   ⇒ ★ 그리고 **선형 팔이 같은 자리에서 안 뛰면** 그 전이가 **주소 덕**임이 갈린다.
	// ★ 미리 등록: 게이팅 팔의 `A' 전반` − `A 후반` 이 **+8%p 이상**이면 전이다.
	//   ⚠️ 아니면 「시간이었다」로 적고, 그래도 ㉠(안 덮인다)는 그대로 선다.
	//
	// ══════ 🎲 **D85 — 씨앗별 부호검정**(작업 규율) ══════
	// ⚠️ D83·D84 는 **씨앗 하나**였다. 결과가 컸지만(이음매 +20.0%p) 긍정 주장에는 **재현**이
	//   필요하다(작업 규율: 씨앗별 부호검정). ⇒ 씨앗을 여러 개 돌리고 **씨앗마다** 부호를 센다.
	//   ★ 정책은 씨앗마다 **0 에서 다시** 시작한다(안 그러면 씨앗이 독립이 아니다).
	//   ⚠️ 과제군을 100 → 80 으로 줄여 시간을 맞췄다 ⇒ D83·D84 와 **직접 비교가 아니다**(함정 213).
	// ★ 미리 등록: 이음매(게이팅) > 0 **이고** 선형보다 큰 씨앗이 **5/6 이상** ⇒ ✅ 선다.
	//
	// ══════ 🧭 **D86 — 전이된 그것이 「심볼」인가**(D85 가 남긴 물음) ══════
	// ✅✅ D83~D85 가 **전이**를 쟀다(이음매 +24.2%p · 씨앗 6/6). 그런데 **무엇이 전이됐나**는
	//   안 물었다. ⇒ `concept.md` 의 성공 조건은 *"**새로 생긴 심볼**이 다음 학습의 앵커로"*
	//   *"실제 사용된다"* 이므로, 전이된 그것이 **심볼의 자격**을 갖는지 봐야 한다.
	//
	// ⚠️⚠️ **왜 「낱말을 문맥에 넣는다」로 안 하나 — 함정 219 다.** 「나아짐/막힘」은 **이미**
	//   문맥에 있다(지속 흔적이 그 부호의 감쇠 합이다) ⇒ 두 정보원이 겹쳐 **잴 수 없다.**
	//   ★ 그래서 물음을 더 정확한 자리로 옮긴다: **게이트 패턴이 심볼인가.**
	//     이름은 없지만 **이산**이고(묶음 넷 중 하나) **상태 종류에 따라 갈리고** **재사용된다면**
	//     그것이 심볼의 자격이다(concept.md: *"중요한 것은 이름이 아니라 다음 경험을 압축하고
	//     예측하며 다른 채널에서 재사용되는가"*).
	//
	// ★ **상관이 아니라 개입으로 잰다** — 학습을 **동결**하고 게이트만 바꿔 같은 과제를 다시 돈다:
	//   ⓐ **정상 게이트**(기준) · ⓑ **균등 게이트**(상태 무관 — 라우팅만 없앤다) ·
	//   ⓒ **무작위 게이트**(매 걸음 뒤섞는다).
	//   ⇒ 가중치가 **똑같으므로** 떨어진 만큼이 곧 **게이트의 상태 의존이 하던 일**이다.
	//   ★ 이것이 이 저장소의 「끊는다」 관용구의 **가장 강한 형태**다(끊는 것이 학습이 아니라 **쓰임**이다).
	// ★ 동결 평가는 **AB 과제**(색+자리 둘 다 틀림)로 한다 — 거기서만 상태 종류가 둘 다 나온다.
	//
	// ★ **미리 등록**:
	//   ㉠ **갈리나** — 「색 틀림」 상태의 최빈 묶음과 「자리 틀림」 상태의 최빈 묶음이 **다르다**
	//   ㉡ **개입** — 균등 게이트로 바꾸면 도달률이 **−10%p 이상** 떨어진다
	//   ㉢ 무작위 게이트는 **더** 떨어진다
	//   ★ 크기 예측: 정상 **~74%** · 균등 **~60%** · 무작위 **~50%**
	//   ⚠️ 갈릴 수 있는 자리: 균등이 안 떨어지면 게이트는 **장식**이었고, 전이는 전문가 가중치
	//     쪽에서 온 것이다(그러면 그렇게 적는다 — 그것도 값진 답이다).
	//
	// ══════ ⚖️ **D87 — 「주소」인가 「작은 학습률」인가**(D86 이 결론을 흔들었다) ══════
	// ⛔⛔ **D86 의 개입 검사가 게이트를 장식으로 판정했다**:
	//   · 상태 종류가 달라도 **전부 묶음 2**(69/77/71%) ⇒ 라우팅이 상태를 **안 가른다**
	//   · 균등 게이트로 바꿔도 **−1.0%p** ⇒ 없애도 같다
	//   · ⚠️⚠️ **무작위 게이트가 오히려 +14.6%p 높다**(55.4 ↔ 40.8) ⇒ 게이트가 **해로웠다**
	// ★ **그러면 D85 의 「주소가 값을 한다」(+30.6 ↔ +6.9)는 다른 이유다.**
	//   가장 유력한 것: 책임 무게가 `resp = g[j]` 이고 `Σg = 1` 이므로 묶음마다의 갱신이
	//   평균 **1/4** 로 줄어든다 ⇒ 주소 팔은 사실상 **유효 학습률이 1/4 인 팔**이다.
	//   ⇒ ⚠️⚠️⚠️ **「주소」와 「작은 학습률」이 구별되지 않았다.** 주소 없는 팔은 `resp = 1` 이라
	//     학습률이 **4배**이고, 그러면 더 빨리 배우고 **더 많이 덮는다**.
	//     ⇒ 「주소가 값을 한다」가 아니라 **「천천히 배우면 덜 덮는다」** 일 수 있다.
	// ★ ⇒ **팔 5 = 주소 없는 게이팅 + 학습률 `lr/4`** 를 넣어 가른다(유효 학습률을 맞춘다).
	//   · 팔 5 가 팔 3(+30.6%p)과 **비슷하면** ⇒ 주소는 **학습률이었다**
	//   · 팔 5 가 팔 4(+6.9%p) 쪽이면 ⇒ 주소가 **진짜** 값을 했다
	//   ★ 미리 등록: 팔 5 의 `A' − A` 가 **+20%p 이상**이면 「학습률이었다」로 적는다.
	//     ⚠️ 어느 쪽이든 D85 의 ㉠·㉤(간섭 없음 · 전이 +24.2%p · 6/6)은 **실측 그대로 남는다** —
	//       바뀌는 것은 **원인의 이름**이다.
	//
	// ══════ 🛡️ **D88 — 보호를 갱신 규칙으로 직접 만든다**(D87 이 기제를 지목했다) ══════
	// ★ D87 의 결론: **주소의 값은 「어디를 읽나」가 아니라 「어디를 안 건드리나」다.**
	//   그리고 게이트가 실제로 한 일을 다시 보면 — `g` 가 **묶음 2 에 74% 쏠려** 있었다 ⇒
	//   갱신이 사실상 **한 묶음에만** 걸렸다. ⇒ ★ 기제의 이름은 **희소성(sparsity)** 이다.
	// ⇒ 그러면 **게이트를 아예 안 쓰고** 같은 것을 만들 수 있다: **한 걸음에 한 묶음만 갱신한다.**
	//   ★ 그 팔들은 **읽기가 선형과 똑같다**(게이트를 균등으로 둔다) ⇒ **쓰기만 다르다** ⇒ 완벽한 격리.
	//
	// ★ 세 팔로 「무엇이 고르는가」를 가른다 (전부 같은 희소성 · 같은 학습률):
	//   · 6 🛡️ **입력이 고른다** — 지금 **가장 크게 말하는 묶음**(`argmax Σ|f|`) 하나만 갱신
	//   · 7 📌 **고정 하나** — 늘 묶음 2 만 갱신(D87 의 `g` 를 흉내낸 것)
	//   · 8 🎲 **무작위 하나** — 매 걸음 무작위 한 묶음(**같은 비용 · 내용 0**)
	//   ⇒ 8 이 6·7 만큼 되면 값을 한 것은 **희소성 자체**이고, 못 하면 **무엇을 고르는가**다.
	//
	// ⚠️⚠️ **그리고 표본을 늘린다** — D85 → D87 에서 팔 하나에 이음매가 +24.2 → +15.0,
	//   부호검정 6/6 → 4/6 으로 흔들렸다. ⇒ 씨앗 **6 → 10**.
	//
	// ★ **미리 등록**:
	//   ㉦ 팔 6(입력이 고른다)의 `A' − A` 가 **선형 + 15%p 이상**
	//   ㉧ 팔 8(무작위)이 팔 6 보다 **5%p 이상 낮다** ⇒ 「무엇을 고르는가」가 값을 한다
	//   ㉨ 팔 7(고정 2)이 D87 의 게이팅+주소(+21.7%p)를 **재현**한다 ⇒ `g` 는 사실상 고정 선택이었다
	//   🎲 팔 6 의 이음매 부호검정 **8/10**
	//   ★ 크기 예측: 팔 6 **+15~20%p** · 팔 7 **+18~22%p** · 팔 8 **+5~10%p**
	//   ⚠️ 갈릴 수 있는 자리: 팔 8 도 크면 **희소성만으로** 된 것이다(그러면 그렇게 적는다 —
	//     그것도 값진 답이고, 「보호」의 정의가 더 단순해진다).
	//
	// ══════ 🎓 **D90 — 「무엇을 고르는가」를 배우게 한다** ══════
	// ✅ D88~D89: 보호는 **쓰기 쪽 규칙**이고 **고르는 것이 값을 한다**(입력 +11.8 ↔ 무작위 +4.8
	//   ↔ 고정 +3.0) · 절대 `A'` **76.6%** 로 전 팔 최고.
	// ⚠️ 그런데 고르는 규칙이 **손으로 쓴 것**이다(`argmax Σ|f|` = 가장 크게 말하는 묶음).
	//   ⇒ 배우게 만든다. **유용성**을 배운다: *"그 묶음을 골라 갱신했더니 **다음** 결과가"*
	//   *"나아졌나."* ★ 자기상태 네 조건을 다 만족한다(내생적·지속·기능적 결과·닫힘).
	// ★ 팔 둘 — **문맥이 값을 하나**를 가른다:
	//   · 9 🎓 **배우는 선택 · 전역** — `v[j]` 하나씩(문맥은 편향만 본다)
	//   · 10 🎓 **배우는 선택 · 문맥별** — `Σ vw[j][k]·c[k]`(지속 흔적 + 자기 색을 본다)
	//   ★ `gw` 를 **재사용**한다 — 이 팔들은 읽기에서 게이트를 안 쓰므로(균등) 충돌이 없다.
	//     ⇒ ★ 같은 라우팅 기계를 **읽기에서 떼고 쓰기에만** 붙인 것이다(D89 의 그 갈림).
	//   ⚠️ 신용은 **한 걸음 늦게** 간다(고른 뒤 다음 결과가 말해 준다) — 그때의 문맥을 쓰므로
	//     한 걸음 어긋난 근사다(정직하게 적는다).
	// ★ **미리 등록**(문턱은 판정문이 찍는다):
	//   ㉦ 배운 선택의 절대 `A'` 가 **손 규칙 + 3%p 이상**
	//   ㉧ 문맥별이 전역보다 **+3%p 이상** ⇒ 문맥이 값을 한다
	//   ㉨ 배운 선택이 **무작위 + 5%p 이상**
	//   ★ 크기 예측: 전역 **~74~78%** · 문맥별 **~76~80%**
	//   ⚠️ 갈릴 수 있는 자리: 손 규칙(`가장 크게 말하는 묶음`)이 이미 거의 최적일 수 있다
	//     ⇒ 그러면 「배운 것이 손 규칙을 못 넘는다」로 적는다(그것도 값진 답이다).
	//
	// ══════ 🎚️ **D91 — 희소성의 경계를 찾는다** ══════
	// ★ D90 이 기제를 **「희소 + 다양」** 으로 좁혔다 — **둘 다 내용 0** 인 대조군이
	//   40%p 갈렸다(무작위 72.8% ↔ 고정 하나 32.2%). ⇒ 이제 **곡선**을 잰다.
	// ★ 축 둘:
	//   · **k** = 한 걸음에 갱신하는 묶음 수 **1 / 2 / 3 / 4**
	//     ⇒ ★ **k = 4 는 「보호 없음」이라 선형과 같아야 한다 — 내장 검산이다.**
	//   · **다양성** = **무작위** / **라운드로빈** / **고정** / **입력이 고른다**(k = 1 에서)
	// ⚠️ 팔을 다시 짠다 — 답이 난 팔(배운 선택 ⛔ · lr/4 ✅✅ 두 번)은 **지운다**
	//   (`Docs/Guide.md`: *"새 기능으로 이전 기능 필요 없어졌다면 호환 유지용으로 두지 말고 제거"*).
	//   ★ 표본이 또 바뀐다(함정 213·237) ⇒ **큰 축만** 본다.
	// ★ **미리 등록**(문턱은 판정문이 찍는다):
	//   ㉦ **k 곡선이 단조 감소**한다(k=1 > k=2 > k=3 > k=4)
	//   ㉧ **검산**: k=4 와 선형의 차가 **3%p 이내**(같은 것이어야 한다)
	//   ㉨ **다양성**: 고정이 무작위보다 **20%p 이상** 낮다 · 라운드로빈은 무작위와 **3%p 이내**
	//   ★ 크기 예측: k=1 ~73% · k=2 ~71% · k=3 ~68% · k=4 ~65%(≈선형) · 고정 ~32%
	//   ⚠️ 갈릴 수 있는 자리: 곡선이 **단조가 아니면**(예: k=2 가 가장 좋다) 「희소성」이 아니라
	//     **「적당한 희소성」** 이고, 그러면 최적 k 가 있다는 뜻이다(그것도 값진 답이다).
	// ══════════════════════════════════════════════════════════════════
	// 🕳️ **묶음 아홉**(D111) — 마지막 묶음은 **이름 없는 행동 카운터 5칸**이다.
	//   ⚠️ 「무엇을 세는지」는 안 알려 준다 — 행동 인덱스는 학습기가 이미 쓰는 것이고,
	//   그것을 **쓸지 말지는 학습기가 정한다**(🚫 사람이 만든 의미축을 주지 않는다).
	static constexpr int kGG = 13;                 // 🧠 묶음 열셋(D119)
	static constexpr int kGF = 169;                // 🌊 100 + 🔮 예측벡터 5 + 🧠 은닉 64
	static constexpr int kHid = 64;                // 🧠 **잠재 상태**의 칸(D122 · 16 → 64)
	// ══════════════════════════════════════════════════════════════════
	// 🎚️ **D92 · 희소 갱신** — 게이팅을 지웠다. **읽기는 선형**이고 **쓰기만** 희소하다.
	//
	// ★ **왜 지웠나** — D91 이 게이팅 결론을 **재현 불가**로 판정했다(함정 239):
	//   간섭 +22.4 → **+7.4%p** · 게이트 패턴 묶음 2(74%) → **묶음 0(100%)** · TV 0.28 → **0.00** ·
	//   부호검정 9/10 → **3/10**. 바뀐 것은 팔 구성과 슬롯뿐이었다.
	//   ⇒ 남겨 두면 **불안정한 팔이 판정과 부호검정을 계속 흔든다**(이음매가 그 팔로 재어졌다).
	//
	// ⚠️⚠️⚠️ **그리고 정직한 정정 하나** — **지속 상태(`h`)도 지웠다.**
	//   `h` 가 영향을 준 **유일한 경로는 게이트의 질의**였고, 개입 검사가 그 게이트를 **장식**으로
	//   판정했다(균등으로 바꿔도 −1~−3%p) ⇒ **지속 상태도 아무 일도 안 했다.**
	//   ⇒ D83 의 *"자기상태 네 조건 중 없던 「지속」을 붙였다"* 는 **철회한다.**
	//     ★ 붙이기는 했지만 **기능적 결과**가 없었으니 그 조건을 만족하지 않았다
	//     (concept.md 의 네 조건 중 셋만 있었다). ⇒ 다시 붙일 자리를 찾아야 한다(📌).
	//
	// ⚖️ **이 라운드가 가르는 것 — 「희소」인가 「총 갱신량」인가**(함정 229 의 재발 검사).
	//   `k=1` 은 한 묶음만 갱신하므로 **총 갱신량이 `k=4` 의 1/4** 이다 ⇒ 두 설명이 같은 숫자를 낸다.
	//   ⇒ ★ **양방향으로** 맞춘다:
	//     · `k=4 + lr/4` — 총량을 `k=1` 에 맞춘다 ⇒ **k=1 만큼 되면 총량이었다**
	//     · `k=1 + lr×4` — 총량을 `k=4` 에 맞춘다 ⇒ **k=4 만큼이면 총량이었다**
	//   ⇒ 두 방향이 **서로 교차검증**한다.
	//   ★ 참고: **고정 k=1 은 총량이 k=1 과 같은데 33.1%** 였다 ⇒ 총량만은 확실히 아니다.
	//
	// ★ **미리 등록**(문턱은 판정문이 찍는다):
	//   ㉠ **희소 ≠ 총량(↓)** — `k=4+lr/4` 가 `k=1` 보다 **5%p 이상 낮다**
	//   ㉡ **희소 ≠ 총량(↑)** — `k=1+lr×4` 가 `k=4`(전부) 보다 **5%p 이상 높다**
	//   ㉢ **다양성** — 고정이 무작위보다 **20%p 이상 낮다**
	//   🎲 **부호검정** — 이음매를 **`k=1` 팔**로 재고 **7/10**(안정된 팔로 잰다)
	//   ★ 크기 예측: 전부 ~66% · k=1 ~73% · k=4+lr/4 ~68% · k=1+lr×4 ~71% ·
	//     라운드로빈 ~76% · 고정 ~33% · 입력 ~79%
	//   ⚠️ 갈릴 수 있는 자리: 두 대조군이 `k=1` 만큼 되면 **「희소」는 이름이고 실체는 총량**이다
	//     (그러면 그렇게 적고 기제를 「작은 갱신」으로 고쳐 부른다).
	//
	// ══════ 🧠 **D93 — 지속 상태를 「다양성 관리」로 다시 붙인다** ══════
	// ⚠️ D92 가 지속 상태를 **철회**했다(영향 경로가 게이트뿐이었고 그 게이트가 장식이었다).
	//   ⇒ **다시 붙일 자리**를 실측이 줬다: **다양성**이 기제이고(고정 36.4 ↔ 무작위 75.4),
	//   라운드로빈(78.9)이 무작위보다 조금 낫다 ⇒ 「**돌아가면 된다**」.
	// ★ 그래서 지속 흔적을 **다양성 관리**에 쓴다:
	//   `score[j] = (그 묶음이 지금 말하는 양) / (1 + 최근성[j])`
	//   · **최근성** `u[j]` = 그 묶음을 고른 것의 **감쇠 합**(걸음마다 `u *= 0.6`, 고르면 `+1`)
	//   ⇒ **입력이 크게 말하는 묶음을 고르되, 최근에 많이 고른 것은 눌린다.**
	//   ⇒ ★ 「입력이 고른다(78.0)」와 「라운드로빈(78.9)」의 **합성**이다.
	// ★ **끊는 검사가 구조에 내장돼 있다** — `u` 를 무시하면 그것이 **입력 팔** 그대로다
	//   ⇒ 팔 7 ↔ 팔 6 의 차가 곧 **지속 흔적이 하는 일**이다(concept.md 의 그 판정법:
	//   *"붙였다고 말하려면 끊었을 때 무언가 무너져야 한다"*).
	// ★ 자기상태 네 조건: **내생적**(고른 것에서 온다) · **지속**(감쇠하며 남는다) ·
	//   **기능적 결과**(다음 선택을 바꾼다) · **닫힘**(선택 → 흔적 → 선택).
	//
	// 🎲 **그리고 부호검정 지표를 고친다**(함정 240) — 이음매는 반구간(40과제)이라 못 쓴다.
	//   ⇒ **씨앗별 절대 `A'`** 로 세 쌍을 센다: `k=1 > 전부` · `팔7 > 팔6` · `무작위 > 고정`.
	//   ★ 그러면 D91(+7.0%p)·D92(+7.3%p)의 재현에 **도장**을 찍을 수 있다.
	// ⚠️ 답이 난 팔(k=2 · k=4+lr/4 · k=1+lr×4)은 **지운다** — 기록은 mllog 에 남는다.
	// ★ **미리 등록**: 🎲 `k=1 > 전부` **8/10** · 🧠 팔 7 이 팔 6 보다 **+3%p 이상** ·
	//   🔁 고정이 무작위보다 **20%p 이상** 낮다 · 크기 예측: 팔 7 **~80~83%**
	//   ⚠️ 갈릴 수 있는 자리: 둘 다 이미 78%대라 **천장**일 수 있다 ⇒ 그러면 「둘이 이미 같은
	//     일을 하고 있었다」로 적는다(그것도 값진 답이다).
	//
	// ══════ 🌊 **D94 — 이름 없는 입력을 넓게** ══════
	// ★ `concept.md` 의 **「고정 특징 집합은 세계 표현이 아니다」** 그 절이다 — 지금까지의
	//   격자 셋 + 색 one-hot 은 *"이번 한 종류의 작동 결과를 읽기 위해 우리가 고른 관측 축"*
	//   이었다(**비계**). 이제 **보호가 섰으니**(희소+다양+최근성 · 재현 3회) 넓혀도 된다.
	//   ⚠️ 순서가 중요했다 — 「넓은 입력 + 약한 학습기 = 잡음」이라 라우팅/보호가 먼저였다.
	//
	// ★ **묶음 여덟 · 특징 75** — 전부 **이름이 없다**(무엇을 뜻하는지 알려주지 않는다):
	//   0 `3x3` 차(목표 색) 9 · 1 `3x3` 차(자기 색) 9 · 2 `3x3` 목표 절대 9
	//   3 `2x2` 차 4 · 4 `4x4` 차 16 · 5 행/열 프로파일 차 8+8
	//   6 **바이트 히스토그램 차** 8 · 7 스칼라 4(잉크 총량 둘 · 배경 아닌 화소 · 편향)
	// ⚠️⚠️ **비계를 걷어냈다** — 손으로 준 **「목표 색 one-hot」을 뺐다.** 색 정보는 이제
	//   **바이트값 히스토그램**(`v >> 5` 로 8칸)에만 있다 ⇒ **이름 없이** 준 것이다.
	//   ★ 그래서 이 라운드는 「넓혔다」와 「비계를 뺐다」를 **동시에** 한다 — 그것이 더 어렵다.
	//
	// ★ **미리 등록**:
	//   ㉠ **넓혀도 선다** — `입력÷최근성` 이 **85% 이상**(D93 은 90.9%, 특징이 2배가 됐으니
	//     조금 내려갈 수 있다)
	//   ㉡ **희소성의 이득이 묶음 수에 비례한다** — `k=1 ↔ 전부` 차가 4묶음의 **+5.4%p** 보다
	//     커진다(예측 **+8~12%p**)
	//   ㉢ **다양성** 재확인 · 🎲 씨앗별 부호검정 **8/10**
	//   ⚠️ 갈릴 수 있는 자리: 특징이 75개로 늘어 **표본이 얇아져** 전체가 내려갈 수 있다
	//     ⇒ 그러면 「넓은 입력은 표본이 받쳐야 한다」의 실측이 된다(그것도 값진 답이다).
	//
	// ══════ 🎛️ **D95 — 손 상수 λ 를 놓아준다** ══════
	// ★ **지적이 정확했다** — 최근성의 감쇠 `λ = 0.6` 은 **내가 손으로 박은 상수**다.
	//   그리고 **적절한 값은 조합마다 다를 것**이다(묶음이 몇 개냐 · 과제가 무엇이냐에 따라).
	//   ⇒ 그것은 「고정 특징 집합」과 **같은 종류의 잘못**이다(🚫 *"손 상수로 정하지 마라"*).
	//   ⚠️ 그리고 **기준을 미리 잡을 수가 없다** — 무엇이 「최근」인지 세계가 정하지 않는다.
	//
	// ★ **두 물음을 한 판에서 답한다**:
	//   ㉠ **λ 가 얼마나 중요한가** — 0.3 / 0.6 / 0.9 세 팔의 **폭**을 본다
	//   ㉡ **적응형이 최고 고정값을 넘나** — **여러 시간 척도를 동시에 들고** 어느 것이
	//      유용한지 배우는 팔. ★ 넘으면 「적응이 필요하다」가 서고, 못 넘으면
	//      「이 세계에서는 고정값으로 충분하다」다(그것도 정직한 답이다).
	//   ㉢ **비계 vs 넓힘**(함정 243 의 처방) — 같은 넓은 입력에 **색 one-hot 만 되돌린 팔**.
	//
	// ★ **적응형은 어떻게 만드나** — 척도 셋을 동시에 굴리고 **성적으로 섞는다**:
	//   `score[j] = Σ_m q[m] · a[j] / (1 + u_m[j])`   (λ_m = 0.3 / 0.6 / 0.9)
	//   · `u_m` = 그 척도의 최근성 흔적 · `q` = 척도의 가중치(합 1)
	//   · 갱신은 **책임 무게 관용구를 재사용**한다 — 고른 묶음에 각 척도가 **준 기여만큼**
	//     신용이 간다(`q[m] += lrq · sg · 기여비중`). ⇒ 참여한 경로에만 책임.
	//   ⚠️ 여전히 `{0.3, 0.6, 0.9}` 라는 손으로 고른 **집합**이다 — 그러나 **하나를 고르는**
	//     **것보다는 정직**하다(인코딩은 허용, 답은 아니다).
	//
	// ★ **미리 등록**:
	//   ㉠ 세 λ 팔의 **폭이 5%p 이상**이면 「λ 가 중요하다」
	//   ㉡ 적응형이 **최고 고정 λ 팔 + 3%p 이상**
	//   ㉢ 색 one-hot 되돌린 팔이 λ=0.6 팔보다 **+5%p 이상**이면 D94 의 하락은 **비계 제거 탓**
	//   ★ 크기 예측: λ=0.3 ~78%% · λ=0.6 ~82%% · λ=0.9 ~79%% · 적응형 **~83~86%%** ·
	//     one-hot 되돌림 **~86%%**
	//   ⚠️ 갈릴 수 있는 자리: 폭이 작으면(≤3%p) **λ 는 중요하지 않았다**는 뜻이고 그러면
	//     적응형도 이길 것이 없다(그러면 그렇게 적는다).
	//
	// ══════ 🎛️ **D96 — λ 를 1.0 까지 밀어 본다** ══════
	// ★ D95: **λ=0.9(가장 오래 기억)가 최고**였다(82.9 ↔ 0.3/0.6 은 80.1).
	//   ⇒ **끝값이 최고면 범위를 안 넓혀 본 것이다**(concept.md 에 적었다).
	//   ⇒ λ ∈ {0.6, **0.9, 0.95, 0.99, 1.0**} + **라운드로빈**을 나란히 둔다.
	// ★ **λ = 1.0 이면 이름이 바뀐다.** `u[j]` 가 감쇠하지 않으므로 그것은 그 묶음을 고른
	//   **총 횟수**이고, `a[j] / (1 + u[j])` 는 **균등 커버리지**를 강제한다.
	//   ⇒ 그때 기제는 「**최근성**」이 아니라 「**커버리지**」다 — **아주 다른 기제**다.
	//     · 최근성 = *"방금 쓴 것은 잠깐 쉬어라"*  · 커버리지 = *"모든 묶음을 골고루 써라"*
	// ★ 적응형(D95 · −1.6%p)과 색 one-hot 팔(D95 · −9.5%p)은 **답이 났으므로 지웠다.**
	// ★ **미리 등록**:
	//   ㉠ λ 다섯 팔의 **폭이 5%p 이상**이면 「λ 가 중요하다」
	//   ㉡ **λ=1.0 이 최고**면 기제를 **「커버리지」로 고쳐 부른다**
	//   ㉢ λ=1.0 ↔ **라운드로빈**의 차가 **3%p 이내**면 「커버리지 = 돌아가기」로 합쳐 적는다
	//   ★ 크기 예측: 0.6 ~80%% · 0.9 ~83%% · 0.95 ~84%% · 0.99 ~85%% · 1.0 ~85%% ·
	//     라운드로빈 ~73%%
	//   ⚠️⚠️ **갈릴 수 있는 자리**: `λ=1.0` 이 **오히려 나빠질** 수 있다 — 영구 기억이면 한 번
	//     고른 묶음을 **영영 피하므로** 정작 필요한 묶음을 못 쓴다. 그러면 「**잊어야 한다**」가
	//     서고 **최적 λ 가 안쪽에** 있다(그러면 그것이 이 기제의 진짜 모양이다).
	//
	// ══════ 🪜 **D97 — 깊이 2**: 당장 좋아지지 않는 선행 행동 ══════
	// ★ **정책이 굳었다** — `k=1` · 입력 ÷ (1 + 최근성 λ=0.99) · 네 성분이 다 재현됐다
	//   (희소 +15.5 · 골고루 +43.6 · 입력 보며 +6.9 · 천천히 잊기 +3.2%p). ⇒ **관문이 섰다**
	//   (깊이 1 을 84.2% 로 한다) ⇒ 이제 **의존 깊이**로 간다(concept.md 의 그 축).
	//
	// ★ **세계에 순서 제약을 넣는다 — 한 줄이다**:
	//   ***크기가 최소(`cs == 0`)일 때만 자리 행동이 통한다.***
	//   ⇒ 목표가 「큰 크기 + 다른 자리」면 **먼저 작게 만들어야** 자리를 옮길 수 있고,
	//     그 첫 걸음은 **목표거리를 늘린다**(= 「막힘」) ⇒ 정확히 **「당장 좋아지지 않는**
	//     **선행 행동」** 이다(GPT 와 얘기한 깊이 2 의 그 모양).
	//   ⚠️ 이것은 **세계의 법칙**이라 if/else 로 확정이다(concept.md: 판단은 분포, 세계는 확정).
	//   ⚠️ **갇히지는 않는다** — 회복 가능하지만 **비싸다**(그래야 도달률로 잴 수 있다).
	//
	// ★ **구간 넷 중 마지막을 `H`(깊이 2)로 바꿨다** — 간섭 검사(A→B→A')는 그대로 산다:
	//   · A/A' 색만 틀림(크기 0) · B 자리만 틀림(크기 0 ⇒ 자리 이동 자유)
	//   · **H 자리 틀림 + 크기가 이미 목표(2)** ⇒ 자리를 옮기려면 **크기를 내렸다 올려야** 한다
	//
	// ★ **미리 등록**:
	//   ㉠ **세계가 진짜 깊이 2 인가** — **손 신호**(선천적 지식)가 `H` 에서 **무너진다**.
	//     ★ 왜: 손 신호는 「가장 큰 오차 축을 고친다」인데 `H` 에서는 색·크기 오차가 0 이라
	//       **자리만 되풀이**하고 그것이 막혀 있다 ⇒ **갇힌다.** 예측 **~0%**.
	//   ㉡ **즉시 보상으로는 순서를 못 배운다**(함정 224 의 재현) — 학습 정책도 `H` 에서 낮다
	//   ㉢ ★ **그런데 탐험이 있는 정책은 우연히 빠져나온다** ⇒ **학습 정책이 `H` 에서 손 신호를**
	//     **크게 이긴다.** ⇒ D66 이후 처음으로 손 신호를 넘는 자리다.
	//   ★ 크기 예측: 손 신호 `H` **~0%** · λ=0.99 `H` **~20~50%** · 무작위 행동 `H` ~30~50%
	//   ⚠️ 갈릴 수 있는 자리: 셋 다 0% 에 가까우면 **회복이 너무 비싼 것**이고, 그러면 제약을
	//     느슨하게 해야 한다(시도 상한을 늘리거나 크기 단계를 줄인다).
	//
	// ══════ 🪜 **D98 — 신용을 뒤로**(이번엔 세계가 준비됐다) ══════
	// ★ D97 이 자리를 만들었다: **세계가 깊이 2 이고**(손 신호 **0.0%**) **무작위가**
	//   **20.6% 로 「가능함」을 증명했다.** ⇒ 물음이 깨끗하다 — **그 20.6% 를 넘나.**
	// ⚠️ D79 에서 종단 흔적이 실패한 이유는 **분산**이었고, 그때는 **세계에 깊이가 없었다.**
	// ★ 그리고 함정 248 이 핵심을 지목했다: **학습이 탐험을 죽인다.**
	//   ⇒ 탐험을 죽이지 않는 **네 축**을 팔로 가른다:
	//   · 🚫 **막힘에 벌 없음** — 「막힘」에 −1 대신 **0**(처벌하지 않고 그냥 넘긴다)
	//   · 🎲 **ε 크게** — 10% → **40%**
	//   · 🪜 **종단만** — 도달 +1 / 실패 −1 을 **흔적으로 뒤로** 흘린다(즉시 보상 없음)
	//   · 🪜 **셋 다** — 종단 + 벌 없음 + ε 크게
	//
	// ★ **미리 등록**(기준선 = 무작위 행동의 `H` **20.6%**):
	//   ㉠ 종단 팔들의 `H` 가 **20.6% 를 넘나**
	//   ㉡ **막힘에 벌을 안 주면** 오르나(팔 3 ↔ 팔 2 의 1.1%)
	//   ㉢ **ε 를 키우면** 오르나(팔 4 ↔ 팔 2)
	//   ㉣ **A' 를 안 망치나** — 깊이 1 이 88.0% 근처를 유지하나
	//   ★ 크기 예측: 벌 없음 ~15%% · ε=40%% ~12~18%% · 종단만 ~5~15%% · 셋 다 **~20~30%%**
	//   ⚠️⚠️ **갈릴 수 있는 자리**: **전부 20.6% 를 못 넘으면** 「이 세계에서 **학습은 손해**」가
	//     서고, 그러면 필요한 것은 **보상 규칙이 아니라 모델**이다 — *"예측을 겸하는 해결책*
	//     *설계"*(사용자가 그린 고리) 로 가야 한다. ⇒ 그것도 값진 답이다.
	//
	// ══════ 🔮 **D99 — 한 걸음 예측기**(관문) ══════
	// ★ D98 이 **모순**을 잡았다(함정 249): 「막힘」의 벌을 빼면 깊이 1 이 88.5 → 26.9% 로
	//   무너지고, 벌을 두면 깊이 2 가 0.5% 다 ⇒ **벌이 필요하고 벌이 해롭다** ⇒ **보상 규칙**
	//   **안에는 답이 없다.** ⇒ **층을 하나 올린다**: *"예측을 겸하는 해결책 설계"*.
	//
	// ★ **최소 형태부터 — 관문이다.** 예측기는 정책과 **나란히** 돌며 **채점만** 한다
	//   (팔 구조를 안 건드리므로 깊이 1/2 숫자가 그대로 비교된다).
	//   · 예측: 행동 `a` 를 하면 **나아질까**(+) 막힐까(−) — `Σ pw[a][k]·f[k]` 의 부호
	//   · 학습: 실제 결과(`sg`)로 퍼셉트론 갱신
	//   · 채점: **직전 걸음의 예측 ↔ 실제** ⇒ 정확도
	//
	// ⚠️⚠️ **정확도만 보면 안 된다**(함정 219 의 계열) — `H` 구간은 「늘 막힘」이 이미 ~90% 라
	//   **최빈 예측이 거의 맞는다.** ⇒ ★ 핵심 지표는 **recall** 이다:
	//   ***실제로 「나아짐」인 걸음만 골라, 그 안에서 맞힌 비율.*** = 「막힘 바다에서 나아짐을
	//   찾아내나」. 최빈 예측의 recall 은 **0%** 이므로 그 자리에서는 겹치지 않는다.
	//
	// ★ **미리 등록**:
	//   ㉠ **정확도**가 「늘 막힘」 대조군보다 **+10%p 이상**(깊이 1 구간)
	//   ㉡ **recall** 이 **50% 이상**(깊이 1) — 최빈 예측은 0% 다
	//   ㉢ **`H` 에서도 recall 이 30% 이상** ⇒ 깊이 2 에서도 예측이 선다
	//   ★ 크기 예측: 정확도 ~80% · 「늘 막힘」 ~65% · recall ~60% · `H` recall ~35%
	//   ⚠️ 갈릴 수 있는 자리: `H` recall 이 낮으면 **깊이 2 에서는 예측조차 안 선다**는 뜻이고,
	//     그러면 2단 롤아웃 전에 **예측기부터 고쳐야** 한다(관문이 그것을 말해 준다).
	//
	// ⚠️ **이 채점은 예측기에게 불리한 쪽으로 기울어 있다** — 예측기는 **씨앗마다 0 에서** 다시
	//   시작하는데 채점은 **첫 걸음부터** 세므로 「아직 안 배운 구간」이 다 들어간다. 최빈 대조군에는
	//   그런 구간이 없다. ⇒ **넘으면 진짜로 넘은 것**이고, 못 넘으면 이 기울기를 먼저 의심한다.
	// ══════════════════════════════════════════════════════════════════
	// 🎚️ 묶음 경계 — `f[0..8] f[9..17] f[18..26] f[27..34]`(목표 색 one-hot).
	static int _GLo(int j)
	{
		static const int lo[kGG + 1] = { 0, 9, 18, 27, 31, 47, 63, 71, 83, 89, 94, 100,
			105, 169 };
		return lo[j];
	}

	// 🎚️ **희소 정책** — 읽기는 **완전 선형**이고, 쓰기에서 **어느 묶음을 갱신하나**만 다르다.
	struct SPol
	{
		double w[kLA][kGF] = {};
		double b[kLA] = {};
		MLChoice Score(const double* f) const
		{
			double s[kLA] = {}, lo = 0.0;
			for (int a = 0; a < kLA; ++a)
			{
				s[a] = b[a];
				for (int k = 0; k < kGF; ++k) s[a] += w[a][k] * f[k];
				if (a == 0 || s[a] < lo) lo = s[a];
			}
			// ⚠️ 지수를 안 쓴다 — 최소값을 0 으로 옮긴다(`MLChoice` 의 규약).
			MLChoice ch; ch.Reset(kLA);
			for (int a = 0; a < kLA; ++a) ch.Set(a, s[a] - lo + 1e-9);
			ch.Normalize();
			return ch;
		}
		// 🎚️ 한 묶음만 갱신한다. ⚠️ `bias` — 여러 묶음을 돌 때 편향을 **한 번만** 올린다.
		void LearnOne(const double* f, int jsel, int a, double sign, double lr, bool bias)
		{
			for (int k = _GLo(jsel); k < _GLo(jsel + 1); ++k) w[a][k] += lr * sign * f[k];
			if (bias) b[a] += lr * sign;
		}
	};

	// 🌊 **`n x n` 격자** — 그 바이트값의 칸별 비율(0~1). 이름이 없다.
	static void _GridN(const uint8* p, int cell, uint8 v, int n, double* out)
	{
		for (int i = 0; i < n * n; ++i) out[i] = 0.0;
		const int h = cell / n;
		for (int y = 0; y < cell; ++y)
		{
			int gy = y / h; if (gy >= n) gy = n - 1;
			for (int x = 0; x < cell; ++x)
			{
				int gx = x / h; if (gx >= n) gx = n - 1;
				if (p[(uint64)y * (uint64)cell + (uint64)x] == v) out[gy * n + gx] += 1.0;
			}
		}
		const double a = (double)(h * h);
		for (int i = 0; i < n * n; ++i) out[i] /= a;
	}

	// 🌊 **행/열 프로파일**(각 `n` 칸) + **바이트 히스토그램**(`v >> 5` 로 8칸) + 스칼라.
	//   ⚠️ 히스토그램이 **색 정보를 이름 없이** 담는다 — 손으로 준 「목표 색 one-hot」의 대체다.
	static void _ProfHist(const uint8* p, int cell, uint8 v, uint8 bg,
		double* row, double* col, double* hist, double* sc)
	{
		const int n = 8;
		for (int i = 0; i < n; ++i) { row[i] = 0.0; col[i] = 0.0; }
		for (int i = 0; i < 8; ++i) hist[i] = 0.0;
		double ink = 0.0, nonbg = 0.0;
		const int h = cell / n;
		for (int y = 0; y < cell; ++y)
		{
			int gy = y / h; if (gy >= n) gy = n - 1;
			for (int x = 0; x < cell; ++x)
			{
				int gx = x / h; if (gx >= n) gx = n - 1;
				const uint8 q = p[(uint64)y * (uint64)cell + (uint64)x];
				if (q == v) { row[gy] += 1.0; col[gx] += 1.0; ink += 1.0; }
				if (q != bg) { hist[q >> 5] += 1.0; nonbg += 1.0; }
			}
		}
		const double area = (double)cell * (double)cell;
		for (int i = 0; i < n; ++i) { row[i] /= area; col[i] /= area; }
		for (int i = 0; i < 8; ++i) hist[i] /= area;
		sc[0] = ink / area;
		sc[1] = nonbg / area;
	}

	// 🌊 **넓은 특징 75개**(D94) — 「지금 − 목표」의 차를 여러 분해능으로 담는다.
	//   ⚠️ 어느 칸이 무엇을 뜻하는지 **알려주지 않는다.**
	static void _WideFeat(const uint8* now, const uint8* goal, int cell,
		uint8 gv, uint8 selfv, uint8 bg, double* f)
	{
		double a9[9] = {}, b9[9] = {}, s9[9] = {};
		_GridN(now, cell, gv, 3, a9);
		_GridN(goal, cell, gv, 3, b9);
		_GridN(now, cell, selfv, 3, s9);
		for (int i = 0; i < 9; ++i)
		{
			f[i] = a9[i] - b9[i];              // 0 목표 색 기준 차
			f[9 + i] = s9[i] - b9[i];          // 1 자기 색 기준 차
			f[18 + i] = b9[i];                 // 2 목표(절대)
		}
		double a4[4] = {}, b4[4] = {};
		_GridN(now, cell, gv, 2, a4);
		_GridN(goal, cell, gv, 2, b4);
		for (int i = 0; i < 4; ++i) f[27 + i] = a4[i] - b4[i];    // 3 `2x2` 차
		double a16[16] = {}, b16[16] = {};
		_GridN(now, cell, gv, 4, a16);
		_GridN(goal, cell, gv, 4, b16);
		for (int i = 0; i < 16; ++i) f[31 + i] = a16[i] - b16[i]; // 4 `4x4` 차
		double r1[8] = {}, c1[8] = {}, h1[8] = {}, s1[2] = {};
		double r2[8] = {}, c2[8] = {}, h2[8] = {}, s2[2] = {};
		_ProfHist(now, cell, gv, bg, r1, c1, h1, s1);
		_ProfHist(goal, cell, gv, bg, r2, c2, h2, s2);
		for (int i = 0; i < 8; ++i)
		{
			f[47 + i] = r1[i] - r2[i];         // 5 행 프로파일 차
			f[55 + i] = c1[i] - c2[i];         //   열 프로파일 차
			f[63 + i] = h1[i] - h2[i];         // 6 바이트 히스토그램 차(색을 이름 없이)
		}
		f[71] = s1[0] - s2[0];                 // 7 목표 색 잉크 총량 차
		f[72] = s1[1] - s2[1];                 //   배경 아닌 화소 차
		{
			double ss[2] = {}, rr[8] = {}, cc[8] = {}, hh[8] = {};
			_ProfHist(now, cell, selfv, bg, rr, cc, hh, ss);
			f[73] = ss[0] - s2[0];             //   자기 색 잉크 총량 차
		}
		f[74] = 1.0;                           //   편향
	}

	// 🎛️ 단일 척도로 고른다 — `입력이 말하는 양 / (1 + 최근성)`.
	static int _PickOne(const double* f, const double* u)
	{
		int best = 0; double bv = -1.0;
		for (int j = 0; j < kGG; ++j)
		{
			double a = 0.0;
			for (int t = _GLo(j); t < _GLo(j + 1); ++t) a += (f[t] < 0.0) ? -f[t] : f[t];
			const double s = a / (1.0 + u[j]);
			if (s > bv) { bv = s; best = j; }
		}
		return best;
	}

	// 🪜 **종단 흔적**(D98) — 걸음마다 (특징, 행동, 고른 묶음)을 쌓고 **끝에서** 흘린다.
	//   ⚠️ 감쇠 무게의 합을 걸음 수로 정규화한다(같은 비용 · D79 의 그 처방).
	static constexpr int kSTr = 64;
	struct STrace
	{
		double f[kSTr][kGF] = {};
		int a[kSTr] = {}, j[kSTr] = {};
		int n = 0;
		void Reset() { n = 0; }
		void Push(const double* ff, int aa, int jj)
		{
			if (n >= kSTr) return;
			for (int k = 0; k < kGF; ++k) f[n][k] = ff[k];
			a[n] = aa; j[n] = jj; n++;
		}
		void Flush(SPol& p, double sign, double lam, double lr)
		{
			if (n == 0) return;
			double s = 0.0, w = 1.0;
			for (int t = 0; t < n; ++t) { s += w; w *= lam; }
			const double g = (s > 0.0) ? ((double)n / s) : 1.0;
			w = 1.0;
			// ★ 최근 걸음이 더 큰 신용을 받는다(뒤에서 앞으로 감쇠).
			for (int t = n - 1; t >= 0; --t)
				{ p.LearnOne(f[t], j[t], a[t], sign * g * w, lr, true); w *= lam; }
		}
	};

	// 🔮 **한 걸음 예측기**(D99) — 행동마다 「나아질까」를 예측한다. **정책과 따로** 산다.
	struct PPol
	{
		double w[kLAX][kGF] = {};
		double b[kLAX] = {};
		double Pred(const double* f, int a) const
		{
			double s = b[a];
			for (int k = 0; k < kGF; ++k) s += w[a][k] * f[k];
			return s;
		}
		// 🎯 **두 모드**(D101) — `logit=false` 면 퍼셉트론, `true` 면 **로지스틱**.
		// ⚠️⚠️ 퍼셉트론은 **틀렸을 때만** 민다 ⇒ **점수의 여백에 뜻이 없다**(함정 256):
		//   부호 정확도 93.1% 인데 `argmax` 정책이 무작위와 같았다(D100).
		// ★ 기제를 손으로 확인했다 — `A'` 에서 색거리가 2 면 `색+1` 도 **막힘**(d 불변)이고
		//   자리 이동도 **막힘**이다. **부호만 보면 둘이 같다.** 그런데 `색+1` 은 **때때로 +1**,
		//   자리 이동은 **항상 −1** ⇒ ***확률로 담으면 구별된다.*** 그래서 로지스틱이 처방이다
		//   (= `concept.md` 의 **「판단은 분포로」** 의 구체적 실현).
		void Learn(const double* f, int a, double sg, double lr, bool logit)
		{
			const double s = Pred(f, a);
			if (!logit)
			{
				if ((s > 0.0) == (sg > 0.0)) return;
				for (int k = 0; k < kGF; ++k) w[a][k] += lr * sg * f[k];
				b[a] += lr * sg;
				return;
			}
			// 🎯 로지스틱 — **맞았을 때도** 배운다(그래서 여백에 뜻이 생긴다).
			//   ⚠️ float 시그모이드로 충분하다(기울기에 1e-7 이면 넘친다) — 엔진에 double
			//   오버로드를 더할 이유가 없다(`Exp` 는 이미 있다).
			const double z = (s > 30.0) ? 30.0 : ((s < -30.0) ? -30.0 : s);
			const double p = 1.0 / (1.0 + (double)Exp(-(float)z));
			const double g = ((sg > 0.0) ? 1.0 : 0.0) - p;
			for (int k = 0; k < kGF; ++k) w[a][k] += lr * g * f[k];
			b[a] += lr * g;
		}
		// 🎯 **argmax** — 이 예측기로 정책을 만들 때 쓴다.
		int Argmax(const double* f, int n) const
		{
			int bi = 0; double bv = -1.0e30;
			for (int a = 0; a < n; ++a)
			{
				const double v = Pred(f, a);
				if (v > bv) { bv = v; bi = a; }
			}
			return bi;
		}
	};

	// ══════ 🔎 **D110 — `H` 열을 찍는다: 축이 구간을 넘어 성립하나** ══════
	// ★ D109 가 **미리 적어 두고 못 확인한 것**을 잰다(그것이 규율이다 — 적어 뒀으면 재라):
	//   `far` 는 크기를 **목표와 반대**로 두는데 `H`(gs=2)에서는 그것이 `cs=0` 이라
	//   **자리를 연다** ⇒ **도움일 수도** 있다. ⚠️ 함정 280 이 「**부호가 구간마다 뒤집힌다**」고
	//   했으므로 이것을 재야 **「해로움의 정도」 축이 구간을 넘어 성립하나**를 말할 수 있다.
	//
	// ★ 배관은 그대로다 — `wH` 는 이미 계산돼 있었고 **로그에 안 넣고 있었을 뿐**이다.
	//   ⇒ 씨앗이 같으므로 `B`·`A'` 숫자는 **소수점까지 재현**되어야 한다(재현 확인).
	//
	// ★ **미리 등록**:
	//   ㉠ 🔎 **`H` 에서도 단조인가** — reset < no-op < far ⇒ 축이 **구간을 넘어** 성립한다
	//   ㉡ 💀 **`far` 가 `H` 에서 도움일 수 있다** — `cs=0` 이 자리를 열므로 `α` 가
	//     `no-op` 보다 **작을** 수 있다(그러면 ㉠ 이 깨지고 그것이 답이다)
	//   ㉢ ✅ `B`·`A'` 가 D109 를 **소수점까지 재현**한다
	//   ⚠️ `H` 의 무작위 도달률은 **아주 낮을** 수 있다(far x 17) ⇒ `α` 가 과대해진다
	//     ⇒ **표본이 작은 칸은 지수를 신뢰하지 말고 절대값도 같이** 읽는다.

	// ══════ 💀 **D109 — 「더 나쁜 상태로」: 해로움의 정도를 축으로** ══════
	// ★ D108 이 뒤집혔다(함정 279): `reset`(시작으로)이 **구원**이었다 — 이 세계의
	//   **시작 상태는 목표에서 한 축만 틀린 상태**라서다(`B` 는 색이 맞고 크기가 0 이다).
	//   ⇒ **「되돌리기 어려움」을 만들려면 시작이 아니라 「더 나쁜 상태」로** 보내야 한다.
	//
	// ★ **가장 해로운 값을 손으로 골랐다**(세계는 목표를 아니 **결정적**으로 정할 수 있다):
	//   · **색** = `(gc + 1) % nc` — ⚠️ 직관과 반대다. `색+1` 이 **유일한 색 행동**이므로
	//     **목표 바로 다음 색이 가장 멀다**(5색이면 **4걸음**). `(gc + nc/2)` 는 3걸음뿐이다.
	//   · **자리** = `(gx >= 2) ? 0 : 2` — 반대편 끝(3칸에서 최대 거리)
	//   · **크기** = `(gs == 0) ? 2 : 0` — 목표와 반대. ⚠️ `B`(gs=0)에서는 **자리를 잠근다**
	//     ⇒ 아주 해롭다. ⚠️ 그런데 `H`(gs=2)에서는 **자리를 연다** ⇒ **도움일 수도** 있다
	//     ⇒ 함정 280(**부호가 구간마다 뒤집힌다**)이 또 나올 자리다 — 미리 적어 둔다.
	//
	// ★ **아홉 판** — 🎲 `no-op`(공짜) · ☠️ `reset`(이 세계에서는 구원) · 💀 `far`(가장 나쁜 곳)
	//   x 행동 5·11·17. ⇒ **「해로움의 정도」 축이 세 점**으로 선다.
	//   ★ 🔭 오라클은 **셋 다 안 쓴다**(최적이므로) ⇒ **상한선이 계속 고정**된다.
	//   ⚠️ 행동 **5** 는 추가 행동이 0개라 **세 종류가 다 같아야** 한다(배관 확인).
	//
	// ★ **미리 등록**:
	//   ㉠ 💀 **`far` 의 `α` 가 `no-op`(0.469)보다 크다** — **0.8 이상**
	//   ㉡ 📏 **`α` 가 단조**다: `reset`(**−0.164**) < `no-op`(**0.469**) < `far`
	//     ⇒ **「해로움의 정도」 축이 선다**(그것이 이 판의 산출물이다)
	//   ㉢ 🎯 **`β/α` 가 `far` 에서 가장 작다** ⇒ 판정이 가장 날카롭다
	//   ㉣ 🔭 **오라클 아홉 판 100%** · 🪜 **깊이 불변**
	//   ㉤ ✅ **행동 5 에서 세 종류가 다 같다**(배관 · 소수점까지)
	//   ★ 갈림: `far` 에서도 `α` 가 1 에 못 가면 **이 세계는 원래 회복 가능한 세계**라는 뜻이다
	//     ⇒ `α = 1` 을 원하면 **세계를 바꿔야** 한다(되돌릴 수 없는 사건 = 사용자 목록 3
	//     「충돌해 사라짐」) ⇒ 그것이 **다음 다리**다. 그것도 값진 답이다.

	// ══════ ☠️ **D108 — 해로운 행동: `α` 를 1 로 만드는 올바른 손잡이** ══════
	// ★ D107 이 **함정 276** 을 냈다: 예산을 줄여도 `B` 의 `α` 는 **0.469 → 0.297** 로
	//   **오히려 작아졌다** — 쓸모없는 행동(`no-op`)은 걸음만 낭비하고 **상태를 안 망치기**
	//   때문이다. ⇒ ***「선택지를 늘리는 것」과 「위험을 늘리는 것」은 다르다.***
	//   그리고 **`α` 는 「실수가 회복되나」가 정한다.**
	//
	// ★ **되돌리기 어려운 행동의 최소 형태**를 손으로 골랐다:
	//   · ⛔ **즉시 실패** — 매 걸음 `(A-5)/A` 로 죽으면 `(5/A)^T` 라 **지수적**이다(너무 강하다)
	//   · ⛔ **색 두 칸 밀기** — 5칸 순환에서 여전히 **회복 가능**하다(`α` 가 1 에 못 간다)
	//   · ✅ **「그 에피소드의 시작 상태로 되돌림」(reset)** — **진행을 통째로 잃는다.**
	//     ⇒ 무작위는 경로 길이 `d` 에 대해 `(5/A)^d` 로 죽는다 ⇒ **`α ≈ d`**(1~2 대역이다)
	//     ⇒ ★ 그리고 **깊이를 안 바꾼다**(경로 길이가 그대로다) ·
	//       **🔭 오라클은 reset 을 안 쓴다**(최적이므로) ⇒ **상한선이 고정**된다.
	//
	// ★ **여섯 판** — `no-op` x (5·11·17) 과 `harmful` x (5·11·17) 을 **나란히**.
	//   ⚠️ 행동 **5** 는 추가 행동이 0개라 **두 종류가 같아야 한다** — 그것이 **배관 확인**이다.
	//
	// ★ **미리 등록**:
	//   ㉠ ☠️ **harmful 의 `α` 가 no-op 보다 크다** — `B` 에서 **0.47 → 1.0 이상**
	//   ㉡ 🔭 **오라클이 두 종류 다 100%**(reset 을 안 쓰므로) ⇒ 상한선 고정
	//   ㉢ 🪜 **깊이 불변** — 오라클 지평 훑기가 여섯 판 다 같은 계단을 찍는다
	//   ㉣ 🎯 **`β/α` 가 harmful 에서 더 작아진다** ⇒ 판정이 날카로워진다
	//   ㉤ ✅ **행동 5 에서 두 종류가 같다**(배관 확인 · 소수점까지)
	//   ★ 갈림: harmful 에서 `β` 도 같이 커지면(β/α 가 안 작아지면) **학습기도 되돌림에**
	//     **취약하다**는 뜻이다 ⇒ 「기억/계획」이 필요하다는 근거가 된다(그것도 값진 답이다).
	//   ⚠️ 그리고 **모든 구간·모든 팔에서** 방향을 확인한다(함정 275·278).

	// ══════ ⏱️ **D107 — 걸음 예산 × 행동 수: `α` 를 1 에 붙인다** ══════
	// ★ D106 이 **「기능한다」를 세웠다**(`α = 0.469` ↔ `β = 0.216`). ⚠️ 그런데 함정 274 가
	//   같이 나왔다: 행동 수를 **3.40배** 늘렸는데 무작위는 **1/1.77** 만 죽었다 —
	//   **상한 60걸음**이면 무작위가 45칸 공간을 **여러 번 훑기** 때문이다.
	//   ⇒ `α` 는 **세계가 아니라 예산의 함수**다.
	//
	// ★ **예산은 깨끗한 축이다** — 관측·세계 법칙·의존 깊이를 **하나도 안 건드린다.**
	//   ⇒ 예산을 줄이면 **쓸모없는 행동이 곧 실패**가 되어 `α → 1` 에 가까워지고
	//   **배율 판정이 날카로워진다.** ★ 덤: 예산이 짧아지면 **라운드가 빨라진다.**
	//
	// ★ **격자로 돈다** — 예산 **60 · 30 · 15** x 행동 **5 · 11 · 17** = **아홉 판.**
	//   ⇒ 예산마다 `α`(무작위 감소 지수)와 `β`(학습)를 **따로** 재고 `β/α` 를 견준다.
	//   ⚠️ **여러 팔에서** 본다(함정 275 — 배율 추세가 팔마다 다르다).
	//
	// ★ **미리 등록**:
	//   ㉠ 🔭 **오라클이 아홉 판 다 100%** — `H` 의 최적 경로가 5~6걸음이라 예산 15 도 충분해야
	//     한다. ⚠️ 못 내는 판이 있으면 **예산이 너무 짧다**는 뜻이고 그 판은 판정에서 뺀다.
	//   ㉡ 🚪 **예산이 줄면 `α` 가 1 에 가까워진다** — 60: **0.47** → 30: ~0.7 → 15: ~0.9
	//   ㉢ 🎯 **`β` 는 예산에 덜 민감하다** ⇒ **`β/α` 가 작아진다**(= 판정이 날카로워진다)
	//   ㉣ ⚠️ **절대 도달률은 전부 떨어진다** — 그것은 **난이도 차**이고 `α`·`β` 로 정규화해 읽는다
	//   ★ 갈림: `α` 가 안 오르면 **예산이 병목이 아니었다**는 뜻이다 ⇒ 무작위가 왜 안 죽는지를
	//     다른 데서 찾아야 한다(그것도 값진 답이다).

	// ══════ 📈 **D106 — 경우의 수 판: 「기능하나」를 처음으로 잰다** ══════
	// ★ **사용자가 판정 자체를 고쳤다**: *"선택 경우의 수가 너무 작으면 무작위가
	//   예측·추론보다 오히려 더 나은 게 얼마든지 가능하지. 무작위는 당연히 **경우의 수 비례로**
	//   낮아지고, 예측·추론은 **비례보다 낮은 수치로 낮아지기만 해도** (기능하는) 거구나.
	//   **격차 좁혀지다가 역전하는 단계**가 빨리 오면 그럭저럭 역할 잘되고 있는 거고…"*
	//   ⇒ ⚠️⚠️ **D97 부터 판정이 줄곧 「무작위를 넘나」 하나였다** — 한 세계 크기로는
	//     **원리적으로 판정이 안 된다**(규율 13 의 계열).
	//
	// ★ **깨끗한 축을 찾는 데 둘을 버렸다**:
	//   · ⛔ **자리 칸 수** — 칸이 촘촘해지면 **관측 구별력**이 같이 흔들린다
	//   · ⛔ **색 수** — `A'` 의 오라클 필요 지평이 **곧 색 거리**다 ⇒ **깊이가 경우의 수와**
	//     **정확히 같이 자란다**(완전 교란 · 함정 272 를 또 밟는 것이다)
	// ⇒ ★ **행동 수**다. **쓸모없는 행동(no-op)을 더한다**:
	//   · 무작위는 `~1/A` 로 **정확히 비례해** 죽는다(그것이 `α = 1` 의 기준선이다)
	//   · **깊이는 안 변한다**(상태를 안 바꾸므로 오라클도 안 고친다)
	//   · **관측 구별력도 안 변한다**(프레임이 그대로다)
	//   ⇒ **축이 하나만 움직인다.**
	// ★ 그리고 그것이 정확히 **「기능하나」의 시험**이다 — *학습기가 쓸모없는 선택지를 배제하나.*
	//
	// ★ **미리 등록**:
	//   ㉠ 🚪 무작위가 **행동 수에 비례해 죽는다** — `B` 도달률이 5 → 17 에서 대략 **1/3.4**
	//   ㉡ 🎯 학습은 **덜 죽는다** ⇒ **배율(학습/무작위)이 행동 수와 함께 커진다**(= `β < α`)
	//   ㉢ 🔭 **오라클은 행동 수와 무관하게 100%** — no-op 을 안 쓰므로(배관 확인)
	//   ㉣ 🪜 **깊이가 안 변한다** — 오라클 지평 훑기가 네 판 다 같은 계단을 찍는다
	//   ★ 갈림: 배율이 **안 커지면** 학습기가 **쓸모없는 행동을 배제하지 못한다** ⇒
	//     「기능하지 않는다」가 **처음으로** 선다(그것도 값진 답이다).

	// ══════ 🌿 **D105 — 다중 조건 분기: 「폭」을 잰다** ══════
	// ★ **순서를 뒤집었다 — 손계산이 그렇게 말했다.** 사용자 목록의 5번(순환 관계)을
	//   먼저 하려 했는데, **비추이성은 「한 상태 안의 행동 순위」에서는 안 생긴다**:
	//   지금 구조는 `argmax_a Q(f, a)` 이고 상태가 주어지면 **최선 행동은 하나**다.
	//   「상태 → 최선 행동」은 **표**이고 그 표는 `(색 one-hot x 행동)` **선형으로 담긴다.**
	//   ⇒ 비추이성이 문제가 되는 자리는 **쌍 비교**뿐이고 그건 **대상이 여럿**이어야 한다
	//     — 사용자가 5번에 「**세** 물체」라고 쓴 것이 정확했다. ⇒ 다물체 배관(`n != 1` 검사 ·
	//     `_WideFeat` 의 목표 색 기준)이 **앞선다.**
	// ⇒ ★ 반면 **7번(다중 조건 분기)은 물체 하나로 되고 배관 변경이 0** 이다(오라클도 그대로).
	//   그래서 **7 을 먼저 한다.**
	//
	// ★ **폭 = 조건 분기의 개수.** 「자리가 열리는 조건」을 색에 따라 갈랐다(`_XOpen`):
	//   · **① 조건 하나**(현행) — 늘 `크기 == 최소`
	//   · **② 분기 둘** — 색 0~2 는 `최소`, 색 3~4 는 **`최대`**(반대다)
	//   · **③ 분기 셋** — 색 0~1 은 `최소`, 색 2~3 은 `최대`, 색 4 는 **늘 열림**
	//   ⚠️ 「깊이」가 아니라 **「폭」** 축이다 — `H` 의 논리곱 **한 겹**이 이미 벽이었다(함정 256).
	//   ★ 그리고 **세계 법칙을 한 함수로 뽑았다**(`_XOpen`) — 예전엔 세계 적용과 오라클 **두**
	//     **곳**에 있었고, 폭을 늘리는 순간 오라클이 **틀린 세계를 계획**할 자리였다.
	//
	// ★ **미리 등록**:
	//   ㉠ 🔭 **오라클이 세 폭 다 `H` 100%** — 못 내면 **세계가 안 풀린다**는 뜻이고 그러면
	//     학습 팔의 숫자는 아무 뜻이 없다 ⇒ **그것을 먼저 적는다**(가능함을 증명하는 팔).
	//   ㉡ 🎯 **`B`(자리만 틀림)가 폭에 따라 떨어진다** — 분기가 늘면 선형이 담기 어렵다
	//     ⚠️ `A'`(색만 틀림)는 자리를 안 움직이므로 **`xOpen` 이 영향을 안 준다** ⇒ `B` 로 본다
	//   ㉢ 📈 **`H` 는 어느 폭에서도 무작위를 못 넘는다** — 깊이가 남아 있으므로(1단의 한계)
	//   ㉣ ⚠️⚠️ **무작위도 폭에 따라 떨어진다** ⇒ 학습 팔의 낙폭을 **무작위 낙폭과 견줘야**
	//     한다 — 그것이 **「난이도 차」와 「학습 실패」를 가른다**(D104 에서 배운 것이다).

	// ══════ 🎭 **D104 — 과제 유형 셋: 따로 재고 섞어서 재라** ══════
	// ★ 사용자가 부른 칸이다: *"과제 유형을 한 3개로 늘리고, 각각 따로 · 섞어서로 하자.
	//   하나에 핏되게 하고 있는 부분들이 보일테니까."*
	//   ⇒ 그것이 `concept.md` 의 **「간섭으로 판정한다」** 그 자리다:
	//   *"A 와 B 를 각각 재면 둘 다 90% 라서 **한 숫자로는 절대 안 보인다**."*
	//
	// ★ **유형 셋** — 같은 축(색·자리·크기) · 같은 행동 5개 · 같은 세계 법칙인데
	//   **특징이 말하는 방식만** 다르다. `Draw::` 에 이미 다 있어 **엔진 변경 0** 이다:
	//   · 🟥 **찬 네모**(`RectFill`) — 현행. 잉크 `s²`
	//   · ⬜ **빈 네모**(`Rect`) — 테두리만. 잉크 `4s−4` ⇒ **잉크·히스토그램이 딴말을 한다**
	//   · ⚪ **찬 동그라미**(`CircleFill`) — 잉크 `πs²/4` ⇒ **격자·프로파일 분포가 다르다**
	//   ⚠️ 유형은 **에피소드마다 고정**이다(「도형 바꾸기」는 행동에 없다) ⇒ 「섞음」은
	//     **에피소드끼리** 섞는 것이다.
	//
	// ★ **네 판을 돈다**: 🟥 따로 · ⬜ 따로 · ⚪ 따로 · 🔀 섞음.
	//   그리고 **섞음 안에서 유형별로 따로 집계**한다 ⇒ 「따로 X%」 ↔ 「섞음에서의 X%」 가
	//   나란히 놓인다. **그 차가 곧 간섭이다.**
	//   ★ `mode 0`(🟥 따로)이 **현행 세계**라 옛 판정 전부가 **재현 확인**이 된다(함정 213).
	//   ⚠️ D103 의 상상기 채점은 **`mode 0` 에서만** 돈다 — 계측을 지우지 않고 **끈다**
	//     (README 의 그 규약) · 비용이 4배가 되지 않는다.
	//
	// ★ **미리 등록**:
	//   ㉠ 🎭 **따로 재면 세 유형이 비슷하다**(`A'` 각각 90%+) — 축·행동·법칙이 같으므로
	//   ㉡ 🔀 **섞으면 떨어진다** — `A'` 평균이 따로 대비 **−10%p 이상**(= 간섭)
	//   ㉢ 🎭 **가장 크게 떨어지는 유형이 있다** — 그것이 *"비계가 그 유형에 핏돼 있었다"* 의 신호
	//   ㉣ 🔭 **오라클 지평 4 는 네 경우 다 `H` 100%** — 세계 법칙이 도형과 무관하므로
	//   ★ 갈림: 섞어도 **안 떨어지면** 이 특징 집합은 **모양에 대해 이미 일반적**이다
	//     ⇒ 그것도 값진 답이고, 간섭을 볼 축을 **다른 데서** 찾아야 한다.
	//   ⚠️ ㉣ 가 깨지면(유형마다 오라클이 다르면) **세계가 유형마다 다른 깊이**라는 뜻이다
	//     ⇒ 그러면 ㉠~㉢ 의 비교가 성립하지 않으므로 **그것을 먼저 적는다.**

	// ══════ 🧩 **D103 — 상상이 맞나**(관문만 · 계획은 그 다음이다) ══════
	// ★ D102 가 **N−1 대조군을 완성**했다(보상 규칙 ⛔ · 예측 ⛔ · 가치/감쇠 ⛔ ↔
	//   🔭 오라클 지평 4 **100.0%**) ⇒ 남은 것은 **계획(상상)** 이다.
	//
	// ⚠️⚠️ **그런데 짓기 전에 손으로 따졌고 두 갈래가 죽었다**:
	//   ㉠ **`Δq̂` 형태**(「a 를 한 뒤 b 의 점수가 얼마나 바뀌나」 · 5x5x83 = 2075)는 `f` 를
	//     입력으로 받으므로 **한 번만 적용된다** ⇒ **지평 2 까지만** 된다. 그런데 D100 이
	//     **지평 2 = 0.0%** 라고 쟀다 ⇒ **실패가 보장된 설계**다(규율 13 의 정신: 원리적으로
	//     못 이기는 것을 짓지 않는다).
	//   ㉡ **탐욕 롤아웃**(첫 걸음만 다양하게 보고 이후는 예측기 argmax)은 **이후 정책이**
	//     **손해를 감수하지 않으므로** 「손해 뒤의 이득」을 **원리적으로 못 본다.**
	//   ⇒ 남는 것은 **전탐색 + 특징 전이 상상**인데 그것은 노드 780 x 곱 6889 x 걸음 19만
	//     = **1e12 곱셈**으로 **한 라운드에 안 들어간다.**
	//
	// ⇒ ★ **그래서 이 판은 관문만 짓는다** — D99 의 교훈(*"관문이 먼저다"*)이고
	//   D100 의 교훈(*"재기 전에 짓지 않는다"*)이다. 물음 하나: ***상상이 맞나.***
	//
	// ★ **그리고 관문을 쓸 곳과 같게 만든다**(함정 257·259·263 세 개를 다 지킨다):
	//   · **모양** — 「상상한 `Ŝ1` 에서 고른 행동」이 「실제 `S1` 에서 고른 행동」과 같나
	//     (계획이 쓰는 것이 정확히 그 결정이다)
	//   · **깊이** — 오차를 **1·2·3·4걸음** 따로 잰다(일치율이 곱으로 들어가므로 · 263)
	//   · **분포** — 채점은 🚪 무작위 팔(고정 분포)로만(259 · 258)
	//
	// ★ 그리고 **깊이별 오차 증가가 곧 「의심 축이 필요한가」의 데이터**다(📌 2):
	//   4걸음 상상에서 오차가 크게 늘면 **「이 상상을 얼마나 의심하나」** 가 없으면 계획이
	//   잘못된 상상을 끝까지 따라간다는 뜻이다.
	//
	// ★ **미리 등록**:
	//   ㉠ 🧩 **깊이 1 상대오차 ≤ 30%**(「안 변한다」 대조군이 정확히 **100%** 다)
	//     — 근거: **전이가 결정적**이라(잡음이 없다) 회귀로 배우기 쉽다
	//   ㉡ 🌫️ **깊이 4 / 깊이 1 배율 ≥ 3배** ⇒ **의심 축이 필요하다**는 근거가 선다
	//   ㉢ ⚖️ **결정 일치율 ≥ 70%**(상상 `Ŝ1` 의 argmax ↔ 실제 `S1` 의 argmax)
	//   ★ 갈림: ㉠ 이 실패하면 **83차원 선형 전이로는 안 된다** ⇒ **잠재 상태**(작은 world
	//     model)로 가야 한다는 근거가 선다(그러면 그렇게 적는다).
	//   ★ 갈림: ㉡ 이 작으면(오차가 안 늘면) **의심 축은 계획에 불필요**하다 ⇒ 📌 2 의 순서를
	//     다시 본다(그것도 값진 답이다).

	// 🧩 **전이 상상기**(D103) — `Δf̂ = W_a·f + b_a` 를 배워 **다음 특징**을 상상한다.
	//   ⚠️⚠️ `5 x 83 x 83` double = **275KB** 라 **`static`** 이어야 한다(스택에 못 올린다).
	//   ⚠️ 그래서 `TPol()` 임시 객체도 만들지 않는다 — `Reset()` 으로 지운다.
	struct TPol
	{
		double w[kLA][kGF][kGF] = {};
		double b[kLA][kGF] = {};
		void Reset()
		{
			for (int a = 0; a < kLA; ++a)
			{
				for (int k = 0; k < kGF; ++k)
				{
					b[a][k] = 0.0;
					for (int j = 0; j < kGF; ++j) w[a][k][j] = 0.0;
				}
			}
		}
		// 🧩 **변화**를 상상한다(절대값이 아니다) — `out = f + Δf̂`.
		void Imagine(const double* f, int a, double* out) const
		{
			for (int k = 0; k < kGF; ++k)
			{
				double s = b[a][k];
				for (int j = 0; j < kGF; ++j) s += w[a][k][j] * f[j];
				out[k] = f[k] + s;
			}
		}
		void Learn(const double* f, int a, const double* fN, double lr)
		{
			for (int k = 0; k < kGF; ++k)
			{
				double s = b[a][k];
				for (int j = 0; j < kGF; ++j) s += w[a][k][j] * f[j];
				const double e = (fN[k] - f[k]) - s;
				for (int j = 0; j < kGF; ++j) w[a][k][j] += lr * e * f[j];
				b[a][k] += lr * e;
			}
		}
	};

	// ══════ 📈 **D102 — 깊이를 감쇠로 담는다**(계획을 짓기 전에) ══════
	// ★ **진단을 다시 본다.** D98~D101 이 `H` 에서 다 실패한 공통 원인은 하나다 —
	//   **「나아짐」을 `d`(화소 목표거리)로 정의했다.** `d` 는 **탐욕 지표**이고, 깊이 4 짜리
	//   세계에서는 첫 걸음이 `d` 를 **키운다.** ⇒ 무엇을 배우든 `d` 를 신호로 쓰면 막힌다.
	//
	// ★ **깊이를 담는 길은 둘이다**: **계획**(상상해서 고른다) · **가치**(감쇠로 접는다).
	//   우리는 계획만 봤다(2단 롤아웃을 📌 에 적어 뒀다). ⇒ ⚠️ **가치 쪽이 훨씬 싸다**:
	//   `Q(f,a)` 는 예측기와 **똑같은 415 파라미터**(5 x 83)이고 구조가 이미 있다.
	//   ⇒ ★ **재기 전에 짓지 않는다**(D100 의 교훈) — 싼 것을 먼저 재고, 안 되면 계획으로 간다.
	//     그러면 「계획이 필요하다」가 **N−1 대조군 위에** 선다.
	//
	// ★ 그리고 **이 처방은 함정 249 의 모순을 원리적으로 피한다**: 보상이 **도달 +1**
	//   **하나뿐**이라 「막힘에 벌」이 아예 없다. ⇒ *"벌이 필요하고 벌이 해롭다"* 가 성립할
	//   자리가 없다. 깊이는 **감쇠 `γ`** 가 담는다(`γ` 가 곧 지평이다).
	//
	// ★ 팔 여덟: 0 🚪 무작위(채점) · 1 🎯 로지스틱 확률뽑기(D101 최고 · A' 95.2 / H 1.4) ·
	//   2 📈 **Q γ=0.9 확률뽑기**(주역) · 3 📈 Q **γ=0.99** · 4 📈 Q **γ=0.5**(얕은 쪽 대조) ·
	//   5 📈 Q γ=0.9 **argmax**(ε=40%) — D101 의 발견이 Q 에도 걸리나 ·
	//   6 🔭 오라클 지평 1 · 7 🔭 오라클 지평 4(상한선 H 100.0)
	//
	// ★ **미리 등록**:
	//   ㉠ 📈 Q(γ=0.9)가 `H` 에서 **무작위 19.5% 를 넘는다** — **~30%**(오라클 100% 와는 멀다)
	//   ㉡ 📈 **γ=0.5 는 못 넘는다** — 감쇠가 곧 지평이고 얕으면 손해를 못 감수한다
	//   ㉢ 📈 **γ=0.99 ≥ γ=0.9** (깊이가 4 라 긴 지평이 유리하다)
	//   ㉣ 🎯 `A'` 에서는 **로지스틱(95.2%)이 Q 보다 낫거나 비슷하다** — `A'` 는 1단이면 되므로
	//     감쇠가 이득 없이 잡음만 는다
	//   ★ 갈림: Q 가 `H` 를 못 넘으면 **감쇠로는 안 된다**가 서고, 그러면 **계획(상상)** 이
	//     필요하다는 말이 **대조군 위에** 선다 ⇒ 그것이 다음 판이다.
	//
	// ★ **그리고 관문을 두 분포에서 잰다**(함정 259 의 처방) — 「고정 분포」(🚪 무작위 팔)와
	//   「자기 분포」(그 정책이 실제로 지나는 상태) 둘. 두 값은 **다른 것**이고 둘 다 뜻이 있다.

	// 🧠 **2층 예측기 = 잠재 상태 생성기**(D119) — 은닉층이 곧 **이름 없는 잠재 상태**다.
	// ★ 왜 2층이어야 하나 — **선형의 선형은 새 정보가 0** 이다. `PPol::Pred` 는 `f` 의
	//   선형함수이고 `QPol::Q` 도 `f` 의 선형함수이므로, 예측값을 특징으로 되먹여도 **Q 가
	//   원리적으로 못 얻는다.** ⇒ 그래서 이 판에 **「예측 벡터 날것」 팔을 원리적 대조군으로**
	//   둔다(규율 13 의 짝: 원리적으로 **못 이기는** 시험은 배관 검증에 쓴다).
	// ★ 그리고 **은닉을 다음 걸음의 특징으로 넣으므로 재귀**가 된다 — `f` 안에 `h_{t-1}` 이
	//   있고 `h_t = tanh(W1 f)` 이므로 **한 겹 순환 신경망**이다. 이름은 안 준다.
	// ★ 학습 신호는 **예측기와 같은 것**(직전 걸음이 나아졌나)이라 세계가 축을 안 알려 준다.
	// ⚠️ `Tanh` 가 엔진에 없다 ⇒ `2·sigmoid(2z) − 1`(도함수는 `1 − h²` 로 같다).
	// ⚠️ **가중치를 0 으로 두면 기울기도 0** 이라 영원히 안 배운다(`dh = g·w2·(1−h²)` 에서
	//   `w2 = 0`) ⇒ **대칭을 깨야** 한다. ★ 그런데 **난수를 쓰면 시드 스트림을 소비해**
	//   과제가 흔들리고 옛 팔의 비트 재현이 깨진다(함정 296·302) ⇒ **결정적 산포**를 쓴다.
	struct MPol
	{
		double w1[kHid][kGF] = {}; double b1[kHid] = {};
		double w2[kLAX][kHid] = {}; double b2[kLAX] = {};
		// 🧠 **결정적 산포**(난수 아님) — 씨앗마다 다르고 스트림을 안 건드린다.
		void Init(uint32 sd)
		{
			for (int j = 0; j < kHid; ++j)
			{
				b1[j] = 0.0;
				for (int t = 0; t < kGF; ++t)
				{
					const uint32 v = ((uint32)j * 131u + (uint32)t * 17u + sd * 7919u) % 2003u;
					w1[j][t] = 0.02 * ((double)v / 1001.5 - 1.0);
				}
			}
			for (int a = 0; a < kLAX; ++a)
			{
				b2[a] = 0.0;
				for (int j = 0; j < kHid; ++j)
				{
					const uint32 v = ((uint32)a * 271u + (uint32)j * 37u + sd * 104729u) % 2003u;
					w2[a][j] = 0.02 * ((double)v / 1001.5 - 1.0);
				}
			}
		}
		void Hidden(const double* f, double* h) const
		{
			for (int j = 0; j < kHid; ++j)
			{
				double s = b1[j];
				for (int t = 0; t < kGF; ++t) s += w1[j][t] * f[t];
				const double z = (s > 15.0) ? 15.0 : ((s < -15.0) ? -15.0 : s);
				h[j] = 2.0 / (1.0 + (double)Exp(-(float)(2.0 * z))) - 1.0;
			}
		}
		double Pred(const double* h, int a) const
		{
			double s = b2[a];
			for (int j = 0; j < kHid; ++j) s += w2[a][j] * h[j];
			return s;
		}
		// 🎯 로지스틱 + 역전파 한 겹. `f` 와 `h` 는 **같은 걸음**의 것이어야 한다.
		void Learn(const double* f, const double* h, int a, double sg, double lr)
		{
			const double s = Pred(h, a);
			const double z = (s > 30.0) ? 30.0 : ((s < -30.0) ? -30.0 : s);
			const double p = 1.0 / (1.0 + (double)Exp(-(float)z));
			const double g = ((sg > 0.0) ? 1.0 : 0.0) - p;   // 목표 − 예측
			for (int j = 0; j < kHid; ++j)
			{
				const double dh = g * w2[a][j] * (1.0 - h[j] * h[j]);
				w2[a][j] += lr * g * h[j];
				for (int t = 0; t < kGF; ++t) w1[j][t] += lr * dh * f[t];
				b1[j] += lr * dh;
			}
			b2[a] += lr * g;
		}
	};

	// 🧩 **잠재 공간 전이 + 가치 머리**(D121) — 계획을 **감당 가능하게** 만드는 자리다.
	// ★ D120 이 비용을 손으로 재게 했다: 화소 공간 상상 1회 = `kGF²` = **14641 곱셈**,
	//   지평 4 전탐색은 `5⁴ × 4` = 2500 상상 = **3.7e7 곱셈/결정** ⇒ 감당 못 한다.
	//   잠재 공간은 `kHid²` = **256 곱셈**이라 **57배 싸고**, 빔 폭 5 면 `4 × 5 × 5` = 100
	//   전이 = **2.6e4 곱셈/결정** ⇒ 감당된다.
	// ★ 그래서 **잠재 상태의 진짜 쓸모는 「특징 하나 더」가 아니라 계획을 가능하게 하는 것**이다
	//   (D119 에서 특징으로는 값을 못 했다 · 함정 310).
	// ★ 전이 초기값을 **항등 + 작은 산포**로 둔다 ⇒ 처음엔 「안 변한다」에서 출발한다
	//   (대조군과 **같은 출발점**이라 개선이 곧 배운 것이다).
	struct TLat
	{
		double w[kLA][kHid][kHid] = {}; double b[kLA][kHid] = {};
		double u[kLA][kHid] = {}; double c[kLA] = {};
		void Init(uint32 sd)
		{
			for (int a = 0; a < kLA; ++a)
			{
				c[a] = 0.0;
				for (int j = 0; j < kHid; ++j)
				{
					b[a][j] = 0.0; u[a][j] = 0.0;
					for (int t = 0; t < kHid; ++t)
					{
						const uint32 v = ((uint32)a * 97u + (uint32)j * 131u
							+ (uint32)t * 17u + sd * 7919u) % 2003u;
						w[a][j][t] = ((j == t) ? 1.0 : 0.0)
							+ 0.02 * ((double)v / 1001.5 - 1.0);
					}
				}
			}
		}
		void Step(const double* h, int a, double* o) const
		{
			for (int j = 0; j < kHid; ++j)
			{
				double s = b[a][j];
				for (int t = 0; t < kHid; ++t) s += w[a][j][t] * h[t];
				const double z = (s > 15.0) ? 15.0 : ((s < -15.0) ? -15.0 : s);
				o[j] = 2.0 / (1.0 + (double)Exp(-(float)(2.0 * z))) - 1.0;
			}
		}
		double V(const double* h, int a) const
		{
			double s = c[a];
			for (int j = 0; j < kHid; ++j) s += u[a][j] * h[j];
			return s;
		}
		double Best(const double* h, int n) const
		{
			double m = V(h, 0);
			for (int a = 1; a < n; ++a) { const double v = V(h, a); if (v > m) m = v; }
			return m;
		}
		// 🧩 **전이** — 실제 다음 은닉과 맞춘다(재구성).
		void LearnT(const double* h, int a, const double* hn, double lr)
		{
			double o[kHid];
			Step(h, a, o);
			for (int j = 0; j < kHid; ++j)
			{
				const double g = (hn[j] - o[j]) * (1.0 - o[j] * o[j]);
				for (int t = 0; t < kHid; ++t) w[a][j][t] += lr * g * h[t];
				b[a][j] += lr * g;
			}
		}
		// 📈 **잠재 가치** — TD(종단 +1 · γ). 기존 `QPol` 과 **같은 규약**이고 입력만 `h` 다.
		void LearnV(const double* h, int a, double tgt, double lr)
		{
			const double e = tgt - V(h, a);
			for (int j = 0; j < kHid; ++j) u[a][j] += lr * e * h[j];
			c[a] += lr * e;
		}
	};

	// 🧩 **지평 빔 탐색**(D121) — 잠재 공간에서 `hz` 걸음을 펼쳐 **첫 행동**을 고른다.
	//   ⚠️ 빔 폭은 **5**(행동 수와 같다) — 손 상수를 하나 더 만들지 않으려고 그렇게 맞췄다.
	//   ★ `hz = 1` 이면 계획이 없는 것(= 잠재 Q 의 argmax) ⇒ **N−1 대조군이 같은 코드**다.
	static int _Plan(const TLat& t, const double* h0, int n, int hz)
	{
		const int nn = (n < kLA) ? n : kLA;
		if (hz <= 1)
		{
			int best = 0; double bv = t.V(h0, 0);
			for (int a = 1; a < nn; ++a)
				{ const double v = t.V(h0, a); if (v > bv) { bv = v; best = a; } }
			return best;
		}
		static constexpr int kB = kLA;
		// ⚡ **스택에서 뺀다**(D125) — `kHid = 64` 라 이 함수가 호출마다 `ch[25][64]` =
		//   **12.8KB** 를 잡고 `= {}` 로 **매번 제로초기화**했다(걸음마다 팔 셋 × 지평).
		//   ★ 단일 스레드·비재귀이고 `nb`/`nc` 만큼만 읽으므로 `static` 이 안전하다.
		//   ⚠️ 이것은 **성능 개선**이다 — 한때 크래시의 원인으로 의심했지만 **반증됐다**
		//   (static 으로 옮겨도 더 빨리 죽었다 · 진짜 원인은 **stale object** 였다 · 함정 328).
		static double bh[kB][kHid]; static double bs[kB]; static int ba[kB];
		int nb = 0;
		for (int a = 0; a < nn && nb < kB; ++a)
		{
			t.Step(h0, a, bh[nb]); bs[nb] = t.V(h0, a); ba[nb] = a; nb++;
		}
		double gam = 0.9;
		for (int st = 1; st < hz; ++st)
		{
			static double ch[kB * kLA][kHid]; static double cs[kB * kLA];
			static int ca[kB * kLA];
			int nc = 0;
			for (int i = 0; i < nb; ++i)
				for (int a = 0; a < nn; ++a)
				{
					t.Step(bh[i], a, ch[nc]);
					cs[nc] = bs[i] + gam * t.V(bh[i], a);
					ca[nc] = ba[i]; nc++;
				}
			// ★ 상위 `kB` 만 남긴다(부분 선택 정렬 — 25개라 이것이 가장 싸다).
			const int keep = (nc < kB) ? nc : kB;
			for (int k = 0; k < keep; ++k)
			{
				int bi = k;
				for (int m = k + 1; m < nc; ++m) if (cs[m] > cs[bi]) bi = m;
				if (bi != k)
				{
					const double sv = cs[k]; cs[k] = cs[bi]; cs[bi] = sv;
					const int av = ca[k]; ca[k] = ca[bi]; ca[bi] = av;
					for (int j = 0; j < kHid; ++j)
						{ const double hv = ch[k][j]; ch[k][j] = ch[bi][j]; ch[bi][j] = hv; }
				}
			}
			nb = keep;
			for (int k = 0; k < nb; ++k)
			{
				bs[k] = cs[k]; ba[k] = ca[k];
				for (int j = 0; j < kHid; ++j) bh[k][j] = ch[k][j];
			}
			gam *= 0.9;
		}
		int best = 0;
		for (int k = 1; k < nb; ++k) if (bs[k] > bs[best]) best = k;
		return ba[best];
	}

	// 📈 **선형 Q**(D102) — 「이 행동이 **결국** 목표에 닿게 하나」. 예측기와 **같은 크기**다.
	//   ⚠️ 예측기(`PPol`)는 「**한 걸음** 나아짐인가」를 배운다 — 같은 구조, **다른 목표**.
	// ══════ 🔬 **D127 — 판정을 구간별로: 뒤집힘을 놓치지 않는다** ══════
	// ⛔ D126 의 판정문이 **`B` 만 보고** 「막힘이 더 낫다 ⇒ 기제가 아니다」를 찍었다.
	//   **틀렸다** — `H` 에서는 정반대이고 **그것이 그 판의 물음이었다**:
	//     `B`(깊이 1)  🚫 **+8.7** > 🔮 +6.8      `H`(깊이 4)  🚫 +4.5 < 🔮 **+11.3**
	//   ⚠️ 그리고 **씨앗별 부호검정은 원래 `H` 에서 잰다** ⇒ 그 숫자는 처음부터 놀람의
	//   압승(**58승 1패** ↔ 47승 11패)을 말하고 있었다 — **두 계가 다른 답을 찍었고**
	//   **나는 평균 쪽을 읽었다**(함정 330).
	// 🐛 그리고 부호검정 짝을 갈면서 **라벨을 안 갈아** 「지평 4 ↔ 지평 1」로 찍혔다
	//   (이 판에 그 팔은 **없다**) — 함정 285 의 **세 번째** 재발(함정 331).
	//
	// ★ **이 판은 그 둘을 원리적으로 막는다**(추가 비용 0 · 팔 표를 안 바꾼다):
	//   ㉠ 성분 비교를 **구간 넷 전부** 찍는다 ⇒ 뒤집힘을 놓칠 수 없다
	//   ㉡ 부호검정의 **짝 + 라벨을 한 구조체**(`SgPair`)로 묶는다 ⇒ 갈리는 것이 **불가능**
	//   ㉢ ★ 그리고 **직접 대결**을 넣는다: `H` 에서 **🔮 놀람만 ↔ 🚫 막힘만**
	//     (D126 은 각각 관측만과만 견줬다 — 직접 짝이 없었다)
	//
	// ★ **미리 등록**(팔 표를 안 바꾸므로 **배관 재현**이 관문 · 함정 304):
	//   ㉠ ♻️ 전 팔이 D126 과 **소수점까지 같다**(`kChg` 전부 0)
	//   ㉡ 🔬 **구간별 성분 우위가 그대로 나온다** — `B` 🚫 +8.7 > 🔮 +6.8 ·
	//     `H` 🔮 +11.3 > 🚫 +4.5(같은 계산이므로 **소수점까지 같아야** 한다)
	//   ㉢ ★ **`H` 직접 부호검정**(🔮 놀람만 ↔ 🚫 막힘만) — **손계산**:
	//     `p1 = 0.220 · p2 = 0.152 · n = 80`(구간 3 의 씨앗당 과제 수) ⇒ 차 평균 **5.44** ·
	//     표준편차 **4.90** ⇒ `P(이김) ≈ 0.867` ⇒ **w ≈ 48 / 유효 55 ⇒ z ≈ 5.5**
	//     ⇒ **p ≪ 0.01**. ⚠️ 짝지음 때문에 **더 클 수 있다**(독립 가정은 하한 · 함정 306)
	//   ㉣ 🔬 **깊이와 함께 뒤집히나** — `A`·`A'`(색만 · 깊이 1)에서도 `B` 처럼
	//     **🚫 막힘 ≥ 🔮 놀람** 이어야 한다(그러면 「깊이가 순서를 정한다」가 네 구간으로 선다)
	//   ★ 갈림: ㉣ 가 ⛔(얕은 구간에서 놀람이 낫다)면 갈리는 축이 **깊이가 아니라 다른 것**
	//     (예: 목표가 색인가 자리인가)이고, 그러면 그 축을 찾는 판으로 간다.

	// ══════ 🔬 **D126 — 흡수의 주인은 누구인가: 성분을 갈라 잰다** ══════
	// ✅✅ D124·D125 가 **흡수를 확인**했다: 비트를 켜니 `B` 에서 📈 관측만은 **76.8 → 72.0**
	//   (−4.8%p)인데 📈 🚫+🔮 둘 다는 **86.5 → 86.7**(+0.2%p) ⇒ 손해를 **완전히 흡수**했다
	//   (씨앗별 flip1 **57승 1패** · z 7.35).
	// ⚠️ 그런데 **기제는 미결**이다 — 「이득이 `flip=1` 에 몰리나」의 차가 **+1.2 / +1.5%p** 로
	//   방향만 맞고 문턱(2.9) 미만이었다.
	//
	// ★ **손계산이 설계를 갈게 했다.** 「차의 차」 짝지은 부호검정을 계산해 보니:
	//   씨앗당 `B`·flip 별 표본 ≈ 40 ⇒ `d1 − d0` 의 SD ≈ **0.09**, 참값 ≈ **+0.012**
	//   ⇒ `P(이김) ≈ 0.553` ⇒ 60 씨앗에서 **z ≈ 0.8** ⇒ z 1.96 을 얻으려면 **씨앗 ~390**
	//   (≈90분). ⇒ ★ **그 축은 지금 규모로 판정 불가능하다** ⇒ **효과가 큰 축으로 갈아탄다.**
	//
	// ★ **갈아탄 축: 성분을 갈라 흡수의 주인을 찾는다.**
	//   기제가 참(놀람이 숨은 비트의 어긋남을 잡는다)이면 **🔮 놀람만으로도 흡수**해야 하고
	//   **🚫 막힘만으로는 덜** 해야 한다. 그것은 **5%p 대역의 큰 효과**이고 **깨끗한 N−1** 이다
	//   (한 성분씩만 다르다). ⇒ 팔 번호를 지켜 `arm 0·1·5·6·7` 은 **비트 재현**.
	//
	// ★ **미리 등록**(구간 4,800 ⇒ 차이 문턱 **1.4%p** · 구간×flip 2,400 ⇒ **2.0%p**):
	//   ㉠ ♻️ **비트 재현** — `arm 0·1·5·6·7` 이 D125 와 소수점까지 같다
	//   ㉡ ★ **놀람만이 흡수하나** — `B` 에서 📈 관측만(**72.0**) 대비 **+10%p 이상**이고
	//     **flip 격차가 작다**(둘 다 높다 = 식별). ⚠️ 절대 수준을 같이 읽는다(326)
	//   ㉢ ★ **막힘만은 덜 흡수하나** — 놀람만보다 **낮다**(차가 문턱 1.4 이상)
	//     ⚠️ 비트 없는 세계(D116)에서는 `B` 놀람 83.1 ↔ 막힘 83.6 으로 **거의 같았다**
	//     ⇒ ★ **비트가 있을 때만 갈리는 것**이 기제의 시험이다
	//   ㉣ 🎯 **씨앗별** — 「놀람만 ↔ 관측만」과 「막힘만 ↔ 관측만」을 나란히(둘 다 z ≥ 2.576
	//     예상 · 그리고 **놀람 쪽이 더 크면** 기제의 증거)
	//   ㉤ 🧩 **합이 성분을 넘나**(`AND` · 286) — 둘 다가 놀람만·막힘만을 **둘 다** 넘나
	//   ★ 갈림: ㉢ 이 ⛔(막힘만이 놀람만과 같거나 낫다)면 **흡수는 놀람의 것이 아니다**
	//     ⇒ 「이력 특징 일반」이 흡수하는 것이고 D124 의 신호는 **놀람 특유가 아니다.**

	// ══════ 🔮 **D125 — 놀람 × 숨은 상태: 두 갈래가 만난다** ══════
	// ★ D124 의 뜻밖의 신호: 비트를 켜니 📈 🚫+🔮 둘 다가 `H` **22.1 → 26.4%**
	//   (**+4.3%p** · 무작위 20.2 대비 **+6.2%p**)로 **그 팔만 좋아졌다.**
	//   ★ 그리고 `B` 에서 더 선명하다 — 비트를 켜니 📈 관측만은 **76.8 → 72.0**(**−4.8%p**)
	//   인데 📈 둘 다는 **86.5 → 86.7**(**+0.2%p**) ⇒ 🚫 막힘 + 🔮 놀람이 **flip 의 손해를**
	//   **완전히 흡수했다.**
	//
	// ★ 기제 가설: 🔮 놀람은 정확히 **「예상 대비 어긋남」**이고 **숨은 비트가 그 어긋남의**
	//   **원천**이다 ⇒ 숨은 상태가 있으면 놀람이 담을 정보가 **는다**. 그리고 그 정보는
	//   **관측에 없는 것**이므로 관측만 팔은 원리적으로 못 얻는다.
	//
	// ★ **재현은 이미 로그에 있다**(전·후반 분리 · D115):
	//   판 0-a 전/후 **22.2 / 22.1** ↔ 판 1 전/후 **26.2 / 26.5** ⇒ 네 값이 두 군으로 갈린다.
	//   ⇒ 그래서 이 판이 새로 묻는 것은 **기제 하나**다: **그 이득이 `flip=1` 부분집단에**
	//   **몰려 있나.** 몰려 있으면 가설이 서고, 고르게 퍼져 있으면 **다른 원인**이다.
	//
	// ★ 세계를 **안 바꾼다** ⇒ `kChg` 전부 0 ⇒ **비트 재현이 관문**이다. 계측과 로그만 늘린다.
	//
	// ★ **미리 등록**(구간×flip = 2,400 ⇒ `σ_diff = √2·√(0.25/2400) = 1.44%p` ⇒ **2σ 2.9%p**):
	//   ㉠ ♻️ **비트 재현** — 전 팔이 D124 판 1 과 **소수점까지 같다**(계측만 늘렸다)
	//   ㉡ ★ **`B` 에서 팔마다 flip 격차가 다르다** —
	//     📈 관측만은 **격차가 작고 둘 다 72 대**(D124 실측 72.6 ↔ 71.5 = **부분집단 상쇄**),
	//     📈 둘 다는 **격차가 작고 둘 다 86 대**(= 등록 표의 「격차 작고 **둘 다 높다**」)
	//     ⇒ ★ **같은 「격차 작음」이 두 팔에서 다른 뜻**이고 그것을 가르는 것이 **절대 수준**이다
	//   ㉢ ★ **이득이 `flip=1` 에 몰려 있나** — `둘 다 − 관측만` 을 flip 별로 잰다.
	//     손계산: `B` 에서 flip=0 은 86 − 73 = **+13%p** · flip=1 은 87 − 72 = **+15%p**
	//     ⇒ **flip=1 쪽이 더 크다**(등록: 차가 **양수**). ⚠️ 차이가 문턱 2.9 미만이면
	//     **판정불가**이고 그때는 「흡수는 확인됐지만 기제는 미결」이 정확한 문장이다.
	//   ㉣ 🎯 **씨앗별 부호검정** — `flip=1` 부분집단에서 「둘 다 ↔ 관측만」(등록: z ≥ 2.576)
	//     그리고 `flip=0` 에서도 같이 찍어 **둘을 견준다**(기제면 flip=1 쪽 z 가 더 크다)
	//   ★ 갈림: ㉢ 이 **음수**면 놀람의 이득은 숨은 상태와 **무관**하고, 그러면 D124 의 +4.3%p
	//     는 **다른 원인**(예: 비트가 만든 추가 탐험)이다 ⇒ 그것을 찾는 판으로 간다.

	// ══════ 🕳️ **D124 — 트리거를 정책이 닿을 수 없는 자리로** ══════
	// ⛔⛔⛔ D123 의 감사가 잡았다(함정 320): `cFlip = (szN >= 3)` 은 **크기 행동 누적**이라
	//   켜지는 시점이 **정책에 달렸다** — 🚪 무작위(2/5) **~8걸음** · ε=40 학습 팔(0.16)
	//   **~19걸음** · 🔭 오라클(ε=0) 얕은 구간에선 **영원히 안 켜짐** ⇒ **대조군·상한선·학습**
	//   **팔이 서로 다른 노출을 겪는다.** 그리고 얕은 구간에서는 과제에 크기 행동이 필요
	//   없는데도 **탐험이 켜서 방향을 배운 팔만 손해**를 본다(🚪 균등은 `a=1`↔`a=2` 라벨
	//   교환에 **불변**이라 면역이다).
	//
	// ★ **설계 패널이 원리적 긴장을 정리했다**(5안 × 3렌즈 · 21 에이전트):
	//   트리거가 **내생적이고 관측에 없으면** 그것은 **궤적의 함수**이고 궤적 분포는 정책이
	//   정한다 ⇒ **걸음 축의 켜짐 분포는 팔마다 같아질 수 없다.** 셋 중 하나는 버려야 한다.
	//   ⇒ ★ **㉠ 내생적은 서술이고, 정책 독립은 측정의 전제다. 전제를 지킨다.**
	//   ⇒ ★ 그리고 ㉠ 은 **잃는 것이 아니라 이사한다** — 학습기 안의 **믿음**이 네 조건을
	//   다 만족한다(D93 의 최근성 흔적이 그 자리다). 그래서 이 판의 문장은
	//   *"세계에 내생적 숨은 상태를 넣었다"* 가 아니라
	//   **"세계에 외생 파라미터를 넣고 내생적 자기상태를 요구하게 만들었다"** 다.
	//
	// ★ **그리고 이 안만이 「팔 안에서 갈라 재는 계」를 만든다.** 현행 트리거로는
	//   「반전 과제」라는 **집합을 정의조차 못 한다**(비트가 궤적의 함수다) ⇒ 판정이 팔 간
	//   비교밖에 없고 그 팔들이 다른 노출을 겪는다. `tFlip` 은 **과제의 속성**이므로
	//   **한 팔 안에서 `flip=0` ↔ `flip=1` 을 갈라 찍는다** ⇒ 팔 간 교란에 **원리적으로 면역**.
	//
	// ★ **덤: 현행 오라클의 실제 버그가 같이 잡힌다.** `_OraclePick` 의 `a==3/4` 가
	//   `q2` 갱신을 **`z` 변화 검사 밖**에 둬서, `H`(시작 `cs=2`)에서 `a=4` 가 **제자리인데도**
	//   `q2` 가 올라 `s2 != s0` ⇒ 프룬을 빠져나가고, 그 잎의 `dd = dx`(dz 가 0)라 사전식
	//   `(dd, n)` 최소가 **제자리를 고른다** ⇒ `q4` 가 3 에서 클램프될 때까지 **3걸음을 태운다.**
	//   ⇒ ★ **숨은 계수기가 오라클의 정체 탈출 장치로 쓰이고 있었다**(함정 254 의 그 자리).
	//   `q` 축을 지우면 그것이 **참 자기고리**가 되어 잘린다 ⇒ 오라클이 최적으로 돌아온다:
	//   `H` 걸음 **8 → 4 + E[d] = 4 + 8/6 = 5.333**.
	//   ⚠️⚠️ 그래서 **함정 321 을 좁힌다** — *"최단 경로는 숨은 비트를 안 밟는다"* 는
	//   **이상적 최단 경로엔 참, 구현된 후퇴 지평 오라클엔 거짓**이다(그 오라클은 정체를
	//   태우면서 `szN` 을 올려 실제로 반전을 만난다).
	//
	// ★ **이 판은 축을 셋 바꾼다 — 정직하게 적는다**:
	//   ㉠ 트리거 자리 이동(의도한 축) ㉡ **`szN` 차원 삭제 ⇒ 세계에서 「정지 행동」이 사라진다**
	//   (의도 안 한 역학 변화 · 오라클 8 → 5.33 이 그 증거) ㉢ 재현 관문 배관.
	//   ⇒ ★ 그래서 **판 0-a**(`kFlipOn = false`)를 **먼저** 돌려 ㉡ 를 단독으로 잰다.
	//   ⚠️ **판 0-a 가 안 서면 판 1 의 숫자를 읽지 않는다.**
	//
	// ★ **미리 등록**(규모: 구간 4,800 · 구간×반절 2,400 · **구간×반절×flip 1,200**
	//   ⇒ `p≈0.5` 에서 `σ_diff = √2·√(0.25/1200) = 2.04%p` ⇒ **2σ 문턱 4.1%p**):
	//   ㉠ 🔭 지평 4 가 네 구간 **100.0%** · `H` 평균 걸음 **5.33**(지금 8) ·
	//     `fl=0` ↔ `fl=1` 이 **같다**(동형사상 `φ`: 행동 `1↔2` 교환 · `_XOpen` 이 행동도
	//     `cx` 도 인자로 안 받으므로 두 세계가 동형 ⇒ **깊이 4 불변**)
	//     ⚠️ 8 → 5.33 은 **예상된 변화**다 — 「재현 실패」로 오독하지 말 것
	//   ㉡ 🚪 무작위가 D123 값 **± 1.44%p**(구간 2σ) — 균등 정책은 라벨 교환에 **불변**이다
	//     ⚠️ **실현은 비트 단위로 같지 않다**(행동열은 같고 궤적이 갈린다) ⇒ 「잡음 안」이 관문
	//   ㉢ 얕은 구간이 안 움직이는 것은 **🚪 와 🔭 두 팔만**이다
	//     ⚠️ **학습 팔은 움직여도 정상**이다 — `gx ∈ {0,2}` 가 2/3 이라 클램프 때문에
	//     `a=1`/`a=2` 중 **하나는 no-op, 하나는 해**이고 **어느 쪽인지가 비트로 뒤집힌다**
	//     ⇒ 얕은 구간에서도 비트에 **기능적 결과가 있다**. 그리고 `qp` 는 씨앗마다만
	//     리셋되므로 `B` 의 오염이 `A'` 로 **반드시** 흘러간다(이 저장소가 재는 「이음매」).
	//     ⇒ ★ 이 판이 얕은 구간에서 고친 것은 「누출」이 아니라 **「팔 간 비대칭」**이다.
	//   ㉣ `B` 에서 `arm 1`(📈 Q·관측만 — 특징이 전부 0 인 **깨끗한 N−1**)의
	//     **`|flip=0 − flip=1|` 격차**를 찍는다. ⚠️ **부호를 등록하지 않는다** —
	//     `φ` 가 참이면 어느 쪽이 높은지는 `Argmax` 의 **엄격 비교(최저 인덱스 우선)**가
	//     정하므로 음수도 반증이 아니다. ⚠️ **절대 수준을 같이 읽는다**: 격차 0 이
	//     「기억이 필요없다」가 아니라 **「양쪽 다 망가졌다」**여도 같이 0 이다.
	//   ㉤ 🔢 **해시 위생** — 반전율 **50.0% ± 0.36%p** · 씨앗당 **40/80 ± 4.47** ·
	//     고유 입력 **19,200 / 19,200**(배수 **1009u**. ⚠️ 131u 면 `idx ∈ [0,320)` 보다
	//     작아 **58% 충돌**하고 씨앗별 부호검정의 독립 전제가 깨진다)
	//   ★ 갈림 — ㉠ 이 100% 아래면 **동형사상 논증이 틀렸거나 타이브레이크가 개입**했다
	//     (`_OraclePick` 은 `a=0..4` 순서로 훑고 잎을 **strict `<`** 로 고르므로 동점이
	//     **낮은 `a`** 로 깨지는데 그 규칙은 `1↔2` 교환에 **대칭이 아니다**).
	//   ★ 갈림 — ㉣ 의 격차가 0 이고 **둘 다 높으면** 관측만으로 풀린다는 뜻이다.
	//     ⚠️ 「원리적으로 불가」를 주장하지 않는다 — `_WideFeat` 에 `a9[i] − b9[i]` 와
	//     `b9[i]` 가 **같이 있어** 절대 자리가 **선형으로 복원**되고, `a=0`(색 +1)이
	//     **항상 관측을 바꾸는 5상태 레지스터**라 **세계를 스크래치패드로 쓰는** 무기억
	//     FSM 이 원리적으로 가능하다 ⇒ 그때는 `B` 에서 `a=0` **사용률**을 본다(올라가면
	//     실패가 아니라 **「세계를 기억으로 썼다」는 양성 발견**이다).

	// ══════ 🧹 **D123 — 배관 청소: 낡은 판정을 걷고 걷어 냈던 계측을 되살린다** ══════
	// ⚠️⚠️⚠️ **병렬 배관 감사**(2026-08-23 · 8축 × 적대적 검증)가 여섯 개의 결함을 잡았다.
	//   그중 **판정에 직접 거짓을 만든 것 셋**을 이 판에서 걷는다.
	//
	// ★ ㉠ **옛 D102 판정 블록이 살아서 거짓 결론을 찍고 있었다.**
	//   `kA_Q9 = 2 · kA_Q99 = 3 · kA_Q5 = 4` 인데 지금 그 팔들은 🧩 **잠재 계획 지평 1·2·4**
	//   이고 `kAGam` 이 **셋 다 0.9**(γ 는 벌려진 적이 없다) · `kAQ` 가 **셋 다 0**(화소 Q 를
	//   안 쓴다). ⇒ ㉡ 「γ 축이 갈리나」는 **원리적으로 못 틀리는 시험**이고 ㉣ 「로지스틱」은
	//   `kARol` 이 전부 0 이라 **존재하지 않는 팔**이다.
	//   ⚠️⚠️ 그리고 헤드라인이 `hQBest = max(arm2, arm3, arm5)` **셋 중 최대**를 **단일비교**
	//   **문턱**으로 재서 **✅✅✅ 「감쇠가 깊이를 담았다」**를 찍었다 — 그 승자는 arm 5
	//   (🚫+🔮 둘 다)이고 그 팔의 우위는 **감쇠가 아니라 특징공학**에서 온다.
	//   ★ **진짜 감쇠 대조군은 arm 1(γ=0.9) ↔ arm 0(γ=0.0)** 이고 그 값은 **10.5 ↔ 20.0%**
	//   = **감쇠 쪽이 더 나쁘다** ⇒ **정답은 ⛔ 인데 ✅✅✅ 이 찍혔다.**
	//   ⇒ ★ 함정 285 가 `kAN[]` 로 막은 자리를 **서식 문자열의 글자 이름**이 새로 뚫었다.
	//
	// ★ ㉡ **「자기 분포」 관문이 한 번도 학습되지 않은 `qp[2]` 를 읽고 있었다.**
	//   `if (arm == 0 || arm == 2)` 로 팔을 **번호로** 잡는데 `kAQ[2] = 0` 이라 `qp[2]` 는
	//   영원히 0 이고 `QPol::Argmax` 는 동점에서 **항상 0(색+1)** 을 돌려준다 ⇒ 그 값은
	//   「오라클이 색+1 을 고른 비율」이라는 **상수**이고, 거기에 **「함정 259 확인」 도장**이
	//   찍혔다. ⇒ 그 물음(예측 argmax 가 오라클과 맞나)은 **함정 256 으로 이미 닫혔다** ⇒ 걷는다.
	//
	// ★ ㉢ **죽은 계수기가 살아 있는 것과 한 글자 차이로 나란히 있었다.**
	//   `dcN`/`dcOk`/`dcCtl`(D103) ↔ `dcN2`/`dcC2`/`dcO2`(D120). 앞의 셋은 D120 에서 증가문을
	//   걷었는데 **선언과 계산이 남아** `dcA`/`dcCA` 를 0 으로 만들고 있었다(찍히지도 않는다).
	//   ⇒ 함정 288 이 그대로 재현될 자리다 ⇒ 걷는다.
	//
	// ★ ㉣ **그리고 걷어 냈던 계측을 되살린다 — 이게 더 중요하다.**
	//   D120 이 상상 관문 로그를 갈아 낼 때 **절대오차**(`aB`/`aD`)와 **밀도**(`nSg`/`nBlk`/
	//   `nSur`)의 출력이 **딸려 죽었다.** 계수기는 계속 돌지만 **읽는 곳이 0개**다.
	//   ⚠️⚠️ 그 결과 나는 D121 기록에 **D116 시절 값**(절대오차 0.454 ↔ 0.774 · 밀도
	//   81.9 ↔ 9.4)을 **현재 값처럼** 적었다 ⇒ **측정을 로그에서 걷어 내면 그 값을 「기억」으로**
	//   **인용하게 된다.** ⇒ 되살린다.
	//
	// ★ **미리 등록**:
	//   ㉠ ♻️ **비트 재현이 완전해야 한다** — 삭제와 로그 추가는 **행동을 안 바꾼다**
	//     ⇒ 전 팔이 D122 와 **소수점까지 같다**(그것이 이 판의 유일한 관문이다).
	//     ★ 안 같으면 **걷어 낸 것 중에 살아 있던 것이 있다**는 뜻이다.
	//   ㉡ 📏 **밀도가 되살아난다** — `H` 관측만에서 🚫 막힘 ~82% ↔ 🔮 놀람 ~9%(D114 값 대역)
	//     ⚠️ 다르면 그 사이 판들이 밀도를 바꿨다는 뜻이고 **그것 자체가 사실**이다.
	//   ㉢ 🧩 **절대오차가 되살아난다** — 깊이 1~4 에서 상상 < 안 변한다
	//     ⚠️ `kGF` 가 100 → 169 로 커졌으므로 **절대값은 D116 과 다를 것**이다(차원이 늘면
	//     노름이 는다) ⇒ **비율**로 본다.
	//   ★ 갈림: ㉠ 이 ⛔ 면 **걷은 것이 판정에 살아 있었다**는 뜻이고, 그러면 어느 것이
	//     살아 있었나를 **하나씩 되돌려** 찾는다.

	// ══════ 🧠 **D122 — 은닉을 넓힌다: 표현의 손실을 갚는다** ══════
	// ★ D121 이 원인을 갈라 냈다(함정 314): **계획은 값을 했는데**(🎯 지평 2 ↔ 1 =
	//   36승 16패 · z **2.77**) **총합이 4배 나빴다**(`H` 5.9 ↔ 23.5%). 그 진단이 가능한
	//   이유는 **`B`(깊이 1 · 계획이 필요 없는 구간)에서도 나빴다**는 것이다
	//   (69.2 ↔ 78.8% = **−9.6%p**) ⇒ 그 차이는 **순전히 121칸 → 16칸 압축의 대가**다.
	//
	// ★ 그래서 이 판은 **은닉만 16 → 64** 로 늘린다. **다른 것은 아무것도 안 바꾼다** —
	//   지평 1·2·4 를 그대로 두어 **같은 자로 계단을 다시 잰다**(함정 243 「한 판에 한 축」).
	//
	// ★ **비용을 손으로 쟀다**:
	//   `MPol.W1` = 64 × 121 = **7744**(16칸의 4배) · `TLat` = 5 × 64² = **20480**
	//   계획 = 100 × 64² = **4.1e5 곱셈/결정** ⇒ 화소 공간(**3.7e7**)의 **1/90** ⇒ 감당된다.
	//   ⚠️ 특징 칸도 늘어난다: `kGF` = 100 + 5 + **64** = **169**(묶음 13 은 그대로).
	//   ⚠️ 그래서 **화소 Q·예측기의 파라미터도 늘고** 옛 팔의 비트 재현은 **깨진다** —
	//   이번엔 그것을 **감수한다**(대신 D121 과 값을 나란히 찍어 얼마나 흔들렸나를 본다).
	//
	// ★ **미리 등록**:
	//   ㉠ ★ **`B` 에서 격차가 줄어든다**(표현이 먼저다) — 잠재 지평 1 이 **69.2 → ≥ 74%**
	//     (관측만 78.8 과의 격차 −9.6 → **≥ −5%p**). ⇒ 안 줄면 **압축이 원인이 아니다.**
	//   ㉡ 🧩 `H` **지평 계단이 문턱 이상**으로 선다(D121 은 +1.3 / +0.3 · 문턱 1.6)
	//   ㉢ 🎯 **씨앗별 z 가 커진다**(지평 2 ↔ 1: 2.77 → **≥ 3.0**)
	//   ㉣ ⚠️ **절대 성적은 여전히 「둘 다」를 못 넘는다**(등록: 못 넘는다 — 4배가 2배로
	//     줄어들면 방향이 맞는 것이다)
	//   ㉤ ♻️ 옛 팔은 **비트 재현이 깨진다** — 다만 흔들림이 **차이 문턱(1.6%p) 안**이어야
	//     한다(그것을 넘으면 `kGF` 변경이 옛 결론을 위협한다는 뜻이고 따로 적어야 한다)
	//   ★ 갈림: ㉠ 이 ⛔ 면 원인은 **압축이 아니라 목표**다(전이를 재구성으로 기른 것) ⇒
	//     함정 268 의 처방(가치의 순위)으로 간다.

	// ══════ 🧩 **D121 — 잠재 공간에서 계획한다** ══════
	// ★ D120 이 관문을 닫고 방향을 지목했다: 결정 일치율은 **상한이 5.9%p** 이고 그중
	//   **46%가 이미 먹혔다**(함정 313) ⇒ 관문을 **성적 그 자체**로 옮긴다
	//   (🚪 무작위 **20.0%** ↔ 🔭 오라클 **100.0%** = **상한 80%p**).
	//
	// ★ 그리고 **비용이 설계를 정했다** — 화소 공간 지평 4 전탐색은 **3.7e7 곱셈/결정**
	//   이라 감당 못 하고, **잠재 공간**(`kHid` 16칸)은 **256 곱셈**으로 **57배 싸다**.
	//   ⇒ ★ **D119 가 만든 은닉의 진짜 쓸모**가 여기다(특징으로는 값을 못 했다 · 함정 310).
	//
	// ★ 무엇을 새로 두었나 — `TLat`: **전이** `h' = tanh(W[a]h + b[a])` + **가치 머리**
	//   `v[a] = u[a]·h + c[a]`. 전이 초기값은 **항등 + 작은 산포**라 처음엔 「안 변한다」에서
	//   출발한다(대조군과 **같은 출발점**). 학습은 재구성(전이) + TD(가치)로 **둘 다**.
	//   계획은 `_Plan` — **빔 폭 5**(행동 수와 같게 맞춰 손 상수를 하나 안 만들었다).
	//
	// ★ **판정은 지평 계단이다**(N−1) — 절대 성적이 아니라 **1 < 2 < 4** 인가.
	//   ⚠️ 잠재 Q 는 121칸을 16칸으로 압축해 보므로 **절대 성적은 낮을 수 있다.** 그래도
	//   **계단이 서면 「계획이 값을 한다」**가 선다 — 그것이 이 판의 물음이다.
	//   ★ 팔 번호를 지켰다 ⇒ `arm 0·1·5·6·7` 은 **비트 재현**(새 팔은 `arm 2·3·4`).
	//
	// ★ **미리 등록**:
	//   ㉠ ♻️ **비트 재현**(새 팔 셋 제외 · 최대 오차 ≤ 0.05%p)
	//   ㉡ ★ **지평 계단** — 잠재 Q 지평 1 < 지평 2 < 지평 4(각 단이 **차이 문턱 이상**)
	//   ㉢ ⚠️ **지평 3 이 아니라 4 에서 계단이 끝난다** — 세계의 의존 깊이가 4 이므로
	//     (D100 의 오라클 지평 훑기) **지평 4 가 지평 2 보다 훨씬 커야** 한다
	//   ㉣ 🎯 **씨앗별 부호검정**(지평 4 ↔ 지평 1)에서 z ≥ 1.96
	//   ㉤ ⚠️ **절대 성적은 「둘 다」(23.5%)를 못 넘을 것이다**(16칸 압축의 대가) — 그것이
	//     ⛔ 라도 계단이 서면 **다음 판은 압축을 늘리는 것**이다(등록: 못 넘는다)
	//   ★ 갈림: 계단이 안 서면 **잠재 전이가 세계를 못 담는 것**이고, 그러면 전이의 목표를
	//     재구성에서 **가치의 순위**로 옮긴다(함정 268 의 처방).

	// ══════ ⚖️ **D120 — 관문을 깊이별로: 상한을 먼저 찍는다** ══════
	// ⚠️⚠️ D103 의 결정 관문은 **한 걸음**을 물었고 대조군(「안 변한다」)이 **95.0%** 였다
	//   ⇒ **상한이 5%p** 다 ⇒ 아무리 좋아져도 **아무 말도 못 한다**(함정 269).
	//   ⇒ ★ 그래서 D119 의 처방(목표를 갈아 끼운다)을 **하기 전에 관문을 고쳐야** 한다 —
	//   개선을 재도 안 보이는 자리에서 목표를 갈면 그 판이 **원리적으로 판정불가**다.
	//
	// ★ 처방은 **깊이**다: `dd` 걸음 전 상태를 그대로 두면(대조군) `dd` 가 커질수록
	//   결정이 어긋날 여지가 커진다 ⇒ **상한이 커진다.** ⇒ 관문을 **깊이 1~4 전부** 찍고
	//   **대조군을 나란히** 둔다. ★ 이 판은 **상상기를 안 고친다**(옛 오차 목표 그대로) —
	//   **자를 먼저 만들고 그 자로 옛것을 재는 판**이다.
	//
	// ★ 그리고 **씨앗별 부호검정**을 깊이 4 에 붙인다(함정 309: 평균만 보면 안 된다).
	//
	// ★ **미리 등록 — 손계산**:
	//   ㉠ ♻️ 학습 팔 여덟은 **비트 재현**(관문 계측만 늘렸다 · 최대 오차 ≤ 0.05%p)
	//   ㉡ ⚖️ **대조군이 깊이와 함께 떨어진다** — 깊이 1 **~95%**(D116 실측) →
	//     깊이 4 **≤ 88%** ⇒ **상한 ≥ 12%p**(관문이 쓸 만해지는 조건)
	//   ㉢ ★ **깊이 4 에서 상상이 대조군을 넘는다** — 절대오차가 이미 크게 갈렸으므로
	//     (상상 0.454 ↔ 안 변한다 0.774) 결정에서도 갈릴 것이다
	//   ㉣ 🎯 **씨앗별 부호검정**(깊이 4)에서 z ≥ 1.96
	//   ★ 갈림: ㉡ 이 ⛔(깊이 4 에서도 대조군 ~95%)면 **결정 일치율 자체가 못 쓰는 자**이고
	//     관문을 **다른 축**(예: 계획의 성적 그 자체)으로 옮겨야 한다.
	//   ★ 갈림: ㉢ 이 ⛔ 면 **옛 목표(오차)로 기른 상상은 결정에 못 닿는다**가 확정되고,
	//     그것이 D103 의 모순(함정 268)을 **깊이 4 에서 재확인**하는 것이다 ⇒ 목표 교체로 간다.

	// ══════ 🧠 **D119 — 잠재 상태의 씨앗: 은닉층을 특징으로** ══════
	// ★ D118 로 벽이 하나 남았다: 🔭 오라클 `H` **100.0%** ↔ 학습 최고 **23.5%**.
	//   ⚠️ 그런데 **계획 앞에 상상**이 있고 **상상 관문이 ⛔** 다(상대오차 77.6% · 결정
	//   일치율이 대조군과 겹친다 · 함정 267) ⇒ **상상 앞에 잠재 상태**가 있다.
	//
	// ★ D118 이 재료를 주었다 — 🔮 예측기의 **놀람이 값을 한다**(z 6.12)는 것은 그 예측기가
	//   **쓸 만한 신호를 이미 갖고 있다**는 뜻이다. ⇒ 그 예측 과제로 **은닉층**을 기르고
	//   그 은닉 벡터를 **다음 걸음의 특징**으로 되먹인다 ⇒ **이름 없는 잠재 상태**다.
	//
	// ★ **원리적 대조군을 같은 판에 둔다**(규율 13 의 짝) — 「🔮 예측 벡터 날것」 팔은
	//   **원리적으로 이길 수 없다**(선형의 선형 ⇒ Q 가 얻을 새 정보가 0). ⇒ 그 팔이 이기면
	//   **배관이 새는 것**이고, 0 이면 배관이 맞다는 증거다.
	//
	// ★ **팔 번호를 지켰다** — `arm 0·1·5·6·7` 이 D118 과 같은 역할이므로 그 다섯은
	//   **비트 단위로 재현**되어야 한다(함정 302). 새 팔은 `arm 2·3·4` 다.
	//
	// ★ **미리 등록**:
	//   ㉠ ♻️ **비트 재현** — `arm 0·1·5·6·7` 이 D118 과 같다(최대 오차 ≤ 0.05%p)
	//   ㉡ 🔍 **관문 두 겹**(303) — 🧠 은닉 특징이 **0 이 아니고** 🚫+🔮(3.38) 대역에 든다
	//   ㉢ ★ **원리적 대조군** — 🔮 예측 벡터 날것이 관측만 대비 **부호검정 판정불가**
	//     (z < 1.96). ⇒ 이기면 배관이 샌다.
	//   ㉣ ★ **은닉만이 관측만을 이긴다** — 부호검정 z ≥ 1.96(등록: **약하게 이긴다** ~2)
	//   ㉤ ★ **은닉+둘 다가 둘 다를 이긴다** — 부호검정 z ≥ 1.96
	//     ⇒ ★ 이것이 이 회차의 물음이다: **잠재 상태가 관측 특징 위에 무엇을 더하나.**
	//   ★ 갈림: ㉤ 가 ⛔ 면 **한 겹 은닉으로는 부족**하다는 뜻이고, 그러면 상상(전이 모델)을
	//     **먼저** 고쳐야 한다 — 잠재 상태를 **예측 과제**로 기르는 것이 약한 것이다.

	// ══════ 🎯 **D118 — 씨앗별 부호검정으로 돌파를 판정한다** ══════
	// ⚠️ D117 이 도구를 지목했다(함정 305): **반쪽 나누기는 재현을 주지만 문턱을 √2 배로**
	//   **키우고 대조군도 흔들린다**(무작위 전 20.9 ↔ 후 19.2 = 1.7%p) ⇒ 경계선
	//   (`둘 다` 23.5 ↔ 🚪 무작위 20.0)은 그 도구로 못 가른다.
	//
	// ★ **처방은 이 저장소의 규율에 이미 있다 — 씨앗별 부호검정.** 씨앗마다 두 팔을
	//   견줘 **이긴 씨앗을 센다** ⇒ 크기가 아니라 **방향의 일관성**을 재므로 대조군의 흔들림에
	//   **면역**이다(같은 씨앗 안에서 비교하니까). ⇒ ★ **추가 실행 비용이 0** 이다.
	//   ⚠️ 동점은 **제외**한다(부호검정의 표준) ⇒ 유효 표본이 줄고 그것도 찍는다.
	//   판정: `z = (w - n/2) / sqrt(n/4)` · **z ≥ 1.96** ⇒ p < 0.05 · **z ≥ 2.576** ⇒ p < 0.01.
	//
	// ★ **팔 표를 안 바꿨다** — 그래서 **전 팔이 D117 과 비트 단위로 같아야 한다.**
	//   ⇒ 그것이 이 판의 **관문**이고, 새 계측이 옛 결과를 안 흔들었다는 증거다(함정 304 의
	//   「배관 재현」).
	//
	// ★ **미리 등록 — 손계산으로 수치까지 적는다**(씨앗당 `H` 표본 ≈ 39):
	//   ㉠ ♻️ **배관 재현** — 전 팔이 D117 과 같다(최대 오차 ≤ 0.05%p)
	//   ㉡ 🔮 **놀람 정규화 ↔ 관측만**: p1=0.220 · p2=0.105 ⇒ 차 평균 4.5 · 표준편차 3.2
	//     ⇒ P(이김) ≈ 0.92 ⇒ **w ≈ 53 / 유효 57 · z ≈ 6.5** ⇒ **p ≪ 0.001**
	//   ㉢ ★ 🚫+🔮 **둘 다 ↔ 무작위**: p1=0.235 · p2=0.200 ⇒ 차 평균 1.37 · 표준편차 3.64
	//     ⇒ P(이김) ≈ 0.65 ⇒ **w ≈ 35 / 유효 53 · z ≈ 2.3** ⇒ ★ **p < 0.05 는 넘고**
	//     **p < 0.01 은 못 넘는다**(그것이 이 회차의 핵 예측이다)
	//   ㉣ 🚫 **막힘 정규화 ↔ 관측만**(+5.4%p) — 넘는다(p < 0.01 대역)
	//   ㉤ 🚫 **막힘 정규화 ↔ 막힘 날것**(+1.85%p): 차 평균 0.7 · 표준편차 3.15
	//     ⇒ P ≈ 0.59 ⇒ **w ≈ 32 · z ≈ 1.3** ⇒ **p < 0.05 미달**(판정불가 대역)
	//   ★ 갈림: ㉢ 이 **p < 0.01 을 넘으면** 손계산이 보수적이었던 것이고, **p < 0.05 도 못**
	//     **넘으면** 돌파는 없다 ⇒ 어느 쪽이든 **숫자가 문장을 정한다**.

	// ══════ 🧪 **D117 — 가설을 반증하려 한다 + 무작위 돌파의 재현** ══════
	// ★ D116 이 둘을 남겼다: ㉠ **무작위를 넘었다**(둘 다 23.5 ↔ 20.0%) 그런데
	//   **재현을 못 봤다**(무작위 팔의 반쪽 값을 안 찍었다) ㉡ **함정 300**(*드문 신호는
	//   스케일이 작아서 못 배운다*)이 **반증 가능한 예측**을 낸다.
	//
	// ★ **그 예측이 이 판의 핵이다** — 정규화는 **드문 신호에만** 들어야 한다.
	//   🚫 막힘의 밀도는 **82%** 이므로 같은 식의 배율이 `0.1/(0.01+0.82)` = **x1.2** 다
	//   ⇒ **거의 안 변해야 한다.** ⚠️ **변하면 가설이 틀린다** — 그러면 답은 「정규화」가
	//   아니라 **「그 칸의 학습률을 올린 것」**이고, 그건 전혀 다른 이야기다.
	//   ⇒ ★ 반증 가능한 예측을 **그 가설이 세운 판에서** 시험한다.
	//
	// ★ **팔 번호를 역할에 고정했다**(함정 302 처방) — `arm 0·1·2·4·5` 가 D116 과
	//   **같은 역할**이고 시드가 `(sd, arm, idx)` 이므로 그 다섯 팔은 **비트 단위로 재현**된다.
	//   ⇒ 새 팔은 **`arm 3`(🚫 막힘 정규화) 하나**다. ⇒ 귀속이 완전하다.
	//
	// ★ **미리 등록**:
	//   ㉠ 🔍 **관문 두 겹**(303) — 🚫 정규화 특징이 날것의 **1.1~1.5배**(예측 x1.2) ·
	//     🔮 정규화는 막힘 대역(1~3)
	//   ㉡ ♻️ **완전 재현** — `arm 0·1·2·4·5` 가 D116 과 **소수점까지 같다**
	//     (무작위 20.0 · 관측만 10.5 · 막힘 날것 14.1 · 놀람 정규화 22.0 · 둘 다 23.5)
	//     ⇒ 그것 자체가 함정 302 의 확인이다
	//   ㉢ ★ **「둘 다」가 무작위를 전·후반 둘 다 넘는다**(D116 의 유일한 미결)
	//   ㉣ ★ **반증 시험** — 🚫 정규화 − 🚫 날것이 **차이 문턱 미만**(거의 안 변한다)
	//   ㉤ 🔮 놀람 정규화가 **또 재현**(D116 +12.2 / +10.8)
	//   ★ 갈림: ㉣ 에서 막힘 정규화가 **크게 오르면** 함정 300 은 **틀렸다** ⇒ 「밀도」가 아니라
	//     **「특징 칸별 학습률」**이 진짜 축이고, 그러면 그것을 **직접** 다뤄야 한다.

	// ══════ 🔮 **D116 — 놀람을 자기 밀도로 정규화한다** ══════
	// ★ D115 가 기제를 지목했다(함정 300): 🔍 특징 평균 절대합이 🚫 막힘 **1.994** ↔
	//   🔮 놀람 **0.258**(**7.7배**)이고 그 비가 밀도 비(81.9/9.4 = **8.7배**)와 거의 같다
	//   ⇒ **드문 신호는 입력 자체가 작아서** 같은 학습률에서 가중치가 그만큼 못 큰다.
	//   ⇒ 그래서 놀람이 못 넘은 것이 **신호가 없어서인지 스케일 때문인지 아직 안 갈렸다.**
	//
	// ★ 처방 — 특징을 **자기 놀람율로 나눈다**. 그 율은 **그 팔이 스스로 온라인 누적**하므로
	//   **세계가 준 것도 아니고 우리가 박은 값도 아니다** ⇒ 폐회로다.
	//     `sRate[arm] += 0.001 * (sur - sRate[arm])`   (씨앗마다 **0.5 에서** 시작)
	//     `f[95+k] = surA[k] * 0.1 / (0.01 + sRate[arm])`
	//   ⚠️ `0.01` 은 **손 상수**다(0으로 나눔 막이 · 배율 상한 100). 그것 말고는 손이 없다.
	//   ★ 초기값 0.5 로 시작하는 이유: 0 에서 시작하면 첫 걸음이 **x100** 으로 폭발한다.
	//
	// ★ **N−1 대조군이 같은 판에 있다** — 팔 3(정규화 안 한 놀람 행동별) ↔ 팔 4(정규화).
	//   그 둘은 **정규화 하나만** 다르다 ⇒ 귀속이 성립한다(함정 243).
	//
	// ★ **미리 등록**:
	//   ㉠ 🔍 **관문** — 정규화 팔의 특징 크기가 **비정규화의 5배 이상**이고 🚫 막힘 대역
	//     (**1~3**)에 든다. ⇒ 안 그러면 정규화가 안 걸린 것이고 아래는 **판정불가**다.
	//   ㉡ 🔭 지평 4 가 `H` **100%** · 📈 관측만이 무작위를 **못 넘는다**
	//   ㉢ 🚫 **막힘 행동별이 또 재현된다** — 전·후반 둘 다(D115 는 +5.8 / +4.2)
	//   ㉣ ★ **정규화가 값을 한다** — 정규화 팔이 **비정규화 팔보다** 전·후반 둘 다 문턱 이상
	//   ㉤ ★ 그래도 **막힘을 못 넘는다**(등록: 못 넘는다 — 막힘은 밀도도 크고 정보도 많다)
	//   ㉥ 🧩 **둘 다**(막힘 행동별 + 정규화 놀람)가 막힘 단독을 넘나 — ⚠️ `AND`(286)
	//   ★ 갈림: ㉣ 가 ⛔ 면 **놀람 축을 닫는다** — 스케일이 아니라 **신호가 없는 것**이고,
	//     그러면 남은 것은 **계획**이다(🔭 오라클 100% ↔ 학습 최고 15.5%).
	//   ⚠️ 모든 `AND` 판정에 **「판정불가」 분기**를 둔다(함정 301).

	// ══════ 🎲 **D115 — 배관을 고치고 다시 잰다** ══════
	// ⛔⛔⛔ D114 가 **앞 두 판의 무효**를 잡았다(함정 295: 막힘 특징이 0 이었다) 그리고
	//   **대조군 자체가 움직인다**는 것도(함정 296: 팔이 난수 스트림을 공유한다).
	//   ⇒ **배관 셋을 고치기 전에는 어떤 판정도 못 믿는다.**
	//
	// ★ ㉠ 🎲 **팔마다 씨앗을 다시 뿌린다**(296) — `(sd, arm, idx)` 로 시드하므로 한 팔을
	//   고쳐도 다른 팔의 표본이 **비트 단위로 같다**. ⚠️ `idx` 를 넣어야 한다 — 안 넣으면
	//   같은 팔이 **과제마다 같은 난수열**로 시작해 탐험이 복제된다.
	//   ★ 과제 자체는 이미 안전하다 — **먼저 전부 뽑아 둔다**(함정 213).
	// ★ ㉡ 🔍 **특징이 0 이 아님을 찍는다**(295) — 「주었다」와 「값이 들어갔다」는 다른
	//   사실이다. 켠 팔의 이력 칸 절대합 평균을 팔마다 누산해 로그에 낸다.
	//   ⇒ ★ **그것이 관문이다** — 0 이면 그 팔의 판정은 **판정불가**다.
	// ★ ㉢ ♻️ **재현을 한 판 안에** — 씨앗 **60** 을 **전반 30 / 후반 30** 으로 따로
	//   집계하면 **한 판에서 두 독립 판정**이 나온다(「부분집단을 미리 정해 둔다」의 적용).
	//   ⇒ D114 가 알려 준 것이 정확히 이것이다: **한 판의 통과는 후보이고 재현이 선 것이다.**
	//
	// ★ 팔 여덟을 **짝 맞춰** 놓았다 — 🚫 막힘(합·행동별) ↔ 🔮 놀람(합·행동별).
	//   🔢 카운터는 **네 판 재현**됐으므로(D111~D114) **팔 예산에서 뺀다**.
	//
	// ★ **미리 등록**:
	//   ㉠ 🔭 오라클 지평 4 가 `H` **100%** · 📈 관측만이 무작위를 **못 넘는다**
	//   ㉡ 🔍 **켠 팔의 특징이 전부 0 이 아니다**(배관 관문 — 이것이 먼저다)
	//   ㉢ 🚫 **막힘이 전·후반 둘 다** 차이 문턱을 넘는다(D114 의 +4.7%p 재현)
	//   ㉣ 🔮 **놀람이 막힘을 못 넘는다**(D114 재현 · 이번엔 합↔합 · 행동별↔행동별)
	//   ㉤ ★ **갈라 두기가 양쪽에서 값을 한다** — 행동별 > 합 (막힘도 놀람도)
	//   ★ 갈림: 전·후반이 **부호가 갈리면** 그 항목은 **판정불가**로 적는다(효과가 아니라
	//     측정 못 함이다 · 함정 291).

	// ══════ 🔮 **D114 — 놀람: 「예상보다 더 막혔나」** ══════
	// ★ D113 이 「막힘」을 닫았다: 🔭 **오라클(=정답)** 의 막힘율이 `A`·`A' `에서 **100%**
	//   이고 `H` 에서 **68.1%** 다 ⇒ **올바른 걸음이 「제자리」로 보인다**(함정 290) ⇒ 갈라도
	//   안 됐다(행동별 5칸 **−1.2%p**). 기제는 **뭉갬이 아니라 포화**였다(함정 292).
	//
	// ★ 처방은 **기준선을 빼는 것**이다 — 「막혔나」가 아니라 **「예상보다 더 막혔나」**.
	//   그리고 그 「예상」은 **손 상수가 아니라 자기 예측기**다(🔮 `prd[arm]` · `H` recall 59.7%)
	//   ⇒ 특징이 **자기 모델의 오차**가 되므로 **폐회로**이기도 하다.
	//
	// ★ **설계의 핵심은 「하나만 다르게」다** — 놀람을 막힘과 **같은 자리**(같은 `sgF`
	//   블록) · **같은 꼴**(0/1 이진 · `+1` 누적 · 같은 배율 0.1) 로 두었다. ⇒ 두 신호의
	//   차이는 **밀도 하나**다(막힘 ~70% ↔ 놀람 ~10%) ⇒ **함정 292 의 직접 시험**이 된다.
	//
	// ★ `kALrn` 을 **전 팔에서 켠다** — 예측기가 특징의 **재료**이고, 🔭 오라클 팔의 것은
	//   **「정상 경로의 놀람율」**을 재는 계다(특징으로는 안 쓴다 · `kASur[6..7] = 0`).
	//   ⚠️ 예측기는 팔마다 따로(`prd[arm]`)라 서로 오염되지 않는다.
	//
	// ★ **미리 등록**:
	//   ㉠ 🔭 오라클 지평 4 가 `H` **100%**(상한선 고정)
	//   ㉡ 📈 관측만이 무작위를 **못 넘는다**(대조군)
	//   ㉢ 🔢 카운터가 **네 판 연속** 재현(`H` ~+4.6%p · 차이 문턱)
	//   ㉣ 📏 **밀도가 갈린다** — `H` 에서 🔮 놀람 **~10%** ↔ 🚫 막힘 **~70%**
	//     ⇒ 손계산의 근거: 예측기 정확도가 `H` 에서 **90.2%**(D113) 이므로 틀리는 걸음이 ~10%.
	//   ㉤ ★ 🔮 **놀람 합이 🚫 막힘 합보다 낫다** — 밀도만 다르므로 이것이 292 의 시험이다
	//   ㉥ ★ 🔮 **놀람 행동별이 관측만 대비 차이 문턱 이상**
	//   ★ 갈림: 놀람도 값을 못 하면 **「실패를 특징으로 주는 길」 자체가 이 세계에서 안 된다**
	//     ⇒ 남는 것은 **계획(상상)** 뿐이다 ⇒ 📌 를 그쪽으로 옮긴다.

	// ══════ 🚫 **D113 — 막힘을 행동별로: 뭉갬을 푼다** ══════
	// ★ D112 가 원인을 지목했다: 막힘 누적이 `B` 에서는 **+3.1%p** 인데 `H` 에서는
	//   **−2.5%p** 였고, 기제는 **`H` 는 깊이 4 라 정상 경로에도 막힘이 많다**는 것이다
	//   (크기를 `2→0` 로 내리는 두 걸음이 `d` 를 키우므로 **막힘으로 세어진다**).
	//   ⇒ **`flip` 신호가 그 잡음에 묻혔다.**
	//
	// ★ 처방은 **이 저장소가 이미 아는 규칙**이다 — **함정 80·91**:
	//   *"설계가 둘로 갈라 둔 것을 코드에서 합치면 그 구분이 만들려던 능력이 정확히 사라진다."*
	//   ⇒ 막힘을 **행동별로**(`blk[a]` 5칸) 센다 ⇒ **「자리 이동에서만 막혔다」**가 갈리고
	//   그것이 `flip` 의 **직접 신호**다.
	//   ⇒ ★ 그리고 그것은 행동 카운터와 **다른 정보**다 — 카운터는 **「했나」**,
	//     행동별 막힘은 **「했는데 안 통했나」**.
	//
	// ★ 그리고 **정상 경로의 실패율**을 찍는다(함정 287 의 계) — 🔭 오라클 팔의 막힘율이
	//   곧 그것이다. **오라클은 최적**이므로 그 팔의 막힘은 **전부 「감수한 손해」**다.
	//   ⇒ 손계산: `H` 의 최적 경로는 5~6걸음이고 그중 **크기 내리기 2 + 올리기 2 = 네 걸음이**
	//     **`d` 를 키운다** ⇒ 정상 실패율 **~65%**. `B` 는 1~2걸음이 전부 `d` 를 줄인다 ⇒ **~0%**.
	//
	// ★ **미리 등록**:
	//   ㉠ 🔭 오라클 지평 4 가 `H` **100%**(상한선 고정)
	//   ㉡ 📈 관측만이 무작위를 **못 넘는다**(대조군)
	//   ㉢ 🔢 카운터가 **D112 를 재현**(`H` ~+6%p) · 🚫 막힘 한 칸도 재현(`H` ~−2.5%p)
	//   ㉣ ★ 🚫 **행동별 막힘이 `H` 에서 값을 한다** — 관측만 대비 **+3%p 이상**
	//     ⇒ **뭉갬이 원인이었다**는 확인이다
	//   ㉤ ★ **합(카운터 + 행동별 막힘)이 둘 다를 넘는다** — ⚠️ **`AND`** 로 판정(함정 286)
	//   ㉥ 📏 **정상 경로 실패율**: `H` **~65%** ↔ `B` **~0%** ⇒ 함정 287 의 기제 확인
	//   ★ 갈림: 행동별로 갈라도 `H` 에서 값을 못 하면 **막힘은 이 세계에서 못 쓰는 신호**이고,
	//     그러면 폐회로를 **다른 것**(예: 예측 오차)에서 찾아야 한다.

	// ══════ 🔁 **D112 — 누적 규칙을 놓아준다: 「무엇을 세나」** ══════
	// ⚠️⚠️ **먼저 D111 의 문구를 정정한다.** 나는 이력 카운터를 *"세계가 준 카운터"* 라고
	//   적었는데 **부정확하다** — `aCnt[a]++` 는 **학습기가 고른 행동**을 세므로
	//   **이미 기능적 폐회로**다(자기 출력 → 자기 입력). ⇒ 진짜 차이는 하나다:
	//   ***누적 규칙이 손으로 고정돼 있다*** — `+1` · 감쇠 없음 · **행동마다 한 칸**.
	//
	// ★ 그래서 물음을 다시 잡았다: ***「무엇을 세나」를 세계가 안 알려 줘도 되나.***
	//   · 🔢 **행동 카운터**(D111) — 세계가 **행동 인덱스**를 준다(5칸)
	//   · 🚫 **막힘 누적**(새것 · **1칸**) — 「나아지지 않은 걸음」의 누적.
	//     ⇒ ★ 세계가 **무엇을 세라고 안 알려 준다.** 그런데 `flip` 이 켜지면 자리 이동이
	//     반대로 가서 **막힘이 늘어난다** ⇒ **담을 수 있다.**
	//     ⇒ ★ 그것이 `concept.md` 의 *"의미는 주지 않고 **기능적 폐회로**만 준다"* 의 실측이고
	//     *"기대 위반이 고칠 자리를 가리킨다"* 와 같은 계열이다.
	//   · ⏳ **감쇠 λ** — 숨은 상태는 **지속**이므로 잊으면 안 될 것이다(그것을 시험한다)
	//
	// ★ 전부 **📈 Q** 로 돌린다 — D111 이 *"이력은 「가치」 학습기에서만 값을 한다"* 를 냈다.
	//
	// ★ **미리 등록**:
	//   ㉠ 🔢 행동 카운터가 **D111 을 재현한다**(`H` ~15.9%)
	//   ㉡ 🚫 **막힘 누적(1칸)도 값을 한다** — 관측만 대비 **문턱(표준오차 x2) 이상**
	//     ⇒ **세계가 무엇을 세라고 안 알려 줘도 된다**가 선다
	//   ㉢ ⏳ **λ=0.9 는 더 나쁘다** — 숨은 상태는 지속이라 **잊으면 안 된다**
	//   ㉣ ★ **둘 다가 가장 낫다**(서로 다른 것을 담으므로)
	//   ★ 갈림: 막힘 누적이 **값을 못 하면** 「세계가 축을 알려 줘야 한다」가 서고, 그것은
	//     이 프로젝트가 **피하려는 방향**이라 그때는 다른 폐회로를 찾아야 한다.

	struct QPol
	{
		double w[kLAX][kGF] = {};
		double b[kLAX] = {};
		double Q(const double* f, int a) const
		{
			double s = b[a];
			for (int k = 0; k < kGF; ++k) s += w[a][k] * f[k];
			return s;
		}
		double Best(const double* f, int n) const
		{
			double m = Q(f, 0);
			for (int a = 1; a < n; ++a) { const double v = Q(f, a); if (v > m) m = v; }
			return m;
		}
		int Argmax(const double* f, int n) const
		{
			int bi = 0; double bv = Q(f, 0);
			for (int a = 1; a < n; ++a)
			{
				const double v = Q(f, a);
				if (v > bv) { bv = v; bi = a; }
			}
			return bi;
		}
		// 📈 회귀 — 목표값으로 당긴다(TD). ⚠️ 부호가 아니라 **값**이다.
		void Learn(const double* f, int a, double tgt, double lr)
		{
			const double e = tgt - Q(f, a);
			for (int k = 0; k < kGF; ++k) w[a][k] += lr * e * f[k];
			b[a] += lr * e;
		}
	};

	// ══════ 🎯 **D101 — 예측기를 「순위」까지**(그리고 관문을 쓸 곳과 같은 모양으로) ══════
	// ⛔⛔ D100 이 남긴 것: 예측 정확도 **93.1%** · recall **90.9%** 인데 그 예측으로
	//   `argmax` 정책을 만들면 `A'` **61.4%** = **무작위 61.5%**(함정 256).
	// ★ 기제(손으로 확인): `A'` 에서 색거리 2 면 `색+1` 도 막힘이고 자리 이동도 막힘 —
	//   **부호만 보면 같다.** 그런데 `색+1` 은 **때때로 +1**, 자리 이동은 **항상 −1**
	//   ⇒ **확률로 담으면 구별된다.** ⇒ 처방 = **로지스틱**(맞았을 때도 배운다).
	//
	// ★ **관문도 고친다**(함정 257) — 「쓸 곳과 같은 모양」으로 재야 한다. 쓸 곳이 `argmax`
	//   이므로 관문도 `argmax` 로: ***🔭 오라클 지평 4 의 선택과 예측기 argmax 의 일치율.***
	//   ⚠️ 대조군은 **무작위 = 20.0%**(행동 다섯). 오라클이 「참」을 주므로 이 관문은 쓸 곳과
	//   정확히 같은 물음이다.
	//
	// ★ **채점 팔을 정책 팔과 분리한다**(함정 258 — 나쁜 정책이 표본을 늘려 예측을 돕는다):
	//   채점은 **🚪 무작위 팔(0)의 예측기**로만 한다. 그 팔은 예측을 정책에 쓰지 않으므로
	//   **고정 분포**이고, 팔끼리의 비교가 공정해진다. ⇒ `kALrn` / `kARol` 을 갈랐다.
	// ⚠️⚠️ 그리고 예측기를 **팔마다** 둔다 — D100 까지는 `prd` 가 **하나**여서 팔이 여럿이면
	//   서로 오염됐다(그때는 한 팔만 써서 드러나지 않았다).
	//
	// ★ 팔 여덟: 0 🚪 무작위(채점 담당) · 1 🧠 보상 규칙(D98 · A' 94.5 / H 2.9) ·
	//   2 🔮 **부호 퍼셉트론 argmax**(D100 재현 · A' 61.4) · 3 🎯 **로지스틱 argmax**(주역) ·
	//   4 🎯 로지스틱 ε=10% · 5 🎯 로지스틱 **확률로 뽑기** · 6 🔭 오라클 지평 1 ·
	//   7 🔭 오라클 지평 4(상한선 H 100.0)
	//
	// ★ **미리 등록**:
	//   ㉠ 🎯 로지스틱이 부호 퍼셉트론(61.4%)을 **크게 넘는다** — `A'` ~88%
	//   ㉡ 🎯 로지스틱이 보상 규칙(94.5%)에 **근접한다**(−10%p 이내)
	//   ㉢ ⚖️ **argmax 관문**: 오라클 일치율 **로지스틱 ≥ 50%** · **퍼셉트론 < 30%**(무작위 20%)
	//   ㉣ 🎯 `H` 에서는 여전히 **무작위(19.2%)를 못 넘는다** — 1단이라 원리적으로(깊이 4)
	//   ★ 갈림: 로지스틱도 `A'` 에서 못 넘으면 **argmax 자체가 이 문제에 안 맞는다**
	//     ⇒ 정책을 따로 배우고 **예측은 계획에만** 쓴다(그러면 그렇게 적는다).

	// ══════ 🔭 **D100 — 이 세계의 의존 깊이는 몇인가**(오라클 지평 훑기) ══════
	// ⛔⛔⛔ **먼저 잘못을 적는다.** D97 에서 **손 신호가 0.0%** 인 것을 보고 세계를
	//   **「깊이 2」** 라고 적었고, 그 이름으로 D98(보상 규칙 네 축)과 D99(한 걸음 예측기)를
	//   설계했다. ⚠️ **실패는 「깊이가 1보다 크다」만 말한다** — 2 라고는 말하지 않는다.
	//
	// ★ **손계산을 해 보니 2 가 아니다.** `ph3` 에서 자리를 옮기려면
	//   `s: 2 → 1 → 0`(두 걸음 · **둘 다 손해**) → `x` 이동 → `s: 0 → 1 → 2`(두 걸음)
	//   ⇒ **최소 5걸음**이고 목표거리 `d` 는 **마지막 걸음에서야** `d0` 아래로 내려간다.
	//   ⚠️⚠️ 그래서 지평이 5 미만인 계획자는 **「막히는 행동」(d 를 유지하는 것)이 더 좋아**
	//   **보여서 영원히 갇힌다** — 지평 3 이나 4 를 줘도 그렇다.
	//   ⇒ **「2단 롤아웃이 답이다」가 원리적으로 틀린 처방이었다.**
	//
	// ★ 그래서 **짓기 전에 잰다**: 세계를 **완벽히 아는 계획자**에게 지평만 달리 주고
	//   `H` 도달률을 본다. ⇒ **처음 넘는 지평이 곧 그 세계의 의존 깊이**다.
	//   ⚠️ 오라클은 손 규칙이다(학습자가 아니다) — **상한선/기준자**로만 쓴다(👁️ 손 신호와
	//   같은 성격). 상태 공간이 `nc x 3 x 3` 뿐이라 **너비우선으로 정확히** 푼다.
	//
	// ★ 팔 여덟:
	//   0 🚪 무작위(기준선 20.9%) · 1~5 🔭 오라클 지평 **1 · 2 · 3 · 4 · 6**
	//   6 🔮 **배운 1단 롤아웃**(D99 예측기로 정책 · ε=40%) — D99 가 남긴 물음의 직접 답
	//   7 🧠 **보상 규칙 최고**(즉시 · ε=40%) = D98 의 그 팔 ⇒ **재현 확인**(A' 93.9 / H 3.8)
	//
	// ★ **미리 등록**:
	//   ㉠ 🔭 지평 **1·2·3·4 가 `H` 에서 전부 ~0%** ⇒ 「깊이 2」가 틀렸다는 실측
	//   ㉡ 🔭 지평 **6 이 크게 넘는다**(~95%+) ⇒ 의존 깊이는 **5~6**이다
	//   ㉢ 🔮 배운 1단이 보상 규칙과 `H` 에서 **비슷하다**(둘 다 1단이다) · `A'` 에서는 **더 낫다**
	//   ㉣ 🔮 예측기가 **정책을 몰면 recall 이 떨어진다**(분포가 좁아진다 · D99 74.1% → ~60%)
	//   ★ 갈림: 지평 4 가 넘으면 **내 손계산이 틀렸다** ⇒ 그대로 적는다.
	//   ★ 갈림: 지평 6 도 못 넘으면 **도달 불가능한 과제가 섞여 있다** ⇒ 생성기를 본다.

	// 🔒 **세계의 법칙 — 한 곳**(D105). 「자리가 움직일 수 있나」를 여기서만 정한다.
	//   ⚠️⚠️ 예전에는 이것이 **두 곳**에 있었다(세계 적용 · 🔭 오라클) ⇒ 조건을 늘리는 순간
	//   오라클이 **틀린 세계를 계획**한다. 같은 사실이 두 곳에 살면 **한쪽이 진다.**
	//
	// ★ **폭**(`w`) = **조건 분기의 개수**(사용자 목록 7번 「다중 조건 분기화」):
	//   · `w=1` **현행** — 늘 `크기 == 최소`. 조건 **하나**
	//   · `w=2` — 색 0~2 는 `최소`, 색 3~4 는 **`최대`**(반대다). 분기 **둘**
	//   · `w=3` — 색 0~1 은 `최소`, 색 2~3 은 `최대`, 색 4 는 **늘 열림**. 분기 **셋**
	//   ★ 분기를 늘려도 **도달 가능성은 남는다**(색을 바꿀 수 있으므로) — 그것을 🔭 오라클이
	//     확인해 준다(「가능함을 증명하는 팔」). ⚠️ 못 내면 **세계가 안 풀린다**는 뜻이고
	//     그러면 학습 팔의 숫자는 아무 뜻이 없다 ⇒ **그것을 먼저 적는다.**
	static bool _XOpen(int cc, int cs, int w)
	{
		if (w <= 1) return (cs == 0);
		if (w == 2) return (cc <= 2) ? (cs == 0) : (cs == 2);
		if (cc <= 1) return (cs == 0);
		if (cc <= 3) return (cs == 2);
		return true;
	}

	// 🔭 **오라클 계획자**(D100) — 세계를 **완벽히 알고** 지평 `hz` 까지 너비우선으로 본다.
	//   ⚠️ 손 규칙이다 — **상한선**으로만 쓴다. 잎 평가는 `(목표거리, 걸음수)` 사전식 최소이고
	//   **깊이 0(가만히)은 후보가 아니다**(세계에 「가만히」가 없다 — 막히는 행동이 그 자리다).
	// 🔒 **자리 행동은 한 곳에서 정한다**(D105 를 이 판에서 완성) — 세계와 🔭 오라클이
	//   **같은 함수**를 부른다. ★ 카운터가 사라졌으므로 두 서명이 **정말 일치**한다
	//   (`szN` 이 있던 동안은 카운터 인자 때문에 통합이 안 됐다).
	static void _XAct(int a, bool xo, bool fl, int& x)
	{
		if (!xo) return;
		const bool right = ((a == 1) == fl);   // 🕳️ `a=1` 은 반전이면 오른쪽
		if (right) { if (x < 2) x++; } else { if (x > 0) x--; }
	}

	static int _OraclePick(int nc, int cc, int cx, int cs,
		int gc, int gx, int gs, int hz, int w, bool fl)   // 🕳️ `int sz0` → `bool fl`(D124)
	{
		// 🕳️ **반전은 이 에피소드의 상수**다 ⇒ 상태가 아니라 **전이의 파라미터**다.
		//   ⇒ 크기 누적 축(`x4`)이 사라진다: `288 → 72`.
		//   ⚠️⚠️ 옛 코드는 `const bool fl = (q4 >= 3);` 이라 **계획 중에 반전이 변했고**,
		//   더 나쁘게 `q2` 갱신이 `z` 변화 검사 **밖**이라 **제자리 크기 행동이 새 상태**가
		//   되어 프룬을 빠져나갔다 ⇒ `H` 에서 오라클이 **제자리를 3걸음 태웠다**(8 ↔ 5.33).
		const int kS = 8 * 3 * 3;
		int dep[kS]; int fst[kS];
		for (int k = 0; k < kS; ++k) { dep[k] = -1; fst[k] = -1; }
		int q[kS]; int qh = 0, qt = 0;
		const int s0 = (cc * 3 + cx) * 3 + cs;
		dep[s0] = 0; q[qt++] = s0;
		int bi = -1, bd = 1 << 20, bn = 1 << 20;
		while (qh < qt)
		{
			const int s = q[qh++];
			const int n = dep[s];
			const int c = s / 9, x = (s / 3) % 3, z = s % 3;
			if (n > 0)
			{
				const int dx = (x > gx) ? (x - gx) : (gx - x);
				const int dz = (z > gs) ? (z - gs) : (gs - z);
				const int dd = ((c != gc) ? 1 : 0) + dx + dz;
				if (dd < bd || (dd == bd && n < bn)) { bd = dd; bn = n; bi = fst[s]; }
			}
			if (n >= hz) continue;
			for (int a = 0; a < 5; ++a)
			{
				int c2 = c, x2 = x, z2 = z;
				const bool xo = _XOpen(c, z, w);   // 🔒 **같은 함수**를 쓴다(D105)
				if (a == 0) c2 = (c + 1) % nc;
				else if (a == 1) _XAct(1, xo, fl, x2);   // 🔒 세계와 **같은 함수**
				else if (a == 2) _XAct(2, xo, fl, x2);
				else if (a == 3) { if (z > 0) z2 = z - 1; }
				else             { if (z < 2) z2 = z + 1; }
				const int s2 = (c2 * 3 + x2) * 3 + z2;
				if (dep[s2] >= 0) continue;
				dep[s2] = n + 1; fst[s2] = (n == 0) ? a : fst[s];
				q[qt++] = s2;
			}
		}
		return (bi >= 0) ? bi : 0;
	}

	// 📏 **`-mlleak` — 「조용한 죽음」의 남은 결함: 누수를 단계로 가른다**(D128)
	//
	// ★ **실측이 이 라운드를 불렀다**: `-mlsparse` 를 돌리며 프로세스 메모리를 표집했더니
	//   **0.71 MB/초로 완벽한 직선**으로 자랐다(핸들·스레드는 평평 ⇒ 순수 메모리 누수).
	//   ⚠️⚠️ D127 은 **기계의 가용 메모리**를 보고 「메모리 부족 아님」이라 적었다 —
	//   **프로세스의 성장**은 한 번도 안 봤다. 그것이 그 표의 구멍이었다.
	//
	// ★ **설계 = 누적 단계.** 걸음마다 사는 것이 넷이고 `① ⊂ ② ⊂ ③ ⊂ ④` 로 켠다 ⇒
	//   **증가율의 차이**가 그 조각의 몫이다(조각마다 N−1 대조군을 두는 것과 같다).
	//   ⚠️ **0 단계(아무것도 안 한다)를 먼저** 둔다 — 루프 자체가 안 새는 것을 먼저 보여야
	//   나머지 차이를 그 조각에 귀속할 수 있다(함정 243: 두 가지를 같이 바꾸면 귀속 불가).
	//
	// ★ 읽는 법: 밖의 표집기가 `LEAKMARK stage=N` 을 보고 CSV 에 단계를 적는다 ⇒
	//   단계별 `(MB 증가) / (반복 수)` = **반복당 바이트**. 손계산 기대치는 **~470 B/걸음**
	//   (0.71 MB/s ÷ ~1500 걸음/s).
	// 🔗 **전방선언** — 아래 `_BindProbe` 의 **매개변수 타입**이 `Blob` 이고 그 정의는 이 파일
	//   **뒤쪽**에 있다. ⚠️ 멤버 함수의 **본문**은 클래스가 완성된 뒤 해석되지만(그래서 다른
	//   함수들이 `Blob bl[8]` 을 그냥 써 왔다) **시그니처는 그 자리에서** 찾는다.
	//   ★ 불완전 타입의 **포인터**는 괜찮으므로 이 한 줄로 끝난다(정의를 옮기지 않는다).
	struct Blob;
	
	// ── 🔗 **D137 · 묶임(binding)** — 대상이 둘이면 「어느 속성이 어느 물체에」가 문제다 ──
	//
	//   ★ D136 이 `_Blobs` 를 연결 기반으로 세웠다 ⇒ 대상 둘을 **볼 수** 있다. 그런데
	//     학습기는 여전히 **`bl[0]`** 만 보고 성분은 **값 순**이다 ⇒ 방해자 색 값이 목표색보다
	//     작으면 **엉뚱한 물체를 잰다.**
	//   ⚠️⚠️ 그리고 그 실패가 **조용하다** — 목표 프레임도 같은 규칙으로 재므로 **방해자끼리**
	//     비교하면 거리가 **0** 이 되어 「됐다」를 일찍 찍는다(= **거짓 도달**).
	//     ★ 그것을 셀 수 있는 것은 이 라운드가 **생성기의 진실**(`cc·cs`)을 갖고 있어서다.
	//   ⚠️ 팔 표를 **건드리지 않는다** — 전용 라운드라 `-mlsparse` 의 비트 재현이 안 깨진다.
	void _RunBind(int rnd)
	{
		const int cell = MLEpisodeGen::kSize;
		const uint64 plane = (uint64)cell * (uint64)cell;
		const int nc = MLEpisodeGen::PaletteCount();
		const int kSd = 30, kPer = 60, kCap = 16;
		static constexpr int kBA = 276;
		// 🧩 **메뉴를 스스로 만든다**(D156) — 후보를 **사람이 적는 것을 그만둔다**.
		//   ★ 지금 메뉴 넷은 사실 **세 축의 곱**이다:
		//     **행동** 3(🔎 관찰 · 🎨 색+1 · 📏 크기±1) × **극성** 2(➖ 빼기 · ➕ 고르기)
		//     × **속성** 3(v 값 · i 잉크 · b 값＆잉크) = **18**.
		//   ⇒ 후보 번호 = `행동*6 + 극성*3 + 속성` 이고 **사람이 적은 넷은 {02, 06, 13, 16}** 이다.
		//   ⭐⭐ 그리고 손으로 따지면 **17(📏➕b)도 100% 정답**인데 **메뉴에 없었다**
		//     ⇒ ㉡「사람이 안 적은 조합을 고르나」가 **원리적으로 가능**하다(그것이 이 판의 요점).
		//   ★ 판정의 근거는 `concept.md` 의 그 한 줄이다: *"인코딩 층의 구조는 주고, 분포 층의
		//     구조는 배우게 한다"* — **축(원시형)은 주고 조합은 안 준다.**
		static constexpr int kBMx = 18;
		// 🧩 **손 메뉴 넷** — `kBNA <= 4` 인 팔은 이 표를 거치지 않고 **옛 코드 경로 그대로** 간다
		//   (규율 18: 재현을 내 재유도가 아니라 **구조**로 보장한다). 이 표는 **읽기용 대조**다.
		static const int kMenu4[4] = { 2, 6, 13, 16 };
		static const char* kBN[kBA] = {
			"㈀ 방해자 없음(상한)             ", "㈁ 방해자 + `bl[0]`(지금)        ",
			"㈂ 방해자 + 🔭 오라클 짝짓기      ", "㈃ 방해자 + 🔬 시험(**색축**)     ",
			"㈄ 방해자 + 🔬 시험(**크기축**)    ", "㈅ 방해자 + 🔎 **관찰만**(0걸음)   ",
			"㈆ ⚡**변하는** 방해자 + 🔎 관찰만  ", "㈇ ⚡**변하는** 방해자 + 🔬 시험    ",
			"㈈ ⚡**변하는** 방해자 + ⚡**개입+예측**  ",
		"㈉ ⚡⚡**색+크기** + ⚡개입+예측        ", "㈊ ⚡⚡**색+크기** + ↩️**되돌리는 개입** ",
		"㈋ 🧠 **학습기**(짝 점수화 · lr>0)      ", "㈌ 🧠 학습기 **lr=0**(N−1 대조군)  ",
		"㈍ 🧠 학습기 + 📉 **기준선 과제군별**",
		"㈎ 🎯 **행동을 고른다**(⚡변하는 방해자)  ", "㈏ 🎯 행동 **lr=0**(N−1 · 무작위)  ",
		"㈐ 🎲 **상황 섞임** + 🎯 행동을 고른다      ", "㈑ 🎲 상황 섞임 + 행동 **lr=0**(N−1)  ",
		"㈒ 🎲 상황 섞임 · 🔎 **관찰에 고정**       ", "㈓ 🎲 상황 섞임 · 🎨 **색에 고정**      ",
		"㈔ 🎲 상황 섞임 · 📏 **크기에 고정**       ",
		"㈕ 🔄 **갈아타기** + 🎯 학습기          ", "㈖ 🔄 갈아타기 **lr=0**(N−1 · 무작위)  ",
		"㈗ 🔀 학습 **180** · 0 에서 시작       ", "㈘ 🔀 학습 180 · ⭐ **물려받는다**      ",
		"㈙ 🔀 학습 180 · ⚠️ **부호 반전**(음성)   ", "㈚ 🔀 학습 **60** · 0 에서 시작        ",
		"㈛ 🔀 학습 **600** · 0 에서 시작       ",
		// 🎨 **같은 색 방해자 둘**(D153 · `-mlsame`) — 대상 수 **3**.
		"Ⓐ 🎨🎨 🔎 **관찰에 고정**            ", "Ⓑ 🎨🎨 🎨 **색에 고정**            ",
		"Ⓒ 🎨🎨 📏 **크기에 고정**(빼기)       ", "Ⓓ 🎨🎨 ⭐ **고르기 극성에 고정**      ",
		"Ⓔ 🎨🎨 🎯 학습기 · 0 에서 시작       ", "Ⓕ 🎨🎨 🎯 · 🎭**다른 판**(㈕) 받음   ",
		"Ⓖ 🎨🎨 🎯 · ⚠️**다른 판** 부호반전   ",
		// 🔀 **「몇 배」의 두 곡선**(D154) — 예산 **60 · 180 · 600**. 900 점은 Ⓔ·Ⓕ·Ⓖ 가 준다.
		"Ⓗ 🔀 0시작 · 학습 **60**            ", "Ⓘ 🔀 0시작 · 학습 **180**           ",
		"Ⓙ 🔀 0시작 · 학습 **600**           ", "Ⓚ 🔀 🎭**다른 판** · 학습 **60**    ",
		"Ⓛ 🔀 🎭**다른 판** · 학습 **180**   ", "Ⓜ 🔀 🎭**다른 판** · 학습 **600**   ",
		"Ⓝ 🔀 ⚠️다른판 부호반전 · **180**    ",
		// 🔔 **더 나은 방아쇠**(D155) — 「매치 0」은 이 세계에서 **한 번도 안 울렸다**(D153·D154 실측 0회).
		//   ★ 틀린 키도 **매치를 찾기** 때문이다(방해자 A 를 잡는다) ⇒ 신호를 **「좁히고 남은 수」**로 바꾼다.
		"Ⓞ 🔔 **남은 후보 ≠ 1** 방아쇠        ", "Ⓟ 🎲 **무작위** 방아쇠(같은 발화율)   ",
		"Ⓠ ⚠️ **뒤집은** 방아쇠(음성)         ",
		// 🔀 ㉮ ↔ ㉯ 를 가른다(🐛B) — 이 팔이 **옛 Ⓕ 의 거동**이라 회귀 감시자다(규율 18).
		"Ⓡ 🔀 ⭐**같은 판**(Ⓔ)에서 물려받음   ",
		// 🔀 ⭐ **같은 판 곡선**(D155) — D154 의 「배율 4~8배」가 **실은 이쪽**이었다(🐛B).
		//   ⇒ ㉮(같은 판) · ㉯(다른 판) · 0시작 **세 곡선**을 한 실행에 나란히 둔다.
		"Ⓢ 🔀 ⭐**같은 판** · 학습 **60**    ", "Ⓣ 🔀 ⭐**같은 판** · 학습 **180**   ",
		"Ⓤ 🔀 ⭐**같은 판** · 학습 **600**   ",
		// 🧩 **메뉴를 스스로 만든다**(D156) — 후보 **18** = 행동 3 x 극성 2 x 속성 3.
		//   ⭐ 손 메뉴 넷은 {02, 06, 13, 16} 이고 **17 은 사람이 안 적은 정답 후보**다.
		//   ⚠️ 고정 팔 18 개가 **메뉴의 서명**이다 — 판정보다 먼저 읽는다(규율 21).
		"Ⓥ 🧩 18-메뉴 · 900 · 🕳️옛 방아쇠  ", "Ⓦ 🧩 18-메뉴 · 900 · 🔔 방아쇠    ",
		"Ⓧ 🧩 18-메뉴 · 학습 **60**        ", "Ⓨ 🧩 18-메뉴 · 학습 **180**       ",
		"Ⓩ 🧩 18-메뉴 · 학습 **600**       ", "ⓐ 🧩 18-메뉴 · **lr=0**(무작위 바닥) ",
		"ⓑ 🩹 4-메뉴 · 🔔 · **첫 결정 r=0** ", "🧩00 🔎➖v 고정",
		"🧩01 🔎➖i 고정", "🧩02 🔎➖b 고정 ←🔎",
		"🧩03 🔎➕v 고정", "🧩04 🔎➕i 고정",
		"🧩05 🔎➕b 고정", "🧩06 🎨➖v 고정 ←🎨",
		"🧩07 🎨➖i 고정", "🧩08 🎨➖b 고정",
		"🧩09 🎨➕v 고정", "🧩10 🎨➕i 고정",
		"🧩11 🎨➕b 고정", "🧩12 📏➖v 고정",
		"🧩13 📏➖i 고정 ←📏", "🧩14 📏➖b 고정",
		"🧩15 📏➕v 고정", "🧩16 📏➕i 고정 ←⭐",
		"🧩17 📏➕b 고정 ⭐**미등록**",
		// 💰 **보상에 걸음을 싣는다**(D157 · 함정 372) — 05(1.92) 와 16(3.09) 을 **구별 가능**하게 만든다.
		//   ⚠️ ⓘ 는 **부호를 뒤집은** 음성 대조다 — argmax 가 **비싼 후보**로 가야 옳다(규율 14).
		"ⓒ 💰 18-메뉴 · 🩹 · 걸음벌 **0**    ", "ⓓ 💰 18-메뉴 · 🩹 · 걸음벌 **0.02** ",
		"ⓔ 💰 18-메뉴 · 🩹 · 걸음벌 **0.05** ", "ⓕ 💰 18-메뉴 · 🩹 · 걸음벌 **0.10** ",
		"ⓖ 💰 18-메뉴 · 🩹 · 걸음벌 **0.30** ", "ⓗ 💰 18-메뉴 · 🩹 · 0.10 · **lr=0** ",
		"ⓘ 💰 18-메뉴 · 🩹 · ⚠️**−0.10**(음성)",
		// 🎭 **방해자가 자리도 바꾼다**(D159 · `di = 21+m`) — 세계 축 = **자리**.
		//   ⚠️⚠️ 고정 18 이 **세계의 서명**이다 — ➖ 아홉은 **안 바뀌어야** 하고(키가 값/잉크),
		//     ➕ 중 목표를 옳게 집는 05·16·17 도 **100%% 를 지켜야** 한다(목표는 자리를 안 바꾼다).
		//   🚨 그리고 **에피소드 수**를 본다 — 1800 미만이면 **버려진 판**이 있고 도달률이 부풀려진다.
		"ⓙ 🎭 자리 · 18-메뉴 · 🔔 남은≠1   ", "ⓚ 🎭 자리 · 18-메뉴 · 🔔+**지목**  ",
		"ⓛ 🎭 자리 · 18-메뉴 · 🔔**지목만** ", "ⓜ 🎭 자리 · 18-메뉴 · **lr=0**   ",
		"🎭00 🔎➖v 고정" , "🎭01 🔎➖i 고정" ,
		"🎭02 🔎➖b 고정" , "🎭03 🔎➕v 고정" ,
		"🎭04 🔎➕i 고정" , "🎭05 🔎➕b 고정" ,
		"🎭06 🎨➖v 고정" , "🎭07 🎨➖i 고정" ,
		"🎭08 🎨➖b 고정" , "🎭09 🎨➕v 고정" ,
		"🎭10 🎨➕i 고정" , "🎭11 🎨➕b 고정" ,
		"🎭12 📏➖v 고정" , "🎭13 📏➖i 고정" ,
		"🎭14 📏➖b 고정" , "🎭15 📏➕v 고정" ,
		"🎭16 📏➕i 고정" , "🎭17 📏➕b 고정" ,
		// ⚖️ **분모를 고친다**(D160 · 함정 375) — 키가 가리킨 것이 없어도 **폴백으로 살린다**.
		//   ⇒ 모든 팔의 에피소드가 **1800** 이 되어야 비율을 견줄 수 있다.
		//   ⚠️ 고정 넷(03·05·09·11)은 D159 에서 **버려지던 후보**다 ⇒ 편향의 크기를 **숫자로** 준다.
		"ⓝ ⚖️ 자리 · 🔔 남은≠1 · **안 버림** ", "ⓞ ⚖️ 자리 · 🔔+지목 · **안 버림**   ",
		"ⓟ ⚖️ 자리 · 🔔 지목만 · **안 버림** ", "ⓠ ⚖️ 자리 · ⚠️**지목 뒤집음**(음성) ",
		"ⓡ ⚖️ 자리 · **lr=0** · 안 버림     ", "⚖️03 🔎➕v 고정 · **안 버림**       ",
		"⚖️05 🔎➕b 고정 · **안 버림**       ", "⚖️09 🎨➕v 고정 · **안 버림**       ",
		"⚖️11 🎨➕b 고정 · **안 버림**       ",
		// 🎚️ **폭을 먼저 잰다**(D162 · 함정 246) — `c₁` 격자. ⭐ **ⓝ 이 `c₁ = 0.00` 점**이다.
		//   ⚠️ 같은 세계(🎭 자리) · 같은 방아쇠(🔔 남은≠1) · **keep 켬**(분모 1800 고정)에서만 견준다.
		"ⓢ 🎚️ c₁ **0.25** · 자리·keep    ", "ⓣ 🎚️ c₁ **0.50** · 자리·keep    ",
		"ⓤ 🎚️ c₁ **0.75** · 자리·keep    ", "ⓥ 🎚️ c₁ **1.00**(옛것) · 자리·keep",
		"ⓦ 🎚️ c₁ ⚠️**2.00**(음성) · 자리·keep",
		// 🎚️🧠 **넓히고 배우게 한다**(D163) — ① `c₁ < 0`(규율 33: 최적이 끝값이었다)
		//   ② **적응 c₁** = 「책임 귀속」을 갈아타기율로 배운다(㉡ 의 ㉯).
		//   ⚠️ 초기값을 **N−1 로 둘** 둔다(0.50 ↔ 격자 최고 0.00) — 「초기값 덕인가」를 그 둘이 가른다.
		"ⓧ 🎚️ c₁ **−1.00**(넓힘) · 자리·keep", "ⓨ 🎚️ c₁ **−0.50**(넓힘) · 자리·keep",
		"ⓩ 🧠 **적응 c₁** · 초기 0.50    ", "㋐ 🧠 **적응 c₁** · 초기 **0.00** ",
		"㋑ 🧠 적응 ⚠️**뒤집음**(음성)     ",
		// 🎯 **희소 갱신**(D164 · ㉡ 의 **원래 정의**) — 「어느 가중치를 흔들까」.
		//   ⭐ **ⓝ 이 `k=0`(전부 갱신) 기준점**이다. D94 예측: 묶음 18 이라 **+12.4%p 를 넘어야** 한다.
		"㋒ 🎯 희소 **k=1**(고른 것만)     ", "㋓ 🎯 희소 **k=2**              ",
		"㋔ 🎯 희소 **k=4**              ", "㋕ 🎯 ⚠️**고른 것만 빼고**(음성)   ",
		// 🎲 **상황을 섞어 「간섭」을 만든다**(D166 · 세계 축 = **규칙**).
		//   ★ D104 의 절차 그대로 — **따로 재고(🎨/📏) · 섞어서 재고(🎲) · 그 차를 본다**.
		//   ⚠️ 고정 넷은 **세계의 서명**이다: 🎨 에서는 **잉크 키**가 살고 📏 에서는 **값 키**가 산다.
		"㋖ 🎨 **색만 변함** · 학습기      ", "㋗ 📏 **크기만 변함** · 학습기    ",
		"㋘ 🎲 **섞음** · 학습기         ", "🎨05 🔎➕b 고정 · 🎨색만",
		"🎨06 🎨➖v 고정 · 🎨색만", "🎨13 📏➖i 고정 · 🎨색만",
		"🎨16 📏➕i 고정 · 🎨색만", "📏05 🔎➕b 고정 · 📏크기만",
		"📏06 🎨➖v 고정 · 📏크기만", "📏13 📏➖i 고정 · 📏크기만",
		"📏16 📏➕i 고정 · 📏크기만",
		// 🧭 **문맥을 관측에서 만든다**(D167) — ⭐ **㋘ 이 `kBCtx = 0`(첫 후보의 정체) 기준점**이다.
		//   ⚠️ 셋 다 🎲 섞음 세계다(D166 과 같은 판) ⇒ 목표는 **74.6% 를 넘는 것**.
		"㋡ 🧭 문맥 = **관측**(좁힌 수)   ", "㋢ 🧭 문맥 = **둘 다**          ",
		"㋣ 🧭 ⚠️**무작위 문맥**(음성)     ",
		// 🔎 **방아쇠와 독립인 관측 문맥**(D168 · 함정 381 의 처방) — 같은 상태를 한 장 더 그려
		//   **A 가 색을 바꾸나 잉크를 바꾸나**를 본다. ⚠️ 음성(㋥)은 **같은 걸음**을 쓰되 정보가 0 이다.
		"㋤ 🔎 문맥 = **A 가 뭘 바꾸나**   ", "㋥ 🔎 ⚠️같은 걸음 · **무작위**(음성)",
		// 🔎 **첫 선택에도 문맥**(D169 · 함정 382 의 처방) — 문맥이 **모든 판**에서 쓰인다.
		//   ⚠️ ㋧ 는 **같은 걸음**을 쓰되 정보가 0 이다(음성 · 걸음 대가를 통제한다).
		"㋦ 🔎 **첫 선택에도 문맥**       ", "㋧ 🔎 ⚠️같은 걸음 · **무작위**(음성)",
		// 📉 **표본 부족인가를 곡선으로**(D170) — 두 곡선(🔎 문맥 있음 ↔ ⬜ 없음) x 예산 넷.
		//   ⭐ **1800 점은 ㋦·㋘ 이 이미 준다** ⇒ 여기는 **60 · 180 · 600** 셋씩이다.
		//   ⚠️ 지표는 **후반(평가) 도달률**이다 — 「그 예산으로 배운 것의 실력」이 그것이다.
		"㋨ 📉 🔎문맥 · 학습 **60**   ", "㋩ 📉 🔎문맥 · 학습 **180**  ",
		"㋪ 📉 🔎문맥 · 학습 **600**  ", "㋫ 📉 ⬜없음 · 학습 **60**   ",
		"㋬ 📉 ⬜없음 · 학습 **180**  ", "㋭ 📉 ⬜없음 · 학습 **600**  ",
		// 🧬 **「어느 관측을 볼까」도 고르게 한다**(D172 · ㉰ 의 **넷째 칸 = 축**).
		//   ★ 지금까지 `kBCtx` 는 **사람이** 정했다 ⇒ 후보를 펼쳐 **고르는 행동**을 만든다(D156 의 관용구).
		"㋮ 🧬 **어느 관측을 볼까**(배운다)  ", "㋯ 🧬 ⚠️관측을 **무작위로**(음성)   ",
		// 🔬 **관측의 값을 「갈랐나」로 잰다**(D173 · 함정 384 의 처방).
		//   ★ 죽은 관측은 **정의상 0점** ⇒ 표본 편향에 안 걸린다. ⚠️ ㋲ 는 N−1(보상은 그대로 · 수렴만 늦춘다).
		"㋰ 🔬 관측 보상 = **갈림**       ", "㋱ 🔬 ⚠️**뒤집은 갈림**(음성)     ",
		"㋲ 🎲 도달률 · **탐험 유지**(lr/5) ",
		// 🪦 **죽은 관측을 늘려 음성을 강하게**(D174 · 함정 385) — 후보 여덟 중 **살아있는 것 셋**.
		//   ★ 손 예측: 무작위 ≈ 3/8x82.7 + 5/8x73.8 = **77.1%** ⇒ 배운 것(82.7)과 **+5.6%p** 로 갈린다.
		//   ⚠️ 그 모델은 D172 가 검증했다(넷 중 셋 ⇒ 예측 80.5% ↔ 실측 80.1%).
		"㋳ 🪦 관측 **여덟** · 배운다      ", "㋴ 🪦 관측 여덟 · ⚠️**무작위**(음성) ",
		// 🎯 **비율만 바꾼다**(D175 · 함정 386) — 후보 **넷** 중 **살아있는 것 하나**(🎨색).
		//   ★ 모델이 계산해 줬다: 무작위 = 1/4x82.7 + 3/4x73.8 = **76.0%** ⇒ 배운 것(82.7)과 **+6.7%p**.
		//   ⚠️ 그 모델은 두 판이 검증했다(오차 0.4·1.1%p) ⇒ 설계를 미리 계산했다.
		"㋵ 🎯 넷 중 **하나만 살아** · 배운다 ", "㋶ 🎯 넷 중 하나 · ⚠️**무작위**(음성) ",
		// 🔬🎯 **갈림 보상 x 하나만 살아**(D176) — 두 판의 재료를 합친다.
		//   ★ 갈림은 `aw` 와 무관하게 계산된다 ⇒ **닭과 달걀(규율 47)이 원리적으로 없다**.
		//   ⚠️ 갈림이 이미 **[1.00·0.00·0.00·0.00]** 로 정확히 하나를 가리킨다(D175 실측).
		"㋷ 🔬🎯 **갈림 x 하나만 살아**    ", "㋸ 🔬🎯 ⚠️**뒤집은 갈림**(음성)   ",
		// 🩺 **아래층을 살린다**(D178 · ㉢ 마무리) — D176 의 후보 둘을 N−1 로 가른다.
		//   ㉠ 🧮 **칸을 둘로**(관측이 굳으면 슬롯은 무의미 ⇒ 표본이 두 배)
		//   ㉡ ⏳ **위층을 늦게**(초반 300판은 균등 · **답을 주지 않는다**)
		"㋹ 🧮 아래층 **칸을 둘로**       ", "㋺ ⏳ 위층을 **늦게 켠다**(300판) ",
		// 🎭 **상황을 셋으로**(D179 · 세계 판) — 🎨 색만 · 📏 크기만 · 📍 **자리만**(새 상황).
		//   ⭐ 겨냥 = **㉡ 선택적 수정** — D166 이 접은 이유(*담을 자리가 없다* · 규율 39)가
		//     **D178 로 사라졌다**(문맥이 82.7% 로 작동한다) ⇒ **간섭이 생기나**를 다시 묻는다.
		//   ⚠️ 규율 38 대로 **min(따로 셋)** 을 기준으로 본다(평균은 표본을 깎는다).
		"㋻ 🎨 색만(따로)                ", "㋼ 📏 크기만(따로)              ", "㋽ 📍 **자리만**(따로 · 새 상황) ",
		"㋾ 🎲 **셋 섞음**(간섭을 본다)   ", "㈎ 🎲 셋 섞음 · ⛔**문맥 없음**  ", "㈏ 🎲 셋 섞음 · 🔭**상황을 준다**",
		// 🧨 **안 보이는 충돌**(D180 · ㉡ 마지막 시도) — 📏 A 크기만 ↔ 🧨 **B 크기만**.
		//   ★ 관측 서명이 **같다**(`[oVC=0 oIC=1 oPC=0]`)는데 **옳은 후보는 다르다**
		//     ⇒ 문맥으로 **원리적으로** 못 가른다 ⇒ 한 후보로 평균을 내야 한다 = **간섭이 강제된다**.
		//   ⚠️ 규율 31 — 그 충돌을 푸는 **행동이 계에 있나**를 ㈓(갈아타기 끔)로 **값으로** 묻는다.
		"㈐ 📏 A 크기만(따로 · 재현)      ", "㈑ 🧨 **B 크기만**(따로 · 새 상황)", "㈒ 🧨 **충돌 둘 섞음**(핵심)     ",
		"㈓ 🧨 충돌 둘 · ⛔**갈아타기 끔** ", "㈔ 🧨 충돌 둘 · 🔭**어느 쪽인지** ", "㈕ 🧨 **넷 섞음**(D179 셋 + 충돌) ",
		// 🔁 **에피소드 안에 「됐다/안 됐다」를 준다**(D181 · 규율 54 의 처방).
		//   ★ 자리는 **간섭이 실재하는 세계**다(D180 의 넷 섞음 = 73.0% ↔ 따로 평균 87.8%).
		//   ⚠️ 음성 **둘**을 같이 둔다 — 「때」와 「내용」과 「비용」을 각각 통제한다.
		"㈖ 🔁 **재시도**(정책이 고친다)   ", "㈗ ⛔ 음성 **무작위 재시도**      ", "㈘ ⛔ 음성 **걸음만 더**(비용)    ",
		"㈙ 🧨 넷 섞음 · 재시도 끔(기준)   ", "㈚ 🔁 재시도 · 🧨 **충돌 둘만**   ",
		// 🎯 **거짓 도달을 낮춘다**(D182 · 규율 55 의 처방).
		//   ⭐ D181 이 병목을 지목했다 — 거짓 도달 28%대가 「됐다」 신호를 못 쓰게 만든다.
		//   ⚠️⚠️ **규율 56** — 기준 팔(㈞ 넷·끔 · ㈟ 충돌둘·끔)을 **같은 판 안에** 뒀다.
		"㈛ 🔍 **두 번 확인** + 재시도     ", "㈜ ⏪ **되감는** 재시도(자)       ", "㈝ 🔍 두 번 확인 + ⏪ 되감기      ",
		"㈞ 🧨 넷 섞음 · 재시도 끔(기준)   ", "㈟ 🧨 **충돌 둘** · 재시도 끔(기준)", "㈠ 🧨 충돌 둘 · 🔍 두 번 확인     ",
		// 🧪 **음성을 되찾는다**(D183 · 규율 57) — D182 가 **+18.9%p** 를 냈는데
		//   음성을 빼먹어 **「고침」인지 「걸음」인지** 못 갈랐다. 이번엔 셋을 나란히 둔다.
		//   ⚠️⚠️ ㈦·㈧ 이 **가장 정직한 음성**이다 — 시험도 갈아타기도 없이 **걸음만** 준다.
		"㈡ 🧨 넷 섞음 · 끔(기준)         ", "㈢ ⏪ **되감는 재시도**(재현)     ", "㈣ ⛔ 되감기 + **걸음만 더**      ",
		"㈤ ⛔ 되감기 + **무작위 재시도**  ", "㈦ ⛔ **예산만 24**(시험 없음)    ", "㈧ ⛔ **예산만 32**(더 큰 음성)   ",
		// 🎲 **씨앗 분산을 잰다**(D184 · 규율 58) — **성능 판이 아니라 계기 판**이다.
		//   ★ D182(+18.9%p) ↔ D183(−15.7%p) 이 **씨앗만 달랐다** ⇒ 스윙 34.6%p.
		//     문턱 공식은 **에피소드 독립**을 가정하는데 한 팔은 **학습 궤적 하나**다
		//     (`aw`/`aw2`/`ow` 가 `sd` 마다 리셋되지 않는다 ⇒ 1800 판이 한 줄기다).
		//   ⇒ ★ 세 설정 x 씨앗 여섯으로 **씨앗 간 표준편차**를 내고 그것으로 문턱을 다시 만든다.
		//   ⚠️ C(문맥 없음)를 넣은 이유: D178 의 핵심 주장(*문맥이 값을 한다*)도 **같은 자로** 잰다.
		"🎲A0 ⬜ 끔(기준)      ", "🎲A1 ⬜ 끔(기준)      ", "🎲A2 ⬜ 끔(기준)      ", "🎲A3 ⬜ 끔(기준)      ", "🎲A4 ⬜ 끔(기준)      ", "🎲A5 ⬜ 끔(기준)      ",
		"🎲B0 ⏪ 되감는 재시도  ", "🎲B1 ⏪ 되감는 재시도  ", "🎲B2 ⏪ 되감는 재시도  ", "🎲B3 ⏪ 되감는 재시도  ", "🎲B4 ⏪ 되감는 재시도  ", "🎲B5 ⏪ 되감는 재시도  ",
		"🎲C0 ⛔ 문맥 없음     ", "🎲C1 ⛔ 문맥 없음     ", "🎲C2 ⛔ 문맥 없음     ", "🎲C3 ⛔ 문맥 없음     ", "🎲C4 ⛔ 문맥 없음     ", "🎲C5 ⛔ 문맥 없음     ",
		// 🧱 **재현되는 실험대**(D185 · 규율 59) — 팔 하나가 **씨앗 여섯**이다.
		//   ★ 여태 팔 하나가 궤적 하나였다 ⇒ **모든 판이 실은 n = 1** 이었다.
		//   ⭐ 그리고 **σ 를 줄이는 길**을 같이 시험한다 — 학습률(↓/↑)과 칸 수.
		//   ⚠️ 🧱N(문맥 없음)은 **작동 판정의 음성**이다 — σ 가 1%p 근처로 나와야 한다(D184: 0.79).
		"🧱R 기준(lr .05)  x6      ", "🧱L 📉 **학습률 .02**  x6   ", "🧱H 📈 학습률 .10      x6   ",
		"🧱C 🧮 **칸 둘**(aCtx=bit) x6", "🧱N ⛔ 문맥 없음(음성)  x6   ",
		// 🤝 **칸 사이에 정보를 공유한다**(D186 · 규율 60 의 처방).
		//   실효 = **공통 `aw0[k]` + 보정 `aw[ctx][k]`** · 보정의 학습률만 낮춘다
		//   ⇒ 초반엔 공통이 지배하고 표본이 쌓이면 칸이 갈린다(초반 갈림이 σ 의 원천이었다).
		//   ⚠️ 씨앗을 D185 와 **같은 200** 으로 맞췄다 ⇒ 🤝0 은 🧱R 과 **값이 정확히 같아야** 한다.
		"🤝0 기준(공유 끔) x6 · 재현  ", "🤝1 🤝 **공통 + 보정 .2** x6 ", "🤝4 🤝 공통 + 보정 .5   x6 ",
		"🤝2 ⛔ 음성 **공통만**   x6  ", "🤝3 ⛔ 음성 **보정만**   x6  ",
		// 🏛️ **기둥을 씨앗 6 으로 다시 잰다**(D187 · 규율 62).
		//   ⚠️⚠️ D184·D185·D186 세 판이 *넷 섞음 세계에선 문맥이 손해*라고 말했는데
		//     나는 두 판을 σ 줄이는 데 썼다 ⇒ **잴 것이 없는 자리에서 자를 갈았다**.
		//   ⇒ ★ **문맥이 값을 하던 세계**로 돌아간다 — D179 의 자리(상황 셋 · 충돌 없음)
		//     거기서 문맥 **98.1%** ↔ 문맥 없음 **85.8%** = **+12.3%p** 였다(다만 그때 n = 1).
		//   ⭐ +12.3 은 σ 8.85 라도 |t| = 3.42 > 2.571 이라 **설 가능성이 있다**.
		//   ⚠️ 씨앗을 D179 와 같은 **40** 으로 맞췄다 ⇒ `rep 0` 이 그 값을 재현해야 한다.
		"🏛C ⭐ **문맥 있음**(D179 처방) x6", "🏛N ⛔ 문맥 없음        x6  ",
		"🏛R 🎲 무작위 문맥(음성)  x6  ", "🏛D ⭐ D178 의 자리(관측1) x6 ",
		// 🔨 **못을 박는다**(D188 · 규율 63) — D187 이 자리를 골라 줬다.
		//   🏛D(관측 넷 중 **하나만 살아**)에서 `문맥 − 문맥없음` = **+2.50%p** ·
		//   σ_diff **2.80** · |t| **2.19**(문턱 2.571) · **여섯 값에 음수가 하나도 없다**
		//   📐 필요 씨앗 = (2.571 x 2.80 / 2.50)^2 = **9** ⇒ **12 로 여유**(문턱 |t| > 2.201 · df=11)
		//   ⚠️ 씨앗을 40 으로 유지 ⇒ 앞 여섯 값이 D187 과 **정확히 같아야** 한다(재현 감시자).
		"🔨C ⭐ **문맥 있음**  x12    ", "🔨N ⛔ 문맥 없음      x12    ", "🔨R 🎲 무작위 문맥(음성) x12 ",
		// 🧨 **간섭을 같은 자로 확정한다**(D189 · 규율 63·64) — ㉡ **전체가 이것에 걸려** 있다.
		//   📐 예산을 먼저: 그 세계 σ_diff ≈ **8.57**(D184) · 효과 **−14.8%p**(D180)
		//     ⇒ 필요 씨앗 = (2.571 x 8.57 / 14.8)^2 = **2.2** ⇒ **6 으로 충분**하다.
		//   ⚠️ 씨앗을 D180 과 같은 **50** 으로 유지 ⇒ `rep 0` 이 그 값을 재현해야 한다
		//     (🧨2 = **51.0** · 🧨4 = **100.0** · 🧨M = **73.0**).
		//   ⭐ 판정은 **짝지어**(규율 64): 씨앗마다 `섞음 − (따로 넷의 평균)` 을 낸다.
		"🧨1 🎨 A색만(따로)    x6  ", "🧨2 📏 A크기만(따로)   x6  ", "🧨3 📍 A자리만(따로)   x6  ",
		"🧨4 🧨 B크기만(따로)   x6  ", "🧨M 🎲 **넷 섞음**    x6  ",
		// ⚔️ **서명이 같은 둘만 섞는다**(D190 · 규율 65 의 탐색 판).
		//   ★ D189 가 자리를 찾아 줬다 — 📍 A자리만과 🧨 B크기만이 **혼자서는 둘 다 100.0% · σ 0.00**
		//     이고 D180 이 **그 둘의 관측 서명이 같다**([0 0 100])고 찍었다.
		//   ⇒ ★ 따로가 결정적이라 **σ_diff = σ(섞음) 하나뿐**이다 — 넷 섞음의 σ_diff 12.78 은
		//     대부분 🎨색만(8.29)·📏크기만(7.86)이 실어 온 **잡음**이었다.
		//   ⚠️ 이것은 **탐색 판**이다(규율 65) — |t| 가 아니라 **σ 와 효과**를 재서 본 판 예산을 낸다.
		"⚔️1 📍 A자리만(따로)   x6  ", "⚔️2 🧨 B크기만(따로)   x6  ", "⚔️M 🎲 **순수 충돌 둘**  x6  ",
		// 📋 **상황 x 후보 성적표**(D191 · 규율 66) — 「답이 무엇인지」를 재는 계기판.
		//   ⚠️ D189·D190 두 판을 「충돌 짝」을 **추측**해서 썼다 — 이 표가 없었기 때문이다.
		//   ★ 균등 정책(lr = 0) + 갈아타기 끔 ⇒ 18 후보가 골고루 쓰이고 aSel 이 끝까지 간다.
		//   ★ 4 회 x 1800 = 7200 판 / (상황 4 x 후보 18) = **칸마다 100 판**.
		"📋 상황x후보 **성적표**(균등) x4",
		// 🎯 **진짜 충돌 짝에서 ㉡ 을 잰다**(D192) — D191 의 성적표가 자리를 찍어 줬다.
		//   📏➕i 는 색 100 / 크기 53 · 🔎➖i 는 색 50 / 크기 91
		//   ⇒ 한 후보 최선 76.5% ↔ 문맥이 있으면 95.5% ⇒ **폭 +19.0%p**(D188 의 9 배)
		//   ★ 두 상황은 oVC(색이 변했나) 하나로 갈리므로 kBCtx = 20(살아있는 관측 하나)로 충분하다
		//     ⇒ 자유도가 낮아 σ 가 작다(규율 63) ⇒ 씨앗 6 이면 넉넉하다
		//   ⚠️ D166 이 이 짝에서 「간섭이 없다」로 끝났다 — 그때는 **문맥이 없었다**(규율 39).
		"🎯C ⭐ **문맥 있음**(충돌둘) x6 ", "🎯N ⛔ 문맥 없음(충돌둘)   x6 ", "🎯R 🎲 무작위 문맥(음성)  x6 ",
		"🎯1 🎨 A색만(따로)      x6 ", "🎯2 📏 A크기만(따로)     x6 ",
		// 🔍 **왜 최적을 못 찾나 — lr 스윕**(D193 · 규율 67).
		//   ★ D192: 📏 A크기만 세계의 성적표 최적은 **🔎➖i 91%** 인데 학습기는 **52.2%** 다.
		//   ⭐⭐ 다른 트랙(MLT 152)이 **같은 모양**을 이미 풀었다:
		//     *용량이 손해로 보인 것이 실은 **lr 교란(과소적합)**이었고 lr x 0.5 가 최고 성적*
		//     ⇒ D192 의 「52.2 ↔ 91 못 찾음」이 정확히 그 모양일 수 있다.
		//   ⚠️ 그리고 D185 가 이미 봤다 — `lr .05` 가 **σ 최대이면서 평균 최소**였다
		//     (|t| 로는 안 섰지만 세 값의 방향이 일관됐다). 지금까지 **모든 판이 .05** 였다.
		//   📋 `kBTbl = 1` 로 **후보별 선택 빈도 + 도달률**을 같이 찍는다(작동 판정이 그 줄이다).
		"🔍05 lr **.05**(기준·재현) x6 ", "🔍02 📉 lr **.02**       x6 ",
		"🔍01 📉 lr **.01**       x6 ", "🔍h 📉 lr **.005**      x6 ",
		// 🌟 **호기심을 넣는다**(D194 · 규율 68 의 처방) — `aeff += c / √(N[k]+1)`.
		//   ★ D193: σ 는 잡음이 아니라 **굳은 후보의 분포**다 ⇒ **어디로 굳느냐**를 바꾼다.
		//   ⛔ 음성 = **무작위 가산점**(c < 0) — 탐험은 같고 정보만 0 이다
		//     ⇒ 「탐험이 늘어서」와 「덜 써 본 것을 밀어서」가 그 자리에서 갈린다.
		//   ⚠️ `kBSw = 1` 을 **유지**했다(D193 과 짝지어 비교 · 검산 고리 10)
		//     ⇒ 작동 판정은 **선택 빈도**(aSel 기준 · 갈아타기와 무관)만 쓴다. **도달률은 오염된다.**
		//   ⚠️ 규율 69 — 예상 효과를 **반으로**: (91−52)/2 = **+20%p**.
		//     안 들을 이유: 호기심은 「덜 써 본 것」을 밀지만 **「좋은 것」을 밀지 않는다**
		//     ⇒ 18 후보 중 나쁜 것이 대부분이면 **탐험이 성적을 깎을 수 있다**.
		"🌟0 c=0(기준·재현)      x6 ", "🌟5 🌟 **c=0.5**        x6 ", "🌟1 🌟 **c=1.0**        x6 ",
		"🌟2 🌟 **c=2.0**        x6 ", "🌟R ⛔ 음성 **무작위 가산점** x6",
		// 🔀 **갈아타기를 끄면 91% 가 나오나**(D195 · 가장 값싼 판 · **ML 처분 결정의 자료**).
		//   ★ D194 의 실마리: 성적표에서 🔎➖i 가 48~51%(D193·D194)인데 **D191 은 91%** 였고
		//     차이는 셋이다 — `kBSw`(1↔0) · `lr`(.05↔0) · `kBCtx`(20↔0).
		//   ⇒ ★ **셋으로 사슬을 만든다**: 지금 → 갈아타기만 끔 → 균등
		//     그러면 **91% 가 어디서 사라지는지** 그 자리에서 보인다.
		//   ⚠️ 🔀U(균등)는 **자다**(규율 11) — 학습기가 아니라 「그 세계의 후보 성적」을 재는 것이다.
		"🔀1 갈아타기 **켬**(지금·재현) x6", "🔀0 🔁 갈아타기 **끔**      x6 ", "🔀U 🎲 **균등**(자·lr 0)   x6 ",
		// ✨ **갈아타기를 끈 채로 ㉡ 을 잰다**(D196) — D195 가 폭을 되살렸다.
		//   정보천장 76.1 → 92.5 · 바닥 75.0 ⇒ 폭 **+17.5%p**(D192 는 -0.4 였다).
		//   ⚠️⚠️ `kBSw = 0` 을 **전부**에 건다(규율 71 — 켰다 껐다 하지 않는다).
		//   ⚠️ 따로 둘(✨1·✨2)도 같은 설정으로 둬서 **그 판의 천장을 그 판에서** 잰다(규율 67).
		"✨C ⭐ **문맥 있음**(끔)   x6 ", "✨N ⛔ 문맥 없음(끔)     x6 ", "✨R 🎲 무작위 문맥(음성·끔) x6",
		"✨1 🎨 A색만(따로·끔)   x6 ", "✨2 📏 A크기만(따로·끔)  x6 ",
		// 🔗 **전이를 처음 잰다**(D198) — `concept.md` 의 절차를 그대로 따른다.
		//   ① **끊는다**: 한 상황을 **학습에서** 뺀다(`kBLrnSit` — 입력은 그대로, 갱신만 스킵)
		//   ② **같은 비용**: `kSd x kPer` 고정이라 에피소드 수가 같다(자동)
		//   ③ **선택적으로 무너지나**: 상황별 성적(D191 계기판)이 그 자리에서 답한다
		//   ⚠️ 방향을 **둘 다** 본다(🔗B 크기만 배움 ↔ 🔗C 색만 배움).
		//   ⚠️⚠️ 최적이 서로 **다르다**(📏➕i 는 색 100/크기 53 · 🔎➖i 는 색 50/크기 91)
		//     ⇒ 전이가 **음수**일 수도 있다 — 그것도 답이다.
		"🔗A 둘 다 배운다(기준)   x6 ", "🔗B 📏 **크기만 배운다**   x6 ", "🔗C 🎨 **색만 배운다**     x6 ",
		// 🧬 **위층도 끊는다**(D199 · 규율 72 의 검정) — 음의 전이의 범인이 공유된 `ow` 인가.
		//   ★ D198: 크기 → 색 **32.3%**(무작위 47% 대비 -14.7%p) — 그런데 aw[ctx] 는 칸별 독립이라
		//     안 배운 칸은 균등(≈47%)이어야 한다 ⇒ 위층이 새고 있다는 뜻이다.
		//   ⇒ `ow` 를 상황별로 나누면 **32.3 → 50%**(D191 성적표의 예측)로 올라야 한다.
		//   ⚠️ 방향을 둘 다 본다(🧬B/🧬Bs 크기만 배움 · 🧬C/🧬Cs 색만 배움).
		//   ⚠️ 🧬B·🧬C 는 D198 의 🔗B·🔗C 와 **같은 설정**이다 ⇒ 검산 고리 13.
		"🧬B 📏 크기만 배움·`ow` 공유 x6", "🧬Bs 🧬 크기만 배움·**나눔** x6",
		"🧬C 🎨 색만 배움·`ow` 공유  x6", "🧬Cs 🧬 색만 배움·**나눔**  x6",
		// 🔭 **주소에 상황을 넣어 본다**(D200 · 규율 73 의 검정 · **자**).
		//   ⚠️⚠️ 자이지 능력이 아니다(규율 11) — 상황을 그냥 주는 것이라 상한을 재는 데만 쓴다.
		//   ★ D199: ow 를 나눠도 aCtx = oSel*2 + bit 라 고른 값이 겹치면 칸이 겹친다.
		//   ⇒ aCtx += epSit*8 로 겹침을 원리적으로 없앤다(칸 8 → 32).
		//   ⚠️ 🔭B 는 D199 의 🧬Bs 와 **같은 설정**이다 ⇒ 검산 고리 14.
		"🔭B 📏 크기만·`ow`나눔(재현) x6", "🔭Ba 🔭 크기만·**주소에 상황** x6", "🔭Ca 🔭 색만·**주소에 상황**  x6",
		// 🧱 **두 번째 자리의 폭을 잰다**(D202 · 닫힘 조건 ㉠ 을 채점한다).
		//   ⚠️ ㉠ 의 문턱은 「정보천장 - 바닥 < 5%p 가 **두 자리**에서」이고 지금 **1/2** 다
		//     (D196 의 A색↔A크기 자리는 활용률 95% 로 소진).
		//   ⇒ 두 번째 자리 = 🎲 **넷 섞음**(kBCf = 1). 전부 kBSw = 0 으로 공정하게 잰다.
		//   🧱 바닥 = 🧱N(문맥 없음)의 실측 · 🏔️ 천장 = 평균(따로 넷) — D196 과 **같은 정의**다.
		//   ⚠️⚠️ 규율 75 를 지킨다 — **바닥을 그 자리에서 재고** 그 뒤에 (핵심)을 쓴다.
		"🧱C ⭐ 넷섞음·문맥 있음   x6 ", "🧱N ⛔ 넷섞음·문맥 없음   x6 ", "🧱a 🎨 A색만(따로·끔)   x6 ",
		"🧱b 📏 A크기만(따로·끔)  x6 ", "🧱c 📍 A자리만(따로·끔)  x6 ", "🧱d 🧨 B크기만(따로·끔)  x6 ",
		// 📉 **곡선을 그린다 — 상황 수 2·3·4**(D203 · 규율 76 의 정량판 · 닫힘 ㉠ 을 결정한다).
		//   D196(둘 **+19.78%p**) ↔ D202(넷 **-18.12%p**) 사이에 **상황 셋**이 비어 있다.
		//   ⇒ 부호가 **어디서** 뒤집히나. 셋에서도 음수면 쓸 수 있는 자리가 「둘」 하나뿐이고
		//     그것은 이미 소진(활용률 95%)이다 ⇒ ★ 그때는 ㉠ 을 **2/2 로 세는 것이 정직하다**.
		//   ⚠️ 따로 셋(🧱a·🧱b·🧱c)은 D202 가 이미 쟀다(95.0 · 85.1 · 100.0) ⇒ 천장 **93.4**.
		//   🧱 바닥은 📉N(문맥 없음)의 실측 · 성적표가 세계별 균등도 같이 찍는다(규율 75).
		"📉C ⭐ 셋섞음·문맥 있음   x6 ", "📉N ⛔ 셋섞음·문맥 없음   x6 " };
		static const int kBDi[kBA] = { 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20,
			20, 20, 20, 20,
			20, 20, 20,
			20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20,
			20, 20, 20, 20, 20, 20, 20,
			21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21,
			21, 21, 21, 21, 21, 21, 21, 21, 21,
			21, 21, 21, 21, 21,
			21, 21, 21, 21, 21,
			21, 21, 21, 21,
			31, 32, 31, 31, 31, 31, 31, 32, 32, 32, 32,
			31, 31, 31,
			31, 31,
			31, 31,
			31, 31, 31, 31, 31, 31,
			31, 31,
			31, 31, 31,
			31, 31,
			31, 31,
			31, 31,
			31, 31,
			31, 32, 33, 31, 31, 31,
			32, 61, 31, 31, 31, 31,
			31, 31, 31, 31, 31,
			31, 31, 31, 31, 31, 31,
			31, 31, 31, 31, 31, 31,
			31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31,
			31, 31, 31, 31, 31,
			31, 31, 31, 31, 31,
			31, 31, 31, 31,
			31, 31, 31,
			31, 32, 33, 61, 31,
			33, 61, 31,
			31,
			31, 31, 31, 31, 32,
			32, 32, 32, 32,
			32, 32, 32, 32, 32,
			32, 32, 32,
			31, 31, 31, 31, 32,
			31, 31, 31,
			31, 31, 31, 31,
			31, 31, 31,
			31, 31, 31, 32, 33, 61,
			31, 31 };   // 방해자를 그리나
		// ⚡ **변하는 방해자**(D140) — 1 이면 프레임마다 색이 갈린다 ⇒ D139 의 관찰 근거가 깨진다.
		static const int kBMv[kBA] = { 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0,
			0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0,
			0, 0,
			0, 0,
			0, 0, 0, 0, 0, 0,
			0, 0,
			0, 0, 0,
			0, 0,
			0, 0,
			0, 0,
			0, 0,
			0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0, 0,
			0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0,
			0,
			0, 0, 0, 0, 0,
			0, 0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0,
			0, 0, 0, 0,
			0, 0, 0,
			0, 0, 0, 0, 0, 0,
			0, 0 };
		// ⚡⚡ **크기까지** 변하나(D141) — ㈈ 의 **잉크 키**가 정면으로 깨지는 자리다.
		static const int kBSz[kBA] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0,
			0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0,
			0, 0,
			0, 0,
			0, 0, 0, 0, 0, 0,
			0, 0,
			0, 0, 0,
			0, 0,
			0, 0,
			0, 0,
			0, 0,
			0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0, 0,
			0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0,
			0,
			0, 0, 0, 0, 0,
			0, 0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0,
			0, 0, 0, 0,
			0, 0, 0,
			0, 0, 0, 0, 0, 0,
			0, 0 };
		static const int kBPr[kBA] = { 0, 0, 1, 2, 3, 4, 4, 3, 5, 5, 6, 7, 7, 7, 8, 8, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9,
			9, 9, 9, 9,
			9, 9, 9,
			9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9,
			9, 9, 9, 9, 9, 9, 9,
			9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9,
			9, 9, 9, 9, 9, 9, 9, 9, 9,
			9, 9, 9, 9, 9,
			9, 9, 9, 9, 9,
			9, 9, 9, 9,
			9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9,
			9, 9, 9,
			9, 9,
			9, 9,
			9, 9, 9, 9, 9, 9,
			9, 9,
			9, 9, 9,
			9, 9,
			9, 9,
			9, 9,
			9, 9,
			9, 9, 9, 9, 9, 9,
			9, 9, 9, 9, 9, 9,
			9, 9, 9, 9, 9,
			9, 9, 9, 9, 9, 9,
			9, 9, 9, 9, 9, 9,
			9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9,
			9, 9, 9, 9, 9,
			9, 9, 9, 9, 9,
			9, 9, 9, 9,
			9, 9, 9,
			9, 9, 9, 9, 9,
			9, 9, 9,
			9,
			9, 9, 9, 9, 9,
			9, 9, 9, 9,
			9, 9, 9, 9, 9,
			9, 9, 9,
			9, 9, 9, 9, 9,
			9, 9, 9,
			9, 9, 9, 9,
			9, 9, 9,
			9, 9, 9, 9, 9, 9,
			9, 9 };   // 1 = 🔭 오라클 · 2·3 = 🔬 시험 · 4 = 🔎 관찰 · 5 = ⚡ 개입+예측 · 6 = ↩️ **되돌림**
		// 🧠 **학습률**(D143 파일럿) — `0` 이면 가중치가 안 움직인다(**N−1 대조군**).
		static const double kBndLr[kBA] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0.05, 0.0, 0.05, 0.05, 0.0, 0.05, 0.0, 0.0, 0.0, 0.0, 0.05, 0.0, 0.05, 0.05, 0.05, 0.05, 0.05, 0, 0, 0, 0, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05,
			0.05, 0.05, 0.05, 0.05,
			0.05, 0.05, 0.05,
			0.05, 0.05, 0.05, 0.05, 0.05, 0.0, 0.05, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
			0.05, 0.05, 0.05, 0.05, 0.05, 0.0, 0.05,
			0.05, 0.05, 0.05, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
			0.05, 0.05, 0.05, 0.05, 0.0, 0.0, 0.0, 0.0, 0.0,
			0.05, 0.05, 0.05, 0.05, 0.05,
			0.05, 0.05, 0.05, 0.05, 0.05,
			0.05, 0.05, 0.05, 0.05,
			0.05, 0.05, 0.05, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
			0.05, 0.05, 0.05,
			0.05, 0.05,
			0.05, 0.05,
			0.05, 0.05, 0.05, 0.05, 0.05, 0.05,
			0.05, 0.05,
			0.05, 0.05, 0.05,
			0.05, 0.05,
			0.05, 0.05,
			0.05, 0.05,
			0.05, 0.05,
			0.05, 0.05, 0.05, 0.05, 0.05, 0.05,
			0.05, 0.05, 0.05, 0.05, 0.05, 0.05,
			0.05, 0.05, 0.05, 0.05, 0.05,
			0.05, 0.05, 0.05, 0.05, 0.05, 0.05,
			0.05, 0.05, 0.05, 0.05, 0.05, 0.05,
			0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05,
			0.05, 0.02, 0.10, 0.05, 0.05,
			0.05, 0.05, 0.05, 0.05, 0.05,
			0.05, 0.05, 0.05, 0.05,
			0.05, 0.05, 0.05,
			0.05, 0.05, 0.05, 0.05, 0.05,
			0.05, 0.05, 0.05,
			0.0,
			0.05, 0.05, 0.05, 0.05, 0.05,
			0.05, 0.02, 0.01, 0.005,
			0.05, 0.05, 0.05, 0.05, 0.05,
			0.05, 0.05, 0.0,
			0.05, 0.05, 0.05, 0.05, 0.05,
			0.05, 0.05, 0.05,
			0.05, 0.05, 0.05, 0.05,
			0.05, 0.05, 0.05,
			0.05, 0.05, 0.05, 0.05, 0.05, 0.05,
			0.05, 0.05 };
		// 📉 **기준선을 과제군별로 두나**(D145) — `1` 이면 색 과제와 크기 과제의 기준선을 **따로**
		//   굴린다. ★ 규율 11(**부분집단을 미리 정해 두고 그 안에서도 본다**)을 **채점**에 적용한 것이고,
		//   근거는 D144 의 진단이다(기준선이 0.501 까지 올라 advantage 가 작아졌다).
		static const int kBndSb[kBA] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
			1, 1, 1, 1,
			1, 1, 1,
			1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
			1, 1, 1, 1, 1, 1, 1,
			1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
			1, 1, 1, 1, 1, 1, 1, 1, 1,
			1, 1, 1, 1, 1,
			1, 1, 1, 1, 1,
			1, 1, 1, 1,
			1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
			1, 1, 1,
			1, 1,
			1, 1,
			1, 1, 1, 1, 1, 1,
			1, 1,
			1, 1, 1,
			1, 1,
			1, 1,
			1, 1,
			1, 1,
			1, 1, 1, 1, 1, 1,
			1, 1, 1, 1, 1, 1,
			1, 1, 1, 1, 1,
			1, 1, 1, 1, 1, 1,
			1, 1, 1, 1, 1, 1,
			1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
			1, 1, 1, 1, 1,
			1, 1, 1, 1, 1,
			1, 1, 1, 1,
			1, 1, 1,
			1, 1, 1, 1, 1,
			1, 1, 1,
			1,
			1, 1, 1, 1, 1,
			1, 1, 1, 1,
			1, 1, 1, 1, 1,
			1, 1, 1,
			1, 1, 1, 1, 1,
			1, 1, 1,
			1, 1, 1, 1,
			1, 1, 1,
			1, 1, 1, 1, 1, 1,
			1, 1 };
		// 🎲 **상황 섞임**(D148) — `1` 이면 에피소드마다 방해자가 **색만** 변하거나 **크기만** 변한다.
		//   ⇒ 상황마다 **옳은 (행동,키) 짝이 갈린다** ⇒ **한 행동으로는 못 이긴다**.
		static const int kBMix[kBA] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0,
			0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0, 0,
			0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
			1, 1, 1,
			1, 1,
			1, 1,
			1, 1, 1, 1, 1, 1,
			1, 1,
			1, 1, 1,
			1, 1,
			1, 1,
			1, 1,
			1, 1,
			0, 0, 0, 1, 1, 1,
			0, 0, 1, 1, 1, 1,
			1, 1, 1, 1, 1,
			1, 1, 1, 1, 1, 1,
			1, 1, 1, 1, 1, 1,
			1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
			1, 1, 1, 1, 1,
			1, 1, 1, 1, 1,
			1, 1, 1, 1,
			1, 1, 1,
			0, 0, 0, 0, 1,
			0, 0, 1,
			1,
			1, 1, 1, 0, 0,
			0, 0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0,
			1, 1, 1, 0, 0,
			1, 1, 1,
			1, 1, 1, 1,
			1, 1, 1,
			1, 1, 0, 0, 0, 0,
			1, 1 };
		// 📌 **후보를 못 박나**(D148) — `-1` = 학습기가 고른다 · `0·1·2` = 그 후보에 고정한다.
		//   ⚠️ 고정 팔들이 **「어떤 단일 행동도 못 이긴다」의 증인**이다(각 상황의 천장을 준다).
		static const int kBFix[kBA] = { -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 0, 1, 2, -1, -1, -1, -1, -1, -1, -1, 0, 1, 2, 3, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
			-1, -1, -1, -1,
			-1, -1, -1,
			-1, -1, -1, -1, -1, -1, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17,
			-1, -1, -1, -1, -1, -1, -1,
			-1, -1, -1, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17,
			-1, -1, -1, -1, -1, 3, 5, 9, 11,
			-1, -1, -1, -1, -1,
			-1, -1, -1, -1, -1,
			-1, -1, -1, -1,
			-1, -1, -1, 5, 6, 13, 16, 5, 6, 13, 16,
			-1, -1, -1,
			-1, -1,
			-1, -1,
			-1, -1, -1, -1, -1, -1,
			-1, -1,
			-1, -1, -1,
			-1, -1,
			-1, -1,
			-1, -1,
			-1, -1,
			-1, -1, -1, -1, -1, -1,
			-1, -1, -1, -1, -1, -1,
			-1, -1, -1, -1, -1,
			-1, -1, -1, -1, -1, -1,
			-1, -1, -1, -1, -1, -1,
			-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
			-1, -1, -1, -1, -1,
			-1, -1, -1, -1, -1,
			-1, -1, -1, -1,
			-1, -1, -1,
			-1, -1, -1, -1, -1,
			-1, -1, -1,
			-1,
			-1, -1, -1, -1, -1,
			-1, -1, -1, -1,
			-1, -1, -1, -1, -1,
			-1, -1, -1,
			-1, -1, -1, -1, -1,
			-1, -1, -1,
			-1, -1, -1, -1,
			-1, -1, -1,
			-1, -1, -1, -1, -1, -1,
			-1, -1 };
		// 🔄 **갈아타나**(D149) — `1` 이면 첫 후보가 **매치를 하나도 못 찾았을 때**(`dvArm < 0`)
		//   두 번째 후보로 간다. ★ 문맥은 **첫 후보의 정체**이고 방아쇠는 **관측(매치 0)**이다.
		static const int kBSw[kBA] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
			1, 1, 1, 1,
			1, 1, 1,
			1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			1, 1, 1, 1, 1, 1, 1,
			1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			1, 1, 1, 1, 1, 0, 0, 0, 0,
			1, 1, 1, 1, 1,
			1, 1, 1, 1, 1,
			1, 1, 1, 1,
			1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0,
			1, 1, 1,
			1, 1,
			1, 1,
			1, 1, 1, 1, 1, 1,
			1, 1,
			1, 1, 1,
			1, 1,
			1, 1,
			1, 1,
			1, 1,
			1, 1, 1, 1, 1, 1,
			1, 1, 1, 0, 1, 1,
			1, 1, 1, 1, 1,
			1, 1, 1, 1, 1, 1,
			1, 1, 1, 1, 1, 1,
			1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
			1, 1, 1, 1, 1,
			1, 1, 1, 1, 1,
			1, 1, 1, 1,
			1, 1, 1,
			1, 1, 1, 1, 1,
			1, 1, 1,
			0,
			1, 1, 1, 1, 1,
			1, 1, 1, 1,
			1, 1, 1, 1, 1,
			1, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0,
			0, 0, 0, 0,
			0, 0, 0,
			0, 0, 0, 0, 0, 0,
			0, 0 };
		// 🔀 **학습에 쓸 에피소드 수**(D151) — **`0` 이 기본**(= 옛 거동: 씨앗 전반).
		//   ⛔ 처음엔 기본을 `30` 으로 **적어 뒀다가** 밟았다: 이 판은 `kSd = 30`(`kPer = 60`)이라
		//     `sd < 30` 이 **늘 참**이 되어 **옛 팔들의 후반이 통째로 사라졌다**(함정 368).
		//     ★ 그래서 **기본을 0 으로 두고 읽을 때 편다** — 같은 사실이 두 곳에 살지 않는다.
		//   ⚠️ 그리고 **씨앗 단위는 눈금이 너무 굵었다**(가장 작은 점이 학습 120 에피소드인데
		//     그것으로도 **후반이 이미 100%**). ⇒ **에피소드 수**로 두고 점을 촘촘히 한다.
		static const int kBLrnEp[kBA] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0, 0, 180, 180, 180, 60, 600, 0, 0, 0, 0, 0, 0, 0, 60, 180, 600, 60, 180, 600, 180,
			0, 0, 0, 0,
			60, 180, 600,
			0, 0, 60, 180, 600, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0,
			0, 0,
			0, 0,
			60, 180, 600, 60, 180, 600,
			0, 0,
			0, 0, 0,
			0, 0,
			0, 0,
			0, 0,
			0, 0,
			0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0, 0,
			0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0,
			0,
			0, 0, 0, 0, 0,
			0, 0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0,
			0, 0, 0, 0,
			0, 0, 0,
			0, 0, 0, 0, 0, 0,
			0, 0 };
		// 🔀 **무엇을 물려받나**(D151) — `0` = 0 에서 시작 · `1` = ㈕ 가 배운 것 ·
		//   `2` = ⚠️ **부호를 뒤집은 것**(음성 대조 · 규율 14 — 크기는 같고 방향만 틀리다).
		// 🔀 **어느 라운드에서 도나**(D153 · 비트마스크) — `1` = `-mlbind` · `2` = `-mlsame` ·
		//   `3` = **둘 다**. ★ ㈕ 만 3 이다 — 물려줄 값을 만들고 동시에 새 라운드의
		//   **회귀 감시자**가 된다(규율 18: 안 바뀌어야 하는 팔을 같은 실행에 남긴다).
		static const int kBRnd[kBA] = { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
			1, 3, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
			2, 2, 2, 2,
			2, 2, 2,
			2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
			2, 2, 2, 2, 2, 2, 2,
			2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
			2, 2, 2, 2, 2, 2, 2, 2, 2,
			2, 2, 2, 2, 2,
			2, 2, 2, 2, 2,
			2, 2, 2, 2,
			2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
			2, 2, 2,
			2, 2,
			2, 2,
			2, 2, 2, 2, 2, 2,
			2, 2,
			2, 2, 2,
			2, 2,
			2, 2,
			2, 2,
			2, 2,
			2, 2, 2, 2, 2, 2,
			2, 2, 2, 2, 2, 2,
			2, 2, 2, 2, 2,
			2, 2, 2, 2, 2, 2,
			2, 2, 2, 2, 2, 2,
			2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
			2, 2, 2, 2, 2,
			2, 2, 2, 2, 2,
			2, 2, 2, 2,
			2, 2, 2,
			2, 2, 2, 2, 2,
			2, 2, 2,
			2,
			2, 2, 2, 2, 2,
			2, 2, 2, 2,
			2, 2, 2, 2, 2,
			2, 2, 2,
			2, 2, 2, 2, 2,
			2, 2, 2,
			2, 2, 2, 2,
			2, 2, 2,
			2, 2, 2, 2, 2, 2,
			2, 2 };
		// 🔢 **후보 수**(D153) — 옛 판은 셋(🔎·🎨·📏 = 전부 **빼기** 극성)이고 새 판은 **넷**이다.
		//   ⭐ 넷째 = **고르기 극성**(잉크가 **변한** 성분이 목표) — 방해자가 **둘**이면 빼기는
		//   하나만 빼고 나머지가 남아 **원리적으로 부족**하다 ⇒ 판이 서기 위한 최소 조건이다.
		static const int kBNA[kBA] = { 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
			3, 3, 3, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
			4, 4, 4, 4,
			4, 4, 4,
			18, 18, 18, 18, 18, 18, 4, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18,
			18, 18, 18, 18, 18, 18, 18,
			18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18,
			18, 18, 18, 18, 18, 18, 18, 18, 18,
			18, 18, 18, 18, 18,
			18, 18, 18, 18, 18,
			18, 18, 18, 18,
			18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18,
			18, 18, 18,
			18, 18,
			18, 18,
			18, 18, 18, 18, 18, 18,
			18, 18,
			18, 18, 18,
			18, 18,
			18, 18,
			18, 18,
			18, 18,
			18, 18, 18, 18, 18, 18,
			18, 18, 18, 18, 18, 18,
			18, 18, 18, 18, 18,
			18, 18, 18, 18, 18, 18,
			18, 18, 18, 18, 18, 18,
			18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18,
			18, 18, 18, 18, 18,
			18, 18, 18, 18, 18,
			18, 18, 18, 18,
			18, 18, 18,
			18, 18, 18, 18, 18,
			18, 18, 18,
			18,
			18, 18, 18, 18, 18,
			18, 18, 18, 18,
			18, 18, 18, 18, 18,
			18, 18, 18,
			18, 18, 18, 18, 18,
			18, 18, 18,
			18, 18, 18, 18,
			18, 18, 18,
			18, 18, 18, 18, 18, 18,
			18, 18 };
		static const int kBSeed[kBA] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 0, 0, 0, 0, 0, 0, 0, 1, 2, 0, 0, 0, 1, 1, 1, 2,
			0, 0, 0, 3,
			3, 3, 3,
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0,
			0, 0,
			0, 0,
			0, 0, 0, 0, 0, 0,
			0, 0,
			0, 0, 0,
			0, 0,
			0, 0,
			0, 0,
			0, 0,
			0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0, 0,
			0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0,
			0,
			0, 0, 0, 0, 0,
			0, 0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0,
			0, 0, 0, 0,
			0, 0, 0,
			0, 0, 0, 0, 0, 0,
			0, 0 };
		// 🎲 **난수 오프셋**(D151) — 기본은 팔 번호다(함정 296: 팔마다 다시 뿌린다).
		//   ★ 그런데 **전이를 비교하는 팔들은 같은 문제 열을 봐야** 공정하다 ⇒ ㈕ 와 ㈗㈘㈙㈚ 를
		//     **같은 오프셋 21** 로 묶는다(스트림 공유가 아니라 **시작이 같은 것**이다).
		static const int kBRs[kBA] = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13,
			14, 15, 16, 17, 18, 19, 20, 21, 22, 21, 21, 21, 21, 21, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30,
			30, 30, 30, 30,
			30, 30, 30,
			30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30,
			30, 30, 30, 30, 30, 30, 30,
			30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30,
			30, 30, 30, 30, 30, 30, 30, 30, 30,
			30, 30, 30, 30, 30,
			30, 30, 30, 30, 30,
			30, 30, 30, 30,
			30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30,
			30, 30, 30,
			30, 30,
			30, 30,
			30, 30, 30, 30, 30, 30,
			30, 30,
			30, 30, 30,
			30, 30,
			30, 30,
			30, 30,
			30, 30,
			40, 40, 40, 40, 40, 40,
			50, 50, 50, 50, 50, 50,
			60, 60, 60, 60, 60,
			70, 70, 70, 70, 70, 70,
			80, 80, 80, 80, 80, 80,
			100, 101, 102, 103, 104, 105, 100, 101, 102, 103, 104, 105, 100, 101, 102, 103, 104, 105,
			200, 200, 200, 200, 200,
			200, 200, 200, 200, 200,
			40, 40, 40, 40,
			40, 40, 40,
			50, 50, 50, 50, 50,
			50, 50, 50,
			50,
			50, 50, 50, 50, 50,
			50, 50, 50, 50,
			50, 50, 50, 50, 50,
			50, 50, 50,
			50, 50, 50, 50, 50,
			50, 50, 50,
			50, 50, 50, 50,
			50, 50, 50,
			50, 50, 50, 50, 50, 50,
			50, 50 };
		// 🔔 **갈아타기 방아쇠**(D155) — 「무엇을 보고 내 키를 의심하나」.
		//   `0` = 🕳️ **매치 0**(D149 의 옛것) · `1` = 🔔 **좁히고 남은 후보 ≠ 1** ·
		//   `2` = 🎲 **무작위**(같은 발화율 · **N−1 대조군**) · `3` = ⚠️ **뒤집음**(음성 대조 · 규율 14).
		//   ★ **왜 바꾸나**: 이 세계에서 옛 방아쇠는 **한 번도 안 울렸다**(D153·D154 = 0회).
		//     틀린 키도 **방해자 A 를 잡아** `dvArm >= 0` 이 되기 때문이다 ⇒ 문제가 「매치 0」이 아니라
		//     **「매치는 있는데 틀린 것」**으로 바뀌었다.
		//   ★ 새 신호는 **오라클이 아니라 관측**이다 — `_BindRead` 와 **똑같은 술어**로 지금 프레임을
		//     걸러 「내 키가 몇 개로 좁혔나」를 센다. 답을 안 보고 **자기 개입의 결과만** 본다.
		//   ⚠️⚠️ **`2`(무작위)가 결정적인 대조군이다** — 갈아타기는 그 자체로 **두 번째 시도**라
		//     아무 때나 당겨도 좋아질 수 있다. **같은 발화율**의 무작위와 갈려야 「방아쇠에 정보가 있다」다.
		static const int kBTg[kBA] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			1, 2, 3, 0,
			0, 0, 0,
			0, 1, 1, 1, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			1, 1, 1, 1, 1, 1, 1,
			1, 5, 4, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			1, 5, 4, 6, 1, 0, 0, 0, 0,
			1, 1, 1, 1, 1,
			1, 1, 1, 1, 1,
			1, 1, 1, 1,
			1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0,
			1, 1, 1,
			1, 1,
			1, 1,
			1, 1, 1, 1, 1, 1,
			1, 1,
			1, 1, 1,
			1, 1,
			1, 1,
			1, 1,
			1, 1,
			1, 1, 1, 1, 1, 1,
			1, 1, 1, 1, 1, 1,
			1, 1, 1, 1, 1,
			1, 1, 1, 1, 1, 1,
			1, 1, 1, 1, 1, 1,
			1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
			1, 1, 1, 1, 1,
			1, 1, 1, 1, 1,
			1, 1, 1, 1,
			1, 1, 1,
			1, 1, 1, 1, 1,
			1, 1, 1,
			1,
			1, 1, 1, 1, 1,
			1, 1, 1, 1,
			1, 1, 1, 1, 1,
			1, 1, 1,
			1, 1, 1, 1, 1,
			1, 1, 1,
			1, 1, 1, 1,
			1, 1, 1,
			1, 1, 1, 1, 1, 1,
			1, 1 };
		// 🔀 **누가 물려주나**(D155) — `1` = 🎭 **다른 판**(㈕ · 방해자 하나 · 후보 셋) ·
		//   `2` = ⭐ **같은 판**(Ⓔ · 이 세계 · 후보 넷).
		//   ⛔⛔ **여기가 🐛B 였다**: 예전엔 이것이 **조건식**(`kBSw && lr>0 && kBLrnEp==0 && kBSeed==0`)
		//     이었는데 **Ⓔ 도 그 조건을 만족**해서 ㈕ 가 남긴 값을 **덮었다** ⇒ D153·D154 가 「**다른 판**으로
		//     옮겨도 빨라진다(㉯)」고 적은 것이 실제로는 **같은 판**(㉮)이었다. **컴파일도 완주도 정상**이었다.
		//   ⇒ ★ 같은 사실이 두 곳에 살지 않게 **팔 표의 값**으로 못 박는다(규율 21 의 코드판).
		static const int kBDon[kBA] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0,
			0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0,
			0, 0,
			0, 0,
			0, 0, 0, 0, 0, 0,
			0, 0,
			0, 0, 0,
			0, 0,
			0, 0,
			0, 0,
			0, 0,
			0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0, 0,
			0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0,
			0,
			0, 0, 0, 0, 0,
			0, 0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0,
			0, 0, 0, 0,
			0, 0, 0,
			0, 0, 0, 0, 0, 0,
			0, 0 };
		// 🎚️ **갈아탄 판에서 첫 결정이 받는 보상의 비율 `c₁`**(D162) — `보상 = c₁ x 도달`.
		//   ★ `1.0` = 옛것(같은 보상) · `0.0` = 🩹 처방(**실패로 친다** · D156) · 그 사이가 **새 눈금**이다.
		//   ⚠️⚠️ 예전엔 이 자리가 **`kBFrs` 0/1** 이었다 — 연속 계수가 그것을 **완전히 덮으므로 지웠다**
		//     (`0 → 1.0` · `1 → 0.0`. Docs/Guide.md: *새 기능으로 이전 기능이 필요 없어지면 제거*).
		//   ★ **왜 폭부터 재나**(함정 246) — *적응의 값은 고정값들의 폭이 상한*이다.
		//     폭이 문턱을 안 넘으면 「배우게 한다」(㉡ 의 ㉯)는 **원리적으로 값을 못 낸다**.
		static const double kBFc[kBA] = { 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0,
			0.25, 0.50, 0.75, 1.00, 2.00,
			-1.00, -0.50, 0.0, 0.0, 0.0,
			0.0, 0.0, 0.0, 0.0,
			0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
			0.0, 0.0, 0.0,
			0.0, 0.0,
			0.0, 0.0,
			0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
			0.0, 0.0,
			0.0, 0.0, 0.0,
			0.0, 0.0,
			0.0, 0.0,
			0.0, 0.0,
			0.0, 0.0,
			0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
			0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
			0.0, 0.0, 0.0, 0.0, 0.0,
			0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
			0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
			0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
			0.0, 0.0, 0.0, 0.0, 0.0,
			0.0, 0.0, 0.0, 0.0, 0.0,
			0.0, 0.0, 0.0, 0.0,
			0.0, 0.0, 0.0,
			0.0, 0.0, 0.0, 0.0, 0.0,
			0.0, 0.0, 0.0,
			0.0,
			0.0, 0.0, 0.0, 0.0, 0.0,
			0.0, 0.0, 0.0, 0.0,
			0.0, 0.0, 0.0, 0.0, 0.0,
			0.0, 0.0, 0.0,
			0.0, 0.0, 0.0, 0.0, 0.0,
			0.0, 0.0, 0.0,
			0.0, 0.0, 0.0, 0.0,
			0.0, 0.0, 0.0,
			0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
			0.0, 0.0 };
		// 🧠 **`c₁` 을 배우나**(D163 · ㉡ 의 ㉯) — `0` = 고정(`kBFc`) ·
		//   `1` = 적응(초기 **0.50** 중립) · `2` = 적응(초기 **0.00** = 격자 최고값) ·
		//   `3` = ⚠️ **뒤집은 적응**(음성 — 갈아타기를 많이 시킨 후보에 **상**을 준다).
		//   ★ 규율 27: 갈 곳이 있다 — 3 은 **틀린 후보를 키우는** 방향이라 반드시 나빠져야 한다.
		static const int kBAd[kBA] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 1, 2, 3,
			0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0,
			0, 0,
			0, 0,
			0, 0, 0, 0, 0, 0,
			0, 0,
			0, 0, 0,
			0, 0,
			0, 0,
			0, 0,
			0, 0,
			0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0, 0,
			0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0,
			0,
			0, 0, 0, 0, 0,
			0, 0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0,
			0, 0, 0, 0,
			0, 0, 0,
			0, 0, 0, 0, 0, 0,
			0, 0 };
		// 🎯 **몇 칸을 흔드나**(D164) — `0` = **전부**(옛것 · 대조 갱신) · `k>0` = **k 칸**(고른 것 + 무작위 k−1) ·
		//   `-1` = ⚠️ **음성**(고른 것을 **빼고** 나머지 전부 = *참여 안 한 것만 흔든다* ⇒ 반드시 나빠야 한다).
		//   ★ D91: **`k=1` 일 때만 보호가 된다**(단조가 아니라 **계단**) · D94: **보호의 값은 묶음 수에 비례**.
		static const int kBK[kBA] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			1, 2, 4, -1,
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0,
			0, 0,
			0, 0,
			0, 0, 0, 0, 0, 0,
			0, 0,
			0, 0, 0,
			0, 0,
			0, 0,
			0, 0,
			0, 0,
			0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0, 0,
			0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0,
			0,
			0, 0, 0, 0, 0,
			0, 0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0,
			0, 0, 0, 0,
			0, 0, 0,
			0, 0, 0, 0, 0, 0,
			0, 0 };
		// 🔭 **주소에 상황을 넣는다**(D200 · 규율 73 의 검정) — `0` = 끔 · `1` = 켬.
		//   ⚠️⚠️ **이것은 자이지 능력이 아니다**(규율 11) — 상황(`epSit`)을 **그냥 주는 것**이라
		//     학습기가 스스로 알아낸 것이 아니다. **상한을 재는 데만** 쓴다.
		//   ★ D199 가 범인을 **칸 주소**로 지목했다: `aCtx = oSel*2 + bit` 라
		//     `ow` 를 나눠도 고른 값이 겹치면 칸이 겹치고, 한 상황의 학습이 다른 상황을 덮는다.
		//   ⇒ 주소를 `epSit*8 + oSel*2 + bit` 로 만들면 그 겹침이 **원리적으로** 사라진다.
		//   ⚠️ 대가: 칸이 **8 → 32** 로 늘어 표본이 또 쪼개진다(규율 60) ⇒ 그것이 「안 들 이유」다.
		//   ⚠️ 기본 `0` 이라 옛 팔은 한 바이트도 안 바뀐다(규율 18).
		static const int kBAdr[kBA] = {
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 1, 1,
			0, 0, 0, 0, 0, 0,
			0, 0 };
		// 🧬 **위층을 상황별로 나눈다**(D199 · 규율 72 의 검정) — `0` = 공유(옛 거동) · `1` = 나눔.
		//   ★ D198 이 **음의 전이**를 찾았고(크기 → 색 **−14.7%%p**) 범인을 **공유된 `ow`** 로 지목했다:
		//     `aw[ctx]` 는 칸별 독립이라 안 배운 칸은 균등(≈47%%)이어야 하는데 **32.3%%** 였다.
		//   ⇒ 나누면 **32.3 → 50%%**(D191 성적표의 예측)로 올라야 한다.
		//   ⚠️ 대가는 **표본이 또 쪼개지는 것**이다(규율 60) ⇒ 그것이 「안 들 이유」다.
		//   ⚠️ 기본 `0` 이라 옛 팔은 한 바이트도 안 바뀐다(규율 18).
		static const int kBOwS[kBA] = {
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 1, 0, 1,
			1, 1, 1,
			0, 0, 0, 0, 0, 0,
			0, 0 };
		// 🔗 **전이 축**(D198) — `-1` = 전부 배운다(기본) · `0`/`1` = **그 상황만** 배운다.
		//   ★ `concept.md` 의 전이 절차 ① **끊는다**의 실물이다:
		//     *「앞 단계의 재료를 **학습에서** 뺀다 — 입력에서만 가리고 학습을 그대로 두면
		//       그것은 「못 쓰게 한 것」이 아니라 「이번에만 결석한 것」이다」*
		//   ⇒ 그래서 **정책 갱신만 건너뛴다**(입력도 채점도 그대로다).
		//   ⚠️ **평가는 전부** 한다 — 그래야 「안 배운 상황이 얼마나 되나」= 전이가 보인다.
		//   ⚠️ 절차 ② **같은 비용**은 자동이다(`kSd x kPer` 가 고정이라 에피소드 수가 같다).
		//   ⚠️ 기본 `-1` 이라 옛 팔은 한 바이트도 안 바뀐다(규율 18).
		static const int kBLrnSit[kBA] = {
			-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
			-1, 1, 0,
			1, 1, 0, 0,
			1, 1, 0,
			-1, -1, -1, -1, -1, -1,
			-1, -1 };
		// 🌟 **호기심 계수**(D194 · 규율 68 의 처방) — `aeff += c / √(N[k]+1)`.
		//   ★★★★★ **왜**: D193 이 σ 의 정체를 밝혔다 — **잡음이 아니라 「굳은 후보의 분포」**다
		//     (24 개 값이 이산값 아홉 개로 뭉쳤다) ⇒ **어디로 굳느냐**를 바꿔야 하고
		//     lr 로는 안 바뀐다(열 배 낮춰도 σ 가 오히려 두 배).
		//   ★ 엔진 `AIBrain::curiosity` 와 **같은 식**이다(이 저장소의 기존 관용구).
		//   ⚠️ **부호가 갈래다**: 양수 = 🌟 호기심(**덜 써 본 것**을 민다) ·
		//     **음수 = ⛔ 음성 「무작위 가산점」**(|c| 만큼 무작위로 민다 = **탐험은 늘리되 정보 0**)
		//     ⇒ ★ 그 둘이 갈라야 *「탐험이 늘어서」*와 *「덜 써 본 것을 밀어서」*가 구별된다.
		//   ⚠️ 기본 `0.0` ⇒ 옛 팔은 한 바이트도 안 바뀐다(규율 18).
		static const double kBCur[kBA] = {
			0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
			0.0, 0.5, 1.0, 2.0, -1.0,
			0.0, 0.0, 0.0,
			0.0, 0.0, 0.0, 0.0, 0.0,
			0.0, 0.0, 0.0,
			0.0, 0.0, 0.0, 0.0,
			0.0, 0.0, 0.0,
			0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
			0.0, 0.0 };
		// 📋 **상황 x 후보 성적표**(D191 · 규율 66 의 처방) — `1` 이면 그 표를 찍는다.
		//   ★ **왜**: D189·D190 **두 판**을 「충돌 짝」을 **추측**해서 썼다.
		//     충돌의 정의는 *관측이 같고 **답이 다르다***인데(규율 66)
		//     **답이 무엇인지를 재는 계기판이 없었다**.
		//   ⚠️ 성적표 팔은 **균등 정책**(`kBndLr = 0`)이고 **갈아타기를 끈다**(`kBSw = 0`)
		//     ⇒ 「그 후보로 끝까지 갔을 때」의 성적이 깨끗하게 쌓인다.
		static const int kBTbl[kBA] = {
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			1,
			0, 0, 0, 0, 0,
			1, 1, 1, 1,
			1, 1, 1, 1, 1,
			1, 1, 1,
			1, 1, 1, 1, 1,
			1, 1, 1,
			0, 0, 0, 0,
			0, 0, 0,
			1, 0, 0, 0, 0, 0,
			1, 0 };
		// 🤝 **칸 사이 정보 공유**(D186 · 규율 60 의 처방) — 아래층을
		//   `실효[ctx][k] = aw0[k] + aw[ctx][k]` 로 쪼갠다(**공통 + 칸별 보정**).
		//   ★ **왜**: σ 의 원천은 **칸마다 독립 정책**이라 초반 표본이 칸으로 쪼개지고
		//     **어느 칸이 어디로 굳나가 씨앗마다 달라지는 것**이다(D185: σ 6~9 배).
		//     ⇒ 보정의 학습률을 낮추면 **초반엔 공통이 지배**하고 표본이 쌓이면 칸이 갈린다.
		//   `0` = 끔(옛 거동 · `aw0` 이 늘 0) · `1` = 공통 1.0 + 보정 **0.2** ·
		//   `2` = ⛔ 음성 **공통만**(보정 0.0 ⇒ 문맥 없음과 같아야 한다) ·
		//   `3` = ⛔ 음성 **보정만**(공통 0.0 ⇒ 지금과 같아야 한다) · `4` = 공통 1.0 + 보정 0.5.
		//   ⚠️ 옛 팔은 전부 `0` 이다 ⇒ 한 바이트도 안 바뀐다(규율 18).
		static const int kBShr[kBA] = {
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 1, 4, 2, 3,
			0, 0, 0, 0,
			0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0,
			0,
			0, 0, 0, 0, 0,
			0, 0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0,
			0, 0, 0, 0,
			0, 0, 0,
			0, 0, 0, 0, 0, 0,
			0, 0 };
		// 🧱 **반복 축**(D185 · 규율 59) — 이 팔을 **씨앗 몇 개로** 돌릴 것인가.
		//   ★ **왜 이것이 필요한가**: 여태 팔 하나가 **학습 궤적 하나**였다
		//     (`aw`/`aw2`/`ow` 가 `sd` 마다 안 리셋된다) ⇒ **모든 판이 실은 n = 1 이었다**.
		//     D184 가 그 값을 쟀다 — 씨앗 간 **σ = 9~10%%p**(문맥 있는 설정) ⇒ 옛 문턱의 **4 배**.
		//   ⚠️ 기본이 **1** 이라 옛 팔은 **한 바이트도 안 바뀐다**(규율 18).
		//   💰 대가는 **시간**이다(그 팔만 배수로 는다) ⇒ 새 팔에만 켠다.
		static const int kBRep[kBA] = {
			1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
			6, 6, 6, 6, 6,
			6, 6, 6, 6, 6,
			6, 6, 6, 6,
			12, 12, 12,
			6, 6, 6, 6, 6,
			6, 6, 6,
			4,
			6, 6, 6, 6, 6,
			6, 6, 6, 6,
			6, 6, 6, 6, 6,
			6, 6, 6,
			6, 6, 6, 6, 6,
			6, 6, 6,
			6, 6, 6, 6,
			6, 6, 6,
			6, 6, 6, 6, 6, 6,
			6, 6 };
		// ⛔ **예산 덤 축**(D183 · 규율 57 의 음성) — 걸음 예산(16)에 이만큼 더한다.
		//   ★ **가장 정직한 음성**이다: 재시도 계열이 이긴 것이 *고침* 때문인지
		//     그냥 **걸음을 더 써서**인지 가른다(시험도 갈아타기도 **없이** 걸음만 준다).
		//   ⚠️ D182 가 이것을 빠뜨려 **+18.9%%p 를 해석하지 못했다**(규율 57 이 거기서 났다).
		static const int kBCap[kBA] = {
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 8, 16,
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0, 0,
			0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0,
			0,
			0, 0, 0, 0, 0,
			0, 0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0,
			0, 0, 0, 0,
			0, 0, 0,
			0, 0, 0, 0, 0, 0,
			0, 0 };
		// 🔍 **두 번 확인 축**(D182 · 규율 55 의 처방) — 시험 항해가 「됐다」를 내면
		//   **한 걸음 더 재서 같은지** 본다. `0` = 끔 · `1` = 켬.
		//   ★ **왜 이것이 거짓을 거르나**: 진짜 목표는 **어느 프레임에서나 그 셀**인데
		//     거짓 짝은 **방해자 변주에 얹혀 있다** ⇒ 프레임이 넘어가면 **안 버틴다**.
		//   ⚠️ 목표도 **그 프레임에서 다시 읽는다** — 안 그러면 방해자가 변한 만큼 목표 쪽도
		//     달라져서 **진짜까지 거짓으로 몰린다**(공정한 비교가 아니다).
		static const int kBVf[kBA] = {
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			1, 0, 1, 0, 0, 1,
			0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0, 0,
			0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0,
			0,
			0, 0, 0, 0, 0,
			0, 0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0,
			0, 0, 0, 0,
			0, 0, 0,
			0, 0, 0, 0, 0, 0,
			0, 0 };
		// 🔁 **재시도 축**(D181 · 규율 54 의 처방) — 갈아타기를 **방아쇠**가 아니라
		//   **결과**가 정하게 한다. `0` = 끔(옛 거동) · `1` = 재시도(**정책**이 두 번째를 고른다) ·
		//   `2` = ⛔ 음성 **무작위 재시도**(고른 것이 값을 하나) ·
		//   `3` = ⛔ 음성 **걸음만 더**(시험 항해는 하되 **안 갈아탄다** = 비용 통제).
		//   ⚠️ 옛 팔은 전부 `0` 이다 ⇒ 한 바이트도 안 바뀐다(규율 18).
		static const int kBRt[kBA] = {
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			1, 2, 3, 0, 1,
			1, 4, 4, 0, 0, 1,
			0, 4, 5, 6, 0, 0,
			0, 0, 0, 0, 0, 0, 4, 4, 4, 4, 4, 4, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0, 0,
			0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0,
			0,
			0, 0, 0, 0, 0,
			0, 0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0,
			0, 0, 0, 0,
			0, 0, 0,
			0, 0, 0, 0, 0, 0,
			0, 0 };
		// 🧨 **충돌 축**(D180) — `0` = 끔 · `1` = 상황 **넷**(넷째가 🧨 B 크기만) ·
		//   `2` = **충돌 둘만**(📏 A 크기만 ↔ 🧨 B 크기만) = 간섭을 **홀로** 재는 자리.
		//   ⚠️ 옛 팔은 전부 `0` 이다 ⇒ 한 바이트도 안 바뀐다(규율 18).
		static const int kBCf[kBA] = {
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			2, 2, 2, 2, 2, 1,
			1, 1, 1, 1, 2,
			1, 1, 1, 1, 2, 2,
			1, 1, 1, 1, 1, 1,
			1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
			1, 1, 1, 1, 1,
			1, 1, 1, 1, 1,
			0, 0, 0, 0,
			0, 0, 0,
			0, 0, 0, 0, 1,
			0, 0, 3,
			1,
			4, 4, 4, 0, 0,
			0, 0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0,
			4, 4, 4, 0, 0,
			4, 4, 4,
			4, 4, 4, 4,
			4, 4, 4,
			1, 1, 0, 0, 0, 0,
			0, 0 };
		// 🧭 **갈아타기 표의 문맥**(D167) — `0` = 첫 후보의 정체(D149) · `1` = ⭐ **관측**(좁힌 수) ·
		//   `2` = 둘 다 · `3` = ⚠️ **무작위**(음성 — 칸 수만 같고 정보가 0 ⇒ 표본만 나뉘어 손해여야 한다).
		static const int kBCtx[kBA] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			1, 2, 3,
			4, 5,
			6, 7,
			6, 6, 6, 0, 0, 0,
			8, 9,
			10, 11, 12,
			13, 14,
			15, 16,
			17, 18,
			19, 20,
			21, 21, 21, 21, 0, 22,
			21, 21, 21, 21, 22, 21,
			21, 21, 21, 21, 21,
			21, 21, 21, 21, 21, 21,
			21, 21, 21, 21, 21, 21,
			21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 0, 0, 0, 0, 0, 0,
			21, 21, 21, 19, 0,
			21, 21, 21, 21, 21,
			21, 0, 7, 20,
			20, 0, 7,
			21, 21, 21, 21, 21,
			21, 21, 21,
			0,
			20, 0, 7, 20, 20,
			20, 20, 20, 20,
			20, 20, 20, 20, 20,
			20, 20, 20,
			20, 0, 7, 20, 20,
			20, 20, 20,
			20, 20, 20, 20,
			20, 20, 20,
			20, 0, 20, 20, 20, 20,
			20, 0 };
		// 💰 **걸음 하나의 값**(D157) — 보상 = 도달 − `kBCst` x 걸음. `0` 이면 옛 보상 그대로다.
		//   ★ 눈금 근거: 05 ↔ 16 의 걸음 차가 **1.17** 이라 `c x 1.17` 이 advantage(~0.1)에 실려야 한다
		//     ⇒ 0.02(23%%) · 0.05(59%%) · 0.10(117%%) · 0.30(무너지나 보는 팔) · **−0.10(음성 대조)**.
		static const double kBCst[kBA] = { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
			0.0, 0.02, 0.05, 0.10, 0.30, 0.10, -0.10,
			0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
			0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
			0.0, 0.0, 0.0, 0.0, 0.0,
			0.0, 0.0, 0.0, 0.0, 0.0,
			0.0, 0.0, 0.0, 0.0,
			0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
			0.0, 0.0, 0.0,
			0.0, 0.0,
			0.0, 0.0,
			0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
			0.0, 0.0,
			0.0, 0.0, 0.0,
			0.0, 0.0,
			0.0, 0.0,
			0.0, 0.0,
			0.0, 0.0,
			0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
			0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
			0.0, 0.0, 0.0, 0.0, 0.0,
			0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
			0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
			0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
			0.0, 0.0, 0.0, 0.0, 0.0,
			0.0, 0.0, 0.0, 0.0, 0.0,
			0.0, 0.0, 0.0, 0.0,
			0.0, 0.0, 0.0,
			0.0, 0.0, 0.0, 0.0, 0.0,
			0.0, 0.0, 0.0,
			0.0,
			0.0, 0.0, 0.0, 0.0, 0.0,
			0.0, 0.0, 0.0, 0.0,
			0.0, 0.0, 0.0, 0.0, 0.0,
			0.0, 0.0, 0.0,
			0.0, 0.0, 0.0, 0.0, 0.0,
			0.0, 0.0, 0.0,
			0.0, 0.0, 0.0, 0.0,
			0.0, 0.0, 0.0,
			0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
			0.0, 0.0 };
		// ⚖️ **버려진 판을 살리나**(D160 · 함정 375 의 처방) — `1` 이면 키가 가리킨 것이 없을 때
		//   **폴백(`bl[0]`)으로 세어진다**. `0`(옛것)은 그 에피소드를 **통째로 버려** 분모를 갉는다.
		//   ⚠️⚠️ D159 실측: 버리면 분모가 1800 → **1284~1781** 로 갈리고 **도달률 순위가 뒤집혔다.**
		static const int kBKeep[kBA] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			1, 1, 1, 1, 1, 1, 1, 1, 1,
			1, 1, 1, 1, 1,
			1, 1, 1, 1, 1,
			1, 1, 1, 1,
			1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
			1, 1, 1,
			1, 1,
			1, 1,
			1, 1, 1, 1, 1, 1,
			1, 1,
			1, 1, 1,
			1, 1,
			1, 1,
			1, 1,
			1, 1,
			1, 1, 1, 1, 1, 1,
			1, 1, 1, 1, 1, 1,
			1, 1, 1, 1, 1,
			1, 1, 1, 1, 1, 1,
			1, 1, 1, 1, 1, 1,
			1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
			1, 1, 1, 1, 1,
			1, 1, 1, 1, 1,
			1, 1, 1, 1,
			1, 1, 1,
			1, 1, 1, 1, 1,
			1, 1, 1,
			1,
			1, 1, 1, 1, 1,
			1, 1, 1, 1,
			1, 1, 1, 1, 1,
			1, 1, 1,
			1, 1, 1, 1, 1,
			1, 1, 1,
			1, 1, 1, 1,
			1, 1, 1,
			1, 1, 1, 1, 1, 1,
			1, 1 };
		// 🔎 **먼저 바이트값을 잰다** — 손 상수를 쓰지 않는다. 팔레트 다섯을 각각 그려 `bl[0].v` 를
		//   읽고, 방해자만 더 그린 프레임에서 **새로 생긴 값**이 방해자다.
		uint8 pv[8] = {}; int npv = 0;
		for (int c = 0; c < nc && npv < 8; ++c)
		{
			uint8 v = 0; int64 cx = 0; uint64 ik = 0; int f = 0, t2 = 0, ms = 0;
			if (_BindRead(c, 1, 1, 0, 0, -1, -1, cell, plane, v, cx, ik, f, t2, ms)) pv[npv++] = v;
		}
		uint8 dByte = 0; bool dOk = false;
		{
			// 방해자를 켠 프레임에서 팔레트 값이 **아닌** 성분을 찾는다.
			DrawProgram pr;
			const String src = MLEpisodeGen::TaskCode(0, 1, 1, 0, 1);
			if (pr.Compile(src.View(), (uint32)cell, (uint32)cell, NameID("Bd0")) && pr.RunStart())
			{
				Bytes b; b.Reset(plane);
				if (ImageFormat::PackRGB332Delta(pr.canvas, nullptr, (uint8*)b.GetData(), plane))
				{
					const uint8* pb = (const uint8*)b.GetData();
					Blob bb[8]; const int nb = _Blobs(pb, cell, _BgByte(pb, plane), bb, 8);
					for (int k = 0; k < nb; ++k)
					{
						bool isPal = false;
						for (int q2 = 0; q2 < npv; ++q2) if (bb[k].v == pv[q2]) { isPal = true; break; }
						if (!isPal) { dByte = bb[k].v; dOk = true; break; }
					}
				}
			}
		}
		// ⭐ 손계산 대조 — 방해자 값이 팔레트 다섯 중 **몇 개보다 작은지**가 곧 예상 묶임 실패율이다.
		int nAbove = 0;
		for (int k = 0; k < npv; ++k) if (dByte < pv[k]) nAbove++;
		LogA("[ml] ── 🔗 **D137 · 묶임** — 대상 둘에서 「어느 속성이 어느 물체에」 ────────\n"
			"[ml]   🔎 **재서 얻은 바이트값** — 팔레트 %d개: %u %u %u %u %u │ 방해자 **%u**(%s)\n"
			"[ml]   ⭐ 방해자가 팔레트 **%d/%d** 보다 작다 ⇒ **예상 묶임 실패율 %.0f%%**"
			"(그만큼 `bl[0]` 이 방해자가 된다)\n"
			"[ml]   📌 **미리 등록**(재기 전에 적는다)\n"
			"[ml]     ㉠ 눈금 — 방해자 팔에서 **성분 수 2** 비율이 ~100%%(배관이 실제로 둘을 본다)\n"
			"[ml]     ㉡ 눈금 — **묶임 실패율**이 위 예상과 맞나(내 손계산의 검산이다)\n"
			"[ml]     ⭐ ㉢ **판정** — ㈁ 에서 **거짓 도달**(측정상 도달 ↔ 진실은 목표가 아니다)이"
			" **생긴다**(> 3.4%%p)\n"
			"[ml]     ⭐ ㉣ **판정** — ㈂ 가 거짓 도달을 **거의 0** 으로 만들고 진짜 도달률을 ㈀ 수준으로"
			" **회복**한다. ⚠️ 회복 못 하면 방해자가 **다른 경로로도** 해를 준다는 뜻이고 그것도 정보다\n"
			"[ml]   📌 **D138 추가 등록 — ㈃ 시험 한 걸음(오라클 없이)**\n"
				"[ml]     ⭐ ㉤ **판정** — ㈃ 가 거짓 도달을 **거의 0**, 진짜 도달을 **㈂ 수준**으로 만든다"
				" ⇒ ★ **오라클 없이 묶임이 풀린다**(concept.md 의 「묶임 빈 곳은 관찰 또는 시험으로」)\n"
				"[ml]     ⭐ ㉥ **판정** — 그 대가가 **걸음 하나**다 ⇒ 평균 걸음이 ㈂ 보다 **+0.7~1.3** 늘어난다"
				"(시험 한 걸음 + 색을 한 칸 돌린 것을 되돌리는 몫 — 색은 순환이라 손해가 **유계**다)\n"
				"[ml]     ⚠️ ㈃ 의 기제: 색을 한 칸 돌려도 **방해자는 안 변한다**(우리 행동에 반응하지 않는다)"
				" ⇒ **(값,잉크)가 그대로인 성분**이 방해자다. 팔레트 바이트가 서로 다르므로 목표는 반드시"
				" 값이 바뀐다 ⇒ **유일하게** 갈린다\n"
				"[ml]     ⚠️⚠️ 그리고 시험은 **실제 행동**이다 — 세계가 움직였고 그것을 걸음에 센다"
				"(공짜 관찰이 아니다)\n"
				"[ml]   📌 **D139 추가 등록 — 시험보다 관찰이 싼가**\n"
					"[ml]     ⭐ ㉦ **판정** — ㈄(시험을 **크기 축**에서)이 ㈃(색축)보다 걸음이 **줄어든다**."
					" 손계산: 색 과제(절반)는 크기가 이미 맞았는데 1칸 밀려 **+2**(시험1+복구1) · 크기 과제"
					"(절반)는 방향이 반반이라 **+1** ⇒ 기대 **+1.5**(㈂ 1.92 대비) = **약 3.4** ⇒ ㈃ 대비 **−1.0**\n"
					"[ml]     ⭐⭐ ㉧ **판정** — ㈅(**관찰만**)이 도달 **100%%** · 거짓 **0%%** 를 **0 걸음**에 낸다"
					"(걸음이 ㈂ 와 같다 ≈ 1.92). ★ 기제: 목표 프레임과 현재 프레임에 **방해자가 둘 다 그대로**"
					" 있고, **목표는 반드시 하나 이상 다르다**(그래야 과제다) ⇒ **(값,잉크)가 둘 다 같은 성분**은"
					" 방해자뿐이다\n"
					"[ml]     ⚠️ ㉧ 가 통과하면 D138 의 문장이 **한 겹 좁혀진다**: **시험은 관찰이 안 될 때만**"
					" **필요하다.** 그리고 `concept.md` 의 「**관찰** 또는 시험」이 정확했다는 뜻이다\n"
					"[ml]     ⚠️⚠️ 그리고 그 예고: **움직이는 방해자**에서는 관찰이 깨진다(방해자도 변한다)"
					" ⇒ 그때 시험이 다시 필요해진다 — 그것이 다음 축이다\n"
					"[ml]   📌 **D140 추가 등록 — 관찰이 깨지는 자리(색이 변하는 방해자)**\n"
						"[ml]     ⭐ ㉨ **판정** — ㈆(변하는 방해자 + 관찰)이 **깨진다**: `(값,잉크)` 가 안 맞아"
						" 방해자를 못 찾고 `bl[0]` 로 **떨어진다** ⇒ 도달이 ㈁ 수준(**~42%%**)으로 내려간다\n"
						"[ml]     ⭐ ㉩ **판정** — ㈇(변하는 방해자 + 시험)**도 깨진다**: 방해자가 **우리 행동과"
						" 무관하게** 변하므로 「안 변한 것」이 **없다** ⇒ 같은 폴백으로 떨어진다\n"
						"[ml]     ⭐⭐ ㉪ **판정** — ㈈(**개입+예측**)만 **선다**: 크기를 한 칸 올리면 목표의 **잉크가"
						" 변한다**(우리가 시킨 것) ↔ 방해자는 색만 바뀌어 **잉크가 그대로**(64) ⇒ **잉크로 갈린다**"
						" ⇒ 도달 **100%%** · 거짓 **0%%** · 걸음 ~3.1(㈄ 수준)\n"
						"[ml]     ⚠️⚠️ 그리고 **짝짓기 키가 색에서 잉크로 바뀐다** — 색이 변하는 방해자에서는"
						" 색이 **원리적으로 키가 될 수 없다**. ★ 그것이 이 판이 가르치는 것이다\n"
						"[ml]     ★ 그리고 ㈈ 는 `concept.md` 5단계 그대로다 — *인과는 이름으로 주어지지 않고"
						" **반복되는 개입과 반사실적 경험의 차이**에서 선다*\n"
						"[ml]   📌 **D141 추가 등록 — 방해자가 크기도 바꾼다(잉크 키가 깨진다)**\n"
							"[ml]     ⭐ ㉫ **판정** — ㈉(색+크기 + ⚡개입+예측)이 **깨진다**: 방해자 잉크가"
							" **36/64/144** 로 변하므로 **잉크가 키가 될 수 없다** ⇒ 폴백 ⇒ 도달 **~30%%**\n"
							"[ml]     ⭐⭐ ㉬ **판정** — ㈊(↩️**되돌리는 개입**)이 **선다**: `+1` 뒤 `−1` 이면"
							" **목표의 잉크는 원래로 돌아오고**(가역) 방해자는 순환을 계속 돌아 **안 돌아온다**"
							" ⇒ 도달 **100%%** · 거짓 **0%%** · 걸음 **~3.9**(개입 2 걸음 · 크기가 원복되니 복구 몫 **0**)\n"
							"[ml]     ⭐ ㉭ **극성이 뒤집힌다** — ㈈ 은 「잉크가 **안 변한** 것 = **방해자**」인데"
							" ㈊ 은 「(되돌린 뒤) 잉크가 **같은** 것 = **목표**」다. ★ **같은 문구가 반대를 뜻한다**"
							" — 뜻을 정하는 것은 문구가 아니라 **개입의 모양**이다\n"
							"[ml]     ⚠️ ㈊ 가 쓰는 키는 **자리**(`cx16`)다 — 이 판의 과제는 색·크기만 흔들어서"
							" 목표의 자리가 **안정된 키**다. ⚠️⚠️ 방해자가 **자리도** 바꾸면 그것도 깨진다(다음 축)\n"
							"[ml]   📌 **D143 파일럿 등록 — 학습기가 묶임을 배우나**(한 회차 제한)\n"
								"[ml]     ★ 형태: **짝 점수화** — (현재 성분, 목표 성분) 네 쌍에 `w·f` 점수를 주고 argmax 를"
								" 읽는다. 특징은 `[1, |Δ값|, |Δ자리|, |Δ잉크|]`(정규화) ⇒ **어느 성분이 목표인지 안 알려준다**\n"
								"[ml]     ⚠️⚠️ 채점은 **세계가 아는 진짜 도달**이다 — **측정 도달로 채점하면** 방해자 짝이"
								" 차이 0 이라 즉시 「됐다」가 되고 학습기가 **방해자를 고르는 것을 배운다**\n"
								"[ml]     ⭐ 그래서 배울 것이 한 줄이다: **「차이가 0 인 짝은 목표가 아니다」**\n"
								"[ml]     ⭐ ㉮ **판정** — 거짓 도달이 ㈁(**57.9%%**)에서 내려간다(> 3.4%%p)\n"
								"[ml]     ⭐⭐ ㉯ **판정** — 진짜 도달이 ㈅(**100.0%%** · 손 규칙)에 **닿나**."
								" ⚠️ 못 닿으면 그 격차가 **「손 규칙이 준 것」의 크기**이고 그것도 정보다\n"
								"[ml]     ⚠️ **관문** — ㈋ ↔ ㈌(**lr=0**)이 갈려야 한다. 안 갈리면 학습이 아무것도 안 한 것"
								"이고 **판정불가**다(함정 299 계열: 「주었다」와 「값이 들어갔다」는 다른 사실이다)\n"
								"[ml]     ⚠️⚠️ **전반 = 배운다(확률뽑기) · 후반 = 평가한다(argmax · 학습 정지)**"
									" ⇒ ★ **후반 숫자가 「배운 것」**이고 전체 평균은 그 둘의 혼합이라 읽지 않는다\n"
								"[ml]   📌 **D144 등록 — 막힌 세 자리를 뚫었다**(캔버스 2번째)\n"
									"[ml]     ㉠ **확률뽑기**(softmax) — `w=0` 이면 **균등**이라 초기 탐험이 자동 최대이고"
									" 배우면서 **저절로 좁아진다** ⇒ **ε 상수가 없다**\n"
									"[ml]     ㉡ **편향 제거** — 특징이 `[|Δ값|, |Δ자리|, |Δ잉크|]` **셋**이다(D143 은 편향으로"
									" 갱신이 새어 나갔다)\n"
									"[ml]     ㉢ **대조 갱신** — `f(고른 것) − Σ p·f` = **안 고른 것을 뺀 것** ⇒ 상대 순위가 움직인다\n"
									"[ml]     ⭐ **관문(먼저 본다)** — ㈋ ↔ ㈌(`lr=0`)이 **갈려야** 한다. 안 갈리면 판정불가다\n"
									"[ml]     ⭐⭐ **판정** — 거짓 도달이 ㈁(**57.9%%**)에서 내려가고 ㈅(**0%%**)에 얼마나 닿나 ·"
									" 그리고 **가중치가 양수로** 자라나(그것이 「차이가 0 인 짝은 목표가 아니다」의 모양이다)\n"
									"[ml]   📌 **D145 등록 — 기준선을 과제군별로**(캔버스 3번째 · **한 축**)\n"
										"[ml]     ★ 근거: D144 의 기준선이 **0.501** 까지 올라 `(r − b)` 가 작아졌다. 그런데 과제가"
										" **두 종류**(색만 / 크기만)이고 난이도가 다르다 ⇒ **한 기준선이 둘을 섞는다**\n"
										"[ml]     ★ 그것이 규율 11(**부분집단을 미리 정해 두고 그 안에서도 본다**)을 **채점**에"
										" 적용한 것이다(함정 206·209: 합계가 부분을 가린다)\n"
										"[ml]     ⭐ ㉰ **판정** — ㈍ 의 **후반** 진짜 도달이 ㈋(**51.3%%**)보다 오른다"
										"(문턱: n=900 · SE 1.67%%p ⇒ 차이 **4.7%%p**)\n"
										"[ml]     ⭐ ㉱ **판정** — 거짓 도달은 **0%% 를 유지**한다(안 나빠진다)\n"
										"[ml]     ⚠️ 그리고 **가중치가 더 커져야** 한다(advantage 가 제대로 서면 학습이 세진다)\n"
										"[ml]     ⚠️⚠️ 안 오르면 ⇒ 기준선이 원인이 **아니고** 남은 후보는 **특징**이다"
										"(교차 짝을 못 가른다) ⇒ 그것이 다음 판이고, **그것도 정보다**\n"
										"[ml]   📌 **D147 등록 — 행동을 고르는 자리를 만든다**(새 캔버스 1번째 · 겨냥 = **㉢ 자기가 만든 경험**)\n"
											"[ml]     ★ D146 심사가 가리켰다: 학습기가 고르던 것은 **읽기**뿐이라 ㉢ 이 **원리적으로** 0 이었다\n"
											"[ml]     ★ ㈎ 는 ㈈(개입+예측)과 **모든 것이 같고** 프로브 행동을 **사람이 못 박나 / 학습기가"
											" 고르나**만 다르다 ⇒ 완벽한 N−1 이다. 후보 셋 = 🔎 관찰만 · 🎨 색 한 칸 · 📏 크기 한 칸\n"
											"[ml]     ★ **읽는 규칙은 하나로 고정**(잉크가 그대로인 성분 = 방해자) ⇒ 갈리는 것은 **행동뿐**이다\n"
											"[ml]     ⚠️ **관문(먼저 본다)** — ㈎ ↔ ㈏(`lr=0` · 무작위)가 **갈려야** 한다."
											" 안 갈리면 자리가 배관으로만 있고 값을 안 한 것이고 **판정불가**다\n"
											"[ml]     ⭐ ㉲ **판정** — ㈎ 의 **후반** 진짜 도달이 **㈈(100.0%%)에 닿는다**(≥ **95%%**)\n"
											"[ml]     ⭐⭐ ㉳ **판정** — 선호가 **📏 크기**로 몰린다(`aw` 셋 중 그것이 **최대**)"
											" ⇒ ★ 그것이 「무엇을 해 보면 갈리는지 **스스로** 골랐다」의 모양이다\n"
											"[ml]     ⚠️ 규율 16 확인 — ㉳ 은 `aw` 의 **순서**를 말한다(크기가 아니다)."
											" 평가가 argmax 라 **순서가 곧 행동**이므로 판정 지표와 원리적으로 이어져 있다\n"
											"[ml]     ⚠️⚠️ **이 판의 한계를 미리 적는다** — 고를 때 아직 아무것도 안 봤다 ⇒ **문맥이 없는**"
											" 3팔 밴딧이다 ⇒ ㉢ 의 **절반**만 시험한다. 상황마다 답이 갈리는 판이 이 캔버스의 **2번째**다\n"
											"[ml]     ⚠️⚠️ 안 닿으면 ⇒ 원인은 **프로브 선택이 아니라 그 뒤의 읽기/정책**이고, 그것도 정보다\n"
											"[ml]   📌 **D148 등록 — 문맥을 준다: 상황마다 옳은 행동이 갈린다**(캔버스 2번째 · 겨냥 = **㉢**)\n"
												"[ml]     ★ 상황 둘을 에피소드마다 **정확히 반씩** 섞는다 — A = 방해자의 **색**만 변한다"
												"(D147 의 판) · B = 방해자의 **크기**만 변한다(**새로 여는 변주**)\n"
												"[ml]     ★ 후보는 **(행동, 읽는 키) 짝**이다 — 안 그러면 B 에 **답이 아예 없다**"
												"(잉크 키가 죽는다) ⇒ 새 축이 아니라 **이 판이 서기 위한 최소 조건**이다\n"
												"[ml]     🔎 관찰+값·잉크키: A 는 크기 과제만 · B ✗ │ 🎨 색+**값만**키: A ✗ · B **✅**"
												" │ 📏 크기+**잉크만**키: A **✅** · B ✗  ⇒ ★ **한 행동으로는 못 이긴다**\n"
												"[ml]     ⚠️ **관문(먼저 본다)** — ㈐ ↔ ㈑(`lr=0` 무작위)가 **갈려야** 한다\n"
												"[ml]     ⭐ ㉴ **판정** — **어떤 고정 팔도 90%% 를 못 넘는다**(㈒ 🔎 · ㈓ 🎨 · ㈔ 📏)"
												" ⇒ 그것이 **「문맥이 필요하다」의 실측 증거**다\n"
												"[ml]     ⭐⭐ ㉵ **판정** — ㈐ 의 선호가 **한 후보로 몰리고**(밴딧은 문맥을 못 본다) 후반이"
												" **최고 고정 팔을 크게 못 넘는다**(≤ +5%%p) ⇒ 그것이 **문맥 없는 천장**이다\n"
												"[ml]     ⚠️⚠️ 고정 팔 하나가 90%% 를 넘으면 ⇒ 상황이 **안 갈린 것**이고 내 손 검증이 틀렸다"
												" ⇒ 판을 다시 만든다. **그것도 정보다**(함정 365 가 바로 그 자리였다)\n"
												"[ml]   📌 **D149 등록 — 갈아타기: 자기 행동의 결과로 상황을 안다**(캔버스 3번째 · 겨냥 = **㉢**)\n"
													"[ml]     ★ 손 검증: **틀린 키를 고르면 매치가 하나도 안 나온다**(`dvArm < 0`) —"
													" A 에서 🎨 값 키는 방해자 값이 변해 매치 0 · B 에서 📏 잉크 키는 방해자 잉크가 변해 매치 0\n"
													"[ml]     ★ ⇒ 그 **「매치 0」이 곧 세계의 대답**이고 **관측에서 온 문맥**이다(축 이름이 아니다)"
													" ⇒ 실패하면 갈아타면 **반드시 맞는다**. 최적은 「📏 → 실패면 🎨」다\n"
													"[ml]     ⚠️ 대가는 **걸음 하나**다(두 번째 프로브도 실제 행동이다)\n"
													"[ml]     ⚠️ **관문(먼저 본다)** — ㈕ ↔ ㈖(`lr=0` · 무작위로 갈아탄다)가 **갈려야** 한다\n"
													"[ml]     ⭐ ㉶ **판정** — ㈕ 의 후반이 **㈐(75.6%%)보다 오른다**(문턱 4.6%%p)"
													" ⇒ **갈아타기 자체가 값을 한다**\n"
													"[ml]     ⭐⭐ ㉷ **판정** — ㈕ 의 후반이 **90%% 를 넘는다** ⇒ ★ D148 이 세운 **단일 행동의"
													" 천장을 넘은 것**이고, 그것은 **문맥을 실제로 썼다**는 뜻이다\n"
													"[ml]     ⭐ ㉸ **판정** — 갈아타기 표가 **서로 맞바꾼다**: 📏→🎨 그리고 🎨→📏\n"
													"[ml]     ⚠️ 규율 16 확인 — ㉸ 은 표의 **argmax**(순서)를 말한다. 평가가 argmax 라"
													" **그 순서가 곧 두 번째 행동**이므로 판정 지표와 원리적으로 이어져 있다\n"
													"[ml]     ⚠️⚠️ 안 오르면 ⇒ **매치 0 이라는 신호가 충분하지 않다**는 뜻이다"
													"(예: 틀린 키도 우연히 매치를 낸다) ⇒ 그것도 정보이고 다음 판은 **더 나은 방아쇠**다\n"
													"[ml]   📌 **D151 등록 — 재사용을 처음으로 잰다**(새 캔버스 1번째 · 겨냥 = **㉠ 재사용**)\n"
														"[ml]     ★ `concept.md` 의 수준 표대로 **㉮**(같은 판을 다시 풀 때 빨라지나)부터 잰다\n"
														"[ml]     ★ **학습 예산만 줄이고 평가는 그대로** 둔다 ⇒ 평가 n 이 안 줄어 문턱이 작다"
														"(예산을 씨앗으로 줄이면 평가 n=90 이라 문턱이 **12%%p** — 아무것도 못 가른다)\n"
														"[ml]     ★ **「몇 배」는 0 에서 시작한 곡선의 점 셋**으로 읽는다(학습 씨앗 **2 · 6 · 30**)\n"
														"[ml]     ⚠️ **가중치만** 물려준다(기준선은 안 준다 — 그것은 다음 축이다)\n"
														"[ml]     ⚠️ **관문(먼저 본다)** — ㈘(물려받음) ↔ ㈗(0 시작)이 **갈려야** 한다\n"
														"[ml]     ⚠️⚠️ **후반으로는 못 잰다**(첫 실행이 말했다): 학습 **120 에피소드**로도 후반이 이미"
															" **100%%** 다 ⇒ 예산이 병목이 아니다 ⇒ 그 시험은 **원리적으로 못 갈린다**(규율 13)\n"
														"[ml]     ★ 그래서 지표는 **전반(= 학습 구간)의 도달률**이다 — **재사용은 학습 곡선의"
															" 앞부분에만 있다**\n"
														"[ml]     ⭐ ㉹ **판정** — ㈘(물려받음)의 **전반**이 ㈗(0 시작)보다 오른다"
															"(n=180 · SE 3.3%%p ⇒ 문턱 **9.4%%p**)\n"
														"[ml]     ⭐⭐ ㉺ **판정 · 음성 대조**(규율 14) — ㈙(**부호 반전**)은 ㈗ 보다 **낮거나 같다**"
														" ⇒ 도운 것이 「물려받아서」가 아니라 **「그 값이라서」**임이 선다\n"
														"[ml]     ⚠️⚠️ ㈙ 도 오르면 ⇒ 도운 것은 값이 아니라 **초기 크기**(탐험이 좁아진 것)이고"
														" 그것도 정보다 — 그러면 다음 판은 **크기를 맞춘 음성 대조**다\n"
														"[ml]   📌 **D154 등록 — 「몇 배」를 잰다**(캔버스 2번째 · 겨냥 = **㉠** 수준 **㉯** 마무리)\n"
															"[ml]     ★ D153 이 ㉯ 를 세웠지만(**+5.9%%p**) **예산 점이 하나뿐**이라 배율을 못 말했다\n"
															"[ml]     ★ **두 곡선**을 나란히 둔다 — 0 에서 시작 ↔ 물려받음, 각각 **60 · 180 · 600**"
															"(900 점은 Ⓔ·Ⓕ 가 이미 준다) ⇒ 배율 = **같은 도달률에 닿는 예산의 비**\n"
															"[ml]     ⚠️ 지표는 **전반(= 학습 구간)** 이다(D151: 후반으로는 원리적으로 못 잰다)\n"
															"[ml]     ⚠️ 문턱이 예산마다 다르다 — n=60 ⇒ **14.6%%p** · n=180 ⇒ **8.4%%p** ·"
															" n=600 ⇒ **4.6%%p**(전부 2√2 × SE) ⇒ **작은 점은 오차 막대를 같이 읽는다**\n"
															"[ml]     ⭐ ㉼ **판정** — 물려받음 곡선이 0 시작 곡선 **위**에 있다(세 예산 **모두**)\n"
															"[ml]     ⭐⭐ ㉽ **판정** — 배율이 **> 2배**다. ⚠️ 곡선 밖이면 **하한**으로만 적는다"
															"(D151 이 그 자리였다 — 0 시작이 900 으로도 못 닿았다)\n"
															"[ml]     ⭐ ㉾ **음성 대조**(규율 14) — Ⓝ(부호 반전 · 180)이 Ⓘ(0 시작 · 180)보다 **낮다**\n"
															"[ml]     ⚠️⚠️ **먼저 볼 것 둘**: 📏 **성분수 3.00**(규율 21: 세계의 서명) ·"
															" ㈕ 의 재현(규율 18: 안 바뀌어야 하는 팔)\n"
			"[ml]   📌 **D155 등록 — 「매치 0」보다 나은 방아쇠**(새 캔버스 1번째 · 겨냥 = **㉢** 수준 **㉰** 로 가는 첫 칸)\n"
				"[ml]     ⚠️⚠️ **먼저 볼 것 셋**(규율 21·18) — 📏 **성분수 3.00**(세계의 서명) ·"
					" ㈕ **91.6%%** · ⭐ **Ⓡ = 옛 Ⓕ 93.7%%**(🐛B 를 고쳤으니 옛 거동은 이제 Ⓡ 다)\n"
				"[ml]     ⓪ 🐛 **배관 결함 셋을 같은 판에서 고쳤다** — 판정보다 **먼저** 읽는다:\n"
					"[ml]        🐛A `gSeedW2` 가 `[3][3]` 인데 `q < nAct`(=4)로 쓰고 읽었다 = **배열 밖**(UB)\n"
					"[ml]        🐛B 물려주는 팔이 **조건식**이라 **Ⓔ 가 ㈕ 를 덮었다** ⇒ D153·D154 의 「**다른 판**」이"
						" 실제로는 **같은 판**이었다 ⇒ ⭐ 이제 Ⓕ(㈕ · ㉯) ↔ Ⓡ(Ⓔ · ㉮)가 **같은 실행에서 갈린다**\n"
					"[ml]        🐛C 두 번째 키 표에 **⭐(고르기 극성)가 없어** 📏 로 떨어졌다 ⇒ 갈아타도 **정답에 못 갔다**\n"
				"[ml]     ⭐ ⓪-㊄ **정정 판정** — 곡선 **셋**을 나란히 둔다: 0시작(Ⓗ Ⓘ Ⓙ Ⓔ) ·"
					" 🎭 **다른 판**(Ⓚ Ⓛ Ⓜ Ⓕ = ㉯) · ⭐ **같은 판**(Ⓢ Ⓣ Ⓤ Ⓡ = ㉮)\n"
					"[ml]        ★ **Ⓡ 이 옛 Ⓕ(93.7%%)를 소수점까지 재현하면** D153·D154 가 잰 것이 **㉮ 였다**는 뜻이다\n"
					"[ml]        ⚠️ 그러면 `concept.md` 의 「㉠ 은 ㉯ 까지」를 **㉮ 로 되돌려야** 한다(규율 19 의 반대 방향)\n"
				"[ml]     ★ **왜 새 방아쇠인가** — 옛 것(`매치 0`)이 이 세계에서 **0회** 울렸다."
					" 틀린 키도 **방해자 A 를 잡기** 때문이다 ⇒ 신호를 **「좁히고 남은 후보 수」**로 바꾼다\n"
				"[ml]     ★ 손 예측(미리 적는다) — 🔎 관찰 **2** · 🎨 색 **2** · 📏 크기 **2** · ⭐ 극성 **1**"
					" ⇒ 「≠ 1」이 **넷을 정확히 가른다**(D153 도달 50.0 / 50.0 / 39.3 / 100.0%% 와 짝이 맞는다)\n"
				"[ml]     ★ 오라클이 아니다 — `_BindRead` 와 **같은 술어**로 내 키의 결과만 센다(정답을 안 본다)\n"
				"[ml]     ⭐ ㊀ **작동 판정**(이 판의 요점) — Ⓞ 의 **방아쇠가 당겨진다**(> 0)."
					" D153·D154 는 **0** 이었다 ⇒ 안 울리면 **㊁㊂ 는 판정불가**다\n"
				"[ml]     ⭐ ㊁ **값을 한다** — Ⓞ 전반 > Ⓔ 전반(**87.8%%**) + **3.1%%p**(2√2 x SE · n=900)\n"
				"[ml]     ⭐ ㊂ **정보가 있다**(핵심) — Ⓞ 전반 > Ⓟ(🎲 **같은 발화율**의 무작위 방아쇠) + **3.1%%p**\n"
					"[ml]        ⚠️⚠️ **이 대조군이 없으면 아무 말도 못 한다** — 갈아타기는 그 자체가 **두 번째 시도**라"
						" 아무 때나 당겨도 오를 수 있다. 갈리는 것은 **언제 당기나**뿐이다(N−1)\n"
				"[ml]     ⭐ ㊃ **음성 대조**(규율 14) — Ⓠ(⚠️ **뒤집은** 방아쇠 = 맞았을 때 당긴다)가 Ⓔ 보다 **낮다**\n"
				"[ml]     ⚠️ 규율 16 확인 — 방아쇠는 **고른 성분을 실제로 바꾼다**(첫 키를 버리고 다시 고른다)"
					" ⇒ 도달률을 원리적으로 바꿀 수 있다(잡음이 아니다)\n"
				"[ml]     ⚠️⚠️ 규율 19 — ✅ 라도 이 판은 **㉰ 가 아니다**: 후보 넷은 **여전히 사람이 적었다**."
					" 이 판이 여는 것은 **방아쇠를 관측에서 얻는다**까지다\n"
				"[ml]     ⚠️ 그리고 **이 세계에서는 「남은 수 = 1」이 「맞다」와 거의 동치**다 ⇒ 결론은 세계에 매여 있다"
					" — 다른 세계에서 다시 재야 한다\n"
			"[ml]   📌 **D156 등록 — 메뉴를 스스로 만든다**(이 캔버스 2번째 · 겨냥 = **㉢** 수준 **㉰**)\n"
				"[ml]     ★ **후보를 사람이 적는 것을 그만둔다** — 지금 넷은 사실 **세 축의 곱**이다:"
					" 행동 3(🔎🎨📏) x 극성 2(➖ 빼기 · ➕ 고르기) x 속성 3(v · i · b) = **18**\n"
				"[ml]     ★ 근거는 `concept.md` 의 그 한 줄이다 — *「인코딩 층의 구조는 주고, 분포 층의 구조는"
					" 배우게 한다」* ⇒ **축(원시형)은 주고 조합은 안 준다**\n"
				"[ml]     ⭐⭐ 손 메뉴 넷 = **{02 🔎➖b · 06 🎨➖v · 13 📏➖i · 16 📏➕i}** 이고,"
					" 손으로 따지면 ⭐ **17(📏➕b)도 100%% 정답**인데 **메뉴에 없었다**\n"
				"[ml]     ⚠️⚠️ **먼저 볼 것 셋**(규율 21·18) — 📏 성분수 3.00 · ㈕ **91.6%%** ·"
					" ⭐ 고정 팔 **🧩02/06/13/16 이 Ⓐ/Ⓑ/Ⓒ/Ⓓ(50.0/50.0/39.3/100.0)와 같은가**\n"
					"[ml]        ★ 마지막 것이 **통합 규칙 자체의 검산**이다 — 다르면 축 분해가 틀린 것이고"
						" **이 판의 모든 숫자가 판정불가**다(손 메뉴 팔은 옛 경로를 그대로 타므로 안 흔들린다)\n"
				"[ml]     ⓪ 🧩 **메뉴의 서명** — 고정 팔 **18** 이 각 후보의 천장을 준다. 판정보다 **먼저** 읽는다\n"
					"[ml]        ★ 손 예측: **16 과 17 만 100%%** · 12(📏➖v)와 15(📏➕v)는 **매치가 원리적으로 없다**"
						"(크기를 바꿔도 값은 안 변한다) ⇒ 폴백으로 떨어진다\n"
				"[ml]     ⭐ ㊅ **찾나** — Ⓥ(18-메뉴 · 900)의 argmax 가 **100%% 후보**(16 또는 17)다\n"
				"[ml]     ⭐ ㊆ **사람이 안 적은 것을 고르나**(㉰ 의 핵심) — 어느 팔에서든 argmax 가"
					" **손 메뉴 밖**(= 17 등)으로 간다. ⚠️ 안 가도 정보다 — 그러면 「18 중에서도 사람이 적은 것을"
					" 찾는다」이고 그것도 ㉰ 의 절반이다\n"
				"[ml]     ⭐ ㊇ **비용은 몇 배인가** — 18-메뉴 곡선(Ⓧ Ⓨ Ⓩ Ⓥ = 60/180/600/900) ↔ 4-메뉴 곡선"
					"(Ⓗ Ⓘ Ⓙ Ⓔ = 61.7/70.0/83.2/87.8%%). ⚠️ **어느 예산에서 잰 배율인지 같이 적는다**(규율 22)\n"
				"[ml]     ⭐ ㊈ **바닥**(N−1) — ⓐ(18-메뉴 · lr=0 = 균등 무작위)보다 Ⓥ 가 **높다**."
					" ⚠️ 메뉴가 4.5배 커졌으니 **무작위 바닥도 같이 내려간다** ⇒ 4-메뉴 바닥과 견주면 안 된다\n"
				"[ml]     🩹 ㊉ **「구제가 압력을 먹는다」 처방**(축 하나 · 4-메뉴 위에서) — ⓑ(갈아탄 판의"
					" **첫 결정 보상 = 0**)가 Ⓞ(**88.2%%**)보다 오르나. **작동 판정**: 첫 선호 ⭐ 가"
					" **Ⓔ 수준(3.238)으로 돌아오면서** 전반이 오른다\n"
					"[ml]        ⚠️ 안 오르고 **선호만 뾰족해지면** ⇒ 상쇄 가설은 맞았고 **이득은 딴 데** 있다는 뜻이다\n"
				"[ml]     ⚠️ 규율 24 확인 — ㊈(아래쪽 바닥)과 ㊇(위쪽 기준선) **둘 다** 등록했다\n"
			"[ml]   📌 **D157 등록 — 보상에 걸음을 싣는다**(이 캔버스 **3번째** · 겨냥 = **㉢** 수준 **㉰**)\n"
				"[ml]     ⚠️⚠️ **캔버스 3연속이다** ⇒ 다음 판은 **🛑 종료 심사**이고, 세계 축 `—` 도 **4연속**이라"
					" 그 다음은 **🎭 세계 판**이다(규율 17·20 — 미리 적어 둔다)\n"
				"[ml]     ★ **함정 372 의 직접 처방** — D156 이 100%% 후보 **셋**(🧩05 걸음 **1.92** ·"
					" 🧩16 **3.09** · 🧩17 **3.09**)을 드러냈는데 보상이 **도달만** 보므로 셋은"
					" **학습기에게 구별 불가능**했다 ⇒ Ⓨ 가 05 로 간 것은 **표집 잡음**이고 예산이 커지자 16 으로 돌아왔다\n"
				"[ml]     ⇒ 보상 = **도달 − c x 걸음**. 눈금 근거: 05↔16 의 걸음 차 **1.17** 에 c 를 곱한 값이"
					" advantage(~0.1)에 실려야 한다 ⇒ **0.02 · 0.05 · 0.10 · 0.30** 네 점 + ⚠️ **−0.10**(음성)\n"
				"[ml]     ⚠️ 벌은 **항상** 붙인다 — 성공했을 때만 붙이면 「실패는 공짜」가 되어 뜻이 흐려진다\n"
				"[ml]     ⚠️⚠️ **먼저 볼 것 넷**(규율 21·18) — 📏 성분수 3.00 · ㈕ **91.6%%** ·"
					" 🧩16 **100.0%%(걸음 3.09)** · ⓑ **93.6%%**(D156 의 🩹 재현)\n"
				"[ml]     ⭐ ㊊ **작동 판정**(먼저) — c > 0 인 팔의 **걸음이 ⓒ(c=0)보다 내려간다**."
					" 안 내려가면 벌이 **안 먹은** 것이고 ⇒ ㊋㊌ 는 **판정불가**다\n"
				"[ml]     ⭐ ㊋ **핵심** — argmax 가 ⭐ **🧩05(가장 싼 100%% 후보)**로 간다."
					" ⚠️ D156 의 같은 예산(900)에서는 **16** 이었다 — 그것이 대조다\n"
				"[ml]     ⭐ ㊌ **안 무너진다** — 전반 도달이 ⓒ 수준을 지킨다. ⚠️ 무너지면 **어디서** 무너지나가"
					" 곡선으로 나오고 **그것도 정보**다(c=0.30 이 그 자리를 보는 팔이다)\n"
				"[ml]     ⭐⭐ ㊍ **음성 대조**(규율 14) — ⓘ(c = **−0.10** = 걸음에 **상**을 준다)의 argmax 가"
					" **비싼 후보**로 가고 **걸음이 오른다**. ⇒ 「걸음이 정말 보상에 실렸나」의 직접 증명\n"
				"[ml]     ⭐ ㊎ **바닥**(규율 24 의 아래쪽) — ⓕ(c=0.10) > ⓗ(같은 c · **lr=0** 무작위)\n"
					"[ml]        ★ 위쪽 기준선은 ⓒ(c=0)다 — **둘 다 등록했다**(D155 가 그것으로 갈렸다)\n"
				"[ml]     ⚠️ 규율 16 확인 — 걸음 벌은 보상을 직접 바꾸고 보상이 argmax 를 정하므로"
					" **판정 지표(argmax·걸음)와 원리적으로 이어져 있다**\n"
				"[ml]     🩹 덤 — 이 팔들은 **🩹 처방을 18-메뉴 위에서** 켠 첫 팔이다(D156 은 4-메뉴에서만 쟀다)"
					" ⇒ ⓒ ↔ Ⓦ(**69.2%%**)가 그 값을 말한다\n"
			"[ml]   📌 **D159 등록 — 🎭 방해자가 자리도 바꾼다**(새 캔버스 1번째 · 겨냥 = **㉢** 수준 **㉰** ·"
				" 세계 축 = 🎭 **자리**)\n"
				"[ml]     ⛔⛔ **먼저: D158 심사의 손 예측을 정정한다** — 「천장 100%% → **60.5%%**」라고 적었는데"
					" **틀렸다.** 짓기 전에 손으로 따지니 그렇지 않다\n"
					"[ml]        ★ 이유: 매치 술어 `M` 은 **속성(v·i·b)만** 본다 ⇒ 자리 변동은 **후보 선택을 안 바꾼다.**"
						" 깨지는 것은 ➕ 가 **자리를 키로 삼는 자리**뿐이고, **목표는 자리를 안 바꾸므로**"
						" 목표를 옳게 집는 05·16·17 은 **멀쩡하다**\n"
					"[ml]        ⇒ ★ **「세계를 어렵게 했다」가 「그 후보가 깨진다」를 뜻하지 않는다**"
						"(규율 21 의 설계판 — 짓기 전에 손으로 죽였다)\n"
				"[ml]     📏 **다시 적는 손 예측**:\n"
					"[ml]        ㉠ ➖ 아홉은 **안 바뀐다**(키가 값/잉크라 자리와 무관)\n"
					"[ml]        ㉡ ➕ **05·16·17 은 100%% 를 지킨다**\n"
					"[ml]        ㉢ 🚨 ➕ **나머지 여섯은 도달률이 오르는 것처럼 보인다** — 방해자를 지목한 판에서"
						" `_BindRead` 가 실패해 그 에피소드가 **통째로 버려지기** 때문이다(**선택 편향**)\n"
					"[ml]        ㉣ ⇒ **에피소드 수가 1800 미만**으로 내려간다. ★ **그것이 세계의 서명**이고"
						" 동시에 **편향의 계기판**이다(규율 21) — 성능보다 **먼저** 읽는다\n"
				"[ml]     ⭐ **그래서 이 판의 겨냥은 「버려지던 것을 신호로 바꾸는 것」이다** —"
					" 🔔 **「내 지목이 사라졌다」**(`kBTg` 4·5)\n"
					"[ml]        ★ 한 프레임 더 그려 **내가 집은 자리에 아직 있나**를 본다. 오라클이 아니라"
						" **자기 개입의 결과**이고, 사람이 정한 것이 아니다 ⇒ **㉢ 의 자리**다\n"
					"[ml]        ⚠️ 확인도 **걸음 하나**다 ⇒ 걸음이 오르는 만큼을 이득에서 뺀다\n"
				"[ml]     ⚠️⚠️ **먼저 볼 것 넷**(규율 21·18) — 📏 성분수 3.00 · ㈕ **91.6%%** ·"
					" 🧩16(옛 세계) **100.0%%** · ⓒ **77.2%%**\n"
				"[ml]     ⭐ ㊐ **세계가 바뀌었나**(작동 판정 · 먼저) — 🎭 팔의 **에피소드 수 < 1800** 이고"
					" ➕ 팔에서만 그렇다. 안 그러면 세계가 **안 바뀐 것**이고 나머지는 **판정불가**다\n"
				"[ml]     ⭐ ㊑ **손 예측 넷이 맞나** — 특히 ㉢(선택 편향)이 **숫자로 보이나**\n"
				"[ml]     ⭐ ㊒ **핵심** — ⓚ(🔔+지목) 또는 ⓛ(지목만)이 ⓙ(남은≠1 만)보다 **에피소드를"
					" 더 살리면서**(수가 1800 에 가깝다) 도달이 안 내려간다\n"
					"[ml]        ★ **두 숫자를 같이 읽어야 한다** — 도달률만 보면 **버리는 쪽이 이긴다**(편향)\n"
				"[ml]     ⭐ ㊓ **바닥**(규율 24 아래쪽) — ⓙ > ⓜ(lr=0). 위쪽 기준선은 ⓒ(옛 세계 77.2%%)다\n"
				"[ml]     ⚠️ 규율 27 확인 — 음성 대조를 **안 뒀다**. 이 판의 ⓛ 이 그 자리를 겸한다"
					"(지목 검사가 **원리적으로 뜻이 없는** 옛 세계에서는 ⓛ 이 ⓙ 와 같아야 한다) ⇒ 다음 판의 숙제로 적는다\n"
			"[ml]   📌 **D160 등록 — ⚖️ 분모를 고쳐서 다시 잰다**(이 캔버스 2번째 · 겨냥 = **㉢** 수준 **㉰**)\n"
				"[ml]     ⛔⛔ **함정 375 의 직접 처방** — D159 에서 키가 가리킨 것이 사라진 판이 **통째로 버려져**"
					" 분모가 1800 → **1284~1781** 로 갈렸고, 그 탓에 도달률 순위가 **뒤집혔다**:\n"
					"[ml]        도달률 ⓙ **90.9** > ⓚ 88.2 > ⓛ 84.5(**−6.4%%p**) ↔"
						" **1800 분모** ⓚ **84.4** > ⓛ 83.6 > ⓙ 83.2(**+1.2%%p** = 문턱 2.44 **안**)\n"
					"[ml]        ⇒ ★ 그 갈림은 **전부 편향**이었다. **비율을 견주기 전에 분모가 같은지** 본다\n"
				"[ml]     ⇒ 처방: `kBKeep` — 키가 가리킨 것이 없으면 **버리지 말고 폴백(`bl[0]`)으로 산다**."
					" 그러면 그 판이 **세어지고, 틀리면 틀린 것으로 세어진다**\n"
				"[ml]     ⚠️⚠️ **먼저 볼 것 넷**(규율 21·18) — 📏 성분수 3.00 · ㈕ **91.6%%** ·"
					" 🧩16 **100.0%%** · ⭐ **ⓙ 1648 / ⓚ 1723 / ⓛ 1781 재현**(옛 팔은 그대로 둔다)\n"
				"[ml]     ⭐ ㊔ **작동 판정**(먼저) — ⚖️ 팔의 **에피소드가 전부 1800** 이다."
					" 아니면 분모가 아직 갈린 것이고 ⇒ **㊕㊖ 는 판정불가**다\n"
				"[ml]     ⭐ ㊕ **핵심** — 분모가 같아진 상태에서 ⓞ(🔔+지목) ↔ ⓝ(남은≠1)이"
					" 문턱 **2.44%%p** 를 넘나. ⚠️ D159 의 「−6.4%%p」는 편향이었으므로 **여기서 처음 판정된다**\n"
				"[ml]     ⭐⭐ ㊖ **음성 대조**(규율 27 의 숙제 · D157 이 빠뜨린 것) — ⓠ 는 지목이"
					" **아직 있을 때** 갈아탄다 = **멀쩡한 지목을 버린다** ⇒ ⓝ 보다 **반드시 낮아야** 한다\n"
					"[ml]        ★ 규율 27 대로 **갈 곳을 미리 적는다**: 옳게 집은 판을 버리는 것이므로"
						" 무너질 자리가 **원리적으로 있다**(D157 의 ⓘ 처럼 못 움직이는 팔이 아니다)\n"
				"[ml]     ⭐ ㊗ **바닥**(규율 24 아래쪽) — ⓝ > ⓡ(lr=0 · 같은 `keep`)\n"
				"[ml]     ⭐⭐ ㊘ **편향을 숫자로 못 박는다** — 고정 넷(⚖️03·05·09·11)은 D159 에서"
					" **버려지던 후보**다. `keep` 을 켜면 **에피소드가 1800 으로 돌아온다**\n"
					"[ml]        📏 **손 예측**: ⚖️**05** 는 D159 에서 **900판 100%%** 였다 ⇒ 살린 절반이"
						" 대개 **틀린 지목**이므로 **1800판에서 50~75%%** 로 내려간다\n"
					"[ml]        📏 ⚖️**09·11** 은 D159 에서 **에피소드 0**(= 값을 못 냈다) ⇒ 1800판이 되고"
						" 도달은 **폴백 수준**으로 찍힌다 ⇒ ★ 그 값이 곧 **「버림이 감췄던 진실」**이다\n"
				"[ml]     ⚠️ 규율 16 확인 — `keep` 은 **분모를 직접 바꾸고** 분모가 판정 지표(비율)를 정한다\n"
			"[ml]   📌 **D162 등록 — 🎚️ 「누구에게 책임을 물을까」의 폭을 잰다**"
				"(새 캔버스 1번째 · 겨냥 = **㉡ 선택적 수정** 수준 **㉯**)\n"
				"[ml]     ★ **왜 ㉡ 인가**(D161 심사 · 근거 셋) — ㉠ D158 이 **그 축이 값을 하는 것을"
					" 처음 쟀다**(🩹 = *성공의 공을 실제로 참여한 결정에만* ⇒ 4-메뉴 **+5.8** · 18-메뉴 **+8.0%%p**)"
					" ㉡ **㉡ 은 D86~D93 이후 수준이 한 번도 안 올랐다** ㉢ 관용구·함정이 이미 있다\n"
				"[ml]     ⚠️⚠️ **함정 246 — 적응의 값은 고정값들의 폭이 상한이다** ⇒ 「배우게 한다」 전에"
					" **폭부터** 잰다. 폭이 문턱을 안 넘으면 ㉯ 는 **원리적으로 값을 못 낸다**\n"
				"[ml]     🎚️ 축 = **`c₁`(갈아탄 판에서 첫 결정이 받는 보상의 비율)** — `보상 = c₁ x 도달`.\n"
					"[ml]        `0.00`(= 🩹 · **ⓝ 이 그 점**) · `0.25` · `0.50` · `0.75` · `1.00`(옛것) ·"
						" ⚠️ `2.00`(**음성**)\n"
					"[ml]        ⚠️ 옛 축 `kBFrs`(0/1)는 이것이 완전히 덮으므로 **지웠다**"
						"(Docs/Guide.md: *새 기능으로 이전 기능이 필요 없어지면 제거*)\n"
				"[ml]     ⚠️⚠️ **먼저 볼 것 넷**(규율 21·18) — 📏 성분수 3.00 · ㈕ **91.6%%** ·"
					" ⭐ **ⓝ 87.0%%**(= `c₁ 0.00` 재현) · ⓙ **1648판 90.9%%**\n"
				"[ml]     ⭐ ㊙ **작동 판정** — 격자 팔의 에피소드가 **전부 1800**(keep 켜짐). 아니면 판정불가\n"
				"[ml]     ⭐ ㊚ **폭**(이 판의 요점) — `max − min` 이 문턱 **2.24%%p** 를 넘나\n"
					"[ml]        ★ 넘으면 → 2번째 판에서 **배우게 한다**(㉡ 의 ㉯)\n"
					"[ml]        ★ 안 넘으면 → **「폭이 상한이다」의 재확인**이고 **그것도 답**이다(D95 가 그 자리였다)\n"
				"[ml]     ⭐⭐ ㊛ **형태** — 단조인가 **안쪽 최적**인가. ⚠️ D96 이 *폭은 미달인데 **형태가 답이었다***"
					" 를 남겼다 ⇒ 폭이 미달이어도 형태는 읽는다\n"
					"[ml]        📏 **손 예측**: **단조 감소**(`c₁` ↑ ⇒ 도달 ↓)로 본다 — `c₁` 이 클수록"
						" 「갈아타게 만든 후보」가 벌을 덜 받는다. ⚠️ **안쪽 최적이면 그것이 더 흥미롭다**\n"
				"[ml]     ⭐ ㊜ **음성 대조**(규율 27) — `c₁ = 2.00` 은 갈아탄 판의 첫 결정에 **더** 준다"
					" ⇒ `c₁ = 1.00` 보다 **낮아야** 한다. ★ **갈 곳이 있다**(틀린 후보를 상 주는 것이다)\n"
				"[ml]     ⭐ ㊝ **재현** — `c₁ 0.00`(ⓝ) ↔ `c₁ 1.00`(ⓥ) 의 차가 D158 의 **+8.0%%p** 언저리인가\n"
				"[ml]     ⚠️ 규율 16 확인 — `c₁` 은 **첫 결정의 갱신 부호를 직접 바꾼다** ⇒ argmax 와 도달을 바꿀 수 있다\n"
				"[ml]     ⚠️⚠️ D161 의 경고 — 앞 두 판이 **측정 쪽**이었다(방법론 과몰입 신호)"
					" ⇒ **이 판은 값을 내는 판이어야 한다**\n"
			"[ml]   📌 **D163 등록 — 🎚️ 넓히고 🧠 배우게 한다**(이 캔버스 2번째 · 겨냥 = **㉡** 수준 **㉯**)\n"
				"[ml]     ① 🎚️ **규율 33 — 최적이 끝값이었다** ⇒ `c₁ = −1.00 · −0.50` 을 더해"
					" **폭의 하한을 없앤다**(D162 의 6.3%%p 는 **하한**이다)\n"
					"[ml]        ★ `c₁ < 0` 의 뜻: 갈아탄 판의 첫 결정은 **성공해도 벌**이다\n"
				"[ml]     ② 🧠 **적응 `c₁` = 「책임 귀속」을 배운다**(㉡ 의 ㉯ = *범위 자체를 배운다*)\n"
					"[ml]        ★ **뜻**: 갈아탔다는 것이 **그 후보 탓**인가 **상황 탓**인가.\n"
					"[ml]           · 후보 `a` 의 갈아타기율이 **평균보다 높다** ⇒ **a 탓** ⇒ 첫 결정에 **덜** 준다\n"
					"[ml]           · 평균과 같다 ⇒ **상황 탓** ⇒ a 는 무죄 ⇒ **더** 준다\n"
					"[ml]        ⇒ `c₁[a] = 1 − 갈아타기율[a] ÷ 전체` — **관측만으로 계산되고 후보마다 다르다**\n"
					"[ml]        ⚠️ 반사실(*다른 후보였어도 갈아탔을까*)은 못 보므로 **비율로 근사**한다\n"
				"[ml]     ⚠️⚠️ **초기값을 N−1 로 둘** 둔다 — `0.50`(중립) ↔ `0.00`(**격자 최고값**)"
					" ⇒ 「적응이 이긴 것이 **초기값 덕**인가」를 그 둘이 가른다\n"
				"[ml]     ⚠️⚠️ **먼저 볼 것 넷**(규율 21·18) — ㈕ **91.6%%** · 🧩16 **100.0%%** ·"
					" ⭐ **ⓝ 87.0%%**(`c₁ 0.00`) · **ⓥ 80.7%%**(`c₁ 1.00`) ⇒ D162 격자가 그대로여야 한다\n"
				"[ml]     ⭐ ㊞ **넓힘** — `c₁ −1.00 · −0.50` 이 `0.00`(**87.0%%**)보다 **높나**."
					" ★ 높으면 폭이 더 크고, **안쪽 최적이면**(0.00 이 최고면) D96 처럼 **형태가 답**이다\n"
				"[ml]     ⭐ ㊟ **적응**(이 판의 요점 · D95 의 판정문 그대로) — 적응 팔이"
					" **격자의 최고 고정값을 넘나**. ⚠️ 못 넘으면 **「폭이 상한이다」의 재확인**이고 그것도 답이다\n"
				"[ml]     ⭐⭐ ㊠ **기제**(㊟ 보다 먼저 읽는다) — 적응 `c₁` 이 **정말 후보별로 갈렸나**."
					" 로그가 **폭(최소~최대)**을 찍는다 ⇒ **폭이 0 에 가까우면 「배웠다」가 아니라"
					" 상수 하나를 다르게 쓴 것**이다(D95 의 λ 가 그 자리였다)\n"
				"[ml]     ⭐ ㊡ **음성 대조**(규율 27) — **뒤집은 적응**(갈아타기를 많이 시킨 후보에 **상**)이"
					" 나빠진다. ★ **갈 곳이 있다** — 틀린 후보를 키우는 방향이다\n"
				"[ml]     ⚠️ 규율 16 확인 — `c₁` 은 첫 결정의 **갱신 부호**를 직접 바꾼다(D162 가 폭 6.3%%p 로 확인했다)\n"
			"[ml]   📌 **D164 등록 — 🎯 희소 갱신을 18-메뉴에**(이 캔버스 3번째 · 겨냥 = **㉡** 수준 **㉯**)\n"
				"[ml]     ★ **㉡ 의 원래 정의로 돌아간다** — D162·D163 은 `c₁`(**공을 얼마나**)을 흔들었는데"
					" ㉡ 은 *「틀렸을 때 흔드는 **범위**가 참여한 경로로 좁혀진다」* 다 ⇒ **「어느 가중치를 흔들까」**\n"
				"[ml]     ⚠️⚠️ **D163 이 그 전환을 강제했다**(규율 34) — `c₁` 은 **최적 근처가 평평**해서"
					" 적응할 것이 원리적으로 없었다. ⇒ 손잡이를 바꾼다\n"
				"[ml]     ★ **재료가 이미 있다** — D91~D96 의 **희소 갱신**: **`k=1` 일 때만 보호가 된다**"
					"(단조가 아니라 **계단** · D91) 그리고 **보호의 값은 묶음 수에 비례한다**(D94)\n"
					"[ml]        ⚠️ 그런데 **지금 판에는 안 들어와 있다** — 갱신이 늘 **전부**(대조 갱신)였다\n"
				"[ml]     ⭐⭐ **D94 가 예측을 준다** — 묶음 **8** 에서 `k=1 ↔ 전부` 가 **+12.4%p** 였다"
					" ⇒ 후보가 **18개**인 지금은 **더 커야** 한다\n"
				"[ml]     ⚠️⚠️ **먼저 볼 것 셋**(규율 21·18) — ㈕ **91.6%%** · ⭐ **ⓝ 87.0%%**(= `k=0` 기준점) ·"
					" 🎚️ 격자(−1.00 **88.2** · 0.00 **87.0** · 1.00 **80.7**)\n"
				"[ml]     ⭐ ㊢ **핵심** — `k=1` ↔ `전부`(ⓝ)의 차가 **+12.4%%p 를 넘나**(D94 의 예측)\n"
					"[ml]        ⚠️ 안 넘으면 그것도 정보다: **「비례한다」가 이 판에서는 안 성립**한다는 뜻이고,"
						" 그때는 **무엇이 다른가**(후보가 특징이 아니라 **행동**이다)를 적는다\n"
				"[ml]     ⭐ ㊣ **계단인가**(D91 의 형태) — `k=1` 만 좋고 `k=2·4` 는 **전부**와 비슷하다\n"
				"[ml]     ⭐⭐ ㊤ **음성 대조**(규율 27) — **고른 것만 빼고** 나머지를 흔든다"
					"(= *참여 안 한 것만*) ⇒ **반드시 나빠야** 한다. ★ **갈 곳이 있다**\n"
				"[ml]     🔧 **덤 — 계기판 수리**(규율 35 · 함정 378): 러닝 평균의 **전반 끝 스냅샷**을 남겨"
					" 로그가 그것을 읽게 했다. ⇒ 적응 팔의 `갈아타기율 전체`가 **0.000 이 아니어야** 한다\n"
					"[ml]        ★ 이것은 **캔버스가 아니라 배관**이다(판정에 안 넣는다)\n"
			"[ml]   📌 **D166 등록 — 🎲 상황을 섞어 「간섭」을 만든다**"
				"(새 캔버스 1번째 · 겨냥 = **㉡** 수준 **㉯** · 세계 축 = 🎲 **규칙**)\n"
				"[ml]     ★ **D165 심사가 이 판을 불렀다** — ㉡ 이 막힌 이유 둘(🎚️ **지형이 평평** ·"
					" 🎯 **축이 경쟁자**)이 **다 「이 세계에 간섭이 없다」**를 가리켰다."
					" *덮일 것이 없으면 보호할 것도 없다.*\n"
				"[ml]     ★ 규약은 **D148 그대로** — A 가 **색만** 변하면 **값 키가 죽고 잉크 키가 살고**,"
					" **크기만** 변하면 **잉크 키가 죽고 값 키가 산다** ⇒ **상황마다 옳은 후보가 갈린다**\n"
					"[ml]        ⚠️ B(같은 색 둘)와 자리는 **안 건드린다**(한 판에 한 축)\n"
				"[ml]     ⚠️⚠️⚠️ **이 판은 관문이다**(D165 가 미리 적었다) — **간섭이 안 생기면 ㉡ 을 접는다.**\n"
				"[ml]     ⚠️⚠️ **먼저 볼 것 — 세계의 서명**(규율 21): 고정 넷의 천장이 **세계마다 갈려야** 한다\n"
					"[ml]        📏 손 예측 — 🎨 색만: **13·16(잉크 키)이 살고 06(값 키)이 죽는다** ·"
						" 📏 크기만: **06 이 살고 13·16 이 죽는다**\n"
					"[ml]        ⚠️ 안 갈리면 세계가 **안 바뀐 것**이고(함정 369 계열) 아래는 **판정불가**다\n"
				"[ml]     ⭐ ㊥ **관문 — 간섭이 생기나**(D104 의 절차: **따로 재고 · 섞어서 재고 · 차를 본다**)\n"
					"[ml]        🎲 섞음(㋘) < **min**(🎨 색만 ㋖, 📏 크기만 ㋗) − 문턱 ⇒ ✅ **간섭이 있다**\n"
					"[ml]        ⚠️ 「평균보다 낮다」로는 부족하다 — **더 쉬운 쪽보다도 낮아야** 섞임 자체의 대가다\n"
				"[ml]     ⭐ ㊦ **천장이 갈리나** — 고정 여덟(🎨×4 · 📏×4)의 **순위가 세계마다 다르다**\n"
				"[ml]     ⚠️ 규율 16 확인 — `kBMix` 는 **에피소드마다 세계 규칙을 바꾼다** ⇒ 옳은 키가 갈리므로"
					" 도달률을 원리적으로 바꾼다\n"
				"[ml]     ⚠️ 규율 27 — 이 판은 **음성 대조가 없다**(관문 판이라 「생기나/안 생기나」가 전부다)"
					" ⇒ 간섭이 서면 **다음 판**에서 보호의 음성을 둔다\n"
			"[ml]   📌 **D167 등록 — 🧭 문맥을 관측에서 만든다**(새 캔버스 1번째 · 겨냥 = **㉢** 수준 **㉰**)\n"
				"[ml]     ★ **D166 이 재료를 남겼다** — 상황 둘에서 **순위가 통째로 뒤집힌다**"
					"(📏➕i 는 **100.0 ↔ 49.1%%** · 📏➖i 는 **27.1 ↔ 79.0%%**). 그런데 학습기가 **상황을 못 갈라"
					" 한 후보로 평균(74.6%%)을 냈다**(규율 39: *담을 자리가 없으면 그냥 평균이 난다*)\n"
				"[ml]     ⇒ ★ **담을 자리를 준다 — 단 상황을 손으로 알려주지 않는다**(D165 의 금지).\n"
					"[ml]        문맥 = **첫 프로브가 몇 개로 좁혔나**(`rb` = 0 / 1 / 2+) ⇒ **관측**이고 오라클이 아니다"
						"(`_BindRead` 와 **같은 술어**로 센 값이다)\n"
				"[ml]     🧭 축 = `kBCtx` : `0` = **첫 후보의 정체**(D149 · 기준점 ㋘) · `1` = ⭐ **관측**(㋡) ·"
					" `2` = **둘 다**(㋢) · `3` = ⚠️ **무작위**(음성 · ㋣)\n"
				"[ml]     ⚠️⚠️ **먼저 볼 것 셋**(규율 21·18) — ㈕ **91.6%%** · 🎲 섞음 기준점 ㋘ **63.8%%** ·"
					" 세계의 서명(🎨16 **100.0** · 📏13 **79.0**)\n"
				"[ml]     ⭐⭐ ㊧ **작동 판정**(먼저) — 관측 문맥 팔의 **문맥 칸마다 두 번째 선택이 달라야** 한다."
					" 같으면 **담을 자리를 줬는데 안 쓴 것**이고 ⇒ ㊨ 는 **판정불가**다(규율 3 ㉢)\n"
				"[ml]     ⭐ ㊨ **핵심** — 🎲 섞음이 **74.6%%**(한 후보 16 의 두 세계 평균)를 **넘나**\n"
					"[ml]        ★ 넘으면 **상황을 관측으로 갈랐다**는 뜻이다 ⇒ ㉢ 이 **㉰ 쪽으로** 한 칸\n"
					"[ml]        ⚠️ 문턱은 **3.18%%p**(n=1800) ⇒ **77.8%% 이상**이어야 한다\n"
				"[ml]     ⭐ ㊩ **음성 대조**(규율 27) — ⚠️ 무작위 문맥(㋣)이 관측 문맥(㋡)보다 **낮다**."
					" ★ **갈 곳이 있다**: 칸 수만 같고 정보가 0 이라 **표본만 나뉘어** 손해여야 한다\n"
					"[ml]        ⚠️ 그리고 ㋣ 가 ㋘(문맥 = 첫 후보)보다도 낮으면 **「나누는 것 자체가 대가」**임이 선다\n"
				"[ml]     ⚠️ 규율 16 확인 — 문맥은 **두 번째 선택의 분포를 직접 바꾼다**(같은 첫 후보라도 칸이 갈린다)\n"
				"[ml]     ⚠️ 규율 38 을 기억한다 — 섞음 판이라 **표본이 나뉜다** ⇒ 비교는 **같은 섞음 세계 안에서만**\n"
			"[ml]   📌 **D168 등록 — 🔎 문맥을 「방아쇠와 다른」 관측에서**(이 캔버스 2번째 · 겨냥 = **㉢** 수준 **㉰**)\n"
				"[ml]     ⛔⛔ **함정 381 의 직접 처방** — D167 은 방아쇠(`nRem != 1`)와 문맥(`f(nRem)`)이"
					" **같은 관측**이라 문맥이 **원리적으로 상수**였다(칸 셋 중 둘이 「균등」)\n"
				"[ml]     ⭐ 새 문맥 = **같은 상태를 한 장 더 그려 「A 가 무엇을 바꾸나」**"
					"(`0` 안 변함 · `1` **색** · `2` **잉크** · `3` 둘 다)\n"
				"[ml]     ⭐⭐ **규율 40 을 손으로 먼저 확인했다** — 이 관측은 **키도 행동도 안 탄다**"
					"(같은 `cc`·`cs` 로 두 장을 그린다) ⇒ 방아쇠가 **걸러낼 수 없다**. **독립이다**\n"
				"[ml]     ⚠️ 대가는 **걸음 하나**다 ⇒ 음성 대조(㋥)도 **같은 걸음**을 쓰게 해서 그것을 **통제**한다\n"
				"[ml]     ⚠️⚠️ **먼저 볼 것 셋**(규율 21·18) — ㈕ **91.6%%** · 🎲 기준점 ㋘ **63.8%%** ·"
					" 🎨 색만 **82.8%%** / 📏 크기만 **55.8%%**\n"
				"[ml]     ⭐⭐ ㊪ **작동 판정**(성능보다 먼저 · D167 이 이것으로 구해졌다) —"
					" 문맥 칸 **`1`(색)과 `2`(잉크)가 둘 다 살아 있어야** 한다\n"
					"[ml]        📏 **손 예측**: 🎨 세계에서 `1`, 📏 세계에서 `2` ⇒ 그 둘만 쓰이고 `0`·`3` 은 거의 안 나온다\n"
					"[ml]        ⚠️ 「균등」이 뜨면 그 칸은 **안 쓰인 것**이고 ⇒ ㊫ 는 **판정불가**다\n"
				"[ml]     ⭐ ㊫ **핵심** — 🎲 섞음이 **77.8%%**(= 한 후보 평균 74.6 + 문턱 3.2)를 **넘나**\n"
					"[ml]        ★ 넘으면 **상황을 관측으로 갈랐다** ⇒ ㉢ 이 ㉰ 쪽으로 한 칸\n"
				"[ml]     ⭐ ㊬ **음성 대조**(규율 27) — ㋥(**같은 걸음** · 무작위 문맥)보다 ㋤ 가 **높다**."
					" ★ 걸음 대가가 같으므로 차이는 **문맥의 정보**뿐이다\n"
				"[ml]     ⚠️ 규율 38 — 섞음 판이라 비교는 **같은 섞음 세계 안에서만**\n"
			"[ml]   📌 **D169 등록 — 🔎 문맥을 결정의 「첫 자리」에**(이 캔버스 3번째 · 겨냥 = **㉢** 수준 **㉰**)\n"
				"[ml]     ⛔⛔ **함정 382 의 직접 처방** — D168 은 문맥이 **살았는데도**(칸마다 다른 선택)"
					" 값이 **−0.1%%p** 였다. 기제는 배관에 있었다:\n"
					"[ml]        첫 선택 `aw[*]` = 문맥 **없다** · **모든 판**(100%%) │"
						" 둘째 `aw2[ctx][*]` = 문맥 있다 · **갈아탄 판만**(≈20%%)\n"
					"[ml]        ⇒ 기대 = `0.8 x 평균 + 0.2 x 문맥` ⇒ **문맥이 완벽해도 상한이 눌린다**(규율 41)\n"
				"[ml]     ⇒ ★ `aw[ctx][*]` — **첫 선택에** 문맥을 준다.\n"
					"[ml]        ⭐ **D168 이 재료를 만들었다**: 그 관측은 **행동과 무관**하므로 **프로브 전에도** 된다"
						" ⇒ 자리를 앞으로 옮겨 **모든 판**에서 쓴다\n"
					"[ml]        ⚠️ `kBCtx < 6` 인 팔은 **늘 `aw[0]`** 라 옛 거동이 **구조로** 보장된다(규율 18)\n"
				"[ml]     ⚠️⚠️ **먼저 볼 것 넷**(규율 21·18) — ㈕ **91.6%%** · 🎲 기준 ㋘ **63.8%%** ·"
					" ㋤(둘째에만 문맥) **63.7%%** · 🎨 색만 **82.8%%** / 📏 크기만 **55.8%%**\n"
				"[ml]     ⭐⭐ ㊭ **작동 판정**(성능보다 먼저 · D167·D168 이 이것으로 구해졌다) —"
					" **첫 선택의 argmax 가 문맥 칸마다 달라야** 한다\n"
					"[ml]        📏 **손 예측**(D166 실측): 🎨 세계 → **📏➕i(16)**(100.0%%) ·"
						" 📏 세계 → **📏➖i(13)**(79.0%%)\n"
					"[ml]        ⚠️ 「균등」이거나 두 칸이 **같은 것**을 고르면 문맥이 안 쓰인 것이고 ⇒ ㊮ 는 **판정불가**\n"
				"[ml]     ⭐ ㊮ **핵심** — 🎲 섞음이 **77.8%%**(= 한 후보 평균 74.6 + 문턱 3.2)를 **넘나**\n"
					"[ml]        ★ 상한이 이제 `0.8 x` 에 안 눌리므로 **넘을 수 있다** ⇒ 넘으면 ㉢ 이 **㉰ 쪽으로** 한 칸\n"
					"[ml]        ⚠️ 진짜 상한은 손 규칙의 두 세계 평균 **(100.0 + 79.0)/2 = 89.5%%** 다\n"
				"[ml]     ⭐ ㊯ **음성 대조**(규율 27) — ㋧(**같은 걸음** · 무작위 문맥)보다 ㋦ 가 **높다**\n"
				"[ml]     ⚠️ 규율 41 을 다시 확인 — 이제 문맥이 **100%% 의 판**에서 쓰인다(그것이 이 판의 전부다)\n"
			"[ml]   📌 **D170 등록 — 📉 「표본 부족인가」를 곡선으로 가른다**"
				"(이 캔버스 4번째 · 겨냥 = **㉢** 수준 **㉰**)\n"
				"[ml]     ⭐ **D169 가 물음을 좁혔다** — 문맥의 **정보는 값을 하는데**(음성 **+6.0%%p**)"
					" **기준은 못 넘는다**(−1.2%%p). 손계산이 범인을 지목한다:\n"
					"[ml]        문맥이 고른 것대로면 기대 = (100.0 + 64.4)/2 = **82.2%%** ↔ 실측 **62.6%%**"
						" ⇒ **19.6%%p 가 학습 부족**(`aw[4][18]` = 72 파라미터 · 규율 38)\n"
				"[ml]     ⇒ ★ **두 곡선 x 예산 넷**(D154 의 관용구) — 🔎 문맥 있음 ↔ ⬜ 없음,"
					" 각각 **60 · 180 · 600 · 1800**(1800 은 ㋦·㋘ 이 준다)\n"
				"[ml]     ⚠️ **지표는 후반(평가) 도달률**이다 — 「그 예산으로 배운 것의 실력」이 그것이다"
					"(D151 이 전반을 쓴 것은 *재사용*을 재느라 그랬고, 여기는 **학습량**을 잰다)\n"
				"[ml]     ⚠️⚠️ **먼저 볼 것 넷**(규율 21·18) — ㈕ **91.6%%** · ㋘ **63.8%%** · ㋦ **62.6%%** ·"
					" ㋧(음성) **56.6%%**\n"
				"[ml]     ⭐ ㊰ **핵심 — 아직 오르는 중인가**: 🔎 곡선의 마지막 두 점(**600 → 1800**) 차가"
					" 문턱(**≈3.2%%p**)을 **넘나**\n"
					"[ml]        ㉠ **넘는다** ⇒ **표본 부족이 확정**된다. 처방은 **문맥 칸을 줄이거나 예산을 늘리는 것**\n"
					"[ml]        ㉡ **평평하다** ⇒ **문맥으로도 안 된다**가 확정 ⇒ ⛔ **캔버스를 닫는다**(미리 적어 둔다)\n"
				"[ml]     ⭐⭐ ㊲ **두 곡선이 어디서 갈리나** — 🔎 가 ⬜ 를 **어느 예산부터** 이기나\n"
					"[ml]        ★ 큰 예산에서만 이기면 **「표본만 있으면 된다」**가 서고,\n"
					"[ml]        ⚠️ 어느 예산에서도 안 이기면 ㊰㉡ 과 같은 결론이다\n"
				"[ml]     ⚠️ 규율 33 을 미리 적용 — **1800 이 끝값**이라 「오르는 중」이면 **폭은 하한**이다\n"
				"[ml]     ⚠️ 규율 38 — 이 판은 **표본 자체가 축**이므로 「평균보다 낮다」류 비교를 안 쓴다\n"
			"[ml]   📌 **D172 등록 — 🧬 「어느 관측을 볼까」도 고르게 한다**"
				"(새 캔버스 1번째 · 겨냥 = **㉢** 수준 **㉰** 의 **넷째 칸 = 축**)\n"
				"[ml]     ★ **D171 심사가 수준 표를 고치자 이 칸이 남았다** — ㉰ 의 넷 중"
					" 🔔 방아쇠(D155)·🔎 문맥(D169·D170)은 ✅, 🧩 메뉴는 절반인데 **🧬 축은 사람이 준다**\n"
				"[ml]     ★ **규율 31 을 먼저 확인했다**(*그 행동이 계에 있나*) — 지금은 `kBCtx` 를 사람이 정하니"
					" **없다**. 그런데 **D156 의 관용구가 그것을 만든다**: **후보를 펼치면 고르는 행동이 생긴다**\n"
				"[ml]     ⇒ 결정을 **두 단계**로 — ① **어느 관측을 볼까**(색 · 잉크 · 색또는잉크 · 자리)"
					" ② 그 문맥으로 **무엇을 할까**(18-메뉴)\n"
					"[ml]        ★ 지금 배관이 이미 두 단계라(갈아타기) 모양이 맞고, 그것이 `concept.md` 의"
						" ㉢ 정의 그 자체다 — *「무엇을 해 보면 갈리는지 스스로 고른다」*\n"
				"[ml]     📏 **손 예측**(짓기 전에 따졌다) — 🎨 색만 세계: `색`=1 · `잉크`=0 │"
					" 📏 크기만: `색`=0 · `잉크`=1\n"
					"[ml]        ⇒ **색·잉크만 가른다**. `색또는잉크`는 **늘 1**, `자리`는 **늘 0** ⇒ **상수라 못 가른다**\n"
					"[ml]        ⭐ 그래서 **넷 중 둘이 「죽은 관측」**이고, 그것이 이 판의 **음성 대조를 세계가 준** 자리다\n"
				"[ml]     ⚠️⚠️ **먼저 볼 것 넷**(규율 21·18) — ㈕ **91.6%%** · ㋘ **63.8%%** ·"
					" 🔎 문맥 고정(평가) **82.7%%** · ⬜ 없음(평가) **73.8%%**\n"
				"[ml]     ⭐⭐ ㊳ **작동 판정**(성능보다 먼저 · 이 계열이 세 번 그것으로 구해졌다) —"
					" `ow` 의 **argmax 가 🎨색 또는 📏잉크**로 간다\n"
					"[ml]        ⚠️ `🔀색또는잉크`·`📍자리`로 가면 **문맥이 상수**가 되고(D167 의 자리)"
						" ⇒ ㊴ 는 **판정불가**다\n"
				"[ml]     ⭐ ㊴ **핵심** — **평가 구간** 도달률이 ⬜ 없음(**73.8%%**)을 넘고"
					" 🔎 손으로 고정한 문맥(**82.7%%**)에 **근접**한다\n"
					"[ml]        ★ 이 판이 묻는 것은 **「더 잘하나」가 아니라 「스스로 고르나」**다"
						" — 고정만큼만 해도 **㉰ 의 넷째 칸이 선다**\n"
					"[ml]        ⚠️ 관측을 **하나만** 쓰므로 D169(색·잉크를 **둘 다** 본 4칸)보다"
						" **정보가 줄 수 있다** ⇒ 그만큼은 정직하게 대가로 적는다\n"
				"[ml]     ⭐ ㊵ **음성 대조**(규율 27) — ㋯(관측을 **무작위로** 고른다)보다 ㋮ 가 **높다**."
					" ★ 갈 곳이 있다: 무작위면 절반은 **죽은 관측**을 집는다\n"
				"[ml]     ⚠️ 규율 42 — 지표는 **평가 구간**이다(전체는 헤맴과 실력을 섞는다)\n"
				"[ml]     ⚠️ 규율 41 — 문맥이 **모든 판**에서 쓰인다(첫 선택이 `aw[aCtx]` 다)\n"
			"[ml]   📌 **D173 등록 — 🔬 관측의 값을 「갈랐나」로 잰다**"
				"(이 캔버스 2번째 · 겨냥 = **㉢** 수준 **㉰** 의 넷째 칸)\n"
				"[ml]     ⛔⛔ **함정 384 의 직접 처방** — D172 는 관측을 **도달률**로 골랐더니"
					" **죽은 관측(🔀 늘 1)에 굳었고** 그 팔이 **문맥 없음과 소수점까지 같았다**(73.8%%)\n"
					"[ml]        ★ 기제는 **표본**이다: 안 가르는 관측은 문맥 칸이 **하나**라 칸당 **900판**,"
						" 가르는 것은 **둘**이라 **450판** ⇒ **초기에 더 좋아 보인다**\n"
					"[ml]        ⛔⛔⛔ 그래서 **무작위(80.1%%)가 배운 것(73.8%%)을 이겼다**\n"
				"[ml]     ⇒ ★ 보상을 **「갈림」**으로 바꾼다: 그 관측의 비트가 에피소드마다 **0/1 로 갈리나**"
					"(`4·p·(1−p)` — 0.5 에서 **1**, 0/1 에서 **0**)\n"
					"[ml]        ★ **죽은 관측은 정의상 0점**이다 ⇒ **표본 편향에 원리적으로 안 걸린다**\n"
					"[ml]        ★ 그리고 **자기 개입의 결과**라 관측이다(오라클이 아니다) —"
						" 넷을 **한 장으로 다 얻으므로** 걸음도 안 는다\n"
				"[ml]     📏 **손 예측**: 🎨색 **1.0** · 📏잉크 **1.0** · 🔀(늘 1) **0.0** · 📍자리(늘 0) **0.0**\n"
				"[ml]     ⚠️ **규율 40 을 손으로 확인했다** — 갈림은 `ow` 와 같은 관측에서 오지만"
					" **방아쇠가 아니라 보상**이라 **걸러내기가 아니다**(D167 의 그 병이 아니다)\n"
				"[ml]     ⚠️⚠️ **먼저 볼 것 넷**(평가 구간) — ㋦ 문맥고정 **82.7%%** · ㋯ 무작위 **80.1%%** ·"
					" ㋮ 배운다 **73.8%%** · ㋘ 문맥없음 **73.8%%**\n"
				"[ml]     ⭐⭐ ㊶ **작동 판정**(성능보다 먼저) — 🔬 갈림이 손 예측대로 **[1.0 · 1.0 · 0.0 · 0.0]**"
					" 이고 `ow` 의 argmax 가 **🎨색 또는 📏잉크**로 간다\n"
					"[ml]        ⚠️ 갈림이 예측과 다르면 **세계를 잘못 읽은 것**이고 아래는 판정불가다\n"
				"[ml]     ⭐ ㊷ **핵심** — ㋰ 의 **평가 구간**이 ㋮(**73.8%%**)를 넘고"
					" ㋯ 무작위(**80.1%%**)도 넘는다 ⇒ ★ **배운 것이 무작위를 이겨야** 「스스로 골랐다」가 선다\n"
				"[ml]     ⭐ ㊸ **음성 대조**(규율 27) — ㋱(**뒤집은 갈림** = 안 갈릴수록 상)가 ㋰ 보다 **낮다**."
					" ★ 갈 곳이 있다: 죽은 관측으로 가면 **문맥 없음(73.8%%)** 수준으로 떨어진다\n"
				"[ml]     ⭐ ㊹ **N−1 — 범인이 보상인가 수렴 속도인가** — ㋲(도달률 그대로 · `ow` 학습률 **1/5**)가"
					" ㋮ 보다 오르나\n"
					"[ml]        ㉠ ㋲ 만 오른다 ⇒ 범인은 **너무 빠른 수렴**(보상은 죄가 없다)\n"
					"[ml]        ㉡ ㋰ 만 오른다 ⇒ 범인은 **보상**(도달률로는 원리적으로 안 된다)\n"
					"[ml]        ㉢ 둘 다 오른다 ⇒ **둘 다 기여**한다 — 그것도 답이다\n"
				"[ml]     ⚠️ 규율 42 — 지표는 **평가 구간**이다\n"
			"[ml]   📌 **D174 등록 — 🪦 죽은 관측을 늘려 음성을 강하게 만든다**"
				"(이 캔버스 3번째 · 겨냥 = **㉢** 수준 **㉰** 의 넷째 칸)\n"
				"[ml]     ⚠️⚠️ **함정 385 의 직접 처방** — D173 에서 **㋲(탐험 유지)가 82.7%%** 로"
					" **손 고정과 정확히 같았는데**, 관측 넷 중 **셋이 살아 있어** 무작위도 **80.1%%** 였다"
					" ⇒ **+2.6%%p 로 안 갈렸다**(문턱 3.77)\n"
					"[ml]        ⇒ ★ **「스스로 골랐다」가 무작위와 구별이 안 된다** — 음성이 약했다\n"
				"[ml]     ⇒ 관측 후보를 **여덟**으로 펴되 **죽은 것을 다섯** 둔다:\n"
					"[ml]        살아있는 셋 = 🎨색 · 📏잉크 · 📍자리(⚠️ D173 이 발견 — **크기가 변하면 중심 x 가 변한다**)\n"
					"[ml]        죽은 다섯 = 🔀색or잉크(늘 1) · 🪦늘1 · 🪦늘0 · 🪦색and잉크(늘 0) · 🪦자리≠잉크(늘 0)\n"
				"[ml]     📏 **손 예측**(모델을 D172 가 검증했다 — 넷 중 셋 ⇒ 예측 **80.5%%** ↔ 실측 **80.1%%**):\n"
					"[ml]        무작위 ≈ 3/8 x 82.7 + 5/8 x 73.8 = **77.1%%** ⇒ 배운 것(82.7)과 **+5.6%%p**"
						" ⇒ **갈린다**(문턱 3.77)\n"
				"[ml]     ⚠️⚠️ **먼저 볼 것 넷**(평가 구간) — ㋦ 문맥고정 **82.7%%** · ㋲ 넷·탐험유지 **82.7%%** ·"
					" ㋯ 넷·무작위 **80.1%%** · ㋘ 문맥없음 **73.8%%**\n"
				"[ml]     ⭐⭐ ㊺ **작동 판정**(성능보다 먼저) — 로그의 **「살아있는 것 N 개」가 3** 이고"
					" ㋳ 의 argmax 가 **살아있다**\n"
					"[ml]        ⚠️ 3 이 아니면 **손 예측이 또 틀린 것**이고(D173 이 그랬다) 아래는 판정불가다\n"
				"[ml]     ⭐ ㊻ **핵심** — ㋳(배운다)가 ㋴(**같은 여덟 · 무작위**)를 문턱 넘게 이긴다\n"
					"[ml]        ★ 이것이 **「스스로 골랐다」의 첫 깨끗한 증거**가 된다 — 지금까지는 음성이 약해 못 갈랐다\n"
				"[ml]     ⭐ ㊼ **대가는 없나** — ㋳ 가 ㋲(넷 · 82.7%%)와 **안 갈린다**(후보가 두 배여도 안 나빠진다)\n"
					"[ml]        ⚠️ 나빠지면 **규율 44**(칸이 늘면 표본이 나뉜다)가 여기서도 문다는 뜻이고 그것도 답이다\n"
				"[ml]     ⚠️ 규율 42 — 지표는 **평가 구간**이다 · 🎲 **탐험 유지가 기본**이다(D173 이 필요조건으로 보였다)\n"
			"[ml]   📌 **D175 등록 — 🎯 비율만 바꾼다: 넷 중 하나만 살린다**"
				"(이 캔버스 4번째 · 겨냥 = **㉢** 수준 **㉰** 의 넷째 칸)\n"
				"[ml]     ⚠️⚠️ **함정 386 의 직접 처방** — D174 는 죽은 것을 늘리려고 **후보 수를 8 로** 늘렸는데"
					" 음성(80.1 → **76.0%%**)과 **학습(82.7 → 75.0%%)이 같이 내려가** 차가 그대로였다\n"
					"[ml]        ⇒ **규율 45 와 44 가 정면으로 부딪히는 자리**다 ⇒ ★ **수는 고정하고 비율만** 바꾼다\n"
				"[ml]     ⭐⭐ **모델이 설계를 미리 계산해 줬다**(두 판에서 오차 **0.4·1.1%%p**):\n"
					"[ml]        `무작위 ≈ 살아있는 비율 x 82.7 + 죽은 비율 x 73.8`\n"
					"[ml]        후보 **넷** · 살아있는 것 **하나** ⇒ 무작위 = **76.0%%**(여덟과 **같은 음성 강도**)\n"
					"[ml]        그런데 **넷이라 배울 수 있다**(D173 이 82.7%% 를 보였다) ⇒ **차 +6.7%%p** > 문턱 3.91\n"
				"[ml]     🎯 관측 슬롯 = `[🎨색(**살아**) · 🪦늘1 · 🪦늘0 · 🪦색and잉크]`"
					" ⇒ **넷 중 하나뿐인 답**을 찾는 **더 어려운 시험**이다\n"
				"[ml]     ⚠️⚠️ **먼저 볼 것 넷**(평가 구간) — ㋲ 넷·탐험유지 **82.7%%** · ㋯ 넷·무작위 **80.1%%** ·"
					" ㋴ 여덟·무작위 **76.0%%** · ㋘ 문맥없음 **73.8%%**\n"
				"[ml]     ⭐⭐ ㊽ **작동 판정**(성능보다 먼저) — 로그의 「살아있는 것」이 **1** 이고"
					" ㋵ 의 argmax 가 **🎨색**이다\n"
					"[ml]        ⚠️ 1 이 아니면 손 예측이 또 틀린 것이고(D173 이 그랬다) 아래는 판정불가다\n"
				"[ml]     ⭐ ㊾ **핵심** — ㋵(배운다)가 ㋶(**같은 넷 · 무작위**)를 문턱 넘게 이긴다\n"
					"[ml]        ★ 이것이 **「스스로 골랐다」의 첫 깨끗한 증거**다 — 세 판 동안 음성이 약해 못 갈랐다\n"
					"[ml]        📏 손 예측: ㋶ ≈ **76.0%%** · ㋵ ≈ **82.7%%**\n"
				"[ml]     ⭐ ㊿ **대가는 없나** — ㋵ 가 ㋲(살아있는 것 셋 · **82.7%%**)와 **안 갈린다**\n"
					"[ml]        ⚠️ 나빠지면 **「하나뿐인 답 찾기」 자체가 어렵다**는 뜻이고 그것도 답이다\n"
				"[ml]     ⚠️ 규율 42 — 지표는 **평가 구간** · 🎲 탐험 유지가 기본이다\n"
			"[ml]   📌 **D176 등록 — 🔬🎯 갈림 보상 x 하나만 살아**"
				"(이 캔버스 **5번째** · 겨냥 = **㉢** 수준 **㉰** 의 넷째 칸)\n"
				"[ml]     ⭐ **두 판의 재료를 합친다** — D173 의 **갈림 보상**과 D175 의 **하나만 살아** 세계\n"
					"[ml]        ★ D173 에서 갈림이 실패한 이유는 *살아있는 셋이 다 양수라 하나로 안 굳었다* 였는데"
						" **지금은 살아있는 것이 하나**라 **흔들릴 데가 없다**\n"
					"[ml]        ★ 그리고 **갈림은 `aw` 와 무관하게 계산된다** ⇒"
						" **닭과 달걀(규율 47)이 원리적으로 없다** — D175 가 그것에 무너졌다(`ow` ≈ 0)\n"
					"[ml]        ⚠️ 탐험 유지(`lr/5`)도 **같이** 켠다(D173 이 필요조건으로 보였다)\n"
				"[ml]     📏 **손 예측**: 갈림 = **[1.00 · 0.00 · 0.00 · 0.00]**(D175 실측 그대로)"
					" ⇒ 슬롯 0 을 고르면 `advO = 1.0 − obase(≈0.25) = **+0.75**`, 나머지는 **−0.25**\n"
					"[ml]        ⇒ ★ **신호가 강하다** ⇒ `ow` 가 **🎨색으로 명확히** 가야 한다\n"
				"[ml]     ⚠️⚠️ **먼저 볼 것 넷**(평가 구간) — ㋲ 넷·살아3 **82.7%%** · ㋶ 넷·살아1·무작위 **74.9%%** ·"
					" ㋵ 넷·살아1·도달률 **73.8%%** · ㋘ 문맥없음 **73.8%%**\n"
				"[ml]     ⭐⭐ (51) **작동 판정**(성능보다 먼저 · 이 계열이 네 번 그것으로 구해졌다) —"
					" ㋷ 의 `ow` argmax 가 **🎨색**이고 **`ow` 가 0 이 아니다**\n"
					"[ml]        ⚠️ `ow` 가 또 0 이면 **갈림 보상도 신호를 못 준 것**이고 그러면"
						" **닭과 달걀이 아니라 다른 원인**이다 — 그것도 큰 정보다\n"
				"[ml]     ⭐ (52) **핵심** — ㋷ 가 ㋶(**74.9%%**)를 문턱(**≈4.1%%p**) 넘게 이기고"
					" ㋲(**82.7%%**)에 근접한다\n"
					"[ml]        ★ 이기면 **「스스로 골랐다」의 첫 깨끗한 증거**다 — 네 판 동안 음성이 약하거나"
						" 아래층이 굶어 못 갈랐다\n"
				"[ml]     ⭐ (53) **음성 대조**(규율 27) — ㋸(**뒤집은 갈림**)는 **죽은 관측**으로 가서"
					" **문맥 없음(73.8%%)** 수준으로 떨어진다. ★ 갈 곳이 있다(죽은 것이 셋이다)\n"
				"[ml]     ⚠️ 이 캔버스가 **5연속**이다 ⇒ **다음은 종료 심사**다(규율 17)\n"
			"[ml]   📌 **D198 등록 — 🔗 전이를 처음 잰다**(⭐ 겨냥 = **전이(성장 지도 15)**)\n"
				"[ml]     ⚠️⚠️ **왜 자리를 옮기나** — D196 의 자리는 **활용률 95%%** 로 소진됐고,\n"
					"[ml]        D197 이 **전이 미측정**을 *「이제 가장 큰 구멍」*으로 지목했다\n"
					"[ml]        ⇒ ★ 그리고 그것은 **성장 지도 칸을 실제로 움직이는 유일한 종류의 판**이다\n"
					"[ml]          (닫힘 조건 ㉢ 이 **아슬하게** 풀렸다 — 다음 20 판에 둘이 안 나오면 발효한다)\n"
				"[ml]     ⭐ **정정 하나 먼저** — 커버리지의 *「전이 ⛔ 없음」*은 **부분적으로 틀렸다**:\n"
					"[ml]        **D154 가 이미 「넣으면 싸지나」를 쟀다**(물려받으면 **7.5~8.3배**(ep 60) ·\n"
					"[ml]        **4.4배**(180) · **곡선 밖**(600)) ⇒ 안 잰 것은 **다른 과제로의 전이**다\n"
				"[ml]     🔗 **`concept.md` 의 절차를 그대로 따른다**:\n"
					"[ml]        ① **끊는다** — 한 상황을 **학습에서** 뺀다(`kBLrnSit` · 새 축)\n"
					"[ml]           ⚠️ *「입력에서만 가리고 학습을 그대로 두면 「이번에만 결석한 것」이다」*\n"
					"[ml]           ⇒ **정책 갱신만** 건너뛴다 — 입력도 채점도 그대로다\n"
					"[ml]        ② **같은 비용** — `kSd x kPer` 고정이라 에피소드 수가 같다(자동)\n"
					"[ml]        ③ **선택적으로 무너지나** — 📋 **상황별 성적**(D191 계기판)이 그 자리에서 답한다\n"
					"[ml]        ⚠️ 방향을 **둘 다** 본다: 🔗B(📏 크기만 배움) ↔ 🔗C(🎨 색만 배움)\n"
				"[ml]     ⭐ (123) **작동 판정**(성능보다 먼저) — 🔗B 의 **🎨 A색 성적**과"
					" 🔗C 의 **📏 A크기 성적**이 기준(🔗A)보다 **낮아야** 한다\n"
					"[ml]        ⚠️ 안 낮으면 `kBLrnSit` 이 **안 걸린 것**이고 그 아래는 무효다\n"
				"[ml]     ⭐ (124) **핵심 = 전이가 있나** — 안 배운 상황이 **무작위(≈47%%)보다 높나**\n"
					"[ml]        ㉠ 높다 ⇒ ★ **전이가 있다**(다른 상황에서 배운 것이 쓰인다)\n"
					"[ml]        ㉡ 같다 ⇒ ⛔ **전이 0** — 두 상황이 **별도 분류기**다"
						"(`concept.md` 의 그 문장: *「여러 별도 분류기를 가진 것에 가깝다」*)\n"
					"[ml]        ㉢ **낮다** ⇒ ⭐⭐ **음의 전이** — 배운 것이 **방해한다**\n"
				"[ml]     📐 **예상 둘**(규율 70 · 이번엔 **폭을 먼저 쟀다** — 규율 67 이 그것을 요구한다):\n"
					"[ml]        ㉠ **전이가 있을 때** = D191 성적표가 답을 준다 —"
						" 색만 배우면 `📏➕i` 로 굳고 그것은 크기에서 **53%%**\n"
					"[ml]           ⇒ 무작위 **47%%** 대비 **+6%%p**\n"
					"[ml]        ㉡ ⛔ **안 들 이유가 맞을 때** = *최적이 정반대라*"
						"(`📏➕i` 100/53 ↔ `🔎➖i` 50/91) **음의 전이** ⇒ **−3%%p**\n"
					"[ml]        ⇒ ⚠️ **예산은 ㉡ 로** — 효과가 작으니 이 판은 **탐색 판**이고 |t| 는 결론이 아니다\n"
			"[ml]   📌 **D196 등록 — ✨ 갈아타기를 끈 채로 ㉡ 을 잰다**(⭐ 겨냥 = **㉡ 선택적 수정**)\n"
				"[ml]     ★ D195 가 **폭을 되살렸다** — 갈아타기를 끄면 정보천장 **76.1 → 92.5** ·"
					" 바닥 **75.0** ⇒ **폭 +17.5%%p**(D192 는 **−0.4** 였다)\n"
				"[ml]     ⚠️⚠️ **`kBSw = 0` 을 전부에 건다**(규율 71) — 켰다 껐다 하지 않는다\n"
					"[ml]        ⇒ 따로 둘(✨1·✨2)도 **같은 설정**이라 **그 판의 천장을 그 판에서** 잰다(규율 67)\n"
				"[ml]     ⭐ (119) **작동 판정**(성능보다 먼저) — 따로 둘이 D195 계열과 맞나:"
					" ✨1 🎨A색 ≈ **100%%** · ✨2 📏A크기 ≈ **85%%**\n"
					"[ml]        ⚠️ ✨2 가 52%% 대로 나오면 `kBSw = 0` 이 **안 걸린 것**이고 그 아래는 무효다\n"
				"[ml]     ⭐ (120) **핵심** — 짝지은 **`✨C − ✨N`** 의 **|t| > 2.571**(df=5)\n"
					"[ml]        ⇒ ✅ 넘으면 **㉡ 이 처음으로 선다** — *배운 것 하나를 상황에 맞게 고친다*\n"
					"[ml]        ⇒ ⛔ 못 넘으면 **폭이 +17.5%%p 인 자리에서도 안 된다** ⇒ 닫힘 조건 ㉠ 에 한 표\n"
				"[ml]     ⭐ (121) **음성**(규율 57) — ✨R(🎲 무작위 문맥)이 ✨N 보다 **낮아야** 한다\n"
				"[ml]     ⭐ (122) **천장까지 갔나** — ✨C 가 **평균(✨1, ✨2)** 에 닿나(그것이 이 판의 정보천장이다)\n"
				"[ml]     📐 **예상 둘**(규율 70):\n"
					"[ml]        ㉠ **처방이 들 때** = **+17.5%%p**(폭 전부)\n"
					"[ml]        ㉡ ⛔ **안 들 이유가 맞을 때** = *문맥 칸이 표본을 쪼개서(규율 60)"
						" 그 폭을 다시 잃는다* ⇒ **+4%%p**(D188 이 그 자리에서 잰 크기)\n"
					"[ml]        ⇒ ⚠️ **예산은 ㉡ 로** 짠다 — 효과 4%%p · σ_diff 2.6(D188) ⇒ 필요 씨앗 **3** ⇒ **6 이면 넉넉**\n"
					"[ml]        ⚠️ 공용 규율 3-d 를 지킨다 — **문턱 근처의 `t` 로 역산하지 않는다**(8.6배 과소평가)\n"
			"[ml]   📌 **D195 등록 — 🔀 갈아타기를 끄면 91%% 가 나오나**(🔍 탐색 · ⚠️ **ML 처분 결정의 자료**)\n"
				"[ml]     ⚠️⚠️ **이 판은 트랙의 처분을 가른다** — 사람이 *「먼저 D195 만 하고 다시 판단」*을 골랐다\n"
					"[ml]        ㉠ 갈아타기가 범인이면 ⇒ **설계 결함**이고 ML 에 아직 고칠 것이 있다\n"
					"[ml]        ㉡ 아니면 ⇒ **학습 정책이 그 후보에 도달조차 못 한다** ⇒"
						" ML **자신이 진단한 벽**(셈 표·선형 합)의 자리다\n"
				"[ml]     ★ D194 의 실마리: 성적표에서 **🔎➖i 가 48~51%%**(D193·D194)인데 **D191 은 91%%** 였다\n"
					"[ml]        ⚠️ 차이가 **셋**이다 — `kBSw`(1↔0) · `lr`(.05↔0) · `kBCtx`(20↔0)\n"
					"[ml]        ⇒ ⭐ **셋으로 사슬을 만든다**: 지금 → **갈아타기만 끔** → **균등**\n"
					"[ml]          그러면 **91%% 가 어디서 사라지는지** 그 자리에서 보인다\n"
				"[ml]     ⚠️ 🔀U(균등 · `lr = 0`)는 **자다**(규율 11) — 학습기가 아니라"
					" 「그 세계의 후보 성적」을 재는 것이다\n"
				"[ml]     ⭐⭐ (116) **재현 판정** — 🔀1 이 D194 🌟0 의 **52.2%%** 를 되낸다(검산 고리 **11**)\n"
				"[ml]     ⭐⭐⭐ (117) **핵심** — 🔀U(균등)가 이 세계에서 **91%% 대**를 내나\n"
					"[ml]        ⇒ ⛔ 안 내면 **D191 의 91%% 는 그 세계(상황 넷)의 값**이었고"
						" 여기(A크기만 따로)에는 애초에 그 천장이 없다\n"
					"[ml]        ⇒ ★ 그러면 **규율 67 의 「도달값」을 다시 재야** 하고 ㉡ 의 폭 계산이 통째로 바뀐다\n"
				"[ml]     ⭐⭐⭐ (118) **가르기** — 🔀0(갈아타기만 끔)이 🔀1 과 🔀U 중 **어느 쪽에 붙나**\n"
					"[ml]        ㉠ 🔀U 쪽 ⇒ ★ **범인은 갈아타기**(규율 54 의 확장) ⇒ 고칠 것이 있다\n"
					"[ml]        ㉡ 🔀1 쪽 ⇒ ★ **범인은 학습 정책**(굳는 곳이 나쁘다) ⇒ 벽의 자리다\n"
				"[ml]     📐 **예상 둘**(규율 70 — 이 규율을 **처음부터** 지킨 판이다):\n"
					"[ml]        ㉠ **처방이 들 때** = 🔀0 이 **+39%%p**(52 → 91)\n"
					"[ml]        ㉡ ⛔ **안 들 이유가 맞을 때** = *D191 의 91%% 는 **균등 정책이 그 후보를 100 판"
						" 강제로 써 본 값**이고, 학습 정책은 그 후보에 **도달조차 못 한다*** ⇒ **+0%%p**\n"
					"[ml]        ⇒ ⚠️ **예산은 ㉡ 로** 짠다 ⇒ 이 판은 **탐색 판**이고 |t| 는 결론이 아니다(규율 65)\n"
			"[ml]   📌 **D194 등록 — 🌟 호기심을 넣는다**(🔍 겨냥 = **탐색** · 규율 68)\n"
				"[ml]     ★ D193 이 **처방을 정해 줬다** — σ 는 잡음이 아니라 **「굳은 후보의 분포」**다"
					"(24 개 값 → 이산값 **아홉 개**)\n"
					"[ml]        ⇒ **어디로 굳느냐**를 바꿔야 하고 **lr 로는 안 바뀐다**"
						"(열 배 낮춰도 σ 가 **오히려 두 배**)\n"
				"[ml]     🌟 **무엇을 넣었나** — `aeff += c / √(N[k]+1)`(안 써 본 후보에 가산점)\n"
					"[ml]        ★ 엔진 `AIBrain::curiosity` 와 **같은 식**이다(이 저장소의 기존 관용구)\n"
					"[ml]        `c = 0.5 / 1.0 / 2.0` · ⛔ 음성 **c = 0**(= 지금) ·"
						" ⛔ 음성 **무작위 가산점**(`c < 0`)\n"
					"[ml]        ★★ 그 음성이 가르는 것: *「탐험이 늘어서」* ↔ *「덜 써 본 것을 밀어서」*\n"
					"[ml]        (무작위 가산점은 **탐험은 같고 정보만 0** 이다)\n"
				"[ml]     ⚠️⚠️ **D193 의 실수를 안 되풀이한다** — 그 판은 `kBTbl` 을 켜면서 `kBSw = 1` 로 둬"
					" 성적표의 **도달률**이 오염됐다\n"
					"[ml]        ⇒ 이 판은 `kBSw = 1` 을 **일부러 유지**하고(D193 과 짝지어 비교 · **검산 고리 10**)"
						" 작동 판정에는 **선택 빈도만** 쓴다\n"
					"[ml]        ★ 선택 빈도(`scT`)는 **`aSel` 기준**이라 갈아타기와 **원리적으로 무관**하다\n"
					"[ml]        ⚠️ 도달률(`scOk`)은 **여전히 오염**이다 ⇒ 그 줄로 판정하지 않는다\n"
				"[ml]     ⚠️⚠️ **규율 69 를 지킨다 — 예상을 반으로 적는다**\n"
					"[ml]        (91 − 52)/2 = **+20%%p** 를 예상한다(누적 채점: 12 중 9 틀림 · **8 이 과대**)\n"
					"[ml]        ⛔ **안 들을 이유**(규율 69 ㉡): 호기심은 **「덜 써 본 것」을 밀지만"
						" 「좋은 것」을 밀지 않는다**\n"
					"[ml]           ⇒ 18 후보 중 나쁜 것이 대부분이면 **탐험이 성적을 깎을 수 있다**\n"
				"[ml]     ⭐⭐ (112) **작동 판정**(성능보다 먼저) — 📋 성적표의 **선택 빈도가 평평해지나**\n"
					"[ml]        ⚠️ 안 평평해지면 가산점이 **소프트맥스에 묻힌 것**이고 그 아래는 무효다\n"
					"[ml]        (D193 기준: 한 후보에 **n = 1204~1207 / 10800** 이 몰렸다)\n"
				"[ml]     ⭐⭐⭐ (113) **핵심** — 📏 A크기만이 **52.2%% → 91%%** 에 가까워지나(짝지어 · |t| > 2.571)\n"
					"[ml]        ⇒ ✅ 그러면 **㉡ 의 폭이 열린다**(76.1 → 95.5) ⇒ D192 를 그 위에서 다시 한다\n"
				"[ml]     ⭐ (114) **음성 판정** — 🌟 계열이 ⛔ 무작위 가산점을 **문턱 넘게** 이기나\n"
					"[ml]        ⚠️ 둘이 같으면 이득은 **탐험의 양**이고 「덜 써 본 것을 민다」는 값을 안 한다\n"
				"[ml]     ⚠️ (115) **σ 도 본다** — 규율 68 이 *σ 가 준다*고 예측한다(굳는 곳이 모이면)\n"
			"[ml]   📌 **D193 등록 — 🔍 왜 최적을 못 찾나(lr 스윕)**(🔍 겨냥 = **탐색** · 규율 67)\n"
				"[ml]     ★ D192 가 **병목을 바꿨다** — ㉡ 이 안 서는 이유는 *간섭이 없어서*가 아니라"
					" **「상황마다 다른 최적」에 학습기가 못 가서**다\n"
					"[ml]        📏 A크기만 세계: 성적표 최적 **🔎➖i 91%%** ↔ 학습기 **52.2%%**(따로 둬도)\n"
				"[ml]     ⭐ **다른 트랙(MLT)이 같은 모양을 이미 풀었다** — 교차 참조:\n"
					"[ml]        MLT 152: *용량이 손해로 보인 것이 실은 **lr 교란(과소적합)**이었고"
						" **lr x 0.5** 가 최고 성적*\n"
					"[ml]        ⇒ ★ D192 의 「52.2 ↔ 91 못 찾음」이 **정확히 그 모양**일 수 있다\n"
					"[ml]        ⚠️ 그리고 D185 가 이미 봤다 — `lr .05` 가 **σ 최대이면서 평균 최소**였다\n"
					"[ml]          (|t| 로는 안 섰지만 세 값의 방향이 일관됐다) · **지금까지 모든 판이 .05** 였다\n"
				"[ml]     🔍 **자리 = 📏 A크기만 따로**(상황 하나 · 문맥 무관 · **가장 단순한 자리**)\n"
					"[ml]        ⇒ lr **.05 / .02 / .01 / .005** 네 값 x 씨앗 **6**\n"
				"[ml]     ⭐⭐ (108) **작동·재현 판정**(성능보다 먼저) — 🔍05(lr .05)가 D192 의 **52.2%%** 를 되낸다\n"
					"[ml]        ⚠️ 씨앗을 **50** 으로 유지했다 ⇒ 여섯 값이 D192 🎯2 와 **정확히 같아야** 한다\n"
					"[ml]        (49.1 51.7 48.7 50.3 63.3 50.0)\n"
				"[ml]     ⭐ (109) **핵심** — lr 을 낮추면 **91%%** 에 가까워지나 (짝지어 · |t| > 2.571)\n"
					"[ml]        ⇒ ✅ 그러면 **㉡ 의 폭이 열린다**(76.1 → 95.5) ⇒ 그 위에서 D192 를 다시 한다\n"
					"[ml]        ⇒ ⛔ 안 되면 범인은 lr 이 아니다 ⇒ 🎲 탐험 · 🌟 낙관적 초기화로 넘어간다\n"
				"[ml]     ⭐⭐ (110) **작동 판정의 실물 = 📋 후보별 선택 빈도**(`kBTbl = 1`)\n"
					"[ml]        ⇒ **🔎➖i 를 얼마나 쓰나**가 그 자리에서 보인다\n"
					"[ml]        ★ lr 이 낮을수록 그 빈도가 **오르면** 기제가 **조기 수렴**으로 확정된다\n"
					"[ml]        ⚠️ 빈도가 그대로인데 성적만 오르면 기제가 **다른 것**이다\n"
				"[ml]     ⚠️ (111) **σ 도 같이 본다** — D185 는 `.10` 이 σ 가 가장 작았다(5.89)"
					" ⇒ **낮은 쪽에서도 σ 가 주나**를 확인해 다음 판 예산에 쓴다(규율 65)\n"
			"[ml]   📌 **D192 등록 — 🎯 진짜 충돌 짝에서 ㉡ 을 잰다**(⭐ 겨냥 = **㉡ 선택적 수정**)\n"
				"[ml]     ⭐ **D191 의 성적표가 자리를 찍어 줬다** — 🎨 **A색만** ↔ 📏 **A크기만**:\n"
					"[ml]        `📏➕i` 는 색 **100** / 크기 **53** · `🔎➖i` 는 색 **50** / 크기 **91**\n"
					"[ml]        ⇒ **한 후보 최선 76.5%%** ↔ **문맥이 있으면 95.5%%** ⇒ ⭐ **폭 +19.0%%p**"
						"(D188 이 잰 +2.16 의 **9 배**)\n"
				"[ml]     ★ **그리고 자유도가 낮다** — 두 상황은 **`oVC`(색이 변했나) 하나로 완전히 갈린다**\n"
					"[ml]        ⇒ `kBCtx = 20`(살아있는 관측 **하나**)로 충분하다 ⇒ **σ 가 작다**(규율 63)\n"
					"[ml]        ⇒ D188 이 그 설정에서 σ_diff **2.61** 을 냈다\n"
				"[ml]     📐 **예산**(규율 63·65) — 효과가 **+19%%p** 로 크다:\n"
					"[ml]        σ_diff 가 D188 수준(**2.61**)이면 씨앗 **1**, D184 수준(**8.57**)이어도 씨앗 **2**\n"
					"[ml]        ⇒ **6 이면 넉넉하다** ⚠️ 그래도 σ 를 **같이 재서** 다음 판 예산에 쓴다(규율 65)\n"
				"[ml]     ⚠️⚠️ **D166 이 이미 이 짝을 했고 「간섭이 없다」로 끝났다**\n"
					"[ml]        ★ 그때의 기제는 **규율 39**: *학습기가 상황을 못 갈라 한 후보로 평균을 낸다*"
						"(담을 자리가 없었다)\n"
					"[ml]        ⇒ ⭐ **D188 이 문맥을 세웠다** ⇒ **다시 물을 때**다 — 이번엔 **표가 답을 미리 아는 채로**\n"
				"[ml]     ⭐⭐ (104) **작동 판정**(성능보다 먼저) — 따로 둘이 성적표대로 나오나:"
					" 🎯1 🎨A색 ≈ **100%%** · 🎯2 📏A크기 ≈ **91%%**\n"
					"[ml]        ⚠️ 크게 다르면 학습기가 성적표의 최적을 **못 찾은 것**이고 그 아래는 무효다\n"
				"[ml]     ⭐ (105) **핵심** — 짝지은 **`🎯C − 🎯N`** 의 **|t| > 2.571**(df=5)\n"
					"[ml]        ⇒ ✅ 넘으면 **㉡ 이 처음으로 선다** — *배운 것 하나를 상황에 맞게 고친다*\n"
					"[ml]        ⇒ ⛔ 못 넘으면 **폭이 +19%%p 인 자리에서도 안 된다**는 뜻이고,"
						" 그때는 **㉡ 을 닫는다**(일곱 판째다)\n"
				"[ml]     ⭐ (106) **음성**(규율 57) — 🎯R(🎲 무작위 문맥)이 🎯N 보다 **낮아야** 한다\n"
				"[ml]     ⭐ (107) **천장까지 갔나** — 🎯C 가 **95.5%%**(= 따로 둘의 평균)에 닿나\n"
					"[ml]        ⇒ 닿으면 **문맥이 상황을 완전히 갈랐다**는 뜻이다\n"
			"[ml]   📌 **D191 등록 — 📋 상황 x 후보 성적표를 만든다**(📏 겨냥 = **계기** · 규율 66)\n"
				"[ml]     ⚠️⚠️ **왜 이 계기판이 없었나** — D189·D190 **두 판**을 「충돌 짝」을 **추측**해서 썼다\n"
					"[ml]        D190 이 규율 66 을 세웠다: **충돌 = 관측이 같고 「답이 다르다」**\n"
					"[ml]        ⇒ 그런데 **「답이 무엇인지」를 재는 표가 한 번도 없었다** ⇒ 그것을 만든다\n"
				"[ml]     📋 **한 팔이면 된다** — 정책을 **균등**으로(`kBndLr = 0`) 두면 18 후보가 골고루 쓰이고,\n"
					"[ml]        **갈아타기를 끄면**(`kBSw = 0`) 첫 후보가 **끝까지** 쓰인다\n"
					"[ml]        ⇒ `scT[4][18]`/`scOk[4][18]` 에 **상황별·후보별 도달률**이 쌓인다\n"
					"[ml]        ⚠️ 계기판을 **반복 루프 밖**에 뒀다 — 안 그러면 반복마다 리셋돼 표본이 안 쌓인다\n"
					"[ml]        ★ 4 회 x 1800 = 7200 판 ÷ (상황 4 x 후보 18) = **칸마다 100 판**\n"
				"[ml]     ⭐⭐ (101) **작동 판정**(성능보다 먼저) — 표의 칸이 **골고루 차야** 한다\n"
					"[ml]        ⚠️ 한 후보에 몰리면 균등이 안 된 것이고 그러면 표를 못 읽는다\n"
				"[ml]     ⭐ (102) **핵심 = 최적 후보가 서로 다른 상황 짝이 실재하나**\n"
					"[ml]        ㉠ **있다** ⇒ ★ 그 짝이 **진짜 충돌**이다 ⇒ 거기서 ㉡ 을 잰다\n"
					"[ml]        ㉡ **없다**(한 후보가 네 상황을 다 푼다) ⇒ ⛔ **이 세계엔 ㉡ 을 잴 자리가 원리적으로 없다**\n"
					"[ml]           ⇒ 그때는 **㉡ 을 닫고 세계를 새로 짓는다** — 여섯 판(D104·D166·D179·D180·D189·D190)의 답이다\n"
				"[ml]     ⭐ (103) **곁가지도 갈린다** — 📋 **상황별 성적**을 학습 팔에도 붙였다\n"
					"[ml]        ⇒ D189 가 못 가른 것이 그 자리에서 갈린다: *간섭인가* ↔ *어려운 상황이 섞여서인가*\n"
					"[ml]        ★ 섞음의 상황별 성적이 **따로일 때와 같으면 난이도 혼합**이고, **낮으면 간섭**이다\n"
				"[ml]     ⚠️ 이 판은 **성능을 겨누지 않는다** — 표 하나를 얻는 것이 전부다(규율 62 의 그 한 줄)\n"
			"[ml]   📌 **D190 등록 — ⚔️ 서명이 같은 둘만 섞는다**(⭐ 겨냥 = **㉡** 의 전제 · 규율 65 의 **탐색 판**)\n"
				"[ml]     ⚠️⚠️ **이것은 탐색 판이다** — **|t| 는 결론이 아니다**(규율 65)."
					" 재는 것은 **σ_diff 와 효과**이고, 그 둘로 **본 판의 씨앗 수**를 계산한다\n"
				"[ml]     ⛔ **D189 가 왜 못 섰나** — 필요 씨앗을 **13** 으로 냈는데 6 으로 돌았다\n"
					"[ml]        그리고 그 13 의 대부분은 **잡음**이었다: σ_diff **12.78** 중 🎨색만(**8.29**)과"
						" 📏크기만(**7.86**)이 실어 온 몫이 크다\n"
				"[ml]     ⚔️ **자리를 바꾼다** — 📍 **A자리만** ↔ 🧨 **B크기만** 둘만 섞는다(`kBCf = 3`)\n"
					"[ml]        ★ **왜 이 짝인가**: 둘 다 **혼자서는 정확히 100.0%% · σ 0.00**"
						"(씨앗과 무관하게 결정적)인데\n"
					"[ml]        **D180 이 바로 그 둘의 관측 서명이 같다**(`[0 0 100]`)고 찍었다\n"
					"[ml]        ⇒ ⭐ 따로가 결정적이므로 **σ_diff = σ(섞음) 하나뿐**이다"
						" — 잡음이 **원리적으로** 준다\n"
					"[ml]        ⇒ ⭐⭐ 그리고 **떨어지는 만큼이 곧 간섭**이다(따로의 천장이 100.0 이라 뺄 것이 없다)\n"
				"[ml]     ⭐⭐ (98) **작동 판정**(성능보다 먼저) — 따로 둘이 **여전히 100.0%% · σ 0.00** 인가\n"
					"[ml]        ⚠️ 아니면 자리가 안 깨끗한 것이고 그러면 이 설계의 전제가 무너진다\n"
					"[ml]        ⚠️ 그리고 **관측 서명**이 두 상황에서 **여전히 같아야** 한다(D180 의 그 줄)\n"
				"[ml]     ⭐ (99) **재는 것** — ⚔️M(둘 섞음)의 **평균과 σ**\n"
					"[ml]        ㉠ 효과 = `100.0 − 평균` · ㉡ σ_diff = **σ(섞음)**\n"
					"[ml]        ⇒ 📐 **필요 씨앗 = (2.571 x σ / 효과)^2** 를 그 자리에서 계산해 다음 판 예산으로 쓴다\n"
				"[ml]     ⭐ (100) **잡음이 정말 줄었나** — ⚔️M 의 σ 를 D189 🧨M(넷 섞음)의 **σ 13.09** 와 견준다\n"
					"[ml]        ★ 절반 아래로 내려가면 **자리를 바꾼 것이 옳았다**는 증거다\n"
				"[ml]     ⚠️ 씨앗은 D189 와 같은 **50** — 따로 둘은 D189 의 🧨3·🧨4 와 **값이 같아야** 한다(재현 감시자)\n"
			"[ml]   📌 **D189 등록 — 🧨 간섭을 같은 자로 확정한다**(⭐ 겨냥 = **㉡** 의 **전제**)\n"
				"[ml]     ★ D188 로 **자와 실험대가 섰다** ⇒ 이제 **미정을 하나씩 확정**한다\n"
					"[ml]        첫 대상 = **D180 의 간섭**(−14.8%%p) — ⭐ **㉡ 전체가 그것에 걸려** 있다\n"
					"[ml]        ⚠️ D184 가 그것을 **미정으로 내렸다**(2σ = 18.33 을 못 넘었다)\n"
					"[ml]        ⇒ 그런데 규율 64 가 그 판정을 고쳤다 — **그것은 「값의 σ」였다**\n"
				"[ml]     📐 **예산 근거**(규율 63 이 요구하는 한 줄):\n"
					"[ml]        그 세계의 **짝지은** σ_diff ≈ **8.57**(D184) · 효과 **−14.8%%p**\n"
					"[ml]        ⇒ 필요 씨앗 = `(2.571 x 8.57 / 14.8)^2` = **2.2** ⇒ **6 으로 충분**하다\n"
					"[ml]        ★ 그래서 이 판은 **씨앗 6** 이다 — 예산이 답을 미리 정해 준다\n"
				"[ml]     ⚠️ **씨앗을 D180 과 같은 50 으로 유지**했다 ⇒ `rep 0` 이 그 값을 재현해야 한다:\n"
					"[ml]        🧨2 A크기만 = **51.0** · 🧨4 B크기만 = **100.0** · 🧨M 넷 섞음 = **73.0**\n"
				"[ml]     ⭐⭐ (94) **재현 판정**(성능보다 먼저) — 위 셋이 맞나\n"
					"[ml]        ⚠️ 아니면 D181~D188 이 그 세계를 건드린 것이고 그 아래는 무효다\n"
				"[ml]     ⭐ (95) **핵심 = 간섭이 실재하나** — 씨앗마다"
					" `섞음 − (따로 넷의 평균)` 을 내고 그 평균의 **|t| > 2.571**(df=5)\n"
					"[ml]        ⇒ ✅ 넘으면 **㉡ 을 잴 수 있는 세계가 확정**된다"
						" ⇒ D181~D183 의 재시도 실험을 **그 위에서 다시** 할 수 있다\n"
					"[ml]        ⇒ ⛔ 못 넘으면 **㉡ 은 세계가 없다** — 다섯 판(D104·D166·D179·D180·D189)이"
						" 같은 답을 낸 것이고 그때는 **㉡ 을 닫는다**\n"
				"[ml]     ⭐ (96) **부호 일관성**(규율 64 가 값을 한 자리) — 여섯 씨앗의 차이가"
					" **다 같은 방향**인가. ★ D188 에서 **음수 0/12** 가 결정적이었다\n"
				"[ml]     ⚠️ (97) **σ 를 같이 적는다** — 이 자리의 짝지은 σ_diff 가 얼마인가"
					"(D184 의 8.57 은 **다른 비교**의 값이다) ⇒ 그 값이 **다음 판들의 예산**을 정한다\n"
			"[ml]   📌 **D188 등록 — 🔨 못을 박는다**(⭐ 겨냥 = **㉢** 넷째 칸 · 규율 63)\n"
				"[ml]     📐 **예산 근거를 먼저 적는다**(규율 63 이 요구하는 그 한 줄):\n"
					"[ml]        D187 의 🏛D 자리에서 `문맥 − 문맥없음` = **+2.50%%p** · σ_diff **2.80** · |t| **2.19**\n"
					"[ml]        ⇒ 필요 씨앗 = `(2.571 x 2.80 / 2.50)^2` = **9** ⇒ **12 로 여유**"
						"(문턱 **|t| > 2.201** · df=11)\n"
					"[ml]        ★ 여섯 값에 **음수가 하나도 없었다**(+4.1 0.0 +5.0 0.0 +5.9 0.0) — 부호가 일관된다\n"
				"[ml]     🎭 **자리 = 🏛D 그대로** — 상황 셋 · 충돌 없음 · 관측 넷 중 **하나만 살아**(`kBCtx = 20`)\n"
					"[ml]        ★ D187 이 보인 것: 살아있는 관측이 **셋이면 σ 10.57**, **하나면 σ 2.93**(3.6 배)\n"
					"[ml]        ⇒ **자유도가 낮은 자리를 골랐다** — 그것이 씨앗 202 개를 9 개로 바꾼다\n"
				"[ml]     ⚠️ **씨앗을 40 으로 유지**했다 ⇒ 앞 **여섯 값이 D187 과 정확히 같아야** 한다(재현 감시자)\n"
					"[ml]        🔨C: 89.9 83.9 88.6 84.4 90.0 84.4 │ 🔨N: 85.8 83.9 83.6 84.4 84.1 84.4\n"
				"[ml]     ⚠️ **그릇도 키웠다** — `repEv[8]` 이면 씨앗 12 가 **조용히 여덟만** 집계된다 ⇒ **16** 으로\n"
				"[ml]     ⭐ (91) **핵심** — 짝지은 **`🔨C − 🔨N`** 의 **|t| > 2.201**\n"
					"[ml]        ⇒ ✅ 넘으면 **㉢ 의 넷째 칸이 되살아난다**(D184 가 미정으로 내린 그 기둥)\n"
					"[ml]        ⇒ ⛔ 못 넘으면 **㉢ 은 닫는다** — 여덟 판을 썼고 자리도 골랐고 예산도 댔다\n"
				"[ml]     ⭐ (92) **음성**(규율 57 — 안 뺐다) — 🔨R(🎲 무작위 문맥)이 🔨N 보다 **낮아야** 한다\n"
					"[ml]        ★ D187 이 그것을 이미 보였다(−4.88%%p · |t| 3.00) ⇒ **재현되면 자가 맞는 것**이다\n"
				"[ml]     ⚠️ (93) **σ 도 다시 본다** — 씨앗 12 의 σ 가 D187 의 **2.93** 근처면 그 값이 확정되고,"
					" 그러면 **다음 판들의 예산이 그 자로 계산된다**\n"
			"[ml]   📌 **D187 등록 — 🏛️ 기둥을 씨앗 6 으로 다시 잰다**(⭐ 겨냥 = **㉢** 되찾기 · 규율 62)\n"
				"[ml]     ⚠️⚠️ **왜 자리를 옮기나** — D184·D185·D186 **세 판**이 같은 말을 했다:"
					" **넷 섞음 세계에서는 문맥이 손해**(문맥 없음 **86.1** ↔ 있음 **80.7**)\n"
					"[ml]        그런데 나는 **두 판을 σ 줄이는 데** 썼다 ⇒ ★ **잴 것이 없는 자리에서 자를 갈았다**\n"
					"[ml]        ⇒ 규율 62 대로 **문맥이 값을 하던 세계**로 돌아간다\n"
				"[ml]     🎭 **자리 = D179 의 세계**(`kBCf = 0` ⇒ 상황 **셋**: 🎨 색만 · 📏 크기만 · 📍 자리만 ·"
					" **충돌 없음**)\n"
					"[ml]        거기서 문맥 **98.1%%** ↔ 문맥 없음 **85.8%%** = **+12.3%%p** 였다"
						"(⚠️ 다만 그때 **n = 1** 이었다)\n"
					"[ml]        ⭐ **+12.3 은 σ 8.85 라도 |t| = 3.42 > 2.571** 이라 **설 가능성이 있다**"
						" — 그래서 이 자리를 먼저 고른다\n"
				"[ml]     ⭐⭐ (87) **재현 판정**(성능보다 먼저) — 씨앗을 D179 와 **같은 40** 으로 맞췄다\n"
					"[ml]        ⇒ 🏛C 의 `rep 0` 이 **98.1%%** · 🏛N 의 `rep 0` 이 **85.8%%** 근처여야 한다\n"
					"[ml]        ⚠️ 아니면 그 사이 판들(D180~D186)이 **이 세계를 건드린 것**이고 그 아래는 무효다\n"
				"[ml]     ⭐ (88) **핵심** — 짝지은 **`🏛C − 🏛N`** 의 `|t| > 2.571`\n"
					"[ml]        ⇒ ✅ 넘으면 **㉢ 의 넷째 칸이 되살아난다**(D184 가 미정으로 내린 그 기둥)\n"
					"[ml]        ⇒ ⛔ 못 넘으면 **㉢ 은 여섯 판을 통째로 잃는다** — 그때는 정직하게 그렇게 적는다\n"
				"[ml]     ⭐ (89) **음성** — 🏛R(🎲 무작위 문맥 · 칸만 있고 정보 0)이 🏛N 과 같아야 한다\n"
					"[ml]        ⚠️ 무작위가 같이 오르면 이득은 **문맥이 아니라 칸 수**다\n"
				"[ml]     ⭐ (90) **자리 확인** — 🏛D(D178 의 자리 · 관측 넷 중 **하나만 살아**)도 같이 잰다\n"
					"[ml]        ⇒ 두 자리 중 **어디서 문맥이 서는지**가 다음 판의 자리를 정한다\n"
				"[ml]     ⚠️ **σ 도 같이 본다** — 이 세계의 σ 가 8.85 근처면 **씨앗을 더 늘려야** 하고,"
					" 작으면 **n=6 으로 충분**하다(그 값이 다음 실험대의 예산을 정한다)\n"
			"[ml]   📌 **D186 등록 — 🤝 칸 사이에 정보를 공유한다**(📏 겨냥 = **계기** · 규율 60)\n"
				"[ml]     📐 **산수가 이 판을 정했다**(D185) — 효과 **5.40%%p** 를 잡으려면 지금 σ 로 **씨앗 18 개**"
					"(시간 18 배)인데, **σ 를 4 배 줄이면**(8.85 → 2.0) **n=6 문턱이 9.29 → 2.10%%p** 다\n"
					"[ml]        ⇒ ★ **뒤가 압도적으로 싸다** ⇒ 씨앗을 늘리지 말고 **σ 를 낳는 구조**를 고친다\n"
				"[ml]     🔬 **σ 의 원천**(D185 가 지목) — **칸마다 독립 정책**이라 초반 표본이 칸으로 쪼개지고"
					" **어느 칸이 어디로 굳나가 씨앗마다 달라진다** ⇒ 그 갈림이 1800 판을 끌고 간다\n"
				"[ml]     🤝 **무엇을 넣었나** — 아래층을 **`실효[ctx][k] = aw0[k] + aw[ctx][k]`** 로 쪼갰다\n"
					"[ml]        (**공통 + 칸별 보정**) · 갱신은 **둘 다** 밀되 **보정의 배율만 낮춘다**\n"
					"[ml]        ⇒ ★ 초반엔 **공통이 지배**하고 표본이 쌓이면 **칸이 갈린다**\n"
					"[ml]        ⚠️ 로그 직전에 공통을 칸에 **합친다** — 안 그러면 계기판이 **보정만** 보여"
						" 「칸이 다 같다」로 잘못 읽힌다(규율 48)\n"
				"[ml]     ⚠️ **음성 둘**(규율 57 — 이번엔 안 뺐다):\n"
					"[ml]        🤝2 ⛔ **공통만**(보정 0.0) ⇒ **문맥 없음(σ 0.92 · 평균 86.1)과 같아야** 한다\n"
					"[ml]        🤝3 ⛔ **보정만**(공통 0.0) ⇒ **지금(σ 8.85 · 평균 80.7)과 같아야** 한다\n"
				"[ml]     ⭐⭐ (84) **작동·재현 판정**(성능보다 먼저) — 씨앗을 D185 와 **같은 200** 으로 맞췄다\n"
					"[ml]        ⇒ 🤝0(공유 끔)이 D185 의 🧱R 과 **여섯 값이 정확히 같아야** 한다"
						"(65.4 86.8 87.3 87.0 82.8 75.0)\n"
					"[ml]        ⚠️ 다르면 내가 **옛 거동을 깼다**는 뜻이고(규율 18) 그 아래는 전부 무효다\n"
				"[ml]     ⭐ (85) **핵심** — 🤝1(보정 .2)의 **σ 가 2%%p 아래**로 내려가면서 **평균이 안 떨어진다**\n"
					"[ml]        ⇒ ✅ 그러면 **n=6 으로 2%%p 를 잴 수 있는 실험대**가 서고,"
						" 그때 **D178 의 기둥부터 다시** 잰다\n"
					"[ml]        ⇒ ⛔ σ 는 주는데 **평균도 같이 떨어지면** 그것은 「문맥을 덜 쓴 것」이다"
						"(🧮 칸둘이 그랬다 · D185) ⇒ **음성 🤝2 와 값이 같은지**로 가른다\n"
				"[ml]     ⭐ (86) **기울기** — 🤝1(.2) ↔ 🤝4(.5) 로 **보정 배율이 σ 를 어떻게 미는지** 본다\n"
					"[ml]        ⇒ 단조롭게 움직이면 **σ 를 조절하는 손잡이를 얻은 것**이다\n"
			"[ml]   📌 **D185 등록 — 🧱 재현되는 실험대를 만든다**(📏 겨냥 = **계기** · 규율 59)\n"
				"[ml]     ⛔⛔⛔ **D184 가 실험대의 결함을 확정했다** — 팔 하나가 **학습 궤적 하나**라"
					" **여태 모든 판이 실은 n = 1 이었다**\n"
					"[ml]        씨앗 간 **σ = 9.16 / 10.26%%p**(문맥 있는 설정) ↔ **0.79%%p**(문맥 없음) = **13 배**\n"
					"[ml]        ⇒ 새 문턱 **14.7 / 9.0%%p** = 옛 문턱의 **3~4 배** ⇒ 최근 결론 넷 중 셋이 **미정**\n"
				"[ml]     🧱 **무엇을 고쳤나** — 새 축 `kBRep`: 팔 하나를 **씨앗 여섯**으로 돌린다\n"
					"[ml]        ★ 학습 상태(`aw`/`aw2`/`ow`/계수기)를 **반복 루프 안에서 선언**하므로"
						" 반복마다 **완전히 새로 시작**한다\n"
					"[ml]        ★ 끝에 **평균 ± σ ± SE** 를 한 줄로 찍는다 ⇒ ⭐ **이제 그 한 줄이 그 팔의 값**이다\n"
					"[ml]        ⚠️ 기본이 **1** 이라 **옛 팔은 한 바이트도 안 바뀐다**(규율 18) · 💰 대가는 **시간**\n"
				"[ml]     ⭐ (81) **작동 판정**(성능보다 먼저 · 이 판의 전부다) — 반복이 **진짜 갈려야** 한다:\n"
					"[ml]        ㉠ 🧱R(기준)의 σ 가 **9%%p 근처**(D184 의 A 가 9.16)\n"
					"[ml]        ㉡ 🧱N(⛔ 문맥 없음)의 σ 가 **1%%p 근처**(D184 의 C 가 0.79)\n"
					"[ml]        ⚠️ 둘 다 나와야 반복 루프가 **씨앗을 제대로 가른 것**이다"
						"(안 갈리면 값이 여섯 개 다 같게 찍힌다 ⇒ 그 자리에서 보인다)\n"
				"[ml]     ⭐ (82) **핵심 = σ 를 줄일 수 있나** — σ 가 절반이면 **문턱도 절반**이다\n"
					"[ml]        📉 🧱L **학습률 .02** · 📈 🧱H **.10** · 🧮 🧱C **칸 둘**(`aCtx = bit`)\n"
					"[ml]        📏 손 예측: **학습률이 낮으면 σ 가 준다**(초반에 덜 굳는다) ·"
						" **칸이 적으면 σ 가 준다**(갈릴 자리가 적다)\n"
					"[ml]        ⇒ ⚠️ 그런데 **평균도 같이 내려가면 소용없다** ⇒ **σ 와 평균을 같이** 본다\n"
				"[ml]     ⚠️ (83) **이 판은 성능을 겨누지 않는다** — ㉡ 도 ㉢ 도 안 민다."
					" **실험대가 서기 전에는 어떤 A/B 도 결론이 아니다**(규율 59)\n"
			"[ml]   📌 **D184 등록 — 🎲 씨앗 분산을 잰다**(📏 겨냥 = **계기** · 규율 58)\n"
				"[ml]     ⚠️⚠️⚠️ **이것은 성능 판이 아니라 계기 판이다** — ㉡ 을 **더 밀지 않는다**"
					"(지금 밀어도 **무엇을 잰 것인지 모른다**)\n"
				"[ml]     ⛔⛔ **왜 멈추나** — 같은 A/B 가 **씨앗만 바꿔 부호가 뒤집혔다**:\n"
					"[ml]        D182(오프셋 70) ⏪ 되감기 **+18.9%%p** ↔ D183(오프셋 80) **−15.7%%p**"
						" ⇒ **스윙 34.6%%p**\n"
					"[ml]        ⚠️ 규율 56 은 **지켰다**(기준 팔을 같은 판에 뒀다) — 그런데도 뒤집혔다\n"
				"[ml]     🔬 **기제는 코드가 말한다** — 한 팔은 **학습 궤적 하나**다:\n"
					"[ml]        `aw`/`aw2`/`ow` 가 `sd` 마다 **리셋되지 않는다** ⇒ `kSd 30 x kPer 60 = 1800` 판이"
						" **한 줄기**이고, 초반에 어느 후보로 굳느냐가 **전체를 결정**한다\n"
					"[ml]        ⇒ ★ 문턱 `2√2·√(p(1−p)/n)` 의 **에피소드 독립 가정이 깨져 있다**"
						" ⇒ **문턱이 심하게 낙관적이다**\n"
				"[ml]     🎲 **설계 = 세 설정 x 씨앗 여섯**(오프셋 100~105 · `SeedRand` 가 7919 를 곱한다):\n"
					"[ml]        **A** ⬜ 끔(기준) · **B** ⏪ 되감는 재시도 · **C** ⛔ **문맥 없음**\n"
					"[ml]        ★ C 를 넣은 이유: **D178 의 핵심 주장**(*문맥이 값을 한다* · 그때 +12.3%%p)도"
						" **같은 자로** 다시 잰다 — 큰 결론일수록 먼저 검정한다\n"
				"[ml]     ⭐⭐ (77) **작동 판정**(성능보다 먼저) — 같은 설정의 여섯 팔이 **서로 다른 값**을 낸다\n"
					"[ml]        ⚠️ 다 같으면 `kBRs` 가 **안 먹은 것**이고 그러면 이 판은 통째로 무효다\n"
				"[ml]     ⭐ (78) **핵심 = 새 문턱** — 설정마다 **씨앗 간 표준편차 σ** 를 내고"
					" **2σ** 를 새 문턱으로 삼는다\n"
					"[ml]        ⇒ 지금 쓰는 문턱(**≈3.3~4.3%%p**)과 **몇 배** 차이인지 적는다\n"
				"[ml]     ⭐ (79) **재검정** — 씨앗 여섯의 **짝지은 차이**(같은 씨앗 A↔B · A↔C)를 본다\n"
					"[ml]        ㉠ **B−A** 의 평균과 부호 일치 개수 ⇒ ⏪ 되감기가 **진짜** 값을 하나\n"
					"[ml]        ㉡ **A−C** 의 평균과 부호 일치 개수 ⇒ ⭐ **문맥이 진짜 값을 하나**"
						"(D178 이 세운 기둥이다)\n"
					"[ml]        ★ **짝지은 차이는 씨앗 효과를 지운다** — 그것이 이 설계의 핵심이다\n"
				"[ml]     ⚠️ (80) **되읽기** — 새 문턱으로 **최근 결론 셋**을 다시 본다:"
					" D178 **82.7**(+7.8) · D180 간섭 **−14.8** · D182 **+18.9**\n"
					"[ml]        ⇒ ⛔ 못 넘는 것은 **결론에서 내리고 「미정」으로 되돌린다**(규율 23 의 그 자리)\n"
			"[ml]   📌 **D183 등록 — 🧪 음성을 되찾고 이득의 정체를 가른다**(⭐ 겨냥 = **㉡** · 규율 57)\n"
				"[ml]     ⛔⛔ **왜 이 판이 필요한가** — D182 가 **+18.9%%p** 라는 큰 값을 냈는데"
					" **음성을 빼먹어서** 그것이 **「고침」인지 「걸음」인지 못 갈랐다**\n"
					"[ml]        (걸음이 **3.91 → 8.63** 으로 늘었다 · D181 엔 있던 「걸음만 더」를 D182 에서 뺐다)\n"
					"[ml]        ⇒ ★ **그래서 ㉡ 이 섰다고 아직 못 적는다** — 값이 아니라 **다리**가 없다\n"
				"[ml]     ⚠️⚠️ **지난 판의 음성 중 이 판에도 걸리는 것**(규율 57 의 그 한 줄):\n"
					"[ml]        · D181 ㈘ **걸음만 더** ⇒ 이 판의 **㈣**(되감기 판에서 다시 묻는다)\n"
					"[ml]        · D181 ㈗ **무작위 재시도** ⇒ 이 판의 **㈤**(되감기 판에서 다시 묻는다)\n"
				"[ml]     ⛔ **음성 넷**(둘은 새것):\n"
					"[ml]        ㈣ 되감기 + **걸음만 더**(시험은 하되 **안 갈아탄다**)\n"
					"[ml]        ㈤ 되감기 + **무작위 재시도**(「**무엇으로** 고치나」)\n"
					"[ml]        ㈦ ⭐ **예산만 24**(`kCap` 16 + 8 · **시험도 갈아타기도 없다**)\n"
					"[ml]        ㈧ ⭐ **예산만 32**(16 + 16 · 재시도 계열의 걸음 8.63 을 **넘어서는** 예산)\n"
					"[ml]        ★ ㈦·㈧ 이 **가장 정직한 음성**이다 — 「걸음이 답이면 이것만으로 올라야」 한다\n"
				"[ml]     ⭐⭐ (74) **작동 판정**(성능보다 먼저) — ㈧(예산 32)의 **평균 걸음이 ㈢(되감기 8.63)를 넘는다**\n"
					"[ml]        ⚠️ 안 넘으면 예산 음성이 **약한 것**이고 그것으로는 아무것도 못 가른다\n"
				"[ml]     ⭐ (75) **핵심 = ㉡ 이 서나** — ㈢(⏪ 되감는 재시도)가 **음성 넷을 전부** 문턱 넘게 이긴다\n"
					"[ml]        ⇒ ✅ 그러면 **㉡ 이 처음으로 선다** — *배운 것 하나를 상황에 맞게 고친다*\n"
					"[ml]        ⇒ ⛔ ㈦·㈧ 이 같이 오르면 이득은 **고침이 아니라 걸음**이다(그러면 D182 의 값은 허수다)\n"
					"[ml]        ⇒ ⛔ ㈤ 가 같이 오르면 이득은 **고른 것이 아니라 다시 함**이다\n"
				"[ml]     ⭐ (76) **재현**(규율 56) — ㈡(넷·끔)와 ㈢(되감기)가 D182 의 **75.3 ↔ 94.2** 를 이 씨앗에서 되낸다\n"
					"[ml]        ⚠️ 씨앗 오프셋이 70 → 80 이다 ⇒ **절대값은 안 맞아도 된다. 차이가 살아 있으면 된다**\n"
				"[ml]     ⚠️⚠️ **그리고 ⏪ 되감기는 자이지 능력이 아니다**(공짜 상상 · 규율 11)"
					" ⇒ 이 판이 통과해도 남는 숙제는 **되감지 않고 그만큼 얻는 길**이다\n"
			"[ml]   📌 **D182 등록 — 🎯 거짓 도달을 낮춘다**(⭐ 겨냥 = **㉡** · 규율 55 의 처방)\n"
				"[ml]     ⭐ **D181 이 병목을 지목했다** — 재시도 기계는 섰는데(음성 둘을 **+9.2** · **+5.5%%p** 로 이겼다)\n"
					"[ml]        **측정 도달이 +4.1%%p 오르는 동안 진짜가 −4.8%%p 내렸고 거짓 도달이 32.1%%** 였다\n"
					"[ml]        ⇒ ★ 시험 판정이 **측정 도달**이라 **네 번에 한 번은 거짓 성공에서 멈춘다**\n"
				"[ml]     🔍 **처방 ㉠ — 두 번 확인**: 「됐다」가 나오면 **한 걸음 더 재서** 같은지 본다\n"
					"[ml]        ★ **왜 이것이 거짓을 거르나**: 진짜 목표는 **어느 프레임에서나 그 셀**인데"
						" 거짓 짝은 **방해자 변주에 얹혀 있다** ⇒ 프레임이 넘어가면 **안 버틴다**\n"
					"[ml]        ⚠️ 목표도 **같은 프레임에서 다시 읽는다**(안 그러면 진짜까지 거짓으로 몰린다)\n"
				"[ml]     ⏪ **자 ㉡ — 되감는 팔**: D181 이 **못 가른 둘**을 가른다\n"
					"[ml]        *신호의 질이 나쁜가* ↔ *되감지 않아서 출발점이 나빠졌나*\n"
					"[ml]        ⇒ ★ **되감아도 안 오르면 범인은 신호**다 ⚠️ 되감기는 **공짜 상상**이라"
						" 이 계에 없는 능력이다 ⇒ **자로만** 쓴다(규율 11)\n"
				"[ml]     🎯 **계기판 ㉢ — 후보별 거짓 도달**(규율 48): *어느 후보가 거짓을 낳나*\n"
					"[ml]        ⚠️ D181 은 거짓을 병목으로 지목했지만 **어느 후보 탓인지는 안 봤다**\n"
				"[ml]     ⚠️⚠️ **규율 56 을 지켰다** — 기준 팔 **둘**을 이 판 안에 뒀다"
					"(㈞ 넷·끔 · ㈟ **충돌 둘·끔** ← D181 의 (68) 이 짝을 잘못 짜 못 답한 자리)\n"
				"[ml]     ⭐⭐ (69) **작동 판정**(성능보다 먼저) — ㈛ 의 **거짓 도달이 ㈞ 보다 낮다**\n"
					"[ml]        ⚠️ 안 낮으면 두 번 확인이 **거짓을 못 거르는 것**이고 그 아래는 무효다\n"
				"[ml]     ⭐ (70) **핵심** — ㈛(🔍 두 번 확인) **>** ㈞(끔)를 문턱(**≈4.0%%p**) 넘게\n"
					"[ml]        ⇒ ✅ 그러면 **㉡ 이 처음 값을 갖는다**(신호를 고쳤더니 고쳐 쓰기가 산다)\n"
				"[ml]     ⭐⭐ (71) **가르기** — ㈜(⏪ 되감기만)가 ㈞ 에 **안 닿으면 범인은 신호**"
					"(되감기로는 안 낫는다) · **닿으면 범인은 대가**(출발점이 나빠진 것)\n"
				"[ml]     ⭐ (72) **겹치나** — ㈝(둘 다)가 ㈛ 보다 더 오르나(처방 둘이 **독립인가**)\n"
				"[ml]     ⭐ (73) **자리 확정** — ㈠(충돌 둘 · 두 번 확인) ↔ ㈟(충돌 둘 · 끔):"
					" 서명이 **갈리는** 세계에서는 이득이 **작아야** 한다(거긴 문맥이 이미 푼다)\n"
			"[ml]   📌 **D181 등록 — 🔁 에피소드 안에 「됐다/안 됐다」를 준다**(⭐ 겨냥 = **㉡** · 규율 54 의 처방)\n"
				"[ml]     ⭐ **왜 지금인가** — D180 이 **간섭이 실재하는 세계**를 처음 만들었다"
					"(🧨 넷 섞음 **73.0%%** ↔ 따로 평균 **87.8%%** = **−14.8%%p**)\n"
					"[ml]        그리고 **그 세계에서 갈아타기를 끈 팔이 켠 팔보다 높았다**(95.0 ↔ 91.3)"
						" ⇒ 규율 54: **방아쇠는 결정 이전의 같은 프레임을 본다**\n"
					"[ml]        ⇒ ★ 처방은 하나다 — **먼저 가 보고 못 맞추면 그때 고친다**\n"
				"[ml]     🔁 **무엇을 넣었나** — 첫 후보로 **시험 항해 8걸음**(예산 16 의 절반)을 하고"
					" **못 맞추면** 갈아타기 표로 두 번째 후보를 고른다\n"
					"[ml]        💰 대가는 **걸음**이다(쓴 만큼 `epStep` 에 싣는다)\n"
					"[ml]        ⚠️⚠️ **되감지 않는다** — 간 자리(`cc`/`cs`)를 그대로 둔다"
						"(되감으면 **공짜 상상**이 되고 그건 이 계에 없는 능력이다)\n"
				"[ml]     ⚠️ **음성 대조 셋**(규율 45·46 이 죽은 자리 — 이번엔 세 갈래로 통제한다):\n"
					"[ml]        ㈗ ⛔ **무작위 재시도** ⇒ 「**무엇으로** 고치나」가 값을 하나\n"
					"[ml]        ㈘ ⛔ **걸음만 더**(시험은 하되 **안 갈아탄다**) ⇒ 이득이 **비용의 부산물**이 아닌가\n"
					"[ml]        ㈙ 🧨 **재시도 끔** ⇒ D180 의 **73.0%%** 를 이 씨앗에서 재현한다(기준선)\n"
				"[ml]     ⭐⭐ (65) **작동 판정**(성능보다 먼저) — ㈖ 의 🔄 **갈아탄 판 비율이 ㈙ 과 확연히 다르다**\n"
					"[ml]        ⚠️ 같으면 시험 항해가 **안 돌고 있는 것**이고 그러면 그 아래는 전부 무효다\n"
				"[ml]     ⭐ (66) **핵심** — ㈖(재시도) **>** ㈙(끔 · **73.0%%** 예상)를 문턱(**≈3.8%%p**) 넘게\n"
					"[ml]        ⇒ ✅ 그러면 **㉡ 이 처음으로 값을 갖는다** — *배운 것 하나를 상황에 맞게 고친다*\n"
				"[ml]     ⭐⭐ (67) **음성이 다 죽어야 한다** — ㈖ **>** ㈗ 그리고 ㈖ **>** ㈘\n"
					"[ml]        ⚠️ ㈘ 가 같이 오르면 이득은 **고침이 아니라 걸음**이다(규율 45 의 그 함정)\n"
					"[ml]        ⚠️ ㈗ 가 같이 오르면 이득은 **고른 것이 아니라 다시 함**이다\n"
				"[ml]     ⭐ (68) **가르는 자**(㈚) — 서명이 **갈리는** 충돌 둘에서는 재시도가 **덜** 값을 해야 한다"
					"(거긴 문맥이 이미 푼다) ⇒ 그것이 맞으면 **이득의 자리가 확정된다**\n"
				"[ml]     ⚠️ 계기판 라벨 버그(D180 · `nSit == 2`)를 **같은 판에서 고쳤다** — 값은 원래 맞았다\n"
			"[ml]   📌 **D180 등록 — 🧨 안 보이는 충돌**(⭐ 겨냥 = **㉡ 선택적 수정** · **마지막 시도**)\n"
				"[ml]     ⚠️⚠️ **㉡ 이 세 번 안 섰다**(D104 · D166 · D179) — 규율 49 대로 **방식을 의심한다**:\n"
					"[ml]        세 판 다 *간섭이 없다*로 끝났고 D179 는 **왜 없는지**까지 냈다 —"
						" **문맥으로 완전히 갈리면 간섭이 아니라 분리가 된다**\n"
					"[ml]        ⇒ ★ 그러면 **문맥으로 원리적으로 못 가르는 충돌**을 만들어야 한다\n"
				"[ml]     🧨 **세계 축** — 📏 **A 가 크기만** 변한다 ↔ 🧨 **B 가 크기만** 변한다\n"
					"[ml]        ★ **왜 안 보이나**: 관측 셋은 *짝을 잃은 성분이 있나*를 본다 ⇒ 어느 쪽이 변하든"
						" **잉크만 짝을 잃고 값·자리는 그대로** ⇒ 서명이 `[0 1 0]` 으로 **같다**\n"
					"[ml]        ⚠️ 그래서 **B 의 x 를 `kSize-12` 로 못 박았다**(오른쪽 끝을 맞추면 `cx16` 이 움직여"
						" `oPC` 가 갈리고 그러면 **더는 안 보이는 충돌이 아니다**)\n"
					"[ml]        ⇒ ★ 그런데 **옳은 후보는 다르다** — A 는 제 색이고 **B 는 목표와 같은 색**이다\n"
				"[ml]     ⭐ (61) **작동 판정 = 계기판 한 줄**(성능보다 먼저) — 🧨 **관측 서명**이"
					" 📏A크기 와 🧨B크기 에서 **같아야** 한다\n"
					"[ml]        ⚠️ 다르면 이것은 **안 보이는 충돌이 아니라 그냥 또 하나의 갈리는 상황**이고"
						" **그 아래는 전부 무효**다(규율 21)\n"
				"[ml]     ⭐ (62) **핵심 = 드디어 간섭이 나오나** — ㈒(충돌 둘 섞음) **<** min(㈐, ㈑) − 문턱\n"
					"[ml]        ⇒ ✅ 나오면 **㉡ 을 잴 수 있는 판이 처음 열린다**(D104·D166·D179 가 못 연 문)\n"
					"[ml]        ⇒ ⛔ 안 나오면 **네 번째**다 ⇒ 그때는 세계가 아니라 **구조**를 의심한다\n"
				"[ml]     ⭐⭐ (63) **규율 31 을 값으로 묻는다** — ㈓(⛔ 갈아타기 끔) **<** ㈒(갈아타기 켬)?\n"
					"[ml]        ★ 📏 손 예측은 **차이 없음**이다: 방아쇠도 **같은 프레임**을 보므로"
						" **문맥이 못 가르는 것은 방아쇠도 못 가른다**\n"
					"[ml]        ⇒ ⭐ 그 예측이 맞으면 **정리 하나가 선다**:"
						" *이 계에서는 「고쳐 쓰기」가 원리적으로 불가능하다*"
						" ⇒ 처방은 **에피소드 안에서 「됐다/안 됐다」를 주는 것**이다\n"
					"[ml]        ⇒ ⚠️ 틀리면(㈒ 가 더 높으면) **㉡ 이 처음 서는 것**이다\n"
				"[ml]     🔭 (64) **상한** — ㈔(어느 쪽인지 그냥 준다)가 min(㈐, ㈑)에 닿나"
					" ⚠️ 규율 52 대로 **오라클이 아래에 있으면 그것은 오라클의 실패**다\n"
				"[ml]     ⚠️ 회귀 감시자 — ㈕(넷 섞음)에 D179 의 셋이 그대로 들어 있다(**98.1%** 가 얼마나 내려가나)\n"
			"[ml]   📌 **D179 등록 — 🎭 상황을 셋으로**(⭐ 겨냥 = **㉡ 선택적 수정** · 수준 **㉯**)\n"
				"[ml]     ⭐ **왜 지금 ㉡ 인가 — D166 이 접은 이유가 사라졌다.**\n"
					"[ml]        D166: *간섭이 없다* ⇒ 그 기제는 **학습기가 상황을 못 갈라 한 후보로 평균을 낸다**"
						"(규율 39) = **담을 자리가 없었다**\n"
					"[ml]        ⇒ ★ **D178 이 그 자리를 만들었다**(문맥이 **82.7%** · 무작위 대비 **+7.8%p**)"
						" ⇒ **이제는 간섭이 생길 수 있다**\n"
				"[ml]     🎭 **세계 축**(규율 20 · `—` 10연속 뒤의 세계 판) — 상황을 **둘 → 셋**으로:"
					" 🎨 색만 · 📏 크기만 · 📍 **자리만**(A 의 x 가 {0,10,20})\n"
					"[ml]        ★ 셋을 고른 근거: **관측 셋(색·잉크·자리)이 각각 한 상황을 가른다**"
						" ⇒ `kObsPick3 = {색, 잉크, 자리, 늘1}`\n"
					"[ml]        ⚠️ 자리 최대 끝 26 < B 의 시작 32 ⇒ **안 겹친다**(`_Blobs` 가 하나로 안 본다)\n"
				"[ml]     ⚠️⚠️ **규율 21 — 세계의 서명부터 읽는다**(성능보다 먼저):"
					" 📍 자리만 상황에서 **`oPC` 가 살아나야** 한다(옛 세계에선 **늘 0** 이었다)\n"
				"[ml]     ⭐⭐ (57) **작동 판정** — ㋽(📍 자리만·따로)가 **혼자 돌 때 잘 푼다**"
					"(안 그러면 새 상황이 **답이 없는 세계**이고 그러면 규율 31 에 걸린다 ⇒ 그 아래는 전부 무효)\n"
				"[ml]     ⭐ (58) **핵심 = 간섭이 있나** — ⚠️ 규율 38 대로 **min(따로 셋)** 이 기준이다(평균이 아니다):\n"
					"[ml]        ㉠ **㋾(섞음) < min(㋻,㋼,㋽) − 문턱** ⇒ ✅ **간섭이 있다** ⇒ ㉡ 을 **잴 수 있는 판**이 열린다\n"
					"[ml]        ㉡ **㋾ ≈ min** ⇒ ⛔ 또 간섭이 없다 ⇒ 그러면 **D166 의 결론이 재확인**된다\n"
				"[ml]     ⭐ (59) **문맥이 값을 하나** — ㋾(문맥 있음) **>** ㈎(⛔ 문맥 없음) 를 문턱 넘게\n"
				"[ml]     🔭 (60) **상한** — ㈏(**오라클** · 상황을 그냥 준다)가 **min(따로 셋)에 닿나**\n"
					"[ml]        ★ 닿으면 *간섭은 원리적으로 다 없앨 수 있다* ⇒ 남은 것은 **문맥을 알아내는 일**뿐이다\n"
					"[ml]        ⚠️ ㈏ 는 **자이지 후보가 아니다**(규율 11 · ㈂ 와 같은 자리)\n"
			"[ml]   📌 **D178 등록 — 🩺 아래층을 살린다**(㉢ **마무리** · 겨냥 = **㉢** 수준 **㉰** 넷째 칸)\n"
				"[ml]     ⚠️⚠️ **규율 20 을 한 판 미뤘다**(D177 심사가 근거를 적었다) — ㉢ 이 **한 판이면 닫히고**"
					" 세계를 바꾸면 다섯 판의 기준(82.7 · 74.9 · 73.8)이 **통째로 무너진다**"
					" ⇒ ★ **그 다음은 무조건 🎭 세계 판**이다\n"
				"[ml]     ⭐ **D176 이 물음을 둘로 좁혔다** — 위층은 풀렸는데(`ow` **1.78**) 아래층이 안 쓴다"
					"(옳게 골라도 **문맥 없음과 동치** · 옳게↔틀리게가 **정확히 같다**)\n"
					"[ml]        ㉠ 🧮 칸이 **여덟**이라 표본이 나뉘었나(`aw[8][18]` = 144 ↔ D169 의 72)\n"
					"[ml]        ㉡ ⏳ 위층이 굳기 전 **초반이 아래층을 흩었나**\n"
				"[ml]     ⇒ ★ **N−1 로 하나씩** 시험한다:\n"
					"[ml]        ㋹ 🧮 **`aCtx = bit`** — 관측이 하나로 굳으면 **슬롯은 무의미**하다"
						" ⇒ 칸이 **둘**(D169 와 같은 수) · 표본이 **두 배**\n"
					"[ml]        ㋺ ⏳ **초반 300판은 `ow` 를 갱신하지 않고 균등으로** 뽑는다"
						" ⇒ ⚠️ **고정이 아니라 균등**이다(답을 주지 않는다)\n"
				"[ml]     🩺 ⭐⭐ **계기판을 등록에 넣었다**(규율 48 · D177 심사가 「안 봤다」로 센 셋 중 둘):\n"
					"[ml]        · **아래층 칸별 첫 선택** · **칸별 표본 수** ⇒ 한 줄로 찍는다\n"
					"[ml]        ★ 이 판이 **실패하면 그 로그가 어디서 실패했는지 말해야** 한다 — 그것이 규율 48 이다\n"
				"[ml]     ⚠️⚠️ **먼저 볼 것 넷**(평가 구간) — ㋲ 넷·살아3 **82.7%%** · ㋷ 갈림×하나 **73.8%%** ·"
					" ㋶ 무작위 **74.9%%** · ㋘ 문맥없음 **73.8%%**\n"
				"[ml]     ⭐⭐ (54) **작동 판정**(성능보다 먼저) — ㋹ 의 칸 **0·1 이 서로 다른 것**을 고르고"
					" **표본이 각각 300 이상**이다\n"
					"[ml]        ⚠️ 같은 것을 고르면 문맥이 안 쓰인 것이고, 표본이 적으면 **아직 칸 수 문제**다\n"
				"[ml]     ⭐ (55) **핵심** — ㋹ 또는 ㋺ 가 ㋷(**73.8%%**)를 문턱(**≈4.1%%p**) 넘게 이긴다\n"
					"[ml]        ㉠ **㋹ 만 오른다** ⇒ 범인은 **칸 수**(표본) — 📏 손 예측이 이쪽이다\n"
					"[ml]        ㉡ **㋺ 만 오른다** ⇒ 범인은 **초반 오염**\n"
					"[ml]        ㉢ **둘 다 안 오른다** ⇒ 원인이 **셋째 것**이고 그때는 계기판이 그것을 가리켜야 한다\n"
				"[ml]     ⭐ (56) **목표** — ㋲(**82.7%%**)에 근접하면 **㉢ 의 넷째 칸이 무작위와 갈린 채로 닫힌다**\n"
			"[ml]   ⚠️ ㈂ 는 **🔭 오라클**이다(우리가 방해자 색을 안다) — **상한을 재는 자**이고"
			" 「배웠다」의 증거가 아니다(이 저장소의 「답을 준 팔」과 같은 자리)\n"
			"[ml]   ⚠️ 문턱: 씨앗 %d x 과제 %d = **%d 에피소드/팔** ⇒ 표준오차 ~1.2%%p"
			" ⇒ **차이 문턱 ≈ 3.4%%p**\n"
			"[ml]   ⚠️⚠️ 과제는 **깊이 1**(색만 또는 크기만 다르다) — 자리 게이트(`_XOpen`)를 안 만나므로"
			" 탐욕이 원리적으로 풀 수 있다 ⇒ 실패는 **묶임 탓만** 남는다\n",
			npv, (uint32)pv[0], (uint32)pv[1], (uint32)pv[2], (uint32)pv[3], (uint32)pv[4],
			(uint32)dByte, dOk ? "재서 얻었다" : "⛔ 못 얻었다 — ㈂ 는 판정불가",
			nAbove, npv, (npv > 0) ? (100.0 * (double)nAbove / (double)npv) : 0.0,
			kSd, kPer, kSd * kPer);
		for (int arm = 0; arm < kBA; ++arm)
		{
			// 🔀 **이 라운드의 팔만** 돈다(D153).
			if ((kBRnd[arm] & rnd) == 0) continue;
			// 🧱 **재현되는 실험대**(D185 · 규율 59) — 이 팔을 **씨앗 여러 개**로 돌린다.
			//   ★ 학습 상태(`aw`/`aw2`/`ow`/계수기)가 **이 루프 안에서 선언**되므로
			//     반복마다 **완전히 새로 시작**한다 = 궤적이 여러 개가 된다.
			//   ⚠️ 로그는 **반복마다** 한 줄씩 나가고, 끝에 **평균 ± σ** 를 한 줄 더 찍는다.
			const int nRep = (kBRep[arm] > 0) ? kBRep[arm] : 1;
			// ⚠️ **그릇을 16 으로**(D188) — `8` 이면 씨앗 12 판이 **조용히 여덟만** 집계된다.
			//   ★ 규율 63 이 씨앗 예산을 설계 변수로 올렸으니 그릇도 같이 키운다.
			double repEv[16] = {};
			// 📋 **상황 x 후보 성적표**(D191) — ⚠️ 반복 루프 **밖**이다(반복마다 리셋되면 표본이 안 쌓인다).
			int scT[4][kBMx] = {}; int scOk[4][kBMx] = {};
			// 📋 **상황별 성적**(D191) — 학습 팔이 **어느 상황에서 얼마나 푸나**.
			//   ★ D189 가 못 가른 것을 이것이 가른다: *간섭인가 난이도 혼합인가*.
			int sitT[4] = {}; int sitOk[4] = {};
			for (int rep = 0; rep < nRep; ++rep)
			{
			const int nAct = kBNA[arm];   // 🔢 후보 수(3 또는 4)
			// 🧠 **학습 가중치**(D144) — `[|Δ값|, |Δ자리|, |Δ잉크|]`. ⚠️ **편향이 없다**:
			//   후보마다 **같은** 값은 확률을 못 바꾸고 갱신이 그 칸으로 **새어** 다른 칸이 못 배운다
			//   (D143 실측 `w = [−8.1, 0, 0, 0]` — 편향만 −8.1 까지 가고 **행동이 한 번도 안 바뀌었다**).
			double lw[3] = { 0.0, 0.0, 0.0 };
			// 🎯 **행동 선호**(D147) — 프로브 행동 셋의 점수다: `[0]` 🔎 관찰만 · `[1]` 🎨 색 · `[2]` 📏 크기.
			//   ⚠️ **문맥이 없다**(고를 때 아직 아무것도 안 봤다) ⇒ 이것은 **3팔 밴딧**이고, 그래서
			//     이 판은 ㉢「자기가 만든 경험」의 **절반**만 시험한다(상황마다 답이 갈리는 판은 다음이다).
			// 🔎 **첫 선택에도 문맥**(D169 · 함정 382 의 처방) — 첫 인덱스가 **문맥**이다.
			//   ⚠️⚠️ `kBCtx < 6` 인 팔은 **늘 `aw[0]`** 를 쓴다 ⇒ 옛 팔의 거동이 **구조로** 보장된다(규율 18).
			//   ★ **왜**: D168 은 문맥이 **살았는데도**(칸마다 다른 선택) 값이 없었다 —
			//     첫 선택은 문맥이 없고 **100%** 쓰이는데 문맥은 **갈아탄 판(20%)의 둘째**에만 있었다
			//     ⇒ 기대 = `0.8 x 평균 + 0.2 x 문맥` ⇒ **상한이 원리적으로 눌렸다**(규율 41).
			//   ⭐ **D172**: 칸이 **여덟**이다 — `관측 4 x 비트 2`(어느 관측을 골랐나 x 그것이 변했나).
			//   ⭐ **D174**: **열여섯** — `관측 8 x 비트 2`.
			// 🔭 **주소에 상황을 넣으면 칸이 32 개**(D200) — 끄면 앞 16 칸만 쓴다(규율 18).
			double aw[32][kBMx] = {};
			// 🤝 **공통 성향**(D186) — 모든 칸이 같이 쓰는 바닥이다.
			//   ⚠️ `kBShr == 0` 이면 **한 번도 안 갱신**되므로 늘 0 이다 ⇒ 옛 팔이 안 바뀐다.
			double aw0[kBMx] = {};
			// 🌟 **후보별 사용 횟수**(D194) — 호기심의 `N[k]` 다.
			//   ⚠️ 반복 루프 **안**이다(궤적마다 새로 세어야 그 궤적의 탐험이 된다).
			int nSel[kBMx] = {};
			// 🤝 두 학습률 배율 — [공통, 보정].
			const double shC = (kBShr[arm] == 0) ? 0.0 : ((kBShr[arm] == 3) ? 0.0 : 1.0);
			const double shD = (kBShr[arm] == 0) ? 1.0 : ((kBShr[arm] == 1) ? 0.2
				: ((kBShr[arm] == 2) ? 0.0 : ((kBShr[arm] == 4) ? 0.5 : 1.0)));
			// 🔄 **갈아타기 표**(D149) — `aw2[첫 후보][두 번째 후보]`. ★ 이것이 **문맥 있는** 정책이다
			//   (D148 의 밴딧은 표가 한 줄뿐이라 상황을 못 갈랐다 — 천장 75.6%).
			// 🧭 **문맥을 관측에서 만든다**(D167) — 첫 인덱스가 **문맥**이고 `kBCtx` 가 그것을 정한다:
			//   `0` = **첫 후보의 정체**(`aSel` · D149 가 세운 것) ·
			//   `1` = ⭐ **관측**(`rb` = 첫 프로브가 **몇 개로 좁혔나** · 0/1/2+) ·
			//   `2` = **둘 다**(`aSel*3 + rb`) · `3` = ⚠️ **무작위**(음성 — 칸 수만 같고 정보가 0).
			//   ★ **왜**: D166 이 **순위가 통째로 뒤집히는 두 상황**을 만들었는데(16 은 100 ↔ 49.1% ·
			//     13 은 27.1 ↔ 79.0%) 학습기가 **상황을 못 가르므로 한 후보로 평균(74.6%)을 냈다**(규율 39).
			//     ⇒ **담을 자리**를 주되 **상황을 손으로 알려주지 않는다** — 문맥이 **관측**에서 와야 한다.
			//   ⚠️ 칸 수가 `kBMx*3` 인 것은 `2`(둘 다) 때문이다. 물려주기는 `q < nAct` 라 그대로 안전하다.
			double aw2[kBMx * 3][kBMx] = {};   // ⚠️ 아래 `kBSeed` 가 이것을 덮을 수 있다(D151)
			int nSw = 0;   // 🔄 갈아탄 에피소드 수 — 「갈아타기가 얼마나 끝까지 갔나」
			// 🔔 **방아쇠가 당겨진 에피소드 수**(D155) — ⚠️ `nSw` 와 **다른 사실**이다:
			//   당겨도 두 번째 프로브가 실패하면 `continue` 하므로 `nSw` 는 안 는다.
			//   ★ 「울렸나」와 「끝까지 갔나」를 가르지 않으면 **발화율 0 과 실패를 구별 못 한다**.
			int nTg = 0;
			// 🧠 **`c₁` 을 배운다**(D163 · ㉡ 의 ㉯ = *범위 자체를 배운다*).
			//   ★ **뜻은 「책임 귀속」이다**: 갈아탔다는 것이 **그 후보 탓**인가 **상황 탓**인가.
			//     · 후보 `a` 의 갈아타기율이 **평균보다 높다** ⇒ **a 탓** ⇒ 첫 결정에 **덜** 준다(`c₁` ↓)
			//     · 평균과 같다 ⇒ **상황 탓** ⇒ a 는 무죄 ⇒ **더** 준다(`c₁` ↑)
			//   ⇒ `c₁[a] = 1 − 갈아타기율[a] ÷ 전체 갈아타기율`. **관측만으로 계산되고 후보마다 다르다.**
			//   ⚠️ 반사실(*다른 후보였어도 갈아탔을까*)은 못 보므로 **후보별 비율로 근사**한다.
			// 🧬 **관측 선택의 선호**(D172) — `0` = 색 · `1` = 잉크 · `2` = 색 또는 잉크 · `3` = 자리.
			//   ★ **이것이 ㉰ 의 넷째 칸**이다 — 지금까지 「무엇을 보고 상황을 가르나」는
			//     **사람이 `kBCtx` 로 정했다**. 이제 **후보를 펼쳐 고르는 행동**을 만든다(D156 의 관용구).
			//   📏 **손 예측**: 🎨 색만 세계 → `색` 이 1 · `잉크` 가 0 │ 📏 크기만 → 반대
			//     ⇒ **색·잉크는 가르고** `색또는잉크`(늘 1) 와 `자리`(늘 0)는 **상수라 못 가른다**
			//     ⇒ ★ **작동 판정 = `ow` 의 argmax 가 색 또는 잉크로 간다**
			//   ⭐ **D174**: 후보가 **여덟**이다 — 살아있는 셋(색·잉크·자리) + **죽은 다섯**.
			//     ⚠️ 죽은 것을 늘린 이유는 **음성 대조의 강도가 죽은 후보의 비율이 정하기** 때문이다(규율 45).
			// 🧬 **상황별 위층**(D199) — `kBOwS` 가 켜지면 `[epSit]` 을, 아니면 늘 `[0]` 을 쓴다.
			//   ⇒ 끄면 **한 바이트도 안 바뀐다**(규율 18).
			double ow[4][8] = {};
			// 🔬 **관측의 「갈림」**(D173 · 함정 384 의 처방) — 그 관측의 비트가 에피소드마다
			//   **0/1 로 갈리나**. `obm` = 비트의 러닝 평균 · 갈림 = `4·p·(1−p)`(0.5 에서 1, 0/1 에서 0).
			//   ★ **죽은 관측은 정의상 0점**이다 ⇒ **표본 편향에 원리적으로 안 걸린다**
			//     (D172 는 도달률로 재서 **안 가르는 관측이 이겼다** — 칸이 하나라 표본이 두 배였다).
			//   📏 손 예측: 🎨색 **1.0** · 📏잉크 **1.0** · 🔀(늘 1) **0.0** · 📍자리(늘 0) **0.0**
			double obm[8] = {};
			// 🩺 **아래층 계기판**(D178 · 규율 48) — 칸마다 몇 판을 받았나.
			//   ⚠️⚠️ 규율 44·47 이 **다 이 얘기인데 다섯 판 동안 한 번도 안 셌다**(D177 심사).
			int awN[32] = {};
			// 🧨 **관측 서명 계기판**(D180 · 규율 48) — 상황마다 `oVC`/`oIC`/`oPC` 가 몇 %% 참인가.
			//   ★ **이 판의 작동 판정이 곧 이 줄이다** — 두 충돌 상황의 서명이 **같아야**
			//     「안 보이는 충돌」이고, 다르면 그것은 그냥 **또 하나의 갈리는 상황**이다.
			int sigN[4][3] = {}; int sigT[4] = {};
			// 🎯 **후보별 거짓 도달 계기판**(D182 · 규율 48) — *어느 후보가 거짓을 낳나*.
			//   ★ D181 이 거짓 도달(28%%대)을 **병목**으로 지목했는데 **어느 후보 탓인지는 안 봤다**.
			int fbN[kBMx] = {}; int fbF[kBMx] = {};
			double obase = 0.0;   // 갈림 보상의 기준선(러닝 평균)
			double swR[kBMx] = {};   // 후보별 갈아타기율(러닝 평균)
			double swAll = 0.0;      // 전체 갈아타기율
			// 🔧 **전반 끝 스냅샷**(D164 · 규율 35) — 로그는 **이것**을 읽는다.
			double swRs[kBMx] = {}; double swAllS = 0.0; bool snapOk = false;
			// 📉 **기준선**(러닝 평균) — 종단 보상의 분산을 줄인다. `(r − b)` 가 갱신의 부호를 정한다.
			// 📉 **기준선** — 칸 둘이다: `[0]` = 색 과제 · `[1]` = 크기 과제.
			//   ⚠️ `kBndSb == 0` 인 팔은 **`[0]` 만** 써서 옛 거동을 그대로 재현한다(N−1).
			double lbase[2] = { 0.0, 0.0 };
			int lTrue[2] = {}, lFalse[2] = {}, lEp[2] = {};   // 전반/후반
			int nEp = 0, nTrue = 0, nMeas = 0, nFalse = 0;
			int nFrame = 0, nTwo = 0, nMiss = 0, nBad = 0;
			gNComp = 0;
			int64 nStep = 0;   // 🔬 걸음 수 — **시험의 대가**를 재려면 이것이 있어야 한다(D138)
			// 🔀 **물려받는다**(D151) — ㈕ 가 판을 끝내며 남긴 것을 시작값으로 쓴다.
			//   ⚠️ **가중치만** 물려준다(기준선은 안 준다 — 그것은 다음 축이다).
			//   ⭐ `3` = **같은 판**(Ⓔ)에서 받는다 — D153·D154 가 실제로 재고 있던 것이 이쪽이다(🐛B).
			if (kBSeed[arm] == 3)
			{
				if (gSeedSOk)
				{
					for (int q = 0; q < 3; ++q) aw[0][q] = gSeedS[q];   // ⚠️ 앞 3칸만 — 넷째는 **안 배운 채** 시작한다
					for (int q = 0; q < nAct; ++q)
						for (int r = 0; r < 3; ++r) aw2[q][r] = gSeedS2[q][r];
				}
			}
			else if (kBSeed[arm] != 0 && gSeedOk)
			{
				const double sg = (kBSeed[arm] == 2) ? -1.0 : 1.0;   // ⚠️ 2 = 음성 대조(부호 반전)
				for (int q = 0; q < 3; ++q) aw[0][q] = sg * gSeedW[q];   // ⚠️ 앞 3칸만 — 넷째는 **안 배운 채** 시작한다
				for (int q = 0; q < nAct; ++q)
					for (int r = 0; r < 3; ++r) aw2[q][r] = sg * gSeedW2[q][r];
			}
			for (int sd = 0; sd < kSd; ++sd)
			{
				// 🎲 씨앗을 **팔마다** 다시 뿌린다(함정 296) — 팔이 난수를 공유하면 대조군이 움직인다.
				// 🧱 **반복마다 다른 씨앗**(D185) — `977` 은 `131`·`7919` 와 안 겹치는 소수다.
					SeedRand((uint32)(1700 + sd * 131 + (kBRs[arm] + rep * 977) * 7919));
				for (int t = 0; t < kPer; ++t)
				{
					// 🧠 **학습 팔**(D143) — 손 규칙 대신 **짝 점수화**로 읽는다. 자기 루프를 쓴다
					//   (손 규칙 경로와 섞으면 어느 것이 값을 했는지 못 가른다 · 함정 169).
					if (kBPr[arm] == 7)
					{
						// 🔀 **학습 예산**(D151) — `kBLrnEp > 0` 이면 **처음 그만큼의 에피소드만** 배운다.
						//   ⚠️ `nEp` 는 **지금까지 센 것**이라 이 자리에서 「몇 번째 판인가」를 그대로 말한다.
						const bool evalPhase0 = (kBLrnEp[arm] > 0)
							? (nEp >= kBLrnEp[arm]) : (sd >= kSd / 2);
						const int half = evalPhase0 ? 1 : 0;
						// 🎓 **전반 = 배운다(확률뽑기) · 후반 = 평가한다(argmax · 학습 정지)**.
						//   ★ 「채점 팔과 정책 팔을 분리하라」(D99) — 읽기에 탐험을 섞으면 **탐욕 정책이 일관성을**
						//     **잃는다**(D144 실측: 26.6% ↔ 고정 읽기 45.5%). ⇒ **후반 숫자가 「배운 것」**이다.
						const bool evalPhase = evalPhase0;
						int lc = RandInt(0, nc), lcs = RandInt(0, 3);
						const int lcx = 1;
						int lgc = lc, lgs = lcs;
						if ((t & 1) == 0) lgc = (lc + 1 + RandInt(0, nc - 1)) % nc;
						else              lgs = (lcs + 1 + RandInt(0, 2)) % 3;
						Blob gb[8]; int gn = 0;
						if (!_BindProbe(lgc, lcx, lgs, 1, cell, plane, gb, gn)) continue;
						nEp++; lEp[half]++;
						// ⚠️ epStep 은 이 블록보다 **뒤에** 선언된다(스코프 밖) ⇒ 학습 팔은 자기 계수기를 쓴다.
						int64 lStep = 0;
						double gAcc[3] = { 0.0, 0.0, 0.0 };   // 🧠 누적 정책 기울기(종단 보상에 곱한다)
						bool measDone2 = false;
						for (int k = 0; k < kCap; ++k)
						{
							Blob cb[8]; int cn = 0;
							if (!_BindProbe(lc, lcx, lcs, 1, cell, plane, cb, cn)) { nBad++; break; }
							nFrame++; if (cn >= 2) nTwo++; gNComp += cn;
							// 🧠 **확률뽑기**(D144) — 네 쌍의 점수를 softmax 로 확률로 만들고 **뽑는다**.
							//   ⭐ `w = 0` 이면 **균등**이라 초기 탐험이 자동 최대이고, 배우면서 **저절로 좁아진다**
							//     ⇒ **섞는 비율 상수(ε)가 없다**(`concept.md` 의 그 요구 · D101 실측이 확률뽑기의 손을 든다).
							//   ⚠️ 그리고 **동점이 고정되지 않는다** — D143 이 갇힌 자리가 바로 그것이었다.
							const int nPair = cn * gn;
							double pf[16][3] = {};
							double ps[16] = {};
							int pi[16] = {}, pj[16] = {};
							int np = 0;
							for (int ci2 = 0; ci2 < cn && np < 16; ++ci2)
								for (int gj = 0; gj < gn && np < 16; ++gj)
								{
								const double dv2 = (double)((cb[ci2].v > gb[gj].v)
									? (cb[ci2].v - gb[gj].v) : (gb[gj].v - cb[ci2].v)) / 255.0;
								const int64 dx2 = (cb[ci2].cx16 > gb[gj].cx16)
									? (cb[ci2].cx16 - gb[gj].cx16) : (gb[gj].cx16 - cb[ci2].cx16);
								const uint64 hiI = (cb[ci2].ink > gb[gj].ink) ? cb[ci2].ink : gb[gj].ink;
								const uint64 loI = (cb[ci2].ink > gb[gj].ink) ? gb[gj].ink : cb[ci2].ink;
								pf[np][0] = dv2; pf[np][1] = (double)dx2 / 1024.0;
								pf[np][2] = (double)(hiI - loI) / 1200.0;
								double s2 = 0.0;
								for (int q2 = 0; q2 < 3; ++q2) s2 += lw[q2] * pf[np][q2];
								ps[np] = s2; pi[np] = ci2; pj[np] = gj; np++;
								}
							if (np <= 0) break;
							// softmax — ⚠️ 최대값을 빼서 넘침을 막는다(`Exp` 는 큰 양수에서 inf 다).
							double smax = ps[0];
							for (int k2 = 1; k2 < np; ++k2) if (ps[k2] > smax) smax = ps[k2];
							double zsum = 0.0;
							for (int k2 = 0; k2 < np; ++k2)
								{ ps[k2] = (double)Exp((float)(ps[k2] - smax)); zsum += ps[k2]; }
							if (zsum <= 0.0) break;
							for (int k2 = 0; k2 < np; ++k2) ps[k2] /= zsum;
							// 🎲 뽑는다(누적 확률). ⚠️ 정수 난수를 0..1 로 옮긴다.
							int sel = 0;
							if (evalPhase)
							{
								// 🎯 **평가 — argmax**. ⚠️ **동점은 무작위로 깬다**(D143 이 `>` 비교로 첫 번째에
								//   갇힌 자리다). 저수→고수 순회에서 같은 값이면 확률 `1/k` 로 바꾼다(온라인 균등).
								int nBestTie = 1; double bestS = ps[0];
								// ⚠️ `ps` 는 이미 softmax 확률이다 ⇒ **최대 확률 = 최대 점수**라 그대로 써도 된다.
								for (int k2 = 1; k2 < np; ++k2)
								{
									if (ps[k2] > bestS) { bestS = ps[k2]; sel = k2; nBestTie = 1; }
									else if (ps[k2] == bestS)
									{ nBestTie++; if (RandInt(0, nBestTie) == 0) sel = k2; }
								}
							}
							else
							{
								// 🎲 **학습 — 확률뽑기**(누적 확률). `w=0` 이면 균등이라 탐험이 자동 최대다.
								const double u2 = (double)RandInt(0, 10000) / 10000.0;
								sel = np - 1; double acc2 = 0.0;
								for (int k2 = 0; k2 < np; ++k2)
									{ acc2 += ps[k2]; if (u2 <= acc2) { sel = k2; break; } }
							}
							const int bi = pi[sel], bj = pj[sel];
							// 🧠 **대조 갱신의 기울기** — `f(고른 것) − Σ p·f` 는 정확히 **안 고른 것을 뺀 것**이다
							//   ⇒ 상대 순위가 움직인다(D143 은 고른 것만 밀어서 순위가 제자리였다).
							for (int q2 = 0; q2 < 3; ++q2)
							{
								double ex = 0.0;
								for (int k2 = 0; k2 < np; ++k2) ex += ps[k2] * pf[k2][q2];
								gAcc[q2] += pf[sel][q2] - ex;
							}
							(void)nPair;
							// ★ 고른 짝으로 **측정값을 읽는다** — 그 뒤는 손 정책과 같은 탐욕이다.
							const uint8 mv2 = cb[bi].v, gv2 = gb[bj].v;
							const uint64 mi2 = cb[bi].ink, gi2 = gb[bj].ink;
							if (mv2 == gv2 && cb[bi].cx16 == gb[bj].cx16 && mi2 == gi2)
								{ measDone2 = true; break; }
							lStep++;
							if (mv2 != gv2) lc = (lc + 1) % nc;
							else if (mi2 < gi2) { if (lcs < 2) lcs++; else break; }
							else                { if (lcs > 0) lcs--; else break; }
						}
						// ⚠️⚠️ 채점은 **세계가 아는 진짜 도달**이다(측정 도달로 채점하면 방해자를 배운다).
						const bool truth2 = (lc == lgc && lcs == lgs);
						if (truth2) { nTrue++; lTrue[half]++; }
						if (measDone2) nMeas++;
						if (measDone2 && !truth2) { nFalse++; lFalse[half]++; }
						// 🧠 **갱신**(D144) — 종단 보상 `r` 에 **기준선**을 빼고 누적 기울기에 곱한다(REINFORCE).
						//   ⚠️ 보상은 **진짜 도달**이다 — 측정 도달로 채점하면 방해자를 고르는 것을 배운다.
						const double lr2 = kBndLr[arm];
						const double r2 = truth2 ? 1.0 : 0.0;
						// 📉 과제군 = `t & 1`(0 = 색만 다르다 · 1 = 크기만 다르다). 팔이 안 켰으면 **한 칸만** 쓴다.
						const int sb = (kBndSb[arm] != 0) ? (int)(t & 1) : 0;
						if (lr2 > 0.0 && !evalPhase)   // 🎓 평가 단계는 **학습 정지**(그것이 분리의 뜻이다)
						{
							const double adv = r2 - lbase[sb];
							for (int q2 = 0; q2 < 3; ++q2) lw[q2] += lr2 * adv * gAcc[q2];
						}
						// 📉 기준선은 **갱신 뒤에** 옮긴다(같은 판의 보상으로 자기를 설명하지 않게).
						lbase[sb] += 0.01 * (r2 - lbase[sb]);
						nStep += lStep;
						continue;
					}
					// 🎓 **전반 = 배운다(확률뽑기) · 후반 = 평가한다(argmax · 학습 정지)** — D144 의 그 분리다.
					//   ⚠️ 손 규칙 팔은 이 값을 **안 쓴다**(그 팔의 거동은 한 바이트도 안 바뀐다).
					// 🔀 **학습 예산**(D151) — `kBLrnEp > 0` 이면 **처음 그만큼의 에피소드만** 배운다.
					//   ⚠️ `nEp` 는 **지금까지 센 것**이라 이 자리에서 「몇 번째 판인가」를 그대로 말한다.
					const bool evalPhase0 = (kBLrnEp[arm] > 0)
						? (nEp >= kBLrnEp[arm]) : (sd >= kSd / 2);
					const int half = evalPhase0 ? 1 : 0;
					const bool evalPhase = evalPhase0;
						// 🔧 **계기판 수리**(D164 · 규율 35 · 함정 378) — 러닝 평균을 **전반이 끝나는 순간**
						//   찍어 둔다. ⚠️ 팔 끝에서 찍으면 **후반(argmax · 갈아타기 거의 없음)**이 그것을
						//   0 으로 밀어 넣어 **학습 중의 값과 딴판**이 된다(D163 이 그것에 속을 뻔했다).
						if (evalPhase && !snapOk)
						{
							snapOk = true; swAllS = swAll;
							for (int q = 0; q < nAct; ++q) swRs[q] = swR[q];
						}
					int aSel = -1;                 // 🎯 고른 프로브 행동(0 🔎 · 1 🎨 · 2 📏)
					double apr[kBMx] = {};   // 그때의 확률 — 대조 갱신이 이것을 뺀다
					int bSel = -1;                 // 🔄 갈아탄 뒤 고른 것
					int bCtx = -1;                 // 🧭 그때 쓴 **문맥**(D167) — 갱신도 같은 칸에 해야 한다
					int aCtx = 0;                  // 🔎 **첫 선택의 문맥**(D169) — 갱신이 이 블록 **밖**이라 여기 둔다
					int oSel = -1;                 // 🧬 **어느 관측을 볼까**(D172) — 이것이 ㉰ 의 넷째 칸이다
					double opr[8] = {};            // 그때의 확률(대조 갱신이 이것을 뺀다)
					double bpr[kBMx] = {};
					int cc = RandInt(0, nc), cs = RandInt(0, 3);
					const int cx = 1;                       // 자리는 고정 — 게이트를 안 만난다
					int gc = cc, gs = cs;
					// 깊이 1 — **색만** 또는 **크기만** 다르다.
					if ((t & 1) == 0) gc = (cc + 1 + RandInt(0, nc - 1)) % nc;
					else              gs = (cs + 1 + RandInt(0, 2)) % 3;
					uint8 gv = 0; int64 gcx = 0; uint64 gink = 0;
					// 🔬 ㈃ — **시험 한 걸음으로 방해자 값을 얻는다**(오라클을 안 쓴다 · D138).
					//   ★ 색을 한 칸 돌려도 **방해자는 안 변한다** ⇒ **(값,잉크)가 그대로인 성분**이 방해자다.
					//   ⚠️ 시험은 **실제 행동**이다 — `cc` 가 움직이고 걸음을 하나 쓴다(공짜 관찰이 아니다).
					// ⚡ **방해자 색 인자**(D140) — 변하는 팔은 프레임마다 갈린다. 고정 팔은 늘 `1` 이다.
					int dfr = 0;                       // 프레임 계수기(변하는 방해자용)
					// 🎲 **이 에피소드의 상황**(D148) — `0` = 방해자의 **색**만 변한다 · `1` = **크기**만 변한다.
					//   ⚠️ `t` 로 **정확히 반씩** 가른다(무작위로 뽑으면 표집 잡음이 판정에 얹힌다).
					//   ★ 그리고 과제군(`t & 1`)과 **직교**한다 — 두 축이 섞이지 않는다.
					// 🎭 **상황 수**(D179) — `di >= 31` 세계는 **셋**, 옛 세계는 **둘**(재현 보존).
					//   ⚠️ `t` 로 정확히 나눈다(무작위로 뽑으면 표집 잡음이 판정에 얹힌다).
					//   ⚠️ `diBase` 는 **아래에서** 선언된다 ⇒ 여기서는 `kBDi[arm]` 을 직접 본다.
					// 🧨 **충돌 축**(D180 · `kBCf`) — `1` 이면 상황이 **넷**(넷째 = 🧨 B 크기만) ·
					//   `2` 면 **충돌 둘만**(📏 A 크기만 ↔ 🧨 B 크기만) = 간섭을 **홀로** 재는 자리.
					//   `3` = 🧨 **순수 충돌 둘**(📍 A자리만 ↔ 🧨 B크기만 · D190) — 둘 다 **혼자서는 100.0% · σ 0.00**
					//     (100.0% · σ 0.00) D180 이 **서명이 같다**(`[0 0 100]`)고 찍은 바로 그 짝이다.
					//     ⇒ ★ 따로가 결정적이라 **σ_diff = σ(섞음) 하나뿐** ⇒ 잡음이 원리적으로 준다.
					//   `4` = 🎯 **진짜 충돌 둘**(🎨 A색만 ↔ 📏 A크기만 · D192) — D191 의 성적표가 지목했다:
					//     `📏➕i` 는 색 **100** / 크기 **53** · `🔎➖i` 는 색 **50** / 크기 **91**
					//     ⇒ 한 후보 최선 **76.5%** ↔ 문맥이 있으면 **95.5%** ⇒ **폭 +19.0%p**.
					//     ★ 그리고 두 상황은 **`oVC`(색이 변했나) 하나로 완전히 갈린다**
					//       ⇒ `kBCtx = 20`(살아있는 관측 **하나**)로 충분하고 그래서 **σ 가 작다**(규율 63).
					const int nSit = (kBCf[arm] >= 2 && kBCf[arm] <= 4) ? 2
						: ((kBCf[arm] == 1) ? 4 : 3);
					const int epSit = (kBMix[arm] == 0) ? 0
						: ((kBDi[arm] >= 31) ? ((t >> 1) % nSit) : ((t >> 1) & 1));
					// 🧬 **이 에피소드가 쓸 위층 줄**(D199) — 나누면 `epSit`, 공유면 늘 `0`.
					const int owS = (kBOwS[arm] != 0 && epSit >= 0 && epSit < 4) ? epSit : 0;
					// 🔬 **이 에피소드의 걸음** — ⚠️ 총합에 직접 더하지 않는다. 개입이 실패해 `continue` 하면
					//   그 에피소드는 **안 세어지는데** 걸음만 남아 평균이 부푼다(실측으로 밟았다).
					//   ⇒ **에피소드가 세어질 때만** 총합에 더한다 ⇒ 분자·분모가 **원리적으로** 짝이 맞는다.
					int64 epStep = 0;
					const int diBase = kBDi[arm];
					int dvArm = (kBPr[arm] == 1) ? (dOk ? (int)dByte : -1) : -1;
					int prArm = (kBPr[arm] == 1) ? 1 : 0;
					// ⚡ 이 프레임의 `di` — 변하는 팔이면 `2 + (계수기 % 3)` 이다.
					auto DiOf = [&](int bump) -> int
					{
						if (diBase == 0) return 0;
						// 🎨🎨 **같은 색 방해자 둘**(D153) — 변주가 없으므로 그대로 넘긴다.
						//   ⛔ 이 줄을 빠뜨려 아래 `kBMv == 0` 이 **무조건 옛 세계(`1`)로** 떨어뜨렸고
						//     그 판의 모든 팔이 **100.0%** 였다(함정 369).
						// 🎲 **상황 섞임**(D166) — `31+q` 는 A 가 **색만**(`q = m`) 또는 **크기만**(`q = 3m`) 변한다.
						//   ★ `kBMix` 가 켜져 있으면 **에피소드마다** 둘 중 하나다(`epSit` — `t` 로 정확히 반씩).
						//   ⚠️ 안 켜져 있으면 **색만** 변하는 세계로 고정한다(「따로 재는」 팔의 자리).
						// 🎭 **상황 셋**(D179) — 🎨 색만(`m`) · 📏 크기만(`3m`) · 📍 **자리만**(`9m`).
						//   ★ **왜 세계를 셋으로**: D166 이 ㉡ 을 접은 이유는 *학습기가 상황을 못 갈라
						//     한 후보로 평균을 낸다*(규율 39)였는데 **D178 이 문맥을 작동시켰다**(82.7% · 무작위 +7.8%p)
						//     ⇒ **담을 자리가 생겼으니 간섭이 생길 수 있다** ⇒ 상황을 하나 더 둬서 다시 묻는다.
						//   ⚠️ `diBase` 33 = 📍 자리만 고정(따로 재는 팔).
						if (diBase >= 31)   // ⚠️ `61`(🧨 B 크기만)도 이 갈래다
						{
							const int m2 = (dfr + bump) % 3;
							// 🧨 **충돌 둘만**(`kBCf == 2`) — 0 = 📏 A 크기만(`31+3m`) · 1 = 🧨 **B 크기만**(`61+3m`).
							// 🎯 **진짜 충돌 둘**(`kBCf == 4` · D192) — 0 = 🎨 A색만(`31+m`) · 1 = 📏 A크기만(`31+3m`).
							if (kBCf[arm] == 4 && kBMix[arm] != 0)
								return 31 + ((epSit == 0) ? m2 : (3 * m2));
							// 🧨 **순수 충돌 둘**(`kBCf == 3` · D190) — 0 = 📍 A자리만(`31+9m`) · 1 = 🧨 B크기만(`61+3m`).
							if (kBCf[arm] == 3 && kBMix[arm] != 0)
								return (epSit == 0) ? (31 + 9 * m2) : (61 + 3 * m2);
							if (kBCf[arm] == 2 && kBMix[arm] != 0)
								return (epSit == 0) ? (31 + 3 * m2) : (61 + 3 * m2);
							if (kBMix[arm] != 0)
								return (epSit == 3) ? (61 + 3 * m2)
									: (31 + ((epSit == 0) ? m2 : ((epSit == 1) ? (3 * m2) : (9 * m2))));
							if (diBase >= 61) return 61 + 3 * m2;   // 🧨 B 크기만(따로 재는 팔)
							return 31 + ((diBase == 32) ? (3 * m2) : ((diBase == 33) ? (9 * m2) : m2));
						}
						// 🎭 **자리 변주**(D159) — `21+m` 은 프레임마다 방해자의 x 가 옮겨간다.
						//   ★ `20` 은 변주가 없다(D153) ⇒ 옛 팔이 한 바이트도 안 바뀐다.
						if (diBase >= 21) return 21 + ((dfr + bump) % 3);
						if (diBase >= 20) return diBase;
						if (kBMv[arm] == 0) return 1;
						const int m = (dfr + bump) % 3;
						// ⚡⚡ 크기까지 변하는 팔은 `c + 3*s` 를 **같이** 돌린다(D141).
						// 🎲 **상황 섞임**(D148) — 색만 = `2 + m`(dk=m · ds=0) · 크기만 = `2 + 3m`(dk=0 · ds=m).
						if (kBMix[arm] != 0) return (epSit == 0) ? (2 + m) : (2 + 3 * m);
						return 2 + m + (kBSz[arm] ? (3 * m) : 0);
					};
					// 🔬 ㈃㈄ — **시험 한 걸음**(색축 = 2 · 크기축 = 3). 오라클을 안 쓴다.
					//   ⚠️ 시험은 **실제 행동**이다 — 세계가 움직이고 걸음을 하나 쓴다.
					// 🔎 ㈅ — **관찰만**(4). ★ 목표 프레임과 현재 프레임에 방해자가 **둘 다 그대로** 있고
					//   **목표는 반드시 하나 이상 다르다**(그래야 과제다) ⇒ **(값,잉크)가 둘 다 같은 성분**은
					//   방해자뿐이다 ⇒ **0 걸음**. 그것이 `concept.md` 의 「**관찰** 또는 시험」의 관찰 쪽이다.
					// 🔬 ㈃㈄㈇ 시험(2·3) · 🔎 ㈅㈆ 관찰(4) · ⚡ ㈈ 개입+예측(5).
					//   ⚠️ 못 찾으면 `prArm` 이 0 으로 남아 **`bl[0]` 로 떨어진다**(폴백) — 조용히 틀리게
					//     고르지 않고 **옛 규칙으로 돌아간다** ⇒ 그 대가가 도달률에 그대로 찍힌다.
					// 🔬 시험(2·3) · 🔎 관찰(4) · ⚡ 개입+예측(5) · ↩️ **되돌리는 개입**(6).
					//   ⚠️ 못 찾으면 `prArm` 이 0 으로 남아 **`bl[0]` 로 떨어진다**(폴백) — 조용히 틀리게
					//     고르지 않고 **옛 규칙으로 돌아간다** ⇒ 그 대가가 도달률에 그대로 찍힌다.
					if (kBPr[arm] >= 2)
					{
						Blob a0[8]; int n0 = 0;
						Blob a1[8]; int n1 = 0;
						const int cs0 = cs;            // ↩️ 되돌림에 쓴다
						if (!_BindProbe(cc, cx, cs, DiOf(0), cell, plane, a0, n0)) continue;
						// 🔎 **방아쇠와 독립인 관측**(D168) — **같은 상태**를 한 장 더 그려
						//   **방해자가 무엇을 바꾸는지** 본다: `1` = 색이 변한다 · `2` = 잉크가 변한다 · `3` = 둘 다.
						//   ★ **키도 행동도 안 탄다** ⇒ 방아쇠(`nRem`)가 이것을 **걸러낼 수 없다**(규율 40).
						//   ★ 그리고 **상황을 직접 가른다**: 🎨 색만 세계 → `1` · 📏 크기만 세계 → `2`.
						//   ⭐⭐ **자리를 여기로 옮겼다**(D169) — 행동과 무관하므로 **프로브 전에도** 된다
						//     ⇒ **첫 선택도** 이 문맥을 쓸 수 있다(D168 은 둘째에만 있어 상한이 눌렸다 · 규율 41).
						//   ⚠️ 대가는 **걸음 하나**다 — 음성 대조도 **같은 걸음**을 쓰게 해서 그것을 통제한다.
						int cs2 = 0;
						// 🧬 **관측 원시형 셋**(D172) — 색 · 잉크 · **자리**가 변했나.
						bool oVC = false, oIC = false, oPC = false;
						if (kBCtx[arm] >= 4)
						{
							Blob av2[8]; int nv2 = 0;
							if (_BindProbe(cc, cx, cs, DiOf(1), cell, plane, av2, nv2))
							{
								for (int k0 = 0; k0 < n0; ++k0)
								{
									bool fv = false, fi = false, fp = false;
									for (int kv = 0; kv < nv2; ++kv)
									{
										if (a0[k0].v == av2[kv].v) fv = true;
										if (a0[k0].ink == av2[kv].ink) fi = true;
										if (a0[k0].cx16 == av2[kv].cx16) fp = true;
									}
									if (!fv) oVC = true;
									if (!fi) oIC = true;
									if (!fp) oPC = true;   // 🧬 자리도 본다(이 세계에선 **늘 0** = 못 가르는 관측의 실물)
								}
								cs2 = (oVC ? 1 : 0) + (oIC ? 2 : 0);
								// 🧨 **상황별 관측 서명**(D180 · 규율 48) — 이 판의 작동 판정이 곧 이 줄이다.
								if (epSit >= 0 && epSit < 4)
								{
									sigT[epSit]++;
									if (oVC) sigN[epSit][0]++;
									if (oIC) sigN[epSit][1]++;
									if (oPC) sigN[epSit][2]++;
								}
							}
							epStep++;
						}
						// 🔎 **첫 선택의 문맥**(D169) — `6` = 관측 · `7` = ⚠️ 무작위(음성 · 같은 걸음).
						//   ⚠️ 그 밖은 **늘 0** ⇒ 옛 팔이 한 바이트도 안 바뀐다(규율 18).
						// 🔭 **상황을 그냥 준다**(D179 · `22`) — **오라클**이다(우리가 `epSit` 를 안다).
						//   ★ 재는 것은 **상한**이다: *문맥을 완벽히 알면 간섭이 얼마나 사라지나*.
						//   ⚠️ 그래서 이것은 **후보가 아니라 자**다(규율 11 · ㈂ 와 같은 자리).
						aCtx = (kBCtx[arm] == 6) ? cs2
							: ((kBCtx[arm] == 7) ? RandInt(0, 4)
							: ((kBCtx[arm] == 22) ? epSit : 0));
						// 🧬 **어느 관측을 볼까를 고른다**(D172) — `8` = 배운다 · `9` = ⚠️ 무작위(음성).
						//   ⚠️ 고른 관측 하나만 쓰므로 **걸음은 그대로**다(관측 한 장은 이미 위에서 그렸다).
						//   ⚠️ `22` 는 오라클이라 **관측을 고르지 않는다**(`oSel` 이 `-1` 로 남아 위층 갱신도 안 돈다).
						if (kBCtx[arm] >= 8 && kBCtx[arm] != 22)
						{
							// 🪦 **관측 후보 수**(D174) — `13`·`14` 는 **여덟**(죽은 것 다섯), 그 밖은 넷이다.
							// 🎯 **비율만 바꾼다**(D175 · 함정 386) — 후보 **수**는 넷으로 두고 **살아있는 것만 하나**로.
							//   ★ 규율 46: 죽은 것을 늘리려고 **후보 수**를 늘리면 표본이 나뉘어 학습이 죽는다
							//     ⇒ **수는 고정하고 비율만** 바꾼다. 모델이 계산해 줬다:
							//     무작위 = 1/4x82.7 + 3/4x73.8 = **76.0%**(여덟과 같은 음성 강도) · 배운 것 = **82.7%**
							//     ⇒ 차 **+6.7%p** > 문턱 3.91 ⇒ 갈린다.
							//   ⚠️ 그리고 **더 어려운 시험**이다 — 넷 중 **하나뿐인 답**을 찾아야 한다.
							static const int kObsPick[4] = { 0, 4, 5, 6 };   // 🎨색(살아) · 🪦늘1 · 🪦늘0 · 🪦색and잉크
							// 🎭 **상황이 셋이면 관측도 셋이 필요하다**(D179) — 색 · 잉크 · **자리** + 죽은 것 하나.
							static const int kObsPick3[4] = { 0, 1, 3, 4 };
							const bool obit[8] = { oVC, oIC, (oVC || oIC), oPC,
								true, false, (oVC && oIC), (oPC != oIC) };
							const int nObs = (kBCtx[arm] == 13 || kBCtx[arm] == 14) ? 8 : 4;
							// ⏳ **위층을 늦게 켠다**(D178 · `20`) — 초반 **300판**은 `ow` 를 **갱신하지 않고 균등**으로 뽑는다.
							//   ★ 아래층이 먼저 배우게 하는 것이고, **답을 주지 않는다**(고정이 아니라 균등이다).
							//   ⇒ D176 의 후보 둘 중 **초반 오염** 쪽을 시험한다.
							if (kBCtx[arm] == 9 || kBCtx[arm] == 14 || kBCtx[arm] == 16
								|| (kBCtx[arm] >= 20 && nEp < 300)) oSel = RandInt(0, nObs);
							else
							{
								double omx = ow[owS][0];
								for (int q = 1; q < nObs; ++q) if (ow[owS][q] > omx) omx = ow[owS][q];
								double osum = 0.0;
								for (int q = 0; q < nObs; ++q) { opr[q] = (double)Exp((float)(ow[owS][q] - omx)); osum += opr[q]; }
								if (osum <= 0.0) continue;
								for (int q = 0; q < nObs; ++q) opr[q] /= osum;
								if (evalPhase)
								{
									int nT = 1; oSel = 0;
									for (int q = 1; q < nObs; ++q)
									{
										if (opr[q] > opr[oSel]) { oSel = q; nT = 1; }
										else if (opr[q] == opr[oSel]) { nT++; if (RandInt(0, nT) == 0) oSel = q; }
									}
								}
								else
								{
									const double u5 = (double)RandInt(0, 10000) / 10000.0;
									oSel = nObs - 1; double acc5 = 0.0;
									for (int q = 0; q < nObs; ++q) { acc5 += opr[q]; if (u5 <= acc5) { oSel = q; break; } }
								}
							}
							// 🔬 **넷 다 센다**(D173) — 고른 것만 세면 안 고른 관측의 갈림을 영영 모른다.
							//   ⚠️ 관측 자체는 **이미 한 장으로 다 얻었다**(oVC·oIC·oPC) ⇒ 걸음이 안 는다.
							// 🪦 **죽은 관측을 늘린다**(D174 · 함정 385) — `4`~`7` 은 **원리적으로 상수**다:
							//   `4` 늘 1 · `5` 늘 0 · `6` 색**과** 잉크(두 세계 다 한쪽만 변하니 **늘 0**) ·
							//   `7` 자리≠잉크(🎨 는 둘 다 0 · 📏 는 둘 다 1 ⇒ **늘 0**).
							//   ⇒ 살아있는 것이 **여덟 중 셋** ⇒ 무작위가 **원리적으로** 나빠진다.
							for (int q = 0; q < nObs; ++q)
							{
								const int oi = (kBCtx[arm] == 21) ? kObsPick3[q]
								: ((kBCtx[arm] >= 15) ? kObsPick[q] : q);
								obm[q] += 0.01 * ((obit[oi] ? 1.0 : 0.0) - obm[q]);
							}
							const bool bit = obit[(kBCtx[arm] == 21) ? kObsPick3[oSel]
								: ((kBCtx[arm] >= 15) ? kObsPick[oSel] : oSel)];
							// 🧮 **칸을 둘로**(D178 · `19`) — 관측이 하나로 굳으면 **슬롯은 무의미**하다.
							//   ★ 그러면 칸이 **둘**이 되어 D169 의 문맥 고정(**82.7%**)과 **같은 칸 수**이고
							//     표본이 **두 배**다 ⇒ D176 의 후보 둘(칸 수 ↔ 초반 오염) 중 **칸 수** 쪽을 시험한다.
							aCtx = (kBCtx[arm] == 19) ? (bit ? 1 : 0) : (oSel * 2 + (bit ? 1 : 0));
							// 🔭 **주소에 상황을 더한다**(D200 · 자) — 겹침이 원리적으로 사라진다.
							if (kBAdr[arm] != 0 && epSit >= 0 && epSit < 4) aCtx += epSit * 8;
						}
						// 🎯 **행동을 고르는 자리**(D147) — `kBPr == 8` 이면 프로브를 사람이 못 박지 않는다.
						//   ★ 후보 셋은 **이미 세계에 있는 행동**이다: 🔎 관찰만(0걸음) · 🎨 색 한 칸 · 📏 크기 한 칸.
						//   ★ 그리고 **읽는 규칙은 하나로 고정**한다(아래 `kBPr == 8` 분기) ⇒ 갈리는 것은 **행동뿐**이다.
						//   ⚠️ 어느 것이 갈라 주는지 **안 알려준다** — 보상(진짜 도달)만 준다. 그것이 이 판의 요점이다.
						int aMode = kBPr[arm];
						// 🔑 **읽는 키**(D148) — 5 = 잉크만 · 6 = 자리(되돌림) · **7 = 값만**(새것) · 그 외 = 값+잉크.
						//   ★ 손 규칙 팔은 `kBPr` 이 그대로 키라 **거동이 한 바이트도 안 바뀐다**.
						int aKey = kBPr[arm];
						if (kBPr[arm] >= 8)
						{
							if (kBFix[arm] >= 0)
							{
								// 📌 **못 박은 팔** — 늘 그 후보다. 확률이 one-hot 이라 갱신도 0 이다(`lr` 도 0 이다).
								aSel = kBFix[arm];
								for (int q = 0; q < nAct; ++q) apr[q] = (q == aSel) ? 1.0 : 0.0;
							}
							else
							{
							// 🤝 **실효값 = 공통 + 보정**(D186). `kBShr == 0` 이면 `aw0` 이 0 이라 옛 식 그대로다.
							double aeff[kBMx];
							// 🌟 **호기심 가산점**(D194) — `c > 0` 이면 덜 써 본 후보를 민다.
							//   ⛔ `c < 0` 은 **음성**이다: |c| 만큼 **무작위로** 민다(탐험은 같고 정보는 0).
							const double cCur = kBCur[arm];
							for (int q = 0; q < nAct; ++q)
							{
								double bon = 0.0;
								if (cCur > 0.0)      bon = cCur / (double)Sqrt((float)(nSel[q] + 1));
								else if (cCur < 0.0) bon = -cCur * ((double)RandInt(0, 1001) / 1000.0);
								aeff[q] = aw0[q] + aw[aCtx][q] + bon;
							}
							double amx = aeff[0];
							for (int q = 1; q < nAct; ++q) if (aeff[q] > amx) amx = aeff[q];
							double asum = 0.0;
							for (int q = 0; q < nAct; ++q) { apr[q] = (double)Exp((float)(aeff[q] - amx)); asum += apr[q]; }
							if (asum <= 0.0) continue;
							for (int q = 0; q < nAct; ++q) apr[q] /= asum;
							if (evalPhase)
							{
								// 🎯 평가 — argmax. ⚠️ **동점은 무작위로**(D143 이 갇힌 자리 · 확률 1/k 로 바꾼다).
								int nTie = 1; aSel = 0;
								for (int q = 1; q < nAct; ++q)
								{
									if (apr[q] > apr[aSel]) { aSel = q; nTie = 1; }
									else if (apr[q] == apr[aSel]) { nTie++; if (RandInt(0, nTie) == 0) aSel = q; }
								}
							}
							else
							{
								// 🎲 학습 — 확률뽑기. `aw = 0` 이면 **균등**이라 초기 탐험이 자동 최대다(ε 상수가 없다).
								const double u3 = (double)RandInt(0, 10000) / 10000.0;
								aSel = nAct - 1; double acc3 = 0.0;
								for (int q = 0; q < nAct; ++q) { acc3 += apr[q]; if (u3 <= acc3) { aSel = q; break; } }
							}
							}
							if (nAct >= kBMx)
							{
								// 🧩 **18-메뉴**(D156) — 후보 번호를 **축으로 풀어** 행동과 키를 만든다.
								//   ★ 키는 `100 + 후보` 로 흘려보낸다 ⇒ 아래에 **통합 분기 하나**만 있으면 된다.
								//   ⚠️⚠️ 손 메뉴 팔(`nAct <= 4`)은 **이 갈래로 안 온다** — 옛 경로를 그대로 타서
								//     재현이 **구조로** 보장된다(규율 18). 통합 규칙이 맞는지는 고정 팔
								//     `🧩02/06/13/16` 이 `Ⓐ/Ⓑ/Ⓒ/Ⓓ` 와 **같은 값**을 내는지로 검산한다.
								aMode = (aSel / 6 == 0) ? 4 : ((aSel / 6 == 1) ? 2 : 3);
								aKey  = 100 + aSel;
							}
							else
							{
							// 🔁 고른 것을 **손 규칙의 어휘로** 옮긴다 — 배관을 새로 만들지 않는다(같은 길을 탄다).
							aMode = (aSel == 0) ? 4 : ((aSel == 1) ? 2 : 3);   // ⭐ 넷째도 행동은 📏 크기다
							// 🔑 **키도 같이 고른다**(D148) — 후보는 **(행동, 키) 짝**이다.
							//   ⚠️ 안 그러면 상황 B(방해자 크기가 변한다)에 **답이 아예 없다**: 잉크 키가 죽는다.
							// ⭐ **넷째 = 고르기 극성**(D153) — 행동은 📏 와 같고 **읽는 극성만 뒤집힌다**.
							if (kBPr[arm] == 9)
								aKey = (aSel == 0) ? 2 : ((aSel == 1) ? 7 : ((aSel == 2) ? 5 : 8));
							// ⚠️⚠️ **`kBPr == 8` 은 키가 하나로 고정이다**(D147 의 설계 — 갈리는 것이 행동뿐이어야 한다).
							//   ⛔ 이 줄을 빠뜨려 `aKey` 가 **8 로 남았고** 식별이 값+잉크 키로 떨어져 ㈎ 가
							//     **100.0% → 28.4%** 로 무너졌다(D148 실측 · 함정 366).
							else                aKey = 5;
								}
							}
						if (aMode == 4)
						{
							// 🔎 짝은 **목표 프레임**이다 — 세계를 안 건드린다.
							if (!_BindProbe(gc, cx, gs, DiOf(1), cell, plane, a1, n1)) continue;
						}
						else
						{
							int ccT = cc, csT = cs;
							if (aMode == 2) ccT = (cc + 1) % nc;
							else                csT = (cs < 2) ? (cs + 1) : (cs - 1);
							if (!_BindProbe(ccT, cx, csT, DiOf(1), cell, plane, a1, n1)) continue;
							// ⚠️⚠️ **`dfr` 을 여기서 올리지 않는다** — 올리면 아래 되돌림의 `DiOf(2)` 가 실제로는
							//   **+3 ≡ 0**(mod 3) 이 되어 **방해자도 돌아오고** ㈊ 의 전제가 깨진다(실측으로 밟았다:
							//   에피소드 704/1800 = **61% 손실**). ⇒ 프로브는 **명시 bump(0·1·2)** 만 쓴다.
							cc = ccT; cs = csT; epStep++;   // ⚠️ 시험의 대가
						}
						if (aKey >= 100)
						{
							// 🧩 **18-메뉴 통합 규칙**(D156) — 축 셋을 그대로 읽는다. 분기가 **하나**다.
							//   ★ 매치 술어 `M(k)` = *"내 속성으로 볼 때 `a0[k]` 와 같은 것이 `a1` 에 있나"*.
							//     ➖ **빼기** = `M` 이 참인 첫 성분이 **방해자**다(그 속성값을 키로 **제외**).
							//     ➕ **고르기** = `M` 이 거짓인 첫 성분이 **목표**다(그 **자리**를 키로 **선택**).
							//   ⚠️ 극성이 바뀌면 **키의 종류까지** 바뀐다(속성값 ↔ 자리) — 그것이 D153 이 손으로
							//     찾아낸 ⭐ 의 정체이고, 여기서는 **축이 저절로 낳는다**(사람이 안 적는다).
							const int cd = aKey - 100;
							const int cPol = (cd / 3) % 2;
							const int cAt  = cd % 3;
							for (int k0 = 0; k0 < n0 && dvArm < 0; ++k0)
							{
								bool hit = false;
								for (int k1 = 0; k1 < n1; ++k1)
								{
									const bool same = (cAt == 0) ? (a0[k0].v == a1[k1].v)
										: ((cAt == 1) ? (a0[k0].ink == a1[k1].ink)
										: (a0[k0].v == a1[k1].v && a0[k0].ink == a1[k1].ink));
									if (same) { hit = true; break; }
								}
								if (cPol == 0)
								{
									if (hit)
									{
										dvArm = (cAt == 1) ? (int)a0[k0].ink : (int)a0[k0].v;
										prArm = (cAt == 1) ? 5 : 1;
									}
								}
								else if (!hit) { dvArm = (int)a0[k0].cx16; prArm = 6; }
							}
						}
						else if (aKey == 6)
						{
							// ↩️ **되돌린다** — 크기를 원래로. 목표는 잉크가 **돌아오고** 방해자는 안 돌아온다.
							//   ⭐ 그래서 **잉크가 같은 성분이 「목표」**다(극성이 뒤집혔다).
							//   ★ 그 성분의 **자리**(`cx16`)를 키로 남긴다 — 이 판에서 목표는 자리를 안 바꾼다.
							Blob a2[8]; int n2 = 0;
							cs = cs0;
							if (!_BindProbe(cc, cx, cs, DiOf(2), cell, plane, a2, n2)) continue;
							epStep++;
							for (int k0 = 0; k0 < n0 && dvArm < 0; ++k0)
								for (int k2 = 0; k2 < n2; ++k2)
									if (a0[k0].ink == a2[k2].ink)
										{ dvArm = (int)a2[k2].cx16; break; }
							if (dvArm >= 0) prArm = 6;
						}
						else if (aKey == 5)
						{
							// ⚡ **개입 + 예측** — 크기를 시켰으니 **목표의 잉크가 변해야** 한다.
							//   ⇒ **잉크가 두 프레임에 그대로 남은 성분**이 방해자다.
							//   🎯 **㈎㈏ 도 이 규칙 하나만 쓴다**(D147) — 고른 행동이 무엇이든 판정자는 같다
							//     ⇒ 성능이 갈리면 그것은 **행동이 목표를 잉크로 움직였나**의 차이뿐이다.
							for (int k0 = 0; k0 < n0 && dvArm < 0; ++k0)
								for (int k1 = 0; k1 < n1; ++k1)
									if (a0[k0].ink == a1[k1].ink) { dvArm = (int)a0[k0].ink; break; }
							if (dvArm >= 0) prArm = 5;
						}
						else if (aKey == 7)
						{
							// 🎨 **값만 키**(D148) — 색을 한 칸 돌렸으니 **목표의 값은 반드시 변한다**
							//   ⇒ **값이 두 프레임에 그대로인 성분**이 방해자다.
							//   ⚠️⚠️ 잉크를 **같이 보면 안 된다** — 방해자의 크기가 변하는 상황에서 잉크 조건이
							//     **방해자를 놓치게** 만든다(옛 「값+잉크」 키가 그 판에서 죽는 이유가 그것이다).
							for (int k0 = 0; k0 < n0 && dvArm < 0; ++k0)
								for (int k1 = 0; k1 < n1; ++k1)
									if (a0[k0].v == a1[k1].v) { dvArm = (int)a0[k0].v; break; }
							if (dvArm >= 0) prArm = 1;
						}
						else if (aKey == 8)
						{
							// ⭐⭐ **고르기 극성**(D153) — 「잉크가 **변한** 성분이 **목표**」다.
							//   ★ 방해자가 **둘**이면 「빼기」는 `dvArm` 에 **하나만** 담아 나머지가 남는다
							//     ⇒ 원리적으로 부족하다. 고르기는 **정확히 하나**를 집는다(우리가 움직인 것 하나).
							//   ★ 키는 **자리**(`cx16`)다 — 이 판에서 목표는 자리를 안 바꾼다(㈊ 와 같은 자리).
							for (int k0 = 0; k0 < n0 && dvArm < 0; ++k0)
							{
								bool moved = true;
								for (int k1 = 0; k1 < n1; ++k1) if (a0[k0].ink == a1[k1].ink) { moved = false; break; }
								if (moved) dvArm = (int)a0[k0].cx16;
							}
							if (dvArm >= 0) prArm = 6;
						}
						else
						{
							for (int k0 = 0; k0 < n0 && dvArm < 0; ++k0)
								for (int k1 = 0; k1 < n1; ++k1)
									if (a0[k0].v == a1[k1].v && a0[k0].ink == a1[k1].ink)
										{ dvArm = (int)a0[k0].v; break; }
							if (dvArm >= 0) prArm = 1;
						}
						// 🔄 **갈아타기**(D149) — 첫 후보가 **매치를 하나도 못 찾았다**(`dvArm < 0`)면 그것 자체가
						//   「이 키는 이 상황에 안 맞는다」는 **세계의 대답**이다 ⇒ 다른 후보로 간다.
						//   ★ 문맥은 **첫 후보의 정체**(`aSel`)이고, 방아쇠는 **관측**(매치 0)이다 — 축 이름이 아니다.
						//   ⚠️ 대가는 **걸음 하나**다(두 번째 프로브도 실제 행동이다).
						// 🔔 **좁히고 남은 후보 수**(D155) — 「내 키가 이 프레임을 몇 개로 좁혔나」.
						//   ★ `_BindRead` 와 **똑같은 술어**다 ⇒ 읽는 쪽이 실제로 보게 될 후보 수와 같다.
						//   ★ 오라클이 아니다 — 정답을 안 보고 **내 키의 결과만** 센다.
						//   ⚠️ 매치가 0 이면 좁힌 것이 없다 ⇒ 성분 전부가 남는다(그래서 옛 방아쇠를 **포함**한다).
						int nRem = n0;
						if (dvArm >= 0)
						{
							nRem = 0;
							for (int k0 = 0; k0 < n0; ++k0)
							{
								const bool keep = (prArm == 1) ? (a0[k0].v != (uint8)dvArm)
									: ((prArm == 5) ? (a0[k0].ink != (uint64)dvArm)
									: ((prArm == 6) ? (a0[k0].cx16 == (int64)dvArm) : true));
								if (keep) nRem++;
							}
						}
						// 🔔 **방아쇠**(D155) — `kBTg` 가 무엇을 보고 의심하나를 정한다.
						//   ⚠️ `0`(옛것)은 **한 바이트도 안 바뀌어야 한다** — 옛 팔 전부가 그 값이다(규율 18).
						// 🔔 **「내 지목이 사라졌다」**(D159) — ➕ 극성은 **자리**를 키로 삼는데, 방해자를
						//   잘못 집었으면 **다음 프레임에 그 자리에 아무것도 없다**. ⇒ 한 프레임 더 그려
						//   **내 지목이 아직 있나**를 본다. ★ 오라클이 아니라 **자기 개입의 결과**다.
						//   ⚠️ 확인도 **걸음 하나**다(공짜 관찰이 아니다).
						//   ⚠️⚠️ 이 신호가 없으면 그 판은 조용히 **버려진다**(`_BindRead` 실패 → `continue`)
						//     ⇒ 도달률이 **부풀려진다**. 방아쇠로 바꾸면 그 판이 **살아서 세어진다.**
						bool gone = false;
						if (kBTg[arm] >= 4 && kBTg[arm] <= 6 && prArm == 6 && dvArm >= 0)
						{
							Blob av[8]; int nv = 0;
							if (_BindProbe(cc, cx, cs, DiOf(2), cell, plane, av, nv))
							{
								gone = true;
								for (int k = 0; k < nv; ++k)
									if (av[k].cx16 == (int64)dvArm) { gone = false; break; }
							}
							epStep++;
						}
						bool susp = (dvArm < 0);
						if (kBTg[arm] == 1)      susp = (nRem != 1);
						else if (kBTg[arm] == 2) susp = (gTgOk && RandInt(0, 10000) < gTgRate);
						else if (kBTg[arm] == 3) susp = (nRem == 1);   // ⚠️ 음성 대조 — 일부러 거꾸로
						else if (kBTg[arm] == 4) susp = gone;                     // 🔔 지목 지속만
						else if (kBTg[arm] == 5) susp = (nRem != 1) || gone;      // 🔔 둘 다
						// ⚠️ **음성 대조**(D160 · 규율 27 의 숙제) — 지목이 **아직 있을 때** 갈아탄다.
						//   ★ 갈 곳이 있다: 「멀쩡한 지목을 버린다」이므로 **반드시 나빠져야** 한다.
						else if (kBTg[arm] == 6) susp = (prArm == 6 && dvArm >= 0 && !gone);
						// 🔁 **에피소드 안 성패 신호**(D181 · 규율 54 의 처방) — 방아쇠가 아니라 **결과**가 정한다.
						//   ★ D180 이 값으로 보였다: 방아쇠는 **결정 이전의 같은 프레임**을 보므로
						//     **문맥이 못 가르는 것은 방아쇠도 못 가른다** — 안 보이는 충돌에서 갈아타기를 **끈**
						//     팔이 **켠** 팔보다 높았다(95.0 ↔ 91.3 · +3.7%p). 두 번째 추측은 잡음만 늘렸다.
						//   ⇒ ★ 그래서 **먼저 가 본다** — 첫 후보로 **시험 항해**를 하고 **못 맞추면 그때** 갈아탄다.
						//   💰 대가는 **걸음**이다(쓴 만큼 `epStep` 에 싣는다) ⇒ 음성 `3`(걸음만 더)이 그 비용을 통제한다.
						//   ⚠️⚠️ **되감지 않는다** — 간 자리(`cc`/`cs`)를 **그대로 둔다**. 그것이 진짜 「시도」다
						//     (되감으면 공짜 상상이 되고, 그건 이 계에 없는 능력이다).
						if (kBRt[arm] != 0 && aSel >= 0)
						{
							const int kRt = 8;   // ⏱️ 시험 예산 = 걸음 예산(16)의 절반
							// ⏪ **되감는 팔**(D182 · `kBRt == 4`) — 시험이 간 자리를 **복원**한다.
							//   ★ D181 이 **못 가른 둘**을 이것이 가른다: *신호의 질이 나쁜가* ↔
							//     *되감지 않아서 출발점이 나빠졌나*. 되감아도 안 오르면 **범인은 신호**다.
							//   ⚠️ 되감기는 **공짜 상상**이라 이 계에 없는 능력이다 ⇒ **자로만** 쓴다(규율 11).
							const int sc0 = cc, ss0 = cs;
							susp = true;
							uint8 tv = 0; int64 tcx = 0; uint64 tink = 0;
							if (_BindRead(gc, cx, gs, DiOf(2), prArm, dvArm, (kBMv[arm] == 0 && dOk) ? (int)dByte : -1,
								cell, plane, tv, tcx, tink, nFrame, nTwo, nMiss, kBKeep[arm] != 0))
							{
								for (int k = 0; k < kRt; ++k)
								{
									uint8 mv = 0; int64 mcx = 0; uint64 mink = 0;
									if (!_BindRead(cc, cx, cs, DiOf(3 + k), prArm, dvArm,
										(kBMv[arm] == 0 && dOk) ? (int)dByte : -1,
										cell, plane, mv, mcx, mink, nFrame, nTwo, nMiss, kBKeep[arm] != 0)) break;
									epStep++;   // 💰 시험도 걸음이다
									if (mv == tv && mcx == tcx && mink == tink)
									{
										if (kBVf[arm] == 0) { susp = false; break; }
										// 🔍 **한 걸음 더 재서 같은지 본다**(D182) — 거짓 짝은 다음 프레임에서 흩어진다.
										//   ⚠️ 목표도 **같은 프레임**에서 다시 읽는다(공정한 비교).
										uint8 gv2 = 0; int64 gcx2 = 0; uint64 gink2 = 0;
										uint8 mv2 = 0; int64 mcx2 = 0; uint64 mink2 = 0;
										epStep++;   // 💰 확인도 걸음이다
										const bool okv =
											_BindRead(gc, cx, gs, DiOf(4 + k), prArm, dvArm,
												(kBMv[arm] == 0 && dOk) ? (int)dByte : -1,
												cell, plane, gv2, gcx2, gink2, nFrame, nTwo, nMiss, kBKeep[arm] != 0)
											&& _BindRead(cc, cx, cs, DiOf(4 + k), prArm, dvArm,
												(kBMv[arm] == 0 && dOk) ? (int)dByte : -1,
												cell, plane, mv2, mcx2, mink2, nFrame, nTwo, nMiss, kBKeep[arm] != 0);
										if (okv && mv2 == gv2 && mcx2 == gcx2 && mink2 == gink2) { susp = false; break; }
										// ⛔ **안 버텼다** ⇒ 거짓이다 ⇒ 계속 간다(그리고 갈아탈 이유가 남는다).
									}
									if (mv != tv) cc = (cc + 1) % nc;
									else if (mink < tink) { if (cs < 2) cs++; else break; }
									else                  { if (cs > 0) cs--; else break; }
								}
							}
							// ⛔ **음성 — 걸음만 쓰고 안 갈아탄다**(`3` = 안 되감음 · `5` = **되감음**).
							//   ★ D182 가 `5` 를 빠뜨렸다 — 되감기 판에서 *이득이 걸음의 부산물인가*를 못 물었다.
							if (kBRt[arm] == 3 || kBRt[arm] == 5) susp = false;
							// ⏪ **되감는다**(자 · `4`·`5`·`6`) — 공짜 상상이라 능력이 아니다(규율 11).
							if (kBRt[arm] >= 4) { cc = sc0; cs = ss0; }
						}
						if (kBSw[arm] != 0 && susp && aSel >= 0)
						{
							nTg++;
							// ⚠️⚠️ **의심했으면 첫 키를 버린다** — 아래 몸통이 `dvArm < 0` 을 전제로 돈다.
							//   ★ 뜻도 그것이 맞다: *"이 키를 못 믿겠다"* 는 곧 *"그 지목을 안 쓴다"* 다.
							if (kBTg[arm] != 0) { dvArm = -1; prArm = 0; }
							// 🧭 **문맥을 정한다**(D167) — `rb` 는 **첫 프로브가 몇 개로 좁혔나**(관측).
							//   ⚠️ `nRem` 은 바로 위에서 `_BindRead` 와 **같은 술어**로 센 값이다(오라클 아님).
							const int rb = (nRem <= 0) ? 0 : ((nRem == 1) ? 1 : 2);
							// 🔎 `cs2` 는 **위(프로브 전)에서 이미 쟀다**(D169) — 행동과 무관하므로 그 자리가 맞다.
							const int ctx = (kBCtx[arm] == 1) ? rb
								: ((kBCtx[arm] == 2) ? (aSel * 3 + rb)
								: ((kBCtx[arm] == 3) ? RandInt(0, 3)
								: ((kBCtx[arm] == 4) ? cs2
								: ((kBCtx[arm] == 5) ? RandInt(0, 4) : aSel))));   // ⚠️ 5 = 같은 걸음 · 정보 0(음성)
							bCtx = ctx;
							double bmx = aw2[ctx][0];
							for (int q = 1; q < nAct; ++q) if (aw2[ctx][q] > bmx) bmx = aw2[ctx][q];
							double bsum = 0.0;
							for (int q = 0; q < nAct; ++q)
								{ bpr[q] = (double)Exp((float)(aw2[ctx][q] - bmx)); bsum += bpr[q]; }
							if (bsum <= 0.0) continue;
							for (int q = 0; q < nAct; ++q) bpr[q] /= bsum;
							// ⛔ **음성 — 무작위 재시도**(D181) — *「어느 것으로 고쳐 쓰나」가 값을 하나*를 묻는다.
							//   ★ 재시도의 **때**(언제 고칠까)와 **내용**(무엇으로 고칠까)을 가르는 자리다.
							//   ⚠️ `6` = **되감기 + 무작위**(D183) — 되감는 판에서도 같은 물음을 던진다.
							if (kBRt[arm] == 2 || kBRt[arm] == 6)
								for (int q = 0; q < nAct; ++q) bpr[q] = 1.0 / (double)nAct;
							if (evalPhase && kBRt[arm] != 2 && kBRt[arm] != 6)
							{
								int nTie2 = 1; bSel = 0;
								for (int q = 1; q < nAct; ++q)
								{
									if (bpr[q] > bpr[bSel]) { bSel = q; nTie2 = 1; }
									else if (bpr[q] == bpr[bSel]) { nTie2++; if (RandInt(0, nTie2) == 0) bSel = q; }
								}
							}
							else
							{
								const double u4 = (double)RandInt(0, 10000) / 10000.0;
								bSel = nAct - 1; double acc4 = 0.0;
								for (int q = 0; q < nAct; ++q) { acc4 += bpr[q]; if (u4 <= acc4) { bSel = q; break; } }
							}
							// 🧩 18-메뉴면 두 번째도 **같은 표**를 쓴다(D156) — 안 그러면 갈아탈 곳이 넷뿐이다.
							const int bMode = (nAct >= kBMx)
								? ((bSel / 6 == 0) ? 4 : ((bSel / 6 == 1) ? 2 : 3))
								: ((bSel == 0) ? 4 : ((bSel == 1) ? 2 : 3));
							// 🔑 **첫 키와 같은 표를 쓴다**(🐛C · D155) — ⛔ 예전엔 넷째(⭐ 고르기 극성)가
							//   **📏 로 떨어졌다** ⇒ 갈아타도 **정답 키에 원리적으로 갈 수 없었다**.
							//   ⚠️ 후보 셋 팔(`nAct == 3`)은 `bSel <= 2` 라 **거동이 한 바이트도 안 바뀐다**(규율 18).
							const int bKey  = (nAct >= kBMx) ? (100 + bSel)
								: ((bSel == 0) ? 2 : ((bSel == 1) ? 7 : ((bSel == 2) ? 5 : 8)));
							// 🔗 짝은 **지금 상태의 프레임**이다 — 첫 후보가 관찰이었으면 세계가 안 움직였으니 `a0`.
							const Blob* pv0 = (aMode == 4) ? a0 : a1;
							const int   pn0 = (aMode == 4) ? n0 : n1;
							Blob a3[8]; int n3 = 0;
							if (bMode == 4)
							{
								if (!_BindProbe(gc, cx, gs, DiOf(2), cell, plane, a3, n3)) continue;
							}
							else
							{
								int ccT2 = cc, csT2 = cs;
								if (bMode == 2) ccT2 = (cc + 1) % nc;
								else            csT2 = (cs < 2) ? (cs + 1) : (cs - 1);
								if (!_BindProbe(ccT2, cx, csT2, DiOf(2), cell, plane, a3, n3)) continue;
								cc = ccT2; cs = csT2; epStep++;   // ⚠️ 갈아타기의 대가
							}
							if (bKey >= 100)
							{
								// 🧩 두 번째도 **통합 규칙**(D156) — 위와 같은 술어다.
								const int cd2 = bKey - 100;
								const int cPol2 = (cd2 / 3) % 2;
								const int cAt2  = cd2 % 3;
								for (int k1 = 0; k1 < pn0 && dvArm < 0; ++k1)
								{
									bool hit2 = false;
									for (int k3 = 0; k3 < n3; ++k3)
									{
										const bool same2 = (cAt2 == 0) ? (pv0[k1].v == a3[k3].v)
											: ((cAt2 == 1) ? (pv0[k1].ink == a3[k3].ink)
											: (pv0[k1].v == a3[k3].v && pv0[k1].ink == a3[k3].ink));
										if (same2) { hit2 = true; break; }
									}
									if (cPol2 == 0)
									{
										if (hit2)
										{
											dvArm = (cAt2 == 1) ? (int)pv0[k1].ink : (int)pv0[k1].v;
											prArm = (cAt2 == 1) ? 5 : 1;
										}
									}
									else if (!hit2) { dvArm = (int)pv0[k1].cx16; prArm = 6; }
								}
							}
							else if (bKey == 8)
							{
								// ⭐ **고르기 극성**(🐛C) — 「잉크가 **변한** 성분이 목표」. 첫 키와 같은 규칙이다.
								for (int k1 = 0; k1 < pn0 && dvArm < 0; ++k1)
								{
									bool moved2 = true;
									for (int k3 = 0; k3 < n3; ++k3)
										if (pv0[k1].ink == a3[k3].ink) { moved2 = false; break; }
									if (moved2) dvArm = (int)pv0[k1].cx16;
								}
								if (dvArm >= 0) prArm = 6;
							}
							else
							{
							for (int k1 = 0; k1 < pn0 && dvArm < 0; ++k1)
								for (int k3 = 0; k3 < n3; ++k3)
								{
									const bool same = (bKey == 5) ? (pv0[k1].ink == a3[k3].ink)
										: ((bKey == 7) ? (pv0[k1].v == a3[k3].v)
										: (pv0[k1].v == a3[k3].v && pv0[k1].ink == a3[k3].ink));
									if (same) { dvArm = (bKey == 5) ? (int)pv0[k1].ink : (int)pv0[k1].v; break; }
								}
							if (dvArm >= 0) prArm = (bKey == 5) ? 5 : 1;
							}
							// ✅ 여기까지 왔으면 이 에피소드는 **세어진다** ⇒ 이제 계수기를 올린다
							//   (앞에서 올리면 `continue` 한 판이 분자에만 남아 비율이 부푼다 · 함정 358 의 그 자리).
							nSw++;
						}
						// ⚡ 프로브가 끝났으니 방해자 변주를 **한 번에** 넘긴다(위 주석의 그 이유).
						dfr += 3;
					}
					if (!_BindRead(gc, cx, gs, DiOf(2), prArm, dvArm, (kBMv[arm] == 0 && dOk) ? (int)dByte : -1,
						cell, plane, gv, gcx, gink, nFrame, nTwo, nMiss, kBKeep[arm] != 0)) continue;
					nEp++;
					bool measDone = false;
					// ⛔ **예산 덤**(D183 · `kBCap`) — 재시도 없이 **걸음만** 늘리는 음성.
					for (int k = 0; k < kCap + kBCap[arm]; ++k)
					{
						uint8 mv = 0; int64 mcx = 0; uint64 mink = 0;
						if (!_BindRead(cc, cx, cs, DiOf(3 + k), prArm, dvArm, (kBMv[arm] == 0 && dOk) ? (int)dByte : -1,
							cell, plane, mv, mcx, mink, nFrame, nTwo, nMiss, kBKeep[arm] != 0)) { nBad++; break; }
						// ★ **측정값으로만** 판단한다 — 그것이 이 판의 요점이다.
						if (mv == gv && mcx == gcx && mink == gink) { measDone = true; break; }
						epStep++;
						if (mv != gv) cc = (cc + 1) % nc;
						else if (mink < gink) { if (cs < 2) cs++; else break; }
						else                  { if (cs > 0) cs--; else break; }
					}
					const bool truth = (cc == gc && cs == gs);
					if (truth) nTrue++;
					if (measDone) nMeas++;
					// ⭐ **거짓 도달** — 측정은 「됐다」인데 진실은 목표가 아니다.
					if (measDone && !truth) nFalse++;
					// 🎯 후보별로 센다(D182) — 첫 선택 `aSel` 이 그 에피소드의 「쓴 후보」다.
					// 🌟 **써 봤다고 센다**(D194) — ⚠️ 여기가 「세어진 에피소드」의 자리다
					//   ⇒ 배관 실패로 버려진 판은 **안 센다**(정보를 못 얻었으니 안 써 본 것이다).
					if (aSel >= 0 && aSel < kBMx) { fbN[aSel]++; nSel[aSel]++; if (measDone && !truth) fbF[aSel]++; }
					// 📋 **상황 x 후보**(D191) — 갈아타기를 끈 팔에서만 뜻이 있다(그래야 `aSel` 이 끝까지 쓰인다).
					if (epSit >= 0 && epSit < 4)
					{
						sitT[epSit]++; if (truth) sitOk[epSit]++;
						if (aSel >= 0 && aSel < kBMx)
						{
							scT[epSit][aSel]++; if (truth) scOk[epSit][aSel]++;
						}
					}
					// ✅ 이 에피소드가 세어졌으므로 걸음도 이제 더한다(위 주석의 그 이유).
					nStep += epStep;
					// 🔗 **끊는다**(D198 · 전이 절차 ①) — 이 상황이 학습 대상이 아니면 **정책을 갱신하지 않는다**.
					//   ★ `concept.md`: *「입력에서만 가리고 학습을 그대로 두면 그것은 「못 쓰게 한 것」이
					//     아니라 「이번에만 결석한 것」이다」* ⇒ 그래서 **갱신을 건너뛴다**(입력은 그대로다).
					//   ⚠️ `continue` 가 아니다 — 에피소드는 **세어지고 채점된다**(평가는 전부 한다).
					const bool lrnOk = (kBLrnSit[arm] < 0) || (epSit == kBLrnSit[arm]);
					// 🎯 **행동 갱신**(D147) — REINFORCE. 기울기는 `one-hot(고른 것) − p` = **대조 갱신**이다
					//   (D144 가 세운 그 모양 · 안 고른 것을 뺀다 ⇒ 상대 순위가 움직인다).
					if (kBPr[arm] >= 8)
					{
						lEp[half]++;
						if (truth) lTrue[half]++;
						if (measDone && !truth) lFalse[half]++;
						const double lr3 = kBndLr[arm];
						// 💰 **보상에 걸음을 싣는다**(D157 · 함정 372 의 직접 처방) — `kBCst` 가 0 이면 옛 보상 그대로다.
						//   ⚠️⚠️ **왜 필요한가**: D156 이 100%% 후보 **셋**(🧩05·16·17)을 드러냈는데 05 는 걸음 **1.92**,
						//     16 은 **3.09** 다. 그런데 보상이 **도달만** 보므로 셋은 학습기에게 **구별 불가능**하다
						//     ⇒ 「더 싼 것을 고른다」는 **학습기에게 존재하지 않는 성질**이었다.
						//   ★ 벌은 **항상** 붙인다(성공했을 때만 붙이면 「실패는 공짜」가 되어 뜻이 흐려진다).
						//   ⚠️ 크게 주면 **「관찰만 하고 안 움직인다」로 무너질 수 있고 그 무너짐도 정보**다 ⇒ 곡선으로 잰다.
						const double r3 = (truth ? 1.0 : 0.0) - kBCst[arm] * (double)epStep;
						const int sb3 = (kBndSb[arm] != 0) ? (int)(t & 1) : 0;
						// 🔗 `lrnOk` 가 여기 붙는다(D198) — **채점(`lEp`/`lTrue`)은 위에서 이미 다 했고**
						//   끊는 것은 **정책 갱신뿐**이다. ⚠️ 위 블록에 걸면 평가까지 스킵되어 설계가 깨진다.
						if (lr3 > 0.0 && !evalPhase && aSel >= 0 && lrnOk)
						{
							const double adv3 = r3 - lbase[sb3];
							// 🩹 **「구제가 압력을 먹는다」의 처방**(D156) — `c₁ = 0` 이면 **갈아탄 판**에서
							//   **첫 결정**의 보상을 **0**(실패)으로 친다. 뜻이 맞다: 갈아탔다는 것 자체가
							//   *"첫 키가 못 믿을 것이었다"* 는 세계의 대답이고 성공은 **두 번째** 덕이다.
							//   ⚠️ D155 실측이 부른 처방이다 — 방아쇠도 갈아타기 표도 옳았는데 **첫 선호가
							//     덜 뾰족해져**(⭐ 2.677 ↔ 3.238) 이득이 **+0.4%p** 에 그쳤다.
							//   ⚠️ 두 번째 결정(`aw2`)의 보상은 **안 건드린다** — 그쪽은 실제로 성공을 만든 결정이다.
							// 🧠 **적응 `c₁`**(D163) — `kBAd` 가 0 이 아니면 상수 대신 **배운 값**을 쓴다.
							//   ⚠️ 표본이 적을 땐 **초기값**을 쓴다(비율이 잡음뿐인 구간).
							//   ⚠️ 초기값을 **N−1 로 둘** 둔다: `1` = 중립 0.5 · `2` = **격자 최고값 0.0**
							//     ⇒ 「적응이 이긴 것이 초기값 덕인가」를 그 둘이 가른다.
							double c1 = kBFc[arm];
							if (kBAd[arm] != 0 && aSel >= 0)
							{
								if (nSw < 30) c1 = (kBAd[arm] == 2) ? 0.0 : 0.5;
								else
								{
									const double rr = (swAll > 1e-9) ? (swR[aSel] / swAll) : 1.0;
									c1 = (kBAd[arm] == 3) ? rr : (1.0 - rr);   // ⚠️ 3 = 음성(뒤집음)
									if (c1 < -1.0) c1 = -1.0; else if (c1 > 1.0) c1 = 1.0;
								}
							}
							const double adv1 = (bSel >= 0) ? (c1 * r3 - lbase[sb3]) : adv3;
							// 🎯 **희소 갱신**(D164 · **㉡ 의 원래 정의** = *흔드는 범위가 참여한 경로로 좁혀진다*).
							//   `kBK` : `0` = **전부**(옛것 · 대조 갱신) · `k>0` = **k 칸만**(고른 것 + 무작위 k−1) ·
							//   `<0` = ⚠️ **음성**(고른 것을 **빼고** 나머지만 = *참여 안 한 것만 흔든다*).
							//   ★ 재료는 D91~D96 이 세웠다 — **`k=1` 일 때만 보호가 된다**(단조가 아니라 **계단**) 그리고
							//     **보호의 값은 묶음 수에 비례한다**(D94 · 묶음 8 에서 **+12.4%p**). ⇒ 후보 **18개**인 지금이 그 시험이다.
							//   ⚠️ `kBK <= 1` 인 팔은 `RandInt` 를 **안 부른다** ⇒ 옛 팔의 난수 스트림이 안 흔들린다.
							if (aCtx >= 0 && aCtx < 32) awN[aCtx]++;   // 🩺 칸별 표본(D178)
							bool upd[kBMx];
							const int kk = kBK[arm];
							if (kk == 0)     { for (int q = 0; q < nAct; ++q) upd[q] = true; }
							else if (kk < 0) { for (int q = 0; q < nAct; ++q) upd[q] = (q != aSel); }
							else
							{
								for (int q = 0; q < nAct; ++q) upd[q] = false;
								upd[aSel] = true;
								for (int j = 1; j < kk; ++j) upd[RandInt(0, nAct)] = true;
							}
							for (int q = 0; q < nAct; ++q)
								// 🤝 **공통과 보정을 같이 민다**(D186) — 배율이 갈림의 속도를 정한다.
								if (upd[q])
								{
									const double g1 = lr3 * adv1 * (((q == aSel) ? 1.0 : 0.0) - apr[q]);
									aw0[q] += shC * g1;
									aw[aCtx][q] += shD * g1;
								}
							// 🧬 **관측 선택도 같은 보상으로** 갱신한다(한 궤적의 또 하나의 결정 · D172).
							// 🔬 **관측 선택의 보상**(D173) — `8` = 도달률(D172 · **죽은 관측에 굳었다**) ·
							//   `10` = ⭐ **갈림** · `11` = ⚠️ **뒤집은 갈림**(음성) · `12` = 🎲 도달률인데 **학습률 1/5**
							//   (탐험 유지 — 「범인이 보상인가 수렴 속도인가」를 그 둘이 가른다).
							if (oSel >= 0 && kBCtx[arm] >= 8 && kBCtx[arm] != 9 && kBCtx[arm] != 14 && kBCtx[arm] != 16
								&& !(kBCtx[arm] >= 20 && nEp < 300))   // ⏳ 초반엔 위층을 안 배운다
							{
								double advO = adv1; double lrO = lr3;
								// 🔬🎯 **갈림 보상 x 하나만 살아**(D176) — `17` = 갈림 · `18` = ⚠️ 뒤집은 갈림(음성).
								//   ★ D173 의 갈림 보상이 실패한 이유는 *살아있는 셋이 다 양수라 하나로 안 굳었다*
								//     인데, **지금 세계는 살아있는 것이 하나**라 **흔들릴 데가 없다**.
								//   ★ 그리고 **갈림은 `aw` 와 무관하게 계산된다** ⇒ **닭과 달걀(규율 47)이 원리적으로 없다**.
								//   ⚠️ 탐험 유지(`lr/5`)도 **같이** 켠다 — D173 이 그것을 필요조건으로 보였다.
								if (kBCtx[arm] == 10 || kBCtx[arm] == 11 || kBCtx[arm] >= 17)
								{
									const double spl = 4.0 * obm[oSel] * (1.0 - obm[oSel]);
									const bool inv = (kBCtx[arm] == 11 || kBCtx[arm] == 18);
									advO = inv ? (obase - spl) : (spl - obase);
									obase += 0.01 * (spl - obase);
									if (kBCtx[arm] >= 17) lrO = lr3 * 0.2;
								}
								// 🎲 **탐험 유지가 기본이 됐다**(D173 이 그것을 필요조건으로 보였다) — `12`·`13` 이 쓴다.
								else if (kBCtx[arm] >= 12) lrO = lr3 * 0.2;   // 🎲 탐험 유지가 기본(D173)
								for (int q = 0; q < ((kBCtx[arm] == 13 || kBCtx[arm] == 14) ? 8 : 4); ++q)
									ow[owS][q] += lrO * advO * (((q == oSel) ? 1.0 : 0.0) - opr[q]);
							}
							// 🔄 **두 번째 결정도 같은 보상으로** 갱신한다(한 궤적의 두 결정 · REINFORCE).
							if (bSel >= 0)
								for (int q = 0; q < nAct; ++q)
									aw2[bCtx][q] += lr3 * adv3 * (((q == bSel) ? 1.0 : 0.0) - bpr[q]);   // 🧭 같은 문맥 칸에
						}
						lbase[sb3] += 0.01 * (r3 - lbase[sb3]);
						// 🧠 **갈아타기율을 후보별로 센다**(D163) — 「책임 귀속」의 재료다.
						//   ⚠️ **갈아탔든 아니든** 매 에피소드 갱신한다(비율이어야 하므로 분모가 필요하다).
						//   ⚠️ 눈금은 `lbase` 와 같은 0.01 이다(같은 종류의 러닝 평균이라 맞춘다).
						if (kBAd[arm] != 0 && aSel >= 0)
						{
							const double sw1 = (bSel >= 0) ? 1.0 : 0.0;
							swR[aSel] += 0.01 * (sw1 - swR[aSel]);
							swAll     += 0.01 * (sw1 - swAll);
						}
					}
				}
			}
			const double pc = (nEp > 0) ? 100.0 / (double)nEp : 0.0;
			const double pf = (nFrame > 0) ? 100.0 / (double)nFrame : 0.0;
			LogA("[ml]   %s — 진짜 도달 **%.1f%%** │ 측정 도달 %.1f%% │ ⭐ **거짓 도달 %.1f%%**"
				"  ‖  🔬 걸음 **%.2f** · 성분≥2 %.1f%% · 📏 **성분수 %.2f** · 묶임실패 **%.1f%%**%s · **에피소드 %d** · 프레임 %d · 배관실패 %d\n",
				kBN[arm], (double)nTrue * pc, (double)nMeas * pc, (double)nFalse * pc,
				(nEp > 0) ? ((double)nStep / (double)nEp) : 0.0,
				(double)nTwo * pf,
				(nFrame > 0) ? ((double)gNComp / (double)nFrame) : 0.0,
				(double)nMiss * pf,
				// 📏 **함정 357 의 처방** — 못 세는 자리에 **깃발**을 단다. ⚠️ ⚡ 팔은 방해자 색이
				//   **하나가 아니므로** 「`bl[0]` 이 방해자인가」가 **성립하지 않는다** ⇒ `0.0%` 를
				//   「실패가 없다」와 **구별할 수 없게** 된다(실측으로 그 혼동을 밟았다).
				(kBMv[arm] != 0) ? " ⚠️(정의 안 됨)" : "",
				nEp, nFrame, nBad);
			// 🧠 학습 팔은 **전반/후반**과 **가중치**를 더 찍는다 — 「배웠나」는 곡선이 말한다.
			if (kBPr[arm] == 7)
				LogA("[ml]      🧠 전반 진짜 %.1f%% · 거짓 %.1f%%(ep %d) │ 후반 진짜 %.1f%% ·"
					" 거짓 %.1f%%(ep %d) │ w = [%.3f %.3f %.3f] · 기준선 [%.3f %.3f]\n",
					(lEp[0] > 0) ? (100.0 * (double)lTrue[0] / (double)lEp[0]) : 0.0,
					(lEp[0] > 0) ? (100.0 * (double)lFalse[0] / (double)lEp[0]) : 0.0, lEp[0],
					(lEp[1] > 0) ? (100.0 * (double)lTrue[1] / (double)lEp[1]) : 0.0,
					(lEp[1] > 0) ? (100.0 * (double)lFalse[1] / (double)lEp[1]) : 0.0, lEp[1],
					lw[0], lw[1], lw[2], lbase[0], lbase[1]);
			// 🔀 **물려줄 것을 남긴다**(D151) — ⚠️ **팔 순서에 의존**한다(주는 팔이 받는 팔보다 먼저 돈다).
			//   ⛔⛔ 예전엔 이 자리가 **조건식**이었고 **Ⓔ 도 만족해서 ㈕ 를 덮었다**(🐛B · D155)
			//     ⇒ 「다른 판(㉯)」이라고 적은 것이 실제로는 **같은 판(㉮)**이었다.
			//   ⇒ ★ 이제 **팔 표**가 말한다: `1` = 🎭 다른 판(㈕) · `2` = ⭐ 같은 판(Ⓔ).
			if (kBDon[arm] == 1)
			{
				for (int q = 0; q < 3; ++q) gSeedW[q] = aw[0][q];
				for (int q = 0; q < nAct; ++q)
					for (int r = 0; r < 3; ++r) gSeedW2[q][r] = aw2[q][r];
				gSeedOk = true;
			}
			else if (kBDon[arm] == 2)
			{
				for (int q = 0; q < 3; ++q) gSeedS[q] = aw[0][q];
				for (int q = 0; q < nAct; ++q)
					for (int r = 0; r < 3; ++r) gSeedS2[q][r] = aw2[q][r];
				gSeedSOk = true;
			}
			// 🔔 **무작위 방아쇠의 발화율을 남긴다**(D155) — 🔔 팔이 실제로 몇 % 당겼나.
			//   ★ N−1 대조군이 **같은 비율**로 당겨야 「몇 번 다시 골랐나」가 섞이지 않는다.
			if (kBTg[arm] == 1 && nEp > 0)
				{ gTgRate = (int)(10000.0 * (double)nTg / (double)nEp); gTgOk = true; }
			// 🎯 행동 팔은 **선호 셋**을 찍는다 — 「무엇을 해 보기로 했나」가 그 줄이다.
			if (kBPr[arm] >= 8)
				LogA("[ml]      🎯 전반 진짜 %.1f%%(ep %d) │ 후반 진짜 %.1f%% · 거짓 %.1f%%(ep %d) │"
					" 선호 = [🔎 %.3f · 🎨 %.3f · 📏 %.3f · ⭐ %.3f] · 기준선 [%.3f %.3f]\n",
					(lEp[0] > 0) ? (100.0 * (double)lTrue[0] / (double)lEp[0]) : 0.0, lEp[0],
					(lEp[1] > 0) ? (100.0 * (double)lTrue[1] / (double)lEp[1]) : 0.0,
					(lEp[1] > 0) ? (100.0 * (double)lFalse[1] / (double)lEp[1]) : 0.0, lEp[1],
					aw[0][0], aw[0][1], aw[0][2], aw[0][3], lbase[0], lbase[1]);
			// 🧩 **18-메뉴는 선호를 따로 찍는다**(D156) — 「무엇을 골랐나」가 이 판의 판정이다.
			//   ★ argmax 와 함께 **손 메뉴 넷**(02·06·13·16)과 ⭐ **17**(사람이 안 적은 정답)을 나란히 둔다.
			if (nAct >= kBMx)
			{
				int bq = 0;
				for (int q = 1; q < nAct; ++q) if (aw[0][q] > aw[0][bq]) bq = q;
				LogA("[ml]      🧩 argmax = **%s(%02d)** %.3f │ 손 메뉴 [02 %.2f · 06 %.2f · 13 %.2f · 16 %.2f]"
					" │ ⭐**17 %.2f** │ 최고 셋 밖 = %s\n",
					_CandSym(bq), bq, aw[0][bq], aw[0][2], aw[0][6], aw[0][13], aw[0][16], aw[0][17],
					(bq == 2 || bq == 6 || bq == 13 || bq == 16) ? "아니다(손 메뉴 안)" : "**그렇다**");
			}
			// 🧠 **적응 `c₁` 이 정말 후보별로 갈렸나**(D163 ㊡) — 안 갈렸으면 「배웠다」가 아니라
			//   **상수 하나를 다르게 쓴 것**이다(D95 의 λ 가 그 자리였다). ⇒ **분포를 찍는다**.
			if (kBAd[arm] != 0 && nAct >= kBMx)
			{
				int bq = 0;
				for (int q = 1; q < nAct; ++q) if (aw[0][q] > aw[0][bq]) bq = q;
				// 🔧 **전반 끝 스냅샷을 읽는다**(규율 35) — 팔 끝의 값은 학습이 끝난 뒤라 딴판이다.
				const double* sR = snapOk ? swRs : swR;
				const double  sA = snapOk ? swAllS : swAll;
				double lo = 9.0, hi = -9.0, sum = 0.0;
				for (int q = 0; q < nAct; ++q)
				{
					const double rr = (sA > 1e-9) ? (sR[q] / sA) : 1.0;
					double cv = (kBAd[arm] == 3) ? rr : (1.0 - rr);
					if (cv < -1.0) cv = -1.0; else if (cv > 1.0) cv = 1.0;
					if (cv < lo) lo = cv;
					if (cv > hi) hi = cv;
					sum += cv;
				}
				const double rb = (sA > 1e-9) ? (sR[bq] / sA) : 1.0;
				double cb = (kBAd[arm] == 3) ? rb : (1.0 - rb);
				if (cb < -1.0) cb = -1.0; else if (cb > 1.0) cb = 1.0;
				LogA("[ml]      🧠 적응 c₁(**전반 끝**) — **argmax %s = %.2f** │ 폭 %.2f ~ %.2f(**%.2f**) ·"
					" 평균 %.2f │ 갈아타기율 전체 **%.3f**%s\n",
					_CandSym(bq), cb, lo, hi, hi - lo, sum / (double)nAct, sA,
					snapOk ? "" : " ⚠️(스냅샷 없음 — 팔 끝 값이다)");
			}
			// 🧭 **문맥이 정말 갈렸나**(D167 ㊧ · 작동 판정) — 관측 문맥(`rb`)을 쓰는 팔은
			//   **문맥 칸마다 argmax 가 달라야** 한다. 같으면 「담을 자리를 줬는데 안 썼다」이고
			//   ⇒ 성능 판정은 **판정불가**다(규율 3 ㉢ — 기제가 발화했나).
			if (kBCtx[arm] == 1 || kBCtx[arm] == 3)
				LogA("[ml]      🧭 문맥별 두 번째 선택 — 좁힘0 → **%s** · 좁힘1 → **%s** · 좁힘2+ → **%s**%s\n",
					_SwSym(aw2[0], nAct), _SwSym(aw2[1], nAct), _SwSym(aw2[2], nAct),
					(kBCtx[arm] == 3) ? "  ⚠️(무작위 문맥 = 음성)" : "");
			// 🔎 **관측 문맥 넷**(D168) — `0` 안 변함 · `1` **색이 변한다**(🎨) · `2` **잉크가 변한다**(📏) · `3` 둘 다.
			//   ★ 손 예측: 🎨 세계는 `1`, 📏 세계는 `2` 만 쓰인다 ⇒ **1 과 2 가 둘 다 살아 있어야** 문맥이 산 것이다.
			// 🔎 **문맥별 첫 선택**(D169 ㊭ · 작동 판정) — 이것이 갈려야 문맥이 **모든 판에서** 산다.
			//   ★ 손 예측(D166 실측): 🎨 세계는 **📏➕i(16)**(100.0%) · 📏 세계는 **📏➖i(13)**(79.0%)
			// 🧬 **어느 관측을 골랐나**(D172 ㊳ · 작동 판정) — argmax 가 **색 또는 잉크**여야 한다.
			//   ⚠️ `색또는잉크`(늘 1)와 `자리`(늘 0)는 **상수라 못 가른다** ⇒ 그리로 가면 문맥이 죽는다(D167).
			if (kBCtx[arm] >= 8)
			{
				static const char* kON[8] = { "🎨색", "📏잉크", "🔀색or잉크", "📍자리",
					"🪦늘1", "🪦늘0", "🪦색and잉크", "🪦자리≠잉크" };
				static const int kOP[4] = { 0, 4, 5, 6 };
				static const int kOP3[4] = { 0, 1, 3, 4 };
				const int nO = (kBCtx[arm] == 13 || kBCtx[arm] == 14) ? 8 : 4;
				int ob = 0;
				for (int q = 1; q < nO; ++q) if (ow[0][q] > ow[0][ob]) ob = q;   // 🧬 로그는 늘 0 줄
				int nLive = 0;
				for (int q = 0; q < nO; ++q) if (4.0 * obm[q] * (1.0 - obm[q]) > 0.5) nLive++;
				LogA("[ml]      🧬 **어느 관측을 볼까** — argmax = **%s** │ ow = [🎨 %.2f · 📏 %.2f ·"
					" 🔀 %.2f · 📍 %.2f] │ 🔬 갈림 = [%.2f · %.2f · %.2f · %.2f]%s\n",
					kON[(kBCtx[arm] == 21) ? kOP3[ob] : ((kBCtx[arm] >= 15) ? kOP[ob] : ob)],
					ow[0][0], ow[0][1], ow[0][2], ow[0][3],
					4.0 * obm[0] * (1.0 - obm[0]), 4.0 * obm[1] * (1.0 - obm[1]),
					4.0 * obm[2] * (1.0 - obm[2]), 4.0 * obm[3] * (1.0 - obm[3]),
					(kBCtx[arm] == 9 || kBCtx[arm] == 14 || kBCtx[arm] == 16) ? "  ⚠️(무작위 = 음성)" : "");
				LogA("[ml]      🪦 관측 후보 **%d** 개 중 **살아있는 것 %d** 개 · argmax 는 %s\n",
					nO, nLive, (4.0 * obm[ob] * (1.0 - obm[ob]) > 0.5) ? "**살아있다** ⭐" : "⛔ **죽었다**");
				LogA("[ml]      🧬 관측x비트별 첫 선택 — 🎨0 **%s** 🎨1 **%s** │ 📏0 **%s** 📏1 **%s** │"
					" 🔀0 **%s** 🔀1 **%s** │ 📍0 **%s** 📍1 **%s**\n",
					_SwSym(aw[0], nAct), _SwSym(aw[1], nAct), _SwSym(aw[2], nAct), _SwSym(aw[3], nAct),
					_SwSym(aw[4], nAct), _SwSym(aw[5], nAct), _SwSym(aw[6], nAct), _SwSym(aw[7], nAct));
			}
			// 🩺 **아래층 계기판**(D178 · 규율 48) — 칸마다 **무엇을 골랐고 몇 판을 받았나**.
			//   ★ D177 심사가 「안 봤다」로 센 셋 중 둘이 이것이다.
			if (kBCf[arm] != 0)
			{
				LogA("[ml]      🎯 **후보별 거짓 도달** — ");
				for (int q = 0; q < kBMx; ++q)
					if (fbN[q] >= 30)
						LogA("%s **%.0f%%**(n=%d)  ", _CandSym(q), 100.0 * fbF[q] / fbN[q], fbN[q]);
				LogA("\n");
				// ⚠️ **라벨 버그 수정**(D180 에서 `nSit == 2` 를 몰라 이름만 틀리게 찍었다 — 값은 맞았다).
				static const char* kSn4[4] = { "🎨A색", "📏A크기", "📍A자리", "🧨B크기" };
				static const char* kSn2[4] = { "📏A크기", "🧨B크기", "-", "-" };
				static const char* kSn3[4] = { "📍A자리", "🧨B크기", "-", "-" };
				const char* const* kSn = (kBCf[arm] == 2) ? kSn2
					: ((kBCf[arm] == 3) ? kSn3 : kSn4);
				LogA("[ml]      🧨 **관측 서명**(상황별 `oVC oIC oPC` %%) — ");
				for (int q = 0; q < 4; ++q)
					if (sigT[q] > 0)
						LogA("%s **[%.0f %.0f %.0f]**(n=%d)  ", kSn[q],
							100.0 * sigN[q][0] / sigT[q], 100.0 * sigN[q][1] / sigT[q],
							100.0 * sigN[q][2] / sigT[q], sigT[q]);
				LogA("\n");
			}
			if (kBCtx[arm] >= 15)
			{
				const int nc2 = (kBCtx[arm] == 19) ? 2 : 8;
				LogA("[ml]      🩺 아래층 칸 **%d** 개 — 0:%s(%d) 1:%s(%d) 2:%s(%d) 3:%s(%d)%s\n", nc2,
					_SwSym(aw[0], nAct), awN[0], _SwSym(aw[1], nAct), awN[1],
					_SwSym(aw[2], nAct), awN[2], _SwSym(aw[3], nAct), awN[3],
					(nc2 == 2) ? "  ⭐(칸 둘 — 2·3 은 안 쓴다)" : "");
			}
			if (kBCtx[arm] >= 6 && kBCtx[arm] <= 7)
				LogA("[ml]      🔎 **문맥별 첫 선택** — 안변함 → **%s** · 🎨색 → **%s** · 📏잉크 → **%s** ·"
					" 둘다 → **%s**%s\n",
					_SwSym(aw[0], nAct), _SwSym(aw[1], nAct), _SwSym(aw[2], nAct), _SwSym(aw[3], nAct),
					(kBCtx[arm] == 7) ? "  ⚠️(무작위 문맥 = 음성 · 걸음은 같다)" : "");
			if (kBCtx[arm] >= 4 && kBCtx[arm] <= 5)
				LogA("[ml]      🔎 관측 문맥별 두 번째 — 안변함 → **%s** · 🎨색 → **%s** · 📏잉크 → **%s** ·"
					" 둘다 → **%s**%s\n",
					_SwSym(aw2[0], nAct), _SwSym(aw2[1], nAct), _SwSym(aw2[2], nAct), _SwSym(aw2[3], nAct),
					(kBCtx[arm] == 5) ? "  ⚠️(무작위 문맥 = 음성 · 걸음은 같다)" : "");
			if (kBSw[arm] != 0)
				LogA("[ml]      🔔 방아쇠 **%d** (%.1f%%) │ 🔄 갈아탄 판 **%d** (%.1f%%) │ 표: 🔎→%s · 🎨→%s · 📏→%s · ⭐→%s\n",
						nTg, (nEp > 0) ? (100.0 * (double)nTg / (double)nEp) : 0.0,
						nSw, (nEp > 0) ? (100.0 * (double)nSw / (double)nEp) : 0.0,
						_SwSym(aw2[0], nAct), _SwSym(aw2[1], nAct), _SwSym(aw2[2], nAct),
						_SwSym(aw2[3], nAct));
			// 🤝 **로그 직전에 공통을 칸에 합친다**(D186) — 안 그러면 계기판이 **보정만** 보여
			//   「칸이 다 같다」로 잘못 읽힌다(규율 48: 계기가 거짓말하면 규율이 안 걸린다).
			if (kBShr[arm] != 0)
				for (int c2 = 0; c2 < 32; ++c2)
					for (int q = 0; q < nAct; ++q) aw[c2][q] += aw0[q];
			// 🧱 **이 반복의 평가 성적을 담는다**(D185) — 평가 구간 = `sd >= kSd/2` 인 절반.
			if (rep < 16) repEv[rep] = (lEp[1] > 0) ? (100.0 * (double)lTrue[1] / (double)lEp[1]) : 0.0;
			}   // 🧱 반복 루프 끝
			// 📋 **상황별 성적**(D191) — 학습 팔의 「어느 상황에서 무너지나」.
			if (kBCf[arm] != 0 || kBMix[arm] != 0)
			{
				static const char* kS4[4] = { "🎨A색", "📏A크기", "📍A자리", "🧨B크기" };
				LogA("[ml]      📋 **상황별 성적** — ");
				for (int q = 0; q < 4; ++q)
					if (sitT[q] > 0)
						LogA("%s **%.1f%%**(n=%d)  ", kS4[q], 100.0 * sitOk[q] / sitT[q], sitT[q]);
				LogA("\n");
			}
			// 📋 **상황 x 후보 성적표**(D191 · 규율 66) — **행마다 최적 후보**를 읽는 자리다.
			if (kBTbl[arm] != 0)
			{
				static const char* kS4b[4] = { "🎨A색  ", "📏A크기", "📍A자리", "🧨B크기" };
				for (int q = 0; q < 4; ++q)
				{
					if (scT[q][0] + scT[q][1] + scT[q][2] <= 0 && scT[q][3] <= 0) continue;
					int bq2 = -1; double bv2 = -1.0;
					LogA("[ml]      📋 %s │", kS4b[q]);
					// ⚠️ `nAct` 는 **반복 루프 안**에 있다(여기는 밖) ⇒ 축을 직접 본다.
					for (int k2 = 0; k2 < kBNA[arm]; ++k2)
					{
						if (scT[q][k2] < 10) { LogA(" %s  --  ", _CandSym(k2)); continue; }
						const double r2 = 100.0 * scOk[q][k2] / scT[q][k2];
						if (r2 > bv2) { bv2 = r2; bq2 = k2; }
						LogA(" %s %3.0f", _CandSym(k2), r2);
					}
					// 🧱 **그 세계의 균등 바닥**(D202 · 규율 75) — 표를 냈으면 **바닥도 같이** 낸다.
					//   ⚠️ D198~D200 이 이 값을 **기억에서** 꺼냈고 그것이 **다른 세계의 값**이었다(규율 74).
					double bsum2 = 0.0; int bn2 = 0;
					for (int k3 = 0; k3 < kBNA[arm]; ++k3)
						if (scT[q][k3] >= 10) { bsum2 += 100.0 * scOk[q][k3] / scT[q][k3]; bn2++; }
					LogA("  ⇒ ⭐ **%s %.0f%%**(n=%d) │ 🧱 **바닥 %.1f%%**(균등 · 후보 %d)\n",
						(bq2 >= 0) ? _CandSym(bq2) : "?", (bq2 >= 0) ? bv2 : 0.0,
						(bq2 >= 0) ? scT[q][bq2] : 0,
						(bn2 > 0) ? (bsum2 / (double)bn2) : 0.0, bn2);
				}
			}
			// 🧱 **평균 ± σ**(D185 · 규율 59) — **이 한 줄이 이제 그 팔의 값**이다.
			//   ⚠️ 반복이 하나면 σ 를 못 내므로 안 찍는다(옛 팔은 그대로다).
			if (nRep >= 2)
			{
				double mu = 0.0;
				for (int q = 0; q < nRep && q < 16; ++q) mu += repEv[q];
				mu /= (double)((nRep < 16) ? nRep : 16);
				double vv = 0.0;
				for (int q = 0; q < nRep && q < 16; ++q) vv += (repEv[q] - mu) * (repEv[q] - mu);
				const int nn = (nRep < 16) ? nRep : 16;
				const double sg2 = (nn >= 2) ? Sqrt((float)(vv / (double)(nn - 1))) : 0.0;
				LogA("[ml]      🧱 **씨앗 %d 개** — 평균 **%.1f%%** · σ **%.2f%%p** · SE %.2f │ 값:",
					nn, mu, sg2, (nn >= 2) ? (sg2 / Sqrt((float)nn)) : 0.0);
				for (int q = 0; q < nn; ++q) LogA(" %.1f", repEv[q]);
				LogA("\n");
			}
		}
		// 🏁 끝 표지(함정 342) — ⚠️ 공백 없음(함정 343).
		LogA("[ml] 🏁 BINDDONE\n");
	}
	
	// 🔗 프레임 하나를 그려 **한 성분**을 고른다(D137).
	//   `pair == 0` ⇒ **`bl[0]`**(지금 코드가 하는 것) · `pair == 1` ⇒ **방해자 값이 아닌 성분**
	//   (🔭 오라클 — 우리가 방해자를 안다). ⚠️ **상한을 재는 자**이고 학습기가 아니다.
	//   ★ 눈금도 센다: 성분이 둘인 프레임 · `bl[0]` 이 방해자인 프레임(= **묶임 실패**).
	//   ⚠️ `dv < 0` 이면 방해자 값을 모른다 ⇒ 짝짓기를 **하지 않는다**(조용히 틀리게 고르지 않는다).
	// 🔬 프레임 하나의 **성분 전부**를 준다(D138) — 시험 팔이 「무엇이 안 변했나」를 보려면
	//   한 성분만으로는 안 된다. ⚠️ 읽기만 한다(눈금을 안 센다 — 시험은 판정 대상이 아니다).
	// 🔀 **물려줄 가중치**(D151) — 한 실행 안에서 앞 팔이 남기고 뒤 팔이 받는다.
	// 🔀 **물려줄 가중치**(D151) + 📏 **세계의 서명**(D153).
	// 📏 **성분 수 합**(D153) — 「세계가 정말 바뀌었나」를 **성능보다 먼저** 말한다.
	//   ⚠️ `_BindRead` 도 세야 해서 멤버다(팔마다 0 으로 되돌린다).
	int64 gNComp = 0;
	// 🔀 물려줄 가중치 — ⛔⛔ **여기가 🐛A 였다**(D155): 소비자 `aw2` 는 **`[4][4]`** 인데 이것이
	//   **`[3][3]`** 이었고 복사 루프가 `q < nAct`(= 후보 넷 팔에서 **4**)라 **배열 밖에 쓰고 읽었다**(UB).
	//   ⚠️ 바로 뒤가 `gSeedOk` 다 ⇒ 그 판정 깃발을 쓰레기로 덮고 있었다. **컴파일도 완주도 정상**이었다.
	//   ⇒ ★ 크기를 **소비자와 같게** 맞춘다. 물려주는 칸이 앞 셋인 것은 **설계**라 그대로다
	//     (넷째 = 새 판의 답이라 **안 준다** — 그것이 D153 의 「무엇이 전이됐나」의 전제다).
	double gSeedW[4] = {};
	double gSeedW2[4][4] = {};
	bool gSeedOk = false;
	// ⭐ **같은 판**(Ⓔ)에서 물려주는 두 번째 슬롯 — ㉮ ↔ ㉯ 를 **같은 실행에서** 가르려면 슬롯이 둘이어야 한다.
	double gSeedS[4] = {};
	double gSeedS2[4][4] = {};
	bool gSeedSOk = false;
	// 🔔 🔔 방아쇠의 **발화율**(만분율) — 🎲 무작위 대조군이 **같은 비율**로 당기게 한다.
	//   ⚠️ 팔 순서에 의존한다(Ⓞ 가 Ⓟ 보다 먼저 돈다) — `kBTg`/`kBDon` 과 같은 관용구다.
	int gTgRate = 0;
	bool gTgOk = false;
	
	// 🔣 갈아타기 표 한 칸을 사람이 읽게 옮긴다.
	//   ⚠️⚠️ **셋이 같으면 「균등」이다** — argmax 를 찍으면 아무것도 안 배운 팔이
	//     **배운 것처럼 보인다**(함정 357 계열: 정의 안 된 값이 값처럼 찍히는 자리).
	static const char* _SwSym(const double* v, int n)
	{
		bool flat = true;
		for (int q = 1; q < n; ++q) if (v[q] != v[0]) { flat = false; break; }
		if (flat) return "균등";
		int b = 0;
		for (int q = 1; q < n; ++q) if (v[q] > v[b]) b = q;
		if (n >= 18) return _CandSym(b);   // 🧩 18-메뉴(D156)
		static const char* kSym[4] = { "🔎", "🎨", "📏", "⭐" };
		return kSym[b];
	}

	// 🧩 **후보 하나의 이름**(D156) — `행동*6 + 극성*3 + 속성`.
	//   행동 🔎 관찰 · 🎨 색 · 📏 크기 │ 극성 ➖ 빼기 · ➕ 고르기 │ 속성 v 값 · i 잉크 · b 값＆잉크.
	//   ★ 손 메뉴 넷 = **02 · 06 · 13 · 16** 이고 ⭐ **17 은 사람이 안 적은 정답 후보**다.
	static const char* _CandSym(int c)
	{
		static const char* kS[18] = {
			"🔎➖v", "🔎➖i", "🔎➖b", "🔎➕v", "🔎➕i", "🔎➕b",
			"🎨➖v", "🎨➖i", "🎨➖b", "🎨➕v", "🎨➕i", "🎨➕b",
			"📏➖v", "📏➖i", "📏➖b", "📏➕v", "📏➕i", "📏➕b" };
		return (c >= 0 && c < 18) ? kS[c] : "??";
	}
	
	
	bool _BindProbe(int ci, int xi, int si, int di, int cell, uint64 plane,
		Blob* out, int& outN)
	{
		outN = 0;
		DrawProgram pr;
		const String src = MLEpisodeGen::TaskCode(ci, xi, si, 0, di);
		if (!pr.Compile(src.View(), (uint32)cell, (uint32)cell, NameID("Bp"))) return false;
		if (!pr.RunStart()) return false;
		Bytes b; b.Reset(plane);
		if (!ImageFormat::PackRGB332Delta(pr.canvas, nullptr, (uint8*)b.GetData(), plane)) return false;
		const uint8* p = (const uint8*)b.GetData();
		outN = _Blobs(p, cell, _BgByte(p, plane), out, 8);
		return (outN >= 1);
	}
	
	// ⚖️ **`keep`**(D160 · 함정 375 의 처방) — 키가 가리킨 것이 **그 프레임에 없을 때** 어떻게 하나.
	//   `false`(옛것) = **실패로 돌려보낸다** ⇒ 호출부가 그 에피소드를 **통째로 버린다**
	//     ⇒ 🚨 **분모가 줄어 도달률이 부풀려진다**(D159 가 실측으로 밟았다: 1800 → 900 · 0).
	//   `true` = **폴백으로 산다**(`bl[0]`) ⇒ 그 판이 **세어지고**, 틀리면 **틀린 것으로 세어진다**.
	//   ★ 「조용히 틀리게 고르지 않고 옛 규칙으로 돌아간다」는 이 저장소의 기존 관용구 그대로다.
	bool _BindRead(int ci, int xi, int si, int di, int pair, int dv, int dvG,
		int cell, uint64 plane, uint8& outV, int64& outCx, uint64& outInk,
		int& nFrame, int& nTwo, int& nMiss, bool keep = false)
	{
		DrawProgram pr;
		const String src = MLEpisodeGen::TaskCode(ci, xi, si, 0, di);
		if (!pr.Compile(src.View(), (uint32)cell, (uint32)cell, NameID("Bd"))) return false;
		if (!pr.RunStart()) return false;
		Bytes b; b.Reset(plane);
		if (!ImageFormat::PackRGB332Delta(pr.canvas, nullptr, (uint8*)b.GetData(), plane)) return false;
		const uint8* p = (const uint8*)b.GetData();
		Blob bl[8]; const int n = _Blobs(p, cell, _BgByte(p, plane), bl, 8);
		if (n < 1) return false;
		nFrame++;
		if (n >= 2) nTwo++;
		gNComp += n;   // 📏 세계의 서명(D153)
		const bool hasD = (di != 0) && (dv >= 0);      // 짝짓기에 쓸 값이 있나
		// 📏 **눈금은 짝짓기와 무관하다** — 짝짓기를 끈 팔에서도 「`bl[0]` 이 방해자인가」는 세야 한다.
		//   ⚠️⚠️ 실측으로 밟았다(D138): 리팩터가 `dv = -1` 을 넘기자 이 계수기가 **조용히 0** 이 됐다
		//     (함정 288·319 의 그 자리 — 「도는가」와 「읽히는가」는 다른 사실이다).
		const bool hasG = (di != 0) && (dvG >= 0);
		if (hasG && bl[0].v == (uint8)dvG) nMiss++;
		int pick = 0;
		// 🔑 **키는 둘 중 하나다**: `pair == 1` ⇒ **색**(`v`) · `pair == 5` ⇒ **잉크**(`ink`).
		//   ⚠️⚠️ 색이 변하는 방해자에서는 색이 **원리적으로 키가 될 수 없다**(D140) ⇒ 잉크로 간다.
		if ((pair == 1 || pair == 5) && dv >= 0)
		{
			pick = -1;
			for (int k = 0; k < n; ++k)
			{
				const bool isD = (pair == 1) ? (bl[k].v == (uint8)dv)
					: (bl[k].ink == (uint64)dv);
				if (!isD) { pick = k; break; }
			}
			// ⚠️ 목표가 안 보인다. `keep` 이면 **폴백으로 살고**(세어진다) 아니면 **버려진다**(D160).
			if (pick < 0) { if (!keep) return false; pick = 0; }
		}
		// ↩️ `pair == 6` — 키가 **방해자**가 아니라 **목표의 자리**(`cx16`)다(D141).
		//   ⭐ 극성이 뒤집혔다: 앞의 둘은 「이것을 **빼라**」였고 이것은 「이것을 **골라라**」다.
		else if (pair == 6 && dv >= 0)
		{
			pick = -1;
			for (int k = 0; k < n; ++k) if (bl[k].cx16 == (int64)dv) { pick = k; break; }
			// ⚠️ 목표가 안 보인다. `keep` 이면 **폴백으로 살고**(세어진다) 아니면 **버려진다**(D160).
			if (pick < 0) { if (!keep) return false; pick = 0; }
		}
		outV = bl[pick].v; outCx = bl[pick].cx16; outInk = bl[pick].ink;
		return true;
	}
	
	void _RunLeak()
	{
		const int cell = MLEpisodeGen::kSize;
		const uint64 plane = (uint64)cell * (uint64)cell;
		static constexpr int kStg = 13;
		static const char* kSN[kStg] = {
			"⓿ 아무것도 안 한다(대조군)", "① + TaskCode(String)",
			"② + Compile(스크립트)", "③ + RunStart(VM)", "④ + Bytes + Pack(4KB)",
			"⑤ **파스**에서 떨어지는 소스", "⑥ Compile · **10배 긴** 소스",
			"⑦ **분석**에서 떨어지는 소스",
			// 🔬 D134 — **방출 이후**를 가른다. ⚠️ D133 의 엔진 컷(⑧~⑫)은 **걷었다** —
			//   그 질문이 닫혔다(`Parse`·`Analyze` 둘 다 0 · 두 판 연속) 그리고 원인이 코드로 확정됐다.
			"⑧ 성공 전체 + **`Release()`**", "⑨ 마무리컷1 — 방출까지만",
			"⑩ 마무리컷2 — + 상태 버퍼", "⑪ 마무리컷3 — + **동적 TypeInfo**",
			// 🐕 **꼬리 단계**(함정 347 처방) — 값을 읽지 않는다. ⚠️⚠️ **반복 수가 아니라 시간**이
			//   있어야 표집이 잡는다: 앞 판의 꼬리는 「아무것도 안 한다」 10만 회라 **점이 1개**였고
			//   라운드 마감 점프를 못 흡수했다. ⇒ **누수가 0 으로 확인된 일**(TaskCode)을 돌린다 —
			//   시간이 들고(≈18초) 그 자신의 기대값이 **0** 이라 오염을 곧바로 드러낸다.
			"⑫ 🐕 꼬리(TaskCode 만 · 기대 0 · 값 안 읽는다)" };
		// ⏱️ 단계마다 같은 횟수. ⚠️ **첫 판(6만)은 단계가 5~8초에 끝나 귀속이 안 됐다** —
		//   5초 표집으로 점이 한두 개뿐이었다. ⇒ **10배**로 늘려 단계마다 **기울기**를 잰다
		//   (기울기는 단계 경계의 오프셋에 면역이다).
		// ⏱️ **단계별 반복 수** — ⑤ 는 `Compile` 이 실패마다 진단을 `LogA` 로 찍으므로
		//   60만 회면 stdout 이 터진다(함정 205 계열) ⇒ 5만으로 줄이고 **반복당**으로 읽는다.
		//   ⑥ 은 소스가 10배라 컴파일이 느리다 ⇒ 20만.
		static const int kSIt[kStg] = { 600000, 600000, 600000, 600000, 600000, 50000, 200000, 50000, 300000, 300000, 300000, 300000, 600000 };
		// ⑤ **일부러 깨진 소스** — 렉서가 거부한다(`@` 는 이 언어의 문자가 아니다).
		//   ⇒ 실패해도 새면 누수는 **전단**(렉서/파서)에 있다.
		String badSrc;
		badSrc.AppendFormat("domain draw\n\nfunc OnStart()\n{\n    @@@\n}\n");
		// ⑥ **10배 긴 소스** — 같은 그리기를 30줄로 늘린다(문법은 그대로).
		//   ⇒ 누수가 크기에 비례하면 AST/바이트코드, 상수면 **호출당 고정 할당 하나**다.
		String bigSrc;
		bigSrc.AppendFormat("domain draw\n\nfunc OnStart()\n{\n");
		bigSrc.AppendFormat("    Draw::Clear(0, 0, 0)\n");
		for (int q = 0; q < 30; ++q)
			bigSrc.AppendFormat("    Draw::Color(%d, %d, %d)\n"
				"    Draw::RectFill(%d, %d, 6, 6)\n", q * 7, 200 - q * 5, q * 3,
				(q % 8) * 7, (q / 8) * 7);
		bigSrc.AppendFormat("}\n");
		// ⑦ **파스는 되고 분석에서 떨어지는 소스** — 문법은 맞고 **없는 함수**를 부른다.
		//   ⇒ ⑤(파스 실패)와 나란히 두면 `Parse` / `Analyze` / `Compile` 셋 중 **어디가**
		//   새는지 확정된다. ⚠️ 그 이름이 실제로 없어야 한다 — 있으면 이 단계가 통째로 뜻을 잃는다
		//   (성공 수가 0 이 아니면 그것이 그 자리의 신호다).
		String anaSrc;
		anaSrc.AppendFormat("domain draw\n\nfunc OnStart()\n{\n"
			"    Draw::ThisFunctionDoesNotExist(1, 2, 3)\n}\n");
		LogA("[ml] ── 📏 **D128 · 누수를 단계로 가른다** ─────────────────────────────\n"
			"[ml]   ★ 실측: `-mlsparse` 가 **0.71 MB/초**로 자란다(직선) · 핸들·스레드 평평\n"
			"[ml]   ★ 누적 단계 %d개(⑤⑥ 은 축을 가르는 곁가지) — 증가율의 **차이**가 그 조각의 몫이다\n"
			"[ml]   ⚠️ 밖의 표집기가 `LEAKMARK` 로 단계를 CSV 에 적는다(값은 거기서 읽는다)\n",
			kStg);
			// 📌 **판정 요약**(D134) — 이 라운드가 무엇을 확정했는지 스스로 찍는다.
			//   ⚠️ 「미리 등록」은 재기 **전에** 적는 것이고, 이 줄들은 **이미 잰 뒤**의 요약이다.
			//     다음 판이 새 물음을 등록하면 그때 다시 「미리」가 된다.
			LogA("[ml] ── 📌 **D134 판정 — 방출 이후를 갈랐다** ────────────────────────\n"
				"[ml]   ⑨ 방출까지만 **0** · ⑩ +상태버퍼 **0** · ⑪ +동적 TypeInfo **203 B**"
				" ⇒ ★ **전부 `ScriptReflection::Build` 다**\n"
				"[ml]   ⚠️ ⑧(전체+`Release()`) = **226 B** ⇒ 등록 ㉠ 반증 — **해제해도 샌다**"
				"(`Clear()` 가 포인터만 null 로 만들고 `delete` 를 안 한다)\n"
				"[ml]   ⚠️⚠️ 문턱: 30만 회 ⇒ 100 B/회면 **30MB** 다. **10 B/회 미만은 「0」으로 읽는다**\n"
				"[ml]   🐕 ⑫ 는 **꼬리**다 — 값을 읽지 않는다(함정 347)\n");
		for (int st = 0; st < kStg; ++st)
		{
			LogA("[ml] LEAKMARK stage=%d %s\n", st, kSN[st]);
			// 🔬 **컷은 단계마다 세운다** — 그 밖의 단계는 반드시 `0`(정상)이어야 한다.
			//   ⚠️ 안 되돌리면 뒤 단계가 통째로 「분석 실패」가 되어 판이 뜻을 잃는다.
			// 🔬 마무리 컷(D134) — ⑨⑩⑪ 만 세운다. ⚠️ ⑧ 은 **정상 경로 전체**여야 한다.
			DrawProgram::PostCut() = (st >= 9 && st <= 11) ? (st - 8) : 0;
			int made = 0, failC = 0, failR = 0, failP = 0;
			for (int i = 0; i < kSIt[st]; ++i)
			{
				// 📏 ⚠️⚠️ **조용한 단계는 탐침에게 「완주」로 읽힌다** — 실측으로 밟았다(D128):
				//   단계 3 이 60만 회를 **한 줄도 안 찍고** 도는 동안 탐침의 「stdout 크기 안정 45초」가
				//   발화해 `quit` 을 보내고(엔진 스레드가 막혀 못 받는다) **60초 뒤 pid 로 죽였다.**
				//   ⇒ **함정 43 의 뒷면**이다 — 크기 안정은 「끝났다」가 아니라 「조용하다」만 말한다.
				//   ★ 처방은 밖이 아니라 **여기**다: 단계 안에서도 진행을 찍는다(6만마다 = 단계당 10줄).
				//   ⇒ 덤으로 표집기의 진행 칸이 촘촘해져 **단계별 기울기**가 더 잘 잡힌다.
				if ((i % 10000) == 0)
					LogA("[ml] LEAKMARK stage=%d 진행 %d/%d\n", st, i, kSIt[st]);
				if (st == 0) { made++; continue; }
				// ⑤ ⚠️ **실패를 기대한다** ⇒ `break` 하지 않는다(성공하면 그것이 이상이다).
				if (st == 5)
				{
					DrawProgram pb;
					if (pb.Compile(badSrc.View(), (uint32)cell, (uint32)cell, NameID("LeakB")))
						failC++;
					made++; continue;
				}
				// ⑥ 긴 소스 — 문법은 맞으므로 실패하면 그것이 배관 문제다.
				if (st == 6)
				{
					DrawProgram pl;
					if (!pl.Compile(bigSrc.View(), (uint32)cell, (uint32)cell, NameID("LeakL")))
						{ failC++; break; }
					made++; continue;
				}
				// ⑦ ⚠️ **분석 실패를 기대한다** ⇒ `break` 하지 않는다(성공하면 이름이 실재하는 것이다).
				if (st == 7)
				{
					DrawProgram pa;
					if (pa.Compile(anaSrc.View(), (uint32)cell, (uint32)cell, NameID("LeakA")))
						failC++;
					made++; continue;
				}
				// 🔬 **D134 — 방출 이후를 가른다.** ⑫ 는 꼬리라 누수 0 인 일만 돈다.
				// 🐕 꼬리 — `TaskCode` 만(누수 0 으로 확인된 일). ⚠️ 값을 읽지 않는다.
				if (st == 12) { MLEpisodeGen::TaskCode(i % 5, i % 3, (i / 3) % 3, 0); made++; continue; }
				if (st >= 8 && st <= 11)
				{
					const int dci = i % 5, dxi = i % 3, dsi = (i / 3) % 3;
					const String dsrc = MLEpisodeGen::TaskCode(dci, dxi, dsi, 0);
					DrawProgram pd;
					if (!pd.Compile(dsrc.View(), (uint32)cell, (uint32)cell, NameID("LeakD")))
						{ failC++; break; }
					// ★ **표제 팔** — 소유한 것을 명시로 놓는다. 이것이 0 B 면 원인은
					//   「소멸 시 해제가 안 된다」로 확정되고 처방이 정해진다(소멸자를 준다).
					if (st == 8) pd.Release();
					made++; continue;
				}
				const int ci = i % 5, xi = i % 3, si = (i / 3) % 3;
				const String src = MLEpisodeGen::TaskCode(ci, xi, si, 0);
				if (st == 1) { made++; continue; }
				DrawProgram pr;
				if (!pr.Compile(src.View(), (uint32)cell, (uint32)cell, NameID("Leak")))
					{ failC++; break; }
				if (st == 2) { made++; continue; }
				if (!pr.RunStart()) { failR++; break; }
				if (st == 3) { made++; continue; }
				Bytes b; b.Reset(plane);
				if (!ImageFormat::PackRGB332Delta(pr.canvas, nullptr,
					(uint8*)b.GetData(), plane)) { failP++; break; }
				made++;
			}
			// ⚠️ 실패 수를 **같이** 찍는다 — 조용히 `break` 하면 「그 단계는 안 샌다」로 오독한다.
			LogA("[ml] LEAKMARK stage=%d 끝(%d회) — 성공 %d · 실패(C/R/P) %d/%d/%d\n",
				st, kSIt[st], made, failC, failR, failP);
		}
		// 🔬 ⚠️ **되돌린다** — 컷이 남으면 이 앱의 스크립트 마무리가 조용히 잘린다.
		DrawProgram::PostCut() = 0;
		LogA("[ml] 📏 LEAKDONE — CSV 의 `stage` 칸과 MB 를 맞춰 **반복당 바이트**를 낸다\n"
			"[ml]   ⚠️ 표지에 **공백을 두지 않는다** — `Start-Process -ArgumentList` 가 공백이 든"
			" 값을 **쪼갠다**(실측으로 밟았다)\n");
	}

	void _RunSparse()
	{
		const int cell = MLEpisodeGen::kSize;
		const uint64 plane = (uint64)cell * (uint64)cell;
		// 🎲 **씨앗 30**(D113-B) — 10 이면 `H` 의 표준오차가 1.4%p 라 **차이 문턱 4.0%p** 가
		//   재려는 효과(+2.5~6%p)와 같은 크기다 ⇒ 판정이 널뛴다.
		// ♻️ **씨앗 60**(D115) — **전반 30 / 후반 30** 으로 따로 집계해 **한 판에서 두**
		//   **독립 판정**을 낸다. ⇒ 각 반의 차이 문턱은 씨앗 30 기준(**~2.3%p**) 그대로다.
		const int kSd = 60, kPh = 4, kPer = 80, kArm = 8;
		// 🔗 **D136 미리 등록** — `_Blobs` 를 연결 기반으로 갈았다. 판정은 **둘**이다.
		//   ⚠️ **한 판에 한 축**이라 이 판은 세계를 넓히지 **않는다** — 배관만 간다.
		const bool blobsOk = _BlobsSelfTest();
		LogA("[ml] ── 📌 **D136 미리 등록 — `_Blobs` 를 연결 기반으로** ──────────────\n"
			"[ml]   ㉠ **배관이 갈렸나** = 자체 시험(같은 색 둘을 3개로 센다) ⇒ %s\n"
			"[ml]   ㉡ **거동 불변인가** = 아래 재현 대조가 `kPrev` 와 **소수점까지** 같아야 한다"
			" — 대상이 하나인 프레임에서는 값별 묶기와 연결 묶기가 **같은 답**이어야 한다\n"
			"[ml]   ⚠️ ㉡ 이 깨지면 **그 자리가 발견**이다 — 후보는 **겹침으로 조각난 프레임**이다"
			"(`잉크 < 8` 버리기가 예전엔 값 전체에, 이제는 **성분마다** 걸린다)\n"
			"[ml]   ⚠️⚠️ ㉠ 이 ⛔ 면 ㉡ 을 읽지 않는다 — 안 갈린 배관의 재현은 **아무 말도 못 한다**\n",
			blobsOk ? "✅" : "⛔ 판정불가");
		// 🔒 **판 0-a 스위치**(D124) — `false` 면 **비트 없는 세계**다.
		//   ★ 이 판이 축을 셋 바꾸므로(트리거 이동 · `szN` 삭제 · 관문 배관) 먼저
		//   `false` 로 돌려 **`szN` 삭제만의 효과**를 단독으로 잰다(함정 243).
		static const bool kFlipOn = true;    // 🕳️ **판 1** — 비트를 켠다
		const double lamT = 0.95;                  // 🪜 종단 흔적의 감쇠
		const double lr = 0.05;
		// 🎚️ 팔마다 (갱신 묶음 수, 다양성 모드, 학습률 배수) — 분기 대신 **표**로 둔다.
		//   모드 0 무작위 · 1 라운드로빈 · 2 고정 · 3 입력이 고른다.
		//   모드 0 무작위 · 1 라운드로빈 · 2 고정 · 3 입력 · 4 **입력 ÷ (1+최근성)**
		// 🐛 **「전부」는 묶음 수를 따라가야 한다** — 묶음이 8 이 됐으므로 `kGG` 를 쓴다.
		//   모드 0 무작위 · 2 고정 · 3 입력 · 4 입력÷최근성(단일 λ) · 5 **적응형**
		// 🪜 팔 여덟(D98) — 전부 **굳은 정책**(k=1 · 입력 ÷ (1+최근성 λ=0.99))을 쓰고,
		//   **보상 규칙과 탐험만** 다르다.
		// 🔭 팔 여덟(D100) — **지평만 다른 오라클 다섯** + 배운 1단 + 보상 규칙(재현).
		// 🎯 팔 여덟(D101) — **예측기 형태**와 **행동 뽑기**만 다르다.
		// 📈 팔 여덟(D102) — **깊이를 감쇠로 담나**를 `γ` 축으로 가른다.
		// 🔭 팔 재배치(D105-C) — **폭마다 실제 깊이를 잰다.** 오라클 지평 다섯 + 학습 둘 + 무작위.
		//   ⚠️ D105 의 첫 판이 「폭을 늘렸다」고 찍었는데 **무작위도 20.4 → 44.6% 로 올랐다**
		//   ⇒ **세계가 쉬워진 것**이다. 「처음 넘는 지평」만이 그것을 가른다(D100 의 방법).
		// 🕳️ 팔 여덟(D111) — **N−1 대조군**: 관측만 ↔ **+이력** ↔ 🔭 오라클(숨은 비트를 안다).
		// 🔁 팔 여덟(D112) — 전부 **📈 Q**(D111: 이력은 「가치」 학습기에서만 값을 한다).
		// 🔬 팔 여덟(D126) — `arm 0·1·5·6·7` 은 D125 와 같은 역할이라 **비트 재현**.
		//   새 팔 `2·3` = **성분 하나씩**(🚫 막힘만 · 🔮 놀람만) · `4` = 🧩 잠재 지평 2
		//   (계획 계단에서 가장 강했던 자리 — 그것만 남긴다).
		static const int kAOra[8]  = { 0, 0, 0, 0, 0, 0, 1, 4 };
		static const int kAHist[8] = { 0, 0, 0, 0, 0, 0, 0, 0 };
		static const int kABlk[8]  = { 0, 0, 2, 0, 0, 2, 0, 0 };   // 🚫 막힘 행동별
		static const int kASur[8]  = { 0, 0, 0, 3, 0, 3, 0, 0 };   // 🔮 놀람 정규화
		static const int kAPv[8]   = { 0, 0, 0, 0, 0, 0, 0, 0 };
		static const int kAHid[8]  = { 0, 0, 0, 0, 1, 0, 0, 0 };   // 🧠 은닉
		static const int kAHz[8]   = { 0, 0, 0, 0, 2, 0, 0, 0 };   // 🧩 계획 지평
		static const double kALam[8] = { 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0 };
		static const int kALrn[8]  = { 1, 1, 1, 1, 1, 1, 1, 1 };
		static const int kALog[8]  = { 1, 1, 1, 1, 1, 1, 1, 1 };
		static const int kARol[8]  = { 0, 0, 0, 0, 0, 0, 0, 0 };
		static const int kAQ[8]    = { 0, 1, 1, 1, 0, 1, 0, 0 };
		static const int kAQAM[8]  = { 0, 1, 1, 1, 0, 1, 0, 0 };
		static const double kAGam[8] = { 0.0, 0.9, 0.9, 0.9, 0.9, 0.9, 0.0, 0.0 };
		static const int kAImm[8]  = { 0, 0, 0, 0, 0, 0, 0, 0 };
		static const int kAPen[8]  = { 0, 0, 0, 0, 0, 0, 0, 0 };
		static const int kAEnd[8]  = { 0, 0, 0, 0, 0, 0, 0, 0 };
		static const int kAEps[8]  = { 0, 40, 40, 40, 40, 40, 0, 0 };
		static const char* kAN[8] = { "🚪 무작위        ", "📈 Q · 관측만    ",
			"📈 Q · 🚫 **막힘만**  ", "📈 Q · 🔮 **놀람만**  ",
			"🧩 잠재 · 지평 2   ", "📈 Q · 🚫+🔮 둘 다 ",
			"🔭 지평 1        ", "🔭 지평 4        " };
		static const char* kPhN[4] = { "A 색만 틀림", "B 자리만 틀림",
			"A' 색만 틀림(다시)", "**H 선행 필요**(자리+크기 제약)" };
		LogA("[ml] ── 📈 **D102 · 깊이를 감쇠로 담는다**(계획을 짓기 전에) ──────\n"
			"[ml]   ★ 진단: D98~D101 이 `H` 에서 다 실패한 공통 원인은 **「나아짐」을 `d`"
			"(화소 목표거리)로 정의한 것**이다 — `d` 는 **탐욕 지표**다\n"
			"[ml]   ★ 깊이를 담는 길은 **둘**: **계획**(상상) · **가치**(감쇠). 계획만 봤다"
			" ⇒ **가치가 훨씬 싸다**(`Q` = 예측기와 같은 **%d 파라미터**) ⇒ **먼저 잰다**\n"
			"[ml]   ★ 그리고 이 처방은 **함정 249 의 모순을 원리적으로 피한다** —"
			" 보상이 **도달 +1 하나뿐**이라 「막힘에 벌」이 **없다**. 깊이는 **γ** 가 담는다\n"
			"[ml]   ★ 미리 등록: ㉠ Q(γ=0.9)가 `H` 에서 **무작위 19.5%% 를 넘는다**(~30%%)"
			" ㉡ **γ=0.5 는 못 넘는다** ㉢ **γ=0.99 ≥ γ=0.9** ㉣ `A'` 는 로지스틱이 낫다\n"
			"[ml]   ⚠️⚠️ 갈림: Q 가 `H` 를 못 넘으면 **감쇠로는 안 된다**가 서고 **계획이 필요하다**"
			"는 말이 **N−1 대조군 위에** 선다 ⇒ 그것이 다음 판이다\n"
			"[ml]   ⚖️ 관문을 **두 분포에서** 잰다(함정 259) — 고정(🚪 무작위) · 자기(그 정책)\n"
			"[ml]   ★ 굳은 정책(묶음 %d · 특징 %d) · 씨앗 %d · 과제군 %d ·"
			" 구간 %s → %s → %s → %s\n",
			kLA * kGF, kGG, kGF, kSd, kPer, kPhN[0], kPhN[1], kPhN[2], kPhN[3]);
		const int nc = MLEpisodeGen::PaletteCount();
		Array<int> tq;
		tq.Reset(0);
		SPol pol[8];
		STrace tr;                                 // 🪜 종단 흔적(재사용 — 스택이 크다)
		// ⚠️ **팔마다** 둔다(D101) — 하나면 팔끼리 오염된다.
		PPol prd[kArm];
		QPol qp[kArm];                             // 📈 선형 Q(D102)
		// 🧩 **전이 상상기**(D103) — 275KB 라 `static` 이다(스택 금지).
		// 🧩 **상상기 셋**(D103-B) — **lr 폭을 잰다.** 안 훑고 「안 된다」고 하면 안 된다.
		//   ⚠️ 하나가 275KB 라 셋이면 825KB ⇒ **`static`** 이다(스택 금지).
		static constexpr int kTL = 3;
		static const double kTLr[kTL] = { 0.01, 0.05, 0.2 };
		// ⚠️ D103-B 에서 **끝값(0.01)이 최고**였다 ⇒ **범위를 안 넓혀 본 것**이다(concept.md 의 그 규칙).
		static TPol tp[kTL];
		static constexpr int kTD = 4;
		// 🧩 **상대** 오차 — 분자 ‖상상−실제‖ · 분모 ‖안 변한다−실제‖ ⇒ 대조군이 정확히 100%.
		//   ⚠️⚠️ **깊이 비교에는 못 쓴다**(함정 266) — 분모가 깊이와 함께 **커진다**.
		double tNum[kTL][kTD][kPh] = {}, tDen[kTD][kPh] = {};
		int tN[kTD][kPh] = {};
		// 🧩 **절대** 오차 — 깊이 비교는 **이쪽**으로 한다(분모가 안 움직인다).
		double tAbs[kTL][kTD] = {}, tAbsD[kTD] = {}; int tAbsN[kTD] = {};
		// ⚖️ **깊이별 결정 일치**(D120) — 대조군을 나란히 둬 **상한**을 눈에 보이게 한다.
		int dcN2[kTD][kPh] = {}, dcC2[kTD][kPh] = {}, dcO2[kTL][kTD][kPh] = {};
		// 🎯 깊이 4 의 **씨앗별 부호검정**(함정 309 — 평균만 보면 안 된다).
		int dcW[kTL] = {}, dcL[kTL] = {}, dcT[kTL] = {};
		// 🔮 **flip 별 씨앗 승패**(D125) — `B` 에서 「둘 다 ↔ 관측만」.
		int flW[2] = {}, flL[2] = {}, flT[2] = {};
		// 🧹 **죽은 계수기 `dcN`/`dcOk`/`dcCtl` 을 걷었다**(D123) — D120 이 증가문을 걷었는데
		//   선언과 계산이 남아 `dcA`/`dcCA` 를 0 으로 만들고 있었다. 살아 있는 것은 `dcN2`/
		//   `dcC2`/`dcO2`(D120)이고 **한 글자 차이**라 함정 288 이 재현될 자리였다.
		const double lrq = 0.02;
		// ⚖️ **argmax 관문**(D101) — 오라클 지평 4 의 선택과 맞나(구간마다).
		// ⚖️ **두 분포**(D102 · 함정 259) — 0 = 고정(🚪 무작위 팔) · 1 = 자기(그 정책).
		const double lrp = 0.03;
		// 🔮 채점 — 구간마다 (걸음 수 · 맞힘 · 「늘 막힘」이 맞음) + **recall**(나아짐만).
		// 📏 **신호의 밀도를 판마다 잰다**(D114 · 함정 292) — 처방을 고르기 전에 밀도다.
		//   ★ D113 의 오라클 전용 계수기를 **대체**한다 — 팔 7(지평 4)의 칸이 곧
		//   **「정상 경로의 실패율」**이고, 이제 **학습 팔의 밀도도 같이** 나온다.
		int nSg[kArm][kPh] = {}, nBlk[kArm][kPh] = {}, nSur[kArm][kPh] = {};
		int pcN[kPh] = {}, pcOk[kPh] = {}, pcMaj[kPh] = {};
		int prN[kPh] = {}, prOk[kPh] = {};
		// 🎭 **네 판**(D104) — 0·1·2 = 유형 따로 · 3 = 섞음.
		// 🌿 **세 판**(D105) — 조건 분기의 **폭**. 도형은 🟥 고정(D104 가 그 축을 닫았다).
		// 📈 **네 판**(D106) — 「경우의 수」 = **행동 수**. 세계·깊이는 그대로다.
		// ⏱️ **아홉 판**(D107) — 예산 x 행동 수 격자. 세계·깊이·관측은 전부 그대로다.
		// ☠️ **여섯 판**(D108) — 추가 행동의 **종류** x **개수**. 예산은 60 고정(D107: 부차적이다).
		// 💀 **아홉 판**(D109) — 추가 행동의 **해로움 정도** x **개수**. 예산 60 고정.
		// 🕳️ **판 하나**(D111) — 이제 축은 **팔**이다(관측만 ↔ 이력 · 그리고 오라클).
		static constexpr int kMd = 1;
		static constexpr int kNB = 1;
		static constexpr int kNA = 1;
		static const int kMdCap[kMd]  = { 60 };
		static const int kMdA[kMd]    = { 5 };
		static const int kMdKind[kMd] = { 0 };
		static const char* kMdKN[1] = { "🕳️ 숨은 상태" };
		int hitM[kMd][kArm][kPh] = {}, nM[kMd][kArm][kPh] = {};
		int hitP[kArm][kPh] = {}, nP[kArm][kPh] = {};
		// 🎯 **씨앗별 부호검정**(D118) — 「어느 팔이 그 씨앗에서 이겼나」를 센다.
		//   ★ 크기가 아니라 **방향의 일관성**이라 대조군의 흔들림에 면역이다.
		//   짝 넷: 0 = 놀람↔관측만 · 1 = 둘다↔무작위 · 2 = 막힘정규화↔관측만 ·
		//   3 = 막힘정규화↔막힘날것.
		static constexpr int kSg = 4;
		// 🔒 **짝과 라벨을 한 구조체로**(D127 · 함정 331) — 두 배열로 두면 **반드시 어긋난다**
		//   (함정 285 가 `kAN[]` 로 막은 것과 같은 병이고 자리만 다르다).
		//   ⚠️ **함수 스코프**여야 한다 — 씨앗 루프 안에 두면 판정문이 못 본다.
		struct SgPair { int a, b; const char* n; };
		static const SgPair kSgP[kSg] = {
			{ 3, 1, "🔮 놀람만 ↔ 📈 관측만  " },
			{ 2, 1, "🚫 막힘만 ↔ 📈 관측만  " },
			{ 3, 2, "🔮 놀람만 ↔ 🚫 **막힘만**" },   // ★ 직접 대결(D127 의 핵)
			{ 5, 0, "🚫+🔮 둘 다 ↔ 🚪 무작위 " },
		};
		int sgnW[kSg] = {}, sgnL[kSg] = {}, sgnT[kSg] = {};
		// ♻️ **전반/후반 따로**(D115) — `rep = (sd < kSd/2) ? 0 : 1`.
		int hitR[kArm][kPh][2] = {}, nR[kArm][kPh][2] = {};
		// 🕳️ **flip 부분집단**(D124) — `tFlip` 은 **과제의 속성**이므로 **한 팔 안에서** 가른다
		//   ⇒ 팔 간 교란(함정 320)에 **원리적으로 면역**인 추정량이 처음 생긴다.
		int hitF[kArm][kPh][2] = {}, nF[kArm][kPh][2] = {};
		// 🔭 **오라클 걸음 수**(D124 등록 ㉠) — `H` 에서 **5.33** 이어야 한다(지금 8: `q` 축 정체).
		int oStp[kArm][kPh] = {}, oStpN[kArm][kPh] = {};
		// 🔢 **해시 위생**(D124 등록 ㉤) — 반전율 · 씨앗당 · 고유 입력.
		int nFl[2] = {}, flSdMin = 999999, flSdMax = -1;
		// 🔍 **특징 관문**(D115 · 함정 295) — 켠 팔에서 그 값이 정말 0 이 아닌가.
		double fMag[kArm] = {}; int fCnt[kArm] = {};
		// 🔮 **자기 놀람율**(D116) — 온라인 이동평균. **그 팔이 스스로 누적**한다.
		double sRate[kArm] = {};
		// 🚫 **자기 막힘율**(D117) — 함정 300 의 **반증 시험**용. 같은 온라인 이동평균.
		double bRate[kArm] = {};
		// 🧠 **잠재 상태 생성기**(D119) — 팔마다 하나. 275KB × 8 ⇒ `static`.
		static MPol mp[kArm];
		// 🧩 **잠재 전이 + 가치**(D121) — 팔마다 하나. `kLA·kHid²` 라 작다(10KB).
		static TLat tl[kArm];
		int hitH2[kArm][kPh][2] = {}, nH2[kArm][kPh][2] = {};
		int upJoin = 0, okSd = 0, upK1 = 0;
		ImageFormat::Bitmap junk;
		if (!ImageFormat::CreateRGBA8(junk, (uint32)cell, (uint32)cell))
			{ LogA("[ml]   ⛔ 비트맵을 못 만들었다\n"); return; }
		for (int md = 0; md < kMd; ++md)
		{
		const int wid = 1;                         // 🔒 세계 법칙은 **현행 고정**(폭 1)
		const int nAct = kMdA[md];                 // 📈 이 판의 **활성 행동 수**
		const int kCap = kMdCap[md];               // ⏱️ 이 판의 **걸음 예산**
		const int kind = kMdKind[md];              // ☠️ 추가 행동의 **종류**
		LogA("[ml]   ☠️ 판 %d/%d — %s x 행동 **%d개**(추가 %d개 · 예산 %d)\n",
			md + 1, kMd, kMdKN[kind], nAct, nAct - 5, kCap);
		for (int sd = 0; sd < kSd; ++sd)
		{
			// ★ 씨앗마다 정책을 0 에서 다시 — 안 그러면 씨앗이 독립이 아니다.
			for (int k = 0; k < 8; ++k) pol[k] = SPol();
			for (int k = 0; k < kArm; ++k) prd[k] = PPol();   // 🔮 씨앗마다 0 에서
			for (int k = 0; k < kArm; ++k) qp[k] = QPol();    // 📈 씨앗마다 0 에서
			for (int q = 0; q < kTL; ++q) tp[q].Reset();      // 🧩 씨앗마다 0 에서
				// 🔮 **자기 놀람율**(D116) — 씨앗마다 **0.5 에서**(0 이면 첫 걸음이 x100).
				for (int k = 0; k < kArm; ++k) sRate[k] = 0.5;
				// 🚫 **자기 막힘율**(D117) — 놀람율과 **같은 식**이어야 시험이 성립한다.
				for (int k = 0; k < kArm; ++k) bRate[k] = 0.5;
				// 🧠 씨앗마다 **결정적 산포**로 대칭을 깬다(난수 스트림을 안 건드린다).
				for (int k = 0; k < kArm; ++k) mp[k].Init((uint32)sd + 1u);
				// 🧩 전이는 **항등에서** 출발한다(대조군과 같은 출발점).
				for (int k = 0; k < kArm; ++k) tl[k].Init((uint32)sd + 1u);
			SeedRand(MLEpisodeGen::ScrambleSeed(92000u + (uint32)sd * 7u));
			// ⚠️ 과제를 **먼저 전부** 뽑는다(함정 213) — 팔의 난수가 과제를 흔들지 않게.
			tq.Reset(0);
			for (int ph = 0; ph < kPh; ++ph)
				for (int q = 0; q < kPer; ++q)
				{
					const int gc = RandInt(0, nc), gx = RandInt(0, 3);
					const bool badC = (ph == 0 || ph == 2);
					const bool badX = (ph == 1 || ph == 3);
					// 🪜 **구간 3 = 깊이 2** — 목표 크기를 **최대(2)** 로 두고 시작도 그것으로 둔다.
					//   ⇒ 크기는 이미 맞는데 **자리를 옮기려면 크기를 내렸다 올려야** 한다.
					const int gs = (ph == 3) ? 2 : 0;
					tq.Add(gc); tq.Add(gx); tq.Add(gs);
					tq.Add(badC ? ((gc + 1 + RandInt(0, nc - 1)) % nc) : gc);
					tq.Add(badX ? ((gx + 1 + RandInt(0, 2)) % 3) : gx);
					tq.Add(gs);
					// 🎭 **유형** — 따로 판은 고정, 섞음 판은 과제마다 뽑는다.
					const int rt = RandInt(0, MLEpisodeGen::kTaskTypes);   // ★ **난수를 늘 뽑는다** —
					//   그래야 판마다 난수열이 같아 (색·자리) 과제가 **동일**하다(짝 비교가 성립).
					tq.Add(0);   // 🎭 도형은 🟥 고정 — D104 가 그 축을 닫았다(함정 270)
				}
			// 🎲 이 씨앗의 이음매 표본 — `A 후반`(0) 과 `A' 전반`(1). ★ **k=1 팔**로 잰다.
			int sH[kArm][2] = {}, sN[kArm][2] = {};
			// 🎲 **씨앗별 절대 `A'`**(D93 · 함정 240) — 부호검정을 이 지표로 한다.
			int shH[kArm] = {}, snH[kArm] = {};   // 🎲 씨앗별 `H` 표본(D98)
			// ⚖️ 이 씨앗의 깊이 4 결정 일치(대조군 · 상상 셋).
			int sdN4 = 0, sdC4 = 0, sdO4[kTL] = {};
			// 🔮 **씨앗별 flip 부분집단**(D125) — 「둘 다 ↔ 관측만」을 flip 별로 견준다.
			int sdFH[kArm][2] = {}, sdFN[kArm][2] = {};
			int sdFl = 0;                            // 🔢 이 씨앗의 반전 과제 수(D124)
			for (int idx = 0; idx < kPh * kPer; ++idx)
			{
				const int ph = idx / kPer;
				const int hf = ((idx % kPer) < kPer / 2) ? 0 : 1;
				const int rep = (sd < kSd / 2) ? 0 : 1;   // ♻️ 재현 반쪽(D115)
				if (idx % kPer == 0) LogA("[ml]   · 씨앗 %d 구간 %d\n", sd + 1, ph);
				const int gc = tq.Data()[idx * 7 + 0], gx = tq.Data()[idx * 7 + 1];
				const int gs = tq.Data()[idx * 7 + 2];
				const int s0c = tq.Data()[idx * 7 + 3], s0x = tq.Data()[idx * 7 + 4];
				const int s0s = tq.Data()[idx * 7 + 5];
				const int tty = tq.Data()[idx * 7 + 6];      // 🎭 이 과제의 유형
				// 🕳️ **숨은 비트 = 이 과제의 잠재 파라미터**(D124). `(씨앗, 과제 번호)` 의 순수
				//   함수이므로 팔의 난수·정책·유능함이 **원리적으로 닿을 수 없다** —
				//   ★ **이 선언이 팔 루프 밖에 있다는 것이 그 증명**이다.
				// ⚠️ 배수는 **1009u** 다: `idx ∈ [0, kPh*kPer) = [0, 320)` 이므로 배수가 320
				//   보다 작으면 `(씨앗, 과제)` 에 **단사가 아니다**(131u 면 58% 충돌 ⇒ 씨앗별
				//   부호검정의 독립 전제가 깨진다).
				// ⚠️ `RandInt` 를 **안 부른다** ⇒ 난수 스트림을 한 draw 도 안 건드린다
				//   (과제 수열이 D123 과 **비트 단위로 같다** · 함정 213).
				const bool tFlip = kFlipOn && ((MLEpisodeGen::ScrambleSeed(51000u
					+ (uint32)sd * 1009u + (uint32)idx) & 1u) != 0u);
					// 🔢 해시 위생 — 전체 반전율(팔 루프 밖이므로 과제마다 한 번 센다).
					nFl[tFlip ? 1 : 0]++;
					if (tFlip) sdFl++;
				uint8 gv = 0; int64 gcx = 0; uint64 gink = 0; uint8 gbg = 0;
				// 🌊 목표 **프레임**을 보관한다 — 넓은 특징이 원본을 본다(D94).
				Bytes gbuf; gbuf.Reset(plane);
				bool gok = false;
				{
					DrawProgram g;
					// 📎 `TaskCode(...)` 의 결과를 **지역 변수로 받는다** — 가독성 때문이다.
					//   ⚠️⚠️ **주석을 정정한다**(2026-08-24): 처음에 이것을 「크래시 가설」로 적었는데
					//   **반증됐다** — ㉠ 실측: 수명을 늘려도 죽었다 ㉡ 원리: `ScriptRunner::Compile` 은
					//   `source` 를 `CompileSource` 에 넘기고 **보관하지 않는다**(`_program` 에 컴파일
					//   결과만 저장한다 · Engine/Script/ScriptRunner.cpp:32) ⇒ **원래 코드도 안전했다.**
					//   ★ 되돌리지 않고 남기는 이유는 **지역 변수가 더 명확해서**이고 그것뿐이다.
					const String src4 = MLEpisodeGen::TaskCode(gc, gx, gs, tty);
					if (!g.Compile(src4.View(),
						(uint32)cell, (uint32)cell, NameID("SpG"))) continue;
					if (!g.RunStart()) continue;
					Bytes& gb = gbuf;
					if (!ImageFormat::PackRGB332Delta(g.canvas, nullptr, (uint8*)gb.GetData(), plane))
						continue;
					const uint8* p = (const uint8*)gb.GetData();
					const uint8 bg = _BgByte(p, plane);
					Blob bl[8]; const int n = _Blobs(p, cell, bg, bl, 8);
					if (n != 1) continue;
					gv = bl[0].v; gcx = bl[0].cx16; gink = bl[0].ink;
					gbg = bg;
					gok = true;
				}
				if (!gok) continue;
				for (int arm = 0; arm < kArm; ++arm)
				{
					// 🎲 **팔마다 씨앗을 다시 뿌린다**(D115 · 함정 296) — `(sd, arm, idx)`.
					//   ⇒ 한 팔을 고쳐도 **다른 팔의 표본이 비트 단위로 같다.**
					//   ⚠️ `idx` 없이 뿌리면 같은 팔이 **과제마다 같은 난수열**을 되쓴다.
					SeedRand(MLEpisodeGen::ScrambleSeed(31000u
						+ ((uint32)sd * (uint32)kArm + (uint32)arm) * 1009u + (uint32)idx));
					int cc = s0c, cx = s0x, cs = s0s;
					// 🕳️ `szN` 은 **삭제됐다**(D124) — 트리거가 과제의 잠재 비트로 옮겨갔다.
					double aCnt[kLAX] = {};              // 🔢 행동 카운터(감쇠를 위해 실수다)
					double blkN = 0.0;                   // 🚫 **막힘 누적**
					double blkA[kLAX] = {};              // 🚫 **행동별** 막힘(D113)
					double surN = 0.0;                   // 🔮 **놀람** 누적(D114)
					double surA[kLAX] = {};              // 🔮 **행동별** 놀람(D114)
					double hCur[kHid] = {};              // 🧠 직전 걸음의 **잠재 상태**
					double pvCur[kLA] = {};              // 🔮 직전 걸음의 예측(확률)
					bool hit = false; int tries = 0;
					double pf[kGF] = {};
					int pa = -1, pjs = 0, rr = 0; double pd = 0.0;
					double pPredV = 0.0;                 // 🔮 직전 걸음의 예측
					// 🧩 최근 걸음의 (특징, 행동) — 깊이 4 를 재려면 5칸이면 된다.
					//   ⚠️ **에피소드마다 비운다** — 다른 과제의 걸음을 이으면 상상이 뜻을 잃는다.
					double fh[5][kGF] = {}; int ah[5] = {}; int hn = 0;
					// 🧠 **최근성**(D93) — 이름 없는 감쇠 흔적. 과제마다 0 에서 시작한다.
					// 🎛️ **세 시간 척도**(λ=0.3/0.6/0.9)를 늘 함께 굴린다(D95).
					double uu[kGG] = {};                 // 🧠 최근성(굳은 λ=0.99)
					tr.Reset();
					for (; tries < kCap; ++tries)
					{
						DrawProgram pr;
						// 📎 `TaskCode(...)` 의 결과를 **지역 변수로 받는다** — 가독성 때문이다.
						//   ⚠️⚠️ **주석을 정정한다**(2026-08-24): 처음에 이것을 「크래시 가설」로 적었는데
						//   **반증됐다** — ㉠ 실측: 수명을 늘려도 죽었다 ㉡ 원리: `ScriptRunner::Compile` 은
						//   `source` 를 `CompileSource` 에 넘기고 **보관하지 않는다**(`_program` 에 컴파일
						//   결과만 저장한다 · Engine/Script/ScriptRunner.cpp:32) ⇒ **원래 코드도 안전했다.**
						//   ★ 되돌리지 않고 남기는 이유는 **지역 변수가 더 명확해서**이고 그것뿐이다.
						const String src5 = MLEpisodeGen::TaskCode(cc, cx, cs, tty);
						if (!pr.Compile(src5.View(),
							(uint32)cell, (uint32)cell, NameID("Sp"))) break;
						if (!pr.RunStart()) break;
						Bytes b; b.Reset(plane);
						if (!ImageFormat::PackRGB332Delta(pr.canvas, nullptr,
							(uint8*)b.GetData(), plane)) break;
						const uint8* p = (const uint8*)b.GetData();
						const uint8 bg = _BgByte(p, plane);
						Blob bl[8]; const int n = _Blobs(p, cell, bg, bl, 8);
						if (n != 1) break;
						const bool badC = (bl[0].v != gv);
						const int64 dx16 = (bl[0].cx16 > gcx) ? (bl[0].cx16 - gcx) : (gcx - bl[0].cx16);
						const uint64 hi = (bl[0].ink > gink) ? bl[0].ink : gink;
						const uint64 loI = (bl[0].ink > gink) ? gink : bl[0].ink;
						if (!badC && dx16 == 0 && bl[0].ink == gink)
						{
							// 📈 **종단 보상 +1**(D102) — 여기서 마감해야 신용이 흐른다.
							//   ⚠️ 이 `break` 앞에서 안 배우면 **도달 신호가 통째로 사라진다.**
							if (pa >= 0 && kAQ[arm]) qp[arm].Learn(pf, pa, 1.0, lrq);
							// 🧩 **종단 보상도 잠재로**(D121) — 여기서 마감해야 신용이 흐른다(D102 의 그 규율).
							if ((pa >= 0) && (pa < kLA) && (kAHz[arm] > 0))
							{
								double hp3[kHid] = {};
								mp[arm].Hidden(pf, hp3);
								tl[arm].LearnV(hp3, pa, 1.0, lrq);
							}
							hit = true; break;
						}
						const double eX = (double)dx16 / (double)((int64)cell * 16);
						const double eS = (hi > 0u) ? ((double)(hi - loI) / (double)hi) : 0.0;
						const double d = (badC ? 1.0 : 0.0) + eX + eS;
						// 🌊 **넓은 특징 75개**(D94) — 이름이 없다. 비계(색 one-hot)는 걷어냈다.
						double f[kGF] = {};
						_WideFeat(p, (const uint8*)gbuf.GetData(), cell, gv, bl[0].v, gbg, f);
						// 🕳️ **이력 특징**(D111) — 이름 없는 행동 카운터 5칸.
						//   ⚠️ **팔이 이력을 보나**에 따라 켜고 끈다 — 0 이면 묶음이 조용하다.
						if (kAHist[arm])
							for (int k = 0; k < 5; ++k) f[83 + k] = aCnt[k] * 0.1;
						// 🚫 **막힘 누적**(D112) — 한 칸. 세계가 「무엇을 세라」고 안 알려 준다.
						if (kABlk[arm] == 1) f[88] = blkN * 0.1;
						// 🚫 **행동별 막힘**(D113) — 뭉갬을 푼 것이 이 다섯 칸이다.
						if (kABlk[arm] == 2)
							for (int k = 0; k < 5; ++k) f[89 + k] = blkA[k] * 0.1;
						// 🚫 **막힘 정규화**(D117) — 놀람과 **완전히 같은 식**이다.
						//   ★ 밀도가 82% 라 배율이 **x1.2** 뿐이어야 한다(예측).
						if (kABlk[arm] == 3)
						{
							const double nrb = 0.1 / (0.01 + bRate[arm]);
							for (int k = 0; k < 5; ++k) f[89 + k] = blkA[k] * nrb;
						}
						// 🔮 **예측 벡터 날것**(D119 · 원리적 대조군) — 선형의 선형이라 새 정보 0.
						if (kAPv[arm]) for (int k = 0; k < kLA; ++k) f[100 + k] = pvCur[k];
						// 🧠 **잠재 상태**(D119) — 직전 걸음의 은닉. `1/sqrt(kHid)` 로 대역을 맞춘다.
						if (kAHid[arm]) for (int k = 0; k < kHid; ++k) f[105 + k] = hCur[k] * 0.125;   // 🧠 1/sqrt(64)
						// 🔮 **놀람**(D114) — 막힘과 **같은 꼴**이고 **밀도만 다르다**.
						if (kASur[arm] == 1) f[94] = surN * 0.1;
						if (kASur[arm] == 2)
							for (int k = 0; k < 5; ++k) f[95 + k] = surA[k] * 0.1;
						// 🔮 **정규화**(D116 · 함정 300) — 자기 놀람율로 나눠 **스케일을 맞춘다**.
						if (kASur[arm] == 3)
						{
							const double nrm = 0.1 / (0.01 + sRate[arm]);
							for (int k = 0; k < 5; ++k) f[95 + k] = surA[k] * nrm;
						}
						// 🔍 **특징 관문**(D115) — 이력 칸(83~99)의 절대합. 켠 팔이 0 이면
						//   **그 팔은 특징을 안 받은 것**이다(함정 295 가 그 자리였다).
						{
							double mg = 0.0;
							for (int k = 83; k < kGF; ++k) mg += (f[k] < 0.0) ? -f[k] : f[k];
							fMag[arm] += mg; fCnt[arm]++;
						}
						// 🗣️ **낱말로 배운다** — 직전 행동이 나아짐이었나 막힘이었나.
						// 🎚️ 어느 묶음을 갱신할까 — **굳은 정책**: 입력 ÷ (1 + 최근성).
						// 🧠 이 걸음의 은닉을 계산해 **다음 걸음의 특징**으로 넘긴다(재귀).
						//   ⚠️ `f` 가 다 찬 뒤여야 한다 — 안 그러면 옛 칸을 본다.
						double hNow[kHid] = {};
						if (kAHid[arm]) mp[arm].Hidden(f, hNow);
						const int jsel = _PickOne(f, uu);
						// 📈 **TD 부트스트랩**(D102) — 보상 0 + γ·max_b Q(지금, b).
						//   ★ 「막힘」에 벌이 없다 ⇒ 함정 249 의 모순이 성립할 자리가 없다.
						if (pa >= 0 && kAQ[arm])
							qp[arm].Learn(pf, pa, kAGam[arm] * qp[arm].Best(f, nAct), lrq);
							// 📈 **잠재 가치 TD**(D121) — 화소 Q 와 **같은 규약**이고 입력만 `h` 다.
							if ((pa >= 0) && (pa < kLA) && (kAHz[arm] > 0))
							{
								double hp2[kHid] = {}, hc2[kHid] = {};
								mp[arm].Hidden(pf, hp2); mp[arm].Hidden(f, hc2);
								tl[arm].LearnV(hp2, pa, kAGam[arm] * tl[arm].Best(hc2, nAct), lrq);
							}
						if (pa >= 0 && (kAImm[arm] || kALrn[arm]))
						{
							// 🚫 **막힘에 벌을 줄까**(D98) — `kAPen` 이 0 이면 「막힘」은 **그냥 넘긴다**.
							// 🔮 **사실 부호**(D100-B) — **정책의 벌 선택과 무관하다.** 예측기는 사실을 배운다.
							//   🐛 함정 254: `kAPen[arm]` 을 예측기에도 쓰고 있었는데 그 팔이 0 이라 `sg=0` 이
							//   들어갔고, `PPol::Learn` 이 `w += lr*0*f` 로 **조용히 no-op** 이 됐다
							//   ⇒ 막힘에서 안 배워 예측이 **항상 양수**로 표류했다(recall 100% · 정확도 26.5%).
							//   ★ 오류가 아니라 **「학습 안 함」** 으로 나타나서 원인과 안 닮았다.
							const double sgF = (d < pd) ? 1.0 : -1.0;
							// 🚫 **막힘 누적**(D112) — 나아지지 않은 걸음을 센다.
							if (sgF < 0.0) blkN += 1.0;
							// 🚫 **행동별** — 「무엇을 하려다 안 통했나」.
							if ((sgF < 0.0) && (pa >= 0) && (pa < kLAX)) blkA[pa] += 1.0;
							// 🔮 **놀람 = 예측기가 틀렸나**(D114) — 「예상보다 더 막혔나」.
							//   ★ 막힘과 **같은 자리·같은 꼴**이다 ⇒ 차이는 **밀도 하나**다.
							const double sur = ((pPredV > 0.0) == (sgF > 0.0)) ? 0.0 : 1.0;
							surN += sur;
							if (pa < kLAX) surA[pa] += sur;
							// 🔮 자기 놀람율을 **그 자리에서** 갱신한다(폐회로).
							sRate[arm] += 0.001 * (sur - sRate[arm]);
							bRate[arm] += 0.001 * (((sgF < 0.0) ? 1.0 : 0.0) - bRate[arm]);
							// 📏 밀도 — 같은 분모에 둘을 센다(비교가 성립하는 유일한 꼴).
							nSg[arm][ph]++;
							if (sgF < 0.0) nBlk[arm][ph]++;
							if (sur > 0.0) nSur[arm][ph]++;
							const double sg = (d < pd) ? 1.0 : (kAPen[arm] ? -1.0 : 0.0);
							// 🔮 **예측 채점**(D99) — **ε=40% 팔에서만**(= `kA_Eps` · 행동 분포가 가장 넓다).
							//   ⚠️ 이름 상수는 판정부에서 선언되므로 여기서는 리터럴이다.
							if (kALrn[arm])
							{
								if (arm == 0) { pcN[ph]++; }
								if (arm == 0) { if ((pPredV > 0.0) == (sgF > 0.0)) pcOk[ph]++; }
								if (arm == 0) { if (sgF < 0.0) pcMaj[ph]++; }          // 「늘 막힘」이 맞은 경우
								if (arm == 0) { if (sgF > 0.0) { prN[ph]++; if (pPredV > 0.0) prOk[ph]++; } }   // recall
								prd[arm].Learn(pf, pa, sgF, lrp, kALog[arm] != 0);
								// 🧠 **같은 신호로 은닉을 기른다**(D119) — 세계가 축을 안 준다.
								if (kAHid[arm])
								{
									double hp[kHid] = {};
									mp[arm].Hidden(pf, hp);
									mp[arm].Learn(pf, hp, pa, sgF, lrp);
									// 🧩 **잠재 전이**(D121) — 직전 은닉에서 지금 은닉으로 가는 법을 배운다.
									if (kAHz[arm] > 0)
									{
										double hn2[kHid] = {};
										mp[arm].Hidden(f, hn2);
										if (pa < kLA) tl[arm].LearnT(hp, pa, hn2, lrp);
									}
								}
							}
							if (kAImm[arm] && sg != 0.0)
								pol[arm].LearnOne(pf, pjs, pa, sg, lr, true);
						}
						// 🧠 최근성 흔적을 갱신한다(고른 묶음은 오르고 나머지는 잊힌다 · λ=0.99).
						for (int j = 0; j < kGG; ++j) uu[j] *= 0.99;
						uu[jsel] += 1.0;
						// ⚖️ **argmax 관문**(D101) — 쓸 곳과 **같은 모양**으로 잰다.
						//   ⚠️⚠️ **행동을 적용하기 전에** 재야 한다 — 뒤에 두면 `cc/cx/cs` 가 이미
						//   바뀌어 오라클이 **다음 상태**를 보고 `f` 는 **이전 상태**를 본다(어긋난다).
						//   ⚠️ 채점 팔(🚪 무작위)에서만 — 고정 분포라야 팔끼리 공정하다(함정 258).
						//   ★ 무작위 대조군은 **정확히 `100/kLA`** 라 뽑지 않는다(난수열을 흐트리지 않는다).
						// 🧩 **상상 관문**(D103) — 채점 팔(🚪 무작위)에서만. 고정 분포라야 공정하다.
						//   ⚠️ 여기는 `f` 가 **막 계산됐고 행동은 아직 안 골랐다** ⇒ 직전 걸음들의
						//   상상을 **지금의 `f`** 와 견주는 자리다.
						if (md == 0 && arm == 0 && hn > 0)
						{
							const int tPrev = (hn - 1) % 5;
							double cur[kGF], nxt[kGF];
							// 🧩 **깊이별 오차** — 상대(대조군 100%)와 **절대**를 **둘 다** 찍는다.
							// ⚖️ **진실은 지금의 결정**이다 — 깊이마다 같은 것과 견준다.
							const int truth = prd[0].Argmax(f, nAct);
							for (int dd = 1; dd <= kTD && dd <= hn; ++dd)
							{
								const int s0 = (hn - dd) % 5;
								double ed = 0.0;
								for (int k = 0; k < kGF; ++k)
								{
									const double u = fh[s0][k] - f[k];      // 「안 변한다」 − 실제
									ed += u * u;
								}
								const double dRoot = (double)Sqrt((float)ed);
								tDen[dd - 1][ph] += dRoot;
								tAbsD[dd - 1] += dRoot;
								tN[dd - 1][ph]++;
								// ⚖️ **대조군** — `dd` 걸음 전 상태를 **그대로** 두었을 때의 결정.
								dcN2[dd - 1][ph]++;
								const bool cOk = (prd[0].Argmax(fh[s0], nAct) == truth);
								if (cOk) dcC2[dd - 1][ph]++;
								if (dd == kTD) { sdN4++; if (cOk) sdC4++; }
								tAbsN[dd - 1]++;
								for (int q = 0; q < kTL; ++q)
								{
									for (int k = 0; k < kGF; ++k) cur[k] = fh[s0][k];
									for (int r = 0; r < dd; ++r)
									{
										tp[q].Imagine(cur, ah[(hn - dd + r) % 5], nxt);
										for (int k = 0; k < kGF; ++k) cur[k] = nxt[k];
									}
									double en = 0.0;
									for (int k = 0; k < kGF; ++k)
									{
										const double u = cur[k] - f[k];        // 상상 − 실제
										en += u * u;
									}
									const double nRoot = (double)Sqrt((float)en);
									tNum[q][dd - 1][ph] += nRoot;
									tAbs[q][dd - 1] += nRoot;
									// ⚖️ **상상의 결정** — `dd` 번 상상한 상태에서 고른다.
									if (prd[0].Argmax(cur, nAct) == truth)
									{
										dcO2[q][dd - 1][ph]++;
										if (dd == kTD) sdO4[q]++;
									}
								}
							}
							// ⚖️ 옛 **한 걸음** 결정 관문은 걷었다(D120) — **깊이 1** 칸이 그것이고,
							//   그 값이 곧 **상한의 좁음**을 말해 준다(함정 269).
							// 🧩 배운다 — **채점을 다 한 뒤에**(채점이 학습 전 상태를 봐야 공정하다).
							for (int q = 0; q < kTL; ++q) tp[q].Learn(fh[tPrev], ah[tPrev], f, kTLr[q]);
						}
						// 🧹 **argmax 관문을 걷었다**(D123) — `arm == 2` 를 「자기 분포」로 잡았는데 `kAQ[2]=0`
						//   이라 `qp[2]` 가 **영원히 0** 이고 `Argmax` 가 늘 0 을 돌려줬다(상수 정책).
						//   ★ 그 물음은 **함정 256 으로 이미 닫혔다**(부호는 맞고 순위는 틀린다).
						// 🚪 **행동을 고른다.**
						int a = 0;
						if (kAOra[arm] > 0)
							// 🔭 **오라클** — 세계를 완벽히 알고 그 지평까지 본다(상한선).
							a = _OraclePick(nc, cc, cx, cs, gc, gx, gs, kAOra[arm], wid, tFlip);
						// 🧩 **계획으로 고른다**(D121) — 잠재 공간에서 `kAHz` 걸음을 펼친다.
						//   ★ `hz = 1` 은 계획이 없는 것(잠재 Q argmax) ⇒ **N−1 이 같은 코드**다.
						else if (kAHz[arm] > 0)
						{
							a = (RandInt(0, 100) < kAEps[arm])
								? RandInt(0, nAct) : _Plan(tl[arm], hNow, nAct, kAHz[arm]);
						}
						else if (kARol[arm] == 1)
						{
							// 🎯 **예측기가 정책이 된다** — `argmax`(쓸 곳이 이 모양이다).
							a = (RandInt(0, 100) < kAEps[arm])
								? RandInt(0, nAct) : prd[arm].Argmax(f, nAct);
						}
						else if (kARol[arm] == 2)
						{
							// 🎯 **확률로 뽑는다** — 탐험을 ε 로 밖에 두지 않고 **정책에 녹인다**.
							//   ⚠️ 로지스틱 확률을 그대로 무게로 쓴다(softmax 온도라는 손 상수를 안 만든다).
							double pw[kLAX]; double tot = 0.0;
							for (int aa = 0; aa < nAct; ++aa)
							{
								const double sv = prd[arm].Pred(f, aa);
								const double zz = (sv > 30.0) ? 30.0 : ((sv < -30.0) ? -30.0 : sv);
								pw[aa] = 1.0 / (1.0 + (double)Exp(-(float)zz));
								tot += pw[aa];
							}
							double r = (double)RandInt(0, 1000000) / 1000000.0 * tot;
							a = nAct - 1;
							for (int aa = 0; aa < nAct; ++aa)
								if ((r -= pw[aa]) <= 0.0) { a = aa; break; }
						}
						else if (kAQ[arm] && kAQAM[arm])
						{
							// 📈 Q 를 **argmax** 로(ε 탐험을 밖에 둔다).
							a = (RandInt(0, 100) < kAEps[arm])
								? RandInt(0, nAct) : qp[arm].Argmax(f, nAct);
						}
						else if (kAQ[arm])
						{
							// 📈 Q 를 **무게로 뽑는다**(D101 이 argmax 를 이겼다).
							//   ★ `Q` 는 보상이 0/1 이고 γ<1 이라 대략 [0,1] 이다 ⇒ 그대로 무게가 된다.
							//   ⚠️ 초기엔 다 0 이라 **균등**이 된다 = 탐험이 자동으로 켜지고,
							//   Q 가 갈라지면서 **저절로 줄어든다**(ε 라는 손 상수가 필요 없다).
							double qw[kLAX]; double tq2 = 0.0;
							for (int aa = 0; aa < nAct; ++aa)
							{
								const double v = qp[arm].Q(f, aa);
								qw[aa] = (v > 0.001) ? v : 0.001;
								tq2 += qw[aa];
							}
							double r2 = (double)RandInt(0, 1000000) / 1000000.0 * tq2;
							a = nAct - 1;
							for (int aa = 0; aa < nAct; ++aa)
								if ((r2 -= qw[aa]) <= 0.0) { a = aa; break; }
						}
						else if (kAImm[arm])
						{
							// 🧠 **보상 규칙**(D98 의 그 팔 — 재현 확인용).
							const MLChoice ch = pol[arm].Score(f);
							a = (RandInt(0, 100) < kAEps[arm] || ch.Margin() <= 0.0)
								? RandInt(0, nAct) : ch.Argmax();
						}
						else a = RandInt(0, nAct);          // 🚪 무작위(채점 담당)
						// 🪜 **세계의 법칙**(D97) — **크기가 최소일 때만 자리가 움직인다.**
						//   ⚠️ 확정적 if 다(학습자의 판단이 아니다) · 모든 팔에 똑같이 걸린다.
						const bool xOpen = _XOpen(cc, cs, wid);   // 🔒 한 곳에서 정한다(D105)
						// 🕳️ **숨은 비트**(D111) — 프레임에 **안 보인다.**
						//   ★ 트리거 = **크기 행동 누적 3회** ⇒ `H` 는 크기를 `2→0→2` 로
						//   **반드시 네 번** 만지므로 **`H` 에서는 항상 켜진다.**
						// 🕳️ **숨은 비트 = 에피소드 전체 고정**(D124) — 프레임에 색·자리·크기만 그려지므로
						//   **안 보인다**(닫힘 ㉣). 그리고 정책이 **원리적으로 못 건드린다**(함정 320 처방).
						const bool cFlip = tFlip;
						if (a == 0) cc = (cc + 1) % nc;
						else if (a == 1) _XAct(1, xOpen, cFlip, cx);   // 🔒 오라클과 **같은 함수**(D105)
						else if (a == 2) _XAct(2, xOpen, cFlip, cx);
						else if (a == 3) { if (cs > 0) cs--; }
						else if (a == 4) { if (cs < 2) cs++; }
						// ☠️ **추가 행동**(D108) — 종류에 따라 갈린다.
						//   · `kind=0` **no-op** : 아무 일도 없다 ⇒ 실수가 **공짜**다(`α` 가 작다)
						//   · `kind=1` **reset** : **시작 상태로 되돌린다** ⇒ 진행을 통째로 잃는다
						//     ⇒ 무작위가 경로 길이 `d` 에 대해 `(5/A)^d` 로 죽는다(**`α ≈ d`**)
						//   ★ 둘 다 **세계 법칙·깊이를 안 바꾼다** — 🔭 오라클은 이 행동을 **안 쓴다**
						//     (최적이므로) ⇒ **상한선이 고정**된다.
						else if (kind == 1) { cc = s0c; cx = s0x; cs = s0s; }
						else if (kind == 2)
						{
							// 💀 **가장 먼 곳으로**(D109) — 결정적이다(세계는 목표를 안다).
							//   ⚠️ 색은 `(gc + 1)` 이 가장 멀다 — `색+1` 이 유일한 색 행동이므로
							//   목표 **바로 다음** 색에서 목표까지 `nc − 1` 걸음이다.
							cc = (gc + 1) % nc;
							cx = (gx >= 2) ? 0 : 2;
							cs = (gs == 0) ? 2 : 0;
						}
						// 🪜 **종단 흔적에 쌓는다** — 신용은 **끝에서** 흘린다.
						// 🔮 이 걸음의 예측을 남긴다 — **다음 걸음에서 채점**한다.
						if (kALrn[arm]) pPredV = prd[arm].Pred(f, a);
						// 🧠🔮 **직전 걸음의 것**으로 넘긴다(D119) — 다음 걸음의 특징이 된다.
						if (kAHid[arm]) for (int k = 0; k < kHid; ++k) hCur[k] = hNow[k];
						if (kAPv[arm])
							for (int k = 0; k < kLA; ++k)
							{
								const double zz = prd[arm].Pred(f, k);
								const double zc = (zz > 30.0) ? 30.0 : ((zz < -30.0) ? -30.0 : zz);
								pvCur[k] = 1.0 / (1.0 + (double)Exp(-(float)zc));
							}
						if (kAEnd[arm]) tr.Push(f, a, jsel);
						// 🧩 링버퍼에 넣는다 — 행동이 정해진 **뒤**다.
						if (md == 0 && arm == 0)
						{
							const int slot = hn % 5;
							for (int k = 0; k < kGF; ++k) fh[slot][k] = f[k];
							ah[slot] = a; hn++;
						}
						for (int k = 0; k < kGF; ++k) pf[k] = f[k];
						// 🔁 누적 — **늘 센다**(보는 것만 팔로 갈린다) · λ 로 잊는다.
						for (int k = 0; k < kLAX; ++k) aCnt[k] *= kALam[arm];
						if (a < kLAX) aCnt[a] += 1.0;
						blkN *= kALam[arm];
						for (int k = 0; k < kLAX; ++k) blkA[k] *= kALam[arm];
						surN *= kALam[arm];
						for (int k = 0; k < kLAX; ++k) surA[k] *= kALam[arm];
						pa = a; pd = d; pjs = jsel;
					}
					// 🪜 **끝에서 한 낱말로 흘린다** — 도달(+1) / 상한을 다 썼다(−1).
					if (kAEnd[arm]) tr.Flush(pol[arm], hit ? 1.0 : -1.0, lamT, lr);
						nM[md][arm][ph]++; if (hit) hitM[md][arm][ph]++;
						if (md != 0) continue;               // 🎭 옛 판정은 **현행 세계**만 본다
					nP[arm][ph]++; nH2[arm][ph][hf]++;
					nF[arm][ph][tFlip ? 1 : 0]++;
					if (ph == 1) sdFN[arm][tFlip ? 1 : 0]++;
					nR[arm][ph][rep]++;
					if (ph == 3) snH[arm]++;
					if (ph == 0 && hf == 1) sN[arm][0]++;
					if (ph == 2 && hf == 0) sN[arm][1]++;
					if (hit)
					{
						hitP[arm][ph]++; hitH2[arm][ph][hf]++;
						hitF[arm][ph][tFlip ? 1 : 0]++;
						if (ph == 1) sdFH[arm][tFlip ? 1 : 0]++;   // 🔮 `B` 구간(D125)
						// 🔭 도달까지의 걸음 수 — 오라클 팔에서만 뜻이 있다(등록 ㉠).
						// 🔭 도달까지의 **행동 수**(등록 ㉠). ⚠️ `tries + 1` 은 **1 만큼 과대**다 —
						//   도달 판정이 걸음 루프 **맨 앞**이므로 `tries` 번째 반복에서 도달을 보면
						//   그때까지 **실행한 행동은 `tries` 개**다(함정 324).
						//   ★ 실측이 네 구간에서 **정확히 +1** 이었던 것이 그 증거다(3.52/2.32/3.51/6.34
						//   ↔ 손계산 2.5/1.33/2.5/5.33).
						if (kAOra[arm] > 0) { oStp[arm][ph] += tries; oStpN[arm][ph]++; }
						hitR[arm][ph][rep]++;
						if (ph == 3) shH[arm]++;
						if (ph == 0 && hf == 1) sH[arm][0]++;
						if (ph == 2 && hf == 0) sH[arm][1]++;
					}
				}
			}
			// 🔊 진행 줄 — 무음 구간을 없앤다(프로브의 대기가 조기 발화하지 않게).
			// 🔢 씨앗별 반전 수의 범위(등록 ㉤: 40/80 ± 4.47).
			if (sdFl < flSdMin) flSdMin = sdFl;
			if (sdFl > flSdMax) flSdMax = sdFl;
			// 🔮 **flip 별 씨앗 승패**(D125) — g 2·3 은 `H` 전체이고 여기서는 `B` 를 flip 으로
			//   갈라 **두 짝**을 더 만든다: 0 = `flip=0` · 1 = `flip=1`.
			for (int k = 0; k < 2; ++k)
			{
				const double a1 = (sdFN[5][k] > 0)
					? ((double)sdFH[5][k] / (double)sdFN[5][k]) : 0.0;
				const double b1 = (sdFN[1][k] > 0)
					? ((double)sdFH[1][k] / (double)sdFN[1][k]) : 0.0;
				if (a1 > b1) flW[k]++; else if (a1 < b1) flL[k]++; else flT[k]++;
			}
			// ⚖️ 깊이 4 결정 일치의 **씨앗별 승패**(상상 ↔ 대조군).
			if (sdN4 > 0)
				for (int q = 0; q < kTL; ++q)
				{
					if (sdO4[q] > sdC4) dcW[q]++;
					else if (sdO4[q] < sdC4) dcL[q]++;
					else dcT[q]++;
				}
			// 🎯 이 씨앗의 `H` 성적으로 짝별 승패를 센다(동점은 제외 · 부호검정의 표준).
			{
				double sr[kArm] = {};
				for (int q = 0; q < kArm; ++q)
					sr[q] = (snH[q] > 0) ? ((double)shH[q] / (double)snH[q]) : 0.0;
				for (int g = 0; g < kSg; ++g)
				{
					const double a = sr[kSgP[g].a], b = sr[kSgP[g].b];
					if (a > b) sgnW[g]++; else if (a < b) sgnL[g]++; else sgnT[g]++;
				}
			}
			okSd++;
			LogA("[ml]   🎲 씨앗 %d/%d 끝\n", sd + 1, kSd);
		}
		}                                          // 🎭 판 루프 끝(D104)
		if (okSd == 0) { LogA("[ml]   🎚️ ⚠️ **판정불가**\n"); return; }
		double rc[kArm][kPh] = {};
		for (int a = 0; a < kArm; ++a)
			for (int ph = 0; ph < kPh; ++ph)
				rc[a][ph] = (nP[a][ph] > 0)
					? (100.0 * (double)hitP[a][ph] / (double)nP[a][ph]) : 0.0;
		LogA("[ml]      ── 📊 **도달률**(과제군마다 %d) — A → B → A' → AB\n", kPer);
		for (int a = 0; a < kArm; ++a)
			LogA("[ml]         %s — A **%.1f%%** │ B **%.1f%%** │ A' **%.1f%%** │ AB **%.1f%%**\n",
				kAN[a], rc[a][0], rc[a][1], rc[a][2], rc[a][3]);
		// 🧹 **옛 D102 판정 블록을 걷었다**(D123 · 배관 감사) — `kA_Q9=2` 등 이름 상수가
		//   지금은 🧩 잠재 계획 팔을 가리켜 **거짓 결론**(✅✅✅ 「감쇠가 깊이를 담았다」)을
		//   찍고 있었다. 함정 285 가 `kAN[]` 로 막은 자리를 **서식 문자열의 글자 이름**이 뚫었다.
		// 🧩 **판정**(D121) — **지평 계단**(N−1 이 같은 코드다) · 🎯 씨앗별 부호검정 ·
		//   ⚠️ 평균과 부호검정을 **같이**(312) · ⚠️ 「판정불가」 분기(301).
		// 🔒 **`kG_Hz1/kG_Hz2/kG_Hz4` 를 지웠다**(D128) — D121 시절 이름이고, D126 이 팔을
		//   재배치하면서 각각 **🚫 막힘만 · 🔮 놀람만 · 🧩 잠재 지평 2** 를 가리키게 됐다.
		//   그런데 판정문이 그것을 「지평 1 → 2 → 4」로 읽어 **「⛔ 계단이 없다」는 거짓 결론**을
		//   찍었고, ㉢ 은 `sgZ[0]`(= 놀람만 ↔ 관측만)에 **「지평 4 ↔ 지평 1」 라벨**을 달았다.
		//   ⇒ **함정 285 의 다섯 번째 얼굴**이다(그 바로 위 주석이 `kA_Q9=2` 로 같은 사고를
		//   기록해 뒀는데 **아래 블록이 같은 병을 앓고 있었다**).
		// ⇒ ★ 처방은 `SgPair` 와 같다: **판정이 팔 표(`kAHz`)를 직접 읽게** 한다 ⇒ 팔을
		//   재배치해도 거짓 결론이 **원리적으로** 안 나온다.
		static const int kG_Rnd = 0, kG_Obs = 1;
		static const int kG_Both = 5, kG_O1 = 6, kG_O4 = 7;
		// ♻️ **지난 판(D123)의 값** — 갱신하는 것이 규율이다(함정 322: 낡은 `kPrev` 는 완전
		//   재현을 「⛔ 흔들렸다」로 찍는다).
		static const double kPrev[kArm] = { 20.2, 10.7, 15.2, 22.0, 9.1, 26.4,
			0.0, 100.0 };   // ♻️ 🔭 두 팔도 대조에 넣는다(D124 · 관문 배관)
		// ♻️ **이 판에서 바꾼 팔**(함정 316) — 「팔 표를 안 바꿨다」와 「그 팔이 안 바뀌었다」는
		//   **다른 사실**이다. 세계·특징 폭·목표를 바꾸면 그것을 쓰는 팔은 **바뀐 팔**이다.
		//   ⇒ 회차마다 **손으로 적는다** — 그것이 「무엇을 바꿨나」의 선언이기도 하다.
		static const int kChg[kArm] = { 0, 0, 0, 0, 0, 0, 0, 0 };   // 🔬 D127 = 판정문만 ⇒ **배관 재현이 관문**
		double rB[kArm] = {}, rA[kArm] = {}, rH[kArm] = {}, fAv[kArm] = {};
		double hR[kArm][2] = {}, thR[2] = {};
		for (int q = 0; q < kArm; ++q)
		{
			rB[q] = (nP[q][1] > 0) ? (100.0 * (double)hitP[q][1] / (double)nP[q][1]) : 0.0;
			rA[q] = (nP[q][2] > 0) ? (100.0 * (double)hitP[q][2] / (double)nP[q][2]) : 0.0;
			rH[q] = (nP[q][3] > 0) ? (100.0 * (double)hitP[q][3] / (double)nP[q][3]) : 0.0;
			fAv[q] = (fCnt[q] > 0) ? (fMag[q] / (double)fCnt[q]) : 0.0;
			for (int r = 0; r < 2; ++r)
				hR[q][r] = (nR[q][3][r] > 0)
					? (100.0 * (double)hitR[q][3][r] / (double)nR[q][3][r]) : 0.0;
		}
		for (int r = 0; r < 2; ++r)
		{
			const double n = (double)nR[kG_Rnd][3][r], p = hR[kG_Rnd][r] / 100.0;
			thR[r] = (n > 0.0)
				? (2.8284271 * 100.0 * (double)Sqrt((float)(p * (1.0 - p) / n))) : 0.0;
		}
		const double thF = 0.5 * (thR[0] + thR[1]) / 1.4142136;   // 전체 표본의 차이 문턱
		double repMax = 0.0;
		for (int q = 0; q < kArm; ++q)
		{
			if (kChg[q]) continue;                    // ♻️ 바꾼 팔은 재현 대조에서 뺀다(316)
			const double d = rH[q] - kPrev[q];
			const double ad = (d < 0.0) ? -d : d;
			if (ad > repMax) repMax = ad;
		}
		double sgZ[kSg] = {};
		for (int g = 0; g < kSg; ++g)
		{
			const int ne = sgnW[g] + sgnL[g];
			sgZ[g] = (ne > 0)
				? (((double)sgnW[g] - 0.5 * (double)ne)
					/ (double)Sqrt((float)(0.25 * (double)ne))) : 0.0;
		}
		// 🔒 라벨은 `kSgP[g].n` 에서 읽는다(D127 · 함정 331).
		// 🔒 **지평 팔을 표에서 센다**(D128) — `kAHz[q] > 0` 인 팔이 🧩 잠재 계획 팔이다.
		//   ⇒ 팔이 **둘도 안 되면 계단을 만들 수 없다** ⇒ 그때는 「판정불가」다(함정 301).
		int hzA[kArm]; int nHz = 0;
		for (int q = 0; q < kArm; ++q) if (kAHz[q] > 0) hzA[nHz++] = q;
		for (int a = 0; a < nHz; ++a)
			for (int b = a + 1; b < nHz; ++b)
				if (kAHz[hzA[b]] < kAHz[hzA[a]])
					{ const int tsw = hzA[a]; hzA[a] = hzA[b]; hzA[b] = tsw; }
		String hzTxt;
		for (int a = 0; a < nHz; ++a)
			hzTxt.AppendFormat("%s지평%d **%.1f%%**",
				(a == 0) ? " — " : " │ ", kAHz[hzA[a]], rH[hzA[a]]);
		if (nHz == 0) hzTxt.AppendFormat(" — (이 판엔 없다)");
		bool ladOk = (nHz >= 2); double ladSum = 0.0;
		for (int a = 1; a < nHz; ++a)
		{
			const double dstep = rH[hzA[a]] - rH[hzA[a - 1]];
			if (dstep < thF) ladOk = false;
			ladSum += dstep;
		}
		const double hzBest = (nHz > 0) ? rH[hzA[nHz - 1]] : 0.0;
		LogA("[ml]      ── 🧩 **잠재 공간에서 계획한다**(전이 256 곱셈 · 빔 폭 5 · 판정은 **계단**)\n"
			"[ml]         🔭 지평 1 **%.1f** · 지평 4 **%.1f**(`H`) │ 전체 차이 문턱 **%.1f%%p**\n",
			rH[kG_O1], rH[kG_O4], thF);
		for (int q = kG_Rnd; q <= kG_Both; ++q)
			LogA("[ml]         %s — `B` %.1f │ `A\'` %.1f │ `H` **%.1f%%**(전 **%.1f** │ 후 **%.1f**) │ ♻️ 지난 판 %.1f\n",
				kAN[q], rB[q], rA[q], rH[q], hR[q][0], hR[q][1], kPrev[q]);
		for (int g = 0; g < kSg; ++g)
			LogA("[ml]         🎯 %s — **%d승 %d패 %d무** │ z = **%.2f** ⇒ %s\n",
				kSgP[g].n, sgnW[g], sgnL[g], sgnT[g], sgZ[g],
				(sgZ[g] >= 2.576) ? "✅✅ **p < 0.01**"
					: ((sgZ[g] >= 1.96) ? "✅ **p < 0.05**"
						: ((sgZ[g] >= 0.0) ? "⚠️ **판정불가**(방향은 맞다)"
							: "⛔ **반대 방향**")));
		LogA("[ml]      ♻️ ㉠ **비트 재현**(새 팔 셋 제외) — 최대 오차 **%.2f%%p** ⇒ %s\n"
			"[ml]      🧩 ㉡ **지평 계단이 서나** — 이 판의 🧩 지평 팔 **%d개**%s ⇒ %s\n"
			"[ml]      📈 ㉣ **절대 성적이 「둘 다」를 넘나**(등록: **못 넘는다**) — 지평 4 **%.1f** ↔ 둘 다 **%.1f%%** ⇒ %s\n"
			"[ml]      ⇒ %s\n",
			repMax,
			(repMax <= 0.05) ? "✅✅✅ ***같다***"
				: ((repMax <= 1.0) ? "✅ 근접" : "⛔ 흔들렸다 ⇒ 아래를 읽지 마라"),
			nHz, hzTxt.ptr(),
			(nHz < 2)
				? "⛔ **판정불가 — 계단을 만들 팔이 둘도 안 된다.** ⚠️ 옛 판정문은 이 자리에서 `kG_Hz*` 이름 상수로 **엉뚱한 팔 셋**을 읽어 「계단이 없다」를 찍었다(D128 이 잡았다 · 함정 285 의 다섯째 얼굴)"
				: (ladOk
					? "✅✅✅ ***계단이 섰다*** — 각 단이 문턱 이상"
					: ((ladSum >= thF)
						? "⚠️ **부분** — 합은 넘지만 각 단이 다 넘지는 않는다"
						: "⛔ **계단이 없다** — 잠재 전이가 세계를 못 담는다")),
			hzBest, rH[kG_Both],
			(hzBest >= rH[kG_Both] + thF)
				? "✅✅✅ ***넘었다*** — 등록보다 강하다(16칸 압축인데도)"
				: "⚠️ **못 넘는다** — 등록대로다(압축의 대가)",
			(nHz < 2)
				? "★ **이 판은 지평 축을 안 물었다** ⇒ 계단은 🧩 지평 팔을 **둘 이상** 둔 판에서 잰다"
				: (ladOk ? "✅✅✅ ***계획이 값을 한다*** ⇒ 다음은 **압축을 늘린다**"
					: "★ 숫자대로 적는다 — 계단이 부분이거나 없다"));
		//   ㉢㉣㉤ 가 「비트 없음」으로 나오는 것이 **정상**이다(그것이 이 판의 관문이다).
		static const int kH_Rnd = 0, kH_Obs = 1, kH_O4 = 7;
		double rH2O[kPh] = {};
		for (int q2 = 0; q2 < kPh; ++q2)
			rH2O[q2] = (nP[kH_O4][q2] > 0)
				? (100.0 * (double)hitP[kH_O4][q2] / (double)nP[kH_O4][q2]) : 0.0;
		// 🔭 오라클 걸음 수.
		double oS[kPh] = {};
		for (int q2 = 0; q2 < kPh; ++q2)
			oS[q2] = (oStpN[kH_O4][q2] > 0)
				? ((double)oStp[kH_O4][q2] / (double)oStpN[kH_O4][q2]) : 0.0;
		// 🕳️ flip 부분집단 — `B`(구간 1)에서 `arm 1`(깨끗한 N−1).
		double fB[2] = {}, fH[2] = {};
		for (int k = 0; k < 2; ++k)
		{
			fB[k] = (nF[kH_Obs][1][k] > 0)
				? (100.0 * (double)hitF[kH_Obs][1][k] / (double)nF[kH_Obs][1][k]) : 0.0;
			fH[k] = (nF[kH_Obs][3][k] > 0)
				? (100.0 * (double)hitF[kH_Obs][3][k] / (double)nF[kH_Obs][3][k]) : 0.0;
		}
		const double gapB = (fB[0] > fB[1]) ? (fB[0] - fB[1]) : (fB[1] - fB[0]);
		const double gapH = (fH[0] > fH[1]) ? (fH[0] - fH[1]) : (fH[1] - fH[0]);
		const double flRate = ((nFl[0] + nFl[1]) > 0)
			? (100.0 * (double)nFl[1] / (double)(nFl[0] + nFl[1])) : 0.0;
		// 📏 구간×반절×flip 의 차이 문턱(등록: p≈0.5 · n=1200 ⇒ 2σ_diff = 4.1%p).
		// 🔢 **해시 위생의 기대값을 계산한다**(D128) — ⚠️ 예전엔 손 상수 `40 ± 4.47`
		//   (통과 조건 `26~54`)였는데 그것은 **80 과제 창**의 값이다. 분모는 `kPh*kPer`
		//   = **320** 이므로 기대 **160** · σ = √(320·0.25) = **8.94** ⇒ 3σ = **26.8**.
		//   ⇒ 실측 130~177 을 「⛔⛔ 이 판은 무효다」로 찍고 있었다 — **거짓 경보**다.
		//   ★ 그리고 반전율(49.73% ↔ 50.0±0.36)은 **통과**했다 ⇒ 해시는 멀쩡했다.
		//   ⇒ **손으로 적지 않고 분모에서 낸다** — `kPer`/`kPh` 를 갈아도 안 어긋난다.
		const double flExp = 0.5 * (double)(kPh * kPer);
		const double flTol = 3.0 * (double)Sqrt((float)(0.25 * (double)(kPh * kPer)));
		// 📏 **60씨앗의 극값 기대 대역** — 정규 순서통계량으로 `E[min] ≈ μ − 2.32σ`(n=60).
		//   ⇒ 이것은 **판정이 아니라 읽는 눈금**이다(그 대역 안이면 「정상」으로 읽는다).
		const double flExt = 2.32 * (flTol / 3.0);
		const double thFl = 4.1;
		const double dRnd = rH[kH_Rnd] - kPrev[kH_Rnd];
		const double aRnd = (dRnd < 0.0) ? -dRnd : dRnd;
		LogA("[ml]      ── 🕳️ **트리거를 정책이 닿을 수 없는 자리로**(판 %s · `szN` 축 삭제)\n"
			"[ml]      🔭 ㉠ **오라클이 최적으로 돌아왔나** — 지평 4 성적 **%.1f / %.1f / %.1f / %.1f%%** │ 걸음 **%.2f / %.2f / %.2f / %.2f**(`H` 등록 **5.33** · 옛 8) ⇒ %s\n"
			"[ml]      🚪 ㉡ **무작위가 잡음 안인가** — `H` **%.1f%%** ↔ D123 **%.1f%%**(차 **%+.1f%%p** · 구간 2σ **1.44**) ⇒ %s\n"
			"[ml]      🔢 ㉤ **해시 위생** — 반전율 **%.2f%%**(기대 50.0 ± 0.36) · 씨앗당 **%d~%d**(기대 **%.0f** · %d씨앗의 극값은 자연히 **%.0f~%.0f** 대역이다 · 분모 **%d**) ⇒ %s\n"
			"[ml]      🕳️ ㉣ **flip 부분집단**(📈 관측만 · 깨끗한 N−1) — `B` **%.1f ↔ %.1f%%**(격차 **%.1f**) │ `H` **%.1f ↔ %.1f%%**(격차 **%.1f** · 문턱 **%.1f%%p**) ⇒ %s\n"
			"[ml]      ⇒ %s\n",
			kFlipOn ? "1(비트 켬)" : "0-a(**비트 없음**)",
			rH2O[0], rH2O[1], rH2O[2], rH2O[3],
			oS[0], oS[1], oS[2], oS[3],
			((rH2O[0] >= 99.0) && (rH2O[1] >= 99.0) && (rH2O[2] >= 99.0)
				&& (rH2O[3] >= 99.0) && (oS[3] <= 6.0))
				? "✅✅✅ ***돌아왔다*** — 네 구간 100% 이고 `H` 걸음이 5.33 대역이다"
				: ((rH2O[3] < 99.0)
					? "⛔⛔ **100% 가 깨졌다** ⇒ 동형사상 논증이 틀렸거나 타이브레이크가 개입했다"
					: "⚠️ 100% 는 섰는데 걸음이 5.33 이 아니다 ⇒ 정체 제거를 잘못 읽었다"),
			rH[kH_Rnd], kPrev[kH_Rnd], dRnd,
			(aRnd <= 1.44) ? "✅ **잡음 안** — 라벨 교환 불변이 섰다"
				: "⛔ **벗어났다** ⇒ 배선 버그(벽 클램프·`kCap` 상호작용)",
			flRate, flSdMin, flSdMax, flExp, kSd, flExp - flExt, flExp + flExt, kPh * kPer,
			(!kFlipOn) ? "— 판 0-a 라 0% 가 정상이다"
				: (((flRate >= 49.5) && (flRate <= 50.5)
					)
					// 🔒 **min/max 를 판정에서 뺐다**(D128 · 세 번째 정정) — 극값에 단일표본 문턱을
					//   걸면 **표본이 많을 때 반드시 걸린다**(실측: min 130 = μ−3.36σ 인데 max 177 은
					//   μ+1.90σ 로 **기대보다 작다** ⇒ 한쪽만 「이상」일 수가 없다 = 검정이 틀린 것).
					//   ⇒ 판정은 **전체 반전율**(표본 19,200 · σ 0.36%p)로 한다 — 훨씬 강하다.
					? "✅ **균형이다**" : "⛔⛔ **해시가 관측 축과 상관됐다 ⇒ 이 판은 무효다**"),
			fB[0], fB[1], gapB, fH[0], fH[1], gapH, thFl,
			(!kFlipOn) ? "— 판 0-a 라 한쪽이 비어 있는 것이 정상이다"
				: ((gapB <= thFl)
					? "★ **격차가 문턱 안** — ⚠️ 절대 수준을 같이 읽어라(둘 다 낮으면 「양쪽 다 망가졌다」이고 같이 0 이다)"
					: "★ **격차가 크다** — 방향을 외웠고 믿음이 없다(부호는 등록하지 않았다)"),
			(!kFlipOn)
				? (((rH2O[3] >= 99.0) && (oS[3] <= 6.0) && (aRnd <= 1.44))
					? "✅✅✅ ***판 0-a 가 섰다*** — 정체 제거가 단독으로 확인됐다 ⇒ **판 1 로 간다**"
					: "⛔⛔ **판 0-a 가 안 섰다** ⇒ **판 1 의 숫자를 읽지 않는다**")
				: "★ 판 1 — ㉢㉣ 를 위 표와 같이 읽는다");
		// 🔮 **판정**(D125) — 이득이 `flip=1` 에 몰려 있나(기제의 시험).
		//   ⚠️ 「격차 작음」은 절대 수준과 **같이** 읽는다(함정 326).
		static const int kI_Obs = 1, kI_Both = 5;
		double bB[2] = {}, oB[2] = {}, bH2[2] = {}, oH2[2] = {};
		for (int k = 0; k < 2; ++k)
		{
			bB[k] = (nF[kI_Both][1][k] > 0)
				? (100.0 * (double)hitF[kI_Both][1][k] / (double)nF[kI_Both][1][k]) : 0.0;
			oB[k] = (nF[kI_Obs][1][k] > 0)
				? (100.0 * (double)hitF[kI_Obs][1][k] / (double)nF[kI_Obs][1][k]) : 0.0;
			bH2[k] = (nF[kI_Both][3][k] > 0)
				? (100.0 * (double)hitF[kI_Both][3][k] / (double)nF[kI_Both][3][k]) : 0.0;
			oH2[k] = (nF[kI_Obs][3][k] > 0)
				? (100.0 * (double)hitF[kI_Obs][3][k] / (double)nF[kI_Obs][3][k]) : 0.0;
		}
		const double gB0 = bB[0] - oB[0], gB1 = bB[1] - oB[1];
		const double gH0 = bH2[0] - oH2[0], gH1 = bH2[1] - oH2[1];
		const double thFS = 2.9;   // 구간×flip 2,400 ⇒ 2σ_diff
		double zF[2] = {};
		for (int k = 0; k < 2; ++k)
		{
			const int ne = flW[k] + flL[k];
			zF[k] = (ne > 0)
				? (((double)flW[k] - 0.5 * (double)ne)
					/ (double)Sqrt((float)(0.25 * (double)ne))) : 0.0;
		}
		LogA("[ml]      ── 🔮 **놀람 × 숨은 상태**(이득이 `flip=1` 에 몰려 있나 — 기제의 시험)\n"
			"[ml]         `B` — 📈 관측만 **%.1f ↔ %.1f%%**(격차 %.1f) │ 📈 둘 다 **%.1f ↔ %.1f%%**(격차 %.1f)  [flip 0 ↔ 1]\n"
			"[ml]         `H` — 📈 관측만 **%.1f ↔ %.1f%%** │ 📈 둘 다 **%.1f ↔ %.1f%%**\n"
			"[ml]      ㉡ **같은 「격차 작음」이 두 팔에서 다른 뜻인가** — 관측만은 **%.0f 대**(부분집단 상쇄) · 둘 다는 **%.0f 대** ⇒ %s\n"
			"[ml]      ★ ㉢ **이득이 `flip=1` 에 몰려 있나** — `B` flip0 **%+.1f** → flip1 **%+.1f**(차 **%+.1f** · 문턱 %.1f) │ `H` **%+.1f** → **%+.1f**(차 **%+.1f**) ⇒ %s\n"
			"[ml]      🎯 ㉣ **씨앗별**(`B` · 둘 다 ↔ 관측만) — flip0 **%d승 %d패 %d무**(z **%.2f**) │ flip1 **%d승 %d패 %d무**(z **%.2f**) ⇒ %s\n"
			"[ml]      ⇒ %s\n",
			oB[0], oB[1], oB[1] - oB[0], bB[0], bB[1], bB[1] - bB[0],
			oH2[0], oH2[1], bH2[0], bH2[1],
			0.5 * (oB[0] + oB[1]), 0.5 * (bB[0] + bB[1]),
			((0.5 * (bB[0] + bB[1])) >= (0.5 * (oB[0] + oB[1])) + 10.0)
				? "✅ **다르다** — 둘 다는 「격차 작고 둘 다 높다」(식별) · 관측만은 「둘 다 낮다」(상쇄)"
				: "⚠️ 절대 수준이 비슷하다 ⇒ 두 팔이 같은 상태다",
			gB0, gB1, gB1 - gB0, thFS, gH0, gH1, gH1 - gH0,
			((gB1 - gB0) >= thFS)
				? "✅✅✅ ***몰려 있다*** — 놀람의 이득이 **숨은 상태에서 더 크다**(기제 확인)"
				: (((gB1 - gB0) >= 0.0)
					? "⚠️ **판정불가** — 방향은 맞지만 문턱 미만 ⇒ 「흡수는 확인 · 기제는 미결」"
					: "⛔ **반대 방향** — 놀람의 이득은 숨은 상태와 무관하다 ⇒ 다른 원인을 찾는다"),
			flW[0], flL[0], flT[0], zF[0], flW[1], flL[1], flT[1], zF[1],
			((zF[1] >= 2.576) && (zF[1] > zF[0]))
				? "✅✅ **flip1 쪽이 더 강하다**(p < 0.01)"
				: ((zF[1] >= 2.576) ? "✅ 둘 다 강하다 — 기제의 증거는 아니다"
					: "⚠️ 판정불가"),
			(((gB1 - gB0) >= thFS) && (zF[1] > zF[0]))
				? "✅✅✅ ***두 갈래가 만났다*** — 숨은 상태가 놀람을 **더 값지게** 만든다"
				: (((gB1 - gB0) >= 0.0)
					? "★ **흡수는 확인됐고 기제는 미결이다** ⇒ 표본을 늘려 ㉢ 을 굳힌다"
					: "⛔ **기제가 아니다** ⇒ D124 의 +4.3%p 의 다른 원인을 찾는다"));
		// 🔬 **판정**(D126) — 성분을 갈라 흡수의 주인을 찾는다.
		static const int kJ_Obs = 1, kJ_Blk = 2, kJ_Sur = 3, kJ_Both = 5;
		// 구간 4,800 ⇒ 차이 문턱 1.4%p · 구간×flip 2,400 ⇒ 2.0%p
		static const double thJ = 1.4, thJF = 2.0;
		double jB[kArm] = {}, jF[kArm][2] = {};
		for (int q = 0; q < kArm; ++q)
		{
			jB[q] = (nP[q][1] > 0)
				? (100.0 * (double)hitP[q][1] / (double)nP[q][1]) : 0.0;
			for (int k = 0; k < 2; ++k)
				jF[q][k] = (nF[q][1][k] > 0)
					? (100.0 * (double)hitF[q][1][k] / (double)nF[q][1][k]) : 0.0;
		}
		const double aSur = jB[kJ_Sur] - jB[kJ_Obs];
		const double aBlk = jB[kJ_Blk] - jB[kJ_Obs];
		const double aBth = jB[kJ_Both] - jB[kJ_Obs];
		const double gSur = (jF[kJ_Sur][0] > jF[kJ_Sur][1])
			? (jF[kJ_Sur][0] - jF[kJ_Sur][1]) : (jF[kJ_Sur][1] - jF[kJ_Sur][0]);
		const double gBlk = (jF[kJ_Blk][0] > jF[kJ_Blk][1])
			? (jF[kJ_Blk][0] - jF[kJ_Blk][1]) : (jF[kJ_Blk][1] - jF[kJ_Blk][0]);
		// 🔬 **구간 넷 전부**(D127 · 함정 330) — 뒤집힘을 놓칠 수 없게 한다.
		static const char* kPhN2[kPh] = { "A  색만", "B  자리만", "A' 색만", "H  선행" };
		LogA("[ml]      ── 🔬 **성분을 구간별로**(🚫 막힘만 ↔ 🔮 놀람만 · 깊이가 순서를 정하나)\n");
		for (int q2 = 0; q2 < kPh; ++q2)
		{
			const double o2 = (nP[kJ_Obs][q2] > 0)
				? (100.0 * (double)hitP[kJ_Obs][q2] / (double)nP[kJ_Obs][q2]) : 0.0;
			const double b2 = (nP[kJ_Blk][q2] > 0)
				? (100.0 * (double)hitP[kJ_Blk][q2] / (double)nP[kJ_Blk][q2]) : 0.0;
			const double s2 = (nP[kJ_Sur][q2] > 0)
				? (100.0 * (double)hitP[kJ_Sur][q2] / (double)nP[kJ_Sur][q2]) : 0.0;
			const double t2 = (nP[kJ_Both][q2] > 0)
				? (100.0 * (double)hitP[kJ_Both][q2] / (double)nP[kJ_Both][q2]) : 0.0;
			LogA("[ml]         %s — 📈 %.1f%% │ 🚫 **%+.1f** │ 🔮 **%+.1f** │ 둘 다 **%+.1f%%p** ⇒ %s\n",
				kPhN2[q2], o2, b2 - o2, s2 - o2, t2 - o2,
				(((s2 - o2) - (b2 - o2)) >= thJ) ? "🔮 **놀람이 낫다**"
					: ((((b2 - o2) - (s2 - o2)) >= thJ) ? "🚫 **막힘이 낫다**" : "⚠️ 구별 안 된다"));
		}
		LogA("[ml]      ── 🔬 **흡수의 주인은 누구인가**(성분을 갈라 잰다 · `B` 구간)\n"
			"[ml]         📈 관측만 **%.1f%%**(flip **%.1f ↔ %.1f**) │ 🚫 막힘만 **%.1f**(**%.1f ↔ %.1f**) │ 🔮 놀람만 **%.1f**(**%.1f ↔ %.1f**) │ 🚫+🔮 둘 다 **%.1f**(**%.1f ↔ %.1f**)\n"
			"[ml]      🔮 ㉡ **놀람만이 흡수하나** — 관측만 대비 **%+.1f%%p**(등록 ≥ 10) │ flip 격차 **%.1f**(문턱 %.1f) ⇒ %s\n"
			"[ml]      🚫 ㉢ **막힘만은 덜 흡수하나** — **%+.1f%%p**(놀람만과 차 **%+.1f** · 문턱 %.1f) │ flip 격차 **%.1f** ⇒ %s\n"
			"[ml]      🧩 ㉤ **합이 성분을 넘나**(`AND`) — 둘 다 **%+.1f%%p** ↔ 🔮 **%+.1f** · 🚫 **%+.1f** ⇒ %s\n"
			"[ml]      ⇒ %s\n",
			jB[kJ_Obs], jF[kJ_Obs][0], jF[kJ_Obs][1],
			jB[kJ_Blk], jF[kJ_Blk][0], jF[kJ_Blk][1],
			jB[kJ_Sur], jF[kJ_Sur][0], jF[kJ_Sur][1],
			jB[kJ_Both], jF[kJ_Both][0], jF[kJ_Both][1],
			aSur, gSur, thJF,
			((aSur >= 10.0) && (gSur <= thJF))
				? "✅✅ **흡수한다** — 크게 높고 flip 격차가 작다(식별)"
				: ((aSur >= 10.0) ? "⚠️ 높지만 flip 격차가 크다 ⇒ 방향을 외웠다"
					: "⛔ **못 흡수한다**"),
			aBlk, aSur - aBlk, thJ, gBlk,
			((aSur - aBlk) >= thJ)
				? "✅✅✅ ***놀람이 더 낫다*** — **흡수는 놀람의 것**이다(기제 확인)"
				: (((aBlk - aSur) >= thJ)
					? "⛔⛔ **막힘이 더 낫다** ⇒ 흡수는 놀람의 것이 아니다"
					: "⚠️ **판정불가** — 두 성분이 구별 안 된다 ⇒ 「이력 특징 일반」이 흡수한다"),
			aBth, aSur, aBlk,
			((aBth >= aSur + thJ) && (aBth >= aBlk + thJ))
				? "✅✅ **둘 다 넘는다** — 서로 다른 것을 담는다"
				: "⚠️ 한쪽만 넘거나 못 넘는다(`AND` 로 판정했다 · 286)",
			((aSur - aBlk) >= thJ)
				? "✅✅✅ ***기제가 섰다*** — 숨은 상태의 어긋남을 **놀람이** 잡는다"
				: (((aBlk - aSur) >= thJ)
					? "⛔⛔ **기제가 아니다** — 막힘이 더 낫다 ⇒ D124 의 신호는 놀람 특유가 아니다"
					: "★ **흡수는 「이력 특징 일반」의 것이다** ⇒ 놀람 특유가 아니라고 적는다"));
				// 🔬 **깊이가 순서를 정하나**(D127 ㉣) — 얕은 셋 ↔ `H`.
				{
					double dv[kPh] = {};
					for (int q2 = 0; q2 < kPh; ++q2)
					{
						const double b2 = (nP[kJ_Blk][q2] > 0)
							? (100.0 * (double)hitP[kJ_Blk][q2] / (double)nP[kJ_Blk][q2]) : 0.0;
						const double s2 = (nP[kJ_Sur][q2] > 0)
							? (100.0 * (double)hitP[kJ_Sur][q2] / (double)nP[kJ_Sur][q2]) : 0.0;
						dv[q2] = s2 - b2;   // 🔮 − 🚫
					}
					const bool shallowBlk = (dv[0] <= thJ) && (dv[1] <= thJ) && (dv[2] <= thJ);
					LogA("[ml]      🔬 ㉣ **깊이가 순서를 정하나**(🔮 − 🚫) — A **%+.1f** │ B **%+.1f** │ A' **%+.1f** │ **H %+.1f%%p** ⇒ %s\n"
						"[ml]      ⇒ %s\n",
						dv[0], dv[1], dv[2], dv[3],
						(shallowBlk && (dv[3] >= thJ))
							? "✅✅✅ ***깊이가 순서를 정한다*** — 얕은 셋은 🚫 · `H` 는 🔮"
							: ((dv[3] >= thJ)
								? "⚠️ `H` 는 🔮 인데 얕은 구간에서도 🔮 가 낫다 ⇒ 갈리는 축이 **깊이가 아니다**"
								: "⛔ `H` 에서도 🔮 가 안 낫다 ⇒ D126 이 재현되지 않았다"),
						(shallowBlk && (dv[3] >= thJ))
							? "✅✅✅ ***네 구간으로 섰다*** — 「막혔나」는 그 걸음의 사실이고 「예상보다 더 막혔나」는 **여러 걸음에 걸친 어긋남**이다"
							: "★ 숫자대로 적는다");
				}
		// ⚖️ **깊이별 결정 관문**(D120) — 대조군을 나란히 둬 **상한**을 먼저 보인다(269).
		double dcRel[kTL][kTD] = {}, dcCtlR[kTD] = {};
		for (int d = 0; d < kTD; ++d)
		{
			double n = 0.0, c = 0.0, o[kTL] = {};
			for (int p2 = 0; p2 < kPh; ++p2)
			{
				n += (double)dcN2[d][p2]; c += (double)dcC2[d][p2];
				for (int q = 0; q < kTL; ++q) o[q] += (double)dcO2[q][d][p2];
			}
			if (n <= 0.0) continue;
			dcCtlR[d] = 100.0 * c / n;
			for (int q = 0; q < kTL; ++q) dcRel[q][d] = 100.0 * o[q] / n;
		}
		// ★ 깊이 4 에서 **가장 나은 lr** 을 고른다(그 자리에서 판정한다).
		int qB = 0;
		for (int q = 1; q < kTL; ++q) if (dcRel[q][kTD - 1] > dcRel[qB][kTD - 1]) qB = q;
		const double head = 100.0 - dcCtlR[kTD - 1];             // ⚖️ 상한(대조군이 남긴 여백)
		const double gain = dcRel[qB][kTD - 1] - dcCtlR[kTD - 1];
		// 🎯 씨앗별 부호검정(깊이 4 · 가장 나은 lr).
		const int neD = dcW[qB] + dcL[qB];
		const double zD = (neD > 0)
			? (((double)dcW[qB] - 0.5 * (double)neD)
				/ (double)Sqrt((float)(0.25 * (double)neD))) : 0.0;
		// 📏 **되살린 계측 ㉠ — 신호 밀도**(D123). `nSg`/`nBlk`/`nSur` 는 계속 세고 있었는데
		//   **읽는 곳이 0개**였다(D120 이 로그를 갈 때 딸려 죽었다).
		double dnB2[kArm] = {}, dnS2[kArm] = {};
		for (int q = 0; q < kArm; ++q)
		{
			const double n = (double)nSg[q][3];
			if (n <= 0.0) continue;
			dnB2[q] = 100.0 * (double)nBlk[q][3] / n;
			dnS2[q] = 100.0 * (double)nSur[q][3] / n;
		}
		// 🧩 **되살린 계측 ㉡ — 상상의 절대오차**. 깊이 비교는 상대가 아니라 절대다(함정 266).
		//   ⚠️ `kGF` 가 커지면 노름도 커진다 ⇒ **비율**로 읽는다.
		double eImg[kTL][kTD] = {}, eCtl[kTD] = {};
		for (int d = 0; d < kTD; ++d)
		{
			if (tAbsN[d] <= 0) continue;
			eCtl[d] = tAbsD[d] / (double)tAbsN[d];
			for (int q = 0; q < kTL; ++q) eImg[q][d] = tAbs[q][d] / (double)tAbsN[d];
		}
		int eB = 0;
		for (int q = 1; q < kTL; ++q) if (eImg[q][kTD - 1] < eImg[eB][kTD - 1]) eB = q;
		LogA("[ml]      📏 **되살린 밀도**(`H` · 같은 분모) — 📈 관측만: 🚫 **%.1f%%** ↔ 🔮 **%.1f%%** │ 📈 둘 다: 🚫 **%.1f%%** ↔ 🔮 **%.1f%%** │ 🔭 지평 4: 🚫 **%.1f%%** ↔ 🔮 **%.1f%%**\n"
			"[ml]      🧩 **되살린 절대오차**(최고 lr %.4f) — 깊이 1~4 상상 **%.3f / %.3f / %.3f / %.3f** ↔ 🚫 안 변한다 **%.3f / %.3f / %.3f / %.3f**(깊이 4 비 **%.2f**)\n",
			dnB2[1], dnS2[1], dnB2[5], dnS2[5], dnB2[7], dnS2[7],
			kTLr[eB], eImg[eB][0], eImg[eB][1], eImg[eB][2], eImg[eB][3],
			eCtl[0], eCtl[1], eCtl[2], eCtl[3],
			(eCtl[3] > 0.0) ? (eImg[eB][3] / eCtl[3]) : 0.0);
		LogA("[ml]      ── ⚖️ **깊이별 결정 관문**(자를 먼저 만든다 · 상상기는 안 고쳤다)\n"
			"[ml]         🚫 **안 변한다**(대조군) — 깊이 1~4: **%.1f / %.1f / %.1f / %.1f%%** ⇒ 깊이 4 의 **상한 %.1f%%p**\n",
			dcCtlR[0], dcCtlR[1], dcCtlR[2], dcCtlR[3], head);
		for (int q = 0; q < kTL; ++q)
			LogA("[ml]         🧩 상상 lr %.4f — 깊이 1~4: **%.1f / %.1f / %.1f / %.1f%%**(깊이 4 이득 **%+.1f%%p**)\n",
				kTLr[q], dcRel[q][0], dcRel[q][1], dcRel[q][2], dcRel[q][3],
				dcRel[q][kTD - 1] - dcCtlR[kTD - 1]);
		LogA("[ml]      ⚖️ ㉠ **대조군이 깊이와 함께 떨어지나**(관문이 쓸 만해지는 조건) — 깊이 1 **%.1f%%** → 깊이 4 **%.1f%%**(상한 **%.1f%%p**) ⇒ %s\n"
			"[ml]      🧩 ㉡ **깊이 4 에서 상상이 대조군을 넘나**(최고 lr %.4f) — **%.1f** ↔ **%.1f%%**(**%+.1f%%p**) ⇒ %s\n"
			"[ml]      🎯 ㉢ **씨앗별 부호검정**(깊이 4) — **%d승 %d패 %d무** │ z = **%.2f** ⇒ %s\n"
			"[ml]      ⇒ %s\n",
			dcCtlR[0], dcCtlR[3], head,
			(head >= 12.0) ? "✅ **떨어진다** — 자가 쓸 만해졌다"
				: ((head >= 5.0) ? "⚠️ 조금 떨어진다 — 자가 여전히 좁다"
					: "⛔⛔ **안 떨어진다** ⇒ 결정 일치율 자체가 **못 쓰는 자**다"),
			kTLr[qB], dcRel[qB][kTD - 1], dcCtlR[kTD - 1], gain,
			(gain >= 3.0) ? "✅✅ **넘는다**"
				: ((gain >= 0.0) ? "⚠️ **판정불가**(방향은 맞다)"
					: "⛔ **못 넘는다** — 옛 목표(오차)로 기른 상상은 결정에 못 닿는다"),
			dcW[qB], dcL[qB], dcT[qB], zD,
			(zD >= 2.576) ? "✅✅ **p < 0.01**"
				: ((zD >= 1.96) ? "✅ **p < 0.05**"
					: ((zD >= 0.0) ? "⚠️ **판정불가**(방향은 맞다)" : "⛔ **반대 방향**")),
			(head < 5.0)
				? "⛔⛔ **자를 다시 만든다** — 관문을 다른 축으로 옮긴다"
				: ((zD >= 1.96)
					? "✅✅✅ ***옛 목표로도 결정에 닿는다*** ⇒ 목표를 갈면 더 커질 자리가 있다"
					: "★ **자는 생겼고 옛 목표는 결정에 안 닿는다** ⇒ **목표를 「결정 인식」으로 간다**(함정 268 의 처방)"));
		// 🔮 **관문 — 예측이 맞나**(D99). 깊이 1 = 구간 2(`A'`) · 깊이 2 = 구간 3(`H`).
		double acc[kPh] = {}, maj[kPh] = {}, rec[kPh] = {};
		for (int q = 0; q < kPh; ++q)
		{
			acc[q] = (pcN[q] > 0) ? (100.0 * (double)pcOk[q] / (double)pcN[q]) : 0.0;
			maj[q] = (pcN[q] > 0) ? (100.0 * (double)pcMaj[q] / (double)pcN[q]) : 0.0;
			rec[q] = (prN[q] > 0) ? (100.0 * (double)prOk[q] / (double)prN[q]) : 0.0;
		}
		LogA("[ml]      ── 🔮 **한 걸음 예측기**(관문 · ε=40%% 팔에서 채점)\n"
			"[ml]         구간 A' — 정확도 **%.1f%%** ↔ 「늘 막힘」 %.1f%%(**%+.1f%%p**) │"
			" **recall %.1f%%**(걸음 %d)\n"
			"[ml]         구간 H  — 정확도 **%.1f%%** ↔ 「늘 막힘」 %.1f%%(**%+.1f%%p**) │"
			" **recall %.1f%%**(걸음 %d)\n"
			"[ml]      🔮 ㉠ **정확도가 최빈을 넘나**(A') — %+.1f%%p(문턱 ≥ 10.0) ⇒ %s\n"
			"[ml]      🔮 ㉡ **recall**(A') — **%.1f%%**(문턱 ≥ 50.0 · 최빈 예측은 0%%) ⇒ %s\n"
			"[ml]      🔮 ㉢ **`H` 에서도 서나**(recall) — **%.1f%%**(문턱 ≥ 30.0) ⇒ %s\n"
			"[ml]      ⇒ %s\n",
			acc[2], maj[2], acc[2] - maj[2], rec[2], prN[2],
			acc[3], maj[3], acc[3] - maj[3], rec[3], prN[3],
			acc[2] - maj[2],
			(acc[2] - maj[2] >= 10.0) ? "✅ **넘는다**" : "⚠️ **최빈과 겹친다**(정확도로는 못 잰다)",
			rec[2],
			(rec[2] >= 50.0) ? "✅✅ **나아짐을 찾아낸다**" : "⛔ **못 찾는다**",
			rec[3],
			(rec[3] >= 30.0) ? "✅✅ **`H` 에서도 예측이 선다** ⇒ 계획으로 갈 수 있다"
				: "⛔ **`H` 에서는 예측조차 안 선다** ⇒ 계획 전에 **예측기부터** 고쳐야 한다",
			((rec[2] >= 50.0) && (rec[3] >= 30.0))
				? "✅✅✅ ***관문 통과*** — 예측이 서므로 **지평 4 계획**으로 간다"
				: "⚠️ 관문 미달 — 무엇이 부족한지 보고 예측기를 고친다");
		const int thUp = 8;
		// 🏁 **끝 표지**(함정 342) — 밖의 탐침이 이것만 보고 끝낸다. ⚠️ **공백 없음**(함정 343).
		LogA("[ml] 🏁 SPARSEDONE\n");
	}

	// 🛡️ 지금 **가장 크게 말하는 묶음**(D88) — **입력이** 고른다(오라클이 아니다).
	static int _LoudGroup(const double* f)
	{
		int m = 0; double best = -1.0;
		for (int j = 0; j < kGG; ++j)
		{
			double s = 0.0;
			for (int k = _GLo(j); k < _GLo(j + 1); ++k)
				s += (f[k] < 0.0) ? -f[k] : f[k];
			if (s > best) { best = s; m = j; }
		}
		return m;
	}

	// 🎚️ **어느 묶음들을 갱신하나**(D91) — `k` 개를 `mode` 로 고른다.
	//   mode 0 무작위 · 1 라운드로빈 · 2 고정(묶음 2 부터) · 3 입력이 고른다(k=1)
	//   mode 4 = **입력 ÷ (1 + 최근성)** — 지속 흔적으로 다양성을 관리한다(D93).
	static void _PickGroups(int k, int mode, const double* f, const double* u,
		int& rr, bool* sel)
	{
		for (int j = 0; j < kGG; ++j) sel[j] = false;
		if (mode == 3) { sel[_LoudGroup(f)] = true; return; }
		if (mode == 4)
		{
			// 🧠 **입력이 말하는 양 ÷ (1 + 최근성)** — 최근에 많이 고른 묶음은 눌린다.
			int m = 0; double best = -1.0;
			for (int j = 0; j < kGG; ++j)
			{
				double s = 0.0;
				for (int q = _GLo(j); q < _GLo(j + 1); ++q)
					s += (f[q] < 0.0) ? -f[q] : f[q];
				s /= (1.0 + u[j]);
				if (s > best) { best = s; m = j; }
			}
			sel[m] = true;
			return;
		}
		if (mode == 2) { for (int i = 0; i < k; ++i) sel[(2 + i) % kGG] = true; return; }
		if (mode == 1)
		{
			for (int i = 0; i < k; ++i) sel[(rr + i) % kGG] = true;
			rr = (rr + 1) % kGG;
			return;
		}
		int n = 0;
		while (n < k) { const int j = RandInt(0, kGG); if (!sel[j]) { sel[j] = true; n++; } }
	}

	struct Blob { uint8 v = 0; int64 cx16 = 0, cy16 = 0; uint64 ink = 0; };

	// 🔗 **연결 성분 기반** — 배경이 아닌 픽셀을 **4-이웃 + 같은 값**으로 묶어 대상을 가른다.
	//   ⚠️⚠️ **예전엔 바이트값별로만** 묶었다 ⇒ **같은 색 둘이 하나로 뭉개졌다.** 그것이 이 세계를
	//     「대상 수 1」에 묶어 둔 자리다(`if (n != 1) break;` 가 그 관문이고, 커버리지의 가장
	//     큰 구멍 셋 중 하나가 **대상 수**였다 → ML.md).
	//   ★ 순서는 **(값, 그 성분의 첫 픽셀 스캔 순서)** 다 — **잉크 순이 아니다.** 순서를 뜻으로
	//     쓰지 않기 위해서고(예전 규약이 「값 순」이었던 그 이유), 값이 같은 둘을 가르는 데는
	//     **기하**를 쓴다(크기를 쓰면 「큰 것이 먼저」라는 뜻이 순서에 생긴다).
	//   ⚠️ **대상이 하나인 프레임에서는 예전과 비트 동일해야 한다** — 그것이 이 변경의 관문이고
	//     라운드의 `kPrev` 재현 대조가 그것을 찍는다.
	//   ⚠️⚠️ 다만 **겹침으로 조각난 경우엔 갈릴 수 있다**: `잉크 < 8` 버리기가 예전엔 **값 전체**에,
	//     이제는 **성분마다** 걸린다 ⇒ 5픽셀 조각이 붙어 있던 값은 중심이 달라진다.
	//     ★ 그것이 갈리면 **그 자리가 발견**이다(예전 값이 겹침에서 중심이 튀는 것을 감추고 있었다).
	static int _Blobs(const uint8* p, int cell, uint8 bg, Blob* out, int cap)
	{
		static constexpr int kBPix = MLEpisodeGen::kSize * MLEpisodeGen::kSize;
		if (p == nullptr || out == nullptr || cap <= 0) return 0;
		const int64 total = (int64)cell * (int64)cell;
		if (total <= 0 || total > (int64)kBPix)
		{
			// ⚠️ 조용히 0 을 주지 않는다 — 배관이 어긋난 것이고 그것을 찍어야 한다(함정 288 계열).
			static bool sTold = false;
			if (!sTold) { sTold = true; LogA("[ml] ⚠️ _Blobs: cell %d 이 상한 %d 을 넘는다 — 0\n",
				cell, MLEpisodeGen::kSize); }
			return 0;
		}
		// 🌲 union-find — 배경은 `-1` 로 두고 나머지는 자기 자신에서 시작한다.
		//   ⇒ ★ `par[i] < 0` 이 곧 「배경」이다(부모는 항상 배경이 아닌 색인이므로 겹치지 않는다).
		static int32 par[kBPix];
		static int64 sx[kBPix], sy[kBPix];
		static uint64 nn[kBPix];
		static int32 firstAt[kBPix];
		static int32 roots[kBPix];
		for (int64 i = 0; i < total; ++i)
		{
			par[i] = (p[i] == bg) ? -1 : (int32)i;
			sx[i] = 0; sy[i] = 0; nn[i] = 0; firstAt[i] = -1;
		}
		// 경로 압축 — 뿌리를 찾는다.
		auto Find = [](int32* pa, int32 i) -> int32
		{
			while (pa[i] != i) { pa[i] = pa[pa[i]]; i = pa[i]; }
			return i;
		};
		// 1차 — 위·왼 이웃과 **값이 같으면** 합친다(4-이웃).
		for (int y = 0; y < cell; ++y)
			for (int x = 0; x < cell; ++x)
			{
				const int32 i = (int32)((int64)y * (int64)cell + (int64)x);
				if (par[i] < 0) continue;
				const uint8 v = p[i];
				if (x > 0)
				{
					const int32 k = i - 1;
					if (par[k] >= 0 && p[k] == v)
					{ const int32 ra = Find(par, i), rb = Find(par, k); if (ra != rb) par[ra] = rb; }
				}
				if (y > 0)
				{
					const int32 k = i - cell;
					if (par[k] >= 0 && p[k] == v)
					{ const int32 ra = Find(par, i), rb = Find(par, k); if (ra != rb) par[ra] = rb; }
				}
			}
		// 2차 — 뿌리별로 중심·잉크를 누적하고 **첫 픽셀**을 기억한다(순서의 두 번째 키).
		for (int y = 0; y < cell; ++y)
			for (int x = 0; x < cell; ++x)
			{
				const int32 i = (int32)((int64)y * (int64)cell + (int64)x);
				if (par[i] < 0) continue;
				const int32 rt = Find(par, i);
				if (firstAt[rt] < 0) firstAt[rt] = i;
				sx[rt] += x; sy[rt] += y; nn[rt]++;
			}
		int nr = 0;
		for (int64 i = 0; i < total; ++i)
			if (par[i] == (int32)i) roots[nr++] = (int32)i;
		// 🔤 **(값, 첫 픽셀)** 로 정렬 — 삽입 정렬(성분 수가 작다).
		for (int i = 1; i < nr; ++i)
		{
			const int32 cur = roots[i];
			int j2 = i - 1;
			while (j2 >= 0)
			{
				const bool after = (p[roots[j2]] > p[cur])
					|| (p[roots[j2]] == p[cur] && firstAt[roots[j2]] > firstAt[cur]);
				if (!after) break;
				roots[j2 + 1] = roots[j2]; --j2;
			}
			roots[j2 + 1] = cur;
		}
		int m = 0;
		for (int k = 0; k < nr && m < cap; ++k)
		{
			const int32 rt = roots[k];
			// ⚠️ 아주 작은 조각은 버린다 — 겹침으로 몇 픽셀만 남은 것을 대상으로 세면 중심이 튄다.
			//   ★ 예전과 **같은 문턱**이다(8). 다른 것은 **성분마다** 본다는 것뿐이다.
			if (nn[rt] < 8u) continue;
			out[m].v = p[rt]; out[m].ink = nn[rt];
			out[m].cx16 = sx[rt] * 16 / (int64)nn[rt];
			out[m].cy16 = sy[rt] * 16 / (int64)nn[rt];
			m++;
		}
		return m;
	}
	
	// 🔬 **자체 시험 — 배관이 실제로 갈렸나.** ⚠️ 이 저장소의 반복 교훈이 그것이다:
	//   **「주었다」와 「값이 들어갔다」는 다른 사실이다**(함정 299·303). 연결 기반으로 바꿨다는
	//   말만으로는 아무것도 안 보장한다 ⇒ **같은 색 둘을 일부러 그려** 세어 본다.
	//   ★ 그리고 이 시험은 **원리적으로 못 틀리지 않는다**(규율 13): 예전 코드로 돌리면 2 가 나온다.
	static bool _BlobsSelfTest()
	{
		const int cell = MLEpisodeGen::kSize;
		static constexpr int kBPix = MLEpisodeGen::kSize * MLEpisodeGen::kSize;
		static uint8 fr[kBPix];
		for (int i = 0; i < kBPix; ++i) fr[i] = 0;
		// 같은 값 7 의 4x4 둘(멀리 떨어뜨린다) + 다른 값 9 의 4x4 하나.
		for (int y = 5; y < 9; ++y) for (int x = 5; x < 9; ++x) fr[y * cell + x] = 7;
		for (int y = 40; y < 44; ++y) for (int x = 40; x < 44; ++x) fr[y * cell + x] = 7;
		for (int y = 40; y < 44; ++y) for (int x = 5; x < 9; ++x) fr[y * cell + x] = 9;
		Blob bb[8];
		const int n = _Blobs(fr, cell, 0, bb, 8);
		// 기대: 3개 · (값,첫픽셀) 순이라 7@(6.5,6.5) → 7@(41.5,41.5) → 9@(6.5,41.5).
		//   ⚠️ 예전(값별)이면 **2개**이고 값 7 의 중심은 **합쳐진 (24,24)** 였다.
		const bool ok = (n == 3)
			&& (bb[0].v == 7 && bb[0].cx16 == 104 && bb[0].cy16 == 104)
			&& (bb[1].v == 7 && bb[1].cx16 == 664 && bb[1].cy16 == 664)
			&& (bb[2].v == 9 && bb[2].cx16 == 104 && bb[2].cy16 == 664);
		LogA("[ml] 🔬 `_Blobs` 자체 시험: 성분 %d개(기대 3) — %s\n"
			"[ml]   실측 중심: v%u(%.1f,%.1f) · v%u(%.1f,%.1f) · v%u(%.1f,%.1f)\n"
			"[ml]   ⚠️ 예전(값별)이면 **2개**이고 v7 은 합쳐진 (24.0,24.0) 하나였다\n",
			n, ok ? "✅ 배관이 갈렸다" : "⛔ 안 갈렸다 — 이 판은 판정불가다",
			(uint32)bb[0].v, (double)bb[0].cx16 / 16.0, (double)bb[0].cy16 / 16.0,
			(uint32)bb[1].v, (double)bb[1].cx16 / 16.0, (double)bb[1].cy16 / 16.0,
			(uint32)bb[2].v, (double)bb[2].cx16 / 16.0, (double)bb[2].cy16 / 16.0);
		return ok;
	}

	void _RunWho()
	{
		const int cell = MLEpisodeGen::kSize;
		const uint64 plane = (uint64)cell * (uint64)cell;
		const int kSeeds = 24, kMaxB = 6;
		LogA("[ml] ── 📐 **D65 · 목표거리를 「누구의」 것으로** — 함정 212 의 처방 ──────────────\n"
			"[ml]   ★ D64: 대상이 둘이면 **합친 무게중심**이 관계 변화를 못 잰다"
			"(11칸 「됐다」 **100%%**) · 10칸은 정상처럼 보여 **더 위험**했다\n"
			"[ml]   ★ 대상은 **색(바이트값)으로** 가른다 — `ImageOps` 는 AA 가 없어 한 도형 = 한 값이다."
			" ⚠️ 오라클이 아니다(생성기의 숨은 상태를 안 본다)\n"
			"[ml]   ★ 작동 판정: ㉠ 4~7칸 **회귀**(대상 하나면 합친 것과 같다) ·"
			" ㉡ 11칸의 관계 낱말이 **갈리나** · ㉢ ★ **캡션 일치율 100%%**(세계가 쓴 낱말 = 우리가 잰 부호)"
			" · ㉣ 11칸 대상별이 「됐다」 100%% 를 **벗어나나**\n"
			"[ml]   ⚠️ 씨앗 %d개/칸 · 칸 4~11\n", kSeeds);
		static const char* kW[3] = { "나아짐", "막힘", "됐다" };
		int capN = 0, capOk = 0;
		for (int rung = 4; rung <= 11; ++rung)
		{
			int ow[3] = {}, rw[3] = {}, epN = 0, nb = 0;
			for (int s = 0; s < kSeeds; ++s)
			{
				MLEpisode ep;
				MLEpisodeGen::Build(rung, MLEpisodeGen::ScrambleSeed(
					65000u + (uint32)(rung * 100 + s)), false, ep);
				DrawProgram prog;
				if (!prog.Compile(ep.code.View(), (uint32)cell, (uint32)cell, NameID("Who"))) continue;
				const int frames = (ep.frameCount > 0) ? ep.frameCount : 1;
				if (frames < 2 || frames > 8) continue;
				Bytes abs; abs.Reset(plane * (uint64)frames);
				bool ok = true;
				for (int f = 0; f < frames && ok; ++f)
				{
					ok = (f == 0) ? prog.RunStart() : prog.RunFrame();
					if (!ok) break;
					ok = ImageFormat::PackRGB332Delta(prog.canvas, nullptr,
						(uint8*)abs.GetData() + plane * (uint64)f, plane);
				}
				if (!ok) continue;
				// 🎯 목표 — `goalCode` 가 있으면 그것의 마지막 장.
				Bytes gbuf;
				const uint8* goal = nullptr;
				if (!ep.goalCode.IsEmpty())
				{
					DrawProgram gp;
					if (!gp.Compile(ep.goalCode.View(), (uint32)cell, (uint32)cell, NameID("GoalH")))
						continue;
					gbuf.Reset(plane);
					bool gok = gp.RunStart();
					for (int gf = 1; gf < frames && gok; ++gf) gok = gp.RunFrame();
					if (gok) gok = ImageFormat::PackRGB332Delta(gp.canvas, nullptr,
						(uint8*)gbuf.GetData(), plane);
					if (!gok) continue;
					goal = (const uint8*)gbuf.GetData();
				}
				else goal = (const uint8*)abs.GetData() + plane * (uint64)(frames - 1);
				const uint8 bg = _BgByte(goal, plane);
				Blob gb[8]; const int gn = _Blobs(goal, cell, bg, gb, kMaxB);
				if (gn == 0) continue;
				epN++; nb += gn;
				// 걸음마다 대상별 거리와 관계 거리.
				int64 pd[8] = {}; int64 pr = -1;
				for (int f = 0; f < frames; ++f)
				{
					const uint8* pf = (const uint8*)abs.GetData() + plane * (uint64)f;
					Blob b[8]; const int n = _Blobs(pf, cell, bg, b, kMaxB);
					// 📏 **대상별** — 같은 바이트값끼리 짝짓는다(색이 키다).
					for (int k = 0; k < gn; ++k)
					{
						int64 d = (int64)cell * 16 * 2;
						for (int q = 0; q < n; ++q)
							if (b[q].v == gb[k].v)
							{
								d = ((b[q].cx16 > gb[k].cx16) ? (b[q].cx16 - gb[k].cx16)
									: (gb[k].cx16 - b[q].cx16))
									+ ((b[q].cy16 > gb[k].cy16) ? (b[q].cy16 - gb[k].cy16)
										: (gb[k].cy16 - b[q].cy16));
								break;
							}
						if (f > 0)
						{
							const int z = (d == 0) ? 2 : ((d < pd[k]) ? 0 : 1);
							ow[z]++;
						}
						pd[k] = d;
					}
					// 🔗 **관계** — 대상이 둘일 때 두 중심 사이 거리.
					if (n >= 2)
					{
						const int64 r = ((b[0].cx16 > b[1].cx16) ? (b[0].cx16 - b[1].cx16)
							: (b[1].cx16 - b[0].cx16))
							+ ((b[0].cy16 > b[1].cy16) ? (b[0].cy16 - b[1].cy16)
								: (b[1].cy16 - b[0].cy16));
						if (f > 0 && pr >= 0)
							rw[(r < pr) ? 0 : ((r > pr) ? 1 : 2)]++;   // 가까워짐 · 멀어짐 · 그대로
						pr = r;
					}
				}
				// ㉢ **캡션 일치** — 세계가 쓴 낱말과 우리가 잰 부호가 같나.
				{
					const bool sN = _Contains(ep.caption.ptr(), "가까워진다");
					const bool sF = _Contains(ep.caption.ptr(), "멀어진다");
					if (sN || sF)
					{
						const uint8* p0 = (const uint8*)abs.GetData();
						const uint8* pL = (const uint8*)abs.GetData() + plane * (uint64)(frames - 1);
						Blob b0[8], bL[8];
						const int n0 = _Blobs(p0, cell, bg, b0, kMaxB);
						const int nL = _Blobs(pL, cell, bg, bL, kMaxB);
						if (n0 >= 2 && nL >= 2)
						{
							const int64 r0 = ((b0[0].cx16 > b0[1].cx16) ? (b0[0].cx16 - b0[1].cx16)
								: (b0[1].cx16 - b0[0].cx16));
							const int64 rL = ((bL[0].cx16 > bL[1].cx16) ? (bL[0].cx16 - bL[1].cx16)
								: (bL[1].cx16 - bL[0].cx16));
							capN++;
							if ((sN && rL < r0) || (sF && rL > r0)) capOk++;
						}
					}
				}
			}
			const int on = ow[0] + ow[1] + ow[2];
			const int rn = rw[0] + rw[1] + rw[2];
			LogA("[ml]      %2d칸 — 에피소드 %2d · 대상 %.1f개 │ **대상별** 나아짐 %.1f%% ·"
				" 막힘 %.1f%% · 됐다 %.1f%%  │ **관계** 가까워짐 %.1f%% · 멀어짐 %.1f%% · 그대로 %.1f%%\n",
				rung, epN, (epN > 0) ? ((double)nb / (double)epN) : 0.0,
				(on > 0) ? (100.0 * ow[0] / on) : 0.0,
				(on > 0) ? (100.0 * ow[1] / on) : 0.0,
				(on > 0) ? (100.0 * ow[2] / on) : 0.0,
				(rn > 0) ? (100.0 * rw[0] / rn) : 0.0,
				(rn > 0) ? (100.0 * rw[1] / rn) : 0.0,
				(rn > 0) ? (100.0 * rw[2] / rn) : 0.0);
		}
		const double cp = (capN > 0) ? (100.0 * (double)capOk / (double)capN) : 0.0;
		LogA("[ml]      ㉢ ★ **캡션 일치 %d/%d = %.1f%%**(등록 **100%%**) ⇒ %s\n"
			"[ml]      ⇒ %s\n",
			capOk, capN, cp,
			(capN == 0) ? "⚠️ **판정불가** — 관계 낱말이 든 에피소드가 0 이다"
				: ((cp >= 99.95) ? "✅ **세계가 쓴 낱말과 우리가 잰 부호가 완전히 같다**"
					: "⛔ **어긋난다** — 같은 사실인데 갈렸으니 **측정이 틀렸다**(부호·짝짓기를 본다)"),
			(capN > 0 && cp >= 99.95)
				? "✅✅✅ ***목표거리가 「누구의」 것이 됐다*** — 대상별 호/불호와 관계 낱말이 갈리고,"
				  " 세계의 캡션과 **완전히 일치**한다 ⇒ 함정 212 가 닫혔다"
				: "⛔ **아직 아니다** — 위 칸별 값과 일치율을 보고 짝짓기(색)와 부호를 다시 본다");
	}
	// ══════════════════════════════════════════════════════════════════
	// 🪜 **D62 · 사다리 커버리지** — 세계가 지금 어느 칸을 갖고 있나를 **실측**한다.
	//
	// ★ 방법을 바꾼 라운드다(대화 판정 2026-08-22): *"수치값보다 원하는 작동 모습을 그리고*
	//   *그 모습이 나오는 쪽으로. 값은 그 다음."* ⇒ D56~D61 은 판정문이 전부 **문턱**이었고
	//   *"무엇이 되면 된 건가"* 를 한 번도 안 그렸다. 사다리를 먼저 그리고 **빈 칸을 목록으로** 만든다.
	//   ⚠️ `concept.md:288` 이 이미 그렇게 적어 놨다 — *"의미는 새 문맥에서 재사용되는 작동으로*
	//     *판정한다"* 이고 거기 나열된 것은 전부 **작동**이다.
	//
	// ★ 그리고 이 라운드는 **D61 의 지름길을 진단한다**. D61 은 낱말이 아니라 「어느 칸인가」를
	//   배웠다(칸별 최빈 가중합 70.6% ↔ 실측 71.0%). 그 원인의 절반이 **어휘 배치**다:
	//   ⇒ ***한 낱말이 한 칸에만 나오면 그 낱말과 그 칸은 구별되지 않는다.***
	//     그러면 「칸을 알아보기」가 「낱말을 알기」의 완전한 대역이 되고, 모델은 더 싼 쪽으로 간다
	//     (함정 154 의 친척: 답을 직접 주지 않았는데 **배치가 답을 준다**).
	//   ⇒ 그래서 **낱말 × 칸 행렬**을 찍고 **한 칸에만 사는 낱말을 센다**. 그것이 이 라운드의 값이다.
	// ⚠️ 학습 없음 · 세계를 안 고침 · 캡션에서 낱말을 **읽기만** 한다.
	// ══════════════════════════════════════════════════════════════════
	// 🔤 낱말과 **그 종류**. ⚠️⚠️ 종류가 필요한 이유: D62 의 판정문이 `한 칸에만 6/25` 로 ✅ 를
	//   찍었는데 감각 어휘 19개가 동작 어휘 6개를 **희석**한 것이었다(동작만 보면 5/6). 합계는
	//   부분집단의 퇴화를 가린다(함정 206 의 재발) ⇒ **종류를 미리 정해 두고 그 안에서도 본다.**
	struct WordK { const char* w; const char* k; };

	void _RunRungs()
	{
		static const WordK kW[] = {
			{ "붉은", "색" }, { "노란", "색" }, { "푸른", "색" }, { "초록", "색" }, { "하얀", "색" },
			{ "왼쪽", "자리" }, { "오른쪽", "자리" }, { "위", "자리" }, { "아래", "자리" },
			{ "가운데", "자리" },
			{ "작은", "크기" }, { "큰", "크기" },
			{ "원", "모양" }, { "네모", "모양" },
			{ "하나", "개수" },
			{ "테두리", "채움" }, { "채워", "채움" },
			{ "있다", "존재" },
			{ "그대로", "동작" }, { "움직인다", "동작" }, { "떨어진다", "동작" },
			{ "닿는다", "동작" }, { "멈춘다", "동작" },
			{ "오른쪽으로", "방향" }, { "아래로", "방향" },
			{ "일정하다", "방식" }, { "점점", "방식" },
			// 👥 **D64 — 둘이 생기면서 열린 어휘**(성장 지도 3·4단계).
			{ "둘", "개수" },
			{ "보다", "비교" }, { "더 크다", "비교" }, { "같다", "비교" },
			{ "더 왼쪽에", "비교" }, { "더 오른쪽에", "비교" },
			{ "가까워진다", "관계" }, { "멀어진다", "관계" },
			{ "왼쪽으로", "방향" },
		};
		const int NW = (int)(sizeof(kW) / sizeof(kW[0]));
		const int kR = 11, kSd = 40;
		LogA("[ml] ── 🪜 **D63 · 낱말 × 칸** — 캡션을 조립으로 바꾼 뒤 ──────────────────────\n"
			"[ml]   ★ 작동 판정(숫자가 아니다): ***동작 낱말이 둘 이상의 칸에 나오나.***\n"
			"[ml]     D62 실측 = 동작 6개 중 **5개가 한 칸에만**(함정 209) ⇒ 「낱말」과 「칸」이 구별 불가\n"
			"[ml]   ★ 처방: 문장을 칸마다 통째로 쓰지 말고 **낱말을 조립**한다(절을 짧게 끊어 잇는다)\n"
			"[ml]   ⚠️ **프레임은 한 바이트도 안 바뀐다** — 캡션만 고쳤다 ⇒ D56~D61 이 그대로 재현된다\n"
			"[ml]   ⚠️⚠️ 세계는 **「막힌다」고 말하지 않는다** — 「닿는다·멈춘다」다. 「막힘」은 목표가"
			" 그 너머일 때만 생기므로(D59) **1인칭 자기상태**의 자리다\n"
			"[ml]   ⚠️ 판정을 **종류별로** 본다(D62 의 판정문이 합계로 봐서 틀렸다 · 함정 206) ·"
			" 칸 %d × 씨앗 %d\n", kR, kSd);
		int hit[64][12] = {};
		for (int r = 1; r <= kR; ++r)
		{
			for (int s = 0; s < kSd; ++s)
			{
				MLEpisode ep;
				MLEpisodeGen::Build(r, MLEpisodeGen::ScrambleSeed(
					62000u + (uint32)(r * 100 + s)), false, ep);
				for (int w = 0; w < NW && w < 64; ++w)
					if (_Contains(ep.caption.ptr(), kW[w].w)) hit[w][r]++;
				if (s < 1) LogA("[ml]      %d칸(%d장) “%s”\n", r, ep.frameCount, ep.caption.ptr());
			}
		}
		LogA("[ml]      ── 낱말 × 칸 (`#` = 그 칸 전부 · 숫자 = 십의 자리 · `.` = 없음) ──\n"
			"[ml]        %-12s %-6s 1 2 3 4 5 6 7   칸\n", "낱말", "종류");
		for (int w = 0; w < NW && w < 64; ++w)
		{
			char row[32] = {};
			int nR = 0;
			for (int r = 1; r <= kR; ++r)
			{
				const int pc = hit[w][r] * 10 / kSd;
				row[(r - 1) * 2]     = (hit[w][r] == 0) ? '.' : ((pc >= 10) ? '#' : (char)('0' + pc));
				row[(r - 1) * 2 + 1] = ' ';
				if (hit[w][r] > 0) nR++;
			}
			LogA("[ml]        %-12s %-6s %s  %d%s\n", kW[w].w, kW[w].k, row, nR,
				(nR == 0) ? "  ⛔ 세계에 없다" : ((nR == 1) ? "  ⚠️ **한 칸에만**" : ""));
		}
		// 📏 **종류별로** 센다 — 이것이 D62 의 판정 실수를 고친 자리다.
		static const char* kK[] = { "색", "자리", "크기", "모양", "개수", "채움",
			"존재", "동작", "방향", "방식", "비교", "관계" };
		const int NK = (int)(sizeof(kK) / sizeof(kK[0]));
		int badAct = 0, badAny = 0;
		LogA("[ml]      ── 종류별 ──\n");
		for (int q = 0; q < NK; ++q)
		{
			int n = 0, solo = 0, dead = 0, shr = 0;
			for (int w = 0; w < NW && w < 64; ++w)
			{
				if (!_Contains(kW[w].k, kK[q]) || !_Contains(kK[q], kW[w].k)) continue;
				n++;
				int nR = 0;
				for (int r = 1; r <= kR; ++r) if (hit[w][r] > 0) nR++;
				if (nR == 0) dead++;
				else if (nR == 1) solo++;
				else shr++;
			}
			if (n == 0) continue;
			const bool act = (_Contains(kK[q], "동작") || _Contains(kK[q], "방식")
				|| _Contains(kK[q], "방향") || _Contains(kK[q], "존재")
				|| _Contains(kK[q], "비교") || _Contains(kK[q], "관계"));
			if (act) badAct += solo + dead;
			badAny += solo + dead;
			LogA("[ml]        %-6s 낱말 %d — 공유 %d · 한 칸 %d · 없음 %d%s\n",
				kK[q], n, shr, solo, dead,
				act ? ((solo + dead == 0) ? "   ✅ **작동 판정 대상 · 통과**"
					: "   ⛔ **작동 판정 대상 · 미달**") : "");
		}
		LogA("[ml]      ⇒ **동작·방식·방향·존재·비교·관계에서 한 칸/없음 = %d개**(등록 = **0**)\n"
			"[ml]      ⇒ 전체(감각 포함)에서는 %d개 — 참고만 한다(합계는 부분집단을 희석한다)\n"
			"[ml]      ⇒ %s\n",
			badAct, badAny,
			(badAct == 0)
				? "✅✅✅ ***어휘가 칸을 넘는다*** — 동작 낱말이 전부 둘 이상의 칸에 산다 ⇒ 「낱말을 아는"
				  " 것」이 「칸을 알아보는 것」과 **다른 일**이 됐다(D61 의 지름길 절반을 막았다)"
				: "⛔ **아직 칸에 묶인 낱말이 있다** — 위 표에서 ⚠️ 를 보고 그 낱말이 다른 칸에도"
				  " 나오게 세계나 캡션을 고친다");
	}
	// ══════════════════════════════════════════════════════════════════
	// 🗣️ **D61 · 낱말을 학습에 붙인다** — 코딩 세계의 첫 학습기.
	//
	// ★ 다섯 라운드가 이 자리를 만들었다: D56 「막힘」이 세계에 없다 → D57 바닥 →
	//   D58 채널은 살았는데 정도가 없다 → D59 거리를 자리로(정도) → D60 벽(도달 불가능한 목표).
	//   ⇒ 이제 세 낱말이 다 있고(59.4 / 13.3 / 27.3%) **대조군이 정해져 있다**(최빈 59.4%).
	//
	// ★ **특징 = 3x3 격자의 잉크량 x 세 블록**(지금 · 목표 · 이전) = **27개**.
	//   ★ 근거: *"인코딩 층의 구조는 주고, 분포 층의 구조는 배우게 한다"*(ML.md 의 그 한 줄).
	//     2D 격자는 **인코딩**이고, *"잉크가 목표의 잉크 쪽으로 갔다"* 는 **배울 것**이다.
	//   ⚠️⚠️ **부호(방향)를 미리 계산해 주지 않는다** — `dx * gx > 0` 같은 특징을 주면 그것은
	//     낱말의 정의를 손으로 적어 주는 것이다(함정 154 의 자리).
	//   ⚠️⚠️ **칸 번호(rung)를 특징으로 주지 않는다** — D60 의 정직한 경계: 7칸엔 「됐다」가 0%,
	//     4·5칸엔 「막힘」이 0% 라 **칸을 맞히면 낱말이 절반 찍힌다.** 그래서 칸을 지운다.
	//     ⇒ 그리고 **칸별 정확도를 따로 낸다**(어디서 오는 이득인지 보이게).
	//
	// ★ **D71 이 판정을 정직하게 만들었다** — **상수 줄기**(줄기 안에서 라벨이 전부 같은
	//   것)를 뺀 값을 같이 낸다. 그런 줄기는 **원리적으로 못 틀리는 시험**이다.
	//   ★ 미리 등록: **줄기를 빼고도 대조군 +10%p 를 넘나** · 씨앗은 전체에 건다(함정 199).
	//   ★ 크기 예측: 상수 줄기는 10칸의 정지 대상뿐이라 걸음의 **~12%** 이고,
	//     빼면 정확도·대조군이 **함께** 내려간다 ⇒ 정확도 **80~82%** · 대조군 **57~60%**.
	// ★ **D70 이 분해능을 열었다** — 삼중에 「**정확한 잉크 수가 변했나**」를 넣었다.
	//   ★ 미리 등록: ㉠ ★ **7칸이 그 칸 최빈(53.3%)을 +10%p 넘나**(D69 는 55.4% = +2.1) ·
	//     ㉡ 전체가 D69 의 **78.2% 보다 오르나** · 씨앗 **10/12**.
	//   ★ 크기 예측: 7칸 55.4 → **70% 대** · 전체 78.2 → **82~86%**.
	//   ⚠️ `kTrain` 을 안 바꿨으므로 D69 와 **같은 표본**이다(직접 비교가 성립한다).
	// ★ **D69 가 특징을 관계로 바꿨다** — 칸마다 (이전, 지금, 목표) 삼중.
	//   ★ **이제 깨끗하게 잴 수 있다** — D68 이 「칸을 알아보기」 지름길을 막았으므로(함정 216)
	//     이득이 있으면 그것은 **관계의 이득**이다.
	//   ★ 미리 등록: ㉠ 대조군 **+10%p 이상** · 씨앗 **10/12** ⇒ 관계가 값을 한다
	//     ㉣ **목표가 든 특징을 빼면 크게 떨어진다**(지금 −0.0%p — 그것이 함정 208 의 증상이었다)
	//   ★ 크기 예측: 대조군 60.9% → **75~85%**. 라벨이 「그 대상의 거리가 줄었나」이고 삼중이
	//     칸마다 *"잉크가 목표 쪽으로 갔나"* 를 주므로 9칸의 다수결이 라벨과 강하게 상관한다.
	// ★ **D68 이 이 라운드의 라벨을 고쳤다** — 걸음이 **대상별**이다(함정 212 의 남은
	//   자리 · 함정 215). 그래서 D61 의 숫자와 **직접 비교할 수 없다**(라벨 자체가 달라졌다).
	//   ★ 작동 판정: ***11칸 정확도가 100% 를 벗어나나*** — 그 칸의 라벨이 상수가 아니게 되나.
	//   ⚠️ ㉣(목표를 빼면 떨어지나)은 **예측하지 않는다** — **함정 208**(독립 곱은 관계를 못
	//     담는다)이 아직 살아 있으므로 목표를 줘도 못 쓸 수 있다. 값만 적는다.
	// ★ **미리 등록**:
	//   ㉠ 전체 정확도가 **대조군(최빈 낱말) + 10%p 이상** · 씨앗 **10/12** ⇒ 배운다
	//   ㉣ **목표 블록 9개를 빼면** 정확도가 **떨어진다**(대조군 쪽으로) · 씨앗 10/12
	//      ⇒ 그것이 *"정보가 입력에 있다"* 의 증거다(D27 과 같은 관용구).
	//   ⚠️ ㉡(앵커로 쓰이나)와 ㉢(불투명 id)는 **이 라운드가 아니다** — ㉠ 이 서야 뜻이 있다.
	// ⚠️ 학습 씨앗과 시험 씨앗을 **가른다**(에피소드 16 ↔ 8) · 표는 씨앗마다 새로 만든다.
	// ══════════════════════════════════════════════════════════════════
	static constexpr int kWF = 27;                 // 특징 수(3블록 x 3x3)
	// 🔗 **관계를 인코딩으로**(D69) — 함정 208 의 처방.
	//
	// ★ D68 이 지름길을 막자 **함정 208 이 순수하게 드러났다**(목표를 빼도 −0.0%p):
	//   정보는 입력에 있는데 **독립 곱이 관계를 원리적으로 못 담는다.**
	// ⚠️⚠️ **(지금, 목표) 쌍만 주면 그 함정이 재발한다** — 라벨은 *"거리가 줄었나"* 이고
	//   그것은 (이전↔목표)와 (지금↔목표)의 **비교**다. 쌍을 두 개 줘도 naive Bayes 는 그
	//   **쌍들 사이의 관계**를 또 못 담는다. ⇒ 칸마다 **세 시점을 한 특징**으로 묶어야 한다.
	// ★ 그래서 특징을 이렇게 짠다(개수는 **27개 그대로**):
	//   · `f[0..8]`   **삼중** — 칸마다 (이전, 지금, 목표)의 **있나/없나** 3비트 = **0..7**
	//     ⇒ 그 칸에서 *"잉크가 목표 쪽으로 갔나"* 가 **한 특징 안에서** 표현된다.
	//   · `f[9..17]`  지금의 잉크량(눈금 4) — **크기**를 잃지 않기 위해 남긴다
	//   · `f[18..26]` 목표의 잉크량(눈금 4)
	// ⚠️ **답을 주는 것이 아니다**(함정 154) — 칸마다의 삼중은 주지만 *"어느 칸 조합이 거리가*
	//   *줄었다는 뜻인가"* 는 배워야 한다(9칸을 합쳐야 한다). `dx x gx > 0` 을 주는 것과 다르다.
	// ⚠️ **눈금은 표본이 정한다** — 삼중을 눈금 4 로 하면 4³ = 64값 × 9칸 = 576칸이고 표본이
	//   ~640 이라 **칸당 1.1** 이다(너무 얇다). 있나/없나(8값)면 72칸 ⇒ 칸당 8.9 다.
	//   ★ 그래서 삼중은 **있나/없나**로, 크기는 **따로** 준다 — 정보를 나눠 담는다.
	// 🔬 **분해능**(D70) — D69 가 7칸(벽)만 못 배운 자리를 연다.
	//
	// ★ **격자를 잘게 하는 것은 답이 아니다.** 7칸의 걸음은 `step ∈ [2, 5)` px 인데
	//   3x3 격자의 칸은 **21px** 이다 ⇒ 이동이 칸을 거의 안 바꾼다. 칸을 걸음보다 작게 하려면
	//   32x32(특징 1024개)가 필요하고 표본이 못 받친다.
	// ★ ⇒ **같은 격자에서 더 미세한 것을 읽는다** — 칸마다 「**정확한 잉크 수가 변했나**」.
	//   도형(8~14px)이 칸(21px)보다 작아 **경계를 걸치므로**, 2px 이동에도 그 칸의 화소 수가
	//   바뀐다. ⇒ 눈금(4단)으로는 안 보이던 것이 **정확한 수의 변화**로는 보인다.
	// ★ 그래서 삼중을 **4비트**로 넓힌다: (변했나, 이전 있나, 지금 있나, 목표 있나) = 0..15.
	//   ⚠️ 특징 개수는 **27개 그대로**다 · 9칸 × 16값 = 144칸이고 표본이 ~640 이라 칸당 4.4 다.
	// ⚠️ **답을 주는 것이 아니다** — 「안 변했다」는 6칸(바닥)에서는 「됐다」이고 7칸(벽)에서는
	//   「막힘」이다. **같은 비트가 두 낱말을 가르므로** 목표와 함께 봐야 갈린다(함정 154 를 안 밟는다).
	// ⚠️ `kTrain` 을 **안 바꾼다** — 같은 씨앗·같은 표본이라 D69 와 **직접 비교가 성립**한다
	//   (함정 213: 회귀는 같은 씨앗으로만).
	static constexpr int kWQ = 16;                 // 특징 값의 상한(삼중이 0..15)
	// 🧹 `stem` = **줄기 번호**(D71) — 한 에피소드의 한 대상이 한 줄기다.
	//   ⚠️ 줄기 안에서 라벨이 **전부 같으면** 그 줄기는 「원리적으로 못 틀리는 시험」이다.
	struct WStep { uint8 f[kWF] = {}; int z = 0; int rung = 0; int stem = 0; };
	struct WTab { uint32 n[3] = {}; uint32 c[3][kWF][kWQ] = {}; };

	// 🔲 3x3 칸별 잉크량을 눈금 넷으로 — ★ **그 바이트값만** 센다(D68).
	//
	// ★ **왜 값별인가 — 함정 212 의 남은 자리다.** D65 가 목표거리를 대상별로 고쳤지만
	//   **`_RunWho` 안에서만** 고쳤고, 학습 라운드가 쓰는 이 자리는 여전히 **합쳐서** 봤다
	//   ⇒ `-mlword` 의 11칸 정확도가 **100%**(라벨이 「됐다」 상수 · 함정 215).
	// ★ *"누구의 거리인가"* 를 물으려면 *"누구를 보고 있나"* 가 **특징에도** 있어야 한다.
	//   그래서 격자를 **그 대상의 잉크만**으로 낸다 ⇒ 특징 개수는 **27개 그대로**이고
	//   대상별로 갈린다. ⚠️ 색 자체를 특징으로 넣지 않는다 — 그것은 임의 라벨이라 지름길이 된다
	//     (D37 이 「글자는 한 번도 쓰이지 않았다」로 그 자리를 쟀다).
	// ⚠️ 눈금 넷은 **인코딩**이다(격자 자체와 같은 종류의 선택 · concept.md 의 그 원칙).
	static void _Grid9v(const uint8* p, int cell, uint8 v, uint8* q9, uint32* raw9)
	{
		uint32 cnt[9] = {};
		const int h = cell / 3;
		for (int y = 0; y < cell; ++y)
		{
			int gy = y / h; if (gy > 2) gy = 2;
			for (int x = 0; x < cell; ++x)
			{
				int gx = x / h; if (gx > 2) gx = 2;
				if (p[(uint64)y * (uint64)cell + (uint64)x] == v) cnt[gy * 3 + gx]++;
			}
		}
		const uint32 area = (uint32)h * (uint32)h;
		for (int k = 0; k < 9; ++k)
		{
			const uint32 q = cnt[k];
			q9[k] = (uint8)((q == 0u) ? 0 : ((q * 4u <= area) ? 1 : ((q * 4u <= area * 3u) ? 2 : 3)));
			// ★ **정확한 수**도 같이 낸다 — 눈금이 못 보는 미세한 변화를 그것이 본다(D70).
			if (raw9 != nullptr) raw9[k] = q;
		}
	}

	// 🎞️ 에피소드 하나를 걸음들로 펼친다 — **대상마다 한 줄기**(D68).
	//   ⚠️ 낱말의 정의는 D59·D60·D65 그대로다(자리 거리 · `goalCode` · **대상별**).
	//   ★ 대상이 하나인 칸은 줄기가 하나라 전과 같고, 둘인 칸은 **걸음이 두 배**가 된다.
	bool _EpSteps(int rung, uint32 seed, int cell, Array<WStep>& out, int& stem)
	{
		const uint64 plane = (uint64)cell * (uint64)cell;
		MLEpisode ep;
		MLEpisodeGen::Build(rung, seed, false, ep);
		DrawProgram prog;
		if (!prog.Compile(ep.code.View(), (uint32)cell, (uint32)cell, NameID("Word"))) return false;
		const int frames = (ep.frameCount > 0) ? ep.frameCount : 1;
		if (frames < 2 || frames > 8) return false;
		Bytes abs; abs.Reset(plane * (uint64)frames);
		bool ok = true;
		for (int f = 0; f < frames && ok; ++f)
		{
			ok = (f == 0) ? prog.RunStart() : prog.RunFrame();
			if (!ok) break;
			ok = ImageFormat::PackRGB332Delta(prog.canvas, nullptr,
				(uint8*)abs.GetData() + plane * (uint64)f, plane);
		}
		if (!ok) return false;
		// 🎯 목표 — `goalCode` 가 있으면 그것을 돌린 마지막 장(도달 불가능할 수 있다 · D60).
		Bytes gbuf;
		const uint8* goal = nullptr;
		if (!ep.goalCode.IsEmpty())
		{
			DrawProgram gp;
			if (!gp.Compile(ep.goalCode.View(), (uint32)cell, (uint32)cell, NameID("GoalW")))
				return false;
			gbuf.Reset(plane);
			bool gok = gp.RunStart();
			for (int gf = 1; gf < frames && gok; ++gf) gok = gp.RunFrame();
			if (gok) gok = ImageFormat::PackRGB332Delta(gp.canvas, nullptr,
				(uint8*)gbuf.GetData(), plane);
			if (!gok) return false;
			goal = (const uint8*)gbuf.GetData();
		}
		else goal = (const uint8*)abs.GetData() + plane * (uint64)(frames - 1);
		const uint8 bg = _BgByte(goal, plane);
		// 👥 **대상별** — 목표의 blob 마다 한 줄기. 짝짓기는 **바이트값**으로 한다(D65 와 같은 근거).
		Blob gb[8]; const int gn = _Blobs(goal, cell, bg, gb, 8);
		if (gn == 0) return false;
		for (int k = 0; k < gn; ++k)
		{
			uint8 g9[9] = {};
			uint32 gr[9] = {};
			_Grid9v(goal, cell, gb[k].v, g9, gr);
			int64 prevD = 0; uint8 p9[9] = {}; uint32 pr9[9] = {}; bool hasPrev = false;
			for (int f = 0; f < frames; ++f)
			{
				const uint8* pf = (const uint8*)abs.GetData() + plane * (uint64)f;
				Blob b[8]; const int n = _Blobs(pf, cell, bg, b, 8);
				int64 cx = 0, cy = 0; bool found = false;
				for (int q = 0; q < n; ++q)
					if (b[q].v == gb[k].v) { cx = b[q].cx16; cy = b[q].cy16; found = true; break; }
				// ⚠️ 그 대상이 이 장에 없으면(가려짐·화면 밖) **가장 먼 값**으로 둔다.
				const int64 d = found
					? (((cx > gb[k].cx16) ? (cx - gb[k].cx16) : (gb[k].cx16 - cx))
						+ ((cy > gb[k].cy16) ? (cy - gb[k].cy16) : (gb[k].cy16 - cy)))
					: ((int64)cell * 16 * 2);
				uint8 n9[9] = {};
				uint32 nr[9] = {};
				_Grid9v(pf, cell, gb[k].v, n9, nr);
				if (f > 0)
				{
					WStep s;
					s.z = (d == 0) ? 2 : ((d < prevD) ? 0 : 1);
					s.rung = rung;
					s.stem = stem;
					for (int j = 0; j < 9; ++j)
					{
						// 🔗 **삼중** — (이전, 지금, 목표)의 있나/없나 3비트. ⇒ 관계가 **한 특징 안에** 있다.
						// 🔬 **삼중 4비트** — (변했나, 이전 있나, 지금 있나, 목표 있나).
						//   ★ 「변했나」는 **정확한 화소 수**로 본다(눈금으로는 2px 이동이 안 보인다).
						s.f[j] = (uint8)(((hasPrev && nr[j] != pr9[j]) ? 8 : 0)
							| ((p9[j] > 0) ? 4 : 0) | ((n9[j] > 0) ? 2 : 0)
							| ((g9[j] > 0) ? 1 : 0));
						s.f[9 + j]  = n9[j];   // 지금의 잉크량(크기)
						s.f[18 + j] = g9[j];   // 목표의 잉크량
					}
					out.Add(s);
				}
				prevD = d;
				for (int j = 0; j < 9; ++j) { p9[j] = n9[j]; pr9[j] = nr[j]; }
				hasPrev = true;
			}
			stem++;                                  // 🧹 이 대상의 줄기가 끝났다
		}
		return true;
	}

	// 🧮 셈 표(naive Bayes · add-1). ⚠️ `useGoal = false` 면 목표 블록 9개를 **안 본다**(㉣).
	// 🧮 셈 표의 **분포**를 낸다(옛 `_WPick` 은 argmax 를 반환했다 · D67).
	//   ⚠️ `useGoal = false` 면 목표 블록 9개를 **안 본다**(㉣).
	static MLChoice _WScore(const WTab& t, const uint8* f, bool useGoal)
	{
		MLChoice ch; ch.Reset(3);
		for (int z = 0; z < 3; ++z)
		{
			if (t.n[z] == 0u) continue;
			double sc = (double)t.n[z];
			for (int k = 0; k < kWF; ++k)
			{
				// ⚠️ `useGoal = false` 면 **목표가 든 특징을 다 뺀다** — 삼중(`0..8`)에는 목표 비트가
				//   박혀 있고 `18..26` 은 목표의 잉크량이다. ⇒ 남는 것은 「지금」 9개뿐이다.
				//   ★ 그래서 이 팔은 *"목표를 안 보면 얼마나 못하나"* 를 재는 것이고, D61~D68 의
				//     「목표 블록만 뺀다」보다 **더 센 제거**다(정직하게 그렇게 읽는다).
				if (!useGoal && (k < 9 || k >= 18)) continue;
				sc *= ((double)t.c[z][k][f[k]] + 1.0) / ((double)t.n[z] + (double)kWQ);
			}
			ch.Set(z, sc);
		}
		const bool any = ch.Any();
		ch.Normalize();
		if (!any) ch.flat = true;
		return ch;
	}

	void _RunWord()
	{
		const int cell = MLEpisodeGen::kSize;
		const int kSd = 12, kTrain = 16, kTest = 8;
		LogA("[ml] ── 🗣️ **D61 · 낱말을 학습에 붙인다** — 코딩 세계의 첫 학습기 ──────────────\n"
			"[ml]   ★ 특징 = **3x3 격자의 잉크량 x 세 블록**(지금 · 목표 · 이전) = **27개** ·"
			" 눈금 4 · 셈 표 naive Bayes(add-1)\n"
			"[ml]   ⚠️⚠️ **부호(방향)를 미리 계산해 주지 않는다**(`dx x gx > 0` 을 주면 낱말의 정의를"
			" 손으로 적는 것이다 · 함정 154) · **칸 번호도 안 준다**(D60 의 지름길)\n"
			"[ml]   ★ 미리 등록: ㉠ 정확도가 **대조군 + 10%%p 이상** · 씨앗 **10/12** ⇒ 배운다 ·"
			" ㉣ **목표 블록을 빼면 떨어진다**(정보가 입력에 있다는 증거 · D27 의 관용구)\n"
			"[ml]   ⚠️ 학습/시험 씨앗을 가른다(에피소드 %d ↔ %d) · 씨앗 %d개 · 칸 4~7\n",
			kTrain, kTest, kSd);
		double accA = 0.0, accB = 0.0, base = 0.0;
		double accA2 = 0.0, base2 = 0.0, kstP = 0.0;   // 🧹 상수 줄기 제외 · 그 비율(D71)
		double rA[12] = {}, rN[12] = {};
		int okSd = 0, upBase = 0, upGoal = 0;
		for (int sd = 0; sd < kSd; ++sd)
		{
			WTab tab;
			Array<WStep> tr, te;
			int stTr = 0, stTe = 0;                     // 🧹 줄기 번호(D71)
			for (int rung = 4; rung <= 11; ++rung)
			{
				for (int i = 0; i < kTrain; ++i)
					_EpSteps(rung, MLEpisodeGen::ScrambleSeed(
						61000u + (uint32)(sd * 1000 + rung * 100 + i)), cell, tr, stTr);
				for (int i = 0; i < kTest; ++i)
					_EpSteps(rung, MLEpisodeGen::ScrambleSeed(
						61000u + (uint32)(sd * 1000 + rung * 100 + 50 + i)), cell, te, stTe);
			}
			if (tr.Count() == 0u || te.Count() == 0u) continue;
			for (uint32 j = 0; j < tr.Count(); ++j)
			{
				const WStep& s = tr.Data()[j];
				tab.n[s.z]++;
				for (int k = 0; k < kWF; ++k) tab.c[s.z][k][s.f[k]]++;
			}
			// 🧹 **상수 줄기를 찾는다**(D71) — 줄기 안에서 라벨이 **전부 같은** 것.
			//   ★ 그런 줄기는 **원리적으로 못 틀리는 시험**이다: 10칸(하나만 움직임)의 **안
			//     움직이는 대상**은 목표가 자기 마지막 장이라 라벨이 「됐다」 상수다(세계의 사실이지
			//     함정이 아니다). 그것을 넣고 세면 「배웠나」가 부풀려진다 — 실측 10칸 **93.5%**.
			//   ★ 함정 134 의 관용구와 같은 계열이다: **관문에 걸린 시험은 본 분석에서도 뺀다.**
			//   ⚠️ 대조군도 **같은 집합에서 다시** 낸다(함정 135) — 안 그러면 기준선이 다른 집합의 것이다.
			Array<uint8> konst;
			konst.Reset(0);
			for (int q = 0; q <= stTe; ++q) konst.Add(1u);
			for (uint32 j = 0; j < te.Count(); ++j)
			{
				const WStep& s0 = te.Data()[j];
				for (uint32 q = 0; q < te.Count(); ++q)
					if (te.Data()[q].stem == s0.stem && te.Data()[q].z != s0.z)
						{ konst.Data()[(uint32)s0.stem] = 0u; break; }
			}
			// 🚪 대조군 — **시험집합의 최빈 낱말**(함정 135: 기준선은 같은 시험집합에서).
			uint32 hz[3] = {}, hz2[3] = {};            // 전부 · 상수 줄기 제외
			for (uint32 j = 0; j < te.Count(); ++j)
			{
				hz[te.Data()[j].z]++;
				if (konst.Data()[(uint32)te.Data()[j].stem] == 0u) hz2[te.Data()[j].z]++;
			}
			int mz = 0;
			for (int z = 1; z < 3; ++z) if (hz[z] > hz[mz]) mz = z;
			int mz2 = 0;
			for (int z = 1; z < 3; ++z) if (hz2[z] > hz2[mz2]) mz2 = z;
			const uint32 n2 = hz2[0] + hz2[1] + hz2[2];
			const double bs2 = (n2 > 0u) ? (100.0 * (double)hz2[mz2] / (double)n2) : 0.0;
			const double bs = 100.0 * (double)hz[mz] / (double)te.Count();
			uint32 okA = 0u, okB = 0u, okA2 = 0u, nA2 = 0u;
			uint32 rOk[12] = {}, rNo[12] = {};
			for (uint32 j = 0; j < te.Count(); ++j)
			{
				const WStep& s = te.Data()[j];
				// 🚪 분포를 받아 **여기서만** 굳힌다(세계 경계).
				const MLChoice ca = _WScore(tab, s.f, true), cb = _WScore(tab, s.f, false);
				const int pa = ca.flat ? -1 : ca.Argmax();
				const int pb = cb.flat ? -1 : cb.Argmax();
				if (pa == s.z) { okA++; rOk[s.rung]++; }
				// 🧹 상수 줄기를 뺀 셈(D71).
				if (konst.Data()[(uint32)s.stem] == 0u)
					{ nA2++; if (pa == s.z) okA2++; }
				if (pb == s.z) okB++;
				rNo[s.rung]++;
			}
			const double a = 100.0 * (double)okA / (double)te.Count();
			const double b = 100.0 * (double)okB / (double)te.Count();
			const double a2 = (nA2 > 0u) ? (100.0 * (double)okA2 / (double)nA2) : 0.0;
			// 🧹 상수 줄기가 걸음의 몇 %인가(예측을 확인할 수 있게 · 함정 127).
			kstP += 100.0 * (double)(te.Count() - nA2) / (double)te.Count();
			accA += a; accB += b; base += bs; accA2 += a2; base2 += bs2; okSd++;
			if (a > bs + 10.0) upBase++;
			if (a > b) upGoal++;
			for (int r = 4; r <= 11; ++r)
				if (rNo[r] > 0u)
					{ rA[r] += 100.0 * (double)rOk[r] / (double)rNo[r]; rN[r] += 1.0; }
		}
		if (okSd == 0) { LogA("[ml]   🗣️ ⚠️ **판정불가**\n"); return; }
		accA /= (double)okSd; accB /= (double)okSd; base /= (double)okSd;
		accA2 /= (double)okSd; base2 /= (double)okSd; kstP /= (double)okSd;
		LogA("[ml]      🚪 대조군(시험집합 최빈 낱말) **%.1f%%**\n"
			"[ml]      🧹 **상수 줄기**(라벨이 안 갈리는 줄기) = 걸음의 **%.1f%%** — 빼면"
			" 대조군 **%.1f%%** · 정확도 **%.1f%%**(**%+.1f%%p**)"
			" ⇒ %s\n"
			"[ml]      🧮 목표 **켬** — 정확도 **%.1f%%**(%+.1f%%p) │ 목표 **끔** — %.1f%%(%+.1f%%p)\n",
			base,
			kstP, base2, accA2, accA2 - base2,
			(accA2 - base2 >= 10.0)
				? "✅✅ **줄기를 빼고도 대조군 +10%p 를 넘는다** — 배운 것이 상수 줄기가 아니었다"
				: "⛔ **빼면 무너진다** — 「배웠나」가 상수 줄기에 업혀 있었다",
			accA, accA - base, accB, accB - base);
		for (int r = 4; r <= 11; ++r)
			if (rN[r] > 0.0)
				LogA("[ml]         └ %d칸 %.1f%%\n", r, rA[r] / rN[r]);
		LogA("[ml]      ㉠ **배우나** — 대조군 + 10%%p 이고 씨앗 %d/%d ⇒ %s\n"
			"[ml]      ㉣ **목표를 빼면** — %.1f → %.1f%%(**%+.1f%%p**) · 씨앗 %d/%d ⇒ %s\n"
			"[ml]      ⇒ %s\n",
			upBase, okSd,
			(upBase * 6 >= okSd * 5) ? "✅ **넘었다**" : "⛔ **미달**(10/12 기준)",
			accA, accB, accB - accA, upGoal, okSd,
			(upGoal * 6 >= okSd * 5)
				? "✅ **목표가 값을 한다** — 정보가 입력에 있다(D27 의 관용구)"
				: "⛔ **목표가 값을 안 한다** — 낱말을 목표 없이 맞히고 있다(지름길을 찾아야 한다)",
			(upBase * 6 < okSd * 5)
				? "⛔ **낱말을 못 배운다** — 특징이 부족하거나 표가 못 담는다"
				: ((upGoal * 6 >= okSd * 5)
					? "✅✅✅ ***낱말이 배워지고 목표가 값을 한다*** — 다음은 ㉡ **앵커로 쓰이나**와"
					  " ㉢ **불투명 id**(D37)다"
					: "⚠️ **배우기는 하는데 목표가 필요 없다** — 무엇이 지름길인지 찾는 것이 먼저다"));
	}

	// ══════════════════════════════════════════════════════════════════
	// 🔗 **D72 · ㉡ 앵커로 쓰이나** — *"새로 생긴 심볼이 **다음 학습**의 앵커로 실제 사용된다"*
	//   (`concept.md` 의 성공 조건 그 줄이다.)
	//
	// ★ **무엇이 달라지나** — D71 까지는 낱말을 **배우나**를 물었다(80.9% · 씨앗 12/12).
	//   이제 그 낱말이 **쓰이나**를 묻는다. 쓰인다는 것은 *"그 심볼이 있어서 다음 배움이 낫다"* 다.
	// ★ **새 과제 = 다음 걸음의 낱말**(`z[t+1]`) — 지금을 보고 **다음**을 말한다.
	//   ⇒ 사용자가 그린 고리의 「**예측을 겸하는 해결책 설계**」에서 **예측** 쪽 씨앗이다.
	// ★ **앵커는 모델이 스스로 낸 낱말**이다 — 정답 라벨이 아니라 D70 표의 argmax(≈81%).
	//   ⚠️ 그래서 라벨을 두 번 보는 것이 아니다 — 같은 학습집합·같은 라벨이고 **모양만** 다르다.
	//
	// ★ **왜 이득이 있을 수 있나 — 표가 원리적으로 못 만드는 요약이라서.**
	//   셈 표(naive Bayes)는 특징을 **독립으로** 곱한다 ⇒ 27개의 곱으로 정해지는 값을 자기
	//   안에서 **만들 수 없다**. 낱말은 바로 그 곱을 **한 칸으로 접은 것**이다.
	//   ⇒ ★ 앵커의 값은 **정보가 아니라 모양**이다(함정 208 을 뒤집어 놓은 얼굴).
	// ⚠️⚠️ 그래서 **가짜 둘을 같이 돌린다** — 안 그러면 「좌표를 하나 더해서 올랐다」와 못 가른다:
	//   · ㉢ **무작위 좌표**(같은 3값) — 「**같은 비용에서**」(concept.md 의 전이 측정 규칙)
	//   · ㉣ **뒤섞은 낱말**(줄기마다 치환 · **항등 제외**) — 「**끊는다**」
	//   ⇒ ㉡ 만 오르고 ㉢·㉣ 이 제자리면 값을 한 것은 **낱말의 내용**이다.
	// 🧹 **D71 을 처음부터 적용한다** — 상수 줄기(줄기 안에서 `z[t+1]` 이 안 갈리는 것)를 빼고 보고,
	//   ⚠️ **대조군도 그 집합에서 다시** 낸다(함정 218: 빼면 **최빈 낱말 자체가 바뀐다**).
	// ⚠️ 씨앗은 `-mlword` 와 **같다**(61000u) ⇒ 여기 쓰는 앵커의 품질이 **이미 잰 값**이다(80.9%).
	// ★ **미리 등록**:
	//   ㉠ **㉡ > ㉠ + 3%p** 이고 씨앗 **10/12** ⇒ ✅ 앵커로 쓰인다
	//   ㉡ **㉢ ≈ ㉠**(±2%p) 이고 **㉣ ≈ ㉠**(±2%p) ⇒ ✅ 값을 한 것은 **내용**이다
	//   ★ 크기 예측: 대조군 ~60% · 사전항 `P(z'|w)` ~70% · ㉠ ~65% · ㉡ ~72%
	//   ⚠️ 갈릴 수 있는 자리: **㉡ ≈ 사전항**이면 특징이 아무것도 안 더한 것이다(그러면 그렇게 적는다).
	//
	// ══════ 🎯 **D73 — 과제를 둘로 늘렸다**(D72 의 실측이 시킨 것) ══════
	// ⛔ **D72 는 못 쟀다.** 실측: 사전항(낱말 하나만) **71.9%** · ㉠(특징 27개) **73.5%** ·
	//   ㉡(둘 다) **73.9%** ⇒ 앵커의 이득이 **+0.4%p**(씨앗 1/12).
	// ★ 그런데 **왜 못 쟀는지가 그 표에 박혀 있다** — 「다음 걸음의 낱말」은 **지금 낱말**로
	//   거의 풀린다(「됐다」·「막힘」이 흡수 상태다). ⇒ 낱말이 이미 아는 것을 특징도 알고,
	//   **더할 자리가 없다.** 앵커가 나쁜 것이 아니라 **과제에 여유가 없었다.**
	//   ⚠️ ✅ 가짜 둘이 제자리였다(㉢ −0.3 · ㉣ −0.0) ⇒ 계측은 멀쩡했다. **사전항 팔이 구했다.**
	// ★ ⇒ **함정 219**: 앵커 검사는 **「낱말만으로 되는 만큼」을 먼저 재라.** 그것이 특징과
	//   비슷하면 그 과제로는 앵커를 **원리적으로** 못 잰다(더할 여유가 없다).
	// ★ 그래서 과제를 **둘** 돌린다 — 여유를 재는 것이 판정의 일부가 된다:
	//   · 과제 0 = **다음 걸음의 낱말** `z[t+1]`(D72 · 여유 없음이 실측됐다)
	//   · 과제 1 = **몇 걸음 뒤에 「됐다」가 되나**(1 / 2~3 / 4+·안 됨)
	//     ★ 낱말은 **방향**만 안다(나아짐/막힘) — **얼마나 남았나**는 특징(잉크량·자리)에 있다.
	//     ⇒ 둘 다 필요한 과제라 **여유가 생긴다**(그것이 이 과제를 고른 이유다).
	//     ⚠️ **세계가 답을 주는 걸음만 쓴다** — 「나아지는 중인데 장이 끝났다」는 버린다
	//       (그것을 「안 된다」로 세면 라벨이 **장 수의 부산물**이 된다).
	//     ★ 끝까지 「막힘」인 줄기는 **안 된다**로 센다(벽 칸이 그것이다 — 세계의 사실).
	//
	// ══════ 🗂️ **D74 — 앵커를 「색인」으로 쓴다**(D73 의 실측이 시킨 것) ══════
	// ⛔ **D73 도 못 올렸다** — 과제 1(몇 걸음 뒤에 됐다)에서도 ㉡ − ㉠ = **+0.2%p**(씨앗 0/12).
	// ★ 그런데 **두 과제가 같은 것을 말했다** — 「낱말 하나」가 「특징 27개」와 **거의 같다**:
	//   · 과제 0: 사전항 **71.9%** ↔ ㉠ **73.5%**(−1.6)
	//   · 과제 1: 사전항 **53.0%** ↔ ㉠ **52.4%**(**+0.6** — 낱말 하나가 **더 낫다**)
	//   ⇒ ★ 표로 세면 **1296칸 ↔ 12칸**이다(3x27x16 ↔ 4x3). **108배 싼 표현**으로 같은 값을 낸다.
	//   ⇒ ★ 그러니 낱말이 **요약이 아닌 것이 아니다** — 요약은 맞고, **합칠 자리가 없었다.**
	// ★ **왜 안 더해지나 — 곱셈은 중복된 증거를 지우지 못한다.**
	//   naive Bayes 는 특징을 **독립으로 곱한다**. 낱말은 그 27개의 **함수**라, 좌표로 더하면
	//   같은 증거를 **두 번** 곱하는 것이다 ⇒ 확신만 커지고 답은 안 바뀐다(그래서 +0.2~0.4%p).
	// ★ ⇒ **함정 220**: 심볼을 「특징 하나 더」로 주면 앵커가 될 수 없다 — 그것은 **증거**의
	//   자리다. 앵커는 **색인**의 자리다: *"이 낱말이면 이 표를 본다."*
	// ★ 그래서 팔을 셋 더 돌린다 — **좌표가 아니라 분할**이다:
	//   · ㉤ **낱말마다 표**(4벌) — 심볼이 **어느 지식이 적용되나**를 고른다
	//   · ㉥ **무작위 3분할** — 「**같은 비용에서**」(표본이 똑같이 쪼개지는 값을 치른다)
	//   · ㉦ **뒤섞은 낱말로 분할** — 「**끊는다**」
	//   ★ 미리 등록: **㉤ > ㉠ + 3%p** 이고 씨앗 **10/12** 이고 **㉥ ≤ ㉠** ⇒ ✅ 색인으로 쓰인다
	//   ★ 크기 예측: ㉤ 는 과제 0 에서 **+2~5%p** · 과제 1 에서 **+3~7%p** ·
	//     ㉥·㉦ 은 **−2~5%p**(쪼개진 값만 치른다)
	//   ⚠️ **분할은 공짜가 아니다** — 표마다 표본이 1/N 이라 칸이 얇아진다. ㉥ 이 그 값을 잰다.
	//
	// ══════ 📈 **D75 — 표본을 4배로**(D74 의 실측이 시킨 것) ══════
	// ★ **D74 가 방향을 뒤집었다** — 같은 낱말인데 **어디에 놓느냐**로 갈렸다:
	//   · 좌표로 더하면(㉡) 과제 0 **+0.4%p** · 과제 1 **+0.2%p** ⇒ 가짜와 못 가른다
	//   · 색인으로 쓰면(㉤) 과제 0 **+0.2%p** · 과제 1 **+2.3%p** ·
	//     그런데 **무작위 분할과의 차이**가 과제 0 **+5.0%p** · 과제 1 **+6.5%p** 다
	//   ⇒ ★ **낱말은 쪼개는 축으로서 무작위보다 확실히 낫다.** 함정 220 이 실측으로 섰다.
	// ⛔ **그런데 「쪼개지 않은 것」을 못 이겼다**(+0.2~2.3%p · 등록은 +3%p·10/12).
	//   ★ 이유가 ㉥ 에 박혀 있다 — **순수 분할의 대가가 −4.2~−4.8%p** 다(내용이 0인 분할).
	//     ⇒ 낱말의 이득(+5~6.5)이 그 대가에 거의 다 먹힌다.
	// ★ **기제를 지목했으니 움직여 확인한다** — 대가의 출처가 **표본 부족**이라는 주장이다:
	//   4벌로 쪼개면 벌당 걸음이 ~160 이고 칸이 27x16 = 432 ⇒ **칸당 0.37**. 못 이길 수밖에 없다.
	//   ⇒ `kTrain` 을 **16 → 64**(표본 4배). ★ **㉥ − ㉠ 는 내용이 0이라 confound 가 없다** —
	//     그것이 줄어들면 대가의 출처가 표본이었다는 뜻이다(㉠ 도 같이 커지므로 차는 공정하다).
	//   ★ 미리 등록: **㉥ − ㉠ 가 −4.2 → −1~−2%p** 로 줄고 **㉤ − ㉠ 가 +2.3 → +4~6%p** 로
	//     커진다 ⇒ 등록 판정(+3%p · 10/12)을 **넘는다**.
	//   ⚠️ 정직하게 적을 것: 씨앗은 그대로지만 **표본이 달라졌으므로 D72~D74 와 직접 비교가
	//     아니다**(함정 213). 그래서 ㉥·㉤·㉠ 을 **한 판 안에서** 견준다.
	// ══════════════════════════════════════════════════════════════════
	static constexpr int kAF = kWF + 1;            // 27 + **앵커 한 칸**
	struct ATab { uint32 n[3] = {}; uint32 c[3][kAF][kWQ] = {}; };
	// 📦 걸음 하나 — 특징 27개 + **앵커 후보 셋**(낱말 · 무작위 · 뒤섞음) + **다음** 낱말.
	struct AStep { uint8 f[kWF] = {}; uint8 a[3] = {}; int nz = 0; int stem = 0; };

	// 🧮 셈 표 — `nf` 개만 본다(㉠ 은 27, 나머지는 28) ⇒ 「같은 비용」이 인자 하나로 갈린다.
	static MLChoice _AScore(const ATab& t, const uint8* f, int nf)
	{
		MLChoice ch; ch.Reset(3);
		for (int z = 0; z < 3; ++z)
		{
			if (t.n[z] == 0u) continue;
			double sc = (double)t.n[z];
			for (int k = 0; k < nf; ++k)
				sc *= ((double)t.c[z][k][f[k]] + 1.0) / ((double)t.n[z] + (double)kWQ);
			ch.Set(z, sc);
		}
		const bool any = ch.Any();
		ch.Normalize();
		if (!any) ch.flat = true;
		return ch;
	}

	// 🎯 과제 이름 — 판정문이 무엇을 쟀는지 스스로 말하게 한다.
	static const char* kATask(int t)
	{
		return (t == 0) ? "다음 걸음의 낱말 `z[t+1]`"
			: "**몇 걸음 뒤에 「됐다」**(1 / 2~3 / 4+·안 됨)";
	}

	// 🔗 걸음들을 **새 과제**로 옮긴다(`task` 0/1).
	//   ⚠️ 답이 없는 걸음은 **버린다** — 줄기의 마지막 걸음(과제 0) · 세계가 답을 안 준 걸음(과제 1).
	static void _AFill(const Array<WStep>& src, const WTab& tab, int task,
		uint32& rs, Array<AStep>& out)
	{
		// ⚠️ **항등을 뺀 다섯 치환** — 항등이 섞이면 줄기의 1/6 은 낱말이 그대로라 「끊는다」가 흐려진다.
		static const uint8 kPerm[5][3] = { {0,2,1},{1,0,2},{1,2,0},{2,0,1},{2,1,0} };
		for (uint32 j = 0; j < src.Count(); ++j)
		{
			const WStep& s = src.Data()[j];
			// 🧭 이 줄기의 끝을 찾는다 — 같은 `stem` 은 **연속으로** 놓인다(`_EpSteps` 가 그렇게 낸다).
			uint32 e = j;
			while (e + 1u < src.Count() && src.Data()[e + 1u].stem == s.stem) e++;
			int nz = -1;
			if (task == 0)
			{
				if (j < e) nz = src.Data()[j + 1u].z;      // 줄기의 끝은 다음이 없다
			}
			else
			{
				// 🎯 **몇 걸음 뒤에 「됐다」가 오나** — 뒤를 훑어 첫 「됐다」까지의 걸음 수.
				int k = -1;
				for (uint32 q = j + 1u; q <= e; ++q)
					if (src.Data()[q].z == 2) { k = (int)(q - j); break; }
				if (k > 0) nz = (k == 1) ? 0 : ((k <= 3) ? 1 : 2);
				// ★ 끝까지 「막힘」이면 **안 된다**(벽 칸 · 멀어지는 칸) — 세계의 사실이다.
				else if (src.Data()[e].z == 1) nz = 2;
				// ⚠️ 그 밖은 **버린다** — 나아지는 중인데 장이 끝났다(세계가 답을 안 줬다).
			}
			if (nz < 0) continue;
			AStep t;
			for (int k = 0; k < kWF; ++k) t.f[k] = s.f[k];
			t.nz = nz;
			t.stem = s.stem;
			// 🗣️ 앵커 = **모델이 스스로 낸 낱말**(flat 이면 「모름」 = 3).
			const MLChoice c = _WScore(tab, s.f, true);
			const uint8 w = (uint8)(c.flat ? 3 : c.Argmax());
			t.a[0] = w;
			rs = rs * 1664525u + 1013904223u;
			t.a[1] = (uint8)((rs >> 16) % 3u);                 // ㉢ 무작위(같은 비용)
			// ㉣ 뒤섞음 — **줄기마다** 치환 ⇒ 뜻만 끊고 분포는 거의 남는다.
			const uint8* pm = kPerm[(uint32)s.stem % 5u];
			t.a[2] = (w < 3u) ? pm[w] : (uint8)3;
			out.Add(t);
		}
	}

	void _RunAnchor()
	{
		const int cell = MLEpisodeGen::kSize;
		// 📈 **표본 4배**(D75) — 분할의 대가가 표본 부족에서 오는지 움직여 확인한다.
		const int kSd = 12, kTrain = 64, kTest = 8;
		LogA("[ml] ── 🔗 **D72 · ㉡ 앵커로 쓰이나** — 새 심볼이 **다음 학습**에 쓰이나 ────────\n"
			"[ml]   ★ 새 과제 = **다음 걸음의 낱말**(`z[t+1]`) — 「예측을 겸하는 해결책 설계」의"
			" 예측 쪽 씨앗\n"
			"[ml]   ★ 앵커 = **모델이 스스로 낸 낱말**(D70 표의 argmax · **정답 라벨이 아니다**)"
			" ⇒ 라벨을 두 번 보는 것이 아니고 **모양만** 다르다\n"
			"[ml]   ★ 왜 오를 수 있나 — 셈 표는 특징을 **독립으로** 곱하므로 27개의 곱으로 정해지는"
			" 값을 **자기 안에서 못 만든다**. 낱말은 그 곱을 **한 칸으로 접은 것**이다\n"
			"[ml]   ⚠️⚠️ 가짜 둘을 같이 돌린다 — ㉢ **무작위 좌표**(같은 비용) · ㉣ **뒤섞은 낱말**"
			"(끊는다 · 항등 제외)\n"
			"[ml]   ★ 미리 등록: **㉡ > ㉠ + 3%%p** 이고 씨앗 **10/12** ⇒ 앵커로 쓰인다 ·"
			" **㉢·㉣ ≈ ㉠**(±2%%p) ⇒ 값을 한 것은 **내용**이다\n"
			"[ml]   ★ 크기 예측 — 과제 0(실측됨): 대조군 65.7%% · 사전항 71.9%% · ㉠ 73.5%% · ㉡ 73.9%%(여유 없음)\n"
			"[ml]   ★ 크기 예측 — 과제 1: 대조군 **~45%%** · 사전항 **~65%%** · ㉠ **~70%%** · ㉡ **~74%%** ⇒ 여유 **+5%%p**\n"
			"[ml]   🧹 상수 줄기는 **처음부터 뺀다**(D71) · 대조군도 그 집합에서 다시 낸다(함정 218)\n"
			"[ml]   📈 **표본 4배**(D75 · 학습 %d편/칸) — ㉥(내용 0인 분할)의 대가가 줄어야 기제가 맞다\n",
			kTrain);
		double mBase[2][2] = {}, mPri[2][2] = {}, mArm[2][7][2] = {};
		double kstP[2] = {}, mN[2] = {};
		int okSd[2] = {}, upAnc[2] = {}, upIdx[2] = {};
		for (int sd = 0; sd < kSd; ++sd)
		{
			// 🗣️ ① 낱말 표 — D70/D71 그대로(같은 씨앗이라 품질이 이미 잰 값이다).
			WTab tab;
			Array<WStep> trw, tew;
			int stTr = 0, stTe = 0;
			for (int rung = 4; rung <= 11; ++rung)
			{
				for (int i = 0; i < kTrain; ++i)
					_EpSteps(rung, MLEpisodeGen::ScrambleSeed(
						61000u + (uint32)(sd * 1000 + rung * 100 + i)), cell, trw, stTr);
				for (int i = 0; i < kTest; ++i)
					_EpSteps(rung, MLEpisodeGen::ScrambleSeed(
						61000u + (uint32)(sd * 1000 + rung * 100 + 50 + i)), cell, tew, stTe);
			}
			if (trw.Count() == 0u || tew.Count() == 0u) continue;
			for (uint32 j = 0; j < trw.Count(); ++j)
			{
				const WStep& s = trw.Data()[j];
				tab.n[s.z]++;
				for (int k = 0; k < kWF; ++k) tab.c[s.z][k][s.f[k]]++;
			}
			// 🎯 ② **과제를 둘 돌린다** — 여유를 재는 것이 판정의 일부다(D73).
			for (int tk = 0; tk < 2; ++tk)
			{
				uint32 rs = 72000u + (uint32)sd * 7919u + (uint32)tk * 131u;
				Array<AStep> tr, te;
				_AFill(trw, tab, tk, rs, tr);
				_AFill(tew, tab, tk, rs, te);
				if (tr.Count() == 0u || te.Count() == 0u) continue;
				// 🧹 ③ 상수 줄기 — 시험집합에서 `z[t+1]` 이 안 갈리는 줄기(D71).
				Array<uint8> konst;
				konst.Reset(0);
				for (int q = 0; q <= stTe; ++q) konst.Add(1u);
				for (uint32 j = 0; j < te.Count(); ++j)
				{
					const AStep& s0 = te.Data()[j];
					for (uint32 q = 0; q < te.Count(); ++q)
						if (te.Data()[q].stem == s0.stem && te.Data()[q].nz != s0.nz)
							{ konst.Data()[(uint32)s0.stem] = 0u; break; }
				}
				uint32 nEx = 0u;
				for (uint32 j = 0; j < te.Count(); ++j)
					if (konst.Data()[(uint32)te.Data()[j].stem] == 0u) nEx++;
				if (nEx == 0u) continue;
				kstP[tk] += 100.0 * (double)(te.Count() - nEx) / (double)te.Count();
				// 🚪 ④ 대조군 — 시험집합의 최빈 **다음** 낱말(전부 · 제외).
				uint32 hz[3] = {}, hz2[3] = {};
				for (uint32 j = 0; j < te.Count(); ++j)
				{
					hz[te.Data()[j].nz]++;
					if (konst.Data()[(uint32)te.Data()[j].stem] == 0u) hz2[te.Data()[j].nz]++;
				}
				int mz = 0, mz2 = 0;
				for (int z = 1; z < 3; ++z) if (hz[z] > hz[mz]) mz = z;
				for (int z = 1; z < 3; ++z) if (hz2[z] > hz2[mz2]) mz2 = z;
				mBase[tk][0] += 100.0 * (double)hz[mz] / (double)te.Count();
				mBase[tk][1] += 100.0 * (double)hz2[mz2] / (double)nEx;
				// 🔗 ⑤ 사전항 `P(z'|w)` — **낱말 하나만** 쓴 마르코프 바닥.
				//   ★ 이것이 있어야 ㉡ 이 「특징 없이도 되는 만큼」을 넘었는지 알 수 있다.
				uint32 mk[4][3] = {};
				for (uint32 j = 0; j < tr.Count(); ++j) mk[tr.Data()[j].a[0]][tr.Data()[j].nz]++;
				{
					uint32 ok = 0u, ok2 = 0u;
					for (uint32 j = 0; j < te.Count(); ++j)
					{
						const AStep& s = te.Data()[j];
						int p = 0;
						for (int z = 1; z < 3; ++z) if (mk[s.a[0]][z] > mk[s.a[0]][p]) p = z;
						if (mk[s.a[0]][0] + mk[s.a[0]][1] + mk[s.a[0]][2] == 0u) p = -1;
						if (p == s.nz) ok++;
						if (konst.Data()[(uint32)s.stem] == 0u && p == s.nz) ok2++;
					}
					mPri[tk][0] += 100.0 * (double)ok / (double)te.Count();
					mPri[tk][1] += 100.0 * (double)ok2 / (double)nEx;
				}
				// 🧮 ⑥ **일곱 팔** — 좌표로 더하는 넷 + **색인으로 분할하는 셋**(D74).
				//   ★ 갈림은 한 줄이다: `part` 면 낱말이 **어느 표를 볼까**를 고르고,
				//     아니면 낱말이 **또 하나의 증거**가 된다. 그 둘이 전혀 다른 자리다.
				double aa[7][2] = {};
				for (int arm = 0; arm < 7; ++arm)
				{
					const bool part = (arm >= 4);
					const int nf = (arm == 0 || part) ? kWF : kAF;
					ATab at[4];
					for (uint32 j = 0; j < tr.Count(); ++j)
					{
						const AStep& s = tr.Data()[j];
						uint8 fb[kAF] = {};
						for (int k = 0; k < kWF; ++k) fb[k] = s.f[k];
						if (arm > 0 && !part) fb[kWF] = s.a[arm - 1];
						ATab& q = at[part ? s.a[arm - 4] : (uint8)0];
						q.n[s.nz]++;
						for (int k = 0; k < nf; ++k) q.c[s.nz][k][fb[k]]++;
					}
					uint32 ok = 0u, ok2 = 0u;
					for (uint32 j = 0; j < te.Count(); ++j)
					{
						const AStep& s = te.Data()[j];
						uint8 fb[kAF] = {};
						for (int k = 0; k < kWF; ++k) fb[k] = s.f[k];
						if (arm > 0 && !part) fb[kWF] = s.a[arm - 1];
						// 🚪 분포를 받아 **여기서만** 굳힌다(세계 경계).
						const MLChoice c = _AScore(at[part ? s.a[arm - 4] : (uint8)0], fb, nf);
						const int p = c.flat ? -1 : c.Argmax();
						if (p == s.nz) ok++;
						if (konst.Data()[(uint32)s.stem] == 0u && p == s.nz) ok2++;
					}
					aa[arm][0] = 100.0 * (double)ok / (double)te.Count();
					aa[arm][1] = 100.0 * (double)ok2 / (double)nEx;
					mArm[tk][arm][0] += aa[arm][0]; mArm[tk][arm][1] += aa[arm][1];
				}
				// 📏 씨앗별 부호검정 — **상수 줄기를 뺀** 값으로 본다(그것이 정직한 값이다).
				if (aa[1][1] > aa[0][1] + 3.0) upAnc[tk]++;
				if (aa[4][1] > aa[0][1] + 3.0) upIdx[tk]++;
				okSd[tk]++;
				mN[tk] += (double)te.Count();
			}
		}
		bool anyOk = false;
		for (int tk = 0; tk < 2; ++tk)
		{
			if (okSd[tk] == 0) { LogA("[ml]   🔗 ⚠️ **과제 %d 판정불가**\n", tk); continue; }
			const double d = (double)okSd[tk];
			for (int q = 0; q < 2; ++q)
			{
				mBase[tk][q] /= d; mPri[tk][q] /= d;
				for (int arm = 0; arm < 7; ++arm) mArm[tk][arm][q] /= d;
			}
			kstP[tk] /= d; mN[tk] /= d;
			LogA("[ml]   ── 🎯 **과제 %d** — %s  (걸음 **%.0f개** · 상수 줄기 %.1f%%)\n"
				"[ml]      🚪 대조군(최빈)         전부 **%.1f%%** │ 🧹 제외 **%.1f%%**\n"
				"[ml]      🔗 사전항(낱말 하나만)   전부 **%.1f%%** │ 🧹 제외 **%.1f%%**\n"
				"[ml]      ㉠ 특징만(27칸)         전부 **%.1f%%** │ 🧹 제외 **%.1f%%**\n"
				"[ml]      ㉡ +**낱말**(28칸)       전부 **%.1f%%** │ 🧹 제외 **%.1f%%**  ⇐ 앵커\n"
				"[ml]      ㉢ +무작위(28칸)         전부 **%.1f%%** │ 🧹 제외 **%.1f%%**  ⇐ 같은 비용\n"
				"[ml]      ㉣ +뒤섞음(28칸)         전부 **%.1f%%** │ 🧹 제외 **%.1f%%**  ⇐ 끊는다\n",
				tk, kATask(tk), mN[tk], kstP[tk],
				mBase[tk][0], mBase[tk][1], mPri[tk][0], mPri[tk][1],
				mArm[tk][0][0], mArm[tk][0][1], mArm[tk][1][0], mArm[tk][1][1],
				mArm[tk][2][0], mArm[tk][2][1], mArm[tk][3][0], mArm[tk][3][1]);
			LogA("[ml]      ── 🗂️ 여기부터는 **좌표가 아니라 색인**이다(낱말마다 다른 표)\n"
				"[ml]      ㉤ **낱말마다 표**(4벌)    전부 **%.1f%%** │ 🧹 제외 **%.1f%%**  ⇐ 앵커\n"
				"[ml]      ㉥ 무작위 3분할           전부 **%.1f%%** │ 🧹 제외 **%.1f%%**  ⇐ 같은 비용\n"
				"[ml]      ㉦ 뒤섞음으로 분할        전부 **%.1f%%** │ 🧹 제외 **%.1f%%**  ⇐ 끊는다\n",
				mArm[tk][4][0], mArm[tk][4][1], mArm[tk][5][0], mArm[tk][5][1],
				mArm[tk][6][0], mArm[tk][6][1]);
			const double gA = mArm[tk][1][1] - mArm[tk][0][1];   // ㉡ − ㉠  앵커의 이득
			const double gR = mArm[tk][2][1] - mArm[tk][0][1];   // ㉢ − ㉠  같은 비용의 가짜
			const double gS = mArm[tk][3][1] - mArm[tk][0][1];   // ㉣ − ㉠  끊은 가짜
			// 📏 **잴 수 있나**(함정 219) — 두 정보원이 **겹치면** 합쳐도 안 오른다.
			//   ★ 재는 법: 「특징만」과 「낱말만」의 거리. 가까우면 서로 대체 가능하다는 뜻이다.
			const double room = mArm[tk][0][1] - mPri[tk][1];
			const bool wide = (room >= 3.0 || room <= -3.0);
			const bool fake = (gR < 2.0 && gR > -2.0) && (gS < 2.0 && gS > -2.0);
			const bool used = (gA >= 3.0 && upAnc[tk] * 6 >= okSd[tk] * 5);
			// 🗂️ **색인 팔** — 같은 세 물음을 분할로 다시 묻는다(D74).
			const double iA = mArm[tk][4][1] - mArm[tk][0][1];   // ㉤ − ㉠
			const double iR = mArm[tk][5][1] - mArm[tk][0][1];   // ㉥ − ㉠  (쪼개진 값만)
			const double iS = mArm[tk][6][1] - mArm[tk][0][1];   // ㉦ − ㉠
			const bool iUsed = (iA >= 3.0 && upIdx[tk] * 6 >= okSd[tk] * 5);
			const bool iFake = (iR <= iA - 3.0) && (iS <= iA - 3.0);
			if ((used && fake) || (iUsed && iFake)) anyOk = true;
			LogA("[ml]      📏 **잴 수 있나** — 특징이 낱말보다 **%+.1f%%p**"
				"(㉠ %.1f ↔ 사전항 %.1f) ⇒ %s\n"
				"[ml]      ㉠ **앵커로 쓰이나** — ㉡ − ㉠ = **%+.1f%%p** · 씨앗 %d/%d ⇒ %s\n"
				"[ml]      ㉡ **값을 한 것이 내용인가** — ㉢ %+.1f%%p · ㉣ %+.1f%%p ⇒ %s\n"
				"[ml]      ㉤ **색인으로 쓰이나** — ㉤ − ㉠ = **%+.1f%%p** · 씨앗 %d/%d ⇒ %s\n"
				"[ml]      ㉥ **쪼갠 값을 넘었나** — ㉥ %+.1f%%p · ㉦ %+.1f%%p ⇒ %s\n",
				room, mArm[tk][0][1], mPri[tk][1],
				wide ? "✅ **여유가 있다** — 이 과제로는 앵커를 잴 수 있다"
					: "⛔ **여유가 없다** — 두 정보원이 겹치므로 이 과제로는 **원리적으로 못 잰다**",
				gA, upAnc[tk], okSd[tk],
				used ? "✅ **쓰인다**"
					: ((gA >= 3.0) ? "⚠️ **평균은 넘는데 씨앗이 모자라다**(10/12 기준)"
						: "⛔ **안 오른다**"),
				gR, gS,
				fake ? "✅ **가짜 둘이 제자리다** — 좌표를 하나 더해서 오른 것이 아니다"
					: "⛔ **가짜도 오른다** — 오른 것은 좌표가 늘어난 것이지 낱말이 아니다",
				iA, upIdx[tk], okSd[tk],
				iUsed ? "✅ **색인으로 쓰인다**"
					: ((iA >= 3.0) ? "⚠️ **평균은 넘는데 씨앗이 모자라다**(10/12 기준)"
						: "⛔ **안 오른다**"),
				iR, iS,
				iFake ? "✅ **분할의 값을 이겼다** — 오른 것은 쪼갠 것이 아니라 **낱말**이다"
					: "⛔ **가짜 분할과 못 가른다** — 쪼갠 효과이지 낱말이 아니다");
		}
		LogA("[ml]      ⇒ %s\n",
			anyOk
				? "✅✅✅ ***낱말이 앵커로 쓰인다*** — 스스로 낸 심볼이 다음 배움을 낫게 했고, 그"
				  " 이득이 **내용에 매여** 있다(뒤섞으면 사라진다)"
				: "⛔ **아직 앵커로 안 쓰인다** — 어느 과제에서도 낱말이 특징 위에 보태지 않았다");
	}
	// ══════════════════════════════════════════════════════════════════
	// 🗣️ **D58 · 호/불호 낱말의 분포** — 학습 **전에** 채널이 살았나 본다.
	//
	// ★ **왜 학습보다 먼저인가** — D56 이 그 값을 증명했다: 코드를 한 줄도 안 고치고
	//   「세계에 없는 것」을 알아서 헛수고를 막았다. 여기서 물을 것은 둘이다:
	//   ㉠ **세 낱말이 다 나오나**(하나가 0%면 채널이 퇴화한다) ·
	//   ㉡ **최빈 낱말이 몇 %인가**(그것이 곧 다음 라운드 ㉠ 판정의 **대조군**이다 · 함정 135:
	//     기준선은 **같은 시험집합**에서 와야 한다).
	//
	// ★ **목표 = 그 에피소드의 마지막 프레임.** 거리는 **다른 바이트 수**다 — 손 상수로
	//   「같다」를 정하지 않는다(🚫). ⚠️ 절대 프레임이 필요하므로 `PackRGB332Delta(cur,
	//   **nullptr**, ...)` 로 매 장을 **절대**로 팩한다(델타를 되만들면 0 이 「검정」과
	//   「안 바뀜」 두 뜻을 겸해 구별이 안 된다 — D56 이 그것을 정직한 경계로 적었다).
	//
	// ★ 낱말 셋(걸음 `t` 마다):
	//   · `d[t] == 0`            → **됐다**   (목표에 닿았다)
	//   · `d[t] <  d[t-1]`       → **나아짐** (가까워졌다 = 호)
	//   · 그 밖                  → **막힘**   (움직였는데 안 가까워졌다 = 불호)
	//   ⚠️⚠️ **「막힘」의 뜻이 하나가 아니다** — ㉠ *정말 막힌 것*과 ㉡ *아직 멀어서 두 자리가
	//     아예 안 겹치는 것*(그러면 다른 바이트 수가 `2·size²` 로 **상수**다)이 같은 낱말을
	//     받는다. 그것은 **화소 거리의 성질**이고 이 라운드가 그 비율을 처음 보여 준다.
	//     ⇒ 만약 「막힘」이 대부분 ㉡ 이면 거리를 고쳐야 한다(예: 겹침 대신 중심거리).
	// ⚠️ **「방금 실행한 줄」은 안 쓴다** — 이 세계는 `OnFrame` 한 덩어리를 매 장 통째로 돌리므로
	//   줄 단위 귀속이 원리적으로 없다. 줄마다 호/불호를 붙이려면 세계가 더 잘게 갈려야 한다(다음 칸).
	// ⚠️ 학습은 **한 줄도 없다.** 여기서 나오는 것은 **세계의 성질**이다.
	// ══════════════════════════════════════════════════════════════════
	// 🎨 **배경 바이트** — 그 장에서 **가장 많은 바이트**다.
	//
	// ⚠️⚠️⚠️ **함정 207 — 절대 RGB332 에는 0 이 없다.** `ImageOps` 의 `_Pack332R0` 이
	//   `v == 0 → 1` 을 한다: 델타 인코딩에서 **0 이 「안 바뀜」의 예약값**이므로 진짜 검정을
	//   0 으로 두면 두 뜻이 겸쳐진다(함수 이름의 `R0` = reserve 0).
	//   ⇒ 그래서 「0 이 아닌 바이트 = 도형」이라는 관용구는 **모든 픽셀을 도형으로** 만든다.
	//   ⚠️ 실측으로 밟았다: 무게중심이 모든 장에서 `(504, 504)`(= 31.5px = 캔버스 **정중앙**) ·
	//     잉크 **4096**(= 전체) ⇒ 자리 거리가 **항상 0** ⇒ 낱말이 「됐다」 **100%** 로 찍혔다.
	//   ⚠️⚠️ 그리고 **결과가 그럴듯했다** — 「됐다 100%」는 *"목표에 늘 닿아 있다"* 로 읽히므로
	//     버그처럼 안 보인다. 잡은 것은 **값을 찍은 것**이다(D54 와 같은 처방).
	// ★ 그래서 상수를 박지 않고 **읽는다** — 세계가 배경을 바꿔도 안 깨진다.
	//   (`episodegen.cw` 머리말의 *"판독기가 「배경 아닌 픽셀」로 도형을 찾는다"* 와 같은 규칙이다.)
	static uint8 _BgByte(const uint8* p, uint64 n)
	{
		uint32 h[256] = {};
		for (uint64 k = 0; k < n; ++k) h[p[k]]++;
		int b = 0;
		for (int v = 1; v < 256; ++v) if (h[v] > h[b]) b = v;
		return (uint8)b;
	}

	// 🧭 **잉크의 무게중심**(1/16 px) — 잉크 = **배경이 아닌 바이트**.
	//   ⚠️ 정수로 낸다 — 부동소수로 「줄었나」를 견주면 같은 자리가 반올림에 따라 갈린다
	//     (판정이 잡음을 타면 그것은 손 상수를 박는 것과 같다).
	static void _Centroid16(const uint8* p, int cell, uint8 bg,
		int64& cx16, int64& cy16, uint64& ink)
	{
		int64 sx = 0, sy = 0; uint64 n = 0;
		for (int y = 0; y < cell; ++y)
			for (int x = 0; x < cell; ++x)
				if (p[(uint64)y * (uint64)cell + (uint64)x] != bg)
					{ sx += x; sy += y; n++; }
		ink = n;
		cx16 = (n > 0u) ? (sx * 16 / (int64)n) : 0;
		cy16 = (n > 0u) ? (sy * 16 / (int64)n) : 0;
	}

	void _RunValence()
	{
		const int cell = MLEpisodeGen::kSize;
		const uint64 plane = (uint64)cell * (uint64)cell;
		const int kSeeds = 24;
		static const char* kD[2] = { "겹침(다른 바이트)", "**자리**(중심거리)" };
		LogA("[ml] ── 📐 **D59 · 거리를 「자리」로 잰다** — 호/불호에 **정도**를 준다 ──────────\n"
			"[ml]   ★ D58 이 보냈다(**함정 206**): 화소 겹침은 두 도형이 **안 겹치는 동안 상수**라"
			" 「가까워진다」를 못 잰다 ⇒ 6칸의 나아짐이 **0.0%%** 였다\n"
			"[ml]   ★ 그래서 거리를 **잉크의 무게중심 사이 맨해튼 거리**(1/16 px · 정수)로 다시 잰다.\n"
			"[ml]      ⚠️ `MLFacts` 를 **고치는 것이 아니다**(🚫) — 프레임에서 자리를 **읽는** 것이다.\n"
			"[ml]      ⚠️ 무게중심은 **세계가 낱말을 붙일 때만** 쓴다 — 학습자에게 주는 입력이 아니다.\n"
			"[ml]   ★ 미리 등록(**크기까지**):\n"
			"[ml]      ㉠ **6칸의 나아짐 > 20%%** ⇒ 「정도」가 생겼다(대조군 = 겹침 팔의 **0.0%%**)\n"
			"[ml]      ㉡ ⚠️ **예측: 「막힘」이 크게 줄거나 0 이 된다.** 이 세계엔 아직 **벽이 없고**"
			" 바닥은 「막힘」이 아니라 **「도착」**이다 ⇒ 「움직였는데 안 가까워진다」가 원리적으로 없다\n"
			"[ml]      ㉢ 그러면 세 낱말 균형(각 >= 10%%)은 **깨진다** — 그리고 그것이 곧"
			" ***「벽」을 만들 근거***다(D57 이 미뤄 둔 그것)\n"
			"[ml]      ㉣ **칸별로 본다** — 합계만 보면 칸별 퇴화를 놓친다(함정 206 의 뒷부분)\n"
			"[ml]   ⚠️ 두 팔을 **같은 에피소드**에서 센다(프레임을 두 번 안 돌린다 · 함정 135)\n"
			"[ml]   ⚠️ 씨앗 %d개/칸 · 주석 끔 · 칸 %dpx\n", kSeeds, cell);
		int tot[2][3] = {};
		double pr[2][12][3] = {};
		for (int rung = 4; rung <= 11; ++rung)
		{
			int w[2][3] = {}; int epN = 0;
			for (int s = 0; s < kSeeds; ++s)
			{
				MLEpisode ep;
				MLEpisodeGen::Build(rung,
					MLEpisodeGen::ScrambleSeed(58000u + (uint32)(rung * 100 + s)), false, ep);
				DrawProgram prog;
				if (!prog.Compile(ep.code.View(), (uint32)cell, (uint32)cell, NameID("Val"))) continue;
				const int frames = (ep.frameCount > 0) ? ep.frameCount : 1;
				if (frames < 2 || frames > 8) continue;
				// 🎞️ 매 장을 **절대**로 팩한다(`prev = nullptr`).
				Bytes abs;
				abs.Reset(plane * (uint64)frames);
				bool ok = true;
				for (int f = 0; f < frames && ok; ++f)
				{
					ok = (f == 0) ? prog.RunStart() : prog.RunFrame();
					if (!ok) break;
					uint8* pl = (uint8*)abs.GetData() + plane * (uint64)f;
					ok = ImageFormat::PackRGB332Delta(prog.canvas, nullptr, pl, plane);
				}
				if (!ok) continue;
				epN++;
				// 🎯 목표 = 마지막 장. **두 거리를 한 번에** 낸다.
				// 🎯 **목표** — `goalCode` 가 있으면 **그것을 돌린 마지막 장**이다(그 에피소드에 한 장도
				//   안 나오는 장면일 수 있다). ★ 그것이 「막힘」의 조건이다: 목표가 **도달 불가능**할
				//   수 있어야 «가려던 데를 못 갔다» 가 생긴다(D59: 바닥만으로는 막힘이 0.0% 였다 —
				//   바닥은 「막힘」이 아니라 **「도착」**이기 때문이다).
				Bytes gbuf;
				const uint8* goal = nullptr;
				if (!ep.goalCode.IsEmpty())
				{
					DrawProgram gp;
					if (!gp.Compile(ep.goalCode.View(), (uint32)cell, (uint32)cell, NameID("Goal"))) continue;
					gbuf.Reset(plane);
					bool gok = gp.RunStart();
					for (int gf = 1; gf < frames && gok; ++gf) gok = gp.RunFrame();
					if (gok) gok = ImageFormat::PackRGB332Delta(gp.canvas, nullptr,
						(uint8*)gbuf.GetData(), plane);
					if (!gok) continue;
					goal = (const uint8*)gbuf.GetData();
				}
				else goal = (const uint8*)abs.GetData() + plane * (uint64)(frames - 1);
				int64 gx = 0, gy = 0; uint64 gi = 0;
				const uint8 bgG = _BgByte(goal, plane);
				_Centroid16(goal, cell, bgG, gx, gy, gi);
				int64 dd[2][8] = {};
				// 🐛 **함정 207 을 여기서 밟았다** — 이 자리에 임시 진단을 넣어 값을 찍고 잡았다:
				//   무게중심이 모든 장에서 `(504, 504)` · 잉크 **4096**(= 전체) ⇒ 자리 거리가 항상 0.
				//   ★ **추론으로는 코드가 맞아 보였다** — 잡은 것은 값을 찍은 것이다(D54 와 같은 처방).
				for (int f = 0; f < frames; ++f)
				{
					const uint8* pf = (const uint8*)abs.GetData() + plane * (uint64)f;
					int64 ov = 0;
					for (uint64 k = 0; k < plane; ++k) if (pf[k] != goal[k]) ov++;
					dd[0][f] = ov;
					int64 cx = 0, cy = 0; uint64 ci = 0;
					_Centroid16(pf, cell, _BgByte(pf, plane), cx, cy, ci);
					// ⚠️ 잉크가 없으면 자리가 없다 ⇒ **가장 먼 값**으로 둔다(조용히 0 이 되면 「됐다」가 된다).
					if (ci == 0u || gi == 0u) dd[1][f] = (int64)cell * 16 * 2;
					else dd[1][f] = ((cx > gx) ? (cx - gx) : (gx - cx))
						+ ((cy > gy) ? (cy - gy) : (gy - cy));
				}
				for (int a = 0; a < 2; ++a)
					for (int f = 1; f < frames; ++f)
					{
						const int64 d = dd[a][f], pv = dd[a][f - 1];
						const int z = (d == 0) ? 2 : ((d < pv) ? 0 : 1);
						w[a][z]++; tot[a][z]++;
					}
			}
			for (int a = 0; a < 2; ++a)
			{
				const int n = w[a][0] + w[a][1] + w[a][2];
				for (int z = 0; z < 3; ++z)
					pr[a][rung][z] = (n > 0) ? (100.0 * (double)w[a][z] / (double)n) : 0.0;
				LogA("[ml]      %d칸 · %-20s — 걸음 %3d │ 나아짐 %3d(%5.1f%%) · 막힘 %3d(%5.1f%%) ·"
					" 됐다 %3d(%5.1f%%)\n",
					rung, kD[a], n,
					w[a][0], pr[a][rung][0], w[a][1], pr[a][rung][1], w[a][2], pr[a][rung][2]);
			}
		}
		double ap[2][3] = {};
		for (int a = 0; a < 2; ++a)
		{
			const int N = tot[a][0] + tot[a][1] + tot[a][2];
			for (int z = 0; z < 3; ++z)
				ap[a][z] = (N > 0) ? (100.0 * (double)tot[a][z] / (double)N) : 0.0;
			LogA("[ml]      ⇒ 합계 · %-20s — 나아짐 %5.1f%% · 막힘 %5.1f%% · 됐다 %5.1f%%\n",
				kD[a], ap[a][0], ap[a][1], ap[a][2]);
		}
		// ⚠️⚠️ 판정은 **칸별과 합계를 둘 다** 본다(함정 206 의 뒷부분).
		const double up6 = pr[1][6][0];             // ㉠ 자리 팔의 6칸 나아짐
		const double st = ap[1][1];                 // ㉡ 자리 팔의 막힘(합계)
		const double st7 = pr[1][7][1];             // 🧱 D60 — **7칸(벽)의 막힘**
		double lo = 100.0;
		for (int z = 0; z < 3; ++z) if (ap[1][z] < lo) lo = ap[1][z];
		LogA("[ml]      ㉠ **6칸의 나아짐** — 겹침 %.1f%% → **자리 %.1f%%** ⇒ %s\n"
			"[ml]      ㉡ **막힘**(합계) — 겹침 %.1f%% → **자리 %.1f%%** ⇒ %s\n"
			"[ml]      ㉢ 세 낱말의 최소 비율 %.1f%% ⇒ %s\n"
			"[ml]      ㉢ᐟ 🧱 **7칸(벽)의 막힘 %.1f%%** (등록 **> 30%%**) ⇒ %s\n"
			"[ml]      ⇒ %s\n",
			pr[0][6][0], up6,
			(up6 > 20.0) ? "✅ ***「정도」가 생겼다*** — 자리 거리는 겹치기 전에도 줄어든다"
				: "⛔ **여전히 안 생긴다** — 자리 거리도 이 세계에서는 「가까워짐」을 못 낸다",
			ap[0][1], st,
			// 🧱 **D60 에서 뜻이 뒤집혔다** — D59 에서는 「막힘 0%」가 예측 적중이었지만(벽이
			//   없었으니까) 이제 7칸이 벽을 준다 ⇒ **막힘이 남는 것이 정상**이다.
			(st > 5.0) ? "✅ ***벽이 「막힘」을 되살렸다*** — D59 에서는 자리 거리로 0.0% 였다"
				: "⛔ **여전히 0 이다** — 벽이 낱말을 안 만든다(목표 정의를 다시 봐야 한다)",
			lo,
			(lo >= 10.0) ? "✅ 세 낱말이 다 살았다"
				: "⚠️ **균형이 깨졌다** — 어느 낱말이 드문지 칸별로 본다",
			st7,
			(st7 > 30.0) ? "✅ ***벽이 「막힘」을 만든다*** — 목표가 도달 불가능하면 낱말이 생긴다"
				: "⛔ **벽으로도 안 생긴다** — 목표 정의를 다시 봐야 한다",
			(up6 <= 20.0)
				? "⛔ **거리 정의로는 안 풀린다** — 「정도」를 다른 데서 찾아야 한다"
				: ((lo >= 10.0 && st7 > 30.0)
					? "✅✅✅ ***정도와 균형을 다 얻었다*** — 세 낱말이 다 살아 있고 벽이 「막힘」을"
					  " 만든다 ⇒ 다음은 **낱말을 학습에 붙이는 것**이다(대조군 = 최빈 낱말 비율)"
					: ((st7 > 30.0)
						? "✅⭐ **벽은 통했는데 합계 균형이 얇다** — 어느 칸을 몇 개 뽑나(칸 비율)가"
						  " 다음 손잡이다. ⚠️ 균형을 세계로 맞추는 것과 표본으로 맞추는 것은 다르다"
						: "⛔ **벽이 「막힘」을 안 만든다** — 목표 정의를 다시 봐야 한다")));
	}
	// ══════════════════════════════════════════════════════════════════
	// 🍎 **D56 · 「막힘」이 세계에 있나** — 코딩 세계의 첫 라운드.
	//
	// ⚠️⚠️ **세계를 짓기 전에 세계를 재라.** 지금 커리큘럼은 「그린다」뿐이고 **실패가 없다** ⇒
	//   「막힘」이 0개면 호/불호가 **상수**이고, 상수 채널은 아무것도 안 가르친다 — 그것은
	//   `MLLife` 의 `trust`(칸마다 같은 값)가 평평했던 것의 **재현**이다(→ ML.md 의 🚫).
	// ★ **그리고 재는 장치가 이미 있다** — `_RunEpisode` 가 프레임을 **키프레임 1 + 델타 N**
	//   으로 팩하고 그 주석이 말한다: *"정지한 장면은 뒤 프레임이 전부 0 이라 바이트열이 최대로
	//   예측 가능해지고, 움직이는 것만 값이 남는다"*.
	//   ⇒ ***「막힘」 = 델타가 전부 0 인 걸음.*** 새 계측을 만들 필요가 없다.
	// ★ **미리 등록**(진단이라 이득 문턱이 아니라 **분기**다):
	//   ㉠ 안 변한 걸음 **> 5%** ⇒ 「막힘」이 이미 세계에 있다 ⇒ 다음은 그것에 **낱말을 붙이는 것**
	//   ㉡ **≈ 0%** ⇒ 세계에 없다 ⇒ 다음은 **6칸(바닥·목표)을 추가하는 것**(능력 하나 = 「조건」)
	// ★ 같이 재는 것 — **걸음마다 바뀐 바이트 수의 흐름**(첫 걸음 ↔ 끝 걸음):
	//   `_Fall` 은 가속이라 **늘어야** 하고, `_Move` 는 **일정**해야 하고, 화면 밖으로 나가면
	//   **0 으로 떨어진다** ⇒ 그 모양 자체가 「막힘」이 있는지의 그림이다.
	// ⚠️ **정직한 경계**: 「되돌아옴」과 「목표거리 단조성」은 **안 쟀다** — 팩이 델타라
	//   절대 프레임을 되만들어야 하고, 그 되만들기는 *"픽셀이 정말 0 이 된 것"* 과 *"안 바뀐 것"* 을
	//   구별하지 못한다(0 이 두 뜻을 겸한다). 그것을 재려면 절대 판을 따로 들어야 한다 ⇒ 다음 칸.
	// ⚠️ 커리큘럼 1~5 는 **안 고친다**(추가만 · 🚫) · 씨앗을 적어 재현한다.
	// ══════════════════════════════════════════════════════════════════
	void _RunStuck()
	{
		const int cell = MLEpisodeGen::kSize;
		const uint64 plane = (uint64)cell * (uint64)cell;
		const int kSeeds = 24;
		LogA("[ml] ── 🍎 **D56 · 「막힘」이 세계에 있나** — 코딩 세계의 첫 진단 ──────────────\n"
			"[ml]   ★ 트랙을 바꿨다: 셈 표는 **순서를 표현 못 한다** ⇒ 목표·막힘·성공은 그 위에서"
			" 원리적으로 안 된다. 새 판정 = **코드가 몸 · 목표 그림이 욕구 · 목표거리의 부호가 호/불호**\n"
			"[ml]   ★ 재는 장치는 이미 있다 — `_RunEpisode` 가 **키프레임 1 + 델타 N** 으로 팩하고"
			" *정지한 장면은 뒤 프레임이 전부 0* 이다 ⇒ ***「막힘」 = 델타가 전부 0 인 걸음***\n"
			"[ml]   ★ 미리 등록(**분기**다 · 이득 문턱이 아니다):"
			" ㉠ 안 변한 걸음 **> 5%%** ⇒ 세계에 이미 있다 ⇒ 다음은 **낱말 붙이기** ·"
			" ㉡ **≈ 0%%** ⇒ 없다 ⇒ 다음은 **6칸(바닥·목표) 추가**\n"
			"[ml]   ⚠️ 커리큘럼 1~5 는 안 고친다(추가만) · 씨앗 %d개/칸 · 주석 끔 · 칸 %dpx\n",
			kSeeds, cell);
		ImageFormat::Bitmap junk;
		if (!ImageFormat::CreateRGBA8(junk, (uint32)cell, (uint32)cell))
			{ LogA("[ml]   ⛔ 비트맵을 못 만들었다\n"); return; }
		int allN = 0, allS = 0;
		for (int rung = 1; rung <= 11; ++rung)
		{
			int stepN = 0, stillN = 0, epN = 0, dead = 0;
			double first = 0.0, last = 0.0; int firstN = 0, lastN = 0;
			for (int s = 0; s < kSeeds; ++s)
			{
				MLEpisode ep;
				MLEpisodeGen::Build(rung,
					MLEpisodeGen::ScrambleSeed(56000u + (uint32)(rung * 100 + s)), false, ep);
				Bytes packed;
				if (!_RunEpisode(ep, junk, 0, cell, packed)) continue;
				epN++;
				const int frames = (ep.frameCount > 0) ? ep.frameCount : 1;
				if (frames < 2) continue;                  // 걸음이 없으면 「막힘」도 정의되지 않는다
				const uint8* base = (const uint8*)packed.GetData();
				bool tail = true;                          // 끝까지 멈춰 있었나(= 화면 밖으로 나갔다)
				for (int f = 1; f < frames; ++f)
				{
					const uint8* p = base + plane * (uint64)f;
					uint64 nz = 0;
					for (uint64 k = 0; k < plane; ++k) if (p[k] != 0u) nz++;
					stepN++; allN++;
					if (nz == 0u) { stillN++; allS++; } else tail = false;
					if (f == 1) { first += (double)nz; firstN++; }
					if (f == frames - 1) { last += (double)nz; lastN++; }
				}
				if (tail) dead++;                          // 첫 걸음부터 아무것도 안 변했다
			}
			const double pct = (stepN > 0) ? (100.0 * (double)stillN / (double)stepN) : 0.0;
			LogA("[ml]      %d칸 — 에피소드 %2d · 걸음 %3d · **안 변한 걸음 %3d(%.1f%%)** │"
				" 바뀐 바이트 첫 %.0f → 끝 %.0f · 통째로 멈춘 것 %d\n",
				rung, epN, stepN, stillN, pct,
				(firstN > 0) ? (first / (double)firstN) : 0.0,
				(lastN > 0) ? (last / (double)lastN) : 0.0, dead);
		}
		const double all = (allN > 0) ? (100.0 * (double)allS / (double)allN) : 0.0;
		LogA("[ml]      ⇒ **전체 — 걸음 %d 중 안 변한 것 %d(%.1f%%)**\n"
			"[ml]      ⇒ %s\n",
			allN, allS, all,
			(all > 5.0)
				? "✅ ***「막힘」이 이미 세계에 있다*** — 호/불호가 상수가 아니다 ⇒ 다음은 그것에"
				  " **낱말을 붙이는 것**(「나아짐」·「막힘」·「됐다」를 캡션과 같은 알파벳으로)"
				: ((all > 0.5)
					? "⚠️ **있는데 드물다** — 낱말을 붙이기엔 표본이 얇다 ⇒ 6칸(바닥·목표)을 더해"
					  " 「막힘」을 **세계의 규칙**으로 만든 뒤 낱말을 붙인다"
					: "⛔ ***「막힘」이 세계에 없다*** — 호/불호가 상수가 된다(= `trust` 의 재현) ⇒"
					  " 다음은 **6칸을 추가하는 것**이다: 떨어지는 것에 **바닥**, 움직이는 것에 **벽**"));
	}
	// 🎲 커리큘럼 5칸을 만들고 실행해서 격자 한 장으로 떨어뜨린다.
	//   ★ 판정 둘을 여기서 같이 본다: ① 다섯 칸이 맞게 그려지나(그림) ② **같은 코드 두 번이 같은
	//     바이트를 내나**(결정성). ②가 깨지면 `코드 → 프레임` 이 함수가 아니라는 뜻이고 이 설계의
	//     전제가 무너진다 — 그래서 그림보다 먼저 확인해야 하는 성질이다.
	void _RunProbe()
	{
		const int cell = MLEpisodeGen::kSize;
		const int cols = 6;     // 4·5칸이 6프레임이라 그만큼
		const int rows = 11;     // 커리큘럼 일곱 칸(6 = 바닥 · 7 = 벽 · D57·D60)

		ImageFormat::Bitmap grid;
		if (!ImageFormat::CreateRGBA8(grid, (uint32)(cell * cols), (uint32)(cell * rows)))
		{
			LogA("[ml] 격자 비트맵을 못 만들었다\n");
			return;
		}
		// 칸 사이가 보이게 배경을 아주 어둡게(검정이 아니라 — 도형의 검은 배경과 구분된다).
		ImageFormat::Fill(grid, Vector4(0.16f, 0.16f, 0.20f, 1.0f));

		int okRungs = 0;
		for (int rung = 1; rung <= rows; ++rung)
		{
			MLEpisode ep;
			MLEpisodeGen::Build(rung, (uint32)(1000u + (uint32)rung), true, ep);

			LogA("\n[ml] ────── %d칸  seed=%u  프레임 %d ──────\n%s", rung, ep.seed, ep.frameCount,
				ep.code.ptr());
			LogA("[ml] 캡션: %s\n", ep.caption.ptr());

			Bytes packedA;
			if (!_RunEpisode(ep, grid, rung - 1, cell, packedA)) continue;

			// ② 결정성 — 같은 씨앗으로 다시 만들어 다시 돌리고 **첫 프레임 바이트를 견준다**.
			MLEpisode ep2;
			MLEpisodeGen::Build(rung, ep.seed, true, ep2);
			Bytes packedB;
			ImageFormat::Bitmap junk;   // 두 번째는 격자에 안 그린다(같은 자리를 덮을 뿐이다)
			if (!ImageFormat::CreateRGBA8(junk, (uint32)cell, (uint32)cell)) continue;
			if (!_RunEpisode(ep2, junk, 0, cell, packedB)) continue;

			const bool sameCode = (ep.code == ep2.code);
			const bool sameBytes = _SameBytes(packedA, packedB);
			LogA("[ml] %d칸 결정성: 코드 %s · 프레임 바이트 %s\n", rung,
				sameCode ? "같다" : "★다르다★", sameBytes ? "같다" : "★다르다★");
			if (sameCode && sameBytes) okRungs++;
		}

		// 격자를 PNG 로 떨어뜨린다. ⚠️ 경로는 **앱의 작업 폴더**(`bin_dev`) 기준이다.
		Bytes png;
		if (ImageFormat::Save(grid, ImageFormat::ImageFileType::PNG, png))
		{
			// ⚠️ `PlatformFile`/`PlatformFileSource` 는 **`PE` 직속**이다(`PE::OS` 가 아니다 — 모듈 이름과
			//   이름공간이 다르다). `External` = 앱 작업 폴더 기준의 바깥 경로.
			if (PlatformFile::SaveBytes("ml_probe_grid.png", png, PlatformFileSource::External))
				LogA("\n[ml] 격자 저장: <bin_dev>/ml_probe_grid.png (%llu bytes)\n",
					(unsigned long long)png.GetSize());
			else
				LogA("\n[ml] 격자 저장 실패\n");
		}
		else LogA("\n[ml] PNG 인코딩 실패\n");

		LogA("[ml] P-1 프로브 끝 — 결정성 통과 %d/%d 칸\n", okRungs, rows);
	}

	// 에피소드 하나를 컴파일·실행하고 프레임을 `dst` 의 `row` 줄에 가로로 깐다.
	//   `outPacked` = **첫 프레임의 RGB332**(1픽셀 1바이트 = 모델이 실제로 보는 것).
	bool _RunEpisode(const MLEpisode& ep, ImageFormat::Bitmap& dst, int row, int cell, Bytes& outPacked)
	{
		// ⚠️ **값으로 든다** — `NewObject<T>` 는 `ObjectBase` 를 거절한다(`Object` 파생을 원한다).
		//   `Bitmap` 도 이미 값 멤버로 쓰이므로(AssetGen 의 `GenTexTarget::px`) 이물질이 아니다.
		DrawProgram prog;
		if (!prog.Compile(ep.code.View(), (uint32)cell, (uint32)cell, NameID("Probe")))
		{
			LogA("[ml] %d칸: 컴파일 실패(진단은 위 로그)\n", ep.rung);
			return false;
		}

		// 🎞️ **키프레임 1 + 델타 N** — 프레임마다 `cell²` 바이트씩 이어 붙인다.
		//   ★ 첫 장은 절대(`prev = nullptr`), 그 뒤는 **바뀐 자리만**. 정지한 장면은 뒤 프레임이
		//     전부 0 이라 바이트열이 최대로 예측 가능해지고, 움직이는 것만 값이 남는다.
		//   ⚠️ **런렝스로 줄이지 않는다** — 0 을 뭉치는 일은 계층 기계가 배울 몫이다(→ ML.md).
		//   ⚠️ 이전 프레임을 **따로 보관**해야 한다 — `prog.canvas` 는 매 프레임 덮인다.
		const uint64 planeSize = (uint64)cell * (uint64)cell;
		const int frames = (ep.frameCount > 0) ? ep.frameCount : 1;
		outPacked.Reset(planeSize * (uint64)frames);
		ImageFormat::Bitmap prev;
		bool hasPrev = false;
		uint64 changed = 0;   // 델타 프레임에서 0 이 아닌 바이트 수(판정용)

		for (int f = 0; f < ep.frameCount; ++f)
		{
			const bool ok = (f == 0) ? prog.RunStart() : prog.RunFrame();
			if (!ok) { LogA("[ml] %d칸: 프레임 %d 실행 실패\n", ep.rung, f); return false; }

			// 칸에 그대로 복사된다(원본과 칸 크기가 같아 배율 1).
			if (f * cell < (int)dst.width)
			{
				ImageFormat::FitIntoRect(prog.canvas, dst, f * cell, row * cell, cell, cell,
					Vector4(0, 0, 0, 1));
			}

			uint8* plane = (uint8*)outPacked.GetData() + planeSize * (uint64)f;
			if (!ImageFormat::PackRGB332Delta(prog.canvas, hasPrev ? &prev : nullptr, plane, planeSize))
			{
				LogA("[ml] %d칸: RGB332 델타 팩 실패(프레임 %d)\n", ep.rung, f);
				return false;
			}
			if (f > 0)
			{
				for (uint64 i = 0; i < planeSize; ++i) if (plane[i] != 0u) changed++;
			}

			if (!ImageFormat::CreateRGBA8(prev, (uint32)cell, (uint32)cell)) return false;
			ImageFormat::FitIntoRect(prog.canvas, prev, 0, 0, cell, cell, Vector4(0, 0, 0, 1));
			hasPrev = true;
		}

		// 📊 **희소성 판정** — 델타가 정말 희소한가. 이 표현을 고른 이유이므로 숫자로 남긴다.
		if (ep.frameCount > 1)
		{
			const uint64 deltaBytes = planeSize * (uint64)(ep.frameCount - 1);
			LogA("[ml] %d칸 델타: %llu/%llu 바이트가 바뀌었다(%.1f%%) — 절대판이면 100%%\n",
				ep.rung, (unsigned long long)changed, (unsigned long long)deltaBytes,
				100.0 * (double)changed / (double)deltaBytes);
		}
		return true;
	}

	// ⚠️ 손으로 훑는다 — 이 자리에 `memcmp` 를 부르려고 `<cstring>` 을 끌어오지 않는다(`.cw` 규약).
	static bool _SameBytes(const Bytes& a, const Bytes& b)
	{
		if (a.GetSize() != b.GetSize()) return false;
		const uint8* pa = (const uint8*)a.GetData();
		const uint8* pb = (const uint8*)b.GetData();
		if (pa == nullptr || pb == nullptr) return false;
		for (uint64 i = 0; i < a.GetSize(); ++i)
			if (pa[i] != pb[i]) return false;
		return true;
	}

public:
	CW_OBJECT_BODY(MLTrainer, GUIWindowSubsystem)
};
