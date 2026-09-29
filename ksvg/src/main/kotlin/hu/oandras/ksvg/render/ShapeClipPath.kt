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

import android.graphics.Path
import android.graphics.RectF
import hu.oandras.ksvg.css.CSSLength
import hu.oandras.ksvg.css.CssUnit
import hu.oandras.ksvg.dom.core.Box
import hu.oandras.ksvg.dom.style.BasicShape
import hu.oandras.ksvg.dom.style.ClipPosition
import hu.oandras.ksvg.dom.style.ClipRadius
import hu.oandras.ksvg.dom.style.FillRule
import hu.oandras.ksvg.render.pool.withPooledObject
import kotlin.math.hypot
import kotlin.math.sqrt

/** Diagonal divisor of the css-shapes percentage reference length. */
private val SHAPE_CLIP_SQRT_2 = sqrt(2f)

/**
 * Converts a CSS basic-shape `clip-path` (reference box snapshotted at
 * build time) into [out]. Percentages resolve against the reference box, and
 * the shape is laid out in the referencing element's own user space, i.e.,
 * from the reference box corner — the same space `path()` data is written
 * in, and the origin `userSpaceOnUse` url clips already use.
 */
context(renderContext: RenderContext)
internal fun shapeClipToPath(clip: ResolvedShapeClip, node: RenderNode<*>, out: Path): Boolean {
    val box = clip.refBox
    when (val shape = clip.shape) {
        is BasicShape.Circle -> {
            val cx = shape.cx.resolveX(box)
            val cy = shape.cy.resolveY(box)
            // Spec (css-shapes): radius % resolves against sqrt(w²+h²)/sqrt(2).
            val diag = hypot(box.width, box.height) / SHAPE_CLIP_SQRT_2
            val r = shape.r.resolveRadius(diag, cx, cy, box)
            if (r <= 0f) return false
            out.addCircle(cx, cy, r, Path.Direction.CW)
        }
        is BasicShape.Ellipse -> {
            val cx = shape.cx.resolveX(box)
            val cy = shape.cy.resolveY(box)
            val rx = shape.rx.resolveRadiusX(cx, box)
            val ry = shape.ry.resolveRadiusY(cy, box)
            if (rx <= 0f || ry <= 0f) return false
            renderContext.rectFPool.withPooledObject { rect ->
                rect.set(cx - rx, cy - ry, cx + rx, cy + ry)
                out.addOval(rect, Path.Direction.CW)
            }
        }
        is BasicShape.Inset -> {
            val left = box.minX + shape.left.resolveWithBase(box.width)
            val top = box.minY + shape.top.resolveWithBase(box.height)
            val right = box.minX + box.width - shape.right.resolveWithBase(box.width)
            val bottom = box.minY + box.height - shape.bottom.resolveWithBase(box.height)
            if (right <= left || bottom <= top) return false
            renderContext.rectFPool.withPooledObject { rect ->
                rect.set(left, top, right, bottom)
                val rx = shape.roundX?.resolveWithBase(box.width) ?: 0f
                val ry = shape.roundY?.resolveWithBase(box.height) ?: rx
                if (rx > 0f && ry > 0f) {
                    out.addRoundRect(rect, rx, ry, Path.Direction.CW)
                } else {
                    out.addRect(rect, Path.Direction.CW)
                }
            }
        }
        is BasicShape.Rect -> {
            // rect() edges are absolute positions from the box origin
            // (unlike inset() inward offsets).
            val left = box.minX + shape.left.resolveWithBase(box.width)
            val top = box.minY + shape.top.resolveWithBase(box.height)
            val right = box.minX + shape.right.resolveWithBase(box.width)
            val bottom = box.minY + shape.bottom.resolveWithBase(box.height)
            if (right <= left || bottom <= top) return false
            renderContext.rectFPool.withPooledObject { rect ->
                rect.set(left, top, right, bottom)
                addRoundRectOrRect(out, rect, shape.roundX, shape.roundY, box)
            }
        }
        is BasicShape.Xywh -> {
            val left = box.minX + shape.x.resolveWithBase(box.width)
            val top = box.minY + shape.y.resolveWithBase(box.height)
            val right = left + shape.w.resolveWithBase(box.width)
            val bottom = top + shape.h.resolveWithBase(box.height)
            if (right <= left || bottom <= top) return false
            renderContext.rectFPool.withPooledObject { rect ->
                rect.set(left, top, right, bottom)
                addRoundRectOrRect(out, rect, shape.roundX, shape.roundY, box)
            }
        }
        is BasicShape.Polygon -> {
            if (!polygonClipToPath(clip, node, box, out)) return false
        }
        is BasicShape.Path -> {
            val clipPath = clip.clipPath ?: return false
            if (clipPath.isEmpty) return false
            out.set(clipPath)
            out.fillType = shapeClipFillType(shape.fillRule, node)
        }
    }
    return true
}

/**
 * Fill type of basic-shape clip: an explicit `polygon()`/`path()` fill-rule
 * prefix wins, otherwise the element's `clip-rule` applies.
 */
