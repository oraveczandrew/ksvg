package hu.oandras.androidsvg

import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.runBlocking
import org.junit.Assume.assumeTrue
import org.junit.BeforeClass
import org.junit.Ignore
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.ParameterizedRobolectricTestRunner
import org.robolectric.ParameterizedRobolectricTestRunner.Parameters
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode
import java.io.File
import java.util.concurrent.TimeUnit

@Ignore("Run manually to generate golden images")
@RunWith(ParameterizedRobolectricTestRunner::class)
@Config(sdk = [34])
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class FiltersCreateGoldenPngs(
    private val subFolderRelativePath: String,
    private val subFolder: File,
) {

    @Test
    fun test() {
        println("Processing ${subFolder.absolutePath}")

        val targetSubFolder = File(targetFolder, subFolderRelativePath)
        if (targetSubFolder.exists()) {
            targetSubFolder.deleteRecursively()
        }
        targetSubFolder.mkdirs()

        val svgs = subFolder.listSvgs()

        runBlocking(converterDispatcher) {
            svgs.map { svg ->
                async {
                    val svgFileName = svg.name
                    val outputFile = File(targetSubFolder, svgFileName.replace(".svg", ".png"))
                    val rsvgResult = runRsvgConvert(svg, outputFile)

                    if (rsvgResult != 0) {
                        println("Error: rsvg-convert failed for $svgFileName with code $rsvgResult")
                    } else {
                        println("Converted $svgFileName to ${outputFile.name}")
                    }
                }
            }.forEach {
                it.await()
            }
        }

        println("Done")
    }

    private fun runRsvgConvert(svgFile: File, outputFile: File): Int {
        val process = ProcessBuilder(
            /* command = */ listOf(
                "rsvg-convert",
                "-w",
                FILTERS_TARGET_SIZE_STR,
                "-h",
                FILTERS_TARGET_SIZE_STR,
                "-b",
                "none",
                svgFile.absolutePath,
                "-o",
                outputFile.absolutePath
            )
        ).start()

        return if (process.waitFor(10, TimeUnit.SECONDS)) {
            process.exitValue()
        } else {
            process.destroy()
            -1
        }
    }

    companion object {

        private val converterDispatcher: CoroutineDispatcher = Dispatchers.Default.limitedParallelism(Runtime.getRuntime().availableProcessors())

        private val targetFolder: File
            get() = File(FILTERS_GOLDEN_ROOT_PATH)

        @JvmStatic
        @BeforeClass
        fun check() {
            assumeTrue("rsvg-convert not found", hasRsvgConvert())

            if (!targetFolder.exists()) {
                targetFolder.mkdirs()
            }
        }

        @JvmStatic
        @Parameters(name = "{0}")
        fun data(): List<Array<Any>> {
            val root = File(FILTERS_ROOT_PATH)
            if (!root.exists()) return emptyList()

            return root
                .listDirectories()
                .map {
                    arrayOf(it.toRelativeString(root), it)
                }
        }
    }
}
