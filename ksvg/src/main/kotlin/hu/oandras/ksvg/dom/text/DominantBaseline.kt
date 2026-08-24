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

internal enum class DominantBaseline {
    Auto,
    UseScript,
    NoChange,
    ResetSize,
    Alphabetic,
    Ideographic,
    Mathematical,
    Hanging,
    TextAfterEdge,
    TextBeforeEdge,
    Central,
    Middle,
    TextTop,
    TextBottom
}

// Parse a dominant baseline keyword
internal fun parseDominantBaseline(value: String): DominantBaseline? {
    return when {
        value.equals("auto", ignoreCase = true) -> DominantBaseline.Auto
        value.equals("use-script", ignoreCase = true) -> DominantBaseline.UseScript
        value.equals("no-change", ignoreCase = true) -> DominantBaseline.NoChange
        value.equals("reset-size", ignoreCase = true) -> DominantBaseline.ResetSize
        value.equals("alphabetic", ignoreCase = true) -> DominantBaseline.Alphabetic
        value.equals("ideographic", ignoreCase = true) -> DominantBaseline.Ideographic
        value.equals("mathematical", ignoreCase = true) -> DominantBaseline.Mathematical
        value.equals("hanging", ignoreCase = true) -> DominantBaseline.Hanging
        value.equals("text-after-edge", ignoreCase = true) -> DominantBaseline.TextAfterEdge
        value.equals("text-before-edge", ignoreCase = true) -> DominantBaseline.TextBeforeEdge
        value.equals("central", ignoreCase = true) -> DominantBaseline.Central
        value.equals("middle", ignoreCase = true) -> DominantBaseline.Middle
        value.equals("text-top", ignoreCase = true) -> DominantBaseline.TextTop
        value.equals("text-bottom", ignoreCase = true) -> DominantBaseline.TextBottom
        else -> null
    }
}
