#include "episodegen.gen.h"   // IDE 인식용(빌드는 gen.h #pragma once 로 중복 skip). cwgen 생성 헤더.
// episodegen.cw — 🎲 **에피소드 생성기.** 커리큘럼 한 칸의 `(코드 · 프레임들 · 말)` 을 만든다.
//
// ★ **랜덤은 코드 텍스트에 나타난다.** 파라미터를 뽑아 **소스에 그 숫자를 써 넣는다**
//   (`Draw::Circle(37, 92, 15)`). 스크립트 안에 난수를 두면 같은 코드가 다른 프레임을 내고
//   *"코드 → 프레임 은 함수"* 라는 전제가 무너져 모델이 **모순을 학습**한다(→ ML.md 의 함정 7).
//
// ★ **주석은 숫자를 되읽지 않는다 — 정성적으로만 말한다.** `// 가운데보다 살짝 위에` 처럼.
//   근거 둘: ㉠ 토큰 1:1 전사면 모델이 배우는 것이 **치환 암호**다 ㉡ **숫자의 뜻은 프레임이 가르친다** —
//   주석이 숫자를 말하면 프레임과 중복이고 모델은 **더 쉬운 쪽(텍스트 복사)으로 도망간다**.
//   ⇒ 그래서 여기서 `왼쪽`/`큰`/`푸른` 같은 낱말을 **값의 구간에서** 만든다. 그 낱말이 어느 수 범위를
//     뜻하는지는 **여러 샘플에서 프레임을 보고** 배워야 하는 것이고, 그것이 정확히 접지다.
//
// ⚠️ 주석은 **줄 위**에 둔다(뒤가 아니라) — 뒤면 인과 순서가 `코드 → 설명` 이라 **생성 방향
//   (설명 → 코드)을 못 가르친다**(→ ML.md 의 조건 ①).
//
// ⚠️ 난수는 `PE::SeedRand`/`RandInt` 다(전역 상태 · 결정론적) → **씨앗을 적어 두면 그 에피소드가
//   그대로 재현된다**. 재현이 안 되면 "판독이 틀렸나 생성이 틀렸나" 를 가를 수 없다.
using namespace PE;

// 🎨 팔레트 — ★ **작게 유지한다.** 커리큘럼이 실제로 쓰는 색이 적으면 색 축을 빨리 배운다.
//   ⚠️ 배경(검정)과 충분히 다른 것만 둔다 — 판독기가 "배경 아닌 픽셀" 로 도형을 찾기 때문이다.
struct MLPalette
{
	const char* name;
	int r, g, b;
};

class MLEpisode
{
public:
	int    rung = 1;          // 커리큘럼 칸(1..11)
	uint32 seed = 0;          // ★ 이것만 있으면 그대로 재현된다
	int    frameCount = 1;    // 이 에피소드의 프레임 수(1..N)
	String code;              // `.pes` 소스 — **코드 모달리티의 실체**
	String caption;           // 자연어 한 줄(프로그램 전체를 말한다)
	// 🎯 **목표 코드**(D60 · 있을 때만) — 이것을 돌린 **마지막 장**이 그 에피소드의 목표다.
	//
	// ★ **왜 이 필드가 필요한가 — 「막힘」의 조건이다.** 목표를 늘 「자기 마지막 장」으로
	//   두면 무엇을 해도 결국 **도착**이 되고 「가려던 데를 못 갔다」가 원리적으로 안 생긴다
	//   (D59 가 그것을 실측했다: 바닥을 만들어도 막힘이 **0.0%** 였다 — 바닥은 「도착」이다).
	//   ⇒ ***목표는 프레임 열 안에 없어도 된다.*** 그것이 「욕구」와 「실제로 일어난 것」을
	//     가르는 자리이고, 호/불호가 뜻을 갖는 조건이다.
	// ⚠️ 비어 있으면 옛 규약 그대로다(목표 = 자기 마지막 장) ⇒ 1~6칸은 한 줄도 안 바뀐다.
	String goalCode;
};

class MLEpisodeGen
{
public:
	// 🖼️ 캔버스 한 변. ⚠️ `DrawProgram` 이 만드는 크기와 같아야 한다.
	// ★ **왜 64 인가 — 텍스트와 같은 알파벳을 쓰기 때문에 프레임의 "글자 수" 가 곧 비용이다.**
	//   절대 프레임 하나가 `kSize²` 바이트다: 128² = 16384, 64² = 4096. 캡션이 20~40바이트이므로
	//   128² 는 말보다 그림이 **~500배** 무겁고, 64² 도 여전히 ~130배다. 시각이 언어를 익사시킨다.
	//   ⚠️ 아래로는 못 간다 — **`빈/찬` 축이 하한을 정한다**(`kStroke = 2` 인 테두리가 속을 남겨야 한다).
	//     48² 면 작은 도형의 반지름이 3이 되고 그 순간 빈 것과 찬 것이 같은 그림이 된다(실측 계산).
	//   ★ 그리고 **연속 시각은 델타로 담는다** → `ImageOps::PackRGB332Delta`. 정지는 전부 0 이므로
	//     실제 비용은 프레임 수가 아니라 **바뀐 픽셀 수**다(움직이는 네모 하나면 수백 바이트).
	static constexpr int kSize = 64;

	// 📐 **128² 기준으로 고른 픽셀값을 지금 해상도로 옮긴다.**
	//   ⚠️⚠️ 예전에는 `RandInt(18, 56)` 처럼 **절대 픽셀값이 흩어져** 있었다 — 해상도를 바꾸는 순간
	//     전부 조용히 틀린 값이 된다(도형이 캔버스를 넘거나 `WordSize` 의 삼분할과 어긋난다).
	//   ★ 숫자의 **뜻**(128² 에서 이만큼)을 남기면서 한 곳에서 비례시킨다.
	static int Px(int at128) { return at128 * kSize / 128; }

	static const MLPalette& Palette(int i)
	{
		// ⚠️ `static` 지역이라 TU 마다 한 벌이지만 값이 같아 무해하다(`.cw` 규약).
		static const MLPalette kPal[] = {
			{ "붉은",   230,  80,  80 },
			{ "노란",   235, 200,  70 },
			{ "푸른",    90, 170, 240 },
			{ "초록",   120, 220, 130 },
			{ "하얀",   235, 235, 235 },
		};
		const int n = (int)(sizeof(kPal) / sizeof(kPal[0]));
		return kPal[((i % n) + n) % n];
	}
	static int PaletteCount() { return 5; }

	// ── 값 → 낱말 ─────────────────────────────────────────────────────────────
	//   ★ 128 을 셋으로 나눈다. ⚠️⚠️ **경계를 여기 한 곳에 둔다** — 판독기(P6)도 **같은 경계**를 써야
	//     "의도 vs 판독" 비교가 성립한다. 두 곳에 다른 숫자가 있으면 조용히 어긋나고, 그 어긋남은
	//     "모델이 위치를 못 배운다" 로 나타나 원인과 안 닮는다.
	static const char* WordH(int cx)
	{
		if (cx < kSize / 3)          return "왼쪽";
		if (cx > (kSize * 2) / 3)    return "오른쪽";
		return nullptr;              // 가운데 = 낱말 없음(아래 `WordPos` 가 조립한다)
	}
	static const char* WordV(int cy)
	{
		if (cy < kSize / 3)          return "위";
		if (cy > (kSize * 2) / 3)    return "아래";
		return nullptr;
	}
	// ★ 자리를 **한 마디로** 만든다 — `왼쪽 위` · `오른쪽 아래` · `왼쪽` · `가운데`.
	//   ⚠️ 예전엔 `WordV` + `WordH` 를 그대로 이어 붙여 **"가운데 왼쪽"** 같은 어색한 말이 나왔다.
	//     둘 다 가운데면 낱말이 두 번 나오기도 했다 → 조립을 한 곳에 둔다.
	static String WordPos(int cx, int cy)
	{
		const char* h = WordH(cx);
		const char* v = WordV(cy);
		if (h != nullptr && v != nullptr) return Format("%s %s", h, v);
		if (h != nullptr)                 return String(h);
		if (v != nullptr)                 return String(v);
		return String("가운데");
	}
	// ⚠️ **뒤에 공백을 붙여 돌려준다** — 뒤에 색 낱말이 이어지므로(`작은 하얀`). 없으면 `작은하얀` 이 된다
	//   (실측으로 밟았다). 크기 말이 없을 때는 빈 문자열이라 공백도 안 생긴다.
	static const char* WordSize(int extent)
	{
		if (extent < kSize / 5)      return "작은 ";
		if (extent > kSize / 2)      return "큰 ";
		return "";
	}

	// ── 🗣️ 캡션 조립 ─────────────────────────────────────────────────────────
	//
	// ★ **문장을 칸마다 통째로 쓰지 않는다.** D62 가 실측했다(**함정 209**): 동작 낱말 6개 중
	//   5개가 **한 칸에만** 살아서 「낱말을 아는 것」과 「어느 칸인가를 알아보는 것」이 구별되지
	//   않았고, D61 이 후자를 배웠다(칸별 최빈 가중합 70.6% ↔ 실측 71.0%).
	//   ⇒ 낱말을 **조각으로 조립**해서 같은 낱말이 여러 칸에 나오게 한다.
	//   ★ 그것이 `concept.md` 의 *"같은 개념을 다른 대상·채널·시간 규모에서 다시 만나게 한다"* 를
	//     **어휘 수준에서** 지키는 일이다.
	//
	// ★ **절을 짧게 끊어 잇는다.** 한 문장으로 매끄럽게 쓰려 하면 칸마다 다른 동사가 나오고
	//   (`움직인다` ↔ `떨어지면서` ↔ `가다가`) 그것이 정확히 함정 209 다. 짧은 절은 덜 유려하지만
	//   **낱말이 재료가 된다** — 그리고 0단계 규약(조사·어형 고정 · 어미 변화 없음)과 오히려 더 맞다.
	//
	// ★ **`있다` 가 모든 칸에 온다** — 존재가 가장 위의 낱말이고(성장 지도 1단계) 그것이 뒤의
	//   `그대로 있다` · `그려져 있다` · `채워져 있다` 를 한 이웃으로 묶는다.
	//
	// ⚠️⚠️ **세계는 「막힌다」고 말하지 않는다 — 「닿는다 · 멈춘다」고 말한다.** D59 가 실측했다:
	//   세계 안의 벽은 도형이 **멈추는** 일이고, 「막힘」은 **목표가 그 너머일 때만** 생긴다.
	//   ⇒ 3인칭 캡션에서 「막힌다」를 뺀다. 그 낱말은 **1인칭 자기상태**의 자리다(층이 갈린다).
	//
	// ⚠️ 프레임은 **한 바이트도 안 바뀐다** — 캡션만 고친다 ⇒ D56~D61 의 측정이 그대로 재현된다.

	// `<자리>에[서] <크기><색> <모양> 하나가 있다` — 대상을 소개하는 첫 절.
	//   ⚠️ `from` 은 조사만 가른다(정적 = `에` · 움직임 = `에서`) — 낱말은 그대로 공유된다.
	//   ⚠️ 조사는 **`에` 하나로** 통일한다. 움직이는 칸에 `에서` 를 쓰면 `~에서 … 있다` 가 되어
	//     문법이 깨진다(실측으로 밟았다). ★ 그리고 `에` 가 오히려 조립에 맞다 — 첫 절은 **상태**
	//     (`왼쪽에 네모 하나가 있다`)이고 둘째 절이 **동작**(`오른쪽으로 움직인다`)이라,
	//     `그대로 있다` ↔ `움직인다` 의 대립이 같은 자리에서 갈린다.
	//   ⚠️ 출발 자리는 첫 절의 자리 낱말이 이미 준다 ⇒ `에서` 가 없어도 잃는 것이 없다.
	static String CapHead(int cx, int cy, int extent, const MLPalette& c, const char* shape)
	{
		return Format("%s에 %s%s %s 하나가 있다.", WordPos(cx, cy).ptr(),
			WordSize(extent), c.name, shape);
	}

	// 👥 **둘을 가리키는 절**(D64) — `<색> 것` 으로 가리킨다.
	//   ★ 색 낱말을 **지시어로 재사용**한다 ⇒ 새 어휘를 안 늘리고 관계 문장이 생긴다.
	//   ⚠️ 그래서 두 대상의 **색이 달라야** 한다(같으면 가리킬 수 없다).
	static String CapCmp(const MLPalette& a, const MLPalette& b, const char* rel)
	{
		return Format(" %s 것이 %s 것보다 %s.", a.name, b.name, rel);
	}

	// 👥 **모든 「둘」 칸이 함께 쓰는 비교 절**(D64-D).
	//
	// ⚠️ 문법 흠 둘을 실측으로 밟았다(D64-E): ㉠ 절을 이을 때 **문장 사이 공백**을 안 넣어
	//   `있다.아래에` 가 됐다 ㉡ `같다` 는 `보다` 를 안 쓰는데 비교 틀에 넣어 **`A 가 B 보다`**
	//   **`같다`** 가 나왔다 ⇒ 크기가 같을 때는 `둘은 크기가 같다.` 로 **절을 바꾼다**.
	//   ★ 조립은 낱말 재사용에 좋지만 **조사·어미가 절마다 맞아야** 한다 — 캡션을 눈으로 읽어야
	//     보인다(그래서 `-mlrung` 이 칸마다 실제 캡션을 찍는다).
	//
	// ⚠️⚠️ 첫 판(D64)에서 이것을 안 하고 **칸마다 다른 비교**를 넣었다 — 8칸은 크기만, 9칸은 자리만.
	//   그러자 `-mlrung` 이 **비교 5개 중 4개가 한 칸에만** 산다고 그 자리에서 잡았다 ⇒ 함정 209 를
	//   **새 칸에서 그대로 재발**시킨 것이다. ★ 계측이 설계 결함을 즉시 잡은 자리다.
	// ★ 그래서 크기와 자리를 **둘 다, 늘** 말한다 — 두 문장 다 참이므로 거짓이 아니고,
	//   같은 비교 낱말이 **네 칸 전부**에 나온다.
	static String CapPair(const MLPalette& ca, int wa, int cxa,
		const MLPalette& cb, int wb, int cxb)
	{
		String s(" 둘이 있다.");
		s = s + ((wa > wb) ? CapCmp(ca, cb, "더 크다")
			: ((wb > wa) ? CapCmp(cb, ca, "더 크다") : String(" 둘은 크기가 같다.")));
		// ★ 양방향을 다 적는다 — 그래야 `더 왼쪽에`·`더 오른쪽에` 가 둘 다 매 칸에 나온다.
		if (cxa < cxb)
			s = s + CapCmp(ca, cb, "더 왼쪽에 있다") + CapCmp(cb, ca, "더 오른쪽에 있다");
		else if (cxb < cxa)
			s = s + CapCmp(cb, ca, "더 왼쪽에 있다") + CapCmp(ca, cb, "더 오른쪽에 있다");
		return s;
	}

	// ── 에피소드 조립 ────────────────────────────────────────────────────────
	//   ⚠️ `withComments` 가 false 면 **주석 없는 판**이 나온다 — 같은 `(코드, 프레임)` 에 유/무 변형을
	//     두면 "주석이 실행에 영향 없다" 는 사실 자체가 학습된다(→ ML.md 의 조건 ③, 무료 증강).
	// ⚠️⚠️⚠️ **씨앗을 섞어서 넣는다 — 연속 씨앗이 상관된 첫 난수를 낸다.** `SeedRand` 는 상태를 씨앗
	//   그대로 두므로(→ Core/PEMath.h) `seed = 1001..1004` 의 **첫 `RandInt` 가 전부 같은 값**이었다
	//   (실측: 커리큘럼 다섯 칸 중 넷이 같은 색으로 나왔다).
	//   ⚠️ 그냥 "색이 심심하다" 가 아니다 — 에피소드를 **씨앗으로 열거하면 데이터셋에 체계적 편향이
	//     박히고** 그 축(여기서는 색)을 배울 신호가 사라진다.
	//   ★ 섞는 식은 `ImageOps::Grain` 의 정수 믹싱과 같은 것을 쓴다(이 저장소에 이미 있는 관용구).
	//   ⚠️ 0 을 피한다 — `SeedRand(0)` 은 특별 처리로 고정 상태가 된다.
	static uint32 ScrambleSeed(uint32 s)
	{
		uint32 h = s * 374761393u + 668265263u;
		h ^= h >> 13; h *= 1274126177u; h ^= h >> 16;
		return (h != 0u) ? h : 0x2545F491u;
	}

