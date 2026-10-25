// mltp3a2.cw — 🧭 회차 45 · 위치와 semantic identity 식별가능성 (`-mltp3a2`)
// 모델은 회차 44 그대로다. 고정 장면 수만 1→8로 바꿔 id가 갈리고 다시 쓰일 압력이 있는지 잰다.

using namespace PE;

class MLTP3A2
{
public:
	static void Tick(RHI* rhi)
	{
		if (_done || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltp3a2"))
		{
			LogA("[mlt] 🧭 회차 45는 **꺼져 있다**(`-mltp3a2`) — 8장 모두 semantic id 1종 · 붕괴 id 8/8 ⇒ 식별 ⛔\n");
			_done = true; return;
		}
		if (!_banner) { _Banner(); _banner = true; }
		if (_st == kInit) { if (!_Begin(rhi)) _Fail("준비 실패"); return; }
		if (_st == kEvalInit || _st == kEvalFinal) { _Eval(); return; }
		if (_st == kTrain) _Train();
	}

	static bool Done() { return _done; }

private:
	static constexpr uint32 kArms = 2u, kFrames = 8u, kSteps = 2400u;
	static constexpr uint32 kN = 1000u, kK = 8u, kSeed = 0u, kLiveSlotRows = 384u;
	static constexpr uint32 kBudget = 500000u, kLogEvery = 400u;
	static constexpr float kFlatRel = 1.0e-6f, kDrop = 0.5f;
	enum { kInit, kEvalInit, kTrain, kEvalFinal };

	inline static MLTP2Enc _E;
	inline static bool _done = false, _banner = false, _finite = true;
	inline static uint32 _arm = 0u, _st = kInit, _step = 0u, _ev = 0u, _nEval = 0u;
	inline static double _sumEval = 0.0;
	inline static float _first = 0.0f, _last = 0.0f;
	inline static uint32 _minDistinct = kK, _maxOor = 0u, _repeatMax = 0u;
	inline static Array<uint32> _seenFrames;
	inline static bool _pass[kArms] = { false, false };
	inline static float _armFirst[kArms] = { 0.0f, 0.0f }, _armLast[kArms] = { 0.0f, 0.0f };
	inline static uint32 _armMinDistinct[kArms] = { 0u, 0u }, _armRepeat[kArms] = { 0u, 0u };

	static const char* _ArmName() { return (_arm == 0u) ? "㈀ lr=3e-3" : "㈁ lr=0"; }

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🧭 **회차 45 · 위치/identity 식별가능성** — seed=%u · episode 0..%u · 고정 %u장\n",
			kSeed, kFrames - 1u, kFrames);
		LogA("[mlt] 🧭   모델 고정: N=%u k=%u rank=%u span=%u · %u스텝(장당 300회)\n",
			kN, kK, MLTP2Cfg::kFootRank, MLTP2Cfg::kFootSpan, kSteps);
		LogA("[mlt] 🧭   관문: 모든 장면 id≥4종 + 한 id가 ≥4/8장 반복 · 다양성 손실/새 커널 0\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

	static bool _Begin(RHI* rhi)
	{
		LogA("[mlt] 🧭 ── %s 시작 ──\n", _ArmName());
		if (_arm == 0u)
		{
			if (!_E.Setup(rhi, kFrames, kN, 0u, false, 0u, false, false, false, false, true)) return false;
			_E.SetK(kK); _E.SetSelectAbs(false);
			Array<float> fr, tg; fr.Reset(0); tg.Reset(0);
			ImageFormat::Bitmap bmp; Bytes packed;
			for (uint32 epi = 0u; epi < kFrames; ++epi)
			{
				MLTWorld w; w.Reset(kSeed, epi, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew); w.Step();
				if (!w.Render(bmp) || !MLTWorld::Pack(bmp, nullptr, packed)) return false;
				MLTP2Enc::AppendFrame(fr, tg, (const uint8*)packed.GetData());
			}
			if (!_E.WritePool(fr, tg, kFrames)) return false;
			const uint32 live = MLTP2Enc::GlobalLiveParams(kLiveSlotRows, kN);
			LogA("[mlt] 🧭 파라미터 — 할당 %u(%.2fM) · 살아있음 **%u**(%.3fM) ≤ %u → %s\n",
				_E.AllocParams(), (double)((float)_E.AllocParams() / 1.0e6f), live,
				(double)((float)live / 1.0e6f), kBudget, (live <= kBudget) ? "통과" : "⛔");
		}
		else if (!_E.ResetSeed()) return false;

		_finite = true; _step = 0u; _first = 0.0f; _last = 0.0f;
		_BeginEval(kEvalInit);
		return true;
	}

	static void _BeginEval(uint32 phase)
	{
		_st = phase; _ev = 0u; _nEval = 0u; _sumEval = 0.0;
		_minDistinct = kK; _maxOor = 0u; _repeatMax = 0u;
		_seenFrames.Reset(0); for (uint32 i = 0u; i < kN; ++i) _seenFrames.Add(0u);
	}

	static void _Eval()
	{
		const bool finalEval = (_st == kEvalFinal);
		if (_ev > 0u)
		{
			float mse = 0.0f; bool finite = true;
			if (!_E.ReadMse(mse, finite)) { _Fail("평가 MSE 리드백 실패"); return; }
			if (!finite || !(mse == mse) || mse > 1.0e30f) _finite = false;
			_sumEval += (double)mse; ++_nEval;
			if (finalEval && !_ReadFrameIds()) { _Fail("평가 활성 리드백 실패"); return; }
		}
		if (_ev < kFrames)
		{
			_E.SetFrame(_ev);
			if (!_E.Forward()) { _Fail("평가 forward 실패"); return; }
			++_ev; return;
		}

		const float mean = (_nEval == kFrames) ? (float)(_sumEval / (double)kFrames) : 0.0f;
		if (!finalEval)
		{
			_first = mean;
			LogA("[mlt] 🧭   %s 초기 8장 평균 MSE **%.6f**\n", _ArmName(), (double)_first);
			_st = kTrain; _step = 0u; return;
		}
		_last = mean;
		for (uint32 i = 0u; i < kN; ++i) if (_seenFrames[i] > _repeatMax) _repeatMax = _seenFrames[i];
		_JudgeArm();
	}

	static bool _ReadFrameIds()
	{
		Array<float> ids, mag;
		if (!_E.ReadAct(ids, mag) || ids.Count() != kK) return false;
		Array<uint8> hit; hit.Reset(0); for (uint32 i = 0u; i < kN; ++i) hit.Add(0u);
		uint32 distinct = 0u, oor = 0u;
		for (uint32 i = 0u; i < kK; ++i)
		{
			const float f = ids[i];
			if (!(f >= 0.0f) || f >= (float)(MLTP2Cfg::kPatches * kN)) { ++oor; continue; }
			const uint32 id = (uint32)f % kN;
			if (hit[id] == 0u) { hit.Data()[id] = 1u; ++distinct; ++_seenFrames.Data()[id]; }
		}
		if (distinct < _minDistinct) _minDistinct = distinct;
		if (oor > _maxOor) _maxOor = oor;
		return true;
	}

	static void _Train()
	{
		if (_step > 0u)
		{
			float mse = 0.0f; bool finite = true;
			if (!_E.ReadMse(mse, finite)) { _Fail("학습 MSE 리드백 실패"); return; }
			if (!finite || !(mse == mse) || mse > 1.0e30f) _finite = false;
			if (_step % kLogEvery == 0u || _step == kSteps)
				LogA("[mlt] 🧭   %s 스텝 %4u · 현재 장면 MSE %.6f\n", _ArmName(), _step, (double)mse);
		}
		if (_step >= kSteps) { _BeginEval(kEvalFinal); return; }

		_E.SetFrame(_step % kFrames);
		if (!_E.Forward() || !_E.Backward() || !_E.AdamStep((_arm == 0u) ? 1.0f : 0.0f))
		{ _Fail("학습 디스패치 실패"); return; }
		++_step;
	}

	static void _JudgeArm()
	{
		const uint32 live = MLTP2Enc::GlobalLiveParams(kLiveSlotRows, kN);
		const bool budget = live <= kBudget;
		const bool learned = _last < kDrop * _first;
		const bool diverse = _minDistinct >= 4u && _maxOor == 0u;
		const bool repeated = _repeatMax >= 4u;
		const bool flat = Abs(_last - _first) <= kFlatRel * Abs(_first);
		_pass[_arm] = budget && _finite && ((_arm == 0u) ? (learned && diverse && repeated) : flat);
		_armFirst[_arm] = _first; _armLast[_arm] = _last;
		_armMinDistinct[_arm] = _minDistinct; _armRepeat[_arm] = _repeatMax;

		LogA("[mlt] 🧭 ── %s 결과: 8장 평균 %.6f → %.6f · 유한 %s\n",
			_ArmName(), (double)_first, (double)_last, _finite ? "통과" : "⛔");
		LogA("[mlt] 🧭   장면별 최소 semantic id %u/8 · 한 id 최대 반복 %u/8장 · OOR 최대 %u\n",
			_minDistinct, _repeatMax, _maxOor);
		if (_arm == 0u)
			LogA("[mlt] 🧭   끝<0.5×처음 %s · 모든 장면 id≥4 %s · id 반복≥4/8 %s\n",
				learned ? "통과" : "⛔", diverse ? "통과" : "⛔", repeated ? "통과" : "⛔");
		else
			LogA("[mlt] 🧭   |끝−처음| %.3e ≤ 1e-6×처음 %.3e → %s\n",
				(double)Abs(_last - _first), (double)(kFlatRel * Abs(_first)), flat ? "통과" : "⛔");

		if (++_arm < kArms) { _st = kInit; return; }
		_Summary();
	}

	static void _Summary()
	{
		const bool ok = _pass[0] && _pass[1];
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🧭 **회차 45 · 위치/identity 식별 결과 — %s**\n", ok ? "✅ 통과" : "⛔ 실패");
		for (uint32 a = 0u; a < kArms; ++a)
			LogA("[mlt] 🧭   %s %.6f → %.6f · min-id %u · repeat %u/8\n",
				(a == 0u) ? "㈀" : "㈁", (double)_armFirst[a], (double)_armLast[a],
				_armMinDistinct[a], _armRepeat[a]);
		LogA("[mlt] 🧭   ⚠️ 고정 8장 식별 판정뿐이다. 종료 심사 전 일반화/P3 몸통으로 이어가지 않는다.\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		_E.Destroy(); _done = true;
	}

	static void _Fail(const char* why)
	{
		LogA("[mlt] 🧭 ⛔ %s\n", why);
		_E.Destroy(); _done = true;
	}
};
