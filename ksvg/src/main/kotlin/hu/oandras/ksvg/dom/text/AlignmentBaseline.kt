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

package hu.oandras.ksvg.dom.text

internal enum class AlignmentBaseline {
    Auto,
    Baseline,
    BeforeEdge,
    TextBeforeEdge,
    Middle,
    Central,
    AfterEdge,
    TextAfterEdge,
    Ideographic,
    Alphabetic,
    Hanging,
    Mathematical
}

// Parse an alignment baseline keyword
internal fun parseAlignmentBaseline(value: String): AlignmentBaseline? {
    return when {
        value.equals("auto", ignoreCase = true) -> AlignmentBaseline.Auto
        value.equals("baseline", ignoreCase = true) -> AlignmentBaseline.Baseline
        value.equals("before-edge", ignoreCase = true) -> AlignmentBaseline.BeforeEdge
        value.equals("text-before-edge", ignoreCase = true) -> AlignmentBaseline.TextBeforeEdge
        value.equals("middle", ignoreCase = true) -> AlignmentBaseline.Middle
        value.equals("central", ignoreCase = true) -> AlignmentBaseline.Central
        value.equals("after-edge", ignoreCase = true) -> AlignmentBaseline.AfterEdge
        value.equals("text-after-edge", ignoreCase = true) -> AlignmentBaseline.TextAfterEdge
        value.equals("ideographic", ignoreCase = true) -> AlignmentBaseline.Ideographic
        value.equals("alphabetic", ignoreCase = true) -> AlignmentBaseline.Alphabetic
        value.equals("hanging", ignoreCase = true) -> AlignmentBaseline.Hanging
        value.equals("mathematical", ignoreCase = true) -> AlignmentBaseline.Mathematical
        else -> null
    }
}
