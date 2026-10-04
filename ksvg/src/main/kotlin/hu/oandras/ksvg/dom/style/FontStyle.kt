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

package hu.oandras.ksvg.dom.style

import hu.oandras.ksvg.utils.equalsWindow

@Suppress("EnumEntryName")
internal enum class FontStyle {
    normal,
    italic,
    oblique
}

// Parse a font style keyword
internal fun parseFontStyle(value: String): FontStyle? {
    // Italic is probably the most common, so test that first :)
    return when {
        value.equals("italic", ignoreCase = true) -> FontStyle.italic
        value.equals("normal", ignoreCase = true) -> FontStyle.normal
        value.equals("oblique", ignoreCase = true) -> FontStyle.oblique
        else -> null
    }
}

// Windowed twin: no token substring for scanner-driven callers.
internal fun parseFontStyle(text: String, start: Int, end: Int): FontStyle? {
    return when {
        text.equalsWindow(start, end, "italic", ignoreCase = true) -> FontStyle.italic
        text.equalsWindow(start, end, "normal", ignoreCase = true) -> FontStyle.normal
        text.equalsWindow(start, end, "oblique", ignoreCase = true) -> FontStyle.oblique
        else -> null
    }
}
