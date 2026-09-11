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

package hu.oandras.ksvg.render.filters.pipeline

/**
 * Bit-set of the primitive kinds contained by one filter graph. Collected once
 * per filter node and handed to [FilterBackend.supports] for the
 * graph-level backend decision.
 */
@JvmInline
internal value class FilterPrimitiveSet private constructor(@JvmField internal val bits: Int) {

    internal fun contains(flag: Int): Boolean = (bits and flag) != 0

    internal operator fun plus(other: FilterPrimitiveSet): FilterPrimitiveSet =
            FilterPrimitiveSet(bits or other.bits)

    internal companion object {
        @JvmStatic
        internal val EMPTY: FilterPrimitiveSet = FilterPrimitiveSet(0)

        internal const val FLAG_COLOR_MATRIX: Int = 1 shl 0
        internal const val FLAG_GAUSSIAN_BLUR: Int = 1 shl 1
        internal const val FLAG_OFFSET: Int = 1 shl 2
        internal const val FLAG_TURBULENCE: Int = 1 shl 3
        internal const val FLAG_DISPLACEMENT_MAP: Int = 1 shl 4
        internal const val FLAG_MORPHOLOGY: Int = 1 shl 5
        internal const val FLAG_CONVOLVE_MATRIX: Int = 1 shl 6
        internal const val FLAG_COMPOSITE: Int = 1 shl 7
        internal const val FLAG_BLEND: Int = 1 shl 8
        internal const val FLAG_DIFFUSE_LIGHTING: Int = 1 shl 9
        internal const val FLAG_SPECULAR_LIGHTING: Int = 1 shl 10
        internal const val FLAG_FLOOD: Int = 1 shl 11
        internal const val FLAG_IMAGE: Int = 1 shl 12
        internal const val FLAG_MERGE: Int = 1 shl 13
        internal const val FLAG_TILE: Int = 1 shl 14
        internal const val FLAG_DROP_SHADOW: Int = 1 shl 15
        internal const val FLAG_COMPONENT_TRANSFER: Int = 1 shl 16

        internal fun from(bits: Int): FilterPrimitiveSet = FilterPrimitiveSet(bits)
    }
}
