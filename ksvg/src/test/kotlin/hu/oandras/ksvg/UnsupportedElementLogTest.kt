/*
 *    Copyright 2026 András Oravecz <info@oandras.hu>
 *
 *    Licensed under the Apache License, Version 2.0 (the "License");
 *    you may not use this file except in compliance with the License.
 *    You may obtain a copy of the License at
 *
 *        https://www.apache.org/licenses/LICENSE-2.0
 *
 *    Unless required by applicable law or agreed to in writing, software
 *    distributed under the License is distributed on an "AS IS" BASIS,
 *    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *    See the License for the specific language governing permissions and
 *    limitations under the License.
 */
package hu.oandras.ksvg

import hu.oandras.ksvg.dom.SVGImpl
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class UnsupportedElementLogTest {

    private fun parseWithRecording(svg: String): RecordingLoggerContext {
        val logger = RecordingLoggerContext()
        SVGImpl.getFromString(svg, loggerContext = logger)
        return logger
    }

    private fun doc(vararg body: String): String =
        "<svg xmlns=\"http://www.w3.org/2000/svg\">" + body.joinToString("") + "</svg>"

    @Test
    fun testSingleUnsupportedLogsOnce() {
        val logger = parseWithRecording(doc("<foreignObject><div xmlns=\"http://www.w3.org/1999/xhtml\"/></foreignObject>"))
        assertEquals(1, logger.messages.size)
        assertTrue(logger.messages[0].contains("<foreignObject>"))
    }

    @Test
    fun testRepeatStaysSilent() {
        val logger = parseWithRecording(doc("<foreignObject/>", "<foreignObject/>"))
        assertEquals("second hit in the same parse stays silent", 1, logger.messages.size)
    }

    @Test
    fun testDistinctTagsLogSeparately() {
        val logger = parseWithRecording(doc("<foreignObject/>", "<hatch/>"))
        assertEquals(2, logger.messages.size)
    }

    @Test
    fun testNestedUnsupportedSingleLog() {
        val logger = parseWithRecording(doc("<foreignObject><hatch/></foreignObject>"))
        assertEquals("inner tag is skipped via ignoring, no double log", 1, logger.messages.size)
    }

    @Test
    fun testFreshParseLogsAfresh() {
        val svg = doc("<foreignObject/>")
        assertEquals(1, parseWithRecording(svg).messages.size)
        assertEquals(1, parseWithRecording(svg).messages.size)
    }

    @Test
    fun testSupportedElementsSilent() {
        val logger = parseWithRecording(doc("<rect width=\"10\" height=\"10\"/>"))
        assertTrue(logger.messages.isEmpty())
    }

    @Test
    fun testBareContextLogsEveryTime() {
        val logger = RecordingLoggerContext()
        logger.logUnsupportedElement("foreignObject")
        logger.logUnsupportedElement("foreignObject")
        assertEquals(2, logger.messages.size)
    }
}
