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

package hu.oandras.ksvg.parser

import hu.oandras.ksvg.dom.style.Style
import hu.oandras.ksvg.utils.equalsWindow

internal object FontWeightKeywords {
    fun get(fontWeight: String?): Float {
        if (fontWeight == null) return Float.NaN
        return get(fontWeight, 0, fontWeight.length)
    }

    fun get(text: String, start: Int, end: Int): Float {
        return when {
            text.equalsWindow(start, end, "normal", ignoreCase = true) -> Style.FONT_WEIGHT_NORMAL
            text.equalsWindow(start, end, "bold", ignoreCase = true) -> Style.FONT_WEIGHT_BOLD
            text.equalsWindow(start, end, "bolder", ignoreCase = true) -> Style.FONT_WEIGHT_BOLDER
            text.equalsWindow(start, end, "lighter", ignoreCase = true) -> Style.FONT_WEIGHT_LIGHTER
            else -> Float.NaN
        }
    }
}
