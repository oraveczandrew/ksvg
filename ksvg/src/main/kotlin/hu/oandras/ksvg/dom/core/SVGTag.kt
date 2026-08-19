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

internal enum class SVGTag {
    a,
    animate,
    animateColor,
    animateMotion,
    animateTransform,
    circle,
    clipPath,
    defs,
    desc,
    ellipse,
    feBlend,
    feColorMatrix,
    feComponentTransfer,
    feComposite,
    feConvolveMatrix,
    feDropShadow,
    feDiffuseLighting,
    feDisplacementMap,
    feDistantLight,
    feFlood,
    feFuncA,
    feFuncB,
    feFuncG,
    feFuncR,
    feGaussianBlur,
    feImage,
    feMerge,
    feMergeNode,
    feMorphology,
    feOffset,
    fePointLight,
    feSpecularLighting,
    feSpotLight,
    feTile,
    feTurbulence,
    filter,
    g,
    image,
    line,
    linearGradient,
    marker,
    mask,
    mpath,
    path,
    pattern,
    polygon,
    polyline,
    radialGradient,
    rect,
    set,
    solidColor,
    stop,
    style,
    svg,
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
        fun fromString(str: String?): SVGTag = when (str) {
            "a" -> a
            "animate" -> animate
            "animateColor" -> animateColor
            "animateMotion" -> animateMotion
            "animateTransform" -> animateTransform
            "circle" -> circle
            "clipPath" -> clipPath
            "defs" -> defs
            "desc" -> desc
            "ellipse" -> ellipse
            "feBlend" -> feBlend
            "feColorMatrix" -> feColorMatrix
            "feComponentTransfer" -> feComponentTransfer
            "feComposite" -> feComposite
            "feConvolveMatrix" -> feConvolveMatrix
            "feDropShadow" -> feDropShadow
            "feDiffuseLighting" -> feDiffuseLighting
            "feDisplacementMap" -> feDisplacementMap
            "feDistantLight" -> feDistantLight
            "feFlood" -> feFlood
            "feFuncA" -> feFuncA
            "feFuncB" -> feFuncB
            "feFuncG" -> feFuncG
            "feFuncR" -> feFuncR
            "feGaussianBlur" -> feGaussianBlur
            "feImage" -> feImage
            "feMerge" -> feMerge
            "feMergeNode" -> feMergeNode
            "feMorphology" -> feMorphology
            "feOffset" -> feOffset
            "fePointLight" -> fePointLight
            "feSpecularLighting" -> feSpecularLighting
            "feSpotLight" -> feSpotLight
            "feTile" -> feTile
            "feTurbulence" -> feTurbulence
            "filter" -> filter
            "g" -> g
            "image" -> image
            "line" -> line
            "linearGradient" -> linearGradient
            "marker" -> marker
            "mask" -> mask
            "mpath" -> mpath
            "path" -> path
            "pattern" -> pattern
            "polygon" -> polygon
            "polyline" -> polyline
            "radialGradient" -> radialGradient
            "rect" -> rect
            "set" -> set
            "solidColor" -> solidColor
            "stop" -> stop
            "style" -> style
            "svg" -> svg
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
