// mltfit.cw — 🧩 **판정 ③ · 조립 검사(과적합).** *"고정 배치 하나를 외울 수 있나?"*
//
// ★ **왜 이 판정이 따로 있어야 하나 — 이것이 이 파일의 존재 이유다**
//
//   ```
//   판정 ②  수치 미분 vs 해석 기울기   → 커널 **한 장**의 미분이 맞나        (CPU 만)
//   판정 ①  GPU vs CPU 레퍼런스        → 셰이더가 CPU 와 **같은 수**를 내나  (커널 한 장)
//   판정 ③  손실이 내려가나            → **엮은 방식**이 맞나                (몸통 전체)
//   ```
//
//   ⚠️⚠️ ①②는 **커널 하나씩**을 재므로 **오프셋·전치·축·잔차 연결**은 하나도 못 본다.
//     그 자리가 틀리면 증상은 크래시가 아니라 *"손실이 안 내려간다"* 이고, **gradcheck 로는
//     절대 안 보인다.** 이 저장소가 쫓던 조용한 버그가 전부 그 종류였다.
//   ⇒ 그래서 몸통을 쓴 **같은 커밋**에 이 판정을 짝으로 둔다.
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문** — ⚠️ 「미리 등록한 뒤에만 흔든다」. 아래 수를 보고 나서 고치면 판정이 아니다.
// ══════════════════════════════════════════════════════════════════════════════
//
//   **과제**(⚠️ 세계를 안 쓴다 — 판정 ③ 은 *조립*을 재는 것이고 세계의 난이도가 섞이면
//     «조립이 틀렸나 과제가 어렵나» 가 갈리지 않는다):
//     · `val[b][t] = Sin(0.7·t + 1.3·b)`  — 배치마다 위상이 다른 매끄러운 파동
//     · 표적 = **다음 스텝 값의 버킷**(마지막 스텝은 자기 값) ⇒ 인과 구조를 실제로 쓴다
//     · 버킷 = `Round((v + 1)/2 · 64)`, `V = 65`
//   ★ 이 과제는 ㉠ **값 경로**(Φ → Win)와 ㉡ **위치 경로**(RoPE) 둘 다 없으면 안 풀린다.
//     그래서 조립의 두 갈래를 한꺼번에 건드린다.
//
//   **팔 둘**
//     · 팔 A — `lr = 3e-3`             ⇒ 손실이 **내려가야** 한다
//     · 팔 B — `lr = 0` (**음성 대조군**) ⇒ 손실이 **평평해야** 한다
//   ⚠️⚠️ B 가 없으면 *"내려갔다"* 가 리드백 표류·초기화 흔들림과 구별되지 않는다. 이 저장소의
//     규율(「대조군이 살아 있나」)이 요구하는 칸이고, **B 가 같이 내려가면 판정이 무효**다.
//
//   **관문**(넷 다 통과해야 ✅)
//     ㉠ 초기 손실이 `ln(65) = 4.1744` 근처인가 — 허용 **±0.20**
//        ★ 이것이 *"로짓이 안 터졌다 · 표적 색인이 안 어긋났다"* 의 첫 증거다. 초기 파라미터가
//          작은 산포이므로 균등분포에 가깝다. **4.6 이나 0.2 가 나오면 그 자리가 이미 틀렸다.**
//     ㉡ 팔 A 가 **300 스텝 안에 `< 1.0`** 으로 내려가는가
//        ★ 근거: 512행 · 65버킷을 802K 파라미터가 외우는 것은 **과분하게 쉽다**. 못 외우면
//          용량 문제가 아니라 **배선 문제**다.
//     ㉢ 팔 B 의 `|마지막 − 처음| < 0.02` (평평한가)
//     ㉣ 전 구간이 **유한**한가 (NaN/Inf 가 하나도 없다)
//
//   ⚠️ 실패했을 때 **모델을 키우지 않는다** — 배선을 읽는다(그것이 이 판정의 계약이다).

using namespace PE;

