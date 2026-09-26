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

package hu.oandras.ksvg.filtering

import androidx.annotation.IntDef

/**
 * feBlend modes for [KotlinKernels.feBlend] and [SoftwareKernels.feBlend].
 * Values mirror the `FeBlendMode` enum ordinals in `:ksvg` (this module must
 * not depend on DOM types); 0=normal must not reach the kernel.
 */
@Retention(AnnotationRetention.SOURCE)
@IntDef(
    FeBlendMode.MULTIPLY,
    FeBlendMode.SCREEN,
    FeBlendMode.OVERLAY,
    FeBlendMode.DARKEN,
    FeBlendMode.LIGHTEN,
    FeBlendMode.COLOR_DODGE,
    FeBlendMode.COLOR_BURN,
    FeBlendMode.HARD_LIGHT,
    FeBlendMode.SOFT_LIGHT,
    FeBlendMode.DIFFERENCE,
    FeBlendMode.EXCLUSION,
    FeBlendMode.HUE,
    FeBlendMode.SATURATION,
    FeBlendMode.COLOR,
    FeBlendMode.LUMINOSITY,
)
public annotation class FeBlendMode {
    public companion object {
        public const val MULTIPLY: Int = 1
        public const val SCREEN: Int = 2
        public const val OVERLAY: Int = 3
        public const val DARKEN: Int = 4
        public const val LIGHTEN: Int = 5
        public const val COLOR_DODGE: Int = 6
        public const val COLOR_BURN: Int = 7
        public const val HARD_LIGHT: Int = 8
        public const val SOFT_LIGHT: Int = 9
        public const val DIFFERENCE: Int = 10
        public const val EXCLUSION: Int = 11
        public const val HUE: Int = 12
        public const val SATURATION: Int = 13
        public const val COLOR: Int = 14
        public const val LUMINOSITY: Int = 15
    }
}
