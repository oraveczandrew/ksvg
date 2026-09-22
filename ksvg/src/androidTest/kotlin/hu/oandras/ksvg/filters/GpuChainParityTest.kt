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

package hu.oandras.ksvg.filters

import android.os.Build
import androidx.test.ext.junit.runners.AndroidJUnit4
import hu.oandras.ksvg.filtering.UnLinearizeValidationCorpus
import org.junit.Assume
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Round-C chain-level parity (`tmp/GPU_PARITY_PLAN_C.md`): hand-designed
 * 2-3 primitive chains exercising composition the Round-A/B isolated
 * primitive tests cannot see (distant `in2` references across the
 * `resultShaders` map, terminal-position sensitivity, region inheritance
 * through chains, mid-chain decline fallbacks, Skia×AGSL mixing).
 *
 * Conventions (Round-A): 256x256 SVG, opaque rect source (flat color —
 * displacement/composite signal lives in the edge bands; interior pixels
 * still pin exact agreement), `filter="url(#f)"` with the baseline
 * derived by stripping it. Fallback chains (C7–C9) assert the decline
 * explicitly (stitch precedent) instead of pixel parity.
 *
 * Known gap (plan §4.1): a silently declined chain renders SW on both
 * sides and passes vacuously. The visible-effect guard plus strict gates
 * catch wrong pixels, but not a whole-chain fallback; chain-taken proof
 * is follow-up work.
 */
@RunWith(AndroidJUnit4::class)
class GpuChainParityTest {

    @Test
    fun distantIn2Arithmetic() {
        // C1: flood result feeds BOTH the displacement map (neighbor) and
        // the arithmetic in2 (2 hops back) — proves resultShaders lifetime
        // across the chain, not just adjacent references. Host golden
        // (F9: device-SW arithmetic is nondeterministic); premultiplied
        // comparison like the corpus (chain emits premult verbatim).
        // Measured 7/65536 at ≤45: displacement edge-straddle flips
        // (map ±1 LSB at the rect boundary selects neighbor texels),
        // amplified by linear+EOTF — same family as C2/C4, so the ratio
        // stays strict and only the max gate budgets them.
        checkParity(
            name = "chainC1",
            svg = chainSvg(
                """
                <feFlood flood-color="#2020c0" result="map"/>
                <feDisplacementMap in="SourceGraphic" in2="map" scale="30" xChannelSelector="R" yChannelSelector="G" result="disp"/>
                <feComposite in="disp" in2="map" operator="arithmetic" k1="0" k2="0.5" k3="0.5" k4="0.1"/>
                """.trimIndent(),
            ),
            maxAbsTol = 64,
            premultiplyReference = true,
            goldenAsset = "parity/chains/chainC1.png",
        )
    }

    @Test
    fun turbulenceMapBlend() {
        // C2: generative turbulence map displaces the source, the product
        // blends with SourceGraphic — a computed branch consumed by blend.
        // Gates: ±1 LSB map quantization flips the truncated shift at
        // scattered edge pixels (measured 37/65536, all within 1 px of an
        // alpha/RGB edge, max 255 where the straddle crosses
        // transparent↔opaque); the outlier ratio budgets them while the
        // near-zero mean pins the field.
        checkParity(
            name = "chainC2",
            svg = chainSvg(
                """
                <feTurbulence type="fractalNoise" baseFrequency="0.05" numOctaves="2" seed="8" result="map"/>
                <feDisplacementMap in="SourceGraphic" in2="map" scale="30" xChannelSelector="R" yChannelSelector="G" result="disp"/>
                <feBlend in="disp" in2="SourceGraphic" mode="multiply"/>
                """.trimIndent(),
            ),
            maxAbsTol = 255,
            maxOutlierRatio = 0.002,
        )
    }

