// mltp3k2.cw — 🔩 회차 70 · **틱당 쓰기 횟수가 범인인가** (`-mltp3k2`)
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 70 이다.**
// ⚠️ 상위 = **경험이 인코딩을 바꾸나** · **판정 회차가 아니다**(배관·진단).
// ══════════════════════════════════════════════════════════════════════════════
//
// ⭐ 회차 69 가 **배관은 멀쩡**을 12/12 로 세웠다(사다리 네 칸). ⇒ 회차 68 의 `㈂ ≡ ㈁` 은
//   **교대 루프의 버그**다. 그리고 회차 69 와 회차 67·68 이 **유일하게 다른 것**은:
//     ***회차 69 는 틱당 `SetExtDMag` 를 1번, 회차 67·68 은 8번 불렀다.***
//   ⚠️ 이 엔진은 컴퓨트 디스패치를 `computeCb` 에 **누적만** 하고 제출은 **Present 에서 1회**다
//     (회차 59 가 만난 그 함정) ⇒ 뒤의 Write 가 **앞서 기록된 디스패치까지 덮을** 수 있다.
//
// ── 팔 넷이 그것을 직접 가른다 ────────────────────────────────────────────
//   A 주입✗·틱당1 · B 주입✗·틱당8 · C 주입✓·틱당1 · **D 주입✓·틱당8**(회차 67·68 이 한 것)
//   ★ `A↔B` = **위생**(주입이 없으면 틱 분할이 결과를 바꾸면 안 된다)
//   ★ `C↔D` = **표제**(주입이 있을 때만 갈리면 범인은 「틱당 여러 번 쓰기」다)
//
// ⚠️⚠️ **시험 벡터가 프레임마다 달라야 한다** — 같으면 덮어써도 값이 같아 **함정이 안 드러난다**.

using namespace PE;

