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

import androidx.collection.ArrayMap
import hu.oandras.ksvg.dom.Style

internal object FontWidthKeywords {
    private val fontWidthKeywords: Map<String, Float> = ArrayMap<String, Float>(9).apply {
        this["ultra-condensed"] = 50f
        this["extra-condensed"] = 62.5f
        this["condensed"] = 75f
        this["semi-condensed"] = 87.5f
        this["normal"] = Style.FONT_WIDTH_NORMAL
        this["semi-expanded"] = 112.5f
        this["expanded"] = 125f
        this["extra-expanded"] = 150f
        this["ultra-expanded"] = 200f
    }

    fun get(fontWidth: String?): Float? {
        return fontWidthKeywords[fontWidth]
    }
}