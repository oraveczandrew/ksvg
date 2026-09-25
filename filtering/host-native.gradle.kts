import java.io.File

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
    // Opt-in 32-bit Intel host build: -Pksvg.host32bit (or env KSVG_HOST_32BIT=1).
    // Compiles the i386 .S kernels with -m32 so the parity suites exercise the
    // 32-bit Intel path on 64-bit Linux runners (needs gcc-multilib + a 32-bit JVM).
    val host32bit: Boolean = (project.findProperty("ksvg.host32bit")?.toString() == "true") ||
        System.getenv("KSVG_HOST_32BIT") == "1"
    inputs.property("ksvg.host32bit", host32bit)
    val javaHome = System.getProperty("java.home")
    environment("JAVA_HOME", javaHome)
    commandLine(
        "sh", "-c",
        "cmake -S . -B ${configureDir.absolutePath} " +
            "-DCMAKE_BUILD_TYPE=Release " +
            "-DJAVA_HOME=${javaHome} " +
            "-DKSVG_HOST_32BIT=" + (if (host32bit) "ON" else "OFF") + " " +
            "-DCMAKE_LIBRARY_OUTPUT_DIRECTORY=${hostNativeOutputDir.absolutePath} " +
            "-DCMAKE_RUNTIME_OUTPUT_DIRECTORY=${hostNativeOutputDir.absolutePath} " +
            "&& cmake --build ${configureDir.absolutePath} -j",
    )
}
tasks.matching { it.name == "testDebugUnitTest" }.configureEach { dependsOn(buildHostNativeLib) }
