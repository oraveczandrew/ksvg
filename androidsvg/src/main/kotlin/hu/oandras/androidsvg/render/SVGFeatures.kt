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

package hu.oandras.androidsvg.render

/**
 * Checks if all the given SVG features are supported by the renderer.
 */
internal fun isSupportedFeatures(features: Collection<String>): Boolean {
    for (feature in features) {
        if (!isSupportedFeature(feature)) {
            return false
        }
    }
    return true
}

/**
 * Checks if the given SVG feature is supported by the renderer.
 */
internal fun isSupportedFeature(feature: String): Boolean {
    return when (feature) {
        // Feature sets that represent sets of other feature strings (ie a group of features strings)
        // "SVG",                       // NO
        // "SVGDOM",                    // NO
        // "SVG-static",                // NO
        // "SVGDOM-static",             // NO
        // "SVG-animation",             // NO
        // "SVGDOM-animation",          // NO
        // "SVG-dynamic",               // NO
        // "SVGDOM-dynamic",            // NO

        // Individual features
        // "CoreAttribute",             // NO
        "Structure", // YES (although desc title and metadata are ignored)
        "BasicStructure", // YES (although desc title and metadata are ignored)
        // "ContainerAttribute",        // NO (filter related. NYI)
        "ConditionalProcessing", // YES
        "Image", // YES (bitmaps only - not SVG files)
        "Style", // YES
        "ViewportAttribute", // YES
        "Shape", // YES
        // "Text",                      // NO
        "BasicText", // YES
        "PaintAttribute", // YES (except color-interpolation and color-rendering)
        "BasicPaintAttribute", // YES (except color-rendering)
        "OpacityAttribute", // YES
        // "GraphicsAttribute",         // NO
        "BasicGraphicsAttribute", // YES
        "Marker", // YES
        // "ColorProfile",              // NO
        "Gradient", // YES
        "Pattern", // YES
        "Clip", // YES
        "BasicClip", // YES
        "Mask", // YES
        // "Filter",                    // NO
        // "BasicFilter",               // NO
        // "DocumentEventsAttribute",   // NO
        // "GraphicalEventsAttribute",  // NO
        // "AnimationEventsAttribute",  // NO
        // "Cursor",                    // NO
        // "Hyperlinking",              // NO
        // "XlinkAttribute",            // NO
        // "ExternalResourcesRequired", // NO
        "View", // YES

        // "Script",                    // NO
        // "Animation",                 // NO
        // "Font",                      // NO
        // "BasicFont",                 // NO
        // "Extensibility",             // NO

        // SVG 1.0 features - all are too general and include things we are not likely to ever support.
        // If we ever do support these, we'll need to change how FEATURE_STRING_PREFIX is used.
        // "org.w3c.svg",
        // "org.w3c.dom.svg",
        // "org.w3c.svg.static",
        // "org.w3c.dom.svg.static",
        // "org.w3c.svg.animation",
        // "org.w3c.dom.svg.animation",
        // "org.w3c.svg.dynamic",
        // "org.w3c.dom.svg.dynamic",
        // "org.w3c.svg.all",
        // "org.w3c.dom.svg.all",
        -> true

        else -> false
    }
}
