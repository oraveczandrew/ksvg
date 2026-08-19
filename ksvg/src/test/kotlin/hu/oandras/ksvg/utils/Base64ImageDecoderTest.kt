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

package hu.oandras.ksvg.utils

import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(manifest = Config.NONE)
class Base64ImageDecoderTest {

    @Test
    fun testNonDataUrl() {
        assertNull(checkForImageDataURL("http://example.com/image.png"))
        assertNull(checkForImageDataURL("assets/image.png"))
    }

    @Test
    fun testShortUrl() {
        assertNull(checkForImageDataURL("data:123"))
    }

    @Test
    fun testNoComma() {
        assertNull(checkForImageDataURL("data:image/png;base64"))
    }

    @Test
    fun testInvalidCommaPosition() {
        // comma at index 11
        assertNull(checkForImageDataURL("data:1234567,"))
    }

    @Test
    fun testNotBase64() {
        assertNull(checkForImageDataURL("data:image/png;utf-8,rawdata"))
    }

    @Test
    fun testValidBase64() {
        // 1x1 transparent PNG
        val url = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII="
        val bitmap = checkForImageDataURL(url)
        assertNotNull(bitmap)
    }

    @Test
    fun testBadBase64() {
        val url = "data:image/png;base64,invalid-base64-content!!!"
        assertNull(checkForImageDataURL(url))
    }
}
