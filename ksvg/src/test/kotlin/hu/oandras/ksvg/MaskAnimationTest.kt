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
 * Animation inside `<mask>` (geometry and style channels): the referencing
 * element's mask follows the animated mask content every frame. Needs
 * `computeHasAnimations` to see `maskNode`; `updateAnimations` already
 * recursed into it.
 */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class MaskAnimationTest {

    private fun renderAt(svg: String, timeMs: Long): Bitmap {
        val doc = SVG.getFromString(svg, parseAnimations = true) as SVGImpl
        doc.animationTimeMs = timeMs
        val bitmap = createBitmap(200, 200)
        doc.renderToCanvas(Canvas(bitmap))
        return bitmap
    }

    private fun redPixels(out: Bitmap): Int =
        countPixels(out) { color -> color.red > 200 && color.green < 100 && color.blue < 100 }

    private fun isRed(b: Bitmap, x: Int, y: Int): Boolean {
        val c = b.getPixel(x, y)
        return c.red > 200 && c.green < 100 && c.blue < 100
    }

    @Test
    fun maskStripeMovesWithContent() {
        val svg = """
            <svg xmlns="http://www.w3.org/2000/svg" width="200" height="200" viewBox="0 0 200 200">
              <defs>
                <mask id="m">
                  <rect x="10" y="10" width="20" height="180" fill="white">
                    <animate attributeName="x" from="10" to="170" begin="0s" dur="1000ms" fill="freeze"/>
                  </rect>
                </mask>
              </defs>
              <rect width="200" height="200" fill="red" mask="url(#m)"/>
            </svg>
        """.trimIndent()
        val start = renderAt(svg, 0)
        assertTrue("stripe starts on the left", isRed(start, 20, 100) && !isRed(start, 180, 100))
        val end = renderAt(svg, 1000)
        assertTrue("stripe ends on the right", !isRed(end, 20, 100) && isRed(end, 180, 100))
    }

    @Test
    fun maskOpacityFadesContent() {
        val svg = """
            <svg xmlns="http://www.w3.org/2000/svg" width="200" height="200" viewBox="0 0 200 200">
              <defs>
                <mask id="m">
                  <rect width="200" height="200" fill="white">
                    <animate attributeName="opacity" from="1" to="0" begin="0s" dur="1000ms" fill="freeze"/>
                  </rect>
                </mask>
              </defs>
              <rect width="200" height="200" fill="red" mask="url(#m)"/>
            </svg>
        """.trimIndent()
        val start = redPixels(renderAt(svg, 0))
        assertTrue("start area: $start, want 39500..40000", start in 39500..40000)
        val end = redPixels(renderAt(svg, 1000))
        assertTrue("end area: $end, want 0..100", end in 0..100)
    }
}
