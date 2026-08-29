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

import org.junit.BeforeClass
import org.junit.Ignore
import org.junit.runner.RunWith
import org.robolectric.ParameterizedRobolectricTestRunner
import org.robolectric.ParameterizedRobolectricTestRunner.Parameters
import org.robolectric.annotation.GraphicsMode
import java.io.File

@Ignore("Run manually to generate golden images")
@RunWith(ParameterizedRobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class CreateGoldenPngs(
    svgFile: File,
    targetSubFolder: File,
) : AbstractCreateGoldenPngs(svgFile, targetSubFolder) {

    override val targetSize: Int
        get() = VISUAL_TARGET_SIZE

    companion object {
        private var cleaned = false

        @JvmStatic
        @BeforeClass
        fun check() {
            assumeHasRsvgConvert()
            if (!cleaned) {
                reinitFolder(VISUAL_GOLDEN_ROOT_PATH)
                cleaned = true
            }
        }

        @JvmStatic
        @Parameters(name = "{0}")
        fun data(): List<Array<Any>> {
            val root = File(VISUAL_ROOT_PATH)
            if (!root.exists()) return emptyList()

            return root.listSvgs().toList().map { svg ->
                arrayOf(svg, File(VISUAL_GOLDEN_ROOT_PATH))
            }
        }
    }
}
