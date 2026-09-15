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

.text
TEXT_SECTION
CONST4_SECTION
	.p2align	2, 0x0                          ## -- Begin function applyAvx2
LCPI0_0:
	.long	4294966784                      ## 0xfffffe00
LCPI0_1:
	.long	4294967040                      ## 0xffffff00
LCPI0_18:
	.long	255                             ## 0xff
CONST16_SECTION
	.p2align	4, 0x0
LCPI0_2:
	.long	0                               ## double 0.00390625
	.long	1064304640
	.long	0                               ## double 0.00390625
	.long	1064304640
LCPI0_14:
	.space	8
	.long	0                               ## double 1
	.long	1072693248
LCPI0_16:
	.long	0                               ## double 255
	.long	1081073664
	.long	0                               ## double 255
	.long	1081073664
LCPI0_17:
	.long	0                               ## double 0.5
	.long	1071644672
	.long	0                               ## double 0.5
	.long	1071644672
LCPI0_21:
	.long	0                               ## double 1
	.long	1072693248
	.long	0                               ## double 1
	.long	1072693248
LCPI0_22:
	.long	0                               ## double 127.5
	.long	1080025088
	.long	0                               ## double 127.5
	.long	1080025088
LCPI0_25:
	.long	16                              ## 0x10
	.long	8                               ## 0x8
	.space	4
	.space	4
LCPI0_26:
	.space	16
CONST_SECTION
	.p2align	5, 0x0
LCPI0_3:
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
LCPI0_4:
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
LCPI0_6:
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
LCPI0_7:
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
LCPI0_8:
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
LCPI0_9:
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
LCPI0_10:
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
CONST8_SECTION
	.p2align	3, 0x0
LCPI0_11:
	.long	0                               ## double 4096
	.long	1085276160
LCPI0_12:
	.long	0                               ## double -1
	.long	3220176896
LCPI0_13:
	.long	0                               ## double 3
	.long	1074266112
LCPI0_15:
	.long	4294967295                      ## double NaN
	.long	2147483647
LCPI0_19:
	.long	0                               ## double 255
	.long	1081073664
LCPI0_20:
	.long	0                               ## double 0.5
	.long	1071644672
LCPI0_23:
	.long	0                               ## double 1
	.long	1072693248
LCPI0_24:
	.long	0                               ## double 127.5
	.long	1080025088
LCPI0_27:
	.long	0                               ## double 0.00390625
	.long	1064304640
TEXT_SECTION
	.globl SYM(ksvgTurbulenceApplyAvx2_i386)
.Lksvg_pcrel_get_pc_edx:
	movl	(%esp), %edx
	retl

TYPE(ksvgTurbulenceApplyAvx2_i386,@function)
	.p2align	4, 0x90
SYM(ksvgTurbulenceApplyAvx2_i386):                             ## @applyAvx2
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
	andl	$-32, %esp
	subl	$69664, %esp                    ## imm = 0x10FE0
	.cfi_offset %esi, -20
	.cfi_offset %edi, -16
	.cfi_offset %ebx, -12
	# Hot constants cached in the local frame.
	movl	$0, -69376(%ebp)
	movl	$1085276160, -69372(%ebp)
	movl	$0, -69384(%ebp)
	movl	$3220176896, -69380(%ebp)
	movl	$0, -69392(%ebp)
	movl	$1074266112, -69388(%ebp)
	movl	$0, -69400(%ebp)
	movl	$1081073664, -69396(%ebp)
	movl	$0, -69408(%ebp)
	movl	$1071644672, -69404(%ebp)
	movl	$0, -69416(%ebp)
	movl	$1072693248, -69412(%ebp)
	movl	$0, -69424(%ebp)
	movl	$1080025088, -69420(%ebp)
	movl	$0, -69432(%ebp)
	movl	$1064304640, -69428(%ebp)
	movl	$0, -69440(%ebp)
	movl	$1072693248, -69436(%ebp)
	movl	$0, -69448(%ebp)
	movl	$1072693248, -69444(%ebp)
	movl	$0, -69456(%ebp)
	movl	$1071644672, -69452(%ebp)
	movl	$0, -69472(%ebp)
	movl	$1080025088, -69468(%ebp)
	movl	$0, -69488(%ebp)
	movl	$0, -69484(%ebp)
	movl	$0, -69480(%ebp)
	movl	$1072693248, -69476(%ebp)	## [0.0, 1.0]
	movl	$524304, -69504(%ebp)	## [16, 8, 0, 0] as dwords
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
	pushl	%edx
	calll	.Lksvg_pcrel_get_pc_edx
1:
	leal	(LCPI0_0-1b)(%edx), %edx
	vpbroadcastd	(%edx), %xmm0          ## xmm0 = [4294966784,4294966784,4294966784,4294966784]
	popl	%edx
	xorl	%edi, %edi
	movl	$-2092037281, %ebx              ## imm = 0x834E0B5F
	pushl	%edx
	calll	.Lksvg_pcrel_get_pc_edx
