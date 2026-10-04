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

package hu.oandras.ksvg.dom.text

import hu.oandras.ksvg.dom.style.NONE
import hu.oandras.ksvg.parser.TextScanner
import hu.oandras.ksvg.utils.equalsWindow
import kotlin.jvm.JvmSynthetic

internal class TextDecoration(@JvmField val mask: Int) {
    fun hasUnderline(): Boolean = (mask and UNDERLINE) != 0
    fun hasOverline(): Boolean = (mask and OVERLINE) != 0
    fun hasLineThrough(): Boolean = (mask and LINE_THROUGH) != 0

    companion object {
        const val NONE = 0
        const val UNDERLINE = 1
        const val OVERLINE = 2
        const val LINE_THROUGH = 4
        const val BLINK = 8

        @JvmSynthetic
        @JvmField
        internal val None: TextDecoration = TextDecoration(NONE)
        @JvmSynthetic
        @JvmField
        internal val Underline: TextDecoration = TextDecoration(UNDERLINE)
        @JvmSynthetic
        @JvmField
        internal val Overline: TextDecoration = TextDecoration(OVERLINE)
        @JvmSynthetic
        @JvmField
        internal val LineThrough: TextDecoration = TextDecoration(LINE_THROUGH)
        @JvmSynthetic
        @JvmField
        internal val Blink: TextDecoration = TextDecoration(BLINK)
    }

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is TextDecoration) return false
        return mask == other.mask
    }

    override fun hashCode(): Int = mask

    override fun toString(): String = "TextDecoration($mask)"
}

// Parse a text decoration keyword list
internal fun parseTextDecoration(value: String): TextDecoration? {
    if (value.equals(NONE, ignoreCase = true)) return TextDecoration.None
    var mask = 0
    val scanner = TextScanner(value)
    while (!scanner.empty()) {
        scanner.skipWhitespace()
        // Single scan per token; the 4-way keyword match runs on the window,
        // so neither the token substring nor per-keyword copies are allocated.
        val flags = scanner.consumeNextToken(' ', false) { text, s, e ->
            when {
                text.equalsWindow(s, e, "underline", ignoreCase = true) -> TextDecoration.UNDERLINE
                text.equalsWindow(s, e, "overline", ignoreCase = true) -> TextDecoration.OVERLINE
                text.equalsWindow(s, e, "line-through", ignoreCase = true) -> TextDecoration.LINE_THROUGH
                text.equalsWindow(s, e, "blink", ignoreCase = true) -> TextDecoration.BLINK
                else -> 0
            }
        } ?: break
        mask = mask or flags
        scanner.skipWhitespace()
    }
    return if (mask != 0) TextDecoration(mask) else null
}
