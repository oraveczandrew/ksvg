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
import android.graphics.Color
import android.graphics.HardwareRenderer
import android.graphics.PixelFormat
import android.graphics.PorterDuff
import android.graphics.RenderNode
import android.media.ImageReader
import android.os.Build
import android.os.SystemClock
import androidx.annotation.RequiresApi
import androidx.test.platform.app.InstrumentationRegistry
import hu.oandras.ksvg.RenderOptions
import hu.oandras.ksvg.SVG
import hu.oandras.ksvg.render.createBitmap
import hu.oandras.ksvg.test.decodePng
import hu.oandras.ksvg.test.renderWithLibrary
import hu.oandras.ksvg.utils.alpha
import hu.oandras.ksvg.utils.blue
import hu.oandras.ksvg.utils.green
import hu.oandras.ksvg.utils.red
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import java.io.File
import kotlin.math.abs

internal const val GPU_PARITY_SIZE = 256

/** Default per-channel tolerance (see `tmp/GPU_PARITY_PLAN_A.md` §1). */
internal const val GPU_PARITY_MAX_ABS = 2

/** Default allowed ratio of pixels with any channel diff above [GPU_PARITY_MAX_ABS]. */
internal const val GPU_PARITY_MAX_OUTLIER_RATIO = 0.001

/** Minimum share of pixels that must visibly change for a filter to count as exercised (§4). */
internal const val GPU_PARITY_MIN_VISIBLE_EFFECT_RATIO = 0.005

/**
 * Software reference render (CPU kernels, software [android.graphics.Canvas]).
 * Mirrors the unit-test path via [renderWithLibrary] with forced software filtering.
 */
internal fun renderSoftware(svgString: String, width: Int = GPU_PARITY_SIZE, height: Int = GPU_PARITY_SIZE): Bitmap {
    val out = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
    return renderWithLibrary(svgString, out, true)
}

/**
 * Hardware render on a [RenderNode] recording canvas (hardware-accelerated, so
 * the GPU filter backend is eligible) read back through an [ImageReader]
 * surface. No `softwareFiltering` flag is set — passing it would measure the
 * CPU path against itself.
 *
 * Requires API 29+ ([HardwareRenderer]); callers must gate with `Assume`.
 */
@RequiresApi(Build.VERSION_CODES.Q)
internal fun renderOnHardware(
    svgString: String,
    width: Int = GPU_PARITY_SIZE,
    height: Int = GPU_PARITY_SIZE,
): Bitmap {
    val svg = SVG.getFromString(svgString)
    val renderer = HardwareRenderer()
    val reader = ImageReader.newInstance(width, height, PixelFormat.RGBA_8888, 1)
    try {
        renderer.setSurface(reader.surface)
        renderer.isOpaque = false

        val node = RenderNode("ksvg-gpu-parity")
        node.setPosition(0, 0, width, height)
        val canvas = node.beginRecording(width, height)
        // Match the software path's eraseColor(0): transparent background.
        canvas.drawColor(Color.TRANSPARENT, PorterDuff.Mode.CLEAR)
        val options = RenderOptions.create()
        options.viewPort(0f, 0f, width.toFloat(), height.toFloat())
        svg.renderToCanvas(canvas, options)
        node.endRecording()

        renderer.setContentRoot(node)
        renderer.createRenderRequest().syncAndDraw()

        val image = pollLatestImage(reader, width, height)
        return image.use { imageToBitmap(it, width, height) }
    } finally {
        renderer.setSurface(null)
        renderer.destroy()
        reader.close()
    }
}

@RequiresApi(Build.VERSION_CODES.Q)
private fun pollLatestImage(reader: ImageReader, width: Int, height: Int): android.media.Image {
    val deadline = SystemClock.uptimeMillis() + 2000L
    while (true) {
        val image = reader.acquireLatestImage()
        if (image != null) return image
        if (SystemClock.uptimeMillis() >= deadline) {
            fail("GpuParityHarness: no frame arrived from HardwareRenderer within 2s (${width}x$height)")
        }
        Thread.sleep(10L)
    }
}

@RequiresApi(Build.VERSION_CODES.Q)
private fun imageToBitmap(image: android.media.Image, width: Int, height: Int): Bitmap {
    val plane = image.planes[0]
    val buffer = plane.buffer
    val pixelStride = plane.pixelStride
    val rowStride = plane.rowStride
    val out = createBitmap(width, height, Bitmap.Config.ARGB_8888)
    val row = ByteArray(rowStride)
    val pixels = IntArray(width)
    for (y in 0 until height) {
        buffer.get(row, 0, rowStride)
        if (pixelStride == 4) {
            for (x in 0 until width) {
                val o = x * 4
                // RGBA_8888 planes are R, G, B, A byte order; Bitmap expects ARGB int.
                val r = row[o].toInt() and 0xff
                val g = row[o + 1].toInt() and 0xff
                val b = row[o + 2].toInt() and 0xff
                val a = row[o + 3].toInt() and 0xff
                pixels[x] = (a shl 24) or (r shl 16) or (g shl 8) or b
            }
        } else {
            fail("GpuParityHarness: unexpected pixelStride=$pixelStride (expected 4)")
        }
        out.setPixels(pixels, 0, width, 0, y, width, 1)
    }
    return out
}

