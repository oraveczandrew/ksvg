# KSVG SVG Implementation Audit

**Audit date:** 2026-08-23
**Subjects:** `SVG-SUPPORT.md` (claimed inventory), `SVG_REFERENCE_v2.md` (audit framework), and the actual KSVG source + tests under `ksvg/src/`.
**Method:** Source-level investigation only — no production code was modified. For every feature the implementation, style computation, rendering, coordinate-system handling, interaction with transforms/clip/mask/filter/opacity, inheritance/cascade, and existing tests were inspected. Where source inspection alone could not establish correctness, the item is marked `UNCERTAIN`.

---

## 1. Executive Summary

KSVG is a fork of AndroidSVG and inherits much of its generally-correct core. The bulk of **single-element, single-property** semantics (paths, shapes, viewBox/preserveAspectRatio, gradients/patterns linear chaining, paint, clipping, standalone masking, text layout, markers, animation timing, structural elements, group opacity, display/visibility) is **correct** and matches the documentation in most cases.

The audit found several **materially incorrect "Full" claims** and a small number of outright bugs:

1. **`filter` silently discards `opacity`, `mask`, and `mix-blend-mode` on the same element.** (`Renderer.kt:808` early-return in `withNewRenderLayer` + `renderWithFilter` drawing with a `null` paint at `Renderer.kt:966`.) This flattens the compositing pipeline and is the single most serious finding.
2. **Cyclic references crash** for `<use>`→`<use>` and `clip-path` A↔B (no visited-set guard), unlike gradient `href` chains which are correctly cycle-guarded.
3. **`pathLength` is parsed but never applied** (stroke dash arrays are not normalized).
4. **CSS-wide keywords are not implemented per spec.** `inherit`/`unset`/`initial`/`revert` are all reduced to a single "leave unspecified" shortcut. `revert` cannot be correct (no cascade-origin tracking); `unset`/`inherit` fail to override presentation attributes; non-inherited `inherit` (e.g. `display:inherit`) is wrong. `revert-layer` and `var()`/custom properties are entirely **missing**.
5. **Animation `fill="remove"` never reverts** (value persists like `freeze`), and **`additive="sum"` accumulates across frames** for style floats / dash arrays and is ignored for colors.
6. **Gradient/pattern defects:** `stop` offset clamped to `[0,100]` (should be `[0,1]`); radial `fx/fy` default hard-coded `0.5` (not `cx/cy`) in `objectBoundingBox`; wrong-type `url(#...)` paint references render inherited color instead of `none`.
7. **Documentation errors:** `markerUnits` is documented only as `userSpaceOnUse` but its actual (and correct) default `strokeWidth` is supported; `glyph-orientation-vertical` is documented `Full` but is a no-op; `textPath` is documented `Full` but `method`/`spacing`/`side` are unimplemented; `<text>` `rotate`/`textLength`/`lengthAdjust` are undocumented-absent.

Most "Full" claims lack targeted unit tests; verification rests on golden-image diffs that do not exercise the subtle divergences above.

Overall: KSVG is **substantially correct for common real-world SVG** but the support document **overstates completeness** in filters, animation, text, CSS cascade, and several cross-feature interactions.

---

## 2. Critical Findings

(Only items that cause materially incorrect rendering or significant compatibility problems.)

