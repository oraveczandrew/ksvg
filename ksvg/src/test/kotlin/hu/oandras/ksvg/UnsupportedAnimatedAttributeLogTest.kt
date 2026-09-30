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

import android.graphics.Canvas
import hu.oandras.ksvg.dom.SVGImpl
import hu.oandras.ksvg.mocks.MockCanvas
import hu.oandras.ksvg.mocks.MockPaint
import hu.oandras.ksvg.mocks.MockPath
import hu.oandras.ksvg.render.createBitmap
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(manifest = Config.NONE, shadows = [MockCanvas::class, MockPath::class, MockPaint::class])
class UnsupportedAnimatedAttributeLogTest {

    private fun animatedDoc(attributeName: String, values: String): String =
        "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"20\" height=\"20\" viewBox=\"0 0 20 20\">" +
            "<rect width=\"2\" height=\"2\">" +
            "<animate attributeName=\"$attributeName\" values=\"$values\" dur=\"1s\" fill=\"freeze\"/>" +
            "</rect></svg>"

    private fun parseWithRecording(svg: String): Pair<SVGImpl, RecordingLoggerContext> {
        val logger = RecordingLoggerContext()
        val doc = SVGImpl.getFromString(svg, parseAnimations = true, loggerContext = logger)
        return doc to logger
    }

    private fun render(doc: SVGImpl) {
        doc.animationTimeMs = 500L
        doc.renderToCanvas(Canvas(createBitmap(20, 20)))
    }

    private fun messagesMatching(logger: RecordingLoggerContext, needle: String): List<String> =
        logger.messages.filter { it.contains(needle) }

    @Test
    fun testUnknownAnimateTargetWarnsOnceAtParse() {
        val doc = "<svg xmlns=\"http://www.w3.org/2000/svg\">" +
            "<rect width=\"10\" height=\"10\">" +
            "<animate attributeName=\"foo\" values=\"1;2\" dur=\"1s\"/>" +
            "</rect>" +
            "<circle r=\"5\">" +
            "<animate attributeName=\"foo\" values=\"1;2\" dur=\"1s\"/>" +
            "</circle></svg>"
        val (_, logger) = parseWithRecording(doc)
        assertEquals(logger.messages.toString(), 1, messagesMatching(logger, "<foo>").size)
    }

    @Test
    fun testUnhandledAnimateTargetWarnsOnceAtRender() {
        val (doc, logger) = parseWithRecording(animatedDoc("font-weight", "400;700"))
        assertTrue(
            "parse must stay silent, got: ${logger.messages}",
            logger.messages.isEmpty()
        )
        render(doc)
        assertEquals(logger.messages.toString(), 1, messagesMatching(logger, "font_weight").size)
        render(doc)
        assertEquals(
            "second render stays silent, got: ${logger.messages}",
            1,
            logger.messages.size
        )
    }

    @Test
    fun testHandledAnimateTargetStaysSilent() {
        val (doc, logger) = parseWithRecording(animatedDoc("opacity", "0;1"))
        render(doc)
        assertTrue(logger.messages.toString(), logger.messages.isEmpty())
    }

    @Test
    fun testBareContextLogsEveryTime() {
        val logger = RecordingLoggerContext()
        logger.logUnsupportedAnimatedAttribute("display")
        logger.logUnsupportedAnimatedAttribute("display")
        assertEquals(2, logger.messages.size)
    }
}
