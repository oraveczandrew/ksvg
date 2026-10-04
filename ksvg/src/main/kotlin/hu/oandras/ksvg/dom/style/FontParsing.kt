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
import hu.oandras.ksvg.utils.equalsWindow
import hu.oandras.ksvg.utils.skipLeading
import hu.oandras.ksvg.utils.skipTrailing

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

    // First part: style/variant/weight (opt - one or more).
    // Windowed dispatch: each token is classified on its `[start, end)` window
    // with no token substring. Both loop exits consume exactly one token (the
    // size candidate) and record its window for `parseFontSize` below.
    val scan = TextScanner(value)
    var sizeStart = 0
    var sizeEnd = 0
    while (true) {
        val tokenStart = scan.getPosition()
        val isSize = scan.consumeNextToken('/', false) { text, s, e ->
            if (!fontWeight.isNaN() && fontStyle != null) return@consumeNextToken true
            if (text.equalsWindow(s, e, NORMAL, ignoreCase = true)) {
                // indeterminate right now which of these this refers to
                return@consumeNextToken false
            }
            if (fontWeight.isNaN()) {
                val fw = FontWeightKeywords.get(text, s, e)
                if (!fw.isNaN()) {
                    fontWeight = fw
                    return@consumeNextToken false
                }
            }
            if (fontStyle == null) {
                val style = parseFontStyle(text, s, e)
                if (style != null) {
                    fontStyle = style
                    return@consumeNextToken false
                }
            }
            // Must be a font-variant keyword?
            if (fontVariantSmallCaps == null &&
                text.equalsWindow(s, e, CSSFontFeatureSettings.FONT_VARIANT_SMALL_CAPS, ignoreCase = true)
            ) {
                fontVariantSmallCaps = true
                return@consumeNextToken false
            }
            if (fontWidth.isNaN()) {
                val fw = FontWidthKeywords.get(text, s, e)
                if (!fw.isNaN()) {
                    fontWidth = fw
                    return@consumeNextToken false
                }
            }
            // Not any of these. Break and try next section
            true
        } ?: return
        val tokenEnd = scan.getPosition()
        scan.skipWhitespace()
        if (isSize) {
            sizeStart = tokenStart
            sizeEnd = tokenEnd
            break
        }
    }

    // Second part: font size (required) and line-height (optional)
    val fontSize: CSSLength? = parseFontSize(value, sizeStart, sizeEnd)

    // Check for line-height (which we don't support)
    if (scan.consume('/')) {
        scan.skipWhitespace()
        val lineHeightOk = scan.consumeNextToken(' ', false) { text, s, e ->
            try {
                parseLength(text, s, e)
                true
            } catch (_: KSVGParseException) {
                false
            }
        }
        if (lineHeightOk == false) return
        scan.skipWhitespace()
    }


    // Third part: font family (the scanner remainder, no tail copy)
    builder.fontFamily = scan.consumeRestOfText { text, s, e -> parseFontFamily(text, s, e) }

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
    return parseFontFamily(value, 0, value.length)
}

// Windowed twin: the scanner covers `[start, end)` with no tail copy, quoted
// items keep their single content copy, and unquoted items are trimmed on the
// window, so only stored family names allocate.
internal fun parseFontFamily(text: String, start: Int, end: Int): List<String>? {
    var fonts: MutableList<String>? = null
    val scan = TextScanner(text, start, end)
    while (true) {
        val quoted = scan.nextQuotedString()
        if (quoted != null) {
            // Quoted content keeps interior whitespace, but surrounding
            // whitespace is insignificant (matches the old trim()).
            val qs = skipLeading(quoted, 0, quoted.length)
            val qe = skipTrailing(quoted, qs, quoted.length)
            if (qs < qe) {
                if (fonts == null) {
                    fonts = ArrayList()
                }
                fonts.add(quoted.substring(qs, qe))
            }
        } else {
            // Blank-but-present tokens (`"Arial, ,serif"`) are skipped like the
            // old trim-then-isNotEmpty check; only a missing token breaks. The
            // shared empty string allocates nothing.
            val item = scan.consumeNextToken(',', true) { t, s, e ->
                val ts = skipLeading(t, s, e)
                val te = skipTrailing(t, ts, e)
                if (ts >= te) "" else t.substring(ts, te)
            } ?: break
            if (item.isNotEmpty()) {
                if (fonts == null) {
                    fonts = ArrayList()
                }
                fonts.add(item)
            }
        }
        scan.skipCommaWhitespace()
        if (scan.empty()) break
    }
    return fonts
}

// Parse a font size keyword or numerical value
internal fun parseFontSize(value: String): CSSLength? = parseFontSize(value, 0, value.length)

// Windowed twin: no token substring for scanner-driven callers.
internal fun parseFontSize(text: String, start: Int, end: Int): CSSLength? {
    return try {
        FontSizeKeywords.get(text, start, end) ?: parseLength(text, start, end)
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
