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

import hu.oandras.ksvg.utils.removeDoubleSpaces
import hu.oandras.ksvg.utils.textXMLSpaceTransform
import hu.oandras.ksvg.utils.trimLowerThanSpace
import org.junit.Assert.assertEquals
import org.junit.Test

class StringUtilsTest {

    // --- removeDoubleSpaces ---

    @Test
    fun testRemoveDoubleSpacesNoDouble() {
        assertEquals("hello world", "hello world".removeDoubleSpaces())
    }

    @Test
    fun testRemoveDoubleSpacesDouble() {
        assertEquals("hello world", "hello  world".removeDoubleSpaces())
    }

    @Test
    fun testRemoveDoubleSpacesTriple() {
        assertEquals("hello world", "hello   world".removeDoubleSpaces())
    }

    @Test
    fun testRemoveDoubleSpacesMultiple() {
        assertEquals("a b c", "a  b   c".removeDoubleSpaces())
    }

    @Test
    fun testRemoveDoubleSpacesLeading() {
        assertEquals(" hello", "  hello".removeDoubleSpaces())
    }

    @Test
    fun testRemoveDoubleSpacesTrailing() {
        assertEquals("hello ", "hello  ".removeDoubleSpaces())
    }

    // --- textXMLSpaceTransform ---

    @Test
    fun testXMLSpaceTransformPreserve() {
        assertEquals(
            "hello\tworld",
            textXMLSpaceTransform(
                "hello\tworld",
                isFirstChild = true,
                isLastChild = true,
                spacePreserve = true
            )
        )
    }

    @Test
    fun testXMLSpaceTransformPreserveKeepsTabs() {
        assertEquals(
            "hello\tworld",
            textXMLSpaceTransform(
                "hello\tworld",
                isFirstChild = true,
                isLastChild = true,
                spacePreserve = true
            )
        )
    }

    @Test
    fun testXMLSpaceTransformDefaultFirstAndLast() {
        assertEquals(
            "hello",
            textXMLSpaceTransform(
                "  hello  ",
                isFirstChild = true,
                isLastChild = true,
                spacePreserve = false
            )
        )
    }

    @Test
    fun testXMLSpaceTransformDefaultNotFirst() {
        assertEquals(
            " hello",
            textXMLSpaceTransform(
                "  hello  ",
                isFirstChild = false,
                isLastChild = true,
                spacePreserve = false
            )
        )
    }

    @Test
    fun testXMLSpaceTransformDefaultNotLast() {
        assertEquals(
            "hello ",
            textXMLSpaceTransform(
                "  hello  ",
                isFirstChild = true,
                isLastChild = false,
                spacePreserve = false
            )
        )
    }

    @Test
    fun testXMLSpaceTransformDefaultNeitherFirstNorLast() {
        assertEquals(
            " hello ",
            textXMLSpaceTransform(
                "  hello  ",
                isFirstChild = false,
                isLastChild = false,
                spacePreserve = false
            )
        )
    }

    @Test
    fun testXMLSpaceTransformDefaultCollapseSpaces() {
        assertEquals(
            "hello world",
            textXMLSpaceTransform(
                "hello  world", isFirstChild = true,
                isLastChild = true,
                spacePreserve = false
            )
        )
    }

    @Test
    fun testXMLSpaceTransformDefaultMultipleSpacesCollapse() {
        assertEquals(
            "a b c",
            textXMLSpaceTransform(
                "a  b   c",
                isFirstChild = true,
                isLastChild = true,
                spacePreserve = false
            )
        )
    }

    // --- trimLowerThanSpace ---

    @Test
    fun testTrimLowerThanSpaceNoChange() {
        assertEquals("hello", "hello".trimLowerThanSpace())
    }

    @Test
    fun testTrimLowerThanSpaceTrimsTab() {
        assertEquals("hello", "\t\thello\t\t".trimLowerThanSpace())
    }

    @Test
    fun testTrimLowerThanSpaceTrimsNewline() {
        assertEquals("hello", "\nhello\n".trimLowerThanSpace())
    }

    @Test
    fun testTrimLowerThanSpaceTrimsCarriageReturn() {
        assertEquals("hello", "\rhello\r".trimLowerThanSpace())
    }

    @Test
    fun testTrimLowerThanSpaceDoesNotTrimSpace() {
        assertEquals("hello", "  hello  ".trimLowerThanSpace())
    }

    @Test
    fun testTrimLowerThanSpaceEmpty() {
        assertEquals("", "".trimLowerThanSpace())
    }
}
