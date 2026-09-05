# feTurbulence ARM64 Kernel — Optimization Plan

**Report:** `TURBULENCE_ARM64_OPT_REPORT.md`
**Kernel:** `filtering/src/main/cpp/turbulence/turbulence_noise_neon64.S`
**Baseline:** neon64 4.534ms @ 512² / 72.342ms @ 2048² (17.9×/20.0× vs scalar)

## Principles
1. **One step at a time.** Parity (22 tests) + bench after every step.
2. **Bit-exact:** same FP op order as the Kotlin/C++ reference. AArch64 has no
   fma-via-fp-contract issue because the reference builds with `-ffp-contract=off`
   and the asm uses `fmul`+`fmla` explicitly.
3. **Incremental:** each step is small, self-contained, and verified before the next.

---

## Step 1 — register-indexed gradient loads  (~16 adds/pixel saved)

AArch64 `ldr q` register-offset addressing **only allows `lsl #0` / `lsl #4`**
(no `lsl #5`, no `[xN,xM,lsl#N,#imm]` form — verified by test-assembly).
So the index is pre-doubled once after each permutation (`lsl x12..x15,#1`),
then `ldr q16,[x3,x12,lsl#4]` reads row `2*idx` = stride 32, replacing the
`add x16,x3,x12,lsl#5; ldr q16,[x16]` pair. Channel-pair 2/3 uses
`add x16,x3,#16` once per block then `ldr q16,[x16,x12,lsl#4]` (x16 is also
clobbered by P1's geometry, so the +16 base is re-added per ch2/3 block).

The doubled indices are short-lived (permutation → gradient loads); P1 and
the tail recompute x12–x15 fresh from their own geometry, so nothing leaks.

Apply to all eight gradient blocks (P0/P1/tail × ch0/1 + ch2/3).

**Result (verified 2026-09-05):** parity 22/22 OK. Bench on `adbca122`
(3 runs, ±3% device noise): neon64 512² 4.526–4.642ms, 2048² 71.688–75.753ms
vs baseline 4.534/72.342. Net change **within noise** — the kernel is
latency-bound on the gradient loads themselves, so removing the address `add`
does not measurably help. Kept: strictly fewer instructions, no regression,
simpler address path.

## Step 2 — materialize pack constants once at entry (~8 instr/pixel-pair saved)

Replace the per-pixel-pair `cbz w1`+literal loads+`dup` chain with:
- at entry (after the fractal test that sets the v7 sign mask): build
  `v24=[scale,scale], v25=[offset,scale], v26=[0.5,0.5]` once into permanent
  registers using the same const loads that already exist.

**Implementation note:** the octave loops clobber every SIMD register
(v24–v26 hold fx0/fy/curtlx0 there, v0–v23 are use), so the constants cannot
live in registers across octaves. Instead the three vectors are built once at
entry and stored to new 16-byte frame slots (S_PACK_SCALE/OFFSET/HALF,
S_SIZE 144→192); each pack path reloads them with straight qword loads.
Also removes the branch in `pack_single` the same way.

**Result (verified 2026-09-05):** parity 22/22 OK. Median across 3 bench
runs (`adbca122`): 512² 4.47ms (vs 4.64 Step 1), 2048² 71.8ms (vs 73.9 Step 1).
Small consistent gain, no regression; device noise today is ±10% so the
absolute numbers carry wide error bars.

## Step 3 — dead freqY/freqX reload removal (G2)

`row_loop` loads `A_FREQ_Y` twice for `py0` (line 143) and `curtly` (line 151)
with no clobber between — the second is dead. Cache the scalar values (freqX,
freqY, invScaleX, invScaleY) once before the row loop into callee-saved d-regs
or into the stack frame, removing ~6 redundant ldr/row.

Apply also to the `fxStep` and `curtlx` computation which has similar patterns
where `d21` holds a value across an `fdiv`+`fmul` block.

Expected: parity OK, very small bench improvement (few instr/row).

## Step 4 — bitwise weight step (1 instr/octave saved)

Replace the per-octave `ldr d29,const_half; fmul d28,d28,d29` with an integer
subtract from a permanent `2^52` double held in a spare dN. The weight is always
a normal power of two, so decrementing the biased exponent by one halves it
bit-exactly (proven in 32-bit parity, applicable identically).

One register live across the octave loop. On AArch64 the register file is wide
enough to spare one more. Verify register pressure.

Expected: parity OK, ~1% improvement at 2048².

## Step 5 — madd row address (1 instr/row saved)

Replace `mul w17,w6,w17; add w17,w17,w18` with `madd w17,w6,w17,w18`.
Trivial 1-instruction-per-row savings. Parity trivially identical.

Expected: no measurable bench impact but code completeness.
