# UNLINEARIZE_SSSE3_WORKLOG.md

UnLinearize SSSE3 kernel micro-optimization — A/B/C structural-overhead study.

## Problem

`unlinearize_ssse3_x86_64.S` (linear→sRGB byte-LUT transfer: `dst[i] = table[channel]`,
alpha passthrough) benchmarked well below scalar on SSSE3 (≈0.5–0.6x). Earlier session
committed a broken 16-px unrolled rewrite (alpha zeroed, `pcmpeqb` clobbering the
hi-nibble vector; parity suite failed 181/294). Mandate: rewrite the hot loop to
eliminate structural overhead (stack-cached LUT rows, alpha round-trips, index
dispatch, callee-saved XMM), measure layout variants A/B/C on identical input, count
per-pixel ops, and report honestly.

## Variants

| file | symbol | structure | correctness |
| :--- | :--- | :--- | :--- |
| `unlinearize_ssse3_x86_64_vA.S` | `ksvgUnlinearizeApplySsse3vA` | committed baseline, 4 px/iter, 328-byte stack LUT cache | byte-exact |
| `unlinearize_ssse3_x86_64_vB.S` | `ksvgUnlinearizeApplySsse3vB` | 16 px / 4-vector static unroll, no stack, alpha in regs | byte-exact |
| `unlinearize_ssse3_x86_64_vC.S` | `ksvgUnlinearizeApplySsse3vC` | 8 px / 2-vector, same per-row stream | byte-exact |
| `unlinearize_ssse3_x86_64.S` (production) | `ksvgUnlinearizeApplySsse3` | now the vB layout | byte-exact |

## Results (i7-7820X, host JVM; `-Pbenchmark.kernel=UnLinearizeVariants`)

| kernel | 512x512 | 2048x2048 |
| :--- | :---: | :---: |
| scalar | 0.287 ms | 4.735 ms |
| ssse3-vA | 0.556 ms (0.52x) | 9.074 ms (0.52x) |
| ssse3-vB | 0.486 ms (0.59x) | 8.082 ms (0.59x) |
| ssse3-vC | 0.488 ms (0.59x) | 7.990 ms (0.60x) |

Unified production run (`-Pbenchmark.kernel=UnLinearize`): scalar 0.281 / ssse3
0.482 (0.58x) / avx2 0.192 (1.46x) at 512; scalar 4.653 / ssse3 7.688 (0.61x) /
avx2 3.428 (1.36x) at 2048.

## Op audit (vB hot loop, objdump)

500 instructions / 16 px = **31.25 ops/px**: pshufb 4.0, pcmpeqb 4.0, pand 5.0,
por 4.25, movdqa 4.75, paddb 3.75, movdqu (64 LUT loads + 4 px loads + 4 stores
≈ 4.5), psrlw 0.25, ptr/branch ~0.25. Scalar loop (Release, compiler): **19 ops/px**
(`movzbl %dh/%dl` indexing, no shifts). SSSE3 does ~1.6x the scalar work for a
cache-hot LUT → cannot win; unroll factor (B vs C) is noise; all <1.0x.

## Verdict

The 16-row pshufb cascade is the bottleneck, not the surrounding structure. Stop
micro-optimizing it (A/B/C done). Next candidates: (a) drop the SIMD path and use
scalar; (b) different SSSE3 lookup algorithm — see KERNEL_REVIEW.md §2.4/§2.6.

## Correctness gates (all green)

- `UnLinearizeNativeParityTest`: 294/294 (was 181 failing).
- `UnlinearizeKernelTest`: 10/10.
- `UnLinearizeVariantCorrectnessTest`: 3/3 — random LUTs/data/alpha, widths not
  divisible by 4 or 16, in-place + out-of-place, 17x4017 large buffer.

## Reproducing

- Host build: `./gradlew :filtering:buildHostNativeLib`
- Correctness: `./gradlew :filtering:testDebugUnitTest --tests *UnLinearize*NativeParity* --tests *UnlinearizeKernelTest --tests *VariantCorrectness*`
- Variant benchmark: same with `-Dbenchmark.kernel=UnLinearizeVariants -PshowTestOutput`
- Unified benchmark: `-Dbenchmark.kernel=UnLinearize -PshowTestOutput`

Inputs into `filtering/host-native/CMakeLists.txt` (vA/vB/vC + `KSSVG_HOST_BUILD`),
host-only JNI hook `UnLinearizeNative.applySsse3Variant` in `unlinearize.cpp`.
Android/NDK builds never see the variants (guarded).