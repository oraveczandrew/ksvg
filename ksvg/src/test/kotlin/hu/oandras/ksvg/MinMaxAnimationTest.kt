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
 * SMIL `min`/`max` active-duration constraints and `restart` parsing.
 *
 * `max` cuts a long active period short (then `fill` applies); `min`
 * extends a short one holding the end value without re-repeating (so the
 * discriminating case is fill="remove", where the unconstrained animation
 * would already be gone). `restart` is parsed but inert on the
 * single-begin timeline: any value renders like the default.
 *
 * Render assertions use NATIVE graphics with pixel counts (per AGENTS.md).
 */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class MinMaxAnimationTest {

    private fun renderAt(svg: String, timeMs: Long, width: Int = 200, height: Int = 100): Bitmap {
        val parsed = SVG.getFromString(svg, parseAnimations = true) as SVGImpl
        parsed.animationTimeMs = timeMs
        val bitmap = createBitmap(width, height)
        parsed.renderToCanvas(Canvas(bitmap))
        return bitmap
    }

    private fun opacityRect(extraAnimateAttrs: String): String {
        return """<svg xmlns="http://www.w3.org/2000/svg" width="200" height="100">""" +
            """<rect x="10" y="10" width="80" height="80" fill="#FF0000">""" +
            """<animate attributeName="opacity" $extraAnimateAttrs/></rect></svg>"""
    }

    @Test
    fun maxCutsActiveDurationShort() {
        val cut = opacityRect("""from="0" to="1" dur="2s" fill="freeze" max="1s" """)
        val opaque = """<svg xmlns="http://www.w3.org/2000/svg" width="200" height="100">""" +
            """<rect x="10" y="10" width="80" height="80" fill="#FF0000"/></svg>"""
        // Past max (1s) the frozen end value holds: fully opaque.
        assertTrue(renderAt(cut, 1500L).sameAs(renderAt(opaque, 0L)))
    }

    @Test
    fun maxControlWithoutMaxIsMidFlight() {
        val plain = opacityRect("""from="0" to="1" dur="2s" fill="freeze"""")
        // 1.5s of 2s: opacity 0.75 — nothing fully opaque, nothing transparent.
        val mid = renderAt(plain, 1500L)
        assertEquals(6400, countPixels(mid) { it.alpha != 0 })
        assertEquals(0, countPixels(mid) { it.alpha == 255 })
    }

    @Test
    fun minExtendsActiveHoldWithoutRefreeze() {
        // Fade-out, fill=remove (default): unconstrained it is gone by 2s
        // (base opacity back to 1); min=4s holds the end (0) instead.
        val held = opacityRect("""from="1" to="0" dur="2s" min="4s"""")
        assertEquals(0, countPixels(renderAt(held, 3000L)) { it.alpha != 0 })
    }

    @Test
    fun minControlWithoutMinIsRemoved() {
        val plain = opacityRect("""from="1" to="0" dur="2s"""")
        // Finished + remove: base opacity 1, rect fully visible again.
        assertEquals(6400, countPixels(renderAt(plain, 3000L)) { it.alpha == 255 })
    }

    @Test
    fun inconsistentMinMaxAreIgnored() {
        // min > max: both ignored, raw 2s active applies (progress 0.75 at 1.5s).
        valoddMinMaxIgnored()
    }

    private fun valoddMinMaxIgnored() {
        val odd = opacityRect("""from="1" to="0" dur="2s" min="5s" max="1s"""")
        val mid = renderAt(odd, 1500L)
        assertEquals(6400, countPixels(mid) { it.alpha != 0 })
        assertEquals(0, countPixels(mid) { it.alpha == 255 })
    }

    @Test
    fun restartValuesRenderLikeDefault() {
        val base = opacityRect("""from="0" to="1" dur="2s"""")
        val never = opacityRect("""from="0" to="1" dur="2s" restart="never"""")
        val whenNotActive = opacityRect("""from="0" to="1" dur="2s" restart="whenNotActive"""")
        val invalid = opacityRect("""from="0" to="1" dur="2s" restart="sometimes"""")
        val expected = renderAt(base, 500L)
        assertTrue(renderAt(never, 500L).sameAs(expected))
        assertTrue(renderAt(whenNotActive, 500L).sameAs(expected))
        assertTrue(renderAt(invalid, 500L).sameAs(expected))
    }
}
