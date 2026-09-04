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

    public class Case(
        public val name: String,
        public val width: Int,
        public val height: Int,
        public val kernel: FloatArray,
        public val orderX: Int,
        public val orderY: Int,
        public val targetX: Int,
        public val targetY: Int,
        public val divisor: Float,
        public val bias: Float,
        public val preserveAlpha: Boolean,
        public val edgeMode: Int,
        public val input: IntArray,
    ) {
        public val size: Int get() = width * height

        public fun reference(): IntArray {
            val out = IntArray(size)
            KotlinKernels.convolveMatrix(
                input, out, width, height,
                kernel, orderX, orderY, targetX, targetY,
                divisor, bias, preserveAlpha, edgeMode
            )
            return out
        }
    }

    public val cases: List<Case> = buildList {
        // Simple 3x3 sharpen
        val sharpen = floatArrayOf(
            0f, -1f, 0f,
            -1f, 5f, -1f,
            0f, -1f, 0f
        )
        add(Case("sharpen 16x16", 16, 16, sharpen, 3, 3, 1, 1, 1f, 0f, true, 0,
            UnLinearizeValidationCorpus.fixedSeedRandom(16 * 16)))
        
        // 5x5 blur
        val blur5x5 = FloatArray(25) { 1f / 25f }
        add(Case("blur5x5 32x8", 32, 8, blur5x5, 5, 5, 2, 2, 1f, 0f, false, 0,
            UnLinearizeValidationCorpus.fixedSeedRandom(32 * 8)))

        // Edge modes: wrap and none
        add(Case("wrap 16x16", 16, 16, sharpen, 3, 3, 1, 1, 1f, 0f, true, 1,
            UnLinearizeValidationCorpus.fixedSeedRandom(16 * 16)))
        add(Case("none 16x16", 16, 16, sharpen, 3, 3, 1, 1, 1f, 0f, true, 2,
            UnLinearizeValidationCorpus.fixedSeedRandom(16 * 16)))
        
        // Asymmetric kernel
        val asym = floatArrayOf(1f, 2f, 3f)
        add(Case("asym 1x3 32x32", 32, 32, asym, 3, 1, 1, 0, 1f, 0f, true, 0,
            UnLinearizeValidationCorpus.fixedSeedRandom(32 * 32)))

        // Anchor at top-left (target 0,0): shift the convolution start.
        add(Case("anchor 0,0 3x3 16x16", 16, 16, sharpen, 3, 3, 0, 0, 1f, 0f, false, 0,
            UnLinearizeValidationCorpus.fixedSeedRandom(16 * 16)))

        // Non-square 3x2 duplicate-edge kernel (orderX != orderY with duplicate).
        val box32 = floatArrayOf(0.5f, 0.5f, 0.5f, 0.5f, 0.5f, 0.5f)
        add(Case("box 3x2 duplicate 16x16", 16, 16, box32, 3, 2, 1, 1, 1f, 0.15f, false, 0,
            UnLinearizeValidationCorpus.fixedSeedRandom(16 * 16)))

        // These two force the AArch64 NEON assembly specializations in
        // applyNeonInterior (only reachable via the NEON64 backend on a real
        // ARM64 device): preserveAlpha=true, anchor at centre, edgeMode=0.
        //
        // 3x3 -> ksvgConvolve3x3NeonAsm (interior SIMD, edges handled by the
        //       applyNeon3x3AsmWithEdges wrapper).
        // 5x5 -> ksvgConvolve5x5NeonAsm (interior SIMD only).
        add(Case("asm 3x3 preserve 20x20", 20, 20, sharpen, 3, 3, 1, 1, 1f, 0f, true, 0,
            UnLinearizeValidationCorpus.fixedSeedRandom(20 * 20)))
        add(Case("asm 5x5 preserve 20x20", 20, 20, blur5x5, 5, 5, 2, 2, 1f, 0f, true, 0,
            UnLinearizeValidationCorpus.fixedSeedRandom(20 * 20)))
    }
}
