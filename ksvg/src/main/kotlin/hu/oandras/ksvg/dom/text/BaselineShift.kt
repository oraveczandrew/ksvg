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

package hu.oandras.ksvg.dom.text

import hu.oandras.ksvg.parser.parseLength

import hu.oandras.ksvg.css.CSSLength

internal class BaselineShift(
    @JvmField
    val value: CSSLength?,
    @JvmField
    val type: Type
) {
    enum class Type {
        Baseline,
        Sub,
        Super,
        Length
    }
}

// Parse a baseline shift
internal fun parseBaselineShift(value: String): BaselineShift? {
    return when {
        value.equals("baseline", ignoreCase = true) -> BaselineShift(null, BaselineShift.Type.Baseline)
        value.equals("sub", ignoreCase = true) -> BaselineShift(null, BaselineShift.Type.Sub)
        value.equals("super", ignoreCase = true) -> BaselineShift(null, BaselineShift.Type.Super)
        else -> {
            val length = parseLength(value)
            BaselineShift(length, BaselineShift.Type.Length)
        }
    }
}
