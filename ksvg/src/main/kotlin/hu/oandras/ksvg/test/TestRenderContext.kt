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

package hu.oandras.ksvg.test

import android.graphics.Canvas
import android.graphics.Matrix
import android.graphics.Path
import android.graphics.RectF
import hu.oandras.ksvg.dom.core.Box
import hu.oandras.ksvg.dom.style.Style
import hu.oandras.ksvg.render.FilterPrimitiveRenderNode
import hu.oandras.ksvg.render.RenderContext
import hu.oandras.ksvg.render.RenderNode
import hu.oandras.ksvg.render.RendererState
import hu.oandras.ksvg.render.SavedRendererState
import hu.oandras.ksvg.render.pool.BitmapPool
import hu.oandras.ksvg.render.pool.Pool

/**
 * Minimal [RenderContext] for driving filter kernels directly in unit
 * tests (e.g. `doFeImageFilter`) with hand-built bitmaps. Real pools where
 * the kernels need them ([bitmapPool], [canvasPool], [matrixPool],
 * [rectFPool]); inert stubs elsewhere. `renderNode`/`resolveFloodColor`
 * are unsupported (they need a full renderer).
 */
internal class TestRenderContext : RenderContext {
    override val dPI: Float = 160f
    override val currentFontSize: Float = 12f
    override val currentFontXHeight: Float = 6f
    override val effectiveViewPortInUserUnits: Box = Box(0f, 0f, 100f, 100f)
    override fun log(level: Int, tag: String, message: String) {}
    override fun isLoggable(tag: String, level: Int): Boolean = false
    override val savedRendererStatePool: Pool<SavedRendererState> =
        simplePool { SavedRendererState(RendererState(), 0) }
    override val renderStatePool: Pool<RendererState> = simplePool { RendererState() }
    override val matrixPool: Pool<Matrix> = simplePool { Matrix() }
    override val canvasPool: Pool<Canvas> = simplePool { Canvas() }
    override val bitmapPool: BitmapPool = BitmapPool()
    override val pathPool: Pool<Path> = simplePool { Path() }
    override val rectFPool: Pool<RectF> = simplePool { RectF() }
    override val floatArray3Pool: Pool<FloatArray> = simplePool { FloatArray(3) }
    override val styleBuilderPool: Pool<Style.Builder> = simplePool { Style.Builder() }
    override fun clear() {}
    override fun resolveFloodColor(
        primitiveNode: FilterPrimitiveRenderNode<*>,
        baseStyle: Style,
    ): Int = throw UnsupportedOperationException("TestRenderContext cannot resolve flood colors")
    override fun renderNode(canvas: Canvas, node: RenderNode<*>) {
        throw UnsupportedOperationException("TestRenderContext cannot render nodes")
    }

    private companion object {
        fun <T> simplePool(create: () -> T): Pool<T> = object : Pool<T>() {
            override fun createInstance(): T = create()
            override fun resetInstance(item: T) {}
        }
    }
}
