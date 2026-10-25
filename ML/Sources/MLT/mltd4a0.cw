// mltd4a0.cw — 🔎 회차 128 · **D4: 흔들리는 것은 학습인가 읽는 길인가** (`-mltd4a0`)
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문은 [mltlog_1.md](../../mltlog_1.md) 회차 128 이다.** ⭐ **하네스보다 먼저 썼다.**
//   **상위 캔버스: `자를 고친다` · 128~ = 1회차**(규율 33) — 회차 127 의 심사가 언어 캔버스를 닫았다.
//
// ── ⭐ 왜 이 회차인가 ────────────────────────────────────────────────
//   회차 127: **표제 자가 실행 사이에 3.5배 흔들린다**(전이율 +0.407 → +0.118).
//   ⇒ ★ **자가 흔들리는 동안 재는 것은 전부 낭비다.**
//
//   ⭐ 그리고 `mltevalgate.cw` 머리말이 **답의 절반**을 갖고 있었다:
//     · 회차 54 — 파라미터 858,368개가 800스텝까지 **비트 동일** ⇒ **학습은 결정적이다.**
//     · 회차 53 — 그런데 CE 폭이 있었다 ⇒ ***흔들린 것은 모델이 아니라 읽는 길이다.***
//     · 엔진(`RHI.h`): dispatch 는 `computeCb[frame]` 에 **누적만** 되고 제출은 Present 에서 1회
//       ⇒ *"짧게 돌면 큐가 얕아 늘 맞고, **길게 돌면 틀린다**"*.
//   ⭐ **회차 127 의 갈림이 정확히 그 모양이다** — 흔들린 팔은 **학습 800걸음을 큐에 쌓은 팔뿐**이고
//     그 걸음을 아예 안 낸 무작위 팔은 **비트 단위로 같았다.**
//
// ── 🔬 자 — **같은 학습 뒤에 「읽는 방식」만 갈라 본다** ──────────────────
//   벌 **A·B** 를 똑같이: `Setup(씨앗0)` → **학습 800걸음** → 표현을 **세 방식**으로 읽는다.
//     ㈀ `kDelay = 3` 틱 대기(**지금 그대로**)   ㈁ ⭐ **`Flush`**(= `WaitIdle`)   ㈂ **24 틱** 대기
//     ㈃ ⭐ **파라미터 블록 비트 비교**(회차 54 재현 — 학습 자체가 결정적인가)
//   ⭐ **논증이 닫힌다**: ㈃ 가 비트 동일인데 ㈀ 가 다르면 ⇒ ***범인은 읽는 길이고 모델이 아니다.***
//     그리고 ㈁ 이 비트 동일이면 ⇒ ***처방까지 나온다***(리드백 앞 `Flush`).
//
// ── ✅ 관문(등록문과 같다) ────────────────────────────────────────────────
//   배관 리드백 유한 · `ParamCount > 0` · ⭐ **양성 대조가 다르다**(안 다르면 자가 죽은 것)
//   ⭐ **㉠** ㈃ 가 A↔B 비트 동일 ⇒ *"학습은 결정적"*
//   ⭐ **㉡** ㈀ 가 다르고 **㈁ 이 비트 동일** ⇒ ***범인 = 읽는 길 · 처방 = `Flush`***
//   ⭐ **규율 37** — ***두 번 돌린다***(이 회차의 표제도 예외가 아니다)
//
// ── ⭐ 예측(재기 전에 적었다 · 최근 열여덟 중 아홉 틀림) ──────────────────
//   ㈃ 비트 동일일 것 · ㈀ **다를 것** · ㈁ **비트 동일일 것** · ㈂ **진짜 모른다**
//
// ── ⚠️ 미리 적는 함정 ────────────────────────────────────────────────────
//   ⚠️⚠️ **atomic 은 범인이 아니다** — backward 커널 여섯의 주석이 전부 *"그래서 안 썼다"* 는 기록이다.
//   ⚠️ `Flush` 는 파이프라인을 비운다 ⇒ **학습 루프에 넣으면 안 된다**(진단·평가 전용).
// ══════════════════════════════════════════════════════════════════════════════

