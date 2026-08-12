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
package hu.oandras.ksvg.dom

import androidx.annotation.LongDef
import hu.oandras.ksvg.SVGParseException
import hu.oandras.ksvg.css.CSSFontFeatureSettings
import hu.oandras.ksvg.css.CSSFontVariationSettings
import hu.oandras.ksvg.css.CSSLength
import hu.oandras.ksvg.css.CssUnit
import hu.oandras.ksvg.parser.SVGParserImpl
import hu.oandras.ksvg.parser.SVGParserImpl.Companion.parseClip
import hu.oandras.ksvg.parser.SVGParserImpl.Companion.parseColor
import hu.oandras.ksvg.parser.SVGParserImpl.Companion.parseFillRule
import hu.oandras.ksvg.parser.SVGParserImpl.Companion.parseFloat
import hu.oandras.ksvg.parser.SVGParserImpl.Companion.parseFont
import hu.oandras.ksvg.parser.SVGParserImpl.Companion.parseFontFamily
import hu.oandras.ksvg.parser.SVGParserImpl.Companion.parseFontSize
import hu.oandras.ksvg.parser.SVGParserImpl.Companion.parseFontStyle
import hu.oandras.ksvg.parser.SVGParserImpl.Companion.parseFontWeight
import hu.oandras.ksvg.parser.SVGParserImpl.Companion.parseFontWidth
import hu.oandras.ksvg.parser.SVGParserImpl.Companion.parseFunctionalIRI
import hu.oandras.ksvg.parser.SVGParserImpl.Companion.parseIsolation
import hu.oandras.ksvg.parser.SVGParserImpl.Companion.parseLength
import hu.oandras.ksvg.parser.SVGParserImpl.Companion.parseLetterOrWordSpacing
import hu.oandras.ksvg.parser.SVGParserImpl.Companion.parseOpacity
import hu.oandras.ksvg.parser.SVGParserImpl.Companion.parseOverflow
import hu.oandras.ksvg.parser.SVGParserImpl.Companion.parsePaintSpecifier
import hu.oandras.ksvg.parser.SVGParserImpl.Companion.parseRenderQuality
import hu.oandras.ksvg.parser.SVGParserImpl.Companion.parseStrokeDashArray
import hu.oandras.ksvg.parser.SVGParserImpl.Companion.parseStrokeLineCap
import hu.oandras.ksvg.parser.SVGParserImpl.Companion.parseStrokeLineJoin
import hu.oandras.ksvg.parser.SVGParserImpl.Companion.parseTextAnchor
import hu.oandras.ksvg.parser.SVGParserImpl.Companion.parseTextDecoration
import hu.oandras.ksvg.parser.SVGParserImpl.Companion.parseTextDirection
import hu.oandras.ksvg.parser.SVGParserImpl.Companion.parseVectorEffect

