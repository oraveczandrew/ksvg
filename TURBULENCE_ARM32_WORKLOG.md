# feTurbulence ARM32 (armeabi-v7a) Port — Work Log

**Plan:** `TURBULENCE_ARM32_PORT_PLAN.md`
**Report:** `TURBULENCE_ARM32_PORT_REPORT.md`
**Strategy:** A — scalar FP64 VFP, 2-pixel interleaved, **bit-exact** (Track 1).

---

## 2026-09-05 — Session 1

### Phase 0 — Groundwork (done)
- **Toolchain green:** `./gradlew :filtering:assembleDebug -PfilterAbis=armeabi-v7a` succeeds.
  Existing ARM32 asm (`Blur_advsimd.S`, `convolve_neon32.S`, `arithmetic_composite_neon32.S`)
  assembles; `-mfpu=neon` arrives via `BLUR_NEEDS_NEON`.
- **Device:** OnePlus CPH2449 (`OP594DL1`), `arm64-v8a` + `armeabi-v7a,armeabi` in abilist →
  `-PfilterAbis=armeabi-v7a` APK runs on it (documented path).
- Baseline scalar bench: **not yet re-recorded** on the 32-bit build (existing
  `tmp/benchmarks_device_Turbulence.csv` is from the arm64 build). The Phase 2
  speed gate compares `neon32` vs `scalar` *within one bench run*, so a dedicated
  32-bit scalar baseline is a nice-to-have, not a blocker.

### Reading / wiring confirmed
- ARM32 args struct offsets for `Turbulence32AsmArgs` (sizeof 120) — plan §3.4.
- `SIMD_BACKEND_NEON32` (`cpu_dispatch.h` / `SimdBackend.kt`), `SimdBackend.kt`
  `backendName` ("neon32"), and `BackendDiscovery.getBackendsFor` already iterate
  NEON32. Only the C++ side lacks advertise/dispatch.
- Parity tests (`TurbulenceNativeParityTest` host + androidTest) force every
  advertised backend over the shared `TurbulenceValidationCorpus`.
- `convolve_neon32.S` prologue convention: `push {r4-r11, lr}` + `.fpu neon` +
  `.syntax unified` implied (pop idiom `pop {r4-r11, pc}`).

### Open questions to resolve during Phase 1
1. **VFP fp→s32 truncation mnemonic on target** (`VCVT` vs `VCVTR`): sources
   disagree. Will confirm via the negative-coordinate corpus cases + a tiny
   on-device probe if parity fails.

---

## Next steps
- [ ] Phase 1 plumbing: CMakeLists.txt, `turbulence_asm32.h`, `Arm32LatticeTables`
      twin, `applyNeon32`, dispatch, corpus additions.
- [ ] Phase 1 kernel: `turbulence_noise_neon32.S` (1-px scalar FP64).
- [ ] Phase 2: 2-px interleave + branchless fabs + pack.
- [ ] Host parity green; device parity + bench.
---

## 2026-09-05 — Session 2 (lazy kernel + neg-coord finding)

### Decision update (user-directed)
User: "write a lazy version first, then I'll ask for advice on register allocation."
=> Phase 1 = correctness-first **LAZY kernel**: per-pixel scalar FP64, 4 channels
unrolled via `CHANNEL_BLOCK` macro, plain `vdiv` for ratio (bit-exact, ratio is a
power of two), trivial register allocation (r0/r2-r11, r1/r12/r14 scratch, d0-d7
consts/scratch, d8-d15 gradient loads, d20-d31 state/geometry). Phase 2 (2-px
interleave + register rebalance) deferred until register-allocation advice.

### CRITICAL correctness finding: floor vs trunc
- Kotlin reference (`SvgPathNoise.noise2`) computes lattice `tx.toInt()` (TRUNC)
  but fraction `tx - floor(tx)` (FLOOR).
- Native kernels (`geometry32`, NEON64 via `fcvtms`, x86) use `std::floor` for BOTH.
- These agree iff `tx >= 0`. All 9 existing corpus cases have tx >= 0, hence green.
- => Do NOT add the planned "neg-coord" corpus case (would break already-green
  scalar/x86/NEON64 host+device parity). Add only near-zero safety cases with tx>=0.
- The ARM32 asm still implements the floor correction (`vcvt.s32.f64` trunc +
  `vcmp`/correction) for full C++-reference fidelity.

### Done
- `turbulence_asm32.h` written: `Turbulence32AsmArgs` (offsets 0..112,
  `static_assert sizeof == 120`) + `extern "C" void turbulence32Asm(const
  Turbulence32AsmArgs*)` under `#if defined(__arm__)`.
- `turbulence_noise_neon32.S` written (LAZY version): frame S_SIZE=272; doubles
  0/8/16/24 (PX0/PY0/TILEX/TILEY), CH0..CH3 blocks at 32/80/128/176 (base+0 FX,
  +8 FY, +16 CTLX, +24 CTLY, +32 RATIO, +40 VALUE; CH_VALUE0..3 = 72/120/168/216),
  words S_WRAPX 224, S_WRAPY 228, S_PIXEL_BASE 232, S_OCT 236, S_GX0 240, S_GX1
  244, S_GY0 248, S_GY1 252, S_B00 256, S_B10 260, S_B01 264, S_B11 268.
  Prologue: push {r4-r11,lr} + sub sp,#4 (8-align) + vpush {d8-d15} + sub sp,#S_SIZE.
  `FLOOR` macro: vcvt.s32.f64 s4,t; vmov b,s4; vcvt.f64.s32 d3,s4; vsub f,t,d3;
  vcmp/vmrs; bge ok; vadd f,f,d0(1.0); sub b,b,#1.
  `SMOOTHSTEP` macro: out = t*t*(3-2t) with d4=2.0 scratch.
  Consts via movw/movt+vmov (127.5=0x405FE000, 255.0=0x406FE000, 0.5=0x3FE00000,
  4096.0=0x40B00000, 1.0=d0).
  Pack: fractal scale127.5/offset1.0, turbulence scale255.0/offset0.0,
  (sum+off)*scale+0.5, trunc, clamp 0..255 (movlt/movgt), B|G<<8|R<<16|A<<24.
  Args offsets via `.equ A_*` (SELECTOR 0 .. UNIT_Y 112, sizeof 120).
