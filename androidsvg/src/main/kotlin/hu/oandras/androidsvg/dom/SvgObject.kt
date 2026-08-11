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

package hu.oandras.androidsvg.dom

// SVGBase and Style are in the same package
import android.graphics.Matrix
import hu.oandras.androidsvg.PreserveAspectRatio
import hu.oandras.androidsvg.SVGParseException
import hu.oandras.androidsvg.css.CSSLength
import hu.oandras.androidsvg.parser.checkState
import hu.oandras.androidsvg.utils.GradientSpread

//===============================================================================
// The objects in the SVG object tree
//===============================================================================
// Any object that can be part of the tree
internal interface SvgObject {
    val document: SVGImpl
    val parent: SvgContainer?
    var id: String?

    fun getNodeName(): String

    //===============================================================================
    // The objects in the SVG object tree
    //===============================================================================
    // Any object that can be part of the tree
    open class SvgObjectImpl: SvgObject {
        override var id: String? = null
        override lateinit var document: SVGImpl
        override var parent: SvgContainer? = null
        override fun getNodeName(): String = ""
    }

    // Any object in the tree that corresponds to an SVG element
    abstract class SvgElementBase : SvgObjectImpl() {
        @JvmField
        var spacePreserve: Boolean? = null

        @JvmField
        var baseStyle: Style? = null // style defined by explicit style attributes in the element (e.g. fill="black")

        @JvmField
        var style: Style? = null // style expressed in a 'style' attribute (e.g. style="fill:black")
        var classNames: List<String>? = null // contents of the 'class' attribute

        override fun toString(): String {
            return getNodeName()
        }
    }

    abstract class SvgPreserveAspectRatioContainer : SvgConditionalContainer() {
        @JvmField
        var preserveAspectRatio: PreserveAspectRatio? = null
    }

    abstract class SvgViewBoxContainer : SvgPreserveAspectRatioContainer() {
        @JvmField
        var viewBox: Box? = null
    }

    class Svg : SvgViewBoxContainer() {
        @JvmField
        var x: CSSLength? = null
        @JvmField
        var y: CSSLength? = null
        @JvmField
        var width: CSSLength? = null
        @JvmField
        var height: CSSLength? = null
        @JvmField
        var version: String? = null

        override fun getNodeName(): String {
            return "svg"
        }
    }

    abstract class SvgTransformingConditionalContainer : SvgConditionalContainer(), HasTransform {
        @JvmField
        var transform: Matrix? = null

        override fun setTransform(transform: Matrix?) {
            this.transform = transform
        }

        override fun getTransform(): Matrix? {
            return transform
        }
    }

    // An SVG element that can contain other elements.
    open class Group : SvgTransformingConditionalContainer() {

        override fun getNodeName(): String {
            return "group"
        }
    }


    // Any object in the tree that corresponds to an SVG element
    abstract class SvgElement : SvgElementBase() {
        @JvmField
        var boundingBox: Box? = null
    }

    interface SvgDomParent {
        fun getChildren(): List<SvgObject>

        @Throws(SVGParseException::class)
        fun addChild(elem: SvgObject)

        fun addAll(list: List<SvgObject>)

        fun childCount(): Int
    }

    interface SvgContainer: SvgObject, SvgDomParent

    private class SvgChildrenStore: SvgDomParent {
        private var children: ArrayList<SvgObject>? = null

        override fun childCount(): Int = children?.size ?: 0

        private fun ensureChildList(): ArrayList<SvgObject> {
            return children ?: ArrayList<SvgObject>().also {
                children = it
            }
        }

        override fun getChildren(): List<SvgObject> {
            return children ?: emptyList()
        }

        override fun addAll(list: List<SvgObject>) {
            ensureChildList().addAll(list)
        }

        @Throws(SVGParseException::class)
        override fun addChild(elem: SvgObject) {
            ensureChildList().add(elem)
        }
    }

    abstract class SvgContainerImpl : SvgElementBase(), SvgContainer, SvgDomParent by SvgChildrenStore()

    // Any element that can appear inside a <switch> element.
    interface SvgConditional {
        var requiredFeatures: Set<String>?
        var requiredExtensions: String?
        var systemLanguage: Set<String>?
        var requiredFormats: Set<String>?
        var requiredFonts: Set<String>?
    }

    // Any element that can appear inside a <switch> element.
    abstract class SvgConditionalElement : SvgElement(), SvgConditional {
        override var requiredFeatures: Set<String>? = null
        override var requiredExtensions: String? = null
        override var systemLanguage: Set<String>? = null
        override var requiredFormats: Set<String>? = null
        override var requiredFonts: Set<String>? = null
    }