@Suppress("EnumEntryName")
internal class Style private constructor(
    // Which properties have been explicitly specified by this element
    @SpecifiedFlags
    private var specifiedFlags: Long,

    @JvmField
    var fill: SvgPaint?,
    @JvmField
    var fillRule: FillRule?,
    @JvmField
    var fillOpacity: Float?,

    @JvmField
    var stroke: SvgPaint?,
    @JvmField
    var strokeOpacity: Float?,
    @JvmField
    var strokeWidth: CSSLength?,
    @JvmField
    var strokeLineCap: LineCap?,
    @JvmField
    var strokeLineJoin: LineJoin?,
    @JvmField
    var strokeMiterLimit: Float?,
    @JvmField
    var strokeDashArray: Array<CSSLength>?,
    @JvmField
    var strokeDashOffset: CSSLength?,

    @JvmField
    var opacity: Float, // master opacity of both stroke and fill

    @JvmField
    var color: ColorValue?,

    @JvmField
    var fontFamily: List<String>?,
    @JvmField
    var fontSize: CSSLength?,
    @JvmField
    var fontWeight: Float?,
    @JvmField
    var fontStyle: FontStyle?,
    @JvmField
    var fontWidth: Float?,
    @JvmField
    var textDecoration: TextDecoration?,
    @JvmField
    var direction: TextDirection?,

    @JvmField
    var textAnchor: TextAnchor?,

    @JvmField
    var overflow: Boolean?, // true if overflow visible
    @JvmField
    var clip: CSSClipRect?,

    @JvmField
    var markerStart: String?,
    @JvmField
    var markerMid: String?,
    @JvmField
    var markerEnd: String?,

    @JvmField
    var display: Boolean?, // true if we should display
    @JvmField
    var visibility: Boolean?, // true if visible

    @JvmField
    var stopColor: SvgColor?,
    @JvmField
    var stopOpacity: Float?,

    @JvmField
    var clipPath: String?,
    @JvmField
    var clipRule: FillRule?,

    @JvmField
    var mask: String?,

    @JvmField
    var maskType: MaskType?,

    @JvmField
    var filter: String?,

    @JvmField
    var floodColor: SvgColor?,

    @JvmField
    var floodOpacity: Float?,

    @JvmField
    var solidColor: SvgColor?,
    @JvmField
    var solidOpacity: Float?,

    @JvmField
    var viewportFill: SvgPaint?,
    @JvmField
    var viewportFillOpacity: Float?,

    @JvmField
    var vectorEffect: VectorEffect?,

    @JvmField
    var imageRendering: RenderQuality?,

    @JvmField
    var isolation: Isolation?,
    @JvmField
    var mixBlendMode: CSSBlendMode?,

    @JvmField
    var fontKerning: FontKerning?,

    @JvmField
    var fontVariantLigatures: CSSFontFeatureSettings?,

    @JvmField
    var fontVariantPosition: CSSFontFeatureSettings?,

    @JvmField
    var fontVariantCaps: CSSFontFeatureSettings?,

    @JvmField
    var fontVariantNumeric: CSSFontFeatureSettings?,

    @JvmField
    var fontVariantEastAsian: CSSFontFeatureSettings?,
    @JvmField
    var fontFeatureSettings: CSSFontFeatureSettings?,
    @JvmField
    var fontVariationSettings: CSSFontVariationSettings,
    @JvmField
    var writingMode: WritingMode?,
    @JvmField
    var glyphOrientationVertical: GlypOrientationVertical?,
    @JvmField
    var textOrientation: TextOrientation?,

    @JvmField
    var letterSpacing: CSSLength?,
    @JvmField
    var wordSpacing: CSSLength?,
) : Cloneable {

    constructor(): this(
        specifiedFlags = 0,
        fill = null,
        fillRule = null,
        fillOpacity = null,
        stroke = null,
        strokeOpacity = null,
        strokeWidth = null,
        strokeLineCap = null,
        strokeLineJoin = null,
        strokeMiterLimit = null,
        strokeDashArray = null,
        strokeDashOffset = null,
        opacity = 1f,
        color = null,
        fontFamily = null,
        fontSize = null,
        fontWeight = null,
        fontStyle = null,
        fontWidth = null,
        textDecoration = null,
        direction = null,
        textAnchor = null,
        overflow = null,
        clip = null,
        markerStart = null,
        markerMid = null,
        markerEnd = null,
        display = null,
        visibility = null,
        stopColor = null,
        stopOpacity = null,
        clipPath = null,
        clipRule = null,
        mask = null,
        maskType = null,
        filter = null,
        floodColor = null,
        floodOpacity = null,
        solidColor = null,
        solidOpacity = null,
        viewportFill = null,
        viewportFillOpacity = null,
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
        fontVariationSettings = CSSFontVariationSettings(),
        writingMode = null,
        glyphOrientationVertical = null,
        textOrientation = null,
        letterSpacing = null,
        wordSpacing = null,
    )

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
            SPECIFIED_FLOOD_OPACITY
        ]
    )
    annotation class SpecifiedFlags

    fun isSpecified(@SpecifiedFlags flag: Long): Boolean = (specifiedFlags and flag) != 0L

    fun addSpecifiedFlag(@SpecifiedFlags flag: Long) {
        specifiedFlags = specifiedFlags or flag
    }

    enum class FillRule {
        NonZero,
        EvenOdd
    }

    enum class LineCap {
        Butt,
        Round,
        Square
    }

    enum class LineJoin {
        Miter,
        Round,
        Bevel
    }

    enum class FontStyle {
        normal,
        italic,
        oblique
    }

    enum class TextAnchor {
        Start,
        Middle,
        End
    }

    enum class TextDecoration {
        None,
        Underline,
        Overline,
        LineThrough,
        Blink
    }

    enum class TextDirection {
        LTR,
        RTL
    }

    enum class VectorEffect {
        None,
        NonScalingStroke
    }

    enum class RenderQuality {
        auto,
        optimizeQuality,
        optimizeSpeed
    }

    enum class Isolation {
        auto,
        isolate
    }

    enum class CSSBlendMode {
        normal,
        multiply,
        screen,
        overlay,
        darken,
        lighten,
        color_dodge,
        color_burn,
        hard_light,
        soft_light,
        difference,
        exclusion,
        hue,
        saturation,
        color,
        luminosity,
        UNSUPPORTED;

        companion object {
            fun fromString(str: String?): CSSBlendMode = when (str) {
                "normal" -> normal
                "multiply" -> multiply
                "screen" -> screen
                "overlay" -> overlay
                "darken" -> darken
                "lighten" -> lighten
                "color-dodge" -> color_dodge
                "color-burn" -> color_burn
                "hard-light" -> hard_light
                "soft-light" -> soft_light
                "difference" -> difference
                "exclusion" -> exclusion
                "hue" -> hue
                "saturation" -> saturation
                "color" -> color
                "luminosity" -> luminosity
                else -> UNSUPPORTED
            }
        }
    }

    enum class MaskType {
        luminance,
        alpha;

        companion object {
            fun fromString(str: String?): MaskType? = when (str) {
                "luminance" -> luminance
                "alpha" -> alpha
                else -> null
            }
        }
    }


    enum class FontKerning {
        auto,
        normal,
        none
    }

    @Suppress("EnumEntryName", "unused")
    enum class WritingMode {
        // Old SVG 1.1 values
        lr_tb,
        rl_tb,
        tb_rl,
        lr,
        rl,
        tb,

        // New CSS3 values
        horizontal_tb,
        vertical_rl,
        vertical_lr
    }

    @Suppress("unused")
    enum class GlypOrientationVertical {
        auto,
        angle0,
        angle90,
        angle180,
        angle270
    }

    @Suppress("unused")
    enum class TextOrientation {
        mixed,
        upright,
        sideways
    }


    // Called on the state.style object to reset the properties that don't inherit
    // from the parent style.
    fun resetNonInheritingProperties(isRootSVG: Boolean) {
        this.display = true
        this.overflow = isRootSVG
        this.clip = null
        this.clipPath = null
        this.opacity = 1f
        this.stopColor = ColorValue.BLACK
        this.stopOpacity = 1f
        this.mask = null
        this.maskType = MaskType.luminance
        this.filter = null
        this.floodColor = ColorValue.BLACK
        this.floodOpacity = 1f
        this.solidColor = null
        this.solidOpacity = 1f
        this.viewportFill = null
        this.viewportFillOpacity = 1f
        this.vectorEffect = VectorEffect.None
        this.isolation = Isolation.auto
        this.mixBlendMode = CSSBlendMode.normal
    }

    fun copy(): Style {
       return Style(
            specifiedFlags = specifiedFlags,
            fill = fill,
            fillRule = fillRule,
            fillOpacity = fillOpacity,
            stroke = stroke,
            strokeOpacity = strokeOpacity,
            strokeWidth = strokeWidth,
            strokeLineCap = strokeLineCap,
            strokeLineJoin = strokeLineJoin,
            strokeMiterLimit = strokeMiterLimit,
            strokeDashArray = strokeDashArray?.clone(),
            strokeDashOffset = strokeDashOffset,
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
            fontVariationSettings = CSSFontVariationSettings(fontVariationSettings),
            writingMode = writingMode,
            glyphOrientationVertical = glyphOrientationVertical,
            textOrientation = textOrientation,
            letterSpacing = letterSpacing,
            wordSpacing = wordSpacing,
        )
    }

    override fun toString(): String {
        return buildString {
            append("Style(specifiedFlags=")
            append(specifiedFlags)
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
            append(", letterSpacing=")
            append(letterSpacing)
            append(", wordSpacing=")
            append(wordSpacing)
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
        const val SPECIFIED_FILTER: Long = 1L shl 55
        const val SPECIFIED_FLOOD_COLOR: Long = 1L shl 56
        const val SPECIFIED_FLOOD_OPACITY: Long = 1L shl 57

        // Flags for the settings that are applied to reset the root style
        private const val SPECIFIED_RESET: Long = -1L


        fun getDefaultStyle(): Style {
            val def = Style()

            def.fill = ColorValue.BLACK
            def.fillRule = FillRule.NonZero
            def.fillOpacity = 1f
            def.stroke = null // none
            def.strokeOpacity = 1f
            def.strokeWidth = CSSLength(1f)
            def.strokeLineCap = LineCap.Butt
            def.strokeLineJoin = LineJoin.Miter
            def.strokeMiterLimit = 4f
            def.strokeDashArray = null
            def.strokeDashOffset = CSSLength.ZERO
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
            def.overflow =
                true // Overflow shown/visible for root, but not for other elements (see section 14.3.3).
            def.clip = null
            def.markerStart = null
            def.markerMid = null
            def.markerEnd = null
            def.display = true
            def.visibility = true
            def.stopColor = ColorValue.BLACK
            def.stopOpacity = 1f
            def.clipPath = null
            def.clipRule = FillRule.NonZero
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
            def.fontVariationSettings.addSetting(
                CSSFontVariationSettings.VARIATION_WEIGHT,
                FONT_WEIGHT_NORMAL
            )
            def.fontVariationSettings.addSetting(
                CSSFontVariationSettings.VARIATION_WIDTH,
                FONT_WIDTH_NORMAL
            )
            def.letterSpacing = CSSLength.ZERO
            def.wordSpacing = CSSLength.ZERO
            def.writingMode = WritingMode.horizontal_tb
            def.glyphOrientationVertical = GlypOrientationVertical.auto
            def.textOrientation = TextOrientation.mixed

            def.specifiedFlags = SPECIFIED_RESET

            //def.inheritFlags = 0;
            return def
        }


        fun processStyleProperty(
            style: Style,
            localName: String?,
            value: String,
            isFromAttribute: Boolean
        ) {
            if (value.isEmpty()) { // The spec doesn't say how to handle empty style attributes.
                return  // Our strategy is just to ignore them.
            }
            if (value == "inherit") return

            when (SVGAttr.fromString(localName)) {
                SVGAttr.fill -> {
                    val fill = parsePaintSpecifier(value)
                    style.fill = fill
                    style.addSpecifiedFlag(SPECIFIED_FILL)
                }

                SVGAttr.fill_rule -> {
                    val fillRule = parseFillRule(value)
                    style.fillRule = fillRule
                    if (fillRule != null) style.addSpecifiedFlag(SPECIFIED_FILL_RULE)
                }

                SVGAttr.fill_opacity -> {
                    val fillOpacity = parseOpacity(value)
                    style.fillOpacity = fillOpacity
                    style.addSpecifiedFlag(SPECIFIED_FILL_OPACITY)
                }

                SVGAttr.stroke -> {
                    val stroke = parsePaintSpecifier(value)
                    style.stroke = stroke
                    style.addSpecifiedFlag(SPECIFIED_STROKE)
                }

                SVGAttr.stroke_opacity -> {
                    val strokeOpacity = parseOpacity(value)
                    style.strokeOpacity = strokeOpacity
                    style.addSpecifiedFlag(SPECIFIED_STROKE_OPACITY)
                }

                SVGAttr.stroke_width -> try {
                    val strokeWidth = parseLength(value)
                    style.strokeWidth = strokeWidth
                    style.addSpecifiedFlag(SPECIFIED_STROKE_WIDTH)
                } catch (_: SVGParseException) {
                    // Do nothing
                }

                SVGAttr.stroke_linecap -> {
                    val strokeLineCap = parseStrokeLineCap(value)
                    style.strokeLineCap = strokeLineCap
                    if (strokeLineCap != null) style.addSpecifiedFlag(SPECIFIED_STROKE_LINECAP)
                }

                SVGAttr.stroke_linejoin -> {
                    val strokeLineJoin = parseStrokeLineJoin(value)
                    style.strokeLineJoin = strokeLineJoin
                    if (strokeLineJoin != null) style.addSpecifiedFlag(SPECIFIED_STROKE_LINEJOIN)
                }

                SVGAttr.stroke_miterlimit -> try {
                    val strokeMiterLimit = parseFloat(value)
                    style.strokeMiterLimit = strokeMiterLimit
                    style.addSpecifiedFlag(SPECIFIED_STROKE_MITERLIMIT)
                } catch (_: SVGParseException) {
                    // Do nothing
                }

                SVGAttr.stroke_dasharray -> {
                    if (SVGParserImpl.NONE == value) {
                        style.strokeDashArray = null
                        style.addSpecifiedFlag(SPECIFIED_STROKE_DASHARRAY)
                    } else {
                        val strokeDashArray = parseStrokeDashArray(value)
                        style.strokeDashArray = strokeDashArray
                        if (strokeDashArray != null) style.addSpecifiedFlag(SPECIFIED_STROKE_DASHARRAY)
                    }
                }

                SVGAttr.stroke_dashoffset -> try {
                    val strokeDashOffset = parseLength(value)
                    style.strokeDashOffset = strokeDashOffset
                    style.addSpecifiedFlag(SPECIFIED_STROKE_DASHOFFSET)
                } catch (_: SVGParseException) {
                    // Do nothing
                }

                SVGAttr.opacity -> {
                    val opacity = parseOpacity(value)
                    style.opacity = opacity ?: 1f
                    style.addSpecifiedFlag(SPECIFIED_OPACITY)
                }

                SVGAttr.color -> {
                    val color = parseColor(value)
                    style.color = color
                    style.addSpecifiedFlag(SPECIFIED_COLOR)
                }

                SVGAttr.font -> {
                    if (!isFromAttribute) {
                        parseFont(style, value)
                    }
                }

                SVGAttr.font_family -> {
                    val fontFamily = parseFontFamily(value)
                    style.fontFamily = fontFamily
                    if (fontFamily != null) style.addSpecifiedFlag(SPECIFIED_FONT_FAMILY)
                }

                SVGAttr.font_size -> {
                    val fontSize = parseFontSize(value)
                    style.fontSize = fontSize
                    if (fontSize != null) style.addSpecifiedFlag(SPECIFIED_FONT_SIZE)
                }

                SVGAttr.font_weight -> {
                    val fontWeight = parseFontWeight(value)
                    style.fontWeight = fontWeight
                    if (fontWeight != null) {
                        style.addSpecifiedFlag(SPECIFIED_FONT_WEIGHT)
                        // Also mirror that setting in the font-variation-settings
                        style.fontVariationSettings.addSetting(CSSFontVariationSettings.VARIATION_WEIGHT, fontWeight)
                        style.addSpecifiedFlag(SPECIFIED_FONT_VARIATION_SETTINGS)
                    }
                }

                SVGAttr.font_style -> {
                    val fontStyle = parseFontStyle(value) // FIXME support oblique-with-angle
                    style.fontStyle = fontStyle
                    if (fontStyle != null) {
                        style.addSpecifiedFlag(SPECIFIED_FONT_STYLE)
                        // Also mirror that setting in the font-variation-settings.
                        // This can cause double slant with italic fonts.
                        // FIXME *************************
                        if (fontStyle == FontStyle.italic || fontStyle == FontStyle.oblique) {
                            // The CSS spec states: If no italic or oblique face is available, oblique faces may be
                            // synthesized by rendering non-obliqued faces with an artificial obliging operation.
                            // Based on that sentiment, we choose to attempt to enable both italics and slant.
                            // Note that Android does not provide a way to query the available axes of a font, so
                            // we just have to turn both on and hope we don't get weird results if the font supports
                            // both axes.  I haven't seen one that does.
                            style.fontVariationSettings.addSetting(
                                CSSFontVariationSettings.VARIATION_ITALIC,
                                CSSFontVariationSettings.VARIATION_ITALIC_VALUE_ON
                            )
                            style.addSpecifiedFlag(SPECIFIED_FONT_VARIATION_SETTINGS)

                            style.fontVariationSettings.addSetting(
                                CSSFontVariationSettings.VARIATION_SLANT,
                                CSSFontVariationSettings.VARIATION_OBLIQUE_VALUE_ON
                            )
                            style.addSpecifiedFlag(SPECIFIED_FONT_VARIATION_SETTINGS)
                        }
                    }
                }

                SVGAttr.font_stretch, SVGAttr.font_width -> {
                    val fontWidth = parseFontWidth(value)
                    style.fontWidth = fontWidth
                    if (fontWidth != null) {
                        style.addSpecifiedFlag(SPECIFIED_FONT_WIDTH)
                        // Also mirror that setting in the font-variation-settings
                        style.fontVariationSettings.addSetting(CSSFontVariationSettings.VARIATION_WIDTH, fontWidth)
                        style.addSpecifiedFlag(SPECIFIED_FONT_VARIATION_SETTINGS)
                    }
                }

                SVGAttr.text_decoration -> {
                    val textDecoration = parseTextDecoration(value)
                    style.textDecoration = textDecoration
                    if (textDecoration != null) style.addSpecifiedFlag(SPECIFIED_TEXT_DECORATION)
                }

                SVGAttr.direction -> {
                    val direction = parseTextDirection(value)
                    style.direction = direction
                    if (direction != null) style.addSpecifiedFlag(SPECIFIED_DIRECTION)
                }

                SVGAttr.text_anchor -> {
                    val textAnchor = parseTextAnchor(value)
                    style.textAnchor = textAnchor
                    if (textAnchor != null) style.addSpecifiedFlag(SPECIFIED_TEXT_ANCHOR)
                }

                SVGAttr.overflow -> {
                    val overflow = parseOverflow(value)
                    style.overflow = overflow
                    if (overflow != null) style.addSpecifiedFlag(SPECIFIED_OVERFLOW)
                }

                SVGAttr.marker -> {
                    val functionalIRI = parseFunctionalIRI(value, localName)
                    style.markerStart = functionalIRI
                    style.markerMid = functionalIRI
                    style.markerEnd = functionalIRI
                    if (functionalIRI != null) {
                        style.addSpecifiedFlag(SPECIFIED_MARKER_START or SPECIFIED_MARKER_MID or SPECIFIED_MARKER_END)
                    }
                }

                SVGAttr.marker_start -> {
                    val markerStart = parseFunctionalIRI(value, localName)
                    style.markerStart = markerStart
                    if (markerStart != null) style.addSpecifiedFlag(SPECIFIED_MARKER_START)
                }

                SVGAttr.marker_mid -> {
                    val markerMid = parseFunctionalIRI(value, localName)
                    style.markerMid = markerMid
                    if (markerMid != null) style.addSpecifiedFlag(SPECIFIED_MARKER_MID)
                }

                SVGAttr.marker_end -> {
                    val markerEnd = parseFunctionalIRI(value, localName)
                    style.markerEnd = markerEnd
                    if (markerEnd != null) style.addSpecifiedFlag(SPECIFIED_MARKER_END)
                }

                SVGAttr.display -> {
                    if (!value.contains('|') && SVGParserImpl.VALID_DISPLAY_VALUES.contains("|$value|")) {
                        val display = value != SVGParserImpl.NONE
                        style.display = display
                        style.addSpecifiedFlag(SPECIFIED_DISPLAY)
                    }
                }

                SVGAttr.visibility -> {
                    if (!value.contains('|') && SVGParserImpl.VALID_VISIBILITY_VALUES.contains("|$value|")) {
                        val visibility = value == "visible"
                        style.visibility = visibility
                        style.addSpecifiedFlag(SPECIFIED_VISIBILITY)
                    }
                }

                SVGAttr.stop_color -> {
                    val stopColor = if (value == SVGParserImpl.CURRENT_COLOR) CurrentColor else parseColor(value)
                    style.stopColor = stopColor
                    style.addSpecifiedFlag(SPECIFIED_STOP_COLOR)
                }

                SVGAttr.stop_opacity -> {
                    val stopOpacity = parseOpacity(value)
                    style.stopOpacity = stopOpacity
                    style.addSpecifiedFlag(SPECIFIED_STOP_OPACITY)
                }

                SVGAttr.clip -> {
                    val clip = parseClip(value)
                    style.clip = clip
                    if (clip != null) style.addSpecifiedFlag(SPECIFIED_CLIP)
                }

                SVGAttr.clip_path -> {
                    val clipPath = parseFunctionalIRI(value, localName)
                    style.clipPath = clipPath
                    if (clipPath != null) style.addSpecifiedFlag(SPECIFIED_CLIP_PATH)
                }

                SVGAttr.clip_rule -> {
                    val clipRule = parseFillRule(value)
                    style.clipRule = clipRule
                    if (clipRule != null) style.addSpecifiedFlag(SPECIFIED_CLIP_RULE)
                }

                SVGAttr.mask -> {
                    val mask = parseFunctionalIRI(value, localName)
                    style.mask = mask
                    if (mask != null) style.addSpecifiedFlag(SPECIFIED_MASK)
                }

                SVGAttr.mask_type -> {
                    val maskType = MaskType.fromString(value)
                    style.maskType = maskType
                    if (maskType != null) style.addSpecifiedFlag(SPECIFIED_MASK_TYPE)
                }

                SVGAttr.filter -> {
                    val filter = parseFunctionalIRI(value, localName)
                    style.filter = filter
                    if (filter != null) style.addSpecifiedFlag(SPECIFIED_FILTER)
                }

                SVGAttr.flood_color -> {
                    val floodColor = if (value == SVGParserImpl.CURRENT_COLOR) CurrentColor else parseColor(value)
                    style.floodColor = floodColor
                    style.addSpecifiedFlag(SPECIFIED_FLOOD_COLOR)
                }

                SVGAttr.flood_opacity -> {
                    val floodOpacity = parseOpacity(value)
                    style.floodOpacity = floodOpacity
                    style.addSpecifiedFlag(SPECIFIED_FLOOD_OPACITY)
                }

                SVGAttr.solid_color -> {
                    // SVG 1.2 Tiny
                    if (isFromAttribute) {
                        val solidColor = if (value == SVGParserImpl.CURRENT_COLOR) CurrentColor else parseColor(value)
                        style.solidColor = solidColor
                        style.addSpecifiedFlag(SPECIFIED_SOLID_COLOR)
                    }
                }

                SVGAttr.solid_opacity -> {
                    // SVG 1.2 Tiny
                    if (isFromAttribute) {
                        val solidOpacity = parseOpacity(value)
                        style.solidOpacity = solidOpacity
                        style.addSpecifiedFlag(SPECIFIED_SOLID_OPACITY)
                    }
                }

                SVGAttr.viewport_fill -> {
                    // SVG 1.2 Tiny
                    val viewportFill = if (value == SVGParserImpl.CURRENT_COLOR) CurrentColor else parseColor(value)
                    style.viewportFill = viewportFill
                    style.addSpecifiedFlag(SPECIFIED_VIEWPORT_FILL)
                }

                SVGAttr.viewport_fill_opacity -> {
                    // SVG 1.2 Tiny
                    val viewportFillOpacity = parseOpacity(value)
                    style.viewportFillOpacity = viewportFillOpacity
                    style.addSpecifiedFlag(SPECIFIED_VIEWPORT_FILL_OPACITY)
                }

                SVGAttr.vector_effect -> {
                    val vectorEffect = parseVectorEffect(value)
                    style.vectorEffect = vectorEffect
                    if (vectorEffect != null) style.addSpecifiedFlag(SPECIFIED_VECTOR_EFFECT)
                }

                SVGAttr.image_rendering -> {
                    val imageRendering = parseRenderQuality(value)
                    style.imageRendering = imageRendering
                    if (imageRendering != null) style.addSpecifiedFlag(SPECIFIED_IMAGE_RENDERING)
                }

                SVGAttr.isolation -> {
                    if (!isFromAttribute) {
                        val isolation = parseIsolation(value)
                        style.isolation = isolation
                        if (isolation != null) style.addSpecifiedFlag(SPECIFIED_ISOLATION)
                    }
                }

                SVGAttr.mix_blend_mode -> {
                    if (!isFromAttribute) {
                        val mixBlendMode = CSSBlendMode.fromString(value)
                        style.mixBlendMode = mixBlendMode
                        style.addSpecifiedFlag(SPECIFIED_MIX_BLEND_MODE)
                    }
                }

                SVGAttr.font_kerning -> {
                    if (!isFromAttribute) {
                        val fontKerning = CSSFontFeatureSettings.parseFontKerning(value)
                        style.fontKerning = fontKerning
                        if (fontKerning != null) style.addSpecifiedFlag(SPECIFIED_FONT_KERNING)
                    }
                }

                SVGAttr.font_variant -> {
                    if (!isFromAttribute) {
                        CSSFontFeatureSettings.parseFontVariant(style, value)
                    }
                }

                SVGAttr.font_variant_ligatures -> {
                    if (!isFromAttribute) {
                        val fontVariantLigatures = CSSFontFeatureSettings.parseVariantLigatures(value)
                        style.fontVariantLigatures = fontVariantLigatures
                        if (fontVariantLigatures != null) style.addSpecifiedFlag(SPECIFIED_FONT_VARIANT_LIGATURES)
                    }
                }

                SVGAttr.font_variant_position -> {
                    if (!isFromAttribute) {
                        val fontVariantPosition = CSSFontFeatureSettings.parseVariantPosition(value)
                        style.fontVariantPosition = fontVariantPosition
                        if (fontVariantPosition != null) style.addSpecifiedFlag(SPECIFIED_FONT_VARIANT_POSITION)
                    }
                }

                SVGAttr.font_variant_caps -> {
                    if (!isFromAttribute) {
                        val fontVariantCaps = CSSFontFeatureSettings.parseVariantCaps(value)
                        style.fontVariantCaps = fontVariantCaps
                        if (fontVariantCaps != null) style.addSpecifiedFlag(SPECIFIED_FONT_VARIANT_CAPS)
                    }
                }

                SVGAttr.font_variant_numeric -> {
                    if (!isFromAttribute) {
                        val fontVariantNumeric = CSSFontFeatureSettings.parseVariantNumeric(value)
                        style.fontVariantNumeric = fontVariantNumeric
                        if (fontVariantNumeric != null) style.addSpecifiedFlag(SPECIFIED_FONT_VARIANT_NUMERIC)
                    }
                }

                SVGAttr.font_variant_east_asian -> {
                    if (!isFromAttribute) {
                        val fontVariantEastAsian = CSSFontFeatureSettings.parseEastAsian(value)
                        style.fontVariantEastAsian = fontVariantEastAsian
                        if (fontVariantEastAsian != null) style.addSpecifiedFlag(SPECIFIED_FONT_VARIANT_EAST_ASIAN)
                    }
                }

                SVGAttr.font_feature_settings -> {
                    if (!isFromAttribute) {
                        val fontFeatureSettings = CSSFontFeatureSettings.parseFontFeatureSettings(value)
                        style.fontFeatureSettings = fontFeatureSettings
                        if (fontFeatureSettings != null) style.addSpecifiedFlag(SPECIFIED_FONT_FEATURE_SETTINGS)
                    }
                }

                SVGAttr.font_variation_settings -> {
                    if (!isFromAttribute) {
                        val fvs = CSSFontVariationSettings.parseFontVariationSettings(value)
                        if (fvs != null) {
                            style.fontVariationSettings.applySettings(fvs)
                            style.addSpecifiedFlag(SPECIFIED_FONT_VARIATION_SETTINGS)
                        }
                    }
                }

                SVGAttr.letter_spacing -> {
                    val letterSpacing = parseLetterOrWordSpacing(value)
                    style.letterSpacing = letterSpacing
                    if (letterSpacing != null) style.addSpecifiedFlag(SPECIFIED_LETTER_SPACING)
                }

                SVGAttr.word_spacing -> {
                    val wordSpacing = parseLetterOrWordSpacing(value)
                    style.wordSpacing = wordSpacing
                    if (wordSpacing != null) style.addSpecifiedFlag(SPECIFIED_WORD_SPACING)
                }

                else -> {}
            }
        }
    }
}
