# NEON Edge Optimization Work Log

## Objective
Fix the generic AArch64 NEON convolve: repair `convolve_neon.S` bugs and fold in (or improve)
the NEON edge path so on-device parity tests pass and the NEON64 backend is faster than scalar.
Currently NEON edge was SLOWER than scalar edge (a regression vs the pre-`d15a05dc` scalar-edge state).

## Key context
- The interior is already a huge win (`neon64 512x512 = 9.6ms` vs `scalar = 128.7ms`, ~13x).
- NEON edge (`convolveNeonEdge4`/`applyNeonEdges4`) is the part that regressed vs scalar edge.
- Keep the assembly (`convolve_neon.S`) — do NOT replace with C++ intrinsics.
- Measure on device `adbca122` via `./gradlew :filtering:runDeviceBenchmark -Pbenchmark.kernel=ConvolveMatrix -Pbenchmark.quick=true`.

## Identified NEON-edge hotspot (from earlier analysis)
1. `vst1q_u32(tmp[4])` spill + per-pixel loop write back — killed the NEON advantage.
2. Four `sampleCoordinateNeonEdge` calls per block per `kx`.
3. `processRange` lambda + per-block overhead.

## Current change (this session)
- Removed the `count` parameter from `convolveNeonEdge4`: it now ALWAYS writes a full
  4-pixel block with a direct spill-free `vst1q_u32(dst + y*width + x, result)`.
- Preserve-alpha path now uses a direct vector load `vld1q_u32(src + y*width + x)` &
  `vandq_u32(..., 0xff000000)` instead of per-lane scalar extraction.
- `applyNeonEdges4.processRange` now only calls `convolveNeonEdge4` for full 4-wide runs;
  the 1..3 tail is handled by scalar `convolveScalarPixel`.
  This guarantees the spill-free vector load/store never over-reads/writes the buffer.
- Built clean via `idea_build_project`.

## This session's edits (applied)
- Removed `count` param from `convolveNeonEdge4`; it now always writes a FULL 4-pixel block
  with direct spill-free `vst1q_u32(dst + y*width + x, result)`. Preserve-alpha via direct
  `vld1q_u32` + `vshrq_n_u32(_,24)` (alpha 0..255 value), so the shared `(ai<<24)` pack is correct.
- **BUG FOUND+FIXED**: preserve path originally set `ai = alphaSrc & 0xff000000` (packed), then
  `vshlq_n_u32(ai,24)` overflowed to 0 -> wrong alpha. Fixed with `vshrq_n_u32(alphaSrc,24)`.
- `applyNeonEdges4.processRange`: 4-wide runs -> `convolveNeonEdge4`; 1..3 tail -> scalar
  `convolveScalarPixel` (safe, no over-read/write).
- Wired `applyNeonEdges4` back into `applyNeonGenericAsmWithEdges` (replaces all four scalar
  edge loops: top/bottom full width + interior left/right). edgeMode hardcoded 0 (clamp).
- Build clean via `idea_build_project` (LSP `jni.h`/`jint` errors are known NDK-include false positives).

## Verification checklist (run in order)
1. On-device `ConvolveNativeParityTest` on `adbca122` -> **PASSED 18/18** (after alpha fix).
2. `./gradlew :filtering:runDeviceBenchmark -Pbenchmark.kernel=ConvolveMatrix -Pbenchmark.quick=true`
   -> **DONE** (note: quick mode still ran ALL kernels; took ~8 min).
   Result (NEON edge wired in):
   - ConvolveMatrix scalar 512x512 = 106.722ms | neon64 = 8.267ms -> 12.91x
   - ConvolveMatrix scalar 2048x2048 = 1649.907ms | neon64 = 102.082ms -> 16.16x
   Comparison vs earlier scalar-edge baseline (work log, different session/thermal):
   - neon64 512: 9.604ms (scalar-edge) -> 8.267ms (NEON-edge)  [FASTER]
   - neon64 2048: 125.220ms (scalar-edge) -> 102.082ms (NEON-edge) [FASTER]
   Speedup ratio dropped slightly (13.40->12.91 / 16.30->16.16) ONLY because the scalar
   backend also got faster in this session (128.66->106.72) — thermal/clock noise, not an
   edge regression. Absolute neon64 time IMPROVED.
3. Host `testDebugUnitTest` `ConvolveNativeParityTest` (x86) -> UP-TO-DATE (already passing;
   change is aarch64-gated, scalar/x86 path untouched).

## Conclusion (REVISED after proper controlled benchmark)
**NEON edge IS slower than scalar edge** — user was right; my earlier "improvement" was cross-session
noise (different quick-mode iteration counts / thermal). Proper single-session ConvolveMatrix-only
quick bench (correct `-Pandroid.testInstrumentationRunnerArguments.` args) on the NEON-edge build:
- scalar 512 = 129.079ms | neon64 512 = **10.985ms** (user scalar-edge baseline neon64 512 = 9.604ms)
- scalar 2048 = 1998.884ms | neon64 2048 = 126.796ms (user scalar-edge baseline neon64 2048 = 125.220ms)
=> neon64 512 ~14% SLOWER with NEON edge; 2048 ~equal. Edge path itself is to blame (same interior).

### Why NEON edge loses
- Edge bands are THIN (5x5: ~2px top/bottom + 2px left/right), so per-pixel setup dominates.
- `convolveNeonEdge4` does 4 folded `sampleCoordinateNeonEdge` calls + `loadEdgePixels`
  (4 conditional loads + assembled vector) + 4-lane init per 4-pixel block — overhead exceeds
  the scalar per-pixel work when there isn't much contiguous edge to amortize.
- Scalar edge wins. -> REVERT to scalar edges, delete the dead NEON edge helpers.

## User idea (applied): generic/specialized edge fn, fewer if-else
Instead of plain scalar edge, wrote `convolveScalarPixelClamp` (edgeMode=0 specialization):
- pins edgeMode to 0 -> the runtime edgeMode branch in sampleCoordinate (wrap/none) is gone
- clamp never yields -1 -> the "srcX<0||srcY<0 -> 0" test is gone
- only 2 tiny clamp comparisons remain
Bit-exact: on-device parity 18/18 PASS.

## RESULT (scalar edge + clamp spec, single-session controlled bench)
- neon64 512 = **9.140ms** (baseline scalar-edge 9.604; NEON-edge 10.985)
- neon64 2048 = **120.386ms** (baseline 125.220; NEON-edge 126.796)
=> clamp-specialized scalar edge beats BOTH the original scalar edge and the NEON edge.
   User's "generic edge, fewer if-else" idea works. KEEP this version. Commit.

## Files
- `filtering/src/main/cpp/convolve_matrix_neon.cpp`: rewrote cleanly — removed dead NEON edge
  helpers (sampleCoordinateNeonEdge, loadEdgePixels, accumulatePixel4, convolveNeonEdge4,
  applyNeonEdges4); scalar edge via new `convolveScalarPixelClamp` + clamp255Neon (floor(v+0.5)!
  round-half-up, matching clamp255). Interior ASM unchanged.
- Work log: `NEON_EDGE_OPT_WORKLOG.md` (this file).