    @Test
    fun nonTerminalSpecularTransfer() {
        // C3: turbulence height-map feeds specular in NON-terminal
        // position (premultiplied chain output, NOT the terminal
        // (lightColor, intensity) form), consumed by componentTransfer —
        // proves the terminal/non-terminal branch, not just the isolated
        // terminal case Round-A covers. Premultiplied comparison (chain
        // emits premult; straight comparison would repeat the C1 trap).
        // NOTE: strict placeholder gates — calibrated from measured stats
        // after the specular-premult fix (see GPU_ROUNDC_WORKLOG.md §C3).
        // Measured (premult space): 943/65536 (0.014), max 6, mean 0.39 —
        // specular fp-intensity noise (exponent 8) passed through the
        // transfer, same class as the Round-B point-specular gates.
        checkParity(
            name = "chainC3",
            svg = chainSvg(
                """
                <feTurbulence type="fractalNoise" baseFrequency="0.05" numOctaves="2" seed="8" result="h"/>
                <feSpecularLighting in="h" surfaceScale="2" specularConstant="1" specularExponent="8" lighting-color="#ffffff" result="s">
                  <feDistantLight azimuth="45" elevation="60"/>
                </feSpecularLighting>
                <feComponentTransfer in="s"><feFuncR type="linear" slope="0.5" intercept="0.2"/></feComponentTransfer>
                """.trimIndent(),
            ),
            maxAbsTol = 8,
            maxOutlierRatio = 0.02,
            premultiplyReference = true,
        )
    }

    @Test
    fun linearTurbulenceDisplacement() {
        // C4: turbulence in NON-terminal position under linearRGB gets no
        // EOTF (intermediate stays linear on both backends); displacement
        // consumes the linear map. Gates like C2: 37/65536 edge-straddle
        // flips, all within 1 px of an edge (verified offline).
        checkParity(
            name = "chainC4",
            svg = chainSvg(
                """
                <feTurbulence type="fractalNoise" baseFrequency="0.05" numOctaves="2" seed="8" result="map"/>
                <feDisplacementMap in="SourceGraphic" in2="map" scale="30" xChannelSelector="R" yChannelSelector="G"/>
                """.trimIndent(),
                filterAttrs = """ color-interpolation-filters="linearRGB"""",
            ),
            maxAbsTol = 255,
            maxOutlierRatio = 0.002,
        )
    }

    @Test
    fun subregionArithmetic() {
        // C5: flood subregion + composite clip (different rects,
        // userSpaceOnUse units) — region-guard mapping consistency across
        // two primitives. Host golden (F9: device-SW arithmetic is
        // nondeterministic); premultiplied comparison like the corpus.
        checkParity(
            name = "chainC5",
            svg = chainSvg(
                """
                <feFlood flood-color="#2020c0" x="48" y="48" width="100" height="100" result="b"/>
                <feComposite in="SourceGraphic" in2="b" operator="arithmetic" k1="0" k2="0.5" k3="0.5" k4="0.1" x="60" y="60" width="100" height="100"/>
                """.trimIndent(),
                filterAttrs = """ primitiveUnits="userSpaceOnUse"""",
            ),
            premultiplyReference = true,
            goldenAsset = "parity/chains/chainC5.png",
        )
    }

    @Test
    fun tileDisplacement() {
        // C6: flood tiled, then used as displacement map — uniform map
        // (constant shift, no quantization flips), but the tile mod/rect
        // logic runs in-chain. Strict gates; premultiplied comparison for
        // the displacement halo.
        checkParity(
            name = "chainC6",
            svg = chainSvg(
                """
                <feFlood flood-color="#2020c0" result="t"/>
                <feTile in="t" result="tile"/>
                <feDisplacementMap in="SourceGraphic" in2="tile" scale="30" xChannelSelector="R" yChannelSelector="G"/>
                """.trimIndent(),
            ),
            premultiplyReference = true,
        )
    }

    @Test
    fun wrapConvolveChain() {
        // C7: wrap-convolve mid-chain (F4: explicit mod-tap sampling, no
        // more decline). Strict gates first, calibrated from measurement.
        checkParity(
            name = "chainC7",
            svg = chainSvg(
                """
                <feFlood flood-color="#2020c0" result="b"/>
                <feConvolveMatrix in="b" order="3" kernelMatrix="0 -1 0 -1 5 -1 0 -1 0" edgeMode="wrap" result="c"/>
                <feComposite in="c" in2="SourceGraphic" operator="over"/>
                """.trimIndent(),
            ),
        )
    }

