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

import hu.oandras.ksvg.filtering.TurbulenceValidationCorpus

/**
 * Round-B SVG builder for [TurbulenceValidationCorpus] cases
 * (`tmp/GPU_PARITY_PLAN_B.md` §2-3).
 *
 * Pure Kotlin (no Android types): the filtered element is a data-URI
 * `<image>` like the other builders (uniform baseline-derivation
 * convention; the turbulence output replaces the source anyway).
 *
 * Fidelity mapping (case -> SVG):
 * - `baseFrequencyX/Y` -> `baseFrequency="bx by"` (`Double.toString`;
 *   all corpus values have exact short reprs, parsing back through
 *   Float is exact for them).
 * - `octaves` -> `numOctaves`, `fractalNoise` -> `type`, `seed` ->
 *   `seed` (kept verbatim, including seed 0 — the lattice is shared
 *   CPU/GPU-side by construction, so seed handling cannot diverge).
 * - `periodX/Y != 0` -> `stitchTiles="stitch"` (SVG has no period
 *   attributes; the GPU chain declines stitch anyway — fallback
 *   coverage in the runner).
 * - `clip*` -> primitive `x/y/width/height`, emitted ONLY when the clip is
 *   a strict subregion (same convention as the morphology builder).
 * - No `color-interpolation-filters` attr (default linearRGB): terminal
 *   turbulence gets the UN_LINEARIZE transfer on both backends (report
 *   §3.4/§7).
 * - Render-context geometry (`invCanvasScale`, `userLeft/Top`,
 *   `origin`, `unitSize`, `canvasScale`) is 1:1 in the test viewport by
 *   construction (filter pinned to image bounds, `userSpaceOnUse`);
 *   corpus cases with non-trivial context (`fractional`, `scaled`) keep
 *   their frequency/seed/octave values but render at 1:1 (documented
 *   adaptation — kernel-level fractional coverage stays in native
 *   parity).
 */
public object TurbulenceParitySvg {

    public fun toSvg(case: TurbulenceValidationCorpus.Case, imageDataUri: String): String {
        return toSvg(
            width = case.width,
            height = case.height,
            baseFrequencyX = case.baseFrequencyX,
            baseFrequencyY = case.baseFrequencyY,
            octaves = case.octaves,
            fractalNoise = case.fractalNoise,
            seed = case.seed,
            stitch = case.periodX != 0 || case.periodY != 0,
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
        baseFrequencyX: Double,
        baseFrequencyY: Double,
        octaves: Int,
        fractalNoise: Boolean,
        seed: Int,
        stitch: Boolean,
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
        val stitchAttr = if (stitch) " stitchTiles=\"stitch\"" else ""
        val type = if (fractalNoise) "fractalNoise" else "turbulence"
        return "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"$width\" height=\"$height\">" +
            "<defs>" +
            "<filter id=\"f\" filterUnits=\"userSpaceOnUse\" x=\"0\" y=\"0\" width=\"$width\" height=\"$height\">" +
            "<feTurbulence type=\"$type\" baseFrequency=\"$baseFrequencyX $baseFrequencyY\" " +
            "numOctaves=\"$octaves\" seed=\"$seed\"$stitchAttr$subregion/>" +
            "</filter>" +
            "</defs>" +
            "<image href=\"$imageDataUri\" x=\"0\" y=\"0\" width=\"$width\" height=\"$height\" filter=\"url(#f)\"/>" +
            "</svg>"
    }
}
