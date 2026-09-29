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
import android.graphics.Canvas
import hu.oandras.ksvg.dom.SVGImpl
import hu.oandras.ksvg.render.createBitmap
import hu.oandras.ksvg.test.countPixels
import hu.oandras.ksvg.utils.blue
import hu.oandras.ksvg.utils.green
import hu.oandras.ksvg.utils.red
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.GraphicsMode

/**
 * Geometry animation inside `<clipPath>` (e.g. `<circle><animate
 * attributeName="r"/></circle>`): the referencing element's clip follows the
 * animated clip content every frame.
 */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class ClipPathAnimationTest {

    private fun renderAt(svg: String, timeMs: Long): Bitmap {
        val doc = SVG.getFromString(svg, parseAnimations = true) as SVGImpl
        doc.animationTimeMs = timeMs
        val bitmap = createBitmap(200, 200)
        doc.renderToCanvas(Canvas(bitmap))
        return bitmap
    }

    private fun redPixels(out: Bitmap): Int =
        countPixels(out) { color -> color.red > 200 && color.green < 100 && color.blue < 100 }

    private fun clippedCircleSvg(): String {
        return """
            <svg xmlns="http://www.w3.org/2000/svg" width="200" height="200" viewBox="0 0 200 200">
              <defs>
                <clipPath id="c">
                  <circle cx="100" cy="100" r="10"><animate attributeName="r" from="10" to="90" begin="0s" dur="1000ms" fill="freeze"/></circle>
                </clipPath>
              </defs>
              <rect width="200" height="200" fill="red" clip-path="url(#c)"/>
            </svg>
        """.trimIndent()
    }

    @Test
    fun clipCircleRadiusAnimates() {
        val svg = clippedCircleSvg()
        // pi * 10^2 ~= 314.
        val start = redPixels(renderAt(svg, 0))
        assertTrue("start area: $start, want 150..600", start in 150..600)
        // pi * 50^2 ~= 7854.
        val mid = redPixels(renderAt(svg, 500))
        assertTrue("mid area: $mid, want 7000..8700", mid in 7000..8700)
        // pi * 90^2 ~= 25447.
        val end = redPixels(renderAt(svg, 1000))
        assertTrue("end area: $end, want 24000..27000", end in 24000..27000)
    }

    @Test
    fun clipCircleCenterMoves() {
        val svg = """
            <svg xmlns="http://www.w3.org/2000/svg" width="200" height="200" viewBox="0 0 200 200">
              <defs>
                <clipPath id="c">
                  <circle cx="30" cy="100" r="30">
                    <animate attributeName="cx" from="30" to="170" begin="0s" dur="1000ms" fill="freeze"/>
                  </circle>
                </clipPath>
              </defs>
              <rect width="200" height="200" fill="red" clip-path="url(#c)"/>
            </svg>
        """.trimIndent()
        fun isRed(b: Bitmap, x: Int, y: Int): Boolean {
            val c = b.getPixel(x, y)
            return c.red > 200 && c.green < 100 && c.blue < 100
        }
        val start = renderAt(svg, 0)
        assertTrue("disc starts on the left", isRed(start, 30, 100) && !isRed(start, 170, 100))
        val end = renderAt(svg, 1000)
        assertTrue("disc ends on the right", !isRed(end, 30, 100) && isRed(end, 170, 100))
    }

    @Test
    fun clipRectWidthAnimates() {
        val svg = """
            <svg xmlns="http://www.w3.org/2000/svg" width="200" height="200" viewBox="0 0 200 200">
              <defs>
                <clipPath id="c">
                  <rect x="10" y="10" width="20" height="100">
                    <animate attributeName="width" from="20" to="180" begin="0s" dur="1000ms" fill="freeze"/>
                  </rect>
                </clipPath>
              </defs>
              <rect width="200" height="200" fill="red" clip-path="url(#c)"/>
            </svg>
        """.trimIndent()
        // 20 x 100 = 2000.
        val start = redPixels(renderAt(svg, 0))
        assertTrue("start area: $start, want 1500..2600", start in 1500..2600)
        // 180 x 100 = 18000.
        val end = redPixels(renderAt(svg, 1000))
        assertTrue("end area: $end, want 17000..19000", end in 17000..19000)
    }
}
