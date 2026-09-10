/*
 *    Copyright 2026 András Oravecz <info@oandras.hu>
 *
 *    Licensed under the Apache License, Version 2.0 (the "License");
 */

package hu.oandras.ksvg.filtering.benchmark

import android.content.Context
import android.os.Build
import android.os.PowerManager

internal fun Context.sustainedSupportedSnapshot(): Boolean {
    val powerManager = getSystemService(Context.POWER_SERVICE) as? PowerManager ?: return false
    return powerManager.isSustainedPerformanceModeSupported
}

internal fun Context.thermalStatus(): Int? {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return null
    val powerManager = getSystemService(Context.POWER_SERVICE) as? PowerManager ?: return null
    return powerManager.currentThermalStatus
}
