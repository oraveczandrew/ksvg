/*
 *    Copyright 2026 András Oravecz <info@oandras.hu>
 *
 *    Licensed under the Apache License, Version 2.0 (the "License");
 *    you may not use this file except in compliance with the License.
 *    You may obtain a copy of the License at
 *
 *        http://www.apache.org/licenses/LICENSE-2.0
 *
 *    Unless required by applicable law or agreed to in writing, software
 *    distributed under the License is distributed on an "AS IS" BASIS,
 *    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *    See the License for the specific language governing permissions and
 *    limitations under the License.
 */

package hu.oandras.ksvg.utils

import org.junit.Assert.assertEquals
import org.junit.Test

class ColorUtilsTest {

    @Test
    fun testPack3Hex() {
        // #F00 -> #FFFF0000
        assertEquals(0xFFFF0000.toInt(), pack3Hex(0xF00))
        // #0F0 -> #FF00FF00
        assertEquals(0xFF00FF00.toInt(), pack3Hex(0x0F0))
        // #00F -> #FF0000FF
        assertEquals(0xFF0000FF.toInt(), pack3Hex(0x00F))
        // #ABC -> #FFAABBCC
        assertEquals(0xFFAABBCC.toInt(), pack3Hex(0xABC))
    }

    @Test
    fun testPack4Hex() {
        // #F00F -> #FFFF0000 (red with full alpha)
        // Note: pack4Hex in implementation is RGBA in hex but ARGB in Int
        // 0xF00F: R=F, G=0, B=0, A=F -> ARGB = 0xFFFF0000
        assertEquals(0xFFFF0000.toInt(), pack4Hex(0xF00F))
        // 0xABC8: R=A, G=B, B=C, A=8 -> ARGB = 0x88AABBCC
        assertEquals(0x88AABBCC.toInt(), pack4Hex(0xABC8))
    }

    @Test
    fun testPack8Hex() {
        // RRGGBBAA -> AARRGGBB
        assertEquals(0xFFAABBCC.toInt(), pack8Hex(0xAABBCCFF.toInt()))
        assertEquals(0x88112233.toInt(), pack8Hex(0x11223388.toInt()))
    }

    @Test
    fun testPackRgba() {
        // Values are expected in 0-255 range for r, g, b
        assertEquals(0xFFFF0000.toInt(), packRgba(255f, 0f, 0f))
        assertEquals(0x8000FF00.toInt(), packRgba(0f, 255f, 0f, 0.5f))
    }

    @Test
    fun testPackHsla() {
        // H=0, S=100, L=50 -> Red
        assertEquals(0xFFFF0000.toInt(), packHsla(0f, 100f, 50f))
        // H=120, S=100, L=50 -> Green
        assertEquals(0xFF00FF00.toInt(), packHsla(120f, 100f, 50f))
        // H=240, S=100, L=50 -> Blue
        assertEquals(0xFF0000FF.toInt(), packHsla(240f, 100f, 50f))
        
        // With Alpha
        assertEquals(0x80FF0000.toInt(), packHsla(0f, 100f, 50f, 0.5f))
        
        // Negative Hue
        assertEquals(0xFFFF0000.toInt(), packHsla(-360f, 100f, 50f))
        // Over 360 Hue
        assertEquals(0xFFFF0000.toInt(), packHsla(720f, 100f, 50f))
    }

    @Test
    fun testColorWithOpacity() {
        val color = 0xFFFF0000.toInt()
        assertEquals(0x80FF0000.toInt(), color.colorWithOpacity(0.5f))
        assertEquals(0x00FF0000.toInt(), color.colorWithOpacity(0f))
        assertEquals(0xFFFF0000.toInt(), color.colorWithOpacity(1f))
    }

    @Test
    fun testWithAlpha() {
        val color = 0x00112233
        assertEquals(0xFF112233.toInt(), color.withAlpha(255))
        assertEquals(0x88112233.toInt(), color.withAlpha(0x88))
    }

    @Test
    fun testInterpolateColor() {
        val start = 0xFFFF0000.toInt() // Red
        val end = 0xFF0000FF.toInt()   // Blue
        
        // 50%
        val mid = interpolateColor(start, end, 0.5f)
        assertEquals(255, mid.alpha)
        assertEquals(128, mid.red) // 255 + (-255 * 0.5).toInt() = 255 - 127 = 128
        assertEquals(0, mid.green)
        assertEquals(127, mid.blue) // 0 + (255 * 0.5).toInt() = 127
        
        // 0%
        assertEquals(start, interpolateColor(start, end, 0f))
        // 100%
        assertEquals(end, interpolateColor(start, end, 1f))
    }
}
