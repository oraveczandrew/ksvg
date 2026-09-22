/*
 *    Copyright 2013-2020 Paul LeBeau, Cave Rock Software Ltd.
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

@file:Suppress("EnumEntryName", "SpellCheckingInspection")

package hu.oandras.ksvg.dom.core

// Supported SVG attributes
internal enum class SVGAttr {
    attributeName,
    additive,
    alignment_baseline,
    accumulate,
    begin,
    baseline_shift,
    calcMode,
    dur,
    id,
    space,
    `class`,
    clip,
    clip_path,
    clipPathUnits,
    clip_rule,
    color,
    color_interpolation_filters,
    cx, cy,
    direction,
    dominant_baseline,
    dx, dy,
    end,
    fx, fy, fr,
    d,
    display,
    fill,
    fill_rule,
    fill_opacity,
    filter,
    filterUnits,
    flood_color,
    flood_opacity,
    font,
    font_family,
    font_feature_settings,
    font_size,
    font_stretch,
    font_width,
    font_style,
    font_weight,
    from,

    // font_size_adjust
    font_kerning,
    font_variant,
    font_variant_ligatures,
    font_variant_position,
    font_variant_caps,
    font_variant_numeric,
    font_variant_east_asian,
    font_variation_settings,
    glyph_orientation_vertical,
    gradientTransform,
    gradientUnits,
    height,
    href,
    `in`,
    in2,
    intercept,

    // id,
    image_rendering,
    isolation,
    k1, k2, k3, k4,
    letter_spacing,
    marker,
    marker_start, marker_mid, marker_end,
    markerHeight, markerUnits, markerWidth,
    mask, mask_type, maskContentUnits, maskUnits,
    media,
    mix_blend_mode,
    mode,
    keyPoints,
    offset,
    opacity,
    operator,
    orient,
    rotate,
    overflow,
    paint_order,
    path,
    pathLength,
    patternContentUnits, patternTransform, patternUnits,
    points,
    preserveAspectRatio,
    primitiveUnits,
    baseFrequency,
    azimuth,
    elevation,
    diffuseConstant,
    specularConstant,
    specularExponent,
    surfaceScale,
    lighting_color,
    pointsAtX,
    pointsAtY,
    pointsAtZ,
    limitingConeAngle,
    numOctaves,
    order,
    kernelMatrix,
    kernelUnitLength,
    divisor,
    bias,
    targetX,
    targetY,
    edgeMode,
    preserveAlpha,
    scale,
    seed,
    stitchTiles,
    xChannelSelector,
    yChannelSelector,
    r,
    radius,
    repeatDur,
    refX,
    refY,
    requiredFeatures, requiredExtensions, requiredFormats, requiredFonts,
    result,
    rx, ry,
    slope,
    solid_color, solid_opacity,
    spreadMethod,
    startOffset,
    stdDeviation,
    stop_color, stop_opacity,
    stroke,
    stroke_dasharray,
    stroke_dashoffset,
    stroke_linecap,
    stroke_linejoin,
    stroke_miterlimit,
    stroke_opacity,
    stroke_width,
    style,
    systemLanguage,
    text_anchor,
    text_decoration,
    text_orientation,
    text_transform,
    to,
    transform,
    type,
    values,
    keySplines,
    keyTimes,
    repeatCount,
    tableValues,
    amplitude,
    by,
    exponent,
    vector_effect,
    version,
    viewBox,
    width,
    word_spacing,
    writing_mode,
    x, y,
    x1, y1,
    x2, y2,
    z,
    viewport_fill, viewport_fill_opacity,
    visibility,
    UNSUPPORTED;

    companion object {
        @JvmStatic
        fun fromString(str: String?): SVGAttr = when (str) {
            "id",
            "xml:id" -> id
            "attributeName" -> attributeName
            "additive" -> additive
            "alignment-baseline" -> alignment_baseline
            "accumulate" -> accumulate
            "begin" -> begin
            "baseline-shift" -> baseline_shift
            "calcMode" -> calcMode
            "space",
            "xml:space" -> space
            "class" -> `class`
            "clip" -> clip
            "clip-path" -> clip_path
            "clipPathUnits" -> clipPathUnits
            "clip-rule" -> clip_rule
            "color" -> color
            "color-interpolation-filters" -> color_interpolation_filters
            "cx" -> cx
            "cy" -> cy
            "direction" -> direction
            "dominant-baseline" -> dominant_baseline
            "dx" -> dx
            "dy" -> dy
            "end" -> end
            "fx" -> fx
            "fy" -> fy
            "fr" -> fr
            "d" -> d
            "display" -> display
            "fill" -> fill
            "fill-rule" -> fill_rule
            "fill-opacity" -> fill_opacity
            "filter" -> filter
            "filterUnits" -> filterUnits
            "flood-color" -> flood_color
            "flood-opacity" -> flood_opacity
            "font" -> font
            "font-family" -> font_family
            "font-feature-settings" -> font_feature_settings
            "font-size" -> font_size
            "font-stretch" -> font_stretch
            "font-width" -> font_width
            "font-style" -> font_style
            "font-weight" -> font_weight
            "from" -> from
            "font-kerning" -> font_kerning
            "font-variant" -> font_variant
            "font-variant-ligatures" -> font_variant_ligatures
            "font-variant-position" -> font_variant_position
            "font-variant-caps" -> font_variant_caps
            "font-variant-numeric" -> font_variant_numeric
            "font-variant-east-asian" -> font_variant_east_asian
            "font-variation-settings" -> font_variation_settings
            "glyph-orientation-vertical" -> glyph_orientation_vertical
            "gradientTransform" -> gradientTransform
            "gradientUnits" -> gradientUnits
            "height" -> height
            "href" -> href
            "in" -> `in`
            "in2" -> in2
            "intercept" -> intercept
            "image-rendering" -> image_rendering
            "isolation" -> isolation
            "k1" -> k1
            "k2" -> k2
            "k3" -> k3
            "k4" -> k4
            "letter-spacing" -> letter_spacing
            "marker" -> marker
            "marker-start" -> marker_start
            "marker-mid" -> marker_mid
            "marker-end" -> marker_end
            "markerHeight" -> markerHeight
            "markerUnits" -> markerUnits
            "markerWidth" -> markerWidth
            "mask" -> mask
            "mask-type" -> mask_type
            "maskContentUnits" -> maskContentUnits
            "maskUnits" -> maskUnits
            "media" -> media
            "keyPoints" -> keyPoints
            "mix-blend-mode" -> mix_blend_mode
            "mode" -> mode
            "offset" -> offset
            "opacity" -> opacity
            "operator" -> operator
            "orient" -> orient
            "rotate" -> rotate
            "overflow" -> overflow
            "paint-order" -> paint_order
            "path" -> path
            "pathLength" -> pathLength
            "patternContentUnits" -> patternContentUnits
            "patternTransform" -> patternTransform
            "patternUnits" -> patternUnits
            "points" -> points
            "preserveAspectRatio" -> preserveAspectRatio
            "primitiveUnits" -> primitiveUnits
            "baseFrequency" -> baseFrequency
            "azimuth" -> azimuth
            "elevation" -> elevation
            "diffuseConstant" -> diffuseConstant
            "specularConstant" -> specularConstant
            "specularExponent" -> specularExponent
            "surfaceScale" -> surfaceScale
            "lighting-color" -> lighting_color
            "pointsAtX" -> pointsAtX
            "pointsAtY" -> pointsAtY
            "pointsAtZ" -> pointsAtZ
            "limitingConeAngle" -> limitingConeAngle
            "numOctaves" -> numOctaves
            "order" -> order
            "kernelMatrix" -> kernelMatrix
            "kernelUnitLength" -> kernelUnitLength
            "divisor" -> divisor
            "bias" -> bias
            "targetX" -> targetX
            "targetY" -> targetY
            "edgeMode" -> edgeMode
            "preserveAlpha" -> preserveAlpha
            "scale" -> scale
            "seed" -> seed
            "stitchTiles" -> stitchTiles
            "xChannelSelector" -> xChannelSelector
            "yChannelSelector" -> yChannelSelector
            "r" -> r
            "radius" -> radius
            "repeatDur" -> repeatDur
            "refX" -> refX
            "refY" -> refY
            "requiredFeatures" -> requiredFeatures
            "requiredExtensions" -> requiredExtensions
            "requiredFormats" -> requiredFormats
            "requiredFonts" -> requiredFonts
            "result" -> result
            "rx" -> rx
            "ry" -> ry
            "slope" -> slope
            "solid-color" -> solid_color
            "solid-opacity" -> solid_opacity
            "spreadMethod" -> spreadMethod
            "startOffset" -> startOffset
            "stop-color" -> stop_color
            "stop-opacity" -> stop_opacity
            "stroke" -> stroke
            "stroke-dasharray" -> stroke_dasharray
            "stroke-dashoffset" -> stroke_dashoffset
            "stroke-linecap" -> stroke_linecap
            "stroke-linejoin" -> stroke_linejoin
            "stroke-miterlimit" -> stroke_miterlimit
            "stroke-opacity" -> stroke_opacity
            "stroke-width" -> stroke_width
            "style" -> style
            "systemLanguage" -> systemLanguage
            "text-anchor" -> text_anchor
            "text-decoration" -> text_decoration
            "text-orientation" -> text_orientation
            "text-transform" -> text_transform
            "to" -> to
            "transform" -> transform
            "type" -> type
            "values" -> values
            "dur" -> dur
            "keySplines" -> keySplines
            "keyTimes" -> keyTimes
            "repeatCount" -> repeatCount
            "tableValues" -> tableValues
            "amplitude" -> amplitude
            "by" -> by
            "exponent" -> exponent
            "vector-effect" -> vector_effect
            "version" -> version
            "viewBox" -> viewBox
            "width" -> width
            "word-spacing" -> word_spacing
            "writing-mode" -> writing_mode
            "x" -> x
            "y" -> y
            "x1" -> x1
            "y1" -> y1
            "x2" -> x2
            "y2" -> y2
            "z" -> z
            "viewport-fill" -> viewport_fill
            "viewport-fill-opacity" -> viewport_fill_opacity
            "visibility" -> visibility
            "stdDeviation" -> stdDeviation
            else -> UNSUPPORTED
        }
    }
}
