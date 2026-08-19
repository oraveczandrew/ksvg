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

import androidx.collection.intListOf
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class TextScannerTest {

    @Test
    fun testNextSemicolonFloatList() {
        val scanner = TextScanner("1.5; 2.0; 3")
        val result = scanner.nextSemicolonFloatList()
        assertEquals(3, result.size)
        assertEquals(1.5f, result[0], 0f)
        assertEquals(2.0f, result[1], 0f)
        assertEquals(3.0f, result[2], 0f)
    }

    @Test
    fun testNextSemicolonFloatListWithExtraSemicolons() {
        val scanner = TextScanner("1.5;; 2.0; ;3;")
        val result = scanner.nextSemicolonFloatList()
        assertEquals(3, result.size)
        assertEquals(1.5f, result[0], 0f)
        assertEquals(2.0f, result[1], 0f)
        assertEquals(3.0f, result[2], 0f)
    }

    @Test
    fun testNextSemicolonColorList() {
        val scanner = TextScanner("red; green; blue")
        val result = scanner.nextSemicolonColorList()
        assertEquals(intListOf(-65536, -16744448, -16776961), result)
    }

    @Test
    fun testNextSemicolonListEmpty() {
        val scanner = TextScanner("  ;  ; ")
        val result = scanner.nextSemicolonColorList()
        assertTrue(result.isEmpty())
    }

    @Test
    fun testSkipSemicolonWhitespace() {
        val scanner = TextScanner(" ; next")
        assertTrue(scanner.skipSemicolonWhitespace())
        assertEquals("next", scanner.nextToken())
    }

    @Test
    fun testNextTokenWithTerminator() {
        val scanner = TextScanner("token1;token2")
        assertEquals("token1", scanner.nextToken(';'))
        // Position should be at ';'
        assertTrue(scanner.consume(';'))
        assertEquals("token2", scanner.nextToken(';'))
    }

    @Test
    fun testNextWord() {
        val scanner = TextScanner("Word123")
        assertEquals("Word", scanner.nextWord())
        // Position should be at '1'
        assertEquals("123", scanner.restOfText())
    }
}
