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

import hu.oandras.ksvg.filtering.ComponentTransferValidationCorpus

/**
 * Round-B SVG builder for [ComponentTransferValidationCorpus] cases
 * (`tmp/GPU_PARITY_PLAN_B.md` §2-3).
 *
 * Pure Kotlin (no Android types): same data-URI `<image>` mechanism as
 * [MorphologyParitySvg] (see that builder for why `feImage` is out).
 *
 * Fidelity mapping (case -> SVG):
 * - `input` -> `<image>` pixels (positioned at 0,0, natural size).
 * - `tableA/R/G/B` (packed bytes) -> per-channel `type="table"`
 *   `tableValues` with 256 `byte/255f` floats. `Float.toString` round-trips,
 *   and the CPU table interpolation lands back on the exact byte after its
 *   final rounding (neighbor values are integers, fp dust is ~1e-5).
 * - `clip*` -> primitive `x/y/width/height`, emitted ONLY when the clip is
 *   a strict subregion (same convention as the morphology builder).
 * - `color-interpolation-filters="sRGB"`: the corpus tables are raw byte
 *   maps, matching the CPU `useLinearRgb=false` LUT path (and the GPU LUT
 *   textures built from the same tables). Without it the linearRGB EOTF
 *   path would apply and diverge from the corpus reference by design.
 *
 * Conventions (shared with round-A): the filtered element carries
 * `filter="url(#f)"` (the runner derives the unfiltered baseline by
 * stripping it), and the filter region is pinned to the image bounds in
 * `userSpaceOnUse` so both backends measure the same pixels.
 */
public object ComponentTransferParitySvg {

    public fun toSvg(case: ComponentTransferValidationCorpus.Case, imageDataUri: String): String {
        return toSvg(
            width = case.width,
            height = case.height,
            tableA = unpack(case.tableA, 24),
            tableR = unpack(case.tableR, 16),
            tableG = unpack(case.tableG, 8),
            tableB = unpack(case.tableB, 0),
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
        tableA: ByteArray,
        tableR: ByteArray,
        tableG: ByteArray,
        tableB: ByteArray,
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
            "<feComponentTransfer$subregion color-interpolation-filters=\"sRGB\">" +
            "<feFuncA type=\"table\" tableValues=\"${tableString(tableA)}\"/>" +
            "<feFuncR type=\"table\" tableValues=\"${tableString(tableR)}\"/>" +
            "<feFuncG type=\"table\" tableValues=\"${tableString(tableG)}\"/>" +
            "<feFuncB type=\"table\" tableValues=\"${tableString(tableB)}\"/>" +
            "</feComponentTransfer>" +
            "</filter>" +
            "</defs>" +
            "<image href=\"$imageDataUri\" x=\"0\" y=\"0\" width=\"$width\" height=\"$height\" filter=\"url(#f)\"/>" +
            "</svg>"
    }

    /**
     * Corpus packed-int tables back to bytes, then to `tableValues` floats.
     * `Float.toString` yields the shortest round-tripping representation.
     */
    public fun tableString(table: ByteArray): String {
        return buildString(table.size * 8) {
            for (i in table.indices) {
                if (i > 0) append(' ')
                append(((table[i].toInt() and 0xFF) / 255f).toString())
            }
        }
    }

    private fun unpack(packed: IntArray, shift: Int): ByteArray {
        return ByteArray(packed.size) { ((packed[it] shr shift) and 0xFF).toByte() }
    }
}
