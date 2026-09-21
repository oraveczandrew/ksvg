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

package hu.oandras.ksvg.filtering.parity

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.JUnit4

/**
 * Host-side snapshot of the round-B blur SVG builder: the generated string
 * must stay byte-stable so device runs measure the intended SVG.
 */
@RunWith(JUnit4::class)
class GaussianBlurParitySvgTest {

    @Test
    fun isotropicSerializesExactly() {
        val svg = GaussianBlurParitySvg.toSvg(
            width = 16,
            height = 16,
            stdDeviationX = 1.5f,
            stdDeviationY = 1.5f,
            imageDataUri = URI,
        )
        assertEquals(
            "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"16\" height=\"16\">" +
                "<defs>" +
                "<filter id=\"f\" filterUnits=\"userSpaceOnUse\" x=\"0\" y=\"0\" width=\"16\" height=\"16\">" +
                "<feGaussianBlur stdDeviation=\"1.5 1.5\"/>" +
                "</filter>" +
                "</defs>" +
                "<image href=\"$URI\" x=\"0\" y=\"0\" width=\"16\" height=\"16\" filter=\"url(#f)\"/>" +
                "</svg>",
            svg,
        )
    }

    @Test
    fun anisotropicKeepsBothSigmas() {
        val svg = GaussianBlurParitySvg.toSvg(
            width = 16,
            height = 16,
            stdDeviationX = 2f,
            stdDeviationY = 4f,
            imageDataUri = URI,
        )
        assertTrue(svg.contains("<feGaussianBlur stdDeviation=\"2.0 4.0\"/>"))
        assertTrue(svg.contains("filter=\"url(#f)\""))
    }

    companion object {
        private const val URI = "data:image/png;base64,AAA"
    }
}
