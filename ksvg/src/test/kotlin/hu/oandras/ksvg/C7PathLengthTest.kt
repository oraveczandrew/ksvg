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

import android.graphics.Canvas
import android.graphics.DashPathEffect
import hu.oandras.ksvg.mocks.MockCanvas
import hu.oandras.ksvg.mocks.MockPaint
import hu.oandras.ksvg.mocks.MockPath
import hu.oandras.ksvg.mocks.asShadow
import hu.oandras.ksvg.render.createBitmap
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * Phase 0 baseline (C7): `pathLength` is parsed but never applied.
 *
 * When `pathLength` is set on a shape, dash arrays / dash offsets must be scaled
 * by `computedPathLength / pathLength`. Today `RendererState.updateStrokeDash`
 * ignores `pathLength`, so the declared dash period is used verbatim.
 *
 * The geometry here: a straight line from (0,50) to (100,50) has computed length
 * 100; `pathLength="50"` must scale the dash array `[10, 10]` to `[20, 20]`.
 *
 * Asserts the CORRECT (post-fix) behaviour. Today it fails.
 */
@RunWith(RobolectricTestRunner::class)
@Config(manifest = Config.NONE, shadows = [MockCanvas::class, MockPath::class, MockPaint::class])
class C7PathLengthTest {

    @Test
    fun pathLengthScalesDashArray() {
        val svg = """
            <svg width="100" height="100" viewBox="0 0 100 100">
              <path d="M0 50 H100" fill="none" stroke="black" stroke-width="4"
                    stroke-dasharray="10 10" pathLength="50"/>
            </svg>
        """.trimIndent()

        val document = SVG.getFromString(svg)
        val canvas = Canvas(createBitmap(100, 100))
        document.renderToCanvas(canvas)

        val shadowPaint = canvas.asShadow().lastPathPaint?.asShadow()
        val effect = shadowPaint?.lastPathEffect
        assertTrue("Expected a DashPathEffect on the stroke paint", effect is DashPathEffect)

        val intervals = shadowPaint?.lastDashIntervals
        assertTrue("Expected dash intervals to be captured from the stroke paint", intervals != null)
        // Correct: scaled by 100/50 = 2 -> [20, 20]. Bug: unchanged [10, 10].
        assertArrayEquals(floatArrayOf(20f, 20f), intervals!!, 0.5f)
    }
}
