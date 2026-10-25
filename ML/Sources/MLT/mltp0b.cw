// mltp0b.cw — 📚 **P0 B단계 · 팔 4(학습).** A단계(`mltp0.cw`)가 바닥·천장을 확인한 뒤에 온다.
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **B단계 파일럿 등록문** — ⚠️ 재기 전에 적는다. 이것은 **라운드가 아니라 파일럿**이다.
// ══════════════════════════════════════════════════════════════════════════════
//
// ★ **왜 전체 스윕이 아니라 파일럿부터인가**
//   전체는 `3 난이도 × 12 씨앗 × 팔 셋` = 108 회다. 지금 모르는 것은 **성능이 아니라
//   「배우기는 하나」**이고, 특히 **값 인코딩이 버킷을 가르나**다(`kFreqMax` 를 8 → 32 로
//   올린 그 자리). ⚠️ 그것을 모르는 채로 108 회를 돌리면 실패했을 때 **원인이 108갈래**가 된다.
//   ⇒ 파일럿 하나로 그것만 가른 뒤 스윕한다. ★ 그리고 파일럿은 **개발 씨앗**만 쓴다.
//
//   **설정**(전부 미리 등록)
//     · 난이도 **중간(hold = 5)** — 창이 넓고(57.5%p) 반사 몫이 작다(3.43%) ⇒ 원인이 섞이지 않는다
//     · **개발 씨앗 0** 하나 · 훈련 에피소드 **1000 부터** · 시험 에피소드 **0~31**
//       ⚠️⚠️ **겹치지 않는다** — 시험 구간을 훈련에 쓰면 재는 것이 일반화가 아니다
//     · 훈련 **600 스텝**(스텝마다 배치 8 = 새 에피소드 8개 ⇒ 4800 에피소드를 본다)
//       ★ 근거: 판정 ③ 이 **50 스텝**에 고정 배치를 외웠다 ⇒ 600 은 그 12배다.
//         ⚠️ 여기는 매 스텝 **새 데이터**라 외우기가 불가능하다(그것이 이 단계의 요점이다).
//     · 시험 = 에피소드 32개 = **2048 예측**(A단계와 같은 표본 수 ⇒ 바닥·천장과 바로 견줄 수 있다)
//     · ⑫ 홀드아웃 `y ∈ [0.30, 0.50)`: **훈련 손실에서 뺀다**(표적이 그 구간인 행).
//       ⚠️ 시험에서는 **빼지 않는다** — 보간 관문 ㉡ 이 바로 그 구간을 묻기 때문이다.
//
//   **읽는 칸**(⚠️ 지표마다 하나씩 · 봉우리를 고른 지표와 검정을 건 지표를 같은 줄에)
//     · 표제 `R = (학습 − 복사) / (베이즈 − 복사)`, 중간 난이도의 바닥·천장은 **A단계 실측값**:
//       복사 **0.2790** · 베이즈 **0.8538** ⇒ 창 **57.48%p**
//     · 곡선: 훈련 손실 50 스텝마다 · 시험 정확도는 **끝에 한 번**(파일럿이므로 곡선을 안 만든다)
//
//   **관문**(파일럿) — ⚠️ 표제 문턱 `R ≥ 0.15` 는 **여기 안 건다**(그것은 판정 씨앗의 일이다)
//     ㉠ 훈련 손실이 `ln(65) = 4.1744` 에서 시작하나 (±0.20) — 조립·표적 색인의 첫 증거
//     ㉡ 시험 정확도가 **복사(27.90%)를 넘나** ⇒ `R > 0`
//     ㉢ 시험 정확도가 **베이즈(85.38%)를 안 넘나** ⇒ 넘으면 **누출이다**(등록문 ㉤)
//     ㉣ `probs` 행 합이 **1.0 ± 0.01** — 리드백이 프레임을 실제로 넘겼나(포이즌 방어)
//   ★ ㉡ 이 ⛔ 면 다음에 볼 것은 **정해져 있다**: ㈀ `kFreqMax`(인코딩 분해력)
//     ㈁ 학습률·스텝 수 ㈂ 컨텍스트가 `Δy` 를 실제로 보나(기제 관문 ㉢). ⚠️ 그 셋을 **동시에** 흔들지 않는다.

using namespace PE;