    @Test
    fun noneConvolveChain() {
        // C17: none-convolve (transparent out-of-bounds taps, F4).
        // Strict gates first, calibrated from measurement.
        checkParity(
            name = "chainC17",
            svg = chainSvg(
                """
                <feFlood flood-color="#2020c0" result="b"/>
                <feConvolveMatrix in="b" order="3" kernelMatrix="0 -1 0 -1 5 -1 0 -1 0" edgeMode="none" result="c"/>
                <feComposite in="c" in2="SourceGraphic" operator="over"/>
                """.trimIndent(),
            ),
        )
    }

    @Test
    fun stitchTurbulenceChain() {
        // C8: stitch-turbulence map feeding displacement (F6: real stitch
        // on GPU, no more fallback). Gates like C2: map quantization flips
        // the truncated shift at scattered edge pixels over the flat rect
        // (measured 45/65536, max 255 where the straddle crosses
        // transparent↔opaque); the ratio budgets them.
        checkParity(
            name = "chainC8",
            svg = chainSvg(
                """
                <feTurbulence type="fractalNoise" baseFrequency="0.05" numOctaves="2" seed="8" stitchTiles="stitch" result="map"/>
                <feDisplacementMap in="SourceGraphic" in2="map" scale="30" xChannelSelector="R" yChannelSelector="G"/>
                """.trimIndent(),
            ),
            maxAbsTol = 255,
            maxOutlierRatio = 0.002,
        )
    }

    @Test
    fun nonTerminalArithmeticOver() {
        // C9 (repurposed — see worklog): non-terminal sRGB arithmetic
        // consumed by composite-over. The linear-decline fallback originally
        // planned here is unmeasurable (native linear arithmetic is
        // nondeterministic run-to-run, Round-B arith worklog §2 — device-SW
        // cannot reference it); mid-chain decline mechanics are covered
        // deterministically by C7/C8 instead. Premultiplied comparison:
        // the over halo outside the rect stays translucent (C1 lesson).
        // Verified offline maxAbs 1, 0/65536 — strict gates hold.
        checkParity(
            name = "chainC9",
            svg = chainSvg(
                """
                <feFlood flood-color="#4060c0" result="c"/>
                <feComposite in="SourceGraphic" in2="c" operator="arithmetic" k1="0" k2="0.5" k3="0.5" k4="0.1" result="a"/>
                <feComposite in="a" in2="SourceGraphic" operator="over"/>
                """.trimIndent(),
            ),
            premultiplyReference = true,
        )
    }

    @Test
    fun skiaBlurComposite() {
        // C10: Skia blur inside an AGSL chain (Skia×AGSL boundary:
        // premult Skia output as AGSL input). Measured: 14/65536 at
        // ≤3 abs (flood-edge clamp, same class as the Round-A blur
        // corners) — tol 4 keeps it honest, ratio stays strict.
        checkParity(
            name = "chainC10",
            svg = chainSvg(
                """
                <feFlood flood-color="#2020c0" result="b"/>
                <feGaussianBlur in="b" stdDeviation="4" result="blur"/>
                <feComposite in="blur" in2="SourceGraphic" operator="over"/>
                """.trimIndent(),
            ),
            maxAbsTol = 4,
            // Readback space (F1): Skia-blur HW halo reads back
            // premultiplied, SW stores straight — compare premultiplied.
            premultiplyReference = true,
        )
    }

    @Test
    fun offsetMorphology() {
        // C11: offset shifts geometry, morphology erodes in the shifted
        // frame — region mapping across a geometric primitive. Strict
        // placeholder gates, calibrated after first run.
        checkParity(
            name = "chainC11",
            svg = chainSvg(
                """
                <feOffset in="SourceGraphic" dx="24" dy="-12" result="o"/>
                <feMorphology in="o" operator="erode" radius="3"/>
                """.trimIndent(),
            ),
        )
    }

    @Test
    fun diffuseMerge() {
        // C12: turbulence height-map → diffuse lighting, merged over
        // SourceGraphic — two-branch merge of a computed result.
        // Strict placeholder gates, calibrated after the first run.
        checkParity(
            name = "chainC12",
            svg = chainSvg(
                """
                <feTurbulence type="fractalNoise" baseFrequency="0.05" numOctaves="2" seed="8" result="h"/>
                <feDiffuseLighting in="h" surfaceScale="2" diffuseConstant="1" lighting-color="#ffffff" result="d">
                  <feDistantLight azimuth="45" elevation="60"/>
                </feDiffuseLighting>
                <feMerge><feMergeNode in="d"/><feMergeNode in="SourceGraphic"/></feMerge>
                """.trimIndent(),
            ),
        )
    }

