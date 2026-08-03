@file:Suppress("EnumEntryName", "SpellCheckingInspection")

package hu.oandras.androidsvg.parser

// Element types that we don't support. Those that are containers have their
// contents ignored.
//private static final String  TAG_ANIMATECOLOR        = "animateColor";
//private static final String  TAG_ANIMATEMOTION       = "animateMotion";
//private static final String  TAG_ANIMATETRANSFORM    = "animateTransform";
//private static final String  TAG_ALTGLYPH            = "altGlyph";
//private static final String  TAG_ALTGLYPHDEF         = "altGlyphDef";
//private static final String  TAG_ALTGLYPHITEM        = "altGlyphItem";
//private static final String  TAG_ANIMATE             = "animate";
//private static final String  TAG_COLORPROFILE        = "color-profile";
//private static final String  TAG_CURSOR              = "cursor";
//private static final String  TAG_FEBLEND             = "feBlend";
//private static final String  TAG_FECOLORMATRIX       = "feColorMatrix";
//private static final String  TAG_FECOMPONENTTRANSFER = "feComponentTransfer";
//private static final String  TAG_FECOMPOSITE         = "feComposite";
//private static final String  TAG_FECONVOLVEMATRIX    = "feConvolveMatrix";
//private static final String  TAG_FEDIFFUSELIGHTING   = "feDiffuseLighting";
//private static final String  TAG_FEDISPLACEMENTMAP   = "feDisplacementMap";
//private static final String  TAG_FEDISTANTLIGHT      = "feDistantLight";
//private static final String  TAG_FEFLOOD             = "feFlood";
//private static final String  TAG_FEFUNCA             = "feFuncA";
//private static final String  TAG_FEFUNCB             = "feFuncB";
//private static final String  TAG_FEFUNCG             = "feFuncG";
//private static final String  TAG_FEFUNCR             = "feFuncR";
//private static final String  TAG_FEGAUSSIANBLUR      = "feGaussianBlur";
//private static final String  TAG_FEIMAGE             = "feImage";
//private static final String  TAG_FEMERGE             = "feMerge";
//private static final String  TAG_FEMERGENODE         = "feMergeNode";
//private static final String  TAG_FEMORPHOLOGY        = "feMorphology";
//private static final String  TAG_FEOFFSET            = "feOffset";
//private static final String  TAG_FEPOINTLIGHT        = "fePointLight";
//private static final String  TAG_FESPECULARLIGHTING  = "feSpecularLighting";
//private static final String  TAG_FESPOTLIGHT         = "feSpotLight";
//private static final String  TAG_FETILE              = "feTile";
//private static final String  TAG_FETURBULENCE        = "feTurbulence";
//private static final String  TAG_FILTER              = "filter";
//private static final String  TAG_FONT                = "font";
//private static final String  TAG_FONTFACE            = "font-face";
//private static final String  TAG_FONTFACEFORMAT      = "font-face-format";
//private static final String  TAG_FONTFACENAME        = "font-face-name";
//private static final String  TAG_FONTFACESRC         = "font-face-src";
//private static final String  TAG_FONTFACEURI         = "font-face-uri";
//private static final String  TAG_FOREIGNOBJECT       = "foreignObject";
//private static final String  TAG_GLYPH               = "glyph";
//private static final String  TAG_GLYPHREF            = "glyphRef";
//private static final String  TAG_HKERN               = "hkern";
//private static final String  TAG_MASK                = "mask";
//private static final String  TAG_METADATA            = "metadata";
//private static final String  TAG_MISSINGGLYPH        = "missing-glyph";
//private static final String  TAG_MPATH               = "mpath";
//private static final String  TAG_SCRIPT              = "script";
//private static final String  TAG_SET                 = "set";
//private static final String  TAG_STYLE               = "style";
//private static final String  TAG_VKERN               = "vkern";

// Define SVG tags
internal enum class SVGElem {
    svg,
    a,
    circle,
    clipPath,
    defs,
    desc,
    ellipse,
    g,
    image,
    line,
    linearGradient,
    marker,
    mask,
    path,
    pattern,
    polygon,
    polyline,
    radialGradient,
    rect,
    solidColor,
    stop,
    style,
    switch,
    symbol,
    text,
    textPath,
    title,
    tref,
    tspan,
    use,
    view,
    UNSUPPORTED;

    companion object {
        fun fromString(str: String?): SVGElem = when (str) {
            "svg" -> svg
            "a" -> a
            "circle" -> circle
            "clipPath" -> clipPath
            "defs" -> defs
            "desc" -> desc
            "ellipse" -> ellipse
            "g" -> g
            "image" -> image
            "line" -> line
            "linearGradient" -> linearGradient
            "marker" -> marker
            "mask" -> mask
            "path" -> path
            "pattern" -> pattern
            "polygon" -> polygon
            "polyline" -> polyline
            "radialGradient" -> radialGradient
            "rect" -> rect
            "solidColor" -> solidColor
            "stop" -> stop
            "style" -> style
            "switch" -> switch
            "symbol" -> symbol
            "text" -> text
            "textPath" -> textPath
            "title" -> title
            "tref" -> tref
            "tspan" -> tspan
            "use" -> use
            "view" -> view
            else -> UNSUPPORTED
        }
    }
}