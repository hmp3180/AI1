// mltp6ctx.cw — 🔗 **P6 사슬 코퍼스** — ⚠️ **P6 의 정본**
//
// ══════════════════════════════════════════════════════════════════════════════
// ⚠️⚠️⚠️ **왜 `MLTP4Ctx` 를 안 고치고 새로 만드나** — 회차 117 설계 심사의 결정이다.
//   `MLTP4Ctx::kAxes` 는 **18** 이고 그 값이 P4 회차 전부의 **배치**다. P6 은 배치가 통째로
//   다르므로(사슬 · 과제 심볼 · 경계) 고치면 ***회차 103~116 의 회귀가 전부 깨진다.***
//   ⇒ ★ **`MLTP4Ctx` 는 P4 의 정본으로 얼린다.** 여기는 P6 의 자리다.
//   ★ 회차 76 이 `MLTP3Ctx` → `MLTP4Ctx` 로 한 것과 **같은 판정**이다.
//
// ── 📐 배치 — `MLT.md` 「배치 최종형」 그대로 ───────────────────────────────
//   ```
//   [EXP]      과거 사건들 — 상태 5 + 활성 8   × 시각 kExp
//   [TASK_k]   ⭐ 과제 심볼(불투명 정수 · 값 없음)
//   [EYE]      지금      — 상태 5 + 활성 8     × 시각 1
//   [LISTEN]   경계
//   [중간]     ⭐ 사슬   — 상태 5 + 활성 8     × 시각 kMid
//   [PRED]     채점 창구
//   [답]                  상태 5 + 활성 8      × 시각 1
//   ```
//   ★ 순서의 근거(`MLT.md`): ㈀ **과제가 「지금」의 읽기를 정한다**(뒤면 늦다) ㈁ 같은 `EXP` prefix 에
//     과제만 바꿔 붙일 수 있다(교란 0 대조군) ㈂ KV 캐시 재사용.
//
// ── ⭐ 제어 심볼을 **「축」으로 흡수**한다 ────────────────────────────────
//   ⚠️ `MLTModel` 은 `axes × timeSteps` 격자라 **제어 토큰을 따로 끼울 자리가 없다.**
//   ⇒ ★ 시각마다 **축 하나**를 「그 시각의 경계 심볼」로 쓴다(값 0 · 표적 없음).
//     `kAxes = 14`(상태 5 + 활성 8 + **경계 1**) · `kTime = 9` ⇒ `kCtx = 126` · `kRows = 1008`
//   ⭐ 그러면 `EXP`/`TASK`/`EYE`/`LISTEN`/`PRED` 가 **모두 그 축에 산다** — 새 커널 0개.
//   ⚠️ 그리고 **과제 심볼도 거기 산다**(`TASK0`/`TASK1`) ⇒ 「같은 prefix 에 과제만 바꾸기」가 그대로 된다.
//
// ── ⚠️ 「단계」는 **세계의 스텝**이다(사고 단계가 아니다) ────────────────────
//   `MLT.md` 의 조건 셋 중 첫째. 중간 시각의 표적은 **시뮬의 그 스텝**이고, 그래서
//   **라벨이 무한하고 정답이 있다.** ⇒ 사고 절차를 준 것이 아니다.
//
// ── ⚠️ 과제 심볼은 **불투명**하다 ────────────────────────────────────────
//   `TASK0`/`TASK1` 은 `s256+` 대역의 **정수**일 뿐이고 임베딩은 무작위 초기화다.
//   ⇒ *"이 심볼이 N스텝을 뜻한다"* 는 **손실이 요구하고 가중치가 만든다.**

using namespace PE;

