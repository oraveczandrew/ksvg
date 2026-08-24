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

import hu.oandras.ksvg.KSVGParseException
import hu.oandras.ksvg.css.CSSLength
import hu.oandras.ksvg.css.CssUnit
import hu.oandras.ksvg.parser.TextScanner
import hu.oandras.ksvg.parser.parseLength
import hu.oandras.ksvg.parser.parseLengthOrAuto


internal fun parseLetterOrWordSpacing(value: String): CSSLength? {
    return if (value.equals("normal", ignoreCase = true)) {
        CSSLength.ZERO
    } else {
        try {
            val result: CSSLength = parseLength(value)
            // Percent units were removed in SVG2 and are treated as an error.
            if (result.unit == CssUnit.percent) {
                null
            } else {
                result
            }
        } catch (_: KSVGParseException) {
            null
        }
    }
}

// Parse CSS clip shape (always a rect())
internal fun parseClip(value: String): CSSClipRect? {
    if (value.equals("auto", ignoreCase = true)) return null
    if (!value.startsWith("rect(", ignoreCase = true)) return null

    val scan = TextScanner(value.substring(5))
    scan.skipWhitespace()

    val top: CSSLength = parseLengthOrAuto(scan)
    scan.skipCommaWhitespace()
    val right: CSSLength = parseLengthOrAuto(scan)
    scan.skipCommaWhitespace()
    val bottom: CSSLength = parseLengthOrAuto(scan)
    scan.skipCommaWhitespace()
    val left: CSSLength = parseLengthOrAuto(scan)

    scan.skipWhitespace()
    return if (!scan.consume(')') && !scan.empty()) {
        // Be forgiving. Allow missing ')'.
        null
    } else {
        CSSClipRect(top, right, bottom, left)
    }
}

// Parse overflow
internal fun parseOverflow(value: String): Boolean? {
    return when {
        value.equals("visible", ignoreCase = true) ||
                value.equals("auto", ignoreCase = true) -> true

        value.equals("hidden", ignoreCase = true) ||
                value.equals("scroll", ignoreCase = true) -> false

        else -> null
    }
}

internal fun isValidDisplayValue(value: String): Boolean {
    return value.equals("inline", ignoreCase = true) ||
            value.equals("block", ignoreCase = true) ||
            value.equals("list-item", ignoreCase = true) ||
            value.equals("run-in", ignoreCase = true) ||
            value.equals("compact", ignoreCase = true) ||
            value.equals("marker", ignoreCase = true) ||
            value.equals("table", ignoreCase = true) ||
            value.equals("inline-table", ignoreCase = true) ||
            value.equals("table-row-group", ignoreCase = true) ||
            value.equals("table-header-group", ignoreCase = true) ||
            value.equals("table-footer-group", ignoreCase = true) ||
            value.equals("table-row", ignoreCase = true) ||
            value.equals("table-column-group", ignoreCase = true) ||
            value.equals("table-column", ignoreCase = true) ||
            value.equals("table-cell", ignoreCase = true) ||
            value.equals("table-caption", ignoreCase = true) ||
            value.equals(NONE, ignoreCase = true)
}

internal fun isValidVisibilityValue(value: String): Boolean {
    return value.equals("visible", ignoreCase = true) ||
            value.equals("hidden", ignoreCase = true) ||
            value.equals("collapse", ignoreCase = true)
}

// Parse stroke-dash-array
internal fun parseStrokeDashArray(value: String): Array<CSSLength>? {
    val scan = TextScanner(value)
    scan.skipWhitespace()

    if (scan.empty()) return null

    val dash: CSSLength = scan.nextLength() ?: return null
    if (dash.isNegative) return null

    var sum = dash.floatValue()

    val dashes: ArrayList<CSSLength> = ArrayList()
    dashes.add(dash)
    while (!scan.empty()) {
        scan.skipCommaWhitespace()
        val nextDash = scan.nextLength() ?: return null
        if (nextDash.isNegative) return null
        dashes.add(nextDash)
        sum += nextDash.floatValue()
    }

    // Spec (section 11.4) says if the sum of dash lengths is zero, it should
    // be treated as "none" i.e., a solid stroke.
    return if (sum == 0f) {
        null
    } else {
        dashes.toTypedArray<CSSLength>()
    }
}
