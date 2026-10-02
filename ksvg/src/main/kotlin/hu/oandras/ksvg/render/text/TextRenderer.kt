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

import android.annotation.SuppressLint
import android.graphics.Canvas
import android.graphics.Matrix
import android.graphics.Paint
import android.graphics.Path
import android.graphics.Rect
import android.graphics.RectF
import hu.oandras.ksvg.dom.style.Style
import hu.oandras.ksvg.dom.style.WritingMode
import hu.oandras.ksvg.dom.style.isVertical
import hu.oandras.ksvg.dom.text.BaselineShift
import hu.oandras.ksvg.dom.text.DominantBaseline
import hu.oandras.ksvg.dom.text.TextAnchor
import hu.oandras.ksvg.dom.text.TextContainer
import hu.oandras.ksvg.dom.text.TextDirection
import hu.oandras.ksvg.dom.text.TextOrientation
import hu.oandras.ksvg.dom.text.TextTransform
import hu.oandras.ksvg.render.DisplayContext
import hu.oandras.ksvg.render.RenderContext
import hu.oandras.ksvg.render.RendererState
import hu.oandras.ksvg.render.TRefRenderNode
import hu.oandras.ksvg.render.TSpanRenderNode
import hu.oandras.ksvg.render.TextNode
import hu.oandras.ksvg.render.TextPathRenderNode
import hu.oandras.ksvg.render.TextSequenceNode
import hu.oandras.ksvg.render.pool.FloatArrayBucket
import hu.oandras.ksvg.render.pool.PoolOwner
import hu.oandras.ksvg.render.pool.withPooledObject
import hu.oandras.ksvg.utils.capitalizeStr
import hu.oandras.ksvg.utils.forEachElement
import hu.oandras.ksvg.utils.toRadians
import java.util.*
import kotlin.math.cos
import kotlin.math.sin

internal abstract class TextProcessor {
    @JvmField
    var x: Float = 0f
    @JvmField
    var y: Float = 0f
    // Supplemental per-character rotation in degrees (SVG `rotate`); summed
    // across positioning levels like dx/dy, missing values count as 0.
    // Advances are unaffected (rotation never bends the baseline).
    @JvmField
    var rotation: Float = 0f

    // Extra advance per character from SVG `textLength` (lengthAdjust=spacing
    // only): (target - measured) / charCount, set while traversing the
    // element carrying textLength, restored afterward. Nested textLengths
    // override for their subtree (single-level layouts are exact).
    @JvmField
    var spacingAdjust: Float = 0f

    // Uniform horizontal glyph scale from `textLength` with
    // lengthAdjust="spacingAndGlyphs": target / measured (1 = off). Advances
    // scale with the glyphs, so the run sums to the target exactly.
    @JvmField
    var glyphScale: Float = 1f

    private val positioningStack: MutableList<TextPositioning> = mutableListOf()

    fun pushPositioning(x: FloatArray?, y: FloatArray?, dx: FloatArray?, dy: FloatArray?, rotate: FloatArray?) {
        positioningStack.add(TextPositioning(x, y, dx, dy, rotate))
    }

    fun popPositioning() {
        if (positioningStack.isNotEmpty()) {
            positioningStack.removeAt(positioningStack.size - 1)
        }
    }

    protected fun hasPositioning(): Boolean {
        positioningStack.forEachElement { p ->
            if (p.hasPending()) return true
        }
        return false
    }

    protected fun applyPositioning() {
        // Primitive locals: Float? would box every assignment on this hot path.
        var absX = Float.NaN
        var absY = Float.NaN

        for (i in positioningStack.size - 1 downTo 0) {
            val p = positioningStack[i]
            if (absX.isNaN() && p.x != null && p.index < p.x.size) {
                absX = p.x[p.index]
            }
            if (absY.isNaN() && p.y != null && p.index < p.y.size) {
                absY = p.y[p.index]
            }
        }

        var relX = 0f
        var relY = 0f
        var rotation = 0f
        positioningStack.forEachElement { p ->
            if (p.dx != null && p.index < p.dx.size) {
                relX += p.dx[p.index]
            }
            if (p.dy != null && p.index < p.dy.size) {
                relY += p.dy[p.index]
            }
            if (p.rotate != null && p.index < p.rotate.size) {
                rotation += p.rotate[p.index]
            }
            p.index++
        }

        if (!absX.isNaN()) x = absX
        if (!absY.isNaN()) y = absY
        x += relX
        y += relY
        this.rotation = rotation
    }

