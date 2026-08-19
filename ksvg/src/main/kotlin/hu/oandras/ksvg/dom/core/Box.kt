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

package hu.oandras.ksvg.dom.core

import android.graphics.RectF
import kotlin.math.ceil
import kotlin.math.floor

public class Box(
    @JvmField
    public val minX: Float,
    @JvmField
    public val minY: Float,
    @JvmField
    public val width: Float,
    @JvmField
    public val height: Float,
) {

    public constructor(rect: RectF): this(
        minX = floor(rect.left),
        minY = floor(rect.top),
        width = ceil(rect.right) - floor(rect.left),
        height = ceil(rect.bottom) - floor(rect.top),
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

    public fun copy(
        minX: Float = this.minX,
        minY: Float = this.minY,
        width: Float = this.width,
        height: Float = this.height,
    ): Box {
        return if (minX == this.minX && minY == this.minY && width == this.width && height == this.height) {
            this
        } else {
            Box(minX, minY, width, height)
        }
    }

    @Suppress("IntroduceWhenSubject")
    internal fun union(other: Box): Box {
        val uMinX = if (other.minX < minX) other.minX else minX
        val uMinY = if (other.minY < minY) other.minY else minY
        val uMaxX = if (other.maxX() > maxX()) other.maxX() else maxX()
        val uMaxY = if (other.maxY() > maxY()) other.maxY() else maxY()

        val uWidth = uMaxX - uMinX
        val uHeight = uMaxY - uMinY

        return when {
            uMinX == minX && uMinY == minY && uWidth == width && uHeight == height -> {
                this
            }
            uMinX == other.minX && uMinY == other.minY && uWidth == other.width && uHeight == other.height -> {
                other
            }
            else -> {
                Box(uMinX, uMinY, uWidth, uHeight)
            }
        }
    }

    internal fun union(
        otherMinX: Float,
        otherMinY: Float,
        otherMaxX: Float,
        otherMaxY: Float
    ): Box {
        val fOtherMinX = floor(otherMinX)
        val fOtherMinY = floor(otherMinY)
        val cOtherMaxX = ceil(otherMaxX)
        val cOtherMaxY = ceil(otherMaxY)

        val uMinX = if (fOtherMinX < minX) fOtherMinX else minX
        val uMinY = if (fOtherMinY < minY) fOtherMinY else minY
        val uMaxX = if (cOtherMaxX > maxX()) cOtherMaxX else maxX()
        val uMaxY = if (cOtherMaxY > maxY()) cOtherMaxY else maxY()

        val uWidth = uMaxX - uMinX
        val uHeight = uMaxY - uMinY

        return if (uMinX == minX && uMinY == minY && uWidth == width && uHeight == height) {
            this
        } else {
            Box(uMinX, uMinY, uWidth, uHeight)
        }
    }

    override fun toString(): String {
        return "[$minX $minY $width $height]"
    }

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false

        other as Box

        if (minX != other.minX) return false
        if (minY != other.minY) return false
        if (width != other.width) return false
        if (height != other.height) return false

        return true
    }

    override fun hashCode(): Int {
        var result = minX.hashCode()
        result = 31 * result + minY.hashCode()
        result = 31 * result + width.hashCode()
        result = 31 * result + height.hashCode()
        return result
    }

    internal companion object {
        @JvmStatic
        fun fromLimits(minX: Float, minY: Float, maxX: Float, maxY: Float): Box {
            return Box(minX, minY, maxX - minX, maxY - minY)
        }

        @Suppress("ObjectPropertyName")
        @JvmField
        internal val _1X1 = Box(0f, 0f, 1f, 1f)

        @JvmField
        internal val EMPTY = Box(0f, 0f, 0f, 0f)

        @JvmField
        internal val UNRESOLVED = Box(-1f, -1f, -1f, -1f)
    }
}