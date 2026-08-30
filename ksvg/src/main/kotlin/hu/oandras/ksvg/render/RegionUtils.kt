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

context(renderContext: DisplayContext)
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

context(renderContext: DisplayContext)
internal fun calculatePrimitiveRegion(
    primitive: FilterPrimitive,
    filterRegion: RectF,
    unitsAreUser: Boolean,
    originalObjBBox: Box,
    outRect: RectF,
    resolveInputRegion: (String?) -> RectF? = { null },
) {
    val x: Float
    val y: Float
    val w: Float
    val h: Float

    // Per the SVG Filter Effects spec, a primitive that omits x/y/width/height and whose
    // input is a referenced node's result defaults its subregion to the union of the
    // referenced node(s)' subregions (falling back to the filter region only for standard
    // inputs such as SourceGraphic/SourceAlpha or when there is no referenced subregion).
    val inputRegion = resolveInputRegion(primitive.`in`)

    if (unitsAreUser) {
        x = primitive.x?.floatValueXInContext()
            ?: inputRegion?.left
                    ?: filterRegion.left
        y = primitive.y?.floatValueYInContext()
            ?: inputRegion?.top
                    ?: filterRegion.top
        w = primitive.width?.floatValueXInContext()
            ?: inputRegion?.let { it.right - it.left }
                    ?: filterRegion.width()
        h = primitive.height?.floatValueYInContext()
            ?: inputRegion?.let { it.bottom - it.top }
                    ?: filterRegion.height()
    } else {
        val px = primitive.x
        val py = primitive.y
        val pw = primitive.width
        val ph = primitive.height
        x = if (px != null) {
            originalObjBBox.minX + px.floatValueInContext(1f) * originalObjBBox.width
        } else {
            inputRegion?.left ?: filterRegion.left
        }
        y = if (py != null) {
            originalObjBBox.minY + py.floatValueInContext(1f) * originalObjBBox.height
        } else {
            inputRegion?.top ?: filterRegion.top
        }
        w = if (pw != null) {
            pw.floatValueInContext(1f) * originalObjBBox.width
        } else {
            inputRegion?.let { it.right - it.left } ?: filterRegion.width()
        }
        h = if (ph != null) {
            ph.floatValueInContext(1f) * originalObjBBox.height
        } else {
            inputRegion?.let { it.bottom - it.top } ?: filterRegion.height()
        }
    }

    outRect.set(x, y, x + w, y + h)
    // Always clip to filter region
    outRect.intersect(filterRegion)
}

/**
 * Fills [out] with the union of the referenced input node(s)' subregions in user space, which
 * is what a primitive that omits x/y/width/height defaults its subregion to (per the SVG
 * Filter Effects spec). Standard inputs (no `in`, SourceGraphic, SourceAlpha) span the full
 * filter region; a non-first primitive with `in == null` means the previous primitive's result
 * and inherits its subregion; named inputs use their recorded subregion.
 *
 * @param inputIds the input identifier(s): feMerge nodes, or a single entry for other
 * primitives.
 * @param isMerge true for an feMerge primitive (whose inputs never inherit the previous
 * primitive's subregion).
 * @param standardFilterRegion the full filter region (default for standard inputs).
 * @param namedRegion resolves a named result id to its recorded subregion, or null if unknown
 * (e.g. an unregistered standard-input name).
 * @param lastResultRegion the previous primitive's subregion (used when `in == null` on a
 * non-first, non-merge primitive).
 * @param out receives the resulting user-space union.
 * @return true iff [out] was set (there was at least one resolvable input).
 */
internal fun resolvePrimitiveInputRegion(
    inputIds: List<String?>,
    isMerge: Boolean,
    standardFilterRegion: RectF,
    namedRegion: (String?) -> RectF?,
    lastResultRegion: RectF,
    out: RectF,
): Boolean {
    out.setEmpty()
    var has = false
    for (id in inputIds) {
        val standard = id == "SourceGraphic" || id == "SourceAlpha"
        val r = when {
            isMerge && id == null -> standardFilterRegion
            !isMerge && id == null -> lastResultRegion
            else -> namedRegion(id) ?: if (standard) standardFilterRegion else null
        } ?: continue
        if (has) {
            out.union(r)
        } else {
            out.set(r)
        }
        has = true
    }
    return has
}
