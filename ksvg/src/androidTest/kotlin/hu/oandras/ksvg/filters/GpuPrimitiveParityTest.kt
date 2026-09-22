/*
 *    Copyright 2026 András Oravecz <info@oandras.hu>
 *
 *    Licensed under the Apache License, Version 2.0 (the "License");
 *    you may not use this file except in compliance with the License.
 *    You may obtain a copy of the License at
 *
 *        https://www.apache.org/licenses/LICENSE-2.0
 *
 *    Unless required by applicable law or agreed to in writing, software
 *    distributed under the License is distributed on an "AS IS" BASIS,
 *    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *    See the License for the specific language governing permissions and
 *    limitations under the License.
 */

package hu.oandras.ksvg.filters

import android.graphics.Bitmap
import android.os.Build
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Assume.assumeFalse
import org.junit.Assume.assumeTrue
import org.junit.Test
import org.junit.runner.RunWith

/**
 * A-round of the CPU↔GPU filter parity work (`tmp/GPU_PARITY_PLAN_A.md`):
 * one minimal SVG per GPU-supported filter primitive, rendered both on the
 * software backend and on a hardware canvas, compared with [assertParity].
 *
 * Conventions:
 * - Every corpus SVG marks the filtered element with `filter="url(#f)"`; the
 *   unfiltered baseline for the vacuous-pass guard is derived by stripping it.
 * - `minGpuApi` documents the API level from which the primitive takes the
 *   GPU path (Impl31 = 31, Impl33 = 33). Below it the HW side silently falls
 *   back to software, so the parity assert passes trivially.
 * - `feImage` is intentionally absent: no GPU backend supports it (never in
 *   the supported mask) — it belongs to the round-B fallback tests.
 */
@RunWith(AndroidJUnit4::class)
class GpuPrimitiveParityTest {

    @Test
    fun gaussianBlur() {
        checkParity(
            name = "feGaussianBlur",
            minGpuApi = 31,
            svg = filteredSvg("""<feGaussianBlur stdDeviation="4"/>"""),
            // Skia's GPU blur kernel is an approximation: edges match past the
            // radius mapping, but corner zones differ structurally (maxAbs 11
            // measured, wider on Adreno). Tight mean/count gates still catch
            // regressions.
            maxAbsTol = 14,
            maxOutlierRatio = 0.006,
        )
    }

    @Test
    fun gaussianBlurSmallSigma() {
        // Second operating point for the Skia blur-radius mapping
        // (skiaBlurRadiusForSigma): guards against overfitting to σ=4, since
        // Skia's approximate kernel need not scale linearly.
        checkParity(
            name = "feGaussianBlurSmall",
            minGpuApi = 31,
            svg = filteredSvg("""<feGaussianBlur stdDeviation="1.5"/>"""),
            // Steep small-sigma edges amplify residual calibration error.
            maxAbsTol = 8,
            maxOutlierRatio = 0.002,
        )
    }

    @Test
    fun gaussianBlurTinySigma() {
        // Low end of the blur-radius mapping table.
        checkParity(
            name = "feGaussianBlurTiny",
            minGpuApi = 31,
            svg = filteredSvg("""<feGaussianBlur stdDeviation="1"/>"""),
            maxAbsTol = 6,
            maxOutlierRatio = 0.001,
        )
    }

    @Test
    fun offset() {
        checkParity(
            name = "feOffset",
            minGpuApi = 31,
            svg = filteredSvg("""<feOffset dx="24" dy="-12"/>"""),
        )
    }

    @Test
    fun colorMatrix() {
        checkParity(
            name = "feColorMatrix",
            minGpuApi = 31,
            svg = filteredSvg("""<feColorMatrix type="saturate" values="0"/>"""),
        )
    }

    @Test
    fun morphology() {
        checkParity(
            name = "feMorphology",
            minGpuApi = 33,
            svg = filteredSvg("""<feMorphology operator="erode" radius="3"/>"""),
            // Adreno exact-boundary pixels on the erode interior edge
            // (device col 205 = clip arithmetic landing on integers): the
            // shader samples out-of-bounds there (undefined values) where
            // the CPU clamps/keeps transparent. Same driver-boundary class
            // as the §8 fringe cases (4-px period, deterministic).
            ignoreBoundaryFringe = true,
        )
    }