    open fun doTextContainer(obj: TextContainer): Boolean {
        return true
    }

    context(renderContext: DisplayContext)
    abstract fun processText(canvas: Canvas, text: String, widths: FloatArrayBucket)
}

private class TextPositioning(
    @JvmField
    val x: FloatArray?,
    @JvmField
    val y: FloatArray?,
    @JvmField
    val dx: FloatArray?,
    @JvmField
    val dy: FloatArray?,
    @JvmField
    val rotate: FloatArray?
) {
    @JvmField
    var index = 0

    fun hasPending(): Boolean {
        return (x != null && index < x.size) ||
                (y != null && index < y.size) ||
                (dx != null && index < dx.size) ||
                (dy != null && index < dy.size) ||
                (rotate != null && index < rotate.size)
    }
}

internal fun RendererState.getAnchorPosition(): TextAnchor? {    val style = this.style
    val textAnchor = style.textAnchor

    if (style.direction == TextDirection.LTR || textAnchor == TextAnchor.Middle) {
        return textAnchor
    }

    // Handle RTL case where Start and End are reversed
    return if (textAnchor == TextAnchor.Start) {
        TextAnchor.End
    } else {
        TextAnchor.Start
    }
}

/** Character count of a text subtree (textLength distributes over these). */
internal fun countTextChars(children: List<TextNode>): Int {
    var count = 0
    children.forEachElement { child ->
        count += when (child) {
            is TextSequenceNode -> child.text.length
            is TSpanRenderNode -> countTextChars(child.children)
            is TRefRenderNode -> child.text.length
            else -> 0
        }
    }
    return count
}

/**
 * Per-character spacing adjustment for `textLength` (spacing mode):
 * (target - natural) / chars, or 0 when inactive/degenerate. Callers save,
 * set, traverse, and restore [TextProcessor.spacingAdjust] around it.
 */
internal fun spacingAdjustFor(
    textLength: Float,
    charCount: Int,
    naturalWidth: Float,
): Float {
    if (textLength.isNaN() || charCount <= 0) return 0f
    return (textLength - naturalWidth) / charCount
}

/**
 * Uniform glyph scale for `textLength` with lengthAdjust="spacingAndGlyphs":
 * target / measured (1 = off, including degenerate input). Renderers scale
 * glyphs and advances together, so the run sums to the target exactly.
 */
internal fun glyphScaleFor(
    textLength: Float,
    scaleGlyphs: Boolean,
    naturalWidth: Float,
): Float {
    if (textLength.isNaN() || !scaleGlyphs || naturalWidth <= 0f) return 1f
    return textLength / naturalWidth
}

/**
 * Arms [TextProcessor.spacingAdjust]/[TextProcessor.glyphScale] for one `textLength` subtree from an
 * already-measured natural width. Callers save both fields, traverse, and
 * restore. The two modes are exclusive: glyph scaling zeroes spacing.
 */
internal fun TextProcessor.applyTextLength(
    textLength: Float,
    scaleGlyphs: Boolean,
    naturalWidth: Float,
    charCount: Int,
) {
    if (textLength.isNaN()) return
    if (scaleGlyphs) {
        glyphScale = glyphScaleFor(textLength, true, naturalWidth)
    } else {
        spacingAdjust = spacingAdjustFor(textLength, charCount, naturalWidth)
    }
}

context(renderContext: DisplayContext)
internal fun calculateTextWidth(children: List<TextNode>, parentState: RendererState): Float {
    var width = 0f
    children.forEachElement { child ->
        width += when (child) {
            is TextSequenceNode -> measureText(child.text, parentState.fillPaint, child.textWidthBuffer)
            is TSpanRenderNode -> {
                // If x or y is specified, it might reset the layout chunk, but for total width 
                // calculation we still need to know how much space it takes from its start point.
                calculateTextWidth(child.children, child.renderState)
            }

            is TextPathRenderNode -> calculateTextWidth(child.children, child.renderState)
            is TRefRenderNode -> measureText(child.text, child.renderState.fillPaint, child.textWidthBuffer)
            else -> 0f
        }
    }
    return width
}

