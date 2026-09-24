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
import hu.oandras.ksvg.utils.green
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.GraphicsMode

/**
 * Coverage for the dark AnimationRenderer paths (coverage round): filter
 * primitive animation (`FilterRenderNode.updateAnimations`), polygon `points`
 * animation (`withPointsAt`) and `by`-only color (`addColors`).
 *
 * NATIVE graphics, no Mock shadows — per AGENTS.md.
 */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class AnimRendererCoverageTest {

    private fun renderAt(svg: String, timeMs: Long, width: Int = 100, height: Int = 100): Bitmap {
        val parsed = SVG.getFromString(svg, parseAnimations = true) as SVGImpl
        parsed.animationTimeMs = timeMs
        val bitmap = createBitmap(width, height)
        parsed.renderToCanvas(Canvas(bitmap))
        return bitmap
    }

    @Test
    fun filterPrimitiveAnimationChangesOutput() {
        val svg = """<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">""" +
            """<defs><filter id="b"><feGaussianBlur stdDeviation="0">""" +
            """<animate attributeName="stdDeviation" values="0;6" dur="1s" fill="freeze"/>""" +
            """</feGaussianBlur></filter></defs>""" +
            """<rect x="20" y="20" width="60" height="60" fill="#FF0000" filter="url(#b)"/></svg>"""

        val sharp = renderAt(svg, 0L)
        val blurred = renderAt(svg, 1000L)
        assertFalse(sharp.sameAs(blurred))
        // Blur spreads ink outside the rect bounds.
        val ink = { b: Bitmap -> countPixels(b) { it.alpha != 0 } }
        assertTrue(ink(blurred) >= ink(sharp))
    }

    @Test
    fun pointsAnimationMovesPolygon() {
        val animated = """<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">""" +
            """<polygon points="10,10 50,10 30,50" fill="#FF0000">""" +
            """<animate attributeName="points" values="10,10 50,10 30,50;60,10 90,10 70,50" """ +
            """dur="1s" fill="freeze"/></polygon></svg>"""
        val target = """<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">""" +
            """<polygon points="60,10 90,10 70,50" fill="#FF0000"/></svg>"""

        assertTrue(renderAt(animated, 1000L).sameAs(renderAt(target, 0L)))
    }

    @Test
    fun byOnlyColorAddsToBase() {
        val animated = """<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">""" +
            """<rect x="10" y="10" width="80" height="80" fill="#FF0000">""" +
            """<animateColor attributeName="fill" by="#006600" dur="1s" fill="freeze"/>""" +
            """</rect></svg>"""
        val target = """<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">""" +
            """<rect x="10" y="10" width="80" height="80" fill="#FF6600"/></svg>"""

        assertTrue(renderAt(animated, 1000L).sameAs(renderAt(target, 0L)))
        // Base red has no green; the animated end state does.
        assertTrue(countPixels(renderAt(animated, 1000L)) { it.green > 0 } > 1000)
    }
}
