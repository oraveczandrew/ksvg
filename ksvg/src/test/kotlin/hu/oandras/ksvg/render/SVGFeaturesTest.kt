/*
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

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class SVGFeaturesTest {

    @Test
    fun testSvgFeatureGroupSupported() {
        val groups = listOf("SVG", "SVGDOM", "SVG-static", "SVGDOM-static",
            "SVG-animation", "SVGDOM-animation", "SVG-dynamic", "SVGDOM-dynamic")
        assertTrue(isSupportedFeatures(groups))
    }

    @Test
    fun testIndividualSupportedFeatures() {
        val features = listOf(
            "Structure", "BasicStructure", "ContainerAttribute", "ConditionalProcessing",
            "Image", "Style", "ViewportAttribute", "Shape", "BasicText",
            "PaintAttribute", "BasicPaintAttribute", "OpacityAttribute",
            "GraphicsAttribute", "BasicGraphicsAttribute", "Marker",
            "Gradient", "Pattern", "Clip", "BasicClip", "Mask",
            "Filter", "BasicFilter", "Hyperlinking", "XlinkAttribute", "View",
            "Animation", "Text"
        )
        for (feature in features) {
            assertTrue("Expected $feature to be supported", isSupportedFeature(feature))
        }
    }

    @Test
    fun testUnsupportedFeatures() {
        val unsupported = listOf(
            "CoreAttribute", "ColorProfile", "DocumentEventsAttribute",
            "GraphicalEventsAttribute", "AnimationEventsAttribute", "Cursor",
            "ExternalResourcesRequired", "Script", "Font", "BasicFont",
            "Extensibility"
        )
        for (feature in unsupported) {
            assertFalse("Expected $feature to be unsupported", isSupportedFeature(feature))
        }
    }

    @Test
    fun testUnknownFeatureUnsupported() {
        assertFalse(isSupportedFeature("completelyUnknown"))
        assertFalse(isSupportedFeature(""))
    }

    @Test
    fun testEmptyCollectionIsSupported() {
        assertTrue(isSupportedFeatures(emptyList()))
    }

    @Test
    fun testMixedSupportedAndUnsupported() {
        val mixed = listOf("Shape", "Font", "Text")
        assertFalse(isSupportedFeatures(mixed))
    }
}