1:
	leal	(LCPI0_1-1b)(%edx), %edx
	vpbroadcastd	(%edx), %xmm1          ## xmm1 = [4294967040,4294967040,4294967040,4294967040]
	popl	%edx
	vmovddup	-69432(%ebp), %xmm2                 ## xmm2 = [3.90625E-3,3.90625E-3]
                                        ## xmm2 = mem[0,0]
	vxorpd	%xmm3, %xmm3, %xmm3
	vpcmpeqd	%xmm4, %xmm4, %xmm4
	.p2align	4, 0x90
LBB0_3:                                 ## =>This Inner Loop Header: Depth=1
	movl	%ecx, %eax
	imull	%ebx
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
	leal	2147483647(%ecx,%eax), %esi
	cmovgl	%edx, %esi
	movl	%esi, %eax
	imull	%ebx
	addl	%esi, %edx
	movl	%edx, %eax
	shrl	$31, %eax
	sarl	$16, %edx
	addl	%eax, %edx
	imull	$127773, %edx, %eax             ## imm = 0x1F31D
	movl	%esi, %ecx
	subl	%eax, %ecx
	imull	$16807, %ecx, %eax              ## imm = 0x41A7
	imull	$-2836, %edx, %ecx              ## imm = 0xF4EC
	leal	(%ecx,%eax), %edx
	testl	%edx, %edx
	leal	2147483647(%ecx,%eax), %ecx
	cmovgl	%edx, %ecx
	vmovd	%ecx, %xmm5
	vpinsrd	$1, %esi, %xmm5, %xmm5
	vpsrad	$31, %xmm5, %xmm6
	vpsrld	$23, %xmm6, %xmm6
	vpaddd	%xmm6, %xmm5, %xmm6
	vpand	%xmm0, %xmm6, %xmm6
	vpsubd	%xmm6, %xmm5, %xmm5
	vpaddd	%xmm1, %xmm5, %xmm5
	vcvtdq2pd	%xmm5, %xmm5
	vmulpd	%xmm2, %xmm5, %xmm5
	vcmpeqpd	%xmm3, %xmm5, %xmm6
	vtestpd	%xmm4, %xmm6
	jb	LBB0_3
## %bb.4:                               ##   in Loop: Header=BB0_3 Depth=1
	vmulsd	%xmm5, %xmm5, %xmm6
	vmovsd	%xmm6, 64(%esp)                 ## 8-byte Spill
	vshufpd	$1, %xmm5, %xmm5, %xmm7         ## xmm7 = xmm5[1,0]
	vmulsd	%xmm7, %xmm7, %xmm6
	vaddsd	64(%esp), %xmm6, %xmm6          ## 8-byte Folded Reload
	vsqrtsd	%xmm6, %xmm6, %xmm6
	vdivsd	%xmm6, %xmm7, %xmm7
	vmovsd	%xmm7, 3788(%esp,%edi,8)
	vdivsd	%xmm6, %xmm5, %xmm5
	vmovsd	%xmm5, 7900(%esp,%edi,8)
	incl	%edi
	cmpl	$256, %edi                      ## imm = 0x100
	jne	LBB0_3
## %bb.5:
	xorl	%edi, %edi
	movl	$-2092037281, %ebx              ## imm = 0x834E0B5F
	vxorpd	%xmm3, %xmm3, %xmm3
	vpcmpeqd	%xmm4, %xmm4, %xmm4
	.p2align	4, 0x90
LBB0_6:                                 ## =>This Inner Loop Header: Depth=1
	movl	%ecx, %eax
	imull	%ebx
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
	leal	2147483647(%ecx,%eax), %esi
	cmovgl	%edx, %esi
	movl	%esi, %eax
	imull	%ebx
	addl	%esi, %edx
	movl	%edx, %eax
	shrl	$31, %eax
	sarl	$16, %edx
	addl	%eax, %edx
	imull	$127773, %edx, %eax             ## imm = 0x1F31D
	movl	%esi, %ecx
	subl	%eax, %ecx
	imull	$16807, %ecx, %eax              ## imm = 0x41A7
	imull	$-2836, %edx, %ecx              ## imm = 0xF4EC
	leal	(%ecx,%eax), %edx
	testl	%edx, %edx
	leal	2147483647(%ecx,%eax), %ecx
	cmovgl	%edx, %ecx
	vmovd	%ecx, %xmm5
	vpinsrd	$1, %esi, %xmm5, %xmm5
	vpsrad	$31, %xmm5, %xmm6
	vpsrld	$23, %xmm6, %xmm6
	vpaddd	%xmm6, %xmm5, %xmm6
	vpand	%xmm0, %xmm6, %xmm6
	vpsubd	%xmm6, %xmm5, %xmm5
	vpaddd	%xmm1, %xmm5, %xmm5
	vcvtdq2pd	%xmm5, %xmm5
	vmulpd	%xmm2, %xmm5, %xmm5
	vcmpeqpd	%xmm3, %xmm5, %xmm6
	vtestpd	%xmm4, %xmm6
	jb	LBB0_6
