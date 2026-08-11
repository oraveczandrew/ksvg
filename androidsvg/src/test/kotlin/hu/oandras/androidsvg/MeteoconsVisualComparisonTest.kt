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

internal const val METEOCONS_ROOT_PATH = "test-data/meteocons"
internal const val METEOCONS_GOLDEN_ROOT_PATH = "test-data/meteocons-golden"
internal const val METEOCONS_TARGET_SIZE = 256
internal const val METEOCONS_TARGET_SIZE_STR: String = METEOCONS_TARGET_SIZE.toString()

@RunWith(ParameterizedRobolectricTestRunner::class)
@Config(sdk = [34])
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class MeteoconsVisualComparisonTest(
    private val svgFile: File,
    private val targetSubFolder: File,
) {

    @Test
    fun compareIcon() {
        val refPng = File(targetSubFolder, svgFile.name.replace(".svg", ".png"))

        if (!refPng.exists()) {
            fail("Reference image does not exist: ${refPng.absolutePath}. Run FiltersCreateGoldenPngs to generate it.")
            return
        }

        // 1. Load reference and compare
        val refBitmap = decodePng(
            file = refPng,
            inBitmap = tempBitmap
        )

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
            targetWidth = METEOCONS_TARGET_SIZE,
            targetHeight = METEOCONS_TARGET_SIZE
        )

        private var _tempBitmap: Bitmap? = null
        private val tempBitmap: Bitmap
            get() = _tempBitmap ?: Bitmap.createBitmap(
                /* width = */ METEOCONS_TARGET_SIZE,
                /* height = */ METEOCONS_TARGET_SIZE,
                /* config = */ Bitmap.Config.ARGB_8888
            ).also {
                _tempBitmap = it
            }

        private var _tempBitmap2: Bitmap? = null
        private val tempBitmap2: Bitmap
            get() = _tempBitmap2 ?: Bitmap.createBitmap(
                /* width = */ METEOCONS_TARGET_SIZE,
                /* height = */ METEOCONS_TARGET_SIZE,
                /* config = */ Bitmap.Config.ARGB_8888
            ).also {
                _tempBitmap2 = it
            }

        private val goldenRootPath: File
            get() = File(METEOCONS_GOLDEN_ROOT_PATH)

        @JvmStatic
        @Parameters(name = "{0}")
        fun data(): List<Array<Any>> {
            val root = File(METEOCONS_ROOT_PATH)
            return ArrayList<Array<Any>>().apply {
                root.listDirectories().forEach { collection ->
                    collection.listDirectories().forEach { style ->
                        // The test data is always root/<collection>/<style>/<icon>.svg,
                        // so avoid File.toRelativeString(), which is expensive at this scale.
                        val relativeDirectory = File(collection.name, style.name)
                        val targetSubFolder = File(goldenRootPath, relativeDirectory.path)

                        val svgFiles = style.listSvgs()
                        ensureCapacity(size + svgFiles.size)
                        svgFiles.forEach { svg ->
                            add(arrayOf(svg, targetSubFolder))
                        }
                    }
                }
            }
        }
    }
}
