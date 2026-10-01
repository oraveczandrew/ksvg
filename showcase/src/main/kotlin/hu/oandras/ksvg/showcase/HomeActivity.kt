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
import androidx.appcompat.app.AppCompatActivity

// Launcher entry point: two buttons leading to the View-based gallery and the Compose tests.
class HomeActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val binding = homeLayout()
        setContentView(binding.root)
        binding.classicButton.setOnClickListener {
            startActivity(Intent(this, MainActivity::class.java))
        }
        binding.composeButton.setOnClickListener {
            startActivity(Intent(this, ComposeTestActivity::class.java))
        }
    }
}
