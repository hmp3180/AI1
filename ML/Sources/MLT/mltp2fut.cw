// mltp2fut.cw — ⏳ 회차 48 · **P3-B1: 학습 표적을 시간 너머로 옮기면 identity 가 세지나** (`-mltp2fut`)
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 48 이다** — 여기 적는 것은 구현 계약뿐이다.
// ══════════════════════════════════════════════════════════════════════════════
//
// ★ **판정자를 바꾸지 않는 것이 이 회차의 핵이다** — 회차 46 의 짝 다섯(`MLTObjProbe`)을
//   **그 클래스 그대로** 쓴다. 같은 자로 재야 두 표적의 **마진이 견줘진다.**
//   ⚠️ 새 지표를 만들면 *"표적이 좋아졌다"* 와 *"자를 바꿨다"* 가 섞이고 숫자만 보면 안 보인다.
//   ★ 그리고 **팔 ㈀ 이 회차 46 재현 검사**로 `SetFramePair` 배관의 동일성을 실제로 검사한다.
//
// ── 바꾸는 것은 한 줄이다 ────────────────────────────────────────────────────
//   `MLTP2Enc::SetFramePair(입력f, 표적f)` — 지금까지 `SetFrame(i)` 이 입력과 표적을 **같은 칸**
//   에서 집었다. 그 둘을 가른다. ⚠️ **배관이지 모델이 아니다**(새 커널·파라미터·손실항 0).
//
// ── 팔 셋 ────────────────────────────────────────────────────────────────────
//   | 팔 | 표적 | 역할 |
//   |---|---|---|
//   | ㈀ | `f`        | **짝지은 기준선 + 회차 46 재현 검사** |
//   | ㈁ | `f + 2`    | 이 회차가 묻는 것 |
//   | ㈂ | `f + 2` · **`lr=0`** | 배관 평탄성(음성 대조군) |
//   ⚠️ 세 팔이 **같은 30칸**을 같은 순서로 돈다(`f = step % 30`) — 안 맞추면 *"표적이 좋아서"* 와
//     *"프레임을 두 장 덜 봐서"* 가 섞인다.
//
// ── 표제 = **회차 46 의 두 마진**(씨앗 안에서 짝지어 견준다) ──────────────────
//   `M_pos   = ㈀ − ㈂`  (위치 마진 — identity 가 자리를 건너나)
//   `M_shape = ㈀ − ㈁색`(모양 마진 — ⚠️ 회차 46 에서 **+0.1155** 뿐이던 그 얇은 자리)
//   ⇒ 두 마진 각각 **`㈁팔 > ㈀팔` 인 씨앗 ≥ 10/12** (`Q=2` · 단측 p=0.0193 < 0.025)

using namespace PE;