class MLTP6Cfg
{
public:
	// ── 축 배치 ────────────────────────────────────────────────
	static constexpr uint32 kStateAx = 5u;
	static constexpr uint32 kPersist = 8u;
	static constexpr uint32 kMarkAx  = 1u;                                  // ⭐ 경계 심볼의 자리
	static constexpr uint32 kAxes    = kStateAx + kPersist + kMarkAx;       // 14
	// ── 시각 배치 ──────────────────────────────────────────────
	//   `[EXP × kExp][EYE 1][중간 × kMid][답 1]` — ⚠️ `TASK`·`LISTEN`·`PRED` 는 **경계 축**에 산다.
	static constexpr uint32 kExp  = 4u;    // 과거
	static constexpr uint32 kMid  = 3u;    // ⭐ 사슬의 중간 스텝 수(= N−1 · `TASK1` 일 때만 채운다)
	static constexpr uint32 kTime = kExp + 1u + kMid + 1u;                  // 9
	static constexpr uint32 kCtx  = kAxes * kTime;                          // 126
	static constexpr uint32 kBatch = MLTModelCfg::kBatch;                   // 8
	static constexpr uint32 kRows = kBatch * kCtx;                          // 1008
	// 시각의 뜻 — ⚠️ 이 넷만 보면 배치를 안다.
	static constexpr uint32 kTEye = kExp;                  // 4  = 「지금」
	static constexpr uint32 kTMid = kExp + 1u;             // 5  = 중간 시작
	static constexpr uint32 kTAns = kTime - 1u;            // 8  = 답

	// ── 심볼 대역 (`MLT.md` 「심볼 대역」 표 그대로) ─────────────
	//   ⚠️ 상태 `0..4` · 활성 `13..(13+N-1)` 은 **P4 와 같은 관용구**(자리만 옮겼다).
	static constexpr uint32 kSymState = 0u;                         // 0..4
	static constexpr uint32 kSymAct   = kStateAx;                   // 5..12 (활성 자리표는 안 쓴다)
	static constexpr uint32 kSymUnit  = kStateAx + kPersist;         // 13.. : 활성 유닛 id 의 시작
	// 경계 심볼 — ⚠️ 활성 대역 **뒤**에 둔다(겹치면 안 된다).
	static constexpr uint32 kNMark = 6u;
	static uint32 MarkBase(uint32 dict) { return kSymUnit + dict; }
	static constexpr uint32 kMkExp = 0u, kMkTask0 = 1u, kMkTask1 = 2u,
		kMkEye = 3u, kMkListen = 4u, kMkPred = 5u;
	static uint32 SymVocab(uint32 dict) { return MarkBase(dict) + kNMark + 1u; }   // +1 = 「없음」

	static constexpr uint32 kAllT1 = 0xFFFFFFFFu;
	static constexpr uint32 kNoCand = 0xFFFFFFFFu;
	static constexpr uint32 kLam = 11u;
};

class MLTP6Ctx
{
public:
	typedef MLTP6Cfg C;
	static constexpr uint32 kStateAx = C::kStateAx, kPersist = C::kPersist;
	static constexpr uint32 kAxes = C::kAxes, kTime = C::kTime;
	static constexpr uint32 kCtx = C::kCtx, kBatch = C::kBatch, kRows = C::kRows;
	static constexpr uint32 kNoCand = C::kNoCand, kAllT1 = C::kAllT1;

	// ══════════════════════════════════════════════════════════════════
	// ⚠️⚠️⚠️ **시험 누출을 컴파일 타임에 막는다**(회차 81 이 찾은 함정 · P4 와 같은 규약)
	// ══════════════════════════════════════════════════════════════════
	template <uint32 TrainEpi, uint32 NCtx, uint32 TestEpi>
	struct NoLeak
	{
		static_assert(TestEpi >= TrainEpi + NCtx,
			"시험 에피소드가 학습과 겹친다 — kTestEpi >= kTrainEpi + kNCtx 여야 한다(회차 81)");
		static constexpr bool ok = true;
	};

