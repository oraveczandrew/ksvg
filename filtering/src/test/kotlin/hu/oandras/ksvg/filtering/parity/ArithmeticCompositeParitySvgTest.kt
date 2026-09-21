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
 * Host-side snapshot of the round-B arithmetic-composite SVG builder.
 */
@RunWith(JUnit4::class)
class ArithmeticCompositeParitySvgTest {

    @Test
    fun arithmeticSerializesExactly() {
        val svg = ArithmeticCompositeParitySvg.toSvg(
            width = 16,
            height = 16,
            k1 = 0f,
            k2 = 1f,
            k3 = -1f,
            k4 = 0f,
            useLinear = false,
            clipLeft = 0,
            clipTop = 0,
            clipRight = 16,
            clipBottom = 16,
            imageDataUri = URI,
        )
        assertEquals(
            "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"16\" height=\"16\">" +
                "<defs>" +
                "<filter id=\"f\" filterUnits=\"userSpaceOnUse\" x=\"0\" y=\"0\" width=\"16\" height=\"16\">" +
                "<feFlood flood-color=\"#4060c0\" result=\"c\"/>" +
                "<feComposite operator=\"arithmetic\" in=\"SourceGraphic\" in2=\"c\" " +
                "k1=\"0.0\" k2=\"1.0\" k3=\"-1.0\" k4=\"0.0\" " +
                "color-interpolation-filters=\"sRGB\"/>" +
                "</filter>" +
                "</defs>" +
                "<image href=\"$URI\" x=\"0\" y=\"0\" width=\"16\" height=\"16\" filter=\"url(#f)\"/>" +
                "</svg>",
            svg,
        )
    }

    @Test
    fun linearSubclipEmitsBoth() {
        val svg = ArithmeticCompositeParitySvg.toSvg(
            width = 32,
            height = 32,
            k1 = 0.5f,
            k2 = 0.5f,
            k3 = 0.5f,
            k4 = 0.1f,
            useLinear = true,
            clipLeft = 4,
            clipTop = 4,
            clipRight = 28,
            clipBottom = 28,
            imageDataUri = URI,
        )
        assertTrue(svg.contains("x=\"4\" y=\"4\" width=\"24\" height=\"24\""))
        assertTrue(svg.contains("color-interpolation-filters=\"linearRGB\""))
        assertTrue(svg.contains("filter=\"url(#f)\""))
    }

    companion object {
        private const val URI = "data:image/png;base64,AAA"
    }
}