    abstract class SvgConditionalContainer : SvgElement(), SvgContainer, SvgConditional, SvgDomParent by SvgChildrenStore() {
        override var requiredFeatures: Set<String>? = null
        override var requiredExtensions: String? = null
        override var systemLanguage: Set<String>? = null
        override var requiredFormats: Set<String>? = null
        override var requiredFonts: Set<String>? = null
    }

    // A <defs> object contains objects that are not rendered directly, but are instead
    // referenced from other parts of the file.
    class Defs : Group(), NotDirectlyRendered {
        override fun getNodeName(): String {
            return "defs"
        }
    }

    sealed class SvgTransformingConditionalElement : SvgConditionalElement(), HasTransform {
        @JvmField
        var transform: Matrix? = null

        override fun setTransform(transform: Matrix?) {
            this.transform = transform
        }

        override fun getTransform(): Matrix? {
            return transform
        }
    }

    // One of the element types that can cause graphics to be drawn onto the target canvas.
    // Specifically: 'circle', 'ellipse', 'image', 'line', 'path', 'polygon', 'polyline', 'rect', 'text' and 'use'.
    sealed class GraphicsElement : SvgTransformingConditionalElement()

    // A linking element (we don't currently do anything with this. It is basically just treated like a Group.)
    class A : Group() {
        @JvmField
        var href: String? = null

        override fun getNodeName(): String {
            return "a"
        }
    }

    class Use : Group() {
        @JvmField
        var href: String? = null

        @JvmField
        var x: CSSLength? = null

        @JvmField
        var y: CSSLength? = null

        @JvmField
        var width: CSSLength? = null

        @JvmField
        var height: CSSLength? = null

        override fun getNodeName(): String {
            return "use"
        }
    }

    class Path : GraphicsElement() {
        @JvmField
        var d: PathDefinition? = null

        @JvmField
        var pathLength: Float? = null

        override fun getNodeName(): String {
            return "path"
        }
    }


    class Rect : GraphicsElement() {
        @JvmField
        var x: CSSLength? = null

        @JvmField
        var y: CSSLength? = null

        @JvmField
        var width: CSSLength? = null

        @JvmField
        var height: CSSLength? = null

        @JvmField
        var rx: CSSLength? = null

        @JvmField
        var ry: CSSLength? = null

        override fun getNodeName(): String {
            return "rect"
        }
    }


    class Circle : GraphicsElement() {
        @JvmField
        var cx: CSSLength? = null

        @JvmField
        var cy: CSSLength? = null

        @JvmField
        var r: CSSLength? = null

        override fun getNodeName(): String {
            return "circle"
        }
    }


    class Ellipse : GraphicsElement() {
        @JvmField
        var cx: CSSLength? = null

        @JvmField
        var cy: CSSLength? = null

        @JvmField
        var rx: CSSLength? = null

        @JvmField
        var ry: CSSLength? = null

        override fun getNodeName(): String {
            return "ellipse"
        }
    }


    class Line : GraphicsElement() {
        @JvmField
        var x1: CSSLength? = null

        @JvmField
        var y1: CSSLength? = null

        @JvmField
        var x2: CSSLength? = null

        @JvmField
        var y2: CSSLength? = null

        override fun getNodeName(): String {
            return "line"
        }
    }


    open class PolyLine : GraphicsElement() {
        @JvmField
        var points: FloatArray? = null

        override fun getNodeName(): String {
            return "polyline"
        }
    }


    class Polygon : PolyLine() {
        override fun getNodeName(): String {
            return "polygon"
        }
    }

    abstract class TextContainer : SvgConditionalContainer() {
        @Throws(SVGParseException::class)
        override fun addChild(elem: SvgObject) {
            checkState(elem is TextChild) {
                "Text content elements cannot contain $elem elements."
            }
            super.addChild(elem)
        }
    }

    abstract class TextPositionedContainer : TextContainer() {
        @JvmField
        var x: List<CSSLength>? = null

        @JvmField
        var y: List<CSSLength>? = null

        @JvmField
        var dx: List<CSSLength>? = null

        @JvmField
        var dy: List<CSSLength>? = null
    }

    class Text : TextPositionedContainer(), TextRoot, HasTransform {
        @JvmField
        var transform: Matrix? = null

        override fun setTransform(transform: Matrix?) {
            this.transform = transform
        }

        override fun getTransform(): Matrix? {
            return transform
        }

