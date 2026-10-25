// mltp3ctx.cw — 🧩 **P3 문맥 코퍼스 + 복사 바닥** — ⚠️ **여기가 정본**이다
//
// ══════════════════════════════════════════════════════════════════════════════
// ★ **왜 파일로 뽑았나** — 회차 51 이 잰 **복사 바닥**을 회차 52 가 **회귀 검사**로 다시
//   써야 한다. 판정 코드가 회차마다 복사되면 *"문맥을 늘려서 좋아진 것"* 과 *"자를 바꾼 것"* 이
//   섞이고, 그 어긋남은 **숫자만 보면 안 보인다**(회차 46↔48 에서 `MLTObjProbe` 로 같은 판정을 했다).
//   ⇒ 회차 51(`mltp3c2.cw`)과 회차 52(`mltp3c3.cw`)가 **이 한 클래스**를 쓴다.
//
// ── 담는 것 ────────────────────────────────────────────────────────────────
//   ㈀ **문맥 코퍼스** — `(상태 5 + 활성 8) × time` 슬롯의 값·표적·심볼(몸통 풀 규약 그대로)
//   ㈁ **복사 바닥의 재료** — 표적 id 와 **직전 시각의 8개**(슬롯순)
//   ㈂ **바닥 셋** — M(주변분포) · C1(슬롯 복사) · C2(집합 복사) + λ 스윕
//
// ⚠️ 활성 선택은 회차 43 의 **`q` 선택자**(`|mag|·‖code‖₂` 탐욕) 그대로다 — 의미 비의존이고 표적을 안 본다.
// ⚠️ 앵커(패치 자리)는 **안 넣는다**(회차 50 등록의 그 결정 — 2D RoPE 가 새 커널이다).
// ⚠️⚠️ 시뮬 은닉 상태를 쓰지 않는다 — 여기 들어가는 상태 다섯은 **관측 상태**(`MLTState`)이고
//   그것은 P0 부터 모델의 **입력**이었다(라벨이 아니다).

using namespace PE;

class MLTP3Ctx
{
public:
	static constexpr uint32 kStateAx = 5u;
	static constexpr uint32 kPersist = 8u;
	static constexpr uint32 kAxes = kStateAx + kPersist;     // 13
	static constexpr uint32 kTime = 8u;
	static constexpr uint32 kCtx  = kAxes * kTime;           // 104
	static constexpr uint32 kBatch = MLTModelCfg::kBatch;    // 8
	static constexpr uint32 kRows = kBatch * kCtx;           // 832
	static constexpr uint32 kLam = 11u;
	static constexpr uint32 kGrid = MLTP2Cfg::kGrid;      // 8 — 앵커 격자 한 변
	static constexpr uint32 kRings = 4u;                   // 중심에서의 링 수(회차 57)
	static constexpr uint32 kLocalPerPatch = 8u;           // 후보 색인 = patch * 이것 + 슬롯
	static constexpr uint32 kAllT1 = 0xFFFFFFFFu;          // 「모든 예측 시각」(회차 60 의 `t1Only`)
	static constexpr uint32 kNoCand = 0xFFFFFFFFu;         // 「고른 후보가 없다」(회차 65)

	// 문맥 `nCtx` 개(=`nCtx/kBatch` 풀 스텝)를 담을 자리를 잡는다.
	void Begin(uint32 nCtx, uint32 dict)
	{
		_nCtx = nCtx; _dict = dict;
		const uint32 n = (nCtx / kBatch) * kRows;
		_val.Reset(0); _tgt.Reset(0); _sym.Reset(0);
		for (uint32 i = 0; i < n; ++i) { _val.Add(0.0f); _tgt.Add(0.0f); _sym.Add(0.0f); }
		_act = nCtx;
		const uint32 m = nCtx * (kTime - 1u) * kPersist;
		_anc.Reset(0); _cand.Reset(0); _rawMag.Reset(0);
		for (uint32 i = 0; i < nCtx * kTime * kPersist; ++i) { _anc.Add(0u); _cand.Add(0u); _rawMag.Add(0.0f); }
		_inv.Reset(0);
		for (uint32 i = 0; i < nCtx * kTime; ++i) _inv.Add(0.0f);
		_tid.Reset(0); _prev.Reset(0);
		for (uint32 i = 0; i < m; ++i) { _tid.Add(0u); _prev.Add(0u); }
	}

