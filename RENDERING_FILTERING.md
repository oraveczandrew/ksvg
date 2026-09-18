# KSVG Rendering & Filtering — Architecture and Validation Notes

Living internal document. It describes how KSVG turns an SVG DOM into rendered
pixels (the Render Tree and the filter pipeline), records design decisions and
their *reasons*, and lists the acceptance criteria/validation commands used to
check the behavior. It grows incrementally together with the implementation
work; re-read it before touching the render/filter code.

Status: working document, kept in sync with `ksvg/src/main/kotlin`.
Scope: rendering core + filter primitives (software and hardware paths).

---

## 1. The two phases: DOM → Render Tree → Scene → Draw

The pipeline has three distinct stages (see also AGENTS.md "Core Architecture"):

1. **DOM** (`hu.oandras.ksvg.dom`): a light-weight, parser-built structure of
   the SVG XML. Parsing is streaming (SAX-like) in `SVGParserImpl.kt`; attributes
   are mapped through `SVGAttr`, tags through `SVGTag`. This layer knows nothing
   about layout or canvas.
2. **Render Tree** (`hu.oandras.ksvg.render`, `RenderTreeBuilder.kt`): DOM is
   walked and turned into render nodes (`KSVGRenderNode` and subclasses). This
   phase resolves CSS styles, inheritance, and pre-calculates geometry. **It must
   not write viewport geometry** — `node.viewPort` / `node.viewBoxTransform` are
   written only by `RenderScene.applyViewport`. Drawable bounds changes update the
   scene in place.
3. **Scene** (`hu.oandras.ksvg.render.RenderScene`): owns the viewport and hosts
   the built tree for a specific layout size. Multiple scenes can share one tree.
4. **Renderer** (`SVGAndroidRenderer.kt`): walks the tree each frame and executes
   `Canvas` operations. This is *the* hot path — zero-allocation rules apply here.

Data-flow rule: a subtree can be rebuilt lazily when its style/content changes
(`RenderNode` version counters), without rebuilding the whole tree.

### 1.1 Scene updates and filtered composition

`RenderScene` owns viewport application and can update drawable bounds in place;
viewport-relative text, shapes, filters, and symbols do not require rebuilding
the render tree. Bounds unions are refreshed bottom-up and the existing scene
is invalidated accordingly.

Filtered output preserves the source element's opacity and blend mode when it
is composited back to the target canvas. This is separate from mask
composition, which requires its own validation.

---

## 2. Filters: where they sit and the two pipelines

