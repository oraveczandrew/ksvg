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

package hu.oandras.ksvg.mocks

import android.graphics.Path
import android.graphics.PathMeasure
import org.robolectric.annotation.Implementation
import org.robolectric.annotation.Implements

@Suppress("unused", "TestFunctionName")
@Implements(PathMeasure::class)
class MockPathMeasure {
    private var path: Path? = null
    private var forceClosed: Boolean = false
    private var length: Float = 0f

    @Implementation
    fun __constructor__(path: Path?, forceClosed: Boolean) {
        setPath(path, forceClosed)
    }

    @Implementation
    fun setPath(path: Path?, forceClosed: Boolean) {
        this.path = path
        this.forceClosed = forceClosed
        this.length = calculateLength(path)
    }

    @Implementation
    fun getLength(): Float = length

    @Implementation
    fun getPosTan(distance: Float, pos: FloatArray?, tan: FloatArray?): Boolean {
        return interpolate(path, distance, pos, tan)
    }

    private fun calculateLength(path: Path?): Float {
        if (path == null) return 0f
        val shadow = path.asShadow()
        var totalLength = 0f
        var lastX = 0f
        var lastY = 0f
        for (cmd in shadow.path) {
            val parts = cmd.split(" ")
            when (parts[0]) {
                "M" -> {
                    lastX = parts[1].toFloat()
                    lastY = parts[2].toFloat()
                }
                "L" -> {
                    val x = parts[1].toFloat()
                    val y = parts[2].toFloat()
                    totalLength += Math.hypot((x - lastX).toDouble(), (y - lastY).toDouble()).toFloat()
                    lastX = x
                    lastY = y
                }
            }
        }
        return totalLength
    }

    private fun interpolate(path: Path?, distance: Float, pos: FloatArray?, tan: FloatArray?): Boolean {
        if (path == null) return false
        val shadow = path.asShadow()
        var currentDist = 0f
        var lastX = 0f
        var lastY = 0f
        val commands = shadow.path
        if (commands.isEmpty()) return false

        for (cmd in commands) {
            val parts = cmd.split(" ")
            when (parts[0]) {
                "M" -> {
                    lastX = parts[1].toFloat()
                    lastY = parts[2].toFloat()
                }
                "L" -> {
                    val x = parts[1].toFloat()
                    val y = parts[2].toFloat()
                    val segLen = Math.hypot((x - lastX).toDouble(), (y - lastY).toDouble()).toFloat()
                    if (segLen > 0 && currentDist + segLen >= distance) {
                        val t = if (segLen == 0f) 0f else (distance - currentDist) / segLen
                        pos?.let {
                            it[0] = lastX + (x - lastX) * t
                            it[1] = lastY + (y - lastY) * t
                        }
                        tan?.let {
                            it[0] = (x - lastX) / segLen
                            it[1] = (y - lastY) / segLen
                        }
                        return true
                    }
                    currentDist += segLen
                    lastX = x
                    lastY = y
                }
            }
        }
        // If distance is exactly total length or slightly beyond due to precision
        pos?.let { it[0] = lastX; it[1] = lastY }
        return true
    }
}

// Helper to access MockPath fields if needed, but I should probably just use it via asShadow()
// Wait, MockPath fields are private. I might need to make them internal or add a getter.
