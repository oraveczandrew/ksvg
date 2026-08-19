// Top-level build file where you can add configuration options common to all subprojects/modules.
plugins {
    id("com.android.library") apply false
    id("org.jetbrains.kotlin.android") apply false
    id("com.google.devtools.ksp") version "2.3.11" apply false
}

subprojects {
    tasks.withType<Test> {
        testLogging {
            showStandardStreams = project.hasProperty("showTestOutput")
        }
    }
}