## %bb.7:                               ##   in Loop: Header=BB0_6 Depth=1
	vmulsd	%xmm5, %xmm5, %xmm6
	vmovsd	%xmm6, 64(%esp)                 ## 8-byte Spill
	vshufpd	$1, %xmm5, %xmm5, %xmm7         ## xmm7 = xmm5[1,0]
	vmulsd	%xmm7, %xmm7, %xmm6
	vaddsd	64(%esp), %xmm6, %xmm6          ## 8-byte Folded Reload
	vsqrtsd	%xmm6, %xmm6, %xmm6
	vdivsd	%xmm6, %xmm7, %xmm7
	vmovsd	%xmm7, 12012(%esp,%edi,8)
	vdivsd	%xmm6, %xmm5, %xmm5
	vmovsd	%xmm5, 16124(%esp,%edi,8)
	incl	%edi
	cmpl	$256, %edi                      ## imm = 0x100
	jne	LBB0_6
## %bb.8:
	xorl	%edi, %edi
	movl	$-2092037281, %ebx              ## imm = 0x834E0B5F
	vxorpd	%xmm3, %xmm3, %xmm3
	vpcmpeqd	%xmm4, %xmm4, %xmm4
	.p2align	4, 0x90
LBB0_9:                                 ## =>This Inner Loop Header: Depth=1
	movl	%ecx, %eax
	imull	%ebx
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
	leal	2147483647(%ecx,%eax), %esi
	cmovgl	%edx, %esi
	movl	%esi, %eax
	imull	%ebx
	addl	%esi, %edx
	movl	%edx, %eax
	shrl	$31, %eax
	sarl	$16, %edx
	addl	%eax, %edx
	imull	$127773, %edx, %eax             ## imm = 0x1F31D
	movl	%esi, %ecx
	subl	%eax, %ecx
	imull	$16807, %ecx, %eax              ## imm = 0x41A7
	imull	$-2836, %edx, %ecx              ## imm = 0xF4EC
	leal	(%ecx,%eax), %edx
	testl	%edx, %edx
	leal	2147483647(%ecx,%eax), %ecx
	cmovgl	%edx, %ecx
	vmovd	%ecx, %xmm5
	vpinsrd	$1, %esi, %xmm5, %xmm5
	vpsrad	$31, %xmm5, %xmm6
	vpsrld	$23, %xmm6, %xmm6
	vpaddd	%xmm6, %xmm5, %xmm6
	vpand	%xmm0, %xmm6, %xmm6
	vpsubd	%xmm6, %xmm5, %xmm5
	vpaddd	%xmm1, %xmm5, %xmm5
	vcvtdq2pd	%xmm5, %xmm5
	vmulpd	%xmm2, %xmm5, %xmm5
	vcmpeqpd	%xmm3, %xmm5, %xmm6
	vtestpd	%xmm4, %xmm6
	jb	LBB0_9
## %bb.10:                              ##   in Loop: Header=BB0_9 Depth=1
	vmulsd	%xmm5, %xmm5, %xmm6
	vmovsd	%xmm6, 64(%esp)                 ## 8-byte Spill
	vshufpd	$1, %xmm5, %xmm5, %xmm7         ## xmm7 = xmm5[1,0]
	vmulsd	%xmm7, %xmm7, %xmm6
	vaddsd	64(%esp), %xmm6, %xmm6          ## 8-byte Folded Reload
	vsqrtsd	%xmm6, %xmm6, %xmm6
	vdivsd	%xmm6, %xmm7, %xmm7
	vmovsd	%xmm7, 20236(%esp,%edi,8)
	vdivsd	%xmm6, %xmm5, %xmm5
	vmovsd	%xmm5, 24348(%esp,%edi,8)
	incl	%edi
	cmpl	$256, %edi                      ## imm = 0x100
	jne	LBB0_9
## %bb.11:
	xorl	%edi, %edi
	movl	$-2092037281, %ebx              ## imm = 0x834E0B5F
	vxorpd	%xmm3, %xmm3, %xmm3
	vpcmpeqd	%xmm4, %xmm4, %xmm4
	.p2align	4, 0x90
LBB0_12:                                ## =>This Inner Loop Header: Depth=1
	movl	%ecx, %eax
	imull	%ebx
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
	leal	2147483647(%ecx,%eax), %esi
	cmovgl	%edx, %esi
	movl	%esi, %eax
	imull	%ebx
	addl	%esi, %edx
	movl	%edx, %eax
	shrl	$31, %eax
	sarl	$16, %edx
	addl	%eax, %edx
	imull	$127773, %edx, %eax             ## imm = 0x1F31D
	movl	%esi, %ecx
	subl	%eax, %ecx
	imull	$16807, %ecx, %eax              ## imm = 0x41A7
	imull	$-2836, %edx, %ecx              ## imm = 0xF4EC
	leal	(%ecx,%eax), %edx
	testl	%edx, %edx
	leal	2147483647(%ecx,%eax), %ecx
	cmovgl	%edx, %ecx
	vmovd	%ecx, %xmm5
	vpinsrd	$1, %esi, %xmm5, %xmm5
	vpsrad	$31, %xmm5, %xmm6
	vpsrld	$23, %xmm6, %xmm6
	vpaddd	%xmm6, %xmm5, %xmm6
	vpand	%xmm0, %xmm6, %xmm6
	vpsubd	%xmm6, %xmm5, %xmm5
	vpaddd	%xmm1, %xmm5, %xmm5
	vcvtdq2pd	%xmm5, %xmm5
	vmulpd	%xmm2, %xmm5, %xmm5
	vcmpeqpd	%xmm3, %xmm5, %xmm6
	vtestpd	%xmm4, %xmm6
	jb	LBB0_12
