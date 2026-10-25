// mltp3c0.cw — 🔩 회차 49 · **몸통의 어휘를 연다** (`-mltp3c0`)
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 49 다.**
// ⚠️⚠️ **판정 라운드가 아니라 배관 회차다** — 세계·표현·경험 학습에 대해 **아무 말도 하지 않는다.**
//   관문은 전부 「옛 것과 같은가」이고, `MLT.md` 가 *"✅ 두 줄은 라운드가 아니다(배관과 조립)"*
//   라고 적어 둔 그 종류다. ★ 그래도 번호를 준다 — 실행됐고 결과가 있으므로.
// ══════════════════════════════════════════════════════════════════════════════
//
// ★ **왜 어휘를 여나** — 지금 몸통의 심볼 어휘는 **셋**(`kAxes` = P1 의 상태 축)이고
//   `[N,A]·[A,D]` 원핫 gemm 으로 얹혀 있다. P3 의 활성 토큰은 `320 + N` 대역이라 어휘가 1000+ 인데
//   원핫은 `[N,V]`(수 MB) · gemm 이 `N·D·V`(수억 MAC)라 **소박한 삼중 루프로는 못 돈다.**
//   ⇒ `embed` 게더로 바꾼다. 그 커널은 **이미 판정 ①② 를 통과했다** ⇒ **새 GPU 커널 0개.**
//
// ── 관문 셋 ────────────────────────────────────────────────────────────────
//   ① ⭐ **비트 동일** — `V_sym=3 · V_out=65` 에서 원핫 경로 ↔ `embed` 경로의 **손실 수열이
//      비트까지 같아야** 한다. 두 경로는 수학적으로 같은 식이고 **누산 순서까지 같다**:
//        · fwd  원핫 합 = `0 + … + Sym[a][d] + … + 0` (정확) ↔ 게더가 그 값을 그대로 쓴다
//        · bwd  `dSym[a] = Σ_n onehot·dX` 는 `n` 오름차순 · `embed_bwd` 도 같은 순서로 맞는 행만
//      ★ **이 관문 하나가 판정 ②·① 를 포섭한다** — `dSym` 이 틀리면 파라미터가 갈리고 수열이 어긋난다.
//      ⚠️ **허용폭을 두지 않는다.** 어긋나면 ㉠ 누산 순서 → ㉡ 배선 순으로 원인을 가른다.
//   ② **어휘를 늘려도 사나** — `V_sym=64 · V_out=128`. ⚠️ 여기서는 비트 동일이 **아닌 것이 정상**이다
//      (표가 커지면 초기화 자리가 밀린다). 관문은 **정규화 손실** `last / ln(V_out) ≤ 0.10` 이
//      **두 팔 다** 성립하는가다. ★ 균등 예측의 손실이 `ln(V_out)` 이라 그것이 **팔 사이 같은 자**다.
//   ③ **P0/P1 회귀** — 늘 도는 판정 ③(`MLTFit`)이 옛 값을 그대로 낸다. ⚠️ 그쪽은 이제 **기본이
//      `embed` 경로**라 그 자체가 회귀 검사다(기본값을 원핫으로 두면 이 검사가 사라진다).

using namespace PE;

