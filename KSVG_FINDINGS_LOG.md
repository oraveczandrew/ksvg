# KSVG Investigation Findings Log

Records the resolution of audit findings flagged as **UNCERTAIN** (e.g. D7, D11)
so that subsequent audits do not re-litigate them. For each entry: the claim,
the verification method, the final conclusion, and the resolution.

Format for each entry:
- **Status:** `INVESTIGATING` | `CONFIRMED_BUG` | `NOT_A_BUG` | `STILL_UNCERTAIN`
- **Resolution:** what was changed (or why it was closed as not-a-bug), with
  commit hash / test reference.

---

## D7 — `feColorMatrix` offset multiplied by 255

- **Location:** `ksvg/src/main/kotlin/hu/oandras/ksvg/render/filters/FilterColor.kt:99-104`
- **Claim (KSVG_EXECUTION_PLAN.md D7):** offset column
  (`values[4]`, `[9]`, `[14]`, `[19]`) is multiplied by `255`, suspect wrong.
- **Expected (SVG spec + Android `ColorMatrix`):** all 20 `feColorMatrix`
  values — including the offset (5th column) — are in the **[0,1]** color space.
  The linear coefficients (`a00..a33`) are *not* scaled, so scaling only the
  offset is asymmetric and incorrect.
- **Verification method:**
  1. Render test `D7FeColorMatrixOffsetTest` — `feColorMatrix type="matrix"` that
     adds `0.5` to R on a black rect; asserts output `R ≈ 128`. **Passes** with the
     current code (offset ×255 present).
  2. Direct Android probe `D7AndroidConventionProbe` — applies a raw
     `ColorMatrix` with offset `0.5` (no KSVG scaling) to a black pixel via
     `ColorMatrixColorFilter`. Result: `red = 0`, i.e. Android interprets the
     matrix offset column in **0..255** space (`0.5/255 ≈ 0`), not 0..1.
- **Conclusion:** Android's `ColorMatrix` offset is in **0..255** units. SVG's
  `feColorMatrix` offset is in **0..1**, so KSVG's `values[4]/[9]/[14]/[19] *= 255`
  is the **correct** conversion (0.5 → 127.5 → Android reads as 127.5/255 ≈ 0.5).
  Removing it would BREAK offsets (0.5 → ~0 instead of ~128).
- **Status:** NOT_A_BUG
- **Resolution:** No source change. Kept `D7FeColorMatrixOffsetTest` as a regression
  guard (prevents a well-meaning "fix" that would remove the ×255). Removed the
  temporary `D7AndroidConventionProbe` and the stray `D7FeColorMatrixOffsetProbe`.

---

## D11 — `transform` + `viewBox` order

- **Location:** `Renderer.kt:266-290` (`renderGroupNode`); dom `Svg.kt` / `Symbol.kt`.
- **Claim (KSVG_EXECUTION_PLAN.md D11):** order of element `transform` and
  `viewBox` fit is uncertain; "apply element transform outermost if diverging."
- **Investigation:** For a nested `<svg>` with both `transform` and `viewBox`, the
  element `transform` must be **outermost** (it positions the element in its
  parent); the `viewBox` fit maps content → viewport and is innermost. The render
  order in `renderGroupNode` was `viewBoxTransform` then `transform`, i.e. viewBox
  outermost — **wrong**. Additionally, `Svg`/`Symbol` DOM classes never forwarded
  the parsed `transform` into the built node (`Svg.Builder.build()`/`copy()` and
  `Symbol.Builder.build()` omitted `transform`), so `<svg>`/`<symbol>` ignored the
  `transform` attribute entirely.
- **Verification method:** render test `D11TransformViewBoxOrderTest` — nested
  `<svg width=100 height=100 viewBox="0 0 10 10" transform="translate(50,0)">`
  with a red rect. Correct (transform outermost): red spans x 50..150. Before the
  fix the rect rendered at the origin (transform dropped) / off-screen (wrong
  order); after the fix it spans 50..150.
- **Conclusion:** Real defect (two parts): (1) `transform` attribute was silently
  dropped on `<svg>`/`<symbol>`; (2) when applied, it was composed innermost
  instead of outermost relative to the `viewBox` fit.
- **Status:** CONFIRMED_BUG (fixed)
- **Resolution:**
  - `Renderer.renderGroupNode`: apply element `transform` **before**
    `viewBoxTransform` so the element transform is outermost.
  - `Svg` / `Symbol` DOM: add `transform` constructor param and forward
    `getTransform()` from the builder (and `Svg.copy()`).
  - Added `D11TransformViewBoxOrderTest` regression test.

