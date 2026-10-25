#include "mlgpu.gen.h"   // IDE 인식용(빌드는 gen.h #pragma once 로 중복 skip). cwgen 생성 헤더.
// mlgpu.cw — 🧮 **텐서 아레나 + 커널.** 이 프로젝트가 GPU 를 만지는 유일한 자리다.
//
// ★ **아레나 규약 — 버퍼를 잘게 만들지 말고 큰 것 하나에 오프셋으로 산다.**
//   그 근거가 P0 에서 얻은 실측 둘이다:
//     ㉠ **파이프라인 캐시 키에 디스크립터셋 포인터가 들어간다** → 커널마다 버퍼 조합을 갈아 바인딩하면
//        같은 셰이더가 여러 파이프라인으로 갈린다(위젯 없는 GUI 앱에서 이미 셰이더 3조합 → 파이프라인 8개).
//     ㉡ **한 커맨드버퍼 안에서 디스크립터셋을 다시 `Update` 하면 앞 디스패치까지 그 값을 본다** —
//        디스패치는 누적되고 셋 내용은 **마지막 것 하나**이므로.
//   ⇒ **버퍼 하나를 한 번 바인딩하고, 무엇을 읽고 쓸지는 push constants 의 오프셋이 말한다.**
//      그러면 디스크립터셋이 **평생 한 번만** 갱신되므로 ㉠·㉡ 이 원리적으로 안 생기고,
//      **한 프레임에 같은 커널을 서로 다른 텐서로 몇 번이든** 돌릴 수 있다(= 학습 한 스텝의 모양).
//   ⚠️ 상한은 **단일 SSBO 바인딩 4GB**(Vulkan `maxStorageBufferRange` 가 `uint32_t`) — 그보다 크면
//      아레나를 여러 개로 나누고 바인딩을 늘린다.
//
// ⚠️⚠️⚠️ **회수는 디스패치보다 뒤 프레임에서 한다.** 이 엔진은 dispatch 를 프레임 컴퓨트 커맨드버퍼에
//   **누적만** 하고 제출은 Present 에서 1회다 → 같은 프레임에 `Read` 하면 **디스패치 이전 내용**이 나온다
//   (실측으로 전부 0 을 밟았다). **함수로 고칠 수 없는 구조**이므로 학습 루프가 "디스패치하는 프레임 /
//   읽는 프레임" 을 갈라야 한다(손실을 한 스텝 늦게 읽는다).
//
// ★ **왜 이 모듈이 RHI 를 직접 쓰나** = `Docs/Guide.md` 의 그 예외다: **그리지 않는 모듈**은 그 금지의
//   대상이 아니다(GPU 를 계산 장치로만 쓴다). 반대로 밀어붙였으면 텐서 아레나가 "그래픽스 원시형" 이 되어
//   그래픽스 모듈이 그래픽스 아닌 어휘를 배웠을 것이다.
//
// ⚠️ 전부 **렌더 스레드**에서 부른다(GPU 오브젝트를 만들고 커맨드를 기록한다).
using namespace PE;

// 🧩 **텐서는 오브젝트가 아니라 아레나 안의 자리**다 — `offset` 은 **float 인덱스**(바이트가 아니다.
//   셰이더가 `RWStructuredBuffer<float>` 로 색인하므로 그 단위가 계약이다).
//   ★ 값 struct 라 복사가 공짜고, 수명 관리가 없다(아레나가 유일한 소유자다).
struct MLTensor
{
	uint32 offset = 0;
	uint32 rows = 0;
	uint32 cols = 0;

	uint32 Count() const { return rows * cols; }
	bool IsValid() const { return rows != 0u && cols != 0u; }
};

// 🏟️ **아레나** — 큰 SSBO 하나 + 범프 할당. 텐서는 여기서 자리를 얻는다.
class MLArena
{
public:
	// `floatCapacity` 개의 float. ⚠️ 4GB(= float 10.7억개)를 넘으면 RHI 가 로그와 함께 거절한다.
	bool Create(RHI* rhi, uint32 floatCapacity)
	{
		Destroy();
		if (rhi == nullptr || floatCapacity == 0u) return false;
		_rhi = rhi;
		// ★ `bRW_Shader` = **GPU 상주(device-local) 단일 버퍼** — 프레임을 넘어 상태를 유지한다(가중치의 자리).
		BufferCreateOptions opts;
		opts.bRW_Shader = true;
		_buf = RHIBuffer::CreateRHIBuffer(rhi, RHIBufferType::STORAGE, (int)sizeof(float),
			(int64)floatCapacity, &opts);
		if (_buf == nullptr) { _rhi = nullptr; return false; }

		// ⚠️ **0 으로 채운다** — "커널이 안 썼다"(0 이 남는다)와 "틀린 값을 썼다" 가 갈리게 하는 값이다.
		//   ★ 이것이 생성 때의 유일한 값싼 CPU 쓰기 창이다(`EndWrite` 가 그 스테이징을 파기한다).
		// ⚠️⚠️⚠️ **회차 130 이 여기를 의심한다** — 이 줄은 `BeginWrite()` 가 null 이면
		//   **조용히 아무것도 안 하고 넘어간다.** 그러면 아레나에 **이전 메모리의 잔재**가 남고,
		//   파라미터는 초기화 커널이 덮으니 멀쩡한데 **AdamW 의 `m`/`v` 만 쓰레기**가 된다
		//   ⇒ 학습 결과가 **벌마다 조금씩 다르다**(회차 129 의 「무리 29개」와 같은 모양).
		//   ★ 그래서 **소리를 내게** 한다 — 이 저장소가 늘 경계하는 *"조용한 실패"* 의 자리다.
		void* m = _buf->BeginWrite();
		if (m != nullptr) MemZero(m, _buf->bufferSize);
		else LogA("[mlcore] ⚠️⚠️ **아레나를 0 으로 못 채웠다**(BeginWrite 가 null) — "
			"AdamW 모멘트에 잔재가 남아 **학습이 실행마다 달라진다**\n");
		_buf->EndWrite();
		// ⚠️ **회차 130 이 시험했고 — 이것으로는 안 고쳐졌다.**
		//   가설은 이랬다: 위 0 채우기는 **스테이징 복사**이고 그것이 뒤이어 쌓이는 컴퓨트 디스패치와
		//   순서 보장이 없으면 커널이 **채워지기 전**을 읽는다. 그 자리가 보이는 조건도 관측과 맞았다
		//   (처음 몇 벌은 **새 GPU 메모리**라 안 보이고, 할당자가 **재활용**을 시작하면 보인다).
		//   ⛔ **실측**: 이 줄을 넣어도 벌 3 부터 여전히 갈렸다(무리 6개) ⇒ **가설 기각**.
		//   ★ 그래도 **남긴다** — 「채운 뒤 씻는다」는 계약상 옳고 **생성 때 1회**라 값이 0 이다.
		//     ⚠️ 회차 111 의 `Destroy` 앞 `WaitIdle` 과 **같은 처지**다(안 고쳤지만 계약은 우리 것).
		_rhi->WaitIdle();
		_capacity = floatCapacity;
		_used = 0;
		return true;
	}

