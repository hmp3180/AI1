// mltgpu.cw — 🖥️ **판정 ① · GPU 커널이 CPU 레퍼런스와 같은 수를 내나**
//
// ★ **② 와 다른 검사다.** ② (`mltgrad.cw`)는 *"미분이 맞나"*(CPU 안에서 수치 vs 해석),
//   ① 은 *"셰이더가 CPU 와 같은 수를 내나"* 다. ② 가 통과해도 ① 은 얼마든지 틀릴 수 있다
//   (push 배치·인덱싱·디스패치 축이 전부 ① 에만 걸린다).
//
// ══════════════════════════════════════════════════════════════════════════════
// ⚠️⚠️⚠️ **이 판정이 「조용히 통과」하는 경로를 막는 장치 다섯** — 전부 실측 근거가 있다.
// ══════════════════════════════════════════════════════════════════════════════
//
// ㉠ ★ **텐서를 `[numthreads]` 보다 크게 잡는다.**
//    RHI 는 축마다 `ceil(threads / local)` 로 그룹을 낸다. 판정 텐서가 local(64 / 256 / 16×16)보다
//    작으면 **모든 디스패치가 `(1,1,1)` 이 되고 워크그룹이 통째로 떠서 범위검사가 전부를 덮는다**
//    ⇒ ***`Dispatch` 인자가 무엇이어도 결과가 같다.*** 그러면 축 오배선이 **원리적으로 안 보인다.**
//    ⇒ 그래서 `kRows = 70 > 64` · `kCols = 300 > 256` · `kDict = 100 > 16` 처럼 **일부러 넘긴다.**
//    ★ 그리고 축을 **틀리게 썼을 때 실제로 칸이 빈다**: `rmsnorm_gbwd` 는 X=`cols`(300)인데 `rows`(70)를
//      넣으면 256스레드로 300 을 못 덮고, `vis_recon_bwd_tab` 은 Y=`dict`(100)인데 `rows`(20)를 넣으면
//      32스레드로 100 을 못 덮는다 ⇒ 남은 칸이 **포이즌으로 남아 걸린다**(㉡).
//
// ㉡ ★ **아레나를 「포이즌」으로 채운다**(0 이 아니다). 안 써진 칸이 0 이면 CPU 쪽도 0 인 자리와
//    구별이 안 되어 **오차 0 = 통과**가 된다(이 저장소가 밟은 그 자리: *"아레나의 안 쓰는 칸에 앞
//    실행의 값이 남는다 — 그런데 커널 판정은 그대로 통과했다"*).
//    ⚠️⚠️ `Array<float>::Reset(n)` 은 **값초기화(0)** 를 한다 — 포이즌을 원하면 **손으로 채워야** 한다
//    (지시서가 «0 으로 안 채운다» 고 적었는데 실측은 반대였다).
//
// ㉢ ★ **NaN 은 오차를 못 올린다.** `MLMaxAbsErr` 이 `if (ad > worst)` 이고 **NaN 비교는 늘 false**
//    ⇒ ***GPU 출력이 전부 NaN 이면 `err = 0` 이 되어 완벽한 통과로 찍힌다.***
//    ⇒ 판정 첫머리에서 **유한성 전수 검사**를 한다.
//
// ㉣ ★ **입력에 포이즌이 남으면 GPU·CPU 가 「같은 쓰레기」를 낸다** — CPU 는 업로드한 것과 같은
//    호스트 배열을 보므로 **비트까지 같고 오차가 0** 이다. ⇒ **입력 텐서도 포이즌 검사**를 한다.
//
// ㉤ ★ **전부 포이즌이면 「축이 틀린 것」이 아니라 「프레임이 안 넘어간 것」이다.**
//    디스패치는 프레임 컴퓨트 커맨드버퍼에 **누적만** 되고 제출은 Present 다 ⇒ 같은 프레임에 읽으면
//    전부 포이즌이다. ⚠️ 그 오독이 이 저장소에 이미 기록돼 있다 ⇒ **그 진단을 축보다 먼저** 찍는다.
//
// ⚠️ 그 밖: `n == 0` 은 **판정불가**(아레나가 넘치면 `Alloc` 이 무효 텐서를 조용히 준다) ·
//   `Write` 는 **Array 오버로드만**(생 포인터 판은 넘어읽어 크래시를 냈다) · 통짜 Write 를 **쪼개지 않는다**.
//
// ⚠️⚠️ **덮지 못한 분기를 요약에 적는다** — 「전부 통과」가 *"셰이더가 CPU 와 같다"* 로 읽히면 오독이다.
//   지금 안 도는 것: `ce_logits` 의 무효 표적 · `act_topk` 의 `k > dict` 센티널 ·
//   `vis_recon` 의 `v >= dict` 건너뛰기 · `rope` 의 2D(mode=1) · `attn_softmax` 의 `causalOff > 0`.
//   ★ 반대로 **`patch_embed` 의 `b > 255` 접기는 덮었다** — 프레임에 300 을 한 칸 넣는다(fwd/bwd 양쪽).

using namespace PE;

class MLTGpu
{
public:
	// ══════════════════════════════════════════════════════════════════
	// 🚪 매 프레임 불린다(렌더 스레드 · 렌더패스 밖). 스스로 단계를 진행한다.
	//   ⚠️ **디스패치 프레임과 리드백 프레임을 가른다** — 같은 프레임에 읽으면 전부 포이즌이다(㉤).
	// ══════════════════════════════════════════════════════════════════
	// ★ 끝났나 — 뒤 판정(판정 ③)이 **이것이 끝난 뒤에** 시작한다(같은 프레임에 겹치면
	//   포이즌 규약이 흐려지고 무엇보다 로그가 섞여 읽을 수 없다).
	static bool Done() { return _stage >= 2; }

	static void Tick(RHI* rhi)
	{
		if (_stage >= 2 || rhi == nullptr) return;
		if (_stage == 0) { if (_Setup(rhi) && _DispatchAll()) _stage = 1; else _stage = 2; return; }
		_Judge();
		_stage = 2;
	}

private:
	// ── 크기 — ⚠️ ㉠ 의 그 이유로 **일부러 local 을 넘긴다** ────────────
	static constexpr uint32 kRows = 70;    // > 64 (행 하나=스레드 하나 커널들)
	static constexpr uint32 kCols = 300;   // > 256 (`rmsnorm_gbwd` 의 X 축)
	static constexpr uint32 kT    = 70;    // > 64 (attn 행)
	static constexpr uint32 kSw   = 300;   // > 256 (swiglu 원소)
	static constexpr uint32 kCeV  = 20;    // > 16 (`ce_logits_bwd` 의 X)
	static constexpr uint32 kRpR  = 20;    // > 16 (rope 행)
	static constexpr uint32 kRpD  = 40;    // 쌍 = 20 > 16 (rope X)
	static constexpr uint32 kVF   = 20;    // > 16 (`val_enc` 의 X)
	static constexpr uint32 kDict = 100;   // > 16 **그리고 > kVisR** (tab 의 Y 오배선을 잡으려면)
	static constexpr uint32 kK    = 20;    // > 16 (`vis_recon_bwd_mag` 의 X)
	static constexpr uint32 kVisR = 20;    // > 16 (vis 행) ⚠️ kDict 보다 **작아야** 한다
	static constexpr uint32 kPix  = 20;    // > 16 (vis 픽셀)
	// 🧱 patch_embed — ⚠️ **세 축 전부 16 을 넘겨야** 한다(`[numthreads(16,16,1)]` 둘)
	static constexpr uint32 kPeK  = 2;                       // 패치 한 변
	static constexpr uint32 kPeGW = 6, kPeGH = 5;            // 격자 → 패치 30 > 16 (fwd 의 Y)
	static constexpr uint32 kPeW  = kPeGW * kPeK;            // 12
	static constexpr uint32 kPeH  = kPeGH * kPeK;            // 10
	static constexpr uint32 kPeD  = 20;                      // > 16 (양쪽의 X)
	static constexpr uint32 kPeP  = kPeGW * kPeGH;           // 30 = 패치 수
	static constexpr uint32 kPeSR = kPeK * kPeK * 256u;      // 1024 > 16 (⚠️ bwd 의 Y = 표의 행)
	static constexpr uint32 kSubN = 300;                     // > 256 (`[numthreads(256,1,1)]`)
	// 🌐 foot_recon — X/Y/출력 축이 모두 16을 넘도록 일부러 크게 잡는다.
	static constexpr uint32 kFtF = 2, kFtG = 9, kFtK = 20, kFtP = 20, kFtR = 2;
	static constexpr uint32 kFtS = kFtG * 2u - 1u, kFtPatch = kFtG * kFtG;
	// ⭐ act_topk_abs — `act_topk` 과 같은 크기를 쓰지만 **텐서는 따로** 잡는다(값이 섞이지 않게).

	// ⚠️ 포이즌 — 절대값이 커야 「같은 쓰레기」가 결과에 티가 난다. 그리고 유한하다(NaN 은 ㉢ 이 본다).
	static constexpr float kPoison = -1.0e30f;
	static constexpr float kTol    = 1.0e-4f;   // 초월함수가 끼는 커널이 있어 0 을 요구할 수 없다

