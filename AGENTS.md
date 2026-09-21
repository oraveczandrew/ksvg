# KSVG Development Guide for AI Agents

KSVG is a high-performance SVG rendering library for Android, written in Kotlin. It parses SVG XML into a DOM, builds an optimized Render Tree, and draws using the Android Canvas API.

## Project Structure
- **`:ksvg`**: The main rendering library.
- **`:glide`**: A plugin for the Glide image loading library.
- **`:showcase`**: An Android application demonstrating the library's capabilities.

## Core Architecture

1. **DOM (`hu.oandras.ksvg.dom`)**: light-weight representation of the SVG XML structure.
2. **Render Tree (`hu.oandras.ksvg.render.KSVGRenderNode`)**: resolves CSS styles, inherits properties, pre-calculates geometry. Never writes viewport geometry.
3. **Scene (`hu.oandras.ksvg.render.RenderScene`)**: owns the viewport (`node.viewPort` / `node.viewBoxTransform` are written ONLY by `RenderScene.applyViewport`).
4. **Renderer (`hu.oandras.ksvg.render.SVGAndroidRenderer`)**: traverses the tree and executes `canvas` operations.
5. **Animations**: centralized in `AnimationRenderer.kt` and `AnimationUtils.kt` (SMIL timing model).

Before touching render/filter code, re-read `RENDERING_FILTERING.md` — it is the source of truth for pipeline, region, and composition rules.

