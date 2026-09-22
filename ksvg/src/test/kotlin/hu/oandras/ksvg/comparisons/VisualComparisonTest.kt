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

package hu.oandras.ksvg.comparisons

import android.graphics.Bitmap
import hu.oandras.ksvg.render.createBitmap
import hu.oandras.ksvg.test.BitmapComparator
import hu.oandras.ksvg.test.decodePng
import hu.oandras.ksvg.test.renderWithLibrary
import org.junit.Assert.fail
import org.junit.BeforeClass
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.ParameterizedRobolectricTestRunner
import org.robolectric.ParameterizedRobolectricTestRunner.Parameters
import org.robolectric.annotation.GraphicsMode
import java.io.File

internal const val VISUAL_ROOT_PATH = "test-data/visual"
internal const val VISUAL_GOLDEN_ROOT_PATH = "test-data/visual-golden"
internal const val VISUAL_LIBRARY_GOLDEN_ROOT_PATH = "test-data/visual-library-golden"
internal const val VISUAL_TARGET_SIZE = 256

// SVGs excluded from the rsvg cross-check: rsvg does not implement the feature
// (e.g. <solidColor> paint server), so its golden is empty/invalid and cannot
// serve as a reference. The library renders these correctly (see
// test-data/visual-library-golden); they are not compared against rsvg.
private val EXCLUDED_FROM_VISUAL_VERIFICATION = setOf("solid_color.svg")

// Per-SVG similarity thresholds below the default 0.95, with a documented reason.
// Two kinds of entries live here:
//  - Engine differences that are valid but never pixel-equal (fonts, anti-aliasing,
//    and filter noise/PRNG algorithms that differ from rsvg).
//  - Complex filter interactions / tiling edge cases with known, stable sub-pixel drift.
private val ACCEPTED_SIMILARITY_EXCEPTIONS: Map<String, Double> = mapOf(
    // Transform interpolation and rounding differences in patterns
    "pattern_transform.svg" to 0.89,
    "patterns_markers.svg" to 0.93,

    // Generic font differences (Robolectric 'sans-serif' vs Golden reference)
    "text.svg" to 0.94,
    "text_anchor.svg" to 0.94,
    "direction_text_anchor.svg" to 0.94,
    "text_fonts.svg" to 0.88,
    "text_letter_spacing.svg" to 0.92,
    "text_variation_settings.svg" to 0.88,
    "text_advanced_features.svg" to 0.88,
    // Font-feature advances the Robolectric Roboto lacks (condensed,
    // small-caps, ligature/tabular/full-width): line widths diverge while
    // all lines still render (measured 0.9256 on 2026-09-22).
    "text_properties_extra.svg" to 0.90,
    "filters.svg" to 0.93,

    // Complex filter interactions and tiling edge cases
    "filter_tile.svg" to 0.93,
    "filter_primitives.svg" to 0.78,
    // Eroded/dilated glyphs amplify base-font coverage noise (the NORMAL
    // line alone is 40%+ band-diff from Roboto-vs-rsvg letterforms; measured
    // 0.8699 on 2026-09-22). Kernel itself covered text-free in Round-B.
    "filter_morphology_erode.svg" to 0.86,
    "filter_component_transfer_complex.svg" to 0.94,
)

@RunWith(ParameterizedRobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class VisualComparisonTest(
    private val svgFile: File,
    private val targetSubFolder: File,
) {

    @Test
    fun compare() {
        val refPng = File(targetSubFolder, svgFile.name.replace(".svg", ".png"))

        if (!refPng.exists()) {
            fail("Reference image does not exist: ${refPng.absolutePath}. Run CreateGoldenPngs to generate it.")
            return
        }

        val refBitmap = decodePng(
            file = refPng,
            inBitmap = tempBitmap
        ) ?: run {
            fail("Error: Could not decode reference for ${svgFile.name}")
            return
        }

        val libBitmap = try {
            renderWithLibrary(svgFile, tempBitmap2)
        } catch (e: Exception) {
            fail("Library failed to render ${svgFile.name}: ${e.message}")
            return
        }

        val similarity = bitmapComparator.compareBitmaps(refBitmap, libBitmap)
        val threshold = ACCEPTED_SIMILARITY_EXCEPTIONS[svgFile.name] ?: 0.95

        if (similarity < threshold) {
            val diffPercent = (1.0 - similarity) * 100.0
            val thresholdPercent = (1.0 - threshold) * 100.0

            val diffDir = File("test-data/visual-diff")
            if (!diffDir.exists()) diffDir.mkdirs()
            val diffBitmap = createBitmap(
                width = VISUAL_TARGET_SIZE,
                height = VISUAL_TARGET_SIZE,
            )
            bitmapComparator.diffBitmap(refBitmap, libBitmap, diffBitmap)
            val diffFile = File(diffDir, svgFile.name.replace(".svg", ".png"))
            writeLosslessPngTo(diffFile, diffBitmap)

            fail("${svgFile.absolutePath}: ${"%.2f".format(diffPercent)}% difference (threshold: ${"%.2f".format(thresholdPercent)}%). Diff image: ${diffFile.absolutePath}")
        }
    }

    companion object {

        private val bitmapComparator = BitmapComparator(
            targetWidth = VISUAL_TARGET_SIZE,
            targetHeight = VISUAL_TARGET_SIZE
        )

        private var _tempBitmap: Bitmap? = null
        private val tempBitmap: Bitmap
            get() = _tempBitmap ?: createBitmap(
                width = VISUAL_TARGET_SIZE,
                height = VISUAL_TARGET_SIZE,
            ).also {
                _tempBitmap = it
            }

        private var _tempBitmap2: Bitmap? = null
        private val tempBitmap2: Bitmap
            get() = _tempBitmap2 ?: createBitmap(
                width = VISUAL_TARGET_SIZE,
                height = VISUAL_TARGET_SIZE,
            ).also {
                _tempBitmap2 = it
            }

        private val goldenRootPath: File
            get() = File(VISUAL_GOLDEN_ROOT_PATH)

        private var setupDone = false

        @JvmStatic
        @BeforeClass
        fun setup() {
            if (setupDone) return
            setupDone = true

            val diffDir = File("test-data/visual-diff")
            if (diffDir.exists()) {
                diffDir.listFiles()?.forEach { it.delete() }
            } else {
                diffDir.mkdirs()
            }
        }

        @JvmStatic
        @Parameters(name = "{0}")
        fun data(): List<Array<Any>> {
            val root = File(VISUAL_ROOT_PATH)
            if (!root.exists()) return emptyList()

            return root.listSvgs().toList()
                .filter { it.name !in EXCLUDED_FROM_VISUAL_VERIFICATION }
                .applyVerifyFilter()
                .map { svg ->
                    arrayOf(svg, goldenRootPath)
                }
        }
    }
}
