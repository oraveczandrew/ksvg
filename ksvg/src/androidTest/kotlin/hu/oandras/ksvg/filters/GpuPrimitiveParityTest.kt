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
import org.junit.Assume
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
        )
    }

    @Test
    fun specularLighting() {
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
                """<feTurbulence type="fractalNoise" baseFrequency="0.05" numOctaves="2"/>""",
            ),
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
        )
    }

    @Test
    fun flood() {
        checkParity(
            name = "feFlood",
            minGpuApi = 33,
            svg = filteredSvg("""<feFlood flood-color="#20a020"/>"""),
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

    private fun checkParity(name: String, minGpuApi: Int, svg: String) {
        Assume.assumeTrue(
            "GpuParityHarness needs API 29+ (HardwareRenderer)",
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q,
        )
        val sw = renderSoftware(svg)
        assertVisibleFilterEffect(name, sw, renderSoftware(unfilteredBaseline(svg)))
        val hw = renderOnHardware(svg)
        assertParity(
            "$name (minGpuApi=$minGpuApi, deviceApi=${Build.VERSION.SDK_INT})",
            sw,
            hw,
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
