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

package hu.oandras.ksvg.parser

import org.junit.Assert.assertEquals
import org.junit.Test

class ColorParserPercentAlphaTest {

    @Test
    fun legacyRgbPercentAlpha() {
        assertEquals(0x80FF0000.toInt(), ColorParser.parseColor("rgba(255,0,0,50%)").value)
    }

    @Test
    fun modernRgbPercentAlpha() {
        assertEquals(0xC0FF0000.toInt(), ColorParser.parseColor("rgb(255 0 0 / 75%)").value)
    }

    @Test
    fun legacyHslaPercentAlpha() {
        assertEquals(0x40FF0000.toInt(), ColorParser.parseColor("hsla(0,100%,50%,25%)").value)
    }

    @Test
    fun modernHslPercentAlpha() {
        assertEquals(0xFFFF0000.toInt(), ColorParser.parseColor("hsl(0 100% 50% / 100%)").value)
    }

    @Test
    fun percentAlphaClampsAbove100() {
        assertEquals(0xFFFF0000.toInt(), ColorParser.parseColor("rgba(255,0,0,150%)").value)
    }

    @Test
    fun zeroPercentAlphaIsTransparent() {
        assertEquals(0x00FF0000, ColorParser.parseColor("rgba(255,0,0,0%)").value)
    }

    @Test
    fun nonPercentAlphaUnchanged() {
        assertEquals(0x80FF0000.toInt(), ColorParser.parseColor("rgba(255,0,0,0.5)").value)
        assertEquals(0xFFFF0000.toInt(), ColorParser.parseColor("rgb(255,0,0)").value)
        assertEquals(0xFFFF0000.toInt(), ColorParser.parseColor("hsl(0,100%,50%)").value)
        assertEquals(0x80FF0000.toInt(), ColorParser.parseColor("hsla(0,100%,50%,0.5)").value)
    }
}
