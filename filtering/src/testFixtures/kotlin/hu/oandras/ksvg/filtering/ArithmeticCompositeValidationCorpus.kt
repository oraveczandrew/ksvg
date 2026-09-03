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
 * Deterministic validation corpus for feComposite operator="arithmetic".
 */
public object ArithmeticCompositeValidationCorpus {

    public class Case(
        public val name: String,
        public val width: Int,
        public val height: Int,
        public val clipLeft: Int,
        public val clipTop: Int,
        public val clipRight: Int,
        public val clipBottom: Int,
        public val k1: Float,
        public val k2: Float,
        public val k3: Float,
        public val k4: Float,
        public val useLinear: Boolean,
        public val input1: IntArray,
        public val input2: IntArray,
    ) {
        public val size: Int get() = width * height

        public fun reference(): IntArray {
            val out = IntArray(size)
            KotlinKernels.arithmeticComposite(
                input1, input2, out, width,
                clipLeft, clipTop, clipRight, clipBottom,
                k1, k2, k3, k4, useLinear
            )
            return out
        }
    }

    public val cases: List<Case> = buildList {
        // Various coefficients and sRGB/linear settings
        for (useLinear in listOf(false, true)) {
            val space = if (useLinear) "linear" else "sRGB"
            
            // Addition: k1=0, k2=1, k3=1, k4=0
            add(Case("add $space 16x16", 16, 16, 0, 0, 16, 16, 0f, 1f, 1f, 0f, useLinear,
                UnLinearizeValidationCorpus.fixedSeedRandom(16 * 16),
                UnLinearizeValidationCorpus.fixedSeedRandom(16 * 16).reversedArray()))
            
            // Subtraction: k1=0, k2=1, k3=-1, k4=0
            add(Case("sub $space 32x8", 32, 8, 0, 0, 32, 8, 0f, 1f, -1f, 0f, useLinear,
                UnLinearizeValidationCorpus.fixedSeedRandom(32 * 8),
                UnLinearizeValidationCorpus.fixedSeedRandom(32 * 8).reversedArray()))

            // Multiply: k1=1, k2=0, k3=0, k4=0
            add(Case("mul $space 16x16", 16, 16, 0, 0, 16, 16, 1f, 0f, 0f, 0f, useLinear,
                UnLinearizeValidationCorpus.fixedSeedRandom(16 * 16),
                UnLinearizeValidationCorpus.fixedSeedRandom(16 * 16).reversedArray()))

            // Sub-clip region
            add(Case("subclip $space 32x32", 32, 32, 4, 4, 28, 28, 0.5f, 0.5f, 0.5f, 0.1f, useLinear,
                UnLinearizeValidationCorpus.fixedSeedRandom(32 * 32),
                UnLinearizeValidationCorpus.fixedSeedRandom(32 * 32).reversedArray()))

            // Constant bias only (k4 > 0): result = k4 everywhere.
            add(Case("bias $space 16x16", 16, 16, 0, 0, 16, 16, 0f, 0f, 0f, 0.25f, useLinear,
                UnLinearizeValidationCorpus.fixedSeedRandom(16 * 16),
                UnLinearizeValidationCorpus.fixedSeedRandom(16 * 16).reversedArray()))
        }
    }
}