        override fun getNodeName(): String {
            return "text"
        }
    }

    class TSpan : TextPositionedContainer(), TextChild {
        override var textRoot: TextRoot? = null

        override fun getNodeName(): String {
            return "tspan"
        }
    }

    class TextSequence(
        @JvmField
        var text: String
    ) : SvgObjectImpl(), TextChild {
        override var textRoot: TextRoot? = null

        override fun toString(): String {
            return "TextChild: '$text'"
        }
    }

    class TRef : TextContainer(), TextChild {
        @JvmField
        var href: String? = null

        override var textRoot: TextRoot? = null

        override fun getNodeName(): String {
            return "tref"
        }
    }

    class TextPath : TextContainer(), TextChild {
        @JvmField
        var href: String? = null

        @JvmField
        var startOffset: CSSLength? = null

        override var textRoot: TextRoot? = null

        override fun getNodeName(): String {
            return "textPath"
        }
    }

    // An SVG element that can contain other elements.
    class Switch : Group() {
        override fun getNodeName(): String {
            return "switch"
        }
    }

    class Symbol : SvgViewBoxContainer(), NotDirectlyRendered {
        override fun getNodeName(): String {
            return "symbol"
        }
    }

    class Marker : SvgViewBoxContainer(), NotDirectlyRendered {
        @JvmField
        var markerUnitsAreUser: Boolean = false

        @JvmField
        var refX: CSSLength? = null

        @JvmField
        var refY: CSSLength? = null

        @JvmField
        var markerWidth: CSSLength? = null

        @JvmField
        var markerHeight: CSSLength? = null

        @JvmField
        var orient: Float? = null

        override fun getNodeName(): String {
            return "marker"
        }
    }


    abstract class GradientElement : SvgContainerImpl() {

        @JvmField
        var gradientUnitsAreUser: Boolean? = null

        @JvmField
        var gradientTransform: Matrix? = null

        @JvmField
        var spreadMethod: GradientSpread? = null

        @JvmField
        var href: String? = null

        @Throws(SVGParseException::class)
        override fun addChild(elem: SvgObject) {
            if (elem is Stop) {
                super.addChild(elem)
            } else {
                throw SVGParseException("Gradient elements cannot contain $elem elements.")
            }
        }
    }


    class Stop : SvgContainerImpl() {
        @JvmField
        var offset: Float? = null

        // Dummy container methods. Stop is officially a container, but we
        // are not interested in any of its possible child elements.
        override fun addChild(elem: SvgObject) {
            /* do nothing */
        }

        override fun addAll(list: List<SvgObject>) {
            /* do nothing */
        }

        override fun getNodeName(): String {
            return "stop"
        }
    }


    class SvgLinearGradient : GradientElement() {
        @JvmField
        var x1: CSSLength? = null

        @JvmField
        var y1: CSSLength? = null

        @JvmField
        var x2: CSSLength? = null

        @JvmField
        var y2: CSSLength? = null

        override fun getNodeName(): String {
            return "linearGradient"
        }
    }


    class SvgRadialGradient : GradientElement() {
        @JvmField
        var cx: CSSLength? = null

        @JvmField
        var cy: CSSLength? = null

        @JvmField
        var r: CSSLength? = null

        @JvmField
        var fx: CSSLength? = null

        @JvmField
        var fy: CSSLength? = null

        @JvmField
        var fr: CSSLength? = null

        override fun getNodeName(): String {
            return "radialGradient"
        }
    }


    class ClipPath : Group(), NotDirectlyRendered {
        @JvmField
        var clipPathUnitsAreUser: Boolean? = null

        override fun getNodeName(): String {
            return NODE_NAME
        }

        companion object {
            const val NODE_NAME: String = "clipPath"
        }
    }


    class Pattern : SvgViewBoxContainer(), NotDirectlyRendered {
        @JvmField
        var patternUnitsAreUser: Boolean? = null

        @JvmField
        var patternContentUnitsAreUser: Boolean? = null

        @JvmField
        var patternTransform: Matrix? = null

        @JvmField
        var x: CSSLength? = null

        @JvmField
        var y: CSSLength? = null

        @JvmField
        var width: CSSLength? = null

        @JvmField
        var height: CSSLength? = null

        @JvmField
        var href: String? = null

        override fun getNodeName(): String {
            return "pattern"
        }
    }


    class Image : SvgPreserveAspectRatioContainer(), HasTransform {
        @JvmField
        var href: String? = null

        @JvmField
        var x: CSSLength? = null

