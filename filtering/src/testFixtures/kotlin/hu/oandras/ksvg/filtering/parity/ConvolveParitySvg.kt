/*
 *    Copyright 2026 András Oravecz <info@oandras.hu>
 *
 *    Licensed under the Apache License, Version 2.0 (the "License");
 *    you may not use this file except in compliance with the License.
 *    You may obtain a copy of the License at
 *
 *        https://www.apache.org/licenses/LICENSE-2.0
 *
 *    Unless required by applicable law or agreed to in writing, software
 *    distributed under the License is distributed on an "AS IS" BASIS,
 *    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *    See the License for the specific language governing permissions and
 *    limitations under the License.
 */

package hu.oandras.ksvg.filtering.parity

import hu.oandras.ksvg.filtering.ConvolveValidationCorpus

/**
 * Round-B SVG builder for [ConvolveValidationCorpus] cases
 * (`tmp/GPU_PARITY_PLAN_B.md` §2-3).
 *
 * Pure Kotlin (no Android types): same data-URI `<image>` mechanism as
 * [MorphologyParitySvg] (see that builder for why `feImage` is out).
 *
 * Fidelity mapping (case -> SVG):
 * - `input` -> `<image>` pixels (positioned at 0,0, natural size).
 * - `kernel`/`orderX`/`orderY` -> `kernelMatrix`/`order` (always the
 *   two-number `order` form; floats via `Float.toString`, which round-trips).
 * - `targetX`/`targetY`, `divisor`, `bias`, `preserveAlpha` -> verbatim.
 * - `edgeMode` (0=duplicate, 1=wrap, 2=none) -> `edgeMode` keyword. NOTE:
 *   the GPU chain only implements duplicate (clamp) sampling — wrap/none
 *   must fall back to software (guarded in `GpuFilterBackendApi33`, covered
 *   by fallback asserts in the runner, not parity asserts).
 * - No primitive subregion attributes: the corpus has no clip, so union
 *   inheritance (full filter region) applies on both backends.
 *
 * Conventions (shared with round-A): the filtered element carries
 * `filter="url(#f)"` (the runner derives the unfiltered baseline by
 * stripping it), and the filter region is pinned to the image bounds in
 * `userSpaceOnUse` so both backends measure the same pixels.
 */
public object ConvolveParitySvg {

    /** Edge-mode keywords by corpus ordinal (mirrors `ConvolveMatrixEdgeMode`). */
    public val edgeModeNames: Array<String> = arrayOf("duplicate", "wrap", "none")

    public fun toSvg(case: ConvolveValidationCorpus.Case, imageDataUri: String): String {
        return toSvg(
            width = case.width,
            height = case.height,
            kernel = case.kernel,
            orderX = case.orderX,
            orderY = case.orderY,
            targetX = case.targetX,
            targetY = case.targetY,
            divisor = case.divisor,
            bias = case.bias,
            preserveAlpha = case.preserveAlpha,
            edgeMode = edgeModeNames[case.edgeMode],
            imageDataUri = imageDataUri,
        )
    }

    public fun toSvg(
        width: Int,
        height: Int,
        kernel: FloatArray,
        orderX: Int,
        orderY: Int,
        targetX: Int,
        targetY: Int,
        divisor: Float,
        bias: Float,
        preserveAlpha: Boolean,
        edgeMode: String,
        imageDataUri: String,
    ): String {
        val kernelString = kernel.joinToString(separator = " ") { it.toString() }
        return "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"$width\" height=\"$height\">" +
            "<defs>" +
            "<filter id=\"f\" filterUnits=\"userSpaceOnUse\" x=\"0\" y=\"0\" width=\"$width\" height=\"$height\">" +
            "<feConvolveMatrix order=\"$orderX $orderY\" kernelMatrix=\"$kernelString\" " +
            "divisor=\"$divisor\" bias=\"$bias\" targetX=\"$targetX\" targetY=\"$targetY\" " +
            "edgeMode=\"$edgeMode\" preserveAlpha=\"$preserveAlpha\"/>" +
            "</filter>" +
            "</defs>" +
            "<image href=\"$imageDataUri\" x=\"0\" y=\"0\" width=\"$width\" height=\"$height\" filter=\"url(#f)\"/>" +
            "</svg>"
    }
}
