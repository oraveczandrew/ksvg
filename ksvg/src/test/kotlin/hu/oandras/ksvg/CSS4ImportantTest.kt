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

import android.graphics.Bitmap
import hu.oandras.ksvg.render.createBitmap
import hu.oandras.ksvg.test.renderWithLibrary
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode

@RunWith(RobolectricTestRunner::class)
@Config(manifest = Config.NONE)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class CSS4ImportantTest {

    private fun render(svg: String): Bitmap = renderWithLibrary(svg, createBitmap(100, 100))

    @Test
    fun importantRuleBeatsInlineStyle() {
        val svg = """
            <svg width="100" height="100" xmlns="http://www.w3.org/2000/svg">
              <style>.t { fill: lime !important; }</style>
              <rect class="t" x="0" y="0" width="100" height="100" fill="red" style="fill: blue"/>
            </svg>
        """.trimIndent()
        assertTrue("!important rule must beat inline style", isGreen(render(svg), 50, 50))
    }

    @Test
    fun normalRuleDoesNotBeatInlineStyle() {
        val svg = """
            <svg width="100" height="100" xmlns="http://www.w3.org/2000/svg">
              <style>.t { fill: lime; }</style>
              <rect class="t" x="0" y="0" width="100" height="100" fill="red" style="fill: blue"/>
            </svg>
        """.trimIndent()
        assertTrue("Inline style must beat normal rule", isBlue(render(svg), 50, 50))
    }

    @Test
    fun importantInlineStyleBeatsImportantRule() {
        val svg = """
            <svg width="100" height="100" xmlns="http://www.w3.org/2000/svg">
              <style>.t { fill: red !important; }</style>
              <rect class="t" x="0" y="0" width="100" height="100"
                    style="fill: lime !important"/>
            </svg>
        """.trimIndent()
        assertTrue("Inline !important must beat rule !important", isGreen(render(svg), 50, 50))
    }

    @Test
    fun importantRuleBeatsPresentationAttribute() {
        val svg = """
            <svg width="100" height="100" xmlns="http://www.w3.org/2000/svg">
              <style>rect { fill: lime !important; }</style>
              <rect x="0" y="0" width="100" height="100" fill="red"/>
            </svg>
        """.trimIndent()
        assertTrue(isGreen(render(svg), 50, 50))
    }
}
