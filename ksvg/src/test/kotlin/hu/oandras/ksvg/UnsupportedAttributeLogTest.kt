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
import hu.oandras.ksvg.logger.logUnsupportedAttribute
import hu.oandras.ksvg.logger.wrapAsUnsupportedFeatureScope
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class UnsupportedAttributeLogTest {

    private fun parseWithRecording(svg: String): RecordingLoggerContext {
        val logger = RecordingLoggerContext()
        SVGImpl.getFromString(svg, loggerContext = logger)
        return logger
    }

    private fun doc(vararg body: String): String =
        "<svg xmlns=\"http://www.w3.org/2000/svg\">" + body.joinToString("") + "</svg>"

    private fun messagesMatching(logger: RecordingLoggerContext, needle: String): List<String> =
        logger.messages.filter { it.contains(needle) }

    @Test
    fun testSingleUnknownAttributeLogsOnce() {
        val logger = parseWithRecording(doc("<rect foo=\"bar\" width=\"10\" height=\"10\"/>"))
        assertEquals(1, logger.messages.size)
        assertTrue(logger.messages[0], logger.messages[0].contains("<foo>"))
    }

    @Test
    fun testDedupIsPerNameOnAWrappedContext() {
        val delegate = RecordingLoggerContext()
        val wrapped = delegate.wrapAsUnsupportedFeatureScope()
        wrapped.logUnsupportedAttribute("foo")
        wrapped.logUnsupportedAttribute("foo")
        assertEquals(1, delegate.messages.size)
        wrapped.logUnsupportedAttribute("bar")
        assertEquals(2, delegate.messages.size)
    }

    @Test
    fun testSameAttributeNameOnTwoElementsWarnsOnce() {
        val logger = parseWithRecording(
            doc("<rect foo=\"1\" width=\"10\" height=\"10\"/>", "<circle foo=\"2\" r=\"5\"/>")
        )
        assertEquals(logger.messages.toString(), 1, logger.messages.size)
    }

    @Test
    fun testSameUnsupportedValueOnTwoElementsWarnsOnce() {
        val logger = parseWithRecording(
            doc("<text white-space=\"pre-wrap\">a</text>", "<text white-space=\"pre-line\">b</text>")
        )
        assertEquals(logger.messages.toString(), 1, logger.messages.size)
    }

    @Test
    fun testDistinctNamesLogSeparately() {
        val logger = parseWithRecording(doc("<rect foo=\"1\" bar=\"2\" width=\"10\" height=\"10\"/>"))
        assertEquals(1, messagesMatching(logger, "<foo>").size)
        assertEquals(1, messagesMatching(logger, "<bar>").size)
    }

    @Test
    fun testKnownAttributeNotApplicableToElementStaysSilent() {
        val logger = parseWithRecording(doc("<rect r=\"5\" width=\"10\" height=\"10\"/>"))
        assertTrue(logger.messages.toString(), logger.messages.isEmpty())
    }

    @Test
    fun testSupportedPresentationAttributesSilent() {
        val logger = parseWithRecording(
            doc("<rect fill=\"red\" stroke-width=\"2\" opacity=\"0.5\" width=\"10\" height=\"10\"/>")
        )
        assertTrue(logger.messages.toString(), logger.messages.isEmpty())
    }

    @Test
    fun testUnknownCssPropertyStaysSilent() {
        val logger = parseWithRecording(doc("<style>rect { totally-unknown-prop: 1; }</style>"))
        assertTrue(logger.messages.toString(), logger.messages.isEmpty())
    }

    @Test
    fun testUnknownAttributeAndUnsupportedFeatureValueLogSeparately() {
        val logger = parseWithRecording(doc("<text foo=\"bar\" white-space=\"pre-wrap\">a</text>"))
        assertEquals(1, messagesMatching(logger, "<foo>").size)
        assertEquals(1, messagesMatching(logger, "white-space wrapping").size)
    }

    @Test
    fun testSupportedFeatureValueStaysSilent() {
        val logger = parseWithRecording(doc("<text white-space=\"normal\">a</text>"))
        assertTrue(logger.messages.toString(), logger.messages.isEmpty())
    }

    @Test
    fun testNamespacePrefixStrippedFromReportedName() {
        val svg = "<svg xmlns=\"http://www.w3.org/2000/svg\" " +
            "xmlns:inkscape=\"http://www.inkscape.org/namespaces/inkscape\">" +
            "<rect inkscape:label=\"x\" width=\"10\" height=\"10\"/></svg>"
        val logger = parseWithRecording(svg)
        assertEquals(1, logger.messages.size)
        assertTrue(logger.messages[0], logger.messages[0].contains("<label>"))
    }

    @Test
    fun testEmptyAttributeValueStaysSilent() {
        val logger = parseWithRecording(doc("<rect foo=\"\" width=\"10\" height=\"10\"/>"))
        assertTrue(logger.messages.toString(), logger.messages.isEmpty())
    }

    @Test
    fun testFreshParseLogsAfresh() {
        val svg = doc("<rect foo=\"bar\" width=\"10\" height=\"10\"/>")
        assertEquals(1, parseWithRecording(svg).messages.size)
        assertEquals(1, parseWithRecording(svg).messages.size)
    }

    @Test
    fun testBareContextLogsEveryTime() {
        val logger = RecordingLoggerContext()
        logger.logUnsupportedAttribute("foo")
        logger.logUnsupportedAttribute("foo")
        assertEquals(2, logger.messages.size)
    }
}
