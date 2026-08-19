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

import android.graphics.RectF
import hu.oandras.ksvg.dom.core.Box
import hu.oandras.ksvg.dom.core.Region
import hu.oandras.ksvg.dom.filter.FilterPrimitive

context(renderContext: RenderContext)
internal fun calculateRegion(region: Region, originalObjBBox: Box, outRect: RectF) {
    val unitsAreUser = region.unitsAreUser == true

    val x: Float
    val y: Float
    val w: Float
    val h: Float

    if (unitsAreUser) {
        x = region.x?.floatValueXInContext() ?: (originalObjBBox.minX - 0.1f * originalObjBBox.width)
        y = region.y?.floatValueYInContext() ?: (originalObjBBox.minY - 0.1f * originalObjBBox.height)
        w = region.width?.floatValueXInContext() ?: (1.2f * originalObjBBox.width)
        h = region.height?.floatValueYInContext() ?: (1.2f * originalObjBBox.height)
    } else {
        val _x = region.x?.floatValueInContext(1f) ?: -0.1f
        val _y = region.y?.floatValueInContext(1f) ?: -0.1f
        val _w = region.width?.floatValueInContext(1f) ?: 1.2f
        val _h = region.height?.floatValueInContext(1f) ?: 1.2f
        x = originalObjBBox.minX + _x * originalObjBBox.width
        y = originalObjBBox.minY + _y * originalObjBBox.height
        w = _w * originalObjBBox.width
        h = _h * originalObjBBox.height
    }

    outRect.set(x, y, x + w, y + h)
}

context(renderContext: RenderContext)
internal fun calculatePrimitiveRegion(
    primitive: FilterPrimitive,
    filterRegion: RectF,
    unitsAreUser: Boolean,
    originalObjBBox: Box,
    outRect: RectF
) {
    val x: Float
    val y: Float
    val w: Float
    val h: Float

    if (unitsAreUser) {
        x = primitive.x?.floatValueXInContext() ?: filterRegion.left
        y = primitive.y?.floatValueYInContext() ?: filterRegion.top
        w = primitive.width?.floatValueXInContext() ?: filterRegion.width()
        h = primitive.height?.floatValueYInContext() ?: filterRegion.height()
    } else {
        val _x = primitive.x?.floatValueInContext(1f)
        val _y = primitive.y?.floatValueInContext(1f)
        val _w = primitive.width?.floatValueInContext(1f)
        val _h = primitive.height?.floatValueInContext(1f)

        x = if (_x != null) {
            originalObjBBox.minX + _x * originalObjBBox.width
        } else {
            filterRegion.left
        }

        y = if (_y != null) {
            originalObjBBox.minY + _y * originalObjBBox.height
        } else {
            filterRegion.top
        }

        w = if (_w != null) {
            _w * originalObjBBox.width
        } else {
            filterRegion.width()
        }

        h = if (_h != null) {
            _h * originalObjBBox.height
        } else {
            filterRegion.height()
        }
    }

    outRect.set(x, y, x + w, y + h)
    // Always clip to filter region
    outRect.intersect(filterRegion)
}