## %bb.13:                              ##   in Loop: Header=BB0_12 Depth=1
	vmulsd	%xmm5, %xmm5, %xmm6
	vmovsd	%xmm6, 64(%esp)                 ## 8-byte Spill
	vshufpd	$1, %xmm5, %xmm5, %xmm7         ## xmm7 = xmm5[1,0]
	vmulsd	%xmm7, %xmm7, %xmm6
	vaddsd	64(%esp), %xmm6, %xmm6          ## 8-byte Folded Reload
	vsqrtsd	%xmm6, %xmm6, %xmm6
	vdivsd	%xmm6, %xmm7, %xmm7
	vmovsd	%xmm7, 28460(%esp,%edi,8)
	vdivsd	%xmm6, %xmm5, %xmm5
	vmovsd	%xmm5, 32572(%esp,%edi,8)
	incl	%edi
	cmpl	$256, %edi                      ## imm = 0x100
	jne	LBB0_12
## %bb.14:
	pushl	%edx
	calll	.Lksvg_pcrel_get_pc_edx
1:
	vmovaps	(LCPI0_3-1b)(%edx), %ymm0       ## ymm0 = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31]
	vmovups	%ymm0, 1216(%esp)
	vmovaps	(LCPI0_4-1b)(%edx), %ymm0                  ## ymm0 = [32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63]
	vmovups	%ymm0, 1248(%esp)
	vmovaps	(LCPI0_5-1b)(%edx), %ymm0                  ## ymm0 = [64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95]
	vmovups	%ymm0, 1280(%esp)
	vmovaps	(LCPI0_6-1b)(%edx), %ymm0                  ## ymm0 = [96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127]
	vmovups	%ymm0, 1312(%esp)
	vmovaps	(LCPI0_7-1b)(%edx), %ymm0                  ## ymm0 = [128,129,130,131,132,133,134,135,136,137,138,139,140,141,142,143,144,145,146,147,148,149,150,151,152,153,154,155,156,157,158,159]
	vmovups	%ymm0, 1344(%esp)
	vmovaps	(LCPI0_8-1b)(%edx), %ymm0                  ## ymm0 = [160,161,162,163,164,165,166,167,168,169,170,171,172,173,174,175,176,177,178,179,180,181,182,183,184,185,186,187,188,189,190,191]
	vmovups	%ymm0, 1376(%esp)
	vmovaps	(LCPI0_9-1b)(%edx), %ymm0                  ## ymm0 = [192,193,194,195,196,197,198,199,200,201,202,203,204,205,206,207,208,209,210,211,212,213,214,215,216,217,218,219,220,221,222,223]
	vmovups	%ymm0, 1408(%esp)
	vmovapd	(LCPI0_10-1b)(%edx), %ymm0                 ## ymm0 = [224,225,226,227,228,229,230,231,232,233,234,235,236,237,238,239,240,241,242,243,244,245,246,247,248,249,250,251,252,253,254,255]
	vmovupd	%ymm0, 1440(%esp)
	popl	%edx
	movl	$256, %esi                      ## imm = 0x100
	movl	$-2092037281, %ebx              ## imm = 0x834E0B5F
	.p2align	4, 0x90
LBB0_15:                                ## =>This Inner Loop Header: Depth=1
	movl	%ecx, %eax
	imull	%ebx
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
	movzbl	1215(%esp,%esi), %eax
	movb	1216(%esp,%edx), %ah
	movb	%ah, 1215(%esp,%esi)
	movb	%al, 1216(%esp,%edx)
	decl	%esi
	cmpl	$1, %esi
	ja	LBB0_15
## %bb.16:
	xorl	%eax, %eax
	movl	$15033, %ecx                    ## imm = 0x3AB9
	.p2align	4, 0x90
