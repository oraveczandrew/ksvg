/*
 *    Copyright 2026 András Oravecz <info@oandras.hu>
 *
 *    Licensed under the Apache License, Version 2.0 (the "License");
 *    you may not use this file except in compliance with the License.
 *    You may obtain a copy of the License at
 *
 *        https://www.apache.org/licenses/LICENSE-2.0
 *
 *    Unless required by applicable law or agreed to in writing, software
 *    distributed under the License is distributed on an "AS IS" BASIS,
 *    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *    See the License for the specific language governing permissions and
 *    limitations under the License.
 */
package hu.oandras.ksvg

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Typeface
import hu.oandras.ksvg.dom.SVGImpl
import hu.oandras.ksvg.dom.core.PathDefinition
import hu.oandras.ksvg.dom.style.FontStyle
import hu.oandras.ksvg.dom.style.Style
import hu.oandras.ksvg.dom.style.parseFontFamily
import hu.oandras.ksvg.parser.parsePath
import hu.oandras.ksvg.render.createBitmap
import hu.oandras.ksvg.render.MarkerVector
import hu.oandras.ksvg.render.resolveRelativeFontWeight
import hu.oandras.ksvg.render.text.checkGenericFont
import hu.oandras.ksvg.test.countPixels
import hu.oandras.ksvg.test.renderWithLibrary
import hu.oandras.ksvg.utils.alpha
import hu.oandras.ksvg.utils.blue
import hu.oandras.ksvg.utils.green
import hu.oandras.ksvg.utils.red
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotSame
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.GraphicsMode

