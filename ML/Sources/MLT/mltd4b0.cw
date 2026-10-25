// mltd4b0.cw — 📊 회차 129 · **D4-b: 발생률을 고정한다** (`-mltd4b0`)
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 129 다.** ⭐ **하네스보다 먼저 썼다.**
//   **상위 캔버스: `자를 고친다` · 128~129 = 2회차**(규율 33).
//
// ── ⭐ 왜 이 회차인가 — **규율 39 가 요구한다** ──────────────────────
//   회차 128: 몸통 학습이 **「가끔·크게」** 갈린다(실행 1 의 벌2↔3 에서 **96.7%** · `max|Δ| 0.245`,
//   실행 2·3 은 여섯 쌍 전부 깨끗). ⇒ ★ **race/미초기화 읽기의 모양**이다.
//   ⚠️⚠️ 그런데 지금 가진 것은 **1건 / 대략 12벌 ≈ 8%** 어림뿐이다 —
//     ***그 하나로는 "고쳤다" 를 판정할 수 없다***(규율 39: 「고쳤다」와 「숨었다」는 구별이 안 된다).
//   ⇒ ⭐ **먼저 발생률을 수로 고정한다.** 그것이 있어야 고침의 **전후**를 견줄 수 있다.
//
// ── 🔬 자 — ⭐ **회차 128 하네스를 구조 그대로 두고 벌만 32 로** ──────────
//   ⚠️⚠️ **구조를 안 바꾸는 것이 이 회차의 규율이다**(규율 39). 팔 다섯을 다 남긴다 —
//     읽는 팔은 이미 결론이 났지만(㈀=㈁=㈂) **빼면 타이밍이 달라져 다른 체제를 재게 된다.**
//
// ── 📏 새로 보는 것 셋 — **갈렸을 때 「어떻게」 갈렸나** ──────────────────
//   ⭐ ㉠ **클러스터** — 벌들을 **비트 동일** 그룹으로 묶는다.
//        **둘로 갈리면** = 이항 race(가끔 배리어를 놓친다) · **전부 제각각** = 누적 쓰레기.
//   ⭐ ㉡ **첫 갈림 자리(index)** — 같은 자리면 ***특정 텐서***를 가리킨다(배치로 되짚는다).
//   ㉢ **기울기 지문**도 담는다(마지막 걸음) — 갈림이 기울기에도 있나.
//
// ── 📐 발생률을 어떻게 적나 — ⚠️ **0 이면 상한으로**(규율 26) ─────────────
//   갈린 벌 수 `k` ⇒ 발생률 `k/32`. **`k = 0` 이면 삼의 법칙: 상한 ≈ `3/32 = 9.4%`**
//   ⇒ *"안 난다"* 가 아니라 ***"9.4% 아래"***.
//
// ── ✅ 관문 ───────────────────────────────────────────────────────────────
//   배관 유한 · ⭐ **양성 대조(㈄)가 이웃 벌끼리 다르다**
//   ⭐ **회귀** 코퍼스 **32벌 전부 비트 동일**(회차 128 재현 — 아니면 다른 것을 재고 있다)
//   ⭐ **표제** 발생률을 **수로** 적는다(0 이면 상한으로) + 클러스터 구조 보고
//   ⚠️ **규율 37 은 형태가 다르다** — 32벌 자체가 표본 32개라 한 실행이 이미 반복이다.
//
// ── ⭐ 예측(재기 전에 적었다 · 최근 스물둘 중 열하나 틀림) ────────────────
//   발생률 **5~15%** · ⭐ 클러스터 **둘로 갈릴 것**(「가끔·크게」 = 이항 race 의 모양) ·
//   첫 갈림 자리 **진짜 모른다**(같은 자리면 ***이 회차의 최대 수확***) · 코퍼스 32벌 전부 같을 것
//
// ── ⚠️ 미리 적는 함정 ────────────────────────────────────────────────────
//   ⚠️⚠️ **atomic 은 범인이 아니다** — backward 커널 여섯의 주석이 전부 *"그래서 안 썼다"* 는 기록이다.
//   ⚠️ 회차 128 이 지운 것: **읽는 길**(㈀=㈁=㈂) · **코퍼스/인코더**(74,624 비트 동일) · **float 합 순서**.
// ══════════════════════════════════════════════════════════════════════════════

using namespace PE;

