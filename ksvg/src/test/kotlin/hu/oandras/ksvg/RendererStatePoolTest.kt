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
package hu.oandras.ksvg

import hu.oandras.ksvg.render.RendererState
import hu.oandras.ksvg.render.pool.PoolOwner
import org.junit.Assert.assertEquals
import org.junit.Assert.assertSame
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

/**
 * Unit coverage for the renderer-state pools of a real [PoolOwner]. Their
 * default reset snapshot is built on first use instead of in the constructor,
 * so these tests pin down that a recycled state is still reset to a pristine
 * default and that the snapshot is shared by every recycled instance.
 */
@RunWith(RobolectricTestRunner::class)
class RendererStatePoolTest {

    @Test
    fun recycledStateIsResetToADefaultState() {
        val pools = PoolOwner()

        val state = pools.renderStatePool.pull()
        state.hasFill = true
        state.fillConfig.color = 0xFFFF0000.toInt()
        pools.renderStatePool.release(state)

        val recycled = pools.renderStatePool.pull()

        assertSame(state, recycled)
        assertEquals(false, recycled.hasFill)
        assertEquals(
            RendererState().fillConfig.color,
            recycled.fillConfig.color
        )
    }

    @Test
    fun resetSnapshotIsSharedAcrossRecycledStates() {
        val pools = PoolOwner()

        val first = pools.renderStatePool.pull()
        val second = pools.renderStatePool.pull()
        pools.renderStatePool.release(first)
        pools.renderStatePool.release(second)

        // Both recycled instances must be reset from the very same snapshot, so
        // that the reset is a plain field copy rather than a fresh allocation.
        first.hasStroke = true
        first.strokeConfig.strokeWidth = 11f
        val recycledFirst = pools.renderStatePool.pull()
        recycledFirst.hasFill = true
        recycledFirst.fillConfig.strokeWidth = 3f
        pools.renderStatePool.release(recycledFirst)
        val recycledSecond = pools.renderStatePool.pull()

        assertEquals(
            RendererState().strokeConfig.strokeWidth,
            recycledSecond.strokeConfig.strokeWidth
        )
    }

    @Test
    fun savedStatesShareASingleDefaultSnapshot() {
        val pools = PoolOwner()

        val first = pools.savedRendererStatePool.pull()
        val second = pools.savedRendererStatePool.pull()

        assertSame(first.state, second.state)
        assertEquals(0, first.canvasSaveCount)
        assertEquals(0, second.canvasSaveCount)
    }
}