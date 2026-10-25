// mltp2.cw — 👁️ **P2 · 프레임 → 활성 → 프레임.** ⚠️⚠️ **워밍업이다 — 여기서 끝내지 않는다.**
//
// ══════════════════════════════════════════════════════════════════════════════
// 📋 **P2 등록문** — ⚠️ 재기 전에 적는다. 관문의 정본은 `MLT.md` 의 P2 절이다.
// ══════════════════════════════════════════════════════════════════════════════
//
// ★ **이 단계가 무엇이고 무엇이 아닌가**
//
//   `MLT.md` 가 못 박았다: *"이 단계는 인코더를 **띄우는** 것이고 **경험 학습은 P3 에서 일어난다.**
//   여기서 얼려 두고 넘어가면 인코딩이 **정적 압축에 머문다.**"*
//   ⇒ ★ P2 의 성공은 «잘 압축했다» 가 아니라 **«붕괴하지 않고 사전이 실제로 쓰인다»** 다.
//   ⚠️ 그래서 관문 넷 중 셋(㉠㉡㉣)이 **붕괴 검사**이고 하나(㉢)만 내용을 본다.
//
// ══════════════════════════════════════════════════════════════════════════════
// ① 파이프라인 — ⭐ **새 커널 3장**(그리고 그 셋이 이미 저장소에 있다)
// ══════════════════════════════════════════════════════════════════════════════
//   ```
//   프레임(64² RGB332 · 1픽셀 1바이트)
//     → patch_embed   [패치 64, D]     ← ⭐ **바이트를 256-원핫으로 룩업**한다(비트필드라 순서가
//                                          의미 없으므로 스칼라로 넣으면 안 된다 — 그 커널이 그 목적이다)
//     → gemm(사전 Wd [D, N])  → score [64, N]
//     → act_topk      → (ids, mag) [64, k]
//     → vis_recon(코드북 [N, pixels]) → recon [64, pixels]
//     → sub(recon, target) → dRecon      ← ⭐ **MSE 의 기울기가 곧 `sub`** 다
//     → vis_recon_bwd_mag / _bwd_tab → act_topk_bwd → gemm(bwd) → patch_embed_bwd
//   ```
//   ⚠️ **판정 ①② 를 새로 통과시켜야 하는 커널은 셋**이다: `patch_embed` · `patch_embed_bwd` · `sub`.
//     ★ `act_topk` · `vis_recon` 계열 다섯은 **이미 통과**했다(판정 ① 22/22 에 들어 있다).
//     ⚠️ 그 셋을 통과시키기 **전에** 인코더를 돌리지 않는다 — 조용한 버그가 전부
//     *"컴파일되고 안 죽고 숫자만 틀린다"* 였고 **학습 곡선으로는 못 본다.**
//     ★ **통과했다**(걸음 1): 판정 ② 는 `patch_embed` 의 `dSlot`·**`dPos`**(커널이 없다는 주장
//       자체)와 `sub` 의 `dA`/`dB`, 판정 ① 은 셋 다 **오차 0** ⇒ ② 16/16 · ① 25/25.
//     ★ **인코더도 섰다**(걸음 2 · `mltp2enc.cw` + `mltp2fit.cw`): 조립 검사(비전)에서
//       고정 프레임 하나가 **0.15343 → 0.00007**(팔 B lr=0 은 비트 평평).
//
//   **재구성 표적** — ⚠️ 결정 하나를 명시한다
//     `pixels = 8×8 패치 × RGB 3채널 = 192`. RGB332 바이트를 `(r/7, g/7, b/3) ∈ [0,1]³` 로 편다.
//     ⚠️⚠️ **표적도 RGB332 를 거친 값**이다(원본 Bitmap 이 아니다) — 양자화 오차를 **대조군과
//     학습이 똑같이** 겪어야 비교가 성립한다.
//   **손실 = MSE** — ⚠️ 문서의 「MSE 금지」와 어긋나 보이므로 근거를 적는다:
//     그 금지는 **「세계의 다음 값」 출력**에 대한 것이고 근거가 **다봉**이었다(같은 상태에서 갈 수
//     있는 다음이 여럿). **재구성은 다봉이 아니다** — 그 프레임은 확정이다.
//     ★ 그리고 `vis_recon` 이 연속 출력이고 그 짝 bwd 둘이 이미 판정을 통과했다.
//     ⚠️ 이 예외를 P3 로 **전파하지 않는다**(다음-활성 예측은 다시 다봉이다).
//
// ══════════════════════════════════════════════════════════════════════════════
// ② A단계 — **대조군 둘의 MSE 를 정확히 계산**한다(손계산이 아니라 정확 계산)
// ══════════════════════════════════════════════════════════════════════════════
//   세계가 결정적이므로 대조군의 손실은 **어림이 아니라 정확값**으로 낼 수 있다:
//   ```
//   대조군 A  「전역 상수」  — 늘 전체 평균색을 낸다        ⇒ MSE = 전체 분산
//   대조군 B  「패치 상수」  — 패치마다 그 패치의 평균색     ⇒ MSE = 패치 안 분산
//   ```
//   ★ **B 가 A 보다 훨씬 낮으면 「패치 안 구조」가 거의 없다는 뜻**이고, 그러면 관문 ㉠ 의 문턱을
//     A 가 아니라 **B** 로 잡아야 한다 — A 만 넘는 것은 「패치 평균만 배웠다」와 구별되지 않는다.
//   ⚠️ 그 판단을 **A단계 결과를 보고** 하되, **어느 쪽을 문턱으로 쓸지는 지금 규칙으로 적는다**:
//     `MSE_B < 0.5 · MSE_A` ⇒ 문턱은 **B**. 아니면 문턱은 **A**.
//     ★ 그러면 결과를 보고 문턱을 고르는 것이 아니라 **미리 정한 규칙이 고르는** 것이다.
//   **A단계 관문**
//     ㉠ 프레임에 **바이트 0 이 없다**(세계 규약 · 회차 0 이 이미 봤지만 이 파이프에서 다시 본다)
//     ㉡ 잉크 비율이 **[8%, 60%]** 안(회차 0 의 그 대역 — 프레임이 안 비었나)
//     ㉢ `MSE_B < MSE_A`(패치 상수가 전역 상수보다 낫다 — 아니면 배관이 틀렸다)
//     ㉣ **팔레트 사용 분포** — 실제로 나타나는 바이트 값의 개수. ⚠️ 사전 사용률 ㉡ 의 **상한 감각**이다
//        (바이트 종류가 20개면 사전 512개가 다 쓰일 이유가 없다 — 그 사실을 미리 안다).
//     ㉤ ⭐ **사전이 필요한 상한을 센다** — **나타난 서로 다른 8×8 패치의 개수**.
//        ★ 이것이 `N`(사전 크기)의 정직한 근거다: 서로 다른 패치가 `U` 종류면 `N > U` 는
//          **원리적으로 낭비**이고, `N ≪ U` 는 **우리가 고정 특징 집합을 만든 것**이다
//          (`mltconcept.md` 의 ㈀ 경고 — *"`k` 가 작으면 우리가 비계를 만든 것"*).
//        ⇒ **등록**: `N` 의 스윕 점을 `U` 로부터 정한다 — `{U/8, U/2, U}` 를 반올림해 쓰고,
//          시작값은 **`U/2`**. ⚠️ 절대수를 미리 박지 않는 이유가 그것이다.
//        ⚠️ `U` 는 **표본에 달렸다**(프레임을 더 보면 는다) ⇒ A단계가 **프레임 수와 함께** 적는다.
//
// ══════════════════════════════════════════════════════════════════════════════
// ③ 판정 라운드의 관문(등록만 — 이번 회차는 A단계까지다)
// ══════════════════════════════════════════════════════════════════════════════
//   ㉠ **재구성** — `MSE_학습 < 0.5 · MSE_문턱`(위 규칙이 고른 대조군) · 부호검정 10/12
//   ㉡ ★ **사전 사용률** — `N` 중 몇 개가 「의미 있게」 쓰이나. 정의: 시험 프레임 전체에서
//      `Σ mag > 0.01 · 최대` 인 유닛의 개수. ⚠️ **문턱은 A단계 ㉣ 를 보고 정한다**(바이트 종류 수의
//      함수여야 한다 — 절대수를 미리 박으면 뜻이 없다). ★ 그 규칙을 A단계 뒤에 **등록해서** 쓴다.
//   ㉢ **활성이 물체를 가르나** — 같은 도형이 다른 자리·크기에서 **같은 유닛**을 켜나.
//      ⚠️ 이것이 P2 의 유일한 「내용」 관문이고 **가장 짜기 어렵다** ⇒ 별 회차로 등록한다.
//      ⚠️⚠️ **그리고 색 대조군이 필수다**(A단계가 그 이유를 냈다): 팔레트가 **5색**인데 도형이
//        **14개**다 ⇒ 색이 도형을 결정하진 않지만(2.8:1) **큰 단서**다.
//        ⇒ 「같은 유닛을 켠다」가 **색만 가른 것**일 수 있다. ⭐ 그래서 짝을 둘로 둔다:
//        ```
//        ㈀ 같은 (kind, col) · 다른 자리·크기   ⇒ 같은 유닛을 켜야 한다      (표제)
//        ㈁ 다른 kind · **같은 col**            ⇒ 켜는 유닛이 **달라야** 한다  (색 대조군)
//        ```
//        ⚠️ ㈁ 가 ㈀ 와 같으면 그것은 **모양이 아니라 색을 가른 것**이고 ⇒ **판정불가**다.
//   ㉣ `k`·`N` 스윕 봉우리 — 손잡이 회차(⚠️ 「크기로 밀기」와 가르려면 **봉우리**여야 한다).
//
// ⚠️ **이번 회차(19)는 A단계까지다.** 커널 판정 → 인코더 → 라운드가 그 뒤다.

