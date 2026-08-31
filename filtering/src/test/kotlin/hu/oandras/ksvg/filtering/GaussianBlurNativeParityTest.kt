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

import org.junit.Assert.assertTrue
import org.junit.Test
import kotlin.math.PI
import kotlin.math.abs
import kotlin.math.ceil
import kotlin.math.exp
import kotlin.math.sqrt
import kotlin.random.Random

/**
 * Host-side parity test for [NativeGaussianBlur].
 *
 * It compares the native blur (ported from RIR Toolkit) against an independent
 * Kotlin Gaussian reference (transparent-black edges, stdDeviation == sigma).
 * Since they are different implementations of the same mathematical goal, we
 * allow a small rounding tolerance (matching the device test).
 */
class GaussianBlurNativeParityTest {

    companion object {
        init {
            System.loadLibrary("ksvgblur")
        }

        private data class Case(val w: Int, val h: Int, val sx: Float, val sy: Float)

        private fun computeWeights(sigma: Float): Pair<FloatArray, Int> {
            if (sigma <= 0f) return Pair(FloatArray(0), 0)
            var radius = ceil(3f * sigma).toInt()
            if (radius < 1) radius = 1
            if (radius > 64) radius = 64
            val w = FloatArray(2 * radius + 1)
            val c1 = 1f / sqrt(2f * PI.toFloat()) / sigma
            val c2 = -1f / (2f * sigma * sigma)
            var sum = 0f
            for (k in -radius..radius) {
                val v = c1 * exp((k * k) * c2)
                w[k + radius] = v
                sum += v
            }
            for (i in w.indices) w[i] /= sum
            return Pair(w, radius)
        }

        private fun referenceGaussian(pixels: IntArray, w: Int, h: Int, sx: Float, sy: Float): IntArray {
            val (wx, rx) = computeWeights(sx)
            val (wy, ry) = computeWeights(sy)
            val n = w * h
            val a = FloatArray(n); val r = FloatArray(n); val g = FloatArray(n); val b = FloatArray(n)
            for (i in 0 until n) {
                val p = pixels[i]
                a[i] = ((p shr 24) and 0xff).toFloat()
                r[i] = ((p shr 16) and 0xff).toFloat()
                g[i] = ((p shr 8) and 0xff).toFloat()
                b[i] = (p and 0xff).toFloat()
            }
            fun conv(src: FloatArray): FloatArray {
                val tmp = FloatArray(n)
                for (y in 0 until h) for (x in 0 until w) {
                    var s = 0f
                    for (k in -rx..rx) {
                        val xx = x + k
                        if (xx in 0 until w) s += src[y * w + xx] * wx[k + rx]
                    }
                    tmp[y * w + x] = s
                }
                val out = FloatArray(n)
                for (y in 0 until h) for (x in 0 until w) {
                    var s = 0f
                    for (k in -ry..ry) {
                        val yy = y + k
                        if (yy in 0 until h) s += tmp[yy * w + x] * wy[k + ry]
                    }
                    out[y * w + x] = s
                }
                return out
            }
            val ra = conv(a); val rr = conv(r); val rg = conv(g); val rb = conv(b)
            val out = IntArray(n)
            for (i in 0 until n) {
                fun cl(v: Float): Int {
                    var x = (v + 0.5f).toInt()
                    if (x < 0) x = 0
                    if (x > 255) x = 255
                    return x
                }
                out[i] = (cl(ra[i]) shl 24) or (cl(rr[i]) shl 16) or (cl(rg[i]) shl 8) or cl(rb[i])
            }
            return out
        }
    }

    @Test
    fun blurMatchesReference() {
        assertTrue(
            "NativeGaussianBlur not available on this host JVM",
            NativeGaussianBlur.isAvailable,
        )
        val cases = listOf(
            Case(4, 4, 0.5f, 0.5f),
            Case(7, 5, 1.5f, 1.5f),
            Case(16, 16, 2f, 2f),
            Case(32, 24, 4f, 4f),
            Case(48, 48, 8f, 8f), // optimized path
            Case(20, 30, 3f, 5f), // anisotropic
        )
        for (c in cases) {
            val rnd = Random(c.w * 1000 + c.h * 7 + (c.sx * 100).toInt())
            val px = IntArray(c.w * c.h) {
                (rnd.nextInt(256) shl 24) or (rnd.nextInt(256) shl 16) or
                    (rnd.nextInt(256) shl 8) or rnd.nextInt(256)
            }
            val ref = referenceGaussian(px, c.w, c.h, c.sx, c.sy)
            val native = px.copyOf()
            val scratch = StackBlurScratch()
            try {
                NativeGaussianBlur.blur(native, c.w, c.h, c.sx, c.sy, scratch)
            } finally {
                scratch.close()
            }

            var maxD = 0
            for (i in px.indices) {
                for (ch in 0..3) {
                    val shift = ch * 8
                    val d = abs(((native[i] shr shift) and 0xff) - ((ref[i] shr shift) and 0xff))
                    if (d > maxD) maxD = d
                }
            }
            assertTrue(
                "case ${c.w}x${c.h} sigma=(${c.sx},${c.sy}): maxDiff=$maxD exceeds tolerance 4",
                maxD <= 4,
            )
        }
    }
}