context(renderContext: DisplayContext, poolOwner: PoolOwner)
internal fun calculateTextBounds(
    canvas: Canvas,
    children: List<TextNode>,
    proc: TextBoundsCalculator,
    parentState: RendererState
) {
    children.forEachElement { child ->
        when (child) {
            is TextSequenceNode -> {
                // For sequence nodes we use parent state because they don't have their own
                proc.processText(canvas, child.text, parentState, child.textWidthBuffer)
            }

            is TSpanRenderNode -> {
                proc.pushPositioning(child.x, child.y, child.dx, child.dy, child.rotate)
                val savedAdjust = proc.spacingAdjust
                val savedScale = proc.glyphScale
                val tspanLength = child.textLength
                if (!tspanLength.isNaN()) {
                    proc.applyTextLength(
                        textLength = tspanLength,
                        scaleGlyphs = child.scaleGlyphs,
                        naturalWidth = calculateTextWidth(child.children, child.renderState),
                        charCount = countTextChars(child.children)
                    )
                }
                calculateTextBounds(canvas, child.children, proc, child.renderState)
                proc.spacingAdjust = savedAdjust
                proc.glyphScale = savedScale
                proc.popPositioning()
            }

            is TRefRenderNode -> {
                proc.pushPositioning(child.x, child.y, child.dx, child.dy, child.rotate)
                val savedAdjust = proc.spacingAdjust
                val savedScale = proc.glyphScale
                val trefLength = child.textLength
                if (!trefLength.isNaN()) {
                    proc.applyTextLength(
                        textLength = trefLength,
                        scaleGlyphs = child.scaleGlyphs,
                        naturalWidth = measureText(child.text, child.renderState.fillPaint, child.textWidthBuffer),
                        charCount = child.text.length
                    )
                }
                proc.processText(canvas, child.text, child.renderState, child.textWidthBuffer)
                proc.spacingAdjust = savedAdjust
                proc.glyphScale = savedScale
                proc.popPositioning()
            }

            is TextPathRenderNode -> {
                // For TextPath we use its path bounds
                poolOwner.rectFPool.withPooledObject { pathBounds ->
                    child.path.computeBounds(pathBounds, true)
                    proc.boundingBox.union(pathBounds)
                }
                // And update x position by text width
                proc.x += calculateTextWidth(child.children, child.renderState)
            }
            else -> {}
        }
    }
}

internal class TextBoundsCalculator : TextProcessor() {
    @JvmField
    val boundingBox: RectF = RectF()

    // Scratch glyph bounds (reused for every character instead of allocating
    // per glyph). DisplayContext exposes no pools (only RenderContext does),
    // so the calculator owns its scratch like PlainTextDrawer owns fontMetrics.
    // Instances are operation-local and used single-threaded.
    private val glyphRect: Rect = Rect()
    private val glyphBounds: RectF = RectF()

    override fun doTextContainer(obj: TextContainer): Boolean {
        // This is the old DOM-based way, should not be called with nodes
        return true
    }

