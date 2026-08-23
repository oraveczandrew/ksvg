# KSVG Development Guide for AI Agents

KSVG is a high-performance SVG rendering library for Android, written in Kotlin. It parses SVG XML into a DOM, builds an optimized Render Tree, and draws using the Android Canvas API.

## Project Structure
- **`:ksvg`**: The main rendering library.
- **`:glide`**: A plugin for the Glide image loading library.
- **`:showcase`**: An Android application demonstrating the library's capabilities.

## Core Architecture

1.  **DOM (`hu.oandras.ksvg.dom`)**: A light-weight representation of the SVG XML structure.
2.  **Render Tree (`hu.oandras.ksvg.render.KSVGRenderNode`)**: Created from the DOM. This phase resolves CSS styles, inherits properties, and pre-calculates geometry.
3.  **Renderer (`hu.oandras.ksvg.render.SVGAndroidRenderer`)**: Traverses the Render Tree and executes `canvas` operations.
4.  **Animations**: Centralized in `AnimationRenderer.kt` and `AnimationUtils.kt`. Uses a SMIL-based timing model.

## Critical Development Conventions

### 1. Performance & Zero-Allocation Rule
The rendering loop (`render()` methods) and animation updates (`updateAnimations()`) are performance-critical.
*   **NO NEW ALLOCATIONS**: Do not create new `Matrix`, `PathShape`, `PathMeasure`, `RectF`, or `FloatArray` objects during draw/update.
*   **Object Pooling**: Always use the pools provided by the `RenderContext`:
    ```kotlin
    renderContext.matrixPool.withPooledObject { matrix -> /* usage */ }
    ```
*   **XFerModes**: Never create `PorterDuffXfermode` instances. Use the pre-allocated constants in `hu.oandras.ksvg.utils.XFerModes`.
*   **Method count**: Use `@JvmField`-s, if possible, to reduce method count.

### 2. Compatibility & PaintCompat
The project `minSdk` is 26, but some features (like `wordSpacing` or `BlendMode`) require higher APIs.
*   **Always use `PaintCompat`**: Use `hu.oandras.ksvg.utils.PaintCompat` (e.g., `paint.setBlendModeCompat(mode)`) instead of direct `SDK_INT` checks when possible.
*   **Blend Modes**: Support is abstracted via `BlendModeCompat`. Check `isBlendModeSupported(mode)` before assuming a mode works on older APIs.

### 3. SMIL Timing Model
Animations must respect `dur`, `repeatCount`, `repeatDur`, and `end`.
*   Use `hu.oandras.ksvg.utils.calculateProgress` and `hu.oandras.ksvg.utils.isFinished` for all timing logic to ensure standard compliance.

### 4. Asking for sources you cannot reliably reproduce
Do **not** fabricate or guess complex low-level sources (e.g. hand-written ARM/NEON assembly, AArch64 assembly, GPU shaders, or generated coefficient/lookup tables). If such a file is required and you cannot reproduce it exactly, **ask the user to provide the file** — it is always acceptable to request it rather than invent a subtly-wrong version.
*   When wiring in a third-party source (e.g. the RIR Toolkit `Blur` kernels), confirm the exact symbol/ABI contract before calling into it; mismatched calling conventions produce silent, hard-to-debug corruption.

## How-To Guides

### Adding a new CSS property
1.  **`Style.kt`**: Add a field to the `Style` class.
2.  **`Style.kt`**: Define a `SPECIFIED_*` constant (as a bit-flag).
3.  **`Style.kt`**: Update `processStyleProperty()` to parse the value.
4.  **`RenderTreeBuilder.kt`**: Ensure the property is copied/inherited during tree building.

### Adding a new SVG attribute
1.  **`SVGAttr.kt`**: Add the attribute to the enum and its name mapping.
2.  **`SVGParserImpl.kt`**: Handle the attribute in the relevant element's `onAttribute` method.

### Adding a new element tag
1.  **`SVGTag.kt`**: Add to the enum.
2.  **`dom/`**: Create the DOM class and its `Builder`.
3.  **`SVGParserImpl.kt`**: Register the builder in the parsing logic.
4.  **`RenderTreeBuilder.kt`**: Add a `build*` method to create the corresponding `RenderNode`.

## Testing & Coverage
*   **Unit Tests**: Located in `ksvg/src/test/kotlin`. Check assert functions in `Asserts.kt`.
*   **Robolectric Shadows**: We use `MockCanvas`, `MockPath`, and `MockPaint`.
*   **Test Quality**: Only test non-trivial logic.
*   **Jacoco Coverage**: To generate a coverage report, run:
    ```bash
    ./gradlew :ksvg:jacocoTestReport
    ```
    The report will be available at `ksvg/ksvg/build/reports/jacoco/jacocoTestReport/html/index.html`.
*   **Golden PNGs**: For visual regression, use `FiltersVisualComparisonTest`. Note that `MeteoconsVisualComparisonTest` is slow and can be excluded during quick iterations.
    ```bash
    ./gradlew :ksvg:testDebugUnitTest -PexcludeSlowTests
    ```
    Run it only before major releases or after changes to the animation engine.

