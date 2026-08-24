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

package hu.oandras.ksvg.render

import android.graphics.Paint
import hu.oandras.ksvg.compat.setWordSpacingCompat
import hu.oandras.ksvg.compat.supportsWordSpacing
import hu.oandras.ksvg.css.CSSFontVariationSettings
import hu.oandras.ksvg.dom.COLOR_BLACK
import hu.oandras.ksvg.dom.style.ColorValue
import hu.oandras.ksvg.dom.style.ContextFill
import hu.oandras.ksvg.dom.style.ContextStroke
import hu.oandras.ksvg.dom.style.CurrentColor
import hu.oandras.ksvg.dom.style.FontStyle
import hu.oandras.ksvg.dom.style.LineCap
import hu.oandras.ksvg.dom.style.LineJoin
import hu.oandras.ksvg.dom.style.Style
import hu.oandras.ksvg.dom.style.SvgPaint
import hu.oandras.ksvg.utils.colorWithOpacity
import hu.oandras.ksvg.utils.forEachElement

context(renderContext: RenderContext)
internal fun updateStyle(
    state: RendererState,
    builder: Style.Builder,
    sourceStyle: Style,
    currentFontSize: Float,
    resolvedFontWeight: Float
) {
    if (sourceStyle.isSpecified(Style.SPECIFIED_COLOR)) {
        builder.color = sourceStyle.color
    }

    if (sourceStyle.isSpecified(Style.SPECIFIED_OPACITY)) {
        builder.opacity = sourceStyle.opacity
    }

    if (sourceStyle.isSpecified(Style.SPECIFIED_FILL)) {
        val fill = sourceStyle.fill
        builder.fill = fill
        state.hasFill = fill != null && fill != ColorValue.TRANSPARENT
    }

    if (sourceStyle.isSpecified(Style.SPECIFIED_FILL_OPACITY)) {
        builder.fillOpacity = sourceStyle.fillOpacity
    }

    if (sourceStyle.isSpecifiedAny(Style.SPECIFIED_FILL or Style.SPECIFIED_FILL_OPACITY or Style.SPECIFIED_COLOR or Style.SPECIFIED_OPACITY)) {
        setFillPaintColor(state, builder, builder.fill)
    }

    if (sourceStyle.isSpecified(Style.SPECIFIED_FILL_RULE)) {
        builder.fillRule = sourceStyle.fillRule
    }

    if (sourceStyle.isSpecified(Style.SPECIFIED_STROKE)) {
        val stroke = sourceStyle.stroke
        builder.stroke = stroke
        state.hasStroke = stroke != null && stroke != ColorValue.TRANSPARENT
    }

    if (sourceStyle.isSpecified(Style.SPECIFIED_STROKE_OPACITY)) {
        builder.strokeOpacity = sourceStyle.strokeOpacity
    }

    if (sourceStyle.isSpecifiedAny(Style.SPECIFIED_STROKE or Style.SPECIFIED_STROKE_OPACITY or Style.SPECIFIED_COLOR or Style.SPECIFIED_OPACITY)) {
        setStrokePaintColor(state, builder, builder.stroke)
    }

    if (sourceStyle.isSpecified(Style.SPECIFIED_VECTOR_EFFECT)) {
        builder.vectorEffect = sourceStyle.vectorEffect
    }

    if (sourceStyle.isSpecified(Style.SPECIFIED_STROKE_WIDTH)) {
        val strokeWidth = sourceStyle.strokeWidth!!
        builder.strokeWidth = strokeWidth
        if (!strokeWidth.isZero) {
            state.strokePaint.strokeWidth = strokeWidth.floatValueInContext()
        } else {
            state.hasStroke = false
        }
    }

    if (sourceStyle.isSpecified(Style.SPECIFIED_STROKE_LINECAP)) {
        val strokeLineCap = sourceStyle.strokeLineCap!!
        builder.strokeLineCap = strokeLineCap
        state.strokePaint.strokeCap = when (strokeLineCap) {
            LineCap.Butt -> Paint.Cap.BUTT
            LineCap.Round -> Paint.Cap.ROUND
            LineCap.Square -> Paint.Cap.SQUARE
        }
    }

    if (sourceStyle.isSpecified(Style.SPECIFIED_STROKE_LINEJOIN)) {
        val strokeLineJoin = sourceStyle.strokeLineJoin!!
        builder.strokeLineJoin = strokeLineJoin
        state.strokePaint.strokeJoin = when (strokeLineJoin) {
            LineJoin.Miter -> Paint.Join.MITER
            LineJoin.Round -> Paint.Join.ROUND
            LineJoin.Bevel -> Paint.Join.BEVEL
        }
    }

    if (sourceStyle.isSpecified(Style.SPECIFIED_STROKE_MITERLIMIT)) {
        val strokeMiterLimit = sourceStyle.strokeMiterLimit
        builder.strokeMiterLimit = strokeMiterLimit
        state.strokePaint.strokeMiter = strokeMiterLimit
    }

    var strokeDashArrayChanged = false
    if (sourceStyle.isSpecified(Style.SPECIFIED_STROKE_DASHARRAY)) {
        strokeDashArrayChanged = !builder.strokeDashArray.contentEquals(sourceStyle.strokeDashArray) ||
                !builder.strokeDashArrayResolved.contentEquals(sourceStyle.strokeDashArrayResolved)
        builder.strokeDashArray = sourceStyle.strokeDashArray
        builder.strokeDashArrayResolved = sourceStyle.strokeDashArrayResolved
    }

    if (sourceStyle.isSpecified(Style.SPECIFIED_STROKE_DASHOFFSET)) {
        strokeDashArrayChanged = strokeDashArrayChanged ||
                builder.strokeDashOffset != sourceStyle.strokeDashOffset ||
                builder.strokeDashOffsetResolved != sourceStyle.strokeDashOffsetResolved
        builder.strokeDashOffset = sourceStyle.strokeDashOffset
        builder.strokeDashOffsetResolved = sourceStyle.strokeDashOffsetResolved
    }

    if (strokeDashArrayChanged) {
        state.updateStrokeDash(
            builder.strokeDashArray,
            builder.strokeDashOffset,
            builder.strokeDashArrayResolved,
            builder.strokeDashOffsetResolved
        )
    }

    if (sourceStyle.isSpecified(Style.SPECIFIED_FONT_SIZE)) {
        val fontSize = sourceStyle.fontSize!!
        builder.fontSize = fontSize
        state.fillPaint.textSize = fontSize.floatValueInContext(currentFontSize)
        state.strokePaint.textSize = fontSize.floatValueInContext(currentFontSize)
    }

    if (sourceStyle.isSpecified(Style.SPECIFIED_FONT_FAMILY)) {
        builder.fontFamily = sourceStyle.fontFamily
    }

    if (sourceStyle.isSpecified(Style.SPECIFIED_FONT_WEIGHT)) {
        builder.fontWeight = resolvedFontWeight
        state.getFontVariationSetBuilder().addSetting(CSSFontVariationSettings.VARIATION_WEIGHT, resolvedFontWeight)
    }

    if (sourceStyle.isSpecified(Style.SPECIFIED_FONT_STYLE)) {
        val fontStyle = sourceStyle.fontStyle!!
        builder.fontStyle = fontStyle
        state.getFontVariationSetBuilder().apply {
            if (fontStyle == FontStyle.italic) {
                addSetting(CSSFontVariationSettings.VARIATION_ITALIC, CSSFontVariationSettings.VARIATION_ITALIC_VALUE_ON)
            } else if (fontStyle == FontStyle.oblique) {
                addSetting(CSSFontVariationSettings.VARIATION_SLANT, CSSFontVariationSettings.VARIATION_OBLIQUE_VALUE_ON)
            }
        }
    }

    if (sourceStyle.isSpecified(Style.SPECIFIED_FONT_WIDTH)) {
        val fontWidth = sourceStyle.fontWidth
        builder.fontWidth = fontWidth
        state.getFontVariationSetBuilder().addSetting(CSSFontVariationSettings.VARIATION_WIDTH, fontWidth)
    }

    if (sourceStyle.isSpecified(Style.SPECIFIED_TEXT_DECORATION)) {
        val textDecoration = sourceStyle.textDecoration!!
        builder.textDecoration = textDecoration
        // We handle decorations manually in TextRenderer to support combinations and overline
        state.fillPaint.isStrikeThruText = false
        state.fillPaint.isUnderlineText = false
        state.strokePaint.isStrikeThruText = false
        state.strokePaint.isUnderlineText = false
    }

    if (sourceStyle.isSpecified(Style.SPECIFIED_DIRECTION)) {
        builder.direction = sourceStyle.direction
    }

    if (sourceStyle.isSpecified(Style.SPECIFIED_TEXT_ANCHOR)) {
        builder.textAnchor = sourceStyle.textAnchor
    }

    if (sourceStyle.isSpecified(Style.SPECIFIED_DOMINANT_BASELINE)) {
        builder.dominantBaseline = sourceStyle.dominantBaseline
    }

    if (sourceStyle.isSpecified(Style.SPECIFIED_ALIGNMENT_BASELINE)) {
        builder.alignmentBaseline = sourceStyle.alignmentBaseline
    }

    if (sourceStyle.isSpecified(Style.SPECIFIED_BASELINE_SHIFT)) {
        builder.baselineShift = sourceStyle.baselineShift
    }

    if (sourceStyle.isSpecified(Style.SPECIFIED_TEXT_TRANSFORM)) {
        builder.textTransform = sourceStyle.textTransform
    }

    if (sourceStyle.isSpecified(Style.SPECIFIED_OVERFLOW)) {
        builder.overflow = sourceStyle.overflow
    }

    if (sourceStyle.isSpecified(Style.SPECIFIED_MARKER_START)) {
        builder.markerStart = sourceStyle.markerStart
    }

    if (sourceStyle.isSpecified(Style.SPECIFIED_MARKER_MID)) {
        builder.markerMid = sourceStyle.markerMid
    }

    if (sourceStyle.isSpecified(Style.SPECIFIED_MARKER_END)) {
        builder.markerEnd = sourceStyle.markerEnd
    }

    if (sourceStyle.isSpecified(Style.SPECIFIED_DISPLAY)) {
        builder.display = sourceStyle.display
    }

    if (sourceStyle.isSpecified(Style.SPECIFIED_VISIBILITY)) {
        builder.visibility = sourceStyle.visibility
    }

    if (sourceStyle.isSpecified(Style.SPECIFIED_CLIP)) {
        builder.clip = sourceStyle.clip
    }

    if (sourceStyle.isSpecified(Style.SPECIFIED_CLIP_PATH)) {
        builder.clipPath = sourceStyle.clipPath
    }

    if (sourceStyle.isSpecified(Style.SPECIFIED_CLIP_RULE)) {
        builder.clipRule = sourceStyle.clipRule
    }

    if (sourceStyle.isSpecified(Style.SPECIFIED_MASK)) {
        builder.mask = sourceStyle.mask
    }

    if (sourceStyle.isSpecified(Style.SPECIFIED_MASK_TYPE)) {
        builder.maskType = sourceStyle.maskType
    }

    if (sourceStyle.isSpecified(Style.SPECIFIED_STOP_COLOR)) {
        builder.stopColor = sourceStyle.stopColor
    }

    if (sourceStyle.isSpecified(Style.SPECIFIED_STOP_OPACITY)) {
        builder.stopOpacity = sourceStyle.stopOpacity
    }

    if (sourceStyle.isSpecified(Style.SPECIFIED_VIEWPORT_FILL)) {
        builder.viewportFill = sourceStyle.viewportFill
    }

    if (sourceStyle.isSpecified(Style.SPECIFIED_VIEWPORT_FILL_OPACITY)) {
        builder.viewportFillOpacity = sourceStyle.viewportFillOpacity
    }

    if (sourceStyle.isSpecified(Style.SPECIFIED_IMAGE_RENDERING)) {
        builder.imageRendering = sourceStyle.imageRendering
    }

    if (sourceStyle.isSpecified(Style.SPECIFIED_ISOLATION)) {
        builder.isolation = sourceStyle.isolation
    }

    if (sourceStyle.isSpecified(Style.SPECIFIED_MIX_BLEND_MODE)) {
        builder.mixBlendMode = sourceStyle.mixBlendMode
    }

    if (sourceStyle.isSpecified(Style.SPECIFIED_FONT_KERNING)) {
        val fontKerning = sourceStyle.fontKerning
        builder.fontKerning = fontKerning
        state.getFontFeatureSetBuilder().applyKerning(fontKerning)
    }

    if (sourceStyle.isSpecified(Style.SPECIFIED_FONT_FEATURE_SETTINGS)) {
        val fontFeatureSettings = sourceStyle.fontFeatureSettings
        builder.fontFeatureSettings = fontFeatureSettings
        state.getFontFeatureSetBuilder().addSettings(fontFeatureSettings)
    }

    if (sourceStyle.isSpecified(Style.SPECIFIED_FONT_VARIANT_LIGATURES)) {
        val fontVariantLigatures = sourceStyle.fontVariantLigatures
        builder.fontVariantLigatures = fontVariantLigatures
        state.getFontFeatureSetBuilder().addSettings(fontVariantLigatures)
    }

    if (sourceStyle.isSpecified(Style.SPECIFIED_FONT_VARIANT_POSITION)) {
        val fontVariantPosition = sourceStyle.fontVariantPosition
        builder.fontVariantPosition = fontVariantPosition
        state.getFontFeatureSetBuilder().addSettings(fontVariantPosition)
    }

    if (sourceStyle.isSpecified(Style.SPECIFIED_FONT_VARIANT_CAPS)) {
        val fontVariantCaps = sourceStyle.fontVariantCaps
        builder.fontVariantCaps = fontVariantCaps
        state.getFontFeatureSetBuilder().addSettings(fontVariantCaps)
    }

    if (sourceStyle.isSpecified(Style.SPECIFIED_FONT_VARIANT_NUMERIC)) {
        val fontVariantNumeric = sourceStyle.fontVariantNumeric
        builder.fontVariantNumeric = fontVariantNumeric
        state.getFontFeatureSetBuilder().addSettings(fontVariantNumeric)
    }

    if (sourceStyle.isSpecified(Style.SPECIFIED_FONT_VARIANT_EAST_ASIAN)) {
        val fontVariantEastAsian = sourceStyle.fontVariantEastAsian
        builder.fontVariantEastAsian = fontVariantEastAsian
        state.getFontFeatureSetBuilder().addSettings(fontVariantEastAsian)
    }

    if (sourceStyle.isSpecified(Style.SPECIFIED_FONT_VARIATION_SETTINGS)) {
        val fontVariationSettings = sourceStyle.fontVariationSettings
        builder.fontVariationSettings = fontVariationSettings
        state.getFontVariationSetBuilder().addSettings(fontVariationSettings)
    }

    if (sourceStyle.isSpecified(Style.SPECIFIED_WRITING_MODE)) {
        builder.writingMode = sourceStyle.writingMode
    }

    if (sourceStyle.isSpecified(Style.SPECIFIED_GLYPH_ORIENTATION_VERTICAL)) {
        builder.glyphOrientationVertical = sourceStyle.glyphOrientationVertical
    }

    if (sourceStyle.isSpecified(Style.SPECIFIED_TEXT_ORIENTATION)) {
        builder.textOrientation = sourceStyle.textOrientation
    }

    if (sourceStyle.isSpecified(Style.SPECIFIED_LETTER_SPACING)) {
        val letterSpacing = sourceStyle.letterSpacing!!
        builder.letterSpacing = letterSpacing
        var spacing = letterSpacing.floatValueInContext()
        if (spacing > 0) {
            if (currentFontSize > 0) {
                spacing /= currentFontSize
            }
        }
        state.fillPaint.letterSpacing = spacing
        state.strokePaint.letterSpacing = spacing
    }

    if (supportsWordSpacing() && sourceStyle.isSpecified(Style.SPECIFIED_WORD_SPACING)) {
        val wordSpacing = sourceStyle.wordSpacing!!
        builder.wordSpacing = wordSpacing
        val spacing = wordSpacing.floatValueInContext()
        if (state.appliedWordSpacing != spacing) {
            state.fillPaint.setWordSpacingCompat(spacing)
            state.strokePaint.setWordSpacingCompat(spacing)
            state.appliedWordSpacing = spacing
        }
    }

    if (sourceStyle.isSpecified(Style.SPECIFIED_FILTER)) {
        builder.filter = sourceStyle.filter
    }

    if (sourceStyle.isSpecified(Style.SPECIFIED_FLOOD_COLOR)) {
        builder.floodColor = sourceStyle.floodColor
    }

    if (sourceStyle.isSpecified(Style.SPECIFIED_FLOOD_OPACITY)) {
        builder.floodOpacity = sourceStyle.floodOpacity
    }

    if (sourceStyle.isSpecified2(Style.SPECIFIED_PAINT_ORDER)) {
        builder.paintOrder = sourceStyle.paintOrder
    }

    builder.addSpecifiedFlag(sourceStyle.specifiedFlags and sourceStyle.suppressedFlags.inv())
    builder.addSpecifiedFlag2(sourceStyle.specifiedFlags2)
}

