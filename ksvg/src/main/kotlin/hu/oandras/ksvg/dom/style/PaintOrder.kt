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

import androidx.annotation.IntDef
import java.util.Locale

/**
 * SVG2 `paint-order`: the order in which fill, stroke and markers are painted.
 *
 * Encoded as three 2-bit digits (component order, high digit first):
 * each digit is [Companion.FILL] = 1, [Companion.STROKE] = 2 or
 * [Companion.MARKERS] = 3. This is exactly the encoding the renderer unpacks
 * while painting, so parsed values can be used directly with zero translation.
 *
 * Partial token lists are normalized by appending the missing components in
 * canonical (fill, stroke, markers) order, so every valid value maps to one of
 * the six permutations. `normal` is [Companion.FillStrokeMarkers].
 * 0 means unspecified.
 */
@Retention(AnnotationRetention.SOURCE)
@IntDef(
    PaintOrder.FillStrokeMarkers,
    PaintOrder.StrokeFillMarkers,
    PaintOrder.FillMarkersStroke,
    PaintOrder.MarkersFillStroke,
    PaintOrder.StrokeMarkersFill,
    PaintOrder.MarkersStrokeFill,
    PaintOrder.UNSPECIFIED,
)
public annotation class PaintOrder {
    public companion object {
        public const val UNSPECIFIED: Int = 0

        public const val FILL: Int = 1
        public const val STROKE: Int = 2
        public const val MARKERS: Int = 3

        public const val FillStrokeMarkers: Int = (FILL shl 4) or (STROKE shl 2) or MARKERS
        public const val StrokeFillMarkers: Int = (STROKE shl 4) or (FILL shl 2) or MARKERS
        public const val FillMarkersStroke: Int = (FILL shl 4) or (MARKERS shl 2) or STROKE
        public const val MarkersFillStroke: Int = (MARKERS shl 4) or (FILL shl 2) or STROKE
        public const val StrokeMarkersFill: Int = (STROKE shl 4) or (MARKERS shl 2) or FILL
        public const val MarkersStrokeFill: Int = (MARKERS shl 4) or (STROKE shl 2) or FILL

        /** Parses a `paint-order` value; returns [UNSPECIFIED] when invalid or empty. */
        public fun parse(value: String): Int {
            var seen = 0
            var count = 0
            var order = 0
            for (token in value.trim().lowercase(Locale.US).split(WHITESPACE)) {
                if (token.isEmpty()) continue
                val component = when (token) {
                    "fill" -> FILL
                    "stroke" -> STROKE
                    "markers" -> MARKERS
                    else -> return UNSPECIFIED
                }
                if (seen and (1 shl component) != 0) return UNSPECIFIED
                seen = seen or (1 shl component)
                order = order * 4 + component
                count++
            }
            if (count == 0 || count > 3) return UNSPECIFIED
            // Append unspecified components in canonical order.
            for (component in intArrayOf(FILL, STROKE, MARKERS)) {
                if (seen and (1 shl component) == 0) {
                    order = order * 4 + component
                }
            }
            return order
        }

        private val WHITESPACE: Regex = Regex("\\s+")
    }
}
