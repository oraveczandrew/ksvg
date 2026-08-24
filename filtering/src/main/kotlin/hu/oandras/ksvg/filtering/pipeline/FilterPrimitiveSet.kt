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

package hu.oandras.ksvg.filtering.pipeline

/**
 * Bit-set of the primitive kinds contained by one filter graph. Handed to
 * [FilterBackend.supports] for the graph-level backend decision.
 *
 * This type is capability-only and lives in the `:filtering` module so the
 * whole backend infrastructure can too; the mapping from concrete SVG DOM
 * render nodes to flags stays in the `:ksvg` module (`internal`).
 */
@JvmInline
public value class FilterPrimitiveSet public constructor(@JvmField public val bits: Int) {

    public operator fun contains(flag: Int): Boolean = (bits and flag) != 0

    public inline fun has(flag: Int): Boolean = (bits and flag) != 0

    public operator fun plus(other: FilterPrimitiveSet): FilterPrimitiveSet =
            FilterPrimitiveSet(bits or other.bits)

    public companion object {
        public const val FLAG_FLOOD: Int = 1 shl 0
        public const val FLAG_BLEND: Int = 1 shl 1
        public const val FLAG_TILE: Int = 1 shl 2
        public const val FLAG_DROP_SHADOW: Int = 1 shl 3
        public const val FLAG_GAUSSIAN_BLUR: Int = 1 shl 4
        public const val FLAG_COLOR_MATRIX: Int = 1 shl 5
        public const val FLAG_OFFSET: Int = 1 shl 6
        public const val FLAG_MERGE: Int = 1 shl 7
        public const val FLAG_CONVOLVE_MATRIX: Int = 1 shl 8
        public const val FLAG_MORPHOLOGY: Int = 1 shl 9
        public const val FLAG_COMPONENT_TRANSFER: Int = 1 shl 10
        public const val FLAG_COMPOSITE: Int = 1 shl 11
        public const val FLAG_TURBULENCE: Int = 1 shl 12
        public const val FLAG_DISPLACEMENT_MAP: Int = 1 shl 13
        public const val FLAG_DIFFUSE_LIGHTING: Int = 1 shl 14
        public const val FLAG_SPECULAR_LIGHTING: Int = 1 shl 15
        public const val FLAG_IMAGE: Int = 1 shl 16

        public val EMPTY: FilterPrimitiveSet = FilterPrimitiveSet(0)
    }
}
