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

import android.graphics.Bitmap
import hu.oandras.ksvg.render.createBitmap
import hu.oandras.ksvg.test.renderWithLibrary
import hu.oandras.ksvg.utils.alpha
import hu.oandras.ksvg.utils.red
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.GraphicsMode

/**
 * `transform-origin` (+ `transform-box`): the `transform` attribute rotates
 * around the resolved pivot instead of the local origin.
 *
 * Setup: 40x40 rect at (30,30), `rotate(45)` (about local 0,0 by default).
 * About the fill-box center (50,50) the rect becomes a centered diamond:
 * the center pixel stays red, the old corner (30,30) goes transparent.
 * About the default origin the whole rect swings away: the center goes
 * transparent. Pivot pixels never move: `left top` keeps (30,30) red.
 * Assertions avoid edge pixels (only pivots and far-field points).
 */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class TransformOriginTest {

    private fun render(rectAttrs: String): Bitmap {
        val svg = """
            <svg xmlns="http://www.w3.org/2000/svg" width="100" height="100" viewBox="0 0 100 100">
              <rect x="30" y="30" width="40" height="40" fill="red" transform="rotate(45)" $rectAttrs/>
            </svg>
        """.trimIndent()
        return renderWithLibrary(
            svg,
            createBitmap(100, 100, Bitmap.Config.ARGB_8888),
        )
    }

    private fun assertRed(p: Int) {
        assertEquals("expected opaque red, was ${p.toUInt().toString(16)}", 255, p.alpha)
        assertEquals("expected opaque red, was ${p.toUInt().toString(16)}", 255, p.red)
    }

    private fun assertTransparent(p: Int) {
        assertEquals("expected transparent, was ${p.toUInt().toString(16)}", 0, p.alpha)
    }

    @Test
    fun defaultOriginSwingsRectAway() {
        val out = render("")
        // Rotation about (0,0) moves the rect: old center is empty.
        assertTransparent(out.getPixel(50, 50))
    }

    @Test
    fun fillBoxCenterKeepsCenter() {
        val out = render("transform-origin=\"center\" transform-box=\"fill-box\"")
        // Diamond centered at (50,50): center and inner points stay red...
        assertRed(out.getPixel(50, 50))
        assertRed(out.getPixel(50, 30))
        // ...while the old corner leaves.
        assertTransparent(out.getPixel(30, 30))
    }

    @Test
    fun fillBoxLeftTopKeepsCorner() {
        val out = render("transform-origin=\"left top\" transform-box=\"fill-box\"")
        // Near-pivot interior point (the pivot pixel itself is a boundary
        // case under antialiasing): rotated (1,2) offset lands at
        // (u,v)=(2.12,0.71), strictly inside the 40x40 area.
        assertRed(out.getPixel(31, 32))
    }

    @Test
    fun viewBoxOriginExplicit() {
        // Explicit 0 0 behaves like the default (rotation about the origin).
        val out = render("transform-origin=\"0 0\"")
        assertTransparent(out.getPixel(50, 50))
    }

    @Test
    fun originNotInheritedFromGroup() {
        // transform-origin is not inherited: set on <g>, the child rotates
        // about its own (default) origin.
        val svg = """
            <svg xmlns="http://www.w3.org/2000/svg" width="100" height="100" viewBox="0 0 100 100">
              <g transform-origin="center" transform-box="fill-box">
                <rect x="30" y="30" width="40" height="40" fill="red" transform="rotate(45)"/>
              </g>
            </svg>
        """.trimIndent()
        val out = renderWithLibrary(
            svg,
            createBitmap(100, 100, Bitmap.Config.ARGB_8888),
        )
        assertTransparent(out.getPixel(50, 50))
    }
}
