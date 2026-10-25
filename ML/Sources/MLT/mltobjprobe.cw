// mltobjprobe.cw — 🔬 **판정자: 활성이 물체를 가르나**(회차 46 의 짝 다섯) — ⚠️ **여기가 정본**이다
//
// ══════════════════════════════════════════════════════════════════════════════
// ★ **왜 파일로 뽑았나** — 회차 48 등록문이 *"판정자를 바꾸지 않는 것이 이 회차의 핵"* 이라고
//   못 박았다. 같은 자로 재야 두 표적의 **마진이 견줘진다.** 판정 코드가 회차마다 복사되면
//   *"표적이 좋아졌다"* 와 *"자를 바꿨다"* 가 섞이고, 그 어긋남은 **숫자만 보면 안 보인다.**
//   ⇒ 회차 46(`mltp2obj.cw`)과 회차 48(`mltp2fut.cw`)이 **이 한 클래스**를 쓴다.
//   ★ 그리고 회차 48 의 팔 ㈀ 이 **회차 46 재현 검사**로 그 동일성을 실제로 검사한다.
//
// ⚠️⚠️ **시뮬 은닉 상태는 판정자만 읽는다** — `MLTWorld::VisibleShapes` 가 그 창구이고 인코더
//   입력·손실·표적 어디에도 한 바이트도 안 들어간다(`mltworld.cw` 의 그 경고를 물려받는다).
//
// ── 짝 다섯 ────────────────────────────────────────────────────────────────
//   한 「출현」 = `(프레임 f, 도형 i)` · **대표 패치** = 그 도형이 **배타적으로 칠한** 8×8 칸 중
//   도형 중심에 가장 가까운 것. 활성 집합 `S` = 그 패치의 top-`k` id · 겹침 = `|S₁ ∩ S₂| / k`.
//   ⚠️ **모든 짝이 프레임을 건넌다**(안 맞추면 프레임 거리와 물체 차이가 섞인다).
//
//   | 칸 | 짝 | 무엇을 말하나 |
//   |---|---|---|
//   | ㈎ `cUp`    | 같은 도형 · **같은 패치** | 재현성 **상한**. 낮으면 나머지가 안 읽힌다 |
//   | ㈀ `cSame`  | 같은 도형 · **다른 패치** | identity 가 자리를 건너 재사용되나 |
//   | ㈁ `cCol`   | 다른 도형 · 다른 패치 · **같은 `col` · 다른 `kind`** | ㈀ 와 같으면 **색만** 가른 것 |
//   | ㈂ `cPos`   | 다른 도형 · **같은 패치** | ㈀ 보다 크면 활성은 **위치의 함수**다 |
//   | ㈃ `cFloor` | 다른 도형 · 다른 패치 · **다른 `col`** | 눈금(관문 아님) |

using namespace PE;

class MLTObjProbe
{
public:
	enum { cUp = 0, cSame = 1, cCol = 2, cPos = 3, cFloor = 4 };
	static constexpr uint32 kCells    = 5u;
	static constexpr uint32 kMinPairs = 30u;     // 씨앗을 읽는 최소 짝 수(회차 46 등록값)
	static constexpr float  kMinR      = 3.0f;   // 화면 반지름이 이보다 작으면 칸을 못 갖는다
	static constexpr float  kRingSlack = 2.0f;   // 빈 원의 테두리가 그 칸을 지나는가
	static constexpr uint32 kInvalid   = 0xFFFFFFFFu;

	void Reset(uint32 k)
	{
		_k = (k == 0u) ? 1u : k;
		_oFrame.Reset(0); _oShape.Reset(0); _oKind.Reset(0); _oCol.Reset(0); _oPatch.Reset(0);
		_oIds.Reset(0); _fStart.Reset(0); _fCount.Reset(0);
	}

	// 🌍 그 상태의 출현을 확정한다 — ⚠️ **그린 직후에** 부른다(`Render` 와 같은 상태여야 한다).
	void AddFrame(const MLTWorld& w)
	{
		typedef MLTP2Cfg C;
		const uint32 f = _fStart.Count();
		MLTShapeView sv[MLTWorldCfg::kShapes];
		const int n = w.VisibleShapes(sv, MLTWorldCfg::kShapes);
		_fStart.Add(_oFrame.Count());
		uint32 kept = 0u;
		for (int j = 0; j < n; ++j)
		{
			uint32 p = 0u;
			if (!_RepPatch(sv, n, j, p)) continue;
			_oFrame.Add(f); _oShape.Add((uint32)sv[j].index);
			_oKind.Add((uint32)sv[j].kind); _oCol.Add(sv[j].col); _oPatch.Add(p);
			for (uint32 t = 0; t < _k; ++t) _oIds.Add(kInvalid);   // 평가에서 채운다
			++kept;
		}
		_fCount.Add(kept);
	}

	uint32 FrameCount() const { return _fStart.Count(); }
	uint32 Occurrences() const { return _oFrame.Count(); }

