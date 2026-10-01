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
 * SVG `textPath` `side`: `left` (default) renders on the path's left side,
 * `right` mirrors the run to the other side (upright, same reading order).
 * `spacing` accepts `auto`/`exact` (no behavioral difference: the static
 * renderer never auto-adjusts advances on a path).
 *
 * Text only rasterizes under NATIVE graphics (see AGENTS.md).
 */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class TextPathSideTest {

    private fun render(textPathAttrs: String): Bitmap {
        val svg = """
            <svg xmlns="http://www.w3.org/2000/svg" width="300" height="100">
              <rect x="0" y="0" width="300" height="100" fill="white"/>
              <defs>
                <path id="p" d="M 10 50 H 290"/>
              </defs>
              <text font-size="30" fill="black"><textPath href="#p" $textPathAttrs>Hello</textPath></text>
            </svg>
        """.trimIndent()
        return renderWithLibrary(
            svg,
            createBitmap(300, 100, Bitmap.Config.ARGB_8888),
        )
    }

    private fun paintedRowCount(bitmap: Bitmap, y: Int): Int {
        val w = bitmap.width
        val pixels = IntArray(w)
        bitmap.getPixels(pixels, 0, w, 0, y, w, 1)
        var count = 0
        for (pixel in pixels) {
            if (pixel != 0xFFFFFFFF.toInt()) count++
        }
        return count
    }

    @Test
    fun sideMovesTextAcrossPath() {
        val left = render("")
        val right = render("""side="right"""")
        // Horizontal path at y=50: left side paints above, right side below.
        assertTrue("left should paint above the path", paintedRowCount(left, 30) > 20)
        assertTrue("left should clear below the path", paintedRowCount(left, 70) < 5)
        assertTrue("right should paint below the path", paintedRowCount(right, 70) > 20)
        assertTrue("right should clear above the path", paintedRowCount(right, 30) < 5)
    }

    @Test
    fun defaultSideIsLeft() {
        val left = render("""side="left"""")
        val default = render("")
        val w = left.width
        val h = left.height
        val a = IntArray(w * h)
        val b = IntArray(w * h)
        left.getPixels(a, 0, w, 0, 0, w, h)
        default.getPixels(b, 0, w, 0, 0, w, h)
        assertTrue("explicit left should equal default", a.contentEquals(b))
    }

    @Test
    fun spacingValuesRenderIdentically() {
        val auto = render("""spacing="auto"""")
        val exact = render("""spacing="exact"""")
        val w = auto.width
        val h = auto.height
        val a = IntArray(w * h)
        val b = IntArray(w * h)
        auto.getPixels(a, 0, w, 0, 0, w, h)
        exact.getPixels(b, 0, w, 0, 0, w, h)
        assertTrue("auto and exact spacing should match", a.contentEquals(b))
    }
}
