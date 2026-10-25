// mltevalgate.cw — 🔁 **평가 리드백 게이트** — ⚠️ **새 하네스의 평가 루프는 이것을 쓴다**
//
// ══════════════════════════════════════════════════════════════════════════════
// ⚠️⚠️⚠️ **「다음 틱에 읽는다」는 보장이 아니다.** 회차 53·54 가 그것을 실측으로 갈랐다:
//   · 회차 54 — 파라미터 **858,368개**가 800스텝까지 **비트 동일** ⇒ **학습은 완전히 결정적**이다.
//   · 회차 53 — 그런데 최종 **CE 폭**이 800스텝 `0.017` · 3200스텝 `0.047` 이었다.
//   ⇒ 흔들린 것은 **모델이 아니라 그것을 읽는 길**이다.
//
// ★ **엔진이 이미 그 자리를 적어 뒀다**(`RHI.h`/`RHIBuffer_Vulkan.cpp` 의 `ReadbackBuffer`):
//   *"이 배리어는 「이 프레임에 누적된 컴퓨트」를 기다려 주지 않는다. 이 엔진은 dispatch 를
//   `computeCb[frame]` 에 **누적만** 하고 제출은 Present 에서 1회다 … **같은 프레임에 dispatch 한
//   결과를 여기서 회수하면 디스패치 이전 내용이 나온다.** ★ 고칠 곳은 이 함수가 아니라
//   **호출부의 타이밍**이다: 회수는 그 디스패치를 낸 프레임보다 **뒤에서** 한다."*
//   ⇒ 그리고 `MAX_FRAMES_IN_FLIGHT = 2` 다 ⇒ **한 틱으로는 모자랄 수 있다.**
//   ⚠️ 짧게 돌면 큐가 얕아 늘 맞고, **길게 돌면 틀린다** — 그것이 회차 53 의 「폭이 100~800 사이에서
//     태어난다」의 정체다.
//
// ── 그래서 규약을 하나로 둔다 ────────────────────────────────────────────────
//   **디스패치 → `kDelay` 틱 대기 → 읽기**, 그리고 **읽기 전에는 다음 forward 를 안 쏜다**
//   (⚠️ `_tLoss` 는 forward 마다 덮어써지므로 미리 쏘면 그 값을 잃는다).
//   ⚠️ `ReadLoss` 는 `SelectStep` 이 세운 `_valid` 로 나눈다 ⇒ **읽기 전에 `SelectStep` 을 다시
//     부르지 않는다**(이 클래스가 그 순서를 지킨다).

using namespace PE;

class MLTEvalGate
{
public:
	// `MAX_FRAMES_IN_FLIGHT`(2) + 1. ⚠️ 상수의 근거가 엔진에 있으므로 임의값이 아니다.
	static constexpr uint32 kDelay = 3u;

	void Begin(uint32 nSteps)
	{
		_n = nSteps; _i = 0u; _wait = 0u; _sum = 0.0; _pending = false; _finite = true;
	}

	// 한 틱에 한 걸음. **끝나면 `true`**(그때 `Mean()` 이 값을 갖는다).
	//   `fail` 이 켜져 돌아오면 호출부가 그 자리에서 멈춘다.
	bool Step(MLTModel& M, bool& fail)
	{
		fail = false;
		if (_pending)
		{
			if (_wait > 0u) { --_wait; return false; }
			float ls = 0.0f;
			if (!M.ReadLoss(ls)) { fail = true; return true; }
			if (!(ls == ls) || ls > 1.0e30f) _finite = false;
			_sum += (double)ls; ++_i; _pending = false;
		}
		if (_i >= _n) return true;
		M.SelectStep(_i);
		if (!M.Forward()) { fail = true; return true; }
		_pending = true; _wait = kDelay;
		return false;
	}

	float Mean() const { return (_n == 0u) ? 0.0f : (float)(_sum / (double)_n); }
	bool  Finite() const { return _finite; }

private:
	uint32 _n = 0u, _i = 0u, _wait = 0u;
	double _sum = 0.0;
	bool _pending = false, _finite = true;
};
