/*
 *    Copyright 2026 András Oravecz <info@oandras.hu>
 *
 *    Licensed under the Apache License, Version 2.0 (the "License");
 *    you may not use this file except in compliance with the License.
 *    You may obtain a copy of the License at
 *
 *        http://www.apache.org/licenses/LICENSE-2.0
 *
 *    Unless required by applicable law or agreed to in writing, software
 *    distributed under the License is distributed on an "AS IS" BASIS,
 *    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *    See the License for the specific language governing permissions and
 *    limitations under the License.
 */

#include "asm_macros.S"

#ifdef __APPLE__
#define TEXT_SECTION .section __TEXT,__text,regular,pure_instructions
#define CONST4_SECTION TEXT_SECTION
#define CONST8_SECTION TEXT_SECTION
#define CONST16_SECTION TEXT_SECTION
#define CONST32_SECTION TEXT_SECTION
#define CONST_SECTION TEXT_SECTION
#ifdef __APPLE__
#define CALL_SYM(x) calll SYM(x)
#else
#define CALL_SYM(x) calll SYM(x)@PLT
#endif
#else
#define TEXT_SECTION .text
#define CONST4_SECTION TEXT_SECTION
#define CONST8_SECTION TEXT_SECTION
#define CONST16_SECTION TEXT_SECTION
#define CONST32_SECTION TEXT_SECTION
#define CONST_SECTION TEXT_SECTION
#ifdef __APPLE__
#define CALL_SYM(x) calll SYM(x)
#else
#define CALL_SYM(x) calll SYM(x)@PLT
#endif
#endif

.text
TEXT_SECTION
CONST8_SECTION
	.p2align	3, 0x0                          ## -- Begin function applySse2
LCPI0_0:
	.long	0                               ## double 0.00390625
	.long	1064304640
LCPI0_18:
	.long	0                               ## double 1
	.long	1072693248
LCPI0_19:
	.long	0                               ## double 4096
	.long	1085276160
LCPI0_20:
	.long	0                               ## double -1
	.long	3220176896
LCPI0_21:
	.long	0                               ## double 3
	.long	1074266112
LCPI0_23:
	.long	0                               ## double 0.5
	.long	1071644672
CONST16_SECTION
	.p2align	4, 0x0
LCPI0_1:
	.byte	0                               ## 0x0
	.byte	1                               ## 0x1
	.byte	2                               ## 0x2
	.byte	3                               ## 0x3
	.byte	4                               ## 0x4
	.byte	5                               ## 0x5
	.byte	6                               ## 0x6
	.byte	7                               ## 0x7
	.byte	8                               ## 0x8
	.byte	9                               ## 0x9
	.byte	10                              ## 0xa
	.byte	11                              ## 0xb
	.byte	12                              ## 0xc
	.byte	13                              ## 0xd
	.byte	14                              ## 0xe
	.byte	15                              ## 0xf
LCPI0_2:
	.byte	16                              ## 0x10
	.byte	17                              ## 0x11
	.byte	18                              ## 0x12
	.byte	19                              ## 0x13
	.byte	20                              ## 0x14
	.byte	21                              ## 0x15
	.byte	22                              ## 0x16
	.byte	23                              ## 0x17
	.byte	24                              ## 0x18
	.byte	25                              ## 0x19
	.byte	26                              ## 0x1a
	.byte	27                              ## 0x1b
	.byte	28                              ## 0x1c
	.byte	29                              ## 0x1d
	.byte	30                              ## 0x1e
	.byte	31                              ## 0x1f
LCPI0_3:
	.byte	32                              ## 0x20
	.byte	33                              ## 0x21
	.byte	34                              ## 0x22
	.byte	35                              ## 0x23
	.byte	36                              ## 0x24
	.byte	37                              ## 0x25
	.byte	38                              ## 0x26
	.byte	39                              ## 0x27
	.byte	40                              ## 0x28
	.byte	41                              ## 0x29
	.byte	42                              ## 0x2a
	.byte	43                              ## 0x2b
	.byte	44                              ## 0x2c
	.byte	45                              ## 0x2d
	.byte	46                              ## 0x2e
	.byte	47                              ## 0x2f
LCPI0_4:
	.byte	48                              ## 0x30
	.byte	49                              ## 0x31
	.byte	50                              ## 0x32
	.byte	51                              ## 0x33
	.byte	52                              ## 0x34
	.byte	53                              ## 0x35
	.byte	54                              ## 0x36
	.byte	55                              ## 0x37
	.byte	56                              ## 0x38
	.byte	57                              ## 0x39
	.byte	58                              ## 0x3a
	.byte	59                              ## 0x3b
	.byte	60                              ## 0x3c
	.byte	61                              ## 0x3d
	.byte	62                              ## 0x3e
	.byte	63                              ## 0x3f
LCPI0_5:
	.byte	64                              ## 0x40
	.byte	65                              ## 0x41
	.byte	66                              ## 0x42
	.byte	67                              ## 0x43
	.byte	68                              ## 0x44
	.byte	69                              ## 0x45
	.byte	70                              ## 0x46
	.byte	71                              ## 0x47
	.byte	72                              ## 0x48
	.byte	73                              ## 0x49
	.byte	74                              ## 0x4a
	.byte	75                              ## 0x4b
	.byte	76                              ## 0x4c
	.byte	77                              ## 0x4d
	.byte	78                              ## 0x4e
	.byte	79                              ## 0x4f
LCPI0_6:
	.byte	80                              ## 0x50
	.byte	81                              ## 0x51
	.byte	82                              ## 0x52
	.byte	83                              ## 0x53
	.byte	84                              ## 0x54
	.byte	85                              ## 0x55
	.byte	86                              ## 0x56
	.byte	87                              ## 0x57
	.byte	88                              ## 0x58
	.byte	89                              ## 0x59
	.byte	90                              ## 0x5a
	.byte	91                              ## 0x5b
	.byte	92                              ## 0x5c
	.byte	93                              ## 0x5d
	.byte	94                              ## 0x5e
	.byte	95                              ## 0x5f
LCPI0_7:
	.byte	96                              ## 0x60
	.byte	97                              ## 0x61
	.byte	98                              ## 0x62
	.byte	99                              ## 0x63
	.byte	100                             ## 0x64
	.byte	101                             ## 0x65
	.byte	102                             ## 0x66
	.byte	103                             ## 0x67
	.byte	104                             ## 0x68
	.byte	105                             ## 0x69
	.byte	106                             ## 0x6a
	.byte	107                             ## 0x6b
	.byte	108                             ## 0x6c
	.byte	109                             ## 0x6d
	.byte	110                             ## 0x6e
	.byte	111                             ## 0x6f
LCPI0_8:
	.byte	112                             ## 0x70
	.byte	113                             ## 0x71
	.byte	114                             ## 0x72
	.byte	115                             ## 0x73
	.byte	116                             ## 0x74
	.byte	117                             ## 0x75
	.byte	118                             ## 0x76
	.byte	119                             ## 0x77
	.byte	120                             ## 0x78
	.byte	121                             ## 0x79
	.byte	122                             ## 0x7a
	.byte	123                             ## 0x7b
	.byte	124                             ## 0x7c
	.byte	125                             ## 0x7d
	.byte	126                             ## 0x7e
	.byte	127                             ## 0x7f
