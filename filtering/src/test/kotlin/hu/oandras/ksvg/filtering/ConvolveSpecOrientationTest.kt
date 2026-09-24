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
import org.junit.Test

/**
 * Pins the feConvolveMatrix kernel orientation against the SVG 1.1 section
 * 15.22 worked example: the kernel applies rotated 180 degrees (true
 * convolution, `kernel[orderX-J-1, orderY-I-1]`), not correlated as-is.
 * Symmetric kernels cannot tell the two apart, so this uses the spec's own
 * asymmetric 5x5 image + 1..9 kernel.
 *
 * Expected values hand-computed from the spec text (divisor 45, bias 0):
 * - pixel (1, 1): (9*0+8*20+7*40+6*100+5*120+4*140+3*200+2*220+1*240)/45
 *   = 3480/45 = 77.33 -> 77 (correlation would give
 *   (1*0+2*20+3*40+4*100+5*120+6*140+7*200+8*220+9*240)/45 = 2220/45 = 49.33
 *   -> 49).
 * - pixel (2, 1): 5880/45 = 130.67 -> 131 (correlation would give 199).
 */
class ConvolveSpecOrientationTest {

    private fun gray(v: Int): Int = (0xFF shl 24) or (v shl 16) or (v shl 8) or v

    @Test
    fun specExampleAppliesFlippedKernel() {
        val rows = arrayOf(
            intArrayOf(0, 20, 40, 235, 235),
            intArrayOf(100, 120, 140, 235, 235),
            intArrayOf(200, 220, 240, 235, 235),
            intArrayOf(225, 225, 255, 255, 255),
            intArrayOf(225, 225, 255, 255, 255),
        )
        val input = IntArray(25) { i -> gray(rows[i / 5][i % 5]) }
        val kernel = FloatArray(9) { (it + 1).toFloat() }
        val out = IntArray(25)
        KotlinKernels.convolveMatrix(
            input, out, 5, 5,
            kernel, 3, 3, 1, 1,
            45f, 0f, true, 0,
        )

        assertEquals(gray(77), out[1 * 5 + 1])
        assertEquals(gray(131), out[1 * 5 + 2])
    }
}
