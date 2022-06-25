;***********************************************************************
;*
;*          Camputers Lynx 96k ROM disassembly (version L014)
;*          -------------------------------------------------
;*
;*   Reconstructed from Camputers Lynx "Mark II" source code (Version 505, 31 July 87)
;*
;*   Disassembly, collation and formatting by: Mike Panter 25/06/2022.
;*
;*   Additional credit to: Russell Davis  (online archive of materials)
;*                         Pete Todd      (knowledge, insight and Pale)
;*
;*   WARNING: May contain inaccuracies - use at own risk.
;*
;*   Free to distribute. Please include attribution.
;*
;* ---------------------------------------------------------------------
;*     DECOMPILED USING: z88dk-dis -o 0x4000 -x "Lynx_48k_Rom.sym" "lynx96-3.rom"
;*     COMPILE/ASSEMBLE: z88dk-z80asm -b -mz80 Lynx_96k_Rom.ASM
;* ---------------------------------------------------------------------
;*
;
include "Lynx_48k_Rom.ASM"

;ORG $4000
;
    NOP                             ;[4000] 
    JP    EXINIT                    ;[4001] 

; Copy to RAM from here.
;
LWRAM:
ROMOFF:
    PUSH  BC                        ;[4004]
    LD    BC,$FF7F                  ;[4005] Bank switching
    LD    A,$10                     ;[4008]
    OUT   (C),A                     ;[400A]
    POP   BC                        ;[400C]
    RET                             ;[400D]
ROMON:
    PUSH  BC                        ;[400E]
    LD    BC,$FF7F                  ;[400F] Bank switching
    XOR   A                         ;[4012]
    OUT   (C),A                     ;[4013]
    POP   BC                        ;[4015]
    RET                             ;[4016]
;
; Execute LD A,(HL) for HL in low RAM
;
LAHL:
    PUSH  BC                        ;[4017] 
    PUSH  DE                        ;[4018] 
    LD    BC,$FF7F                  ;[4019] 
    LD    DE,$1000                  ;[401C] 
    OUT   (C),D                     ;[401F] 
    LD    A,(HL)                    ;[4021] 
    OUT   (C),E                     ;[4022] 
    POP   DE                        ;[4024] 
    POP   BC                        ;[4025] 
    RET                             ;[4026] 
;
; Execute LDIR for HL in low RAM
;
ELDIR:
; ROM OFF
    PUSH  BC                        ;[4027] 
    LD    BC,$FF7F                  ;[4028] Bank switching
    LD    A,$10                     ;[402B] 
    OUT   (C),A                     ;[402D] 
    POP   BC                        ;[402F] 
; Do LDIR
    LDIR                            ;[4030] 
; ROM ON
    LD    BC,$FF7F                  ;[4032] Bank switching
    XOR   A                         ;[4035] 
    OUT   (C),A                     ;[4036] 
    RET                             ;[4038] 
;
; Read variables from pad into
; BASIC area. In both,
; IX = pointer to BASIC
; HL = read pointer
; BC = write pointer
; Set C for EOF.
;
RNUM:
    CALL  ROMOFF                    ;[4039] cd 04 40
    PUSH  DE                        ;[403C] d5
    CALL  $40B8                     ;[403D] cd b8 40
    BIT   7,A                       ;[4040] cb 7f
    JP    NZ,$40C8                  ;[4042] c2 c8 40
    BIT   6,A                       ;[4045] cb 77
    JR    NZ,$407A                  ;[4047] 20 31
    BIT   5,A                       ;[4049] cb 6f
    JR    NZ,$4057                  ;[404B] 20 0a
    LD    D,$00                     ;[404D] 16 00
    BIT   4,A                       ;[404F] cb 67
    JR    Z,$405E                   ;[4051] 28 0b
    AND   $0F                       ;[4053] e6 0f
    JR    $405A                     ;[4055] 18 03
    CALL  $40B8                     ;[4057] cd b8 40
    LD    D,A                       ;[405A] 57
    CALL  $40B8                     ;[405B] cd b8 40
    LD    E,A                       ;[405E] 5f
    PUSH  BC                        ;[405F] c5
    PUSH  HL                        ;[4060] e5
    EX    DE,HL                     ;[4061] eb
    CALL  $400E                     ;[4062] cd 0e 40
    CALL  INTFP                     ;[4065] cd c4 34
    LD    B,$05                     ;[4068] 06 05
    LD    HL,SYSVAR_WRA1            ;[406A] 21 e5 62
    LD    A,(HL)                    ;[406D] 7e
    INC   HL                        ;[406E] 23
    LD    (IX+$00),A                ;[406F] dd 77 00
    INC   IX                        ;[4072] dd 23
    DJNZ  $406D                     ;[4074] 10 f7
    POP   HL                        ;[4076] e1
    POP   BC                        ;[4077] c1
    POP   DE                        ;[4078] d1
    RET                             ;[4079] c9

    LD    E,$05                     ;[407A] 1e 05
    CALL  $40B8                     ;[407C] cd b8 40
    LD    (IX+$00),A                ;[407F] dd 77 00
    INC   IX                        ;[4082] dd 23
    DEC   E                         ;[4084] 1d
    JR    NZ,$407C                  ;[4085] 20 f5
    POP   DE                        ;[4087] d1
    JP    $400E                     ;[4088] c3 0e 40
    CALL  LWRAM                     ;[408B] cd 04 40
    PUSH  DE                        ;[408E] d5
    LD    E,(IX-$01)                ;[408F] dd 5e ff
    CALL  $40B8                     ;[4092] cd b8 40
    BIT   7,A                       ;[4095] cb 7f
    JP    Z,$40C8                   ;[4097] ca c8 40
    RES   7,A                       ;[409A] cb bf
    LD    D,A                       ;[409C] 57
    INC   D                         ;[409D] 14
    DEC   D                         ;[409E] 15
    JR    Z,$40B0                   ;[409F] 28 0f
    CALL  $40B8                     ;[40A1] cd b8 40
    INC   E                         ;[40A4] 1c
    DEC   E                         ;[40A5] 1d
    JR    Z,$409E                   ;[40A6] 28 f6
    LD    (IX+$00),A                ;[40A8] dd 77 00
    INC   IX                        ;[40AB] dd 23
    DEC   E                         ;[40AD] 1d
    JR    $409E                     ;[40AE] 18 ee
    LD    (IX+$00),$0D              ;[40B0] dd 36 00 0d
    POP   DE                        ;[40B4] d1
    JP    $400E                     ;[40B5] c3 0e 40
;
; Read byte from software file
; NB Assumes interrupts already disabled *******
;
PRDBYT:
    LD    A,H                       ;[40B8] 7c
    CP    B                         ;[40B9] b8
    JR    NZ,PRDB2                  ;[40BA] 20 05
    LD    A,L                       ;[40BC] 7d
    CP    C                         ;[40BD] b9
    JP    Z,$40CE                   ;[40BE] ca ce 40
PRDB2:
    INC   L                         ;[40C1] 2c
    JR    NZ,PRDB3                  ;[40C2] 20 02
    LD    H,(HL)                    ;[40C4] 66
    INC   L                         ;[40C5] 2c
PRDB3: 
    LD    A,(HL)                    ;[40C6] 7e
    RET                             ;[40C7] c9
PRDTM:
    CALL  ROMON                     ;[40C8] cd 0e 40
    CALL  ERR_TYPE_MISMATCH         ;[40CB] cd 23 3b
PRDEOF:
    CALL  ROMON                     ;[40CE] cd 0e 40
    CALL  ERR_OUT_OF_DATA           ;[40D1] cd 1a 3b
;
; Get byte to save to tape.
;
EGETB:
    EXX                             ;[40D4] d9
    OUT   (C),D                     ;[40D5] ed 51
    INC   L                         ;[40D7] 2c
    JR    NZ,$40DC                  ;[40D8] 20 02
    LD    H,(HL)                    ;[40DA] 66
    INC   L                         ;[40DB] 2c
GTBYT1:
    LD    A,(HL)                    ;[40DC] 7e
    OUT   (C),E                     ;[40DD] ed 59
    EXX                             ;[40DF] d9
    RET                             ;[40E0] c9
;
; Length of this RAM
;
LWLEN	equ $-LWRAM
;
; Padding
;
    NOP                             ;[40E1] 00
    NOP                             ;[40E2] 00
    NOP                             ;[40E3] 00
    NOP                             ;[40E4] 00
    NOP                             ;[40E5] 00
    NOP                             ;[40E6] 00
    NOP                             ;[40E7] 00
    NOP                             ;[40E8] 00
    NOP                             ;[40E9] 00
    NOP                             ;[40EA] 00
    NOP                             ;[40EB] 00
    NOP                             ;[40EC] 00
    NOP                             ;[40ED] 00
    NOP                             ;[40EE] 00
    NOP                             ;[40EF] 00
    NOP                             ;[40F0] 00
    NOP                             ;[40F1] 00
    NOP                             ;[40F2] 00
    NOP                             ;[40F3] 00
    NOP                             ;[40F4] 00
    NOP                             ;[40F5] 00
    NOP                             ;[40F6] 00
    NOP                             ;[40F7] 00
    NOP                             ;[40F8] 00
    NOP                             ;[40F9] 00
    NOP                             ;[40FA] 00
    NOP                             ;[40FB] 00
    NOP                             ;[40FC] 00
    NOP                             ;[40FD] 00
    NOP                             ;[40FE] 00
    NOP                             ;[40FF] 00
;
; Extra initialization.
; Copy ROM to RAM
;
EXINIT:
    LD    HL,LWRAM                  ;[4100] 21 04 40
    LD    D,H                       ;[4103] 54
    LD    E,L                       ;[4104] 5d
    LD    BC,LWLEN                  ;[4105] 01 dd 00
    LDIR                            ;[4108] ed b0
    LD    HL,$4160                  ;[410A] 21 60 41
    LD    DE,$61C6                  ;[410D] 11 c6 61
    LD    BC,FOR                    ;[4110] 01 0f 00
    LDIR                            ;[4113] ed b0
    LD    HL,$416F                  ;[4115] 21 6f 41
    LD    DE,SYSVAR_FLIGHT          ;[4118] 11 76 62
    LD    BC,CONT                   ;[411B] 01 15 00
    LDIR                            ;[411E] ed b0
;
; Change some 48K values.
;
    LD    A,($6226)                 ;[4120] 3a 26 62
    CP    $40                       ;[4123] fe 40
    JR    NC,$4143                  ;[4125] 30 1c
    LD    HL,$61E6                  ;[4127] 21 e6 61
    LD    B,$08                     ;[412A] 06 08
CHG1:
    LD    (HL),$00                  ;[412C] 36 00
    INC   HL                        ;[412E] 23
    DJNZ  $412C                     ;[412F] 10 fb
CHG2:
    LD    HL,$41CD                  ;[4131] 21 cd 41
    LD    ($6222),HL                ;[4134] 22 22 62
    LD    HL,$4295                  ;[4137] 21 95 42
    LD    ($6225),HL                ;[413A] 22 25 62
    LD    HL,$420C                  ;[413D] 21 0c 42
    LD    ($62B3),HL                ;[4140] 22 b3 62
    LD    HL,$4184                  ;[4143] 21 84 41
    LD    ($61E8),HL                ;[4146] 22 e8 61
    LD    A,$41                     ;[4149] 3e 41
    LD    ($623E),A                 ;[414B] 32 3e 62
    LD    A,$C3                     ;[414E] 3e c3
    LD    HL,$4745                  ;[4150] 21 45 47
    LD    (SYSVAR_EXECSUB),A        ;[4153] 32 2a 62
    LD    ($622B),HL                ;[4156] 22 2b 62
    CALL  $4800                     ;[4159] cd 00 48
    CALL  $43BA                     ;[415C] cd ba 43
    RET                             ;[415F] c9

;
; Initial values of RAM.
;
UPROM:
    LD    (BC),A                    ;[4160] 02
    NOP                             ;[4161] 00
    NOP                             ;[4162] 00
    RST   $38                       ;[4163] ff
    NOP                             ;[4164] 00
    RST   $38                       ;[4165] ff
    NOP                             ;[4166] 00
    RST   $38                       ;[4167] ff
    NOP                             ;[4168] 00
    NOP                             ;[4169] 00
    NOP                             ;[416A] 00
    NOP                             ;[416B] 00
    NOP                             ;[416C] 00
    NOP                             ;[416D] 00
    ADC   B                         ;[416E] 88
UPLEN	equ $-UPROM
;
    JP    $4981                     ;[416F] c3 81 49
    JP    $49C4                     ;[4172] c3 c4 49
    JP    ERR_NOT_YET_IMP           ;[4175] c3 32 3b
    JP    ERR_NOT_YET_IMP           ;[4178] c3 32 3b
    JP    ERR_NOT_YET_IMP           ;[417B] c3 32 3b
    JP    ERR_NOT_YET_IMP           ;[417E] c3 32 3b
    JP    $470F                     ;[4181] c3 0f 47
;
EXTTAB:
EXT_ASCII:
    DW    XT96KS                    ;[4184] ASCII for EXT commands
EXT_INPUT:
    DW    XI96KS                    ;[4186] addr's for EXT input
EXT_EXEC:
    DW    XE96KS                    ;[4188] addr's for EXT exec
;
; Search for tokenable word.
; HL points to start of table,
; DE points to input.
; Exit with A = position of word,
; set C if no match.
; BC is changed!
;
EXTK:
    PUSH  HL                        ;[418A] 
    LD    B,(HL)                    ;[418B] word count
    INC   B                         ;[418C] 
    PUSH  DE                        ;[418D]
EXTK1:
; start new word
    POP   DE                        ;[418E] Restart input
    DJNZ  EXTK2                     ;[418F]
    POP   HL                        ;[4191] Failed
    SCF                             ;[4192]
    RET                             ;[4193]
EXTK2:
    INC   HL                        ;[4194]
    LD    A,(HL)                    ;[4195]
    SUB   $80                       ;[4196]
    JR    C,EXTK2                   ;[4198] Loop till start of wo
    LD    C,A                       ;[419A]
    PUSH  DE                        ;[419B]
    JR    EXTK5                     ;[419C]
EXTK4:
; next char in word
    INC   HL                        ;[419E]
    LD    C,(HL)                    ;[419F]
    BIT   7,C                       ;[41A0] Start of next word?
    JR    NZ,$41BB                  ;[41A2]
EXTK5:
; compare with input
    RST   $10                       ;[41A4]
    INC   DE                        ;[41A5]
    CP    'a'                       ;[41A6] l/c to u/c
    JR    C,EXTK6                   ;[41A8]
    CP    'z'+1                     ;[41AA]
    JR    NC,EXTK6                  ;[41AC]
    SUB   $20                       ;[41AE]
EXTK6:
    CP    C                         ;[41B0]
    JR    Z,$419E                   ;[41B1]
EXTK7:
; check for '.' abbrev.
    CP    '.'                       ;[41B3]
    JR    NZ,EXTK1                  ;[41B5]
    BIT   7,(HL)                    ;[41B7] must be >1 char
    JR    NZ,EXTK1                  ;[41B9]
EXTK8:
; match found
    POP   HL                        ;[41BB] leave DE now
    POP   HL                        ;[41BC] start of table
    LD    A,(HL)                    ;[41BD]
    SUB   B                         ;[41BE]
    OR    A                         ;[41BF] clear carry
    RET                             ;[41C0]
;
; Get address from list.
; Entry:	 HL points to list, A = position
; Exit :	 HL holds addresss
;
HL2A:
    PUSH  DE                        ;[41C1] d5
    RLCA                            ;[41C2] 07
    LD    E,A                       ;[41C3] 5f
    LD    D,$00                     ;[41C4] 16 00
    ADD   HL,DE                     ;[41C6] 19
    LD    A,(HL)                    ;[41C7] 7e
    INC   HL                        ;[41C8] 23
    LD    H,(HL)                    ;[41C9] 66
    LD    L,A                       ;[41CA] 6f
    POP   DE                        ;[41CB] d1
    RET                             ;[41CC] c9
