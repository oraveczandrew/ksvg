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
import android.content.res.AssetManager
import android.content.res.Resources
import android.graphics.Canvas
import android.graphics.Matrix
import android.graphics.Path
import android.graphics.RectF
import androidx.collection.ArrayMap
import androidx.collection.ArraySet
import hu.oandras.ksvg.AndroidLoggerContext
import hu.oandras.ksvg.ExternalFileResolver
import hu.oandras.ksvg.HitRegion
import hu.oandras.ksvg.KSVGAnimatedDrawable
import hu.oandras.ksvg.KSVGDrawable
import hu.oandras.ksvg.KSVGParseException
import hu.oandras.ksvg.LoggerContext
import hu.oandras.ksvg.OnSvgClickListener
import hu.oandras.ksvg.PreserveAspectRatio
import hu.oandras.ksvg.RenderOptions
import hu.oandras.ksvg.SVG
import hu.oandras.ksvg.css.CSSLength
import hu.oandras.ksvg.css.CSSRule
import hu.oandras.ksvg.css.CSSRuleset
import hu.oandras.ksvg.css.CssUnit
import hu.oandras.ksvg.css.Source
import hu.oandras.ksvg.dom.core.Box
import hu.oandras.ksvg.dom.core.Container
import hu.oandras.ksvg.dom.core.ElementBase
import hu.oandras.ksvg.dom.core.Svg
import hu.oandras.ksvg.dom.core.SvgObject
import hu.oandras.ksvg.dom.core.View
import hu.oandras.ksvg.logW
import hu.oandras.ksvg.parser.SVGParser
import hu.oandras.ksvg.parser.SVGParserImpl
import hu.oandras.ksvg.parser.parseLength
import hu.oandras.ksvg.render.PathConverter
import hu.oandras.ksvg.render.RenderNode
import hu.oandras.ksvg.render.RenderOptionsImpl
import hu.oandras.ksvg.render.RenderScene
import hu.oandras.ksvg.render.Renderer
import hu.oandras.ksvg.render.collectHitRegions
import hu.oandras.ksvg.render.inverseRootMapping
import hu.oandras.ksvg.render.pool.PoolOwner
import hu.oandras.ksvg.utils.forEachElement
import java.io.ByteArrayInputStream
import java.io.IOException
import java.io.InputStream
import kotlin.jvm.Volatile

internal const val COLOR_WHITE: Int = 0xFFFFFFFF.toInt()
internal const val COLOR_TRANSPARENT: Int = 0
internal const val COLOR_BLACK: Int = -0x1000000

/**
 * KSVG is a library for reading, parsing and rendering SVG documents on Android devices.
 *
 * All interaction with KSVG is via this class.
 *
 * Typically, you will call one of the SVG loading and parsing classes then call the renderer,
 * passing it a canvas to draw upon.
 *
 * <h3>Usage summary</h3>
 *
 *  * Use one of the static `getFromX()` methods to read and parse the SVG file.  They will
 * return an instance of this class.
 *  * Call one of the `renderToX()` methods to render the document.
 */
