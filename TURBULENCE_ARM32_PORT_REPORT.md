# feTurbulence NEON64 → ARM32 Port — Feasibility Report

**Date:** 2026-09-05
**Subject:** Porting `filtering/src/main/cpp/turbulence/turbulence_noise_neon64.S`
(`turbulence64Asm`, 993 lines) to `armeabi-v7a` (ARMv7-A NEON / VFPv3).
**Sources:** direct analysis of the NEON64 kernel and its wiring, plus the
companion implementation report `tmp/turbulence_neon64_aarch32_implementacios_report.md`
(which this document subsumes its useful parts into; attribution where noted).

---

## 0. Verdict

**Feasible — both reports agree: "átültethető: igen", with one crucial qualifier:**

> **A 1:1 port of the AArch64 assembly is NOT the right strategy.** A separate
> AArch32 kernel is required, with a different register allocation and a
> different numeric scheduling.

The deeper strategic question is which *numerical domain* the ARM32 kernel runs
in, because that decides whether the product's **bit-exact parity gate** can be
kept:

| Strategy | Kernel shape | Bit-exact vs Kotlin reference? | Speed over ARM32 scalar (est.) | Fit for production today |
|---|---|---|---|---|
| **A — Scalar FP64 VFP** | scalar VFPv3 double port; keep 2-px interleave, branchless fabs | **Yes** (VFPv3 non-fused `vmla` mirrors `-ffp-contract=off` reference) | ~1.3–2× | **Drop-in**; parity tests pass unchanged |
| **B — FP32 NEON, 2 px** | geometry/indexing scalar, noise inner math `float32x4` NEON, pack NEON | **No** — FP32 vs FP64 lattice math diverges | high (several ×) | needs a relaxed (tolerance) parity gate |
| **C — Hybrid FP64/FP32** | FP64 geometry + FP32 NEON noise + controlled FP64 accumulation | Probably not bit-exact; bounded drift | medium–high | needs a relaxed parity gate + drift audit |

Device benchmark (`tmp/benchmarks_device_Turbulence.csv`) anchors the payoff
ceiling: the AArch64 kernel is **~20× scalar** (512²: 6.6 ms vs 132 ms;
2048²: 104 ms vs 2113 ms). On ARM32 the same 20× is unreachable (no FP64 SIMD,
half the SIMD regs); a realistic target is **"significant speedup over ARMv7
scalar"**, with the exact number depending on the strategy chosen.

**Recommendation:** proceed in stages — first a correctness-first scalar-FP64
(Strategy A) kernel to lock down ABI/layout/parity, then benchmark
Strategy B (the performance target) and make the parity-gate decision with
measured drift in hand. Effort: **~1–2 days** core work + device verification.

---

## 1. Current wiring (how the NEON64 kernel is built and dispatched)

```
turbulence_noise_neon64.S  →  turbulence64Asm(const Turbulence64AsmArgs*)   [AArch64 only]
turbulence_arm.cpp  #if __aarch64__  → applyNeon64(...)  (builds tables, fills args, calls asm)
turbulence.cpp      nativeBackendForAbi()  → SCALAR | NEON64 on __aarch64__, SCALAR otherwise
                    apply()                → x86 → AVX2/SSSE3/scalar, arm64 → applyNeon64,
                                             everything else (incl. __arm__) → applyScalar
                    applyForced()          → same split, keyed on forced SimdBackend flag
```

- **Build:** `CMakeLists.txt:36-38` adds `TURBULENCE_SOURCES` only for
  `ANDROID_ABI STREQUAL "arm64-v8a"`.
- **Backend plumbing already exists for NEON32:** `SIMD_BACKEND_NEON32` is
  defined in `cpu_dispatch.h` (`1<<5`) and in Kotlin `SimdBackend.kt`
  (`SIMD_NEON32`, name `"neon32"`); `BackendDiscovery.getBackendsFor` already
  iterates it. Only the C++ side fails to advertise or call it today.
