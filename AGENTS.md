# KSVG Development Guide for AI Agents

KSVG is a high-performance SVG rendering library for Android, written in Kotlin. It parses SVG XML into a DOM, builds an optimized Render Tree, and draws using the Android Canvas API.

## Project Structure
- **`:ksvg`**: The main rendering library.
- **`:glide`**: A plugin for the Glide image loading library.
- **`:showcase`**: An Android application demonstrating the library's capabilities.

## Core Architecture

1. **DOM (`hu.oandras.ksvg.dom`)**: A light-weight representation of the SVG XML structure.
2. **Render Tree (`hu.oandras.ksvg.render.KSVGRenderNode`)**: Created from the DOM. This phase resolves CSS styles, inherits properties, and pre-calculates geometry.
3. **Scene (`hu.oandras.ksvg.render.RenderScene`)**: Wraps the built tree and owns the viewport geometry: `node.viewPort` / `node.viewBoxTransform` are written ONLY by `RenderScene.applyViewport` (never by the builder). Drawable bounds changes update the scene in place - do not reintroduce viewport writes into `RenderTreeBuilder`.
4. **Renderer (`hu.oandras.ksvg.render.SVGAndroidRenderer`)**: Traverses the Render Tree and executes `canvas` operations.
5. **Animations**: Centralized in `AnimationRenderer.kt` and `AnimationUtils.kt`. Uses a SMIL-based timing model.

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
*   **Collections** Prefer non-allocating functions in `hu.oandras.ksvg.utils.Collections`, such as `forEachElement`.

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
 *   **Deterministic filter output**: When a unit test exercises the filter pipeline, render with the
     software backend via `hu.oandras.ksvg.test.renderWithLibrary(file, bitmap, softwareFiltering = true)`
     (see `CommonTestUtils`). Use the shared pixel helpers `Bitmap.forEachPixel` and `countPixels`
     (also in `CommonTestUtils`) for assertions; inspect channels with `hu.oandras.ksvg.utils.ColorUtils`
     (`val Int.alpha/red/green/blue`). Note that `renderWithLibrary`'s `softwareFiltering` argument opts in to
     `@SlowSoftwareFiltering` internally.
 *   **Test Quality**: Only test non-trivial logic.
*   **Jacoco Coverage**: To generate a coverage report, run:
    ```bash
    ./gradlew :ksvg:jacocoTestReport -Dorg.gradle.warning.mode=none
    ```
     The report will be available at `ksvg/ksvg/build/reports/jacoco/jacocoTestReport/html/index.html`.
  *   **Robolectric text/canvas unit-test pitfalls** (read before asserting on rendered pixels):
    *   **Text only rasterizes under `@GraphicsMode(NATIVE)`**; the default LEGACY canvas draws no glyphs (transparent bitmap). Annotate text tests with `@GraphicsMode(NATIVE)`.
    *   **Never shadow `MockCanvas`/`MockPath`/`MockPaint` for rasterization checks.** `MockPaint` setters (`setColor`,`setTextSize`,`setTypeface`,…) skip `super`, so the real `Paint` gets no color/size and draws nothing. Use `hu.oandras.ksvg.test.renderWithLibrary(svg, bitmap)` + `countPixels`/`forEachPixel`; the Mock* shadows are only good for op-list assertions on shapes (path/rect).
    *   **On NATIVE (HW) the display-list cache is active**: `drawText`/`drawPath` land in an offscreen `RenderNode`, invisible to `MockCanvas` op logs — so don't assert on `drawText`/`drawRect` ops, use `Bitmap.sameAs`/`countPixels`.
    *   **`Style.Builder` needs a base**: `build()` reads `lateinit original` and throws on bare `Style.Builder()`. Use `Style().toBuilder().apply{…}.build()`; its enum fields (in `dom.style`/`dom.text`) use lowercase constants, e.g. `WritingMode.horizontal_tb`, `TextTransform.Uppercase`, `BaselineShift(null, BaselineShift.Type.Sub)`.
 *   **Golden PNGs**: For visual regression, use `FiltersVisualComparisonTest`. Note that `MeteoconsVisualComparisonTest` is slow and can be excluded during quick iterations.
    ```bash
    ./gradlew :ksvg:testDebugUnitTest -PexcludeSlowTests -Dorg.gradle.warning.mode=none
    ```
    Run it only before major releases or after changes to the animation engine.
 *   **Native vs Kotlin kernel parity**: `filtering/.../TurbulenceNativeParityTest` compares the
     native feTurbulence kernel (via `SoftwareKernels`) against the pure-Kotlin reference
     (`KotlinKernels`) bit-exactly. It is a host-JVM test that loads a host-architecture
     (`x86_64`) build of `libksvgblur`. The `:filtering` `buildHostNativeLib` task generates it
     automatically (into `filtering/build/host-native/`) and the test task depends on it, so
     running the test is all you need:
     ```bash
     ./gradlew :filtering:testDebugUnitTest --tests "hu.oandras.ksvg.filtering.TurbulenceNativeParityTest"
     ```
     The host CMake project lives at `filtering/host-native/`; touching any native filter
     source or that CMakeLists invalidates the up-to-date check and rebuilds. If the host lib is
     absent/unloadable the test fails loudly (it asserts the native path actually ran), rather than
     silently comparing Kotlin against Kotlin.

## Tracking Progress
*   **`SVG-SUPPORT.md`**: This is the **Source of Truth** for supported features. If you implement or improve a feature, update its status (Full/Partial/None) here.
*   **`SvgFeatures.kt`**: Update the supported feature strings returned to `<switch>` elements.

