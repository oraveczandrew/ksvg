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

package hu.oandras.ksvg

import hu.oandras.ksvg.utils.textXMLSpaceTransform
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

/**
 * Phase 0 baseline (C3): `<text>` whitespace collapses wrong.
 *
 * Per SVG `xml:space="default"`, newlines/tabs are converted to a single space
 * (not deleted). For `xml:space="preserve"` they must be kept.
 *
 * `removeTabsAndLineBreaks` (utils/String.kt) currently deletes `\n`/`\t`
 * entirely, so `"foo\nbar"` becomes `"foobar"` and the spec-required space is
 * lost.
 *
 * These tests assert the CORRECT behaviour. Today they fail.
 */
@RunWith(RobolectricTestRunner::class)
class C3WhitespaceTest {

    @Test
    fun defaultSpaceConvertsNewlineToSpace() {
        // isFirstChild / isLastChild = true trims outer whitespace but must keep the
        // inner newline converted to a single space.
        val result = textXMLSpaceTransform("foo\nbar", isFirstChild = true, isLastChild = true, spacePreserve = false)
        assertEquals("foo bar", result)
    }

    @Test
    fun defaultSpaceConvertsTabToSpace() {
        val result = textXMLSpaceTransform("foo\tbar", isFirstChild = true, isLastChild = true, spacePreserve = false)
        assertEquals("foo bar", result)
    }

    @Test
    fun preserveSpaceKeepsNewline() {
        val result = textXMLSpaceTransform("a\nb", isFirstChild = true, isLastChild = true, spacePreserve = true)
        assertEquals("a\nb", result)
    }
}