/**
 * Computes which properties' WINNING declaration (highest-priority tier that
 * declares them) is a CSS-wide keyword (inherit/unset/initial/revert). Tiers in
 * ascending priority: presentation attributes < normal CSS rules < normal inline
 * style < '!important' CSS rules < '!important' inline style. The returned mask
 * holds concrete SPECIFIED_* bits.
 *
 * Implemented without local closures: capturing lambdas/functions would
 * allocate on every call.
 */
internal fun resolveCssWideKeywordMask(base: Style?, rules: List<Style>, inlineStyle: Style?): Long {
    var keywordWinners = foldCssWideKeyword(0L, base)
    rules.forEachElement { style ->
        keywordWinners = foldCssWideKeyword(keywordWinners, style)
    }
    return foldCssWideKeyword(keywordWinners, inlineStyle)
}

/** Folds one source style into the running keyword-winner mask. */
private fun foldCssWideKeyword(keywordWinners: Long, s: Style?): Long {
    if (s == null) return keywordWinners
    val declared = s.specifiedFlags or s.specifiedFlags2 or s.cssWideKeywordFlags or s.importantFlags
    val imp = s.importantFlags
    val cssWide = s.cssWideKeywordFlags
    // Normal tier.
    var result = (keywordWinners and (declared and imp.inv()).inv()) or (cssWide and imp.inv())
    // Important tier beats every normal declaration, but only declares the
    // properties actually marked '!important'.
    result = (result and imp.inv()) or (cssWide and imp)
    return result
}

