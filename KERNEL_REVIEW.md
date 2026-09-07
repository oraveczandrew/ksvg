# Kernel Review — what needs investigation

Status: 2026-09-06/07, based on the host (i7-7820X), x86-32 emulator, OnePlus 11
arm64 AND armeabi-v7a (32-bit) benchmark tables in `BENCHMARKS.md`. The ARM32
lighting build blocker is resolved (2026-09-07) and the 32-bit device benchmark
has run.

Marker legend is the same as in `BENCHMARKS.md`: 🚀 >9x, 🟢 >1x, 🔴 <1x (slower than scalar).

---

## 1. Blockers (compile errors)

### 1.1 ~~`lighting/lighting_distant_diffuse_armv7a_neon.S` does not assemble on ARM32~~ ✅ RESOLVED

The file used NEON quad registers **q16–q25** (AArch64-only; ARMv7 NEON has
q0–q15), a Thumb-only `cbz`, and invalid `vdup.32 q, s` scalar syntax, which
failed the `armeabi-v7a` target of `libksvgblur`.

**Fix applied** (2026-09-07): the file was rewritten as a valid ARMv7 kernel
(`.arm`, `.fpu neon`, all register types in q0–q15):
- register map: q4=`ss`, q5=`1/invDx`, q6=`1/invDy`, q7=`k`, q8–q10=`l, m, n`
  direction, q11–q13=`r, g, b`, q14=`1.0f`; scratch q0–q3, q15.
  q4–q7 (d8–d15) are callee-saved → preserved via `vpush {d8-d15}`, so
  prologue is `push {r4-r11,r12,lr}` + `vpush {d8-d15}`; stack args move to
  `[sp,#104]` (count) / `[sp,#108]` (params).
- per-output `ss` scaling (`h = alpha*ss`) exactly as the verified x86 SSE2
  kernel, **two** `vrsqrts` Newton refinements (matches the legacy ARM32 C++
  NEON reference), rounding via `vcvt.u32.f32` (round-nearest ties-even ==
  Kotlin `roundToInt()`), pack via `vshl`/`vorr` + `vdup.32 q0, r6` with
  r6 = `0xFF000000`.
- Verified: assembles with NDK clang (`-target armv7a-linux-androideabi24`),
  and `./gradlew :filtering:externalNativeBuildDebug -PfilterAbis=armeabi-v7a`
  succeeds; `ksvgLightingDistantDiffuseRowNeon32` is present in the produced
  `libksvgblur.so`.
- **Still to do:** ARM32 device parity/runtime test (the byte-exact parity suite
  needs a 32-bit device/emulator; algorithmic ordering matches the 18/18-green
  x86 SSE2 bit-exact reference, so bit-parity risk is confined to VFP vs SSE
  float/double rounding).

---

## 2. Performance regressions (genuine SIMD kernels, not fallbacks)

Every row below is a **real vector kernel** (verified in the C++ dispatch: the
`applyForced(…, neon64/ssse3)` paths are real code, not scalar disguised), except
2.4 which **is** a silent scalar fallback.

### 2.1 Device (OnePlus 11, arm64 `neon64`) — 5 real regressing kernels

| Kernel | 512 | 2048 | Source file |
| :--- | :---: | :---: | :--- |
| UnLinearize | 0.05x | 0.05x | `component_transfer/unlinearize.cpp` `lutLookupNeon64`/`applyNeon64` (slow NEON LUT) |
| ComponentTransfer | 0.08x | 0.08x | `component_transfer/component_transfer.cpp` `applyNeon64` |
| ArithmeticComposite (linear) | 0.34x | 0.34x | `arithmetic_composite/arithmetic_composite_neon.cpp` (linear = LUT conversions) |
| DisplacementMap | 0.61x | 0.61x | `displacement_map/displacement_map.cpp` `applyNeon64` |
| Lighting | 0.97x | 0.98x | `lighting/lighting_distant_diffuse_aarch64_neon.S` (≈ no gain) |

Worth noting: **Lighting was fixed on x86** (host 15–16x, x86-32 rebuild 38–55x,
parity 18/18 green) but the **AArch64 NEON row gives nothing**. This is the most
suspicious one: the x86 fix discovered the kernel was mathematically wrong
(extra `/255`); the AArch64 row should be re-checked for both correctness and
register/loop efficiency — with scalar it is the *same speed*, which is
consistent with either a broken-but-fallback path or a simply non-optimal kernel.