## Tracking Progress
*   **`SVG-SUPPORT.md`**: This is the **Source of Truth** for supported features. If you implement or improve a feature, update its status (Full/Partial/None) here.
*   **`SvgFeatures.kt`**: Update the supported feature strings returned to `<switch>` elements.

## Common Gotchas
*   **`Paint.setFontVariationSettings`**: Throws `NoSuchMethodError` in Robolectric; avoid testing complex text layouts in unit tests if they rely on variable fonts.
*   **`stroke-dasharray`**: Requires normalization (doubling the array if length is odd) before it can be used with Android's `DashPathEffect`.
*   **`accumulate="sum"`**: For colors (ARGB), "sum" is ignored per SVG spec.
*   **CSS keyword matching is case-insensitive**: use `equals(KEYWORD, ignoreCase = true)` (or `Locale.US` lowercase tokens) in `parse*` funcs, never `==`/`when(value)`. Exception: `parseFontFeatureSettings` 4-char feature tags stay case-sensitive.
*   **`CSSParser.RuleMatchContext`/`Selector`** are nested but referenced externally as `CSSParser.*` — keep the `CSSParser.` prefix when refactoring.
* 
## AI Helper Test Package (`hu.oandras.ksvg.aihelpers`)
Reusable image-diff/diagnostic tests for investigating rendering fidelity live here. Keep them in the codebase so future sessions can reuse them.
- **`AiVisualDiffTest`**: Parameterized per-SVG diff test. It renders each SVG under `test-data/verification/`/`filters/`/`meteocons/`, compares against the matching `*-golden/*.png` (rsvg/browser reference) using `hu.oandras.ksvg.comparisons.GoldenImageUtils.compareWithGolden`, and writes `<name>.out.png`, `<name>.diff.png`, and `summary.txt` (similarity, diffPixels, cornerDiff, meanAbsErr) under `ksvg/test-data/ai-helper/<name>/`.
- Use the library color helpers from `hu.oandras.ksvg.utils.ColorUtils` (`val Int.alpha/red/green/blue`) for pixel math — do not recompute `(p shr 24) and 0xff` inline.
- **CLI filtering**: pass `-PverifyFilter=<substring>` (e.g. `-PverifyFilter=filter_specular`) to run a single SVG across all visual-comparison suites (`VerificationVisualComparisonTest`, `FiltersVisualComparisonTest`, `MeteoconsVisualComparisonTest`, `AiVisualDiffTest`). The value is forwarded to the JVM system property `ksvg.verify.filter` and matched case-sensitively against the SVG file name.
- Example: `./gradlew :ksvg:testDebugUnitTest --tests "hu.oandras.ksvg.aihelpers.AiVisualDiffTest" -PverifyFilter=filter_specular`

## Rendering
- Drawables must be renderable off the main thread.
- Do not introduce mutable shared or global state.
- Do not use mutable singleton (`object`) helpers for allocation avoidance.
- Reusable state must be owned by the current rendering operation and must not be shared between threads.

## Native blur (`:nativeblur`) — JNI / NDK
- **NDK build, no hand-config**: `gaussian_blur.cpp` is an Android/NDK CMake build (Gradle compiles it via `nativeblur/.cxx`); never configure it on the host toolchain.
- **IDE errors are false positives**: "Cannot resolve symbol 'JNIEXPORT'" / "no project target" mean the IDE lacks the NDK toolchain — point its CMake profile at the **SDK's** cmake/ninja + NDK toolchain file (see full command above if needed). Do not change the code for these.
- **Caller-owned buffers**: blur state lives in `StackBlurScratch` (sealed interface) — `NativeScratch` (lazy native handle) and `FallbackScratch` (Kotlin stack blur). Never add shared/global mutable state to the native code.

## Quick Commands
- **Do not pass `--no-daemon` to Gradle** — always use the Gradle daemon (omit `--no-daemon`).
- Build: `./gradlew :ksvg:compileDebugKotlin`
- Tests: `./gradlew :ksvg:testDebugUnitTest`
- Coverage: `./gradlew :ksvg:jacocoTestReport`

### Tooling preferences
- **Prefer IDE functions over shell commands** whenever one exists — e.g. `idea_build_project` for compiling, `idea_get_file_problems`/`idea_lint_files` for diagnostics, `idea_search_symbol`/`idea_search_regex` for search, `idea_rename_refactoring` for renames. Fall back to the terminal only when no IDE tool fits.
- **Temporary files go inside the project**, in a `tmp/` folder at the repo root (git-ignored), not in system temp directories. Clean it up when done.

### Viewing test `println` / stdout
Test standard output (e.g. `println` debug statements) is suppressed by default. Pass `-PshowTestOutput --console=plain` to surface it:
```bash
./gradlew :ksvg:testDebugUnitTest --tests "hu.oandras.ksvg.aihelpers.AnalyzeComponentTransferTest" -PshowTestOutput --console=plain
```


- Use US English for all code and documentation.
- Use the IDE's import optimization feature to remove unused imports, if possible.
