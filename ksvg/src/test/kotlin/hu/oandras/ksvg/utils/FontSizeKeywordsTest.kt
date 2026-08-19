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

import hu.oandras.ksvg.css.CssUnit
import hu.oandras.ksvg.parser.FontSizeKeywords
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class FontSizeKeywordsTest {

    @Test
    fun testGetKeywords() {
        assertEquals(0.694f, FontSizeKeywords.get("xx-small")!!.value)
        assertEquals(CssUnit.pt, FontSizeKeywords.get("xx-small")!!.unit)

        assertEquals(0.833f, FontSizeKeywords.get("x-small")!!.value)
        assertEquals(10.0f, FontSizeKeywords.get("small")!!.value)
        assertEquals(12.0f, FontSizeKeywords.get("medium")!!.value)
        assertEquals(14.4f, FontSizeKeywords.get("large")!!.value)
        assertEquals(17.3f, FontSizeKeywords.get("x-large")!!.value)
        assertEquals(20.7f, FontSizeKeywords.get("xx-large")!!.value)

        assertEquals(83.33f, FontSizeKeywords.get("smaller")!!.value)
        assertEquals(CssUnit.percent, FontSizeKeywords.get("smaller")!!.unit)

        assertEquals(120f, FontSizeKeywords.get("larger")!!.value)
        assertEquals(CssUnit.percent, FontSizeKeywords.get("larger")!!.unit)
    }

    @Test
    fun testInvalidKeywords() {
        assertNull(FontSizeKeywords.get(null))
        assertNull(FontSizeKeywords.get(""))
        assertNull(FontSizeKeywords.get("big"))
        assertNull(FontSizeKeywords.get("12pt"))
    }
}
