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

import android.graphics.Canvas
import android.graphics.Matrix
import android.graphics.Path
import android.graphics.RectF
import hu.oandras.ksvg.dom.style.Style
import hu.oandras.ksvg.render.RendererState
import hu.oandras.ksvg.render.SavedRendererState

internal interface PoolOwner {
    val savedRendererStatePool: Pool<SavedRendererState>
    val renderStatePool: Pool<RendererState>
    val matrixPool: Pool<Matrix>
    val canvasPool: Pool<Canvas>
    val bitmapPool: BitmapPool
    val pathPool: Pool<Path>
    val rectFPool: Pool<RectF>
    val floatArray3Pool: Pool<FloatArray>
    val styleBuilderPool: Pool<Style.Builder>

    fun clear()
}

private class PoolOwnerImpl: PoolOwner {

    override val savedRendererStatePool: Pool<SavedRendererState> = object : Pool<SavedRendererState>() {
        private val defaultRenderState = RendererState()

        override fun createInstance(): SavedRendererState {
            return SavedRendererState(defaultRenderState, 0)
        }

        override fun resetInstance(item: SavedRendererState) {
            // ignore
        }
    }

    override val renderStatePool: Pool<RendererState> = object : Pool<RendererState>() {

        private val defaultRenderState = RendererState()

        override fun createInstance(): RendererState {
            return RendererState()
        }

        override fun resetInstance(item: RendererState) {
            item.apply(defaultRenderState)
        }
    }

    override val rectFPool: Pool<RectF> = object : Pool<RectF>() {
        override fun createInstance(): RectF {
            return RectF()
        }

        override fun resetInstance(item: RectF) {
            item.set(0f, 0f, 0f, 0f)
        }
    }

    override val floatArray3Pool: Pool<FloatArray> = object : Pool<FloatArray>() {
        override fun createInstance(): FloatArray {
            return FloatArray(3)
        }

        override fun resetInstance(item: FloatArray) {
            item[0] = 0f
            item[1] = 0f
            item[2] = 0f
        }
    }

    override val pathPool: Pool<Path> = object : Pool<Path>() {
        override fun createInstance(): Path {
            return Path()
        }

        override fun resetInstance(item: Path) {
            item.reset()
        }
    }

    override val canvasPool: Pool<Canvas> = object : Pool<Canvas>() {
        override fun createInstance(): Canvas {
            return Canvas()
        }

        override fun resetInstance(item: Canvas) {
            item.setBitmap(null)
            item.setMatrix(null)
        }
    }

    override val matrixPool: Pool<Matrix> = object: Pool<Matrix>() {
        override fun createInstance(): Matrix = Matrix()

        override fun resetInstance(item: Matrix) {
            item.reset()
        }
    }

    override val bitmapPool = BitmapPool()

    override val styleBuilderPool: Pool<Style.Builder> = object : Pool<Style.Builder>() {
        override fun createInstance(): Style.Builder {
            return Style.Builder()
        }

        override fun resetInstance(item: Style.Builder) {
            // item.reset() is called by the user before use
        }
    }

    override fun clear() {
        matrixPool.clear()
        canvasPool.clear()
        bitmapPool.clear()
        floatArray3Pool.clear()
        styleBuilderPool.clear()
    }
}

internal fun PoolOwner(): PoolOwner {
    return PoolOwnerImpl()
}