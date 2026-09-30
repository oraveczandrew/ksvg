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

package hu.oandras.ksvg.glide

import hu.oandras.ksvg.LoggerContext
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class LabeledLoggerContextTest {

    private class RecordingLogger : LoggerContext {
        val messages = mutableListOf<Triple<Int, String, String>>()
        var loggable: Boolean = true
        override fun log(level: Int, tag: String, message: String) {
            messages.add(Triple(level, tag, message))
        }
        override fun isLoggable(tag: String, level: Int): Boolean = loggable
    }

    @Test
    fun testPrefixesMessageWithLabelInParentheses() {
        val delegate = RecordingLogger()
        val labeled = LabeledLoggerContext(delegate, "https://example.com/icon.svg")
        labeled.log(LoggerContext.WARN, "KSVG", "unsupported element")
        assertEquals(1, delegate.messages.size)
        assertEquals("(https://example.com/icon.svg) unsupported element", delegate.messages[0].third)
    }

    @Test
    fun testEmptyLabelForwardsUnchanged() {
        val delegate = RecordingLogger()
        val labeled = LabeledLoggerContext(delegate, "")
        labeled.log(LoggerContext.WARN, "KSVG", "plain message")
        assertEquals("plain message", delegate.messages[0].third)
    }

    @Test
    fun testIsLoggableDelegates() {
        val delegate = RecordingLogger().apply { loggable = false }
        val labeled = LabeledLoggerContext(delegate, "label")
        assertTrue(!labeled.isLoggable("KSVG", LoggerContext.WARN))
    }
}
