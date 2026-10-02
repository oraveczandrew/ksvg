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

package hu.oandras.ksvg.dom.style

import hu.oandras.ksvg.utils.parseFloatOrElse
import hu.oandras.ksvg.utils.splitBy

/**
 * Parsed value of the SVG 1.1 `enable-background` property
 * (`accumulate | new [<x> <y> <width> <height>]`).
 *
 * The property is not inherited: each container element either accumulates
 * into the parent backdrop ([EnableBackground.Accumulate], the initial value) or establishes
 * a new one ([EnableBackground.New], optionally clipped to a subregion).
 *
 * Backdrop capture itself is not implemented yet (BackgroundImage resolves
 * to transparent); the parsed value is stored so Phase B can consume it.
 */
internal sealed interface EnableBackground {

    data object Accumulate : EnableBackground {

        override fun toString(): String = "accumulate"
    }

    /**
     * @param x subregion origin x in user space, NaN when `new` has no bounds
     * @param y subregion origin y in user space, NaN when `new` has no bounds
     * @param width subregion width in user space, NaN when `new` has no bounds
     * @param height subregion height in user space, NaN when `new` has no bounds
     */
    data class New(
        @JvmField
        val x: Float,
        @JvmField
        val y: Float,
        @JvmField
        val width: Float,
        @JvmField
        val height: Float,
    ) : EnableBackground {

        override fun toString(): String =
            if (x.isNaN() || y.isNaN() || width.isNaN() || height.isNaN()) {
                "new"
            } else {
                "new $x $y $width $height"
            }
    }
}

// Parses an enable-background property value; null when invalid.
internal fun parseEnableBackground(value: String): EnableBackground? {
    val tokens = value.splitBy { it == ',' || it <= ' ' }

    if (tokens.isEmpty()) return null

    if (tokens[0].equals("accumulate", ignoreCase = true)) {
        return if (tokens.size == 1) {
            EnableBackground.Accumulate
        } else {
            null
        }
    }

    if (tokens[0].equals("new", ignoreCase = true)) {
        if (tokens.size == 1) {
            return EnableBackground.New(Float.NaN, Float.NaN, Float.NaN, Float.NaN)
        }

        if (tokens.size == 5) {
            val x = tokens[1].parseFloatOrElse { return null }
            val y = tokens[2].parseFloatOrElse { return null }
            val width = tokens[3].parseFloatOrElse { return null }
            val height = tokens[4].parseFloatOrElse { return null }
            return EnableBackground.New(x, y, width, height)
        }
    }

    return null
}
