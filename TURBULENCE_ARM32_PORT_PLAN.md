# feTurbulence ARM32 (armeabi-v7a) Kernel — Implementation PLAN

**Date:** 2026-09-05
**Report / background:** `TURBULENCE_ARM32_PORT_REPORT.md`
**Source kernel:** `filtering/src/main/cpp/turbulence/turbulence_noise_neon64.S` (`turbulence64Asm`)
**Goal:** a bit-exact NEON32 turbulence kernel that participates in the existing
`TurbulenceNativeParityTest` pipeline and is meaningfully faster than the ARM32
scalar C++ path.

---

## 1. Strategy decision (adopted)

**Track 1 (this plan, production): Strategy A — scalar FP64 VFP kernel,
2-pixel interleaved, bit-exact.**

- Keeps the project's bit-exact parity contract intact (parity tests unchanged).
- VFPv3 non-fused `vmla.f64` mirrors the `-ffp-contract=off` reference — no
  rounding-mode risk.
- Realistic gain: **≥1.3×** over ARM32 `applyScalar` (geometry sharing,
  branchless fabs, tighter pack).

**Track 2 (explicitly OUT of this plan): Strategy B — FP32 NEON.** It is the
higher-throughput path but **fails bit-exact parity**; it requires a product
decision to relax the parity gate. Do not start it until Track 1 lands and is
measured, and only with a defined tolerance + max-drift assertion.

---

## 2. Deliverables (files)

| File | Action | Content |
|---|---|---|
| `filtering/src/main/cpp/turbulence/turbulence_noise_neon32.S` | **new** | ARM32 scalar-FP64 port (this is the bulk of the work) |
| `filtering/src/main/cpp/turbulence/turbulence_asm32.h` | **new** | `Turbulence32AsmArgs` + `static_assert` offsets + `extern "C" turbulence32Asm` |
| `filtering/src/main/cpp/turbulence/turbulence_arm.cpp/.h` | **modify** | `applyNeon32(...)` under `#if defined(__arm__)`; header decl |
| `filtering/src/main/cpp/turbulence/turbulence_tables.h` | **modify** | `Arm32LatticeTables` + `initArm32Tables` under `#elif defined(__arm__)` (twin of the arm64 block, identical body) |
| `filtering/src/main/cpp/turbulence/turbulence.cpp` | **modify** | advertise + dispatch `SIMD_BACKEND_NEON32` on `__arm__` in `nativeBackendForAbi` / `apply` / `applyForced` |
| `filtering/src/main/cpp/CMakeLists.txt` | **modify** | `TURBULENCE_SOURCES` for `armeabi-v7a` |
| `TurbulenceValidationCorpus.kt` (`testFixtures`) | **modify** | add negative-coordinate cases (floor-guard coverage) |
| `TURBULENCE_ARM32_WORKLOG.md` | **new** | problem-specific work log (per AGENTS convention) |

**Do NOT touch:** `turbulence_noise_neon64.S`, `turbulence_asm64.h`, the
AArch64/x86 kernels, the shared table builders' numeric logic, or any Kotlin
parity/corpus semantics beyond adding cases. Keep AArch64 and AArch32 as
**separate .S files + separate wrappers** on the same C++ reference.

---

## 3. Architecture checklist / build wiring

### 3.1 CMakeLists.txt
```cmake
if(ANDROID_ABI STREQUAL "armeabi-v7a")
    set(TURBULENCE_SOURCES turbulence/turbulence_noise_neon32.S)
endif()
```
`-mfpu=neon` already arrives via `BLUR_NEEDS_NEON` (`CMakeLists.txt:104-106`);
`.fpu neon` in the .S is authoritative for the integrated/Clang assembler.

### 3.2 turbulence.cpp dispatch
```cpp
// nativeBackendForAbi():
#elif defined(__arm__)
    backends |= SIMD_BACKEND_NEON32;
// apply()/applyForced():
#elif defined(__arm__)
    if (simdBackend == SIMD_BACKEND_NEON32) { applyNeon32(...); } else { assert(false && "unsupported"); }
```

### 3.3 Tables
Copy the arm64 block: `Arm32LatticeTables` (`selector32` + `gradPackedX/Y[514][4]`)
and `initArm32Tables` (identical body to `initArm64Tables`) under
`#elif defined(__arm__)`. Same byte layout → the .S uses the same loads.

