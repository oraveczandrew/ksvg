# Native Benchmark Harness — Implementation Plan

**Specification:** `tmp/TEST_HARNESS.md` (24 sections, the source of truth for behavior)
**Target module:** `:filtering` (`androidTest`)
**Goal:** A stable, long-running native/NEON microbenchmark harness for the instrumented
tests that detects thermal throttling / CPU-frequency drift and reports per-sample
statistics, so that `old-assembly vs new-assembly` comparisons are trustworthy.

Guiding principle (spec §23 + AGENTS.md): **infrastructure changes and kernel/assembly
changes go in separate commits**, and the benchmark harness must never be "helped" by
touching the code it measures.

---

## 1. Current state (findings)

- `KernelBenchmarkRunner` (`filtering/src/testFixtures/.../KernelBenchmarkRunner.kt`)
  is shared host+device. It measures a **single wall-clock average** over N iterations
  (`avgMs`), has a `warmup` param, and reports CSV + Markdown. No per-sample stats.
- `KernelPerformanceDeviceBenchmark` (`androidTest`) drives 8 kernels × 2 sizes
  (512² / 2048²), wired to `KernelBenchmarkRunner.runBenchmark` + `report(File)`.
  Output pulled into `tmp/benchmarks_device*.csv` by the `runDeviceBenchmark` Gradle task.
- There is **no instrumented test manifest**, no Activity, no foreground window, no
  thread-priority handling, no thermal monitoring, no warmup/measurement batch model,
  and no per-sample statistics.
- The `filtering` module is a **library**. AGP auto-generates a self-contained test APK
  (package `hu.oandras.filtering.test`) that contains the library + test classes + native
  libs in **one process**. → An Activity declared in `filtering/src/androidTest/AndroidManifest.xml`
  runs in the *same* process as the kernels being measured, so the foreground-window /
  sustained-performance approach is viable without a separate app module.
- Per-kernel parity tests exist (`TurbulenceNativeParityTest` and 7 others). These are the
  correctness gate and must stay green (acceptance item 12).

## 2. Design decisions (each traces to a spec section)

1. **Package** (spec §2): `hu.oandras.ksvg.filtering.benchmark` under `androidTest`, files:
   - `NativeBenchmarkHarness.kt` — public DSL + orchestration (spec §19)
   - `ThermalStateMonitor.kt` — API 29+ status + API<29 fallback probe (§6, §7)
   - `CpuInfo.kt` — device + sysfs best-effort + affinity availability (§10, §11)
   - `BenchmarkActivity.kt` — minimal foreground Activity owning the Window (§3)
   - `CacheNormalizer.kt` — deterministic memory workload (§8)
   - `BenchmarkReport.kt` — statistics + classification + environment (§14, §15, §16)
   - `BenchmarkStats.kt` — distribution math (§14)
2. **Do not fork AndroidX internals** (spec §18): implement the ThrottleDetector/ThreadPriority
   *ideas* ourselves; no `androidx.benchmark.*` reflection.
3. **Separation** (spec §1, §2): harness lives in the benchmark test sources; production
   native code untouched; `KernelBenchmarkRunner` (host JVM suite) left as-is. The new
   harness keeps **CSV-compatible output** so the existing `runDeviceBenchmark` Gradle pull
   workflow keeps working; the harness may be adopted by the device benchmark test later.
4. **Activity viability spike first** (spec §3): confirm a launched `BenchmarkActivity` in the
   test APK, on the main thread, yields a real foreground Window on which
   `setSustainedPerformanceMode(true)` can be observed. If a device/platform silently ignores
   it, the harness **reports** `sustainedPerformanceMode=false` (never fails the run).
5. **Measurement model** (spec §13, §20): `warmup` → `batch 1..N`; per-iteration
   `System.nanoTime()` sampling; measured region = **only the JNI call**; all thermal checks,
   cache reset, logging, I/O outside the measured region.