	// ⭐ **바닥은 그 팔이 실제로 본 데이터에서 맞춰야 한다**(회차 52 1차가 그 자리를 밟았다) —
	//   앞 `n` 문맥만 보게 한다. `Begin` 이 전체로 되돌린다.
	//   ⚠️ 코퍼스 자체는 안 자른다(몸통 풀은 부르는 쪽이 잘라 올린다) — 여기서 좁히는 것은
	//     **바닥 계산의 표본**뿐이다.
	void SetActive(uint32 n) { _act = (n == 0u || n > _nCtx) ? _nCtx : n; }
	uint32 Active() const { return _act; }

	// ⭐ **슬롯 배치**(회차 55) — `false` = `q` 선택 **순위**(지금까지) · `true` = **id 오름차순**.
	//   ⚠️ **활성 집합은 한 원소도 안 바뀐다 — 순서만 바뀐다.** 달라지는 것은 표적의 정렬 방식뿐이다.
	//   ★ 회차 51 이 그 대가를 쟀다: **슬롯 복사 0.642 ↔ 집합 복사 0.882**(차 **0.240**) ⇒ 같은 8개가
//     그대로 남는데도 **순위가 뒤바뀌어** 슬롯 표적이 틀린다 = **우리가 만든 잡음**이다.
	//   ⚠️ id 오름차순도 **불투명 정수의 순서**라 「축 이름을 주지 않는다」를 안 어긴다.
	//   ⚠️ `Begin` 보다 **먼저** 부르든 뒤에 부르든 되지만 `StoreAct` 전에는 정해져 있어야 한다.
	void SetSortById(bool on) { _sortId = on; }
	// ⭐ 회차 167 — **물체 항등성 · 배치 짝짓기**
	//   직전 시각의 슬롯 배치를 보고 **같은 id 는 그 자리**에 놓는다.
	//   ★ 그러면 「같은 id 가 자리를 옮기는 것」(= 밀림)이 **정의상 사라진다**.
	//   ⚠️⚠️ 못 막는 것도 분명하다 — **id 집합 자체가 바뀌는 것**(= 새id)은 그대로다
	//     (회차 166: 정지 세계 표적의 **77.7% 가 새id** 다) ⇒ 그것은 **선택 규칙**의 일이다.
	//   ⚠️ 기본 **false** ⇒ 기존 하네스 열여덟 개가 **비트 동일**하다.
	void SetMatchPrev(bool v) { _matchPrev = v; }
	bool MatchPrev() const { return _matchPrev; }
	// ⭐ 회차 168 — **선택 히스테리시스**(= 추적)
	//   지금 선택 규칙은 **「세기 상위 8」**이라 경계에서 흔들린다. 회차 166 이 그 원인을 지목했다:
	//     *"코드 8.9 개가 슬롯 8 개를 두고 경쟁하며 **경계의 하나가 들락날락**한다"*
	//   ⇒ ★ 처방 = **직전 시각에 뽑혔던 id 에 보너스** ⇒ 선택이 붙잡힌다.
	//   ⚠️ **곱셈**이라 세기 규모에 무관하다(덧셈이면 프레임마다 스케일이 달라 자가 흔들린다).
	//   ⚠️ `beta = 1` 이 기본 ⇒ 기존 하네스 전부 **비트 동일**.
	void SetHysteresis(float beta) { _hysBeta = (beta > 0.0f) ? beta : 1.0f; }
	float Hysteresis() const { return _hysBeta; }
	// ⭐ 회차 170 — **빈 슬롯을 허용한다**(세기 문턱)
	//   ⚠️ 지금 선택 루프는 ***무조건 여덟을 채운다*** ⇒ 정지 세계에서 세기가 거의 0 인
	//     후보까지 억지로 뽑히고, 그것들이 **들락날락**한다(회차 166 이 지목한 그 잡음).
	//   ⇒ ★ 처방: `sc < alpha × scMax` 이면 **뽑지 않고 슬롯을 비운다**.
	//     ⭐ **상대 문턱**이라 프레임마다 규모가 달라도 자가 안 흔들린다.
	//     ⭐ `scMax` 는 **그 프레임 안에서** 구한다 ⇒ 코퍼스 통계를 안 본다(훔쳐보기 없음).
	//   ⚠️ alpha = 0 이 기본 ⇒ 기존 하네스 전부 **비트 동일**.
	//   ★ 이것이 회차 169 가 등록한 「슬롯 수 16」의 **싼 대체**다 —
	//     `kPersist` 는 그대로 8 이고(276 곳 · 69 파일 수술이 없다) 효과는 같다.
	void SetFloor(float alpha) { _floor = (alpha >= 0.0f) ? alpha : 0.0f; }
	float Floor() const { return _floor; }
	// ⭐ 회차 171 — **죽은 패치를 슬롯에서 뺀다**(규율 65)
	//   ⚠️ 회차 170 이 배운 것: 인코더 출력의 **상대 문턱은 아무것도 안 걸린다**
	//     (sparse coding 은 입력이 약해도 상위 k 를 채운다 ⇒ 상대 순위가 규모에 무관).
	//   ⇒ ★ 그래서 **인코더 앞단**을 본다: 그 패치의 패킹 바이트가 **전부 0** 이면
	//     그 패치에서 온 후보를 **슬롯에 안 넣는다**.
	//   ★ 이것이 회차 158 이 설계한 그 불변식이다 — *\"안 움직였다 = 델타 전부 0\"*.
	//   ⭐ 절대적이다 — *\"바이트가 0 인가\"* 는 규모에도 씨앗에도 무관하다.
	//   ⚠️ 기본 꺼짐(`_liveOn = false`) ⇒ 기존 하네스 전부 비트 동일.
	void SetLiveOnly(bool v) { _liveOn = v; }
	bool LiveOnly() const { return _liveOn; }
	// ⭐ 서명 — 그 (문맥,시각)에 **실제로 채운 슬롯 수**(누적 평균을 하네스가 낸다)
	uint32 FilledSum() const { return _fillSum; }
	uint32 FilledN() const { return _fillN; }
	void ResetFilled() { _fillSum = 0u; _fillN = 0u; }
	bool SortById() const { return _sortId; }

