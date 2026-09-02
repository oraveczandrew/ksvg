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
import org.junit.Assert.assertTrue
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

    // ── UNLINEARIZE LUT ──────────────────────────────────────────────

    @Test
    fun unlinearizeLut_matchesLibrsvgBuildRs() {
        // Expected bytes from librsvg's build.rs UNLINEARIZE table
        // (verified against their Rust source and 3 byte-identical PNG captures).
        // Note: only index 0 has c = 0 <= 0.0031308 (linear branch). Index 1 already
        // c = 1/255 ≈ 0.003922 > 0.0031308, so it uses the pow branch.
        assertEquals(0, UN_LINEARIZE[0].toInt() and 0xff)
        assertEquals(13, UN_LINEARIZE[1].toInt() and 0xff)
        assertEquals(22, UN_LINEARIZE[2].toInt() and 0xff)
        assertEquals(28, UN_LINEARIZE[3].toInt() and 0xff)
        assertEquals(34, UN_LINEARIZE[4].toInt() and 0xff)

        // Mid-range — linear 0.5 → sRGB ≈ 0.7353 → byte 188
        assertEquals(188, UN_LINEARIZE[128].toInt() and 0xff)

        // White point
        assertEquals(255, UN_LINEARIZE[255].toInt() and 0xff)

        // Known value used in our dev(8,16) pixel: unpremul R byte 71 → sRGB 144
        assertEquals(144, UN_LINEARIZE[71].toInt() and 0xff)

        // Spot values used in the half-alpha test: 64 → 137, 32 → 99
        assertEquals(137, UN_LINEARIZE[64].toInt() and 0xff)
        assertEquals(99, UN_LINEARIZE[32].toInt() and 0xff)

        // Monotonicity: LUT must be non-decreasing
        for (i in 1 until 256) {
            assertTrue(
                "LUT must be non-decreasing: UN_LINEARIZE[$i]=${UN_LINEARIZE[i].toInt() and 0xff} < UN_LINEARIZE[${i - 1}]=${UN_LINEARIZE[i - 1].toInt() and 0xff}",
                (UN_LINEARIZE[i].toInt() and 0xff) >= (UN_LINEARIZE[i - 1].toInt() and 0xff)
            )
        }
    }

    // ── unLinearizeArgb (single pixel, straight channels) ────────────

    @Test
    fun unLinearizeArgb_opaqueRed() {
        // Fully opaque linear red = 0xFF_FF0000. LUT[255]=255, LUT[0]=0.
        val result = unLinearizeArgb(0xFFFF0000.toInt())
        assertEquals(0xFFFF0000.toInt(), result)
    }

    @Test
    fun unLinearizeArgb_zeroLinear() {
        // Linear value 0 maps to 0.
        assertEquals(0xFF000000.toInt(), unLinearizeArgb(0xFF000000.toInt()))
    }

    @Test
    fun unLinearizeArgb_opaqueWhite() {
        assertEquals(0xFFFFFFFF.toInt(), unLinearizeArgb(0xFFFFFFFF.toInt()))
    }

    @Test
    fun unLinearizeArgb_preservesAlpha() {
        // Straight channels: 71,24,143 with alpha 130 → LUT per channel.
        val pixel = (130 shl 24) or (71 shl 16) or (24 shl 8) or 143
        val result = unLinearizeArgb(pixel)
        assertEquals("Alpha must be preserved", 130, (result ushr 24) and 0xff)
        assertEquals("R: LUT[71]=144", 144, (result ushr 16) and 0xff)
        assertEquals("G: LUT[24]=86", 86, (result ushr 8) and 0xff)
        assertEquals("B: LUT[143]=197", 197, result and 0xff)
    }

    @Test
    fun unLinearizeArgb_devPixel8_16_matchesGolden() {
        // The verified turbulence dev pixel: straight linear (71,24,143,130).
        // Straight source-over over white: out = LUT[c]*A + 255*(1-A).
        // Golden (198,169,225). Verify the LUT application reproduces it.
        val pixel = (130 shl 24) or (71 shl 16) or (24 shl 8) or 143
        val result = unLinearizeArgb(pixel)
        val rSrgb = (result ushr 16) and 0xff
        val gSrgb = (result ushr 8) and 0xff
        val bSrgb = result and 0xff
        val a = (result ushr 24) and 0xff
        val alpha = a.toDouble() / 255.0
        fun over(c: Int) = (c.toDouble() * alpha + 255.0 * (1.0 - alpha) + 0.5).toInt().coerceIn(0, 255)
        assertEquals("R over white", 198, over(rSrgb))
        assertEquals("G over white", 169, over(gSrgb))
        assertEquals("B over white", 225, over(bSrgb))
    }

    // ── unLinearizePixels (batch) ────────────────────────────────────

    @Test
    fun unLinearizePixels_allTransparent() {
        val pixels = intArrayOf(0x00000000, 0x00FF0000, 0x0000FF00)
        unLinearizePixels(pixels)
        assertEquals(0x00000000, pixels[0])
        // LUT[255]=255, LUT[0]=0 — transparent pixels keep channels but pixel is transparent.
        assertEquals(0x00FF0000, pixels[1])
        assertEquals(0x0000FF00, pixels[2])
    }

    @Test
    fun unLinearizePixels_matchesSingle() {
        val pixel = (130 shl 24) or (71 shl 16) or (24 shl 8) or 143
        val expected = unLinearizeArgb(pixel)
        val pixels = intArrayOf(pixel)
        unLinearizePixels(pixels)
        assertEquals(expected, pixels[0])
    }
}
