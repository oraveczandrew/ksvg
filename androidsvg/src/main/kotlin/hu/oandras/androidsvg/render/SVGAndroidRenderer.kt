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
@file:Suppress("UsePropertyAccessSyntax")

package hu.oandras.androidsvg.render

import android.annotation.SuppressLint
import android.graphics.Bitmap
import android.graphics.BlendMode
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.ColorMatrix
import android.graphics.ColorMatrixColorFilter
import android.graphics.DashPathEffect
import android.graphics.LinearGradient
import android.graphics.Matrix
import android.graphics.Paint
import android.graphics.Path
import android.graphics.Path.FillType
import android.graphics.PathMeasure
import android.graphics.PorterDuff
import android.graphics.PorterDuffXfermode
import android.graphics.RadialGradient
import android.graphics.Rect
import android.graphics.RectF
import android.graphics.Shader.TileMode
import android.graphics.Typeface
import android.os.Build
import android.util.Log
import androidx.annotation.ColorInt
import androidx.annotation.RequiresApi
import androidx.collection.ArrayMap
import hu.oandras.androidsvg.BuildConfig
import hu.oandras.androidsvg.PreserveAspectRatio
import hu.oandras.androidsvg.RenderOptions
import hu.oandras.androidsvg.SVGExternalFileResolver
import hu.oandras.androidsvg.css.CSSFontFeatureSettings
import hu.oandras.androidsvg.css.CSSFontVariationSettings
import hu.oandras.androidsvg.css.CSSLength
import hu.oandras.androidsvg.css.CSSParser
import hu.oandras.androidsvg.css.CSSParser.RuleMatchContext
import hu.oandras.androidsvg.dom.Box
import hu.oandras.androidsvg.dom.Box.Companion.fromLimits
import hu.oandras.androidsvg.dom.COLOR_BLACK
import hu.oandras.androidsvg.dom.ColorValue
import hu.oandras.androidsvg.dom.CurrentColor
import hu.oandras.androidsvg.dom.HasTransform
import hu.oandras.androidsvg.dom.NotDirectlyRendered
import hu.oandras.androidsvg.dom.PaintReference
import hu.oandras.androidsvg.dom.PathDefinition
import hu.oandras.androidsvg.dom.PathInterface
import hu.oandras.androidsvg.dom.SVGImpl
import hu.oandras.androidsvg.dom.Style
import hu.oandras.androidsvg.dom.Style.CSSBlendMode
import hu.oandras.androidsvg.dom.Style.FillRule
import hu.oandras.androidsvg.dom.Style.FontStyle
import hu.oandras.androidsvg.dom.Style.Isolation
import hu.oandras.androidsvg.dom.Style.LineCap
import hu.oandras.androidsvg.dom.Style.LineJoin
import hu.oandras.androidsvg.dom.Style.MaskType
import hu.oandras.androidsvg.dom.Style.RenderQuality
import hu.oandras.androidsvg.dom.Style.TextAnchor
import hu.oandras.androidsvg.dom.Style.TextDecoration
import hu.oandras.androidsvg.dom.Style.TextDirection
import hu.oandras.androidsvg.dom.Style.VectorEffect
import hu.oandras.androidsvg.dom.SvgObject
import hu.oandras.androidsvg.dom.SvgObject.Circle
import hu.oandras.androidsvg.dom.SvgObject.ClipPath
import hu.oandras.androidsvg.dom.SvgObject.Ellipse
import hu.oandras.androidsvg.dom.SvgObject.FeBlend
import hu.oandras.androidsvg.dom.SvgObject.FeColorMatrix
import hu.oandras.androidsvg.dom.SvgObject.FeComponentTransfer
import hu.oandras.androidsvg.dom.SvgObject.FeComposite
import hu.oandras.androidsvg.dom.SvgObject.FeConvolveMatrix
import hu.oandras.androidsvg.dom.SvgObject.FeDiffuseLighting
import hu.oandras.androidsvg.dom.SvgObject.FeDisplacementMap
import hu.oandras.androidsvg.dom.SvgObject.FeFlood
import hu.oandras.androidsvg.dom.SvgObject.FeGaussianBlur
import hu.oandras.androidsvg.dom.SvgObject.FeImage
import hu.oandras.androidsvg.dom.SvgObject.FeMerge
import hu.oandras.androidsvg.dom.SvgObject.FeMergeNode
import hu.oandras.androidsvg.dom.SvgObject.FeMorphology
import hu.oandras.androidsvg.dom.SvgObject.FeOffset
import hu.oandras.androidsvg.dom.SvgObject.FeSpecularLighting
import hu.oandras.androidsvg.dom.SvgObject.FeTile
import hu.oandras.androidsvg.dom.SvgObject.FeTurbulence
import hu.oandras.androidsvg.dom.SvgObject.Filter
import hu.oandras.androidsvg.dom.SvgObject.FilterPrimitive
import hu.oandras.androidsvg.dom.SvgObject.GradientElement
import hu.oandras.androidsvg.dom.SvgObject.GraphicsElement
import hu.oandras.androidsvg.dom.SvgObject.Group
import hu.oandras.androidsvg.dom.SvgObject.Image
import hu.oandras.androidsvg.dom.SvgObject.Line
import hu.oandras.androidsvg.dom.SvgObject.Marker
import hu.oandras.androidsvg.dom.SvgObject.Mask
import hu.oandras.androidsvg.dom.SvgObject.PolyLine
import hu.oandras.androidsvg.dom.SvgObject.Polygon
import hu.oandras.androidsvg.dom.SvgObject.SolidColor
import hu.oandras.androidsvg.dom.SvgObject.Stop
import hu.oandras.androidsvg.dom.SvgObject.Svg
import hu.oandras.androidsvg.dom.SvgObject.SvgConditional
import hu.oandras.androidsvg.dom.SvgObject.SvgContainer
import hu.oandras.androidsvg.dom.SvgObject.SvgElement
import hu.oandras.androidsvg.dom.SvgObject.SvgElementBase
import hu.oandras.androidsvg.dom.SvgObject.SvgLinearGradient
import hu.oandras.androidsvg.dom.SvgObject.SvgRadialGradient
import hu.oandras.androidsvg.dom.SvgObject.Switch
import hu.oandras.androidsvg.dom.SvgObject.Symbol
import hu.oandras.androidsvg.dom.SvgObject.TSpan
import hu.oandras.androidsvg.dom.SvgObject.Text
import hu.oandras.androidsvg.dom.SvgObject.TextContainer
import hu.oandras.androidsvg.dom.SvgObject.TextPath
import hu.oandras.androidsvg.dom.SvgObject.TextSequence
import hu.oandras.androidsvg.dom.SvgObject.Use
import hu.oandras.androidsvg.dom.SvgObject.View
import hu.oandras.androidsvg.dom.SvgPaint
import hu.oandras.androidsvg.render.filters.doFeBlendFilter
import hu.oandras.androidsvg.render.filters.doFeColorMatrixFilter
import hu.oandras.androidsvg.render.filters.doFeComponentTransferFilter
import hu.oandras.androidsvg.render.filters.doFeCompositeFilter
import hu.oandras.androidsvg.render.filters.doFeConvolveMatrixFilter
import hu.oandras.androidsvg.render.filters.doFeDiffuseLightingFilter
import hu.oandras.androidsvg.render.filters.doFeDisplacementMapFilter
import hu.oandras.androidsvg.render.filters.doFeGaussianBlurFilter
import hu.oandras.androidsvg.render.filters.doFeImageFilter
import hu.oandras.androidsvg.render.filters.doFeMorphologyFilter
import hu.oandras.androidsvg.render.filters.doFeOffsetFilter
import hu.oandras.androidsvg.render.filters.doFeSpecularLightingFilter
import hu.oandras.androidsvg.render.filters.doFeTileFilter
import hu.oandras.androidsvg.render.filters.doFeTurbulenceFilter
import hu.oandras.androidsvg.render.filters.getFilterInput
import hu.oandras.androidsvg.utils.GradientSpread
import hu.oandras.androidsvg.utils.ceilToInt
import hu.oandras.androidsvg.utils.checkForImageDataURL
import hu.oandras.androidsvg.utils.clamp255
import hu.oandras.androidsvg.utils.colorWithOpacity
import hu.oandras.androidsvg.utils.createBitmap
import hu.oandras.androidsvg.utils.createBitmapSameAs
import hu.oandras.androidsvg.utils.extractAlpha
import hu.oandras.androidsvg.utils.forEachElement
import hu.oandras.androidsvg.utils.forEachKeyValue
import hu.oandras.androidsvg.utils.isSpaceLike
import hu.oandras.androidsvg.utils.removeDoubleSpaces
import hu.oandras.androidsvg.utils.removeTabsAndLineBreaks
import hu.oandras.androidsvg.utils.toDegrees
import hu.oandras.androidsvg.utils.withAlpha
import java.util.Locale
import java.util.Stack
import kotlin.math.abs
import kotlin.math.atan2
import kotlin.math.floor
import kotlin.math.hypot
import kotlin.math.max
import kotlin.math.min


internal val SUPPORTS_BLEND_MODE: Boolean = Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q // Android 10
private val SUPPORTS_PAINT_WORD_SPACING: Boolean  = Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q // Android 10
private val SUPPORTS_RADIAL_GRADIENT_WITH_FOCUS: Boolean  = Build.VERSION.SDK_INT >= Build.VERSION_CODES.S // Android 12

/*
 * The rendering part of AndroidSVG.
 */
