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
import java.util.Locale


//=========================================================================
// Parsing various SVG value types
//=========================================================================
/*
* Parse an SVG 'Length' value (usually a coordinate).
* Spec says: length ::= number ("em" | "ex" | "px" | "in" | "cm" | "mm" | "pt" | "pc" | "%")?
*/
@Throws(KSVGParseException::class)
internal fun parseLength(value: String): CSSLength {
    checkState(value.isNotEmpty()) { "Invalid length value (empty string)" }

    var end = value.length
    var unit = CssUnit.px
    val lastChar = value[end - 1]

    if (lastChar == '%') {
        end -= 1
        unit = CssUnit.percent
    } else if (end > 2 && lastChar.isLetter() && value[end - 2].isLetter()) {
        end -= 2
        val unitStr = value.substring(end)
        try {
            unit = CssUnit.valueOf(unitStr.lowercase(Locale.US))
        } catch (_: IllegalArgumentException) {
            throw KSVGParseException("Invalid length unit specifier: $value")
        }
    }
    try {
        val scalar: Float = parseFloat(value, 0, end)
        return CSSLength(scalar, unit)
    } catch (e: NumberFormatException) {
        throw KSVGParseException("Invalid length value: $value", e)
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
        coords.add(CSSLength(scalar, unit))
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