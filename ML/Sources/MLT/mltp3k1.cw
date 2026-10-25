// mltp3k1.cw — 🔩 회차 69 · **어디서 끊기나 — 사다리 진단** (`-mltp3k1`)
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 69 이다.**
// ⚠️ 상위 = **경험이 인코딩을 바꾸나** · **판정 회차가 아니다**(배관·진단).
// ══════════════════════════════════════════════════════════════════════════════
//
// ⭐ **소스를 읽어 둘을 먼저 확정했다**(측정 전):
//   ㈀ `act_topk.cs.hlsl` 의 `oBase = r * gP.k` ⇒ **stride 는 `k`(=8)** 이다 ⇒ 회차 67·68 의
//     `sub(count = kPatches·k)` 는 **옳았다**(회차 68 이 적은 「배치 의심」은 여기서 죽는다).
//   ㈁ `_rank == 0` 에서 `dScore` 는 ⑨ `dH = dScore·Wd` → `dPatch` → ⑪ `dSlot`, 그리고
//     ⑩ `dWd = dScoreᵀ·h` 로 **파라미터 기울기 두 곳에 닿는다** ⇒ 배선상 효과가 0 일 이유가 없다.
//
// ── 🪜 사다리 — **처음 0 이 되는 칸이 범인이다** ─────────────────────────
//   ① `‖Δ dMag‖`  ② `‖Δ dScore‖`  ③ `‖Δ g‖`(파라미터 기울기)  ④ `‖Δ p‖`(파라미터)
//
// ── 팔 셋 — ⚠️ **잡음 바닥을 실측한다**(문턱을 손으로 안 정한다) ─────────
//   A 주입 없이 · B 주입 · **C 주입 없이(= A 와 같다)** ⇒ `|A−C|` 가 **잡음 바닥**이다.
//
// ⚠️⚠️ **리드백 규약을 지킨다** — 디스패치 뒤 `kDelay` 틱을 비우고 읽는다
//   (회차 68 의 `Δp` 오염이 정확히 그 자리였다: 얼린 팔이 `0.0455 ≠ 0` 이었다).

using namespace PE;

