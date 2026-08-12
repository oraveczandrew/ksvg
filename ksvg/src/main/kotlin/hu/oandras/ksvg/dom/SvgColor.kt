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

package hu.oandras.ksvg.dom

import androidx.annotation.ColorInt

internal sealed class SvgColor : SvgPaint()

// Special version of Color that indicates use of 'currentColor' keyword
internal object CurrentColor : SvgColor()

internal class ColorValue internal constructor(
    @ColorInt
    @JvmField
    val value: Int
) : SvgColor() {

    override fun toString(): String {
        return String.format("#%08x", value)
    }

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false

        other as ColorValue

        return value == other.value
    }

    override fun hashCode(): Int {
        return value
    }

    companion object {
        @JvmField
        val BLACK: ColorValue = ColorValue(COLOR_BLACK) // Black singleton - a common default value.
        @JvmField
        val TRANSPARENT: ColorValue = ColorValue(0) // Transparent black
    }
}