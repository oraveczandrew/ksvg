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
import hu.oandras.ksvg.dom.core.Box
import hu.oandras.ksvg.dom.core.Element
import hu.oandras.ksvg.dom.core.SVGAttr
import hu.oandras.ksvg.dom.shapes.CircleShape
import hu.oandras.ksvg.dom.shapes.EllipseShape
import hu.oandras.ksvg.dom.shapes.LineShape
import hu.oandras.ksvg.dom.shapes.PathShape
import hu.oandras.ksvg.dom.shapes.PolyLineShape
import hu.oandras.ksvg.dom.shapes.PolygonShape
import hu.oandras.ksvg.dom.shapes.RectShape
import hu.oandras.ksvg.render.animation.AnimationContext
import hu.oandras.ksvg.render.animation.animatedFloat
import hu.oandras.ksvg.render.pool.PoolOwner
import hu.oandras.ksvg.render.pool.withPooledObject
import kotlin.math.abs
import kotlin.math.min

context(renderContext: DisplayContext)
internal fun updatePathAndBoundingBox(obj: RectShape, outPath: Path, node: PathRenderNode?): Boolean {
    // Missing width/height makes the <rect> invalid -> not rendered (spec).
    val objWidth = obj.width ?: return false
    val objHeight = obj.height ?: return false
    var x: Float = obj.x.floatValueXInContext()
    var y: Float = obj.y.floatValueYInContext()
    var w: Float = objWidth.floatValueXInContext()
    var h: Float = objHeight.floatValueYInContext()
    
    // Keep these as primitive locals: a `Float?` intermediate would box every
    // value (java.lang.Float) on each render pass.
    val rxLength = obj.rx
    val ryLength = obj.ry
    var rxVal = rxLength?.floatValueXInContext() ?: 0f
    var ryVal = ryLength?.floatValueYInContext() ?: 0f

    // Per SVG spec, if one of rx/ry is omitted it defaults to the other.
    if (ryLength == null && rxLength != null) ryVal = rxVal
    if (rxLength == null && ryLength != null) rxVal = ryVal

    if (renderContext is AnimationContext && node != null) {
        x = animatedFloat(node, SVGAttr.x, x)
        y = animatedFloat(node, SVGAttr.y, y)
        w = animatedFloat(node, SVGAttr.width, w)
        h = animatedFloat(node, SVGAttr.height, h)
        rxVal = animatedFloat(node, SVGAttr.rx, rxVal)
        ryVal = animatedFloat(node, SVGAttr.ry, ryVal)
    }

    rxVal = min(rxVal, w / 2f)
    ryVal = min(ryVal, h / 2f)

    val changed = obj.updateBoundingBox(x, y, w, h)

    outPath.reset()
    if (rxVal == 0f || ryVal == 0f) {
        outPath.addRect(x, y, x + w, y + h, Path.Direction.CW)
    } else {
        outPath.addRoundRect(x, y, x + w, y + h, rxVal, ryVal, Path.Direction.CW)
    }
    return changed
}

context(renderContext: DisplayContext)
internal fun updatePathAndBoundingBox(obj: CircleShape, outPath: Path, node: PathRenderNode?): Boolean {
    var cx = obj.cx?.floatValueXInContext() ?: 0f
    var cy = obj.cy?.floatValueYInContext() ?: 0f
    // Missing r makes the <circle> invalid -> not rendered (spec).
    val rLength = obj.r ?: return false
    var r = rLength.floatValueInContext()

    if (renderContext is AnimationContext && node != null) {
        cx = animatedFloat(node, SVGAttr.cx, cx)
        cy = animatedFloat(node, SVGAttr.cy, cy)
        r = animatedFloat(node, SVGAttr.r, r)
    }

    val changed = obj.updateBoundingBox(
        minX = cx - r,
        minY = cy - r,
        width = r * 2,
        height = r * 2
    )

    outPath.reset()
    outPath.addCircle(cx, cy, r, Path.Direction.CW)
    return changed
}

