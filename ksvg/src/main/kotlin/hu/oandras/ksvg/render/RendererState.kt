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

    // The state carries ONLY the paint-driving configuration (plain data).
    // The actual Paint objects live on the RenderNodes and are lazily
    // field-diffed against these configurations right before drawing, so a
    // node whose style did not change performs zero paint writes per frame.

    @JvmField
    internal val fillConfig = PaintConfiguration()

    // apply() memo: last source whose content was copied into fillConfig.
    // Sound because configs only mutate through bumping mutators and pooled
    // states receive configs exclusively via apply().
    @JvmField
    internal var lastFillSource: PaintConfiguration? = null
    @JvmField
    internal var lastFillVersion: Long = -1L
    @JvmField
    internal var lastFillReceiverVersion: Long = -1L

    @JvmField
    internal val strokeConfig = PaintConfiguration()

    // apply() memo for strokeConfig; same contract as lastFillSource.
    @JvmField
    internal var lastStrokeSource: PaintConfiguration? = null
    @JvmField
    internal var lastStrokeVersion: Long = -1L
    @JvmField
    internal var lastStrokeReceiverVersion: Long = -1L

    /**
     * Set by the renderer whenever this state becomes active for a node; the
     * fillPaint/strokePaint getters resolve against this node's paints.
     */
    @JvmField
    internal var paintHost: RenderNode<*>? = null

    // Build-time (host-less) reads fall back to detached paints owned by this
    // state, synced exactly like node paints. These are created on the first
    // host-less read instead of in the constructor: a renderer state is created
    // for every render pass, while the vast majority of them are only ever read
    // with a paint host attached. Constructing an android.graphics.Paint is
    // expensive (on some OEM ROMs it also builds a String cache-key object
    // graph), so paying for two of them eagerly is pure overhead.
    private var detachedFillPaint: Paint? = null
    private var detachedStrokePaint: Paint? = null
    // Last typeface written into each detached paint by syncDetached. A fresh
    // Paint() holds the platform-default null typeface, so the cache starts
    // valid: repeated host-less reads with an unchanged configuration skip the
    // (OEM-hook-tripping) typeface write entirely.
    private var detachedFillTypeface: Typeface? = null
    private var detachedStrokeTypeface: Typeface? = null
    // Last variation/feature settings written into each detached paint. A fresh
    // Paint() holds none, so the caches start at the configuration defaults:
    // repeated host-less reads with an unchanged configuration skip the
    // (OEM-hook-tripping) font writes entirely.
    private var detachedFillVariation: String = ""
    private var detachedFillFeature: String = ""
    private var detachedStrokeVariation: String = ""
    private var detachedStrokeFeature: String = ""

    /** Read access resolves against the active node's lazily-synced paint. */
    val fillPaint: Paint
        get() {
            val host = paintHost
            if (host != null) {
                return host.obtainFillPaint(fillConfig)
            }
            var paint = detachedFillPaint
            if (paint == null) {
                paint = Paint()
                detachedFillPaint = paint
                detachedFillTypeface = null
                detachedFillVariation = ""
                detachedFillFeature = ""
            }
            return syncDetached(paint, fillConfig, detachedFillTypeface, detachedFillVariation, detachedFillFeature).also {
                detachedFillTypeface = fillConfig.typeface
                detachedFillVariation = fillConfig.fontVariationSettings
                detachedFillFeature = fillConfig.fontFeatureSettings
            }
        }

    val strokePaint: Paint
        get() {
            val host = paintHost
            if (host != null) {
                return host.obtainStrokePaint(strokeConfig)
            }
            // The detached stroke paint must be a STROKE-style paint from the
            // start: PaintConfigSync.apply never writes `style`, it only carries
            // the paint-driving configuration.
            var paint = detachedStrokePaint
            if (paint == null) {
                paint = Paint()
                paint.style = Paint.Style.STROKE
                detachedStrokePaint = paint
                detachedStrokeTypeface = null
                detachedStrokeVariation = ""
                detachedStrokeFeature = ""
            }
            return syncDetached(paint, strokeConfig, detachedStrokeTypeface, detachedStrokeVariation, detachedStrokeFeature).also {
                detachedStrokeTypeface = strokeConfig.typeface
                detachedStrokeVariation = strokeConfig.fontVariationSettings
                detachedStrokeFeature = strokeConfig.fontFeatureSettings
            }
        }

    private fun syncDetached(
        paint: Paint,
        cfg: PaintConfiguration,
        knownTypeface: Typeface?,
        knownFontVariation: String,
        knownFontFeature: String,
    ): Paint {
        PaintConfigSync.apply(
            paint,
            cfg,
            knownTypeface,
            knownTypefaceValid = true,
            knownFontVariation,
            knownFontFeature,
        )
        return paint
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
    var dashIntervalBuffer: FloatArrayBucket? = null

    // Scale applied to stroke-dasharray / dashoffset when the shape declares a
    // `pathLength`. Computed from (actual path length / declared pathLength).
    @JvmField
    var dashLengthScale: Float = 1f

    // Last values written to these paints by the font styler. Some OEM ROMs
    // (OnePlus PaintExtImpl.replaceTypeface) hook paint setters and allocate on
    // EVERY call even for unchanged values, so callers skip redundant writes
    // using these caches instead of reading them back from Paint.

    private var lastDashIntervals: FloatArray? = null
    private var lastDashOffset: Float = 0f
    private var lastPathEffect: DashPathEffect? = null

    fun resetDashCache() {
        lastDashIntervals = null
        lastDashOffset = 0f
        lastPathEffect = null
    }

    val fillType: Path.FillType
        get() = if (style.fillRule == FillRule.EVEN_ODD) Path.FillType.EVEN_ODD else Path.FillType.WINDING

    val clipFillType: Path.FillType
        get() = if (style.clipRule == FillRule.EVEN_ODD) Path.FillType.EVEN_ODD else Path.FillType.WINDING

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

        // Config copy only: the paints are re-synced lazily on next read.
        // Version-gated: configs only mutate through bumping mutators
        // (audit: no direct field writes), so (same source identity +
        // unchanged source version + untouched receiver) implies the receiver
        // already holds this content. The receiver check matters: render-time
        // style resolution (updateStyleForElement) tweaks pooled working
        // states' configs directly between applies.
        val srcFill = other.fillConfig
        if (lastFillSource !== srcFill || lastFillVersion != srcFill.version ||
            lastFillReceiverVersion != fillConfig.version
        ) {
            fillConfig.setFrom(srcFill)
            lastFillSource = srcFill
            lastFillVersion = srcFill.version
            lastFillReceiverVersion = fillConfig.version
        }
        val srcStroke = other.strokeConfig
        if (lastStrokeSource !== srcStroke || lastStrokeVersion != srcStroke.version ||
            lastStrokeReceiverVersion != strokeConfig.version
        ) {
            strokeConfig.setFrom(srcStroke)
            lastStrokeSource = srcStroke
            lastStrokeVersion = srcStroke.version
            lastStrokeReceiverVersion = strokeConfig.version
        }

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
        return "RendererState(style=$style, hasFill=$hasFill, hasStroke=$hasStroke, viewPort=$viewPort, viewBox=$viewBox, spacePreserve=$spacePreserve, fontFeatureSet=$fontFeatureSet, fontVariationSet=$fontVariationSet)"
    }

    context(renderContext: DisplayContext)
    internal fun updateStrokeDash(
        strokeDashArray: Array<CSSLength>? = style.strokeDashArray,
        strokeDashOffset: CSSLength? = style.strokeDashOffset,
        strokeDashArrayResolved: FloatArray? = style.strokeDashArrayResolved,
        strokeDashOffsetResolved: Float = style.strokeDashOffsetResolved,
    ) {
        strokeConfig.setPathEffect(if (strokeDashArrayResolved == null && strokeDashArray == null) {
            lastDashIntervals = null
            lastPathEffect = null
            null
        } else {
            var intervalSum = 0f
            val n = strokeDashArrayResolved?.size ?: strokeDashArray?.size ?: 0
            val arrayLen = if (n % 2 == 0) n else n * 2
            val intervals = (dashIntervalBuffer
                ?: FloatArrayBucket().also { dashIntervalBuffer = it }).getWithSize(arrayLen)
            
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
        })
    }
}
