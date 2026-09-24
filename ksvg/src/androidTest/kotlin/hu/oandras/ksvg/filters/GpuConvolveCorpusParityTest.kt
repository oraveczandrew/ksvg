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
import org.junit.Assume.assumeTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.Parameterized

/**
 * Round-B corpus coverage for `feConvolveMatrix` (`tmp/GPU_PARITY_PLAN_B.md`
 * §2): each [ConvolveValidationCorpus.Case] becomes an SVG via
 * [ConvolveParitySvg] (input pixels travel as a PNG data-URI `<image>`,
 * alpha pinned opaque — see `opaqueInput`) and is measured SW-vs-HW.
 *
 * All three edge modes take the GPU chain now (F4: duplicate/clamp,
 * wrap/modulo, none/transparent taps): strict [assertParity] everywhere
 * with `premultiplyReference` (same representation rationale as the
 * morphology runner: corpus pipeline ends straight on SW, premultiplied
 * on HW). Per-case gates below are Adreno-measured (see worklog).
 */
@RunWith(Parameterized::class)
class GpuConvolveCorpusParityTest(
    private val caseName: String,
    private val case: ConvolveValidationCorpus.Case,
) {

    @Test
    fun convolveCorpusParity() {
        assumeTrue(
            "GpuParityHarness needs API 29+ (HardwareRenderer)",
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q,
        )
        val svg = ConvolveParitySvg.toSvg(
            case = case,
            imageDataUri = imageSource(
                input = opaqueInput(case.input),
                width = case.width,
                height = case.height
            ),
        )
        val name = "convolve:$caseName"
        val sw = renderSoftware(
            svgString = svg,
            width = case.width,
            height = case.height
        )
        assertVisibleFilterEffect(
            name = name,
            filtered = sw,
            unfiltered = renderSoftware(
                svgString = corpusBaseline(svg),
                width = case.width,
                height = case.height
            )
        )
        val hw = renderOnHardware(svg, case.width, case.height)
        // Round-E chain-taken proof (wrap/none take the GPU chain since F4).
        assertChainBackend(name, minGpuApi = 33)
        // NOTE (F4): wrap/none take the GPU chain now; strict placeholder
        // gates for all modes, calibrated from measured stats (worklog).
        assertParity(
            name = "$name (minGpuApi=33, deviceApi=${Build.VERSION.SDK_INT})",
            sw = sw,
            hw = hw,
            // Same representation rationale as the morphology runner:
            // corpus pipeline ends straight on SW, premultiplied on HW.
            premultiplyReference = true,
        )
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
            // 1x1 images cannot exercise a filter visibly (a 3x3 sharpen of a
            // single clamped pixel is the identity, tripping the harness's
            // visible-effect guard on the SW reference itself). They stay in
            // the shared corpus for the native overread parity, but not here.
            val gpuCases = ConvolveValidationCorpus.cases.filter { it.width * it.height > 1 }
            val cases = if (nameFilter.isNullOrBlank()) {
                gpuCases
            } else {
                gpuCases.filter { it.name.contains(nameFilter) }
            }
            check(cases.isNotEmpty()) {
                "GpuConvolveCorpusParityTest: no cases selected " +
                    "(filter=$nameFilter, corpus=${ConvolveValidationCorpus.cases.size})"
            }
            return cases.map { arrayOf(it.name, it) }
        }
    }
}