class MLTP2Fut
{
public:
	static void Tick(RHI* rhi)
	{
		if (_done || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltp2fut"))
		{
			LogA("[mlt] ⏳ 회차 48은 **꺼져 있다**(`-mltp2fut`) — 시간 표적(Δ=2)이 identity 마진을 세우나\n");
			_done = true; return;
		}
		if (!_banner) { _Banner(); _banner = true; }
		if (_arm >= kArms) { _Summary(); return; }
		if (_st == kSetup)   { _Begin(rhi); return; }
		if (_st == kEvalPre) { _Eval(false); return; }
		if (_st == kTrain)   { _Train(); return; }
		_Eval(true);
	}

	static bool Done() { return _done; }

private:
	// ── 등록값 — ⚠️ 학습은 회차 46 과 **글자 그대로 같다** ────────────────────
	static constexpr uint32 kSeeds  = 12u;
	static constexpr uint32 kFrames = 32u;
	static constexpr uint32 kSteps  = 1200u;
	static constexpr uint32 kN      = 1000u;
	static constexpr uint32 kK      = 8u;
	static constexpr uint32 kPerTick = 8u;
	static constexpr uint32 kDelta  = 2u;               // ⚠️ 회차 47 이 근거를 냈다(Δ 스윕 없음)
	static constexpr uint32 kSlots  = kFrames - kDelta; // 30 — 세 팔이 같은 칸을 돈다
	static constexpr uint32 kCells  = MLTObjProbe::kCells;
	static constexpr uint32 kArms   = 3u;
	static constexpr uint32 kSignPass = 10u;
	static constexpr float  kReproTol = 0.02f;          // ㈀ 이 회차 46 을 되짚는 허용폭
	static constexpr float  kFlatRel  = 1.0e-6f;
	// 회차 46 실측(재현 검사의 표적) — ㈎ ㈀ ㈁ ㈂ ㈃
	static constexpr float  kR46[kCells] = { 0.8018f, 0.6886f, 0.5731f, 0.4227f, 0.3336f };

	enum { kSetup, kEvalPre, kTrain, kEvalPost };

	inline static MLTP2Enc _E;
	inline static MLTObjProbe _P;
	inline static bool _done = false, _banner = false, _setup = false;
	inline static uint32 _arm = 0u, _seed = 0u, _st = kSetup, _step = 0u, _ev = 0u, _nMse = 0u;
	inline static double _sumMse = 0.0;
	inline static float _msePre = 0.0f, _msePost = 0.0f;
	inline static bool _finite = true;

	inline static float  _cell[kArms][kSeeds][kCells];
	inline static bool   _ok[kArms][kSeeds];
	inline static float  _flatPre[kSeeds], _flatPost[kSeeds];

	static const char* _ArmName()
	{
		return (_arm == 0u) ? "㈀ 표적 f" : ((_arm == 1u) ? "㈁ 표적 f+2" : "㈂ 표적 f+2 · lr=0");
	}
	static uint32 _ArmDelta() { return (_arm == 0u) ? 0u : kDelta; }
	static float  _ArmLr()    { return (_arm == 2u) ? 0.0f : 1.0f; }

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] ⏳ **회차 48 · P3-B1 — 학습 표적을 시간 너머로(Δ=%u)**\n", kDelta);
		LogA("[mlt] ⏳   학습은 회차 46 그대로: 씨앗 0..%u · 에피소드 0 · 프레임 %u · %u스텝 · N=%u k=%u\n",
			kSeeds - 1u, kFrames, kSteps, kN, kK);
		LogA("[mlt] ⏳   팔 셋: ㈀ 표적 f(재현 검사) · ㈁ 표적 f+%u · ㈂ 같은 호출 lr=0 · 같은 %u칸\n",
			kDelta, kSlots);
		LogA("[mlt] ⏳   표제: 위치 마진(㈀−㈂)과 모양 마진(㈀−㈁색)이 ㈁팔에서 커지나 · 각 %u/%u · Q=2\n",
			kSignPass, kSeeds);
		LogA("[mlt] ⏳   판정자는 `MLTObjProbe`(회차 46 과 **같은 클래스**) · 새 커널/파라미터/손실 0\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

	static void _Begin(RHI* rhi)
	{
		if (!_setup)
		{
			if (!_E.Setup(rhi, kFrames, kN)) { _Fail("준비 실패"); return; }
			_setup = true;
		}
		else if (!_E.ResetSeed()) { _Fail("되돌리기 실패"); return; }
		_E.SetK(kK); _E.SetSelectAbs(false);

		Array<float> fr, tg; fr.Reset(0); tg.Reset(0);
		_P.Reset(kK);
		ImageFormat::Bitmap bmp; Bytes packed;
		MLTWorld w; w.Reset(_seed, 0u, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
		for (uint32 f = 0; f < kFrames; ++f)
		{
			w.Step();
			if (!w.Render(bmp) || !MLTWorld::Pack(bmp, nullptr, packed)) { _Fail("Render/Pack 실패"); return; }
			MLTP2Enc::AppendFrame(fr, tg, (const uint8*)packed.GetData());
			_P.AddFrame(w);   // ⚠️ 판정 창구 — 학습 입력이 아니다
		}
		if (!_E.WritePool(fr, tg, kFrames)) { _Fail("풀 업로드 실패"); return; }

		// ⚠️ `_finite` 는 **되돌리지 않는다** — 어느 팔·어느 씨앗에서든 비유한이 한 번 나오면
		//   그 실행 전체의 위생이 깨진 것이다(씨앗마다 켜 두면 마지막 씨앗만 보게 된다).
		_step = 0u;
		_BeginEval(kEvalPre);
	}

	static void _BeginEval(uint32 phase) { _st = phase; _ev = 0u; _nMse = 0u; _sumMse = 0.0; }

	// ⚠️ 디스패치와 되읽기는 **한 틱 떨어진다**. 평가 forward 는 학습과 **같은 (입력, 표적) 짝**을
	//   쓴다 — 그래야 `lr=0` 평탄성이 학습이 보는 손실 위에서 성립한다.
	static void _Eval(bool post)
	{
		if (_ev > 0u)
		{
			float mse = 0.0f; bool fin = true;
			if (!_E.ReadMse(mse, fin)) { _Fail("평가 MSE 리드백 실패"); return; }
			if (!fin || !(mse == mse) || mse > 1.0e30f) _finite = false;
			// ⚠️⚠️ **평탄성은 학습이 보는 30칸에서만 잰다** — 사후 평가는 판정자 때문에 32칸을 도는데
			//   꼬리 두 칸은 표적이 없어 `f→f` 로 접힌다. 그 둘을 섞으면 「전/후 같은 것」이 깨진다.
			if (_ev - 1u < kSlots) { _sumMse += (double)mse; ++_nMse; }
			if (post)
			{
				Array<float> ids, mag;
				if (!_E.ReadAct(ids, mag)) { _Fail("활성 리드백 실패"); return; }
				if (!_P.FillIds(_ev - 1u, ids, kN)) { _Fail("활성 채우기 실패"); return; }
			}
		}
		const uint32 n = post ? kFrames : kSlots;
		if (_ev < n)
		{
			// ⚠️ 사후 평가는 **32프레임 전부**(판정자가 그것을 요구한다) · 표적은 학습과 같은 짝이다.
			//   ★ 선택(top-k)은 **입력 프레임만** 보므로 꼬리 두 칸의 표적 접힘은 판정에 안 닿는다.
			const uint32 f = _ev;
			const uint32 t = (f + _ArmDelta() < kFrames) ? (f + _ArmDelta()) : f;
			_E.SetFramePair(f, t);
			if (!_E.Forward()) { _Fail("평가 forward 실패"); return; }
			++_ev; return;
		}
		const float mean = (_nMse == 0u) ? 0.0f : (float)(_sumMse / (double)_nMse);
		if (!post) { _msePre = mean; _st = kTrain; _step = 0u; return; }
		_msePost = mean;
		_Score();
	}

	static void _Train()
	{
		for (uint32 i = 0; i < kPerTick && _step < kSteps; ++i)
		{
			const uint32 f = _step % kSlots;
			_E.SetFramePair(f, f + _ArmDelta());
			if (!_E.Forward() || !_E.Backward() || !_E.AdamStep(_ArmLr()))
			{ _Fail("학습 디스패치 실패"); return; }
			++_step;
		}
		if (_step >= kSteps) _BeginEval(kEvalPost);
	}

	static void _Score()
	{
		uint32 pairs[kCells];
		_ok[_arm][_seed] = _P.Score(_cell[_arm][_seed], pairs);
		if (_arm == 2u) { _flatPre[_seed] = _msePre; _flatPost[_seed] = _msePost; }

		LogA("[mlt] ⏳ %s 씨앗 %2u · 출현 %3u · ㈎%.4f ㈀%.4f ㈁%.4f ㈂%.4f ㈃%.4f · 마진 위치 **%+.4f** 모양 **%+.4f** · MSE %.5f→%.5f %s\n",
			_ArmName(), _seed, _P.Occurrences(),
			(double)_cell[_arm][_seed][MLTObjProbe::cUp],
			(double)_cell[_arm][_seed][MLTObjProbe::cSame],
			(double)_cell[_arm][_seed][MLTObjProbe::cCol],
			(double)_cell[_arm][_seed][MLTObjProbe::cPos],
			(double)_cell[_arm][_seed][MLTObjProbe::cFloor],
			(double)_MPos(_arm, _seed), (double)_MShape(_arm, _seed),
			(double)_msePre, (double)_msePost, _ok[_arm][_seed] ? "" : "⚠️ 짝 부족");

		++_seed;
		if (_seed >= kSeeds) { _ArmDone(); return; }
		_st = kSetup;
	}

	static float _MPos(uint32 a, uint32 s)
	{ return _cell[a][s][MLTObjProbe::cSame] - _cell[a][s][MLTObjProbe::cPos]; }
	static float _MShape(uint32 a, uint32 s)
	{ return _cell[a][s][MLTObjProbe::cSame] - _cell[a][s][MLTObjProbe::cCol]; }

	static void _ArmDone()
	{
		double m[kCells]; uint32 n = 0u;
		for (uint32 c = 0; c < kCells; ++c) m[c] = 0.0;
		for (uint32 s = 0; s < kSeeds; ++s)
		{
			if (!_ok[_arm][s]) continue;
			++n; for (uint32 c = 0; c < kCells; ++c) m[c] += (double)_cell[_arm][s][c];
		}
		if (n > 0u) for (uint32 c = 0; c < kCells; ++c) m[c] /= (double)n;
		LogA("[mlt] ⏳ ── %s 평균(읽은 %u/%u) — ㈎%.4f ㈀%.4f ㈁%.4f ㈂%.4f ㈃%.4f\n",
			_ArmName(), n, kSeeds, m[0], m[1], m[2], m[3], m[4]);
		if (_arm == 0u)
		{
			float worst = 0.0f;
			for (uint32 c = 0; c < kCells; ++c)
			{ const float d = Abs((float)m[c] - kR46[c]); if (d > worst) worst = d; }
			LogA("[mlt] ⏳    ⭐ 회차 46 재현 — 최대 |차| **%.4f** (허용 %.4f) → %s\n",
				(double)worst, (double)kReproTol, (worst <= kReproTol) ? "통과" : "⛔ 판정불가");
		}
		++_arm; _seed = 0u; _st = kSetup;
	}

	static void _Summary()
	{
		// ── 위생 ① ㈀ 재현 ─────────────────────────────────────────
		double m0[kCells]; uint32 n0 = 0u;
		for (uint32 c = 0; c < kCells; ++c) m0[c] = 0.0;
		for (uint32 s = 0; s < kSeeds; ++s)
		{
			if (!_ok[0][s]) continue;
			++n0; for (uint32 c = 0; c < kCells; ++c) m0[c] += (double)_cell[0][s][c];
		}
		if (n0 > 0u) for (uint32 c = 0; c < kCells; ++c) m0[c] /= (double)n0;
		float worst = 0.0f;
		for (uint32 c = 0; c < kCells; ++c)
		{ const float d = Abs((float)m0[c] - kR46[c]); if (d > worst) worst = d; }
		const bool repro = (worst <= kReproTol) && (n0 > 0u);

		// ── 위생 ② ㈂ 평탄 ─────────────────────────────────────────
		uint32 flat = 0u;
		for (uint32 s = 0; s < kSeeds; ++s)
			if (Abs(_flatPost[s] - _flatPre[s]) <= kFlatRel * Abs(_flatPre[s])) ++flat;
		const bool flatOk = (flat == kSeeds) && _finite;

		// ── 표제 둘 — 씨앗 안에서 짝지어 ────────────────────────────
		uint32 t1 = 0u, t2 = 0u, readable = 0u;
		double mp0 = 0.0, mp1 = 0.0, ms0 = 0.0, ms1 = 0.0;
		for (uint32 s = 0; s < kSeeds; ++s)
		{
			if (!_ok[0][s] || !_ok[1][s]) continue;
			++readable;
			mp0 += (double)_MPos(0u, s); mp1 += (double)_MPos(1u, s);
			ms0 += (double)_MShape(0u, s); ms1 += (double)_MShape(1u, s);
			if (_MPos(1u, s)   > _MPos(0u, s))   ++t1;
			if (_MShape(1u, s) > _MShape(0u, s)) ++t2;
		}
		if (readable > 0u) { mp0 /= readable; mp1 /= readable; ms0 /= readable; ms1 /= readable; }

		const bool p1 = (t1 >= kSignPass), p2 = (t2 >= kSignPass);
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] ⏳ **회차 48 · P3-B1 결과** — 짝지어 읽은 씨앗 %u/%u\n", readable, kSeeds);
		LogA("[mlt] ⏳   위생① ㈀ 회차 46 재현 — 최대 |차| **%.4f** ≤ %.4f → %s\n",
			(double)worst, (double)kReproTol, repro ? "통과" : "⛔");
		LogA("[mlt] ⏳   위생② ㈂ lr=0 평탄 — **%u/%u** · 전 구간 유한 %s → %s\n",
			flat, kSeeds, _finite ? "예" : "아니오", flatOk ? "통과" : "⛔");
		LogA("[mlt] ⏳   위치 마진(㈀−㈂) — ㈀팔 **%+.4f** → ㈁팔 **%+.4f**\n", mp0, mp1);
		LogA("[mlt] ⏳   모양 마진(㈀−㈁색) — ㈀팔 **%+.4f** → ㈁팔 **%+.4f**\n", ms0, ms1);
		if (!repro || !flatOk)
			LogA("[mlt] ⏳   ⭐ 판정 = ⛔ **판정불가**(위생) — 배관만 읽고 손잡이를 훑지 않는다.\n");
		else
		{
			LogA("[mlt] ⏳   **표제① 위치 마진 ↑ — %u/%u**(필요 %u) → %s\n", t1, kSeeds, kSignPass, p1 ? "통과" : "⛔");
			LogA("[mlt] ⏳   **표제② 모양 마진 ↑ — %u/%u**(필요 %u) → %s\n", t2, kSeeds, kSignPass, p2 ? "통과" : "⛔");
			if (p1 && p2)
				LogA("[mlt] ⏳   ⭐ 판정 = ✅ **시간 표적이 identity 를 세운다** ⇒ 회차 49 = 미래 표적 아래의 압축 관문\n");
			else if (p1)
				LogA("[mlt] ⏳   ⭐ 판정 = ⚠️ **위치 불변성만 산다** ⇒ 회차 49 = 모양 마진이 얇은 원인을 세계 심사에 올린다\n");
			else
				LogA("[mlt] ⏳   ⭐ 판정 = ⛔ **오라클 이득이 학습으로 안 넘어온다** ⇒ 재구성 표적 계열을 닫고 회차 49 = P3 몸통\n");
		}
		LogA("[mlt] ⏳   ⚠️ 고정 32프레임 **학습 코퍼스**의 진단이다 — 일반화·P3 경험 성공으로 인용하지 않는다.\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		_E.Destroy(); _done = true;
	}

	static void _Fail(const char* why)
	{
		LogA("[mlt] ⏳ ⛔ %s (팔 %u · 씨앗 %u)\n", why, _arm, _seed);
		_E.Destroy(); _done = true;
	}
};
