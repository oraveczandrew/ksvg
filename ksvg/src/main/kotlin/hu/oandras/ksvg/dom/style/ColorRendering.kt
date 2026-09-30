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
 * SVG `color-rendering` property (`auto | optimizeSpeed | optimizeQuality`).
 * Inherited. Parsed and stored, but currently with no rendering effect:
 * Android Canvas exposes no speed/quality switch for color math, so every
 * mode paints the same path.
 */
@Suppress("EnumEntryName")
internal enum class ColorRendering {
    auto,
    optimizeSpeed,
    optimizeQuality
}

// Parses a color-rendering property value; null when invalid.
internal fun parseColorRendering(value: String): ColorRendering? {
    return when {
        value.equals("auto", ignoreCase = true) -> ColorRendering.auto
        value.equals("optimizeSpeed", ignoreCase = true) -> ColorRendering.optimizeSpeed
        value.equals("optimizeQuality", ignoreCase = true) -> ColorRendering.optimizeQuality
        else -> null
    }
}
