# Filter Kernel Regression Fix Plan

Status: 2026-09-07. Plan for resolving the 🔴 regressing native filter kernels
listed in `BENCHMARKS.md` and `KERNEL_REVIEW.md` §2. Allies: `SIMD_KERNEL_TRICKS.md`
(transferable techniques from the 🚀 kernels) and `UNLINEARIZE_SSSE3_WORKLOG.md`
(A..E study already closed on the LUT kernels).

## Objective

Bring every advertised SIMD backend to ≥1.0x vs scalar, or explicitly disable it
(and stop advertising it) where the vector path cannot win on 128-bit registers.
Bit-exactness against the Kotlin reference is a hard gate.

## Constraints & gates (non-negotiable)

1. **Parity first, bench second.** Each change must pass its `*NativeParityTest`
   suite before any benchmark matters.
2. **Bit-exact FP**: preserve the scalar operation *order* (e.g. `x / 255.0f` is
   NOT identical to `x * (1/255.0f)` in the last ULP — do not fold without
   proving parity). Any constant-folding/secant change that alters rounding
   requires adapting the Kotlin/C++ reference and re-running parity.
3. **One step at a time.** Small, self-contained change → parity → bench on the
   same device/session. Record results in this file.
4. **No shared mutable state**, no allocation in the hot loop.

---

## WP0 — Blur x86 SIMD wiring (AHEAD of WP1/WP2; i386 variants incoming)

> **Status / priority (2026-09-07):** taken **ahead of WP1/WP2** by user request and
> **DONE** (2026-09-07): all 4 asm files wired (x86-64 + i386), Apple-guarded, host +
> NDK built, parity 14/14, bench recorded. x86_64 NDK full link still blocked by the
> **pre-existing** lighting `Size expression must be absolute` `.S` error (WP2 fixes
> it; the x86-64 blur `.S` themselves assemble under the NDK clang standalone).
> i386 variant files landed and are wired; they ship in the same per-ABI list shape.

### Background (why this package exists)

Today `GaussianBlur` on x86 is a **mislabeled composite**: `blur_x86_avx2.cpp`
is a thin C++ wrapper that just calls the *compiled-SSE* RIR kernels
(`blur_x86.cpp`). `blurIsotropicKernel` therefore runs the same C++ SSSE3
kernel whether or not AVX2 is reported — the host 1.8–2x row is the C++ SSE
path, and nothing real exercises AVX2. The new asm provides:
- `blur_x86_64_avx2.S` → `ksvgBlurVerticalAvx2_x86_64` /
  `ksvgBlurHorizontalAvx2_x86_64` (8 px/iter vertical, 8 px/iter packed
  horizontal).
- `blur_x86_64_ssse3.S` → `rsdIntrinsicBlurVFU4_K_x86_64_ssse3` /
  `rsdIntrinsicBlurHFU4_K_x86_64_ssse3` (drop-in ABI twin of the C++
  `rsdIntrinsicBlurVFU4_K`/`HFU4_K`).

The asm follows the exact RIR op order (broadcast weight → mul → add), so the
parity contract (scalar bit-exact, SIMD tail tolerance 1) is expected to hold —
verify, don't assume.

### Steps

1. **Host build** — add both `.S` to `filtering/host-native/CMakeLists.txt`
   (host x86-64 is the fast parity/bench surface). Host only builds x86-64 from
   this tree, so i386 asm is validated via the NDK emulator path (step 4).
2. **NDK build** — add per-ABI `BLUR_SOURCES` entries in
   `filtering/src/main/cpp/CMakeLists.txt`:
   - `x86_64` → the two new `.S` files;
   - `x86` → the i386 variants once provided (same list shape). Keep
     `blur/blur_x86_avx2.cpp` in `AVX2_SOURCES` only as long as a path needs
     it; once the asm covers the ABI, the wrapper can be dropped from that
     ABI's dispatch.
