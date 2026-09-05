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

The two MUST agree (parity). The committed subregion-defaulting work (see
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

---

## 4. Native kernels (`:filtering`)

- `KotlinKernels.kt` is the Kotlin reference; `lighting.cpp` (NDK, built via
  `.cxx`) must stay bit-exact with it. Changes land in BOTH.
- `LightingNative.isAvailable == NativeGaussianBlur.isAvailable`; in Robolectric
  the native path is typically absent → Kotlin kernel runs.
- Caller-owned scratch state (`StackBlurScratch` etc.) — never global mutable
  state; reuse is owned by the current render operation and is not thread-shared.

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

### 6.1 Kernel performance benchmarks (`:filtering`)

The 9 native kernels (`:filtering`, §4) have a shared throughput harness
(`KernelBenchmarkRunner`) driven from two places — a host JVM benchmark for the
x86 build and an instrumented device benchmark for ARM64. Both report the same
CSV columns (`Kernel,Backend,Size,AvgMs,MPix/s,GB/s,Speedup`).

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

**Device (ARM64)** — `runDeviceBenchmark` wrapper (runs `connectedDebugAndroidTest`,
auto-`adb pull`s the CSV from the device's `externalCacheDir` into `tmp/`, then
prints it as a Markdown table):

```bash
./gradlew :filtering:runDeviceBenchmark \
  -Pandroid.testInstrumentationRunnerArguments.class=hu.oandras.ksvg.filtering.KernelPerformanceDeviceBenchmark \
  -Pandroid.testInstrumentationRunnerArguments.benchmark.quick=true
```

- The instrumentation args the benchmark reads are `benchmark.kernel` (name filter; omit
  for the full suite) and `benchmark.quick` (`true` = 1 iteration).
- Requires a connected device. The pull works because the project enables
  `android.injected.androidTest.leaveApksInstalledAfterRun=true` (the test APK —
  and its cache dir) is left installed after the run, and the pull reads the
  canonical `/storage/emulated/0/Android/data/<pkg>/cache/` path.
- `class=hu.oandras.ksvg.filtering.KernelPerformanceDeviceBenchmark` restricts
  the run to the benchmark so the parity/device tests don't also execute.

**32-bit (ARMv7 NEON32) test builds** — pass `-PfilterAbis=armeabi-v7a` to build a
32-bit-only test APK. This lets you exercise the ARM32 NEON kernels
(`convolve_neon32.S`, `Blur_advsimd.S`) on arm64 devices (which also support v7a),
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

### Host Results (i7-7820X)

| Kernel | Backend | Size | Avg ms | MPix/s | GB/s | Speedup |
| :--- | :--- | :---: | ---: | ---: | ---: | ---: |
| Unlinearize | scalar | 512x512 | 1.333 | 196.62 | 1.57 | 1.00x |
| Unlinearize | ssse3 | 512x512 | 0.541 | 484.84 | 3.88 | 2.47x |
| Unlinearize | avx2 | 512x512 | 0.312 | 839.34 | 6.71 | 4.27x |
| ComponentTransfer | scalar | 512x512 | 0.475 | 551.70 | 4.41 | 1.00x |
| ComponentTransfer | avx2 | 512x512 | 0.448 | 585.40 | 4.68 | 1.06x |
| Morphology | scalar | 512x512 | 23.678 | 11.07 | 0.09 | 1.00x |
| Morphology | avx2 | 512x512 | 9.691 | 27.05 | 0.22 | 2.44x |
| ConvolveMatrix | scalar | 512x512 | 10.402 | 25.20 | 0.20 | 1.00x |
| ConvolveMatrix | avx512 | 512x512 | 1.406 | 186.43 | 1.49 | 7.40x |
| DisplacementMap | scalar | 512x512 | 2.524 | 103.87 | 1.25 | 1.00x |
| DisplacementMap | ssse3 | 512x512 | 0.715 | 366.54 | 4.40 | 3.53x |
| Lighting | scalar | 512x512 | 7.803 | 33.59 | 0.27 | 1.00x |
| Lighting | ssse3 | 512x512 | 3.855 | 68.00 | 0.54 | 2.02x |
| GaussianBlur | scalar | 512x512 | 21.140 | 12.40 | 0.10 | 1.00x |
| GaussianBlur | avx2 | 512x512 | 10.768 | 24.34 | 0.19 | 1.96x |
| Turbulence | scalar | 512x512 | 16.247 | 16.13 | 0.06 | 1.00x |
| Turbulence | ssse3 | 512x512 | 7.449 | 35.19 | 0.14 | **2.18x** |
| Turbulence | avx2 | 512x512 | 6.017 | 43.57 | 0.17 | **2.70x** |

### Device Results (Snapdragon 8 Gen 2)

| Kernel | Backend | Size | Avg ms | MPix/s | GB/s | Speedup |
| :--- | :--- | :---: | ---: | ---: | ---: | ---: |
| Unlinearize | scalar | 512x512 | 1.282 | 204.53 | 1.64 | 1.00x |
| Unlinearize | neon64 | 512x512 | 33.992 | 7.71 | 0.06 | **0.04x** |
| ComponentTransfer | scalar | 512x512 | 2.848 | 92.05 | 0.74 | 1.00x |
| ComponentTransfer | neon64 | 512x512 | 39.201 | 6.69 | 0.05 | **0.07x** |
| Morphology | scalar | 512x512 | 286.274 | 0.92 | 0.01 | 1.00x |
| Morphology | neon64 | 512x512 | 647.917 | 0.40 | 0.00 | **0.44x** |
| ConvolveMatrix | scalar | 512x512 | 90.549 | 2.90 | 0.02 | 1.00x |
| ConvolveMatrix | neon64 | 512x512 | 9.580 | 27.36 | 0.22 | **9.45x** |
| DisplacementMap | scalar | 512x512 | 8.261 | 31.73 | 0.38 | 1.00x |
| DisplacementMap | neon64 | 512x512 | 13.300 | 19.71 | 0.24 | **0.62x** |
| GaussianBlur | scalar | 512x512 | 357.167 | 0.73 | 0.01 | 1.00x |
| GaussianBlur | neon64 | 512x512 | 6.398 | 40.97 | 0.33 | **55.83x** |
| Turbulence | scalar | 512x512 | 131.544 | 1.99 | 0.01 | 1.00x |

---

### 6.2 Stable native benchmark harness (androidTest, Steps 0-8 done)

A stable, long-running **harness** for comparing native/NEON kernel work (e.g. `old
assembly vs new assembly`) lives in `filtering/src/androidTest/.../benchmark/`
(`NativeBenchmarkHarness.kt`, DSL `nativeBenchmark { }`; spec = `tmp/TEST_HARNESS.md`,
plan = `TEST_HARNESS_PLAN.md`, findings = `tmp/TEST_HARNESS_WORKLOG.md`). It is the
preferred device path for Turbulence going forward.

It provides, per benchmark block (measured region = **only the JNI call**, spec §20):

- foreground `BenchmarkActivity` + focus wait (the window is held by the same process
  that loads `libksvgblur`),
- benchmark-thread priority key: bump `setThreadPriority(myTid(), -20)`, restored at end,
- `warmup` → repeated `measurementBatches` × `iterationsPerBatch`, per-iteration
  `System.nanoTime()` sampling,
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
  no root).

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
  -e class hu.oandras.ksvg.filtering.benchmark.TurbulenceNativeHarnessBenchmark \
  -e benchmark.quick true \
  hu.oandras.filtering.test/androidx.test.runner.AndroidJUnitRunner
adb -s adbca122 logcat -d -s System.out
```

The migrated `TurbulenceNativeHarnessBenchmark` covers every native backend (scalar,
neon64, …) × both sizes (512² / 2048²; quick = 512² only) and honours the
`benchmark.kernel` / `benchmark.quick` args. The old raw path
`KernelPerformanceDeviceBenchmark` is kept for the raw-vs-harness comparison
(`HarnessValidationRawTest`, spec §22). Console output example:

```text
=== Benchmark: Turbulence (neon64) 512x512 ===
thermalSource=powerManager        thermalStatusBefore=0  thermalStatusAfter=0 ...
stats(count=50) min=4.4414 p90=4.4981 median=4.4679 mean=4.4699 p95=4.5042 max=4.5168
classification=VALID valid=true invalidatedBatches=0 cooldownTimeMs=0
```

**Device findings (OnePlus 12 / CPH2449, SDK 36, SM8550, non-root)** — relevant to
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