	// ══════════════════════════════════════════════════════════════════
	// ⚠️ **파기 전에 `WaitIdle` 로 씻는다** — 엔진이 적어 둔 계약을 지키는 것뿐이다
	// ══════════════════════════════════════════════════════════════════
	//   `RHI.h`: `WaitIdle()` = *"런타임 중 GPU 리소스를 처음 만들면서 … **in-flight 커맨드 참조 회피**"* ·
	//   `ReleaseGPU()` = *"⚠ in-flight 참조가 없을 때 호출해야 안전(**호출측이 WaitIdle 등으로 보장**)"*.
	//   ⇒ ★ **보장하는 쪽이 우리다** — 여태 안 지키고 있었다.
	//
	// ⚠️⚠️⚠️ **이것이 「몸통 비결정성」을 고치지는 못했다** — 그 사실을 여기 적어 둔다(MLT 회차 111).
	//   실측: 같은 씨앗·같은 800스텝을 반복하면 파라미터 859,136개 중 **830,848개**가 갈리고
	//   그 갈림이 **간헐적**이다(경합의 얼굴). 이 한 줄을 넣고 **같은 하네스를 다시 돌렸더니
	//   여전히 갈렸다**(그리고 무늬가 팔 사이에서 재현되지 않았다 ⇒ 팔별 해석은 **표본 3개짜리 잡음**이었다).
	//   ⇒ ⚠️ **범인은 아직 안 잡혔다.** 그래도 이 호출은 **계약상 옳으므로 남긴다**
	//     (비용 = `Setup` 당 한 번). ★ 진행 상황은 `Projects/ML/mltlog_1.md` 회차 108~111.
	//   ⚠️ `Create` 가 `Destroy` 를 먼저 부르므로 `Setup` 한 번에 한 번만 돈다.
	void Destroy()
	{
		if (_rhi != nullptr && _buf != nullptr) { _rhi->WaitIdle(); _rhi->DestroyRHIBuffer(_buf); }
		_buf = nullptr; _rhi = nullptr; _capacity = 0; _used = 0;
	}
	~MLArena() { Destroy(); }

	bool IsValid() const { return _buf != nullptr; }
	RHIBuffer* Raw() const { return _buf; }
	uint32 Used() const { return _used; }
	uint32 Capacity() const { return _capacity; }

	// 🎯 자리를 잡는다(범프 할당). 넘치면 **무효 텐서**를 돌려주고 로그를 찍는다.
	//   ⚠️ **해제가 없다** — 학습 그래프의 텐서 배치는 스텝마다 같으므로 "한 번 잡고 계속 쓴다" 가 맞고,
	//     해제를 넣으면 단편화 관리가 생긴다(그 복잡도를 벌 이유가 아직 없다).
	MLTensor Alloc(uint32 rows, uint32 cols)
	{
		MLTensor t;
		if (rows == 0u || cols == 0u) return t;
		const uint64 need = (uint64)rows * (uint64)cols;
		if (_used + need > (uint64)_capacity)
		{
			LogA("[mlcore] 아레나가 모자란다: %llu 개 더 필요한데 남은 것이 %u 개다\n",
				(unsigned long long)need, _capacity - _used);
			return t;
		}
		t.offset = _used;
		t.rows = rows;
		t.cols = cols;
		_used += (uint32)need;
		return t;
	}

	// CPU → GPU (그 텐서 자리에). ⚠️ 동기이고 무겁다(스테이징 + 큐 유휴 대기) — 스텝마다 부르지 마라.
	// ⚠️⚠️⚠️ **이 원시형은 `t.Count()` 만큼 읽는다 — 소스가 그보다 짧으면 넘어 읽는다.**
	//   ★ 그래서 **가능하면 아래의 배열 오버로드를 써라**(배열은 자기 크기를 안다).
	//     생 포인터 판은 "소스 크기가 텐서와 정확히 같다" 를 **부르는 쪽이 보증**할 때만 쓴다.
	bool Write(const MLTensor& t, const float* src)
	{
		if (_rhi == nullptr || _buf == nullptr || !t.IsValid() || src == nullptr) return false;
		return _rhi->UploadBuffer(_buf, src, (uint64)t.Count() * sizeof(float),
			(uint64)t.offset * sizeof(float));
	}

	// ★ **크기를 아는 쓰기 — 넘어읽기가 구조적으로 불가능하다.**
	//
	// ⚠️⚠️ **왜 있나(실측으로 밟았다)**: 아레나의 텐서는 **상한으로** 잡히는 자리가 있는데
	//   (`kEMaxSpans`·`kXMaxSpans` 처럼 "구간이 최대 몇 개") 소스 배열은 **실제 개수**만 갖는다.
	//   그때 `Write(t, arr.Data())` 는 `t.Count()` 만큼 읽으므로 배열 뒤를 **넘어 읽었다**:
	//     · P2-c 교차 `kXMaxSpans = 2400` ⇒ 최대 **9.6KB**
	//     · P3-b β / 코덱 `400` ⇒ 최대 **1.6KB**
	//   ★ 그 자리가 **매핑 안 된 페이지**면 업로드의 memcpy 안에서 액세스 위반이 나고,
	//     매핑 여부는 **힙 배치에 달렸으므로 간헐적**이다 — 이 저장소가 오래 쫓던
	//     `MLApp.exe · ucrtbase.dll · 0xc0000005` 의 서명과 정확히 같다.
	//   ⚠️ 그리고 τ 점이 진행될수록 구간이 줄어 **넘어읽는 양이 커지므로** 죽는 자리가 달라 보였다.
	// ★ 판정 규칙: ***"상한으로 잡은 자리에 실제 크기 배열을 쓸 때는 크기를 아는 쪽에 물어라."***
	//
	// ⚠️ 크기가 다르면 **적게** 올리고 **로그를 찍는다** — 조용히 맞추면 다음 사람이 같은 함정을 밟는다.
	//   ★ 이것은 앞 동작보다 **엄격하게 안전하다**: 짧으면 넘어읽는 대신 그만큼만 올리고,
	//     길면 예전과 같이 텐서 크기까지만 올린다(넘치는 쓰기가 원래 없었다).
	bool Write(const MLTensor& t, const Array<float>& src)
	{
		if (_rhi == nullptr || _buf == nullptr || !t.IsValid()) return false;
		const uint64 have = (uint64)src.Count(), want = (uint64)t.Count();
		if (have == 0ull || src.Data() == nullptr) return false;
		const uint64 n = (have < want) ? have : want;
		if (have != want)
			LogA("[mlcore] ⚠️ Write 크기 불일치: 배열 %llu · 텐서 %llu → **%llu 개만** 올린다\n",
				(unsigned long long)have, (unsigned long long)want, (unsigned long long)n);
		return _rhi->UploadBuffer(_buf, src.Data(), n * sizeof(float),
			(uint64)t.offset * sizeof(float));
	}

