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
import hu.oandras.ksvg.test.countPixels
import hu.oandras.ksvg.test.renderWithLibrary
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.GraphicsMode

/**
 * SVG `rotate` on `text`/`tspan`: per-character supplemental rotation about
 * the glyph origin. Advances stay on the unrotated baseline.
 *
 * Text only rasterizes under NATIVE graphics (see AGENTS.md).
 */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class TextRotateTest {

    private fun render(textAttrs: String, body: String = "X"): Bitmap {
        val svg = """
            <svg xmlns="http://www.w3.org/2000/svg" width="200" height="100">
              <rect x="0" y="0" width="200" height="100" fill="white"/>
              <text x="60" y="60" font-size="40" fill="black" $textAttrs>$body</text>
            </svg>
        """.trimIndent()
        return renderWithLibrary(
            svg,
            createBitmap(200, 100, Bitmap.Config.ARGB_8888),
        )
    }

    private fun differingPixels(a: Bitmap, b: Bitmap): Int {
        val w = a.width
        val h = a.height
        val pa = IntArray(w * h)
        val pb = IntArray(w * h)
        a.getPixels(pa, 0, w, 0, 0, w, h)
        b.getPixels(pb, 0, w, 0, 0, w, h)
        var differing = 0
        for (i in pa.indices) {
            if (pa[i] != pb[i]) differing++
        }
        return differing
    }

    private fun paintedPixels(bitmap: Bitmap): Int =
        countPixels(bitmap) { it != 0xFFFFFFFF.toInt() }

    @Test
    fun textLevelRotateChangesGlyphs() {
        val plain = render("")
        val rotated = render("""rotate="45"""")
        assertTrue("plain text should paint", paintedPixels(plain) > 100)
        assertTrue("rotated text should paint", paintedPixels(rotated) > 100)
        assertTrue(
            "rotated glyphs should differ from plain",
            differingPixels(plain, rotated) > 100
        )
    }

    @Test
    fun zeroRotateMatchesNoRotate() {
        val plain = render("")
        val zero = render("""rotate="0"""")
        assertTrue(
            "explicit zero rotation should be a no-op",
            differingPixels(plain, zero) == 0
        )
    }

    @Test
    fun tspanLevelRotateChangesGlyphs() {
        val svgTemplate = """
            <svg xmlns="http://www.w3.org/2000/svg" width="200" height="100">
              <rect x="0" y="0" width="200" height="100" fill="white"/>
              <text x="60" y="60" font-size="40" fill="black"><tspan %s>X</tspan></text>
            </svg>
        """.trimIndent()
        fun renderTspan(tspanAttrs: String): Bitmap = renderWithLibrary(
            svgTemplate.format(tspanAttrs),
            createBitmap(200, 100, Bitmap.Config.ARGB_8888),
        )
        val plain = renderTspan("")
        val rotated = renderTspan("""rotate="45"""")
        assertTrue("plain tspan should paint", paintedPixels(plain) > 100)
        assertTrue("rotated tspan should paint", paintedPixels(rotated) > 100)
        assertTrue(
            "rotated tspan glyphs should differ from plain",
            differingPixels(plain, rotated) > 100
        )
    }
}