LCPI0_9:
	.byte	128                             ## 0x80
	.byte	129                             ## 0x81
	.byte	130                             ## 0x82
	.byte	131                             ## 0x83
	.byte	132                             ## 0x84
	.byte	133                             ## 0x85
	.byte	134                             ## 0x86
	.byte	135                             ## 0x87
	.byte	136                             ## 0x88
	.byte	137                             ## 0x89
	.byte	138                             ## 0x8a
	.byte	139                             ## 0x8b
	.byte	140                             ## 0x8c
	.byte	141                             ## 0x8d
	.byte	142                             ## 0x8e
	.byte	143                             ## 0x8f
LCPI0_10:
	.byte	144                             ## 0x90
	.byte	145                             ## 0x91
	.byte	146                             ## 0x92
	.byte	147                             ## 0x93
	.byte	148                             ## 0x94
	.byte	149                             ## 0x95
	.byte	150                             ## 0x96
	.byte	151                             ## 0x97
	.byte	152                             ## 0x98
	.byte	153                             ## 0x99
	.byte	154                             ## 0x9a
	.byte	155                             ## 0x9b
	.byte	156                             ## 0x9c
	.byte	157                             ## 0x9d
	.byte	158                             ## 0x9e
	.byte	159                             ## 0x9f
LCPI0_11:
	.byte	160                             ## 0xa0
	.byte	161                             ## 0xa1
	.byte	162                             ## 0xa2
	.byte	163                             ## 0xa3
	.byte	164                             ## 0xa4
	.byte	165                             ## 0xa5
	.byte	166                             ## 0xa6
	.byte	167                             ## 0xa7
	.byte	168                             ## 0xa8
	.byte	169                             ## 0xa9
	.byte	170                             ## 0xaa
	.byte	171                             ## 0xab
	.byte	172                             ## 0xac
	.byte	173                             ## 0xad
	.byte	174                             ## 0xae
	.byte	175                             ## 0xaf
LCPI0_12:
	.byte	176                             ## 0xb0
	.byte	177                             ## 0xb1
	.byte	178                             ## 0xb2
	.byte	179                             ## 0xb3
	.byte	180                             ## 0xb4
	.byte	181                             ## 0xb5
	.byte	182                             ## 0xb6
	.byte	183                             ## 0xb7
	.byte	184                             ## 0xb8
	.byte	185                             ## 0xb9
	.byte	186                             ## 0xba
	.byte	187                             ## 0xbb
	.byte	188                             ## 0xbc
	.byte	189                             ## 0xbd
	.byte	190                             ## 0xbe
	.byte	191                             ## 0xbf
LCPI0_13:
	.byte	192                             ## 0xc0
	.byte	193                             ## 0xc1
	.byte	194                             ## 0xc2
	.byte	195                             ## 0xc3
	.byte	196                             ## 0xc4
	.byte	197                             ## 0xc5
	.byte	198                             ## 0xc6
	.byte	199                             ## 0xc7
	.byte	200                             ## 0xc8
	.byte	201                             ## 0xc9
	.byte	202                             ## 0xca
	.byte	203                             ## 0xcb
	.byte	204                             ## 0xcc
	.byte	205                             ## 0xcd
	.byte	206                             ## 0xce
	.byte	207                             ## 0xcf
LCPI0_14:
	.byte	208                             ## 0xd0
	.byte	209                             ## 0xd1
	.byte	210                             ## 0xd2
	.byte	211                             ## 0xd3
	.byte	212                             ## 0xd4
	.byte	213                             ## 0xd5
	.byte	214                             ## 0xd6
	.byte	215                             ## 0xd7
	.byte	216                             ## 0xd8
	.byte	217                             ## 0xd9
	.byte	218                             ## 0xda
	.byte	219                             ## 0xdb
	.byte	220                             ## 0xdc
	.byte	221                             ## 0xdd
	.byte	222                             ## 0xde
	.byte	223                             ## 0xdf
LCPI0_15:
	.byte	224                             ## 0xe0
	.byte	225                             ## 0xe1
	.byte	226                             ## 0xe2
	.byte	227                             ## 0xe3
	.byte	228                             ## 0xe4
	.byte	229                             ## 0xe5
	.byte	230                             ## 0xe6
	.byte	231                             ## 0xe7
	.byte	232                             ## 0xe8
	.byte	233                             ## 0xe9
	.byte	234                             ## 0xea
	.byte	235                             ## 0xeb
	.byte	236                             ## 0xec
	.byte	237                             ## 0xed
	.byte	238                             ## 0xee
	.byte	239                             ## 0xef
LCPI0_16:
	.byte	240                             ## 0xf0
	.byte	241                             ## 0xf1
	.byte	242                             ## 0xf2
	.byte	243                             ## 0xf3
	.byte	244                             ## 0xf4
	.byte	245                             ## 0xf5
	.byte	246                             ## 0xf6
	.byte	247                             ## 0xf7
	.byte	248                             ## 0xf8
	.byte	249                             ## 0xf9
	.byte	250                             ## 0xfa
	.byte	251                             ## 0xfb
	.byte	252                             ## 0xfc
	.byte	253                             ## 0xfd
	.byte	254                             ## 0xfe
	.byte	255                             ## 0xff
LCPI0_17:
	.long	0                               ## double 255
	.long	1081073664
	.long	0                               ## double 127.5
	.long	1080025088
LCPI0_22:
	.long	4294967295                      ## double NaN
	.long	2147483647
	.long	4294967295                      ## double NaN
	.long	2147483647
TEXT_SECTION
	.globl SYM(ksvgTurbulenceApplySse2_i386)
.Lksvg_pcrel_get_pc_edx:
	movl	(%esp), %edx
	retl

TYPE(ksvgTurbulenceApplySse2_i386,@function)
	.p2align	4, 0x90
SYM(ksvgTurbulenceApplySse2_i386):                             ## @applySse2
	.cfi_startproc
## %bb.0:
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset %ebp, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register %ebp
	pushl	%ebx
	pushl	%edi
	pushl	%esi
	subl	$69868, %esp                    ## imm = 0x1108C
	.cfi_offset %esi, -20
	.cfi_offset %edi, -16
	.cfi_offset %ebx, -12
	fnstcw	-69840(%ebp)
	movzwl	-69840(%ebp), %eax
	andl	$-3073, %eax
	orl	$1024, %eax
	movw	%ax, -69842(%ebp)
	fldcw	-69842(%ebp)
	# Hot scalar constants cached in the local frame.
	movl	$0, -69776(%ebp)
	movl	$1064304640, -69772(%ebp)
	movl	$0, -69784(%ebp)
	movl	$1072693248, -69780(%ebp)
	movl	$0, -69792(%ebp)
	movl	$1085276160, -69788(%ebp)
	movl	$0, -69800(%ebp)
	movl	$3220176896, -69796(%ebp)
	movl	$0, -69808(%ebp)
	movl	$1074266112, -69804(%ebp)
	movl	$0, -69816(%ebp)
	movl	$1071644672, -69812(%ebp)
	movl	$0, -69832(%ebp)
	movl	$1081073664, -69828(%ebp)	## 255.0
	movl	$0, -69824(%ebp)
	movl	$1080025088, -69820(%ebp)	## 127.5
	movl	132(%ebp), %eax
	testl	%eax, %eax
	jg	LBB0_2
## %bb.1:
	leal	2147483646(%eax), %ecx
	leal	2147483645(%eax), %edx
	cmpl	$2147483646, %edx               ## imm = 0x7FFFFFFE
	cmovbl	%eax, %ecx
	movl	$1, %eax
	subl	%ecx, %eax
