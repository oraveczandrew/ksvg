package hu.oandras.androidsvg.utils

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