# REGRESSION_FIX_WORKLOG.md — WP3: LUT kernel backends (UnLinearize / ComponentTransfer / ArithmeticComposite-linear)

Status of the regression-fix work. Plan and acceptance criteria: `REGRESSION_FIX_PLAN.md`.

## Scope being executed (WP3)

Disable the losing SIMD paths for the LUT-trio kernels on 128-bit targets, keep the
winning AVX2 paths on x86-64 host builds, and keep bit-exact parity. Per the trick
analysis this maps to the "negative verdict on all SIMD paths" case (§8, §9): a byte
LUT cascade (16-row compare/mask with `vqtbl`/`pshufb`) costs more than the alias-free
scalar loop costs to avoid.

## Backend advertisement mechanism (verified)

- `XxxNative.nativeBackend()` returns an ABI bitmask (`SIMD_SCALAR|SSSE3|AVX2|...`).
- Both the parity harness and both benchmarks enumerate ONLY advertised backends:
  `getBackendsFor(nativeBackend())` in `BackendDiscovery.kt` (testFixtures) / `Asserts.kt`.
- No test asserts the exact flag bits of `nativeBackend()`, only non-zero + parse.
- `applyForced` still reaches every kernel function, so disabled backends remain
  reachable for validation/measurement — un-advertising only changes default dispatch
  and the parity/bench surface.

## Key finding — host benchmark `useLinear` labeling bug

`KernelPerformanceBenchmark.benchmarkArithmeticCompositeLinear` (line ~268) passes
`useLinear = false`, so the "ArithmeticComposite (linear) ... ssse3 1.66x" host row is in
fact a **non-linear** measurement. The device benchmark
`KernelPerformanceDeviceBenchmark` (lines 245–247) sets `useLinear` correctly, which is
why that data set shows the real losses: neon64 0.34x, neon32 0.22x, x86-32 0.17x.
Fixing this bug is part of the WP3 diligence (needed to measure what the gate actually
fixes on the host).

## Decision per kernel (evidence review of `KERNEL_REVIEW.md` / `BENCHMARKS.md`)

| Filter | Winner | Losers → gate to scalar | Gate details |
|---|---|---|---|
| UnLinearize | AVX2 (x86-64, host 1.37–1.52x) | SSSE3 (host 0.58–0.61x), NEON64 (device 0.05x), NEON32 (device 0.01x) | `nativeBackend()` = SCALAR only on ARM / non-x86_64; AVX2 + SCALAR on x86-64-with-AVX2. `apply()` → AVX2 if `detectSimdLevel() >= SIMD_AVX2` on x86_64, else scalar. |
| ComponentTransfer | AVX2 (host 1.06–1.10x) | SSSE3, NEON64, NEON32 | Same as UnLinearize. |
| ArithmeticComposite | non-linear NEON formula asm (17–23x) and non-linear SSE (10–14x) | linear mode through LUT (`vqtbx4q_u8` cascade) — neon64 0.34x, neon32 0.22x, x86-32 0.17x | **Leave the non-linear asm untouched.** Gate production `apply` only: `useLinear == JNI_TRUE` → scalar on ARM and on non-AVX2 x86 (SSE linear 0.56–0.57x), AVX2 everywhere (measured winner 1.05–1.07x). `runForced`/`applyForced` stays a pure forced executor so parity/bench can still validate the SIMD linear kernels. |

## Log

- (Todo created) WP3 chosen as the "easiest by gut feeling" work package.
- Mapped the dispatch/advertisement surface:
  - `filtering/src/main/cpp/cpu_dispatch.h` — `SimdLevel` + `detectSimdLevel()` (x86 only; non-x86 → SSE2).
  - `filtering/src/main/kotlin/hu/oandras/ksvg/filtering/SimdBackend.kt`, testFixtures `BackendDiscovery.kt` + `Asserts.kt` — flags + `getBackendsFor`.
  - `KernelPerformanceBenchmark.kt` — `ApplyForced`-based enumeration over `getBackendsFor(nativeBackend())`; found the `useLinear` mislabeling.
  - `KernelPerformanceDeviceBenchmark.kt` — correct `useLinear` handling (source of the real linear losses).
  - `unlinearize.cpp` / `component_transfer.cpp` (SSSE3+NEON) / `arithmetic_composite*.cpp` + `srgb_lut.h` (NEON64 `vqtbx4q_u8` linear LUT) — confirmed kernels are bit-exact byte maps; the losses come from per-block LUT-row loading + compare/mask selection, not from math.
