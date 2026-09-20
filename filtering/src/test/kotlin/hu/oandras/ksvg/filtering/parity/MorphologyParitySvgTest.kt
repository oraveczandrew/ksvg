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

import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.JUnit4
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue

/**
 * Host-side snapshot of the round-B morphology SVG builder: the generated
 * string must stay byte-stable so device runs measure the intended SVG.
 */
@RunWith(JUnit4::class)
class MorphologyParitySvgTest {

    @Test
    fun fullClipOmitsSubregion() {
        val svg = MorphologyParitySvg.toSvg(
            width = 16,
            height = 16,
            operator = "erode",
            radiusX = 1,
            radiusY = 1,
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
                "<feMorphology operator=\"erode\" radius=\"1 1\"/>" +
                "</filter>" +
                "</defs>" +
                "<image href=\"$URI\" x=\"0\" y=\"0\" width=\"16\" height=\"16\" filter=\"url(#f)\"/>" +
                "</svg>",
            svg,
        )
    }

    @Test
    fun subclipEmitsSubregion() {
        val svg = MorphologyParitySvg.toSvg(
            width = 32,
            height = 32,
            operator = "dilate",
            radiusX = 2,
            radiusY = 2,
            clipLeft = 4,
            clipTop = 4,
            clipRight = 28,
            clipBottom = 28,
            imageDataUri = URI,
        )
        assertTrue(svg.contains("<feMorphology operator=\"dilate\" radius=\"2 2\" x=\"4\" y=\"4\" width=\"24\" height=\"24\"/>"))
        assertTrue(svg.contains("filter=\"url(#f)\""))
    }

    companion object {
        private const val URI = "data:image/png;base64,AAA"
    }
}