	static void Build(int rung, uint32 seed, bool withComments, MLEpisode& out)
	{
		SeedRand(ScrambleSeed(seed));
		out.rung = rung;
		out.seed = seed;
		out.code.Clear();
		out.caption.Clear();
		out.goalCode.Clear();
		out.frameCount = 1;

		const MLPalette& c = Palette(RandInt(0, PaletteCount()));

		// ★ `domain draw` 는 **각 빌더가** 낸다 — 4·5칸은 최상위 `self.x :=` 가 그 뒤에 와야 하므로
		//   여기서 미리 붙이면 빌더가 지우고 다시 쓰는 꼴이 된다(그 조립 순서 버그를 한 번 냈다).
		if (rung == 1)      _Circle(c, withComments, out);
		else if (rung == 2) _Rect(c, withComments, false, out);
		else if (rung == 3) _Rect(c, withComments, true, out);
		else if (rung == 4) _Move(c, withComments, out);
		else if (rung == 5) _Fall(c, withComments, out);
		else if (rung == 6) _Land(c, withComments, out);   // 🧱 6칸 — 바닥(조건)
		else if (rung == 7)  _Wall(c, withComments, out);  // 🧱 7칸 — 벽(도달 불가능한 목표)
		else if (rung == 8)  _Pair(withComments, out);      // 👥 8칸 — 둘 · 크기 비교
		else if (rung == 9)  _PairPos(withComments, out);   // 👥 9칸 — 둘 · 자리 관계
		else if (rung == 10) _OneMoves(withComments, out);  // 👥 10칸 — 하나만 움직인다
		else                 _Approach(withComments, out);  // 👥 11칸 — 가까워진다/멀어진다
	}

private:
	// 주석 한 줄(들여쓰기 4칸). `withComments` 가 false 면 아무것도 안 쓴다.
	static void _Cmt(String& s, bool on, const char* text)
	{
		if (on) s.AppendFormat("    // %s\n", text);
	}

	// 1칸 — 원 테두리 하나.
	static void _Circle(const MLPalette& c, bool cm, MLEpisode& out)
	{
		const int r  = RandInt(Px(10), Px(34));
		const int cx = RandInt(r + Px(4), kSize - r - Px(4));
		const int cy = RandInt(r + Px(4), kSize - r - Px(4));

		out.code.AppendFormat("domain draw\n\nfunc OnStart()\n{\n");
		_Cmt(out.code, cm, "아무것도 없는 검은 바탕에서 시작한다");
		out.code.AppendFormat("    Draw::Clear(0, 0, 0)\n");
		_Cmt(out.code, cm, Format("%s빛으로 그린다", c.name).ptr());
		out.code.AppendFormat("    Draw::Color(%d, %d, %d)\n", c.r, c.g, c.b);
		_Cmt(out.code, cm, Format("%s에 동그라미를 하나 놓는다. 속은 비어 있다",
			WordPos(cx, cy).ptr()).ptr());
		out.code.AppendFormat("    Draw::Circle(%d, %d, %d)\n}\n", cx, cy, r);

		// 🗣️ 조립: 대상 절 + 채움 절 + 유지 절. `있다`·`하나`·`그대로` 가 다른 칸과 공유된다.
		out.caption = CapHead(cx, cy, r * 2, c, "원")
			+ String(" 테두리만 그려져 있다. 그대로 있다.");
	}

	// 2·3칸 — 네모 테두리 / 채운 네모. ★ 둘의 차이는 **함수 이름 하나**뿐이다(사다리 한 칸 = 능력 하나).
	static void _Rect(const MLPalette& c, bool cm, bool filled, MLEpisode& out)
	{
		const int w = RandInt(Px(18), Px(56));
		const int h = RandInt(Px(18), Px(56));
		const int x = RandInt(Px(4), kSize - w - Px(4));
		const int y = RandInt(Px(4), kSize - h - Px(4));

		out.code.AppendFormat("domain draw\n\nfunc OnStart()\n{\n");
		_Cmt(out.code, cm, "아무것도 없는 검은 바탕에서 시작한다");
		out.code.AppendFormat("    Draw::Clear(0, 0, 0)\n");
		_Cmt(out.code, cm, Format("%s빛으로 그린다", c.name).ptr());
		out.code.AppendFormat("    Draw::Color(%d, %d, %d)\n", c.r, c.g, c.b);
		if (filled)
		{
			_Cmt(out.code, cm, Format("%s에 네모를 놓고 속까지 꽉 채운다",
				WordPos(x + w / 2, y + h / 2).ptr()).ptr());
			out.code.AppendFormat("    Draw::RectFill(%d, %d, %d, %d)\n}\n", x, y, w, h);
			out.caption = CapHead(x + w / 2, y + h / 2, (w > h) ? w : h, c, "네모")
				+ String(" 속까지 채워져 있다. 그대로 있다.");
		}
		else
		{
			_Cmt(out.code, cm, Format("%s에 네모난 테두리를 두른다. 속은 비어 있다",
				WordPos(x + w / 2, y + h / 2).ptr()).ptr());
			out.code.AppendFormat("    Draw::Rect(%d, %d, %d, %d)\n}\n", x, y, w, h);
			out.caption = CapHead(x + w / 2, y + h / 2, (w > h) ? w : h, c, "네모")
				+ String(" 테두리만 그려져 있다. 그대로 있다.");
		}
	}

	// 4칸 — 옆으로 간다. ★ **시간축이 처음 생긴다**(프레임이 여러 장).
	static void _Move(const MLPalette& c, bool cm, MLEpisode& out)
	{
		const int size = RandInt(Px(16), Px(30));
		const int y    = RandInt(Px(20), kSize - size - Px(20));
		const int step = RandInt(Px(4), Px(11));
		const int x0   = RandInt(Px(4), Px(20));
		out.frameCount = 6;

		out.code.AppendFormat("domain draw\n\n");
		// ⚠️ 최상위 선언 앞 주석은 **들여쓰지 않는다** — `_Cmt` 는 함수 안(4칸)용이다.
		if (cm) out.code.AppendFormat("// 왼쪽 끝에서 시작한다\n");
		out.code.AppendFormat("self.x := %d\n", x0);
		if (cm) out.code.AppendFormat("// 한 장 넘어갈 때마다 이만큼 옮긴다. 늘 같은 만큼이다\n");
		out.code.AppendFormat("self.step := %d\n", step);

		out.code.AppendFormat("\nfunc OnStart()\n{\n");
		out.code.AppendFormat("    Draw::Clear(0, 0, 0)\n");
		out.code.AppendFormat("    Draw::Color(%d, %d, %d)\n", c.r, c.g, c.b);
		out.code.AppendFormat("    Draw::RectFill(self.x, %d, %d, %d)\n}\n", y, size, size);

		out.code.AppendFormat("\nfunc OnFrame()\n{\n");
		_Cmt(out.code, cm, "있던 자리에서 한 걸음 나아간다");
		out.code.AppendFormat("    self.x = self.x + self.step\n");
		_Cmt(out.code, cm, "지난 그림은 지우고, 새 자리에 다시 그린다");
		out.code.AppendFormat("    Draw::Clear(0, 0, 0)\n");
		out.code.AppendFormat("    Draw::Color(%d, %d, %d)\n", c.r, c.g, c.b);
		out.code.AppendFormat("    Draw::RectFill(self.x, %d, %d, %d)\n}\n", y, size, size);

		out.caption = CapHead(x0 + size / 2, y + size / 2, size, c, "네모")
			+ String(" 오른쪽으로 움직인다. 빠르기가 일정하다.");
	}

	// 5칸 — 떨어진다. ★ **규칙 하나가 더 생긴다**: 걸음이 일정하지 않고 커진다.
	//   ⚠️ 이 언어에 `+=` 가 없어서 `self.v = self.v + self.g` 로 쓴다 — **그것이 이득이다**:
	//     읽기-수정-쓰기가 명시적이라 재귀 관계가 토큰 흐름에 그대로 보인다(→ ML.md).
	static void _Fall(const MLPalette& c, bool cm, MLEpisode& out)
	{
		const int size = RandInt(Px(16), Px(30));
		const int x    = RandInt(Px(10), kSize - size - Px(10));
		const int y0   = RandInt(Px(4), Px(16));
		// ⚠️ **가속은 길이가 아니라 1 이 하한이다** — `Px(1)` 은 64² 에서 0 이고, 0 이면 **떨어지지 않는다**
		//   (캡션은 "떨어진다" 고 말하는데 그림은 멈춰 있다 → 캡션이 거짓). 그래서 1 을 바닥에 깐다.
		const int g    = RandInt(1, 1 + Px(3));
		out.frameCount = 6;

		out.code.AppendFormat("domain draw\n\n");
		if (cm) out.code.AppendFormat("// 위에서 시작한다\n");
		out.code.AppendFormat("self.y := %d\n", y0);
		if (cm) out.code.AppendFormat("// 아래로 내려가는 빠르기. 처음에는 멈춰 있다\n");
		out.code.AppendFormat("self.v := 0\n");
		if (cm) out.code.AppendFormat("// 한 장마다 빠르기에 더해지는 양 — 이것 때문에 갈수록 빨라진다\n");
		out.code.AppendFormat("self.g := %d\n", g);

		out.code.AppendFormat("\nfunc OnStart()\n{\n");
		out.code.AppendFormat("    Draw::Clear(0, 0, 0)\n");
		out.code.AppendFormat("    Draw::Color(%d, %d, %d)\n", c.r, c.g, c.b);
		out.code.AppendFormat("    Draw::RectFill(%d, self.y, %d, %d)\n}\n", x, size, size);

		out.code.AppendFormat("\nfunc OnFrame()\n{\n");
		_Cmt(out.code, cm, "먼저 빠르기가 자란다");
		out.code.AppendFormat("    self.v = self.v + self.g\n");
		_Cmt(out.code, cm, "그 빠르기만큼 내려간다. 그래서 아래로 갈수록 그림 사이 간격이 벌어진다");
		out.code.AppendFormat("    self.y = self.y + self.v\n");
		out.code.AppendFormat("    Draw::Clear(0, 0, 0)\n");
		out.code.AppendFormat("    Draw::Color(%d, %d, %d)\n", c.r, c.g, c.b);
		out.code.AppendFormat("    Draw::RectFill(%d, self.y, %d, %d)\n}\n", x, size, size);

		out.caption = CapHead(x + size / 2, y0 + size / 2, size, c, "네모")
			+ String(" 아래로 움직인다. 점점 빨라진다. 떨어진다.");
	}

	// 🧱 6칸 — 떨어져서 **바닥에 닿아 멈춘다**. ★ 능력 하나가 늘어난다: **조건**(`if`).
	//
	// ★ **왜 이 칸이 필요한가 — D56 이 실측했다**: 1~5칸에 「막힘」이 **0개**다(240 걸음 중 0).
	//   세계에 멈추는 일이 없으면 「됐다」·「막힘」이라는 낱말이 **가리킬 대상이 없고**, 그러면
	//   호/불호는 **상수**가 된다 — 그것은 `MLLife` 의 `trust`(칸마다 같은 값)가 평평했던 것의
	//   재현이다(→ ML.md 의 🚫 · 「호/불호의 자리」).
	// ★ 그리고 이것이 대화에서 나온 그 문장이다 — *"사과가 떨어져서 **바닥에 닿아서** 부서지고"*.
	//   바닥이 없으면 그 문장은 이 세계에 **존재할 수 없다**.
	//
	// ⚠️ **바닥은 무작위 파라미터가 아니라 세계의 규칙이다** — 화면 아래(도형의 밑변이 닿는 자리)에
	//   붙인다. 대신 **가속을 역산해** 창(6프레임) 안에서 닿게 한다: 착지 프레임 `lf` 를 고르고
	//   `g = ceil((바닥 - 시작) / T)`, `T = lf(lf+1)/2`. ⇒ 「떨어진다 → 닿는다 → 멈춘다」가
	//   **한 에피소드 안에** 다 들어온다.
	//   ★ 왜 역산인가: 5칸의 `g` 는 실질 **1로 고정**돼 있어서(`RandInt(1, 1 + Px(3))` = `[1,2)`)
	//     6프레임에 15px 만 내려간다 — 그 값으로는 64px 캔버스의 바닥에 **닿을 수 없다**(D56 이
	//     「화면 밖으로 나가는 일도 없었다」로 그것을 실측했다).
	// ⚠️ 착지 뒤 프레임은 **바이트가 같다** ⇒ 델타가 0 ⇒ `-mlstuck` 이 그것을 센다(**대조군 공짜**).
	// ⚠️ 주석은 여전히 **숫자를 되읽지 않는다**(머리말의 그 ★) — `바닥`도 정성적으로만 말한다.
	static void _Land(const MLPalette& c, bool cm, MLEpisode& out)
	{
		const int size = RandInt(Px(16), Px(30));
		const int x    = RandInt(Px(10), kSize - size - Px(10));
		const int y0   = RandInt(Px(4), Px(16));
		// 🧱 바닥 — 도형의 **밑변**이 화면 아래에 닿는 자리(그래서 `kSize - size`).
		const int fl   = kSize - size - Px(4);
		// 🎯 착지 프레임 2·3·4 — 1이면 「떨어지는 것」을 한 장도 못 보고, 5면 멈춘 걸음이 하나뿐이다.
		const int lf   = RandInt(2, 5);
		const int T    = lf * (lf + 1) / 2;
		int g = (fl > y0) ? ((fl - y0 + T - 1) / T) : 1;   // 올림 — `lf` 에 **닿거나 지나친다**
		if (g < 1) g = 1;
		out.frameCount = 6;

		out.code.AppendFormat("domain draw\n\n");
		if (cm) out.code.AppendFormat("// 위에서 시작한다\n");
		out.code.AppendFormat("self.y := %d\n", y0);
		if (cm) out.code.AppendFormat("// 아래로 내려가는 빠르기. 처음에는 멈춰 있다\n");
		out.code.AppendFormat("self.v := 0\n");
		if (cm) out.code.AppendFormat("// 한 장마다 빠르기에 더해지는 양 — 이것 때문에 갈수록 빨라진다\n");
		out.code.AppendFormat("self.g := %d\n", g);
		if (cm) out.code.AppendFormat("// 여기가 바닥이다. 이보다 더 아래로는 못 간다\n");
		out.code.AppendFormat("self.floor := %d\n", fl);

		out.code.AppendFormat("\nfunc OnStart()\n{\n");
		out.code.AppendFormat("    Draw::Clear(0, 0, 0)\n");
		out.code.AppendFormat("    Draw::Color(%d, %d, %d)\n", c.r, c.g, c.b);
		out.code.AppendFormat("    Draw::RectFill(%d, self.y, %d, %d)\n}\n", x, size, size);

		out.code.AppendFormat("\nfunc OnFrame()\n{\n");
		_Cmt(out.code, cm, "먼저 빠르기가 자란다");
		out.code.AppendFormat("    self.v = self.v + self.g\n");
		_Cmt(out.code, cm, "그 빠르기만큼 내려간다");
		out.code.AppendFormat("    self.y = self.y + self.v\n");
		_Cmt(out.code, cm, "바닥을 지나쳤으면 바닥에 세운다. 그리고 더는 내려가지 않는다");
		out.code.AppendFormat("    if self.y > self.floor\n    {\n");
		out.code.AppendFormat("        self.y = self.floor\n");
		out.code.AppendFormat("        self.v = 0\n    }\n");
		out.code.AppendFormat("    Draw::Clear(0, 0, 0)\n");
		out.code.AppendFormat("    Draw::Color(%d, %d, %d)\n", c.r, c.g, c.b);
		out.code.AppendFormat("    Draw::RectFill(%d, self.y, %d, %d)\n}\n", x, size, size);

		out.caption = CapHead(x + size / 2, y0 + size / 2, size, c, "네모")
			+ String(" 아래로 움직인다. 점점 빨라진다. 떨어진다.")
			+ String(" 바닥에 닿는다. 멈춘다.");
	}

