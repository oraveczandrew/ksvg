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

package hu.oandras.ksvg.parser

import hu.oandras.ksvg.KSVGParseException
import hu.oandras.ksvg.css.CSSLength
import hu.oandras.ksvg.css.CssUnit
import hu.oandras.ksvg.utils.equalsWindow


//=========================================================================
// Parsing various SVG value types
//=========================================================================
/*
* Parse an SVG 'Length' value (usually a coordinate).
* Spec says: length ::= number ("em" | "ex" | "px" | "in" | "cm" | "mm" | "pt" | "pc" | "%")?
*/
@Throws(KSVGParseException::class)
internal fun parseLength(value: String): CSSLength {
    return parseLength(value, 0, value.length)
}

// Windowed twin: parses `[start, end)` with no substring or lowercase copy.
// Unit matching mirrors the `CssUnit.valueOf(lowercase)` table above exactly.
@Throws(KSVGParseException::class)
internal fun parseLength(text: String, start: Int, end: Int): CSSLength {
    checkState(start < end) { "Invalid length value (empty string)" }

    var e = end
    var unit = CssUnit.px
    val lastChar = text[e - 1]

    if (lastChar == '%') {
        e -= 1
        unit = CssUnit.percent
    } else if (e - start > 2 && lastChar.isLetter() && text[e - 2].isLetter()) {
        e -= 2
        unit = when {
            text.equalsWindow(e, end, "px", ignoreCase = true) -> CssUnit.px
            text.equalsWindow(e, end, "em", ignoreCase = true) -> CssUnit.em
            text.equalsWindow(e, end, "ex", ignoreCase = true) -> CssUnit.ex
            text.equalsWindow(e, end, "in", ignoreCase = true) -> CssUnit.`in`
            text.equalsWindow(e, end, "cm", ignoreCase = true) -> CssUnit.cm
            text.equalsWindow(e, end, "mm", ignoreCase = true) -> CssUnit.mm
            text.equalsWindow(e, end, "pt", ignoreCase = true) -> CssUnit.pt
            text.equalsWindow(e, end, "pc", ignoreCase = true) -> CssUnit.pc
            else -> throw KSVGParseException("Invalid length unit specifier: ${text.substring(start, end)}")
        }
    }
    try {
        val scalar: Float = parseFloat(text, start, e)
        return CSSLength.of(scalar, unit)
    } catch (e: NumberFormatException) {
        throw KSVGParseException("Invalid length value: ${text.substring(start, end)}", e)
    }
}

@Throws(KSVGParseException::class)
internal fun parseNonNegativeLength(value: String, errorMessage: String): CSSLength {
    return parseLength(value).also {
        checkState(!it.isNegative) { errorMessage }
    }
}

/*
* Parse a list of Length/Coords
*/
@Throws(KSVGParseException::class)
internal fun parseLengthList(value: String): List<CSSLength> {
    checkState(value.isNotEmpty()) { "Invalid length list (empty string)" }

    val coords = ArrayList<CSSLength>(1)

    val scan = TextScanner(value)
    scan.skipWhitespace()

    while (!scan.empty()) {
        val scalar = scan.nextFloat()
        checkState(!scalar.isNaN()) { "Invalid length list value: " + scan.ahead() }
        val unit = scan.nextUnit() ?: CssUnit.px
        coords.add(CSSLength.of(scalar, unit))
        scan.skipCommaWhitespace()
    }
    return coords
}

internal fun parseLengthOrAuto(scan: TextScanner): CSSLength {
    return if (scan.consumeIgnoreCase("auto")) {
        CSSLength.ZERO
    } else {
        scan.nextLength() ?: CSSLength.ZERO
    }
}