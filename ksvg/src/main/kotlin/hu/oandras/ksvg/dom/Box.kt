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

import android.graphics.RectF

public data class Box(
    @JvmField
    var minX: Float,
    @JvmField
    var minY: Float,
    @JvmField
    var width: Float,
    @JvmField
    var height: Float,
) {

    public constructor(rect: RectF): this(
        minX = rect.left,
        minY = rect.top,
        width = rect.right - rect.left,
        height = rect.bottom - rect.top,
    )

    internal fun toRectF(): RectF {
        return RectF(minX, minY, maxX(), maxY())
    }

    internal fun maxX(): Float {
        return minX + width
    }

    internal fun maxY(): Float {
        return minY + height
    }

    internal fun union(other: Box) {
        if (other.minX < minX) minX = other.minX
        if (other.minY < minY) minY = other.minY
        if (other.maxX() > maxX()) width = other.maxX() - minX
        if (other.maxY() > maxY()) height = other.maxY() - minY
    }

    override fun toString(): String {
        return "[$minX $minY $width $height]"
    }

    internal companion object {
        @JvmStatic
        fun fromLimits(minX: Float, minY: Float, maxX: Float, maxY: Float): Box {
            return Box(minX, minY, maxX - minX, maxY - minY)
        }
    }
}