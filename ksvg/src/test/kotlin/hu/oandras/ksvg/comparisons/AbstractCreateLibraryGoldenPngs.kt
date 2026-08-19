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
import android.graphics.Canvas
import hu.oandras.ksvg.RenderOptions
import hu.oandras.ksvg.SVG
import hu.oandras.ksvg.render.createBitmap
import org.junit.Test
import java.io.File

/**
 * Shared logic for the `*CreateLibraryGoldenPngs` tests: it renders a single SVG with KSVG
 * itself into a square reference PNG (what `renderWithLibrary` produces in the comparison
 * tests).
 *
 * Concrete subclasses only have to provide the target size, whether animations are parsed,
 * and the parameter list (each parameter is a `(svgFile, targetSubFolder)` pair).
 */
abstract class AbstractCreateLibraryGoldenPngs(
    protected val svgFile: File,
    protected val targetSubFolder: File,
) {

    @Test
    fun createGolden() {
        if (!targetSubFolder.exists()) {
            targetSubFolder.mkdirs()
        }

        val outputPng = File(targetSubFolder, svgFile.name.replace(".svg", ".png"))

        val svg = svgFile.inputStream().use { SVG.getFromInputStream(it, parseAnimations = parseAnimations) }
        val bitmap = createBitmap(width = targetSize, height = targetSize)
        val canvas = Canvas(bitmap)

        val options = RenderOptions.create()
        options.viewPort(
            minX = 0f,
            minY = 0f,
            width = targetSize.toFloat(),
            height = targetSize.toFloat()
        )

        svg.renderToCanvas(canvas, options)

        writeLosslessPngTo(outputPng, bitmap)

        println("Generated library golden: ${outputPng.absolutePath}")
    }

    protected abstract val targetSize: Int

    protected abstract val parseAnimations: Boolean
}