	void Begin(uint32 nCtx, uint32 dict)
	{
		_nCtx = nCtx; _dict = dict;
		const uint32 n = (nCtx / kBatch) * kRows;
		_val.Reset(0); _tgt.Reset(0); _sym.Reset(0);
		for (uint32 i = 0; i < n; ++i) { _val.Add(0.0f); _tgt.Add(0.0f); _sym.Add(0.0f); }
		_act = nCtx;
		_task.Reset(0);
		for (uint32 i = 0; i < nCtx; ++i) _task.Add(0u);
		// 표적 id — 중간 `kMid` + 답 1 = `kMid+1` 시각 × `kPersist`
		const uint32 m = nCtx * (C::kMid + 1u) * kPersist;
		_tid.Reset(0); _prev.Reset(0);
		for (uint32 i = 0; i < m; ++i) { _tid.Add(0u); _prev.Add(0u); }
		_inv.Reset(0);
		for (uint32 i = 0; i < nCtx * kTime; ++i) _inv.Add(0.0f);
		_lastId.Reset(0);
		for (uint32 i = 0; i < nCtx * kPersist; ++i) _lastId.Add(0u);
	}

	void SetSortById(bool on) { _sortId = on; }
	void SetActive(uint32 n) { _act = (n == 0u || n > _nCtx) ? _nCtx : n; }
	uint32 NCtx() const { return _nCtx; }
	uint32 PoolSteps() const { return _nCtx / kBatch; }
	uint32 Targets() const { return _act * (C::kMid + 1u) * kPersist; }
	const Array<float>& Val() const { return _val; }
	const Array<float>& Tgt() const { return _tgt; }
	const Array<float>& Sym() const { return _sym; }
	uint32 Task(uint32 ctx) const { return _task[ctx]; }
	float  Inv(uint32 ctx, uint32 t) const { return _inv[ctx * kTime + t]; }

	// ⭐ 그 문맥의 과제를 정한다 — ⚠️ **경계 축의 심볼로 들어간다**(값 없음).
	//   `task == 0` ⇒ `TASK0`(다음 스텝) · `task == 1` ⇒ `TASK1`(N스텝 뒤)
	void SetTask(uint32 ctx, uint32 task) { _task.Data()[ctx] = (task != 0u) ? 1u : 0u; }

	// ⭐ 시각마다 **경계 심볼**을 박는다 — ⚠️ 값은 0 · 표적은 없다(`IgnoreTgt`).
	//   ★ `TASK` 는 「지금」 **바로 앞** 시각에 붙는다(과제가 「지금」의 읽기를 정한다는 그 순서).
	void StoreMarks(uint32 ctx)
	{
		const uint32 base = C::MarkBase(_dict);
		for (uint32 t = 0; t < kTime; ++t)
		{
			uint32 mk;
			if (t + 1u == C::kTEye)      mk = (_task[ctx] == 0u) ? C::kMkTask0 : C::kMkTask1;
			else if (t < C::kTEye)       mk = C::kMkExp;
			else if (t == C::kTEye)      mk = C::kMkEye;
			else if (t + 1u == C::kTAns) mk = C::kMkPred;   // 답 **바로 앞** = 채점 창구 선언
			else                          mk = C::kMkListen; // 중간 구간
			const uint32 r = Row(ctx, t, kAxes - 1u);
			_sym.Data()[r] = (float)(base + mk);
			_val.Data()[r] = 0.0f;
			_tgt.Data()[r] = (float)_dict;                  // IgnoreTgt
		}
	}

	// 상태 다섯 — ⚠️ 표적은 없다(P4 와 같다).
	void StoreState(uint32 ctx, uint32 t, const MLTState& s)
	{
		const uint32 base = Row(ctx, t, C::kSymState);
		for (uint32 a = 0; a < kStateAx; ++a)
		{
			_sym.Data()[base + a] = (float)(C::kSymState + a);
			_val.Data()[base + a] = s.Axis((int)a);
			_tgt.Data()[base + a] = (float)_dict;
		}
	}

