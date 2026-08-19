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
package hu.oandras.ksvg

import android.content.Context
import android.content.res.AssetManager
import android.content.res.Resources
import android.graphics.Canvas
import android.graphics.Path
import android.graphics.RectF
import android.graphics.drawable.Drawable
import hu.oandras.ksvg.dom.SVGImpl
import hu.oandras.ksvg.render.PathConverter
import java.io.IOException
import java.io.InputStream

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
public interface SVG {
    /**
     * Indicates whether internal entities were enabled when this SVG was parsed.

     */
    public val isInternalEntitiesEnabled: Boolean


    /**
     * The [ExternalFileResolver] in effect when this SVG was parsed.
     * 

     */
    public val externalFileResolver: ExternalFileResolver?


    /**
     * The DPI (dots-per-inch) value to use when rendering.
     * 
     * The DPI setting is used in the conversion of "physical" units - such a "pt" or "cm" - to pixel values.
     * The default DPI is 96.
     * 
     * You should not normally need to alter the DPI from the default of 96 as recommended by the SVG
     * and CSS specifications.
     */
    public var renderDPI: Float

    /**
     * Returns this SVG document as a [Drawable].
     *
     * The returned drawable renders the SVG into its current bounds when drawn. If no bounds have
     * been assigned, the drawable uses the document's intrinsic dimensions where available.
     */
    public fun toDrawable(): KSVGDrawable

    /**
     * Returns this SVG document as a [Drawable].
     *
     * @param renderOptions options that describe how to render this SVG.
     */
    public fun toDrawable(renderOptions: RenderOptions?): KSVGDrawable

    /**
     * Returns this SVG document as an animatable [Drawable].
     *
     * This currently uses the same rendering path as [toDrawable], but exposes Android's animation
     * lifecycle so SVG animation support can be driven by the drawable API.
     */
    public fun toAnimatedDrawable(): KSVGAnimatedDrawable

    /**
     * Returns this SVG document as an animatable [Drawable].
     *
     * @param renderOptions options that describe how to render this SVG.
     */
    public fun toAnimatedDrawable(renderOptions: RenderOptions?): KSVGAnimatedDrawable


    //===============================================================================
    // SVG document rendering to a canvas object (direct rendering)
    /**
     * Renders this SVG document to a Canvas object.  The full width and height of the canvas
     * will be used as the viewport into which the document will be rendered.
     * 
     * @param canvas the canvas to which the document should be rendered.

     */
    public fun renderToCanvas(canvas: Canvas)


    /**
     * Renders this SVG document to a Canvas object.
     * 
     * @param canvas the canvas to which the document should be rendered.
     * @param viewPort the bounds of the area on the canvas you want the SVG rendered, or null for the whole canvas.
     */
    public fun renderToCanvas(canvas: Canvas, viewPort: RectF?)


    /**
     * Renders this SVG document to a Canvas object.
     * 
     * @param canvas the canvas to which the document should be rendered.
     * @param renderOptions options that describe how to render this SVG on the Canvas.

     */
    public fun renderToCanvas(canvas: Canvas, renderOptions: RenderOptions?)


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
    public fun renderViewToCanvas(viewId: String?, canvas: Canvas)


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
    public fun renderViewToCanvas(viewId: String?, canvas: Canvas, viewPort: RectF?)


    /**
     * Sets a listener for click events on `<a>` elements in the SVG document.
     *
     * Must be called after [renderToCanvas] so that hit regions are available.
     *
     * @param listener the listener to invoke when an `<a>` element is clicked, or `null` to remove.
     */
    public fun setOnSvgClickListener(listener: OnSvgClickListener?)


    /**
     * Returns the list of clickable regions in the most recently rendered SVG.
     *
     * Each region corresponds to an `<a>` element and contains its `href` and
     * bounding rectangle in screen (canvas) coordinates. An empty list is returned
     * if no `<a>` elements exist or if no rendering has been performed yet.
     */
    public fun getHitRegions(): List<HitRegion>


    /**
     * Performs a hit-test at the given screen coordinates and returns the `href`
     * of the topmost `<a>` element that contains the point, or `null` if none.
     *
     * @param x the x coordinate in canvas/screen space.
     * @param y the y coordinate in canvas/screen space.
     * @return the `href` attribute value of the hit `<a>` element, or `null`.
     */
    public fun hitTest(x: Float, y: Float): String?


    /**
     * The contents of the `<title>` element in the SVG document.
     * 
     * @throws IllegalArgumentException if there is no current SVG document loaded.
     */
    public val documentTitle: String?


    /**
     * The contents of the `<desc>` element in the SVG document.
     * 
     * @throws IllegalArgumentException if there is no current SVG document loaded.
     */
    public val documentDescription: String?


    /**
     * The SVG version number as provided in the root `<svg>` tag of the document.
     * 
     * @throws IllegalArgumentException if there is no current SVG document loaded.
     */
    public val documentSVGVersion: String?


    /**
     * A list of ids for all `<view>` elements in this SVG document.
     * 
     * The returned view ids could be used when calling and of the `renderViewToX()` methods.
     * 
     * @throws IllegalArgumentException if there is no current SVG document loaded.
     */
    public val viewList: MutableSet<String>


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
    public var documentWidth: Float


