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

package hu.oandras.ksvg.filtering

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Correctness of [KotlinKernels.colorMatrix] (feColorMatrix lowered to a 4x5
 * matrix in SVG 0..1 semantics). The linear path is what the default
 * `color-interpolation-filters="linearRGB"` requires; the canvas
 * ColorMatrixColorFilter path always works in gamma space.
 */
class ColorMatrixKernelTest {

    private fun runMatrix(src: Int, matrix: FloatArray, useLinear: Boolean): Int {
        val out = IntArray(1)
        KotlinKernels.colorMatrix(
            intArrayOf(src), out, 1,
            0, 0, 1, 1, matrix, useLinear,
        )
        return out[0]
    }

    private fun channel(c: Int, shift: Int): Int = c ushr shift and 0xFF

    @Test
    fun `plain third-matrix on blue matches rsvg in linear space`() {
        // filter_primitives.svg `cm` cell: blue through 0.33-everywhere.
        // Linear: 0.33 -> sRGB ~155 (golden); gamma: 84 (old canvas output).
        val m = FloatArray(20)
        for (row in 0..2) for (col in 0..2) m[row * 5 + col] = 0.33f
        m[18] = 1f

        val linear = runMatrix(0xFF0000FF.toInt(), m, true)
        assertEquals(255, channel(linear, 24))
        for (shift in listOf(16, 8, 0)) {
            assertTrue("linear channel $shift = ${channel(linear, shift)}, want ~155",
                channel(linear, shift) in 152..158)
        }

        val gamma = runMatrix(0xFF0000FF.toInt(), m, false)
        for (shift in listOf(16, 8, 0)) {
            assertEquals(84, channel(gamma, shift))
        }
    }

    @Test
    fun `saturate-zero on green matches rsvg in linear space`() {
        // filter_primitives.svg `gray` cell: golden 109, old canvas 92.
        val m = floatArrayOf(
            0.213f, 0.715f, 0.072f, 0f, 0f,
            0.213f, 0.715f, 0.072f, 0f, 0f,
            0.213f, 0.715f, 0.072f, 0f, 0f,
            0f, 0f, 0f, 1f, 0f,
        )
        val linear = runMatrix(0xFF008000.toInt(), m, true)
        for (shift in listOf(16, 8, 0)) {
            assertTrue("linear channel $shift = ${channel(linear, shift)}, want ~109",
                channel(linear, shift) in 106..113)
        }

        val gamma = runMatrix(0xFF008000.toInt(), m, false)
        for (shift in listOf(16, 8, 0)) {
            assertEquals(92, channel(gamma, shift))
        }
    }

    @Test
    fun `identity matrix is a no-op`() {
        val m = FloatArray(20)
        m[0] = 1f; m[6] = 1f; m[12] = 1f; m[18] = 1f
        val src = 0xFF9680C8.toInt()
        assertEquals(src, runMatrix(src, m, false))
        // Linear path round-trips through 8-bit LUTs; channels >= ~52
        // round-trip within +-1 (darker values crush, e.g. 18 -> 22), so the
        // test color only uses exact round-tripping channels.
        val linear = runMatrix(src, m, true)
        assertEquals(255, channel(linear, 24))
        assertTrue("R off: ${channel(linear, 16)}", kotlin.math.abs(channel(linear, 16) - 0x96) <= 1)
        assertTrue("G off: ${channel(linear, 8)}", kotlin.math.abs(channel(linear, 8) - 0x80) <= 1)
        assertTrue("B off: ${channel(linear, 0)}", kotlin.math.abs(channel(linear, 0) - 0xC8) <= 1)
    }
}
