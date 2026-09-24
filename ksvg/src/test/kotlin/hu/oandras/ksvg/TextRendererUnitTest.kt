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

import android.graphics.Paint
import hu.oandras.ksvg.dom.core.Box
import hu.oandras.ksvg.dom.style.Style
import hu.oandras.ksvg.dom.text.BaselineShift
import hu.oandras.ksvg.dom.text.DominantBaseline
import hu.oandras.ksvg.dom.text.TextAnchor
import hu.oandras.ksvg.dom.text.TextDirection
import hu.oandras.ksvg.dom.text.TextTransform
import hu.oandras.ksvg.render.DisplayContext
import hu.oandras.ksvg.render.RendererState
import hu.oandras.ksvg.render.pool.FloatArrayBucket
import hu.oandras.ksvg.render.text.TextProcessor
import hu.oandras.ksvg.render.text.applyTextTransform
import hu.oandras.ksvg.render.text.calculateBaselineOffset
import hu.oandras.ksvg.render.text.getAnchorPosition
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import android.graphics.Canvas as AndroidCanvas

/**
 * Unit coverage for the canvas-free text helpers (coverage round): case
 * transforms, baseline/shift offsets, the x/y/dx/dy positioning stack and
 * the RTL anchor swap.
 */
@RunWith(RobolectricTestRunner::class)
class TextRendererUnitTest {

    private object TestDisplayContext : DisplayContext {
        override val dPI: Float = 160f
        override val currentFontSize: Float = 20f
        override val currentFontXHeight: Float = 10f
        override val effectiveViewPortInUserUnits: Box = Box(0f, 0f, 200f, 100f)
    }

    private class ExposedProcessor : TextProcessor() {
        fun hasAnyPositioning(): Boolean = super.hasPositioning()
        fun runApplyPositioning() = super.applyPositioning()

        context(renderContext: DisplayContext)
        override fun processText(canvas: AndroidCanvas, text: String, widths: FloatArrayBucket) = Unit
    }

    @Test
    fun textTransformCases() {
        assertEquals("ABC", applyTextTransform("abc", TextTransform.Uppercase))
        assertEquals("abc", applyTextTransform("ABC", TextTransform.Lowercase))
        assertEquals("Abc Def", applyTextTransform("abc def", TextTransform.Capitalize))
        assertEquals("aBc", applyTextTransform("aBc", TextTransform.None))
        assertEquals("aBc", applyTextTransform("aBc", null))
    }

    @Test
    fun baselineOffsetFollowsMetrics() = with(TestDisplayContext) {
        val paint = Paint()
        paint.textSize = 20f
        val fm = paint.fontMetrics
        fun styleWith(baseline: DominantBaseline) =
            Style().toBuilder().apply { dominantBaseline = baseline }.build()

        assertEquals(0f, calculateBaselineOffset(paint, Style().toBuilder().build()), 0f)
        assertEquals(
            -(fm.ascent + fm.descent) / 2f,
            calculateBaselineOffset(paint, styleWith(DominantBaseline.Middle)), 1e-3f
        )
        assertEquals(-fm.ascent, calculateBaselineOffset(paint, styleWith(DominantBaseline.Hanging)), 1e-3f)
        assertEquals(-fm.descent, calculateBaselineOffset(paint, styleWith(DominantBaseline.Ideographic)), 1e-3f)
        assertEquals(-fm.top, calculateBaselineOffset(paint, styleWith(DominantBaseline.TextTop)), 1e-3f)
        assertEquals(-fm.bottom, calculateBaselineOffset(paint, styleWith(DominantBaseline.TextBottom)), 1e-3f)
    }

    @Test
    fun baselineShiftOffsets() = with(TestDisplayContext) {
        val paint = Paint()
        paint.textSize = 20f
        fun styleWith(type: BaselineShift.Type) =
            Style().toBuilder().apply { baselineShift = BaselineShift(null, type) }.build()

        assertEquals(0f, calculateBaselineOffset(paint, Style().toBuilder().build()), 0f)
        assertEquals(20f * 0.25f, calculateBaselineOffset(paint, styleWith(BaselineShift.Type.Sub)), 1e-3f)
        assertEquals(-20f * 0.33f, calculateBaselineOffset(paint, styleWith(BaselineShift.Type.Super)), 1e-3f)
    }

    @Test
    fun positioningStackAdvancesAndExhausts() {
        val p = ExposedProcessor()
        p.x = 10f
        p.y = 20f
        p.pushPositioning(floatArrayOf(100f), null, floatArrayOf(5f), null)
        assertTrue(p.hasAnyPositioning())
        p.runApplyPositioning()
        assertEquals(105f, p.x, 0f)
        assertEquals(20f, p.y, 0f)
        assertFalse(p.hasAnyPositioning())
        p.popPositioning()
        p.runApplyPositioning()
        assertEquals(105f, p.x, 0f)
    }

    @Test
    fun anchorSwapsInRtl() {
        fun stateWith(direction: TextDirection, anchor: TextAnchor): RendererState {
            val style = Style().toBuilder().apply {
                this.direction = direction
                textAnchor = anchor
            }.build()
            return RendererState().apply { this.style = style }
        }

        assertEquals(TextAnchor.Start, stateWith(TextDirection.LTR, TextAnchor.Start).getAnchorPosition())
        assertEquals(TextAnchor.Middle, stateWith(TextDirection.RTL, TextAnchor.Middle).getAnchorPosition())
        assertEquals(TextAnchor.End, stateWith(TextDirection.RTL, TextAnchor.Start).getAnchorPosition())
        assertEquals(TextAnchor.Start, stateWith(TextDirection.RTL, TextAnchor.End).getAnchorPosition())
    }

    private fun assertTrue(value: Boolean) = org.junit.Assert.assertTrue(value)
    private fun assertFalse(value: Boolean) = org.junit.Assert.assertFalse(value)
}
