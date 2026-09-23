# SIMD Kernel Development Ground Truth

Invariants + reverse-engineered lessons for hand-written SIMD kernels in `filtering/src/main/cpp/**/*.S`.

Priority: **ABI → register liveness → PIC → FP op order → rounding → lighting window/center-height → tail → parity → runtime validation**

## Typical mistakes — check these first when hunting an assembly bug

1. **`powf` / libc calls**: which regs does the call clobber on this ISA (per-ISA tables in `native-docs/` + `## 2`, `## 5`)? Live caller-saved regs spilled, return consumed, flags not relied on. i386: keep GOT base live across the call.
2. **Caller args**: re-derive layout from call site + dispatcher + prologue/frame size (`## 1`). Wrong slot = garbage/SIGSEGV. i386 linear kernels take **6** args only.
3. **Register clobbers**: look up every value survival in the matching per-ISA `.md` table. Watch `MUL`/`DIV`/`IDIV`→`EDX`, `CPUID`→`EBX`, string ops, `CALL`/`RET`→`RSP`/flags, AArch64 `BL`→`X30`, `PACIASP`, ARMv7 `d8–d15`.
4. **Rounding**: compare with the Kotlin reference. Missing `+0.5f` (`## 6`) or altered FP op order (`## 7`) = ~half the pixels off by 1 LSB. `0.5f` ≠ `0.5`; `* (1/255.0f)` ≠ `/255.0f`.
5. **VEX FMA has no broadcast**: `vfmadd213ps m32, %ymm, %ymm` reads a full `m256`, not a scalar (broadcast is EVEX-only). Horner-style coefficient steps need an explicit `vbroadcastss` + register-form FMA (see `POW8_FMA_STEP`); lane 0 stays accidentally correct, hiding the bug from narrow tests.
6. **Bare `$N` immediates in parameter-less macros (Apple-LLVM)**: inside a
parameter-less `.macro` body LLVM replaces `$N` (digit N followed by a
non-digit: `$1`, `$23`, `$255`, `$0xff` all match) with the Nth macro
argument — empty, so the operand silently degrades to a memory reference
(`andl $255,%ecx` assembles as `andl [55],%ecx`, `shrl $23` may even go
EVEX and SIGILL pre-AVX512). Decimal literals do NOT help. Named-parameter
macros are immune — so parameter-less macros needing `$` immediates take a
dummy parameter (see `POW1_X64 dummy`); bare invocation still works.
7. **AArch64 logical-op forms (LLVM)**: register `orr`/`and`/`bic` only accept byte arrangements (`.8b`/`.16b`) — `orr v4.4s, v4.4s, v5.4s` is rejected; use `.16b`. Shifted `orr`-immediate (`orr v.4s, v.4s, #imm, lsl #N`) is likewise rejected; build masks with `movi` + register `orr`. `ldp q,q` offsets must be multiples of 16 — pad literal tables accordingly.

---

## 1. ABI / argument layout — hard contract

ISA-specific; never copy across ISAs.

| ISA | srcT | srcM | srcB | dst | count | params | l2s |
|---|---|---|---|---|---|---|---|
| x86-64 SysV | `rdi` | `rsi` | `rdx` | `rcx` | `r8` | `r9` | register |
| i386 cdecl | `frame+20(%esp)` | `+24` | `+28` | `+32` | `+36` | `+40` | **global / not passed** |
| AArch64 AAPCS64 | `x0` | `x1` | `x2` | `x3` | `x4` | `x5` | register |
| ARMv7 AAPCS32 | `r0` | `r1` | `r2` | `r3` | `[sp,#0]` | `[sp,#4]` | register |

- **i386**: offsets depend on frame size. Standard prologue `push ebp/ebx/edi/esi; sub $N` → first arg at `(N+20)(%esp)`, subsequent at `+4`. Never port x86-64 offsets to i386; always derive from call site + dispatcher + prologue.
- **i386 Linear kernels**: 6 args, no `l2s` slot; LUT `ksvg_linear_to_srgb_lut` via `@GOT(%ebx)`. Reading a 7th arg = stack garbage → SIGSEGV.

---

## 2. Register budget / liveness

Budget:
- x86-64: 16 XMM/YMM · i386: **8** (`xmm0–7` / `ymm0–7`) · AArch64: `v0–v7`, `v16–v31` caller-saved, `d8–d15` (`v8–v15` low halves) **callee-saved** (this line previously misstated v0–31 as caller-saved; the convolve NEON kernel clobbered d14/d15 unspilled because of it — audit R2) · ARMv7: 16 q-regs, `d8–d15` (`q4–q7`) **callee-saved**

Liveness rule: a register is dead only if dead across the **entire remaining control flow** — straight-line, LUT/fallback paths, epilogues, and every later branch.

---

## 3. PIC — mandatory shared-library invariant

- **x86-64**: RIP-relative constants only (e.g. `addps .Lhalf(%rip), %xmm1`); no absolute addressing.
- **i386**: GOT base in `%ebx` — `calll .L0$pb` / `popl %ebx` / `addl $_GLOBAL_OFFSET_TABLE_+(.Ltmp0-.L0$pb), %ebx`. Locals `@GOTOFF(%ebx)`, globals `@GOT(%ebx)`. `%ebx` must be live while such code is reachable.
- **AArch64**: PC-relative (`adrp/add`, literal pools); avoid absolute table/LUT addressing that introduces text relocations.

---

## 4. Symbol / build convention

- Every `.S`: `#include "asm_macros.S"` (wraps `SYM`/`TYPE`/`SIZE`/`CFI_*`/`CALL`/sections). Don't duplicate wrappers in individual files.
- Kernel entry-name must **exactly match** the C/C++ declaration + dispatch symbol. Mismatch → link error (x86), runtime crash (ARM).

