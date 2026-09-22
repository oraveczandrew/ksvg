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
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import hu.oandras.ksvg.filtering.ComponentTransferValidationCorpus
import hu.oandras.ksvg.filtering.parity.ComponentTransferParitySvg
import org.junit.Assume.assumeTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.Parameterized

/**
 * Round-B corpus coverage for `feComponentTransfer`
 * (`tmp/GPU_PARITY_PLAN_B.md` §2): each
 * [ComponentTransferValidationCorpus.Case] becomes an SVG via
 * [ComponentTransferParitySvg] (baked tables as `type="table"`, input
 * pixels as PNG data-URI `<image>` with alpha pinned opaque — see
 * `opaqueInput`) and is measured SW-vs-HW with strict gates plus
 * `premultiplyReference` (LUT output is premultiplied, like morphology).
 */
@RunWith(Parameterized::class)
class GpuComponentTransferCorpusParityTest(
    private val caseName: String,
    private val case: ComponentTransferValidationCorpus.Case,
) {

    @Test
    fun componentTransferCorpusParity() {
        assumeTrue(
            "GpuParityHarness needs API 29+ (HardwareRenderer)",
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q,
        )
        val svg = ComponentTransferParitySvg.toSvg(
            case,
            imageSource(opaqueInput(case.input), case.width, case.height),
        )
        val name = "componentTransfer:$caseName"
        val sw = renderSoftware(svg, case.width, case.height)
        assertVisibleFilterEffect(name, sw, renderSoftware(corpusBaseline(svg), case.width, case.height))
        val hw = renderOnHardware(svg, case.width, case.height)
        // Single-row images are bilinear-sensitive: the content row has
        // transparent padding on both vertical sides, so any sub-texel
        // pipeline offset (or Adreno dither) blends the corner pixels.
        // Measured: one corner pixel at 3 LSB on several tails, stable
        // across runs; everything else strict-green. The ratio slack covers
        // that single pixel on tiny images (1/63 = 1.6%).
        val singleRow = case.height == 1
        assertParity(
            name = "$name (minGpuApi=33, deviceApi=${Build.VERSION.SDK_INT})",
            sw = sw,
            hw = hw,
            maxAbsTol = if (singleRow) 4 else GPU_PARITY_MAX_ABS,
            maxOutlierRatio = if (singleRow) 0.05 else GPU_PARITY_MAX_OUTLIER_RATIO,
            premultiplyReference = true,
        )
    }

    companion object {
        private val CURATED = setOf(
            "full 32 x 8",
            "full 33 x 9",
            "subclip 32x32",
            "clip top-left 16x16",
            "clip bottom-right 16x16",
            "tail 17 x 1",
            "tail 65 x 1",
            "tail 1 x 1",
        )

        @JvmStatic
        @Parameterized.Parameters(name = "{0}")
        fun data(): List<Array<Any?>> {
            val args = InstrumentationRegistry.getArguments()
            val nameFilter: String? = args.getString("gpu_parity_filter")
            val cases = when {
                !nameFilter.isNullOrBlank() -> ComponentTransferValidationCorpus.cases.filter {
                    it.name.contains(nameFilter)
                }
                args.getString("gpu_parity_full") == "true" -> ComponentTransferValidationCorpus.cases
                else -> ComponentTransferValidationCorpus.cases.filter { it.name in CURATED }
            }
            check(cases.isNotEmpty()) {
                "GpuComponentTransferCorpusParityTest: no cases selected " +
                    "(filter=$nameFilter, curated=${CURATED.size}, corpus=${ComponentTransferValidationCorpus.cases.size})"
            }
            return cases.map { arrayOf(it.name, it) }
        }
    }
}

/**
 * Func-level coverage the baked-table corpus cannot give (plan §6.1):
 * `discrete`/`linear`/`gamma` exercise the LUT *construction* paths
 * (`buildTransferLutTables`) on both backends, where the corpus only
 * exercises table *lookup*. (`identity` needs no test: passthrough.)
 */
@RunWith(AndroidJUnit4::class)
class GpuComponentTransferFuncParityTest {

    @Test
    fun discrete() {
        checkFuncParity(
            "discrete",
            """<feFuncR type="discrete" tableValues="0 0.25 0.5 0.75 1"/>""" +
                """<feFuncG type="discrete" tableValues="1 0.75 0.5 0.25 0"/>""",
        )
    }

    @Test
    fun linear() {
        checkFuncParity(
            "linear",
            """<feFuncR type="linear" slope="1.5" intercept="-0.1"/>""" +
                """<feFuncB type="linear" slope="0.5" intercept="0.2"/>""",
        )
    }

    @Test
    fun gamma() {
        checkFuncParity(
            "gamma",
            """<feFuncR type="gamma" amplitude="1" exponent="2" offset="0"/>""" +
                """<feFuncG type="gamma" amplitude="1" exponent="0.5" offset="0.1"/>""",
        )
    }

    private fun checkFuncParity(name: String, functions: String) {
        assumeTrue(
            "GpuParityHarness needs API 29+ (HardwareRenderer)",
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q,
        )
        // Deterministic opaque noise (alpha pinned: same representation
        // rationale as `opaqueInput` — straight==premult, lossless PNG).
        var state = 0x9E3779B9.toInt()
        val input = IntArray(16 * 16) {
            state = state * 1664525 + 1013904223
            val r = (state ushr 16) and 0xFF
            val g = (state ushr 8) and 0xFF
            val b = state and 0xFF
            (-0x1000000) or (r shl 16) or (g shl 8) or b
        }
        val uri = imageSource(input, 16, 16)
        val svg = "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"16\" height=\"16\">" +
            "<defs>" +
            "<filter id=\"f\" filterUnits=\"userSpaceOnUse\" x=\"0\" y=\"0\" width=\"16\" height=\"16\">" +
            "<feComponentTransfer color-interpolation-filters=\"sRGB\">$functions</feComponentTransfer>" +
            "</filter>" +
            "</defs>" +
            "<image href=\"$uri\" x=\"0\" y=\"0\" width=\"16\" height=\"16\" filter=\"url(#f)\"/>" +
            "</svg>"
        val fullName = "componentTransferFunc:$name"
        val sw = renderSoftware(svg, 16, 16)
        assertVisibleFilterEffect(fullName, sw, renderSoftware(corpusBaseline(svg), 16, 16))
        val hw = renderOnHardware(svg, 16, 16)
        assertParity(
            name = "$fullName (minGpuApi=33, deviceApi=${Build.VERSION.SDK_INT})",
            sw = sw,
            hw = hw,
            premultiplyReference = true,
        )
    }
}