        @JvmField
        var y: CSSLength? = null

        @JvmField
        var width: CSSLength? = null

        @JvmField
        var height: CSSLength? = null

        @JvmField
        var transform: Matrix? = null

        override fun setTransform(transform: Matrix?) {
            this.transform = transform
        }

        override fun getTransform(): Matrix? {
            return transform
        }

        override fun getNodeName(): String {
            return "image"
        }
    }


    class View : SvgViewBoxContainer(), NotDirectlyRendered {
        override fun getNodeName(): String {
            return NODE_NAME
        }

        companion object {
            const val NODE_NAME: String = "view"
        }
    }


    class Mask : SvgConditionalContainer(), NotDirectlyRendered {
        @JvmField
        var maskUnitsAreUser: Boolean? = null

        @JvmField
        var maskContentUnitsAreUser: Boolean? = null
        var x: CSSLength? = null
        var y: CSSLength? = null

        @JvmField
        var width: CSSLength? = null

        @JvmField
        var height: CSSLength? = null

        override fun getNodeName(): String {
            return "mask"
        }
    }


    class SolidColor : SvgContainerImpl() {
        // Not needed right now. Color is set in this.baseStyle.
        //public Length  solidColor;
        //public Length  solidOpacity;
        // Dummy container methods. Stop is officially a container, but we
        // are not interested in any of its possible child elements.

    }

    class Filter : SvgConditionalContainer() {
        @JvmField
        var filterUnitsAreUser: Boolean? = null

        @JvmField
        var primitiveUnitsAreUser: Boolean? = null

        @JvmField
        var x: CSSLength? = null

        @JvmField
        var y: CSSLength? = null

        @JvmField
        var width: CSSLength? = null

        @JvmField
        var height: CSSLength? = null

        override fun getNodeName(): String {
            return "filter"
        }
    }

    abstract class FilterPrimitive : SvgContainerImpl() {
        @JvmField
        var x: CSSLength? = null

        @JvmField
        var y: CSSLength? = null

        @JvmField
        var width: CSSLength? = null

        @JvmField
        var height: CSSLength? = null

        @JvmField
        var result: String? = null

        @JvmField
        var `in`: String? = null
    }

    class FeBlend : FilterPrimitive() {
        @JvmField
        var in2: String? = null

        @JvmField
        var mode: FeBlendMode = FeBlendMode.normal

        override fun getNodeName(): String {
            return "feBlend"
        }
    }

    class FeColorMatrix : FilterPrimitive() {
        @JvmField
        var type: FeColorMatrixType = FeColorMatrixType.matrix

        @JvmField
        var values: FloatArray? = null

        override fun getNodeName(): String {
            return "feColorMatrix"
        }
    }

    class FeComponentTransfer : FilterPrimitive() {
        override fun getNodeName(): String {
            return "feComponentTransfer"
        }
    }

    class FeFunc : SvgContainerImpl() {
        enum class Channel { R, G, B, A }

        @JvmField
        var channel: Channel = Channel.R

        @JvmField
        var type: FeFuncType = FeFuncType.identity

        @JvmField
        var tableValues: FloatArray? = null

        @JvmField
        var slope: Float = 1f

        @JvmField
        var intercept: Float = 0f

        @JvmField
        var amplitude: Float = 1f

        @JvmField
        var exponent: Float = 1f

        @JvmField
        var offset: Float = 0f

        override fun getNodeName(): String {
            return when (channel) {
                Channel.R -> "feFuncR"
                Channel.G -> "feFuncG"
                Channel.B -> "feFuncB"
                Channel.A -> "feFuncA"
            }
        }
    }

    class FeComposite : FilterPrimitive() {
        @JvmField
        var in2: String? = null

        @JvmField
        var operator: FeCompositeOperator = FeCompositeOperator.over

        @JvmField
        var k1: Float = 0f

        @JvmField
        var k2: Float = 0f

        @JvmField
        var k3: Float = 0f

        @JvmField
        var k4: Float = 0f

        override fun getNodeName(): String {
            return "feComposite"
        }
    }

    class FeConvolveMatrix : FilterPrimitive() {
        @JvmField
        var orderX: Int = 3

        @JvmField
        var orderY: Int = 3

        @JvmField
        var kernelMatrix: FloatArray? = null

        @JvmField
        var divisor: Float = 0f

        @JvmField
        var bias: Float = 0f

        @JvmField
        var targetX: Int? = null

        @JvmField
        var targetY: Int? = null