    context(renderContext: DisplayContext)
    override fun processText(canvas: Canvas, text: String, widths: FloatArrayBucket) {
        if (state.style.visibility != false) {
            val rect = glyphRect
            val paint = state.fillPaint
            val transformedText = applyTextTransform(text, state.style.textTransform)
            val baselineOffset = calculateBaselineOffset(paint, state.style)

            val spacingAdjust = spacingAdjust
            if (spacingAdjust != 0f || glyphScale != 1f || hasPositioning()) {
                val buffer = widths.getWithSize(transformedText.length)
                paint.getTextWidths(transformedText, buffer)
                for (i in transformedText.indices) {
                    applyPositioning()
                    paint.getTextBounds(transformedText, i, i + 1, rect)
                    val textBounds = glyphBounds
                    textBounds.set(rect)
                    val glyphRotation = rotation
                    val glyphScaleX = glyphScale
                    if (glyphRotation != 0f || glyphScaleX != 1f) {
                        // Union the transformed glyph box: scale horizontally
                        // about the glyph origin, then rotate the corners
                        // manually (no Matrix allocation on this path).
                        val radians = glyphRotation.toDouble().toRadians()
                        val cos = cos(radians).toFloat()
                        val sin = sin(radians).toFloat()
                        var minX = Float.MAX_VALUE
                        var minY = Float.MAX_VALUE
                        var maxX = -Float.MAX_VALUE
                        var maxY = -Float.MAX_VALUE
                        var corner = 0
                        while (corner < 4) {
                            val px = (if (corner == 0 || corner == 3) rect.left.toFloat() else rect.right.toFloat()) * glyphScaleX
                            val py = if (corner < 2) rect.top.toFloat() else rect.bottom.toFloat()
                            val rx = px * cos - py * sin
                            val ry = px * sin + py * cos
                            if (rx < minX) minX = rx
                            if (rx > maxX) maxX = rx
                            if (ry < minY) minY = ry
                            if (ry > maxY) maxY = ry
                            corner++
                        }
                        textBounds.set(minX, minY, maxX, maxY)
                    }
                    textBounds.offset(x, y + baselineOffset)
                    boundingBox.union(textBounds)
                    x += buffer[i] * glyphScaleX + spacingAdjust
                }
            } else {
                paint.getTextBounds(transformedText, 0, transformedText.length, rect)
                val textBounds = glyphBounds
                textBounds.set(rect)
                textBounds.offset(x, y + baselineOffset)
                boundingBox.union(textBounds)
                x += measureText(transformedText, paint, widths)
            }
        }
    }

    // Needed for calculateTextBounds calls that pass state
    context(renderContext: DisplayContext)
    fun processText(canvas: Canvas, text: String, state: RendererState, widths: FloatArrayBucket) {
        // Wrap state so processText can access it
        // Actually, TextBoundsCalculator seems to be used without an initial state
        // in calculateTextBounds, but it uses the passed state for each call.
        // Let's adjust TextBoundsCalculator to hold current state.
        this.state = state
        processText(canvas, text, widths)
    }

    @JvmField
    internal var state: RendererState = RendererState()
}

