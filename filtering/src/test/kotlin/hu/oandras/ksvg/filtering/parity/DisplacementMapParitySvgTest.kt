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
 * Host-side snapshot of the round-B displacement-map SVG builder.
 */
@RunWith(JUnit4::class)
class DisplacementMapParitySvgTest {

    @Test
    fun displacementSerializesExactly() {
        val svg = DisplacementMapParitySvg.toSvg(
            width = 16,
            height = 16,
            scale = 10f,
            xChannel = 0,
            yChannel = 1,
            imageDataUri = URI,
        )
        assertEquals(
            "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"16\" height=\"16\">" +
                "<defs>" +
                "<filter id=\"f\" filterUnits=\"userSpaceOnUse\" x=\"0\" y=\"0\" width=\"16\" height=\"16\">" +
                "<feTurbulence type=\"fractalNoise\" baseFrequency=\"0.15\" " +
                "numOctaves=\"2\" seed=\"8\" result=\"map\"/>" +
                "<feDisplacementMap in=\"SourceGraphic\" in2=\"map\" " +
                "scale=\"10.0\" xChannelSelector=\"R\" yChannelSelector=\"G\"/>" +
                "</filter>" +
                "</defs>" +
                "<image href=\"$URI\" x=\"0\" y=\"0\" width=\"16\" height=\"16\" filter=\"url(#f)\"/>" +
                "</svg>",
            svg,
        )
    }

    @Test
    fun channelsMapToNames() {
        assertEquals("R", DisplacementMapParitySvg.channelName(0))
        assertEquals("G", DisplacementMapParitySvg.channelName(1))
        assertEquals("B", DisplacementMapParitySvg.channelName(2))
        assertEquals("A", DisplacementMapParitySvg.channelName(3))
        val svg = DisplacementMapParitySvg.toSvg(
            width = 32,
            height = 8,
            scale = 20f,
            xChannel = 2,
            yChannel = 3,
            imageDataUri = URI,
        )
        assertTrue(svg.contains("xChannelSelector=\"B\" yChannelSelector=\"A\""))
        assertTrue(svg.contains("filter=\"url(#f)\""))
    }

    companion object {
        private const val URI = "data:image/png;base64,AAA"
    }
}