	// ── 커널 상수 ──────────────────────────────────────────────────
	static constexpr float  kNormEps   = 1.0e-6f;
	static constexpr float  kRopeTheta = 10000.0f;
	static constexpr uint32 kNoIgnore  = 0xFFFFFFFFu;   // ⚠️ 0 이 멀쩡한 id 라 기본값을 안 준다
	// ⚠️⚠️ **판정용 `freqMax` 는 학습용(1000)과 다르다** — `ω·u` 가 커지면 `sin` 위상 오차가
	//   임계를 넘긴다(**정확한 커널인데도**). 셰이더 머리말이 못 박은 자리다.
	//   ⚠️ 그리고 판정 ②(`mltgrad.cw`)는 **64** 를 쓴다 ⇒ 두 판정의 수를 눈으로 대조하지 마라.
	static constexpr float  kJudgeFreqMax = 8.0f;

	inline static int _stage = 0;
	inline static MLArena _ar;
	inline static Array<float> _host;   // 아레나의 **거울** — CPU 레퍼런스가 이것을 본다(비트까지 같다)
	inline static uint32 _need = 0;
	inline static uint32 _spvBytes = 0;

	// 커널 스물아홉(기존 스물다섯 + 전역 발자국 넷)
	enum { kRms, kRmsB, kRmsG, kRope, kAttn, kAttnB, kSwi, kSwiB,
	       kCe, kCeB, kVal, kValB, kTop, kTopB, kVis, kVisM, kVisT,
	       kPE, kPEB, kSub, kTopA, kGather, kGatherB, kResidualSwap, kCoeffSweep,
	       kFoot, kFootM, kFootC, kFootS, kNK };
	inline static MLKernel _k[kNK];

	// 텐서 — 그룹별로 모아 둔다(카나리를 사이에 끼운다)
	inline static MLTensor tRmIn, tRmG, tRmOut, tRmRstd, tRmDO, tRmDI, tRmDG, cA;
	inline static MLTensor tRpIn, tRpPos, tRpOut, tRpDO, tRpDI, cB;
	inline static MLTensor tAtIn, tAtOut, tAtDO, tAtDI, cC;
	inline static MLTensor tSwA, tSwB, tSwOut, tSwDO, tSwDA, tSwDB, cD;
	inline static MLTensor tCeZ, tCeT, tCeP, tCeL, tCeDZ, cE;
	inline static MLTensor tVlIn, tVlOut, tVlDO, tVlDI, cF;
	inline static MLTensor tTpS, tTpId, tTpMg, tTpDM, tTpDS, cG;
	inline static MLTensor tViId, tViMg, tViTab, tViOut, tViDO, tViDM, tViDT, cH;
	// 🧱 patch_embed — ⚠️ 표가 `자리×256` 행이라 이 그룹만으로 아레나의 절반을 먹는다(1024×20 두 장)
	inline static MLTensor tPeFr, tPeSlot, tPePos, tPeOut, tPeDO, tPeDS, cI;
	inline static MLTensor tSbA, tSbB, tSbOut, cJ;
	// ⭐ act_topk_abs — 자기 텐서(입력 점수는 `tTpS` 와 **같은 산포**를 쓰지만 칸은 따로다)
	inline static MLTensor tAbS, tAbId, tAbMg, cK;
	// 🧲 act_gather — ids 는 앞의 `act_topk` 결과를 그대로 받아 커널 사이 배선까지 함께 본다.
	inline static MLTensor tGaA, tGaB, tGaMg, tGaDM, tGaDI, cL;
	// 🔁 residual_swap — top-k와 recon까지 CPU로 만들어 입력해 교체/no-op 배선을 함께 본다.
	inline static MLTensor tRsT, tRsR, tRsS, tRsTab, tRsId0, tRsMg0, tRsId1, tRsMg1, cM;
	// 🔧 coeff_sweep — 같은 입력의 ids는 고정하고 mag만 한 바퀴 보정한다.
	inline static MLTensor tCsMg1, cN;
	// 🌐 전역 발자국 — candidate ids · factor X/Y · 네 출력.
	inline static MLTensor tFtId, tFtMg, tFtCode, tFtX, tFtY, tFtOut, tFtDO, tFtDM, tFtDC, tFtDX, tFtDY, cO;

	inline static int _fail = 0;
	inline static int _judged = 0;

	// ══════════════════════════════════════════════════════════════════
	// 결정적 산포 — ⚠️ 난수를 쓰지 않는다(시드 스트림을 소비하면 비트 재현이 깨진다).
	//   ★ 부호가 섞인다 — 0 을 지나는 출력이 없으면 이 판정이 뜻이 없다.
	// ══════════════════════════════════════════════════════════════════
	static float _Spread(uint32 i, uint32 salt)
	{
		uint32 h = i * 2654435761u + salt * 2246822519u;
		h ^= (h >> 15); h *= 2654435761u; h ^= (h >> 13);
		return ((float)(h & 0xFFFFu) / 32768.0f) - 1.0f;
	}

	static float* _P(const MLTensor& t) { return _host.Data() + t.offset; }

	// 텐서를 산포로 채운다(호스트 거울에 직접 쓴다 — 통짜 Write 한 번으로 올라간다).
	static void _Put(const MLTensor& t, uint32 salt, float amp = 1.0f)
	{
		float* p = _P(t);
		for (uint32 i = 0; i < t.Count(); ++i) p[i] = _Spread(i, salt) * amp;
	}

	// 카나리 — 그룹 사이에 끼워 **남의 텐서를 덮는 오버런**을 잡는다.
	//   ⚠️ 아레나 끝에만 두면 오버런이 거의 항상 **옆 텐서** 위에 떨어져 엉뚱한 커널이 범인이 된다.
	static void _Canary(const MLTensor& t) { float* p = _P(t); for (uint32 i = 0; i < t.Count(); ++i) p[i] = kPoison; }

	static bool _AllPoison(const float* v, uint32 n)
	{
		for (uint32 i = 0; i < n; ++i) if (v[i] > -1.0e29f) return false;
		return n != 0u;
	}

	static bool _AnyPoison(const float* v, uint32 n)
	{
		for (uint32 i = 0; i < n; ++i) if (v[i] < -1.0e29f) return true;
		return false;
	}

	static bool _AllFinite(const float* v, uint32 n)
	{
		// ⚠️ ㉢ — NaN/Inf 를 **여기서** 잡는다. `MLMaxAbsErr` 은 NaN 을 못 센다.
		for (uint32 i = 0; i < n; ++i) { const float x = v[i]; if (!(x == x) || x > 3.0e38f || x < -3.0e38f) return false; }
		return true;
	}

