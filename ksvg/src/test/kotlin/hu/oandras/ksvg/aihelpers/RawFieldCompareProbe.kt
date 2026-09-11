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

package hu.oandras.ksvg.aihelpers

import hu.oandras.ksvg.filtering.LcgRandom
import hu.oandras.ksvg.filtering.SvgPathNoise
import hu.oandras.ksvg.render.createBitmap
import hu.oandras.ksvg.test.decodePng
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode
import java.io.File
import kotlin.math.abs
import kotlin.math.floor
import kotlin.math.sqrt

/**
 * Decisive forensic comparison for `turbulence_seed_stitch.svg`.
 *
 * Recomputes the kernel raw turbulence RGB at the device-projected canvas pixels and
 * compares three quantities over the fully-opaque noise region (kernel alpha == 255):
 *   1. out.png RGB  vs raw RGB        (is KSVG's alpha-composite == raw when a==255?)
 *   2. golden RGB   vs raw RGB        (does the golden match the raw field?)
 *   3. implied-alpha solve: does `golden = (a/255)*raw + (1-a/255)*255` hold with a
 *      CONSTANT effective a? If so, the golden is just the raw field faded toward white
 *      by a fixed factor (signature of an opacity/premultiply mismatch).
 */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
@Config(sdk = [33])
class RawFieldCompareProbe {

    @Test
    fun probe() {
        val golden = createBitmap(256, 256)
        val out = createBitmap(256, 256)
        decodePng(File("test-data/visual-golden/turbulence_seed_stitch.png"), golden)
        decodePng(File("test-data/ai-helper/turbulence_seed_stitch.out.png"), out)
        val gPx = IntArray(256 * 256)
        val oPx = IntArray(256 * 256)
        golden.getPixels(gPx, 0, 256, 0, 0, 256, 256)
        out.getPixels(oPx, 0, 256, 0, 0, 256, 256)

        val lcg = LcgRandom(7)
        val p = IntArray(SvgPathNoise.LATTICE_SIZE)
        val gens = Array(4) { SvgPathNoise(lcg, p) }
        SvgPathNoise.buildPermutation(lcg, p)

        val invCS = 0.625
        val userLeft = -4.0
        val userTop = 0.0
        val unit = 1.0
        val baseFx = 0.07063197026022305
        val baseFy = 0.07253886010362694
        val periodX = 19
        val periodY = 14
        val octaves = 2
        val fX = (invCS / unit) * baseFx
        val fY = (invCS / unit) * baseFy
        val kleft = -6.4
        val top = 16.0

        var nPix = 0
        // out vs raw / vs alpha-composite
        var outVsRaw = 0.0
        var outVsComp = 0.0
        // golden vs raw / vs alpha-composite
        var gVsRaw = 0.0
        var gVsComp = 0.0
        // golden vs out
        var gVsOut = 0.0
        // implied effective alpha from golden (golden = (aeff/255)*raw + (1-aeff/255)*255)
        var nAlpha = 0
        var alphaMin = 1e9
        var alphaMax = -1e9
        var alphaSum = 0.0
        var alphaSum2 = 0.0

        for (cy in 0 until 256) {
            val ky = cy - top
            if (ky < 0.0 || ky >= 193.0) continue
            val userY = userTop + ky * invCS
            val py0 = (userY / unit) * baseFy
            for (cx in 0 until 256) {
                val kx = cx + kleft
                if (kx < 0.0 || kx >= 269.0) continue
                val userX = userLeft + kx * invCS
                val px0 = (userX / unit) * baseFx
                val tileX: Double = kx
                val tileY: Double = ky

                val sums = DoubleArray(4)
                for (ch in 0 until 4) {
                    var px = px0
                    var py = py0
                    var curtlx = tileX * fX
                    var curtly = tileY * fY
                    var octPeriodX = periodX
                    var octPeriodY = periodY
                    val ratio = 1.0
                    var value = 0.0
                    repeat(octaves) {
                        val wrapX = floor(curtlx).toInt() + 4096 + octPeriodX
                        val wrapY = floor(curtly).toInt() + 4096 + octPeriodY
                        val n = gens[ch].noise2(px, py, octPeriodX, octPeriodY, wrapX, wrapY)
                        value += abs(n) / ratio
                        px *= 2.0
                        py *= 2.0
                        curtlx *= 2.0
                        curtly *= 2.0
                        octPeriodX *= 2
                        octPeriodY *= 2
                    }
                    sums[ch] = value
                }
                val rr = clamp255(sums[0] * 255.0)
                val gg = clamp255(sums[1] * 255.0)
                val bb = clamp255(sums[2] * 255.0)
                val aa = clamp255(sums[3] * 255.0)
                nPix++

                // Correct alpha composite over white:
                val ac = aa / 255.0
                val cri = (rr * ac + 255 * (1 - ac)).coerceIn(0.0, 255.0)
                val cgi = (gg * ac + 255 * (1 - ac)).coerceIn(0.0, 255.0)
                val cbi = (bb * ac + 255 * (1 - ac)).coerceIn(0.0, 255.0)

                val ov = oPx[cy * 256 + cx]
                val gv = gPx[cy * 256 + cx]
                val or_ = (ov shr 16) and 0xff
                val og = (ov shr 8) and 0xff
                val ob = ov and 0xff
                val gr = (gv shr 16) and 0xff
                val gg2 = (gv shr 8) and 0xff
                val gb = gv and 0xff

                outVsRaw += abs(or_ - rr) + abs(og - gg) + abs(ob - bb)
                outVsComp += abs(or_ - cri) + abs(og - cgi) + abs(ob - cbi)
                gVsRaw += abs(gr - rr) + abs(gg2 - gg) + abs(gb - bb)
                gVsComp += abs(gr - cri) + abs(gg2 - cgi) + abs(gb - cbi)
                gVsOut += abs(gr - or_) + abs(gg2 - og) + abs(gb - ob)

                // implied effective alpha from golden: golden = (aeff/255)*raw + (1-aeff/255)*255
                val den = (rr - 255).toDouble()
                if (abs(den) > 1e-6) {
                    val aEff = (gr - 255) / den // = a/255 effective
                    alphaMin = minOf(alphaMin, aEff)
                    alphaMax = maxOf(alphaMax, aEff)
                    alphaSum += aEff
                    alphaSum2 += aEff * aEff
                    nAlpha++
                }
            }
        }
        println("in-range(noise-region) pixels=$nPix")
        println("out vs raw   mean|.| = ${(outVsRaw / (nPix * 3)).toString().take(12)}")
        println("out vs alpha-comp  = ${(outVsComp / (nPix * 3)).toString().take(12)}")
        println("golden vs raw      = ${(gVsRaw / (nPix * 3)).toString().take(12)}")
        println("golden vs alpha-comp=${(gVsComp / (nPix * 3)).toString().take(12)}")
        println("golden vs out      = ${(gVsOut / (nPix * 3)).toString().take(12)}")
        if (nAlpha > 0) {
            val mean = alphaSum / nAlpha
            val var_ = (alphaSum2 / nAlpha) - mean * mean
            println("implied-alpha(golden): n=$nAlpha min=${alphaMin.toString().take(6)} max=${alphaMax.toString().take(6)} mean=${mean.toString().take(6)} std=${sqrt(var_).toString().take(6)}")
        }
    }

    private fun clamp255(v: Double): Int = v.toInt().coerceIn(0, 255)
}
