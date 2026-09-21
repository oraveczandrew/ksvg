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
import androidx.test.platform.app.InstrumentationRegistry
import hu.oandras.ksvg.filtering.TurbulenceValidationCorpus
import hu.oandras.ksvg.filtering.UnLinearizeValidationCorpus
import hu.oandras.ksvg.filtering.parity.TurbulenceParitySvg
import org.junit.Assume
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.Parameterized

/**
 * Round-B corpus coverage for `feTurbulence`
 * (`tmp/GPU_PARITY_PLAN_B.md` §2): each
 * [TurbulenceValidationCorpus.Case] becomes an SVG via
 * [TurbulenceParitySvg] and is measured on HW.
 *
 * Reference strategy (NOT device-SW): the on-device software bitmap itself
 * round-trips straight turbulence output through premultiplied `Bitmap`
 * storage, which is lossy at low alpha — so non-stitch cases compare HW
 * against host-generated goldens (`parity/turbulence/` PNGs, pure-Kotlin
 * reference + terminal UN_LINEARIZE, Round-A turb_seed8 precedent).
 * The SW render only feeds the vacuous-pass guard.
 *
 * Comparison space: straight bytes with the alpha-scaled quantization bound
 * (`translucentQuantK = 510`). `type=turbulence` alpha is abs-noise with most
 * pixels near zero, where straight RGB is unrepresentable through premultiplied
 * 8-bit storage (at alpha 1 only {0, 255} survive): the GPU chain, the software
 * `Bitmap` round-trips, and the `ImageReader` readback each keep an equally
 * valid but byte-different survivor. The kernels themselves are proven exact
 * (native `TurbulenceNative` bit-matches Kotlin on-device; the AGSL shader
 * matches the golden within fp noise wherever alpha makes values observable).
 * The bound stays tight at opaque pixels, so real kernel regressions (wrong
 * lattice/accumulation/EOTF) still fail there.
 *
 * Stitch cases (`periodX/Y != 0`): the GPU chain declines (no stitch
 * support — `uTilePeriod` hardcodes no-stitch), so the hardware side
 * falls back to software. These assert HW==SW under the same bound: both
 * sides run the same deterministic native kernel, so agreement proves the
 * fallback instead of passing vacuously (a taken GPU path would compute a
 * non-stitched field and diverge hugely, far outside the bound).
 */
@RunWith(Parameterized::class)
class GpuTurbulenceCorpusParityTest(
    private val caseName: String,
    private val case: TurbulenceValidationCorpus.Case,
) {

    @Test
    fun turbulenceCorpusParity() {
        Assume.assumeTrue(
            "GpuParityHarness needs API 29+ (HardwareRenderer)",
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q,
        )
        // Turbulence ignores its source (generative primitive): any image
        // works as the filtered element (keeps the baseline-derivation
        // convention uniform across runners).
        val placeholder = UnLinearizeValidationCorpus.fixedSeedRandom(case.width * case.height)
        val svg = TurbulenceParitySvg.toSvg(
            case,
            imageSource(placeholder, case.width, case.height),
        )
        val name = "turbulence:$caseName"
        val sw = renderSoftware(svg, case.width, case.height)
        assertVisibleFilterEffect(name, sw, renderSoftware(corpusBaseline(svg), case.width, case.height))
        val hw = renderOnHardware(svg, case.width, case.height)
        if (case.periodX == 0 && case.periodY == 0) {
            val golden = loadGoldenAsset(
                "parity/turbulence/" + caseName.replace(Regex("[^A-Za-z0-9]+"), "_") + ".png",
                Bitmap.createBitmap(case.width, case.height, Bitmap.Config.ARGB_8888),
            )
            assertParity(
                "$name (minGpuApi=33, deviceApi=${Build.VERSION.SDK_INT})",
                golden,
                hw,
                // Round-A turbulence gates (fp32 + 8-bit gradient packing).
                maxAbsTol = 4,
                maxOutlierRatio = 0.005,
                ignoreBoundaryFringe = true,
                // Straight-space comparison with the alpha-scaled
                // quantization bound (see class kdoc): premultiplying the
                // reference would crush all low-alpha signal to ~0 and pass
                // vacuously there, while straight comparison keeps the
                // observable pixels tight.
                translucentQuantK = 510,
            )
        } else {
            // Stitch fallback: both sides run the same deterministic
            // native kernel, so agreement proves the fallback (a taken GPU
            // path would compute a non-stitched field and diverge hugely,
            // far outside the quantization bound).
            assertParity(
                "$name (fallback, minGpuApi=33, deviceApi=${Build.VERSION.SDK_INT})",
                sw,
                hw,
                maxAbsTol = 4,
                translucentQuantK = 510,
                // Premultiplied-space comparison: HW fallback output is
                // premultiplied SW bytes (straight RGB unrepresentable at
                // low alpha); validated 0 bad / 0 outliers offline.
                premultiplyReference = true,
            )
        }
    }

    companion object {
        @JvmStatic
        @Parameterized.Parameters(name = "{0}")
        fun data(): List<Array<Any?>> {
            // Full corpus (11 cases): stitch takes the fallback branch.
            val nameFilter: String? = InstrumentationRegistry.getArguments()
                .getString("gpu_parity_filter")
            val cases = if (nameFilter.isNullOrBlank()) {
                TurbulenceValidationCorpus.cases
            } else {
                TurbulenceValidationCorpus.cases.filter { it.name.contains(nameFilter) }
            }
            check(cases.isNotEmpty()) {
                "GpuTurbulenceCorpusParityTest: no cases selected " +
                    "(filter=$nameFilter, corpus=${TurbulenceValidationCorpus.cases.size})"
            }
            return cases.map { arrayOf(it.name, it) }
        }
    }
}