6. **Thermal gating** (spec §6, §7, §9): status `> THERMAL_STATUS_NONE` (or fallback probe
   degradation ≥ ~10%) invalidates the current batch only → cooldown (configurable) → retry.
7. **Statistics / comparison** (spec §14): report min/median/mean/max/p90/p95/p99/stddev;
   compare primarily by **median**, secondarily **p90**, then **min**.
8. **Classification** (spec §15): `VALID / THERMAL_THROTTLED / THERMAL_RECOVERY /
   UNSTABLE / INSUFFICIENT_SAMPLES`.
9. **CPU affinity** (spec §11): report availability only; **no root/taskset/shell hacks**;
   architecture ready for an optional root-only extension.
10. **Public API** (spec §19):
    ```kotlin
    nativeBenchmark {
        warmupIterations = …
        measurementBatches = …
        iterationsPerBatch = …
        run { nativeTurbulenceNoise(...) }
    }
    ```

## 2b. Reference source (checked out, reference only — never a dependency)

AndroidX Benchmark is used as a *technique reference* (spec §18: ideas, not internal APIs).
Shallow/sparse clone at `tmp/androidx-reference/` (`benchmark/benchmark-common/...`, ~12 MB).
Note: in the current monorepo the library API lives in `benchmark-common` (not `benchmark/benchmark`,
which is the Gradle plugin), and the block/phase model is split into `TheMicrobenchmarkPhase`/
`MicrobenchmarkPhase`, `WarmupManager`, etc.

Relevant files mapped to steps:
- **Step 0 (Activity):** `BenchmarkState.kt` / `MicrobenchmarkPhase.kt` (activity launch contract),
  `IsolationActivity.kt` (foreground window + sustained-performance enablement)
- **Step 3 (thermal):** `Api29.kt` (`currentThermalStatus`), `ThrottleDetector.kt`
  (cpufreq-based API<29 fallback; note current code also weighs temp sysfs readings)
- **Step 4 (cooldown/retry):** `ThrottleDetector.kt` (sustained-performance + coalesced sleeps),
  `MicrobenchmarkPhase.kt` (phase invalidation)
- **Step 6 (cpu info):** `CpuInfo.kt`, `DeviceInfo.kt`, `UserInfo.kt`
- **Step 8 (validation/stability):** `BenchmarkStateLegacy.kt` + docs on variance reporting
- **Also useful:** `ThreadPriority.kt`, `Measurements.kt` (percentiles), `WarmupManager.kt`,
  `MemInfo.kt` (background-work parking pattern), `.agents/skills/benchmark/SKILL.md` (module docs)

## 3. Incremental steps (each: `assembleDebugAndroidTest` + device parity + a bench smoke run)

### Step 0 — Activity + sustained-mode spike
- Add `filtering/src/androidTest/AndroidManifest.xml` with a fullscreen `BenchmarkActivity`
  (exported=true). Launch it via a test, verify it is foreground and that
  `window.setSustainedPerformanceMode(true)` is callable/observable on the target device.
- Decide fallback behavior; document result in the worklog. Deliverable: the five-class
  pattern for "works / silently no-op / unavailable". Reference: `IsolationActivity.kt` (2b).

### Step 1 — Harness skeleton + environment report
- `NativeBenchmarkHarness` with config (warmup/batches/iterations/cooldown), foreground
  Activity launch, `android.os.Process.setThreadPriority` on the benchmark thread only
  (restore at end), and an environment report (device/model/version/abi/coreCount/
  sustainedPerformanceMode/…).
- First concrete benchmark: move **Turbulence** onto the DSL (spec §24.3) with a
  scalar-vs-neon basis. Parity tests still green.

### Step 2 — Measurement + statistics
- Batch loop with per-sample timing; `BenchmarkStats` (min/median/mean/max/p90/p95/p99/stddev);
  CSV report compatible with the existing pull path. Verify against the old runner on the
  same device (sanity: same median ballpark).

