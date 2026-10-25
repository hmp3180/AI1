// mltp4ctx.cw — 🧩 **P4 문맥 코퍼스**(상태 5 + ⭐ **행동 5** + 활성 8) — ⚠️ **P4 의 정본**
//
// ══════════════════════════════════════════════════════════════════════════════
// ⚠️⚠️⚠️ **왜 `MLTP3Ctx` 를 안 고치고 새로 만드나** — 회차 76 설계 심사의 결정이다.
//   `MLTP3Ctx::kAxes` 는 **13** 이고 그 값이 P3 회차 전부의 **배치**다. 그것을 18 로 바꾸면
//   ***회차 51·52·59·60·73 의 회귀가 통째로 깨진다***(회차 75 가 그 회귀를 세운 지 하루도 안 됐다).
//   ⇒ ★ **`MLTP3Ctx` 는 P3 의 정본으로 얼린다.** 여기는 P4 의 자리다.
//
// ⚠️ 공유하는 것: `q` 선택자(회차 43) · id 오름차순 정렬(회차 55) · 최대 세기 정규화 ·
//   후보 색인/원세기/역수 저장(회차 65) · 복사 바닥(회차 51·60). ⇒ **식은 하나도 안 바꿨다.**
//
// ── 대역 배치 ────────────────────────────────────────────────────────────
//   `[상태 5][행동 5][활성 8]` × 시각 8  ⇒ `kAxes = 18` · `kCtx = 144` · `kRows = 1152`
//   ⚠️ **행동 슬롯의 표적은 `IgnoreTgt`** 다 — 행동을 표적으로 삼으면 그것은 **행동을 예측하는**
//     과제이고 `P5` 의 자리다(`mltconcept.md` 가 *"진짜 자기상태가 필요하다"* 로 미뤄 뒀다).
//   ⭐ 행동은 **컨텍스트 값 슬롯**이다 — 생성기가 낸다, 모델이 아니다(`MLT.md` P4 의 그 줄).

using namespace PE;

class MLTP4Ctx
{
public:
	static constexpr uint32 kStateAx = 5u;
	static constexpr uint32 kActAx   = 5u;                  // ⭐ P4 가 더한 대역
	static constexpr uint32 kPersist = 8u;
	static constexpr uint32 kAxes = kStateAx + kActAx + kPersist;   // 18
	static constexpr uint32 kTime = 8u;
	static constexpr uint32 kCtx  = kAxes * kTime;          // 144
	static constexpr uint32 kBatch = MLTModelCfg::kBatch;   // 8
	static constexpr uint32 kRows = kBatch * kCtx;          // 1152
	static constexpr uint32 kLam = 11u;
	static constexpr uint32 kLocalPerPatch = 8u;
	static constexpr uint32 kAllT1 = 0xFFFFFFFFu;
	static constexpr uint32 kNoCand = 0xFFFFFFFFu;
	// 대역의 시작 칸 — ⚠️ 이 셋만 보면 배치를 안다.
	static constexpr uint32 kOState = 0u;
	static constexpr uint32 kOAct   = kStateAx;             // 5
	static constexpr uint32 kOAct2  = kStateAx + kActAx;    // 10 (= 활성 시작)