;
; Set up rest of line after EXT.
;
IEXTS:
    PUSH  HL                        ;[41CD] e5
    LD    HL,$61E5                  ;[41CE] 21 e5 61
    LD    B,$04                     ;[41D1] 06 0
    PUSH  BC                        ;[41D3] c5
    INC   HL                        ;[41D4] 23
    LD    C,(HL)                    ;[41D5] 4e
    INC   HL                        ;[41D6] 23
    LD    B,(HL)                    ;[41D7] 46
    LD    A,C                       ;[41D8] 79
    OR    B                         ;[41D9] b0
    JR    Z,$41EC                   ;[41DA] 28 10
    PUSH  BC                        ;[41DC] c5
    POP   IX                        ;[41DD] dd e1
    PUSH  HL                        ;[41DF] e5
    LD    L,(IX+$00)                ;[41E0] dd 6e 00
    LD    H,(IX+$01)                ;[41E3] dd 66 01
    CALL  $418A                     ;[41E6] cd 8a 41
    POP   HL                        ;[41E9] e1
    JR    NC,$41F2                  ;[41EA] 30 06
    POP   BC                        ;[41EC] c1
    DJNZ  $41D3                     ;[41ED] 10 e4
    CALL  ERR_SYNTAX                ;[41EF] cd 3b 3b
    POP   BC                        ;[41F2] c1
    LD    C,A                       ;[41F3] 4f
    LD    A,$04                     ;[41F4] 3e 04
    SUB   B                         ;[41F6] 90
    RRCA                            ;[41F7] 0f
    RRCA                            ;[41F8] 0f
    ADD   C                         ;[41F9] 81
    POP   HL                        ;[41FA] e1
    LD    (HL),A                    ;[41FB] 77
    INC   HL                        ;[41FC] 23
    LD    A,C                       ;[41FD] 79
    PUSH  HL                        ;[41FE] e5
    LD    L,(IX+$02)                ;[41FF] dd 6e 02
    LD    H,(IX+$03)                ;[4202] dd 66 03
    CALL  HL2A                      ;[4205] cd c1 41
    EX    (SP),HL                   ;[4208] e3
    JP    RST_10                    ;[4209] c3 10 00
    PUSH  IX                        ;[420C] dd e5
    POP   HL                        ;[420E] e1
    PUSH  HL                        ;[420F] e5
    CALL  LNUM1                     ;[4210] cd b1 35
    CALL  PN                        ;[4213] cd 59 1d
    CALL  TEST_IS_LOOP_END          ;[4216] cd 5f 28
    CALL  SUB_INDENT                ;[4219] cd 77 28
    CALL  SKIP_LNUM                 ;[421C] cd 1b 25
    LD    A,(DE)                    ;[421F] 1a
    PUSH  AF                        ;[4220] f5
    CALL  SUB_PRINT_KEYWORD         ;[4221] cd d2 27
    POP   AF                        ;[4224] f1
    CP    $17                       ;[4225] fe 17
    JR    Z,$428C                   ;[4227] 28 63
    CP    $41                       ;[4229] fe 41
    JR    NZ,$4244                  ;[422B] 20 17
    LD    A,(DE)                    ;[422D] 1a
    AND   $C0                       ;[422E] e6 c0
    RLCA                            ;[4230] 07
    RLCA                            ;[4231] 07
    LD    HL,$61E6                  ;[4232] 21 e6 61
    CALL  HL2A                      ;[4235] cd c1 41
    LD    A,(HL)                    ;[4238] 7e
    INC   HL                        ;[4239] 23
    LD    H,(HL)                    ;[423A] 66
    LD    L,A                       ;[423B] 6f
    LD    A,(DE)                    ;[423C] 1a
    AND   $3F                       ;[423D] e6 3f
    CALL  $27D8                     ;[423F] cd d8 27
    JR    $424D                     ;[4242] 18 09
    CP    $3C                       ;[4244] fe 3c
    JR    Z,$421F                   ;[4246] 28 d7
    CP    $33                       ;[4248] fe 33
    JP    Z,PRINT_BAS_LINE          ;[424A] ca 0a 0f
    DEC   DE                        ;[424D] 1b
    INC   DE                        ;[424E] 13
    LD    A,(DE)                    ;[424F] 1a
    CP    $7B                       ;[4250] fe 7b
    RET   Z                         ;[4252] c8
    CP    $0D                       ;[4253] fe 0d
    JR    Z,$4286                   ;[4255] 28 2f
    CP    $7D                       ;[4257] fe 7d
    JR    Z,$426A                   ;[4259] 28 0f
    CP    $80                       ;[425B] fe 80
    JR    NC,$4270                  ;[425D] 30 11
    RST   $08                       ;[425F] cf
    CP    $22                       ;[4260] fe 22
    JR    NZ,$424E                  ;[4262] 20 ea
    CALL  PRINT_STRING              ;[4264] cd 57 22
    RST   $08                       ;[4267] cf
    JR    $424E                     ;[4268] 18 e4
    INC   DE                        ;[426A] 13
    CALL  SYSVAR_PP                 ;[426B] cd a9 62
    JR    $424E                     ;[426E] 18 de
    CP    $DF                       ;[4270] fe df
    PUSH  AF                        ;[4272] f5
    CALL  C,DISPLAY_SPACE           ;[4273] dc 2a 35
    CALL  PNE1                      ;[4276] cd 57 18
    POP   AF                        ;[4279] f1
    PUSH  AF                        ;[427A] f5
    CALL  C,DISPLAY_SPACE           ;[427B] dc 2a 35
    POP   AF                        ;[427E] f1
    INC   DE                        ;[427F] 13
    CP    $D7                       ;[4280] fe d7
    JR    Z,$421F                   ;[4282] 28 9b
    JR    $424F                     ;[4284] 18 c9
    POP   IX                        ;[4286] dd e1
    JP    $2842                     ;[4288] c3 42 28
    INC   DE                        ;[428B] 13
    LD    A,(DE)                    ;[428C] 1a
    CP    $0D                       ;[428D] fe 0d
    JP    Z,DO_INDENT               ;[428F] ca 40 28
    RST   $08                       ;[4292] cf
    JR    $428B                     ;[4293] 18 f6
    PUSH  IX                        ;[4295] dd e5
    AND   $C0                       ;[4297] e6 c0
    RLCA                            ;[4299] 07
    RLCA                            ;[429A] 07
    LD    HL,$61E6                  ;[429B] 21 e6 61
    CALL  HL2A                      ;[429E] cd c1 41
    LD    A,H                       ;[42A1] 7c
    OR    L                         ;[42A2] b5
    CALL  Z,ERR_NOT_YET_IMP         ;[42A3] cc 32 3b
    PUSH  HL                        ;[42A6] e5
    POP   IX                        ;[42A7] dd e1
    LD    L,(IX+$04)                ;[42A9] dd 6e 04
    LD    H,(IX+$05)                ;[42AC] dd 66 05
    LD    A,(DE)                    ;[42AF] 1a
    AND   $3F                       ;[42B0] e6 3f
    CALL  HL2A                      ;[42B2] cd c1 41
    INC   DE                        ;[42B5] 13
    LD    A,(DE)                    ;[42B6] 1a
    POP   IX                        ;[42B7] dd e1
    JP    (HL)                      ;[42B9] e9
;
; ASCII for EXT commands
;
XT96KS:
    DB    $1B                       ;[42BA] 27 (1b) = say how many
	DB    $80+'E',"XPLODE"          ;[42BB]
	DB    $80+'K',"LAXON"           ;[42C2]
	DB    $80+'L',"ASER"            ;[42C7]
	DB    $80+'Z',"AP"              ;[42CD]
	DB    $80+'S',"TORE"            ;[42D0]
	DB    $80+'I',"STORE"           ;[42D5]
	DB    $80+'F',"ETCH"            ;[42DB]
	DB    $80+'W',"IPE"             ;[42E0]
	DB    $80+'B',"ACK"             ;[42E4]
	DB    $80+'S',"SAVE"            ;[42E8]
	DB    $80+'S',"LOAD"            ;[42ED]
	DB    $80+'C',"SAVE"            ;[42F2]
	DB    $80+'C',"HAIN"            ;[42F7]
	DB    $80+'T',"RAP"             ;[42FC]
	DB    $80+'N',"OTRAP"           ;[4300]
	DB    $80+'P',"PRINT"           ;[4306]
	DB    $80+'S',"PRINT"           ;[430C]
	DB    $80+'V',"RESET"           ;[4312]
	DB    $80+'C',"IRCLE"           ;[4318]
	DB    $80+'T',"RIANGLE"         ;[431E]
	DB    $80+'C',"LW"              ;[4326]
	DB    $80+'@',"@@@@@"           ;[4329]
	DB    $80+'@',"@@@@@"           ;[432F]
	DB    $80+'@',"@@@@@"           ;[4335]
	DB    $80+'@',"@@@@@"           ;[433B]
    DB    $80+'@',"@@@@@"           ;[4341]
	DB    $80+'@',"@@@@@"           ;[4347]
    DB    $80                       ;[434D]
;
; Dispatch table for EXT input
;
XI96KS:
    DW    IMON                      ;[434E] EXPLODE
    DW    IMON                      ;[4350] KLAXON
    DW    IMON                      ;[4352] LASER
    DW    IMON                      ;[4354] ZAP
    DW    $447D                     ;[4356] STORE
    DW    $449D                     ;[4358] ISTORE
    DW    $44B2                     ;[435A] FETCH
    DW    IINK                      ;[435C] WIPE
    DW    IINK                      ;[435E] BACK
    DW    $44CE                     ;[4360] SSAVE
    DW    $44CE                     ;[4362] SLOAD
    DW    $44CE                     ;[4364] CSAVE
    DW    IDPOKE                    ;[4366] CHAIN
    DW    $46F2                     ;[4368] TRAP
    DW    IMON                      ;[436A] NOTRAP
    DW    IMON                      ;[436C] PPRINT
    DW    IMON                      ;[436E] SPRINT
    DW    IMON                      ;[4370] VRESET
    DW    IE4CR                     ;[4372] CIRCLE
    DW    IE6CR                     ;[4374] TRIANGLE
    DW    IMON                      ;[4376] CLW
    DW    IREM                      ;[4378] @@@@@@
    DW    IREM                      ;[437A] @@@@@@
    DW    IREM                      ;[437C] @@@@@@
    DW    IREM                      ;[437E] @@@@@@
    DW    IREM                      ;[4380] @@@@@@
    DW    IREM                      ;[4382] @@@@@@
;
; Dispatch table for EXT execution
;
XE96KS:
    DW    EXPL                      ;[4384] EXPLODE
    DW    EKLX                      ;[4386] KLAXON
    DW    ELSR                      ;[4388] LASER
    DW    EZAP                      ;[438A] ZAP
    DW    $44D5                     ;[438C] STORE
    DW    $452C                     ;[438E] ISTORE
    DW    $4596                     ;[4390] FETCH
    DW    $45C1                     ;[4392] WIPE
    DW    $45E2                     ;[4394] BACK
    DW    $465B                     ;[4396] SSAVE
    DW    $45F1                     ;[4398] SLOAD
    DW    $4665                     ;[439A] CSAVE
    DW    $46C1                     ;[439C] CHAIN
    DW    $46F8                     ;[439E] TRAP
    DW    $4708                     ;[43A0] NOTRAP
    DW    $4800                     ;[43A2] PPRINT
    DW    $484E                     ;[43A4] SPRINT
    DW    $49FB                     ;[43A6] VRESET
    DW    $4ACA                     ;[43A8] CIRCLE
    DW    $4D18                     ;[43AA] TRIANGLE
    DW    $4F1B                     ;[43AC] CLW
    DW    ERR_NOT_YET_IMP           ;[43AE] @@@@@@
    DW    ERR_NOT_YET_IMP           ;[43B0] @@@@@@
    DW    ERR_NOT_YET_IMP           ;[43B2] @@@@@@
    DW    ERR_NOT_YET_IMP           ;[43B4] @@@@@@
    DW    ERR_NOT_YET_IMP           ;[43B6] @@@@@@
    DW    ERR_NOT_YET_IMP           ;[43B8] @@@@@@
;
;
;
    LD    HL,$9FFF                  ;[43BA] 21 ff 9f
    LD    DE,$BFFF                  ;[43BD] 11 ff bf
    LD    A,(DE)                    ;[43C0] 1a
    CPL                             ;[43C1] 2f
    LD    (DE),A                    ;[43C2] 12
    LD    C,(HL)                    ;[43C3] 4e
    CPL                             ;[43C4] 2f
    LD    (DE),A                    ;[43C5] 12
    LD    A,(HL)                    ;[43C6] 7e
    CP    C                         ;[43C7] b9
    JR    Z,$43D0                   ;[43C8] 28 06
    LD    A,$80                     ;[43CA] 3e 80
    LD    ($61C7),A                 ;[43CC] 32 c7 61
    RET                             ;[43CF] c9

    LD    A,($61C6)                 ;[43D0] 3a c6 61
    LD    H,A                       ;[43D3] 67
    LD    L,$00                     ;[43D4] 2e 00
    INC   A                         ;[43D6] 3c
    LD    (HL),A                    ;[43D7] 77
    INC   H                         ;[43D8] 24
    CP    $5F                       ;[43D9] fe 5f
    JR    NZ,$43D6                  ;[43DB] 20 f9
    LD    (HL),$FF                  ;[43DD] 36 ff
    LD    H,$3F                     ;[43DF] 26 3f
    LD    (HL),$41                  ;[43E1] 36 41
    LD    HL,$61C8                  ;[43E3] 21 c8 61
    LD    DE,S                      ;[43E6] 11 80 00
    LD    B,$30                     ;[43E9] 06 30
    PUSH  BC                        ;[43EB] c5
    LD    BC,RANDOM                 ;[43EC] 01 08 00
    PUSH  HL                        ;[43EF] e5
    LDIR                            ;[43F0] ed b0
    POP   HL                        ;[43F2] e1
    POP   BC                        ;[43F3] c1
    DJNZ  $43EB                     ;[43F4] 10 f5
    RET                             ;[43F6] c9

    LD    HL,$61C7                  ;[43F7] 21 c7 61
    BIT   7,(HL)                    ;[43FA] cb 7e
    CALL  NZ,ERR_NOT_YET_IMP        ;[43FC] c4 32 3b
    PUSH  HL                        ;[43FF] e5
    RST   $18                       ;[4400] df
    INC   DE                        ;[4401] 13
    DEC   H                         ;[4402] 25
    INC   H                         ;[4403] 24
    CALL  NZ,ERR_NUM_OUT_RANGE      ;[4404] c4 29 3b
    DEC   A                         ;[4407] 3d
    CP    $30                       ;[4408] fe 30
    CALL  NC,ERR_NUM_OUT_RANGE      ;[440A] d4 29 3b
    INC   A                         ;[440D] 3c
    POP   HL                        ;[440E] e1
    BIT   6,(HL)                    ;[440F] cb 76
    JR    Z,$4417                   ;[4411] 28 04
    RES   6,(HL)                    ;[4413] cb b6
    CP    (HL)                      ;[4415] be
    RET   Z                         ;[4416] c8
    LD    (HL),A                    ;[4417] 77
    DEC   A                         ;[4418] 3d
    LD    H,$00                     ;[4419] 26 00
    LD    L,A                       ;[441B] 6f
    ADD   HL,HL                     ;[441C] 29
    ADD   HL,HL                     ;[441D] 29
    ADD   HL,HL                     ;[441E] 29
    PUSH  DE                        ;[441F] d5
    LD    DE,S                      ;[4420] 11 80 00
    ADD   HL,DE                     ;[4423] 19
    LD    DE,$61C8                  ;[4424] 11 c8 61
    LD    BC,RANDOM                 ;[4427] 01 08 00
    CALL  ELDIR                     ;[442A] cd 27 40
    POP   DE                        ;[442D] d1
    RET                             ;[442E] c9

    LD    HL,$61C7                  ;[442F] 21 c7 61
    LD    A,(HL)                    ;[4432] 7e
    SET   6,(HL)                    ;[4433] cb f6
    DEC   A                         ;[4435] 3d
    LD    H,$00                     ;[4436] 26 00
    LD    L,A                       ;[4438] 6f
    ADD   HL,HL                     ;[4439] 29
    ADD   HL,HL                     ;[443A] 29
    ADD   HL,HL                     ;[443B] 29
    LD    DE,S                      ;[443C] 11 80 00
    ADD   HL,DE                     ;[443F] 19
    EX    DE,HL                     ;[4440] eb
    LD    HL,$61C8                  ;[4441] 21 c8 61
    LD    BC,RANDOM                 ;[4444] 01 08 00
    LDIR                            ;[4447] ed b0
    RET                             ;[4449] c9

    LD    HL,($61CA)                ;[444A] 2a ca 61
    LD    L,$00                     ;[444D] 2e 00
    LD    A,H                       ;[444F] 7c
    CP    $FF                       ;[4450] fe ff
    LD    A,($61C6)                 ;[4452] 3a c6 61
    JR    Z,$4459                   ;[4455] 28 02
    LD    (HL),A                    ;[4457] 77
    RET                             ;[4458] c9

    LD    H,A                       ;[4459] 67
    LD    ($61C9),A                 ;[445A] 32 c9 61
    LD    ($61CA),HL                ;[445D] 22 ca 61
    LD    ($61CC),HL                ;[4460] 22 cc 61
    LD    H,$00                     ;[4463] 26 00
    LD    ($61CE),HL                ;[4465] 22 ce 61
    CP    $FF                       ;[4468] fe ff
    RET                             ;[446A] c9