- **Confirmed** `nativeBackend()` flags are consumed only by the test/benchmark harness (`getBackendsFor`), never by production Kotlin → un-advertising is safe.
- **Host benchmark property**: the forwarding in `build.gradle.kts` reads `System.getProperty("benchmark.kernel")`, so it must be passed as `-Dbenchmark.kernel=X`, NOT `-P`. (`-P` silently runs every kernel and writes `tmp/benchmarks_host_.csv`.)

## Implementation (2026-09-07)

All production dispatch is scalar/AVX2-correct; disabled kernels stay reachable via `applyForced` (so the parity + benchmark harness can still characterize them). Explicit-Api / NDK constraints: none touched on Kotlin side.

1. `unlinearize.cpp`:
   - `nativeBackendForAbi()` → `SCALAR` always; `+AVX2` only on `__SSSE3__ && __x86_64__ && detectSimdLevel() >= SIMD_AVX2`.
   - `apply()` (in-place + out-of-place) → AVX2 on x86-64-with-AVX2, else `applyScalar`.
   - `runForced` unchanged (still reaches NEON64/NEON32/SSSE3/AVX2).
2. `component_transfer.cpp`:
   - `nativeBackendForAbi()` → `SCALAR` always; `+AVX2` on `__SSSE3__` + detect.
   - `apply()` → AVX2 or `applyScalar`.
   - `runForced` unchanged.
3. `arithmetic_composite.cpp` `applyNative` (production only):
   - ARM: `useLinear == JNI_TRUE` → `applyArithmeticScalar` (neon linear 0.34x/0.22x right), else `applyArithmeticNeon` (non-linear 17–23x).
   - x86: AVX2 always (AVX2 linear measured 1.05–1.07x host, still a win); else `useLinear` → scalar (ssse3 linear 0.56–0.57x), else `ksvgArithmeticApplySse` (non-linear 1.5–1.7x).
   - `runForced` deliberately **left un-gated** (refinement vs plan): `applyForced` must stay a pure forced-executor so parity/bench still validate each SIMD kernel's linear path bit-exactly and can measure it.
4. `KernelPerformanceBenchmark.benchmarkArithmeticCompositeLinear`: `useLinear = true` (was `false` — the bug that mislabeled host rows as non-linear).

## Verification

- Host `buildHostNativeLib` + 3 parity suites: **284 tests, 0 failures**.
  - UnLinearize: 196 = 98× scalar + 98× AVX2 (SSSE3/NEON gone from the run).
  - ComponentTransfer: 58, ArithmeticComposite: 30 — green.
- NDK `externalNativeBuildDebug` arm64-v8a + armeabi-v7a + x86: **BUILD SUCCESSFUL**. (x86_64 NDK still fails on the pre-existing `lighting/lighting_distant_diffuse_x86_64_{sse2,avx2,avx512}.S` "Size expression must be absolute" — unrelated, WP2.)

## Fresh host measurements (i7-7820X, 2026-09-07)

| Kernel/mode | backend | 512x512 | 2048x2048 |
|---|---|---|---|
| UnLinearize | scalar | 1.00x | 1.00x |
| UnLinearize | avx2 | **1.95x** 🟢 | **1.69x** 🟢 |
| ComponentTransfer | scalar | 1.00x | 1.00x |
| ComponentTransfer | avx2 | **1.02x** 🟢 | **1.09x** 🟢 |
| ArithmeticComposite linear | scalar | 1.00x | 1.00x |
| ArithmeticComposite linear | ssse3 | 0.57x 🔴 (now un-used) | 0.56x 🔴 (now un-used) |
| ArithmeticComposite linear | avx2 | 1.07x 🟢 | 1.05x 🟢 |
| ArithmeticComposite non-linear | ssse3 | 1.66x 🟢 | 1.59x 🟢 |
| ArithmeticComposite non-linear | avx2 | 2.84x 🟢 | 2.51x 🟢 |