LBB0_2:
	cmpl	$2147483646, %eax               ## imm = 0x7FFFFFFE
	movl	$2147483646, %ecx               ## imm = 0x7FFFFFFE
	cmovbl	%eax, %ecx
	movl	16(%ebp), %ebx
	xorl	%esi, %esi
	movl	$-2092037281, %edi              ## imm = 0x834E0B5F
	movsd	-69776(%ebp), %xmm0                  ## xmm0 = [3.90625E-3,0.0E+0]
	xorpd	%xmm1, %xmm1
	jmp	LBB0_3
LBB0_5:                                 ##   in Loop: Header=BB0_3 Depth=1
	movapd	%xmm3, %xmm4
	mulsd	%xmm3, %xmm4
	movapd	%xmm2, %xmm5
	mulsd	%xmm2, %xmm5
	addsd	%xmm4, %xmm5
	xorps	%xmm4, %xmm4
	sqrtsd	%xmm5, %xmm4
	divsd	%xmm4, %xmm2
	movsd	%xmm2, -67196(%ebp,%esi,8)
	divsd	%xmm4, %xmm3
	movsd	%xmm3, -63084(%ebp,%esi,8)
	incl	%esi
	cmpl	$256, %esi                      ## imm = 0x100
	je	LBB0_6
	.p2align	4, 0x90
LBB0_3:                                 ## =>This Inner Loop Header: Depth=1
	movl	%ecx, %eax
	imull	%edi
	addl	%ecx, %edx
	movl	%edx, %eax
	shrl	$31, %eax
	sarl	$16, %edx
	addl	%eax, %edx
	imull	$127773, %edx, %eax             ## imm = 0x1F31D
	subl	%eax, %ecx
	imull	$16807, %ecx, %eax              ## imm = 0x41A7
	imull	$-2836, %edx, %ecx              ## imm = 0xF4EC
	leal	(%ecx,%eax), %edx
	testl	%edx, %edx
	leal	2147483647(%ecx,%eax), %ecx
	cmovgl	%edx, %ecx
	leal	511(%ecx), %eax
	testl	%ecx, %ecx
	cmovnsl	%ecx, %eax
	andl	$-512, %eax                     ## imm = 0xFE00
	negl	%eax
	addl	%ecx, %eax
	addl	$-256, %eax
	xorps	%xmm2, %xmm2
	cvtsi2sd	%eax, %xmm2
	movl	%ecx, %eax
	imull	%edi
	addl	%ecx, %edx
	movl	%edx, %eax
	shrl	$31, %eax
	sarl	$16, %edx
	addl	%eax, %edx
	imull	$127773, %edx, %eax             ## imm = 0x1F31D
	subl	%eax, %ecx
	imull	$16807, %ecx, %eax              ## imm = 0x41A7
	imull	$-2836, %edx, %ecx              ## imm = 0xF4EC
	leal	(%ecx,%eax), %edx
	testl	%edx, %edx
	leal	2147483647(%ecx,%eax), %ecx
	cmovgl	%edx, %ecx
	leal	511(%ecx), %eax
	testl	%ecx, %ecx
	cmovnsl	%ecx, %eax
	andl	$-512, %eax                     ## imm = 0xFE00
	negl	%eax
	addl	%ecx, %eax
	addl	$-256, %eax
	xorps	%xmm3, %xmm3
	cvtsi2sd	%eax, %xmm3
	mulsd	%xmm0, %xmm2
	mulsd	%xmm0, %xmm3
	ucomisd	%xmm1, %xmm2
	jne	LBB0_5
	jp	LBB0_5
## %bb.4:                               ##   in Loop: Header=BB0_3 Depth=1
	ucomisd	%xmm1, %xmm3
	jne	LBB0_5
	jnp	LBB0_3
	jmp	LBB0_5
LBB0_6:
	xorl	%esi, %esi
	movl	$-2092037281, %edi              ## imm = 0x834E0B5F
	xorpd	%xmm1, %xmm1
	jmp	LBB0_7
LBB0_9:                                 ##   in Loop: Header=BB0_7 Depth=1
	movapd	%xmm3, %xmm4
	mulsd	%xmm3, %xmm4
	movapd	%xmm2, %xmm5
	mulsd	%xmm2, %xmm5
	addsd	%xmm4, %xmm5
	xorps	%xmm4, %xmm4
	sqrtsd	%xmm5, %xmm4
	divsd	%xmm4, %xmm2
	movsd	%xmm2, -58972(%ebp,%esi,8)
	divsd	%xmm4, %xmm3
	movsd	%xmm3, -54860(%ebp,%esi,8)
	incl	%esi
	cmpl	$256, %esi                      ## imm = 0x100
	je	LBB0_10
	.p2align	4, 0x90
LBB0_7:                                 ## =>This Inner Loop Header: Depth=1
	movl	%ecx, %eax
	imull	%edi
	addl	%ecx, %edx
	movl	%edx, %eax
	shrl	$31, %eax
	sarl	$16, %edx
	addl	%eax, %edx
	imull	$127773, %edx, %eax             ## imm = 0x1F31D
	subl	%eax, %ecx
	imull	$16807, %ecx, %eax              ## imm = 0x41A7
	imull	$-2836, %edx, %ecx              ## imm = 0xF4EC
	leal	(%ecx,%eax), %edx
	testl	%edx, %edx
	leal	2147483647(%ecx,%eax), %ecx
	cmovgl	%edx, %ecx
	leal	511(%ecx), %eax
	testl	%ecx, %ecx
	cmovnsl	%ecx, %eax
	andl	$-512, %eax                     ## imm = 0xFE00
	negl	%eax
	addl	%ecx, %eax
	addl	$-256, %eax
	xorps	%xmm2, %xmm2
	cvtsi2sd	%eax, %xmm2
	movl	%ecx, %eax
	imull	%edi
	addl	%ecx, %edx
	movl	%edx, %eax
	shrl	$31, %eax
	sarl	$16, %edx
	addl	%eax, %edx
	imull	$127773, %edx, %eax             ## imm = 0x1F31D
	subl	%eax, %ecx
	imull	$16807, %ecx, %eax              ## imm = 0x41A7
	imull	$-2836, %edx, %ecx              ## imm = 0xF4EC
	leal	(%ecx,%eax), %edx
	testl	%edx, %edx
	leal	2147483647(%ecx,%eax), %ecx
	cmovgl	%edx, %ecx
	leal	511(%ecx), %eax
	testl	%ecx, %ecx
	cmovnsl	%ecx, %eax
	andl	$-512, %eax                     ## imm = 0xFE00
	negl	%eax
	addl	%ecx, %eax
	addl	$-256, %eax
	xorps	%xmm3, %xmm3
	cvtsi2sd	%eax, %xmm3
	mulsd	%xmm0, %xmm2
	mulsd	%xmm0, %xmm3
	ucomisd	%xmm1, %xmm2
	jne	LBB0_9
	jp	LBB0_9
## %bb.8:                               ##   in Loop: Header=BB0_7 Depth=1
	ucomisd	%xmm1, %xmm3
	jne	LBB0_9
	jnp	LBB0_7
	jmp	LBB0_9
LBB0_10:
	xorl	%esi, %esi
	movl	$-2092037281, %edi              ## imm = 0x834E0B5F
	xorpd	%xmm1, %xmm1
	jmp	LBB0_11
