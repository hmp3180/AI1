// mltp2fit.cw — 🧩👁️ **판정 ③ 의 비전판 · 조립 검사.** *"고정 프레임 **하나**를 외울 수 있나?"*
//
// ★ **왜 또 필요한가** — `mltfit.cw` 의 판정 ③ 은 **트랜스포머 몸통**을 쟀다. P2 의 인코더는
//   **다른 그래프**(패치표 · 사전 · top-k · 코드북)이고 커널도 다르다. ⇒ 그 조립은 **아직 안 재졌다.**
//   ⚠️ 판정 ①② 는 커널 하나씩을 재므로 **오프셋·전치·축·겹치기**는 하나도 못 본다. 그리고 이 인코더는
//     ⭐ `dPatch` 를 **`g` 블록의 `pos` 칸에 겹쳐** 두었다 — 그 겹치기가 틀리면 증상이 크래시가 아니라
//     *"자리를 못 배운다"* 이고 **gradcheck 로는 절대 안 보인다.**
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **등록문** — ⚠️ 아래 수를 보고 나서 고치면 판정이 아니다.
// ══════════════════════════════════════════════════════════════════════════════
//
//   **과제** — 씨앗 0 · `hold=중간` · 8스텝 뒤의 **프레임 하나**를 외운다.
//   ⚠️ 세계를 쓰지만 **난이도가 없다**(프레임이 하나라 일반화가 아니고 외우기다) ⇒ 조립만 재진다.
//   ★ 그리고 이 과제는 그래프의 **모든** 갈래를 지난다: 패치표(자리·바이트) · 자리표2 · 사전 ·
//     top-k 선택 · 코드북. 어느 하나가 끊겨 있으면 못 외운다.
//
//   **팔 둘** — 팔 A `lr = 3e-3` ⇒ 내려가야 한다 · 팔 B `lr = 0`(음성 대조군) ⇒ 평평해야 한다.
//   ⚠️⚠️ **대조군을 「호출 건너뛰기」로 만들지 않는다** — `lr` 에 0 을 곱한다(코드 경로가 같아야
//     대조군이다). `mltfit.cw` 가 못 박은 그 자리다.
//
//   **관문 다섯**
//     ㉠ ⭐ **초기 MSE ≈ 표적의 제곱평균** — 허용 **±25%**(상대).
//        ★ 근거: 코드북 초기 산포가 작으므로 `recon ≈ 0` ⇒ `MSE ≈ E[t²]` 여야 한다.
//          그것이 *"표적이 제자리에 있고 recon 이 안 터졌다"* 의 첫 증거다.
//          ⚠️ 비교 대상 `E[t²]` 는 **CPU 가 따로** 센다(GPU 리드백과 다른 코드) ⇒ 자기참조가 아니다.
//     ㉡ 팔 A 의 **최저 MSE < 0.1 × 초기** — 300 스텝 안.
//        ★ 근거: 패치 64개를 사전 1000개 · 코드북 1000×192 로 외우는 것은 **과분하게 쉽다**
//          (패치마다 유닛 여덟을 전용으로 쓰면 **정확히** 표현된다). 못 하면 용량이 아니라 **배선**이다.
//     ㉢ 팔 B 의 `|마지막 − 처음| ≤ 1e-6 · 처음` — ⚠️ `lr=0` 이고 `wd=0` 이라 파라미터가 **비트 동일**
//        이어야 하므로 사실상 0 을 요구하는 것이다(리드백 표류만 허용).
//     ㉣ 전 구간 **유한**.
//     ㉤ ⭐ **예산** — **살아있는 파라미터 ≤ 0.5M**(`MLT.md` 의 인코더 예산).
//        ⚠️ 「살아있음」의 정의와 근거는 `mltp2enc.cw` 머리말에 있다(자리표의 죽은 행은 어떤 입력에도
//        기울기가 0 이라 접지를 숨길 수 없다). ★ 로그가 **할당 수도 같이** 찍는다.
//
//   **보고(관문 아님)** — 활성이 실제로 갈리나(서로 다른 id 개수). 전부 같으면 그것이 붕괴의 얼굴이고
//     **손실만 보면 안 보인다.** ⚠️ 사전 사용률의 **관문**은 판정 라운드의 칸이다(여기서 미리 재지 않는다).
//
//   ⚠️ 실패했을 때 **모델을 키우지 않는다** — 겹치기·전치·축을 읽는다(판정 ③ 의 계약).

using namespace PE;

