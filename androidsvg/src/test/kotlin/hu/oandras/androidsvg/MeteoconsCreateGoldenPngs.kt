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
import kotlin.collections.toList

@Ignore("x")
@RunWith(ParameterizedRobolectricTestRunner::class)
@Config(sdk = [34])
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class MeteoconsCreateGoldenPngs(
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
                METEOCONS_TARGET_SIZE_STR,
                "-h",
                METEOCONS_TARGET_SIZE_STR,
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
            get() = File(METEOCONS_GOLDEN_ROOT_PATH)

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
            val root = File(METEOCONS_ROOT_PATH)
            return root
                .listDirectories()
                .flatMap {
                    it
                        .listDirectories()
                        .toList()
                }.map {
                    arrayOf(it.toRelativeString(root), it)
                }
        }
    }
}

internal fun File.listDirectories(): Array<File> {
    return listFiles {
        it.isDirectory
    }!!
}

internal fun File.listSvgs(): Array<File> {
    return listFiles {
        it.path.endsWith(".svg")
    }!!
}

fun hasRsvgConvert(): Boolean {
    return try {
        val process = ProcessBuilder("which", "rsvg-convert").start()
        process.waitFor() == 0
    } catch (_: Exception) {
        false
    }
}