### 3.4 turbulence_asm32.h — exact ARM32 struct offsets
Compute from the field order (4-byte pointers, 8-byte double alignment):

| Field | ARM32 offset | (AArch64 for contrast) |
|---|---|---|
| `selector32` | 0 | 0 |
| `gradPackedX` | 4 | 8 |
| `gradPackedY` | 8 | 16 |
| `pixels` | 12 | 24 |
| `width` | 16 | 32 |
| `clipLeft` | 20 | 36 |
| `clipTop` | 24 | 40 |
| `clipRight` | 28 | 44 |
| `clipBottom` | 32 | 48 |
| `periodX` | 36 | 52 |
| `periodY` | 40 | 56 |
| `octaves` | 44 | 60 |
| `fractal` | 48 | 64 |
| *(pad 4)* | — | 68 |
| `baseFrequencyX` | 56 | 72 |
| `baseFrequencyY` | 64 | 80 |
| `invCanvasScaleX` | 72 | 88 |
| `invCanvasScaleY` | 80 | 96 |
| `userLeft` | 88 | 104 |
| `userTop` | 96 | 112 |
| `unitSizeX` | 104 | 120 |
| `unitSizeY` | 112 | 128 |
| **sizeof** | **120** | 136 |

Define these as `.equ` in the .S **and** as `static_assert`s in the header;
the asserts are the tripwire against copying AArch64 offsets.

---

## 4. The .S port — mapping from `turbulence_noise_neon64.S`

Port structure section-by-section (line refs are to the NEON64 file). Keep the
same algorithm and identical FP ops; only the encoding/registers change.

| AArch64 section | NEON64 lines | ARM32 approach |
|---|---|---|
| prologue / callee-save | 100-105 | `push {r4-r11, lr}` + `vpush {d8-d15}`; keep SP 8-aligned before the vpush (pad the GPR frame) |
| arg loads + fabs sign mask | 107-124 | `mov`/`vmov d, r, r` build `0x8000000000000000`; conditional `movne r_hi, #0` for fractal → `vbic.f64` path |
| row setup (py0, curtly, fxBase, fxStep, ctlx) | 130-196 | identical scalar VFP; reload per-row constants from `r0` (as AArch64 does) |
| pixel pair loop | 202-231 | same 2-px condition + `add/cmp/bge` on word counters |
| octave loop, shared Y geometry | 232-272 | same, scalar: `fcvtms` → truncating VFP convert (§4.1), `vbic.f64` smoothstep |
| P0 X geom / stitch / perm | 274-323 | ARM GPR loads `ldr r, [rbase, ridx, lsl #2]`; stitch `cmp/csel` → `cmp` + IT (`movhs`/`subhs`) or branch |
| P0 gradients + dot + lerp + fabs + accumulate | 324-406 | scalar `vldr`/`vldm` doubles; 4 × `vmul/vmla.f64` per corner × 2 channel-pairs; `vbic.f64`; `vmla.f64` into `d0..d3` (P0) |
| P1 (reload by0/by1, reuse geometry) | 408-547 | restore S_BY0/S_BY1; gradient loads + dot/lerp again; accumulate `d4..d7` |
| octave coordinate update (doubles, stitch width/height doubles) | 549-577 | scalar `vadd.f64 d,d,d`; `lsl` for stitch dims |
| pack 2 px (SIMD) | 579-690 | scalar pack per pixel — reuse the AArch64 tail `pack_single` GPR-clamp pattern (§4.3) |
| tail single pixel | 696-962 | port verbatim (scalar already) |
| epilogue | 964-974 | restore + `vpop {d8-d15}`, `pop {r4-r11, pc}` |

### 4.1 Floor (the one non-mechanical bit)

- AArch64 uses `fcvtms` (round toward −∞). ARMv7 VFP has **no floor
  conversion** (directed-rounding `VCVT{A,N,P,M}` are Armv8-only).
- Inputs are `+4096`-biased; for `t ≥ 0`, `floor(t) == trunc(t)` — use the
  VFP fp→s32 **truncating** convert, then `r = t − (double)b`.
