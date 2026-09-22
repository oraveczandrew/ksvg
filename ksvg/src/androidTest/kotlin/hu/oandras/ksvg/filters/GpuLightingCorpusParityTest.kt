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
import hu.oandras.ksvg.filtering.LightingValidationCorpus
import hu.oandras.ksvg.filtering.parity.LightingParitySvg
import org.junit.Assume
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.Parameterized

/**
 * Round-B corpus coverage for `feDiffuseLighting`/`feSpecularLighting`
 * (`tmp/GPU_PARITY_PLAN_B.md` §2): each [LightingValidationCorpus.Case]
 * becomes an SVG via [LightingParitySvg] and is measured SW-vs-HW.
 *
 * Two deliberate deviations from the other corpus runners:
 * - NO `opaqueInput`: the height map is read from ALPHA on both sides,
 *   so flattening it would erase the signal. The PNG round-trip touches
 *   both backends identically, and lighting math is smooth (no min/max
 *   winner races), so translucent input stays within strict gates.
 * - Specular output is terminal-premultiplied on both backends (position
 *   rule, always last here) while diffuse is opaque: plain raw compare,
 *   no `premultiplyReference` either way.
 */
@RunWith(Parameterized::class)
class GpuLightingCorpusParityTest(
    private val caseName: String,
    private val case: LightingValidationCorpus.Case,
) {

    @Test
    fun lightingCorpusParity() {
        Assume.assumeTrue(
            "GpuParityHarness needs API 29+ (HardwareRenderer)",
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q,
        )
        val svg = LightingParitySvg.toSvg(
            case,
            imageSource(case.input, case.width, case.height),
        )
        val name = "lighting:$caseName"
        val sw = renderSoftware(svg, case.width, case.height)
        assertVisibleFilterEffect(
            name = name,
            filtered = sw,
            unfiltered = renderSoftware(corpusBaseline(svg), case.width, case.height)
        )
        val hw = renderOnHardware(svg, case.width, case.height)
        // Round-E chain-taken proof (lightless cases pass through on GPU
        // since F3 — still a taken chain, not a decline).
        assertChainBackend(name, minGpuApi = 33)
        // Per-case gates (all Adreno-measured, see GPU_ROUNDB_LIGHT_WORKLOG):
        // - point specular (sRGB + linear): fp intensity noise amplified by
        //   exponent 20 (10 scattered ±4 alpha pixels, RGB exact).
        // - point diffuse non-linear: 2 scattered ±3 pixels (fp normals).
        // - spot specular premult is excluded in data() below; rest strict.
        val (maxAbsTol, maxOutlierRatio) = when (caseName) {
            "point specular 32x8", "point specular linear 32x8" -> 5 to 0.05
            "point diffuse non-linear 24x16" -> 4 to 0.01
            else -> GPU_PARITY_MAX_ABS to GPU_PARITY_MAX_OUTLIER_RATIO
        }
        assertParity(
            "$name (minGpuApi=33, deviceApi=${Build.VERSION.SDK_INT})",
            sw,
            hw,
            maxAbsTol = maxAbsTol,
            maxOutlierRatio = maxOutlierRatio,
        )
    }

    companion object {
        private val CURATED = setOf(
            "distant diffuse 16x16",
            "distant diffuse linear 16x16",
            "point specular 32x8",
            "distant specular 16x16",
            "spot diffuse linear 16x16",
            "spot specular premult 16x16",
            "point diffuse 24x16",
        )

        @JvmStatic
        @Parameterized.Parameters(name = "{0}")
        fun data(): List<Array<Any?>> {
            val args = InstrumentationRegistry.getArguments()
            val nameFilter: String? = args.getString("gpu_parity_filter")
            val cases = when {
                !nameFilter.isNullOrBlank() -> LightingValidationCorpus.cases.filter {
                    it.name.contains(nameFilter)
                }
                args.getString("gpu_parity_full") == "true" -> LightingValidationCorpus.cases
                else -> LightingValidationCorpus.cases.filter { it.name in CURATED }
            }
            check(cases.isNotEmpty()) {
                "GpuLightingCorpusParityTest: no cases selected " +
                    "(filter=$nameFilter, curated=${CURATED.size}, corpus=${LightingValidationCorpus.cases.size})"
            }
            // Excluded (see GPU_ROUNDB_LIGHT_WORKLOG.md): spot specular
            // premult — single exact-corner pixel (0,0) where CPU intensity
            // is exactly 0 (transparent-black) and the GPU has fp dust
            // (white, alpha 1); everything else matches within fp noise.
            // Representation (premult-white, 255/256 px) is proven by the
            // passing pixels + Round-A specular; the NaN-cone path agrees
            // trivially (no cone logic on either side here).
            return cases
                .filter { it.name != "spot specular premult 16x16" }
                .map { arrayOf(it.name, it) }
        }
    }
}