context(renderContext: DisplayContext)
internal fun updatePathAndBoundingBox(obj: EllipseShape, outPath: Path, node: PathRenderNode?): Boolean {
    var cx = obj.cx?.floatValueXInContext() ?: 0f
    var cy = obj.cy?.floatValueYInContext() ?: 0f
    // Missing rx/ry make the <ellipse> invalid -> not rendered (spec).
    val rxLength = obj.rx ?: return false
    val ryLength = obj.ry ?: return false
    var rx = rxLength.floatValueXInContext()
    var ry = ryLength.floatValueYInContext()

    if (renderContext is AnimationContext && node != null) {
        cx = animatedFloat(node, SVGAttr.cx, cx)
        cy = animatedFloat(node, SVGAttr.cy, cy)
        rx = animatedFloat(node, SVGAttr.rx, rx)
        ry = animatedFloat(node, SVGAttr.ry, ry)
    }

    val changed = obj.updateBoundingBox(
        minX = cx - rx,
        minY = cy - ry,
        width = rx * 2,
        height = ry * 2
    )

    outPath.reset()
    outPath.addOval(cx - rx, cy - ry, cx + rx, cy + ry, Path.Direction.CW)
    return changed
}

context(renderContext: DisplayContext)
internal fun updatePathAndBoundingBox(obj: LineShape, outPath: Path, node: PathRenderNode?): Boolean {
    var x1 = obj.x1?.floatValueXInContext() ?: 0f
    var y1 = obj.y1?.floatValueYInContext() ?: 0f
    var x2 = obj.x2?.floatValueXInContext() ?: 0f
    var y2 = obj.y2?.floatValueYInContext() ?: 0f

    if (renderContext is AnimationContext && node != null) {
        x1 = animatedFloat(node, SVGAttr.x1, x1)
        y1 = animatedFloat(node, SVGAttr.y1, y1)
        x2 = animatedFloat(node, SVGAttr.x2, x2)
        y2 = animatedFloat(node, SVGAttr.y2, y2)
    }

    val changed = obj.updateBoundingBox(
        minX = min(x1, x2),
        minY = min(y1, y2),
        width = abs(x2 - x1),
        height = abs(y2 - y1)
    )

    outPath.reset()
    outPath.moveTo(x1, y1)
    outPath.lineTo(x2, y2)
    return changed
}

context(poolOwner: PoolOwner)
internal fun updatePathAndBoundingBox(obj: PolyLineShape, outPath: Path, animatedPoints: FloatArray?): Boolean {
    val points = animatedPoints ?: obj.points ?: return false
    val numPoints = points.size
    if (numPoints % 2 != 0) return false

    outPath.reset()
    if (numPoints > 0) {
        outPath.moveTo(points[0], points[1])
        var i = 2
        while (i < numPoints) {
            outPath.lineTo(points[i], points[i + 1])
            i += 2
        }
        if (obj is PolygonShape) outPath.close()
    }

    return obj.updateBoundingBox(outPath)
}

internal fun updatePathAndBoundingBox(
    obj: PathShape,
    outPath: Path,
    @Suppress("unused") node: PathRenderNode?
): Boolean {
    val pathDef = obj.d
    return if (pathDef != null) {
        outPath.set(PathConverter(pathDef).path)
        true
    } else {
        false
    }
}

context(poolOwner: PoolOwner)
internal fun Element.updateBoundingBox(path: Path): Boolean {
    return poolOwner.rectFPool.withPooledObject { rect ->
        path.computeBounds(rect, true)
        updateBoundingBox(
            minX = rect.left,
            minY = rect.top,
            width = rect.width(),
            height = rect.height()
        )
    }
}

internal fun Element.updateBoundingBox(minX: Float, minY: Float, width: Float, height: Float): Boolean {
    val current = boundingBox
    return if (current == null || current.minX != minX || current.minY != minY || current.width != width || current.height != height) {
        boundingBox = Box(minX, minY, width, height)
        true
    } else {
        false
    }
}

context(renderContext: RenderContext)
internal fun RenderNode<*>.updateBoundingBox(path: Path) {
    renderContext.rectFPool.withPooledObject { rect ->
        path.computeBounds(rect, true)
        val minX = rect.left
        val minY = rect.top
        val width = rect.width()
        val height = rect.height()

        val current = boundingBox
        if (current == null || current.minX != minX || current.minY != minY || current.width != width || current.height != height) {
            boundingBox = Box(minX, minY, width, height)
        }
    }
}

context(poolOwner: PoolOwner)
internal fun calculatePathBounds(path: Path?, toRecycle: Box?): Box {
    return if (path == null) {
        Box.EMPTY
    } else {
        poolOwner.rectFPool.withPooledObject { rect ->
            path.computeBounds(rect, true)
            toRecycle?.copy(rect) ?: Box(rect)
        }
    }
}