| #  | Finding                                                                  | Evidence                                                                                                                                                                                                   | Impact                                                                                                                                                        |
|----|--------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------|
| C1 | **`filter` drops `opacity`/`mask`/`mix-blend-mode`** on the same element | `Renderer.kt:802-833` (`withNewRenderLayer` early-returns on `filterNode`), `Renderer.kt:835-977` (`renderWithFilter` draws `oldCanvas.drawBitmap(..., null)` with no alpha/blend, never calls `popLayer`) | A filtered element with `opacity`, `mask`, or `mix-blend-mode` renders ignoring them. Documented "Full" for each individually is contradicted in combination. |
| C2 | **Cyclic `<use>` / `clip-path` references crash**                        | `RenderTreeBuilder.kt:881-911` (`buildUse` → `build(ref)` with no cycle check), `RenderTreeBuilder.kt:1261` (only self-ref guard for clip); contrast gradient guard at `ResolvedPaint.kt:195`              | `A`→`B`→`A` (non-self) `StackOverflowError`. Gradient `href` chains are correctly cycle-guarded, but use/clip are not.                                        |
| C3 | **`<text>` whitespace collapses wrong**                                  | `utils/String.kt:30-40,47-64` deletes `\n`/`\t` instead of converting to a space; `xml:space="preserve"` also drops newlines                                                                               | `xml:space="default"` turns `"foo\nbar"` into `"foobar"` (missing space), breaking word separation.                                                           |
| C4 | **`stop` offset upper bound 100 instead of 1**                           | `Stop.kt:100` `clamp(scalar, 0f, 100f)`                                                                                                                                                                    | `offset="120%"` → position `100.0` placed directly into shader `positions` array (must be ≤1.0) → undefined/wrong gradient.                                   |
| C5 | **`fill="remove"` animation never reverts**                              | `AnimationRenderer.kt` mutates persistent `renderState.style`; finished non-frozen animation `withValueAt` returns early (`AnimationRenderer.kt:647`) so base value is never restored                      | After an animation ends, the last animated value persists — equivalent to `freeze`. Documented `fill                                                          | Full | freeze, remove`. |
| C6 | **`additive="sum"` frame-accumulates for style/dash, ignored for color** | `AnimationRenderer.kt:372-546` (style floats accumulate against persistent `builder`), `:778-787` (dash), no additive param in `applyColorAnimation` (`:548-621`)                                          | `additive="sum"` over counts by the number of frames for opacity/stroke-width/dash, and is silently ignored for colors.                                       |
| C7 | **`pathLength` parsed but never applied**                                | `PathShape.kt:37,63-65` stores value; never read in `RendererState.kt:211-274` (`updateStrokeDash`)                                                                                                        | `<path pathLength="...">` dash arrays are not rescaled. Listed under `<path>` "Full".                                                                         |

---

## 3. Documentation Mismatches (vs `SVG-SUPPORT.md`)

For every mismatch: feature, claimed, actual, evidence, affected code, affected tests.

### 3.1 `filter` + opacity/mask/mix-blend-mode
- **Claimed:** `filter`, `opacity`, `mask`, `mix-blend-mode` all **Full** (lines 120, 138, 162, 223).
- **Actual:** Each is Full *standalone*, but **combinations with `filter`** are broken (C1).
- **Evidence:** `Renderer.kt:808` early return; `Renderer.kt:966` `null` paint.
- **Code:** `withNewRenderLayer`, `renderWithFilter`.
- **Tests:** `FiltersTest.kt`, `MaskTest.kt` never combine `filter` with `opacity`/`mask`/`blend`. **Gap.**

### 3.2 `paint-order`
- **Claimed:** **Full** (CSS Paint table, line 834-area; `SVG-SUPPORT.md` lists `paint-order` under Rendering as Full — line 221 also lists it globally).
- **Actual:** **NOT IMPLEMENTED** — no field in `Style.kt`/`SVGAttr.kt`; render order hard-coded fill→stroke→markers (`Renderer.kt:323-331`).
- **Evidence:** grep of `src/main` for `paintOrder`/`paint-order` → none in render path.
- **Tests:** none. **Gap.**

### 3.3 `markerUnits` documentation
- **Claimed:** `markerUnits | Full | userSpaceOnUse` (line 151) — the actual default `strokeWidth` is omitted.
- **Actual:** Implementation **CORRECT** — `strokeWidth` (default) and `userSpaceOnUse` both implemented (`Marker.kt:73`, `Renderer.kt:1650-1654`).
- **Evidence:** `Renderer.kt:1650-1654`.
- **Tests:** none for marker geometry. **Gap** (but impl correct → DOCUMENTATION_ERROR, not overstatement).

### 3.4 `glyph-orientation-vertical`
- **Claimed:** **Full** (line 211).
- **Actual:** Parsed and stored but **never read** in rendering (`StyleUpdate.kt:341` stores; only `textOrientation` read at `TextRenderer.kt:359`).
- **Evidence:** no read site for `glyphOrientationVertical` in render path.
- **Tests:** none. **Gap.**

### 3.5 `textPath`
- **Claimed:** **Full** — `href`, `startOffset` (line 50).
- **Actual:** `method`, `spacing`, `side` **not parsed** (`dom/text/TextPath.kt:60-68`); only `href` + `startOffset`. Tspan x/y/rotate inside textPath ignored (whole-string `drawTextOnPath`).
- **Evidence:** `TextPath.kt:60-68`; `Renderer.renderTextPathNode:382-400`.
- **Tests:** `ParseTest.kt:130` parse-only. **Gap.**