	// ══════════════════════════════════════════════════════════════════
	// 🏗 셋업 — 할당은 **여기서 한 번만**(`Alloc` 은 해제가 없다).
	// ══════════════════════════════════════════════════════════════════
	static bool _Setup(RHI* rhi)
	{
		const uint32 need =
			// rmsnorm
			kRows * kCols * 4u + kCols * 2u + kRows + 8u
			// rope
			+ kRpR * kRpD * 4u + kRpR + 8u
			// attn
			+ kT * kT * 4u + 8u
			// swiglu
			+ kSw * 6u + 8u
			// ce
			+ kRows * kCeV * 3u + kRows * 2u + 8u
			// val_enc
			+ kRows * kVF * 2u * 2u + kRows * 2u + 8u
			// act_topk
			+ kRows * kDict * 2u + kRows * kK * 3u + 8u
			// vis_recon
			+ kVisR * kK * 4u + kDict * kPix * 2u + kVisR * kPix * 2u + 8u
			// patch_embed — 프레임 + 표 두 장(slot·dSlot) + 패치칸 셋(pos·out·dOut)
			+ kPeW * kPeH + kPeSR * kPeD * 2u + kPeP * kPeD * 3u + 8u
			// sub
			+ kSubN * 3u + 8u
			// act_topk_abs
			+ kRows * kDict + kRows * kK * 2u + 8u
			// act_gather — A/B/dIn + mag/dMag
			+ kRows * kDict * 3u + kRows * kK * 2u + 8u
			// act_residual_swap — target/recon + score/table + ids/mag 입출력
			+ kVisR * kPix * 2u + kVisR * kDict + kDict * kPix + kVisR * kK * 4u + 8u
			// act_coeff_sweep — 위 입력을 공유하고 mag 출력만 별도
			+ kVisR * kK + 8u
			// foot_recon — 입력/출력과 네 기울기
			+ kFtF * kFtK * 2u + kDict * kFtP * 2u + kDict * kFtR * kFtS * 4u
			+ kFtF * kFtPatch * kFtP * 2u + 8u
			+ 64u;   // ⚠️ 뒤 패딩 — `robustBufferAccess` 가 꺼져 있어 범위 밖 SSBO 쓰기는 **정의되지 않는다**

		if (!_ar.Create(rhi, need)) { LogA("[mlt] ① 아레나 생성 실패(need=%u)\n", need); return false; }
		_need = need;

		tRmIn = _ar.Alloc(kRows, kCols); tRmG = _ar.Alloc(1, kCols); tRmOut = _ar.Alloc(kRows, kCols);
		tRmRstd = _ar.Alloc(1, kRows); tRmDO = _ar.Alloc(kRows, kCols); tRmDI = _ar.Alloc(kRows, kCols);
		tRmDG = _ar.Alloc(1, kCols); cA = _ar.Alloc(1, 8);

		tRpIn = _ar.Alloc(kRpR, kRpD); tRpPos = _ar.Alloc(1, kRpR); tRpOut = _ar.Alloc(kRpR, kRpD);
		tRpDO = _ar.Alloc(kRpR, kRpD); tRpDI = _ar.Alloc(kRpR, kRpD); cB = _ar.Alloc(1, 8);

		tAtIn = _ar.Alloc(kT, kT); tAtOut = _ar.Alloc(kT, kT); tAtDO = _ar.Alloc(kT, kT);
		tAtDI = _ar.Alloc(kT, kT); cC = _ar.Alloc(1, 8);

		tSwA = _ar.Alloc(1, kSw); tSwB = _ar.Alloc(1, kSw); tSwOut = _ar.Alloc(1, kSw);
		tSwDO = _ar.Alloc(1, kSw); tSwDA = _ar.Alloc(1, kSw); tSwDB = _ar.Alloc(1, kSw); cD = _ar.Alloc(1, 8);

		tCeZ = _ar.Alloc(kRows, kCeV); tCeT = _ar.Alloc(1, kRows); tCeP = _ar.Alloc(kRows, kCeV);
		tCeL = _ar.Alloc(1, kRows); tCeDZ = _ar.Alloc(kRows, kCeV); cE = _ar.Alloc(1, 8);

		tVlIn = _ar.Alloc(1, kRows); tVlOut = _ar.Alloc(kRows, kVF * 2u); tVlDO = _ar.Alloc(kRows, kVF * 2u);
		tVlDI = _ar.Alloc(1, kRows); cF = _ar.Alloc(1, 8);

		tTpS = _ar.Alloc(kRows, kDict); tTpId = _ar.Alloc(kRows, kK); tTpMg = _ar.Alloc(kRows, kK);
		tTpDM = _ar.Alloc(kRows, kK); tTpDS = _ar.Alloc(kRows, kDict); cG = _ar.Alloc(1, 8);

		tViId = _ar.Alloc(kVisR, kK); tViMg = _ar.Alloc(kVisR, kK); tViTab = _ar.Alloc(kDict, kPix);
		tViOut = _ar.Alloc(kVisR, kPix); tViDO = _ar.Alloc(kVisR, kPix); tViDM = _ar.Alloc(kVisR, kK);
		tViDT = _ar.Alloc(kDict, kPix); cH = _ar.Alloc(1, 8);

		tPeFr = _ar.Alloc(kPeH, kPeW); tPeSlot = _ar.Alloc(kPeSR, kPeD); tPePos = _ar.Alloc(kPeP, kPeD);
		tPeOut = _ar.Alloc(kPeP, kPeD); tPeDO = _ar.Alloc(kPeP, kPeD); tPeDS = _ar.Alloc(kPeSR, kPeD);
		cI = _ar.Alloc(1, 8);

		tSbA = _ar.Alloc(1, kSubN); tSbB = _ar.Alloc(1, kSubN); tSbOut = _ar.Alloc(1, kSubN);
		cJ = _ar.Alloc(1, 8);

		tAbS = _ar.Alloc(kRows, kDict); tAbId = _ar.Alloc(kRows, kK); tAbMg = _ar.Alloc(kRows, kK);
		cK = _ar.Alloc(1, 8);

		tGaA = _ar.Alloc(kRows, kDict); tGaB = _ar.Alloc(kRows, kDict); tGaMg = _ar.Alloc(kRows, kK);
		tGaDM = _ar.Alloc(kRows, kK); tGaDI = _ar.Alloc(kRows, kDict); cL = _ar.Alloc(1, 8);

		tRsT = _ar.Alloc(kVisR, kPix); tRsR = _ar.Alloc(kVisR, kPix); tRsS = _ar.Alloc(kVisR, kDict);
		tRsTab = _ar.Alloc(kDict, kPix); tRsId0 = _ar.Alloc(kVisR, kK); tRsMg0 = _ar.Alloc(kVisR, kK);
		tRsId1 = _ar.Alloc(kVisR, kK); tRsMg1 = _ar.Alloc(kVisR, kK); cM = _ar.Alloc(1, 8);
		tCsMg1 = _ar.Alloc(kVisR, kK); cN = _ar.Alloc(1, 8);
		tFtId = _ar.Alloc(kFtF, kFtK); tFtMg = _ar.Alloc(kFtF, kFtK);
		tFtCode = _ar.Alloc(kDict, kFtP); tFtX = _ar.Alloc(kDict * kFtR, kFtS); tFtY = _ar.Alloc(kDict * kFtR, kFtS);
		tFtOut = _ar.Alloc(kFtF * kFtPatch, kFtP); tFtDO = _ar.Alloc(kFtF * kFtPatch, kFtP);
		tFtDM = _ar.Alloc(kFtF, kFtK); tFtDC = _ar.Alloc(kDict, kFtP);
		tFtDX = _ar.Alloc(kDict * kFtR, kFtS); tFtDY = _ar.Alloc(kDict * kFtR, kFtS); cO = _ar.Alloc(1, 8);

		// ⚠️ **마지막 텐서만 검사하면 된다**(범프 할당이라 앞이 성공했으면 뒤도 성공했다).
		if (!cO.IsValid()) { LogA("[mlt] ① 텐서 할당 실패 — 아레나 부족(need=%u · used=%u)\n", need, _ar.Used()); return false; }

		// ── ㉡ 포이즌 프리필 → 그 위에 입력만 얹는다 ──────────────────
		//   ⚠️ `Reset(n)` 은 **0** 으로 채운다 ⇒ 포이즌은 손으로 넣어야 한다.
		_host.Reset(0);
		for (uint32 i = 0; i < need; ++i) _host.Add(kPoison);

		_Put(tRmIn, 11); _Put(tRmG, 12); _Put(tRmDO, 13);
		_Put(tRpIn, 21); _Put(tRpDO, 22);
		{ float* p = _P(tRpPos); for (uint32 r = 0; r < kRpR; ++r) p[r] = (float)r; }
		_Put(tAtIn, 31); _Put(tAtDO, 32);
		_Put(tSwA, 41); _Put(tSwB, 42); _Put(tSwDO, 43);
		_Put(tCeZ, 51);
		{ float* p = _P(tCeT); for (uint32 r = 0; r < kRows; ++r) p[r] = (float)(r % kCeV); }
		_Put(tVlIn, 61); _Put(tVlDO, 62);
		_Put(tTpS, 71); _Put(tTpDM, 72);
		_Put(tViMg, 81); _Put(tViTab, 82); _Put(tViDO, 83);
		{ float* p = _P(tViId); for (uint32 i = 0; i < tViId.Count(); ++i) p[i] = (float)((i * 7u + 1u) % kDict); }
		_Put(tPeSlot, 91, 0.5f); _Put(tPePos, 92); _Put(tPeDO, 93);
		// ⚠️ 프레임은 **정수 바이트**(0..255)다 — 산포로 채우면 전부 0 으로 접혀 판정이 뜻이 없어진다.
		//   ⚠️ 바이트를 **다섯 종류**로 좁힌다: gather 가 맞는지는 **같은 자리에 같은 값이 여러 패치에서**
		//     나올 때만 드러난다(합이 한 항뿐이면 누락도 순서도 티가 안 난다).
		//   ★ 그리고 **300 을 한 칸** 섞어 `b > 255 → 0` 접기 규약을 fwd/bwd 가 같이 지키는지 본다.
		{
			float* p = _P(tPeFr);
			for (uint32 i = 0; i < tPeFr.Count(); ++i) p[i] = (float)((i * 7u + 1u) % 5u);
			p[tPeFr.Count() / 2u] = 300.0f;
		}
		_Put(tSbA, 101); _Put(tSbB, 102);
		// ⭐ `act_topk` 과 **같은 산포**(salt 71)를 쓴다 — 그러면 두 커널의 결과를 나란히 읽을 수 있다
		//   (`abs` 쪽이 음의 큰 값을 고르는지 눈으로 보인다).
		_Put(tAbS, 71);
		_Put(tGaA, 141); _Put(tGaB, 142); _Put(tGaDM, 143);
		_Put(tRsT, 151, 0.7f); _Put(tRsS, 152, 0.5f); _Put(tRsTab, 153, 0.35f);
		// 입력 ids/mag/recon은 서로 독립 산포가 아니라 실제 top-k→recon 배선으로 만든다.
		MLActTopkCpu(_P(tRsS), _P(tRsId0), _P(tRsMg0), kVisR, kDict, kK);
		MLVisReconCpu(_P(tRsId0), _P(tRsMg0), _P(tRsTab), _P(tRsR), kVisR, kK, kPix, kDict);
		_Put(tFtMg, 161, 0.5f); _Put(tFtCode, 162, 0.4f); _Put(tFtX, 163, 0.6f); _Put(tFtY, 164, 0.6f); _Put(tFtDO, 165, 0.5f);
		{
			float* p = _P(tFtId);
			for (uint32 i = 0; i < tFtId.Count(); ++i)
				p[i] = (float)(((i * 13u + 3u) % kFtPatch) * kDict + ((i * 7u + 1u) % kDict));
		}

		_Canary(cA); _Canary(cB); _Canary(cC); _Canary(cD);
		_Canary(cE); _Canary(cF); _Canary(cG); _Canary(cH);
		_Canary(cI); _Canary(cJ); _Canary(cK); _Canary(cL); _Canary(cM); _Canary(cN); _Canary(cO);

		// ⚠️ ㉡ 진단 — 포이즌 칸 수를 **찍는다**(프리필이 조용히 0 으로 바뀌는 것을 막는다).
		uint32 pz = 0;
		for (uint32 i = 0; i < need; ++i) if (_host.Data()[i] < -1.0e29f) ++pz;
		LogA("[mlt] ① 아레나 %u float · 포이즌 %u칸(%.1f%%) · 입력 %u칸\n",
			need, pz, (double)(100.0f * (float)pz / (float)need), need - pz);

		// ⚠️ 통짜 Write 한 번 — **쪼개지 않는다.** 그리고 크기를 **하드 검사**한다
		//   (`Write` 는 크기가 달라도 `min` 만 올리고 경고만 찍은 뒤 `true` 를 준다).
		if (_host.Count() != need) { LogA("[mlt] ① 호스트 크기 불일치 %u != %u\n", _host.Count(), need); return false; }
		MLTensor whole; whole.offset = 0u; whole.rows = 1u; whole.cols = need;
		if (!_ar.Write(whole, _host)) { LogA("[mlt] ① 업로드 실패\n"); return false; }

		return _LoadAll(rhi);
	}

