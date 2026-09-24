import java.io.File
import java.util.concurrent.TimeUnit

// Host-architecture build of the native kernels (turbulence, blur, lighting, ...)
// so JVM unit tests can drive the real native path bit-exactly against the Kotlin
// reference (TurbulenceNativeParityTest). Output lands in this module's build dir.
val hostNativeCpp: FileTree = fileTree("src/main/cpp") {
    include("**/*.cpp", "**/*.h", "**/*.S")
}
val hostNativeOutputDir: File = layout.buildDirectory.dir("host-native").get().asFile
val hostLibName: String = when {
    System.getProperty("os.name").lowercase().contains("mac") -> "libksvgfilters.dylib"
    System.getProperty("os.name").lowercase().contains("linux") -> "libksvgfilters.so"
    else -> "ksvgfilters.dll"
}
val buildHostNativeLib = tasks.register<Exec>("buildHostNativeLib") {
    group = "verification"
    description = "Builds a host-architecture libksvgfilters for native-vs-Kotlin kernel parity tests."
    inputs.files(hostNativeCpp)
    inputs.file(rootProject.file("filtering/host-native/CMakeLists.txt"))
    outputs.file(hostNativeOutputDir.resolve(hostLibName))
    workingDir(rootProject.file("filtering/host-native"))
    val configureDir = hostNativeOutputDir.resolve("cmake")
    commandLine(
        "sh", "-c",
        "cmake -S . -B ${configureDir.absolutePath} " +
            "-DCMAKE_BUILD_TYPE=Release " +
            "-DCMAKE_LIBRARY_OUTPUT_DIRECTORY=${hostNativeOutputDir.absolutePath} " +
            "-DCMAKE_RUNTIME_OUTPUT_DIRECTORY=${hostNativeOutputDir.absolutePath} " +
            "&& cmake --build ${configureDir.absolutePath} -j",
    )
}
tasks.matching { it.name == "testDebugUnitTest" }.configureEach { dependsOn(buildHostNativeLib) }