	// 🧱 7칸 — 오른쪽으로 가다 **벽에 막힌다**. ★ 능력은 6칸과 **같다**(조건) ⇒ 사다리가 안 늘어난다.
	//
	// ★ **바닥과 벽은 같은 `if` 인데 뜻이 반대다.**
	//   · 바닥(6칸) — 목표가 **거기**다 ⇒ 닿으면 「됐다」
	//   · 벽(7칸)   — 목표가 **그 너머**다 ⇒ 닿으면 「막힘」
	//   ⇒ 그래서 이 칸은 **목표 코드**를 같이 낸다: **벽이 없는 같은 프로그램**. 그것을 돌린
	//     마지막 장이 «벽이 없었다면 갔을 자리» 이고, 그 자리는 이 에피소드에 **한 장도 안 나온다**.
	// ⚠️ 목표가 화면 안에 있어야 한다 — 밖이면 목표 장이 **빈 캔버스**이고 무게중심이 없다
	//   ⇒ `step` 의 상한을 `(kSize - size - x0) / 5` 로 잡는다.
	// ⚠️ 벽은 **목표보다 앞**이어야 한다(안 그러면 막힘이 아니라 도착이다) — `lw <= 3` 이라 성립한다.
	static void _Wall(const MLPalette& c, bool cm, MLEpisode& out)
	{
		const int size = RandInt(Px(16), Px(30));
		const int y    = RandInt(Px(20), kSize - size - Px(20));
		const int x0   = RandInt(Px(4), Px(12));
		int sMax = (kSize - size - x0) / 5;            // 목표가 화면 안에 남는 상한
		if (sMax < 3) sMax = 3;
		const int step = RandInt(2, sMax + 1);
		const int lw   = RandInt(2, 4);                // 벽에 닿는 프레임(2·3)
		int wall = x0 + (lw - 1) * step + ((step / 2 > 0) ? (step / 2) : 1);
		const int cap = kSize - size - Px(2);
		if (wall > cap) wall = cap;
		out.frameCount = 6;

		out.code.AppendFormat("domain draw\n\n");
		if (cm) out.code.AppendFormat("// 왼쪽 끝에서 시작한다\n");
		out.code.AppendFormat("self.x := %d\n", x0);
		if (cm) out.code.AppendFormat("// 한 장 넘어갈 때마다 이만큼 옮긴다\n");
		out.code.AppendFormat("self.step := %d\n", step);
		if (cm) out.code.AppendFormat("// 여기가 벽이다. 이보다 더 오른쪽으로는 못 간다\n");
		out.code.AppendFormat("self.wall := %d\n", wall);

		out.code.AppendFormat("\nfunc OnStart()\n{\n");
		out.code.AppendFormat("    Draw::Clear(0, 0, 0)\n");
		out.code.AppendFormat("    Draw::Color(%d, %d, %d)\n", c.r, c.g, c.b);
		out.code.AppendFormat("    Draw::RectFill(self.x, %d, %d, %d)\n}\n", y, size, size);

		out.code.AppendFormat("\nfunc OnFrame()\n{\n");
		_Cmt(out.code, cm, "있던 자리에서 한 걸음 나아간다");
		out.code.AppendFormat("    self.x = self.x + self.step\n");
		_Cmt(out.code, cm, "벽을 지나쳤으면 벽에 붙인다. 그리고 더는 나아가지 못한다");
		out.code.AppendFormat("    if self.x > self.wall\n    {\n");
		out.code.AppendFormat("        self.x = self.wall\n    }\n");
		out.code.AppendFormat("    Draw::Clear(0, 0, 0)\n");
		out.code.AppendFormat("    Draw::Color(%d, %d, %d)\n", c.r, c.g, c.b);
		out.code.AppendFormat("    Draw::RectFill(self.x, %d, %d, %d)\n}\n", y, size, size);

		// 🎯 **목표 = 벽이 없는 같은 프로그램**(주석은 안 붙인다 — 이것은 모델에게 보이는 코드가
		//   아니라 **세계가 목표 장을 만드는 식**이다).
		out.goalCode.AppendFormat("domain draw\n\n");
		out.goalCode.AppendFormat("self.x := %d\n", x0);
		out.goalCode.AppendFormat("self.step := %d\n", step);
		out.goalCode.AppendFormat("\nfunc OnStart()\n{\n");
		out.goalCode.AppendFormat("    Draw::Clear(0, 0, 0)\n");
		out.goalCode.AppendFormat("    Draw::Color(%d, %d, %d)\n", c.r, c.g, c.b);
		out.goalCode.AppendFormat("    Draw::RectFill(self.x, %d, %d, %d)\n}\n", y, size, size);
		out.goalCode.AppendFormat("\nfunc OnFrame()\n{\n");
		out.goalCode.AppendFormat("    self.x = self.x + self.step\n");
		out.goalCode.AppendFormat("    Draw::Clear(0, 0, 0)\n");
		out.goalCode.AppendFormat("    Draw::Color(%d, %d, %d)\n", c.r, c.g, c.b);
		out.goalCode.AppendFormat("    Draw::RectFill(self.x, %d, %d, %d)\n}\n", y, size, size);

		out.caption = CapHead(x0 + size / 2, y + size / 2, size, c, "네모")
			+ String(" 오른쪽으로 움직인다. 빠르기가 일정하다.")
			+ String(" 벽에 닿는다. 멈춘다.");
	}

	// ══════════════════════════════════════════════════════════════════════════
	// 👥 **8~11칸 — 대상을 둘로**(D64). ★ 능력은 **하나**다(둘째 대상) · 사례는 **넷**이다.
	//
	// ★ **왜 이 층인가** — D62 의 커버리지가 숫자로 보냈다: **대상 수 축이 1 에 고정**돼 있어
	//   「더 크다·더 가깝다·사이」(성장 지도 3단계)와 「충돌·합쳐짐」(4단계)이 ***원리적으로***
	//   표현 불가였다. 관계 수 축도 그래서 **0** 이었다. ⇒ 한 칸이 **여러 단계를 동시에** 연다.
	//
	// ★ **예시 하나를 칸으로 착각하지 않는다**(concept.md 의 그 규칙) — 「둘」의 사례를 넷 둔다:
	//   8 크기 비교 · 9 자리 관계 · 10 하나만 움직인다 · 11 가까워진다/멀어진다.
	//
	// ★ **어휘를 칸에 묶지 않는다** — `둘`·`보다`·`더 크다`가 여러 칸에 나오고, `그대로 있다`(10칸)와
	//   `닿는다`·`멈춘다`(11칸)는 **옛 칸과 공유**된다.
	// ⭐ 그리고 11칸이 특별하다 — **`가까워진다`·`멀어진다`가 세계의 3인칭 사건으로 먼저 생긴다.**
	//   나중에 1인칭 호/불호(`나아짐`)가 **그 낱말을 재료로** 쓸 수 있다(연결 조직).
	//
	// ⚠️ **1~7칸은 한 줄도 안 고친다**(추가만) ⇒ D56~D63 의 측정이 그대로 재현된다.
	// ⚠️ 그래서 **함정 210(「큰」이 0개)도 여기서 푼다** — 옛 칸의 크기 범위를 건드리지 않고,
	//   새 칸을 **위아래로** 배치해 폭을 넓게 뽑는다(`WordSize` 의 「큰」 경계는 `kSize/2` = 32).
	// ⚠️ 두 대상의 **색이 달라야** 한다 — `<색> 것` 으로 가리키기 때문이다.
	// ══════════════════════════════════════════════════════════════════════════

	// 🎨 색 둘을 **다르게** 고른다.
	static void _TwoColors(int& ia, int& ib)
	{
		const int n = PaletteCount();
		ia = RandInt(0, n);
		ib = (ia + RandInt(1, n)) % n;
	}

	// 8칸 — 둘이 위아래로 있다. ★ 능력: **크기 비교**(3단계). 「큰」이 여기서 살아난다.
	static void _Pair(bool cm, MLEpisode& out)
	{
		int ia = 0, ib = 0; _TwoColors(ia, ib);
		const MLPalette& ca = Palette(ia);
		const MLPalette& cb = Palette(ib);
		// ⚠️ 폭을 넓게 뽑는다 — 그래야 `WordSize` 의 「큰」(> 32)이 나온다(함정 210).
		const int wa = RandInt(Px(20), Px(90)), wb = RandInt(Px(20), Px(90));
		const int ha = RandInt(Px(12), Px(40)), hb = RandInt(Px(12), Px(40));
		const int xa = RandInt(Px(2), kSize - wa - Px(2));
		const int xb = RandInt(Px(2), kSize - wb - Px(2));
		const int ya = Px(6), yb = kSize - hb - Px(6);        // 위 · 아래
		out.frameCount = 1;

		out.code.AppendFormat("domain draw\n\nfunc OnStart()\n{\n");
		_Cmt(out.code, cm, "아무것도 없는 검은 바탕에서 시작한다");
		out.code.AppendFormat("    Draw::Clear(0, 0, 0)\n");
		_Cmt(out.code, cm, "위에 하나를 놓는다");
		out.code.AppendFormat("    Draw::Color(%d, %d, %d)\n", ca.r, ca.g, ca.b);
		out.code.AppendFormat("    Draw::RectFill(%d, %d, %d, %d)\n", xa, ya, wa, ha);
		_Cmt(out.code, cm, "아래에 또 하나를 놓는다. 이제 둘이다");
		out.code.AppendFormat("    Draw::Color(%d, %d, %d)\n", cb.r, cb.g, cb.b);
		out.code.AppendFormat("    Draw::RectFill(%d, %d, %d, %d)\n}\n", xb, yb, wb, hb);

		out.caption = CapHead(xa + wa / 2, ya + ha / 2, wa, ca, "네모")
			+ String(" ") + CapHead(xb + wb / 2, yb + hb / 2, wb, cb, "네모")
			+ CapPair(ca, wa, xa + wa / 2, cb, wb, xb + wb / 2);
	}

	// 9칸 — 둘이 좌우로 있다. ★ 능력: **자리 관계**(3단계). `보다` 를 8칸과 공유한다.
	static void _PairPos(bool cm, MLEpisode& out)
	{
		int ia = 0, ib = 0; _TwoColors(ia, ib);
		const MLPalette& ca = Palette(ia);
		const MLPalette& cb = Palette(ib);
		// ⚠️ 둘의 크기를 **다르게** 뽑는다 — 그래야 이 칸에도 크기 비교 낱말이 나온다(D64-D).
		const int sa = RandInt(Px(14), Px(40)), sb = RandInt(Px(14), Px(40));
		const int ya = RandInt(Px(4), kSize - sa - Px(4));
		const int yb = RandInt(Px(4), kSize - sb - Px(4));
		const int xa = Px(6), xb = kSize - sb - Px(6);       // 왼쪽 · 오른쪽
		out.frameCount = 1;

		out.code.AppendFormat("domain draw\n\nfunc OnStart()\n{\n");
		out.code.AppendFormat("    Draw::Clear(0, 0, 0)\n");
		_Cmt(out.code, cm, "왼쪽에 하나를 놓는다");
		out.code.AppendFormat("    Draw::Color(%d, %d, %d)\n", ca.r, ca.g, ca.b);
		out.code.AppendFormat("    Draw::RectFill(%d, %d, %d, %d)\n", xa, ya, sa, sa);
		_Cmt(out.code, cm, "오른쪽에 또 하나를 놓는다");
		out.code.AppendFormat("    Draw::Color(%d, %d, %d)\n", cb.r, cb.g, cb.b);
		out.code.AppendFormat("    Draw::RectFill(%d, %d, %d, %d)\n}\n", xb, yb, sb, sb);

		out.caption = CapHead(xa + sa / 2, ya + sa / 2, sa, ca, "네모")
			+ String(" ") + CapHead(xb + sb / 2, yb + sb / 2, sb, cb, "네모")
			+ CapPair(ca, sa, xa + sa / 2, cb, sb, xb + sb / 2);
	}

	// 10칸 — 둘 중 **하나만** 움직인다. ★ 능력: **유지와 변화가 한 장면에**(1단계의 대립).
	static void _OneMoves(bool cm, MLEpisode& out)
	{
		int ia = 0, ib = 0; _TwoColors(ia, ib);
		const MLPalette& ca = Palette(ia);       // 그대로 있는 것
		const MLPalette& cb = Palette(ib);       // 움직이는 것
		const int wa = RandInt(Px(20), Px(90)), ha = RandInt(Px(12), Px(30));
		const int s  = RandInt(Px(14), Px(30));
		const int xa = RandInt(Px(2), kSize - wa - Px(2)), ya = Px(4);
		const int yb = kSize - s - Px(6);
		// ⚠️ 방향을 랜덤으로 둔다 — 그래야 `왼쪽으로` 가 이 칸에도 나온다(D64-D).
		const bool toRight = (RandInt(0, 2) == 0);
		const int step = RandInt(Px(6), Px(16));
		const int x0 = toRight ? Px(4) : (kSize - s - Px(4));
		// 🔗 정지한 것과 **가까워지나 멀어지나** — 첫 칸과 끝 칸의 거리로 정한다.
		const int cxs = xa + wa / 2;
		const int c0 = x0 + s / 2, c5 = c0 + (toRight ? 1 : -1) * step * 5;
		const int d0 = (c0 > cxs) ? (c0 - cxs) : (cxs - c0);
		const int d5 = (c5 > cxs) ? (c5 - cxs) : (cxs - c5);
		out.frameCount = 6;

		out.code.AppendFormat("domain draw\n\n");
		if (cm) out.code.AppendFormat("// 움직이는 것의 자리. 위의 것은 상태가 없다\n");
		out.code.AppendFormat("self.x := %d\n", x0);
		out.code.AppendFormat("self.step := %d\n", toRight ? step : -step);
		out.code.AppendFormat("\nfunc OnStart()\n{\n");
		out.code.AppendFormat("    Draw::Clear(0, 0, 0)\n");
		out.code.AppendFormat("    Draw::Color(%d, %d, %d)\n", ca.r, ca.g, ca.b);
		out.code.AppendFormat("    Draw::RectFill(%d, %d, %d, %d)\n", xa, ya, wa, ha);
		out.code.AppendFormat("    Draw::Color(%d, %d, %d)\n", cb.r, cb.g, cb.b);
		out.code.AppendFormat("    Draw::RectFill(self.x, %d, %d, %d)\n}\n", yb, s, s);
		out.code.AppendFormat("\nfunc OnFrame()\n{\n");
		_Cmt(out.code, cm, "아래 것만 한 걸음 나아간다. 위 것은 매번 같은 자리에 다시 그린다");
		out.code.AppendFormat("    self.x = self.x + self.step\n");
		out.code.AppendFormat("    Draw::Clear(0, 0, 0)\n");
		out.code.AppendFormat("    Draw::Color(%d, %d, %d)\n", ca.r, ca.g, ca.b);
		out.code.AppendFormat("    Draw::RectFill(%d, %d, %d, %d)\n", xa, ya, wa, ha);
		out.code.AppendFormat("    Draw::Color(%d, %d, %d)\n", cb.r, cb.g, cb.b);
		out.code.AppendFormat("    Draw::RectFill(self.x, %d, %d, %d)\n}\n", yb, s, s);

		out.caption = CapHead(xa + wa / 2, ya + ha / 2, wa, ca, "네모")
			+ String(" ") + CapHead(x0 + s / 2, yb + s / 2, s, cb, "네모")
			+ CapPair(ca, wa, xa + wa / 2, cb, s, x0 + s / 2)
			+ Format(" %s 것은 그대로 있다.", ca.name)
			+ Format(" %s 것은 %s 움직인다.", cb.name, toRight ? "오른쪽으로" : "왼쪽으로")
			+ String((d5 < d0) ? " 가까워진다." : " 멀어진다.");
	}

