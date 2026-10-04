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

package hu.oandras.ksvg.parser

import hu.oandras.ksvg.BuildConfig

@Suppress("DuplicatedCode")
internal class StringDictionary(
    private val names: Array<String>,
    private val hashCodes: IntArray,
) {

    init {
        @Suppress("KotlinConstantConditions")
        if (BuildConfig.DEBUG) {
            for (i in names.indices) {
                assert(hashCode(names[i].toCharArray(), 0, names[i].length) == hashCodes[i])
            }

            assert(hashCodes.sortedArray().contentEquals(hashCodes))
        }
    }

    fun obtainForRange(charArray: CharArray, offset: Int, length: Int): String? {
        return searchWithHasCodeAndEquals(
            hashCode = hashCode(charArray, offset, length),
            charsEquals = { name ->
                charRangeEquals(name, charArray, offset, length)
            }
        )
    }

    fun obtainForRange(charArray: CharSequence, offset: Int, length: Int): String? {
        return searchWithHasCodeAndEquals(
            hashCode = hashCode(charArray, offset, length),
            charsEquals = { name ->
                charRangeEquals(name, charArray, offset, length)
            }
        )
    }

    private inline fun searchWithHasCodeAndEquals(
        hashCode: Int,
        charsEquals: (name: String) -> Boolean,
    ): String? {
        val hashCodes = hashCodes

        val index = hashCodes.binarySearch(hashCode)

        if (index < 0) {
            return null
        }

        val names = names

        val name = names[index]
        if (charsEquals(name)) {
            return name
        }

        for (hashIndex in index + 1 until hashCodes.size) {
            if (hashCodes[hashIndex] != hashCode) {
                break
            }

            val name = names[hashIndex]
            if (charsEquals(name)) {
                return name
            }
        }

        for (hashIndex in index - 1 downTo 0) {
            if (hashCodes[hashIndex] != hashCode) {
                break
            }

            val name = names[hashIndex]
            if (charsEquals(name)) {
                return name
            }
        }

        return null
    }

    private fun charRangeEquals(name: String, charArray: CharArray, offset: Int, length: Int): Boolean {
        if (name.length != length) {
            return false
        }

        for (i in 0 until length) {
            if (charArray[offset + i] != name[i]) {
                return false
            }
        }

        return true
    }

    private fun charRangeEquals(name: String, charArray: CharSequence, offset: Int, length: Int): Boolean {
        if (name.length != length) {
            return false
        }

        for (i in 0 until length) {
            if (charArray[offset + i] != name[i]) {
                return false
            }
        }

        return true
    }

    companion object {

        fun hashCode(charArray: CharArray, offset: Int, length: Int): Int {
            var h = 0

            for (i in offset..<offset+length) {
                h = 31 * h + charArray[i].code
            }

            return h
        }

        fun hashCode(charArray: CharSequence, offset: Int, length: Int): Int {
            var h = 0

            for (i in offset..<offset+length) {
                h = 31 * h + charArray[i].code
            }

            return h
        }
    }
}