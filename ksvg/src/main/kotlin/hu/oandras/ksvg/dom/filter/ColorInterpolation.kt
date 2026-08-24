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

package hu.oandras.ksvg.dom.filter

import androidx.annotation.IntDef
import java.util.Locale

/**
 * SVG `color-interpolation` / `color-interpolation-filters`.
 *
 * [UNSPECIFIED] (-1) means "not specified"; the effective default for filters
 * is [LINEAR_RGB] per the SVG spec.
 */
@Retention(AnnotationRetention.SOURCE)
@IntDef(
    ColorInterpolation.AUTO,
    ColorInterpolation.SRGB,
    ColorInterpolation.LINEAR_RGB,
    ColorInterpolation.UNSPECIFIED,
)
public annotation class ColorInterpolation {
    public companion object {
        public const val UNSPECIFIED: Int = -1

        public const val AUTO: Int = 0
        public const val SRGB: Int = 1
        public const val LINEAR_RGB: Int = 2

        /** Parses a `color-interpolation[-filters]` value; returns [UNSPECIFIED] when invalid. */
        internal fun parse(value: String): Int {
            return when {
                value.equals("auto", ignoreCase = true) -> AUTO
                value.equals("sRGB", ignoreCase = true) -> SRGB
                value.equals("linearRGB", ignoreCase = true) -> LINEAR_RGB
                else -> UNSPECIFIED
            }
        }
    }
}