	// ⚠️ 경로는 **`const char*` 그대로** 넘긴다 — 기존 관례가 그렇고(`_LoadKernel`) `String` 조립이
	//   필요 없다. ⭐ 그리고 `.spv` 바이트 수를 로그에 남긴다: **낡은 spv 는 로드가 성공한다**
	//   (셰이더를 고치고 쿡을 안 돌리면 옛 커널이 판정을 통과/실패하고 어느 쪽이든 뜻이 없다).
	static bool _Load(RHI* rhi, int idx, const char* path)
	{
		Bytes spv;
		if (!PlatformFile::LoadBytes(path, spv, PlatformFileSource::Package) || spv.GetSize() == 0)
		{
			LogA("[mlt] ① %s 를 못 읽었다(쿡 확인)\n", path);
			return false;
		}
		if (!_k[idx].Create(rhi, spv.GetData(), spv.GetSize(), _ar))
		{
			LogA("[mlt] ① 커널 생성 실패: %s (%llu 바이트)\n", path, (unsigned long long)spv.GetSize());
			return false;
		}
		_spvBytes += (uint32)spv.GetSize();
		return true;
	}

	static bool _LoadAll(RHI* rhi)
	{
		_spvBytes = 0u;
		const bool ok =
		       _Load(rhi, kRms,  "shaders/rmsnorm.cs.spv")      && _Load(rhi, kRmsB, "shaders/rmsnorm_bwd.cs.spv")
		    && _Load(rhi, kRmsG, "shaders/rmsnorm_gbwd.cs.spv") && _Load(rhi, kRope, "shaders/rope.cs.spv")
		    && _Load(rhi, kAttn, "shaders/attn_softmax.cs.spv") && _Load(rhi, kAttnB, "shaders/softmax_bwd.cs.spv")
		    && _Load(rhi, kSwi,  "shaders/swiglu.cs.spv")       && _Load(rhi, kSwiB, "shaders/swiglu_bwd.cs.spv")
		    && _Load(rhi, kCe,   "shaders/ce_logits.cs.spv")    && _Load(rhi, kCeB,  "shaders/ce_logits_bwd.cs.spv")
		    && _Load(rhi, kVal,  "shaders/val_enc.cs.spv")      && _Load(rhi, kValB, "shaders/val_enc_bwd.cs.spv")
		    && _Load(rhi, kTop,  "shaders/act_topk.cs.spv")     && _Load(rhi, kTopB, "shaders/act_topk_bwd.cs.spv")
		    && _Load(rhi, kVis,  "shaders/vis_recon.cs.spv")    && _Load(rhi, kVisM, "shaders/vis_recon_bwd_mag.cs.spv")
		    && _Load(rhi, kVisT, "shaders/vis_recon_bwd_tab.cs.spv")
		    && _Load(rhi, kPE,   "shaders/patch_embed.cs.spv")     && _Load(rhi, kPEB, "shaders/patch_embed_bwd.cs.spv")
		    && _Load(rhi, kSub,  "shaders/sub.cs.spv")
		    && _Load(rhi, kTopA, "shaders/act_topk_abs.cs.spv")
		    && _Load(rhi, kGather,  "shaders/act_gather.cs.spv")
		    && _Load(rhi, kGatherB, "shaders/act_gather_bwd.cs.spv")
		    && _Load(rhi, kResidualSwap, "shaders/act_residual_swap.cs.spv")
		    && _Load(rhi, kCoeffSweep, "shaders/act_coeff_sweep.cs.spv")
		    && _Load(rhi, kFoot,  "shaders/foot_recon.cs.spv")
		    && _Load(rhi, kFootM, "shaders/foot_recon_bwd_mag.cs.spv")
		    && _Load(rhi, kFootC, "shaders/foot_recon_bwd_code.cs.spv")
		    && _Load(rhi, kFootS, "shaders/foot_recon_bwd_space.cs.spv");
		if (ok) LogA("[mlt] ① 커널 29장 로드 · spv 합계 %u 바이트\n", _spvBytes);
		return ok;
	}

