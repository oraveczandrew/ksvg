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
import hu.oandras.ksvg.render.RenderContext
import hu.oandras.ksvg.render.RendererState
import hu.oandras.ksvg.render.TRefRenderNode
import hu.oandras.ksvg.render.TSpanRenderNode
import hu.oandras.ksvg.render.TextNode
import hu.oandras.ksvg.render.TextPathRenderNode
import hu.oandras.ksvg.render.TextSequenceNode
import hu.oandras.ksvg.utils.capitalizeStr
import hu.oandras.ksvg.utils.forEachElement
import java.util.*

internal abstract class TextProcessor {
    @JvmField
    var x: Float = 0f
    @JvmField
    var y: Float = 0f

    private val positioningStack = mutableListOf<TextPositioning>()

    fun pushPositioning(x: FloatArray?, y: FloatArray?, dx: FloatArray?, dy: FloatArray?) {
        positioningStack.add(TextPositioning(x, y, dx, dy))
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
        var absX: Float? = null
        var absY: Float? = null
        var relX = 0f
        var relY = 0f

        for (i in positioningStack.size - 1 downTo 0) {
            val p = positioningStack[i]
            if (absX == null && p.x != null && p.index < p.x.size) {
                absX = p.x[p.index]
            }
            if (absY == null && p.y != null && p.index < p.y.size) {
                absY = p.y[p.index]
            }
        }

        positioningStack.forEachElement { p ->
            if (p.dx != null && p.index < p.dx.size) {
                relX += p.dx[p.index]
            }
            if (p.dy != null && p.index < p.dy.size) {
                relY += p.dy[p.index]
            }
            p.index++
        }

        if (absX != null) x = absX
        if (absY != null) y = absY
        x += relX
        y += relY
    }

    open fun doTextContainer(obj: TextContainer): Boolean {
        return true
    }

    context(renderContext: RenderContext)
    abstract fun processText(text: String)
}

private class TextPositioning(
    val x: FloatArray?,
    val y: FloatArray?,
    val dx: FloatArray?,
    val dy: FloatArray?
) {
    var index = 0

    fun hasPending(): Boolean {
        return (x != null && index < x.size) ||
                (y != null && index < y.size) ||
                (dx != null && index < dx.size) ||
                (dy != null && index < dy.size)
    }
}