- `t < 0` (huge negative `userLeft/userTop` × high freq) requires the guard:
  `i = round_nearest(t); d = t − i; if (d < 0) { i -= 1; } r = d < 0 ? d+1 : d`.
  Route through it with a single sign test on `t`.
- **Action item during Phase 1:** confirm on-device which VFP mnemonic
  (`VCVT` vs `VCVTR`) truncates toward zero — sources disagree (ddi0406c decode
  vs ARMv7-M UG). The new negative-coordinate corpus cases will catch a wrong
  choice automatically.

### 4.2 Register allocation (Strategy A)

| Regs | Role |
|---|---|
| `d0..d3` | **P0 sums ch0..3** (persist across octaves) |
| `d4..d7` | **P1 sums ch0..3** (persist across octaves) |
| `d8..d13` | callee-saved geometry: `rx0, rx1, ry0, ry1, sx, sy` |
| `d14, d15` | optional extra callee-saved slots if needed (spare) |
| `d16..d31` | scratch: `fx0, fy, curtlx0, curtly, ratio`, row constants, gradient staging |

| GPRs | Role |
|---|---|
| `r0` | **args pointer (keep live the whole function)** |
| `r1` | fractal flag |
| `r2` | output pixel cursor |
| `r3, r4` | `gradPackedX`, `gradPackedY` base |
| `r5` | `selector32` base |
| `r6` | row counter `y` |
| `r7` | octaves counter |
| `r8` | column counter `x` |
| `r9` | `clipRight` |
| `r10, r11` | stitch width, stitch height (doubled per octave) |
| `r12` | perm-index / address scratch |
| `r14` | scratch (after `lr` is pushed) |

Stack slots (8-aligned frame, mirror the AArch64 `S_*` names): `S_PIXELS`,
`S_FX_BASE`, `S_FX_STEP`, `S_CTLX_BASE`, `S_PY0`, `S_CTLY`, `S_FX1`,
`S_CTLX1`, `S_BY0`, `S_BY1`.

**Hard rules:** sums never leave `d0..d7`; constants NEVER placed in a register
also used as scalar scratch (the `d30/v30` trap from the NEON64 kernel);
`load → compute → consume → reuse`; keep the two-pixel Y-geometry sharing.

### 4.3 Pack (both pixels)

Per-pixel scalar pack equivalent to AArch64 `pack_single` (NEON64:896-949):
`vmul/vadd.f64` scale+offset, add 0.5, truncate to s32, GPR clamp
(`cmp; it lt; movlt r, #0` / `cmp r, #255; it gt; movgt r, #255`), `orr` the
byte lanes, `str` ×2. This is bit-identical post-clamp (report §3.4) and
avoids any 8B-aligned store requirement.

---

## 5. Corpus additions (floor-guard + FP edge coverage)

Add to `TurbulenceValidationCorpus`:
- `neg-coord`: `userLeft=-10000.0, userTop=-8000.0, baseFrequency=1.0,
  unitSize=1.0` so `pxd+4096 < 0` — forces the `t<0` floor guard path,
  must match Kotlin bit-exactly.
- `near-zero`: tiny `userLeft/userTop` + fractional offsets to stress
  trunc-vs-floor at the zero crossing.

Both reuse the existing `Case(...)` type; no test-code changes beyond the data.

---

## 6. Build & test commands

```bash
# Fast C++ + asm compile for the 32-bit ABI only (assemble the .S early):
./gradlew :filtering:compileDebugKotlin -PfilterAbis=armeabi-v7a -Dorg.gradle.warning.mode=none
./gradlew :filtering:assembleDebug        -PfilterAbis=armeabi-v7a -Dorg.gradle.warning.mode=none

# Host parity (x86_64 host lib) — must stay green; guards against breaking the
# shared dispatch/table code:
./gradlew :filtering:testDebugUnitTest --tests "hu.oandras.ksvg.filtering.TurbulenceNativeParityTest" \
    -Dorg.gradle.warning.mode=none

# DEVICE parity — THE gate. Exercises NEON32 + SCALAR on a 32-bit build
# (works on an arm64 device too; -PfilterAbis builds a 32-bit-only APK):
./gradlew :filtering:connectedDebugAndroidTest \
    -PfilterAbis=armeabi-v7a \
    -Pandroid.testInstrumentationRunnerArguments.class=hu.oandras.ksvg.filtering.TurbulenceNativeParityTest \
    -Dorg.gradle.warning.mode=none

# Speed gate:
./gradlew :filtering:runDeviceBenchmark \
    -PfilterAbis=armeabi-v7a \
    -Pbenchmark.kernel=Turbulence -Pbenchmark.quick=true \
    -Dorg.gradle.warning.mode=none
```
Prereq: a connected device/emulator (arm64 device + `-PfilterAbis=armeabi-v7a`
is the documented path — `filtering/build.gradle.kts:48-53`).

