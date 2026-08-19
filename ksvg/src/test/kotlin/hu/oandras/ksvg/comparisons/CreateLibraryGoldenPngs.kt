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
class CreateLibraryGoldenPngs(
    svgFile: File,
    targetSubFolder: File,
) : AbstractCreateLibraryGoldenPngs(svgFile, targetSubFolder) {

    override val targetSize: Int
        get() = VISUAL_TARGET_SIZE

    override val parseAnimations: Boolean
        get() = true

    companion object {

        @JvmStatic
        @BeforeClass
        fun check() {
            val targetFolder = File(VISUAL_LIBRARY_GOLDEN_ROOT_PATH)
            if (targetFolder.exists()) {
                targetFolder.deleteRecursively()
            }
            targetFolder.mkdirs()
        }

        @JvmStatic
        @Parameters(name = "{0}")
        fun data(): List<Array<Any>> {
            val root = File(VISUAL_ROOT_PATH)
            if (!root.exists()) return emptyList()

            return root.listSvgs().toList().map { svg ->
                arrayOf(svg, File(VISUAL_LIBRARY_GOLDEN_ROOT_PATH))
            }
        }
    }
}