DETACH:
    LD    HL,($61CA)                ;[446B] 2a ca 61
    LD    A,H                       ;[446E] 7c
    CP    $FF                       ;[446F] fe ff
    RET   Z                         ;[4471] c8
    LD    L,$00                     ;[4472] 2e 00
    CALL  LAHL                      ;[4474] cd 17 40
    LD    (HL),$FF                  ;[4477] 36 ff
    LD    ($61C6),A                 ;[4479] 32 c6 61
    RET                             ;[447C] c9
;
; Input syntax for STORE
;
    CALL  TEST_IS_COMMA             ;[447D] cd 0d 27
    RST   $10                       ;[4480] d7
    CP    $0D                       ;[4481] fe 0d
    CALL  Z,ERR_SOMETHG_MISSG       ;[4483] cc 38 3b
    CALL  TEST_FOR_STR_EXP          ;[4486] cd 4b 2b
    JR    NZ,$4491                  ;[4489] 20 06
    CALL  READ_STRING_EXPR          ;[448B] cd 9d 2c
    INC   DE                        ;[448E] 13
    JR    $4494                     ;[448F] 18 03
    CALL  RP                        ;[4491] cd e2 25
    CP    $2C                       ;[4494] fe 2c
    JP    NZ,IMON                   ;[4496] c2 db 26
    LD    (HL),A                    ;[4499] 77
    INC   HL                        ;[449A] 23
    JR    $4480                     ;[449B] 18 e3
    CALL  TEST_IS_COMMA             ;[449D] cd 0d 27
    RST   $10                       ;[44A0] d7
    CP    $0D                       ;[44A1] fe 0d
    CALL  Z,ERR_SOMETHG_MISSG       ;[44A3] cc 38 3b
    CALL  RP                        ;[44A6] cd e2 25
    CP    $2C                       ;[44A9] fe 2c
    JP    NZ,IMON                   ;[44AB] c2 db 26
    LD    (HL),A                    ;[44AE] 77
    INC   HL                        ;[44AF] 23
    JR    $44A0                     ;[44B0] 18 ee
    CALL  TEST_IS_COMMA             ;[44B2] cd 0d 27
    CALL  TEST_FOR_STRING           ;[44B5] cd ea 21
    JR    NZ,$44C0                  ;[44B8] 20 06
    CALL  READ_STRING_VAR           ;[44BA] cd f4 21
    RST   $10                       ;[44BD] d7
    JR    $44C3                     ;[44BE] 18 03
    CALL  IREAD                     ;[44C0] cd 21 27
    LD    (HL),A                    ;[44C3] 77
    CP    $0D                       ;[44C4] fe 0d
    RET   Z                         ;[44C6] c8
    RST   $20                       ;[44C7] e7
    INC   L                         ;[44C8] 2c
    INC   HL                        ;[44C9] 23
    INC   DE                        ;[44CA] 13
    RST   $10                       ;[44CB] d7
    JR    $44B5                     ;[44CC] 18 e7
    CALL  TEST_IS_COMMA             ;[44CE] cd 0d 27
    RST   $10                       ;[44D1] d7
    JP    ILOAD                     ;[44D2] c3 16 26
;
; Write into software file. (EXT STORE)
;
EPWR:
    CALL  WROPEN                    ;[44D5]
EPWR1:
    PUSH  BC                        ;[44D8]
    PUSH  HL                        ;[44D9]
    LD    A,(DE)                    ;[44DA] byte after ','
    CP    SOP                       ;[44DB] start of Polish?
    JR    NZ,EPWR4                  ;[44DD] 
    RST   40                        ;[44DF] number into WRA1
    POP   HL                        ;[44E0] 
    POP   BC                        ;[44E1] 
    PUSH  DE                        ;[44E2] 
    CALL  WRADV                     ;[44E3] 
    LD    (HL),$40                  ;[44E6] means f.p.
    LD    IX,SYSVAR_WRA1            ;[44E8] 
    LD    E,$05                     ;[44EC] 
EPWR2:
    CALL  WRADV                     ;[44EE] 
    LD    A,(IX+$00)                ;[44F1] byte of number
    INC   IX                        ;[44F4] 
    LD    (HL),A                    ;[44F6] into file
    DEC   E                         ;[44F7] 
    JR    NZ,EPWR2                  ;[44F8] 
    POP   DE                        ;[44FA] 
    JR    EPWR7                     ;[44FB] 
EPWR4:
    CALL  STRING_EXEC               ;[44FD] String expr.
    POP   HL                        ;[4500] 
    POP   BC                        ;[4501] 
    PUSH  DE                        ;[4502] 
    CALL  WRADV                     ;[4503] 
    PUSH  HL                        ;[4506] addr for control byte
    LD    E,$80                     ;[4507] init byte
    LD    IX,SYSVAR_STRBUF          ;[4509] point to answer
EPWR5:
    LD    A,(IX+$00)                ;[450D] 
    CP    SZ                        ;[4510] 
    JR    Z,EPWR6                   ;[4512] 
    INC   IX                        ;[4514] 
    CALL  WRADV                     ;[4516] 
    LD    (HL),A                    ;[4519] 
    INC   E                         ;[451A] incr control count
    JR    EPWR5                     ;[451B] 
EPWR6:
    POP   IX                        ;[451D] was HL
    LD    (IX+$00),E                ;[451F] control byte first
    POP   DE                        ;[4522] 
EPWR7:
    LD    A,(DE)                    ;[4523] 
    INC   DE                        ;[4524] 
    CP    ','                       ;[4525] another arg?
    JR    Z,EPWR1                   ;[4527] 
    JP    EIST9                     ;[4529] 
;
; Execute ISTORE
;
EIST:
    CALL  WROPEN                    ;[452C] 
EIST1:
    PUSH  BC                        ;[452F] 
    PUSH  HL                        ;[4530] 
    LD    A,(DE)                    ;[4531] 
    CP    SOP                       ;[4532] Start of polish
    CALL  NZ,ERR_TYPE_MISMATCH      ;[4534] numeric only
    RST   40                        ;[4537] no. to WRA1
    POP   HL                        ;[4538] 
    POP   BC                        ;[4539] 
;
    PUSH  DE                        ;[453A] 
    PUSH  BC                        ;[453B] 
    PUSH  HL                        ;[453C] 
    CALL  FPINT                     ;[453D] Float to int
    EX    DE,HL                     ;[4540] no. to DE
    POP   HL                        ;[4541] 
    POP   BC                        ;[4542] 
    LD    A,$0F                     ;[4543] fits half byte? 
    CP    D                         ;[4545] 
    JR    NC,EIST2                  ;[4546] 
    CALL  WRADV                     ;[4548] 
    LD    (HL),$20                  ;[454B] 
    JR    EIST4                     ;[454D] 
EIST2:
    INC   D                         ;[454F] 
    DEC   D                         ;[4550] 
    JR    NZ,EIST3                  ;[4551] 
    CP    E                         ;[4553] 
    JR    NC,EIST5                  ;[4554]
EIST3:
    SET   4,D                       ;[4556] 
EIST4:
    CALL  WRADV                     ;[4558] 
    LD    (HL),D                    ;[455B] 
EIST5:
    CALL  WRADV                     ;[455C] 
    LD    (HL),E                    ;[455F] 
    POP   DE                        ;[4560] 
    LD    A,(DE)                    ;[4561] 
    INC   DE                        ;[4562] 
    CP    ','                       ;[4563] another arg?
    JR    Z,EIST1                   ;[4565]
EIST9:
    LD    ($61CA),HL                ;[4567] update file info
    LD    ($61CE),BC                ;[456A] 
    CALL  $446B                     ;[456E] 
    CALL  $442F                     ;[4571] 
    RET                             ;[4574] 
;
; Open software file.
;
WROPEN:
    CALL  $43F7                     ;[4575] 
    CALL  $444A                     ;[4578] 
    CALL  Z,ERR_OUT_OF_MEM          ;[457B] 
    LD    HL,($61CA)                ;[457E] 
    LD    BC,($61CE)                ;[4581] 
    RET                             ;[4585] 
;
; Advance write pointer, inc count
;
WRADV:
    INC   BC                        ;[4586] 
    INC   L                         ;[4587] 
    RET   NZ                        ;[4588] 
    PUSH  AF                        ;[4589] 
    CALL  LAHL                      ;[458A] 
    CP    $FF                       ;[458D] 
    CALL  Z,ERR_OUT_OF_MEM          ;[458F] 
    LD    H,A                       ;[4592] 
    INC   L                         ;[4593] 
    POP   AF                        ;[4594] 
    RET                             ;[4595] 
