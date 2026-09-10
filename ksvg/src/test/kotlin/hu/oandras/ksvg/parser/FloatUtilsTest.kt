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

package hu.oandras.ksvg.parser

import hu.oandras.ksvg.KSVGParseException
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class FloatUtilsTest {

    // --- parseFloatList ---

    @Test
    fun testParseFloatListSimple() {
        val result = parseFloatList("1 2 3")
        assertEquals(3, result.size)
        assertEquals(1f, result[0], 0f)
        assertEquals(2f, result[1], 0f)
        assertEquals(3f, result[2], 0f)
    }

    @Test
    fun testParseFloatListCommaSeparated() {
        val result = parseFloatList("1, 2, 3")
        assertEquals(3, result.size)
        assertEquals(1f, result[0], 0f)
        assertEquals(2f, result[1], 0f)
        assertEquals(3f, result[2], 0f)
    }

    @Test
    fun testParseFloatListEmpty() {
        val result = parseFloatList("")
        assertEquals(0, result.size)
    }

    @Test
    fun testParseFloatListDecimal() {
        val result = parseFloatList("1.5 2.7")
        assertEquals(2, result.size)
        assertEquals(1.5f, result[0], 0.001f)
        assertEquals(2.7f, result[1], 0.001f)
    }

    @Test
    fun testParseFloatListNegative() {
        val result = parseFloatList("-1 -2.5")
        assertEquals(2, result.size)
        assertEquals(-1f, result[0], 0f)
        assertEquals(-2.5f, result[1], 0f)
    }

    // --- parsePoints ---

    @Test
    fun testParsePointsSimple() {
        val result = parsePoints("1,2 3,4")
        assertEquals(4, result.size)
        assertEquals(1f, result[0], 0f)
        assertEquals(2f, result[1], 0f)
        assertEquals(3f, result[2], 0f)
        assertEquals(4f, result[3], 0f)
    }

    @Test
    fun testParsePointsSpaceSeparated() {
        val result = parsePoints("1 2 3 4")
        assertEquals(4, result.size)
    }

    @Test
    fun testParsePointsEmpty() {
        val result = parsePoints("")
        assertEquals(0, result.size)
    }

    @Test(expected = KSVGParseException::class)
    fun testParsePointsOddNumbers() {
        parsePoints("1,2,3")
    }

    @Test(expected = KSVGParseException::class)
    fun testParsePointsSingleNumber() {
        parsePoints("1")
    }

    // --- parseFloat ---

    @Test
    fun testParseFloatSimple() {
        assertEquals(3.14f, parseFloat("3.14"), 0.001f)
    }

    @Test
    fun testParseFloatInteger() {
        assertEquals(42f, parseFloat("42"))
    }

    @Test
    fun testParseFloatNegative() {
        assertEquals(-1.5f, parseFloat("-1.5"), 0.001f)
    }

    @Test(expected = KSVGParseException::class)
    fun testParseFloatEmpty() {
        parseFloat("")
    }

    @Test(expected = KSVGParseException::class)
    fun testParseFloatInvalid() {
        parseFloat("abc")
    }

    // --- parseFloat with offset ---

    @Test
    fun testParseFloatWithOffset() {
        assertEquals(42f, parseFloat("abc42def", 3, 8))
    }

    // --- parseNonNegativeFloat ---

    @Test
    fun testParseNonNegativeFloatValid() {
        assertEquals(1.5f, parseNonNegativeFloat("1.5", "error"))
    }

    @Test
    fun testParseNonNegativeFloatZero() {
        assertEquals(0f, parseNonNegativeFloat("0", "error"))
    }

    @Test(expected = KSVGParseException::class)
    fun testParseNonNegativeFloatNegative() {
        parseNonNegativeFloat("-1", "Must be non-negative")
    }

    // --- parseOpacity ---

    @Test
    fun testParseOpacityValid() {
        assertEquals(0.5f, parseOpacity("0.5"), 0.001f)
    }

    @Test
    fun testParseOpacityClampedHigh() {
        assertEquals(1f, parseOpacity("2.0"), 0.001f)
    }

    @Test
    fun testParseOpacityClampedLow() {
        assertEquals(0f, parseOpacity("-1.0"), 0.001f)
    }

    @Test
    fun testParseOpacityZero() {
        assertEquals(0f, parseOpacity("0"), 0.001f)
    }

    @Test
    fun testParseOpacityOne() {
        assertEquals(1f, parseOpacity("1"), 0.001f)
    }

    @Test
    fun testParseOpacityInvalid() {
        val result = parseOpacity("abc")
        assertTrue(result.isNaN())
    }
}
