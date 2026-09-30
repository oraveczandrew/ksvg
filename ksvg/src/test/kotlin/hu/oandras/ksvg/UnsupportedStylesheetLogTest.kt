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
class UnsupportedStylesheetLogTest {

    private class NoopResolver : ExternalFileResolver()

    private class StubResolver(private val sheets: Map<String, String> = emptyMap()) : ExternalFileResolver() {
        override fun resolveCSSStyleSheet(url: String): String? = sheets[url]
    }

    private fun parseWithRecording(
        pi: String,
        resolver: ExternalFileResolver? = NoopResolver()
    ): RecordingLoggerContext {
        val logger = RecordingLoggerContext()
        SVGImpl.getFromString(
            "<?xml-stylesheet $pi?>" +
                "<svg xmlns=\"http://www.w3.org/2000/svg\">" +
                "<rect width=\"10\" height=\"10\"/>" +
                "</svg>",
            loggerContext = logger,
            externalFileResolver = resolver
        )
        return logger
    }

    private fun messagesMatching(logger: RecordingLoggerContext, needle: String): List<String> =
        logger.messages.filter { it.contains(needle) }

    @Test
    fun testAlternateStylesheetWarnsOnce() {
        val pi = "type=\"text/css\" href=\"alt.css\" alternate=\"yes\""
        val logger = parseWithRecording("$pi?><?xml-stylesheet $pi")
        val matching = messagesMatching(logger, "alternate")
        assertEquals(logger.messages.toString(), 1, matching.size)
    }

    @Test
    fun testPrimaryStylesheetStaysSilent() {
        val logger = parseWithRecording("type=\"text/css\" href=\"main.css\"")
        assertTrue(
            logger.messages.toString(),
            messagesMatching(logger, "alternate").isEmpty()
        )
    }

    @Test
    fun testNoResolverStaysSilent() {
        val logger = parseWithRecording(
            "type=\"text/css\" href=\"alt.css\" alternate=\"yes\"",
            resolver = null
        )
        assertTrue(logger.messages.toString(), logger.messages.isEmpty())
    }

    @Test
    fun testUnresolvableStylesheetHrefWarns() {
        val logger = parseWithRecording("type=\"text/css\" href=\"missing.css\"")
        assertEquals(logger.messages.toString(), 1, logger.messages.size)
        assertTrue(
            logger.messages.toString(),
            messagesMatching(logger, "missing.css").size == 1
        )
    }

    @Test
    fun testUnresolvableImportWarns() {
        val logger = RecordingLoggerContext()
        SVGImpl.getFromString(
            "<svg xmlns=\"http://www.w3.org/2000/svg\">" +
                "<style>@import \"missing.css\"; rect { fill: #0f0; }</style>" +
                "<rect width=\"10\" height=\"10\"/>" +
                "</svg>",
            loggerContext = logger,
            externalFileResolver = NoopResolver()
        )
        assertEquals(logger.messages.toString(), 1, logger.messages.size)
        assertTrue(
            logger.messages.toString(),
            messagesMatching(logger, "missing.css").size == 1
        )
    }

    @Test
    fun testResolvableStylesheetStaysSilent() {
        val logger = RecordingLoggerContext()
        SVGImpl.getFromString(
            "<?xml-stylesheet type=\"text/css\" href=\"main.css\"?>" +
                "<svg xmlns=\"http://www.w3.org/2000/svg\">" +
                "<rect width=\"10\" height=\"10\"/>" +
                "</svg>",
            loggerContext = logger,
            externalFileResolver = StubResolver(mapOf("main.css" to "rect { fill: #0f0; }"))
        )
        assertTrue(logger.messages.toString(), logger.messages.isEmpty())
    }

    @Test
    fun testFreshParseLogsAfresh() {
        val pi = "type=\"text/css\" href=\"alt.css\" alternate=\"yes\""
        assertEquals(1, parseWithRecording(pi).messages.size)
        assertEquals(1, parseWithRecording(pi).messages.size)
    }

    @Test
    fun testBareContextLogsEveryTime() {
        val logger = RecordingLoggerContext()
        logger.logUnsupportedFeature(UnsupportedFeature.ALTERNATE_STYLESHEET)
        logger.logUnsupportedFeature(UnsupportedFeature.ALTERNATE_STYLESHEET)
        assertEquals(2, logger.messages.size)
    }
}
