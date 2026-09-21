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
 * Host-side snapshot of the round-B convolve SVG builder: the generated
 * string must stay byte-stable so device runs measure the intended SVG.
 */
@RunWith(JUnit4::class)
class ConvolveParitySvgTest {

    @Test
    fun sharpenSerializesExactly() {
        val svg = ConvolveParitySvg.toSvg(
            width = 16,
            height = 16,
            kernel = floatArrayOf(0f, -1f, 0f, -1f, 5f, -1f, 0f, -1f, 0f),
            orderX = 3,
            orderY = 3,
            targetX = 1,
            targetY = 1,
            divisor = 1f,
            bias = 0f,
            preserveAlpha = true,
            edgeMode = "duplicate",
            imageDataUri = URI,
        )
        assertEquals(
            "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"16\" height=\"16\">" +
                "<defs>" +
                "<filter id=\"f\" filterUnits=\"userSpaceOnUse\" x=\"0\" y=\"0\" width=\"16\" height=\"16\">" +
                "<feConvolveMatrix order=\"3 3\" " +
                "kernelMatrix=\"0.0 -1.0 0.0 -1.0 5.0 -1.0 0.0 -1.0 0.0\" " +
                "divisor=\"1.0\" bias=\"0.0\" targetX=\"1\" targetY=\"1\" " +
                "edgeMode=\"duplicate\" preserveAlpha=\"true\"/>" +
                "</filter>" +
                "</defs>" +
                "<image href=\"$URI\" x=\"0\" y=\"0\" width=\"16\" height=\"16\" filter=\"url(#f)\"/>" +
                "</svg>",
            svg,
        )
    }

    @Test
    fun fractionalKernelRoundTrips() {
        // 1/25f must serialize as "0.04" and parse back to the same float.
        val kernel = FloatArray(25) { 1f / 25f }
        val svg = ConvolveParitySvg.toSvg(
            width = 32,
            height = 8,
            kernel = kernel,
            orderX = 5,
            orderY = 5,
            targetX = 2,
            targetY = 2,
            divisor = 1f,
            bias = 0f,
            preserveAlpha = false,
            edgeMode = "duplicate",
            imageDataUri = URI,
        )
        assertTrue(svg.contains("kernelMatrix=\"" + List(25) { "0.04" }.joinToString(" ") + "\""))
        assertTrue(svg.contains("filter=\"url(#f)\""))
        val parsed = "0.04".toFloat()
        assertEquals(1f / 25f, parsed, 0f)
    }

    companion object {
        private const val URI = "data:image/png;base64,AAA"
    }
}
