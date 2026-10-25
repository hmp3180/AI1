#include "drawprogram.gen.h"   // IDE 인식용(빌드는 gen.h #pragma once 로 중복 skip). cwgen 생성 헤더.
// drawprogram.cw — 🎨 **`domain draw` 의 호스트.** 128² 캔버스에 도형을 그리는 프로그램 하나를 돌린다.
//
// ★ **왜 이것이 있나 = 코드가 모달리티다.** 이 프로젝트의 모델은 `.pes` 소스 텍스트와 그것을
//   **실행한 프레임**을 짝으로 배운다. 그래서 이 도메인의 함수 집합이 곧 **모델이 배워야 하는 코드 어휘**다
//   (→ Projects/ML/ML.md). 그리는 일 자체는 엔진 원시형(`ImageFormat::ImageOps`)이 하고, 여기 있는 것은
//   **스크립트에서 그것을 부르는 창구**뿐이다.
//
// ★ **봉인(`Sealed`)한다.** `room` 의 근거가 여기선 두 배로 맞다 — *"어휘가 열둘이면 생성이 옳게
//   나오고 이백이면 헤맨다."* 어휘가 **학습 대상 그 자체**이므로 작고 닫힌 것이 목표다. 봉인은 태그 없는
//   엔진 API(월드·애셋·창)가 이 도메인에서 **이름조차 없게** 만든다.
//
// ★ **호스트가 넷째다.** `self.x` 를 리플렉션으로 여는 기계(`Script::ScriptReflection`)의 소비자가
//   여태 셋이었다(`ScriptComponent`/`ScriptWindowSubsystem`/`ScriptWorldSubsystem`). 그 문서가
//   *"셋의 차이는 부모 타입과 state 포인터 자리뿐"* 이라고 적어 둔 덕에 **World 를 import 하지 않고**
//   넷째를 세울 수 있었다 — 이 앱에는 엔티티도 월드도 없다.
//
// ⚠️⚠️ **소스는 파일이 아니라 문자열로 온다.** 생성기가 파라미터를 뽑아 **소스에 숫자를 써 넣기** 때문이다
//   (`Draw::Circle(37, 92, 15)`). 스크립트 안에 난수를 두면 같은 코드가 다른 프레임을 내고
//   *"코드 → 프레임 은 함수"* 라는 전제가 무너져 모델이 **모순을 학습**한다(→ ML.md 의 함정 7).
//   ★ `ScriptRunner::Compile` 이 `StringView` 를 받으므로 디스크에 아무것도 남지 않는다.
using namespace PE;

// ★ **도메인 등록** — 클래스보다 먼저 둔다(`.cw` 는 헤더라 선언 순서가 곧 가시성이다).
//   ⚠️ 호스트를 **이름 문자열**로 적는다 — Script 모듈은 상위 모듈을 모른다(→ ScriptDomain.h 의 `hostClass`).
CW_EXPORT void RegisterDrawScriptDomain()
{
	Script::ScriptDomainInfo d;
	d.name = NameID("draw");
	d.parent = Script::DefaultScriptDomain();
	d.mainThread = ScriptThread_Engine;
	d.tooltip = "Draw — 128² 캔버스에 도형을 그리는 프로그램(ML 커리큘럼의 코드 모달리티)";
	d.Host("DrawProgram");
	// ★ 봉인 — 어휘가 곧 학습 대상이다(머리말).
	d.Sealed();
	// ★ 엔트리 둘. **`OnStart` 는 상태를 세우고 `OnFrame` 은 그것을 굴린다** — 그 갈림이
	//   커리큘럼 4·5칸(이동·낙하)의 전부다: `self.v` 를 `OnStart` 가 세우고 `OnFrame` 이 `+=` 한다.
	//   ⚠️ 프레임 인덱스를 인자로 주지 않는다 — 주면 저자가 `y = f(i)` 라는 **폐함수**를 쓰게 되고,
	//     그러면 낙하가 "누적" 이 아니라 "공식" 이 되어 `+=` 의 순차적 인과가 사라진다(ML.md 의 그 ★).
	d.Entry("OnStart").Tip("프레임 0 앞에 1회 — self.* 초기 상태를 세운다");
	d.Entry("OnFrame").Tip("프레임마다 1회 — self.* 를 굴리고 그린다");
	Script::RegisterScriptDomain(d);
}
// ★ **모듈이 올라올 때** 등록한다(엔진 도메인들과 같은 규약) — "쓸 때 등록" 이면 매니페스트가 반쪽이 된다.
//   ⚠️ `.cw` 는 `gen.h` 를 무는 TU 가 둘이라 이 등록기가 **두 번** 돈다 — 중복 등록은 설계상 조용히
//     무시된다(첫 것이 이긴다). 그래서 1회 가드를 두지 않는다.
PE_AUTO_REGISTER_SCRIPT_DOMAIN(RegisterDrawScriptDomain)

