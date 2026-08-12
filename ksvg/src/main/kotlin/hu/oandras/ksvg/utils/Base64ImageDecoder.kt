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

package hu.oandras.ksvg.utils

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