class MLTP3C0
{
public:
	static void Tick(RHI* rhi)
	{
		if (_done || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltp3c0"))
		{
			LogA("[mlt] 🔩 회차 49는 **꺼져 있다**(`-mltp3c0`) — 몸통 어휘 열기(비트 동일 + 확장 생존)\n");
			_done = true; return;
		}
		if (!_banner) { _Banner(); _banner = true; }
		if (_arm >= kArms) { _Summary(); return; }
		if (!_begun) { if (!_Begin(rhi)) { _Fail("준비 실패"); } return; }

		// ⚠️ 지금 읽는 손실은 **지난 프레임 forward** 의 것이다(`MLTFit` 과 같은 관용구).
		if (_step > 0u)
		{
			float ls = 0.0f;
			if (!_M.ReadLoss(ls)) { _Fail("손실 리드백 실패"); return; }
			_Record(ls);
		}
		if (_step >= kSteps) { _ArmDone(); return; }
		if (!_M.Forward() || !_M.Backward() || !_M.AdamStep(1.0f)) { _Fail("스텝 실패"); return; }
		++_step;
	}

	static bool Done() { return _done; }

private:
	static constexpr uint32 kArms  = 3u;
	static constexpr uint32 kSteps = 300u;          // 판정 ③ 과 같은 길이
	static constexpr float  kMemo  = 0.10f;         // 관문 ② — 균등 손실의 10분의 1
	// 팔마다 `(심볼 어휘, 출력 어휘, embed 경로인가)`
	static constexpr uint32 kSym[kArms] = { MLTModelCfg::kAxes, MLTModelCfg::kAxes, 64u };
	static constexpr uint32 kOut[kArms] = { MLTModelCfg::kBuckets, MLTModelCfg::kBuckets, 128u };
	static constexpr bool   kEmb[kArms] = { false, true, true };

	inline static MLTModel _M;
	inline static bool _done = false, _banner = false, _begun = false, _finite = true;
	inline static uint32 _arm = 0u, _step = 0u, _read = 0u, _mismatch = 0u, _firstBad = 0u;
	inline static float _first[kArms] = { 0.0f }, _last[kArms] = { 0.0f };
	inline static Array<float> _curve0;             // 팔 ㈀ 의 손실 수열(비트 비교의 기준)
	inline static Array<float> _cur;

	static const char* _ArmName()
	{
		return (_arm == 0u) ? "㈀ 원핫 V=3/65" : ((_arm == 1u) ? "㈁ embed V=3/65" : "㈂ embed V=64/128");
	}

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🔩 **회차 49 · 몸통의 어휘를 연다**(⚠️ 판정 라운드가 아니라 **배관 회차**)\n");
		LogA("[mlt] 🔩   ㈀ 원핫 ↔ ㈁ embed 를 **비트 동일**로 · ㈂ 는 어휘를 늘려도 사나\n");
		LogA("[mlt] 🔩   고정 배치 %u스텝 · 새 GPU 커널 0 · 모델 수치 변경 0\n", kSteps);
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

	static bool _Begin(RHI* rhi)
	{
		LogA("[mlt] 🔩 ── %s 시작 ──\n", _ArmName());
		if (!_M.Setup(rhi, kSym[_arm], kOut[_arm])) return false;
		_M.SetSymbolPath(kEmb[_arm]);
		if (_M.UsesEmbed() != kEmb[_arm])
		{ LogA("[mlt] 🔩 ⛔ 심볼 경로가 요청과 다르다(요청 %u · 실제 %u)\n",
			kEmb[_arm] ? 1u : 0u, _M.UsesEmbed() ? 1u : 0u); return false; }

		// ⚠️ 배치는 **판정 ③ 과 글자 그대로 같다** — 새 배치를 만들면 그 차이가 판정에 섞인다.
		typedef MLTModelCfg C;
		Array<float> val, tgt; val.Reset(0); tgt.Reset(0);
		for (uint32 b = 0; b < C::kBatch; ++b)
			for (uint32 t = 0; t < C::kCtx; ++t)
				val.Add(Sin(0.7f * (float)t + 1.3f * (float)b));
		for (uint32 b = 0; b < C::kBatch; ++b)
			for (uint32 t = 0; t < C::kCtx; ++t)
			{
				const uint32 nt = (t + 1u < C::kCtx) ? (t + 1u) : t;
				tgt.Add((float)_Bucket(val[b * C::kCtx + nt]));
			}
		if (!_M.Upload(val, tgt)) { LogA("[mlt] 🔩 배치 업로드 실패\n"); return false; }

		LogA("[mlt] 🔩   파라미터 %u · 심볼어휘 %u · 출력어휘 %u · 경로 %s\n",
			_M.ParamTotal(), _M.SymVocab(), _M.OutVocab(), _M.UsesEmbed() ? "embed" : "원핫");
		_step = 0u; _read = 0u; _finite = true; _cur.Reset(0);
		_begun = true;
		return true;
	}

	// ⚠️ 표적은 **65 버킷** 그대로다 — 이 회차는 헤드 폭을 인자로 열 뿐 **뜻을 안 바꾼다**.
	static uint32 _Bucket(float v)
	{
		const float u = (v + 1.0f) * 0.5f * (float)(MLTModelCfg::kBuckets - 1u);
		int b = (int)(u + 0.5f);
		if (b < 0) b = 0;
		if (b > (int)MLTModelCfg::kBuckets - 1) b = (int)MLTModelCfg::kBuckets - 1;
		return (uint32)b;
	}

	static void _Record(float ls)
	{
		++_read;
		if (!(ls == ls) || ls > 1.0e30f) _finite = false;
		if (_read == 1u) _first[_arm] = ls;
		_last[_arm] = ls;
		_cur.Add(ls);
		// ⭐ 팔 ㈁ 은 팔 ㈀ 과 **비트까지** 같아야 한다(관문 ①).
		if (_arm == 1u && _read <= _curve0.Count())
		{
			if (!(_cur[_read - 1u] == _curve0[_read - 1u]))
			{
				if (_mismatch == 0u) _firstBad = _read;
				++_mismatch;
			}
		}
		if (_read == 1u || _read % 100u == 0u || _read == kSteps)
			LogA("[mlt] 🔩   %s 스텝 %3u · 손실 %.6f\n", _ArmName(), _read, (double)ls);
	}

	static void _ArmDone()
	{
		const float ln = Log((float)kOut[_arm]);
		LogA("[mlt] 🔩 ── %s 결과: 손실 %.6f → %.6f · 유한 %s · 정규화 %.4f (= 마지막/ln%u)\n",
			_ArmName(), (double)_first[_arm], (double)_last[_arm], _finite ? "예" : "⛔",
			(double)(_last[_arm] / ln), kOut[_arm]);
		if (_arm == 0u) { _curve0.Reset(0); for (uint32 i = 0; i < _cur.Count(); ++i) _curve0.Add(_cur[i]); }
		if (_arm == 1u)
			LogA("[mlt] 🔩    ⭐ 비트 비교 — 어긋난 스텝 **%u/%u**%s\n",
				_mismatch, _curve0.Count(),
				(_mismatch == 0u) ? " → **비트 동일**" : "");
		++_arm; _begun = false;
	}

	static void _Summary()
	{
		const bool bitOk = (_mismatch == 0u) && (_curve0.Count() == kSteps);
		const float n0 = _last[0] / Log((float)kOut[0]);
		const float n2 = _last[2] / Log((float)kOut[2]);
		const bool memoOk = (n0 <= kMemo) && (n2 <= kMemo);

		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🔩 **회차 49 · 배관 결과**\n");
		LogA("[mlt] 🔩   관문① **비트 동일** — 어긋난 스텝 %u/%u → %s\n",
			_mismatch, kSteps, bitOk ? "통과" : "⛔");
		LogA("[mlt] 🔩   관문② **어휘 확장 생존** — 정규화 손실 ㈀ **%.4f** · ㈂ **%.4f** (문턱 %.2f) → %s\n",
			(double)n0, (double)n2, (double)kMemo, memoOk ? "통과" : "⛔");
		if (!bitOk)
			LogA("[mlt] 🔩   ⛔ **여기서 멈춘다** — 첫 어긋남 스텝 %u. ㉠ 누산 순서 → ㉡ 배선 순으로 가른다. 허용폭을 넣지 않는다.\n",
				_firstBad);
		else if (!memoOk)
			LogA("[mlt] 🔩   ⛔ 어휘를 늘리면 안 산다 — **왜**(초기화 척도 `1/√V` · 헤드 gemm 비용)를 적고 회차 50 의 크기를 그 위에서 등록한다.\n");
		else
			LogA("[mlt] 🔩   ✅ 어휘가 열렸다 — 회차 50 이 `EXP` 활성 토큰과 다음-활성 CE 를 얹고 관문 ㉠ 을 등록한다.\n");
		LogA("[mlt] 🔩   ⚠️ **배관 결과다** — 세계·표현·경험 학습에 대해 아무 말도 하지 않는다.\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		_done = true;
	}

	static void _Fail(const char* why)
	{
		LogA("[mlt] 🔩 ⛔ %s (팔 %u · 스텝 %u)\n", why, _arm, _step);
		_done = true;
	}
};
