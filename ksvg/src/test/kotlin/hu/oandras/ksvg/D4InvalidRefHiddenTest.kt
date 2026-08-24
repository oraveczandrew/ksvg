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
class D4InvalidRefHiddenTest {

    private fun render(extra: String): Bitmap {
        val svg = """
            <svg width="100" height="100" xmlns="http://www.w3.org/2000/svg">
              <defs>
                <clipPath id="goodClip"><rect x="0" y="0" width="50" height="100"/></clipPath>
                <mask id="goodMask"><rect x="0" y="0" width="50" height="100" fill="white"/></mask>
                <rect id="notAClip" x="0" y="0" width="10" height="10"/>
              </defs>
              $extra
            </svg>
        """.trimIndent()
        return renderWithLibrary(svg, createBitmap(100, 100))
    }


    @Test
    fun missingClipPathReferenceHidesElement() {
        val bitmap = render("""<rect x="10" y="10" width="80" height="80" fill="red" clip-path="url(#nope)"/>""")
        assertTrue("Element with missing clip-path ref must be hidden", !isRed(bitmap, 25, 50))
        assertTrue(!isRed(bitmap, 75, 50))
    }

    @Test
    fun wrongTypeClipPathReferenceHidesElement() {
        val bitmap = render("""<rect x="10" y="10" width="80" height="80" fill="red" clip-path="url(#notAClip)"/>""")
        assertTrue("Element with wrong-type clip-path ref must be hidden", !isRed(bitmap, 25, 50))
    }

    @Test
    fun validClipPathClips() {
        val bitmap = render("""<rect x="10" y="10" width="80" height="80" fill="red" clip-path="url(#goodClip)"/>""")
        assertTrue("Left half visible", isRed(bitmap, 25, 50))
        assertTrue("Right half clipped", !isRed(bitmap, 75, 50))
    }

    @Test
    fun missingMaskReferenceHidesElement() {
        val bitmap = render("""<rect x="10" y="10" width="80" height="80" fill="red" mask="url(#nope)"/>""")
        assertTrue("Element with missing mask ref must be hidden", !isRed(bitmap, 25, 50))
        assertTrue(!isRed(bitmap, 75, 50))
    }

    @Test
    fun wrongTypeMaskReferenceHidesElement() {
        val bitmap = render("""<rect x="10" y="10" width="80" height="80" fill="red" mask="url(#notAClip)"/>""")
        assertTrue("Element with wrong-type mask ref must be hidden", !isRed(bitmap, 25, 50))
    }
}