	// 11칸 — 둘이 **가까워진다 / 멀어진다**. ★ 능력: **관계가 시간에 따라 변한다**(3+4단계).
	//   ⭐ `가까워진다`·`멀어진다` 가 여기서 생긴다 — 나중에 1인칭 호/불호가 **그 낱말을 재료로** 쓴다.
	static void _Approach(bool cm, MLEpisode& out)
	{
		int ia = 0, ib = 0; _TwoColors(ia, ib);
		const MLPalette& ca = Palette(ia);
		const MLPalette& cb = Palette(ib);
		const int s = RandInt(Px(14), Px(28));
		const int ya = Px(8), yb = kSize - s - Px(8);
		// 🐛🐛 **`near` 는 이름으로 쓸 수 없다** — Windows 헤더의 **매크로**다(`far` 도 같다).
		//   변수로 쓰면 `expected unqualified-id before '=' token` 으로 터지고, **에러가 원인과
		//   안 닮는다**(선언 자리를 가리키지 매크로를 가리키지 않는다). ⇒ `toward` 로 쓴다.
		const bool toward = (RandInt(0, 2) == 0);              // 가까워지나 멀어지나
		const int step = RandInt(Px(4), Px(11));
		// 가까워지면 안에서 시작해 서로를 향하고, 멀어지면 가운데서 시작해 벌어진다.
		const int ax = toward ? Px(4) : (kSize / 2 - s - Px(2));
		const int bx = toward ? (kSize - s - Px(4)) : (kSize / 2 + Px(2));
		out.frameCount = 6;

		out.code.AppendFormat("domain draw\n\n");
		out.code.AppendFormat("self.a := %d\n", ax);
		out.code.AppendFormat("self.b := %d\n", bx);
		if (cm) out.code.AppendFormat("// 둘이 매번 이만큼씩 서로에게 다가간다\n");
		out.code.AppendFormat("self.step := %d\n", step);
		out.code.AppendFormat("\nfunc OnStart()\n{\n");
		out.code.AppendFormat("    Draw::Clear(0, 0, 0)\n");
		out.code.AppendFormat("    Draw::Color(%d, %d, %d)\n", ca.r, ca.g, ca.b);
		out.code.AppendFormat("    Draw::RectFill(self.a, %d, %d, %d)\n", ya, s, s);
		out.code.AppendFormat("    Draw::Color(%d, %d, %d)\n", cb.r, cb.g, cb.b);
		out.code.AppendFormat("    Draw::RectFill(self.b, %d, %d, %d)\n}\n", yb, s, s);
		out.code.AppendFormat("\nfunc OnFrame()\n{\n");
		out.code.AppendFormat("    self.a = self.a %s self.step\n", toward ? "+" : "-");
		out.code.AppendFormat("    self.b = self.b %s self.step\n", toward ? "-" : "+");
		out.code.AppendFormat("    Draw::Clear(0, 0, 0)\n");
		out.code.AppendFormat("    Draw::Color(%d, %d, %d)\n", ca.r, ca.g, ca.b);
		out.code.AppendFormat("    Draw::RectFill(self.a, %d, %d, %d)\n", ya, s, s);
		out.code.AppendFormat("    Draw::Color(%d, %d, %d)\n", cb.r, cb.g, cb.b);
		out.code.AppendFormat("    Draw::RectFill(self.b, %d, %d, %d)\n}\n", yb, s, s);

		// ⚠️ 「서로」를 **뺐다** — 둘 다 움직일 때만 참이라 원리적으로 이 칸에 갇힌다.
		//   빼도 잃는 것이 없다(이어지는 두 절이 둘 다 움직인다고 말한다).
		out.caption = CapHead(ax + s / 2, ya + s / 2, s, ca, "네모")
			+ String(" ") + CapHead(bx + s / 2, yb + s / 2, s, cb, "네모")
			+ CapPair(ca, s, ax + s / 2, cb, s, bx + s / 2)
			+ String(toward ? " 가까워진다." : " 멀어진다.")
			+ Format(" %s 것은 오른쪽으로 움직인다.", toward ? ca.name : cb.name)
			+ Format(" %s 것은 왼쪽으로 움직인다.", toward ? cb.name : ca.name);
	}

public:   // 🖐️ 과제 API — 아래는 밖(라운드)에서 부른다.

	// ══════════════════════════════════════════════════════════════════════════
	// 🖐️ **과제 코드**(D66) — 축 셋의 값을 받아 프로그램을 낸다.
	//
	// ★ **여기서 모델이 처음으로 행동한다.** 지금까지 세계가 코드를 주고 모델은 봤다
	//   ⇒ 개입이 없어 인과(성장 지도 5단계)도 **1인칭 자기상태**(6단계)도 원리적으로 생길 수
	//   없었다(D62 의 커버리지가 「행동 길이 0」으로 그것을 찍었다).
	// ★ **가장 작은 행동 = 후보 중 하나를 고르는 것.** 축 셋(색 · 자리 · 크기)의 값을 고르면
	//   프로그램 하나가 되고, 그것을 실행하면 결과가 나온다. 그 결과를 **비전으로 읽어** 무엇이
	//   틀렸는지 스스로 안다 — 그것이 대화에서 나온 *"코딩 때 잘됐나 자기 검사도 비전으로"* 다.
	// ⚠️ **새 능력이 아니다** — 커리큘럼 1~3칸과 **같은 어휘**(`Draw::Clear/Color/RectFill`)를 쓴다.
	//   행동이 생긴 것이지 문법이 는 것이 아니다.
	// ⚠️ 크기 3단의 맨 위는 **`WordSize` 의 「큰」 경계(32)를 넘게** 잡는다 — 과제의 어휘가
	//   커리큘럼의 어휘와 같아야 한다.
	// ⚠️⚠️⚠️ **축은 직교해야 한다.** 첫 판(D66)에서 `x` 를 `(kSize - s)/2` 로 잡아 **자리가**
	//   **크기에 의존**했다 ⇒ 크기를 바꾸면 중심 x 도 바뀌어 「자리가 틀렸다」가 **크기 때문에도**
	//   참이 됐다. 실측: 자리 지목 정확도 **33.0%**(= 축 셋에서 **무작위**) · 도달 **67.5%**
	//   (고리가 갇힌다 — 크기를 맞추면 자리가 깨지고 그 반대도 된다).
	//   ⇒ **중심 x 를 크기와 무관하게** 두고 거기서 `s/2` 를 뺀다.
	//   ★ 이것이 `concept.md` 의 *"한 번에 하나만 바꾸는 쉬운 경험"* 을 세계 쪽에서 지키는 일이다
	//     — 축이 얽혀 있으면 「어느 축이 틀렸나」가 **원리적으로** 안 갈린다.
	// ══════════════════════════════════════════════════════════════════════════

	// 축 셋의 값 개수 — 0 색 · 1 자리 · 2 크기.
	static int TaskAxisCount(int ax) { return (ax == 0) ? PaletteCount() : 3; }
	static const char* TaskAxisName(int ax)
	{
		return (ax == 0) ? "색" : ((ax == 1) ? "자리" : "크기");
	}

	// 🎭 **과제 유형 셋**(D104) — 같은 축(색·자리·크기) · 같은 행동 · 같은 세계 법칙인데
	//   **특징이 말하는 방식만** 다르다. ⇒ *"하나에 핏된 부분"* 을 **간섭으로** 드러내는 축이다.
	//   ★ `Draw::` 표면에 이미 다 있다(`RectFill` · `Rect` · `CircleFill`) ⇒ 엔진 변경 0.
	//   ⚠️ **유형은 에피소드마다 고정**이다 — 「도형 바꾸기」는 행동 집합에 없으므로
	//     목표와 지금이 같은 유형이어야 과제가 성립한다. 「섞음」은 **에피소드끼리** 섞는 것이다.
	static constexpr int kTaskTypes = 3;
	static const char* TaskTypeName(int ti)
	{
		if (ti == 1) return "⬜ 빈 네모";
		if (ti == 2) return "⚪ 찬 동그라미";
		return "🟥 찬 네모";
	}
	// 🎭 **방해자 변주 표**(D140 · D166 이 공유한다) — 색 셋 · 크기 셋.
	//   ⚠️ 색은 셋 다 **팔레트 밖**이고, 크기 잉크(**36 / 64 / 144**)는 목표 잉크({100, 484, 1156})와
	//     **하나도 안 겹친다**(겹치면 잉크가 키가 될 수 없다).
	//   ⚠️ `di == 1`(고정)이 **크기 8** 인 것은 옛 팔 재현 때문이다.
	//   ⚠️ 클래스 스코프의 `static` 배열은 **`constexpr`** 이어야 클래스 안에서 초기화된다.
	static constexpr int kDistR[3] = { 160,  60, 120 };
	static constexpr int kDistG[3] = { 120, 160,  60 };
	static constexpr int kDistB[3] = {  60, 120, 160 };
	static constexpr int kDistS[3] = { 6, 8, 12 };
	// 📍 **자리 변주**(D179) — A 의 x. ⚠️ 최대 끝 20+6=26 < B 의 최소 시작 32 ⇒ 안 겹친다.
	static constexpr int kDistX[3] = { 0, 10, 20 };

	// ★ 기본값 0 = 옛 회차와 **같은 세계**(재현이 성립한다).
	static String TaskCode(int ci, int xi, int si, int ti = 0, int di = 0)
	{
		const MLPalette& c = Palette(ci);
		const int s = Px(20) + si * Px(24);                  // 10 · 22 · 34 px (맨 위가 「큰」)
		const int cxs = kSize / 2 + (xi - 1) * Px(30);        // 중심 x: 17 · 32 · 47
		const int x = cxs - s / 2;                            // ★ 크기와 **무관**하다
		const int y = (kSize - s) / 2;
		String o;
		o.AppendFormat("domain draw\n\nfunc OnStart()\n{\n");
		o.AppendFormat("    Draw::Clear(0, 0, 0)\n");
		// 🎭 **방해자**(`di != 0`) — 왼쪽 위 구석의 8x8. ★ 목표와 **겹치지 않는다**: 목표의 `y` 는
		//   늘 중앙 쪽이다(가장 큰 크기 34 에서도 `y >= 15`) ⇒ **겹침 조각이 안 생긴다**
		//   (D136 이 「겹치면 `잉크 < 8` 이 성분마다 걸린다」를 경계로 남겼다 — 그 축을 피한다).
		//   ⚠️⚠️ 색이 **팔레트 밖**이다 — 팔레트 색인으로 두면 `ci` 가 그 색일 때 **목표와 같은 색**이
		//     되어 「값으로 짝짓기」가 원리적으로 무너진다(그건 다음 축이다 · 한 판에 한 축).
		//   ★ 색은 **고정**이고 목표 색은 **순환**한다(행동 0 = 색+1) ⇒ 성분 순서(**값 순**)에서
		//     방해자가 **간헐적으로** 앞에 온다. 그것이 재려는 **조용한 묶임 실패**다.
		//   ⚠️ `di == 0` 이면 코드가 **한 글자도 안 달라진다** ⇒ 옛 세계 재현이 성립한다(함정 213).
		// 🎨 **색 변주**(D140) — `di == 1` 은 고정색, `di >= 2` 는 `(di-2) % 3` 번째 색이다.
		//   ★ 셋 다 **팔레트 밖**이고 서로 다르다 ⇒ 프레임마다 `di` 를 바꾸면 **방해자가 변한다**
		//     = D139 의 관찰(「안 변한 것이 방해자」)이 **정면으로** 깨지는 세계다.
		//   ⚠️ **잉크는 안 바꾼다**(늘 8x8 = 64) — 한 판에 한 축이고, 그 덕에 「개입+예측」이
		//     쓸 수 있는 키가 **잉크**로 남는다(그것이 다음 축의 자리다).
		// 🎨🎨 **같은 색 방해자 둘**(D153) — `di == 20` 은 **대상 수 축**이다(2 → 3).
		//   ★ A = 좌상 8x8 **팔레트 밖** 고정색(옛 것과 같은 모양) · B = **우상 12x12** 이고
		//     **목표와 같은 색**이다(같은 `ci` 로 그린다).
		//   ⚠️⚠️ 그래서 B 는 **목표를 따라 색이 변한다** ⇒ 「값이 그대로 = 방해자」가 B 를
		//     **원리적으로 못 잡는다.** 바로 아래 옛 주석이 「그건 다음 축이다」라고 적어 둔 그 자리다.
		//   ⚠️ 잉크가 셋 다 다르다: A **64** · B **144** · 목표 **100/484/1156** ⇒ 잉크가 키로 산다.
		//   ⚠️ 겹치지 않는다 — 목표의 `y` 는 늘 15 이상이고 B 는 `y < 12` 다.
		//   ★ 변주는 **없다**(한 판에 한 축) ⇒ 이 세계는 `di == 20` 하나뿐이다.
		// 🎭 **방해자가 자리도 바꾼다**(D159) — `di == 21+m` 은 **자리 축**이다.
		//   ★ 색·잉크는 `di == 20` 과 **한 톨도 안 바꾼다**(한 판에 한 축) — 오직 **x** 만 옮긴다.
		//   ⚠️ 겹치지 않게 잡았다: A 는 `0/10/20`(폭 8 ⇒ 끝 8/18/**28**) · B 는 `52/42/**32**`(폭 12)
		//     ⇒ A 의 최대 끝(28) < B 의 최소 시작(32). 그리고 **y 는 0** 이라 목표(`y >= 15`)와도 안 겹친다.
		//   ★ **무엇이 깨지나 — 짓기 전에 손으로 따졌다**: 매치 술어 `M` 은 **속성(v·i·b)만**
		//     보므로 **후보 선택은 안 바뀐다.** 깨지는 것은 ➕ 극성이 **자리(`cx16`)를 키로 삼는 자리**이고,
		//     그마저 **목표는 자리를 안 바꾸므로** 목표를 옳게 집은 후보(05·16·17)는 **멀쩡하다**.
		//   ⚠️⚠️ 그래서 진짜로 달라지는 것은 **틀리게 집었을 때**다 — 방해자의 자리를 키로 삼으면
		//     다음 프레임에 **그 자리에 아무것도 없어** `_BindRead` 가 실패하고 **에피소드가 버려진다**
		//     ⇒ 🚨 **도달률이 부풀려 보이는 선택 편향**이 생긴다. **에피소드 수**가 그 계기판이다.
		// 🎲 **상황을 섞는다**(D166 · `di = 31+q`) — 방해자 **A 가 색만** 또는 **크기만** 변한다.
		//   ★ **왜 이 축인가**: D165 심사가 *㉡ 이 막힌 이유 둘이 다 「간섭이 없다」를 가리킨다*
		//     고 확정했다. ⇒ **상황마다 옳은 키가 갈려야** 덮임이 생기고 비로소 보호가 값을 한다.
		//   ★ 규약은 D148 그대로다 — **색만 변함 ⇒ 값 키가 죽고 잉크 키가 산다** ·
		//     **크기만 변함 ⇒ 잉크 키가 죽고 값 키가 산다**.
		//   ⚠️ B(목표와 같은 색 · 12x12)와 자리는 **안 건드린다** — 한 판에 한 축이다.
		// 🧨 **안 보이는 충돌**(D180 · `di = 61+q`) — **B 가 크기만** 변한다(A 는 고정).
		//   ★ **왜 이것이 「안 보이는」가**: 관측 셋은 *성분 중에 짝이 없는 것이 있나*를 본다.
		//     A 가 크기만 변해도 B 가 크기만 변해도 **잉크가 짝을 잃는 성분이 하나**이고
		//     값(색)과 자리는 **둘 다 그대로**다 ⇒ 서명이 `[oVC=0 oIC=1 oPC=0]` 으로 **완전히 같다**.
		//   ⚠️ 그래서 **B 의 x 를 `kSize - 12` 로 못 박는다** — 오른쪽 끝을 맞추면 `cx16` 이 움직여
		//     `oPC` 가 갈리고 그러면 **더는 안 보이는 충돌이 아니다**.
		//   ⇒ ★ 그런데 **옳은 후보는 다르다** — A 는 제 색이고 **B 는 목표와 같은 색**이다.
		if (di >= 61)
		{
			const int ds2 = ((di - 61) / 3) % 3;
			o.AppendFormat("    Draw::Color(%d, %d, %d)\n"
				"    Draw::RectFill(0, 0, 6, 6)\n", kDistR[0], kDistG[0], kDistB[0]);
			o.AppendFormat("    Draw::Color(%d, %d, %d)\n"
				"    Draw::RectFill(%d, 0, %d, %d)\n",
				c.r, c.g, c.b, kSize - 12, kDistS[ds2], kDistS[ds2]);
		}
		else if (di >= 31)
		{
			const int dq = di - 31;
			const int dk = dq % 3;            // 🎨 색 변주(0 이면 고정)
			const int ds = (dq / 3) % 3;      // 📏 크기 변주(0 이면 고정 6px)
			const int dp = (dq / 9) % 3;      // 📍 **자리 변주**(D179 · 0 이면 x=0 고정)
			o.AppendFormat("    Draw::Color(%d, %d, %d)\n"
				"    Draw::RectFill(%d, 0, %d, %d)\n",
				kDistR[dk], kDistG[dk], kDistB[dk], kDistX[dp], kDistS[ds], kDistS[ds]);
			o.AppendFormat("    Draw::Color(%d, %d, %d)\n"
				"    Draw::RectFill(%d, 0, 12, 12)\n", c.r, c.g, c.b, kSize - 12);
		}
		else if (di >= 21)
		{
			static const int kAX[3] = { 0, 10, 20 };
			const int m = (di - 21) % 3;
			o.AppendFormat("    Draw::Color(160, 120, 60)\n"
				"    Draw::RectFill(%d, 0, 8, 8)\n", kAX[m]);
			o.AppendFormat("    Draw::Color(%d, %d, %d)\n"
				"    Draw::RectFill(%d, 0, 12, 12)\n", c.r, c.g, c.b, kSize - 12 - 10 * m);
		}
		else if (di >= 20)
		{
			o.AppendFormat("    Draw::Color(160, 120, 60)\n"
				"    Draw::RectFill(0, 0, 8, 8)\n");
			o.AppendFormat("    Draw::Color(%d, %d, %d)\n"
				"    Draw::RectFill(%d, 0, 12, 12)\n", c.r, c.g, c.b, kSize - 12);
		}
		else
		if (di != 0)
		{
			static const int kDR[3] = { 160,  60, 120 };
			static const int kDG[3] = { 120, 160,  60 };
			static const int kDB[3] = {  60, 120, 160 };
			// 🎨 `di - 2` 를 **색 3 x 크기 3** 으로 푼다: `c + 3*s`.
			//   ★ 크기 변주 잉크는 **36 / 64 / 144**(6·8·12 px) — ⚠️ 목표 잉크 {100, 484, 1156} 과
			//     **하나도 겹치지 않는다**(겹치면 잉크가 키가 될 수 없고 판정이 흐려진다).
			//   ⚠️ 12px 도 목표를 안 가린다 — 목표의 `y` 는 늘 15 이상이다.
			//   ⚠️⚠️ `di == 1`(고정)은 **크기 8** 이다 ⇒ 옛 팔의 재현이 성립한다.
			static const int kDS[3] = { 6, 8, 12 };
			const int dq = (di >= 2) ? (di - 2) : 0;
			const int dk = dq % 3;
			const int ds = (di >= 2) ? ((dq / 3) % 3) : 1;
			o.AppendFormat("    Draw::Color(%d, %d, %d)\n"
				"    Draw::RectFill(0, 0, %d, %d)\n", kDR[dk], kDG[dk], kDB[dk], kDS[ds], kDS[ds]);
		}
		o.AppendFormat("    Draw::Color(%d, %d, %d)\n", c.r, c.g, c.b);
		if (ti == 1)
			// ⬜ **테두리만** — 잉크가 훨씬 적다(`4s−4`) ⇒ 잉크·히스토그램 특징이 딴말을 한다.
			o.AppendFormat("    Draw::Rect(%d, %d, %d, %d)\n}\n", x, y, s, s);
		else if (ti == 2)
			// ⚪ **찬 동그라미** — 격자/프로파일 분포가 다르다(잉크는 `πs²/4`).
			o.AppendFormat("    Draw::CircleFill(%d, %d, %d)\n}\n", cxs, kSize / 2, s / 2);
		else
			o.AppendFormat("    Draw::RectFill(%d, %d, %d, %d)\n}\n", x, y, s, s);
		return o;
	}