internal data class ParityStats(
    @JvmField val maxAbs: Int,
    @JvmField val meanAbs: Double,
    @JvmField val outlierCount: Int,
    @JvmField val total: Int,
    @JvmField val worstX: Int = -1,
    @JvmField val worstY: Int = -1,
    @JvmField val worstA: Int = 0,
    @JvmField val worstB: Int = 0,
)

internal fun parityStats(sw: Bitmap, hw: Bitmap, ignoreBoundaryFringe: Boolean = false): ParityStats {
    assertEquals("Bitmap widths differ", sw.width, hw.width)
    assertEquals("Bitmap heights differ", sw.height, hw.height)
    val w = sw.width
    val h = sw.height
    val swPx = IntArray(w * h)
    val hwPx = IntArray(w * h)
    sw.getPixels(swPx, 0, w, 0, 0, w, h)
    hw.getPixels(hwPx, 0, w, 0, 0, w, h)
    // Pixels transparent in both images: the fringe rule excuses differing
    // pixels 4-adjacent to any of these (accepted Adreno boundary variance).
    val bothTransparent = if (ignoreBoundaryFringe) {
        BooleanArray(w * h) { i -> (swPx[i] ushr 24) == 0 && (hwPx[i] ushr 24) == 0 }
    } else {
        null
    }
    fun isFringe(x: Int, y: Int): Boolean {
        val transparent = bothTransparent ?: return false
        if (x > 0 && transparent[y * w + x - 1]) return true
        if (x < w - 1 && transparent[y * w + x + 1]) return true
        if (y > 0 && transparent[(y - 1) * w + x]) return true
        if (y < h - 1 && transparent[(y + 1) * w + x]) return true
        return false
    }
    var maxAbs = 0
    var sumAbs = 0L
    var outliers = 0
    var total = 0
    var worstX = -1
    var worstY = -1
    var worstA = 0
    var worstB = 0
    for (y in 0 until h) {
        for (x in 0 until w) {
            val i = y * w + x
            if (isFringe(x, y)) continue
            total++
            val a = swPx[i]
            val b = hwPx[i]
            val d = maxOf(
                abs(a.alpha - b.alpha),
                abs(a.red - b.red),
                abs(a.green - b.green),
                abs(a.blue - b.blue),
            )
            if (d > maxAbs) {
                maxAbs = d
                worstX = x
                worstY = y
                worstA = a
                worstB = b
            }
            sumAbs += d
            if (d > GPU_PARITY_MAX_ABS) outliers++
        }
    }
    return ParityStats(
        maxAbs,
        if (total == 0) 0.0 else sumAbs.toDouble() / total,
        outliers,
        total,
        worstX,
        worstY,
        worstA,
        worstB,
    )
}

/**
 * CPU↔GPU parity assert. NOT bit-exact by design (Skia blur, AGSL fp32,
 * premultiplied intermediates): per-channel `maxAbs <= maxAbsTol` plus a cap
 * on the outlier share.
 *
 * @param ignoreBoundaryFringe when true, differing pixels 4-adjacent to a
 * pixel that is transparent in BOTH bitmaps are excluded from both gates.
 * Adreno-only accommodation: its rasterizer resolves exact-equality region
 * boundary pixels (guard/clip bounds landing exactly on pixel centers, i.e.,
 * integral filter regions) as CUT where SwiftShader and the CPU keep them,
 * plus dithering on the fractional top row (both verified deterministically
 * on-device). Confined to single boundary-adjacent pixels; interior
 * divergences (wrong kernels, shapes, colors) still fail. See
 * `tmp/GPU_SCALAR_PARITY_REPORT.md` §8.
 */
internal fun assertParity(
    name: String,
    sw: Bitmap,
    hw: Bitmap,
    maxAbsTol: Int = GPU_PARITY_MAX_ABS,
    maxOutlierRatio: Double = GPU_PARITY_MAX_OUTLIER_RATIO,
    ignoreBoundaryFringe: Boolean = false,
) {
    val stats = parityStats(sw, hw, ignoreBoundaryFringe)
    val outlierRatio = stats.outlierCount.toDouble() / stats.total
    if (stats.maxAbs > maxAbsTol || outlierRatio > maxOutlierRatio) {
        dumpParityBitmaps(name, sw, hw, stats)
    }
    assertTrue(
        "$name: maxAbsDiff=${stats.maxAbs} exceeds $maxAbsTol " +
            "(meanAbs=${"%.4f".format(stats.meanAbs)}, " +
            "outliers=${stats.outlierCount}/${stats.total})",
        stats.maxAbs <= maxAbsTol,
    )
    assertTrue(
        "$name: outlierRatio=${"%.5f".format(outlierRatio)} exceeds $maxOutlierRatio " +
            "(maxAbs=${stats.maxAbs}, meanAbs=${"%.4f".format(stats.meanAbs)})",
        outlierRatio <= maxOutlierRatio,
    )
}