/**
 * Regression tests for audit P1 findings (tmp/AUDIT_FINDINGS.md).
 *
 * Covers: SMIL to-only/by-only float animation (base-relative resolution),
 * unknown calcMode fallback, dur="indefinite", case-insensitive !important,
 * audit round 4 (R1): stray coords after Z, empty input, use-cycle/depth guards,
 * image href/validity skip.
 * Raster assertions use NATIVE graphics + pixel reads (per AGENTS.md).
 */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class P1AuditReproTest {

    private fun drawAt(svg: SVGImpl, timeMs: Long, size: Int = 100): Int {
        val drawable = KSVGDrawable(svg)
        val bitmap = createBitmap(size, size)
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, size, size)
        svg.animationTimeMs = timeMs
        drawable.draw(canvas)
        return bitmap.getPixel(size / 2, size / 2)
    }

    @Test
    fun toOnlyOpacityAnimatesBaseToTarget() {
        val svg = SVG.getFromString(
            svg = """
                <svg width="100" height="100" viewBox="0 0 100 100">
                  <rect width="100" height="100" fill="red" opacity="0.8">
                    <animate attributeName="opacity" to="0.2" dur="1s" fill="freeze"/>
                  </rect>
                </svg>
            """.trimIndent(),
            parseAnimations = true
        ) as SVGImpl

        // SMIL to-animation: base + (to - base) * p.
        // t=0: base 0.8 -> alpha 204.
        assertEquals(204, drawAt(svg, 0L).alpha)
        // t=500ms: 0.8 + (0.2 - 0.8) * 0.5 = 0.5 -> alpha ~127.
        // (Before the fix the animation froze at `to` for the whole duration.)
        val mid = drawAt(svg, 500L).alpha
        assertTrue("expected midpoint near 127, got $mid", mid in 120..135)
        // t=dur (frozen): exactly `to` = 0.2 -> alpha 51.
        assertEquals(51, drawAt(svg, 1000L).alpha)
    }

    @Test
    fun byOnlyOpacityAnimatesBasePlusDelta() {
        val svg = SVG.getFromString(
            svg = """
                <svg width="100" height="100" viewBox="0 0 100 100">
                  <rect width="100" height="100" fill="red" opacity="0.5">
                    <animate attributeName="opacity" by="0.3" dur="1s" fill="freeze"/>
                  </rect>
                </svg>
            """.trimIndent(),
            parseAnimations = true
        ) as SVGImpl

        // SMIL by-animation: base + by * p.
        // t=0: base 0.5 -> alpha ~127.
        // (Before the fix the animation was dropped -> alpha 127 as well, but
        // frozen; the end value distinguishes: 0.8 -> 204 vs dropped 127.)
        val start = drawAt(svg, 0L).alpha
        assertTrue("expected start near 127, got $start", start in 120..135)
        // t=dur (frozen): base 0.5 + 0.3 = 0.8 -> alpha 204.
        assertEquals(204, drawAt(svg, 1000L).alpha)
    }

    @Test
    fun unknownCalcModeFallsBackToLinear() {
        val svg = SVG.getFromString(
            svg = """
                <svg width="100" height="100" viewBox="0 0 100 100">
                  <rect width="100" height="100" fill="red" opacity="0.0">
                    <animate attributeName="opacity" from="0.0" to="1.0" dur="1s" calcMode="bogus" fill="freeze"/>
                  </rect>
                </svg>
            """.trimIndent(),
            parseAnimations = true
        ) as SVGImpl

        // Must parse (no exception) and behave linearly: midpoint ~127.
        val mid = drawAt(svg, 500L).alpha
        assertTrue("expected linear midpoint near 127, got $mid", mid in 100..155)
        assertEquals(255, drawAt(svg, 1000L).alpha)
    }

    @Test
    fun indefiniteDurKeepsAnimationAlive() {
        val svg = SVG.getFromString(
            svg = """
                <svg width="100" height="100" viewBox="0 0 100 100">
                  <rect width="100" height="100" fill="red">
                    <animate attributeName="opacity" from="0.0" to="1.0" dur="indefinite"/>
                  </rect>
                </svg>
            """.trimIndent(),
            parseAnimations = true
        ) as SVGImpl

        // Animation active from the start: alpha ~0.
        // (Before the fix dur parsed as 0 -> animation dropped -> alpha 255.)
        assertEquals(0, drawAt(svg, 500L).alpha)
    }

    @Test
    fun colorToOnlyAnimatesBaseToTarget() {
        val svg = SVG.getFromString(
            svg = """
                <svg width="100" height="100" viewBox="0 0 100 100">
                  <rect width="100" height="100" fill="red">
                    <animate attributeName="fill" to="blue" dur="1s" fill="freeze"/>
                  </rect>
                </svg>
            """.trimIndent(),
            parseAnimations = true
        ) as SVGImpl

        // SMIL to-animation on colors: interpolate base -> target.
        // t=0: base red.
        val start = drawAt(svg, 0L)
        assertEquals(255, start.red)
        assertEquals(0, start.blue)
        // t=500ms: midpoint purple (red ~128, blue ~127).
        val mid = drawAt(svg, 500L)
        assertTrue("expected mid red near 128, got ${mid.red}", mid.red in 115..140)
        assertTrue("expected mid blue near 127, got ${mid.blue}", mid.blue in 115..140)
        // t=dur (frozen): exactly blue.
        // (Before the fix the fill froze at `to` for the whole duration.)
        val end = drawAt(svg, 1000L)
        assertEquals(0, end.red)
        assertEquals(255, end.blue)
    }

    @Test
    fun uppercaseUrlPaintReferenceResolves() {
        val svg = SVG.getFromString(
            svg = """
                <svg width="100" height="100" viewBox="0 0 100 100">
                  <defs>
                    <linearGradient id="g">
                      <stop offset="0%" stop-color="red"/>
                      <stop offset="100%" stop-color="blue"/>
                    </linearGradient>
                  </defs>
                  <rect width="100" height="100" fill="URL(#g)"/>
                </svg>
            """.trimIndent()
        ) as SVGImpl

        // Uppercase URL( must resolve the gradient (midpoint is purple).
        // (Before the fix the paint fell back to black.)
        val mid = drawAt(svg, 0L)
        assertTrue("expected purple midpoint, got r=${mid.red} b=${mid.blue}", mid.red > 80 && mid.blue > 80)
    }

    @Test
    fun uppercaseNthChildOddMatches() {
        val svg = SVG.getFromString(
            svg = """
                <svg width="100" height="100" viewBox="0 0 100 100">
                  <style>rect:nth-child(ODD) { fill: blue; }</style>
                  <rect x="0" y="0" width="50" height="100" fill="red"/>
                  <rect x="50" y="0" width="50" height="100" fill="red"/>
                </svg>
            """.trimIndent()
        ) as SVGImpl

        val drawable = KSVGDrawable(svg)
        val bitmap = createBitmap(100, 100)
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, 100, 100)
        drawable.draw(canvas)

        // First rect matches :nth-child(ODD) -> blue; second stays red.
        assertEquals(255, bitmap.getPixel(25, 50).blue)
        assertEquals(255, bitmap.getPixel(75, 50).red)
    }

    @Test
    fun uppercaseDegHueParses() {
        val svg = SVG.getFromString(
            svg = """
                <svg width="100" height="100" viewBox="0 0 100 100">
                  <rect width="100" height="100" fill="hsl(120DEG 100% 50%)"/>
                </svg>
            """.trimIndent()
        ) as SVGImpl

        // hsl(120deg) is pure green.
        val px = drawAt(svg, 0L)
        assertEquals(255, px.green)
    }

    @Test
    fun uppercaseImportantDoesNotDropRestOfStylesheet() {
        val svg = SVG.getFromString(
            svg = """
                <svg width="100" height="100" viewBox="0 0 100 100">
                  <style>.a { fill: red !IMPORTANT; } .b { fill: blue; }</style>
                  <rect width="100" height="100" class="b"/>
                </svg>
            """.trimIndent()
        ) as SVGImpl

        val drawable = KSVGDrawable(svg)
        val bitmap = createBitmap(100, 100)
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, 100, 100)
        drawable.draw(canvas)

        // The .b rule after the !IMPORTANT declaration must still apply.
        // (Before the fix the whole stylesheet was dropped -> black fill.)
        assertEquals(255, bitmap.getPixel(50, 50).blue)
    }

    // Audit #24: stray coordinates after Z must terminate the path instead of
    // looping forever (appending CLOSE segments until OOM).
    @Test
    fun strayCoordsAfterZTerminate() {
        val path: PathDefinition
        val clean: PathDefinition
        with(NoopLoggerContext) {
            path = parsePath("M0 0Z10 10")
            clean = parsePath("M0 0Z")
        }
        assertTrue(path.commandsEquals(clean))
    }

    // Audit #44: empty input must raise the parse contract, not StringIndexOutOfBounds.
    @Test
    fun emptyInputThrowsParseException() {
        try {
            SVG.getFromString("")
            throw AssertionError("expected KSVGParseException for empty input")
        } catch (e: KSVGParseException) {
            assertTrue(e.message?.isNotEmpty() == true)
        }
    }

    // Audit #23: an anonymous cyclic <use> must render siblings instead of
    // overflowing the stack.
    @Test
    fun useSymbolCycleRendersSiblings() {
        val out = renderWithLibrary(
            """<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">""" +
                """<symbol id="s"><use href="#s" width="10" height="10"/></symbol>""" +
                """<use href="#s" width="50" height="50"/>""" +
                """<rect x="10" y="10" width="40" height="40" fill="#FF0000"/></svg>""",
            Bitmap.createBitmap(100, 100, Bitmap.Config.ARGB_8888)
        )
        assertTrue(countPixels(out) { it.red == 255 } > 1000)
    }

    // Audit #23 (depth cap): pathological nesting truncates gracefully.
    @Test
    fun deepNestingTruncatesGracefully() {
        val deep = "<g>".repeat(3000) + """<rect width="10" height="10"/>""" + "</g>".repeat(3000)
        val out = renderWithLibrary(
            """<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">""" +
                deep +
                """<rect x="10" y="10" width="40" height="40" fill="#FF0000"/></svg>""",
            Bitmap.createBitmap(100, 100, Bitmap.Config.ARGB_8888)
        )
        assertTrue(countPixels(out) { it.red == 255 } > 1000)
    }

    // Audit #32: a broken <image> (missing href, bad geometry) is skipped,
    // siblings still render.
    @Test
    fun brokenImageIsSkipped() {
        val out = renderWithLibrary(
            """<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">""" +
                """<image width="10" height="10"/>""" +
                """<image width="bogus" height="10" href="x.png"/>""" +
                """<rect x="10" y="10" width="40" height="40" fill="#FF0000"/></svg>""",
            Bitmap.createBitmap(100, 100, Bitmap.Config.ARGB_8888)
        )
        assertTrue(countPixels(out) { it.red == 255 } > 1000)
    }

    // Audit #30: negative arc radii take abs() instead of dropping the path tail.
    @Test
    fun negativeArcRadiiTreatedAsAbs() {
        val positive: PathDefinition
        val negative: PathDefinition
        with(NoopLoggerContext) {
            positive = parsePath("M0 0 A30 50 0 0 1 60 0 L100 100")
            negative = parsePath("M0 0 A-30 50 0 0 1 60 0 L100 100")
        }
        assertTrue(negative.commandsEquals(positive))
    }

    // Audit #31: unclamped acos(p/n) yields NaN arcs when FP rounding pushes the
    // ratio to 1±e (start direction nearly +x). Fuzz near-horizontal arcs: every
    // non-degenerate one must rasterize something.
    @Test
    fun nearHorizontalArcsAlwaysRasterize() {
        var checked = 0
        for (r in listOf(40f, 100f, 400f)) {
            for (dy in listOf(0.0001f, 0.001f, 0.01f)) {
                for (flags in listOf("0 0", "0 1", "1 0", "1 1")) {
                    val d = "M20 50 A$r $r 0 $flags 80 ${50 + dy}"
                    val out = renderWithLibrary(
                        """<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">""" +
                            """<path d="$d" fill="#FF0000"/></svg>""",
                        Bitmap.createBitmap(100, 100, Bitmap.Config.ARGB_8888)
                    )
                    assertTrue(
                        "arc d=$d rasterized nothing",
                        countPixels(out) { it.red == 255 } > 0
                    )
                    checked++
                }
            }
        }
        assertEquals(36, checked)
    }

    // Audit #28: symbol viewports clip oversized content (was: full bleed).
    @Test
    fun symbolViewportClips() {
        val out = renderWithLibrary(
            """<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">""" +
                """<symbol id="s" viewBox="0 0 10 10"><rect width="100" height="100" fill="#FF0000"/></symbol>""" +
                """<use href="#s" width="10" height="10"/></svg>""",
            Bitmap.createBitmap(100, 100, Bitmap.Config.ARGB_8888)
        )
        val red = countPixels(out) { it.red == 255 }
        assertTrue("expected ~100 clipped px, got $red", red in 1..200)
    }

    // Audit font findings: family items are trimmed; generic matching is
    // case-insensitive; 600+ synthesizes bold (CSS Fonts 4 §5.2: above-500
    // matches ascending), 500 and below stay normal.
    @Test
    fun fontFamilyTrimAndGenericCase() {
        assertEquals(listOf("Arial", "serif"), parseFontFamily("Arial ,serif"))
        assertTrue(
            checkGenericFont("Sans-Serif", Style.FONT_WEIGHT_NORMAL, FontStyle.normal)?.style ==
                Typeface.NORMAL
        )
    }

    @Test
    fun semiboldMapsToBold() {
        assertTrue(
            checkGenericFont("sans-serif", 600f, FontStyle.normal)?.style == Typeface.BOLD
        )
        assertTrue(
            checkGenericFont("sans-serif", 500f, FontStyle.normal)?.style == Typeface.NORMAL
        )
        assertTrue(
            checkGenericFont("sans-serif", 400f, FontStyle.normal)?.style == Typeface.NORMAL
        )
    }

    // Audit #35: S reflects only after C/S (else first control = current point),
    // T only after Q/T. Cross-type smooths must match their explicit curves.
    @Test
    fun crossTypeSmoothMatchesExplicitCurve() {
        fun render(d: String): Bitmap = renderWithLibrary(
            """<svg xmlns="http://www.w3.org/2000/svg" width="220" height="130" viewBox="-10 -60 220 130">""" +
                """<path d="$d" fill="#FF0000"/></svg>""",
            Bitmap.createBitmap(220, 130, Bitmap.Config.ARGB_8888)
        )
        // S after Q: first control is the current point (100,0).
        assertTrue(
            render("M0 0 Q50 50 100 0 S150 -50 200 0")
                .sameAs(render("M0 0 Q50 50 100 0 C100 0 150 -50 200 0"))
        )
        // T after C: first control is the current point (100,50).
        assertTrue(
            render("M0 0 C50 0 50 50 100 50 T200 50")
                .sameAs(render("M0 0 C50 0 50 50 100 50 Q100 50 200 50"))
        )
    }

    // Audit #36: hit regions must follow bounds-only resizes (viewport re-applied
    // in place without a rebuild).
    @Test
    fun hitTestFollowsBoundsResize() {
        val svg = SVG.getFromString(
            svg = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">""" +
                """<a href="https://example.com"><rect x="10" y="10" width="80" height="80"/></a></svg>"""
        ) as SVGImpl
        val drawable = KSVGDrawable(svg)
        drawable.setBounds(0, 0, 100, 100)
        drawable.draw(Canvas(Bitmap.createBitmap(100, 100, Bitmap.Config.ARGB_8888)))
        assertEquals("https://example.com", drawable.hitTest(50f, 50f))
        drawable.setBounds(0, 0, 200, 200)
        drawable.draw(Canvas(Bitmap.createBitmap(200, 200, Bitmap.Config.ARGB_8888)))
        assertEquals("https://example.com", drawable.hitTest(150f, 150f))
    }

    // Audit #4: media types are ASCII case-insensitive (`@media SCREEN` applies).
    @Test
    fun uppercaseMediaTypeMatches() {
        fun render(media: String): Bitmap = renderWithLibrary(
            """<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">""" +
                """<style>@media $media { rect { fill: #00FF00 } }</style>""" +
                """<rect x="10" y="10" width="40" height="40"/></svg>""",
            Bitmap.createBitmap(100, 100, Bitmap.Config.ARGB_8888)
        )
        val ref = render("screen")
        assertTrue(countPixels(ref) { it.green == 255 } > 1000)
        assertTrue(render("SCREEN").sameAs(ref))
    }

    // Audit #15: word-spacing must reach Paint (previously dropped between the
    // detached apply and the lazy diff, which seeded equality).
    @Test
    fun wordSpacingWidensText() {
        fun render(spacing: String): Bitmap = renderWithLibrary(
            """<svg xmlns="http://www.w3.org/2000/svg" width="200" height="60">""" +
                """<text x="10" y="40" font-size="40" fill="#000000" word-spacing="$spacing">A B</text></svg>""",
            Bitmap.createBitmap(200, 60, Bitmap.Config.ARGB_8888)
        )
        assertFalse(render("0").sameAs(render("20")))
    }

    // Audit #34: relative weights resolve against the base (table unit test) and
    // never reach external resolvers as sentinels (end-to-end with a capturing
    // resolver; font-family is non-generic so the resolver is actually called).
    @Test
    fun relativeFontWeightResolves() {
        assertEquals(100f, resolveRelativeFontWeight(Style.FONT_WEIGHT_LIGHTER, 400f))
        assertEquals(700f, resolveRelativeFontWeight(Style.FONT_WEIGHT_BOLDER, 400f))
        assertEquals(400f, resolveRelativeFontWeight(Style.FONT_WEIGHT_BOLDER, 300f))
        assertEquals(500f, resolveRelativeFontWeight(500f, 400f))
    }

    @Test
    fun bolderNeverReachesResolverAsSentinel() {
        var seenWeight = Float.NaN
        val resolver = object : ExternalFileResolver() {
            override fun resolveFont(
                fontFamily: String,
                fontWeight: Float,
                fontStyle: String,
                fontStretch: Float
            ): Typeface? {
                seenWeight = fontWeight
                return null
            }
        }
        renderWithLibrary(
            """<svg xmlns="http://www.w3.org/2000/svg" width="100" height="60">""" +
                """<text x="10" y="40" font-size="40" font-family="NoSuchFont" font-weight="bolder">A</text></svg>""",
            Bitmap.createBitmap(100, 60, Bitmap.Config.ARGB_8888),
            externalFileResolver = resolver,
        )
        assertEquals(700f, seenWeight)
    }

    // Audit plen: SVG2 pathLength applies to shapes, not just <path>.
    // Same rect geometry, different pathLength -> different dash density.
    @Test
    fun rectPathLengthScalesDash() {
        fun render(pathLength: String): Bitmap = renderWithLibrary(
            """<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">""" +
                """<rect x="10" y="10" width="80" height="20" fill="none" stroke="#FF0000" """ +
                """stroke-width="4" stroke-dasharray="10" pathLength="$pathLength"/></svg>""",
            Bitmap.createBitmap(100, 100, Bitmap.Config.ARGB_8888)
        )
        val sparse = render("100")
        val dense = render("200")
        assertTrue(countPixels(sparse) { it.red == 255 } > 100)
        assertTrue(countPixels(dense) { it.red == 255 } > 100)
        assertFalse(sparse.sameAs(dense))
    }

    // Audit #17: pattern tile overflow is clipped with and without viewBox
    // (hasOverflow gate verified empirically in both spaces; fully-outside
    // content paints nothing, so the gate cannot be vacuous here).
    @Test
    fun patternTileOverflowClipped() {
        fun render(content: String, patternDef: String): Int = countPixels(
            renderWithLibrary(
                """<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">""" +
                    """<defs><pattern id="p" patternUnits="userSpaceOnUse" $patternDef>""" +
                    content +
                    """</pattern></defs>""" +
                    """<rect width="100" height="100" fill="url(#p)"/></svg>""",
                Bitmap.createBitmap(100, 100, Bitmap.Config.ARGB_8888)
            )
        ) { it.red == 255 }
        val outside = """<rect x="-15" y="-15" width="10" height="10" fill="#FF0000"/>"""
        assertEquals(0, render(outside, """width="20" height="20" viewBox="0 0 20 20""""))
        assertEquals(0, render(outside, """width="20" height="20""""))
    }

    // Audit tcache: generic typefaces are deduplicated (same instance back).
    @Test
    fun genericTypefaceCached() {
        val first = checkGenericFont("sans-serif", 400f, FontStyle.normal)
        val second = checkGenericFont("sans-serif", 400f, FontStyle.normal)
        assertSame(first, second)
        assertNotSame(
            first,
            checkGenericFont("sans-serif", 700f, FontStyle.normal)
        )
    }

    // Audit poly1: a single-point polyline renders nothing, so it takes no markers.
    @Test
    fun singlePointPolylineTakesNoMarker() {
        val defs = """<defs><marker id="m" markerWidth="10" markerHeight="10" refX="5" refY="5">""" +
            """<rect width="10" height="10" fill="#FF0000"/></marker></defs>"""
        fun render(points: String, marker: String): Bitmap = renderWithLibrary(
            """<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">$defs""" +
                """<polyline points="$points" stroke="#000000" $marker/></svg>""",
            Bitmap.createBitmap(100, 100, Bitmap.Config.ARGB_8888)
        )
        assertTrue(render("50,50", """marker-start="url(#m)"""").sameAs(render("50,50", "")))
        assertTrue(countPixels(render("10,10 90,90", """marker-start="url(#m)"""")) { it.red == 255 } > 0)
    }

    // Audit marker180: near-reversal sums flag ambiguous instead of jittering.
    @Test
    fun nearReversalIsAmbiguous() {
        val direct = MarkerVector(0f, 0f, 1f, 0f)
        direct.add(-1f, 0.0000001f)
        assertTrue(direct.isAmbiguous)
        val viaVector = MarkerVector(0f, 0f, 1f, 0f)
        viaVector.add(MarkerVector(0f, 0f, -1f, 0.0000001f))
        assertTrue(viaVector.isAmbiguous)
    }

    // Audit view-blank: a <view> without viewBox must not blank the scene.
    @Test
    fun viewWithoutViewBoxDoesNotBlank() {
        val svg = SVG.getFromString(
            svg = """<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">""" +
                """<view id="v"/>""" +
                """<rect x="10" y="10" width="40" height="40" fill="#FF0000"/></svg>"""
        ) as SVGImpl
        val drawable = KSVGDrawable(svg, RenderOptions.create().view("v"))
        val bitmap = Bitmap.createBitmap(100, 100, Bitmap.Config.ARGB_8888)
        drawable.setBounds(0, 0, 100, 100)
        drawable.draw(Canvas(bitmap))
        assertTrue(countPixels(bitmap) { it.red == 255 } > 1000)
    }

    // Audit xlink: plain href wins over xlink:href regardless of order (SVG2).
    @Test
    fun plainHrefBeatsXlinkHref() {
        fun render(first: String, second: String): Bitmap = renderWithLibrary(
            """<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="100" height="100">""" +
                """<defs><rect id="a" width="40" height="40" fill="#FF0000"/>""" +
                """<rect id="b" width="40" height="40" fill="#0000FF"/></defs>""" +
                """<use $first $second width="40" height="40"/></svg>""",
            Bitmap.createBitmap(100, 100, Bitmap.Config.ARGB_8888)
        )
        for ((first, second) in listOf(
            """href="#a"""" to """xlink:href="#b"""",
            """xlink:href="#b"""" to """href="#a""""
        )) {
            val out = render(first, second)
            assertTrue(countPixels(out) { it.red == 255 } > 1000)
            assertEquals(0, countPixels(out) { it.blue == 255 })
        }
    }

    // Audit empty-conditional: systemLanguage="" matches nothing (existential),
    // requiredFeatures="" constrains nothing (universal). Both per-spec; locked here.
    @Test
    fun emptyConditionalsBehavePerSpec() {
        val out = renderWithLibrary(
            """<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">""" +
                """<rect x="10" y="10" width="40" height="40" fill="#FF0000" systemLanguage=""/>""" +
                """<rect x="50" y="50" width="40" height="40" fill="#00FF00" requiredFeatures=""/></svg>""",
            Bitmap.createBitmap(100, 100, Bitmap.Config.ARGB_8888)
        )
        assertEquals(0, countPixels(out) { it.red == 255 })
        assertTrue(countPixels(out) { it.green == 255 } > 1000)
    }

    // Audit #33: visibility pauses the ticker without losing the running state;
    // stop() still terminates.
    @Test
    fun animatedDrawableVisibilityPausesTicker() {
        val svg = SVG.getFromString(
            svg = """<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">""" +
                """<rect width="100" height="100" fill="red" opacity="0.8">""" +
                """<animate attributeName="opacity" to="0.2" dur="1s" fill="freeze"/></rect></svg>""",
            parseAnimations = true
        )
        val drawable = KSVGAnimatedDrawable(svg)
        assertFalse(drawable.isRunning)
        drawable.start()
        assertTrue(drawable.isRunning)
        assertTrue(drawable.setVisible(false, false))
        assertTrue(drawable.isRunning)
        drawable.setVisible(true, false)
        assertTrue(drawable.isRunning)
        drawable.stop()
        assertFalse(drawable.isRunning)
    }

    // Audit cmatrix: short value lists fall back to identity (instead of crashing
    // ColorMatrix, which needs exactly 20 elements); long lists keep the first 20.
    @Test
    fun shortColorMatrixFallsBackToIdentity() {
        fun render(filter: String): Bitmap = renderWithLibrary(
            """<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">""" +
                """<defs><filter id="f">$filter</filter></defs>""" +
                """<rect x="10" y="10" width="40" height="40" fill="#FF0000" filter="url(#f)"/></svg>""",
            Bitmap.createBitmap(100, 100, Bitmap.Config.ARGB_8888)
        )
        val baseline = renderWithLibrary(
            """<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">""" +
                """<rect x="10" y="10" width="40" height="40" fill="#FF0000"/></svg>""",
            Bitmap.createBitmap(100, 100, Bitmap.Config.ARGB_8888)
        )
        assertTrue(render("""<feColorMatrix type="matrix" values="1 0 0"/>""").sameAs(baseline))
        assertTrue(
            render("""<feColorMatrix type="matrix" values="0 0 0 0 1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1 9 9 9 9 9"/>""")
                .sameAs(render("""<feColorMatrix type="matrix" values="0 0 0 0 1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1"/>"""))
        )
    }

    // Audit morph-neg: negative radii clamp to 0 (passthrough), identically on
    // every backend (parsed once, upstream of all of them).
    @Test
    fun negativeMorphologyIsPassthrough() {
        fun render(filter: String): Bitmap = renderWithLibrary(
            """<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">""" +
                """<defs><filter id="f">$filter</filter></defs>""" +
                """<rect x="10" y="10" width="40" height="40" fill="#FF0000" filter="url(#f)"/></svg>""",
            Bitmap.createBitmap(100, 100, Bitmap.Config.ARGB_8888)
        )
        val baseline = renderWithLibrary(
            """<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">""" +
                """<rect x="10" y="10" width="40" height="40" fill="#FF0000"/></svg>""",
            Bitmap.createBitmap(100, 100, Bitmap.Config.ARGB_8888)
        )
        assertTrue(render("""<feMorphology operator="dilate" radius="-5"/>""").sameAs(baseline))
    }

    // Audit R6 feSpotLight: the per-light beam exponent takes effect (default 1.0
    // renders, explicit values refocus; both non-blank so the diff is real).
    @Test
    fun spotBeamExponentTakesEffect() {
        fun render(beamExp: String): Bitmap = renderWithLibrary(
            """<svg xmlns="http://www.w3.org/2000/svg" width="240" height="220" viewBox="0 0 240 220">""" +
                """<defs><filter id="spot" x="-30%" y="-30%" width="160%" height="160%">""" +
                """<feSpecularLighting in="SourceGraphic" surfaceScale="4" specularConstant="1" """ +
                """specularExponent="18" lighting-color="white">""" +
                """<feSpotLight x="60" y="60" z="100" pointsAtX="120" pointsAtY="110" pointsAtZ="0" """ +
                """limitingConeAngle="35" specularExponent="$beamExp"/>""" +
                """</feSpecularLighting></filter></defs>""" +
                """<circle cx="170" cy="110" r="50" fill="seagreen" filter="url(#spot)"/></svg>""",
            Bitmap.createBitmap(240, 220, Bitmap.Config.ARGB_8888),
            true
        )
        val soft = render("1")
        val focused = render("5")
        assertTrue(countPixels(soft) { it.alpha != 0 } > 1000)
        assertTrue(countPixels(focused) { it.alpha != 0 } > 1000)
        assertFalse(soft.sameAs(focused))
    }

    // Audit D2 (browser parity): an element with invalid attribute values is
    // skipped with a warning; siblings still render. No exception escapes.
    @Test
    fun invalidGeometrySkipsElementOnly() {
        val out = renderWithLibrary(
            """<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">""" +
                """<rect x="10" y="10" width="bogus" height="40" fill="#FF0000"/>""" +
                """<circle cx="70" cy="70" r="15" fill="#00FF00"/></svg>""",
            Bitmap.createBitmap(100, 100, Bitmap.Config.ARGB_8888)
        )
        assertEquals(0, countPixels(out) { it.red == 255 })
        assertTrue(countPixels(out) { it.green == 255 } > 500)
    }

    // Audit D2: the skip keeps the element stack balanced even nested.
    @Test
    fun invalidNestedGeometryKeepsStackBalanced() {
        val out = renderWithLibrary(
            """<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">""" +
                """<g><rect x="10" y="10" width="bogus" height="40" fill="#FF0000"/>""" +
                """<rect x="10" y="10" width="20" height="20" fill="#0000FF"/></g>""" +
                """<rect x="60" y="60" width="30" height="30" fill="#00FF00"/></svg>""",
            Bitmap.createBitmap(100, 100, Bitmap.Config.ARGB_8888)
        )
        assertEquals(0, countPixels(out) { it.red == 255 })
        assertTrue(countPixels(out) { it.blue == 255 } > 300)
        assertTrue(countPixels(out) { it.green == 255 } > 500)
    }

    // Audit D4: a bad preserveAspectRatio must surface as KSVGParseException
    // (via PreserveAspectRatio.of), so the D2 per-element dispatch skips only
    // the broken element and siblings still render. No IAE escapes.
    @Test
    fun invalidPreserveAspectRatioSkipsElementOnly() {
        val out = renderWithLibrary(
            """<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">""" +
                """<svg x="0" y="0" width="50" height="50" preserveAspectRatio="xMidYMid bogus">""" +
                """<rect x="5" y="5" width="20" height="20" fill="#FF0000"/></svg>""" +
                """<circle cx="70" cy="70" r="15" fill="#00FF00"/></svg>""",
            Bitmap.createBitmap(100, 100, Bitmap.Config.ARGB_8888)
        )
        assertEquals(0, countPixels(out) { it.red == 255 })
        assertTrue(countPixels(out) { it.green == 255 } > 500)
    }

    // Audit #46: DEFAULT_STYLE stamps specifiedFlags=-1 and Builder.reset()
    // copies it, so an inherited style reports isSpecified for properties that
    // were never declared. The updateStyle gates therefore always pass today;
    // the copied values are the correctly resolved ones, so this is perf-only.
    // Pins the lineage until D10 decides the semantic fix.
    @Test
    fun inheritedStyleReportsUndeclaredPropertiesAsSpecified() {
        val child = Style.Builder().also { it.reset(Style.getDefaultStyle()) }.build()
        assertTrue(child.isSpecified(Style.SPECIFIED_WORD_SPACING))
        assertTrue(child.isSpecified(Style.SPECIFIED_FONT_WEIGHT))
        assertTrue(child.isSpecified(Style.SPECIFIED_FILL))
    }
}
