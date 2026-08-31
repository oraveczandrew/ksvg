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
  similarity improved **0.425 → 0.722**; `filter_specular.svg` (specular consumed
  by `feComposite arithmetic` → non-terminal) unchanged at **0.981**. The residual
  to 0.95 is dominated by the **diffuse** circle (see §3.3), not the specular
  premultiplied case.

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

The `lighting_point_spot` left circle (`feDiffuseLighting` + `fePointLight`) also
shows a small systematic brightening in rsvg vs KSVG (golden ~5–15% brighter
inside the plateau) — NOT the premultiplied artifact (diffuse output is opaque,
alpha=255). Light formula appears equal; suspected cause still to investigate
(surface-normal/`kernelUnitLength` interpretation at the plateau edges, or the
`+0.5` rounding in librsvg's `clamp(..)+0.5 as u8`). Do not alter the diffuse
kernel without a repeatable failing case.

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