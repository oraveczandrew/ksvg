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

import kotlin.math.PI
import kotlin.math.ceil
import kotlin.math.exp
import kotlin.math.sqrt

/**
 * Deterministic validation corpus for feGaussianBlur.
 */
public object GaussianBlurValidationCorpus {

    public class Case(
        @JvmField
        public val name: String,
        @JvmField
        public val width: Int,
        @JvmField
        public val height: Int,
        @JvmField
        public val stdDeviationX: Float,
        @JvmField
        public val stdDeviationY: Float,
        @JvmField
        public val input: IntArray,
    ) {
        public val size: Int get() = width * height

        public fun reference(): IntArray {
            return referenceGaussian(input, width, height, stdDeviationX, stdDeviationY)
        }
    }

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
            val v = c1 * exp((k * k).toFloat() * c2)
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
        fun conv(src: FloatArray, weights: FloatArray, radius: Int, horizontal: Boolean): FloatArray {
            if (radius == 0) return src
            val out = FloatArray(n)
            val dim = if (horizontal) w else h
            for (y in 0 until h) for (x in 0 until w) {
                var sa = 0f
                for (k in -radius..radius) {
                    val coord = (if (horizontal) x else y) + k
                    if (coord in 0 until dim) {
                        val idx = if (horizontal) (y * w + coord) else (coord * w + x)
                        sa += src[idx] * weights[k + radius]
                    }
                }
                out[y * w + x] = sa
            }
            return out
        }
        
        var ra = conv(a, wx, rx, true); var rr = conv(r, wx, rx, true)
        var rg = conv(g, wx, rx, true); var rb = conv(b, wx, rx, true)
        
        ra = conv(ra, wy, ry, false); rr = conv(rr, wy, ry, false)
        rg = conv(rg, wy, ry, false); rb = conv(rb, wy, ry, false)

        val out = IntArray(n)
        for (i in 0 until n) {
            fun cl(v: Float): Int {
                val x = (v + 0.5f).toInt()
                return x.coerceIn(0, 255)
            }
            out[i] = (cl(ra[i]) shl 24) or (cl(rr[i]) shl 16) or (cl(rg[i]) shl 8) or cl(rb[i])
        }
        return out
    }

    @JvmField
    public val cases: List<Case> = buildList {
        // Small isotropic
        add(Case("isotropic 1.5 16x16", 16, 16, 1.5f, 1.5f, 
            UnLinearizeValidationCorpus.fixedSeedRandom(16 * 16)))
        
        // Optimized path isotropic (radius 8, sigma ~2.6)
        add(Case("isotropic 2.6 32x24", 32, 24, 2.6f, 2.6f,
            UnLinearizeValidationCorpus.fixedSeedRandom(32 * 24)))

        // Large radius (routes to the optimized scalar path).
        add(Case("optimized 8.0 48x48", 48, 48, 8f, 8f,
            UnLinearizeValidationCorpus.fixedSeedRandom(48 * 48)))

        // Small isotropic (small radius, scalar tail).
        add(Case("isotropic 0.5 8x8", 8, 8, 0.5f, 0.5f,
            UnLinearizeValidationCorpus.fixedSeedRandom(8 * 8)))

        // Anisotropic
        add(Case("anisotropic 2.0 4.0 16x16", 16, 16, 2f, 4f,
            UnLinearizeValidationCorpus.fixedSeedRandom(16 * 16)))

        // Large radius (routes to scalar)
        add(Case("large 10.0 16x16", 16, 16, 10f, 10f,
            UnLinearizeValidationCorpus.fixedSeedRandom(16 * 16)))

        // F6-tiny: radius-3 kernel on sub-kernel geometry (pure edge path).
        add(Case("tiny 2x2 1.0", 2, 2, 1f, 1f,
            UnLinearizeValidationCorpus.fixedSeedRandom(2 * 2)))
    }
}
