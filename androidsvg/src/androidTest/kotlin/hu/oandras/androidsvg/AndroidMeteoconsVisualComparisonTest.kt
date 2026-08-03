package hu.oandras.androidsvg

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.fail
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.Parameterized
import kotlin.math.pow
import kotlin.math.sqrt

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
        val assets = InstrumentationRegistry.getInstrumentation().context.assets

        // 1. Load reference and compare
        val refBitmap = assets.open(referenceAssetPath).use(BitmapFactory::decodeStream)
        if (refBitmap == null) {
            fail("Error: Could not decode reference for $svgAssetPath")
            return
        }

        // 2. Render with library
        val libBitmap = try {
            renderWithLibrary(svgAssetPath)
        } catch (e: Exception) {
            fail("Library failed to render $svgAssetPath: ${e.message}")
            return
        }

        val similarity = compareBitmaps(refBitmap, libBitmap)
        if (similarity < 0.95) { // Allow 5% difference for engine variations
            val diffPercent = (1.0 - similarity) * 100.0
            fail("$svgAssetPath ($relativePath): ${"%.2f".format(diffPercent)}% difference. Check image in $referenceAssetPath")
        }
    }

    private fun renderWithLibrary(svgAssetPath: String): Bitmap {
        val assets = InstrumentationRegistry.getInstrumentation().context.assets
        val svg = assets.open(svgAssetPath).use { SVG.getFromInputStream(it) }
        val bitmap = Bitmap.createBitmap(
            /* width = */ METEOCONS_TARGET_SIZE,
            /* height = */ METEOCONS_TARGET_SIZE,
            /* config = */ Bitmap.Config.ARGB_8888
        )
        val canvas = Canvas(bitmap)

        val options = RenderOptions.create()
        options.viewPort(
            minX = 0f,
            minY = 0f,
            width = METEOCONS_TARGET_SIZE.toFloat(),
            height = METEOCONS_TARGET_SIZE.toFloat()
        )

        svg.renderToCanvas(canvas, options)
        return bitmap
    }

    private fun compareBitmaps(b1: Bitmap, b2: Bitmap): Double {
        if (b1.width != b2.width || b1.height != b2.height) return 0.0

        var matchingPixels = 0
        val totalPixels = b1.width * b1.height
        val pixels1 = IntArray(totalPixels)
        val pixels2 = IntArray(totalPixels)

        b1.getPixels(pixels1, 0, b1.width, 0, 0, b1.width, b1.height)
        b2.getPixels(pixels2, 0, b2.width, 0, 0, b2.width, b2.height)

        for (i in 0 until totalPixels) {
            if (isColorSimilar(pixels1[i], pixels2[i])) {
                matchingPixels++
            }
        }

        return matchingPixels.toDouble() / totalPixels.toDouble()
    }

    private fun isColorSimilar(c1: Int, c2: Int): Boolean {
        if (c1 == c2) return true

        val r1 = Color.red(c1)
        val g1 = Color.green(c1)
        val b1 = Color.blue(c1)
        val a1 = Color.alpha(c1)

        val r2 = Color.red(c2)
        val g2 = Color.green(c2)
        val b2 = Color.blue(c2)
        val a2 = Color.alpha(c2)

        val dist = sqrt(
            (r1 - r2).toDouble().pow(2.0) +
                    (g1 - g2).toDouble().pow(2.0) +
                    (b1 - b2).toDouble().pow(2.0) +
                    (a1 - a2).toDouble().pow(2.0)
        )

        return dist < 15.0
    }

    companion object {
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

private fun android.content.res.AssetManager.listSvgAssets(path: String): List<String> {
    return list(path).orEmpty().flatMap { name ->
        val childPath = "$path/$name"
        if (name.endsWith(".svg", ignoreCase = true)) {
            listOf(childPath)
        } else {
            listSvgAssets(childPath)
        }
    }
}
