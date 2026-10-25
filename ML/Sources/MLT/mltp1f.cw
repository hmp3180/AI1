// mltp1f.cw — 🧊 **회차 13 · 「보호·동결」의 폭.** 그리고 ⭐ **「주소」냐 「그냥 적게 갱신」이냐
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문** — ⚠️ 재기 전에 적는다
// ══════════════════════════════════════════════════════════════════════════════
//
// ★ **왜 이 회차인가**
//
//   회차 12 가 P1b 를 닫았다: 덮음은 **재방문**으로 거의 다 없어진다. 그리고 다음 물음이
//   *"어떻게 **학습 자체**가 그 재방문을 만들게 할까"* 인데, 그것을 만들기 전에 `mltconcept.md` 가
//   **셋을 요구했다.** 그 첫째가 **A1 폭 재기**다:
//   > **적응의 값은 고정값들의 폭이 상한이다.** … 바꾸려는 대상을 **여러 상수로 고정해** 결과의
//   > 폭을 먼저 재고, 폭이 문턱을 못 넘는 목적지는 **그 라운드에서 삭제한다.**
//
//   ⚠️⚠️ 회차 10 이 **데이터 쪽**(리허설)의 폭을 쟀다(0.674). **파라미터 쪽**(보호·동결·갱신 범위)의
//     폭은 **아직 안 쟀다.** 그런데 문서는 «자기평가의 첫 소비자는 **갱신**이어야 한다» 고 했다
//     ⇒ 그 목적지의 폭을 모르면 **적응형을 만들 자격이 없다.**
//
// ★ **그리고 이 회차가 문서의 그 쌍 대조군을 만든다**
//   > ⚠️ **「주소」와 「작은 학습률」을 가르는 쌍 대조군이 필수다**(실측: 주소 +21.7%p ↔
//   > 주소 없이 `lr/N` +0.8%p).
//   ⇒ **같은 파라미터 몫**을 동결하는데
//     · **층 경계**로 동결 = **구조적 주소가 있다**
//     · **무작위 조각**으로 동결 = **주소가 없다**(몫만 같다)
//   그 둘의 차이가 곧 **「주소의 몫」**이다.
//   ⚠️ 무작위 쪽이 층 쪽과 **같으면** 그것은 주소가 아니라 **그냥 적게 갱신한 것**이다.
//
// ══════════════════════════════════════════════════════════════════════════════
// ① 팔 일곱 — 기준선 공유
// ══════════════════════════════════════════════════════════════════════════════
//   ```
//   F0  동결 없음                                   (기준선 · 두 손잡이가 공유)
//   L1  **앞 1층** 동결   (파라미터의 ≈24.7%)
//   L2  **앞 2층** 동결   (≈49.3%)
//   L3  **앞 3층** 동결   (≈74.0%)
//   R1  **무작위 조각**으로 같은 몫 동결 (≈24.7%)   ← L1 의 짝
//   R2  같은 몫 (≈49.3%)                            ← L2 의 짝
//   R3  같은 몫 (≈74.0%)                            ← L3 의 짝
//   ```
//   ⚠️ 동결은 **B 단계에서만** 건다(A 단계는 언제나 전부 갱신).
//   ⚠️ 몫은 **파라미터 개수**로 맞춘다 — 층 하나가 197,888 개이고 전체가 802,432 개다.
//   ★ 무작위 조각: 파라미터 블록을 **`kPieces = 64` 조각**으로 균등 분할하고 그 중
//     `round(64 · 몫)` 개를 **결정적 해시**로 골라 동결한다. ⚠️ 난수를 안 쓴다(비트 재현).
//     ⭐ 조각이 연속이므로 **갱신 구간의 목록**으로 표현된다 ⇒ **새 커널이 0개**다.
//   ⚠️⚠️ 무작위 조각은 **층 경계와 무관**하게 골린다 — 그것이 「주소가 없다」의 뜻이다.
//     ★ 조각 하나가 층 안을 가르는 것은 상관없다(오히려 그것이 요점이다).
//
// ══════════════════════════════════════════════════════════════════════════════
// ② 읽는 칸과 문턱
// ══════════════════════════════════════════════════════════════════════════════
//   · 낙폭 `= R_A(B 뒤) − R_A(A 뒤)` (회차 9~12 와 **같은 정의**)
//   · ⚠️⚠️ **같은 줄에 `R_B(B 뒤)`** — **동결하면 B 를 못 배울 수 있다**(그것이 대가다).
//   · **손잡이의 폭** = `max(낙폭) − min(낙폭)` (층 쪽 4점 · 무작위 쪽 4점 각각)
//   · ⭐ **「주소의 몫」** = `낙폭(L_k) − 낙폭(R_k)` (몫이 같은 짝 안에서)
//   **문턱**
//     ㉠ **폭 ≥ 0.10**(≈6·SE) 이어야 그 목적지가 **살아 있다.** 못 넘으면 ***삭제한다.***
//     ㉡ ⭐ **주소의 몫 ≥ 0.10** 이고 부호검정 **10/12** ⇒ ***"구조적 주소가 값을 한다."***
//        `< 0.05` ⇒ ***"주소가 아니라 그냥 적게 갱신한 것이다"*** — 그러면 **주소를 만들 근거가 없다.**
//     ㉢ **배관** — `probs` 합 1.0 ± 0.01 · 전 구간 유한
//     ㉣ ⚠️ **위생** — `L3`(74% 동결)에서 `R_B` 가 **크게 떨어져야** 한다.
//        안 떨어지면 **동결이 실제로 안 걸린 것**이다(배선 검사).
//   **부호검정**은 `낙폭(L2) − 낙폭(R2)` 에 건다 — ★ 중간 몫(49%)을 고른 근거: 양 끝(24.7%·74%)은
//     각각 「너무 적어서 아무 일도 없다」와 「너무 많아서 B 를 못 배운다」로 **포화**할 수 있다.
//
//   ⚠️⚠️ **미리 적는 분기**
//     · ㉠ ⛔ ⇒ **「보호·동결」 목적지를 삭제한다.** 자기평가를 그쪽에 걸 근거가 없다
//       ⇒ 남은 목적지는 **데이터 쪽(재방문)** 이고 회차 10~12 가 그 폭을 이미 쟀다.
//     · ㉠ ✅ ㉡ ✅ ⇒ **주소가 값을 한다** ⇒ 그때 «학습이 그 주소를 만들게 할까» 를 묻는다.
//     · ㉠ ✅ ㉡ ⛔ ⇒ **폭은 있지만 주소가 아니다** ⇒ 「갱신 몫」은 손잡이지만 **어디를**
//       동결하는지는 상관없다 ⇒ 자기평가에 **주소를 맡길 근거가 없다**(몫만 맡길 수 있다).
//   ⚠️ 이 회차도 **아무것도 만들지 않는다.**
//
// ⚠️ 비용: 7팔 × 12씨앗 = **84 실행** · 실행당 600스텝 ⇒ **≈6분**.