internal fun RendererState.getAnchorPosition(): TextAnchor? {
    val style = this.style
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

context(renderContext: RenderContext)
internal fun calculateTextWidth(children: List<TextNode>, parentState: RendererState): Float {
    var width = 0f
    for (child in children) {
        width += when (child) {
            is TextSequenceNode -> measureText(child.text, parentState.fillPaint, parentState.textWidthBuffer)
            is TSpanRenderNode -> {
                // If x or y is specified, it might reset the layout chunk, but for total width 
                // calculation we still need to know how much space it takes from its start point.
                calculateTextWidth(child.children, child.renderState)
            }

            is TextPathRenderNode -> calculateTextWidth(child.children, child.renderState)
            is TRefRenderNode -> measureText(child.text, child.renderState.fillPaint, child.renderState.textWidthBuffer)
            else -> 0f
        }
    }
    return width
}

context(renderContext: RenderContext)
internal fun calculateTextBounds(
    children: List<TextNode>,
    proc: TextBoundsCalculator,
    parentState: RendererState
) {
    for (child in children) {
        when (child) {
            is TextSequenceNode -> {
                // For sequence nodes we use parent state because they don't have their own
                proc.processText(child.text, parentState)
            }

            is TSpanRenderNode -> {
                proc.pushPositioning(child.x, child.y, child.dx, child.dy)
                calculateTextBounds(child.children, proc, child.renderState)
                proc.popPositioning()
            }

            is TRefRenderNode -> {
                proc.pushPositioning(child.x, child.y, child.dx, child.dy)
                proc.processText(child.text, child.renderState)
                proc.popPositioning()
            }

            is TextPathRenderNode -> {
                // For TextPath we use its path bounds
                val path = child.path
                val pathBounds = RectF()
                path.computeBounds(pathBounds, true)
                proc.boundingBox.union(pathBounds)
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

    override fun doTextContainer(obj: TextContainer): Boolean {
        // This is the old DOM-based way, should not be called with nodes
        return true
    }

    context(renderContext: RenderContext)
    override fun processText(text: String) {
        if (state.style.visibility != false) {
            val rect = Rect()
            val paint = state.fillPaint
            val widths = state.textWidthBuffer
            val transformedText = applyTextTransform(text, state.style.textTransform)
            val baselineOffset = calculateBaselineOffset(paint, state.style)
            
            if (hasPositioning()) {
                for (char in transformedText) {
                    applyPositioning()
                    val s = char.toString()
                    paint.getTextBounds(s, 0, 1, rect)
                    val textBounds = RectF(rect)
                    textBounds.offset(x, y + baselineOffset)
                    boundingBox.union(textBounds)
                    x += measureText(s, paint, widths)
                }
            } else {
                paint.getTextBounds(transformedText, 0, transformedText.length, rect)
                val textBounds = RectF(rect)
                textBounds.offset(x, y + baselineOffset)
                boundingBox.union(textBounds)
                x += measureText(transformedText, paint, widths)
            }
        }
    }

    // Needed for calculateTextBounds calls that pass state
    context(renderContext: RenderContext)
    fun processText(text: String, state: RendererState) {
        // Wrap state so processText can access it
        // Actually, TextBoundsCalculator seems to be used without an initial state 
        // in calculateTextBounds, but it uses the passed state for each call.
        // Let's adjust TextBoundsCalculator to hold current state.
        this.state = state
        processText(text)
    }

    @JvmField
    internal var state: RendererState = RendererState()
}

internal open class PlainTextDrawer(
    internal var canvas: Canvas,
    @JvmField
    internal var state: RendererState,
) : TextProcessor() {

    context(renderContext: RenderContext)
    override fun processText(text: String) {
        val style = state.style
        if (style.visibility == false) {
            updatePositionAfterText(text)
            return
        }

        val transformedText = applyTextTransform(text, style.textTransform)

        val writingMode = style.writingMode ?: WritingMode.horizontal_tb
        if (writingMode.isVertical) {
            processTextVertical(transformedText)
        } else {
            processTextHorizontal(transformedText)
        }
    }

    private fun updatePositionAfterText(text: String) {
        val style = state.style
        val writingMode = style.writingMode ?: WritingMode.horizontal_tb
        val advance = measureText(text, state.fillPaint, state.textWidthBuffer)
        if (writingMode.isVertical) {
            y += advance
        } else {
            x += advance
        }
    }

    context(renderContext: RenderContext)
    private fun processTextHorizontal(text: String) {
        val letterspacingAdj = state.style.letterSpacing!!.floatValueInContext() / 2
        val paint = state.fillPaint
        val strokePaint = state.strokePaint
        val widths = state.textWidthBuffer
        val baselineOffset = calculateBaselineOffset(paint, state.style)

        if (hasPositioning()) {
            for (char in text) {
                applyPositioning()
                val s = char.toString()
                val adjustedX = x - letterspacingAdj
                val baselineY = y + baselineOffset
                if (state.hasFill) {
                    canvas.drawText(s, adjustedX, baselineY, paint)
                }
                if (state.hasStroke) {
                    canvas.drawText(s, adjustedX, baselineY, strokePaint)
                }
                val advance = measureText(s, paint, widths)
                drawManualDecorations(canvas, adjustedX, baselineY, advance, paint)
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
            drawManualDecorations(canvas, adjustedX, baselineY, advance, paint)
            x += advance
        }
    }

    private fun drawManualDecorations(canvas: Canvas, x: Float, y: Float, advance: Float, paint: Paint) {
        val decoration = state.style.textDecoration ?: return
        val fm = paint.fontMetrics
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
    context(renderContext: RenderContext)
    private fun processTextVertical(text: String) {
        val orientation = state.style.textOrientation ?: TextOrientation.mixed

        if (orientation == TextOrientation.sideways) {
            val oldX = x
            val oldY = y
            canvas.save()
            canvas.rotate(90f, x, y)
            processTextHorizontal(text)
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

            for (char in text) {
                val s = char.toString()
                if (state.hasFill) {
                    canvas.drawText(s, x, currentY, paint)
                }
                if (state.hasStroke) {
                    canvas.drawText(s, x, currentY, strokePaint)
                }
                currentY += charAdvance
            }
            y = currentY
        }
    }
}

internal class PathTextDrawer(
    private val path: Path,
    canvas: Canvas,
    state: RendererState
) : PlainTextDrawer(canvas, state) {

    context(renderContext: RenderContext)
    override fun processText(text: String) {
        if (state.style.visibility != false) {
            val transformedText = applyTextTransform(text, state.style.textTransform)
            // Android/Skia divides letterspacing and puts half before and after each letter.
            // We need to readjust initial text X position to counter that.
            val letterspacingAdj = state.style.letterSpacing!!.floatValueInContext() / 2
            val baselineOffset = calculateBaselineOffset(state.fillPaint, state.style)
            if (state.hasFill) {
                canvas.drawTextOnPath(
                    /* text = */ transformedText,
                    /* path = */ path,
                    /* hOffset = */ x - letterspacingAdj,
                    /* vOffset = */ y + baselineOffset,
                    /* paint = */ state.fillPaint
                )
            }

            if (state.hasStroke) {
                canvas.drawTextOnPath(
                    /* text = */ transformedText,
                    /* path = */ path,
                    /* hOffset = */ x - letterspacingAdj,
                    /* vOffset = */ y + baselineOffset,
                    /* paint = */ state.strokePaint
                )
            }
        }

        // Update the current text position
        x += measureText(text, state.fillPaint, state.textWidthBuffer)
    }
}

context(renderContext: RenderContext)
internal fun calculateTextPath(
    children: List<TextNode>,
    proc: PlainTextToPath,
    parentState: RendererState
) {
    for (child in children) {
        when (child) {
            is TextSequenceNode -> {
                proc.processText(child.text, parentState)
            }

            is TSpanRenderNode -> {
                proc.pushPositioning(child.x, child.y, child.dx, child.dy)
                calculateTextPath(child.children, proc, child.renderState)
                proc.popPositioning()
            }

            is TRefRenderNode -> {
                proc.pushPositioning(child.x, child.y, child.dx, child.dy)
                proc.processText(child.text, child.renderState)
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
    override fun doTextContainer(obj: TextContainer): Boolean {
        return true
    }

    context(renderContext: RenderContext)
    override fun processText(text: String) {
        // Should not be called without state
    }

    context(renderContext: RenderContext)
    fun processText(text: String, state: RendererState) {
        if (state.style.visibility != false) {
            val paint = state.fillPaint
            val widths = state.textWidthBuffer
            val transformedText = applyTextTransform(text, state.style.textTransform)
            val baselineOffset = calculateBaselineOffset(paint, state.style)
            
            if (hasPositioning()) {
                for (char in transformedText) {
                    applyPositioning()
                    val s = char.toString()
                    val spanPath = Path()
                    paint.getTextPath(s, 0, 1, x, y + baselineOffset, spanPath)
                    textAsPath.addPath(spanPath)
                    x += measureText(s, paint, widths)
                }
            } else {
                val spanPath = Path()
                paint.getTextPath(transformedText, 0, transformedText.length, x, y + baselineOffset, spanPath)
                textAsPath.addPath(spanPath)
                x += measureText(transformedText, paint, widths)
            }
        }
    }
}

context(renderContext: RenderContext)
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
