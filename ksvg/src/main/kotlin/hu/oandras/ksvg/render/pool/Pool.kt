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

package hu.oandras.ksvg.render.pool

import hu.oandras.ksvg.utils.forEachElement
import hu.oandras.ksvg.utils.indexOfFirstElement

internal abstract class Pool<T> {
    private val deque = ArrayList<T>()

    protected abstract fun createInstance(): T

    protected abstract fun resetInstance(item: T)

    fun pull(): T {
        return deque.removeLastOrNull()?.also {
            resetInstance(it)
        } ?: createInstance()
    }

    fun release(item: T) {
        if (deque.indexOfFirstElement { it === item } < 0) {
            deque.add(item)
        }
    }

    fun releaseAll(items: MutableList<T>) {
        items.forEachElement { items ->
            release(items)
        }
        items.clear()
    }

    fun clear() {
        deque.clear()
    }
}

@IgnorableReturnValue
internal inline fun <T, K> Pool<T>.withPooledObject(r: (T) -> K): K {
    val item = pull()
    try {
        return r.invoke(item)
    } finally {
        release(item)
    }
}