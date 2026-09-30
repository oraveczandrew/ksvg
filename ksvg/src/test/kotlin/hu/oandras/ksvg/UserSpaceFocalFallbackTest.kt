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
import hu.oandras.ksvg.render.createBitmap
import hu.oandras.ksvg.test.BitmapComparator
import hu.oandras.ksvg.test.decodePng
import hu.oandras.ksvg.test.renderWithLibrary
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode
import java.io.File

/**
 * API < 31 `gradientUnits="userSpaceOnUse"` focal-gradient fallback: the focal
 * point and focal radius are absolute user-space coordinates, so the focal
 * bake in `makeRadialGradient` has to sample them in user space (through the
 * inverted `gradientTransform`) instead of the objectBoundingBox unit space
 * used by [RadialFocalFallbackTest].
 *
 * Runs the whole class under SDK 26, so the bake branch — not the API-31+
 * two-point platform constructor — is exercised, comparing against the same
 * rsvg reference images as the host suite.
 */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
@Config(manifest = Config.NONE, sdk = [26])
class UserSpaceFocalFallbackTest {

    @Test
    fun userSpaceFocal_apexLandsOnFocalPoint() {
        assertGolden("gradient_radial_userspace_focal.svg")
    }

    @Test
    fun userSpaceCentered_stillUsesPlatformPath() {
        // Negative control: no focal offset, so no bake at all — the platform
        // single-center RadialGradient keeps rendering these unchanged.
        assertGolden("gradient_radial_userspace_centered.svg")
    }

    @Test
    fun userSpaceFocal_gradientTransformIsInverted() {
        // The gradientTransform is mapped gradient space -> user space, so the
        // bake must push every texel back through its inverse before solving
        // the focal cone.
        assertGolden("gradient_radial_userspace_transform.svg")
    }

    @Test
    fun userSpaceFocal_sharedGradientRepaintsPerReferencingBbox() {
        // One userSpaceOnUse gradient referenced by two elements of EQUAL bbox
        // size at DIFFERENT positions: the bake raster is cached per paint, so
        // without the bake origin in the cache key, the second element would
        // reuse the first element's texels.
        assertGolden("gradient_radial_userspace_shared.svg")
    }

    private fun assertGolden(fileName: String, minSimilarity: Float = 0.95f) {
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
        assertTrue(
            "$fileName (API 26 user-space focal bake): " +
                "${"%.2f".format((1.0 - similarity) * 100.0)}% difference, " +
                "threshold ${"%.2f".format((1.0 - minSimilarity) * 100.0)}%",
            similarity >= minSimilarity,
        )
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
