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
 * Correctness of [KotlinKernels.feBlend] (feBlend for non-normal modes).
 * Mode ordinals mirror `FeBlendMode` in `:ksvg` (1=multiply … 15=luminosity).
 */
class FeBlendKernelTest {

    private fun runBlend(src: Int, dst: Int, mode: Int, useLinear: Boolean): Int {
        val out = IntArray(1)
        KotlinKernels.feBlend(
            intArrayOf(src), intArrayOf(dst), out, 1,
            0, 0, 1, 1, mode, useLinear,
        )
        return out[0]
    }

    private fun red(c: Int): Int = c ushr 16 and 0xFF
    private fun green(c: Int): Int = c ushr 8 and 0xFF
    private fun blue(c: Int): Int = c and 0xFF
    private fun alpha(c: Int): Int = c ushr 24

    @Test
    fun `multiply opaque cyan over opaque red is black in both spaces`() {
        for (linear in listOf(false, true)) {
            val out = runBlend(0xFF00FFFF.toInt(), 0xFFFF0000.toInt(), 1, linear)
            assertEquals(0xFF000000.toInt(), out)
        }
    }

    @Test
    fun `multiply against translucent backdrop follows the CSS general formula`() {
        // Source opaque cyan over 50%-alpha red: (1-ab) * cyan, i.e., half cyan.
        // Linear space encodes half as sRGB ~187, gamma space as ~127 — the
        // canvas xfermode path always produced the gamma value.
        val linear = runBlend(0xFF00FFFF.toInt(), 0x80FF0000.toInt(), 1, true)
        assertEquals(255, alpha(linear))
        assertEquals(0, red(linear))
        assertTrue("linear green ${green(linear)} not ~187", green(linear) in 185..189)
        assertTrue("linear blue ${blue(linear)} not ~187", blue(linear) in 185..189)

        val gamma = runBlend(0xFF00FFFF.toInt(), 0x80FF0000.toInt(), 1, false)
        assertEquals(255, alpha(gamma))
        assertTrue("gamma green ${green(gamma)} not ~127", green(gamma) in 125..129)
    }

    @Test
    fun `screen black over white is white`() {
        val out = runBlend(0xFF000000.toInt(), 0xFFFFFFFF.toInt(), 2, true)
        assertEquals(0xFFFFFFFF.toInt(), out)
    }

    @Test
    fun `lighten cyan over red is white`() {
        val out = runBlend(0xFF00FFFF.toInt(), 0xFFFF0000.toInt(), 5, true)
        assertEquals(0xFFFFFFFF.toInt(), out)
    }

    @Test
    fun `difference cyan and red`() {
        // |Cb - Cs| per channel: R |1-0|, G |0-1|, B |0-1| -> white.
        val out = runBlend(0xFF00FFFF.toInt(), 0xFFFF0000.toInt(), 10, true)
        assertEquals(0xFFFFFFFF.toInt(), out)
    }

    @Test
    fun `transparent pair stays transparent`() {
        val out = runBlend(0x00000000, 0x00000000, 1, true)
        assertEquals(0, out)
    }

    @Test
    fun `transparent backdrop passes source through`() {
        val out = runBlend(0xFF00FFFF.toInt(), 0x00000000, 1, true)
        assertEquals(0xFF00FFFF.toInt(), out)
    }
}
