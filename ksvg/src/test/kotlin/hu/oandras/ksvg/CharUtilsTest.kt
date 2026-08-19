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
