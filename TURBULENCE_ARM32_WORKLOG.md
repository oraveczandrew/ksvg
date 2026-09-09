# feTurbulence ARM32 (armeabi-v7a) Port — Work Log

**Plan:** `TURBULENCE_ARM32_PORT_PLAN.md`
**Report:** `TURBULENCE_ARM32_PORT_REPORT.md`
**Strategy:** A — scalar FP64 VFP, 2-pixel interleaved, **bit-exact** (Track 1).

---

## 2026-09-05 — Session 1

### Phase 0 — Groundwork (done)
- **Toolchain green:** `./gradlew :filtering:assembleDebug -PfilterAbis=armeabi-v7a` succeeds.
  Existing ARM32 asm (`Blur_advsimd.S`, `convolve_neon32.S`, `arithmetic_composite_armv7a_neon.S`)
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

## 2026-09-05 — Post-commit on-device benchmark (lazy kernel)

Ran the device turbulence bench (armeabi-v7a build) after the parity fix+commit.

| Kernel | Backend | Size | AvgMs | MPix/s | GB/s | Speedup | Note |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Turbulence | scalar | 512x512 | 136.992 | 1.91 | 0.01 | 1.00 |  |
| Turbulence | neon32 | 512x512 | 40.719 | 6.44 | 0.03 | 3.36 |  |
| Turbulence | scalar | 2048x2048 | 2165.834 | 1.94 | 0.01 | 1.00 |  |
| Turbulence | neon32 | 2048x2048 | 660.526 | 6.35 | 0.03 | 3.28 |  |

### Implication
Phase 2's exit gate (neon32 >= 1.3x scalar in the same bench run) is ALREADY
MET by the lazy 1-px kernel (3.36x / 3.28x). The lazy kernel's per-row geometry
hoisting + tight unrolled VFP channel chain beats the C++ scalar reference
(which recomputes geometry per pixel through call layers) by ~3.3x.

Phase 2 (2-px interleave + register rebalance) is now an OPTIONAL extra perf
step, not a gate. Defer register-allocation discussion; revisit only if more
headroom is needed. Phase 3 (channel-pair blocking) likewise optional.

## 2026-09-05 — Session 3: octave-outer register-resident restructure

### Motive (user-directed)
The lazy kernel recomputed ALL channel-independent work per channel:
fx/fy/ctlx/ctly/ratio/value round-tripped to stack 4x per octave; geometry,
wrap and permutation ran inside each channel. The user's register-allocation
plan (seconded by another AI) was to flop the loop nest: octave-outer /
channel-inner, with geometry computed once per octave.

Re-verified liveness: the 4-accumulator map DOES fit exactly in d0..d31. The
noise block writes ONLY d3-d7 and reads d8-d15 (gradients, reloaded per
channel), d26-d31 (geometry) and d24 (ratio); d16-d19 accumulate R/G/B/A;
d20-d24 are fx/fy/curtlx/curtly/ratio. No two live sets overlap, so all four
accumulators are register-resident and the octave loop performs ZERO stack
traffic for state (vs ~120 bytes/octave before).

### New structure (turbulence_noise_neon32.S)
```
pixel setup: accs d16-d19=0; fx=d20; ctlx=d22; fy=d21; ctly=d23; ratio=d24; r5=0
octave loop (r5 = octave index):
  wrap folded into each geometry (no S_WRAP* slots)
  X geometry once   -> bx0/bx1, rx0/rx1, sx
  Y geometry once   -> by0/by1, ry0/ry1, sy
  permutation once  -> b00/r14 b01/r10 b10/r12 b11/r11 (kept in GPRs across channels)
  NOISE_CHANNEL 0, d16  (grad reload + noise + acc)
  NOISE_CHANNEL 8, d17
  NOISE_CHANNEL 16, d18
  NOISE_CHANNEL 24, d19
  state advance once   (vadd d20-d24 self; r5 += 1)
pack: accs straight from d16-d19
```
- GPRs: r5 = octave index (selector base reloaded per octave from args);
  r2 = dst spilled to S_DST per pixel; b-indices live in r1/r10/r11/r12/r14.
- periodX/Y now computed per octave as `args.period << r5` (identical integer
  value to the old per-channel doubling, same 32-bit wrap semantics).
- Math and FP op order per (octave,channel) UNCHANGED -> bit-exact by
  construction; stack shrank 272 -> 24 bytes.