internal fun reapplyDynamicPaints(state: RendererState) {
    val style = state.style
    val fill = style.fill
    if (fill is ContextStroke || fill is ContextFill || fill is CurrentColor) {
        setPaintColor(
            state = state,
            paint = fill,
            color = style.color,
            paintOpacity = if (style.fillOpacity.isNaN()) 1f else style.fillOpacity,
            targetPaint = state.fillPaint
        )
    }
    val stroke = style.stroke
    if (stroke is ContextStroke || stroke is ContextFill || stroke is CurrentColor) {
        setPaintColor(
            state = state,
            paint = stroke,
            color = style.color,
            paintOpacity = if (style.strokeOpacity.isNaN()) 1f else style.strokeOpacity,
            targetPaint = state.strokePaint
        )
    }
}

internal fun setFillPaintColor(state: RendererState, builder: Style.Builder, paint: SvgPaint?) {
    setPaintColor(
        state = state,
        color = builder.color,
        paint = paint,
        paintOpacity = if (builder.fillOpacity.isNaN()) 1f else builder.fillOpacity,
        targetPaint = state.fillPaint
    )
}

internal fun setStrokePaintColor(state: RendererState, builder: Style.Builder, paint: SvgPaint?) {
    setPaintColor(
        state = state,
        color = builder.color,
        paint = paint,
        paintOpacity = if (builder.strokeOpacity.isNaN()) 1f else builder.strokeOpacity,
        targetPaint = state.strokePaint
    )
}

private fun setPaintColor(
    state: RendererState,
    paint: SvgPaint?,
    color: ColorValue?,
    paintOpacity: Float,
    targetPaint: Paint
) {
    val col: Int = when (paint) {
        is ColorValue -> {
            paint.value
        }

        is CurrentColor -> {
            color?.value ?: COLOR_BLACK
        }

        is ContextStroke -> {
            when (val ctx = state.contextStroke) {
                is ColorValue -> ctx.value
                is CurrentColor -> color?.value ?: COLOR_BLACK
                else -> return
            }
        }

        is ContextFill -> {
            when (val ctx = state.contextFill) {
                is ColorValue -> ctx.value
                is CurrentColor -> color?.value ?: COLOR_BLACK
                else -> return
            }
        }

        else -> {
            return
        }
    }

    // Keep the explicit shader reset: mock-based tests record the assignment, and
    // gradients rely on it being cleared. Only the color write is change-guarded
    // (OEM ROMs like OnePlus allocate inside setters even for unchanged values).
    targetPaint.shader = null
    val newColor = col.colorWithOpacity(paintOpacity)
    if (targetPaint.color != newColor) {
        targetPaint.color = newColor
    }
}