	uint32 NCtx() const { return _nCtx; }
	uint32 PoolSteps() const { return _nCtx / kBatch; }
	uint32 Targets() const { return _act * (kTime - 1u) * kPersist; }
	const Array<float>& Val() const { return _val; }
	const Array<float>& Tgt() const { return _tgt; }
	const Array<float>& Sym() const { return _sym; }
	// ⭐ 회차 65 — 인코더로 되돌리는 재료. ⚠️ **판정 창구가 아니라 배관 정보**다(세계의 은닉 상태가 아니다).
	// ⭐ **앵커(패치 자리) 읽기** — ⚠️ 이것은 **몸통에 안 올라간다**(위 ⚠️ 의 그 결정).
	//   판정자가 *"자리가 무엇을 담나"* 를 재는 창구다(첫 소비자 = 회차 94).
	uint32 Anc(uint32 ctx, uint32 t, uint32 j) const { return _anc[AncIx(ctx, t, j)]; }
	uint32 Cand(uint32 ctx, uint32 t, uint32 j) const { return _cand[AncIx(ctx, t, j)]; }
	float  RawMag(uint32 ctx, uint32 t, uint32 j) const { return _rawMag[AncIx(ctx, t, j)]; }
	float  Inv(uint32 ctx, uint32 t) const { return _inv[ctx * kTime + t]; }
	// ⚠️ 값 슬롯을 **다시 정규화**해 덮어쓴다(중앙차분이 `pm` 을 흔든 뒤 부르는 자리).
	//   ★ 여기 한 곳에만 두는 이유: 정규화 식이 두 곳에 살면 반드시 한쪽이 진다.
	void RewriteVals(uint32 ctx, uint32 t)
	{
		float maxAbs = 0.0f;
		for (uint32 j = 0; j < kPersist; ++j)
		{ const float a = Abs(_rawMag[AncIx(ctx, t, j)]); if (a > maxAbs) maxAbs = a; }
		const float inv = (maxAbs > 1.0e-12f) ? (1.0f / maxAbs) : 0.0f;
		_inv.Data()[ctx * kTime + t] = inv;
		const uint32 base = Row(ctx, t, kStateAx);
		for (uint32 j = 0; j < kPersist; ++j) _val.Data()[base + j] = _rawMag[AncIx(ctx, t, j)] * inv;
	}
	void SetRawMag(uint32 ctx, uint32 t, uint32 j, float v) { _rawMag.Data()[AncIx(ctx, t, j)] = v; }

