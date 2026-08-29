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
import hu.oandras.ksvg.test.countPixels
import hu.oandras.ksvg.test.renderWithLibrary
import hu.oandras.ksvg.utils.alpha
import hu.oandras.ksvg.utils.blue
import hu.oandras.ksvg.utils.green
import hu.oandras.ksvg.utils.red
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.GraphicsMode
import java.io.File

/**
 * Regression tests for rendering bugs that were producing empty / wrong output.
 *
 * The filter pipelines are forced to the software backend so the assertions
 * deterministically exercise the [hu.oandras.ksvg.render.filters.pipeline.SoftwareFilterBackend]
 * code paths that these fixes live in.
 */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class RenderBugFixesTest {

    @Test
    fun feImageRendersElementReference() {
        // `feImage href="#source"` must render the referenced <circle>, not stay empty.
        val bitmap = renderFixture("filter_feImage.svg")
        val gold = countPixels(bitmap) { c ->
            // Gold (#FFD700-ish) produced by the referenced circle.
            c.red > 200 && c.green > 150 && c.blue < 120
        }
        assertTrue("feImage element reference should render gold pixels", gold > 0)
    }

    @Test
    fun trefRendersWhenNotInsideText() {
        // A top-level <tref> must be wrapped in a synthetic text root and render.
        val bitmap = renderFixture("tref_basic.svg")
        val nonTransparent = countPixels(bitmap) { it.alpha > 10 }
        assertTrue("tref content should be rendered", nonTransparent > 0)
    }

    @Test
    fun filterGeometryUnitsRendersShape() {
        // The filtered circle must be drawn (orientation/slice fix), not clipped away.
        val bitmap = renderFixture("filter_geometry_units.svg")
        val orange = countPixels(bitmap) { c ->
            c.red > 150 && c.green in 80..200 && c.blue < 120
        }
        assertTrue("filtered geometry circle should be visible", orange > 0)
    }

    @Test
    fun componentTransferLinearRendersAllRects() {
        // The bottom rect (affected by component transfer) must be drawn, not clipped.
        val bitmap = renderFixture("component_transfer_linear.svg")
        val nonTransparent = countPixels(bitmap) { it.alpha > 10 }
        val orange = countPixels(bitmap) { c ->
            c.red > 150 && c.green in 80..200 && c.blue < 120
        }
        assertTrue("component transfer output should not be empty", nonTransparent > 1000)
        assertTrue("component transfer should produce visible content", orange > 0)
    }

    private fun renderFixture(name: String): Bitmap {
        val file = File("test-data/visual/$name")
        val bitmap = createBitmap(512, 512)
        renderWithLibrary(file, bitmap, softwareFiltering = true)
        return bitmap
    }
}
