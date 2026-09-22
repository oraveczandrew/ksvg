/*
 *    Copyright 2013-2020 Paul LeBeau, Cave Rock Software Ltd.
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

package hu.oandras.ksvg.css

import android.util.ArrayMap
import java.util.Locale

// Supported SVG attributes
@Suppress("EnumEntryName")
internal enum class PseudoClassIdentifiers {
    target,
    root,
    nth_child,
    nth_last_child,
    nth_of_type,
    nth_last_of_type,
    first_child,
    last_child,
    first_of_type,
    last_of_type,
    only_child,
    only_of_type,
    empty,
    not,

    // Others from  Selectors 3 (and earlier)
    // Supported but always fail to match.
    lang,  // might support later
    link, visited, hover, active, focus, enabled, disabled, checked, indeterminate,  // Added in Selectors 4 spec
    // Might support these later
    //matches,
    //something,  // Not final name(?)
    //has,
    //dir,  might support later
    //target_within,
    //blank,

    // Operators from Selectors 4
    // any-link, local-link, scope, focus-visible, focus-within, drop, current, past,
    // future, playing, paused, read-only, read-write, placeholder-shown, default, valid, invalid,
    // in-range, out-of-range, required, optional, user-invalid, nth-col, nth-last-col
    UNSUPPORTED;

    companion object {
        private val cache: Map<String, PseudoClassIdentifiers> = ArrayMap<String, PseudoClassIdentifiers>(entries.size - 1).apply {
            for (attr in PseudoClassIdentifiers.entries) {
                if (attr != UNSUPPORTED) {
                    val key = attr.name.replace('_', '-')
                    this[key] = attr
                }
            }
        }

        @JvmStatic
        fun fromString(str: String?): PseudoClassIdentifiers {
            // CSS pseudo-classes are ASCII case-insensitive.
            return cache[str?.lowercase(Locale.US)] ?: UNSUPPORTED
        }
    }
}