using namespace PE;

class MLTP1F
{
public:
	static bool Done() { return _run >= kRuns; }

	static void Tick(RHI* rhi)
	{
		if (_run >= kRuns || rhi == nullptr) return;
		if (MLTModelCfg::kAxes != MLTP1::kAxes || MLTModelCfg::kTime != MLTP1::kTime)
		{ LogA("[mlt] 🧊 ⛔⛔ 축/시각 전제가 다르다\n"); _run = kRuns; return; }
		// ⚠️ **기본에서 껐다** — 회차 13 으로 쟀다. ★ 다시 돌리려면 `-mltfreeze`.
		if (!OS::CommandLine::Has("-mltfreeze"))
		{
			LogA("[mlt] 🧊 회차 13(보호·동결의 폭)은 **꺼져 있다**(`-mltfreeze`) — 기록: 폭 0.187/0.168"
			     " · 주소의 몫 +0.130(**7/12** ⇒ 중간) · 층 동결은 R_B 를 −35%% 깎는다\n");
			_run = kRuns;
			return;
		}
		if (!_banner) { _Banner(); _banner = true; }

		if (_st == kInit)
		{
			if (!_M.Setup(rhi)) { LogA("[mlt] 🧊 준비 실패(run %u)\n", _run); _run = kRuns; return; }
			for (uint32 a = 0; a < MLTP1::kAxes; ++a)
				MLTP1::_Baseline(a, kHold, _Seed(_run), 1u, kEvalEpi0, kEvalEpis, _bC[a], _bB[a]);
			_BuildRanges();
			_ph = 0u; _step = 0u; _finite = true;
			_st = kTrain;
			return;
		}

		if (_st == kTrain)
		{
			if (_step > 0u)
			{
				float ls = 0.0f;
				if (!_M.ReadLoss(ls)) { LogA("[mlt] 🧊 손실 리드백 실패\n"); _run = kRuns; return; }
				if (!(ls == ls) || ls > 1.0e30f) _finite = false;
			}
			if (_ph >= 2u) { _Finish(); return; }
			if (_step >= kSteps) { _StartEval(); return; }

			const uint32 K = MLTModelCfg::kPool;
			const uint32 slot = _step % K;
			if (slot == 0u)
			{
				const uint32 n = ((kSteps - _step) < K) ? (kSteps - _step) : K;
				_pv.Reset(0); _pt.Reset(0);
				for (uint32 k = 0; k < n; ++k)
				{
					Array<float> v, g;
					_Batch(_Seed(_run), 1000u + _ph * 20000u + (_step + k) * MLTModelCfg::kBatch, false, v, g);
					for (uint32 i = 0; i < v.Count(); ++i) _pv.Add(v[i]);
					for (uint32 i = 0; i < g.Count(); ++i) _pt.Add(g[i]);
				}
				if (!_M.UploadPool(_pv, _pt, n)) { LogA("[mlt] 🧊 풀 업로드 실패\n"); _run = kRuns; return; }
			}
			_M.SelectStep(slot);
			if (!_M.Forward() || !_M.Backward())
			{ LogA("[mlt] 🧊 스텝 실패(ph %u · step %u)\n", _ph, _step); _run = kRuns; return; }
			// ⭐ **동결은 B 단계(ph=1)에서만** 건다. A 단계는 전부 갱신한다.
			bool ok;
			if (_ph == 1u && _nRange > 0u) ok = _M.AdamStepRanges(_rFrom, _rCnt, _nRange);
			else
			{
				const uint32 f = 0u, c = _M.ParamTotal();
				ok = _M.AdamStepRanges(&f, &c, 1u);
			}
			if (!ok) { LogA("[mlt] 🧊 AdamW 실패(ph %u · step %u)\n", _ph, _step); _run = kRuns; return; }
			++_step;
			return;
		}

		if (_st == kEvalUp)
		{
			if (_eb >= kEvalB) { _EvalDone(); return; }
			_Batch(_Seed(_run), kEvalEpi0 + _eb * MLTModelCfg::kBatch, true, _ev, _et);
			if (!_M.Upload(_ev, _et)) { LogA("[mlt] 🧊 시험 업로드 실패\n"); _run = kRuns; return; }
			if (!_M.Forward()) { LogA("[mlt] 🧊 시험 forward 실패\n"); _run = kRuns; return; }
			_st = kEvalRd;
			return;
		}

		// kEvalRd
		{
			Array<float> m;
			float sp = 0.0f;
			for (uint32 a = 0; a < MLTP1::kAxes; ++a)
			{
				m.Reset(0);
				for (uint32 r = 0; r < MLTModelCfg::kRows; ++r)
					m.Add((((r % MLTModelCfg::kCtx) % MLTP1::kAxes) == a) ? 1.0f : 0.0f);
				uint32 h = 0u, n = 0u, hb = 0u, nb = 0u;
				float dd = 0.0f, ddb = 0.0f, ddo = 0.0f;
				if (!_M.ReadHits(_et, m, h, n, hb, nb, sp, dd, ddb, ddo))
				{ LogA("[mlt] 🧊 리드백 실패\n"); _run = kRuns; return; }
				_hit[a] += hb; _cnt[a] += nb;
			}
			_sumP += sp;
			++_eb;
			_st = kEvalUp;
		}
	}

private:
	static constexpr uint32 kSeed0 = 12u, kSeeds = 12u;
	static constexpr uint32 kArms = 7u;                  // F0 · L1 L2 L3 · R1 R2 R3
	static constexpr uint32 kRuns = kArms * kSeeds;      // 84
	static constexpr int    kHold = MLTWorldCfg::kHoldMid;
	static constexpr uint32 kSteps = 300u;
	static constexpr uint32 kEvalEpi0 = 0u, kEvalB = 4u;
	static constexpr uint32 kEvalEpis = kEvalB * MLTModelCfg::kBatch;
	static constexpr uint32 kPieces = 64u;               // ① 무작위 조각 수
	static constexpr uint32 kMaxRange = kPieces + 4u;
	static constexpr float  kWidthMin = 0.10f;           // ㉠
	static constexpr float  kAddrMin  = 0.10f;           // ㉡ 주소의 몫
	static constexpr float  kAddrNone = 0.05f;
	static constexpr uint32 kSignNeed = 10u;

