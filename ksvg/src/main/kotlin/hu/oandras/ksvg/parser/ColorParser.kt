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
import hu.oandras.ksvg.dom.COLOR_BLACK
import hu.oandras.ksvg.dom.style.ColorValue
import hu.oandras.ksvg.utils.pack3Hex
import hu.oandras.ksvg.utils.pack4Hex
import hu.oandras.ksvg.utils.pack8Hex
import hu.oandras.ksvg.utils.packHsla
import hu.oandras.ksvg.utils.packRgba
import java.util.Locale

internal object ColorParser {
    /*
     * Parse a color definition.
     */
    @JvmStatic
    fun parseColor(value: String): ColorValue = parseColor(value, 0, value.length)

    @JvmStatic
    fun parseColor(input: String, start: Int, end: Int): ColorValue {
        var s = start.coerceIn(0, input.length)
        var e = end.coerceIn(s, input.length)
        while (s < e && input[s] <= ' ') s++
        while (e > s && input[e - 1] <= ' ') e--
        require(s < e) { "Color string is empty" }

        if (input[s] == '#') {
            val ip = IntegerParser.parseHex(input, s + 1, e)
            val endPos = ip.endPos
            if (ip.isInvalid()) throw KSVGParseException("Invalid hex color: ${input.substring(s, e)}")

            return when (endPos - s) {
                4 -> ColorValue.of(pack3Hex(ip.value))
                5 -> ColorValue.of(pack4Hex(ip.value))
                7 -> ColorValue.of(COLOR_BLACK or ip.value)
                9 -> ColorValue.of(pack8Hex(ip.value))
                else -> {
                    throw KSVGParseException("Invalid hex color length: ${input.substring(s, e)}")
                }
            }
        }

        // Parse a rgb() or rgba() color.
        // In CSS Color 4, these are synonyms, and the alpha parameter is optional in both cases.
        // Prefix checks are case-insensitive region matches, so no lowercase copy is allocated.
        val remaining = e - s
        val isRGBA = remaining >= 5 && input.regionMatches(s, "rgba(", 0, 5, ignoreCase = true)
        if (isRGBA || (remaining >= 4 && input.regionMatches(s, "rgb(", 0, 4, ignoreCase = true))) {
            val scan = TextScanner(input, s + if (isRGBA) 5 else 4, e)
            scan.skipWhitespace()

            var red = scan.nextFloat()
            require(!red.isNaN()) { "Invalid red component in rgb color: ${input.substring(s, e)}" }
            if (scan.consume('%')) {
                red = red * 256 / 100
            }

            // If there is a comma, then it is the "legacy" format: rgb(r, g, b, a?).
            // Otherwise, we assume it is the new format: rgb[a?](r g b / a?).
            val isLegacyCSSColor3 = scan.skipCommaWhitespace()

            var green = scan.nextFloat()
            require(!green.isNaN()) { "Invalid green component in rgb color: ${input.substring(s, e)}" }
            if (scan.consume('%')) {
                green = green * 256 / 100
            }

            if (isLegacyCSSColor3) {
                require(scan.skipCommaWhitespace()) { "Missing comma in legacy rgb color: ${input.substring(s, e)}" }
            } else {
                scan.skipWhitespace()
            }

            var blue = scan.nextFloat()
            require(!blue.isNaN()) { "Invalid blue component in rgb color: ${input.substring(s, e)}" }
            if (scan.consume('%')) {
                blue = blue * 256 / 100
            }

            // Now look for optional alpha
            var alpha = Float.NaN
            if (isLegacyCSSColor3) {
                if (scan.skipCommaWhitespace()) {
                    alpha = scan.nextFloat()
                    require(!alpha.isNaN()) { "Invalid alpha component in legacy rgb color: ${input.substring(s, e)}" }
                    if (scan.consume('%')) {
                        alpha /= 100f
                    }
                }
            } else {
                scan.skipWhitespace()
                if (scan.consume('/')) {
                    scan.skipWhitespace()
                    alpha = scan.nextFloat()
                    require(!alpha.isNaN()) { "Invalid alpha component in rgb color: ${input.substring(s, e)}" }
                    if (scan.consume('%')) {
                        alpha /= 100f
                    }
                }
            }
            scan.skipWhitespace()

            require(scan.consume(')')) { "Missing closing bracket in rgb color: ${input.substring(s, e)}" }
            return ColorValue.of(packRgba(red, green, blue, alpha))
        } else {
            // Parse a hsl() or hsla() color.
            // In CSS Color 4, these are synonyms, and the alpha parameter is optional in both cases.
            val isHSLA = remaining >= 5 && input.regionMatches(s, "hsla(", 0, 5, ignoreCase = true)
            if (isHSLA || (remaining >= 4 && input.regionMatches(s, "hsl(", 0, 4, ignoreCase = true))) {
                val scan = TextScanner(input, s + if (isHSLA) 5 else 4, e)
                scan.skipWhitespace()

                val hue = scan.nextFloat()
                require(!hue.isNaN()) { "Invalid hue component in hsl color: ${input.substring(s, e)}" }
                scan.consumeIgnoreCase("deg") // Optional units

                // If there is a comma, then it is the "legacy" format: rgb(r, g, b, a?).
                // Otherwise, we assume it is the new format: rgb[a?](r g b / a?).
                val isLegacyCSSColor3 = scan.skipCommaWhitespace()

                val saturation = scan.nextFloat()
                require(!saturation.isNaN()) { "Invalid saturation component in hsl color: ${input.substring(s, e)}" }
                require(scan.consume('%')) { "Missing % in saturation component of hsl color: ${input.substring(s, e)}" }

                if (isLegacyCSSColor3) {
                    require(scan.skipCommaWhitespace()) { "Missing comma in legacy hsl color: ${input.substring(s, e)}" }
                } else {
                    scan.skipWhitespace()
                }

                val lightness = scan.nextFloat()
                require(!lightness.isNaN()) { "Invalid lightness component in hsl color: ${input.substring(s, e)}" }
                require(scan.consume('%')) { "Missing % in lightness component of hsl color: ${input.substring(s, e)}" }

                // Now look for optional alpha
                var alpha = Float.NaN
                if (isLegacyCSSColor3) {
                    if (scan.skipCommaWhitespace()) {
                        alpha = scan.nextFloat()
                        require(!alpha.isNaN()) { "Invalid alpha component in legacy hsl color: ${input.substring(s, e)}" }
                        if (scan.consume('%')) {
                            alpha /= 100f
                        }
                    }
                } else {
                    scan.skipWhitespace()
                    if (scan.consume('/')) {
                        scan.skipWhitespace()
                        alpha = scan.nextFloat()
                        require(!alpha.isNaN()) { "Invalid alpha component in hsl color: ${input.substring(s, e)}" }
                        if (scan.consume('%')) {
                            alpha /= 100f
                        }
                    }
                }
                scan.skipWhitespace()
                require(scan.consume(')')) { "Missing closing bracket in hsl color: ${input.substring(s, e)}" }
                return ColorValue.of(packHsla(hue, saturation, lightness, alpha))
            }
        }

        // Must be a color keyword
        return if (s == 0 && e == input.length) parseColorKeyword(input)
        else parseColorKeyword(input.substring(s, e))
    }

    private fun parseColorKeyword(value: String): ColorValue {
        // Fast path: already-lowercase names (the common case) need no copy.
        // Only BLACK-or-unknown falls through to a single lowercase attempt.
        val direct = ColorKeywords.get(value)
        if (direct != COLOR_BLACK || value == "black") return ColorValue.of(direct)
        val lower = value.lowercase(Locale.US)
        val color = ColorKeywords.get(lower)
        checkState(color != COLOR_BLACK || lower == "black") { "Invalid color keyword: $value" }
        return ColorValue.of(color)
    }
}