LBB0_13:                                ##   in Loop: Header=BB0_11 Depth=1
	movapd	%xmm3, %xmm4
	mulsd	%xmm3, %xmm4
	movapd	%xmm2, %xmm5
	mulsd	%xmm2, %xmm5
	addsd	%xmm4, %xmm5
	xorps	%xmm4, %xmm4
	sqrtsd	%xmm5, %xmm4
	divsd	%xmm4, %xmm2
	movsd	%xmm2, -50748(%ebp,%esi,8)
	divsd	%xmm4, %xmm3
	movsd	%xmm3, -46636(%ebp,%esi,8)
	incl	%esi
	cmpl	$256, %esi                      ## imm = 0x100
	je	LBB0_14
	.p2align	4, 0x90
LBB0_11:                                ## =>This Inner Loop Header: Depth=1
	movl	%ecx, %eax
	imull	%edi
	addl	%ecx, %edx
	movl	%edx, %eax
	shrl	$31, %eax
	sarl	$16, %edx
	addl	%eax, %edx
	imull	$127773, %edx, %eax             ## imm = 0x1F31D
	subl	%eax, %ecx
	imull	$16807, %ecx, %eax              ## imm = 0x41A7
	imull	$-2836, %edx, %ecx              ## imm = 0xF4EC
	leal	(%ecx,%eax), %edx
	testl	%edx, %edx
	leal	2147483647(%ecx,%eax), %ecx
	cmovgl	%edx, %ecx
	leal	511(%ecx), %eax
	testl	%ecx, %ecx
	cmovnsl	%ecx, %eax
	andl	$-512, %eax                     ## imm = 0xFE00
	negl	%eax
	addl	%ecx, %eax
	addl	$-256, %eax
	xorps	%xmm2, %xmm2
	cvtsi2sd	%eax, %xmm2
	movl	%ecx, %eax
	imull	%edi
	addl	%ecx, %edx
	movl	%edx, %eax
	shrl	$31, %eax
	sarl	$16, %edx
	addl	%eax, %edx
	imull	$127773, %edx, %eax             ## imm = 0x1F31D
	subl	%eax, %ecx
	imull	$16807, %ecx, %eax              ## imm = 0x41A7
	imull	$-2836, %edx, %ecx              ## imm = 0xF4EC
	leal	(%ecx,%eax), %edx
	testl	%edx, %edx
	leal	2147483647(%ecx,%eax), %ecx
	cmovgl	%edx, %ecx
	leal	511(%ecx), %eax
	testl	%ecx, %ecx
	cmovnsl	%ecx, %eax
	andl	$-512, %eax                     ## imm = 0xFE00
	negl	%eax
	addl	%ecx, %eax
	addl	$-256, %eax
	xorps	%xmm3, %xmm3
	cvtsi2sd	%eax, %xmm3
	mulsd	%xmm0, %xmm2
	mulsd	%xmm0, %xmm3
	ucomisd	%xmm1, %xmm2
	jne	LBB0_13
	jp	LBB0_13
## %bb.12:                              ##   in Loop: Header=BB0_11 Depth=1
	ucomisd	%xmm1, %xmm3
	jne	LBB0_13
	jnp	LBB0_11
	jmp	LBB0_13
LBB0_14:
	xorl	%esi, %esi
	movl	$-2092037281, %edi              ## imm = 0x834E0B5F
	xorpd	%xmm1, %xmm1
	jmp	LBB0_15
LBB0_17:                                ##   in Loop: Header=BB0_15 Depth=1
	movapd	%xmm3, %xmm4
	mulsd	%xmm3, %xmm4
	movapd	%xmm2, %xmm5
	mulsd	%xmm2, %xmm5
	addsd	%xmm4, %xmm5
	xorps	%xmm4, %xmm4
	sqrtsd	%xmm5, %xmm4
	divsd	%xmm4, %xmm2
	movsd	%xmm2, -42524(%ebp,%esi,8)
	divsd	%xmm4, %xmm3
	movsd	%xmm3, -38412(%ebp,%esi,8)
	incl	%esi
	cmpl	$256, %esi                      ## imm = 0x100
	je	LBB0_18
	.p2align	4, 0x90
LBB0_15:                                ## =>This Inner Loop Header: Depth=1
	movl	%ecx, %eax
	imull	%edi
	addl	%ecx, %edx
	movl	%edx, %eax
	shrl	$31, %eax
	sarl	$16, %edx
	addl	%eax, %edx
	imull	$127773, %edx, %eax             ## imm = 0x1F31D
	subl	%eax, %ecx
	imull	$16807, %ecx, %eax              ## imm = 0x41A7
	imull	$-2836, %edx, %ecx              ## imm = 0xF4EC
	leal	(%ecx,%eax), %edx
	testl	%edx, %edx
	leal	2147483647(%ecx,%eax), %ecx
	cmovgl	%edx, %ecx
	leal	511(%ecx), %eax
	testl	%ecx, %ecx
	cmovnsl	%ecx, %eax
	andl	$-512, %eax                     ## imm = 0xFE00
	negl	%eax
	addl	%ecx, %eax
	addl	$-256, %eax
	xorps	%xmm2, %xmm2
	cvtsi2sd	%eax, %xmm2
	movl	%ecx, %eax
	imull	%edi
	addl	%ecx, %edx
	movl	%edx, %eax
	shrl	$31, %eax
	sarl	$16, %edx
	addl	%eax, %edx
	imull	$127773, %edx, %eax             ## imm = 0x1F31D
	subl	%eax, %ecx
	imull	$16807, %ecx, %eax              ## imm = 0x41A7
	imull	$-2836, %edx, %ecx              ## imm = 0xF4EC
	leal	(%ecx,%eax), %edx
	testl	%edx, %edx
	leal	2147483647(%ecx,%eax), %ecx
	cmovgl	%edx, %ecx
	leal	511(%ecx), %eax
	testl	%ecx, %ecx
	cmovnsl	%ecx, %eax
	andl	$-512, %eax                     ## imm = 0xFE00
	negl	%eax
	addl	%ecx, %eax
	addl	$-256, %eax
	xorps	%xmm3, %xmm3
	cvtsi2sd	%eax, %xmm3
	mulsd	%xmm0, %xmm2
	mulsd	%xmm0, %xmm3
	ucomisd	%xmm1, %xmm2
	jne	LBB0_17
	jp	LBB0_17
## %bb.16:                              ##   in Loop: Header=BB0_15 Depth=1
	ucomisd	%xmm1, %xmm3
	jne	LBB0_17
	jnp	LBB0_15
	jmp	LBB0_17
LBB0_18:
	pushl	%edx
	calll	.Lksvg_pcrel_get_pc_edx