3. **Dispatch** (`gaussian_blur.cpp` `blurIsotropicKernel`, x86 `#else`
   branch): 
   - `detectSimdLevel() >= SIMD_AVX2` → vertical `ksvgBlurVerticalAvx2_x86_64`,
     horizontal `ksvgBlurHorizontalAvx2_x86_64` (same call shape as the current
     C++ functions);
   - else → `rsdIntrinsicBlurVFU4_K_x86_64_ssse3` /
     `rsdIntrinsicBlurHFU4_K_x86_64_ssse3`.
   - Keep the existing scalar tails (`vEnd`, `[pw-r, pw)`) as-is.
   - i386 integration: confirm the 32-bit calling-convention/ABI contract of the
     incoming files against the i386-compiled `blur_x86.cpp` symbols (stack args
     differ) before wiring the same branch.
4. **Parity** — `GaussianBlurNativeParityTest` on host (forces every advertised
   backend: scalar + SSSE3 + AVX2) must stay green (SIMD tolerance 1). For
   i386: `-PfilterAbis=x86` emulator parity run.
5. **Bench + tables** — host `-Dbenchmark.kernel=GaussianBlur`:
   ssse3-asm vs the current C++ SSE baseline (1.8–2x) and the AVX2-asm gain.
   Update `BENCHMARKS.md` host rows + `KERNEL_REVIEW.md` §3 note; record in the
   worklog.
6. **Cleanup nits** — decide fate of `blur_x86_avx2.cpp` wrapper and the
   `rsdIntrinsicBlur*_K` C++ exports (keep only what a path still calls).

### Acceptance

- [x] `GaussianBlurNativeParityTest` green on host (AVX2 + SSSE3 backends): 14/14,
      scalar bit-exact, SIMD tolerance 1.
- [x] Host x86-64 ≥ current 1.8–2x for AVX2: now **3.35x/3.77x** (512/2048);
      ssse3-asm ≥ C++ SSE baseline: 3.35x/3.78x. Old rows were the C++ SSE kernel
      masquerading as AVX2 (1.96x).
- [x] NDK `x86` build links the asm (i386 symbols present in `libksvgblur.so`;
      `x86_64` link blocked by pre-existing lighting error — WP2).
- [x] Emulator parity+bench for i386: parity 10/10 (after fixing a stack-arg offset
      bug in `blur_i386_ssse3.S` HFU4_K), ssse3 = 21.34x/24.13x.
- [x] `blur_x86_avx2.cpp` wrapper / `rsdIntrinsicBlur*_K` C++ exports fate
      (step 6 nit): **removed** — `blur_x86_avx2.cpp` + `blur_x86.cpp` deleted,
      dead `ksvgBlurVerticalAvx2` decl dropped from `simd_x86.h`, dead bare C++
      kernel decls dropped from `gaussian_blur.cpp`, CMakeLists (main + host)
      updated. All ABIs build green; host parity 14/14 preserved.

---

## WP1 — DisplacementMap neon64 (was device 0.61x, now ✅ 12.2×)

File: `filtering/src/main/cpp/displacement_map/displacement_map.cpp`
(`applyNeon64Impl`) + the arm32/neon64 `.S` kernels.

**Resolution:** the neon64 `.S` rewrite in this branch already eliminated
the scalar round-trip anti-pattern, so the neon64 path is now fast and
byte-exact. The *regression actually fixed* was in the arm32 NEON32
kernel (two register-aliasing bugs — see worklog), not the round-trip.
See "### Root-cause hypothesis" below for the original hypothesis, which
is superseded by the actual fix.

### Root-cause hypothesis

The NEON block computes `sx`/`sy` as vectors, then immediately **spills them to
the stack** (`vst1q_s32(sxa/sya)`, lines 157–161) and does four fully scalar
random gathers (lines 163–173). This is exactly the vector→stack→scalar
round-trip anti-pattern that lost the NEON convolve edges
(`NEON_EDGE_OPT_WORKLOG.md`). Since the gather is inherently memory-latency-bound
and scalar, the NEON offset math buys nothing once the spill + per-pixel
`(int)` truncation path is paid.

