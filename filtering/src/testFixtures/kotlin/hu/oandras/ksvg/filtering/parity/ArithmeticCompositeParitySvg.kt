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

import hu.oandras.ksvg.filtering.ArithmeticCompositeValidationCorpus

/**
 * Round-B SVG builder for [ArithmeticCompositeValidationCorpus] cases
 * (`tmp/GPU_PARITY_PLAN_B.md` §2-3).
 *
 * Pure Kotlin (no Android types): same data-URI `<image>` mechanism as
 * [MorphologyParitySvg] (see that builder for why `feImage` is out).
 *
 * Fidelity mapping (case -> SVG):
 * - `input1` -> `<image>` pixels (positioned at 0,0, natural size), wired
 *   as `in="SourceGraphic"`.
 * - `input2` -> ADAPTED (documented gap): arbitrary pixel arrays cannot
 *   enter the GPU path (`feImage` is CPU-only), so a constant
 *   `feFlood` (`FLOOD_COLOR`, opaque) feeds `in2`. Operators, k-coeffs,
 *   clips and color spaces stay covered; input2 variety is lost.
 * - `k1..k4` -> verbatim (`Float.toString` round-trips).
 * - `useLinear` -> `color-interpolation-filters="linearRGB"|"sRGB"`
 *   (explicit; the linear path has its own GPU support story, see the
 *   runner).
 * - `clip*` -> primitive `x/y/width/height`, emitted ONLY when the clip is
 *   a strict subregion (same convention as the morphology builder).
 *
 * Conventions (shared with round-A): the filtered element carries
 * `filter="url(#f)"` (the runner derives the unfiltered baseline by
 * stripping it), and the filter region is pinned to the image bounds in
 * `userSpaceOnUse` so both backends measure the same pixels.
 */
public object ArithmeticCompositeParitySvg {

    /** Asymmetric opaque flood color feeding `in2` (exercises channels unevenly). */
    public const val FLOOD_COLOR: String = "#4060c0"

    public fun toSvg(case: ArithmeticCompositeValidationCorpus.Case, imageDataUri: String): String {
        return toSvg(
            width = case.width,
            height = case.height,
            k1 = case.k1,
            k2 = case.k2,
            k3 = case.k3,
            k4 = case.k4,
            useLinear = case.useLinear,
            clipLeft = case.clipLeft,
            clipTop = case.clipTop,
            clipRight = case.clipRight,
            clipBottom = case.clipBottom,
            imageDataUri = imageDataUri,
        )
    }

    public fun toSvg(
        width: Int,
        height: Int,
        k1: Float,
        k2: Float,
        k3: Float,
        k4: Float,
        useLinear: Boolean,
        clipLeft: Int,
        clipTop: Int,
        clipRight: Int,
        clipBottom: Int,
        imageDataUri: String,
    ): String {
        val subregion = if (clipLeft == 0 && clipTop == 0 && clipRight == width && clipBottom == height) {
            ""
        } else {
            " x=\"$clipLeft\" y=\"$clipTop\" width=\"${clipRight - clipLeft}\" height=\"${clipBottom - clipTop}\""
        }
        val colorSpace = if (useLinear) "linearRGB" else "sRGB"
        return "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"$width\" height=\"$height\">" +
            "<defs>" +
            "<filter id=\"f\" filterUnits=\"userSpaceOnUse\" x=\"0\" y=\"0\" width=\"$width\" height=\"$height\">" +
            "<feFlood flood-color=\"$FLOOD_COLOR\" result=\"c\"/>" +
            "<feComposite operator=\"arithmetic\" in=\"SourceGraphic\" in2=\"c\" " +
            "k1=\"$k1\" k2=\"$k2\" k3=\"$k3\" k4=\"$k4\"$subregion " +
            "color-interpolation-filters=\"$colorSpace\"/>" +
            "</filter>" +
            "</defs>" +
            "<image href=\"$imageDataUri\" x=\"0\" y=\"0\" width=\"$width\" height=\"$height\" filter=\"url(#f)\"/>" +
            "</svg>"
    }
}
