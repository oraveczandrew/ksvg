/*
 *    Copyright 2013-2020 Paul LeBeau, Cave Rock Software Ltd.
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

import hu.oandras.ksvg.parser.ColorParser
import hu.oandras.ksvg.utils.trimLowerThanSpace

internal const val CURRENT_COLOR: String = "currentColor"


internal fun parseFunctionalIRI(value: String): String? {
    return when {
        value.equals(NONE, ignoreCase = true) -> null
        !value.startsWith("url(", ignoreCase = true) -> null
        else -> {
            if (value.endsWith(')')) {
                value.substring(4, value.length - 1)
            } else {
                value.substring(4)
            }.trimLowerThanSpace()
        }
    }
}

internal fun parsePaintSpecifier(valueParam: String): SvgPaint {
    val trimmed = valueParam.trimLowerThanSpace()
    if (trimmed.equals("context-stroke", ignoreCase = true)) return ContextStroke
    if (trimmed.equals("context-fill", ignoreCase = true)) return ContextFill

    var value = valueParam
    return if (value.startsWith("url(")) {
        val closeBracket = value.indexOf(')')
        if (closeBracket != -1) {
            val href = value.substring(4, closeBracket).trimLowerThanSpace()
            value = value.substring(closeBracket + 1).trimLowerThanSpace()
            val fallback: SvgPaint? = if (value.isNotEmpty()) {
                parseColorSpecifier(value)
            } else {
                null
            }
            PaintReference(href, fallback)
        } else {
            val href = value.substring(4).trimLowerThanSpace()
            PaintReference(href, null)
        }
    } else {
        parseColorSpecifier(value)
    }
}

internal fun parseColorSpecifier(value: String): SvgColor {
    return when {
        value.equals(NONE, ignoreCase = true) -> ColorValue.TRANSPARENT
        value.equals(CURRENT_COLOR, ignoreCase = true) -> CurrentColor
        else -> ColorParser.parseColor(value)
    }
}
