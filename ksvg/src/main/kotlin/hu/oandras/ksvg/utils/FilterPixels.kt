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

package hu.oandras.ksvg.utils

import hu.oandras.ksvg.dom.ConvolveMatrixEdgeMode
import hu.oandras.ksvg.dom.FeChannelSelector

internal fun channelSelectorValue(pixel: Int, selector: FeChannelSelector): Float {
    return when (selector) {
        FeChannelSelector.R -> pixel.red / 255f
        FeChannelSelector.G -> pixel.green / 255f
        FeChannelSelector.B -> pixel.blue / 255f
        FeChannelSelector.A -> pixel.alpha / 255f
    }
}

internal fun sampleCoordinate(coordinate: Int, limit: Int, edgeMode: ConvolveMatrixEdgeMode): Int {
    return if (coordinate in 0 until limit) {
        coordinate
    } else {
        when (edgeMode) {
            ConvolveMatrixEdgeMode.none -> -1
            ConvolveMatrixEdgeMode.wrap -> {
                val m = coordinate % limit
                if (m < 0) m + limit else m
            }
            ConvolveMatrixEdgeMode.duplicate -> clamp(coordinate, 0, limit - 1)
        }
    }
}
