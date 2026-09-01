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
import kotlin.math.ceil
import kotlin.math.floor

@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
@Config(sdk = [33])
class StitchProbe {

    @Test
    fun probeStitch() {
        val golden = createBitmap(320, 140)
        decodePng(File("test-data/visual-golden/turbulence_seed_stitch.png"), golden)
        val gPx = IntArray(320 * 140)
        golden.getPixels(gPx, 0, 320, 0, 0, 320, 140)

        val lcg = LcgRandom(7)
        val p = IntArray(SvgPathNoise.LATTICE_SIZE)
        val gens = Array(4) { SvgPathNoise(lcg, p) }
        SvgPathNoise.buildPermutation(lcg, p)

        // SVG params: baseFreq 0.07, octaves 2.
        // SVG size 320x140. rendered at 256x256 in AiVisualDiffTest? 
        // No, renderWithLibrary renders at the SVG's intrinsic size if possible.
        // Let's assume intrinsic size: 1 pixel = 1 unit.
        
        val freq = 0.07
        val tileW = 140.0 // The rect width is 140.
        // Wait, stitch adjustment uses the FILTER REGION width.
        // Default filter region is -5%..105% of element.
        // x=10, w=140. Region: [10 - 7, 10 + 140 + 7] = [3, 157]. Width = 154? 
        // Or is it 168? (140 * 1.2)
        
        for (w in listOf(140.0, 154.0, 168.0)) {
            val fLo = floor(w * freq) / w
            val fHi = ceil(w * freq) / w
            val f = if (freq / fLo < fHi / freq) fLo else fHi
            val period = (w * f + 0.5).toInt()
            println("Probing w=$w f=$f period=$period")
            probe(gPx, gens, period, f, 10, 10, 140, 100)
        }
    }

    private fun probe(
        gPx: IntArray,
        gens: Array<SvgPathNoise>,
        period: Int,
        f: Double,
        rectX: Int,
        rectY: Int,
        rectW: Int,
        rectH: Int
    ) {
        var match = 0
        for (y in rectY until rectY + rectH) {
            val tileY = (y - rectY).toDouble()
            for (x in rectX until rectX + rectW) {
                val tileX = (x - rectX).toDouble()
                
                var sum = 0.0
                var ratio = 1.0
                var px = x * f
                var py = y * f
                
                var curP = period
                var curWrapX = floor(tileX * f).toInt() + 4096 + curP
                var curWrapY = floor(tileY * f).toInt() + 4096 + curP

                repeat(2) {
                    sum += abs(gens[3].noise2(px, py, curP, curP, curWrapX, curWrapY)) / ratio
                    px *= 2.0
                    py *= 2.0
                    ratio *= 2.0
                    curWrapX = 2 * curWrapX - 4096
                    curWrapY = 2 * curWrapY - 4096
                    curP *= 2
                }
                val a = (sum * 255.0 + 0.5).toInt().coerceIn(0, 255)
                if (a == (gPx[y * 320 + x] ushr 24) and 0xff) match++
            }
        }
        println("Matches: $match/${rectW * rectH}")
    }
}
