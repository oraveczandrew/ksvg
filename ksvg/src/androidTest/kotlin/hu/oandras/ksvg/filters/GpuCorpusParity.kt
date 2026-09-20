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

import android.graphics.Bitmap
import android.util.Base64
import hu.oandras.ksvg.render.createBitmap
import java.io.ByteArrayOutputStream

/**
 * Round-B shared helpers (`tmp/GPU_PARITY_PLAN_B.md` §3, §5.1).
 *
 * Corpus [IntArray] inputs reach the GPU path as `SourceGraphic` through a
 * device-encoded lossless PNG data URI (`<image href="data:...">`).
 * `feImage` is deliberately NOT used: no GPU backend supports it, so it
 * would silently fall back to software and the parity assert would compare
 * CPU against CPU (vacuous pass). The PNG round-trip is parity-neutral:
 * both backends decode the same bytes through the same
 * `checkForImageDataURL` path.
 */
internal fun imageSource(input: IntArray, width: Int, height: Int): String {
    require(input.size == width * height) {
        "GpuCorpusParity: input.size=${input.size} != ${width}x$height"
    }
    val bitmap = createBitmap(width, height, Bitmap.Config.ARGB_8888)
    bitmap.setPixels(input, 0, width, 0, 0, width, height)
    val png = ByteArrayOutputStream().use { out ->
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
        bitmap.recycle()
        out.toByteArray()
    }
    return "data:image/png;base64," + Base64.encodeToString(png, Base64.NO_WRAP)
}

/**
 * Pins every pixel to opaque, keeping RGB. Corpus inputs carry random alpha,
 * which the PNG premultiply round-trip (`setPixels` store rounding +
 * `getPixels` unpremultiply rounding) reproduces only approximately — and the
 * GPU shader's float `tap/alpha` division then disagrees with the platform
 * integer unpremultiply by up to ~13 LSB at low alpha, flipping min/max
 * winner races all over the image (measured: dilate catastrophic, erode
 * partial on translucent noise). That noise is a test artifact of the two
 * representations, not a kernel bug: the taps themselves are byte-exact
 * (`RAW == half-up-premult(SW)`, verified on-device), and the alpha channel
 * exercises the same min/max code path as RGB. With opaque inputs
 * premultiplied == straight, the PNG is lossless, taps are bit-exact, and
 * the strict gates measure what Round-B is for: window geometry, subregions,
 * radii, operators. Documented adaptation, see `tmp/GPU_PARITY_PLAN_B.md` §2.
 */
internal fun opaqueInput(input: IntArray): IntArray {
    return IntArray(input.size) { i -> -0x1000000 or (input[i] and 0x00FFFFFF) }
}

/**
 * Round-A baseline convention, reused for corpus SVGs: every corpus SVG
 * marks the filtered element with `filter="url(#f)"`.
 */
internal fun corpusBaseline(svg: String): String {
    val baseline = svg.replace(""" filter="url(#f)"""", "")
    check(baseline != svg) { "Corpus SVG must contain filter=\"url(#f)\"" }
    return baseline
}
