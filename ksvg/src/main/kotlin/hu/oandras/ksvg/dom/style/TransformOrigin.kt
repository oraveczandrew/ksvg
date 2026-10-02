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

package hu.oandras.ksvg.dom.style

import hu.oandras.ksvg.KSVGParseException
import hu.oandras.ksvg.css.CSSLength
import hu.oandras.ksvg.css.CssUnit
import hu.oandras.ksvg.parser.parseLength
import hu.oandras.ksvg.utils.splitBy

/**
 * Parsed CSS `transform-origin` (`<x> [<y> [<z>]]`, keywords included).
 * Percentages resolve against the `transform-box` reference box at build
 * time; the `z` component is 2D-ignored (parsed but dropped).
 */
internal data class TransformOrigin(
    @JvmField
    val x: CSSLength,
    @JvmField
    val y: CSSLength,
)

// Parses a transform-origin value; null when invalid (ignored declaration).
internal fun parseTransformOrigin(value: String): TransformOrigin? {
    val tokens = value.splitBy { it == ',' || it <= ' ' }
    if (tokens.isEmpty() || tokens.size > 3) return null
    val x = parseOriginComponent(tokens[0], isX = true) ?: return null
    // Single value: y defaults to center (CSS).
    val y = if (tokens.size == 1) {
        CSSLength(50f, CssUnit.percent)
    } else {
        parseOriginComponent(tokens[1], isX = false) ?: return null
    }
    return TransformOrigin(x, y)
}

private fun parseOriginComponent(token: String, isX: Boolean): CSSLength? {
    val percent = when {
        token.equals("left", ignoreCase = true) && isX -> 0f
        token.equals("top", ignoreCase = true) && !isX -> 0f
        token.equals("center", ignoreCase = true) -> 50f
        token.equals("right", ignoreCase = true) && isX -> 100f
        token.equals("bottom", ignoreCase = true) && !isX -> 100f
        else -> null
    }
    if (percent != null) return CSSLength(percent, CssUnit.percent)
    return try {
        parseLength(token)
    } catch (_: KSVGParseException) {
        null
    }
}
