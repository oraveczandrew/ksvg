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

import android.graphics.Rect
import hu.oandras.ksvg.ExternalFileResolver
import hu.oandras.ksvg.dom.SVGImpl
import hu.oandras.ksvg.render.pool.BitmapPool
import hu.oandras.ksvg.render.pool.PoolOwner

/**
 * Owns a built render-node tree together with the state that decides when the
 * tree has to be rebuilt versus when it can be updated in place.
 *
 * Rebuild triggers:
 *  - document [modificationCount] changed (parse/mutation),
 *  - render-options fingerprint changed (css / view / viewBox / preserveAspectRatio / target),
 *  - viewport (drawable bounds) changed -- until viewport in-place updates are
 *    implemented, this also forces a rebuild (Step 1 behaviour).
 *
 * The options fingerprint deliberately excludes the viewport: bounds changes are
 * expected to be frequent (layout passes) and are handled by the update path.
 */
internal class RenderScene private constructor(
    @JvmField val rootNode: RenderNode<*>?,
    @JvmField val modificationCount: Int,
    @JvmField val optionsFingerprint: Long,
) {

    /** Last applied drawable bounds. */
    @JvmField var viewport: Rect? = null

    fun isUpToDate(modificationCount: Int, fingerprint: Long): Boolean {
        return this.modificationCount == modificationCount &&
                this.optionsFingerprint == fingerprint
    }

    fun recycle(bitmapPool: BitmapPool) {
        rootNode?.recycle(bitmapPool)
    }

    internal companion object {
        fun build(
            document: SVGImpl,
            dPI: Float,
            externalFileResolver: ExternalFileResolver?,
            pools: PoolOwner,
            options: RenderOptionsImpl,
            modificationCount: Int,
            optionsFingerprint: Long,
        ): RenderScene {
            val builder = RenderTreeBuilder(
                document = document,
                dPI = dPI,
                externalFileResolver = externalFileResolver,
                pools = pools,
            )
            val node = builder.build(options)
            return RenderScene(node, modificationCount, optionsFingerprint)
        }

        /**
         * Fingerprint of the render-options fields that require a tree rebuild.
         * Excludes the viewport (frequent, handled by the update path).
         */
        fun computeOptionsFingerprint(options: RenderOptionsImpl): Long {
            var result = options.css.hashCode().toLong()
            result = 31L * result + options.preserveAspectRatio.hashCode()
            result = 31L * result + options.targetId.hashCode()
            result = 31L * result + options.viewBox.hashCode()
            result = 31L * result + options.viewId.hashCode()
            return result
        }
    }
}