class MLTP0B
{
public:
	// ══════════════════════════════════════════════════════════════════
	// 🚪 매 프레임(렌더 스레드). ⚠️ **한 프레임 = 한 스텝** — 리드백이 프레임을 넘어야 한다.
	// ══════════════════════════════════════════════════════════════════
	static void Tick(RHI* rhi)
	{
		if (_st >= kDone || rhi == nullptr) return;

		if (_st == kInit)
		{
			// ⚠️ **파일럿은 기본에서 끈다** — 통과했고(아래 수), 매 세션 604 프레임을 다시 쓰면
			//   판정 스윕이 그만큼 늦어진다. ★ 다시 돌리려면 `-mltpilot` 을 준다.
			//   ⚠️ **지운 것이 아니라 끈 것**이다 — 등록문과 실측이 이 파일에 남아 있어야
			//     다음 사람이 「무엇을 이미 갈랐나」를 안다.
			if (!OS::CommandLine::Has("-mltpilot"))
			{
				LogA("[mlt] ④ P0 B단계 파일럿은 **꺼져 있다**(`-mltpilot` 으로 켠다) —"
				     " 통과 기록: 정확도 63.67%% · R = 0.622 · 누출 없음\n");
				_st = kDone;
				return;
			}
			// ⚠️⚠️⚠️ **P0 은 `kCtx = 64`(원래 배치)로 등록됐다.** 지금은 P1 의 배치다
			//   ⇒ 이 하네스를 그대로 돌리면 **등록문과 다른 것을 재고** 그 수를 P0 의 수인 것처럼
			//   적게 된다. ★ 그래서 **크게 집고 멈칸다.**
			//   ⇒ 그 회차를 재현하려면 **그 초기 커밋으로 돌아가라**(`mltlog_1.md` 회차 3·4·5).
			if (MLTModelCfg::kAxes != 1u || MLTModelCfg::kCtx != 64u)
			{
				LogA("[mlt] ④ ⛔⛔ **이 하네스는 P0 의 배치(kCtx=64 · 원래 1축)를 전제한다** —"
				     " 지금은 kCtx=%u · 축 %u 다. **재현은 그 커밋에서 하라**(회차 3~5)\n",
					MLTModelCfg::kCtx, MLTModelCfg::kAxes);
				_st = kDone;
				return;
			}
			LogA("[mlt] ─────────────────────────────────────────────\n");
			LogA("[mlt] ④ **P0 B단계 파일럿** — 난이도 중간(hold=%d) · 개발 씨앗 %u · %u 스텝\n",
				MLTWorldCfg::kHoldMid, kSeed, kTrain);
			LogA("[mlt] ④   바닥 복사 %.2f%% · 천장 베이즈 %.2f%% (A단계 실측) ⇒ 창 %.2f%%p\n",
				(double)(kCopy * 100.0f), (double)(kBayes * 100.0f), (double)((kBayes - kCopy) * 100.0f));
			if (!_M.Setup(rhi)) { LogA("[mlt] ④ 모델 준비 실패 — B단계를 접는다\n"); _st = kDone; return; }
			_step = 0u; _read = 0u; _first = 0.0f; _last = 0.0f; _finite = true;
			_st = kTrain0;
			return;
		}

		if (_st == kTrain0)
		{
			if (_step > 0u)
			{
				float ls = 0.0f;
				if (!_M.ReadLoss(ls)) { LogA("[mlt] ④ 손실 리드백 실패\n"); _st = kDone; return; }
				if (!(ls == ls) || ls > 1.0e30f) _finite = false;
				if (_read == 0u) _first = ls;
				_last = ls; ++_read;
				if (_read == 1u || _read % kLogEvery == 0u || _read == kTrain)
					LogA("[mlt] ④   스텝 %3u · 훈련 손실 %.4f\n", _read, (double)ls);
			}
			if (_step >= kTrain) { _st = kEval0; _eval = 0u; _hits = 0u; _n = 0u; _sumP = 0.0f; return; }

			// ── 훈련 배치 하나 — ⚠️ **매 스텝 새 에피소드**다(외울 수 없다)
			Array<float> val, tgt;
			_Batch(kTrainEpi0 + _step * MLTModelCfg::kBatch, true, val, tgt);
			if (!_M.Upload(val, tgt)) { LogA("[mlt] ④ 업로드 실패(스텝 %u)\n", _step); _st = kDone; return; }
			// ⚠️ **훈련** 배치의 유효 행 수를 남긴다 — 시험 배치는 홀드아웃이 없어 늘 512 다.
			//   ★ 등록문이 «훈련 표본 0 을 세어 로그에 찍는다» 고 못 박은 자리.
			_trValid += _M.Valid(); ++_trBatch;
			if (!_M.Forward() || !_M.Backward() || !_M.AdamStep())
			{ LogA("[mlt] ④ 스텝 실패(%u)\n", _step); _st = kDone; return; }
			++_step;
			return;
		}

		// ── 시험 — ⚠️ 배치를 올리고 **다음 프레임에** 읽는다(같은 프레임에 읽으면 옛 값이다)
		if (_st == kEval0)
		{
			if (_eval >= kEvalB) { _Judge(); _st = kDone; return; }
			_Batch(kEvalEpi0 + _eval * MLTModelCfg::kBatch, false, _evVal, _evTgt);
			_evBand.Reset(0);
			for (uint32 i = 0; i < _evTgt.Count(); ++i) _evBand.Add(0.0f);   // 파일럿은 밴드를 안 쓴다
			if (!_M.Upload(_evVal, _evTgt)) { LogA("[mlt] ④ 시험 업로드 실패\n"); _st = kDone; return; }
			if (!_M.Forward()) { LogA("[mlt] ④ 시험 forward 실패\n"); _st = kDone; return; }
			_st = kEval1;
			return;
		}
		if (_st == kEval1)
		{
			uint32 h = 0u, n = 0u, hb = 0u, nb = 0u; float sp = 0.0f, dd = 0.0f, ddb = 0.0f, ddo = 0.0f;
			if (!_M.ReadHits(_evTgt, _evBand, h, n, hb, nb, sp, dd, ddb, ddo))
			{ LogA("[mlt] ④ 시험 리드백 실패\n"); _st = kDone; return; }
			_hits += h; _n += n; _sumP += sp;
			++_eval;
			_st = kEval0;
			return;
		}
	}

