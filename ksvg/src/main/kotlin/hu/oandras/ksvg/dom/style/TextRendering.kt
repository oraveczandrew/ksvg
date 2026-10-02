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
 * SVG `text-rendering` property (`auto | optimizeSpeed | optimizeLegibility
 * | geometricPrecision`). Inherited. Only `optimizeSpeed` disables
 * antialiasing for glyph painting; the rest keep it enabled
 * (`optimizeLegibility` hinting subtleties are out of scope: Android
 * paints run with hinting off).
 */
@Suppress("EnumEntryName")
internal enum class TextRendering {
    auto,
    optimizeSpeed,
    optimizeLegibility,
    geometricPrecision;

    /** True when glyphs paint without antialiasing under this mode. */
    internal val disablesAntiAlias: Boolean
        get() = this == optimizeSpeed
}

// Parses a text-rendering property value; null when invalid.
internal fun parseTextRendering(value: String): TextRendering? {
    return when {
        value.equals("auto", ignoreCase = true) -> TextRendering.auto
        value.equals("optimizeSpeed", ignoreCase = true) -> TextRendering.optimizeSpeed
        value.equals("optimizeLegibility", ignoreCase = true) -> TextRendering.optimizeLegibility
        value.equals("geometricPrecision", ignoreCase = true) -> TextRendering.geometricPrecision
        else -> null
    }
}