## Documentation Map
- **`SVG-SUPPORT.md`**: **Source of Truth** for supported SVG features (Full/Partial/None) — keep it updated with every feature change.
- **`SVG_REFERENCE_v2.md`**: AI-facing, audit-first reference for implementing/reviewing SVG behavior (SVG 2 + SVG 1.1 + delegated CSS/graphics specs). It is a map and audit framework, not a substitute for the specifications.
- **`RENDERING_FILTERING.md`**: Living architecture and validation notes for the rendering/filtering pipeline. Re-read it before touching render/filter code.
- **`BENCHMARKS.md`**: Kernel benchmark tables (native SIMD vs. scalar C++ vs. Kotlin reference). Rows follow the ISA superset order (see "Benchmark table conventions").
- **`native-docs/`**: Low-level native docs — `ASSEMBLY_CONVENTIONS.md` (ABI/argument/register/PIC contract plus parity gate), `ASSEMBLY_FORMATTING_REQUIREMENTS.md` (mandatory formatting, indentation, mnemonic padding, and semantic commenting requirements for handwritten assembly), `SIMD_KERNEL_TRICKS.md` (transferable SIMD optimization checklist distilled from the top-performing filter kernels), and per-ISA implicit-register-clobber tables (`X86_IMPLICIT_REGISTER_CLOBBERS.md`, `AARCH64_IMPLICIT_REGISTER_CLOBBERS.md`, `ARM32_IMPLICIT_REGISTER_CLOBBERS.md`): reference lists of which instructions read/write registers or architectural state implicitly (e.g. `MUL`/`DIV` clobbering `EDX`, `CPUID` clobbering `EBX`, string/SP/flags state, pointer-auth/exclusive-monitor state) so handwritten assembly never relies on value survival that the ISA does not guarantee.
- **`README.md`**: Public project overview, key enhancements, and usage.
- **qemu-trace-bridge** (external repo, https://github.com/oraveczandrew/qemu-trace-bridge): instruction-by-instruction tracer for native assembly kernels under QEMU (i386+AVX2 with full 256-bit YMM via a patched GDB stub, ARM32/ARM64 NEON on stock QEMU). Use it to observe the exact before/after machine state when static audit (§5) is inconclusive.

## Critical Development Conventions

### 1. Performance & Zero-Allocation Rule
The rendering loop (`render()` methods) and animation updates (`updateAnimations()`) are performance-critical: no allocations, no capturing lambdas, no shared mutable state in hot paths. Full rules live in `RENDERING_FILTERING.md` §5 — read it before touching render/filter code.

### 2. Asking for sources you cannot reliably reproduce
Do **not** fabricate or guess complex low-level sources (e.g., handwritten ARM/NEON assembly, AArch64 assembly, GPU shaders, or generated coefficient/lookup tables). If such a file is required, and you cannot reproduce it exactly, **ask the user to provide the file** — it is always acceptable to request it rather than invent a subtly wrong version.
*   When wiring in a third-party source (e.g., the RIR Toolkit `Blur` kernels), confirm the exact symbol/ABI contract before calling into it; mismatched calling conventions produce silent, hard-to-debug corruption.

### 3. Assembly bug investigation — start here
When investigating a suspected native/assembly kernel bug, first read native-docs/ASSEMBLY_CONVENTIONS.md (especially the "Typical mistakes" checklist), then native-docs/SIMD_KERNEL_TRICKS.md (structural patterns, rounding/parity checklist, known traps).

Before touching code, identify the target ISA and grep the relevant implicit-register-clobber table for every suspicious instruction:

x86/x86-64: native-docs/X86_IMPLICIT_REGISTER_CLOBBERS.md
AArch64: native-docs/AARCH64_IMPLICIT_REGISTER_CLOBBERS.md
ARM32: native-docs/ARM32_IMPLICIT_REGISTER_CLOBBERS.md

Use the grep results to verify whether any instruction has implicit register/state inputs or outputs that could invalidate the suspected register-liveness assumptions.

If static audit is inconclusive, trace one instruction live with qemu-trace-bridge and compare before/after state.

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
    *   **Text only rasterize under `@GraphicsMode(NATIVE)`**; the default LEGACY canvas draws no glyphs (transparent bitmap). Annotate text tests with `@GraphicsMode(NATIVE)`.
    *   **Never shadow `MockCanvas`/`MockPath`/`MockPaint` for rasterization checks.** `MockPaint` setters (`setColor`,`setTextSize`,`setTypeface`,…) skip `super`, so the real `Paint` gets no color/size and draws nothing. Use `hu.oandras.ksvg.test.renderWithLibrary(svg, bitmap)` + `countPixels`/`forEachPixel`; the Mock* shadows are only good for op-list assertions on shapes (path/rect).
    *   **On NATIVE (HW) the display-list cache is active**: `drawText`/`drawPath` land in an offscreen `RenderNode`, invisible to `MockCanvas` op logs — so don't assert on `drawText`/`drawRect` ops, use `Bitmap.sameAs`/`countPixels`.
 *   **Golden PNGs**: For visual regression, use `FiltersVisualComparisonTest`. Note that `MeteoconsVisualComparisonTest` is slow and can be excluded during quick iterations.
    ```bash
    ./gradlew :ksvg:testDebugUnitTest -PexcludeSlowTests -Dorg.gradle.warning.mode=none
    ```
    Run it only before major releases or after changes to the animation engine.
 *   **Native vs. Kotlin kernel parity**: `filtering/.../*NativeParityTest` compares the
     native kernels (via `SoftwareKernels`) against the pure-Kotlin reference
     (`KotlinKernels`) bit-exactly. It is a host-JVM test that loads a host-architecture
     (`x86_64`) build of `libksvgblur`. The `:filtering` `buildHostNativeLib` task generates it
     automatically (into `filtering/build/host-native/`) and the test task depends on it, so
     running the test is all you need ex:
     ```bash
     ./gradlew :filtering:testDebugUnitTest --tests "hu.oandras.ksvg.filtering.TurbulenceNativeParityTest"
     ```

## Tracking Progress
*   **`SvgFeatures.kt`**: Update the supported feature strings returned to `<switch>` elements.

## Common Gotchas
*   **Explicit API mode is ON**: all public declarations (classes, objects, functions, properties, consts) need explicit visibility modifiers and explicit return/property types. Missing ones are compile errors, not warnings.
*   **`public` is NOT needed in `src/test` / `src/androidTest`**.
*   **`Paint.setFontVariationSettings`**: Throws `NoSuchMethodError` in Robolectric; avoid testing complex text layouts in unit tests if they rely on variable fonts.
*   **`stroke-dasharray`**: Requires normalization (doubling the array if length is odd) before it can be used with Android's `DashPathEffect`.
*   **`accumulate="sum"`**: For colors (ARGB), "sum" is ignored per SVG spec.
*   **CSS keyword matching is case-insensitive**: use `equals(KEYWORD, ignoreCase = true)` (or `Locale.US` lowercase tokens) in `parse*` funcs, never `==`/`when(value)`. Exception: `parseFontFeatureSettings` 4-char feature tags stay case-sensitive.

## AI Helper Test Package (`hu.oandras.ksvg.aihelpers`)
Reusable image-diff/diagnostic tests for investigating rendering fidelity live here. Keep them in the codebase so future sessions can reuse them.
- **`AiVisualDiffTest`**: Parameterized per-SVG diff test. It renders each SVG under `test-data/verification/`/`filters/`/`meteocons/`, compares against the matching `*-golden/*.png` (rsvg/browser reference) using `hu.oandras.ksvg.comparisons.GoldenImageUtils.compareWithGolden`, and writes `<name>.out.png`, `<name>.diff.png`, and `summary.txt` (similarity, diffPixels, cornerDiff, meanAbsErr) under `ksvg/test-data/ai-helper/<name>/`.
- Use the library color helpers from `hu.oandras.ksvg.utils.ColorUtils` (`val Int.alpha/red/green/blue`) for pixel math — do not recompute `(p shr 24) and 0xff` inline.
- **CLI filtering**: pass `-PverifyFilter=<substring>` (e.g. `-PverifyFilter=filter_specular`) to run a single SVG across all visual-comparison suites (`VerificationVisualComparisonTest`, `FiltersVisualComparisonTest`, `MeteoconsVisualComparisonTest`, `AiVisualDiffTest`). The value is forwarded to the JVM system property `ksvg.verify.filter` and matched case-sensitively against the SVG file name.
- Example: `./gradlew :ksvg:testDebugUnitTest --tests "hu.oandras.ksvg.aihelpers.AiVisualDiffTest" -PverifyFilter=filter_specular -Dorg.gradle.warning.mode=none`

## Rendering & Native filters

Rendering hot-path rules, the software/GPU filter backend selection (`RenderOptions.softwareFiltering`), JNI/NDK entry rules, and validated native-filtering lessons live in `RENDERING_FILTERING.md` (§2.2, §4–§6) — read it before touching render/filter code.

## Reports

If the user asks for a report, make it in the tmp folder as a Markdown file.

## Work Log

- For non-trivial tasks, maintain a problem-specific Markdown work log (for example, SVG_FILTER_RENDERING.md or ISSUE_142_WORKLOG.md) in `tmp/`.
- Record important findings, attempted approaches, failures, decisions, and next steps. Read it before starting or resuming work, and do not repeat failed approaches unless new evidence justifies them.
- Update the log after each major investigation step or milestone, so the current state can be recovered after interruption.

## Quick Commands
- Always use the Gradle daemon (omit `--no-daemon`).
- Create commits without agent commit signing.
- Build: `./gradlew :ksvg:compileDebugKotlin -Dorg.gradle.warning.mode=none`
- Tests: `./gradlew :ksvg:testDebugUnitTest -Dorg.gradle.warning.mode=none`
- Coverage: `./gradlew :ksvg:jacocoTestReport -Dorg.gradle.warning.mode=none`

### Tooling preferences
- **Prefer IDE functions over shell commands** whenever one exists. Fall back to the terminal only when no IDE tool fits. Use the IDE's import optimization feature to remove unused imports, if possible.
- **Temporary files go inside the project**, in a `tmp/` folder at the repo root (git-ignored), not in system temp directories. Clean it up when done.

### Viewing test `println` / stdout
Test standard output (e.g. `println` debug statements) is suppressed by default. Pass `-PshowTestOutput --console=plain` to surface it:
```bash
./gradlew :ksvg:testDebugUnitTest --tests "hu.oandras.ksvg.aihelpers.AnalyzeComponentTransferTest" -PshowTestOutput --console=plain -Dorg.gradle.warning.mode=none
```


- Use English internally and for all code, comments, documentation, logs, commit messages, and other project artifacts.
- You can answer in English even if the question is in Hungarian.