### 3.6 `<text>` `rotate`/`textLength`/`lengthAdjust`
- **Claimed:** implied **Full** (line 47 lists `x,y,dx,dy,transform` but not the omissions).
- **Actual:** `rotate`, `textLength`, `lengthAdjust` **never parsed** anywhere in `dom/text/`.
- **Evidence:** grep of `dom/text/` → zero references.
- **Tests:** none. **Gap.**

### 3.7 `revert` (CSS-wide keyword)
- **Claimed:** **Full** (line 253).
- **Actual:** Same undifferentiated early-return as `unset`/`inherit`/`initial` (`Style.kt:1716-1723`); no cascade-origin tracking (CSSParser.kt:302-303 TODO). Cannot be correct per spec.
- **Evidence:** `Style.kt:1720-1723`.
- **Tests:** none. **Gap.** → DOCUMENTATION_ERROR.

### 3.8 `inherit` / `unset` (CSS-wide keywords)
- **Claimed:** **Full** (lines 250-251).
- **Actual:** `inherit` wrong for non-inherited props (e.g. `display:inherit`); both fail to override presentation attributes (`<rect fill="red" style="fill:unset"/>` keeps red). `unset` doc even asserts "same mechanism as inherit" — true, but not spec-correct.
- **Evidence:** `Style.kt:1716-1723`, `Style.kt:941`.
- **Tests:** `StylePropertyParsingTest.kt:88-91` only asserts `inherit` leaves `fill` unspecified. **Gap.**

### 3.9 Radial gradient `fx`/`fy` default
- **Claimed:** `radialGradient` **Full** incl. `fx,fy,fr` (line 57).
- **Actual:** In `objectBoundingBox` mode `fx/fy` default hard-coded `0.5f` instead of resolved `cx/cy` (`Renderer.kt:2040-2042`).
- **Evidence:** `Renderer.kt:2040-2042` (gated by `SUPPORTS_RADIAL_GRADIENT_WITH_FOCUS`, API≥12).
- **Tests:** none. **Gap.**

### 3.10 Missing/invalid reference handling for clips & paint
- **Claimed:** `clip-path`, `mask`, `fill` all **Full**.
- **Actual:** Missing `clip-path`/`mask` reference → element rendered **fully visible/unclipped** (should hide) (`RenderTreeBuilder.kt:311-318`, `:322-329`). Wrong-type `url(#...)` paint → keeps inherited color instead of `none` (`ResolvedPaint.kt:176`).
- **Evidence:** cited lines.
- **Tests:** `ClipPathsTest`/`MaskTest` cover valid refs only. **Gap.**

---

## 4. Missing SVG Behavior

- **`var()` / custom properties** (`--foo`, `var(--c)`): entirely absent (no storage, parsed as unknown → dropped/black). `SVGAttr.kt:377` `UNSUPPORTED`.
- **`revert-layer`** and `@layer` cascade layers: absent.
- **`!important`**: parsed then discarded (`CSSParser.kt:295-300`).
- **Filter inputs `BackgroundImage`, `BackgroundAlpha`, `FillPaint`, `StrokePaint`**: not provided (`FilterSourceMap.kt:42-56` returns null).
- **`feImage` element reference** (`href="#id"`): only external/data images; subregion positioning ignored (`FilterGeneration.kt:187-204`).
- **`paint-order`**: not implemented at all.
- **`pointer-events` / hit-testing geometry**: not implemented (hit-test is `<a>` bounding-box only, ignores `pointer-events` and shape geometry).
- **`<text>` `rotate`/`textLength`/`lengthAdjust`**: not parsed.
- **`textPath` `method`/`spacing`/`side`**: not parsed.
- **`glyph-orientation-vertical`**: parsed but unused.
- **`animate` on `transform` attribute** (non-`animateTransform`) and **gradient stop `offset` animation**: not wired.
- **Deep clone for `<use>`**: shared DOM re-rendered, so multiple `<use>` of the same element share mutated `boundingBox` state.
- **`stitchTiles` on `feTurbulence`**: parsed but never applied.
- **`feMorphology` border pixels**: out-of-bounds clamped to edge (spec: transparent black).
- **`feSpecularLighting` alpha**: hard-coded to 255 (spec: max(R,G,B)).
- **`color-interpolation-filters` default `linearRGB`**: effectively `sRGB` for most primitives (only feComponentTransfer and feComposite-arithmetic honor it).
- **`transform-origin`** (SVG2): not supported.
- **`xml:space` newline handling**: deletes rather than collapses.
- **Cyclic `<use>`/clip-path** → crash.

