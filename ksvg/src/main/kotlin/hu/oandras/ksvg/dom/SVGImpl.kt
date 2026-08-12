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
package hu.oandras.ksvg.dom

// Box and SvgObject are in the same package
import android.content.Context
import android.content.res.AssetManager
import android.content.res.Resources
import android.graphics.Canvas
import android.graphics.Path
import android.graphics.Picture
import android.graphics.RectF
import android.util.Log
import androidx.collection.ArrayMap
import androidx.collection.ArraySet
import hu.oandras.ksvg.PreserveAspectRatio
import hu.oandras.ksvg.RenderOptions
import hu.oandras.ksvg.SVG
import hu.oandras.ksvg.SVGExternalFileResolver
import hu.oandras.ksvg.SVGParseException
import hu.oandras.ksvg.css.CSSLength
import hu.oandras.ksvg.css.CSSParser
import hu.oandras.ksvg.css.CSSParser.Ruleset
import hu.oandras.ksvg.css.CssUnit
import hu.oandras.ksvg.parser.SVGParser
import hu.oandras.ksvg.parser.SVGParserImpl
import hu.oandras.ksvg.parser.SVGParserImpl.Companion.parseLength
import hu.oandras.ksvg.render.PathConverter
import hu.oandras.ksvg.render.SVGAndroidRenderer
import hu.oandras.ksvg.utils.RenderOptionsImpl
import hu.oandras.ksvg.utils.ceilToInt
import hu.oandras.ksvg.utils.forEachElement
import java.io.ByteArrayInputStream
import java.io.IOException
import java.io.InputStream

internal const val COLOR_WHITE: Int = 0xFFFFFFFF.toInt()
internal const val COLOR_BLACK: Int = -0x1000000

/**
 * KSVG is a library for reading, parsing and rendering SVG documents on Android devices.
 * 
 * 
 * All interaction with KSVG is via this class.
 * 
 * 
 * Typically, you will call one of the SVG loading and parsing classes then call the renderer,
 * passing it a canvas to draw upon.
 * 
 * <h3>Usage summary</h3>
 * 
 * 
 *  * Use one of the static `getFromX()` methods to read and parse the SVG file.  They will
 * return an instance of this class.
 *  * Call one of the `renderToX()` methods to render the document.
 * 
 * 
 * <h3>Usage example</h3>
 * 
 * <pre>
 * `SVG.registerExternalFileResolver(myResolver); SVG  svg = SVG.getFromAsset(getContext().getAssets(), svgPath); Bitmap  newBM = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888); Canvas  bmcanvas = new Canvas(newBM); bmcanvas.drawRGB(255, 255, 255);  // Clear background to white svg.renderToCanvas(bmcanvas); `
</pre> * 
 * 
 * For more detailed information on how to use this library, see the documentation at `https://github.com/oraveczandrew/ksvg`
 */
