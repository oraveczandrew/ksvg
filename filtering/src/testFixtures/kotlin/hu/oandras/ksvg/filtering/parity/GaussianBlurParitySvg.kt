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

import hu.oandras.ksvg.filtering.GaussianBlurValidationCorpus

/**
 * Round-B SVG builder for [GaussianBlurValidationCorpus] cases
 * (`tmp/GPU_PARITY_PLAN_B.md` §2-3).
 *
 * Pure Kotlin (no Android types): same data-URI `<image>` mechanism as
 * [MorphologyParitySvg] (see that builder for why `feImage` is out).
 *
 * Fidelity mapping (case -> SVG):
 * - `input` -> `<image>` pixels (positioned at 0,0, natural size).
 * - `stdDeviationX`/`stdDeviationY` -> `stdDeviation="sx sy"` (always the
 *   two-number form; `Float.toString` round-trips).
 * - No primitive subregion attributes: the corpus has no clip, so union
 *   inheritance (full filter region) applies on both backends.
 *
 * Conventions (shared with round-A): the filtered element carries
 * `filter="url(#f)"` (the runner derives the unfiltered baseline by
 * stripping it), and the filter region is pinned to the image bounds in
 * `userSpaceOnUse` so both backends measure the same pixels.
 *
 * Note: the GPU path (`RenderEffect.createBlurEffect` with the calibrated
 * `skiaBlurRadiusForSigma` mapping) is an approximation of the CPU kernel
 * (see `GPU_SCALAR_PARITY_REPORT.md` §7) — the runner carries per-case
 * tolerances for it. Both sides clamp out-of-bounds taps (Skia CLAMP vs
 * stack-blur clamp), so edges are comparable, unlike the wrap/none
 * convolve gap.
 */
public object GaussianBlurParitySvg {

    public fun toSvg(case: GaussianBlurValidationCorpus.Case, imageDataUri: String): String {
        return toSvg(
            width = case.width,
            height = case.height,
            stdDeviationX = case.stdDeviationX,
            stdDeviationY = case.stdDeviationY,
            imageDataUri = imageDataUri,
        )
    }

    public fun toSvg(
        width: Int,
        height: Int,
        stdDeviationX: Float,
        stdDeviationY: Float,
        imageDataUri: String,
    ): String {
        return "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"$width\" height=\"$height\">" +
            "<defs>" +
            "<filter id=\"f\" filterUnits=\"userSpaceOnUse\" x=\"0\" y=\"0\" width=\"$width\" height=\"$height\">" +
            "<feGaussianBlur stdDeviation=\"$stdDeviationX $stdDeviationY\"/>" +
            "</filter>" +
            "</defs>" +
            "<image href=\"$imageDataUri\" x=\"0\" y=\"0\" width=\"$width\" height=\"$height\" filter=\"url(#f)\"/>" +
            "</svg>"
    }
}
