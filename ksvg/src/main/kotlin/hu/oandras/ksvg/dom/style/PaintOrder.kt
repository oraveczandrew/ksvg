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

package hu.oandras.ksvg.dom.style

import java.util.Locale

/**
 * SVG2 `paint-order`: the order in which fill, stroke and markers are painted.
 * Partial token lists are normalized by appending the missing components in
 * canonical (fill, stroke, markers) order, so every valid value maps to one of
 * the six permutations. `normal` is [FillStrokeMarkers].
 */
internal enum class PaintOrder {
    FillStrokeMarkers,
    StrokeFillMarkers,
    FillMarkersStroke,
    MarkersFillStroke,
    StrokeMarkersFill,
    MarkersStrokeFill;

    companion object {
        private const val FILL = 1
        private const val STROKE = 2
        private const val MARKERS = 3

        fun parse(value: String): PaintOrder? {
            var seen = 0
            var count = 0
            var order = 0
            for (token in value.trim().lowercase(Locale.US).split(WHITESPACE)) {
                if (token.isEmpty()) continue
                val component = when (token) {
                    "fill" -> FILL
                    "stroke" -> STROKE
                    "markers" -> MARKERS
                    else -> return null
                }
                if (seen and (1 shl component) != 0) return null
                seen = seen or (1 shl component)
                order = order * 4 + component
                count++
            }
            if (count == 0 || count > 3) return null
            // Append unspecified components in canonical order.
            for (component in intArrayOf(FILL, STROKE, MARKERS)) {
                if (seen and (1 shl component) == 0) {
                    order = order * 4 + component
                }
            }
            return when (order) {
                FILL * 16 + STROKE * 4 + MARKERS -> FillStrokeMarkers
                STROKE * 16 + FILL * 4 + MARKERS -> StrokeFillMarkers
                FILL * 16 + MARKERS * 4 + STROKE -> FillMarkersStroke
                MARKERS * 16 + FILL * 4 + STROKE -> MarkersFillStroke
                STROKE * 16 + MARKERS * 4 + FILL -> StrokeMarkersFill
                MARKERS * 16 + STROKE * 4 + FILL -> MarkersStrokeFill
                else -> null
            }
        }

        private val WHITESPACE = Regex("\\s+")
    }
}