using namespace PE;

class MLTP2
{
public:
	static constexpr uint32 kSide   = 64u;                 // 프레임 한 변(세계 규약)
	static constexpr uint32 kPatch  = 8u;                  // 패치 한 변
	static constexpr uint32 kGrid   = kSide / kPatch;      // 8
	static constexpr uint32 kPatches = kGrid * kGrid;      // 64
	static constexpr uint32 kPix    = kPatch * kPatch * 3u; // 192 (RGB)

	// ══════════════════════════════════════════════════════════════════
	// 🚪 **A단계** — 프레임 통계와 대조군 둘의 MSE **정확값**. (CPU 만)
	// ══════════════════════════════════════════════════════════════════
	static void RunBaselines()
	{
		LogA("[mlt] ── 👁️ **P2 A단계** · 프레임 통계와 대조군 둘의 MSE (씨앗 %u~%u · %u 프레임) ──\n",
			kSeed0, kSeed0 + kSeeds - 1u, kSeeds * kFrames);

		double sum[3] = { 0.0, 0.0, 0.0 }, sqr[3] = { 0.0, 0.0, 0.0 };
		double patchSqr = 0.0;                 // 패치-상수 대조군의 잔차²
		uint64 nPix = 0ull, nInk = 0ull, nZero = 0ull;
		uint32 seen[256] = { 0u };
		// ⭐ **서로 다른 8×8 패치를 센다**(㉤) — 해시 집합(선형 탐사).
		//   ⚠️ 64바이트를 64비트 해시로 접으므로 **충돌이 과소 계수**를 만든다 ⇒ 슬롯을 넉넉히 두고
		//     충돌 수를 따로 세서 로그에 남긴다(조용히 틀리지 않게).
		Array<uint64> slot; slot.Reset(0);
		for (uint32 i = 0; i < kSlots; ++i) slot.Add(0ull);
		uint32 uniq = 0u, probeMax = 0u;

		ImageFormat::Bitmap bmp;
		Bytes packed;
		for (uint32 s = 0; s < kSeeds; ++s)
		{
			MLTWorld w;
			w.Reset(kSeed0 + s, 0u, MLTWorldCfg::kHoldMid, MLTWorldCfg::kAutoFew);
			for (uint32 f = 0; f < kFrames; ++f)
			{
				w.Step();
				if (!w.Render(bmp)) { LogA("[mlt] 👁️ ⛔ Render 실패\n"); return; }
				if (!MLTWorld::Pack(bmp, nullptr, packed)) { LogA("[mlt] 👁️ ⛔ Pack 실패\n"); return; }
				const uint8* px = (const uint8*)packed.GetData();

				// ── 최빈 바이트를 배경으로 본다(회차 0 의 그 규약 — 0 을 배경으로 쓰면 안 된다)
				uint32 hist[256] = { 0u };
				for (uint32 i = 0; i < kSide * kSide; ++i) ++hist[px[i]];
				uint32 bg = 0u;
				for (uint32 v = 1; v < 256u; ++v) if (hist[v] > hist[bg]) bg = v;

				for (uint32 i = 0; i < kSide * kSide; ++i)
				{
					const uint8 b = px[i];
					if (b == 0u) ++nZero;
					if (b != (uint8)bg) ++nInk;
					++seen[b];
					float c[3]; _Unpack(b, c);
					for (uint32 j = 0; j < 3u; ++j) { sum[j] += c[j]; sqr[j] += (double)c[j] * c[j]; }
					++nPix;
				}

				// ── ⭐ 서로 다른 패치 세기(㉤)
				for (uint32 gy = 0; gy < kGrid; ++gy)
					for (uint32 gx = 0; gx < kGrid; ++gx)
					{
						uint64 h = 1469598103934665603ull;   // FNV-1a 64
						for (uint32 y = 0; y < kPatch; ++y)
							for (uint32 x = 0; x < kPatch; ++x)
							{
								h ^= (uint64)px[(gy * kPatch + y) * kSide + (gx * kPatch + x)];
								h *= 1099511628211ull;
							}
						if (h == 0ull) h = 1ull;             // 0 은 「빈 슬롯」 표식
						uint32 idx = (uint32)(h % (uint64)kSlots), probe = 0u;
						while (slot[idx] != 0ull && slot[idx] != h)
						{ idx = (idx + 1u) % kSlots; ++probe; }
						if (probe > probeMax) probeMax = probe;
						if (slot[idx] == 0ull) { slot[idx] = h; ++uniq; }
					}

				// ── 패치-상수 대조군: 패치마다 평균색을 내고 그 잔차²을 모은다
				for (uint32 gy = 0; gy < kGrid; ++gy)
					for (uint32 gx = 0; gx < kGrid; ++gx)
					{
						double pm[3] = { 0.0, 0.0, 0.0 };
						for (uint32 y = 0; y < kPatch; ++y)
							for (uint32 x = 0; x < kPatch; ++x)
							{
								float c[3]; _Unpack(px[(gy * kPatch + y) * kSide + (gx * kPatch + x)], c);
								for (uint32 j = 0; j < 3u; ++j) pm[j] += c[j];
							}
						const double inv = 1.0 / (double)(kPatch * kPatch);
						for (uint32 j = 0; j < 3u; ++j) pm[j] *= inv;
						for (uint32 y = 0; y < kPatch; ++y)
							for (uint32 x = 0; x < kPatch; ++x)
							{
								float c[3]; _Unpack(px[(gy * kPatch + y) * kSide + (gx * kPatch + x)], c);
								for (uint32 j = 0; j < 3u; ++j)
								{ const double d = (double)c[j] - pm[j]; patchSqr += d * d; }
							}
					}
			}
		}

		// ── 대조군 둘의 MSE(채널 평균) ─────────────────────────────
		double varA = 0.0;
		for (uint32 j = 0; j < 3u; ++j)
		{
			const double m = sum[j] / (double)nPix;
			varA += sqr[j] / (double)nPix - m * m;
		}
		const double mseA = varA / 3.0;
		const double mseB = patchSqr / (double)(nPix * 3ull);

		uint32 kinds = 0u;
		for (uint32 v = 0; v < 256u; ++v) if (seen[v] != 0u) ++kinds;

		LogA("[mlt]   프레임 %llu픽셀 · 바이트 0 **%llu개** · 잉크 **%.2f%%** · 나타난 바이트 종류 **%u**\n",
			(unsigned long long)nPix, (unsigned long long)nZero,
			(double)((double)nInk / (double)nPix * 100.0), kinds);
		LogA("[mlt]   대조군 A(전역 상수) MSE = **%.5f** · 대조군 B(패치 상수) MSE = **%.5f**"
		     " (B/A = %.3f)\n", mseA, mseB, (mseA > 1e-12) ? (mseB / mseA) : 0.0);

		// ⭐ **미리 정한 규칙이 문턱을 고른다**(결과를 보고 고르는 것이 아니다)
		const bool useB = (mseB < 0.5 * mseA);
		LogA("[mlt]   ⭐ 규칙(`MSE_B < 0.5·MSE_A`)이 고른 문턱 대조군 = **%s** (MSE = %.5f)\n",
			useB ? "B(패치 상수)" : "A(전역 상수)", useB ? mseB : mseA);
		LogA("[mlt]      ⇒ 판정 라운드의 ㉠ 문턱: `MSE_학습 < %.5f`(그 절반)\n",
			(useB ? mseB : mseA) * 0.5);

		int fail = 0;
		const bool g1 = (nZero == 0ull);
		LogA("[mlt]   %s ㉠ 바이트 0 이 없나(세계 규약)\n", g1 ? "✅" : "⛔");
		if (!g1) ++fail;
		const float ink = (float)((double)nInk / (double)nPix);
		const bool g2 = (ink >= 0.08f && ink <= 0.60f);
		LogA("[mlt]   %s ㉡ 잉크 비율 %.2f%% ∈ [8%%, 60%%]\n", g2 ? "✅" : "⛔", (double)(ink * 100.0f));
		if (!g2) ++fail;
		const bool g3 = (mseB < mseA);
		LogA("[mlt]   %s ㉢ 패치 상수 < 전역 상수(배관 검사)\n", g3 ? "✅" : "⛔");
		if (!g3) ++fail;
		LogA("[mlt]   ⓘ ㉣ 바이트 종류 **%u** ⇒ 사전 사용률의 **상한 감각**이다"
		     "(종류가 적으면 N=512 가 다 쓰일 이유가 없다)\n", kinds);
		// ⭐ ㉤ — 사전이 필요한 상한과, 그것이 정하는 `N` 스윕 점
		const uint32 nPatch = kSeeds * kFrames * kPatches;
		LogA("[mlt]   ⭐ ㉤ 서로 다른 8×8 패치 **%u개** / 본 패치 %u개 (%.1f%%) · 해시 최대 탐사 %u\n",
			uniq, nPatch, (double)((float)uniq / (float)nPatch * 100.0f), probeMax);
		LogA("[mlt]      ⇒ 등록: `N` 스윕 = **{%u, %u, %u}** · 시작값 **%u**"
		     " (규칙 `{U/8, U/2, U}` · U = %u)\n",
			(uniq + 4u) / 8u, (uniq + 1u) / 2u, uniq, (uniq + 1u) / 2u, uniq);
		LogA("[mlt]      ⚠️ `U` 는 **표본에 달렸다** — 이 수는 씨앗 %u × 프레임 %u 에서의 값이다\n",
			kSeeds, kFrames);

		if (fail == 0)
			LogA("[mlt] ✅ **P2 A단계 — 재구성 과제의 바닥을 정확히 안다.** 커널 판정으로 간다\n");
		else
			LogA("[mlt] ⛔ **P2 A단계 %d개 어긋남 — 세계를 고친다**(모델을 고치지 않는다)\n", fail);
	}

private:
	static constexpr uint32 kSeed0 = 0u, kSeeds = 12u;   // 개발 씨앗
	static constexpr uint32 kFrames = 8u;                // 씨앗마다 8 프레임
	static constexpr uint32 kSlots  = 65536u;            // ㉤ 해시 집합 슬롯(본 패치 6144 의 10배)

	// RGB332 바이트 → `[0,1]³`. ⚠️ **비트필드**다(스칼라로 쓰면 순서가 거짓말을 한다).
	static void _Unpack(uint8 b, float* c)
	{
		c[0] = (float)((b >> 5) & 7u) / 7.0f;
		c[1] = (float)((b >> 2) & 7u) / 7.0f;
		c[2] = (float)(b & 3u) / 3.0f;
	}
};
