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
