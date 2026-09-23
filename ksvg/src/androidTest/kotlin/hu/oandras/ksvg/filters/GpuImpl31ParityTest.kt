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
import hu.oandras.ksvg.render.filters.pipeline.FilterBackendFactoryImpl31
import org.junit.Assume.assumeTrue
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Permanent Impl31-path coverage: injects [FilterBackendFactoryImpl31] into the
 * hardware render so the API 31-32 backend is exercised on any API 31+ device.
 * Covers exactly the base mask (ColorMatrix/Blur/Offset linear chains); every
 * other primitive must decline to software (covered by the fallback tests).
 */
@RunWith(AndroidJUnit4::class)
class GpuImpl31ParityTest {

    private val impl31 = FilterBackendFactoryImpl31

    @Test
    fun blur() {
        checkImpl31(
            name = "impl31-feGaussianBlur",
            svg = filteredSvg("""<feGaussianBlur stdDeviation="4"/>"""),
            // Same calibration comment as the Api33 sibling: approximate kernel,
            // corner zones differ structurally.
            maxAbsTol = 14,
            maxOutlierRatio = 0.006,
            premultiplyReference = true,
        )
    }

    @Test
    fun blurSmallSigma() {
        checkImpl31(
            name = "impl31-feGaussianBlurSmall",
            svg = filteredSvg("""<feGaussianBlur stdDeviation="1.5"/>"""),
            maxAbsTol = 8,
            maxOutlierRatio = 0.002,
            premultiplyReference = true,
        )
    }

    @Test
    fun blurTinySigma() {
        checkImpl31(
            name = "impl31-feGaussianBlurTiny",
            svg = filteredSvg("""<feGaussianBlur stdDeviation="1"/>"""),
            maxAbsTol = 6,
            // TODO audit-#45: measured 0.00275 outlier on the base path (fringe at
            // the blurred shape edge); the Api33 sibling holds 0.001. Tighten to
            // 0.001 after the base pad-alignment investigation.
            maxOutlierRatio = 0.004,
            premultiplyReference = true,
        )
    }

    @Test
    fun offset() {
        checkImpl31(
            name = "impl31-feOffset",
            svg = filteredSvg("""<feOffset dx="24" dy="-12"/>"""),
        )
    }

    @Test
    fun colorMatrix() {
        checkImpl31(
            name = "impl31-feColorMatrix",
            svg = filteredSvg("""<feColorMatrix type="saturate" values="0"/>"""),
        )
    }

    private fun checkImpl31(
        name: String,
        svg: String,
        maxAbsTol: Int = GPU_PARITY_MAX_ABS,
        maxOutlierRatio: Double = GPU_PARITY_MAX_OUTLIER_RATIO,
        premultiplyReference: Boolean = false,
    ) {
        assumeTrue(
            "GpuParityHarness needs API 29+ (HardwareRenderer)",
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q,
        )
        // Impl31 injection instantiates the API 31 backend: only valid on 31+.
        assumeTrue(
            "FilterBackendFactoryImpl31 requires API 31+",
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.S,
        )
        val sw = renderSoftware(svg)
        assertVisibleFilterEffect(name, sw, renderSoftware(unfilteredBaseline(svg)))
        val hw = renderOnHardware(svg, gpuBackendFactory = impl31)
        // Impl31 takes these chains on every API 31+ device; the event tag is
        // backend-agnostic ("gpu"), so the standard chain proof applies.
        assertChainBackend(name, minGpuApi = 31)
        assertParity(
            "$name (impl31, deviceApi=${Build.VERSION.SDK_INT})",
            sw,
            hw,
            maxAbsTol,
            maxOutlierRatio,
            premultiplyReference = premultiplyReference,
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