	// ══════════════════════════════════════════════════════════════════
	// 🚀 디스패치 — ⚠️ **축을 표대로** 넣는다. 틀리면 ㉠+㉡ 이 잡는다.
	// ══════════════════════════════════════════════════════════════════
	static bool _DispatchAll()
	{
		// 📏 rmsnorm — X=rows
		{
			MLRmsNormParams p{}; p.inOff = tRmIn.offset; p.gainOff = tRmG.offset;
			p.outOff = tRmOut.offset; p.rstdOff = tRmRstd.offset;
			p.rows = kRows; p.cols = kCols; p.eps = kNormEps;
			if (!_k[kRms].Dispatch(kRows, 1u, 1u, &p, (uint32)sizeof(p))) return _Bad("rmsnorm");
		}
		{
			MLRmsNormBwdParams p{}; p.inOff = tRmIn.offset; p.gainOff = tRmG.offset;
			p.rstdOff = tRmRstd.offset; p.dOutOff = tRmDO.offset; p.dInOff = tRmDI.offset;
			p.rows = kRows; p.cols = kCols;
			if (!_k[kRmsB].Dispatch(kRows, 1u, 1u, &p, (uint32)sizeof(p))) return _Bad("rmsnorm_bwd");
		}
		{
			// ⚠️⚠️ **X = cols** 다(다른 rmsnorm 둘은 rows). 축이 정반대인 유일한 커널 — gather 라서.
			MLRmsNormGBwdParams p{}; p.inOff = tRmIn.offset; p.rstdOff = tRmRstd.offset;
			p.dOutOff = tRmDO.offset; p.dGainOff = tRmDG.offset; p.rows = kRows; p.cols = kCols;
			if (!_k[kRmsG].Dispatch(kCols, 1u, 1u, &p, (uint32)sizeof(p))) return _Bad("rmsnorm_gbwd");
		}
		// 🌀 rope — X = **쌍** 개수(dim>>1), Y=rows. bwd 는 같은 spv 를 dirSign=-1 로.
		{
			MLRopeParams p{}; p.inOff = tRpIn.offset; p.outOff = tRpOut.offset; p.posOff = tRpPos.offset;
			p.rows = kRpR; p.dim = kRpD; p.mode = 0u; p.theta = kRopeTheta; p.dirSign = 1.0f;
			if (!_k[kRope].Dispatch(kRpD >> 1, kRpR, 1u, &p, (uint32)sizeof(p))) return _Bad("rope");
			p.inOff = tRpDO.offset; p.outOff = tRpDI.offset; p.dirSign = -1.0f;
			if (!_k[kRope].Dispatch(kRpD >> 1, kRpR, 1u, &p, (uint32)sizeof(p))) return _Bad("rope(bwd)");
		}
		// 🎯 attn_softmax — X=rows. bwd 는 **기존** softmax_bwd(⚠️ scale 을 fwd 와 같게).
		{
			MLAttnSoftmaxParams p{}; p.inOff = tAtIn.offset; p.outOff = tAtOut.offset;
			p.rows = kT; p.cols = kT; p.causalOff = 0u; p.scale = 1.0f;
			if (!_k[kAttn].Dispatch(kT, 1u, 1u, &p, (uint32)sizeof(p))) return _Bad("attn_softmax");
			// ⚠️ `scale` 을 fwd 와 **같은 값**으로 준다 — 한쪽만 주면 기울기가 그 배수만큼 틀린다.
			MLSoftmaxBwdParams q{}; q.probOff = tAtOut.offset; q.dOutOff = tAtDO.offset;
			q.dInOff = tAtDI.offset; q.rows = kT; q.cols = kT; q.scale = 1.0f;
			if (!_k[kAttnB].Dispatch(kT, 1u, 1u, &q, (uint32)sizeof(q))) return _Bad("softmax_bwd");
		}
		// 🚪 swiglu — 원소별, X=count
		{
			MLSwigluParams p{}; p.aOff = tSwA.offset; p.bOff = tSwB.offset; p.outOff = tSwOut.offset; p.count = kSw;
			if (!_k[kSwi].Dispatch(kSw, 1u, 1u, &p, (uint32)sizeof(p))) return _Bad("swiglu");
			MLSwigluBwdParams q{}; q.aOff = tSwA.offset; q.bOff = tSwB.offset; q.dOutOff = tSwDO.offset;
			q.dAOff = tSwDA.offset; q.dBOff = tSwDB.offset; q.count = kSw;
			if (!_k[kSwiB].Dispatch(kSw, 1u, 1u, &q, (uint32)sizeof(q))) return _Bad("swiglu_bwd");
		}
		// 📉 ce_logits — fwd X=rows · bwd X=cols,Y=rows. ⚠️ ignoreIdx 를 **양쪽 같은 값**으로.
		{
			MLCeLogitsParams p{}; p.logitsOff = tCeZ.offset; p.targetOff = tCeT.offset;
			p.probsOff = tCeP.offset; p.lossOff = tCeL.offset;
			p.rows = kRows; p.cols = kCeV; p.ignoreIdx = kNoIgnore;
			if (!_k[kCe].Dispatch(kRows, 1u, 1u, &p, (uint32)sizeof(p))) return _Bad("ce_logits");
			MLCeLogitsBwdParams q{}; q.probsOff = tCeP.offset; q.targetOff = tCeT.offset;
			q.dLogitsOff = tCeDZ.offset; q.rows = kRows; q.cols = kCeV; q.ignoreIdx = kNoIgnore; q.lossScale = 1.0f;
			if (!_k[kCeB].Dispatch(kCeV, kRows, 1u, &q, (uint32)sizeof(q))) return _Bad("ce_logits_bwd");
		}
		// 📐 val_enc — fwd X=freqs,Y=rows · bwd X=rows(행 감산)
		{
			MLValEncParams p{}; p.inOff = tVlIn.offset; p.outOff = tVlOut.offset;
			p.rows = kRows; p.freqs = kVF; p.vBias = 0.0f; p.vScale = 1.0f;
			p.freqMin = 1.0f; p.freqMax = kJudgeFreqMax;
			if (!_k[kVal].Dispatch(kVF, kRows, 1u, &p, (uint32)sizeof(p))) return _Bad("val_enc");
			MLValEncBwdParams q{}; q.inOff = tVlIn.offset; q.dOutOff = tVlDO.offset; q.dInOff = tVlDI.offset;
			q.rows = kRows; q.freqs = kVF; q.vBias = 0.0f; q.vScale = 1.0f;
			q.freqMin = 1.0f; q.freqMax = kJudgeFreqMax;
			if (!_k[kValB].Dispatch(kRows, 1u, 1u, &q, (uint32)sizeof(q))) return _Bad("val_enc_bwd");
		}
		// 👁️ act_topk — fwd X=rows · bwd X=dict,Y=rows
		{
			MLActTopkParams p{}; p.scoreOff = tTpS.offset; p.idsOff = tTpId.offset; p.magOff = tTpMg.offset;
			p.rows = kRows; p.dict = kDict; p.k = kK;
			if (!_k[kTop].Dispatch(kRows, 1u, 1u, &p, (uint32)sizeof(p))) return _Bad("act_topk");
			MLActTopkBwdParams q{}; q.idsOff = tTpId.offset; q.dMagOff = tTpDM.offset; q.dScoreOff = tTpDS.offset;
			q.rows = kRows; q.dict = kDict; q.k = kK;
			if (!_k[kTopB].Dispatch(kDict, kRows, 1u, &q, (uint32)sizeof(q))) return _Bad("act_topk_bwd");
		}
		// 🧲 act_gather — top-k ids 를 그대로 받고, bwd 두 번째 호출로 `add` 분기도 검증한다.
		{
			MLActGatherParams p{}; p.aOff = tGaA.offset; p.bOff = tGaB.offset;
			p.idsOff = tTpId.offset; p.magOff = tGaMg.offset;
			p.rows = kRows; p.dict = kDict; p.k = kK; p.useB = 1u; p.scale = 1.731f;
			if (!_k[kGather].Dispatch(kRows * kK, 1u, 1u, &p, (uint32)sizeof(p))) return _Bad("act_gather");

			MLActGatherBwdParams q{}; q.idsOff = tTpId.offset; q.dMagOff = tGaDM.offset; q.dInOff = tGaDI.offset;
			q.rows = kRows; q.dict = kDict; q.k = kK; q.add = 0u; q.scale = 1.731f;
			if (!_k[kGatherB].Dispatch(kDict, kRows, 1u, &q, (uint32)sizeof(q))) return _Bad("act_gather_bwd");
			q.add = 1u; q.scale = -0.417f;
			if (!_k[kGatherB].Dispatch(kDict, kRows, 1u, &q, (uint32)sizeof(q))) return _Bad("act_gather_bwd(add)");
		}
		// 🔁 residual_swap — 행 하나=스레드 하나. 입력 top-k/recon은 셋업에서 CPU 정본으로 만들었다.
		{
			MLActResidualSwapParams p{};
			p.targetOff = tRsT.offset; p.reconOff = tRsR.offset; p.scoreOff = tRsS.offset; p.tableOff = tRsTab.offset;
			p.idsInOff = tRsId0.offset; p.magInOff = tRsMg0.offset; p.idsOutOff = tRsId1.offset; p.magOutOff = tRsMg1.offset;
			p.rows = kVisR; p.k = kK; p.pixels = kPix; p.dict = kDict; p.eps = 1.0e-6f;
			if (!_k[kResidualSwap].Dispatch(kVisR * 64u, 1u, 1u, &p, (uint32)sizeof(p))) return _Bad("act_residual_swap");
		}
		// 🔧 coeff_sweep — 행마다 64-lane 워크그룹 하나.
		{
			MLActCoeffSweepParams p{};
			p.targetOff = tRsT.offset; p.reconOff = tRsR.offset; p.tableOff = tRsTab.offset;
			p.idsOff = tRsId0.offset; p.magInOff = tRsMg0.offset; p.magOutOff = tCsMg1.offset;
			p.rows = kVisR; p.k = kK; p.pixels = kPix; p.dict = kDict; p.eps = 1.0e-6f;
			if (!_k[kCoeffSweep].Dispatch(kVisR * 64u, 1u, 1u, &p, (uint32)sizeof(p))) return _Bad("act_coeff_sweep");
		}
		// 🧩 vis_recon — fwd X=pixels,Y=rows · mag bwd X=k,Y=rows · ⚠️⚠️ tab bwd **Y=dict**(rows 아님)
		{
			MLVisReconParams p{}; p.idsOff = tViId.offset; p.magOff = tViMg.offset; p.tableOff = tViTab.offset;
			p.outOff = tViOut.offset; p.rows = kVisR; p.k = kK; p.pixels = kPix; p.dict = kDict;
			if (!_k[kVis].Dispatch(kPix, kVisR, 1u, &p, (uint32)sizeof(p))) return _Bad("vis_recon");
			MLVisReconMagBwdParams q{}; q.idsOff = tViId.offset; q.tableOff = tViTab.offset;
			q.dOutOff = tViDO.offset; q.dMagOff = tViDM.offset;
			q.rows = kVisR; q.k = kK; q.pixels = kPix; q.dict = kDict;
			if (!_k[kVisM].Dispatch(kK, kVisR, 1u, &q, (uint32)sizeof(q))) return _Bad("vis_recon_bwd_mag");
			MLVisReconTabBwdParams s{}; s.idsOff = tViId.offset; s.magOff = tViMg.offset;
			s.dOutOff = tViDO.offset; s.dTableOff = tViDT.offset;
			s.rows = kVisR; s.k = kK; s.pixels = kPix; s.dict = kDict;
			// ⚠️⚠️ **Y = `kDict` 다(`kVisR` 아니다)** — 2D 커널 일곱 중 Y 가 rows 가 아닌 **유일한 것**이다.
			//   ★ 음성 대조로 확인했다: `kVisR`(20)로 틀리면 32스레드가 100 을 못 덮어
			//     **「일부 포이즌 — 디스패치 축이 칸을 안 덮었다」로 정확히 잡힌다.**
			if (!_k[kVisT].Dispatch(kPix, kDict, 1u, &s, (uint32)sizeof(s))) return _Bad("vis_recon_bwd_tab");
		}
		// 🧱 patch_embed — fwd X=dim,Y=패치 · ⚠️⚠️ bwd 는 **Y=표의 행**(자리×256)이다(패치가 아니다)
		{
			MLPatchEmbedParams p{}; p.frameOff = tPeFr.offset; p.aOff = tPeSlot.offset;
			p.bOff = tPePos.offset; p.cOff = tPeOut.offset;
			p.frameW = kPeW; p.frameH = kPeH; p.patchK = kPeK; p.dim = kPeD;
			if (!_k[kPE].Dispatch(kPeD, p.Patches(), 1u, &p, (uint32)sizeof(p))) return _Bad("patch_embed");
			// ★ 같은 구조체를 배치만 바꿔 쓴다 — `a = dOut · b = dSlotTable`(`c` 는 안 쓴다).
			MLPatchEmbedParams q{}; q.frameOff = tPeFr.offset; q.aOff = tPeDO.offset;
			q.bOff = tPeDS.offset;
			q.frameW = kPeW; q.frameH = kPeH; q.patchK = kPeK; q.dim = kPeD;
			if (!_k[kPEB].Dispatch(kPeD, q.SlotRows(), 1u, &q, (uint32)sizeof(q))) return _Bad("patch_embed_bwd");
		}
		// ➖ sub — 1D. ★ 길이만 안다(원소별이라 모양을 몰라도 된다).
		{
			MLSubParams p{}; p.aOff = tSbA.offset; p.bOff = tSbB.offset; p.outOff = tSbOut.offset;
			p.count = kSubN;
			if (!_k[kSub].Dispatch(kSubN, 1u, 1u, &p, (uint32)sizeof(p))) return _Bad("sub");
		}
		// ⭐ act_topk_abs — `act_topk` 과 같은 축(X=rows)
		{
			MLActTopkParams p{}; p.scoreOff = tAbS.offset; p.idsOff = tAbId.offset; p.magOff = tAbMg.offset;
			p.rows = kRows; p.dict = kDict; p.k = kK;
			if (!_k[kTopA].Dispatch(kRows, 1u, 1u, &p, (uint32)sizeof(p))) return _Bad("act_topk_abs");
		}
		// 🌐 foot_recon — fwd X=pixel,Y=frame*patch · 나머지는 각 출력 모양 그대로.
		{
			MLFootReconParams p{}; p.idsOff=tFtId.offset; p.magOff=tFtMg.offset; p.codeOff=tFtCode.offset;
			p.xOff=tFtX.offset; p.yOff=tFtY.offset; p.outOff=tFtOut.offset;
			p.frames=kFtF; p.k=kFtK; p.grid=kFtG; p.pixels=kFtP; p.dict=kDict; p.rank=kFtR; p.span=kFtS;
			if (!_k[kFoot].Dispatch(kFtP, kFtF*kFtPatch, 1u, &p, (uint32)sizeof(p))) return _Bad("foot_recon");
			MLFootReconMagBwdParams m{}; m.idsOff=tFtId.offset; m.codeOff=tFtCode.offset; m.xOff=tFtX.offset;
			m.yOff=tFtY.offset; m.dOutOff=tFtDO.offset; m.dMagOff=tFtDM.offset;
			m.frames=kFtF; m.k=kFtK; m.grid=kFtG; m.pixels=kFtP; m.dict=kDict; m.rank=kFtR; m.span=kFtS;
			if (!_k[kFootM].Dispatch(kFtK, kFtF, 1u, &m, (uint32)sizeof(m))) return _Bad("foot_recon_bwd_mag");
			MLFootReconCodeBwdParams c{}; c.idsOff=tFtId.offset; c.magOff=tFtMg.offset; c.xOff=tFtX.offset;
			c.yOff=tFtY.offset; c.dOutOff=tFtDO.offset; c.dCodeOff=tFtDC.offset;
			c.frames=kFtF; c.k=kFtK; c.grid=kFtG; c.pixels=kFtP; c.dict=kDict; c.rank=kFtR; c.span=kFtS;
			if (!_k[kFootC].Dispatch(kFtP, kDict, 1u, &c, (uint32)sizeof(c))) return _Bad("foot_recon_bwd_code");
			MLFootReconSpaceBwdParams s{}; s.idsOff=tFtId.offset; s.magOff=tFtMg.offset; s.codeOff=tFtCode.offset;
			s.xOff=tFtX.offset; s.yOff=tFtY.offset; s.dOutOff=tFtDO.offset; s.dXOff=tFtDX.offset; s.dYOff=tFtDY.offset;
			s.frames=kFtF; s.k=kFtK; s.grid=kFtG; s.pixels=kFtP; s.dict=kDict; s.rank=kFtR; s.span=kFtS;
			if (!_k[kFootS].Dispatch(kFtS, kDict*kFtR, 1u, &s, (uint32)sizeof(s))) return _Bad("foot_recon_bwd_space");
		}
		LogA("[mlt] ① 디스패치 29회 기록 — ⚠️ 회수는 **다음 프레임**이다(같은 프레임엔 전부 포이즌이다)\n");
		return true;
	}