    @Test
    fun subregionColorMatrix() {
        // C13: saturate-0 colormatrix confined to a user-space subregion —
        // proves the uPrimitiveRegion guard (the Skia/AGSL paths used to
        // ignore it; geometry_units precedent for blur). Premultiplied
        // comparison for the antialiased rect fringe.
        checkParity(
            name = "chainC13",
            svg = chainSvg(
                """
                <feColorMatrix in="SourceGraphic" type="saturate" values="0" x="48" y="48" width="100" height="100"/>
                """.trimIndent(),
                filterAttrs = """ primitiveUnits="userSpaceOnUse"""",
            ),
            premultiplyReference = true,
        )
    }

    @Test
    fun implicitIn2Displacement() {
        // C14: flood map feeds displacement through the IMPLICIT in2
        // default (no in2 attribute = previous result, per spec) — proves
        // the F1 defaulting, not just named references. Constant map:
        // strict gates + premult (halo).
        checkParity(
            name = "chainC14",
            svg = chainSvg(
                """
                <feFlood flood-color="#2020c0" result="map"/>
                <feDisplacementMap in="SourceGraphic" scale="30" xChannelSelector="R" yChannelSelector="G"/>
                """.trimIndent(),
            ),
            premultiplyReference = true,
        )
    }

    @Test
    fun subregionDropShadowFallback() {
        // C15: dropShadow with an explicit subregion declines (the Skia
        // composite ignores it — F2) → whole-chain software fallback.
        // HW==SW assert (a taken path would paint the whole input).
        // NOTE: the subregion must EXTEND past the rect (shadow lives at
        // +10/+10 outside it); a rect-equal subregion clips the shadow
        // away and the output trivially equals the baseline.
        checkFallback(
            name = "chainC15",
            svg = chainSvg(
                """
                <feDropShadow dx="10" dy="10" stdDeviation="4" flood-color="#000000" flood-opacity="0.8" x="48" y="48" width="200" height="200"/>
                """.trimIndent(),
                filterAttrs = """ primitiveUnits="userSpaceOnUse"""",
            ),
        )
    }

    @Test
    fun lightlessDiffusePassthrough() {
        // C16: diffuse lighting WITHOUT a light child passes the input
        // through on the CPU (`light ?: return inputBitmap`) — the GPU
        // mirrors with passthrough (F3), no decline. No visible-effect
        // guard (passthrough by design, like identity); parity is strict
        // (bit-exact expected).
        checkParity(
            name = "chainC16",
            svg = chainSvg(
                """<feDiffuseLighting in="SourceGraphic" surfaceScale="2" diffuseConstant="1" lighting-color="#ffffff"/>""",
            ),
            skipVisibleEffectGuard = true,
        )
    }

    @Test
    fun largeKernelConvolve() {
        // C18: 7x7 box blur (F5: uKernel[49]). Exercises taps beyond the
        // old 5x5 limit. Strict gates first, calibrated from measurement.
        checkParity(
            name = "chainC18",
            svg = chainSvg(
                """
                <feFlood flood-color="#2020c0" result="b"/>
                <feConvolveMatrix in="b" order="7" kernelMatrix="1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1" divisor="49" result="c"/>
                <feComposite in="c" in2="SourceGraphic" operator="over"/>
                """.trimIndent(),
            ),
            premultiplyReference = true,
        )
    }

    @Test
    fun subregionOffset() {
        // C19: offset confined to a user-space subregion (F7: AGSL offset
        // with region guard). Strict gates first, calibrated from
        // measurement.
        checkParity(
            name = "chainC19",
            svg = chainSvg(
                """<feOffset in="SourceGraphic" dx="24" dy="-12" x="48" y="48" width="160" height="160"/>""",
                filterAttrs = """ primitiveUnits="userSpaceOnUse"""",
            ),
        )
    }

