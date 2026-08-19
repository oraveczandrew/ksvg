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
import hu.oandras.ksvg.dom.SVGImpl
import hu.oandras.ksvg.mocks.MockCanvas
import hu.oandras.ksvg.mocks.MockPaint
import hu.oandras.ksvg.mocks.MockPath
import hu.oandras.ksvg.mocks.asShadow
import hu.oandras.ksvg.render.animation.normalizeDashArrays
import hu.oandras.ksvg.render.animation.parseDashArrayKeyframes
import hu.oandras.ksvg.render.createBitmap
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(manifest = Config.NONE, shadows = [MockCanvas::class, MockPath::class, MockPaint::class])
class StrokeDashArrayAnimationTest {

    @Test
    fun parseDashArrayKeyframes_singleValues() {
        val keyframes = parseDashArrayKeyframes("10;20;30")
        assertEquals(3, keyframes.size)
        assertArrayEquals(floatArrayOf(10f), keyframes[0])
        assertArrayEquals(floatArrayOf(20f), keyframes[1])
        assertArrayEquals(floatArrayOf(30f), keyframes[2])
    }

    @Test
    fun parseDashArrayKeyframes_commaSeparated() {
        val keyframes = parseDashArrayKeyframes("5,10;20,5;5,10")
        assertEquals(3, keyframes.size)
        assertArrayEquals(floatArrayOf(5f, 10f), keyframes[0])
        assertArrayEquals(floatArrayOf(20f, 5f), keyframes[1])
        assertArrayEquals(floatArrayOf(5f, 10f), keyframes[2])
    }

    @Test
    fun parseDashArrayKeyframes_spaceSeparated() {
        val keyframes = parseDashArrayKeyframes("5 10;20 5")
        assertEquals(2, keyframes.size)
        assertArrayEquals(floatArrayOf(5f, 10f), keyframes[0])
        assertArrayEquals(floatArrayOf(20f, 5f), keyframes[1])
    }

    @Test
    fun parseDashArrayKeyframes_mixedSeparators() {
        val keyframes = parseDashArrayKeyframes("5, 10; 20 ,5")
        assertEquals(2, keyframes.size)
        assertArrayEquals(floatArrayOf(5f, 10f), keyframes[0])
        assertArrayEquals(floatArrayOf(20f, 5f), keyframes[1])
    }

    @Test
    fun parseSingleDashArray() {
        val result = hu.oandras.ksvg.render.animation.parseSingleDashArray("5,10,15")
        assertArrayEquals(floatArrayOf(5f, 10f, 15f), result)
    }

    @Test
    fun parseSingleDashArray_spaceSeparated() {
        val result = hu.oandras.ksvg.render.animation.parseSingleDashArray("5 10 15")
        assertArrayEquals(floatArrayOf(5f, 10f, 15f), result)
    }

    @Test
    fun normalizeDashArrays_equalLengths() {
        val keyframes = listOf(
            floatArrayOf(5f, 10f),
            floatArrayOf(20f, 5f)
        )
        val (stride, normalized) = normalizeDashArrays(keyframes)
        assertEquals(2, stride)
        assertEquals(4, normalized.size)
        assertFloatListEquals(floatArrayOf(5f, 10f, 20f, 5f), normalized)
    }

    @Test
    fun normalizeDashArrays_unequalLengths_cycles() {
        val keyframes = listOf(
            floatArrayOf(5f),
            floatArrayOf(20f, 5f)
        )
        val (stride, normalized) = normalizeDashArrays(keyframes)
        assertEquals(2, stride)
        assertEquals(4, normalized.size)
        // [5] cycled to [5, 5], then [20, 5]
        assertFloatListEquals(floatArrayOf(5f, 5f, 20f, 5f), normalized)
    }

    @Test
    fun normalizeDashArrays_threeValueKeyframes() {
        val keyframes = listOf(
            floatArrayOf(1f),
            floatArrayOf(2f, 3f),
            floatArrayOf(4f, 5f, 6f)
        )
        val (stride, normalized) = normalizeDashArrays(keyframes)
        assertEquals(3, stride)
        assertEquals(9, normalized.size)
        // [1] cycled to [1,1,1], [2,3] cycled to [2,3,2], [4,5,6]
        assertFloatListEquals(
            floatArrayOf(1f, 1f, 1f, 2f, 3f, 2f, 4f, 5f, 6f),
            normalized
        )
    }

    @Test
    fun renderStrokeDashArrayAnimation() {
        val svg = SVG.getFromString(
            svg = """
                <svg width="200" height="50" viewBox="0 0 200 50">
                  <line x1="10" y1="25" x2="190" y2="25" stroke="black" stroke-width="4">
                    <animate attributeName="stroke-dasharray" values="10,5;5,10;10,5" dur="2s" repeatCount="indefinite"/>
                  </line>
                </svg>
            """.trimIndent(),
            parseAnimations = true
        ) as SVGImpl
        svg.animationTimeMs = 0L

        val bitmap = createBitmap(200, 50)
        val canvas = Canvas(bitmap)
        svg.renderToCanvas(canvas)

        // Verify it rendered without crashing
        val operations = canvas.asShadow().getOperations()
        assertTrue(operations.isNotEmpty())
    }

    @Test
    fun renderStrokeDashArrayAnimation_midpoint() {
        val svg = SVG.getFromString(
            svg = """
                <svg width="200" height="50" viewBox="0 0 200 50">
                  <line x1="10" y1="25" x2="190" y2="25" stroke="black" stroke-width="4">
                    <animate attributeName="stroke-dasharray" values="10,5;5,10;10,5" dur="2s" repeatCount="indefinite"/>
                  </line>
                </svg>
            """.trimIndent(),
            parseAnimations = true
        ) as SVGImpl
        svg.animationTimeMs = 500L

        val bitmap = createBitmap(200, 50)
        val canvas = Canvas(bitmap)
        svg.renderToCanvas(canvas)

        val operations = canvas.asShadow().getOperations()
        assertTrue(operations.isNotEmpty())
    }

    @Test
    fun strokeDashArrayAnimationFromTo() {
        val svg = SVG.getFromString(
            svg = """
                <svg width="200" height="50" viewBox="0 0 200 50">
                  <line x1="10" y1="25" x2="190" y2="25" stroke="black" stroke-width="4">
                    <animate attributeName="stroke-dasharray" from="10,5" to="5,10" dur="1s"/>
                  </line>
                </svg>
            """.trimIndent(),
            parseAnimations = true
        ) as SVGImpl
        svg.animationTimeMs = 0L

        val bitmap = createBitmap(200, 50)
        val canvas = Canvas(bitmap)
        svg.renderToCanvas(canvas)

        val operations = canvas.asShadow().getOperations()
        assertTrue(operations.isNotEmpty())
    }
}
