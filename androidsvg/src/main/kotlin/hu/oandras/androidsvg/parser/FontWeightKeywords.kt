package hu.oandras.androidsvg.parser

import androidx.collection.ArrayMap
import hu.oandras.androidsvg.dom.Style

internal object FontWeightKeywords {
    private val fontWeightKeywords: Map<String, Float> = ArrayMap<String, Float>(4).apply {
        this["normal"] = Style.FONT_WEIGHT_NORMAL
        this["bold"] = Style.FONT_WEIGHT_BOLD
        this["bolder"] = Style.FONT_WEIGHT_BOLDER
        this["lighter"] = Style.FONT_WEIGHT_LIGHTER
    }

    fun get(fontWeight: String?): Float? {
        return fontWeightKeywords[fontWeight]
    }
}