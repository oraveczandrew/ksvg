package hu.oandras.ksvg.dom.style

import hu.oandras.ksvg.assertIs
import hu.oandras.ksvg.css.CSSLength
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
        Style.processStyleProperty(builder, attr, value, isFromAttribute)
        return builder
    }

    private fun Style.Builder.buildAndGet(): Style = build()

    private fun specified(flags: Long, flag: Long): Boolean = (flags and flag) != 0L

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
        assertEquals(FillRule.NonZero, s.fillRule)
    }

    @Test
    fun testFillRuleEvenOdd() {
        val s = process("fill-rule", "evenodd").buildAndGet()
        assertEquals(FillRule.EvenOdd, s.fillRule)
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
        assertEquals(LineCap.Round, s.strokeLineCap)
    }

    @Test
    fun testStrokeLineCapSquare() {
        val s = process("stroke-linecap", "square").buildAndGet()
        assertEquals(LineCap.Square, s.strokeLineCap)
    }

    @Test
    fun testStrokeLineCapButt() {
        val s = process("stroke-linecap", "butt").buildAndGet()
        assertEquals(LineCap.Butt, s.strokeLineCap)
    }

    @Test
    fun testStrokeLineCapInvalid() {
        val s = process("stroke-linecap", "invalid")
        assertNull(s.strokeLineCap)
    }

    // --- stroke-linejoin ---

    @Test
    fun testStrokeLineJoinMiter() {
        val s = process("stroke-linejoin", "miter").buildAndGet()
        assertEquals(LineJoin.Miter, s.strokeLineJoin)
    }

    @Test
    fun testStrokeLineJoinBevel() {
        val s = process("stroke-linejoin", "bevel").buildAndGet()
        assertEquals(LineJoin.Bevel, s.strokeLineJoin)
    }

    @Test
    fun testStrokeLineJoinRound() {
        val s = process("stroke-linejoin", "round").buildAndGet()
        assertEquals(LineJoin.Round, s.strokeLineJoin)
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
        assertEquals("#clip1", s.clipPath)
    }

    @Test
    fun testClipRuleNonZero() {
        val s = process("clip-rule", "nonzero").buildAndGet()
        assertEquals(FillRule.NonZero, s.clipRule)
    }

    @Test
    fun testClipRuleEvenOdd() {
        val s = process("clip-rule", "evenodd").buildAndGet()
        assertEquals(FillRule.EvenOdd, s.clipRule)
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
        val s = process("font", "caption", isFromAttribute = false)
        assertFalse(specified(s.specifiedFlags, Style.SPECIFIED_FONT_SIZE))
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
