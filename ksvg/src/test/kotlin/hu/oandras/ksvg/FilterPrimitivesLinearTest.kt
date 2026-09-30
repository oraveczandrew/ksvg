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

package hu.oandras.ksvg

import android.graphics.Bitmap
import hu.oandras.ksvg.render.createBitmap
import hu.oandras.ksvg.test.renderWithLibrary
import hu.oandras.ksvg.utils.green
import java.io.File
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.GraphicsMode

/**
 * `filter_primitives.svg` cells must blend / apply
 * the color matrix in linearRGB (the filter default), not gamma space.
 * Pins the rsvg golden values for the `blend` (multiply over turbulence-red),
 * `cm` (0.33 matrix over blue) and `gray` (saturate 0 over green) cells.
 */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class FilterPrimitivesLinearTest {

    private fun render(): Bitmap {
        val svg = File("test-data/visual/filter_primitives.svg")
        return renderWithLibrary(svg, createBitmap(256, 256), softwareFiltering = true)
    }

    private fun cellGreen(bitmap: Bitmap, x0: Int, y0: Int): Double {
        val px = IntArray(1)
        var sum = 0L
        var n = 0
        for (y in y0 + 5 until y0 + 45) {
            for (x in x0 + 5 until x0 + 45) {
                bitmap.getPixels(px, 0, 1, x, y, 1, 1)
                sum += px[0].green
                n++
            }
        }
        return sum.toDouble() / n
    }

    @Test
    fun `blend multiply cell matches linear reference`() {
        // Golden interior mean green = 185 (linear); the gamma-space canvas
        // path produced 127.
        val mean = cellGreen(render(), 150, 80)
        assertTrue("blend cell green $mean, want ~185 (linear)", mean in 170.0..200.0)
    }

    @Test
    fun `color matrix cells match linear reference`() {
        val bitmap = render()
        // Golden: cm = 155, gray = 109; the gamma-space canvas path gave 84/92.
        val cm = cellGreen(bitmap, 150, 10)
        assertTrue("cm cell green $cm, want ~155 (linear)", cm in 145.0..165.0)
        val gray = cellGreen(bitmap, 80, 10)
        assertTrue("gray cell green $gray, want ~109 (linear)", gray in 100.0..120.0)
    }
}
