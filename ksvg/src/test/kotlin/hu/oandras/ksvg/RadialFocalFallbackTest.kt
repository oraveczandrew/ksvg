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

import hu.oandras.ksvg.comparisons.VISUAL_GOLDEN_ROOT_PATH
import hu.oandras.ksvg.comparisons.VISUAL_ROOT_PATH
import hu.oandras.ksvg.comparisons.VISUAL_TARGET_SIZE
import hu.oandras.ksvg.dom.gradient.GradientSpread
import hu.oandras.ksvg.render.applyGradientSpread
import hu.oandras.ksvg.render.clampFocalToCircle
import hu.oandras.ksvg.render.createBitmap
import hu.oandras.ksvg.render.focalGradientT
import hu.oandras.ksvg.render.sampleGradientStops
import hu.oandras.ksvg.test.BitmapComparator
import hu.oandras.ksvg.test.decodePng
import hu.oandras.ksvg.test.renderWithLibrary
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode
import java.io.File
import kotlin.math.abs

/**
 * API < 31 focal-gradient fallback: below API 31 the platform
 * `RadialGradient` cannot express an off-center focal point, so
 * `makeRadialGradient` rasterizes such gradients into a bitmap
 * ([focalGradientT] bake) instead of falling back to centered.
 *
 * Runs the whole class under SDK 26 so the bake branch (not the API-31+
 * two-point constructor) is exercised, comparing against the same
 * rsvg goldens as the host suite.
 */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
@Config(manifest = Config.NONE, sdk = [26])
class RadialFocalFallbackTest {

    @Test
    fun gradients_focalHighlightMatchesGolden() {
        assertGolden("gradients.svg")
    }

    @Test
    fun gradientRadialFr_focalPointAndRadiusMatchGolden() {
        assertGolden("gradient_radial_fr.svg")
    }

    @Test
    fun gradientHref_derivedFocalMatchesGolden() {
        assertGolden("gradient_href.svg")
    }

    @Test
    fun objectBoundingBoxFocal_gradientTransformAppliesBelowApi31() {
        // The bake used to drop the gradientTransform (objectBoundingBox
        // branch kept the pure bbox local matrix), so a transformed focal
        // gradient rendered unshifted. The sampling affine now carries G⁻¹.
        assertGolden("gradient_radial_obbox_transform.svg")
    }

    @Test
    fun focalT_centeredGradientMatchesRadius() {
        // Centered: t must equal normalized distance from the center.
        assertEquals(0f, focalGradientT(0.5f, 0.5f, 0.5f, 0.5f, 0f, 0.5f, 0.5f, 0.5f), 1e-6f)
        assertEquals(0.5f, focalGradientT(0.75f, 0.5f, 0.5f, 0.5f, 0f, 0.5f, 0.5f, 0.5f), 1e-5f)
        assertEquals(1f, focalGradientT(1f, 0.5f, 0.5f, 0.5f, 0f, 0.5f, 0.5f, 0.5f), 1e-5f)
    }

    @Test
    fun focalT_focalPointIsZeroAndEndCircleIsOne() {
        // Off-center focal: apex maps to 0, end circle to 1.
        assertEquals(
            0f,
            focalGradientT(0.25f, 0.25f, 0.25f, 0.25f, 0f, 0.5f, 0.5f, 0.5f),
            1e-6f,
        )
        assertEquals(
            1f,
            focalGradientT(1f, 0.5f, 0.25f, 0.25f, 0f, 0.5f, 0.5f, 0.5f),
            1e-5f,
        )
        // End-circle center sits between apex and rim for an on-circle focal.
        val mid = focalGradientT(0.5f, 0.5f, 0.25f, 0.25f, 0f, 0.5f, 0.5f, 0.5f)
        assertTrue("mid must be inside (0,1), was $mid", mid > 0f && mid < 1f)
    }

    @Test
    fun focalT_insideStartCircleSolvesThroughCone() {
        // No "inside -> start" special case: the platform two-point
        // RadialGradient (SDK 34 probe) paints the start disc through the cone
        // solution (blue-ish here, verified against Skia pixel reads), so the
        // bake must return the numeric cone t, neither 0 nor NaN.
        val centerT = focalGradientT(70f, 60f, 70f, 60f, 25f, 130f, 110f, 90f)
        assertTrue("start center must solve numeric, was $centerT", !centerT.isNaN())
        val innerT = focalGradientT(80f, 70f, 70f, 60f, 25f, 130f, 110f, 90f)
        assertTrue("inner start disc must solve numeric, was $innerT", !innerT.isNaN())
    }

