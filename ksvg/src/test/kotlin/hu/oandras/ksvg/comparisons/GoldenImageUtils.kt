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
import android.graphics.BitmapFactory
import org.junit.Assume.assumeTrue
import java.io.File
import java.util.concurrent.TimeUnit

/**
 * Renders [svgFile] with `rsvg-convert` into a square [size]×[size] PNG that matches
 * how KSVG renders the SVG into an explicit square viewport (see [renderWithLibrary],
 * which always sets a `size`×`size` viewport via `RenderOptions`).
 *
 * To get `rsvg-convert` to honour the SVG's `preserveAspectRatio` into that square
 * viewport we must override the root `<svg>` element's `width`/`height` to [size].
 * `rsvg-convert` otherwise maps the `viewBox` into the SVG's *intrinsic* size first
 * and only then scales that to the requested output, which both letter-boxes
 * `slice` content and stretches `meet` content non-uniformly. With a square root
 * viewport equal to the output size the `viewBox`→viewport mapping is a single,
 * uniform, spec-compliant step.
 *
 * @return the exit code of `rsvg-convert` (0 on success).
 */
internal fun renderReferenceGolden(svgFile: File, outputFile: File, size: Int): Int {
    val rawFile = File.createTempFile("ksvg-golden-", ".png").apply { deleteOnExit() }

    val svgSource = svgFile.readText()
    val sizedSource = overrideRootSize(svgSource, size)

    val process = ProcessBuilder(
        "rsvg-convert",
        "-w",
        size.toString(),
        "-h",
        size.toString(),
        "-b",
        "none",
        "-",
        "-o",
        rawFile.absolutePath
    ).apply { redirectInput(ProcessBuilder.Redirect.PIPE) }.start()

    process.outputStream.use { it.write(sizedSource.toByteArray()) }
    process.outputStream.close()

    val exit = if (process.waitFor(10, TimeUnit.SECONDS)) {
        process.exitValue()
    } else {
        process.destroy()
        -1
    }

    if (exit != 0) {
        rawFile.delete()
        return exit
    }

    val raw = BitmapFactory.decodeFile(rawFile.absolutePath) ?: run {
        rawFile.delete()
        return -1
    }

    writeLosslessPngTo(outputFile, raw)

    rawFile.delete()
    return 0
}

/**
 * Replaces (or, if missing, adds) the `width` and `height` attributes on the root
 * `<svg>` element so that the SVG is laid out into a [size]×[size] viewport. The
 * `viewBox` and `preserveAspectRatio` attributes are preserved, which is what makes
 * `rsvg-convert` honour the aspect-ratio handling into the square output.
 */
private fun overrideRootSize(svg: String, size: Int): String {
    val open = svg.indexOf("<svg")
    if (open < 0) return svg
    val close = svg.indexOf(">", open)
    if (close < 0) return svg

    val before = svg.substring(0, open)
    val tag = svg.substring(open, close + 1)
    val after = svg.substring(close + 1)

    val widthReplaced = if (Regex("""\swidth\s*=""").containsMatchIn(tag)) {
        Regex("""width\s*=\s*"[^"]*"""").replace(tag, "width=\"$size\"")
    } else {
        tag.replaceFirst(">", " width=\"$size\">")
    }
    val heightReplaced = if (Regex("""\sheight\s*=""").containsMatchIn(widthReplaced)) {
        Regex("""height\s*=\s*"[^"]*"""").replace(widthReplaced, "height=\"$size\"")
    } else {
        widthReplaced.replaceFirst(">", " height=\"$size\">")
    }

    return before + heightReplaced + after
}

fun writeLosslessPngTo(file: File, bitmap: Bitmap) {
    file.outputStream().use {
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, it)
    }
}

fun hasRsvgConvert(): Boolean {
    return try {
        val process = ProcessBuilder("which", "rsvg-convert").start()
        process.waitFor() == 0
    } catch (_: Exception) {
        false
    }
}

fun assumeHasRsvgConvert() {
    assumeTrue("rsvg-convert not found", hasRsvgConvert())
}

/**
 * Deletes [rootPath] (if it exists) and recreates it empty, so a golden-generation run
 * starts from a clean slate without leaving goldens from SVGs that were removed.
 */
internal fun reinitFolder(rootPath: String) {
    val folder = File(rootPath)
    if (folder.exists()) {
        folder.deleteRecursively()
    }
    folder.mkdirs()
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

/**
 * The optional CLI filter (`-PverifyFilter=name`) used by the visual-comparison tests to run
 * on a single SVG instead of the whole suite. Returns `null` when no filter was supplied.
 */
internal fun currentVerifyFilter(): String? =
    System.getProperty("ksvg.verify.filter")?.takeIf { it.isNotBlank() }

/**
 * Keeps only the SVGs whose file name contains [currentVerifyFilter] (case-insensitive).
 * When no filter is set, the list is returned unchanged.
 */
internal fun List<File>.applyVerifyFilter(): List<File> {
    val filter = currentVerifyFilter() ?: return this
    return filter { it.name.contains(filter, ignoreCase = true) }
}
