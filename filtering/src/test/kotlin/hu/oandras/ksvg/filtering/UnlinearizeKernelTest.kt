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

package hu.oandras.ksvg.filtering

import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Correctness of the linear→sRGB (unlinearize) filter-output transfer reference:
 * the [KotlinKernels.UN_LINEARIZE] table, [KotlinKernels.unLinearizeArgb] single-
 * pixel semantics and [KotlinKernels.unlinearize] batch op. These tests were
 * migrated from `:ksvg`'s `ColorUtilsTest` when the transfer moved into the
 * `:filtering` module.
 */
class UnlinearizeKernelTest {

    // ── UNLINEARIZE LUT ──────────────────────────────────────────────

    @Test
    fun unlinearizeLut_matchesLibrsvgBuildRs() {
        // Expected bytes from librsvg's build.rs UNLINEARIZE table
        // (verified against their Rust source and 3 byte-identical PNG captures).
        // Note: only index 0 has c = 0 <= 0.0031308 (linear branch). Index 1 already
        // c = 1/255 ≈ 0.003922 > 0.0031308, so it uses the pow branch.
        assertEquals(0, KotlinKernels.UN_LINEARIZE[0].toInt() and 0xff)
        assertEquals(13, KotlinKernels.UN_LINEARIZE[1].toInt() and 0xff)
        assertEquals(22, KotlinKernels.UN_LINEARIZE[2].toInt() and 0xff)
        assertEquals(28, KotlinKernels.UN_LINEARIZE[3].toInt() and 0xff)
        assertEquals(34, KotlinKernels.UN_LINEARIZE[4].toInt() and 0xff)

        // Mid-range — linear 0.5 → sRGB ≈ 0.7353 → byte 188
        assertEquals(188, KotlinKernels.UN_LINEARIZE[128].toInt() and 0xff)

        // White point
        assertEquals(255, KotlinKernels.UN_LINEARIZE[255].toInt() and 0xff)

        // Known value used in our dev(8,16) pixel: unpremul R byte 71 → sRGB 144
        assertEquals(144, KotlinKernels.UN_LINEARIZE[71].toInt() and 0xff)

        // Spot values used in the half-alpha test: 64 → 137, 32 → 99
        assertEquals(137, KotlinKernels.UN_LINEARIZE[64].toInt() and 0xff)
        assertEquals(99, KotlinKernels.UN_LINEARIZE[32].toInt() and 0xff)

        // Monotonicity: LUT must be non-decreasing
        for (i in 1 until 256) {
            assertTrue(
                "LUT must be non-decreasing: UN_LINEARIZE[$i]=${KotlinKernels.UN_LINEARIZE[i].toInt() and 0xff} < UN_LINEARIZE[${i - 1}]=${KotlinKernels.UN_LINEARIZE[i - 1].toInt() and 0xff}",
                (KotlinKernels.UN_LINEARIZE[i].toInt() and 0xff) >= (KotlinKernels.UN_LINEARIZE[i - 1].toInt() and 0xff)
            )
        }
    }

    // ── unLinearizeArgb (single pixel, straight channels) ────────────

    @Test
    fun unLinearizeArgb_opaqueRed() {
        // Fully opaque linear red = 0xFF_FF0000. LUT[255]=255, LUT[0]=0.
        val result = KotlinKernels.unLinearizeArgb(0xFFFF0000.toInt(), KotlinKernels.UN_LINEARIZE)
        assertEquals(0xFFFF0000.toInt(), result)
    }

    @Test
    fun unLinearizeArgb_zeroLinear() {
        // Linear value 0 maps to 0.
        assertEquals(
            0xFF000000.toInt(),
            KotlinKernels.unLinearizeArgb(0xFF000000.toInt(), KotlinKernels.UN_LINEARIZE)
        )
    }

    @Test
    fun unLinearizeArgb_opaqueWhite() {
        assertEquals(
            0xFFFFFFFF.toInt(),
            KotlinKernels.unLinearizeArgb(0xFFFFFFFF.toInt(), KotlinKernels.UN_LINEARIZE)
        )
    }

