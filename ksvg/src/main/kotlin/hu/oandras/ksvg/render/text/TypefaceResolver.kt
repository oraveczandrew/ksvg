/*
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

package hu.oandras.ksvg.render.text

import android.graphics.Paint
import android.graphics.Typeface
import hu.oandras.ksvg.ExternalFileResolver
import hu.oandras.ksvg.css.CSSFontVariationSettings
import hu.oandras.ksvg.dom.style.FontStyle
import hu.oandras.ksvg.dom.style.Style
import hu.oandras.ksvg.render.RendererState
import hu.oandras.ksvg.render.pool.FloatArrayBucket

private const val DEFAULT_FONT_FAMILY = "serif"

internal fun measureText(text: String, paint: Paint, widths: FloatArrayBucket): Float {
    val buffer = widths.getWithSize(text.length)
    paint.getTextWidths(text, buffer)
    return buffer.sum()
}

internal fun RendererState.selectTypefaceAndFontStyling(
    externalFileResolver: ExternalFileResolver?
) {
    val style = this.style

    val fontWeight = style.fontWeight
    val fontStyle = style.fontStyle ?: FontStyle.normal

    val font: Typeface = resolveFontFromFontFamily(
        externalFileResolver = externalFileResolver,
        fontFamily = style.fontFamily,
        fontWidth = style.fontWidth,
        fontWeight = fontWeight,
        fontStyle = fontStyle,
    ) ?: checkGenericFont(
        fontName = DEFAULT_FONT_FAMILY,
        fontWeight = fontWeight,
        fontStyle = fontStyle
    )!!

    // Skip redundant writes: OEM ROMs (OnePlus PaintExtImpl) hook paint setters
    // and allocate on every call, even for unchanged values.
    if (appliedTypeface !== font) {
        fillPaint.typeface = font
        strokePaint.typeface = font
        appliedTypeface = font
    }

    // Just in case this is a variable font, let's also set the fontVariationSettings
    // In order to get the desired font weight, style and width.
    val fvsBuilder = getFontVariationSetBuilder()
    fvsBuilder.addSetting(
        CSSFontVariationSettings.VARIATION_WEIGHT,
        fontWeight
    )
    fvsBuilder.addSetting(
        CSSFontVariationSettings.VARIATION_WIDTH,
        style.fontWidth
    )
    // If italic has been specified, enable the 'ital' axis in case this is a
    // variable font and has one.
    if (fontStyle == FontStyle.italic && !font.isItalic) {
        fvsBuilder.addSetting(
            CSSFontVariationSettings.VARIATION_ITALIC,
            CSSFontVariationSettings.VARIATION_ITALIC_VALUE_ON
        )
    }
    // If oblique has been specified, enable the 'slnt' axis in case this is a
    // variable font and has one.
    if (fontStyle == FontStyle.oblique && !font.isItalic) {
        fvsBuilder.addSetting(
            CSSFontVariationSettings.VARIATION_SLANT,
            CSSFontVariationSettings.VARIATION_OBLIQUE_VALUE_ON
        )
    }

    // Apply the CSS font-variation-setting values if there are any
    fvsBuilder.addSettings(style.fontVariationSettings)
    
    val fontVariationSettings = fontVariationSet.toString()
    if (appliedFontVariationSettings != fontVariationSettings) {
        fillPaint.fontVariationSettings = fontVariationSettings
        strokePaint.fontVariationSettings = fontVariationSettings
        appliedFontVariationSettings = fontVariationSettings
    }

    val fontFeatureSettings = fontFeatureSet.toString()
    if (appliedFontFeatureSettings != fontFeatureSettings) {
        fillPaint.fontFeatureSettings = fontFeatureSettings
        strokePaint.fontFeatureSettings = fontFeatureSettings
        appliedFontFeatureSettings = fontFeatureSettings
    }
}

private fun resolveFontFromFontFamily(
    externalFileResolver: ExternalFileResolver?,
    fontFamily: List<String>?,
    fontWidth: Float?,
    fontWeight: Float,
    fontStyle: FontStyle
): Typeface? {
    if (fontFamily == null) return null

    for (i in fontFamily.indices) {
        val fontName = fontFamily[i]
        // Check if this font entry is a generic font specifier
        val font = checkGenericFont(
            fontName = fontName,
            fontWeight = fontWeight,
            fontStyle = fontStyle
        ) ?:
                // Otherwise, try loading the specified font
                externalFileResolver?.resolveFont(
                    fontFamily = fontName,
                    fontWeight = fontWeight,
                    fontStyle = fontStyle.toString(),
                    fontStretch = fontWidth!!
                )

        if (font != null) {
            return font
        }
    }

    return null
}

private fun checkGenericFont(
    fontName: String,
    fontWeight: Float,
    fontStyle: FontStyle
): Typeface? {
    val italic = fontStyle == FontStyle.italic

    val typefaceStyle: Int = if (fontWeight >= Style.FONT_WEIGHT_BOLD) {
        if (italic) {
            Typeface.BOLD_ITALIC
        } else {
            Typeface.BOLD
        }
    } else {
        if (italic) {
            Typeface.ITALIC
        } else {
            Typeface.NORMAL
        }
    }

    return when (fontName) {
        "serif" -> Typeface.create(Typeface.SERIF, typefaceStyle)
        "sans-serif",
        "cursive",
        "fantasy" -> Typeface.create(Typeface.SANS_SERIF, typefaceStyle)

        "monospace" -> Typeface.create(Typeface.MONOSPACE, typefaceStyle)
        else -> null
    }
}
