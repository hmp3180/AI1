// mlt.cw — 🪞 **MLT 트랙 진입** (`-mlt`)
//
// ★ **이 트랙이 묻는 것 하나**
//
//   언어 없이 상태값과 비전으로 경험을 먼저 쌓고, 그 위에 언어를 붙이면
//   **낱말·관계·예측·사슬추론이 생기나?**
//
//   ```
//   P 단계 (사전언어)  언어가 **한 토큰도 없다.** 감시는 「다음 스텝」과 「재구성」뿐
//   L 단계 (언어)      몸통을 **얼리고** 시작 ⇒ 언어는 이미 있는 표현을 **가리키는 것**이 된다
//   ```
//
//   ⇒ ⭐ **L0(얼린 표현 + 선형 프로브)이 「언어 귀속이 아니다」를 숫자로 만드는 칸이다.**
//
// ⚠️⚠️ **정본은 문서다** — 단계·관문·대조군은 `Projects/ML/MLT.md`, 원리·경계는 `mltconcept.md`.
//   코드가 그 둘과 갈리면 **문서가 이긴다**. 그리고 작업으로 달라지면 **같은 커밋에서** 문서를 고친다.
//
// ★ 자리: 커널과 CPU 레퍼런스는 **MLCore**(몸통), 조립·세계·러너는 **여기**(→ `module.toml` 의 그 절).

// ⚠️ `.cw` 는 헤더리스라 `#include` 를 안 쓰지만 **이름공간은 열어야 한다** — `MLCore/mlgpu.cw` 와
//   같은 관례다(실측: 없으면 `LogA` 가 `PE::LogA` 를 못 찾아 컴파일이 깨진다).
using namespace PE;

class MLT
{
public:
	// ══════════════════════════════════════════════════════════════════
	// 🚪 진입 — `MLApp` 의 `-mlt` 가 여기로 온다.
	//
	// ⚠️⚠️ **1회 가드를 여기 둔다**(부르는 쪽이 기억하게 하지 않는다). 부르는 자리가 `OnUpdate` 라
	//   매 프레임 돌고, 가드 없이 돌린 실측이 있다 — 진단이 끝없이 반복되어 **stdout 이 62MB** 가 되고
	//   프로브의 대기 조건(크기 안정)이 **원리적으로 성립하지 않아** 상한까지 갔다.
	//   ★ `MLDiff::Run()` 이 같은 이유로 자기 안에 가드를 갖고 있다 — 같은 관용구다.
	// ══════════════════════════════════════════════════════════════════
	static void Run()
	{
		static bool done = false;
		if (done) return;
		done = true;

		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] MLT — 사전학습 0 · 토크나이저 0 · 접지된 언어\n");
		LogA("[mlt] 정본: Projects/ML/MLT.md · mltconcept.md\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");

		// ── 배관 단계 ──────────────────────────────────────────────
		// ⚠️ **판정은 P0 부터 시작한다** — 아래 둘은 라운드가 아니라 배관이다(MLT.md 📌 의 1·2).
		//   ⭐ 그리고 **커널마다 gradcheck 통과가 완료 조건**이다. 이 저장소의 조용한 버그가 전부
		//     *"컴파일되고 안 죽고 숫자만 틀린다"* 였고 **학습 곡선으로는 못 본다.**
		_RunGradCheck();
	}

private:
	// ══════════════════════════════════════════════════════════════════
	// 🧪 **커널 검증** — 새 커널은 예외 없이 여기를 지난 뒤에 쓴다.
	//
	// ⚠️ 조건부가 필요한 자리 둘을 미리 적어 둔다(안 적으면 다음 사람이 «gradcheck 를 못 통과한다» 로
	//   오진한다):
	//   · `act_topk` — 선택이 **이산**이라 straight-through 다 ⇒ **「선택 고정 조건부」**로 잰다.
	//   · `val_enc`  — 정규화 계수가 **러닝 통계**(비미분 경로)다 ⇒ **「계수 고정 조건부」**로 잰다.
	// ⚠️ 그리고 `stopgrad` 를 켠 판은 **수치 기울기 ≠ 해석 기울기**다 ⇒ **끈 판에서 통과시키고,
	//   켠 판은 「그 경로가 정확히 0 인가」를 따로** 검사한다. **두 검사를 합치면 조용히 틀린다.**
	// ══════════════════════════════════════════════════════════════════
	static void _RunGradCheck()
	{
		// ⚠️ 지금 도는 것은 **판정 ② 뿐**이다(수치 미분 vs 해석 기울기 · CPU 레퍼런스만).
		//   ★ 판정 ①(GPU vs CPU)은 디스패치가 `OnPreGuiRender(RHICommandList*)` 라서
		//     `MLT::Tick(RHICommandList*)` 를 열어야 돈다 — 둘은 **다른 검사**다:
		//     ② 는 *"미분이 맞나"*, ① 은 *"셰이더가 CPU 와 같은 수를 내나"*.
		//   ⚠️ ② 만 통과한 것을 「커널이 섰다」로 인용하면 그 자리가 곧 오독이다.
		MLTGrad::RunAll();

		// ── 🚧 배관 관문 — ⚠️ **그림보다 먼저**, 그리고 **P0 보다 먼저** ─────────
		//   ★ 이것이 재는 것은 성능이 아니라 **전제**다: *"`씨앗 → 세계` 가 함수다"*.
		//     실패하면 **세계를 고친다**(모델을 고치지 않는다).
		MLTWorldGate::RunAll();

		// ── 📚 P0 · A단계 — ⚠️ **학습을 켜기 전에** 해석 팔 넷을 실측해 등록값과 대조한다.
		//   ★ 근거: `R = (학습 − 복사) / (최적 − 복사)` 의 **바닥과 분모**가 그 둘이다.
		//     저 둘이 세계와 안 맞으면 표제 지표가 통째로 거짓이고, 학습 곡선으로는 그것을 못 본다.
		MLTP0::RunBaselines();

		// ── 📚 P1 · A단계 — 축 셋의 바닥·천장. ⚠️ 축마다 `|Δ|` 가 달라 **바닥이 축마다 다르다**
		//   ⇒ 하나로 접으면 «축이 갈리나» 가 안 보인다(P1 등록문 ⑤ 의 그 이유).
		MLTP1::RunBaselines();

		// ── 🔗 회차 17 · A단계 — 얽힌 축(x·z)의 바닥·천장. ⚠️ 오라클이 yaw **값**(관측)을 쓴다.
		MLTPX::RunBaselines();

		// ── 👁️ P2 · A단계 — 프레임 통계와 재구성 대조군 둘의 MSE **정확값**.
		//   ⚠️ 인코더를 만들기 전에 **바닥을 정확히** 안다 — 관문 ㉠ 의 문턱이 그것으로 정해진다.
		MLTP2::RunBaselines();
	}