// 🎨 프로그램 하나 = 소스 하나 + 캔버스 하나 + `self.*` 상태.
//   ⚠️⚠️ **`CW_OBJECT_BODY` 를 못 쓴다** — 그 매크로가 내는 `PE_REG_TYPE` 이 `GetType()` 을 같이 정의하는데,
//     스크립트 호스트는 그 자리에 **동적 스크립트 타입**을 돌려줘야 한다. 둘이 겹치면 컴파일 에러다
//     ⇒ 등록 세 줄만 손으로 적는다(엔진의 스크립트 호스트들 · TWC `RoomComponent` 와 같은 모양).
class DrawProgram : public ObjectBase
{
public:
	using Super = ObjectBase;
	inline static TypeInfo StaticType = TypeInfo("DrawProgram", &ObjectBase::StaticType, false);
	inline static FactoryFuncReg<DrawProgram> _FactoryFuncReg = FactoryFuncReg<DrawProgram>(StaticType);

	// ★ 컴파일에 성공하면 이 인스턴스의 타입은 그 스크립트다 — `self.*` 가 프로퍼티로 열리는 근거다.
	TypeInfo* GetType() const override { return _refl.Type() ? _refl.Type() : &StaticType; }

	// 🖼️ 그림이 앉는 자리(RGBA8). ★ **모델 입력은 이것을 `PackRGB332` 로 깎은 것**이고 여기는 저작 해상도다 —
	//   그리기는 엔진 원시형 그대로 8비트/채널로 하고 양자화는 마지막에 한 번 한다(→ ML.md 의 프레임 포맷).
	ImageFormat::Bitmap canvas;

	// 🎯 지금 도는 프로그램. `RoomComponent::Current` 와 **같은 장치**다.
	//   ★ 자유함수가 아니라 **정적 멤버**다 — 헤더 겸 소스라 파일 스코프 도우미는 이름을 밖에 흘린다.
	//   ⚠️ 이 도메인 밖(다른 스크립트)에서는 null 이고 아래 `Draw::*` 는 전부 no-op 이 된다.
	static DrawProgram* Current() { return Cast<DrawProgram>(Script::CurrentScriptHost()); }

	// 소스를 컴파일하고 상태를 세운다. 실패 = false(컴파일 진단은 러너가 로그로 낸다).
	//   ⚠️⚠️ **순서가 계약이다**: `Prepare`(state 버퍼) → `Build`(그 배치로 프로퍼티) → `Sync`(버퍼 주소) →
	//     `Initialize`(최상위 초기식) → `Sync`. `Initialize` 를 먼저 하면 프로퍼티 없이 초기값이 서고,
	//     `Sync` 를 빠뜨리면 프로퍼티가 **null 을 역참조**한다(조용히 0 으로 읽힌다).
	// 🔬 **임시 계측**(D134) — `Compile` 의 **마무리 넷**을 이분한다. `0` = 정상.
	//   ★ 왜: D133 이 `Parse`·`Analyze` 를 **배제**했다(둘 다 0 B) ⇒ 남은 자리가 방출과
	//     이 마무리다. 그리고 이 셋(`DrawProgram`·`ScriptRunner`·`ScriptReflection`)은
	//     **놓는 함수가 있는데 소멸자가 없다** — 그것이 이 판의 가설이다.
	//   ⚠️ 컷에서 `true` 를 준다(호출자는 성공으로 본다) — 누수 라운드는 성공/실패를 세기만 한다.
	//   ⚠️⚠️ **임시다** — 자리가 찍히면 지운다.
	static int& PostCut() { static int s = 0; return s; }
	
	bool Compile(StringView source, uint32 width, uint32 height, NameID typeName)
	{
		if (!ImageFormat::CreateRGBA8(canvas, width, height)) return false;

		_runner.SetHost(this);
		if (!_runner.Compile(source, NameID("draw"), StringView("draw-program"))) return false;
		if (PostCut() == 1) return true;   // 🔬 컷1 — 방출까지만(D134)

		_runner.Instance().Prepare(_runner.Program());
		if (PostCut() == 2) return true;   // 🔬 컷2 — + 인스턴스 상태 버퍼(D134)
		_refl.Build(typeName, StaticType, GetMemberOffset(&DrawProgram::_refl), _runner.Program());
		if (PostCut() == 3) return true;   // 🔬 컷3 — + 동적 TypeInfo(D134)
		_refl.Sync(_runner.Instance());
		if (!_runner.Initialize()) return false;
		_refl.Sync(_runner.Instance());

		_fnStart = _runner.Find(NameID("OnStart"));
		_fnFrame = _runner.Find(NameID("OnFrame"));
		return true;
	}

	// 엔트리 둘. ⚠️ 진입점이 없으면 `Call0` 은 성공(no-op)이다 — `OnStart` 만 있는 프로그램도 정상이다.
	bool RunStart() { return _runner.Call0(_fnStart); }
	bool RunFrame() { return _runner.Call0(_fnFrame); }

	bool IsReady() const { return _runner.IsReady(); }

