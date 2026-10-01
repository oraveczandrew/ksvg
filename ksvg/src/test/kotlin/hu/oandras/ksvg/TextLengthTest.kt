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
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.GraphicsMode

/**
 * SVG `textLength` with `lengthAdjust="spacing"` (the default): the run's
 * advances stretch/squeeze to the target width. `spacingAndGlyphs` is not
 * implemented (content renders naturally).
 *
 * Text only rasterizes under NATIVE graphics (see AGENTS.md).
 */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class TextLengthTest {

    private fun render(textAttrs: String): Bitmap {
        val svg = """
            <svg xmlns="http://www.w3.org/2000/svg" width="300" height="100">
              <rect x="0" y="0" width="300" height="100" fill="white"/>
              <text x="10" y="60" font-size="40" fill="black" $textAttrs>AB</text>
            </svg>
        """.trimIndent()
        return renderWithLibrary(
            svg,
            createBitmap(300, 100, Bitmap.Config.ARGB_8888),
        )
    }

    private fun paintedExtent(bitmap: Bitmap): IntRange {
        val w = bitmap.width
        val h = bitmap.height
        val pixels = IntArray(w * h)
        bitmap.getPixels(pixels, 0, w, 0, 0, w, h)
        var minX = w
        var maxX = -1
        for (y in 0 until h) {
            for (x in 0 until w) {
                if (pixels[y * w + x] != 0xFFFFFFFF.toInt()) {
                    if (x < minX) minX = x
                    if (x > maxX) maxX = x
                }
            }
        }
        return minX..maxX
    }

    @Test
    fun stretchWidensRun() {
        val natural = paintedExtent(render(""))
        val stretched = paintedExtent(render("""textLength="150""""))
        assertTrue("sanity: natural paints $natural", natural.first <= 11 && natural.last in 50..70)
        // Advances sum to the target exactly; the painted max shifts by one
        // per-character delta (trailing gap excluded).
        val growth = stretched.last - natural.last
        assertTrue("stretched should grow ~48px, grew $growth", growth in 40..56)
        assertTrue("stretch keeps left edge", stretched.first == natural.first)
    }

    @Test
    fun squeezeNarrowsRun() {
        val natural = paintedExtent(render(""))
        val squeezed = paintedExtent(render("""textLength="20""""))
        assertTrue("squeezed should narrow by 10+, got $natural -> $squeezed", natural.last - squeezed.last >= 10)
        assertTrue("squeeze keeps left edge", squeezed.first == natural.first)
    }

    @Test
    fun spacingAndGlyphsIsIgnored() {
        val natural = render("")
        val glyphs = render("""textLength="150" lengthAdjust="spacingAndGlyphs"""")
        assertTrue("spacingAndGlyphs renders naturally", paintedExtent(glyphs) == paintedExtent(natural))
    }

    @Test
    fun tspanLevelStretches() {
        fun renderTspan(attrs: String): Bitmap {
            val svg = """
                <svg xmlns="http://www.w3.org/2000/svg" width="300" height="100">
                  <rect x="0" y="0" width="300" height="100" fill="white"/>
                  <text x="10" y="60" font-size="40" fill="black"><tspan $attrs>AB</tspan></text>
                </svg>
            """.trimIndent()
            return renderWithLibrary(
                svg,
                createBitmap(300, 100, Bitmap.Config.ARGB_8888),
            )
        }
        val natural = paintedExtent(renderTspan(""))
        val stretched = paintedExtent(renderTspan("""textLength="150""""))
        val growth = stretched.last - natural.last
        assertTrue("tspan stretch should grow ~48px, grew $growth", growth in 40..56)
    }
}