1:
	movaps	(LCPI0_1-1b)(%edx), %xmm0       ## xmm0 = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]
	movaps	%xmm0, -69768(%ebp)
	movaps	(LCPI0_2-1b)(%edx), %xmm0                  ## xmm0 = [16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31]
	movaps	%xmm0, -69752(%ebp)
	movaps	(LCPI0_3-1b)(%edx), %xmm0                  ## xmm0 = [32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47]
	movaps	%xmm0, -69736(%ebp)
	movaps	(LCPI0_4-1b)(%edx), %xmm0                  ## xmm0 = [48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63]
	movaps	%xmm0, -69720(%ebp)
	movaps	(LCPI0_5-1b)(%edx), %xmm0                  ## xmm0 = [64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79]
	movaps	%xmm0, -69704(%ebp)
	movaps	(LCPI0_6-1b)(%edx), %xmm0                  ## xmm0 = [80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95]
	movaps	%xmm0, -69688(%ebp)
	movaps	(LCPI0_7-1b)(%edx), %xmm0                  ## xmm0 = [96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111]
	movaps	%xmm0, -69672(%ebp)
	movaps	(LCPI0_8-1b)(%edx), %xmm0                  ## xmm0 = [112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127]
	movaps	%xmm0, -69656(%ebp)
	movaps	(LCPI0_9-1b)(%edx), %xmm0                  ## xmm0 = [128,129,130,131,132,133,134,135,136,137,138,139,140,141,142,143]
	movaps	%xmm0, -69640(%ebp)
	movaps	(LCPI0_10-1b)(%edx), %xmm0                 ## xmm0 = [144,145,146,147,148,149,150,151,152,153,154,155,156,157,158,159]
	movaps	%xmm0, -69624(%ebp)
	movaps	(LCPI0_11-1b)(%edx), %xmm0                 ## xmm0 = [160,161,162,163,164,165,166,167,168,169,170,171,172,173,174,175]
	movaps	%xmm0, -69608(%ebp)
	movaps	(LCPI0_12-1b)(%edx), %xmm0                 ## xmm0 = [176,177,178,179,180,181,182,183,184,185,186,187,188,189,190,191]
	movaps	%xmm0, -69592(%ebp)
	movaps	(LCPI0_13-1b)(%edx), %xmm0                 ## xmm0 = [192,193,194,195,196,197,198,199,200,201,202,203,204,205,206,207]
	movaps	%xmm0, -69576(%ebp)
	movaps	(LCPI0_14-1b)(%edx), %xmm0                 ## xmm0 = [208,209,210,211,212,213,214,215,216,217,218,219,220,221,222,223]
	movaps	%xmm0, -69560(%ebp)
	movaps	(LCPI0_15-1b)(%edx), %xmm0                 ## xmm0 = [224,225,226,227,228,229,230,231,232,233,234,235,236,237,238,239]
	movaps	%xmm0, -69544(%ebp)
	movapd	(LCPI0_16-1b)(%edx), %xmm0                 ## xmm0 = [240,241,242,243,244,245,246,247,248,249,250,251,252,253,254,255]
	movapd	%xmm0, -69528(%ebp)
	popl	%edx
	movl	$256, %esi                      ## imm = 0x100
	movl	$-2092037281, %edi              ## imm = 0x834E0B5F
	.p2align	4, 0x90
LBB0_19:                                ## =>This Inner Loop Header: Depth=1
	movl	%ecx, %eax
	imull	%edi
	addl	%ecx, %edx
	movl	%edx, %eax
	shrl	$31, %eax
	sarl	$16, %edx
	addl	%eax, %edx
	imull	$127773, %edx, %eax             ## imm = 0x1F31D
	subl	%eax, %ecx
	imull	$16807, %ecx, %eax              ## imm = 0x41A7
	imull	$-2836, %edx, %ecx              ## imm = 0xF4EC
	leal	(%ecx,%eax), %edx
	testl	%edx, %edx
	leal	2147483647(%ecx,%eax), %ecx
	cmovgl	%edx, %ecx
	leal	255(%ecx), %eax
	testl	%ecx, %ecx
	cmovnsl	%ecx, %eax
	andl	$-256, %eax
	movl	%ecx, %edx
	subl	%eax, %edx
	movzbl	-69769(%ebp,%esi), %eax
	movb	-69768(%ebp,%edx), %ah
	movb	%ah, -69769(%ebp,%esi)
	movb	%al, -69768(%ebp,%edx)
	decl	%esi
	cmpl	$1, %esi
	ja	LBB0_19
## %bb.20:
	xorl	%eax, %eax
	movl	$15033, %ecx                    ## imm = 0x3AB9
	.p2align	4, 0x90
LBB0_21:                                ## =>This Inner Loop Header: Depth=1
	movzbl	-69768(%ebp,%eax), %edx
	movb	%dl, -69512(%ebp,%eax)
	movl	%edx, -69252(%ebp,%eax,4)
	movl	%edx, -68228(%ebp,%eax,4)
	movsd	-67196(%ebp,%eax,8), %xmm0      ## xmm0 = mem[0],zero
	movsd	-63084(%ebp,%eax,8), %xmm1      ## xmm1 = mem[0],zero
	movsd	%xmm0, -65148(%ebp,%eax,8)
	movsd	%xmm1, -61036(%ebp,%eax,8)
	movsd	%xmm0, -94432(%ebp,%ecx,4)
	movsd	%xmm1, -77984(%ebp,%ecx,4)
	movsd	%xmm0, -86240(%ebp,%ecx,4)
	movsd	%xmm1, -69792(%ebp,%ecx,4)
	movsd	-58972(%ebp,%eax,8), %xmm0      ## xmm0 = mem[0],zero
	movsd	-54860(%ebp,%eax,8), %xmm1      ## xmm1 = mem[0],zero
	movsd	%xmm0, -56924(%ebp,%eax,8)
	movsd	%xmm1, -52812(%ebp,%eax,8)
	movsd	%xmm0, -94424(%ebp,%ecx,4)
	movsd	%xmm1, -77976(%ebp,%ecx,4)
	movsd	%xmm0, -86232(%ebp,%ecx,4)
	movsd	%xmm1, -69784(%ebp,%ecx,4)
	movsd	-50748(%ebp,%eax,8), %xmm0      ## xmm0 = mem[0],zero
	movsd	-46636(%ebp,%eax,8), %xmm1      ## xmm1 = mem[0],zero
	movsd	%xmm0, -48700(%ebp,%eax,8)
	movsd	%xmm1, -44588(%ebp,%eax,8)
	movsd	%xmm0, -94416(%ebp,%ecx,4)
	movsd	%xmm1, -77968(%ebp,%ecx,4)
	movsd	%xmm0, -86224(%ebp,%ecx,4)
	movsd	%xmm1, -69776(%ebp,%ecx,4)
	movsd	-42524(%ebp,%eax,8), %xmm0      ## xmm0 = mem[0],zero
	movsd	-38412(%ebp,%eax,8), %xmm1      ## xmm1 = mem[0],zero
	movsd	%xmm0, -40476(%ebp,%eax,8)
	movsd	%xmm1, -36364(%ebp,%eax,8)
	movsd	%xmm0, -94408(%ebp,%ecx,4)
	movsd	%xmm1, -77960(%ebp,%ecx,4)
	movsd	%xmm0, -86216(%ebp,%ecx,4)
	movsd	%xmm1, -69768(%ebp,%ecx,4)
	incl	%eax
	addl	$8, %ecx
	cmpl	$258, %eax                      ## imm = 0x102
	jne	LBB0_21
## %bb.22:
	imull	12(%ebp), %ebx
	shll	$2, %ebx
	movl	8(%ebp), %edi
	movl	%ebx, %ecx
	shrl	$2, %ecx
	xorl	%eax, %eax
	rep	stosl
	cmpl	$0, 52(%ebp)
	setg	-13(%ebp)                       ## 1-byte Folded Spill
	cmpl	$0, 56(%ebp)
	setg	%al
	movl	60(%ebp), %ecx
	cmpl	$32, %ecx
	movl	$32, %edx
	cmovll	%ecx, %edx
	movl	%edx, -36(%ebp)                 ## 4-byte Spill
	movl	24(%ebp), %ecx
	cmpl	32(%ebp), %ecx
	jge	LBB0_36
## %bb.23:
	orb	%al, -13(%ebp)                  ## 1-byte Folded Spill
	xorl	%eax, %eax
	movsd	-69784(%ebp), %xmm0                 ## xmm0 = [1.0E+0,0.0E+0]
	movsd	%xmm0, -32(%ebp)                ## 8-byte Spill
	cmpl	$1, 64(%ebp)
	sete	%al
	je	LBB0_25
