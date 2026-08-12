/*
 *    Copyright 2013-2020 Paul LeBeau, Cave Rock Software Ltd.
 *    Copyright 2026 András Oravecz <info@oandras.hu>
 *
 *    Licensed under the Apache License, Version 2.0 (the "License");
 *    you may not use this file except in compliance with the License.
 *    You may obtain a copy of the License at
 *
 *        http://www.apache.org/licenses/LICENSE-2.0
 *
 *    Unless required by applicable law or agreed to in writing, software
 *    distributed under the License is distributed on an "AS IS" BASIS,
 *    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *    See the License for the specific language governing permissions and
 *    limitations under the License.
 */

package hu.oandras.ksvg

import hu.oandras.ksvg.dom.SVGImpl
import hu.oandras.ksvg.dom.SvgObject
import org.junit.Assert.assertEquals
import org.junit.BeforeClass
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import java.io.InputStream

@Suppress("SpellCheckingInspection")
@RunWith(RobolectricTestRunner::class)
class FileParsingTest {

    @Test
    fun testParse() {
        val svg = SVGImpl.getFromInputStream(openFile("hungary_location_map.svg"))
        assertNotNull(svg)
        assertEquals("1.0", svg.documentSVGVersion)
        assertEquals(1209.7271f, svg.documentWidth, 0.0001f)
        assertEquals(746.20312f, svg.documentHeight, 0.0001f)
        assertEquals("", svg.documentTitle)
        assertEquals("", svg.documentDescription)
        assertEquals(1.621176f, svg.documentAspectRatio, 0.0001f)
        assertEquals(0, svg.viewList.size)

        val viewBox = svg.documentViewBox
        assertNotNull(viewBox)
        assertEquals(0f, viewBox.left, 0.0001f)
        assertEquals(0f, viewBox.top, 0.0001f)
        assertEquals(1209.727f, viewBox.right, 0.0001f)
        assertEquals(746.20312f, viewBox.bottom, 0.0001f)

        val rootElement = svg.rootElement
        assertNotNull(rootElement)
        assertEquals("svg2", rootElement.id)
        assertEquals(5, rootElement.childCount())

        val children = rootElement.getChildren()
        assertEquals(5, children.size)

        val child0 = children[0]
        assertIs<SvgObject.Defs>(child0)
        assertEquals("defs131", child0.id)
        assertEquals(0, child0.childCount())

        val child1 = children[1]
        assertIs<SvgObject.Group>(child1)
        assertEquals("Hilfslinien_anzeigen", child1.id)
        assertEquals(0, child1.childCount())

        val child2 = children[2]
        assertIs<SvgObject.Group>(child2)
        assertEquals("Land", child2.id)
        assertEquals(22, child2.childCount())
        val landChildren = child2.getChildren()
        val landChild0 = landChildren[0]
        assertIs<SvgObject.Rect>(landChild0)
        assertEquals("rect8", landChild0.id)
        val landChild21 = landChildren[21]
        assertIs<SvgObject.Polygon>(landChild21)
        assertEquals("polygon50", landChild21.id)

        val child3 = children[3]
        assertIs<SvgObject.Group>(child3)
        assertEquals("Seen", child3.id)
        assertEquals(2, child3.childCount())
        val seenChildren = child3.getChildren()
        val seenChild0 = seenChildren[0]
        assertIs<SvgObject.Polygon>(seenChild0)
        assertEquals("polygon53", seenChild0.id)
        val seenChild1 = seenChildren[1]
        assertIs<SvgObject.Path>(seenChild1)
        assertEquals("path55", seenChild1.id)

        val child4 = children[4]
        assertIs<SvgObject.Group>(child4)
        assertEquals("Linien", child4.id)
        assertEquals(36, child4.childCount())
        val linienChild0 = child4.getChildren()[0]
        assertIs<SvgObject.PolyLine>(linienChild0)
    }

    companion object {

        @Suppress("SameParameterValue")
        private fun openFile(fileName: String): InputStream {
            return this::class.java.getResourceAsStream(fileName)!!
        }

        @JvmStatic
        @BeforeClass
        fun warmUp() {
            val _ = SVGImpl.getFromInputStream(openFile("hungary_location_map.svg"))
        }
    }
}