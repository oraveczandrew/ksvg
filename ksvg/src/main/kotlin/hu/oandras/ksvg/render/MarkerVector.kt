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

package hu.oandras.ksvg.render

import kotlin.math.hypot

//==============================================================================
// Marker handling
//==============================================================================
internal class MarkerVector(
    @JvmField
    val x: Float,
    @JvmField
    val y: Float,
    dx: Float,
    dy: Float
) {
    @JvmField
    var dx: Float = 0f

    @JvmField
    var dy: Float = 0f

    @JvmField
    var isAmbiguous: Boolean = false

    init {
        // normalise direction vector
        val len = hypot(dx, dy)
        if (len != 0f) {
            this.dx = dx / len
            this.dy = dy / len
        }
    }

    fun add(x: Float, y: Float) {
        // In order to get accurate angles, we have to normalize
        // all vectors before we add them.  As long as they are
        // all the same length, the angles will work out correctly.
        var dx = x - this.x
        var dy = y - this.y
        val len = hypot(dx, dy)
        if (len != 0f) {
            dx /= len
            dy /= len
        }
        // Check for degenerate result where the two unit vectors canceled each other out
        if (dx == -this.dx && dy == -this.dy) {
            this.isAmbiguous = true
            // Choose one of the perpendiculars now. We will get a chance to switch it later.
            this.dx = -dy
            this.dy = dx
        } else {
            this.dx += dx
            this.dy += dy
        }
    }

    fun add(v2: MarkerVector) {
        // Check for degenerate result where the two unit vectors canceled each other out
        if (v2.dx == -this.dx && v2.dy == -this.dy) {
            this.isAmbiguous = true
            // Choose one of the perpendiculars now. We will get a chance to switch it later.
            this.dx = -v2.dy
            this.dy = v2.dx
        } else {
            this.dx += v2.dx
            this.dy += v2.dy
        }
    }


    override fun toString(): String {
        return "($x,$y $dx,$dy)"
    }
}