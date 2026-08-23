# KSVG Audit Remediation — Execution Plan

**Source:** `KSVG_AUDIT_REPORT.md` (2026-08-23)
**Scope:** Fix material bugs, correct overstated `Full` claims, and close test gaps.
**Strategy:** Fix real bugs first (correctness + crashes), then documentation accuracy, then missing features by ROI. Every fix ships with a regression test.

---

## Phase 0 — Reproduce & Baseline (1 day)
**Goal:** Turn "UNCERTAIN" and "Gap" items into reproducible tests before changing code.

1. Add golden/unit tests for each Critical finding (C1–C7) that currently has **no** test, so a fix has a green target.
2. For UNCERTAIN items (transform+viewBox order, feColorMatrix offset) write a device/on-device or Robolectric render probe to confirm.
3. Snapshot current `SVG-SUPPORT.md` status per affected line so doc edits in later phases are tracked.

**Deliverables:** New test files `C1FilterComposeTest`, `C2CyclicRefTest`, `C3WhitespaceTest`, `C4StopOffsetTest`, `C5FillRemoveTest`, `C6AdditiveTest`, `C7PathLengthTest` (all initially failing/red).

---

## Phase 1 — Critical Correctness Bugs (highest priority)

### P1.1 — C1: `filter` drops `opacity`/`mask`/`mix-blend-mode`  *(impact: silent wrong render)*
- **File:** `Renderer.kt` `withNewRenderLayer` (~802-833) + `renderWithFilter` (~835-977).
- **Fix:** After filtering into the offscreen layer, do NOT early-return. Composite the filtered bitmap through the existing layer stack honoring `opacity` (draw with alpha paint), `mask` (apply mask before/after), and `mix-blend-mode` (set XferMode via `PaintCompat`/`XFerModes`).
- **Approach:** Replace the `null`-paint `drawBitmap` with a layered composite that respects the same `applyLayer`/`popLayer` path used by standalone `opacity`/`mask`/`blend`.
- **Tests:** `C1FilterComposeTest` — filter+opacity, filter+mask, filter+blend combos.

### P1.2 — C2: Cyclic `<use>` / `clip-path` references crash  *(impact: crash)*
- **File:** `RenderTreeBuilder.kt` `buildUse` (~881-911), clip resolver (~1261, ~1421-1423); mirror gradient guard at `ResolvedPaint.kt:195-225`.
- **Fix:** Thread a `visited: Set<nodeId>` through `build()` / clip-path / pattern / gradient resolution; on revisit, skip (treat cyclic ref as empty/missing per spec, not StackOverflow).
- **Tests:** `C2CyclicRefTest` — `A→B→A` for `<use>` and `clip-path`; gradient non-self cycle.

### P1.3 — C3: `<text>` whitespace collapses wrong  *(impact: missing spaces)*
- **File:** `utils/String.kt:30-64`.
- **Fix:** Convert `\n`/`\t`/`\r` → space per `xml:space="default"`; for `xml:space="preserve"` keep newlines as line breaks (or at least keep them, not delete). Insert a space at run boundaries where a newline was removed.
- **Tests:** `C3WhitespaceTest` — `"foo\nbar"` → `"foo bar"`; preserve mode keeps newline.

### P1.4 — C4: `stop` offset clamp `[0,100]` → `[0,1]`  *(impact: broken gradient)*
- **File:** `Stop.kt:100` `clamp(scalar, 0f, 100f)`.
- **Fix:** Parse `offset` as fraction (divide `%` by 100) and clamp to `[0f,1f]`; keep percentage parsing but normalize to 0..1 before storing in shader `positions`.
- **Tests:** `C4StopOffsetTest` — `offset="120%"` clamps to 1.0; `offset="50%"` → 0.5.

### P1.5 — C5: `fill="remove"` never reverts  *(impact: acts like freeze)*
- **File:** `AnimationRenderer.kt:647` + persistent `renderState.style` mutation.
- **Fix:** On animation end with `fill="remove"`, restore the base (pre-animation) value — keep a captured base snapshot per animated property and re-apply on finish.
- **Tests:** `C5FillRemoveTest` — animate opacity 0→1, end at t>dur, assert reverts to base.

