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

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class NumberParserTest {

    // --- parseNumber(String, Int, Int) ---

    @Test
    fun testParseSimpleInteger() {
        assertEquals(123f, NumberParser.parseNumber("123", 0, 3))
    }

    @Test
    fun testParseNegativeInteger() {
        assertEquals(-42f, NumberParser.parseNumber("-42", 0, 3))
    }

    @Test
    fun testParsePositiveInteger() {
        assertEquals(42f, NumberParser.parseNumber("+42", 0, 3))
    }

    @Test
    fun testParseSimpleFloat() {
        assertEquals(3.14f, NumberParser.parseNumber("3.14", 0, 4), 0.001f)
    }

    @Test
    fun testParseNegativeFloat() {
        assertEquals(-1.5f, NumberParser.parseNumber("-1.5", 0, 4), 0.001f)
    }

    @Test
    fun testParseEmptyString() {
        assertTrue(NumberParser.parseNumber("", 0, 0).isNaN())
    }

    @Test
    fun testParseAtPosition() {
        assertEquals(42f, NumberParser.parseNumber("abc42def", 3, 8))
    }

    @Test
    fun testParseWithExponent() {
        assertEquals(1e3f, NumberParser.parseNumber("1e3", 0, 3))
    }

    @Test
    fun testParseWithCapitalExponent() {
        assertEquals(1E3f, NumberParser.parseNumber("1E3", 0, 3))
    }

    @Test
    fun testParseWithNegativeExponent() {
        assertEquals(1e-3f, NumberParser.parseNumber("1e-3", 0, 4), 0.0001f)
    }

    @Test
    fun testParseWithPositiveExponent() {
        assertEquals(2.5e4f, NumberParser.parseNumber("2.5e+4", 0, 6), 1f)
    }

    @Test
    fun testParseOnlyDecimalPoint() {
        assertTrue(NumberParser.parseNumber(".", 0, 1).isNaN())
    }

    @Test
    fun testParseDecimalWithTrailingZeroes() {
        assertEquals(1.0f, NumberParser.parseNumber("1.0", 0, 3), 0.001f)
    }

    @Test
    fun testParseLeadingZeroes() {
        assertEquals(0.5f, NumberParser.parseNumber("0.5", 0, 3), 0.001f)
    }

    @Test
    fun testParseZero() {
        assertEquals(0f, NumberParser.parseNumber("0", 0, 1))
    }

    @Test
    fun testParseNotANumber() {
        assertTrue(NumberParser.parseNumber("abc", 0, 3).isNaN())
    }

    @Test
    fun testParseDoubleDecimal() {
        // Should stop at second decimal point
        assertEquals(1.5f, NumberParser.parseNumber("1.5.5", 0, 5), 0.001f)
    }

    // --- parseNumberPacked packs value and end position into one Long ---

    @Test
    fun testParseNumberPackedEndPos() {
        val result = NumberParser.parseNumberPacked("42abc", 0, 5)
        assertEquals(42f, result.value)
        assertEquals(2, result.endPos)
    }

    @Test
    fun testParseNumberPackedEndPosEmpty() {
        val result = NumberParser.parseNumberPacked("", 0, 0)
        assertTrue(result.value.isNaN())
        assertEquals(0, result.endPos)
    }

    @Test
    fun testParseNumberPackedEndPosWithDecimal() {
        val result = NumberParser.parseNumberPacked("3.14rest", 0, 8)
        assertEquals(3.14f, result.value, 0.001f)
        assertEquals(4, result.endPos)
    }

    @Test
    fun testParseNumberPackedEndPosWithExponent() {
        val result = NumberParser.parseNumberPacked("1e3 ", 0, 4)
        assertEquals(1000f, result.value)
        assertEquals(3, result.endPos)
    }

    @Test
    fun testNumberParserResultRoundTrip() {
        val result = NumberParserResult(-12.5f, 7)
        assertEquals(-12.5f, result.value)
        assertEquals(7, result.endPos)
    }
}
