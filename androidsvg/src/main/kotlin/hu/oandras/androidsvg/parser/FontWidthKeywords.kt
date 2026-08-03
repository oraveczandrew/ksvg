package hu.oandras.androidsvg.parser

import androidx.collection.ArrayMap
import hu.oandras.androidsvg.dom.Style

internal object FontWidthKeywords {
    private val fontWidthKeywords: Map<String, Float> = ArrayMap<String, Float>(9).apply {
        this["ultra-condensed"] = 50f
        this["extra-condensed"] = 62.5f
        this["condensed"] = 75f
        this["semi-condensed"] = 87.5f
        this["normal"] = Style.FONT_WIDTH_NORMAL
        this["semi-expanded"] = 112.5f
        this["expanded"] = 125f
        this["extra-expanded"] = 150f
        this["ultra-expanded"] = 200f
    }

    fun get(fontWidth: String?): Float? {
        return fontWidthKeywords[fontWidth]
    }
}