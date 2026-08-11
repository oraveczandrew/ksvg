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

package hu.oandras.androidsvg

import android.graphics.Bitmap
import hu.oandras.androidsvg.utils.BitmapComparator
import org.junit.Assert.fail
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.ParameterizedRobolectricTestRunner
import org.robolectric.ParameterizedRobolectricTestRunner.Parameters
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode
import java.io.File

internal const val FILTERS_ROOT_PATH = "test-data/filters"
internal const val FILTERS_GOLDEN_ROOT_PATH = "test-data/filters-golden"
internal const val FILTERS_TARGET_SIZE = 256
internal const val FILTERS_TARGET_SIZE_STR: String = FILTERS_TARGET_SIZE.toString()

@RunWith(ParameterizedRobolectricTestRunner::class)
@Config(sdk = [34])
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class FiltersVisualComparisonTest(
    private val svgFile: File,
    private val targetSubFolder: File,
) {

    @Test
    fun compareFilter() {
        val refPng = File(targetSubFolder, svgFile.name.replace(".svg", ".png"))

        if (!refPng.exists()) {
            fail("Reference image does not exist: ${refPng.absolutePath}. Run FiltersCreateGoldenPngs to generate it.")
            return
        }

        // 1. Load reference and compare
        val refBitmap = decodePng(refPng, tempBitmap)
        if (refBitmap == null) {
            fail("Error: Could not decode reference for ${svgFile.name}")
            return
        }

        // 2. Render with library
        val libBitmap = try {
            renderWithLibrary(svgFile, tempBitmap2)
        } catch (e: Exception) {
            fail("Library failed to render ${svgFile.name}: ${e.message}")
            return
        }

        val similarity = bitmapComparator.compareBitmaps(refBitmap, libBitmap)
        if (similarity < 0.95) { // Allow 5% difference for engine variations
            val diffPercent = (1.0 - similarity) * 100.0
            fail("${svgFile.absolutePath}: ${"%.2f".format(diffPercent)}% difference. Check image in $refPng")
        }
    }

    companion object {

        private val bitmapComparator = BitmapComparator(
            targetWidth = FILTERS_TARGET_SIZE,
            targetHeight = FILTERS_TARGET_SIZE
        )

        private var _tempBitmap: Bitmap? = null
        private val tempBitmap: Bitmap
            get() = _tempBitmap ?: Bitmap.createBitmap(
                /* width = */ FILTERS_TARGET_SIZE,
                /* height = */ FILTERS_TARGET_SIZE,
                /* config = */ Bitmap.Config.ARGB_8888
            ).also {
                _tempBitmap = it
            }

        private var _tempBitmap2: Bitmap? = null
        private val tempBitmap2: Bitmap
            get() = _tempBitmap2 ?: Bitmap.createBitmap(
                /* width = */ FILTERS_TARGET_SIZE,
                /* height = */ FILTERS_TARGET_SIZE,
                /* config = */ Bitmap.Config.ARGB_8888
            ).also {
                _tempBitmap2 = it
            }

        private val goldenRootPath: File
            get() = File(FILTERS_GOLDEN_ROOT_PATH)

        @JvmStatic
        @Parameters(name = "{0}")
        fun data(): List<Array<Any>> {
            val root = File(FILTERS_ROOT_PATH)
            if (!root.exists()) return emptyList()
            
            return ArrayList<Array<Any>>().apply {
                root.listDirectories().forEach { collection ->
                    val relativeDirectory = File(collection.name)
                    val targetSubFolder = File(goldenRootPath, relativeDirectory.path)

                    val svgFiles = collection.listSvgs()
                    ensureCapacity(size + svgFiles.size)
                    svgFiles.forEach { svg ->
                        add(arrayOf(svg, targetSubFolder))
                    }
                }
            }
        }
    }
}