        @JvmField
        var edgeMode: ConvolveMatrixEdgeMode = ConvolveMatrixEdgeMode.duplicate

        @JvmField
        var preserveAlpha: Boolean = false

        override fun getNodeName(): String {
            return "feConvolveMatrix"
        }
    }

    class FeDiffuseLighting : FilterPrimitive() {
        @JvmField
        var surfaceScale: Float = 1f

        @JvmField
        var diffuseConstant: Float = 1f

        @JvmField
        var light: SvgLight? = null

        override fun getNodeName(): String {
            return "feDiffuseLighting"
        }
    }

    class FeSpecularLighting : FilterPrimitive() {
        @JvmField
        var surfaceScale: Float = 1f

        @JvmField
        var specularConstant: Float = 1f

        @JvmField
        var specularExponent: Float = 1f

        @JvmField
        var light: SvgLight? = null

        override fun getNodeName(): String {
            return "feSpecularLighting"
        }
    }

    sealed class SvgLight : SvgContainerImpl()

    class FeDistantLight : SvgLight() {
        @JvmField
        var azimuth: Float = 0f

        @JvmField
        var elevation: Float = 0f

        override fun getNodeName(): String {
            return "feDistantLight"
        }
    }

    class FePointLight : SvgLight() {
        @JvmField
        var x: Float = 0f

        @JvmField
        var y: Float = 0f

        @JvmField
        var z: Float = 0f

        override fun getNodeName(): String {
            return "fePointLight"
        }
    }

    class FeSpotLight : SvgLight() {
        @JvmField
        var x: Float = 0f

        @JvmField
        var y: Float = 0f

        @JvmField
        var z: Float = 0f

        @JvmField
        var pointsAtX: Float = 0f

        @JvmField
        var pointsAtY: Float = 0f

        @JvmField
        var pointsAtZ: Float = 0f

        @JvmField
        var limitingConeAngle: Float? = null

        override fun getNodeName(): String {
            return "feSpotLight"
        }
    }

    class FeDisplacementMap : FilterPrimitive() {
        @JvmField
        var in2: String? = null

        @JvmField
        var scale: Float = 0f

        @JvmField
        var xChannelSelector: FeChannelSelector = FeChannelSelector.A

        @JvmField
        var yChannelSelector: FeChannelSelector = FeChannelSelector.A

        override fun getNodeName(): String {
            return "feDisplacementMap"
        }
    }

    class FeFlood : FilterPrimitive() {
        // Properties flood-color and flood-opacity are in the style

        override fun getNodeName(): String {
            return "feFlood"
        }
    }

    class FeGaussianBlur : FilterPrimitive() {
        @JvmField
        var stdDeviationX: Float = 0f

        @JvmField
        var stdDeviationY: Float = 0f

        override fun getNodeName(): String {
            return "feGaussianBlur"
        }
    }

    class FeImage : FilterPrimitive() {
        @JvmField
        var href: String? = null

        override fun getNodeName(): String {
            return "feImage"
        }
    }

    class FeMerge : SvgConditionalContainer() {
        @JvmField
        var result: String? = null

        override fun getNodeName(): String {
            return "feMerge"
        }
    }

    class FeMergeNode : SvgContainerImpl() {
        @JvmField
        var `in`: String? = null

        override fun getNodeName(): String {
            return "feMergeNode"
        }
    }

    class FeOffset : FilterPrimitive() {
        @JvmField
        var dx: CSSLength? = null

        @JvmField
        var dy: CSSLength? = null

        override fun getNodeName(): String {
            return "feOffset"
        }
    }

    class FeTurbulence : FilterPrimitive() {
        @JvmField
        var baseFrequencyX: Float = 0f

        @JvmField
        var baseFrequencyY: Float = 0f

        @JvmField
        var numOctaves: Int = 1

        @JvmField
        var seed: Float = 0f

        @JvmField
        var stitchTiles: FeStitchTiles = FeStitchTiles.noStitch

        @JvmField
        var type: FeTurbulenceType = FeTurbulenceType.turbulence

        override fun getNodeName(): String {
            return "feTurbulence"
        }
    }

    class FeMorphology : FilterPrimitive() {
        @JvmField
        var operator: FeMorphologyOperator = FeMorphologyOperator.erode

        @JvmField
        var radiusX: Float = 0f

        @JvmField
        var radiusY: Float = 0f

        override fun getNodeName(): String {
            return "feMorphology"
        }
    }

    class FeTile : FilterPrimitive() {
        override fun getNodeName(): String {
            return "feTile"
        }
    }
}