## %bb.24:
	xorps	%xmm0, %xmm0
	movsd	%xmm0, -32(%ebp)                ## 8-byte Spill
LBB0_25:
	movl	52(%ebp), %ecx
	addl	$4096, %ecx                     ## imm = 0x1000
	movl	%ecx, -88(%ebp)                 ## 4-byte Spill
	movzbl	-13(%ebp), %ecx                 ## 1-byte Folded Reload
	movl	%ecx, -80(%ebp)                 ## 4-byte Spill
	movsd	-69832(%ebp,%eax,8), %xmm0        ## xmm0 = mem[0],zero
	movsd	%xmm0, -48(%ebp)                ## 8-byte Spill
	movsd	44(%ebp), %xmm0                 ## xmm0 = mem[0],zero
	movddup	%xmm0, %xmm0                    ## xmm0 = xmm0[0,0]
	movapd	%xmm0, -296(%ebp)               ## 16-byte Spill
	movsd	36(%ebp), %xmm0                 ## xmm0 = mem[0],zero
	movddup	%xmm0, %xmm0                    ## xmm0 = xmm0[0,0]
	movapd	%xmm0, -312(%ebp)               ## 16-byte Spill
	movl	24(%ebp), %eax
	movl	%eax, -20(%ebp)                 ## 4-byte Spill
	jmp	LBB0_26
	.p2align	4, 0x90
LBB0_35:                                ##   in Loop: Header=BB0_26 Depth=1
	movl	-20(%ebp), %eax                 ## 4-byte Reload
	incl	%eax
	movl	%eax, -20(%ebp)                 ## 4-byte Spill
	cmpl	32(%ebp), %eax
	je	LBB0_36
LBB0_26:                                ## =>This Loop Header: Depth=1
                                        ##     Child Loop BB0_28 Depth 2
                                        ##     Child Loop BB0_33 Depth 2
                                        ##       Child Loop BB0_38 Depth 3
	cmpl	$0, 60(%ebp)
	jle	LBB0_31
## %bb.27:                              ##   in Loop: Header=BB0_26 Depth=1
	movl	-20(%ebp), %ecx                 ## 4-byte Reload
	movl	%ecx, %eax
	subl	24(%ebp), %eax
	xorps	%xmm0, %xmm0
	cvtsi2sd	%eax, %xmm0
	xorps	%xmm1, %xmm1
	cvtsi2sd	%ecx, %xmm1
	mulsd	76(%ebp), %xmm1
	addsd	92(%ebp), %xmm1
	divsd	124(%ebp), %xmm1
	unpcklpd	%xmm0, %xmm1                    ## xmm1 = xmm1[0],xmm0[0]
	mulpd	-296(%ebp), %xmm1               ## 16-byte Folded Reload
	leal	-1400(%ebp), %esi
	movl	-36(%ebp), %edx                 ## 4-byte Reload
	movl	56(%ebp), %edi
	jmp	LBB0_28
	.p2align	4, 0x90
LBB0_30:                                ##   in Loop: Header=BB0_28 Depth=2
	movl	-72(%ebp), %edx                 ## 4-byte Reload
	movzbl	%bl, %eax
	movl	%eax, (%esi)
	movzbl	%cl, %eax
	movl	%eax, 4(%esi)
	movsd	-104(%ebp), %xmm2               ## 8-byte Reload
                                        ## xmm2 = mem[0],zero
	subsd	%xmm0, %xmm2
	movsd	%xmm2, 8(%esi)
	movapd	%xmm2, %xmm0
	addsd	-69800(%ebp), %xmm0
	movsd	%xmm0, 16(%esi)
	movapd	%xmm2, %xmm0
	mulsd	%xmm2, %xmm0
	addsd	%xmm2, %xmm2
	movsd	-69808(%ebp), %xmm1                 ## xmm1 = [3.0E+0,0.0E+0]
	subsd	%xmm2, %xmm1
	mulsd	%xmm0, %xmm1
	movl	-80(%ebp), %ecx                 ## 4-byte Reload
                                        ## kill: def $cl killed $cl killed $ecx
	shll	%cl, %edi
	movsd	%xmm1, 24(%esi)
	movapd	-136(%ebp), %xmm0               ## 16-byte Reload
	addpd	%xmm0, %xmm0
	addl	$32, %esi
	decl	%edx
	movapd	%xmm0, %xmm1
	je	LBB0_31
LBB0_28:                                ##   Parent Loop BB0_26 Depth=1
                                        ## =>  This Inner Loop Header: Depth=2
	movapd	%xmm1, -136(%ebp)               ## 16-byte Spill
	movl	%edx, -72(%ebp)                 ## 4-byte Spill
	addsd	-69792(%ebp), %xmm1
	movsd	%xmm1, -104(%ebp)               ## 8-byte Spill
	movsd	%xmm1, (%esp)
	fldl	(%esp)
	frndint
	fstpl	-216(%ebp)
	movsd	-216(%ebp), %xmm0               ## xmm0 = mem[0],zero
	cvttsd2si	%xmm0, %ebx
	leal	1(%ebx), %ecx
	testl	%edi, %edi
	setg	%al
	andb	-13(%ebp), %al                  ## 1-byte Folded Reload
	cmpb	$1, %al
	jne	LBB0_30
## %bb.29:                              ##   in Loop: Header=BB0_28 Depth=2
	movsd	%xmm0, -56(%ebp)                ## 8-byte Spill
	movaps	-136(%ebp), %xmm0               ## 16-byte Reload
	movhps	%xmm0, (%esp)
	movl	%ecx, -24(%ebp)                 ## 4-byte Spill
	fldl	(%esp)
	frndint
	movsd	-56(%ebp), %xmm0                ## 8-byte Reload
                                        ## xmm0 = mem[0],zero
	fstpl	-208(%ebp)
	cvttsd2si	-208(%ebp), %eax
	addl	%edi, %eax
	addl	$4096, %eax                     ## imm = 0x1000
	cmpl	%ebx, %eax
	movl	%edi, %ecx
	movl	$0, %edx
	cmovgl	%edx, %ecx
	subl	%ecx, %ebx
	movl	-24(%ebp), %ecx                 ## 4-byte Reload
	cmpl	%eax, %ecx
	movl	%edi, %eax
	cmovll	%edx, %eax
	subl	%eax, %ecx
	jmp	LBB0_30
	.p2align	4, 0x90
LBB0_31:                                ##   in Loop: Header=BB0_26 Depth=1
	movl	20(%ebp), %eax
	cmpl	28(%ebp), %eax
	jge	LBB0_35
## %bb.32:                              ##   in Loop: Header=BB0_26 Depth=1
	movl	-20(%ebp), %eax                 ## 4-byte Reload
	imull	12(%ebp), %eax
	movl	8(%ebp), %ecx
	leal	(%ecx,%eax,4), %eax
	movl	%eax, -76(%ebp)                 ## 4-byte Spill
	movl	20(%ebp), %ecx
	jmp	LBB0_33
	.p2align	4, 0x90
LBB0_34:                                ##   in Loop: Header=BB0_33 Depth=2
	xorpd	%xmm0, %xmm0
	movapd	%xmm0, -72(%ebp)                ## 16-byte Spill
	xorpd	%xmm3, %xmm3
