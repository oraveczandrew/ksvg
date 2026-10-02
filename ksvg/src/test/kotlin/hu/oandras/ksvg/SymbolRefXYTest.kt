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
import hu.oandras.ksvg.utils.blue
import hu.oandras.ksvg.utils.green
import hu.oandras.ksvg.utils.red
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.GraphicsMode

/**
 * SVG2 `symbol` refX/refY: the reference point (post-viewBox coords) lands on
 * the `use` x/y, so content shifts by -ref. Unspecified means no adjustment.
 */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class SymbolRefXYTest {

    private fun render(symbolAttrs: String, rectAttrs: String = """x="30" y="0" width="10" height="40""""): Bitmap {
        val svg = """
            <svg xmlns="http://www.w3.org/2000/svg" width="200" height="100">
              <rect x="0" y="0" width="200" height="100" fill="white"/>
              <defs>
                <symbol id="s" $symbolAttrs>
                  <rect $rectAttrs fill="red"/>
                </symbol>
              </defs>
              <use href="#s" x="100" y="10" width="40" height="40"/>
            </svg>
        """.trimIndent()
        return renderWithLibrary(
            svg,
            createBitmap(200, 100, Bitmap.Config.ARGB_8888),
        )
    }

    private fun isRed(color: Int): Boolean =
        color.red > 128 && color.green < 128 && color.blue < 128

    @Test
    fun refXShiftsContentLeft() {
        // Content covers local x in [30, 40): baseline paints (135, 30) only.
        val baseline = render("")
        assertTrue("baseline should paint at (135, 30)", isRed(baseline.getPixel(135, 30)))
        assertTrue("baseline should be clear at (105, 30)", !isRed(baseline.getPixel(105, 30)))
        // refX=25 moves the block to [5, 15): (105, 30) turns red, (135, 30) clears.
        val shifted = render("""refX="25"""")
        assertTrue("refX should paint at (105, 30)", isRed(shifted.getPixel(105, 30)))
        assertTrue("refX should clear (135, 30)", !isRed(shifted.getPixel(135, 30)))
    }

    @Test
    fun refYShiftsContentUp() {
        val baseline = render("", """x="0" y="30" width="40" height="10"""")
        assertTrue("baseline should paint at (110, 45)", isRed(baseline.getPixel(110, 45)))
        assertTrue("baseline should be clear at (110, 20)", !isRed(baseline.getPixel(110, 20)))
        // refY=25 moves the block to local y [5, 15), i.e., global [15, 25).
        val shifted = render("""refY="25"""", """x="0" y="30" width="40" height="10"""")
        assertTrue("refY should paint at (110, 20)", isRed(shifted.getPixel(110, 20)))
        assertTrue("refY should clear (110, 45)", !isRed(shifted.getPixel(110, 45)))
    }

    @Test
    fun centerKeywordMatchesHalfViewBox() {
        val keyword = render("""viewBox="0 0 40 40" refX="center"""")
        val numeric = render("""viewBox="0 0 40 40" refX="20"""")
        // center = 50% of the 40-wide viewBox = 20: block [30, 40) moves to [10, 20).
        assertTrue("center should paint at (115, 30)", isRed(keyword.getPixel(115, 30)))
        assertTrue("center should clear (135, 30)", !isRed(keyword.getPixel(135, 30)))
        assertTrue(
            "center should equal numeric 20",
            keyword.getPixel(115, 30) == numeric.getPixel(115, 30) &&
                keyword.getPixel(135, 30) == numeric.getPixel(135, 30)
        )
    }
}
