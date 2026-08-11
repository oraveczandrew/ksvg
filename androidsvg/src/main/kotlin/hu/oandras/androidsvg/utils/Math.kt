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

package hu.oandras.androidsvg.utils

import kotlin.math.PI
import kotlin.math.ceil
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

internal fun clamp(n: Double, min: Double, max: Double): Double {
    return max(min, min(n, max))
}

internal fun clamp(n: Float, min: Float, max: Float): Float {
    return max(min, min(n, max))
}

internal fun clamp(n: Int, min: Int, max: Int): Int {
    return max(min, min(n, max))
}

// Clamp a value to the range 0..255
internal fun clamp255(value: Double): Int {
    return clamp(value.roundToInt(), 0, 255)
}

internal fun clamp255(value: Float): Int {
    return clamp(value.roundToInt(), 0, 255)
}

internal fun clamp255(value: Int): Int {
    return clamp(value,0,255)
}

internal fun Double.toRadians(): Double = this * PI / 180.0
internal fun Double.toDegrees(): Double = this * 180.0 / PI

internal fun Float.toRadians(): Float = (this * PI / 180.0).toFloat()
internal fun Float.toDegrees(): Float = (this * 180.0 / PI).toFloat()

internal fun Float.ceilToInt(): Int {
    return ceil(this).toInt()
}

internal fun Int.squared(): Int = Math.multiplyExact(this, this)