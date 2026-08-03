package hu.oandras.androidsvg.utils

internal fun Char.isSpaceLike(): Boolean {
    return when (this) {
        '\n',
        '\r',
        '\t',
        ' ' -> true
        else -> false
    }
}