---

## 7. Phases with exit gates

### Phase 0 — Groundwork (≈0.5 h)
- Build `-PfilterAbis=armeabi-v7a` to confirm armv7 toolchain, `-mfpu=neon`,
  and that existing ARM32 asm (`Blur_advsimd.S`, `convolve_neon32.S`)
  assembles in this checkout.
- Confirm device/serial + `runDeviceBenchmark` plumbing works (baseline scalar
  numbers captured).
- Write `TURBULENCE_ARM32_WORKLOG.md`.
- **Exit:** scalar baseline bench recorded; toolchain green.

### Phase 1 — Correctness kernel (1 px, scalar FP64) (≈0.5–1 day)
- Implement the complete .S but **without** the two-pixel interleave: per
  pixel, the full octave loop, 4 channels; plus all plumbing (§3.2-3.4).
- Purpose: lock down ABI, args layout, selector/gradient addressing, stitch,
  octave state, pack, and the floor-guard path against the Kotlin reference.
- **Exit:**
  - `connectedDebugAndroidTest` (TurbulenceNativeParityTest) **bit-exact pass**
    with the new corpus.
  - `nativeBackend()` on the 32-bit build reports `SCALAR|NEON32`
    (`getBackendsFor` → `[SCALAR, NEON32]`).
  - Host parity still green.

### Phase 2 — 2-pixel interleave + optimizations (≈0.5-1 day)
- Add: Y-geometry sharing across the pair, branchless fabs (sign mask),
  per-row constant recomputation, odd-width tail, scalar pack.
- **Exit:**
  - Same parity gate still bit-exact.
  - Speed gate: Turbulence 512²/2048² `neon32` ≥ **1.3×** the `scalar` row
    in the same bench run (mirrors how NEON64 numbers are reported).

### Phase 3 — Channel-pair blocking (optional, ≈half day)
- Process ch0-1 then ch2-3 per pixel pair (smaller live set, better L1 on the
  gradient tables). **Benchmark layout as a separate change.**
- **Exit:** parity + bench; keep only if it helps.

### Phase 4 — Track 2 decision (approx half day, GATED)
- Only after Phases 1-3: prototype the FP32 NEON 2-px inner loop, measure
  speedup + **max channel drift** over the corpus, and bring the parity-gate
  relaxation proposal to the user. Do not merge anything that changes the
  bit-exact contract without an explicit decision.

---

## 8. Risks & mitigations (execution checklist)

- [ ] VFP fp→int truncation mnemonic confirmed on target (§4.1) — else parity
      fails loudly; corpus cases cover it.
- [ ] `turbulence_asm32.h` offsets match `.equ` table (§3.4) — catch stale
      AArch64 values via the static_asserts.
- [ ] SP kept 8-aligned before `vpush`/64-bit stores (§4 prologue).
- [ ] No `vfma.f64`; no `fpscr` mutation; no fused anything (§3.4).
- [ ] Constant registers strictly separated from scalar scratch (§4.2).
- [ ] Odd-width `clipLeft` row-pointer handled (word stores only, §4.3).
- [ ] AArch64 kernel and its `.equ` table untouched.

---

## 9. Definition of done

1. `turbulence_noise_neon32.S` committed, built into `libksvgblur.so` for
   armeabi-v7a, and advertised as `neon32` by `nativeBackend()`.
2. `TurbulenceNativeParityTest` (device, forced `SIMD_BACKEND_NEON32`) passes
   **bit-exact** over the full corpus incl. new negative-coordinate cases.
3. `runDeviceBenchmark` shows `neon32 ≥ 1.3× scalar` on Turbulence 512²/2048².
4. Host parity + full `:filtering:testDebugUnitTest` green.
5. `TURBULENCE_ARM32_WORKLOG.md` records phases, measurements, decisions.