LBB0_45:                                ##   in Loop: Header=BB0_33 Depth=2
	movapd	%xmm3, -104(%ebp)               ## 16-byte Spill
	movsd	-32(%ebp), %xmm0                ## 8-byte Reload
                                        ## xmm0 = mem[0],zero
	addsd	%xmm3, %xmm0
	mulsd	-48(%ebp), %xmm0                ## 8-byte Folded Reload
	movsd	-69816(%ebp), %xmm1                 ## xmm1 = [5.0E-1,0.0E+0]
	addsd	%xmm1, %xmm0
	movsd	%xmm0, (%esp)
	fldl	(%esp)
	frndint
	fstpl	-168(%ebp)
	cvttsd2si	-168(%ebp), %esi
	cmpl	$255, %esi
	movl	$255, %eax
	cmovgel	%eax, %esi
	testl	%esi, %esi
	movl	$0, %eax
	cmovlel	%eax, %esi
	xorl	%ebx, %ebx
	movapd	-104(%ebp), %xmm0               ## 16-byte Reload
	unpckhpd	%xmm0, %xmm0                    ## xmm0 = xmm0[1,1]
	addsd	-32(%ebp), %xmm0                ## 8-byte Folded Reload
	mulsd	-48(%ebp), %xmm0                ## 8-byte Folded Reload
	addsd	-69816(%ebp), %xmm0
	movsd	%xmm0, (%esp)
	fldl	(%esp)
	frndint
	fstpl	-160(%ebp)
	cvttsd2si	-160(%ebp), %edi
	cmpl	$255, %edi
	movl	$255, %eax
	cmovgel	%eax, %edi
	testl	%edi, %edi
	cmovlel	%ebx, %edi
	movsd	-32(%ebp), %xmm0                ## 8-byte Reload
                                        ## xmm0 = mem[0],zero
	addsd	-72(%ebp), %xmm0                ## 16-byte Folded Reload
	mulsd	-48(%ebp), %xmm0                ## 8-byte Folded Reload
	addsd	-69816(%ebp), %xmm0
	movsd	%xmm0, (%esp)
	fldl	(%esp)
	frndint
	fstpl	-184(%ebp)
	cvttsd2si	-184(%ebp), %ebx
	cmpl	$255, %ebx
	movl	$255, %eax
	cmovgel	%eax, %ebx
	testl	%ebx, %ebx
	movl	$0, %eax
	cmovlel	%eax, %ebx
	movapd	-72(%ebp), %xmm0                ## 16-byte Reload
	unpckhpd	%xmm0, %xmm0                    ## xmm0 = xmm0[1,1]
	addsd	-32(%ebp), %xmm0                ## 8-byte Folded Reload
	mulsd	-48(%ebp), %xmm0                ## 8-byte Folded Reload
	addsd	-69816(%ebp), %xmm0
	movsd	%xmm0, (%esp)
	fldl	(%esp)
	frndint
	fstpl	-176(%ebp)
	cvttsd2si	-176(%ebp), %eax
	cmpl	$255, %eax
	movl	$255, %ecx
	cmovgel	%ecx, %eax
	testl	%eax, %eax
	movl	$0, %ecx
	cmovlel	%ecx, %eax
	shll	$24, %eax
	orl	%ebx, %eax
	shll	$16, %esi
	shll	$8, %edi
	orl	%esi, %edi
	orl	%eax, %edi
	movl	-76(%ebp), %eax                 ## 4-byte Reload
	movl	-84(%ebp), %ecx                 ## 4-byte Reload
	movl	%edi, (%eax,%ecx,4)
	incl	%ecx
	cmpl	28(%ebp), %ecx
	je	LBB0_35
LBB0_33:                                ##   Parent Loop BB0_26 Depth=1
                                        ## =>  This Loop Header: Depth=2
                                        ##       Child Loop BB0_38 Depth 3
	cmpl	$0, 60(%ebp)
	movl	%ecx, -84(%ebp)                 ## 4-byte Spill
	jle	LBB0_34
## %bb.37:                              ##   in Loop: Header=BB0_33 Depth=2
	movl	%ecx, %eax
	subl	20(%ebp), %eax
	xorps	%xmm0, %xmm0
	cvtsi2sd	%eax, %xmm0
	xorps	%xmm1, %xmm1
	cvtsi2sd	%ecx, %xmm1
	mulsd	68(%ebp), %xmm1
	addsd	84(%ebp), %xmm1
	divsd	116(%ebp), %xmm1
	unpcklpd	%xmm0, %xmm1                    ## xmm1 = xmm1[0],xmm0[0]
	mulpd	-312(%ebp), %xmm1               ## 16-byte Folded Reload
	xorpd	%xmm3, %xmm3
	leal	-1400(%ebp), %eax
	movl	%eax, -56(%ebp)                 ## 4-byte Spill
	movl	-36(%ebp), %eax                 ## 4-byte Reload
	xorpd	%xmm0, %xmm0
	movapd	%xmm0, -72(%ebp)                ## 16-byte Spill
	movsd	-69784(%ebp), %xmm4                 ## xmm4 = [1.0E+0,0.0E+0]
	movl	52(%ebp), %edi
	jmp	LBB0_38
	.p2align	4, 0x90
LBB0_44:                                ##   in Loop: Header=BB0_38 Depth=3
	movapd	-104(%ebp), %xmm3               ## 16-byte Reload
	movl	-24(%ebp), %eax                 ## 4-byte Reload
	movapd	-232(%ebp), %xmm4               ## 16-byte Reload
	movddup	%xmm4, %xmm2                    ## xmm2 = xmm4[0,0]
	divpd	%xmm2, %xmm0
	addpd	%xmm0, %xmm3
	divpd	%xmm2, %xmm1
	movapd	-72(%ebp), %xmm0                ## 16-byte Reload
	addpd	%xmm1, %xmm0
	movapd	%xmm0, -72(%ebp)                ## 16-byte Spill
	movapd	-136(%ebp), %xmm1               ## 16-byte Reload
	addpd	%xmm1, %xmm1
	addsd	%xmm4, %xmm4
	addl	$32, -56(%ebp)                  ## 4-byte Folded Spill
	decl	%eax
	movl	52(%ebp), %edi
	je	LBB0_45
LBB0_38:                                ##   Parent Loop BB0_26 Depth=1
                                        ##     Parent Loop BB0_33 Depth=2
                                        ## =>    This Inner Loop Header: Depth=3
	movaps	%xmm4, -232(%ebp)               ## 16-byte Spill
	movl	%eax, -24(%ebp)                 ## 4-byte Spill
	movapd	%xmm3, -104(%ebp)               ## 16-byte Spill
	xorl	%esi, %esi
	cmpb	$0, -13(%ebp)                   ## 1-byte Folded Reload
	movapd	%xmm1, -136(%ebp)               ## 16-byte Spill
	je	LBB0_40
## %bb.39:                              ##   in Loop: Header=BB0_38 Depth=3
	movhpd	%xmm1, (%esp)
	fldl	(%esp)
	frndint
	movapd	-136(%ebp), %xmm1               ## 16-byte Reload
	fstpl	-200(%ebp)
	cvttsd2si	-200(%ebp), %esi
	addl	-88(%ebp), %esi                 ## 4-byte Folded Reload
LBB0_40:                                ##   in Loop: Header=BB0_38 Depth=3
	addsd	-69792(%ebp), %xmm1
	movsd	%xmm1, -120(%ebp)               ## 8-byte Spill
	movsd	%xmm1, (%esp)
	fldl	(%esp)
	frndint
	movsd	-120(%ebp), %xmm1               ## 8-byte Reload
                                        ## xmm1 = mem[0],zero
	fstpl	-192(%ebp)
	movsd	-192(%ebp), %xmm0               ## xmm0 = mem[0],zero
	cvttsd2si	%xmm0, %ecx
	leal	1(%ecx), %eax
	subsd	%xmm0, %xmm1
	movsd	%xmm1, -280(%ebp)
	movapd	%xmm1, %xmm0
	addsd	-69800(%ebp), %xmm0
	movsd	%xmm0, -272(%ebp)
	testl	%edi, %edi
	jle	LBB0_42
