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
import hu.oandras.ksvg.filtering.GaussianBlurValidationCorpus
import hu.oandras.ksvg.filtering.parity.GaussianBlurParitySvg
import org.junit.Assume.assumeTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.Parameterized

/**
 * Round-B corpus coverage for `feGaussianBlur` (`tmp/GPU_PARITY_PLAN_B.md`
 * §2): each [GaussianBlurValidationCorpus.Case] becomes an SVG via
 * [GaussianBlurParitySvg] (input pixels travel as a PNG data-URI `<image>`,
 * alpha pinned opaque — see `opaqueInput`) and is measured SW-vs-HW.
 *
 * The GPU path (`RenderEffect.createBlurEffect` with the calibrated
 * `skiaBlurRadiusForSigma` mapping) approximates the CPU kernel
 * (`GPU_SCALAR_PARITY_REPORT.md` §7: non-separable Skia kernel, corner
 * zones): strict gates first, per-case tolerances only from measured
 * device data with justification comments.
 */
@RunWith(Parameterized::class)
class GpuGaussianBlurCorpusParityTest(
    private val caseName: String,
    private val case: GaussianBlurValidationCorpus.Case,
) {

    @Test
    fun gaussianBlurCorpusParity() {
        assumeTrue(
            "GpuParityHarness needs API 29+ (HardwareRenderer)",
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q,
        )
        val svg = GaussianBlurParitySvg.toSvg(
            case,
            imageSource(opaqueInput(case.input), case.width, case.height),
        )
        val name = "gaussianBlur:$caseName"
        val sw = renderSoftware(svg, case.width, case.height)
        assertVisibleFilterEffect(name, sw, renderSoftware(corpusBaseline(svg), case.width, case.height))
        val hw = renderOnHardware(svg, case.width, case.height)
        // Round-E chain-taken proof.
        assertChainBackend(name, minGpuApi = 31)
        // The GPU path (Skia blur) approximates the CPU kernel (report §7:
        // non-separable kernel, corner zones): per-case tolerances below are
        // Adreno-measured (see GPU_ROUNDB_BLUR_WORKLOG.md), never global.
        val (maxAbsTol, maxOutlierRatio) = when {
            case.stdDeviationX >= 8f || case.stdDeviationY >= 8f ->
                5 to 0.025
            case.stdDeviationX != case.stdDeviationY ->
                4 to 0.15
            maxOf(case.stdDeviationX, case.stdDeviationY) > 2f ->
                4 to 0.005
            else -> GPU_PARITY_MAX_ABS to GPU_PARITY_MAX_OUTLIER_RATIO
        }
        assertParity(
            "$name (minGpuApi=31, deviceApi=${Build.VERSION.SDK_INT})",
            sw,
            hw,
            maxAbsTol = maxAbsTol,
            maxOutlierRatio = maxOutlierRatio,
            // Readback space (F1): SW stores straight bright halos
            // (rsvg-correct), HW reads back premultiplied — compare
            // premultiplied (display-identical either way). Replaces the
            // old dark-vs-dark accidental match.
            premultiplyReference = true,
        )
    }

    companion object {
        @JvmStatic
        @Parameterized.Parameters(name = "{0}")
        fun data(): List<Array<Any?>> {
            // Small corpus: the PR gate runs all of them except the two
            // documented exclusions below.
            val nameFilter: String? = InstrumentationRegistry.getArguments()
                .getString("gpu_parity_filter")
            val selected = if (nameFilter.isNullOrBlank()) {
                GaussianBlurValidationCorpus.cases
            } else {
                GaussianBlurValidationCorpus.cases.filter { it.name.contains(nameFilter) }
            }
            // Excluded (see GPU_ROUNDB_BLUR_WORKLOG.md): isotropic 0.5 is
            // below Skia's faithful range (radius floor over-blurs; fully
            // edge-dominated 8x8) and large 10.0 is beyond the calibrated
            // mapping on a fully kernel-dominated 16px image (96% outlier
            // noise — no meaningful gate). Small/large sigma regression
            // stays covered by Round-A tiny (1.0) and optimized 8.0 here.
            val cases = selected.filter { c ->
                c.name != "isotropic 0.5 8x8" && c.name != "large 10.0 16x16"
            }
            check(cases.isNotEmpty()) {
                "GpuGaussianBlurCorpusParityTest: no cases selected " +
                    "(filter=$nameFilter, corpus=${GaussianBlurValidationCorpus.cases.size})"
            }
            return cases.map { arrayOf(it.name, it) }
        }
    }
}