	// 🔎 **회차 128(D4)** — 리드백 앞에서 **쌓인 컴퓨트를 씻는다**.
	//   ⚠️⚠️ 이 엔진은 dispatch 를 `computeCb[frame]` 에 **누적만** 하고 제출은 Present 에서 1회다
	//     ⇒ 「몇 틱 기다린다」는 **큐가 얕을 때만** 맞는 어림이다(회차 53 이 그것을 밟았다:
	//     짧게 돌면 늘 맞고 **길게 돌면 틀린다**). ★ `WaitIdle` 은 그 어림을 **보장으로** 바꾼다.
	//   ⚠️ **진단·평가 경로 전용**이다 — 학습 루프에서 부르면 매 걸음 파이프라인이 비워진다.
	void Flush() const { if (_rhi != nullptr) _rhi->WaitIdle(); }

	// GPU → CPU (그 텐서 자리에서). ⚠️⚠️ **이 프레임에 디스패치한 결과는 안 보인다**(머리말의 ⚠️⚠️⚠️).
	bool Read(const MLTensor& t, Bytes& out) const
	{
		if (_rhi == nullptr || _buf == nullptr || !t.IsValid()) return false;
		return _rhi->ReadbackBuffer(_buf, out, (uint64)t.offset * sizeof(float),
			(uint64)t.Count() * sizeof(float));
	}

private:
	RHI*       _rhi = nullptr;
	RHIBuffer* _buf = nullptr;
	uint32     _capacity = 0;
	uint32     _used = 0;
};

// 🔧 **커널 하나** = 컴퓨트 셰이더 + 아레나 바인딩 하나.
//   ★ 바인딩은 **한 번만** 한다(아레나 규약 ㉡) — 그 뒤로 `Update` 를 다시 부르지 않는다.
class MLKernel
{
public:
	// 쿡된 `.spv` 바이트로 만든다(`shaders/gemm.cs.spv`).
	bool Create(RHI* rhi, const void* spv, uint64 spvSize, const MLArena& arena)
	{
		Destroy();
		if (rhi == nullptr || spv == nullptr || spvSize == 0 || !arena.IsValid()) return false;
		_rhi = rhi;
		_shader = rhi->CreateRHIShader(RHIShader::Type::COMPUTE, (const uchar*)spv, (size_t)spvSize);
		if (_shader == nullptr) { _rhi = nullptr; return false; }
		// ⚠️ `[numthreads]` 를 spv 에서 못 읽으면 스레드 수로 디스패치할 수 없다 — 그 자리에서 거절한다
		//   (관례값으로 몰래 떨어지는 것이 이 프로젝트에서 제일 위험한 종류의 침묵이다).
		if (!_shader->HasLocalSize())
		{
			LogA("[mlcore] 커널의 numthreads 를 spv 에서 못 읽었다 — 스레드 디스패치 불가\n");
			Destroy();
			return false;
		}
		_desc = rhi->CreateRHIDescriptorSet();
		if (_desc == nullptr) { Destroy(); return false; }
		// ★ 아레나를 `u0` 에 **한 번** 건다.
		_desc->SetStorageBuffer(0, arena.Raw(), DESC_USAGE::COMPUTE_SHADER);
		_desc->Update();
		return true;
	}

	void Destroy()
	{
		if (_rhi != nullptr)
		{
			if (_desc != nullptr)   _rhi->DestroyRHIDescriptorSet(_desc);
			if (_shader != nullptr) _rhi->DestroyRHIShader(_shader);
		}
		_desc = nullptr; _shader = nullptr; _rhi = nullptr;
	}
	~MLKernel() { Destroy(); }

	bool IsReady() const { return _shader != nullptr && _desc != nullptr; }
	void LocalSize(uint32 out[3]) const
	{
		if (out == nullptr) return;
		const bool ok = (_shader != nullptr);
		out[0] = ok ? _shader->localSize[0] : 0u;
		out[1] = ok ? _shader->localSize[1] : 0u;
		out[2] = ok ? _shader->localSize[2] : 0u;
	}

	// ★ **스레드 수로 디스패치한다** — 그룹 수는 엔진이 셰이더의 `[numthreads]` 로 나눈다.
	//   `push` = push constants(최대 128바이트 — 텐서 오프셋과 M/N/K 가 그 자리다).
	//   ⚠️ 남는 스레드를 버리는 **범위 검사는 커널의 몫**이다.
	bool Dispatch(uint32 threadsX, uint32 threadsY, uint32 threadsZ,
		const void* push, uint32 pushSize)
	{
		if (!IsReady()) return false;
		return _rhi->DispatchComputeThreads(_shader, _desc, threadsX, threadsY, threadsZ, push, pushSize);
	}

private:
	RHI*              _rhi = nullptr;
	RHIShader*        _shader = nullptr;
	RHIDescriptorSet* _desc = nullptr;
};

// 📦 push constants — ⚠️⚠️ **셰이더의 같은 이름 구조체와 바이트가 같아야 한다.**
//   어긋나면 커널이 엉뚱한 오프셋/크기를 읽고 **크래시가 아니라 조용히 틀린 결과**가 나온다
//   (이 프로젝트에서 제일 잡기 힘든 종류의 버그다 → 그래서 짝을 여기 나란히 둔다).

// `gemm.cs.hlsl` 의 `GemmParams`.
//   ★ `transA`/`transB` = **그 입력이 전치되어 저장돼 있다**는 뜻이고, `M`/`N`/`K` 는 **언제나 논리 크기**다
//     (계산은 늘 `(M×K)·(K×N)`). 그 규약을 헷갈리면 색인이 밀려 조용히 틀린다.
//   ⚠️⚠️ **마지막이 `float` 다** — 셰이더의 그 자리와 타입이 같아야 한다(함정 33 을 밟은 자리).
//   ★ `beta` = `C = A·B + beta·C`(BLAS 규약). **기본 0 이라 기존 호출부는 글자 그대로 같다** —
//     그것이 이 필드를 뒤에 붙인 이유다(앞에 끼우면 조용히 밀린다).
//     ⇒ 어텐션의 `dPatch = dQ·Wqᵀ + dK·Wkᵀ + dV·Wvᵀ` 가 첫 소비자다(`add` 커널을 만들지 않는다).
struct MLGemmParams
{
	uint32 aOff = 0, bOff = 0, cOff = 0;
	uint32 M = 0, N = 0, K = 0;
	uint32 transA = 0, transB = 0;
	float  beta = 0.0f;
};

// `sub.cs.hlsl` 의 `SubParams` — 원소별 `out = a - b`(= MSE 의 기울기 `dC = C - T`).
struct MLSubParams
{
	uint32 aOff = 0, bOff = 0, outOff = 0, count = 0;
};

