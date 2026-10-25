// mltw0.cw — 🌍 회차 95 · **세계를 먼저 찍는다** (`-mltw0`) ⚠️ **프로브 0 · 모델 0 · 인코더 0**
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 95 이다.** ⭐ **하네스보다 먼저 썼다.**
//
// ⚠️ **`l0` 계열이 아니다** — 이것은 **세계를 재는 도구**다(판정 관문이 없다).
//
// ── 🚨 왜 이 회차인가 — **규율 21 을 기계로 만든다** ──────────────────────
//   회차 94 가 중단되며 **회차 91·93·94 의 「깊이」 결론 셋을 철회**시켰다. 원인 한 줄:
//     ***나는 `d` 를 「거리」로 읽고 손계산했지만 실제로는 「전방 깊이」였다.***
//     `MLTWorld::_Project` — `d = cz`(카메라 전방 성분) · `kNear = 0.25`
//     ⇒ 시선에 **수직**으로 놓인 옆쪽 도형이 고리 위에 있어도 `d` 가 **0.25 까지** 내려간다.
//     ⇒ `r = 40/d` 이므로 `d = 0.37` 이면 **`r = 108px`**(64px 화면!) — 통째로 덮거나 **화면 밖**.
//   ⇒ **한 줄만 찍었으면 세 회차를 안 버렸다.** ⇒ ★ **이제 그 한 줄을 기계로 둔다.**
//
// ── 무엇을 찍나 — 관문 시각(`t = kTime−2`)의 후보 표적 여섯 ─────────────────
//   | ① `minD`    | 보이는 도형의 **최소 전방 깊이**(회차 91~94 가 쓴 그 값) |
//   | ② `maxR`    | 화면 반지름 **최댓값**(= `40/minD` — ⚠️ **정의상 ①과 한 몸**이어야 한다) |
//   | ③ `nOn`     | **중심이 화면 안**에 든 도형 수 |
//   | ④ `maxROn`  | 그중 반지름 **최댓값** ← ⭐ *"내가 실제로 보는 가장 큰 것"* |
//   | ⑤ `minDOn`  | 그중 **최소 깊이** ← ⭐ *"내가 실제로 보는 가장 가까운 것"* |
//   | ⑥ `ink`     | 잉크 비율(1 − 최빈 바이트 비율) ← **회차 93 이 12/12 로 「담긴다」고 실측** |
//
//   ⭐ 그리고 **결정적인 한 줄**: ***`minD` 를 낸 도형의 중심이 화면 밖인 비율.***
//     그것이 크면 회차 91 의 표적이 **뜻하는 것을 안 뜻했다**는 증거가 숫자로 남는다.
//
// ── 어떻게 읽나 ───────────────────────────────────────────────────────────
//   · 여섯 각각 **최소 · 5% · 50% · 95% · 최대 · 평균 · 표준편차**
//   · 쌍마다 **피어슨 상관** + ⭐ **3분위 계급 일치율**
//     ★ 일치율이 진짜 물음이다 — *"둘을 낱말로 만들면 같은 낱말인가"*.
//     ⚠️ 특히 **⑥ 잉크 ↔ ④ 화면안 최대반지름**이 거의 같으면 그 둘은 **한 낱말**이고,
//       그러면 회차 93 의 *"인코더가 잉크를 담는다"* 가 이미 *"크기를 담는다"* 를 뜻한다.
//
// ⚠️ **판정 관문이 없다.** 적을 것은 *"어느 양이 실제로 변하나 · 어느 둘이 같은 것인가"* 뿐이다.
// ══════════════════════════════════════════════════════════════════════════════

using namespace PE;