	static bool Done() { return _st >= kDone; }

private:
	enum { kInit = 0, kTrain0, kEval0, kEval1, kDone };

	static constexpr uint32 kSeed      = 0u;
	static constexpr uint32 kTrain     = 600u;
	static constexpr uint32 kLogEvery  = 50u;
	static constexpr uint32 kTrainEpi0 = 1000u;   // ⚠️ 시험 구간(0~31)과 **겹치지 않는다**
	static constexpr uint32 kEvalEpi0  = 0u;
	static constexpr uint32 kEvalB     = 4u;      // 배치 4 × 8 = 32 에피소드 = 2048 예측
	// A단계 실측 — ⚠️ 손계산이 아니라 **실측**이다(그 절의 그 이유)
	static constexpr float  kCopy  = 0.2790f;
	static constexpr float  kBayes = 0.8538f;
	static constexpr float  kHoldLo = 0.30f, kHoldHi = 0.50f;

	inline static MLTModel _M;
	inline static int    _st = kInit;
	inline static uint32 _step = 0u, _read = 0u, _eval = 0u, _hits = 0u, _n = 0u;
	inline static float  _first = 0.0f, _last = 0.0f, _sumP = 0.0f;
	inline static uint32 _trValid = 0u, _trBatch = 0u;
	inline static bool   _finite = true;
	inline static Array<float> _evVal, _evTgt, _evBand;

	// ══════════════════════════════════════════════════════════════════
	// 🎒 배치 하나 — 행 `b*T + t` 는 «에피소드 `epi0+b` 의 스텝 `t`» 다.
	//   ⚠️ 표적은 **다음 상태값의 버킷**이고, 인과 마스크가 그 행이 미래를 안 보게 한다.
	//   ★ `holdout = true`(훈련)면 표적이 `[0.30, 0.50)` 인 행을 **손실에서 뺀다**.
	//     ⚠️ 시험에서는 빼지 않는다 — 관문 ㉡(보간)이 바로 그 구간을 묻는다.
	// ══════════════════════════════════════════════════════════════════
	static void _Batch(uint32 epi0, bool holdout, Array<float>& val, Array<float>& tgt)
	{
		typedef MLTModelCfg C;
		val.Reset(0); tgt.Reset(0);
		float y[C::kCtx + 1u];
		for (uint32 b = 0; b < C::kBatch; ++b)
		{
			MLTWorld w;
			w.Reset(kSeed, epi0 + b, MLTWorldCfg::kHoldMid, 0);
			y[0] = w.State().y;
			for (uint32 t = 0; t < C::kCtx; ++t) { w.Step(); y[t + 1u] = w.State().y; }
			for (uint32 t = 0; t < C::kCtx; ++t) val.Add(y[t]);
			for (uint32 t = 0; t < C::kCtx; ++t)
			{
				const float ny = y[t + 1u];
				const bool skip = holdout && (ny >= kHoldLo && ny < kHoldHi);
				tgt.Add(skip ? C::kIgnoreTgt : (float)MLTP0::Bucket(ny));
			}
		}
		// ★ 행 색인은 `b*T + t` 다: `val`/`tgt` 이 **서로 다른 배열**이고 각각 b 순서로 64개씩
		//   붙으므로 둘의 색인이 같은 자리를 가리킨다. ⚠️ 한 배열에 섞어 담으면 그때 어긋난다.
	}