class MLTP3K1
{
public:
	static void Tick(RHI* rhi)
	{
		if (_done || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltp3k1"))
		{
			LogA("[mlt] 🔩 회차 69는 **꺼져 있다**(`-mltp3k1`) — 사다리 진단(어디서 끊기나)\n");
			_done = true; return;
		}
		if (!_banner) { _Banner(); _banner = true; }
		if (_seed >= kSeeds) { _Summary(); return; }
		switch (_st)
		{
		case kEncInit:  _EncBegin(rhi); return;
		case kEncTrain: _EncTrain();    return;
		case kSettle:   if (_wait > 0u) { --_wait; } else _st = kStep; return;
		case kStep:     _Step();        return;
		case kReadG:    _ReadG();       return;
		case kReadP:    _ReadP();       return;
		default: return;
		}
	}

	static bool Done() { return _done; }

private:
	static constexpr uint32 kSeeds = 12u;
	static constexpr uint32 kEncF = 32u, kEncSteps = 1200u, kEncPerTick = 8u;
	static constexpr uint32 kN = 250u, kLocal = 8u;
	static constexpr uint32 kCand = MLTP2Cfg::kPatches * kLocal;   // 512
	static constexpr uint32 kArms = 3u;                            // A · B · C
	static constexpr uint32 kRungs = 4u;
	static constexpr uint32 kSignPass = 10u;
	static constexpr float  kBeat = 10.0f;                         // |A−B| > 10 × |A−C|

	enum { kEncInit, kEncTrain, kSettle, kStep, kReadG, kReadP };

	inline static MLTP2Enc _E;
	inline static bool _done = false, _banner = false, _encSetup = false;
	inline static uint32 _seed = 0u, _st = kEncInit, _step = 0u, _arm = 0u, _wait = 0u;
	inline static Array<float> _dm[kArms], _ds[kArms], _gr[kArms], _pr[kArms];
	inline static Array<float> _ext;
	// 사다리 — 씨앗마다 칸별 (|A−B|, |A−C|)
	inline static float _ab[kRungs][kSeeds], _ac[kRungs][kSeeds];
	inline static bool  _seedOk[kSeeds];

	static const char* _ArmName()
	{ return (_arm == 0u) ? "A 주입없이" : ((_arm == 1u) ? "B 주입" : "C 주입없이(잡음)"); }

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🔩 **회차 69 · 사다리 진단 — 어디서 끊기나**(⚠️ 판정 회차 아님)\n");
		LogA("[mlt] 🔩   ① dMag → ② dScore → ③ 파라미터 기울기 → ④ 파라미터 · **처음 0 이 되는 칸이 범인**\n");
		LogA("[mlt] 🔩   팔 셋 A/B/C — ⭐ **C 가 A 와 같아서 `|A−C|` 가 잡음 바닥**(문턱을 손으로 안 정한다)\n");
		LogA("[mlt] 🔩   ⚠️ 소스로 확정: stride = **k(=8)** · `dScore → dWd·dSlot` 경로 **있다**\n");
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
		Array<float> fr, tg; fr.Reset(0); tg.Reset(0);
		ImageFormat::Bitmap bmp; Bytes packed;
		MLTWorld w; w.Reset(_seed, 0u, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
		for (uint32 f = 0; f < kEncF; ++f)
		{
			w.Step();
			if (!w.Render(bmp) || !MLTWorld::Pack(bmp, nullptr, packed)) { _Fail("Render/Pack"); return; }
			MLTP2Enc::AppendFrame(fr, tg, (const uint8*)packed.GetData());
		}
		if (!_E.WritePool(fr, tg, kEncF)) { _Fail("풀 업로드"); return; }
		_step = 0u; _st = kEncTrain;
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
		// ⚠️⚠️ **리드백 규약** — 프리트레인 디스패치가 제출·완료될 때까지 틱을 비운다.
		//   ★ 회차 68 이 이것을 안 해서 얼린 팔의 `Δp` 가 0.0455 로 나왔다.
		_wait = MLTEvalGate::kDelay; _st = kSettle;
	}

	// ── 한 스텝: Forward → (주입) → Backward → 읽기 → AdamStep → 읽기 ──
	static void _Step()
	{
		_E.SetFrame(0u);
		if (!_E.Forward()) { _Fail("forward"); return; }
		if (_arm == 1u)
		{
			// ⚠️ 시험 벡터는 **몸통 기울기가 아니다** — 배관 진단이라 결정적 해시를 쓴다.
			//   크기는 팔 A 의 `‖dMag‖/2`(회차 68 의 판정 ① 과 같은 방식).
			double su = 0.0, sd = 0.0;
			_ext.Reset(0);
			for (uint32 c = 0; c < kCand; ++c)
			{
				const float u = MLTWorld::Unit(MLTWorld::Hash(_seed * 613u + c, MLTSalt::Start, 31u));
				_ext.Add(u); su += (double)u * u;
				sd += (double)_dm[0][c] * _dm[0][c];
			}
			const float nu = Sqrt((float)su), nd = Sqrt((float)sd);
			const float sc = (nu > 1.0e-20f) ? (0.5f * nd / nu) : 1.0f;
			for (uint32 c = 0; c < kCand; ++c) _ext.Data()[c] *= sc;
			if (!_E.SetExtDMag(_ext)) { _Fail("주입"); return; }
		}
		else _E.ClearExtDMag();
		if (!_E.Backward()) { _Fail("backward"); return; }
		_E.ClearExtDMag();
		_wait = MLTEvalGate::kDelay; _st = kReadG;
	}

	static void _ReadG()
	{
		if (_wait > 0u) { --_wait; return; }
		if (!_E.ReadDMag(_dm[_arm]) || !_E.ReadDScore(_ds[_arm]) || !_E.ReadGrad(_gr[_arm]))
		{ _Fail("사다리 ①②③ 리드백"); return; }
		if (!_E.AdamStep(1.0f)) { _Fail("AdamStep"); return; }
		_wait = MLTEvalGate::kDelay; _st = kReadP;
	}

	static void _ReadP()
	{
		if (_wait > 0u) { --_wait; return; }
		if (!_E.ReadParams(_pr[_arm])) { _Fail("파라미터 리드백"); return; }
		if (++_arm < kArms) { _st = kEncInit; return; }
		_arm = 0u; _Judge();
	}

	// 상대 차이 `‖x − y‖ / (‖x‖ + 1e-20)`
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
		_ab[0][_seed] = _Rel(_dm[0], _dm[1]); _ac[0][_seed] = _Rel(_dm[0], _dm[2]);
		_ab[1][_seed] = _Rel(_ds[0], _ds[1]); _ac[1][_seed] = _Rel(_ds[0], _ds[2]);
		_ab[2][_seed] = _Rel(_gr[0], _gr[1]); _ac[2][_seed] = _Rel(_gr[0], _gr[2]);
		_ab[3][_seed] = _Rel(_pr[0], _pr[1]); _ac[3][_seed] = _Rel(_pr[0], _pr[2]);
		_seedOk[_seed] = true;
		LogA("[mlt] 🔩   씨앗 %2u · |A−B| ① **%.4g** ② **%.4g** ③ **%.4g** ④ **%.4g**  |  |A−C| %.2g / %.2g / %.2g / %.2g\n",
			_seed, (double)_ab[0][_seed], (double)_ab[1][_seed], (double)_ab[2][_seed], (double)_ab[3][_seed],
			(double)_ac[0][_seed], (double)_ac[1][_seed], (double)_ac[2][_seed], (double)_ac[3][_seed]);
		++_seed; _st = kEncInit;
	}