	// 그 문맥·시각의 **상태 다섯**(GPU 와 무관하다 — 렌더할 때 바로 적는다).
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

	// 그 문맥·시각의 **활성 여덟** — `q` 선택자로 512 후보에서 고른다.
	//   ⚠️ `patchLive` 는 **패치 개수 길이**(kPatches=64)이고 0 이면 그 패치는 죽었다.
	//     기본 `nullptr` ⇒ 기존 호출이 한 줄도 안 바뀐다.
	void StoreAct(uint32 ctx, uint32 t, const Array<float>& ids, const Array<float>& mag,
		const Array<float>& norm, const Array<uint8>* patchLive = nullptr)
	{
		const uint32 cand = ids.Count();
		uint32 pick[kPersist]; float pm[kPersist]; uint32 pa[kPersist]; uint32 pc[kPersist];
		for (uint32 j = 0; j < kPersist; ++j) { pa[j] = 0u; pc[j] = kNoCand; }
		Array<uint8> used; used.Reset(0);
		for (uint32 c = 0; c < cand; ++c) used.Add(0u);
		// ⭐ 회차 171 — **죽은 패치에서 온 후보를 미리 배제**한다.
		//   후보 색인 c 의 패치는 `c / kLocalPerPatch` 다(회차 57 의 그 규약).
		if (_liveOn && patchLive != nullptr)
			for (uint32 c = 0; c < cand; ++c)
			{
				const uint32 p = c / kLocalPerPatch;
				if (p < patchLive->Count() && (*patchLive)[p] == 0u) used.Data()[c] = 1u;
			}
		// ⭐ 회차 168 — **직전 시각에 뽑혔던 id 집합**을 만든다(히스테리시스의 대상).
		//   ⚠️ id 로 판정한다 — 같은 코드가 **다른 패치**에서 나와도 *"같은 것"* 이다.
		bool hysOn = (_hysBeta > 1.0f) && (t > 0u);
		Array<uint8> prevId;
		if (hysOn)
		{
			prevId.Reset(0);
			for (uint32 i = 0; i < _dict; ++i) prevId.Add(0u);
			const uint32 pbase2 = Row(ctx, t - 1u, kStateAx);
			for (uint32 j = 0; j < kPersist; ++j)
			{
				if (_cand[AncIx(ctx, t - 1u, j)] == kNoCand) continue;   // 직전이 빈 슬롯
				const uint32 pid = (uint32)(_sym[pbase2 + j] - (float)kStateAx);
				if (pid < _dict) prevId.Data()[pid] = 1u;
			}
		}
		// ⭐ 회차 170 — 먼저 **그 프레임의 최고 점수**를 구한다(상대 문턱의 분모).
		//   ⚠️ 히스테리시스 보너스를 **포함해서** 구한다 — 안 그러면 두 자가 어긋난다.
		float scMax = 0.0f;
		if (_floor > 0.0f)
			for (uint32 c = 0; c < cand; ++c)
			{
				const float f = ids[c];
				if (!(f >= 0.0f) || f >= (float)_dict) continue;
				float sc = Abs(mag[c]) * norm[(uint32)f];
				if (hysOn && prevId[(uint32)f] != 0u) sc *= _hysBeta;
				if (sc > scMax) scMax = sc;
			}
		const float scFloor = _floor * scMax;
		uint32 filled = 0u;
		float maxAbs = 0.0f;
		for (uint32 j = 0; j < kPersist; ++j)
		{
			bool found = false; float best = 0.0f; uint32 bp = 0u;
			for (uint32 c = 0; c < cand; ++c)
			{
				if (used[c] != 0u) continue;
				const float f = ids[c];
				if (!(f >= 0.0f) || f >= (float)_dict) continue;
				float sc = Abs(mag[c]) * norm[(uint32)f];
				// ⭐ 회차 168 — 직전에 뽑혔던 id 면 **β 배**(추적)
				if (hysOn && prevId[(uint32)f] != 0u) sc *= _hysBeta;
				// ⭐ 회차 170 — **문턱 아래는 뽑지 않는다**(그 슬롯은 빈다)
				if (_floor > 0.0f && sc < scFloor) continue;
				if (!found || sc > best) { found = true; best = sc; bp = c; }
			}
			if (!found) { pick[j] = 0u; pm[j] = 0.0f; pa[j] = 0u; pc[j] = kNoCand; continue; }
			++filled;
			used.Data()[bp] = 1u; pick[j] = (uint32)ids[bp]; pm[j] = mag[bp]; pc[j] = bp;
			// ⭐ 회차 57 — **앵커**(패치 자리)를 함께 남긴다. 후보 색인이 `patch * kLocal + 슬롯` 이다.
			pa[j] = bp / kLocalPerPatch;
			const float a = Abs(pm[j]); if (a > maxAbs) maxAbs = a;
		}
		// ⭐ 회차 167 — **배치 짝짓기**가 켜져 있고 직전 시각이 있으면 그것이 먼저다.
		//   ① 직전 슬롯과 **같은 id** 를 그 자리에  ② 남은 것을 **빈 슬롯**에 id 오름차순으로
		//   ⚠️ 직전 슬롯이 **비어 있으면**(`_cand == kNoCand`) 짝짓기 대상이 아니다
		//     — 안 그러면 **id 0 끼리 잘못 짝지어진다**(빈 슬롯의 pick 이 0 이다).
		bool matched = false;
		if (_matchPrev && t > 0u)
		{
			const uint32 pbase = Row(ctx, t - 1u, kStateAx);
			uint32 npick[kPersist]; float npm[kPersist]; uint32 npa[kPersist]; uint32 npc[kPersist];
			uint8 placed[kPersist], filled[kPersist];
			for (uint32 j = 0; j < kPersist; ++j)
			{
				npick[j] = 0u; npm[j] = 0.0f; npa[j] = 0u; npc[j] = kNoCand;
				placed[j] = 0u; filled[j] = 0u;
			}
			// ① 같은 id 를 그 자리에
			for (uint32 j = 0; j < kPersist; ++j)
			{
				if (_cand[AncIx(ctx, t - 1u, j)] == kNoCand) continue;   // 직전이 빈 슬롯
				const uint32 prev = (uint32)(_sym[pbase + j] - (float)kStateAx);
				for (uint32 c = 0; c < kPersist; ++c)
				{
					if (placed[c] != 0u || pc[c] == kNoCand) continue;
					if (pick[c] != prev) continue;
					npick[j] = pick[c]; npm[j] = pm[c]; npa[j] = pa[c]; npc[j] = pc[c];
					placed[c] = 1u; filled[j] = 1u; break;
				}
			}
			// ② 남은 것을 id 오름차순으로 빈 슬롯에(결정적이게)
			for (uint32 pass = 0; pass < kPersist; ++pass)
			{
				uint32 bestC = kPersist; uint32 bestId = 0u;
				for (uint32 c = 0; c < kPersist; ++c)
				{
					if (placed[c] != 0u || pc[c] == kNoCand) continue;
					if (bestC == kPersist || pick[c] < bestId) { bestC = c; bestId = pick[c]; }
				}
				if (bestC == kPersist) break;
				uint32 slot = kPersist;
				for (uint32 j = 0; j < kPersist; ++j) if (filled[j] == 0u) { slot = j; break; }
				if (slot == kPersist) break;
				npick[slot] = pick[bestC]; npm[slot] = pm[bestC];
				npa[slot] = pa[bestC]; npc[slot] = pc[bestC];
				placed[bestC] = 1u; filled[slot] = 1u;
			}
			for (uint32 j = 0; j < kPersist; ++j)
			{ pick[j] = npick[j]; pm[j] = npm[j]; pa[j] = npa[j]; pc[j] = npc[j]; }
			matched = true;
		}
		// ⭐ 회차 55 — 슬롯 배치를 **id 오름차순**으로(삽입 정렬 · `kPersist = 8`).
		//   ⚠️ `pick` 과 `pm` 을 **짝으로** 옮긴다 — 하나만 옮기면 세기가 엉뚱한 id 에 붙는다.
		if (_sortId && !matched)
			for (uint32 a = 1; a < kPersist; ++a)
			{
				const uint32 kv = pick[a]; const float mv = pm[a]; const uint32 av = pa[a];
				const uint32 cv = pc[a];
				uint32 b = a;
				while (b > 0u && pick[b - 1u] > kv)
				{
					pick[b] = pick[b - 1u]; pm[b] = pm[b - 1u];
					pa[b] = pa[b - 1u]; pc[b] = pc[b - 1u]; --b;
				}
				pick[b] = kv; pm[b] = mv; pa[b] = av; pc[b] = cv;
			}
		// ⚠️ `val_enc` 의 등록 범위가 `[-1,1]` 이라 **그 프레임의 최대 세기로 나눈다**(상대 세기).
		const float inv = (maxAbs > 1.0e-12f) ? (1.0f / maxAbs) : 0.0f;
		const uint32 base = Row(ctx, t, kStateAx);
		for (uint32 j = 0; j < kPersist; ++j)
		{
			_sym.Data()[base + j] = (float)(kStateAx + pick[j]);
			_val.Data()[base + j] = pm[j] * inv;
			_tgt.Data()[base + j] = (float)_dict;
		}
		// ⭐ 회차 57 — **앵커를 모든 시각에** 남긴다(`AncIx`). 표적 `(ctx, t1, j)` 의 「직전 앵커」는
		//   정의상 `AncIx(ctx, t1, j)` 다 — 따로 옮길 필요가 없다.
		for (uint32 j = 0; j < kPersist; ++j) _anc.Data()[AncIx(ctx, t, j)] = pa[j];
		// ⭐ 회차 65 — **인코더로 되돌리는 데 필요한 것 셋**을 남긴다:
		//   `cand` = 그 슬롯이 온 **후보 색인**(`patch·kLocalPerPatch + 로컬슬롯`) ·
		//   `rawMag` = **정규화 전** 세기 · `inv` = 그 (문맥,시각)의 `1/maxAbs`.
		//   ⚠️ 이것이 없으면 `dVal` 을 **어느 후보로** 되돌릴지 알 수 없다(앵커는 패치까지만 말한다).
		for (uint32 j = 0; j < kPersist; ++j)
		{
			_cand.Data()[AncIx(ctx, t, j)] = pc[j];
			_rawMag.Data()[AncIx(ctx, t, j)] = pm[j];
		}
		_inv.Data()[ctx * kTime + t] = inv;
		_fillSum += filled; ++_fillN;   // ⭐ 170 서명
		// ⭐ 표적은 **직전 시각의 같은 슬롯**이 이번 id 를 맞히는 것이다.
		if (t > 0u)
		{
			const uint32 prev = Row(ctx, t - 1u, kStateAx);
			for (uint32 j = 0; j < kPersist; ++j)
			{
				// ⭐ 회차 171 — **빈 슬롯은 표적이 아니다**.
				//   ⚠️ 빈 슬롯의 `pick` 은 0 인데 그것이 표적으로 들어가면
				//     「id 0 -> 다른 id」가 **가짜 변화**가 된다(실측: 정지 표적 8.9 -> 29.4).
				//   ⇒ ★ 직전이나 지금 중 **하나라도 비면** 그 자리는 `IgnoreTgt`.
				//   ⚠️ 빈 슬롯은 `_liveOn`/`_floor` 를 켠 때만 생긴다 ⇒ 기존 회차 **비트 동일**.
				const bool nowEmpty  = (pc[j] == kNoCand);
				const bool prevEmpty = (_cand[AncIx(ctx, t - 1u, j)] == kNoCand);
				if (nowEmpty || prevEmpty)
				{
					_tgt.Data()[prev + j] = (float)_dict;              // IgnoreTgt
					_tid.Data()[Tix(ctx, t - 1u, j)] = _dict;
					_prev.Data()[Tix(ctx, t - 1u, j)] = _dict;
					continue;
				}
				_tgt.Data()[prev + j] = (float)pick[j];
				_tid.Data()[Tix(ctx, t - 1u, j)] = pick[j];
				_prev.Data()[Tix(ctx, t - 1u, j)] = (uint32)(_sym[prev + j] - (float)kStateAx);
			}
		}
	}

