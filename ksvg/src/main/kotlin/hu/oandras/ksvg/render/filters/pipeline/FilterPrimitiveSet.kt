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
        internal const val FLAG_COLOR_MATRIX: Int = 1 shl 5
    }
}