@SuppressLint("UseKtx")
@Suppress("LocalVariableName")
internal class SVGAndroidRenderer internal constructor(
    private val document: SVGImpl,
    private var canvas: Canvas,
    // dots per inch. Needed for accurate conversion of length values that have real world units, such as "cm".
    override val dPI: Float,
    private val externalFileResolver: SVGExternalFileResolver?
): RenderContext {
    // Renderer state
    private var state: RendererState = RendererState()

    data class SavedRendererState(
        @JvmField
        val state: RendererState,
        @JvmField
        val canvasSaveCount: Int,
    )

    private val stateStack: Stack<SavedRendererState> = Stack() // Keeps track of render state as we render

    // Keep track of element stack while rendering.
    private val parentStack: Stack<SvgContainer> =
        Stack() // The 'render parent' for elements like Symbol cf. file parent
    private val matrixStack: Stack<Matrix> =
        Stack() // Keeps track of current transform as we descend into element tree

    private var ruleMatchContext: RuleMatchContext? = null

    override val currentFontSize: Float
        get() = state.fillPaint.textSize

    override val currentFontXHeight: Float
        get() {
            // The CSS3 spec says to use 0.5em if there is no way to determine true x-height;
            return currentFontSize / 2f
        }

    override val effectiveViewPortInUserUnits: Box
        /*
         * Get the current view port in user units.
         * If a viewBox is in effect, then this will return the viewBox
         * since a viewBox transform will have already been applied.
         */
        get() {
            val s = state
            return s.viewBox ?: checkNotNull(s.viewPort) { "Viewport is null" }
        }

    internal class RendererState internal constructor(
        @JvmField
        val style: Style,

        @JvmField
        var hasFill: Boolean,

        @JvmField
        var hasStroke: Boolean,

        @JvmField
        internal var viewPort: Box?,

        @JvmField
        internal var viewBox: Box?,

        @JvmField
        var spacePreserve: Boolean,

        @JvmField
        val fillPaint: Paint,

        @JvmField
        val strokePaint: Paint,

        @JvmField
        val fontFeatureSet: CSSFontFeatureSettings,

        @JvmField
        val fontVariationSet: CSSFontVariationSettings,
    ) {

        val fillType: FillType
            get() {
                return if (style.fillRule == FillRule.EvenOdd) {
                    FillType.EVEN_ODD
                } else {
                    FillType.WINDING
                }
            }

        val clipRule: FillType
            get() {
                return if (style.clipRule == FillRule.EvenOdd) {
                    FillType.EVEN_ODD
                } else {
                    FillType.WINDING
                }
            }

        internal constructor() : this(
            style = Style.getDefaultStyle(),
            hasFill = false,
            hasStroke = false,
            viewPort = null,
            viewBox = null,
            spacePreserve = false,
            fillPaint = Paint().apply {
                flags = Paint.ANTI_ALIAS_FLAG or Paint.LINEAR_TEXT_FLAG or Paint.SUBPIXEL_TEXT_FLAG
                hinting = Paint.HINTING_OFF
                style = Paint.Style.FILL
                setTypeface(
                    Typeface.DEFAULT
                )
            },

            strokePaint = Paint().apply {
                flags = Paint.ANTI_ALIAS_FLAG or Paint.LINEAR_TEXT_FLAG or Paint.SUBPIXEL_TEXT_FLAG
                hinting = Paint.HINTING_OFF
                style = Paint.Style.STROKE
                setTypeface(Typeface.DEFAULT)
            },

            fontFeatureSet = CSSFontFeatureSettings(),
            fontVariationSet = CSSFontVariationSettings(),
        )

        internal constructor(copy: RendererState) : this(
            hasFill = copy.hasFill,
            hasStroke = copy.hasStroke,
            fillPaint = Paint(copy.fillPaint),
            strokePaint = Paint(copy.strokePaint),
            viewPort = copy.viewPort?.copy(),
            viewBox = copy.viewBox?.copy(),
            spacePreserve = copy.spacePreserve,
            fontFeatureSet = CSSFontFeatureSettings(copy.fontFeatureSet),
            fontVariationSet = CSSFontVariationSettings(copy.fontVariationSet),
            style = copy.style.copy()
        )

        override fun toString(): String {
            return "RendererState(style=$style, hasFill=$hasFill, hasStroke=$hasStroke, viewPort=$viewPort, viewBox=$viewBox, spacePreserve=$spacePreserve, fillPaint=$fillPaint, strokePaint=$strokePaint, fontFeatureSet=$fontFeatureSet, fontVariationSet=$fontVariationSet)"
        }
    }

    private fun resetState() {
        val state = RendererState()
        this.state = state
        stateStack.clear()

        // Initialize the style state properties like Paints etc. using a fresh instance of Style
        updateStyle(state, Style.getDefaultStyle())

        state.viewPort = null // Get filled in later

        state.spacePreserve = false

        // Push a copy of the state with 'default' style, so that inherit works for top level objects
        stateStack.push(SavedRendererState(state , canvas.saveCount)) // Manual push here - don't use statePush();

        // Keep track of element stack while rendering.
        // The 'render parent' for some elements (eg <use> references) is different from its DOM parent.
        matrixStack.clear()
        parentStack.clear()
    }

    /*
    * Render the whole document.
    */
    internal fun renderDocument(renderOptions: RenderOptions) {
        val rootObj = document.rootElement

        if (rootObj == null) {
            warn("Nothing to render. Document is empty.")
            return
        }

        val viewBox: Box?
        val preserveAspectRatio: PreserveAspectRatio?

        if (renderOptions.hasView()) {
            val obj = document.getElementById(renderOptions.viewId)
            if (obj !is View) {
                Log.w(
                    TAG,
                    String.format("View element with id \"%s\" not found.", renderOptions.viewId)
                )
                return
            }

            if (obj.viewBox == null) {
                Log.w(
                    TAG,
                    String.format(
                        "View element with id \"%s\" is missing a viewBox attribute.",
                        renderOptions.viewId
                    )
                )
                return
            }
            viewBox = obj.viewBox
            preserveAspectRatio = obj.preserveAspectRatio
        } else {
            viewBox = if (renderOptions.hasViewBox()) {
                renderOptions.viewBox
            } else {
                rootObj.viewBox
            }

            preserveAspectRatio = if (renderOptions.hasPreserveAspectRatio()) {
                renderOptions.preserveAspectRatio
            } else {
                rootObj.preserveAspectRatio
            }
        }

        val css = renderOptions.css
        if (css != null) {
            document.addCSSRules(css.cssRuleSet)
        }

        if (renderOptions.hasTarget()) {
            ruleMatchContext = RuleMatchContext(
                targetElement = document.getElementById(renderOptions.targetId)
            )
        }

        // Initialize the state
        resetState()

        checkXMLSpaceAttribute(rootObj)

        withNewRootContextState {
            val viewPort = renderOptions.viewPort!!.copy()
            // If root element specifies a width, then we need to adjust our default viewPort that was based on the canvas size
            rootObj.width?.let {
                viewPort.width = it.floatValue(this, viewPort.width)
            }
            rootObj.height?.let {
                viewPort.height = it.floatValue(this, viewPort.height)
            }

            // Render the document
            render(
                obj = rootObj,
                viewPort = viewPort,
                viewBox = viewBox,
                positioning = preserveAspectRatio
            )
        }

        if (renderOptions.hasCss()) {
            document.clearRenderCSSRules()
        }
    }

    //==============================================================================
    // Render dispatcher
    private fun render(obj: SvgObject) {
        if (obj is NotDirectlyRendered) return

        withNewState {
            checkXMLSpaceAttribute(obj)

            when (obj) {
                is Svg -> render(obj)
                is Use -> render(obj)
                is Switch -> render(obj)
                is Group -> render(obj) // Includes <a> elements
                is Image -> render(obj)
                is SvgObject.Path -> render(obj)
                is SvgObject.Rect -> render(obj)
                is Circle -> render(obj)
                is Ellipse -> render(obj)
                is Line -> render(obj)
                is Polygon -> render(obj)
                is PolyLine -> render(obj)
                is Text -> render(obj)
            }
        }
    }

    //==============================================================================
    private fun renderChildren(obj: SvgContainer, isContainer: Boolean) {
        if (isContainer) {
            parentPush(obj)
        }

        obj.getChildren().forEachElement { child ->
            render(child)
        }

        if (isContainer) {
            parentPop()
        }
    }

    private inline fun withNewRootContextState(r: (RendererState) -> Unit) {
        val state = statePush(true)
        r.invoke(state)
        statePop()
    }

    private inline fun <T> withNewState(saveCanvas: Boolean = true, r: (RendererState) -> T): T {
        val stateStackState = if (BuildConfig.DEBUG) {
            stateStack.size
        } else {
            0
        }
        val state = statePush(false, saveCanvas)
        return try {
            r.invoke(state)
        } finally {
            statePop()
            if (BuildConfig.DEBUG) {
                check(stateStack.size == stateStackState) {
                    "Stack size mismatch expected: $stateStackState, was: ${stateStack.size}!"
                }
            }
        }
    }

    //==============================================================================
    @JvmSynthetic
    internal fun statePush(isRootContext: Boolean = false, saveCanvas: Boolean = true): RendererState {
        val savedCount = if (saveCanvas) {
            if (isRootContext) {
                // Root SVG context should be transparent. So we need to saveLayer
                // to avoid background messing with blend modes etc.
                canvas.saveLayer(null, null)
            } else {
                canvas.save()
            }
        } else {
            -1
        }
        // Save style state
        val oldState = state
        stateStack.push(SavedRendererState(oldState, savedCount))
        val newState = RendererState(oldState)
        state = newState
        return newState
    }

    @JvmSynthetic
    internal fun statePop() {
        val poppedState = stateStack.pop()
        if (poppedState.canvasSaveCount != -1) {
            canvas.restoreToCount(poppedState.canvasSaveCount)
        }
        state = poppedState.state
    }

    //==============================================================================
    private fun parentPush(obj: SvgContainer) {
        parentStack.push(obj)
        @Suppress("DEPRECATION")
        matrixStack.push(canvas.matrix)
    }

    private fun parentPop() {
        parentStack.pop()
        matrixStack.pop()
    }

    //==============================================================================
    private fun updateStyleForElement(state: RendererState, obj: SvgElementBase) {
        val isRootSVG = obj.parent == null
        state.style.resetNonInheritingProperties(isRootSVG)

        // Apply the styles defined by style attributes on the element
        obj.baseStyle?.let { updateStyle(state, it) }

        // Apply the styles from any CSS files or <style> elements
        document.cSSRules.forEachElement { rule ->
            if (CSSParser.ruleMatch(ruleMatchContext, rule.selector, obj)) {
                updateStyle(state, rule.style)
            }
        }

        // Apply the styles defined by the 'style' attribute. They have the highest precedence.
        obj.style?.let { updateStyle(state, it) }
    }

    /*
    * Check and update xml:space handling.
    */
    private fun checkXMLSpaceAttribute(obj: SvgObject) {
        if (obj is SvgElementBase) {
            obj.spacePreserve?.let { state.spacePreserve = it }
        }
    }

    /*
    * Fill a path with either the given paint, or if a pattern is set, with the pattern.
    */
    private fun doFilledPath(obj: SvgElement, path: Path) {
        val s = state
        // First check for pattern fill. It requires special handling.
        val fill = s.style.fill
        if (fill is PaintReference) {
            val ref = document.resolveIRI(fill.href)
            if (ref is SvgObject.Pattern) {
                fillWithPattern(obj, path, ref)
                return
            }
        }

        // Otherwise do a normal fill
        canvas.drawPath(path, s.fillPaint)
    }

    private fun doStroke(path: Path) {
        // TODO handle degenerate subpaths properly

        val state = state
        if (state.style.vectorEffect == VectorEffect.NonScalingStroke) {
            // For non-scaling-stroke, the stroke width is not transformed along with the path.
            // It will be rendered at the same width no matter how the document contents are transformed.

            // First step: get the current canvas matrix

            @Suppress("DEPRECATION")
            val currentMatrix = canvas.matrix
            // Transform the path using this transform
            val transformedPath = Path()
            path.transform(currentMatrix, transformedPath)
            // Reset the current canvas transform completely
            canvas.setMatrix(Matrix())

            // If there is a shader (such as a gradient), we need to update its transform also
            val shader = state.strokePaint.shader
            val currentShaderMatrix = Matrix()
            if (shader != null) {
                shader.getLocalMatrix(currentShaderMatrix)
                val newShaderMatrix = Matrix(currentShaderMatrix)
                newShaderMatrix.postConcat(currentMatrix)
                shader.setLocalMatrix(newShaderMatrix)
            }

            // Render the transformed path. The stroke width used will be in unscaled device units.
            canvas.drawPath(transformedPath, state.strokePaint)

            // Return the current canvas transform to what it was before all this happened         
            canvas.setMatrix(currentMatrix)
            // And reset the shader matrix also
            shader?.setLocalMatrix(currentShaderMatrix)
        } else {
            canvas.drawPath(path, state.strokePaint)
        }
    }

    //==============================================================================
    // Renderers for each element type
    private fun render(obj: Svg) {
        // <svg> elements establish a new viewport.
        val viewPort = makeViewPort(
            x = obj.x,
            y = obj.y,
            width = obj.width,
            height = obj.height
        )

        render(
            obj = obj,
            viewPort = viewPort,
            viewBox = obj.viewBox,
            positioning = obj.preserveAspectRatio
        )
    }

    // When called from renderDocument, we pass in our own viewBox.
    // If rendering the whole document, it will be rootObj.viewBox.  When rendering a view
    // it will be the viewBox from the <view> element.
    // When referenced by a <use> element, it's width and height take precedence over the ones in the <svg> object.
    private fun render(
        obj: Svg,
        viewPort: Box,
        viewBox: Box? = obj.viewBox,
        positioning: PreserveAspectRatio? = obj.preserveAspectRatio
    ) {
        var positioning = positioning
        debug { "Svg render" }

        if (viewPort.width == 0f || viewPort.height == 0f) return

        // "If attribute 'preserveAspectRatio' is not specified, then the effect is as if a value of xMidYMid meet were specified."
        if (positioning == null) positioning =
            obj.preserveAspectRatio ?: PreserveAspectRatio.LETTERBOX

        val s = state
        updateStyleForElement(s, obj)

        if (!display()) return

        s.viewPort = viewPort

        if (s.style.overflow == false) {
            setClipRect(viewPort)
        }

        checkForClipPath(obj, viewPort)

        if (viewBox != null) {
            canvas.concat(calculateViewBoxTransform(viewPort, viewBox, positioning))
            s.viewBox = obj.viewBox // Note: definitely obj.viewBox here. Not viewBox parameter.
        } else {
            canvas.translate(viewPort.minX, viewPort.minY)
            s.viewBox = null
        }

        withNewRenderLayer(obj) {
            // Action the viewport-fill property (if set)
            viewportFill()
            renderChildren(obj, true)
        }

        updateParentBoundingBox(obj)
    }


    // Derive the viewport from the x, y, width and height attributes of an object
    private fun makeViewPort(
        x: CSSLength?,
        y: CSSLength?,
        width: CSSLength?,
        height: CSSLength?
    ): Box {
        val _x = x?.floatValueX(this) ?: 0f
        val _y = y?.floatValueY(this) ?: 0f

        val viewPortUser = effectiveViewPortInUserUnits
        val _w = width?.floatValueX(this) ?: viewPortUser.width // default 100%
        val _h = height?.floatValueY(this) ?: viewPortUser.height

        return Box(_x, _y, _w, _h)
    }

    private fun concatTransform(canvas: Canvas, obj: HasTransform) {
        obj.getTransform()?.let { canvas.concat(it) }
    }

    //==============================================================================
    // Render <g> and <a> elements
    private fun render(obj: Group) {
        val s = state
        debug { obj.getNodeName() + " render" }

        updateStyleForElement(s, obj)

        if (!display()) return

        concatTransform(canvas, obj)

        checkForClipPath(obj)

        withNewRenderLayer(obj) {
            renderChildren(obj, true)
        }

        updateParentBoundingBox(obj)
    }


    //==============================================================================
    /*
    * Called by an object to update its parent's bounding box.
    *
    * This operation is made more tricky because the child's boundingBox is in the child's coordinate space,
    * but the parent needs it in the parent's coordinate space.
    */
    private fun updateParentBoundingBox(obj: SvgElement) {
        if (obj.parent == null)  // skip this if obj is root element
            return

        val boundingBox = obj.boundingBox
            ?: return // empty boundingBox, possibly as a result of a badly defined element (e.g. bad use reference etc.)

        // Convert the corners of the child boundingBox to world space
        val m = Matrix()
        // Get the inverse of the child transform
        if (matrixStack.peek()!!.invert(m)) {
            val pts = floatArrayOf(
                boundingBox.minX,
                boundingBox.minY,
                boundingBox.maxX(),
                boundingBox.minY,
                boundingBox.maxX(),
                boundingBox.maxY(),
                boundingBox.minX,
                boundingBox.maxY()
            )
            // Now concatenate the parent's matrix to create a child-to-parent transform
            @Suppress("DEPRECATION")
            m.preConcat(canvas.matrix)
            m.mapPoints(pts)
            // Finally, find the bounding box of the transformed points
            val rect = RectF(pts[0], pts[1], pts[0], pts[1])
            var i = 2
            while (i <= 6) {
                if (pts[i] < rect.left) rect.left = pts[i]
                if (pts[i] > rect.right) rect.right = pts[i]
                if (pts[i + 1] < rect.top) rect.top = pts[i + 1]
                if (pts[i + 1] > rect.bottom) rect.bottom = pts[i + 1]
                i += 2
            }
            // Update the parent bounding box with the transformed boundingBox
            val parent = parentStack.peek() as SvgElement
            val parentBoundingBox = parent.boundingBox
            if (parentBoundingBox == null) {
                parent.boundingBox = fromLimits(
                    minX = rect.left,
                    minY = rect.top,
                    maxX = rect.right,
                    maxY = rect.bottom
                )
            } else {
                parentBoundingBox.union(
                    fromLimits(
                        rect.left,
                        rect.top,
                        rect.right,
                        rect.bottom
                    )
                )
            }
        }
    }

    private inline fun withNewRenderLayer(
        obj: SvgElement,
        opacityAdjustment: Float = 1f,
        r: (RendererState) -> Unit
    ) {
        val filterId = state.style.filter
        if (filterId != null) {
            val filter = document.resolveIRI(filterId) as? Filter
            if (filter != null) {
                val boundingBox = obj.boundingBox ?: calculatePathBounds(objectToPath(obj, true) ?: Path()).also { obj.boundingBox = it }
                val region = calculateFilterRegion(filter, boundingBox)
                if (region.width() > 0f && region.height() > 0f) {
                    val oldCanvas = canvas
                    val matrix = Matrix()
                    @Suppress("DEPRECATION")
                    oldCanvas.getMatrix(matrix)

                    val deviceRegion = RectF()
                    matrix.mapRect(deviceRegion, region)

                    val bitmap = createBitmap(
                        deviceRegion.width().ceilToInt(),
                        deviceRegion.height().ceilToInt(),
                    )
                    
                    canvas = Canvas(bitmap)
                    val newMatrix = Matrix(matrix)
                    newMatrix.postTranslate(-deviceRegion.left, -deviceRegion.top)
                    canvas.setMatrix(newMatrix)

                    val m = FloatArray(9)
                    matrix.getValues(m)
                    val sx = hypot(m[Matrix.MSCALE_X], m[Matrix.MSKEW_Y])
                    val sy = hypot(m[Matrix.MSCALE_Y], m[Matrix.MSKEW_X])

                    try {
                        r.invoke(state)
                    } finally {
                        canvas = oldCanvas
                    }
                    applyFilter(
                        bitmap = bitmap,
                        region = deviceRegion,
                        sx = sx,
                        sy = sy,
                        filter = filter,
                        originalObjBBox = boundingBox
                    )
                    return
                }
            }
        }

        val stateStackState = if (BuildConfig.DEBUG) {
            stateStack.size
        } else {
            0
        }
        val pushed = pushLayer(opacityAdjustment)
        try {
            r.invoke(state)
        } finally {
            if (pushed) {
                popLayer(obj)
            }
            if (BuildConfig.DEBUG) {
                check(stateStack.size == stateStackState) {
                    "Stack size mismatch expected: $stateStackState, was: ${stateStack.size}!"
                }
            }
        }
    }

    private inline fun withNewRenderLayer(
        obj: SvgElement,
        originalObjBBox: Box,
        opacityAdjustment: Float = 1f,
        r: (RendererState) -> Unit
    ) {
        val filterId = state.style.filter
        if (filterId != null) {
            val filter = document.resolveIRI(filterId) as? Filter
            if (filter != null) {
                val region = calculateFilterRegion(filter, originalObjBBox)
                if (region.width() > 0f && region.height() > 0f) {
                    val oldCanvas = canvas
                    val matrix = Matrix()
                    @Suppress("DEPRECATION")
                    oldCanvas.getMatrix(matrix)

                    val deviceRegion = RectF()
                    matrix.mapRect(deviceRegion, region)

                    val bitmap = createBitmap(
                        deviceRegion.width().ceilToInt(),
                        deviceRegion.height().ceilToInt(),
                    )

                    canvas = Canvas(bitmap)
                    val newMatrix = Matrix(matrix)
                    newMatrix.postTranslate(-deviceRegion.left, -deviceRegion.top)
                    canvas.setMatrix(newMatrix)

                    val m = FloatArray(9)
                    matrix.getValues(m)
                    val sx = hypot(m[Matrix.MSCALE_X], m[Matrix.MSKEW_Y])
                    val sy = hypot(m[Matrix.MSCALE_Y], m[Matrix.MSKEW_X])

                    try {
                        r.invoke(state)
                    } finally {
                        canvas = oldCanvas
                    }
                    applyFilter(bitmap, deviceRegion, sx, sy, filter, originalObjBBox)
                    return
                }
            }
        }

        val stateStackState = if (BuildConfig.DEBUG) {
            stateStack.size
        } else {
            0
        }
        val pushed = pushLayer(opacityAdjustment)
        try {
            r.invoke(state)
        } finally {
            if (pushed) {
                popLayer(obj, originalObjBBox)
            }
            if (BuildConfig.DEBUG) {
                check(stateStack.size == stateStackState) {
                    "Stack size mismatch expected: $stateStackState, was: ${stateStack.size}!"
                }
            }
        }
    }

    //==============================================================================
    private fun pushLayer(opacityAdjustment: Float = 1f): Boolean {
        // opacityAdjustment is used by fillWithPattern() in order to apply the fillOpacity for the
        // pattern

        val oldState = state
        if (!requiresCompositing() && opacityAdjustment == 1f) {
            return false
        }

        // Custom version of statePush() that also saves the layer
        val savePaint = Paint()
        savePaint.alpha = clamp255(oldState.style.opacity * opacityAdjustment * 255f)

        if (SUPPORTS_BLEND_MODE && oldState.style.mixBlendMode != CSSBlendMode.normal) {
            setBlendMode(oldState, savePaint)
        }
        val savedCount = canvas.saveLayer(null, savePaint)

        // Save style state
        stateStack.push(SavedRendererState(oldState, savedCount))
        val newState = RendererState(oldState)
        state = newState

        val mask = newState.style.mask
        if (mask != null) {
            val ref = document.resolveIRI(mask)
            // Check that we are referencing a mask element
            if (ref !is Mask) {
                // This is an invalid mask reference - disable this object's mask
                error("Mask reference '%s' not found", mask)
                newState.style.mask = null
                return true
            }

            // After this method completes, the caller will draw the masked object to its own layer.
            // That will later be composited together with our mask layer (in popLayer())
        }

        return true
    }


    /**
     * @param obj The object we are compositing. Compositing happens if the obj is not fully opaque, or if it has a mask.
     * @param originalObjBBox Normally equal to obj.boundingBox. However, if obj is a mask, then this is the bounding box of the original object to which the mask was applied.
     */
    @JvmSynthetic
    internal fun popLayer(obj: SvgElement, originalObjBBox: Box = obj.boundingBox!!) {
        // If this is masked content, apply the mask now
        val mask = state.style.mask
        if (mask != null) {
            val ref = document.resolveIRI(mask) as Mask
            val maskType = findInheritFromAncestorState(ref).style.maskType

            // The masked content has been drawn, now we have to composite it with our mask layer.
            // The mask has to be built from two parts:
            // Step 1: Apply a luminanceToAlpha conversion to the mask content.
            // Step 2: Multiply the mask's alpha to the alpha channel generated in step 1.

            // Final mask gets composited using Porter Duff mode DST_IN

            val maskPaintCombined = Paint()
            maskPaintCombined.xfermode = PorterDuffXfermode(PorterDuff.Mode.DST_IN)
            val layer1Count = canvas.saveLayer(originalObjBBox.toRectF(), maskPaintCombined)

            if (maskType == MaskType.luminance) {
                // Step 1: convert the mask luminance to alpha.
                val maskPaint1 = Paint()
                val luminanceToAlpha = ColorMatrix(
                    floatArrayOf(
                        0f, 0f, 0f, 0f, 0f,
                        0f, 0f, 0f, 0f, 0f,
                        0f, 0f, 0f, 0f, 0f,
                        LUMINANCE_TO_ALPHA_RED, LUMINANCE_TO_ALPHA_GREEN, LUMINANCE_TO_ALPHA_BLUE, 0f, 0f
                    )
                )
                maskPaint1.setColorFilter(ColorMatrixColorFilter(luminanceToAlpha))
                val layer2Count = canvas.saveLayer(originalObjBBox.toRectF(), maskPaint1)
                renderMask(ref, obj, originalObjBBox)
                canvas.restoreToCount(layer2Count)
                // Step 2: multiply the luminance alpha by the source alpha.
                val maskPaint2 = Paint()
                maskPaint2.xfermode = PorterDuffXfermode(PorterDuff.Mode.DST_IN)
                val layer3Count = canvas.saveLayer(originalObjBBox.toRectF(), maskPaint2)
                renderMask(ref, obj, originalObjBBox)
                canvas.restoreToCount(layer3Count)
            } else {
                // For mask-type: alpha, the mask's alpha channel is the final mask.
                renderMask(ref, obj, originalObjBBox)
            }

            // Apply the final mask to the original object waiting in the open layer created in pushLayer()
            canvas.restoreToCount(layer1Count)
        }

        statePop()
    }

    private fun calculateMaskRegion(mask: Mask, originalObjBBox: Box): RectF {
        val maskUnitsAreUser = mask.maskUnitsAreUser == true

        // Default values are -10%, -10%, 120%, 120%
        val x: Float
        val y: Float
        val w: Float
        val h: Float

        if (maskUnitsAreUser) {
            x = mask.x?.floatValueX(this) ?: (originalObjBBox.minX - 0.1f * originalObjBBox.width)
            y = mask.y?.floatValueY(this) ?: (originalObjBBox.minY - 0.1f * originalObjBBox.height)
            w = mask.width?.floatValueX(this) ?: (1.2f * originalObjBBox.width)
            h = mask.height?.floatValueY(this) ?: (1.2f * originalObjBBox.height)
        } else {
            val _x = mask.x?.floatValue(this, 1f) ?: -0.1f
            val _y = mask.y?.floatValue(this, 1f) ?: -0.1f
            val _w = mask.width?.floatValue(this, 1f) ?: 1.2f
            val _h = mask.height?.floatValue(this, 1f) ?: 1.2f
            x = originalObjBBox.minX + _x * originalObjBBox.width
            y = originalObjBBox.minY + _y * originalObjBBox.height
            w = _w * originalObjBBox.width
            h = _h * originalObjBBox.height
        }

        return RectF(x, y, x + w, y + h)
    }

    private fun calculateFilterRegion(filter: Filter, originalObjBBox: Box): RectF {
        val filterUnitsAreUser = filter.filterUnitsAreUser == true

        // Default values are -10%, -10%, 120%, 120%
        val x: Float
        val y: Float
        val w: Float
        val h: Float

        if (filterUnitsAreUser) {
            x = filter.x?.floatValueX(this) ?: (originalObjBBox.minX - 0.1f * originalObjBBox.width)
            y = filter.y?.floatValueY(this) ?: (originalObjBBox.minY - 0.1f * originalObjBBox.height)
            w = filter.width?.floatValueX(this) ?: (1.2f * originalObjBBox.width)
            h = filter.height?.floatValueY(this) ?: (1.2f * originalObjBBox.height)
        } else {
            val _x = filter.x?.floatValue(this, 1f) ?: -0.1f
            val _y = filter.y?.floatValue(this, 1f) ?: -0.1f
            val _w = filter.width?.floatValue(this, 1f) ?: 1.2f
            val _h = filter.height?.floatValue(this, 1f) ?: 1.2f
            x = originalObjBBox.minX + _x * originalObjBBox.width
            y = originalObjBBox.minY + _y * originalObjBBox.height
            w = _w * originalObjBBox.width
            h = _h * originalObjBBox.height
        }

        return RectF(x, y, x + w, y + h)
    }

    private fun applyFilter(
        bitmap: Bitmap,
        region: RectF,
        sx: Float,
        sy: Float,
        filter: Filter,
        originalObjBBox: Box,
    ) {
        val results = ArrayMap<String, Bitmap>()
        results["SourceGraphic"] = bitmap
        results["SourceAlpha"] = extractAlpha(bitmap)

        var lastResult: Bitmap? = bitmap
        val primitiveUnitsAreUser = filter.primitiveUnitsAreUser != false
        val primitiveScaleX = if (primitiveUnitsAreUser) sx else originalObjBBox.width * sx
        val primitiveScaleY = if (primitiveUnitsAreUser) sy else originalObjBBox.height * sy

        filter.getChildren().forEachElement { child ->
            val res = when (child) {
                is FilterPrimitive -> {
                    val r = applyPrimitive(
                        primitive = child,
                        results = results,
                        lastResult = lastResult,
                        primitiveScaleX = primitiveScaleX,
                        primitiveScaleY = primitiveScaleY,
                        canvasScaleX = sx,
                        canvasScaleY = sy,
                        primitiveUnitsAreUser = primitiveUnitsAreUser,
                    )
                    if (r != null) {
                        child.result?.let { results[it] = r }
                    }
                    r
                }

                is FeMerge -> {
                    val r = applyFeMerge(child, results, lastResult, region)
                    child.result?.let { results[it] = r }
                    r
                }

                else -> null
            }
            if (res != null) {
                lastResult = res
            }
        }

        if (lastResult != null) {
            val canvas = canvas
            canvas.save()
            canvas.setMatrix(null)
            canvas.drawBitmap(lastResult, region.left, region.top, null)
            canvas.restore()
        }

        results.forEachKeyValue { _, b ->
            if (b !== bitmap) {
                b.recycle()
            }
        }
    }

    private fun applyPrimitive(
        primitive: FilterPrimitive,
        results: Map<String, Bitmap>,
        lastResult: Bitmap?,
        primitiveScaleX: Float,
        primitiveScaleY: Float,
        canvasScaleX: Float,
        canvasScaleY: Float,
        primitiveUnitsAreUser: Boolean,
    ): Bitmap? {
        val input = getFilterInput(
            name = primitive.`in`,
            results = results,
            lastResult = lastResult
        )

        if (primitive is FeTurbulence) {
            return doFeTurbulenceFilter(
                primitive = primitive,
                input = input,
                lastResult = lastResult,
                results = results,
                canvasScaleX = canvasScaleX,
                canvasScaleY = canvasScaleY,
            )
        }

        val inputBitmap = input ?: return null

        return when (primitive) {

            is FeOffset -> doFeOffsetFilter(
                renderContext = this,
                primitive = primitive,
                inputBitmap = inputBitmap,
                primitiveUnitsAreUser = primitiveUnitsAreUser,
                primitiveScaleX = primitiveScaleX,
                primitiveScaleY = primitiveScaleY,
                canvasScaleX = canvasScaleX,
                canvasScaleY = canvasScaleY,
            )

            is FeColorMatrix -> doFeColorMatrixFilter(primitive, inputBitmap)

            is FeConvolveMatrix -> doFeConvolveMatrixFilter(primitive, inputBitmap)

            is FeDisplacementMap -> doFeDisplacementMapFilter(
                primitive,
                inputBitmap,
                results,
                lastResult
            )

            is FeDiffuseLighting -> doFeDiffuseLightingFilter(
                primitive = primitive,
                inputBitmap = inputBitmap,
                canvasScaleX = canvasScaleX,
                canvasScaleY = canvasScaleY,
            )

            is FeSpecularLighting -> doFeSpecularLightingFilter(
                primitive = primitive,
                inputBitmap = inputBitmap,
                canvasScaleX = canvasScaleX,
                canvasScaleY = canvasScaleY,
            )

            is FeFlood -> doFeFloodFilter(
                primitive = primitive,
                inputBitmap = inputBitmap,
            )

            is FeComposite -> doFeCompositeFilter(
                primitive = primitive,
                inputBitmap = inputBitmap,
                results = results,
                lastResult = lastResult,
            )

            is FeComponentTransfer -> doFeComponentTransferFilter(
                primitive = primitive,
                inputBitmap = inputBitmap,
            )

            is FeBlend -> doFeBlendFilter(
                primitive = primitive,
                inputBitmap = inputBitmap,
                results = results,
                lastResult = lastResult,
            )

            is FeGaussianBlur -> doFeGaussianBlurFilter(
                primitive = primitive,
                inputBitmap = inputBitmap,
                primitiveScaleX = primitiveScaleX,
                primitiveScaleY = primitiveScaleY,
            )

            is FeImage -> doFeImageFilter(
                primitive = primitive,
                inputBitmap = inputBitmap,
                externalFileResolver = externalFileResolver,
            )

            is FeMorphology -> doFeMorphologyFilter(
                primitive = primitive,
                inputBitmap = inputBitmap,
                primitiveScaleX = primitiveScaleX,
                primitiveScaleY = primitiveScaleY,
            )

            is FeTile -> doFeTileFilter(inputBitmap)

            else -> {
                val res = createBitmapSameAs(input)
                val c = Canvas(res)
                c.drawBitmap(input, 0f, 0f, null)
                res
            }
        }
    }

    internal fun doFeFloodFilter(
        primitive: FeFlood,
        inputBitmap: Bitmap,
    ): Bitmap {
        val color = withNewState { state ->
            updateStyleForElement(state, primitive)
            val floodColor = state.style.floodColor
            val floodOpacity = state.style.floodOpacity ?: 1f
            val colorInt = when (floodColor) {
                is ColorValue -> floodColor.value
                is CurrentColor -> state.style.color?.value ?: COLOR_BLACK
                else -> COLOR_BLACK
            }
            val alpha = clamp255(floodOpacity * 255f)
            if (alpha == 0) 0 else colorInt.withAlpha(alpha)
        }

        val res = createBitmapSameAs(inputBitmap)
        Canvas(res).drawColor(color, PorterDuff.Mode.SRC)
        return res
    }

    private fun applyFeMerge(
        merge: FeMerge,
        results: Map<String, Bitmap>,
        lastResult: Bitmap?,
        region: RectF
    ): Bitmap {
        val res = createBitmap(
            width = region.width().ceilToInt(),
            height = region.height().ceilToInt(),
        )
        val c = Canvas(res)
        var isFirst = true
        merge.getChildren().forEachElement { child ->
            if (child is FeMergeNode) {
                val input = if (child.`in` == null) {
                    if (isFirst) {
                        results["SourceGraphic"]
                    } else {
                        lastResult
                    }
                } else {
                    results[child.`in`]
                }
                if (input != null) {
                    c.drawBitmap(input, 0f, 0f, null)
                }
                isFirst = false
            }
        }
        return res
    }

    private fun requiresCompositing(): Boolean {
        val s = state
        val style = s.style
        return style.opacity < 1.0f || style.mask != null || style.filter != null || style.isolation == Isolation.isolate || SUPPORTS_BLEND_MODE && style.mixBlendMode != CSSBlendMode.normal
    }

    //==============================================================================
    /*
    * Find the first child of the switch that passes the feature tests and render only that child.
    */
    private fun render(obj: Switch) {
        val s = state
        debug { "Switch render" }

        updateStyleForElement(s, obj)

        if (!display()) return

        concatTransform(canvas, obj)

        checkForClipPath(obj)

        withNewRenderLayer(obj) {
            renderSwitchChild(obj)
        }

        updateParentBoundingBox(obj)
    }

    private fun renderSwitchChild(obj: Switch) {
        val deviceLanguage = Locale.getDefault().language

        val children = obj.getChildren()
        for (i in children.indices) {
            val child = children[i]

            // Ignore any objects that don't belong in a <switch>
            if (child !is SvgConditional) {
                continue
            }

            val condObj: SvgConditional = child as SvgConditional

            // We don't support extensions
            if (condObj.requiredExtensions != null) {
                continue
            }

            // Check language
            val sysLang = condObj.systemLanguage
            if (sysLang != null && (sysLang.isEmpty() || !sysLang.contains(deviceLanguage))) {
                continue
            }

            // Check features
            val reqFeat = condObj.requiredFeatures
            if (reqFeat != null) {
                if (!isRequiredFeaturesSupported(reqFeat)) {
                    continue
                }
            }

            // Check formats (MIME types)
            val reqFormats = condObj.requiredFormats
            if (reqFormats != null) {
                if (!isRequiredFormatsSupported(reqFormats)) {
                    continue
                }
            }

            // Check fonts
            val reqFonts = condObj.requiredFonts
            if (reqFonts != null) {
                if (!isRequiredFontsSupported(reqFonts)) {
                    continue
                }
            }

            // All checks passed!  Render this one element and exit
            render(child)
            break
        }
    }

    private fun isRequiredFeaturesSupported(reqFeat: Collection<String>): Boolean {
        return !reqFeat.isEmpty() && isSupportedFeatures(reqFeat)
    }

    private fun isRequiredFormatsSupported(reqFormats: Collection<String>): Boolean {
        if (reqFormats.isEmpty() || externalFileResolver == null) {
            return false
        }

        for (mimeType in reqFormats) {
            if (!externalFileResolver.isFormatSupported(mimeType)) {
                return false
            }
        }

        return true
    }

    private fun isRequiredFontsSupported(reqFonts: Collection<String>): Boolean {
        if (reqFonts.isEmpty() || externalFileResolver == null) {
            return false
        }

        for (fontName in reqFonts) {
            val style = state.style
            if (externalFileResolver.resolveFont(
                    fontFamily = fontName,
                    fontWeight = style.fontWeight!!,
                    fontStyle = style.fontStyle.toString(),
                    fontStretch = style.fontWidth!!
            ) == null) {
                return false
            }
        }

        return true
    }

    //==============================================================================
    private fun render(obj: Use) {
        val s = state
        debug { "Use render" }

        if (obj.width?.isZero == true || obj.height?.isZero == true) return

        updateStyleForElement(s, obj)

        if (!display()) return

        // Locate the referenced object
        val ref = obj.document.resolveIRI(obj.href)
        if (ref == null) {
            error("Use reference '%s' not found", obj.href)
            return
        }

        concatTransform(canvas, obj)

        // Handle the x,y attributes
        val _x = obj.x?.floatValueX(this) ?: 0f
        val _y = obj.y?.floatValueY(this) ?: 0f
        canvas.translate(_x, _y)

        checkForClipPath(obj)

        withNewRenderLayer(obj) {
            parentPush(obj)

            when (ref) {
                is Svg -> {
                    val svgElem: Svg = ref
                    val viewPort = makeViewPort(
                        x = null,
                        y = null,
                        width = obj.width,
                        height = obj.height
                    )

                    withNewState {
                        render(svgElem, viewPort)
                    }
                }

                is Symbol -> {
                    val viewPort = makeViewPort(
                        x = null,
                        y = null,
                        width = obj.width ?: CSSLength.PERCENT_100,
                        height = obj.height ?: CSSLength.PERCENT_100
                    )

                    withNewState {
                        render(ref, viewPort)
                    }
                }

                else -> {
                    render(ref)
                }
            }

            parentPop()
        }

        updateParentBoundingBox(obj)
    }


    //==============================================================================
    private fun render(obj: SvgObject.Path) {
        val s = state
        debug { "Path render" }

        val pathDefinition = obj.d ?: return

        updateStyleForElement(s, obj)

        if (!display()) return
        if (!visible()) return
        if (!s.hasStroke && !s.hasFill) return

        concatTransform(canvas, obj)

        val path = PathConverter(pathDefinition).path

        if (obj.boundingBox == null) {
            obj.boundingBox = calculatePathBounds(path)
        }
        updateParentBoundingBox(obj)

        checkForGradientsAndPatterns(obj)
        checkForClipPath(obj)

        withNewRenderLayer(obj) { state ->
            if (state.hasFill) {
                path.fillType = state.fillType
                doFilledPath(obj, path)
            }
            if (state.hasStroke) {
                doStroke(path)
            }

            renderMarkers(obj)
        }
    }


    //==============================================================================
    private fun render(obj: SvgObject.Rect) {
        val s = state
        debug { "Rect render" }

        val ojbWidth = obj.width
        val objHeight = obj.height
        if (ojbWidth == null || objHeight == null || ojbWidth.isZero || objHeight.isZero) return

        updateStyleForElement(s, obj)

        if (!display()) return
        if (!visible()) return

        concatTransform(canvas, obj)

        val path = makePathAndBoundingBox(obj)
        updateParentBoundingBox(obj)

        checkForGradientsAndPatterns(obj)
        checkForClipPath(obj)

        withNewRenderLayer(obj) { state ->
            if (state.hasFill) doFilledPath(obj, path)
            if (state.hasStroke) doStroke(path)
        }
    }


    //==============================================================================
    private fun render(obj: Circle) {
        val s = state
        debug { "Circle render" }

        if (obj.r?.isZero == true) return

        updateStyleForElement(s, obj)

        if (!display()) return
        if (!visible()) return

        concatTransform(canvas, obj)

        val path = makePathAndBoundingBox(obj)
        updateParentBoundingBox(obj)

        checkForGradientsAndPatterns(obj)
        checkForClipPath(obj)

        withNewRenderLayer(obj) { state ->
            if (state.hasFill) doFilledPath(obj, path)
            if (state.hasStroke) doStroke(path)
        }
    }


    //==============================================================================
    private fun render(obj: Ellipse) {
        val s = state
        debug { "Ellipse render" }

        if (obj.rx?.isZero == true || obj.ry?.isZero == true) return

        updateStyleForElement(s, obj)

        if (!display()) return
        if (!visible()) return

        concatTransform(canvas, obj)

        val path = makePathAndBoundingBox(obj)
        updateParentBoundingBox(obj)

        checkForGradientsAndPatterns(obj)
        checkForClipPath(obj)

        withNewRenderLayer(obj) { state ->
            if (state.hasFill) doFilledPath(obj, path)
            if (state.hasStroke) doStroke(path)
        }
    }


    //==============================================================================
    private fun render(obj: Line) {
        val s = state
        debug { "Line render" }

        updateStyleForElement(s, obj)

        if (!display()) return
        if (!visible()) return
        if (!s.hasStroke) return

        concatTransform(canvas, obj)

        val path = makePathAndBoundingBox(obj)
        updateParentBoundingBox(obj)

        checkForGradientsAndPatterns(obj)
        checkForClipPath(obj)

        withNewRenderLayer(obj) {
            doStroke(path)
            renderMarkers(obj)
        }
    }

    private fun calculateMarkerPositions(obj: Line): List<MarkerVector> {
        val _x1: Float = obj.x1?.floatValueX(this) ?: 0f
        val _y1: Float = obj.y1?.floatValueY(this) ?: 0f
        val _x2: Float = obj.x2?.floatValueX(this) ?: 0f
        val _y2: Float = obj.y2?.floatValueY(this) ?: 0f

        return listOf(
            MarkerVector(_x1, _y1, _x2 - _x1, _y2 - _y1),
            MarkerVector(_x2, _y2, _x2 - _x1, _y2 - _y1)
        )
    }

    //==============================================================================
    private fun render(obj: PolyLine) {
        val s = state
        debug { "PolyLine render" }

        updateStyleForElement(s, obj)

        if (!display()) return
        if (!visible()) return
        if (!s.hasStroke && !s.hasFill) return

        concatTransform(canvas, obj)

        val numPoints = obj.points?.size ?: 0
        if (
            numPoints < 2 ||  // pointless
            numPoints % 2 == 1
        ) {
            // error
            return
        }

        val path = makePathAndBoundingBox(obj)!!
        updateParentBoundingBox(obj)

        path.fillType = state.fillType

        checkForGradientsAndPatterns(obj)
        checkForClipPath(obj)

        withNewRenderLayer(obj) { state ->
            if (state.hasFill) doFilledPath(obj, path)
            if (state.hasStroke) doStroke(path)

            renderMarkers(obj)
        }
    }

    private fun calculateMarkerPositions(obj: PolyLine): List<MarkerVector>? {
        val points = obj.points ?: return null

        val numPoints = points.size
        if (numPoints < 2) {
            return null
        }

        val markers: MutableList<MarkerVector> = ArrayList()
        var lastPos = MarkerVector(points[0], points[1], 0f, 0f)
        var x = 0f
        var y = 0f

        var i = 2
        while (i < numPoints) {
            x = points[i]
            y = points[i + 1]
            lastPos.add(x, y)
            markers.add(lastPos)
            lastPos = MarkerVector(x, y, x - lastPos.x, y - lastPos.y)
            i += 2
        }

        // Deal with last point
        if (obj is Polygon) {
            if (x != points[0] && y != points[1]) {
                x = points[0]
                y = points[1]
                lastPos.add(x, y)
                markers.add(lastPos)
                // Last marker point needs special handling because its orientation depends
                // on the orientation of the very first segment of the path
                val newPos = MarkerVector(x, y, x - lastPos.x, y - lastPos.y)
                newPos.add(markers[0])
                markers.add(newPos)
                markers[0] = newPos // Start marker is the same
            }
        } else {
            markers.add(lastPos)
        }
        return markers
    }


    //==============================================================================
    private fun render(obj: Polygon) {
        val s = state
        debug { "Polygon render" }

        updateStyleForElement(s, obj)

        if (!display()) return
        if (!visible()) return
        if (!s.hasStroke && !s.hasFill) return

        concatTransform(canvas, obj)

        val numPoints = obj.points?.size ?: 0
        if (numPoints < 2) return

        val path = makePathAndBoundingBox(obj)!!
        updateParentBoundingBox(obj)

        checkForGradientsAndPatterns(obj)
        checkForClipPath(obj)

        withNewRenderLayer(obj) { state ->
            if (state.hasFill) doFilledPath(obj, path)
            if (state.hasStroke) doStroke(path)

            renderMarkers(obj)
        }
    }


    //==============================================================================
    private fun render(obj: Text) {
        debug { "Text render" }

        updateStyleForElement(state, obj)

        if (!display()) return

        selectTypefaceAndFontStyling()

        concatTransform(canvas, obj)

        // Get the first coordinate pair from the lists in the x and y properties.
        var x = obj.x?.firstOrNull()?.floatValueX(this) ?: 0f
        val y = obj.y?.firstOrNull()?.floatValueY(this) ?: 0f
        val dx = obj.dx?.firstOrNull()?.floatValueX(this) ?: 0f
        val dy = obj.dy?.firstOrNull()?.floatValueY(this) ?: 0f

        // Handle text alignment
        val anchor = this.anchorPosition
        if (anchor != TextAnchor.Start) {
            val textWidth = calculateTextWidth(obj)
            x -= if (anchor == TextAnchor.Middle) {
                textWidth / 2
            } else {
                textWidth // 'End' (right justify)
            }
        }

        if (obj.boundingBox == null) {
            val proc = TextBoundsCalculator(x, y)
            enumerateTextSpans(obj, proc)
            obj.boundingBox = Box(proc.boundingBox)
        }
        updateParentBoundingBox(obj)

        checkForGradientsAndPatterns(obj)
        checkForClipPath(obj)

        withNewRenderLayer(obj) {
            enumerateTextSpans(obj, PlainTextDrawer(x + dx, y + dy))
        }
    }

    private fun resolveFontFromFontFamily(
        fontFamily: List<String>?,
        fontWidth: Float?,
        fontWeight: Float,
        fontStyle: FontStyle
    ): Typeface? {
        if (fontFamily == null) return null

        for (i in fontFamily.indices) {
            val fontName = fontFamily[i]
            // Check if this font entry is a generic font specifier
            val font = checkGenericFont(
                fontName = fontName,
                fontWeight = fontWeight,
                fontStyle = fontStyle
            ) ?:
                    // Otherwise, try loading the specified font
                    externalFileResolver?.resolveFont(
                        fontFamily = fontName,
                        fontWeight = fontWeight,
                        fontStyle = fontStyle.toString(),
                        fontStretch = fontWidth!!
                    )

            if (font != null) {
                Log.d(
                    "Typeface",
                    "$fontName: wt=${fontWeight} st=${fontStyle}: style=${font.style} bold=${font.isBold} italic=${font.isItalic}"
                )

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                    Log.d(
                        "Typeface",
                        "weight=${font.weight} sysfont='${font.systemFontFamilyName}'"
                    )
                }

                return font
            }
        }

        return null
    }

    private fun selectTypefaceAndFontStyling() {
        val state = state
        val style = state.style

        val fontWeight = style.fontWeight!!
        val fontStyle = style.fontStyle ?: FontStyle.normal

        val font: Typeface = resolveFontFromFontFamily(
            fontFamily = style.fontFamily,
            fontWidth = style.fontWidth,
            fontWeight = fontWeight,
            fontStyle = fontStyle,
        ) ?: checkGenericFont(
            fontName = DEFAULT_FONT_FAMILY,
            fontWeight = fontWeight,
            fontStyle = fontStyle
        )!!

        state.fillPaint.setTypeface(font)
        state.strokePaint.setTypeface(font)

        // Just in case this is a variable font, let's also set the fontVariationSettings
        // In order to get the desired font weight and style
        // Just in case this is a variable font, mirror the font-weight setting
        // as a backup, so we can get the weight we want.
        if (fontWeight >= Style.FONT_WEIGHT_BOLD && !font.isBold) {
            state.fontVariationSet.addSetting(
                CSSFontVariationSettings.VARIATION_WEIGHT,
                fontWeight
            )
        }
        // If italic has been specified, enable the 'ital' axis in case this is a
        // variable font and has one.
        if (fontStyle == FontStyle.italic && !font.isItalic) {
            state.fontVariationSet.addSetting(
                CSSFontVariationSettings.VARIATION_ITALIC,
                CSSFontVariationSettings.VARIATION_ITALIC_VALUE_ON
            )
        }
        // If oblique has been specified, enable the 'slnt' axis in case this is a
        // variable font and has one.
        if (fontStyle == FontStyle.oblique && !font.isItalic) {
            state.fontVariationSet.addSetting(
                CSSFontVariationSettings.VARIATION_SLANT,
                CSSFontVariationSettings.VARIATION_OBLIQUE_VALUE_ON
            )
        }

        // Apply the CSS font-variation-setting values if there are any
        state.fontVariationSet.applySettings(style.fontVariationSettings)

        val fontVariationSettings = state.fontVariationSet.toString()
        debug { "fontVariationSettings = $fontVariationSettings" }
        state.fillPaint.setFontVariationSettings(fontVariationSettings)
        state.strokePaint.setFontVariationSettings(fontVariationSettings)

        val fontFeatureSettings = state.fontFeatureSet.toString()
        debug { "fontFeatureSettings = $fontFeatureSettings" }
        state.fillPaint.setFontFeatureSettings(fontFeatureSettings)
        state.strokePaint.setFontFeatureSettings(fontFeatureSettings)
    }


    private val anchorPosition: TextAnchor?
        get() {
            val style = state.style
            val textAnchor = style.textAnchor

            if (style.direction == TextDirection.LTR || textAnchor == TextAnchor.Middle) {
                return textAnchor
            }

            // Handle RTL case where Start and End are reversed
            return if (textAnchor == TextAnchor.Start) {
                TextAnchor.End
            } else {
                TextAnchor.Start
            }
        }

    private open inner class PlainTextDrawer(
        @JvmField
        var x: Float,
        @JvmField
        var y: Float
    ) : TextProcessor() {

        override fun processText(text: String) {
            debug {
                "TextSequence render"
            }

            val state = state

            if (visible()) {
                // Android/Skia divides letterspacing and puts half before and after each letter.
                // We need to readjust initial text X position to counter that.
                val letterspacingAdj = state.style.letterSpacing!!.floatValue(this@SVGAndroidRenderer) / 2

                if (state.hasFill) {
                    canvas.drawText(
                        text,
                        x - letterspacingAdj,
                        y,
                        state.fillPaint
                    )
                }

                if (state.hasStroke) {
                    canvas.drawText(
                        text,
                        x - letterspacingAdj,
                        y,
                        state.strokePaint
                    )
                }
            }

            // Update the current text position
            x += measureText(text, state.fillPaint)
        }
    }


    //==============================================================================
    // Text sequence enumeration
    private abstract class TextProcessor {
        open fun doTextContainer(obj: TextContainer): Boolean {
            return true
        }

        abstract fun processText(text: String)
    }

    /*
    * Given a text container, recursively visit its children invoking the TextDrawer
    * handler for each segment of text found.
    */
    private fun enumerateTextSpans(obj: TextContainer, textProcessor: TextProcessor) {
        if (!display()) return

        val children = obj.getChildren()
        val lastIndex = children.lastIndex

        for (i in 0 .. lastIndex) {
            val child = children[i]

            if (child is TextSequence) {
                textProcessor.processText(
                    textXMLSpaceTransform(
                        text = child.text,
                        isFirstChild = i == 0,
                        isLastChild = i == lastIndex,
                        state.spacePreserve,
                    )
                )
            } else {
                processTextChild(
                    obj = child,
                    textProcessor = textProcessor
                )
            }
        }
    }

    private fun processTextChild(obj: SvgObject, textProcessor: TextProcessor) {
        // Ask the processor implementation if it wants to process this object
        if (!textProcessor.doTextContainer(obj as TextContainer)) return

        when (obj) {
            is TextPath -> {
                withNewState {
                    renderTextPath(obj)
                }
            }

            is TSpan -> {
                debug {
                    "TSpan render"
                }

                withNewState { s ->
                    val tSpan: TSpan = obj

                    updateStyleForElement(s, tSpan)

                    if (display()) {
                        selectTypefaceAndFontStyling()

                        // Get the first coordinate pair from the lists in the x and y properties.
                        var x = 0f
                        var y = 0f
                        var dx = 0f
                        var dy = 0f
                        val specifiedX = tSpan.x?.isNotEmpty() == true
                        if (textProcessor is PlainTextDrawer) {
                            x = tSpan.x?.firstOrNull()?.floatValueX(this) ?: textProcessor.x
                            y = tSpan.y?.firstOrNull()?.floatValueY(this) ?: textProcessor.y
                            dx = tSpan.dx?.firstOrNull()?.floatValueX(this) ?: 0f
                            dy = tSpan.dy?.firstOrNull()?.floatValueY(this) ?: 0f
                        }

                        // If x was specified on tspan, then we need to recalculate the alignment
                        if (specifiedX) {
                            val anchor = anchorPosition
                            if (anchor != TextAnchor.Start) {
                                val textWidth = calculateTextWidth(tSpan)
                                x -= if (anchor == TextAnchor.Middle) {
                                    textWidth / 2
                                } else {
                                    textWidth // 'End' (right justify)
                                }
                            }
                        }

                        checkForGradientsAndPatterns(tSpan.textRoot as SvgElement)

                        if (textProcessor is PlainTextDrawer) {
                            textProcessor.x = x + dx
                            textProcessor.y = y + dy
                        }

                        withNewRenderLayer(tSpan) {
                            enumerateTextSpans(tSpan, textProcessor)
                        }
                    }
                }
            }

            is SvgObject.TRef -> {
                withNewState { st ->
                    val tRef: SvgObject.TRef = obj

                    updateStyleForElement(st, tRef)

                    if (display()) {
                        checkForGradientsAndPatterns(tRef.textRoot as SvgElement)

                        // Locate the referenced object
                        val ref = obj.document.resolveIRI(tRef.href)
                        if (ref is TextContainer) {
                            val str = StringBuilder()
                            extractRawText(ref, str, state.spacePreserve)
                            if (str.isNotEmpty()) {
                                textProcessor.processText(str.toString())
                            }
                        } else {
                            error("Tref reference '%s' not found", tRef.href)
                        }
                    }
                }
            }
        }
    }


    //==============================================================================
    private fun renderTextPath(obj: TextPath) {
        debug { "TextPath render" }

        val s = state
        updateStyleForElement(s, obj)

        if (!display()) return
        if (!visible()) return

        selectTypefaceAndFontStyling()

        val ref = obj.document.resolveIRI(obj.href)
        if (ref == null) {
            error("TextPath reference '%s' not found", obj.href)
            return
        }

        val pathObj = ref as SvgObject.Path
        val path = PathConverter(pathObj.d).path

        pathObj.transform?.let { path.transform(it) }

        val measure = PathMeasure(path, false)

        var startOffset = obj.startOffset?.floatValue(this, measure.length) ?: 0f

        // Handle text alignment
        val anchor = this.anchorPosition
        if (anchor != TextAnchor.Start) {
            val textWidth = calculateTextWidth(obj)
            startOffset -= if (anchor == TextAnchor.Middle) {
                textWidth / 2
            } else {
                textWidth // 'End' (right justify)
            }
        }

        checkForGradientsAndPatterns(obj.textRoot as SvgElement)

        withNewRenderLayer(obj) {
            enumerateTextSpans(obj, PathTextDrawer(path, startOffset, 0f))
        }
    }

    private inner class PathTextDrawer(
        private val path: Path,
        x: Float,
        y: Float
    ) : PlainTextDrawer(x, y) {

        override fun processText(text: String) {
            val state = state
            if (visible()) {
                // Android/Skia divides letterspacing and puts half before and after each letter.
                // We need to readjust initial text X position to counter that.
                val letterspacingAdj =
                    state.style.letterSpacing!!.floatValue(this@SVGAndroidRenderer) / 2
                if (state.hasFill) {
                    canvas.drawTextOnPath(
                        /* text = */ text,
                        /* path = */ path,
                        /* hOffset = */ x - letterspacingAdj,
                        /* vOffset = */ y,
                        /* paint = */ state.fillPaint
                    )
                }

                if (state.hasStroke) {
                    canvas.drawTextOnPath(
                        /* text = */ text,
                        /* path = */ path,
                        /* hOffset = */ x - letterspacingAdj,
                        /* vOffset = */ y,
                        /* paint = */ state.strokePaint
                    )
                }
            }

            // Update the current text position
            x += measureText(text, state.fillPaint)
        }
    }

    //==============================================================================
    /*
    * Calculate the approximate width of this line of text.
    * To simplify, we will ignore font changes and just assume that all the text
    * uses the current font.
    */
    private fun calculateTextWidth(parentTextObj: TextContainer): Float {
        val proc = TextWidthCalculator()
        enumerateTextSpans(parentTextObj, proc)
        return proc.x
    }

    private inner class TextWidthCalculator : TextProcessor() {
        @JvmField
        var x: Float = 0f

        override fun processText(text: String) {
            x += measureText(text, state.fillPaint)
        }
    }

    //==============================================================================
    /*
    * Use the TextDrawer process to determine the bounds of a <text> element
    */
    private inner class TextBoundsCalculator(
        @JvmField
        var x: Float,
        @JvmField
        var y: Float
    ) : TextProcessor() {
        @JvmField
        val boundingBox: RectF = RectF()

        override fun doTextContainer(obj: TextContainer): Boolean {
            if (obj is TextPath) {
                // Since we cheat a bit with our textPath rendering, we need
                // to cheat a bit with our boundingBox calculation.
                val tPath: TextPath = obj
                val ref = obj.document.resolveIRI(tPath.href)
                if (ref == null) {
                    error("TextPath path reference '%s' not found", tPath.href)
                    return false
                }
                val pathObj = ref as SvgObject.Path
                val path = PathConverter(pathObj.d).path
                pathObj.transform?.let { path.transform(it) }
                val pathBounds = RectF()
                path.computeBounds(pathBounds, true)
                boundingBox.union(pathBounds)
                return false
            }
            return true
        }

        override fun processText(text: String) {
            if (visible()) {
                val rect = Rect()
                // Get text bounding box (for offset 0)
                state.fillPaint.getTextBounds(text, 0, text.length, rect)
                val textBounds = RectF(rect)
                // Adjust bounds to offset at text position
                textBounds.offset(x, y)
                // Merge with accumulated bounding box
                boundingBox.union(textBounds)
            }

            // Update the current text position
            x += measureText(text, state.fillPaint)
        }
    }


    //==============================================================================
    private fun render(obj: Symbol, viewPort: Box) {
        val s = state
        debug { "Symbol render" }

        if (viewPort.width == 0f || viewPort.height == 0f) return

        // "If attribute 'preserveAspectRatio' is not specified, then the effect is as if a value of xMidYMid meet were specified."
        val positioning: PreserveAspectRatio =
            obj.preserveAspectRatio ?: PreserveAspectRatio.LETTERBOX

        updateStyleForElement(s, obj)

        s.viewPort = viewPort

        if (s.style.overflow == false) {
            setClipRect(viewPort)
        }

        val viewBox = obj.viewBox
        if (viewBox != null) {
            canvas.concat(calculateViewBoxTransform(viewPort, viewBox, positioning))
            s.viewBox = viewBox
        } else {
            canvas.translate(viewPort.minX, viewPort.minY)
            s.viewBox = null
        }

        withNewRenderLayer(obj) {
            renderChildren(obj, true)
        }

        updateParentBoundingBox(obj)
    }


    //==============================================================================
    private fun render(obj: Image) {
        debug { "Image render" }

        val width = obj.width
        val height = obj.height
        if (width == null || width.isZero || height == null || height.isZero) return

        val href = obj.href ?: return

        // "If attribute 'preserveAspectRatio' is not specified, then the effect is as if a value of xMidYMid meet were specified."
        val positioning: PreserveAspectRatio =
            obj.preserveAspectRatio ?: PreserveAspectRatio.LETTERBOX

        // Locate the referenced image
        var image = checkForImageDataURL(href)
        if (image == null) {
            if (externalFileResolver == null) {
                return
            }

            image = externalFileResolver.resolveImage(href)
        }
        if (image == null) {
            error("Could not locate image '%s'", href)
            return
        }
        val imageNaturalSize = Box(
            minX = 0f,
            minY = 0f,
            width = image.getWidth().toFloat(),
            height = image.getHeight().toFloat()
        )

        val s = state
        updateStyleForElement(s, obj)

        if (!display()) return
        if (!visible()) return

        concatTransform(canvas, obj)

        val _x = obj.x?.floatValueX(this) ?: 0f
        val _y = obj.y?.floatValueY(this) ?: 0f
        val _w = width.floatValueX(this)
        val _h = height.floatValueX(this)
        val viewPort = Box(_x, _y, _w, _h).also {
            s.viewPort = it
        }

        if (s.style.overflow == false) {
            setClipRect(viewPort)
        }

        obj.boundingBox = viewPort
        updateParentBoundingBox(obj)

        checkForClipPath(obj)

        withNewRenderLayer(obj) {
            viewportFill()

            val saveCount = canvas.save()

            // Local transform from image's natural dimensions to the specified SVG dimensions
            canvas.concat(calculateViewBoxTransform(viewPort, imageNaturalSize, positioning))

            val bmPaint = Paint(
                if (s.style.imageRendering == RenderQuality.optimizeSpeed) {
                    0
                } else {
                    Paint.FILTER_BITMAP_FLAG
                }
            )
            canvas.drawBitmap(image, 0f, 0f, bmPaint)

            canvas.restoreToCount(saveCount)
        }
    }


    private fun display(): Boolean {
        return state.style.display ?: true
    }


    private fun visible(): Boolean {
        return state.style.visibility ?: true
    }

    /*
    * Calculate the transform required to fit the supplied viewBox into the current viewPort.
    * See spec section 7.8 for an explanation of how this works.
    * 
    * aspectRatioRule determines where the graphic is placed in the viewPort when aspect ratio
    *    is kept.  xMin means left justified, xMid is centred, xMax is right justified etc.
    * slice determines whether we see the whole image or not. True fill the whole viewport.
    *    If slice is false, the image will be "letter-boxed".
    * 
    * Note values in the two Box parameters would be in user units. If you pass values
    * that are in "objectBoundingBox" space, you will get incorrect results.
    */
    private fun calculateViewBoxTransform(
        viewPort: Box,
        viewBox: Box,
        positioning: PreserveAspectRatio?
    ): Matrix {
        val m = Matrix()

        if (positioning == null) {
            return m
        }

        val alignment = positioning.alignment ?: return m

        val xScale = viewPort.width / viewBox.width
        val yScale = viewPort.height / viewBox.height
        var xOffset = -viewBox.minX
        var yOffset = -viewBox.minY

        // 'none' means scale both dimensions to fit the viewport
        if (positioning == PreserveAspectRatio.STRETCH) {
            m.preTranslate(viewPort.minX, viewPort.minY)
            m.preScale(xScale, yScale)
            m.preTranslate(xOffset, yOffset)
            return m
        }

        // Otherwise, the aspect ratio of the image is kept.
        // What scale are we going to use?
        val scale = if (positioning.scale == PreserveAspectRatio.Scale.slice) {
            max(
                xScale,
                yScale
            )
        } else {
            min(xScale, yScale)
        }
        // What size will the image end up being? 
        val imageW = viewPort.width / scale
        val imageH = viewPort.height / scale
        // Determine final X position
        when (alignment) {
            PreserveAspectRatio.Alignment.xMidYMin,
            PreserveAspectRatio.Alignment.xMidYMid,
            PreserveAspectRatio.Alignment.xMidYMax -> xOffset -= (viewBox.width - imageW) / 2

            PreserveAspectRatio.Alignment.xMaxYMin,
            PreserveAspectRatio.Alignment.xMaxYMid,
            PreserveAspectRatio.Alignment.xMaxYMax -> xOffset -= viewBox.width - imageW
            else -> {}
        }
        // Determine final Y position
        when (alignment) {
            PreserveAspectRatio.Alignment.xMinYMid,
            PreserveAspectRatio.Alignment.xMidYMid,
            PreserveAspectRatio.Alignment.xMaxYMid -> yOffset -= (viewBox.height - imageH) / 2

            PreserveAspectRatio.Alignment.xMinYMax,
            PreserveAspectRatio.Alignment.xMidYMax,
            PreserveAspectRatio.Alignment.xMaxYMax -> yOffset -= viewBox.height - imageH
            else -> {}
        }

        m.preTranslate(viewPort.minX, viewPort.minY)
        m.preScale(scale, scale)
        m.preTranslate(xOffset, yOffset)
        return m
    }


    /*
    * Updates the global style state with the style defined by the current object.
    * Will also update the current paints etc. where appropriate.
    */
    private fun updateStyle(state: RendererState, sourceStyle: Style) {
        val targetStyle = state.style

        // Now update each style property we know about
        if (sourceStyle.isSpecified(Style.SPECIFIED_COLOR)) {
            targetStyle.color = sourceStyle.color
        }

        if (sourceStyle.isSpecified(Style.SPECIFIED_OPACITY)) {
            targetStyle.opacity = sourceStyle.opacity
        }

        if (sourceStyle.isSpecified(Style.SPECIFIED_FILL)) {
            val fill = sourceStyle.fill
            targetStyle.fill = fill
            state.hasFill = fill != null && fill != ColorValue.TRANSPARENT
        }

        if (sourceStyle.isSpecified(Style.SPECIFIED_FILL_OPACITY)) {
            targetStyle.fillOpacity = sourceStyle.fillOpacity
        }

        // If either fill or its opacity has changed, update the fillPaint
        if (sourceStyle.isSpecified(Style.SPECIFIED_FILL or Style.SPECIFIED_FILL_OPACITY or Style.SPECIFIED_COLOR or Style.SPECIFIED_OPACITY)) {
            setPaintColor(state, true, targetStyle.fill)
        }

        if (sourceStyle.isSpecified(Style.SPECIFIED_FILL_RULE)) {
            targetStyle.fillRule = sourceStyle.fillRule
        }

        if (sourceStyle.isSpecified(Style.SPECIFIED_STROKE)) {
            val stroke = sourceStyle.stroke
            targetStyle.stroke = stroke
            state.hasStroke = stroke != null && stroke != ColorValue.TRANSPARENT
        }

        if (sourceStyle.isSpecified(Style.SPECIFIED_STROKE_OPACITY)) {
            targetStyle.strokeOpacity = sourceStyle.strokeOpacity
        }

        if (sourceStyle.isSpecified(Style.SPECIFIED_STROKE or Style.SPECIFIED_STROKE_OPACITY or Style.SPECIFIED_COLOR or Style.SPECIFIED_OPACITY)) {
            setPaintColor(state, false, targetStyle.stroke)
        }

        if (sourceStyle.isSpecified(Style.SPECIFIED_VECTOR_EFFECT)) {
            targetStyle.vectorEffect = sourceStyle.vectorEffect
        }

        if (sourceStyle.isSpecified(Style.SPECIFIED_STROKE_WIDTH)) {
            val strokeWidth = sourceStyle.strokeWidth!!
            targetStyle.strokeWidth = strokeWidth
            // Handle zero stroke widths specially. Spec says they should result in no stroke,
            // however in Android, a 1px line is rendered for Paint.setStrokeWidth(0).
            if (!strokeWidth.isZero) {
                state.strokePaint.strokeWidth = strokeWidth.floatValue(this)
            } else {
                state.hasStroke = false
            }
        }

        if (sourceStyle.isSpecified(Style.SPECIFIED_STROKE_LINECAP)) {
            val strokeLineCap = sourceStyle.strokeLineCap!!
            targetStyle.strokeLineCap = strokeLineCap
            state.strokePaint.strokeCap = when (strokeLineCap) {
                LineCap.Butt -> Paint.Cap.BUTT
                LineCap.Round -> Paint.Cap.ROUND
                LineCap.Square -> Paint.Cap.SQUARE
            }
        }

        if (sourceStyle.isSpecified(Style.SPECIFIED_STROKE_LINEJOIN)) {
            val strokeLineJoin = sourceStyle.strokeLineJoin!!
            targetStyle.strokeLineJoin = strokeLineJoin
            state.strokePaint.strokeJoin = when (strokeLineJoin) {
                LineJoin.Miter -> Paint.Join.MITER
                LineJoin.Round -> Paint.Join.ROUND
                LineJoin.Bevel -> Paint.Join.BEVEL
            }
        }

        if (sourceStyle.isSpecified(Style.SPECIFIED_STROKE_MITERLIMIT)) {
            // FIXME: must be >= 0
            val strokeMiterLimit = sourceStyle.strokeMiterLimit!!
            targetStyle.strokeMiterLimit = strokeMiterLimit
            state.strokePaint.strokeMiter = strokeMiterLimit
        }

        if (sourceStyle.isSpecified(Style.SPECIFIED_STROKE_DASHARRAY)) {
            targetStyle.strokeDashArray = sourceStyle.strokeDashArray
        }

        if (sourceStyle.isSpecified(Style.SPECIFIED_STROKE_DASHOFFSET)) {
            targetStyle.strokeDashOffset = sourceStyle.strokeDashOffset
        }

        if (sourceStyle.isSpecified(Style.SPECIFIED_STROKE_DASHARRAY or Style.SPECIFIED_STROKE_DASHOFFSET)) {
            // Either the dash array or dash offset has changed.
            val strokeDashArray = targetStyle.strokeDashArray
            if (strokeDashArray == null) {
                state.strokePaint.setPathEffect(null)
            } else {
                var intervalSum = 0f
                val n = strokeDashArray.size
                // SVG dash arrays can be odd length, whereas Android dash arrays must have an even length.
                // So we solve the problem by doubling the array length.
                val arrayLen = if (n % 2 == 0) n else n * 2
                val intervals = FloatArray(arrayLen)
                for (i in 0..<arrayLen) {
                    intervals[i] = strokeDashArray[i % n].floatValue(this)
                    intervalSum += intervals[i]
                }
                if (intervalSum == 0f) {
                    state.strokePaint.setPathEffect(null)
                } else {
                    var offset = targetStyle.strokeDashOffset!!.floatValue(this)
                    if (offset < 0) {
                        // SVG offsets can be negative. Not sure if Android ones can be.
                        // Just in case we will convert it.
                        offset = intervalSum + offset % intervalSum
                    }
                    state.strokePaint.setPathEffect(DashPathEffect(intervals, offset))
                }
            }
        }

        if (sourceStyle.isSpecified(Style.SPECIFIED_FONT_SIZE)) {
            val currentFontSize = this.currentFontSize
            val fontSize = sourceStyle.fontSize!!
            targetStyle.fontSize = fontSize
            state.fillPaint.textSize = fontSize.floatValue(this, currentFontSize)
            state.strokePaint.textSize = fontSize.floatValue(this, currentFontSize)
        }

        if (sourceStyle.isSpecified(Style.SPECIFIED_FONT_FAMILY)) {
            targetStyle.fontFamily = sourceStyle.fontFamily
        }

        if (sourceStyle.isSpecified(Style.SPECIFIED_FONT_WEIGHT)) {
            // Font weights are 0..1000
            // Relative weight rules from CSS-Fonts-4: https://www.w3.org/TR/css-fonts-4/#relative-weights
            when (sourceStyle.fontWeight) {
                Style.FONT_WEIGHT_LIGHTER -> {
                    val fw = targetStyle.fontWeight!!
                    targetStyle.fontWeight = when {
                        fw in 100f..<550f -> {
                            // FIXME clamp instead of ignoring < 100
                            100f
                        }

                        fw in 550f..<750f -> {
                            400f
                        }

                        fw >= 750f -> {
                            700f
                        }

                        else -> {
                            fw
                        }
                    }
                }

                Style.FONT_WEIGHT_BOLDER -> {
                    val fw = targetStyle.fontWeight!!
                    targetStyle.fontWeight = when {
                        fw < 350f -> {
                            400f
                        }

                        fw in 350f..<550f -> {
                            700f
                        }

                        fw in 550f..<900f -> {
                            900f
                        }

                        else -> {
                            fw
                        }
                    }
                }

                else -> {
                    targetStyle.fontWeight = sourceStyle.fontWeight
                }
            }
        }

        if (sourceStyle.isSpecified(Style.SPECIFIED_FONT_STYLE)) {
            targetStyle.fontStyle = sourceStyle.fontStyle
        }

        if (sourceStyle.isSpecified(Style.SPECIFIED_FONT_WIDTH)) {
            // Typical font stretch values are 50...200 (percent)
            targetStyle.fontWidth = sourceStyle.fontWidth
        }

        if (sourceStyle.isSpecified(Style.SPECIFIED_TEXT_DECORATION)) {
            val textDecoration = sourceStyle.textDecoration!!
            targetStyle.textDecoration = textDecoration
            state.fillPaint.isStrikeThruText = textDecoration == TextDecoration.LineThrough
            state.fillPaint.isUnderlineText = textDecoration == TextDecoration.Underline
            // There is a bug in Android <= JELLY_BEAN (16) that causes stroked underlines to
            // not be drawn properly. See bug (39511). This has been fixed in JELLY_BEAN_MR1 (4.2)
            state.strokePaint.isStrikeThruText = textDecoration == TextDecoration.LineThrough
            state.strokePaint.isUnderlineText = textDecoration == TextDecoration.Underline
        }

        if (sourceStyle.isSpecified(Style.SPECIFIED_DIRECTION)) {
            targetStyle.direction = sourceStyle.direction
        }

        if (sourceStyle.isSpecified(Style.SPECIFIED_TEXT_ANCHOR)) {
            targetStyle.textAnchor = sourceStyle.textAnchor
        }

        if (sourceStyle.isSpecified(Style.SPECIFIED_OVERFLOW)) {
            targetStyle.overflow = sourceStyle.overflow
        }

        if (sourceStyle.isSpecified(Style.SPECIFIED_MARKER_START)) {
            targetStyle.markerStart = sourceStyle.markerStart
        }

        if (sourceStyle.isSpecified(Style.SPECIFIED_MARKER_MID)) {
            targetStyle.markerMid = sourceStyle.markerMid
        }

        if (sourceStyle.isSpecified(Style.SPECIFIED_MARKER_END)) {
            targetStyle.markerEnd = sourceStyle.markerEnd
        }

        if (sourceStyle.isSpecified(Style.SPECIFIED_DISPLAY)) {
            targetStyle.display = sourceStyle.display
        }

        if (sourceStyle.isSpecified(Style.SPECIFIED_VISIBILITY)) {
            targetStyle.visibility = sourceStyle.visibility
        }

        if (sourceStyle.isSpecified(Style.SPECIFIED_CLIP)) {
            targetStyle.clip = sourceStyle.clip
        }

        if (sourceStyle.isSpecified(Style.SPECIFIED_CLIP_PATH)) {
            targetStyle.clipPath = sourceStyle.clipPath
        }

        if (sourceStyle.isSpecified(Style.SPECIFIED_CLIP_RULE)) {
            targetStyle.clipRule = sourceStyle.clipRule
        }

        if (sourceStyle.isSpecified(Style.SPECIFIED_MASK)) {
            targetStyle.mask = sourceStyle.mask
        }

        if (sourceStyle.isSpecified(Style.SPECIFIED_MASK_TYPE)) {
            targetStyle.maskType = sourceStyle.maskType
        }

        if (sourceStyle.isSpecified(Style.SPECIFIED_STOP_COLOR)) {
            targetStyle.stopColor = sourceStyle.stopColor
        }

        if (sourceStyle.isSpecified(Style.SPECIFIED_STOP_OPACITY)) {
            targetStyle.stopOpacity = sourceStyle.stopOpacity
        }

        if (sourceStyle.isSpecified(Style.SPECIFIED_VIEWPORT_FILL)) {
            targetStyle.viewportFill = sourceStyle.viewportFill
        }

        if (sourceStyle.isSpecified(Style.SPECIFIED_VIEWPORT_FILL_OPACITY)) {
            targetStyle.viewportFillOpacity = sourceStyle.viewportFillOpacity
        }

        if (sourceStyle.isSpecified(Style.SPECIFIED_IMAGE_RENDERING)) {
            targetStyle.imageRendering = sourceStyle.imageRendering
        }

        if (sourceStyle.isSpecified(Style.SPECIFIED_ISOLATION)) {
            targetStyle.isolation = sourceStyle.isolation
        }

        if (sourceStyle.isSpecified(Style.SPECIFIED_MIX_BLEND_MODE)) {
            targetStyle.mixBlendMode = sourceStyle.mixBlendMode
        }

        if (sourceStyle.isSpecified(Style.SPECIFIED_FONT_KERNING)) {
            val fontKerning = sourceStyle.fontKerning
            targetStyle.fontKerning = fontKerning
            state.fontFeatureSet.applyKerning(fontKerning)
        }

        if (sourceStyle.isSpecified(Style.SPECIFIED_FONT_FEATURE_SETTINGS)) {
            val fontFeatureSettings = sourceStyle.fontFeatureSettings
            targetStyle.fontFeatureSettings = fontFeatureSettings
            state.fontFeatureSet.applySettings(fontFeatureSettings)
        }

        if (sourceStyle.isSpecified(Style.SPECIFIED_FONT_VARIANT_LIGATURES)) {
            val fontVariantLigatures = sourceStyle.fontVariantLigatures
            targetStyle.fontVariantLigatures = fontVariantLigatures
            state.fontFeatureSet.applySettings(fontVariantLigatures)
        }

        if (sourceStyle.isSpecified(Style.SPECIFIED_FONT_VARIANT_POSITION)) {
            val fontVariantPosition = sourceStyle.fontVariantPosition
            targetStyle.fontVariantPosition = fontVariantPosition
            state.fontFeatureSet.applySettings(fontVariantPosition)
        }

        if (sourceStyle.isSpecified(Style.SPECIFIED_FONT_VARIANT_CAPS)) {
            val fontVariantCaps = sourceStyle.fontVariantCaps
            targetStyle.fontVariantCaps = fontVariantCaps
            state.fontFeatureSet.applySettings(fontVariantCaps)
        }

        if (sourceStyle.isSpecified(Style.SPECIFIED_FONT_VARIANT_NUMERIC)) {
            val fontVariantNumeric = sourceStyle.fontVariantNumeric
            targetStyle.fontVariantNumeric = fontVariantNumeric
            state.fontFeatureSet.applySettings(fontVariantNumeric)
        }

        if (sourceStyle.isSpecified(Style.SPECIFIED_FONT_VARIANT_EAST_ASIAN)) {
            val fontVariantEastAsian = sourceStyle.fontVariantEastAsian
            targetStyle.fontVariantEastAsian = fontVariantEastAsian
            state.fontFeatureSet.applySettings(fontVariantEastAsian)
        }

        if (sourceStyle.isSpecified(Style.SPECIFIED_FONT_VARIATION_SETTINGS)) {
            val fontVariationSettings = sourceStyle.fontVariationSettings
            targetStyle.fontVariationSettings = fontVariationSettings
            state.fontVariationSet.applySettings(fontVariationSettings)
        }

        if (sourceStyle.isSpecified(Style.SPECIFIED_WRITING_MODE)) {
            targetStyle.writingMode = sourceStyle.writingMode
        }

        if (sourceStyle.isSpecified(Style.SPECIFIED_GLYPH_ORIENTATION_VERTICAL)) {
            targetStyle.glyphOrientationVertical = sourceStyle.glyphOrientationVertical
        }

        if (sourceStyle.isSpecified(Style.SPECIFIED_TEXT_ORIENTATION)) {
            targetStyle.textOrientation = sourceStyle.textOrientation
        }

        if (sourceStyle.isSpecified(Style.SPECIFIED_LETTER_SPACING)) {
            val letterSpacing = sourceStyle.letterSpacing!!
            targetStyle.letterSpacing = letterSpacing
            // Note: Paint.setLetterSpacing() takes a value in ems.

            var spacing = letterSpacing.floatValue(this)
            if (spacing > 0) {
                val currentFontSize = currentFontSize
                if (currentFontSize > 0) {
                    spacing /= currentFontSize
                }
            }
            state.fillPaint.letterSpacing = spacing
            state.strokePaint.letterSpacing = spacing
        }

        if (sourceStyle.isSpecified(Style.SPECIFIED_WORD_SPACING)) {
            val wordSpacing = sourceStyle.wordSpacing!!
            targetStyle.wordSpacing = wordSpacing
            if (SUPPORTS_PAINT_WORD_SPACING) {
                val spacing = wordSpacing.floatValue(this)
                state.fillPaint.wordSpacing = spacing
                state.strokePaint.wordSpacing = spacing
            }
        }

        if (sourceStyle.isSpecified(Style.SPECIFIED_FILTER)) {
            targetStyle.filter = sourceStyle.filter
        }

        if (sourceStyle.isSpecified(Style.SPECIFIED_FLOOD_COLOR)) {
            targetStyle.floodColor = sourceStyle.floodColor
        }

        if (sourceStyle.isSpecified(Style.SPECIFIED_FLOOD_OPACITY)) {
            targetStyle.floodOpacity = sourceStyle.floodOpacity
        }
    }

    private fun setClipRect(box: Box) {
        setClipRect(
            minX = box.minX,
            minY = box.minY,
            width = box.width,
            height = box.height
        )
    }

    private fun setClipRect(minX: Float, minY: Float, width: Float, height: Float) {
        var left = minX
        var top = minY
        var right = minX + width
        var bottom = minY + height

        val clip = state.style.clip
        if (clip != null) {
            left += clip.left.floatValueX(this)
            top += clip.top.floatValueY(this)
            right -= clip.right.floatValueX(this)
            bottom -= clip.bottom.floatValueY(this)
        }

        canvas.clipRect(left, top, right, bottom)
    }

    /*
    * Viewport fill color. A new feature in SVG 1.2.
    */
    private fun viewportFill() {
        val style = state.style

        var col: Int = when (val viewportFill = style.viewportFill) {
            is ColorValue -> {
                viewportFill.value
            }

            is CurrentColor -> {
                style.color!!.value
            }

            else -> {
                return
            }
        }

        val viewportFillOpacity = style.viewportFillOpacity
        if (viewportFillOpacity != null) {
            col = col.colorWithOpacity(viewportFillOpacity)
        }

        canvas.drawColor(col)
    }

    //==============================================================================
    /*
    *  Convert an internal PathDefinition to an android.graphics.Path object
    */
    internal class PathConverter internal constructor(pathDef: PathDefinition?) : PathInterface {
        @JvmField
        val path: Path = Path()

        @JvmField
        var lastX: Float = 0f

        @JvmField
        var lastY: Float = 0f

        init {
            pathDef?.enumeratePath(this)
        }

        override fun moveTo(x: Float, y: Float) {
            path.moveTo(x, y)
            lastX = x
            lastY = y
        }

        override fun lineTo(x: Float, y: Float) {
            path.lineTo(x, y)
            lastX = x
            lastY = y
        }

        override fun cubicTo(x1: Float, y1: Float, x2: Float, y2: Float, x3: Float, y3: Float) {
            path.cubicTo(x1, y1, x2, y2, x3, y3)
            lastX = x3
            lastY = y3
        }

        override fun quadTo(x1: Float, y1: Float, x2: Float, y2: Float) {
            path.quadTo(x1, y1, x2, y2)
            lastX = x2
            lastY = y2
        }

        override fun arcTo(
            rx: Float,
            ry: Float,
            xAxisRotation: Float,
            largeArcFlag: Boolean,
            sweepFlag: Boolean,
            x: Float,
            y: Float
        ) {
            arcTo(
                lastX = lastX,
                lastY = lastY,
                rx = rx,
                ry = ry,
                angle = xAxisRotation,
                largeArcFlag = largeArcFlag,
                sweepFlag = sweepFlag,
                x = x,
                y = y,
                pather = this
            )
            lastX = x
            lastY = y
        }

        override fun close() {
            path.close()
        }
    }


    //==============================================================================
    // Marker handling
    //==============================================================================
    private class MarkerVector(
        @JvmField
        val x: Float,
        @JvmField
        val y: Float,
        dx: Float,
        dy: Float
    ) {
        @JvmField
        var dx: Float = 0f

        @JvmField
        var dy: Float = 0f

        @JvmField
        var isAmbiguous: Boolean = false

        init {
            // normalise direction vector
            val len = hypot(dx, dy)
            if (len != 0f) {
                this.dx = dx / len
                this.dy = dy / len
            }
        }

        fun add(x: Float, y: Float) {
            // In order to get accurate angles, we have to normalize
            // all vectors before we add them.  As long as they are
            // all the same length, the angles will work out correctly.
            var dx = x - this.x
            var dy = y - this.y
            val len = hypot(dx, dy)
            if (len != 0f) {
                dx /= len
                dy /= len
            }
            // Check for degenerate result where the two unit vectors canceled each other out
            if (dx == -this.dx && dy == -this.dy) {
                this.isAmbiguous = true
                // Choose one of the perpendiculars now. We will get a chance to switch it later.
                this.dx = -dy
                this.dy = dx
            } else {
                this.dx += dx
                this.dy += dy
            }
        }

        fun add(v2: MarkerVector) {
            // Check for degenerate result where the two unit vectors canceled each other out
            if (v2.dx == -this.dx && v2.dy == -this.dy) {
                this.isAmbiguous = true
                // Choose one of the perpendiculars now. We will get a chance to switch it later.
                this.dx = -v2.dy
                this.dy = v2.dx
            } else {
                this.dx += v2.dx
                this.dy += v2.dy
            }
        }


        override fun toString(): String {
            return "($x,$y $dx,$dy)"
        }
    }

    /*
    *  Calculates the positions and orientations of any markers that should be placed on the given path.
    */
    private inner class MarkerPositionCalculator(pathDef: PathDefinition?) : PathInterface {
        @JvmField
        val markers: MutableList<MarkerVector> = ArrayList()

        private var startX = 0f
        private var startY = 0f
        private var lastPos: MarkerVector? = null
        private var startArc = false
        private var normalCubic = true
        private var subpathStartIndex = -1
        private var closePathReAdjustPending = false


        init {
            if (pathDef != null) {
                // Generate and add markers for the first N-1 points
                pathDef.enumeratePath(this)

                if (closePathReAdjustPending) {
                    // Now correct the start and end marker points of the subpath.
                    // They should both be oriented as if this was a midpoint (ie sum the vectors).
                    val lastPos = lastPos!!
                    lastPos.add(markers[subpathStartIndex])
                    // Overwrite start marker. Other (end) marker will be written on exit or at start of next subpath.
                    markers[subpathStartIndex] = lastPos
                    closePathReAdjustPending = false
                }
                // Add the marker for the pending last point
                lastPos?.let { markers.add(it) }
            }
        }

        override fun moveTo(x: Float, y: Float) {
            if (closePathReAdjustPending) {
                // Now correct the start and end marker points of the subpath.
                // They should both be oriented as if this was a midpoint (ie sum the vectors).
                val lastPos = lastPos!!
                lastPos.add(markers[subpathStartIndex])
                // Overwrite start marker. Other (end) marker will be written on exit or at start of next subpath.
                markers[subpathStartIndex] = lastPos
                closePathReAdjustPending = false
            }
            lastPos?.let { markers.add(it) }
            startX = x
            startY = y
            lastPos = MarkerVector(x, y, 0f, 0f)
            subpathStartIndex = markers.size
        }

        override fun lineTo(x: Float, y: Float) {
            val prevPos = lastPos!!
            prevPos.add(x, y)
            markers.add(prevPos)
            lastPos = MarkerVector(x, y, x - prevPos.x, y - prevPos.y)
            closePathReAdjustPending = false
        }

        override fun cubicTo(x1: Float, y1: Float, x2: Float, y2: Float, x3: Float, y3: Float) {
            if (normalCubic || startArc) {
                val prevPos = lastPos!!
                prevPos.add(x1, y1)
                markers.add(prevPos)
                startArc = false
            }
            lastPos = MarkerVector(x3, y3, x3 - x2, y3 - y2)
            closePathReAdjustPending = false
        }

        override fun quadTo(x1: Float, y1: Float, x2: Float, y2: Float) {
            val prevPos = lastPos!!
            prevPos.add(x1, y1)
            markers.add(prevPos)
            lastPos = MarkerVector(x2, y2, x2 - x1, y2 - y1)
            closePathReAdjustPending = false
        }

        override fun arcTo(
            rx: Float,
            ry: Float,
            xAxisRotation: Float,
            largeArcFlag: Boolean,
            sweepFlag: Boolean,
            x: Float,
            y: Float
        ) {
            // We'll piggyback on the arc->bezier conversion to get our start and end vectors
            startArc = true
            normalCubic = false
            val lastPos = lastPos!!
            arcTo(
                lastPos.x,
                lastPos.y,
                rx,
                ry,
                xAxisRotation,
                largeArcFlag,
                sweepFlag,
                x,
                y,
                this
            )
            normalCubic = true
            closePathReAdjustPending = false
        }

        override fun close() {
            markers.add(lastPos!!)
            lineTo(startX, startY)
            // We may need to readjust the first and last markers on this subpath so that
            // the orientation is a sum of the inward and outward vectors.
            // But this only happens if the path ends or the next subpath starts with a Move.
            // See description of "orient" attribute in section 11.6.2.
            closePathReAdjustPending = true
        }
    }

    private fun renderMarkers(obj: GraphicsElement) {
        val state = state
        val style = state.style
        if (style.markerStart == null && style.markerMid == null && style.markerEnd == null) {
            return
        }

        val _markerStart: Marker? = resolveMarkerReference(obj, style.markerStart)
        val _markerMid: Marker? = resolveMarkerReference(obj, style.markerMid)
        val _markerEnd: Marker? = resolveMarkerReference(obj, style.markerEnd)

        val markers = when (obj) {
            is SvgObject.Path -> MarkerPositionCalculator(obj.d).markers
            is Line -> calculateMarkerPositions(obj)
            else -> {
                // PolyLine and Polygon
                calculateMarkerPositions(obj as PolyLine)
            }
        }

        if (markers == null) return

        val markerCount = markers.size
        if (markerCount == 0) return

        // We don't want the markers to inherit themselves as markers, otherwise we get infinite recursion. 
        style.markerEnd = null
        style.markerMid = null
        style.markerStart = null

        if (_markerStart != null) {
            renderMarker(_markerStart, markers[0])
        }

        if (_markerMid != null && markers.size > 2) {
            var lastPos = markers[0]
            var thisPos = markers[1]

            for (i in 1..<markerCount - 1) {
                val nextPos = markers[i + 1]
                if (thisPos.isAmbiguous) {
                    thisPos = realignMarkerMid(lastPos, thisPos, nextPos)
                }
                renderMarker(_markerMid, thisPos)
                lastPos = thisPos
                thisPos = nextPos
            }
        }

        if (_markerEnd != null) {
            renderMarker(_markerEnd, markers[markerCount - 1])
        }
    }

    /*
    * Render the given marker type at the given position
    */
    private fun renderMarker(marker: Marker, pos: MarkerVector) {
        withNewState {
            var angle = 0f

            // Calculate vector angle
            val orient = marker.orient
            if (orient != null) {
                if (orient.isNaN())  // Indicates "auto"
                {
                    if (pos.dx != 0f || pos.dy != 0f) {
                        angle = atan2(pos.dy.toDouble(), pos.dx.toDouble()).toDegrees().toFloat()
                    }
                } else {
                    angle = orient
                }
            }
            // Calculate units scale
            val unitsScale: Float = if (marker.markerUnitsAreUser) {
                1f
            } else {
                state.style.strokeWidth!!.floatValue(dPI)
            }

            // "Properties inherit into the <marker> element from its ancestors; properties do not
            // inherit from the element referencing the <marker> element." (sect 11.6.2)
            state = findInheritFromAncestorState(marker)

            val m = Matrix()
            m.preTranslate(pos.x, pos.y)
            m.preRotate(angle)
            m.preScale(unitsScale, unitsScale)
            // Scale and/or translate the marker to fit in the marker viewPort
            val _refX = marker.refX?.floatValueX(this) ?: 0f
            val _refY = marker.refY?.floatValueY(this) ?: 0f
            val _markerWidth = marker.markerWidth?.floatValueX(this) ?: 3f
            val _markerHeight = marker.markerHeight?.floatValueY(this) ?: 3f

            val viewBox = marker.viewBox
            if (viewBox != null) {
                // We now do a simplified version of calculateViewBoxTransform().  For now we will
                // ignore the alignment setting because refX and refY have to be aligned with the
                // marker position, and alignment would complicate the calculations.
                var xScale: Float
                var yScale: Float

                xScale = _markerWidth / viewBox.width
                yScale = _markerHeight / viewBox.height

                // If we are keeping aspect ratio, then set both scales to the appropriate value depending on 'slice'
                val positioning: PreserveAspectRatio =
                    marker.preserveAspectRatio ?: PreserveAspectRatio.LETTERBOX
                if (positioning != PreserveAspectRatio.STRETCH) {
                    val aspectScale = if (positioning.scale == PreserveAspectRatio.Scale.slice) {
                        max(
                            xScale,
                            yScale
                        )
                    } else {
                        min(xScale, yScale)
                    }
                    yScale = aspectScale
                    xScale = yScale
                }

                //m.preTranslate(viewPort.minX, viewPort.minY);
                m.preTranslate(-_refX * xScale, -_refY * yScale)
                canvas.concat(m)

                // Now we need to take account of alignment setting, because it affects the
                // size and position of the clip rectangle.
                val imageW = viewBox.width * xScale
                val imageH = viewBox.height * yScale
                var xOffset = 0f
                var yOffset = 0f
                when (positioning.alignment) {
                    PreserveAspectRatio.Alignment.xMidYMin,
                    PreserveAspectRatio.Alignment.xMidYMid,
                    PreserveAspectRatio.Alignment.xMidYMax -> xOffset -= (_markerWidth - imageW) / 2
                    PreserveAspectRatio.Alignment.xMaxYMin,
                    PreserveAspectRatio.Alignment.xMaxYMid,
                    PreserveAspectRatio.Alignment.xMaxYMax -> xOffset -= _markerWidth - imageW
                    else -> {}
                }
                // Determine final Y position
                when (positioning.alignment) {
                    PreserveAspectRatio.Alignment.xMinYMid,
                    PreserveAspectRatio.Alignment.xMidYMid,
                    PreserveAspectRatio.Alignment.xMaxYMid -> yOffset -= (_markerHeight - imageH) / 2
                    PreserveAspectRatio.Alignment.xMinYMax,
                    PreserveAspectRatio.Alignment.xMidYMax,
                    PreserveAspectRatio.Alignment.xMaxYMax -> yOffset -= _markerHeight - imageH
                    else -> {}
                }

                if (!state.style.overflow!!) {
                    setClipRect(xOffset, yOffset, _markerWidth, _markerHeight)
                }

                m.reset()
                m.preScale(xScale, yScale)
                canvas.concat(m)
            } else {
                // No viewBox provided

                m.preTranslate(-_refX, -_refY)
                canvas.concat(m)

                if (!state.style.overflow!!) {
                    setClipRect(0f, 0f, _markerWidth, _markerHeight)
                }
            }

            withNewRenderLayer(marker) {
                renderChildren(marker, false)
            }
        }
    }

    /*
    * Determine an elements style based on its ancestors in the tree rather than
    * it's render time ancestors.
    */
    private fun findInheritFromAncestorState(obj: SvgObject): RendererState {
        val newState = RendererState()
        updateStyle(newState, Style.getDefaultStyle())
        return findInheritFromAncestorState(obj, newState)
    }

    private fun findInheritFromAncestorState(
        obj: SvgObject,
        newState: RendererState
    ): RendererState {
        var obj: SvgObject = obj
        val ancestors: ArrayList<SvgElementBase> = ArrayList()

        // Traverse up the document tree adding element styles to a list.
        while (true) {
            if (obj is SvgElementBase) {
                ancestors.add(0, obj)
            }
            obj = obj.parent ?: break
        }


        // Now apply the ancestor styles in reverse order to a fresh RendererState object
        ancestors.forEachElement { ancestor ->
            updateStyleForElement(newState, ancestor)
        }

        // Caller may also need a valid viewBox in order to calculate percentages
        val oldState = state
        newState.viewBox = oldState.viewBox
        newState.viewPort = oldState.viewPort
        return newState
    }


    //==============================================================================
    // Gradients
    //==============================================================================
    /*
    * Check for gradient fills or strokes on this object.  These are always relative
    * to the object, so can't be preconfigured. They have to be initialized at the
    * time each object is rendered.
    */
    private fun checkForGradientsAndPatterns(obj: SvgElement) {
        val style = state.style

        val fill = style.fill
        if (fill is PaintReference) {
            decodePaintReference(true, obj.boundingBox!!, fill)
        }

        val stroke = style.stroke
        if (stroke is PaintReference) {
            decodePaintReference(false, obj.boundingBox!!, stroke)
        }
    }

    /*
    * Takes a PaintReference object and generates an appropriate Android Shader object from it.
    */
    private fun decodePaintReference(
        isFill: Boolean,
        boundingBox: Box,
        paintRef: PaintReference
    ) {
        val state = state
        val ref = document.resolveIRI(paintRef.href)
        if (ref == null) {
            error("%s reference '%s' not found", if (isFill) "Fill" else "Stroke", paintRef.href)
            val fallback = paintRef.fallback
            if (fallback != null) {
                setPaintColor(state, isFill, fallback)
            } else {
                if (isFill) {
                    state.hasFill = false
                } else {
                    state.hasStroke = false
                }
            }
            return
        }

        when (ref) {
            is SvgLinearGradient -> makeLinearGradient(isFill, boundingBox, ref)
            is SvgRadialGradient -> makeRadialGradient(isFill, boundingBox, ref)
            is SolidColor -> setSolidColor(state, isFill, ref)
        }
        //if (ref instanceof Pattern) {}  // May be needed later if/when we do direct rendering
    }

    private fun makeLinearGradient(
        isFill: Boolean,
        boundingBox: Box,
        gradient: SvgLinearGradient
    ) {
        val href = gradient.href
        if (href != null) {
            fillInChainedGradientFields(gradient, href)
        }

        val userUnits = gradient.gradientUnitsAreUser == true
        val paint = if (isFill) {
            state.fillPaint
        } else {
            state.strokePaint
        }

        val _x1: Float
        val _y1: Float
        val _x2: Float
        val _y2: Float
        if (userUnits) {
            _x1 = gradient.x1?.floatValueX(this) ?: 0f
            _y1 = gradient.y1?.floatValueY(this) ?: 0f
            _x2 = gradient.x2?.floatValueX(this)
                ?: CSSLength.PERCENT_100.floatValueX(this) // default is 1.0/100%
            _y2 = gradient.y2?.floatValueY(this) ?: 0f
        } else {
            _x1 = gradient.x1?.floatValue(this, 1f) ?: 0f
            _y1 = gradient.y1?.floatValue(this, 1f) ?: 0f
            _x2 = gradient.x2?.floatValue(this, 1f) ?: 1f // default is 1.0/100%
            _y2 = gradient.y2?.floatValue(this, 1f) ?: 0f
        }

        // Push the state
        statePush()

        // Set the style for the gradient (inherits from its own ancestors, not from callee's state)
        state = findInheritFromAncestorState(gradient)

        // Calculate the gradient transform matrix
        val m = Matrix()
        if (!userUnits) {
            m.preTranslate(boundingBox.minX, boundingBox.minY)
            m.preScale(boundingBox.width, boundingBox.height)
        }

        gradient.gradientTransform?.let {
            m.preConcat(it)
        }

        // Create the color and position arrays for the shader
        val gradientChildren = gradient.getChildren()
        val numStops = gradientChildren.size
        if (numStops == 0) {
            // If there are no stops defined, we are to treat it as paint = 'none' (see spec 13.2.4)
            statePop()
            if (isFill) {
                state.hasFill = false
            } else {
                state.hasStroke = false
            }
            return
        }

        val colors = IntArray(numStops)
        val positions = FloatArray(numStops)
        var lastOffset = -1f
        for (i in gradientChildren.indices) {
            val stop = gradientChildren[i] as Stop
            val offset: Float = stop.offset ?: 0f
            if (i == 0 || offset >= lastOffset) {
                positions[i] = offset
                lastOffset = offset
            } else {
                // Each offset must be equal or greater than the last one.
                // If it doesn't we need to replace it with the previous value.
                positions[i] = lastOffset
            }

            withNewState { state ->
                updateStyleForElement(state, stop)
                val style = state.style
                val col = style.stopColor as ColorValue? ?: ColorValue.BLACK
                colors[i] = col.value.colorWithOpacity(style.stopOpacity!!)
            }
        }

        // If gradient vector is zero length, we instead fill with last stop color
        if (_x1 == _x2 && _y1 == _y2 || numStops == 1) {
            statePop()
            paint.setColor(colors[numStops - 1])
            return
        }

        // Convert spreadMethod->TileMode
        val tileMode: TileMode = when (gradient.spreadMethod) {
            GradientSpread.reflect -> {
                TileMode.MIRROR
            }

            GradientSpread.repeat -> {
                TileMode.REPEAT
            }

            else -> {
                TileMode.CLAMP
            }
        }

        statePop()

        // Create shader instance
        val gr = LinearGradient(_x1, _y1, _x2, _y2, colors, positions, tileMode)
        gr.setLocalMatrix(m)
        paint.setShader(gr)
        paint.alpha = clamp255(state.style.fillOpacity!! * 255f)
    }

    private sealed class GradientColorArray {
        abstract val size: Int
        abstract operator fun set(index: Int, @ColorInt color: Int)
        abstract fun setOnPaint(paint: Paint, index: Int)

        class Ints(val array: IntArray) : GradientColorArray() {
            override val size: Int get() = array.size
            override fun set(index: Int, color: Int) {
                array[index] = color
            }

            override fun setOnPaint(paint: Paint, index: Int) {
                paint.setColor(array[index])
            }
        }

        @RequiresApi(Build.VERSION_CODES.Q)
        class Longs(val array: LongArray) : GradientColorArray() {
            override val size: Int get() = array.size
            override fun set(index: Int, color: Int) {
                array[index] = Color.pack(color)
            }

            override fun setOnPaint(paint: Paint, index: Int) {
                paint.setColor(array[index])
            }
        }
    }

    private fun makeRadialGradient(
        isFill: Boolean,
        boundingBox: Box,
        gradient: SvgRadialGradient
    ) {
        val href = gradient.href
        if (href != null) {
            fillInChainedGradientFields(gradient, href)
        }

        val userUnits = gradient.gradientUnitsAreUser == true
        val paint = if (isFill) {
            state.fillPaint
        } else {
            state.strokePaint
        }

        val _cx: Float
        val _cy: Float
        val _r: Float
        var _fx = 0f
        var _fy = 0f
        var _fr = 0f
        if (userUnits) {
            _cx = gradient.cx?.floatValueX(this) ?: CSSLength.PERCENT_50.floatValueX(this)
            _cy = gradient.cy?.floatValueY(this) ?: CSSLength.PERCENT_50.floatValueY(this)
            _r = gradient.r?.floatValue(this) ?: CSSLength.PERCENT_50.floatValue(this)

            if (SUPPORTS_RADIAL_GRADIENT_WITH_FOCUS) {
                _fx = gradient.fx?.floatValueX(this) ?: _cx
                _fy = gradient.fy?.floatValueY(this) ?: _cy
                _fr = gradient.fr?.floatValue(this) ?: 0f
            }
        } else {
            _cx = gradient.cx?.floatValue(this, 1f) ?: 0.5f
            _cy = gradient.cy?.floatValue(this, 1f) ?: 0.5f
            _r = gradient.r?.floatValue(this, 1f) ?: 0.5f

            if (SUPPORTS_RADIAL_GRADIENT_WITH_FOCUS) {
                _fx = gradient.fx?.floatValue(this, 1f) ?: 0.5f
                _fy = gradient.fy?.floatValue(this, 1f) ?: 0.5f
                _fr = gradient.fr?.floatValue(this, 1f) ?: 0f
            }
        }

        // fx and fy are ignored because Android RadialGradient doesn't support a
        // 'focus' point that is different from cx,cy.

        // Push the state
        statePush()

        // Set the style for the gradient (inherits from its own ancestors, not from callee's state)
        state = findInheritFromAncestorState(gradient)

        // Calculate the gradient transform matrix
        val m = Matrix()
        if (!userUnits) {
            m.preTranslate(boundingBox.minX, boundingBox.minY)
            m.preScale(boundingBox.width, boundingBox.height)
        }

        gradient.gradientTransform?.let {
            m.preConcat(it)
        }

        // Create the color and position arrays for the shader
        val gradientChildren = gradient.getChildren()
        val numStops = gradientChildren.size
        if (numStops == 0) {
            // If there are no stops defined, we are to treat it as paint = 'none' (see spec 13.2.4)
            statePop()
            if (isFill) {
                state.hasFill = false
            } else {
                state.hasStroke = false
            }
            return
        }

        val colors = if (SUPPORTS_RADIAL_GRADIENT_WITH_FOCUS) {
            GradientColorArray.Longs(LongArray(numStops))
        } else {
            GradientColorArray.Ints(IntArray(numStops))
        }

        val positions = FloatArray(numStops)
        var lastOffset = -1f
        for (i in gradientChildren.indices) {
            val stop = gradientChildren[i] as Stop
            val offset: Float = stop.offset ?: 0f
            if (i == 0 || offset >= lastOffset) {
                positions[i] = offset
                lastOffset = offset
            } else {
                // Each offset must be equal or greater than the last one.
                // If it doesn't we need to replace it with the previous value.
                positions[i] = lastOffset
            }

            withNewState { st5 ->
                updateStyleForElement(st5, stop)
                val style = st5.style
                val col = style.stopColor as ColorValue? ?: ColorValue.BLACK
                colors[i] = col.value.colorWithOpacity(style.stopOpacity!!)
            }
        }

        // If gradient radius is zero, we instead fill with last stop color
        if (_r == 0f || numStops == 1) {
            statePop()
            colors.setOnPaint(paint, numStops - 1)
            return
        }

        // Convert spreadMethod->TileMode
        var tileMode = TileMode.CLAMP
        if (gradient.spreadMethod != null) {
            if (gradient.spreadMethod == GradientSpread.reflect) {
                tileMode = TileMode.MIRROR
            } else if (gradient.spreadMethod == GradientSpread.repeat) {
                tileMode = TileMode.REPEAT
            }
        }

        statePop()

        // Create shader instance
        val gr = when (colors) {
            is GradientColorArray.Longs -> {
                @Suppress("NewApi")
                RadialGradient(
                    /* startX = */ _fx,
                    /* startY = */ _fy,
                    /* startRadius = */ _fr,
                    /* endX = */ _cx,
                    /* endY = */ _cy,
                    /* endRadius = */ _r,
                    /* colors = */ colors.array,
                    /* stops = */ positions,
                    /* tileMode = */ tileMode
                )
            }

            is GradientColorArray.Ints -> {
                RadialGradient(
                    /* centerX = */ _cx,
                    /* centerY = */ _cy,
                    /* radius = */ _r,
                    /* colors = */ colors.array,
                    /* stops = */ positions,
                    /* tileMode = */ tileMode
                )
            }
        }
        gr.setLocalMatrix(m)
        paint.setShader(gr)
        paint.alpha = clamp255(state.style.fillOpacity!! * 255f)
    }

    /*
    * Any unspecified fields in this gradient can be 'borrowed' from another
    * gradient specified by the href attribute.
    */
    private fun fillInChainedGradientFields(gradient: GradientElement, href: String) {
        // Locate the referenced object
        val ref = gradient.document.resolveIRI(href)
        if (ref == null) {
            // Non-existent
            warn("Gradient reference '%s' not found", href)
            return
        }
        if (ref !is GradientElement) {
            error("Gradient href attributes must point to other gradient elements")
            return
        }
        if (ref === gradient) {
            error("Circular reference in gradient href attribute '%s'", href)
            return
        }

        val gradientRef: GradientElement = ref

        if (gradient.gradientUnitsAreUser == null) {
            gradient.gradientUnitsAreUser = gradientRef.gradientUnitsAreUser
        }
        if (gradient.gradientTransform == null) {
            gradient.gradientTransform = gradientRef.gradientTransform
        }
        if (gradient.spreadMethod == null) {
            gradient.spreadMethod = gradientRef.spreadMethod
        }
        if (gradient.childCount() == 0) {
            gradient.addAll(gradientRef.getChildren())
        }

        try {
            when (gradient) {
                is SvgLinearGradient -> fillInChainedGradientFields(
                    gradient,
                    ref as SvgLinearGradient
                )

                is SvgRadialGradient -> fillInChainedGradientFields(
                    gradient,
                    ref as SvgRadialGradient
                )
            }
        } catch (_: ClassCastException) { /* expected - do nothing */
        }

        val href1 = gradientRef.href
        if (href1 != null) fillInChainedGradientFields(gradient, href1)
    }

    //==============================================================================
    // Clip paths
    //==============================================================================
    private fun checkForClipPath(obj: SvgElement, boundingBox: Box? = obj.boundingBox) {
        if (state.style.clipPath == null) {
            return
        }

        val combinedPath = calculateClipPath(obj, boundingBox)
        if (combinedPath != null) {
            canvas.clipPath(combinedPath)
        }
    }

    //-----------------------------------------------------------------------------------------------
    // Clip-path handling.
    // Used Path.op(Path, Path.Op) methods.
    //
    private fun calculateClipPath(obj: SvgElement, boundingBox: Box?): Path? {
        val clipPath = run {
            // Locate the referenced object
            val cp = state.style.clipPath
            val ref = obj.document.resolveIRI(cp)
            if (ref == null) {
                error("ClipPath reference '%s' not found", cp)
                return null
            }

            // https://drafts.fxtf.org/css-masking-1/#the-clip-path
            // If the URI reference is not valid (e.g. it points to an object that doesn’t
            // exist or the object is not a clipPath element), no clipping is applied.
            if (ref.getNodeName() != ClipPath.NODE_NAME) return null

            ref
        } as ClipPath

        withNewState(saveCanvas = false) {
            // "Properties inherit into the <clipPath> element from its ancestors; properties do not
            // inherit from the element referencing the <clipPath> element." (sect 14.3.5)
            state = findInheritFromAncestorState(clipPath)

            val userUnits = clipPath.clipPathUnitsAreUser != false
            val m = Matrix()
            if (!userUnits) {
                if (boundingBox == null) {
                    return null
                }
                m.preTranslate(boundingBox.minX, boundingBox.minY)
                m.preScale(boundingBox.width, boundingBox.height)

                // Set the viewport to 1x1 so that percentages are resolved correctly
                state.viewPort = Box(0f, 0f, 1f, 1f)
                state.viewBox = null
            }
            clipPath.transform?.let { m.preConcat(it) }

            val combinedPath = Path()
            clipPath.getChildren().forEachElement { child ->
                if (child is SvgElement) {
                    val part = objectToPath(child, true)
                    if (part != null) {
                        combinedPath.op(part, Path.Op.UNION)
                    }
                }
            }

            // Does the clip-path also have a clip-path?
            if (state.style.clipPath != null) {
                val boundingBox = clipPath.boundingBox ?: calculatePathBounds(combinedPath).also {
                    clipPath.boundingBox = it
                }

                val clipClipPath = calculateClipPath(
                    obj = clipPath,
                    boundingBox = boundingBox
                )

                if (clipClipPath != null) {
                    combinedPath.op(clipClipPath, Path.Op.INTERSECT)
                }
            }

            combinedPath.transform(m)
            return combinedPath
        }
    }


    /*
    * Convert the clipPath child element to a path. Transformed if need be, and clipped also if it has its own clip-path.
    */
    private fun objectToPath(obj: SvgElement, allowUse: Boolean): Path? {
        withNewState(saveCanvas = false) {
            state = RendererState(state)

            updateStyleForElement(state, obj)

            if (!display() || !visible()) {
                return null
            }

            var path: Path? = null

            when (obj) {
                is Use -> {
                    if (!allowUse) {
                        error("<use> elements inside a <clipPath> cannot reference another <use>")
                    }

                    // Locate the referenced object
                    val useElement = obj
                    val ref = obj.document.resolveIRI(useElement.href)
                    if (ref == null) {
                        error("Use reference '%s' not found", useElement.href)
                        return null
                    }
                    if (ref !is SvgElement) {
                        return null
                    }

                    path = objectToPath(ref, false)
                    if (path == null) return null

                    if (useElement.boundingBox == null) {
                        useElement.boundingBox = calculatePathBounds(path)
                    }

                    useElement.transform?.let { path.transform(it) }
                }

                is GraphicsElement -> {
                    val elem: GraphicsElement = obj

                    when (obj) {
                        is SvgObject.Path -> {
                            val pathElem: SvgObject.Path = obj
                            path = PathConverter(pathElem.d).path
                            if (obj.boundingBox == null) {
                                obj.boundingBox = calculatePathBounds(path)
                            }
                        }

                        is SvgObject.Rect -> {
                            path = makePathAndBoundingBox(obj)
                        }

                        is Circle -> {
                            path = makePathAndBoundingBox(obj)
                        }

                        is Ellipse -> {
                            path = makePathAndBoundingBox(obj)
                        }

                        is PolyLine -> {
                            path = makePathAndBoundingBox(obj)
                        }

                        else -> {}
                    }

                    if (path == null) return null

                    if (elem.boundingBox == null) {
                        elem.boundingBox = calculatePathBounds(path)
                    }

                    elem.transform?.let { path.transform(it) }

                    path.fillType = state.clipRule
                }

                is Text -> {
                    val textElem: Text = obj
                    path = makePathAndBoundingBox(textElem)

                    textElem.transform?.let { path.transform(it) }

                    path.fillType = state.clipRule
                }

                is Group -> {
                    val combined = Path()
                    obj.getChildren().forEachElement { child ->
                        if (child is SvgElement) {
                            val part = objectToPath(child, allowUse)
                            if (part != null) {
                                combined.op(part, Path.Op.UNION)
                            }
                        }
                    }
                    path = combined
                }

                else -> {
                    error("Invalid %s element found in clipPath definition", obj.getNodeName())
                    return null
                }

                // Does the clip-path child element also have a clip-path?
            }

            // Does the clip-path child element also have a clip-path?
            if (state.style.clipPath != null) {
                val childrenClipPath = calculateClipPath(obj, obj.boundingBox!!)
                if (childrenClipPath != null) path.op(childrenClipPath, Path.Op.INTERSECT)
            }

            return path
        }
    }

    //-----------------------------------------------------------------------------------------------
    private inner class PlainTextToPath(
        @JvmField
        var x: Float,
        @JvmField
        var y: Float,
        @JvmField
        val textAsPath: Path
    ) :
        TextProcessor() {
        override fun doTextContainer(obj: TextContainer): Boolean {
            if (obj is TextPath) {
                warn("Using <textPath> elements in a clip path is not supported.")
                return false
            }
            return true
        }

        override fun processText(text: String) {
            val s = state

            if (visible()) {
                //state.fillPaint.getTextPath(text, 0, text.length(), x, y, textAsPath);
                val spanPath = Path()
                s.fillPaint.getTextPath(text, 0, text.length, x, y, spanPath)
                textAsPath.addPath(spanPath)
            }

            // Update the current text position
            x += measureText(text, s.fillPaint)
        }
    }


    //==============================================================================
    // Convert the different shapes to paths
    //==============================================================================
    private fun makePathAndBoundingBox(obj: Line): Path {
        val x1 = obj.x1?.floatValueX(this) ?: 0f
        val y1 = obj.y1?.floatValueY(this) ?: 0f
        val x2 = obj.x2?.floatValueX(this) ?: 0f
        val y2 = obj.y2?.floatValueY(this) ?: 0f

        if (obj.boundingBox == null) {
            obj.boundingBox = Box(
                minX = min(x1, x2),
                minY = min(y1, y2),
                width = abs(x2 - x1),
                height = abs(y2 - y1)
            )
        }

        val p = Path()
        p.moveTo(x1, y1)
        p.lineTo(x2, y2)
        return p
    }


    private fun makePathAndBoundingBox(obj: SvgObject.Rect): Path {
        var rx: Float
        var ry: Float

        val objRx = obj.rx
        val objRy = obj.ry
        val objWidth = obj.width!!
        val objHeight = obj.height!!

        if (objRx == null && objRy == null) {
            rx = 0f
            ry = 0f
        } else if (objRx == null) {
            ry = objRy!!.floatValueY(this)
            rx = ry
        } else if (objRy == null) {
            ry = objRx.floatValueX(this)
            rx = ry
        } else {
            rx = objRx.floatValueX(this)
            ry = objRy.floatValueY(this)
        }
        rx = min(rx, objWidth.floatValueX(this) / 2f)
        ry = min(ry, objHeight.floatValueY(this) / 2f)
        val x: Float = obj.x?.floatValueX(this) ?: 0f
        val y: Float = obj.y?.floatValueY(this) ?: 0f
        val w: Float = objWidth.floatValueX(this)
        val h: Float = objHeight.floatValueY(this)

        if (obj.boundingBox == null) {
            obj.boundingBox = Box(x, y, w, h)
        }

        val right = x + w
        val bottom = y + h

        val p = Path()
        if (rx == 0f || ry == 0f) {
            // Simple rect
            p.moveTo(x, y)
            p.lineTo(right, y)
            p.lineTo(right, bottom)
            p.lineTo(x, bottom)
            p.lineTo(x, y)
        } else {
            // Rounded rect

            // Bezier control point lengths for a 90 degree arc

            val cpx: Float = rx * BEZIER_ARC_FACTOR
            val cpy: Float = ry * BEZIER_ARC_FACTOR

            p.moveTo(x, y + ry)
            p.cubicTo(x, y + ry - cpy, x + rx - cpx, y, x + rx, y)
            p.lineTo(right - rx, y)
            p.cubicTo(right - rx + cpx, y, right, y + ry - cpy, right, y + ry)
            p.lineTo(right, bottom - ry)
            p.cubicTo(right, bottom - ry + cpy, right - rx + cpx, bottom, right - rx, bottom)
            p.lineTo(x + rx, bottom)
            p.cubicTo(x + rx - cpx, bottom, x, bottom - ry + cpy, x, bottom - ry)
            p.lineTo(x, y + ry)
        }
        p.close()
        return p
    }


    private fun makePathAndBoundingBox(obj: Circle): Path {
        val cx = obj.cx?.floatValueX(this) ?: 0f
        val cy = obj.cy?.floatValueY(this) ?: 0f
        val r = obj.r!!.floatValue(this)

        val left = cx - r
        val top = cy - r
        val right = cx + r
        val bottom = cy + r

        if (obj.boundingBox == null) {
            obj.boundingBox = Box(left, top, r * 2, r * 2)
        }

        val cp: Float = r * BEZIER_ARC_FACTOR

        val p = Path()
        p.moveTo(cx, top)
        p.cubicTo(cx + cp, top, right, cy - cp, right, cy)
        p.cubicTo(right, cy + cp, cx + cp, bottom, cx, bottom)
        p.cubicTo(cx - cp, bottom, left, cy + cp, left, cy)
        p.cubicTo(left, cy - cp, cx - cp, top, cx, top)
        p.close()
        return p
    }


    private fun makePathAndBoundingBox(obj: Ellipse): Path {
        val cx = obj.cx?.floatValueX(this) ?: 0f
        val cy = obj.cy?.floatValueY(this) ?: 0f
        val rx = obj.rx!!.floatValueX(this)
        val ry = obj.ry!!.floatValueY(this)

        val left = cx - rx
        val top = cy - ry
        val right = cx + rx
        val bottom = cy + ry

        if (obj.boundingBox == null) {
            obj.boundingBox = Box(left, top, rx * 2, ry * 2)
        }

        val cpx: Float = rx * BEZIER_ARC_FACTOR
        val cpy: Float = ry * BEZIER_ARC_FACTOR

        val p = Path()
        p.moveTo(cx, top)
        p.cubicTo(cx + cpx, top, right, cy - cpy, right, cy)
        p.cubicTo(right, cy + cpy, cx + cpx, bottom, cx, bottom)
        p.cubicTo(cx - cpx, bottom, left, cy + cpy, left, cy)
        p.cubicTo(left, cy - cpy, cx - cpx, top, cx, top)
        p.close()
        return p
    }


    private fun makePathAndBoundingBox(obj: PolyLine): Path? {
        val path = Path()

        val points = obj.points ?: return null
        var numPoints = points.size
        // Odd number of points is an error
        if (numPoints % 2 != 0) return null

        if (numPoints > 0) {
            var i = 0
            while (numPoints >= 2) {
                if (i == 0) {
                    path.moveTo(points[0], points[1])
                } else {
                    path.lineTo(points[i], points[i + 1])
                }
                i += 2
                numPoints -= 2
            }
            if (obj is Polygon) path.close()
        }

        if (obj.boundingBox == null) {
            obj.boundingBox = calculatePathBounds(path)
        }
        return path
    }


    private fun makePathAndBoundingBox(obj: Text): Path {
        // Get the first coordinate pair from the lists in the x and y properties.
        var x = obj.x?.firstOrNull()?.floatValueX(this) ?: 0f
        val y = obj.y?.firstOrNull()?.floatValueY(this) ?: 0f
        val dx = obj.dx?.firstOrNull()?.floatValueX(this) ?: 0f
        val dy = obj.dy?.firstOrNull()?.floatValueY(this) ?: 0f

        // Handle text alignment
        val style = state.style
        if (style.textAnchor != TextAnchor.Start) {
            val textWidth = calculateTextWidth(obj)
            x -= if (style.textAnchor == TextAnchor.Middle) {
                textWidth / 2
            } else {
                textWidth // 'End' (right justify)
            }
        }

        if (obj.boundingBox == null) {
            val proc = TextBoundsCalculator(x, y)
            enumerateTextSpans(obj, proc)
            obj.boundingBox = Box(proc.boundingBox)
        }

        val textAsPath = Path()
        enumerateTextSpans(
            obj = obj,
            textProcessor = PlainTextToPath(
                x = x + dx,
                y = y + dy,
                textAsPath = textAsPath
            )
        )
        return textAsPath
    }


    //==============================================================================
    // Pattern fills
    //==============================================================================
    /*
    * Fill a path with a pattern by setting the path as a clip path and
    * drawing the pattern element as a repeating tile inside it.
    */
    private fun fillWithPattern(obj: SvgElement, path: Path, pattern: SvgObject.Pattern) {
        val patternUnitsAreUser = pattern.patternUnitsAreUser == true
        var x: Float
        var y: Float
        var w: Float
        var h: Float
        val objFillOpacity: Float = state.style.fillOpacity!!

        pattern.href?.let {
            fillInChainedPatternFields(pattern, it)
        }

        if (patternUnitsAreUser) {
            x = pattern.x?.floatValueX(this) ?: 0f
            y = pattern.y?.floatValueY(this) ?: 0f
            w = pattern.width?.floatValueX(this) ?: 0f
            h = pattern.height?.floatValueY(this) ?: 0f
        } else {
            // Convert objectBoundingBox space to user space
            val boundingBox = obj.boundingBox!!
            x = pattern.x?.floatValue(this, 1f) ?: 0f
            y = pattern.y?.floatValue(this, 1f) ?: 0f
            w = pattern.width?.floatValue(this, 1f) ?: 0f
            h = pattern.height?.floatValue(this, 1f) ?: 0f
            x = boundingBox.minX + x * boundingBox.width
            y = boundingBox.minY + y * boundingBox.height
            w *= boundingBox.width
            h *= boundingBox.height
        }
        if (w == 0f || h == 0f) return

        // "If attribute 'preserveAspectRatio' is not specified, then the effect is as if a value of xMidYMid meet were specified."
        val positioning: PreserveAspectRatio = pattern.preserveAspectRatio ?: PreserveAspectRatio.LETTERBOX

        withNewState {
            // Set path as the clip region
            canvas.clipPath(path)

            // Set the style for the pattern (inherits from its own ancestors, not from callee's state)
            val baseState = RendererState()
            updateStyle(baseState, Style.getDefaultStyle())
            baseState.style.overflow = false // By default, patterns do not overflow

            // SVG2 TODO: Patterns now inherit from the element referencing the pattern
            state = findInheritFromAncestorState(pattern, baseState)

            // The bounds of the area we need to cover with pattern to ensure that our shape is filled
            var patternArea = obj.boundingBox
            // Apply the patternTransform
            val patternTransform = pattern.patternTransform
            if (patternTransform != null) {
                canvas.concat(patternTransform)


                // A pattern transform will affect the area we need to cover with the pattern.
                // So we need to alter the area bounding rectangle.
                val inverse = Matrix()
                if (patternTransform.invert(inverse)) {
                    val boundingBox = obj.boundingBox!!
                    val pts = floatArrayOf(
                        boundingBox.minX,
                        boundingBox.minY,
                        boundingBox.maxX(),
                        boundingBox.minY,
                        boundingBox.maxX(),
                        boundingBox.maxY(),
                        boundingBox.minX,
                        boundingBox.maxY()
                    )
                    inverse.mapPoints(pts)
                    // Find the bounding box of the shape created by the inverse transform
                    val rect = RectF(pts[0], pts[1], pts[0], pts[1])
                    var i = 2
                    while (i <= 6) {
                        if (pts[i] < rect.left) rect.left = pts[i]
                        if (pts[i] > rect.right) rect.right = pts[i]
                        if (pts[i + 1] < rect.top) rect.top = pts[i + 1]
                        if (pts[i + 1] > rect.bottom) rect.bottom = pts[i + 1]
                        i += 2
                    }
                    patternArea = Box(rect)
                }
            }

            // Calculate the pattern origin
            val originX = x + floor((patternArea!!.minX - x) / w) * w
            val originY = y + floor((patternArea.minY - y) / h) * h

            // For each Y step, then each X step
            val right = patternArea.maxX()
            val bottom = patternArea.maxY()
            val stepViewBox = Box(0f, 0f, w, h)

            withNewRenderLayer(
                obj = pattern,
                opacityAdjustment = objFillOpacity
            ) {
                var stepY = originY
                while (stepY < bottom) {
                    var stepX = originX
                    while (stepX < right) {
                        stepViewBox.minX = stepX
                        stepViewBox.minY = stepY

                        withNewState { st6 ->
                            // Set pattern clip rectangle if appropriate
                            if (!st6.style.overflow!!) {
                                setClipRect(stepViewBox)
                            }
                            // Calculate and set the viewport for each instance of the pattern
                            val viewBox = pattern.viewBox
                            if (viewBox != null) {
                                canvas.concat(
                                    calculateViewBoxTransform(
                                        viewPort = stepViewBox,
                                        viewBox = viewBox,
                                        positioning = positioning
                                    )
                                )
                            } else {
                                val patternContentUnitsAreUser = pattern.patternContentUnitsAreUser == true
                                // Simple translate of pattern to step position
                                canvas.translate(stepX, stepY)
                                if (!patternContentUnitsAreUser) {
                                    val boundingBox = obj.boundingBox!!
                                    canvas.scale(boundingBox.width, boundingBox.height)

                                    // Set the viewport to 1x1 so that percentages are resolved correctly
                                    st6.viewPort = Box(0f, 0f, 1f, 1f)
                                    st6.viewBox = null
                                }
                            }

                            // Render the pattern
                            renderChildren(pattern, false)
                        }

                        stepX += w
                    }
                    stepY += h
                }
            }
        }
    }


    //==============================================================================
    // Masks
    //==============================================================================
    /*
    * Render the contents of a mask element.
    */
    @SuppressLint("UseKtx")
    private fun renderMask(mask: Mask, obj: SvgElement, originalObjBBox: Box) {
        debug {
            "Mask render"
        }

        val maskRegion = calculateMaskRegion(mask, originalObjBBox)
        if (maskRegion.width() <= 0f || maskRegion.height() <= 0f) return

        withNewState {
            state = findInheritFromAncestorState(mask)
            // Set the style for the mask (inherits from its own ancestors, not from callee's state)
            // The 'opacity', 'filter' and 'display' properties do not apply to the 'mask' element" (sect 14.4)
            state.style.opacity = 1f

            //state.style.filter = null;

            canvas.save()
            canvas.clipRect(maskRegion)

            withNewRenderLayer(obj, originalObjBBox) {
                // Save the current transform matrix, as we need to undo the following transform straight away
                val savePoint = canvas.save()

                val maskContentUnitsAreUser = mask.maskContentUnitsAreUser != false
                if (!maskContentUnitsAreUser) {
                    canvas.translate(originalObjBBox.minX, originalObjBBox.minY)
                    canvas.scale(originalObjBBox.width, originalObjBBox.height)

                    // Set the viewport to 1x1 so that percentages are resolved correctly
                    state.viewPort = Box(0f, 0f, 1f, 1f)
                    state.viewBox = null
                }

                // Render the mask
                renderChildren(mask, false)

                // Restore the matrix so that, if this mask has a mask, it is not affected by the objectBoundingBox transform
                canvas.restoreToCount(savePoint)
            }

            canvas.restore()
        }
    }

    companion object {
        private const val TAG = "SVGAndroidRenderer"

        @Suppress("FloatingPointLiteralPrecision")
        private const val BEZIER_ARC_FACTOR: Float = 0.5522847498f

        // The feColorMatrix luminance-to-alpha coefficient. Used for <mask>s.
        // Note we are using the CSS/SVG2 version of the coefficients here, rather than the older SVG1.1 coefficients.
        const val LUMINANCE_TO_ALPHA_RED: Float = 0.2127f
        const val LUMINANCE_TO_ALPHA_GREEN: Float = 0.7151f
        const val LUMINANCE_TO_ALPHA_BLUE: Float = 0.0722f

        private const val DEFAULT_FONT_FAMILY = "serif"

        //==============================================================================

        private fun warn(message: String) {
            Log.w(TAG, message)
        }

        private fun warn(format: String, vararg args: Any?) {
            Log.w(TAG, String.format(format, *args))
        }

        private fun error(message: String) {
            Log.e(TAG, message)
        }

        private fun error(format: String, vararg args: Any?) {
            Log.e(TAG, String.format(format, *args))
        }

        private inline fun debug(lazyMessage: () -> String) {
            if (BuildConfig.DEBUG) {
                Log.d(TAG, lazyMessage.invoke())
            }
        }

        private fun setPaintColor(state: RendererState, isFill: Boolean, paint: SvgPaint?) {
            val paintOpacity = if (isFill) {
                state.style.fillOpacity
            } else {
                state.style.strokeOpacity
            }!!

            var col: Int = when (paint) {
                is ColorValue -> {
                    paint.value
                }

                is CurrentColor -> {
                    state.style.color!!.value
                }

                else -> {
                    return
                }
            }

            col = col.colorWithOpacity(paintOpacity)

            if (isFill) {
                state.fillPaint
            } else {
                state.strokePaint
            }.setColor(col)
        }

        /*
        * Any unspecified fields in this pattern can be 'borrowed' from another
        * pattern specified by the href attribute.
        */
        private fun fillInChainedPatternFields(pattern: SvgObject.Pattern, href: String) {
            // Locate the referenced object
            val ref = pattern.document.resolveIRI(href)
            if (ref == null) {
                // Non-existent
                warn("Pattern reference '%s' not found", href)
                return
            }
            if (ref !is SvgObject.Pattern) {
                error("Pattern href attributes must point to other pattern elements")
                return
            }
            if (ref === pattern) {
                error("Circular reference in pattern href attribute '%s'", href)
                return
            }

            val pRef: SvgObject.Pattern = ref

            if (pattern.patternUnitsAreUser == null) {
                pattern.patternUnitsAreUser = pRef.patternUnitsAreUser
            }

            if (pattern.patternContentUnitsAreUser == null) {
                pattern.patternContentUnitsAreUser = pRef.patternContentUnitsAreUser
            }

            if (pattern.patternTransform == null) {
                pattern.patternTransform = pRef.patternTransform
            }

            if (pattern.x == null) {
                pattern.x = pRef.x
            }

            if (pattern.y == null) {
                pattern.y = pRef.y
            }

            if (pattern.width == null) {
                pattern.width = pRef.width
            }

            if (pattern.height == null) {
                pattern.height = pRef.height
            }

            // attributes from superclasses
            if (pattern.childCount() == 0) {
                pattern.addAll(pRef.getChildren())
            }

            if (pattern.viewBox == null) {
                pattern.viewBox = pRef.viewBox
            }

            if (pattern.preserveAspectRatio == null) {
                pattern.preserveAspectRatio = pRef.preserveAspectRatio
            }

            val href = pRef.href
            if (href != null) {
                fillInChainedPatternFields(pattern, href)
            }
        }

        private fun calculatePathBounds(path: Path): Box {
            val pathBounds = RectF()
            path.computeBounds(pathBounds, true)
            return Box(pathBounds)
        }

        @RequiresApi(Build.VERSION_CODES.Q)
        private fun setBlendMode(state: RendererState, paint: Paint) {
            val mixBlendMode = state.style.mixBlendMode

            debug {
                "Setting blend mode to $mixBlendMode"
            }

            when (mixBlendMode) {
                CSSBlendMode.multiply -> paint.blendMode = BlendMode.MULTIPLY
                CSSBlendMode.screen -> paint.blendMode = BlendMode.SCREEN
                CSSBlendMode.overlay -> paint.blendMode = BlendMode.OVERLAY
                CSSBlendMode.darken -> paint.blendMode = BlendMode.DARKEN
                CSSBlendMode.lighten -> paint.blendMode = BlendMode.LIGHTEN
                CSSBlendMode.color_dodge -> paint.blendMode = BlendMode.COLOR_DODGE
                CSSBlendMode.color_burn -> paint.blendMode = BlendMode.COLOR_BURN
                CSSBlendMode.hard_light -> paint.blendMode = BlendMode.HARD_LIGHT
                CSSBlendMode.soft_light -> paint.blendMode = BlendMode.SOFT_LIGHT
                CSSBlendMode.difference -> paint.blendMode = BlendMode.DIFFERENCE
                CSSBlendMode.exclusion -> paint.blendMode = BlendMode.EXCLUSION
                CSSBlendMode.hue -> paint.blendMode = BlendMode.HUE
                CSSBlendMode.saturation -> paint.blendMode = BlendMode.SATURATION
                CSSBlendMode.color -> paint.blendMode = BlendMode.COLOR
                CSSBlendMode.luminosity -> paint.blendMode = BlendMode.LUMINOSITY
                CSSBlendMode.normal -> paint.blendMode = null
                else -> paint.blendMode = null
            }
        }

        /*
        * Calculate an accurate text width.
        * In the case of very small font sizes, Paint.measureText() returns a result that is too large,
        * because it rounds up (Maih.ceil()) the total width before returning.
          */
        private fun measureText(text: String, paint: Paint): Float {
            val widths = FloatArray(text.length)
            paint.getTextWidths(text, widths)
            return widths.sum()
        }

        /*
        * Extract the raw text from a TextContainer. Used by <tref> handler code.
        */
        private fun extractRawText(
            parent: TextContainer,
            str: StringBuilder,
            spacePreserve: Boolean
        ) {
            val children = parent.getChildren()
            val lastIndex = children.lastIndex

            for (i in 0 .. lastIndex) {
                val child = children[i]

                if (child is TextContainer) {
                    extractRawText(
                        parent = child,
                        str = str,
                        spacePreserve = spacePreserve,
                    )
                } else if (child is TextSequence) {
                    str.append(
                        textXMLSpaceTransform(
                            text = child.text,
                            isFirstChild = i == 0,
                            isLastChild = i == lastIndex,
                            spacePreserve = spacePreserve
                        )
                    )
                }
            }
        }

        //==============================================================================
        // Process the text string according to the xml:space rules
        private fun textXMLSpaceTransform(
            text: String,
            isFirstChild: Boolean,
            isLastChild: Boolean,
            spacePreserve: Boolean,
        ): String {
            var text = text
            if (spacePreserve) {
                // xml:space = "preserve"
                return text.removeTabsAndLineBreaks()
            }

            // xml:space = "default"
            text = text.removeTabsAndLineBreaks()
            if (isFirstChild) text = text.trimStart { it.isSpaceLike() }
            if (isLastChild) text = text.trimEnd { it.isSpaceLike() }
            return text.removeDoubleSpaces()
        }

        private fun checkGenericFont(
            fontName: String,
            fontWeight: Float,
            fontStyle: FontStyle
        ): Typeface? {
            val italic = fontStyle == FontStyle.italic

            val typefaceStyle: Int = if (fontWeight >= Style.FONT_WEIGHT_BOLD) {
                if (italic) {
                    Typeface.BOLD_ITALIC
                } else {
                    Typeface.BOLD
                }
            } else {
                if (italic) {
                    Typeface.ITALIC
                } else {
                    Typeface.NORMAL
                }
            }

            return when (fontName) {
                "serif" -> Typeface.create(Typeface.SERIF, typefaceStyle)
                "sans-serif",
                "cursive",
                "fantasy" -> Typeface.create(Typeface.SANS_SERIF, typefaceStyle)

                "monospace" -> Typeface.create(Typeface.MONOSPACE, typefaceStyle)
                else -> null
            }
        }

        private fun resolveMarkerReference(obj: GraphicsElement, iri: String?): Marker? {
            if (iri == null) {
                return null
            }

            val ref = obj.document.resolveIRI(iri)
            return if (ref != null) {
                ref as Marker
            } else {
                error("Marker reference '%s' not found", iri)
                null
            }
        }

        /*
        * This was one of the ambiguous markers. Try to see if we can find a better direction for
        * it, now that we have more info available on the neighboring marker positions.
        */
        private fun realignMarkerMid(
            lastPos: MarkerVector,
            thisPos: MarkerVector,
            nextPos: MarkerVector
        ): MarkerVector {
            // Check the temporary marker vector against the incoming vector
            var dot = dotProduct(
                x1 = thisPos.dx,
                y1 = thisPos.dy,
                x2 = thisPos.x - lastPos.x,
                y2 = thisPos.y - lastPos.y
            )
            if (dot == 0f) {
                // Those two were perpendicular, so instead try the outgoing vector
                dot = dotProduct(
                    x1 = thisPos.dx,
                    y1 = thisPos.dy,
                    x2 = nextPos.x - thisPos.x,
                    y2 = nextPos.y - thisPos.y
                )
            }
            if (dot > 0) return thisPos
            if (dot == 0f) {
                // If that was perpendicular also, then give up.
                // Else use the one that points in the same direction as 0deg (1,0) or has non-negative y.
                if (thisPos.dx > 0f || thisPos.dy >= 0) return thisPos
            }
            // Reverse this vector and point the marker in the opposite direction.
            thisPos.dx = -thisPos.dx
            thisPos.dy = -thisPos.dy
            return thisPos
        }

        /*
        * Calculate the dot product of two vectors.
        */
        private fun dotProduct(x1: Float, y1: Float, x2: Float, y2: Float): Float {
            return x1 * x2 + y1 * y2
        }

        private fun fillInChainedGradientFields(gradient: SvgLinearGradient, grRef: SvgLinearGradient) {
            if (gradient.x1 == null) gradient.x1 = grRef.x1
            if (gradient.y1 == null) gradient.y1 = grRef.y1
            if (gradient.x2 == null) gradient.x2 = grRef.x2
            if (gradient.y2 == null) gradient.y2 = grRef.y2
        }

        private fun fillInChainedGradientFields(gradient: SvgRadialGradient, grRef: SvgRadialGradient) {
            if (gradient.cx == null) gradient.cx = grRef.cx
            if (gradient.cy == null) gradient.cy = grRef.cy
            if (gradient.r == null) gradient.r = grRef.r
            if (gradient.fx == null) gradient.fx = grRef.fx
            if (gradient.fy == null) gradient.fy = grRef.fy
            if (gradient.fr == null) gradient.fr = grRef.fr
        }

        private fun setSolidColor(state: RendererState, isFill: Boolean, ref: SolidColor) {
            val style = state.style

            val baseStyle = ref.baseStyle!!

            // Make a Style object that has fill or stroke color values set depending on the value of isFill.
            if (isFill) {
                if (baseStyle.isSpecified(Style.SPECIFIED_SOLID_COLOR)) {
                    val solidColor = baseStyle.solidColor
                    style.fill = solidColor
                    state.hasFill = solidColor != null
                }

                if (baseStyle.isSpecified(Style.SPECIFIED_SOLID_OPACITY)) {
                    style.fillOpacity = baseStyle.solidOpacity
                }

                // If either fill or its opacity has changed, update the fillPaint
                if (baseStyle.isSpecified(Style.SPECIFIED_SOLID_COLOR or Style.SPECIFIED_SOLID_OPACITY)) {
                    setPaintColor(state, true, style.fill)
                }
            } else {
                if (baseStyle.isSpecified(Style.SPECIFIED_SOLID_COLOR)) {
                    val solidColor = baseStyle.solidColor
                    style.stroke = solidColor
                    state.hasStroke = solidColor != null
                }

                if (baseStyle.isSpecified(Style.SPECIFIED_SOLID_OPACITY)) {
                    style.strokeOpacity = baseStyle.solidOpacity
                }

                // If either fill or its opacity has changed, update the fillPaint
                if (baseStyle.isSpecified(Style.SPECIFIED_SOLID_COLOR or Style.SPECIFIED_SOLID_OPACITY)) {
                    setPaintColor(state, false, style.stroke)
                }
            }
        }

    }
}
