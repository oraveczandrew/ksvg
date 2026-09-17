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

import kotlin.math.floor
import kotlin.math.sqrt

/**
 * Implementation of the Perlin Noise algorithm as defined in the SVG 1.1 specification (Appendix O).
 * Uses Double precision for internal calculations to minimize rounding errors.
 *
 * The lattice is built to match the reference (librsvg / SVG spec) draw order so the
 * output is byte-identical to the reference implementation:
 *
 *  - the four channel gradient tables are filled first, in channel order 0..3, each
 *    drawing exactly two LCG values per lattice point (retrying when both are zero),
 *    from the shared LCG stream;
 *  - only afterwards is the single lattice permutation built/shuffled from the same
 *    stream and shared across all channels.
 */
public class SvgPathNoise(
    lcg: LcgRandom,
    @JvmField public val p: IntArray
) {

    // Flat gradient tables (one DoubleArray per component). Previously an
    // Array<DoubleArray>; the flat form halves noise2's loads and removes
    // ~500 tiny allocations per generator. Values are bit-identical to the
    // old layout (same doubles, same indices, including the wrapped tail).
    @JvmField public val gx: DoubleArray = DoubleArray(B_SIZE + B_SIZE + 2)
    @JvmField public val gy: DoubleArray = DoubleArray(B_SIZE + B_SIZE + 2)

    init {
        for (i in 0 until B_SIZE) {
            var a: Int
            var b: Int
            do {
                a = (lcg.next() % (B_SIZE + B_SIZE)) - B_SIZE
                b = (lcg.next() % (B_SIZE + B_SIZE)) - B_SIZE
            } while (a == 0 && b == 0)
            // Same op order as the old normalize2(row): round a/B and b/B
            // first, then normalize the rounded values.
            var gx0 = a.toDouble() / B_SIZE
            var gy0 = b.toDouble() / B_SIZE
            val s = sqrt(gx0 * gx0 + gy0 * gy0)
            if (s != 0.0) {
                gx0 /= s
                gy0 /= s
            }
            gx[i] = gx0
            gy[i] = gy0
        }

        for (i in 0 until B_SIZE + 2) {
            gx[B_SIZE + i] = gx[i]
            gy[B_SIZE + i] = gy[i]
        }
    }

    private inline fun sCurve(t: Double): Double = t * t * (3.0 - 2.0 * t)
    private inline fun lerp(t: Double, a: Double, b: Double): Double = a + t * (b - a)

    /**
     * Samples 2D Perlin noise.
     * [x], [y] are absolute lattice coordinates.
     * If [periodX] > 0, the noise stitches periodically over the tile.
     * [wrapX] is the lattice coordinate (including PERLIN_N offset) where wrapping occurs.
     */
    public fun noise2(
        x: Double, y: Double,
        periodX: Int = 0, periodY: Int = 0,
        wrapX: Int = 0, wrapY: Int = 0
    ): Double {
        val tx = x + 4096.0
        var bx0 = tx.toInt()
        var bx1 = bx0 + 1
        val rx0 = tx - floor(tx)
        val rx1 = rx0 - 1.0

        val ty = y + 4096.0
        var by0 = ty.toInt()
        var by1 = by0 + 1
        val ry0 = ty - floor(ty)
        val ry1 = ry0 - 1.0

        if (periodX > 0) {
            if (bx0 >= wrapX) bx0 -= periodX
            if (bx1 >= wrapX) bx1 -= periodX
        }
        if (periodY > 0) {
            if (by0 >= wrapY) by0 -= periodY
            if (by1 >= wrapY) by1 -= periodY
        }

        bx0 = bx0 and BM
        bx1 = bx1 and BM
        by0 = by0 and BM
        by1 = by1 and BM

        val i = p[bx0]
        val j = p[bx1]

        val b00 = p[i + by0]
        val b10 = p[j + by0]
        val b01 = p[i + by1]
        val b11 = p[j + by1]

        val sx = sCurve(rx0)
        val sy = sCurve(ry0)

        val u = rx0 * gx[b00] + ry0 * gy[b00]
        val v = rx1 * gx[b10] + ry0 * gy[b10]
        val a = lerp(sx, u, v)

        val u2 = rx0 * gx[b01] + ry1 * gy[b01]
        val v2 = rx1 * gx[b11] + ry1 * gy[b11]
        val b = lerp(sx, u2, v2)

        return lerp(sy, a, b)
    }

    public companion object {
        private const val B_SIZE = 0x100
        private const val BM = 0xff

        public fun buildPermutation(lcg: LcgRandom, p: IntArray) {
            for (i in 0 until B_SIZE) {
                p[i] = i
            }
            for (i in B_SIZE - 1 downTo 1) {
                val k = p[i]
                val j = lcg.next() % B_SIZE
                p[i] = p[j]
                p[j] = k
            }
            for (i in 0 until B_SIZE + 2) {
                p[B_SIZE + i] = p[i]
            }
        }

        public const val LATTICE_SIZE: Int = B_SIZE + B_SIZE + 2
    }
}
