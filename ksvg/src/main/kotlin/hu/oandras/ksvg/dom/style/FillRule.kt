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
 * SVG `fill-rule` / `clip-rule`.
 *
 * Constant values intentionally match the ordinals of [android.graphics.Path.FillType],
 * so stored values can be mapped to path fill types without translation.
 * [UNSPECIFIED] (-1) means "not specified".
 */
@Retention(AnnotationRetention.SOURCE)
@IntDef(
    FillRule.NON_ZERO,
    FillRule.EVEN_ODD,
    FillRule.UNSPECIFIED,
)
public annotation class FillRule {
    public companion object {
        public const val UNSPECIFIED: Int = -1

        public const val NON_ZERO: Int = 0
        public const val EVEN_ODD: Int = 1
    }
}

// Parse fill rule
@FillRule
internal fun parseFillRule(value: String?): Int {
    return when {
        value.equals("nonzero", ignoreCase = true) -> FillRule.NON_ZERO
        value.equals("evenodd", ignoreCase = true) -> FillRule.EVEN_ODD
        else -> FillRule.UNSPECIFIED
    }
}
