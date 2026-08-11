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

package hu.oandras.androidsvg.utils

import androidx.annotation.ColorInt
import androidx.annotation.IntRange
import hu.oandras.androidsvg.dom.COLOR_BLACK

internal fun pack3Hex(threeHex: Int): Int {
    val h1 = threeHex and 0xf00 // r
    val h2 = threeHex and 0x0f0 // g
    val h3 = threeHex and 0x00f // b
    return COLOR_BLACK or (h1 shl 12) or (h1 shl 8) or (h2 shl 8) or (h2 shl 4) or (h3 shl 4) or h3
}

internal fun pack4Hex(fourHex: Int): Int {
    val h1 = fourHex and 0xf000 // r
    val h2 = fourHex and 0x0f00 // g
    val h3 = fourHex and 0x00f0 // b
    val h4 = fourHex and 0x000f // alpha
    return (h4 shl 28) or (h4 shl 24) or (h1 shl 8) or (h1 shl 4) or (h2 shl 4) or h2 or h3 or (h3 shr 4)
}

internal fun pack8Hex(value: Int): Int {
    return (value shl 24) or (value ushr 8)
}

internal fun packRgba(r: Float, g: Float, b: Float, a: Float = Float.NaN): Int {
    return if (a.isNaN()) {
        COLOR_BLACK or (clamp255(r) shl 16) or (clamp255(g) shl 8) or clamp255(b)
    } else {
        (clamp255(a * 256f) shl 24) or (clamp255(r) shl 16) or (clamp255(g) shl 8) or clamp255(b)
    }
}

internal fun packHsla(hue: Float, sat: Float, light: Float, alpha: Float = Float.NaN): Int {
    val rgb = hslToRgb(hue, sat, light)
    return if (alpha.isNaN()) {
        COLOR_BLACK or rgb
    } else {
        (clamp255(alpha * 256f) shl 24) or rgb
    }
}

// Hue (degrees), saturation [0, 100], lightness [0, 100]
internal fun hslToRgb(hue: Float, sat: Float, light: Float): Int {
    var h = if (hue >= 0f) hue % 360f else (hue % 360f) + 360f // positive modulo (ie. -10 => 350)
    h /= 60f // [0, 360] -> [0, 6]
    val s = clamp(sat / 100f, 0f, 1f)
    val l = clamp(light / 100f, 0f, 1f)

    val t2 = if (l <= 0.5f) {
        l * (s + 1f)
    } else {
        l + s - (l * s)
    }
    val t1 = l * 2f - t2
    val r = hueToRgb(t1, t2, h + 2f)
    val g = hueToRgb(t1, t2, h)
    val b = hueToRgb(t1, t2, h - 2f)
    return (clamp255(r * 256f) shl 16) or (clamp255(g * 256f) shl 8) or clamp255(b * 256f)
}

private fun hueToRgb(t1: Float, t2: Float, hue: Float): Float {
    var h = hue
    if (h < 0f) h += 6f
    if (h >= 6f) h -= 6f

    return when {
        h < 1f -> (t2 - t1) * h + t1
        h < 3f -> t2
        h < 4f -> (t2 - t1) * (4f - h) + t1
        else -> t1
    }
}

@ColorInt
internal fun Int.colorWithOpacity(opacity: Float): Int {
    return withAlpha(clamp255(alpha * opacity))
}

@ColorInt
internal fun @receiver:ColorInt Int.withAlpha(@IntRange(from = 0L, to = 255L) alpha: Int): Int {
    return (alpha shl 24) or (this and 0x00FFFFFF)
}

@ColorInt
internal fun rgb(
    @IntRange(from = 0, to = 255) red: Int,
    @IntRange(from = 0, to = 255) green: Int,
    @IntRange(from = 0, to = 255) blue: Int,
): Int {
    return -0x1000000 or (red shl 16) or (green shl 8) or blue
}

@ColorInt
internal fun argb(
    @IntRange(from = 0, to = 255) alpha: Int,
    @IntRange(from = 0, to = 255) red: Int,
    @IntRange(from = 0, to = 255) green: Int,
    @IntRange(from = 0, to = 255) blue: Int,
): Int {
    return (alpha shl 24) or (red shl 16) or (green shl 8) or blue
}

internal inline val @receiver:ColorInt Int.alpha: Int
    get() = (this shr 24) and 0xff

internal inline val @receiver:ColorInt Int.red: Int
    get() = (this shr 16) and 0xff

internal inline val @receiver:ColorInt Int.green: Int
    get() = (this shr 8) and 0xff

internal inline val @receiver:ColorInt Int.blue: Int
    get() = this and 0xff
