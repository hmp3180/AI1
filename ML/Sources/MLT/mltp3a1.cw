// mltp3a1.cw — 🌐 회차 44 · 이동 가능한 전역 발자국의 고정 프레임 조립 (`-mltp3a1`)
//
// 사전등록은 `mltlog_1.md` 회차 44가 정본이다. 씨앗/프레임/폭/rank/k/lr를 여기서 더 흔들지 않는다.

using namespace PE;

class MLTP3A1
{
public:
	static void Tick(RHI* rhi)
	{
		if (_done || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltp3a1"))
		{
			LogA("[mlt] 🌐 회차 44는 **꺼져 있다**(`-mltp3a1`) — 0.199761→0.055084이나 semantic id 1/8종 ⇒ 비붕괴 ⛔\n");
			_done = true; return;
		}
		if (!_banner) { _Banner(); _banner = true; }
		if (!_begun) { if (!_Begin(rhi)) _Fail("준비 실패"); return; }

		// 이번 Tick에서 읽는 것은 지난 Tick의 forward 결과다.
		if (_step > 0u)
		{
			float mse = 0.0f; bool finite = true;
			if (!_E.ReadMse(mse, finite)) { _Fail("MSE 리드백 실패"); return; }
			_Record(mse, finite);
		}
		if (_step >= kSteps) { _JudgeArm(); return; }

		if (!_E.Forward() || !_E.Backward() || !_E.AdamStep((_arm == 0u) ? 1.0f : 0.0f))
		{
			LogA("[mlt] 🌐 스텝 실패(%s · %u)\n", _ArmName(), _step);
			_Fail("전역 조립 디스패치 실패"); return;
		}
		++_step;
	}

	static bool Done() { return _done; }

private:
	static constexpr uint32 kArms = 2u, kSteps = 1200u, kN = 1000u, kK = 8u;
	static constexpr uint32 kSeed = 0u, kEpisode = 0u, kLiveSlotRows = 384u;
	static constexpr uint32 kBudget = 500000u, kLogEvery = 200u;
	static constexpr float kFlatRel = 1.0e-6f, kDrop = 0.5f;

	inline static MLTP2Enc _E;
	inline static bool _done = false, _banner = false, _begun = false;
	inline static uint32 _arm = 0u, _step = 0u, _read = 0u;
	inline static float _first = 0.0f, _last = 0.0f;
	inline static bool _finite = true, _pass[kArms] = { false, false };
	inline static float _armFirst[kArms] = { 0.0f, 0.0f }, _armLast[kArms] = { 0.0f, 0.0f };
	inline static uint32 _distinct[kArms] = { 0u, 0u };

	static const char* _ArmName() { return (_arm == 0u) ? "㈀ lr=3e-3" : "㈁ lr=0"; }

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🌐 **회차 44 · P3-A1 전역 발자국 조립** — seed=%u episode=%u · 고정 프레임 · %u스텝\n",
			kSeed, kEpisode, kSteps);
		LogA("[mlt] 🌐   N=%u k=%u rank=%u span=%u · 팔 lr=3e-3 / lr=0 · 스윕 없음\n",
			kN, kK, MLTP2Cfg::kFootRank, MLTP2Cfg::kFootSpan);
		LogA("[mlt] 🌐   ⚠️ 고정 프레임 과적합 조립만 잰다 — 절대 성능·일반화 주장이 아님\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

	static bool _Begin(RHI* rhi)
	{
		LogA("[mlt] 🌐 ── %s 시작 ──\n", _ArmName());
		if (_arm == 0u)
		{
			if (!_E.Setup(rhi, 1u, kN, 0u, false, 0u, false, false, false, false, true)) return false;
			_E.SetK(kK); _E.SetSelectAbs(false);

			ImageFormat::Bitmap bmp; Bytes packed;
			MLTWorld w; w.Reset(kSeed, kEpisode, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
			w.Step();
			if (!w.Render(bmp) || !MLTWorld::Pack(bmp, nullptr, packed)) return false;
			if (!_E.UploadFrame((const uint8*)packed.GetData())) return false;

			const uint32 live = MLTP2Enc::GlobalLiveParams(kLiveSlotRows, kN);
			LogA("[mlt] 🌐 파라미터 — 할당 %u(%.2fM) · 살아있음 **%u**(%.3fM) ≤ %u → %s\n",
				_E.AllocParams(), (double)((float)_E.AllocParams() / 1.0e6f), live,
				(double)((float)live / 1.0e6f), kBudget, (live <= kBudget) ? "통과" : "⛔");
		}
		else if (!_E.ResetSeed()) return false;

		_step = 0u; _read = 0u; _first = 0.0f; _last = 0.0f; _finite = true;
		_begun = true;
		return true;
	}

	static void _Record(float mse, bool finite)
	{
		if (!finite || !(mse == mse) || mse > 1.0e30f) _finite = false;
		if (_read == 0u) _first = mse;
		_last = mse; ++_read;
		if (_read == 1u || _read % kLogEvery == 0u || _read == kSteps)
			LogA("[mlt] 🌐   %s 스텝 %4u · MSE %.6f\n", _ArmName(), _read, (double)mse);
	}

	static void _JudgeArm()
	{
		uint32 distinct = 0u, oor = 0u; float magMax = 0.0f;
		if (!_E.ReadActStats(distinct, oor, magMax)) { _Fail("활성 리드백 실패"); return; }
		const uint32 live = MLTP2Enc::GlobalLiveParams(kLiveSlotRows, kN);
		const bool budget = live <= kBudget;
		const bool flat = Abs(_last - _first) <= kFlatRel * Abs(_first);
		const bool learned = _last < kDrop * _first;
		const bool diverse = distinct >= 4u && oor == 0u;
		_pass[_arm] = budget && _finite && ((_arm == 0u) ? (learned && diverse) : flat);
		_armFirst[_arm] = _first; _armLast[_arm] = _last; _distinct[_arm] = distinct;

		LogA("[mlt] 🌐 ── %s 결과: %.6f → %.6f · 유한 %s · semantic id %u/8 · OOR %u\n",
			_ArmName(), (double)_first, (double)_last, _finite ? "통과" : "⛔", distinct, oor);
		if (_arm == 0u)
			LogA("[mlt] 🌐   마지막 < 0.5×처음(%.6f) → %s · 서로 다른 id≥4 → %s\n",
				(double)(kDrop * _first), learned ? "통과" : "⛔", diverse ? "통과" : "⛔");
		else
			LogA("[mlt] 🌐   |끝−처음| %.3e ≤ 1e-6×처음 %.3e → %s\n",
				(double)Abs(_last - _first), (double)(kFlatRel * Abs(_first)), flat ? "통과" : "⛔");

		if (++_arm < kArms) { _begun = false; return; }
		_Summary();
	}

	static void _Summary()
	{
		const bool ok = _pass[0] && _pass[1];
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🌐 **회차 44 · P3-A1 결과 — %s**\n", ok ? "✅ 조립·비붕괴 통과" : "⛔ 실패");
		LogA("[mlt] 🌐   ㈀ %.6f → %.6f · semantic id %u/8\n",
			(double)_armFirst[0], (double)_armLast[0], _distinct[0]);
		LogA("[mlt] 🌐   ㈁ %.6f → %.6f · semantic id %u/8\n",
			(double)_armFirst[1], (double)_armLast[1], _distinct[1]);
		LogA("[mlt] 🌐   ⚠️ 고정 프레임 조립 결과뿐이다. 종료 심사 전 다음 P3 단계로 이어가지 않는다.\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		_E.Destroy(); _done = true;
	}

	static void _Fail(const char* why)
	{
		LogA("[mlt] 🌐 ⛔ %s\n", why);
		_E.Destroy(); _done = true;
	}
};