Filters live on element render nodes; they are executed when an element with a
`filter` attribute is drawn. The output replaces the element's visual on the
canvas (per the SVG spec the filter output is the element's rendering).

There are **two competing implementations** of the filter chain, selected by
canvas type/API level:

| Backend | Entry point | Runs on | Notes |
|---|---|---|---|
| Software (CPU) | `SoftwareFilterBackend` | software `Canvas` | The reference. Every primitive claims it. |
| Hardware (GPU) | `FilterPipelineImpl31`/`FilterPipelineImpl33` | hardware canvas, API 31+/33+ | RenderEffect chain; shares region semantics with software via `RegionUtils`. |

The two must agree **closely, not bit-exactly**. The software path and its
native kernels are compared byte-for-byte by default (parity gate, see §6.3 —
with documented per-kernel tolerances: ±1 LSB SIMD-tail tolerance of the RIR
Toolkit Gaussian blur port, `maxDelta = 1` for specular lighting). The GPU path instead goes through Skia
`RenderEffect` implementations and AGSL `float` (fp32) shaders with different
rounding/fused-math, premultiplied intermediates and dithering, so ±1-2 LSB
per-channel differences are expected and normal. GPU parity is therefore a
**tolerance-based near-match** (`maxAbsDiff ≤ 2` per channel, outlier ratio
< 0.1%, plus `meanAbsErr`), never a byte-for-byte comparison.
The committed subregion-defaulting work (see
commit `fb6d299a`) mirrored the software region semantics into the HW chain;
the one known residual gap is the `feMerge` HW clamp.
**Caution**: HW pixels cannot be verified in Robolectric (software canvas is
used), so HW parity is checked by code-review + API-level reasoning, not by
unit-test pixel output.

Per-primitive execution model (software path, `applyFilterToBitmap`):
- `sourceBitmap` (the element's own rendering, recorded via a backend-owned
  `recordCanvas`) is the initial `lastResult`.
- Each primitive resolves its input (`getFilterInput`), computes its **subregion**
  in user space (`calculatePrimitiveRegion`, `RegionUtils.kt`), executes its
  kernel over that subregion, and stores the result into `FilterSourceMap`
  (`results`), keyed by the primitive's `result` id. Named results can be
  referenced by later primitives.
- The last primitive's result is the filter output; it is composited back onto
  the canvas by `drawFiltered` → `drawResult` (default: plain `drawBitmap`,
  source-over into the target canvas).

### 2.1 Region semantics (subregion defaulting)

Per the SVG Filter Effects spec, a primitive that omits `x`/`y`/`width`/`height`
defaults its subregion to the **union of its referenced inputs' subregions**
(falling back to the full filter region for standard inputs like SourceGraphic /
SourceAlpha). Non-first primitives with `in == null` mean "previous result" and
inherit its subregion; `feMerge` never inherits.

This is centralized in `RegionUtils.resolvePrimitiveInputRegion` (shared by the
software backend and the HW chain) plus `calculatePrimitiveRegion`
(which then remaps user-space regions to bitmap-pixel space for the kernels).

Key gotcha: use `listOf(input)` (NOT `listOfNotNull`) when forwarding a single
`in` — a `null` input must be preserved to inherit the previous result.

---

## 3. Lighting (`feDiffuseLighting` / `feSpecularLighting`)

### 3.1 Storage & compositing: straight vs. premultiplied — IMPORTANT

The most subtle lighting issue discovered so far (`lighting_point_spot`):

- The KSVG kernels emit **straight** RGBA for specular:
  `out = (k·N·H^se·color·cone, intensity)` with `outA = max(outR, outG, outB)`.
  Composited on a transparent canvas this straight `(I,I,I,I)` stays `(I,I,I,I)`
  through Android's premultiplied source-over.
- **rsvg/cairo emits premultiplied** specular: the light color is stored at full
  strength and only the intensity lives in alpha, so straight-decode yields
  `(color, intensity)` — i.e. `(255,255,255, I)` for white light. Pixels are the
  same *visually* on an opaque canvas but differ in the raw channel values, which
  breaks golden comparison when the specular result is the **terminal** output of
  the filter (no `feComposite`/`feMerge` to absorb the difference).

Consequences (verified, 2026-08-30):
- Specular intensity (alpha) already matches rsvg — the brightness/cone formula is
  correct and must NOT be "fixed" in the kernel.
- `filter_specular.svg` passes because a `feComposite operator="arithmetic"`
  consumes the specular before the canvas; only a *direct* specular-to-canvas
  output exposes the discrepancy.
- The fix (implemented 2026-08-31): when a `feSpecularLighting` is the **last**
  primitive of the filter (its result becomes the terminal canvas draw), the
  kernel emits the premultiplied form `(lightColor, intensity)`; otherwise it stays
  straight so consumer kernels (composite/merge) keep working. This is a
  *compositing representation* decision, not a formula change.

  Implementation (software path + bit-exact native): a `premultipliedOutput`
  boolean is threaded from `SoftwareFilterBackend.applyFilterToBitmap` (where the
  terminal primitive is detected via `primitives.lastOrNull()`) → `doFeSpecular
  LightingFilter` → `doLightingFilter` → `KotlinKernels.lighting` and
  `LightingNative.apply` (JNI `jboolean`). When set and `specular`, the RGB
  channels are the full-strength `lightColor` and alpha carries the specular
  intensity; otherwise the original straight `(I·color, max(R,G,B))` is kept.
  Diffuse output is untouched (opaque, alpha=255).

  Result (AiVisualDiffTest, 256×256, software backend): `lighting_point_spot`
  similarity improved **0.425 → 0.722** with the premultiplied-terminal fix alone;
  `filter_specular.svg` (specular consumed by `feComposite arithmetic` →
  non-terminal) unchanged at **0.981**. The diffuse-circe divergence (see §3.3)
  then took it to **0.9783** (target ≥0.95).

### 3.2 Spot-light cone factor

Kernel `params` packing for spot (documented as bit-exact with `lighting.cpp`):
`[x, y, z, pointsAtX, pointsAtY, pointsAtZ, limitingConeAngleDeg]` (NaN = no cone).

Per librsvg `lighting.rs` `color_and_vector`:
- `vector` = direction from surface **to** light (normalized).
- `direction` = `normalize(pointsAt - origin)` (spot axis).
- `minus_l_dot_s = -vector · direction`; cone factor = `minus_l_dot_s^feSpotLight.specularExponent`
  (default 1.0), with hard cutoffs: `minus_l_dot_s <= 0` → black, and if a
  `limitingConeAngle` is set, `minus_l_dot_s < cos(limit)` → black.
- **The spot cone exponent is the `feSpotLight`'s own `specularExponent`**, NOT the
  parent `feSpecularLighting`'s. The KSVG `FeSpotLight` DOM does not yet parse its
  own `specularExponent` (currently missing); when this matters the DOM + kernel
  params must be extended. The current test uses no spot `specularExponent`, so
  the cone factor reduces to `cos` regardless (matches).
- Specular `H = L + V` with `V = (0,0,1)`; `n_dot_h = (N·h)/(|N||h|)`;
  `Ks · n_dot_h^se` (fast path if `se == 1`). `H == 0` → intensity 0.

### 3.3 Diffuse-vs-specular divergence note

The `lighting_point_spot` left circle (`feDiffuseLighting` + `fePointLight`) showed
a systematic brightening in rsvg vs KSVG. **Root cause (resolved 2026-08-31)**:
the SVGs use the spec default `color-interpolation-filters: linearRGB`, so the
lighting straight RGBA is computed in linear light and the RGB terminals are
converted back to sRGB via the sRGB EOTF before compositing. KSVG computed the
entire lighting result directly in sRGB, darkening the diffuse output. The fix
(`useLinear` threaded through `KotlinKernels.lighting` and the `:filtering`
`lighting.cpp` native/AGSL path) linearizes the light color once
(`linearLightR/G/B = sRgbToLinear(lightColor)`), computes the straight RGB in
linear space, then applies `linearToSRgb` to the straight output when
`color-interpolation-filters` is `LINEAR_RGB`. Bit-exact `sRgbToLinear` /
`linearToSRgb` helpers were added to both the Kotlin and native kernels.

- Diffuse: `useLinear` gamma-corrects the straight RGB (opaque, alpha=255).
  `lighting_point_spot` similarity rose **0.722 → 0.9783** (target ≥0.95 met).
- Specular terminal (`premultipliedOutput`, last primitive): keeps the full light
  color in RGB and the raw linear intensity in alpha — **untouched** by the fix.
  For the (linearRGB) `lighting_point_spot` specular circle this matches the
  golden exactly (alpha=intensity, saturated white RGB); verified against
  `rsvg-convert`, which produces the same alpha=R/GB=255 relationship (i.e. the
  `alpha = max(R,G,B)` identity holds only in sRGB space, not the linearRGB
  straight terminal that librsvg emits).
- Validation: `filter_specular.svg` (sRGB) unchanged (0.9812); `filter_primitives.svg`
  (linearRGB) improved 0.818 → 0.8264. The pre-existing `lighting.svg` (0.2233) red
  is unchanged.

> Note: `color-interpolation-filters="sRGB"` is not yet honored by the lighting
> kernel — the light color is always linearized and gamma-corrected as if linearRGB
> (the default). sRGB is honored by other primitives (`feComponentTransfer`,
> `feComposite`), so an sRGB-requesting lighting SVG currently renders with the
> linearRGB straight-RGB EOTF. Out of scope for this fix; tracked separately.

### 3.4 Turbulence parity and terminal color-space conversion

The turbulence kernel is parity-proven against captured librsvg runtime
inputs: lattice construction, `noise2`, octave sums, and final ARGB bytes
matched the captured non-stitch and stitch calls. One intermediate wrap-value
derivation still differs, but it was output-neutral for the captured stitch
fixture; do not change the kernel solely to reproduce that integer.

The important visual distinction is after the kernel. `feTurbulence` emits
straight linearRGB channels in KSVG. For a terminal turbulence filter with
`color-interpolation-filters="linearRGB"`, apply the existing UN_LINEARIZE LUT
to the straight RGB channels and preserve alpha before source-over compositing.
Do not apply this as a blanket filter-wide conversion: other primitives have
different output representations.

For `stitchTiles="stitch"`, tile-frequency quantization must use device-pixel
primitive extents, not a ceiling of the user-space region. The remaining
one-pixel bounds difference in the reference fixture comes from librsvg's
f32-parsed percentage geometry; do not introduce an empirical global geometry
offset to imitate it.

---

## 4. Native kernels (`:filtering`)

- `KotlinKernels.kt` is the Kotlin reference; `lighting.cpp` (NDK, built via
  `.cxx`) must stay bit-exact with it. Changes land in BOTH.
- `LightingNative.isAvailable == NativeGaussianBlur.isAvailable`; in Robolectric
  the native path is typically absent → Kotlin kernel runs.
- Caller-owned scratch state (`StackBlurScratch` etc.) — never global mutable
  state; reuse is owned by the current render operation and is not thread-shared.

### 4.1 i386 assembly and TEXTREL

Hand-written i386 assembly must be position-independent. Absolute references to
local literal-pool labels in `.text` create `R_386_32` relocations inside the
executable text segment; the resulting `DF_TEXTREL` library is rejected by
Android when native libraries are loaded from an uncompressed APK. The failure
usually appears only as a swallowed `UnsatisfiedLinkError`, leaving the native
kernel unavailable and silently selecting the Kotlin/scalar path.

For i386 kernels, establish a read-only literal-pool base with a local
`call`/`pop` pair and address constants relative to that register. Keep the
literal pool in the same output section as the code so the assembler/linker can
resolve the section difference at link time. Verify every x86-32 native build
with `llvm-readelf -d` (no `TEXTREL`) and `llvm-readelf -r` (no text-segment
`R_386_32` relocations), then run the forced native parity test on the x86
emulator; a successful build alone does not prove that the library will load.

### 4.2 ARMv7 NEON assembly — table lookup and macro gotchas

- **ARMv7 has no wide table lookup.** `vtbl.8 d12, {d10,d11}, d8` covers only 16
  entries (VTBL2 = two D registers), so a 256-entry LUT is a 16-row scan (row
  selected by the index high nibble). The scan counter must be explicitly bounded
  (`movs`/`adds`/`cmp`/`bne`); an unbounded `adds …; bne` loop runs 256 iterations
  × 16 bytes = 4096 bytes read — a 16× heap over-read of the caller's 256-byte LUT
  per lookup (hit in `arithmetic_composite_armv7a_neon.S`).
- **LLVM `.macro` token-paste.** `lsl #\shift` pastes when the argument already
  carries `#`: `\shift=#24` → `lsl ##24` (`error: invalid immediate shift value`).
  Pass bare numbers as shift args (`CHANNEL ..., 24, ...`); keep `#` only in the
  macro body.

---

## 5. Performance rules (REVIEW BEFORE HOT-PATH EDITS)

- `render()` and `updateAnimations()` must not allocate: no new `Matrix`,
  `PathShape`, `PathMeasure`, `RectF`, `FloatArray`.
- Use `RenderContext` pools (`matrixPool`, `rectFPool`, `bitmapPool`,
  `IntArrayBucket`), inline helpers (`forEachElement`), XFerModes constants.
- No capturing lambdas / local function references in hot paths.
- Build-path (parse, tree-build, filter-cache) is lenient; per-frame path is not.

---

## 6. Validation & acceptance

Unit/golden validation commands (re-run after render/filter changes):

```bash
# targeted single-SVG diff + summary metrics:
./gradlew :ksvg:testDebugUnitTest --tests "hu.oandras.ksvg.aihelpers.AiVisualDiffTest" \
  -PverifyFilter=lighting_point_spot -Dorg.gradle.warning.mode=none

# same SVG across all visual-comparison suites (VerificationVisualComparisonTest,
# FiltersVisualComparisonTest, MeteoconsVisualComparisonTest, AiVisualDiffTest):
./gradlew :ksvg:testDebugUnitTest --tests "hu.oandras.ksvg.aihelpers.AiVisualDiffTest" \
  -PverifyFilter=lighting_point_spot -Dorg.gradle.warning.mode=none
```

Golden sources: `rsvg-convert` (the `-b none` variant) via `CreateGoldenPngs`
(`GoldenImageUtils.renderReferenceGolden`). Threshold 0.95 in
`VisualComparisonTest` unless overridden by `ACCEPTED_SIMILARITY_EXCEPTIONS`
(noise/PRNG files only, with justification comments).

To only re-run with software filtering, `renderWithLibrary(svg, bitmap,
softwareFiltering = true)` and the shared `Bitmap.forEachPixel`/`countPixels`
helpers are used (see AGENTS.md).

Full suite: `./gradlew :ksvg:testDebugUnitTest -Dorg.gradle.warning.mode=none`

### 6.1 Kernel performance benchmarks (:filtering)

Detailed performance metrics for both Host (x86_64) and Device (ARM64) are maintained in the separate **[BENCHMARKS.md](BENCHMARKS.md)** file.

The 9 native kernels (`:filtering`, §4) have a shared throughput harness
(`KernelBenchmarkRunner`) driven from two places — a host JVM benchmark for the
x86 build and an instrumented device benchmark for ARM64. Both report the same
CSV columns (`Kernel,Backend,Size,AvgMs,MPix/s,GB/s,Speedup,IPC,CyclesPerIter`).

**Host (x86)** — `KernelPerformanceBenchmark`, output → `tmp/benchmarks_host*.csv`:

```bash
# single kernel, quick (1 iteration) — omit -D... for the full suite
./gradlew :filtering:testDebugUnitTest \
  --tests "hu.oandras.ksvg.filtering.KernelPerformanceBenchmark" \
  -Dbenchmark.kernel=Turbulence -Dbenchmark.quick=true -Dorg.gradle.warning.mode=none
```

The host parity run depends on `buildHostNativeLib` (compiles `libksvgblur` for
the host CPU); the `benchmark.*` JVM system props are forwarded to the test fork
by `testOptions.unitTests` in `filtering/build.gradle.kts`.

**Exporting CSV to Markdown Tables (`exportBenchmarkTable`)** — convert benchmark
CSV outputs (both host and device formats) to formatted Markdown tables adhering to
the strict ISA superset ordering (`kotlin → scalar → sse2 → ssse3 → avx2 → avx512`
/ `neon32 → neon64`):

```bash
# Convert host or device benchmark CSV into a Markdown table:
./gradlew :filtering:exportBenchmarkTable \
  -Pcsv=tmp/benchmarks_host.csv \
  -Dorg.gradle.warning.mode=none

# Optionally specify a custom output path (defaults to matching .md next to .csv):
./gradlew :filtering:exportBenchmarkTable \
  -Pcsv=tmp/benchmarks_host.csv \
  -Poutput=tmp/custom_table.md \
  -Dorg.gradle.warning.mode=none
```

The task groups measurements by `(Kernel, Size)`, sorts backend rows into standard
ISA progression, calculates speedup metrics vs scalar/Kotlin, and decorates rows with
status indicators (🚀, 🟢, 🔴, ⬆️) ready for pasting into `BENCHMARKS.md`.

**Device (ARM64)** — `runDeviceBenchmark` wrapper (runs `connectedDebugAndroidTest`,
auto-`adb pull`s the CSVs from the device's `externalCacheDir` into `tmp/device-bench-<abi>/`
(`tmp/device-bench-arm64-v8a/`, `tmp/device-bench-armeabi-v7a/`, … — the ABI the benchmark process actually
ran as), then prints them as a Markdown table). The device benchmark
(`KernelPerformanceDeviceBenchmark`, src/androidTest) runs every kernel through the
stable `nativeBenchmark { }` harness — see §6.2:

```bash
./gradlew :filtering:runDeviceBenchmark \
  -Pandroid.testInstrumentationRunnerArguments.class=hu.oandras.ksvg.filtering.KernelPerformanceDeviceBenchmark \
  -Pandroid.testInstrumentationRunnerArguments.benchmark.quick=true
```

- The instrumentation args the benchmark reads are `benchmark.kernel` (name filter; omit
  for the full suite) and `benchmark.quick` (`true` = 512x512 only). Each
  (kernel, backend, size) cell is its own harness block → one summary + one detail CSV
  per cell (`benchmarks_device_harness_<kernel>_<backend>_<size>.csv` /
  `benchmarks_harness_detail_<kernel>_<backend>_<size>.csv`), all matched by the
  `benchmarks_device*.csv` pull glob.
- Requires a connected device. The pull works because the project enables
  `android.injected.androidTest.leaveApksInstalledAfterRun=true` (the test APK —
  and its cache dir) is left installed after the run, and the pull reads the
  canonical `/storage/emulated/0/Android/data/<pkg>/cache/` path.
- `class=hu.oandras.ksvg.filtering.KernelPerformanceDeviceBenchmark` restricts
  the run to the benchmark so the parity/device tests don't also execute.

**32-bit (ARMv7 NEON32) test builds** — pass `-PfilterAbis=armeabi-v7a` to build a
32-bit-only test APK. This lets you exercise the ARM32 NEON kernels
(`convolve_armv7a_neon.S`, `blur_armv7a_neon.S`) on arm64 devices (which also support v7a),
where the benchmark/parity instrumentation reports the `neon32` backend instead of
`neon64`. Multiple ABIs are comma-separated, e.g. `-PfilterAbis=armeabi-v7a,arm64-v8a`.
Without the property all ABIs build as usual (this is wired in
`filtering/build.gradle.kts` via `defaultConfig.ndk.abiFilters`).

```bash
# 32-bit-only device benchmark for the ConvolveMatrix kernel:
./gradlew :filtering:runDeviceBenchmark \
  -PfilterAbis=armeabi-v7a \
  -Pandroid.testInstrumentationRunnerArguments.class=hu.oandras.ksvg.filtering.KernelPerformanceDeviceBenchmark \
  -Pandroid.testInstrumentationRunnerArguments.benchmark.kernel=ConvolveMatrix \
  -Pandroid.testInstrumentationRunnerArguments.benchmark.quick=true
```

**x86 (i386 / 32-bit) test builds** — pass `-PfilterAbis=x86` to build a
32-bit-only test APK for emulators. This lets you exercise the i386 kernels
(`turbulence_noise_i386_avx2.S`, `lighting_distant_diffuse_i386_sse2.S`) on
emulated x86 environments.

```bash
# 32-bit-only emulator benchmark for the Turbulence kernel:
./gradlew :filtering:runDeviceBenchmark \
  -PfilterAbis=x86 \
  -Pandroid.testInstrumentationRunnerArguments.class=hu.oandras.ksvg.filtering.KernelPerformanceDeviceBenchmark \
  -Pandroid.testInstrumentationRunnerArguments.benchmark.kernel=Turbulence \
  -Pandroid.testInstrumentationRunnerArguments.benchmark.quick=true
```

Methodology note: for everything except Morphology, `ms` is the raw-runner
**average** (2026-09-02); the Morphology rows come from the stable `nativeBenchmark { }`
harness (spec §6.2, median of 5 batches with warmup + thermal gating + batch-CV
classifier, measured 2026-09-05 on the same OnePlus 12 / SM8550). Scalar-vs-SIMD
speedups are only directly comparable within the same run (CPU-frequency/thermal
drift makes cross-session absolute times differ — e.g. Morphology scalar 512² was
286.3 ms avg in the 2026-09-02 run vs ~200 ms harness median here). The Morphology
`neon64` row median (15.979 ms @512², 224.114 ms @2048²) is the post-2026-09-05
optimization revision of the hand-written AArch64 kernel (`morphology_neon64.S`):
the tail loop was replaced by a straight-line 1-or-3-pixel tail (`tbz w12, #1`) and
the per-iteration `cbz` was hoisted out of the vector loop; the previous inline NEON
path measured **0.44x** vs scalar.

- 2026-09-07 — Ported the full row/pixel/octave loop logic to x86_64 and i386
  assembly for the feTurbulence filter (AVX2 and SSE2 backends). This matches the
  full-loop-in-ASM architecture of the AArch64 version, reducing C++ overhead and
  enabling future interleaving optimizations. Unified symbol naming for Convolve
  and Lighting across all x86 variants to simplify dispatch and library linking.
  Enabled Mach-O compatibility for host benchmarking on macOS by porting section
  directives and commenting out ELF-specific SIZE attributes.

---

### 6.2 Stable native benchmark harness (androidTest, Steps 0-8 done)

A stable, long-running **harness** for comparing native/NEON kernel work (e.g. `old
assembly vs new assembly`) lives in `filtering/src/androidTest/.../benchmark/`
(`NativeBenchmarkHarness.kt`, DSL `nativeBenchmark { }`; spec = `tmp/TEST_HARNESS.md`,
plan = `TEST_HARNESS_PLAN.md`, findings = `tmp/TEST_HARNESS_WORKLOG.md`). The device
kernel benchmark (`KernelPerformanceDeviceBenchmark`, §6.1) runs every filter kernel
(UnLinearize, ComponentTransfer, Morphology, ArithmeticComposite non-linear + linear,
ConvolveMatrix, DisplacementMap, Lighting, Turbulence, GaussianBlur) through it — the
Morphology-only `TurbulenceNativeHarnessBenchmark` was the step-7 precursor and was
removed once the general driver landed.

It provides, per benchmark block (measured region = **only the JNI call**, spec §20):

- foreground `BenchmarkActivity` + focus wait (the window is held by the same process
  that loads `libksvgblur`),
- benchmark-thread priority key: bump `setThreadPriority(myTid(), -20)`, restored at end,
- `warmup` → repeated `measurementBatches` × `iterationsPerBatch`, per-iteration
  `System.nanoTime()` sampling, with **warmup-based batch calibration**: when
  `targetBatchMillis > 0` (driver: 100 ms), the warmup iterations are timed (≥
  `MIN_CALIBRATION_SAMPLES` = 32 samples) and the **P25 of the sorted times** (robust against
  GC/JIT storms inflating most samples) calibrates `effectiveIterationsPerBatch =
  clamp(targetBatchMillis / p25ms, iterationsPerBatch, max(IterationsPerBatch,
  maxIterationsPerBatch=200))`. Sub-ms kernels thus gather enough samples per batch for the
  batch-average-CV rule to average out per-iteration timer/GC noise (~1/√n) instead of being
  flagged `UNSTABLE`; `targetBatchMillis=0` keeps the legacy exact-count behavior. Per-iteration
  UI progress pushes are rate-limited (~10/s) so the measured loop stays ~allocation-free —
  a `BenchmarkUiState` push per iteration parked the GC mid-batch and was the noise source,
- one `CacheNormalizer.normalize()` (deterministic 1 MB×2 copy/touch) before each batch,
  outside the measurement,
- thermal gating (`ThermalStateMonitor`): API 29+ `PowerManager.currentThermalStatus`;
  API<29 deterministic compute-probe fallback (baseline once per run, >10% degradation =
  throttled). A batch measured while throttled is **invalidated** → configurable cooldown
  (`cooldownMillis`, default 5 s) → fresh batch; `invalidatedBatches` / `cooldownTimeMs`
  are tracked,
- per-sample statistics (`BenchmarkStats`: min/median/mean/max/p90/p95/p99/stddev;
  compare by median → p90 → min),
- classification (spec §15): `VALID / THERMAL_THROTTLED / THERMAL_RECOVERY /
  UNSTABLE / INSUFFICIENT_SAMPLES`, `isValid` flag (batch-average CV > 5% → `UNSTABLE`),
- environment report (spec §16): device/model/abi/coreCount, SoC (`CpuInfo`:
  QTI SM8550 on the test device), sustained-mode result, `thermalStatusBefore/After`,
  `invalidatedBatches`/`cooldownTimeMs`, best-effort sysfs CPU frequency
  `cpuFreqBeforeKhz`/`cpuFreqAfterKhz`, `cpuAffinityControlAvailable` (always `false`,
  no root), plus the calibration keys `requestedIterationsPerBatch`/
  `effectiveIterationsPerBatch`/`calibratedPerIterationMs`/`targetBatchMillis`/
  `maxIterationsPerBatch`.

CSV (pull-compatible with `runDeviceBenchmark`'s `benchmarks_device*.csv` glob):

```text
# summary — benchmarks_device_harness_<kernel>_<backend>_<size>.csv
Kernel,Backend,Size,MinMs,MedianMs,MeanMs,MaxMs,P90,P95,P99,StdDevMs,MPix/s,InvalidatedBatches,CooldownMs,Classification,VALID

# detail — benchmarks_harness_detail_<kernel>_<backend>_<size>.csv
env,<key>=<value> ...        # environment block
batch,iteration,ms           # per-sample rows
```

Commands (device serial = e.g. `adbca122`):

```bash
./gradlew :filtering:assembleDebugAndroidTest -PfilterAbis=arm64-v8a -Dorg.gradle.warning.mode=none
adb -s adbca122 install -r -t filtering/build/outputs/apk/androidTest/debug/filtering-debug-androidTest.apk
adb -s adbca122 logcat -c
adb -s adbca122 shell am instrument -w \
  -e class hu.oandras.ksvg.filtering.KernelPerformanceDeviceBenchmark \
  -e benchmark.kernel Turbulence -e benchmark.quick true \
  hu.oandras.filtering.test/androidx.test.runner.AndroidJUnitRunner
adb -s adbca122 logcat -d -s System.out
```

`KernelPerformanceDeviceBenchmark` covers every native backend (scalar, neon64, …) ×
both sizes (512² / 2048²; quick = 512² only) per kernel and honours the
`benchmark.kernel` / `benchmark.quick` args. Buffer reuse means the measured region is
exactly the JNI call (spec §20). The raw-vs-harness comparison lives in
`HarnessValidationRawTest` (spec §22). Console output example:

```text
=== Benchmark: Turbulence (neon64) 512x512 ===
thermalSource=powerManager        thermalStatusBefore=0  thermalStatusAfter=0 ...
stats(count=50) min=4.4414 p90=4.4981 median=4.4679 mean=4.4699 p95=4.5042 max=4.5168
classification=VALID valid=true invalidatedBatches=0 cooldownTimeMs=0
```

**Device findings (OnePlus 11 / CPH2449, SDK 36, SM8550, non-root)** — relevant to
trusting long bench runs on this device:

- Sustained performance mode is **unsupported** (`sustainedPerformanceMode=false`);
  reported, never asserted.
- `PowerManager.currentThermalStatus` stays `NONE` even while performance drifts
  ~15-20% (observed across sessions); the **sysfs `scaling_cur_freq` read is the
  load-bearing signal** — e.g. 1.555 → 1.459 GHz across one run with status 0 the whole
  time. Every CSV carries `cpuFreqBeforeKhz`/`cpuFreqAfterKhz`.
- The batch-average-CV classifier flags exactly that drift: an early-fast / later-slow
  scalar run scored `UNSTABLE` `valid=false` while the neon64 cell in the same run scored
  `VALID`.
- Not active on this device (reported as false/unavailable): sustained mode, CPU-affinity
  pinning.

---

### 6.3 Native-kernel decisions that affect rendering correctness

These are implementation invariants, not benchmark-specific optimizations:

- Native kernels are compared against the scalar/Kotlin reference
  byte-for-byte by default wherever the parity suite requires it (documented
  per-kernel tolerances excepted: Gaussian-blur SIMD tails ±1 LSB,
  specular lighting `maxDelta = 1`). Keep reference
  operation order; rewrites such as `x / 255.0f` → `x * (1 / 255.0f)` can
  change the final rounded byte. (Scope note: this near-exact gate covers
  CPU scalar/Kotlin vs CPU native/SIMD only — it does NOT apply to the
  GPU/RenderEffect/AGSL path, which is tolerance-based per §2.)
- Production dispatch may fall back to scalar when a SIMD backend loses on its
  target. The forced executor is intentionally separate so disabled candidates
  can still be parity-tested and measured.
- ARM32 and AArch64 assembly use separate argument layouts and register maps.
  ARM32 has q0-q15 only and must preserve d8-d15. Keep layout assertions next
  to the C++ argument structs.
- Assembly tables and literal pools must be PIC-safe. Absolute local pointers
  can produce Android text relocations, causing a load failure and an apparent
  scalar fallback. Validate the linked i386 artifact, not just assembly.
- Thin edge bands often lose with SIMD coordinate handling and temporary
  spills. Reserve SIMD for the interior, specialize scalar edge sampling, and
  route short tails outside full-vector stores.
- Exact 256-entry LUT transforms are a known exception: 128-bit lookup
  cascades can lose to scalar even when bit-exact. Keep them scalar on those
  targets unless a measured wider-vector path wins.
- Validation corpora must exercise all LUT entries and alpha values, vector
  boundaries, odd-width tails, in-place and out-of-place buffers, and guarded
  memory regions through the actual JNI/native entry point. A backend that was
  only compiled is unverified.

---

### 6.4 Host-Compatible Performance Auditing & Profiling

The host-JVM benchmark suite (`KernelPerformanceBenchmark`) includes an optional detailed hardware profiling engine for auditing SIMD kernel efficiency directly on development machines (macOS and Linux). It provides per-thread metrics similar to Android's `simpleperf`, allowing for deep architectural analysis (IPC, Cycles) without a device.

**Metrics Provided:**
- **Avg Time (ms)**: Wall-clock time.
- **IPC (Instructions Per Cycle)**: Measures execution density. Values > 2.0 indicate high SIMD utilization on modern cores.
- **Cycles/Iter**: Raw CPU cycles executed for a single kernel call.
- **Throughput**: MPix/s and GB/s.

**Supported Platforms:**
- **macOS (Intel & Apple Silicon)**: Uses the private `kpc` (Kernel Performance Counters) API for thread-local PMC access.
- **Linux (x86_64 & ARM64)**: Uses the `perf_event_open` syscall to read hardware performance counters.
- **Windows**: Fallback to `NoOp` (timing only).

**Command to run with profiling:**
Pass the `-Dbenchmark.host.profile=true` system property to the test task.

```bash
./gradlew :filtering:testDebugUnitTest \
  --tests "hu.oandras.ksvg.filtering.KernelPerformanceBenchmark" \
  -Dbenchmark.host.profile=true \
  -PshowTestOutput --console=plain
```

The output report will automatically include the **IPC** and **Cycles/Iter** columns in the Markdown table. If hardware counters are restricted by the OS (e.g., `perf_event_paranoid` on Linux), it gracefully falls back to raw timing.

---

## 7. Change log (append)

- 2026-08-30 — Document created. Recorded: two-phase render model, software/HW
  backend parity, region subregion-defaulting, lighting straight-vs-premultiplied
  finding (`lighting_point_spot`), spot-cone factor semantics from librsvg
  `lighting.rs`.
- 2026-08-31 — Implemented the `premultipliedOutput` flag for terminal
  `feSpecularLighting` (details in §3.1). Threaded through
  `SoftwareFilterBackend` → `FilterLighting.kt` → `KotlinKernels.lighting` +
  `LightingNative.apply` (JNI) + native `lighting.cpp` (`applyScalar`/`applyVector`),
  bit-exact. Validated: `lighting_point_spot` 0.425 → 0.722; `filter_specular.svg`
  unchanged (0.981); native builds on all 4 ABIs. Residual gap to 0.95 is the
  separate diffuse-brightness divergence (§3.3).
- 2026-09-03 — Documented the `:filtering` kernel benchmark commands (host +
  device) in §6.1 (see NATIVE_VALIDATION_WORKLOG 2026-09-02 for the measured
  results). Added the `runDeviceBenchmark` wrapper task, which forwards
  `-Pandroid.testInstrumentationRunnerArguments.*` (class/kernel/benchmark.quick)
  to `connectedDebugAndroidTest`, then pulls `benchmarks_device*.csv` from the
  device cache dir into `tmp/` and prints it as a Markdown table. The pull relies
  on `android.injected.androidTest.leaveApksInstalledAfterRun=true`.
- 2026-09-04 — Implemented the ARMv7-A NEON32 ConvolveMatrix interior kernel
  (`convolve_neon32.S`), shared the edge-mode-parameterized scalar helpers in
  `convolve_matrix_neon.cpp` across aarch64/arm32, and routed NEON32 through
  `runForced`/`apply` in `convolve_matrix.cpp` (all `edgeMode`s supported, like
  aarch64). Validation: all-ABI native build clean; host parity pass; on-device
  parity 18/18. Added `-PfilterAbis` (32-bit-only test APK) to §6.1. On-device
  quick benchmark: neon32 ConvolveMatrix **7.41x** @512x512 (16.1ms), **7.27x**
  @2048x2048 (241.2ms) vs scalar.
- 2026-09-05 — Completed the stable native benchmark harness (Steps 0-8,
  spec `tmp/TEST_HARNESS.md`) and documented it in §6.2: `nativeBenchmark { }` DSL,
  foreground window + focus wait, thread-priority keying, warmup/batch model,
  per-batch cache normalization, thermal gating with cooldown/retry
  (`ThermalStateMonitor` API 29+ status + API<29 probe fallback), stats + five-way
  classification, environment/SoC/CPU-frequency report, summary+detail CSV
  pull-compatible with `runDeviceBenchmark`. Migrated the device Turbulence driver
  onto the harness (all backends × 512²/2048², `benchmark.kernel`/`benchmark.quick`
  compat) and added the raw-vs-harness validation test (`HarnessValidationRawTest`,
  spec §22). Key device finding: on the OnePlus 12 (SM8550) sustained mode is
  unsupported and `currentThermalStatus` stays `NONE` while CPU frequency drifts
  (sysfs `scaling_cur_freq` is the reliable signal); the batch-CV classifier flags
  such drift as `UNSTABLE`.
- 2026-09-05 — Generalised the harness to the whole device kernel suite:
  `KernelPerformanceDeviceBenchmark` (src/androidTest) now runs **all** kernels
  (UnLinearize, ComponentTransfer, Morphology, ArithmeticComposite non-linear +
  linear, ConvolveMatrix, DisplacementMap, Lighting, Turbulence, GaussianBlur)
  through `nativeBenchmark { }`, one harness block per (kernel, backend, size) cell,
  replacing the old raw `KernelBenchmarkRunner` driver. `quick` = 512² only; 2048²
  cells use 3 iterations/batch (vs 10 at 512²) to keep the larger kernels bounded.
  Fixed two latent driver bugs while migrating: ConvolveMatrix now passes a proper
  25-element 5x5 weight array (the old 9-float array + order-5 was an OOB read), and
  the ArithmeticComposite `(linear)` variant now actually sets `useLinear=true`.
  Removed the superseded Turbulence-only `TurbulenceNativeHarnessBenchmark`;
  `KernelBenchmarkRunner` is host-JVM-only again.
- 2026-09-05 — Replaced the AArch64 morphology interior loop (erode/dilate) with a
  hand-written kernel (`morphology_neon64.S`): wired into CMake for arm64-v8a and into
  both `applyForced`/`apply` via an `extern "C"` declaration under `__aarch64__`. Fixed
  a critical register-aliasing bug in its tail loop (`w14`/`x14` — the per-row cursor
  `mov x14, x15` trashed the tail counter held in `w14`, causing out-of-bounds reads /
  effectively unbounded loops for every odd kernel width) and normalized the byte
  stride to `sxtw(w2)`. Device parity (scalar + neon64 forced backends vs the Kotlin
  reference across the `MorphologyValidationCorpus`): **OK (108 tests)**; host parity
  and `buildHostNativeLib` green. Updated the §6.1 Device Results table with a harness
  run: neon64 Morphology is now **12.6x** @512² (15.8 ms) and **13.7x** @2048²
  (238.9 ms) vs scalar in the same run, where the previous inline NEON path measured
  **0.44x**. CSVs: `tmp/benchmarks_device_harness_Morphology_*.csv`.
- 2026-09-05 — Optimized `morphology_neon64.S` (points 1, 2, 3, 5, 7 of the code review):
  fixed a critical bug where vertical accumulators were not reset per column group in the row kernel;
  removed the reserved `x18` register on AArch64 (using post-indexed loads instead); clarified
  the horizontal-only cache comment; implemented true 4-way independent accumulator chains in the
  vector loops; structurally eliminated the `w14`/`x14` counter/cursor aliasing bug class using
  a straight-line `tbz w12, #1` tail. Device parity re-run:
  **OK (108 tests)**; harness medians re-measured in the same run: scalar 200.2 /
  neon64 15.98 ms @512² (**12.5x**) and scalar 3295.6 / neon64 224.1 ms @2048²
  (**14.7x**). The 2048² cell improved ~6% over the pre-optimization revision
  (238.9 -> 224.1 ms); 512² is within noise. §6.1 table refreshed.
- 2026-09-06 — Standardized assembly naming convention to `<feature>_<arch>_<isa>.S`
  across the whole project (Morphology, Blur, Convolve, Turbulence, ArithmeticComposite, Lighting).
  Integrated hand-written distant-light diffuse lighting assembly kernels for all
  architectures (aarch64, armv7a, x86_64, i386) including SSE2, AVX2 and AVX512
  variants for x86.
- 2026-09-09 — Documented ARMv7 NEON assembly gotchas in §4.2 (16-entry VTBL2
  LUT-scan bound; LLVM `.macro` token-paste for shift args).
- 2026-09-10 — Consolidated validated native-kernel guidance: parity-first
  arithmetic, production-vs-forced dispatch, ARM32 ABI/PIC hazards, scalar
  thin-edge specialization, and the measured 128-bit LUT exception (§6.3).
- 2026-09-10 — Added the closed turbulence findings: kernel parity against
  librsvg, device-pixel stitch tile quantization, and the narrowly scoped
  straight-linearRGB terminal transfer (§3.4).
- 2026-09-13 — Removed the i386 AVX-512 assembly rows
  (`morphology_i386_avx512.S`, `lighting_distant_specular_i386_avx512.S`, and the
  never-built WIP `lighting_distant_diffuse_i386_avx512.S`). They were untestable
  everywhere: the Android emulator's HVF guest masks every AVX-512 CPUID bit on
  both x86 and x86_64 (verified on API 26/30/37), 32-bit x86 images end at
  API 30, and there is no host i386 toolchain to validate against. The x86_64
  AVX-512 rows stay (host-native build + host benchmarks validate them). i386
  morphology now dispatches SSE2/AVX2 only; i386 specular lighting SSE2/AVX2;
  `nativeBackendForAbi` on i386 never advertises `SIMD_BACKEND_AVX512` (lighting,
  convolve report functions fixed to match: AVX512 gated on x86_64 only).
- 2026-09-13 — Fixed sibling AVX2-detection bug uncovered by the same emulator
  CPUID audit: `detectSimdLevel()` keyed AVX2 on `__builtin_cpu_supports("avx2")`,
  which in the emulator guest additionally demands `CPUID.1:ECX.OSXSAVE`; the
  HVF mask clears that bit even though `XCR0.YMM` is provably enabled and the
  AVX-256 kernels execute correctly (execution probe verified on API 37). New
  `cpuHasAvx2Raw()` in `cpu_dispatch.h` reads the real state instead of the
  OSXSAVE *report*: CPUID leaf1 XSAVE (a sanity precondition for XCR0/XGETBV)
  → actual `XCR0.YMM` via `xgetbv` (proves the OS saves/restores the YMM state
  AVX requires) → CPUID leaf7 EBX bit5. On real silicon the result equals
  normal detection (host probe: level=AVX512), because XCR0.YMM and the
  OSXSAVE bit are always set together there. AVX-512 detection deliberately
  stays on `__builtin_cpu_supports` — raw detection must never unlock a backend
  that would `#UD` in the emulator. Emulator now detects **AVX2** instead of
  SSSE3.
- 2026-09-13 — Added NEON `useLinear` (linearRGB) distant-diffuse rows to match
  the x86 `*Linear` kernels (§3.3): `ksvgLightingDistantDiffuseRowNeon64Linear`
  (aarch64; full-256-LUT `tbl` conversion, LUT resident in v16-v31) and
  `ksvgLightingDistantDiffuseRowNeon32Linear` (armv7a; scalar per-pixel `ldrb`
  lookups into the reference `ksvg_linear_to_srgb_lut`, mirroring the i386
  SSSE3 `*Linear` row because only 16 q-regs are available). `lighting.cpp`
  wires both and sets `allowDiffuseLinear = true` unconditionally. Parity on
  CPH2449: NEON64 16/16 and NEON32 16/16 (`LightingNativeParityTest`, incl.
  `distant diffuse linear 16x16`); host x86_64 24/24. Previously this combo
  silently used the scalar fallback on ARM.
- 2026-09-13 — Replaced the x86_64 distant-light baseline rows: the SSE2
  lighting asm (`lighting_distant_{diffuse,specular}_x86_64_sse2.S`) was
  rewritten/renamed to SSSE3 (`*_ssse3.S`, symbols `...RowSsse3`), gaining new
  `...Linear` entry points that amortize the linear->sRGB byte mapping in place.
  Wired dispatch, `simd_x86.h` externs, and CMake source lists (base + host).
  x86_64 lighting now advertises `SIMD_BACKEND_SSSE3` as its baseline (i386
  stays SSE2); the parity test forces scalar/ssse3/avx2 over the corpus.
- 2026-09-13 — Dropped the x86_64 AVX-512 distant-light kernels
  (`lighting_distant_{diffuse,specular}_x86_64_avx512.S`). The 16-lane loops
  crashed the full suite with SIGABRT in `.L_loop_avx512` (host benchmark runs;
  the parity corpus never exercised them because widths ≤ 16 leave 0 avx512
  lanes). Removed the dispatch case, the `simd_x86.h` externs, the CMake source
  entries (main + host), and the AVX512 advertisement from
  `nativeBackendForAbi`/`apply`. x86_64 lighting now tops out at `AVX2` (`avx2`
  rows become the widest advertised backend; parity forces scalar/ssse3/avx2).
  Parity still green (21 cases), full `:filtering` suite no longer crashes.
- 2026-09-14 — Integrated host-compatible hardware profiling (Intel/ARM macOS and
  Linux) into the kernel benchmark runner. Added JNI wrappers for the macOS `kpc`
  API and Linux `perf_event_open` syscall to measure IPC and CPU cycles for hot-path
  auditing. Moved `KernelBenchmarkRunner` to the `:filtering` test source set to
  isolate host-only dependencies.