    @Test
    fun focalT_behindApexIsUncovered() {
        // No forward (t >= 0) circle reaches the region behind the focal apex:
        // the bake must paint these texels transparent (platform two-point
        // RadialGradient and rsvg behavior on every tile mode), so NaN.
        assertTrue(focalGradientT(0.5f, 0.5f, 70f, 60f, 25f, 130f, 110f, 90f).isNaN())
        assertTrue(focalGradientT(10f, 10f, 70f, 60f, 25f, 130f, 110f, 90f).isNaN())
    }

    @Test
    fun focalT_coveredExteriorIsBeyondOne() {
        // Beyond the end circle but on a forward circle: t > 1 (pad -> last stop).
        val t = focalGradientT(200f, 200f, 70f, 60f, 25f, 130f, 110f, 90f)
        assertTrue("covered exterior must stay numeric and > 1, was $t", !t.isNaN() && t > 1f)
    }

    @Test
    fun clampFocalToCircle_outsideFocalLandsOnCircle() {
        val out = clampFocalToCircle(5f, 0f, 0f, 0f, 1f, FloatArray(2))
        assertEquals(1f, out[0], 1e-6f)
        assertEquals(0f, out[1], 1e-6f)
        val inside = clampFocalToCircle(0.25f, 0.25f, 0.5f, 0.5f, 0.5f, FloatArray(2))
        assertEquals(0.25f, inside[0], 1e-6f)
        assertEquals(0.25f, inside[1], 1e-6f)
    }

    @Test
    fun spread_repeatAndReflectWrap() {
        assertEquals(0.7f, applyGradientSpread(-0.3f, GradientSpread.repeat), 1e-6f)
        assertEquals(0.5f, applyGradientSpread(1.5f, GradientSpread.reflect), 1e-6f)
        assertEquals(0.5f, applyGradientSpread(-0.5f, GradientSpread.reflect), 1e-6f)
        assertEquals(1f, applyGradientSpread(2f, GradientSpread.pad), 1e-6f)
    }

    @Test
    fun sampleStops_interpolatesAndClamps() {
        val colors = intArrayOf(0xff000000.toInt(), 0xffffffff.toInt())
        val positions = floatArrayOf(0f, 1f)
        assertEquals(0xff000000.toInt(), sampleGradientStops(colors, positions, 2, -0.5f))
        assertEquals(0xffffffff.toInt(), sampleGradientStops(colors, positions, 2, 1.5f))
        val mid = sampleGradientStops(colors, positions, 2, 0.5f)
        assertTrue("mid grey alpha must stay opaque", (mid ushr 24) == 0xff)
        val lum = ((mid shr 16) and 0xff)
        assertTrue("mid grey must be ~half, was $lum", abs(lum - 127) <= 2)
    }

    private fun assertGolden(fileName: String) {
        val svgFile = File("$VISUAL_ROOT_PATH/$fileName")
        val refPng = File("$VISUAL_GOLDEN_ROOT_PATH/${fileName.replace(".svg", ".png")}")
        if (!refPng.exists()) {
            fail("Reference image does not exist: ${refPng.path}")
            return
        }
        val refBitmap = decodePng(refPng, tempBitmap)
        if (refBitmap == null) {
            fail("Could not decode reference for $fileName")
            return
        }
        val libBitmap = renderWithLibrary(svgFile, tempBitmap2)
        val similarity = bitmapComparator.compareBitmaps(refBitmap, libBitmap)
        if (similarity < 0.95) {
            val diffPercent = (1.0 - similarity) * 100.0
            fail("$fileName (API 26 focal bake): ${"%.2f".format(diffPercent)}% difference")
        }
    }

    companion object {
        private val bitmapComparator = BitmapComparator(
            targetWidth = VISUAL_TARGET_SIZE,
            targetHeight = VISUAL_TARGET_SIZE,
        )

        private var _tempBitmap = null as android.graphics.Bitmap?
        private val tempBitmap: android.graphics.Bitmap
            get() = _tempBitmap ?: createBitmap(
                width = VISUAL_TARGET_SIZE,
                height = VISUAL_TARGET_SIZE,
            ).also {
                _tempBitmap = it
            }

        private var _tempBitmap2 = null as android.graphics.Bitmap?
        private val tempBitmap2: android.graphics.Bitmap
            get() = _tempBitmap2 ?: createBitmap(
                width = VISUAL_TARGET_SIZE,
                height = VISUAL_TARGET_SIZE,
            ).also {
                _tempBitmap2 = it
            }
    }
}
