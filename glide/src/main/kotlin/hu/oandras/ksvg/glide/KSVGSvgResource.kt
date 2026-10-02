/*
 *    Copyright 2026 András Oravecz <info@oandras.hu>
 *
 *    Licensed under the Apache License, Version 2.0 (the "License");
 *    you may not use this file except in compliance with the License.
 *    You may obtain a copy of the License at
 *
 *        https://www.apache.org/licenses/LICENSE-2.0
 *
 *    Unless required by applicable law or agreed to in writing, software
 *    distributed under the License is distributed on an "AS IS" BASIS,
 *    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *    See the License for the specific language governing permissions and
 *    limitations under the License.
 */

package hu.oandras.ksvg.glide

import com.bumptech.glide.load.engine.Resource
import hu.oandras.ksvg.SVG

/**
 * Glide [Resource] wrapping a parsed [SVG] document.
 *
 * The document is immutable after parsing and safe to share: per-target
 * drawables are created from it by [KSVGSvgDrawableTranscoder], so this is
 * what lives in Glide's caches — never a drawable instance.
 */
public class KSVGSvgResource(private val svg: SVG) : Resource<SVG> {
    override fun getResourceClass(): Class<SVG> = SVG::class.java
    override fun get(): SVG = svg
    override fun getSize(): Int {
        // Cache-weighing estimate: one intrinsic-sized frame. Falls back to
        // 192px per axis for viewBox-only documents without intrinsics.
        val documentWidth = svg.documentWidth
        val width = if (documentWidth > 0f) documentWidth else FALLBACK_DIMENSION_PX
        val documentHeight = svg.documentHeight
        val height = if (documentHeight > 0f) documentHeight else FALLBACK_DIMENSION_PX
        return (width.toLong() * height.toLong() * BYTES_PER_PIXEL)
            .coerceAtMost(Int.MAX_VALUE.toLong()).toInt()
    }

    override fun recycle() {
        // The parsed document holds no pooled memory; nothing to release.
    }

    private companion object {
        const val FALLBACK_DIMENSION_PX: Float = 192f
        const val BYTES_PER_PIXEL: Long = 4L
    }
}
