package hu.oandras.androidsvg.dom

import androidx.annotation.ColorInt

internal sealed class SvgColor : SvgPaint()

// Special version of Color that indicates use of 'currentColor' keyword
internal object CurrentColor : SvgColor()

internal class ColorValue internal constructor(
    @ColorInt
    @JvmField
    val value: Int
) : SvgColor() {

    override fun toString(): String {
        return String.format("#%08x", value)
    }

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false

        other as ColorValue

        return value == other.value
    }

    override fun hashCode(): Int {
        return value
    }

    companion object {
        @JvmField
        val BLACK: ColorValue = ColorValue(COLOR_BLACK) // Black singleton - a common default value.
        @JvmField
        val TRANSPARENT: ColorValue = ColorValue(0) // Transparent black
    }
}