@OptIn(ExperimentalStdlibApi::class)
internal class SVGImpl internal constructor(
    /**
     * Indicates whether internal entities were enabled when this SVG was parsed.
     * 
     * *Note: prior to release 1.5, this was a static method of (@code SVG).  In 1.5, it was
     * changed to an instance method to coincide with the change making parsing settings thread safe.*
     * 

     */
    override val isInternalEntitiesEnabled: Boolean,
    /**
     * The [SVGExternalFileResolver] in effect when this SVG was parsed.
     * 

     */
    // The parser configuration settings that was used for the current instance
    // Will continue to be used for future parsing by this instance. For example
    // when parsing addition CSS.
    override val externalFileResolver: SVGExternalFileResolver?
) : SVG {
    //===============================================================================
    // The root svg element
    @JvmField
    internal var rootElement: SvgObject.Svg? = null

    internal fun requireRootElement(): SvgObject.Svg {
        return requireNotNull(rootElement) { "SVG document is empty" }
    }

    // Metadata
    private var title: String? = ""
    private var desc: String? = ""

    /**
     * The DPI (dots-per-inch) value to use when rendering.
     * 
     * The DPI setting is used in the conversion of "physical" units - such a "pt" or "cm" - to pixel values.
     * The default DPI is 96.
     * 
     * You should not normally need to alter the DPI from the default of 96 as recommended by the SVG
     * and CSS specifications.
     */
    override var renderDPI: Float = 96f // default is 96

    // CSS rules
    private val cssRules = Ruleset()

    // Map from id attribute to element
    private val idToElementMap: ArrayMap<String, SvgObject> = ArrayMap()

    //===============================================================================
    // SVG document rendering to a Picture object (indirect rendering)
    /**
     * Renders this SVG document to a Picture object.
     * 
     * 
     * An attempt will be made to determine a suitable initial viewport from the contents of the SVG file.
     * If an appropriate viewport can't be determined, a default viewport of 512x512 will be used.
     * 
     * @return a Picture object suitable for later rendering using `Canvas.drawPicture()`
     */
    override fun renderToPicture(): Picture {
        return renderToPicture(renderOptions = null)
    }

    /**
     * Renders this SVG document to a [Picture].
     * 
     * @param widthInPixels the width of the initial viewport
     * @param heightInPixels the height of the initial viewport
     * @return a Picture object suitable for later rendering using [Canvas.drawPicture]
     */
    override fun renderToPicture(widthInPixels: Int, heightInPixels: Int): Picture {
        return renderToPicture(
            widthInPixels = widthInPixels,
            heightInPixels = heightInPixels,
            renderOptions = null
        )
    }

    /**
     * Renders this SVG document to a [Picture].
     * 
     * @param renderOptions options that describe how to render this SVG on the Canvas.
     * @return a Picture object suitable for later rendering using [Canvas.drawPicture]

     */
    override fun renderToPicture(renderOptions: RenderOptions?): Picture {
        val rootElement = rootElement!!
        val viewBox = if (renderOptions != null && renderOptions.hasViewBox()) {
            renderOptions.viewBox
        } else {
            rootElement.viewBox
        }

        // If a viewPort was supplied in the renderOptions, then use its maxX and maxY as the Picture size
        return if (renderOptions?.hasViewPort() == true) {
            val viewPort = renderOptions.viewPort!!
            val w = viewPort.maxX()
            val h = viewPort.maxY()

            renderToPicture(
                widthInPixels = w.ceilToInt(),
                heightInPixels = h.ceilToInt(),
                renderOptions = renderOptions
            )
        } else {
            val rootWidth = rootElement.width
            val rootHeight = rootElement.height
            if (rootWidth != null && rootWidth.unit != CssUnit.percent && rootHeight != null && rootHeight.unit != CssUnit.percent) {
                val w = rootWidth.floatValue(renderDPI)
                val h = rootHeight.floatValue(renderDPI)

                renderToPicture(
                    widthInPixels = w.ceilToInt(),
                    heightInPixels = h.ceilToInt(),
                    renderOptions = renderOptions
                )
            } else if (rootWidth != null && viewBox != null) {
                // Width and viewBox supplied, but no height
                // Determine the Picture size and initial viewport. See SVG spec section 7.12.
                val w = rootWidth.floatValue(renderDPI)
                val h = w * viewBox.height / viewBox.width

                renderToPicture(
                    widthInPixels = w.ceilToInt(),
                    heightInPixels = h.ceilToInt(),
                    renderOptions = renderOptions
                )
            } else if (rootHeight != null && viewBox != null) {
                // Height and viewBox supplied, but no width
                val h = rootHeight.floatValue(renderDPI)
                val w = h * viewBox.width / viewBox.height

                renderToPicture(
                    widthInPixels = w.ceilToInt(),
                    heightInPixels = h.ceilToInt(),
                    renderOptions = renderOptions
                )
            } else {
                renderToPicture(
                    widthInPixels = DEFAULT_PICTURE_WIDTH,
                    heightInPixels = DEFAULT_PICTURE_HEIGHT,
                    renderOptions = renderOptions
                )
            }
        }
    }

    /**
     * Renders this SVG document to a [Picture].
     * 
     * @param widthInPixels the width of the `Picture`
     * @param heightInPixels the height of the `Picture`
     * @param renderOptions options that describe how to render this SVG on the Canvas.
     * @return a Picture object suitable for later rendering using [Canvas.drawPicture]

     */
    override fun renderToPicture(
        widthInPixels: Int,
        heightInPixels: Int,
        renderOptions: RenderOptions?
    ): Picture {
        var renderOptions = renderOptions
        
        val picture = Picture()
        val canvas = picture.beginRecording(widthInPixels, heightInPixels)

        if (renderOptions?.viewPort == null) {
            renderOptions = if (renderOptions == null) {
                RenderOptionsImpl()
            } else {
                RenderOptionsImpl(renderOptions)
            }
            renderOptions.viewPort(
                minX = 0f,
                minY = 0f,
                width = widthInPixels.toFloat(),
                height = heightInPixels.toFloat()
            )
        }

        val renderer = SVGAndroidRenderer(
            document = this,
            canvas = canvas,
            dPI = renderDPI,
            externalFileResolver = externalFileResolver
        )

        renderer.renderDocument(renderOptions)

        picture.endRecording()
        return picture
    }

    /**
     * Renders this SVG document to a [Picture] using the specified view defined in the document.
     * 
     * 
     * A View is a special element in an SVG document that describes a rectangular area in the document.
     * Calling this method with a `viewId` will result in the specified view being positioned and scaled
     * to the viewport.  In other words, use [.renderToPicture] to render the whole document, or use this
     * method instead to render just a part of it.
     * 
     * @param viewId the id of a view element in the document that defines which section of the document is to be visible.
     * @param widthInPixels the width of the initial viewport
     * @param heightInPixels the height of the initial viewport
     * @return a Picture object suitable for later rendering using `Canvas.drawPicture()`, or null if the viewId was not found.
     */
    override fun renderViewToPicture(viewId: String?, widthInPixels: Int, heightInPixels: Int): Picture {
        val renderOptions = RenderOptionsImpl()
        renderOptions
            .view(viewId)
            .viewPort(
                minX = 0f,
                minY = 0f,
                width = widthInPixels.toFloat(),
                height = heightInPixels.toFloat()
            )


        val picture = Picture()
        val canvas = picture.beginRecording(widthInPixels, heightInPixels)

        val renderer = SVGAndroidRenderer(
            document = this,
            canvas = canvas,
            dPI = renderDPI,
            externalFileResolver = externalFileResolver
        )

        renderer.renderDocument(renderOptions)

        picture.endRecording()
        return picture
    }

    //===============================================================================
    // SVG document rendering to a canvas object (direct rendering)
    /**
     * Renders this SVG document to a Canvas object.  The full width and height of the canvas
     * will be used as the viewport into which the document will be rendered.
     * 
     * @param canvas the canvas to which the document should be rendered.

     */
    override fun renderToCanvas(canvas: Canvas) {
        renderToCanvas(
            canvas = canvas,
            renderOptions = null
        )
    }

    /**
     * Renders this SVG document to a Canvas object.
     * 
     * @param canvas the canvas to which the document should be rendered.
     * @param viewPort the bounds of the area on the canvas you want the SVG rendered, or null for the whole canvas.
     */
    override fun renderToCanvas(canvas: Canvas, viewPort: RectF?) {
        val renderOptions = RenderOptionsImpl()

        if (viewPort != null) {
            renderOptions.viewPort(
                minX = viewPort.left,
                minY = viewPort.top,
                width = viewPort.width(),
                height = viewPort.height()
            )
        } else {
            renderOptions.viewPort(
                minX = 0f,
                minY = 0f,
                width = canvas.width.toFloat(),
                height = canvas.height.toFloat()
            )
        }

        val renderer = SVGAndroidRenderer(
            document = this,
            canvas = canvas,
            dPI = renderDPI,
            externalFileResolver = externalFileResolver
        )

        renderer.renderDocument(renderOptions)
    }

    /**
     * Renders this SVG document to a Canvas object.
     * 
     * @param canvas the canvas to which the document should be rendered.
     * @param renderOptions options that describe how to render this SVG on the Canvas.

     */
    override fun renderToCanvas(canvas: Canvas, renderOptions: RenderOptions?) {
        val renderOptions = renderOptions ?: RenderOptionsImpl()

        if (!renderOptions.hasViewPort()) {
            renderOptions.viewPort(
                minX = 0f,
                minY = 0f,
                width = canvas.width.toFloat(),
                height = canvas.height.toFloat()
            )
        }

        val renderer = SVGAndroidRenderer(
            document = this,
            canvas = canvas,
            dPI = renderDPI,
            externalFileResolver = externalFileResolver
        )

        renderer.renderDocument(renderOptions)
    }

    /**
     * Renders this SVG document to a Canvas using the specified view defined in the document.
     * 
     * 
     * A View is a special element in an SVG documents that describes a rectangular area in the document.
     * Calling this method with a `viewId` will result in the specified view being positioned and scaled
     * to the viewport.  In other words, use [.renderToPicture] to render the whole document, or use this
     * method instead to render just a part of it.
     * 
     * 
     * If the `<view>` could not be found, nothing will be drawn.
     * 
     * @param viewId the id of a view element in the document that defines which section of the document is to be visible.
     * @param canvas the canvas to which the document should be rendered.
     */
    override fun renderViewToCanvas(viewId: String?, canvas: Canvas) {
        renderToCanvas(canvas, RenderOptionsImpl().view(viewId))
    }

    /**
     * Renders this SVG document to a Canvas using the specified view defined in the document.
     * 
     * 
     * A View is a special element in an SVG documents that describes a rectangular area in the document.
     * Calling this method with a `viewId` will result in the specified view being positioned and scaled
     * to the viewport.  In other words, use [.renderToPicture] to render the whole document, or use this
     * method instead to render just a part of it.
     * 
     * 
     * If the `<view>` could not be found, nothing will be drawn.
     * 
     * @param viewId the id of a view element in the document that defines which section of the document is to be visible.
     * @param canvas the canvas to which the document should be rendered.
     * @param viewPort the bounds of the area on the canvas you want the SVG rendered, or null for the whole canvas.
     */
    override fun renderViewToCanvas(viewId: String?, canvas: Canvas, viewPort: RectF?) {
        val renderOptions = RenderOptionsImpl().view(viewId)

        if (viewPort != null) {
            renderOptions.viewPort(
                minX = viewPort.left,
                minY = viewPort.top,
                width = viewPort.width(),
                height = viewPort.height()
            )
        }

        renderToCanvas(canvas, renderOptions)
    }

    //===============================================================================
    // Other document utility API functions
    /**
     * The contents of the `<title>` element in the SVG document.
     * 
     * @throws IllegalArgumentException if there is no current SVG document loaded.
     */
    override val documentTitle: String?
        get() {
            requireRootElement()
            return title
        }

    /**
     * The contents of the `<desc>` element in the SVG document.
     * 
     * @throws IllegalArgumentException if there is no current SVG document loaded.
     */
    override val documentDescription: String?
        get() {
            requireRootElement()
            return desc
        }

    /**
     * The SVG version number as provided in the root `<svg>` tag of the document.
     *
     * @throws IllegalArgumentException if there is no current SVG document loaded.
     */
    override val documentSVGVersion: String?
        get() = requireRootElement().version

    /**
     * A list of ids for all `<view>` elements in this SVG document.
     * 
     * The returned view ids could be used when calling and of the `renderViewToX()` methods.
     * 
     * @throws IllegalArgumentException if there is no current SVG document loaded.
     */
    override val viewList: MutableSet<String>
        get() {
            val viewElems = getElementsByTagName(SvgObject.View.NODE_NAME)

            return viewElems.mapNotNullTo(ArraySet(viewElems.size)) { elem ->
                (elem as SvgObject.View).id.also {
                    if (it == null) {
                        Log.w("KSVG", "getViewList(): found a <view> without an id attribute")
                    }
                }
            }
        }

    /**
     * The width of the document as specified in the SVG file.
     * 
     * If the width in the document is specified in pixels, that value will be returned.
     * If the value is listed with a physical unit such as "cm", then the current
     * `RenderDPI` value will be used to convert that value to pixels. If the width
     * is missing, or in a form which can't be converted to pixels, such as "100%" for
     * example, -1 will be returned.
     * 
     * Setting this property changes the width of the document by altering the "width" attribute
     * of the root `<svg>` element.
     * 
     * @throws IllegalArgumentException if there is no current SVG document loaded.
     */
    override var documentWidth: Float
        get() = getDocumentDimensions(renderDPI).width
        set(pixels) {
            requireRootElement().width = CSSLength(pixels)
        }

    /**
     * Change the width of the document by altering the "width" attribute
     * of the root `<svg>` element.
     * 
     * @param value A valid SVG 'length' attribute, such as "100px" or "10cm".
     * @throws SVGParseException if `value` cannot be parsed successfully.
     * @throws IllegalArgumentException if there is no current SVG document loaded.
     */
    override fun setDocumentWidth(value: String) {
        requireRootElement().width = parseLength(value)
    }

    /**
     * The height of the document as specified in the SVG file.
     * 
     * If the height in the document is specified in pixels, that value will be returned.
     * If the value is listed with a physical unit such as "cm", then the current
     * `RenderDPI` value will be used to convert that value to pixels. If the height
     * is missing, or in a form which can't be converted to pixels, such as "100%" for
     * example, -1 will be returned.
     * 
     * Setting this property changes the height of the document by altering the "height" attribute
     * of the root `<svg>` element.
     * 
     * @throws IllegalArgumentException if there is no current SVG document loaded.
     */
    override var documentHeight: Float
        get() {
            requireRootElement()
            return getDocumentDimensions(renderDPI).height
        }
        set(pixels) {
            requireRootElement().height = CSSLength(pixels)
        }

    /**
     * Change the height of the document by altering the "height" attribute
     * of the root `<svg>` element.
     * 
     * @param value A valid SVG 'length' attribute, such as "100px" or "10cm".
     * @throws SVGParseException if `value` cannot be parsed successfully.
     * @throws IllegalArgumentException if there is no current SVG document loaded.
     */
    override fun setDocumentHeight(value: String) {
        requireRootElement().height = parseLength(value)
    }


    /**
     * Change the document view box by altering the "viewBox" attribute
     * of the root `<svg>` element.
     * 
     * 
     * The viewBox generally describes the bounding box dimensions of the
     * document contents.  A valid viewBox is necessary if you want the
     * document scaled to fit the canvas or viewport the document is to be
     * rendered into.
     * 
     * 
     * By setting a viewBox that describes only a portion of the document,
     * you can reproduce the effect of image sprites.
     * 
     * @param minX the left coordinate of the viewBox in pixels
     * @param minY the top coordinate of the viewBox in pixels.
     * @param width the width of the viewBox in pixels
     * @param height the height of the viewBox in pixels
     * @throws IllegalArgumentException if there is no current SVG document loaded.
     */
    override fun setDocumentViewBox(minX: Float, minY: Float, width: Float, height: Float) {
        requireRootElement().viewBox = Box(minX, minY, width, height)
    }


    /**
     * The viewBox attribute of the current SVG document.
     * 
     * @throws IllegalArgumentException if there is no current SVG document loaded.
     */
    override val documentViewBox: RectF?
        get() = requireRootElement().viewBox?.toRectF()

    /**
     * The "preserveAspectRatio" attribute of the root `<svg>` element.
     * 
     * Positioning works according to the documentation for [PreserveAspectRatio].
     * 
     * @throws IllegalArgumentException if there is no current SVG document loaded.
     */
    override var documentPreserveAspectRatio: PreserveAspectRatio?
        get() = requireRootElement().preserveAspectRatio
        set(preserveAspectRatio) {
            requireRootElement().preserveAspectRatio = preserveAspectRatio
        }

    /**
     * The aspect ratio of the document as a width/height fraction.
     * 
     * If the width or height of the document are listed with a physical unit such as "cm",
     * then the current `renderDPI` setting will be used to convert that value to pixels.
     * 
     * If the width or height cannot be determined, -1 will be returned.
     * 
     * @throws IllegalArgumentException if there is no current SVG document loaded.
     */
    override val documentAspectRatio: Float
        get() {
            val rootElement = requireRootElement()

            val w = rootElement.width
            val h = rootElement.height

            // If width and height are both specified and are not percentages, aspect ratio is calculated from these (SVG1.1 sect 7.12)
            if (w != null && h != null && w.unit != CssUnit.percent && h.unit != CssUnit.percent) {
                if (w.isZero || h.isZero) return -1f
                return w.floatValue(renderDPI) / h.floatValue(renderDPI)
            }

            // Otherwise, get the ratio from the viewBox
            val viewBox = rootElement.viewBox
            if (viewBox != null && viewBox.width != 0f && viewBox.height != 0f) {
                return viewBox.width / viewBox.height
            }

            // Could not determine aspect ratio
            return -1f
        }


    internal fun resolveIRI(iri: String?): SvgObject? {
        var iri = iri ?: return null

        iri = cssQuotedString(iri)
        return if (iri.length > 1 && iri.startsWith('#')) {
            getElementById(iri.substring(1))
        } else {
            null
        }
    }

    private fun cssQuotedString(str: String): String {
        var result = str

        if (result.startsWith('"') && result.endsWith('"')) {
            // Remove quotes and replace escaped double-quote
            result = result.substring(1, result.lastIndex).replace("\\\"", "\"")
        } else if (result.startsWith('\'') && result.endsWith('\'')) {
            // Remove quotes and replace escaped single-quote
            result = result.substring(1, result.lastIndex).replace("\\'", "'")
        }

        // Remove escaped newline. Replace escape seq representing newline
        return result
            .replace("\\\n", "")
            .replace("\\A", "\n")
    }

    private fun getDocumentDimensions(dpi: Float): Box {
        val rootElement = requireRootElement()
        val w = rootElement.width
        val h = rootElement.height

        if (w == null || w.isZero || w.unit == CssUnit.percent || w.unit == CssUnit.em || w.unit == CssUnit.ex) {
            return Box(
                minX = -1f,
                minY = -1f,
                width = -1f,
                height = -1f
            )
        }

        val wOut = w.floatValue(dpi)
        val hOut: Float

        if (h != null) {
            if (h.isZero || h.unit == CssUnit.percent || h.unit == CssUnit.em || h.unit == CssUnit.ex) {
                return Box(
                    minX = -1f,
                    minY = -1f,
                    width = -1f,
                    height = -1f
                )
            }
            hOut = h.floatValue(dpi)
        } else {
            // height is not specified. SVG spec says this is okay. If there is a viewBox, we use
            // that to calculate the height. Otherwise, we set height equal to width.
            val viewBox = rootElement.viewBox
            hOut = if (viewBox != null) {
                (wOut * viewBox.height) / viewBox.width
            } else {
                wOut
            }
        }

        return Box(
            minX = 0f,
            minY = 0f,
            width = wOut,
            height = hOut
        )
    }

    //===============================================================================
    // CSS support methods
    internal fun addCSSRules(ruleset: Ruleset) {
        cssRules.addAll(ruleset)
    }

    internal val cSSRules: List<CSSParser.Rule>
        get() = cssRules.rules

    fun clearRenderCSSRules() {
        cssRules.removeFromSource(CSSParser.Source.RenderOptions)
    }

    //===============================================================================
    // Protected setters for internal use
    internal fun setTitle(title: String?) {
        this.title = title
    }

    internal fun setDesc(desc: String?) {
        this.desc = desc
    }

    internal fun getElementById(id: String?): SvgObject? {
        if (id.isNullOrEmpty()) return null

        val rootElement = requireRootElement()

        return if (id == rootElement.id) {
            rootElement
        } else {
            idToElementMap.getOrPutIfMissing(id) {
                // Search the object tree for a node with id property that matches 'id'
                getElementById(rootElement, id)
            }
        }
    }

    private fun getElementById(obj: SvgObject.SvgContainer, id: String): SvgObject? {
        if (id == obj.id) return obj
        obj.getChildren().forEachElement { child ->
            if (child !is SvgObject.SvgElementBase) {
                return@forEachElement
            }

            if (id == child.id) {
                return child
            }

            if (child is SvgObject.SvgContainer) {
                val found = getElementById(child, id)
                if (found != null) {
                    return found
                }
            }
        }
        return null
    }

    @Suppress("SameParameterValue")
    private fun getElementsByTagName(nodeName: String): MutableList<SvgObject> {
        val result = ArrayList<SvgObject>()
        // Search the object tree for nodes with the give element class
        getElementsByTagName(result, requireRootElement(), nodeName)
        return result
    }

    private fun getElementsByTagName(
        result: MutableList<SvgObject>,
        obj: SvgObject,
        nodeName: String
    ) {
        if (obj.getNodeName() == nodeName) {
            result.add(obj)
        }

        if (obj is SvgObject.SvgContainer) {
            obj.getChildren().forEachElement { child ->
                getElementsByTagName(
                    result = result,
                    obj = child,
                    nodeName = nodeName
                )
            }
        }
    }

    internal companion object {
        //static final String  TAG = "SVGBase";
        private const val DEFAULT_PICTURE_WIDTH = 512
        private const val DEFAULT_PICTURE_HEIGHT = 512

        // Parser configuration singletons
        // Configures the parser that will be used for the next SVG that gets parsed
        private var externalFileResolverSingleton: SVGExternalFileResolver? = null
        private var enableInternalEntitiesSingleton = true

        /**
         * Read and parse an SVG from the given `InputStream`.
         * 
         * @param inputStream the input stream from which to read the file.
         * @return an SVG instance on which you can call one of the render methods.
         * @throws SVGParseException if there is an error parsing the document.
         */
        @JvmStatic
        @Throws(SVGParseException::class)
        internal fun getFromInputStream(inputStream: InputStream): SVGImpl {
            return createParser().parseStream(inputStream)
        }

        /**
         * Read and parse an SVG from the given `String`.
         * 
         * @param svg the String instance containing the SVG document.
         * @return an SVG instance on which you can call one of the render methods.
         * @throws SVGParseException if there is an error parsing the document.
         */
        @JvmStatic
        @Throws(SVGParseException::class)
        internal fun getFromString(svg: String): SVGImpl {
            return createParser().parseStream(ByteArrayInputStream(svg.toByteArray()))
        }

        /**
         * Read and parse an SVG from the given resource location.
         * 
         * @param context the Android context of the resource.
         * @param resourceId the resource identifier of the SVG document.
         * @return an SVG instance on which you can call one of the render methods.
         * @throws SVGParseException if there is an error parsing the document.
         */
        @Suppress("unused")
        @Throws(SVGParseException::class)
        internal fun getFromResource(context: Context, resourceId: Int): SVGImpl {
            return getFromResource(context.resources, resourceId)
        }

        /**
         * Read and parse an SVG from the given resource location.
         * 
         * @param resources the set of Resources in which to locate the file.
         * @param resourceId the resource identifier of the SVG document.
         * @return an SVG instance on which you can call one of the render methods.
         * @throws SVGParseException if there is an error parsing the document.
    
         */
        @JvmStatic
        @Throws(SVGParseException::class)
        internal fun getFromResource(resources: Resources, resourceId: Int): SVGImpl {
            val inputStream = resources.openRawResource(resourceId)
            try {
                return createParser().parseStream(inputStream)
            } finally {
                try {
                    inputStream.close()
                } catch (_: IOException) {
                    // Do nothing
                }
            }
        }

        /**
         * Read and parse an SVG from the assets folder.
         * 
         * @param assetManager the AssetManager instance to use when reading the file.
         * @param filename the filename of the SVG document within assets.
         * @return an SVG instance on which you can call one of the render methods.
         * @throws SVGParseException if there is an error parsing the document.
         * @throws IOException if there is some IO error while reading the file.
         */
        @JvmStatic
        @Throws(SVGParseException::class, IOException::class)
        internal fun getFromAsset(assetManager: AssetManager, filename: String): SVGImpl {
            val inputStream = assetManager.open(filename)
            try {
                return createParser().parseStream(inputStream)
            } finally {
                try {
                    inputStream.close()
                } catch (_: IOException) {
                    // Do nothing
                }
            }
        }

        /**
         * Parse an SVG path definition from the given `String`.
         * 
         * `Path  path = SVG.parsePath("M 0,0 L 100,100"); path.setFillType(Path.FillType.EVEN_ODD); // You could render the path to a Canvas now Paint paint = new Paint(); paint.setStyle(Paint.Style.FILL); paint.setColor(Color.RED); canvas.drawPath(path, paint); // Or perform other operations on it RectF bounds = new RectF(); path.computeBounds(bounds, false); `
         * 
         * Note that this method does not throw any exceptions or return any errors. Per the SVG
         * specification, if there are any errors in the path definition, the valid portion of the
         * path up until the first error is returned.
         * 
         * @param pathDefinition an SVG path element definition string
         * @return an Android `Path`
    
         */
        @JvmStatic
        internal fun parsePath(pathDefinition: String): Path {
            val pathDef = SVGParserImpl.parsePath(pathDefinition)
            val pathConv = PathConverter(pathDef)
            return pathConv.path
        }

        //===============================================================================
        /**
         * Tells the parser whether to allow the expansion of internal entities.
         * An example of a document containing an internal entities is:
         * 
         * `<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.0//EN" "http://www.w3.org/TR/2001/REC-SVG-20010904/DTD/svg10.dtd" [   <!ENTITY hello "Hello World!"> ]> <svg>    <text>&hello;</text> </svg> `
         * 
         * Entities are useful in some circumstances, but SVG files that use them are quite rare.  Note
         * also that enabling entity expansion makes you vulnerable to the
         * [Billion Laughs Attack](https://en.wikipedia.org/wiki/Billion_laughs_attack)
         * 
         * Entity expansion is enabled by default.
         * 
         * @param enable Set true if you want to enable entity expansion by the parser.
    
         */
        @JvmStatic
        internal fun setInternalEntitiesEnabled(enable: Boolean) {
            enableInternalEntitiesSingleton = enable
        }

        /**
         * Register an [SVGExternalFileResolver] instance that the renderer should use when resolving
         * external references such as images, fonts, and CSS stylesheets.
         * 
         * 
         * 
         * *Note: prior to release 1.3, this was an instance method of (@code SVG).  In 1.3, it was
         * changed to a static method so that users can resolve external references to CSSS files while
         * the SVG is being parsed.*
         * 
         * 
         * @param fileResolver the resolver to use.
    
         */
        @JvmStatic
        internal fun registerExternalFileResolver(fileResolver: SVGExternalFileResolver?) {
            externalFileResolverSingleton = fileResolver
        }

        /**
         * De-register the current [SVGExternalFileResolver] instance.
         * 
    
         */
        @JvmStatic
        internal fun deregisterExternalFileResolver() {
            externalFileResolverSingleton = null
        }

        //===============================================================================
        internal fun createParser(): SVGParser {
            return SVGParserImpl()
                .setInternalEntitiesEnabled(enableInternalEntitiesSingleton)
                .setExternalFileResolver(externalFileResolverSingleton)
        }
    }
}
