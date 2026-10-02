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
import android.graphics.Color
import android.graphics.RectF
import hu.oandras.ksvg.dom.SVGImpl
import hu.oandras.ksvg.dom.core.Defs
import hu.oandras.ksvg.dom.filter.FeImage
import hu.oandras.ksvg.dom.filter.Filter
import hu.oandras.ksvg.render.FeImageRenderNode
import hu.oandras.ksvg.render.createBitmap
import hu.oandras.ksvg.render.filters.doFeImageFilter
import hu.oandras.ksvg.test.TestRenderContext
import hu.oandras.ksvg.test.renderWithLibrary
import hu.oandras.ksvg.utils.alpha
import hu.oandras.ksvg.utils.forEachElement
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.GraphicsMode

/**
 * `feImage preserveAspectRatio`: the raster image is mapped into the
 * primitive subregion (meet = letterbox, slice = crop, none = stretch).
 *
 * Setup: 1x1 white source bitmap, subregion (10,10)-(50,30) in a 100x100
 * region at scale 1. meet scales to 20x20 centered (x 20..40); letterbox
 * wings (e.g., x=12) stay transparent while the mapped core (x=30) is
 * opaque.
 *
 * `doFeImageFilter` is driven directly with a minimal [RenderContext]
 * because PNG decoding (`BitmapFactory`) does not work under Robolectric,
 * so no render-level raster test can decode an `href` here (the existing
 * `FiltersTest.feImage` only asserts href passthrough for the same reason).
 */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class FeImageParTest {

    private fun parseFeImage(parAttr: String): FeImage {
        val svg = """
            <svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
              <defs>
                <filter id="f" filterUnits="userSpaceOnUse" x="0" y="0" width="100" height="100" primitiveUnits="userSpaceOnUse">
                  <feImage href="data:image/png;base64,AAAA" x="10" y="10" width="40" height="20" $parAttr/>
                </filter>
              </defs>
              <rect x="0" y="0" width="100" height="100" fill="red" filter="url(#f)"/>
            </svg>
        """.trimIndent()
        val root = (SVG.getFromString(svg) as SVGImpl).requireRootElement()
        var found: FeImage? = null
        root.getChildren().forEachElement { child ->
            if (child is Defs) {
                child.getChildren().forEachElement { defsChild ->
                    if (defsChild is Filter) {
                        defsChild.getChildren().forEachElement { primitive ->
                            if (primitive is FeImage) found = primitive
                        }
                    }
                }
            }
        }
        return found ?: throw AssertionError("feImage not parsed")
    }

    private fun runFilter(parAttr: String): Bitmap {
        val element = parseFeImage(parAttr)
        val src = createBitmap(1, 1, Bitmap.Config.ARGB_8888)
        src.setPixel(0, 0, Color.WHITE)
        val node = FeImageRenderNode(sourceElement = element, image = src, referencedNode = null)
        val input = createBitmap(100, 100, Bitmap.Config.ARGB_8888)
        val ctx = TestRenderContext()
        return with(ctx) {
            doFeImageFilter(
                primitiveNode = node,
                inputBitmap = input,
                canvasScaleX = 1f,
                canvasScaleY = 1f,
                filterRegionLeft = 0f,
                filterRegionTop = 0f,
                primitiveRegion = RectF(10f, 10f, 50f, 30f),
            )
        }
    }

    @Test
    fun preserveAspectRatioAbsentIsNull() {
        assertNull(parseFeImage("").preserveAspectRatio)
    }

    @Test
    fun preserveAspectRatioParsed() {
        val par = parseFeImage("preserveAspectRatio=\"xMinYMin slice\"").preserveAspectRatio
            ?: throw AssertionError("PAR not parsed")
        assertEquals(
            hu.oandras.ksvg.PreserveAspectRatio.Alignment.xMinYMin,
            par.alignment,
        )
        assertEquals(hu.oandras.ksvg.PreserveAspectRatio.Scale.slice, par.scale)
    }

    @Test
    fun defaultMeetLetterboxes() {
        val out = runFilter("")
        assertEquals(100, out.width)
        assertEquals(100, out.height)
        // Letterbox wing: transparent.
        assertEquals(0, out.getPixel(12, 20).alpha)
        // Mapped core: opaque.
        assertEquals(255, out.getPixel(30, 20).alpha)
    }

    @Test
    fun explicitMeetLetterboxes() {
        val out = runFilter("preserveAspectRatio=\"xMidYMid meet\"")
        assertEquals(0, out.getPixel(12, 20).alpha)
        assertEquals(255, out.getPixel(30, 20).alpha)
    }

    @Test
    fun noneStretches() {
        val out = runFilter("preserveAspectRatio=\"none\"")
        assertEquals(255, out.getPixel(12, 20).alpha)
        assertEquals(255, out.getPixel(30, 20).alpha)
    }

    @Test
    fun sliceCrops() {
        // 40x40 scaled, vertically centered crop: covers the whole subregion.
        val out = runFilter("preserveAspectRatio=\"xMidYMid slice\"")
        assertEquals(255, out.getPixel(12, 20).alpha)
        assertEquals(255, out.getPixel(12, 12).alpha)
        assertEquals(255, out.getPixel(30, 20).alpha)
    }

    @Test
    fun meetAlignsLeft() {
        // xMinYMin: 20x20 mapped block at the left (x 10..30).
        val out = runFilter("preserveAspectRatio=\"xMinYMin meet\"")
        assertEquals(255, out.getPixel(12, 20).alpha)
        assertEquals(0, out.getPixel(38, 20).alpha)
    }

    @Test
    fun fullPipelineStaysConsistent() {
        // Element-reference feImage path is untouched by the PAR change:
        // the existing visual golden (filter_feImage.svg) still renders.
        val svg = """
            <svg xmlns="http://www.w3.org/2000/svg" width="240" height="220" viewBox="0 0 240 220">
              <defs>
                <filter id="mix" filterUnits="userSpaceOnUse" x="0" y="0" width="240" height="220">
                  <feImage href="#source" result="img"/>
                  <feBlend in="SourceGraphic" in2="img" mode="screen"/>
                </filter>
                <circle id="source" cx="120" cy="100" r="55" fill="gold"/>
              </defs>
              <rect x="0" y="0" width="240" height="180" fill="midnightblue"/>
              <circle cx="120" cy="100" r="70" fill="tomato" filter="url(#mix)"/>
            </svg>
        """.trimIndent()
        val out = renderWithLibrary(
            svg,
            createBitmap(240, 220, Bitmap.Config.ARGB_8888),
        )
        // Gold circle region blended over tomato: must be lit (was gold screen).
        val p = out.getPixel(120, 100)
        assertEquals(255, p.alpha)
    }
}
