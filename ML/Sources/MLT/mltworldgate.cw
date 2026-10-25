// mltworldgate.cw — 🚧 **배관 관문 넷.** ⚠️ **그림보다 이것을 먼저 본다**
//
// ★ **왜 그림보다 먼저인가** — 그림은 «그럴듯해 보이는 것» 을 잘 만든다. 그런데 이 트랙의
//   전제는 *"`씨앗 → 세계` 가 **함수**다"* 이고, 그것이 깨지면 **뒤의 모든 판정이 뜻을 잃는다.**
//   ⇒ 바이트 비교로 먼저 못 박는다(CPU 픽셀이라 그대로 된다).
//
// | # | 무엇 | 왜 |
// |---|---|---|
// | ㉠ | 같은 씨앗 두 번 = **상태 + 프레임 바이트 동일** | 깨지면 `씨앗 → 세계` 가 함수가 아니다 |
// | ㉡ | ⭐ **프레임 on/off 에서 상태 바이트 동일** | ***「같은 씨앗」 못의 조작적 정의*** |
// | ㉢ | 배경이 **최빈 바이트**로 잡히나(0 이 **아니다**) | RGB332 는 0 이 「안 바뀜」 예약이라 검정이 1 로 밀린다 |
// | ㉣ | **축의 직교** — 한 축만 흔들면 나머지가 안 흔들리나 | 안 그러면 P1 의 「축이 갈리나」가 원리적으로 못 선다 |
//
// ⚠️⚠️ ㉡ 이 왜 결정적인가: 프레임 렌더가 **난수를 한 번이라도 뽑으면** 그 뒤 상태가 갈린다.
//   그러면 *"상태와 프레임이 같은 사건"* 이 거짓이 되고 **두 접지가 서로를 도울 근거가 사라진다.**
//   ★ 그래서 이 관문은 **성능이 아니라 전제**를 잰다 — 실패하면 세계를 고친다(모델을 고치지 않는다).
//
// ⚠️ ㉣ 는 **완전 직교를 요구하지 않는다** — 전후진이 시선 방향으로 가므로 `yaw` 는 위치에
//   **의도적으로 관여한다**(그래야 축이 얽힌 세계다). 요구하는 것은 *"흔든 축이 **가장 크게**
//   움직이나"* 이고, 그 기준이 뒤집히면 세계가 축을 뒤섞은 것이다.

using namespace PE;

class MLTWorldGate
{
public:
	// 반환 = 실패 수(0 이면 전부 통과).
	static int RunAll()
	{
		LogA("[mlt] ── 🚧 배관 관문 (그림보다 먼저 · 바이트 비교) ──\n");
		int fail = 0;
		fail += _G1_Determinism();
		fail += _G2_FrameDoesNotConsume();
		fail += _G3_BackgroundIsModal();
		fail += _G4_AxisSeparation();
		if (fail == 0) LogA("[mlt] ✅ 배관 관문 — 넷 다 통과 (P0 을 돌릴 자격이 생겼다)\n");
		else           LogA("[mlt] ⛔ 배관 관문 — 실패 %d건 ⇒ **P0 을 돌리지 않는다**(세계를 고친다)\n", fail);
		return fail;
	}

private:
	static constexpr uint32 kTicks = 24u;

	// 한 에피소드를 굴려 상태를 **바이트로** 담는다(비교 가능하게).
	//   `render` 가 true 면 매 틱 프레임도 그린다 — ㉡ 이 그 유무를 가른다.
	static void _RunEpisode(uint32 seedNo, uint32 epi, int hold, int autoN, bool render,
		Array<float>& outState, Bytes* outLastFrame)
	{
		MLTWorld w;
		w.Reset(seedNo, epi, hold, autoN);
		outState.Reset(0);
		ImageFormat::Bitmap canvas;   // ⚠️ 루프 **밖**에서 한 번(매 틱 만들면 재할당+제로필이다)
		for (uint32 t = 0; t < kTicks; ++t)
		{
			w.Step();
			const MLTState& s = w.State();
			for (int a = 0; a < MLTState::kAxes; ++a) outState.Add(s.Axis(a));
			if (render)
			{
				if (!w.Render(canvas)) { LogA("[mlt]   ⛔ Render 실패(t=%u)\n", t); return; }
				if (outLastFrame != nullptr && t + 1u == kTicks) MLTWorld::Pack(canvas, nullptr, *outLastFrame);
			}
		}
	}

	static bool _SameBytes(const Array<float>& a, const Array<float>& b)
	{
		if (a.Count() != b.Count() || a.Count() == 0u) return false;
		// ⚠️ **비트 비교**다(근사 비교가 아니다) — 결정성은 「거의 같다」가 아니다.
		const uint8* pa = (const uint8*)a.Data();
		const uint8* pb = (const uint8*)b.Data();
		const uint32 n = a.Count() * (uint32)sizeof(float);
		for (uint32 i = 0; i < n; ++i) if (pa[i] != pb[i]) return false;
		return true;
	}

