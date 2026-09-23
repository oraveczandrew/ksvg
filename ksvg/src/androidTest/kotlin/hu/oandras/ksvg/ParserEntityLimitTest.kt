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
import hu.oandras.ksvg.dom.SVGImpl
import hu.oandras.ksvg.dom.core.Container
import hu.oandras.ksvg.dom.core.SvgObject
import hu.oandras.ksvg.dom.text.TextSequence
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Device counterpart of the host billion-laughs guard test (audit D1/R2):
 * decides whether Android's Expat-based SAX stack reports internal-entity
 * boundaries (startEntity/endEntity), which the expansion counter depends on.
 * Few expansions (21), many chars (2M): only OUR guard can fire here.
 */
@RunWith(AndroidJUnit4::class)
class ParserEntityLimitTest {

    @Test
    fun billionLaughsTripsExpansionLimitOnDevice() {
        // No static getter exists; default is enabled (fresh instrumentation
        // process), so restore the default afterwards.
        // Sized past the SAX_CHAR_LIMIT backstop (10M chars out): on stacks that
        // report entity boundaries the precise 1M guard fires first; on blind
        // stacks (Android Expat, device-measured) the backstop must fire.
        SVG.setInternalEntitiesEnabled(true)
        try {
            // Phase 1 (2M chars, below every cap): prove Expat expands at all.
            // Discriminator is the parsed text length, summed over TextSequences.
            val small = "x".repeat(100_000)
            val smallRefs = StringBuilder()
            repeat(20) { smallRefs.append("&a0;") }
            val probe =
                "<!DOCTYPE svg [<!ENTITY a0 \"$small\"><!ENTITY a1 \"$smallRefs\">]>" +
                    "<svg xmlns=\"http://www.w3.org/2000/svg\">" +
                    "<text id=\"t\">&a1;</text>" +
                    "</svg>"
            val probed = SVGImpl.getFromString(probe, logger = NoopLoggerContext)
            var total = 0
            fun walk(o: SvgObject) {
                if (o is TextSequence) total += o.text.length
                if (o is Container) o.getChildren().forEach(::walk)
            }
            (probed.getElementById("t") as? Container)?.let(::walk)
            println("AUDITDBG device textChars=$total")
            assertTrue("expected Expat to expand entities at all", total > 1_000_000)

            // Phase 2 (10M chars, past the SAX_CHAR_LIMIT backstop): must trip.
            // (The precise 1M guard only fires where entity boundaries are
            // reported; the backstop covers blind stacks.)
            val big = "x".repeat(500_000)
            val refs = StringBuilder()
            repeat(20) { refs.append("&a0;") }
            val test =
                "<!DOCTYPE svg [<!ENTITY a0 \"$big\"><!ENTITY a1 \"$refs\">]>" +
                    "<svg xmlns=\"http://www.w3.org/2000/svg\">" +
                    "<text>&a1;</text>" +
                    "</svg>"
            try {
                SVGImpl.getFromString(test, logger = NoopLoggerContext)
                fail("expected KSVGParseException for billion laughs")
            } catch (e: KSVGParseException) {
                var cursor: Throwable? = e
                var seen = false
                val dbg = StringBuilder()
                var guard = 0
                while (cursor != null && !seen && guard++ < 10) {
                    val message = cursor.message ?: ""
                    dbg.append("[").append(cursor::class.simpleName).append(": ").append(message).append("] <- ")
                    if (message.contains("expansion limit") || message.contains("SAX character limit")) seen = true
                    // SAXException nests via getException(), not always via cause.
                    val next: Throwable? = (cursor as? org.xml.sax.SAXException)?.exception ?: cursor.cause
                    cursor = if (next === cursor) null else next
                }
                println("AUDITDBG device throw chain: $dbg")
                assertTrue(
                    "expected our expansion guard (precise or backstop)",
                    seen
                )
            }
        } finally {
            SVG.setInternalEntitiesEnabled(true)
        }
    }
}
