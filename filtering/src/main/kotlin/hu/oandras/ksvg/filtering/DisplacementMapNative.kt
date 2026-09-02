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

package hu.oandras.ksvg.filtering

/**
 * feDisplacementMap kernel over unpremultiplied ARGB_8888.
 *
 * Stateless and availability follows `libksvgblur` ([NativeGaussianBlur.isAvailable]).
 */
internal object DisplacementMapNative {

    @JvmField
    val isAvailable: Boolean = NativeGaussianBlur.isAvailable

    @JvmStatic
    external fun apply(
        src: IntArray,
        map: IntArray,
        dst: IntArray,
        width: Int,
        height: Int,
        mapWidth: Int,
        mapHeight: Int,
        scale: Float,
        xChannel: Int,
        yChannel: Int,
    )

    /**
     * Validation/test-only twin of [apply]. Runs an explicitly selected backend
     * regardless of normal CPU dispatch.
     */
    @JvmStatic
    external fun applyForced(
        src: IntArray,
        map: IntArray,
        dst: IntArray,
        width: Int,
        height: Int,
        mapWidth: Int,
        mapHeight: Int,
        scale: Float,
        xChannel: Int,
        yChannel: Int,
        simdBackend: Int,
    )

    /** Reports the backend the production dispatcher actually selects on this ABI. */
    @JvmStatic
    external fun nativeBackend(): Int
}