	// 🗣️ 그 과제를 **말로** — 커리큘럼과 같은 낱말을 쓴다(목표를 말로 주는 칸의 재료).
	static String TaskCaption(int ci, int xi, int si, int ti = 0)
	{
		const MLPalette& c = Palette(ci);
		const int s = Px(20) + si * Px(24);
		const int cxs = kSize / 2 + (xi - 1) * Px(30);        // 중심 x: 17 · 32 · 47
	const int x = cxs - s / 2;                            // ★ 크기와 **무관**하다
		// 🎭 유형마다 낱말이 다르다 — 「빈/찬」과 「원」은 **이미 쓰는 어휘**다.
		const char* sh = (ti == 1) ? "빈 네모" : ((ti == 2) ? "원" : "네모");
		return CapHead((ti == 2) ? (kSize / 2 + (xi - 1) * Px(30)) : (x + s / 2),
			kSize / 2, s, c, sh)
			+ String(" 속까지 채워져 있다. 그대로 있다.");
	}
};

// ── 🧿 감각 어휘 — 축 하나만 흔드는 **최소대립쌍** ────────────────────────────────────
//
// ★ **접지는 대조에서 온다.** `작은 원` 그림 하나는 아무것도 가르치지 않는다 — `작은` 이 크기인지
//   색인지 자리인지 그 그림만으로는 좁혀지지 않는다. 좁히는 것은 **변화**다:
//     **한 축만 흔들고 나머지를 고정한다 → 그때 바뀌는 낱말이 그 축의 이름이다.**
//
// ★ **캡션이 완전 평행 구조**다 — `{자리}에 {크기} {색} {속} {모양} {개수} 있다`.
//   그래서 **각 축이 정확히 한 낱말**이고, 그것이 최소대립쌍의 전제다.
//   ★ 그리고 같은 모양이 **경계망에도 이득**이다: 공유 부분이 최대로 반복되고 목표 낱말만 고립되므로
//     엔트로피 경계가 **낱말 자리에서** 뚜렷해진다(두 목적이 같은 데이터를 원한다).
//
// ⚠️⚠️ **어휘 감사** — 여기 쓰이는 모든 내용어는 아래 `MLScene` 의 **필드 하나**에 대응한다.
//   대응이 없는 낱말은 **매달린 기호**이고 버그다(`맛있다` 가 그 예다 → ML.md 의 접지 폐쇄 절).
//   ★ 필드를 늘리지 않고 낱말을 늘리면 그 즉시 감사가 깨진다 — 그것이 이 구조의 요점이다.

// 🧿 축 — 흔들 수 있는 것의 목록. ⚠️ **낱말 목록과 1:1** 이어야 한다(감사).
enum class MLAxis
{
	Count,   // ① 하나/둘/셋/넷/다섯/여럿
	Shape,   // ② 동그라미/네모
	Color,   // ③ 붉은/노란/푸른/초록/하얀
	Size,    // ④ 작은/큰
	Pos,     // ⑤ 왼쪽/오른쪽/위/아래/가운데
	Fill,    // ⑥ 빈/찬
};

// 🎬 장면 하나 — **이것이 곧 어휘의 정의다**(필드 하나 = 낱말 한 무리).
struct MLScene
{
	int count = 1;      // 1..6(6 = "여럿")
	int shape = 0;      // 0 = 동그라미 · 1 = 네모
	int color = 0;      // 팔레트 index
	int big = 0;        // 0 = 작은 · 1 = 큰
	int pos = 4;        // 0 왼쪽 · 1 오른쪽 · 2 위 · 3 아래 · 4 가운데
	int filled = 1;     // 0 = 빈 · 1 = 찬
	// 🌍 **간격 — 생명주기 실험 전용 축**(0 = 붙음 · 1 = 보통 · 2 = 넓음).
	//
	// ★ **왜 이것이 생겼나**(50차 · 함정 115): 이 세계는 `Extent` 의 `step` 이 크기에 비례해
	//   커져서 **덩어리가 절대 안 붙는다** ⇒ `덩어리 수` 가 사실상 `개수` 의 **대리 변수**였고,
	//   그래서 *"사실마다 지배하는 채널이 하나"* 라는 **쉬운 구조**가 공짜로 주어졌다.
	//   ⇒ 그 위에서 얻은 *"조합 문맥은 값을 안 한다"*(49차)는 **거의 생성기 명세**였다.
	// ⚠️⚠️ **그 큰 `step` 은 일부러 넣은 것이다** — 캡션의 `넷이` 가 거짓이 되는 것을 막으려고
	//   (`Extent` 의 그 ⚠️⚠️ 주석). ⇒ 그래서 **기본값 `1` 이 옛 동작 그대로**이고,
	//   `BaseScene` 은 이 값을 **건드리지 않는다** ⇒ **캡션 경로는 한 픽셀도 안 바뀐다.**
	// ★ 흔드는 것은 `MLLife` 뿐이다(그 실험은 캡션도 가중치도 안 쓰는 독립 트랙이다).
	//   ⇒ **두 세계가 갈린다**(생명주기 세계 ≠ 캡션 세계). 그것을 알고 고른 대가다.
	int gap = 1;

	// ★ **존재는 축이 아니라 전제다.**
	//   ⚠️⚠️ 다른 여섯 축과 **같은 급이 아니다** — 없으면 모양·색·개수가 통째로 사라지므로
	//     **최소대립쌍이 성립하지 않는다**(한 낱말만 다르게 만들 수가 없다).
	//   ⇒ 그래서 `MLAxis` 에 넣지 않고 여기 따로 둔다. 대립쌍 기계는 `exists = 1` 만 쓴다.
	//   ★ **그런데 이것이 없으면 `있다` 는 판별력이 0 이다** — 모든 캡션에 나오고 반대말이 없으니까.
	//     실측으로 그것을 밟았다: 교차채널이 `있`·`다` 를 접지 못했고 나는 그것을
	//     *"시각 내용이 없는 낱말"* 이라 불렀는데, 실은 **대조가 없어서** 그랬다.
	//     ⇒ `없다` + **빈 프레임**을 넣으면 `있다/없다` 가 진짜 대조를 얻는다 —
	//       데이터 트릭이 아니라 **구조 수정**이고, 가장 원시적인 접지다(있나 없나).
	int exists = 1;     // 0 = 아무것도 없다(빈 프레임) · 1 = 있다

	// ★ **이동도 존재와 같은 꼴이다: 먼저 이진 대조, 그 다음 속성.**
	//   `간다`/`안간다` 를 먼저 가르치고, 그 다음 `왼쪽 간다`/`오른쪽 간다` 로 방향을 붙인다.
	//   ⚠️ `moves == 0` 이면 방향은 **해당없음**이다(안 가는데 왼쪽으로 안 간다고 말할 수 없다).
	//   ★ **그리고 델타가 이 대조를 이미 준다**: `안간다` = 델타 프레임이 **전부 0** ·
	//     `간다` = **0 아닌** 델타. 비용 때문에 만든 표현이 시간 인과의 가장 원시적인 대조를 그대로 낸다
	//     (→ `PackRGB332Delta`). ⇒ 이 축의 **접지가 공짜로 붙는다.**
	int moves = 0;      // 0 = 안 간다 · 1 = 간다
	int moveDir = 0;    // 0 왼쪽 · 1 오른쪽 · 2 위 · 3 아래  (⚠️ moves == 1 일 때만 뜻이 있다)

	// ★ **이동 횟수 — `2 번 갔다`.** ⚠️ `moves == 1` 일 때만 뜻이 있다.
	//   ★ 왜 넣나: **`개` 에 대조를 주려고**. 셈낱말이 `개` 하나뿐이면 *"어느 축의 셈낱말인가"* 를
	//     구별할 것이 없다(`있다` 가 반대말이 없어 안 배워졌던 것과 **같은 구조** · 함정 25).
	//     `개`(물체 수) ↔ `번`(횟수) 가 짝이 되면 비로소 셈낱말이 뜻을 가진다.
	//   ⚠️ 그리고 **프레임 수가 곧 횟수다** — 소비자가 `OnFrame` 을 그만큼 호출한다(코드는 그대로).
	int moveSteps = 1;  // 1..4
};

class MLSense
{
public:
	// ⚠️ `MLEpisodeGen::kSize` 와 **같아야** 한다(같은 캔버스를 말한다).
	static constexpr int kSize = MLEpisodeGen::kSize;

	// ── 낱말표 — ⚠️ 각 함수가 `MLScene` 의 필드 **하나**만 본다(그것이 감사다) ──
	// ⚠️⚠️⚠️ **조사를 낱말 표에서 뗐다 — 붙여 두면 측정이 거짓말을 한다.**
	//   예전엔 `"하나가"`·`"셋이"` 처럼 **조사가 표 안에** 있었고, 정답 경계를 템플릿의 공백으로 정의했으니
	//   `하나가` 가 **한 낱말**이었다. 그런데 교차채널 모델이 `하나|가` 로 쪼개면(형태소로는 **맞는데**)
	//   그것이 **오답으로 세어졌다** — P4′ 의 가장 흔한 헛경계 둘(`아래|에`·`하나|가`)이 실은 정답이었고
	//   정밀도 0.669 가 그만큼 부당하게 깎였다.
	//   ★ 이 프로젝트 목적으로는 **형태소 경계가 맞는 정답**이다: `아래` 는 자리 축에 접지되고
	//     `에` 는 아무 시각 사실도 가리키지 않으므로, 경계는 정확히 그 자리다.
	// ★ **개수를 아라비아 숫자로 쓴다 — 숫자를 "체계" 로 배우게.**
	//   ⚠️⚠️ `하나`·`둘`·`셋` 은 서로 **구조가 없는 임의 기호**다: `둘` 을 배워도 `셋` 에 도움이 안 되고,
	//     여섯 개를 **따로따로** 외워야 한다. `1`·`2`·`3` 은 **순서가 있는 체계**이고 나중에
	//     `10`·`12` 로 **조합**된다 ⇒ 같은 노출로 훨씬 멀리 간다.
	//   ★ 부수 이득이 둘 더 있다:
	//     ① 숫자는 **1바이트(ASCII)** 다 — 한글 음절(3바이트)과 **값의 종류가 다르다**.
	//        같은 텍스트 채널 안에 서로 다른 값 종류가 섞이는 것이고, 그것 자체가 시험거리다.
	//     ② 그래서 **경계 후보에도 자연히 걸린다**(선두 바이트다).
	//   ⚠️ 6 이상은 여전히 `여럿` 이다 — *"많다"* 는 개수가 아니라 **판단**이고, 숫자로 쓰면
	//     세지 않은 것을 센 것처럼 거짓말하게 된다.
	static const char* WordCount(int n)
	{
		if (n <= 1) return "1";
		if (n == 2) return "2";
		if (n == 3) return "3";
		if (n == 4) return "4";
		if (n == 5) return "5";
		return "여럿";
	}
	// 수량 구 — `3개`. ★ 셈낱말(`개`)이 붙는 형태이고, 1칸 단독은 **숫자만**(`3.`) 준다.
	//   ⇒ *"숫자 자체"* 와 *"숫자 + 셈낱말"* 을 갈라 가르친다(사다리).
	static String WordCountPhrase(int n)
	{
		if (n >= 6) return String("여럿");
		return Format("%s개", WordCount(n));
	}
	// 수량 구 뒤 주격 조사. ⚠️ 받침에 따라 정해진다 — `3개`+가 · `여럿`+이. **음운으로 결정**되므로
	//   마음대로 흔들면 비문이 된다. ★ 흔들 수 있는 것은 *"조사를 쓰나 마나"* 와 `도` 같은 보조사다.
	static const char* WordCountPart(int n) { return (n >= 6) ? "이" : "가"; }
	static const char* WordShape(int s) { return (s == 0) ? "동그라미" : "네모"; }
	static const char* WordSize(int b)  { return (b == 0) ? "작은" : "큰"; }
	static const char* WordFill(int f)  { return (f == 0) ? "빈" : "찬"; }
	static const char* WordPos(int p)
	{
		if (p == 0) return "왼쪽";
		if (p == 1) return "오른쪽";
		if (p == 2) return "위";
		if (p == 3) return "아래";
		return "가운데";
	}
	static const char* WordColor(int c) { return MLEpisodeGen::Palette(c).name; }
	static const char* WordMove(int m)  { return (m == 0) ? "안간다" : "간다"; }
	// 과거·수동은 어렵다(`한 번 옮겨졌다`) ⇒ **`2 번 갔다`** 처럼 **숫자 + 셈낱말 + 동사**로 쓴다.
	static const char* WordWent()       { return "갔다"; }
	// 방향 낱말 — ★ **자리 낱말과 같은 것을 쓴다**(`왼쪽`·`오른쪽`·`위`·`아래`).
	//   ⚠️ 일부러 그렇게 한다: 같은 낱말이 **정적인 자리**와 **움직이는 방향** 둘에 쓰이면
	//     모델이 그 낱말을 *"공간의 한쪽"* 이라는 하나의 뜻으로 묶어야 한다 — 그것이 재조합의 시험이다.
	static const char* WordDir(int d)
	{
		if (d == 0) return "왼쪽";
		if (d == 1) return "오른쪽";
		if (d == 2) return "위";
		return "아래";
	}

	// 한 프레임에 옮기는 픽셀 수. ★ 어휘가 아니라 상수다(`kStroke` 와 같은 성격).
	//   ⚠️ 델타가 **0 이 아니게** 충분히 커야 한다 — 1픽셀이면 RGB332 로 깎인 뒤 안 보일 수 있다.
	static constexpr int kStep = 4;