	// 앵커 자리 — **모든 시각**(`kTime`)이라 `Tix`(표적용 `kTime-1`)와 크기가 다르다.
	static uint32 AncIx(uint32 ctx, uint32 t, uint32 j) { return (ctx * kTime + t) * kPersist + j; }
	// 8×8 격자에서 중심으로부터의 **링**(0=안쪽 … 3=바깥). ⚠️ 격자 좌표의 함수일 뿐 의미 라벨이 아니다.
	static uint32 Ring(uint32 anchor)
	{
		const float gx = (float)(anchor % kGrid), gy = (float)(anchor / kGrid);
		const float c = ((float)kGrid - 1.0f) * 0.5f;
		const float dx = Abs(gx - c), dy = Abs(gy - c);
		const uint32 r = (uint32)((dx > dy) ? dx : dy);
		return (r >= kRings) ? (kRings - 1u) : r;
	}

	// 풀 배치 규약 — `r = k·kRows + b·kCtx + t·kAxes + a`
	static uint32 Row(uint32 ctx, uint32 t, uint32 a)
	{
		const uint32 k = ctx / kBatch, b = ctx % kBatch;
		return k * kRows + b * kCtx + t * kAxes + a;
	}
	static uint32 Tix(uint32 ctx, uint32 t1, uint32 j) { return (ctx * (kTime - 1u) + t1) * kPersist + j; }

