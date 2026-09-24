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
@file:OptIn(ExperimentalContracts::class)

package hu.oandras.ksvg.dom.style

import androidx.annotation.LongDef
import hu.oandras.ksvg.KSVGParseException
import hu.oandras.ksvg.css.CSSFontFeatureSettings
import hu.oandras.ksvg.css.CSSFontVariationSettings
import hu.oandras.ksvg.css.CSSLength
import hu.oandras.ksvg.css.CssUnit
import hu.oandras.ksvg.dom.core.SVGAttr
import hu.oandras.ksvg.dom.filter.ColorInterpolation
import hu.oandras.ksvg.dom.text.AlignmentBaseline
import hu.oandras.ksvg.dom.text.BaselineShift
import hu.oandras.ksvg.dom.text.DominantBaseline
import hu.oandras.ksvg.dom.text.TextAnchor
import hu.oandras.ksvg.dom.text.TextDecoration
import hu.oandras.ksvg.dom.text.TextDirection
import hu.oandras.ksvg.dom.text.TextOrientation
import hu.oandras.ksvg.dom.text.TextTransform
import hu.oandras.ksvg.dom.text.parseAlignmentBaseline
import hu.oandras.ksvg.dom.text.parseBaselineShift
import hu.oandras.ksvg.dom.text.parseDominantBaseline
import hu.oandras.ksvg.dom.text.parseTextAnchor
import hu.oandras.ksvg.dom.text.parseTextDecoration
import hu.oandras.ksvg.dom.text.parseTextDirection
import hu.oandras.ksvg.dom.text.parseTextTransform
import hu.oandras.ksvg.parser.ColorParser
import hu.oandras.ksvg.parser.parseFloat
import hu.oandras.ksvg.parser.parseLength
import hu.oandras.ksvg.parser.parseOpacity
import kotlin.contracts.ExperimentalContracts
import kotlin.contracts.contract

// Special attribute keywords
internal const val NONE: String = "none"

