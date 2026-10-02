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
package hu.oandras.ksvg.dom.style

import hu.oandras.ksvg.css.CSSLength
import hu.oandras.ksvg.css.CssUnit
import org.junit.Assert.assertEquals
import org.junit.Assert.assertSame
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

/**
 * [CSSLength.of] returns shared instances for the values that dominate parsed
 * documents, keyed on the (value, unit) pair: unit matters, `0px` is not `0%`.
 */
@RunWith(RobolectricTestRunner::class)
class CSSLengthOfTest {

    @Test
    fun commonValuesReturnSharedInstances() {
        assertSame(CSSLength.ZERO, CSSLength.of(0f, CssUnit.px))
        assertSame(CSSLength.ONE, CSSLength.of(1f, CssUnit.px))
        assertSame(CSSLength.PERCENT_0, CSSLength.of(0f, CssUnit.percent))
        assertSame(CSSLength.PERCENT_50, CSSLength.of(50f, CssUnit.percent))
        assertSame(CSSLength.PERCENT_100, CSSLength.of(100f, CssUnit.percent))
    }

    @Test
    fun otherValuesReturnEqualFreshInstances() {
        val length = CSSLength.of(12.5f, CssUnit.px)

        assertEquals(CSSLength(12.5f, CssUnit.px), length)
        assertEquals(12.5f, length.value, 0f)
    }

    @Test
    fun unitDistinguishesZero() {
        assertEquals(CSSLength(0f, CssUnit.px), CSSLength.ZERO)
        assertEquals(CSSLength(0f, CssUnit.percent), CSSLength.PERCENT_0)
    }
}