	// ══════════════════════════════════════════════════════════════════
	// 🧮 바닥 — M(주변분포) · C1(슬롯 복사) · C2(집합 복사)
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

	double CeMarginal(const Array<float>& marg) const
	{
		const uint32 n = Targets();
		double s = 0.0;
		for (uint32 i = 0; i < n; ++i)
		{
			float p = marg[_tid[i]];
			if (p < 1.0e-9f) p = 1.0e-9f;
			s += -(double)Log(p);
		}
		return s / (double)n;
	}

	// `useSet == false` → C1(슬롯) · `true` → C2(집합)
	// ⭐ **`t1Only`(회차 60)** — 바닥을 **그 예측 시각 하나에서만** 잰다.
	//   ⚠️ 이유는 하나다: **몸통을 채점하는 자리와 바닥을 재는 자리가 같아야 한다.** 회차 60 은
	//     과거를 끊는 개입이라 시각 `0..t-1` 의 표적은 *"자기 입력이 끊겼다"* 를 재게 된다 ⇒ 채점을
	//     **마지막 예측 시각**으로 좁히는데, 바닥이 여전히 전 시각 평균이면 **다른 자를 견주는 것**이 된다.
	//   ⚠️ `kAllT1` 이면 지금까지와 **비트 동일**하다(회차 51·52·59 의 숫자가 안 흔들린다).
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

