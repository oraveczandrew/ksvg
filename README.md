# KSVG

KSVG is a high-performance SVG parser and renderer for Android. The framework is **100% Kotlin**; filters are **fully hardware-accelerated on API 33+** through an AGSL-shader pipeline (`RenderEffect` chain, API 31+), backed by a native SIMD engine (x86_64/x86 SSSE3 baselines with AVX2 rows; ARMv7/ARM64 NEON) and a bit-exact pure-Kotlin CPU fallback. It is an optimized fork and evolution of the original [AndroidSVG](https://github.com/BigBadaboom/androidsvg) library, designed for modern Android development with a focus on memory efficiency, immutability, and expanded feature support.

*KSVG is licensed under the [Apache License v2.0](http://www.apache.org/licenses/LICENSE-2.0)*.

## Key Enhancements

- **Modern Language**: Fully rewritten in Kotlin, leveraging modern language features and coroutines compatibility.
- **Immutable DOM**: `Style`, `CSSFontFeatureSettings`, and `CSSFontVariationSettings` are immutable. The builder pattern is optimized to return existing instances if no changes are detected during a build, significantly reducing object churn.
- **Aggressive Pooling**: Extensive use of object pooling for high-frequency objects (`Matrix`, `Canvas`, `PathShape`, `RectF`, `Bitmap`, and `Style.Builder`) to minimize Garbage Collection (GC) pressure and prevent frame drops during complex rendering or animations.
- **Expanded SVG Support**:
    - **Filters**: Comprehensive support for SVG filter primitives (e.g., `feGaussianBlur`, `feColorMatrix`, `feComposite`, `feTurbulence`, `feDisplacementMap`, and more).
    - **Animations**: Support for declarative SVG animations including `<animate>`, `<animateTransform>`, and `<animateColor>`.
    - **Modern Typography**: First-class support for **Variable Fonts** (`font-variation-settings`) and **OpenType features** (`font-feature-settings`).
- **Native Filter Engine**: per-ABI handwritten SIMD kernels (x86_64 and 32-bit x86: SSE2/SSSE3 baselines with AVX2 rows — except the arithmetic-composite kernel, which is scalar-only on 32-bit x86; ARMv7/ARM64: NEON), each bit-exact against the portable Kotlin reference.
- **Dual Filter Backends**: GPU `RenderEffect` pipeline on hardware canvases (AGSL shaders on API 33+, `RenderEffect` chain on API 31+) with automatic decline to the CPU software path; `RenderOptions.softwareFiltering(true)` forces deterministic software rendering.
- **Rendering Performance**: Optimized rendering pipeline with lazy builder initialization and smart style inheritance.

## KSVG vs. AndroidSVG Comparison

| Feature                 | AndroidSVG (Original)  | KSVG                                         |
|:------------------------|:-----------------------|:---------------------------------------------|
| **Language**            | Java                   | 100% Kotlin                                  |
| **Style State**         | Mutable Objects        | **Immutable** (Memory Optimized)             |
| **Memory Management**   | Standard Allocation    | **Object Pooling** (`PoolOwner`)             |
| **SVG Filters**         | Very Limited / Missing | **Comprehensive** (Most Primitives)          |
| **SVG Animations**      | Not Supported          | **Supported** (`animate`, `transform`, etc.) |
| **Variable Fonts**      | Not Supported          | **Supported** (`font-variation-settings`)    |
| **Font Features**       | Not Supported          | **Supported** (`font-feature-settings`)      |
| **Modern Graphics API** | PorterDuff only        | PorterDuff + **BlendMode** (API 29+)         |
| **GC Pressure**         | Regular                | **Minimal** (Optimized for 60/120 FPS)       |

## Modules

| Module       | Artifact                                 | Description                       |
|:-------------|:-----------------------------------------|:----------------------------------|
| `:ksvg`      | `hu.oandras.ksvg:ksvg`                   | Parser, DOM, renderer, public API |
| `:filtering` | `hu.oandras.ksvg:filtering` (transitive) | Native + Kotlin filter kernels    |
| `:glide`     | `hu.oandras.ksvg:glide`                  | Glide integration (optional)      |
| `:showcase`  | — (demo app, not published)              | Sample application                |

## Detailed Feature Support

### SVG Filter Primitives
KSVG provides a highly optimized implementation for almost all SVG 1.1 filter primitives:
- `feGaussianBlur`, `feOffset`, `feColorMatrix`
- `feComponentTransfer` (including `feFuncR`, `feFuncG`, `feFuncB`, `feFuncA` with `identity`, `table`, `discrete`, `linear`, `gamma`)
- `feComposite`, `feBlend` (including modern CSS blend modes on API 29+)
- `feTurbulence` (fractal noise and turbulence)
- `feDisplacementMap`
- `feDiffuseLighting`, `feSpecularLighting`
- `feMorphology` (erode and dilate)
- `feConvolveMatrix`, `feTile`, `feFlood`, `feImage`, `feMerge`

### SVG Animations (SMIL)
Supported declarative animation elements:
- `<animate>`: Animate float and color attributes.
- `<animateTransform>`: Animate `translate`, `scale`, `rotate`, `skewX`, `skewY`.
- `<animateColor>`: Dedicated color transitions.
- Supports `additive` (sum), `accumulate` (sum), `repeatCount` (including `indefinite`), and `fill` (freeze/remove).
- Keyframe-based animations with `keyTimes` and `values` interpolation.

### Modern Typography
- **Variable Fonts**: Full support for `font-variation-settings` (e.g., `'wght' 700, 'wdth' 100`).
- **OpenType Features**: Support for `font-feature-settings` (e.g., `'liga', 'kern', 'smcp'`).
- **Relative Font Weights**: Correct handling of `lighter` and `bolder` keywords according to CSS Fonts 4.

## Installation

```kotlin
dependencies {
    implementation("hu.oandras.ksvg:ksvg:1.0.0-beta01")
    // Optional Glide integration:
    implementation("hu.oandras.ksvg:glide:1.0.0-beta01")
}
```

## Basic Usage

Rendering an SVG to a Canvas:

```kotlin
val svg = SVG.getFromAsset(assets, "sample.svg")
val canvas = Canvas(bitmap)
svg.renderToCanvas(canvas)
```

For more advanced usage, including custom CSS, viewPorts, and target element rendering, see the `RenderOptions` documentation.

## Contributing

### Find a bug?
Please file a [bug report](https://github.com/oraveczandrew/ksvg/issues) and include as much detail as you can. If possible, include a sample SVG file showing the error.

### Feedback
If you wish to contact the author with feedback on this project, you can email me at [info@oandras.hu](mailto:info@oandras.hu).