	static void _Judge()
	{
		typedef MLTModelCfg C;
		const float acc = (_n > 0u) ? (float)_hits / (float)_n : 0.0f;
		const float R   = (acc - kCopy) / (kBayes - kCopy);
		const float ln  = Log((float)C::kBuckets);
		const float sp  = (_eval > 0u) ? _sumP / (float)_eval : 0.0f;

		const bool g1 = (Abs(_first - ln) <= 0.20f);
		const bool g2 = (acc > kCopy);
		const bool g3 = (acc <= kBayes);
		const bool g4 = (Abs(sp - 1.0f) <= 0.01f);

		LogA("[mlt] ④ ── B단계 파일럿 결과 ──\n");
		LogA("[mlt] ④   훈련 손실 %.4f → %.4f (%u 스텝) · 훈련 유효 행 평균 %.1f/%u"
		     " ⇒ 홀드아웃이 뺀 몫 %.2f%%\n",
			(double)_first, (double)_last, _read,
			(double)(_trBatch ? (float)_trValid / (float)_trBatch : 0.0f), C::kRows,
			(double)(_trBatch ? (1.0f - (float)_trValid / (float)(_trBatch * C::kRows)) * 100.0f : 0.0f));
		LogA("[mlt] ④   **시험 정확도 %.2f%%** (%u/%u) · 복사 %.2f%% · 베이즈 %.2f%% ⇒ **R = %.3f**\n",
			(double)(acc * 100.0f), _hits, _n, (double)(kCopy * 100.0f), (double)(kBayes * 100.0f), (double)R);
		LogA("[mlt] ④   %s ㉠ 초기 손실 %.4f vs ln(65)=%.4f (±0.20)\n", g1 ? "✅" : "⛔", (double)_first, (double)ln);
		LogA("[mlt] ④   %s ㉡ 복사를 넘나 — %.2f%% > %.2f%%\n", g2 ? "✅" : "⛔",
			(double)(acc * 100.0f), (double)(kCopy * 100.0f));
		LogA("[mlt] ④   %s ㉢ 베이즈를 안 넘나(누출 검사) — %.2f%% ≤ %.2f%%\n", g3 ? "✅" : "⛔",
			(double)(acc * 100.0f), (double)(kBayes * 100.0f));
		LogA("[mlt] ④   %s ㉣ probs 행 합 %.4f (1.0 ± 0.01) · 유한 %s\n", (g4 && _finite) ? "✅" : "⛔",
			(double)sp, _finite ? "예" : "**아니다**");

		const bool ok = g1 && g2 && g3 && g4 && _finite;
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] ④ **P0 B단계 파일럿 — %s**\n", ok ? "✅ 통과 (스윕으로 간다)" : "⛔ 실패");
		if (!g2)
			LogA("[mlt] ④   ⚠️ ㉡ 가 ⛔ 다 ⇒ 다음에 볼 것은 **정해져 있다**: ㈀ kFreqMax(인코딩 분해력)"
			     " ㈁ 학습률·스텝 수 ㈂ 컨텍스트가 Δy 를 보나. **동시에 흔들지 마라**\n");
		if (!g3)
			LogA("[mlt] ④   ⚠️⚠️ ㉢ 가 ⛔ 다 = **누출이다**(표적 어긋남·시험 구간이 훈련에 섞임)."
			     " 성능으로 읽지 마라\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}
};