---

## 5. Calls/jumps to exported ELF symbols

```asm
jmp symbol@PLT
call symbol@PLT
```

Plain `jmp symbol` can emit an invalid relocation in a shared lib. Use `CALL()` for calls; forwarding `jmp` stubs must use the proper PLT form. Mach-O: platform wrappers from `asm_macros.S`.

---

## 6. sRGB rounding invariant — every channel

Reference: `clamp255(value) = value.roundToInt().coerceIn(0, 255)` → **`value + 0.5f` before float→int**.

```asm
addps .Lhalf(%rip), %xmm... ; cvttps2dq ...    ; x86
fmov v27.4s, #0.5                              ; AArch64 example
```

i386 loads `0.5f` from `.rodata` via `@GOTOFF(%ebx)`. Missing `+0.5f` → ~half the affected pixels off by 1 LSB. Not optional.

---

## 7. Exact FP operation order

Order is semantically significant: `/255.0f` ≠ `* (1/255.0f)` bitwise; FMA/fused can change output bytes.

**Keep assembly FP op order compatible with the reference; no "mathematically equivalent" reassociation.**

---

## 8. Lighting window semantics

Output pixel `x` reads a 3-tap window `src+0/+4/+8`; pointers `srcT/srcM/srcB → x-1`, so `src[+0]=x-1`, `src[+1]=x`, `src[+2]=x+1`.

**Center height** (point/spot Z-distance) = `srcM[+1]`, the window-center pixel. **Not `srcT`** (top Sobel row).

---

## 9. Lighting math invariants

- `h = (alpha >> 24) * ss`
- Distant gradient: `dzdx = (sumT_r - sumT_l)` etc.; `ss` folded into gradient scale
- `dxRel = (rT - lT) + 2*(rM - lM) + (rB - lB)`
- Frontal: `dot = max(0, n·l)`; negative dot → black, no specular
- `clamp(k * dot) → [0,1]`

Reference op order takes priority for parity.

---

## 10. Output packing

`(R << 16) | (G << 8) | B | 0xFF000000` — alpha from constant or LUT. Channels stay **linear** until the final stage; only `*Linear` kernels use the linear→sRGB LUT.

---

## 11. Vector loop / tail

Must work for `count % vector_width != 0`: vector main loop → tail → scalar remainder.
- AArch64: 8px main → 4-lane tail → scalar remainder
- x86: full-vector main + epilogue + scalar tail / branch-specialized fallback

1–3 px remainder: scalar is usually faster than masked vectors.

---

## 12. Resource discipline

No mutable global/static write buffers; scratch caller-owned; state per-call or in caller-provided scratch. ARMv7: preserve `d8–d15` if used.

---

## 13. Parity gate — correctness gate

Every kernel change must pass the matching `*NativeParityTest` (deterministic corpus, byte-for-byte vs Kotlin/scalar reference by default, with documented per-kernel tolerances — e.g. Gaussian-blur SIMD tails ±1 LSB, specular lighting `maxDelta = 1`). Compile/assemble/link success and benchmarks are **not** correctness proof. **Parity is the gate.**

---

## 14. First-mismatch rule

Parity aborts on the first mismatch → loop: `fix → full parity run → fix → full parity run`. Fixing one bug may reveal masked mismatches; the current index is not the whole bug set.

---

## 15. i386 PIC / runtime validation

Assembling ≠ correct PIC. Check: GOT/GOTOFF addressing, GOT-base + dest-pointer liveness, stack arg offsets, PLT calls/jumps, shared-lib relocations.

Validate: `assemble → build .so → link → target runtime → NativeParityTest`. For text-reloc-sensitive changes inspect with `llvm-readelf` (`TEXTREL`, `R_386_32`).

---

## 16. NDK vs host-native build

Android: NDK/CMake → the real Android native library. Host: `buildHostNativeLib` → host-JVM parity tests only. Don't treat host/IDE errors as Android problems.

---

## 17. Spill / register reuse (i386)

High vector-register pressure. Out of spill room, broadcast a loop constant into a **provably dead** vector reg (`vbroadcastss .LCPI...@GOTOFF(%ebx), %ymm3`); dead = across the entire downstream flow. Reuse may beat restructuring the stack frame.

---

## 18. Deterministic parity corpus

LCG `state = state * 1664525 + 1013904223`, seed `0x9E3779B9`; pixel height/alpha from `(state >> 24) & 0xFF`. Never reseed/normalize/alter the corpus to force a pass — determinism is part of the parity mechanism.

---

# Development Checklist

Before modifying assembly:

- [ ] call site + ABI verified
- [ ] ISA-specific args re-derived; i386 frame offsets recalculated (linear: 6 args)
- [ ] register budget checked
- [ ] reused regs proven dead across downstream control flow
- [ ] PIC verified; i386 `%ebx` preserved as GOT base
- [ ] exported ELF calls/jumps use PLT
- [ ] lighting center height uses `srcM[+1]`
- [ ] FP op order reference-compatible; `+0.5f` preserved
- [ ] output packing unchanged
- [ ] vector tail handled
- [ ] ARMv7 callee-saved NEON preserved where relevant
- [ ] no mutable global scratch

After modifying assembly:

- [ ] target shared library built + linked
- [ ] relocations checked where relevant
- [ ] target runtime executed
- [ ] full `*NativeParityTest` passed
- [ ] newly exposed mismatches fixed + parity rerun
- [ ] benchmark only after clean parity
- [ ] perf improvement accepted only with parity success
