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
import hu.oandras.ksvg.logger.logUnsupportedPseudoClass
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class UnsupportedPseudoClassLogTest {

    private fun parseWithRecording(css: String): RecordingLoggerContext {
        val logger = RecordingLoggerContext()
        SVGImpl.getFromString(
            "<svg xmlns=\"http://www.w3.org/2000/svg\"><style>$css</style></svg>",
            loggerContext = logger
        )
        return logger
    }

    private fun messagesMatching(logger: RecordingLoggerContext, needle: String): List<String> =
        logger.messages.filter { it.contains(needle) }

    @Test
    fun testSingleUnsupportedPseudoLogsOnce() {
        val logger = parseWithRecording("rect:hover { fill: #0f0; }")
        assertEquals(1, logger.messages.size)
        assertTrue(logger.messages[0], logger.messages[0].contains(":hover"))
    }

    @Test
    fun testSamePseudoOnTwoRulesWarnsOnce() {
        val logger = parseWithRecording(
            "rect:hover { fill: #0f0; } circle:hover { fill: #0f0; }"
        )
        assertEquals(logger.messages.toString(), 1, logger.messages.size)
    }

    @Test
    fun testDistinctPseudosLogSeparately() {
        val logger = parseWithRecording(
            "rect:hover { fill: #0f0; } rect:focus { fill: #0f0; }"
        )
        assertEquals(1, messagesMatching(logger, ":hover").size)
        assertEquals(1, messagesMatching(logger, ":focus").size)
    }

    @Test
    fun testNestedNotWarns() {
        val logger = parseWithRecording("rect:not(:hover) { fill: #0f0; }")
        assertEquals(logger.messages.toString(), 1, messagesMatching(logger, ":hover").size)
    }

    @Test
    fun testCaseVariantsDedupTogether() {
        val logger = parseWithRecording(
            "rect:HOVER { fill: #0f0; } rect:hover { fill: #0f0; }"
        )
        assertEquals(logger.messages.toString(), 1, logger.messages.size)
    }

    @Test
    fun testSelectors4PseudoWarnsOnce() {
        val logger = parseWithRecording(
            "rect:any-link { fill: #0f0; } circle:any-link { fill: #0f0; }"
        )
        assertEquals(logger.messages.toString(), 1, messagesMatching(logger, ":any-link").size)
    }

    @Test
    fun testUnsupportedPseudoDoesNotDropRule() {
        val logger = parseWithRecording("rect:any-link { fill: #0f0; }")
        assertEquals(logger.messages.toString(), 1, logger.messages.size)
        assertTrue(
            logger.messages.toString(),
            messagesMatching(logger, "dropped").isEmpty()
        )
    }

    @Test
    fun testFunctionalPseudoParamSkipped() {
        val logger = parseWithRecording("rect:nth-col(2n) { fill: #0f0; }")
        assertEquals(logger.messages.toString(), 1, messagesMatching(logger, ":nth-col").size)
        assertTrue(
            logger.messages.toString(),
            messagesMatching(logger, "dropped").isEmpty()
        )
    }

    @Test
    fun testRelationalPseudoWarns() {
        val logger = parseWithRecording("rect:has(circle) { fill: #0f0; }")
        assertEquals(logger.messages.toString(), 1, messagesMatching(logger, ":has").size)
        assertTrue(
            logger.messages.toString(),
            messagesMatching(logger, "dropped").isEmpty()
        )
    }

    @Test
    fun testDirPseudoWarns() {
        val logger = parseWithRecording("rect:dir(rtl) { fill: #0f0; }")
        assertEquals(logger.messages.toString(), 1, messagesMatching(logger, ":dir").size)
        assertTrue(
            logger.messages.toString(),
            messagesMatching(logger, "dropped").isEmpty()
        )
    }

    @Test
    fun testIsPseudoWarns() {
        val logger = parseWithRecording("rect:is(.a, .b) { fill: #0f0; }")
        assertEquals(logger.messages.toString(), 1, messagesMatching(logger, ":is").size)
        assertTrue(
            logger.messages.toString(),
            messagesMatching(logger, "dropped").isEmpty()
        )
    }

    @Test
    fun testWherePseudoWarns() {
        val logger = parseWithRecording("rect:where(.a) { fill: #0f0; }")
        assertEquals(logger.messages.toString(), 1, messagesMatching(logger, ":where").size)
        assertTrue(
            logger.messages.toString(),
            messagesMatching(logger, "dropped").isEmpty()
        )
    }

    @Test
    fun testSupportedPseudoStaysSilent() {
        val logger = parseWithRecording("rect:first-child { fill: #0f0; }")
        assertTrue(logger.messages.toString(), logger.messages.isEmpty())
    }

    @Test
    fun testFreshParseLogsAfresh() {
        val css = "rect:hover { fill: #0f0; }"
        assertEquals(1, parseWithRecording(css).messages.size)
        assertEquals(1, parseWithRecording(css).messages.size)
    }

    @Test
    fun testBareContextLogsEveryTime() {
        val logger = RecordingLoggerContext()
        logger.logUnsupportedPseudoClass("hover")
        logger.logUnsupportedPseudoClass("hover")
        assertEquals(2, logger.messages.size)
    }
}
