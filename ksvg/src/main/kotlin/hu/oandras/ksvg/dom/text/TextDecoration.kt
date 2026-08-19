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

internal class TextDecoration(val mask: Int) {
    fun hasUnderline(): Boolean = (mask and UNDERLINE) != 0
    fun hasOverline(): Boolean = (mask and OVERLINE) != 0
    fun hasLineThrough(): Boolean = (mask and LINE_THROUGH) != 0

    companion object {
        const val NONE = 0
        const val UNDERLINE = 1
        const val OVERLINE = 2
        const val LINE_THROUGH = 4
        const val BLINK = 8

        val None = TextDecoration(NONE)
        val Underline = TextDecoration(UNDERLINE)
        val Overline = TextDecoration(OVERLINE)
        val LineThrough = TextDecoration(LINE_THROUGH)
        val Blink = TextDecoration(BLINK)
    }

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is TextDecoration) return false
        return mask == other.mask
    }

    override fun hashCode(): Int = mask

    override fun toString(): String = "TextDecoration($mask)"
}
