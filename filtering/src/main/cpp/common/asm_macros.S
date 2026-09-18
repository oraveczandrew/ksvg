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

#if defined(__APPLE__)
#define SYM(x) _##x
#define TYPE(x,y)
#define SIZE(x)
#else
#define SYM(x) x
#define TYPE(x,y) .type x,y
#define SIZE(x) .size x,.-x
#endif

// CFI unwind directives. The macOS host assembler rejects the CFA epilogue
// sequence emitted by the compiler for these kernels ("invalid CFI advance_loc
// expression"), so the debug info is stripped on Apple; the NDK/Linux
// assemblers accept it unchanged.
#ifdef __APPLE__
#define CFI_START
#define CFI_DEF_CFA_OFFSET(x)
#define CFI_OFFSET(reg, offset)
#define CFI_DEF_CFA_REGISTER(reg)
#define CFI_DEF_CFA(reg, offset)
#define CFI_RESTORE(reg)
#define CFI_END
#else
#define CFI_START .cfi_startproc
#define CFI_DEF_CFA_OFFSET(x) .cfi_def_cfa_offset x
#define CFI_OFFSET(reg, offset) .cfi_offset reg, offset
#define CFI_DEF_CFA_REGISTER(reg) .cfi_def_cfa_register reg
#define CFI_DEF_CFA(reg, offset) .cfi_def_cfa reg, offset
#define CFI_RESTORE(reg) .cfi_restore reg
#define CFI_END .cfi_endproc
#endif

#ifdef __APPLE__
#define CALL(func) callq _##func
#else
#define CALL(func) callq func@PLT
#endif

// Jump forwarding between exported kernels (PLT required on ELF shared libs;
// a plain PC-relative relocation against a dynamic symbol is rejected).
#ifdef __APPLE__
#define JMP(func) jmp _##func
#else
#define JMP(func) jmp func@PLT
#endif

// i386 PIC prologue: call/pop loads %ebx with a PC anchor. ELF then adds the
// GOT base; Mach-O uses the anchor directly for @GOTOFF references. Pass a
// unique label suffix per file. Call the external RNG helpers with CALL_SYM.
#ifdef __APPLE__
#define LOAD_GOT(label) calll 1f; 1: popl %ebx
#define CALL_SYM(x) calll SYM(x)
#else
#define LOAD_GOT(label) calll 1f; 1: popl %ebx; .Lgot_##label: addl $_GLOBAL_OFFSET_TABLE_+(.Lgot_##label - 1b), %ebx
#define CALL_SYM(x) calll SYM(x)@PLT
#endif

// Section macros for Mach-O / ELF divergence.  Apple assemblers require
// explicit __TEXT / __const / __literal section directives; ELF uses the
// standard .text / .rodata equivalents.
#ifdef __APPLE__
#define POINT_TEXT .section __TEXT,__text,regular,pure_instructions
#define POINT_CONST .section __TEXT,__const
#define POINT_LIT4 .section __TEXT,__literal4,4byte_literals
#define POINT_LIT16 .section __TEXT,__literal16,16byte_literals
#define SPOT_TEXT .section __TEXT,__text,regular,pure_instructions
#define SPOT_CONST .section __TEXT,__const
#define SPOT_LIT4 .section __TEXT,__literal4,4byte_literals
#define TEXT_SECTION .section __TEXT,__text,regular,pure_instructions
#else
#define POINT_TEXT .text
#define POINT_CONST .section .rodata
#define POINT_LIT4 .section .rodata
#define POINT_LIT16 .section .rodata
#define SPOT_TEXT .text
#define SPOT_CONST .section .rodata
#define SPOT_LIT4 .section .rodata
#define TEXT_SECTION .text
#endif

// Generic constant-section macros: Apple puts constants in __TEXT,__const /
// __literal pools; ELF uses mergeable .rodata / .rodata.cstN.
#ifdef __APPLE__
#define RODATA .section __TEXT,__const
#define RODATA4 .section __TEXT,__const
#define RODATA8 .section __TEXT,__const
#define RODATA16 .section __TEXT,__const
#define RODATA32 .section __TEXT,__const
#define LIT4 .section __TEXT,__literal4,4byte_literals
#define LIT16 .section __TEXT,__literal16,16byte_literals
#else
#define RODATA .section .rodata
#define RODATA4 .section .rodata.cst4,"aM",@progbits,4
#define RODATA8 .section .rodata.cst8,"aM",@progbits,8
#define RODATA16 .section .rodata.cst16,"aM",@progbits,16
#define RODATA32 .section .rodata.cst32,"aM",@progbits,32
#define LIT4 .section .rodata.cst4,"aM",@progbits,4
#define LIT16 .section .rodata.cst16,"aM",@progbits,16
#endif

// ELF-only pragmas; all no-ops on Apple.
#ifdef __APPLE__
#define GNU_STACK
#define ADDRSIG
#define HIDE_SYM(x)
#else
#define GNU_STACK .section .note.GNU-stack,"",@progbits
#define ADDRSIG .addrsig
#define HIDE_SYM(x) .hidden SYM(x)
#endif

// The i386 turbulence kernels emit their constant pools into the text
// section on both platforms.
#define CONST4_SECTION TEXT_SECTION
#define CONST8_SECTION TEXT_SECTION
#define CONST16_SECTION TEXT_SECTION
#define CONST32_SECTION TEXT_SECTION
#define CONST_SECTION TEXT_SECTION