LBB0_17:                                ## =>This Inner Loop Header: Depth=1
	movzbl	1216(%esp,%eax), %edx
	movb	%dl, 1472(%esp,%eax)
	movl	%edx, 1732(%esp,%eax,4)
	movl	%edx, 2756(%esp,%eax,4)
	vmovsd	3788(%esp,%eax,8), %xmm0        ## xmm0 = mem[0],zero
	vmovsd	7900(%esp,%eax,8), %xmm1        ## xmm1 = mem[0],zero
	vmovsd	%xmm0, 5836(%esp,%eax,8)
	vmovsd	%xmm1, 9948(%esp,%eax,8)
	vmovsd	%xmm0, -23448(%esp,%ecx,4)
	vmovsd	%xmm1, -7000(%esp,%ecx,4)
	vmovsd	%xmm0, -15256(%esp,%ecx,4)
	vmovsd	%xmm1, 1192(%esp,%ecx,4)
	vmovsd	12012(%esp,%eax,8), %xmm0       ## xmm0 = mem[0],zero
	vmovsd	16124(%esp,%eax,8), %xmm1       ## xmm1 = mem[0],zero
	vmovsd	%xmm0, 14060(%esp,%eax,8)
	vmovsd	%xmm1, 18172(%esp,%eax,8)
	vmovsd	%xmm0, -23440(%esp,%ecx,4)
	vmovsd	%xmm1, -6992(%esp,%ecx,4)
	vmovsd	%xmm0, -15248(%esp,%ecx,4)
	vmovsd	%xmm1, 1200(%esp,%ecx,4)
	vmovsd	20236(%esp,%eax,8), %xmm0       ## xmm0 = mem[0],zero
	vmovsd	24348(%esp,%eax,8), %xmm1       ## xmm1 = mem[0],zero
	vmovsd	%xmm0, 22284(%esp,%eax,8)
	vmovsd	%xmm1, 26396(%esp,%eax,8)
	vmovsd	%xmm0, -23432(%esp,%ecx,4)
	vmovsd	%xmm1, -6984(%esp,%ecx,4)
	vmovsd	%xmm0, -15240(%esp,%ecx,4)
	vmovsd	%xmm1, 1208(%esp,%ecx,4)
	vmovsd	28460(%esp,%eax,8), %xmm0       ## xmm0 = mem[0],zero
	vmovq	32572(%esp,%eax,8), %xmm1       ## xmm1 = mem[0],zero
	vmovsd	%xmm0, 30508(%esp,%eax,8)
	vmovq	%xmm1, 34620(%esp,%eax,8)
	vmovsd	%xmm0, -23424(%esp,%ecx,4)
	vmovq	%xmm1, -6976(%esp,%ecx,4)
	vmovsd	%xmm0, -15232(%esp,%ecx,4)
	vmovq	%xmm1, 1216(%esp,%ecx,4)
	incl	%eax
	addl	$8, %ecx
	cmpl	$258, %eax                      ## imm = 0x102
	jne	LBB0_17
## %bb.18:
	movl	16(%ebp), %eax
	imull	12(%ebp), %eax
	shll	$2, %eax
	movl	8(%ebp), %edi
	movl	%eax, %ecx
	shrl	$2, %ecx
	xorl	%eax, %eax
	vzeroupper
	rep	stosl
	movl	52(%ebp), %edx
	testl	%edx, %edx
	setg	%ah
	cmpl	$0, 56(%ebp)
	setg	%al
	movl	60(%ebp), %ecx
	cmpl	$32, %ecx
	movl	$32, %esi
	cmovll	%ecx, %esi
	movl	%esi, 28(%esp)                  ## 4-byte Spill
	movl	24(%ebp), %ecx
	cmpl	32(%ebp), %ecx
	jge	LBB0_30
## %bb.19:
	orb	%al, %ah
	movb	%ah, 23(%esp)                   ## 1-byte Spill
	movzbl	%ah, %eax
	movl	%eax, 56(%esp)                  ## 4-byte Spill
	leal	4096(%edx), %eax
	movl	%eax, 60(%esp)                  ## 4-byte Spill
	xorl	%esi, %esi
	movl	24(%ebp), %eax
	movl	%eax, 24(%esp)                  ## 4-byte Spill
	jmp	LBB0_20
	.p2align	4, 0x90
LBB0_29:                                ##   in Loop: Header=BB0_20 Depth=1
	movl	24(%esp), %eax                  ## 4-byte Reload
	incl	%eax
	movl	%eax, 24(%esp)                  ## 4-byte Spill
	cmpl	32(%ebp), %eax
	je	LBB0_30
LBB0_20:                                ## =>This Loop Header: Depth=1
                                        ##     Child Loop BB0_22 Depth 2
                                        ##     Child Loop BB0_27 Depth 2
                                        ##       Child Loop BB0_32 Depth 3
	cmpl	$0, 60(%ebp)
	jle	LBB0_25
## %bb.21:                              ##   in Loop: Header=BB0_20 Depth=1
	movl	24(%esp), %ecx                  ## 4-byte Reload
	movl	%ecx, %eax
	subl	24(%ebp), %eax
	vxorps	%xmm6, %xmm6, %xmm6
	vcvtsi2sd	%eax, %xmm6, %xmm0
	vxorps	%xmm6, %xmm6, %xmm6
	vcvtsi2sd	%ecx, %xmm6, %xmm3
	vmovsd	44(%ebp), %xmm1                 ## xmm1 = mem[0],zero
	vmulsd	%xmm1, %xmm0, %xmm4
	vmulsd	76(%ebp), %xmm3, %xmm0
	vaddsd	92(%ebp), %xmm0, %xmm0
	vdivsd	124(%ebp), %xmm0, %xmm0
	vmulsd	%xmm1, %xmm0, %xmm5
	leal	192(%esp), %eax
	movl	28(%esp), %ebx                  ## 4-byte Reload
	movl	56(%ebp), %edi
	jmp	LBB0_22
	.p2align	4, 0x90
LBB0_24:                                ##   in Loop: Header=BB0_22 Depth=2
	movl	64(%esp), %ebx                  ## 4-byte Reload
	movzbl	%dl, %edx
	movl	%edx, (%eax)
	movzbl	%cl, %ecx
	movl	%ecx, 4(%eax)
	vsubsd	%xmm7, %xmm6, %xmm0
	vmovsd	%xmm0, 8(%eax)
	vaddsd	-69384(%ebp), %xmm0, %xmm3
	vmovsd	%xmm3, 16(%eax)
	vmulsd	%xmm0, %xmm0, %xmm3
	vaddsd	%xmm0, %xmm0, %xmm0
	vmovsd	-69392(%ebp), %xmm1                 ## xmm1 = [3.0E+0,0.0E+0]
	vsubsd	%xmm0, %xmm1, %xmm0
	vmulsd	%xmm0, %xmm3, %xmm0
	vmovsd	%xmm0, 24(%eax)
	movl	56(%esp), %ecx                  ## 4-byte Reload
                                        ## kill: def $cl killed $cl killed $ecx
	shll	%cl, %edi
	vaddsd	%xmm5, %xmm5, %xmm5
	vaddsd	%xmm4, %xmm4, %xmm4
	addl	$32, %eax
	decl	%ebx
	je	LBB0_25
