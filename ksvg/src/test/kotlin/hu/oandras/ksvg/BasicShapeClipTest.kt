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
import hu.oandras.ksvg.test.countPixels
import hu.oandras.ksvg.test.renderWithLibrary
import hu.oandras.ksvg.utils.blue
import hu.oandras.ksvg.utils.green
import hu.oandras.ksvg.utils.red
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.GraphicsMode

/**
 * CSS basic-shape `clip-path`
 * (`circle()`, `ellipse()`, `inset()`, `rect()`, `xywh()`, `polygon()`,
 * `path()`) clips the referencing element in its own user space. Pixel areas
 * pin the geometry; percentages resolve against the reference box (default
 * `fill-box`).
 */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class BasicShapeClipTest {

    private fun render(clip: String): Bitmap {
        val svg = """
            <svg xmlns="http://www.w3.org/2000/svg" width="200" height="200" viewBox="0 0 200 200">
              <rect width="200" height="200" fill="white"/>
              <rect width="200" height="200" fill="red" clip-path="$clip"/>
            </svg>
        """.trimIndent()
        return renderWithLibrary(svg, createBitmap(200, 200, Bitmap.Config.ARGB_8888))
    }

    private fun redPixels(out: Bitmap): Int =
        countPixels(out) { color -> color.red > 200 && color.green < 100 && color.blue < 100 }

    @Test
    fun circleClipsToDisc() {
        // pi * 50^2 ~= 7854.
        val red = redPixels(render("circle(50px at center center)"))
        assertTrue("circle area: $red, want 7000..8700", red in 7000..8700)
    }

    @Test
    fun circlePercentResolvesAgainstViewBoxDiagonal() {
        // 25% of (sqrt(200^2+200^2)/sqrt(2)) = 50 -> same disc as above.
        val red = redPixels(render("circle(25% at center center)"))
        assertTrue("percent circle area: $red, want 7000..8700", red in 7000..8700)
    }

    @Test
    fun ellipseClipsToEllipse() {
        // pi * 60 * 30 ~= 5655.
        val red = redPixels(render("ellipse(60px 30px at center center)"))
        assertTrue("ellipse area: $red, want 5000..6300", red in 5000..6300)
    }

    @Test
    fun insetClipsToRect() {
        // 100 x 100 = 10000.
        val red = redPixels(render("inset(50px)"))
        assertTrue("inset area: $red, want 9500..10500", red in 9500..10500)
    }

    @Test
    fun insetRoundClipsToRoundRect() {
        // 100x100 minus rounded corners (r=20): 10000 - 4*(400-314) ~= 9656.
        val red = redPixels(render("inset(50px round 20px)"))
        assertTrue("round inset area: $red, want 9000..10100", red in 9000..10100)
    }

    @Test
    fun polygonClipsToTriangle() {
        // Half of 200x200 = 20000.
        val red = redPixels(render("polygon(0px 0px, 200px 0px, 0px 200px)"))
        assertTrue("triangle area: $red, want 19000..21000", red in 19000..21000)
    }

    @Test
    fun polygonEvenOddCutsStarHole() {
        // Pentagram; evenodd leaves the inner pentagon empty (~7700),
        // nonzero fills the whole star (~11200).
        val star = "100px 0px, 158.8px 180.9px, 4.9px 69.1px, 195.1px 69.1px, 41.2px 180.9px, 100px 0px"
        val evenOdd = redPixels(render("polygon(evenodd, $star)"))
        assertTrue("evenodd star area: $evenOdd, want 6500..9000", evenOdd in 6500..9000)
        val nonZero = redPixels(render("polygon($star)"))
        assertTrue("nonzero star area: $nonZero, want 10000..12500", nonZero in 10000..12500)
    }

    @Test
    fun circleDefaultsToElementBox() {
        // 100x100 rect at the origin; circle(40px at center) resolves against
        // the element box -> full disc pi*40^2 ~= 5027. A view-box default
        // would center the disc at (100,100), leaving only a quarter (~1257).
        val svg = """
            <svg xmlns="http://www.w3.org/2000/svg" width="200" height="200" viewBox="0 0 200 200">
              <rect width="200" height="200" fill="white"/>
              <rect width="100" height="100" fill="red" clip-path="circle(40px at center center)"/>
            </svg>
        """.trimIndent()
        val out = renderWithLibrary(svg, createBitmap(200, 200, Bitmap.Config.ARGB_8888))
        val red = redPixels(out)
        assertTrue("element-box circle area: $red, want 4400..5600", red in 4400..5600)
    }

    @Test
    fun circleClosestSideTouchesNearestEdge() {
        // Center (100,100) in a 200x200 box -> r = 100 -> pi*100^2 ~= 31416.
        val red = redPixels(render("circle(closest-side at center center)"))
        assertTrue("closest-side area: $red, want 30000..32800", red in 30000..32800)
    }

    @Test
    fun circleFarthestSideCoversBox() {
        // At (0,100): distances to sides are 0/200/100/100 -> r = 200.
        // Disc ∩ canvas ~= 38300 (only the far corners fall outside).
        val red = redPixels(render("circle(farthest-side at left center)"))
        assertTrue("farthest-side area: $red, want 37000..39200", red in 37000..39200)
    }

    @Test
    fun ellipseSideKeywordsPerAxis() {
        // At (50,100): rx = closest-side = 50, ry = farthest-side = 100 ->
        // pi*50*100 ~= 15708, fully inside the canvas.
        val red = redPixels(render("ellipse(closest-side farthest-side at 50px center)"))
        assertTrue("side-keyword ellipse area: $red, want 14800..16600", red in 14800..16600)
    }

    @Test
    fun circleOffsetPosition() {
        // center = (0+60, 0+70) = (60,70), r = 40: disc fully inside the
        // canvas -> pi*40^2 ~= 5027. A keyword-only read would center at
        // (0,0) and clip the disc to a quarter.
        val red = redPixels(render("circle(40px at left 60px top 70px)"))
        assertTrue("offset-position area: $red, want 4400..5600", red in 4400..5600)
    }

    @Test
    fun circleVerticalFirstPosition() {
        // "at top left" is the vertical-keyword-first order of the two-value
        // position: center = (0, 0), r = 50 -> only a quarter disc is inside
        // the canvas, pi*50^2/4 ~= 1963.
        val red = redPixels(render("circle(50px at top left)"))
        assertTrue("top-left quarter area: $red, want 1700..2200", red in 1700..2200)
    }

    @Test
    fun rectUsesAbsoluteEdges() {
        // rect() edges are absolute (top half of the canvas = 200x100).
        // Inset semantics would read right=200-200=0 and clip everything out.
        val red = redPixels(render("rect(0px 200px 100px 0px)"))
        assertTrue("rect area: $red, want 19500..20500", red in 19500..20500)
    }

    @Test
    fun rectRoundClipsToRoundRect() {
        // Same 100x100 as inset(50px) but via absolute edges + slash radii.
        val red = redPixels(render("rect(50px 150px 150px 50px round 20px / 10px)"))
        assertTrue("round rect area: $red, want 9300..10100", red in 9300..10100)
    }

    @Test
    fun xywhClipsToBox() {
        // 100 x 100 = 10000.
        val red = redPixels(render("xywh(50px 50px 100px 100px)"))
        assertTrue("xywh area: $red, want 9500..10500", red in 9500..10500)
    }

    @Test
    fun pathClipsToPathData() {
        // 100 x 100 square = 10000 (single quotes: the SVG attribute itself
        // is double-quoted).
        val red = redPixels(render("path('M50 50H150V150H50Z')"))
        assertTrue("path area: $red, want 9500..10500", red in 9500..10500)
    }

    @Test
    fun pathEvenOddCutsHole() {
        // Donut: outer 120x120 minus inner 40x40 = 14400-1600 = 12800.
        val red = redPixels(
            render("path(evenodd, 'M40 40H160V160H40Z M80 80H120V120H80Z')"),
        )
        assertTrue("evenodd path area: $red, want 12000..13600", red in 12000..13600)
    }

    @Test
    fun pathResolvesAgainstTheElementOrigin() {
        // The clip sits on a 100x100 tile at (50,50), so `path()` data (like
        // every other basic shape) resolves against the element's own user
        // space: a 40x40 square at the tile origin. Reading the data in the
        // parent user space would clip the strip x/y = 10..50 instead.
        val svg = """
            <svg xmlns="http://www.w3.org/2000/svg" width="200" height="200" viewBox="0 0 200 200">
              <rect width="200" height="200" fill="white"/>
              <rect x="50" y="50" width="100" height="100" fill="red" clip-path="path('M0 0 H40 V40 H0 Z')"/>
            </svg>
        """.trimIndent()
        val out = renderWithLibrary(svg, createBitmap(200, 200, Bitmap.Config.ARGB_8888))
        val red = redPixels(out)
        assertTrue("path clip offset: $red, want 1500..1700", red in 1500..1700)
    }

    @Test
    fun noneRendersWholeElement() {
        val red = redPixels(render("none"))
        assertTrue("none area: $red, want > 39000", red > 39000)
    }

    @Test
    fun invalidShapeRendersWholeElement() {
        val red = redPixels(render("circle(foo)"))
        assertTrue("invalid shape area: $red, want > 39000", red > 39000)
    }

    @Test
    fun unsupportedCornerRadiusListRendersWholeElement() {
        val red = redPixels(render("inset(50px round 5px 3px)"))
        assertTrue("unsupported radii area: $red, want > 39000", red > 39000)
    }

    private fun renderCustom(body: String): Int {
        val svg = """
            <svg xmlns="http://www.w3.org/2000/svg" width="200" height="200" viewBox="0 0 200 200">
              <rect width="200" height="200" fill="white"/>
              $body
            </svg>
        """.trimIndent()
        return redPixels(renderWithLibrary(svg, createBitmap(200, 200, Bitmap.Config.ARGB_8888)))
    }

    @Test
    fun shapeClipLivesInElementUserSpace() {
        // The shape resolves in the referencing element's user space, so the
        // element's own transform moves the clip along with its content: the
        // 100x100 element lands at (100,100)-(200,200) and the disc, centered
        // on it, is inscribed in that square -> pi*50^2 ~= 7854. Resolving the
        // shape in the parent's space would leave the disc at (50,50) with no
        // overlap with the element at all.
        val red = renderCustom(
            """<rect width="100" height="100" fill="red" transform="translate(100 100)" """ +
                """clip-path="circle(50px at center center)"/>""",
        )
        assertTrue("transformed element clip area: $red, want 7000..8700", red in 7000..8700)
    }

    @Test
    fun viewBoxGeometryBoxUsesViewport() {
        // `view-box` resolves against the nearest viewport (0,0,200,200) instead
        // of the element's own 100x100 box: the disc is centered at the viewport
        // center (100,100), so only its lower-left quadrant overlaps the element
        // (~1963). The default fill-box would center it on the element, where the
        // whole disc fits (~7854).
        val red = renderCustom(
            """<rect width="100" height="100" fill="red" clip-path="circle(50px at center center) view-box"/>""",
        )
        assertTrue("view-box circle area: $red, want 1500..2400", red in 1500..2400)
    }

    @Test
    fun strokeBoxFallsBackToElementBox() {
        // Documented approximation: no stroke extent is tracked, so `stroke-box`
        // resolves like `fill-box` -> disc at (50,50), r=40 -> pi*40^2 ~= 5027.
        val red = renderCustom(
            """<rect width="100" height="100" fill="red" stroke="black" stroke-width="10" """ +
                """clip-path="circle(40px at center center) stroke-box"/>""",
        )
        assertTrue("stroke-box circle area: $red, want 4400..5600", red in 4400..5600)
    }
}