/**
 * Loads a golden reference PNG from androidTest assets into [outBitmap].
 * Used where the on-device software reference is itself untrusted (e.g. a
 * divergent native kernel); the golden is generated host-side from the
 * pure-Kotlin reference (see `tmp/GPU_SCALAR_PARITY_REPORT.md`).
 */
internal fun loadGoldenAsset(assetPath: String, outBitmap: Bitmap): Bitmap {
    val assets = androidx.test.platform.app.InstrumentationRegistry.getInstrumentation().context.assets
    return assets.open(assetPath).use {
        // Straight (non-premultiplied), unscaled decode: the golden bytes must
        // land in the bitmap untouched. The defaults (premultiplied + scaled)
        // round/shift pixel values and silently corrupt byte-exact references.
        val opts = android.graphics.BitmapFactory.Options().also { o ->
            o.inBitmap = outBitmap
            o.inPremultiplied = false
            o.inScaled = false
        }
        hu.oandras.ksvg.test.decodePng(it, outBitmap, opts)
            ?: throw AssertionError("GpuParityHarness: cannot decode golden $assetPath")
    }
}

/**
 * Failure diagnostics: writes `<name>.sw.png`, `<name>.hw.png` and
 * `<name>.diff.png` (red = pixel with channel diff above tolerance) into the
 * app-private external files dir for `adb pull`. Only called on failure.
 */
internal fun dumpParityBitmaps(name: String, sw: Bitmap, hw: Bitmap, stats: ParityStats) {
    val safe = name.replace(Regex("[^A-Za-z0-9]+"), "_")
    val dir = try {
        InstrumentationRegistry.getInstrumentation()
            .targetContext.getExternalFilesDir("parity") ?: return
    } catch (_: Exception) {
        return
    }
    try {
        val w = sw.width
        val h = sw.height
        val swPx = IntArray(w * h)
        val hwPx = IntArray(w * h)
        sw.getPixels(swPx, 0, w, 0, 0, w, h)
        hw.getPixels(hwPx, 0, w, 0, 0, w, h)
        val diffPx = IntArray(w * h)
        for (i in swPx.indices) {
            val a = swPx[i]
            val b = hwPx[i]
            val d = maxOf(
                abs(a.alpha - b.alpha),
                abs(a.red - b.red),
                abs(a.green - b.green),
                abs(a.blue - b.blue),
            )
            diffPx[i] = if (d > GPU_PARITY_MAX_ABS) -0x10000 else b
        }
        val diff = createBitmap(w, h, Bitmap.Config.ARGB_8888)
        diff.setPixels(diffPx, 0, w, 0, 0, w, h)
        sw.compress(Bitmap.CompressFormat.PNG, 100, File(dir, "$safe.sw.png").outputStream())
        hw.compress(Bitmap.CompressFormat.PNG, 100, File(dir, "$safe.hw.png").outputStream())
        diff.compress(Bitmap.CompressFormat.PNG, 100, File(dir, "$safe.diff.png").outputStream())
        android.util.Log.w("GpuParity", "$name parity dump in ${dir.absolutePath} stats=$stats")
        android.util.Log.w(
            "GpuParity",
            "$name worst non-fringe d=${stats.maxAbs} at (${stats.worstX},${stats.worstY}) " +
                "ref=${stats.worstA.toUInt().toString(16)} hw=${stats.worstB.toUInt().toString(16)}",
        )
    } catch (_: Exception) {
        // Diagnostics must never mask the real assertion.
    }
}
/** Counts pixels whose packed ARGB value differs between the two bitmaps. */
internal fun countDifferingPixels(a: Bitmap, b: Bitmap): Int {
    assertEquals("Bitmap widths differ", a.width, b.width)
    assertEquals("Bitmap heights differ", a.height, b.height)
    val w = a.width
    val h = a.height
    val aPx = IntArray(w * h)
    val bPx = IntArray(w * h)
    a.getPixels(aPx, 0, w, 0, 0, w, h)
    b.getPixels(bPx, 0, w, 0, 0, w, h)
    var count = 0
    for (i in aPx.indices) {
        if (aPx[i] != bPx[i]) count++
    }
    return count
}

/**
 * Vacuous-pass guard (plan §4): the filtered software render must visibly
 * differ from the unfiltered baseline, proving the primitive actually ran.
 * Without this, a silent software fallback on the HW side would compare
 * CPU-against-CPU and always pass.
 */
internal fun assertVisibleFilterEffect(name: String, filtered: Bitmap, unfiltered: Bitmap) {
    val differing = countDifferingPixels(filtered, unfiltered)
    val ratio = differing.toDouble() / (filtered.width * filtered.height)
    assertTrue(
        "$name: filter has no visible effect " +
            "($differing differing pixels) — primitive may not be exercised",
        ratio >= GPU_PARITY_MIN_VISIBLE_EFFECT_RATIO,
    )
}