Post-gate advertised hosts (UnLinearize/ComponentTransfer) have every advertised
backend ≥ 1.0x; ArithmeticComposite keeps its non-linear winners and linear now
tracks scalar-or-better.

## Docs updated
- `BENCHMARKS.md` Host section: LUT-trio rows re-measured; noted the `useLinear=false` bug.
- `KERNEL_REVIEW.md` §2/§2.4/§2.6/§6: LUT rows marked ✅ gated; decision recorded.
- `REGRESSION_FIX_PLAN.md` WP3 → done.

## WP1 exploration (2026-09-07)

- **Plan fold #2/#3 is provably dead**: replacing the in-loop `vdivq_f32(px, 255)`
  with `vmulq_f32(px, 1/255)` is NOT bit-exact. A host C probe (float32 RNE,
  all u=0..255) shows `u/255.0f != u*(1.0f/255.0f)` for ~94 values; division
  rounds to the correctly-rounded `u/255`, multiply-to-reciprocal lands 1 ulp
  above, and downstream `(int)(scale*(val-0.5f))` diverges — e.g. at u=51 the
  parity-scale-adjacent `scale=10` already flips idx (-3 vs -2). The plan's own
  gate #2 ("do not fold without proving parity") applies; the fold fails. The
  scalar reference (`KotlinKernels.displacementMap`) keeps `/255.0f`, so the NEON
  kernel must keep `vdivq_f32` (true FP division) for bit-exactness.
- Remaining WP1 lever: the vector→stack→scalar round-trip (see plan WP1
  root-cause). That is the next thing to measure/A-B.

## WP0 status (blur x86 asm wiring)
- **DONE (host + NDK x86 ABIs). x86_64 full NDK link blocked by pre-existing lighting
  `.S` error (WP2).**
- Host `CMakeLists.txt`: added `blur/blur_x86_64_{ssse3,avx2}.S` to the host lib.
- NDK `CMakeLists.txt`: added per-ABI `BLUR_SOURCES` for `x86_64`
  (`blur_x86_64_{ssse3,avx2}.S`) and `x86` (`blur_i386_{ssse3,avx2}.S`).
- All 4 `.S` files: added the `SYM()`/`TYPE()`/`SIZE()` `__APPLE__` guard + guarded
  `.note.GNU-stack` under `#ifndef __APPLE__` (ELF-only), matching the morphology
  precedent. Host darwin link validated (`_ksvgBlurVerticalAvx2_x86_64` etc. present).
- `gaussian_blur.cpp` `blurIsotropicKernel`: vertical now dispatches
  `ksvgBlurVerticalAvx2_{x86_64,i386}` (AVX2) / `rsdIntrinsicBlurVFU4_K_{x86_64,i386}_ssse3`
  (else); horizontal dispatches `ksvgBlurHorizontalAvx2_{x86_64,i386}` /
  `rsdIntrinsicBlurHFU4_K_{x86_64,i386}_ssse3`; scalar tails unchanged.
- **Pre-existing bug fixed (unrelated to WP0):** `GaussianBlurNativeParityTest` failed at
  `data()` with `UnsatisfiedLinkError` on `nativeBackend` because the object had no
  `isAvailable` init to trigger `System.loadLibrary("ksvgblur")` before the JNI call.
  `TurbulenceNative` etc. load via their `@JvmField isAvailable = NativeBackend.isAvailable`;
  `NativeGaussianBlur` lacked it. Added the same field → parity test now runs 14 cases,
  0 failures.
- Host parity: `GaussianBlurNativeParityTest` green — scalar bit-exact, ssse3 + avx2
  asm backends within tolerance 1 (cases 16x16, 32x24, 48x48, 8x8; anisotropic/scalar too).
- NDK `x86` build (`-PfilterAbis=x86`) green; `llvm-nm` confirms
  `ksvgBlurVerticalAvx2_i386`, `ksvgBlurHorizontalAvx2_i386`,
  `rsdIntrinsicBlurVFU4_K_i386_ssse3`, `rsdIntrinsicBlurHFU4_K_i386_ssse3` exported.
- NDK `x86_64`: full build still fails on the pre-existing lighting `Size expression
  must be absolute` blocker, but both blur x86_64 `.S` compile standalone with the NDK
  `clang -target x86_64-none-linux-android26 -c` (no Apple guards → ELF build path OK).
