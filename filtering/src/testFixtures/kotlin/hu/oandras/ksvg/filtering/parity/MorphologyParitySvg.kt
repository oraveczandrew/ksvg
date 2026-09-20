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

import hu.oandras.ksvg.filtering.MorphologyValidationCorpus

/**
 * Round-B SVG builder for [MorphologyValidationCorpus] cases
 * (`tmp/GPU_PARITY_PLAN_B.md` §2-3).
 *
 * Pure Kotlin (no Android types): the corpus [IntArray] input reaches the
 * filter as `SourceGraphic` through a device-side PNG data URI
 * (`<image href="data:...">`, see `GpuCorpusParity.imageSource`), because
 * `feImage` is CPU-only and would silently force the software fallback.
 * The builder takes the URI as a string so it stays host-testable.
 *
 * Fidelity mapping (case -> SVG):
 * - `input` -> `<image>` pixels (positioned at 0,0, natural size).
 * - `radiusX`/`radiusY` -> `radius="rx ry"`.
 * - `erode` -> `operator="erode|dilate"`.
 * - `clip*` -> primitive `x/y/width/height`, emitted ONLY when the clip is
 *   a strict subregion: full-clip cases omit the subregion attributes and
 *   thereby exercise the union-inheritance path instead.
 *
 * Conventions (shared with round-A): the filtered element carries
 * `filter="url(#f)"` (the runner derives the unfiltered baseline by
 * stripping it), and the filter region is pinned to the image bounds in
 * `userSpaceOnUse` so both backends measure the same pixels.
 */
public object MorphologyParitySvg {

    public fun toSvg(case: MorphologyValidationCorpus.Case, imageDataUri: String): String {
        return toSvg(
            width = case.width,
            height = case.height,
            operator = if (case.erode) "erode" else "dilate",
            radiusX = case.radiusX,
            radiusY = case.radiusY,
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
        operator: String,
        radiusX: Int,
        radiusY: Int,
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
        return "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"$width\" height=\"$height\">" +
            "<defs>" +
            "<filter id=\"f\" filterUnits=\"userSpaceOnUse\" x=\"0\" y=\"0\" width=\"$width\" height=\"$height\">" +
            "<feMorphology operator=\"$operator\" radius=\"$radiusX $radiusY\"$subregion/>" +
            "</filter>" +
            "</defs>" +
            "<image href=\"$imageDataUri\" x=\"0\" y=\"0\" width=\"$width\" height=\"$height\" filter=\"url(#f)\"/>" +
            "</svg>"
    }
}
