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

import android.os.Build
import androidx.test.platform.app.InstrumentationRegistry
import hu.oandras.ksvg.filtering.ConvolveValidationCorpus
import hu.oandras.ksvg.filtering.parity.ConvolveParitySvg
import org.junit.Assume
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.Parameterized

/**
 * Round-B corpus coverage for `feConvolveMatrix` (`tmp/GPU_PARITY_PLAN_B.md`
 * §2): each [ConvolveValidationCorpus.Case] becomes an SVG via
 * [ConvolveParitySvg] (input pixels travel as a PNG data-URI `<image>`,
 * alpha pinned opaque — see `opaqueInput`) and is measured SW-vs-HW.
 *
 * Two assertion modes:
 * - duplicate edge mode: strict [assertParity] (the GPU implements clamp
 *   sampling, matching the CPU `duplicate` path).
 * - wrap/none edge modes: the GPU chain declines (`buildConvolveMatrixShader`
 *   returns null — clamp sampling would silently compute wrong edges), so
 *   the hardware side falls back to software. These assert bit-exact
 *   HW==SW ([assertParity] with zero tolerances): if the GPU ever took the
 *   path, clamp-vs-wrap/none would diverge hugely on noise, so equality
 *   proves the fallback instead of passing vacuously.
 */
@RunWith(Parameterized::class)
class GpuConvolveCorpusParityTest(
    private val caseName: String,
    private val case: ConvolveValidationCorpus.Case,
) {

    @Test
    fun convolveCorpusParity() {
        Assume.assumeTrue(
            "GpuParityHarness needs API 29+ (HardwareRenderer)",
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q,
        )
        val svg = ConvolveParitySvg.toSvg(
            case,
            imageSource(opaqueInput(case.input), case.width, case.height),
        )
        val name = "convolve:$caseName"
        val sw = renderSoftware(svg, case.width, case.height)
        assertVisibleFilterEffect(name, sw, renderSoftware(corpusBaseline(svg), case.width, case.height))
        val hw = renderOnHardware(svg, case.width, case.height)
        if (case.edgeMode == 0) {
            assertParity(
                "$name (minGpuApi=33, deviceApi=${Build.VERSION.SDK_INT})",
                sw,
                hw,
                // Same representation rationale as the morphology runner:
                // corpus pipeline ends straight on SW, premultiplied on HW.
                premultiplyReference = true,
            )
        } else {
            assertParity(
                "$name (fallback, minGpuApi=33, deviceApi=${Build.VERSION.SDK_INT})",
                sw,
                hw,
                maxAbsTol = 0,
                maxOutlierRatio = 0.0,
            )
        }
    }

    companion object {
        @JvmStatic
        @Parameterized.Parameters(name = "{0}")
        fun data(): List<Array<Any?>> {
            // Small corpus (9 cases): the PR gate runs all of them;
            // `gpu_parity_filter` still selects by name. (`gpu_parity_full`
            // is accepted for uniformity with the other corpus runners.)
            val nameFilter: String? = InstrumentationRegistry.getArguments()
                .getString("gpu_parity_filter")
            val cases = if (nameFilter.isNullOrBlank()) {
                ConvolveValidationCorpus.cases
            } else {
                ConvolveValidationCorpus.cases.filter { it.name.contains(nameFilter) }
            }
            check(cases.isNotEmpty()) {
                "GpuConvolveCorpusParityTest: no cases selected " +
                    "(filter=$nameFilter, corpus=${ConvolveValidationCorpus.cases.size})"
            }
            return cases.map { arrayOf(it.name, it) }
        }
    }
}
