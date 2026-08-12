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

package hu.oandras.ksvg.utils

import androidx.collection.FloatList
import androidx.collection.MutableObjectFloatMap
import androidx.collection.MutableObjectIntMap
import androidx.collection.SimpleArrayMap

internal inline fun <T> List<T>.forEachElement(r: (T) -> Unit) {
    for (i in indices) {
        r.invoke(get(i))
    }
}

internal fun <T> MutableObjectIntMap<T>?.copyIfNotEmpty(): MutableObjectIntMap<T>? {
    return if (this == null || this.isEmpty()) {
        null
    } else {
        MutableObjectIntMap<T>(this.size).also {
            it.putAll(this)
        }
    }
}

internal fun <T> MutableObjectFloatMap<T>?.copyIfNotEmpty(): MutableObjectFloatMap<T>? {
    return if (this == null || this.isEmpty()) {
        null
    } else {
        MutableObjectFloatMap<T>(this.size).also {
            it.putAll(this)
        }
    }
}

internal inline fun<K, V> SimpleArrayMap<K, V>.forEachKeyValue(r: (K, V) -> Unit) {
    for (i in 0 until size()) {
        r(keyAt(i), valueAt(i))
    }
}

internal fun FloatList.toFloatArray(): FloatArray {
    return FloatArray(size) {
        get(it)
    }
}