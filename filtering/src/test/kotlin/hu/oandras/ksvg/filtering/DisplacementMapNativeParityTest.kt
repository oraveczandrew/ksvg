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

package hu.oandras.ksvg.filtering

import org.junit.Assert.assertArrayEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.Parameterized

@RunWith(Parameterized::class)
class DisplacementMapNativeParityTest(
    private val scale: Float,
    private val xChannel: Int,
    private val yChannel: Int,
) {
    companion object {

        @JvmStatic
        @Parameterized.Parameters
        fun data(): List<Array<Any>> = listOf(
            arrayOf(10f, 0, 1), // R, G
            arrayOf(20f, 2, 3), // B, A
            arrayOf(-5f, 1, 1), // G, G, negative scale
            arrayOf(0f, 0, 0),  // identity
        )
    }

    @Test
    fun nativeMatchesKotlin() {
        assertNativeBackendAvailable()

        val width = 32
        val height = 32
        val mapWidth = 24
        val mapHeight = 40
        val src = pattern(width, height, 1)
        val map = pattern(mapWidth, mapHeight, 2)
        val ref = IntArray(width * height)
        val native = IntArray(width * height)

        KotlinKernels.displacementMap(
            src, map, ref, width, height, mapWidth, mapHeight, scale, xChannel, yChannel
        )
        SoftwareKernels.displacementMap(
            src, map, native, width, height, mapWidth, mapHeight, scale, xChannel, yChannel
        )

        assertArrayEquals("displacementMap mismatch", ref, native)
    }
}
