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
import hu.oandras.ksvg.filtering.ArithmeticCompositeValidationCorpus
import hu.oandras.ksvg.filtering.parity.ArithmeticCompositeParitySvg
import org.junit.Assume.assumeTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.Parameterized

/**
 * Round-B corpus coverage for `feComposite operator="arithmetic"`
 * (`tmp/GPU_PARITY_PLAN_B.md` §2): each
 * [ArithmeticCompositeValidationCorpus.Case] becomes an SVG via
 * [ArithmeticCompositeParitySvg] (`input1` as PNG data-URI `<image>`,
 * `input2` adapted to a constant `feFlood`, alpha pinned opaque — see
 * `opaqueInput`).
 *
 * Reference strategy (NOT device-SW): the on-device native
 * `arithmeticComposite` kernel is nondeterministic in `useLinear`
 * (identical calls flip between linear/sRGB math run-to-run —
 * `GPU_ROUNDB_ARITH_WORKLOG.md`), so no pixel assert may use it.
 * All cases compare HW against host-generated goldens
 * (`parity/arithmetic/\*.png`, pure-Kotlin reference, sRGB + linear —
 * F9 generated the linear set with the validated sRGB recipe).
 * with `premultiplyReference` (arithmetic output is
 * premultiplied, like morphology). The SW render only feeds the
 * vacuous-pass guard (robust: any native behavior differs hugely from
 * unfiltered noise).
 */
@RunWith(Parameterized::class)
class GpuArithmeticCompositeCorpusParityTest(
    private val caseName: String,
    private val case: ArithmeticCompositeValidationCorpus.Case,
) {

    @Test
    fun arithmeticCompositeCorpusParity() {
        assumeTrue(
            "GpuParityHarness needs API 29+ (HardwareRenderer)",
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q,
        )
        val svg = ArithmeticCompositeParitySvg.toSvg(
            case,
            imageSource(opaqueInput(case.input1), case.width, case.height),
        )
        val name = "arithmeticComposite:$caseName"
        val sw = renderSoftware(svg, case.width, case.height)
        assertVisibleFilterEffect(name, sw, renderSoftware(corpusBaseline(svg), case.width, case.height))
        val hw = renderOnHardware(svg, case.width, case.height)
        val golden = loadGoldenAsset(
            "parity/arithmetic/" + caseName.replace(Regex("[^A-Za-z0-9]+"), "_") + ".png",
            Bitmap.createBitmap(case.width, case.height, Bitmap.Config.ARGB_8888),
        )
        if (isAllTransparent(golden)) {
            // Fully transparent output (e.g., sub with opaque inputs:
            // alpha-out is zero everywhere): assert the HW output is
            // transparent too via alpha-only comparison. RGB under
            // alpha-zero is invisible and legitimately differs
            // (straight residue vs. premultiplied zero).
            assertParity(
                "$name (minGpuApi=33, deviceApi=${Build.VERSION.SDK_INT})",
                alphaOnlyCopy(golden),
                alphaOnlyCopy(hw),
                maxAbsTol = 2,
            )
        } else {
            assertParity(
                "$name (minGpuApi=33, deviceApi=${Build.VERSION.SDK_INT})",
                golden,
                hw,
                premultiplyReference = true,
                ignoreTransparent = true,
            )
        }
    }

    companion object {
        @JvmStatic
        @Parameterized.Parameters(name = "{0}")
        fun data(): List<Array<Any?>> {
            // Small corpus (10 cases): the PR gate runs all of them.
            val nameFilter: String? = InstrumentationRegistry.getArguments()
                .getString("gpu_parity_filter")
            val cases = if (nameFilter.isNullOrBlank()) {
                ArithmeticCompositeValidationCorpus.cases
            } else {
                ArithmeticCompositeValidationCorpus.cases.filter { it.name.contains(nameFilter) }
            }
            check(cases.isNotEmpty()) {
                "GpuArithmeticCompositeCorpusParityTest: no cases selected " +
                    "(filter=$nameFilter, corpus=${ArithmeticCompositeValidationCorpus.cases.size})"
            }
            return cases.map { arrayOf(it.name, it) }
        }

        private fun isAllTransparent(bitmap: Bitmap): Boolean {
            val px = IntArray(bitmap.width * bitmap.height)
            bitmap.getPixels(px, 0, bitmap.width, 0, 0, bitmap.width, bitmap.height)
            return px.all { (it ushr 24) == 0 }
        }
    }
}