class MLTD4B0
{
public:
	static void Tick(RHI* rhi)
	{
		if (_done || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltd4b0"))
		{
			LogA("[mlt] 📊 회차 129(D4-b · 발생률을 고정한다)는 **꺼져 있다**(`-mltd4b0`)\n");
			_done = true; return;
		}
		if (!_banner) { _Banner(); _banner = true; }
		if (_pass >= kPasses) { _Summary(); return; }
		if (_st == kEncInit)  { _EncBegin(rhi); return; }
		if (_st == kEncTrain) { _EncTrain(); return; }
		if (_st == kGather)   { _Gather(); return; }
		if (_st == kBodyInit) { _BodyBegin(rhi); return; }
		if (_st == kBodyTrain){ _BodyTrain(); return; }
		_ReadArms();
	}

	static bool Done() { return _done; }

private:
	// ⭐ **벌 넷** = (A·B) × **바깥 반복 2**(규율 37 — 표제도 두 번 돌린다).
	static constexpr uint32 kPasses = 8u;   // ⭐ 회차 130 — 초기화만 보면 되니 8벌로 충분(회차 129 는 32벌)
	static constexpr uint32 kSeed = 0u;

	// 회차 126·127 과 **같은 몸통**이라야 그 흔들림을 잰다(작게 줄이면 다른 것을 잰다).
	static constexpr uint32 kEncF = 32u, kEncSteps = 1200u, kEncPerTick = 8u;
	static constexpr uint32 kN = 250u, kLocal = 8u;
	static constexpr uint32 kTime  = MLTP3Ctx::kTime;
	static constexpr uint32 kBatch = MLTP3Ctx::kBatch;
	static constexpr uint32 kCandidates = MLTP2Cfg::kPatches * kLocal;
	static constexpr uint32 kGroup = kEncF / kTime;
	static constexpr uint32 kNCtx = 512u, kPbCtx = 128u;
	static constexpr uint32 kTrainEpi = 1u, kPbEpi = 2001u;
	static constexpr uint32 kPoolSteps = kNCtx / kBatch;
	static constexpr uint32 kPbPool = kPbCtx / kBatch;
	static constexpr uint32 kSteps = 800u, kPerTick = 4u;   // ⭐ 회차 127 과 같은 800걸음
	static constexpr uint32 kSymA = MLTP3Ctx::kStateAx + kN + 1u;
	static constexpr uint32 kD = MLTModel::RepDim();

	// ⭐ 읽는 팔 넷 — ㈀ kDelay · ㈁ Flush · ㈂ 24틱 · ㈃ 파라미터(양성 대조는 ㈄)
	static constexpr uint32 kArms = 5u;
	static constexpr uint32 kLongWait = 24u;
	static const char* _ArmName(uint32 a)
	{
		switch (a)
		{
		case 0u: return "㈀ kDelay=3(지금)";
		case 1u: return "㈁ Flush ⭐   ";
		case 2u: return "㈂ 24틱        ";
		case 3u: return "㈃ 파라미터    ";
		default: return "㈄ 양성(딴 걸음)";
		}
	}

	enum { kEncInit, kEncTrain, kGather, kBodyInit, kBodyTrain, kRead };

	inline static MLTP2Enc _E;
	inline static MLTModel _M;
	inline static MLTP3Ctx _trA, _pbA;
	inline static bool _done = false, _banner = false, _encSetup = false, _finite = true;
	inline static bool _pending = false;
	inline static uint32 _pass = 0u, _st = kEncInit, _step = 0u;
	inline static uint32 _cor = 0u, _gGrp = 0u, _gIdx = 0u;
	inline static Array<float> _code, _norm;

	// 팔마다 지문 하나 — 벌마다 담는다
	inline static Array<float> _fp[kPasses][kArms];
	// ⭐ **코퍼스 지문** — 갈림이 **코퍼스에서 왔나 몸통에서 왔나**를 가른다(첫 실행이 요구했다).
	//   ★ 코드북 + 프로브 코퍼스의 값·심볼을 이어 붙인다(전부 학습 이전에 정해진다).
	inline static Array<float> _cfp[kPasses];
	// ⭐ 회차 129 — **기울기 지문**(마지막 걸음 기준). 갈림이 기울기에도 있나.
	inline static Array<float> _gfp[kPasses];
	// ⭐ 회차 130(D4-c) — **`Setup` 직후** 파라미터 지문(⓪). 초기화인가 학습인가를 가른다.
	inline static Array<float> _ifp[kPasses];
	inline static uint32 _arm = 0u, _ri = 0u, _wait = 0u;
	inline static bool   _rpend = false;
	inline static Array<float> _acc;      // 표현을 모으는 자리

	static uint32 _NCtxOf(uint32 c) { return (c == 0u) ? kNCtx : kPbCtx; }
	static uint32 _EpiOf(uint32 c)  { return (c == 0u) ? kTrainEpi : kPbEpi; }
	static MLTP3Ctx& _CorA(uint32 c) { return (c == 0u) ? _trA : _pbA; }

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 📊 **회차 129 · D4-b — 발생률을 고정한다**(⭐ 규율 39 가 요구한 회차)\n");
		LogA("[mlt] 📊   회차 128: 몸통 학습이 **「가끔·크게」** 갈린다(96.7%% · max|Δ| 0.245, 3실행 중 1회)\n");
		LogA("[mlt] 📊     ⇒ **race/미초기화 읽기의 모양** — 반올림이면 **작고 늘** 있어야 한다\n");
		LogA("[mlt] 📊   ⚠️⚠️ 그런데 표본이 **1건**뿐이라 *\"고쳤다\"* 를 **판정할 수 없다**(규율 39)\n");
		LogA("[mlt] 📊   ⇒ ★ **벌 %u** 을 돌려 발생률을 **수로** 고정한다(0 이면 **상한**으로 · 규율 26)\n", kPasses);
		LogA("[mlt] 📊   ⚠️⚠️ **구조는 회차 128 그대로 둔다** — 읽는 팔은 결론이 났지만 **빼면 체제가 달라진다**\n");
		LogA("[mlt] 📊   새로 보는 것 — ⭐ **클러스터**(둘이면 이항 race · 제각각이면 누적 쓰레기) ·\n");
		LogA("[mlt] 📊     ⭐ **첫 갈림 자리**(같으면 특정 텐서를 가리킨다) · **기울기 지문**\n");
		LogA("[mlt] 📊   ⭐ 예측 — 발생률 **5~15%%** · 클러스터 **둘** · 첫 자리 **진짜 모른다** · 코퍼스 전부 같다\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

	// ── 인코더(회차 126·127 과 같다) ─────────────────────────────────
	static void _EncBegin(RHI* rhi)
	{
		if (!_encSetup)
		{
			if (!_E.Setup(rhi, kEncF, kN)) { _Fail("인코더 준비"); return; }
			_encSetup = true;
		}
		else if (!_E.ResetSeed()) { _Fail("인코더 되돌리기"); return; }
		_E.SetK(kLocal); _E.SetSelectAbs(false);
		Array<float> fr, tg; fr.Reset(0); tg.Reset(0);
		ImageFormat::Bitmap bmp; Bytes packed;
		MLTWorld w; w.Reset(kSeed, 0u, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
		for (uint32 f = 0; f < kEncF; ++f)
		{
			w.Step();
			if (!w.Render(bmp) || !MLTWorld::Pack(bmp, nullptr, packed)) { _Fail("Render/Pack(인코더)"); return; }
			MLTP2Enc::AppendFrame(fr, tg, (const uint8*)packed.GetData());
		}
		if (!_E.WritePool(fr, tg, kEncF)) { _Fail("인코더 풀 업로드"); return; }
		_step = 0u; _st = kEncTrain;
	}

	static void _EncTrain()
	{
		for (uint32 i = 0; i < kEncPerTick && _step < kEncSteps; ++i)
		{
			_E.SetFrame(_step % kEncF);
			if (!_E.Forward() || !_E.Backward() || !_E.AdamStep(1.0f)) { _Fail("인코더 학습"); return; }
			++_step;
		}
		if (_step < kEncSteps) return;
		if (!_E.ReadCodebook(_code) || _code.Count() != kN * MLTP2Cfg::kPix) { _Fail("코드북 리드백"); return; }
		_norm.Reset(0);
		for (uint32 id = 0; id < kN; ++id)
		{
			double sq = 0.0; const float* a = _code.Data() + id * MLTP2Cfg::kPix;
			for (uint32 d = 0; d < MLTP2Cfg::kPix; ++d) sq += (double)a[d] * (double)a[d];
			_norm.Add((float)Sqrt((float)sq));
		}
		_trA.SetSortById(true); _pbA.SetSortById(true);
		_trA.Begin(kNCtx, kN); _pbA.Begin(kPbCtx, kN);
		_cor = 0u; _gGrp = 0u; _gIdx = 0u; _pending = false; _st = kGather;
	}

	static void _Gather()
	{
		const uint32 nCtx = _NCtxOf(_cor);
		if (_pending)
		{
			Array<float> ids, mag;
			if (!_E.ReadAct(ids, mag) || ids.Count() != kCandidates) { _Fail("활성 리드백"); return; }
			const uint32 cx = _gGrp * kGroup + (_gIdx - 1u) / kTime, tt = (_gIdx - 1u) % kTime;
			_CorA(_cor).StoreAct(cx, tt, ids, mag, _norm);
			_pending = false;
		}
		if (_gIdx == 0u)
		{
			Array<float> fr, tg; fr.Reset(0); tg.Reset(0);
			ImageFormat::Bitmap bmp; Bytes packed;
			const uint32 epi = _EpiOf(_cor);
			for (uint32 g = 0; g < kGroup; ++g)
			{
				const uint32 ctx = _gGrp * kGroup + g;
				MLTWorld w; w.Reset(kSeed, epi + ctx, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
				for (uint32 t = 0; t < kTime; ++t)
				{
					w.Step();
					if (!w.Render(bmp) || !MLTWorld::Pack(bmp, nullptr, packed)) { _Fail("Render/Pack(문맥)"); return; }
					MLTP2Enc::AppendFrame(fr, tg, (const uint8*)packed.GetData());
					_CorA(_cor).StoreState(ctx, t, w.State());
				}
			}
			if (!_E.WritePool(fr, tg, kEncF)) { _Fail("문맥 풀 업로드"); return; }
		}
		if (_gIdx < kEncF)
		{
			_E.SetFrame(_gIdx);
			if (!_E.Forward()) { _Fail("문맥 forward"); return; }
			++_gIdx; _pending = true; return;
		}
		_gIdx = 0u;
		if (++_gGrp * kGroup < nCtx) return;
		_gGrp = 0u;
		if (++_cor < 2u) return;
		// ⭐ 코퍼스 지문 — **학습 이전에 정해지는 것 전부**(코드북 + 프로브 값·심볼)
		_cfp[_pass].Reset(0);
		for (uint32 i = 0; i < _code.Count(); ++i) _cfp[_pass].Add(_code[i]);
		{
			const Array<float>& v = _pbA.Val(); const Array<float>& s = _pbA.Sym();
			for (uint32 i = 0; i < v.Count(); ++i) _cfp[_pass].Add(v[i]);
			for (uint32 i = 0; i < s.Count(); ++i) _cfp[_pass].Add(s[i]);
		}
		LogA("[mlt] 🔎   벌 %u · 코퍼스 지문 **%u개**(코드북 %u + 프로브 값·심볼)\n",
			_pass, _cfp[_pass].Count(), _code.Count());
		_st = kBodyInit;
	}

	// ── 몸통 — ⚠️ **벌마다 `Setup` 부터** 다시 한다(누적 오염을 막는다) ──
	static void _BodyBegin(RHI* rhi)
	{
		if (!_M.Setup(rhi, kSymA, kN, MLTP3Ctx::kAxes, kTime)) { _Fail("몸통 준비"); return; }
		// ⭐ **회차 130(D4-c)** — `Setup` **직후** 파라미터 지문.
		//   ⚠️⚠️ 회차 128 등록문이 이 지문(⓪)을 잡았다가 설계를 바꾸며 **말없이 뺐다**(규율 41).
		//   ★ 회차 129 가 *"첫 갈림 자리가 28벌 전부 `0`"* 을 냈다 ⇒ ***시작점이 다르다***는 뜻이고,
		//     그러면 이 한 지문이 「초기화가 다른가 ↔ 학습이 다른가」를 **그 자리에서** 가른다.
		{
			_M.Flush();
			Array<float> p0;
			if (!_M.ReadParams(p0)) { _Fail("초기 파라미터 리드백"); return; }
			_ifp[_pass].Reset(0);
			for (uint32 i = 0; i < p0.Count(); ++i) _ifp[_pass].Add(p0[i]);
			LogA("[mlt] 📊   벌 %2u · ⓪ **초기 파라미터** %u개 읽음\n", _pass, p0.Count());
		}
		const bool okUp = _M.UploadPool(_trA.Val(), _trA.Tgt(), kPoolSteps)
			&& _M.UploadSymbolPool(_trA.Sym(), kPoolSteps);
		if (!okUp) { _Fail("학습 풀 업로드"); return; }
		_step = 0u; _st = kBodyTrain;
	}

	static void _BodyTrain()
	{
		if (_step >= kSteps)
		{
			// ⭐ 학습이 끝났다 — 이제 **프로브 풀로 갈아 끼우고** 읽는 방식만 가른다.
			const bool okUp = _M.UploadPool(_pbA.Val(), _pbA.Tgt(), kPbPool)
				&& _M.UploadSymbolPool(_pbA.Sym(), kPbPool);
			if (!okUp) { _Fail("프로브 풀 업로드"); return; }
			_arm = 0u; _ri = 0u; _wait = 0u; _rpend = false;
			for (uint32 a = 0; a < kArms; ++a) _fp[_pass][a].Reset(0);
			_st = kRead; return;
		}
		for (uint32 i = 0; i < kPerTick && _step < kSteps; ++i)
		{
			_M.SelectStep(_step % kPoolSteps);
			if (!_M.Forward() || !_M.Backward() || !_M.AdamStep(1.0f)) { _Fail("몸통 스텝"); return; }
			++_step;
		}
	}

	// ══════════════════════════════════════════════════════════════════
	// ⭐ **이 회차의 핵심 — 같은 상태를 「읽는 방식」만 갈라 읽는다**
	// ══════════════════════════════════════════════════════════════════
	//   ⚠️⚠️ 팔 사이에 **모델을 안 건드린다** — 학습은 끝났고 `Forward` 는 순수 함수다
	//     ⇒ 다른 값이 나오면 그것은 **읽는 길**의 것이다.
	//   ⚠️ ㈃(파라미터)는 forward 가 필요 없다 — 학습 뒤 상태 그대로다.
	//   ⚠️ ㈄(양성 대조)는 **일부러 다른 걸음**을 골라 읽는다 ⇒ **반드시 달라야** 한다.
	static void _ReadArms()
	{
		if (_arm >= kArms) { _NextPass(); return; }

		// ── ㈃ 파라미터 — ⭐ 회차 54 의 재현(dispatch 없이 그냥 읽는다)
		if (_arm == 3u)
		{
			_M.Flush();                     // ⚠️ 학습 디스패치를 씻고 읽는다(이 팔은 「모델」을 묻는다)
			Array<float> p;
			if (!_M.ReadParams(p)) { _Fail("파라미터 리드백"); return; }
			_fp[_pass][3].Reset(0);
			for (uint32 i = 0; i < p.Count(); ++i) _fp[_pass][3].Add(p[i]);
			_CheckFinite(p);
			// ⭐ 회차 129 — **기울기도 담는다**(마지막 걸음 기준). 갈림이 기울기에도 있나.
			Array<float> gr;
			if (!_M.ReadGrads(gr)) { _Fail("기울기 리드백"); return; }
			_gfp[_pass].Reset(0);
			for (uint32 i = 0; i < gr.Count(); ++i) _gfp[_pass].Add(gr[i]);
			LogA("[mlt] 📊   벌 %2u · ㈃ 파라미터 **%u개** · 기울기 **%u개**\n",
				_pass, p.Count(), gr.Count());
			++_arm; _ri = 0u; _rpend = false; _wait = 0u; return;
		}

		// ── ㈀·㈁·㈂·㈄ — forward 를 쏘고 방식대로 표현을 읽는다
		if (_rpend)
		{
			if (_arm == 1u) _M.Flush();                        // ⭐ ㈁ — 보장
			else if (_wait > 0u) { --_wait; return; }           // ㈀ 3틱 · ㈂ 24틱 · ㈄ 3틱
			Array<float> rep;
			if (!_M.ReadRep(rep)) { _Fail("표현 리드백"); return; }
			for (uint32 i = 0; i < rep.Count(); ++i) _fp[_pass][_arm].Add(rep[i]);
			_CheckFinite(rep);
			_rpend = false;
		}
		if (_ri >= kPbPool)
		{
			LogA("[mlt] 🔎   벌 %u · %s **%u개** 읽음\n", _pass, _ArmName(_arm), _fp[_pass][_arm].Count());
			++_arm; _ri = 0u; _wait = 0u; return;
		}
		// ⭐ ㈄ 양성 대조 — **벌마다 다른 걸음**을 읽는다.
		//   ⚠️⚠️ 처음엔 `(_ri + 1)` 로 썼는데 그건 **A·B 가 같은 어긋남**이라 결국 같아진다
		//     ⇒ 양성 대조가 **원리적으로 못 선다**(회차 121·125·126 이 밟은 그 함정의 다섯째 얼굴).
		//   ★ 그래서 **벌 번호**로 민다 — 쌍의 두 벌이 서로 다른 걸음을 읽으므로 **반드시 달라야** 한다.
		_M.SelectStep((_arm == 4u) ? ((_ri + _pass) % kPbPool) : _ri);
		if (!_M.Forward()) { _Fail("표현 forward"); return; }
		++_ri; _rpend = true;
		_wait = (_arm == 2u) ? kLongWait : MLTEvalGate::kDelay;
	}

	static void _CheckFinite(const Array<float>& v)
	{
		for (uint32 i = 0; i < v.Count(); ++i)
			if (!(v[i] == v[i]) || Abs(v[i]) > 1.0e30f) { _finite = false; return; }
	}

	static void _NextPass()
	{
		LogA("[mlt] 🔎 ── 벌 %u 끝 ──\n", _pass);
		++_pass;
		if (_pass < kPasses) { _st = kEncInit; _encSetup = true; }
	}

	// ══════════════════════════════════════════════════════════════════
	// 📊 판정 — **A↔B 를 팔마다 비트로 견준다**
	// ══════════════════════════════════════════════════════════════════
	//   ⚠️ 벌 넷 = (A·B) × 바깥 반복 2 ⇒ 쌍 둘: (0,1) 과 (2,3). ⭐ **둘 다 같은 답이어야 한다**(규율 37).
	struct Cmp { uint32 n; uint32 diff; uint32 first; double maxAbs; double rel; };

	static Cmp _Compare(const Array<float>& a, const Array<float>& b)
	{
		Cmp c{}; c.n = 0u; c.diff = 0u; c.first = 0xFFFFFFFFu; c.maxAbs = 0.0; c.rel = 0.0;
		const uint32 n = (a.Count() < b.Count()) ? a.Count() : b.Count();
		c.n = n;
		double mx = 0.0;
		for (uint32 i = 0; i < n; ++i)
		{
			const double av = (double)a[i];
			if (Abs((float)av) > mx) mx = Abs((float)av);
			if (a[i] != b[i])
			{
				++c.diff;
				if (c.first == 0xFFFFFFFFu) c.first = i;
				const double d = Abs((float)(av - (double)b[i]));
				if (d > c.maxAbs) c.maxAbs = d;
			}
		}
		c.rel = (mx > 1.0e-12) ? (c.maxAbs / mx) : 0.0;
		return c;
	}
	// ══════════════════════════════════════════════════════════════════
	// 📊 **회차 129 — 발생률과 클러스터**(규율 39 가 요구한 그것)
	// ══════════════════════════════════════════════════════════════════
	//   ⭐ ㉠ **클러스터** — 벌들을 **비트 동일** 그룹으로 묶는다.
	//     둘로 갈리면 = **이항 race**(가끔 배리어를 놓친다) · 전부 제각각 = **누적 쓰레기**.
	//   ⭐ ㉡ **첫 갈림 자리** — 같은 자리면 ***특정 텐서***를 가리킨다(파라미터 배치로 되짚는다).
	//   ⚠️ ㉢ 발생률이 **0 이면 상한으로 적는다**(삼의 법칙 · 규율 26) — *"안 났다"* 가 아니다.
	static void _Summary()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 📊 **회차 129 · D4-b — 발생률을 고정한다** (벌 %u · 유한 %s)\n",
			kPasses, _finite ? "✅" : "⛔");
		LogA("[mlt] 📊   ⚠️ 규율 39 — *\"고쳤다\"* 와 *\"숨었다\"* 를 가르려면 **재현 조건을 먼저 고정**해야 한다\n");

		// ── ⭐ 회귀 관문: 코퍼스가 전부 같은가(회차 128 재현) ─────────────
		uint32 corpDiff = 0u, corpFirst = 0xFFFFFFFFu;
		for (uint32 i = 1u; i < kPasses; ++i)
		{
			const Cmp c = _Compare(_cfp[0], _cfp[i]);
			if (c.diff != 0u) { ++corpDiff; if (corpFirst == 0xFFFFFFFFu) corpFirst = i; }
		}
		LogA("[mlt] 📊   ⭐ **회귀** — 코퍼스가 벌 0 과 같은가: **%u/%u 이 다르다**%s\n",
			corpDiff, kPasses - 1u,
			(corpDiff == 0u) ? "  ✅ 전부 같다(회차 128 재현)" : "  ⛔ **다른 것을 재고 있다**");

		// ── ⭐ 양성 대조: ㈄ 는 벌마다 다른 걸음을 읽는다 ⇒ 이웃끼리 달라야 한다 ──
		uint32 posOk = 0u, posN = 0u;
		for (uint32 i = 0u; i + 1u < kPasses; ++i)
		{
			const Cmp c = _Compare(_fp[i][4], _fp[i + 1u][4]);
			++posN; if (c.diff != 0u) ++posOk;
		}
		LogA("[mlt] 📊   ⭐ **양성 대조**(㈄ 이웃 벌끼리 **달라야** 한다) — **%u/%u**%s\n",
			posOk, posN, (posOk == posN) ? "  ✅ 자가 살아 있다" : "  ⛔ **자가 죽었다**");

		// ══════════════════════════════════════════════════════════════
		// ⭐ **회차 130(D4-c) — ⓪ `Setup` 직후 파라미터**
		// ══════════════════════════════════════════════════════════════
		//   ⚠️ 회차 129 가 *"첫 갈림 자리가 28벌 전부 `0`"* 을 냈다 ⇒ ***시작점이 다르다***는 뜻.
		//   ★ 이 한 지문이 **「초기화가 다른가 ↔ 학습이 다른가」** 를 그 자리에서 가른다.
		uint32 initDiff = 0u, initFirst = 0xFFFFFFFFu; double initMax = 0.0;
		for (uint32 i = 1u; i < kPasses; ++i)
		{
			const Cmp c = _Compare(_ifp[0], _ifp[i]);
			if (c.diff != 0u)
			{
				++initDiff;
				if (initFirst == 0xFFFFFFFFu) initFirst = c.first;
				if (c.maxAbs > initMax) initMax = c.maxAbs;
			}
		}
		LogA("[mlt] 📊   ── ⭐ ⓪ **`Setup` 직후 파라미터**(벌 0 과 견줘) ──\n");
		LogA("[mlt] 📊     **%u/%u 벌이 다르다** · 첫 자리 %d · max|Δ| %.3e → %s\n",
			initDiff, kPasses - 1u, (initFirst == 0xFFFFFFFFu) ? -1 : (int)initFirst, initMax,
			(initDiff == 0u) ? "✅ **초기화는 결정적** ⇒ 범인은 **학습**"
			                 : "⛔ ⭐ ***초기화부터 다르다*** ⇒ 범인은 **학습이 아니다**");

		// ── ⭐ ㉠ 클러스터 — 파라미터가 비트 동일인 벌끼리 묶는다 ─────────
		uint32 cl[kPasses];        // 벌 i 가 속한 클러스터의 **대표 벌**
		uint32 nCl = 0u;
		for (uint32 i = 0; i < kPasses; ++i)
		{
			cl[i] = i;
			for (uint32 j = 0; j < i; ++j)
			{
				if (cl[j] != j) continue;                     // 대표만 견준다
				const Cmp c = _Compare(_fp[i][3], _fp[j][3]);
				if (c.diff == 0u && c.n > 0u) { cl[i] = j; break; }
			}
			if (cl[i] == i) ++nCl;
		}
		LogA("[mlt] 📊   ── ⭐ ㉠ **클러스터**(파라미터 비트 동일끼리) — **무리 %u개** ──\n", nCl);
		uint32 best = 0u, bestN = 0u;
		for (uint32 r = 0; r < kPasses; ++r)
		{
			if (cl[r] != r) continue;
			uint32 n = 0u;
			for (uint32 i = 0; i < kPasses; ++i) if (cl[i] == r) ++n;
			if (n > bestN) { bestN = n; best = r; }
		}
		for (uint32 r = 0; r < kPasses; ++r)
		{
			if (cl[r] != r) continue;
			uint32 n = 0u;
			for (uint32 i = 0; i < kPasses; ++i) if (cl[i] == r) ++n;
			// 그 무리에 든 벌 번호를 최대 12개까지 적는다(⚠️ 자르면 자른다고 말한다 — 규율)
			char who[128]; uint32 w = 0u, shown = 0u;
			for (uint32 i = 0; i < kPasses && w + 4u < 120u; ++i)
			{
				if (cl[i] != r) continue;
				if (shown >= 12u) break;
				if (shown > 0u) { who[w++] = ','; }
				if (i >= 10u) who[w++] = (char)('0' + (i / 10u));
				who[w++] = (char)('0' + (i % 10u));
				++shown;
			}
			who[w] = '\0';
			LogA("[mlt] 📊     무리(대표 벌 %2u) — **%2u벌** [%s]%s%s\n",
				r, n, who, (shown < n) ? " …(잘랐다)" : "",
				(r == best) ? "   ⭐ **다수파**" : "");
		}

		// ── ⭐ ㉡ 첫 갈림 자리 — 다수파와 다른 벌들이 「어디서」 갈리나 ────
		const uint32 minority = kPasses - bestN;
		LogA("[mlt] 📊   ── ⭐ ㉡ **첫 갈림 자리**(다수파와 견줘) ──\n");
		if (minority == 0u)
			LogA("[mlt] 📊     ⚠️ 갈린 벌이 **없다** — 잴 것이 없다\n");
		else
			for (uint32 i = 0; i < kPasses; ++i)
			{
				if (cl[i] == best) continue;
				const Cmp cp = _Compare(_fp[best][3], _fp[i][3]);
				const Cmp cg = _Compare(_gfp[best], _gfp[i]);       // ⭐ 기울기(마지막 걸음)
				const Cmp cr = _Compare(_fp[best][0], _fp[i][0]);   // 표현(㈀)
				LogA("[mlt] 📊     벌 %2u │ 파라미터 %7u/%-7u · 첫 %8d · max|Δ| %.3e │ 기울기 %7u/%-7u · 첫 %8d │ 표현 %7u/%-7u\n",
					i, cp.diff, cp.n, (cp.first == 0xFFFFFFFFu) ? -1 : (int)cp.first, cp.maxAbs,
					cg.diff, cg.n, (cg.first == 0xFFFFFFFFu) ? -1 : (int)cg.first,
					cr.diff, cr.n);
			}

		// ── ⭐ ㉢ 발생률 ──────────────────────────────────────────────
		const double rate = (double)minority / (double)kPasses;
		LogA("[mlt] 📊   ── ⭐ ㉢ **발생률** ──\n");
		if (minority == 0u)
			LogA("[mlt] 📊     **0 / %u** ⇒ ⚠️ *\"안 난다\"* 가 아니라 ***상한 %.1f%%***(삼의 법칙 3/%u · 규율 26)\n",
				kPasses, 100.0 * 3.0 / (double)kPasses, kPasses);
		else
			LogA("[mlt] 📊     **%u / %u = %.1f%%** ⇒ ⭐ 이제 **고침의 전후를 견줄 수 있다**(규율 39)\n",
				minority, kPasses, 100.0 * rate);

		// ── 판정 ────────────────────────────────────────────────────────
		const bool plumb = _finite && (corpDiff == 0u) && (posOk == posN);
		if (!plumb)
			LogA("[mlt] 📊   ⭐ 판정 = ⛔ **판정불가** — 배관이 안 섰다(코퍼스 회귀 %s · 양성 대조 %s)\n",
				(corpDiff == 0u) ? "✅" : "⛔", (posOk == posN) ? "✅" : "⛔");
		else if (minority == 0u)
			LogA("[mlt] 📊   ⭐ 판정 = 🔶 **이 체제에서는 안 난다**(상한 %.1f%%)\n"
			     "[mlt] 📊      ⇒ ⚠️⚠️ 회차 128 실행 1 은 **분명히 갈렸다** ⇒ 그 체제와 지금 체제가 **다르다**\n"
			     "[mlt] 📊      ⇒ ★ 다음은 *\"무엇이 달라졌나\"* 다 — 규율 39 가 경고한 **타이밍 이동**이 유력하다\n",
				100.0 * 3.0 / (double)kPasses);
		else if (nCl == 2u)
			LogA("[mlt] 📊   ⭐ 판정 = ⭐ ***이항이다*** — 무리가 **정확히 둘**이고 소수파가 **%u/%u = %.1f%%**\n"
			     "[mlt] 📊      ⇒ ★ 「가끔 배리어를 놓친다」의 모양이다 — 결과가 **두 가지뿐**이라 누적 쓰레기가 아니다\n"
			     "[mlt] 📊      ⇒ ⭐ 다음 = 첫 갈림 자리로 **텐서를 짚고**, 걸음별로 **첫 갈림 걸음**을 찾는다\n",
				minority, kPasses, 100.0 * rate);
		else
			LogA("[mlt] 📊   ⭐ 판정 = ⭐ **발생률을 얻었다** — %u/%u = %.1f%% · 무리 **%u개**\n"
			     "[mlt] 📊      ⇒ ⚠️ 무리가 셋 이상이면 **이항 race 가 아니다**(값이 매번 조금씩 다르다)\n",
				minority, kPasses, 100.0 * rate, nCl);
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		_E.Destroy(); _done = true;
	}

	static void _Fail(const char* why)
	{
		LogA("[mlt] 🔎 ⛔ %s (벌 %u · 단계 %u · 팔 %u · 코퍼스 %u · %u)\n",
			why, _pass, _st, _arm, _cor, _ri);
		_E.Destroy(); _done = true;
	}

	CW_BODY(MLTD4B0)
};
