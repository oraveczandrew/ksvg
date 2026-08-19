/*
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

package hu.oandras.ksvg.utils

import hu.oandras.ksvg.dom.core.SVGAttr
import hu.oandras.ksvg.parser.forEachKeyValue
import hu.oandras.ksvg.parser.getSVGAttr
import hu.oandras.ksvg.parser.getTrimmedValue
import org.junit.Assert.assertEquals
import org.junit.Test
import org.xml.sax.helpers.AttributesImpl

class AttributesTest {

    @Test
    fun testGetTrimmedValue() {
        val attrs = AttributesImpl()
        attrs.addAttribute("", "width", "width", "CDATA", "  100  ")
        
        assertEquals("100", attrs.getTrimmedValue(0))
    }

    @Test
    fun testGetSVGAttr() {
        val attrs = AttributesImpl()
        attrs.addAttribute("", "width", "width", "CDATA", "100")
        attrs.addAttribute("", "fill-opacity", "fill-opacity", "CDATA", "0.5")

        assertEquals(SVGAttr.width, attrs.getSVGAttr(0))
        assertEquals(SVGAttr.fill_opacity, attrs.getSVGAttr(1))
    }

    @Test
    fun testForEachKeyValue() {
        val attrs = AttributesImpl()
        attrs.addAttribute("", "width", "width", "CDATA", " 100 ")
        attrs.addAttribute("", "height", "height", "CDATA", " 200 ")

        val results = mutableListOf<Pair<SVGAttr, String>>()
        attrs.forEachKeyValue { _, attr, value ->
            results.add(attr to value)
        }

        assertEquals(2, results.size)
        assertEquals(SVGAttr.width to "100", results[0])
        assertEquals(SVGAttr.height to "200", results[1])
    }
}
