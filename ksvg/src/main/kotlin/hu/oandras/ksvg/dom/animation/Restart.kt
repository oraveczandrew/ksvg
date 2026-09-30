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

package hu.oandras.ksvg.dom.animation

/**
 * SMIL `restart` attribute (`always | whenNotActive | never`, default
 * `always`): whether a new begin instance may restart a running animation.
 *
 * KSVG has a single-begin timeline (no event/syncbase/instance lists), so no
 * second instance can ever occur and the value is behaviorally inert. It is
 * parsed and stored so the model is complete for a future multi-begin path.
 */
@Suppress("EnumEntryName")
internal enum class Restart {
    always,
    whenNotActive,
    never
}

// Parses a restart attribute value; invalid falls back to the default.
internal fun parseRestart(value: String): Restart {
    return when {
        value.equals("always", ignoreCase = true) -> Restart.always
        value.equals("whenNotActive", ignoreCase = true) -> Restart.whenNotActive
        value.equals("never", ignoreCase = true) -> Restart.never
        else -> Restart.always
    }
}
