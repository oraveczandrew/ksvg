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
import hu.oandras.ksvg.render.RendererState
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotSame
import org.junit.Assert.assertSame
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

/**
 * Unit coverage for the host-less (detached) paint fallback of
 * [RendererState]. The detached paints are created on the first host-less read
 * instead of in the constructor, so these tests pin down both the laziness
 * contract (one instance, reused) and the configuration the fallback has to
 * reproduce - in particular the stroke style, which
 * `PaintConfigSync.apply` never writes.
 */
@RunWith(RobolectricTestRunner::class)
class RendererStateDetachedPaintTest {

    @Test
    fun detachedFillPaintIsCreatedOnceAndReused() {
        val state = RendererState()

        val first = state.fillPaint
        val second = state.fillPaint

        assertSame(first, second)
    }

    @Test
    fun detachedFillPaintIsNotSharedBetweenStates() {
        val first = RendererState().fillPaint
        val second = RendererState().fillPaint

        assertNotSame(first, second)
    }

    @Test
    fun detachedStrokePaintIsCreatedOnceAndReused() {
        val state = RendererState()

        val first = state.strokePaint
        val second = state.strokePaint

        assertSame(first, second)
    }

    @Test
    fun detachedPaintsAreIndependentOfEachOther() {
        val state = RendererState()

        assertNotSame(state.fillPaint, state.strokePaint)
    }

    @Test
    fun detachedStrokePaintIsStrokeStyled() {
        // PaintConfigSync.apply only carries the paint-driving configuration and
        // never writes `style`, so the detached stroke paint has to be created
        // as a STROKE-style paint.
        assertEquals(Paint.Style.STROKE, RendererState().strokePaint.style)
    }

    @Test
    fun detachedFillPaintKeepsFillStyle() {
        assertEquals(Paint.Style.FILL, RendererState().fillPaint.style)
    }

    @Test
    fun detachedFillPaintCarriesTheFillConfiguration() {
        val state = RendererState()
        state.fillConfig.color = 0xFF3366CC.toInt()
        state.fillConfig.strokeWidth = 7f
        state.fillConfig.antiAlias = true

        val paint = state.fillPaint

        assertEquals(0xFF3366CC.toInt(), paint.color)
        assertEquals(7f, paint.strokeWidth, 0.001f)
        assertEquals(true, paint.isAntiAlias)
    }

    @Test
    fun detachedFillPaintIsResyncedOnEveryRead() {
        val state = RendererState()
        state.fillConfig.color = 0xFFFF0000.toInt()

        val paint = state.fillPaint
        assertEquals(0xFFFF0000.toInt(), paint.color)

        // The fallback has no cheap diffing, so a later configuration change
        // must still be visible through the very same Paint instance.
        state.fillConfig.color = 0xFF00FF00.toInt()

        assertSame(paint, state.fillPaint)
        assertEquals(0xFF00FF00.toInt(), paint.color)
    }

    @Test
    fun detachedStrokePaintCarriesTheStrokeConfiguration() {
        val state = RendererState()
        state.strokeConfig.color = 0xFF00FF00.toInt()
        state.strokeConfig.strokeWidth = 3.5f

        val paint = state.strokePaint

        assertEquals(0xFF00FF00.toInt(), paint.color)
        assertEquals(3.5f, paint.strokeWidth, 0.001f)
        assertEquals(Paint.Style.STROKE, paint.style)
    }
}