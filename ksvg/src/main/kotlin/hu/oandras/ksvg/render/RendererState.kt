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

package hu.oandras.ksvg.render

import android.graphics.DashPathEffect
import android.graphics.Paint
import android.graphics.Path
import android.graphics.Typeface
import hu.oandras.ksvg.css.CSSFontFeatureSettings
import hu.oandras.ksvg.css.CSSFontVariationSettings
import hu.oandras.ksvg.css.CSSLength
import hu.oandras.ksvg.dom.core.Box
import hu.oandras.ksvg.dom.style.FillRule
import hu.oandras.ksvg.dom.style.Style
import hu.oandras.ksvg.dom.style.SvgPaint
import hu.oandras.ksvg.render.pool.FloatArrayBucket

internal class RendererState private constructor(
    @JvmField
    var style: Style,

    @JvmField
    var hasFill: Boolean,

    @JvmField
    var hasStroke: Boolean,

    @JvmField
    internal var viewPort: Box?,

    @JvmField
    internal var viewBox: Box?,

    @JvmField
    var spacePreserve: Boolean,

    @JvmField
    var contextStroke: SvgPaint?,

    @JvmField
    var contextFill: SvgPaint?,

    fontFeatureSet: CSSFontFeatureSettings,
    fontVariationSet: CSSFontVariationSettings,
) {

    private var fillPaintDirty = false
    private val _fillPaint: Paint = Paint().apply {
        flags = Paint.ANTI_ALIAS_FLAG or Paint.LINEAR_TEXT_FLAG or Paint.SUBPIXEL_TEXT_FLAG
        hinting = Paint.HINTING_OFF
        style = Paint.Style.FILL
        setTypeface(Typeface.DEFAULT)
    }

    val fillPaint: Paint
        get() {
            fillPaintDirty = true
            return _fillPaint
        }

    private var strokePaintDirty = false
    private val _strokePaint: Paint = Paint().apply {
        flags = Paint.ANTI_ALIAS_FLAG or Paint.LINEAR_TEXT_FLAG or Paint.SUBPIXEL_TEXT_FLAG
        hinting = Paint.HINTING_OFF
        style = Paint.Style.STROKE
        setTypeface(Typeface.DEFAULT)
    }

    val strokePaint: Paint
        get() {
            strokePaintDirty = true
            return _strokePaint
        }

    private var _fontFeatureSet: CSSFontFeatureSettings = fontFeatureSet
    private var _fontFeatureSetBuilder: CSSFontFeatureSettings.Builder? = null

    var fontFeatureSet: CSSFontFeatureSettings
        get() = _fontFeatureSetBuilder?.build() ?: _fontFeatureSet
        set(value) {
            _fontFeatureSet = value
            _fontFeatureSetBuilder?.reset(value)
        }

    fun getFontFeatureSetBuilder(): CSSFontFeatureSettings.Builder {
        var b = _fontFeatureSetBuilder
        if (b == null) {
            b = _fontFeatureSet.toBuilder()
            _fontFeatureSetBuilder = b
        }
        return b
    }

    private var _fontVariationSet: CSSFontVariationSettings = fontVariationSet
    private var _fontVariationSetBuilder: CSSFontVariationSettings.Builder? = null

    var fontVariationSet: CSSFontVariationSettings
        get() = _fontVariationSetBuilder?.build() ?: _fontVariationSet
        set(value) {
            _fontVariationSet = value
            _fontVariationSetBuilder?.reset(value)
        }

    fun getFontVariationSetBuilder(): CSSFontVariationSettings.Builder {
        var b = _fontVariationSetBuilder
        if (b == null) {
            b = _fontVariationSet.toBuilder()
            _fontVariationSetBuilder = b
        }
        return b
    }

    @JvmField
    val dashIntervalBuffer = FloatArrayBucket()

    @JvmField
    val textWidthBuffer = FloatArrayBucket()

    // Scale applied to stroke-dasharray / dashoffset when the shape declares a
    // `pathLength`. Computed from (actual path length / declared pathLength).
    @JvmField
    var dashLengthScale: Float = 1f

    // Last values written to these paints by the font styler. Some OEM ROMs
    // (OnePlus PaintExtImpl.replaceTypeface) hook paint setters and allocate on
    // EVERY call even for unchanged values, so callers skip redundant writes
    // using these caches instead of reading them back from Paint.
    @JvmField
    internal var appliedTypeface: Typeface? = null
    @JvmField
    internal var appliedFontVariationSettings: String? = null
    @JvmField
    internal var appliedFontFeatureSettings: String? = null
    @JvmField
    internal var appliedWordSpacing: Float = Float.NaN

    private var lastDashIntervals: FloatArray? = null
    private var lastDashOffset: Float = 0f
    private var lastPathEffect: DashPathEffect? = null

    fun resetDashCache() {
        lastDashIntervals = null
        lastDashOffset = 0f
        lastPathEffect = null
    }

    val fillType: Path.FillType
        get() {
            return if (style.fillRule == FillRule.EvenOdd) {
                Path.FillType.EVEN_ODD
            } else {
                Path.FillType.WINDING
            }
        }

    val clipRule: Path.FillType
        get() {
            return if (style.clipRule == FillRule.EvenOdd) {
                Path.FillType.EVEN_ODD
            } else {
                Path.FillType.WINDING
            }
        }

    internal constructor() : this(
        style = Style.getDefaultStyle(),
        hasFill = false,
        hasStroke = false,
        viewPort = null,
        viewBox = null,
        spacePreserve = false,
        contextStroke = null,
        contextFill = null,

        fontFeatureSet = CSSFontFeatureSettings.EMPTY,
        fontVariationSet = CSSFontVariationSettings.EMPTY,
    )

    fun apply(other: RendererState) {
        hasFill = other.hasFill
        hasStroke = other.hasStroke

        if (!fillPaintDirty && !other.fillPaintDirty) {
            // ignore
        } else {
            fillPaintDirty = other.fillPaintDirty
            fillPaint.set(other.fillPaint)
        }

        if (!strokePaintDirty && !other.strokePaintDirty) {
            // ignore
        } else {
            strokePaintDirty = other.strokePaintDirty
            strokePaint.set(other.strokePaint)
        }

        appliedTypeface = null
        appliedFontVariationSettings = null
        appliedFontFeatureSettings = null
        appliedWordSpacing = Float.NaN

        viewPort = other.viewPort
        viewBox = other.viewBox
        spacePreserve = other.spacePreserve
        fontFeatureSet = other.fontFeatureSet
        fontVariationSet = other.fontVariationSet
        style = other.style
        contextStroke = other.contextStroke
        contextFill = other.contextFill
        resetDashCache()
    }

    override fun toString(): String {
        return "RendererState(style=$style, hasFill=$hasFill, hasStroke=$hasStroke, viewPort=$viewPort, viewBox=$viewBox, spacePreserve=$spacePreserve, fillPaint=$fillPaint, strokePaint=$strokePaint, fontFeatureSet=$fontFeatureSet, fontVariationSet=$fontVariationSet)"
    }

    context(renderContext: RenderContext)
    internal fun updateStrokeDash(
        strokeDashArray: Array<CSSLength>? = style.strokeDashArray,
        strokeDashOffset: CSSLength? = style.strokeDashOffset,
        strokeDashArrayResolved: FloatArray? = style.strokeDashArrayResolved,
        strokeDashOffsetResolved: Float = style.strokeDashOffsetResolved,
    ) {
        strokePaint.pathEffect = if (strokeDashArrayResolved == null && strokeDashArray == null) {
            lastDashIntervals = null
            lastPathEffect = null
            null
        } else {
            var intervalSum = 0f
            val n = strokeDashArrayResolved?.size ?: strokeDashArray?.size ?: 0
            val arrayLen = if (n % 2 == 0) n else n * 2
            val intervals = dashIntervalBuffer.getWithSize(arrayLen)
            
            if (strokeDashArrayResolved != null) {
                for (i in 0 until arrayLen) {
                    val interval = strokeDashArrayResolved[i % n]
                    intervals[i] = interval
                    intervalSum += interval
                }
            } else if (strokeDashArray != null) {
                for (i in 0 until arrayLen) {
                    val interval = strokeDashArray[i % n].floatValueInContext()
                    intervals[i] = interval
                    intervalSum += interval
                }
            }

            if (dashLengthScale != 1f) {
                for (i in 0 until arrayLen) {
                    intervals[i] *= dashLengthScale
                }
                intervalSum *= dashLengthScale
            }

            if (intervalSum == 0f) {
                lastDashIntervals = null
                lastPathEffect = null
                null
            } else {
                var offset = if (!strokeDashOffsetResolved.isNaN()) {
                    strokeDashOffsetResolved
                } else {
                    strokeDashOffset?.floatValueInContext() ?: 0f
                }

                if (dashLengthScale != 1f) {
                    offset *= dashLengthScale
                }
                
                if (offset < 0) {
                    offset = intervalSum + offset % intervalSum
                }

                val lastIntervals = lastDashIntervals
                if (lastIntervals != null && offset == lastDashOffset && lastIntervals.contentEquals(intervals)) {
                    lastPathEffect
                } else if (lastIntervals != null && lastIntervals.contentEquals(intervals)) {
                    val pathEffect = DashPathEffect(lastIntervals, offset)
                    lastDashOffset = offset
                    lastPathEffect = pathEffect
                    pathEffect
                } else {
                    val pathEffect = DashPathEffect(intervals, offset)
                    lastDashIntervals = intervals.copyOf()
                    lastDashOffset = offset
                    lastPathEffect = pathEffect
                    pathEffect
                }
            }
        }
    }
}
