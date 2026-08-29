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

package hu.oandras.ksvg.render.text

import android.graphics.Typeface
import android.os.Build
import hu.oandras.ksvg.dom.style.FontStyle
import hu.oandras.ksvg.dom.style.Style
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(manifest = Config.NONE, sdk = [Build.VERSION_CODES.O])
class TypefaceResolverTest {

    @Test
    fun testCheckGenericFontNormal() {
        val tf = checkGenericFont("serif", Style.FONT_WEIGHT_NORMAL, FontStyle.normal)
        assertNotNull(tf)
        assertEquals(Typeface.NORMAL, tf!!.style)
    }

    @Test
    fun testCheckGenericFontItalic() {
        val tf = checkGenericFont("serif", Style.FONT_WEIGHT_NORMAL, FontStyle.italic)
        assertNotNull(tf)
        assertEquals(Typeface.ITALIC, tf!!.style)
    }

    @Test
    fun testCheckGenericFontOblique() {
        // This is what we fixed: oblique should also result in Typeface.ITALIC style for generic fonts fallback
        val tf = checkGenericFont("serif", Style.FONT_WEIGHT_NORMAL, FontStyle.oblique)
        assertNotNull(tf)
        assertEquals("Oblique should fallback to italic typeface style", Typeface.ITALIC, tf!!.style)
    }

    @Test
    fun testCheckGenericFontBoldOblique() {
        val tf = checkGenericFont("serif", Style.FONT_WEIGHT_BOLD, FontStyle.oblique)
        assertNotNull(tf)
        assertEquals(Typeface.BOLD_ITALIC, tf!!.style)
    }
}