	// 📖 그 프레임의 활성(`패치 × k`)을 받아 출현마다 id 를 채운다.
	//   ⚠️ 범위 밖은 `kInvalid` 로 둔다 — **어느 것과도 안 겹친다**(0 으로 채우면 유닛 0 과 겹친다).
	bool FillIds(uint32 frame, const Array<float>& ids, uint32 dict)
	{
		typedef MLTP2Cfg C;
		if (frame >= _fStart.Count() || ids.Count() != C::kPatches * _k) return false;
		const uint32 s = _fStart[frame], c = _fCount[frame];
		for (uint32 o = 0; o < c; ++o)
		{
			const uint32 p = _oPatch[s + o];
			for (uint32 t = 0; t < _k; ++t)
			{
				const float v = ids[p * _k + t];
				const uint32 id = (!(v >= 0.0f) || v >= (float)dict) ? kInvalid : (uint32)v;
				_oIds.Data()[(s + o) * _k + t] = id;
			}
		}
		return true;
	}

	// 🧮 다섯 칸의 평균 겹침과 짝 수. 반환 = **칸마다 짝이 `kMinPairs` 이상인가**(그 씨앗을 읽나).
	bool Score(float* cell, uint32* pairs) const
	{
		double sum[kCells]; uint32 cnt[kCells];
		for (uint32 i = 0; i < kCells; ++i) { sum[i] = 0.0; cnt[i] = 0u; }
		const uint32 m = _oFrame.Count();
		for (uint32 a = 0; a < m; ++a)
			for (uint32 b = a + 1u; b < m; ++b)
			{
				if (_oFrame[a] == _oFrame[b]) continue;          // ⚠️ 모든 칸이 프레임을 건넌다
				const bool sameShape = (_oShape[a] == _oShape[b]);
				const bool samePatch = (_oPatch[a] == _oPatch[b]);
				uint32 c = kCells;
				if (sameShape) c = samePatch ? (uint32)cUp : (uint32)cSame;
				else if (samePatch) c = (uint32)cPos;
				else if (_oCol[a] == _oCol[b]) { if (_oKind[a] != _oKind[b]) c = (uint32)cCol; }
				else c = (uint32)cFloor;
				if (c >= kCells) continue;
				sum[c] += (double)_Overlap(a, b);
				++cnt[c];
			}
		bool ok = true;
		for (uint32 i = 0; i < kCells; ++i)
		{
			pairs[i] = cnt[i];
			cell[i] = (cnt[i] == 0u) ? 0.0f : (float)(sum[i] / (double)cnt[i]);
			if (cnt[i] < kMinPairs) ok = false;
		}
		return ok;
	}

private:
	uint32 _k = 8u;
	Array<uint32> _oFrame, _oShape, _oKind, _oCol, _oPatch, _oIds;
	Array<uint32> _fStart, _fCount;

	// 🖌️ 그 도형이 **그 점을 칠하나** — `MLTWorld::Render` 의 세 갈래와 같은 식이다.
	//   ⚠️ 빈 원은 테두리만 그린다 ⇒ 안쪽은 「안 칠한 것」이다(그게 이 함수가 있는 이유).
	static bool _Paints(const MLTShapeView& s, float px, float py)
	{
		const float dx = px - s.sx, dy = py - s.sy;
		if (s.kind == 1) return (Abs(dx) <= s.r) && (Abs(dy) <= s.r);
		const float d = Sqrt(dx * dx + dy * dy);
		if (s.kind == 0) return d <= s.r;
		return Abs(d - s.r) <= (MLTWorldCfg::kStroke + kRingSlack);
	}

	// 대표 패치 — 배타적으로 칠한 칸 중 중심에 가장 가까운 것. 없으면 `false`.
	//   ⚠️ **배타성**(그 칸 중심을 칠하는 도형이 그것 하나)이 겹침·가림을 막는다.
	static bool _RepPatch(const MLTShapeView* sv, int n, int j, uint32& outPatch)
	{
		typedef MLTP2Cfg C;
		if (sv[j].r < kMinR) return false;
		bool found = false; float best = 0.0f; uint32 bestP = 0u;
		for (uint32 p = 0; p < C::kPatches; ++p)
		{
			const float cx = (float)((p % C::kGrid) * C::kPatch) + (float)C::kPatch * 0.5f;
			const float cy = (float)((p / C::kGrid) * C::kPatch) + (float)C::kPatch * 0.5f;
			if (!_Paints(sv[j], cx, cy)) continue;
			bool excl = true;
			for (int q = 0; q < n; ++q)
				if (q != j && _Paints(sv[q], cx, cy)) { excl = false; break; }
			if (!excl) continue;
			const float dx = cx - sv[j].sx, dy = cy - sv[j].sy;
			const float d = dx * dx + dy * dy;
			if (!found || d < best) { found = true; best = d; bestP = p; }
		}
		outPatch = bestP;
		return found;
	}

	float _Overlap(uint32 a, uint32 b) const
	{
		uint32 hit = 0u;
		for (uint32 i = 0; i < _k; ++i)
		{
			const uint32 x = _oIds[a * _k + i];
			if (x == kInvalid) continue;                 // 범위 밖은 안 센다
			for (uint32 j = 0; j < _k; ++j)
				if (_oIds[b * _k + j] == x) { ++hit; break; }
		}
		return (float)hit / (float)_k;
	}
};
