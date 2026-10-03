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
import hu.oandras.ksvg.dom.core.ElementBase
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

/**
 * Pins the raw-attribute map contract: `id`/`class`/`style`/`d` are typed fields
 * (or never read back) and must not be retained as raw strings; everything else is.
 */
@RunWith(RobolectricTestRunner::class)
class AttributesMapTest {

    private fun elementById(svg: String, id: String): ElementBase {
        val doc = SVG.getFromString(svg) as SVGImpl
        return doc.getElementById(id) as ElementBase
    }

    @Test
    fun skipsTypedAndUnreadAttributes() {
        val el = elementById(
            """
            <svg width="100" height="100" xmlns="http://www.w3.org/2000/svg">
              <path id="p" class="c" style="fill:red" d="M0,0L10,10"/>
            </svg>
            """.trimIndent(),
            "p"
        )
        assertNull(el.attributes)
    }

    @Test
    fun keepsOtherAttributes() {
        val el = elementById(
            """
            <svg width="100" height="100" xmlns="http://www.w3.org/2000/svg">
              <rect id="r" fill="red" x="1" y="2" width="10" height="10"/>
            </svg>
            """.trimIndent(),
            "r"
        )
        val attrs = el.attributes
        assertEquals("red", attrs?.get("fill"))
        // Typed duplicates are not retained.
        assertEquals(null, attrs?.get("id"))
    }
}
