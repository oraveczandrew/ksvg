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
 * SVG `shape-rendering` property (`auto | optimizeSpeed | crispEdges |
 * geometricPrecision`). Inherited. `optimizeSpeed`/`crispEdges` disable
 * antialiasing for shape painting; the rest keep it enabled.
 */
@Suppress("EnumEntryName")
internal enum class ShapeRendering {
    auto,
    optimizeSpeed,
    crispEdges,
    geometricPrecision;

    /** True when shapes paint without antialiasing under this mode. */
    internal val disablesAntiAlias: Boolean
        get() = this == optimizeSpeed || this == crispEdges
}

// Parses a shape-rendering property value; null when invalid.
internal fun parseShapeRendering(value: String): ShapeRendering? {
    return when {
        value.equals("auto", ignoreCase = true) -> ShapeRendering.auto
        value.equals("optimizeSpeed", ignoreCase = true) -> ShapeRendering.optimizeSpeed
        value.equals("crispEdges", ignoreCase = true) -> ShapeRendering.crispEdges
        value.equals("geometricPrecision", ignoreCase = true) -> ShapeRendering.geometricPrecision
        else -> null
    }
}
