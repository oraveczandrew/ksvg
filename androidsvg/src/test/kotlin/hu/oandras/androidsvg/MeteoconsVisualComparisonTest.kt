package hu.oandras.androidsvg

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import org.junit.Assert.fail
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.ParameterizedRobolectricTestRunner
import org.robolectric.ParameterizedRobolectricTestRunner.Parameters
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode
import java.io.File
import kotlin.math.pow
import kotlin.math.sqrt

internal const val METEOCONS_ROOT_PATH = "test-data/meteocons"
internal const val METEOCONS_GOLDEN_ROOT_PATH = "test-data/meteocons-golden"
internal const val METEOCONS_TARGET_SIZE = 256
internal const val METEOCONS_TARGET_SIZE_STR: String = METEOCONS_TARGET_SIZE.toString()

@RunWith(ParameterizedRobolectricTestRunner::class)
@Config(sdk = [34])
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class MeteoconsVisualComparisonTest(
    private val relativePath: String,
    private val svgFile: File,
    private val targetSubFolder: File,
) {

    @Test
    fun compareIcon() {
        val refPng = File(targetSubFolder, "${svgFile.nameWithoutExtension}.png")

        // 1. Load reference and compare
        val refBitmap = BitmapFactory.decodeFile(refPng.absolutePath)
        if (refBitmap == null) {
            fail("Error: Could not decode reference for ${svgFile.name}")
            return
        }

        // 2. Render with library
        val libBitmap = try {
            renderWithLibrary(svgFile)
        } catch (e: Exception) {
            fail("Library failed to render ${svgFile.name}: ${e.message}")
            return
        }

        val similarity = compareBitmaps(refBitmap, libBitmap)
        if (similarity < 0.95) { // Allow 5% difference for engine variations
            val diffPercent = (1.0 - similarity) * 100.0
            fail("${svgFile.name} ($relativePath): ${"%.2f".format(diffPercent)}% difference. Check image in $refPng")
        }
    }

    private fun renderWithLibrary(file: File): Bitmap {
        val svg = file.inputStream().use { SVG.getFromInputStream(it) }
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

        private val goldenRootPath: File
            get() = File(METEOCONS_GOLDEN_ROOT_PATH)

        @JvmStatic
        @Parameters(name = "{0}")
        fun data(): List<Array<Any>> {
            val root = File(METEOCONS_ROOT_PATH)
            return root
                .listDirectories()
                .flatMap {
                    it.listDirectories()
                }.flatMap {
                    val targetSubFolder = File(goldenRootPath, it.toRelativeString(root))
                    it.listSvgs().map { svg ->
                        arrayOf(svg.toRelativeString(root), svg, targetSubFolder)
                    }
                }
        }
    }
}

