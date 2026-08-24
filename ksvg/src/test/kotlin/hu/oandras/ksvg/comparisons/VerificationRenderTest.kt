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
import hu.oandras.ksvg.mocks.MockCanvas
import hu.oandras.ksvg.mocks.MockPaint
import hu.oandras.ksvg.mocks.MockPath
import hu.oandras.ksvg.mocks.asShadow
import hu.oandras.ksvg.render.createBitmap
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.ParameterizedRobolectricTestRunner
import org.robolectric.ParameterizedRobolectricTestRunner.Parameters
import org.robolectric.annotation.Config
import java.io.File

internal const val VERIFICATION_ROOT_PATH = "test-data/visual"
internal const val VERIFICATION_TARGET_SIZE = 256

@RunWith(ParameterizedRobolectricTestRunner::class)
@Config(manifest = Config.NONE, shadows = [MockCanvas::class, MockPath::class, MockPaint::class])
class VerificationRenderTest(
    private val svgFile: File,
) {

    @Test
    fun parsesAndRenders() {
        val svg = SVG.getFromInputStream(svgFile.inputStream(), parseAnimations = true)

        assertTrue(
            "Document has no intrinsic size for ${svgFile.name}",
            svg.documentWidth > 0f && svg.documentHeight > 0f
        )

        val bitmap: Bitmap = createBitmap(VERIFICATION_TARGET_SIZE, VERIFICATION_TARGET_SIZE)
        val canvas = Canvas(bitmap)

        val options = RenderOptions.create()
        options.viewPort(
            minX = 0f,
            minY = 0f,
            width = VERIFICATION_TARGET_SIZE.toFloat(),
            height = VERIFICATION_TARGET_SIZE.toFloat()
        )

        svg.renderToCanvas(canvas, options)

        val operations = canvas.asShadow().getOperations()
        assertTrue(
            "No canvas operations produced for ${svgFile.name}",
            operations.isNotEmpty()
        )

        val drawOperations = operations.count { it.startsWith("draw") }
        assertTrue(
            "No draw operations produced for ${svgFile.name}",
            drawOperations > 0
        )
    }

    companion object {

        @JvmStatic
        @Parameters(name = "{0}")
        fun data(): List<Array<Any>> {
            val root = File(VERIFICATION_ROOT_PATH)
            if (!root.exists()) return emptyList()

            return root.listSvgs().map { arrayOf(it) }
        }
    }
}
