package hu.oandras.ksvg

import androidx.collection.mutableFloatListOf
import androidx.collection.mutableIntListOf
import hu.oandras.ksvg.render.animation.calculateProgress
import hu.oandras.ksvg.render.animation.computePacedKeyTimesColor
import hu.oandras.ksvg.render.animation.computePacedKeyTimesFloat
import hu.oandras.ksvg.render.animation.interpolate
import hu.oandras.ksvg.render.animation.isFinished
import hu.oandras.ksvg.render.animation.normalizeDashArrays
import hu.oandras.ksvg.render.animation.parseClockValueMillis
import hu.oandras.ksvg.render.animation.parseDashArrayKeyframes
import hu.oandras.ksvg.render.animation.parseSingleDashArray
import hu.oandras.ksvg.render.animation.selectAnimationSegmentDiscrete
import hu.oandras.ksvg.utils.CubicBezier
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class AnimationUtilsExtendedTest {

    // --- interpolate ---

    @Test
    fun testInterpolateZero() {
        assertEquals(0f, interpolate(0f, 10f, 0f), 0.001f)
    }

    @Test
    fun testInterpolateOne() {
        assertEquals(10f, interpolate(0f, 10f, 1f), 0.001f)
    }

    @Test
    fun testInterpolateHalf() {
        assertEquals(5f, interpolate(0f, 10f, 0.5f), 0.001f)
    }

    @Test
    fun testInterpolateSameValues() {
        assertEquals(5f, interpolate(5f, 5f, 0.5f), 0.001f)
    }

    @Test
    fun testInterpolateNegative() {
        assertEquals(-5f, interpolate(0f, -10f, 0.5f), 0.001f)
    }

    // --- CubicBezier ---

    @Test
    fun testCubicBezierEvaluateAtZero() {
        val bezier = CubicBezier(0.42f, 0f, 0.58f, 1f)
        assertEquals(0f, bezier.evaluate(0f), 0.01f)
    }

    @Test
    fun testCubicBezierEvaluateAtOne() {
        val bezier = CubicBezier(0.42f, 0f, 0.58f, 1f)
        assertEquals(1f, bezier.evaluate(1f), 0.01f)
    }

    @Test
    fun testCubicBezierEvaluateLinear() {
        // CubicBezier(0,0,1,1) evaluates as y/x, so evaluate(0.5) = 1.0
        val bezier = CubicBezier(0f, 0f, 1f, 1f)
        assertEquals(1f, bezier.evaluate(0.5f), 0.01f)
    }

    @Test
    fun testCubicBezierDataClass() {
        val b1 = CubicBezier(0.1f, 0.2f, 0.3f, 0.4f)
        val b2 = CubicBezier(0.1f, 0.2f, 0.3f, 0.4f)
        assertEquals(b1, b2)
    }

    // --- parseClockValueMillis ---

    @Test
    fun testParseClockValueMillisMs() {
        assertEquals(500L, parseClockValueMillis("500ms"))
    }

    @Test
    fun testParseClockValueMillisS() {
        assertEquals(2000L, parseClockValueMillis("2s"))
    }

    @Test
    fun testParseClockValueMillisPlain() {
        assertEquals(1500L, parseClockValueMillis("1500"))
    }

    @Test
    fun testParseClockValueMillisZero() {
        assertEquals(0L, parseClockValueMillis("0ms"))
    }

    @Test
    fun testParseClockValueMillisWithSpaces() {
        assertEquals(500L, parseClockValueMillis(" 500ms "))
    }

    @Test
    fun testParseClockValueMillisInvalid() {
        assertEquals(0L, parseClockValueMillis("abc"))
    }

    // --- calculateProgress ---

    @Test
    fun testCalculateProgressZeroDuration() {
        assertEquals(1f, calculateProgress(0, 1, 0, 0))
    }

    @Test
    fun testCalculateProgressHalfway() {
        assertEquals(0.5f, calculateProgress(1000, 1, 0, 500))
    }

    @Test
    fun testCalculateProgressAtEnd() {
        assertEquals(1f, calculateProgress(1000, 1, 0, 1000))
    }

    @Test
    fun testCalculateProgressWithRepeat() {
        // duration=1000, repeatCount=3, total=3000
        // elapsed=1500 -> 1500 % 1000 = 500 -> 500/1000 = 0.5
        assertEquals(0.5f, calculateProgress(1000, 3, 0, 1500))
    }

    @Test
    fun testCalculateProgressExceedsDuration() {
        assertEquals(1f, calculateProgress(1000, 1, 0, 2000))
    }

    @Test
    fun testCalculateProgressRepeatDurLimits() {
        // dur=1000, repeatCount=3, repeatDur=1500, activeDur=min(3000,1500)=1500
        // elapsed=1500 -> 1f (at end)
        assertEquals(1f, calculateProgress(1000, 3, 1500, 1500))
    }

    // --- isFinished ---

    @Test
    fun testIsFinishedAnimationTimeExceedsEnd() {
        assertTrue(isFinished(1000, 1, 0, 500, 600, 600))
    }

    @Test
    fun testIsFinishedAnimationTimeBeforeEnd() {
        assertFalse(isFinished(1000, 1, 0, 500, 400, 400))
    }

    @Test
    fun testIsFinishedElapsedExceedsActiveDur() {
        assertTrue(isFinished(1000, 1, 0, Long.MAX_VALUE, 0, 1001))
    }

    @Test
    fun testIsFinishedElapsedWithinActiveDur() {
        assertFalse(isFinished(1000, 2, 0, Long.MAX_VALUE, 0, 1500))
    }

    // --- parseDashArrayKeyframes ---

    @Test
    fun testParseDashArrayKeyframesSimple() {
        val result = parseDashArrayKeyframes("5 10; 3 6")
        assertEquals(2, result.size)
        assertArrayEquals(floatArrayOf(5f, 10f), result[0], 0.001f)
        assertArrayEquals(floatArrayOf(3f, 6f), result[1], 0.001f)
    }

    @Test
    fun testParseDashArrayKeyframesEmpty() {
        val result = parseDashArrayKeyframes("")
        assertEquals(0, result.size)
    }

    @Test
    fun testParseDashArrayKeyframesSingle() {
        val result = parseDashArrayKeyframes("5 10")
        assertEquals(1, result.size)
        assertArrayEquals(floatArrayOf(5f, 10f), result[0], 0.001f)
    }

    // --- normalizeDashArrays ---

    @Test
    fun testNormalizeDashArraysEmpty() {
        val (stride, list) = normalizeDashArrays(emptyList())
        assertEquals(0, stride)
        assertEquals(0, list.size)
    }

    @Test
    fun testNormalizeDashArraysSingle() {
        val (stride, list) = normalizeDashArrays(listOf(floatArrayOf(5f, 10f)))
        assertEquals(2, stride)
        assertEquals(2, list.size)
        assertEquals(5f, list[0], 0f)
        assertEquals(10f, list[1], 0f)
    }

    @Test
    fun testNormalizeDashArraysDifferentLengths() {
        val (stride, list) = normalizeDashArrays(listOf(floatArrayOf(1f), floatArrayOf(2f, 3f)))
        assertEquals(2, stride)
        assertEquals(4, list.size)
        // First keyframe: [1, 1] (repeated)
        assertEquals(1f, list[0], 0f)
        assertEquals(1f, list[1], 0f)
        // Second keyframe: [2, 3]
        assertEquals(2f, list[2], 0f)
        assertEquals(3f, list[3], 0f)
    }

    // --- parseSingleDashArray ---

    @Test
    fun testParseSingleDashArray() {
        val result = parseSingleDashArray("5 10 15")
        assertEquals(3, result.size)
        assertEquals(5f, result[0], 0f)
        assertEquals(10f, result[1], 0f)
        assertEquals(15f, result[2], 0f)
    }

    @Test
    fun testParseSingleDashArrayEmpty() {
        val result = parseSingleDashArray("")
        assertEquals(0, result.size)
    }

    @Test
    fun testParseSingleDashArrayCommaSeparated() {
        val result = parseSingleDashArray("5,10,15")
        assertEquals(3, result.size)
    }

    // --- computePacedKeyTimesFloat ---

    @Test
    fun testComputePacedKeyTimesFloatNull() {
        assertNull(computePacedKeyTimesFloat(mutableFloatListOf()))
    }

    @Test
    fun testComputePacedKeyTimesFloatSingle() {
        assertNull(computePacedKeyTimesFloat(mutableFloatListOf(5f)))
    }

    @Test
    fun testComputePacedKeyTimesFloatTwo() {
        val result = computePacedKeyTimesFloat(mutableFloatListOf(0f, 10f))
        assertNotNull(result)
        assertEquals(2, result.size)
        assertEquals(0f, result[0], 0.001f)
        assertEquals(1f, result[1], 0.001f)
    }

    @Test
    fun testComputePacedKeyTimesFloatThree() {
        val result = computePacedKeyTimesFloat(mutableFloatListOf(0f, 5f, 15f))
        assertNotNull(result)
        assertEquals(3, result.size)
        assertEquals(0f, result[0], 0.001f)
        assertEquals(0.333f, result[1], 0.001f)
        assertEquals(1f, result[2], 0.001f)
    }

    @Test
    fun testComputePacedKeyTimesFloatAllSame() {
        assertNull(computePacedKeyTimesFloat(mutableFloatListOf(5f, 5f, 5f)))
    }

    // --- computePacedKeyTimesColor ---

    @Test
    fun testComputePacedKeyTimesColorNull() {
        assertNull(computePacedKeyTimesColor(mutableIntListOf()))
    }

    @Test
    fun testComputePacedKeyTimesColorSingle() {
        assertNull(computePacedKeyTimesColor(mutableIntListOf(0xFF0000.toInt())))
    }

    @Test
    fun testComputePacedKeyTimesColorTwo() {
        val result = computePacedKeyTimesColor(
            mutableIntListOf(0xFF0000.toInt(), 0x00FF00.toInt())
        )
        assertNotNull(result)
        assertEquals(2, result.size)
        assertEquals(0f, result[0], 0.001f)
        assertEquals(1f, result[1], 0.001f)
    }

    // --- selectAnimationSegmentDiscrete edge cases ---

    @Test
    fun testSelectAnimationSegmentDiscreteEmpty() {
        assertEquals(0f, selectAnimationSegmentDiscrete(mutableFloatListOf(), null, 0.5f))
    }

    @Test
    fun testSelectAnimationSegmentDiscreteSingle() {
        assertEquals(5f, selectAnimationSegmentDiscrete(mutableFloatListOf(5f), null, 0.5f))
    }

}