	// 축 이름(로그/감사용). ⚠️ 낱말이 아니라 **축의 이름**이다 — 캡션에는 안 들어간다.
	static const char* AxisName(MLAxis a)
	{
		if (a == MLAxis::Count) return "개수";
		if (a == MLAxis::Shape) return "모양";
		if (a == MLAxis::Color) return "색";
		if (a == MLAxis::Size)  return "크기";
		if (a == MLAxis::Pos)   return "자리";
		return "속";
	}
	static int AxisCount() { return 6; }
	static MLAxis AxisAt(int i)
	{
		if (i == 0) return MLAxis::Count;
		if (i == 1) return MLAxis::Shape;
		if (i == 2) return MLAxis::Color;
		if (i == 3) return MLAxis::Size;
		if (i == 4) return MLAxis::Pos;
		return MLAxis::Fill;
	}

	// 📏 장면 → 픽셀 자리. ⚠️ **결정적**이어야 한다(같은 장면이 같은 그림).
	// ★ **작은 반지름의 하한은 `빈/찬` 축이 정한다.** `kStroke = 2` 인 테두리는 `r±1` 을 칠하므로
	//   속으로 남는 것이 반지름 `r-1` 짜리 원이다. `r = 3` 이면 속이 5픽셀도 안 되어 **빈 것과 찬 것이
	//   같은 그림**이 된다(그러면 `빈` 이라는 낱말이 가리킬 것이 없다 = 매달린 기호).
	//   ⇒ 64² 에서 `4`. 그리고 큰 것은 `7` — 판독기가 보는 bbox 가 `15 vs 9` 로 갈린다.
	//   ⚠️ 여기를 키우면 **큰 도형 여러 개가 캔버스를 넘는다** → 넘는 것은 `Fits` 가 거절한다(조용히 안 접는다).
	static int Radius(const MLScene& s) { return (s.big != 0) ? 7 : 4; }

	// 📐 군집의 크기 — 칸 수·간격·바깥 끝·반폭/반높이.
	//   ★ **`Center`/`Fits`/`SlotAt` 이 이 한 함수를 본다.** 셋이 따로 계산하면 조용히 어긋나고,
	//     그 어긋남은 "도형이 붙었다"/"캡션이 거짓" 으로 나타나 원인과 안 닮는다.
	static void Extent(const MLScene& s, int& cols, int& rows, int& step, int& outer,
		int& halfW, int& halfH)
	{
		const int r = Radius(s);
		// ⚠️⚠️ **간격은 `r` 이 아니라 "바깥 끝" 으로 잡는다.** 빈 도형은 테두리를 `r` **가운데** 두고
		//   양쪽으로 `thickness/2` 씩 퍼지므로 바깥 반지름이 `r + 1` 이다(`kStroke = 2`).
		//   ★ 실측으로 밟았다: `2*r + 4` 로 두니 **빈 동그라미 넷이 두 덩어리로 붙었고**, 그래서
		//     캡션의 `넷이` 가 거짓이 됐다(판독기가 그것을 잡았다 — 캡션 감사는 못 잡는다).
		outer = r + 2;                       // 바깥 끝(+1 여유)
		// 🌍 **간격이 `step` 을 정한다** — `1` 이 옛 값(`2*outer + 4`)이라 기본 동작이 불변이다.
		//   ★ `0`(붙음)은 지름(`2*outer`)보다 `step` 이 **작아** 덩어리가 실제로 **병합된다**
		//     ⇒ `덩어리 수`·`잉크 면적` 이 `(개수, 크기, 모양, 속)` 의 **결합 함수**가 된다.
		//     그것이 이 축을 넣은 목적이다(상호작용을 **기하에서** 만든다 — 손으로 만든 라벨이 아니다).
		const int gapPad = (s.gap == 0) ? -2 : ((s.gap == 2) ? 14 : 4);
		step  = 2 * outer + gapPad;
		cols = 1;
		if (s.count >= 2) cols = 2;
		if (s.count >= 5) cols = 3;
		rows  = (s.count + cols - 1) / cols;
		halfW = (int)((float)(cols - 1) * 0.5f * (float)step) + outer;
		halfH = (int)((float)(rows - 1) * 0.5f * (float)step) + outer;
	}

	// 📍 군집의 중심.
	// ★ **`자리` 낱말은 "그 쪽으로 들어가는 만큼 민 것"** 이다.
	//   ⚠️⚠️ 예전에는 `kSize/4` 같은 **고정 좌표**를 쓰고 넘치면 중심을 접었다. 그 접기가
	//     세 자리를 몇 픽셀 차로 뭉갰다 — 128² · 큰 도형 다섯 개에서 왼쪽/가운데/오른쪽이
	//     **56 / 64 / 71** 이었다. 판독기가 bbox 중심을 읽으면 **셋 다 "가운데"** 이므로
	//     `왼쪽` 이라는 낱말이 거짓이다. 그리고 **대립쌍 감사는 이것을 못 잡는다**(낱말은 잘 달랐다).
	//   ⇒ 자리를 **의도**로 적고, 그 의도가 성립하지 않는 장면은 `Fits` 가 **거절**한다.
	//     ★ 접는 것보다 거절하는 것이 맞다 — 접기는 데이터를 조용히 거짓으로 만들고, 거절은 시끄럽다.
	static void Center(const MLScene& s, int& cx, int& cy)
	{
		int cols = 0, rows = 0, step = 0, outer = 0, halfW = 0, halfH = 0;
		Extent(s, cols, rows, step, outer, halfW, halfH);
		cx = kSize / 2; cy = kSize / 2;
		if (s.pos == 0)      cx = halfW + 1;
		else if (s.pos == 1) cx = kSize - 2 - halfW;
		else if (s.pos == 2) cy = halfH + 1;
		else if (s.pos == 3) cy = kSize - 2 - halfH;
	}

	// ✅ **그 장면이 자기 캡션을 정직하게 입을 수 있나.**
	//   ㉠ 군집이 캔버스 안에 들어간다(도형이 잘리면 개수 낱말부터 거짓이 된다)
	//   ㉡ ★ **`자리` 낱말이 판독으로 되짚어진다** — 그림에서 bbox 중심을 재서 `MLEpisodeGen::WordH`/
	//      `WordV` 에 넣으면 **캡션이 쓴 그 낱말이 다시 나와야** 한다.
	//      ★ 그래서 경계 숫자(삼분할)는 낱말 함수 안에만 있고 여기에는 없다 — 두 곳에 두면 어긋난다.
	//      ★ 낱말도 `WordPos` 에서 가져온다(캡션이 쓰는 그 함수) ⇒ 이 검사는 곧
	//        **"캡션이 판독을 통과하는가"** 이고, 그것이 접지의 정의다.
	static bool Fits(const MLScene& s)
	{
		if (s.exists == 0) return true;   // 아무것도 안 그리므로 늘 들어간다
		int cols = 0, rows = 0, step = 0, outer = 0, halfW = 0, halfH = 0;
		Extent(s, cols, rows, step, outer, halfW, halfH);
		int cx = 0, cy = 0;
		Center(s, cx, cy);
		if (cx - halfW < 1 || cx + halfW > kSize - 2) return false;
		if (cy - halfH < 1 || cy + halfH > kSize - 2) return false;

		// 군집 중심 = 판독기가 잴 bbox 중심(격자가 가운데 정렬이므로 같다).
		const bool horiz = (s.pos == 0 || s.pos == 1);
		const char* want = (s.pos == 4) ? nullptr : WordPos(s.pos);
		if (!_SameWord(MLEpisodeGen::WordH(cx), horiz ? want : nullptr)) return false;
		if (!_SameWord(MLEpisodeGen::WordV(cy), horiz ? nullptr : want)) return false;
		return true;
	}

	// 낱말 두 개가 같은가(둘 다 없으면 같다). ⚠️ 손으로 훑는다 — `.cw` 라 `<cstring>` 을 안 끌어온다.
	static bool _SameWord(const char* a, const char* b)
	{
		if (a == nullptr || b == nullptr) return a == b;
		for (uint32 i = 0; ; ++i)
		{
			if (a[i] != b[i]) return false;
			if (a[i] == 0) return true;
		}
	}

	// 🧱 여러 개를 **결정적 격자**로 놓는다. ★ 세로/가로 칸 수를 개수에서 정한다(같은 개수 = 같은 배치).
	//   ⚠️ 간격을 반지름에서 뽑아 **겹치지 않게** 한다 — 겹치면 사람도 개수를 못 세고,
	//     그러면 `셋이` 라는 낱말이 그림과 안 맞는다(캡션이 거짓이 된다).
	static void SlotAt(const MLScene& s, int i, int& x, int& y)
	{
		int cols = 0, rows = 0, step = 0, outer = 0, halfW = 0, halfH = 0;
		Extent(s, cols, rows, step, outer, halfW, halfH);
		int cx = 0, cy = 0;
		Center(s, cx, cy);
		const int col = i % cols, row = i / cols;
		// 가로/세로 모두 가운데 정렬 — 격자의 **중심**이 `Center` 에 오게 한다.
		//   ★ 그래야 개수가 바뀌어도 `자리` 낱말이 계속 맞는다(개수 축을 흔들 때 자리가 따라 흔들리면
		//     그것은 최소대립쌍이 아니다 — 두 축이 같이 움직인 것이다).
		// ⚠️⚠️ **괄호를 `step` 까지 감싼다.** 예전엔 `(int)(... 0.5f) * step` 이었는데 캐스팅이 `* step`
		//   **보다 먼저** 묶여 `(int)(-0.5f) = 0` 이 되었고, 그래서 **모든 도형이 같은 자리에 겹쳤다**.
		//   ★ 증상이 무서웠다: 캡션은 `셋이` 라고 말하는데 그림에는 하나만 있었다 — **캡션이 거짓이 되는**
		//     종류의 버그이고, 캡션 감사(낱말 하나만 다른가)는 그것을 **잡지 못한다**.
		x = cx + (int)(((float)col - (float)(cols - 1) * 0.5f) * (float)step);
		y = cy + (int)(((float)row - (float)(rows - 1) * 0.5f) * (float)step);
		// ★ 접기가 **없다** — 캔버스를 넘는 장면은 `Fits` 가 애초에 거절했다.
		//   ⚠️ 그래서 `Fits` 를 안 통과한 장면을 여기 넣으면 도형이 잘린다(호출부의 책임).
	}

	// 📝 캡션 — **완전 평행 구조**. 각 낱말이 축 하나에 대응한다.
	//   ★ 이것이 **전체 문장 형태**이고 최소대립쌍 감사가 쓰는 정본이다(모든 축이 한 번씩 나온다).
	//   ⚠️ 조사가 **따로 떨어진 낱말**이고 끝에 **종결 부호**가 붙는다(아래 `CaptionVar` 의 근거).
	static String Caption(const MLScene& s)
	{
		return Format("%s 에 %s %s %s %s %s %s 있다.",
			WordPos(s.pos), WordSize(s.big), WordColor(s.color), WordFill(s.filled),
			WordShape(s.shape), WordCountPhrase(s.count).ptr(), WordCountPart(s.count));
	}

	// 축마다 값이 몇 가지인가(단독 노출을 고르게 돌리려고).
	static uint32 AxisClassCount(int axis)
	{
		const MLAxis a = AxisAt(axis);
		if (a == MLAxis::Count) return 6u;
		if (a == MLAxis::Color) return (uint32)MLEpisodeGen::PaletteCount();
		if (a == MLAxis::Pos)   return 5u;
		return 2u;
	}
	static void SetAxis(MLScene& s, int axis, int value)
	{
		const MLAxis a = AxisAt(axis);
		if (a == MLAxis::Count)      s.count = value + 1;
		else if (a == MLAxis::Shape) s.shape = value;
		else if (a == MLAxis::Color) s.color = value;
		else if (a == MLAxis::Size)  s.big = value;
		else if (a == MLAxis::Pos)   s.pos = value;
		else                         s.filled = value;
	}

	// ── 낱말 축 코드 ────────────────────────────────────────────────────────
	//   `0..5` = 외양 축(개수·모양·색·크기·자리·속) · `6` = 이동 · `7` = 방향
	//   `8` = **존재** — ★ `있다`/`없다` 는 이제 **축을 말하는 내용어**다(자가 커리큘럼 1차 조치)
	//   `kWFunc(-1)` = **기능어**(조사·셈낱말·종결) — 시각 값을 하나도 안 가리킨다
	//   ⚠️ `8 /*존재*/(-2)` 는 **더 안 쓴다** — 존재가 축이 되었으므로 `8` 로 라벨한다.
	// ★ **왜 낱말 단위인가**: 음절 단위 정답은 **원리적으로 불가능**하다 —
	//   `다` 는 `있다`·`간다`·`안간다` 에 다 나오고 `하` 는 `1`… 아니 `하얀`·`하나` 에 나온다.
	//   ⇒ 같은 음절이 역할이 다르므로 **낱말이 라벨의 단위**여야 한다(그리고 그 사실 자체가
	//     이 실험이 밝힌 것이다 — 음절만으로는 안 된다).
	static constexpr int kWFunc = -1;

	// 낱말 하나를 캡션에 붙이면서 그 낱말의 축을 기록한다.
	static void AddWord(String& cap, Array<int>& wax, bool& first, const char* w, int ax)
	{
		if (!first) cap.AppendFormat(" ");
		cap.AppendFormat("%s", w);
		wax.Add(ax);
		first = false;
	}

