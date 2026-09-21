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

import hu.oandras.ksvg.filtering.LightingValidationCorpus

/**
 * Round-B SVG builder for [LightingValidationCorpus] cases
 * (`tmp/GPU_PARITY_PLAN_B.md` §2-3).
 *
 * Pure Kotlin (no Android types): same data-URI `<image>` mechanism as
 * [MorphologyParitySvg] (see that builder for why `feImage` is out).
 *
 * Fidelity mapping (case -> SVG):
 * - `input` -> `<image>` pixels (positioned at 0,0, natural size). NOTE:
 *   the height map is read from ALPHA (both kernels), so the runner must
 *   NOT opaque-ify the input (unlike the other corpora) — flattening
 *   alpha would erase the height signal. The PNG round-trip touches both
 *   backends identically (parity-neutral, smooth math, no selection).
 * - `lightType` 0/1/2 -> `feDistantLight` (azimuth/elevation),
 *   `fePointLight` (x/y/z), `feSpotLight` (x/y/z + pointsAt +
 *   limitingConeAngle, omitted when NaN = no cone). All corpus values are
 *   integral, so double->string->float is exact.
 * - `surfaceScale`, diffuse/specular `k` (constant), `exponent`
 *   (specular only), `lightR/G/B` (`lighting-color`) -> verbatim. The
 *   corpus `premultiplied` flag needs no mapping: both backends derive
 *   terminal-premult from filter position (always terminal here).
 * - `useLinear` -> `color-interpolation-filters="linearRGB"|"sRGB"`.
 * - `clip*` -> primitive `x/y/width/height`, emitted ONLY when the clip is
 *   a strict subregion (all corpus clips are full; kept for uniformity).
 *
 * Known approximations (verified per-case on device, see worklog):
 * - Spot cone: the GPU shader has no cone logic (spot renders as point);
 *   the corpus geometries sit fully inside their cones, so no cutoff
 *   triggers on either side. Spot's own specularExponent is missing from
 *   the DOM (RENDERING_FILTERING.md §3.2) — the parent exponent feeds
 *   both sides equally here.
 *
 * Conventions (shared with round-A): the filtered element carries
 * `filter="url(#f)"` (the runner derives the unfiltered baseline by
 * stripping it), and the filter region is pinned to the image bounds in
 * `userSpaceOnUse` so both backends measure the same pixels (matches the
 * corpus unit scales).
 */
public object LightingParitySvg {

    public fun toSvg(case: LightingValidationCorpus.Case, imageDataUri: String): String {
        val light = when (case.lightType) {
            0 -> "<feDistantLight azimuth=\"${case.params[0]}\" elevation=\"${case.params[1]}\"/>"
            1 -> "<fePointLight x=\"${case.params[0]}\" y=\"${case.params[1]}\" z=\"${case.params[2]}\"/>"
            else -> buildSpotLight(case.params)
        }
        val color = "#${hex(case.lightR)}${hex(case.lightG)}${hex(case.lightB)}"
        val colorSpace = if (case.useLinear) "linearRGB" else "sRGB"
        val subregion = if (case.clipLeft == 0 && case.clipTop == 0 &&
            case.clipRight == case.width && case.clipBottom == case.height
        ) {
            ""
        } else {
            " x=\"${case.clipLeft}\" y=\"${case.clipTop}\" " +
                "width=\"${case.clipRight - case.clipLeft}\" height=\"${case.clipBottom - case.clipTop}\""
        }
        val primitive = if (case.specular) {
            "<feSpecularLighting surfaceScale=\"${case.surfaceScale}\" " +
                "specularConstant=\"${case.k}\" specularExponent=\"${case.exponent}\" " +
                "lighting-color=\"$color\"$subregion " +
                "color-interpolation-filters=\"$colorSpace\">$light</feSpecularLighting>"
        } else {
            "<feDiffuseLighting surfaceScale=\"${case.surfaceScale}\" " +
                "diffuseConstant=\"${case.k}\" lighting-color=\"$color\"$subregion " +
                "color-interpolation-filters=\"$colorSpace\">$light</feDiffuseLighting>"
        }
        return "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"${case.width}\" height=\"${case.height}\">" +
            "<defs>" +
            "<filter id=\"f\" filterUnits=\"userSpaceOnUse\" x=\"0\" y=\"0\" " +
            "width=\"${case.width}\" height=\"${case.height}\">" +
            primitive +
            "</filter>" +
            "</defs>" +
            "<image href=\"$imageDataUri\" x=\"0\" y=\"0\" " +
            "width=\"${case.width}\" height=\"${case.height}\" filter=\"url(#f)\"/>" +
            "</svg>"
    }

    private fun buildSpotLight(params: DoubleArray): String {
        val cone = if (params[6].isNaN()) {
            ""
        } else {
            " limitingConeAngle=\"${params[6]}\""
        }
        return "<feSpotLight x=\"${params[0]}\" y=\"${params[1]}\" z=\"${params[2]}\" " +
            "pointsAtX=\"${params[3]}\" pointsAtY=\"${params[4]}\" pointsAtZ=\"${params[5]}\"$cone/>"
    }

    private fun hex(v: Int): String = v.toString(16).padStart(2, '0')
}