	// λ 를 **이 코퍼스에서** 골라 C1*·C2* 를 낸다(⭐ 바닥에 일부러 유리하게).
	// ⚠️ `t1Only` 는 위 `CeCopy` 와 **같은 뜻**이고 λ 도 그 자리에서 고른다(자를 통째로 옮긴다).
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

	// ══════════════════════════════════════════════════════════════════
	// ⭐ 회차 57 — **앵커 링**으로 조건화한 집합 복사(`C4`) · 링별 지속률
	// ══════════════════════════════════════════════════════════════════
	//   `C2` 와 **같은 식**인데 λ 를 **링마다 따로** 쓴다 ⇒ 전부 같게 두면 정확히 `C2` 다
	//   ⇒ **`C4` 는 `C2` 보다 나쁠 수 없다.** 그래서 판정은 「낮아지나」가 아니라 **「얼마나」**다.
	double CeCopyRing(const Array<float>& marg, const float* lam) const
	{
		double s = 0.0; uint32 n = 0u;
		for (uint32 ctx = 0; ctx < _act; ++ctx)
			for (uint32 t1 = 0; t1 + 1u < kTime; ++t1)
				for (uint32 j = 0; j < kPersist; ++j)
				{
					const uint32 ix = Tix(ctx, t1, j);
					const uint32 v = _tid[ix];
					// ⚠️ 링은 **표적이 아니라 직전 시각 그 슬롯의 앵커**로 정한다(미래를 안 본다).
					const float l = lam[Ring(_anc[AncIx(ctx, t1, j)])];
					float p = (1.0f - l) * marg[v];
					uint32 c = 0u;
					for (uint32 q = 0; q < kPersist; ++q) if (_prev[Tix(ctx, t1, q)] == v) ++c;
					if (c > 0u) p += l * ((float)c / (float)kPersist);
					if (p < 1.0e-9f) p = 1.0e-9f;
					s += -(double)Log(p); ++n;
				}
		return (n == 0u) ? 0.0 : (s / (double)n);
	}

