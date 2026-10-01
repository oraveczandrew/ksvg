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

/**
 * CSS `unicode-bidi` property (`normal | embed | isolate | bidi-override |
 * isolate-override | plaintext`). Inherited.
 *
 * Hit-for-hit UBA support is out of scope; only the override values change
 * text layout (see `visualOrderForOverride`): `bidi-override` and
 * `isolate-override` force the base direction on every character. All other
 * values keep the platform text stack's default ordering. `plaintext` behaves
 * as `normal` (first-strong base-direction detection is not implemented).
 */
@Suppress("EnumEntryName")
internal enum class UnicodeBidi {
    normal,
    embed,
    isolate,
    bidiOverride,
    isolateOverride,
    plaintext;

    /** True for the two override values that force character direction. */
    internal val isOverride: Boolean
        get() = this == bidiOverride || this == isolateOverride
}

// Parses a unicode-bidi value; null when invalid.
internal fun parseUnicodeBidi(value: String): UnicodeBidi? {
    return when {
        value.equals("normal", ignoreCase = true) -> UnicodeBidi.normal
        value.equals("embed", ignoreCase = true) -> UnicodeBidi.embed
        value.equals("isolate", ignoreCase = true) -> UnicodeBidi.isolate
        value.equals("bidi-override", ignoreCase = true) -> UnicodeBidi.bidiOverride
        value.equals("isolate-override", ignoreCase = true) -> UnicodeBidi.isolateOverride
        value.equals("plaintext", ignoreCase = true) -> UnicodeBidi.plaintext
        else -> null
    }
}
