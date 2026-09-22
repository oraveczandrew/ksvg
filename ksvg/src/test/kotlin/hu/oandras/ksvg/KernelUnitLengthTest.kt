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
package hu.oandras.ksvg

import hu.oandras.ksvg.render.createBitmap
import hu.oandras.ksvg.test.renderWithLibrary
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode

/**
 * `kernelUnitLength` on `feConvolveMatrix`: scales the kernel sampling step
 * (reference model: downscale input → convolve at 1px steps → upscale back,
 * validated against `rsvg-convert`; see `tmp/kul/`).
 *
 * Raster assertions use NATIVE graphics + the software filter backend
 * (per AGENTS.md). Structural asserts (monotonicity, ranges) are used
 * instead of exact pixels so the tests survive resampler grid differences.
 */
@RunWith(RobolectricTestRunner::class)
@Config(manifest = Config.NONE)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class KernelUnitLengthTest {

    private fun renderEdge(kulAttr: String): IntArray {
        val svg = """
            <svg width="60" height="20" xmlns="http://www.w3.org/2000/svg">
              <filter id="f" x="0" y="0" width="60" height="20"
                      filterUnits="userSpaceOnUse" primitiveUnits="userSpaceOnUse">
                <feConvolveMatrix order="3 1" kernelMatrix="1 1 1" divisor="3"$kulAttr/>
              </filter>
              <g filter="url(#f)">
                <rect x="0" y="0" width="30" height="20" fill="black"/>
                <rect x="30" y="0" width="30" height="20" fill="white"/>
              </g>
            </svg>
        """.trimIndent()
        val bitmap = renderWithLibrary(svg, createBitmap(60, 20), softwareFiltering = true)
        return IntArray(60) { x -> (bitmap.getPixel(x, 10) shr 16) and 0xff }
    }

    @Test
    fun defaultStepIsOnePixel() {
        val row = renderEdge("")
        // 3-tap box smooths the edge over +-1px only: black well before,
        // white right after the transition.
        assertTrue("expected black at x=28, got ${row[28]}", row[28] < 16)
        assertTrue("expected white at x=31, got ${row[31]}", row[31] > 239)
    }

    @Test
    fun kernelUnitLengthWidensTransition() {
        val row = renderEdge(" kernelUnitLength=\"3\"")
        // Far fields untouched, transition spread over ~order*3 px, monotonic.
        assertEquals(0, row[24])
        assertEquals(255, row[35])
        for (x in 25 until 35) {
            assertTrue("expected monotonic ramp at x=$x: ${row[x - 1]} -> ${row[x]}", row[x] >= row[x - 1])
        }
        // x=29 sits strictly inside the transition (hard edge would be 255).
        assertTrue("expected interior transition value at x=29, got ${row[29]}", row[29] in 1..254)
    }

    @Test
    fun nonPositiveKernelUnitLengthFallsBackToDefault() {
        for (kul in listOf("0", "-2", "0 0")) {
            val row = renderEdge(" kernelUnitLength=\"$kul\"")
            assertTrue("kul=$kul: expected black at x=28, got ${row[28]}", row[28] < 16)
            assertTrue("kul=$kul: expected white at x=31, got ${row[31]}", row[31] > 239)
        }
    }

    private fun renderLit(kulAttr: String): IntArray {
        // Alpha step as the bump map: flat field with a degenerate-normal
        // edge (black), matching rsvg pixel-for-pixel without kernelUnitLength.
        val svg = """
            <svg width="60" height="20" xmlns="http://www.w3.org/2000/svg">
              <filter id="f" x="0" y="0" width="60" height="20"
                      filterUnits="userSpaceOnUse" primitiveUnits="userSpaceOnUse">
                <feDiffuseLighting surfaceScale="2" diffuseConstant="1" lighting-color="white"$kulAttr>
                  <feDistantLight azimuth="0" elevation="60"/>
                </feDiffuseLighting>
              </filter>
              <g filter="url(#f)">
                <rect x="0" y="0" width="30" height="20" fill="white" opacity="0"/>
                <rect x="30" y="0" width="30" height="20" fill="white" opacity="1"/>
              </g>
            </svg>
        """.trimIndent()
        val bitmap = renderWithLibrary(svg, createBitmap(60, 20), softwareFiltering = true)
        return IntArray(60) { x -> (bitmap.getPixel(x, 10) shr 16) and 0xff }
    }

    @Test
    fun lightingKernelUnitLengthWidensEdgeResponse() {
        val flat = renderLit("")
        // Baseline without kernelUnitLength: uniform field, black edge pair.
        assertTrue("expected flat field at x=24, got ${flat[24]}", flat[24] in 230..255)
        assertEquals(0, flat[29])
        assertEquals(0, flat[30])
        assertTrue("expected flat field at x=26, got ${flat[26]}", flat[26] in 230..255)

        // kernelUnitLength=3: same flat field and black core, but the
        // shoulders spread (validated against rsvg-convert; tmp/kul/).
        val row = renderLit(" kernelUnitLength=\"3\"")
        assertTrue("expected flat field at x=24, got ${row[24]}", row[24] in 230..255)
        assertEquals(0, row[29])
        assertTrue("expected spread shoulder at x=26, got ${row[26]}", row[26] in 150..220)
        assertTrue("expected spread shoulder at x=27, got ${row[27]}", row[27] in 100..200)
        assertTrue("expected flat field at x=34, got ${row[34]}", row[34] in 230..255)
    }

    @Test
    fun lightingInvalidKernelUnitLengthFallsBackToDefault() {
        val row = renderLit(" kernelUnitLength=\"0\"")
        assertTrue("expected flat field at x=26, got ${row[26]}", row[26] in 230..255)
        assertEquals(0, row[29])
    }
}