;
    CALL    $43F7                           ;[4596] cd f7 43
    LD      HL,($61CC)                      ;[4599] 2a cc 61
    LD      BC,($61CA)                      ;[459C] ed 4b ca 61
    PUSH    BC                              ;[45A0] c5
    PUSH    HL                              ;[45A1] e5
    CALL    VPTR_IS_STR                     ;[45A2] cd 13 21
    PUSH    HL                              ;[45A5] e5
    POP     IX                              ;[45A6] dd e1
    POP     HL                              ;[45A8] e1
    POP     BC                              ;[45A9] c1
    JR      C,$45B1                         ;[45AA] 38 05
    CALL    $4039                           ;[45AC] cd 39 40
    JR      $45B4                           ;[45AF] 18 03
    CALL    $408B                           ;[45B1] cd 8b 40
    LD      A,(DE)                          ;[45B4] 1a
    INC     DE                              ;[45B5] 13
    CP      $2C                             ;[45B6] fe 2c
    JR      Z,$45A0                         ;[45B8] 28 e6
    LD      ($61CC),HL                      ;[45BA] 22 cc 61
    CALL    $442F                           ;[45BD] cd 2f 44
    RET                                     ;[45C0] c9

    CALL    $43F7                           ;[45C1] cd f7 43
    CALL    $444A                           ;[45C4] cd 4a 44
    LD      HL,$61C9                        ;[45C7] 21 c9 61
    LD      A,(HL)                          ;[45CA] 7e
    LD      ($61C6),A                       ;[45CB] 32 c6 61
    LD      A,$FF                           ;[45CE] 3e ff
    LD      (HL),A                          ;[45D0] 77
    LD      H,A                             ;[45D1] 67
    LD      L,$00                           ;[45D2] 2e 00
    LD      ($61CA),HL                      ;[45D4] 22 ca 61
    LD      ($61CC),HL                      ;[45D7] 22 cc 61
    LD      H,$00                           ;[45DA] 26 00
    LD      ($61CE),HL                      ;[45DC] 22 ce 61
    JP      $442F                           ;[45DF] c3 2f 44
    CALL    $43F7                           ;[45E2] cd f7 43
    LD      A,($61C9)                       ;[45E5] 3a c9 61
    LD      H,A                             ;[45E8] 67
    LD      L,$00                           ;[45E9] 2e 00
    LD      ($61CC),HL                      ;[45EB] 22 cc 61
    JP      $442F                           ;[45EE] c3 2f 44
    CALL    $43F7                           ;[45F1] cd f7 43
    CALL    $444A                           ;[45F4] cd 4a 44
    JR      Z,$464F                         ;[45F7] 28 56
    CALL    TAPE_READ                       ;[45F9] cd 26 0c
    LD      HL,($61CA)                      ;[45FC] 2a ca 61
    CALL    RSYNC                           ;[45FF] cd 65 0b
    CALL    RBYTE                           ;[4602] cd 85 0b
    CP      $44                             ;[4605] fe 44
    JR      NZ,$4655                        ;[4607] 20 4c
    CALL    RBYTE                           ;[4609] cd 85 0b
    LD      C,A                             ;[460C] 4f
    CALL    RBYTE                           ;[460D] cd 85 0b
    LD      B,A                             ;[4610] 47
    PUSH    BC                              ;[4611] c5
    LD      E,$00                           ;[4612] 1e 00
    JR      $462A                           ;[4614] 18 14
    CALL    RBYTE                           ;[4616] cd 85 0b
    LD      D,A                             ;[4619] 57
    ADD     E                               ;[461A] 83
    LD      E,A                             ;[461B] 5f
    INC     L                               ;[461C] 2c
    JR      NZ,$4628                        ;[461D] 20 09
    CALL    LAHL                            ;[461F] cd 17 40
    CP      $FF                             ;[4622] fe ff
    JR      Z,$464F                         ;[4624] 28 29
    LD      H,A                             ;[4626] 67
    INC     L                               ;[4627] 2c
    LD      (HL),D                          ;[4628] 72
    DEC     BC                              ;[4629] 0b
    LD      A,B                             ;[462A] 78
    OR      C                               ;[462B] b1
    JR      NZ,$4616                        ;[462C] 20 e8
    CALL    RBYTE                           ;[462E] cd 85 0b
    CP      E                               ;[4631] bb
    JR      NZ,$4655                        ;[4632] 20 21
    CALL    RBYTE                           ;[4634] cd 85 0b
    LD      ($61CA),HL                      ;[4637] 22 ca 61
    LD      HL,($61CE)                      ;[463A] 2a ce 61
    POP     BC                              ;[463D] c1
    ADD     HL,BC                           ;[463E] 09
    LD      ($61CE),HL                      ;[463F] 22 ce 61
    CP      $4E                             ;[4642] fe 4e
    JR      Z,$45FC                         ;[4644] 28 b6
    CALL    $446B                           ;[4646] cd 6b 44
    CALL    MOTOFF                          ;[4649] cd fb 0c
    JP      $442F                           ;[464C] c3 2f 44
    CALL    MOTOFF                          ;[464F] cd fb 0c
    CALL    ERR_OUT_OF_MEM                  ;[4652] cd 4d 3b
    CALL    MOTOFF                          ;[4655] cd fb 0c
    CALL    ERR_BAD_TAPE                    ;[4658] cd f9 3a
    CALL    $43F7                           ;[465B] cd f7 43
    XOR     A                               ;[465E] af
    LD      ($61C8),A                       ;[465F] 32 c8 61
    JP      $4668                           ;[4662] c3 68 46
    CALL    $43F7                           ;[4665] cd f7 43
    EXX                                     ;[4668] d9
    LD      BC,$FF7F                        ;[4669] 01 7f ff
    LD      DE,$1000                        ;[466C] 11 00 10
    EXX                                     ;[466F] d9
    CALL    WRITE_FNAME                     ;[4670] cd b4 0b
    EXX                                     ;[4673] d9
    LD      A,($61C9)                       ;[4674] 3a c9 61
    LD      H,A                             ;[4677] 67
    LD      L,$00                           ;[4678] 2e 00
    EXX                                     ;[467A] d9
    CALL    WSYNC                           ;[467B] cd 93 0b
    LD      A,$44                           ;[467E] 3e 44
    CALL    SYSVAR_WBYTE                    ;[4680] cd a6 62
    LD      BC,($61CE)                      ;[4683] ed 4b ce 61
    LD      A,C                             ;[4687] 79
    CALL    SYSVAR_WBYTE                    ;[4688] cd a6 62
    LD      A,B                             ;[468B] 78
    CALL    SYSVAR_WBYTE                    ;[468C] cd a6 62
    LD      E,$00                           ;[468F] 1e 00
    JR      $469C                           ;[4691] 18 09
    CALL    $40D4                           ;[4693] cd d4 40
    CALL    SYSVAR_WBYTE                    ;[4696] cd a6 62
    ADD     E                               ;[4699] 83
    LD      E,A                             ;[469A] 5f
    DEC     BC                              ;[469B] 0b
    LD      A,B                             ;[469C] 78
    OR      C                               ;[469D] b1
    JR      NZ,$4693                        ;[469E] 20 f3
    LD      A,E                             ;[46A0] 7b
    CALL    SYSVAR_WBYTE                    ;[46A1] cd a6 62
    LD      A,($61C8)                       ;[46A4] 3a c8 61
    OR      A                               ;[46A7] b7
    JR      Z,$46B6                         ;[46A8] 28 0c
    LD      D,A                             ;[46AA] 57
    LD      A,$4E                           ;[46AB] 3e 4e
    CALL    SYSVAR_WBYTE                    ;[46AD] cd a6 62
    LD      A,D                             ;[46B0] 7a
    CALL    $4418                           ;[46B1] cd 18 44
    JR      $4673                           ;[46B4] 18 bd
    LD      A,$45                           ;[46B6] 3e 45
    CALL    SYSVAR_WBYTE                    ;[46B8] cd a6 62
    CALL    SYSVAR_WBYTE                    ;[46BB] cd a6 62
    JP      MOTOFF                          ;[46BE] c3 fb 0c
    CALL    $43F7                           ;[46C1] cd f7 43
    RST     $18                             ;[46C4] df
    DEC     H                               ;[46C5] 25
    INC     H                               ;[46C6] 24
    CALL    NZ,ERR_NUM_OUT_RANGE            ;[46C7] c4 29 3b
    CP      $31                             ;[46CA] fe 31
    CALL    NC,ERR_NUM_OUT_RANGE            ;[46CC] d4 29 3b
    LD      C,A                             ;[46CF] 4f
    LD      HL,$61C7                        ;[46D0] 21 c7 61
    LD      B,(HL)                          ;[46D3] 46
    JR      $46E4                           ;[46D4] 18 0e
    DEC     A                               ;[46D6] 3d
    LD      H,$00                           ;[46D7] 26 00
    LD      L,A                             ;[46D9] 6f
    ADD     HL,HL                           ;[46DA] 29
    ADD     HL,HL                           ;[46DB] 29
    ADD     HL,HL                           ;[46DC] 29
    LD      DE,S                            ;[46DD] 11 80 00
    ADD     HL,DE                           ;[46E0] 19
    CALL    LAHL                            ;[46E1] cd 17 40
    CP      B                               ;[46E4] b8
    CALL    Z,ERR_OVERFLOW                  ;[46E5] cc 3e 3b
    OR      A                               ;[46E8] b7
    JR      NZ,$46D6                        ;[46E9] 20 eb
    LD      HL,$61C8                        ;[46EB] 21 c8 61
    LD      (HL),C                          ;[46EE] 71
    JP      $442F                           ;[46EF] c3 2f 44
    CALL    IREAD                           ;[46F2] cd 21 27
    JP      IMON                            ;[46F5] c3 db 26
    CALL    GET_VAR_ADDR                    ;[46F8] cd 18 22
    LD      ($61D0),HL                      ;[46FB] 22 d0 61
    EX      DE,HL                           ;[46FE] eb
    LD      HL,FLOAT_ZERO                   ;[46FF] 21 05 36
    LD      BC,NEXT                         ;[4702] 01 05 00
    LDIR                                    ;[4705] ed b0
    RET                                     ;[4707] c9

    LD      HL,LET                          ;[4708] 21 00 00
    LD      ($61D0),HL                      ;[470B] 22 d0 61
    RET                                     ;[470E] c9

    LD      HL,ERROR_PRINT                  ;[470F] 21 56 3b
    EX      (SP),HL                         ;[4712] e3
    LD      C,A                             ;[4713] 4f
    LD      HL,(SYSVAR_CURRLP)              ;[4714] 2a f6 61
    LD      A,(HL)                          ;[4717] 7e
    CP      $80                             ;[4718] fe 80
    JR      Z,$4740                         ;[471A] 28 24
    LD      HL,($61D0)                      ;[471C] 2a d0 61
    LD      A,H                             ;[471F] 7c
    OR      L                               ;[4720] b5
    JR      Z,$4735                         ;[4721] 28 12
    PUSH    HL                              ;[4723] e5
    LD      L,C                             ;[4724] 69
    LD      H,$00                           ;[4725] 26 00
    CALL    INTFP                           ;[4727] cd c4 34
    LD      HL,SYSVAR_WRA1                  ;[472A] 21 e5 62
    POP     DE                              ;[472D] d1
    LD      BC,NEXT                         ;[472E] 01 05 00
    LDIR                                    ;[4731] ed b0
    JR      $4739                           ;[4733] 18 04
    LD      A,C                             ;[4735] 79
    OR      A                               ;[4736] b7
    JR      NZ,$4740                        ;[4737] 20 07
    LD      SP,($61D2)                      ;[4739] ed 7b d2 61
    JP      EXEC2                           ;[473D] c3 be 24
    LD      HL,(SYSVAR_ERRTBL)                      ;[4740] 2a 9a 62
    LD      A,C                             ;[4743] 79
    RET                                     ;[4744] c9

    POP     HL                              ;[4745] e1
    LD      ($61D2),SP                      ;[4746] ed 73 d2 61
    JP      (HL)                            ;[474A] e9
    RST     $38                             ;[474B] ff
    RST     $38                             ;[474C] ff
    RST     $38                             ;[474D] ff
    RST     $38                             ;[474E] ff
    RST     $38                             ;[474F] ff
    RST     $38                             ;[4750] ff
    RST     $38                             ;[4751] ff
    RST     $38                             ;[4752] ff
    RST     $38                             ;[4753] ff
    RST     $38                             ;[4754] ff
    RST     $38                             ;[4755] ff
    RST     $38                             ;[4756] ff
    RST     $38                             ;[4757] ff
    RST     $38                             ;[4758] ff
    RST     $38                             ;[4759] ff
    RST     $38                             ;[475A] ff
    RST     $38                             ;[475B] ff
    RST     $38                             ;[475C] ff
    RST     $38                             ;[475D] ff
    RST     $38                             ;[475E] ff
    RST     $38                             ;[475F] ff
    RST     $38                             ;[4760] ff
    RST     $38                             ;[4761] ff
    RST     $38                             ;[4762] ff
    RST     $38                             ;[4763] ff
    RST     $38                             ;[4764] ff
    RST     $38                             ;[4765] ff
    RST     $38                             ;[4766] ff
    RST     $38                             ;[4767] ff
    RST     $38                             ;[4768] ff
    RST     $38                             ;[4769] ff
    RST     $38                             ;[476A] ff
    RST     $38                             ;[476B] ff
    RST     $38                             ;[476C] ff
    RST     $38                             ;[476D] ff
    RST     $38                             ;[476E] ff
    RST     $38                             ;[476F] ff
    RST     $38                             ;[4770] ff
    RST     $38                             ;[4771] ff
    RST     $38                             ;[4772] ff
    RST     $38                             ;[4773] ff
    RST     $38                             ;[4774] ff
    RST     $38                             ;[4775] ff
    RST     $38                             ;[4776] ff
    RST     $38                             ;[4777] ff
    RST     $38                             ;[4778] ff
    RST     $38                             ;[4779] ff
    RST     $38                             ;[477A] ff
    RST     $38                             ;[477B] ff
    RST     $38                             ;[477C] ff
    RST     $38                             ;[477D] ff
    RST     $38                             ;[477E] ff
    RST     $38                             ;[477F] ff
    RST     $38                             ;[4780] ff
    RST     $38                             ;[4781] ff
    RST     $38                             ;[4782] ff
    RST     $38                             ;[4783] ff
    RST     $38                             ;[4784] ff
    RST     $38                             ;[4785] ff
    RST     $38                             ;[4786] ff
    RST     $38                             ;[4787] ff
    RST     $38                             ;[4788] ff
    RST     $38                             ;[4789] ff
    RST     $38                             ;[478A] ff
    RST     $38                             ;[478B] ff
    RST     $38                             ;[478C] ff
    RST     $38                             ;[478D] ff
    RST     $38                             ;[478E] ff
    RST     $38                             ;[478F] ff
    RST     $38                             ;[4790] ff
    RST     $38                             ;[4791] ff
    RST     $38                             ;[4792] ff
    RST     $38                             ;[4793] ff
    RST     $38                             ;[4794] ff
    RST     $38                             ;[4795] ff
    RST     $38                             ;[4796] ff
    RST     $38                             ;[4797] ff
    RST     $38                             ;[4798] ff
    RST     $38                             ;[4799] ff
    RST     $38                             ;[479A] ff
    RST     $38                             ;[479B] ff
    RST     $38                             ;[479C] ff
    RST     $38                             ;[479D] ff
    RST     $38                             ;[479E] ff
    RST     $38                             ;[479F] ff
    RST     $38                             ;[47A0] ff
    RST     $38                             ;[47A1] ff
    RST     $38                             ;[47A2] ff
    RST     $38                             ;[47A3] ff
    RST     $38                             ;[47A4] ff
    RST     $38                             ;[47A5] ff
    RST     $38                             ;[47A6] ff
    RST     $38                             ;[47A7] ff
    RST     $38                             ;[47A8] ff
    RST     $38                             ;[47A9] ff
    RST     $38                             ;[47AA] ff
    RST     $38                             ;[47AB] ff
    RST     $38                             ;[47AC] ff
    RST     $38                             ;[47AD] ff
    RST     $38                             ;[47AE] ff
    RST     $38                             ;[47AF] ff
    RST     $38                             ;[47B0] ff
    RST     $38                             ;[47B1] ff
    RST     $38                             ;[47B2] ff
    RST     $38                             ;[47B3] ff
    RST     $38                             ;[47B4] ff
    RST     $38                             ;[47B5] ff
    RST     $38                             ;[47B6] ff
    RST     $38                             ;[47B7] ff
    RST     $38                             ;[47B8] ff
    RST     $38                             ;[47B9] ff
    RST     $38                             ;[47BA] ff
    RST     $38                             ;[47BB] ff
    RST     $38                             ;[47BC] ff
    RST     $38                             ;[47BD] ff
    RST     $38                             ;[47BE] ff
    RST     $38                             ;[47BF] ff
    RST     $38                             ;[47C0] ff
    RST     $38                             ;[47C1] ff
    RST     $38                             ;[47C2] ff
    RST     $38                             ;[47C3] ff
    RST     $38                             ;[47C4] ff
    RST     $38                             ;[47C5] ff
    RST     $38                             ;[47C6] ff
    RST     $38                             ;[47C7] ff
    RST     $38                             ;[47C8] ff
    RST     $38                             ;[47C9] ff
    RST     $38                             ;[47CA] ff
    RST     $38                             ;[47CB] ff
    RST     $38                             ;[47CC] ff
    RST     $38                             ;[47CD] ff
    RST     $38                             ;[47CE] ff
    RST     $38                             ;[47CF] ff
    RST     $38                             ;[47D0] ff
    RST     $38                             ;[47D1] ff
    RST     $38                             ;[47D2] ff
    RST     $38                             ;[47D3] ff
    RST     $38                             ;[47D4] ff
    RST     $38                             ;[47D5] ff
    RST     $38                             ;[47D6] ff
    RST     $38                             ;[47D7] ff
    RST     $38                             ;[47D8] ff
    RST     $38                             ;[47D9] ff
    RST     $38                             ;[47DA] ff
    RST     $38                             ;[47DB] ff
    RST     $38                             ;[47DC] ff
    RST     $38                             ;[47DD] ff
    RST     $38                             ;[47DE] ff
    RST     $38                             ;[47DF] ff
    RST     $38                             ;[47E0] ff
    RST     $38                             ;[47E1] ff
    RST     $38                             ;[47E2] ff
    RST     $38                             ;[47E3] ff
    RST     $38                             ;[47E4] ff
    RST     $38                             ;[47E5] ff
    RST     $38                             ;[47E6] ff
    RST     $38                             ;[47E7] ff
    RST     $38                             ;[47E8] ff
    RST     $38                             ;[47E9] ff
    RST     $38                             ;[47EA] ff
    RST     $38                             ;[47EB] ff
    RST     $38                             ;[47EC] ff
    RST     $38                             ;[47ED] ff
    RST     $38                             ;[47EE] ff
    RST     $38                             ;[47EF] ff
    RST     $38                             ;[47F0] ff
    RST     $38                             ;[47F1] ff
    RST     $38                             ;[47F2] ff
    RST     $38                             ;[47F3] ff
    RST     $38                             ;[47F4] ff
    RST     $38                             ;[47F5] ff
    RST     $38                             ;[47F6] ff
    RST     $38                             ;[47F7] ff
    RST     $38                             ;[47F8] ff
    RST     $38                             ;[47F9] ff
    RST     $38                             ;[47FA] ff
    RST     $38                             ;[47FB] ff
    RST     $38                             ;[47FC] ff
    RST     $38                             ;[47FD] ff
    RST     $38                             ;[47FE] ff
    RST     $38                             ;[47FF] ff
    PUSH    AF                              ;[4800] f5
    PUSH    HL                              ;[4801] e5
    PUSH    DE                              ;[4802] d5
    PUSH    BC                              ;[4803] c5
    IN      A,($7D)                         ;[4804] db 7d
    LD      HL,$48CB                        ;[4806] 21 cb 48
    LD      (SYSVAR_LPRNTD),HL              ;[4809] 22 02 62
    LD      HL,$4847                        ;[480C] 21 47 48
    LD      DE,$61BC                        ;[480F] 11 bc 61
    LD      BC,PAPER                        ;[4812] 01 07 00
    LDIR                                    ;[4815] ed b0
    POP     BC                              ;[4817] c1
    POP     DE                              ;[4818] d1
    POP     HL                              ;[4819] e1
    POP     AF                              ;[481A] f1
    RET                                     ;[481B] c9

    LD      L,A                             ;[481C] 6f
    LD      BC,S                            ;[481D] 01 80 00
    IN      A,(C)                           ;[4820] ed 78
    BIT     6,A                             ;[4822] cb 77
    RET     Z                               ;[4824] c8
    IN      A,($7C)                         ;[4825] db 7c
    BIT     0,A                             ;[4827] cb 47
    JR      Z,$4820                         ;[4829] 28 f5
    BIT     1,A                             ;[482B] cb 4f
    RET     Z                               ;[482D] c8
    LD      A,L                             ;[482E] 7d
    OUT     ($7E),A                         ;[482F] d3 7e
    CP      $20                             ;[4831] fe 20
    CALL    C,$4963                         ;[4833] dc 63 49
    LD      HL,$61C2                        ;[4836] 21 c2 61
    JR      C,$4844                         ;[4839] 38 09
    INC     (HL)                            ;[483B] 34
    LD      A,($61C1)                       ;[483C] 3a c1 61
    CP      (HL)                            ;[483F] be
    RET     NC                              ;[4840] d0
    LD      (HL),$01                        ;[4841] 36 01
    RET                                     ;[4843] c9

    LD      (HL),$00                        ;[4844] 36 00
    RET                                     ;[4846] c9

    NOP                                     ;[4847] 00
    INC     H                               ;[4848] 24
    EX      AF,AF'                          ;[4849] 08
    ADD     B                               ;[484A] 80
    RRCA                                    ;[484B] 0f
    LD      D,B                             ;[484C] 50
    NOP                                     ;[484D] 00
    PUSH    AF                              ;[484E] f5
    PUSH    HL                              ;[484F] e5
    PUSH    DE                              ;[4850] d5
    PUSH    BC                              ;[4851] c5
    LD      HL,$48D0                        ;[4852] 21 d0 48
    LD      (SYSVAR_LPRNTD),HL              ;[4855] 22 02 62
    LD      HL,$48C1                        ;[4858] 21 c1 48
    LD      DE,$61BC                        ;[485B] 11 bc 61
    LD      BC,DOKE                         ;[485E] 01 0a 00
    LDIR                                    ;[4861] ed b0
    POP     BC                              ;[4863] c1
    POP     DE                              ;[4864] d1
    POP     HL                              ;[4865] e1
    POP     AF                              ;[4866] f1
    RET                                     ;[4867] c9

    PUSH    AF                              ;[4868] f5
    LD      C,A                             ;[4869] 4f
    IN      A,($84)                         ;[486A] db 84
    BIT     6,A                             ;[486C] cb 77
    JR      Z,$486A                         ;[486E] 28 fa
    LD      A,C                             ;[4870] 79
    OUT     ($82),A                         ;[4871] d3 82
    LD      A,($61C3)                       ;[4873] 3a c3 61
    LD      B,$05                           ;[4876] 06 05
    CALL    $48B0                           ;[4878] cd b0 48
    LD      A,C                             ;[487B] 79
    CP      $20                             ;[487C] fe 20
    CALL    C,$4963                         ;[487E] dc 63 49
    LD      HL,$61C2                        ;[4881] 21 c2 61
    JR      C,$4891                         ;[4884] 38 0b
    INC     (HL)                            ;[4886] 34
    LD      A,($61C1)                       ;[4887] 3a c1 61
    CP      (HL)                            ;[488A] be
    JR      NC,$48A3                        ;[488B] 30 16
    LD      (HL),$01                        ;[488D] 36 01
    JR      $4894                           ;[488F] 18 03
    LD      A,(HL)                          ;[4891] 7e
    LD      (HL),$00                        ;[4892] 36 00
    ADD     $10                             ;[4894] c6 10
    LD      B,A                             ;[4896] 47
    PUSH    BC                              ;[4897] c5
    LD      A,($61C4)                       ;[4898] 3a c4 61
    LD      B,$05                           ;[489B] 06 05
    CALL    $48B0                           ;[489D] cd b0 48
    POP     BC                              ;[48A0] c1
    DJNZ    $4897                           ;[48A1] 10 f4
    POP     AF                              ;[48A3] f1
    CP      $0C                             ;[48A4] fe 0c
    RET     NZ                              ;[48A6] c0
    LD      A,($61C5)                       ;[48A7] 3a c5 61
    LD      B,$0E                           ;[48AA] 06 0e
    CALL    $48B0                           ;[48AC] cd b0 48
    RET                                     ;[48AF] c9

    LD      HL,VDU                          ;[48B0] 21 01 00
    ADD     HL,HL                           ;[48B3] 29
    DJNZ    $48B3                           ;[48B4] 10 fd
    LD      B,A                             ;[48B6] 47
    PUSH    HL                              ;[48B7] e5
    DEC     HL                              ;[48B8] 2b
    LD      A,L                             ;[48B9] 7d
    OR      H                               ;[48BA] b4
    JR      NZ,$48B8                        ;[48BB] 20 fb
    POP     HL                              ;[48BD] e1
    DJNZ    $48B7                           ;[48BE] 10 f7
    RET                                     ;[48C0] c9

    NOP                                     ;[48C1] 00
    LD      ($C008),HL                      ;[48C2] 22 08 c0
    RRA                                     ;[48C5] 1f
    LD      D,B                             ;[48C6] 50
    NOP                                     ;[48C7] 00
    LD      B,C                             ;[48C8] 41
    ADD     A                               ;[48C9] 87
    ADD     A                               ;[48CA] 87
    PUSH    DE                              ;[48CB] d5
    LD      E,$00                           ;[48CC] 1e 00
    JR      $48D3                           ;[48CE] 18 03
    PUSH    DE                              ;[48D0] d5
    LD      E,$01                           ;[48D1] 1e 01
    PUSH    AF                              ;[48D3] f5
    PUSH    HL                              ;[48D4] e5
    PUSH    BC                              ;[48D5] c5
    CP      $20                             ;[48D6] fe 20
    CALL    C,$48F2                         ;[48D8] dc f2 48
    JR      NC,$48E2                        ;[48DB] 30 05
    CALL    $490C                           ;[48DD] cd 0c 49
    JR      $48E5                           ;[48E0] 18 03
    CALL    $48EA                           ;[48E2] cd ea 48
    POP     BC                              ;[48E5] c1
    POP     HL                              ;[48E6] e1
    POP     AF                              ;[48E7] f1
    POP     DE                              ;[48E8] d1
    RET                                     ;[48E9] c9

    BIT     0,E                             ;[48EA] cb 43
    JP      Z,$481C                         ;[48EC] ca 1c 48
    JP      $4868                           ;[48EF] c3 68 48
    LD      C,A                             ;[48F2] 4f
    SRL     A                               ;[48F3] cb 3f
    SRL     A                               ;[48F5] cb 3f
    SRL     A                               ;[48F7] cb 3f
    LD      HL,$61BC                        ;[48F9] 21 bc 61
    ADD     L                               ;[48FC] 85
    JR      NC,$4900                        ;[48FD] 30 01
    INC     H                               ;[48FF] 24
    LD      L,A                             ;[4900] 6f
    LD      A,C                             ;[4901] 79
    AND     $07                             ;[4902] e6 07
    LD      B,A                             ;[4904] 47
    INC     B                               ;[4905] 04
    LD      A,(HL)                          ;[4906] 7e
    RRA                                     ;[4907] 1f
    DJNZ    $4907                           ;[4908] 10 fd
    LD      A,C                             ;[490A] 79
    RET                                     ;[490B] c9

    LD      HL,$4943                        ;[490C] 21 43 49
    LD      B,$00                           ;[490F] 06 00
    LD      C,A                             ;[4911] 4f
    ADD     HL,BC                           ;[4912] 09
    LD      A,(HL)                          ;[4913] 7e
    OR      A                               ;[4914] b7
    RET     Z                               ;[4915] c8
    CP      $09                             ;[4916] fe 09
    JR      NZ,$4934                        ;[4918] 20 1a
    LD      A,($61C2)                       ;[491A] 3a c2 61
    LD      B,A                             ;[491D] 47
    AND     $F8                             ;[491E] e6 f8
    ADD     $08                             ;[4920] c6 08
    LD      HL,$61C1                        ;[4922] 21 c1 61
    CP      (HL)                            ;[4925] be
    JR      NC,$493D                        ;[4926] 30 15
    SUB     B                               ;[4928] 90
    LD      B,A                             ;[4929] 47
    LD      A,$20                           ;[492A] 3e 20
    PUSH    BC                              ;[492C] c5
    CALL    $48EA                           ;[492D] cd ea 48
    POP     BC                              ;[4930] c1
    DJNZ    $492A                           ;[4931] 10 f7
    RET                                     ;[4933] c9

    CP      $13                             ;[4934] fe 13
    JR      NZ,$493F                        ;[4936] 20 07
    LD      A,($61C2)                       ;[4938] 3a c2 61
    OR      A                               ;[493B] b7
    RET     Z                               ;[493C] c8
    LD      A,$0A                           ;[493D] 3e 0a
    CALL    $48EA                           ;[493F] cd ea 48
    RET                                     ;[4942] c9

    NOP                                     ;[4943] 00
    NOP                                     ;[4944] 00
    NOP                                     ;[4945] 00
    NOP                                     ;[4946] 00
    INC     C                               ;[4947] 0c
    NOP                                     ;[4948] 00
    NOP                                     ;[4949] 00
    NOP                                     ;[494A] 00
    NOP                                     ;[494B] 00
    ADD     HL,BC                           ;[494C] 09
    NOP                                     ;[494D] 00
    NOP                                     ;[494E] 00
    LD      A,(BC)                          ;[494F] 0a
    LD      A,(BC)                          ;[4950] 0a
    NOP                                     ;[4951] 00
    NOP                                     ;[4952] 00
    INC     C                               ;[4953] 0c
    NOP                                     ;[4954] 00
    NOP                                     ;[4955] 00
    INC     DE                              ;[4956] 13
    NOP                                     ;[4957] 00
    NOP                                     ;[4958] 00
    EX      AF,AF'                          ;[4959] 08
    NOP                                     ;[495A] 00
    NOP                                     ;[495B] 00
    NOP                                     ;[495C] 00
    NOP                                     ;[495D] 00
    NOP                                     ;[495E] 00
    NOP                                     ;[495F] 00
    NOP                                     ;[4960] 00
    NOP                                     ;[4961] 00
    LD      A,(BC)                          ;[4962] 0a
    LD      HL,$61C0                        ;[4963] 21 c0 61
    LD      C,(HL)                          ;[4966] 4e
    LD      B,$06                           ;[4967] 06 06
    LD      HL,$4979                        ;[4969] 21 79 49
    CP      (HL)                            ;[496C] be
    JR      Z,$4976                         ;[496D] 28 07
    INC     HL                              ;[496F] 23
    RR      C                               ;[4970] cb 19
    DJNZ    $496C                           ;[4972] 10 f8
    LD      C,$00                           ;[4974] 0e 00
    RR      C                               ;[4976] cb 19
    RET                                     ;[4978] c9

    LD      A,(BC)                          ;[4979] 0a
    DEC     C                               ;[497A] 0d
    INC     D                               ;[497B] 14
    INC     C                               ;[497C] 0c
    DEC     BC                              ;[497D] 0b
    EX      AF,AF'                          ;[497E] 08
    NOP                                     ;[497F] 00
    NOP                                     ;[4980] 00
    CALL    FPINT                           ;[4981] cd 97 34
    DEC     H                               ;[4984] 25
    INC     H                               ;[4985] 24
    CALL    NZ,ERR_NUM_OUT_RANGE            ;[4986] c4 29 3b
    LD      C,$87                           ;[4989] 0e 87
    LD      A,$11                           ;[498B] 3e 11
    OUT     ($86),A                         ;[498D] d3 86
    IN      E,(C)                           ;[498F] ed 58
    INC     L                               ;[4991] 2c
    DEC     L                               ;[4992] 2d
    JR      Z,$49AD                         ;[4993] 28 18
    DEC     L                               ;[4995] 2d
    CALL    NZ,ERR_NUM_OUT_RANGE            ;[4996] c4 29 3b
    DEC     A                               ;[4999] 3d
    OUT     ($86),A                         ;[499A] d3 86
    IN      D,(C)                           ;[499C] ed 50
    EX      DE,HL                           ;[499E] eb
    ADD     HL,HL                           ;[499F] 29
    ADD     HL,HL                           ;[49A0] 29
    ADD     HL,HL                           ;[49A1] 29
    LD      A,($61D4)                       ;[49A2] 3a d4 61
    AND     $0F                             ;[49A5] e6 0f
    RLCA                                    ;[49A7] 07
    SUB     $10                             ;[49A8] d6 10
    ADD     H                               ;[49AA] 84
    JR      $49BE                           ;[49AB] 18 11
    SLA     E                               ;[49AD] cb 23
    SLA     E                               ;[49AF] cb 23
    SLA     E                               ;[49B1] cb 23
    LD      A,($61D4)                       ;[49B3] 3a d4 61
    AND     $F0                             ;[49B6] e6 f0
    RRCA                                    ;[49B8] 0f
    RRCA                                    ;[49B9] 0f
    RRCA                                    ;[49BA] 0f
    SUB     $28                             ;[49BB] d6 28
    ADD     E                               ;[49BD] 83
    LD      L,A                             ;[49BE] 6f
    LD      H,$00                           ;[49BF] 26 00
    JP      INTFP                           ;[49C1] c3 c4 34
    CALL    FPINT                           ;[49C4] cd 97 34
    DEC     H                               ;[49C7] 25
    INC     H                               ;[49C8] 24
    CALL    NZ,ERR_NUM_OUT_RANGE            ;[49C9] c4 29 3b
    LD      C,$7A                           ;[49CC] 0e 7a
    INC     L                               ;[49CE] 2c
    DEC     L                               ;[49CF] 2d
    JR      Z,$49D7                         ;[49D0] 28 05
    DEC     L                               ;[49D2] 2d
    CALL    NZ,ERR_NUM_OUT_RANGE            ;[49D3] c4 29 3b
    INC     C                               ;[49D6] 0c
    IN      A,(C)                           ;[49D7] ed 78
    CPL                                     ;[49D9] 2f
    PUSH    AF                              ;[49DA] f5
    AND     $0F                             ;[49DB] e6 0f
    LD      E,A                             ;[49DD] 5f
    LD      D,$00                           ;[49DE] 16 00
    LD      HL,$49F0                        ;[49E0] 21 f0 49
    ADD     HL,DE                           ;[49E3] 19
    LD      L,(HL)                          ;[49E4] 6e
    LD      H,$00                           ;[49E5] 26 00
    POP     AF                              ;[49E7] f1
    BIT     5,A                             ;[49E8] cb 6f
    JR      Z,$49ED                         ;[49EA] 28 01
    INC     H                               ;[49EC] 24
    JP      INTFP                           ;[49ED] c3 c4 34
    NOP                                     ;[49F0] 00
    EX      AF,AF'                          ;[49F1] 08
    INC     B                               ;[49F2] 04
    NOP                                     ;[49F3] 00
    LD      B,$07                           ;[49F4] 06 07
    DEC     B                               ;[49F6] 05
    NOP                                     ;[49F7] 00
    LD      (BC),A                          ;[49F8] 02
    LD      BC,$AF03                        ;[49F9] 01 03 af
    OUT     ($80),A                         ;[49FC] d3 80
    LD      BC,$FF7F                        ;[49FE] 01 7f ff
    OUT     (C),A                           ;[4A01] ed 79
    LD      B,$10                           ;[4A03] 06 10
    LD      C,$87                           ;[4A05] 0e 87
    LD      HL,D6845                        ;[4A07] 21 56 00
    OUT     ($86),A                         ;[4A0A] d3 86
    LD      E,(HL)                          ;[4A0C] 5e
    OUT     (C),E                           ;[4A0D] ed 59
    INC     A                               ;[4A0F] 3c
    INC     HL                              ;[4A10] 23
    DJNZ    $4A0A                           ;[4A11] 10 f7
    LD      HL,$177B                        ;[4A13] 21 7b 17
    LD      DE,SYSVAR_CURSORX               ;[4A16] 11 54 62
    LD      BC,MOVE                         ;[4A19] 01 22 00
    LDIR                                    ;[4A1C] ed b0
    LD      A,$04                           ;[4A1E] 3e 04
    RST     $08                             ;[4A20] cf
    RET                                     ;[4A21] c9