Also: `vdivq_f32(vcvtq_f32_u32(xPixels), v255)` divides per pixel in-loop
(§3 of the tricks doc: fold domain conversions — but see bit-exactness gate #2).

### Steps

1. **Confirm contention** — measure scalar vs neon64 on-device back-to-back with
   the `nativeBenchmark{}` harness (the 0.61x is already confirmed; skip if just
   re-verification is needed). Goal: establish whether the gap is real on THIS
   code (it is) or measurement noise.
2. **A/B: remove the round-trip.** Two candidate kernels, both parity-gated:
   - (a) Pure scalar gather with the channel-index integers produced in the
     scalar domain from the start (drops NEON entirely; the gather stays scalar
     either way). Expected: ≈1.0x — but that is the target.
   - (b) Keep NEON only for the *integer* channel extraction and the
     min/max clamp, but emit per-pixel `dst` via an indirect jump-free scalar
     path that reuses the computed `sx/sy` values held in GPRs (no `vst1q`
     bounce). Realistic only if neon remains faster than scalar in A/B (a).
   - Decision rule: pick whichever is ≥1.0x and passes `DisplacementMapNativeParityTest`;
     if neither beats scalar, disable the neon64 path and benchmark scalar.
3. **Constant folding (§3), parity-gated.** If the winning kernel uses division,
   try folding `scale * (chan/255 - 0.5f)` into precomputed `scale/255` +
   `scale*0.5` accumulators — ONLY if the parity suite proves bit-exactness with
   the reference (likely NOT, due to rounding; drop if it fails).
4. **Dispatch hygiene** — the neon64 path currently requires
   `width==mapWidth && height==mapHeight` (line 302) else silently falls to
   scalar. Keep that contract; don't resurrect a wrong fast path.
5. **Update tables**: `BENCHMARKS.md` row(s), `SvgFeatures.kt` (no change to
   feature strings — this is purely internal), and this file's result column.

### Acceptance

- `DisplacementMapNativeParityTest` green (arm64 10/10; arm32 10/10
  after fixing two register-aliasing bugs: the `d22[0]` scale-broadcast
  and the `s26`/`q6` divisor clobber).
- On-device neon64 row ≥1.0x ✅ (12.2× @ 2048², 14.2× @ 512²) —
  `BENCHMARKS.md` rows updated.
- On-device neon32 row ≥1.0x ✅ (8.2× @ 2048², 10.9× @ 512²) —
  `BENCHMARKS.md` rows updated.

---

## WP2 — Lighting arm64 (device ~0.97x vs x86-32 38–55x)

Files: `filtering/src/main/cpp/lighting/lighting_distant_diffuse_aarch64_neon.S`
(and `lighting.cpp` dispatch). Reference: `lighting_distant_diffuse_x86_64_sse2.S`
(verified, parity 18/18 green).

### Root-cause hypothesis

The x86 fix found the kernel was *mathematically wrong* (extra `/255`); once
removed, x86-32 jumped from ~3.86 MPix/s to 148 MPix/s (38x). The AArch64 row
runs at exactly scalar speed — consistent with EITHER a broken-but-fallback path
OR a plain non-optimal kernel carrying the same math defect. Must be re-checked
for both correctness and efficiency.

### Steps

1. **Math audit** — diff the AArch64 kernel's FP ops against the x86 SSE2
   reference op-for-op:
   - unroll `diff` grep scan of `fdiv`/`fmul`/`fadd`/`fmla` sequences;
   - confirm the surface-normal normalization and the output scale (the `/255`
     class of bug) match the verified x86 kernel exactly;
   - confirm the reciprocal computation (`1/invDx`, `1/invDy`) hoisted out of
     the row loop and its rounding convention matches the scalar reference
     (`roundToInt()` → ties-even, not truncate).
2. **Parity** — run `LightingNativeParityTest` (host build; on-device arm64 via
   `-PfilterAbis=arm64-v8a` + `*NativeParityTest` classes). Confirms whether the
   neon64 kernel is even reachable/used in the forced path.
3. **Dispatch check** — verify `apply()` routes to the neon row kernel and it is
   not silently falling back to `applyScalarPixel_full` during the benchmark
   (KERNEL_REVIEW §2.1 suspicion).
4. **Efficiency pass** — where the math is right, port the SSE2 micro-structure
   wins that §3/§4/§6 of `SIMD_KERNEL_TRICKS.md` enumerate (4px interleave,
   hoisted reciprocals, pre-multiplied scale, canonical ARGB pack) if the AArch64
   file misses any.
5. **Bench + table update** like WP1.

### Acceptance

- `LightingNativeParityTest` green on all advertised backends.
- Device arm64 `neon64` row ≥1.0x (target: the 10x+ the x86 path shows), or
  disabled + relabeled.

---

## WP3 — LUT trio (UnLinearize, ComponentTransfer, Arithmetic-linear)

> **STATUS: DONE ✅ (2026-09-07)** — see `REGRESSION_FIX_WORKLOG.md` for the full
> log, measurements and verification. Summary: SSSE3/NEON un-advertised for
> UnLinearize/ComponentTransfer (scalar on 128-bit, AVX2 kept — 1.69–1.95x /
> 1.02–1.09x host, all advertised backends ≥1.0x); Arithmetic-linear gated in
> production `apply()` to scalar on ARM/non-AVX2 x86 and to AVX2 where available.
> Host parity 284/284 green; NDK arm64/armv7/x86 builds pass. The one deviation
> from the plan: `runForced`/`applyForced` stays un-gated so the harness can still
> characterize the disabled SIMD kernels. Step 3 (work-reduction) and step 5
> (AVX2 hoisted LUT) were intentionally not taken — no 🔴 rows remain without them.

Files:
- `filtering/src/main/cpp/component_transfer/unlinearize.cpp`
- `filtering/src/main/cpp/component_transfer/component_transfer.cpp`
- `filtering/src/main/cpp/arithmetic_composite/arithmetic_composite_neon.cpp`

Device rows: UnLinearize 0.05x / ComponentTransfer 0.08x / Arithmetic-linear
0.34x (neon64); SSSE3 host 0.58–0.61x / 0.20x / 0.17x. **This is a closed case.**
`UNLINEARIZE_SSSE3_WORKLOG.md` proved (variants D and E) that neither the LUT
row-load count nor the compare-and-select ALU/dependency depth is the residue:
the irreducible per-vector leaf gather (16 PSHUFB + 15 blends ≈ 21.75 ALU/px) vs
19 ops/px for the cache-hot scalar loop cannot win on a 128-bit register. The
same holds for NEON `vtbl`/`vqtbl1q` paths.

→ **Do NOT keep optimizing the 16-row LUT scheme.** Follow KERNEL_REVIEW §2.6
candidate (a).

### Steps

1. **Disable the losing LUT SIMD paths on 128-bit targets only**:
   - arm64/armv7 (`neon64`/`neon32`) → scalar fallback for the three kernels.
   - x86 SSSE3 → scalar (keep AVX2/AVX-512 paths, which already win:
     1.37–2.89x).
   - Implementation: gate the SIMD dispatch behind `detectSimdLevel()` /
     `__aarch64__` width checks so the path is not advertised (update
     `nativeBackend()` bits).
2. **Parity after gate** — rerun the three parity suites (they force each
   advertised backend; with the LUT backends unadvertised, only scalar paths
   validate).
3. **Work-reduction (optional, KERNEL_REVIEW §2.6 (b))** — only re-map changed
   channels (e.g. ComponentTransfer identity tables, alpha passthrough) before
   wholesale table lookups. Purely a win if the SVG uses default/identity
   transfers; do NOT use the LUT SIMD gather for it.
4. **Re-benchmark** all three on host + device; update `BENCHMARKS.md` rows
   (expect the neon64/neon32/ssse3 🔴 rows replaced by `scalar` or removed).
5. **Wider-vector follow-up (optional, §2.6 (d))** — AVX2 hoisted LUT (~5 ops/px)
   is the only line with real >1.0x headroom; track as a separate task only if
   wanted.

### Acceptance

- No 🔴 rows remain for these kernels on 128-bit targets (either ≥1.0x via AVX2
  or relabeled scalar/disabled).
- Parity suites green.
- `SVG-SUPPORT.md` untouched (feature set unchanged).

---

## Cross-cutting verification commands

Host build + parity + bench (see `UNLINEARIZE_SSSE3_WORKLOG.md` reproduction):

```bash
./gradlew :filtering:buildHostNativeLib
./gradlew :filtering:testDebugUnitTest -Dorg.gradle.warning.mode=none \
  --tests "*DisplacementMap*Parity*" --tests "*Lighting*Parity*" \
  --tests "*UnLinearize*Parity*" --tests "*ComponentTransfer*Parity*" \
  --tests "*ArithmeticComposite*Parity*"
# bench (per kernel):
./gradlew :filtering:testDebugUnitTest -Dbenchmark.kernel=<Kernel> -PshowTestOutput
```

Device (arm64 / armv7) parity:

```bash
./gradlew :filtering:connectedDebugAndroidTest -PfilterAbis=arm64-v8a
# or per-class via am instrument with the 10 *NativeParityTest classes
```

## DoD summary

- [x] WP0: Blur x86 asm wired (host + NDK x86_64, then i386); parity + bench recorded.
- [x] WP1: DisplacementMap ≥1.0x or disabled; parity + bench recorded.
  (neon64 12.2×, neon32 8.2× @2048²; parity 10/10 both ABIs)
- [ ] WP2: Lighting arm64 math audited, parity green, ≥1.0x or disabled.
- [ ] WP3: LUT trio LUT-SIMD disabled on 128-bit; AVX2 kept; parity + bench recorded.
- [ ] `BENCHMARKS.md` / this file updated; no advertised 🔴 rows.
- [ ] Work log entries appended after each milestone (see work-log convention).

## Work log

- 2026-09-07 — WP0 added ahead of WP1/WP2 (user request): blur x86 asm wiring.
  `blur_x86_64_{ssse3,avx2}.S` exist (staged) but are unreferenced; current
  x86 `GaussianBlur` is the C++ SSE kernel mislabeled as AVX2. ABI contracts of
  both .S files read and match the C++ `rsdIntrinsicBlur{V,H}FU4_K` signatures,
  so the dispatch swap is mechanical. i386 variants expected soon.
- 2026-09-07 — **WP0 DONE**: i386 variants landed; all 4 `.S` Apple-guarded
  (`SYM/TYPE/SIZE` + `#ifndef __APPLE__` GNU-stack); host CMake + NDK per-ABI
  `BLUR_SOURCES` wired; `gaussian_blur.cpp` dispatch re-pointed at asm (AVX2 +
  ssse3, scalar tails kept). Fixed a pre-existing `UnsatisfiedLinkError` in
  `NativeGaussianBlur` (missing `isAvailable` load-trigger) → parity 14/14.
  NDK x86 build green (i386 symbols exported); x86_64 asm assembles standalone
  under NDK clang (full link blocked by pre-existing lighting error — WP2).
  Host bench: ssse3 3.35x/3.78x, avx2 3.35x/3.77x (512/2048) vs scalar 1.00x —
  BENCHMARKS.md updated.
- 2026-09-07 — Plan created. Based on `KERNEL_REVIEW.md` §2, `SIMD_KERNEL_TRICKS.md`,
  `UNLINEARIZE_SSSE3_WORKLOG.md`, and in-file analysis of
  `displacement_map.cpp` (spill round-trip found, lines 157–173) and the LUT
  kernels. WP1 hypothesis also confirmed the `/255` division in-loop
  (`displacement_map.cpp` lines 121–129).