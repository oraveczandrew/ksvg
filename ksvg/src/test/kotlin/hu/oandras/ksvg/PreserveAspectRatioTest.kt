package hu.oandras.ksvg

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class PreserveAspectRatioTest {

    @Test
    fun testParseNone() {
        val par = PreserveAspectRatio.of("none")
        assertEquals(PreserveAspectRatio.Alignment.none, par.alignment)
        assertNull(par.scale)
    }

    @Test
    fun testParseXMidYMidMeet() {
        val par = PreserveAspectRatio.of("xMidYMid meet")
        assertEquals(PreserveAspectRatio.Alignment.xMidYMid, par.alignment)
        assertEquals(PreserveAspectRatio.Scale.meet, par.scale)
    }

    @Test
    fun testParseXMinYMinSlice() {
        val par = PreserveAspectRatio.of("xMinYMin slice")
        assertEquals(PreserveAspectRatio.Alignment.xMinYMin, par.alignment)
        assertEquals(PreserveAspectRatio.Scale.slice, par.scale)
    }

    @Test
    fun testParseXMaxYMaxMeet() {
        val par = PreserveAspectRatio.of("xMaxYMax meet")
        assertEquals(PreserveAspectRatio.Alignment.xMaxYMax, par.alignment)
        assertEquals(PreserveAspectRatio.Scale.meet, par.scale)
    }

    @Test
    fun testParseWithDefer() {
        val par = PreserveAspectRatio.of("defer xMidYMid meet")
        assertEquals(PreserveAspectRatio.Alignment.xMidYMid, par.alignment)
        assertEquals(PreserveAspectRatio.Scale.meet, par.scale)
    }

    @Test
    fun testParseCaseInsensitive() {
        val par = PreserveAspectRatio.of("XMidYMid MEET")
        assertEquals(PreserveAspectRatio.Alignment.xMidYMid, par.alignment)
        assertEquals(PreserveAspectRatio.Scale.meet, par.scale)
    }

    @Test
    fun testParseAllAlignments() {
        assertEquals(PreserveAspectRatio.Alignment.none, PreserveAspectRatio.of("none").alignment)
        assertEquals(PreserveAspectRatio.Alignment.xMinYMin, PreserveAspectRatio.of("xMinYMin meet").alignment)
        assertEquals(PreserveAspectRatio.Alignment.xMidYMin, PreserveAspectRatio.of("xMidYMin meet").alignment)
        assertEquals(PreserveAspectRatio.Alignment.xMaxYMin, PreserveAspectRatio.of("xMaxYMin meet").alignment)
        assertEquals(PreserveAspectRatio.Alignment.xMinYMid, PreserveAspectRatio.of("xMinYMid meet").alignment)
        assertEquals(PreserveAspectRatio.Alignment.xMidYMid, PreserveAspectRatio.of("xMidYMid meet").alignment)
        assertEquals(PreserveAspectRatio.Alignment.xMaxYMid, PreserveAspectRatio.of("xMaxYMid meet").alignment)
        assertEquals(PreserveAspectRatio.Alignment.xMinYMax, PreserveAspectRatio.of("xMinYMax meet").alignment)
        assertEquals(PreserveAspectRatio.Alignment.xMidYMax, PreserveAspectRatio.of("xMidYMax meet").alignment)
        assertEquals(PreserveAspectRatio.Alignment.xMaxYMax, PreserveAspectRatio.of("xMaxYMax meet").alignment)
    }

    @Test(expected = IllegalArgumentException::class)
    fun testParseInvalidMeetOrSlice() {
        PreserveAspectRatio.of("xMidYMid invalid")
    }

    @Test
    fun testToString() {
        val par = PreserveAspectRatio.of("xMidYMid meet")
        assertEquals("xMidYMid meet", par.toString())
    }

    @Test
    fun testToStringNone() {
        val par = PreserveAspectRatio.of("none")
        assertEquals("none null", par.toString())
    }

    // --- Static constants ---

    @Test
    fun testUnscaled() {
        assertNull(PreserveAspectRatio.UNSCALED.alignment)
        assertNull(PreserveAspectRatio.UNSCALED.scale)
    }

    @Test
    fun testStretch() {
        assertEquals(PreserveAspectRatio.Alignment.none, PreserveAspectRatio.STRETCH.alignment)
        assertNull(PreserveAspectRatio.STRETCH.scale)
    }

    @Test
    fun testLetterbox() {
        assertEquals(PreserveAspectRatio.Alignment.xMidYMid, PreserveAspectRatio.LETTERBOX.alignment)
        assertEquals(PreserveAspectRatio.Scale.meet, PreserveAspectRatio.LETTERBOX.scale)
    }

    @Test
    fun testStart() {
        assertEquals(PreserveAspectRatio.Alignment.xMinYMin, PreserveAspectRatio.START.alignment)
        assertEquals(PreserveAspectRatio.Scale.meet, PreserveAspectRatio.START.scale)
    }

    @Test
    fun testEnd() {
        assertEquals(PreserveAspectRatio.Alignment.xMaxYMax, PreserveAspectRatio.END.alignment)
        assertEquals(PreserveAspectRatio.Scale.meet, PreserveAspectRatio.END.scale)
    }

    @Test
    fun testTop() {
        assertEquals(PreserveAspectRatio.Alignment.xMidYMin, PreserveAspectRatio.TOP.alignment)
        assertEquals(PreserveAspectRatio.Scale.meet, PreserveAspectRatio.TOP.scale)
    }

    @Test
    fun testBottom() {
        assertEquals(PreserveAspectRatio.Alignment.xMidYMax, PreserveAspectRatio.BOTTOM.alignment)
        assertEquals(PreserveAspectRatio.Scale.meet, PreserveAspectRatio.BOTTOM.scale)
    }

    @Test
    fun testFullscreen() {
        assertEquals(PreserveAspectRatio.Alignment.xMidYMid, PreserveAspectRatio.FULLSCREEN.alignment)
        assertEquals(PreserveAspectRatio.Scale.slice, PreserveAspectRatio.FULLSCREEN.scale)
    }

    @Test
    fun testFullscreenStart() {
        assertEquals(PreserveAspectRatio.Alignment.xMinYMin, PreserveAspectRatio.FULLSCREEN_START.alignment)
        assertEquals(PreserveAspectRatio.Scale.slice, PreserveAspectRatio.FULLSCREEN_START.scale)
    }

    // --- Data class ---

    @Test
    fun testEquality() {
        val par1 = PreserveAspectRatio.of("xMidYMid meet")
        val par2 = PreserveAspectRatio.of("xMidYMid meet")
        assertEquals(par1, par2)
    }

    @Test
    fun testInequality() {
        val par1 = PreserveAspectRatio.of("xMidYMid meet")
        val par2 = PreserveAspectRatio.of("xMinYMin meet")
        assertTrue(par1 != par2)
    }
}