// `gradcheck.cs.hlsl` 의 `GradCheckParams` — 중앙차분 수치 기울기(B 에 대해).
//   ⚠️ 마지막이 **`float`** 다 — 호스트/셰이더에서 그 자리와 타입이 같아야 한다.
struct MLGradCheckParams
{
	uint32 aOff = 0, bOff = 0, tOff = 0, outOff = 0;
	uint32 M = 0, N = 0, K = 0;
	float  eps = 0.0f;
};

// 🧮 **CPU 레퍼런스 GEMM** — `C = A · B`(행 우선).
//   ★ **이것을 버리지 않는다.** 커널을 고칠 때마다 필요하고, 그래디언트 체크의 바닥이 된다.
//     `-perf` 처럼 **끄는 것이지 지우는 것이 아니다**(→ Docs/Guide.md 의 그 원칙).
//   ⚠️ 누산 순서를 셰이더와 **같게**(k 오름차순) 둔다 — 다르면 부동소수 오차가 커져 "커널이 틀렸나" 를
//     판정할 수 없다(그 순서가 곧 비교 가능성이다).
CW_EXPORT void MLGemmCpu(const float* a, const float* b, float* c, uint32 M, uint32 N, uint32 K)
{
	if (a == nullptr || b == nullptr || c == nullptr) return;
	for (uint32 row = 0; row < M; ++row)
		for (uint32 col = 0; col < N; ++col)
		{
			float acc = 0.0f;
			for (uint32 k = 0; k < K; ++k) acc += a[row * K + k] * b[k * N + col];
			c[row * N + col] = acc;
		}
}

// `adamw.cs.hlsl` 의 `AdamWParams`. ⚠️ **편향보정을 호스트가 계산해 넘긴다**(`bc1`/`bc2`) —
//   스텝을 세는 것은 호스트의 일이고 커널은 "이번에 이만큼 보정하라" 만 받는다.
struct MLAdamWParams
{
	uint32 pOff = 0, gOff = 0, mOff = 0, vOff = 0, count = 0;
	float  lr = 1.0e-2f, beta1 = 0.9f, beta2 = 0.999f, eps = 1.0e-8f, wd = 0.0f;
	float  bc1 = 1.0f, bc2 = 1.0f;
};

// `embed.cs.hlsl` / `embed_bwd.cs.hlsl` 의 파라미터(둘의 자리 배치가 같아 한 구조체로 쓴다).
//   ⚠️ 두 셰이더의 필드 **이름**은 다르지만(`tableOff`/`outOff` ↔ `dOutOff`/`dTableOff`) **바이트 배치가
//     같다** — 그래서 하나로 둔다. ★ 이름이 다른 이유는 방향이 다르기 때문이고, 배치가 같은 이유는
//     둘 다 "토큰 · 표 · 활성값" 세 자리를 쓰기 때문이다.
struct MLEmbedParams
{
	uint32 tokOff = 0, aOff = 0, bOff = 0;   // forward: a=table b=out · backward: a=dOut b=dTable
	uint32 seqLen = 0, dim = 0, vocab = 0;
};

// `patch_embed.cs.hlsl` / `patch_embed_bwd.cs.hlsl` 의 파라미터.
//   ⚠️ 두 셰이더의 셋째 필드 이름이 다르지만(`posTableOff` ↔ `dSlotTableOff`) **바이트 배치가 같아**
//     한 구조체로 쓴다 — `MLEmbedParams` 와 같은 관용구다.
//   ★ forward: `a = slotTable · b = posTable · c = out`
//     backward: `a = dOut · b = dSlotTable`(c 는 안 쓴다 — 뒤 절의 `dPos == dOut` 지름길 때문에)
struct MLPatchEmbedParams
{
	uint32 frameOff = 0, aOff = 0, bOff = 0, cOff = 0;
	uint32 frameW = 0, frameH = 0, patchK = 0, dim = 0;

	// 격자에서 따라 나오는 값들 — ★ 여기서 한 번만 계산한다(호출부마다 나누기를 쓰면 어긋난다).
	uint32 GridW() const { return (patchK != 0u) ? (frameW / patchK) : 0u; }
	uint32 GridH() const { return (patchK != 0u) ? (frameH / patchK) : 0u; }
	uint32 Patches() const { return GridW() * GridH(); }
	uint32 Slots() const { return patchK * patchK; }
	uint32 SlotRows() const { return Slots() * 256u; }
};

// `ctx_embed.cs.hlsl` / `ctx_embed_bwd.cs.hlsl` 의 파라미터.
//   ★ forward: `a = slotTable · b = out` · backward: `a = dOut · b = dSlotTable`(배치가 같아 한 구조체)
//   ⚠️⚠️ 표의 행이 `자리 × 257` 이다 — 마지막(256)이 **"없음"**(창이 코퍼스 앞을 넘어감)이다.
//     실제 바이트값 하나를 빌려 쓰면 *"앞이 없다"* 와 *"그 바이트였다"* 가 구별되지 않는다.
struct MLCtxEmbedParams
{
	uint32 tokOff = 0, aOff = 0, bOff = 0, pad0 = 0;
	uint32 seqLen = 0, ctxK = 0, dim = 0, pad1 = 0;

	uint32 SlotRows() const { return ctxK * 257u; }
};

// `span_embed.cs.hlsl` / `span_embed_bwd.cs.hlsl` 의 파라미터.
//   ★ forward: `a = slotTable · b = out` · backward: `a = dOut · b = dSlotTable`(배치가 같아 한 구조체)
//   ⚠️⚠️ 표의 행이 `구간자리 × 257` 이다 — 마지막(256)이 **"끝/없음"**(구간이 그보다 짧다).
//     0 으로 메우면 *"바이트 0 이 있었다"* 와 *"거기서 끝났다"* 가 구별되지 않아 **길이를 못 배운다.**
//   ★ 그리고 디코더의 출력 어휘도 257 이라 **인코더와 디코더가 같은 알파벳**을 쓴다.
struct MLSpanEmbedParams
{
	uint32 tokOff = 0, startOff = 0, lenOff = 0, aOff = 0;
	uint32 bOff = 0, spans = 0, maxLen = 0, dim = 0;

	uint32 SlotRows() const { return maxLen * 257u; }
};

// `relu.cs.hlsl` / `relu_bwd.cs.hlsl` 의 파라미터.
//   ⚠️ 두 셰이더의 필드 이름이 다르지만(`inOff/outOff` ↔ `preOff/dOutOff/dInOff`) **배치가 같다** —
//     `MLEmbedParams` 와 같은 관용구다. forward 는 `c` 를 안 쓴다.
struct MLReluParams
{
	uint32 aOff = 0, bOff = 0, cOff = 0, count = 0;
};

// `softmax.cs.hlsl` 의 `SoftmaxParams`.
//   ⚠️⚠️ **마지막이 `float` 다**(함정 33). ★ `scale` = **온도**(`softmax(z · scale)`) —
//     기본 `1.0` 이면 예전과 같다. 어텐션이 `1/√D` 를 여기로 넘긴다(점수 곱셈 커널을 만들지 않는다).
struct MLSoftmaxParams
{
	uint32 inOff = 0, outOff = 0, rows = 0, cols = 0;
	float  scale = 1.0f;
};