- **Tables:** `turbulence_tables.h` `Arm64LatticeTables` (under `__aarch64__`)
  = `uint8 selector[514]` + `uint32 selector32[514]` + `double gradPackedX[514][4]`
  + `double gradPackedY[514][4]`. The builder is architecture-neutral and
  reusable as-is for ARM32.
- **Verification:** `TurbulenceNativeParityTest` (host JVM on x86_64, and
  androidTest on device) forces *every* advertised backend through the shared
  `TurbulenceValidationCorpus` and asserts **bit-exact** equality with the pure
  Kotlin reference. On ARM32 today this only ever runs `[SCALAR]`.

---

## 2. The decision that matters: FP64 bit-exact vs FP32 NEON throughput

This is the single most important implementation decision, and the AArch64
kernel gives no guidance: it gets both (FP64 products via 2-lane SIMD). ARMv7
forces a choice, because classic NEON has **no FP64 vector arithmetic** — FP64
is scalar VFP only, while FP32 is fully vectorizable on NEON.

### Strategy A — scalar FP64 VFP (correctness-first)

Numerically sensitive parts (geometry, dot products, lerp, octave
accumulation) stay in scalar VFP double. NEON only absorbs the integer/conversion
work (packing, saturate/clamp, store). This stays bit-close to the
scalar/reference numerics, and with VFPv3's non-fused `vmla` it is
**bit-exact** (§3.4). Cost: the expensive part — FP noise evaluation — never
gets SIMD, so this is a *baseline/fallback*, not the terminal kernel.

### Strategy B — FP32 NEON (throughput-first)

The whole noise inner math (4 gradient corners, dot/lerp, octave accumulation)
becomes `float32x4` NEON. This is the "first serious performance target" the
companion report proposes — but it is **not bit-exact**. Turbulence input
coordinates, interpolation, and octave accumulation are all numerically
sensitive; FP32 results drift deterministically from the FP64 reference, so
the current `assertArrayEquals` parity tests will fail. Adopting B is therefore
a **product decision**: relax the parity gate (tolerance-based comparison,
golden-diff tests, QuantEcho-style Δ) — not something the kernel can do on its
own.

### Between A and B: controlled-hybrid options (Strategy C)

- FP32 noise for the inner gradient interpolation, convert-and-accumulate into
  FP64 — reduces accumulated error but adds convert cost and still does not
  give bit-exact results;
- FP32 for everything except a FP64 final summation.

Both are legitimate "parity-tolerance" targets; pick by benchmark + measured
max drift over the corpus, not by assumption.