    /**
     * Change the width of the document by altering the "width" attribute
     * of the root `<svg>` element.
     * 
     * @param value A valid SVG 'length' attribute, such as "100px" or "10cm".
     * @throws KSVGParseException if `value` cannot be parsed successfully.
     * @throws IllegalArgumentException if there is no current SVG document loaded.
     */
    @Throws(KSVGParseException::class)
    public fun setDocumentWidth(value: String)

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
    public var documentHeight: Float


    /**
     * Change the height of the document by altering the "height" attribute
     * of the root `<svg>` element.
     * 
     * @param value A valid SVG 'length' attribute, such as "100px" or "10cm".
     * @throws KSVGParseException if `value` cannot be parsed successfully.
     * @throws IllegalArgumentException if there is no current SVG document loaded.
     */
    @Throws(KSVGParseException::class)
    public fun setDocumentHeight(value: String)


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
    public fun setDocumentViewBox(minX: Float, minY: Float, width: Float, height: Float)


    /**
     * The viewBox attribute of the current SVG document.
     * 
     * @throws IllegalArgumentException if there is no current SVG document loaded.
     */
    public val documentViewBox: RectF?


    /**
     * The "preserveAspectRatio" attribute of the root `<svg>` element.
     * 
     * Positioning works according to the documentation for [PreserveAspectRatio].
     * 
     * @throws IllegalArgumentException if there is no current SVG document loaded.
     */
    public var documentPreserveAspectRatio: PreserveAspectRatio?


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
    public val documentAspectRatio: Float


    // Removed rootElement from interface to avoid 'internal' modifier issues

    public companion object {
        /**
         * Returns the version number of this library.
         * 
         * @return the version number in string format
         */
        //static final String  TAG = "SVG";
        public const val VERSION: String = "1.0"

        /**
         * Read and parse an SVG from the given `InputStream`.
         * 
         * @param inputStream the input stream from which to read the file.
         * @param parseAnimations set true if you want to enable animation parsing by the parser.
         * @return an SVG instance on which you can call one of the render methods.
         * @throws KSVGParseException if there is an error parsing the document.
         */
        @JvmStatic
        @JvmOverloads
        @Throws(KSVGParseException::class)
        public fun getFromInputStream(
            inputStream: InputStream,
            parseAnimations: Boolean = false
        ): SVG {
            return SVGImpl.getFromInputStream(inputStream, parseAnimations)
        }


        /**
         * Read and parse an SVG from the given `String`.
         * 
         * @param svg the String instance containing the SVG document.
         * @param parseAnimations set true if you want to enable animation parsing by the parser.
         * @return an SVG instance on which you can call one of the render methods.
         * @throws KSVGParseException if there is an error parsing the document.
         */
        @JvmStatic
        @JvmOverloads
        @Throws(KSVGParseException::class)
        public fun getFromString(
            svg: String,
            parseAnimations: Boolean = false
        ): SVG {
            return SVGImpl.getFromString(svg, parseAnimations)
        }


        /**
         * Read and parse an SVG from the given resource location.
         * 
         * @param context the Android context of the resource.
         * @param resourceId the resource identifier of the SVG document.
         * @param parseAnimations set true if you want to enable animation parsing by the parser.
         * @return an SVG instance on which you can call one of the render methods.
         * @throws KSVGParseException if there is an error parsing the document.
         */
        @JvmStatic
        @JvmOverloads
        @Throws(KSVGParseException::class)
        public fun getFromResource(
            context: Context,
            resourceId: Int,
            parseAnimations: Boolean = false
        ): SVG {
            return getFromResource(context.resources, resourceId, parseAnimations)
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
        @JvmStatic
        @JvmOverloads
        @Throws(KSVGParseException::class)
        public fun getFromResource(
            resources: Resources,
            resourceId: Int,
            parseAnimations: Boolean = false
        ): SVG {
            return SVGImpl.getFromResource(resources, resourceId, parseAnimations)
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
        @JvmStatic
        @JvmOverloads
        @Throws(KSVGParseException::class, IOException::class)
        public fun getFromAsset(
            assetManager: AssetManager,
            filename: String,
            parseAnimations: Boolean = false
        ): SVG {
            return SVGImpl.getFromAsset(assetManager, filename, parseAnimations)
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
        @JvmStatic
        public fun parsePath(pathDefinition: String): Path {
            val pathDef = hu.oandras.ksvg.parser.parsePath(pathDefinition)
            val pathConv = PathConverter(pathDef)
            return pathConv.path
        }


        //===============================================================================
         /**
          * Tells the parser whether to allow the expansion of internal entities.
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
        public fun setInternalEntitiesEnabled(enable: Boolean) {
            SVGImpl.setInternalEntitiesEnabled(enable)
        }

        /**
         * Register an [ExternalFileResolver] instance that the renderer should use when resolving
         * external references such as images, fonts, and CSS stylesheets.
         *
         * @param fileResolver the resolver to use.
    
         */
        @JvmStatic
        public fun registerExternalFileResolver(fileResolver: ExternalFileResolver?) {
            SVGImpl.registerExternalFileResolver(fileResolver)
        }


        /**
         * De-register the current [ExternalFileResolver] instance.
         * 
    
         */
        @JvmStatic
        public fun deregisterExternalFileResolver() {
            SVGImpl.deregisterExternalFileResolver()
        }

        //===============================================================================
        // Other document utility API functions
    }
}