### Step 3 — Thermal monitoring
- `ThermalStateMonitor`: API 29+ `PowerManager.currentThermalStatus`; API<29 deterministic
  compute probe with per-run baseline. Batches gated on status.
  Reference: `Api29.kt` + `ThrottleDetector.kt` (2b).

### Step 4 — Cooldown / retry / classification
- Invalid batch → configurable cooldown → fresh batch; track `invalidatedBatches`,
  `cooldownTime`; assign `VALID / THERMAL_* / UNSTABLE / INSUFFICIENT_SAMPLES`.

### Step 5 — Cache normalization + strict measured region
- `CacheNormalizer` workload before each batch (outside measurement); audit that the
  measured region contains only the JNI call (no log/IO/thermal/GC — optionally a
  verification assertion in debug).

### Step 6 — CPU info + affinity availability
- `CpuInfo`: `Build.*`, `Runtime.availableProcessors()`, sysfs frequency reads best-effort
  (`cpuFreqBefore/After`, sampling), `cpuAffinityControlAvailable` flag.

### Step 7 — DSL polish + Turbulence migration
- Finalize `nativeBenchmark { }`, migrate the device Turbulence benchmark driver fully,
  keep `benchmark.kernel`/`benchmark.quick` argument compatibility.

### Step 8 — Validation test + acceptance
- New test comparing **raw** vs **harness** runs (spec §22): N runs each; success = lower
  variance, fewer thermal outliers, stabler median/p95 (not necessarily faster).
- Run the full 12-item acceptance checklist from spec §21 and record which stabilizers were
  actually active on the connected device (deliverable 6).

## 4. Verification & acceptance

- After **every** step: build, install, run the device parity suite (all 8 kernels),
  quick turbulence bench smoke run. Parity must stay green.
- Worklog: `tmp/TEST_HARNESS_WORKLOG.md` (findings from the spike, per-step results,
  device thermal observations).

## 5. Risks / mitigations

- **Activity-in-test-APK foreground + sustained mode**: may be a silent no-op on some
  devices/platforms → always reported, never asserted (Step 0 spike resolves the design).
- **API < 29 fallback noise**: probe threshold (10%) configurable; classification tolerates
  borderline cases as UNSTABLE instead of VALID.
- **Per-sample overhead**: `System.nanoTime()` per iteration is acceptable for ms-scale
  kernels; document the floor for sub-µs workloads.
- **Cache-normalizer cost vs benefit**: size configurable; never inside the measured region.
- **No root**: affinity control reported unavailable; benchmark never depends on it.

## 6. Build / run

```bash
# build + install both APKs (or with -PfilterAbis=arm64-v8a)
./gradlew :filtering:assembleDebugAndroidTest -Dorg.gradle.warning.mode=none
adb install -r -t filtering/build/outputs/apk/androidTest/debug/filtering-debug-androidTest.apk

# parity gate (Turbulence example; run the other 7 kernels likewise)
adb shell am instrument -w \
  -e class hu.oandras.ksvg.filtering.TurbulenceNativeParityTest \
  hu.oandras.filtering.test/androidx.test.runner.AndroidJUnitRunner

# harness benchmark
adb shell am instrument -w \
  -e class <benchmark test> \
  hu.oandras.filtering.test/androidx.test.runner.AndroidJUnitRunner
# CSV pulled by the existing runDeviceBenchmark task
./gradlew :filtering:runDeviceBenchmark -Pbenchmark.kernel=Turbulence -Dorg.gradle.warning.mode=none
```

## 7. Deliverables (spec §24)

1. Modified `androidTest` benchmark infrastructure (harness package).
2. `AndroidManifest.xml` + any Gradle changes for the test APK.
3. ≥1 concrete native NEON benchmark test (Turbulence).
4. Example benchmark report (CSV + Markdown, incl. environment + classification).
5. Build/run commands (above) in the worklog.
6. Note on which stabilizers were actually active on the measured device.