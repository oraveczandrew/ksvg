package hu.oandras.ksvg.dom.style

import hu.oandras.ksvg.css.CSSLength
import hu.oandras.ksvg.dom.core.PathDefinition

internal sealed interface CSSClipPath {
    data class UrlClip(
        @JvmField val iri: String
    ) : CSSClipPath

    data class ShapeClip(
        @JvmField val shape: BasicShape,
        @JvmField val refBox: GeometryBox
    ) : CSSClipPath

    object NoClip : CSSClipPath
}

internal enum class GeometryBox {
    FILL_BOX,
    STROKE_BOX,
    VIEW_BOX,
}

internal sealed interface BasicShape {
    data class Circle(
        @JvmField
        val r: ClipRadius,
        @JvmField
        val cx: ClipPosition,
        @JvmField
        val cy: ClipPosition
    ) : BasicShape

    data class Ellipse(
        @JvmField
        val rx: ClipRadius,
        @JvmField
        val ry: ClipRadius,
        @JvmField
        val cx: ClipPosition,
        @JvmField
        val cy: ClipPosition,
    ) : BasicShape

    data class Inset(
        @JvmField
        val top: CSSLength,
        @JvmField
        val right: CSSLength,
        @JvmField
        val bottom: CSSLength,
        @JvmField
        val left: CSSLength,
        @JvmField
        val roundX: CSSLength?,
        @JvmField
        val roundY: CSSLength?,
    ) : BasicShape

    data class Rect(
        @JvmField
        val top: CSSLength,
        @JvmField
        val right: CSSLength,
        @JvmField
        val bottom: CSSLength,
        @JvmField
        val left: CSSLength,
        @JvmField
        val roundX: CSSLength?,
        @JvmField
        val roundY: CSSLength?,
    ) : BasicShape

    data class Xywh(
        @JvmField
        val x: CSSLength,
        @JvmField
        val y: CSSLength,
        @JvmField
        val w: CSSLength,
        @JvmField
        val h: CSSLength,
        @JvmField
        val roundX: CSSLength?,
        @JvmField
        val roundY: CSSLength?,
    ) : BasicShape

    data class Polygon(
        @JvmField
        val points: List<CSSLength>,
        @JvmField
        @FillRule
        val fillRule: Int
    ) : BasicShape

    data class Path(
        @JvmField
        val path: PathDefinition,
        @JvmField
        @FillRule
        val fillRule: Int
    ) : BasicShape
}

/** Radius of a `circle()` / `ellipse()`: explicit length or a side keyword. */
internal sealed interface ClipRadius {
    data class Len(@JvmField val v: CSSLength) : ClipRadius
    object ClosestSide : ClipRadius
    object FarthestSide : ClipRadius
}

internal sealed interface ClipPosition {
    data class Len(@JvmField val v: CSSLength) : ClipPosition

    /** Keyword with an explicit offset, e.g. `right 10px` in 3-4 value positions. */
    data class Offset(
        @JvmField
        val anchor: ClipPosition,
        @JvmField
        val delta: CSSLength
    ) : ClipPosition

    object Left : ClipPosition
    object Center : ClipPosition
    object Right : ClipPosition
    object Top : ClipPosition
    object Bottom : ClipPosition
}
