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

import hu.oandras.ksvg.filtering.DisplacementMapValidationCorpus

/**
 * Round-B SVG builder for [DisplacementMapValidationCorpus] cases
 * (`tmp/GPU_PARITY_PLAN_B.md` §2-3).
 *
 * Pure Kotlin (no Android types): same data-URI `<image>` mechanism as
 * [MorphologyParitySvg] (see that builder for why `feImage` is out).
 *
 * Fidelity mapping (case -> SVG):
 * - `src` -> `<image>` pixels (positioned at 0,0, natural size), wired
 *   as `in="SourceGraphic"`. Verbatim, alpha included: displacement only
 *   *selects* source texels (no min/max races), so the PNG round-trip is
 *   parity-neutral here — the same texel decodes to the same bytes on
 *   both backends. No `opaqueInput` (unlike morphology).
 * - `map` -> ADAPTED (documented gap): the corpus pixel array cannot enter
 *   the GPU path (`feImage` is CPU-only → silent SW fallback → vacuous
 *   pass), so a fixed `feTurbulence` (`MAP_*` constants, `result="map"`)
 *   generates the displacement field. Scale, channel selectors and the
 *   src size stay covered; the corpus map bytes and the differing map
 *   size (`different 32x8`: 16x4 map over a 32x8 src — the native parity
 *   tests own that routing) are lost. `fractalNoise` keeps map alpha
 *   centered (~112-143, never near 0), and the turbulence shader emits
 *   straight values into the chain, so both backends read the same
 *   straight map channels (no premultiplied-storage divergence).
 *   Base frequency 0.15 (not the Round-A 0.05): the corpus surfaces are
 *   tiny (16x16), and 0.05 leaves less than one noise feature across the
 *   map — so flat the corpus smallest scale (-5) displaces nothing.
 * - `src` representation: the GPU chain is premultiplied end to end
 *   (morphology-shader kdoc: taps carry premultiplied values, emission is
 *   verbatim). Displacement copies the selected texel through untouched,
 *   so the hardware output is the premultiplied texel while the software
 *   bitmap holds it straight — the runner compares in premultiplied
 *   space (`premultiplyReference`), where float-vs-integer rounding is
 *   ±1-2 LSB. Selection itself is exact (no min/max races), so the PNG
 *   round-trip stays parity-neutral: no `opaqueInput`.
 * - `scale` -> verbatim (`Float.toString` round-trips).
 * - `xChannel`/`yChannel` (corpus 0=R,1=G,2=B,3=A) -> `R/G/B/A` names
 *   (matching `FeChannelSelector` ordinals on both backends).
 *
 * Conventions (shared with round-A): the filtered element carries
 * `filter="url(#f)"` (the runner derives the unfiltered baseline by
 * stripping it), and the filter region is pinned to the image bounds in
 * `userSpaceOnUse` so both backends measure the same pixels.
 */
public object DisplacementMapParitySvg {

    public const val MAP_TYPE: String = "fractalNoise"
    public const val MAP_BASE_FREQUENCY: String = "0.15"
    public const val MAP_NUM_OCTAVES: Int = 2
    public const val MAP_SEED: Int = 8

    public fun toSvg(case: DisplacementMapValidationCorpus.Case, imageDataUri: String): String {
        return toSvg(
            width = case.width,
            height = case.height,
            scale = case.scale,
            xChannel = case.xChannel,
            yChannel = case.yChannel,
            imageDataUri = imageDataUri,
        )
    }

    public fun toSvg(
        width: Int,
        height: Int,
        scale: Float,
        xChannel: Int,
        yChannel: Int,
        imageDataUri: String,
    ): String {
        return "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"$width\" height=\"$height\">" +
            "<defs>" +
            "<filter id=\"f\" filterUnits=\"userSpaceOnUse\" x=\"0\" y=\"0\" width=\"$width\" height=\"$height\">" +
            "<feTurbulence type=\"$MAP_TYPE\" baseFrequency=\"$MAP_BASE_FREQUENCY\" " +
            "numOctaves=\"$MAP_NUM_OCTAVES\" seed=\"$MAP_SEED\" result=\"map\"/>" +
            "<feDisplacementMap in=\"SourceGraphic\" in2=\"map\" " +
            "scale=\"$scale\" xChannelSelector=\"${channelName(xChannel)}\" " +
            "yChannelSelector=\"${channelName(yChannel)}\"/>" +
            "</filter>" +
            "</defs>" +
            "<image href=\"$imageDataUri\" x=\"0\" y=\"0\" width=\"$width\" height=\"$height\" filter=\"url(#f)\"/>" +
            "</svg>"
    }

    public fun channelName(channel: Int): String = when (channel) {
        0 -> "R"
        1 -> "G"
        2 -> "B"
        else -> "A"
    }
}