class MLTP2Fit
{
public:
	static void Tick(RHI* rhi)
	{
		if (_arm >= 2 || rhi == nullptr) return;
		if (!_begun)
		{
			if (!_Begin(rhi)) { LogA("[mlt] 👁️③ 준비 실패 — 접는다\n"); _arm = 2; return; }
			_begun = true;
		}

		// ⚠️ 지금 읽는 것은 **지난 프레임 forward** 의 `dRecon` 이다(같은 프레임엔 옛 값이다).
		if (_step > 0u)
		{
			float mse = 0.0f; bool fin = true;
			if (!_E.ReadMse(mse, fin)) { LogA("[mlt] 👁️③ MSE 리드백 실패\n"); _arm = 2; return; }
			_Record(mse, fin);
		}

		if (_step >= kSteps) { _Judge(); _NextArm(); return; }

		const float lrMul = (_arm == 0) ? 1.0f : 0.0f;
		if (!_E.Forward() || !_E.Backward() || !_E.AdamStep(lrMul))
		{ LogA("[mlt] 👁️③ 스텝 실패(팔 %s · 스텝 %u)\n", _ArmName(), _step); _arm = 2; return; }
		++_step;
	}

	static bool Done() { return _arm >= 2; }

private:
	static constexpr uint32 kSteps    = 300u;
	static constexpr uint32 kLogEvery = 50u;
	static constexpr float  kInitTol  = 0.25f;      // ㉠ 상대
	static constexpr float  kDropTo   = 0.10f;      // ㉡ 초기의 몇 배 아래로
	static constexpr float  kFlatRel  = 1.0e-6f;    // ㉢
	static constexpr uint32 kBudget   = 500000u;    // ㉤ 살아있는 파라미터 상한
	static constexpr uint32 kSeed     = 0u;         // 과제 프레임
	static constexpr uint32 kWarm     = 8u;         // 그 프레임까지 굴리는 스텝 수

	inline static MLTP2Enc _E;
	inline static int    _arm = 0;
	inline static bool   _begun = false;
	inline static uint32 _step = 0u, _read = 0u;
	inline static float  _first = 0.0f, _last = 0.0f, _best = 0.0f;
	inline static bool   _finite = true;
	inline static bool   _pass[2] = { false, false };
	inline static float  _armFirst[2] = { 0.0f, 0.0f }, _armLast[2] = { 0.0f, 0.0f };
	inline static float  _tgtSq = 0.0f;            // CPU 가 센 `E[t²]`
	inline static uint32 _live = 0u;               // 코퍼스에서 살아있는 자리표 행
	inline static uint32 _liveFrame = 0u;          // 이 프레임 하나가 깨우는 행
	inline static uint32 _idsFirst = 0u, _idsLast = 0u;

	static const char* _ArmName() { return (_arm == 0) ? "A(lr=3e-3)" : "B(lr=0)"; }

