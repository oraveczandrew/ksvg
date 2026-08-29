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

import kotlin.RequiresOptIn

/**
 * Marks a KSVG API that forces the **software (CPU) filter backend** instead of
 * the GPU/RenderEffect pipeline.
 *
 * Software filtering is significantly slower than the hardware-accelerated path
 * and should only be used when deterministic output is required (e.g. tests or
 * golden comparisons) or when a filter primitive is not supported by the GPU
 * backend. Callers must opt in (e.g. `@OptIn(SlowSoftwareFiltering::class)`) to
 * acknowledge the performance cost.
 */
@RequiresOptIn(
    level = RequiresOptIn.Level.WARNING,
    message = "Forcing software filtering bypasses the GPU filter pipeline and is significantly slower. Only use it for deterministic output (e.g. tests) or for filter primitives the GPU backend does not support."
)
@Retention(AnnotationRetention.BINARY)
@Target(
    AnnotationTarget.CLASS,
    AnnotationTarget.FUNCTION,
    AnnotationTarget.PROPERTY
)
public annotation class SlowSoftwareFiltering
