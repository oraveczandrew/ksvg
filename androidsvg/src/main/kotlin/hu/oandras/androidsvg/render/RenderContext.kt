package hu.oandras.androidsvg.render

import hu.oandras.androidsvg.dom.Box

internal interface RenderContext {
    val dPI: Float
    val currentFontSize: Float
    val currentFontXHeight: Float
    val effectiveViewPortInUserUnits: Box
}