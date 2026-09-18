# SIMD Kernel Development & Debugging Guide

Purpose: transferable rules and known traps for **developing and debugging** the
hand-written SIMD kernels in `filtering/src/main/cpp/**/*.S`. Benchmark numbers
live in `BENCHMARKS.md`; this file is about what must *stay true* and what
already fails.

Reading priority: `ASSEMBLY_CONVENTIONS.md` + per-ISA implicit-clobber tables →
this guide → the specific kernel.

**Speed is never correctness.** A vector kernel passing parity is the only
condition for shipping it; benchmark claims are evidence only under the
conditions in §4.

---

## 1. Structural patterns — read these first when approaching a kernel

- **Decompose the footprint.** Morphology folds a square window in two passes
  (vertical → shared `spanBuf` scratch row, then horizontal) so overlapping
  windows re-read a single L1-resident scratch row instead of the source per
  pixel. Row kernel runs once per row; all bounds/strides/header math is hoisted
  out of per-pixel work; scratch is allocated once per call
  (`morphology.cpp:267`, `:585`).
- **Stay packed.** Little-endian ARGB bytes in memory are `B G R A`, so a load
  on a pixel boundary has a fixed channel→lane map (lane 0=B, 1=G, 2=R, 3=A) —
  `vminq_u8`/`pminub` is exactly the scalar per-channel min/max, no unpack.
  ARM: `uminv b0, v0.16b` + `dup`+`str` reduces 4 pixels in one instruction;
  x86 needs the `psrldq`+`pmaxub` shift-ladder
  (`morphology_x86_64_sse2.S:267-274`). Only go planar (`and`/`shl`/`ucvtf` per
  channel) when the math genuinely needs float/numeric per channel.
- **Fold domain conversions into constants** (`/255`, `*255`, `+0.5`, `1/invDx`)
  as pre-computed `dup`'d scalars so the loop body has no division — but never
  at the cost of FP op order or the rounding convention (see §2).
- **Variable-radius windows**: fully unrolled body, computed jump entry
  (`adr` + `br` into the middle), symmetric taps folded before the multiply.
  GaussianBlur's AOSP macros are the reference (`blur_aarch64_neon.S:82-234`).
- **Interleave 2/4 pixels per iteration** to amortize per-pixel setup, with
  independent accumulator chains to hide FP latency; keep a scalar tail for the
  leftover 1–3 pixels. Never write a partial vector.
- **Canonical pack pipeline** (copy this shape):
  ```
  float → int with scalar-matching rounding   // fadd +0.5 + cvttps2dq, or fcvtzs
  clamp to [0,255]                            // fmax/fmin, or sqxtun (neg→0) then umin #255
  shl R<<16, G<<8, A<<24 ; orr chain ; store
  ```
- **Mode selection via sign mask**, not branch (turbulence fabs: `bic` with a
  permanent `0x8000…` mask, set once at entry).

## 2. Rounding & parity — the #1 debugging checklist

- The Kotlin/scalar reference defines the contract. `value + 0.5f` before
  float→int is **mandatory** (`clamp255 = roundToInt().coerceIn(0,255)`).
- FP operation order is semantically significant: `/255.0f` ≠ `* (1/255.0f)` bitwise;
  a reordered `fmla`/`fmul` chain, or introducing FMA, changes low bits.
- `roundToInt()` is `floor(v + 0.5f)`, **not** nearest-even — a native fcvtn
  replacement diverges at half values.
- A one-ULP intermediate difference can cross the final `+0.5` pack threshold →
  verify bit-exactly after *every* scheduling/rounding change (forced parity
  corpus, see §4). A missing `+0.5f` shows up as ~half the pixels off by 1 LSB.

## 3. Known traps

- **Pure byte-LUT on 128-bit registers stays scalar.** The exact 256-entry
  per-byte map costs ≈ irreducible 16-way compare-and-select vs a cache-hot
  scalar loop; unrolling, register-resident tables, and decision-tree replace
  (variants A–E) all measured no gain. Only vectorize a LUT when real float
  math sits under the gather. AVX2 (8 YMM holding the table) is the exception
  (~1.4x); keep `applyForced` for characterization but never advertise a backend
  that loses to scalar.
- **Thin edges lose to scalar.** SIMD setup on 1–2px edge bands exceeds the work
  saved; specialize the scalar sampler instead (pin `edgeMode`, drop the
  wrap/none branch), keep SIMD for the interior rectangle, let the caller fill
  the 1–3px tail from the returned first-unprocessed `x`.
- **ABI traps** (recheck on the 32-bit target even when 64-bit is green):
  - ARM32 NEON has q0–q15 only (AArch64 q16+ may assemble but fails
    `armeabi-v7a`); callee-saved d8–d15 must be `vpush`'d/`vpop`'d; stack-arg
    offsets shift when the prologue grows.
  - Capture dimensions/flags before constant materialization clobbers argument
    registers; keep pointer and counter roles distinct (aliasing turns a tail
    bug into an out-of-bounds loop); keep live constants out of registers whose
    lanes pixel loads / row broadcasts overwrite.
  - Literal pools and dispatch tables must be PC-relative; a successful assembly
    is insufficient if the final library contains text relocations.
- **Byte-LUT / turbulence validation traps**:
  - A 256-entry table is not covered by a 64-byte AArch64 `vqtbl4q_u8` lookup —
    bounded 16-row scheme, test every index 0..255 on every channel.
  - Indexed lattice tables with mirrored tails: initialize the integer and
    gradient mirrors too, or an AVX2-only index range reads uninitialized tail
    data while host scalar/SSSE3 parity still passes.
  - Native seed normalization must match the Kotlin RNG for `seed <= 0`; parity
    cases with only positive seeds miss this.
  - Preserve alpha: don't route alpha through the sRGB LUT (it stays
    non-linear in linear-light mode).