class MLTFit
{
public:
	// ══════════════════════════════════════════════════════════════════
	// 🚪 매 프레임(렌더 스레드). ⚠️ **한 프레임 = 한 스텝**이다 — 아레나 규약이
	//   *"이번 프레임에 디스패치한 결과는 다음 프레임에나 읽힌다"* 이므로 손실 곡선을 찍으려면
	//   프레임을 넘겨야 한다. ⇒ 300 스텝 × 두 팔 = 약 600 프레임.
	// ══════════════════════════════════════════════════════════════════
	static void Tick(RHI* rhi)
	{
		if (_arm >= 2 || rhi == nullptr) return;
		if (!_begun)
		{
			if (!_Begin(rhi)) { LogA("[mlt] ③ 준비 실패 — 판정 ③ 을 접는다\n"); _arm = 2; return; }
			_begun = true;
		}

		// ⚠️ 지금 읽는 손실은 **지난 프레임 forward** 의 것이다(같은 프레임에 읽으면 옛 값이다).
		if (_step > 0u)
		{
			float ls = 0.0f;
			if (!_M.ReadLoss(ls)) { LogA("[mlt] ③ 손실 리드백 실패(팔 %s)\n", _ArmName()); _arm = 2; return; }
			_Record(ls);
		}

		if (_step >= kSteps) { _Judge(); _NextArm(); return; }

		// ★ 팔 B 는 **같은 그래프를 같은 순서로** 돌리고 `lr` 만 0 이다 — 그것이 대조군의 조건이다.
		const float lrMul = (_arm == 0) ? 1.0f : 0.0f;
		if (!_M.Forward() || !_M.Backward() || !_M.AdamStep(lrMul))
		{ LogA("[mlt] ③ 스텝 실패(팔 %s · 스텝 %u)\n", _ArmName(), _step); _arm = 2; return; }
		++_step;
	}

	static bool Done() { return _arm >= 2; }

private:
	static constexpr uint32 kSteps   = 300u;
	static constexpr float  kInitTol = 0.20f;    // ㉠
	static constexpr float  kTarget  = 1.0f;     // ㉡
	static constexpr float  kFlat    = 0.02f;    // ㉢
	static constexpr uint32 kLogEvery = 50u;

	inline static MLTModel _M;
	inline static int    _arm = 0;          // 0 = A(학습) · 1 = B(대조군) · 2 = 끝
	inline static bool   _begun = false;
	inline static uint32 _step = 0u;
	inline static uint32 _read = 0u;
	inline static float  _first = 0.0f, _last = 0.0f, _best = 0.0f;
	inline static bool   _finite = true;
	inline static bool   _pass[2] = { false, false };
	inline static float  _armFirst[2] = { 0.0f, 0.0f }, _armLast[2] = { 0.0f, 0.0f };

	static const char* _ArmName() { return (_arm == 0) ? "A(lr=3e-3)" : "B(lr=0)"; }

	// ── 팔 하나를 시작한다 ─────────────────────────────────────────
	//   ⚠️ `Setup` 이 아레나를 **다시 만든다**(`Create` 가 먼저 `Destroy` 한다) ⇒ 팔마다
	//     파라미터가 **같은 초기값에서** 출발한다(결정적 산포라 비트까지 같다). 그것이 A/B 의 전제다.
	static bool _Begin(RHI* rhi)
	{
		LogA("[mlt] ─────────────────────────────────────────────\n");
		LogA("[mlt] ③ 판정 ③ 조립 검사 · 팔 %s · %u 스텝\n", _ArmName(), kSteps);
		if (!_M.Setup(rhi)) return false;

		typedef MLTModelCfg C;
		Array<float> val, tgt;
		val.Reset(0); tgt.Reset(0);
		for (uint32 b = 0; b < C::kBatch; ++b)
			for (uint32 t = 0; t < C::kCtx; ++t)
				val.Add(Sin(0.7f * (float)t + 1.3f * (float)b));
		for (uint32 b = 0; b < C::kBatch; ++b)
			for (uint32 t = 0; t < C::kCtx; ++t)
			{
				// ★ 표적은 **다음 스텝**의 버킷(마지막은 자기 것) — 인과 마스크가 실제로 쓰인다.
				const uint32 nt = (t + 1u < C::kCtx) ? (t + 1u) : t;
				tgt.Add((float)_Bucket(val[b * C::kCtx + nt]));
			}
		if (!_M.Upload(val, tgt)) { LogA("[mlt] ③ 배치 업로드 실패\n"); return false; }
		_step = 0u; _read = 0u; _finite = true;
		_first = 0.0f; _last = 0.0f; _best = 0.0f;
		return true;
	}