---

## 5. Incorrectly Claimed "Full" Support

Features where `SVG-SUPPORT.md` says **Full** but the implementation does **not** satisfy the relevant semantics:

1. **`paint-order`** — not implemented (§3.2).
2. **`filter` (in combination)** — drops opacity/mask/blend (C1, §3.1).
3. **`revert`** — cannot be correct without origin tracking (§3.7).
4. **`inherit` / `unset`** — wrong for non-inherited props and cannot override presentation attributes (§3.8).
5. **`glyph-orientation-vertical`** — no-op (§3.4).
6. **`textPath`** — `method`/`spacing`/`side` missing (§3.5).
7. **`<text>` `rotate`/`textLength`/`lengthAdjust`** — not parsed (§3.6).
8. **`radialGradient` `fx/fy`** — wrong default in OBB (§3.9).
9. **`stop`** — offset clamp `[0,100]` vs `[0,1]` (C4).
10. **Animation `fill`** — `remove` never reverts (C5).
11. **Animation `additive`** — `sum` accumulates/ignored (C6).
12. **Animation `begin`/`end`** — offset-only; no syncbase/event/list (agent: PARTIAL).
13. **`feImage`** — subregion + element ref missing (agent: PARTIAL/OVERSTATED).
14. **`feTurbulence`** — `stitchTiles` ignored (agent: PARTIAL).
15. **`feMorphology`** — border handling wrong (agent: PARTIAL).
16. **`feSpecularLighting`** — alpha wrong (agent: PARTIAL).
17. **`writing-mode` (vertical)** — crude, no rl/lr distinction (agent: PARTIAL).
18. **`dominant-baseline`** — many keywords missing, approximations (agent: PARTIAL).
19. **`word-spacing`** — API-26 gated, platform-dependent (agent: PARTIAL).
20. **`<use>`** — no deep clone, cyclic crash (§4, agent: PARTIAL).
21. **`<switch>` `systemLanguage`** — single-language only (agent: PARTIAL).
22. **`<a>` (nested-transform hit-test)** — coordinate-space mismatch (agent: PARTIAL).
23. **`clip-path`/`mask` (missing ref)** — element shown instead of hidden (§3.10).
24. **`fill`/`stroke` wrong-type `url()`** — keeps inherited color vs `none` (§3.10).
25. **`text-orientation`** — correctly documented as Partial (excluded); listed here only to note `glyph-orientation-vertical` is the overstated sibling.

---

## 6. Weak / Questionable Implementations

- **`stroke-miterlimit`**: no clamp to `>=1` (`Style.kt:1776-1780`); sub-1 values just force bevel (negligible visual impact).
- **Cyclic reference detection**: inconsistent — gradient/pattern chains guard *self*-reference only and recurse with the original node, so non-self cycles (`A→B→A`) `StackOverflow` (`ResolvedPaint.kt:195-198,225`, `RenderTreeBuilder.kt:1421-1423,1471`).
- **`feColorMatrix` `matrix` type offset column**: multiplied by 255 (`FilterColor.kt:99-104`) — correctness depends on Android `ColorMatrix` offset scale; untested (`FiltersTest.feColorMatrix` only uses `saturate`). Marked **UNCERTAIN**.
- **`transform` + `viewBox` composition order** on `<svg>`/`<symbol>`/`<image>`/`<marker>`: code applies element `transform` innermost (`Renderer.kt:266-290`), spec/browser applies it outermost. Diverges only for non-commuting transforms with non-uniform viewBox scaling. Strong code-level evidence, needs an on-device rendering test. Marked **UNCERTAIN**.
- **`<switch>` `requiredFeatures`**: permissive accept list (`SvgFeatures.kt`) — acceptable but not spec-strict.
- **`<a>` hit region** uses `node.boundingBox` in local space with a root-only inverse transform (`SVGImpl.kt:155-163`) → wrong for transformed ancestors.
- **Marker `preserveAspectRatio` non-default**: alignment/slice ignored for ref-point placement (`Renderer.kt:1667-1669`).
- **Number parser edge cases**: `"1."` → NaN; `"1.5.5"` silently accepted; `1e40` rejected (`NumberParser.kt:124-128,210-213`).
- **Malformed path recovery**: any NaN coordinate or `rx/ry<0` arc truncates the **entire remainder** of the path (`PathParser.kt:327`).
- **viewBox zero/negative dims**: divide-by-zero / parse-abort (`ViewBoxContainer.kt:79-84`).
- **negative/missing shape dims** (rect/circle/ellipse): throw or NPE instead of "not rendered" (`RectShape.kt:76-79`, `PathUtils.kt:38-39,82,106-107`).