private fun shapeClipFillType(@FillRule fillRule: Int, node: RenderNode<*>): Path.FillType {
    return when (fillRule) {
        FillRule.EVEN_ODD -> Path.FillType.EVEN_ODD
        FillRule.NON_ZERO -> Path.FillType.WINDING
        else -> node.renderState.clipFillType
    }
}

context(renderContext: RenderContext)
private fun addRoundRectOrRect(
    out: Path,
    rect: RectF,
    roundX: CSSLength?,
    roundY: CSSLength?,
    box: Box,
) {
    val rx = roundX?.resolveWithBase(box.width) ?: 0f
    val ry = roundY?.resolveWithBase(box.height) ?: rx
    if (rx > 0f && ry > 0f) {
        out.addRoundRect(rect, rx, ry, Path.Direction.CW)
    } else {
        out.addRect(rect, Path.Direction.CW)
    }
}

/** Resolves a circle radius: length against the spec diagonal, side keywords against the box. */
context(renderContext: RenderContext)
private fun ClipRadius.resolveRadius(diag: Float, cx: Float, cy: Float, box: Box): Float {
    return when (this) {
        is ClipRadius.Len -> v.resolveWithBase(diag)
        is ClipRadius.ClosestSide -> minOf(
            cx - box.minX, box.minX + box.width - cx,
            cy - box.minY, box.minY + box.height - cy,
        ).coerceAtLeast(0f)
        is ClipRadius.FarthestSide -> maxOf(
            cx - box.minX, box.minX + box.width - cx,
            cy - box.minY, box.minY + box.height - cy,
        ).coerceAtLeast(0f)
    }
}

@Suppress("DuplicatedCode")
context(renderContext: RenderContext)
private fun ClipRadius.resolveRadiusX(cx: Float, box: Box): Float {
    return when (this) {
        is ClipRadius.Len -> v.resolveWithBase(box.width)
        is ClipRadius.ClosestSide -> minOf(cx - box.minX, box.minX + box.width - cx).coerceAtLeast(0f)
        is ClipRadius.FarthestSide -> maxOf(cx - box.minX, box.minX + box.width - cx).coerceAtLeast(0f)
    }
}

@Suppress("DuplicatedCode")
context(renderContext: RenderContext)
private fun ClipRadius.resolveRadiusY(cy: Float, box: Box): Float {
    return when (this) {
        is ClipRadius.Len -> v.resolveWithBase(box.height)
        is ClipRadius.ClosestSide -> minOf(cy - box.minY, box.minY + box.height - cy).coerceAtLeast(0f)
        is ClipRadius.FarthestSide -> maxOf(cy - box.minY, box.minY + box.height - cy).coerceAtLeast(0f)
    }
}

context(renderContext: RenderContext)
private fun polygonClipToPath(
    clip: ResolvedShapeClip,
    node: RenderNode<*>,
    box: Box,
    out: Path,
): Boolean {
    val shape = clip.shape as BasicShape.Polygon
    val pts = shape.points
    if (pts.size < 4) return false
    var i = 0
    var first = true
    while (i + 1 < pts.size) {
        val x = box.minX + pts[i].resolveWithBase(box.width)
        val y = box.minY + pts[i + 1].resolveWithBase(box.height)
        if (first) {
            out.moveTo(x, y)
            first = false
        } else {
            out.lineTo(x, y)
        }
        i += 2
    }
    out.close()
    out.fillType = shapeClipFillType(shape.fillRule, node)
    return true
}

context(renderContext: RenderContext)
private fun CSSLength.resolveWithBase(base: Float): Float {
    return when (unit) {
        CssUnit.percent -> value * base / 100f
        CssUnit.em -> value * renderContext.currentFontSize
        CssUnit.ex -> value * renderContext.currentFontXHeight
        else -> with(renderContext) { floatValueXInContext() }
    }
}

context(renderContext: RenderContext)
private fun ClipPosition.resolveX(box: Box): Float {
    return when (this) {
        ClipPosition.Left -> box.minX
        ClipPosition.Center -> box.minX + box.width / 2f
        ClipPosition.Right -> box.minX + box.width
        ClipPosition.Top -> box.minX
        ClipPosition.Bottom -> box.minX + box.width
        is ClipPosition.Len -> box.minX + v.resolveWithBase(box.width)
        is ClipPosition.Offset -> {
            val d = delta.resolveWithBase(box.width)
            when (anchor) {
                ClipPosition.Left -> box.minX + d
                ClipPosition.Right -> box.minX + box.width - d
                else -> box.minX + box.width / 2f + d
            }
        }
    }
}

context(renderContext: RenderContext)
private fun ClipPosition.resolveY(box: Box): Float {
    return when (this) {
        ClipPosition.Top -> box.minY
        ClipPosition.Center -> box.minY + box.height / 2f
        ClipPosition.Bottom -> box.minY + box.height
        ClipPosition.Left -> box.minY
        ClipPosition.Right -> box.minY + box.height
        is ClipPosition.Len -> box.minY + v.resolveWithBase(box.height)
        is ClipPosition.Offset -> {
            val d = delta.resolveWithBase(box.height)
            when (anchor) {
                ClipPosition.Top -> box.minY + d
                ClipPosition.Bottom -> box.minY + box.height - d
                else -> box.minY + box.height / 2f + d
            }
        }
    }
}
