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
import android.graphics.drawable.Animatable2
import android.graphics.drawable.Drawable
import hu.oandras.ksvg.dom.SVGImpl
import hu.oandras.ksvg.mocks.MockCanvas
import hu.oandras.ksvg.mocks.MockPaint
import hu.oandras.ksvg.mocks.MockPath
import hu.oandras.ksvg.mocks.asShadow
import hu.oandras.ksvg.render.createBitmap
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(manifest = Config.NONE, shadows = [MockCanvas::class, MockPath::class, MockPaint::class])
class DrawableAnimationTest {

    @Test
    fun toDrawableReturnsDrawable() {
        val svg = SVG.getFromString(
            svg = """<svg width="10" height="10"><rect width="10" height="10"/></svg>""",
            parseAnimations = true
        )

        assertTrue(svg.toDrawable() is KSVGDrawable)
    }

    @Test
    fun toAnimatedDrawableReturnsAnimatable2() {
        val svg =
            SVG.getFromString(
                svg = """<svg width="10" height="10"><rect width="10" height="10"/></svg>""",
                parseAnimations = true
            )

        val drawable: Drawable = svg.toAnimatedDrawable()
        assertIs<Animatable2>(drawable)
    }

    @Test
    fun renderAppliesAnimateTransformAtCurrentTime() {
        val svg = SVG.getFromString(
            svg = """
                    <svg width="20" height="20" viewBox="0 0 20 20">
                      <g>
                        <animateTransform attributeName="transform" type="translate" values="0 0;10 0" dur="1s"/>
                        <rect width="10" height="10"/>
                      </g>
                    </svg>
                    """.trimIndent(),
            parseAnimations = true
        ) as SVGImpl
        svg.animationTimeMs = 500L

        val bitmap = createBitmap(20, 20)
        val canvas = Canvas(bitmap)
        svg.renderToCanvas(canvas)

        val operations = canvas.asShadow().getOperations()
        assertTrue(operations.contains("concat(Matrix(1 0 0 1 5 0))"))
    }
}
