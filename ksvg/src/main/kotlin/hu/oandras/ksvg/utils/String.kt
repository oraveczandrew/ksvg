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

import java.util.regex.Pattern

internal fun String.removeTabsAndLineBreaks(): String {
    if (!contains('\n') && !contains('\t')) return this

    return buildString(length) {
        for (c in this) {
            if (c != '\n' && c != '\t') {
                append(c)
            }
        }
    }
}

private val PATTERN_DOUBLE_SPACES: Pattern = compilePattern("\\s{2,}")
internal fun String.removeDoubleSpaces(): String {
    return PATTERN_DOUBLE_SPACES.matcher(this).replaceAll(" ")
}