LBB0_22:                                ##   Parent Loop BB0_20 Depth=1
                                        ## =>  This Inner Loop Header: Depth=2
	movl	%ebx, 64(%esp)                  ## 4-byte Spill
	vaddsd	-69376(%ebp), %xmm5, %xmm6
	vroundsd	$9, %xmm6, %xmm6, %xmm7
	vcvttsd2si	%xmm7, %edx
	leal	1(%edx), %ecx
	testl	%edi, %edi
	setg	%bl
	andb	23(%esp), %bl                   ## 1-byte Folded Reload
	cmpb	$1, %bl
	jne	LBB0_24
## %bb.23:                              ##   in Loop: Header=BB0_22 Depth=2
	vroundsd	$9, %xmm4, %xmm4, %xmm0
	vcvttsd2si	%xmm0, %ebx
	leal	(%edi,%ebx), %esi
	addl	$4096, %esi                     ## imm = 0x1000
	movl	%esi, 40(%esp)                  ## 4-byte Spill
	cmpl	%edx, %esi
	movl	%edi, %esi
	movl	$0, %ebx
	cmovgl	%ebx, %esi
	subl	%esi, %edx
	cmpl	40(%esp), %ecx                  ## 4-byte Folded Reload
	movl	%edi, %esi
	cmovll	%ebx, %esi
	subl	%esi, %ecx
	xorl	%esi, %esi
	jmp	LBB0_24
	.p2align	4, 0x90
LBB0_25:                                ##   in Loop: Header=BB0_20 Depth=1
	movl	20(%ebp), %eax
	cmpl	28(%ebp), %eax
	movl	52(%ebp), %ebx
	jge	LBB0_29
## %bb.26:                              ##   in Loop: Header=BB0_20 Depth=1
	movl	24(%esp), %eax                  ## 4-byte Reload
	imull	12(%ebp), %eax
	movl	8(%ebp), %ecx
	leal	(%ecx,%eax,4), %eax
	movl	%eax, 52(%esp)                  ## 4-byte Spill
	movl	20(%ebp), %edi
	jmp	LBB0_27
	.p2align	4, 0x90
LBB0_39:                                ##   in Loop: Header=BB0_27 Depth=2
	vaddpd	-69440(%ebp), %xmm2, %xmm0
	vmulpd	-69472(%ebp), %xmm0, %xmm0
	vaddpd	-69456(%ebp), %xmm0, %xmm0
	vroundpd	$9, %xmm0, %xmm0
	vcvttpd2dq	%xmm0, %xmm0
	vextractf128	$1, %ymm2, %xmm1
	vmovsd	-69416(%ebp), %xmm3                 ## xmm3 = [1.0E+0,0.0E+0]
	vaddsd	%xmm3, %xmm1, %xmm2
	vmovsd	-69424(%ebp), %xmm4                 ## xmm4 = [1.275E+2,0.0E+0]
	vmulsd	%xmm4, %xmm2, %xmm2
	vmovsd	-69408(%ebp), %xmm6                 ## xmm6 = [5.0E-1,0.0E+0]
	vaddsd	%xmm6, %xmm2, %xmm2
	vroundsd	$9, %xmm2, %xmm2, %xmm2
	vcvttsd2si	%xmm2, %ecx
	vpcmpeqd	%xmm7, %xmm7, %xmm7
	vpsrld	$24, %xmm7, %xmm7         ## xmm7 = [255,255,255,255]
	cmpl	$255, %ecx
	movl	$255, %edx
	cmovgel	%edx, %ecx
	vpminsd	%xmm7, %xmm0, %xmm0
	testl	%ecx, %ecx
	cmovlel	%esi, %ecx
	vpxor	%xmm5, %xmm5, %xmm5
	vpmaxsd	%xmm5, %xmm0, %xmm5
	vshufpd	$1, %xmm1, %xmm1, %xmm0         ## xmm0 = xmm1[1,0]
	vaddsd	%xmm3, %xmm0, %xmm0
	vmovapd	%xmm6, %xmm2
	vmulsd	%xmm4, %xmm0, %xmm0
LBB0_40:                                ##   in Loop: Header=BB0_27 Depth=2
	movl	32(%esp), %edi                  ## 4-byte Reload
	vmovd	-69504(%ebp), %xmm1
	vpsllvd	%xmm1, %xmm5, %xmm1
	vaddsd	%xmm2, %xmm0, %xmm0
	vroundsd	$9, %xmm0, %xmm0, %xmm0
	vcvttsd2si	%xmm0, %eax
	cmpl	$255, %eax
	cmovgel	%edx, %eax
	testl	%eax, %eax
	cmovlel	%esi, %eax
	vmovd	%xmm1, %edx
	orl	%ecx, %edx
	vpextrd	$1, %xmm1, %ecx
	orl	%ecx, %edx
	shll	$24, %eax
	orl	%eax, %edx
	movl	52(%esp), %eax                  ## 4-byte Reload
	movl	%edx, (%eax,%edi,4)
	incl	%edi
	cmpl	28(%ebp), %edi
	je	LBB0_29