	// ══════════════════════════════════════════════════════════════════
	// ⚠️⚠️⚠️ **시험 누출을 컴파일 타임에 막는다** (2026-08-27 · 회차 81 이 찾았다)
	// ══════════════════════════════════════════════════════════════════
	//   하네스가 `MLTWorld::Reset(seed, epi + ctx, ...)` 로 문맥을 만들므로
	//     학습 = `[kTrainEpi, kTrainEpi + kNCtx)` · 시험 = `[kTestEpi, kTestEpi + kTestCtx)`
	//   ⇒ **`kTestEpi ≥ kTrainEpi + kNCtx` 가 아니면 시험이 학습과 겹친다.**
	//   ⚠️ 실측: `kTrainEpi=1 · kNCtx=128 · kTestEpi=101` 이면 **101~128 = 시험의 43.75%** 가 샜다.
	//     회차 58·59·60·61·62·64·77·79·80 이 그 대역을 썼다. ⚠️ **회차 24 가 이미 밟은 함정**이다.
	//   ★ 새 하네스는 반드시 이것을 부른다: `MLTP4Ctx::AssertNoLeak(kTrainEpi, kNCtx, kTestEpi);`
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
		const uint32 m = nCtx * (kTime - 1u) * kPersist;
		_cand.Reset(0); _rawMag.Reset(0);
		for (uint32 i = 0; i < nCtx * kTime * kPersist; ++i) { _cand.Add(kNoCand); _rawMag.Add(0.0f); }
		_inv.Reset(0);
		for (uint32 i = 0; i < nCtx * kTime; ++i) _inv.Add(0.0f);
		_tid.Reset(0); _prev.Reset(0);
		for (uint32 i = 0; i < m; ++i) { _tid.Add(0u); _prev.Add(0u); }
	}

	void SetActive(uint32 n) { _act = (n == 0u || n > _nCtx) ? _nCtx : n; }
	void SetSortById(bool on) { _sortId = on; }

	uint32 NCtx() const { return _nCtx; }
	uint32 PoolSteps() const { return _nCtx / kBatch; }
	uint32 Targets() const { return _act * (kTime - 1u) * kPersist; }
	const Array<float>& Val() const { return _val; }
	const Array<float>& Tgt() const { return _tgt; }
	const Array<float>& Sym() const { return _sym; }
	uint32 Cand(uint32 ctx, uint32 t, uint32 j) const { return _cand[AncIx(ctx, t, j)]; }
	float  RawMag(uint32 ctx, uint32 t, uint32 j) const { return _rawMag[AncIx(ctx, t, j)]; }
	float  Inv(uint32 ctx, uint32 t) const { return _inv[ctx * kTime + t]; }

	// 상태 다섯 — ⚠️ 표적은 없다(채점하지 않는다).
	void StoreState(uint32 ctx, uint32 t, const MLTState& s)
	{
		const uint32 base = Row(ctx, t, kOState);
		for (uint32 a = 0; a < kStateAx; ++a)
		{
			_sym.Data()[base + a] = (float)a;
			_val.Data()[base + a] = s.Axis((int)a);
			_tgt.Data()[base + a] = (float)_dict;
		}
	}

	// ⭐ **행동 다섯** — P4 가 더한 것. ⚠️ **표적은 `IgnoreTgt`**(위 머리말의 그 이유).
	//   ⚠️ 심볼은 상태와 **겹치지 않는 번호**여야 한다 ⇒ `kStateAx + a`.
	void StoreAct5(uint32 ctx, uint32 t, const MLTAct& a)
	{
		const uint32 base = Row(ctx, t, kOAct);
		for (uint32 i = 0; i < kActAx; ++i)
		{
			_sym.Data()[base + i] = (float)(kStateAx + i);
			_val.Data()[base + i] = a.Axis((int)i);
			_tgt.Data()[base + i] = (float)_dict;
		}
	}

	// ══════════════════════════════════════════════════════════════════
	// ⭐ **표적 선택만** — 저장은 안 한다(회차 107 이 뽑아냈다).
	// ══════════════════════════════════════════════════════════════════
	//   ★ 왜 뽑아냈나: 회차 107 의 **반사실 프레임**이 *"내가 다른 행동을 했다면 이 슬롯의 표적이
	//     달랐겠나"* 를 묻는다 ⇒ **실기와 한 글자도 다르지 않은 선택 식**이 그 자리에 필요하다.
	//   ⚠️⚠️ **`StoreAct` 가 이 함수를 부른다** — 두 벌로 두면 반드시 갈리고, 갈리면 반사실이
	//     *"행동이 바꿨다"* 대신 *"선택 식이 달랐다"* 를 잰다(그리고 그것은 조용히 통과한다).
	//   ⚠️ 순수 함수다(멤버를 안 건드린다) — `dict`·`sortId` 를 인자로 받는 이유.
	static void Pick(const Array<float>& ids, const Array<float>& mag, const Array<float>& norm,
		uint32 dict, bool sortId, uint32* pick, float* pm, uint32* pc, float& maxAbsOut)
	{
		const uint32 cand = ids.Count();
		for (uint32 j = 0; j < kPersist; ++j) pc[j] = kNoCand;
		Array<uint8> used; used.Reset(0);
		for (uint32 c = 0; c < cand; ++c) used.Add(0u);
		float maxAbs = 0.0f;
		for (uint32 j = 0; j < kPersist; ++j)
		{
			bool found = false; float best = 0.0f; uint32 bp = 0u;
			for (uint32 c = 0; c < cand; ++c)
			{
				if (used[c] != 0u) continue;
				const float f = ids[c];
				if (!(f >= 0.0f) || f >= (float)dict) continue;
				const float sc = Abs(mag[c]) * norm[(uint32)f];
				if (!found || sc > best) { found = true; best = sc; bp = c; }
			}
			if (!found) { pick[j] = 0u; pm[j] = 0.0f; pc[j] = kNoCand; continue; }
			used.Data()[bp] = 1u; pick[j] = (uint32)ids[bp]; pm[j] = mag[bp]; pc[j] = bp;
			const float a = Abs(pm[j]); if (a > maxAbs) maxAbs = a;
		}
		if (sortId)
			for (uint32 a = 1; a < kPersist; ++a)
			{
				const uint32 kv = pick[a]; const float mv = pm[a]; const uint32 cv = pc[a];
				uint32 b = a;
				while (b > 0u && pick[b - 1u] > kv)
				{ pick[b] = pick[b - 1u]; pm[b] = pm[b - 1u]; pc[b] = pc[b - 1u]; --b; }
				pick[b] = kv; pm[b] = mv; pc[b] = cv;
			}
		maxAbsOut = maxAbs;
	}

	// 활성 여덟 — ⚠️ `MLTP3Ctx::StoreAct` 와 **식이 같다**(자리만 `kOAct2` 로 옮겼다).
	void StoreAct(uint32 ctx, uint32 t, const Array<float>& ids, const Array<float>& mag,
		const Array<float>& norm)
	{
		uint32 pick[kPersist]; float pm[kPersist]; uint32 pc[kPersist];
		float maxAbs = 0.0f;
		Pick(ids, mag, norm, _dict, _sortId, pick, pm, pc, maxAbs);
		const float inv = (maxAbs > 1.0e-12f) ? (1.0f / maxAbs) : 0.0f;
		const uint32 base = Row(ctx, t, kOAct2);
		for (uint32 j = 0; j < kPersist; ++j)
		{
			_sym.Data()[base + j] = (float)(kStateAx + kActAx + pick[j]);
			_val.Data()[base + j] = pm[j] * inv;
			_tgt.Data()[base + j] = (float)_dict;
			_cand.Data()[AncIx(ctx, t, j)] = pc[j];
			_rawMag.Data()[AncIx(ctx, t, j)] = pm[j];
		}
		_inv.Data()[ctx * kTime + t] = inv;
		if (t > 0u)
		{
			const uint32 prev = Row(ctx, t - 1u, kOAct2);
			for (uint32 j = 0; j < kPersist; ++j)
			{
				_tgt.Data()[prev + j] = (float)pick[j];
				_tid.Data()[Tix(ctx, t - 1u, j)] = pick[j];
				_prev.Data()[Tix(ctx, t - 1u, j)] =
					(uint32)(_sym[prev + j] - (float)(kStateAx + kActAx));
			}
		}
	}

	// ⭐ 표적만 갈아 끼운다 — **교차 설계**(회차 78)가 쓴다: 같은 컨텍스트에 **다른 미래의 표적**.
	//   ⚠️ 활성 슬롯의 표적만 바꾼다(상태·행동은 그대로 `IgnoreTgt`).
	void SwapTargetsFrom(const MLTP4Ctx& other)
	{
		for (uint32 ctx = 0; ctx < _nCtx; ++ctx)
			for (uint32 t = 0; t + 1u < kTime; ++t)
				for (uint32 j = 0; j < kPersist; ++j)
				{
					const uint32 r = Row(ctx, t, kOAct2 + j);
					_tgt.Data()[r] = other._tgt[r];
					_tid.Data()[Tix(ctx, t, j)] = other._tid[Tix(ctx, t, j)];
				}
	}

	static uint32 AncIx(uint32 ctx, uint32 t, uint32 j) { return (ctx * kTime + t) * kPersist + j; }
	static uint32 Row(uint32 ctx, uint32 t, uint32 a)
	{
		const uint32 k = ctx / kBatch, b = ctx % kBatch;
		return k * kRows + b * kCtx + t * kAxes + a;
	}
	static uint32 Tix(uint32 ctx, uint32 t1, uint32 j) { return (ctx * (kTime - 1u) + t1) * kPersist + j; }

	// ══════════════════════════════════════════════════════════════════
	// 🧮 바닥 — ⚠️ `MLTP3Ctx` 와 **식이 같다**(복사 바닥 · λ 스윕).
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

	double CeCopy(const Array<float>& marg, float lam, bool useSet, uint32 t1Only = kAllT1) const
	{
		double s = 0.0; uint32 n = 0u;
		for (uint32 ctx = 0; ctx < _act; ++ctx)
			for (uint32 t1 = 0; t1 + 1u < kTime; ++t1)
			{
				if (t1Only != kAllT1 && t1 != t1Only) continue;
				for (uint32 j = 0; j < kPersist; ++j)
				{
					const uint32 ix = Tix(ctx, t1, j);
					const uint32 v = _tid[ix];
					float p = (1.0f - lam) * marg[v];
					if (!useSet) { if (_prev[ix] == v) p += lam; }
					else
					{
						uint32 c = 0u;
						for (uint32 q = 0; q < kPersist; ++q) if (_prev[Tix(ctx, t1, q)] == v) ++c;
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
		uint32 t1Only = kAllT1) const
	{
		double b1 = 1.0e30, b2 = 1.0e30; lam1 = 0.1f; lam2 = 0.1f;
		for (uint32 i = 0; i < kLam; ++i)
		{
			const float l = Lam(i);
			const double e1 = CeCopy(marg, l, false, t1Only);
			const double e2 = CeCopy(marg, l, true, t1Only);
			if (e1 < b1) { b1 = e1; lam1 = l; }
			if (e2 < b2) { b2 = e2; lam2 = l; }
		}
		c1 = (float)b1; c2 = (float)b2;
	}

private:
	uint32 _nCtx = 0u, _act = 0u, _dict = 0u;
	bool _sortId = false;
	Array<float> _val, _tgt, _sym;
	Array<uint32> _tid, _prev, _cand;
	Array<float>  _rawMag, _inv;
};