	// 🎓 **수업 하나 = (장면, 캡션) 한 쌍.** ★ 둘을 **함께** 골라야 커리큘럼이 된다.
	//
	// ★ **낱말마다 고르게 단독 노출을 준다** — `왼쪽`·`오른쪽`·`위`·`아래`·`가운데` 를
	//   **다 따로** 가르쳐야 한다(애기처럼). ⚠️ 장면을 무작위로 뽑고 그 값을 말하게 하면
	//   `가운데` 는 드물게 나온다 ⇒ **축과 값을 인덱스로 돌려** 균등하게 만든다.
	//
	// ★ 비중(사다리): **없다 1/12 · 1칸 단독 6/12 · 2칸 두 낱말 3/12 · 3칸 문장 2/12.**
	//   ⚠️ 사전학습이 0 이므로 **아래 칸이 두꺼워야** 한다 — 위 칸은 아래 칸을 딛는 것이다.
	static void MakeLesson(uint32 idx, MLScene& outScene, String& outCap, Array<int>& outWordAxis)
	{
		const uint32 slot = idx % 16u;
		const char* end = ((idx / 5u) % 2u == 0u) ? "." : "!";

		// ⚠️ 배경 장면은 **씨앗에서** 뽑되, 아래에서 목표 축만 덮어쓴다(다른 축은 계속 흔들린다).
		MLScene sc = BaseScene(idx * 7919u + 17u);
		// ★ **이동을 캡션 형태와 독립으로 둔다 — 가짜 상관을 막는다**(함정 28).
		//   ⚠️⚠️ 처음엔 *"이동 칸에서만 켠다"* 로 뒀는데, 그러면 **외양 칸은 항상 안 간다** ⇒
		//     `있`·`작은`·`개`·`에` 같은 외양 낱말이 *"이동 = 안간다"* 를 **100% 예측**해서
		//     `이동` 축이 **쓰레기통**이 됐다. ⇒ 물체가 움직이는데 캡션은 **색만 말할 수도** 있어야 한다.
		sc.moves = (int)((idx / 16u) % 2u);
		sc.moveDir = (int)((idx / 32u) % 4u);
		// ⚠️ **횟수도 캡션 형태와 독립**이어야 한다(함정 28) — 축을 추가할 때마다 다시 묻는다.
		sc.moveSteps = (int)((idx / 128u) % 4u) + 1;

		String cap;
		Array<int> wax;
		bool first = true;

		if (slot == 0u)
		{
			sc.exists = 0;
			AddWord(cap, wax, first, "없다", 8 /*존재*/);
			cap.AppendFormat("%s", end);
			outScene = sc; outCap = cap; outWordAxis = wax;
			return;
		}
		sc.exists = 1;

		// 🎞️ **이동 1칸 — 이진 대조.** `간다` / `안간다`.
		if (slot <= 2u)
		{
			sc.moves = (int)(slot - 1u);
			AddWord(cap, wax, first, WordMove(sc.moves), 6);
		}
		// 🎞️ **이동 2칸 — 방향이 붙는다.** `왼쪽 간다.`
		else if (slot <= 4u)
		{
			sc.moves = 1;
			AddWord(cap, wax, first, WordDir(sc.moveDir), 7);
			AddWord(cap, wax, first, WordMove(1), 6);
		}
		// 🎞️ **이동 3칸 — 주어가 붙는다.** `동그라미 왼쪽 간다.`
		else if (slot == 5u)
		{
			sc.moves = 1;
			AddWord(cap, wax, first, WordShape(sc.shape), 1);
			AddWord(cap, wax, first, WordDir(sc.moveDir), 7);
			AddWord(cap, wax, first, WordMove(1), 6);
		}
		// 🔢 **횟수 — `2 번 갔다`.** ★ `개`(물체 수) 와 `번`(횟수) 가 여기서 **짝**이 된다.
		//   ⚠️ 과거·수동(`한 번 옮겨졌다`)은 어렵다 ⇒ **숫자 + 셈낱말 + 동사**로 쓴다.
		else if (slot == 6u)
		{
			sc.moves = 1;
			AddWord(cap, wax, first, WordCount(sc.moveSteps), 9);   // 숫자 = 이동횟수 축의 값
			AddWord(cap, wax, first, "번", kWFunc);                 // 셈낱말 = 기능어
			AddWord(cap, wax, first, WordWent(), 6);                // 갔다 = 이동
		}
		// 1칸 — 단독. ★ 축과 값을 **인덱스로 돌려** 모든 낱말이 고르게 나온다.
		else if (slot <= 10u)
		{
			if (((idx / 13u) % 6u) == 0u) AddWord(cap, wax, first, "있다", 8 /*존재*/);
			else
			{
				const int ax = (int)((idx / 12u) % 6u);
				const int val = (int)((idx / 72u) % AxisClassCount(ax));
				SetAxis(sc, ax, val);
				// ⚠️ 덮어쓰면 캔버스에 안 들어갈 수 있다 → **그 축 값은 고정한 채** 나머지를 다시 뽑는다.
				for (uint32 t = 0; t < 64u && !Fits(sc); ++t)
				{
					const MLScene bg = BaseScene(idx * 7919u + 17u + t * 104729u);
					const int mv = sc.moves, md = sc.moveDir;
					sc = bg; sc.exists = 1; sc.moves = mv; sc.moveDir = md;
					SetAxis(sc, ax, val);
				}
				AddWord(cap, wax, first, WordOfAxis(sc, ax), ax);
			}
		}
		// 2칸 — 두 낱말. ★ 여기서 **재조합**이 처음 생긴다.
		else if (slot <= 13u)
		{
			const uint32 k = (idx / 11u) % 4u;
			if (k == 0u)
			{
				AddWord(cap, wax, first, WordColor(sc.color), 2);
				AddWord(cap, wax, first, WordShape(sc.shape), 1);
			}
			else if (k == 1u)
			{
				AddWord(cap, wax, first, WordShape(sc.shape), 1);
				AddCount(cap, wax, first, sc.count);
			}
			else if (k == 2u)
			{
				AddWord(cap, wax, first, WordSize(sc.big), 3);
				AddWord(cap, wax, first, WordShape(sc.shape), 1);
			}
			else
			{
				AddWord(cap, wax, first, WordShape(sc.shape), 1);
				AddWord(cap, wax, first, "있다", 8 /*존재*/);
			}
		}
		// 3칸 — 전체 문장. 조사를 흔든다(⚠️ 음운으로 정해지는 이/가는 안 흔든다).
		else
		{
			const uint32 pp = (idx / 7u) % 3u;
			const uint32 cp = (idx / 11u) % 3u;
			AddWord(cap, wax, first, WordPos(sc.pos), 4);
			if (pp == 0u)      AddWord(cap, wax, first, "에", kWFunc);
			else if (pp == 1u) AddWord(cap, wax, first, "에는", kWFunc);
			AddWord(cap, wax, first, WordSize(sc.big), 3);
			AddWord(cap, wax, first, WordColor(sc.color), 2);
			AddWord(cap, wax, first, WordFill(sc.filled), 5);
			AddWord(cap, wax, first, WordShape(sc.shape), 1);
			AddCount(cap, wax, first, sc.count);
			if (cp == 0u)      AddWord(cap, wax, first, WordCountPart(sc.count), kWFunc);
			else if (cp == 1u) AddWord(cap, wax, first, "도", kWFunc);
			AddWord(cap, wax, first, "있다", 8 /*존재*/);
		}

		cap.AppendFormat("%s", end);
		outScene = sc; outCap = cap; outWordAxis = wax;
	}

	// 수량 표현 — ★ **`3 개` 로 띄운다.** 숫자는 개수 축의 값이고 `개` 는 **셈낱말(기능어)** 이라
	//   역할이 다르다. ⚠️ 붙여 쓰면 한 낱말 안에 내용어와 기능어가 섞여 라벨이 오염된다.
	//   ★ 그리고 형태소로도 그것이 맞다(단위명사는 띄어 쓸 수 있다).
	static void AddCount(String& cap, Array<int>& wax, bool& first, int n)
	{
		AddWord(cap, wax, first, WordCount(n), 0);
		if (n < 6) AddWord(cap, wax, first, "개", kWFunc);
	}

	// 축 하나만 말하는 낱말(단독 제시용).
	static const char* WordOfAxis(const MLScene& s, int axis)
	{
		const MLAxis a = AxisAt(axis);
		if (a == MLAxis::Count) return WordCount(s.count);
		if (a == MLAxis::Shape) return WordShape(s.shape);
		if (a == MLAxis::Color) return WordColor(s.color);
		if (a == MLAxis::Size)  return WordSize(s.big);
		if (a == MLAxis::Pos)   return WordPos(s.pos);
		return WordFill(s.filled);
	}

	// 📝📝 **형태를 섞은 캡션** — `variant` 로 고른다. ⚠️ `variant` 는 **장면과 독립**이어야 한다
	//   (조사·형태가 축과 상관되면 조사가 축을 예측하게 되어 측정이 오염된다).
	//
	// ★ **단독 제시를 넣는 것이 핵심이다.** 이름을 가르칠 때는 문장에 묻어 주지 않고
	//   **그 낱말만** 딱 준다(`동그라미.`). 그러면 **그 낱말의 범위가 그대로 보인다** —
	//   속임수가 아니라 **세상에 실제로 있는 감독**이고, 오히려 가장 당연한 형태다.
	//   ⇒ 커리큘럼이 **단독 → 짧은 구 → 전체 문장**이 된다(*"사다리 한 칸이 능력 하나"* 규약과 같다).
	//
	// ★ **종결 부호를 준다**(`.`/`!`). ⚠️ 예전에는 캡션이 `…셋이 있다왼쪽에…` 로 그냥 이어붙어서
	//   **문장 끝 경계에 관측 가능한 신호가 하나도 없었다**(정답에는 그 경계가 있었다).
	//   ★ 종결 부호는 **인코딩 사실**이다 — 진짜 글에 있는 것이고 우리가 심는 힌트가 아니다.
	//     ⚠️ 단 **낱말 경계마다** 부호를 넣는 것은 답을 주는 짓이다 — **문장 끝에만** 넣는다.
	// ★ **사다리다 — 형태를 섞는 것이 아니다.**
	//   ⚠️⚠️ 사전학습이 **0** 이므로 처음부터 여덟 낱말·여섯 축을 한꺼번에 주면 배울 수가 없다.
	//     사람이 배우는 순서가 그렇지 않다: `사과` → `사과 빨강` → `사과는 빨강이다`.
	//   ⇒ **칸마다 능력 하나**(이 저장소의 그 규약):
	//     · **1칸 — 단독**: `동그라미.` `붉은.` `셋.` `있다.` **`없다.`**  ← 낱말의 **범위가 그대로 보인다**
	//     · **2칸 — 두 낱말**: `붉은 동그라미.` `동그라미 셋.` `동그라미 있다.`  ← **재조합**이 처음 생긴다
	//     · **3칸 — 전체 문장**: 조사·모든 축                              ← 앞 두 칸을 딛는다
	//   ★ 1칸이 **속임수가 아니다** — 이름을 가르칠 때 낱말만 주는 것은 세상에 실제로 있는 감독이고,
	//     오히려 가장 당연한 형태다.
	//   ⚠️ `variant` 는 **장면과 독립**이어야 한다(형태·조사가 축과 상관되면 조사가 축을 예측한다).
	static String CaptionVar(const MLScene& s, uint32 variant)
	{
		const char* end = ((variant / 3u) % 2u == 0u) ? "." : "!";
		// ★ 없으면 말할 것이 하나뿐이다 — 그것이 **가장 원시적인 접지**다.
		if (s.exists == 0) return Format("없다%s", end);

		const uint32 form = variant % 6u;          // 0·1 = 1칸 · 2·3 = 2칸 · 4·5 = 3칸
		const uint32 pick = (variant / 5u) % 6u;   // 1칸에서 어느 축을 말하나

		if (form <= 1u)
		{
			// 1칸 — 단독. ★ 가끔 `있다.` 도 준다(`없다.` 와 짝이 되어야 뜻이 생긴다).
			if (((variant / 7u) % 5u) == 0u) return Format("있다%s", end);
			return Format("%s%s", WordOfAxis(s, (int)pick), end);
		}
		if (form <= 3u)
		{
			// 2칸 — 두 낱말. ★ 여기서 **재조합**이 처음 생긴다(같은 모양에 색만 바뀐다 …).
			const uint32 k = (variant / 11u) % 4u;
			if (k == 0u) return Format("%s %s%s", WordColor(s.color), WordShape(s.shape), end);
			if (k == 1u) return Format("%s %s%s", WordShape(s.shape),
				WordCountPhrase(s.count).ptr(), end);
			if (k == 2u) return Format("%s %s%s", WordSize(s.big), WordShape(s.shape), end);
			return Format("%s 있다%s", WordShape(s.shape), end);
		}

		// 전체 문장 — 조사를 흔든다. ⚠️ 음운으로 정해지는 이/가는 안 흔들고 **쓰나 마나**만 흔든다.
		const uint32 pp = (variant / 7u) % 3u;     // 자리 조사: 에 / 에는 / 없음
		const uint32 cp = (variant / 11u) % 3u;    // 개수 조사: 이·가 / 도 / 없음
		const char* posPart = (pp == 0u) ? " 에" : ((pp == 1u) ? " 에는" : "");
		String cntPart;
		if (cp == 0u) cntPart = Format(" %s", WordCountPart(s.count));
		else if (cp == 1u) cntPart = String(" 도");
		return Format("%s%s %s %s %s %s %s%s 있다%s",
			WordPos(s.pos), posPart, WordSize(s.big), WordColor(s.color), WordFill(s.filled),
			WordShape(s.shape), WordCountPhrase(s.count).ptr(), cntPart.ptr(), end);
	}

	// 💻 장면 → `.pes` 소스. ⚠️ 랜덤은 없다 — 숫자가 **소스에 박혀** 코드가 그림을 결정한다.
	static String Code(const MLScene& s, bool cm)
	{
		const MLPalette& p = MLEpisodeGen::Palette(s.color);
		const int r = Radius(s);
		const bool mv = (s.exists != 0 && s.moves != 0);
		String out;
		out.AppendFormat("domain draw\n\n");
		// 🎞️ **최상위 `self` 선언** — ⚠️ `:=` 는 이 언어에서 **최상위 선언**이다(함수 안에서 못 쓴다).
		//   ★ `ox/oy` 가 **누적**되어야 `간다` 가 된다 — 상수 오프셋이면 *"한 번 옮겨졌다"* 일 뿐이고
		//     둘째 프레임부터 델타가 0 이 되어 `안간다` 와 구별이 안 된다.
		//   ★ `tx/ty` 는 그릴 자리 임시값이다(인자 자리에 산술식을 넣지 않으려고 — 이 언어에서
		//     검증된 관용구는 **맨 변수**다).
		if (mv) out.AppendFormat("self.ox := 0\nself.oy := 0\nself.tx := 0\nself.ty := 0\n\n");
		out.AppendFormat("func OnStart()\n{\n");
		if (cm) out.AppendFormat("    // 아무것도 없는 검은 바탕에서 시작한다\n");
		out.AppendFormat("    Draw::Clear(0, 0, 0)\n");
		// ★ 없으면 여기서 끝이다 — **빈 프레임**이 `없다` 의 지시대상이다.
		if (s.exists == 0) { out.AppendFormat("}\n"); return out; }
		if (cm) out.AppendFormat("    // %s빛으로 그린다\n", p.name);
		out.AppendFormat("    Draw::Color(%d, %d, %d)\n", p.r, p.g, p.b);
		if (cm)
		{
			// ⚠️ 숫자를 되읽지 않는다 — **의도**를 적는다(숫자의 뜻은 프레임이 가르친다).
			out.AppendFormat("    // %s에 %s %s%s를 %s 놓는다\n", WordPos(s.pos), WordSize(s.big),
				WordFill(s.filled), WordShape(s.shape), WordCount(s.count));
		}
		for (int i = 0; i < s.count; ++i)
		{
			int x = 0, y = 0;
			SlotAt(s, i, x, y);
			if (s.shape == 0)
			{
				if (s.filled != 0) out.AppendFormat("    Draw::CircleFill(%d, %d, %d)\n", x, y, r);
				else               out.AppendFormat("    Draw::Circle(%d, %d, %d)\n", x, y, r);
			}
			else
			{
				const int w = r * 2, h = r * 2;
				if (s.filled != 0) out.AppendFormat("    Draw::RectFill(%d, %d, %d, %d)\n", x - r, y - r, w, h);
				else               out.AppendFormat("    Draw::Rect(%d, %d, %d, %d)\n", x - r, y - r, w, h);
			}
		}
		out.AppendFormat("}\n");

		// 🎞️ **이동이면 `OnFrame` 을 낸다** — 시간축이 여기서 생긴다.
		//   ⚠️ 프레임 인자를 받지 않는다(→ `drawprogram.cw` 의 그 근거): `+=` 로 **재귀 관계**를 쓰게 해야
		//     닫힌 형태 `y = f(i)` 로 도망가지 않는다.
		//   ★ `안간다` 면 **`OnFrame` 을 아예 내지 않는다** ⇒ 프레임이 안 바뀌고 **델타가 전부 0** 이다.
		//     그것이 `안간다` 의 지시대상이고, 우리가 심는 것이 아니라 **코드가 낸 결과**다.
		if (mv)
		{
			const int dx = (s.moveDir == 0) ? -kStep : ((s.moveDir == 1) ? kStep : 0);
			const int dy = (s.moveDir == 2) ? -kStep : ((s.moveDir == 3) ? kStep : 0);
			out.AppendFormat("\nfunc OnFrame()\n{\n");
			if (cm) out.AppendFormat("    // 있던 자리에서 한 걸음 나아간다. 늘 같은 만큼이다\n");
			out.AppendFormat("    self.ox = self.ox + %d\n", dx);
			out.AppendFormat("    self.oy = self.oy + %d\n", dy);
			if (cm) out.AppendFormat("    // 지난 그림은 지우고, 새 자리에 다시 그린다\n");
			out.AppendFormat("    Draw::Clear(0, 0, 0)\n");
			out.AppendFormat("    Draw::Color(%d, %d, %d)\n", p.r, p.g, p.b);
			for (int i = 0; i < s.count; ++i)
			{
				int x = 0, y = 0;
				SlotAt(s, i, x, y);
				if (s.shape == 0)
				{
					out.AppendFormat("    self.tx = self.ox + %d\n    self.ty = self.oy + %d\n", x, y);
					if (s.filled != 0) out.AppendFormat("    Draw::CircleFill(self.tx, self.ty, %d)\n", r);
					else               out.AppendFormat("    Draw::Circle(self.tx, self.ty, %d)\n", r);
				}
				else
				{
					const int w = r * 2;
					out.AppendFormat("    self.tx = self.ox + %d\n    self.ty = self.oy + %d\n", x - r, y - r);
					if (s.filled != 0) out.AppendFormat("    Draw::RectFill(self.tx, self.ty, %d, %d)\n", w, w);
					else               out.AppendFormat("    Draw::Rect(self.tx, self.ty, %d, %d)\n", w, w);
				}
			}
			out.AppendFormat("}\n");
		}
		return out;
	}

