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

@file:Suppress("EnumEntryName")

package hu.oandras.ksvg.dom.style

internal enum class CSSBlendMode {
    normal,
    multiply,
    screen,
    overlay,
    darken,
    lighten,
    color_dodge,
    color_burn,
    hard_light,
    soft_light,
    difference,
    exclusion,
    hue,
    saturation,
    color,
    luminosity,
    UNSUPPORTED;

    companion object {
        fun fromString(str: String?): CSSBlendMode = when {
            str.equals("normal", ignoreCase = true) -> normal
            str.equals("multiply", ignoreCase = true) -> multiply
            str.equals("screen", ignoreCase = true) -> screen
            str.equals("overlay", ignoreCase = true) -> overlay
            str.equals("darken", ignoreCase = true) -> darken
            str.equals("lighten", ignoreCase = true) -> lighten
            str.equals("color-dodge", ignoreCase = true) -> color_dodge
            str.equals("color-burn", ignoreCase = true) -> color_burn
            str.equals("hard-light", ignoreCase = true) -> hard_light
            str.equals("soft-light", ignoreCase = true) -> soft_light
            str.equals("difference", ignoreCase = true) -> difference
            str.equals("exclusion", ignoreCase = true) -> exclusion
            str.equals("hue", ignoreCase = true) -> hue
            str.equals("saturation", ignoreCase = true) -> saturation
            str.equals("color", ignoreCase = true) -> color
            str.equals("luminosity", ignoreCase = true) -> luminosity
            else -> UNSUPPORTED
        }
    }
}