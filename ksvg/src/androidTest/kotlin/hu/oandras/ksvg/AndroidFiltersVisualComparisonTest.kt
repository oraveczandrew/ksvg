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
import hu.oandras.ksvg.utils.BitmapComparator
import org.junit.Assert.fail
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.Parameterized

internal const val ANDROID_FILTERS_ROOT_PATH = "filters"
internal const val ANDROID_FILTERS_GOLDEN_ROOT_PATH = "filters-golden"
internal const val ANDROID_FILTERS_TARGET_SIZE = 256

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
        if (similarity < 0.95) { // Allow 5% difference for engine variations
            val diffPercent = (1.0 - similarity) * 100.0
            fail("$svgAssetPath ($relativePath): ${"%.2f".format(diffPercent)}% difference. Check image in $referenceAssetPath")
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
            return assetManager.listSvgAssets(ANDROID_FILTERS_ROOT_PATH)
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
