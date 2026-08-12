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
package hu.oandras.ksvg.utils

import hu.oandras.ksvg.css.CSS
import hu.oandras.ksvg.PreserveAspectRatio
import hu.oandras.ksvg.RenderOptions
import hu.oandras.ksvg.SVGExternalFileResolver
import hu.oandras.ksvg.css.CSSParser
import hu.oandras.ksvg.dom.Box

/**
 * Internal implementation of the [RenderOptions] interface.
 * 
 * @since 1.3
 */
internal class RenderOptionsImpl internal constructor(
    private var _css: CSS?,
    private var _preserveAspectRatio: PreserveAspectRatio?,
    private var _targetId: String?,
    private var _viewBox: Box?,
    private var _viewId: String?,
    private var _viewPort: Box?,
) : RenderOptions {

    override val css: CSS?
        get() = _css

    override val viewId: String?
        get() = _viewId

    override val viewBox: Box?
        get() = _viewBox

    override val viewPort: Box?
        get() = _viewPort

    override val preserveAspectRatio: PreserveAspectRatio?
        get() = _preserveAspectRatio

    override val targetId: String?
        get() = _targetId

    /**
     * Create a new `RenderOptions` instance.
     */
    internal constructor(): this(
        _css = null,
        _preserveAspectRatio = null,
        _targetId = null,
        _viewBox = null,
        _viewId = null,
        _viewPort = null,
    )

    /**
     * Creates a copy of the given `RenderOptions` object.
     * @param other the object to copy
     */
    internal constructor(other: RenderOptions): this(
        _css = other.css,
        _preserveAspectRatio = other.preserveAspectRatio,
        _viewBox = other.viewBox,
        _viewId = other.viewId,
        _viewPort = other.viewPort,
        _targetId = other.targetId,
    )

    /**
     * Specifies some already parsed CSS that will be applied during render in
     * addition to any specified in the file itself.
     * @param css CSS rules to apply
     * @return this same `RenderOptions` instance
     */
    override fun css(css: CSS): RenderOptions {
        _css = css
        return this
    }

    override fun css(css: String?, externalFileResolver: SVGExternalFileResolver?): RenderOptions {
        _css = if (css.isNullOrBlank()) {
            null
        } else {
            val parser = CSSParser(
                source = CSSParser.Source.RenderOptions,
                externalFileResolver = externalFileResolver
            )
            CSS(parser.parse(css))
        }
        return this
    }

    /**
     * Returns true if this RenderOptions instance has had CSS set with `css()`.
     * @return true if this RenderOptions instance has had CSS set
     */
    override fun hasCss(): Boolean {
        return _css != null
    }

    /**
     * Specifies how the renderer should handle aspect ratio when rendering the SVG.
     * If not specified, the default will be `PreserveAspectRatio.LETTERBOX`. This is
     * equivalent to the SVG default of `xMidYMid meet`.
     * @param preserveAspectRatio the new aspect ratio value
     * @return this same `RenderOptions` instance
     */
    override fun preserveAspectRatio(preserveAspectRatio: PreserveAspectRatio?): RenderOptions {
        this._preserveAspectRatio = preserveAspectRatio
        return this
    }


    /**
     * Returns true if this RenderOptions instance has had a preserveAspectRatio value set with `preserveAspectRatio()`.
     * @return true if this RenderOptions instance has had a preserveAspectRatio value set
     */
    override fun hasPreserveAspectRatio(): Boolean {
        return this._preserveAspectRatio != null
    }

    /**
     * Specifies the `id` of a `<view>` element in the SVG.  A `<view>`
     * element is a way to specify a predetermined view of the document, that differs from the default view.
     * For example, it can allow you to focus in on a small detail of the document.
     * 
     * Note: setting this option will override any [.viewBox] or [.preserveAspectRatio] settings.
     * 
     * @param viewId the id attribute of the view that should be used for rendering
     * @return this same `RenderOptions` instance
     */
    override fun view(viewId: String?): RenderOptions {
        this._viewId = viewId
        return this
    }


    /**
     * Returns true if this RenderOptions instance has had a view set with `view()`.
     * @return true if this RenderOptions instance has had a view set
     */
    override fun hasView(): Boolean {
        return this._viewId != null
    }


    /**
     * Specifies alternative values to use for the root element `viewBox`. Any existing `viewBox`
     * attribute value will be ignored.
     * 
     * Note: will be overridden if a [.view] is set.
     * 
     * @param minX The left X coordinate of the viewBox
     * @param minY The top Y coordinate of the viewBox
     * @param width The width of the viewBox
     * @param height The height of the viewBox
     * @return this same `RenderOptions` instance
     */
    override fun viewBox(minX: Float, minY: Float, width: Float, height: Float): RenderOptions {
        this._viewBox = Box(minX, minY, width, height)
        return this
    }


    /**
     * Returns true if this RenderOptions instance has had a viewBox set with `viewBox()`.
     * @return true if this RenderOptions instance has had a viewBox set
     */
    override fun hasViewBox(): Boolean {
        return this._viewBox != null
    }


    /**
     * Describes the viewport into which the SVG should be rendered.  If this is not specified,
     * then the whole of the canvas will be used as the viewport.  If rendering to a `Picture`
     * then a default viewport width and height will be used.
     * 
     * @param minX The left X coordinate of the viewport
     * @param minY The top Y coordinate of the viewport
     * @param width The width of the viewport
     * @param height The height of the viewport
     * @return this same `RenderOptions` instance
     */
    override fun viewPort(minX: Float, minY: Float, width: Float, height: Float): RenderOptions {
        this._viewPort = Box(minX, minY, width, height)
        return this
    }


    /**
     * Returns true if this RenderOptions instance has had a viewPort set with `viewPort()`.
     * @return true if this RenderOptions instance has had a viewPort set
     */
    override fun hasViewPort(): Boolean {
        return this._viewPort != null
    }


    /**
     * Specifies the `id` of an element, in the SVG, to treat as the target element when
     * using the `:target` CSS pseudo class.
     * 
     * @param targetId the id attribute of an element
     * @return this same `RenderOptions` instance
     */
    override fun target(targetId: String?): RenderOptions {
        _targetId = targetId
        return this
    }


    /**
     * Returns true if this RenderOptions instance has had a target set with `target()`.
     * @return true if this RenderOptions instance has had a target set
     */
    override fun hasTarget(): Boolean {
        return _targetId != null
    }


    internal companion object {
        /**
         * Create a new `RenderOptions` instance.
         * @return new instance of this class.
         */
        internal fun create(): RenderOptionsImpl {
            return RenderOptionsImpl()
        }
    }
}
