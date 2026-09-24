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
import android.graphics.Canvas
import hu.oandras.ksvg.dom.SVGImpl
import hu.oandras.ksvg.render.animation.activeDurationMs
import hu.oandras.ksvg.render.animation.completedIterations
import hu.oandras.ksvg.render.createBitmap
import hu.oandras.ksvg.test.countPixels
import hu.oandras.ksvg.utils.alpha
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.GraphicsMode

/**
 * SMIL repeat/accumulate timing: fractional repeatCount ("2.5" plays two and
 * a half iterations) and accumulate="sum" freezing at the active end (only
 * strictly-earlier full iterations count on top of the held end value).
 *
 * Render assertions pin animated frames against statically-rendered controls
 * with [Bitmap.sameAs] (NATIVE graphics, no Mock shadows — per AGENTS.md).
 */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class RepeatAccumulateAnimationTest {

    private fun renderAt(svg: String, timeMs: Long, width: Int = 200, height: Int = 100): Bitmap {
        val parsed = SVG.getFromString(svg, parseAnimations = true) as SVGImpl
        parsed.animationTimeMs = timeMs
        val bitmap = createBitmap(width, height)
        parsed.renderToCanvas(Canvas(bitmap))
        return bitmap
    }

    @Test
    fun fractionalRepeatCountPlaysPartialIteration() {
        val animated = """<svg xmlns="http://www.w3.org/2000/svg" width="200" height="100">""" +
            """<rect x="10" y="10" width="80" height="80" fill="#FF0000">""" +
            """<animate attributeName="opacity" from="0" to="1" dur="1s" """ +
            """repeatCount="2.5" fill="freeze"/></rect></svg>"""
        val opaque = """<svg xmlns="http://www.w3.org/2000/svg" width="200" height="100">""" +
            """<rect x="10" y="10" width="80" height="80" fill="#FF0000"/></svg>"""

        // Frozen past the active end (2.5s) holds the end value.
        assertTrue(renderAt(animated, 5000L).sameAs(renderAt(opaque, 0L)))
        // Mid partial iteration (2.25s): opacity 0.25 — everything drawn,
        // nothing fully opaque.
        val midBitmap = renderAt(animated, 2250L)
        assertEquals(6400, countPixels(midBitmap) { it.alpha != 0 })
        assertEquals(0, countPixels(midBitmap) { it.alpha == 255 })
        // Start of the partial iteration: opacity back at 0.
        assertEquals(0, countPixels(renderAt(animated, 2000L)) { it.alpha == 255 })
    }

    @Test
    fun accumulateFreezeCountsOnlyCompletedIterations() {
        val animated = """<svg xmlns="http://www.w3.org/2000/svg" width="300" height="100">""" +
            """<rect x="10" y="10" width="20" height="20" fill="#FF0000">""" +
            """<animateTransform attributeName="transform" type="translate" """ +
            """values="0,0;100,0" dur="1s" repeatCount="2" accumulate="sum" """ +
            """fill="freeze"/></rect></svg>"""
        // End value (100) + one completed range (100) = tx 200: rect lands at 210.
        val shifted = """<svg xmlns="http://www.w3.org/2000/svg" width="300" height="100">""" +
            """<rect x="210" y="10" width="20" height="20" fill="#FF0000"/></svg>"""

        assertTrue(renderAt(animated, 5000L, 300).sameAs(renderAt(shifted, 0L, 300)))
    }

    @Test
    fun completedIterationsCapsAtActiveEnd() {
        // dur=1s, repeatCount=2: past the end only 1 strictly-earlier iteration.
        assertEquals(1, completedIterations(5000L, 1000L, activeDurationMs(1000L, 2f, 0L)))
        // Fractional: 2.5 iterations freeze with 2 completed.
        assertEquals(2, completedIterations(5000L, 1000L, activeDurationMs(1000L, 2.5f, 0L)))
        // Single iteration freezes with none.
        assertEquals(0, completedIterations(5000L, 1000L, activeDurationMs(1000L, 1f, 0L)))
        // Mid-run: floor.
        assertEquals(1, completedIterations(1500L, 1000L, activeDurationMs(1000L, 3f, 0L)))
        // Degenerate durations never divide by zero.
        assertEquals(0, completedIterations(5000L, 0L, activeDurationMs(0L, 2f, 0L)))
        // repeatDur truncation caps like the active end.
        assertEquals(1, completedIterations(5000L, 1000L, activeDurationMs(1000L, 5f, 1500L)))
    }
}
