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

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import hu.oandras.ksvg.dom.SVGImpl
import hu.oandras.ksvg.dom.core.DomParent
import hu.oandras.ksvg.dom.core.ElementBase
import hu.oandras.ksvg.dom.core.SvgObject
import hu.oandras.ksvg.parser.SvgDictionary
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

/**
 * On-device proof that repeated tag/attribute/value strings share one instance
 * through the parser string tables (no instrumentation needed).
 */
@RunWith(AndroidJUnit4::class)
class DictionarySharingTest {

    @Test
    fun repeatedValuesShareInstances() {
        val assets = InstrumentationRegistry.getInstrumentation().context.assets
        val doc = assets.open("dictionary-sharing.svg").use {
            SVG.getFromInputStream(it)
        } as SVGImpl
        val table = SvgDictionary.names.toSet()
        val byContent = mutableMapOf<String, String>()
        var checked = 0
        val stack = ArrayDeque<SvgObject>()
        stack.add(doc.requireRootElement())
        while (stack.isNotEmpty()) {
            val obj = stack.removeLast()
            (obj as? ElementBase)?.attributes?.let { map ->
                for ((_, v) in map) {
                    if (v in table) {
                        val first = byContent[v]
                        if (first == null) {
                            byContent[v] = v
                        } else {
                            assertSame("value '$v' is not shared", first, v)
                        }
                        checked++
                    }
                }
            }
            if (obj is DomParent) stack.addAll(obj.getChildren())
        }
        assertTrue("expected shared values, found none", checked > 0)
    }

    @Test
    fun repeatedInlineStylesShareInstances() {
        val assets = InstrumentationRegistry.getInstrumentation().context.assets
        val doc = assets.open("dictionary-sharing.svg").use {
            SVG.getFromInputStream(it)
        } as SVGImpl
        val styles = mutableListOf<Any>()
        val stack = ArrayDeque<SvgObject>()
        stack.add(doc.requireRootElement())
        while (stack.isNotEmpty()) {
            val obj = stack.removeLast()
            (obj as? ElementBase)?.style?.let { styles.add(it) }
            if (obj is DomParent) stack.addAll(obj.getChildren())
        }
        // Both paths carry the identical style text: one shared instance.
        assertTrue("expected two styled elements, found ${styles.size}", styles.size == 2)
        assertSame("inline styles are not shared", styles[0], styles[1])
    }
}