---

## D12 — `glyph-orientation-vertical` no-op

- **Location:** `dom/style/Style.kt`, `render/text/*`.
- **Claim (KSVG_EXECUTION_PLAN.md D12):** property is a no-op; doc claims Full.
- **Investigation:** The value is parsed and propagated through the style system,
  but no code in the text renderer consumes it. Vertical glyph orientation only
  has observable effect inside a vertical text layout, and `writing-mode`
  itself is unimplemented — so implementing this property alone would not
  change any rendering output today.
- **Conclusion:** Implementing is not worthwhile until vertical text layout
  exists; the honest state is "unsupported".
- **Status:** RESOLVED as doc-downgrade (per plan: "either implement or
  downgrade doc claim")
- **Resolution:** `SVG-SUPPORT.md` entry changed Full → None with note. No code
  change; the parsed value remains harmless. Revisit together with any future
  `writing-mode` implementation.

---

## CSS2/CSS3/CSS5 — `revert`, `var()`, `revert-layer`/`@layer`

- **Claim (KSVG_EXECUTION_PLAN.md):** `revert` cannot be fully correct without
  cascade-origin tracking; `var()`/custom properties unimplemented (large,
  ROI-low); layer features only meaningful with custom properties.
- **Conclusion:** Per plan guidance ("CSS1 is the only correctness bug with
  real-world impact; CSS2–CSS5 can be doc-downgraded"), these are documented as
  Partial/unsupported instead of implemented. `!important` (CSS4) WAS
  implemented since it has real-world impact.
- **Status:** RESOLVED as doc-downgrade (CSS3 deferred)
- **Resolution:** `SVG-SUPPORT.md` CSS keywords section updated: `unset`,
  `initial`, `revert` → Partial with behavioral notes; explicit note that
  `var()`/`revert-layer`/`@layer` are unsupported.

---

## feTurbulence stitch tile-size basis (tile from device-pixel extents)

- **Location:** `FilterGeneration.kt` (`doFeTurbulenceFilter`, stitch branch).
- **What changed:** sting tile size now derives from the device-pixel kernel
  extents instead of a `ceil` of the user-space region. Replaced
  `ceil(filterRegion.width().toDouble())` / `ceil(filterRegion.height().toDouble())`
  with `width.toDouble()` / `height.toDouble()` (`filterRegionPx` extents), the
  same semantic region librsvg uses (`bounds.width()/bounds.height()` of the
  output IRect). Kernel, parity test, clip, and geometry untouched.
- **Similarity on `turbulence_seed_stitch.svg`** (AiVisualDiffTest, software
  filtering): baseline 0.3492 → after change 0.4012
  (diffPixels 38832→29213, cornerDiff 11786→9080, meanAbsErr 24.03→18.44).
  KSVG bfX + both periods now match librsvg; bfY differs only via the row below.
- **Tests passed:** full `:ksvg:testDebugUnitTest` (5025 tests) — identical
  12/12 pre-existing failure set before/after, zero new regressions.
  `TurbulenceKernelParityTest` 2/2 green (forced re-run), kernel unchanged.
- **Remaining discrepancy (not addressed):** librsvg renders 194 rows vs
  KSVG's 193 for the fixture — now fully diagnosed (see
  `tmp/PHASE2_INPUT_DIVERGENCE.md`, "193 vs 194 — focused diagnosis").
  **Root cause:** librsvg tokenizes ALL number/percentage lengths at f32
  (cssparser), widened to f64 at `length.rs:311`. The default filter region
  `-10%` becomes `f64(f32(-0.1)) = -0.10000000149011612` instead of the f64
  `-0.1` KSVG uses, so librsvg's device-space region top lands at
  `15.999999761581421` (just *below* the pixel boundary) and
  `y0.floor()` → 15 instead of 16. Bottom is identical (both `ceil` → 209);
  the extra row comes entirely from the top integer bound (15 vs 16).
  **Proof:** rebuilt librsvg with only the four default region lengths
  constructed at f64 (`CssLength::new`, bypassing the tokenizer); re-captured
  `tss_256` → bounds top moved 15 → 16 exactly (IRect `(0,15,256,209)` H=194 →
  `(0,16,256,208)` H=192). No fix implemented; matching librsvg's f32
  percentages (or making librsvg's parse f64) is a librsvg-side choice, and
  forcing KSVG to mimic the f32 slop would require intentionally wrong lengths.
