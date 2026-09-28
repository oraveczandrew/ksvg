# Known Issues (hardware / platform-specific)

Confirmed divergences with NO code fix. Feature support: `SVG-SUPPORT.md`.
Investigation trail: `tmp/RENDER_FIDELITY_PLAN.md`.

## 1. `mix-blend-mode` below API 29 — black flood (OPEN)

`blend_mode.svg` (leaf `multiply`/`screen`) renders circles on BLACK on the
API-26 emulator; white + correct on the API-36 phone. Below API 29 blends fall
back to PorterDuff (`compat/PaintCompat.kt`): the leaf's isolation `saveLayer`
(`Renderer.pushLayer`) composites transparent layer pixels against the opaque
in-SVG backdrop → opaque black. Root isolation doesn't cover this (the flood
comes from the leaf layer, not from under the SVG backdrop).

A leaf direct-draw path matched the golden exactly on the sdk26 **host** — but
host Skia is not the device GPU, so it proves nothing; reverted. Policy: no
host-test iteration on this; on-device proof required (`SvgTestActivity` +
screenshots, `emulator-5554` vs phone). Group-level blend
(`rendering_properties.svg`) is fine on the emulator. Non-PorterDuff modes
(hue/saturation/color/…, difference) fall back to SrcOver below 29 by design.

## 2. Soft vector edges on API-26 emulator HW — device rasterizer (NO BUG)

`marker_shorthand_strokeWidth.svg` bottom row (stroke-width 10) looks BLURRY on
API-26 HW. Not marker-specific: plain ellipses blur identically; the same
device with `LAYER_TYPE_SOFTWARE` is pixel-sharp and the API-29 emulator HW is
crisp (max pixel step 27 vs 250). The API-26 SwiftShader path softens ALL HW
vector edges ~1 user px; `markerUnits=strokeWidth` just magnifies it (31 device
px at sw=10). KSVG emits correct vectors — nothing to fix. Evidence:
`tmp/screenshots/marker_*.png`, `ellipse_emu_hw.png`.
