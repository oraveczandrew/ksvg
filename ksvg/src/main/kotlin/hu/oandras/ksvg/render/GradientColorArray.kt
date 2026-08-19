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

import android.graphics.Color
import android.graphics.Paint
import android.os.Build
import androidx.annotation.ColorInt
import androidx.annotation.RequiresApi

internal sealed class GradientColorArray {
    abstract val size: Int
    abstract operator fun set(index: Int, @ColorInt color: Int)
    abstract fun setOnPaint(paint: Paint, index: Int)
    abstract fun contentHashCode(): Int

    class Ints(val array: IntArray) : GradientColorArray() {
        override val size: Int get() = array.size
        override fun set(index: Int, color: Int) {
            array[index] = color
        }

        override fun setOnPaint(paint: Paint, index: Int) {
            paint.setColor(array[index])
        }

        override fun contentHashCode(): Int = array.contentHashCode()
    }

    @RequiresApi(Build.VERSION_CODES.Q)
    class Longs(val array: LongArray) : GradientColorArray() {
        override val size: Int get() = array.size
        override fun set(index: Int, color: Int) {
            array[index] = Color.pack(color)
        }

        override fun setOnPaint(paint: Paint, index: Int) {
            paint.setColor(array[index])
        }

        override fun contentHashCode(): Int = array.contentHashCode()
    }
}