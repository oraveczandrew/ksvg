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
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class TextScannerExtendedTest {

    @Test
    fun testEmptyInput() {
        val scanner = TextScanner("")
        assertTrue(scanner.empty())
    }

    @Test
    fun testNonEmptyInput() {
        val scanner = TextScanner("hello")
        assertFalse(scanner.empty())
    }

    @Test
    fun testSkipWhitespace() {
        val scanner = TextScanner("   hello")
        scanner.skipWhitespace()
        assertEquals("hello", scanner.restOfText())
    }

    @Test
    fun testSkipWhitespaceNoWhitespace() {
        val scanner = TextScanner("hello")
        scanner.skipWhitespace()
        assertEquals("hello", scanner.restOfText())
    }

    @Test
    fun testSkipCommaWhitespaceWithComma() {
        val scanner = TextScanner(",hello")
        assertTrue(scanner.skipCommaWhitespace())
        assertEquals("hello", scanner.restOfText())
    }

    @Test
    fun testSkipCommaWhitespaceWithoutComma() {
        val scanner = TextScanner("hello")
        assertFalse(scanner.skipCommaWhitespace())
    }

    @Test
    fun testSkipCommaWhitespaceEmpty() {
        val scanner = TextScanner("")
        assertFalse(scanner.skipCommaWhitespace())
    }

    @Test
    fun testNextFloatSimple() {
        val scanner = TextScanner("3.14")
        assertEquals(3.14f, scanner.nextFloat(), 0.001f)
    }

    @Test
    fun testNextFloatEmpty() {
        val scanner = TextScanner("")
        assertTrue(scanner.nextFloat().isNaN())
    }

    @Test
    fun testNextFloatNonNumeric() {
        val scanner = TextScanner("abc")
        assertTrue(scanner.nextFloat().isNaN())
    }

    @Test
    fun testPossibleNextFloatWithComma() {
        val scanner = TextScanner(",5.0")
        assertEquals(5f, scanner.possibleNextFloat(), 0.001f)
    }

    @Test
    fun testPossibleNextFloatWithoutComma() {
        val scanner = TextScanner("5.0")
        assertEquals(5f, scanner.possibleNextFloat(), 0.001f)
    }

    @Test
    fun testPossibleNextFloatEmpty() {
        val scanner = TextScanner("")
        assertTrue(scanner.possibleNextFloat().isNaN())
    }

    @Test
    fun testCheckedNextFloatWithValidLast() {
        val scanner = TextScanner(" , 42")
        assertEquals(42f, scanner.checkedNextFloat(1f), 0f)
    }

    @Test
    fun testCheckedNextFloatWithNaNLast() {
        val scanner = TextScanner(" , 42")
        assertTrue(scanner.checkedNextFloat(Float.NaN).isNaN())
    }

    @Test
    fun testCheckedNextFloatNullLast() {
        val scanner = TextScanner(" , 42")
        assertTrue(scanner.checkedNextFloat(null as Boolean?).isNaN())
    }

    @Test
    fun testNextIntegerSimple() {
        val scanner = TextScanner("42")
        assertEquals(42, scanner.nextInteger(withSign = false))
    }

    @Test
    fun testNextIntegerWithSign() {
        val scanner = TextScanner("-42")
        assertEquals(-42, scanner.nextInteger(withSign = true))
    }

    @Test
    fun testNextIntegerEmpty() {
        val scanner = TextScanner("")
        assertNull(scanner.nextInteger(withSign = false))
    }

    @Test
    fun testNextChar() {
        val scanner = TextScanner("abc")
        assertEquals('a', scanner.nextChar())
        assertEquals('b', scanner.nextChar())
        assertEquals('c', scanner.nextChar())
    }

    @Test(expected = IndexOutOfBoundsException::class)
    fun testNextCharEmpty() {
        val scanner = TextScanner("")
        scanner.nextChar()
    }

    @Test
    fun testNextFlagZero() {
        val scanner = TextScanner("0")
        assertEquals(false, scanner.nextFlag())
    }

    @Test
    fun testNextFlagOne() {
        val scanner = TextScanner("1")
        assertEquals(true, scanner.nextFlag())
    }

    @Test
    fun testNextFlagInvalid() {
        val scanner = TextScanner("2")
        assertNull(scanner.nextFlag())
    }

    @Test
    fun testNextFlagEmpty() {
        val scanner = TextScanner("")
        assertNull(scanner.nextFlag())
    }

    @Test
    fun testConsumeChar() {
        val scanner = TextScanner("abc")
        assertTrue(scanner.consume('a'))
        assertEquals("bc", scanner.restOfText())
    }

    @Test
    fun testConsumeCharNotFound() {
        val scanner = TextScanner("abc")
        assertFalse(scanner.consume('x'))
        assertEquals("abc", scanner.restOfText())
    }

    @Test
    fun testConsumeString() {
        val scanner = TextScanner("hello world")
        assertTrue(scanner.consume("hello "))
        assertEquals("world", scanner.restOfText())
    }

    @Test
    fun testConsumeStringNotFound() {
        val scanner = TextScanner("hello")
        assertFalse(scanner.consume("world"))
        assertEquals("hello", scanner.restOfText())
    }

    @Test
    fun testAdvanceChar() {
        val scanner = TextScanner("ab")
        assertEquals('b', scanner.advanceChar())
    }

    @Test
    fun testAdvanceCharAtEnd() {
        val scanner = TextScanner("a")
        scanner.advanceChar()
        assertEquals(INVALID_CHAR, scanner.advanceChar())
    }

    @Test
    fun testNextToken() {
        val scanner = TextScanner("helloworld")
        assertEquals("helloworld", scanner.nextToken())
    }

    @Test
    fun testNextTokenEmpty() {
        val scanner = TextScanner("")
        assertNull(scanner.nextToken())
    }

    @Test
    fun testNextTokenWithTerminator() {
        val scanner = TextScanner("hello;world")
        assertEquals("hello", scanner.nextToken(';'))
        assertTrue(scanner.consume(';'))
        assertEquals("world", scanner.restOfText())
    }

    @Test
    fun testNextWord() {
        val scanner = TextScanner("Word123")
        assertEquals("Word", scanner.nextWord())
    }

    @Test
    fun testNextWordEmpty() {
        val scanner = TextScanner("")
        assertNull(scanner.nextWord())
    }

    @Test
    fun testNextWordNonLetter() {
        val scanner = TextScanner("123abc")
        assertNull(scanner.nextWord())
    }

    @Test
    fun testNextFunction() {
        val scanner = TextScanner("translate(10,20)")
        assertEquals("translate", scanner.nextFunction())
    }

    @Test
    fun testNextFunctionWithSpaces() {
        val scanner = TextScanner("translate (10,20)")
        assertEquals("translate", scanner.nextFunction())
    }

    @Test
    fun testNextFunctionEmpty() {
        val scanner = TextScanner("")
        assertNull(scanner.nextFunction())
    }

    @Test
    fun testNextFunctionNoParen() {
        val scanner = TextScanner("translate")
        assertNull(scanner.nextFunction())
    }

    @Test
    fun testAhead() {
        val scanner = TextScanner("hello world")
        assertEquals("hello", scanner.ahead())
    }

    @Test
    fun testHasLetter() {
        assertTrue(TextScanner("a").hasLetter())
        assertTrue(TextScanner("Z").hasLetter())
        assertFalse(TextScanner("1").hasLetter())
        assertFalse(TextScanner("").hasLetter())
    }

    @Test
    fun testNextQuotedStringDoubleQuote() {
        val scanner = TextScanner("\"hello world\"")
        assertEquals("hello world", scanner.nextQuotedString())
    }

    @Test
    fun testNextQuotedStringSingleQuote() {
        val scanner = TextScanner("'hello world'")
        assertEquals("hello world", scanner.nextQuotedString())
    }

    @Test
    fun testNextQuotedStringEmpty() {
        val scanner = TextScanner("")
        assertNull(scanner.nextQuotedString())
    }

    @Test
    fun testNextQuotedStringNotQuoted() {
        val scanner = TextScanner("hello")
        assertNull(scanner.nextQuotedString())
    }

    @Test
    fun testNextQuotedStringUnclosed() {
        val scanner = TextScanner("\"hello")
        assertNull(scanner.nextQuotedString())
    }

    @Test
    fun testRestOfText() {
        val scanner = TextScanner("helloworld")
        scanner.nextChar() // skip 'h'
        assertEquals("elloworld", scanner.restOfText())
    }

    @Test
    fun testRestOfTextEmpty() {
        val scanner = TextScanner("")
        assertNull(scanner.restOfText())
    }

    @Test
    fun testNextLengthWithUnit() {
        val scanner = TextScanner("12px")
        val length = scanner.nextLength()
        assertNotNull(length)
        assertEquals(12f, length!!.value, 0f)
    }

    @Test
    fun testNextLengthNoUnit() {
        val scanner = TextScanner("12")
        val length = scanner.nextLength()
        assertNotNull(length)
        assertEquals(12f, length!!.value, 0f)
    }

    @Test
    fun testNextLengthEmpty() {
        val scanner = TextScanner("")
        assertNull(scanner.nextLength())
    }

    @Test
    fun testNextUnitPx() {
        val scanner = TextScanner("px")
        val unit = scanner.nextUnit()
        assertNotNull(unit)
    }

    @Test
    fun testNextUnitPercent() {
        val scanner = TextScanner("%")
        val unit = scanner.nextUnit()
        assertNotNull(unit)
    }

    @Test
    fun testNextUnitEmpty() {
        val scanner = TextScanner("")
        assertNull(scanner.nextUnit())
    }

    @Test
    fun testCheckedNextFlagWithNull() {
        val scanner = TextScanner(",1")
        assertNull(scanner.checkedNextFlag(null))
    }

    @Test
    fun testCheckedNextFlagWithPrevious() {
        val scanner = TextScanner(" , 1")
        assertEquals(true, scanner.checkedNextFlag("prev"))
    }

    private fun assertNotNull(o: Any?) {
        org.junit.Assert.assertNotNull(o)
    }
}