LBB0_27:                                ##   Parent Loop BB0_20 Depth=1
                                        ## =>  This Loop Header: Depth=2
                                        ##       Child Loop BB0_32 Depth 3
	cmpl	$0, 60(%ebp)
	movl	%edi, 32(%esp)                  ## 4-byte Spill
	jle	LBB0_28
## %bb.31:                              ##   in Loop: Header=BB0_27 Depth=2
	movl	%edi, %eax
	subl	20(%ebp), %eax
	vxorps	%xmm7, %xmm7, %xmm7
	vcvtsi2sd	%eax, %xmm7, %xmm0
	vxorps	%xmm7, %xmm7, %xmm7
	vcvtsi2sd	%edi, %xmm7, %xmm3
	vmulsd	68(%ebp), %xmm3, %xmm3
	vaddsd	84(%ebp), %xmm3, %xmm3
	vdivsd	116(%ebp), %xmm3, %xmm3
	vmovsd	36(%ebp), %xmm1                 ## xmm1 = mem[0],zero
	vmulsd	%xmm1, %xmm3, %xmm3
	vmulsd	%xmm1, %xmm0, %xmm0
	vblendpd	$2, -69488(%ebp), %xmm0, %xmm4      ## xmm4 = xmm0[0],mem[1]
	vxorpd	%xmm2, %xmm2, %xmm2
	leal	192(%esp), %ecx
	movl	28(%esp), %eax                  ## 4-byte Reload
	jmp	LBB0_32
	.p2align	4, 0x90
LBB0_36:                                ##   in Loop: Header=BB0_32 Depth=3
	xorl	%esi, %esi
	vmovapd	64(%esp), %ymm2                 ## 32-byte Reload
	vmovsd	40(%esp), %xmm3                 ## 8-byte Reload
                                        ## xmm3 = mem[0],zero
	vmovapd	160(%esp), %ymm4                ## 32-byte Reload
	movl	36(%esp), %eax                  ## 4-byte Reload
	vpermpd	$85, %ymm4, %ymm1               ## ymm1 = ymm4[1,1,1,1]
	vdivpd	%ymm1, %ymm0, %ymm0
	vaddpd	%ymm0, %ymm2, %ymm2
	vaddsd	%xmm3, %xmm3, %xmm3
	vaddpd	%xmm4, %xmm4, %xmm4
	addl	$32, %ecx
	decl	%eax
	movl	52(%ebp), %ebx
	je	LBB0_37
LBB0_32:                                ##   Parent Loop BB0_20 Depth=1
                                        ##     Parent Loop BB0_27 Depth=2
                                        ## =>    This Inner Loop Header: Depth=3
	movl	%eax, 36(%esp)                  ## 4-byte Spill
	vmovsd	%xmm3, 40(%esp)                 ## 8-byte Spill
	vaddsd	-69376(%ebp), %xmm3, %xmm0
	vroundsd	$9, %xmm0, %xmm0, %xmm3
	vcvttsd2si	%xmm3, %edx
	leal	1(%edx), %eax
	vsubsd	%xmm3, %xmm0, %xmm7
	vmovsd	%xmm7, 112(%esp)
	vaddsd	-69384(%ebp), %xmm7, %xmm0
	vmovsd	%xmm0, 120(%esp)
	testl	%ebx, %ebx
	vmovapd	%ymm2, 64(%esp)                 ## 32-byte Spill
	vmovapd	%ymm4, 160(%esp)                ## 32-byte Spill
	jle	LBB0_34
## %bb.33:                              ##   in Loop: Header=BB0_32 Depth=3
	vroundsd	$9, %xmm4, %xmm4, %xmm0
	vcvttsd2si	%xmm0, %esi
	addl	60(%esp), %esi                  ## 4-byte Folded Reload
	cmpl	%edx, %esi
	movl	%ebx, %edi
	movl	$0, %ebx
	cmovgl	%ebx, %edi
	xorl	%ebx, %ebx
	subl	%edi, %edx
	cmpl	%esi, %eax
	movl	52(%ebp), %esi
	cmovll	%ebx, %esi
	subl	%esi, %eax