	static bool _Bad(const char* n) { LogA("[mlt] ① 디스패치 실패: %s\n", n); return false; }

	// ══════════════════════════════════════════════════════════════════
	// 📊 한 텐서를 회수해 CPU 레퍼런스와 견준다. ⚠️ 방어 순서가 뜻이 있다.
	// ══════════════════════════════════════════════════════════════════
	static int _Cmp(const char* name, const MLTensor& t, const float* want, const char* note, bool exact = false)
	{
		++_judged;
		const uint32 n = t.Count();
		// ⚠️ `n == 0` 은 **판정불가**다 — 아레나가 넘치면 `Alloc` 이 무효 텐서를 조용히 준다.
		if (n == 0u) { LogA("[mlt]   ⚠️ %-20s 판정불가 — 텐서가 비었다(할당 실패)\n", name); return 1; }

		Bytes got;
		if (!_ar.Read(t, got) || got.GetSize() != (uint64)n * sizeof(float))
		{ LogA("[mlt]   ⛔ %-20s 회수 실패\n", name); return 1; }
		const float* g = (const float*)got.GetData();

		// ㉤ **전부 포이즌 = 프레임이 안 넘어간 것**(축 문제가 아니다) — 이 진단을 **먼저** 찍는다.
		if (_AllPoison(g, n))
		{ LogA("[mlt]   ⛔ %-20s 전부 포이즌 — **프레임이 안 넘어갔다**(축 문제가 아니다)\n", name); return 1; }
		// ㉠+㉡ 일부만 포이즌 = **디스패치 축이 칸을 안 덮었다**
		if (_AnyPoison(g, n))
		{ LogA("[mlt]   ⛔ %-20s 일부 포이즌 — **디스패치 축이 칸을 안 덮었다**\n", name); return 1; }
		// ㉢ NaN/Inf 는 `MLMaxAbsErr` 이 **못 센다** ⇒ 여기서 잡는다
		if (!_AllFinite(g, n))
		{ LogA("[mlt]   ⛔ %-20s GPU 출력에 NaN/Inf — (오차 지표는 이것을 못 본다)\n", name); return 1; }
		if (!_AllFinite(want, n))
		{ LogA("[mlt]   ⚠️ %-20s 판정불가 — CPU 레퍼런스에 NaN/Inf\n", name); return 1; }
		// ㉣ 입력이 안 올라갔으면 **양쪽이 같은 쓰레기**를 낸다 ⇒ 크기 상한으로 막는다
		const float mag = MLMaxAbs(want, n);
		if (mag > 1.0e6f)
		{ LogA("[mlt]   ⚠️ %-20s 판정불가 — |want|=%.2e 가 비정상(입력에 포이즌?)\n", name, (double)mag); return 1; }

		const float err = MLMaxAbsErr(g, want, n);
		if (exact)
		{
			// `act_topk` 의 `ids` — 정수라 **정확일치**를 요구한다. ⚠️ 한 칸이라도 어긋나면 그 뒤
			//   `act_topk_bwd`/`vis_recon*` 판정이 통째로 거짓말이 되므로 여기가 먼저다.
			const bool ok = (err == 0.0f);
			LogA("[mlt]   %s %-20s 정확일치 %s (n=%u)  %s\n", ok ? "✅" : "⛔", name,
				ok ? "0" : "불일치", n, note);
			return ok ? 0 : 1;
		}
		// ⚠️ **정규화 절대오차** — `MLMaxRelErr` 은 0 을 지나는 출력에서 멀쩡한 커널을 떨어뜨린다.
		if (mag < 1.0e-6f)
		{ LogA("[mlt]   ⚠️ %-20s 판정불가 — |want|=%.2e (견줄 것이 없다)\n", name, (double)mag); return 1; }
		const float rel = err / mag;
		const bool ok = (rel < kTol);
		LogA("[mlt]   %s %-20s GPUvsCPU %.2e (|want|=%.2e · n=%u)  %s\n",
			ok ? "✅" : "⛔", name, (double)rel, (double)mag, n, note);
		return ok ? 0 : 1;
	}

	static int _CheckCanary(const char* name, const MLTensor& t)
	{
		Bytes got;
		if (!_ar.Read(t, got)) return 0;
		const float* g = (const float*)got.GetData();
		if (_AllPoison(g, t.Count())) return 0;
		LogA("[mlt]   ⛔ 카나리 %s 가 깨졌다 — 어떤 커널이 **남의 자리**를 덮었다\n", name);
		return 1;
	}