internal open class PlainTextDrawer(
    @JvmField
    internal var state: RendererState,
) : TextProcessor() {

    private val fontMetrics = Paint.FontMetrics()

    context(renderContext: DisplayContext)
    override fun processText(canvas: Canvas, text: String, widths: FloatArrayBucket) {
        val style = state.style
        if (style.visibility == false) {
            updatePositionAfterText(text, widths)
            return
        }

        val transformedText = applyTextTransform(text, style.textTransform)

        val writingMode = style.writingMode ?: WritingMode.horizontal_tb
        if (writingMode.isVertical) {
            processTextVertical(canvas, transformedText, widths)
        } else {
            processTextHorizontal(canvas, transformedText, widths)
        }
    }

    private fun updatePositionAfterText(text: String, widths: FloatArrayBucket) {
        val style = state.style
        val writingMode = style.writingMode ?: WritingMode.horizontal_tb
        val advance = measureText(text, state.fillPaint, widths) * glyphScale + spacingAdjust * text.length
        if (writingMode.isVertical) {
            y += advance
        } else {
            x += advance
        }
    }

    context(renderContext: DisplayContext)
    private fun processTextHorizontal(canvas: Canvas, text: String, widths: FloatArrayBucket) {
        val letterspacingAdj = state.style.letterSpacing!!.floatValueInContext() / 2
        val paint = state.fillPaint
        val strokePaint = state.strokePaint
        val baselineOffset = calculateBaselineOffset(paint, state.style)
        // Resolve font metrics once for the whole run. drawManualDecorations is
        // called per glyph in the positioning branch, so reading paint.fontMetrics
        // (which allocates a FontMetrics) there would allocate per character.
        val fm = fontMetrics
        paint.getFontMetrics(fm)

        // A textLength adjustment (either mode) also forces the per-character
        // loop: the single-draw fast path can neither redistribute advances
        // nor scale glyphs.
        if (spacingAdjust != 0f || glyphScale != 1f || hasPositioning()) {
            // Measure the whole run once into the node's width buffer, then index
            // per character. This keeps the buffer at the run's fixed length (no
            // per-frame resize) and avoids measuring each glyph in isolation.
            val buffer = widths.getWithSize(text.length)
            paint.getTextWidths(text, buffer)
            for (i in text.indices) {
                applyPositioning()
                val adjustedX = x - letterspacingAdj
                val baselineY = y + baselineOffset
                // Supplemental per-character rotation about the glyph origin.
                // Manual save/rotate/restore (not the withRotation helper):
                // a capturing lambda per glyph would allocate on this hot path.
                val glyphRotation = rotation
                val glyphScaleX = glyphScale
                val rotated = glyphRotation != 0f
                val scaled = glyphScaleX != 1f
                val checkpoint = if (rotated || scaled) canvas.save() else 0
                if (rotated) {
                    canvas.rotate(glyphRotation, adjustedX, baselineY)
                }
                if (scaled) {
                    canvas.scale(glyphScaleX, 1f, adjustedX, baselineY)
                }
                if (state.hasFill) {
                    canvas.drawText(text, i, i + 1, adjustedX, baselineY, paint)
                }
                if (state.hasStroke) {
                    canvas.drawText(text, i, i + 1, adjustedX, baselineY, strokePaint)
                }
                val advance = buffer[i] * glyphScaleX + spacingAdjust
                drawManualDecorations(canvas, adjustedX, baselineY, advance, paint, fm)
                if (rotated || scaled) {
                    canvas.restoreToCount(checkpoint)
                }
                x += advance
            }
        } else {
            val adjustedX = x - letterspacingAdj
            val baselineY = y + baselineOffset
            if (state.hasFill) {
                canvas.drawText(text, adjustedX, baselineY, paint)
            }
            if (state.hasStroke) {
                canvas.drawText(text, adjustedX, baselineY, strokePaint)
            }
            val advance = measureText(text, paint, widths)
            drawManualDecorations(canvas, adjustedX, baselineY, advance, paint, fm)
            x += advance
        }
    }

    private fun drawManualDecorations(canvas: Canvas, x: Float, y: Float, advance: Float, paint: Paint, fm: Paint.FontMetrics) {
        val decoration = state.style.textDecoration ?: return
        val thickness = paint.textSize / 18f

        if (decoration.hasOverline()) {
            val lineY = y + fm.ascent
            drawDecorationLine(canvas, x, lineY, advance, thickness, paint)
        }
        if (decoration.hasUnderline()) {
            val lineY = y + thickness * 2f
            drawDecorationLine(canvas, x, lineY, advance, thickness, paint)
        }
        if (decoration.hasLineThrough()) {
            val lineY = y + (fm.ascent + fm.descent) / 2.5f
            drawDecorationLine(canvas, x, lineY, advance, thickness, paint)
        }
    }

    private fun drawDecorationLine(canvas: Canvas, x: Float, y: Float, advance: Float, thickness: Float, paint: Paint) {
        if (state.hasFill) {
            canvas.drawRect(x, y - thickness / 2f, x + advance, y + thickness / 2f, paint)
        }
        if (state.hasStroke) {
            canvas.drawRect(x, y - thickness / 2f, x + advance, y + thickness / 2f, state.strokePaint)
        }
    }

    @SuppressLint("UseKtx")
    context(renderContext: DisplayContext)
    private fun processTextVertical(canvas: Canvas, text: String, widths: FloatArrayBucket) {
        val orientation = state.style.textOrientation ?: TextOrientation.mixed

        if (orientation == TextOrientation.sideways) {
            val oldX = x
            val oldY = y
            canvas.save()
            canvas.rotate(90f, x, y)
            processTextHorizontal(canvas, text, widths)
            canvas.restore()

            val advance = x - oldX
            x = oldX
            y = oldY + advance
        } else {
            // Upright or mixed (default for vertical)
            // Draw character by character
            var currentY = y
            val paint = state.fillPaint
            val strokePaint = state.strokePaint
            val fm = paint.fontMetrics
            val charAdvance = fm.bottom - fm.top

            for (i in text.indices) {
                if (state.hasFill) {
                    canvas.drawText(text, i, i + 1, x, currentY, paint)
                }
                if (state.hasStroke) {
                    canvas.drawText(text, i, i + 1, x, currentY, strokePaint)
                }
                // Upright vertical has no per-glyph rotation support (positioned
                // chunks only); advances still honor both adjustments.
                currentY += charAdvance * glyphScale + spacingAdjust
            }
            y = currentY
        }
    }
}