**Where the boundary sits in this codebase:** every other native filter here
holds bit-exact parity (that is the project's stated contract). So:
- If the ARM32 kernel must participate in `TurbulenceNativeParityTest`
  unchanged → **A only**.
- If a tolerance-based ARM32 gate is acceptable → B/C, benchmarked per §6.

---

## 3. Feasibility analysis

### 3.1 ABI / calling convention — favorable

`turbulence64Asm` takes a **single pointer argument**. On AAPCS32 the struct
pointer arrives in `r0`, and with only one argument the
softfp-vs-hardfloat question disappears — the C++ wrapper does all double
argument marshalling. Requirements:

- Preserve callee-saved GPRs `r4–r11` and VFP `d8–d15` (`vpush {d8-d15}`/`vpop`).
- `.syntax unified` + `.fpu neon` + `.align 2` (same prologue as the existing
  `convolve_neon32.S` / `arithmetic_composite_armv7a_neon.S`). The project already
  compiles armeabi-v7a with `-mfpu=neon` (`CMakeLists.txt:104-106`,
  `BLUR_NEEDS_NEON`) → VFPv3-D32, i.e. the full `d0–d31` file.
- **Struct offsets differ from AArch64** (4-byte pointers; `double` stays
  8-byte aligned). Do NOT reuse the AArch64 `.equ` values: write an AArch32
  offset table and guard it with explicit C++ `static_assert`s on a
  `Turbulence32AsmArgs` mirror struct (the companion report flags this too —
  "az argument structot érdemes explicit C++ `static_assert`-okkal rögzíteni").

### 3.2 Instruction mapping (AArch64 → ARMv7)

| AArch64 (used in kernel) | ARM32 replacement | Constraint / note |
|---|---|---|
| `fmul v2.2d, vA.2d, vB.d[0]` | `vmul.f64 d, d, d` (VFP) | 2-lane → 2 scalar VFP ops; **NEON has no double SIMD** |
| `fmla v2.2d, vA.2d, vB.d[0]` | `vmla.f64 d, d, d` (VFPv3) | non-fused (see §3.4) — *correct* choice for strategy A |
| `fsub/fadd`, fabs via `bic` w/ sign mask | `vsub/vadd.f64`, `vbic.f64` w/ sign mask | mask built from two GPR halves (`mov` + `vmov d, r, r`) + conditional `movne` |
| `fcvtms x, d` (floor) | see §3.3 | Armv8-only directed rounding |
| `scvtf` (int→double) | `vcvt.f64.s32 d, d` | |
| `fcvtzs w, d` (trunc) | VFP fp→s32 truncating convert | see §3.3 (confirm which mnemonic truncates on target) |
| `sqxtun / umin / shl / orr / zip1/2 / dup / umov / stp` | per-channel scalar VFP + GPR clamp/shift/`orr`, or ARM32 NEON int lane ops (`vqmovun`, `vmin.u16`) | strategy A: per-pixel scalar pack is simplest and correct; strategy B: does all of this natively in NEON |
| FP64 2-lane math (`v2.2d` ...) | — | strategy B replaces the whole block with `float32x4` NEON (different algorithm shape, not a mechanical mapping) |

### 3.3 Floor conversion (the one tricky detail for strategy A)

AArch64 `fcvtms` (round toward −∞, then to integer) has **no ARMv7 equivalent**:
the directed-rounding `VCVT{A,N,P,M}` forms are officially "Armv8 only".

Mitigation — exploit the kernel's own structure:

- All lattice coordinates are computed **biased by `+4096`** (`t = fx + 4096`,
  `t = fy + 4096`) exactly as in the scalar reference (`geometry()`:
  `tx = pxd + 4096.0`).
- For **`t ≥ 0`, `floor(t) == trunc(t)`**, and `r = t − floor(t) ∈ [0,1)` is
  recovered identically. Fast path: one VFP fp→s32 **truncating** convert → `b`,
  then `r = t − (double)b`.
- `t` stays non-negative whenever the noise coordinate stays above −4096, which
  holds for all real feTurbulence usage and the whole validation corpus. If the
  corner case (`userLeft`/`userTop` very negative × high frequency × many
  octaves) matters, add a guarded fallback: `i = round_nearest(t); d = t − i;
  if (d < 0) i -= 1; r = d < 0 ? d+1 : d` — or switch `FPSCR.RMode` around the
  converts (correct but serializing).
- Engineering note: the *plain vs `TR`* VFP fp→int mnemonics are documented
  inconsistently (ddi0406c decode vs ARMv7-M UG disagree about which is
  round-toward-zero vs FPSCR-mode). Confirm once per target with a tiny
  on-device cross-check (±1.9 → inspect); the parity test is the safety net.
  Strategy B sidesteps this entirely: ARMv7 NEON `vcvt` (fp→int) is defined as
  round-toward-zero.

### 3.4 Bit-exactness (strategy A) — achievable, and *safer* than AArch64

The reason to port in double is the project's hard parity guarantee
(`assertArrayEquals` vs. the Kotlin reference). Three facts make it work:

1. **`VMLA` (VFPv3) is NOT fused.** It rounds the product to destination
   precision first, then adds — exactly the semantics the C++ reference produces
   under `-ffp-contract=off` (`CMakeLists.txt:91`). The AArch64 kernel uses
   fused `FMLA` and passes the corpus empirically; the ARM32 port avoids the
   question by using `vmul.f64`+`vadd.f64`/`vmla.f64`. Do **not** reach for
   VFPv4 fused `vfma.f64` unless the whole corpus is re-verified.
2. **Ratio scaling is exact:** reference `n / ratio` (`ratio` a power of two)
   vs kernel `n * (0.5^k)` — identical in IEEE. No issue on any ISA.
3. **Pack equivalence:** reference `floor(v+0.5)` then clamp `[0,255]` vs
   kernel `trunc(v+0.5)` then saturate — identical post-clamp for reachable
   inputs, so the pack can use either VFP truncation or the GPR
   `movlt/movgt` clamp pattern from the AArch64 tail (`pack_single`).

**Constraint:** do not touch `FPSCR` (leave default round-nearest, no
flush-to-zero) so VFP arithmetic stays identical to the compiled scalar
reference.

For strategy B, the parity question is explicitly different: define the
tolerance, measure max channel error over the corpus, and encode it in the
test — do not silently drop the assertion.

### 3.5 Register file, live ranges, and the constant-vs-scratch trap

Both reports converge: the AArch64 kernel can afford long live ranges (32 SIMD
regs); the ARM32 kernel must **not** try to keep all gradient corners, both
pixels' accumulators, and all geometry live at once. The guiding principle is:

```
load → compute → consume → reuse        (short live ranges, immediate consume)
```

- **Strategy A allocation:** `d0–d7` the eight live double accumulators
  (P0/P1 × channels); `d8–d15` callee-saved geometry (`rx0, rx1, ry0, ry1, sx,
  sy` + spill slots); `d16–d31` scratch; GPRs: `r0` = args pointer (keep live,
  reload per-row constants from it), `r2` = pixel cursor, `r3/r4` = gradient
  bases, `r5` = `selector32`, `r6` = y, `r7` = octave count, `r10/r11` = stitch
  dims, `r12/r14` = perm indices. ~15 GPRs — fits, with several values on the
  stack frame exactly as the AArch64 kernel already does (`S_FX1`, `S_BY0`, ...).
- **Strategy B allocation (from the companion report, 2-px FP32 sketch):**
  `q0/q1` P0 accumulators ch0-1/ch2-3, `q2/q3` P1, `q4–q7` gradient X/Y
  temporaries, `q8/q9` interpolation temporaries, `q10/q11` geometry/lerp
  constants, `q12/q13` packing temporaries, `q14/q15` reload window. This is a
  scheduling sketch, not a finished allocation — the principle is that a
  well-optimized 2-px kernel beats a spill-heavy 4-px kernel.
- **Avoid the mechanical `v0→q0, v1→q1, …` mapping** and, for strategy A, avoid
  assuming AArch64's `.2d` pairing survives — it does not.

**Pitfall taken from the AArch64 kernel itself (worth encoding in the ARM32
one):** *do not keep a constant in a SIMD register that the hot octave loop
uses as scalar scratch.* The NEON64 file's `v30`/`d30` alias is exactly this —
the pack ceiling `v30.4s = 255` has to be re-established at the top of every
`pack_pixel_pair` because `d30` (its low 64 bits) is reused as a geometry
scratch double inside the loop. In the ARM32 kernel, keep constant registers
and scratch registers strictly separate, or reload constants at the start of
each pack block.

### 3.6 Data tables and gradient layout

- **Strategy A:** the AArch64 `gradPackedX/Y[S_TABLE_SIZE][4]` (32 B/entry)
  layout is reused byte-for-byte; `initArm64Tables` is architecture-neutral and
  can back an `initArm32Tables` alias. Permutation loads
  (`ldr r, [r5, r12, lsl #2]`) are legal in AArch32.
- **Strategy B:** reconsider the layout. The AArch64 entry-major shape
  (`double x[4], y[4]` per lattice entry = 64 B) exists to feed 2-lane FP64; for
  an FP32 kernel the natural shape is `struct Gradient4f { float x[4], y[4]; }`
  or even a 2-channel `Gradient2f`, and a **channel-major** alternative
  (`Gradient{float x,y} gradients[4][S_TABLE_SIZE]`) is worth benchmarking.
  The companion report's rule: *optimize the AArch32 layout to the actual load
  pattern; do not conserve the AArch64 struct.* Decision deferred to a layout
  benchmark, and layout / block-size / precision should be benchmarked as
  **separate variables**, not changed together.
- Data flow for the 2-px FP32 kernel: per channel-pair, load only the two
  gradients needed per corner and let them die immediately (corner00 → corner10
  → lerp → corner01 → corner11 → lerp), shrinking the live set and improving L1
  locality.

### 3.7 Stitching and per-octave state

Update stitch `wrapX/wrapY` and the period doubling **once per octave, outside
the pixel loop**, not per pixel:

```
octave setup  →  shared octave state
pixel pair loop → per-pixel geometry only
```

The AArch64 kernel already does this; preserve the structure. Geometry
(floor, +4096, b-coords, rx/ry, selector, sx/sy) doesn't need SIMD — keep it
scalar/ARM-integer and spend the register budget on gradient math.

---

## 4. Work required (independent of strategy)

1. **`turbulence/turbulence_noise_neon32.S`** (new, ~700–1100 lines): the
   strategy-A scalar-VFP port (or the strategy-B NEON kernel), keeping the
   two-pixel interleave, branchless fabs, per-row constant recomputation from
   `r0`, odd-width tail, and scalar pack.
2. **`turbulence/turbulence_asm32.h`** (new): `Turbulence32AsmArgs` +
   `static_assert` offsets + `extern "C" void turbulence32Asm(...)`.
3. **`turbulence/turbulence_arm.cpp` / `.h`**: `#if defined(__arm__)`
   `applyNeon32(...)` reusing the table builder; declare in header.
4. **`turbulence/turbulence.cpp`**:
   - `nativeBackendForAbi()`: `#elif defined(__arm__) backends |= SIMD_BACKEND_NEON32;`
   - `apply()` and `applyForced()`: add `#elif defined(__arm__)` branches
     calling `applyNeon32` (respecting the forced flag, same `assert(false)`
     guard as arm64).
5. **`CMakeLists.txt`**:
   `if(ANDROID_ABI STREQUAL "armeabi-v7a") set(TURBULENCE_SOURCES .../turbulence_noise_neon32.S)`.
   `-mfpu=neon` already arrives via `BLUR_NEEDS_NEON`; `.fpu neon` in the file
   is authoritative for the integrated assembler.
6. **Kotlin/test:** nothing to change structurally — `SIMD_NEON32` already
   exists (`SimdBackend.kt`), `BackendDiscovery` iterates it, both parity tests
   force every advertised backend. Once `nativeBackend()` advertises NEON32 the
   corpus runs the new kernel automatically. Keep the AArch64 and AArch32
   kernels in **separate .S files with separate wrappers** on top of the same
   C++ reference (the companion report's §15 — keeps parity tests simple).

---

## 5. Risks and pitfalls

| Risk | Severity | Mitigation |
|---|---|---|
| Bit-exactness drift (VFP rounding, strategy A) | high | Non-fused `vmul/vadd/vmla.f64`; never `vfma`; never touch FPSCR; device parity run over full corpus |
| FP32 drift / parity gate (strategy B) | high (process) | Decide tolerance up-front; encode max-drift assertion in the ARM32-only test; do not silently drop the bit-exact check |
| Wrong floor semantics (`VCVT` vs `VCVTR`) | high (A only) | On-device conversion cross-check; `+4096` bias keeps `t ≥ 0` so trunc == floor |
| Constant in a hot-loop scratch register (the `d30/v30` trap) | medium | Separate constant regs from scratch regs, or reload at pack-block entry |
| Register pressure / spills eating the speed-up | medium | Short live ranges everywhere; keep `sums` permanently in `d0–d7` (A) or `q0–q3` (B); load-compute-consume-reuse |
| Over-eager 4-px block or premature layout change | medium | Benchmark layout / block-size / precision as separate variables; a clean 2-px kernel beats a spilling 4-px kernel |
| Stale AArch64 offsets copied into the 32-bit file | medium | Guard with `static_assert`s on the AArch32 layout |
| `armeabi-v7a` is a shrinking market | low (product) | 32-bit-only devices, or `-PfilterAbis=armeabi-v7a` builds on arm64 hw; correctness already covered today by the scalar path |

---

## 6. Recommended implementation plan

The companion report's phasing is sound and adapts to either strategy. Change
**one variable at a time**; benchmark each phase.

```
Phase 0 — wiring               build the plumbing (§4) with applyNeon32 = applyScalar alias
Phase 1 — correctness kernel   1 pixel, scalar FP64 (strategy A shape)
                               proves: ABI, args layout, selector, gradient addressing,
                               stitching, octave state, pack; parity MUST pass bit-exact
Phase 2 — 2-pixel SIMD noise   either (A) 2-px scalar-FP64 interleave [drop-in], or
                               (B) 2-px FP32 NEON noise + scalar geometry [perf target]
                               → device parity + bench
Phase 3 — channel blocking     ch0-1 then ch2-3 per pixel pair (smaller live set,
                               fewer spills, better L1) → re-bench
Phase 4 — layout benchmark     entry-major vs channel-major gradient layout
Phase 5 — 4-pixel experiment   ONLY if q0–q15 pressure allows (likely not on ARM32)
```

Verification for every phase:
- Instrumented `TurbulenceNativeParityTest` with
  `-PfilterAbis=armeabi-v7a` (builds a 32-bit-only APK, exercisable on arm64
  devices) — forced `SIMD_BACKEND_NEON32` **and** SCALAR.
- `runDeviceBenchmark` (`-Pbenchmark.kernel=Turbulence`) for the speed gate.
- Target numbers: Phase 1 must be ≈ scalar (correctness only); Phase 2 (A)
  should be **≥ 1.3× scalar**; Phase 2 (B) the ceiling is much higher — measure,
  then decide the parity-tolerance strategy with the measured max drift.

---

## 7. Performance expectations

Device data: NEON64 = **~20× scalar** (512² 6.6 vs 132 ms; 2048² 104 vs 2113 ms).
ARM32 realistically:

- **Strategy A (scalar FP64 VFP):** ~1.3–2× over ARMv7 `applyScalar`, from
  two-pixel Y-geometry sharing, branchless fabs, and a tighter pack — not from
  data parallelism (ARMv7 cannot vectorize the doubles).
- **Strategy B (FP32 NEON, 2-px):** several × over scalar — the real
  performance play — but bundles the parity-gate decision.
- **Never expect `ARM32 ≈ AArch64`.** The gap is architectural (no FP64 SIMD,
  half the SIMD register file), not a porting defect.

---

## 8. Decision matrix (adapted from the companion report)

| Approach | Implementability | Correctness | Expected perf | Recommendation |
|---|---|---|---|---|
| AArch64 1:1 asm port | ❌ | — | — | **No** |
| Scalar FP64 ARM32 (A) | ✅ | ✅ bit-exact | low | **Baseline / drop-in** |
| FP32 NEON 2 px (B) | ✅ | needs tolerance gate | high | **First serious perf target** |
| FP32 NEON 4 px | ✅ | needs tolerance gate | theoretically high | later experiment only |
| Hybrid FP64/FP32 (C) | ✅ | likely good, bounded drift | medium–high | second target |

## 9. Bottom line

**Portable: yes.** **Direct assembly port: no — write a separate AArch32
kernel with its own register allocation.** For the bit-exact parity contract
that the rest of this codebase holds, ship strategy A (scalar FP64 VFP) as the
production kernel; if the parity gate can be relaxed for ARM32, strategy B
(2-pixel FP32 NEON with channel blocking and short live ranges) is the
performance target — decide B-vs-A with measured drift and measured speedup in
hand, not by assumption. The biggest risk is not the algorithm rewrite but the
**precision/correctness vs SIMD throughput** trade-off.