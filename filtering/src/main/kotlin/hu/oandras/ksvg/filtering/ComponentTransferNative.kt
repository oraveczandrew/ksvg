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
 * feComponentTransfer kernel over unpremultiplied ARGB_8888 IntArrays.
 *
 * All per-channel transfer math (table/discrete/linear/gamma plus any
 * sRGB<->linearRGB folding) is precomputed by the caller into four 256-entry
 * byte tables; the native side only performs table gathers. Pixels outside the
 * clip rectangle are set to transparent black in dst.
 *
 * Stateless and allocation-free: both pixel arrays are caller-owned scratch
 * (reused buffers), no shared/global state. Availability follows the same
 * `libksvgblur` library as [NativeGaussianBlur].
 */
public object ComponentTransferNative {

    @JvmField
    public val isAvailable: Boolean = NativeGaussianBlur.isAvailable

    @JvmStatic
    public external fun apply(
        src: IntArray,
        dst: IntArray,
        width: Int,
        height: Int,
        clipLeft: Int,
        clipTop: Int,
        clipRight: Int,
        clipBottom: Int,
        tableA: ByteArray,
        tableR: ByteArray,
        tableG: ByteArray,
        tableB: ByteArray,
    )
}