internal class PathTextDrawer(
    private val path: Path,
    state: RendererState,
    private val flipSide: Boolean,
) : PlainTextDrawer(state) {

    context(renderContext: DisplayContext)
    override fun processText(canvas: Canvas, text: String, widths: FloatArrayBucket) {
        if (state.style.visibility != false) {
            val transformedText = applyTextTransform(text, state.style.textTransform)
            // Android/Skia divides letterspacing and puts half before and after each letter.
            // We need to readjust initial text X position to counter that.
            val letterspacingAdj = state.style.letterSpacing!!.floatValueInContext() / 2
            val baselineOffset = calculateBaselineOffset(state.fillPaint, state.style)
            // side="right" translates the run to the other side of the path
            // (glyphs stay upright, reading order unchanged): mirror the
            // [vOffset+ascent, vOffset+descent] interval about the path.
            val vOffset = y + baselineOffset
            val pathOffset = if (flipSide) {
                val fm = state.fillPaint.fontMetrics
                -(vOffset + fm.ascent + fm.descent)
            } else {
                vOffset
            }
            if (state.hasFill) {
                canvas.drawTextOnPath(
                    /* text = */ transformedText,
                    /* path = */ path,
                    /* hOffset = */ x - letterspacingAdj,
                    /* vOffset = */ pathOffset,
                    /* paint = */ state.fillPaint
                )
            }

            if (state.hasStroke) {
                canvas.drawTextOnPath(
                    /* text = */ transformedText,
                    /* path = */ path,
                    /* hOffset = */ x - letterspacingAdj,
                    /* vOffset = */ pathOffset,
                    /* paint = */ state.strokePaint
                )
            }
        }

        // Update the current text position
        x += measureText(text, state.fillPaint, widths)
    }
}

context(renderContext: RenderContext)
internal fun calculateTextPath(
    children: List<TextNode>,
    proc: PlainTextToPath,
    parentState: RendererState
) {
    children.forEachElement { child ->
        when (child) {
            is TextSequenceNode -> {
                proc.processText(child.text, parentState, child.textWidthBuffer)
            }

            is TSpanRenderNode -> {
                proc.pushPositioning(child.x, child.y, child.dx, child.dy, child.rotate)
                val savedAdjust = proc.spacingAdjust
                val savedScale = proc.glyphScale
                val tspanLength = child.textLength
                if (!tspanLength.isNaN()) {
                    proc.applyTextLength(
                        textLength = tspanLength,
                        scaleGlyphs = child.scaleGlyphs,
                        naturalWidth = calculateTextWidth(child.children, child.renderState),
                        charCount = countTextChars(child.children)
                    )
                }
                calculateTextPath(child.children, proc, child.renderState)
                proc.spacingAdjust = savedAdjust
                proc.glyphScale = savedScale
                proc.popPositioning()
            }

            is TRefRenderNode -> {
                proc.pushPositioning(child.x, child.y, child.dx, child.dy, child.rotate)
                val savedAdjust = proc.spacingAdjust
                val savedScale = proc.glyphScale
                val trefLength = child.textLength
                if (!trefLength.isNaN()) {
                    proc.applyTextLength(
                        textLength = trefLength,
                        scaleGlyphs = child.scaleGlyphs,
                        naturalWidth = measureText(child.text, child.renderState.fillPaint, child.textWidthBuffer),
                        charCount = child.text.length
                    )
                }
                proc.processText(child.text, child.renderState, child.textWidthBuffer)
                proc.spacingAdjust = savedAdjust
                proc.glyphScale = savedScale
                proc.popPositioning()
            }

            is TextPathRenderNode -> {
                // TextPath in clipPath is technically not supported or complex, 
                // but we can try to approximate it by just getting text width
                proc.x += calculateTextWidth(child.children, child.renderState)
            }
            else -> {}
        }
    }
}