- Host bench (`-Dbenchmark.kernel=GaussianBlur`) → `tmp/benchmarks_host_GaussianBlur.csv`
  → `BENCHMARKS.md` x86-64 rows updated: scalar 1.00x, ssse3 3.35x/3.78x, avx2
  3.35x/3.77x (512/2048). Both SIMD backends ≥1.0x acceptance; old rows (avx2 1.96x)
  had been the C++ SSE kernel masquerading as AVX2.
- **i386 bug found + fixed (2026-09-07):** device parity on x86 emulator initially
  failed 4/10 (`ssse3` cases, diff 36–149 at element [0]). Root cause:
  `blur_i386_ssse3.S` `rsdIntrinsicBlurHFU4_K_i386_ssse3` read its stack args at
  offsets 16/20/24/28/32/36, but after 4 pushed regs (+16) the args live at
  20/24/28/32/36/40 — the loop bound decoded `rct`=x1 slot, so the kernel returned
  without writing (matching "diff at element [0]" + vertical-only content). Fixed
  the six arg loads + the in-loop `gptr`/`rct` reloads (+4). The i386 AVX2
  horizontal twin was already correct (`subl $4` → 24–44). Parity on the x86
  emulator now 10/10.
- i386 emulator bench (`runDeviceBenchmark`, x86 AVD API 26): ssse3 asm = **21.34x**
  (512) / **24.13x** (2048) vs scalar — the old 1.93x/2.13x rows were the C++ SSE
  kernel. `BENCHMARKS.md` x86-32 rows updated (now 🚀).
- **Step-6 nit done (2026-09-07):** answered user's `blur_x86_avx2.cpp` question —
  it was dead (only defined the old C++ `ksvgBlurVerticalAvx2` calling `blur_x86.cpp`'s
  SSE `rsdIntrinsicBlurVFU4_K`; no callers). Removed both `blur_x86_avx2.cpp` and
  `blur_x86.cpp`, dropped dead `ksvgBlurVerticalAvx2` decl from `simd_x86.h` and the bare
  `rsdIntrinsicBlur{V,H}FU4_K` decls from `gaussian_blur.cpp`. Updated both CMakeLists
  (main + host-native). NDK `x86`/`arm64-v8a`/`armeabi-v7a` all build green; host parity
  14/14 preserved. Only `x86_64` NDK link remains blocked by the pre-existing lighting
  WP2 issue.

## WP1 DisplacementMap — ARM asm wiring (2026-09-07, in progress)

User asked to wire the hand-written `displacement_map_arm{32,64}.S` kernels (and to
also cover the x86_64 versions). The x86_64 avx2/avx512 kernels were already wired +
exported (`simd_x86.h:101/104`, host `_ksvgDisplacementMapApplyAvx2/_Avx512`).

### Approved/edited diffs
- `filtering/src/main/cpp/CMakeLists.txt`: new `DISPLACEMENT_MAP_SOURCES` —
  `arm64-v8a → displacement_map_arm64_neon64.S`, `armeabi-v7a → displacement_map_arm32_neon32.S`.
- `displacement_map.cpp`: extern "C" asm decls; **deleted the entire C++ aarch64
  template block** (`applyNeon64Impl`, 16-way `applyNeon64`, `shiftRightFF`) — the
  old stack-bounce path is gone, the asm (`umov` straight to GPRs) is the
  no-spill WP1 lever. `runForced`/`apply`/`nativeBackendForAbi` dispatch
  `ksvgDisplacementMapApplyNeon64` (aarch64, NEON64) / `ksvgDisplacementMapApplyNeon32`
  (`__arm__`, NEON32 now advertised). Host/build unchanged for x86.
- `displacement_map_arm32_neon32.S`: byte-exact fix — vector path now uses a true
  VFP scalar `vdiv.f32` per lane (s4..s11 ÷ s26) instead of `vrecpe`+2×`vrecps`
  (reciprocal is 1 ulp off vs the Kotlin `/255f`). NEON has no vector FP divide on
  ARMv7, so this is the price of parity. `255.0f` loaded via `vldr s26` from a
  per-kernel literal (s26 = d26[0] = q13 lane0, caller-saved; free after removing
  the reciprocal block). Header comment updated.