### P1.6 — C6: `additive="sum"` frame-accumulates  *(impact: wrong values, color ignored)*
- **File:** `AnimationRenderer.kt:372-546` (style floats), `:778-787` (dash), `:548-621` (color).
- **Fix:** Accumulate relative to the **base value**, not the previously-computed frame; compute `base + sum(delta)` per frame. For color, apply additive sum of ARGB deltas (per spec `sum` is not ignored for colors in `additive`).
- **Tests:** `C6AdditiveTest` — additive opacity 0.1 each of N frames equals base+0.1 not base+N*0.1.

### P1.7 — C7: `pathLength` parsed but never applied  *(impact: wrong dash scaling)*
- **File:** `PathShape.kt:37,63-65`; read in `RendererState.kt:211-274` `updateStrokeDash`.
- **Fix:** When `pathLength` is set and >0, scale dash array + dashoffset by `computedPathLength / pathLength` (use `PathMeasure` length from render context pool).
- **Tests:** `C7PathLengthTest` — path with `pathLength` produces expected dash gaps.

---

## Phase 2 — High-Value Doc/Behavior Fixes (medium effort)

| ID | Item | Fix location | Action |
|----|------|--------------|--------|
| D1 | `paint-order` unimplemented (§3.2) | `Style.kt`, `SVGAttr.kt`, `Renderer.kt:323-331` | Implement field + parse + reorder fill/stroke/markers draw. |
| D2 | Radial `fx/fy` default (§3.9) | `Renderer.kt:2040-2042` | Default `fx/fy` to `cx/cy` (not `0.5`) in OBB mode. |
| D3 | Wrong-type `url()` paint keeps color (§3.10) | `ResolvedPaint.kt:176` | Wrong-type paint reference → `none`, not inherited color. |
| D4 | Missing `clip-path`/`mask` ref → shown (§3.10) | `RenderTreeBuilder.kt:311-318,322-329` | Missing/invalid ref → element **hidden** (per spec). |
| D5 | `<use>` deep-clone shared state (§4) | `RenderTreeBuilder.buildUse` | Clone referenced DOM subtree so transformed `<use>` don't share `boundingBox`. |
| D6 | `stroke-miterlimit` no clamp (§6) | `Style.kt:1776-1780` | Clamp to `>=1`. |
| D7 | `feColorMatrix` offset ×255 (§6, UNCERTAIN→confirm) | `FilterColor.kt:99-104` | Verify Android `ColorMatrix` scale; fix if needed. |
| D8 | `feSpecularLighting` alpha (§4) | `FilterLighting.kt:130` | Set alpha to `max(R,G,B)` per spec. |
| D9 | `feMorphology` border (§4) | filter kernel | Out-of-bounds → transparent black, not edge clamp. |
| D10| `feTurbulence stitchTiles` (§4) | `FilterGeneration.kt` | Apply stitch tile logic. |
| D11| `transform`+`viewBox` order (§6, UNCERTAIN) | `Renderer.kt:266-290` | Confirm; apply element `transform` outermost if diverging. |
| D12| `glyph-orientation-vertical` no-op (§3.4) | `StyleUpdate.kt`/`TextRenderer.kt` | Either implement or downgrade doc claim (see Phase 4). |

---

## Phase 3 — CSS Cascade Correctness (§3.7, §3.8, §4)

| ID | Item | Fix |
|----|------|-----|
| CSS1 | `inherit`/`unset` cannot override presentation attrs (§3.8) | Resolve cascade so `style` wins over presentation attribute; `inherit` forces parent value even for non-inherited props. |
| CSS2 | `revert` cannot be correct (§3.7) | Track cascade origin (author/UA) minimally, or downgrade doc to Partial. |
| CSS3 | `var()` / custom properties (§4) | Add `--name` storage + `var()` resolution in `Style`/`CSSParser`. *(large; optional/ROI-low)* |
| CSS4 | `!important` discarded (§4) | Store importance flag; honor in cascade. |
| CSS5 | `revert-layer` / `@layer` (§4) | Add if CSS3 done; else document as unsupported. |

**Note:** CSS1 is the only correctness bug with real-world impact; CSS2–CSS5 can be doc-downgraded if effort is constrained.

---

## Phase 4 — Documentation Accuracy (`SVG-SUPPORT.md`)

Downgrade or correct overstated `Full` claims to match reality (per §5 list of 25 items):