	// ══════════════════════════════════════════════════════════════════
	// 활성 여덟 — ⚠️ 선택 식은 **`MLTP4Ctx::Pick` 을 그대로 부른다**(두 벌로 두면 갈린다).
	// ══════════════════════════════════════════════════════════════════
	//   ⭐ **표적 규약이 P4 와 다르다** — P4 는 *"직전 시각의 표적 = 지금의 활성"* 이었다.
	//     P6 은 **사슬**이라 `EXP`·`EYE` 구간에는 표적이 없고, **중간과 답에만** 있다:
	//       중간 시각 `t` 의 표적 = **그 시각 자신의 활성**(그 스텝을 내야 한다)
	//       답 시각의 표적       = **답의 활성**
	//   ⚠️ 그래서 「자기 자신을 표적으로」가 아니다 — ★ **입력에는 그 시각의 활성을 넣지 않는다**
	//     (중간·답 시각의 활성 슬롯은 **「없음」 심볼 + 값 0**). 그것이 *"모델이 만든다"* 의 뜻이다.
	void StoreAct(uint32 ctx, uint32 t, const Array<float>& ids, const Array<float>& mag,
		const Array<float>& norm)
	{
		uint32 pick[kPersist]; float pm[kPersist]; uint32 pc[kPersist];
		float maxAbs = 0.0f;
		MLTP4Ctx::Pick(ids, mag, norm, _dict, _sortId, pick, pm, pc, maxAbs);
		const float inv = (maxAbs > 1.0e-12f) ? (1.0f / maxAbs) : 0.0f;
		const uint32 base = Row(ctx, t, C::kSymAct);
		const bool isTarget = (t >= C::kTMid);      // ⭐ 중간·답 = 모델이 만들 자리
		for (uint32 j = 0; j < kPersist; ++j)
		{
			if (isTarget)
			{
				// ⭐ 입력은 **비운다**(「없음」) · 표적은 **그 활성**
				_sym.Data()[base + j] = (float)(C::MarkBase(_dict) + C::kNMark);   // 「없음」
				_val.Data()[base + j] = 0.0f;
				_tgt.Data()[base + j] = (float)pick[j];
				_tid.Data()[Tix(ctx, t, j)] = pick[j];
				// 복사 바닥용 — 「직전 시각의 그 슬롯 id」
				_prev.Data()[Tix(ctx, t, j)] = (t == C::kTMid) ? _lastId[ctx * kPersist + j]
					: _tid[Tix(ctx, t - 1u, j)];
			}
			else
			{
				_sym.Data()[base + j] = (float)(C::kSymUnit + pick[j]);
				_val.Data()[base + j] = pm[j] * inv;
				_tgt.Data()[base + j] = (float)_dict;
				_lastId.Data()[ctx * kPersist + j] = pick[j];   // ⭐ `EYE` 활성 = 중간 첫 시각의 「직전」
			}
		}
		_inv.Data()[ctx * kTime + t] = inv;
	}

	// ══════════════════════════════════════════════════════════════════
	// ⭐ **회차 119 가 더한 둘** — 「중간을 내게 하나」와 「어디를 채점하나」를 가른다.
	// ══════════════════════════════════════════════════════════════════
	// ⭐ **중간 시각의 표적을 뺀다** — ⚠️ **한 함수인데 쓰는 자리가 둘**이고 뜻이 다르다:
	//   | **학습 풀**에 쓰면 | *"중간을 **내게 하지 않는다**"* ⇒ 팔 ㈀(중간 없음)의 정의 |
	//   | **시험 풀**에 쓰면 | *"**답만 채점**한다"* ⇒ ⭐ 두 팔을 **같은 질문**(4스텝 뒤)으로 견준다 |
	//   ⚠️⚠️ 시험 쪽을 빼먹으면 ㈁ 팔이 **더 많은 표적을 채점받아** 평균이 흔들린다
	//     (회차 116 이 밟은 함정 — 그때는 두 팔의 표적 **수**를 맞추는 것이 요점이었다).
	//   ★ 같은 연산이라 **한 함수로 둔다**(저장소 규약: 비슷한 함수는 묶는다).
	void DropMidTargets(uint32 ctx, Array<float>& tgt) const
	{
		for (uint32 t = C::kTMid; t + 1u < kTime; ++t)
		{
			const uint32 base = Row(ctx, t, C::kSymAct);
			for (uint32 j = 0; j < kPersist; ++j)
				tgt.Data()[base + j] = MLTModelCfg::kIgnoreTgt;
		}
	}

