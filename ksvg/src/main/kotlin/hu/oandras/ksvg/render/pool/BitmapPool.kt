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

import android.graphics.Bitmap
import androidx.collection.ArrayMap
import hu.oandras.ksvg.render.createBitmap
import hu.oandras.ksvg.utils.forEachKeyValue
import java.util.*

/**
 * A pool of reusable [Bitmap]s keyed by width, height and config, used to avoid
 * per-frame allocations in the render loop.
 *
 * Contract:
 * - [acquire] and [acquireSameAs] always hand back a fully erased (transparent)
 *   bitmap, whether it was freshly allocated or reused from the pool.
 * - The pool owns any bitmap passed to [release]; it must not be touched
 *   afterwards and must not be released more than once.
 */
internal class BitmapPool {

    private class Key(
        @JvmField
        var width: Int,
        @JvmField
        var height: Int,
        @JvmField
        var config: Bitmap.Config,
    ) {
        override fun equals(other: Any?): Boolean {
            return other === this ||
                    other is Key &&
                    width == other.width &&
                    height == other.height &&
                    config == other.config
        }

        override fun hashCode(): Int {
            var result = width
            result = 31 * result + height
            result = 31 * result + config.hashCode()
            return result
        }

        override fun toString(): String {
            return "Key(width=$width, height=$height, config=$config)"
        }
    }

    private val pools = ArrayMap<Key, ArrayDeque<Bitmap>>()

    private val lookupKey = Key(
        width = 0,
        height = 0,
        config = Bitmap.Config.ARGB_8888,
    )

    /**
     * Acquires a bitmap with the same dimensions and config as [bitmap].
     *
     * The returned bitmap is always fully erased (transparent), regardless of
     * whether it was freshly allocated or reused from the pool. Callers must
     * not rely on the previous contents and must not call [Bitmap.eraseColor]
     * again after acquiring.
     */
    fun acquireSameAs(bitmap: Bitmap): Bitmap {
        return acquire(
            width = bitmap.width,
            height = bitmap.height,
            config = bitmap.config!!
        )
    }

    /**
     * Acquires a bitmap with the given dimensions and config.
     *
     * The returned bitmap is always fully erased (transparent), regardless of
     * whether it was freshly allocated or reused from the pool. Callers must
     * not rely on the previous contents and must not call [Bitmap.eraseColor]
     * again after acquiring.
     */
    fun acquire(
        width: Int,
        height: Int,
        config: Bitmap.Config,
    ): Bitmap {
        lookupKey.width = width
        lookupKey.height = height
        lookupKey.config = config

        val pool = pools[lookupKey] ?: return createBitmap(
            width,
            height,
            config
        )

        while (pool.isNotEmpty()) {
            val bitmap = pool.removeLast()

            if (!bitmap.isRecycled) {
                return bitmap.also {
                    it.eraseColor(0)
                }
            }
        }

        return createBitmap(width, height, config)
    }

    /**
     * Returns a bitmap to the pool for later reuse by [acquire] or [acquireSameAs].
     *
     * Recycled bitmaps and bitmaps without a config are ignored. A bitmap that
     * is already present in its bucket is not added again, so callers must not
     * release the same instance more than once. The pool takes ownership of the
     * bitmap; it must not be read from or written to after being released.
     */
    fun release(bitmap: Bitmap) {
        if (bitmap.isRecycled) {
            return
        }

        val config = bitmap.config ?: return

        lookupKey.width = bitmap.width
        lookupKey.height = bitmap.height
        lookupKey.config = config

        var pool = pools[lookupKey]

        if (pool == null) {
            pool = ArrayDeque()
            pools[Key(
                width = lookupKey.width,
                height = lookupKey.height,
                config = lookupKey.config,
            )] = pool
        }

        if (!pool.contains(bitmap)) {
            pool.addLast(bitmap)
        }
    }

    /**
     * Recycles every pooled bitmap and empties the pool. Call this to free all
     * retained native memory (e.g., on a low-memory event or when the renderer
     * is no longer needed).
     */
    fun clear() {
        pools.forEachKeyValue { _, bitmaps ->
            bitmaps.forEach { it.recycle() }
        }
        pools.clear()
    }

    override fun toString(): String {
        var imageCount = 0
        var imageBytes = 0
        pools.forEachKeyValue { _, bitmapQueues ->
            imageCount += bitmapQueues.size
            imageBytes += bitmapQueues.sumOf { it.allocationByteCount }
        }
        return "BitmapPool(imageCount=$imageCount, imageBytes=$imageBytes)"
    }
}