---

## 7. Test Coverage Gaps

No existing test exercises (verification relies only on golden-image diffs that miss subtle divergences):

- `filter` + `opacity` / + `mask` / + `mix-blend-mode` (the C1 bug is entirely untested).
- `paint-order` (unimplemented, untested).
- `pathLength` normalization.
- Odd-length `stroke-dasharray` doubling (agent found animation tests only).
- `vector-effect` / `non-scaling-stroke` (none).
- `currentColor` static fill/stroke (animation context only).
- `stroke-miterlimit` clamp.
- Missing/invalid `clip-path`/`mask`/paint references.
- Gradient/pattern cyclic `href` (non-self) → would *crash*.
- `stop` offset clamping; radial `fx/fy` default; wrong-type paint ref.
- `<use>` cyclic references (crash).
- CSS-wide keywords distinct behavior (`unset`/`initial`/`revert`/`revert-layer`), `var()`, `!important`.
- Text: `textPath` rendering, whitespace/xml:space, RTL/bidi, vertical writing-mode, baseline offsets, `textLength`/`rotate`, `word-spacing` rendering, `paint-order`.
- Animation: `fill="remove"` reversion, `additive="sum"` across frames, `begin`/`end` syncbase, `<animate>` on `transform`, stop `offset` animation.
- `<switch>` `systemLanguage` negotiation; `<a>` nested-transform hit-test.
- `feColorMatrix` `matrix` offset; `feTurbulence` `stitchTiles`; `feMorphology` border; `feSpecularLighting` alpha; `feImage` subregion.
- `transform` + `viewBox` composition (non-commuting).
- `Marker` geometry/orient/placement (visual golden only).

---

## 8. Reference Gaps (`SVG_REFERENCE_v2.md`)

Important SVG/CSS concepts the framework **itself fails to capture** (do not silently correct the reference — list separately):

1. **ICC profiles / `color-profile`** — color management is delegated to Android; KSVG ignores `<color-profile>`. The reference omits color-management policy entirely.
2. **`color-interpolation-filters` = `linearRGB` default** and the perceptual cost of ignoring it — not called out as a common implementation pitfall in §3.6.
3. **`enable-background` / `BackgroundImage`/`BackgroundAlpha` filter inputs** — referenced only obliquely; not flagged as commonly-unsupported.
4. **`image-rendering`** interaction with `filter`/scaling — listed as a property but no audit guidance on smoothing behavior.
5. **`shape-rendering` / `text-rendering`** — listed but no guidance on geometric-precision vs speed trade-offs.
6. **`will-change` / GPU-layer hints** — N/A to a drawable, but not explicitly carved out.
7. **`transform-origin` (SVG2)** — absent from the transform audit list (§4.4/§23).
8. **`overflow` on non-viewport elements** (e.g. `<svg>` content clipping, marker/pattern clipping defaults) — only loosely covered.
9. **`vector-effect` non-scaling-stroke interaction with `markerUnits` and clip** — flagged in audit prompt but not in reference §23.
10. **Deep-clone semantics of `<use>` and shadow trees / duplicate-ID scoping** — reference §4.2 mentions `<use>` but not the clone/ID-resolution model that is a classic divergence source.
11. **`xml:base` / base URL resolution for external references** — reference §4.1 asks the question but gives no normative behavior to audit against.
12. **`requiredExtensions`/`requiredFormats`/`requiredFonts`/`systemLanguage` language-negotiation model** (ordered preference list, region subtags, `*`) — not specified as an audit item in §17.
13. **`clip` (CSS property, `rect()`) vs `clip-path`** — reference conflates; KSVG implements `clip` only for viewport-establishing elements (correct scope) but the reference does not distinguish.
14. **Soft / `mix-blend-mode` and `isolation` group-isolation semantics** — reference §3.7/§12 mentions but does not demand verifying that filtered elements drop blend/isolation.
15. **`feDropShadow`** — not in the primitive inventory (§3.6) though it is a standard element KSVG implements.