	// ══════════════════════════════════════════════════════════════════
	// ⭐ **회차 120 의 두 팔** — ⚠️ **표적만 바꾼다**(입력은 「없음」 그대로).
	// ══════════════════════════════════════════════════════════════════
	//   ★ **규율 34** 가 요구하는 형태다: *"정답을 넣는 자리 ≠ 채점하는 자리"*.
	//     여기 둘은 **중간 시각의 표적**을 바꾸고 채점은 **답 시각**이라 ***베낄 자리가 없다.***
	//   ⚠️ 회차 118 은 **입력**에 정답을 넣었고 그 자리가 곧 표적이라 **자명한 복사**였다.

	// ⭐ 기준선 팔 — 중간 표적을 **다른 문맥의 것**으로 바꾼다.
	//   ★ **개수·분포가 그대로**이고 ***"이 문맥의 진짜 사슬인가"* 만 없앤다**(회차 116 의 관용구).
	//   ⚠️ 짝은 **결정적**이어야 한다(같은 씨앗이면 같은 섞기) ⇒ `ctx ^ 1` 로 둔다.
	void ShuffleMidTargets(uint32 ctx, uint32 nCtx, Array<float>& tgt) const
	{
		const uint32 src = (ctx ^ 1u) < nCtx ? (ctx ^ 1u) : ctx;
		for (uint32 t = C::kTMid; t + 1u < kTime; ++t)
		{
			const uint32 base = Row(ctx, t, C::kSymAct);
			for (uint32 j = 0; j < kPersist; ++j)
				tgt.Data()[base + j] = (float)_tid[Tix(src, t, j)];
		}
	}

	// ⭐ **양성 대조** — 중간 표적을 **답과 같은 id** 로 둔다(*"중간에서 답을 미리 예측하게 한다"*).
	//   ⭐ 그러면 중간 네 시각이 전부 **답의 리허설**이 된다 ⇒ 답이 **반드시 좋아져야** 한다.
	//   ⚠️ 안 좋아지면 **자가 죽은 것**이다(규율 16).
	void MidTargetsToAnswer(uint32 ctx, Array<float>& tgt) const
	{
		for (uint32 t = C::kTMid; t + 1u < kTime; ++t)
		{
			const uint32 base = Row(ctx, t, C::kSymAct);
			for (uint32 j = 0; j < kPersist; ++j)
				tgt.Data()[base + j] = (float)_tid[Tix(ctx, C::kTAns, j)];
		}
	}

	// ⭐ **판정 ① 용** — 중간 입력을 **정답으로 채운다**(가림의 반대 팔).
	//   ⚠️⚠️ **회차 119 가 이 자를 무효로 만들었다**(규율 34) — 중간 시각의 **표적이 같은 id** 라
	//     ***모델이 자기 입력 슬롯을 베끼면 된다.*** ⇒ ★ **채점을 중간 밖(답)으로 옮기면 값이 무너진다**
	//     (실측: 회차 118 CE 0.296 → 회차 119 CE 10.64). **판정용으로 쓰지 마라.**
	//   ★ 남겨 두는 이유: `N2b`(자기 출력 되먹임)의 **워밍업**에는 여전히 쓸 수 있다(그때는 채점이 다르다).
	void FillMidInputs(uint32 ctx, Array<float>& val, Array<float>& sym) const
	{
		for (uint32 t = C::kTMid; t + 1u < kTime; ++t)
		{
			const uint32 base = Row(ctx, t, C::kSymAct);
			for (uint32 j = 0; j < kPersist; ++j)
			{
				sym.Data()[base + j] = (float)(C::kSymUnit + _tid[Tix(ctx, t, j)]);
				val.Data()[base + j] = 1.0f;    // ⚠️ 세기는 모른다 ⇒ 1.0 로 둔다(존재만 준다)
			}
		}
	}

