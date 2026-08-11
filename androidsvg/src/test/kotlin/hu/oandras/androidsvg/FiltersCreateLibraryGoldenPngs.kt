package hu.oandras.androidsvg

import android.graphics.Bitmap
import android.graphics.Canvas
import org.junit.Ignore
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.ParameterizedRobolectricTestRunner
import org.robolectric.ParameterizedRobolectricTestRunner.Parameters
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode
import java.io.File
import java.io.FileOutputStream

@Ignore("Run manually to update library-specific golden images")
@RunWith(ParameterizedRobolectricTestRunner::class)
@Config(sdk = [34])
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class FiltersCreateLibraryGoldenPngs(
    private val svgFile: File,
    private val targetSubFolder: File,
) {

    @Test
    fun createGolden() {
        if (!targetSubFolder.exists()) {
            targetSubFolder.mkdirs()
        }

        val outputPng = File(targetSubFolder, svgFile.name.replace(".svg", ".png"))
        
        val svg = svgFile.inputStream().use { SVG.getFromInputStream(it) }
        val bitmap = Bitmap.createBitmap(
            /* width = */ FILTERS_TARGET_SIZE,
            /* height = */ FILTERS_TARGET_SIZE,
            /* config = */ Bitmap.Config.ARGB_8888
        )
        val canvas = Canvas(bitmap)

        val options = RenderOptions.create()
        options.viewPort(
            minX = 0f,
            minY = 0f,
            width = FILTERS_TARGET_SIZE.toFloat(),
            height = FILTERS_TARGET_SIZE.toFloat()
        )

        svg.renderToCanvas(canvas, options)
        
        FileOutputStream(outputPng).use {
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, it)
        }
        
        println("Generated library golden: ${outputPng.absolutePath}")
    }

    companion object {

        @JvmStatic
        @Parameters(name = "{0}")
        fun data(): List<Array<Any>> {
            val root = File(FILTERS_ROOT_PATH)
            if (!root.exists()) return emptyList()
            
            val goldenRootPath = File(FILTERS_GOLDEN_ROOT_PATH)
            
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