;
; Sounds
; EXPLODE
EXPL:
    LD    A,$01                      ;[4A22] Speaker on
    OUT   ($80),A                    ;[4A24] 
    LD    HL,EXPTAB                  ;[4A26]
    LD    C,20                       ;[4A29]
EEXPL1:
    LD    E,(HL)                     ;[4A2B]
    INC   HL                         ;[4A2C]
    LD    B,100                      ;[4A2D]
EEXPL2:
    LD    A,E                        ;[4A2F]
    OUT   ($84),A                    ;[4A30]
    LD    A,R                        ;[4A32]
EEXPL3:
    DEC   A                          ;[4A34]
    JR    NZ,EEXPL3                  ;[4A35]
    XOR   A                          ;[4A37]
    OUT   ($84),A                    ;[4A38]
    LD    A,R                        ;[4A3A]
EEXPL4:
    DEC   A                          ;[4A3C]
    JR    NZ,EEXPL4                  ;[4A3D]
    DJNZ  EEXPL2                     ;[4A3F]
    DEC   C                          ;[4A41]
    JR    NZ,EEXPL1                  ;[4A42]
    XOR   A                          ;[4A44] speaker off 
    OUT   ($80),A                    ;[4A45]
    RET                              ;[4A47]
;
EXPTAB:	
    DB    30,63,62,61,60,58,56,53    ;[4A48]
	DB    50,48,45,42,39,36,32,28    ;[4A50]
	DB    24,20,16,12                ;[4A58]
;
EKLX:
; KLAXON (police)
    LD    A,$01                      ;[4A5C] Speaker on
    OUT   ($80),A                    ;[4A5E] 
    LD    DE,CYAN                    ;[4A60] 
    LD    C,$0E                      ;[4A63] 
    CALL  EKLAX1                     ;[4A65] 
    LD    DE,ADDQ                    ;[4A68] 
    LD    C,$09                      ;[4A6B] 
    CALL  EKLAX1                     ;[4A6D] 
    XOR   A                          ;[4A70]
    OUT   ($80),A                    ;[4A71] Speaker off
    RET                              ;[4A73] 
EKLAX1:
    XOR   A                          ;[4A74]
EKLAX2:
    OUT   ($84),A                    ;[4A75]
    LD    B,C                        ;[4A77]
EKLAX3:
    DJNZ  EKLAX3                     ;[4A78]
    INC   A                          ;[4A7A]
    CP    $40                        ;[4A7B]
    JR    C,EKLAX2                   ;[4A7D]
    DEC   DE                         ;[4A7F]
    LD    A,D                        ;[4A80]
    OR    E                          ;[4A81]
    JR    NZ,EKLAX1                  ;[4A82]
    RET                              ;[4A84]
;
; LASER (pfut)
;
ELSR:
    LD    HL,5                       ;[4A85] 
    LD    DE,1                       ;[4A88] 
    LD    B,70                       ;[4A8B] 
ELSR1:
    PUSH  BC                         ;[4A8D] 
    PUSH  DE                         ;[4A8E] 
    PUSH  HL                         ;[4A8F] 
    LD    B,63                       ;[4A90] 
    CALL  ELSR2                      ;[4A92] 
    POP   HL                         ;[4A95] 
    POP   DE                         ;[4A96] 
    POP   BC                         ;[4A97] 
    INC   DE                         ;[4A98] 
    INC   DE                         ;[4A99] 
    DJNZ  ELSR1                      ;[4A9A] 
    RET                              ;[4A9C] 
ELSR2:
    PUSH  DE                         ;[4A9D] 
    PUSH  HL                         ;[4A9E] 
    LD    A,$01                      ;[4A9F] 
    OUT   ($80),A                    ;[4AA1] 
    LD    A,B                        ;[4AA3] 
    JP    _BEEP                      ;[4AA4] use low ROM routine
 ;
 ; ZAP (a sort of tinkling)
 ;
EZAP:
    LD    A,$01                      ;[4AA7] 
    OUT   ($80),A                    ;[4AA9] 
    LD    C,20                       ;[4AAB] 
EZAP1:
    LD    B,50                       ;[4AAD] 