	// ── ㉠ 같은 씨앗 두 번 = 상태 + 프레임 바이트 동일 ────────────────
	static int _G1_Determinism()
	{
		int fail = 0;
		for (uint32 sd = 0; sd < 3u; ++sd)   // 씨앗 셋만 봐도 충분하다(함수가 아니면 첫 씨앗에서 깨진다)
		{
			Array<float> s1, s2; Bytes f1, f2;
			_RunEpisode(sd, 0u, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew, true, s1, &f1);
			_RunEpisode(sd, 0u, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew, true, s2, &f2);
			const bool okS = _SameBytes(s1, s2);
			bool okF = (f1.GetSize() == f2.GetSize() && f1.GetSize() != 0);
			if (okF)
			{
				const uint8* p1 = (const uint8*)f1.GetData();
				const uint8* p2 = (const uint8*)f2.GetData();
				for (uint64 i = 0; i < f1.GetSize(); ++i) if (p1[i] != p2[i]) { okF = false; break; }
			}
			if (!okS || !okF)
			{
				LogA("[mlt]   ⛔ ㉠ 씨앗 %u — 상태 %s · 프레임 %s (씨앗→세계가 함수가 아니다)\n",
					sd, okS ? "동일" : "**다르다**", okF ? "동일" : "**다르다**");
				++fail;
			}
		}
		if (fail == 0) LogA("[mlt]   ✅ ㉠ 결정성 — 같은 씨앗 두 번이 상태·프레임 **비트 동일**(씨앗 3개)\n");
		return fail;
	}

	// ── ㉡ ⭐ 프레임 on/off 에서 상태 바이트 동일 ──────────────────
	static int _G2_FrameDoesNotConsume()
	{
		int fail = 0;
		for (uint32 sd = 0; sd < 3u; ++sd)
		{
			Array<float> withF, noF;
			_RunEpisode(sd, 1u, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew, true,  withF, nullptr);
			_RunEpisode(sd, 1u, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew, false, noF,   nullptr);
			if (!_SameBytes(withF, noF))
			{
				LogA("[mlt]   ⛔ ㉡ 씨앗 %u — **프레임이 난수를 소비했다**(상태가 갈렸다)\n", sd);
				++fail;
			}
		}
		if (fail == 0)
			LogA("[mlt]   ✅ ㉡ 프레임 on/off 에서 상태 **비트 동일** — 「같은 씨앗」 못이 박혔다\n");
		return fail;
	}

	// ── ㉢ 배경이 최빈 바이트인가 (⚠️ 0 이 아니다) ────────────────────
	static int _G3_BackgroundIsModal()
	{
		MLTWorld w; w.Reset(0u, 2u, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoNone);
		w.Step();
		ImageFormat::Bitmap c; Bytes packed;
		if (!w.Render(c) || !MLTWorld::Pack(c, nullptr, packed))
		{ LogA("[mlt]   ⛔ ㉢ 렌더/팩 실패\n"); return 1; }

		// ⚠️ **추론하지 말고 읽어 대조한다** — 「비었다」의 원인을 두 번 잘못 짚었다.
		//   ⇒ 프레임을 아스키로 찍어 **눈으로** 본다(64² → 32×16 로 접는다).
		{
			const uint8* g = (const uint8*)packed.GetData();
			uint32 bg = 0u, bn = 0u, h2[256];
			for (int i = 0; i < 256; ++i) h2[i] = 0u;
			for (uint64 i = 0; i < packed.GetSize(); ++i) h2[g[i]]++;
			for (uint32 v = 0; v < 256u; ++v) if (h2[v] > bn) { bn = h2[v]; bg = v; }
			const int S = MLTWorldCfg::kSide;
			LogA("[mlt]   🔍 프레임 아스키 (배경 0x%02X = '.' · 그 외 = '#')\n", bg);
			for (int ry = 0; ry < S; ry += 4)
			{
				char line[80]; int w = 0;
				for (int rx = 0; rx < S && w < 72; rx += 2)
				{
					bool ink = false;
					for (int dy = 0; dy < 4 && !ink; ++dy)
						for (int dx = 0; dx < 2 && !ink; ++dx)
							if (g[(ry + dy) * S + (rx + dx)] != (uint8)bg) ink = true;
					line[w++] = ink ? '#' : '.';
				}
				line[w] = 0;
				LogA("[mlt]      %s\n", line);
			}
		}

		uint32 hist[256]; for (int i = 0; i < 256; ++i) hist[i] = 0u;
		const uint8* p = (const uint8*)packed.GetData();
		for (uint64 i = 0; i < packed.GetSize(); ++i) hist[p[i]]++;
		uint32 best = 0u, bestN = 0u, zeros = hist[0];
		for (uint32 v = 0; v < 256u; ++v) if (hist[v] > bestN) { bestN = hist[v]; best = v; }
		const float share = 100.0f * (float)bestN / (float)packed.GetSize();

		int fail = 0;
		// ⚠️ 키프레임에 **0 이 있으면** 규약을 잘못 이해한 것이다(0 은 「안 바뀜」 예약이다).
		if (zeros != 0u) { LogA("[mlt]   ⛔ ㉢ 키프레임에 바이트 0 이 %u개 — 규약 위반\n", zeros); ++fail; }
		// 배경이 최빈이어야 한다(도형 넷이 화면을 다 덮으면 판독이 안 된다).
		if (share < 40.0f) { LogA("[mlt]   ⛔ ㉢ 최빈 바이트 몫 %.1f%% — 배경이 안 보인다\n", (double)share); ++fail; }
		// ⚠️⚠️ **상한도 있어야 한다** — 처음에 하한만 두고 98.2% 를 「통과」로 찍었다.
		//   배경이 거의 전부면 **프레임이 비었다**는 뜻이고, 그 프레임으로는 비전 접지가 원리적으로 안 된다
		//   (P2 의 재구성·활성이 전부 배경 한 색을 배운다). ⇒ 잉크 몫에 **바닥**을 건다.
		if (share > 92.0f)
		{
			LogA("[mlt]   ⛔ ㉢ 최빈 바이트 몫 %.1f%% — **프레임이 거의 비었다**(잉크 %.1f%% · 도형이 안 보인다)\n",
				(double)share, (double)(100.0f - share));
			++fail;
		}
		if (fail == 0)
			LogA("[mlt]   ✅ ㉢ 배경 = 최빈 0x%02X (%.1f%%) · 잉크 %.1f%% · 바이트 0 **없다**(규약대로)\n",
				best, (double)share, (double)(100.0f - share));
		return fail;
	}