	// ══════════════════════════════════════════════════════════════════
	// ⚖️ 판정 — 다음 프레임. CPU 레퍼런스는 **업로드한 그 호스트 거울**을 본다(비트까지 같다).
	// ══════════════════════════════════════════════════════════════════
	static void _Judge()
	{
		LogA("[mlt] ── 판정 ① · GPU vs CPU (정규화 절대오차 < %.0e) ──\n", (double)kTol);
		_fail = 0; _judged = 0;
		Array<float> w;   // CPU 레퍼런스 산출 버퍼

		// 📏 rmsnorm
		{
			Array<float> rstd; _Res(rstd, kRows); _Res(w, kRows * kCols);
			MLRmsNormCpu(_P(tRmIn), _P(tRmG), w.Data(), rstd.Data(), kRows, kCols, kNormEps);
			_fail += _Cmp("rmsnorm.y", tRmOut, w.Data(), "");
			_fail += _Cmp("rmsnorm.rstd", tRmRstd, rstd.Data(), "");
			Array<float> di; _Res(di, kRows * kCols);
			MLRmsNormBwdCpu(_P(tRmIn), _P(tRmG), rstd.Data(), _P(tRmDO), di.Data(), kRows, kCols);
			_fail += _Cmp("rmsnorm.dIn", tRmDI, di.Data(), "");
			Array<float> dg; _Res(dg, kCols);
			MLRmsNormGainBwdCpu(_P(tRmIn), rstd.Data(), _P(tRmDO), dg.Data(), kRows, kCols);
			_fail += _Cmp("rmsnorm.dGain", tRmDG, dg.Data(), "⚠️ X=cols 축");
		}
		// 🌀 rope (fwd · bwd = 같은 spv 의 dirSign=-1)
		{
			_Res(w, kRpR * kRpD);
			MLRopeCpu(_P(tRpIn), _P(tRpPos), w.Data(), kRpR, kRpD, 0u, kRopeTheta, 1.0f);
			_fail += _Cmp("rope.y", tRpOut, w.Data(), "mode=1D");
			Array<float> di; _Res(di, kRpR * kRpD);
			MLRopeBwdCpu(_P(tRpDO), _P(tRpPos), di.Data(), kRpR, kRpD, 0u, kRopeTheta);
			_fail += _Cmp("rope.dIn", tRpDI, di.Data(), "같은 spv · dirSign=-1");
		}
		// 🎯 attn_softmax (+ 기존 softmax_bwd)
		{
			_Res(w, kT * kT);
			MLAttnSoftmaxCpu(_P(tAtIn), w.Data(), kT, kT, 0u, 1.0f);
			_fail += _Cmp("attn_softmax.p", tAtOut, w.Data(), "causalOff=0");
			Array<float> di; _Res(di, kT * kT);
			MLSoftmaxBwdCpu(w.Data(), _P(tAtDO), di.Data(), kT, kT, 1.0f);
			_fail += _Cmp("softmax_bwd.dIn", tAtDI, di.Data(), "기존 커널 · scale 을 fwd 와 같게");
		}
		// 🚪 swiglu
		{
			_Res(w, kSw);
			MLSwigluCpu(_P(tSwA), _P(tSwB), w.Data(), kSw);
			_fail += _Cmp("swiglu.y", tSwOut, w.Data(), "");
			Array<float> da, db; _Res(da, kSw); _Res(db, kSw);
			MLSwigluBwdCpu(_P(tSwA), _P(tSwB), _P(tSwDO), da.Data(), db.Data(), kSw);
			_fail += _Cmp("swiglu.dA", tSwDA, da.Data(), "");
			_fail += _Cmp("swiglu.dB", tSwDB, db.Data(), "");
		}
		// 📉 ce_logits
		{
			Array<float> pr, ls; _Res(pr, kRows * kCeV); _Res(ls, kRows);
			MLCeLogitsCpu(_P(tCeZ), _P(tCeT), pr.Data(), ls.Data(), kRows, kCeV, kNoIgnore);
			_fail += _Cmp("ce_logits.probs", tCeP, pr.Data(), "");
			_fail += _Cmp("ce_logits.loss", tCeL, ls.Data(), "");
			Array<float> dz; _Res(dz, kRows * kCeV);
			MLCeLogitsBwdCpu(pr.Data(), _P(tCeT), dz.Data(), kRows, kCeV, kNoIgnore, 1.0f);
			_fail += _Cmp("ce_logits.dLogits", tCeDZ, dz.Data(), "ignoreIdx·lossScale 양쪽 같게");
		}
		// 📐 val_enc
		{
			_Res(w, kRows * kVF * 2u);
			MLValEncCpu(_P(tVlIn), w.Data(), kRows, kVF, 0.0f, 1.0f, 1.0f, kJudgeFreqMax);
			_fail += _Cmp("val_enc.phi", tVlOut, w.Data(), "⚠️ freqMax=8(판정용 · ②는 64)");
			Array<float> dv; _Res(dv, kRows);
			MLValEncBwdCpu(_P(tVlIn), _P(tVlDO), dv.Data(), kRows, kVF, 0.0f, 1.0f, 1.0f, kJudgeFreqMax);
			_fail += _Cmp("val_enc.dIn", tVlDI, dv.Data(), "계수는 인자(러닝 통계)");
		}
		// 👁️ act_topk — ⚠️ `ids` 를 **먼저** 정확일치로 본다
		{
			Array<float> ids, mg; _Res(ids, kRows * kK); _Res(mg, kRows * kK);
			MLActTopkCpu(_P(tTpS), ids.Data(), mg.Data(), kRows, kDict, kK);
			_fail += _Cmp("act_topk.ids", tTpId, ids.Data(), "정수 — 여기가 어긋나면 뒤가 다 거짓말", true);
			_fail += _Cmp("act_topk.mag", tTpMg, mg.Data(), "점수의 비트 복사");
			Array<float> ds; _Res(ds, kRows * kDict);
			MLActTopkBwdCpu(ids.Data(), _P(tTpDM), ds.Data(), kRows, kDict, kK);
			_fail += _Cmp("act_topk.dScore", tTpDS, ds.Data(), "");
		}
		// 🧲 act_gather — fwd 의 A+B와 bwd 의 덮어쓰기→누산을 각각 CPU와 견준다.
		{
			Array<float> ids, mg, di; _Res(ids, kRows * kK); _Res(mg, kRows * kK); _Res(di, kRows * kDict);
			MLActTopkCpu(_P(tTpS), ids.Data(), mg.Data(), kRows, kDict, kK);
			MLActGatherCpu(_P(tGaA), _P(tGaB), ids.Data(), mg.Data(), kRows, kDict, kK, true, 1.731f);
			_fail += _Cmp("act_gather.mag", tGaMg, mg.Data(), "ids 고정 · A+B · scale");
			MLActGatherBwdCpu(ids.Data(), _P(tGaDM), di.Data(), kRows, kDict, kK, 1.731f, false);
			MLActGatherBwdCpu(ids.Data(), _P(tGaDM), di.Data(), kRows, kDict, kK, -0.417f, true);
			_fail += _Cmp("act_gather.dIn", tGaDI, di.Data(), "덮어쓰기 뒤 add 누산");
		}
		// 🔁 residual_swap — ids는 정확일치, mag는 `score[id]` 복사라 수치일치. 교체 분기도 살아 있어야 한다.
		{
			Array<float> ids, mg; _Res(ids, kVisR * kK); _Res(mg, kVisR * kK);
			MLActResidualSwapCpu(_P(tRsT), _P(tRsR), _P(tRsS), _P(tRsTab), _P(tRsId0), _P(tRsMg0),
				ids.Data(), mg.Data(), kVisR, kK, kPix, kDict, 1.0e-6f);
			_fail += _Cmp("residual_swap.ids", tRsId1, ids.Data(), "정수 · 교체/no-op", true);
			_fail += _Cmp("residual_swap.mag", tRsMg1, mg.Data(), "최종 mag=score[id]");
			uint32 changed = 0u;
			for (uint32 i = 0; i < kVisR * kK; ++i) if ((uint32)ids[i] != (uint32)_P(tRsId0)[i]) ++changed;
			LogA("[mlt]   ⓘ residual_swap — 바뀐 슬롯 **%u**/%u (0이면 교체 분기를 못 덮었다)\n",
				changed, kVisR * kK);
			if (changed == 0u) { LogA("[mlt]   ⛔ residual_swap 교체 분기 미도달\n"); ++_fail; }
		}
		// 🔧 coeff_sweep — mag 수치와 실제 SSE 개선을 함께 본다. ids는 출력 자체가 없어 바뀔 길이 없다.
		{
			Array<float> mg, rec; _Res(mg, kVisR * kK); _Res(rec, kVisR * kPix);
			MLActCoeffSweepCpu(_P(tRsT), _P(tRsR), _P(tRsTab), _P(tRsId0), _P(tRsMg0),
				mg.Data(), kVisR, kK, kPix, kDict, 1.0e-6f);
			_fail += _Cmp("coeff_sweep.mag", tCsMg1, mg.Data(), "ids 고정 · 좌표 오름차순 1회");
			MLVisReconCpu(_P(tRsId0), mg.Data(), _P(tRsTab), rec.Data(), kVisR, kK, kPix, kDict);
			uint32 changed = 0u, improved = 0u;
			for (uint32 row = 0; row < kVisR; ++row)
			{
				double s0 = 0.0, s1 = 0.0;
				for (uint32 j = 0; j < kK; ++j) if (mg[row * kK + j] != _P(tRsMg0)[row * kK + j]) ++changed;
				for (uint32 px = 0; px < kPix; ++px)
				{
					const float y = _P(tRsT)[row * kPix + px];
					const float d0 = y - _P(tRsR)[row * kPix + px], d1 = y - rec[row * kPix + px];
					s0 += (double)d0 * d0; s1 += (double)d1 * d1;
				}
				if (s1 < s0) ++improved;
			}
			LogA("[mlt]   ⓘ coeff_sweep — 바뀐 계수 **%u**/%u · SSE 엄격 개선 **%u**/%u\n",
				changed, kVisR * kK, improved, kVisR);
			if (changed == 0u || improved == 0u) { LogA("[mlt]   ⛔ coeff_sweep 갱신/개선 분기 미도달\n"); ++_fail; }
		}
		// 🧩 vis_recon
		{
			_Res(w, kVisR * kPix);
			MLVisReconCpu(_P(tViId), _P(tViMg), _P(tViTab), w.Data(), kVisR, kK, kPix, kDict);
			_fail += _Cmp("vis_recon.y", tViOut, w.Data(), "");
			Array<float> dm; _Res(dm, kVisR * kK);
			MLVisReconMagBwdCpu(_P(tViId), _P(tViTab), _P(tViDO), dm.Data(), kVisR, kK, kPix, kDict);
			_fail += _Cmp("vis_recon.dMag", tViDM, dm.Data(), "");
			Array<float> dt; _Res(dt, kDict * kPix);
			MLVisReconTabBwdCpu(_P(tViId), _P(tViMg), _P(tViDO), dt.Data(), kVisR, kK, kPix, kDict);
			_fail += _Cmp("vis_recon.dTable", tViDT, dt.Data(), "⚠️⚠️ Y=dict(rows 아님)");
		}

		// 🧱 patch_embed
		{
			_Res(w, kPeP * kPeD);
			MLPatchEmbedCpu(_P(tPeFr), _P(tPeSlot), _P(tPePos), w.Data(), kPeW, kPeH, kPeK, kPeD);
			_fail += _Cmp("patch_embed.y", tPeOut, w.Data(), "바이트 5종 + 300 한 칸(접기 분기)");
			Array<float> dsl; _Res(dsl, kPeSR * kPeD);
			MLPatchEmbedBwdCpu(_P(tPeFr), _P(tPeDO), dsl.Data(), kPeW, kPeH, kPeK, kPeD);
			// ⚠️⚠️ 여기가 **Y=1024** 다 — 축을 패치(30)로 잘못 주면 나머지가 포이즌으로 남아 정확히 잡힌다.
			_fail += _Cmp("patch_embed.dSlot", tPeDS, dsl.Data(), "⚠️⚠️ Y=표의 행 1024(패치 아님)");
		}
		// ⭐ act_topk_abs — ⚠️ `ids` 를 **먼저 정확일치**로 본다(선택이 어긋나면 뒤가 다 거짓말)
		{
			Array<float> ids, mg; _Res(ids, kRows * kK); _Res(mg, kRows * kK);
			MLActTopkAbsCpu(_P(tAbS), ids.Data(), mg.Data(), kRows, kDict, kK);
			_fail += _Cmp("act_topk_abs.ids", tAbId, ids.Data(), "정수 — |z| 로 고른다", true);
			_fail += _Cmp("act_topk_abs.mag", tAbMg, mg.Data(), "부호 있는 점수의 비트 복사");
			// ⓘ 이 커널이 `act_topk` 과 **실제로 다른가** — 음수 계수가 나오는지 센다
			uint32 neg = 0, diff = 0;
			Array<float> ids0, mg0; _Res(ids0, kRows * kK); _Res(mg0, kRows * kK);
			MLActTopkCpu(_P(tAbS), ids0.Data(), mg0.Data(), kRows, kDict, kK);
			for (uint32 i = 0; i < kRows * kK; ++i)
			{
				if (mg[i] < 0.0f) ++neg;
				if ((uint32)ids[i] != (uint32)ids0[i]) ++diff;
			}
			LogA("[mlt]   ⓘ act_topk_abs vs act_topk — 음수 계수 **%u**/%u · 선택이 다른 칸 **%u**/%u"
			     " (0 이면 두 커널이 같은 것이다)\n", neg, kRows * kK, diff, kRows * kK);
		}
		// ➖ sub — ★ 뺄셈뿐이라 **정확일치**를 요구한다(초월함수가 없다)
		{
			_Res(w, kSubN);
			MLSubCpu(_P(tSbA), _P(tSbB), w.Data(), kSubN);
			_fail += _Cmp("sub.out", tSbOut, w.Data(), "뺄셈뿐 — 정확일치", true);
		}
		// 🌐 이동 가능한 전역 발자국
		{
			_Res(w, kFtF*kFtPatch*kFtP);
			MLFootReconCpu(_P(tFtId),_P(tFtMg),_P(tFtCode),_P(tFtX),_P(tFtY),w.Data(),kFtF,kFtK,kFtG,kFtP,kDict,kFtR,kFtS);
			_fail += _Cmp("foot_recon.y", tFtOut, w.Data(), "candidate=anchor*dict+id");
			Array<float> dm,dc,dx,dy; _Res(dm,kFtF*kFtK); _Res(dc,kDict*kFtP); _Res(dx,kDict*kFtR*kFtS); _Res(dy,kDict*kFtR*kFtS);
			MLFootReconMagBwdCpu(_P(tFtId),_P(tFtCode),_P(tFtX),_P(tFtY),_P(tFtDO),dm.Data(),kFtF,kFtK,kFtG,kFtP,kDict,kFtR,kFtS);
			MLFootReconCodeBwdCpu(_P(tFtId),_P(tFtMg),_P(tFtX),_P(tFtY),_P(tFtDO),dc.Data(),kFtF,kFtK,kFtG,kFtP,kDict,kFtR,kFtS);
			MLFootReconSpaceBwdCpu(_P(tFtId),_P(tFtMg),_P(tFtCode),_P(tFtX),_P(tFtY),_P(tFtDO),dx.Data(),dy.Data(),kFtF,kFtK,kFtG,kFtP,kDict,kFtR,kFtS);
			_fail += _Cmp("foot_recon.dMag",tFtDM,dm.Data(),"선택 고정 조건부");
			_fail += _Cmp("foot_recon.dCode",tFtDC,dc.Data(),"Y=dict");
			_fail += _Cmp("foot_recon.dX",tFtDX,dx.Data(),"X=span,Y=dict*rank");
			_fail += _Cmp("foot_recon.dY",tFtDY,dy.Data(),"X=span,Y=dict*rank");
		}

		// 카나리 — 남의 자리를 덮은 커널이 있나
		_fail += _CheckCanary("A", cA); _fail += _CheckCanary("B", cB);
		_fail += _CheckCanary("C", cC); _fail += _CheckCanary("D", cD);
		_fail += _CheckCanary("E", cE); _fail += _CheckCanary("F", cF);
		_fail += _CheckCanary("G", cG); _fail += _CheckCanary("H", cH);
		_fail += _CheckCanary("I", cI); _fail += _CheckCanary("J", cJ);
		_fail += _CheckCanary("K", cK); _fail += _CheckCanary("L", cL); _fail += _CheckCanary("M", cM);
		_fail += _CheckCanary("N", cN); _fail += _CheckCanary("O", cO);

		// ══════════════════════════════════════════════════════════════
		// ⚠️⚠️ **요약이 없으면 「판정이 안 돌았다」로 읽는 규약이다** — 창이 최소화되면 Tick 자체가
		//   안 돌 수 있어서, 「찍힌 줄이 없다」를 통과로 오독하면 안 된다.
		// ══════════════════════════════════════════════════════════════
		// ⚠️ 카나리는 **`_judged` 를 올리지 않는다**(견줄 레퍼런스가 없다) ⇒ *"N개에 포함"* 으로 적으면
		//   그 자리가 곧 오독이다. **따로** 적는다.
		if (_fail == 0) LogA("[mlt] ✅ 판정 ① — %d개 전부 통과 (＋ 카나리 15칸 무사)\n", _judged);
		else            LogA("[mlt] ⛔ 판정 ① — %d개 중 실패 %d건 (위 줄을 읽어라 · 넘기지 마라)\n", _judged, _fail);

		// ⚠️ **덮지 못한 분기를 적는다** — 「전부 통과」가 *"셰이더가 CPU 와 같다"* 로 읽히면 오독이다.
		LogA("[mlt] ⚠️ ① 이 안 덮은 분기: ce_logits 의 무효 표적 · act_topk 의 k>dict 센티널 ·\n");
		LogA("[mlt]    vis_recon 의 v>=dict 건너뛰기 · rope 의 2D(mode=1) · attn 의 causalOff>0\n");
		LogA("[mlt]    ⭐ patch_embed 의 `b>255` 접기는 **덮었다**(프레임에 300 을 한 칸 넣는다)\n");
	}

	// ⚠️ `Reset(n)` 은 **0 으로 채운다**(값초기화) — CPU 레퍼런스 출력 버퍼는 그것으로 충분하다.
	static void _Res(Array<float>& v, uint32 n) { v.Reset(0); for (uint32 i = 0; i < n; ++i) v.Add(0.0f); }
};