// `softmax_bwd.cs.hlsl` 의 `SoftmaxBwdParams`. ⚠️ 마지막이 **`float`** 다.
//   ★ `scale` 은 forward 와 **같은 값**을 받는다(사슬규칙) — 한쪽만 넣으면 기울기가 `1/√D` 배 틀리고
//     증상이 *"학습이 느리다"* 라서 버그로 안 읽힌다.
struct MLSoftmaxBwdParams
{
	uint32 probOff = 0, dOutOff = 0, dInOff = 0;
	uint32 rows = 0, cols = 0;
	float  scale = 1.0f;
};

// 🔢 **CPU 레퍼런스 softmax** — 셰이더와 **같은 순서·같은 안정화**(행 최댓값 빼기).
//   ⚠️ 최댓값 빼기를 한쪽만 하면 값이 미묘하게 갈려 비교가 흐려진다(수학적으로 같아도 부동소수는 다르다).
//   ★ `scale`(온도)은 **기본값이 있다** — 그래서 기존 호출부가 하나도 안 바뀐다.
//     ⚠️ 최댓값은 **곱한 뒤**에 잰다(셰이더와 같은 순서 — 곱하기 전에 재면 안정화가 어긋난다).
CW_EXPORT void MLSoftmaxCpu(const float* in, float* out, uint32 rows, uint32 cols, float scale = 1.0f)
{
	if (in == nullptr || out == nullptr) return;
	for (uint32 r = 0; r < rows; ++r)
	{
		const uint32 base = r * cols;
		float mx = in[base] * scale;
		for (uint32 v = 1; v < cols; ++v)
		{ const float z = in[base + v] * scale; if (z > mx) mx = z; }
		float sum = 0.0f;
		for (uint32 v = 0; v < cols; ++v)
		{ const float e = Exp(in[base + v] * scale - mx); out[base + v] = e; sum += e; }
		const float inv = 1.0f / sum;
		for (uint32 v = 0; v < cols; ++v) out[base + v] *= inv;
	}
}

// 🔢◀ **CPU 레퍼런스 — softmax 의 기울기.** `dIn_i = scale · p_i · (dOut_i − Σ_j p_j·dOut_j)`
//   ★ **왜 지금 생겼나**: 여태 softmax 는 **늘 손실 바로 앞**이었고 `softmax+CE` 의 기울기는
//     `probs − onehot` 으로 접혀 `sub` 하나로 끝났다. 어텐션의 softmax 는 **망 안쪽**이라
//     뒤에서 오는 `dOut` 이 임의의 값이고 접히지 않는다 ⇒ **야코비안을 실제로 쓰는 첫 자리**다.
//   ★ 야코비안을 **행렬로 만들지 않는다** — `Σ_j p_i(δ_ij − p_j)dOut_j = p_i(dOut_i − Σ_j p_j dOut_j)`
//     이므로 **행마다 내적 하나**면 된다(`cols×cols` 를 짓지 않는다).
//   ⚠️ 누산 순서는 `j` 오름차순 — 셰이더와 같아야 견줄 수 있다.
CW_EXPORT void MLSoftmaxBwdCpu(const float* prob, const float* dOut, float* dIn,
	uint32 rows, uint32 cols, float scale = 1.0f)
{
	if (prob == nullptr || dOut == nullptr || dIn == nullptr) return;
	for (uint32 r = 0; r < rows; ++r)
	{
		const uint32 base = r * cols;
		float dot = 0.0f;
		for (uint32 j = 0; j < cols; ++j) dot += prob[base + j] * dOut[base + j];
		for (uint32 i = 0; i < cols; ++i)
			dIn[base + i] = scale * prob[base + i] * (dOut[base + i] - dot);
	}
}

// 📉 **교차엔트로피**(자연로그 · 자리마다 평균). `probs` 는 softmax 결과, `target` 은 정답 바이트다.
//   ★ **손실은 CPU 가 회수한 `probs` 로 계산한다** — 리덕션 커널이 없는 이유가 그것이다(학습에 필요한
//     것은 손실값이 아니라 **기울기**이고, 그 기울기는 `probs − onehot` 이라 이미 `sub` 커널이 낸다).
//   ⚠️ `log(0)` 을 막는다 — softmax 출력이 float 아래로 깎이면 `-inf` 가 되어 곡선이 통째로 못 읽힌다.
CW_EXPORT float MLCrossEntropyCpu(const float* probs, const float* target, uint32 rows, uint32 cols)
{
	if (probs == nullptr || target == nullptr || rows == 0u) return 0.0f;
	float sum = 0.0f;
	for (uint32 r = 0; r < rows; ++r)
	{
		uint32 v = (uint32)target[r];
		if (v >= cols) v = 0u;
		float p = probs[r * cols + v];
		if (p < 1.0e-30f) p = 1.0e-30f;
		sum += -Log(p);
	}
	return sum / (float)rows;
}

// 🎯 **경험적 조건부 엔트로피 `H(다음|현재)`** — 이 코퍼스에서 **바이그램 모델이 도달할 수 있는 하한**이다.
//   ★ **왜 이것을 계산하나 = 판정을 "내려갔다" 에서 "어디까지 내려갔나" 로 바꾼다.**
//     *"손실이 내려간다"* 는 거의 아무것도 증명하지 않는다(틀린 기울기로도 내려간다). 하지만 **절대
//     목표**가 있으면 "모델이 이 데이터에서 배울 수 있는 것을 다 배웠나" 를 물을 수 있다.
//   ⚠️ 이 모델은 `임베딩 조회 → 선형` 이고 사이에 비선형이 없다 ⇒ **정확히 바이그램**이다(현재 바이트만
//     보고 다음을 고른다). 그래서 이 값이 그 구조의 정직한 하한이다.
//     ★ 나중에 층을 얹으면 이 하한 아래로 내려갈 수 있어야 한다 — 그때 이 숫자가 **비교 기준**이 된다.
//   ⚠️ 자연로그 단위(nat)다 — 손실과 **같은 단위**여야 견줄 수 있다.
CW_EXPORT float MLBigramEntropyCpu(const float* cur, const float* next, uint32 count, uint32 vocab)
{
	if (cur == nullptr || next == nullptr || count == 0u || vocab == 0u) return 0.0f;
	// ⚠️ 어휘²는 256² = 65536 이라 세는 표를 스택에 두면 크다 → `Array` 로 잡는다.
	Array<uint32> joint;   joint.Reset((uint64)vocab * vocab);
	Array<uint32> marg;    marg.Reset(vocab);
	for (uint32 i = 0; i < (uint32)joint.Count(); ++i) joint.Data()[i] = 0u;
	for (uint32 i = 0; i < vocab; ++i) marg.Data()[i] = 0u;

	for (uint32 i = 0; i < count; ++i)
	{
		uint32 a = (uint32)cur[i], b = (uint32)next[i];
		if (a >= vocab) a = 0u;
		if (b >= vocab) b = 0u;
		joint.Data()[a * vocab + b] += 1u;
		marg.Data()[a] += 1u;
	}

	// H(Y|X) = −Σ_x p(x) Σ_y p(y|x) log p(y|x)
	float h = 0.0f;
	for (uint32 a = 0; a < vocab; ++a)
	{
		const uint32 n = marg.Data()[a];
		if (n == 0u) continue;
		const float px = (float)n / (float)count;
		float hcond = 0.0f;
		for (uint32 b = 0; b < vocab; ++b)
		{
			const uint32 c = joint.Data()[a * vocab + b];
			if (c == 0u) continue;
			const float pyx = (float)c / (float)n;
			hcond += -pyx * Log(pyx);
		}
		h += px * hcond;
	}
	return h;
}

