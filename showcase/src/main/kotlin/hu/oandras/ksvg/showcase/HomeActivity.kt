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

package hu.oandras.ksvg.showcase

import android.content.Intent
import android.os.Bundle
import android.util.Log
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import androidx.profileinstaller.ProfileVerifier

// Launcher entry point: two buttons leading to the View-based gallery and the Compose tests.
class HomeActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        applyLightSystemBars()
        val binding = homeLayout()
        setContentView(binding.root)
        binding.classicButton.setOnClickListener {
            startActivity(Intent(this, ViewsTestActivity::class.java))
        }
        binding.composeButton.setOnClickListener {
            startActivity(Intent(this, ComposeTestActivity::class.java))
        }
        logBaselineProfileStatus()
    }

    /** One-line diagnostics: is the shipped baseline profile compiled in? */
    private fun logBaselineProfileStatus() {
        val future = ProfileVerifier.getCompilationStatusAsync()
        future.addListener({
            val status = try {
                future.get()
            } catch (e: Exception) {
                Log.w(TAG, "profile status check failed", e)
                return@addListener
            }
            Log.i(TAG, "baseline profile: ${describe(status.profileInstallResultCode)}" +
                ", compiled=${status.isCompiledWithProfile}")
        }, ContextCompat.getMainExecutor(this))
    }

    companion object {
        private const val TAG = "BaselineProfile"

        private fun describe(code: Int): String = when (code) {
            ProfileVerifier.CompilationStatus.RESULT_CODE_COMPILED_WITH_PROFILE ->
                "COMPILED_WITH_PROFILE"
            ProfileVerifier.CompilationStatus.RESULT_CODE_PROFILE_ENQUEUED_FOR_COMPILATION ->
                "ENQUEUED_FOR_COMPILATION"
            ProfileVerifier.CompilationStatus.RESULT_CODE_COMPILED_WITH_PROFILE_NON_MATCHING ->
                "COMPILED_WITH_PROFILE_NON_MATCHING (stale profile?)"
            ProfileVerifier.CompilationStatus.RESULT_CODE_NO_PROFILE_INSTALLED ->
                "NO_PROFILE_INSTALLED"
            ProfileVerifier.CompilationStatus.RESULT_CODE_ERROR_NO_PROFILE_EMBEDDED ->
                "ERROR_NO_PROFILE_EMBEDDED"
            else -> "code=$code"
        }
    }
}
