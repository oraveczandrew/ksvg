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

package hu.oandras.ksvg.render.pool

/**
 * Lazily sized, reusable [IntArray]. Avoids re-allocating pixel buffers on every
 * render frame; only grows/allocates when the required size changes.
 */
internal class IntArrayBucket {
    @JvmField var array: IntArray? = null

    fun getWithSize(size: Int): IntArray {
        var array = array
        if (array?.size != size) {
            array = IntArray(size).also {
                this.array = it
            }
        }
        return array
    }
}