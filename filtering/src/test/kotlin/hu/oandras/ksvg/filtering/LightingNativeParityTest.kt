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
class LightingNativeParityTest(
    private val lightType: Int,
    private val specular: Boolean,
    private val params: DoubleArray,
) {
    companion object {

        @JvmStatic
        @Parameterized.Parameters
        fun data(): List<Array<Any>> = listOf(
            arrayOf(0, false, doubleArrayOf(45.0, 30.0)), // distant, diffuse
            arrayOf(0, true, doubleArrayOf(90.0, 60.0)), // distant, specular
            arrayOf(1, false, doubleArrayOf(20.0, 25.0, 60.0)), // point, diffuse
            arrayOf(1, true, doubleArrayOf(10.0, 10.0, 40.0)), // point, specular
            arrayOf(2, false, doubleArrayOf(15.0, 20.0, 50.0, 0.0, 0.0, 0.0, 20.0)), // spot, cone
            arrayOf(2, true, doubleArrayOf(15.0, 20.0, 50.0, 0.0, 0.0, 0.0, Double.NaN)), // spot, no cone
        )
    }

    @Test
    fun nativeMatchesKotlin() {
        assertNativeBackendAvailable()

        val width = 32
        val height = 32
        for (useLinear in listOf(false, true)) {
            for (premultiplied in listOf(false, true)) {
                if (premultiplied && !specular) continue

                val src = pattern(width, height, lightType * 13 + specular.hashCode())
                val ref = IntArray(width * height)
                val native = IntArray(width * height)

                KotlinKernels.lighting(
                    src, ref, width, height, 0, 0, width, height,
                    surfaceScaleNormalized = 1f,
                    invCanvasScaleX = 1.0, invCanvasScaleY = 1.0,
                    userLeft = 0.0, userTop = 0.0, originX = 0.0, originY = 0.0,
                    unitSizeX = 1.0, unitSizeY = 1.0,
                    canvasScaleX = 1f, canvasScaleY = 1f,
                    lightType = lightType, specular = specular,
                    k = 1f, exponent = 20f, lightR = 255, lightG = 255, lightB = 255,
                    params = params, premultipliedOutput = premultiplied, useLinear = useLinear,
                )
                SoftwareKernels.lighting(
                    src, native, width, height, 0, 0, width, height,
                    surfaceScaleNormalized = 1f,
                    invCanvasScaleX = 1.0, invCanvasScaleY = 1.0,
                    userLeft = 0.0, userTop = 0.0, originX = 0.0, originY = 0.0,
                    unitSizeX = 1.0, unitSizeY = 1.0,
                    canvasScaleX = 1f, canvasScaleY = 1f,
                    lightType = lightType, specular = specular,
                    k = 1f, exponent = 20f, lightR = 255, lightG = 255, lightB = 255,
                    params = params, premultipliedOutput = premultiplied, useLinear = useLinear,
                )

                assertArrayEquals(
                    "lighting mismatch: type=$lightType specular=$specular useLinear=$useLinear premult=$premultiplied",
                    ref, native,
                )
            }
        }
    }
}
