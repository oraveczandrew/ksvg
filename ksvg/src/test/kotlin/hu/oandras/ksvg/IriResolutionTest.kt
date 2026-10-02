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

import hu.oandras.ksvg.dom.SVGImpl
import hu.oandras.ksvg.logger.NoopLoggerContext
import org.junit.Assert.assertNull
import org.junit.Assert.assertSame
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

/**
 * Fragment references resolve through the ID cache on demand. The IRI cache
 * memoizes raw lookup results; it does not need a preseeded "#id" entry for
 * every element id.
 */
@RunWith(RobolectricTestRunner::class)
class IriResolutionTest {
    @Test
    fun fragmentResolvesThroughIdCache() {
        val test = "<svg xmlns=\"http://www.w3.org/2000/svg\">" +
            "<g id=\"box\" />" +
            "</svg>"
        val svg: SVGImpl = SVGImpl.getFromString(test, loggerContext = NoopLoggerContext)

        val element = checkNotNull(svg.resolveIRI("#box"))

        assertSame(element, checkNotNull(svg.resolveIRI("#box")))
        assertSame(element, checkNotNull(svg.resolveIRI("\"#box\"")))
        assertNull(svg.resolveIRI("box"))
        assertNull(svg.resolveIRI("#missing"))
    }
}