    @Test
    fun diffuseLighting() {
        checkParity(
            name = "feDiffuseLighting",
            minGpuApi = 33,
            svg = filteredSvg(
                """
                <feDiffuseLighting surfaceScale="2" lighting-color="#ffffff">
                  <feDistantLight azimuth="45" elevation="60"/>
                </feDiffuseLighting>
                """.trimIndent(),
            ),
            ignoreBoundaryFringe = true,
        )
    }

    @Test
    fun specularLighting() {
        // x86_64 emulator's native lighting kernel ignores the terminal
        // premultiplied-output flag (emits straight non-EOTF output), so the
        // software reference is meaningless here — same broken-native family
        // as turbulence/displacement (see report §5). Physical ARM64 runs it.
        assumeFalse(
            "x86_64 emulator: native specular-terminal flag ignored (see report §5)",
            Build.SUPPORTED_ABIS.any { it.startsWith("x86") },
        )
        checkParity(
            name = "feSpecularLighting",
            minGpuApi = 33,
            svg = filteredSvg(
                """
                <feSpecularLighting surfaceScale="2" specularConstant="1" specularExponent="8" lighting-color="#ffffff">
                  <feDistantLight azimuth="45" elevation="60"/>
                </feSpecularLighting>
                """.trimIndent(),
            ),
            ignoreBoundaryFringe = true,
        )
    }

    @Test
    fun componentTransfer() {
        checkParity(
            name = "feComponentTransfer",
            minGpuApi = 33,
            svg = filteredSvg(
                """<feComponentTransfer><feFuncR type="table" tableValues="1 0"/></feComponentTransfer>""",
            ),
        )
    }

    @Test
    fun convolveMatrix() {
        checkParity(
            name = "feConvolveMatrix",
            minGpuApi = 33,
            svg = filteredSvg(
                """<feConvolveMatrix order="3" kernelMatrix="0 -1 0 -1 5 -1 0 -1 0"/>""",
            ),
        )
    }

    @Test
    fun displacementMap() {
        // The software reference of this case SIGILL-crashes inside the x86_64
        // :filtering native displacement kernel on emulators (tombstone:
        // ILL_ILLOPN in DisplacementMapNative_apply) — a native-dispatch issue,
        // not a GPU one. Physical ARM64 covers this case; skip on x86 emulators
        // so one crashing case cannot abort the whole suite (process death).
        assumeFalse(
            "x86_64 emulator: native displacement kernel SIGILL (see report §5)",
            Build.SUPPORTED_ABIS.any { it.startsWith("x86") },
        )
        checkParity(
            name = "feDisplacementMap",
            minGpuApi = 33,
            svg = filteredSvg(
                // NOTE: in2 is a constant flood (not turbulence) so this case stays
                // independent of feTurbulence parity; the constant map gives a
                // uniform ~11px translation, exercising scale/channel selection.
                """
                <feFlood flood-color="#2020c0" result="n"/>
                <feDisplacementMap in="SourceGraphic" in2="n" scale="30" xChannelSelector="R" yChannelSelector="G"/>
                """.trimIndent(),
            ),
        )
    }

    @Test
    fun turbulence() {
        checkParity(
            name = "feTurbulence",
            minGpuApi = 33,
            svg = filteredSvg(
                // NOTE: explicit positive seed. Seed 0 exercises the native
                // seed-normalization path (see report §5); parity at seed 0 is
                // tracked separately once the native normalization matches.
                // The SVG geometry must stay in sync with the golden asset
                // (generated host-side from the pure-Kotlin reference, see
                // TempTurbDumpTest in :filtering).
                """<feTurbulence type="fractalNoise" baseFrequency="0.05" numOctaves="2" seed="8"/>""",
            ),
            // Golden reference (not device software: the native turbulence
            // kernel diverges from the reference on emulator x86_64 and
            // slightly on ARM64, so the on-device SW bitmap is untrusted).
            // GPU-vs-reference residual is fp32 + 8-bit gradient packing.
            goldenAsset = "parity/turb_seed8.png",
            maxAbsTol = 4,
            maxOutlierRatio = 0.005,
            ignoreBoundaryFringe = true,
        )
    }

