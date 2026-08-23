# Phase 0 — `SVG-SUPPORT.md` Status Snapshot

**Date:** 2026-08-23 (Phase 0 baseline)
**Purpose:** Record the *current* claimed support status of every feature that the
`KSVG_AUDIT_REPORT.md` / `KSVG_EXECUTION_PLAN.md` flags as overstated or buggy, so
that later phases (esp. Phase 4 — Documentation Accuracy) can diff against this
baseline and produce a clean downgrade commit.

Each entry is copied verbatim from `SVG-SUPPORT.md` at the referenced line. The
"Audit finding" column references the execution plan item that disputes the claim.

| Line | Feature                                                               | Claimed status | Audit finding                                        |
|------|-----------------------------------------------------------------------|----------------|------------------------------------------------------|
| 16   | `<use>` (`href`,`x`,`y`,`width`,`height`)                             | Full           | §4 / D5 deep-clone shared state; P1.2 cyclic crash   |
| 17   | `<a>` (`href`, click)                                                 | Full           | audit: nested-transform hit-test gap                 |
| 18   | `<switch>` (`systemLanguage`, …)                                      | Full           | audit: `systemLanguage` model incomplete             |
| 24   | `<mask>` (`maskUnits`, …)                                             | Full           | D4 missing ref handling                              |
| 50   | `<textPath>` (`href`,`startOffset`)                                   | Full           | audit: `method`/`spacing`/`side` missing (Partial)   |
| 57   | `<radialGradient>` (`fx`,`fy`,`fr`, …)                                | Full           | D2 `fx/fy` default wrong (Partial)                   |
| 58   | `<stop>` (`offset`,`stop-color`,`stop-opacity`)                       | Full           | P1.4 offset clamp bug (Partial)                      |
| 64   | `<filter>` (`filterUnits`,`primitiveUnits`,`x/y/w/h`)                 | Full           | P1.1 drops opacity/mask/blend when combined          |
| 75   | `<feSpecularLighting>` (in, surfaceScale, …)                          | Full           | D8 alpha must be max(R,G,B)                          |
| 79   | `<feImage>` (`href`)                                                  | Full           | audit: subregion / feImage gaps                      |
| 82   | `<feMorphology>` (in, operator, radius)                               | Full           | D9 border = transparent black, not edge clamp        |
| 84   | `<feTurbulence>` (baseFrequency, numOctaves, seed, stitchTiles, type) | Full           | D10 stitchTiles unimplemented                        |
| 109  | `fill` (colors, `url()`, `currentColor`, `none`, `context-fill`)      | Full           | D3 wrong-type `url()` keeps color (should be `none`) |
| 116  | `stroke-miterlimit`                                                   | Full           | D6 no clamp to >=1                                   |
| 121  | `color` (sets `currentColor`)                                         | Full           | (ok)                                                 |
| 134  | `clip-path` (references `<clipPath>`)                                 | Full           | D4 missing/invalid ref should hide element           |
| 138  | `mask` (references `<mask>`)                                          | Full           | D4 missing/invalid ref should hide element           |
| 162  | `filter` (references `<filter>`)                                      | Full           | P1.1 combination breaks with opacity/mask/blend      |
| 200  | `dominant-baseline`                                                   | Full           | audit: mostly unimplemented (Partial)                |
| 209  | `word-spacing`                                                        | Full           | (compat-gated; verify)                               |
| 210  | `writing-mode`                                                        | Full           | audit: unimplemented (Partial)                       |
| 211  | `glyph-orientation-vertical`                                          | Full           | D12 no-op (should be None)                           |
| 224  | `color-interpolation-filters`                                         | Full           | D7 offset ×255 suspect                               |
| 250  | `inherit`                                                             | Full           | CSS1: cannot override presentation attr              |
| 251  | `unset`                                                               | Full           | CSS1: same as inherit model                          |
| 253  | `revert`                                                              | Full           | CSS2: cannot be fully correct                        |
| 267  | animation `fill` (`freeze`,`remove`)                                  | Full           | P1.5 `remove` never reverts                          |
| 275  | animation `additive` (`replace`,`sum`)                                | Full           | P1.6 `sum` frame-accumulates                         |

## Notes
- Feature lines 121/209 are recorded as plausibly correct; they are included for
  completeness but are NOT targeted for downgrade unless later phases disprove them.
- After each fix phase, re-run this snapshot (or `git diff SVG-SUPPORT.md`) to
  confirm the claimed status now matches the implemented behaviour.
