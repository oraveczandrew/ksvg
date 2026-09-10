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
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode
import java.io.File
import java.nio.ByteBuffer
import java.nio.ByteOrder
import kotlin.math.abs
import kotlin.math.floor

/**
 * Compares the ACTUAL kernel-produced turbulence bitmap (269x193, dumped from
 * `drawFiltered` as little-endian ARGB ints) directly against a Kotlin recompute
 * at identical kernel coordinates. Removes all canvas-projection guesswork.
 */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
@Config(sdk = [33])
class KernelDumpCompareProbe {

    @Test
    fun probe() {
        val f = listOf(File("tmp/turb_kernel_dump.bin"), File("../tmp/turb_kernel_dump.bin")).firstOrNull { it.exists() } ?: File("tmp/turb_kernel_dump.bin")
        if (!f.exists()) return
        val bytes = f.readBytes()
        val buf = ByteBuffer.wrap(bytes).order(ByteOrder.LITTLE_ENDIAN)
        val w = 269
        val h = 193
        val px = IntArray(w * h)
        for (i in px.indices) px[i] = buf.int

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

        // Compare raw RGBA per channel against the dump.
        var total = 0
        var n = 0
        var exactAlpha = 0
        var nAlphaDiff = 0
        var nRgbDiff = 0
        for (y in 0 until h) {
            val userY = userTop + y * invCS
            val py0 = (userY / unit) * baseFy
            for (x in 0 until w) {
                val userX = userLeft + x * invCS
                val px0 = (userX / unit) * baseFx
                val tileX = x.toDouble()
                val tileY = y.toDouble()

                val sums = DoubleArray(4)
                for (ch in 0 until 4) {
                    var pxv = px0
                    var pyv = py0
                    var curtlx = tileX * fX
                    var curtly = tileY * fY
                    var octPeriodX = periodX
                    var octPeriodY = periodY
                    var ratio = 1.0
                    var value = 0.0
                    repeat(octaves) {
                        val wrapX = floor(curtlx).toInt() + 4096 + octPeriodX
                        val wrapY = floor(curtly).toInt() + 4096 + octPeriodY
                        val nn = gens[ch].noise2(pxv, pyv, octPeriodX, octPeriodY, wrapX, wrapY)
                        value += abs(nn) / ratio
                        pxv *= 2.0
                        pyv *= 2.0
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

                val dv = px[y * w + x]
                val dra = (dv shr 24) and 0xff
                val dr_ = (dv shr 16) and 0xff
                val dg = (dv shr 8) and 0xff
                val db = dv and 0xff

                total += abs(dr_ - rr) + abs(dg - gg) + abs(db - bb)
                n++
                if (abs(dra - aa) <= 1) exactAlpha++ else nAlphaDiff++
                if (abs(dr_ - rr) > 2 || abs(dg - gg) > 2 || abs(db - bb) > 2) nRgbDiff++
            }
        }
        println("n=$n  mean|rgb-diff|/ch=${(total.toDouble() / n / 3).toString().take(8)}")
        println("alpha match(<=1): $exactAlpha/$n  alphaDiff>1: $nAlphaDiff")
        println("rgbDiff>2: $nRgbDiff/$n (${(100 * nRgbDiff / n)}%)")
    }

    private fun clamp255(v: Double): Int = v.toInt().coerceIn(0, 255)
}