class MLTW0
{
public:
	static void Tick(RHI* rhi)
	{
		(void)rhi;
		if (_done) return;
		if (!OS::CommandLine::Has("-mltw0"))
		{
			LogA("[mlt] 🌍 회차 95(세계를 먼저 찍는다)는 **꺼져 있다**(`-mltw0`)\n");
			_done = true; return;
		}
		if (!_banner) { _Banner(); _banner = true; }
		if (_seed >= kSeeds) { _Summary(); return; }
		_Chunk();
	}

	static bool Done() { return _done; }

private:
	static constexpr uint32 kSeeds = 12u;
	static constexpr uint32 kCtx   = 512u;
	static constexpr uint32 kPerTick = 64u;                 // 한 틱에 문맥 몇 개(프레임이 안 멈추게)
	static constexpr uint32 kTime  = MLTP3Ctx::kTime;       // 8
	static constexpr uint32 kGateT = kTime - 2u;            // 6 = 관문 시각(회차 88~94 와 같다)
	static constexpr uint32 kEpi   = 5001u;                 // ⚠️ 회차 91~94 의 **프로브 시험** 대역
	static constexpr uint32 kQ     = 6u;                    // 재는 양의 수
	static constexpr uint32 kCls   = 3u;
	static constexpr uint32 kN     = kSeeds * kCtx;         // 6144

	inline static bool _done = false, _banner = false;
	inline static uint32 _seed = 0u, _ctx = 0u;
	inline static uint32 _offAny = 0u, _offMin = 0u;        // 화면 밖 판정 계수기
	inline static Array<float> _v[kQ];