	static uint32 _Arm(uint32 r)  { return r / kSeeds; }   // 0=F0 · 1~3=L · 4~6=R
	static uint32 _Seed(uint32 r) { return kSeed0 + (r % kSeeds); }
	static uint32 _NumLayers(uint32 r)
	{
		const uint32 a = _Arm(r);
		if (a >= 1u && a <= 3u) return a;          // L1·L2·L3
		if (a >= 4u) return a - 3u;                // R1·R2·R3 은 **같은 몫**을 쓴다
		return 0u;
	}
	static bool _IsRandomArm(uint32 r) { return _Arm(r) >= 4u; }
	static const char* _ArmName(uint32 r)
	{
		switch (_Arm(r))
		{
			case 0: return "F0 동결없음      ";
			case 1: return "L1 앞1층 동결    ";
			case 2: return "L2 앞2층 동결    ";
			case 3: return "L3 앞3층 동결    ";
			case 4: return "R1 무작위 같은몫 ";
			case 5: return "R2 무작위 같은몫 ";
			default: return "R3 무작위 같은몫 ";
		}
	}

	enum { kInit = 0, kTrain, kEvalUp, kEvalRd };

	inline static MLTModel _M;
	inline static bool _banner = false;
	inline static uint32 _run = 0u, _ph = 0u, _step = 0u, _eb = 0u;
	inline static int _st = kInit;
	inline static bool _finite = true;
	inline static float _sumP = 0.0f;
	inline static uint32 _hit[MLTP1::kAxes] = { 0u }, _cnt[MLTP1::kAxes] = { 0u };
	inline static MLTP1::Base _bC[MLTP1::kAxes], _bB[MLTP1::kAxes];
	inline static float _phR[2][MLTP1::kAxes] = { { 0.0f } };
	inline static Array<float> _ev, _et, _pv, _pt;
	// **갱신할** 구간 목록(= 동결의 여집합)
	inline static uint32 _rFrom[kMaxRange] = { 0u }, _rCnt[kMaxRange] = { 0u }, _nRange = 0u;
	inline static uint32 _frozen = 0u;   // 실제로 동결된 파라미터 개수(로그용)

