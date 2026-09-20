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
import hu.oandras.ksvg.filtering.MorphologyValidationCorpus
import hu.oandras.ksvg.filtering.parity.MorphologyParitySvg
import hu.oandras.ksvg.filters.GpuMorphologyCorpusParityTest.Companion.CURATED
import org.junit.Assume.assumeTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.Parameterized

/**
 * Round-B pilot (`tmp/GPU_PARITY_PLAN_B.md` §5.1-5.2): corpus-driven
 * single-primitive coverage for `feMorphology`.
 *
 * Each [MorphologyValidationCorpus.Case] becomes an SVG via
 * [MorphologyParitySvg] (input pixels travel as a PNG data-URI `<image>`)
 * and is measured SW-vs-HW with the round-A gates ([assertParity] strict,
 * [assertVisibleFilterEffect] against the unfiltered baseline).
 *
 * Quantity control (plan §4): the PR gate runs the curated [CURATED] edge
 * representatives; `-e gpu_parity_full true` runs the whole corpus
 * (nightly); `-e gpu_parity_filter <substring>` selects by case name.
 * (Underscore keys: dots break `am instrument -e` parsing.)
 */
@RunWith(Parameterized::class)
class GpuMorphologyCorpusParityTest(
    private val caseName: String,
    private val case: MorphologyValidationCorpus.Case,
) {

    @Test
    fun morphologyCorpusParity() {
        assumeTrue(
            "GpuParityHarness needs API 29+ (HardwareRenderer)",
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q,
        )
        val svg = MorphologyParitySvg.toSvg(
            case,
            imageSource(opaqueInput(case.input), case.width, case.height),
        )
        val name = "morphology:$caseName"
        val sw = renderSoftware(svg, case.width, case.height)
        assertVisibleFilterEffect(name, sw, renderSoftware(corpusBaseline(svg), case.width, case.height))
        val hw = renderOnHardware(svg, case.width, case.height)
        assertParity(
            name = "$name (minGpuApi=33, deviceApi=${Build.VERSION.SDK_INT})",
            sw = sw,
            hw = hw,
            // Corpus inputs carry translucent pixels: the software backend
            // emits straight pixels while the hardware chain emits
            // premultiplied ones (identical compositing, different raw
            // bytes) — compare in premultiplied space (see assertParity).
            premultiplyReference = true,
        )
    }

    companion object {
        private val CURATED = setOf(
            "erode 1x1 16x16",
            "dilate 1x1 16x16",
            "erode 3x1 32x8",
            "dilate 3x1 32x8",
            "erode 10x10 5x5",
            "dilate 10x10 5x5",
            "erode 2x2 subclip 32x32",
            "dilate 2x2 subclip 32x32",
            "erode 1x1 tail 17 x 1",
            "dilate 1x1 tail 33 x 1",
        )

        @JvmStatic
        @Parameterized.Parameters(name = "{0}")
        fun data(): List<Array<Any?>> {
            val args = InstrumentationRegistry.getArguments()
            val nameFilter: String? = args.getString("gpu_parity_filter")
            val cases = when {
                !nameFilter.isNullOrBlank() -> MorphologyValidationCorpus.cases.filter {
                    it.name.contains(nameFilter)
                }
                args.getString("gpu_parity_full") == "true" -> MorphologyValidationCorpus.cases
                else -> MorphologyValidationCorpus.cases.filter { it.name in CURATED }
            }
            // Single-pixel images are excluded: dilate is the identity on them
            // (window == the pixel itself), so the SW-vs-HW comparison would
            // be vacuously green on ANY backend — a parity test that cannot
            // fail is worse than none. (Erode blanks them via the empty
            // interior rule, but that path is already covered by the
            // radius-exceeds-image cases.) The corpus classes themselves stay
            // untouched (plan §4); this only scopes the GPU runner.
            val sized = cases.filter { it.width * it.height > 1 }
            check(sized.isNotEmpty()) {
                "GpuMorphologyCorpusParityTest: no cases selected " +
                    "(filter=$nameFilter, curated=${CURATED.size}, corpus=${MorphologyValidationCorpus.cases.size})"
            }
            return sized.map { arrayOf(it.name, it) }
        }
    }
}