	static const char* _QName(uint32 q)
	{
		switch (q)
		{
		case 0u: return "① minD  최소 전방깊이";
		case 1u: return "② maxR  화면반지름 최대";
		case 2u: return "③ nOn   화면안 도형수 ";
		case 3u: return "④ maxROn 화면안 최대반지름";
		case 4u: return "⑤ minDOn 화면안 최소깊이";
		default: return "⑥ ink   잉크 비율    ";
		}
	}

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🌍 **회차 95 · 세계를 먼저 찍는다**(⚠️ **프로브 0 · 모델 0 · 인코더 0** · 규율 21 을 기계로)\n");
		LogA("[mlt] 🌍   🚨 회차 94 가 **회차 91·93·94 의 「깊이」 결론 셋을 철회**시켰다 — `d` 는 **거리가 아니라 전방 깊이**였다\n");
		LogA("[mlt] 🌍     `_Project`: `d = cz`(전방 성분) · `kNear=0.25` ⇒ 시선에 **수직**인 옆 도형이 0.25 까지 내려간다\n");
		LogA("[mlt] 🌍     `r = 40/d` ⇒ `d=0.37` 이면 **r = 108px**(64px 화면) — 통째로 덮거나 **화면 밖**\n");
		LogA("[mlt] 🌍   재는 것 여섯 — ① minD · ② maxR · ③ 화면안 도형수 · **④ 화면안 최대반지름** · **⑤ 화면안 최소깊이** · ⑥ 잉크\n");
		LogA("[mlt] 🌍   씨앗 %u × 문맥 %u = **표본 %u** · 관문 시각 t=%u · 에피소드 %u~%u(회차 91~94 의 시험 대역)\n",
			kSeeds, kCtx, kN, kGateT, kEpi, kEpi + kCtx - 1u);
		LogA("[mlt] 🌍   ⭐ 읽을 것 — 분위수 + **쌍마다 피어슨 상관 & 3분위 계급 일치율**(*둘이 같은 낱말인가*)\n");
		LogA("[mlt] 🌍   ⚠️ **판정 관문이 없다** — 이것은 측정 회차다\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

	// 잉크 비율 = 1 − 최빈 바이트 비율(배경색 상수를 여기 다시 적지 않는다)
	static float _Ink(const Bytes& packed)
	{
		uint32 hist[256];
		for (uint32 i = 0; i < 256u; ++i) hist[i] = 0u;
		const uint8* p = (const uint8*)packed.GetData();
		const uint32 n = (uint32)MLTWorldCfg::kPixels;
		for (uint32 i = 0; i < n; ++i) ++hist[p[i]];
		uint32 mx = 0u;
		for (uint32 i = 0; i < 256u; ++i) if (hist[i] > mx) mx = hist[i];
		return 1.0f - (float)mx / (float)n;
	}

	static void _Chunk()
	{
		ImageFormat::Bitmap bmp; Bytes packed;
		const float S = (float)MLTWorldCfg::kSide;
		for (uint32 c = 0; c < kPerTick && _ctx < kCtx; ++c, ++_ctx)
		{
			MLTWorld w; w.Reset(_seed, kEpi + _ctx, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
			for (uint32 t = 0; t <= kGateT; ++t) w.Step();
			if (!w.Render(bmp) || !MLTWorld::Pack(bmp, nullptr, packed))
			{ LogA("[mlt] 🌍 ⛔ Render/Pack (씨앗 %u · 문맥 %u)\n", _seed, _ctx); _done = true; return; }

			MLTShapeView vs[MLTWorldCfg::kShapes];
			const int nv = w.VisibleShapes(vs, MLTWorldCfg::kShapes);
			// ⚠️ 목록은 **먼 것부터** 정렬 ⇒ 마지막이 `minD`.
			float minD = 0.0f, maxR = 0.0f;
			float maxROn = 0.0f, minDOn = 0.0f;
			uint32 nOn = 0u;
			bool haveOn = false;
			int argMin = -1;
			for (int i = 0; i < nv; ++i)
			{
				if (argMin < 0 || vs[i].d < vs[argMin].d) argMin = i;
				if (vs[i].r > maxR) maxR = vs[i].r;
				const bool on = (vs[i].sx >= 0.0f && vs[i].sx < S && vs[i].sy >= 0.0f && vs[i].sy < S);
				if (!on) continue;
				++nOn;
				if (vs[i].r > maxROn) maxROn = vs[i].r;
				if (!haveOn || vs[i].d < minDOn) { minDOn = vs[i].d; haveOn = true; }
			}
			if (argMin >= 0)
			{
				minD = vs[argMin].d;
				// ⭐ **결정적인 한 줄** — `minD` 를 낸 도형의 중심이 화면 밖인가
				const bool on = (vs[argMin].sx >= 0.0f && vs[argMin].sx < S
					&& vs[argMin].sy >= 0.0f && vs[argMin].sy < S);
				if (!on) ++_offMin;
			}
			if (nOn == 0u) ++_offAny;
			_v[0].Add(minD);   _v[1].Add(maxR);   _v[2].Add((float)nOn);
			_v[3].Add(maxROn); _v[4].Add(haveOn ? minDOn : 0.0f); _v[5].Add(_Ink(packed));
		}
		if (_ctx < kCtx) return;
		_ctx = 0u; ++_seed;
		if (_seed < kSeeds) return;
	}

	// ── 분위수(이분법 — 정렬 없이 O(50n)) ────────────────────────────
	static float _Quant(const float* v, uint32 n, float lo, float hi, float frac)
	{
		const uint32 want = (uint32)((double)n * (double)frac + 0.5);
		for (int it = 0; it < 60; ++it)
		{
			const float mid = 0.5f * (lo + hi);
			uint32 cnt = 0u;
			for (uint32 i = 0; i < n; ++i) if (v[i] < mid) ++cnt;
			if (cnt < want) lo = mid; else hi = mid;
		}
		return 0.5f * (lo + hi);
	}

	static void _Summary()
	{
		const uint32 n = _v[0].Count();
		float mn[kQ], mx[kQ], q05[kQ], q50[kQ], q95[kQ];
		double mean[kQ], sd[kQ];
		for (uint32 q = 0; q < kQ; ++q)
		{
			const float* v = _v[q].Data();
			mn[q] = v[0]; mx[q] = v[0];
			double s = 0.0, ss = 0.0;
			for (uint32 i = 0; i < n; ++i)
			{
				if (v[i] < mn[q]) mn[q] = v[i];
				if (v[i] > mx[q]) mx[q] = v[i];
				s += (double)v[i]; ss += (double)v[i] * (double)v[i];
			}
			mean[q] = s / (double)n;
			sd[q] = Sqrt((float)(ss / (double)n - mean[q] * mean[q]));
			q05[q] = _Quant(v, n, mn[q], mx[q], 0.05f);
			q50[q] = _Quant(v, n, mn[q], mx[q], 0.50f);
			q95[q] = _Quant(v, n, mn[q], mx[q], 0.95f);
		}
		// 3분위 계급
		static Array<uint32> cls[kQ];
		for (uint32 q = 0; q < kQ; ++q)
		{
			const float* v = _v[q].Data();
			const float t1 = _Quant(v, n, mn[q], mx[q], 1.0f / 3.0f);
			const float t2 = _Quant(v, n, mn[q], mx[q], 2.0f / 3.0f);
			cls[q].Reset(0);
			for (uint32 i = 0; i < n; ++i) cls[q].Add((v[i] < t1) ? 0u : ((v[i] < t2) ? 1u : 2u));
		}

		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🌍 **회차 95 · 세계를 먼저 찍는다** — 표본 **%u**(씨앗 %u × 문맥 %u · 관문 시각 t=%u)\n",
			n, kSeeds, kCtx, kGateT);
		LogA("[mlt] 🌍   🚨🚨 **`minD` 를 낸 도형의 중심이 화면 밖인 비율 = %.1f%%** (%u/%u)\n",
			100.0 * (double)_offMin / (double)n, _offMin, n);
		LogA("[mlt] 🌍   ⚠️ 화면 안에 중심이 든 도형이 **0개**인 프레임 = %.1f%% (%u/%u)\n",
			100.0 * (double)_offAny / (double)n, _offAny, n);
		LogA("[mlt] 🌍   ── 분위수 ────────────────────────────────────\n");
		for (uint32 q = 0; q < kQ; ++q)
			LogA("[mlt] 🌍   %s │ 최소 %8.3f · 5%% %8.3f · **중앙 %8.3f** · 95%% %8.3f · 최대 %8.3f │ 평균 %8.3f · sd %7.3f\n",
				_QName(q), (double)mn[q], (double)q05[q], (double)q50[q], (double)q95[q], (double)mx[q],
				mean[q], sd[q]);
		LogA("[mlt] 🌍   ── 쌍: 피어슨 상관 / **3분위 계급 일치율**(우연 33.3%%) ──\n");
		for (uint32 a = 0; a < kQ; ++a)
			for (uint32 b = a + 1u; b < kQ; ++b)
			{
				const float* va = _v[a].Data(); const float* vb = _v[b].Data();
				double sab = 0.0;
				for (uint32 i = 0; i < n; ++i)
					sab += ((double)va[i] - mean[a]) * ((double)vb[i] - mean[b]);
				const double r = (sd[a] > 1e-9 && sd[b] > 1e-9)
					? (sab / (double)n) / (sd[a] * sd[b]) : 0.0;
				uint32 agree = 0u;
				for (uint32 i = 0; i < n; ++i) if (cls[a][i] == cls[b][i]) ++agree;
				const double ag = 100.0 * (double)agree / (double)n;
				LogA("[mlt] 🌍   %u↔%u  r = %+7.4f │ 계급 일치 **%5.1f%%**%s\n",
					a + 1u, b + 1u, r, ag, (ag >= 80.0) ? "  ⭐ **거의 같은 낱말**" : "");
			}
		LogA("[mlt] 🌍   ⚠️ **판정 관문이 없다** — 이 표를 보고 **다음 낱말을 값으로** 고른다(규율 21)\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		_done = true;
	}

	CW_BODY(MLTW0)
};
