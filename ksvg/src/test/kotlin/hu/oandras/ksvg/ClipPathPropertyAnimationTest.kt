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
 * SMIL animation of the `clip-path` property itself
 * (`<animate attributeName="clip-path" .../>`). Same-kind basic shapes
 * interpolate component-wise (CSS Shapes rule); `url()`, `none` and
 * mismatched shapes are discrete.
 */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class ClipPathPropertyAnimationTest {

    private fun renderAt(svg: String, timeMs: Long): Bitmap {
        val doc = SVG.getFromString(svg, parseAnimations = true) as SVGImpl
        doc.animationTimeMs = timeMs
        val bitmap = createBitmap(200, 200)
        doc.renderToCanvas(Canvas(bitmap))
        return bitmap
    }

    private fun redPixels(out: Bitmap): Int =
        countPixels(out) { color -> color.red > 200 && color.green < 100 && color.blue < 100 }

    @Test
    fun circleRadiusInterpolates() {
        val svg = """
            <svg xmlns="http://www.w3.org/2000/svg" width="200" height="200" viewBox="0 0 200 200">
              <rect width="200" height="200" fill="red" clip-path="circle(10px at center center)">
                <animate attributeName="clip-path" from="circle(10px at center center)" to="circle(90px at center center)"
                  begin="0s" dur="1000ms" fill="freeze"/>
              </rect>
            </svg>
        """.trimIndent()
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
    fun insetInterpolates() {
        val svg = """
            <svg xmlns="http://www.w3.org/2000/svg" width="200" height="200" viewBox="0 0 200 200">
              <rect width="200" height="200" fill="red" clip-path="inset(80px)">
                <animate attributeName="clip-path" from="inset(80px)" to="inset(20px)"
                  begin="0s" dur="1000ms" fill="freeze"/>
              </rect>
            </svg>
        """.trimIndent()
        // 40 x 40 = 1600.
        val start = redPixels(renderAt(svg, 0))
        assertTrue("start area: $start, want 1200..2100", start in 1200..2100)
        // 100 x 100 = 10000.
        val mid = redPixels(renderAt(svg, 500))
        assertTrue("mid area: $mid, want 9500..10500", mid in 9500..10500)
        // 160 x 160 = 25600.
        val end = redPixels(renderAt(svg, 1000))
        assertTrue("end area: $end, want 25000..26200", end in 25000..26200)
    }

    @Test
    fun toOnlyResolvesAgainstBase() {
        val svg = """
            <svg xmlns="http://www.w3.org/2000/svg" width="200" height="200" viewBox="0 0 200 200">
              <rect width="200" height="200" fill="red" clip-path="circle(10px at center center)">
                <animate attributeName="clip-path" to="circle(90px at center center)"
                  begin="0s" dur="1000ms" fill="freeze"/>
              </rect>
            </svg>
        """.trimIndent()
        val start = redPixels(renderAt(svg, 0))
        assertTrue("start area: $start, want 150..600", start in 150..600)
        val mid = redPixels(renderAt(svg, 500))
        assertTrue("mid area: $mid, want 7000..8700", mid in 7000..8700)
        val end = redPixels(renderAt(svg, 1000))
        assertTrue("end area: $end, want 24000..27000", end in 24000..27000)
    }

    @Test
    fun mismatchedShapesStayDiscrete() {
        val svg = """
            <svg xmlns="http://www.w3.org/2000/svg" width="200" height="200" viewBox="0 0 200 200">
              <rect width="200" height="200" fill="red" clip-path="circle(50px at center center)">
                <animate attributeName="clip-path" calcMode="discrete"
                  values="circle(50px at center center);inset(50px 50px 50px 50px);inset(50px 50px 50px 50px)"
                  keyTimes="0;0.5;1" begin="0s" dur="1000ms" fill="freeze"/>
              </rect>
            </svg>
        """.trimIndent()
        // pi * 50^2 ~= 7854 while the circle holds.
        val first = redPixels(renderAt(svg, 250))
        assertTrue("first area: $first, want 7000..8700", first in 7000..8700)
        // 100 x 100 = 10000 after the switch.
        val second = redPixels(renderAt(svg, 750))
        assertTrue("second area: $second, want 9500..10500", second in 9500..10500)
    }

    @Test
    fun urlToNoneRevealsAndReverts() {
        val svg = """
            <svg xmlns="http://www.w3.org/2000/svg" width="200" height="200" viewBox="0 0 200 200">
              <defs>
                <clipPath id="c"><rect x="50" y="50" width="100" height="100"/></clipPath>
              </defs>
              <rect width="200" height="200" fill="red" clip-path="url(#c)">
                <animate attributeName="clip-path" from="url(#c)" to="none"
                  begin="0s" dur="1000ms" fill="freeze"/>
              </rect>
            </svg>
        """.trimIndent()
        // 100 x 100 = 10000 while the url clip holds.
        val start = redPixels(renderAt(svg, 0))
        assertTrue("start area: $start, want 9500..10500", start in 9500..10500)
        // `none` means no clipping: the full 200 x 200 shows.
        val end = redPixels(renderAt(svg, 1000))
        assertTrue("end area: $end, want 39500..40000", end in 39500..40000)
    }

    @Test
    fun fillRemoveRevertsToBaseClip() {
        val svg = """
            <svg xmlns="http://www.w3.org/2000/svg" width="200" height="200" viewBox="0 0 200 200">
              <rect width="200" height="200" fill="red" clip-path="circle(10px at center center)">
                <animate attributeName="clip-path" from="circle(10px at center center)" to="circle(90px at center center)"
                  begin="0s" dur="1000ms"/>
              </rect>
            </svg>
        """.trimIndent()
        val mid = redPixels(renderAt(svg, 500))
        assertTrue("mid area: $mid, want 7000..8700", mid in 7000..8700)
        // Default fill="remove": the base clip returns after the end.
        val end = redPixels(renderAt(svg, 1500))
        assertTrue("reverted area: $end, want 150..600", end in 150..600)
    }

    @Test
    fun invalidValuesDropAnimation() {
        val svg = """
            <svg xmlns="http://www.w3.org/2000/svg" width="200" height="200" viewBox="0 0 200 200">
              <rect width="200" height="200" fill="red" clip-path="circle(10px at center center)">
                <animate attributeName="clip-path" values="circle(10px at center center);garbage("
                  begin="0s" dur="1000ms" fill="freeze"/>
              </rect>
            </svg>
        """.trimIndent()
        val mid = redPixels(renderAt(svg, 500))
        assertTrue("base area: $mid, want 150..600", mid in 150..600)
    }

    @Test
    fun setSwitchesClipDiscretely() {
        val svg = """
            <svg xmlns="http://www.w3.org/2000/svg" width="200" height="200" viewBox="0 0 200 200">
              <rect width="200" height="200" fill="red" clip-path="circle(50px at center center)">
                <set attributeName="clip-path" to="inset(50px 50px 50px 50px)" begin="500ms"/>
              </rect>
            </svg>
        """.trimIndent()
        val before = redPixels(renderAt(svg, 250))
        assertTrue("before area: $before, want 7000..8700", before in 7000..8700)
        val after = redPixels(renderAt(svg, 750))
        assertTrue("after area: $after, want 9500..10500", after in 9500..10500)
    }
}