## %bb.41:                              ##   in Loop: Header=BB0_38 Depth=3
	cmpl	%ecx, %esi
	movl	%edi, %edx
	movl	$0, %ebx
	cmovgl	%ebx, %edx
	subl	%edx, %ecx
	cmpl	%esi, %eax
	movl	%edi, %edx
	cmovll	%ebx, %edx
	subl	%edx, %eax
LBB0_42:                                ##   in Loop: Header=BB0_38 Depth=3
	movzbl	%cl, %esi
	movzbl	%al, %eax
	movl	-56(%ebp), %ecx                 ## 4-byte Reload
	movl	(%ecx), %edi
	movl	4(%ecx), %edx
	movl	%edx, -152(%ebp)                ## 4-byte Spill
	movl	-69252(%ebp,%esi,4), %ebx
	movl	-69252(%ebp,%eax,4), %esi
	movl	%esi, -120(%ebp)                ## 4-byte Spill
	leal	(%ebx,%edi), %eax
	movzbl	-69252(%ebp,%eax,4), %eax
	addl	%esi, %edi
	movzbl	-69252(%ebp,%edi,4), %esi
	addl	%edx, %ebx
	movzbl	-69252(%ebp,%ebx,4), %ebx
	shll	$5, %eax
	shll	$5, %esi
	shll	$5, %ebx
	movups	8(%ecx), %xmm0
	movddup	8(%ecx), %xmm2                  ## xmm2 = mem[0,0]
	movapd	%xmm2, -360(%ebp)               ## 16-byte Spill
	movaps	%xmm0, -264(%ebp)
	movapd	%xmm1, %xmm0
	mulsd	%xmm1, %xmm0
	addsd	%xmm1, %xmm1
	movsd	-69808(%ebp), %xmm6                 ## xmm6 = [3.0E+0,0.0E+0]
	subsd	%xmm1, %xmm6
	mulsd	%xmm0, %xmm6
	movsd	%xmm6, -248(%ebp)
	movsd	24(%ecx), %xmm0                 ## xmm0 = mem[0],zero
	movaps	%xmm0, -376(%ebp)               ## 16-byte Spill
	movsd	%xmm0, -240(%ebp)
	movddup	-280(%ebp), %xmm3               ## xmm3 = mem[0,0]
	movddup	-272(%ebp), %xmm5               ## xmm5 = mem[0,0]
	leal	-34300(%ebp), %edi
	movupd	(%edi,%eax), %xmm0
	mulpd	%xmm3, %xmm0
	movapd	%xmm3, %xmm4
	movapd	%xmm3, -344(%ebp)               ## 16-byte Spill
	movupd	16448(%edi,%eax), %xmm3
	movl	%eax, %edx
	mulpd	%xmm2, %xmm3
	addpd	%xmm0, %xmm3
	movupd	(%edi,%esi), %xmm0
	mulpd	%xmm5, %xmm0
	movapd	%xmm5, -328(%ebp)               ## 16-byte Spill
	movupd	16448(%edi,%esi), %xmm7
	movl	%esi, %ecx
	mulpd	%xmm2, %xmm7
	addpd	%xmm0, %xmm7
	movupd	(%edi,%ebx), %xmm0
	mulpd	%xmm4, %xmm0
	movddup	-256(%ebp), %xmm4               ## xmm4 = mem[0,0]
	movupd	16448(%edi,%ebx), %xmm2
	mulpd	%xmm4, %xmm2
	addpd	%xmm0, %xmm2
	movl	-120(%ebp), %eax                ## 4-byte Reload
	addl	-152(%ebp), %eax                ## 4-byte Folded Reload
	movzbl	-69252(%ebp,%eax,4), %esi
	shll	$5, %esi
	movupd	(%edi,%esi), %xmm1
	mulpd	%xmm5, %xmm1
	movupd	16448(%edi,%esi), %xmm0
	mulpd	%xmm4, %xmm0
	addpd	%xmm1, %xmm0
	movddup	%xmm6, %xmm1                    ## xmm1 = xmm6[0,0]
	movapd	%xmm1, -152(%ebp)               ## 16-byte Spill
	subpd	%xmm3, %xmm7
	mulpd	%xmm1, %xmm7
	addpd	%xmm3, %xmm7
	subpd	%xmm2, %xmm0
	mulpd	%xmm1, %xmm0
	addpd	%xmm2, %xmm0
	movddup	-376(%ebp), %xmm1               ## 16-byte Folded Reload
                                        ## xmm1 = mem[0,0]
	movapd	%xmm1, -120(%ebp)               ## 16-byte Spill
	subpd	%xmm7, %xmm0
	mulpd	%xmm1, %xmm0
	addpd	%xmm7, %xmm0
	movupd	16(%edi,%edx), %xmm1
	movapd	-344(%ebp), %xmm5               ## 16-byte Reload
	mulpd	%xmm5, %xmm1
	movupd	16464(%edi,%edx), %xmm2
	movapd	-360(%ebp), %xmm3               ## 16-byte Reload
	mulpd	%xmm3, %xmm2
	addpd	%xmm1, %xmm2
	movupd	16464(%edi,%ecx), %xmm7
	mulpd	%xmm3, %xmm7
	movupd	16(%edi,%ecx), %xmm1
	movapd	-328(%ebp), %xmm6               ## 16-byte Reload
	mulpd	%xmm6, %xmm1
	addpd	%xmm1, %xmm7
	movupd	16(%edi,%ebx), %xmm1
	mulpd	%xmm5, %xmm1
	movupd	16464(%edi,%ebx), %xmm3
	mulpd	%xmm4, %xmm3
	addpd	%xmm1, %xmm3
	movupd	16(%edi,%esi), %xmm5
	mulpd	%xmm6, %xmm5
	movupd	16464(%edi,%esi), %xmm1
	mulpd	%xmm4, %xmm1
	addpd	%xmm5, %xmm1
	subpd	%xmm2, %xmm7
	movapd	-152(%ebp), %xmm4               ## 16-byte Reload
	mulpd	%xmm4, %xmm7
	addpd	%xmm2, %xmm7
	subpd	%xmm3, %xmm1
	mulpd	%xmm4, %xmm1
	addpd	%xmm3, %xmm1
	subpd	%xmm7, %xmm1
	mulpd	-120(%ebp), %xmm1               ## 16-byte Folded Reload
	addpd	%xmm7, %xmm1
	cmpl	$1, 64(%ebp)
	je	LBB0_44
## %bb.43:                              ##   in Loop: Header=BB0_38 Depth=3
	pcmpeqd	%xmm2, %xmm2
	psrlq	$1, %xmm2
	andpd	%xmm2, %xmm0
	andpd	%xmm2, %xmm1
	jmp	LBB0_44
LBB0_36:
	fldcw	-69840(%ebp)
	addl	$69868, %esp                    ## imm = 0x1108C
	popl	%esi
	popl	%edi
	popl	%ebx
	popl	%ebp
	retl
	.cfi_endproc
                                        ## -- End function
//// SIZE(SYM(ksvgTurbulenceApplySse2_i386))