	// 값 → 버킷. ⚠️ `V` 가 홀수라 0 이 정확히 중앙 버킷이다(`kBuckets` 의 그 이유).
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
		// ⚠️ `MLMaxAbsErr` 류로는 NaN 이 안 보인다 — **유한성은 따로** 본다(판정 ① 의 그 방어).
		if (!(ls == ls) || ls > 1.0e30f || ls < -1.0e30f) _finite = false;
		if (_read == 0u) { _first = ls; _best = ls; }
		if (ls < _best) _best = ls;
		_last = ls;
		++_read;
		if (_read == 1u || _read % kLogEvery == 0u || _read == kSteps)
			LogA("[mlt] ③   팔 %s 스텝 %3u · 손실 %.4f (최저 %.4f) · ⏱️ 렌더CPU %.1fms · GPU %.1fms\n",
				_ArmName(), _read, (double)ls, (double)_best,
				(double)FrameStats::renderCpuMs, (double)FrameStats::gpuMs);
	}

	static void _Judge()
	{
		typedef MLTModelCfg C;
		const float ln = Log((float)C::kBuckets);
		_armFirst[_arm] = _first; _armLast[_arm] = _last;

		const bool g1 = (Abs(_first - ln) <= kInitTol);
		const bool g4 = _finite;
		bool g2 = true, g3 = true;
		if (_arm == 0) g2 = (_best < kTarget);
		else           g3 = (Abs(_last - _first) < kFlat);

		LogA("[mlt] ③ ── 팔 %s 결과 ──\n", _ArmName());
		LogA("[mlt] ③   ㉠ 초기 손실 %.4f vs ln(%u)=%.4f (허용 ±%.2f) → %s\n",
			(double)_first, C::kBuckets, (double)ln, (double)kInitTol, g1 ? "통과" : "⛔");
		if (_arm == 0)
			LogA("[mlt] ③   ㉡ 최저 손실 %.4f < %.2f → %s\n", (double)_best, (double)kTarget, g2 ? "통과" : "⛔");
		else
			LogA("[mlt] ③   ㉢ 평평함 |%.4f − %.4f| = %.4f < %.2f → %s\n",
				(double)_last, (double)_first, (double)Abs(_last - _first), (double)kFlat, g3 ? "통과" : "⛔");
		LogA("[mlt] ③   ㉣ 전 구간 유한 → %s\n", g4 ? "통과" : "⛔");
		_pass[_arm] = g1 && g2 && g3 && g4;
	}

	static void _NextArm()
	{
		if (_arm == 0) { _arm = 1; _begun = false; return; }
		_arm = 2;
		// ⚠️⚠️ **요약이 없으면 「판정이 안 돌았다」로 읽는 규약이다**(판정 ① 과 같은 계약).
		const bool ok = _pass[0] && _pass[1];
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] ③ **판정 ③ 조립 검사 — %s**\n", ok ? "✅ 통과" : "⛔ 실패");
		LogA("[mlt] ③   A(lr=3e-3) %.4f → %.4f · B(lr=0) %.4f → %.4f\n",
			(double)_armFirst[0], (double)_armLast[0], (double)_armFirst[1], (double)_armLast[1]);
		if (!ok)
			LogA("[mlt] ③   ⚠️ **모델을 키우지 마라** — 오프셋·전치·잔차 연결을 읽어라(이 판정의 계약)\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}
};
