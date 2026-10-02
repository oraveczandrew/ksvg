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

@file:Suppress("EnumEntryName")

package hu.oandras.ksvg.dom.text

/** SVG `textPath` `side`: which side of the path the text renders on. */
internal enum class TextPathSide {
    left,
    right;

    companion object {
        fun parseOrNull(value: String): TextPathSide? {
            if (value.equals("left", ignoreCase = true)) return left
            if (value.equals("right", ignoreCase = true)) return right
            return null
        }
    }
}

/**
 * SVG `textPath` `spacing`: `auto` lets the renderer adjust inter-glyph
 * spacing, `exact` forbids it. Both render with natural advances (the static
 * renderer never auto-adjusts on a path).
 */
internal enum class TextPathSpacing {
    auto,
    exact;

    companion object {
        fun parseOrNull(value: String): TextPathSpacing? {
            if (value.equals("auto", ignoreCase = true)) return auto
            if (value.equals("exact", ignoreCase = true)) return exact
            return null
        }
    }
}

/**
 * SVG `textPath` `method`: `align` keeps glyphs rigid along the path
 * (supported); `stretch` would deform glyphs to the path (not supported —
 * renders as `align`).
 */
internal enum class TextPathMethod {
    align,
    stretch;

    companion object {
        fun parseOrNull(value: String): TextPathMethod? {
            if (value.equals("align", ignoreCase = true)) return align
            if (value.equals("stretch", ignoreCase = true)) return stretch
            return null
        }
    }
}