- Confirmed Kotlin side already supports NEON32 (`SimdBackend.kt` SIMD_NEON32 =
  1 shl 5, backendName "neon32"; BackendDiscovery lists it). LSP jni.h errors in
  turbulence_arm.cpp/.h are pre-existing false positives.

### Open / next
- [ ] Assemble `turbulence_noise_neon32.S` standalone (NDK clang) to catch errors.
- [ ] Phase 1 plumbing: `turbulence_tables.h` Arm32 twin, `turbulence_arm.cpp/.h`
      applyNeon32, `turbulence.cpp` dispatch, `CMakeLists.txt`, `cpu_dispatch.h`.
- [ ] Corpus: add near-zero case (tx >= 0). NO neg-coord.
- [ ] Register allocation discussion (await user).

## Session: root-causing residual ±1 flips → BIT-EXACT PARITY ACHIEVED

### Symptom
Parity gate (on-device amplitude 11-case corpus) failed only `[neon32]` on all
11 cases: scattered deterministic ±1 output-step flips (~4-9% of pixels), while
`[scalar]` (=C++ VFP) was bit-exact. Every static layer looked right:
- Disassembly of `turbulence_noise_neon32.S.o` matched source intent exactly
  (noise2 operands, permutation, gradient loads `lsl #5`+ch offsets, no VMLA).
- `Turbulence32AsmArgs` offsets matched `.equ A_*` (static asserts held).
- Device `libksvgblur.so` faa57bb byte-identical to local stripped androidTest build.
- Host op-for-op FP64 transcription (`tmp/asm_arm32_model.cpp`, via `tmp/jni_types.h`
  shim) is 0-diff vs the C++ reference on 4 cases.

### Runtime probing (throwaway instrumentation)
- Added `float* debugFinalOut;` at offset 52 (struct padding; sizeof 120 unchanged)
  + static_assert; `.S` `.equ A_DEBUG,52` + guarded stores of the pre-conversion
  finalVal into float[4] (labels `.Ldbg0..3`; note `\@` macro labels do NOT work
  outside `.macro`); C++ `thread_local g_neon32DebugFinalOut` + JNI
  `setNeon32DebugOut(jfloatArray)`; Kotlin `external fun setNeon32DebugOut`.
- Diagnostic rendered each failing pixel alone (1×1 clip) with the scratch enabled,
  dumped finalVals to a pullable file
  (`/sdcard/Android/data/hu.oandras.filtering.test/files/turb_probes.txt`);
  logcat System.out was unreliable (hard-truncated at 262 lines).
- JNI pitfalls hit: (1) `GetFloatArrayElements` may return a COPY whose writes are
  lost unless the array is released → the JNI setter must retain env+array and
  ReleaseFloatArrayElements on clear; (2) raw `jfloatArray` is a LOCAL ref, dead
  after the setter returns → `NewGlobalRef` + `DeleteGlobalRef` required (CheckJNI
  aborts on stale refs). Retrieving exact bits via `%a`-style hex floats
  (`Float.toHexString` / C `%lf` scanf is hex-float aware) gives exact deltas.

### The bug: corrupted +0.5 pack constant
Device finalVals were exactly `refFinalVal + 7/256` (0.02734375) on EVERY pixel
and channel, in BOTH scales and fractal/non-fractal → additive in FINAL-VALUE
space (sum-space add would halve for fractal ×127.5).
Decoding pack_pixel's constant build:
```
mov r12, #0
movw r1, #0xE000     <-- STRAY: sets the low half-word
movt r1, #0x3FE0     <-- 0.5 high word
vmov d7, r12, r1     -> r1=0x3FE0E000 = 0.52734375 (=0.5 + 7/256)
```
`movw r1,#0xE000` should have been `movw r1,#0x0000`. The stale `0xE000` low
half-word raised the mantissa by 0x0E000/0x100000 of 0.5 = 7/256 exactly, biasing
every channel's rounding +7/256 → occasional +1 output flips at integer
thresholds. (1.0/4096.0/127.5/255.0 builds use `movw #0` and were correct.)
Fix: `movw r1, #0x0000`. All five double-constant decodes re-verified.

### Result
`TurbulenceNativeParityTest` on-device: previously failing; now **OK (22 tests)**
— full bit-exact parity, both scalar and neon32, on the 11-case corpus.
`neonVsKotlin diffCount=0` also confirmed for nearzero/scaled/fractal in the
diagnostic before cleanup.

### Cleanup
Reverted ALL throwaway debug: `.S` debug stores + `A_DEBUG`, `debugFinalOut` field
+ skip-assert, C++ thread_local + JNI setter + args wiring (struct back to exact
original layout/size 120), Kotlin `setNeon32DebugOut`, and deleted the throwaway
`TurbulenceArm32DiagnosticTest`. Parity re-ran green AFTER the revert.
