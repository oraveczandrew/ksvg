# Execution Plan — Unified Filter Pipeline (Reports 1–3), detailed

Prerequisites: **Report 4 (RenderScene / bounds-update) is DONE** — the render tree is
updatable in place, `RenderScene` exists, contentVersion-based display-list invalidation works.

---

## 1. Current state (code map)

Filter execution today lives entirely in `ksvg` module:

| Concern | Location |
|---|---|
| Filter entry + source re-render + cache | `Renderer.renderWithFilter` (Renderer.kt:934–1075) — inline, pooled rects/matrices, `node.cachedFilterOutput` keyed by contentVersion + filterNode.version + scale |
| Per-primitive loop | `Renderer.applyFilterToBitmap` (1162–1232) → `applyPrimitive` (1234+) via `when(primitiveNode)` |
| Primitive implementations | `render/filters/`: `FilterPixels.kt` (convolve edge sampling, component transfer), `FilterGeneration.kt` (turbulence — double-based Kotlin loop), `FilterGeometry.kt` (morphology, displacement), `FilterComposition.kt`, `FilterColor.kt`, `FilterLighting.kt` |
| Named-result bookkeeping | `FilterSourceMap` (per-`FilterRenderNode`, reused via `reInitWith`) |
| Blur scratch | `RenderNode.blurScratch: StackBlurScratch` (RenderNode.kt:477) — caller-owned precedent |
| Native blur module | `:nativeblur`: `NativeGaussianBlur.kt`, `StackBlur.kt`, cpp: `gaussian_blur.cpp` + `Blur_advsimd{,64}.S` + `x86.cpp` scalar fallback |

## 1b. Third-party source verification (actually reviewed)

### renderscript-intrinsics-replacement-toolkit (`tmp/renderscript-intrinsics-replacement-toolkit/`)
- **Instance-based, NOT singleton-forced**: `Toolkit.kt` uses
  `createNative(): Long / destroyNative(handle)` JNI pairs + `shutdown()` — a per-render-op
  instance with its own native handle and bounded pool is the DESIGNED usage. The Report 1
  singleton concern is resolved by adopting this handle model directly (no global state).
- Kernels are C++ files reusing AOSP RS intrinsic asm entry points
  (`rsdIntrinsicConvolve3x3_K` etc.) behind `TaskProcessor` row-parallelism.
- `convolve`: only `Convolve3x3.cpp` / `Convolve5x5.cpp` exist → fixed sizes, center anchor,
  clamp edge, no bias — confirms the subset restriction in Phase 1. Divisor = RS kernel
  normalization; SVG `bias≠0` graphs must stay on Kotlin.
- `lut(Bitmap, table: LookupTable, restriction)` — ARGB_8888 premultiplied path;
  `ByteArray` variant also exists (`sizeX*sizeY*4`). `LookupTable` = 4×256 entries,
  matches our per-channel table build.
- Vendoring scope for us: `Lut.cpp`, `Convolve3x3.cpp`, `Convolve5x5.cpp`,
  `Convolve_{neon,advsimd}.S`, plus required infra (`TaskProcessor.{h,cpp}`, `Utils.*`,
  `RenderScriptToolkit.{h,cpp}` trimmed, `JniEntryPoints.cpp` adapted). Blend/ColorMatrix/
  Blur/Histogram/Lut3d/Resize/YuvToRgb NOT needed initially (blur stays ours).

### go-images images (`tmp/images/internal/kernels/`)
- `kernels.go:960–1044+` verified: `Erode/Dilate` → separable van Herk/Gil–Werman
  (`morphScratch.vanHerk1D`), exactly 3 comparisons/pixel, per-worker reusable scratch
  (`pad/pref/suf`) — maps cleanly to our caller-owned scratch rule.
- **Two adaptations needed, not one**:
  1. clamp-to-edge pad → transparent-black pad (known), AND
  2. go-images "**preserve alpha**" semantics (alpha copied through) vs SVG spec where
     erode/dilate applies to ALL FOUR channels incl. alpha. Must change the vertical pass
     to include the alpha channel.
- `simd_arm64.s` present as NEON vmin/vmax reference (asm itself not portable — Go ABI).