- `displacement_map_arm64_neon64.S`: dispatcher jump table made PIC-safe —
  `.xword SYM(...)` emitted `R_AARCH64_ABS64` (non-PIC, link fail under `-fPIC`);
  now `.align 2` + `.word SYM(kernel) - .Ldispatch` `R_AARCH64_PREL32` + `adr`/`ldr
  [x8,w7,uxtw]`/`add (sxtw)`/`br`.

### arm32 PIC blocker (the `.word .L_increments` literal pointer)
armeabi-v7a link failed: `R_ARM_ABS32 against local symbol` ×4. Same failure class
as arm64: `ldr r0, .L_inc_ptr_` + `.word .L_increments` is an absolute data address
(also the ONLY table-address load in the repo's armv7a asm — the existing armv7a
kernels use synthetic immediates only). Fixed: `adr r0, .L_inc_\label` against a
per-kernel local 4-word literal (PC-relative, relocation-free; in-range because
the pool sits at the end of each ~600B kernel). Removed the shared `.L_increments`.

### Verification so far
- NDK arm64-v8a: BUILD SUCCESSFUL; `llvm-nm` shows `ksvgDisplacementMapApplyNeon64`
  + 16 `_RR.._AA` kernels exported. (scalar C++ `applyNeon64Impl` removal OK).
- NDK armeabi-v7a: BUILD SUCCESSFUL (after the `adr` fix); `llvm-nm` shows
  `ksvgDisplacementMapApplyNeon32` + kernels (local `t`).
- NDK x86: BUILD SUCCESSFUL (x86_64 still block by pre-existing WP2 lighting error).
- Host `buildHostNativeLib`: BUILD SUCCESSFUL; host `DisplacementMapNativeParityTest`
  **15/15 byte-exact** (avx2/avx512/scalar).
### Device parity (OnePlus 11, `adbca122`)
- arm64 NEON64: **10/10 byte-exact** (5 corpus cases × forced backends).
- arm32 NEON32: two register-aliasing bugs found via a temporary per-pixel
  diagnostic (NDK JAVA-full-run):
  1. `vdup.32 q11, d22[0]` after `vldr s22,[sp,#40]` — `s22 = d11[0]`, so `d22[0]`
     (= s44) was uninitialized junk → garbage scale broadcast. Fixed line 110 to
     `vdup.32 q11, d11[0]`. Symptom before fix: nondeterministic wrong indices.
  2. `vldr s26, .L_float255_\label` puts the `/255f` divisor in `s26 = d13[0]`,
     but the per-row `vdup.32 q6, r11` (y,y,y,y) writes ALL of d12/d13 (s24–s27),
     clobbering the divisor every row. Row 0 → divisor `0.0f`, rows ≥1 → the raw
     `y` bits (a ~1.4e-45 denormal). Decode: byte/divisor → `+Inf` →
     `vcvt.s32` → `INT_MAX` → `clamp(x + INT_MAX)` **wraps** in the lane add (lane0
     → 15, lanes1-3 wrap negative → 0), so the gather returned only the four src
     CORNER indices {0,15,240,255} (`0x700a2b74` = src[240] broadcast). identity
     (scale=0) masked it: `Inf * 0 = NaN → 0`.
     Fixed by relocating the y-broadcast off q6 onto the free **q13**: the two
     loop instructions became `vdup.32 q13, r11` / `vadd.i32 q4, q13, q2`
     (NOT `vldr s63,_` — VFP scalar ops only accept s0–s31 on this target).
- After fix + clean reinstall: **10/10 byte-exact on NEON32** (neon32 matrix).
  Device bench (OnePlus 11, medians, `nativeBenchmark { }`):
  - arm64 NEON64 DisplacementMap: 12.23× @ 2048² (7.50 ms vs scalar 91.72),
    14.21× @ 512² (0.476 ms vs 6.765).
  - arm32 NEON32 DisplacementMap: 8.16× @ 2048² (23.02 ms vs scalar 187.80),
    10.94× @ 512² (0.967 ms vs 10.58).
  Diagnostic test file removed; the parity test keeps `assertArrayEquals`.