1. `paint-order` → **None** (or Full after D1).
2. `filter` combination → note "Full standalone; breaks with opacity/mask/blend" until P1.1 done.
3. `revert` → **Partial/None** (until CSS2).
4. `inherit`/`unset` → **Partial** (until CSS1).
5. `glyph-orientation-vertical` → **None** (no-op).
6. `textPath` → **Partial** (method/spacing/side missing).
7. `<text> rotate/textLength/lengthAdjust` → **None**.
8. `radialGradient fx/fy` → **Partial** (until D2).
9. `stop` → **Partial** (until P1.4).
10. Animation `fill` remove → **Partial** (until P1.5).
11. Animation `additive` → **Partial** (until P1.6).
12–25. Mark `feImage`, `feTurbulence`, `feMorphology`, `feSpecularLighting`, `writing-mode`, `dominant-baseline`, `word-spacing`, `<use>`, `<switch> systemLanguage`, `<a>`, `clip-path/mask` missing ref, `fill/stroke` wrong-type url as **Partial**.
- **Correct** (doc error, not overstatement): `markerUnits strokeWidth` default — add to doc; `glyph-orientation-vertical` remove Full.

---

## Phase 5 — Test Coverage Gaps (§7)

Add focused unit tests (Robolectric `MockCanvas`/`MockPath`/`MockPaint`) for:
- filter+opacity/mask/blend (P1.1)
- paint-order (D1)
- pathLength (P1.7)
- odd-length stroke-dasharray doubling
- vector-effect / non-scaling-stroke
- currentColor static fill/stroke
- stroke-miterlimit clamp (D6)
- missing/invalid clip-path/mask/paint refs (D3/D4)
- gradient/pattern cyclic href (P1.2)
- stop offset clamp (P1.4); radial fx/fy (D2); wrong-type paint (D3)
- cyclic `<use>` (P1.2)
- CSS keyword distinct behavior, var(), !important (CSS*)
- text: textPath render, xml:space, baselines, textLength/rotate
- animation: fill remove (P1.5), additive sum (P1.6), syncbase begin/end, animate on transform, stop offset anim
- switch systemLanguage; `<a>` nested-transform hit-test
- feColorMatrix matrix offset (D7); feTurbulence stitchTiles (D10); feMorphology border (D9); feSpecular alpha (D8); feImage subregion
- transform+viewBox order (D11)
- marker geometry/orient/placement

---

## Phase 6 — Reference Gaps (`SVG_REFERENCE_v2.md`) §8

Update the audit framework (not KSVG code) to capture the 15 missing concepts (ICC profiles, `color-interpolation-filters` default, `enable-background` inputs, `image-rendering`, `shape/text-rendering`, `transform-origin`, deep-clone/`<use>` shadow tree, `xml:base`, `requiredExtensions`/`systemLanguage` model, `clip` vs `clip-path`, `mix-blend-mode`+`isolation` group semantics, `feDropShadow`). **This is a doc edit only**, separate file.

---

## Sequencing & Dependencies

```
Phase 0 (baseline tests)
   └─> Phase 1 (C1–C7 bugs)         [blocking: none, highest value]
          └─> Phase 5 tests for C-items
Phase 2 (D1–D12)                    [independent of P1]
Phase 3 (CSS1 first; CSS2–5 optional)
Phase 4 (doc downgrades)            [after P1/P2 so claims match code]
Phase 5 (remaining test gaps)
Phase 6 (reference doc)             [independent, any time]
```

**Recommended first PRs:** P1.1, P1.2, P1.4, P1.5, P1.6 (correctness + crashes). Then D1, D2, D3, D4 (high-real-world-impact behavior). Then documentation (Phase 4) to stop overstating. Large/optional (CSS3 var(), D5 deep clone, D11) scheduled last or deferred.

---

## Effort Estimate

| Phase | Items | Est. |
|-------|-------|------|
| 0 | baseline | 1d |
| 1 | C1–C7 | 5–7d |
| 2 | D1–D12 | 4–6d |
| 3 | CSS1 (+optional) | 1–4d |
| 4 | doc | 1d |
| 5 | tests | 3–4d |
| 6 | reference | 0.5d |

**Total:** ~16–24 dev-days. Critical path = Phase 1 + Phase 4.
