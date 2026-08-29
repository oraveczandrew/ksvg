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

import android.graphics.Canvas
import hu.oandras.ksvg.dom.style.Style
import hu.oandras.ksvg.render.pool.PoolOwner

internal interface RenderContext: DisplayContext, PoolOwner {
    fun resolveFloodColor(
        primitiveNode: FilterPrimitiveRenderNode<*>,
        baseStyle: Style
    ): Int

    /** Renders a previously-built render node onto the given canvas (used by `feImage`
     *  when it references another element by id). */
    fun renderNode(canvas: Canvas, node: RenderNode<*>)
}
