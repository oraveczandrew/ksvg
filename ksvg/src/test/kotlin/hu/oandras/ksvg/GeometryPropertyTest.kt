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
 * SVG2 geometry properties (`r`, `cx`, `x`, …) in CSS form override the
 * element attributes with normal cascade precedence:
 * attribute < stylesheet < inline style.
 */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class GeometryPropertyTest {

    private fun render(body: String): Bitmap {
        val svg = """
            <svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
              <rect x="0" y="0" width="100" height="100" fill="white"/>
              $body
            </svg>
        """.trimIndent()
        return renderWithLibrary(
            svg,
            createBitmap(100, 100, Bitmap.Config.ARGB_8888),
        )
    }

    private fun isRed(color: Int): Boolean =
        color.red > 128 && color.green < 128 && color.blue < 128

    @Test
    fun inlineStyleBeatsAttribute() {
        // r=10 attribute, 15px from the center is outside; style r:20 covers it.
        val out = render("""<circle cx="50" cy="50" r="10" style="r: 20" fill="red"/>""")
        assertTrue("style r should paint at distance 15", isRed(out.getPixel(65, 50)))
    }

    @Test
    fun attributeAppliesWithoutStyle() {
        val out = render("""<circle cx="50" cy="50" r="10" fill="red"/>""")
        assertTrue("attribute r should paint at distance 5", isRed(out.getPixel(55, 50)))
        assertTrue("attribute r should clear at distance 15", !isRed(out.getPixel(65, 50)))
    }

    @Test
    fun stylesheetBeatsAttribute() {
        val out = render(
            """<style>circle { r: 20px }</style>""" +
                """<circle cx="50" cy="50" r="10" fill="red"/>"""
        )
        assertTrue("stylesheet r should paint at distance 15", isRed(out.getPixel(65, 50)))
    }

    @Test
    fun inlineStyleBeatsStylesheet() {
        val out = render(
            """<style>circle { r: 8px }</style>""" +
                """<circle cx="50" cy="50" r="10" style="r: 20" fill="red"/>"""
        )
        assertTrue("inline r should paint at distance 15", isRed(out.getPixel(65, 50)))
    }

    @Test
    fun negativeStyleValueFallsBackToAttribute() {
        val out = render("""<circle cx="50" cy="50" r="10" style="r: -5" fill="red"/>""")
        assertTrue("fallback r should paint at distance 5", isRed(out.getPixel(55, 50)))
        assertTrue("fallback r should clear at distance 15", !isRed(out.getPixel(65, 50)))
    }

    @Test
    fun rectPositionFromStyle() {
        // Attribute block at [10, 30); style x shifts it to [50, 70).
        val out = render("""<rect x="10" y="10" width="20" height="20" style="x: 50" fill="red"/>""")
        assertTrue("style x should paint at (60, 20)", isRed(out.getPixel(60, 20)))
        assertTrue("style x should clear (20, 20)", !isRed(out.getPixel(20, 20)))
    }
}