    @Test
    fun rasterImageComposite() {
        // C20: raster feImage (data-URI PNG) composited over SourceGraphic
        // (F8: decoded bitmap as chain input). Opaque pixels (premult ==
        // straight, exact). Strict gates first, calibrated from measurement.
        checkParity(
            name = "chainC20",
            svg = chainSvgWithImage(
                width = 64,
                height = 64,
                primitives = """
                <feImage href="%s" result="img"/>
                <feComposite in="SourceGraphic" in2="img" operator="over"/>
                """.trimIndent(),
            ),
        )
    }

    private fun checkParity(
        name: String,
        svg: String,
        maxAbsTol: Int = GPU_PARITY_MAX_ABS,
        maxOutlierRatio: Double = GPU_PARITY_MAX_OUTLIER_RATIO,
        premultiplyReference: Boolean = false,
        skipVisibleEffectGuard: Boolean = false,
        goldenAsset: String? = null,
    ) {
        Assume.assumeTrue(
            "GpuParityHarness needs API 29+ (HardwareRenderer)",
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q,
        )
        val sw = renderSoftware(svg)
        if (!skipVisibleEffectGuard) {
            assertVisibleFilterEffect(name, sw, renderSoftware(chainBaseline(svg)))
        }
        val hw = renderOnHardware(svg)
        // Round-E chain-taken proof (all parity chains run Impl33, min 33 —
        // including C16 lightless passthrough, which the GPU serves, and
        // C1/C5 golden paths, whose goldens exist for determinism, not
        // decline, reasons).
        assertChainBackend(name, minGpuApi = 33)
        // Host-golden path (F9): device-SW is untrusted here (native
        // nondeterminism), so parity is HW vs the committed golden
        // (host render-path recipe, determinism-checked at generation).
        val reference = if (goldenAsset != null) {
            loadGoldenAsset(
                goldenAsset,
                android.graphics.Bitmap.createBitmap(256, 256, android.graphics.Bitmap.Config.ARGB_8888),
            )
        } else {
            sw
        }
        assertParity(
            "$name (minGpuApi=33, deviceApi=${Build.VERSION.SDK_INT})",
            reference,
            hw,
            maxAbsTol,
            maxOutlierRatio,
            premultiplyReference = premultiplyReference,
        )
    }

    private fun chainSvg(primitives: String, filterAttrs: String = ""): String {
        return """
            <svg xmlns="http://www.w3.org/2000/svg" width="256" height="256">
              <defs>
                <filter id="f"$filterAttrs>
                  $primitives
                </filter>
              </defs>
              <rect x="48" y="48" width="160" height="160" fill="#c83232" filter="url(#f)"/>
            </svg>
        """.trimIndent()
    }

    private fun chainSvgWithImage(width: Int, height: Int, primitives: String): String {
        val pixels = UnLinearizeValidationCorpus.fixedSeedRandom(width * height)
        val uri = imageSource(opaqueInput(pixels), width, height)
        return """
            <svg xmlns="http://www.w3.org/2000/svg" width="256" height="256">
              <defs>
                <filter id="f">
                  ${primitives.format(uri)}
                </filter>
              </defs>
              <rect x="48" y="48" width="160" height="160" fill="#c83232" filter="url(#f)"/>
            </svg>
        """.trimIndent()
    }

    private fun chainBaseline(svg: String): String {
        val baseline = svg.replace(""" filter="url(#f)"""", "")
        check(baseline != svg) { "Chain SVG must contain filter=\"url(#f)\"" }
        return baseline
    }

    /**
     * Fallback assert for chains the GPU must decline (C7–C9): both sides
     * render through the software backend, so HW==SW bit-exactly. Strict
     * gates — any taken (wrong) GPU path diverges hugely. The SW
     * visible-effect guard proves the chain does something (non-vacuous).
     */
    private fun checkFallback(name: String, svg: String) {
        Assume.assumeTrue(
            "GpuParityHarness needs API 29+ (HardwareRenderer)",
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q,
        )
        val sw = renderSoftware(svg)
        assertVisibleFilterEffect(name, sw, renderSoftware(chainBaseline(svg)))
        val hw = renderOnHardware(svg)
        // Round-E decline proof: C15 must NOT take the chain.
        assertChainBackend(name, minGpuApi = 33, expectFallback = true)
        assertParity(
            "$name (fallback, minGpuApi=33, deviceApi=${Build.VERSION.SDK_INT})",
            sw,
            hw,
        )
    }
}
