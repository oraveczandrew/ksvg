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
package hu.oandras.androidsvg

import hu.oandras.androidsvg.css.CSS
import hu.oandras.androidsvg.dom.Box
import hu.oandras.androidsvg.utils.RenderOptionsImpl

/**
 * A fluent builder interface that creates a render configuration object for the
 * [SVG.renderToCanvas] and [SVG.renderToPicture] methods.
 * 
 * <h3>Example usage</h3>
 * 
 * <pre class="code-block">
 * `RenderOption renderOptions = RenderOptions.create(); renderOptions.viewPort(100f, 100f, 400f, 300f)   // Set the area of the Canvas to render the SVG into              .css("rect { fill: red; }")         // Add some CSS that makes all rectangles red svg.renderToCanvas(canvas, renderOptions); `
</pre> * 
 * @since 1.3
 */
public interface RenderOptions {

    public val css: CSS?

    public val viewId: String?

    public val preserveAspectRatio: PreserveAspectRatio?

    public val targetId: String?

    public val viewBox: Box?

    public val viewPort: Box?

    /**
     * Specifies some already parsed CSS that will be applied during render in
     * addition to any specified in the file itself.
     * @param css CSS rules to apply
     * @return this same `RenderOptions` instance
     */
    public fun css(css: CSS): RenderOptions

    /**
     * Specifies some additional CSS rules that will be applied during render in addition to
     * any specified in the file itself. CSS will be parsed during SVG render.
     * @param css CSS rules to apply
     * @return this same `RenderOptions` instance
     */
    public fun css(css: String?, externalFileResolver: SVGExternalFileResolver? = null): RenderOptions

    /**
     * Returns true if this RenderOptions instance has had CSS set with `css()`.
     * @return true if this RenderOptions instance has had CSS set
     */
    public fun hasCss(): Boolean

    /**
     * Specifies how the renderer should handle aspect ratio when rendering the SVG.
     * If not specified, the default will be `PreserveAspectRatio.LETTERBOX`. This is
     * equivalent to the SVG default of `xMidYMid meet`.
     * @param preserveAspectRatio the new aspect ratio value
     * @return this same `RenderOptions` instance
     */
    public fun preserveAspectRatio(preserveAspectRatio: PreserveAspectRatio?): RenderOptions

    /**
     * Returns true if this RenderOptions instance has had a preserveAspectRatio value set with `preserveAspectRatio()`.
     * @return true if this RenderOptions instance has had a preserveAspectRatio value set
     */
    public fun hasPreserveAspectRatio(): Boolean

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
    public fun view(viewId: String?): RenderOptions

    /**
     * Returns true if this RenderOptions instance has had a view set with `view()`.
     * @return true if this RenderOptions instance has had a view set
     */
    public fun hasView(): Boolean

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
    public fun viewBox(
        minX: Float,
        minY: Float,
        width: Float,
        height: Float
    ): RenderOptions

    /**
     * Returns true if this RenderOptions instance has had a viewBox set with `viewBox()`.
     * @return true if this RenderOptions instance has had a viewBox set
     */
    public fun hasViewBox(): Boolean

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
    public fun viewPort(
        minX: Float,
        minY: Float,
        width: Float,
        height: Float
    ): RenderOptions

    /**
     * Returns true if this RenderOptions instance has had a viewPort set with `viewPort()`.
     * @return true if this RenderOptions instance has had a viewPort set
     */
    public fun hasViewPort(): Boolean

    /**
     * Specifies the `id` of an element, in the SVG, to treat as the target element when
     * using the `:target` CSS pseudo class.
     * 
     * @param targetId the id attribute of an element
     * @return this same `RenderOptions` instance
     */
    public fun target(targetId: String?): RenderOptions

    /**
     * Returns true if this RenderOptions instance has had a target set with `target()`.
     * @return true if this RenderOptions instance has had a target set
     */
    public fun hasTarget(): Boolean

    public companion object {
        /**
         * Create a new `RenderOptions` instance.
         * @return new instance of this class.
         */
        @JvmStatic
        public fun create(): RenderOptions {
            return RenderOptionsImpl()
        }
    }
}
