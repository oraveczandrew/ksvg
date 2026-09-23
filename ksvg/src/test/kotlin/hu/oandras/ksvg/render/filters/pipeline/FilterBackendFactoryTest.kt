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

package hu.oandras.ksvg.render.filters.pipeline

import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * API routing of the filter-backend factories. Explicit SDK levels only, so the
 * test stays off `Build.VERSION` (plain JVM, no Robolectric). Backend behavior
 * itself is covered by device parity tests.
 */
class FilterBackendFactoryTest {

    @Test
    fun routesByApi() {
        assertTrue(FilterBackendFactory.forApi(36) is FilterBackendFactoryImpl33)
        assertTrue(FilterBackendFactory.forApi(33) is FilterBackendFactoryImpl33)
        assertTrue(FilterBackendFactory.forApi(32) is FilterBackendFactoryImpl31)
        assertTrue(FilterBackendFactory.forApi(31) is FilterBackendFactoryImpl31)
        assertTrue(FilterBackendFactory.forApi(30) is FilterBackendFactoryImpl26)
        assertTrue(FilterBackendFactory.forApi(21) is FilterBackendFactoryImpl26)
    }
}