	static uint32 Row(uint32 ctx, uint32 t, uint32 a)
	{
		const uint32 k = ctx / kBatch, b = ctx % kBatch;
		return k * kRows + b * kCtx + t * kAxes + a;
	}
	// ⭐ 표적 색인 — 중간·답 시각만 산다(`t` 는 `kTMid..kTAns`).
	static uint32 Tix(uint32 ctx, uint32 t, uint32 j)
	{ return (ctx * (C::kMid + 1u) + (t - C::kTMid)) * kPersist + j; }

	// ══════════════════════════════════════════════════════════════════
	// 🧮 복사 바닥 — ⚠️ `MLTP4Ctx` 와 **식이 같다**(자리만 옮겼다).
	// ══════════════════════════════════════════════════════════════════
	void Marginal(Array<float>& out) const
	{
		const uint32 n = Targets();
		Array<uint32> h; h.Reset(0);
		for (uint32 i = 0; i < _dict; ++i) h.Add(0u);
		for (uint32 i = 0; i < n; ++i) ++h.Data()[_tid[i]];
		out.Reset(0);
		for (uint32 i = 0; i < _dict; ++i) out.Add((float)((double)h[i] / (double)n));
	}

	double CeCopy(const Array<float>& marg, float lam, bool useSet, uint32 tOnly = kAllT1) const
	{
		double s = 0.0; uint32 n = 0u;
		for (uint32 ctx = 0; ctx < _act; ++ctx)
			for (uint32 t = C::kTMid; t < kTime; ++t)
			{
				if (tOnly != kAllT1 && t != tOnly) continue;
				for (uint32 j = 0; j < kPersist; ++j)
				{
					const uint32 ix = Tix(ctx, t, j);
					const uint32 v = _tid[ix];
					float p = (1.0f - lam) * marg[v];
					if (!useSet) { if (_prev[ix] == v) p += lam; }
					else
					{
						uint32 c = 0u;
						for (uint32 q = 0; q < kPersist; ++q) if (_prev[Tix(ctx, t, q)] == v) ++c;
						if (c > 0u) p += lam * ((float)c / (float)kPersist);
					}
					if (p < 1.0e-9f) p = 1.0e-9f;
					s += -(double)Log(p); ++n;
				}
			}
		return (n == 0u) ? 0.0 : (s / (double)n);
	}

	static float Lam(uint32 i)
	{
		if (i < 9u) return 0.1f * (float)(i + 1u);
		return (i == 9u) ? 0.95f : 0.99f;
	}

	void BestCopy(const Array<float>& marg, float& c1, float& c2, float& lam1, float& lam2,
		uint32 tOnly = kAllT1) const
	{
		double b1 = 1.0e30, b2 = 1.0e30; lam1 = 0.1f; lam2 = 0.1f;
		for (uint32 i = 0; i < C::kLam; ++i)
		{
			const float l = Lam(i);
			const double e1 = CeCopy(marg, l, false, tOnly);
			const double e2 = CeCopy(marg, l, true, tOnly);
			if (e1 < b1) { b1 = e1; lam1 = l; }
			if (e2 < b2) { b2 = e2; lam2 = l; }
		}
		c1 = (float)b1; c2 = (float)b2;
	}

	// ⭐ 판정 ② 용 — 그 문맥의 **답 표적**(과제 둘을 견줄 때 쓴다)
	uint32 AnsId(uint32 ctx, uint32 j) const { return _tid[Tix(ctx, C::kTAns, j)]; }

private:
	uint32 _nCtx = 0u, _act = 0u, _dict = 0u;
	bool _sortId = false;
	Array<float> _val, _tgt, _sym, _inv;
	Array<uint32> _tid, _prev, _task;
	// ⭐ `EYE` 의 활성 → 중간 첫 시각의 「직전」(복사 바닥용). ⚠️ 고정 배열을 쓰면 문맥 수 상한을
	//   **소스에 박는 것**이라 `Array` 로 둔다(`Begin` 이 크기를 맞춘다).
	Array<uint32> _lastId;
};
