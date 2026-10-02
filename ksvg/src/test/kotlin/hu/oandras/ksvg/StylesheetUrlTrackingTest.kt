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

import android.os.Build
import hu.oandras.ksvg.ExternalFileResolver.ResolvedStylesheet
import hu.oandras.ksvg.dom.SVGImpl
import hu.oandras.ksvg.logger.NoopLoggerContext
import hu.oandras.ksvg.mocks.MockCanvas
import hu.oandras.ksvg.mocks.MockPaint
import hu.oandras.ksvg.mocks.MockPath
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(
    manifest = Config.NONE,
    sdk = [Build.VERSION_CODES.O],
    shadows = [MockCanvas::class, MockPath::class, MockPaint::class]
)
class StylesheetUrlTrackingTest {

    private class RecordingResolver(
        private val sheets: Map<String, String>,
    ) : ExternalFileResolver() {
        val calls = mutableListOf<Pair<String, String?>>()

        override fun resolveCSSStyleSheet(url: String, baseUri: String?): ResolvedStylesheet? {
            calls.add(url to baseUri)
            val effective = resolveHrefAgainstBase(baseUri, url)
            return sheets[effective]?.let { ResolvedStylesheet(effective, it) }
        }
    }

    private fun svgDoc(piHref: String, body: String = "<rect width=\"10\" height=\"10\"/>"): String {
        return "<?xml-stylesheet href=\"$piHref\" type=\"text/css\"?>" +
            "<svg xmlns=\"http://www.w3.org/2000/svg\">$body</svg>"
    }

    @Test
    fun piHref_resolvesAgainstDocumentBase_importChainsOnSheetUrl() {
        val resolver = RecordingResolver(
            mapOf(
                "https://cdn.example/docs/styles/main.css" to
                    "@import \"base.css\"; rect { fill: red; }",
                "https://cdn.example/docs/styles/base.css" to
                    "rect { stroke: blue; }",
            )
        )
        SVGImpl.getFromString(
            svgDoc("styles/main.css"),
            loggerContext = NoopLoggerContext,
            externalFileResolver = resolver,
            documentBaseUrl = "https://cdn.example/docs/doc.svg",
        )
        assertEquals(
            listOf(
                "styles/main.css" to "https://cdn.example/docs/doc.svg",
                "base.css" to "https://cdn.example/docs/styles/main.css",
            ),
            resolver.calls,
        )
    }

    @Test
    fun noDocumentBase_nullBasePassedThrough() {
        val resolver = RecordingResolver(
            mapOf("https://cdn.example/main.css" to "rect { fill: red; }")
        )
        SVGImpl.getFromString(
            svgDoc("https://cdn.example/main.css"),
            loggerContext = NoopLoggerContext,
            externalFileResolver = resolver,
        )
        assertEquals(listOf("https://cdn.example/main.css" to null), resolver.calls)
    }

    @Test
    fun embeddedStyleImport_resolvesAgainstDocumentBase() {
        val resolver = RecordingResolver(
            mapOf("https://cdn.example/docs/base.css" to "rect { fill: red; }")
        )
        SVGImpl.getFromString(
            "<svg xmlns=\"http://www.w3.org/2000/svg\">" +
                "<style>@import \"base.css\";</style>" +
                "<rect width=\"10\" height=\"10\"/>" +
                "</svg>",
            loggerContext = NoopLoggerContext,
            externalFileResolver = resolver,
            documentBaseUrl = "https://cdn.example/docs/doc.svg",
        )
        assertEquals(
            listOf("base.css" to "https://cdn.example/docs/doc.svg"),
            resolver.calls,
        )
    }

    @Test
    fun importCycle_terminates() {
        val resolver = RecordingResolver(
            mapOf(
                "https://cdn.example/a.css" to "@import \"b.css\";",
                "https://cdn.example/b.css" to "@import \"a.css\";",
            )
        )
        SVGImpl.getFromString(
            svgDoc("https://cdn.example/a.css"),
            loggerContext = NoopLoggerContext,
            externalFileResolver = resolver,
        )
        // a -> b -> a(dropped as cycle): exactly 3 fetches, then termination.
        assertEquals(3, resolver.calls.size)
    }

    @Test
    fun deepChain_stopsAtDepthCap() {
        val sheets = mutableMapOf<String, String>()
        for (i in 0..12) {
            sheets["https://cdn.example/$i.css"] = "@import \"${i + 1}.css\";"
        }
        val resolver = RecordingResolver(sheets)
        SVGImpl.getFromString(
            svgDoc("https://cdn.example/0.css"),
            loggerContext = NoopLoggerContext,
            externalFileResolver = resolver,
        )
        // PI fetch + 8 nested imports + 1 dropped over-cap fetch.
        assertEquals(10, resolver.calls.size)
    }

    @Test
    fun documentBase_anchorsXmlBaseChain() {
        val resolver = RecordingResolver(emptyMap())
        val doc = SVGImpl.getFromString(
            "<svg xmlns=\"http://www.w3.org/2000/svg\" xml:base=\"img/\">" +
                "<image id=\"i\" href=\"a.png\" width=\"10\" height=\"10\"/>" +
                "</svg>",
            loggerContext = NoopLoggerContext,
            externalFileResolver = resolver,
            documentBaseUrl = "https://cdn.example/docs/doc.svg",
        )
        val image = doc.getElementById("i") as hu.oandras.ksvg.dom.core.Image
        assertEquals("https://cdn.example/docs/img/", image.xmlBase)
    }
}
