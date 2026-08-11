package hu.oandras.androidsvg.utils

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.Base64
import android.util.Log

private const val TAG = "Base64ImageDecoder"

/*
* Check for and decode an image encoded in a data URL.
* We don't handle all permutations of data URLs. Only base64 ones.
*/
internal fun checkForImageDataURL(url: String): Bitmap? {
    if (!url.startsWith("data:")) {
        return null
    }

    if (url.length < 14) {
        return null
    }

    val comma = url.indexOf(',')

    if (comma < 12) {
        // "< 12"  test also covers not found (-1) case
        return null
    }

    if (!url.regionMatches(comma - 7, ";base64", 0, 7)) {
        return null
    }

    try {
        val imageData = Base64.decode(
            url.substring(comma + 1),
            Base64.DEFAULT
        ) // throws IllegalArgumentException for bad data
        return BitmapFactory.decodeByteArray(imageData, 0, imageData.size)
    } catch (e: Exception) {
        Log.e(TAG, "Could not decode bad Data URL", e)
        return null
    }
}