### 2.2 Device (OnePlus 11, armeabi-v7a `neon32`) — benchmark ran 2026-09-07

| Kernel | 512 | 2048 | Note |
| :--- | :---: | :---: | :--- |
| UnLinearize | 0.01x | 0.02x | worst of all platforms; `lutLookupNeon32` |
| ComponentTransfer | 0.02x | 0.03x | `applyNeon32` |
| ArithmeticComposite (linear) | 0.22x | 0.22x | LUT conversions |
| Lighting | 0.99x | 0.99x | newly fixed ARM32 kernel ≈ scalar (see 1.1) |
| Turbulence | 6.69x | 6.69x | 🟢, well below arm64's 20x |

Winners here: Morphology 139–143x, GaussianBlur 42x, ConvolveMatrix 14–18x,
ArithmeticComposite (non-linear) 18–23x. `DisplacementMap` has **no** ARM32 SIMD
backend (scalar only) — same situation as x86-32. The 512px rows for
ArithmeticComposite (non-linear) neon32, DisplacementMap scalar, GaussianBlur
neon32 and Morphology neon32 were flagged UNSTABLE by the harness.

### 2.3 Emulator (x86-32, `ssse3`)

| Kernel | 512 | 2048 |
| :--- | :---: | :---: |
| UnLinearize | 0.10x | 0.07x |
| ComponentTransfer | 0.03x | 0.03x |
| ArithmeticComposite (linear) | 0.17x | 0.17x |

Same three LUT-heavy kernels, worse relative to scalar on 32-bit.

### 2.4 Host (i7-7820X, x86-64 `ssse3`)

| Kernel | 512 | 2048 |
| :--- | :---: | :---: |
| UnLinearize | 0.58x | 0.61x |
| ComponentTransfer | 0.20x | 0.21x |

(The `avx2`/`avx512` rows for these kernels are fine — this is a `pshufb`
path problem.)

**UnLinearize SSSE3 A/B/C structural study** — all three variants gated by the
mandated correctness suite (random 256-entry LUTs, random pixel data, widths
not divisible by 4 or 16, in-place `src == dst` and out-of-place, byte-exact
vs `KotlinKernels.unLinearize`):

| variant | structure | hot-loop ops/px | 512x512 | 2048x2048 |
| :--- | :--- | ---: | :---: | :---: |
| A (baseline) | 4 px/iter, 328-byte stack-cached LUT rows, callee-saved XMM | — | 0.52x | 0.52x |
| B (winner) | 16 px / 4-vector static unroll, no stack, alpha in regs | 31.25 | 0.59x | 0.59x |
| C | 8 px / 2-vector, same microstructure as B | ~31.25 | 0.59x | 0.60x |

Production now ships the **B** layout (`ksvgUnlinearizeApplySsse3`, unified
benchmark 0.58x / 0.61x). Removing the full structural overhead — stack LUT
cache, alpha round-trips through memory, runtime index dispatch, and all
callee-saved xmm8..xmm15 — bought only ~13% (0.52x → 0.59x); the unroll factor
(B vs C) is noise. **All variants remain well below 1.0x, so the bottleneck is
the 16-row PSHUFB cascade itself, not its surroundings.** The mandated op audit
confirms it: the B hot loop is 500 instructions per 16 px = 31.25 ops/px, of
which the row-cascade core costs ~17 (4× `pshufb`, 4× `pcmpeqb`, 5× `pand`,
4× `por` per pixel) plus 8.25 LUT-row loads / rowid advances and 4.75 `movdqa`
copies — versus **19 ops/px** for the Release scalar loop (which needs no
shifts thanks to `movzbl %dh/%dl` indexing). The SSSE3 path does ~1.6× the
work of a cache-hot 256-byte scalar byte gather and gets nothing back because
the LUT never misses. Verdict: stop micro-optimizing the 16-row pshufb scheme
(A/B/C are final for it); the next step is a **different SSSE3 lookup
algorithm** or dropping the SIMD path for this kernel (§2.6 candidate (a)).

### 2.5 Silent fallback that pollutes the table