    @Test
    fun blend() {
        checkParity(
            name = "feBlend",
            minGpuApi = 33,
            svg = filteredSvg(
                """
                <feFlood flood-color="#2020c0" result="b"/>
                <feBlend in="SourceGraphic" in2="b" mode="multiply"/>
                """.trimIndent(),
            ),
            ignoreBoundaryFringe = true,
        )
    }

    @Test
    fun composite() {
        checkParity(
            name = "feComposite",
            minGpuApi = 33,
            svg = filteredSvg(
                """
                <feFlood flood-color="#2020c0" result="c"/>
                <feComposite in="SourceGraphic" in2="c" operator="over"/>
                """.trimIndent(),
            ),
            ignoreBoundaryFringe = true,
        )
    }

    @Test
    fun flood() {
        checkParity(
            name = "feFlood",
            minGpuApi = 33,
            svg = filteredSvg("""<feFlood flood-color="#20a020"/>"""),
            ignoreBoundaryFringe = true,
        )
    }

    @Test
    fun merge() {
        checkParity(
            name = "feMerge",
            minGpuApi = 33,
            svg = filteredSvg(
                """
                <feFlood flood-color="#2020c0" result="m"/>
                <feMerge><feMergeNode in="m"/><feMergeNode in="SourceGraphic"/></feMerge>
                """.trimIndent(),
            ),
            ignoreBoundaryFringe = true,
        )
    }

    @Test
    fun tile() {
        checkParity(
            name = "feTile",
            minGpuApi = 33,
            svg = filteredSvg(
                """
                <feFlood flood-color="#20a020" result="t"/>
                <feTile in="t"/>
                """.trimIndent(),
            ),
            ignoreBoundaryFringe = true,
        )
    }

    @Test
    fun dropShadow() {
        checkParity(
            name = "feDropShadow",
            minGpuApi = 33,
            svg = filteredSvg(
                """<feDropShadow dx="10" dy="10" stdDeviation="4" flood-color="#000000" flood-opacity="0.8"/>""",
            ),
        )
    }

    private fun checkParity(
        name: String,
        minGpuApi: Int,
        svg: String,
        maxAbsTol: Int = GPU_PARITY_MAX_ABS,
        maxOutlierRatio: Double = GPU_PARITY_MAX_OUTLIER_RATIO,
        // See assertParity: Adreno-only boundary-fringe accommodation.
        // Enable ONLY where the driver quirk is proven (region-filling
        // primitives); never for edge-band cases (blur/displacement), where
        // fringe-adjacent diffs carry real signal.
        ignoreBoundaryFringe: Boolean = false,
        // Golden-asset path for cases where the on-device software reference
        // is itself untrusted (divergent native kernel): compare the hardware
        // render against the asset instead of the software render. The SW
        // render still runs for the visible-effect guard.
        goldenAsset: String? = null,
    ) {
        assumeTrue(
            "GpuParityHarness needs API 29+ (HardwareRenderer)",
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q,
        )
        val sw = renderSoftware(svg)
        assertVisibleFilterEffect(name, sw, renderSoftware(unfilteredBaseline(svg)))
        val hw = renderOnHardware(svg)
        val reference = if (goldenAsset != null) {
            loadGoldenAsset(
                goldenAsset,
                Bitmap.createBitmap(GPU_PARITY_SIZE, GPU_PARITY_SIZE, Bitmap.Config.ARGB_8888),
            )
        } else {
            sw
        }
        assertParity(
            "$name (minGpuApi=$minGpuApi, deviceApi=${Build.VERSION.SDK_INT})",
            reference,
            hw,
            maxAbsTol,
            maxOutlierRatio,
            ignoreBoundaryFringe,
        )
    }

    private fun filteredSvg(primitives: String): String {
        return """
            <svg xmlns="http://www.w3.org/2000/svg" width="256" height="256">
              <defs>
                <filter id="f">
                  $primitives
                </filter>
              </defs>
              <rect x="48" y="48" width="160" height="160" fill="#c83232" filter="url(#f)"/>
            </svg>
        """.trimIndent()
    }

    private fun unfilteredBaseline(svg: String): String {
        val baseline = svg.replace(""" filter="url(#f)"""", "")
        check(baseline != svg) { "Corpus SVG must contain filter=\"url(#f)\"" }
        return baseline
    }
}
