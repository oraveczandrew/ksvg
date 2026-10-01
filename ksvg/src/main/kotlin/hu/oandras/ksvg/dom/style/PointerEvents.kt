/*
 *    Copyright 2026 András Oravecz <info@oandras.hu>
 *
 *    Licensed under the Apache License, Version 2.0 (the "License");
 *    you may not use this file except in compliance with the License.
 *    You may obtain a copy of the License at
 *
 *        https://www.apache.org/licenses/LICENSE-2.0
 *
 *    Unless required by applicable law or agreed to in writing, software
 *    distributed under the License is distributed on an "AS IS" BASIS,
 *    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *    See the License for the specific language governing permissions and
 *    limitations under the License.
 */

package hu.oandras.ksvg.dom.style

/**
 * CSS `pointer-events` property for SVG (`visiblePainted | visibleFill |
 * visibleStroke | visible | painted | fill | stroke | all | none`). Inherited.
 *
 * Hit-test coverage is intentionally middle-ground (touch screens make
 * stroke-level precision meaningless): only [none] is honored (the element
 * contributes no hit region); every other value keeps the bounding-box
 * region. `visibility` is applied separately at the hit-test walk.
 */
@Suppress("EnumEntryName")
internal enum class PointerEvents {
    visiblePainted,
    visibleFill,
    visibleStroke,
    visible,
    painted,
    fill,
    stroke,
    all,
    none;
}

// Parses a pointer-events value; null when invalid.
internal fun parsePointerEvents(value: String): PointerEvents? {
    return when {
        value.equals("visiblePainted", ignoreCase = true) -> PointerEvents.visiblePainted
        value.equals("visibleFill", ignoreCase = true) -> PointerEvents.visibleFill
        value.equals("visibleStroke", ignoreCase = true) -> PointerEvents.visibleStroke
        value.equals("visible", ignoreCase = true) -> PointerEvents.visible
        value.equals("painted", ignoreCase = true) -> PointerEvents.painted
        value.equals("fill", ignoreCase = true) -> PointerEvents.fill
        value.equals("stroke", ignoreCase = true) -> PointerEvents.stroke
        value.equals("all", ignoreCase = true) -> PointerEvents.all
        value.equals("none", ignoreCase = true) -> PointerEvents.none
        else -> null
    }
}