// 🔤 **CPU 레퍼런스 — 임베딩 조회.** 토큰은 float 로 담긴 정수다(0..255 는 float32 에 정확하다).
CW_EXPORT void MLEmbedCpu(const float* tok, const float* table, float* out,
	uint32 seqLen, uint32 dim, uint32 vocab)
{
	if (tok == nullptr || table == nullptr || out == nullptr) return;
	for (uint32 t = 0; t < seqLen; ++t)
	{
		uint32 v = (uint32)tok[t];
		if (v >= vocab) v = 0u;   // 셰이더와 **같은 규약**(범위 밖은 0 행)
		for (uint32 d = 0; d < dim; ++d) out[t * dim + d] = table[v * dim + d];
	}
}

// 🔤◀ **CPU 레퍼런스 — 임베딩 표의 기울기.** ★ 셰이더와 **같은 방향(gather)** 이고 **같은 순서**(t 오름차순)다.
//   ⚠️ 순서를 다르게 두면 float 합이 달라져 비교가 무의미해진다 — 그것이 애초에 atomic 을 피한 이유다.
CW_EXPORT void MLEmbedBwdCpu(const float* tok, const float* dOut, float* dTable,
	uint32 seqLen, uint32 dim, uint32 vocab)
{
	if (tok == nullptr || dOut == nullptr || dTable == nullptr) return;
	for (uint32 v = 0; v < vocab; ++v)
		for (uint32 d = 0; d < dim; ++d)
		{
			float acc = 0.0f;
			for (uint32 t = 0; t < seqLen; ++t)
			{
				uint32 tv = (uint32)tok[t];
				if (tv >= vocab) tv = 0u;
				if (tv == v) acc += dOut[t * dim + d];
			}
			dTable[v * dim + d] = acc;   // ★ 쓴다(더하지 않는다)
		}
}

// 🧱 **CPU 레퍼런스 — 패치 임베딩.** 셰이더와 **같은 순서**(자리 s 오름차순)로 더한다.
//   ⚠️ 순서를 바꾸면 float 합이 달라져 "오차 0" 을 요구할 수 없게 된다.
//   ★ `pos` 를 **먼저** 넣는 것까지 셰이더와 같다(누산 시작값이다).
CW_EXPORT void MLPatchEmbedCpu(const float* frame, const float* slotTable, const float* posTable,
	float* out, uint32 frameW, uint32 frameH, uint32 patchK, uint32 dim)
{
	if (frame == nullptr || slotTable == nullptr || posTable == nullptr || out == nullptr) return;
	if (patchK == 0u) return;
	const uint32 gridW = frameW / patchK, gridH = frameH / patchK;
	const uint32 slots = patchK * patchK;
	for (uint32 p = 0; p < gridW * gridH; ++p)
	{
		const uint32 py = p / gridW, px = p % gridW;
		for (uint32 d = 0; d < dim; ++d)
		{
			float acc = posTable[p * dim + d];
			for (uint32 sIdx = 0; sIdx < slots; ++sIdx)
			{
				const uint32 sy = sIdx / patchK, sx = sIdx % patchK;
				const uint32 fy = py * patchK + sy, fx = px * patchK + sx;
				uint32 b = (uint32)frame[fy * frameW + fx];
				if (b > 255u) b = 0u;   // 셰이더와 **같은 규약**
				acc += slotTable[(sIdx * 256u + b) * dim + d];
			}
			out[p * dim + d] = acc;
		}
	}
}

// 🧱◀ **CPU 레퍼런스 — 자리표의 기울기.** ★ 셰이더와 **같은 방향(gather)** 이고 **같은 순서**(p 오름차순).
//   ⚠️ `posTable` 의 기울기는 여기 없다 — **`dOut` 이 그것이다**(forward 가 그냥 더하므로 미분이 1 이고
//     배치가 같다). 그것을 모르고 커널을 하나 더 만들면 같은 값을 두 번 계산하게 된다.
CW_EXPORT void MLPatchEmbedBwdCpu(const float* frame, const float* dOut, float* dSlotTable,
	uint32 frameW, uint32 frameH, uint32 patchK, uint32 dim)
{
	if (frame == nullptr || dOut == nullptr || dSlotTable == nullptr) return;
	if (patchK == 0u) return;
	const uint32 gridW = frameW / patchK, gridH = frameH / patchK;
	const uint32 patches = gridW * gridH, slots = patchK * patchK;
	for (uint32 v = 0; v < slots * 256u; ++v)
	{
		const uint32 sIdx = v / 256u, b = v % 256u;
		const uint32 sy = sIdx / patchK, sx = sIdx % patchK;
		for (uint32 d = 0; d < dim; ++d)
		{
			float acc = 0.0f;
			for (uint32 pp = 0; pp < patches; ++pp)
			{
				const uint32 py = pp / gridW, px = pp % gridW;
				const uint32 fy = py * patchK + sy, fx = px * patchK + sx;
				uint32 fb = (uint32)frame[fy * frameW + fx];
				if (fb > 255u) fb = 0u;
				if (fb == b) acc += dOut[pp * dim + d];
			}
			dSlotTable[v * dim + d] = acc;   // ★ 쓴다(더하지 않는다)
		}
	}
}

// 🪟 **CPU 레퍼런스 — 창 임베딩.** 셰이더와 **같은 순서**(창 자리 j 오름차순)로 더한다.
//   ⚠️ `i < 0` 은 **256 행**(없음)이다 — 이 규약이 fwd/bwd/CPU 셋에서 같아야 한다.
CW_EXPORT void MLCtxEmbedCpu(const float* tok, const float* slotTable, float* out,
	uint32 seqLen, uint32 ctxK, uint32 dim)
{
	if (tok == nullptr || slotTable == nullptr || out == nullptr || ctxK == 0u) return;
	for (uint32 t = 0; t < seqLen; ++t)
		for (uint32 d = 0; d < dim; ++d)
		{
			float acc = 0.0f;
			for (uint32 j = 0; j < ctxK; ++j)
			{
				const int i = (int)t - (int)(ctxK - 1u) + (int)j;
				uint32 b = 256u;
				if (i >= 0) { b = (uint32)tok[(uint32)i]; if (b > 255u) b = 0u; }
				acc += slotTable[(j * 257u + b) * dim + d];
			}
			out[t * dim + d] = acc;
		}
}

