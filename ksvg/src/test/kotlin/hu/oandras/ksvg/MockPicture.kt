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
package hu.oandras.ksvg

import android.graphics.Canvas
import android.graphics.Picture
import org.robolectric.annotation.Implementation
import org.robolectric.annotation.Implements
import org.robolectric.shadows.ShadowPicture

/**
 * Mock version of Android Picture class for testing.
 */
@Implements(Picture::class)
class MockPicture : ShadowPicture() {
    private var width: Int = 0

    override fun getWidth(): Int {
        return width
    }

    //public static Picture createFromStream(InputStream stream ) { return null; }
    private var height: Int = 0

    override fun getHeight(): Int {
        return height
    }

    private var canvas: Canvas? = null
    private var recording = false

    val operations: List<String>
        get() = canvas!!.asShadow().getOperations()

    fun clearOperations() {
        canvas!!.asShadow().clearOperations()
    }

    @Implementation
    override fun beginRecording(width: Int, height: Int): Canvas {
        this.width = width
        this.height = height
        val canvas = Canvas().also {
            this.canvas = it
        }
        this.recording = true
        return canvas
    }

    @Implementation
    fun endRecording() {
        recording = false
    }


    //public void draw(Canvas canvas) { /* do nothing */ }
    //public boolean requiresHardwareAcceleration() { return true; }
    //public void writeToStream(OutputStream stream ) { /* do nothing */ }
}
