// mltp3actx.cw — 🧩⚓ **P3 문맥 코퍼스 + 앵커** — ⭐ 회차 50 의 결정을 뒤집는 판
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 98 이다.**
//
// ── ⚠️⚠️ **왜 `MLTP3Ctx` 를 안 고치고 새로 만드나** ────────────────────────
//   `MLTP3Ctx` 를 **40개 하네스가 쓴다**(`mltp3c3` ~ `mltl0i0`). `kAxes` 를 13 → 29 로 바꾸면
//   ***회차 51~97 의 회귀 검사가 전부 깨진다*** — 복사 바닥 · 비트 동일 · 눈금이 통째로 어긋난다.
//   ⇒ ⭐ **P4 가 `MLTP4Ctx` 를 따로 만든 것과 같은 관용구**로 간다.
//
// ── ⭐ 무엇이 다른가 — **앵커(패치 자리)를 몸통에 싣는다** ───────────────
//   `MLTP3Ctx` 의 머리말은 이렇게 적혀 있었다:
//     *"⚠️ 앵커(패치 자리)는 **안 넣는다**(회차 50 등록의 그 결정 — 2D RoPE 가 새 커널이다)."*
//   ⇒ **회차 96 이 그 결정의 대가를 실측했다**: `minDOn`(내가 보는 가장 가까운 것)이
//     ***앵커 통계 8차원만으로 12/12*** 로 잡힌다 — 세기만 9차원은 11/12 · 전부 509차원은 8/12.
//   ★ ***크기는 「공간적 퍼짐」이고 퍼짐은 「자리」로만 잰다.***
//
// ── 배치 ──────────────────────────────────────────────────────────────────
//   | 축 | 개수 | 심볼 | 값 | 표적 |
//   | 상태 | 5 | `0..4` | 관측 상태 | **IgnoreTgt** |
//   | 활성 | 8 | `5 + id`(=`5..254`) | 세기(프레임 최대로 정규화) | **다음 시각의 id** |
//   | ⭐ **앵커** | **16** | `256 + 2j + q`(q=0 → ax · q=1 → ay) | ⭐ `2·g/(kGrid−1) − 1` ∈ `[-1,1]` | **IgnoreTgt** |
//   ⇒ **`kAxes = 29` · `kCtx = 232` · `kRows = 1856` · `kSymVocab = 272`**
//
//   ⭐ **왜 「두 값 축」인가**(심볼로 패치 id 를 주지 않고): 값 채널은 **다주파 사인 `Φ(v)`** 라
//     ***이웃한 자리가 비슷한 임베딩을 받는다*** — mltconcept 의 「시각의 이웃」을 **구조로 주는** 것이다.
//   ⚠️ 2D RoPE 는 **새 커널**이라 회차 50 이 미룬 것이고, ***이 판은 새 커널이 0개다.***
//
// ⚠️ 활성 선택(`q` 선택자)·정규화·표적 규약은 **`MLTP3Ctx` 와 한 글자도 안 다르다** —
//   달라진 것은 **앵커 16축을 더 실었다는 것뿐**이다(그래야 A/B 가 성립한다).
// ⚠️⚠️ 복사바닥(`Marginal`/`CeCopy`/`BestCopy`)은 **여기 없다** — 회차 98 이 안 쓴다.
//   필요해지면 그때 옮긴다(쓰지 않는 코드를 미리 복사해 두지 않는다).
// ══════════════════════════════════════════════════════════════════════════════

using namespace PE;

