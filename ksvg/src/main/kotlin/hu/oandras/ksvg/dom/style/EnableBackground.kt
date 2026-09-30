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

/**
 * Parsed value of the SVG 1.1 `enable-background` property
 * (`accumulate | new [<x> <y> <width> <height>]`).
 *
 * The property is not inherited: each container element either accumulates
 * into the parent backdrop ([Accumulate], the initial value) or establishes
 * a new one ([New], optionally clipped to [bounds]).
 *
 * Backdrop capture itself is not implemented yet (BackgroundImage resolves
 * to transparent); the parsed value is stored so Phase B can consume it.
 */
internal sealed interface EnableBackground {

    data object Accumulate : EnableBackground {

        override fun toString(): String = "accumulate"
    }

    /**
     * @param x subregion origin x in user space, null when `new` has no bounds
     * @param y subregion origin y in user space, null when `new` has no bounds
     * @param width subregion width in user space, null when `new` has no bounds
     * @param height subregion height in user space, null when `new` has no bounds
     */
    data class New(
        val x: Float?,
        val y: Float?,
        val width: Float?,
        val height: Float?,
    ) : EnableBackground {

        override fun toString(): String =
            if (x == null || y == null || width == null || height == null) {
                "new"
            } else {
                "new $x $y $width $height"
            }
    }
}

// Parses an enable-background property value; null when invalid.
internal fun parseEnableBackground(value: String): EnableBackground? {
    val tokens = value.trim().split(BACKGROUND_SPLIT_REGEX).filter { it.isNotEmpty() }
    if (tokens.isEmpty()) return null
    if (tokens[0].equals("accumulate", ignoreCase = true)) {
        return if (tokens.size == 1) EnableBackground.Accumulate else null
    }
    if (tokens[0].equals("new", ignoreCase = true)) {
        if (tokens.size == 1) {
            return EnableBackground.New(null, null, null, null)
        }
        if (tokens.size == 5) {
            val x = tokens[1].toFloatOrNull() ?: return null
            val y = tokens[2].toFloatOrNull() ?: return null
            val width = tokens[3].toFloatOrNull() ?: return null
            val height = tokens[4].toFloatOrNull() ?: return null
            return EnableBackground.New(x, y, width, height)
        }
        return null
    }
    return null
}

private val BACKGROUND_SPLIT_REGEX: Regex = Regex("[\\s,]+")
