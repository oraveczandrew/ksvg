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

import org.junit.Test
import java.io.File

/**
 * Shared logic for the `*CreateGoldenPngs` tests: it renders a single SVG into a square
 * reference PNG (see [renderReferenceGolden]) using the supplied size.
 *
 * Concrete subclasses only have to provide the target size and the parameter list (each
 * parameter is a `(svgFile, targetSubFolder)` pair).
 */
abstract class AbstractCreateGoldenPngs(
    protected val svgFile: File,
    protected val targetSubFolder: File,
) {

    @Test
    fun test() {
        if (!targetSubFolder.exists()) {
            targetSubFolder.mkdirs()
        }

        val outputFile = File(targetSubFolder, svgFile.name.replace(".svg", ".png"))
        val result = renderReferenceGolden(svgFile, outputFile, targetSize)

        if (result != 0) {
            println("Error: rsvg-convert failed for ${svgFile.name} with code $result")
        } else {
            println("Converted ${svgFile.name} to ${outputFile.name}")
        }
    }

    protected abstract val targetSize: Int
}
