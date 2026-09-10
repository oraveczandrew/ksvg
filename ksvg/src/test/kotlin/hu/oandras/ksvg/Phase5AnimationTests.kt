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
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode

@RunWith(RobolectricTestRunner::class)
@Config(manifest = Config.NONE)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class Phase5AnimationTests {

    private fun renderAt(svg: String, timeMs: Long): Bitmap {
        val doc = SVG.getFromString(svg, parseAnimations = true) as SVGImpl
        doc.animationTimeMs = timeMs
        val bitmap = createBitmap(120, 120)
        doc.renderToCanvas(Canvas(bitmap))
        return bitmap
    }


    // --- <set> honors begin/end; default fill="remove" reverts afterwards ---

    @Test
    fun setElementHidesDuringActiveIntervalOnly() {
        val svg = """
            <svg width="120" height="120" xmlns="http://www.w3.org/2000/svg">
              <rect x="10" y="10" width="100" height="100" fill="red">
                <set attributeName="opacity" to="0" begin="100ms" end="200ms"/>
              </rect>
            </svg>
        """.trimIndent()

        assertTrue("Visible before begin", isRed(renderAt(svg, 0), 60, 60))
        assertTrue("Hidden during active interval", !isRed(renderAt(svg, 150), 60, 60))
        assertTrue("Visible again after end (fill=remove)", isRed(renderAt(svg, 300), 60, 60))
    }

    // --- <animate> interpolates between values ---

    @Test
    fun animateOpacityInterpolates() {
        val svg = """
            <svg width="120" height="120" xmlns="http://www.w3.org/2000/svg">
              <rect x="10" y="10" width="100" height="100" fill="red" opacity="0">
                <animate attributeName="opacity" from="0" to="1"
                         begin="0s" dur="200ms" fill="freeze"/>
              </rect>
            </svg>
        """.trimIndent()

        fun alpha(b: Bitmap) = (b.getPixel(60, 60) ushr 24) and 0xff
        val start = alpha(renderAt(svg, 0))
        val mid = alpha(renderAt(svg, 100))
        val end = alpha(renderAt(svg, 250))
        assertTrue("t=0 must be transparent", start < 20)
        assertInRange("mid must be between endpoints", 90, 165, mid)
        assertTrue("frozen end must be opaque", end > 235)
        assertStrictlyIncreasing("opacity must increase over time", start, mid, end)
    }

    // --- animateTransform with fill=freeze keeps the final transform ---

    @Test
    fun animateTransformFreezesAtEnd() {
        val svg = """
            <svg width="120" height="120" xmlns="http://www.w3.org/2000/svg">
              <g transform="translate(10,10)">
                <rect x="0" y="0" width="40" height="40" fill="red">
                  <animateTransform attributeName="transform" type="translate"
                                    from="0 0" to="50 50" begin="0s" dur="100ms"
                                    fill="freeze"/>
                </rect>
              </g>
            </svg>
        """.trimIndent()

        // Rect starts at (10..50); frozen at translate(50,50) -> occupies (60..100).
        val before = renderAt(svg, 0)
        assertTrue(isRed(before, 30, 30))
        assertTrue(!isRed(before, 80, 80))

        val after = renderAt(svg, 200)
        assertTrue("Frozen transform must move the rect", isRed(after, 80, 80))
        assertTrue(!isRed(after, 20, 20))
    }

    // --- repeatCount repeats the active duration ---

    @Test
    fun repeatCountRestartsAnimation() {
        val svg = """
            <svg width="120" height="120" xmlns="http://www.w3.org/2000/svg">
              <rect x="10" y="10" width="100" height="100" fill="red" opacity="0">
                <animate attributeName="opacity" from="0" to="1"
                         begin="0s" dur="100ms" repeatCount="2"/>
              </rect>
            </svg>
        """.trimIndent()

        fun alpha(b: Bitmap) = (b.getPixel(60, 60) ushr 24) and 0xff
        // t=150ms is inside the SECOND repetition, halfway -> ~0.5.
        val secondPass = alpha(renderAt(svg, 150))
        assertInRange("Second repetition must restart interpolation", 90, 165, secondPass)
        // After both repetitions (no freeze) the value reverts to the base.
        val afterAll = alpha(renderAt(svg, 400))
        assertTrue("After last repetition without freeze, base applies: $afterAll", afterAll < 20)
    }
}
