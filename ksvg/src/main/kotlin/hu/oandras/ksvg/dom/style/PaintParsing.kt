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
import hu.oandras.ksvg.utils.equalsWindow
import hu.oandras.ksvg.utils.skipLeading
import hu.oandras.ksvg.utils.skipTrailing

internal const val CURRENT_COLOR: String = "currentColor"


internal fun parseFunctionalIRI(value: String): String? = parseFunctionalIRI(value, 0, value.length)

internal fun parseFunctionalIRI(text: String, start: Int, end: Int): String? {
    if (text.equalsWindow(start, end, NONE, ignoreCase = true)) return null
    if (!(end - start >= 4 && text.regionMatches(start, "url(", 0, 4, ignoreCase = true))) return null
    val innerEnd = if (end > start && text[end - 1] == ')') end - 1 else end
    val trimmedStart = skipLeading(text, start + 4, innerEnd)
    val trimmedEnd = skipTrailing(text, trimmedStart, innerEnd)
    return text.substring(trimmedStart, trimmedEnd)
}

internal fun parsePaintSpecifier(valueParam: String): SvgPaint =
    parsePaintSpecifier(valueParam, 0, valueParam.length)

internal fun parsePaintSpecifier(text: String, start: Int, end: Int): SvgPaint {
    val se = start.coerceIn(0, text.length)
    val ee = end.coerceIn(se, text.length)
    val s = skipLeading(text, se, ee)
    val e = skipTrailing(text, s, ee)
    if (text.equalsWindow(s, e, "context-stroke", ignoreCase = true)) return ContextStroke
    if (text.equalsWindow(s, e, "context-fill", ignoreCase = true)) return ContextFill

    // NOTE: like the original, the url test runs on the UNtrimmed window start
    // (a leading space means "not a url()"), while name/href/tail windows below
    // are trimmed. Only the stored href is ever copied.
    if (ee - se >= 4 && text.regionMatches(se, "url(", 0, 4, ignoreCase = true)) {
        var close = se + 4
        while (close < e && text[close] != ')') close++
        if (close < e) {
            val hs = skipLeading(text, se + 4, close)
            val he = skipTrailing(text, hs, close)
            val href = text.substring(hs, he)
            val fs = skipLeading(text, close + 1, e)
            val fe = skipTrailing(text, fs, e)
            val fallback: SvgPaint? = if (fs < fe) {
                parseColorSpecifier(text, fs, fe)
            } else {
                null
            }
            return PaintReference(href, fallback)
        } else {
            val hs = skipLeading(text, se + 4, e)
            val he = skipTrailing(text, hs, e)
            return PaintReference(text.substring(hs, he), null)
        }
    } else {
        return parseColorSpecifier(text, s, e)
    }
}

internal fun parseColorSpecifier(value: String): SvgColor = parseColorSpecifier(value, 0, value.length)

internal fun parseColorSpecifier(text: String, start: Int, end: Int): SvgColor {
    return when {
        text.equalsWindow(start, end, NONE, ignoreCase = true) -> ColorValue.TRANSPARENT
        text.equalsWindow(start, end, CURRENT_COLOR, ignoreCase = true) -> CurrentColor
        else -> ColorParser.parseColor(text, start, end)
    }
}