	inline static float _rA0[kRuns] = { 0.0f }, _rA1[kRuns] = { 0.0f }, _rB1[kRuns] = { 0.0f };
	inline static uint32 _rFroz[kRuns] = { 0u };
	inline static bool  _rOk[kRuns] = { false };

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🧊 **회차 13 · 「보호·동결」의 폭** + ⭐ 「주소」냐 「그냥 적게」냐 · %u 실행\n", kRuns);
		LogA("[mlt] 🧊   L 팔 = **층 경계**로 동결(구조적 주소) ↔ R 팔 = **무작위 조각**으로 **같은 몫**"
		     "(주소 없음)\n");
		LogA("[mlt] 🧊   문턱: 폭 ≥ %.2f 면 목적지가 살아 있다 · **주소의 몫 ≥ %.2f**(부호검정 %u/12)"
		     " 면 「주소가 값을 한다」 · < %.2f 면 「그냥 적게 갱신한 것」\n",
			(double)kWidthMin, (double)kAddrMin, kSignNeed, (double)kAddrNone);
		LogA("[mlt] 🧊   ⚠️ 이 회차도 **아무것도 만들지 않는다**\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

	// ── 갱신 구간을 만든다(= 동결의 여집합) ──────────────────────────
	static void _BuildRanges()
	{
		const uint32 total = _M.ParamTotal();
		_nRange = 0u; _frozen = 0u;
		const uint32 nl = _NumLayers(_run);
		if (nl == 0u) { _rFrom[0] = 0u; _rCnt[0] = total; _nRange = 1u; return; }

		if (!_IsRandomArm(_run))
		{
			// ⭐ **층 경계** — 층은 연속이므로 「앞 nl 층」은 **한 구간**이다.
			const uint32 b0 = _M.LayerParamBegin(0u);
			const uint32 b1 = _M.LayerParamBegin(nl);   // nl 번째 층의 시작 = 동결 끝
			_frozen = b1 - b0;
			// 갱신 = `[0, b0)` (임베딩) + `[b1, total)` (남은 층 + 헤드)
			_rFrom[0] = 0u;  _rCnt[0] = b0;
			_rFrom[1] = b1;  _rCnt[1] = total - b1;
			_nRange = 2u;
			return;
		}

		// ⭐ **무작위 조각** — 같은 몫을 조각 단위로 동결한다.
		//   ⚠️ 결정적 해시로 고른다(난수 금지 · 비트 재현).
		const uint32 layerLen = _M.LayerParamBegin(1u) - _M.LayerParamBegin(0u);
		const uint32 want = layerLen * nl;                          // 동결할 파라미터 개수
		const uint32 pieceLen = total / kPieces;
		uint32 nFreeze = (want + pieceLen / 2u) / pieceLen;         // 반올림
		if (nFreeze > kPieces) nFreeze = kPieces;
		// 조각을 결정적으로 섞어 앞 `nFreeze` 개를 동결로 표시한다.
		bool froz[kPieces];
		for (uint32 i = 0; i < kPieces; ++i) froz[i] = false;
		uint32 picked = 0u, probe = 0u;
		while (picked < nFreeze && probe < kPieces * 8u)
		{
			const uint32 h = MLTWorld::Hash(_run * 7919u + probe, MLTSalt::Start, 0u);
			const uint32 idx = h % kPieces;
			if (!froz[idx]) { froz[idx] = true; ++picked; }
			++probe;
		}
		// 갱신 구간 = 동결 아닌 조각들의 **연속 병합**
		uint32 i = 0u;
		while (i < kPieces)
		{
			if (froz[i]) { ++i; continue; }
			const uint32 s = i;
			while (i < kPieces && !froz[i]) ++i;
			const uint32 from = s * pieceLen;
			const uint32 to = (i == kPieces) ? total : (i * pieceLen);
			if (_nRange < kMaxRange) { _rFrom[_nRange] = from; _rCnt[_nRange] = to - from; ++_nRange; }
		}
		_frozen = nFreeze * pieceLen;
		if (_nRange == 0u) { _rFrom[0] = 0u; _rCnt[0] = 0u; _nRange = 1u; }   // 전부 동결
	}

	static void _StartEval()
	{
		_eb = 0u; _sumP = 0.0f;
		for (uint32 a = 0; a < MLTP1::kAxes; ++a) { _hit[a] = 0u; _cnt[a] = 0u; }
		_st = kEvalUp;
	}

	static void _EvalDone()
	{
		for (uint32 a = 0; a < MLTP1::kAxes; ++a)
		{
			const float acc = _cnt[a] ? (float)_hit[a] / (float)_cnt[a] : 0.0f;
			const float w = _bB[a].acc - _bC[a].acc;
			_phR[_ph][a] = (w > 1.0e-4f) ? (acc - _bC[a].acc) / w : 0.0f;
		}
		++_ph;
		_step = 0u;
		_st = kTrain;
	}

	// 1단계 = A(y) · 2단계 = B(yaw) · 시험이면 전부. ⚠️ 이 회차는 **리허설이 없다**.
	static void _Batch(uint32 seed, uint32 epi0, bool isEval, Array<float>& val, Array<float>& tgt)
	{
		typedef MLTModelCfg M;
		const uint32 A = MLTP1::kAxes, T = MLTP1::kTime;
		const uint32 kAll = 0xFFFFFFFFu;
		const uint32 tgtAxis = isEval ? kAll : ((_ph == 0u) ? 0u : 1u);
		val.Reset(0); tgt.Reset(0);
		float v[MLTP1::kAxes][MLTP1::kTime + 1u];
		for (uint32 b = 0; b < M::kBatch; ++b)
		{
			for (uint32 a = 0; a < A; ++a) MLTP1::_Episode(a, seed, epi0 + b, kHold, v[a], nullptr);
			for (uint32 t = 0; t < T; ++t)
				for (uint32 a = 0; a < A; ++a)
				{
					val.Add(v[a][t]);
					const bool on = (tgtAxis == kAll) || (a == tgtAxis);
					tgt.Add(on ? (float)MLTP0::Bucket(v[a][t + 1u]) : M::kIgnoreTgt);
				}
		}
	}

	static void _Finish()
	{
		const float sp = (_eb > 0u) ? _sumP / (float)_eb : 0.0f;
		_rA0[_run] = _phR[0][0]; _rA1[_run] = _phR[1][0]; _rB1[_run] = _phR[1][1];
		_rFroz[_run] = _frozen;
		_rOk[_run] = _finite && (Abs(sp - 1.0f) <= 0.01f);
		if ((_run % kSeeds) == kSeeds - 1u)
			LogA("[mlt] 🧊 [%2u/%u] %s 동결 %u(%.1f%%) · R_A %.3f→%.3f (낙폭 %+.3f) · R_B %.3f%s\n",
				_run + 1u, kRuns, _ArmName(_run), _frozen,
				(double)((float)_frozen / (float)_M.ParamTotal() * 100.0f),
				(double)_rA0[_run], (double)_rA1[_run],
				(double)(_rA1[_run] - _rA0[_run]), (double)_rB1[_run], _rOk[_run] ? "" : "  ⛔배관");
		++_run;
		_st = kInit;
		if (_run >= kRuns) _Judge();
	}

	static void _Judge()
	{
		float drop[kArms] = { 0.0f }, rb[kArms] = { 0.0f };
		uint32 froz[kArms] = { 0u };
		bool plumb = true;
		for (uint32 m = 0; m < kArms; ++m)
		{
			float d = 0.0f, b = 0.0f;
			for (uint32 i = 0; i < kSeeds; ++i)
			{
				const uint32 r = m * kSeeds + i;
				d += (_rA1[r] - _rA0[r]); b += _rB1[r];
				if (!_rOk[r]) plumb = false;
			}
			drop[m] = d / (float)kSeeds; rb[m] = b / (float)kSeeds;
			froz[m] = _rFroz[m * kSeeds];
		}

		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🧊 **회차 13 결과 — 「보호·동결」의 폭**\n");
		for (uint32 m = 0; m < kArms; ++m)
			LogA("[mlt] 🧊   %s 동결 %.1f%% · 낙폭 **%+.3f** · R_B %.3f\n",
				_ArmName(m * kSeeds), (double)((float)froz[m] / (float)_M.ParamTotal() * 100.0f),
				(double)drop[m], (double)rb[m]);
		if (!plumb) LogA("[mlt] 🧊   ⛔ ㉢ 배관이 깨진 실행이 있다 — **판정불가**\n");
		else        LogA("[mlt] 🧊   ✅ ㉢ 배관 — probs 합 1.0 · 전 구간 유한\n");

		// ㉣ 위생 — L3(74% 동결)에서 R_B 가 크게 떨어져야 한다
		const bool g4 = (rb[3] < rb[0] - 0.10f);
		LogA("[mlt] 🧊   %s ㉣ 위생 — L3 의 R_B %.3f < 기준 %.3f − 0.10 (동결이 실제로 걸렸나)\n",
			g4 ? "✅" : "⛔", (double)rb[3], (double)rb[0]);

		// ㉠ 폭
		float loL = drop[0], hiL = drop[0], loR = drop[0], hiR = drop[0];
		for (uint32 m = 1; m <= 3u; ++m) { if (drop[m] < loL) loL = drop[m]; if (drop[m] > hiL) hiL = drop[m]; }
		for (uint32 m = 4u; m <= 6u; ++m) { if (drop[m] < loR) loR = drop[m]; if (drop[m] > hiR) hiR = drop[m]; }
		const float wL = hiL - loL, wR = hiR - loR;
		LogA("[mlt] 🧊   ── ㉠ 폭 ──\n");
		LogA("[mlt] 🧊   층 동결의 폭 **%.3f** · 무작위 동결의 폭 **%.3f** (문턱 %.2f)\n",
			(double)wL, (double)wR, (double)kWidthMin);
		const bool g1 = (wL >= kWidthMin) || (wR >= kWidthMin);

		// ㉡ 주소의 몫 — 몫이 같은 짝 안에서
		uint32 sign = 0u;
		for (uint32 i = 0; i < kSeeds; ++i)
		{
			const float dl = _rA1[2u * kSeeds + i] - _rA0[2u * kSeeds + i];   // L2
			const float dr = _rA1[5u * kSeeds + i] - _rA0[5u * kSeeds + i];   // R2
			if (dl > dr) ++sign;
		}
		LogA("[mlt] 🧊   ── ㉡ 주소의 몫(같은 몫에서 L − R) ──\n");
		for (uint32 k = 1u; k <= 3u; ++k)
			LogA("[mlt] 🧊   몫 %.1f%% : L %+.3f − R %+.3f = **%+.3f**%s\n",
				(double)((float)froz[k] / (float)_M.ParamTotal() * 100.0f),
				(double)drop[k], (double)drop[k + 3u], (double)(drop[k] - drop[k + 3u]),
				(k == 2u) ? "   ← 부호검정을 건 짝" : "");
		const float addr = drop[2] - drop[5];
		LogA("[mlt] 🧊   ⇒ 주소의 몫(L2−R2) **%+.3f** · 부호검정 **%u/12**\n", (double)addr, sign);

		LogA("[mlt] ══════════════════════════════════════════════════\n");
		if (!plumb || !g4)
			LogA("[mlt] 🧊 ⛔ **배관/위생이 깨졌다 — 판정불가**\n");
		else if (!g1)
			LogA("[mlt] 🧊 ⇒ ⚠️ **폭이 문턱을 못 넘었다 ⇒ 「보호·동결」 목적지를 삭제한다.**"
			     " 자기평가를 그쪽에 걸 근거가 없다 — 남은 목적지는 **데이터 쪽(재방문)** 이다\n");
		else if (addr >= kAddrMin && sign >= kSignNeed)
			LogA("[mlt] 🧊 ⇒ ✅✅ **구조적 주소가 값을 한다**(%+.3f · %u/12)"
			     " ⇒ 다음 물음은 «학습이 그 주소를 만들게 할까» 다\n", (double)addr, sign);
		else if (Abs(addr) < kAddrNone)
			LogA("[mlt] 🧊 ⇒ ⚠️⚠️ **폭은 있지만 주소가 아니다**(L−R = %+.3f) ⇒ 「갱신 **몫**」은"
			     " 손잡이지만 **어디를** 동결하는지는 상관없다 ⇒ 자기평가에 **주소를 맡길 근거가"
			     " 없다**(몫만 맡길 수 있다)\n", (double)addr);
		else
			LogA("[mlt] 🧊 ⇒ ⚠️ **중간**(L−R = %+.3f · %u/12) ⇒ 단정하지 않는다\n", (double)addr, sign);
		LogA("[mlt] 🧊   ⚠️ **`R_B` 를 같이 읽어라** — 동결이 B 를 못 배우게 하면 그것이 대가다\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}
};
