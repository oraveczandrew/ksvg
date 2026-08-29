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

package hu.oandras.ksvg.render.filters

import android.graphics.Bitmap
import android.graphics.Paint
import android.graphics.PorterDuff
import android.graphics.RectF
import hu.oandras.ksvg.dom.style.Style
import hu.oandras.ksvg.render.FeDropShadowRenderNode
import hu.oandras.ksvg.render.FeFloodRenderNode
import hu.oandras.ksvg.render.FilterSourceMap
import hu.oandras.ksvg.render.RenderContext
import hu.oandras.ksvg.render.pool.withPooledObject

context(renderContext: RenderContext)
internal fun doFeFloodFilter(
    primitiveNode: FeFloodRenderNode,
    inputBitmap: Bitmap,
    primitiveRegion: RectF,
    filterRegion: RectF,
    baseStyle: Style,
): Bitmap {
    val color = renderContext.resolveFloodColor(primitiveNode, baseStyle)

    val res = renderContext.bitmapPool.acquireSameAs(inputBitmap)
    renderContext.canvasPool.withPooledObject { c ->
        c.setBitmap(res)
        val clipLeft = (primitiveRegion.left - filterRegion.left)
        val clipTop = (primitiveRegion.top - filterRegion.top)
        val clipRight = (primitiveRegion.right - filterRegion.left)
        val clipBottom = (primitiveRegion.bottom - filterRegion.top)

        val paint = Paint()
        paint.color = color
        c.drawRect(clipLeft, clipTop, clipRight, clipBottom, paint)
    }
    return res
}

context(renderContext: RenderContext)
internal fun doFeDropShadowFilter(
    primitiveNode: FeDropShadowRenderNode,
    inputBitmap: Bitmap,
    results: FilterSourceMap,
    lastResult: Bitmap?,
    primitiveUnitsAreUser: Boolean,
    primitiveScaleX: Float,
    primitiveScaleY: Float,
    canvasScaleX: Float,
    canvasScaleY: Float,
    primitiveRegion: RectF,
    filterRegion: RectF,
    baseStyle: Style,
): Bitmap {
    val primitive = primitiveNode.sourceElement

    // The shadow silhouette is derived from the input's alpha.
    val sourceAlpha = getFilterInput("SourceAlpha", results, lastResult)
        ?: getFilterInput(primitive.`in`, results, lastResult)
        ?: return inputBitmap

    // 1. Blur the silhouette.
    val blurred = doFeGaussianBlurFilter(
        primitiveNode = primitiveNode.blurNode,
        inputBitmap = sourceAlpha,
        primitiveScaleX = primitiveScaleX,
        primitiveScaleY = primitiveScaleY,
        primitiveRegion = primitiveRegion,
        filterRegion = filterRegion,
    )

    // 2. Offset the blurred silhouette by dx, dy.
    val offset = doFeOffsetFilter(
        primitiveNode = primitiveNode.offsetNode,
        inputBitmap = blurred,
        primitiveUnitsAreUser = primitiveUnitsAreUser,
        primitiveScaleX = primitiveScaleX,
        primitiveScaleY = primitiveScaleY,
        canvasScaleX = canvasScaleX,
        canvasScaleY = canvasScaleY,
        primitiveRegion = primitiveRegion,
        filterRegion = filterRegion,
    )

    // 3. Resolve the flood color/opacity from the element's style.
    val floodColorInt = renderContext.resolveFloodColor(primitiveNode, baseStyle)

    // 4. Color the offset silhouette with the flood color.
    val shadow = renderContext.bitmapPool.acquireSameAs(inputBitmap)
    renderContext.canvasPool.withPooledObject { c ->
        c.setBitmap(shadow)
        c.drawColor(floodColorInt, PorterDuff.Mode.SRC)
        c.drawBitmap(offset, 0f, 0f, primitiveNode.shadowPaint)
    }

    // 5. Composite the original graphic on top of the shadow.
    val res = renderContext.bitmapPool.acquireSameAs(inputBitmap)
    renderContext.canvasPool.withPooledObject { c ->
        c.setBitmap(res)
        c.drawBitmap(shadow, 0f, 0f, null)
        c.drawBitmap(inputBitmap, 0f, 0f, null)
    }
    return res
}
