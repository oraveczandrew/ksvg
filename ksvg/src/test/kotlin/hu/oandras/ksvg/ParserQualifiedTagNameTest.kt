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
import hu.oandras.ksvg.dom.core.Group
import hu.oandras.ksvg.parser.SVGParserImpl
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.xml.sax.helpers.AttributesImpl

/**
 * The qualified tag name is needed only when an XML frontend does not supply a
 * local name. Ordinary prefixed elements still dispatch on the local name, and
 * the separate prefix is used only for that rare fallback.
 */
@RunWith(RobolectricTestRunner::class)
class ParserQualifiedTagNameTest {
    private class RecordingLoggerContext : LoggerContext {
        val messages = mutableListOf<String>()

        override fun log(level: Int, tag: String, message: String) {
            messages.add(message)
        }

        override fun isLoggable(tag: String, level: Int): Boolean = true
    }

    @Test
    fun prefixedElementDispatchesOnLocalName() {
        val test = "<svg xmlns=\"http://www.w3.org/2000/svg\" xmlns:s=\"http://www.w3.org/2000/svg\">" +
            "<s:g />" +
            "</svg>"
        val svg: SVGImpl = SVGImpl.getFromString(test, loggerContext = NoopLoggerContext)
        val root = checkNotNull(svg.rootElement)

        assertEquals(1, root.childCount())
        assertIs<Group>(root.getChildren()[0])
    }

    @Test
    fun emptyLocalNamePrefersSuppliedQualifiedName() {
        val logger = RecordingLoggerContext()
        val parser = SVGParserImpl(logger = logger)

        parser.startElement(
            "http://www.w3.org/2000/svg",
            "",
            "foo:bar",
            null,
            AttributesImpl()
        )

        assertEquals(listOf("Unsupported element <foo:bar> ignored"), logger.messages)
    }

    @Test
    fun emptyLocalNameFallsBackToSeparatePrefix() {
        val logger = RecordingLoggerContext()
        val parser = SVGParserImpl(logger = logger)

        parser.startElement(
            "http://www.w3.org/2000/svg",
            "",
            null,
            "foo",
            AttributesImpl()
        )

        // This preserves the historical XPP diagnostic, even though "foo:" is
        // not a dispatchable tag name.
        assertEquals(listOf("Unsupported element <foo:> ignored"), logger.messages)
    }
}