### Constraints honoured
- Parity gate is byte-exact (`assertArrayEquals` vs `KotlinKernels.displacementMap`,
  `/255f` true division); corpus widths are all multiples of 4 → vector path fully
  covered, the arm32 tail never runs (so the true-divide per-lane path is what
  parity validates).
- No memory allocation in kernels; no shared/global state.
- Pre-existing latent issue (NOT in scope): arm32 kernel clobbers AAPCS callee-saved
  VFP d8–d15 without save/restore.

## Host convolve SSE2 + lighting distant-diffuse AVX2 fixes (2026-09-08) — DONE

Two independent native kernel bugs found via `NativeParityTest` on the host AVX512
machine (`--rerun` required to actually re-execute the test task).

### 1. Convolve SSE2 preserve-alpha (`convolve_x86_64_sse2.S`) — fixed
- Parity failed on the preserve=α cases. Root cause: the `_true` body was a stale
  diverged copy (missing masking / wrong blending math → wrong output rows).
- Fix: replaced the `_true` body with an exact clone of the proven `_false` body,
  then added the source-alpha blend at pack time: after writing `(kernel,255)`,
  inject `srcA` via `movslq`/`imulq`/`addq` pointer math +
  `pslld $24`/`psrld $24` + `por`. Verified bit-exact vs avx2 preserve=true and the
  Kotlin oracle. Convolve suite: 36/36.

### 2. Lighting distant diffuse AVX2 (`lighting_distant_diffuse_x86_64_avx2.S`) — fixed
- Parity failed only on "distant diffuse 16x16" (element 18: expected 0xFF8C8C8C,
  got 0xFFFFFFFF). Probe `dumpLightingDistant` + a C harness
  (`tmp/lighting_harness.c`, linked against the compiled .S objects) showed the
  AVX2 block's lanes 1,2,3 = 0xFF,0x80,0xFF — stale/garbage, regardless of input.
- Root cause (diagnosed by user, then confirmed): `vmaxps .Lzero(%rip),%ymm0,%ymm0`
  is a 32-byte AVX load, but `.Lzero: .float 0.0` is only 4 bytes. Lanes 1/2/3 read
  the FOLLOWING constants (`.Lone`=1.0→0xFF, `.Lhalf`=0.5→0x80,
  `.Lthree_halves`=1.5→0xFF), exactly the observed corruption. The assembler does
  not flag y/z-memory operands against undersized constants.
- Fix: `vxorps %ymm4,%ymm4,%ymm4` + `vmaxps %ymm4,%ymm0,%ymm0` (ymm4 is free at that
  point — re-broadcast 1.0 on the very next instructions). SSE2 file unaffected
  (its `.Lzero` has 4 floats = full 16 bytes); AVX512 already zeroes via a register.
- **Bug-class sweep**: only ymm/zmm memory operands against constants were the 3
  found by `rg "v?(maxps|... ) +\.L...\(%rip\), %y?m"`: `vpor .LmaskAlphaShifted`
  (8 entries, fine), `vpand .L_rgb_mask`/`.L_alpha_mask` (8 entries, fine), and the
  buggy `vmaxps .Lzero`. The i386 avx2 twin builds constants from immediates (no
  memory reads) — clean. No other `.S` files affected.
- Note (harness quirk that wasted time): `applyForced` ignores the forced backend —
  it uses `detectSimdLevel()`, so on this AVX512 host the "ssse3"/"avx2"/"avx512"/
  "sse2" forced cases all ran the SAME real kernel (avx2, since a 16-wide image is
  < 32 → c16=0). The corruption was entirely inside the AVX2 8-lane block.
- Lighting suite: 30/30. Combined final: convolve 36/36 + lighting 30/30.
- Docs: `lighting_distant_diffuse_x86_64_avx2.S` updated. Probe file
  (`filtering/src/test/kotlin/.../TmpDebugAsm.kt`, both source sets) + `tmp/`
  harness files deleted.

## Next steps
1. WP2 Lighting arm64 (math audit vs verified SSE2, `.S` parity/dispatch check; also fixes the x86_64 NDK build blocker so WP0's final x86_64 link validation can complete).
2. Optional: x86-32 silent-fallback bench classification (§2.5).