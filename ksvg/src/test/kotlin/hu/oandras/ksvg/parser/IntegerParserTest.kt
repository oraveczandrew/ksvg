package hu.oandras.ksvg.parser

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Test

class IntegerParserTest {

    // --- parseInt ---

    @Test
    fun testParseIntSimple() {
        val result = IntegerParser.parseInt("42", 0, 2, includeSign = false)
        assertNotNull(result)
        assertEquals(42, result!!.value)
        assertEquals(2, result.endPos)
    }

    @Test
    fun testParseIntPositive() {
        val result = IntegerParser.parseInt("+42", 0, 3, includeSign = true)
        assertNotNull(result)
        assertEquals(42, result!!.value)
    }

    @Test
    fun testParseIntNegative() {
        val result = IntegerParser.parseInt("-42", 0, 3, includeSign = true)
        assertNotNull(result)
        assertEquals(-42, result!!.value)
    }

    @Test
    fun testParseIntNoSign() {
        val result = IntegerParser.parseInt("42", 0, 2, includeSign = false)
        assertNotNull(result)
        assertEquals(42, result!!.value)
    }

    @Test
    fun testParseIntWithSignDisabled() {
        val result = IntegerParser.parseInt("+42", 0, 3, includeSign = false)
        assertNull(result)
    }

    @Test
    fun testParseIntNonDigit() {
        val result = IntegerParser.parseInt("abc", 0, 3, includeSign = false)
        assertNull(result)
    }

    @Test
    fun testParseIntEmpty() {
        val result = IntegerParser.parseInt("", 0, 0, includeSign = false)
        assertNull(result)
    }

    @Test
    fun testParseIntAtOffset() {
        val result = IntegerParser.parseInt("abc42def", 3, 8, includeSign = false)
        assertNotNull(result)
        assertEquals(42, result!!.value)
        assertEquals(5, result.endPos)
    }

    @Test
    fun testParseIntZero() {
        val result = IntegerParser.parseInt("0", 0, 1, includeSign = false)
        assertNotNull(result)
        assertEquals(0, result!!.value)
    }

    @Test
    fun testParseIntOverflow() {
        val result = IntegerParser.parseInt("9999999999", 0, 10, includeSign = false)
        assertNull(result)
    }

    @Test
    fun testParseIntNegativeOverflow() {
        val result = IntegerParser.parseInt("-9999999999", 0, 11, includeSign = true)
        assertNull(result)
    }

    // --- parseHex ---

    @Test
    fun testParseHexSimple() {
        val result = IntegerParser.parseHex("FF", 0, 2)
        assertNotNull(result)
        assertEquals(0xFF, result!!.value)
    }

    @Test
    fun testParseHexLowercase() {
        val result = IntegerParser.parseHex("ff", 0, 2)
        assertNotNull(result)
        assertEquals(0xFF, result!!.value)
    }

    @Test
    fun testParseHexMixedCase() {
        val result = IntegerParser.parseHex("aB", 0, 2)
        assertNotNull(result)
        assertEquals(0xAB, result!!.value)
    }

    @Test
    fun testParseHexDigits() {
        val result = IntegerParser.parseHex("0123", 0, 4)
        assertNotNull(result)
        assertEquals(0x0123, result!!.value)
    }

    @Test
    fun testParseHexEmpty() {
        val result = IntegerParser.parseHex("", 0, 0)
        assertNull(result)
    }

    @Test
    fun testParseHexNonHexChar() {
        val result = IntegerParser.parseHex("G", 0, 1)
        assertNull(result)
    }

    @Test
    fun testParseHexAtOffset() {
        val result = IntegerParser.parseHex("abcFF0G", 3, 7)
        assertNotNull(result)
        assertEquals(0xFF0, result!!.value)
        assertEquals(6, result.endPos)
    }

    @Test
    fun testParseHexLongString() {
        val result = IntegerParser.parseHex("FFFFFFFF", 0, 8)
        assertNotNull(result)
        assertEquals(-1, result!!.value) // 0xFFFFFFFF as signed int
    }

    @Test
    fun testParseHexTooLong() {
        val result = IntegerParser.parseHex("100000000", 0, 9) // > 32 bits
        assertNull(result)
    }
}
