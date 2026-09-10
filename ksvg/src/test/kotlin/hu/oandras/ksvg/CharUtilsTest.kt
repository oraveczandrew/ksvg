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

import hu.oandras.ksvg.utils.isSpaceLike
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class CharUtilsTest {

    @Test
    fun testIsSpaceLikeSpace() {
        assertTrue(' '.isSpaceLike())
    }

    @Test
    fun testIsSpaceLikeTab() {
        assertTrue('\t'.isSpaceLike())
    }

    @Test
    fun testIsSpaceLikeNewline() {
        assertTrue('\n'.isSpaceLike())
    }

    @Test
    fun testIsSpaceLikeCarriageReturn() {
        assertTrue('\r'.isSpaceLike())
    }

    @Test
    fun testIsSpaceLikeLetter() {
        assertFalse('a'.isSpaceLike())
        assertFalse('Z'.isSpaceLike())
    }

    @Test
    fun testIsSpaceLikeDigit() {
        assertFalse('0'.isSpaceLike())
        assertFalse('9'.isSpaceLike())
    }

    @Test
    fun testIsSpaceLikeOtherWhitespace() {
        assertFalse('\u00A0'.isSpaceLike()) // non-breaking space - not space-like
        assertFalse('\u2003'.isSpaceLike()) // em space - not space-like
    }

    @Test
    fun testIsSpaceLikeSpecialChars() {
        assertFalse(';'.isSpaceLike())
        assertFalse(','.isSpaceLike())
        assertFalse('.'.isSpaceLike())
    }
}