	static void _Summary()
	{
		uint32 alive[kRungs]; double mb[kRungs], mc[kRungs];
		for (uint32 r = 0; r < kRungs; ++r) { alive[r] = 0u; mb[r] = 0.0; mc[r] = 0.0; }
		uint32 ok = 0u;
		for (uint32 s = 0; s < kSeeds; ++s)
		{
			if (!_seedOk[s]) continue;
			++ok;
			for (uint32 r = 0; r < kRungs; ++r)
			{
				mb[r] += _ab[r][s]; mc[r] += _ac[r][s];
				const bool live = (_ac[r][s] <= 0.0f) ? (_ab[r][s] > 0.0f)
				                                      : (_ab[r][s] > kBeat * _ac[r][s]);
				if (live) ++alive[r];
			}
		}
		if (ok > 0u) for (uint32 r = 0; r < kRungs; ++r) { mb[r] /= ok; mc[r] /= ok; }
		const char* nm[kRungs] = { "① dMag", "② dScore", "③ 기울기", "④ 파라미터" };
		uint32 firstDead = kRungs;
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🔩 **회차 69 · 사다리 진단** — 읽은 씨앗 %u/%u\n", ok, kSeeds);
		for (uint32 r = 0; r < kRungs; ++r)
		{
			const bool live = (alive[r] >= kSignPass);
			if (!live && firstDead == kRungs) firstDead = r;
			LogA("[mlt] 🔩   %s — |A−B| **%.4g** ↔ 잡음 |A−C| **%.3g** · 살아있음 **%u/%u** → %s\n",
				nm[r], mb[r], mc[r], alive[r], ok, live ? "살았다" : "⛔ 끊겼다");
		}
		if (firstDead == kRungs)
			LogA("[mlt] 🔩   ⭐ 판정 = ⭐ **네 칸 다 살았다 — 배관은 멀쩡하다** ⇒ 회차 68 의 `㈂≡㈁` 은 **교대 루프의 버그**다\n");
		else
			LogA("[mlt] 🔩   ⭐ 판정 = ⛔ **%s 에서 끊긴다** — 범인이 그 자리다\n", nm[firstDead]);
		LogA("[mlt] 🔩   ⚠️ 시험 벡터는 **몸통 기울기가 아니다**(결정적 해시 · ‖dMag‖/2) — 배관만 본다\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		_E.Destroy(); _done = true;
	}

	static void _Fail(const char* why)
	{
		LogA("[mlt] 🔩 ⛔ %s (씨앗 %u · 팔 %u · 단계 %u)\n", why, _seed, _arm, _st);
		_E.Destroy(); _done = true;
	}
};