internal class Style internal constructor(
    @SpecifiedFlags
    @JvmField
    val specifiedFlags: Long,

    @SpecifiedFlags2
    @JvmField
    val specifiedFlags2: Long,

    // Third flag group: holds the SAME concrete SPECIFIED_* bit values, marking
    // properties whose winning declaration was a CSS-wide keyword (inherit/unset/
    // initial/revert). While a bit is set here, isSpecified() reports the property
    // as unspecified so the inherited (parent computed) value survives.
    @JvmField
    val cssWideKeywordFlags: Long,

    // Fourth flag group: same concrete SPECIFIED_* bit values, marking properties
    // whose winning declaration carried '!important' (author level).
    @JvmField
    val importantFlags: Long,

    @JvmField val fill: SvgPaint?,
    @JvmField
    @FillRule
    val fillRule: Int,
    @JvmField val fillOpacity: Float,

    @JvmField val stroke: SvgPaint?,
    @JvmField val strokeOpacity: Float,
    @JvmField val strokeWidth: CSSLength?,
    @JvmField
    @LineCap
    val strokeLineCap: Int,
    @JvmField
    @LineJoin
    val strokeLineJoin: Int,
    @JvmField val strokeMiterLimit: Float,
    @JvmField val strokeDashArray: Array<CSSLength>?,
    @JvmField val strokeDashOffset: CSSLength?,

    @JvmField val strokeDashArrayResolved: FloatArray?,
    @JvmField val strokeDashOffsetResolved: Float,

    @JvmField val opacity: Float,

    @JvmField val color: ColorValue?,

    @JvmField val fontFamily: List<String>?,
    @JvmField val fontSize: CSSLength?,
    @JvmField val fontWeight: Float,
    @JvmField val fontStyle: FontStyle?,
    @JvmField val fontWidth: Float,
    @JvmField val textDecoration: TextDecoration?,
    @JvmField val direction: TextDirection?,

    @JvmField val textAnchor: TextAnchor?,
    @JvmField val dominantBaseline: DominantBaseline?,
    @JvmField val alignmentBaseline: AlignmentBaseline?,
    @JvmField val baselineShift: BaselineShift?,
    @JvmField val textTransform: TextTransform?,
    @JvmField val overflow: Boolean?,
    @JvmField val clip: CSSClipRect?,

    @JvmField val markerStart: String?,
    @JvmField val markerMid: String?,
    @JvmField val markerEnd: String?,

    @JvmField val display: Boolean?,
    @JvmField val visibility: Boolean?,

    @JvmField val stopColor: SvgColor?,
    @JvmField val stopOpacity: Float,

    @JvmField val clipPath: String?,
    @JvmField
    @FillRule
    val clipRule: Int,

    @JvmField val mask: String?,

    @JvmField val maskType: MaskType?,

    @JvmField val filter: String?,

    @JvmField val floodColor: SvgColor?,

    @JvmField val floodOpacity: Float,

    @JvmField val lightingColor: SvgColor?,

    @JvmField val solidColor: SvgColor?,
    @JvmField val solidOpacity: Float,

    @JvmField val viewportFill: SvgPaint?,
    @JvmField val viewportFillOpacity: Float,

    @JvmField val vectorEffect: VectorEffect?,

    @JvmField val imageRendering: RenderQuality?,

    @JvmField val isolation: Isolation?,
    @JvmField val mixBlendMode: CSSBlendMode?,

    @JvmField val fontKerning: FontKerning?,

    @JvmField val fontVariantLigatures: CSSFontFeatureSettings?,

    @JvmField val fontVariantPosition: CSSFontFeatureSettings?,

    @JvmField val fontVariantCaps: CSSFontFeatureSettings?,

    @JvmField val fontVariantNumeric: CSSFontFeatureSettings?,

    @JvmField val fontVariantEastAsian: CSSFontFeatureSettings?,
    @JvmField val fontFeatureSettings: CSSFontFeatureSettings?,
    @JvmField val fontVariationSettings: CSSFontVariationSettings,
    @JvmField val writingMode: WritingMode?,
    @JvmField val glyphOrientationVertical: GlypOrientationVertical?,
    @JvmField val textOrientation: TextOrientation?,

    @JvmField
    @ColorInterpolation
    val colorInterpolationFilters: Int,
    @JvmField val letterSpacing: CSSLength?,
    @JvmField val wordSpacing: CSSLength?,

    // SVG2 paint-order as a packed 3-digit base-4 code (see PaintOrder).
    // `0` means unspecified ("normal": fill, stroke, markers).
    @JvmField
    @PaintOrder
    val paintOrder: Int,
) {

    /**
     * Transient, tree-build-time only: concrete SPECIFIED_* flags that lost to a
     * higher-priority CSS-wide keyword declaration. Set around each source style
     * during application and consulted by [isSpecified]/[isSpecified2]. Never part
     * of equality, copy or build; always reset back to zero after use.
     */
    @JvmField
    internal var suppressedFlags: Long = 0L

    constructor() : this(
        specifiedFlags = 0,
        specifiedFlags2 = 0,
        cssWideKeywordFlags = 0,
        importantFlags = 0,
        fill = null,
        fillRule = FillRule.UNSPECIFIED,
        fillOpacity = Float.NaN,
        stroke = null,
        strokeOpacity = Float.NaN,
        strokeWidth = null,
        strokeLineCap = LineCap.UNSPECIFIED,
        strokeLineJoin = LineJoin.UNSPECIFIED,
        strokeMiterLimit = 4f,
        strokeDashArray = null,
        strokeDashOffset = null,
        strokeDashArrayResolved = null,
        strokeDashOffsetResolved = Float.NaN,
        opacity = 1f,
        color = null,
        fontFamily = null,
        fontSize = null,
        fontWeight = Float.NaN,
        fontStyle = null,
        fontWidth = Float.NaN,
        textDecoration = null,
        direction = null,
        textAnchor = null,
        dominantBaseline = null,
        alignmentBaseline = null,
        baselineShift = null,
        textTransform = null,
        overflow = null,
        clip = null,
        markerStart = null,
        markerMid = null,
        markerEnd = null,
        display = null,
        visibility = null,
        stopColor = null,
        stopOpacity = Float.NaN,
        clipPath = null,
        clipRule = FillRule.UNSPECIFIED,
        mask = null,
        maskType = null,
        filter = null,
        floodColor = null,
        floodOpacity = Float.NaN,
        lightingColor = null,
        solidColor = null,
        solidOpacity = Float.NaN,
        viewportFill = null,
        viewportFillOpacity = Float.NaN,
        vectorEffect = null,
        imageRendering = null,
        isolation = null,
        mixBlendMode = null,
        fontKerning = null,
        fontVariantLigatures = null,
        fontVariantPosition = null,
        fontVariantCaps = null,
        fontVariantNumeric = null,
        fontVariantEastAsian = null,
        fontFeatureSettings = null,
        fontVariationSettings = CSSFontVariationSettings.EMPTY,
        writingMode = null,
        glyphOrientationVertical = null,
        textOrientation = null,
        colorInterpolationFilters = ColorInterpolation.UNSPECIFIED,
        letterSpacing = null,
        wordSpacing = null,
        paintOrder = PaintOrder.FILL_STROKE_MARKERS,
    )

    fun toBuilder(): Builder = Builder().apply { reset(this@Style) }

    internal class Builder {
        private lateinit var original: Style
        @JvmField
        var specifiedFlags: Long = 0
        @JvmField
        var specifiedFlags2: Long = 0
        @JvmField
        var cssWideKeywordFlags: Long = 0
        @JvmField
        var importantFlags: Long = 0
        // Last property flag touched by processStyleProperty for this declaration
        // (used by the CSS parser to attach '!important').
        @JvmField
        var lastTouchedFlag: Long = 0L
        @JvmField
        var fill: SvgPaint? = null
        @JvmField
        @FillRule
        var fillRule: Int = FillRule.UNSPECIFIED
        @JvmField
        var fillOpacity: Float = Float.NaN
        @JvmField
        var stroke: SvgPaint? = null
        @JvmField
        var strokeOpacity: Float = Float.NaN
        @JvmField
        var strokeWidth: CSSLength? = null
        @JvmField
        @LineCap
        var strokeLineCap: Int = LineCap.UNSPECIFIED
        @JvmField
        @LineJoin
        var strokeLineJoin: Int = LineJoin.UNSPECIFIED
        @JvmField
        var strokeMiterLimit: Float = 4f
        @JvmField
        var strokeDashArray: Array<CSSLength>? = null
        @JvmField
        var strokeDashOffset: CSSLength? = null
        @JvmField
        var strokeDashArrayResolved: FloatArray? = null
        @JvmField
        var strokeDashOffsetResolved: Float = Float.NaN
        @JvmField
        var opacity: Float = 1f
        @JvmField
        var color: ColorValue? = null
        @JvmField
        var fontFamily: List<String>? = null
        @JvmField
        var fontSize: CSSLength? = null
        @JvmField
        var fontWeight: Float = Float.NaN
        @JvmField
        var fontStyle: FontStyle? = null
        @JvmField
        var fontWidth: Float = Float.NaN
        @JvmField
        var textDecoration: TextDecoration? = null
        @JvmField
        var direction: TextDirection? = null
        @JvmField
        var textAnchor: TextAnchor? = null
        @JvmField
        var dominantBaseline: DominantBaseline? = null
        @JvmField
        var alignmentBaseline: AlignmentBaseline? = null
        @JvmField
        var baselineShift: BaselineShift? = null
        @JvmField
        var textTransform: TextTransform? = null
        @JvmField
        var overflow: Boolean? = null
        @JvmField
        var clip: CSSClipRect? = null
        @JvmField
        var markerStart: String? = null
        @JvmField
        var markerMid: String? = null
        @JvmField
        var markerEnd: String? = null
        @JvmField
        var display: Boolean? = null
        @JvmField
        var visibility: Boolean? = null
        @JvmField
        var stopColor: SvgColor? = null
        @JvmField
        var stopOpacity: Float = Float.NaN
        @JvmField
        var clipPath: String? = null
        @JvmField
        @FillRule
        var clipRule: Int = FillRule.UNSPECIFIED
        @JvmField
        var mask: String? = null
        @JvmField
        var maskType: MaskType? = null
        @JvmField
        var filter: String? = null
        @JvmField
        var floodColor: SvgColor? = null
        @JvmField
        var floodOpacity: Float = Float.NaN
        @JvmField
        var lightingColor: SvgColor? = null
        @JvmField
        var solidColor: SvgColor? = null
        @JvmField
        var solidOpacity: Float = Float.NaN
        @JvmField
        var viewportFill: SvgPaint? = null
        @JvmField
        var viewportFillOpacity: Float = Float.NaN
        @JvmField
        var vectorEffect: VectorEffect? = null
        @JvmField
        var imageRendering: RenderQuality? = null
        @JvmField
        var isolation: Isolation? = null
        @JvmField
        var mixBlendMode: CSSBlendMode? = null
        @JvmField
        var fontKerning: FontKerning? = null
        @JvmField
        var fontVariantLigatures: CSSFontFeatureSettings? = null
        @JvmField
        var fontVariantPosition: CSSFontFeatureSettings? = null
        @JvmField
        var fontVariantCaps: CSSFontFeatureSettings? = null
        @JvmField
        var fontVariantNumeric: CSSFontFeatureSettings? = null
        @JvmField
        var fontVariantEastAsian: CSSFontFeatureSettings? = null

        private var _fontFeatureSettings: CSSFontFeatureSettings? = null
        private var _fontFeatureSettingsBuilder: CSSFontFeatureSettings.Builder? = null

        var fontFeatureSettings: CSSFontFeatureSettings?
            get() = _fontFeatureSettingsBuilder?.build() ?: _fontFeatureSettings
            set(value) {
                _fontFeatureSettings = value
                _fontFeatureSettingsBuilder?.reset(value ?: CSSFontFeatureSettings.EMPTY)
            }

        fun getFontFeatureSettingsBuilder(): CSSFontFeatureSettings.Builder {
            var b = _fontFeatureSettingsBuilder
            if (b == null) {
                b = (_fontFeatureSettings ?: CSSFontFeatureSettings.EMPTY).toBuilder()
                _fontFeatureSettingsBuilder = b
            }
            return b
        }

        private var _fontVariationSettings: CSSFontVariationSettings = CSSFontVariationSettings.EMPTY
        private var _fontVariationSettingsBuilder: CSSFontVariationSettings.Builder? = null

        var fontVariationSettings: CSSFontVariationSettings
            get() = _fontVariationSettingsBuilder?.build() ?: _fontVariationSettings
            set(value) {
                _fontVariationSettings = value
                _fontVariationSettingsBuilder?.reset(value)
            }

        fun getFontVariationSettingsBuilder(): CSSFontVariationSettings.Builder {
            var b = _fontVariationSettingsBuilder
            if (b == null) {
                b = _fontVariationSettings.toBuilder()
                _fontVariationSettingsBuilder = b
            }
            return b
        }

        @JvmField
        var writingMode: WritingMode? = null
        @JvmField
        var glyphOrientationVertical: GlypOrientationVertical? = null
        @JvmField
        var textOrientation: TextOrientation? = null
        @JvmField
        @ColorInterpolation
        var colorInterpolationFilters: Int = ColorInterpolation.UNSPECIFIED
        @JvmField
        var letterSpacing: CSSLength? = null
        @JvmField
        var wordSpacing: CSSLength? = null
        @JvmField
        @PaintOrder
        var paintOrder: Int = 0

        fun addSpecifiedFlag(@SpecifiedFlags flag: Long) {
            specifiedFlags = specifiedFlags or flag
            // A concrete declaration beats an earlier CSS-wide keyword.
            cssWideKeywordFlags = cssWideKeywordFlags and flag.inv()
            lastTouchedFlag = flag
        }

        fun addSpecifiedFlag2(@SpecifiedFlags2 flag: Long) {
            specifiedFlags2 = specifiedFlags2 or flag
            cssWideKeywordFlags = cssWideKeywordFlags and flag.inv()
            lastTouchedFlag = flag
        }

        /**
         * Records that the winning declaration for this property was a CSS-wide
         * keyword (inherit/unset/initial/revert). While the flag is set,
         * [Style.isSpecified] reports the property as unspecified, so the style
         * application keeps the parent's computed value instead.
         */
        fun markCssWideKeyword(@SpecifiedFlags flag: Long) {
            cssWideKeywordFlags = cssWideKeywordFlags or flag
            lastTouchedFlag = flag
        }

        /** Records '!important' on the property last processed by this builder. */
        fun markImportant(@SpecifiedFlags flag: Long) {
            importantFlags = importantFlags or flag
        }

        fun resetNonInheritingProperties(isRootSVG: Boolean, cssWideOverrides: Long = 0L): Builder {
            // A property whose winning declaration was a CSS-wide keyword (either on
            // this element or inherited as such from the parent) must keep the value
            // inherited from the parent, so its default reset is skipped.
            val kw = cssWideKeywordFlags or cssWideOverrides
            if (kw and SPECIFIED_DISPLAY == 0L) this.display = true
            if (kw and SPECIFIED_OVERFLOW == 0L) this.overflow = isRootSVG
            if (kw and SPECIFIED_CLIP == 0L) this.clip = null
            if (kw and SPECIFIED_CLIP_PATH == 0L) this.clipPath = null
            if (kw and SPECIFIED_OPACITY == 0L) this.opacity = 1f
            if (kw and SPECIFIED_STOP_COLOR == 0L) this.stopColor = ColorValue.BLACK
            if (kw and SPECIFIED_STOP_OPACITY == 0L) this.stopOpacity = 1f
            if (kw and SPECIFIED_MASK == 0L) this.mask = null
            if (kw and SPECIFIED_MASK_TYPE == 0L) this.maskType = MaskType.luminance
            if (kw and SPECIFIED_FILTER == 0L) this.filter = null
            if (kw and SPECIFIED_FLOOD_COLOR == 0L) this.floodColor = ColorValue.BLACK
            if (kw and SPECIFIED_FLOOD_OPACITY == 0L) this.floodOpacity = 1f
            if (kw and SPECIFIED_SOLID_COLOR == 0L) this.solidColor = null
            if (kw and SPECIFIED_SOLID_OPACITY == 0L) this.solidOpacity = 1f
            if (kw and SPECIFIED_VIEWPORT_FILL == 0L) this.viewportFill = null
            if (kw and SPECIFIED_VIEWPORT_FILL_OPACITY == 0L) this.viewportFillOpacity = 1f
            if (kw and SPECIFIED_VECTOR_EFFECT == 0L) this.vectorEffect = VectorEffect.None
            if (kw and SPECIFIED_ISOLATION == 0L) this.isolation = Isolation.auto
            if (kw and SPECIFIED_MIX_BLEND_MODE == 0L) this.mixBlendMode = CSSBlendMode.normal
            return this
        }

        fun reset(original: Style) {
            this.original = original
            // "specified" means author-declared. The builder inherits
            // the *values* from the original, but the declaration flags start
            // empty: updateStyle gates then fire only for properties the source
            // style actually declares. cssWideKeyword/important flags are still
            // inherited (they qualify values, not declarations).
            this.specifiedFlags = 0L
            this.specifiedFlags2 = 0L
            this.cssWideKeywordFlags = original.cssWideKeywordFlags
            this.importantFlags = original.importantFlags
            this.lastTouchedFlag = 0L
            this.fill = original.fill
            this.fillRule = original.fillRule
            this.fillOpacity = original.fillOpacity
            this.stroke = original.stroke
            this.strokeOpacity = original.strokeOpacity
            this.strokeWidth = original.strokeWidth
            this.strokeLineCap = original.strokeLineCap
            this.strokeLineJoin = original.strokeLineJoin
            this.strokeMiterLimit = original.strokeMiterLimit
            this.strokeDashArray = original.strokeDashArray
            this.strokeDashOffset = original.strokeDashOffset
            this.strokeDashArrayResolved = original.strokeDashArrayResolved
            this.strokeDashOffsetResolved = original.strokeDashOffsetResolved
            this.opacity = original.opacity
            this.color = original.color
            this.fontFamily = original.fontFamily
            this.fontSize = original.fontSize
            this.fontWeight = original.fontWeight
            this.fontStyle = original.fontStyle
            this.fontWidth = original.fontWidth
            this.textDecoration = original.textDecoration
            this.direction = original.direction
            this.textAnchor = original.textAnchor
            this.dominantBaseline = original.dominantBaseline
            this.alignmentBaseline = original.alignmentBaseline
            this.baselineShift = original.baselineShift
            this.textTransform = original.textTransform
            this.overflow = original.overflow
            this.clip = original.clip
            this.markerStart = original.markerStart
            this.markerMid = original.markerMid
            this.markerEnd = original.markerEnd
            this.display = original.display
            this.visibility = original.visibility
            this.stopColor = original.stopColor
            this.stopOpacity = original.stopOpacity
            this.clipPath = original.clipPath
            this.clipRule = original.clipRule
            this.mask = original.mask
            this.maskType = original.maskType
            this.filter = original.filter
            this.floodColor = original.floodColor
            this.floodOpacity = original.floodOpacity
            this.lightingColor = original.lightingColor
            this.solidColor = original.solidColor
            this.solidOpacity = original.solidOpacity
            this.viewportFill = original.viewportFill
            this.viewportFillOpacity = original.viewportFillOpacity
            this.vectorEffect = original.vectorEffect
            this.imageRendering = original.imageRendering
            this.isolation = original.isolation
            this.mixBlendMode = original.mixBlendMode
            this.fontKerning = original.fontKerning
            this.fontVariantLigatures = original.fontVariantLigatures
            this.fontVariantPosition = original.fontVariantPosition
            this.fontVariantCaps = original.fontVariantCaps
            this.fontVariantNumeric = original.fontVariantNumeric
            this.fontVariantEastAsian = original.fontVariantEastAsian
            this.fontFeatureSettings = original.fontFeatureSettings
            this.fontVariationSettings = original.fontVariationSettings
            this.writingMode = original.writingMode
            this.glyphOrientationVertical = original.glyphOrientationVertical
            this.textOrientation = original.textOrientation
            this.colorInterpolationFilters = original.colorInterpolationFilters
            this.letterSpacing = original.letterSpacing
            this.wordSpacing = original.wordSpacing
            this.paintOrder = original.paintOrder
        }

        private var lastBuilt: Style? = null
        fun build(): Style {
            val featureSettings = fontFeatureSettings
            val variationSettings = fontVariationSettings

            val original = original
            if (isDataEqualsWith(original, featureSettings, variationSettings)) {
                return original
            }

            val lastBuilt = lastBuilt
            if (isDataEqualsWith(lastBuilt, featureSettings, variationSettings)) {
                return lastBuilt
            }

            return Style(
                specifiedFlags = specifiedFlags,
                specifiedFlags2 = specifiedFlags2,
                cssWideKeywordFlags = cssWideKeywordFlags,
                importantFlags = importantFlags,
                fill = fill,
                fillRule = fillRule,
                fillOpacity = fillOpacity,
                stroke = stroke,
                strokeOpacity = strokeOpacity,
                strokeWidth = strokeWidth,
                strokeLineCap = strokeLineCap,
                strokeLineJoin = strokeLineJoin,
                strokeMiterLimit = strokeMiterLimit,
                strokeDashArray = strokeDashArray,
                strokeDashOffset = strokeDashOffset,
                strokeDashArrayResolved = strokeDashArrayResolved,
                strokeDashOffsetResolved = strokeDashOffsetResolved,
                opacity = opacity,
                color = color,
                fontFamily = fontFamily,
                fontSize = fontSize,
                fontWeight = fontWeight,
                fontStyle = fontStyle,
                fontWidth = fontWidth,
                textDecoration = textDecoration,
                direction = direction,
                textAnchor = textAnchor,
                dominantBaseline = dominantBaseline,
                alignmentBaseline = alignmentBaseline,
                baselineShift = baselineShift,
                textTransform = textTransform,
                overflow = overflow,
                clip = clip,
                markerStart = markerStart,
                markerMid = markerMid,
                markerEnd = markerEnd,
                display = display,
                visibility = visibility,
                stopColor = stopColor,
                stopOpacity = stopOpacity,
                clipPath = clipPath,
                clipRule = clipRule,
                mask = mask,
                maskType = maskType,
                filter = filter,
                floodColor = floodColor,
                floodOpacity = floodOpacity,
                lightingColor = lightingColor,
                solidColor = solidColor,
                solidOpacity = solidOpacity,
                viewportFill = viewportFill,
                viewportFillOpacity = viewportFillOpacity,
                vectorEffect = vectorEffect,
                imageRendering = imageRendering,
                isolation = isolation,
                mixBlendMode = mixBlendMode,
                fontKerning = fontKerning,
                fontVariantLigatures = fontVariantLigatures,
                fontVariantPosition = fontVariantPosition,
                fontVariantCaps = fontVariantCaps,
                fontVariantNumeric = fontVariantNumeric,
                fontVariantEastAsian = fontVariantEastAsian,
                fontFeatureSettings = featureSettings,
                fontVariationSettings = variationSettings,
                writingMode = writingMode,
                glyphOrientationVertical = glyphOrientationVertical,
                textOrientation = textOrientation,
                colorInterpolationFilters = colorInterpolationFilters,
                letterSpacing = letterSpacing,
                wordSpacing = wordSpacing,
                paintOrder = paintOrder,
            ).also {
                this.lastBuilt = it
            }
        }

        private fun isDataEqualsWith(
            original: Style?,
            featureSettings: CSSFontFeatureSettings?,
            variationSettings: CSSFontVariationSettings,
        ): Boolean {
            contract {
                returns(true) implies (original != null)
            }

            return original != null && specifiedFlags == original.specifiedFlags &&
                    specifiedFlags2 == original.specifiedFlags2 &&
                    cssWideKeywordFlags == original.cssWideKeywordFlags &&
                    importantFlags == original.importantFlags &&
                    paintOrder == original.paintOrder &&
                    fill == original.fill &&
                    fillRule == original.fillRule &&
                    (fillOpacity == original.fillOpacity || (fillOpacity.isNaN() && original.fillOpacity.isNaN())) &&
                    stroke == original.stroke &&
                    (strokeOpacity == original.strokeOpacity || (strokeOpacity.isNaN() && original.strokeOpacity.isNaN())) &&
                    strokeWidth == original.strokeWidth &&
                    strokeLineCap == original.strokeLineCap &&
                    strokeLineJoin == original.strokeLineJoin &&
                    strokeMiterLimit == original.strokeMiterLimit &&
                    strokeDashArray.contentEquals(original.strokeDashArray) &&
                    strokeDashOffset == original.strokeDashOffset &&
                    strokeDashArrayResolved.contentEquals(original.strokeDashArrayResolved) &&
                    (strokeDashOffsetResolved == original.strokeDashOffsetResolved || (strokeDashOffsetResolved.isNaN() && original.strokeDashOffsetResolved.isNaN())) &&
                    opacity == original.opacity &&
                    color == original.color &&
                    fontFamily == original.fontFamily &&
                    fontSize == original.fontSize &&
                    (fontWeight == original.fontWeight || (fontWeight.isNaN() && original.fontWeight.isNaN())) &&
                    fontStyle == original.fontStyle &&
                    (fontWidth == original.fontWidth || (fontWidth.isNaN() && original.fontWidth.isNaN())) &&
                    textDecoration == original.textDecoration &&
                    direction == original.direction &&
                    textAnchor == original.textAnchor &&
                    dominantBaseline == original.dominantBaseline &&
                    alignmentBaseline == original.alignmentBaseline &&
                    baselineShift == original.baselineShift &&
                    textTransform == original.textTransform &&
                    overflow == original.overflow &&
                    clip == original.clip &&
                    markerStart == original.markerStart &&
                    markerMid == original.markerMid &&
                    markerEnd == original.markerEnd &&
                    display == original.display &&
                    visibility == original.visibility &&
                    stopColor == original.stopColor &&
                    (stopOpacity == original.stopOpacity || (stopOpacity.isNaN() && original.stopOpacity.isNaN())) &&
                    clipPath == original.clipPath &&
                    clipRule == original.clipRule &&
                    mask == original.mask &&
                    maskType == original.maskType &&
                    filter == original.filter &&
                    floodColor == original.floodColor &&
                    (floodOpacity == original.floodOpacity || (floodOpacity.isNaN() && original.floodOpacity.isNaN())) &&
                    lightingColor == original.lightingColor &&
                    solidColor == original.solidColor &&
                    (solidOpacity == original.solidOpacity || (solidOpacity.isNaN() && original.solidOpacity.isNaN())) &&
                    viewportFill == original.viewportFill &&
                    (viewportFillOpacity == original.viewportFillOpacity || (viewportFillOpacity.isNaN() && original.viewportFillOpacity.isNaN())) &&
                    vectorEffect == original.vectorEffect &&
                    imageRendering == original.imageRendering &&
                    isolation == original.isolation &&
                    mixBlendMode == original.mixBlendMode &&
                    fontKerning == original.fontKerning &&
                    fontVariantLigatures == original.fontVariantLigatures &&
                    fontVariantPosition == original.fontVariantPosition &&
                    fontVariantCaps == original.fontVariantCaps &&
                    fontVariantNumeric == original.fontVariantNumeric &&
                    fontVariantEastAsian == original.fontVariantEastAsian &&
                    featureSettings == original.fontFeatureSettings &&
                    variationSettings == original.fontVariationSettings &&
                    writingMode == original.writingMode &&
                    glyphOrientationVertical == original.glyphOrientationVertical &&
                    textOrientation == original.textOrientation &&
                    colorInterpolationFilters == original.colorInterpolationFilters &&
                    letterSpacing == original.letterSpacing &&
                    wordSpacing == original.wordSpacing
        }
    }

    @Retention(AnnotationRetention.SOURCE)
    @LongDef(
        flag = true,
        value = [
            SPECIFIED_FILL,
            SPECIFIED_FILL_RULE,
            SPECIFIED_FILL_OPACITY,
            SPECIFIED_STROKE,
            SPECIFIED_STROKE_OPACITY,
            SPECIFIED_STROKE_WIDTH,
            SPECIFIED_STROKE_LINECAP,
            SPECIFIED_STROKE_LINEJOIN,
            SPECIFIED_STROKE_MITERLIMIT,
            SPECIFIED_STROKE_DASHARRAY,
            SPECIFIED_STROKE_DASHOFFSET,
            SPECIFIED_OPACITY,
            SPECIFIED_COLOR,
            SPECIFIED_FONT_FAMILY,
            SPECIFIED_FONT_SIZE,
            SPECIFIED_FONT_WEIGHT,
            SPECIFIED_FONT_STYLE,
            SPECIFIED_TEXT_DECORATION,
            SPECIFIED_TEXT_ANCHOR,
            SPECIFIED_OVERFLOW,
            SPECIFIED_CLIP,
            SPECIFIED_MARKER_START,
            SPECIFIED_MARKER_MID,
            SPECIFIED_MARKER_END,
            SPECIFIED_DISPLAY,
            SPECIFIED_VISIBILITY,
            SPECIFIED_STOP_COLOR,
            SPECIFIED_STOP_OPACITY,
            SPECIFIED_CLIP_PATH,
            SPECIFIED_CLIP_RULE,
            SPECIFIED_MASK,
            SPECIFIED_MASK_TYPE,
            SPECIFIED_SOLID_COLOR,
            SPECIFIED_SOLID_OPACITY,
            SPECIFIED_VIEWPORT_FILL,
            SPECIFIED_VIEWPORT_FILL_OPACITY,
            SPECIFIED_VECTOR_EFFECT,
            SPECIFIED_DIRECTION,
            SPECIFIED_IMAGE_RENDERING,
            SPECIFIED_ISOLATION,
            SPECIFIED_MIX_BLEND_MODE,
            SPECIFIED_FONT_VARIANT_LIGATURES,
            SPECIFIED_FONT_VARIANT_POSITION,
            SPECIFIED_FONT_VARIANT_CAPS,
            SPECIFIED_FONT_VARIANT_NUMERIC,
            SPECIFIED_FONT_VARIANT_EAST_ASIAN,
            SPECIFIED_FONT_FEATURE_SETTINGS,
            SPECIFIED_WRITING_MODE,
            SPECIFIED_GLYPH_ORIENTATION_VERTICAL,
            SPECIFIED_TEXT_ORIENTATION,
            SPECIFIED_FONT_KERNING,
            SPECIFIED_FONT_VARIATION_SETTINGS,
            SPECIFIED_FONT_WIDTH,
            SPECIFIED_LETTER_SPACING,
            SPECIFIED_WORD_SPACING,
            SPECIFIED_FILTER,
            SPECIFIED_FLOOD_COLOR,
            SPECIFIED_FLOOD_OPACITY,
            SPECIFIED_LIGHTING_COLOR,
            SPECIFIED_DOMINANT_BASELINE,
            SPECIFIED_ALIGNMENT_BASELINE,
            SPECIFIED_BASELINE_SHIFT,
            SPECIFIED_TEXT_TRANSFORM,
            SPECIFIED_COLOR_INTERPOLATION_FILTERS
        ]
    )
    annotation class SpecifiedFlags

    @Retention(AnnotationRetention.SOURCE)
    @LongDef(
        flag = true,
        value = [
            SPECIFIED_PAINT_ORDER
        ]
    )
    annotation class SpecifiedFlags2

    fun isSpecified(@SpecifiedFlags flag: Long): Boolean =
        (specifiedFlags and flag) != 0L &&
                (cssWideKeywordFlags or suppressedFlags) and flag == 0L

    /**
     * True when ANY property in [mask] is specified and not suppressed/keyword-won.
     * Unlike OR-ing several [isSpecified] calls, this stays correct for combined
     * masks where some constituents may be suppressed.
     */
    fun isSpecifiedAny(@SpecifiedFlags mask: Long): Boolean =
        (specifiedFlags and cssWideKeywordFlags.inv() and suppressedFlags.inv() and mask) != 0L

    fun isSpecified2(@SpecifiedFlags2 flag: Long): Boolean =
        (specifiedFlags2 and flag) != 0L &&
                (cssWideKeywordFlags or suppressedFlags) and flag == 0L

    fun copy(
        specifiedFlags: Long = this.specifiedFlags,
        specifiedFlags2: Long = this.specifiedFlags2,
        cssWideKeywordFlags: Long = this.cssWideKeywordFlags,
        importantFlags: Long = this.importantFlags,
        fill: SvgPaint? = this.fill,
        @FillRule
        fillRule: Int = this.fillRule,
        fillOpacity: Float = this.fillOpacity,
        stroke: SvgPaint? = this.stroke,
        strokeOpacity: Float = this.strokeOpacity,
        strokeWidth: CSSLength? = this.strokeWidth,
        @LineCap
        strokeLineCap: Int = this.strokeLineCap,
        @LineJoin
        strokeLineJoin: Int = this.strokeLineJoin,
        strokeMiterLimit: Float = this.strokeMiterLimit,
        strokeDashArray: Array<CSSLength>? = this.strokeDashArray,
        strokeDashOffset: CSSLength? = this.strokeDashOffset,
        strokeDashArrayResolved: FloatArray? = this.strokeDashArrayResolved,
        strokeDashOffsetResolved: Float = this.strokeDashOffsetResolved,
        opacity: Float = this.opacity,
        color: ColorValue? = this.color,
        fontFamily: List<String>? = this.fontFamily,
        fontSize: CSSLength? = this.fontSize,
        fontWeight: Float = this.fontWeight,
        fontStyle: FontStyle? = this.fontStyle,
        fontWidth: Float = this.fontWidth,
        textDecoration: TextDecoration? = this.textDecoration,
        direction: TextDirection? = this.direction,
        textAnchor: TextAnchor? = this.textAnchor,
        dominantBaseline: DominantBaseline? = this.dominantBaseline,
        alignmentBaseline: AlignmentBaseline? = this.alignmentBaseline,
        baselineShift: BaselineShift? = this.baselineShift,
        textTransform: TextTransform? = this.textTransform,
        overflow: Boolean? = this.overflow,
        clip: CSSClipRect? = this.clip,
        markerStart: String? = this.markerStart,
        markerMid: String? = this.markerMid,
        markerEnd: String? = this.markerEnd,
        display: Boolean? = this.display,
        visibility: Boolean? = this.visibility,
        stopColor: SvgColor? = this.stopColor,
        stopOpacity: Float = this.stopOpacity,
        clipPath: String? = this.clipPath,
        @FillRule
        clipRule: Int = this.clipRule,
        mask: String? = this.mask,
        maskType: MaskType? = this.maskType,
        filter: String? = this.filter,
        floodColor: SvgColor? = this.floodColor,
        floodOpacity: Float = this.floodOpacity,
        lightingColor: SvgColor? = this.lightingColor,
        solidColor: SvgColor? = this.solidColor,
        solidOpacity: Float = this.solidOpacity,
        viewportFill: SvgPaint? = this.viewportFill,
        viewportFillOpacity: Float = this.viewportFillOpacity,
        vectorEffect: VectorEffect? = this.vectorEffect,
        imageRendering: RenderQuality? = this.imageRendering,
        isolation: Isolation? = this.isolation,
        mixBlendMode: CSSBlendMode? = this.mixBlendMode,
        fontKerning: FontKerning? = this.fontKerning,
        fontVariantLigatures: CSSFontFeatureSettings? = this.fontVariantLigatures,
        fontVariantPosition: CSSFontFeatureSettings? = this.fontVariantPosition,
        fontVariantCaps: CSSFontFeatureSettings? = this.fontVariantCaps,
        fontVariantNumeric: CSSFontFeatureSettings? = this.fontVariantNumeric,
        fontVariantEastAsian: CSSFontFeatureSettings? = this.fontVariantEastAsian,
        fontFeatureSettings: CSSFontFeatureSettings? = this.fontFeatureSettings,
        fontVariationSettings: CSSFontVariationSettings = this.fontVariationSettings,
        writingMode: WritingMode? = this.writingMode,
        glyphOrientationVertical: GlypOrientationVertical? = this.glyphOrientationVertical,
        textOrientation: TextOrientation? = this.textOrientation,
        @ColorInterpolation
        colorInterpolationFilters: Int = this.colorInterpolationFilters,
        letterSpacing: CSSLength? = this.letterSpacing,
        wordSpacing: CSSLength? = this.wordSpacing,
    ): Style {
        return Style(
            specifiedFlags = specifiedFlags,
            specifiedFlags2 = specifiedFlags2,
            cssWideKeywordFlags = cssWideKeywordFlags,
            importantFlags = importantFlags,
            fill = fill,
            fillRule = fillRule,
            fillOpacity = fillOpacity,
            stroke = stroke,
            strokeOpacity = strokeOpacity,
            strokeWidth = strokeWidth,
            strokeLineCap = strokeLineCap,
            strokeLineJoin = strokeLineJoin,
            strokeMiterLimit = strokeMiterLimit,
            strokeDashArray = strokeDashArray,
            strokeDashOffset = strokeDashOffset,
            strokeDashArrayResolved = strokeDashArrayResolved,
            strokeDashOffsetResolved = strokeDashOffsetResolved,
            opacity = opacity,
            color = color,
            fontFamily = fontFamily,
            fontSize = fontSize,
            fontWeight = fontWeight,
            fontStyle = fontStyle,
            fontWidth = fontWidth,
            textDecoration = textDecoration,
            direction = direction,
            textAnchor = textAnchor,
            dominantBaseline = dominantBaseline,
            alignmentBaseline = alignmentBaseline,
            baselineShift = baselineShift,
            textTransform = textTransform,
            overflow = overflow,
            clip = clip,
            markerStart = markerStart,
            markerMid = markerMid,
            markerEnd = markerEnd,
            display = display,
            visibility = visibility,
            stopColor = stopColor,
            stopOpacity = stopOpacity,
            clipPath = clipPath,
            clipRule = clipRule,
            mask = mask,
            maskType = maskType,
            filter = filter,
            floodColor = floodColor,
            floodOpacity = floodOpacity,
            lightingColor = lightingColor,
            solidColor = solidColor,
            solidOpacity = solidOpacity,
            viewportFill = viewportFill,
            viewportFillOpacity = viewportFillOpacity,
            vectorEffect = vectorEffect,
            imageRendering = imageRendering,
            isolation = isolation,
            mixBlendMode = mixBlendMode,
            fontKerning = fontKerning,
            fontVariantLigatures = fontVariantLigatures,
            fontVariantPosition = fontVariantPosition,
            fontVariantCaps = fontVariantCaps,
            fontVariantNumeric = fontVariantNumeric,
            fontVariantEastAsian = fontVariantEastAsian,
            fontFeatureSettings = fontFeatureSettings,
            fontVariationSettings = fontVariationSettings,
            writingMode = writingMode,
            glyphOrientationVertical = glyphOrientationVertical,
            textOrientation = textOrientation,
            colorInterpolationFilters = colorInterpolationFilters,
            letterSpacing = letterSpacing,
            wordSpacing = wordSpacing,
            paintOrder = paintOrder,
        )
    }

    override fun toString(): String {
        return buildString {
            append("Style(specifiedFlags=")
            append(specifiedFlags)
            append(", specifiedFlags2=")
            append(specifiedFlags2)
            append(", fill=")
            append(fill)
            append(", fillRule=")
            append(fillRule)
            append(", fillOpacity=")
            append(fillOpacity)
            append(", stroke=")
            append(stroke)
            append(", strokeOpacity=")
            append(strokeOpacity)
            append(", strokeWidth=")
            append(strokeWidth)
            append(", strokeLineCap=")
            append(strokeLineCap)
            append(", strokeLineJoin=")
            append(strokeLineJoin)
            append(", strokeMiterLimit=")
            append(strokeMiterLimit)
            append(", strokeDashArray=")
            append(strokeDashArray.contentToString())
            append(", strokeDashOffset=")
            append(strokeDashOffset)
            append(", strokeDashArrayResolved=")
            append(strokeDashArrayResolved.contentToString())
            append(", strokeDashOffsetResolved=")
            append(strokeDashOffsetResolved)
            append(", opacity=")
            append(opacity)
            append(", color=")
            append(color)
            append(", fontFamily=")
            append(fontFamily)
            append(", fontSize=")
            append(fontSize)
            append(", fontWeight=")
            append(fontWeight)
            append(", fontStyle=")
            append(fontStyle)
            append(", fontWidth=")
            append(fontWidth)
            append(", textDecoration=")
            append(textDecoration)
            append(", direction=")
            append(direction)
            append(", textAnchor=")
            append(textAnchor)
            append(", dominantBaseline=")
            append(dominantBaseline)
            append(", alignmentBaseline=")
            append(alignmentBaseline)
            append(", baselineShift=")
            append(baselineShift)
            append(", textTransform=")
            append(textTransform)
            append(", overflow=")
            append(overflow)
            append(", clip=")
            append(clip)
            append(", markerStart=")
            append(markerStart)
            append(", markerMid=")
            append(markerMid)
            append(", markerEnd=")
            append(markerEnd)
            append(", display=")
            append(display)
            append(", visibility=")
            append(visibility)
            append(", stopColor=")
            append(stopColor)
            append(", stopOpacity=")
            append(stopOpacity)
            append(", clipPath=")
            append(clipPath)
            append(", clipRule=")
            append(clipRule)
            append(", mask=")
            append(mask)
            append(", maskType=")
            append(maskType)
            append(", filter=")
            append(filter)
            append(", floodColor=")
            append(floodColor)
            append(", floodOpacity=")
            append(floodOpacity)
            append(", solidColor=")
            append(solidColor)
            append(", solidOpacity=")
            append(solidOpacity)
            append(", viewportFill=")
            append(viewportFill)
            append(", viewportFillOpacity=")
            append(viewportFillOpacity)
            append(", vectorEffect=")
            append(vectorEffect)
            append(", imageRendering=")
            append(imageRendering)
            append(", isolation=")
            append(isolation)
            append(", mixBlendMode=")
            append(mixBlendMode)
            append(", fontKerning=")
            append(fontKerning)
            append(", fontVariantLigatures=")
            append(fontVariantLigatures)
            append(", fontVariantPosition=")
            append(fontVariantPosition)
            append(", fontVariantCaps=")
            append(fontVariantCaps)
            append(", fontVariantNumeric=")
            append(fontVariantNumeric)
            append(", fontVariantEastAsian=")
            append(fontVariantEastAsian)
            append(", fontFeatureSettings=")
            append(fontFeatureSettings)
            append(", fontVariationSettings=")
            append(fontVariationSettings)
            append(", writingMode=")
            append(writingMode)
            append(", glyphOrientationVertical=")
            append(glyphOrientationVertical)
            append(", textOrientation=")
            append(textOrientation)
            append(", colorInterpolationFilters=")
            append(colorInterpolationFilters)
            append(", letterSpacing=")
            append(letterSpacing)
            append(", wordSpacing=")
            append(wordSpacing)
            append(", paintOrder=")
            append(paintOrder)
            append(")")
        }
    }

    companion object {
        const val FONT_WEIGHT_MIN: Float = 1f
        const val FONT_WEIGHT_NORMAL: Float = 400f
        const val FONT_WEIGHT_BOLD: Float = 700f
        const val FONT_WEIGHT_MAX: Float = 1000f
        const val FONT_WEIGHT_LIGHTER: Float = Float.MIN_VALUE
        const val FONT_WEIGHT_BOLDER: Float = Float.MAX_VALUE

        const val FONT_WIDTH_MIN: Float = 0f
        const val FONT_WIDTH_NORMAL: Float = 100f


        const val SPECIFIED_FILL: Long = 1L shl 0
        const val SPECIFIED_FILL_RULE: Long = 1L shl 1
        const val SPECIFIED_FILL_OPACITY: Long = 1L shl 2
        const val SPECIFIED_STROKE: Long = 1L shl 3
        const val SPECIFIED_STROKE_OPACITY: Long = 1L shl 4
        const val SPECIFIED_STROKE_WIDTH: Long = 1L shl 5
        const val SPECIFIED_STROKE_LINECAP: Long = 1L shl 6
        const val SPECIFIED_STROKE_LINEJOIN: Long = 1L shl 7
        const val SPECIFIED_STROKE_MITERLIMIT: Long = 1L shl 8
        const val SPECIFIED_STROKE_DASHARRAY: Long = 1L shl 9
        const val SPECIFIED_STROKE_DASHOFFSET: Long = 1L shl 10
        const val SPECIFIED_OPACITY: Long = 1L shl 11
        const val SPECIFIED_COLOR: Long = 1L shl 12
        const val SPECIFIED_FONT_FAMILY: Long = 1L shl 13
        const val SPECIFIED_FONT_SIZE: Long = 1L shl 14
        const val SPECIFIED_FONT_WEIGHT: Long = 1L shl 15
        const val SPECIFIED_FONT_STYLE: Long = 1L shl 16
        const val SPECIFIED_TEXT_DECORATION: Long = 1L shl 17
        const val SPECIFIED_TEXT_ANCHOR: Long = 1L shl 18
        const val SPECIFIED_DOMINANT_BASELINE: Long = 1L shl 59
        const val SPECIFIED_ALIGNMENT_BASELINE: Long = 1L shl 60
        const val SPECIFIED_BASELINE_SHIFT: Long = 1L shl 61
        const val SPECIFIED_TEXT_TRANSFORM: Long = 1L shl 62
        const val SPECIFIED_OVERFLOW: Long = 1L shl 19
        const val SPECIFIED_CLIP: Long = 1L shl 20
        const val SPECIFIED_MARKER_START: Long = 1L shl 21
        const val SPECIFIED_MARKER_MID: Long = 1L shl 22
        const val SPECIFIED_MARKER_END: Long = 1L shl 23
        const val SPECIFIED_DISPLAY: Long = 1L shl 24
        const val SPECIFIED_VISIBILITY: Long = 1L shl 25
        const val SPECIFIED_STOP_COLOR: Long = 1L shl 26
        const val SPECIFIED_STOP_OPACITY: Long = 1L shl 27
        const val SPECIFIED_CLIP_PATH: Long = 1L shl 28
        const val SPECIFIED_CLIP_RULE: Long = 1L shl 29
        const val SPECIFIED_MASK: Long = 1L shl 30
        const val SPECIFIED_MASK_TYPE: Long = 1L shl 54
        const val SPECIFIED_SOLID_COLOR: Long = 1L shl 31
        const val SPECIFIED_SOLID_OPACITY: Long = 1L shl 32
        const val SPECIFIED_VIEWPORT_FILL: Long = 1L shl 33
        const val SPECIFIED_VIEWPORT_FILL_OPACITY: Long = 1L shl 34
        const val SPECIFIED_VECTOR_EFFECT: Long = 1L shl 35
        const val SPECIFIED_DIRECTION: Long = 1L shl 36
        const val SPECIFIED_IMAGE_RENDERING: Long = 1L shl 37
        const val SPECIFIED_ISOLATION: Long = 1L shl 38
        const val SPECIFIED_MIX_BLEND_MODE: Long = 1L shl 39
        const val SPECIFIED_FONT_VARIANT_LIGATURES: Long = 1L shl 40
        const val SPECIFIED_FONT_VARIANT_POSITION: Long = 1L shl 41
        const val SPECIFIED_FONT_VARIANT_CAPS: Long = 1L shl 42
        const val SPECIFIED_FONT_VARIANT_NUMERIC: Long = 1L shl 43
        const val SPECIFIED_FONT_VARIANT_EAST_ASIAN: Long = 1L shl 44
        const val SPECIFIED_FONT_FEATURE_SETTINGS: Long = 1L shl 45
        const val SPECIFIED_WRITING_MODE: Long = 1L shl 46
        const val SPECIFIED_GLYPH_ORIENTATION_VERTICAL: Long = 1L shl 47
        const val SPECIFIED_TEXT_ORIENTATION: Long = 1L shl 48
        const val SPECIFIED_FONT_KERNING: Long = 1L shl 49
        const val SPECIFIED_FONT_VARIATION_SETTINGS: Long = 1L shl 50
        const val SPECIFIED_FONT_WIDTH: Long = 1L shl 51
        const val SPECIFIED_LETTER_SPACING: Long = 1L shl 52
        const val SPECIFIED_WORD_SPACING: Long = 1L shl 53
        const val SPECIFIED_COLOR_INTERPOLATION_FILTERS: Long = 1L shl 63
        const val SPECIFIED_FILTER: Long = 1L shl 55
        const val SPECIFIED_FLOOD_COLOR: Long = 1L shl 56
        const val SPECIFIED_FLOOD_OPACITY: Long = 1L shl 57
        const val SPECIFIED_LIGHTING_COLOR: Long = 1L shl 58

        // Second flag group (specifiedFlags2) — the first 64 bits are exhausted.
        const val SPECIFIED_PAINT_ORDER: Long = 1L shl 0

        // Flags for the settings that are applied to reset the root style
        // NOTE: DEFAULT_STYLE declares nothing, so its flags
        // stay empty (all-zero); the default *values* below are what reset()
        // inherits. isSpecified() means author-declared again.
        private val DEFAULT_STYLE: Style = run {
            val def = Builder()
            def.reset(Style())
            def.fill = ColorValue.BLACK
            def.fillRule = FillRule.NON_ZERO
            def.fillOpacity = 1f
            def.stroke = null // none
            def.strokeOpacity = 1f
            def.strokeWidth = CSSLength(1f)
            def.strokeLineCap = LineCap.BUTT
            def.strokeLineJoin = LineJoin.MITER
            def.strokeMiterLimit = 4f
            def.strokeDashArray = null
            def.strokeDashOffset = CSSLength.ZERO
            def.strokeDashArrayResolved = null
            def.strokeDashOffsetResolved = Float.NaN
            def.opacity = 1f
            def.color = ColorValue.BLACK // currentColor defaults to black
            def.fontFamily = null
            def.fontSize = CSSLength(
                12f,
                CssUnit.pt
            )
            def.fontWeight = FONT_WEIGHT_NORMAL
            def.fontStyle = FontStyle.normal
            def.fontWidth = FONT_WIDTH_NORMAL
            def.textDecoration = TextDecoration.None
            def.direction = TextDirection.LTR
            def.textAnchor = TextAnchor.Start
            def.overflow = true // Overflow shown/visible for root
            def.clip = null
            def.markerStart = null
            def.markerMid = null
            def.markerEnd = null
            def.display = true
            def.visibility = true
            def.stopColor = ColorValue.BLACK
            def.stopOpacity = 1f
            def.clipPath = null
            def.clipRule = FillRule.NON_ZERO
            def.mask = null
            def.maskType = MaskType.luminance
            def.filter = null
            def.floodColor = ColorValue.BLACK
            def.floodOpacity = 1f
            def.solidColor = null
            def.solidOpacity = 1f
            def.viewportFill = null
            def.viewportFillOpacity = 1f
            def.vectorEffect = VectorEffect.None
            def.imageRendering = RenderQuality.auto
            def.isolation = Isolation.auto
            def.mixBlendMode = CSSBlendMode.normal
            def.fontKerning = FontKerning.auto
            def.fontVariantLigatures = CSSFontFeatureSettings.LIGATURES_NORMAL
            def.fontVariantPosition = CSSFontFeatureSettings.POSITION_ALL_OFF
            def.fontVariantCaps = CSSFontFeatureSettings.CAPS_ALL_OFF
            def.fontVariantNumeric = CSSFontFeatureSettings.NUMERIC_ALL_OFF
            def.fontVariantEastAsian = CSSFontFeatureSettings.EAST_ASIAN_ALL_OFF
            def.fontFeatureSettings = CSSFontFeatureSettings.FONT_FEATURE_SETTINGS_NORMAL
            def.fontVariationSettings = CSSFontVariationSettings(
                weight = FONT_WEIGHT_NORMAL,
                width = FONT_WIDTH_NORMAL
            )
            def.letterSpacing = CSSLength.ZERO
            def.wordSpacing = CSSLength.ZERO
            def.writingMode = WritingMode.horizontal_tb
            def.glyphOrientationVertical = GlypOrientationVertical.auto
            def.textOrientation = TextOrientation.mixed

            def.build()
        }

        fun getDefaultStyle(): Style = DEFAULT_STYLE

        fun processStyleProperty(
            builder: Builder,
            localName: String?,
            value: String,
            isFromAttribute: Boolean
        ) {
            if (value.isEmpty()) return
            // CSS-wide keywords: inherit/unset/initial/revert must override any lower-
            // priority declaration (presentation attribute or earlier source), taking
            // the parent's computed value (or the initial one). We record the property
            // in cssWideKeywordFlags so updateStyle skips it and the value inherited
            // from the parent state survives. Note: 'initial' is only correct for
            // non-inherited properties; inherited ones currently fall back to inherit.
            if (value.equals("inherit", ignoreCase = true)
                || value.equals("unset", ignoreCase = true)
                || value.equals("initial", ignoreCase = true)
                || value.equals("revert", ignoreCase = true)) {
                specifiedFlagForAttr(SVGAttr.fromString(localName))?.let {
                    builder.markCssWideKeyword(it)
                }
                return
            }

            when (SVGAttr.fromString(localName)) {
                SVGAttr.fill -> {
                    builder.fill = parsePaintSpecifier(value)
                    builder.addSpecifiedFlag(SPECIFIED_FILL)
                }

                SVGAttr.fill_rule -> {
                    val fillRule = parseFillRule(value)
                    if (fillRule != FillRule.UNSPECIFIED) {
                        builder.fillRule = fillRule
                        builder.addSpecifiedFlag(SPECIFIED_FILL_RULE)
                    }
                }

                SVGAttr.fill_opacity -> {
                    val opacity = parseOpacity(value)
                    if (!opacity.isNaN()) {
                        builder.fillOpacity = opacity
                        builder.addSpecifiedFlag(SPECIFIED_FILL_OPACITY)
                    }
                }

                SVGAttr.stroke -> {
                    builder.stroke = parsePaintSpecifier(value)
                    builder.addSpecifiedFlag(SPECIFIED_STROKE)
                }

                SVGAttr.stroke_opacity -> {
                    val opacity = parseOpacity(value)
                    if (!opacity.isNaN()) {
                        builder.strokeOpacity = opacity
                        builder.addSpecifiedFlag(SPECIFIED_STROKE_OPACITY)
                    }
                }

                SVGAttr.stroke_width -> try {
                    builder.strokeWidth = parseLength(value)
                    builder.addSpecifiedFlag(SPECIFIED_STROKE_WIDTH)
                } catch (_: KSVGParseException) {
                }

                SVGAttr.stroke_linecap -> {
                    val strokeLineCap = parseStrokeLineCap(value)
                    if (strokeLineCap != LineCap.UNSPECIFIED) {
                        builder.strokeLineCap = strokeLineCap
                        builder.addSpecifiedFlag(SPECIFIED_STROKE_LINECAP)
                    }
                }

                SVGAttr.stroke_linejoin -> {
                    val strokeLineJoin = parseStrokeLineJoin(value)
                    if (strokeLineJoin != LineJoin.UNSPECIFIED) {
                        builder.strokeLineJoin = strokeLineJoin
                        builder.addSpecifiedFlag(SPECIFIED_STROKE_LINEJOIN)
                    }
                }

                SVGAttr.stroke_miterlimit -> try {
                    // Per spec the value must be >= 1; smaller values are clamped.
                    builder.strokeMiterLimit = parseFloat(value).coerceAtLeast(1f)
                    builder.addSpecifiedFlag(SPECIFIED_STROKE_MITERLIMIT)
                } catch (_: KSVGParseException) {
                }

                SVGAttr.stroke_dasharray -> {
                    if (value.equals(NONE, ignoreCase = true)) {
                        builder.strokeDashArray = null
                        builder.addSpecifiedFlag(SPECIFIED_STROKE_DASHARRAY)
                    } else {
                        val strokeDashArray = parseStrokeDashArray(value)
                        builder.strokeDashArray = strokeDashArray
                        if (strokeDashArray != null) builder.addSpecifiedFlag(SPECIFIED_STROKE_DASHARRAY)
                    }
                }

                SVGAttr.stroke_dashoffset -> try {
                    builder.strokeDashOffset = parseLength(value)
                    builder.addSpecifiedFlag(SPECIFIED_STROKE_DASHOFFSET)
                } catch (_: KSVGParseException) {
                }

                SVGAttr.opacity -> {
                    val opacity = parseOpacity(value)
                    if (!opacity.isNaN()) {
                        builder.opacity = opacity
                        builder.addSpecifiedFlag(SPECIFIED_OPACITY)
                    }
                }

                SVGAttr.color -> {
                    builder.color = ColorParser.parseColor(value)
                    builder.addSpecifiedFlag(SPECIFIED_COLOR)
                }

                SVGAttr.font -> {
                    if (!isFromAttribute) {
                        parseFont(builder, value)
                    }
                }

                SVGAttr.font_family -> {
                    val fontFamily = parseFontFamily(value)
                    builder.fontFamily = fontFamily
                    if (fontFamily != null) builder.addSpecifiedFlag(SPECIFIED_FONT_FAMILY)
                }

                SVGAttr.font_size -> {
                    val fontSize = parseFontSize(value)
                    builder.fontSize = fontSize
                    if (fontSize != null) builder.addSpecifiedFlag(SPECIFIED_FONT_SIZE)
                }

                SVGAttr.font_weight -> {
                    val fontWeight = parseFontWeight(value)
                    if (!fontWeight.isNaN()) {
                        builder.fontWeight = fontWeight
                        builder.addSpecifiedFlag(SPECIFIED_FONT_WEIGHT)
                        builder.getFontVariationSettingsBuilder().addSetting(CSSFontVariationSettings.VARIATION_WEIGHT, fontWeight)
                        builder.addSpecifiedFlag(SPECIFIED_FONT_VARIATION_SETTINGS)
                    }
                }

                SVGAttr.font_style -> {
                    val fontStyle = parseFontStyle(value)
                    builder.fontStyle = fontStyle
                    if (fontStyle != null) {
                        builder.addSpecifiedFlag(SPECIFIED_FONT_STYLE)
                        if (fontStyle == FontStyle.italic) {
                            builder.getFontVariationSettingsBuilder().addSetting(
                                CSSFontVariationSettings.VARIATION_ITALIC,
                                CSSFontVariationSettings.VARIATION_ITALIC_VALUE_ON
                            )
                            builder.addSpecifiedFlag(SPECIFIED_FONT_VARIATION_SETTINGS)
                        } else if (fontStyle == FontStyle.oblique) {
                            builder.getFontVariationSettingsBuilder().addSetting(
                                CSSFontVariationSettings.VARIATION_SLANT,
                                CSSFontVariationSettings.VARIATION_OBLIQUE_VALUE_ON
                            )
                            builder.addSpecifiedFlag(SPECIFIED_FONT_VARIATION_SETTINGS)
                        }
                    }
                }

                SVGAttr.font_stretch, SVGAttr.font_width -> {
                    val fontWidth = parseFontWidth(value)
                    if (!fontWidth.isNaN()) {
                        builder.fontWidth = fontWidth
                        builder.addSpecifiedFlag(SPECIFIED_FONT_WIDTH)
                        builder.getFontVariationSettingsBuilder().addSetting(CSSFontVariationSettings.VARIATION_WIDTH, fontWidth)
                        builder.addSpecifiedFlag(SPECIFIED_FONT_VARIATION_SETTINGS)
                    }
                }

                SVGAttr.text_decoration -> {
                    val textDecoration = parseTextDecoration(value)
                    builder.textDecoration = textDecoration
                    if (textDecoration != null) builder.addSpecifiedFlag(SPECIFIED_TEXT_DECORATION)
                }

                SVGAttr.direction -> {
                    val direction = parseTextDirection(value)
                    builder.direction = direction
                    if (direction != null) builder.addSpecifiedFlag(SPECIFIED_DIRECTION)
                }

                SVGAttr.text_anchor -> {
                    val textAnchor = parseTextAnchor(value)
                    builder.textAnchor = textAnchor
                    if (textAnchor != null) builder.addSpecifiedFlag(SPECIFIED_TEXT_ANCHOR)
                }

                SVGAttr.dominant_baseline -> {
                    val dominantBaseline = parseDominantBaseline(value)
                    builder.dominantBaseline = dominantBaseline
                    if (dominantBaseline != null) builder.addSpecifiedFlag(SPECIFIED_DOMINANT_BASELINE)
                }

                SVGAttr.alignment_baseline -> {
                    val alignmentBaseline = parseAlignmentBaseline(value)
                    builder.alignmentBaseline = alignmentBaseline
                    if (alignmentBaseline != null) builder.addSpecifiedFlag(SPECIFIED_ALIGNMENT_BASELINE)
                }

                SVGAttr.baseline_shift -> {
                    val baselineShift = parseBaselineShift(value)
                    builder.baselineShift = baselineShift
                    if (baselineShift != null) builder.addSpecifiedFlag(SPECIFIED_BASELINE_SHIFT)
                }

                SVGAttr.text_transform -> {
                    val textTransform = parseTextTransform(value)
                    builder.textTransform = textTransform
                    if (textTransform != null) builder.addSpecifiedFlag(SPECIFIED_TEXT_TRANSFORM)
                }

                SVGAttr.overflow -> {
                    val overflow = parseOverflow(value)
                    builder.overflow = overflow
                    if (overflow != null) builder.addSpecifiedFlag(SPECIFIED_OVERFLOW)
                }

                SVGAttr.marker -> {
                    val functionalIRI = parseFunctionalIRI(value)
                    builder.markerStart = functionalIRI
                    builder.markerMid = functionalIRI
                    builder.markerEnd = functionalIRI
                    if (functionalIRI != null) {
                        builder.addSpecifiedFlag(SPECIFIED_MARKER_START or SPECIFIED_MARKER_MID or SPECIFIED_MARKER_END)
                    }
                }

                SVGAttr.marker_start -> {
                    val markerStart = parseFunctionalIRI(value)
                    builder.markerStart = markerStart
                    if (markerStart != null) builder.addSpecifiedFlag(SPECIFIED_MARKER_START)
                }

                SVGAttr.marker_mid -> {
                    val markerMid = parseFunctionalIRI(value)
                    builder.markerMid = markerMid
                    if (markerMid != null) builder.addSpecifiedFlag(SPECIFIED_MARKER_MID)
                }

                SVGAttr.marker_end -> {
                    val markerEnd = parseFunctionalIRI(value)
                    builder.markerEnd = markerEnd
                    if (markerEnd != null) builder.addSpecifiedFlag(SPECIFIED_MARKER_END)
                }

                SVGAttr.display -> {
                    if (!value.contains('|') && isValidDisplayValue(value)) {
                        val display = !value.equals(NONE, ignoreCase = true)
                        builder.display = display
                        builder.addSpecifiedFlag(SPECIFIED_DISPLAY)
                    }
                }

                SVGAttr.visibility -> {
                    if (!value.contains('|') && isValidVisibilityValue(value)) {
                        val visibility = value.equals("visible", ignoreCase = true)
                        builder.visibility = visibility
                        builder.addSpecifiedFlag(SPECIFIED_VISIBILITY)
                    }
                }

                SVGAttr.stop_color -> {
                    builder.stopColor = if (value.equals(CURRENT_COLOR, ignoreCase = true)) CurrentColor else ColorParser.parseColor(value)
                    builder.addSpecifiedFlag(SPECIFIED_STOP_COLOR)
                }

                SVGAttr.stop_opacity -> {
                    val opacity = parseOpacity(value)
                    if (!opacity.isNaN()) {
                        builder.stopOpacity = opacity
                        builder.addSpecifiedFlag(SPECIFIED_STOP_OPACITY)
                    }
                }

                SVGAttr.clip -> {
                    val clip = parseClip(value)
                    builder.clip = clip
                    if (clip != null) builder.addSpecifiedFlag(SPECIFIED_CLIP)
                }

                SVGAttr.clip_path -> {
                    val clipPath = parseFunctionalIRI(value)
                    builder.clipPath = clipPath
                    if (clipPath != null) builder.addSpecifiedFlag(SPECIFIED_CLIP_PATH)
                }

                SVGAttr.clip_rule -> {
                    val clipRule = parseFillRule(value)
                    if (clipRule != FillRule.UNSPECIFIED) {
                        builder.clipRule = clipRule
                        builder.addSpecifiedFlag(SPECIFIED_CLIP_RULE)
                    }
                }

                SVGAttr.mask -> {
                    val mask = parseFunctionalIRI(value)
                    builder.mask = mask
                    if (mask != null) builder.addSpecifiedFlag(SPECIFIED_MASK)
                }

                SVGAttr.mask_type -> {
                    val maskType = MaskType.fromString(value)
                    builder.maskType = maskType
                    if (maskType != null) builder.addSpecifiedFlag(SPECIFIED_MASK_TYPE)
                }

                SVGAttr.color_interpolation_filters -> {
                    val mode = ColorInterpolation.parse(value)
                    if (mode != ColorInterpolation.UNSPECIFIED) {
                        builder.colorInterpolationFilters = mode
                        builder.addSpecifiedFlag(SPECIFIED_COLOR_INTERPOLATION_FILTERS)
                    }
                }

                SVGAttr.filter -> {
                    val filter = parseFunctionalIRI(value)
                    builder.filter = filter
                    if (filter != null) builder.addSpecifiedFlag(SPECIFIED_FILTER)
                }

                SVGAttr.flood_color -> {
                    builder.floodColor = if (value.equals(CURRENT_COLOR, ignoreCase = true)) CurrentColor else ColorParser.parseColor(value)
                    builder.addSpecifiedFlag(SPECIFIED_FLOOD_COLOR)
                }

                SVGAttr.flood_opacity -> {
                    val opacity = parseOpacity(value)
                    if (!opacity.isNaN()) {
                        builder.floodOpacity = opacity
                        builder.addSpecifiedFlag(SPECIFIED_FLOOD_OPACITY)
                    }
                }

                SVGAttr.lighting_color -> {
                    builder.lightingColor = if (value.equals(CURRENT_COLOR, ignoreCase = true)) CurrentColor else ColorParser.parseColor(value)
                    builder.addSpecifiedFlag(SPECIFIED_LIGHTING_COLOR)
                }

                SVGAttr.solid_color -> {
                    if (isFromAttribute) {
                        builder.solidColor = if (value.equals(CURRENT_COLOR, ignoreCase = true)) CurrentColor else ColorParser.parseColor(value)
                        builder.addSpecifiedFlag(SPECIFIED_SOLID_COLOR)
                    }
                }

                SVGAttr.solid_opacity -> {
                    if (isFromAttribute) {
                        val opacity = parseOpacity(value)
                        if (!opacity.isNaN()) {
                            builder.solidOpacity = opacity
                            builder.addSpecifiedFlag(SPECIFIED_SOLID_OPACITY)
                        }
                    }
                }

                SVGAttr.viewport_fill -> {
                    builder.viewportFill = if (value.equals(CURRENT_COLOR, ignoreCase = true)) CurrentColor else ColorParser.parseColor(value)
                    builder.addSpecifiedFlag(SPECIFIED_VIEWPORT_FILL)
                }

                SVGAttr.viewport_fill_opacity -> {
                    val opacity = parseOpacity(value)
                    if (!opacity.isNaN()) {
                        builder.viewportFillOpacity = opacity
                        builder.addSpecifiedFlag(SPECIFIED_VIEWPORT_FILL_OPACITY)
                    }
                }

                SVGAttr.vector_effect -> {
                    val vectorEffect = parseVectorEffect(value)
                    builder.vectorEffect = vectorEffect
                    if (vectorEffect != null) builder.addSpecifiedFlag(SPECIFIED_VECTOR_EFFECT)
                }

                SVGAttr.image_rendering -> {
                    val imageRendering = parseRenderQuality(value)
                    builder.imageRendering = imageRendering
                    if (imageRendering != null) builder.addSpecifiedFlag(SPECIFIED_IMAGE_RENDERING)
                }

                SVGAttr.isolation -> {
                    if (!isFromAttribute) {
                        val isolation = parseIsolation(value)
                        builder.isolation = isolation
                        if (isolation != null) builder.addSpecifiedFlag(SPECIFIED_ISOLATION)
                    }
                }

                SVGAttr.mix_blend_mode -> {
                    if (!isFromAttribute) {
                        builder.mixBlendMode = CSSBlendMode.fromString(value)
                        builder.addSpecifiedFlag(SPECIFIED_MIX_BLEND_MODE)
                    }
                }

                SVGAttr.font_kerning -> {
                    if (!isFromAttribute) {
                        val fontKerning = CSSFontFeatureSettings.parseFontKerning(value)
                        builder.fontKerning = fontKerning
                        if (fontKerning != null) builder.addSpecifiedFlag(SPECIFIED_FONT_KERNING)
                    }
                }

                SVGAttr.font_variant -> {
                    if (!isFromAttribute) {
                        CSSFontFeatureSettings.parseFontVariant(builder, value)
                    }
                }

                SVGAttr.font_variant_ligatures -> {
                    if (!isFromAttribute) {
                        val fontVariantLigatures = CSSFontFeatureSettings.parseVariantLigatures(value)
                        builder.fontVariantLigatures = fontVariantLigatures
                        if (fontVariantLigatures != null) builder.addSpecifiedFlag(SPECIFIED_FONT_VARIANT_LIGATURES)
                    }
                }

                SVGAttr.font_variant_position -> {
                    if (!isFromAttribute) {
                        val fontVariantPosition = CSSFontFeatureSettings.parseVariantPosition(value)
                        builder.fontVariantPosition = fontVariantPosition
                        if (fontVariantPosition != null) builder.addSpecifiedFlag(SPECIFIED_FONT_VARIANT_POSITION)
                    }
                }

                SVGAttr.font_variant_caps -> {
                    if (!isFromAttribute) {
                        val fontVariantCaps = CSSFontFeatureSettings.parseVariantCaps(value)
                        builder.fontVariantCaps = fontVariantCaps
                        if (fontVariantCaps != null) builder.addSpecifiedFlag(SPECIFIED_FONT_VARIANT_CAPS)
                    }
                }

                SVGAttr.font_variant_numeric -> {
                    if (!isFromAttribute) {
                        val fontVariantNumeric = CSSFontFeatureSettings.parseVariantNumeric(value)
                        builder.fontVariantNumeric = fontVariantNumeric
                        if (fontVariantNumeric != null) builder.addSpecifiedFlag(SPECIFIED_FONT_VARIANT_NUMERIC)
                    }
                }

                SVGAttr.font_variant_east_asian -> {
                    if (!isFromAttribute) {
                        val fontVariantEastAsian = CSSFontFeatureSettings.parseEastAsian(value)
                        builder.fontVariantEastAsian = fontVariantEastAsian
                        if (fontVariantEastAsian != null) builder.addSpecifiedFlag(SPECIFIED_FONT_VARIANT_EAST_ASIAN)
                    }
                }

                SVGAttr.font_feature_settings -> {
                    if (!isFromAttribute) {
                        val fontFeatureSettings = CSSFontFeatureSettings.parseFontFeatureSettings(value)
                        builder.fontFeatureSettings = fontFeatureSettings
                        if (fontFeatureSettings != null) builder.addSpecifiedFlag(SPECIFIED_FONT_FEATURE_SETTINGS)
                    }
                }

                SVGAttr.font_variation_settings -> {
                    if (!isFromAttribute) {
                        val fvsValues = CSSFontVariationSettings.parseFontVariationSettings(value)
                        if (fvsValues != null) {
                            builder.getFontVariationSettingsBuilder().addSettings(fvsValues)
                            builder.addSpecifiedFlag(SPECIFIED_FONT_VARIATION_SETTINGS)
                        }
                    }
                }

                SVGAttr.letter_spacing -> {
                    val letterSpacing = parseLetterOrWordSpacing(value)
                    builder.letterSpacing = letterSpacing
                    if (letterSpacing != null) builder.addSpecifiedFlag(SPECIFIED_LETTER_SPACING)
                }

                SVGAttr.word_spacing -> {
                    val wordSpacing = parseLetterOrWordSpacing(value)
                    builder.wordSpacing = wordSpacing
                    if (wordSpacing != null) builder.addSpecifiedFlag(SPECIFIED_WORD_SPACING)
                }

                SVGAttr.paint_order -> {
                    val paintOrder = if (value.equals(NORMAL, ignoreCase = true)) {
                        PaintOrder.FILL_STROKE_MARKERS
                    } else {
                        PaintOrder.parse(value)
                    }
                    builder.paintOrder = paintOrder
                    if (paintOrder != 0) builder.addSpecifiedFlag2(SPECIFIED_PAINT_ORDER)
                }

                else -> {}
            }
        }

        /**
         * The SPECIFIED_* flag of properties that support CSS-wide keywords, used by
         * the inherit/unset/initial/revert handling in [processStyleProperty]. Multi-
         * property shorthands and properties without a dedicated flag return null.
         */
        private fun specifiedFlagForAttr(attr: SVGAttr): Long? = when (attr) {
            SVGAttr.alignment_baseline -> SPECIFIED_ALIGNMENT_BASELINE
            SVGAttr.baseline_shift -> SPECIFIED_BASELINE_SHIFT
            SVGAttr.clip -> SPECIFIED_CLIP
            SVGAttr.clip_path -> SPECIFIED_CLIP_PATH
            SVGAttr.clip_rule -> SPECIFIED_CLIP_RULE
            SVGAttr.color -> SPECIFIED_COLOR
            SVGAttr.color_interpolation_filters -> SPECIFIED_COLOR_INTERPOLATION_FILTERS
            SVGAttr.direction -> SPECIFIED_DIRECTION
            SVGAttr.display -> SPECIFIED_DISPLAY
            SVGAttr.dominant_baseline -> SPECIFIED_DOMINANT_BASELINE
            SVGAttr.fill -> SPECIFIED_FILL
            SVGAttr.fill_opacity -> SPECIFIED_FILL_OPACITY
            SVGAttr.fill_rule -> SPECIFIED_FILL_RULE
            SVGAttr.filter -> SPECIFIED_FILTER
            SVGAttr.flood_color -> SPECIFIED_FLOOD_COLOR
            SVGAttr.flood_opacity -> SPECIFIED_FLOOD_OPACITY
            SVGAttr.font_family -> SPECIFIED_FONT_FAMILY
            SVGAttr.font_feature_settings -> SPECIFIED_FONT_FEATURE_SETTINGS
            SVGAttr.font_kerning -> SPECIFIED_FONT_KERNING
            SVGAttr.font_size -> SPECIFIED_FONT_SIZE
            SVGAttr.font_stretch -> SPECIFIED_FONT_WIDTH
            SVGAttr.font_style -> SPECIFIED_FONT_STYLE
            SVGAttr.font_variant_caps -> SPECIFIED_FONT_VARIANT_CAPS
            SVGAttr.font_variant_east_asian -> SPECIFIED_FONT_VARIANT_EAST_ASIAN
            SVGAttr.font_variant_ligatures -> SPECIFIED_FONT_VARIANT_LIGATURES
            SVGAttr.font_variant_numeric -> SPECIFIED_FONT_VARIANT_NUMERIC
            SVGAttr.font_variant_position -> SPECIFIED_FONT_VARIANT_POSITION
            SVGAttr.font_variation_settings -> SPECIFIED_FONT_VARIATION_SETTINGS
            SVGAttr.font_weight -> SPECIFIED_FONT_WEIGHT
            SVGAttr.font_width -> SPECIFIED_FONT_WIDTH
            SVGAttr.image_rendering -> SPECIFIED_IMAGE_RENDERING
            SVGAttr.isolation -> SPECIFIED_ISOLATION
            SVGAttr.letter_spacing -> SPECIFIED_LETTER_SPACING
            SVGAttr.lighting_color -> SPECIFIED_LIGHTING_COLOR
            SVGAttr.marker_end -> SPECIFIED_MARKER_END
            SVGAttr.marker_mid -> SPECIFIED_MARKER_MID
            SVGAttr.marker_start -> SPECIFIED_MARKER_START
            SVGAttr.mask -> SPECIFIED_MASK
            SVGAttr.mask_type -> SPECIFIED_MASK_TYPE
            SVGAttr.mix_blend_mode -> SPECIFIED_MIX_BLEND_MODE
            SVGAttr.opacity -> SPECIFIED_OPACITY
            SVGAttr.overflow -> SPECIFIED_OVERFLOW
            SVGAttr.paint_order -> SPECIFIED_PAINT_ORDER
            SVGAttr.solid_color -> SPECIFIED_SOLID_COLOR
            SVGAttr.solid_opacity -> SPECIFIED_SOLID_OPACITY
            SVGAttr.stop_color -> SPECIFIED_STOP_COLOR
            SVGAttr.stop_opacity -> SPECIFIED_STOP_OPACITY
            SVGAttr.stroke -> SPECIFIED_STROKE
            SVGAttr.stroke_dasharray -> SPECIFIED_STROKE_DASHARRAY
            SVGAttr.stroke_dashoffset -> SPECIFIED_STROKE_DASHOFFSET
            SVGAttr.stroke_linecap -> SPECIFIED_STROKE_LINECAP
            SVGAttr.stroke_linejoin -> SPECIFIED_STROKE_LINEJOIN
            SVGAttr.stroke_miterlimit -> SPECIFIED_STROKE_MITERLIMIT
            SVGAttr.stroke_opacity -> SPECIFIED_STROKE_OPACITY
            SVGAttr.stroke_width -> SPECIFIED_STROKE_WIDTH
            SVGAttr.text_anchor -> SPECIFIED_TEXT_ANCHOR
            SVGAttr.text_decoration -> SPECIFIED_TEXT_DECORATION
            SVGAttr.text_transform -> SPECIFIED_TEXT_TRANSFORM
            SVGAttr.vector_effect -> SPECIFIED_VECTOR_EFFECT
            SVGAttr.viewport_fill -> SPECIFIED_VIEWPORT_FILL
            SVGAttr.viewport_fill_opacity -> SPECIFIED_VIEWPORT_FILL_OPACITY
            SVGAttr.visibility -> SPECIFIED_VISIBILITY
            SVGAttr.word_spacing -> SPECIFIED_WORD_SPACING
            else -> null
        }
    }
}

