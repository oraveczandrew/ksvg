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
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.Parameterized

@RunWith(Parameterized::class)
class MorphologyNativeParityTest(
    private val clipLeft: Int,
    private val clipTop: Int,
    private val clipRight: Int,
    private val clipBottom: Int,
    private val radiusX: Int,
    private val radiusY: Int,
    private val erode: Boolean,
) {
    companion object {
        init {
            System.loadLibrary("ksvgblur")
        }

        @JvmStatic
        @Parameterized.Parameters
        fun data(): List<Array<Any>> = listOf(
            // full frame, erode, radius 1
            arrayOf(0, 0, 32, 32, 1, 1, true),
            // full frame, dilate, radius 1
            arrayOf(0, 0, 32, 32, 1, 1, false),
            // anisotropic radius, dilate
            arrayOf(0, 0, 40, 30, 3, 2, false),
            // clip sub-rectangle, erode, radius touches edges
            arrayOf(4, 6, 28, 26, 2, 2, true),
            // large radius (kernel spans whole frame), dilate
            arrayOf(0, 0, 24, 24, 30, 30, false),
        )
    }

    @Test
    fun nativeMatchesKotlin() {
        assertTrue("libksvgblur not loadable on the host JVM", MorphologyNative.isAvailable)

        val width = 32
        val height = 32
        val src = pattern(width, height, erode.hashCode() + radiusX * 7 + radiusY)
        val ref = IntArray(width * height)
        val native = IntArray(width * height)

        KotlinKernels.morphology(
            src, ref, width, height, radiusX, radiusY, erode,
            clipLeft, clipTop, clipRight, clipBottom,
        )
        SoftwareKernels.morphology(
            src, native, width, height, radiusX, radiusY, erode,
            clipLeft, clipTop, clipRight, clipBottom,
        )

        assertArrayEquals("morphology mismatch", ref, native)
    }
}
