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
package hu.oandras.ksvg

import android.graphics.Canvas
import android.os.Build
import hu.oandras.ksvg.mocks.MockCanvas
import hu.oandras.ksvg.mocks.MockPaint
import hu.oandras.ksvg.mocks.MockPath
import hu.oandras.ksvg.mocks.asShadow
import hu.oandras.ksvg.render.createBitmap
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(manifest = Config.NONE, sdk = [Build.VERSION_CODES.O], shadows = [MockCanvas::class, MockPath::class, MockPaint::class])
class TRefRenderTest {

    @Test
    fun trefAppliesItsOwnFontStyling() {
        val svg = SVG.getFromString(
            """
            <svg width="200" height="200">
              <defs><text id="ref">Hello</text></defs>
              <text><tref href="#ref" style="font-stretch: ultra-expanded"/></text>
            </svg>
            """.trimIndent()
        )

        val bitmap = createBitmap(200, 200)
        val canvas = Canvas(bitmap)
        svg.renderToCanvas(canvas)

        val mock = canvas.asShadow()
        // The <tref> inherits the parent text's default width (100) unless its own
        // font-stretch is applied, in which case it becomes ultra-expanded (200).
        assertEquals(
            sortVariations("'wdth' 200,'wght' 400"),
            sortVariations(mock.paintProp(4, "fv"))
        )
    }

    private fun sortVariations(str: String): List<String> {
        return str.split(",").map { it.trim() }.sorted()
    }
}