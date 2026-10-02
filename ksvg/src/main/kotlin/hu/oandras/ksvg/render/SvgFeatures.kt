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

package hu.oandras.ksvg.render

/**
 * Checks if all the given SVG features are supported by the renderer.
 */
// Note: Collection (not List) because the DOM stores required* as Set<String>;
// this runs at tree-build time only, so the iterator allocation is acceptable.
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
        "SVG",
        "SVGDOM",
        "SVG-static",
        "SVGDOM-static",
        "SVG-animation",
        "SVGDOM-animation",
        "SVG-dynamic",
        "SVGDOM-dynamic",

        // Individual features
        // "CoreAttribute",             // NO
        "Structure", // YES (although desc title and metadata are ignored)
        "BasicStructure", // YES (although desc title and metadata are ignored)
        "ContainerAttribute", // YES
        "ConditionalProcessing", // YES
        "Image", // YES (bitmaps only - not SVG files)
        "Style", // YES
        "ViewportAttribute", // YES
        "Shape", // YES
        "BasicText", // YES
        "PaintAttribute", // YES (except color-rendering; color-interpolation honored for gradients)
        "BasicPaintAttribute", // YES (except color-rendering)
        "OpacityAttribute", // YES
        "GraphicsAttribute", // YES
        "BasicGraphicsAttribute", // YES
        "Marker", // YES
        // "ColorProfile",              // NO
        "Gradient", // YES
        "Pattern", // YES
        "Clip", // YES
        "BasicClip", // YES
        "Mask", // YES
        "Filter", // YES
        "BasicFilter", // YES
        // "DocumentEventsAttribute",   // NO
        // "GraphicalEventsAttribute",  // NO
        // "AnimationEventsAttribute",  // NO
        // "Cursor",                    // NO
        "Hyperlinking", // YES
        "XlinkAttribute", // YES
        // "ExternalResourcesRequired", // NO
        "View", // YES

        // "Script",                    // NO
        "Animation", // YES
        "Text", // YES
        // "Font",                      // NO
        // "BasicFont",                 // NO
        // "Extensibility",             // NO

        // SVG Tiny 1.2 URIs (Appendix J). Each URI gets its own verdict:
        // same local names mean different things across profiles (e.g., 1.1
        // "Animation" is SMIL, Tiny "#Animation" is the <animation> media
        // element), so these must NOT be derived by stripping the namespace
        // and reusing the 1.1 table above. Only the normative
        // "http://www.w3.org/Graphics/SVG/feature/1.2/..." spelling matches;
        // composites stay false unless every member is supported.
        "http://www.w3.org/Graphics/SVG/feature/1.2/#Structure",
        "http://www.w3.org/Graphics/SVG/feature/1.2/#ConditionalProcessing",
        "http://www.w3.org/Graphics/SVG/feature/1.2/#ConditionalProcessingAttribute",
        "http://www.w3.org/Graphics/SVG/feature/1.2/#Image",
        "http://www.w3.org/Graphics/SVG/feature/1.2/#Shape",
        "http://www.w3.org/Graphics/SVG/feature/1.2/#Text",
        "http://www.w3.org/Graphics/SVG/feature/1.2/#PaintAttribute",
        "http://www.w3.org/Graphics/SVG/feature/1.2/#OpacityAttribute",
        "http://www.w3.org/Graphics/SVG/feature/1.2/#GraphicsAttribute",
        "http://www.w3.org/Graphics/SVG/feature/1.2/#Gradient",
        "http://www.w3.org/Graphics/SVG/feature/1.2/#SolidColor",
        "http://www.w3.org/Graphics/SVG/feature/1.2/#Hyperlinking",
        "http://www.w3.org/Graphics/SVG/feature/1.2/#XlinkAttribute",
        "http://www.w3.org/Graphics/SVG/feature/1.2/#CoreAttribute",
        "http://www.w3.org/Graphics/SVG/feature/1.2/#TimedAnimation",

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