class MLTP3ACtx
{
public:
	static constexpr uint32 kStateAx = 5u;
	static constexpr uint32 kPersist = 8u;
	static constexpr uint32 kAncAx   = kPersist * 2u;            // 16 = 슬롯당 ax·ay
	static constexpr uint32 kAxes = kStateAx + kPersist + kAncAx; // 29
	static constexpr uint32 kTime = 8u;
	static constexpr uint32 kCtx  = kAxes * kTime;               // 232
	static constexpr uint32 kBatch = MLTModelCfg::kBatch;        // 8
	static constexpr uint32 kRows = kBatch * kCtx;               // 1856
	static constexpr uint32 kGrid = MLTP2Cfg::kGrid;             // 8
	static constexpr uint32 kLocalPerPatch = 8u;
	static constexpr uint32 kNoCand = 0xFFFFFFFFu;
	// 심볼 대역 — 상태 `0..4` · 활성 `5..(5+dict-1)` · 「없음」 · ⭐ **앵커 16**
	static constexpr uint32 kAncSym0 = kStateAx + 250u + 1u;     // 256(사전 250 기준)
	static constexpr uint32 kSymVocab = kAncSym0 + kAncAx;       // 272

	// ⚠️ 앵커 축의 시작 행 오프셋 — 활성 여덟 **뒤**다.
	static constexpr uint32 kAncBase = kStateAx + kPersist;      // 13

	void Begin(uint32 nCtx, uint32 dict)
	{
		_nCtx = nCtx; _dict = dict; _act = nCtx;
		const uint32 n = (nCtx / kBatch) * kRows;
		_val.Reset(0); _tgt.Reset(0); _sym.Reset(0);
		for (uint32 i = 0; i < n; ++i) { _val.Add(0.0f); _tgt.Add(0.0f); _sym.Add(0.0f); }
		_anc.Reset(0); _rawMag.Reset(0);
		for (uint32 i = 0; i < nCtx * kTime * kPersist; ++i) { _anc.Add(0u); _rawMag.Add(0.0f); }
		_inv.Reset(0);
		for (uint32 i = 0; i < nCtx * kTime; ++i) _inv.Add(0.0f);
	}

	void SetSortById(bool on) { _sortId = on; }
	uint32 NCtx() const { return _nCtx; }
	uint32 PoolSteps() const { return _nCtx / kBatch; }
	const Array<float>& Val() const { return _val; }
	const Array<float>& Tgt() const { return _tgt; }
	const Array<float>& Sym() const { return _sym; }
	uint32 Anc(uint32 ctx, uint32 t, uint32 j) const { return _anc[AncIx(ctx, t, j)]; }
	float  RawMag(uint32 ctx, uint32 t, uint32 j) const { return _rawMag[AncIx(ctx, t, j)]; }
	float  Inv(uint32 ctx, uint32 t) const { return _inv[ctx * kTime + t]; }

	// 상태 다섯 — `MLTP3Ctx` 와 같다.
	void StoreState(uint32 ctx, uint32 t, const MLTState& s)
	{
		const uint32 base = Row(ctx, t, 0u);
		for (uint32 a = 0; a < kStateAx; ++a)
		{
			_sym.Data()[base + a] = (float)a;
			_val.Data()[base + a] = s.Axis((int)a);
			_tgt.Data()[base + a] = (float)_dict;      // IgnoreTgt — 상태는 채점하지 않는다
		}
	}

	// ⭐ 격자 좌표를 `[-1,1]` 로 편다 — **다주파 사인이 이웃을 준다**.
	static float GridVal(uint32 g)
	{
		return 2.0f * (float)g / (float)(kGrid - 1u) - 1.0f;
	}