LBB0_34:                                ##   in Loop: Header=BB0_32 Depth=3
	movzbl	%dl, %esi
	movzbl	%al, %edi
	movl	(%ecx), %edx
	movl	4(%ecx), %ebx
	movl	1732(%esp,%esi,4), %eax
	movl	1732(%esp,%edi,4), %esi
	leal	(%eax,%edx), %edi
	addl	%esi, %edx
	addl	%ebx, %eax
	addl	%ebx, %esi
	movzbl	1732(%esp,%edi,4), %edi
	shll	$5, %edi
	vmovups	8(%ecx), %xmm0
	vmovups	%xmm0, 128(%esp)
	vmulsd	%xmm7, %xmm7, %xmm0
	vaddsd	%xmm7, %xmm7, %xmm3
	vmovsd	-69392(%ebp), %xmm1                 ## xmm1 = [3.0E+0,0.0E+0]
	vsubsd	%xmm3, %xmm1, %xmm3
	vmulsd	%xmm3, %xmm0, %xmm0
	vmovsd	%xmm0, 144(%esp)
	vmovsd	24(%ecx), %xmm0                 ## xmm0 = mem[0],zero
	vmovsd	%xmm0, 152(%esp)
	vbroadcastsd	112(%esp), %ymm0
	vbroadcastsd	128(%esp), %ymm1
	leal	36684(%esp), %ebx
	vmulpd	(%ebx,%edi), %ymm0, %ymm7
	vmulpd	16448(%ebx,%edi), %ymm1, %ymm3
	movzbl	1732(%esp,%edx,4), %edx
	shll	$5, %edx
	vbroadcastsd	120(%esp), %ymm2
	vmulpd	(%ebx,%edx), %ymm2, %ymm4
	vmulpd	16448(%ebx,%edx), %ymm1, %ymm1
	movzbl	1732(%esp,%eax,4), %eax
	shll	$5, %eax
	vmovddup	16(%ecx), %xmm5                 ## xmm5 = mem[0,0]
	vbroadcastsd	%xmm5, %ymm5
	vmulpd	(%ebx,%eax), %ymm0, %ymm0
	vmulpd	16448(%ebx,%eax), %ymm5, %ymm6
	movzbl	1732(%esp,%esi,4), %eax
	shll	$5, %eax
	vmulpd	(%ebx,%eax), %ymm2, %ymm2
	vmulpd	16448(%ebx,%eax), %ymm5, %ymm5
	vaddpd	%ymm3, %ymm7, %ymm3
	vaddpd	%ymm1, %ymm4, %ymm1
	vaddpd	%ymm6, %ymm0, %ymm0
	vaddpd	%ymm5, %ymm2, %ymm2
	vbroadcastsd	144(%esp), %ymm4
	vsubpd	%ymm3, %ymm1, %ymm1
	vmulpd	%ymm1, %ymm4, %ymm1
	vaddpd	%ymm1, %ymm3, %ymm1
	vsubpd	%ymm0, %ymm2, %ymm2
	vmulpd	%ymm2, %ymm4, %ymm2
	vaddpd	%ymm2, %ymm0, %ymm0
	vbroadcastsd	152(%esp), %ymm2
	vsubpd	%ymm1, %ymm0, %ymm0
	vmulpd	%ymm0, %ymm2, %ymm0
	vaddpd	%ymm0, %ymm1, %ymm0
	cmpl	$1, 64(%ebp)
	je	LBB0_36
## %bb.35:                              ##   in Loop: Header=BB0_32 Depth=3
	vpcmpeqd	%ymm7, %ymm7, %ymm7
	vpsrlq	$1, %ymm7, %ymm7
	vandpd	%ymm7, %ymm0, %ymm0
	jmp	LBB0_36
	.p2align	4, 0x90
LBB0_28:                                ##   in Loop: Header=BB0_27 Depth=2
	vxorpd	%xmm2, %xmm2, %xmm2
LBB0_37:                                ##   in Loop: Header=BB0_27 Depth=2
	cmpl	$1, 64(%ebp)
	je	LBB0_39
## %bb.38:                              ##   in Loop: Header=BB0_27 Depth=2
	vmovddup	-69400(%ebp), %xmm1
	vmulpd	%xmm1, %xmm2, %xmm0
	vaddpd	-69456(%ebp), %xmm0, %xmm0
	vroundpd	$9, %xmm0, %xmm0
	vcvttpd2dq	%xmm0, %xmm0
	vpcmpeqd	%xmm1, %xmm1, %xmm1
	vpsrld	$24, %xmm1, %xmm1
	vpminsd	%xmm1, %xmm0, %xmm0
	vpxor	%xmm5, %xmm5, %xmm5
	vpmaxsd	%xmm5, %xmm0, %xmm5
	vextractf128	$1, %ymm2, %xmm0
	vmovsd	-69400(%ebp), %xmm3                 ## xmm3 = [2.55E+2,0.0E+0]
	vmulsd	%xmm3, %xmm0, %xmm1
	vmovsd	-69408(%ebp), %xmm2                 ## xmm2 = [5.0E-1,0.0E+0]
	vaddsd	%xmm2, %xmm1, %xmm1
	vroundsd	$9, %xmm1, %xmm1, %xmm1
	vcvttsd2si	%xmm1, %ecx
	cmpl	$255, %ecx
	movl	$255, %edx
	cmovgel	%edx, %ecx
	testl	%ecx, %ecx
	cmovlel	%esi, %ecx
	vshufpd	$1, %xmm0, %xmm0, %xmm0         ## xmm0 = xmm0[1,0]
	vmulsd	%xmm3, %xmm0, %xmm0
	jmp	LBB0_40
LBB0_30:
	leal	-12(%ebp), %esp
	popl	%esi
	popl	%edi
	popl	%ebx
	popl	%ebp
	vzeroupper
	retl
	.cfi_endproc
                                        ## -- End function
//// SIZE(SYM(ksvgTurbulenceApplyAvx2_i386))
