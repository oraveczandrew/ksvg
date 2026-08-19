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

package hu.oandras.ksvg.utils

import java.util.Locale
import java.util.regex.Pattern

internal fun String.charCount(c: Char): Int {
    var count = 0
    for (i in indices) {
        if (this[i] == c) count++
    }
    return count
}

internal fun String.removeTabsAndLineBreaks(): String {
    if (!contains('\n') && !contains('\t')) return this

    return buildString(length) {
        for (c in this@removeTabsAndLineBreaks) {
            if (c != '\n' && c != '\t') {
                append(c)
            }
        }
    }
}

private val PATTERN_DOUBLE_SPACES: Pattern = "\\s{2,}".toPattern()
internal fun String.removeDoubleSpaces(): String {
    return PATTERN_DOUBLE_SPACES.matcher(this).replaceAll(" ")
}

internal fun textXMLSpaceTransform(
    text: String,
    isFirstChild: Boolean,
    isLastChild: Boolean,
    spacePreserve: Boolean,
): String {
    if (spacePreserve) {
        // xml:space = "preserve"
        return text.removeTabsAndLineBreaks()
    }

    // xml:space = "default"
    val result = text.removeTabsAndLineBreaks()
        .let { if (isFirstChild) it.trimStart { c -> c.isSpaceLike() } else it }
        .let { if (isLastChild) it.trimEnd { c -> c.isSpaceLike() } else it }

    return result.removeDoubleSpaces()
}

internal fun String.trimLowerThanSpace(): String {
    return trim {
        it <= ' '
    }
}

@Suppress("UNNECESSARY_NOT_NULL_ASSERTION")
internal fun String.toPattern(): Pattern {
    return Pattern.compile(this)!!
}

internal fun String.capitalizeStr(locale: Locale): String {
    return split(" ").joinToString(" ") { it.replaceFirstChar { char -> if (char.isLowerCase()) char.titlecase(locale) else char.toString() } }
}
