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
import hu.oandras.ksvg.dom.core.Image
import hu.oandras.ksvg.mocks.MockCanvas
import hu.oandras.ksvg.mocks.MockPaint
import hu.oandras.ksvg.mocks.MockPath
import hu.oandras.ksvg.render.createBitmap
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(manifest = Config.NONE, shadows = [MockCanvas::class, MockPath::class, MockPaint::class])
class XmlBaseTest {

    // --- pure helpers ---

    @Test
    fun effectiveBase_composesNested() {
        assertEquals(
            "https://cdn.example/svg/img/",
            effectiveXmlBase("https://cdn.example/svg/", "img/")
        )
    }

    @Test
    fun effectiveBase_missingOwnKeepsParent() {
        assertEquals("https://cdn.example/a/", effectiveXmlBase("https://cdn.example/a/", null))
        assertNull(effectiveXmlBase(null, null))
    }

    @Test
    fun resolveHref_fragmentAndAbsolutePassThrough() {
        assertEquals("#grad", resolveHrefAgainstBase("https://cdn.example/svg/", "#grad"))
        assertEquals(
            "https://other.example/a.png",
            resolveHrefAgainstBase("https://cdn.example/svg/", "https://other.example/a.png")
        )
        assertEquals(
            "data:image/png;base64,AAA",
            resolveHrefAgainstBase("https://cdn.example/svg/", "data:image/png;base64,AAA")
        )
        assertEquals("img/a.png", resolveHrefAgainstBase(null, "img/a.png"))
    }

    @Test
    fun resolveHref_relativeAgainstBase() {
        assertEquals(
            "https://cdn.example/svg/img/a.png",
            resolveHrefAgainstBase("https://cdn.example/svg/", "img/a.png")
        )
    }

    // --- DOM parsing ---

    private fun parse(svg: String): SVGImpl {
        return SVG.getFromString(svg = svg) as SVGImpl
    }

    @Test
    fun imageHref_staysRaw_baseTracked() {
        val doc = parse(
            "<svg xmlns=\"http://www.w3.org/2000/svg\" xml:base=\"https://cdn.example/svg/\">" +
                "<image id=\"i\" href=\"img/a.png\" width=\"10\" height=\"10\"/>" +
                "</svg>"
        )
        val image = doc.getElementById("i") as Image
        assertEquals("img/a.png", image.href)
        assertEquals("https://cdn.example/svg/", image.xmlBase)
    }

    @Test
    fun nestedBase_composes() {
        val doc = parse(
            "<svg xmlns=\"http://www.w3.org/2000/svg\" xml:base=\"https://cdn.example/svg/\">" +
                "<g xml:base=\"img/\">" +
                "<image id=\"i\" href=\"a.png\" width=\"10\" height=\"10\"/>" +
                "</g>" +
                "</svg>"
        )
        val image = doc.getElementById("i") as Image
        assertEquals("https://cdn.example/svg/img/", image.xmlBase)
    }

    @Test
    fun fragmentRef_untouched() {
        val doc = parse(
            "<svg xmlns=\"http://www.w3.org/2000/svg\" xml:base=\"https://cdn.example/svg/\">" +
                "<defs><rect id=\"r\" width=\"10\" height=\"10\"/></defs>" +
                "<use id=\"u\" href=\"#r\"/>" +
                "</svg>"
        )
        val use = doc.getElementById("u") as hu.oandras.ksvg.dom.core.Use
        assertEquals("#r", use.href)
    }

    // --- resolver + hit regions carry the base ---

    private class RecordingResolver : ExternalFileResolver() {
        val imageCalls = mutableListOf<Pair<String, String?>>()
        override fun resolveImage(filename: String, baseUri: String?): android.graphics.Bitmap? {
            imageCalls.add(filename to baseUri)
            return null
        }
    }

    @Test
    fun render_imageResolverReceivesBase() {
        val resolver = RecordingResolver()
        val doc = SVG.getFromString(
            svg = "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"200\" height=\"200\" " +
                "xml:base=\"https://cdn.example/svg/\">" +
                "<image href=\"img/a.png\" width=\"10\" height=\"10\"/>" +
                "</svg>",
            externalFileResolver = resolver
        ) as SVGImpl
        doc.renderToCanvas(Canvas(createBitmap(200, 200)))
        assertEquals(listOf("img/a.png" to "https://cdn.example/svg/"), resolver.imageCalls)
    }

    @Test
    fun hitRegion_carriesBase() {
        val doc = SVG.getFromString(
            svg = "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"200\" height=\"200\" " +
                "xml:base=\"https://cdn.example/docs/\">" +
                "<a href=\"page.html\">" +
                "<rect x=\"10\" y=\"10\" width=\"100\" height=\"50\"/>" +
                "</a>" +
                "</svg>"
        ) as SVGImpl
        doc.renderToCanvas(Canvas(createBitmap(200, 200)))
        val regions = doc.getHitRegions()
        assertEquals(1, regions.size)
        assertEquals("page.html", regions[0].href)
        assertEquals("https://cdn.example/docs/", regions[0].baseUri)
    }
}
