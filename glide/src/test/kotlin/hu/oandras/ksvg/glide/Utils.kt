package hu.oandras.ksvg.glide

import java.io.InputStream
import kotlin.jvm.java

fun Any.resourceAsInputStream(name: String): InputStream {
    return this::class.java.classLoader!!.getResourceAsStream(name)
}