---

## 9. Recommended Audit Matrix

Confidence: **H** high (source + tests), **M** medium (source only), **L** low/uncertain.

| Feature                                                                                                                                                                      | Claimed     | Actual       | Conf | Evidence                     | Main gap                         | Tests                   |
|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------|--------------|------|------------------------------|----------------------------------|-------------------------|
| `<path>` commands/parsing                                                                                                                                                    | Full        | CORRECT      | H    | PathParser.kt, ArcToTest     | `pathLength` unapplied           | A5 pathLength untested  |
| `<path>` `pathLength`                                                                                                                                                        | Full        | MISSING      | H    | PathShape.kt:37,63           | not applied to dash              | none                    |
| `<rect>`/`<circle>`/`<ellipse>` dims                                                                                                                                         | Full        | PARTIAL      | M    | PathUtils.kt, RectShape.kt   | throw/NPE on bad/missing dims    | none                    |
| `<line>`/`<polyline>`/`<polygon>`                                                                                                                                            | Full        | CORRECT      | H    | PathUtils.kt:129-173         | —                                | none                    |
| `transform`                                                                                                                                                                  | Full        | CORRECT      | M    | TransformParser.kt           | +viewBox order UNCERTAIN         | anim tests only         |
| `viewBox`                                                                                                                                                                    | Full        | PARTIAL      | M    | ViewBoxContainer.kt          | zero/negative dims               | PreserveAspectRatioTest |
| `preserveAspectRatio`                                                                                                                                                        | Full        | CORRECT      | H    | ViewBoxTransform.kt          | —                                | PreserveAspectRatioTest |
| `fill`/`stroke`/`fill-rule`/`clip-rule`                                                                                                                                      | Full        | CORRECT      | H    | Style.kt, RendererState.kt   | wrong-type url() keeps color     | golden only             |
| `stroke-linecap/join/miterlimit`                                                                                                                                             | Full        | CORRECT      | M    | StyleUpdate.kt:97-121        | miterlimit <1 not clamped        | none                    |
| `stroke-dasharray/offset`                                                                                                                                                    | Full        | CORRECT      | M    | RendererState.kt:224-255     | odd-doubling OK                  | anim tests only         |
| `paint-order`                                                                                                                                                                | Full        | MISSING      | H    | not in Style.kt/render       | unimplemented                    | none                    |
| `vector-effect`                                                                                                                                                              | Full        | CORRECT      | M    | Renderer.kt:657-697          | —                                | none                    |
| `currentColor`                                                                                                                                                               | Full        | CORRECT      | M    | StyleUpdate.kt:440-458       | —                                | anim only               |
| `clip-path`                                                                                                                                                                  | Full        | PARTIAL      | M    | Renderer.kt:2185-2251        | missing ref → shown              | ClipPathsTest           |
| `clipPathUnits`                                                                                                                                                              | Full        | CORRECT      | H    | ClipPath.kt:57               | per-child clip-rule edge         | ClipPathsTest           |
| `mask` (standalone)                                                                                                                                                          | Full        | CORRECT      | H    | Renderer.kt:1020-1056        | —                                | MaskTest                |
| `mask` + `filter`                                                                                                                                                            | Full        | BROKEN       | H    | Renderer.kt:808              | mask dropped                     | none                    |
| `mask-type`/`maskUnits`/`maskContentUnits`                                                                                                                                   | Full        | CORRECT      | H    | Mask.kt, RegionUtils.kt      | —                                | MaskTest                |
| `opacity`                                                                                                                                                                    | Full        | CORRECT      | H    | Renderer.kt:991,1453         | +filter dropped                  | none                    |
| `opacity` + `filter`                                                                                                                                                         | Full        | BROKEN       | H    | Renderer.kt:966              | alpha 1                          | none                    |
| `mix-blend-mode`                                                                                                                                                             | Full        | PARTIAL      | M    | Renderer.kt:993              | +filter dropped                  | parse only              |
| `isolation`                                                                                                                                                                  | Full        | CORRECT      | M    | Renderer.kt:1453             | —                                | parse only              |
| `display`/`visibility`                                                                                                                                                       | Full        | CORRECT      | H    | builders, Renderer.kt:557    | —                                | none                    |
| `linearGradient`/`gradientUnits`/`gradientTransform`/`spreadMethod`                                                                                                          | Full        | CORRECT      | H    | Renderer.kt:1869-1975        | wrong-type ref                   | golden                  |
| `radialGradient` `fx/fy`                                                                                                                                                     | Full        | PARTIAL      | M    | Renderer.kt:2040-2042        | default 0.5 not cx/cy            | none                    |
| `stop`                                                                                                                                                                       | Full        | PARTIAL      | M    | Stop.kt:100                  | offset clamp 0..100              | none                    |
| gradient/pattern `href` cyclic                                                                                                                                               | Full        | MISSING(bug) | H    | ResolvedPaint.kt:195-225     | non-self cycle SO                | none                    |
| `pattern` (tiling/units/transform)                                                                                                                                           | Full        | CORRECT      | M    | Renderer.kt:2299-2435        | cyclic crash                     | golden                  |
| `<filter>` regions/units                                                                                                                                                     | Full        | CORRECT      | H    | RegionUtils.kt               | —                                | FiltersTest             |
| `color-interpolation-filters`                                                                                                                                                | Full        | OVERSTATED   | H    | FilterColor.kt:182 only      | sRGB for most                    | none                    |
| `feBlend`/`feComposite`/`feColorMatrix`/`feConvolveMatrix`/`feMorphology`/`feGaussianBlur`/`feFlood`/`feOffset`/`feMerge`/`feComponentTransfer`/`feTile`/`feDisplacementMap` | Full        | PARTIAL      | M    | render/filters/*             | color-space / edge cases         | FiltersTest subset      |
| `feTurbulence`                                                                                                                                                               | Full        | PARTIAL      | M    | FilterGeneration.kt          | stitchTiles ignored              | feTurbulence test       |
| `feSpecularLighting`                                                                                                                                                         | Full        | PARTIAL      | M    | FilterLighting.kt:130        | alpha=255                        | feSpecular test         |
| `feImage`                                                                                                                                                                    | Full        | PARTIAL      | M    | FilterGeneration.kt:187-204  | subregion/element-ref            | feImage test            |
| `feDropShadow`                                                                                                                                                               | Full        | PARTIAL      | M    | Renderer.kt:1371-1449        | color-space                      | complexDropShadow       |
| `<text>` x/y/dx/dy/transform                                                                                                                                                 | Full        | PARTIAL      | M    | dom/text/Text.kt             | rotate/textLength/lengthAdjust   | none                    |
| `<tspan>` multi-coord                                                                                                                                                        | Full        | CORRECT      | M    | TextRenderer.kt:70-100       | —                                | none                    |
| `<textPath>`                                                                                                                                                                 | Full        | OVERSTATED   | M    | TextPath.kt:60-68            | method/spacing/side              | parse only              |
| `<tref>`                                                                                                                                                                     | Partial     | CORRECT      | M    | RenderTreeBuilder.kt:1147    | —                                | TRefRenderTest          |
| `xml:space`/whitespace                                                                                                                                                       | (n/a)       | PARTIAL/bug  | M    | String.kt:30-64              | newline deletion                 | none                    |
| `dominant/alignment-baseline`                                                                                                                                                | Full        | PARTIAL      | M    | TextRenderer.kt:510-539      | keyword gaps/approx              | none                    |
| `direction`/bidi                                                                                                                                                             | Full        | PARTIAL/UNC  | M    | TextRenderer.kt:126-140      | no bidi flags                    | none                    |
| `writing-mode` vertical                                                                                                                                                      | Full        | PARTIAL      | M    | TextRenderer.kt:357-393      | no rl/lr                         | none                    |
| `glyph-orientation-vertical`                                                                                                                                                 | Full        | DOC-ERROR    | H    | parsed, unused               | no-op                            | none                    |
| `text-anchor`                                                                                                                                                                | Full        | CORRECT      | M    | RenderTreeBuilder.kt:1023    | —                                | parse only              |
| `letter-spacing`                                                                                                                                                             | Full        | CORRECT      | M    | StyleUpdate.kt:349           | —                                | parse only              |
| `word-spacing`                                                                                                                                                               | Full        | PARTIAL      | M    | StyleUpdate.kt:362           | API26/platform                   | none                    |
| `text-decoration`                                                                                                                                                            | Full        | PARTIAL      | M    | TextRenderer.kt:328-354      | approx positions                 | parse only              |
| `text-transform`                                                                                                                                                             | Full        | CORRECT      | M    | TextRenderer.kt:541          | —                                | none                    |
| font properties                                                                                                                                                              | Full        | CORRECT      | M    | TypefaceResolver.kt          | platform fonts                   | Font*Tests              |
| `<use>`                                                                                                                                                                      | Full        | PARTIAL      | M    | RenderTreeBuilder.kt:881     | no clone, cyclic crash           | CSSTest.use             |
| `<symbol>`                                                                                                                                                                   | Full        | CORRECT      | M    | buildSymbol:721              | —                                | none                    |
| `<switch>`                                                                                                                                                                   | Full        | PARTIAL      | M    | buildSwitch:776              | systemLanguage simplif.          | none                    |
| `<a>`                                                                                                                                                                        | Full        | PARTIAL      | M    | SVGImpl.kt:120-191           | nested hit coord                 | HyperlinkHitTestTest    |
| `<defs>`/`<view>`/`<solidColor>`                                                                                                                                             | Full        | CORRECT      | M    | SVGImpl.kt:609,2485          | —                                | ViewsTest               |
| `inherit`/`unset`                                                                                                                                                            | Full        | OVERSTATED   | H    | Style.kt:1716-1723           | no override of pres.attr         | StylePropParsing:88     |
| `initial`                                                                                                                                                                    | Partial     | ACCURATE     | H    | Style.kt:1718                | inherited→inherit                | none                    |
| `revert`                                                                                                                                                                     | Full        | DOC-ERROR    | H    | Style.kt:1720                | no origin tracking               | none                    |
| `revert-layer`/`var()`/`!important`                                                                                                                                          | (n/a)       | MISSING      | H    | Style.kt:1723, CSSParser.kt  | absent                           | none                    |
| `markerUnits` `strokeWidth`                                                                                                                                                  | (doc omits) | CORRECT      | M    | Renderer.kt:1650             | doc error only                   | none                    |
| `marker` orient/refX/refY/placement                                                                                                                                          | Full        | CORRECT      | M    | MarkerPositionCalculator.kt  | non-default PA ref               | golden                  |
| `animate` (values/keyTimes/calcMode)                                                                                                                                         | Full        | CORRECT      | H    | AnimationUtils.kt            | —                                | AnimationTest           |
| `animate` `begin`/`end`                                                                                                                                                      | Full        | PARTIAL      | M    | Animation.kt:101,112         | offset only                      | none                    |
| `fill` freeze/remove                                                                                                                                                         | Full        | PARTIAL      | M    | AnimationRenderer.kt:647     | remove never reverts             | none                    |
| `additive` sum                                                                                                                                                               | Full        | PARTIAL      | M    | AnimationRenderer.kt:372-621 | frame-accumulate/ignore          | none                    |
| `accumulate`                                                                                                                                                                 | Full        | CORRECT      | M    | AnimationRenderer.kt:698-814 | color ignored (spec OK)          | none                    |
| `animateTransform`                                                                                                                                                           | Full        | CORRECT      | H    | AnimationRenderer.kt:714-762 | additive replace broken          | AnimationTest           |
| `animateMotion`/`mpath`                                                                                                                                                      | Full        | CORRECT      | M    | AnimateMotionTest            | mpath→path only                  | AnimateMotionTest       |
| `<set>`/`<animateColor>`                                                                                                                                                     | Full        | CORRECT      | M    | AnimateColor.kt              | additive sum ignored             | AnimationTest           |
| `attributeName` (stop offset / animate-transform)                                                                                                                            | Full        | PARTIAL      | M    | AnimationRenderer.kt:534     | offset/animate-transform missing | none                    |
| `pointer-events`                                                                                                                                                             | (n/a)       | MISSING      | H    | grep → 0                     | absent                           | none                    |

---

## Appendix — Discipline Note

Every significant finding above was traced to a feature → spec → implementation → discrepancy chain, per the audit's source-discipline rule. Items where source inspection alone was insufficient (transform+viewBox order, feColorMatrix offset scale) are explicitly marked **UNCERTAIN** rather than guessed. No production code was modified.
