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

internal enum class TextTransform {
    None,
    Capitalize,
    Uppercase,
    Lowercase
}

// Parse a text transform keyword
internal fun parseTextTransform(value: String): TextTransform? {
    return when {
        value.equals("none", ignoreCase = true) -> TextTransform.None
        value.equals("capitalize", ignoreCase = true) -> TextTransform.Capitalize
        value.equals("uppercase", ignoreCase = true) -> TextTransform.Uppercase
        value.equals("lowercase", ignoreCase = true) -> TextTransform.Lowercase
        else -> null
    }
}
