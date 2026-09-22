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

package hu.oandras.ksvg

import android.graphics.Bitmap
import hu.oandras.ksvg.filtering.LcgRandom
import hu.oandras.ksvg.filtering.SvgPathNoise
import hu.oandras.ksvg.render.createBitmap
import hu.oandras.ksvg.test.renderWithLibrary
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode
import kotlin.math.abs

@RunWith(RobolectricTestRunner::class)
@Config(manifest = Config.NONE)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class D10StitchTilesTest {

    @Test
    fun periodicNoiseRepeatsEveryPeriod() {
        val lcg = LcgRandom(7)
        val permutation = IntArray(SvgPathNoise.LATTICE_SIZE)
        SvgPathNoise.buildPermutation(lcg, permutation)
        val noise = SvgPathNoise(lcg, permutation)
        val p = 10
        // Production wrap convention (cf. KotlinKernels turbulence loop):
        // tile origin 0 + PERLIN_N offset + period. Since e8e52097 noise2
        // uses the SVG 1.1 / librsvg edge-wrap form (conditional subtraction
        // past the wrap line, NOT modular folding), so the wrap origin must
        // be explicit — the (0, 0) defaults fold every sample and cannot tile.
        val w = 4096 + p
        for (t in listOf(0.3, 3.7)) {
            val v = noise.noise2(t, 2.4, p, p, w, w)
            assertTrue("noise(x+$p) must equal noise(x)", abs(v - noise.noise2(t + p, 2.4, p, p, w, w)) < 1e-9)
            assertTrue("noise(y+$p) must equal noise(y)", abs(v - noise.noise2(t, 2.4 + p, p, p, w, w)) < 1e-9)
        }
        // Seam continuity: the cell straddling the wrap line folds only its
        // far corner (e.g. t=9.9999 folds bx1 but not bx0), so exact
        // t/t+p equality does NOT hold there by design — but the folded far
        // corner meets the folded near corner, i.e. the tile edge is
        // seamless: the difference scales with eps (measured ~1e-7 at 1e-7).
        // A broken fold would diverge O(0.1).
        val eps = 1e-7
        assertTrue(
            "stitch seam must be continuous in x",
            abs(noise.noise2(p - eps, 2.4, p, p, w, w) - noise.noise2(p + eps, 2.4, p, p, w, w)) < 1e-5
        )
        assertTrue(
            "stitch seam must be continuous in y",
            abs(noise.noise2(3.7, p - eps, p, p, w, w) - noise.noise2(3.7, p + eps, p, p, w, w)) < 1e-5
        )
        // Sanity: without a period the values differ.
        val a = noise.noise2(1.234, 2.4)
        assertTrue(abs(a - noise.noise2(1.234 + p, 2.4)) > 1e-6)
    }

    private fun render(stitchTiles: String): Bitmap {
        val svg = """
            <svg width="100" height="100" xmlns="http://www.w3.org/2000/svg">
              <defs>
                <filter id="f" x="0" y="0" width="1" height="1">
                  <feTurbulence type="turbulence" baseFrequency="0.1" numOctaves="2"
                                seed="7" stitchTiles="$stitchTiles"/>
                </filter>
              </defs>
              <rect x="0" y="0" width="100" height="100" fill="white" filter="url(#f)"/>
            </svg>
        """.trimIndent()
        return renderWithLibrary(svg, createBitmap(100, 100))
    }

    @Test
    fun stitchChangesSampling() {
        // With stitch the effective base frequency is adjusted to
        // round(tile*f)/tile; here it happens to be identical (0.1*100=10 is
        // already integral), but the periodic wrapping still yields the same
        // values while a different frequency/seed combination does not.
        // Smoke check: both modes render non-trivial noise.
        for (mode in listOf("stitch", "noStitch")) {
            val bitmap = render(mode)
            var variance = 0.0
            var last = -1
            for (x in 0 until 100) {
                val v = (bitmap.getPixel(x, 50) shr 16) and 0xff
                if (last >= 0) variance += abs(v - last)
                last = v
            }
            assertTrue("Expected non-constant noise for $mode", variance > 500.0)
        }
    }
}