// 🪟◀ **CPU 레퍼런스 — 창 임베딩 표의 기울기.** ★ 셰이더와 **같은 방향(gather)**·**같은 순서**(t 오름차순).
CW_EXPORT void MLCtxEmbedBwdCpu(const float* tok, const float* dOut, float* dSlotTable,
	uint32 seqLen, uint32 ctxK, uint32 dim)
{
	if (tok == nullptr || dOut == nullptr || dSlotTable == nullptr || ctxK == 0u) return;
	for (uint32 v = 0; v < ctxK * 257u; ++v)
	{
		const uint32 j = v / 257u, b = v % 257u;
		for (uint32 d = 0; d < dim; ++d)
		{
			float acc = 0.0f;
			for (uint32 t = 0; t < seqLen; ++t)
			{
				const int i = (int)t - (int)(ctxK - 1u) + (int)j;
				uint32 tb = 256u;
				if (i >= 0) { tb = (uint32)tok[(uint32)i]; if (tb > 255u) tb = 0u; }
				if (tb == b) acc += dOut[t * dim + d];
			}
			dSlotTable[v * dim + d] = acc;   // ★ 쓴다(더하지 않는다)
		}
	}
}

// 🌡️ **행마다 엔트로피** `H_t = -Σ_v p log p` (nat).
//   ★ **이것이 경계 점수다** — ML.md 의 *"경계 기준 = 접두사 조건부 엔트로피"* 그 값이다.
//     *"지금까지 본 것으로 다음이 예측되나"* 를 재고, 예측이 안 되면(높으면) **덩어리가 끝난 것**이다.
//   ⚠️ 확률이지 로짓이 아니다(softmax 를 이미 지난 값을 넣는다).
//   ⚠️ `p = 0` 인 항은 건너뛴다 — `0·log 0 = 0` 이 맞고, 그냥 곱하면 `NaN` 이 퍼진다.
CW_EXPORT void MLRowEntropyCpu(const float* probs, float* outH, uint32 rows, uint32 cols)
{
	if (probs == nullptr || outH == nullptr) return;
	for (uint32 r = 0; r < rows; ++r)
	{
		const float* q = probs + (uint64)r * cols;
		float h = 0.0f;
		for (uint32 v = 0; v < cols; ++v)
			if (q[v] > 0.0f) h -= q[v] * Log(q[v]);
		outH[r] = h;
	}
}

// 🧷 **CPU 레퍼런스 — 구간 임베딩.** 셰이더와 **같은 순서**(구간자리 j 오름차순)로 더한다.
//   ⚠️ `j >= len` 은 **256 행**(끝) 이다 — 이 규약이 fwd/bwd/CPU 셋에서 같아야 한다.
CW_EXPORT void MLSpanEmbedCpu(const float* tok, const float* starts, const float* lens,
	const float* slotTable, float* out, uint32 spans, uint32 maxLen, uint32 dim)
{
	if (tok == nullptr || starts == nullptr || lens == nullptr) return;
	if (slotTable == nullptr || out == nullptr) return;
	for (uint32 c = 0; c < spans; ++c)
	{
		const uint32 st = (uint32)starts[c], ln = (uint32)lens[c];
		for (uint32 d = 0; d < dim; ++d)
		{
			float acc = 0.0f;
			for (uint32 j = 0; j < maxLen; ++j)
			{
				uint32 b = 256u;
				if (j < ln) { b = (uint32)tok[st + j]; if (b > 255u) b = 0u; }
				acc += slotTable[(j * 257u + b) * dim + d];
			}
			out[c * dim + d] = acc;
		}
	}
}

// 🧷◀ **CPU 레퍼런스 — 구간 임베딩 표의 기울기.** ★ 셰이더와 **같은 방향(gather)**·**같은 순서**(c 오름차순).
CW_EXPORT void MLSpanEmbedBwdCpu(const float* tok, const float* starts, const float* lens,
	const float* dOut, float* dSlotTable, uint32 spans, uint32 maxLen, uint32 dim)
{
	if (tok == nullptr || starts == nullptr || lens == nullptr) return;
	if (dOut == nullptr || dSlotTable == nullptr) return;
	for (uint32 v = 0; v < maxLen * 257u; ++v)
	{
		const uint32 j = v / 257u, b = v % 257u;
		for (uint32 d = 0; d < dim; ++d)
		{
			float acc = 0.0f;
			for (uint32 c = 0; c < spans; ++c)
			{
				const uint32 st = (uint32)starts[c], ln = (uint32)lens[c];
				uint32 cb = 256u;
				if (j < ln) { cb = (uint32)tok[st + j]; if (cb > 255u) cb = 0u; }
				if (cb == b) acc += dOut[c * dim + d];
			}
			dSlotTable[v * dim + d] = acc;   // ★ 쓴다(더하지 않는다)
		}
	}
}

// ➖ **CPU 레퍼런스 — 원소별 뺄셈.**
//   ★ 이름은 **하는 일**로 지었다 — 지금 이 커널의 쓰임은 **MSE 의 기울기**(`dC = C − T`)지만
//   그것은 쓰임이고 하는 일은 뺄셈이다. `mse_grad` 로 지으면 다음 소비자가 생길 때 이름이 거짓말이 된다.
//   ★ 곱셈도 초월함수도 없어 GPU 와 **정확히** 같다 ⇒ 바로 아래 `MLReluCpu` 와 같은 결의 커널이고
//   **오차 0 을 상대로 요구할 수 있는** 자리다.
//   ⚠️⚠️ **이것이 없어서 P1 판정부가 인라인 `for` 문으로 흉내내고 있었다** — 그러면 같은 식이
//   **셰이더와 판정부 둘에** 살고, 한쪽을 고칠 때 다른 한쪽이 **조용히** 남는다. 그것이 바로 아래
//   `MLAdamWCpu` 의 ★ 주석이 말하는 값(*"파라미터를 직접 견주는 것만이 판정이다"*)의 전제다.
//   ★ 그리고 그것이 **판정 ① 의 `exact` 대상**이다(MLT 트랙이 같은 자리를 그렇게 적었다).
CW_EXPORT void MLSubCpu(const float* a, const float* b, float* out, uint32 count)
{
	if (a == nullptr || b == nullptr || out == nullptr) return;
	for (uint32 i = 0; i < count; ++i) out[i] = a[i] - b[i];
}

// 🔀 **CPU 레퍼런스 — ReLU.** ★ `max(v, 0)` 하나뿐이라 GPU 와 **정확히** 같다.
//   ⚠️ 그것이 ReLU 를 고른 이유다: GELU/tanh 는 근사식이 갈려 **오차 0 을 요구할 수 없게** 된다.
CW_EXPORT void MLReluCpu(const float* in, float* out, uint32 count)
{
	if (in == nullptr || out == nullptr) return;
	for (uint32 i = 0; i < count; ++i) out[i] = (in[i] > 0.0f) ? in[i] : 0.0f;
}