	// 🎲 기준 장면(씨앗에서 결정적으로). ⚠️ 씨앗을 섞어 넣는다 — 연속 씨앗이 상관된 첫 난수를 낸다.
	//   ★ **`Fits` 를 안 통과하는 조합이 있다 — 64² 는 좁다.** 큰 도형 다섯 개는 어디에도 안 들어가고,
	//     큰 도형 둘을 `왼쪽` 에 두면 bbox 중심이 가운데 칸으로 넘어간다(그러면 `왼쪽` 이 거짓).
	//   ⇒ 씨앗을 굴려 **들어가는 것**을 고른다. ⚠️ 대신 분포가 작은/가운데 쪽으로 기운다 —
	//     그것은 버그가 아니라 **캔버스가 정하는 사실**이고, 축을 조용히 거짓으로 만드는 것보다 낫다.
	static MLScene BaseScene(uint32 seed)
	{
		for (int t = 0; t < 64; ++t)
		{
			SeedRand(MLEpisodeGen::ScrambleSeed(seed + (uint32)t * 7919u));
			MLScene s;
			s.count  = RandInt(1, 6);
			s.shape  = RandInt(0, 2);
			s.color  = RandInt(0, MLEpisodeGen::PaletteCount());
			s.big    = RandInt(0, 2);
			s.pos    = RandInt(0, 5);
			s.filled = RandInt(0, 2);
			if (Fits(s)) return s;
		}
		return MLScene();   // 하나·작은·가운데 = 늘 들어간다(기본값). 실질적으로 안 온다.
	}

	// ⭐ **그 축만 다른 짝**을 만든다. ⚠️ 반드시 **값이 달라야** 한다 — 같으면 대조가 아니다.
	//   ★ **결과가 `Fits` 를 통과해야 한다** → 못 하면 false. ⚠️ 그때 **다른 축으로 도망가지 않는다** —
	//     그러면 최소대립쌍이 아닌 것을 대립쌍이라고 이름 붙이는 셈이다. 대신 호출부가 기준 장면을 다시 뽑는다.
	//   ★ 개수·자리는 후보가 여러 개라 **들어가는 것을 골라** 쓴다. 크기(빈/찬 아님)는 값이 둘뿐이라
	//     안 들어가면 그 기준 장면으로는 크기 축을 못 흔든다.
	static bool Vary(const MLScene& s, MLAxis a, uint32 seed, MLScene& out)
	{
		SeedRand(MLEpisodeGen::ScrambleSeed(seed ^ 0x9E3779B9u));
		MLScene o = s;
		if (a == MLAxis::Count)
		{
			// ★ 개수는 **한 칸이 아니라 눈에 보이게** 바꾼다(1↔3, 2↔5 …) — 1↔2 는 그림에서 덜 뚜렷하다.
			const int first = (s.count <= 2) ? (s.count + 2) : (s.count - 2);
			for (int k = 0; k < 6; ++k)
			{
				// 뚜렷한 후보를 먼저 보고, 안 들어가면 나머지 개수를 훑는다.
				const int c = (k == 0) ? first : (k + 1);
				if (c < 1 || c > 6 || c == s.count) continue;
				o.count = c;
				if (Fits(o)) { out = o; return true; }
			}
			return false;
		}
		if (a == MLAxis::Pos)
		{
			const int start = 1 + RandInt(0, 4);
			for (int k = 0; k < 5; ++k)
			{
				const int q = (s.pos + start + k) % 5;
				if (q == s.pos) continue;
				o.pos = q;
				if (Fits(o)) { out = o; return true; }
			}
			return false;
		}
		if (a == MLAxis::Shape)      o.shape = 1 - s.shape;
		else if (a == MLAxis::Size)  o.big = 1 - s.big;
		else if (a == MLAxis::Fill)  o.filled = 1 - s.filled;
		else
		{
			const int n = MLEpisodeGen::PaletteCount();
			o.color = (s.color + 1 + RandInt(0, n - 1)) % n;   // 자기 자신은 피한다
		}
		if (!Fits(o)) return false;
		out = o;
		return true;
	}

	// 최소대립쌍 하나. ⚠️ **기준 장면부터 다시 뽑는다** — 흔든 쪽이 캔버스에 안 들어갈 수 있으므로.
	//   ★ 실패를 조용히 삼키지 않는다: false 면 그 축은 이 씨앗으로 대립쌍이 안 되는 것이고,
	//     호출부가 그것을 로그로 낸다(감사에서 "축이 6/6" 이 아니게 되어 눈에 띈다).
	static bool BuildPair(int axisIndex, uint32 seed, bool withComments,
		MLEpisode& a, MLEpisode& b)
	{
		const MLAxis ax = AxisAt(axisIndex);
		for (uint32 t = 0; t < 32u; ++t)
		{
			const MLScene sa = BaseScene(seed + t * 104729u);
			MLScene sb;
			if (!Vary(sa, ax, seed + t * 104729u, sb)) continue;
			_Fill(a, sa, withComments, seed);
			_Fill(b, sb, withComments, seed);
			return true;
		}
		return false;
	}

private:
	static void _Fill(MLEpisode& e, const MLScene& s, bool cm, uint32 seed)
	{
		e.rung = 0;
		e.seed = seed;
		e.frameCount = 1;
		e.code = Code(s, cm);
		e.caption = Caption(s);
	}
};

// ── 👁️ **프레임 판독기**(최소판) — 그림에서 사실을 뽑는다 ────────────────────────────────
//
// ★ **왜 지금 필요해졌나 = 캡션 감사가 "프레임이 거짓말하는 것" 을 못 잡는다.**
//   실측으로 밟았다: 캡션은 `셋이` 라고 말하는데 그림에는 도형이 **하나**만 있었다(격자 오프셋이 캐스팅
//   우선순위 때문에 전부 0 이 되어 겹쳤다). 캡션 감사는 *"낱말이 하나만 다른가"* 만 보므로 **통과했다.**
//   ⇒ **말과 그림을 서로 견주는 검사**가 따로 있어야 한다. 그것이 이 판독기이고, P6(실패에서 배우기)의
//     판독기와 **같은 것**이다 — 데이터 유효성 때문에 먼저 왔을 뿐이다.
//
// ★ **판독기는 사실만 뽑고 문장은 만들지 않는다**(→ ML.md 의 그 위험). 문장은 사람이 저작하고,
//   판독 어휘를 늘리는 것이 곧 커리큘럼 확장이다.
// ⚠️⚠️ **모델/LLM 으로 판독하지 않는다** — 결정론이 깨지면 "정답" 이 흔들리고 이 프로젝트의 유일한
//   접지를 잃는다.
//
// ⚠️ 아주 단순한 4-이웃 라벨링이다(스택 대신 배열 큐). 도형이 겹치면 **한 덩어리로 센다** — 그것이 맞다:
//   사람도 겹친 것을 못 세고, 그러면 캡션의 개수 낱말이 애초에 거짓이기 때문이다.

class MLFrameFacts
{
public:
	int   blobs = 0;        // 배경 아닌 덩어리 수
	int   minX = 0, minY = 0, maxX = 0, maxY = 0;   // 전체 바운딩 박스
	int   litPixels = 0;    // 배경 아닌 픽셀 수
	// 🎨 켜진 픽셀의 **평균색**. ★ AA 도 디더링도 없으므로 단색 도형이면 팔레트 값과 **정확히** 같다
	//   → `색` 낱말을 되짚는 재료가 된다(가장 가까운 팔레트 항목을 고르면 그 낱말이 나와야 한다).
	int   avgR = 0, avgG = 0, avgB = 0;
	float fillRatio = 0.0f; // ⚠️ **전체** bbox 기준이다 — 덩어리가 흩어지면 급락하므로 개수·자리에 오염된다
	// 🔷 **덩어리별 채움률의 평균** — `덩어리픽셀 / 그 덩어리의 bbox 면적` 을 덩어리마다 재서 평균.
	//   ★ **왜 이것을 더하나**: `fillRatio` 는 **전체** bbox 라 덩어리가 흩어지면 급락한다
	//     ⇒ 개수·자리에 오염되어 **모양을 못 가른다**. 덩어리별로 재면 개수·자리·크기에 **불변**이다.
	//   ★ 그러면 모양이 갈린다: 동그라미 꽉 = `π/4 ≈ 0.785` · 네모 꽉 ≈ `1.0` · 테두리는 훨씬 낮다.
	//   ⚠️⚠️ **모양과 속을 동시에 건드린다** — 그것은 결함이 아니라 실제 커플링이고, 지금 필요한 것이
	//     바로 그것이다: *"사실 하나에 축 후보가 둘"* 이 없으면 호/불호의 선택 스케일(성격)이
	//     고를 것이 없다(실측: 아는 축 2개 이상인 사실이 **1개**뿐이었다).
	//   ⚠️ 겹친 도형은 한 덩어리로 세므로(위 머리말) 그 경우 이 값도 한 덩어리 기준이다 — 그것이 맞다.
	float blobFill = 0.0f;
	bool  empty = true;

	// 🔲🔲 **공간 격자 두 장**(D49) — `틀` = 프레임 3x3 · `몸` = bbox 3x3. 값은 **그 칸의 잉크 픽셀 수**.
	//
	// ★ **왜 두 장이고 왜 상보적인가**(D46 이 실측으로 정했다): 축 → 사실 대응을 재 보니
	//   **면적을 세 축이(개수 37.5 · 크기 47.1 · 속 16.0), 채움을 세 축이** 가산으로 민다
	//   ⇒ 전역 스칼라가 「어디서」를 잃어서 겹친다. `틀` 은 **개수·자리**를 갈라 주고(도형이 프레임
	//   어디에 있나) `몸` 은 **모양·속**을 갈라 준다(bbox 안에서 잉크가 어떻게 퍼졌나 — 크기·자리에 불변).
	// ★ **왜 「유무」가 아니라 「픽셀 수」인가** — 그것이 이 설계의 유일한 비자명한 판정이다.
	//   `_Calibrate` 는 *"캡션이 같은 쌍에서의 **최대** 차분"* 을 문턱으로 쓴다(튜닝 상수 0개).
	//   그런데 이산(0/1) 사실은 그 쌍에서 **한 번만 뒤집혀도 `_thr = 1`** 이 되어 `raw > thr` 이
	//   영원히 거짓이다 ⇒ **격자 18칸이 조용히 죽는다.** 캡션이 같은 쌍은 `간격`만 다르고
	//   간격은 도형을 움직이므로 **반드시 뒤집힌다.**
	//   ⇒ ★ 그래서 **센서는 셀 수 있는 것을 담고**(픽셀 수) **「유무냐 양이냐」는 소비자가 정한다**
	//     (`MLDiff::_tileM`). 유무는 `count > 0` 한 줄이므로 정보를 하나도 안 잃는다.
	//   ⚠️ 이것은 함정 173 의 형제다 — *"손잡이의 소비자를 세어라"*. 여기서는 **문턱의 소비자**가
	//     둘(교정 가능한 연속량 ↔ 톨러런스가 없는 이산량)이고, 센서를 이산으로 만들면 그 갈림을
	//     **표현할 수 없게** 된다.
	// ⚠️ `uint16` 이면 충분하다 — 128x128 프레임의 한 칸이 최대 `43x43 = 1849` 픽셀이다.
	uint16 tileF[9] = {}, tileB[9] = {};
};

class MLFrameReader
{
public:
	// RGBA8 비트맵에서 사실을 뽑는다. `bg` 와 다른 픽셀을 "켜진 것" 으로 본다.
	//   ⚠️ 임계값을 둔다 — AA 가 없으므로 정확 비교로도 되지만, 양자화(RGB332)를 지난 그림도
	//     같은 함수로 읽을 수 있게 여유를 둔다.
	static void Read(const ImageFormat::Bitmap& bmp, MLFrameFacts& out)
	{
		out = MLFrameFacts();
		const uint32 w = bmp.width, h = bmp.height;
		if (w == 0 || h == 0) return;
		const uint8* px = (const uint8*)bmp.bitmap.GetData();
		if (px == nullptr) return;

		int sumR = 0, sumG = 0, sumB = 0;
		Array<uint8> lit;   lit.Reset((uint64)w * h);
		Array<uint8> seen;  seen.Reset((uint64)w * h);
		for (uint32 i = 0; i < w * h; ++i)
		{
			const uint8* q = px + (uint64)i * 4;
			// 배경은 검정이다(커리큘럼이 `Draw::Clear(0,0,0)` 로 시작한다).
			const bool on = (q[0] > 24 || q[1] > 24 || q[2] > 24);
			lit.Data()[i] = on ? 1u : 0u;
			seen.Data()[i] = 0u;
			if (on)
			{
				out.litPixels++; sumR += (int)q[0]; sumG += (int)q[1]; sumB += (int)q[2];
				// 🔲 `틀` = **프레임** 3x3. ⚠️ `* 3 / w` 는 마지막 칸이 한 픽셀 넓을 수 있다 —
				//   그것이 맞다(경계를 나눌 다른 방법이 없고, 상수를 박지 않는다).
				const uint32 tx = (i % w) * 3u / w, ty = (i / w) * 3u / h;
				out.tileF[ty * 3u + tx]++;
			}
		}
		if (out.litPixels == 0) return;
		out.empty = false;
		out.avgR = sumR / out.litPixels;
		out.avgG = sumG / out.litPixels;
		out.avgB = sumB / out.litPixels;

		out.minX = (int)w; out.minY = (int)h; out.maxX = -1; out.maxY = -1;
		Array<uint32> queue; queue.Reset((uint64)w * h);
		float blobFillSum = 0.0f;   // 🔷 덩어리별 채움률의 합(끝에서 덩어리 수로 나눈다)

		for (uint32 start = 0; start < w * h; ++start)
		{
			if (lit.Data()[start] == 0u || seen.Data()[start] != 0u) continue;
			out.blobs++;
			// 🔷 **이 덩어리만의** bbox 와 픽셀 수 — 전체 bbox 와 따로 든다.
			int bx0 = (int)w, by0 = (int)h, bx1 = -1, by1 = -1, bn = 0;
			uint32 qh = 0, qt = 0;
			queue.Data()[qt++] = start;
			seen.Data()[start] = 1u;
			while (qh < qt)
			{
				const uint32 c = queue.Data()[qh++];
				const int cx = (int)(c % w), cy = (int)(c / w);
				bn++;
				if (cx < bx0) bx0 = cx;
				if (cy < by0) by0 = cy;
				if (cx > bx1) bx1 = cx;
				if (cy > by1) by1 = cy;
				if (cx < out.minX) out.minX = cx;
				if (cy < out.minY) out.minY = cy;
				if (cx > out.maxX) out.maxX = cx;
				if (cy > out.maxY) out.maxY = cy;
				// 4-이웃
				if (cx > 0)            _Push(lit, seen, queue, qt, c - 1);
				if (cx + 1 < (int)w)   _Push(lit, seen, queue, qt, c + 1);
				if (cy > 0)            _Push(lit, seen, queue, qt, c - w);
				if (cy + 1 < (int)h)   _Push(lit, seen, queue, qt, c + w);
			}
			const int dw = bx1 - bx0 + 1, dh = by1 - by0 + 1;
			if (dw > 0 && dh > 0) blobFillSum += (float)bn / (float)(dw * dh);
		}

		const int bw = out.maxX - out.minX + 1, bh = out.maxY - out.minY + 1;
		if (bw > 0 && bh > 0) out.fillRatio = (float)out.litPixels / (float)(bw * bh);
		if (out.blobs > 0) out.blobFill = blobFillSum / (float)out.blobs;

		// 🔲 `몸` = **bbox** 3x3 — bbox 를 알아야 하므로 두 번째 훑기다(잉크만 본다).
		//   ★ 이것이 `틀` 과 상보적인 자리다: bbox 로 정규화하므로 **크기·자리에 불변**이고
		//     **모양·속**(잉크가 bbox 안에서 어떻게 퍼졌나)만 남는다.
		if (bw > 0 && bh > 0)
			for (uint32 i = 0; i < w * h; ++i)
			{
				if (lit.Data()[i] == 0u) continue;
				const int cx = (int)(i % w) - out.minX, cy = (int)(i / w) - out.minY;
				uint32 tx = (uint32)(cx * 3 / bw), ty = (uint32)(cy * 3 / bh);
				if (tx > 2u) tx = 2u;
				if (ty > 2u) ty = 2u;
				out.tileB[ty * 3u + tx]++;
			}
	}

private:
	static void _Push(Array<uint8>& lit, Array<uint8>& seen, Array<uint32>& q, uint32& qt, uint32 i)
	{
		if (lit.Data()[i] == 0u || seen.Data()[i] != 0u) return;
		seen.Data()[i] = 1u;
		q.Data()[qt++] = i;
	}
};