class MLTP3K2
{
public:
	static void Tick(RHI* rhi)
	{
		if (_done || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltp3k2"))
		{
			LogA("[mlt] 🔩 회차 70은 **꺼져 있다**(`-mltp3k2`) — 틱당 쓰기 횟수가 범인인가\n");
			_done = true; return;
		}
		if (!_banner) { _Banner(); _banner = true; }
		if (_seed >= kSeeds) { _Summary(); return; }
		switch (_st)
		{
		case kEncInit:  _EncBegin(rhi); return;
		case kEncTrain: _EncTrain();    return;
		case kSettle:   if (_wait > 0u) { --_wait; } else _AfterSettle(); return;
		case kScale:    _Scale();       return;
		case kPush:     _Push();        return;
		case kReadP:    _ReadP();       return;
		default: return;
		}
	}

	static bool Done() { return _done; }

private:
	static constexpr uint32 kSeeds = 12u;
	static constexpr uint32 kEncF = 32u, kEncSteps = 1200u, kEncPerTick = 8u;
	static constexpr uint32 kN = 250u, kLocal = 8u;
	static constexpr uint32 kTime = MLTP3Ctx::kTime;
	static constexpr uint32 kGroup = kEncF / kTime;                 // 4 문맥
	static constexpr uint32 kCand = MLTP2Cfg::kPatches * kLocal;    // 512
	// ⭐ 회차 71 — 팔을 **하나 더** 붙였다(자는 하나도 안 바꿨다): **E = 8칸 희소 주입**.
	//   ⚠️ 회차 70 이 「틱당 여러 번 쓰기」를 죽였고, 남은 유력 후보가 **희소성**이다 —
	//     몸통 기울기는 한 프레임에서 그 (문맥,시각)의 **8슬롯**에만 있다(512칸 중 8칸).
	static constexpr uint32 kArms = 5u;                             // A B C D **E**
	static constexpr uint32 kSparse = MLTP3Ctx::kPersist;           // 8
	static constexpr uint32 kSignPass = 10u;
	static constexpr uint32 kTrainEpi = 1u;

	enum { kEncInit, kEncTrain, kSettle, kScale, kPush, kReadP };

	inline static MLTP2Enc _E;
	inline static bool _done = false, _banner = false, _encSetup = false;
	inline static uint32 _seed = 0u, _st = kEncInit, _step = 0u, _arm = 0u, _wait = 0u;
	inline static uint32 _pf = 0u, _phase = 0u;
	inline static float  _scale = 1.0f;
	inline static bool   _scaleOk = false;
	inline static Array<float> _ext, _dm, _pr[kArms];
	inline static float _rel[kArms][kSeeds];      // ‖p(팔) − p(A)‖ / ‖p(A)‖
	inline static bool  _seedOk[kSeeds];

	// 팔의 성질 — ⭐ 이 두 줄이 이 회차의 전부다.
	static bool _Inject() { return _arm >= 2u; }
	static bool _Sparse() { return _arm == 4u; }                    // ⭐ E 만 8칸
	static uint32 _PerTick() { return (_arm == 1u || _arm == 3u) ? 8u : 1u; }
	static const char* _ArmName()
	{
		return (_arm == 0u) ? "A 주입✗·틱당1" : ((_arm == 1u) ? "B 주입✗·틱당8"
		     : ((_arm == 2u) ? "C 주입✓조밀·틱당1" : ((_arm == 3u) ? "D 주입✓조밀·틱당8"
		     : "E 주입✓**희소8칸**·틱당1")));
	}

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🔩 **회차 71 · 희소 주입이 범인인가**(⚠️ 판정 회차 아님 · 회차 70 에 팔 E 만 더했다)\n");
		LogA("[mlt] 🔩   A 주입✗·틱당1 · B 주입✗·틱당8 · C 조밀·틱당1 · D 조밀·틱당8 · ⭐ **E 희소 8칸**\n");
		LogA("[mlt] 🔩   ★ 표제 = `|A−E| > 0` — ⚠️ 노름은 C 와 **같게** 맞춘다(*희소해서* ↔ *작아서* 를 가른다)\n");
		LogA("[mlt] 🔩   ⚠️ 회차 70 이 「틱당 여러 번 쓰기」를 죽였다(D/C = 1.02 · 7/12)\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

	static void _EncBegin(RHI* rhi)
	{
		if (!_encSetup)
		{
			if (!_E.Setup(rhi, kEncF, kN)) { _Fail("인코더 준비"); return; }
			_encSetup = true;
		}
		else if (!_E.ResetSeed()) { _Fail("인코더 되돌리기"); return; }
		_E.SetK(kLocal); _E.SetSelectAbs(false); _E.ClearExtDMag();
		if (!_RenderPool(true)) return;
		_step = 0u; _st = kEncTrain;
	}

	// `pretrain == true` → 에피소드 0(프리트레인) · `false` → 코퍼스 그룹 0(문맥 0..3)
	static bool _RenderPool(bool pretrain)
	{
		Array<float> fr, tg; fr.Reset(0); tg.Reset(0);
		ImageFormat::Bitmap bmp; Bytes packed;
		if (pretrain)
		{
			MLTWorld w; w.Reset(_seed, 0u, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
			for (uint32 f = 0; f < kEncF; ++f)
			{
				w.Step();
				if (!w.Render(bmp) || !MLTWorld::Pack(bmp, nullptr, packed)) { _Fail("Render/Pack"); return false; }
				MLTP2Enc::AppendFrame(fr, tg, (const uint8*)packed.GetData());
			}
		}
		else
		{
			for (uint32 g = 0; g < kGroup; ++g)
			{
				MLTWorld w; w.Reset(_seed, kTrainEpi + g, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
				for (uint32 t = 0; t < kTime; ++t)
				{
					w.Step();
					if (!w.Render(bmp) || !MLTWorld::Pack(bmp, nullptr, packed)) { _Fail("Render/Pack"); return false; }
					MLTP2Enc::AppendFrame(fr, tg, (const uint8*)packed.GetData());
				}
			}
		}
		if (!_E.WritePool(fr, tg, kEncF)) { _Fail("풀 업로드"); return false; }
		return true;
	}

	static void _EncTrain()
	{
		for (uint32 i = 0; i < kEncPerTick && _step < kEncSteps; ++i)
		{
			_E.SetFrame(_step % kEncF);
			if (!_E.Forward() || !_E.Backward() || !_E.AdamStep(1.0f)) { _Fail("인코더 학습"); return; }
			++_step;
		}
		if (_step < kEncSteps) return;
		_wait = MLTEvalGate::kDelay; _st = kSettle;      // ⚠️ 리드백 규약
	}

	static void _AfterSettle()
	{
		// 배율은 **씨앗마다 한 번**(팔 A 의 프리트레인 직후 프레임 0). ⚠️ AdamStep 을 안 하므로
		//   파라미터를 안 건드린다 ⇒ 팔 A 가 다른 팔과 달라지지 않는다.
		if (!_scaleOk) { _phase = 0u; _st = kScale; return; }
		if (!_RenderPool(false)) return;
		_pf = 0u; _st = kPush;
	}

	static void _Scale()
	{
		if (_phase == 0u)
		{
			_E.SetFrame(0u); _E.ClearExtDMag();
			if (!_E.Forward() || !_E.Backward()) { _Fail("배율용 fwd/bwd"); return; }
			_wait = MLTEvalGate::kDelay; _phase = 1u; return;
		}
		if (_wait > 0u) { --_wait; return; }
		if (!_E.ReadDMag(_dm)) { _Fail("배율용 dMag"); return; }
		double su = 0.0, sd = 0.0;
		for (uint32 c = 0; c < kCand; ++c)
		{
			const float u = MLTWorld::Unit(MLTWorld::Hash(_seed * 613u + c, MLTSalt::Start, 31u));
			su += (double)u * u; sd += (double)_dm[c] * _dm[c];
		}
		const float nu = Sqrt((float)su), nd = Sqrt((float)sd);
		_scale = (nu > 1.0e-20f) ? (0.5f * nd / nu) : 1.0f;
		_scaleOk = true;
		LogA("[mlt] 🔩   씨앗 %2u · 배율 %.4g(‖dMag‖ %.4g)\n", _seed, (double)_scale, (double)nd);
		if (!_RenderPool(false)) return;
		_pf = 0u; _st = kPush;
	}

	// ⚠️ 시험 벡터는 **프레임마다 다르다** — 그것이 회차 70 설계의 핵심이다.
	// ⭐ 회차 71 — 팔 E 는 **8칸만** 채운다. ⚠️ **노름은 조밀 팔과 같게 맞춘다**
	//   (안 맞추면 *"희소해서"* 와 *"작아서"* 가 안 갈린다).
	//   ⚠️ 어느 8칸인지는 상관없다 — `_tDMag` 의 **512칸 전부가 「선택된 자리」**이기 때문이다
	//     (`_tMag[r·k+j]` 가 곧 패치 `r` 의 `j` 번째 top-k 픽이다). ⇒ 묻는 것은 **자리가 아니라 개수**다.
	static void _BuildExt(uint32 f)
	{
		_ext.Reset(0);
		double dense = 0.0;
		for (uint32 c = 0; c < kCand; ++c)
		{
			const float v = MLTWorld::Unit(MLTWorld::Hash(_seed * 613u + f * 7919u + c, MLTSalt::Start, 31u)) * _scale;
			_ext.Add(v); dense += (double)v * v;
		}
		if (!_Sparse()) return;
		// 결정적으로 고른 **서로 다른 8칸**만 남기고 나머지를 0 으로.
		uint8 keep[kCand];
		for (uint32 c = 0; c < kCand; ++c) keep[c] = 0u;
		uint32 got = 0u, probe = 0u;
		while (got < kSparse && probe < 4096u)
		{
			const uint32 c = MLTWorld::Hash(_seed * 977u + f * 131u + probe, MLTSalt::Start, 53u) % kCand;
			if (keep[c] == 0u) { keep[c] = 1u; ++got; }
			++probe;
		}
		double sp = 0.0;
		for (uint32 c = 0; c < kCand; ++c)
		{
			if (keep[c] == 0u) _ext.Data()[c] = 0.0f;
			else sp += (double)_ext[c] * _ext[c];
		}
		// ⭐ 노름 맞추기 — 희소 팔의 세기를 조밀 팔과 **같게** 한다.
		const float k = (sp > 1.0e-30) ? (float)(Sqrt((float)dense) / Sqrt((float)sp)) : 0.0f;
		for (uint32 c = 0; c < kCand; ++c) _ext.Data()[c] *= k;
	}

	static void _Push()
	{
		if (_pf >= kEncF) { _wait = MLTEvalGate::kDelay; _st = kReadP; return; }
		const uint32 per = _PerTick();
		for (uint32 i = 0; i < per && _pf < kEncF; ++i)
		{
			_E.SetFrame(_pf);
			if (!_E.Forward()) { _Fail("밀기 forward"); return; }
			if (_Inject())
			{
				_BuildExt(_pf);
				if (!_E.SetExtDMag(_ext)) { _Fail("주입"); return; }
			}
			else _E.ClearExtDMag();
			if (!_E.Backward() || !_E.AdamStep(1.0f)) { _Fail("밀기 bwd/adam"); return; }
			_E.ClearExtDMag();
			++_pf;
		}
	}

	static void _ReadP()
	{
		if (_wait > 0u) { --_wait; return; }
		if (!_E.ReadParams(_pr[_arm])) { _Fail("파라미터 리드백"); return; }
		if (++_arm < kArms) { _st = kEncInit; return; }
		_arm = 0u; _Judge();
	}

	static float _Rel(const Array<float>& x, const Array<float>& y)
	{
		const uint32 n = (x.Count() < y.Count()) ? x.Count() : y.Count();
		double d = 0.0, s = 0.0;
		for (uint32 i = 0; i < n; ++i)
		{
			const double e = (double)x[i] - (double)y[i];
			d += e * e; s += (double)x[i] * x[i];
		}
		return (float)(Sqrt((float)d) / (Sqrt((float)s) + 1.0e-20));
	}

	static void _Judge()
	{
		for (uint32 a = 0; a < kArms; ++a) _rel[a][_seed] = _Rel(_pr[0], _pr[a]);
		_seedOk[_seed] = true;
		LogA("[mlt] 🔩   씨앗 %2u · |A−B| **%.4g** · |A−C| **%.4g** · |A−D| **%.4g** · **|A−E| %.4g** · E/C **%.3g**\n",
			_seed, (double)_rel[1][_seed], (double)_rel[2][_seed], (double)_rel[3][_seed], (double)_rel[4][_seed],
			(_rel[2][_seed] > 0.0f) ? (double)(_rel[4][_seed] / _rel[2][_seed]) : 0.0);
		++_seed; _scaleOk = false; _st = kEncInit;
	}

	static void _Summary()
	{
		uint32 ok = 0u, hyg = 0u, t1 = 0u, tE = 0u;
		double mb = 0.0, mc = 0.0, md = 0.0, me = 0.0, mr = 0.0;
		for (uint32 s = 0; s < kSeeds; ++s)
		{
			if (!_seedOk[s]) continue;
			++ok;
			mb += _rel[1][s]; mc += _rel[2][s]; md += _rel[3][s]; me += _rel[4][s];
			if (_rel[2][s] > 0.0f) mr += (double)(_rel[4][s] / _rel[2][s]);
			if (_rel[1][s] == 0.0f) ++hyg;
			if (_rel[2][s] > 0.0f) ++t1;
			if (_rel[4][s] > 0.0f) ++tE;
		}
		if (ok > 0u) { mb /= ok; mc /= ok; md /= ok; me /= ok; mr /= ok; }
		const bool hOk = (hyg >= kSignPass);
		const bool p1 = (t1 >= kSignPass), pE = (tE >= kSignPass);

		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🔩 **회차 71 · 희소 주입이 범인인가** — 읽은 씨앗 %u/%u\n", ok, kSeeds);
		LogA("[mlt] 🔩   평균 — |A−B| **%.4g**(위생) · |A−C| **%.4g**(조밀·틱당1) · |A−D| **%.4g**(조밀·틱당8)\n",
			mb, mc, md);
		LogA("[mlt] 🔩   ⭐ **|A−E| %.4g**(희소 8칸 · 노름은 C 와 같다) · **E/C = %.3g**\n", me, mr);
		LogA("[mlt] 🔩   **위생** `|A−B| = 0` — **%u/%u** → %s · **재현** `|A−C|` ↔ 회차 70 의 0.1474\n",
			hyg, ok, hOk ? "통과" : "⛔");
		LogA("[mlt] 🔩   **표제** `|A−E| > 0` — **%u/%u**(필요 %u)\n", tE, kSeeds, kSignPass);
		if (!hOk || !p1)
			LogA("[mlt] 🔩   ⭐ 판정 = ⛔ **판정불가** — 위생 또는 조밀 팔의 재현이 안 선다\n");
		else if (pE)
			LogA("[mlt] 🔩   ⭐ 판정 = ⚠️ **희소성은 범인이 아니다**(8칸도 파라미터를 바꾼다) ⇒ 남은 후보 = **규모·배율**\n");
		else
			LogA("[mlt] 🔩   ⭐ 판정 = ✅ **희소성이 범인이다** — 8칸은 아무것도 못 바꾼다 ⇒ *왜* 를 묻는다\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		_E.Destroy(); _done = true;
	}

	static void _Fail(const char* why)
	{
		LogA("[mlt] 🔩 ⛔ %s (씨앗 %u · 팔 %u · 단계 %u · 프레임 %u)\n", why, _seed, _arm, _st, _pf);
		_E.Destroy(); _done = true;
	}
};