	// 활성 여덟 + ⭐ **앵커 열여섯** — 선택·정규화·표적은 `MLTP3Ctx` 와 한 글자도 안 다르다.
	void StoreAct(uint32 ctx, uint32 t, const Array<float>& ids, const Array<float>& mag,
		const Array<float>& norm)
	{
		const uint32 cand = ids.Count();
		uint32 pick[kPersist]; float pm[kPersist]; uint32 pa[kPersist];
		for (uint32 j = 0; j < kPersist; ++j) pa[j] = 0u;
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
				if (!(f >= 0.0f) || f >= (float)_dict) continue;
				const float sc = Abs(mag[c]) * norm[(uint32)f];
				if (!found || sc > best) { found = true; best = sc; bp = c; }
			}
			if (!found) { pick[j] = 0u; pm[j] = 0.0f; pa[j] = 0u; continue; }
			used.Data()[bp] = 1u; pick[j] = (uint32)ids[bp]; pm[j] = mag[bp];
			pa[j] = bp / kLocalPerPatch;
			const float a = Abs(pm[j]); if (a > maxAbs) maxAbs = a;
		}
		if (_sortId)
			for (uint32 a = 1; a < kPersist; ++a)
			{
				const uint32 kv = pick[a]; const float mv = pm[a]; const uint32 av = pa[a];
				uint32 b = a;
				while (b > 0u && pick[b - 1u] > kv)
				{ pick[b] = pick[b - 1u]; pm[b] = pm[b - 1u]; pa[b] = pa[b - 1u]; --b; }
				pick[b] = kv; pm[b] = mv; pa[b] = av;
			}
		const float inv = (maxAbs > 1.0e-12f) ? (1.0f / maxAbs) : 0.0f;
		const uint32 base = Row(ctx, t, kStateAx);
		for (uint32 j = 0; j < kPersist; ++j)
		{
			_sym.Data()[base + j] = (float)(kStateAx + pick[j]);
			_val.Data()[base + j] = pm[j] * inv;
			_tgt.Data()[base + j] = (float)_dict;
		}
		// ⭐ **앵커 열여섯** — 슬롯 `j` 의 `ax`·`ay` 를 **값 축 둘**로 싣는다.
		//   ⚠️ 심볼은 **슬롯과 축**만 말한다(`256 + 2j + q`) — 자리 자체는 **값**에 있다.
		//   ⚠️ 표적은 `IgnoreTgt` 다(앵커는 채점하지 않는다 — 상태 축과 같은 규약).
		const uint32 ab = Row(ctx, t, kAncBase);
		for (uint32 j = 0; j < kPersist; ++j)
		{
			const uint32 gx = pa[j] % kGrid, gy = pa[j] / kGrid;
			_sym.Data()[ab + 2u * j]      = (float)(kAncSym0 + 2u * j);
			_val.Data()[ab + 2u * j]      = GridVal(gx);
			_tgt.Data()[ab + 2u * j]      = (float)_dict;
			_sym.Data()[ab + 2u * j + 1u] = (float)(kAncSym0 + 2u * j + 1u);
			_val.Data()[ab + 2u * j + 1u] = GridVal(gy);
			_tgt.Data()[ab + 2u * j + 1u] = (float)_dict;
		}
		for (uint32 j = 0; j < kPersist; ++j)
		{
			_anc.Data()[AncIx(ctx, t, j)] = pa[j];
			_rawMag.Data()[AncIx(ctx, t, j)] = pm[j];
		}
		_inv.Data()[ctx * kTime + t] = inv;
		// 표적 = **직전 시각의 같은 슬롯**이 이번 id 를 맞힌다(`MLTP3Ctx` 와 같다).
		if (t > 0u)
		{
			const uint32 prev = Row(ctx, t - 1u, kStateAx);
			for (uint32 j = 0; j < kPersist; ++j) _tgt.Data()[prev + j] = (float)pick[j];
		}
	}

	static uint32 AncIx(uint32 ctx, uint32 t, uint32 j) { return (ctx * kTime + t) * kPersist + j; }
	// 풀 배치 규약 — `r = k·kRows + b·kCtx + t·kAxes + a`(`MLTP3Ctx` 와 같은 식 · 상수만 다르다)
	static uint32 Row(uint32 ctx, uint32 t, uint32 a)
	{
		const uint32 k = ctx / kBatch, b = ctx % kBatch;
		return k * kRows + b * kCtx + t * kAxes + a;
	}

private:
	Array<float> _val, _tgt, _sym, _rawMag, _inv;
	Array<uint32> _anc;
	uint32 _nCtx = 0u, _dict = 0u, _act = 0u;
	bool _sortId = false;

	CW_BODY(MLTP3ACtx)
};
