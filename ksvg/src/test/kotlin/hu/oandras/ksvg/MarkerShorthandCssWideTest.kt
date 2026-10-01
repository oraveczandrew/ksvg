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

import hu.oandras.ksvg.dom.style.Style
import org.junit.Assert.assertFalse
import org.junit.Test

class MarkerShorthandCssWideTest {

    @Test
    fun markerInheritMarksAllThreeLonghands() {
        val builder = Style.Builder()
        builder.reset(Style())
        with(NoopLoggerContext) {
            Style.processStyleProperty(builder, "marker", "inherit", false)
        }
        val style = builder.build()
        assertFalse(style.isSpecified(Style.SPECIFIED_MARKER_START))
        assertFalse(style.isSpecified(Style.SPECIFIED_MARKER_MID))
        assertFalse(style.isSpecified(Style.SPECIFIED_MARKER_END))
    }
}
