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

/**
 * Deterministic validation corpus for feConvolveMatrix.
 */
public object ConvolveValidationCorpus {

    data class Case(
        val name: String,
        val width: Int,
        val height: Int,
        val kernel: FloatArray,
        val orderX: Int,
        val orderY: Int,
        val targetX: Int,
        val targetY: Int,
        val divisor: Float,
        val bias: Float,
        val preserveAlpha: Boolean,
        val edgeMode: Int,
        val input: IntArray,
    ) {
        val size: Int get() = width * height

        fun reference(): IntArray {
            val out = IntArray(size)
            KotlinKernels.convolveMatrix(
                input, out, width, height,
                kernel, orderX, orderY, targetX, targetY,
                divisor, bias, preserveAlpha, edgeMode
            )
            return out
        }
    }

    val cases: List<Case> = buildList {
        // Simple 3x3 sharpen
        val sharpen = floatArrayOf(
            0f, -1f, 0f,
            -1f, 5f, -1f,
            0f, -1f, 0f
        )
        add(Case("sharpen 16x16", 16, 16, sharpen, 3, 3, 1, 1, 1f, 0f, true, 0, 
            UnlinearizeValidationCorpus.fixedSeedRandom(16 * 16)))
        
        // 5x5 blur
        val blur5x5 = FloatArray(25) { 1f / 25f }
        add(Case("blur5x5 32x8", 32, 8, blur5x5, 5, 5, 2, 2, 1f, 0f, false, 0,
            UnlinearizeValidationCorpus.fixedSeedRandom(32 * 8)))

        // Edge modes: wrap and none
        add(Case("wrap 16x16", 16, 16, sharpen, 3, 3, 1, 1, 1f, 0f, true, 1,
            UnlinearizeValidationCorpus.fixedSeedRandom(16 * 16)))
        add(Case("none 16x16", 16, 16, sharpen, 3, 3, 1, 1, 1f, 0f, true, 2,
            UnlinearizeValidationCorpus.fixedSeedRandom(16 * 16)))
        
        // Asymmetric kernel
        val asym = floatArrayOf(1f, 2f, 3f)
        add(Case("asym 1x3 32x32", 32, 32, asym, 3, 1, 1, 0, 1f, 0f, true, 0,
            UnlinearizeValidationCorpus.fixedSeedRandom(32 * 32)))
    }
}
