package hu.oandras.androidsvg.utils

import android.annotation.SuppressLint
import android.graphics.Bitmap
import androidx.annotation.VisibleForTesting
import kotlin.math.sqrt

@SuppressLint("UseKtx")
@VisibleForTesting
internal class BitmapComparator(
    targetWidth: Int,
    targetHeight: Int,
) {

    private val tempPixels1 = IntArray(targetWidth * targetHeight)
    private val tempPixels2 = IntArray(targetWidth * targetHeight)

    internal fun compareBitmaps(b1: Bitmap, b2: Bitmap): Double {
        assert(b1 !== b2)

        if (b1.width != b2.width || b1.height != b2.height) return 0.0

        var matchingPixels = 0
        val totalPixels = b1.width * b1.height
        val pixels1 = tempPixels1
        val pixels2 = tempPixels2

        b1.getPixels(pixels1, 0, b1.width, 0, 0, b1.width, b1.height)
        b2.getPixels(pixels2, 0, b2.width, 0, 0, b2.width, b2.height)

        for (i in 0 until totalPixels) {
            if (isColorSimilar(pixels1[i], pixels2[i])) {
                matchingPixels++
            }
        }

        return matchingPixels.toDouble() / totalPixels.toDouble()
    }

    private fun isColorSimilar(c1: Int, c2: Int): Boolean {
        if (c1 == c2) return true

        val r1 = c1.red
        val g1 = c1.green
        val b1 = c1.blue
        val a1 = c1.alpha

        val r2 = c2.red
        val g2 = c2.green
        val b2 = c2.blue
        val a2 = c2.alpha

        val dist = sqrt(
            ((r1 - r2).squared() +
                    (g1 - g2).squared() +
                    (b1 - b2).squared() +
                    (a1 - a2).squared()).toDouble()
        )

        return dist < 15.0
    }
}