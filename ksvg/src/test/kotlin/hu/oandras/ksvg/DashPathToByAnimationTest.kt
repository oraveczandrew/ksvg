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
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.GraphicsMode

/**
 * SMIL to-only / by-only remainder (float/color pattern transplanted):
 * stroke-dasharray and path `d` resolve against the base value at apply time
 * instead of freezing at (or dropping) the endpoint.
 *
 * Assertions pin animated frames against statically-rendered controls with
 * [Bitmap.sameAs] (NATIVE graphics, no Mock shadows — per AGENTS.md).
 */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class DashPathToByAnimationTest {

    private fun renderAt(svg: String, timeMs: Long, width: Int = 200, height: Int = 50): Bitmap {
        val parsed = SVG.getFromString(svg, parseAnimations = true) as SVGImpl
        parsed.animationTimeMs = timeMs
        val bitmap = createBitmap(width, height)
        parsed.renderToCanvas(Canvas(bitmap))
        return bitmap
    }

    private fun lineSvg(dash: String, anim: String): String {
        return """<svg xmlns="http://www.w3.org/2000/svg" width="200" height="50">""" +
            """<line x1="10" y1="25" x2="190" y2="25" stroke="black" stroke-width="4" """ +
            """stroke-dasharray="$dash">$anim</line></svg>"""
    }

    private fun dashAnim(spec: String): String {
        return """<animate attributeName="stroke-dasharray" $spec dur="1s" fill="freeze"/>"""
    }

    @Test
    fun dashToOnlyRampsBaseToTarget() {
        val animated = lineSvg("10,5", dashAnim("""to="20,10""""))
        val base = lineSvg("10,5", "")
        val target = lineSvg("20,10", "")

        assertTrue(renderAt(animated, 0L).sameAs(renderAt(base, 0L)))
        assertTrue(renderAt(animated, 1000L).sameAs(renderAt(target, 0L)))
        assertFalse(renderAt(animated, 500L).sameAs(renderAt(base, 0L)))
        assertFalse(renderAt(animated, 500L).sameAs(renderAt(target, 0L)))
    }

    @Test
    fun dashByOnlyAddsToBase() {
        val animated = lineSvg("10,5", dashAnim("""by="4,2""""))
        val target = lineSvg("14,7", "")

        assertTrue(renderAt(animated, 1000L).sameAs(renderAt(target, 0L)))
    }

    @Test
    fun dashToOnlyAdditiveSumsOntoBase() {
        val animated = lineSvg("10,5", """<animate attributeName="stroke-dasharray" to="20,10" additive="sum" dur="1s" fill="freeze"/>""")
        // base + to * 0.5 = [20, 10] at the midpoint.
        val mid = lineSvg("20,10", "")

        assertTrue(renderAt(animated, 500L).sameAs(renderAt(mid, 0L)))
    }

    @Test
    fun pathToOnlyRampsBaseToTarget() {
        fun pathSvg(d: String, anim: String): String {
            return """<svg xmlns="http://www.w3.org/2000/svg" width="200" height="50">""" +
                """<path d="$d" fill="none" stroke="black" stroke-width="4">$anim</path></svg>"""
        }
        val animated = pathSvg(
            "M10,25 L100,25",
            """<animate attributeName="d" to="M10,25 L190,25" dur="1s" fill="freeze"/>"""
        )
        val base = pathSvg("M10,25 L100,25", "")
        val target = pathSvg("M10,25 L190,25", "")

        assertTrue(renderAt(animated, 0L).sameAs(renderAt(base, 0L)))
        assertTrue(renderAt(animated, 1000L).sameAs(renderAt(target, 0L)))
        assertFalse(renderAt(animated, 500L).sameAs(renderAt(base, 0L)))
    }
}
