/*
 *    Copyright 2026 András Oravecz <info@oandras.hu>
 *
 *    Licensed under the Apache License, Version 2.0 (the "License");
 *    you may not use this file except in compliance with the License.
 *    You may obtain a copy of the License at
 *
 *        https://www.apache.org/licenses/LICENSE-2.0
 *
 *    Unless required by applicable law or agreed to in writing, software
 *    distributed under the License is distributed on an "AS IS" BASIS,
 *    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *    See the License for the specific language governing permissions and
 *    limitations under the License.
 */

package hu.oandras.ksvg.render

import android.graphics.Matrix
import hu.oandras.ksvg.css.CSSLength
import hu.oandras.ksvg.css.CssUnit
import hu.oandras.ksvg.dom.core.Box
import hu.oandras.ksvg.dom.style.TransformOrigin
import hu.oandras.ksvg.render.pool.Pool
import hu.oandras.ksvg.render.pool.withPooledObject

/**
 * Wraps [matrix] with a CSS `transform-origin` pivot (`T(origin) x matrix
 * x T(-origin)`), in place. Percentages resolve against [refBox]; lengths
 * resolve in viewport context. A (0,0) origin is a no-op (the SVG initial
 * for elements without a CSS box). The scratch matrix comes from
 * [matrixPool]: no allocation on either the build or the animation path.
 */
context(displayContext: DisplayContext)
internal fun applyTransformOrigin(
    matrix: Matrix,
    origin: TransformOrigin,
    refBox: Box,
    matrixPool: Pool<Matrix>,
) {
    val ox = resolveOriginComponent(origin.x, refBox.minX, refBox.width, isX = true)
    val oy = resolveOriginComponent(origin.y, refBox.minY, refBox.height, isX = false)
    if (ox == 0f && oy == 0f) return
    // Android pre* right-multiplies (appends), post* left-multiplies
    // (prepends): postConcat(T(o)) then preConcat(T(-o)) yields T(o)*M*T(-o).
    matrixPool.withPooledObject { tmp ->
        tmp.setTranslate(ox, oy)
        matrix.postConcat(tmp)
        tmp.setTranslate(-ox, -oy)
        matrix.preConcat(tmp)
    }
}

context(displayContext: DisplayContext)
private fun resolveOriginComponent(c: CSSLength, min: Float, size: Float, isX: Boolean): Float {
    // Percentages resolve against the reference box (NOT the viewport:
    // floatValueXInContext would use the viewport for percents).
    return if (c.unit == CssUnit.percent) {
        min + c.value * size / 100f
    } else if (isX) {
        c.floatValueXInContext()
    } else {
        c.floatValueYInContext()
    }
}
