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

package hu.oandras.androidsvg.utils

import kotlin.math.floor
import kotlin.math.sqrt

/**
 * Implementation of the Perlin Noise algorithm as defined in the SVG 1.1 specification (Appendix O).
 * Uses Double precision for internal calculations to minimize rounding errors.
 */
internal class SvgPathNoise(lcg: LcgRandom) {
    private val p: IntArray = IntArray(B_SIZE + B_SIZE + 2)
    private val g2: Array<DoubleArray> = Array(B_SIZE + B_SIZE + 2) {
        DoubleArray(2)
    }

    init {
        // Initialize gradients and lattice
        for (i in 0 until B_SIZE) {
            p[i] = i
            g2[i][0] = ((lcg.next() % (B_SIZE + B_SIZE)) - B_SIZE).toDouble() / B_SIZE
            g2[i][1] = ((lcg.next() % (B_SIZE + B_SIZE)) - B_SIZE).toDouble() / B_SIZE
            normalize2(g2[i])
        }

        // Shuffle lattice
        for (i in B_SIZE - 1 downTo 0) {
            val k = p[i]
            val j = lcg.next() % B_SIZE
            p[i] = p[j]
            p[j] = k
        }

        // Extend for wrapping
        for (i in 0 until B_SIZE + 2) {
            p[B_SIZE + i] = p[i]
            g2[B_SIZE + i][0] = g2[i][0]
            g2[B_SIZE + i][1] = g2[i][1]
        }
    }

    private fun normalize2(v: DoubleArray) {
        val s = sqrt(v[0] * v[0] + v[1] * v[1])
        if (s != 0.0) {
            v[0] /= s
            v[1] /= s
        }
    }

    private fun sCurve(t: Double): Double = t * t * (3.0 - 2.0 * t)
    private fun lerp(t: Double, a: Double, b: Double): Double = a + t * (b - a)

    fun noise2(x: Double, y: Double): Double {
        val bx0 = floor(x).toInt() and BM
        val bx1 = (bx0 + 1) and BM
        val rx0 = x - floor(x)
        val rx1 = rx0 - 1.0

        val by0 = floor(y).toInt() and BM
        val by1 = (by0 + 1) and BM
        val ry0 = y - floor(y)
        val ry1 = ry0 - 1.0

        val i = p[bx0]
        val j = p[bx1]

        val b00 = p[i + by0]
        val b10 = p[j + by0]
        val b01 = p[i + by1]
        val b11 = p[j + by1]

        val sx = sCurve(rx0)
        val sy = sCurve(ry0)

        val u = rx0 * g2[b00][0] + ry0 * g2[b00][1]
        val v = rx1 * g2[b10][0] + ry0 * g2[b10][1]
        val a = lerp(sx, u, v)

        val u2 = rx0 * g2[b01][0] + ry1 * g2[b01][1]
        val v2 = rx1 * g2[b11][0] + ry1 * g2[b11][1]
        val b = lerp(sx, u2, v2)

        return lerp(sy, a, b)
    }

    companion object {
        private const val B_SIZE = 0x100
        private const val BM = 0xff
    }
}
