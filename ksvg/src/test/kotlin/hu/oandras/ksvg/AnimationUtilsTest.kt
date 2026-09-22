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

import androidx.collection.mutableFloatListOf
import androidx.collection.mutableIntListOf
import hu.oandras.ksvg.dom.core.SVGAttr
import hu.oandras.ksvg.render.animation.applySplineInterpolation
import hu.oandras.ksvg.render.animation.isColorAttribute
import hu.oandras.ksvg.render.animation.parseKeySplines
import hu.oandras.ksvg.render.animation.selectAnimationSegmentDiscrete
import hu.oandras.ksvg.utils.CubicBezier
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class AnimationUtilsTest {

    @Test
    fun testParseKeySplines() {
        val keySplines = ".42 0 .58 1; .42 0 .58 1"
        val result = parseKeySplines(keySplines)
        assertNotNull(result)
        assertEquals(2, result?.size)

        val first = result!![0]
        assertEquals(0.42f, first.x1, 0.001f)
        assertEquals(0f, first.y1, 0.001f)
        assertEquals(0.58f, first.x2, 0.001f)
        assertEquals(1f, first.y2, 0.001f)

        val second = result[1]
        assertEquals(0.42f, second.x1, 0.001f)
        assertEquals(0f, second.y1, 0.001f)
        assertEquals(0.58f, second.x2, 0.001f)
        assertEquals(1f, second.y2, 0.001f)
    }

    @Test
    fun testParseKeySplinesWithExtraSpaces() {
        val keySplines = "  0.1 0.2  0.3 0.4 ;  0.5 0.6 0.7 0.8  "
        val result = parseKeySplines(keySplines)
        assertNotNull(result)
        assertEquals(2, result?.size)

        val first = result!![0]
        assertEquals(0.1f, first.x1, 0.001f)
        assertEquals(0.2f, first.y1, 0.001f)
        assertEquals(0.3f, first.x2, 0.001f)
        assertEquals(0.4f, first.y2, 0.001f)

        val second = result[1]
        assertEquals(0.5f, second.x1, 0.001f)
        assertEquals(0.6f, second.y1, 0.001f)
        assertEquals(0.7f, second.x2, 0.001f)
        assertEquals(0.8f, second.y2, 0.001f)
    }

    @Test
    fun testParseKeySplinesNullOrEmpty() {
        assertNull(parseKeySplines(null))
        assertNull(parseKeySplines(""))
        assertNull(parseKeySplines("   "))
    }

    @Test
    fun testCubicBezierSolveY() {
        // Standard ease-in-out cubic bezier
        val bezier = CubicBezier(0.42f, 0f, 0.58f, 1f)

        // At y=0, t should be 0
        val t0 = bezier.solveY(0f)
        assertEquals(0f, t0, 0.01f)

        // At y=1, t should be 1
        val t1 = bezier.solveY(1f)
        assertEquals(1f, t1, 0.01f)

        // At y=0.5, t should be around 0.5 for symmetric ease-in-out
        val tHalf = bezier.solveY(0.5f)
        assertEquals(0.5f, tHalf, 0.05f)
    }

    @Test
    fun testApplySplineInterpolation() {
        // Standard ease-in-out cubic bezier
        val bezier = CubicBezier(0.42f, 0f, 0.58f, 1f)

        // Test spline interpolation at various progress values
        val p0 = applySplineInterpolation(0f, bezier)
        assertEquals(0f, p0, 0.01f)

        val p1 = applySplineInterpolation(1f, bezier)
        assertEquals(1f, p1, 0.01f)

        // At 0.5 progress, for symmetric ease-in-out, should be close to 0.5
        val pHalf = applySplineInterpolation(0.5f, bezier)
        assertEquals(0.5f, pHalf, 0.05f)
    }

    @Test
    fun testSelectAnimationSegmentDiscrete_floatList() {
        val values = mutableFloatListOf(0f, 50f, 100f)

        // SMIL discrete: values[0] holds at t=0
        val r0 = selectAnimationSegmentDiscrete(values, null, 0.0f)
        assertEquals(0f, r0, 0.001f)

        // At progress 0.5 (default keyTime of the middle value) -> second value
        val r1 = selectAnimationSegmentDiscrete(values, null, 0.5f)
        assertEquals(50f, r1, 0.001f)

        // At progress 1, should be at last value
        val r2 = selectAnimationSegmentDiscrete(values, null, 1.0f)
        assertEquals(100f, r2, 0.001f)
    }

    @Test
    fun testSelectAnimationSegmentDiscrete_floatList_withKeyTimes() {
        val values = mutableFloatListOf(0f, 50f, 100f)
        val keyTimes = mutableFloatListOf(0f, 0.3f, 1.0f)

        // Before first keyTime boundary -> first value (SMIL discrete)
        val r0 = selectAnimationSegmentDiscrete(values, keyTimes, 0.1f)
        assertEquals(0f, r0, 0.001f)

        // Inside second interval [0.3, 1.0) -> second value (SMIL discrete)
        val r1 = selectAnimationSegmentDiscrete(values, keyTimes, 0.5f)
        assertEquals(50f, r1, 0.001f)

        // At end
        val r2 = selectAnimationSegmentDiscrete(values, keyTimes, 1.0f)
        assertEquals(100f, r2, 0.001f)
    }

    @Test
    fun testSelectAnimationSegmentDiscrete_intList() {
        val values = mutableIntListOf(0xFF0000.toInt(), 0x00FF00.toInt(), 0x0000FF.toInt())

        val r0 = selectAnimationSegmentDiscrete(values, null, 0.0f)
        assertEquals(0xFF0000.toInt(), r0)

        val r1 = selectAnimationSegmentDiscrete(values, null, 0.5f)
        assertEquals(0x00FF00.toInt(), r1)

        val r2 = selectAnimationSegmentDiscrete(values, null, 1.0f)
        assertEquals(0x0000FF.toInt(), r2)
    }

    @Test
    fun testIsColorAttribute() {
        assertTrue(isColorAttribute(SVGAttr.fill))
        assertTrue(isColorAttribute(SVGAttr.stroke))
        assertTrue(isColorAttribute(SVGAttr.stop_color))
        assertTrue(isColorAttribute(SVGAttr.flood_color))
        assertTrue(isColorAttribute(SVGAttr.color))
        assertTrue(isColorAttribute(SVGAttr.lighting_color))
        assertTrue(isColorAttribute(SVGAttr.solid_color))
        assertTrue(!isColorAttribute(SVGAttr.opacity))
        assertTrue(!isColorAttribute(SVGAttr.stroke_width))
        assertTrue(!isColorAttribute(SVGAttr.font_size))
    }
}