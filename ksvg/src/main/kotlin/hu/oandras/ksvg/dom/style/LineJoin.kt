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

package hu.oandras.ksvg.dom.style

import androidx.annotation.IntDef

/**
 * SVG `stroke-linejoin`.
 *
 * Constant values intentionally match the ordinals of [android.graphics.Paint.Join],
 * so stored values can be applied to paints without translation.
 * [UNSPECIFIED] (-1) means "not specified".
 */
@Retention(AnnotationRetention.SOURCE)
@IntDef(
    LineJoin.MITER,
    LineJoin.ROUND,
    LineJoin.BEVEL,
    LineJoin.UNSPECIFIED,
)
public annotation class LineJoin {
    public companion object {
        public const val UNSPECIFIED: Int = -1

        public const val MITER: Int = 0
        public const val ROUND: Int = 1
        public const val BEVEL: Int = 2
    }
}