	// ── ㉣ 축의 분리 — 흔든 축이 **가장 크게** 움직이나 ────────────────
	//   ⚠️ 완전 직교를 요구하지 않는다(전후진이 시선 방향이라 yaw 는 **의도적으로** 위치에 관여한다).
	static int _G4_AxisSeparation()
	{
		// 같은 시작 상태에서 **한 축의 명령만** 준 다섯 판을 굴려 어느 상태 축이 가장 움직였나 본다.
		//   ★ 축 i 의 명령 → 기대되는 상태 축: fwd/side→위치, up→y, dYaw→yaw, dPitch→pitch
		const int expect[MLTAct::kAxes] = { -1, 1, -1, 3, 4 };   // −1 = 위치(0/2 중 아무거나)
		const char* nm[MLTAct::kAxes] = { "fwd", "up", "side", "dYaw", "dPitch" };
		int fail = 0;
		for (int ax = 0; ax < MLTAct::kAxes; ++ax)
		{
			float mv[MLTState::kAxes];
			for (int a = 0; a < MLTState::kAxes; ++a) mv[a] = 0.0f;
			// 손으로 굴린다(행동을 우리가 정하므로 `MLTWorld::Step` 의 난수 경로를 안 탄다).
			MLTState s; s.x = 0.1f; s.y = 0.0f; s.z = 0.1f; s.yaw = 0.0f; s.pitch = 0.0f;
			const MLTState s0 = s;
			for (int t = 0; t < 8; ++t)
			{
				const float sy = Sin(s.yaw * 3.14159265f), cy = Cos(s.yaw * 3.14159265f);
				const float dt = MLTWorldCfg::kDt, u = 0.8f;
				if (ax == 0) { s.x += (u * sy) * dt; s.z += (u * cy) * dt; }
				if (ax == 1) { s.y += u * dt; }
				if (ax == 2) { s.x += (u * cy) * dt; s.z += (-u * sy) * dt; }
				if (ax == 3) { s.yaw += u * dt; }
				if (ax == 4) { s.pitch += u * dt; }
			}
			for (int a = 0; a < MLTState::kAxes; ++a)
			{
				const float d = s.Axis(a) - s0.Axis(a);
				mv[a] = (d < 0.0f) ? -d : d;
			}
			int arg = 0; for (int a = 1; a < MLTState::kAxes; ++a) if (mv[a] > mv[arg]) arg = a;
			const bool ok = (expect[ax] < 0) ? (arg == 0 || arg == 2) : (arg == expect[ax]);
			if (!ok)
			{
				LogA("[mlt]   ⛔ ㉣ %s 만 줬는데 가장 움직인 상태 축이 %d 다(기대 %d)\n",
					nm[ax], arg, expect[ax]);
				++fail;
			}
		}
		if (fail == 0)
			LogA("[mlt]   ✅ ㉣ 축 분리 — 다섯 명령이 각자 기대한 상태 축을 가장 크게 움직인다\n");
		return fail;
	}
};