internal class PlainTextToPath(
    @JvmField
    val textAsPath: Path,
) : TextProcessor() {
    // Scratch glyph path, rewound (not reset: keeps its backing store)
    // before every use. Operation-local instance, single-threaded use.
    private val spanScratch: Path = Path()

    // Scratch transform, created on first rotated/scaled glyph and reused
    // via setRotate (no further allocation). Same lifetime discipline.
    private var transformScratch: Matrix? = null

    override fun doTextContainer(obj: TextContainer): Boolean {
        return true
    }

    context(renderContext: DisplayContext)
    override fun processText(canvas: Canvas, text: String, widths: FloatArrayBucket) {
        // Should not be called without state
    }

    context(renderContext: RenderContext)
    fun processText(text: String, state: RendererState, widths: FloatArrayBucket) {
        if (state.style.visibility != false) {
            val paint = state.fillPaint
            val transformedText = applyTextTransform(text, state.style.textTransform)
            val baselineOffset = calculateBaselineOffset(paint, state.style)

            val spacingAdjust = spacingAdjust
            val spanScratch = spanScratch
            if (hasPositioning() || spacingAdjust != 0f || glyphScale != 1f) {
                val buffer = widths.getWithSize(transformedText.length)
                paint.getTextWidths(transformedText, buffer)
                // Scratch matrix created only if a rotated/scaled glyph shows up
                // (setRotate reuses it without further allocation).
                for (i in transformedText.indices) {
                    applyPositioning()
                    spanScratch.rewind()
                    paint.getTextPath(transformedText, i, i + 1, x, y + baselineOffset, spanScratch)
                    val glyphRotation = rotation
                    val glyphScaleX = glyphScale
                    if (glyphRotation != 0f || glyphScaleX != 1f) {
                        val matrix = transformScratch ?: Matrix().also { transformScratch = it }
                        matrix.setRotate(glyphRotation, x, y + baselineOffset)
                        if (glyphScaleX != 1f) {
                            matrix.preScale(glyphScaleX, 1f, x, y + baselineOffset)
                        }
                        spanScratch.transform(matrix)
                    }
                    textAsPath.addPath(spanScratch)
                    x += buffer[i] * glyphScaleX + spacingAdjust
                }
            } else {
                spanScratch.rewind()
                paint.getTextPath(transformedText, 0, transformedText.length, x, y + baselineOffset, spanScratch)
                textAsPath.addPath(spanScratch)
                x += measureText(transformedText, paint, widths)
            }
        }
    }
}

context(renderContext: DisplayContext)
internal fun calculateBaselineOffset(paint: Paint, style: Style): Float {
    val baseline = style.alignmentBaseline ?: style.dominantBaseline
    var offset = 0f
    if (baseline != null && baseline != DominantBaseline.Auto && baseline != DominantBaseline.Alphabetic) {
        val fm = paint.fontMetrics
        offset = when (baseline) {
            DominantBaseline.Middle -> -(fm.ascent + fm.descent) / 2f
            DominantBaseline.Hanging -> -fm.ascent
            DominantBaseline.Ideographic -> -fm.descent
            DominantBaseline.Central -> -(fm.ascent + fm.descent) / 2f
            DominantBaseline.TextBeforeEdge -> -fm.ascent
            DominantBaseline.TextAfterEdge -> -fm.descent
            DominantBaseline.TextTop -> -fm.top
            DominantBaseline.TextBottom -> -fm.bottom
            else -> 0f
        }
    }

    val shift = style.baselineShift
    if (shift != null) {
        offset += when (shift.type) {
            BaselineShift.Type.Baseline -> 0f
            BaselineShift.Type.Sub -> paint.textSize * 0.25f
            BaselineShift.Type.Super -> -paint.textSize * 0.33f
            BaselineShift.Type.Length -> -shift.value!!.floatValueInContext(paint.textSize)
        }
    }
    return offset
}

internal fun applyTextTransform(text: String, transform: TextTransform?): String {
    return when (transform) {
        TextTransform.Uppercase -> text.uppercase(Locale.US)
        TextTransform.Lowercase -> text.lowercase(Locale.US)
        TextTransform.Capitalize -> text.capitalizeStr(Locale.US)
        else -> text
    }
}