@OptIn(ExperimentalStdlibApi::class)
internal class SVGImpl internal constructor(
    /**
     * Indicates whether internal entities were enabled when this SVG was parsed.

     */
    override val isInternalEntitiesEnabled: Boolean,
    /**
     * The [ExternalFileResolver] in effect when this SVG was parsed.
     * 

     */
    // The parser configuration settings that was used for the current instance
    // Will continue to be used for future parsing by this instance. For example
    // when parsing addition CSS.
    override val externalFileResolver: ExternalFileResolver?,
    /**
     * The [LoggerContext] used for parser and renderer logging for this document.
     */
    loggerContext: LoggerContext = AndroidLoggerContext
) : SVG, LoggerContext by loggerContext {
    @JvmField
    internal var animationsEnabled: Boolean = false

    // Click listener support (lazily computed on hitTest)
    private var onSvgClickListener: OnSvgClickListener? = null
    private var hitRegions: List<HitRegion>? = null
    private var screenToSvgTransform: Matrix? = null
    private var hitRegionsDirty: Boolean = true
    private var lastRenderNode: RenderNode<*>? = null
    private var lastRenderViewPort: RectF? = null

    override fun setOnSvgClickListener(listener: OnSvgClickListener?) {
        onSvgClickListener = listener
    }

    override fun getHitRegions(): List<HitRegion> {
        ensureHitRegions()
        return hitRegions ?: emptyList()
    }

    override fun hitTest(x: Float, y: Float): String? {
        ensureHitRegions()
        val transform = screenToSvgTransform ?: return null

        // Convert screen coordinates to SVG user-space coordinates
        val pts = floatArrayOf(x, y)
        transform.mapPoints(pts)
        val svgX = pts[0]
        val svgY = pts[1]

        // Test in reverse order (last drawn = topmost)
        val regions = hitRegions ?: return null
        for (i in regions.indices.reversed()) {
            if (regions[i].bounds.contains(svgX, svgY)) {
                return regions[i].href
            }
        }
        return null
    }

    private fun ensureHitRegions() {
        if (!hitRegionsDirty) return
        hitRegionsDirty = false

        val node = lastRenderNode
        val viewport = lastRenderViewPort
        if (node == null || viewport == null) {
            hitRegions = emptyList()
            screenToSvgTransform = null
            return
        }

        val regions = mutableListOf<HitRegion>()
        collectHitRegions(node, regions)

        screenToSvgTransform = inverseRootMapping(node) ?: run {
            val identity = Matrix()
            identity.setTranslate(-viewport.left, -viewport.top)
            identity
        }

        hitRegions = regions
    }

    /**
     * Dispatches a click event to the listener if an <a> element was hit.
     * Returns true if the event was consumed.
     */
    internal fun dispatchClick(x: Float, y: Float): Boolean {
        val listener = onSvgClickListener ?: return false
        val href = hitTest(x, y) ?: return false
        return listener.onLinkClicked(href)
    }

    //===============================================================================
    // The root svg element
    @JvmField
    internal var rootElement: Svg? = null

    internal fun requireRootElement(): Svg {
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
        set(value) {
            if (field != value) {
                field = value
                notifyModification()
            }
        }

    // CSS rules
    private val cssRules = CSSRuleset()

    @JvmField
    internal var animationTimeMs: Long = 0L

    internal var modificationCount: Int = 0
        private set

    internal fun notifyModification() {
        modificationCount++
    }

    private val iriToElementCache: ArrayMap<String, SvgObject> = ArrayMap()
    private val idToElementCache: ArrayMap<String, SvgObject> = ArrayMap()

    override fun toDrawable(): KSVGDrawable {
        return toDrawable(renderOptions = null)
    }

    override fun toDrawable(renderOptions: RenderOptions?): KSVGDrawable {
        return KSVGDrawable(this, renderOptions)
    }

    override fun toAnimatedDrawable(): KSVGAnimatedDrawable {
        return toAnimatedDrawable(renderOptions = null)
    }

    override fun toAnimatedDrawable(renderOptions: RenderOptions?): KSVGAnimatedDrawable {
        return KSVGAnimatedDrawable(this, renderOptions)
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

        renderToCanvas(canvas, renderOptions)
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

        val pools = PoolOwner()

        val options = renderOptions as? RenderOptionsImpl ?: RenderOptionsImpl(renderOptions)
        val scene = RenderScene.build(
            document = this,
            dPI = renderDPI,
            externalFileResolver = externalFileResolver,
            pools = pools,
            options = options,
            modificationCount = modificationCount,
            optionsFingerprint = RenderScene.computeOptionsFingerprint(options),
        )
        val node = scene.rootNode ?: return
        val vp = options.viewPort
        if (vp != null) {
            val bounds = android.graphics.Rect(
                vp.minX.toInt(), vp.minY.toInt(),
                (vp.minX + vp.width).toInt(), (vp.minY + vp.height).toInt()
            )
            scene.applyViewport(bounds, options, pools)
        }

        val renderer = Renderer(
            document = this,
            dPI = renderDPI,
            pools = pools,
            gpuBackendFactory = options.gpuBackendFactory,
        )

        renderer.renderDocument(canvas, node, renderOptions)

        // Store render state for lazy hit region computation
        lastRenderNode = node
        lastRenderViewPort = renderOptions.viewPort?.toRectF()
        hitRegionsDirty = true
    }

    /**
     * Renders this SVG document to a Canvas using the specified view defined in the document.
     * 
     * 
     * A View is a special element in an SVG documents that describes a rectangular area in the document.
     * Calling this method with a `viewId` will result in the specified view being positioned and scaled
     * to the viewport.  In other words, use [renderToCanvas] to render the whole document, or use this
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
     * to the viewport.  In other words, use [renderToCanvas] to render the whole document, or use this
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
            val viewElems = getElementsByTagName(View.NODE_NAME)

            return viewElems.mapNotNullTo(ArraySet(viewElems.size)) { elem ->
                (elem as View).id.also {
                    if (it == null) {
                        logW("KSVG") { "getViewList(): found a <view> without an id attribute" }
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
            rootElement = requireRootElement().copy(width = CSSLength(pixels))
            notifyModification()
        }

    /**
     * Change the width of the document by altering the "width" attribute
     * of the root `<svg>` element.
     * 
     * @param value A valid SVG 'length' attribute, such as "100px" or "10cm".
     * @throws KSVGParseException if `value` cannot be parsed successfully.
     * @throws IllegalArgumentException if there is no current SVG document loaded.
     */
    override fun setDocumentWidth(value: String) {
        rootElement = requireRootElement().copy(width = parseLength(value))
        notifyModification()
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
            rootElement = requireRootElement().copy(height = CSSLength(pixels))
            notifyModification()
        }

    /**
     * Change the height of the document by altering the "height" attribute
     * of the root `<svg>` element.
     * 
     * @param value A valid SVG 'length' attribute, such as "100px" or "10cm".
     * @throws KSVGParseException if `value` cannot be parsed successfully.
     * @throws IllegalArgumentException if there is no current SVG document loaded.
     */
    override fun setDocumentHeight(value: String) {
        rootElement = requireRootElement().copy(height = parseLength(value))
        notifyModification()
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
        rootElement = requireRootElement().copy(viewBox = Box(minX, minY, width, height))
        notifyModification()
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
            rootElement = requireRootElement().copy(preserveAspectRatio = preserveAspectRatio)
            notifyModification()
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

        return iriToElementCache.getOrPut(iri) {
            iri = cssQuotedString(iri)
            if (iri.length > 1 && iri.startsWith('#')) {
                getElementById(iri.substring(1))
            } else {
                null
            }
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

    private var cachedDocumentDimensions: Box? = null
    private var cachedDocumentDimensionsMod: Int = -1

    private fun getDocumentDimensions(dpi: Float): Box {
        val cached = cachedDocumentDimensions
        if (cachedDocumentDimensionsMod == modificationCount && cached != null) {
            return cached
        }
        val result = computeDocumentDimensions(dpi)
        cachedDocumentDimensions = result
        cachedDocumentDimensionsMod = modificationCount
        return result
    }

    private fun computeDocumentDimensions(dpi: Float): Box {
        val rootElement = requireRootElement()
        val w = rootElement.width
        val h = rootElement.height

        val viewBox = rootElement.viewBox

        if (w == null || w.isZero || w.unit == CssUnit.percent || w.unit == CssUnit.em || w.unit == CssUnit.ex) {
            if (viewBox != null) return viewBox

            // If width/height are missing or percentage, fall back to the bounding box if available
            rootElement.boundingBox?.let { return it }

            return Box.UNRESOLVED
        }

        val wOut = w.floatValue(dpi)
        val hOut: Float

        if (h != null) {
            if (h.isZero || h.unit == CssUnit.percent || h.unit == CssUnit.em || h.unit == CssUnit.ex) {
                return Box.UNRESOLVED
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
    internal fun addCSSRules(ruleset: CSSRuleset) {
        cssRules.addAll(ruleset)
        notifyModification()
    }

    internal val cSSRules: List<CSSRule>
        get() = cssRules.rules

    fun clearRenderCSSRules() {
        cssRules.removeFromSource(Source.RenderOptions)
        notifyModification()
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
            idToElementCache.getOrPutIfMissing(id) {
                // Search the object tree for a node with id property that matches 'id'
                getElementById(rootElement, id)
            }
        }
    }

    private fun getElementById(obj: Container, id: String): SvgObject? {
        if (id == obj.id) return obj
        obj.getChildren().forEachElement { child ->
            if (child !is ElementBase) {
                return@forEachElement
            }

            if (id == child.id) {
                return child
            }

            if (child is Container) {
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

        if (obj is Container) {
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

        /**
         * Read and parse an SVG from the given `InputStream`.
         * 
         * @param inputStream the input stream from which to read the file.
         * @param parseAnimations set true if you want to enable animation parsing by the parser.
         * @return an SVG instance on which you can call one of the render methods.
         * @throws KSVGParseException if there is an error parsing the document.
         */
        @Throws(KSVGParseException::class)
        fun getFromInputStream(
            inputStream: InputStream,
            parseAnimations: Boolean = false,
            logger: LoggerContext,
            externalFileResolver: ExternalFileResolver? = null,
            enableInternalEntities: Boolean = true,
        ): SVGImpl {
            return createParser(parseAnimations, logger, externalFileResolver, enableInternalEntities)
                .parseStream(inputStream)
        }

        /**
         * Read and parse an SVG from the given `String`.
         * 
         * @param svg the String instance containing the SVG document.
         * @param parseAnimations set true if you want to enable animation parsing by the parser.
         * @return an SVG instance on which you can call one of the render methods.
         * @throws KSVGParseException if there is an error parsing the document.
         */
        @Throws(KSVGParseException::class)
        fun getFromString(
            svg: String,
            parseAnimations: Boolean = false,
            logger: LoggerContext,
            externalFileResolver: ExternalFileResolver? = null,
            enableInternalEntities: Boolean = true,
        ): SVGImpl {
            return createParser(parseAnimations, logger, externalFileResolver, enableInternalEntities)
                .parseStream(ByteArrayInputStream(svg.toByteArray()))
        }

        /**
         * Read and parse an SVG from the given resource location.
         * 
         * @param resources the set of Resources in which to locate the file.
         * @param resourceId the resource identifier of the SVG document.
         * @param parseAnimations set true if you want to enable animation parsing by the parser.
         * @return an SVG instance on which you can call one of the render methods.
         * @throws KSVGParseException if there is an error parsing the document.
     
         */
        @Throws(KSVGParseException::class)
        fun getFromResource(
            resources: Resources,
            resourceId: Int,
            parseAnimations: Boolean = false,
            logger: LoggerContext,
            externalFileResolver: ExternalFileResolver? = null,
            enableInternalEntities: Boolean = true,
        ): SVGImpl {
            val inputStream = resources.openRawResource(resourceId)
            try {
                return createParser(parseAnimations, logger, externalFileResolver, enableInternalEntities)
                    .parseStream(inputStream)
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
         * @param parseAnimations set true if you want to enable animation parsing by the parser.
         * @return an SVG instance on which you can call one of the render methods.
         * @throws KSVGParseException if there is an error parsing the document.
         * @throws IOException if there is some IO error while reading the file.
         */
        @Throws(KSVGParseException::class, IOException::class)
        fun getFromAsset(
            assetManager: AssetManager,
            filename: String,
            parseAnimations: Boolean = false,
            logger: LoggerContext,
            externalFileResolver: ExternalFileResolver? = null,
            enableInternalEntities: Boolean = true,
        ): SVGImpl {
            val inputStream = assetManager.open(filename)
            try {
                return createParser(parseAnimations, logger, externalFileResolver, enableInternalEntities)
                    .parseStream(inputStream)
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
          * Note that this method does not throw any exceptions or return any errors. Per the SVG
          * specification, if there are any errors in the path definition, the valid portion of the
          * path up until the first error is returned.
          *
          * @param pathDefinition an SVG path element definition string
          * @return an Android `Path`
          */
        fun parsePath(pathDefinition: String, logger: LoggerContext): Path {
            val pathDef = with(logger) {
                hu.oandras.ksvg.parser.parsePath(pathDefinition)
            }
            val pathConv = PathConverter(pathDef)
            return pathConv.path
        }

        private fun createParser(
            parseAnimations: Boolean,
            logger: LoggerContext,
            externalFileResolver: ExternalFileResolver?,
            enableInternalEntities: Boolean,
        ): SVGParser {
            return SVGParserImpl(
                enableInternalEntities = enableInternalEntities,
                externalFileResolver = externalFileResolver,
                animationsEnabled = parseAnimations,
                logger = logger,
            )
        }
    }
}
