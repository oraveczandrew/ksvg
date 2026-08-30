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

package hu.oandras.ksvg.render

import android.graphics.Bitmap
import android.graphics.RectF
import androidx.collection.ArrayMap
import hu.oandras.ksvg.render.pool.PoolOwner
import hu.oandras.ksvg.utils.forEachElement
import hu.oandras.ksvg.utils.forEachKey
import hu.oandras.ksvg.utils.forEachValue

internal class FilterSourceMap(
    private val poolOwner: PoolOwner,
) {
    private val results = ArrayMap<String, Bitmap>()
    private val resultsWithoutId: ArrayList<Bitmap> = ArrayList()

    // The filter-primitive subregion (in user space) of each named result. Per the SVG
    // Filter Effects spec, when a following primitive omits x/y/width/height and its input
    // is a referenced node's result, its subregion defaults to the union of the referenced
    // node(s)' subregions — not the full filter region.
    private val resultRegion = ArrayMap<String, RectF>()

    private var sourceGraphic: Bitmap? = null

    fun reInitWith(sourceGraphic: Bitmap) {
        clearMap()
        this.sourceGraphic = sourceGraphic
        results["SourceGraphic"] = sourceGraphic

        resultsWithoutId.clear()
    }

    /** Records the user-space subregion of the primitive result identified by [id]. */
    fun setResultRegion(id: String?, rect: RectF) {
        if (id == null) return
        val existing = resultRegion[id]
        if (existing != null) {
            existing.set(rect)
        } else {
            resultRegion[id] = RectF(rect)
        }
    }

    /**
     * Returns the user-space subregion of a previously stored named result, or `null` when
     * [id] does not reference a stored result (e.g. it is a standard input or is unknown).
     */
    fun getResultRegion(id: String?): RectF? {
        if (id == null) return null
        return resultRegion[id]
    }

    fun get(id: String): Bitmap? {
        return results[id] ?: run {
            if (id == "SourceAlpha") {
                sourceGraphic?.let { sourceGraphic ->
                    poolOwner.run {
                        extractAlpha(sourceGraphic).also {
                            results["SourceAlpha"] = it
                        }
                    }
                }
            } else {
                null
            }
        }
    }

    fun set(id: String?, bitmap: Bitmap) {
        if (id != null) {
            results[id] = bitmap
        } else {
            resultsWithoutId.add(bitmap)
        }
    }

    fun recycle(exclude: Bitmap? = null) {
        val bitmapPool = poolOwner.bitmapPool

        results.forEachValue { bitmap ->
            // `sourceGraphic` is owned by the element that hosts the filter (its cached
            // source content), not by this map. Releasing it here would hand a live,
            // referenced bitmap back to the pool, where `clear()` could recycle it and
            // cause a later "trying to use a recycled bitmap" crash.
            if (bitmap !== exclude && bitmap !== sourceGraphic) {
                bitmapPool.release(bitmap)
            }
        }
        clearMap()

        resultsWithoutId.forEachElement { bitmap ->
            if (bitmap !== exclude) {
                bitmapPool.release(bitmap)
            }
        }
        resultsWithoutId.clear()
    }

    private fun clearMap() {
        results.forEachKey { string ->
            results[string] = null
        }
        resultRegion.clear()
    }
}