- **Morphology `ssse3` on x86-32**: `morphology.cpp` `default:` → `applyScalarPixel`.
  There is **no** i386 ssse3 kernel; the row reads 0.92x 🔴 but is really scalar.
  The emulator table already carries a `Note` column for this. Recommendation:
  stop advertising/benchmarking a backend that does not exist (or make the
  bench label rows as `scalar-fallback`).

### 2.6 Common root cause (candidates)

UnLinearize / ComponentTransfer / Arithmetic(linear) are all **table-LUT kernels**:
the "vector" path is a `pshufb`/NEON `vtbl` per-byte lookup that is slower than
the cache-hot scalar loop with 256-entry tables. Single 256-byte LUT and scalar
alignment make the SIMD version pointless. For UnLinearize the A/B/C structural
study (§2.4) has now ruled out surrounding overhead and pinned the pshufb
row-cascade itself as the cost. Candidates: (a) drop SIMD and use scalar for
these three; (b) reduce work (e.g. only re-map changed components);
(c) verify Automatic vs forced path selection; (d) for UnLinearize, research a
*different* SSSE3 lookup algorithm (the 16-row pshufb cascade is final).
Clear decision + parity rerun is needed.

---

## 3. Winners (no action)

Morphology (18–20x host, 103–105x x86-32 `sse2`, 101–117x arm64, 139–143x arm32),
GaussianBlur (1.8–2x host, 55–57x arm64, 42x arm32), Turbulence (2.1–2.6x host,
20x arm64, 6.7x arm32), ConvolveMatrix (4–8x host, 17–19x arm64, 14–18x arm32),
ArithmeticComposite (non-linear) (1.5–3x host, 18–19x arm64, 18–23x arm32),
Lighting x86 only (15–16x host; 38–55x x86-32).

---

## 4. Parity / test coverage gaps to close

- **ARM32 parity suite**: unblocked by the 1.1 fix — the 32-bit **benchmark** has
  run (`-PfilterAbis=armeabi-v7a`), but the **parity** classes still need a
  device run (`-Pandroid.testInstrumentationRunnerArguments.class=…` with the
  10 `*NativeParityTest` classes).
- **Device (arm64) parity**: not confirmed green in this session — the full
  `connectedDebugAndroidTest` was aborted right after the benchmark finished.
  Recommended: `-PfilterAbis=arm64-v8a` + the 10 `*NativeParityTest` classes.
- **Emulator parity tail**: x86 parity was run as part of the aborted suite;
  the 152 logged tests showed no failures, but the final XML report never
  completed. Re-run the parity classes directly via
  `adb shell am instrument` (`-e class …` with all 10 parity classes,
  excluding `KernelPerformanceDeviceBenchmark`) to get a clean, complete result.

---

## 5. Minor / infrastructure nits

- `lighting/lighting_distant_diffuse_i386_avx2.S` + `…_i386_avx512.S` are WIP
  drafts, explicitly excluded from `CMakeLists.txt` (`lighting.cpp` dispatch is
  guarded to `__x86_64__`). Decide: finish or delete.
- Host benchmark writes `tmp/benchmarks_host_.csv` (trailing underscore):
  `build.gradle.kts` forwards the unset `benchmark.kernel` as an empty string, so
  `suffix = "_"`. Cosmetic; fix the property-forwarding.
- The x86-32 row ordering of the emulator table is alphabetical, matching the
  host table after the reorder (good).

---

## 6. Prioritized action list

1. ~~**Blocker**: unblock `armeabi-v7a` lighting — obtain the correct ARM32 NEON
   source or exclude the file (scalar fallback).~~ ✅ done via in-place ARM32
   rewrite (see 1.1); 32-bit benchmark also ran (see 2.2). Remaining task is the
   ARM32 device parity run.
2. Device neon64 regressions (UnLinearize, ComponentTransfer, Arithmetic-linear,
   DisplacementMap, Lighting): investigate/fix or disable + rerun parity.
3. `ssse3` x86 regressions for the same LUT kernels.
4. Classify "silent fallback" rows in the bench harness instead of reporting 🔴.
5. Close parity gaps: arm64 device suite, emulator parity via `am instrument`.
6. Nits: i386 AVX-512 lighting drafts, `benchmarks_host_.csv` naming.