public:
	// ══════════════════════════════════════════════════════════════════
	// 🖥️ **판정 ① 의 훅** — `mltrainer.cw::OnPreGuiRender` 가 매 프레임 부른다(렌더 스레드).
	//   ⚠️ `Run()` 과 **다른 자리**다: `Run()` 은 `OnGuiUpdate`(CPU) 경로이고 여기가 GPU 경로다.
	//   ⚠️ 진행이 **프레임에 걸쳐** 있다(디스패치 → 다음 프레임 회수) ⇒ 1회 가드가 아니라 **단계**다.
	//   ⚠️ 채널이 작은 것(신뢰 채널)은 **채널별로 나눠 상대오차를 재라** — 큰 채널이 작은 채널의
	//     오차를 가린다(대역 관문과 같은 이유).
	// ══════════════════════════════════════════════════════════════════
	static void Tick(RHI* rhi)
	{
		// ⚠️ **순서가 계약이다** — 판정 ①(커널 한 장씩)이 끝난 뒤에 판정 ③(몸통 조립)이 온다.
		//   ★ 근거: ① 이 ⛔ 인데 ③ 을 읽으면 *"조립이 틀렸다"* 로 오진한다(원인이 커널일 수 있다).
		if (!MLTGpu::Done()) { MLTGpu::Tick(rhi); return; }
		// ⚠️ 판정 ③(조립)이 끝난 뒤에 P0 B단계가 온다 — 조립이 ⛔ 인데 학습 곡선을 읽으면
		//   *"안 배운다"* 로 오진한다(원인이 배선일 수 있다).
		if (!MLTFit::Done()) { MLTFit::Tick(rhi); return; }
		// 👁️ 그리고 **비전 인코더의 조립 검사**(판정 ③ 의 비전판) — ⚠️ 위 `MLTFit` 은 **트랜스포머
		//   몸통**을 쟀다. P2 의 인코더는 **다른 그래프**(패치표·사전·top-k·코드북)이므로 그 조립은
		//   그것으로 안 재진다. ★ 판정이지 회차가 아니라 **늘 돈다**(`MLTFit` 과 같은 계약).
		//   ⚠️ 값 = 600 프레임(≈ 몇 초). 그 값을 아끼려고 끄면 인코더를 고칠 때마다 **조용해진다.**
		if (!MLTP2Fit::Done()) { MLTP2Fit::Tick(rhi); return; }
		// 🏁👁️ P2 판정 라운드(㉠ 재구성 · ㉡ 사전 사용률) — ⚠️ 조립 검사가 끝난 뒤다(같은 계약).
		if (!MLTP2Run::Done()) { MLTP2Run::Tick(rhi); return; }
		// 🎚️ 걸음 4 — `k` 스윕(회차 21 의 ⛔ 가 가리킨 축). ⚠️ 값이 십 분 대라 플래그로 켠다.
		if (!MLTP2K::Done()) { MLTP2K::Tick(rhi); return; }
		// 📚 걸음 5 — 「데이터를 더 준다」(회차 23 이 「병목 = 일반화」를 못 박았다). `-mltp2d`.
		if (!MLTP2D::Done()) { MLTP2D::Tick(rhi); return; }
		// 🗄️ 걸음 6 — `N` 스윕(회차 24 가 「병목 = 죽은 유닛」을 가리켰다). `-mltp2n`.
		if (!MLTP2N::Done()) { MLTP2N::Tick(rhi); return; }
		// 📏 걸음 7 — 사전 유닛 크기 정규화 A/B(회차 25 가 「병목 = top-k 승자독식」을 냈다). `-mltp2u`.
		if (!MLTP2U::Done()) { MLTP2U::Tick(rhi); return; }
		// 🔬 걸음 8 — 오라클 분해(⚠️ 손잡이가 아니라 **분해**다). `-mltp2dec`.
		if (!MLTP2Dec::Done()) { MLTP2Dec::Tick(rhi); return; }
		// 🧱 걸음 9 — 코드북 행 크기 정규화 A/B(회차 27 의 분해가 「세기」를 가리켰다). `-mltp2cb`.
		if (!MLTP2Cb::Done()) { MLTP2Cb::Tick(rhi); return; }
		// ± 걸음 10 — 선택은 `|z|` · 세기는 `z` A/B(회차 27·28 이 「부호·크기 제약」을 남겼다). `-mltp2ab`.
		if (!MLTP2Ab::Done()) { MLTP2Ab::Tick(rhi); return; }
		// 🎯 걸음 11/14 — OMP·잔차 1회 오라클(⚠️ 손잡이가 아니라 **측정**). `-mltp2omp` / `-mltp2swap`.
		if (!MLTP2Omp::Done()) { MLTP2Omp::Tick(rhi); return; }
		// 🧠 걸음 12 — 은닉 한 겹(SwiGLU ↔ 공유 RMSNorm 경로). `-mltp2h`.
		if (!MLTP2H::Done()) { MLTP2H::Tick(rhi); return; }
		// 🪓 걸음 13 — 선택 순위 S와 재구성 계수 C를 별도 머리로 푼다. `-mltp2sc`.
		if (!MLTP2SC::Done()) { MLTP2SC::Tick(rhi); return; }
		// 🔁 걸음 14 — 현재 재구성의 잔차로 같은 코드북 원자 하나를 교체한다. `-mltp2r`.
		if (!MLTP2R::Done()) { MLTP2R::Tick(rhi); return; }
		// 🔬 회차 37~39 — 평가전용 교체·계수 갱신·GPU 이전을 분해한다. `-mltp2rpost`.
		if (!MLTP2RP::Done()) { MLTP2RP::Tick(rhi); return; }
		// 🔧 회차 40 — 계수 갱신을 δ-stop-gradient STE로 학습까지 통과시킨다. `-mltp2ct`.
		if (!MLTP2CT::Done()) { MLTP2CT::Tick(rhi); return; }
		// 🧊 회차 41 — 따뜻한 시작 뒤 코드북 피드백을 동결 대조군으로 가른다. `-mltp2cw`.
		if (!MLTP2CW::Done()) { MLTP2CW::Tick(rhi); return; }
		// 🛑 회차 43 — 로컬 512 → 지속 8/16 상한이 0/12·1/12로 실패했다. 재현 플래그만 남긴다.
		if (!MLTP3A0::Done()) { MLTP3A0::Tick(rhi); return; }
		// 🌐 회차 44 — 의미 id와 위치를 갈라 둔 전역 상대 발자국의 고정 프레임 조립. `-mltp3a1`.
		if (!MLTP3A1::Done()) { MLTP3A1::Tick(rhi); return; }
		// 🧭 회차 45 — 모델은 그대로 두고 고정 8장에서 위치와 semantic id가 갈리는지 잰다. `-mltp3a2`.
		if (!MLTP3A2::Done()) { MLTP3A2::Tick(rhi); return; }
		// 🔬 회차 46 — **미측정 관문 ㉢**: 활성이 물체를 가르나(색·위치 대조군). `-mltp2obj`.
		//   ⚠️ 재구성(㉠)이 id 를 요구하지 않는다는 것이 P3-A1·A2 에서 드러났다 ⇒ 기능으로 판정한다.
		if (!MLTP2Obj::Done()) { MLTP2Obj::Tick(rhi); return; }
		// ⏳ 회차 47 — 표적만 `t`↔`t+Δ` 로 가른 탐욕 오라클(**토큰 등가치 τ**). `-mltp3b0`.
		//   ⚠️ 학습 표적을 옮기기 **전에** 그 표적이 무력하지 않은지부터 판정한다.
		if (!MLTP3B0::Done()) { MLTP3B0::Tick(rhi); return; }
		// ⏳ 회차 48 — 학습 표적을 시간 너머로(Δ=2). 판정자는 회차 46 과 **같은 클래스**. `-mltp2fut`.
		if (!MLTP2Fut::Done()) { MLTP2Fut::Tick(rhi); return; }
		// 🔩 회차 49 — 몸통의 심볼/출력 어휘를 연다(**비트 동일** A/B + 확장 생존). `-mltp3c0`.
		//   ⚠️ 판정 라운드가 아니라 **배관 회차**다.
		if (!MLTP3C0::Done()) { MLTP3C0::Tick(rhi); return; }
		// ⏳ 회차 50 — **관문 ㉠**: 상태 슬롯을 끊으면 다음-활성 예측이 나빠지나. `-mltp3c1`.
		if (!MLTP3C1::Done()) { MLTP3C1::Tick(rhi); return; }
		// ⏳ 회차 51 — **바닥 재기**: 복사 바닥과 외움 몫(㈀ 0.6969 가 무슨 뜻인가). `-mltp3c2`.
		if (!MLTP3C2::Done()) { MLTP3C2::Tick(rhi); return; }
		// ⏳ 회차 52 — **문맥 수**: 표본이 64개라는 사실을 고치면 일반화가 서나. `-mltp3c3`.
		if (!MLTP3C3::Done()) { MLTP3C3::Tick(rhi); return; }
		// 🐛 회차 53 — **재현 폭 진단**: 몸통 GPU 경로가 흔들리는 자리를 사다리로 좁힌다. `-mltp3d0`.
		if (!MLTP3D0::Done()) { MLTP3D0::Tick(rhi); return; }
		// 🐛 회차 54 — **파라미터 비트 비교**로 비결정성이 태어나는 스텝과 틱 경계의 몫. `-mltp3d1`.
		if (!MLTP3D1::Done()) { MLTP3D1::Tick(rhi); return; }
		// ⏳ 회차 55 — **미룬 관문**: 슬롯 순서(`q` 순위 ↔ id 정렬)가 표적을 흐리나. `-mltp3e0`.
		if (!MLTP3E0::Done()) { MLTP3E0::Tick(rhi); return; }
		// 🐛 회차 56 — **모순 풀기**: 파라미터와 CE 를 같은 반복에서 읽는다. `-mltp3d2`.
		//   ⚠️ 이 캔버스(재현성)의 **세 번째**이고 **여기서 닫는다**.
		if (!MLTP3D2::Done()) { MLTP3D2::Tick(rhi); return; }
		// ⏳ 회차 57 — **미룬 관문 둘째**: 앵커가 다음 id 를 설명하나(학습 0 · CPU). `-mltp3e1`.
		if (!MLTP3E1::Done()) { MLTP3E1::Tick(rhi); return; }
		// ⏳ 회차 58 — **㉠ 재판정**(고쳐진 배관 위에서 · 반복 최빈값). `-mltp3c4`.
		//   ⚠️ 이 상위 캔버스의 **세 번째**이고 여기서 닫는다.
		if (!MLTP3C4::Done()) { MLTP3C4::Tick(rhi); return; }
		// ⏳ 회차 59 — **새 상위**: 잡음을 이기는 자(분할 반쪽)로 ㉠ 을 부른다. `-mltp3f0`.
		if (!MLTP3F0::Done()) { MLTP3F0::Tick(rhi); return; }
		// ⏳ 회차 60 — **새 상위**: 과거 활성이 시간을 건너 하중을 받나. `-mltp3g0`.
		//   ⚠️ ㉡(눈감기)이 아니다 — 컨텍스트에 원본 패치가 없어 **이미 눈감은 상태**다(그 짝이다).
		if (!MLTP3G0::Done()) { MLTP3G0::Tick(rhi); return; }
		// ⏳ 회차 61 — **새 상위**: 변화가 표현에 있나(P3 ㉢ · 선형 프로브). `-mltp3h0`.
		//   ⚠️ *"활성이 물체를 가르나"* 는 **P2 의 ㉢** 이고 회차 46 이 이미 통과시켰다(다른 것이다).
		if (!MLTP3H0::Done()) { MLTP3H0::Tick(rhi); return; }
		// ⏳ 회차 62 — **진단**: 라벨을 몸통의 표적으로 바꿔 「자리」와 「학습의 몫」을 가른다. `-mltp3h1`.
		//   ⚠️ 회차 61 과 **같은 상위 캔버스**이고 **둘째**다 — 셋째면 규율 6(멈춤).
		if (!MLTP3H1::Done()) { MLTP3H1::Tick(rhi); return; }
		// ⏳ 회차 64 — **새 상위**: 몸통이 인코더를 밀 신호가 있나(㉣ 의 첫 걸음). `-mltp3i0`.
		//   ⭐ 인코더를 안 건드리고 `dVal` 의 탄력도만 잰다 — 없으면 합동학습 배관이 **불필요**해진다.
		if (!MLTP3I0::Done()) { MLTP3I0::Tick(rhi); return; }
		// 🔩 회차 65 — **판정 ②**: `dVal → dMag` 연쇄법칙 ↔ 중앙차분. `-mltp3j0`.
		//   ⚠️ **판정 회차가 아니다**(배관/판정 도구) — 규율 6 계수 규칙은 등록문에 있다.
		if (!MLTP3J0::Done()) { MLTP3J0::Tick(rhi); return; }
		// 🔩 회차 66 — **판정 ② 재시도**: ε 스윕 + 꺾인점 진단. `-mltp3j1`.
		if (!MLTP3J1::Done()) { MLTP3J1::Tick(rhi); return; }
		// 🔩 회차 67 — ⭐ **몸통의 손실이 인코더에 닿는다**(배관 + 판정 ① + 생존). `-mltp3k0`.
		if (!MLTP3K0::Done()) { MLTP3K0::Tick(rhi); return; }
		// 🔩 회차 69 — **사다리 진단**: dMag→dScore→기울기→파라미터 중 어디서 끊기나. `-mltp3k1`.
		if (!MLTP3K1::Done()) { MLTP3K1::Tick(rhi); return; }
		// 🔩 회차 70 — **틱당 쓰기 횟수가 범인인가**(팔 넷: 주입✗/✓ × 틱당1/8). `-mltp3k2`.
		if (!MLTP3K2::Done()) { MLTP3K2::Tick(rhi); return; }
		// 🔩 회차 72 — ⭐ **몸통 기울기가 인코더를 바꾸나(끝점)**. `-mltp3k3`.
		//   ⚠️ 회차 71 심사가 `mltp3k0.cw` 를 버렸다 — 이것이 그 자리를 대신한다.
		if (!MLTP3K3::Done()) { MLTP3K3::Tick(rhi); return; }
		// ⏳ 회차 73 — ⭐ **㉣ 의 표제: 「차이의 존재」**(판정 회차). `-mltp3k4`.
		if (!MLTP3K4::Done()) { MLTP3K4::Tick(rhi); return; }
		// 🔩 회차 77 — ⭐ **P4 배관 + 판정 ①**(`StepWith` ↔ `Step()` 비트 동일). `-mltp4a0`.
		if (!MLTP4A0::Done()) { MLTP4A0::Tick(rhi); return; }
		// ⏳ 회차 78 — ⭐ **P4 ㉠ 개입 시험**(2×2 교차 · 판정 회차). `-mltp4b0`.
		if (!MLTP4B0::Done()) { MLTP4B0::Tick(rhi); return; }
		// 🔩 회차 79 — **위생을 세운다**: 회차 77 과 **규약 하나만** 다른 A/B. `-mltp4a1`.
		if (!MLTP4A1::Done()) { MLTP4A1::Tick(rhi); return; }
		// 🔩 회차 80 — **채점 자리를 가른다**: 같은 몸통에서 전 시각 ↔ 시각 6. `-mltp4a2`.
		if (!MLTP4A2::Done()) { MLTP4A2::Tick(rhi); return; }
		// ⏳ 회차 81 — ⭐ **P4 ㉠ 재시도**: 조합 사이에 틱을 비워 오염을 끊는다. `-mltp4b1`.
		if (!MLTP4B1::Done()) { MLTP4B1::Tick(rhi); return; }
		// 🎯 회차 101 — P4 ㉠ 을 **512 문맥**으로 다시(회차 85 의 수술을 P4 에)
		if (!MLTP4B2::Done()) { MLTP4B2::Tick(rhi); return; }
		// 🔊 회차 102 — 개입을 키우고(k=1.0) 표적을 8배로(kTestCtx 512)
		if (!MLTP4B3::Done()) { MLTP4B3::Tick(rhi); return; }
		// ✂️ 회차 103 — P4 ㉠ 을 **끊어서** 잰다(규율 25 · 회차 85b 의 자를 P4 에)
		if (!MLTP4C0::Done()) { MLTP4C0::Tick(rhi); return; }
		// 🔀 회차 104 — 절제의 **분포**를 본다(사람이 찌른 그 구멍)
		if (!MLTP4C1::Done()) { MLTP4C1::Tick(rhi); return; }
		// 🗺️ 회차 105 — 어떤 표적에서 행동을 읽나(회차 104 의 분포를 세계 값으로 나눈다)
		if (!MLTP4C2::Done()) { MLTP4C2::Tick(rhi); return; }
		// 🧷 회차 106 — ㉣ 를 표제로 + 씨앗 안 분할 반쪽(뒤집힘이 표본인가 세계인가)
		if (!MLTP4C3::Done()) { MLTP4C3::Tick(rhi); return; }
		// 🎯 회차 107 — ⭐ **P4 ㉡ 오귀속률**(반사실 개입으로 표적마다 「내 행동이 정했나」를 가른다)
		if (!MLTP4D0::Done()) { MLTP4D0::Tick(rhi); return; }
		// 🐛 회차 108 — ⭐ **비결정성이 사는 곳을 이등분한다**(학습 경로 ↔ 평가 경로). 회차 54 의 부채.
		if (!MLTP4E0::Done()) { MLTP4E0::Tick(rhi); return; }
		// 🐛 회차 109 — ⭐ **갈림이 태어나는 스텝**(`S=0` 을 넣어 「배관이냐 커널이냐」를 가른다)
		if (!MLTP4E1::Done()) { MLTP4E1::Tick(rhi); return; }
		// 🐛 회차 110 — ⭐ **평가를 넷으로 쪼갠다**(없음 / 온전 / 업로드만 / forward만)
		if (!MLTP4E2::Done()) { MLTP4E2::Tick(rhi); return; }
		// 🐛 회차 123 — ⭐ **B3: 비결정성의 범인**(축 = 큐 깊이 · `R=12` · 양성 대조 `S=0`)
		if (!MLTP4E3::Done()) { MLTP4E3::Tick(rhi); return; }
		// 📏 회차 112 — ⭐ **`sd_run` 자**(회차 106 을 바깥 반복으로 감싸 실행 사이 폭을 잰다)
		if (!MLTP4F0::Done()) { MLTP4F0::Tick(rhi); return; }
		// 📊 회차 113 — ⭐ **㉣ 를 「모은 평균 ± SE」로 + 회차 104 를 12씨앗으로 굳힌다**
		if (!MLTP4F1::Done()) { MLTP4F1::Tick(rhi); return; }
		// 🌍 회차 114 — ⭐ **행동의 「잉여」를 없앤다**(`_hold` 5→1 · 씨앗 안 짝지은 A/B)
		if (!MLTP4G0::Done()) { MLTP4G0::Tick(rhi); return; }
		// 🎯 회차 115 — ⭐ **「순이득이 0 인 이유」= P4 ㉡**(`r = corr(Δ끊음, 반사실 가름)`)
		if (!MLTP4H0::Done()) { MLTP4H0::Tick(rhi); return; }
		// ⚖️ 회차 116 — ⭐ **인과를 「배울 이유」를 준다**(⚠️ 교사 실험 · 상한 측정)
		if (!MLTP4I0::Done()) { MLTP4I0::Tick(rhi); return; }
		// 🔩 회차 118 — ⭐ **P6 배관**(`MLTP6Ctx` + 판정①). ⚠️ 상위 캔버스가 바뀐 **파일럿 한 회차**다.
		if (!MLTP6A0::Done()) { MLTP6A0::Tick(rhi); return; }
		// ⏳ 회차 119 — ⭐ **㉠ 중간을 주면 「먼 예측」이 되나**(같은 과제 안의 A/B · 채점은 답 시각만)
		//   ⚠️ **중단됨** — 이 회차가 회차 118 의 판정①을 무효로 만들었다(규율 34) · 자체 결함도 있다(개수)
		if (!MLTP6B0::Done()) { MLTP6B0::Tick(rhi); return; }
		// ⏳ 회차 120 — ⭐ **㉠ 재설계**(참 중간 ↔ 뒤섞은 중간 · **표적만** 흔든다 · 개수 관문)
		if (!MLTP6B1::Done()) { MLTP6B1::Tick(rhi); return; }
		// ⏳ 회차 82 — ⭐ **깨끗한 시험에서 P3 가 서나**(`kTestEpi` 101→901). `-mltp3g1`.
		//   ⚠️ 회차 81 이 **시험 집합 44% 누출**을 찾았다 — 이 회차가 그 영향을 잰다.
		if (!MLTP3G1::Done()) { MLTP3G1::Tick(rhi); return; }
		// ⏳ 회차 83 — ⭐ **㉠ 도 깨끗한 시험에서**(`kTestEpi` 101→901). `-mltp3f1`.
		if (!MLTP3F1::Done()) { MLTP3F1::Tick(rhi); return; }
		// ⏳ 회차 84 — ⭐ **새 상위: 왜 일반화가 안 되나** — 문맥 수 세 점(128·256·512). `-mltp3n0`.
		if (!MLTP3N0::Done()) { MLTP3N0::Tick(rhi); return; }
		// ⏳ 회차 85 — ⭐ **P3 를 512 문맥으로 재판정**(회차 84 가 「문맥이 병목」을 세웠다).
		//   `-mltp3f2` = ㉠ · `-mltp3g2` = ㉡′. ⚠️ 자·팔·문턱은 **한 글자도 안 바꿨다**.
		if (!MLTP3F2::Done()) { MLTP3F2::Tick(rhi); return; }
		// 📉 회차 122 — ⭐ **B1: P 를 「어떻게 죽나」로 판정한다**(난이도 세 점 · 기울기의 비)
		if (!MLTP3D3::Done()) { MLTP3D3::Tick(rhi); return; }
		if (!MLTP3G2::Done()) { MLTP3G2::Tick(rhi); return; }
		// 📐 회차 124 — ⭐ **B2: P3 ㉡′ 을 정직한 자로**(짝지은 SE + 바깥 반복 · 규율 31·32)
		if (!MLTP3D4::Done()) { MLTP3D4::Tick(rhi); return; }
		// 🐣 **L 단계의 첫 회차** — 얼린 표현에 선형 프로브(회차 86)
		if (!MLTL0A0::Done()) { MLTL0A0::Tick(rhi); return; }
		if (!MLTL0A1::Done()) { MLTL0A1::Tick(rhi); return; }   // 회차 87 — 자를 고친 재측정(판정)
		if (!MLTL0A2::Done()) { MLTL0A2::Tick(rhi); return; }   // 회차 88 — 하중 받는 행에서 재측정(판정)
		if (!MLTL0B0::Done()) { MLTL0B0::Tick(rhi); return; }   // 회차 89 — 양성 대조(새 캔버스 · 규율 16)
		if (!MLTL0C0::Done()) { MLTL0C0::Tick(rhi); return; }   // 회차 90 — 읽는 형식(전체 풀링 · 판정)
		if (!MLTL0D0::Done()) { MLTL0D0::Tick(rhi); return; }   // 회차 91 — L0 비전 낱말 「얼마나 가까이 있나」
		if (!MLTL0E0::Done()) { MLTL0E0::Tick(rhi); return; }   // 회차 92 — 한 층 아래(인코더가 깊이를 담나)
		if (!MLTL0F0::Done()) { MLTL0F0::Tick(rhi); return; }   // 회차 93 — 정규화가 깊이를 지웠나
		if (!MLTL0G0::Done()) { MLTL0G0::Tick(rhi); return; }   // 회차 94 — 앵커(패치 자리)가 깊이를 담나
		if (!MLTW0::Done())   { MLTW0::Tick(rhi);   return; }   // 회차 95 — 🌍 세계를 먼저 찍는다(측정)
		if (!MLTL0H0::Done()) { MLTL0H0::Tick(rhi); return; }   // 회차 96 — 🔭 L0 재개(보이는 가장 가까운 것)
		if (!MLTL0I0::Done()) { MLTL0I0::Tick(rhi); return; }   // 회차 97 — 🩻 몸통 층 기준선(minDOn)
		if (!MLTL0J0::Done()) { MLTL0J0::Tick(rhi); return; }   // 회차 98 — ⚓ 앵커를 몸통에 싣는다
		if (!MLTL0K0::Done()) { MLTL0K0::Tick(rhi); return; }   // 회차 99 — 🎚️ 대역별 풀링 · 앵커 A/B
		if (!MLTL0M0::Done()) { MLTL0M0::Tick(rhi); return; }   // 회차 100 — 🧪 과제 낱말 ↔ 무관 낱말
		// 🧪 회차 121 — ⭐ **C0: L0 을 정직한 자로 다시**(짝지은 SE + 바깥 반복 · 규율 31·32)
		if (!MLTL0N0::Done()) { MLTL0N0::Tick(rhi); return; }
		// 🗣️ 회차 125 — ⭐ **C2: L1 배관**(값 구간 홀드아웃 · 낱말 축 ↔ 홀드아웃 축을 가른다)
		if (!MLTL1A0::Done()) { MLTL1A0::Tick(rhi); return; }
		// 🗣️ 회차 126 — ⭐ **C3: L1 ㉠ 보간을 판정으로**(㉠-a 절대 · ㉠-b 상대)
		if (!MLTL1A1::Done()) { MLTL1A1::Tick(rhi); return; }
		// 🌉 회차 127 — ⭐ **L1 ㉣ 채널 간 전이**(상태로 배운 낱말 방향을 비전 대역에 그대로 꽂는다)
		if (!MLTL1A2::Done()) { MLTL1A2::Tick(rhi); return; }
		// 🔎 회차 128 — ⭐ **D4: 흔들리는 것은 학습인가 읽는 길인가**(모델 비트 ↔ 리드백 방식)
		if (!MLTD4A0::Done()) { MLTD4A0::Tick(rhi); return; }
		// 📊 회차 129 — ⭐ **D4-b: 발생률을 고정한다**(벌 32 · 클러스터 · 첫 갈림 자리)
		if (!MLTD4B0::Done()) { MLTD4B0::Tick(rhi); return; }
		// 🪜 회차 131 — ⭐ **D4-d: 몇 번째 걸음에서 처음 갈리나**(걸음 중간 지문)
		if (!MLTD4C0::Done()) { MLTD4C0::Tick(rhi); return; }
		// 🔄 회차 132 — ⭐ **L1 ㌥ 역방향**(낱말을 입력으로 주면 예측이 좋아지나)
		if (!MLTL1B0::Done()) { MLTL1B0::Tick(rhi); return; }
		// 📏 회차 140 — ⭐ **자의 천장을 계산한다**(학습 0 · `H(낱말)/채점 표적 수` · 실측 MI)
		if (!MLTL1C0::Done()) { MLTL1C0::Tick(rhi); return; }
		// 🪜 회차 141 — ⭐ **천장을 올린다**(낱말을 시각당 하나 · 채점을 변화 표적에만)
		if (!MLTL1D0::Done()) { MLTL1D0::Tick(rhi); return; }
		// 🔍 회차 142 — ⭐ **표제 낱말을 고른다**(학습 0 · `Î−Î섞음` 으로 후보를 거른다)
		if (!MLTL1E0::Done()) { MLTL1E0::Tick(rhi); return; }
		// 🧮 회차 143 — ⭐ **변화 표적을 배우나**(학습 0 · 예측기 다섯 vs 몸통 · 밀림/새id 분해)
		if (!MLTL1F0::Done()) { MLTL1F0::Tick(rhi); return; }
		// 🎯 회차 144 — ⭐ **왜 못 배우나**(손실 마스크 팔 넷 · 목표선 2.1111 을 깨나)
		if (!MLTL1G0::Done()) { MLTL1G0::Tick(rhi); return; }
		// ⚖️ 회차 145 — ⭐ **가중 스윕**(지속 표적 보존율 q 다섯 점 · 파레토 · 양쪽 끝이 검산)
		if (!MLTL1H0::Done()) { MLTL1H0::Tick(rhi); return; }
		// 🔄 회차 146 — ⭐ **회전 마스크**(순회마다 다른 지속 부분집합 ⇒ 표본 손실 제거 · 커널 0줄)
		if (!MLTL1I0::Done()) { MLTL1I0::Tick(rhi); return; }
		// ⚖️ 회차 147 — ⭐ **에너지 채널 거르기 + 세계 서명**(⚠️ 세계를 켜는 첫 회차 · 규율 21)
		if (!MLTL1J0::Done()) { MLTL1J0::Tick(rhi); return; }
		// 🎯 회차 149 — ⭐ **`A1` 파일럿**(변화 표적의 「내용 축」에 폭이 있나 · 밀림 ↔ 새id · 개수 맞춤)
		if (!MLTL1K0::Done()) { MLTL1K0::Tick(rhi); return; }
		// 🔧 회차 150 — ⭐ **용량을 올리면 파레토 교환이 풀리나**(용량이 **런타임 팔**이다 · 셰이더 0줄)
		if (!MLTL1L0::Done()) { MLTL1L0::Tick(rhi); return; }
		// 🧩 회차 156 — ⭐ **조합과 이진이 표적을 가르나**(학습 0 · 142 의 ⛔ 가 자의 탓인지 세계의 탓인지)
		if (!MLTL1M0::Done()) { MLTL1M0::Tick(rhi); return; }
		// 🏃 회차 157 — ⭐ **「어디로 가고 있나」가 표적을 가르나**(속도 = 프레임 차분 · **세계 코드 0줄**)
		if (!MLTL1N0::Done()) { MLTL1N0::Tick(rhi); return; }
		// 🎞️ 회차 159 — ⭐ **델타를 켜고 서명부터**(`-mltdelta` · 세계 코드 0줄 · 규율 21)
		if (!MLTL1O0::Done()) { MLTL1O0::Tick(rhi); return; }
		// 📐 회차 160 — ⭐ **델타판의 목표선을 세운다**(143 하네스 + `-mltdelta` · 절대판은 검산)
		if (!MLTL1P0::Done()) { MLTL1P0::Tick(rhi); return; }
		// 🎯 회차 162 — ⭐ **칸 10 의 첫 실측**(141 의 자 + `maxV` 낱말 · `-mltdelta`)
		if (!MLTL1Q0::Done()) { MLTL1Q0::Tick(rhi); return; }
		// 📐 회차 164 — ⭐ **고르기 전에 재기**(세계 손잡이 점 · `-mltpt <n>` · 학습 0)
		if (!MLTL1R0::Done()) { MLTL1R0::Tick(rhi); return; }
		// ⭐ 회차 179 — ㉲ 의 세계 서명(학습 0 · 세계만 · 초 단위)
		if (!MLTL1S0::Done()) { MLTL1S0::Tick(rhi); return; }
		// ⭐ 회차 181 — ㉲ 로 몸통을 돌린다(인코더 없음 · 물체가 슬롯이다)
		if (!MLTL1T0::Done()) { MLTL1T0::Tick(rhi); return; }
		// ⚠️ 파일럿은 기본에서 꺼져 있다(`-mltpilot` 으로 켠다) — 통과했고 기록이 그 파일에 남아 있다.
		if (!MLTP0B::Done()) { MLTP0B::Tick(rhi); return; }
		// ⚠️ 판정 스윕(회차 3·4)도 기본에서 꺼져 있다(`-mltsweep`) — 표제가 통계 재현됐다.
		if (!MLTP0Sweep::Done()) { MLTP0Sweep::Tick(rhi); return; }
		if (!MLTP0Freq::Done()) { MLTP0Freq::Tick(rhi); return; }
		if (!MLTP1Run::Done()) { MLTP1Run::Tick(rhi); return; }
		if (!MLTP1Band::Done()) { MLTP1Band::Tick(rhi); return; }
		if (!MLTP1b::Done()) { MLTP1b::Tick(rhi); return; }
		if (!MLTP1W::Done()) { MLTP1W::Tick(rhi); return; }
		if (!MLTP1P::Done()) { MLTP1P::Tick(rhi); return; }
		if (!MLTP1M::Done()) { MLTP1M::Tick(rhi); return; }
		if (!MLTP1F::Done()) { MLTP1F::Tick(rhi); return; }
		if (!MLTP1C::Done()) { MLTP1C::Tick(rhi); return; }
		if (!MLTP1S::Done()) { MLTP1S::Tick(rhi); return; }
		if (!MLTP1O::Done()) { MLTP1O::Tick(rhi); return; }
		if (!MLTPX::Done()) { MLTPX::Tick(rhi); return; }
		MLTPXL::Tick(rhi);
	}

private:

	// ⚠️ **CW 마커가 없다** — 정적 멤버만 있는 실험 클래스라 리플렉션이 필요 없다(`MLDiff` 와 같다).
	//   ★ 리플렉션이 필요해지면(인스펙터에 노출 등) 그때 `CW_BODY(MLT)` 를 **클래스 맨 끝**에 붙인다.
};
