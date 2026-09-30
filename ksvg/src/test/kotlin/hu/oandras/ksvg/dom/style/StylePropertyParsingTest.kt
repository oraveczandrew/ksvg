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

package hu.oandras.ksvg.dom.style

import hu.oandras.ksvg.NoopLoggerContext
import hu.oandras.ksvg.LoggerContext
import hu.oandras.ksvg.RecordingLoggerContext
import hu.oandras.ksvg.UnsupportedFeatureLoggerContext
import hu.oandras.ksvg.assertIs
import hu.oandras.ksvg.css.CSSLength
import hu.oandras.ksvg.dom.filter.ColorInterpolation
import hu.oandras.ksvg.dom.text.TextAnchor
import hu.oandras.ksvg.dom.text.TextDecoration
import hu.oandras.ksvg.dom.text.TextDirection
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class StylePropertyParsingTest {

    private fun process(attr: String, value: String, isFromAttribute: Boolean = false): Style.Builder {
        val builder = Style.Builder()
        builder.reset(Style())
        with(NoopLoggerContext) {
            Style.processStyleProperty(builder, attr, value, isFromAttribute)
        }
        return builder
    }

    private fun Style.Builder.buildAndGet(): Style = build()

    private fun specified(flags: Long, flag: Long): Boolean = (flags and flag) != 0L

    private fun processWith(
        attr: String,
        value: String,
        ctx: LoggerContext,
        isFromAttribute: Boolean = false,
    ): Style.Builder {
        val builder = Style.Builder()
        builder.reset(Style())
        with(ctx) {
            Style.processStyleProperty(builder, attr, value, isFromAttribute)
        }
        return builder
    }

    private fun wrappedRecording(): Pair<UnsupportedFeatureLoggerContext, RecordingLoggerContext> {
        val delegate = RecordingLoggerContext()
        return UnsupportedFeatureLoggerContext(delegate) to delegate
    }

    // --- deferred G6 properties: warn once per parse, silent when harmless ---

    @Test
    fun testWhiteSpaceWrapWarnsOncePerParse() {
        val (ctx, delegate) = wrappedRecording()
        processWith("white-space", "pre-wrap", ctx)
        assertEquals(1, delegate.messages.size)
        processWith("white-space", "pre-line", ctx, isFromAttribute = true)
        assertEquals("second hit in the same parse stays silent", 1, delegate.messages.size)
        // A fresh parse (fresh wrapper) logs afresh.
        val (ctx2, delegate2) = wrappedRecording()
        processWith("white-space", "pre-wrap", ctx2)
        assertEquals(1, delegate2.messages.size)
    }

    @Test
    fun testWhiteSpaceHarmlessSilent() {
        val (ctx, delegate) = wrappedRecording()
        for (v in listOf("normal", "pre", "nowrap")) {
            processWith("white-space", v, ctx)
        }
        assertTrue(delegate.messages.isEmpty())
    }

    @Test
    fun testLineHeightWarnsOnce() {
        val (ctx, delegate) = wrappedRecording()
        processWith("line-height", "24px", ctx)
        assertEquals(1, delegate.messages.size)
        processWith("line-height", "150%", ctx)
        assertEquals(1, delegate.messages.size)
    }

    @Test
    fun testLineHeightNormalSilent() {
        val (ctx, delegate) = wrappedRecording()
        processWith("line-height", "normal", ctx)
        assertTrue(delegate.messages.isEmpty())
    }

    @Test
    fun testTextOverflowEllipsisWarnsOnce() {
        val (ctx, delegate) = wrappedRecording()
        processWith("text-overflow", "ellipsis", ctx)
        assertEquals(1, delegate.messages.size)
        processWith("text-overflow", "ellipsis", ctx)
        assertEquals(1, delegate.messages.size)
    }

    @Test
    fun testTextOverflowClipSilent() {
        val (ctx, delegate) = wrappedRecording()
        processWith("text-overflow", "clip", ctx)
        assertTrue(delegate.messages.isEmpty())
    }

    // --- fill / stroke ---

    @Test
    fun testFillColor() {
        val s = process("fill", "#FF0000").buildAndGet()
        assertTrue(specified(s.specifiedFlags, Style.SPECIFIED_FILL))
        assertIs<ColorValue>(s.fill)
    }

    @Test
    fun testFillNone() {
        val s = process("fill", "none").buildAndGet()
        assertTrue(specified(s.specifiedFlags, Style.SPECIFIED_FILL))
        // none maps to TRANSPARENT
        assertIs<ColorValue>(s.fill)
    }

    @Test
    fun testFillCurrentColor() {
        val s = process("fill", "currentColor").buildAndGet()
        assertTrue(specified(s.specifiedFlags, Style.SPECIFIED_FILL))
        assertIs<CurrentColor>(s.fill)
    }

    @Test
    fun testFillUrlReference() {
        val s = process("fill", "url(#myGradient)").buildAndGet()
        assertTrue(specified(s.specifiedFlags, Style.SPECIFIED_FILL))
        assertIs<PaintReference>(s.fill)
    }

    @Test
    fun testFillUrlWithFallback() {
        val s = process("fill", "url(#grad) #ff0000").buildAndGet()
        val pr = s.fill as PaintReference
        assertEquals("#grad", pr.href)
        assertNotNull(pr.fallback)
    }

    @Test
    fun testFillUrlNoClosingParen() {
        val s = process("fill", "url(#grad").buildAndGet()
        assertTrue(specified(s.specifiedFlags, Style.SPECIFIED_FILL))
        assertIs<PaintReference>(s.fill)
    }

    @Test
    fun testStrokeColor() {
        val s = process("stroke", "blue").buildAndGet()
        assertTrue(specified(s.specifiedFlags, Style.SPECIFIED_STROKE))
        assertIs<ColorValue>(s.stroke)
    }

    @Test
    fun testFillEmptyIgnored() {
        val s = process("fill", "")
        assertFalse(specified(s.specifiedFlags, Style.SPECIFIED_FILL))
    }

    @Test
    fun testFillInheritIgnored() {
        val s = process("fill", "inherit")
        assertFalse(specified(s.specifiedFlags, Style.SPECIFIED_FILL))
    }

    // --- fill-rule ---

    @Test
    fun testFillRuleNonZero() {
        val s = process("fill-rule", "nonzero").buildAndGet()
        assertTrue(specified(s.specifiedFlags, Style.SPECIFIED_FILL_RULE))
        assertEquals(FillRule.NON_ZERO, s.fillRule)
    }

    @Test
    fun testFillRuleEvenOdd() {
        val s = process("fill-rule", "evenodd").buildAndGet()
        assertEquals(FillRule.EVEN_ODD, s.fillRule)
    }

    @Test
    fun testFillRuleInvalid() {
        val s = process("fill-rule", "badvalue")
        assertFalse(specified(s.specifiedFlags, Style.SPECIFIED_FILL_RULE))
    }

    // --- fill-opacity ---

    @Test
    fun testFillOpacity() {
        val s = process("fill-opacity", "0.5").buildAndGet()
        assertTrue(specified(s.specifiedFlags, Style.SPECIFIED_FILL_OPACITY))
        assertEquals(0.5f, s.fillOpacity, 0.001f)
    }

    // --- stroke-width ---

    @Test
    fun testStrokeWidth() {
        val s = process("stroke-width", "3.5px").buildAndGet()
        assertTrue(specified(s.specifiedFlags, Style.SPECIFIED_STROKE_WIDTH))
        assertEquals(3.5f, s.strokeWidth!!.floatValue(), 0.001f)
    }

    @Test
    fun testStrokeWidthInvalid() {
        val s = process("stroke-width", "abc")
        assertFalse(specified(s.specifiedFlags, Style.SPECIFIED_STROKE_WIDTH))
    }

    // --- stroke-linecap ---

    @Test
    fun testStrokeLineCapRound() {
        val s = process("stroke-linecap", "round").buildAndGet()
        assertEquals(LineCap.ROUND, s.strokeLineCap)
    }

    @Test
    fun testStrokeLineCapSquare() {
        val s = process("stroke-linecap", "square").buildAndGet()
        assertEquals(LineCap.SQUARE, s.strokeLineCap)
    }

    @Test
    fun testStrokeLineCapButt() {
        val s = process("stroke-linecap", "butt").buildAndGet()
        assertEquals(LineCap.BUTT, s.strokeLineCap)
    }

    @Test
    fun testStrokeLineCapInvalid() {
        val s = process("stroke-linecap", "invalid")
        assertEquals(LineCap.UNSPECIFIED, s.strokeLineCap)
    }

    // --- stroke-linejoin ---

    @Test
    fun testStrokeLineJoinMiter() {
        val s = process("stroke-linejoin", "miter").buildAndGet()
        assertEquals(LineJoin.MITER, s.strokeLineJoin)
    }

    @Test
    fun testStrokeLineJoinBevel() {
        val s = process("stroke-linejoin", "bevel").buildAndGet()
        assertEquals(LineJoin.BEVEL, s.strokeLineJoin)
    }

    @Test
    fun testStrokeLineJoinRound() {
        val s = process("stroke-linejoin", "round").buildAndGet()
        assertEquals(LineJoin.ROUND, s.strokeLineJoin)
    }

    // --- stroke-miterlimit ---

    @Test
    fun testStrokeMiterLimit() {
        val s = process("stroke-miterlimit", "8").buildAndGet()
        assertEquals(8f, s.strokeMiterLimit, 0.001f)
    }

    @Test
    fun testStrokeMiterLimitClampedToOne() {
        // Per spec values below 1 are invalid; clamped to 1 rather than used as-is.
        assertEquals(1f, process("stroke-miterlimit", "0.5").buildAndGet().strokeMiterLimit, 0.001f)
        assertEquals(1f, process("stroke-miterlimit", "0").buildAndGet().strokeMiterLimit, 0.001f)
        assertEquals(1f, process("stroke-miterlimit", "-3").buildAndGet().strokeMiterLimit, 0.001f)
    }

    @Test
    fun testStrokeMiterLimitInvalid() {
        val s = process("stroke-miterlimit", "abc")
        assertFalse(specified(s.specifiedFlags, Style.SPECIFIED_STROKE_MITERLIMIT))
    }

    // --- stroke-dasharray ---

    @Test
    fun testStrokeDashArrayNone() {
        val s = process("stroke-dasharray", "none").buildAndGet()
        assertTrue(specified(s.specifiedFlags, Style.SPECIFIED_STROKE_DASHARRAY))
        assertNull(s.strokeDashArray)
    }

    @Test
    fun testStrokeDashArrayValues() {
        val s = process("stroke-dasharray", "5 10 15").buildAndGet()
        assertNotNull(s.strokeDashArray)
        assertEquals(3, s.strokeDashArray!!.size)
    }

    @Test
    fun testStrokeDashArrayCommaSeparated() {
        val s = process("stroke-dasharray", "5,10").buildAndGet()
        assertNotNull(s.strokeDashArray)
        assertEquals(2, s.strokeDashArray!!.size)
    }

    @Test
    fun testStrokeDashArrayNegativeReturnsNull() {
        val s = process("stroke-dasharray", "-5 10")
        assertFalse(specified(s.specifiedFlags, Style.SPECIFIED_STROKE_DASHARRAY))
    }

    @Test
    fun testStrokeDashArrayAllZeroReturnsNull() {
        val s = process("stroke-dasharray", "0 0")
        assertFalse(specified(s.specifiedFlags, Style.SPECIFIED_STROKE_DASHARRAY))
    }

    // --- stroke-dashoffset ---

    @Test
    fun testStrokeDashOffset() {
        val s = process("stroke-dashoffset", "3px").buildAndGet()
        assertTrue(specified(s.specifiedFlags, Style.SPECIFIED_STROKE_DASHOFFSET))
        assertEquals(3f, s.strokeDashOffset!!.floatValue(), 0.001f)
    }

    // --- opacity ---

    @Test
    fun testOpacity() {
        val s = process("opacity", "0.7").buildAndGet()
        assertTrue(specified(s.specifiedFlags, Style.SPECIFIED_OPACITY))
        assertEquals(0.7f, s.opacity, 0.001f)
    }

    @Test
    fun testOpacityEmptyFallback() {
        val s = process("opacity", "").buildAndGet()
        assertEquals(1f, s.opacity, 0.001f)
    }

    // --- color ---

    @Test
    fun testColor() {
        val s = process("color", "#00FF00").buildAndGet()
        assertTrue(specified(s.specifiedFlags, Style.SPECIFIED_COLOR))
        assertIs<ColorValue>(s.color)
    }

    // --- font-size ---

    @Test
    fun testFontSizeNumeric() {
        val s = process("font-size", "16px").buildAndGet()
        assertTrue(specified(s.specifiedFlags, Style.SPECIFIED_FONT_SIZE))
        assertEquals(16f, s.fontSize!!.floatValue(), 0.001f)
    }

    @Test
    fun testFontSizeKeyword() {
        val s = process("font-size", "xx-large").buildAndGet()
        assertTrue(specified(s.specifiedFlags, Style.SPECIFIED_FONT_SIZE))
        assertNotNull(s.fontSize)
    }

    @Test
    fun testFontSizeInvalid() {
        val s = process("font-size", "abc")
        assertFalse(specified(s.specifiedFlags, Style.SPECIFIED_FONT_SIZE))
    }

    // --- font-family ---

    @Test
    fun testFontFamilySingle() {
        val s = process("font-family", "Arial").buildAndGet()
        assertTrue(specified(s.specifiedFlags, Style.SPECIFIED_FONT_FAMILY))
        assertEquals(listOf("Arial"), s.fontFamily)
    }

    @Test
    fun testFontFamilyQuoted() {
        val s = process("font-family", "'Times New Roman'").buildAndGet()
        assertNotNull(s.fontFamily)
        assertEquals(1, s.fontFamily!!.size)
    }

    @Test
    fun testFontFamilyMultiple() {
        val s = process("font-family", "Arial, Helvetica, sans-serif").buildAndGet()
        assertEquals(3, s.fontFamily!!.size)
    }

    // --- font-weight ---

    @Test
    fun testFontWeightBold() {
        val s = process("font-weight", "bold").buildAndGet()
        assertTrue(specified(s.specifiedFlags, Style.SPECIFIED_FONT_WEIGHT))
        assertEquals(700f, s.fontWeight, 0.001f)
    }

    @Test
    fun testFontWeightNumeric() {
        val s = process("font-weight", "300").buildAndGet()
        assertEquals(300f, s.fontWeight, 0.001f)
    }

    @Test
    fun testFontWeightOutOfRange() {
        val s = process("font-weight", "1500")
        assertTrue(s.fontWeight.isNaN())
    }

    // --- font-style ---

    @Test
    fun testFontStyleItalic() {
        val s = process("font-style", "italic").buildAndGet()
        assertEquals(FontStyle.italic, s.fontStyle)
    }

    @Test
    fun testFontStyleOblique() {
        val s = process("font-style", "oblique").buildAndGet()
        assertEquals(FontStyle.oblique, s.fontStyle)
    }

    @Test
    fun testFontStyleNormal() {
        val s = process("font-style", "normal").buildAndGet()
        assertEquals(FontStyle.normal, s.fontStyle)
    }

    @Test
    fun testFontStyleInvalid() {
        val s = process("font-style", "bad")
        assertNull(s.fontStyle)
    }

    // --- font-stretch / font-width ---

    @Test
    fun testFontStretchKeyword() {
        val s = process("font-stretch", "condensed").buildAndGet()
        assertTrue(specified(s.specifiedFlags, Style.SPECIFIED_FONT_WIDTH))
        assertNotNull(s.fontWidth)
    }

    @Test
    fun testFontStretchPercentage() {
        val s = process("font-stretch", "50%").buildAndGet()
        assertEquals(50f, s.fontWidth, 0.001f)
    }

    @Test
    fun testFontStretchInvalid() {
        val s = process("font-stretch", "bad")
        assertTrue(s.fontWidth.isNaN())
    }

    @Test
    fun testFontStretchBelowMin() {
        val s = process("font-stretch", "-1%")
        assertTrue(s.fontWidth.isNaN())
    }

    // --- text-decoration ---

    @Test
    fun testTextDecorationUnderline() {
        val s = process("text-decoration", "underline").buildAndGet()
        assertEquals(TextDecoration.Underline, s.textDecoration)
    }

    @Test
    fun testTextDecorationLineThrough() {
        val s = process("text-decoration", "line-through").buildAndGet()
        assertEquals(TextDecoration.LineThrough, s.textDecoration)
    }

    @Test
    fun testTextDecorationOverline() {
        val s = process("text-decoration", "overline").buildAndGet()
        assertEquals(TextDecoration.Overline, s.textDecoration)
    }

    @Test
    fun testTextDecorationBlink() {
        val s = process("text-decoration", "blink").buildAndGet()
        assertEquals(TextDecoration.Blink, s.textDecoration)
    }

    @Test
    fun testTextDecorationNone() {
        val s = process("text-decoration", "none").buildAndGet()
        assertEquals(TextDecoration.None, s.textDecoration)
    }

    // --- direction ---

    @Test
    fun testDirectionLTR() {
        val s = process("direction", "ltr").buildAndGet()
        assertEquals(TextDirection.LTR, s.direction)
    }

    @Test
    fun testDirectionRTL() {
        val s = process("direction", "rtl").buildAndGet()
        assertEquals(TextDirection.RTL, s.direction)
    }

    // --- text-anchor ---

    @Test
    fun testTextAnchorStart() {
        val s = process("text-anchor", "start").buildAndGet()
        assertEquals(TextAnchor.Start, s.textAnchor)
    }

    @Test
    fun testTextAnchorMiddle() {
        val s = process("text-anchor", "middle").buildAndGet()
        assertEquals(TextAnchor.Middle, s.textAnchor)
    }

    @Test
    fun testTextAnchorEnd() {
        val s = process("text-anchor", "end").buildAndGet()
        assertEquals(TextAnchor.End, s.textAnchor)
    }

    // --- overflow ---

    @Test
    fun testOverflowVisible() {
        val s = process("overflow", "visible").buildAndGet()
        assertTrue(s.overflow!!)
    }

    @Test
    fun testOverflowHidden() {
        val s = process("overflow", "hidden").buildAndGet()
        assertFalse(s.overflow!!)
    }

    @Test
    fun testOverflowAuto() {
        val s = process("overflow", "auto").buildAndGet()
        assertTrue(s.overflow!!)
    }

    @Test
    fun testOverflowScroll() {
        val s = process("overflow", "scroll").buildAndGet()
        assertFalse(s.overflow!!)
    }

    // --- clip ---

    @Test
    fun testClipAuto() {
        val s = process("clip", "auto").buildAndGet()
        assertNull(s.clip)
    }

    @Test
    fun testClipRect() {
        val s = process("clip", "rect(0 10 20 30)").buildAndGet()
        assertNotNull(s.clip)
    }

    @Test
    fun testClipRectWithAuto() {
        val s = process("clip", "rect(auto, auto, auto, auto)").buildAndGet()
        assertNotNull(s.clip)
    }

    @Test
    fun testClipInvalid() {
        val s = process("clip", "somethingelse").buildAndGet()
        assertNull(s.clip)
    }

    // --- display ---

    @Test
    fun testDisplayBlock() {
        val s = process("display", "block").buildAndGet()
        assertTrue(specified(s.specifiedFlags, Style.SPECIFIED_DISPLAY))
        assertTrue(s.display!!)
    }

    @Test
    fun testDisplayNone() {
        val s = process("display", "none").buildAndGet()
        assertFalse(s.display!!)
    }

    @Test
    fun testDisplayInline() {
        val s = process("display", "inline").buildAndGet()
        assertTrue(s.display!!)
    }

    // --- visibility ---

    @Test
    fun testVisibilityVisible() {
        val s = process("visibility", "visible").buildAndGet()
        assertTrue(s.visibility!!)
    }

    @Test
    fun testVisibilityHidden() {
        val s = process("visibility", "hidden").buildAndGet()
        assertFalse(s.visibility!!)
    }

    @Test
    fun testVisibilityCollapse() {
        val s = process("visibility", "collapse").buildAndGet()
        assertFalse(s.visibility!!)
    }

    // --- stop-color / stop-opacity ---

    @Test
    fun testStopColor() {
        val s = process("stop-color", "#FF0000").buildAndGet()
        assertTrue(specified(s.specifiedFlags, Style.SPECIFIED_STOP_COLOR))
        assertIs<ColorValue>(s.stopColor)
    }

    @Test
    fun testStopColorCurrentColor() {
        val s = process("stop-color", "currentColor").buildAndGet()
        assertIs<CurrentColor>(s.stopColor)
    }

    @Test
    fun testStopOpacity() {
        val s = process("stop-opacity", "0.8").buildAndGet()
        assertEquals(0.8f, s.stopOpacity, 0.001f)
    }

    // --- clip-path / clip-rule ---

    @Test
    fun testClipPath() {
        val s = process("clip-path", "url(#clip1)").buildAndGet()
        assertTrue(specified(s.specifiedFlags, Style.SPECIFIED_CLIP_PATH))
        assertEquals(CSSClipPath.UrlClip("#clip1"), s.clipPath)
    }

    @Test
    fun testClipPathNone() {
        val s = process("clip-path", "none").buildAndGet()
        assertFalse(specified(s.specifiedFlags, Style.SPECIFIED_CLIP_PATH))
        assertNull(s.clipPath)
    }

    @Test
    fun testClipPathCircle() {
        val s = process("clip-path", "circle(50px at center center)").buildAndGet()
        assertTrue(specified(s.specifiedFlags, Style.SPECIFIED_CLIP_PATH))
        val cp = s.clipPath as CSSClipPath.ShapeClip
        assertEquals(GeometryBox.FILL_BOX, cp.refBox)
        val c = cp.shape as BasicShape.Circle
        assertEquals(ClipRadius.Len(CSSLength(50f)), c.r)
        assertEquals(ClipPosition.Center, c.cx)
        assertEquals(ClipPosition.Center, c.cy)
    }

    @Test
    fun testClipPathCirclePercentAt() {
        val s = process("clip-path", "circle(25% at left top)").buildAndGet()
        val cp = s.clipPath as CSSClipPath.ShapeClip
        val c = cp.shape as BasicShape.Circle
        assertEquals(ClipRadius.Len(CSSLength(25f, hu.oandras.ksvg.css.CssUnit.percent)), c.r)
        assertEquals(ClipPosition.Left, c.cx)
        assertEquals(ClipPosition.Top, c.cy)
    }

    @Test
    fun testClipPathCircleClosestSide() {
        val s = process("clip-path", "circle(closest-side at center)").buildAndGet()
        val c = (s.clipPath as CSSClipPath.ShapeClip).shape as BasicShape.Circle
        assertEquals(ClipRadius.ClosestSide, c.r)
    }

    @Test
    fun testClipPathEllipseFarthestSide() {
        val s = process("clip-path", "ellipse(farthest-side closest-side at 10px 20px)").buildAndGet()
        val e = (s.clipPath as CSSClipPath.ShapeClip).shape as BasicShape.Ellipse
        assertEquals(ClipRadius.FarthestSide, e.rx)
        assertEquals(ClipRadius.ClosestSide, e.ry)
        assertEquals(ClipPosition.Len(CSSLength(10f)), e.cx)
        assertEquals(ClipPosition.Len(CSSLength(20f)), e.cy)
    }

    @Test
    fun testClipPathEllipse() {
        val s = process("clip-path", "ellipse(30px 20px at 10px 15px)").buildAndGet()
        val cp = s.clipPath as CSSClipPath.ShapeClip
        val e = cp.shape as BasicShape.Ellipse
        assertEquals(ClipRadius.Len(CSSLength(30f)), e.rx)
        assertEquals(ClipRadius.Len(CSSLength(20f)), e.ry)
        assertEquals(ClipPosition.Len(CSSLength(10f)), e.cx)
        assertEquals(ClipPosition.Len(CSSLength(15f)), e.cy)
    }

    @Test
    fun testClipPathInset() {
        val s = process("clip-path", "inset(10px 20px round 5px)").buildAndGet()
        val cp = s.clipPath as CSSClipPath.ShapeClip
        val i = cp.shape as BasicShape.Inset
        assertEquals(10f, i.top.value)
        assertEquals(20f, i.right.value)
        assertEquals(10f, i.bottom.value)
        assertEquals(20f, i.left.value)
        assertEquals(5f, i.roundX?.value)
    }

    @Test
    fun testClipPathInsetFourValues() {
        val s = process("clip-path", "inset(1px 2px 3px 4px)").buildAndGet()
        val i = (s.clipPath as CSSClipPath.ShapeClip).shape as BasicShape.Inset
        assertEquals(1f, i.top.value)
        assertEquals(2f, i.right.value)
        assertEquals(3f, i.bottom.value)
        assertEquals(4f, i.left.value)
        assertNull(i.roundX)
    }

    @Test
    fun testClipPathInsetOneAndThreeValues() {
        val one = (process("clip-path", "inset(7px)").buildAndGet().clipPath as CSSClipPath.ShapeClip).shape
        val i1 = one as BasicShape.Inset
        assertEquals(7f, i1.top.value)
        assertEquals(7f, i1.right.value)
        assertEquals(7f, i1.bottom.value)
        assertEquals(7f, i1.left.value)
        assertNull(i1.roundX)

        val three = (process("clip-path", "inset(1px 2px 3px)").buildAndGet().clipPath as CSSClipPath.ShapeClip).shape
        val i3 = three as BasicShape.Inset
        assertEquals(1f, i3.top.value)
        assertEquals(2f, i3.right.value)
        assertEquals(3f, i3.bottom.value)
        assertEquals(2f, i3.left.value)
    }

    @Test
    fun testClipPathPolygon() {
        val s = process("clip-path", "polygon(0px 0px, 100px 0px, 50px 100px)").buildAndGet()
        val cp = s.clipPath as CSSClipPath.ShapeClip
        val p = cp.shape as BasicShape.Polygon
        assertEquals(6, p.points.size)
        assertEquals(FillRule.UNSPECIFIED, p.fillRule)
    }

    @Test
    fun testClipPathPolygonFillRule() {
        val s = process("clip-path", "polygon(evenodd, 0px 0px, 100px 0px, 50px 100px)").buildAndGet()
        val p = (s.clipPath as CSSClipPath.ShapeClip).shape as BasicShape.Polygon
        assertEquals(FillRule.EVEN_ODD, p.fillRule)
    }

    @Test
    fun testClipPathGeometryBox() {
        val s = process("clip-path", "circle(50% at center) fill-box").buildAndGet()
        val cp = s.clipPath as CSSClipPath.ShapeClip
        assertEquals(GeometryBox.FILL_BOX, cp.refBox)
    }

    @Test
    fun testClipPathRect() {
        val s = process("clip-path", "rect(10px 90px 80px 20px round 5px)").buildAndGet()
        val r = (s.clipPath as CSSClipPath.ShapeClip).shape as BasicShape.Rect
        assertEquals(10f, r.top.value)
        assertEquals(90f, r.right.value)
        assertEquals(80f, r.bottom.value)
        assertEquals(20f, r.left.value)
        assertEquals(5f, r.roundX?.value)
    }

    @Test
    fun testClipPathXywh() {
        val s = process("clip-path", "xywh(10px 20px 100px 50px round 8px / 4px)").buildAndGet()
        val r = (s.clipPath as CSSClipPath.ShapeClip).shape as BasicShape.Xywh
        assertEquals(10f, r.x.value)
        assertEquals(20f, r.y.value)
        assertEquals(100f, r.w.value)
        assertEquals(50f, r.h.value)
        assertEquals(8f, r.roundX?.value)
        assertEquals(4f, r.roundY?.value)
    }

    @Test
    fun testClipPathPath() {
        val s = process("clip-path", "path(evenodd, \"M0 0H100V100H0Z\")").buildAndGet()
        val p = (s.clipPath as CSSClipPath.ShapeClip).shape as BasicShape.Path
        assertEquals(FillRule.EVEN_ODD, p.fillRule)
        assertFalse(p.path.isEmpty)
    }

    @Test
    fun testClipPathPathSingleQuotes() {
        val s = process("clip-path", "path('M0 0L100 0L50 100Z')").buildAndGet()
        val p = (s.clipPath as CSSClipPath.ShapeClip).shape as BasicShape.Path
        assertEquals(FillRule.UNSPECIFIED, p.fillRule)
        assertFalse(p.path.isEmpty)
    }

    @Test
    fun testClipPathOffsetPosition() {
        val s = process("clip-path", "circle(40px at left 10px top 20px)").buildAndGet()
        val c = (s.clipPath as CSSClipPath.ShapeClip).shape as BasicShape.Circle
        assertEquals(
            ClipPosition.Offset(ClipPosition.Left, CSSLength(10f)),
            c.cx,
        )
        assertEquals(
            ClipPosition.Offset(ClipPosition.Top, CSSLength(20f)),
            c.cy,
        )
    }

    @Test
    fun testClipPathOffsetPositionThreeValues() {
        val s = process("clip-path", "circle(40px at right 10px bottom)").buildAndGet()
        val c = (s.clipPath as CSSClipPath.ShapeClip).shape as BasicShape.Circle
        assertEquals(
            ClipPosition.Offset(ClipPosition.Right, CSSLength(10f)),
            c.cx,
        )
        assertEquals(ClipPosition.Bottom, c.cy)
    }

    @Test
    fun testClipPathPositionVerticalFirst() {
        val s = process("clip-path", "circle(40px at top left)").buildAndGet()
        val c = (s.clipPath as CSSClipPath.ShapeClip).shape as BasicShape.Circle
        assertEquals(ClipPosition.Left, c.cx)
        assertEquals(ClipPosition.Top, c.cy)
    }

    @Test
    fun testClipPathOffsetPositionOtherOrder() {
        val s = process("clip-path", "circle(40px at left bottom 20px)").buildAndGet()
        val c = (s.clipPath as CSSClipPath.ShapeClip).shape as BasicShape.Circle
        assertEquals(ClipPosition.Left, c.cx)
        assertEquals(ClipPosition.Offset(ClipPosition.Bottom, CSSLength(20f)), c.cy)
    }

    @Test
    fun testClipPathInvalid() {
        assertNull(process("clip-path", "circle(foo)").buildAndGet().clipPath)
        assertNull(process("clip-path", "rect(0 0 10)").buildAndGet().clipPath)
        assertNull(process("clip-path", "xywh(0 0 10)").buildAndGet().clipPath)
        assertNull(process("clip-path", "xywh(0 0 -10 10)").buildAndGet().clipPath)
        assertNull(process("clip-path", "path(\"\")").buildAndGet().clipPath)
        assertNull(process("clip-path", "path(not-a-path!!!)").buildAndGet().clipPath)
        assertNull(process("clip-path", "circle(-5px)").buildAndGet().clipPath)
        // A lone keyword+offset pair is the 3-4 value syntax without its
        // second axis, not a two-value position.
        assertNull(process("clip-path", "circle(40px at left 10px)").buildAndGet().clipPath)
        assertNull(process("clip-path", "circle(40px at center 10px)").buildAndGet().clipPath)
        // Both keywords of a two-value position must sit on different axes.
        assertNull(process("clip-path", "circle(40px at top top)").buildAndGet().clipPath)
        assertNull(process("clip-path", "circle(40px at left left)").buildAndGet().clipPath)
        assertNull(process("clip-path", "circle(40px at 10px left)").buildAndGet().clipPath)
        assertNull(process("clip-path", "circle(near-side)").buildAndGet().clipPath)
        assertNull(process("clip-path", "polygon(0px 0px, 1px)").buildAndGet().clipPath)
        // Per-corner radius lists (CSS Borders 4) are not supported: rejected
        // instead of being read as a single elliptical radius pair.
        assertNull(process("clip-path", "inset(10px round 5px 3px)").buildAndGet().clipPath)
        assertNull(process("clip-path", "rect(0 0 10 10 round 1px 2px 3px 4px)").buildAndGet().clipPath)
    }

    @Test
    fun testClipPathUrlRegression() {
        val s = process("clip-path", "URL(#clip1)").buildAndGet()
        assertEquals(CSSClipPath.UrlClip("#clip1"), s.clipPath)
    }

    @Test
    fun testClipRuleNonZero() {
        val s = process("clip-rule", "nonzero").buildAndGet()
        assertEquals(FillRule.NON_ZERO, s.clipRule)
    }

    @Test
    fun testClipRuleEvenOdd() {
        val s = process("clip-rule", "evenodd").buildAndGet()
        assertEquals(FillRule.EVEN_ODD, s.clipRule)
    }

    // --- mask ---

    @Test
    fun testMask() {
        val s = process("mask", "url(#mask1)").buildAndGet()
        assertTrue(specified(s.specifiedFlags, Style.SPECIFIED_MASK))
        assertEquals("#mask1", s.mask)
    }

    // --- filter ---

    @Test
    fun testFilter() {
        val s = process("filter", "url(#blur1)").buildAndGet()
        assertTrue(specified(s.specifiedFlags, Style.SPECIFIED_FILTER))
        assertEquals("#blur1", s.filter)
    }

    // --- flood-color / flood-opacity ---

    @Test
    fun testFloodColor() {
        val s = process("flood-color", "#AABBCC").buildAndGet()
        assertTrue(specified(s.specifiedFlags, Style.SPECIFIED_FLOOD_COLOR))
        assertIs<ColorValue>(s.floodColor)
    }

    @Test
    fun testFloodColorCurrentColor() {
        val s = process("flood-color", "currentColor").buildAndGet()
        assertIs<CurrentColor>(s.floodColor)
    }

    @Test
    fun testFloodOpacity() {
        val s = process("flood-opacity", "0.3").buildAndGet()
        assertEquals(0.3f, s.floodOpacity, 0.001f)
    }

    // --- lighting-color ---

    @Test
    fun testLightingColor() {
        val s = process("lighting-color", "#FFF").buildAndGet()
        assertTrue(specified(s.specifiedFlags, Style.SPECIFIED_LIGHTING_COLOR))
        assertIs<ColorValue>(s.lightingColor)
    }

    // --- solid-color / solid_opacity (attribute only) ---

    @Test
    fun testSolidColorFromAttribute() {
        val s = process("solid-color", "#123456", isFromAttribute = true).buildAndGet()
        assertTrue(specified(s.specifiedFlags, Style.SPECIFIED_SOLID_COLOR))
        assertIs<ColorValue>(s.solidColor)
    }

    @Test
    fun testSolidColorNotFromAttributeIgnored() {
        val s = process("solid-color", "#123456", isFromAttribute = false)
        assertFalse(specified(s.specifiedFlags, Style.SPECIFIED_SOLID_COLOR))
    }

    @Test
    fun testSolidOpacityFromAttribute() {
        val s = process("solid-opacity", "0.5", isFromAttribute = true).buildAndGet()
        assertEquals(0.5f, s.solidOpacity, 0.001f)
    }

    // --- viewport-fill / viewport-fill-opacity ---

    @Test
    fun testViewportFill() {
        val s = process("viewport-fill", "#00FF00").buildAndGet()
        assertTrue(specified(s.specifiedFlags, Style.SPECIFIED_VIEWPORT_FILL))
        assertIs<ColorValue>(s.viewportFill)
    }

    @Test
    fun testViewportFillOpacity() {
        val s = process("viewport-fill-opacity", "0.6").buildAndGet()
        assertEquals(0.6f, s.viewportFillOpacity, 0.001f)
    }

    // --- vector-effect ---

    @Test
    fun testVectorEffectNone() {
        val s = process("vector-effect", "none").buildAndGet()
        assertEquals(VectorEffect.None, s.vectorEffect)
    }

    @Test
    fun testVectorEffectNonScalingStroke() {
        val s = process("vector-effect", "non-scaling-stroke").buildAndGet()
        assertEquals(VectorEffect.NonScalingStroke, s.vectorEffect)
    }

    @Test
    fun testVectorEffectInvalid() {
        val s = process("vector-effect", "invalid")
        assertNull(s.vectorEffect)
    }

    // --- image-rendering ---

    @Test
    fun testImageRenderingAuto() {
        val s = process("image-rendering", "auto").buildAndGet()
        assertEquals(RenderQuality.auto, s.imageRendering)
    }

    @Test
    fun testImageRenderingOptimizeQuality() {
        val s = process("image-rendering", "optimizeQuality").buildAndGet()
        assertEquals(RenderQuality.optimizeQuality, s.imageRendering)
    }

    @Test
    fun testImageRenderingOptimizeSpeed() {
        val s = process("image-rendering", "optimizeSpeed").buildAndGet()
        assertEquals(RenderQuality.optimizeSpeed, s.imageRendering)
    }

    // --- marker ---

    @Test
    fun testMarker() {
        val s = process("marker", "url(#arrow)").buildAndGet()
        assertTrue(specified(s.specifiedFlags, Style.SPECIFIED_MARKER_START))
        assertTrue(specified(s.specifiedFlags, Style.SPECIFIED_MARKER_MID))
        assertTrue(specified(s.specifiedFlags, Style.SPECIFIED_MARKER_END))
        assertEquals("#arrow", s.markerStart)
        assertEquals("#arrow", s.markerMid)
        assertEquals("#arrow", s.markerEnd)
    }

    @Test
    fun testMarkerStart() {
        val s = process("marker-start", "url(#start)").buildAndGet()
        assertEquals("#start", s.markerStart)
    }

    @Test
    fun testMarkerMid() {
        val s = process("marker-mid", "url(#mid)").buildAndGet()
        assertEquals("#mid", s.markerMid)
    }

    @Test
    fun testMarkerEnd() {
        val s = process("marker-end", "url(#end)").buildAndGet()
        assertEquals("#end", s.markerEnd)
    }

    @Test
    fun testMarkerNone() {
        val s = process("marker", "none").buildAndGet()
        assertNull(s.markerStart)
        assertNull(s.markerMid)
        assertNull(s.markerEnd)
    }

    // --- letter-spacing / word-spacing ---

    @Test
    fun testLetterSpacingNormal() {
        val s = process("letter-spacing", "normal").buildAndGet()
        assertEquals(CSSLength.ZERO, s.letterSpacing)
    }

    @Test
    fun testLetterSpacingValue() {
        val s = process("letter-spacing", "2px").buildAndGet()
        assertEquals(2f, s.letterSpacing!!.floatValue(), 0.001f)
    }

    @Test
    fun testLetterSpacingPercentIgnored() {
        val s = process("letter-spacing", "5%")
        assertNull(s.letterSpacing)
    }

    @Test
    fun testWordSpacingNormal() {
        val s = process("word-spacing", "normal").buildAndGet()
        assertEquals(CSSLength.ZERO, s.wordSpacing)
    }

    @Test
    fun testWordSpacingValue() {
        val s = process("word-spacing", "3em").buildAndGet()
        assertEquals(3f, s.wordSpacing!!.floatValue(), 0.001f)
    }

    // --- stroke-opacity ---

    @Test
    fun testStrokeOpacity() {
        val s = process("stroke-opacity", "0.9").buildAndGet()
        assertTrue(specified(s.specifiedFlags, Style.SPECIFIED_STROKE_OPACITY))
        assertEquals(0.9f, s.strokeOpacity, 0.001f)
    }

    // --- stroke-dasharray with commas and spaces mixed ---

    @Test
    fun testStrokeDashArrayMixedSeparators() {
        val s = process("stroke-dasharray", "5, 10 15").buildAndGet()
        assertNotNull(s.strokeDashArray)
        assertEquals(3, s.strokeDashArray!!.size)
    }

    // --- font shorthand ---

    @Test
    fun testFontShorthand() {
        val s = process("font", "italic bold 16px Arial", isFromAttribute = false).buildAndGet()
        assertTrue(specified(s.specifiedFlags, Style.SPECIFIED_FONT_SIZE))
        assertTrue(specified(s.specifiedFlags, Style.SPECIFIED_FONT_WEIGHT))
        assertTrue(specified(s.specifiedFlags, Style.SPECIFIED_FONT_STYLE))
        assertEquals(FontStyle.italic, s.fontStyle)
        assertEquals(700f, s.fontWeight, 0.001f)
    }

    @Test
    fun testFontShorthandFromAttributeIgnored() {
        val s = process("font", "italic bold 16px Arial", isFromAttribute = true)
        assertFalse(specified(s.specifiedFlags, Style.SPECIFIED_FONT_SIZE))
    }

    @Test
    fun testFontShorthandSystemFont() {
        // System-font keywords have no generic-family mapping: the whole
        // declaration is ignored (no DEFAULT-mapping), setting no flags.
        for (keyword in listOf("caption", "icon", "menu", "message-box", "small-caption", "status-bar")) {
            val s = process("font", keyword, isFromAttribute = false).buildAndGet()
            assertEquals(0L, s.specifiedFlags)
            assertNull(s.fontFamily)
        }
    }

    // --- mix-blend-mode / isolation (only from style, not attribute) ---

    @Test
    fun testMixBlendMode() {
        val s = process("mix-blend-mode", "multiply", isFromAttribute = false).buildAndGet()
        assertEquals(CSSBlendMode.multiply, s.mixBlendMode)
    }

    @Test
    fun testMixBlendModeFromAttributeIgnored() {
        val s = process("mix-blend-mode", "multiply", isFromAttribute = true)
        assertFalse(specified(s.specifiedFlags, Style.SPECIFIED_MIX_BLEND_MODE))
    }

    @Test
    fun testIsolation() {
        val s = process("isolation", "isolate", isFromAttribute = false).buildAndGet()
        assertEquals(Isolation.isolate, s.isolation)
    }

    @Test
    fun testIsolationFromAttributeIgnored() {
        val s = process("isolation", "isolate", isFromAttribute = true)
        assertFalse(specified(s.specifiedFlags, Style.SPECIFIED_ISOLATION))
    }

    @Test
    fun testIsolationAuto() {
        val s = process("isolation", "auto", isFromAttribute = false).buildAndGet()
        assertEquals(Isolation.auto, s.isolation)
    }

    // --- enable-background (presentation attribute AND style) ---

    @Test
    fun testEnableBackgroundAccumulate() {
        val s = process("enable-background", "accumulate").buildAndGet()
        assertEquals(EnableBackground.Accumulate, s.enableBackground)
        assertTrue(specified(s.specifiedFlags2, Style.SPECIFIED_ENABLE_BACKGROUND))
    }

    @Test
    fun testEnableBackgroundAccumulateFromAttribute() {
        // Unlike isolation, enable-background IS a presentation attribute.
        val s = process("enable-background", "accumulate", isFromAttribute = true).buildAndGet()
        assertEquals(EnableBackground.Accumulate, s.enableBackground)
        assertTrue(specified(s.specifiedFlags2, Style.SPECIFIED_ENABLE_BACKGROUND))
    }

    @Test
    fun testEnableBackgroundNew() {
        val s = process("enable-background", "new", isFromAttribute = true).buildAndGet()
        assertEquals(EnableBackground.New(null, null, null, null), s.enableBackground)
        assertTrue(specified(s.specifiedFlags2, Style.SPECIFIED_ENABLE_BACKGROUND))
    }

    @Test
    fun testEnableBackgroundNewWithBounds() {
        val s = process("enable-background", "new 10 20 30 40").buildAndGet()
        assertEquals(EnableBackground.New(10f, 20f, 30f, 40f), s.enableBackground)
        assertTrue(specified(s.specifiedFlags2, Style.SPECIFIED_ENABLE_BACKGROUND))
    }

    @Test
    fun testEnableBackgroundCaseInsensitiveAndCommaSeparated() {
        val s = process("enable-background", "NEW 0, 0, 100, 50").buildAndGet()
        assertEquals(EnableBackground.New(0f, 0f, 100f, 50f), s.enableBackground)
        assertTrue(specified(s.specifiedFlags2, Style.SPECIFIED_ENABLE_BACKGROUND))
    }

    @Test
    fun testEnableBackgroundInvalid() {
        for (value in listOf("banana", "new 10 20", "new 10 20 30", "accumulate new", "new 1 2 3 x", "new 1 2 3 4 5")) {
            val s = process("enable-background", value).buildAndGet()
            assertFalse(specified(s.specifiedFlags2, Style.SPECIFIED_ENABLE_BACKGROUND))
            assertNull(s.enableBackground)
        }
    }

    @Test
    fun testEnableBackgroundResetDefault() {
        val builder = Style.Builder()
        builder.reset(Style())
        builder.resetNonInheritingProperties(isRootSVG = false)
        assertEquals(EnableBackground.Accumulate, builder.enableBackground)
    }

    // --- color-interpolation (presentation attribute AND style, inherited) ---

    @Test
    fun testColorInterpolationLinearRgb() {
        val s = process("color-interpolation", "linearRGB").buildAndGet()
        assertEquals(ColorInterpolation.LINEAR_RGB, s.colorInterpolation)
        assertTrue(specified(s.specifiedFlags2, Style.SPECIFIED_COLOR_INTERPOLATION))
    }

    @Test
    fun testColorInterpolationLinearRgbFromAttribute() {
        // color-interpolation IS a presentation attribute (SVG 1.1).
        val s = process("color-interpolation", "linearRGB", isFromAttribute = true).buildAndGet()
        assertEquals(ColorInterpolation.LINEAR_RGB, s.colorInterpolation)
        assertTrue(specified(s.specifiedFlags2, Style.SPECIFIED_COLOR_INTERPOLATION))
    }

    @Test
    fun testColorInterpolationSrgbAndAuto() {
        assertEquals(
            ColorInterpolation.SRGB,
            process("color-interpolation", "sRGB").buildAndGet().colorInterpolation,
        )
        assertEquals(
            ColorInterpolation.AUTO,
            process("color-interpolation", "auto").buildAndGet().colorInterpolation,
        )
    }

    @Test
    fun testColorInterpolationInvalid() {
        for (value in listOf("banana", "linear-rgb", "")) {
            val s = process("color-interpolation", value).buildAndGet()
            assertFalse(specified(s.specifiedFlags2, Style.SPECIFIED_COLOR_INTERPOLATION))
            assertEquals(ColorInterpolation.UNSPECIFIED, s.colorInterpolation)
        }
    }

    @Test
    fun testColorInterpolationDefaultUnspecified() {
        // Inherited: no reset in resetNonInheritingProperties; fresh styles stay unspecified.
        val builder = Style.Builder()
        builder.reset(Style())
        builder.resetNonInheritingProperties(isRootSVG = false)
        assertEquals(ColorInterpolation.UNSPECIFIED, builder.colorInterpolation)
        assertEquals(ColorInterpolation.UNSPECIFIED, Style().colorInterpolation)
    }

    // --- shape-rendering / text-rendering / color-rendering ---

    @Test
    fun testShapeRenderingCrispEdges() {
        val s = process("shape-rendering", "crispEdges", isFromAttribute = true).buildAndGet()
        assertEquals(ShapeRendering.crispEdges, s.shapeRendering)
        assertTrue(specified(s.specifiedFlags2, Style.SPECIFIED_SHAPE_RENDERING))
    }

    @Test
    fun testShapeRenderingFromStyle() {
        val s = process("shape-rendering", "optimizeSpeed").buildAndGet()
        assertEquals(ShapeRendering.optimizeSpeed, s.shapeRendering)
    }

    @Test
    fun testShapeRenderingInvalid() {
        val s = process("shape-rendering", "banana").buildAndGet()
        assertFalse(specified(s.specifiedFlags2, Style.SPECIFIED_SHAPE_RENDERING))
        assertNull(s.shapeRendering)
    }

    @Test
    fun testTextRenderingOptimizeSpeed() {
        val s = process("text-rendering", "optimizeSpeed", isFromAttribute = true).buildAndGet()
        assertEquals(TextRendering.optimizeSpeed, s.textRendering)
        assertTrue(specified(s.specifiedFlags2, Style.SPECIFIED_TEXT_RENDERING))
    }

    @Test
    fun testTextRenderingInvalid() {
        val s = process("text-rendering", "smooth").buildAndGet()
        assertFalse(specified(s.specifiedFlags2, Style.SPECIFIED_TEXT_RENDERING))
        assertNull(s.textRendering)
    }

    @Test
    fun testColorRenderingParsed() {
        val s = process("color-rendering", "optimizeQuality", isFromAttribute = true).buildAndGet()
        assertEquals(ColorRendering.optimizeQuality, s.colorRendering)
        assertTrue(specified(s.specifiedFlags2, Style.SPECIFIED_COLOR_RENDERING))
    }

    @Test
    fun testColorRenderingInvalid() {
        val s = process("color-rendering", "banana").buildAndGet()
        assertFalse(specified(s.specifiedFlags2, Style.SPECIFIED_COLOR_RENDERING))
        assertNull(s.colorRendering)
    }

    // --- mask-type ---

    @Test
    fun testMaskTypeLuminance() {
        val s = process("mask-type", "luminance").buildAndGet()
        assertEquals(MaskType.luminance, s.maskType)
    }

    @Test
    fun testMaskTypeAlpha() {
        val s = process("mask-type", "alpha").buildAndGet()
        assertEquals(MaskType.alpha, s.maskType)
    }

    // --- font-kerning ---

    @Test
    fun testFontKerning() {
        val s = process("font-kerning", "normal", isFromAttribute = false).buildAndGet()
        assertEquals(FontKerning.normal, s.fontKerning)
    }

    @Test
    fun testFontKerningFromAttributeIgnored() {
        val s = process("font-kerning", "normal", isFromAttribute = true)
        assertFalse(specified(s.specifiedFlags, Style.SPECIFIED_FONT_KERNING))
    }

    // --- Builder resetNonInheritingProperties ---

    @Test
    fun testResetNonInheritingRoot() {
        val builder = Style.Builder()
        builder.display = false
        builder.opacity = 0.5f
        builder.resetNonInheritingProperties(isRootSVG = true)
        assertEquals(true, builder.display)
        assertEquals(true, builder.overflow)
        assertEquals(1f, builder.opacity, 0.001f)
    }

    @Test
    fun testResetNonInheritingNonRoot() {
        val builder = Style.Builder()
        builder.resetNonInheritingProperties(isRootSVG = false)
        assertEquals(false, builder.overflow)
    }

    // --- Builder toBuilder roundtrip ---

    @Test
    fun testToBuilderRoundtrip() {
        val original = process("fill", "#FF0000")
            .apply { opacity = 0.5f }
            .buildAndGet()
        val rebuilt = original.toBuilder().buildAndGet()
        assertTrue(original.isSpecified(Style.SPECIFIED_FILL))
        assertEquals(original.opacity, rebuilt.opacity, 0.001f)
    }

    // --- Builder caching: build same data twice returns same instance ---

    @Test
    fun testBuildCaching() {
        val builder = Style.Builder()
        builder.reset(Style())
        builder.fill = ColorValue.of(0xFF0000)
        val first = builder.build()
        val second = builder.build()
        assertTrue(first === second)
    }
}