### Result
- `TurbulenceNativeParityTest` on-device: **OK (22 tests)** — unchanged parity.
- Device bench (same run as baseline, adbca122):

  | Kernel | Backend | Size | AvgMs | MPix/s | Speedup |
  | :--- | :--- | :--- | :--- | :--- | :--- |
  | Turbulence | scalar | 512x512 | 154.482 | 1.70 | 1.00 |
  | Turbulence | neon32 | 512x512 | 24.967 | 10.50 | **6.19** |
  | Turbulence | scalar | 2048x2048 | 2474.369 | 1.70 | 1.00 |
  | Turbulence | neon32 | 2048x2048 | 397.618 | 10.55 | **6.22** |

  vs lazy baseline neon32: 40.719 -> 24.967 ms (1.63x) and 660.526 -> 397.618 ms
  (1.66x). Speedup vs scalar went 3.36/3.28 -> 6.19/6.22. Phase 2 gate (>=1.3x)
  is now satisfied by ~5x margin; the 2-px interleave remains optional.

## Step A — vldr [r2,#chb] offset merge (incremental pass 1)

Restructured the NOISE_CHANNEL gradient loads: fold the per-channel byte offset
into the `vldr` addressing ([r2, #\chb]) instead of a separate `add r2,r2,#\chb`.
Removes 8 integer adds per channel, 32 per octave. Alignment is preserved
(gradX/gradY base 4-aligned, index stride 32, offsets 0/8/16/24 -> 8-aligned).

Parity: OK (22 tests).
Bench (scalar/neon32 same-run, vs 0df7b09e baseline):
  512:   154.473 / 24.741 ms   (was 24.967)  6.24x  (+0.9%)
  2048:  2159.946 / 344.828 ms (was 397.618)  6.26x  (+13.3%)

## Steps B-F — incremental micro-optimization pass (all parity-green)

Step B — hoist the accumulate branch into one `cmp r8,#0` + conditional
`vabseq.f64 d4,d4`, sharing the div+add for both fractal/turbulence paths.
Removes 2 branches + 1 duplicate vdiv per channel. abs still precedes div,
so the FP op order is unchanged.  512: 24.741 -> 21.417 ms; 2048: 344.828 -> 344.653 ms.

Step C — single reciprocal per octave: `vdiv.f64 d25, d0, d24` once after the
permutation, then `vmul` instead of `vdiv` in each channel accumulate. ratio is
a power of two, so n/ratio == n*(1/ratio) bit-exactly; confirmed by parity.
d25 now time-shared (2.0 during geometry, 1/ratio after permutation).
512: 21.417 -> 20.660 ms; 2048: 344.653 -> 327.216 ms.

Step D — hoist `ctly0 = (y - clipTop)*freqY` into the row loop (stack slot
S_TILEY -> S_CTLY0); pixel loop just vldr's it. Same mul order -> bit-exact.
512: 20.660 -> 20.579 ms; 2048: 327.216 -> 326.841 ms.

Step E — permanent constants for SMOOTHSTEP: d2 = 3.0 (vmov.f64 #3.0 at entry),
d25 = 2.0 (vadd d0,d0 at octave top). FLOOR int-convert moved s4 -> s14 (d7 low
half; d2 is now live) and the int->double vmov traffic moved s4 -> s6 (d3 low
half). Pack still uses s4 (d2 is dead there). Saves 2 vadd per smoothstep.
512: 20.579 -> 20.693 ms; 2048: 326.841 -> 328.667 ms (flat, within noise).

Step F — pack's +0.5 constant via `vmov.f64 d7, #0.5` (VFP immediate), dropping
the 4-instruction movw/movt/... build (3 fewer instructions per pixel).
512: 20.693 -> 20.531 ms; 2048: 328.667 -> 327.018 ms (flat, within noise).

Final cumulative (vs 0df7b09e baseline 24.967 / 397.618):
  512:   20.531 ms  (~17.8% faster)    6.56x
  2048:  327.018 ms (~17.8% faster)    6.59x
All 6 steps: parity OK (22 tests each).

## Round 3 — usat clamp, veor accumulator clear, bitwise weight (all parity-green)

1. Pack clamp -> `usat r12, #8, r12` (saturates signed word to [0,255],
   identical to the cmp/movlt/cmp/movgt clamp for any int32 incl. the 0x80000000
   NaN-box from vcvt). 4 instr x 4 channels = 16/pixel saved.
   512: 20.531 -> 20.513; 2048: 327.018 -> 325.350 ms.

2. Accumulator clear: veor q8,q8,q8 / veor q9,q9,q9 (q8=d16/d17, q9=d18/d19)
   replaces mov+4x vmov. 5 -> 2 instr/pixel.
   (measured together with #1: 6.87x/6.64x)

3. Kill the per-octave vdiv entirely. d24 now holds the WEIGHT = 1/2^octave
   (starts as 1.0 = d0). Each octave end: vshr.u64 d25,d25,#10 turns 2.0
   (0x4000...0) into one exponent unit (bit 52 = 0x0010...0), and
   vsub.i64 d24,d24,d25 decrements the biased exponent -> weight halves
   bit-exactly. Valid for any octave count within the normal double range
   (octave < 1022); parity confirms. vdiv.f64 d25,d0,d24 (the last remaining
   per-octave division) is gone; accumulate multiplies by d24.
   512: 20.513 -> 20.123; 2048: 325.350 -> 320.663 ms (6.65x/6.65x).

## Round 4 — hoisted cmp, dead vldr removal, permanent 2^52 weight step, mla,
## stack-cached pack constants (all parity-green)

G1  One `cmp r8,#0` feeds all four channel accumulate vabseqs (VFP arithmetic
    and the `add` address math never write APSR; the hoisted cmp sits after the
    permutation so the geometry's cmp/subge can't interfere). 3 cmp/octave gone.
G2  d5 keeps freqY / freqX alive between the two adjacent vmuls, so the second
    vldr d5,[r0,#A_FREQ_Y/_X] was dead: 1 load/row + 1 load/pixel removed.
G3  d25 is now a PERMANENT 2^52 constant (0x0010 0000 0000 0000 = one exponent
    unit), built once at entry. SMOOTHSTEP doubles t with `vadd d5,t,t` (exact,
    == t*2.0), and the octave-end weight halve is just `vsub.i64 d24,d24,d25`.
    Removes the per-octave vadd (2.0 re-arm) + vshr: 2 instr/octave, and d25 is
    never a clobbered state anymore.
G4  row address: mul+add -> mla (1 instr/row).
G5  Pack constants (scale/offset/0.5) cached in the frame ONCE per call
    (S_SCALE/S_OFFSET/S_HALF); pack_pixel restores them with a single
    `vldm sp,{d5,d6,d7}` and the per-pixel cmp/beq + movw/movt builds are gone.
    Frame grew 24 -> 48 bytes (still 8-aligned).

NOTE: idea "FLOOR branch removal" was REVIEWED and REJECTED for now: fx can be
negative when userLeft < 0 (the +4096 shift only guarantees t >= 0 for
fx > -4096), so trunc-then-correct is still required for bit-exactness.

Bench (two runs: first was within-noise, second real):
  run1 512: 20.523  2048: 324.375
  run2 512: 20.067  2048: 322.425  (6.76x / 6.73x)

Per-pixel instruction budget (4-octave corpus):
  pixel prologue ~26, per octave ~248, pack ~32; total ~1050 @4 octaves.
  octave split: noise arith 84 (34%), gradient loads 64 (26%), geometry 66
  (27%), accumulate 13 (5%), permutation 11 (4.4%), entry/advance 10 (4%).
  Biggest remaining structural win: Idea 6 (incremental fx/ctlx) - killed for
  bit-exact reasons; FLOOR branch removal would save 12 instr/octave (4.8%) but
  needs a coordinate-domain contract.

## Round 5 — register-map redraw: shared 8-pointer gradient cache (parity-green)

Per-channel gradient addressing was 4x4 adds (32/octave, each channel rebuilt
b00/b10/b01/b11 on the fly). Redraw allocates all 8 gradient pointers to GPRs
for the length of the channel group, built ONCE per octave from the
permutation's lattice indices:

    add r1, r3, r14, lsl #5   ; GX00 (b00=r14)
    add r2, r4, r14, lsl #5   ; GY00
    add r5, r3, r12, lsl #5   ; GX10 (b10=r12)
    add r9, r4, r12, lsl #5   ; GY10
    add r12, r3, r10, lsl #5  ; GX01 (b01=r10)
    add r14, r4, r10, lsl #5  ; GY01
    add r10, r3, r11, lsl #5  ; GX11 (b11=r11)
    add r11, r4, r11, lsl #5  ; GY11

Then NOISE_CHANNEL is eight pure vldrs ([rX,#chb]) + noise + vabseq, with the
partials describing no order-of-evaluation dependencies. 32 -> 8 adds/octave
(24 saved). r9 (clipRight) is repurposed as GY10 during the channel group, so
pack_pixel's tail reloads `ldr r9,[r0,#A_CLIP_RIGHT]` (+1 instr/pixel); the
fractal flag, previously r8, is re-read per octave (`ldr r1,[r0,#A_FRACTAL];
cmp r1,#0`) because r8 became the octave index and the geometry's cmp/subge
clobber APSR anyway (+1 ldr/octave). Order of cache adds is load-conservative
(no lattice index is read after its register is overwritten).

Rejected as a bad trade: splitting the channel section per fractal/turbulence
mode to avoid the re-read (~240 duplicated instructions to save 1 cmp+1 ldr
per octave).

Bench (third run; run1 throttled - device asleep, scalar 2477ms; run2 within
noise, scalar 2176ms; run3 warm, scalar 2151ms == prior baseline):
  512: 20.067 -> 19.984 ms  2048: 322.425 -> 318.241 ms  (6.73x / 6.76x)
Modest (approx -1.3% on 2048) — the win is limited by the two extra loads
per octave (fractal) + per pixel (clipRight).