### Mozilla SVGTurbulenceRenderer-inl.h + FULL gfx/2d tree (`tmp/turbulence/`, 158 files)
- The complete `gfx/2d` directory was vendored (not just 4 headers): includes
  `Point.h`, `BasePoint.h`, `BaseRect.h`, `BaseSize.h`, `Types.h`, `Rect.h`,
  `FilterNodeSoftware.cpp` (Firefox's own filter executor), plus all backends
  (Cairo/Skia/DWrite/Recording) we will NOT use.
- **Whole-Firefox-tree NOT needed**: the only thing still missing from this folder is
  `mfbt` (`mozilla/*` headers: RefPtr, Attributes, Assertions, Atomics…) which lives
  outside `gfx/2d`. We deliberately do NOT compile against it — the extraction approach
  (self-contained TU over raw byte buffers) stands. The vendored tree's value is as an
  exact REFERENCE for semantics, not as a compile unit.
- Key reference facts extracted:
  - `Types.h:24`: `typedef float Float` → turbulence math runs on float32, not double
    (our current Kotlin uses double — expect small golden deltas after the port;
    Firefox output is the reference).
  - `Point.h`/`BasePoint.h`/`BaseRect.h`: exact operator semantics to mirror in our
    mini geometry header (`Point*scalar`, mixed `Point±IntPoint`, `Rect::X/Y/Width/Height`,
    `Size` from `BaseSize.h`). Copy semantics, not the files (they still include
    `mozilla/Attributes.h`, `mozilla/gfx/NumericTools.h`).
  - `FilterNodeSoftware.cpp:481+,2732–2781`: how Firefox instantiates the renderer
    (attributes: baseFrequency pair, tile rect, stitchable flag, numOctaves, seed,
    TurbulenceType) — ideal integration-reference for our JNI parameter surface.
  - `TurbulenceType` enum: `Filters.h:229–230`.
- **SIMD.h re-checked in full tree**: STILL scalar + SSE2 only (`xmmintrin.h` guard,
  no `__ARM_NEON` section anywhere in this copy). NEON specializations remain OUR work:
  ship scalar-first, NEON follow-up (~13 functions listed below).
  - ⚠️ **Rounding mismatch inside SIMD.h**: scalar `F32ToI32` = `floor(x + 0.5f)`
    (round-half-up), SSE2 `_mm_cvtps_epi32` = round-to-nearest-even → pick ONE semantic
    for the port (recommend scalar floor(+0.5) so device/x86 outputs match); goldens must
    use that single implementation.
- License headers carry project Apache + MPL-2.0 notice — confirm policy before merge.

## 2. Target architecture

```
hu.oandras.ksvg.render.filters.pipeline (in :ksvg — DECISION: backend infra stays in
│                                        the main module as `internal`. The Kotlin
│                                        filter orchestration depends on ~30 :ksvg-
│                                        internal types; splitting kernel-math vs
│                                        orchestration across modules would need a
│                                        public-API widening or an allocation-heavy
│                                        adapter layer. Attempted move to :filtering
│                                        was reverted.)
├─ FilterPipeline.kt                 capability-based factory, create(canvas)
├─ FilterBackend.kt                  internal interface + FilterGraphInfo
├─ FilterPrimitiveSet.kt             @JvmInline value class over Int, flag constants
└─ FilterPipelineNativeImpl.kt       CPU backend, claims every set for now

:filtering keeps the pure kernels only: ComponentTransferNative, ConvolveNative,
future native morphology/turbulence JNI + their C++ sources.
```

### Backend interface (explicit API mode: everything `internal`)

```kotlin
internal interface FilterBackend {
    /** Per-primitive bitmap→bitmap execution (CPU path). */
    fun applyPrimitive(ctx: FilterPrimitiveContext): Bitmap?

    /**
     * Whole-graph GPU chain; null = "cannot represent this graph".
     * Non-null result lets renderWithFilter skip ALL intermediate bitmaps.
     */
    fun buildEffectChain(graph: FilterGraphInfo): RenderEffect?

    fun release()   // backend-owned scratch, called from render operation teardown
}
```

Selection (`FilterPipeline.create`), evaluated once per render operation at first
filtered node:

1. `!canvas.isHardwareAccelerated || SDK < 31` → `FilterPipelineNativeImpl`
2. SDK ≥ 33 && Impl33.supports(set) → Impl33
3. SDK ≥ 31 && Impl31.supports(set) → Impl31
4. else → NativeImpl

**Graph-level decision**: `supports()` receives a `FilterPrimitiveSet` collected by walking
`filterNode.primitives` once. Mixed graphs never split across backends (readback would cost
more than software execution).

### Integration point in Renderer

`applyFilterToBitmap` stays as the native-backend driver (its body moves behind
`FilterBackend.applyPrimitive`). In `renderWithFilter`, before the source-render step,
try:

```kotlin
val chain = pipeline?.buildEffectChain(graphInfo)
if (chain != null) {
    // draw cachedSourceContent once with paint.setRenderEffect(chain) onto canvas
    // update node.cached* fields with an EffectCache marker instead of Bitmap
} else {
    // today's applyFilterToBitmap loop through activeBackend.applyPrimitive
}
```

The existing cache check (Renderer.kt:970–985) keeps working unchanged on the CPU path;
on the GPU path the cached value becomes the stored `RenderEffect` (rebuild skipped while
contentVersion/scale keys match).

---

## Phase 0 — Module rename + skeleton (behavior-neutral)

1. Rename dir `nativeblur/` → `filtering/`, Gradle module `:nativeblur` → `:filtering`,
   namespace/package `hu.oandras.ksvg.nativeblur` → `hu.oandras.ksvg.filtering`.
   Update `settings.gradle(.kts)`, `ksvg/build.gradle.kts` dep, imports
   (`RenderNode.kt:66` `StackBlurScratch`). Keep `NativeGaussianBlur`, `StackBlur`,
   asm files untouched.
2. Add `FilterBackend`, `FilterPipeline`, `FilterPrimitiveSet`, context/info value classes.
3. Wrap today's `applyPrimitive` `when`-dispatch as `FilterPipelineNativeImpl`; wire factory
   so every device takes the native backend (no behavior change).
   **Gate:** full unit suite + `FiltersVisualComparisonTest` goldens.

## Phase 1 — Toolkit kernels into the native backend (wins on ALL APIs)

Vendor at source level into `:filtering/src/main/cpp/` (like blur asm, not a Gradle dep):
convolve (3×3/5×5) + LUT kernels; optionally blend/colorMatrix.

### feComponentTransfer → LUT (highest-value toolkit match)

**STATUS: DONE (Phase 1a). Implementation deviation from the original plan (documented):**
the current Kotlin path uses `Bitmap.getPixels`, which returns **unpremultiplied**
components — so the spec-semantics are already correct without any premultiply handling.
The toolkit `Lut` kernel (premultiplied ByteArray RGBA) would have needed extra
conversion passes; instead a compact custom kernel
(`filtering/src/main/cpp/component_transfer.cpp` + `ComponentTransferNative`) operates
directly on the existing pooled `IntArray`s:
- Kotlin precomputes 4×256 byte LUTs replicating `applyTransferFunction` exactly,
  including sRGB→linear→transfer→sRGB folding for linearRGB (`buildTransferLutTables`),
  cached on `FeComponentTransferRenderNode.lutTables` (computed once per node).
- Native side is a pure table-gather over the clip region; outside-clip pixels are set to
  transparent black (bit-exact with the old `outPixels.fill(0)` semantics).
- Kotlin scalar loop retained as fallback (`doComponentTransferKotlin`) when the native
  lib is unavailable (JVM/Robolectric determinism preserved).
- Device parity test: `ComponentTransferNativeDeviceTest` (androidTest).
- Gates run: full unit suite + `-PverifyFilter=component_transfer` visual suites green
  (JVM exercises the fallback; native path verified by device test / device goldens).

- Build-time: compute four 256-entry tables (`table`/`discrete`/`linear`/`gamma`) per
  channel exactly as today's Kotlin does, then one JNI call over the whole bitmap.
- **linearRGB/color-interpolation-filters**: fold sRGB→linear into table construction only
  if the primitive runs unpremultiplied end-to-end; otherwise keep the existing pre/post
  bitmap conversion passes and make the LUT operate in linear space consistently with them.
- **Premultiplied gotcha** (critical): Toolkit's Bitmap variant operates on premultiplied
  pixels. Component transfer is defined on unpremultiplied components. Two safe options:
  - use the ByteArray variant on `bitmap.copyPixelsToBuffer` (raw, premultiplied too!) —
    still needs unpremul round-trip, OR
  - simplest correct route: `getPixels` IntArray → unpremultiply → LUT JNI (u8 buffers) →
    premultiply → `setPixels`. The unpremul/premul pair can itself be folded into the LUT
    (two extra 256-entry tables for R,G,B scaling-by-alpha approximation is NOT spec-exact;
    do real unpremultiply). Benchmark before optimizing.

### feConvolveMatrix → convolve subset

**STATUS: DONE (Phase 1b). Deviation from the original subset restriction:**
instead of capping at 3×3/5×5 center-anchor clamp-only, a custom kernel
(`filtering/src/main/cpp/convolve_matrix.cpp` + `ConvolveNative`) supports ARBITRARY
order/anchor, all three edge modes and preserveAlpha — bit-exact with the Kotlin
reference loop (`doConvolveMatrixKotlin`, kept as JVM fallback):
- same float accumulation order, explicit mul→add (no FMA), `-ffp-contract=off`,
  half-up rounding via floor(+0.5) (trunc-vs-floor irrelevant after clamping negatives to 0),
- edge-mode ordinals match `ConvolveMatrixEdgeMode` (duplicate=0, wrap=1, none=2),
- **AArch64 NEON**: duplicate-edge interior vectorized 4 px/iteration (f32x4
  accumulation, vcvtq u8→f32, vmin/vmax clamp); borders + other modes scalar.
- **x86 SSE2**: same interior vectorization as NEON (`applySseInterior`); rounding via
  `_mm_cvttps_epi32(x+0.5)` = floor(+0.5) for positives, negatives clamp to 0 anyway.
  Module compiled with `-mssse3` on x86 ABIs.
- **feComponentTransfer SIMD coverage**:
  - AArch64: `vld4q_u8` channel de-interleave + `vqtbl4q_u8` full-table gathers,
    16 px/iter.
  - x86 SSSE3: pshufb 16-row selection scheme (entry = rows[hi][lo]), 4 px/iter +
    unpacklo re-pack; requires `-mssse3` (universal on Android x86 devices).
  - armv7 NEON: identical 16-row scheme with `vtbl2_u8`, 8 px/iter full-width rows.
  - All paths are pure byte permutation → bit-exact with scalar by construction.
- armv7 convolve stays scalar: ARM32 NEON has no integer divide and a
  reciprocal-multiply would break bit-exact rounding (documented decision).
- **x86 wide ISA paths (AVX2 + AVX-512)**: `simd_x86_avx2.cpp` (-mavx2) and
  `simd_x86_avx512.cpp` (-mavx512f -mavx512bw) as separate translation units —
  per-file flags make <immintrin.h> expose the wide intrinsics while baseline
  code stays SSE2. Runtime dispatch via `cpu_dispatch.h`
  (`__builtin_cpu_supports`, cached static): SSE2 → SSSE3 → AVX2 → AVX512.
  - morphology: 32/64-byte byte-min/max folds (bit-exact at any width),
  - convolve: f32×8 / f32×16 interior accumulation, same op sequence,
  - componentTransfer: AVX2 `vpshufb` LUT (8 px/iter); AVX-512 runs the AVX2
    path — a vpermb two-level 256-entry gather was judged not worth the complexity.
- armv7 / x86: scalar (documented; SSSE3/armv7-NEON can follow if profiling justifies).
- Device parity test: `ConvolveNativeDeviceTest` (3 edge modes × preserveAlpha,
  non-square kernel, off-center anchor, non-multiple-of-4 width).
- Gates run: full unit suite (incl. slow tests) + `-PverifyFilter=convolve` green.

- Fast path ONLY when: order ∈ {3×3, 5×5}, anchor == center, bias == 0,
  edgeMode == duplicate(clamp). Everything else keeps the Kotlin loop in
  `FilterPixels.kt`. Route selection happens in `FilterPipelineNativeImpl.applyPrimitive`
  so behavior is identical either way.
- divisor: pre-divide kernel weights on the Kotlin side before JNI (toolkit has no bias).

### Threading / ownership rules

- Use the toolkit's native-handle model directly: one `Toolkit` instance per render
  operation (createNative/destroyNative JNI pairs), thread count fixed in constructor.
  No global instance.
- Pixel I/O via Bitmap getPixels/setPixels into pooled `IntArray`s; intermediate bitmaps
  from the existing `BitmapPool`.
- JNI ABI: verify exact symbol names/signatures before wiring (AGENTS.md rule); C++
  intrinsics preferred over hand-written asm; scalar fallback mandatory for x86 + Robolectric.

**Gate:** goldens for componentTransfer + convolve fixtures
(`./gradlew :ksvg:testDebugUnitTest --tests "...FiltersVisualComparisonTest"` +
`AiVisualDiffTest -PverifyFilter=<fixture>`); add unit tests for LUT construction math
(table/discrete/linear/gamma × sRGB/linearRGB) — pure logic, no Android deps.

## Phase 2 — Own native kernels: morphology + turbulence (+ displacement)

### feMorphology (source: go-images/images, BSD-3)

**STATUS: DONE (Phase 2a). Deviation from plan (documented):** instead of porting van
Herk/Gil–Werman separable sliding windows, a direct-fold kernel
(`filtering/src/main/cpp/morphology.cpp` + `MorphologyNative`) replicates the existing
Kotlin semantics bit-exactly; van Herk remains a future optimization only if large-radius
profiling demands it. Rationale: bit-exactness is structural (integer min/max, no
rounding), no intermediate buffer is needed, and typical SVG morphology radii are small.
- SIMD on ALL ISAs as requested: interior-window tap folds run on 16-byte vectors of raw
  pixel bytes — `vmin/vmaxq_u8` (ARM32 NEON + AArch64), `_mm_min/max_epu8` (x86 SSE2).
  Lane positions map to fixed channels (chunks start on pixel boundaries: B,G,R,A),
  so vector output is exactly the scalar per-channel result.
- Semantics preserved bit-exactly: min/max over all four channels incl. alpha,
  transparent-black padding, erosion border short-circuit, clip-region-only output.
- Kotlin reference loop kept (`doMorphologyKotlin`, JVM fallback);
  device parity test: `MorphologyNativeDeviceTest` (both operators × radii 1/2/5,
  non-square footprint, non-aligned sizes).
- Gates run: full unit suite + `-PverifyFilter=morphology` green.

Original van Herk source notes (kept for the possible future optimization):
- Port structure including per-worker `morphScratch` (`pad/pref/suf`) as caller-owned scratch.
- go-images pads clamp-to-edge and preserves alpha — both would need spec adaptation
  (transparent-black pad; alpha participates in min/max).

### feTurbulence (source: Mozilla gfx SVGTurbulenceRenderer-inl.h, MPL-2.0)

**STATUS: DONE (Phase 2b). Per decision: SVG-reference algorithm, not the previous
Kotlin Perlin variant.** `turbulence.cpp` + `TurbulenceNative` implement the
SVG 1.1 §15.25 / mozilla scheme:
- Park–Miller seeded lattice init, 4-channel gradient packing per lattice point,
- turbulence |n|/ratio vs fractalNoise (n+1)/2 scaling,
- stitchTiles via lattice wrap periods (period doubling per octave);
  the base-frequency stitch adjustment stays Kotlin-side (it needs canvas/unit
  mapping context),
- output written UNPREMULTIPLIED ARGB ints into the clip region (our
  getPixels/setPixels domain — the vendored source's premultiplied-BGRA step
  is intentionally dropped),
- lattice tables rebuilt per call on the native stack (~10 KB): no shared state.
- Scalar float32 this round; the 4-pixel-wide f32 SIMD inner loop from the
  vendored source is a mechanical follow-up (structure mirrors Noise2/Turbulence).
- ⚠️ Golden note: turbulence/displacement fixtures were ALREADY excluded from
  pixel comparison (VisualComparisonTest threshold 0.0) because any correct
  spec implementation differs per PRNG; gates are parse/render success +
  non-black output + all other fixtures staying green.
- JVM fallback remains the legacy SvgPathNoise loop until a spec-exact Kotlin
  kernel is wanted (device vs JVM outputs differ by design).

- Port as C++ file in `:filtering`; specialize its `f32x4_t/i32x4_t/u8x16_t` templates to
  NEON intrinsics + scalar fallback. Stitch tiles supported upstream.
- ⚠️ Source depends on mozilla infra (`2D.h`, `Filters.h`, `SIMD.h`,
  `RefPtr<DataSourceSurface>`): extract the renderer body into a self-contained TU over
  raw byte buffers rather than stubbing the whole gfx layer (small surface: ctor +
  `Render(IntSize, Point)`).
- **Full extraction checklist** (verified line-by-line):
  - Trivial types to replace: `Point`, `Size`, `IntPoint`, `IntSize`, `Rect`,
    `Float` (=float, `Types.h:24`) → own tiny header mirroring `BasePoint/BaseRect/
    BaseSize` operator semantics from the vendored tree (reference-copy, not include).
  - `TurbulenceType` enum (`TURBULENCE_TYPE_TURBULENCE/_FRACTAL_NOISE`) → copy.
  - **SIMD.h surface is only 13 functions**: `FromF32, From32, SplatF32, MulF32, AddF32,
    DivF32, AbsF32, MixF32, WSumF32, F32ToI32, Pick, PackAndSaturate32To8, Store8` —
    the vendored SIMD.h has scalar + SSE2 only; NEON specializations are OURS to write
    (scalar-first shipping, NEON as follow-up).
  - Allocation/map layer to strip: `Factory::CreateDataSourceSurface`,
    `DataSourceSurface::ScopedMap`, `RefPtr/already_AddRefed`, `MOZ_ALWAYS_INLINE` →
    replace with caller-provided `uint8_t* out + stride` parameter.
  - `<utility>` `std::swap` only other std include — fine.
  - ⚠️ **Channel-order gotcha**: output is written as **B8G8R8A8 byte order**
    (see `ColorToBGRA`: premultiplied RGB + unpremultiplied alpha packed as BGRA), while
    Android `ARGB_8888` memory layout is **RGBA byte order** → swap R/B lanes either in
    `PackAndSaturate32To8` consumption or a dedicated store helper. Premultiplied output
    itself matches Android's bitmap convention — good.
  - ⚠️ **Width multiple-of-4 assumption**: `Render()` loops `x += 4` with no tail handling
    → pad the render width up to a multiple of 4 (or add scalar tail) for arbitrary
    filter-region sizes.
- Replaces the double-based Kotlin loop in `FilterGeneration.kt` — biggest CPU win after blur.
- License: MPL-2.0 file vendored verbatim with attribution header preserved (check project
  license compatibility before merging).
- JNI input: write directly into a byte buffer view of the destination bitmap
  (BGRA byte buffer) rather than ARGB IntArray conversion.

### feDisplacementMap

- Simple gather loop; port natively only if turbulence port infrastructure makes it cheap
  (< ~1 day), otherwise defer to AGSL in Phase 4. Decision point at end of turbulence task.

**Gate:** new verification fixtures (turbulence with stitchTiles variants, morphology
erode/dilate radius sweep) compared against rsvg goldens via `AiVisualDiffTest`.

## Phase 3 — `FilterPipelineImpl31` (RenderEffect, API 31+)

**STATUS: first slice DONE. GPU path = RenderEffect + RenderNode RECORDING (no bitmaps):
the filter source is recorded into a `RenderNode` via beginRecording/endRecording and
drawn once with `node.setRenderEffect(chain)` — zero intermediate bitmap allocation,
zero readback (per design direction).**

Implemented:
- `FilterPipelineImpl31.tryBuildChain(filterNode)` — strictly linear
  feColorMatrix chains map 1:1 onto `createColorFilterEffect(ColorMatrixColorFilter)`
  built by the SAME `buildColorMatrix()` the CPU path uses -> pixel parity by construction.
  Strict-chain check: every non-first `in` must equal the previous result name.
- Renderer integration: on HW canvas + API 31+ + opacity 1 + blend normal,
  source content is recorded into `filterNode.gpuNode` (re-recorded only when
  contentVersion / filterVersion / scale / size keys change — dedicated gpu* cache
  fields so the CPU bitmap cache stays independent), then drawn under identity
  matrix with the effect attached.
- All other graphs fall back to the CPU kernel path unchanged.

Deliberately NOT claimed yet:
- GaussianBlur: CPU pads transparent black vs createBlurEffect(CLAMP) edge clamp
  -> halo differences until pad handling is added;
- Offset: needs CSSLength resolution with renderer context;
- two-input/canvas-drawn primitives (Blend/Composite/Merge/Flood/Image);
- node-keyed RenderEffect caching (chain rebuilt per frame for now — cheap).

Remaining mapping work (next slices): blur with transparent-pad wrapper, offset,
then AGSL (Phase 4) for turbulence/lighting/composite-arithmetic.

## Phase 4 — `FilterPipelineImpl33` (AGSL RuntimeShader)

Order of implementation (value/risk ascending):
1. feTurbulence — pure generator shader, no input bitmap; biggest win.
2. feDisplacementMap — two-input sampling, trivially shader-shaped.
3. feMorphology, feConvolveMatrix — fixed-window loops; edge-mode encoded in-shader.
4. feComposite(arithmetic) + feBlend — `createRuntimeShaderEffect(shader, inputTextureName)`
   with second input as child effect.
5. feDiffuse/feSpecularLighting — alpha-as-heightmap normals + `pow()` lighting; most complex.

Semantics that MUST be handled inside shaders:
- premultiplied ↔ unpremultiplied conversions where spec-sensitive (composite arithmetic,
  component transfer),
- color-interpolation-filters=linearRGB: sRGB↔linear in-shader, or keep the framework-level
  pre/post passes used by the CPU path (decide once, apply uniformly).

Then relax `supports(set)` to claim the full set on API 33+ HW canvases.

**Gate:** goldens on API 33+ device/emulator; explicit regression fixtures for premultiplied
arithmetic-composite and linearRGB lighting cases.

## Cross-cutting tasks

- `SVG-SUPPORT.md` status updates per shipped primitive; `SvgFeatures.kt` strings if needed.
- Unit-test policy: only non-trivial logic (LUT math, edge-mode handling, pipeline selection,
  supports() classification). Visual correctness via golden suites.
- Constraints honored throughout: no global/shared mutable state, no mutable singletons,
  caller-owned reusable state, no capturing lambdas in hot paths, explicit API mode
  (pipeline types stay `internal`).
- Keep `MockCanvas` determinism: unit tests always exercise the native/Kotlin path; GPU
  paths are covered by device-side visual tests only.

## Risks & mitigations

| Risk | Mitigation |
|---|---|
| Premultiplied/unpremultiplied mismatches (LUT, AGSL) | Real unpremultiply in CPU path; in-shader conversions; dedicated golden fixtures before merge |
| linearRGB inconsistency between backends | Single decision documented; same fixtures run against all three backends |
| OEM RenderEffect quirks | Framework Skia path (low risk), one device sanity pass |
| Toolkit thread pool vs no-global-state rule | Solved: toolkit's native-handle model is per-instance by design; one handle per render op |
| Turbulence port drags in mozilla gfx infra | Solved: full gfx/2d vendored as reference; extraction into self-contained TU, no mfbt dependency |
| MPL-2.0 vendored file | Preserve header/attribution; confirm license policy |
| Morphology padding change alters goldens | Match current Kotlin semantics first, then fix to spec with fixture updates |

## Commit sequence

1. `:filtering` rename + FilterBackend/Pipeline skeleton, native wrapper (no behavior change)
2. Toolkit LUT (component transfer)
3. Toolkit convolve subset
4. Native morphology
5. Native turbulence (+ displacement decision)
6. Impl31 (blur/colorMatrix/dropShadow chains + effect caching)
7. Impl33 AGSL shaders (one commit per primitive)