- **Rounding is part of the algorithm**: don't fold a division into a
  reciprocal multiply or reorder ops "because the formula is unchanged" — run
  the complete forced parity corpus before benchmarking (§4).

## 4. Methodology — what evidence is valid

- **Parity is the gate.** Deterministic corpus (LCG `state*1664525+1013904223`,
  seed `0x9E3779B9`, height/alpha = `(state>>24)&0xFF`), byte-for-byte vs Kotlin
  by default with documented per-kernel tolerances (Gaussian-blur SIMD tails
  ±1 LSB, specular lighting `maxDelta = 1`),
  aborts on first mismatch. Compile/assemble/link success and faster benchmarks
  are **not** proof. Fix → full parity → next mismatch → fix.
- **Benchmark validity is part of the result**: compare backends in the same
  session, prefer medians, record thermal invalidation/batch CV/frequency. A
  cross-session absolute time change is not evidence (the "NEON-edge win" was
  thermal noise).
- **A NEON kernel at ~1x scalar speed is usually a broken/mis-optimized path**,
  not a genuine "no SIMD gain" case — investigate before accepting it.

## 5. Current validated implementation state — don't re-break, don't re-invent

- ConvolveMatrix scalar edge specialization is bit-exact and beats forced SIMD
  across thin borders; the vector kernel handles only the interior.
- The AArch64 Morphology kernel needs tail counters separate from row cursors
  and per-column accumulator reset (it passed the 108-case corpus 12.5x @ 512²,
  14.7x @ 2048² in one controlled device run).
- UnLinearize uses a bounded 16-row AArch64 lookup over the full byte domain;
  the SSSE3/AVX2 paths are byte-exact. Do not swap in a 64-entry lookup that
  silently truncates indices.

---

## 6. Case study: i386 AVX2 feTurbulence parity (2026-09-16) — differential probing

When a vector kernel produces wrong-but-structured output (not zeros, not a
crash), bisect it with **differential probes**: instrument the kernel to dump
intermediate vectors per pixel into `.bss` record buffers (written via a
PC-relative `calll get_pc_edx` / `leal (Sym-1b)(%edx)` block that touches no
live state), log them after the call returns, and diff each stage against a
host recomputation of the reference algorithm for the same inputs. Narrow
stage by stage — coordinates → lattice indices → tables → corner dots →
weights → accumulator → conversion → pack — until one stage diverges; the bug
is at or immediately before the first divergent stage. What this caught:

- **Permutation table with dupes** (`0(x4)`, missing 1,2,3): the identity
  `memcpy` ran inside `pushl %edx`, so its `1216(%esp)`-style stores landed
  4 bytes low. Rule: any esp-relative store between a push and its pop must
  be compensated by the push depth. Verify table validity (sort/uniqueness
  over 0..255) directly, don't assume the shuffle preserves it.
- **Frame collision (ebp-constants vs esp-spills)**: a 69 KB frame using both
  addressing modes can alias Hot constants with per-row/per-pixel scratch
  depending on stack alignment — here the channel structs clobbered the
  ratio source (`[0,+1]` became `[0,-1]`, negating every accumulator) and
  the pack shift counts (zeroed). Symptoms flip across runs/devices when the
  alignment changes, which looks like flakiness but is deterministic per
  stack layout. Rule: map every ebp-constant to its esp-alias
  (`ebp-X` = `esp+(ebp-esp-X)`); any alias inside a region the kernel writes
  per row/pixel must move (here: struct base 192→336, into dead byte-table
  space) or be loaded PC-relative (here: shifts from `LCPI0_25`).
- **Packed-pair constant loads**: `vaddpd`/`vmulpd` with a memory operand
  reads 16 bytes, so a single-double Hot constant drags in its neighbor
  (G lane got `+1.0` instead of `+0.5`; fractal R/G got wrong offset/scale/
  rounding the same way). Rule: packed FP mem-ops need a true 16-byte pair
  constant (e.g. `LCPI0_17` `[0.5,0.5]`); otherwise `vmovddup`-broadcast the
  single double first. Scalar (`vaddsd`/`vmulsd`) paths are immune.
- **Probe hygiene** (instrumentation must not perturb the kernel): guards
  must use provably-dead registers (a `movl 32(%esp), %eax` guard destroyed
  the live `bx1`, varying corner indices per pixel — only pixel 1 matched by
  coincidence); every clobbered vector/GPR must be saved or reloaded
  (`ymm0/ymm1` needed explicit restore); `calll` leaves esp unchanged (thunk
  ends in `ret`), so post-call esp offsets are unshifted but post-push ones
  are not; C++ log offsets/strides must match asm slot math exactly;
  uninitialized `char[]` log buffers with `%s` crash when empty.

## Quick checklist for touching a new filter

1. Read `ASSEMBLY_CONVENTIONS.md` + per-ISA clobber tables first.
2. Footprint separable / outputs overlap? → scratch span + row kernel.
3. Math per-channel & monotone? → stay packed; numerics → planar `ucvtf`.
4. Hoist reciprocals `/255` `+0.5` `*255` → dup'd scalars (keep op order).
5. Variable radius → unrolled body + computed jump entry.
6. Amortize setup → 2/4 px per iteration + scalar tail.
7. Pack: `+0.5` → round → clamp → shift/orr chain; preserve alpha.
8. Edges → specialized scalar, interior-only SIMD.
9. Pure LUT on 128-bit → scalar (negative result, see §3).
10. Validate every byte-LUT index 0..255, mirrored tails, `seed<=0` paths.
11. Verify ABI: arg regs captured before clobber, d8–d15, stack offsets, PC-rel.
12. Parity corpus → then single-session controlled bench.