// 🔀◀ **CPU 레퍼런스 — ReLU 의 기울기.** ⚠️ **활성 전 값**(`pre`)을 본다(활성 후가 아니다) ·
//   그리고 `pre == 0` 은 **0 쪽**이다(`>` 이지 `>=` 가 아니다) — 셰이더와 같은 경계여야 한다.
CW_EXPORT void MLReluBwdCpu(const float* pre, const float* dOut, float* dIn, uint32 count)
{
	if (pre == nullptr || dOut == nullptr || dIn == nullptr) return;
	for (uint32 i = 0; i < count; ++i) dIn[i] = (pre[i] > 0.0f) ? dOut[i] : 0.0f;
}

// ⚙️ **CPU 레퍼런스 AdamW** — 셰이더와 **글자 그대로 같은 식**이어야 한다.
//   ★ 왜 필요한가: *"손실이 내려간다"* 는 **약한 검사**다. 편향보정이 틀려도 실효 lr 만 바뀌어
//     손실은 그대로 내려가고, 감쇠를 기울기에 섞어도(= Adam+L2) 내려간다 — 둘 다 AdamW 가 아닌데
//     증상이 "정규화가 약하다" 라서 **버그로 안 읽힌다**. ⇒ 파라미터를 직접 견주는 것만이 판정이다.
//   ⚠️ 감쇠는 **갱신에서 따로 뺀다**(decoupled) — `g += wd*p` 로 짜면 AdamW 가 아니다.
CW_EXPORT void MLAdamWCpu(float* p, const float* g, float* m, float* v, uint32 count,
	float lr, float beta1, float beta2, float eps, float wd, float bc1, float bc2)
{
	if (p == nullptr || g == nullptr || m == nullptr || v == nullptr) return;
	for (uint32 i = 0; i < count; ++i)
	{
		m[i] = beta1 * m[i] + (1.0f - beta1) * g[i];
		v[i] = beta2 * v[i] + (1.0f - beta2) * g[i] * g[i];
		const float mhat = m[i] * bc1;
		const float vhat = v[i] * bc2;
		p[i] -= lr * (mhat / (Sqrt(vhat) + eps));
		p[i] -= lr * wd * p[i];
	}
}

// 🧮 **CPU 레퍼런스 — 전치까지 있는 GEMM.** 셰이더와 **같은 규약**이다(`M`/`N`/`K` 는 논리 크기).
//   ★ forward 와 backward 를 이 하나로 검산한다(`dA = dC·Bᵀ` · `dB = Aᵀ·dC` 가 다 GEMM 이니까).
//   ★ `beta` 는 **기본값이 있다**(0 = 덮어쓴다) — 그래서 기존 호출부가 하나도 안 바뀐다.
//     ⚠️ `beta == 0` 은 **곱하지 않고 분기**한다 — `c` 가 초기화 전 쓰레기면 `0 * NaN = NaN` 이라
//       곱셈으로 두면 "0 으로 덮기" 가 실패한다(셰이더도 같은 분기다).
CW_EXPORT void MLGemmCpuT(const float* a, const float* b, float* c,
	uint32 M, uint32 N, uint32 K, bool transA, bool transB, float beta = 0.0f)
{
	if (a == nullptr || b == nullptr || c == nullptr) return;
	for (uint32 row = 0; row < M; ++row)
		for (uint32 col = 0; col < N; ++col)
		{
			float acc = 0.0f;
			for (uint32 k = 0; k < K; ++k)
			{
				const uint32 ai = transA ? (k * M + row) : (row * K + k);
				const uint32 bi = transB ? (col * K + k) : (k * N + col);
				acc += a[ai] * b[bi];
			}
			const uint32 ci = row * N + col;
			c[ci] = (beta != 0.0f) ? (acc + beta * c[ci]) : acc;
		}
}

// 📏 두 배열의 **최대 상대오차**. 판정에 쓰는 한 숫자다.
//   ⚠️ 분모에 절대값 하한을 둔다 — 기대값이 0 근처면 상대오차가 무한이 되어 판정이 무의미해진다.
// 📏 **최대 절대오차**와 **참값의 최대 크기**.
//   ★ **왜 이것이 따로 필요한가 — 원소별 상대오차는 0 을 지나는 출력에서 지표가 못 된다.**
//     `MLMaxRelErr` 은 분모에 `1e-6` 바닥이 있어서, 참값이 0 근처인 원소의 절대오차 `1e-12` 가
//     `1e-12 / 1e-6 = 1e-6` 으로 **증폭되어** 찍힌다. ⇒ 완벽한 커널이 "오차 1e-6" 으로 보인다.
//   ⚠️ 실측으로 밟았다: `softmax_bwd`(`dIn = scale·p·(dOut − dot)`)는 `dOut_i ≈ dot` 인 원소에서
//     결과가 0 을 지나고, 그 자리에서 원소별 상대오차가 `1.1e-6` 이 되어 판정이 실패로 떨어졌다.
//     ★ 그런데 `gemm` 은 **정확히 0** 이었고 배관은 멀쩡했다 — 즉 **지표가 틀린 것**이다.
//   ⇒ 그런 커널은 **`최대절대오차 / 참값최대크기`**(정규화 절대오차)로 본다 — 수치선형대수의 관례다.
//   ★ 함정 19(*"CE 를 지표로 삼았다"*)와 **같은 계열**이다: 값은 맞는데 척도가 거짓말을 한다.
CW_EXPORT float MLMaxAbsErr(const float* got, const float* want, uint32 n)
{
	if (got == nullptr || want == nullptr || n == 0u) return 0.0f;
	float worst = 0.0f;
	for (uint32 i = 0; i < n; ++i)
	{
		const float d = got[i] - want[i];
		const float ad = (d < 0.0f) ? -d : d;
		if (ad > worst) worst = ad;
	}
	return worst;
}

CW_EXPORT float MLMaxAbs(const float* v, uint32 n)
{
	if (v == nullptr || n == 0u) return 0.0f;
	float worst = 0.0f;
	for (uint32 i = 0; i < n; ++i)
	{
		const float a = (v[i] < 0.0f) ? -v[i] : v[i];
		if (a > worst) worst = a;
	}
	return worst;
}

CW_EXPORT float MLMaxRelErr(const float* got, const float* want, uint32 n)
{
	if (got == nullptr || want == nullptr || n == 0u) return 0.0f;
	float worst = 0.0f;
	for (uint32 i = 0; i < n; ++i)
	{
		const float d = got[i] - want[i];
		const float ad = (d < 0.0f) ? -d : d;
		float aw = (want[i] < 0.0f) ? -want[i] : want[i];
		if (aw < 1e-6f) aw = 1e-6f;
		const float r = ad / aw;
		if (r > worst) worst = r;
	}
	return worst;
}