	// 링마다 λ 를 **따로** 고른다 — 링별로 CE 가 분리되므로 독립 스윕이 정확하다.
	void BestCopyRing(const Array<float>& marg, float* lamOut) const
	{
		for (uint32 r = 0; r < kRings; ++r)
		{
			double best = 1.0e30; float bl = Lam(0u);
			for (uint32 i = 0; i < kLam; ++i)
			{
				const float l = Lam(i);
				double s = 0.0; uint32 n = 0u;
				for (uint32 ctx = 0; ctx < _act; ++ctx)
					for (uint32 t1 = 0; t1 + 1u < kTime; ++t1)
						for (uint32 j = 0; j < kPersist; ++j)
						{
							const uint32 ix = Tix(ctx, t1, j);
							if (Ring(_anc[AncIx(ctx, t1, j)]) != r) continue;
							const uint32 v = _tid[ix];
							float p = (1.0f - l) * marg[v];
							uint32 c = 0u;
							for (uint32 q = 0; q < kPersist; ++q) if (_prev[Tix(ctx, t1, q)] == v) ++c;
							if (c > 0u) p += l * ((float)c / (float)kPersist);
							if (p < 1.0e-9f) p = 1.0e-9f;
							s += -(double)Log(p); ++n;
						}
				if (n == 0u) continue;
				const double e = s / (double)n;
				if (e < best) { best = e; bl = l; }
			}
			lamOut[r] = bl;
		}
	}

	// 눈금 — **링별 집합 지속률**(그 폭이 「앵커가 가르는 양」이다).
	void PersistByRing(float* rate, uint32* cnt) const
	{
		for (uint32 r = 0; r < kRings; ++r) { rate[r] = 0.0f; cnt[r] = 0u; }
		uint32 hit[kRings];
		for (uint32 r = 0; r < kRings; ++r) hit[r] = 0u;
		for (uint32 ctx = 0; ctx < _act; ++ctx)
			for (uint32 t1 = 0; t1 + 1u < kTime; ++t1)
				for (uint32 j = 0; j < kPersist; ++j)
				{
					const uint32 ix = Tix(ctx, t1, j);
					const uint32 r = Ring(_anc[AncIx(ctx, t1, j)]);
					++cnt[r];
					for (uint32 q = 0; q < kPersist; ++q)
						if (_tid[ix] == _prev[Tix(ctx, t1, q)]) { ++hit[r]; break; }
				}
		for (uint32 r = 0; r < kRings; ++r) rate[r] = (cnt[r] == 0u) ? 0.0f : ((float)hit[r] / (float)cnt[r]);
	}

	// 눈금 — 복사 정확도 둘(그 차가 「`q` 순위가 흔드는 몫」이다).
	void CopyAcc(float& slot, float& set) const
	{
		const uint32 n = Targets();
		uint32 hs = 0u, he = 0u;
		for (uint32 ctx = 0; ctx < _act; ++ctx)
			for (uint32 t1 = 0; t1 + 1u < kTime; ++t1)
				for (uint32 j = 0; j < kPersist; ++j)
				{
					const uint32 ix = Tix(ctx, t1, j);
					if (_tid[ix] == _prev[ix]) ++hs;
					for (uint32 q = 0; q < kPersist; ++q)
						if (_tid[ix] == _prev[Tix(ctx, t1, q)]) { ++he; break; }
				}
		slot = (float)hs / (float)n; set = (float)he / (float)n;
	}

private:
	uint32 _nCtx = 0u, _act = 0u, _dict = 0u;
	bool _sortId = false;
	bool _matchPrev = false;   // ⭐ 167
	float _hysBeta = 1.0f;     // ⭐ 168
	float _floor = 0.0f;       // ⭐ 170
	bool _liveOn = false;      // ⭐ 171
	uint32 _fillSum = 0u, _fillN = 0u;   // ⭐ 170 서명
	Array<float> _val, _tgt, _sym;
	Array<uint32> _tid, _prev, _anc;
	Array<uint32> _cand;              // 회차 65 — 그 슬롯이 온 후보 색인
	Array<float>  _rawMag, _inv;      // 회차 65 — 정규화 전 세기 · 1/maxAbs
};