using namespace PE;

class MLTD4A0
{
public:
	static void Tick(RHI* rhi)
	{
		if (_done || rhi == nullptr) return;
		if (!OS::CommandLine::Has("-mltd4a0"))
		{
			LogA("[mlt] 🔎 회차 128(D4 · 학습인가 읽는 길인가)은 **꺼져 있다**(`-mltd4a0`)\n");
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
	static constexpr uint32 kPasses = 4u;
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
	inline static uint32 _arm = 0u, _ri = 0u, _wait = 0u;
	inline static bool   _rpend = false;
	inline static Array<float> _acc;      // 표현을 모으는 자리

	static uint32 _NCtxOf(uint32 c) { return (c == 0u) ? kNCtx : kPbCtx; }
	static uint32 _EpiOf(uint32 c)  { return (c == 0u) ? kTrainEpi : kPbEpi; }
	static MLTP3Ctx& _CorA(uint32 c) { return (c == 0u) ? _trA : _pbA; }

	static void _Banner()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🔎 **회차 128 · D4 — 흔들리는 것은 학습인가 읽는 길인가**(⭐ 진단 회차)\n");
		LogA("[mlt] 🔎   회차 127: 표제 자가 **실행 사이 3.5배** 흔들렸다 ⇒ ★ **자를 먼저 고친다**\n");
		LogA("[mlt] 🔎   ⭐ 회차 54 는 *\"파라미터가 800스텝까지 비트 동일\"* 이라 적었다 ⇒ **학습은 결정적**\n");
		LogA("[mlt] 🔎     그리고 회차 127 에서 흔들린 팔은 **학습 800걸음을 큐에 쌓은 팔뿐**이었다\n");
		LogA("[mlt] 🔎   ⇒ 가설: 엔진이 dispatch 를 **누적만** 하므로 `kDelay=3` 틱이 **모자라다**\n");
		LogA("[mlt] 🔎   벌 A·B 를 똑같이 돌리고 **읽는 방식만** 가른다 — 팔 다섯:\n");
		LogA("[mlt] 🔎     ㈀ kDelay=3(지금) · ⭐ ㈁ **Flush**(WaitIdle) · ㈂ 24틱 · ㈃ **파라미터 비트** · ㈄ 양성 대조\n");
		LogA("[mlt] 🔎   ⭐ 논증 — **㈃ 가 같은데 ㈀ 가 다르면 범인은 읽는 길이다**. ㈁ 이 같으면 **처방까지** 나온다\n");
		LogA("[mlt] 🔎   ⭐ 예측 — ㈃ 같다 · ㈀ **다르다** · ㈁ **같다** · ㈂ **진짜 모른다**\n");
		LogA("[mlt] 🔎   ⚠️ 벌 넷 = (A·B) × **바깥 반복 2**(규율 37 — 표제도 두 번 돌린다)\n");
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
			LogA("[mlt] 🔎   벌 %u · ㈃ 파라미터 **%u개** 읽음\n", _pass, p.Count());
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

	static void _Summary()
	{
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 🔎 **회차 128 · D4 — 학습인가 읽는 길인가** (벌 %u · 유한 %s)\n",
			kPasses, _finite ? "✅" : "⛔");
		LogA("[mlt] 🔎   ⚠️ 비트와 크기를 **둘 다** 적는다 — 비트만 보면 *\"1 ULP 도 다르다\"*, 크기만 보면 *\"거의 같다\"*\n");
		LogA("[mlt] 🔎   팔                │쌍│ 다른 원소 / 전체      │ 첫 자리   │ max|Δ|     │ 무차원 max|Δ|/max|값|\n");
		bool same[2][kArms];
		for (uint32 pr = 0; pr < 2u; ++pr)
			for (uint32 a = 0; a < kArms; ++a)
			{
				const Cmp c = _Compare(_fp[pr * 2u][a], _fp[pr * 2u + 1u][a]);
				same[pr][a] = (c.diff == 0u && c.n > 0u);
				LogA("[mlt] 🔎   %s │ %s │ **%7u** / %-8u │ %9d │ %.3e │ **%.3e** %s\n",
					_ArmName(a), (pr == 0u) ? "1" : "2",
					c.diff, c.n, (c.first == 0xFFFFFFFFu) ? -1 : (int)c.first,
					c.maxAbs, c.rel, same[pr][a] ? "✅ 비트 동일" : "⛔ 다르다");
			}

		// ══════════════════════════════════════════════════════════════
		// ⭐ **첫 실행이 요구한 것 — 모든 벌 쌍을 본다**(규율 38)
		// ══════════════════════════════════════════════════════════════
		//   ⚠️ 첫 실행: 쌍1(벌0↔1)은 **전부 비트 동일**인데 쌍2(벌2↔3)는 **전부 달랐다.**
		//     그런데 벌 1·2·3 은 **완전히 같은 코드 경로**다(벌 0 만 `Setup`, 나머지는 `ResetSeed`).
		//   ⇒ ★ *"어느 벌들이 서로 같은가"* 를 알아야 **간헐인지 단조인지**가 갈린다.
		//   ★ 그리고 **코퍼스 지문**을 같이 본다 — 갈림이 **코퍼스에서 왔나 몸통에서 왔나**.
		LogA("[mlt] 🔎   ── ⭐ **모든 벌 쌍**(㈃ 파라미터 · ㈀ 표현 · 코퍼스) ──\n");
		LogA("[mlt] 🔎     쌍   │ ㈃ 파라미터 다름 │ ㈀ 표현 다름 │ ⭐ 코퍼스 다름\n");
		for (uint32 i = 0; i < kPasses; ++i)
			for (uint32 j = i + 1u; j < kPasses; ++j)
			{
				const Cmp cp = _Compare(_fp[i][3], _fp[j][3]);
				const Cmp cr = _Compare(_fp[i][0], _fp[j][0]);
				const Cmp cc = _Compare(_cfp[i], _cfp[j]);
				LogA("[mlt] 🔎     %u↔%u  │ %8u/%-8u │ %8u/%-8u │ **%8u/%-8u** %s\n",
					i, j, cp.diff, cp.n, cr.diff, cr.n, cc.diff, cc.n,
					(cc.diff == 0u) ? "✅ 코퍼스 같다" : "⛔ **코퍼스가 다르다**");
			}

		// ── 관문 ────────────────────────────────────────────────────────
		const bool okN = (_fp[0][0].Count() > 0u) && (_fp[0][3].Count() > 0u);
		const bool pos = (!same[0][4]) && (!same[1][4]);          // ⭐ 양성 대조 — **달라야** 한다
		const bool plumb = okN && _finite && pos;
		const bool gA = same[0][3] && same[1][3];                  // ㉠ 파라미터가 같다
		const bool armDiff = (!same[0][0]) && (!same[1][0]);       // ㈀ 가 다르다
		const bool flushOk = same[0][1] && same[1][1];             // ㈁ Flush 가 같다
		const bool longOk  = same[0][2] && same[1][2];             // ㈂ 24틱이 같다

		LogA("[mlt] 🔎   ── 관문 ──\n");
		LogA("[mlt] 🔎     배관 — 리드백 유한 %s · 개수 %s · ⭐ **양성 대조(㈄)가 다르다** %s → %s\n",
			_finite ? "✅" : "⛔", okN ? "✅" : "⛔", pos ? "✅" : "⛔ **자가 죽었다**",
			plumb ? "통과" : "⛔");
		LogA("[mlt] 🔎     ⭐ **㉠** ㈃ 파라미터가 A↔B **비트 동일** → %s%s\n",
			gA ? "✅" : "⛔", gA ? "  ⇒ ***학습은 결정적이다***(회차 54 재현)"
			                    : "  ⇒ ⚠️⚠️ **회차 54 와 어긋난다 — 학습 자체가 흔들린다**");
		LogA("[mlt] 🔎     ⭐ **㉡** ㈀(kDelay=3) 다르다 %s · ㈁(**Flush**) 같다 %s · ㈂(24틱) 같다 %s\n",
			armDiff ? "✅" : "⛔", flushOk ? "✅" : "⛔", longOk ? "✅" : "⛔");

		// ── 판정 ────────────────────────────────────────────────────────
		if (!plumb)
			LogA("[mlt] 🔎   ⭐ 판정 = ⛔ **판정불가** — 배관이 안 섰다(양성 대조가 안 서면 **자가 죽은 것**이다)\n");
		else if (same[0][3] != same[1][3])
			LogA("[mlt] 🔎   ⭐ 판정 = ⚠️⚠️⚠️ ***비결정성이 간헐적이다*** — **한 쌍은 비트 동일이고 다른 쌍은 다르다**\n"
			     "[mlt] 🔎      ⇒ ★ 벌 1·2·3 은 **완전히 같은 코드 경로**다 ⇒ 「늘 다르다」가 아니라 **가끔 갈린다**\n"
			     "[mlt] 🔎      ⇒ ⚠️ 그래서 회차 54 의 *\"비트 동일\"* 도 **참이었을 수 있다**(그날은 안 갈렸다)\n"
			     "[mlt] 🔎      ⇒ ⭐ 위 **모든 벌 쌍** 표와 **코퍼스 지문**이 다음 표적을 정한다\n");
		else if (!gA)
			LogA("[mlt] 🔎   ⭐ 판정 = ⚠️⚠️ **학습 자체가 흔들린다** — 회차 54 의 *\"비트 동일\"* 이 **지금은 안 선다**\n"
			     "[mlt] 🔎      ⇒ ★ 그러면 다음은 forward/backward/adam 중 **어디서 태어나나**를 가르는 회차다\n");
		else if (armDiff && flushOk)
			LogA("[mlt] 🔎   ⭐ 판정 = ⭐ ***범인은 읽는 길이고 처방은 `Flush` 다***\n"
			     "[mlt] 🔎      ⇒ ★ 모델은 **비트 동일**인데 `kDelay=3` 으로 읽으면 다르고 `WaitIdle` 로 읽으면 같다\n"
			     "[mlt] 🔎      ⇒ ⚠️ 다음 회차 = **모든 평가 리드백 앞에 `Flush`** 를 넣고 회차 127 을 다시 잰다\n");
		else if (armDiff && !flushOk)
			LogA("[mlt] 🔎   ⭐ 판정 = 🔶 **반쪽** — 모델은 같은데 읽기가 다르고 **`Flush` 로도 안 고쳐진다**\n"
			     "[mlt] 🔎      ⇒ ⚠️ 그러면 `WaitIdle` 이 이 엔진에서 **컴퓨트 제출을 안 기다린다**는 뜻이다(그 자체가 발견)\n");
		else
			LogA("[mlt] 🔎   ⭐ 판정 = ⛔ **재현이 안 됐다** — ㈀ 가 **이 회차에서는 안 흔들렸다**\n"
			     "[mlt] 🔎      ⇒ ⚠️ 회차 127 의 흔들림은 **여기 없는 무언가**에서 온다(코퍼스·인코더·프로브 쪽)\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		_E.Destroy(); _done = true;
	}

	static void _Fail(const char* why)
	{
		LogA("[mlt] 🔎 ⛔ %s (벌 %u · 단계 %u · 팔 %u · 코퍼스 %u · %u)\n",
			why, _pass, _st, _arm, _cor, _ri);
		_E.Destroy(); _done = true;
	}

	CW_BODY(MLTD4A0)
};
