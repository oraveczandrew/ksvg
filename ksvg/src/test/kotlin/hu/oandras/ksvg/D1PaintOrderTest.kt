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
import hu.oandras.ksvg.render.createBitmap
import hu.oandras.ksvg.test.renderWithLibrary
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.GraphicsMode

@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class D1PaintOrderTest {

    private fun render(paintOrderAttr: String?): Bitmap {
        val attr = if (paintOrderAttr != null) " paint-order=\"$paintOrderAttr\"" else ""
        val svg = """
            <svg width="100" height="100" xmlns="http://www.w3.org/2000/svg">
              <rect x="25" y="25" width="50" height="50" fill="black"
                    stroke="red" stroke-width="20"$attr/>
            </svg>
        """.trimIndent()
        return renderWithLibrary(svg, createBitmap(100, 100))
    }


    @Test
    fun `default order paints stroke over fill`() {
        // Stroke band around left edge x=25 covers 15..35; fill covers 25..75.
        // Overlap zone 25..35 must show the stroke (drawn last).
        val bitmap = render(null)
        assertTrue("Expected stroke over fill in overlap zone", isRed(bitmap, 30, 50))
        assertTrue("Expected pure stroke outside fill", isRed(bitmap, 18, 50))
        assertTrue("Expected fill interior untouched", !isRed(bitmap, 60, 50))
    }

    @Test
    fun `paint-order normal behaves as default`() {
        val bitmap = render("normal")
        assertTrue(isRed(bitmap, 30, 50))
        assertTrue(!isRed(bitmap, 60, 50))
    }

    @Test
    fun `paint-order stroke paints fill over stroke`() {
        val bitmap = render("stroke")
        // "stroke" alone = stroke first, then remaining in canonical order -> fill over stroke.
        assertTrue("Expected fill to cover stroke in overlap zone", !isRed(bitmap, 30, 50))
        assertTrue("Pure stroke area still visible", isRed(bitmap, 18, 50))
    }

    @Test
    fun `paint-order stroke fill paints fill over stroke`() {
        val bitmap = render("stroke fill")
        assertTrue(!isRed(bitmap, 30, 50))
        assertTrue(isRed(bitmap, 18, 50))
    }
}
