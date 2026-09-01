package hu.oandras.ksvg.aihelpers

import android.graphics.Bitmap
import hu.oandras.ksvg.comparisons.applyVerifyFilter
import hu.oandras.ksvg.comparisons.listSvgs
import hu.oandras.ksvg.comparisons.writeLosslessPngTo
import hu.oandras.ksvg.render.createBitmap
import hu.oandras.ksvg.test.BitmapComparator
import hu.oandras.ksvg.test.decodePng
import hu.oandras.ksvg.test.renderWithLibrary
import hu.oandras.ksvg.utils.alpha
import hu.oandras.ksvg.utils.blue
import hu.oandras.ksvg.utils.green
import hu.oandras.ksvg.utils.red
import org.junit.BeforeClass
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.ParameterizedRobolectricTestRunner
import org.robolectric.ParameterizedRobolectricTestRunner.Parameters
import org.robolectric.annotation.GraphicsMode
import java.io.File
import kotlin.math.abs

/**
 * AI-assisted visual-diff helper. Renders each SVG (filtered via `-PverifyFilter=name`) with
 * KSVG and compares it against the rsvg reference golden, writing diagnostics to
 * `test-data/ai-helper/`:
 *  - `<name>.out.png`  — the KSVG render
 *  - `<name>.diff.png` — magenta = pixels that differ from the reference
 *  - `summary.txt`     — per-SVG `similarity`, `diffPixels`, `meanAbsErr`
 *
 * Diagnostic only (never fails the suite). Uses the library colour-channel helpers
 * ([alpha], [red], [green], [blue]) for the per-pixel error metric.
 */
@RunWith(ParameterizedRobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class AiVisualDiffTest(private val svgFile: File) {

    @Test
    fun analyze() {
        val refPng = File(VERIFICATION_RSVG_GOLDEN_ROOT_PATH, svgFile.name.replace(".svg", ".png"))
        val outDir = File(AI_HELPER_OUT_PATH)
        if (!outDir.exists()) outDir.mkdirs()

        val refBitmap = if (refPng.exists()) decodePng(refPng, tempRef) else null
        val libBitmap = renderWithLibrary(svgFile, tempOut, softwareFiltering = true)

        if (refBitmap != null) {
            val similarity = comparator.compareBitmaps(refBitmap, libBitmap)
            val diff = createBitmap(VERIFICATION_TARGET_SIZE, VERIFICATION_TARGET_SIZE)
            comparator.diffBitmap(refBitmap, libBitmap, diff)

            var diffPixels = 0
            var absErrSum = 0L
            var cornerDiff = 0
            val w = VERIFICATION_TARGET_SIZE
            // Shape corners in canvas space (viewBox == target size == 256, shape is 40..216).
            val corners = arrayOf(40 to 40, 216 to 40, 40 to 216, 216 to 216)
            val px1 = IntArray(w * w)
            val px2 = IntArray(w * w)
            refBitmap.getPixels(px1, 0, w, 0, 0, w, w)
            libBitmap.getPixels(px2, 0, w, 0, 0, w, w)
            for (y in 0 until w) {
                for (x in 0 until w) {
                    val i = y * w + x
                    val c1 = px1[i]
                    val c2 = px2[i]
                    val maxChannel = maxOf(
                        abs(c1.alpha - c2.alpha),
                        abs(c1.red - c2.red),
                        abs(c1.green - c2.green),
                        abs(c1.blue - c2.blue),
                    )
                    if (maxChannel >= 16) {
                        diffPixels++
                        absErrSum += abs(c1.alpha - c2.alpha) +
                            abs(c1.red - c2.red) +
                            abs(c1.green - c2.green) +
                            abs(c1.blue - c2.blue)
                        if (corners.any { (cx, cy) -> abs(x - cx) <= 40 && abs(y - cy) <= 40 }) {
                            cornerDiff++
                        }
                    }
                }
            }
            val meanAbsErr = if (diffPixels > 0) absErrSum.toDouble() / diffPixels / 4.0 else 0.0

            writeLosslessPngTo(File(outDir, svgFile.name.replace(".svg", ".diff.png")), diff)
            File(outDir, "summary.txt").appendText(
                "${svgFile.name} similarity=${"%.4f".format(similarity)} diffPixels=$diffPixels cornerDiff=$cornerDiff meanAbsErr=${"%.2f".format(meanAbsErr)}\n"
            )
        } else {
            // Write a note if golden is missing
            File(outDir, "summary.txt").appendText(
                "${svgFile.name} MISSING GOLDEN REFERENCE\n"
            )
        }

        writeLosslessPngTo(File(outDir, svgFile.name.replace(".svg", ".out.png")), libBitmap)
    }

    companion object {
        private const val VERIFICATION_ROOT_PATH = "test-data/visual"
        private const val VERIFICATION_RSVG_GOLDEN_ROOT_PATH = "test-data/visual-golden"
        private const val AI_HELPER_OUT_PATH = "test-data/ai-helper"
        private const val VERIFICATION_TARGET_SIZE = 256

        private val comparator = BitmapComparator(VERIFICATION_TARGET_SIZE, VERIFICATION_TARGET_SIZE)

        private var _ref: Bitmap? = null
        private val tempRef: Bitmap
            get() = _ref ?: createBitmap(VERIFICATION_TARGET_SIZE, VERIFICATION_TARGET_SIZE).also { _ref = it }

        private var _out: Bitmap? = null
        private val tempOut: Bitmap
            get() = _out ?: createBitmap(VERIFICATION_TARGET_SIZE, VERIFICATION_TARGET_SIZE).also { _out = it }

        private var cleaned = false

        @JvmStatic
        @BeforeClass
        fun setup() {
            if (cleaned) return
            val outDir = File(AI_HELPER_OUT_PATH)
            if (outDir.exists()) {
                outDir.listFiles()?.forEach { it.delete() }
            } else {
                outDir.mkdirs()
            }
            cleaned = true
        }

        @JvmStatic
        @Parameters(name = "{0}")
        fun data(): List<Array<Any>> {
            val root = File(VERIFICATION_ROOT_PATH)
            if (!root.exists()) return emptyList()
            return root.listSvgs().toList().applyVerifyFilter().map { arrayOf(it) }
        }
    }
}
