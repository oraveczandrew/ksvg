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
import hu.oandras.ksvg.css.CSSFontFeatureSettings
import hu.oandras.ksvg.css.CSSFontVariationSettings
import hu.oandras.ksvg.css.CSSLength
import hu.oandras.ksvg.parser.FontSizeKeywords
import hu.oandras.ksvg.parser.FontWeightKeywords
import hu.oandras.ksvg.parser.FontWidthKeywords
import hu.oandras.ksvg.parser.TextScanner
import hu.oandras.ksvg.parser.parseLength

internal const val NORMAL = "normal"


private fun isSystemFont(value: String): Boolean {
    return value.equals("caption", ignoreCase = true) ||
            value.equals("icon", ignoreCase = true) ||
            value.equals("menu", ignoreCase = true) ||
            value.equals("message-box", ignoreCase = true) ||
            value.equals("small-caption", ignoreCase = true) ||
            value.equals("status-bar", ignoreCase = true)
}

// [ [ <'font-style'> || <'font-variant'> || <'font-weight'> ]? <'font-size'> [ / <'line-height'> ]? <'font-family'> ] | caption | icon | menu | message-box | small-caption | status-bar | inherit
internal fun parseFont(builder: Style.Builder, value: String) {
    var fontWeight: Float = Float.NaN
    var fontStyle: FontStyle? = null
    var fontWidth: Float = Float.NaN
    var fontVariantSmallCaps: Boolean? = null

    // Start by checking for the fixed size standard system font names (which we don't support)
    if (isSystemFont(value)) return

    // First part: style/variant/weight (opt - one or more)
    val scan = TextScanner(value)
    var item: String?
    while (true) {
        item = scan.nextToken('/')
        scan.skipWhitespace()
        if (item == null) return
        if (!fontWeight.isNaN() && fontStyle != null) break
        if (item.equals(NORMAL, ignoreCase = true)) {
            // indeterminate right now which of these this refers to
            continue
        }
        if (fontWeight.isNaN()) {
            val fw = FontWeightKeywords.get(item)
            if (!fw.isNaN()) {
                fontWeight = fw
                continue
            }
        }
        if (fontStyle == null) {
            fontStyle = parseFontStyle(item)
            if (fontStyle != null) continue
        }
        // Must be a font-variant keyword?
        if (fontVariantSmallCaps == null && item.equals(CSSFontFeatureSettings.FONT_VARIANT_SMALL_CAPS, ignoreCase = true)) {
            fontVariantSmallCaps = true
            continue
        }
        if (fontWidth.isNaN()) {
            val fw = FontWidthKeywords.get(item)
            if (!fw.isNaN()) {
                fontWidth = fw
                continue
            }
        }
        // Not any of these. Break and try next section
        break
    }

    // Second part: font size (reqd) and line-height (opt)
    val fontSize: CSSLength? = parseFontSize(item)

    // Check for line-height (which we don't support)
    if (scan.consume('/')) {
        scan.skipWhitespace()
        item = scan.nextToken()
        if (item != null) {
            try {
                parseLength(item)
            } catch (_: KSVGParseException) {
                return
            }
        }
        scan.skipWhitespace()
    }


    // Third part: font family
    builder.fontFamily = parseFontFamily(scan.restOfText())

    builder.fontSize = fontSize
    builder.fontWeight = if (fontWeight.isNaN()) {
        Style.FONT_WEIGHT_NORMAL
    } else {
        fontWeight
    }
    builder.fontStyle = fontStyle ?: FontStyle.normal
    builder.fontWidth = if (fontWidth.isNaN()) {
        Style.FONT_WIDTH_NORMAL
    } else {
        fontWidth
    }
    builder.fontKerning = FontKerning.auto
    builder.fontVariantLigatures = CSSFontFeatureSettings.LIGATURES_NORMAL
    builder.fontVariantPosition = CSSFontFeatureSettings.POSITION_ALL_OFF
    builder.fontVariantCaps = CSSFontFeatureSettings.CAPS_ALL_OFF
    if (fontVariantSmallCaps == true) {
        builder.fontVariantCaps = CSSFontFeatureSettings.CAPS_SMALL_CAPS
    }
    builder.fontVariantNumeric = CSSFontFeatureSettings.NUMERIC_ALL_OFF
    builder.fontVariantEastAsian = CSSFontFeatureSettings.EAST_ASIAN_ALL_OFF
    builder.fontFeatureSettings = CSSFontFeatureSettings.FONT_FEATURE_SETTINGS_NORMAL
    builder.fontVariationSettings = CSSFontVariationSettings.EMPTY

    builder.addSpecifiedFlag(
        Style.SPECIFIED_FONT_FAMILY or Style.SPECIFIED_FONT_SIZE or Style.SPECIFIED_FONT_WEIGHT or Style.SPECIFIED_FONT_STYLE or Style.SPECIFIED_FONT_WIDTH or
                Style.SPECIFIED_FONT_KERNING or Style.SPECIFIED_FONT_VARIANT_LIGATURES or Style.SPECIFIED_FONT_VARIANT_POSITION or Style.SPECIFIED_FONT_VARIANT_CAPS or
                Style.SPECIFIED_FONT_VARIANT_NUMERIC or Style.SPECIFIED_FONT_VARIANT_EAST_ASIAN or Style.SPECIFIED_FONT_FEATURE_SETTINGS or Style.SPECIFIED_FONT_VARIATION_SETTINGS
    )
}

// Parse a font family list
internal fun parseFontFamily(value: String?): List<String>? {
    if (value == null) return null

    var fonts: MutableList<String>? = null
    val scan = TextScanner(value)
    while (true) {
        val item = scan.nextQuotedString()
            ?: scan.nextTokenWithWhitespace(',')
            ?: break
        if (fonts == null) {
            fonts = ArrayList()
        }
        fonts.add(item)
        scan.skipCommaWhitespace()
        if (scan.empty()) break
    }
    return fonts
}

// Parse a font size keyword or numerical value
internal fun parseFontSize(value: String): CSSLength? {
    return try {
        FontSizeKeywords.get(value) ?: parseLength(value)
    } catch (_: KSVGParseException) {
        null
    }
}

// Parse a font weight keyword or numerical value
internal fun parseFontWeight(value: String): Float {
    val result = FontWeightKeywords.get(value)
    if (!result.isNaN()) {
        return result
    }
    // Check for a number
    val scan = TextScanner(value)
    val num = scan.nextFloat()
    scan.skipWhitespace()
    if (!scan.empty()) {
        return Float.NaN
    } else if (num < Style.FONT_WEIGHT_MIN || num > Style.FONT_WEIGHT_MAX) {
        return Float.NaN // Invalid
    }
    return num
}

// Parse a font width/stretch keyword or numerical value
internal fun parseFontWidth(value: String): Float {
    val result = FontWidthKeywords.get(value)
    if (!result.isNaN()) {
        return result
    }
    // Check for a percentage value
    val scan = TextScanner(value)
    val num = scan.nextFloat()
    if (!scan.consume('%')) return Float.NaN
    scan.skipWhitespace()
    if (!scan.empty()) return Float.NaN
    if (num < Style.FONT_WIDTH_MIN) return Float.NaN // Invalid
    return num
}
