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

package hu.oandras.ksvg.render

import android.graphics.Matrix
import hu.oandras.ksvg.HitRegion
import hu.oandras.ksvg.dom.text.A
import hu.oandras.ksvg.utils.forEachElement

/**
 * Collects clickable `<a>` regions in root-local space (the space
 * `hitTest` maps screen coordinates into via the inverse root transform).
 *
 * Every [RenderNode.boundingBox] is stored in its own local (pre-transform)
 * space, so ancestor `transform` / `viewBoxTransform` matrices are accumulated
 * down the walk in the same order the renderer concatenates them
 * (`transform` first, then `viewBoxTransform`). The root node's own transform
 * is intentionally excluded to preserve the `screenToSvgTransform` contract.
 *
 * Runs on demand when hit regions go stale — never on the render hot path —
 * so per-level [Matrix] allocation is acceptable here.
 */
internal fun collectHitRegions(node: RenderNode<*>, regions: MutableList<HitRegion>) {
    val identity = Matrix()
    if (node is GroupRenderNode<*>) {
        node.children.forEachElement { child ->
            collectHitRegionsRecursive(child, regions, identity)
        }
    } else {
        collectHitRegionsRecursive(node, regions, identity)
    }
}

private fun collectHitRegionsRecursive(
    node: RenderNode<*>,
    regions: MutableList<HitRegion>,
    parentMatrix: Matrix
) {
    if (node is GroupRenderNode<*> && node.sourceElement is A) {
        val href = (node.sourceElement as A).href
        val bb = node.boundingBox
        if (href != null && bb != null) {
            val world = Matrix(parentMatrix)
            node.transform?.let { world.postConcat(it) }
            node.viewBoxTransform?.let { world.postConcat(it) }
            val rect = bb.toRectF()
            world.mapRect(rect)
            regions.add(HitRegion(href, rect))
        }
    }
    if (node is GroupRenderNode<*>) {
        val childMatrix = Matrix(parentMatrix)
        node.transform?.let { childMatrix.postConcat(it) }
        node.viewBoxTransform?.let { childMatrix.postConcat(it) }
        node.children.forEachElement { child ->
            collectHitRegionsRecursive(child, regions, childMatrix)
        }
    }
}

/**
 * Inverse of the root node's user→screen mapping: `transform` followed by
 * `viewBoxTransform`, matching renderer concat order
 * (`applyTransformTo` then `concat(viewBoxTransform)`). Without a `viewBox`
 * the latter is a pure viewport translation, so this reduces exactly to the
 * previous behavior (inverse root transform, else viewport translation).
 *
 * Returns null when the root carries neither matrix; callers then fall back
 * to the viewport translation.
 */
internal fun inverseRootMapping(node: RenderNode<*>): Matrix? {
    var mapped = false
    val forward = Matrix()
    node.transform?.let { forward.postConcat(it); mapped = true }
    node.viewBoxTransform?.let { forward.postConcat(it); mapped = true }
    if (!mapped) return null
    val inverse = Matrix()
    return if (forward.invert(inverse)) inverse else null
}
