package hu.oandras.androidsvg

import android.content.res.AssetManager
import android.graphics.Bitmap
import androidx.test.platform.app.InstrumentationRegistry
import hu.oandras.androidsvg.utils.BitmapComparator
import org.junit.Assert.fail
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.Parameterized

internal const val METEOCONS_ROOT_PATH = "meteocons"
internal const val METEOCONS_GOLDEN_ROOT_PATH = "meteocons-golden"
internal const val METEOCONS_TARGET_SIZE = 256

@RunWith(Parameterized::class)
class AndroidMeteoconsVisualComparisonTest(
    private val relativePath: String,
    private val svgAssetPath: String,
    private val referenceAssetPath: String,
) {

    @Test
    fun compareIcon() {
        // 1. Load reference and compare
        val refBitmap = assetManager.open(referenceAssetPath).use {
            decodePng(
                input = it,
                inBitmap = tempBitmap
            )
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
            targetWidth = METEOCONS_TARGET_SIZE,
            targetHeight = METEOCONS_TARGET_SIZE
        )

        private val tempBitmap: Bitmap = Bitmap.createBitmap(
            /* width = */ METEOCONS_TARGET_SIZE,
            /* height = */ METEOCONS_TARGET_SIZE,
            /* config = */ Bitmap.Config.ARGB_8888
        )

        private val tempBitmap2: Bitmap = Bitmap.createBitmap(
            /* width = */ METEOCONS_TARGET_SIZE,
            /* height = */ METEOCONS_TARGET_SIZE,
            /* config = */ Bitmap.Config.ARGB_8888
        )

        @JvmStatic
        @Parameterized.Parameters(name = "{0}")
        fun data(): List<Array<Any>> {
            val assets = InstrumentationRegistry.getInstrumentation().context.assets
            return assets.listSvgAssets(METEOCONS_ROOT_PATH)
                .map { svgAssetPath ->
                    val relativePath = svgAssetPath.removePrefix("$METEOCONS_ROOT_PATH/")
                    val referenceAssetPath = "$METEOCONS_GOLDEN_ROOT_PATH/" +
                        relativePath.replaceAfterLast('.', "png")
                    arrayOf(relativePath, svgAssetPath, referenceAssetPath)
                }
        }
    }
}

private fun AssetManager.listSvgAssets(path: String): List<String> {
    return list(path).orEmpty().flatMap { name ->
        val childPath = "$path/$name"
        if (name.endsWith(".svg", ignoreCase = true)) {
            listOf(childPath)
        } else {
            listSvgAssets(childPath)
        }
    }
}
