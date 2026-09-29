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

import android.graphics.Canvas
import hu.oandras.ksvg.render.createBitmap
import hu.oandras.ksvg.test.countPixels
import hu.oandras.ksvg.utils.alpha
import hu.oandras.ksvg.utils.blue
import hu.oandras.ksvg.utils.green
import hu.oandras.ksvg.utils.red
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotSame
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.GraphicsMode

/**
 * Sharing guarantees: one parsed document feeds many independent drawables.
 */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class KSVGDrawableShareabilityTest {

    private fun opaquePixelCount(drawable: KSVGDrawable, size: Int): Int {
        val bitmap = createBitmap(size, size)
        drawable.setBounds(0, 0, size, size)
        drawable.draw(Canvas(bitmap))
        return countPixels(bitmap) { it.alpha > 0 }
    }

    @Test
    fun constantStateHandsOutIndependentDrawables() {
        val svg = SVG.getFromString(
            """<svg width="100" height="100"><rect width="100" height="100" fill="red"/></svg>"""
        )
        val first = svg.toDrawable()
        first.setBounds(0, 0, 50, 50)

        val second = first.constantState.newDrawable() as KSVGDrawable
        assertNotSame(first, second)
        // The copy starts without bounds; sizing one must not affect the other.
        assertTrue(second.bounds.isEmpty)
        assertEquals(50, first.bounds.width())

        assertTrue(opaquePixelCount(first, 50) > 0)
        assertTrue(opaquePixelCount(second, 100) > 0)
        assertEquals(50, first.bounds.width())
    }

    @Test
    fun animatedInstancesRunIndependently() {
        val svg = SVG.getFromString(
            svg = """
                <svg width="100" height="100">
                  <rect width="100" height="100" fill="red">
                    <animate attributeName="opacity" from="1" to="0" dur="1s" fill="freeze"/>
                  </rect>
                </svg>
            """.trimIndent(),
            parseAnimations = true
        )
        val first = svg.toAnimatedDrawable()
        val second = svg.toAnimatedDrawable()
        assertNotSame(first, second)

        first.start()
        second.start()
        first.stop()

        assertFalse(first.isRunning)
        assertTrue(second.isRunning)
        second.stop()
    }

    @Test
    fun renderOptionsCssDoesNotLeakAcrossDrawables() {
        val svg = SVG.getFromString(
            """<svg width="100" height="100"><rect width="100" height="100" fill="red"/></svg>"""
        )
        val overlayOptions = RenderOptions.create().css("rect { fill: rgb(0, 0, 255); }")

        fun centerOf(drawable: KSVGDrawable): Int {
            val bitmap = createBitmap(100, 100)
            drawable.setBounds(0, 0, 100, 100)
            drawable.draw(Canvas(bitmap))
            return bitmap.getPixel(50, 50)
        }

        // Overlay first, then plain: the plain drawable must still see the
        // base presentation attribute, not the other drawable's overlay.
        val overlaid = centerOf(svg.toDrawable(overlayOptions))
        assertTrue(overlaid.blue > overlaid.red)

        val plain = centerOf(svg.toDrawable())
        assertTrue(plain.red > plain.blue)
        assertTrue(plain.green < 128)

        // And the other order: plain first must not pin the overlay out.
        val overlaidAgain = centerOf(svg.toDrawable(overlayOptions))
        assertTrue(overlaidAgain.blue > overlaidAgain.red)
    }
}
