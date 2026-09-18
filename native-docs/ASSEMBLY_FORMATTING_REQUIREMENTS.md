# Assembly Formatting Requirements & Style Guide

This guide establishes the mandatory formatting, structure, and documentation standards for all hand-written SIMD assembly kernel sources (`*.S`) across the project. All assembly source files must conform to these layout and architectural style conventions to ensure maintainability, uniform readability, and clean visual structure.

---

## 1. Copyright and License Header

Every assembly file must begin with exactly the following Apache 2.0 license header. This header must be the absolute first content in the file, preceding any `#include` directives or code definitions.

```c
/*
 * Copyright 2026 András Oravecz <info@oandras.hu>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
```

> [!NOTE]
> Files carrying an upstream **Android Open Source Project copyright header** (such as legacy/borrowed AOSP files `blur_aarch64_neon.S` and `blur_armv7a_neon.S`) preserve their original upstream headers and file identity, and are exempt from reformatting or relicensing.

---

## 2. Prohibited Compiler Artifacts and Metadata

Assembly sources must contain only clean, hand-maintained code structure. Toolchain-generated metadata, environment-specific artifacts, and compiler remnants are prohibited:

*   **No `IDENT` or `.ident` Directives:** `IDENT(...)` and `.ident` statements are completely disallowed.
*   **No Build/Environment Metadata:** Sources must be free of compiler version strings, local build paths, generation timestamps, and compiler-injected `.file` name directives (unless explicitly documented as required for a specific debug configuration).

---

## 3. Indentation and Alignment

A single, uniform alignment convention applies across the entire file, covering both function bodies and global scopes.

*   **Instructions:** All instruction lines are indented by exactly one level (**4 spaces**).
*   **Labels:** All label definitions reside at **column 0** (no indentation).
*   **Mnemonic Padding:** Instruction mnemonics are padded so that all operands align perfectly in a single column.
    *   The standard padding width equals the longest instruction mnemonic in the file plus 1 (typically a standard width of `8` spaces; exceptionally long mnemonics maintain a single space).
*   **Operand Spacing:** Multiple operands are separated by a comma and a single trailing space (`, `).
*   **Macro and Structural Invocations:** Preprocessor macros and structural pseudo-ops (e.g., `CFI_*`, `RODATA`, `TEXT`, `HIDE_SYM`) use a single space after the macro name, without mnemonic padding. Long macro invocations remain single-line.

Example of correct structural alignment:
```asm
    mov     x0, x1
    add     x2, x2, x3
    ldr     q0, [x1], #16
```

---

## 4. Labels and Functions

*   **Placement:** Global and function labels reside at column 0. Local labels (e.g., `.Lloop:`, `.Ltail:`) are kept unindented and visually distinct from the indented instruction stream.
*   **Spacing:** Function labels and major block labels are preceded by exactly one blank line to visually separate logical control blocks.
*   **Invariance:** Label names, branch targets, and control flows are preserved exactly to prevent unintended logic alterations.

---

## 5. Assembler Directives

*   **Placement:** Core symbol and section directives (`.text`, `.globl`, `.type`, `.size`, etc.) reside at column 0 to distinguish structural declarations from executable instructions.
*   **CFI Directives:** Standard `.cfi_*` frame unwinding directives are maintained in their exact structural locations to preserve debugging and stack tracing.
*   **Completeness:** All directives needed for architecture/ISA selection, correct symbol visibility, section alignment, and target ABI constraints are present.

---

## 6. Whitespace, Layout, and Line Endings

*   **Line Endings:** All files use Unix `LF` line endings exclusively.
*   **Trailing Whitespace:** Lines must be free of trailing spaces or tabs.
*   **Blank Lines:** Excessive or multiple consecutive blank lines are collapsed. Single blank lines are used purposefully to mark boundaries between logical stages.
*   **File End:** Every file terminates with exactly one newline.

---

## 7. Comments and Semantic References

Comments serve to clarify vector algorithms by mapping the SIMD implementation directly to its high-level algorithmic meaning.

### Semantic Reference Baseline
Comments detailing the operation behavior are verified against the corresponding scalar reference implementations:
1.  **Primary baseline:** `filtering/src/main/kotlin/hu/oandras/ksvg/filtering/KotlinKernels.kt` (the pure-Kotlin per-pixel reference).
2.  **Secondary baseline:** The C++ scalar fallback implementation found in `filtering/src/main/cpp/<filter>/<filter>.cpp`.

### Commenting Conventions
*   **Comment Characters by ISA Family:**
    *   **x86_64** and **ARM (AArch64/ARMv7):** Use `//` followed by a single space (`// comment`).
    *   **i386:** Use `#` followed by a single space (`# comment`).
*   **Logical Boundary Commenting:** Individual instructions are not commented line-by-line. Instead, comments are grouped at logical stage boundaries (e.g., input loading, unpacking/deinterleaving, channel rearrangement, main arithmetic processing, clamping/saturation, alpha handling, and output storage).
*   **SIMD Transformations:** Non-obvious vector implementations—such as parallel pixel execution, channel packing permutations, specialized lookup tables, reciprocal/rsqrt approximations, or horizontal reductions—include high-level scalar expressions to clarify the transformation.
*   **No Compiler Comment Artifacts:** Sources must be free of compiler-generated comment structures (e.g., `##`, `-- Begin/End function`, `%bb.N`, `N-byte Reload/Spill`, or inline hex echoes).

Example of correct logical boundary commenting:
```asm
    // Scalar equivalent:
    // result = src * diffuse + ambient
    fmul    v0.4s, v0.4s, v1.4s
    fadd    v0.4s, v0.4s, v2.4s
```

---

## 8. Register Documentation

When register roles remain stable across a substantial block of logic, their algorithmic meanings are documented at the entry point of the function or block:

```asm
    // v0-v3: RGBA input pixels
    // v4:    diffuse lighting factor
    // v5:    ambient lighting term
```

Register maps are kept concise and focused, avoiding redundant layouts that provide no diagnostic value.

---

## 9. Function Header Descriptor Comments

Every public or main exported assembly function must be preceded by a formal C-style block comment descriptor specifying its corresponding C/C++ function prototype signature and the exact architectural register assignment mapping for inputs/parameters according to the target ABI.

*   **Spacing:** The block comment descriptor is preceded by at least one blank line to visually separate it from the preceding code.

Example format for an AArch64 function:
```c
/*
 * void ksvgDisplacementMapApplyNeon64(
 *     const int32_t* src, const int32_t* map, int32_t* dst,
 *     int width, int height, float scale, int xChannel, int yChannel);
 *
 * AArch64 ABI:
 *   x0 = src, x1 = map, x2 = dst
 *   w3 = width, w4 = height
 *   s0 = scale
 *   w5 = xChannel, w6 = yChannel
 */
```

