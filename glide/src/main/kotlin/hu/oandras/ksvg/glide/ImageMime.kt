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

package hu.oandras.ksvg.glide

import androidx.annotation.StringDef

@Retention(AnnotationRetention.SOURCE)
@StringDef(value = [
    ImageMime.AVIF,
    ImageMime.GIF,
    ImageMime.PNG,
    ImageMime.JPEG,
    ImageMime.WEBP
])
internal annotation class ImageMime {
    companion object {
        const val GIF: String = "image/gif"
        const val PNG: String = "image/png"
        const val JPEG: String = "image/jpeg"
        const val WEBP: String = "image/webp"
        const val AVIF: String = "image/avif"
        const val SVG: String = "image/svg+xml"
        const val APNG: String = "image/apng"
    }
}