EZAP2:
    XOR   A                          ;[4AAF] 
    OUT   ($84),A                    ;[4AB0] 
    LD    A,R                        ;[4AB2] 
EZAP3:
    DEC   A                          ;[4AB4] 
    NOP                              ;[4AB5] 
    JR    NZ,EZAP3                   ;[4AB6] 
    LD    A,63                       ;[4AB8] 
    OUT   ($84),A                    ;[4ABA] 
    LD    A,R                        ;[4ABC] 
EZAP4:
    DEC   A                          ;[4ABE] 
    JR    NZ,EZAP4                   ;[4ABF] 
    DJNZ  EZAP2                      ;[4AC1] 
    DEC   C                          ;[4AC3] 
    JR    NZ,EZAP1                   ;[4AC4]
    XOR   A                          ;[4AC6] Speaker off 
    OUT   ($80),A                    ;[4AC7] 
    RET                              ;[4AC9] 
;
;
;
    RST     $18                             ;[4ACA] df
    INC     DE                              ;[4ACB] 13
    PUSH    HL                              ;[4ACC] e5
    RST     $18                             ;[4ACD] df
    INC     DE                              ;[4ACE] 13
    PUSH    HL                              ;[4ACF] e5
    RST     $18                             ;[4AD0] df
    INC     DE                              ;[4AD1] 13
    PUSH    HL                              ;[4AD2] e5
    RST     $18                             ;[4AD3] df
    PUSH    HL                              ;[4AD4] e5
    LD      B,$0E                           ;[4AD5] 06 0e
    LD      HL,$6410                        ;[4AD7] 21 10 64
    LD      (HL),$00                        ;[4ADA] 36 00
    INC     HL                              ;[4ADC] 23
    DJNZ    $4ADA                           ;[4ADD] 10 fb
    LD      DE,$640F                        ;[4ADF] 11 0f 64
    POP     HL                              ;[4AE2] e1
    BIT     7,H                             ;[4AE3] cb 7c
    JP      NZ,ERR_NUM_OUT_RANGE            ;[4AE5] c2 29 3b
    LD      A,H                             ;[4AE8] 7c
    AND     $E0                             ;[4AE9] e6 e0
    JP      NZ,ERR_NUM_OUT_RANGE            ;[4AEB] c2 29 3b
    LD      A,H                             ;[4AEE] 7c
    LD      (DE),A                          ;[4AEF] 12
    DEC     DE                              ;[4AF0] 1b
    LD      A,L                             ;[4AF1] 7d
    LD      (DE),A                          ;[4AF2] 12
    DEC     DE                              ;[4AF3] 1b
    POP     HL                              ;[4AF4] e1
    BIT     7,H                             ;[4AF5] cb 7c
    LD      A,H                             ;[4AF7] 7c
    JR      NZ,$4B02                        ;[4AF8] 20 08
    AND     $E0                             ;[4AFA] e6 e0
    JP      NZ,ERR_NUM_OUT_RANGE            ;[4AFC] c2 29 3b
    JP      $4B0A                           ;[4AFF] c3 0a 4b
    CPL                                     ;[4B02] 2f
    ADD     $01                             ;[4B03] c6 01
    AND     $60                             ;[4B05] e6 60
    JP      NZ,ERR_NUM_OUT_RANGE            ;[4B07] c2 29 3b
    LD      A,H                             ;[4B0A] 7c
    LD      (DE),A                          ;[4B0B] 12
    DEC     DE                              ;[4B0C] 1b
    LD      A,L                             ;[4B0D] 7d
    LD      (DE),A                          ;[4B0E] 12
    DEC     DE                              ;[4B0F] 1b
    POP     HL                              ;[4B10] e1
    BIT     7,H                             ;[4B11] cb 7c
    LD      A,H                             ;[4B13] 7c
    JR      NZ,$4B1E                        ;[4B14] 20 08
    AND     $E0                             ;[4B16] e6 e0
    JP      NZ,ERR_NUM_OUT_RANGE            ;[4B18] c2 29 3b
    JP      $4B26                           ;[4B1B] c3 26 4b
    CPL                                     ;[4B1E] 2f
    ADD     $01                             ;[4B1F] c6 01
    AND     $60                             ;[4B21] e6 60
    JP      NZ,ERR_NUM_OUT_RANGE            ;[4B23] c2 29 3b
    LD      A,H                             ;[4B26] 7c
    LD      (DE),A                          ;[4B27] 12
    DEC     DE                              ;[4B28] 1b
    LD      A,L                             ;[4B29] 7d
    LD      (DE),A                          ;[4B2A] 12
    DEC     DE                              ;[4B2B] 1b
    POP     HL                              ;[4B2C] e1
    LD      A,H                             ;[4B2D] 7c
    AND     A                               ;[4B2E] a7
    JP      NZ,ERR_NUM_OUT_RANGE            ;[4B2F] c2 29 3b
    LD      A,L                             ;[4B32] 7d
    AND     $FE                             ;[4B33] e6 fe
    JP      NZ,ERR_NUM_OUT_RANGE            ;[4B35] c2 29 3b
    DEC     DE                              ;[4B38] 1b
    LD      A,L                             ;[4B39] 7d
    LD      (DE),A                          ;[4B3A] 12
    LD      IX,LET                          ;[4B3B] dd 21 00 00
    LD      IY,($640E)                      ;[4B3F] fd 2a 0e 64
    PUSH    IY                              ;[4B43] fd e5
    PUSH    IY                              ;[4B45] fd e5
    POP     BC                              ;[4B47] c1
    POP     DE                              ;[4B48] d1
    XOR     A                               ;[4B49] af
    OR      D                               ;[4B4A] b2
    OR      E                               ;[4B4B] b3
    JP      Z,$4C0D                         ;[4B4C] ca 0d 4c
    SLA     C                               ;[4B4F] cb 21
    RL      B                               ;[4B51] cb 10
    XOR     A                               ;[4B53] af
    LD      H,A                             ;[4B54] 67
    LD      L,$01                           ;[4B55] 2e 01
    SBC     HL,BC                           ;[4B57] ed 42
    LD      C,L                             ;[4B59] 4d
    LD      B,H                             ;[4B5A] 44
    ADD     HL,DE                           ;[4B5B] 19
    LD      DE,VDU                          ;[4B5C] 11 01 00
    PUSH    HL                              ;[4B5F] e5
    PUSH    DE                              ;[4B60] d5
    PUSH    BC                              ;[4B61] c5
    XOR     A                               ;[4B62] af
    PUSH    IX                              ;[4B63] dd e5
    POP     DE                              ;[4B65] d1
    PUSH    IY                              ;[4B66] fd e5
    POP     HL                              ;[4B68] e1
    SBC     HL,DE                           ;[4B69] ed 52
    JP      C,$4C09                         ;[4B6B] da 09 4c
    LD      HL,$6410                        ;[4B6E] 21 10 64
    PUSH    IX                              ;[4B71] dd e5
    POP     DE                              ;[4B73] d1
    LD      (HL),E                          ;[4B74] 73
    INC     HL                              ;[4B75] 23
    LD      (HL),D                          ;[4B76] 72
    INC     HL                              ;[4B77] 23
    LD      A,E                             ;[4B78] 7b
    CPL                                     ;[4B79] 2f
    ADD     $01                             ;[4B7A] c6 01
    LD      (HL),A                          ;[4B7C] 77
    INC     HL                              ;[4B7D] 23
    LD      A,D                             ;[4B7E] 7a
    CPL                                     ;[4B7F] 2f
    ADC     $00                             ;[4B80] ce 00
    LD      (HL),A                          ;[4B82] 77
    INC     HL                              ;[4B83] 23
    PUSH    IY                              ;[4B84] fd e5
    POP     DE                              ;[4B86] d1
    LD      (HL),E                          ;[4B87] 73
    INC     HL                              ;[4B88] 23
    LD      (HL),D                          ;[4B89] 72
    INC     HL                              ;[4B8A] 23
    LD      A,E                             ;[4B8B] 7b
    CPL                                     ;[4B8C] 2f
    ADD     $01                             ;[4B8D] c6 01
    LD      (HL),A                          ;[4B8F] 77
    INC     HL                              ;[4B90] 23
    LD      A,D                             ;[4B91] 7a
    CPL                                     ;[4B92] 2f
    ADC     $00                             ;[4B93] ce 00
    LD      (HL),A                          ;[4B95] 77
    LD      HL,$640A                        ;[4B96] 21 0a 64
    LD      DE,$6410                        ;[4B99] 11 10 64
    LD      BC,$6418                        ;[4B9C] 01 18 64
    CALL    $4C26                           ;[4B9F] cd 26 4c
    DEC     HL                              ;[4BA2] 2b
    INC     BC                              ;[4BA3] 03
    INC     DE                              ;[4BA4] 13
    CALL    $4C26                           ;[4BA5] cd 26 4c
    INC     HL                              ;[4BA8] 23
    INC     BC                              ;[4BA9] 03
    INC     DE                              ;[4BAA] 13
    CALL    $4C26                           ;[4BAB] cd 26 4c
    PUSH    HL                              ;[4BAE] e5
    PUSH    DE                              ;[4BAF] d5
    PUSH    BC                              ;[4BB0] c5
    CALL    $4C30                           ;[4BB1] cd 30 4c
    POP     BC                              ;[4BB4] c1
    POP     DE                              ;[4BB5] d1
    POP     HL                              ;[4BB6] e1
    DEC     HL                              ;[4BB7] 2b
    DEC     BC                              ;[4BB8] 0b
    INC     DE                              ;[4BB9] 13
    CALL    $4C26                           ;[4BBA] cd 26 4c
    CALL    $4C30                           ;[4BBD] cd 30 4c
    LD      HL,$640A                        ;[4BC0] 21 0a 64
    LD      DE,$6414                        ;[4BC3] 11 14 64
    LD      BC,$6418                        ;[4BC6] 01 18 64
    CALL    $4C26                           ;[4BC9] cd 26 4c
    DEC     HL                              ;[4BCC] 2b
    INC     DE                              ;[4BCD] 13
    INC     BC                              ;[4BCE] 03
    CALL    $4C26                           ;[4BCF] cd 26 4c
    LD      DE,$6410                        ;[4BD2] 11 10 64
    INC     HL                              ;[4BD5] 23
    INC     BC                              ;[4BD6] 03
    CALL    $4C26                           ;[4BD7] cd 26 4c
    PUSH    HL                              ;[4BDA] e5
    PUSH    DE                              ;[4BDB] d5
    PUSH    BC                              ;[4BDC] c5
    CALL    $4C30                           ;[4BDD] cd 30 4c
    POP     BC                              ;[4BE0] c1
    POP     DE                              ;[4BE1] d1
    POP     HL                              ;[4BE2] e1
    DEC     HL                              ;[4BE3] 2b
    INC     DE                              ;[4BE4] 13
    DEC     BC                              ;[4BE5] 0b
    CALL    $4C26                           ;[4BE6] cd 26 4c
    CALL    $4C30                           ;[4BE9] cd 30 4c
    POP     BC                              ;[4BEC] c1
    POP     DE                              ;[4BED] d1
    POP     HL                              ;[4BEE] e1
    BIT     7,H                             ;[4BEF] cb 7c
    JR      Z,$4BF8                         ;[4BF1] 28 05
    INC     BC                              ;[4BF3] 03
    INC     BC                              ;[4BF4] 03
    ADD     HL,DE                           ;[4BF5] 19
    JR      $4BFF                           ;[4BF6] 18 07
    DEC     IY                              ;[4BF8] fd 2b
    INC     BC                              ;[4BFA] 03
    INC     BC                              ;[4BFB] 03
    INC     BC                              ;[4BFC] 03
    INC     BC                              ;[4BFD] 03
    ADD     HL,BC                           ;[4BFE] 09
    INC     DE                              ;[4BFF] 13
    INC     DE                              ;[4C00] 13
    INC     IX                              ;[4C01] dd 23
    PUSH    HL                              ;[4C03] e5
    PUSH    DE                              ;[4C04] d5
    PUSH    BC                              ;[4C05] c5
    JP      $4B62                           ;[4C06] c3 62 4b
    POP     BC                              ;[4C09] c1
    POP     DE                              ;[4C0A] d1
    POP     HL                              ;[4C0B] e1
    RET                                     ;[4C0C] c9

    LD      DE,$640D                        ;[4C0D] 11 0d 64
    LD      A,(DE)                          ;[4C10] 1a
    AND     A                               ;[4C11] a7
    RET     NZ                              ;[4C12] c0
    DEC     DE                              ;[4C13] 1b
    LD      A,(DE)                          ;[4C14] 1a
    CP      $FC                             ;[4C15] fe fc
    RET     NC                              ;[4C17] d0
    EXX                                     ;[4C18] d9
    LD      H,A                             ;[4C19] 67
    EXX                                     ;[4C1A] d9
    DEC     DE                              ;[4C1B] 1b
    LD      A,(DE)                          ;[4C1C] 1a
    AND     A                               ;[4C1D] a7
    RET     NZ                              ;[4C1E] c0
    DEC     DE                              ;[4C1F] 1b
    LD      A,(DE)                          ;[4C20] 1a
    LD      H,A                             ;[4C21] 67
    CALL    SUB_PLOT3                       ;[4C22] cd 17 10
    RET                                     ;[4C25] c9

    LD      A,(DE)                          ;[4C26] 1a
    ADD     (HL)                            ;[4C27] 86
    LD      (BC),A                          ;[4C28] 02
    INC     HL                              ;[4C29] 23
    INC     BC                              ;[4C2A] 03
    INC     DE                              ;[4C2B] 13
    LD      A,(DE)                          ;[4C2C] 1a
    ADC     (HL)                            ;[4C2D] 8e
    LD      (BC),A                          ;[4C2E] 02
    RET                                     ;[4C2F] c9

    LD      DE,$641D                        ;[4C30] 11 1d 64
    LD      A,(DE)                          ;[4C33] 1a
    AND     A                               ;[4C34] a7
    JR      NZ,$4C83                        ;[4C35] 20 4c
    DEC     DE                              ;[4C37] 1b
    LD      A,(DE)                          ;[4C38] 1a
    CP      $FC                             ;[4C39] fe fc
    JP      NC,$4C83                        ;[4C3B] d2 83 4c
    LD      HL,$6419                        ;[4C3E] 21 19 64
    LD      A,(HL)                          ;[4C41] 7e
    AND     A                               ;[4C42] a7
    JP      M,$4C83                         ;[4C43] fa 83 4c
    LD      HL,$641B                        ;[4C46] 21 1b 64
    LD      A,(HL)                          ;[4C49] 7e
    LD      B,$00                           ;[4C4A] 06 00
    AND     A                               ;[4C4C] a7
    JP      M,$4C5D                         ;[4C4D] fa 5d 4c
    JR      NZ,$4C83                        ;[4C50] 20 31
    DEC     HL                              ;[4C52] 2b
    LD      A,(HL)                          ;[4C53] 7e
    LD      B,A                             ;[4C54] 47
    LD      H,A                             ;[4C55] 67
    LD      A,(DE)                          ;[4C56] 1a
    EXX                                     ;[4C57] d9
    LD      H,A                             ;[4C58] 67
    EXX                                     ;[4C59] d9
    CALL    SUB_PLOT3                       ;[4C5A] cd 17 10
    LD      HL,$6419                        ;[4C5D] 21 19 64
    LD      A,(HL)                          ;[4C60] 7e
    LD      C,$FF                           ;[4C61] 0e ff
    AND     A                               ;[4C63] a7
    JR      NZ,$4C71                        ;[4C64] 20 0b
    DEC     HL                              ;[4C66] 2b
    LD      A,(HL)                          ;[4C67] 7e
    LD      C,A                             ;[4C68] 4f
    LD      H,A                             ;[4C69] 67
    LD      A,(DE)                          ;[4C6A] 1a
    EXX                                     ;[4C6B] d9
    LD      H,A                             ;[4C6C] 67
    EXX                                     ;[4C6D] d9
    CALL    SUB_PLOT3                       ;[4C6E] cd 17 10
    LD      HL,$6408                        ;[4C71] 21 08 64
    LD      A,(HL)                          ;[4C74] 7e
    AND     A                               ;[4C75] a7
    JR      Z,$4C83                         ;[4C76] 28 0b
    LD      A,B                             ;[4C78] 78
    CP      C                               ;[4C79] b9
    JR      Z,$4C83                         ;[4C7A] 28 07
    LD      HL,$641C                        ;[4C7C] 21 1c 64
    LD      A,(HL)                          ;[4C7F] 7e
    CALL    $4C84                           ;[4C80] cd 84 4c
    RET                                     ;[4C83] c9

    LD      DE,SYSVAR_STRBUF                ;[4C84] 11 07 64
    LD      (DE),A                          ;[4C87] 12
    LD      L,A                             ;[4C88] 6f
    LD      H,$00                           ;[4C89] 26 00
    ADD     HL,HL                           ;[4C8B] 29
    ADD     HL,HL                           ;[4C8C] 29
    ADD     HL,HL                           ;[4C8D] 29
    ADD     HL,HL                           ;[4C8E] 29
    ADD     HL,HL                           ;[4C8F] 29
    PUSH    HL                              ;[4C90] e5
    LD      E,B                             ;[4C91] 58
    SRL     E                               ;[4C92] cb 3b
    SRL     E                               ;[4C94] cb 3b
    SRL     E                               ;[4C96] cb 3b
    LD      D,$00                           ;[4C98] 16 00
    ADD     HL,DE                           ;[4C9A] 19
    EX      DE,HL                           ;[4C9B] eb
    POP     HL                              ;[4C9C] e1
    PUSH    DE                              ;[4C9D] d5
    LD      E,C                             ;[4C9E] 59
    SRL     E                               ;[4C9F] cb 3b
    SRL     E                               ;[4CA1] cb 3b
    SRL     E                               ;[4CA3] cb 3b
    LD      D,$00                           ;[4CA5] 16 00
    ADD     HL,DE                           ;[4CA7] 19
    LD      A,B                             ;[4CA8] 78
    LD      DE,$FF80                        ;[4CA9] 11 80 ff
    AND     $07                             ;[4CAC] e6 07
    JR      Z,$4CB5                         ;[4CAE] 28 05
    SRL     D                               ;[4CB0] cb 3a
    DEC     A                               ;[4CB2] 3d
    JR      NZ,$4CB0                        ;[4CB3] 20 fb
    LD      A,C                             ;[4CB5] 79
    AND     $07                             ;[4CB6] e6 07
    JR      Z,$4CBF                         ;[4CB8] 28 05
    SRA     E                               ;[4CBA] cb 2b
    DEC     A                               ;[4CBC] 3d
    JR      NZ,$4CBA                        ;[4CBD] 20 fb
    POP     BC                              ;[4CBF] c1
    PUSH    HL                              ;[4CC0] e5
    PUSH    BC                              ;[4CC1] c5
    XOR     A                               ;[4CC2] af
    SBC     HL,BC                           ;[4CC3] ed 42
    LD      B,L                             ;[4CC5] 45
    LD      HL,SYSVAR_STRBUF                ;[4CC6] 21 07 64
    LD      A,(HL)                          ;[4CC9] 7e
    EXX                                     ;[4CCA] d9
    LD      H,A                             ;[4CCB] 67
    EXX                                     ;[4CCC] d9
    JP      Z,$4D0A                         ;[4CCD] ca 0a 4d
    JP      M,$4D15                         ;[4CD0] fa 15 4d
    LD      A,D                             ;[4CD3] 7a
    CPL                                     ;[4CD4] 2f
    LD      C,A                             ;[4CD5] 4f
    CPL                                     ;[4CD6] 2f
    POP     HL                              ;[4CD7] e1
    LD      D,B                             ;[4CD8] 50
    PUSH    DE                              ;[4CD9] d5
    CALL    SYSVAR_OUTB                     ;[4CDA] cd 6c 62
    LD      HL,SYSVAR_STRBUF                ;[4CDD] 21 07 64
    LD      A,(HL)                          ;[4CE0] 7e
    EXX                                     ;[4CE1] d9
    LD      H,A                             ;[4CE2] 67
    EXX                                     ;[4CE3] d9
    POP     DE                              ;[4CE4] d1
    LD      A,E                             ;[4CE5] 7b
    CPL                                     ;[4CE6] 2f
    LD      C,A                             ;[4CE7] 4f
    CPL                                     ;[4CE8] 2f
    POP     HL                              ;[4CE9] e1
    PUSH    HL                              ;[4CEA] e5
    PUSH    DE                              ;[4CEB] d5
    CALL    SYSVAR_OUTB                     ;[4CEC] cd 6c 62
    LD      A,$FF                           ;[4CEF] 3e ff
    POP     BC                              ;[4CF1] c1
    LD      C,$00                           ;[4CF2] 0e 00
    POP     HL                              ;[4CF4] e1
    DEC     HL                              ;[4CF5] 2b
    LD      DE,SYSVAR_STRBUF                ;[4CF6] 11 07 64
    LD      A,(DE)                          ;[4CF9] 1a
    EXX                                     ;[4CFA] d9
    LD      H,A                             ;[4CFB] 67
    EXX                                     ;[4CFC] d9
    LD      A,$FF                           ;[4CFD] 3e ff
    DEC     B                               ;[4CFF] 05
    JR      Z,$4D14                         ;[4D00] 28 12
    PUSH    BC                              ;[4D02] c5
    CALL    SYSVAR_OUTB                     ;[4D03] cd 6c 62
    POP     BC                              ;[4D06] c1
    JP      $4CF5                           ;[4D07] c3 f5 4c
    LD      A,E                             ;[4D0A] 7b
    AND     D                               ;[4D0B] a2
    CPL                                     ;[4D0C] 2f
    LD      C,A                             ;[4D0D] 4f
    CPL                                     ;[4D0E] 2f
    POP     HL                              ;[4D0F] e1
    POP     HL                              ;[4D10] e1
    CALL    SYSVAR_OUTB                     ;[4D11] cd 6c 62
    RET                                     ;[4D14] c9

    POP     HL                              ;[4D15] e1
    POP     HL                              ;[4D16] e1
    RET                                     ;[4D17] c9

    RST     $18                             ;[4D18] df
    INC     DE                              ;[4D19] 13
    PUSH    HL                              ;[4D1A] e5
    RST     $18                             ;[4D1B] df
    INC     DE                              ;[4D1C] 13
    PUSH    HL                              ;[4D1D] e5
    RST     $18                             ;[4D1E] df
    INC     DE                              ;[4D1F] 13
    PUSH    HL                              ;[4D20] e5
    RST     $18                             ;[4D21] df
    INC     DE                              ;[4D22] 13
    PUSH    HL                              ;[4D23] e5
    RST     $18                             ;[4D24] df
    INC     DE                              ;[4D25] 13
    PUSH    HL                              ;[4D26] e5
    RST     $18                             ;[4D27] df
    INC     DE                              ;[4D28] 13
    PUSH    HL                              ;[4D29] e5
    LD      C,$00                           ;[4D2A] 0e 00
    LD      DE,$6417                        ;[4D2C] 11 17 64
    LD      B,$03                           ;[4D2F] 06 03
    POP     HL                              ;[4D31] e1
    BIT     7,H                             ;[4D32] cb 7c
    JP      NZ,ERR_NUM_OUT_RANGE            ;[4D34] c2 29 3b
    LD      A,L                             ;[4D37] 7d
    CP      $FC                             ;[4D38] fe fc
    JP      NC,ERR_NUM_OUT_RANGE            ;[4D3A] d2 29 3b
    LD      (DE),A                          ;[4D3D] 12
    CP      C                               ;[4D3E] b9
    JR      C,$4D42                         ;[4D3F] 38 01
    LD      C,A                             ;[4D41] 4f
    DEC     DE                              ;[4D42] 1b
    POP     HL                              ;[4D43] e1
    BIT     7,H                             ;[4D44] cb 7c
    JP      NZ,ERR_NUM_OUT_RANGE            ;[4D46] c2 29 3b
    LD      A,L                             ;[4D49] 7d
    LD      (DE),A                          ;[4D4A] 12
    DEC     DE                              ;[4D4B] 1b
    DJNZ    $4D31                           ;[4D4C] 10 e3
    LD      A,C                             ;[4D4E] 79
    LD      HL,$6418                        ;[4D4F] 21 18 64
    LD      B,$03                           ;[4D52] 06 03
    DEC     HL                              ;[4D54] 2b
    CP      (HL)                            ;[4D55] be
    JR      NZ,$4D59                        ;[4D56] 20 01
    LD      E,B                             ;[4D58] 58
    DEC     HL                              ;[4D59] 2b
    DJNZ    $4D54                           ;[4D5A] 10 f8
    DEC     HL                              ;[4D5C] 2b
    LD      (HL),E                          ;[4D5D] 73
    LD      B,$03                           ;[4D5E] 06 03
    LD      HL,$6418                        ;[4D60] 21 18 64
    LD      C,$FD                           ;[4D63] 0e fd
    DEC     HL                              ;[4D65] 2b
    LD      A,(HL)                          ;[4D66] 7e
    CP      C                               ;[4D67] b9
    JR      Z,$4D6D                         ;[4D68] 28 03
    JR      NC,$4D6E                        ;[4D6A] 30 02
    LD      C,A                             ;[4D6C] 4f
    LD      E,B                             ;[4D6D] 58
    DEC     HL                              ;[4D6E] 2b
    DJNZ    $4D65                           ;[4D6F] 10 f4
    LD      HL,$6411                        ;[4D71] 21 11 64
    LD      A,(HL)                          ;[4D74] 7e
    LD      C,A                             ;[4D75] 4f
    XOR     E                               ;[4D76] ab
    LD      D,A                             ;[4D77] 57
    JR      NZ,$4D7F                        ;[4D78] 20 05
    INC     A                               ;[4D7A] 3c
    LD      E,A                             ;[4D7B] 5f
    INC     A                               ;[4D7C] 3c
    LD      C,A                             ;[4D7D] 4f
    INC     C                               ;[4D7E] 0c
    LD      B,$00                           ;[4D7F] 06 00
    DEC     HL                              ;[4D81] 2b
    PUSH    HL                              ;[4D82] e5
    SLA     C                               ;[4D83] cb 21
    ADD     HL,BC                           ;[4D85] 09
    PUSH    HL                              ;[4D86] e5
    POP     IX                              ;[4D87] dd e1
    POP     HL                              ;[4D89] e1
    SLA     A                               ;[4D8A] cb 27
    LD      C,A                             ;[4D8C] 4f
    ADD     HL,BC                           ;[4D8D] 09
    PUSH    HL                              ;[4D8E] e5
    POP     IY                              ;[4D8F] fd e1
    PUSH    DE                              ;[4D91] d5
    LD      L,(IX+$00)                      ;[4D92] dd 6e 00
    LD      C,(IY+$00)                      ;[4D95] fd 4e 00
    CALL    $4E74                           ;[4D98] cd 74 4e
    LD      L,(IX+$01)                      ;[4D9B] dd 6e 01
    LD      E,(IY+$01)                      ;[4D9E] fd 5e 01
    SBC     HL,DE                           ;[4DA1] ed 52
    CALL    Z,$4EF4                         ;[4DA3] cc f4 4e
    JR      Z,$4DAB                         ;[4DA6] 28 03
    CALL    $4E8A                           ;[4DA8] cd 8a 4e
    LD      HL,$6408                        ;[4DAB] 21 08 64
    LD      (HL),E                          ;[4DAE] 73
    INC     HL                              ;[4DAF] 23
    LD      (HL),C                          ;[4DB0] 71
    INC     HL                              ;[4DB1] 23
    LD      (HL),B                          ;[4DB2] 70
    LD      HL,$6410                        ;[4DB3] 21 10 64
    POP     BC                              ;[4DB6] c1
    PUSH    BC                              ;[4DB7] c5
    LD      B,$00                           ;[4DB8] 06 00
    SLA     C                               ;[4DBA] cb 21
    ADD     HL,BC                           ;[4DBC] 09
    PUSH    HL                              ;[4DBD] e5
    EX      (SP),IY                         ;[4DBE] fd e3
    LD      L,(IX+$00)                      ;[4DC0] dd 6e 00
    LD      C,(IY+$00)                      ;[4DC3] fd 4e 00
    CALL    $4E74                           ;[4DC6] cd 74 4e
    LD      E,(IY+$01)                      ;[4DC9] fd 5e 01
    LD      L,(IX+$01)                      ;[4DCC] dd 6e 01
    SBC     HL,DE                           ;[4DCF] ed 52
    CALL    Z,$4EF4                         ;[4DD1] cc f4 4e
    JR      Z,$4DD9                         ;[4DD4] 28 03
    CALL    $4E8A                           ;[4DD6] cd 8a 4e
    LD      HL,$640B                        ;[4DD9] 21 0b 64
    LD      (HL),E                          ;[4DDC] 73
    INC     HL                              ;[4DDD] 23
    LD      (HL),C                          ;[4DDE] 71
    INC     HL                              ;[4DDF] 23
    LD      (HL),B                          ;[4DE0] 70
    EX      (SP),IX                         ;[4DE1] dd e3
    LD      L,(IX+$00)                      ;[4DE3] dd 6e 00
    LD      C,(IY+$00)                      ;[4DE6] fd 4e 00
    CALL    $4E74                           ;[4DE9] cd 74 4e
    LD      L,(IX+$01)                      ;[4DEC] dd 6e 01
    LD      E,(IY+$01)                      ;[4DEF] fd 5e 01
    SBC     HL,DE                           ;[4DF2] ed 52
    CALL    Z,$4EF4                         ;[4DF4] cc f4 4e
    JR      Z,$4DFC                         ;[4DF7] 28 03
    CALL    $4E8A                           ;[4DF9] cd 8a 4e
    LD      HL,$640E                        ;[4DFC] 21 0e 64
    LD      (HL),E                          ;[4DFF] 73
    INC     HL                              ;[4E00] 23
    LD      (HL),C                          ;[4E01] 71
    INC     HL                              ;[4E02] 23
    LD      (HL),B                          ;[4E03] 70
    LD      B,$06                           ;[4E04] 06 06
    LD      HL,$6418                        ;[4E06] 21 18 64
    LD      (HL),$00                        ;[4E09] 36 00
    INC     HL                              ;[4E0B] 23
    DJNZ    $4E09                           ;[4E0C] 10 fb
    LD      HL,$6419                        ;[4E0E] 21 19 64
    LD      A,(IY+$00)                      ;[4E11] fd 7e 00
    LD      (HL),A                          ;[4E14] 77
    LD      HL,$641C                        ;[4E15] 21 1c 64
    LD      (HL),A                          ;[4E18] 77
    LD      B,A                             ;[4E19] 47
    LD      C,A                             ;[4E1A] 4f
    LD      A,(IX+$01)                      ;[4E1B] dd 7e 01
    LD      E,(IY+$01)                      ;[4E1E] fd 5e 01
    LD      D,E                             ;[4E21] 53
    SUB     E                               ;[4E22] 93
    LD      E,A                             ;[4E23] 5f
    LD      A,D                             ;[4E24] 7a
    EX      (SP),IY                         ;[4E25] fd e3
    PUSH    DE                              ;[4E27] d5
    JR      NZ,$4E34                        ;[4E28] 20 0a
    LD      C,(IX+$00)                      ;[4E2A] dd 4e 00
    LD      (HL),C                          ;[4E2D] 71
    LD      A,C                             ;[4E2E] 79
    CALL    $4EE2                           ;[4E2F] cd e2 4e
    JR      $4E41                           ;[4E32] 18 0d
    CALL    $4C84                           ;[4E34] cd 84 4c
    CALL    $4EB4                           ;[4E37] cd b4 4e
    INC     HL                              ;[4E3A] 23
    INC     DE                              ;[4E3B] 13
    CALL    $4ECE                           ;[4E3C] cd ce 4e
    JR      NZ,$4E37                        ;[4E3F] 20 f6
    POP     DE                              ;[4E41] d1
    LD      A,(IY+$01)                      ;[4E42] fd 7e 01
    LD      D,(IX+$01)                      ;[4E45] dd 56 01
    LD      E,D                             ;[4E48] 5a
    SUB     E                               ;[4E49] 93
    JR      Z,$4E5B                         ;[4E4A] 28 0f
    LD      E,A                             ;[4E4C] 5f
    PUSH    DE                              ;[4E4D] d5
    CALL    $4EB4                           ;[4E4E] cd b4 4e
    INC     DE                              ;[4E51] 13
    LD      HL,$6408                        ;[4E52] 21 08 64
    CALL    $4ECE                           ;[4E55] cd ce 4e
    JR      NZ,$4E4E                        ;[4E58] 20 f4
    POP     DE                              ;[4E5A] d1
    POP     IX                              ;[4E5B] dd e1
    POP     BC                              ;[4E5D] c1
    XOR     A                               ;[4E5E] af
    OR      B                               ;[4E5F] b0
    RET     NZ                              ;[4E60] c0
    LD      B,(IX+$00)                      ;[4E61] dd 46 00
    LD      C,(IY+$00)                      ;[4E64] fd 4e 00
    LD      A,C                             ;[4E67] 79
    CP      B                               ;[4E68] b8
    JR      NC,$4E6D                        ;[4E69] 30 02
    LD      C,B                             ;[4E6B] 48
    LD      B,A                             ;[4E6C] 47
    LD      A,(IY+$01)                      ;[4E6D] fd 7e 01
    CALL    $4C84                           ;[4E70] cd 84 4c
    RET                                     ;[4E73] c9

    XOR     A                               ;[4E74] af
    LD      H,A                             ;[4E75] 67
    LD      B,A                             ;[4E76] 47
    SBC     HL,BC                           ;[4E77] ed 42
    PUSH    HL                              ;[4E79] e5
    JP      P,$4E82                         ;[4E7A] f2 82 4e
    CPL                                     ;[4E7D] 2f
    XOR     L                               ;[4E7E] ad
    ADD     $01                             ;[4E7F] c6 01
    LD      L,A                             ;[4E81] 6f
    LD      C,L                             ;[4E82] 4d
    POP     HL                              ;[4E83] e1
    EX      (SP),HL                         ;[4E84] e3
    PUSH    HL                              ;[4E85] e5
    XOR     A                               ;[4E86] af
    LD      D,A                             ;[4E87] 57
    LD      H,A                             ;[4E88] 67
    RET                                     ;[4E89] c9

    PUSH    HL                              ;[4E8A] e5
    LD      A,L                             ;[4E8B] 7d
    JP      P,$4E92                         ;[4E8C] f2 92 4e
    CPL                                     ;[4E8F] 2f
    ADD     $01                             ;[4E90] c6 01
    LD      E,A                             ;[4E92] 5f
    LD      A,C                             ;[4E93] 79
    LD      C,$00                           ;[4E94] 0e 00
    CALL    $4F04                           ;[4E96] cd 04 4f
    LD      E,C                             ;[4E99] 59
    LD      C,A                             ;[4E9A] 4f
    POP     HL                              ;[4E9B] e1
    LD      A,H                             ;[4E9C] 7c
    POP     HL                              ;[4E9D] e1
    EX      (SP),HL                         ;[4E9E] e3
    XOR     H                               ;[4E9F] ac
    LD      B,$00                           ;[4EA0] 06 00
    JP      P,$4EB3                         ;[4EA2] f2 b3 4e
    LD      B,$FF                           ;[4EA5] 06 ff
    LD      A,E                             ;[4EA7] 7b
    CPL                                     ;[4EA8] 2f
    ADD     $01                             ;[4EA9] c6 01
    LD      E,A                             ;[4EAB] 5f
    LD      A,C                             ;[4EAC] 79
    CPL                                     ;[4EAD] 2f
    LD      C,A                             ;[4EAE] 4f
    JP      NC,$4EB3                        ;[4EAF] d2 b3 4e
    INC     BC                              ;[4EB2] 03
    RET                                     ;[4EB3] c9

    LD      HL,$640B                        ;[4EB4] 21 0b 64
    LD      DE,$6418                        ;[4EB7] 11 18 64
    CALL    $4EF9                           ;[4EBA] cd f9 4e
    LD      B,A                             ;[4EBD] 47
    LD      A,(DE)                          ;[4EBE] 1a
    ADC     (HL)                            ;[4EBF] 8e
    LD      (DE),A                          ;[4EC0] 12
    AND     A                               ;[4EC1] a7
    JP      P,$4EC9                         ;[4EC2] f2 c9 4e
    LD      B,$00                           ;[4EC5] 06 00
    JR      $4ECD                           ;[4EC7] 18 04
    JR      Z,$4ECD                         ;[4EC9] 28 02
    LD      B,$FF                           ;[4ECB] 06 ff
    RET                                     ;[4ECD] c9

    CALL  $4EF9                     ;[4ECE] cd f9 4e
    LD    C,A                       ;[4ED1] 4f
    LD    A,(DE)                    ;[4ED2] 1a
    ADC   (HL)                      ;[4ED3] 8e
    LD    (DE),A                    ;[4ED4] 12
    AND   A                         ;[4ED5] a7
    JP    P,$4EDD                   ;[4ED6] f2 dd 4e
    LD    C,$00                     ;[4ED9] 0e 00
    JR    $4EE1                     ;[4EDB] 18 04
    JR    Z,$4EE1                   ;[4EDD] 28 02
    LD    C,$FF                     ;[4EDF] 0e ff
    LD    A,C                       ;[4EE1] 79
    LD    C,A                       ;[4EE2] 4f
    CP    B                         ;[4EE3] b8
    JR    NC,$4EE8                  ;[4EE4] 30 02
    LD    C,B                       ;[4EE6] 48
    LD    B,A                       ;[4EE7] 47
    POP   HL                        ;[4EE8] e1
    EX    (SP),HL                   ;[4EE9] e3
    LD    A,H                       ;[4EEA] 7c
    PUSH  HL                        ;[4EEB] e5
    CALL  $4C84                     ;[4EEC] cd 84 4c
    POP   HL                        ;[4EEF] e1
    INC   H                         ;[4EF0] 24
    DEC   L                         ;[4EF1] 2d
    EX    (SP),HL                   ;[4EF2] e3
    JP    (HL)                      ;[4EF3] e9
    POP   HL                        ;[4EF4] e1
    POP   BC                        ;[4EF5] c1
    LD    E,$00                     ;[4EF6] 1e 00
    JP    (HL)                      ;[4EF8] e9
    LD    A,(DE)                    ;[4EF9] 1a
    ADD   (HL)                      ;[4EFA] 86
    LD    (DE),A                    ;[4EFB] 12
    INC   DE                        ;[4EFC] 13
    INC   HL                        ;[4EFD] 23
    LD    A,(DE)                    ;[4EFE] 1a
    ADC   (HL)                      ;[4EFF] 8e
    LD    (DE),A                    ;[4F00] 12
    INC   HL                        ;[4F01] 23
    INC   DE                        ;[4F02] 13
    RET                             ;[4F03] c9

    LD    HL,LET                    ;[4F04] 21 00 00
    LD    B,$10                     ;[4F07] 06 10
    AND   A                         ;[4F09] a7
    RL    C                         ;[4F0A] cb 11
    RLA                             ;[4F0C] 17
    ADC   HL,HL                     ;[4F0D] ed 6a
    SBC   HL,DE                     ;[4F0F] ed 52
    JR    NC,$4F14                  ;[4F11] 30 01
    ADD   HL,DE                     ;[4F13] 19
    CCF                             ;[4F14] 3f
    DJNZ  $4F0A                     ;[4F15] 10 f3
    RL    C                         ;[4F17] cb 11
    RLA                             ;[4F19] 17
    RET                             ;[4F1A] c9

    CALL  $4F41                     ;[4F1B] cd 41 4f
    LD    HL,(SYSVAR_WINDST)        ;[4F1E] 2a 56 62
    LD    DE,($6258)                ;[4F21] ed 5b 58 62
    LD    A,L                       ;[4F25] 7d
    LD    (SYSVAR_CURSORX),A        ;[4F26] 32 54 62
    LD    A,E                       ;[4F29] 7b
    LD    (SYSVAR_CURSORY),A        ;[4F2A] 32 55 62
    ADD   HL,HL                     ;[4F2D] 29
    LD    A,D                       ;[4F2E] 7a
    SUB   E                         ;[4F2F] 93
    LD    B,L                       ;[4F30] 45
    LD    C,H                       ;[4F31] 4c
    INC   C                         ;[4F32] 0c
    PUSH  AF                        ;[4F33] f5
    LD    A,E                       ;[4F34] 7b
    PUSH  BC                        ;[4F35] c5
    PUSH  DE                        ;[4F36] d5
    CALL  $4C84                     ;[4F37] cd 84 4c
    POP   DE                        ;[4F3A] d1
    POP   BC                        ;[4F3B] c1
    POP   AF                        ;[4F3C] f1
    INC   E                         ;[4F3D] 1c
    DEC   A                         ;[4F3E] 3d
    JR    NZ,$4F33                  ;[4F3F] 20 f2
    LD    HL,(SYSVAR_INKST)         ;[4F41] 2a 5b 62
    LD    E,H                       ;[4F44] 5c
    LD    H,L                       ;[4F45] 65
    LD    L,E                       ;[4F46] 6b
    LD    (SYSVAR_INKST),HL         ;[4F47] 22 5b 62
    RET                             ;[4F4A] c9

    RST   $38                       ;[4F4B] ff
    RST   $38                       ;[4F4C] ff
    RST   $38                       ;[4F4D] ff
    RST   $38                       ;[4F4E] ff
    RST   $38                       ;[4F4F] ff
    RST   $38                       ;[4F50] ff
    RST   $38                       ;[4F51] ff
    RST   $38                       ;[4F52] ff
    RST   $38                       ;[4F53] ff
    RST   $38                       ;[4F54] ff
    RST   $38                       ;[4F55] ff
    RST   $38                       ;[4F56] ff
    RST   $38                       ;[4F57] ff
    RST   $38                       ;[4F58] ff
    RST   $38                       ;[4F59] ff
    RST   $38                       ;[4F5A] ff
    RST   $38                       ;[4F5B] ff
    RST   $38                       ;[4F5C] ff
    RST   $38                       ;[4F5D] ff
    RST   $38                       ;[4F5E] ff
    RST   $38                       ;[4F5F] ff
    RST   $38                       ;[4F60] ff
    RST   $38                       ;[4F61] ff
    RST   $38                       ;[4F62] ff
    RST   $38                       ;[4F63] ff
    RST   $38                       ;[4F64] ff
    RST   $38                       ;[4F65] ff
    RST   $38                       ;[4F66] ff
    RST   $38                       ;[4F67] ff
    RST   $38                       ;[4F68] ff
    RST   $38                       ;[4F69] ff
    RST   $38                       ;[4F6A] ff
    RST   $38                       ;[4F6B] ff
    RST   $38                       ;[4F6C] ff
    RST   $38                       ;[4F6D] ff
    RST   $38                       ;[4F6E] ff
    RST   $38                       ;[4F6F] ff
    RST   $38                       ;[4F70] ff
    RST   $38                       ;[4F71] ff
    RST   $38                       ;[4F72] ff
    RST   $38                       ;[4F73] ff
    RST   $38                       ;[4F74] ff
    RST   $38                       ;[4F75] ff
    RST   $38                       ;[4F76] ff
    RST   $38                       ;[4F77] ff
    RST   $38                       ;[4F78] ff
    RST   $38                       ;[4F79] ff
    RST   $38                       ;[4F7A] ff
    RST   $38                       ;[4F7B] ff
    RST   $38                       ;[4F7C] ff
    RST   $38                       ;[4F7D] ff
    RST   $38                       ;[4F7E] ff
    RST   $38                       ;[4F7F] ff
    RST   $38                       ;[4F80] ff
    RST   $38                       ;[4F81] ff
    RST   $38                       ;[4F82] ff
    RST   $38                       ;[4F83] ff
    RST   $38                       ;[4F84] ff
    RST   $38                       ;[4F85] ff
    RST   $38                       ;[4F86] ff
    RST   $38                       ;[4F87] ff
    RST   $38                       ;[4F88] ff
    RST   $38                       ;[4F89] ff
    RST   $38                       ;[4F8A] ff
    RST   $38                       ;[4F8B] ff
    RST   $38                       ;[4F8C] ff
    RST   $38                       ;[4F8D] ff
    RST   $38                       ;[4F8E] ff
    RST   $38                       ;[4F8F] ff
    RST   $38                       ;[4F90] ff
    RST   $38                       ;[4F91] ff
    RST   $38                       ;[4F92] ff
    RST   $38                       ;[4F93] ff
    RST   $38                       ;[4F94] ff
    RST   $38                       ;[4F95] ff
    RST   $38                       ;[4F96] ff
    RST   $38                       ;[4F97] ff
    RST   $38                       ;[4F98] ff
    RST   $38                       ;[4F99] ff
    RST   $38                       ;[4F9A] ff
    RST   $38                       ;[4F9B] ff
    RST   $38                       ;[4F9C] ff
    RST   $38                       ;[4F9D] ff
    RST   $38                       ;[4F9E] ff
    RST   $38                       ;[4F9F] ff
    RST   $38                       ;[4FA0] ff
    RST   $38                       ;[4FA1] ff
    RST   $38                       ;[4FA2] ff
    RST   $38                       ;[4FA3] ff
    RST   $38                       ;[4FA4] ff
    RST   $38                       ;[4FA5] ff
    RST   $38                       ;[4FA6] ff
    RST   $38                       ;[4FA7] ff
    RST   $38                       ;[4FA8] ff
    RST   $38                       ;[4FA9] ff
    RST   $38                       ;[4FAA] ff
    RST   $38                       ;[4FAB] ff
    RST   $38                       ;[4FAC] ff
    RST   $38                       ;[4FAD] ff
    RST   $38                       ;[4FAE] ff
    RST   $38                       ;[4FAF] ff
    RST   $38                       ;[4FB0] ff
    RST   $38                       ;[4FB1] ff
    RST   $38                       ;[4FB2] ff
    RST   $38                       ;[4FB3] ff
    RST   $38                       ;[4FB4] ff
    RST   $38                       ;[4FB5] ff
    RST   $38                       ;[4FB6] ff
    RST   $38                       ;[4FB7] ff
    RST   $38                       ;[4FB8] ff
    RST   $38                       ;[4FB9] ff
    RST   $38                       ;[4FBA] ff
    RST   $38                       ;[4FBB] ff
    RST   $38                       ;[4FBC] ff
    RST   $38                       ;[4FBD] ff
    RST   $38                       ;[4FBE] ff
    RST   $38                       ;[4FBF] ff
    RST   $38                       ;[4FC0] ff
    RST   $38                       ;[4FC1] ff
    RST   $38                       ;[4FC2] ff
    RST   $38                       ;[4FC3] ff
    RST   $38                       ;[4FC4] ff
    RST   $38                       ;[4FC5] ff
    RST   $38                       ;[4FC6] ff
    RST   $38                       ;[4FC7] ff
    RST   $38                       ;[4FC8] ff
    RST   $38                       ;[4FC9] ff
    RST   $38                       ;[4FCA] ff
    RST   $38                       ;[4FCB] ff
    RST   $38                       ;[4FCC] ff
    RST   $38                       ;[4FCD] ff
    RST   $38                       ;[4FCE] ff
    RST   $38                       ;[4FCF] ff
    RST   $38                       ;[4FD0] ff
    RST   $38                       ;[4FD1] ff
    RST   $38                       ;[4FD2] ff
    RST   $38                       ;[4FD3] ff
    RST   $38                       ;[4FD4] ff
    RST   $38                       ;[4FD5] ff
    RST   $38                       ;[4FD6] ff
    RST   $38                       ;[4FD7] ff
    RST   $38                       ;[4FD8] ff
    RST   $38                       ;[4FD9] ff
    RST   $38                       ;[4FDA] ff
    RST   $38                       ;[4FDB] ff
    RST   $38                       ;[4FDC] ff
    RST   $38                       ;[4FDD] ff
    RST   $38                       ;[4FDE] ff
    RST   $38                       ;[4FDF] ff
    RST   $38                       ;[4FE0] ff
    RST   $38                       ;[4FE1] ff
    RST   $38                       ;[4FE2] ff
    RST   $38                       ;[4FE3] ff
    RST   $38                       ;[4FE4] ff
    RST   $38                       ;[4FE5] ff
    RST   $38                       ;[4FE6] ff
    RST   $38                       ;[4FE7] ff
    RST   $38                       ;[4FE8] ff
    RST   $38                       ;[4FE9] ff
    RST   $38                       ;[4FEA] ff
    RST   $38                       ;[4FEB] ff
    RST   $38                       ;[4FEC] ff
    RST   $38                       ;[4FED] ff
    RST   $38                       ;[4FEE] ff
    RST   $38                       ;[4FEF] ff
    LD    H,H                       ;[4FF0] 64
    LD    E,C                       ;[4FF1] 59
    LD    H,H                       ;[4FF2] 64
    LD    D,E                       ;[4FF3] 53
    LD    E,B                       ;[4FF4] 58
    NOP                             ;[4FF5] 00
    NOP                             ;[4FF6] 00
    NOP                             ;[4FF7] 00
    NOP                             ;[4FF8] 00
    NOP                             ;[4FF9] 00
    NOP                             ;[4FFA] 00
    NOP                             ;[4FFB] 00
    NOP                             ;[4FFC] 00
    NOP                             ;[4FFD] 00
    NOP                             ;[4FFE] 00
    NOP                             ;[4FFF] 00
    