	// 🎨 지금 색(0..255). ★ **스크립트가 0..255 로 말한다** — 픽셀도 코드의 숫자도 같은 범위에 살게 되어
	//   모델이 보는 수 체계가 하나가 된다(0..1 float 로 두면 코드에만 소수점이 생긴다).
	//   ⚠️ `ImageOps` 는 0..1 을 받으므로 그리는 자리에서 나눈다.
	Vector4 color = Vector4(1.0f, 1.0f, 1.0f, 1.0f);
	// ★ **여기서 범위를 클램프하지 않는다** — `ImageOps` 의 `ToByte` 가 이미 0..1 밖을 자른다.
	//   또 하면 같은 사실이 두 곳에 살고, 그러면 한쪽을 고칠 때 반드시 어긋난다.
	static Vector4 FromBytes(int32 r, int32 g, int32 b)
	{
		const float k = 1.0f / 255.0f;
		return Vector4((float)r * k, (float)g * k, (float)b * k, 1.0f);
	}

	// ✏️ 테두리 굵기는 **어휘가 아니라 상수**다 — 인자로 열면 커리큘럼 코드에 축이 하나 더 붙는데
	//   그 축은 배울 값이 없다(사다리 한 칸이 능력 하나라는 규칙 → ML.md). 2.0 인 이유는
	//   ⚠️ **1.5 미만이면 큰 반지름에서 테두리에 구멍이 생기기** 때문이다(→ ImageOps.h 의 그 ⚠️⚠️).
	static constexpr float kStroke = 2.0f;

	void Release()
	{
		_refl.Clear();
		_runner.Reset();
		_fnStart = -1;
		_fnFrame = -1;
	}

private:
	Script::ScriptRunner     _runner;
	Script::ScriptReflection _refl;   // 동적 TypeInfo + state 포인터(→ Script/ScriptReflection.h)
	int32 _fnStart = -1;
	int32 _fnFrame = -1;
};

// ── 🖌️ 스크립트 표면 = 이 프로젝트가 배우려는 **코드 어휘** ────────────────────────────────
//   ★ 이름공간 `DrawApi` → 스크립트에서 **`Draw::`** 다(cwgen 이 끝의 `Api` 를 뗀다).
//   ★ 접두사를 둔 이유가 둘이다: ㉠ 전역 이름 충돌을 피한다(`Clear`/`Rect` 는 너무 흔하다)
//     ㉡ **일관된 접두사가 경계 학습기에 유리하다** — `Draw::Circle` 이 늘 같이 오므로 엔트로피 기준으로
//        한 덩어리로 잘리는 것이 명확해진다(그것이 L2 가 배워야 하는 바로 그 종류의 사실이다).
//   ⚠️ 좌표·크기는 **픽셀 정수**이고 색은 **0..255 정수**다 — 모델이 보는 수 체계를 하나로 둔다.
namespace DrawApi
{
	// 캔버스를 한 색으로 덮는다. ★ 커리큘럼의 모든 프로그램이 이것으로 시작한다(배경이 정의돼야
	//   "도형이 있다" 가 뜻을 갖는다).
	CW_SCRIPT("draw") void Clear(int32 r, int32 g, int32 b)
	{
		if (DrawProgram* p = DrawProgram::Current())
			ImageFormat::Fill(p->canvas, DrawProgram::FromBytes(r, g, b));
	}

	// 지금 색을 정한다(이후 도형에 적용). ★ 색을 도형 인자에 섞지 않는 이유 = 도형 호출을 짧게 유지해
	//   **좌표/크기 축과 색 축이 코드에서 분리되어 보이게** 하는 것이다.
	CW_SCRIPT("draw") void Color(int32 r, int32 g, int32 b)
	{
		if (DrawProgram* p = DrawProgram::Current())
			p->color = DrawProgram::FromBytes(r, g, b);
	}

	CW_SCRIPT("draw") void Circle(int32 x, int32 y, int32 radius)
	{
		if (DrawProgram* p = DrawProgram::Current())
			ImageFormat::DrawCircle(p->canvas, (float)x, (float)y, (float)radius,
				DrawProgram::kStroke, p->color);
	}

	CW_SCRIPT("draw") void CircleFill(int32 x, int32 y, int32 radius)
	{
		if (DrawProgram* p = DrawProgram::Current())
			ImageFormat::FillCircle(p->canvas, (float)x, (float)y, (float)radius, p->color);
	}

	CW_SCRIPT("draw") void Rect(int32 x, int32 y, int32 w, int32 h)
	{
		if (DrawProgram* p = DrawProgram::Current())
			ImageFormat::DrawRect(p->canvas, x, y, w, h, (int32)DrawProgram::kStroke, p->color);
	}

	CW_SCRIPT("draw") void RectFill(int32 x, int32 y, int32 w, int32 h)
	{
		if (DrawProgram* p = DrawProgram::Current())
			ImageFormat::FillRect(p->canvas, x, y, w, h, p->color);
	}
}
