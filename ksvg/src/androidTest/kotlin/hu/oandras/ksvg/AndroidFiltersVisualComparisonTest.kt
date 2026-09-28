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

import android.content.res.AssetManager
import android.graphics.Bitmap
import androidx.test.platform.app.InstrumentationRegistry
import hu.oandras.ksvg.test.BitmapComparator
import hu.oandras.ksvg.test.decodePng
import hu.oandras.ksvg.test.renderWithLibrary
import org.junit.Assert.fail
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.Parameterized

internal const val ANDROID_FILTERS_ROOT_PATH = "visual"
internal const val ANDROID_FILTERS_GOLDEN_ROOT_PATH = "visual-golden"
internal const val ANDROID_FILTERS_TARGET_SIZE = 256

// Gating policy mirrored from the host VisualComparisonTest
// (ksvg/.../comparisons/VisualComparisonTest.kt): same exclusions, same
// per-file thresholds with the same reasons. Anything red here that the host
// gates green is an on-device divergence worth investigating (see
// tmp/RENDER_FIDELITY_PLAN.md items 9-13); anything red on the host too is a
// host-side issue and must not be "fixed" against the emulator.

// No valid rsvg reference exists (mirrors EXCLUDED_FROM_VISUAL_VERIFICATION).
private val EXCLUDED_FROM_ENDPOINT_VERIFICATION = setOf(
    // rsvg lacks <solidColor>: golden empty, library renders correctly.
    "solid_color.svg",
    // rsvg <= 2.63.2 ignores the marker="" shorthand: golden has no markers.
    // Pinned by MarkerShorthandTest instead.
    "marker_shorthand_strokeWidth.svg",
)

// Below API 29 blends fall back to PorterDuff layer compositing and flood
// (KNOWN_ISSUES.md item 1). The host software path is unaffected, so these
// stay gated there and are skipped here only on old devices.
private val EXCLUDED_BELOW_API_29 = setOf(
    "blend_mode.svg",
    "rendering_properties.svg",
)

// Mirrors ACCEPTED_SIMILARITY_EXCEPTIONS (same values, same reasons).
private val ACCEPTED_ENDPOINT_SIMILARITY_EXCEPTIONS: Map<String, Double> = mapOf(
    "pattern_transform.svg" to 0.89,
    "patterns_markers.svg" to 0.93,
    "text.svg" to 0.94,
    "text_anchor.svg" to 0.94,
    "direction_text_anchor.svg" to 0.94,
    "text_fonts.svg" to 0.88,
    "text_letter_spacing.svg" to 0.92,
    "text_variation_settings.svg" to 0.88,
    "text_advanced_features.svg" to 0.88,
    "text_properties_extra.svg" to 0.90,
    "filters.svg" to 0.93,
    "filter_tile.svg" to 0.93,
    "filter_primitives.svg" to 0.78,
    "filter_morphology_erode.svg" to 0.86,
    "filter_component_transfer_complex.svg" to 0.94,
)

@RunWith(Parameterized::class)
class AndroidFiltersVisualComparisonTest(
    private val relativePath: String,
    private val svgAssetPath: String,
    private val referenceAssetPath: String,
) {

    @Test
    fun compareFilter() {
        // 1. Load reference
        val refBitmap = try {
            assetManager.open(referenceAssetPath).use {
                decodePng(
                    input = it,
                    inBitmap = tempBitmap
                )
            }
        } catch (_: Exception) {
            fail("Reference image does not exist: $referenceAssetPath. Run FiltersCreateGoldenPngs to generate it.")
            return
        }

        if (refBitmap == null) {
            fail("Error: Could not decode reference for $svgAssetPath")
            return
        }

        // 2. Render with library
        val libBitmap = try {
            assetManager.open(svgAssetPath).use {
                renderWithLibrary(it, tempBitmap2)
            }
        } catch (e: Exception) {
            fail("Library failed to render $svgAssetPath: ${e.message}")
            return
        }

        val similarity = bitmapComparator.compareBitmaps(refBitmap, libBitmap)
        val threshold =
            ACCEPTED_ENDPOINT_SIMILARITY_EXCEPTIONS[relativePath.substringAfterLast('/')] ?: 0.95
        if (similarity < threshold) {
            val diffPercent = (1.0 - similarity) * 100.0
            val thresholdPercent = (1.0 - threshold) * 100.0
            fail("$svgAssetPath ($relativePath): ${"%.2f".format(diffPercent)}% difference (threshold: ${"%.2f".format(thresholdPercent)}%). Check image in $referenceAssetPath")
        }
    }

    companion object {

        private val assetManager: AssetManager = InstrumentationRegistry.getInstrumentation().context.assets

        private val bitmapComparator = BitmapComparator(
            targetWidth = ANDROID_FILTERS_TARGET_SIZE,
            targetHeight = ANDROID_FILTERS_TARGET_SIZE
        )

        private val tempBitmap: Bitmap = Bitmap.createBitmap(
            /* width = */ ANDROID_FILTERS_TARGET_SIZE,
            /* height = */ ANDROID_FILTERS_TARGET_SIZE,
            /* config = */ Bitmap.Config.ARGB_8888
        )

        private val tempBitmap2: Bitmap = Bitmap.createBitmap(
            /* width = */ ANDROID_FILTERS_TARGET_SIZE,
            /* height = */ ANDROID_FILTERS_TARGET_SIZE,
            /* config = */ Bitmap.Config.ARGB_8888
        )

        @JvmStatic
        @Parameterized.Parameters(name = "{0}")
        fun data(): List<Array<Any>> {
            val belowApi29 = android.os.Build.VERSION.SDK_INT < android.os.Build.VERSION_CODES.Q
            return assetManager.listSvgAssets(ANDROID_FILTERS_ROOT_PATH)
                .filter { svgAssetPath ->
                    val fileName = svgAssetPath.substringAfterLast('/')
                    fileName !in EXCLUDED_FROM_ENDPOINT_VERIFICATION &&
                        !(belowApi29 && fileName in EXCLUDED_BELOW_API_29)
                }
                .map { svgAssetPath ->
                    val relativePath = svgAssetPath.removePrefix("$ANDROID_FILTERS_ROOT_PATH/")
                    val referenceAssetPath = "$ANDROID_FILTERS_GOLDEN_ROOT_PATH/" +
                        relativePath.replaceAfterLast('.', "png")
                    arrayOf(relativePath, svgAssetPath, referenceAssetPath)
                }
        }
    }
}

private fun AssetManager.listSvgAssets(path: String): List<String> {
    return list(path).orEmpty().flatMap { name ->
        val childPath = if (path.isEmpty()) name else "$path/$name"
        if (name.endsWith(".svg", ignoreCase = true)) {
            listOf(childPath)
        } else {
            listSvgAssets(childPath)
        }
    }
}