## Common Gotchas
*   **Explicit API mode is ON**: all public declarations (classes, objects, functions, properties, consts) need explicit visibility modifiers and explicit return/property types. Missing ones are compile errors, not warnings.
*   **`public` is NOT needed in `src/test` / `src/androidTest`** (nor in any plain test source set): `public` is the Kotlin default there, so the explicit modifier is redundant noise. Only `src/main` code needs the explicit `public` (for Explicit API mode). **Exception — `src/testFixtures`**: the `filtering` module enables explicitApi, which DOES cover the `testFixtures` compilation (it is compiled as a real `testFixturesApi` surface), so corpus classes/members under `filtering/src/testFixtures/...` DO need explicit `public` + explicit return/property types. Those are the shared filter-validation corpora (`XxxValidationCorpus`), pulled in by both `test` and `androidTest` via `testImplementation(testFixtures(project(":filtering")))` / `androidTestImplementation(testFixtures(...))`.
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
- Example: `./gradlew :ksvg:testDebugUnitTest --tests "hu.oandras.ksvg.aihelpers.AiVisualDiffTest" -PverifyFilter=filter_specular -Dorg.gradle.warning.mode=none`

## Rendering
- Drawables must be renderable off the main thread.
- **No capturing lambdas / local function references in hot paths.** In render
  and animation-update code, a lambda that captures locals, a `::localFun`
  reference, or any non-inline higher-order call allocates Function objects on
  EVERY invocation. Use private methods with explicit parameters, inline
  helpers (`forEachElement`, pools), or pre-allocated state instead.
  (`forEachElement` is inline and safe.)
- Do not introduce mutable shared or global state.
- Do not use mutable singleton (`object`) helpers for allocation avoidance.
- Reusable state must be owned by the current rendering operation and must not be shared between threads.
- **Forcing the software filter backend**: The renderer prefers the GPU/RenderEffect pipeline when the canvas is
  hardware-accelerated and the API level allows. To force the CPU/software filter backend, use
  `RenderOptions.softwareFiltering(enabled = true)`, e.g.
  `SVG.getFromString(svg).renderToCanvas(canvas, RenderOptions.create().softwareFiltering(true))`.
  The setter is annotated with `@SlowSoftwareFiltering` (a `kotlin.RequiresOptIn` marker at WARNING level) because
  software filtering is significantly slower — callers must opt in with `@OptIn(SlowSoftwareFiltering::class)` to
  acknowledge the cost. Use it for deterministic output (tests, golden comparisons) or for filter primitives the
  GPU backend does not yet support. The GPU path is selected automatically otherwise.

## Native blur (`:nativeblur`) — JNI / NDK
- **NDK build, no hand-config**: `gaussian_blur.cpp` is an Android/NDK CMake build (Gradle compiles it via `nativeblur/.cxx`); never configure it on the host toolchain.
- **IDE errors are false positives**: "Cannot resolve symbol 'JNIEXPORT'" / "no project target" mean the IDE lacks the NDK toolchain — point its CMake profile at the **SDK's** cmake/ninja + NDK toolchain file (see full command above if needed). Do not change the code for these.
- **Caller-owned buffers**: blur state lives in `StackBlurScratch` (sealed interface) — `NativeScratch` (lazy native handle) and `FallbackScratch` (Kotlin stack blur). Never add shared/global mutable state to the native code.
- **NEVER mark a `@JvmStatic external fun` (JNI entry) `internal`**: Kotlin mangles internal members (`apply` → `apply$...`), so the C++ symbol (`Java_<pkg>_<Class>_<method>`) stops matching → `UnsatisfiedLinkError`. Make the enclosing `object` `internal`.

## Work Log

- For non-trivial tasks, maintain a problem-specific Markdown work log (for example, SVG_FILTER_RENDERING.md or ISSUE_142_WORKLOG.md).
- Record important findings, attempted approaches, failures, decisions, and next steps. Read it before starting or resuming work, and do not repeat failed approaches unless new evidence justifies them.
- Update the log after each major investigation step or milestone, so the current state can be recovered after interruption.

## Quick Commands
- **Do not pass `--no-daemon` to Gradle** — always use the Gradle daemon (omit `--no-daemon`).
- Build: `./gradlew :ksvg:compileDebugKotlin -Dorg.gradle.warning.mode=none`
- Tests: `./gradlew :ksvg:testDebugUnitTest -Dorg.gradle.warning.mode=none`
- Coverage: `./gradlew :ksvg:jacocoTestReport -Dorg.gradle.warning.mode=none`

### Tooling preferences
- **Prefer IDE functions over shell commands** whenever one exists — e.g. `idea_build_project` for compiling, `idea_get_file_problems`/`idea_lint_files` for diagnostics, `idea_search_symbol`/`idea_search_regex` for search, `idea_rename_refactoring` for renames. Fall back to the terminal only when no IDE tool fits.
- **Temporary files go inside the project**, in a `tmp/` folder at the repo root (git-ignored), not in system temp directories. Clean it up when done.

### Viewing test `println` / stdout
Test standard output (e.g. `println` debug statements) is suppressed by default. Pass `-PshowTestOutput --console=plain` to surface it:
```bash
./gradlew :ksvg:testDebugUnitTest --tests "hu.oandras.ksvg.aihelpers.AnalyzeComponentTransferTest" -PshowTestOutput --console=plain -Dorg.gradle.warning.mode=none
```


- Use US English for all code and documentation. You can answer in English even if the question is in Hungarian.
- Use English internally and for all code, comments, documentation, logs, commit messages, and other project artifacts.
- Use the IDE's import optimization feature to remove unused imports, if possible.
