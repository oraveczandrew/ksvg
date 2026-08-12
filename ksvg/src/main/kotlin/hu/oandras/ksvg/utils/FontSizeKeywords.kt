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

package hu.oandras.ksvg.utils

import hu.oandras.ksvg.css.CSSLength
import hu.oandras.ksvg.css.CssUnit

internal object FontSizeKeywords {
    private val XX_SMALL = CSSLength(0.694f, CssUnit.pt)
    private val X_SMALL = CSSLength(0.833f, CssUnit.pt)
    private val SMALL = CSSLength(10.0f, CssUnit.pt)
    private val MEDIUM = CSSLength(12.0f, CssUnit.pt)
    private val LARGE = CSSLength(14.4f, CssUnit.pt)
    private val X_LARGE = CSSLength(17.3f, CssUnit.pt)
    private val XX_LARGE = CSSLength(20.7f, CssUnit.pt)
    private val SMALLER = CSSLength(83.33f, CssUnit.percent)
    private val LARGER = CSSLength(120f, CssUnit.percent)

    fun get(fontSize: String?): CSSLength? = when (fontSize) {
        "xx-small" -> XX_SMALL
        "x-small" -> X_SMALL
        "small" -> SMALL
        "medium" -> MEDIUM
        "large" -> LARGE
        "x-large" -> X_LARGE
        "xx-large" -> XX_LARGE
        "smaller" -> SMALLER
        "larger" -> LARGER
        else -> null
    }
}