    @Test
    fun unLinearizeArgb_preservesAlpha() {
        // Straight channels: 71,24,143 with alpha 130 → LUT per channel.
        val pixel = (130 shl 24) or (71 shl 16) or (24 shl 8) or 143
        val result = KotlinKernels.unLinearizeArgb(pixel, KotlinKernels.UN_LINEARIZE)
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
        val result = KotlinKernels.unLinearizeArgb(pixel, KotlinKernels.UN_LINEARIZE)
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

    // ── unLinearize (batch) ──────────────────────────────────────────

    @Test
    fun unLinearize_allTransparent_inPlace() {
        // Transparent pixels keep their (LUT-mapped) channels but stay transparent.
        val pixels = intArrayOf(0x00000000, 0x00FF0000.toInt(), 0x0000FF00)
        KotlinKernels.unlinearize(pixels, pixels, pixels.size, 1, KotlinKernels.UN_LINEARIZE)
        assertEquals(0x00000000, pixels[0])
        // LUT[255]=255, LUT[0]=0 — transparent pixels keep channels but pixel is transparent.
        assertEquals(0x00FF0000.toInt(), pixels[1])
        assertEquals(0x0000FF00, pixels[2])
    }

    @Test
    fun unLinearize_matchesSingle() {
        val pixel = (130 shl 24) or (71 shl 16) or (24 shl 8) or 143
        val expected = KotlinKernels.unLinearizeArgb(pixel, KotlinKernels.UN_LINEARIZE)
        val pixels = intArrayOf(pixel)
        val out = IntArray(1)
        KotlinKernels.unlinearize(pixels, out, 1, 1, KotlinKernels.UN_LINEARIZE)
        assertArrayEquals(intArrayOf(expected), out)
    }

    @Test
    fun unLinearize_alphaPassthrough_allChannels() {
        // Exercise the full 0..255 domain on every channel from a varied pattern.
        val width = 19
        val height = 13
        val src = pattern(width, height, 47)
        val dst = IntArray(width * height)
        KotlinKernels.unlinearize(src, dst, width, height, KotlinKernels.UN_LINEARIZE)
        for (i in src.indices) {
            assertEquals(
                "alpha passthrough at $i",
                (src[i] ushr 24) and 0xff,
                (dst[i] ushr 24) and 0xff
            )
            val table = KotlinKernels.UN_LINEARIZE
            assertEquals(
                "R at $i",
                table[(src[i] ushr 16) and 0xff].toInt() and 0xff,
                (dst[i] ushr 16) and 0xff
            )
            assertEquals(
                "G at $i",
                table[(src[i] ushr 8) and 0xff].toInt() and 0xff,
                (dst[i] ushr 8) and 0xff
            )
            assertEquals(
                "B at $i",
                table[src[i] and 0xff].toInt() and 0xff,
                dst[i] and 0xff
            )
        }
    }

    @Test
    fun unLinearize_all256Indices_eachChannel() {
        // Guaranteed full-coverage input: every 8-bit index appears in every colour
        // channel and alpha spans 0..255, so any single-byte lookup error (e.g. a
        // 64-entry table silently zeroing channels >= 64) is caught for all 256.
        val width = 16
        val height = 16
        val src = fullCoverage(width, height)
        val dst = IntArray(width * height)
        KotlinKernels.unlinearize(src, dst, width, height, KotlinKernels.UN_LINEARIZE)
        val table = KotlinKernels.UN_LINEARIZE
        for (i in src.indices) {
            assertEquals(
                "alpha passthrough at $i",
                (src[i] ushr 24) and 0xff,
                (dst[i] ushr 24) and 0xff
            )
            assertEquals(
                "R at $i",
                table[(src[i] ushr 16) and 0xff].toInt() and 0xff,
                (dst[i] ushr 16) and 0xff
            )
            assertEquals(
                "G at $i",
                table[(src[i] ushr 8) and 0xff].toInt() and 0xff,
                (dst[i] ushr 8) and 0xff
            )
            assertEquals(
                "B at $i",
                table[src[i] and 0xff].toInt() and 0xff,
                dst[i] and 0xff
            )
        }
    }
}