	static bool _Begin(RHI* rhi)
	{
		typedef MLTP2Cfg C;
		LogA("[mlt] ─────────────────────────────────────────────\n");
		LogA("[mlt] 👁️③ 조립 검사(비전) · 팔 %s · %u 스텝\n", _ArmName(), kSteps);

		// ── 과제 프레임 하나 ───────────────────────────────────────
		ImageFormat::Bitmap bmp;
		Bytes packed;
		{
			MLTWorld w;
			w.Reset(kSeed, 0u, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
			for (uint32 i = 0; i < kWarm; ++i) w.Step();
			if (!w.Render(bmp) || !MLTWorld::Pack(bmp, nullptr, packed))
			{ LogA("[mlt] 👁️③ Render/Pack 실패\n"); return false; }
		}
		const uint8* px = (const uint8*)packed.GetData();

		// ── ㉠ 의 비교값: 표적의 제곱평균을 **CPU 가 따로** 센다 ───
		{
			double s = 0.0;
			for (uint32 i = 0; i < C::kSide * C::kSide; ++i)
			{
				float c[3]; MLTP2Enc::Unpack(px[i], c);
				for (uint32 j = 0; j < 3u; ++j) s += (double)c[j] * c[j];
			}
			_tgtSq = (float)(s / (double)(C::kSide * C::kSide * 3u));
		}
		_liveFrame = _CountLiveSlotRows(px, 1u);

		// ── ㉤ 예산 — ⚠️ **팔 A 에서 한 번만** 센다(코퍼스 96 프레임을 도는 일이다) ──
		if (_arm == 0 && _live == 0u) _live = _CorpusLiveSlotRows();

		// ⭐ 이 검사는 프레임 **하나**를 쓴다 ⇒ 풀도 1 이면 된다(아레나를 뚱뚱하게 만들지 않는다).
		if (!_E.Setup(rhi, 1u)) return false;
		if (!_E.UploadFrame(px)) { LogA("[mlt] 👁️③ 프레임 업로드 실패\n"); return false; }

		if (_arm == 0)
		{
			const uint32 alloc = _E.AllocParams();
			const uint32 live = MLTP2Enc::LiveParams(_live, _E.N());
			LogA("[mlt] 👁️③ ⭐ 파라미터 — **할당 %u**(%.2fM) · **살아있음 %u**(%.2fM · 자리표 %u/%u 행 = %.1f%%)\n",
				alloc, (double)((float)alloc / 1.0e6f), live, (double)((float)live / 1.0e6f),
				_live, MLTP2Cfg::kSlotRows, (double)(100.0f * (float)_live / (float)MLTP2Cfg::kSlotRows));
			LogA("[mlt] 👁️③    ⚠️ 예산(≤ %u)은 **살아있는 쪽**으로 센다 — 근거는 `mltp2enc.cw` 머리말\n", kBudget);
			LogA("[mlt] 👁️③    ⓘ 이 프레임 하나가 깨우는 자리표 행 = %u\n", _liveFrame);
			LogA("[mlt] 👁️③    ⓘ 표적의 제곱평균 E[t²] = %.5f (㉠ 의 비교값 · CPU 가 따로 셌다)\n",
				(double)_tgtSq);
		}

		_step = 0u; _read = 0u; _finite = true;
		_first = 0.0f; _last = 0.0f; _best = 0.0f;
		_idsFirst = 0u; _idsLast = 0u;
		return true;
	}

	// ⭐ 코퍼스(A단계와 **같은** 씨앗·프레임 수)에서 살아있는 자리표 행을 센다.
	//   ⚠️ A단계와 같은 표본이어야 그 로그의 「바이트 종류 6」과 나란히 읽힌다.
	static uint32 _CorpusLiveSlotRows()
	{
		typedef MLTP2Cfg C;
		Array<uint8> hit; hit.Reset(0);
		for (uint32 i = 0; i < C::kSlotRows; ++i) hit.Add(0u);
		ImageFormat::Bitmap bmp;
		Bytes packed;
		for (uint32 s = 0; s < kCorpusSeeds; ++s)
		{
			MLTWorld w;
			w.Reset(s, 0u, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
			for (uint32 f = 0; f < kCorpusFrames; ++f)
			{
				w.Step();
				if (!w.Render(bmp) || !MLTWorld::Pack(bmp, nullptr, packed)) return 0u;
				_MarkSlotRows((const uint8*)packed.GetData(), hit.Data());
			}
		}
		uint32 n = 0u;
		for (uint32 i = 0; i < C::kSlotRows; ++i) if (hit[i] != 0u) ++n;
		return n;
	}

	static uint32 _CountLiveSlotRows(const uint8* px, uint32 frames)
	{
		typedef MLTP2Cfg C;
		Array<uint8> hit; hit.Reset(0);
		for (uint32 i = 0; i < C::kSlotRows; ++i) hit.Add(0u);
		for (uint32 f = 0; f < frames; ++f) _MarkSlotRows(px, hit.Data());
		uint32 n = 0u;
		for (uint32 i = 0; i < C::kSlotRows; ++i) if (hit[i] != 0u) ++n;
		return n;
	}

	// `(자리 s, 바이트 b)` 쌍을 표시한다 — ⚠️ 색인이 `patch_embed` 와 **글자 그대로 같아야** 한다.
	static void _MarkSlotRows(const uint8* px, uint8* hit)
	{
		typedef MLTP2Cfg C;
		for (uint32 p = 0; p < C::kPatches; ++p)
		{
			const uint32 py = p / C::kGrid, pxi = p % C::kGrid;
			for (uint32 s = 0; s < C::kSlots; ++s)
			{
				const uint32 sy = s / C::kPatch, sx = s % C::kPatch;
				const uint32 fy = py * C::kPatch + sy, fx = pxi * C::kPatch + sx;
				hit[s * 256u + (uint32)px[fy * C::kSide + fx]] = 1u;
			}
		}
	}

	static void _Record(float mse, bool fin)
	{
		if (!fin) _finite = false;
		if (!(mse == mse) || mse > 1.0e30f) _finite = false;
		if (_read == 0u) { _first = mse; _best = mse; }
		if (mse < _best) _best = mse;
		_last = mse;
		++_read;
		const bool logNow = (_read == 1u || _read % kLogEvery == 0u || _read == kSteps);
		if (logNow)
		{
			uint32 dist = 0u, oor = 0u; float mg = 0.0f;
			if (_E.ReadActStats(dist, oor, mg))
			{
				if (_read == 1u) _idsFirst = dist;
				_idsLast = dist;
			}
			LogA("[mlt] 👁️③   팔 %s 스텝 %3u · MSE %.5f (최저 %.5f) · 활성 %u종/%u · |mag|max %.3f"
			     " · ⏱️ 렌더CPU %.1fms\n",
				_ArmName(), _read, (double)mse, (double)_best, dist, MLTP2Cfg::kPatches * MLTP2Cfg::kK,
				(double)mg, (double)FrameStats::renderCpuMs);
			if (oor != 0u)
				LogA("[mlt] 👁️③   ⚠️ 범위 밖 id %u개 — `act_topk` 의 센티널이 나왔다(사전보다 k 가 크면 그렇다)\n", oor);
		}
	}

	static void _Judge()
	{
		_armFirst[_arm] = _first; _armLast[_arm] = _last;
		const float rel = (_tgtSq > 1.0e-9f) ? (Abs(_first - _tgtSq) / _tgtSq) : 1.0f;
		const bool g1 = (rel <= kInitTol);
		const bool g4 = _finite;
		const bool g5 = (MLTP2Enc::LiveParams(_live, _E.N()) <= kBudget);
		bool g2 = true, g3 = true;
		if (_arm == 0) g2 = (_best < kDropTo * _first);
		else           g3 = (Abs(_last - _first) <= kFlatRel * Abs(_first));

		LogA("[mlt] 👁️③ ── 팔 %s 결과 ──\n", _ArmName());
		LogA("[mlt] 👁️③   ㉠ 초기 MSE %.5f vs E[t²] %.5f (상대 %.1f%% ≤ %.0f%%) → %s\n",
			(double)_first, (double)_tgtSq, (double)(rel * 100.0f), (double)(kInitTol * 100.0f),
			g1 ? "통과" : "⛔");
		if (_arm == 0)
			LogA("[mlt] 👁️③   ㉡ 최저 MSE %.5f < %.2f × 초기(%.5f) → %s\n",
				(double)_best, (double)kDropTo, (double)(kDropTo * _first), g2 ? "통과" : "⛔");
		else
			LogA("[mlt] 👁️③   ㉢ 평평함 |%.5f − %.5f| = %.2e ≤ %.0e·초기 → %s\n",
				(double)_last, (double)_first, (double)Abs(_last - _first), (double)kFlatRel,
				g3 ? "통과" : "⛔");
		LogA("[mlt] 👁️③   ㉣ 전 구간 유한 → %s\n", g4 ? "통과" : "⛔");
		LogA("[mlt] 👁️③   ㉤ 살아있는 파라미터 %u ≤ %u → %s\n",
			MLTP2Enc::LiveParams(_live, _E.N()), kBudget, g5 ? "통과" : "⛔");
		LogA("[mlt] 👁️③   ⓘ 활성 종류 %u → %u (관문 아님 · 붕괴의 얼굴을 본다)\n", _idsFirst, _idsLast);
		_pass[_arm] = g1 && g2 && g3 && g4 && g5;
	}

	static void _NextArm()
	{
		if (_arm == 0) { _arm = 1; _begun = false; return; }
		_arm = 2;
		_E.Destroy();
		const bool ok = _pass[0] && _pass[1];
		LogA("[mlt] ══════════════════════════════════════════════════\n");
		LogA("[mlt] 👁️③ **조립 검사(비전) — %s**\n", ok ? "✅ 통과" : "⛔ 실패");
		LogA("[mlt] 👁️③   A(lr=3e-3) %.5f → %.5f · B(lr=0) %.5f → %.5f\n",
			(double)_armFirst[0], (double)_armLast[0], (double)_armFirst[1], (double)_armLast[1]);
		if (!ok)
			LogA("[mlt] 👁️③   ⚠️ **모델을 키우지 마라** — 겹치기(dPatch=g+pos)·전치·축을 읽어라\n");
		LogA("[mlt] ══════════════════════════════════════════════════\n");
	}

	static constexpr uint32 kCorpusSeeds = 12u, kCorpusFrames = 8u;   // ⚠️ A단계와 같은 표본
};
