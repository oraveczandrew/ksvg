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
//private static final String  TAG_METADATA            = "metadata";
//private static final String  TAG_MISSINGGLYPH        = "missing-glyph";
//private static final String  TAG_MPATH               = "mpath";
//private static final String  TAG_SCRIPT              = "script";
//private static final String  TAG_SET                 = "set";
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
    feBlend,
    feColorMatrix,
    feComponentTransfer,
    feFuncA,
    feFuncB,
    feFuncG,
    feFuncR,
    feConvolveMatrix,
    feComposite,
    feDiffuseLighting,
    feDisplacementMap,
    feDistantLight,
    fePointLight,
    feSpecularLighting,
    feSpotLight,
    feFlood,
    feGaussianBlur,
    feImage,
    feMerge,
    feMergeNode,
    feMorphology,
    feOffset,
    feTurbulence,
    feTile,
    filter,
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
            "feBlend" -> feBlend
            "feColorMatrix" -> feColorMatrix
            "feComponentTransfer" -> feComponentTransfer
            "feFuncA" -> feFuncA
            "feFuncB" -> feFuncB
            "feFuncG" -> feFuncG
            "feFuncR" -> feFuncR
            "feConvolveMatrix" -> feConvolveMatrix
            "feComposite" -> feComposite
            "feDiffuseLighting" -> feDiffuseLighting
            "feDisplacementMap" -> feDisplacementMap
            "feDistantLight" -> feDistantLight
            "fePointLight" -> fePointLight
            "feSpecularLighting" -> feSpecularLighting
            "feSpotLight" -> feSpotLight
            "feFlood" -> feFlood
            "feGaussianBlur" -> feGaussianBlur
            "feImage" -> feImage
            "feMerge" -> feMerge
            "feMergeNode" -> feMergeNode
            "feMorphology" -> feMorphology
            "feOffset" -> feOffset
            "feTurbulence" -> feTurbulence
            "feTile" -> feTile
            "filter" -> filter
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
