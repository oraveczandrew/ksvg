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

import hu.oandras.ksvg.utils.ceilToInt
import hu.oandras.ksvg.utils.clamp
import hu.oandras.ksvg.utils.clamp255
import hu.oandras.ksvg.utils.squared
import hu.oandras.ksvg.utils.takeIfNonZeroOrElse
import hu.oandras.ksvg.utils.toDegrees
import hu.oandras.ksvg.utils.toFloatOrError
import hu.oandras.ksvg.utils.toRadians
import org.junit.Assert.assertEquals
import org.junit.Test
import kotlin.math.PI

class MathUtilsTest {

    // --- clamp ---

    @Test
    fun testClampDouble() {
        assertEquals(5.0, clamp(5.0, 0.0, 10.0), 0.0)
        assertEquals(0.0, clamp(-1.0, 0.0, 10.0), 0.0)
        assertEquals(10.0, clamp(15.0, 0.0, 10.0), 0.0)
        assertEquals(0.0, clamp(0.0, 0.0, 10.0), 0.0)
        assertEquals(10.0, clamp(10.0, 0.0, 10.0), 0.0)
    }

    @Test
    fun testClampFloat() {
        assertEquals(5f, clamp(5f, 0f, 10f), 0f)
        assertEquals(0f, clamp(-1f, 0f, 10f), 0f)
        assertEquals(10f, clamp(15f, 0f, 10f), 0f)
    }

    @Test
    fun testClampInt() {
        assertEquals(5, clamp(5, 0, 10))
        assertEquals(0, clamp(-1, 0, 10))
        assertEquals(10, clamp(15, 0, 10))
    }

    @Test
    fun testClampNegativeRange() {
        assertEquals(-5, clamp(-5, -10, 0))
        assertEquals(-10, clamp(-15, -10, 0))
        assertEquals(0, clamp(5, -10, 0))
    }

    // --- clamp255 ---

    @Test
    fun testClamp255Double() {
        assertEquals(0, clamp255(-10.0))
        assertEquals(255, clamp255(300.0))
        assertEquals(128, clamp255(128.0))
        assertEquals(0, clamp255(0.0))
        assertEquals(255, clamp255(255.0))
    }

    @Test
    fun testClamp255Float() {
        assertEquals(0, clamp255(-10f))
        assertEquals(255, clamp255(300f))
        assertEquals(128, clamp255(128f))
    }

    @Test
    fun testClamp255Int() {
        assertEquals(0, clamp255(-10))
        assertEquals(255, clamp255(300))
        assertEquals(128, clamp255(128))
    }

    @Test
    fun testClamp255Rounding() {
        assertEquals(128, clamp255(127.6))
        assertEquals(128, clamp255(128.4))
    }

    // --- toRadians / toDegrees ---

    @Test
    fun testDoubleToRadians() {
        assertEquals(PI, 180.0.toRadians(), 1e-10)
        assertEquals(PI / 2, 90.0.toRadians(), 1e-10)
        assertEquals(0.0, 0.0.toRadians(), 1e-10)
    }

    @Test
    fun testDoubleToDegrees() {
        assertEquals(180.0, PI.toDegrees(), 1e-10)
        assertEquals(90.0, (PI / 2).toDegrees(), 1e-10)
        assertEquals(0.0, 0.0.toDegrees(), 1e-10)
    }

    @Test
    fun testFloatToRadians() {
        assertEquals(PI.toFloat(), 180f.toRadians(), 1e-5f)
        assertEquals((PI / 2).toFloat(), 90f.toRadians(), 1e-5f)
    }

    @Test
    fun testFloatToDegrees() {
        assertEquals(180f, PI.toFloat().toDegrees(), 1e-5f)
        assertEquals(90f, (PI / 2).toFloat().toDegrees(), 1e-5f)
    }

    // --- ceilToInt ---

    @Test
    fun testCeilToInt() {
        assertEquals(2, 1.1f.ceilToInt())
        assertEquals(1, 1.0f.ceilToInt())
        assertEquals(1, 0.1f.ceilToInt())
        assertEquals(0, 0.0f.ceilToInt())
        assertEquals(0, (-0.1f).ceilToInt())
        assertEquals(-1, (-1.0f).ceilToInt())
        assertEquals(-1, (-1.9f).ceilToInt())
    }

    // --- squared ---

    @Test
    fun testSquared() {
        assertEquals(0, 0.squared())
        assertEquals(1, 1.squared())
        assertEquals(1, (-1).squared())
        assertEquals(4, 2.squared())
        assertEquals(9, (-3).squared())
        assertEquals(100, 10.squared())
    }

    // --- takeIfNonZeroOrElse ---

    @Test
    fun testTakeIfNonZeroOrElseNonZero() {
        assertEquals(5f, 5f.takeIfNonZeroOrElse { 10f })
    }

    @Test
    fun testTakeIfNonZeroOrElseZero() {
        assertEquals(10f, 0f.takeIfNonZeroOrElse { 10f })
    }

    @Test
    fun testTakeIfNonZeroOrElseNegative() {
        assertEquals(-3f, (-3f).takeIfNonZeroOrElse { 10f })
    }

    // --- toFloatOrError ---

    @Test
    fun testToFloatOrErrorValid() {
        assertEquals(3.14f, "3.14".toFloatOrError { "fail" })
        assertEquals(0f, "0".toFloatOrError { "fail" })
        assertEquals(-42f, "-42".toFloatOrError { "fail" })
    }

    @Test(expected = KSVGParseException::class)
    fun testToFloatOrErrorInvalid() {
        "abc".toFloatOrError { "Invalid float" }
    }

    @Test
    fun testToFloatOrErrorMessage() {
        try {
            "not_a_number".toFloatOrError { "Custom error" }
        } catch (e: KSVGParseException) {
            assertEquals("Custom error", e.message)
            return
        }
        throw AssertionError("Expected KSVGParseException")
    }
}
