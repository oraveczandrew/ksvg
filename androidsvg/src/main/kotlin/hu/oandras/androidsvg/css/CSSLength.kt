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

package hu.oandras.androidsvg.css

import hu.oandras.androidsvg.render.RenderContext
import kotlin.math.hypot

private const val SQRT2 = 1.414213562373095

internal data class CSSLength(
    @JvmField
    val value: Float,
    @JvmField
    internal val unit: CssUnit
) : Cloneable {

    constructor(value: Float): this(
        value = value,
        unit = CssUnit.px
    )

    fun floatValue(): Float {
        return value
    }

    // Convert length to user units for a horizontally-related context.
    fun floatValueX(renderContext: RenderContext): Float {
        return when (unit) {
            CssUnit.em -> value * renderContext.currentFontSize
            CssUnit.ex -> value * renderContext.currentFontXHeight
            CssUnit.`in` -> value * renderContext.dPI
            CssUnit.cm -> value * renderContext.dPI / 2.54f
            CssUnit.mm -> value * renderContext.dPI / 25.4f
            CssUnit.pt -> value * renderContext.dPI / 72f
            CssUnit.pc -> value * renderContext.dPI / 6f
            CssUnit.percent -> {
                val viewPortUser = renderContext.effectiveViewPortInUserUnits

                value * viewPortUser.width / 100f
            }

            CssUnit.px -> value
        }
    }

    // Convert length to user units for a vertically-related context.
    fun floatValueY(renderContext: RenderContext): Float {
        return if (unit == CssUnit.percent) {
            val viewPortUser = renderContext.effectiveViewPortInUserUnits

            value * viewPortUser.height / 100f
        } else {
            floatValueX(renderContext)
        }
    }

    // Convert length to user units for a context that is not orientation specific.
    // For example, stroke width.
    fun floatValue(renderContext: RenderContext): Float {
        return if (unit == CssUnit.percent) {
            val viewPortUser = renderContext.effectiveViewPortInUserUnits

            val w = viewPortUser.width
            val h = viewPortUser.height
            if (w == h) value * w / 100f
            else {
                val n = (hypot(w, h) / SQRT2).toFloat() // see spec section 7.10
                value * n / 100f
            }
        } else {
            floatValueX(renderContext)
        }
    }

    // Convert length to user units for a context that is not orientation specific.
    // For percentage values, use the given 'max' parameter to represent the 100% value.
    fun floatValue(renderContext: RenderContext, max: Float): Float {
        return if (unit == CssUnit.percent) {
            value * max / 100f
        } else {
            floatValueX(renderContext)
        }
    }

    // For situations (like calculating the initial viewport) when we can only rely on
    // physical real world units.
    fun floatValue(dpi: Float): Float {
        return when (unit) {
            CssUnit.`in` -> value * dpi
            CssUnit.cm -> value * dpi / 2.54f
            CssUnit.mm -> value * dpi / 25.4f
            CssUnit.pt -> value * dpi / 72f
            CssUnit.pc -> value * dpi / 6f
            CssUnit.px,
            CssUnit.em,
            CssUnit.ex,
            CssUnit.percent -> value
        }
    }

    val isZero: Boolean
        get() = value == 0f

    val isNegative: Boolean
        get() = value < 0f

    override fun toString(): String {
        return "$value$unit"
    }

    companion object {
        @JvmField
        val ZERO: CSSLength = CSSLength(0f)
        @JvmField
        val PERCENT_50: CSSLength = CSSLength(50f, CssUnit.percent)
        @JvmField
        val PERCENT_100: CSSLength = CSSLength(100f, CssUnit.percent)
    }
}