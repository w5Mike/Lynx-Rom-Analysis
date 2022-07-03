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
;*     COMPILE/ASSEMBLE: z88dk-z80asm -split-bin -b -mz80 -o"Lynx" "Lynx_48k_Rom.ASM" "Lynx_96k_Rom.ASM"
;* ---------------------------------------------------------------------
;*
;
EXTERN INTFP, ERR_TYPE_MISMATCH, ERR_OUT_OF_DATA, ERR_NOT_YET_IMP, ERR_SYNTAX, SPACE
EXTERN LNUM1, PN, TEST_IS_LOOP_END, SUB_INDENT, SKIP_LNUM, SUB_PRINT_KEYWORD, PRINT_BAS_LINE
EXTERN PRINT_STRING, DISPLAY_SPACE, PNE1, DO_INDENT, IEND, _BEEP, D6845, ERR_BAD_TAPE
EXTERN ERR_NUM_OUT_RANGE, ERR_OUT_OF_MEM, ERR_OVERFLOW, ERR_SOMETHG_MISSG, ERROR_PRINT
EXTERN EXEC2, FLOAT_ZERO, FPINT, GET_VAR_ADDR, IDPOKE, IE4CR, IE6CR, IINK, ILOAD, IVRY 
EXTERN IREM, MOTOFF, RBYTE, READ_STRING_EXPR, READ_STRING_VAR, RP, RSYNC, STRING_EXEC
EXTERN SUB_PLOT3, TAPE_READ, TEST_FOR_STR_EXP, TEST_FOR_STRING, TEST_IS_COMMA
EXTERN VPTR_IS_STR, WRITE_FNAME, WSYNC, VROM, DFTW
;
include "Lynx.def"
include "Tokens.def"

SECTION _96k_3
PHASE $4000
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
    PUSH  DE                        ;[4018] Rom off
    LD    BC,$FF7F                  ;[4019] Bank switching
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
    PUSH  BC                        ;[4027] ROMOFF
    LD    BC,$FF7F                  ;[4028] Bank switching
    LD    A,$10                     ;[402B] 
    OUT   (C),A                     ;[402D] 
    POP   BC                        ;[402F] 
    LDIR                            ;[4030] LDIR
    LD    BC,$FF7F                  ;[4032] ROMON
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
    CALL  ROMOFF                    ;[4039] 
    PUSH  DE                        ;[403C] 
    CALL  PRDBYT                    ;[403D] control byte
    BIT   7,A                       ;[4040] 
    JP    NZ,PRDTM                  ;[4042] 1 = string (type mismatch)
    BIT   6,A                       ;[4045] 
    JR    NZ,PRDN5                  ;[4047] 1 = f.p.
    BIT   5,A                       ;[4049] 
    JR    NZ,PRDN1                  ;[404B] 
    LD    D,0                       ;[404D] 
    BIT   4,A                       ;[404F] 
    JR    Z,PRDN3                   ;[4051] 
    AND   $0F                       ;[4053] 
    JR    PRDN2                     ;[4055] 
PRDN1:
    CALL  PRDBYT                    ;[4057] 
PRDN2:
    LD    D,A                       ;[405A] 
    CALL  PRDBYT                    ;[405B] 
PRDN3:  
    LD    E,A                       ;[405E] now DE = number
    PUSH  BC                        ;[405F] 
    PUSH  HL                        ;[4060] 
    EX    DE,HL                     ;[4061] 
    CALL  ROMON                     ;[4062] 
    CALL  INTFP                     ;[4065] number to WRA1
    LD    B,5                       ;[4068] 
    LD    HL,SYSVAR_WRA1            ;[406A] 
PRDN4:
    LD    A,(HL)                    ;[406D] floating point
    INC   HL                        ;[406E] 
    LD    (IX+0),A                  ;[406F] 
    INC   IX                        ;[4072] 
    DJNZ  PRDN4                     ;[4074] 
    POP   HL                        ;[4076] 
    POP   BC                        ;[4077] 
    POP   DE                        ;[4078] 
    RET                             ;[4079] 
PRDN5:
    LD    E,$05                     ;[407A]
PRDN6:
    CALL  PRDBYT                    ;[407C]
    LD    (IX+0),A                  ;[407F]
    INC   IX                        ;[4082]
    DEC   E                         ;[4084]
    JR    NZ,PRDN6                  ;[4085]
PRDN7:
    POP   DE                        ;[4087]
    JP    ROMON                     ;[4088]
;
; Read string
;
RSTR:
    CALL  ROMOFF                    ;[408B] 
    PUSH  DE                        ;[408E] 
    LD    E,(IX-1)                  ;[408F] max size for string
    CALL  PRDBYT                    ;[4092] control byte
    BIT   7,A                       ;[4095] 
    JP    Z,PRDTM                   ;[4097] 
    RES   7,A                       ;[409A] 
    LD    D,A                       ;[409C] length in file
    INC   D                         ;[409D] 
PRDS1:
    DEC   D                         ;[409E] 
    JR    Z,PRDS2                   ;[409F] 
    CALL  PRDBYT                    ;[40A1] get char
    INC   E                         ;[40A4] 
    DEC   E                         ;[40A5] 
    JR    Z,PRDS1                   ;[40A6] ignore if no room
    LD    (IX+0),A                  ;[40A8] 
    INC   IX                        ;[40AB] 
    DEC   E                         ;[40AD] 
    JR    PRDS1                     ;[40AE] 
PRDS2:
    LD    (IX+0),SZ                 ;[40B0] 
    POP   DE                        ;[40B4] 
    JP    ROMON                     ;[40B5] 
;
; Read byte from software file
; NB Assumes interrupts already disabled *******
;
PRDBYT:
    LD    A,H                       ;[40B8] 
    CP    B                         ;[40B9] 
    JR    NZ,PRDB2                  ;[40BA] 
    LD    A,L                       ;[40BC] 
    CP    C                         ;[40BD] 
    JP    Z,PRDEOF                  ;[40BE] 
PRDB2:
    INC   L                         ;[40C1] 
    JR    NZ,PRDB3                  ;[40C2] 
    LD    H,(HL)                    ;[40C4] 
    INC   L                         ;[40C5] 
PRDB3: 
    LD    A,(HL)                    ;[40C6] 
    RET                             ;[40C7] 
PRDTM:
    CALL  ROMON                     ;[40C8] 
    CALL  ERR_TYPE_MISMATCH         ;[40CB] 
PRDEOF:
    CALL  ROMON                     ;[40CE] 
    CALL  ERR_OUT_OF_DATA           ;[40D1] 
;
; Get byte to save to tape.
;
EGETB:
    EXX                             ;[40D4] 
    OUT   (C),D                     ;[40D5] 
    INC   L                         ;[40D7] 
    JR    NZ,GTBYT1                 ;[40D8] 
    LD    H,(HL)                    ;[40DA] 
    INC   L                         ;[40DB] 
GTBYT1:
    LD    A,(HL)                    ;[40DC] 
    OUT   (C),E                     ;[40DD] 
    EXX                             ;[40DF] 
    RET                             ;[40E0] 
;
; Length of the "Low Ram" section above - to be copied to RAM (in EXINIT)
; (the PHASE command messes up the calculation by $4000, so deduct $4000)
;
LWLEN	equ $-LWRAM-$4000
;
; Padding
;
DEFS 31,0
;
; Extra initialization.
; Copy ROM (LWRAM) to LOW RAM
;
EXINIT:
    LD    HL,LWRAM                  ;[4100] copy from HL (rom) to HL (ram)!
    LD    D,H                       ;[4103] (rom/ram reflection)
    LD    E,L                       ;[4104] 
    LD    BC,LWLEN                  ;[4105] 
    LDIR                            ;[4108] Copy the "Low Ram" rom section to RAM
    LD    HL,UPROM                  ;[410A] 
    LD    DE,UPRAM                  ;[410D] 
    LD    BC,UPLEN                  ;[4110] 
    LDIR                            ;[4113] 
    LD    HL,JUMPS                  ;[4115] 
    LD    DE,SYSVAR_FLIGHT          ;[4118] 
    LD    BC,$15                    ;[411B]
    LDIR                            ;[411E] 
;
; Change some 48K values.
;
    LD    A,(SYSVAR_EEXT+2)         ;[4120] EXT done already?
    CP    $40                       ;[4123] 
    JR    NC,CHG2                   ;[4125] 
    LD    HL,EXTRAM                 ;[4127] no, clear RAM
    LD    B,8                       ;[412A] 
CHG1:
    LD    (HL),0                    ;[412C] 
    INC   HL                        ;[412E] 
    DJNZ  CHG1                      ;[412F] 
;
    LD    HL,IEXTS                  ;[4131] 
    LD    (SYSVAR_IEXT+1),HL        ;[4134] 
    LD    HL,EEXTS                  ;[4137] 
    LD    (SYSVAR_EEXT+1),HL        ;[413A] 
    LD    HL,DBL96K                 ;[413D] 
    LD    (SYSVAR_DBASLN+1),HL      ;[4140] 
CHG2:
    LD    HL,EXTTAB                 ;[4143] 
    LD    (EXTRAM+2),HL             ;[4146] 2 for int. ROM
    LD    A,EXT                     ;[4149] make <O$ESC>E = EXT
    LD    (SYSVAR_KTBL+4),A         ;[414B] 
    LD    A,FN1                     ;[414E] 
    LD    HL,EXSR                   ;[4150] 
    LD    (SYSVAR_EXECSUB),A        ;[4153] 
    LD    (SYSVAR_EXECSUB+1),HL     ;[4156]
 ;
    CALL  EPPR                      ;[4159] init parallel printer
    CALL  PAD                       ;[415C] init pad (low RAM)
    RET                             ;[415F] 

;
; Initial values of RAM.
;
UPROM:	
    DB    2                         ;[4160] next free page
	DB    0                         ;[4161] current file
	DB    0,PZ,0,PZ,0,PZ,0,0        ;[4162] file info
	DW    0                         ;[416A] error variable
	DW    0                         ;[416C] EXEC stack pointer
	DB    $88                       ;[416E] lightpen offset
UPLEN	equ ASMPC-UPROM-$4000
;
; Jumps
;
JUMPS:
    JP    FPEN                      ;[416F] Lightpen function
    JP    FJOY                      ;[4171] Joystick function 
    JP    ERR_NOT_YET_IMP           ;[4175] User0
    JP    ERR_NOT_YET_IMP           ;[4178] User1
    JP    ERR_NOT_YET_IMP           ;[417B] User2
    JP    ERR_NOT_YET_IMP           ;[417E] User3
    JP    ERRORHANDLER              ;[4181] Called during error.
;
EXTTAB:
EXT_ASCII: DW XT96KS                ;[4184] ASCII for EXT commands
EXT_INPUT: DW XI96KS                ;[4186] addr's for EXT input
EXT_EXEC:  DW XE96KS                ;[4188] addr's for EXT exec
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
EXTK1:                              ;       Start new word
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
EXTK4:                              ;       next char in word
    INC   HL                        ;[419E]
    LD    C,(HL)                    ;[419F]
    BIT   7,C                       ;[41A0] Start of next word?
    JR    NZ,EXTK8                  ;[41A2]
EXTK5:                              ;       compare with input
    RST   $10                       ;[41A4]
    INC   DE                        ;[41A5]
    CP    'a'                       ;[41A6] l/c to u/c
    JR    C,EXTK6                   ;[41A8]
    CP    'z'+1                     ;[41AA]
    JR    NC,EXTK6                  ;[41AC]
    SUB   $20                       ;[41AE]
EXTK6:
    CP    C                         ;[41B0]
    JR    Z,EXTK4                   ;[41B1]
EXTK7:                              ;       check for '.' abbrev.
    CP    '.'                       ;[41B3]
    JR    NZ,EXTK1                  ;[41B5]
    BIT   7,(HL)                    ;[41B7] must be >1 char
    JR    NZ,EXTK1                  ;[41B9]
EXTK8:                              ;       match found
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
    PUSH  DE                        ;[41C1] 
    RLCA                            ;[41C2] 
    LD    E,A                       ;[41C3] 
    LD    D,0                       ;[41C4] 
    ADD   HL,DE                     ;[41C6] 
    LD    A,(HL)                    ;[41C7] 
    INC   HL                        ;[41C8] 
    LD    H,(HL)                    ;[41C9] 
    LD    L,A                       ;[41CA] 
    POP   DE                        ;[41CB] 
    RET                             ;[41CC] 
;
; Set up rest of line after EXT.
;
IEXTS:
    PUSH  HL                        ;[41CD] Polish pointer
    LD    HL,EXTRAM-1               ;[41CE]
    LD    B,4                       ;[41D1] 4 types of EXT
IEXTS1:
    PUSH  BC                        ;[41D3]
    INC   HL                        ;[41D4]
    LD    C,(HL)                    ;[41D5]
    INC   HL                        ;[41D6]
    LD    B,(HL)                    ;[41D7]
    LD    A,C                       ;[41D8]
    OR    B                         ;[41D9]
    JR    Z,IEXTS2                  ;[41DA] JR if not set up
    PUSH  BC                        ;[41DC]
    POP   IX                        ;[41DD] IX points to 3-word table
    PUSH  HL                        ;[41DF]
    LD    L,(IX+0)                  ;[41E0]
    LD    H,(IX+1)                  ;[41E3] point HL at commands
    CALL  EXTK                      ;[41E6] get token if match
    POP   HL                        ;[41E9]
    JR    NC,IEXTS3                 ;[41EA] JR if match
IEXTS2:
    POP   BC                        ;[41EC]
    DJNZ  IEXTS1                    ;[41ED]
    CALL  ERR_SYNTAX                ;[41EF] not in any table
IEXTS3:
    POP   BC                        ;[41F2]
    LD    C,A                       ;[41F3] position in table
    LD    A,$04                     ;[41F4]
    SUB   B                         ;[41F6] type (0 to 3)
    RRCA                            ;[41F7]
    RRCA                            ;[41F8] times $40
    ADD   C                         ;[41F9] make token
    POP   HL                        ;[41FA] Polish pointer
    LD    (HL),A                    ;[41FB]
    INC   HL                        ;[41FC]
    LD    A,C                       ;[41FD] position in table
    PUSH  HL                        ;[41FE]
    LD    L,(IX+2)                  ;[41FF]
    LD    H,(IX+3)                  ;[4202] point HL at dispatch
    CALL  HL2A                      ;[4205] HL = disp. addr.
    EX    (SP),HL                   ;[4208]
    JP    SPACE                     ;[4209] get char, then dispatch (skip spaces)
;
; New "Display Basic Line".
; Allow for EXT, correct REM bug.
;
DBL96K:
    PUSH  IX                        ;[420C] 
    POP   HL                        ;[420E] 
    PUSH  HL                        ;[420F] 
    CALL  LNUM1                     ;[4210] 
    CALL  PN                        ;[4213] 
    CALL  TEST_IS_LOOP_END          ;[4216] 
    CALL  SUB_INDENT                ;[4219] 
    CALL  SKIP_LNUM                 ;[421C] 
NDBL1:
    LD    A,(DE)                    ;[421F] 
    PUSH  AF                        ;[4220] 
    CALL  SUB_PRINT_KEYWORD         ;[4221] 
    POP   AF                        ;[4224] 
    CP    REM                       ;[4225] ------ start insert
    JR    Z,KOPY                    ;[4227] just copy rest if REM
    CP    EXT                       ;[4229] 
    JR    NZ,NDBL6                  ;[422B] 
    LD    A,(DE)                    ;[422D] token after EXT
    AND   %11000000                 ;[422E] 
    RLCA                            ;[4230] 
    RLCA                            ;[4231] A = type of EXT
    LD    HL,EXTRAM                 ;[4232] 
    CALL  HL2A                      ;[4235] point to 3-word table
    LD    A,(HL)                    ;[4238] 
    INC   HL                        ;[4239] 
    LD    H,(HL)                    ;[423A] 
    LD    L,A                       ;[423B] point to ASCII
    LD    A,(DE)                    ;[423C] token again
    AND   %00111111                 ;[423D] posn in list
    CALL  SUB_PRINT_KEYWORD+6       ;[423F] token back to ASCII
    JR    NDBL15                    ;[4242] ------ end insert
NDBL6:   
    CP    ELSE                      ;[4244] 
    JR    Z,NDBL1                   ;[4246] 
    CP    CODE                      ;[4248] 
    JP    Z,PRINT_BAS_LINE          ;[424A]
NDBL15:
    DEC   DE                        ;[424D] 
NDBL:
    INC   DE                        ;[424E] 
NDBL11:
    LD    A,(DE)                    ;[424F] 
    CP    EOS                       ;[4250] 
    RET   Z                         ;[4252] 
    CP    CR                        ;[4253] 
    JR    Z,NDBL4                   ;[4255] 
    CP    SOP                       ;[4257] Start of polish
    JR    Z,NDBL2                   ;[4259] 
    CP    $80                       ;[425B] 
    JR    NC,NDBL3                  ;[425D] Token
    RST   8                         ;[425F] 
    CP    $22                       ;[4260] Quote char
    JR    NZ,NDBL                   ;[4262] 
    CALL  PRINT_STRING              ;[4264] 
    RST   8                         ;[4267] 
    JR    NDBL                      ;[4268]
NDBL2:  
    INC   DE                        ;[426A] 
    CALL  SYSVAR_PP                 ;[426B] 
    JR    NDBL                      ;[426E]
NDBL3:
    CP    CHR                       ;[4270] 
    PUSH  AF                        ;[4272] 
    CALL  C,DISPLAY_SPACE           ;[4273] 
    CALL  PNE1                      ;[4276] 
    POP   AF                        ;[4279] 
    PUSH  AF                        ;[427A] 
    CALL  C,DISPLAY_SPACE           ;[427B] 
    POP   AF                        ;[427E] 
    INC   DE                        ;[427F] 
    CP    THEN                      ;[4280] 
    JR    Z,NDBL1                   ;[4282] 
    JR    NDBL11                    ;[4284]
NDBL4:
    POP   IX                        ;[4286] 
    JP    DO_INDENT+2               ;[4288]
;
; Here to copy ASCII from Polish
;
KOPY1:
    INC   DE                        ;[428B]
KOPY:
    LD    A,(DE)                    ;[428C] 
    CP    $0D                       ;[428D] 
    JP    Z,DO_INDENT               ;[428F] 
    RST   8                         ;[4292] 
    JR    $428B                     ;[4293] 
;
; Execute EXT command.
; DE points to token after EXT,
; A holds (DE).
;
EEXTS:
    PUSH  IX                        ;[4295] 
    AND   %11000000                 ;[4297] 
    RLCA                            ;[4299] 
    RLCA                            ;[429A] A = type of EXT
    LD    HL,EXTRAM                 ;[429B] 
    CALL  HL2A                      ;[429E] point to 3-word table
    LD    A,H                       ;[42A1] 
    OR    L                         ;[42A2] 
    CALL  Z,ERR_NOT_YET_IMP         ;[42A3] error if not set up
    PUSH  HL                        ;[42A6] 
    POP   IX                        ;[42A7] 
    LD    L,(IX+4)                  ;[42A9] 
    LD    H,(IX+5)                  ;[42AC] point HL at dispatch
    LD    A,(DE)                    ;[42AF] 
    AND   %00111111                 ;[42B0] 
    CALL  HL2A                      ;[42B2] get address
    INC   DE                        ;[42B5] 
    LD    A,(DE)                    ;[42B6] next byte
    POP   IX                        ;[42B7] 
    JP    (HL)                      ;[42B9] 
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
    DW    IEND                      ;[434E] EXPLODE
    DW    IEND                      ;[4350] KLAXON
    DW    IEND                      ;[4352] LASER
    DW    IEND                      ;[4354] ZAP
    DW    IPWR                      ;[4356] STORE
    DW    IIST                      ;[4358] ISTORE
    DW    IPRD                      ;[435A] FETCH
    DW    IINK                      ;[435C] WIPE
    DW    IINK                      ;[435E] BACK
    DW    ISSV                      ;[4360] SSAVE
    DW    ISSV                      ;[4362] SLOAD
    DW    ISSV                      ;[4364] CSAVE
    DW    IDPOKE                    ;[4366] CHAIN
    DW    ITRP                      ;[4368] TRAP
    DW    IEND                      ;[436A] NOTRAP
    DW    IEND                      ;[436C] PPRINT
    DW    IEND                      ;[436E] SPRINT
    DW    IEND                      ;[4370] VRESET
    DW    IE4CR                     ;[4372] CIRCLE
    DW    IE6CR                     ;[4374] TRIANGLE
    DW    IEND                      ;[4376] CLW
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
    DW    EPWR                      ;[438C] STORE
    DW    EIST                      ;[438E] ISTORE
    DW    EPRD                      ;[4390] FETCH
    DW    EWIP                      ;[4392] WIPE
    DW    EBAK                      ;[4394] BACK
    DW    ESSV                      ;[4396] SSAVE
    DW    ESLD                      ;[4398] SLOAD
    DW    ECSV                      ;[439A] CSAVE
    DW    ECHN                      ;[439C] CHAIN
    DW    ETRP                      ;[439E] TRAP
    DW    ENTR                      ;[43A0] NOTRAP
    DW    EPPR                      ;[43A2] PPRINT
    DW    ESPR                      ;[43A4] SPRINT
    DW    EVRS                      ;[43A6] VRESET
    DW    ECIR                      ;[43A8] CIRCLE
    DW    ETRI                      ;[43AA] TRIANGLE
    DW    ECLW                      ;[43AC] CLW
    DW    ERR_NOT_YET_IMP           ;[43AE] @@@@@@
    DW    ERR_NOT_YET_IMP           ;[43B0] @@@@@@
    DW    ERR_NOT_YET_IMP           ;[43B2] @@@@@@
    DW    ERR_NOT_YET_IMP           ;[43B4] @@@@@@
    DW    ERR_NOT_YET_IMP           ;[43B6] @@@@@@
    DW    ERR_NOT_YET_IMP           ;[43B8] @@@@@@
;
;----------------------------------------------------------
; Routines for store, i.e. low RAM used to store software files.
; Organized into pages of 256 bytes, with byte 0 of each page
; used to point to the next page.
;
; Initialize. The file information
; has already been copied from ROM
;
PAD:
    LD    HL,$9FFF                  ;[43BA] test for 96K
    LD    DE,$BFFF                  ;[43BD] 
    LD    A,(DE)                    ;[43C0] 
    CPL                             ;[43C1] 
    LD    (DE),A                    ;[43C2] 
    LD    C,(HL)                    ;[43C3] 
    CPL                             ;[43C4] 
    LD    (DE),A                    ;[43C5] 
    LD    A,(HL)                    ;[43C6] 
    CP    C                         ;[43C7] if 48K, HL & DE are different
    JR    Z,PAD1                    ;[43C8] 
    LD    A,$80                     ;[43CA] set flag if 48K 
    LD    (KFILE),A                 ;[43CC] 
    RET                             ;[43CF] 
PAD1:
    LD    A,(NXFRPG)                ;[43D0] next free page
    LD    H,A                       ;[43D3] point to byte 0 of that
    LD    L,0                       ;[43D4] 
PAD2:
    INC   A                         ;[43D6] 
    LD    (HL),A                    ;[43D7] 
    INC   H                         ;[43D8] 
    CP    $5F                       ;[43D9] 
    JR    NZ,PAD2                   ;[43DB] 
    LD    (HL),PZ                   ;[43DD] terminator
    LD    H,$3F                     ;[43DF] skip over page 40H
    LD    (HL),$41                  ;[43E1] 
    LD    HL,KNXFIL                 ;[43E3] file info, upper RAM
    LD    DE,FILINF                 ;[43E6] lower RAM
    LD    B,MXNFIL                  ;[43E9] copy for each file
PAD3:
    PUSH  BC                        ;[43EB] 
    LD    BC,RANDOM                 ;[43EC] 
    PUSH  HL                        ;[43EF] 
    LDIR                            ;[43F0] 
    POP   HL                        ;[43F2] 
    POP   BC                        ;[43F3] 
    DJNZ  PAD3                      ;[43F4] 
    RET                             ;[43F6] 
;
; Read file number from program,
; then get info about file & put
; info into upper RAM.
;
GETINF:
    LD    HL,KFILE                  ;[43F7] current datastore
    BIT   7,(HL)                    ;[43FA] 48K Lynx?
    CALL  NZ,ERR_NOT_YET_IMP        ;[43FC] yes, "not yet implemented"
    PUSH  HL                        ;[43FF] 
    RST   $18                       ;[4400] file no. to HL and A
    INC   DE                        ;[4401] start of next arg.
    DEC   H                         ;[4402] test high byte
    INC   H                         ;[4403]
    CALL  NZ,ERR_NUM_OUT_RANGE      ;[4404] must be 0
    DEC   A                         ;[4407] nos. start at 1
    CP    MXNFIL                    ;[4408] max no of files (48)
    CALL  NC,ERR_NUM_OUT_RANGE      ;[440A] 
    INC   A                         ;[440D] 
    POP   HL                        ;[440E] 
    BIT   6,(HL)                    ;[440F] valid info?
    JR    Z,GTINF0                  ;[4411] 
    RES   6,(HL)                    ;[4413] 
    CP    (HL)                      ;[4415] about this file?
    RET   Z                         ;[4416] then do no more
GTINF0:
    LD    (HL),A                    ;[4417] 
GTINF1:
    DEC   A                         ;[4418] 
    LD    H,0                       ;[4419] 
    LD    L,A                       ;[441B] 
    ADD   HL,HL                     ;[441C] 8*(file number)
    ADD   HL,HL                     ;[441D] 
    ADD   HL,HL                     ;[441E] 
    PUSH  DE                        ;[441F] save program pointer
    LD    DE,S                      ;[4420] info in low RAM
    ADD   HL,DE                     ;[4423] point to this file
    LD    DE,KNXFIL                 ;[4424] info in high RAM
    LD    BC,8                      ;[4427] 
    CALL  ELDIR                     ;[442A] copy info
    POP   DE                        ;[442D] 
    RET                             ;[442E] 
;
; Put updated info about file
; from high RAM into low RAM.
;
PUTINF:
    LD    HL,KFILE                  ;[442F] 
    LD    A,(HL)                    ;[4432] file no.
    SET   6,(HL)                    ;[4433] flag for GETINF
    DEC   A                         ;[4435] 
    LD    H,0                       ;[4436] 
    LD    L,A                       ;[4438] 
    ADD   HL,HL                     ;[4439] times 8
    ADD   HL,HL                     ;[443A] 
    ADD   HL,HL                     ;[443B] 
    LD    DE,FILINF                 ;[443C] info in low RAM
    ADD   HL,DE                     ;[443F] 
    EX    DE,HL                     ;[4440] 
    LD    HL,KNXFIL                 ;[4441] 
    LD    BC,RANDOM                 ;[4444] 
    LDIR                            ;[4447] 
    RET                             ;[4449] 
;
; Attach unused pages to current file
; Set Z if file not started and no
; free page is available.
;
ATTACH:
    LD    HL,(KWRPTR)               ;[444A] write pointer
    LD    L,0                       ;[444D] byte 0 of last page used
    LD    A,H                       ;[444F] or nothing there?
    CP    PZ                        ;[4450] 
    LD    A,(NXFRPG)                ;[4452] next free page
    JR    Z,ATTCH1                  ;[4455] JR if file not started
    LD    (HL),A                    ;[4457] chain it on
    RET                             ;[4458] with Z reset
ATTCH1:
    LD    H,A                       ;[4459] HL = byte 0 of free page
    LD    (KFSTPG),A                ;[445A] 
    LD    (KWRPTR),HL               ;[445D] 
    LD    (KRDPTR),HL               ;[4460] 
    LD    H,0                       ;[4463] 
    LD    (KFILEN),HL               ;[4465] length = 0
    CP    PZ                        ;[4468] set Z if no space
    RET                             ;[446A] 
;
; Detach unused pages from current file.
;
DETACH:
    LD    HL,(KWRPTR)               ;[446B] write pointer
    LD    A,H                       ;[446E] last page used
    CP    PZ                        ;[446F] file started?
    RET   Z                         ;[4471] if not, nothing to do
    LD    L,0                       ;[4472] byte 0 of page
    CALL  LAHL                      ;[4474] A = next page
    LD    (HL),PZ                   ;[4477] terminate file
    LD    (NXFRPG),A                ;[4479] unused becomes free
    RET                             ;[447C] 
;
; Input syntax for STORE
;
IPWR:
    CALL  TEST_IS_COMMA             ;[447D] expression + ','
    RST   $10                       ;[4480] char after ','
    CP    CR                        ;[4481] end of line?
    CALL  Z,ERR_SOMETHG_MISSG       ;[4483] 
    CALL  TEST_FOR_STR_EXP          ;[4486] test for string expr.
    JR    NZ,IPWR2                  ;[4489] 
    CALL  READ_STRING_EXPR          ;[448B] read string expr.
    INC   DE                        ;[448E] 
    JR    IPWR3                     ;[448F] 
IPWR2:
    CALL  RP                        ;[4491] Reverse polish
IPWR3:
    CP    ','                       ;[4494] 
    JP    NZ,IEND                   ;[4496] 
    LD    (HL),A                    ;[4499] 
    INC   HL                        ;[449A] 
    JR    $4480                     ;[449B] 
;
; Input syntax for ISTORE
;
IIST:
    CALL  TEST_IS_COMMA             ;[449D] 
IIST1:
    RST   $10                       ;[44A0] 
    CP    CR                        ;[44A1] 
    CALL  Z,ERR_SOMETHG_MISSG       ;[44A3] 
    CALL  RP                        ;[44A6] must be numeric
    CP    ','                       ;[44A9] 
    JP    NZ,IEND                   ;[44AB] 
    LD    (HL),A                    ;[44AE] 
    INC   HL                        ;[44AF] 
    JR    IIST1                     ;[44B0] 
;
; Input syntax for FETCH
;
IPRD:
    CALL  TEST_IS_COMMA             ;[44B2] expression + ','
IPRD1:
    CALL  TEST_FOR_STRING           ;[44B5] test for string
    JR    NZ,IPRD2                  ;[44B8] 
    CALL  READ_STRING_VAR           ;[44BA] string syntax
    RST   $10                       ;[44BD] 
    JR    IPRD3                     ;[44BE] 
IPRD2:
    CALL  IVRY                      ;[44C0] numeric syntax
IPRD3:
    LD    (HL),A                    ;[44C3] term'r to Polish
    CP    CR                        ;[44C4] 
    RET   Z                         ;[44C6] 
    RST   $20                       ;[44C7] 
    DB    ','                       ;[44C8] 
    INC   HL                        ;[44C9] 
    INC   DE                        ;[44CA] 
    RST   $10                       ;[44CB] 
    JR    IPRD1                     ;[44CC] 
;
; Input syntax for SSAVE, SLOAD
;
ISSV:
    CALL  TEST_IS_COMMA             ;[44CE] expression + ','
    RST   $10                       ;[44D1] get char after ','
    JP    ILOAD                     ;[44D2] rest like LOAD
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
    LD    A,(IX+0)                  ;[44F1] byte of number
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
    LD    A,(IX+0)                  ;[450D] 
    CP    SZ                        ;[4510] 
    JR    Z,EPWR6                   ;[4512] 
    INC   IX                        ;[4514] 
    CALL  WRADV                     ;[4516] 
    LD    (HL),A                    ;[4519] 
    INC   E                         ;[451A] incr control count
    JR    EPWR5                     ;[451B] 
EPWR6:
    POP   IX                        ;[451D] was HL
    LD    (IX+0),E                  ;[451F] control byte first
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
    LD    (KWRPTR),HL               ;[4567] update file info
    LD    (KFILEN),BC               ;[456A] 
    CALL  DETACH                    ;[456E] 
    CALL  PUTINF                    ;[4571] 
    RET                             ;[4574] 
;
; Open software file.
;
WROPEN:
    CALL  GETINF                    ;[4575] 
    CALL  ATTACH                    ;[4578] 
    CALL  Z,ERR_OUT_OF_MEM          ;[457B] 
    LD    HL,(KWRPTR)               ;[457E] 
    LD    BC,(KFILEN)               ;[4581] 
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
    CP    PZ                        ;[458D] 
    CALL  Z,ERR_OUT_OF_MEM          ;[458F] 
    LD    H,A                       ;[4592] 
    INC   L                         ;[4593] 
    POP   AF                        ;[4594] 
    RET                             ;[4595] 
;
EPRD:
    CALL  GETINF                    ;[4596] get file info
    LD    HL,(KRDPTR)               ;[4599] read-pointer
    LD    BC,(KWRPTR)               ;[459C] last byte written
EPRD1: 
    PUSH  BC                        ;[45A0] 
    PUSH  HL                        ;[45A1] 
    CALL  VPTR_IS_STR               ;[45A2] addr of var into HL
    PUSH  HL                        ;[45A5] 
    POP   IX                        ;[45A6] 
    POP   HL                        ;[45A8] file info
    POP   BC                        ;[45A9] 
    JR    C,EPRD2                   ;[45AA] C set if string
    CALL  RNUM                      ;[45AC] use RAM routines
    JR    EPRD3                     ;[45AF] 
EPRD2:
    CALL  RSTR                      ;[45B1] 
EPRD3:
    LD    A,(DE)                    ;[45B4] look at terminator
    INC   DE                        ;[45B5] 
    CP    ','                       ;[45B6] 
    JR    Z,EPRD1                   ;[45B8] repeat if more args
    LD    (KRDPTR),HL               ;[45BA] update file info
    CALL  PUTINF                    ;[45BD] 
    RET                             ;[45C0] 

;
; Wipe a software file.
;
EWIP:
    CALL  GETINF                    ;[45C1] info to upper RAM
    CALL  ATTACH                    ;[45C4] add free space
    LD    HL,KFSTPG                 ;[45C7] point to first page
    LD    A,(HL)                    ;[45CA] 
    LD    (NXFRPG),A                ;[45CB] make file free
    LD    A,PZ                      ;[45CE] say no first page
    LD    (HL),A                    ;[45D0] 
    LD    H,A                       ;[45D1] reinit pointers
    LD    L,0                       ;[45D2] 
    LD    (KWRPTR),HL               ;[45D4] 
    LD    (KRDPTR),HL               ;[45D7] 
    LD    H,0                       ;[45DA] 
    LD    (KFILEN),HL               ;[45DC] 
    JP    PUTINF                    ;[45DF] reinit low RAM
;
; Back to start of software file
;
EBAK:
    CALL  GETINF                    ;[45E2] info to high RAM
    LD    A,(KFSTPG)                ;[45E5] first page
    LD    H,A                       ;[45E8] point there
    LD    L,0                       ;[45E9] 
    LD    (KRDPTR),HL               ;[45EB] reinit pointer
    JP    PUTINF                    ;[45EE] update low RAM
;
; Execute EXT SLOAD, load RAM file
; Append data if file exists.
;
ESLD:
    CALL  GETINF                    ;[45F1] info about file
    CALL  ATTACH                    ;[45F4] get free pages
    JR    Z,EDLD8                   ;[45F7] 
    CALL  TAPE_READ                 ;[45F9] 
EDLD1:
    LD    HL,(KWRPTR)               ;[45FC] 
    CALL  RSYNC                     ;[45FF] 
    CALL  RBYTE                     ;[4602] 
    CP    'D'                       ;[4605] 
    JR    NZ,EDLD9                  ;[4607] 
    CALL  RBYTE                     ;[4609] read byte count
    LD    C,A                       ;[460C] 
    CALL  RBYTE                     ;[460D] 
    LD    B,A                       ;[4610] 
    PUSH  BC                        ;[4611] 
    LD    E,0                       ;[4612] init. checksum
    JR    EDLD4                     ;[4614] 
EDLD2:
    CALL  RBYTE                     ;[4616] data byte
    LD    D,A                       ;[4619] save
    ADD   E                         ;[461A] 
    LD    E,A                       ;[461B] 
    INC   L                         ;[461C] file pointer
    JR    NZ,EDLD3                  ;[461D] 
    CALL  LAHL                      ;[461F] new page
    CP    PZ                        ;[4622] 
    JR    Z,EDLD8                   ;[4624] 
    LD    H,A                       ;[4626] 
    INC   L                         ;[4627] 
EDLD3:
    LD    (HL),D                    ;[4628] byte to file
    DEC   BC                        ;[4629] 
EDLD4:
    LD    A,B                       ;[462A] see if all read
    OR    C                         ;[462B] 
    JR    NZ,EDLD2                  ;[462C] 
    CALL  RBYTE                     ;[462E] checksum
    CP    E                         ;[4631] 
    JR    NZ,EDLD9                  ;[4632] 
    CALL  RBYTE                     ;[4634] 'N' for next?
    LD    (KWRPTR),HL               ;[4637] update info
    LD    HL,(KFILEN)               ;[463A] 
    POP   BC                        ;[463D] 
    ADD   HL,BC                     ;[463E] 
    LD    (KFILEN),HL               ;[463F] 
    CP    'N'                       ;[4642] 
    JR    Z,EDLD1                   ;[4644] 
    CALL  DETACH                    ;[4646] 
    CALL  MOTOFF                    ;[4649] 
    JP    PUTINF                    ;[464C] 
EDLD8:
    CALL  MOTOFF                    ;[464F] 
    CALL  ERR_OUT_OF_MEM            ;[4652] 
EDLD9:
    CALL  MOTOFF                    ;[4655] 
    CALL  ERR_BAD_TAPE              ;[4658] 
;
; Execute EXT SSAVE, save a
; single RAM file onto tape.
;
ESSV:
    CALL  GETINF                    ;[465B] get info
    XOR   A                         ;[465E] 
    LD    (KNXFIL),A                ;[465F] say no next file
    JP    ECSV1                     ;[4662] 
;
; Execute EXT CSAVE, save a chain
; of RAM files to tape.
;
ECSV:
    CALL  GETINF                    ;[4665] info about first file
ECSV1:
    EXX                             ;[4668] for bank switching
    LD    BC,$FF7F                  ;[4669] 
    LD    DE,$1000                  ;[466C] 
    EXX                             ;[466F] 
;
; Original version (ie. modified in worksp.mac - 15/12/83)
;
    CALL  WRITE_FNAME               ;[4670] 
ECSV2:
    EXX                             ;[4673] 
    LD    A,(KFSTPG)                ;[4674] 
    LD    H,A                       ;[4677] 
    LD    L,0                       ;[4678] 
    EXX                             ;[467A] 
    CALL  WSYNC                     ;[467B] to finish off name
    LD    A,'D'                     ;[467E] for 'data' file
    CALL  SYSVAR_WBYTE              ;[4680] 
    LD    BC,(KFILEN)               ;[4683] byte count
    LD    A,C                       ;[4687] 
    CALL  SYSVAR_WBYTE              ;[4688] 
    LD    A,B                       ;[468B] 
    CALL  SYSVAR_WBYTE              ;[468C] 
    LD    E,0                       ;[468F] 
    JR    ECSV4                     ;[4691]
ECSV3:
    CALL  EGETB                     ;[4693] 
    CALL  SYSVAR_WBYTE              ;[4696] 
    ADD   E                         ;[4699] 
    LD    E,A                       ;[469A] 
    DEC   BC                        ;[469B]
ECSV4:
    LD    A,B                       ;[469C] 
    OR    C                         ;[469D] 
    JR    NZ,ECSV3                  ;[469E] 
    LD    A,E                       ;[46A0] 
    CALL  SYSVAR_WBYTE              ;[46A1] 
    LD    A,(KNXFIL)                ;[46A4] next file in chain
    OR    A                         ;[46A7] 
    JR    Z,ECSV5                   ;[46A8] 
    LD    D,A                       ;[46AA] 
    LD    A,'N'                     ;[46AB] 
    CALL  SYSVAR_WBYTE              ;[46AD] finish off 'n'
    LD    A,D                       ;[46B0] 
    CALL  GTINF1                    ;[46B1] 
    JR    ECSV2                     ;[46B4] 
ECSV5:
    LD    A,'E'                     ;[46B6] 
    CALL  SYSVAR_WBYTE              ;[46B8] 
    CALL  SYSVAR_WBYTE              ;[46BB] 
    JP    MOTOFF                    ;[46BE] 
;
; Execute EXT CHAIN, chain second file onto first.
; Check non-circular.
;
ECHN:
    CALL  GETINF                    ;[46C1] info about first file
    RST   $18                       ;[46C4] 
    DEC   H                         ;[46C5] test range
    INC   H                         ;[46C6] 
    CALL  NZ,ERR_NUM_OUT_RANGE      ;[46C7] 
    CP    MXNFIL+1                  ;[46CA] 0 is allowed
    CALL  NC,ERR_NUM_OUT_RANGE      ;[46CC] 
    LD    C,A                       ;[46CF] C = new file
    LD    HL,KFILE                  ;[46D0] 
    LD    B,(HL)                    ;[46D3] B = current file
    JR    ECHN2                     ;[46D4] 
ECHN1:
    DEC   A                         ;[46D6] test non-circular
    LD    H,0                       ;[46D7] 
    LD    L,A                       ;[46D9] 
    ADD   HL,HL                     ;[46DA] 
    ADD   HL,HL                     ;[46DB] 
    ADD   HL,HL                     ;[46DC] 
    LD    DE,FILINF+0               ;[46DD] byte 0 = next fil
    ADD   HL,DE                     ;[46E0] 
    CALL  LAHL                      ;[46E1] 
ECHN2:
    CP    B                         ;[46E4] chain closed?
    CALL  Z,ERR_OVERFLOW            ;[46E5] let's use this one
    OR    A                         ;[46E8] end of chain?
    JR    NZ,ECHN1                  ;[46E9] 
    LD    HL,KNXFIL                 ;[46EB] OK, put info in
    LD    (HL),C                    ;[46EE] 
    JP    PUTINF                    ;[46EF] 
;
; Syntax check & execution of EXT M$TRAP, set up variable to
; trap error code.
;
ITRP:
    CALL  IVRY                      ;[46F2] numeric variable
    JP    IEND                      ;[46F5] 
;
ETRP:
    CALL  GET_VAR_ADDR              ;[46F8] addr of var to HL
    LD    (ERRVR),HL                ;[46FB] store in RAM
    EX    DE,HL                     ;[46FE] set variable to 0
    LD    HL,FLOAT_ZERO             ;[46FF] 
    LD    BC,5                      ;[4702] 
    LDIR                            ;[4705] 
    RET                             ;[4707] 
;
; Execute EXT NOTRAP, remove error trap.
;
ENTR:
    LD    HL,0                      ;[4708] 
    LD    (ERRVR),HL                ;[470B] 
    RET                             ;[470E] 
;
; Routine called via RAM on error. May be here by ERROR command.
;
ERRORHANDLER:
    LD    HL,ERROR_PRINT            ;[470F] return to old ROM
    EX    (SP),HL                   ;[4712] 
    LD    C,A                       ;[4713] error code
    LD    HL,(SYSVAR_CURRLP)        ;[4714] in program?
    LD    A,(HL)                    ;[4717] 
    CP    $80                       ;[4718] 
    JR    Z,ERRSR3                  ;[471A] if not, never trap
    LD    HL,(ERRVR)                ;[471C] trap set?
    LD    A,H                       ;[471F] 
    OR    L                         ;[4720] 
    JR    Z,ERRSR1                  ;[4721] JR if not
    PUSH  HL                        ;[4723] 
    LD    L,C                       ;[4724] error code to WRA1
    LD    H,0                       ;[4725] 
    CALL  INTFP                     ;[4727] 
    LD    HL,SYSVAR_WRA1            ;[472A] then to variable
    POP   DE                        ;[472D] 
    LD    BC,NEXT                   ;[472E] 
    LDIR                            ;[4731] 
    JR    ERRSR2                    ;[4733]
ERRSR1:   
    LD    A,C                       ;[4735] no trap, but ignore 0
    OR    A                         ;[4736] 
    JR    NZ,ERRSR3                 ;[4737] 
ERRSR2:
    LD    SP,(EXECSP)               ;[4739] continue as if no error
    JP    EXEC2                     ;[473D] 
ERRSR3:
    LD    HL,(SYSVAR_ERRTBL)        ;[4740] go via error in old ROM
    LD    A,C                       ;[4743] 
    RET                             ;[4744] 
;
; Routine called via RAM when line is executed.
;
EXSR:
    POP   HL                        ;[4745] fix stack
    LD    (EXECSP),SP               ;[4746] for error trap
    JP    (HL)                      ;[474A] return
;
; Padding to HARDWARE routines
;
DEFS 181, $FF
;
;----------------------------------------------------------
;
;		***  PRINTER ROUTINES  ***
;
; Initialize parallel printer
;
EPPR:
    PUSH  AF                        ;[4800] 
    PUSH  HL                        ;[4801] 
    PUSH  DE                        ;[4802] 
    PUSH  BC                        ;[4803] 
    IN    A,($7D)                   ;[4804] R/W this port to init
    LD    HL,PPCHAR                 ;[4806] address for BASIC
    LD    (SYSVAR_LPRNTD),HL        ;[4809] 
    LD    HL,PSTORE                 ;[480C] initial flags etc
; (ESPRT1)
    LD    DE,LXFLAG                 ;[480F] 
    LD    BC,7                      ;[4812] 
    LDIR                            ;[4815] 
    POP   BC                        ;[4817] 
    POP   DE                        ;[4818] 
    POP   HL                        ;[4819] 
    POP   AF                        ;[481A] 
    RET                             ;[481B] 
EPPR2: ;??
    LD    L,A                       ;[481C] 
    LD    BC,$80                    ;[481D] 
BASP1:
    IN    A,(C)                     ;[4820] keyboard column 0
    BIT   6,A                       ;[4822] test for <ESA> (ESCAPE?)
    RET   Z                         ;[4824] 
;
; is parallel printer ready?
;
STAP:
    IN    A,($7C)                   ;[4825] 
    BIT   0,A                       ;[4827] 
    JR    Z,BASP1                   ;[4829] 
    BIT   1,A                       ;[482B] 
    RET   Z                         ;[482D] 
BASP2:
    LD    A,L                       ;[482E] 
    OUT   ($7E),A                   ;[482F] 
SRLC4:
    CP    ' '                       ;[4831] control char?
    CALL  C,NLTEST                  ;[4833] if so, new line?
    LD    HL,BUFCT                  ;[4836] 
    JR    C,PLL4                    ;[4839] 
    INC   (HL)                      ;[483B] 
    LD    A,(BUFSIZ)                ;[483C] 
    CP    (HL)                      ;[483F] 
    RET   NC                        ;[4840] 
    LD    (HL),1                    ;[4841] 
    RET                             ;[4843] 
PLL4:
    LD    (HL),0                    ;[4844] 
    RET                             ;[4846] 
;
PSTORE:
    DB    %00000000,%00100100       ;[4847]
    DB    %00001000,%10000000       ;[4849]
    DB    %00001111                 ;[484B]
    DB    80                        ;[484C]
    DB    0                         ;[484D]
;
; Initialize serial printer
;
ESPR:
    PUSH  AF                        ;[484E] 
    PUSH  HL                        ;[484F] 
    PUSH  DE                        ;[4850] 
    PUSH  BC                        ;[4851] 
    LD    HL,SPCHAR                 ;[4852] address for BASIC
    LD    (SYSVAR_LPRNTD),HL        ;[4855] 
    LD    HL,SSTORE                 ;[4858] initial flags etc
ESPRT1:
    LD    DE,LXFLAG                 ;[485B] 
    LD    BC,$0A                    ;[485E] 
    LDIR                            ;[4861] 
    POP   BC                        ;[4863] 
    POP   DE                        ;[4864] 
    POP   HL                        ;[4865] 
    POP   AF                        ;[4866] 
    RET                             ;[4867] 
ESPRT2:
    PUSH  AF                        ;[4868] 
    LD    C,A                       ;[4869] 
ESPRT3:
    IN    A,($84)                   ;[486A] Serial read?
    BIT   6,A                       ;[486C] 
    JR    Z,ESPRT3                  ;[486E] 
    LD    A,C                       ;[4870] 
    OUT   ($82),A                   ;[4871] 
    LD    A,(BUFDLY)                ;[4873] 
    LD    B,$05                     ;[4876] 
    CALL  SPRTDELAY                 ;[4878] 
    LD    A,C                       ;[487B] 
; Old SPRINT routine?
    CP    ' '                       ;[487C] 
    CALL  C,NLTEST                  ;[487E] 
    LD    HL,BUFCT                  ;[4881] 
    JR    C,ESPRT4                  ;[4884] 
    INC   (HL)                      ;[4886] 
    LD    A,(BUFSIZ)                ;[4887] 
    CP    (HL)                      ;[488A] 
    JR    NC,ESPRT7                 ;[488B] 
    LD    (HL),1                    ;[488D] 
    JR    ESPRT5                    ;[488F] 
ESPRT4:
    LD    A,(HL)                    ;[4891] 
    LD    (HL),0                    ;[4892] 
ESPRT5:
    ADD   $10                       ;[4894] 
    LD    B,A                       ;[4896] 
ESPRT6:
    PUSH  BC                        ;[4897] 
    LD    A,(PRTDLY)                ;[4898] print delay
    LD    B,$05                     ;[489B] 
    CALL  SPRTDELAY                 ;[489D] 
    POP   BC                        ;[48A0] 
    DJNZ  ESPRT6                    ;[48A1]
ESPRT7:
    POP   AF                        ;[48A3] 
    CP    $0C                       ;[48A4] formfeed char
    RET   NZ                        ;[48A6] 
    LD    A,(FFDLY)                 ;[48A7] formfeed delay
    LD    B,$0E                     ;[48AA] 
    CALL  SPRTDELAY                 ;[48AC] 
    RET                             ;[48AF] 
;
; Delays, waiting for serial (baud rate?)
;
SPRTDELAY:
    LD    HL,1                      ;[48B0] 
SPRTDELAY1:
    ADD   HL,HL                     ;[48B3] 
    DJNZ  SPRTDELAY1                ;[48B4] 
    LD    B,A                       ;[48B6] 
SPRTDELAY2:
    PUSH  HL                        ;[48B7] 
SPRTDELAY3:
    DEC   HL                        ;[48B8] 
    LD    A,L                       ;[48B9] 
    OR    H                         ;[48BA] 
    JR    NZ,SPRTDELAY3             ;[48BB] 
    POP   HL                        ;[48BD] 
    DJNZ  SPRTDELAY2                ;[48BE] 
    RET                             ;[48C0] 
;
SSTORE:
    DB    %00000000,%00100010       ;[48C1] 
    DB    %00001000,%11000000       ;[48C3] 
    DB    %00011111                 ;[48C5]
    DB    %01010000                 ;[48C6]
    DB    %00000000                 ;[48C7]
    DB    %01000001                 ;[48C8]
    DB    %10000111                 ;[48C9]
    DB    %10000111                 ;[48CA]
; Parallel
PPCHAR:
    PUSH  DE                        ;[48CB] 
    LD    E,0                       ;[48CC] 
    JR    PPCHR1                    ;[48CE] 
; Serial
SPCHAR:
    PUSH  DE                        ;[48D0] 
    LD    E,1                       ;[48D1] 
PPCHR1:
    PUSH  AF                        ;[48D3] 
    PUSH  HL                        ;[48D4] 
    PUSH  BC                        ;[48D5] 
    CP    ' '                       ;[48D6] 
    CALL  C,OCHR                    ;[48D8] 
    JR    NC,PPCHR2                 ;[48DB] 
    CALL  LXOUT                     ;[48DD] 
    JR    PPCHR3                    ;[48E0] 
PPCHR2:
    CALL  PPCHR4                    ;[48E2]
PPCHR3:
    POP   BC                        ;[48E5]
    POP   HL                        ;[48E6]
    POP   AF                        ;[48E7]
    POP   DE                        ;[48E8]
    RET                             ;[48E9]
PPCHR4:
    BIT   0,E                       ;[48EA]
    JP    Z,EPPR2                   ;[48EC]
    JP    ESPRT2                    ;[48EF]
;
; ?Output character.
; ?HL holds address of primitive output routine
; ?B=FF for no wait, else wait till printer ready
;
OCHR:
    LD    C,A                        ;[48F2] 
    SRL   A                          ;[48F3] 
    SRL   A                          ;[48F5] 
    SRL   A                          ;[48F7] 
    LD    HL,LXFLAG                  ;[48F9] 
    ADD   L                          ;[48FC] 
    JR    NC,LXTEST                  ;[48FD] 
    INC   H                          ;[48FF] 
;
; Test whether char is to be sent to
; the printer or dealt with specially.
; Set C for special action
;
LXTEST:
    LD    L,A                        ;[4900] 
    LD    A,C                        ;[4901] 
    AND   7                          ;[4902] 
    LD    B,A                        ;[4904] 
    INC   B                          ;[4905] 
    LD    A,(HL)                     ;[4906] 
LXT2:
    RRA                              ;[4907] rotate bit into carry
    DJNZ  LXT2                       ;[4908] 
    LD    A,C                        ;[490A] 
    RET                              ;[490B] 

LXOUT:
    LD    HL,LXTABL                  ;[490C] conversion table
    LD    B,0                        ;[490F] 
    LD    C,A                        ;[4911] 
    ADD   HL,BC                      ;[4912] 
    LD    A,(HL)                     ;[4913] convert the char
    OR    A                          ;[4914] 
    RET   Z                          ;[4915] many of them do nothing
    CP    9                          ;[4916] simulate tab with spaces
    JR    NZ,LX02                    ;[4918] 
    LD    A,(BUFCT)                  ;[491A] 
    LD    B,A                        ;[491D] 
    AND   %11111000                  ;[491E] 
    ADD   8                          ;[4920] (new position)-1
    LD    HL,BUFSIZ                  ;[4922] 
    CP    (HL)                       ;[4925] CP with buffer size
    JR    NC,LX03                    ;[4926] if so, new line
    SUB   B                          ;[4928] get number of spaces
    LD    B,A                        ;[4929] 
LX01:
    LD    A,$20                      ;[492A] 
    PUSH  BC                         ;[492C] 
    CALL  PPCHR4                     ;[492D]
    POP   BC                         ;[4930] 
    DJNZ  LX01                       ;[4931] 
    RET                              ;[4933] 
LX02:
    CP    $13                        ;[4934] conditional linefeed?
    JR    NZ,LX04                    ;[4936] 
    LD    A,(BUFCT)                  ;[4938] yes, start of line?
    OR    A                          ;[493B] 
    RET   Z                          ;[493C] if so, don't send
LX03: 
    LD    A,$0A                      ;[493D] newline char
LX04:
    CALL  PPCHR4                     ;[493F] 
    RET                              ;[4942] 
;
; Table to convert control chars.
;
LXTABL:	
    DB    0,0,0,0,$0C,0,0,0          ;[4943]
    DB    0,9,0,0,$0A,$0A,0,0        ;[494B]
    DB    $0C,0,0,$13,0,0,8,0        ;[4953]
	DB    0,0,0,0,0,0,0,$0A          ;[495B]
;
; NLTEST - test whether control character in C caused a new line
; when it was printed. Set C to flag new line.
;
NLTEST:
    LD    HL,NLFLAG                  ;[4963] 
    LD    C,(HL)                     ;[4966] get flag
    LD    B,6                        ;[4967] number of chars to test
    LD    HL,NLTABL                  ;[4969] list of chars
NLT1:
    CP    (HL)                       ;[496C] 
    JR    Z,NLT2                     ;[496D] 
    INC   HL                         ;[496F] 
    RR    C                          ;[4970] 
    DJNZ  NLT1                       ;[4972] 
    LD    C,0                        ;[4974] 
NLT2:
    RR    C                          ;[4976] 
    RET                              ;[4978] 
;
NLTABL:
    DB    $0A,$0D,$14,$0C,$0B,8,0,0  ;[4979]

;
;------ LIGHTPEN ------
;
; Argument 0 = X,1= Y.
; Range 0 to 256 each way (like text window)
;
FPEN:
    CALL  FPINT                      ;[4981] 
    DEC   H                          ;[4984] 
    INC   H                          ;[4985] 
    CALL  NZ,ERR_NUM_OUT_RANGE       ;[4986] 
    LD    C,$87                      ;[4989] 
    LD    A,$11                      ;[498B] LP low 
    OUT   ($86),A                    ;[498D] 
    IN    E,(C)                      ;[498F] 
    INC   L                          ;[4991] 
    DEC   L                          ;[4992] 
    JR    Z,FLT1                     ;[4993] JR to get X
    DEC   L                          ;[4995] 
    CALL  NZ,ERR_NUM_OUT_RANGE       ;[4996] 
    DEC   A                          ;[4999] LP high
    OUT   ($86),A                    ;[499A] 
    IN    D,(C)                      ;[499C] 
    EX    DE,HL                      ;[499E] 
    ADD   HL,HL                      ;[499F] shift Y into H
    ADD   HL,HL                      ;[49A0] 
    ADD   HL,HL                      ;[49A1] 
    LD    A,(LPOFFS)                 ;[49A2] offset
    AND   %00001111                  ;[49A5] Y part
    RLCA                             ;[49A7] 
    SUB   $10                        ;[49A8] 
    ADD   H                          ;[49AA] 
    JR    FLT2                       ;[49AB]
FLT1:
    SLA   E                          ;[49AD] 
    SLA   E                          ;[49AF] 
    SLA   E                          ;[49B1] 
    LD    A,(LPOFFS)                 ;[49B3] 
    AND   %11110000                  ;[49B6] X part
    RRCA                             ;[49B8] 
    RRCA                             ;[49B9] 
    RRCA                             ;[49BA] 
    SUB   $28                        ;[49BB] 
    ADD   E                          ;[49BD]
FLT2:
    LD    L,A                        ;[49BE] 
    LD    H,0                        ;[49BF] 
    JP    INTFP                      ;[49C1] 
;
; Joystick
; Here with stick no. 0 or 1 in WRA1. Return position in WRA1.
;
FJOY:
    CALL  FPINT                      ;[49C4] stick no. to HL
    DEC   H                          ;[49C7] 
    INC   H                          ;[49C8] 
    CALL  NZ,ERR_NUM_OUT_RANGE       ;[49C9] 
    LD    C,$7A                      ;[49CC] ports are 7A,7B
    INC   L                          ;[49CE] 
    DEC   L                          ;[49CF] 
    JR    Z,FJOYS1                   ;[49D0]
    DEC   L                          ;[49D2] 
    CALL  NZ,ERR_NUM_OUT_RANGE       ;[49D3] 
    INC   C                          ;[49D6] 
FJOYS1:
    IN    A,(C)                      ;[49D7] 
    CPL                              ;[49D9] 
    PUSH  AF                         ;[49DA] 
    AND   %00001111                  ;[49DB] direction bits
    LD    E,A                        ;[49DD] 
    LD    D,0                        ;[49DE] 
    LD    HL,JOYTAB                  ;[49E0] 
    ADD   HL,DE                      ;[49E3] 
    LD    L,(HL)                     ;[49E4] 
    LD    H,0                        ;[49E5] 
    POP   AF                         ;[49E7] 
    BIT   5,A                        ;[49E8] "fire" bit
    JR    Z,FJOYS2                   ;[49EA] 
    INC   H                          ;[49EC] 
FJOYS2:
    JP    INTFP                      ;[49ED] 
;
JOYTAB:	
    DB    0,8,4,0,6,7,5,0,2,1,3      ;[49F0]
;
;------ VIDEO RESET ------
;
EVRS:
    XOR   A                          ;[49FB] 
    OUT   ($80),A                    ;[49FC] 
    LD    BC,$FF7F                   ;[49FE] 
    OUT   (C),A                      ;[4A01] 
    LD    B,$10                      ;[4A03] 
    LD    C,$87                      ;[4A05] 
    LD    HL,D6845                   ;[4A07]
 EVRS1:
    OUT   ($86),A                    ;[4A0A] 
    LD    E,(HL)                     ;[4A0C] 
    OUT   (C),E                      ;[4A0D] 
    INC   A                          ;[4A0F] 
    INC   HL                         ;[4A10] 
    DJNZ  EVRS1                      ;[4A11] 
    LD    HL,VROM                    ;[4A13] 
    LD    DE,SYSVAR_CURSORX          ;[4A16] 
    LD    BC,MOVE                    ;[4A19] 
    LDIR                             ;[4A1C] 
    LD    A,$04                      ;[4A1E] 
    RST   8                          ;[4A20] 
    RET                              ;[4A21] 
;
; Sounds
; EXPLODE
EXPL:
    LD    A,1                        ;[4A22] Speaker on
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
    LD    A,1                        ;[4A5C] Speaker on
    OUT   ($80),A                    ;[4A5E] 
    LD    DE,CYAN                    ;[4A60] 
    LD    C,14                       ;[4A63] 
    CALL  EKLAX1                     ;[4A65] 
    LD    DE,ADDQ                    ;[4A68] 
    LD    C,9                        ;[4A6B] 
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
    CP    64                         ;[4A7B]
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
    LD    A,1                        ;[4A9F] speaker on
    OUT   ($80),A                    ;[4AA1] 
    LD    A,B                        ;[4AA3] 
    JP    _BEEP                      ;[4AA4] use low ROM routine
 ;
 ; ZAP (a sort of tinkling)
 ;
EZAP:
    LD    A,1                        ;[4AA7] 
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
; EXT CIRCLE
;
ECIR:
    RST   $18                        ;[4ACA] 
    INC   DE                         ;[4ACB] 
    PUSH  HL                         ;[4ACC] 
    RST   $18                        ;[4ACD] 
    INC   DE                         ;[4ACE] 
    PUSH  HL                         ;[4ACF] 
    RST   $18                        ;[4AD0] 
    INC   DE                         ;[4AD1] 
    PUSH  HL                         ;[4AD2] 
    RST   $18                        ;[4AD3] 
VQ3:
    PUSH  HL                         ;[4AD4] 
    LD    B,14                       ;[4AD5] 
    LD    HL,SYSVAR_STRBUF+9         ;[4AD7] 
CLL1:
    LD    (HL),0                     ;[4ADA] 
    INC   HL                         ;[4ADC] 
    DJNZ  CLL1                       ;[4ADD] 
;
;
    LD    DE,SYSVAR_STRBUF+8         ;[4ADF] 
    POP   HL                         ;[4AE2] 
    BIT   7,H                        ;[4AE3] 
    JP    NZ,ERR_NUM_OUT_RANGE       ;[4AE5] 
    LD    A,H                        ;[4AE8] 
    AND   $E0                        ;[4AE9] 
    JP    NZ,ERR_NUM_OUT_RANGE       ;[4AEB] 
    LD    A,H                        ;[4AEE] 
    LD    (DE),A                     ;[4AEF] 
    DEC   DE                         ;[4AF0] 
    LD    A,L                        ;[4AF1] 
    LD    (DE),A                     ;[4AF2] 
CLL2:
    DEC   DE                         ;[4AF3] 
    POP   HL                         ;[4AF4] 
    BIT   7,H                        ;[4AF5] 
    LD    A,H                        ;[4AF7] 
    JR    NZ,CLL3                    ;[4AF8] 
    AND   %11100000                  ;[4AFA] 
    JP    NZ,ERR_NUM_OUT_RANGE       ;[4AFC] 
    JP    EX1                        ;[4AFF] 
CLL3:
    CPL                              ;[4B02] 
    ADD   1                          ;[4B03] 
    AND   %01100000                  ;[4B05] 
    JP    NZ,ERR_NUM_OUT_RANGE       ;[4B07] 
EX1:
    LD    A,H                        ;[4B0A] 
    LD    (DE),A                     ;[4B0B] 
    DEC   DE                         ;[4B0C] 
    LD    A,L                        ;[4B0D] 
    LD    (DE),A                     ;[4B0E] 
    DEC   DE                         ;[4B0F] 
    POP   HL                         ;[4B10] 
    BIT   7,H                        ;[4B11] 
    LD    A,H                        ;[4B13] 
    JR    NZ,CLL4                    ;[4B14] 
    AND   %11100000                  ;[4B16] 
    JP    NZ,ERR_NUM_OUT_RANGE       ;[4B18] 
    JP    CLL5                       ;[4B1B] 
CLL4:
    CPL                              ;[4B1E] 
    ADD   1                          ;[4B1F] 
    AND   %01100000                  ;[4B21] 
    JP    NZ,ERR_NUM_OUT_RANGE       ;[4B23] 
CLL5:
    LD    A,H                        ;[4B26] 
    LD    (DE),A                     ;[4B27] 
    DEC   DE                         ;[4B28] 
    LD    A,L                        ;[4B29] 
    LD    (DE),A                     ;[4B2A] 
    DEC   DE                         ;[4B2B] 
    POP   HL                         ;[4B2C] 
    LD    A,H                        ;[4B2D] 
    AND   A                          ;[4B2E] 
    JP    NZ,ERR_NUM_OUT_RANGE       ;[4B2F] 
    LD    A,L                        ;[4B32] 
    AND   %11111110                  ;[4B33] 
    JP    NZ,ERR_NUM_OUT_RANGE       ;[4B35] 
CHI0:
    DEC   DE                         ;[4B38] 
    LD    A,L                        ;[4B39] 
    LD    (DE),A                     ;[4B3A] 
    LD    IX,0                       ;[4B3B] 
    LD    IY,(SYSVAR_STRBUF+7)       ;[4B3F] 
    PUSH  IY                         ;[4B43] 
    PUSH  IY                         ;[4B45] 
    POP   BC                         ;[4B47] 
    POP   DE                         ;[4B48] 
    XOR   A                          ;[4B49] 
    OR    D                          ;[4B4A] 
    OR    E                          ;[4B4B] 
    JP    Z,EXU2                     ;[4B4C] 
    SLA   C                          ;[4B4F] 
    RL    B                          ;[4B51] 
    XOR   A                          ;[4B53] 
    LD    H,A                        ;[4B54] 
    LD    L,1                        ;[4B55] 
    SBC   HL,BC                      ;[4B57] 
    LD    C,L                        ;[4B59] 
    LD    B,H                        ;[4B5A] 
    ADD   HL,DE                      ;[4B5B] 
    LD    DE,1                       ;[4B5C] 
    PUSH  HL                         ;[4B5F] 
    PUSH  DE                         ;[4B60] 
    PUSH  BC                         ;[4B61] 
MLE:
    XOR   A                          ;[4B62] 
    PUSH  IX                         ;[4B63] 
    POP   DE                         ;[4B65] 
    PUSH  IY                         ;[4B66] 
    POP   HL                         ;[4B68] 
    SBC   HL,DE                      ;[4B69] 
    JP    C,EXU                      ;[4B6B] 
    LD    HL,SYSVAR_STRBUF+9         ;[4B6E] 
    PUSH  IX                         ;[4B71] 
    POP   DE                         ;[4B73] 
    LD    (HL),E                     ;[4B74] 
    INC   HL                         ;[4B75] 
    LD    (HL),D                     ;[4B76] 
    INC   HL                         ;[4B77] 
    LD    A,E                        ;[4B78] 
    CPL                              ;[4B79] 
    ADD   1                          ;[4B7A] 
    LD    (HL),A                     ;[4B7C] 
    INC   HL                         ;[4B7D] 
    LD    A,D                        ;[4B7E] 
    CPL                              ;[4B7F] 
    ADC   0                          ;[4B80] 
    LD    (HL),A                     ;[4B82] 
    INC   HL                         ;[4B83] 
    PUSH  IY                         ;[4B84] 
    POP   DE                         ;[4B86] 
    LD    (HL),E                     ;[4B87] 
    INC   HL                         ;[4B88] 
    LD    (HL),D                     ;[4B89] 
    INC   HL                         ;[4B8A] 
    LD    A,E                        ;[4B8B] 
    CPL                              ;[4B8C] 
    ADD   1                          ;[4B8D] 
    LD    (HL),A                     ;[4B8F] 
    INC   HL                         ;[4B90] 
    LD    A,D                        ;[4B91] 
    CPL                              ;[4B92] 
    ADC   0                          ;[4B93] 
    LD    (HL),A                     ;[4B95] 
;
    LD    HL,SYSVAR_STRBUF+3         ;[4B96] 
    LD    DE,SYSVAR_STRBUF+9         ;[4B99] 
    LD    BC,SYSVAR_STRBUF+17        ;[4B9C] 
    CALL  SIG                        ;[4B9F] 
    DEC   HL                         ;[4BA2] 
    INC   BC                         ;[4BA3] 
    INC   DE                         ;[4BA4] 
    CALL  SIG                        ;[4BA5] 
    INC   HL                         ;[4BA8] 
    INC   BC                         ;[4BA9] 
    INC   DE                         ;[4BAA] 
    CALL  SIG                        ;[4BAB] 
    PUSH  HL                         ;[4BAE] 
    PUSH  DE                         ;[4BAF] 
    PUSH  BC                         ;[4BB0] 
    CALL  SCRNT                      ;[4BB1] 
    POP   BC                         ;[4BB4] 
    POP   DE                         ;[4BB5] 
    POP   HL                         ;[4BB6] 
    DEC   HL                         ;[4BB7] 
    DEC   BC                         ;[4BB8] 
    INC   DE                         ;[4BB9] 
    CALL  SIG                        ;[4BBA] 
    CALL  SCRNT                      ;[4BBD] 
;
    LD    HL,SYSVAR_STRBUF+3         ;[4BC0] 
    LD    DE,SYSVAR_STRBUF+13        ;[4BC3] 
    LD    BC,SYSVAR_STRBUF+17        ;[4BC6] 
    CALL  SIG                        ;[4BC9] 
    DEC   HL                         ;[4BCC] 
    INC   DE                         ;[4BCD] 
    INC   BC                         ;[4BCE] 
    CALL  SIG                        ;[4BCF] 
    LD    DE,SYSVAR_STRBUF+9         ;[4BD2] 
    INC   HL                         ;[4BD5] 
    INC   BC                         ;[4BD6] 
    CALL  SIG                        ;[4BD7] 
    PUSH  HL                         ;[4BDA] 
    PUSH  DE                         ;[4BDB] 
    PUSH  BC                         ;[4BDC] 
    CALL  SCRNT                      ;[4BDD] 
    POP   BC                         ;[4BE0] 
    POP   DE                         ;[4BE1] 
    POP   HL                         ;[4BE2] 
    DEC   HL                         ;[4BE3] 
    INC   DE                         ;[4BE4] 
    DEC   BC                         ;[4BE5] 
    CALL  SIG                        ;[4BE6] 
    CALL  SCRNT                      ;[4BE9] 
    POP   BC                         ;[4BEC] 
    POP   DE                         ;[4BED] 
    POP   HL                         ;[4BEE] 
    BIT   7,H                        ;[4BEF] 
    JR    Z,CGAM1                    ;[4BF1] 
    INC   BC                         ;[4BF3] 
    INC   BC                         ;[4BF4] 
    ADD   HL,DE                      ;[4BF5] 
    JR    CGAM2                      ;[4BF6] 
CGAM1:
    DEC   IY                         ;[4BF8] 
    INC   BC                         ;[4BFA] 
    INC   BC                         ;[4BFB] 
    INC   BC                         ;[4BFC] 
    INC   BC                         ;[4BFD] 
    ADD   HL,BC                      ;[4BFE] 
CGAM2:
    INC   DE                         ;[4BFF] 
    INC   DE                         ;[4C00] 
    INC   IX                         ;[4C01] 
    PUSH  HL                         ;[4C03] 
    PUSH  DE                         ;[4C04] 
    PUSH  BC                         ;[4C05] 
    JP    MLE                        ;[4C06] 
EXU:
    POP   BC                         ;[4C09] 
    POP   DE                         ;[4C0A] 
    POP   HL                         ;[4C0B] 
    RET                              ;[4C0C] 
;
EXU2:
    LD    DE,SYSVAR_STRBUF+6         ;[4C0D] 
    LD    A,(DE)                     ;[4C10] 
    AND   A                          ;[4C11] 
    RET   NZ                         ;[4C12] 
    DEC   DE                         ;[4C13] 
    LD    A,(DE)                     ;[4C14] 
    CP    252                        ;[4C15] 
    RET   NC                         ;[4C17] 
    EXX                              ;[4C18] 
    LD    H,A                        ;[4C19] 
    EXX                              ;[4C1A] 
    DEC   DE                         ;[4C1B] 
    LD    A,(DE)                     ;[4C1C] 
    AND   A                          ;[4C1D] 
    RET   NZ                         ;[4C1E] 
    DEC   DE                         ;[4C1F] 
    LD    A,(DE)                     ;[4C20] 
    LD    H,A                        ;[4C21] 
    CALL  SUB_PLOT3                  ;[4C22] 
    RET                              ;[4C25] 
SIG:
    LD    A,(DE)                     ;[4C26] 
    ADD   (HL)                       ;[4C27] 
    LD    (BC),A                     ;[4C28] 
    INC   HL                         ;[4C29] 
    INC   BC                         ;[4C2A] 
    INC   DE                         ;[4C2B] 
    LD    A,(DE)                     ;[4C2C] 
    ADC   (HL)                       ;[4C2D] 
    LD    (BC),A                     ;[4C2E] 
    RET                              ;[4C2F] 
SCRNT:
    LD    DE,SYSVAR_STRBUF+22        ;[4C30] 
    LD    A,(DE)                     ;[4C33] 
    AND   A                          ;[4C34] 
    JR    NZ,NPT0                    ;[4C35] 
    DEC   DE                         ;[4C37] 
    LD    A,(DE)                     ;[4C38] 
    CP    252                        ;[4C39] 
    JP    NC,NPT0                    ;[4C3B] 
;
    LD    HL,SYSVAR_STRBUF+18        ;[4C3E] 
    LD    A,(HL)                     ;[4C41] 
    AND   A                          ;[4C42] 
    JP    M,NPT0                     ;[4C43] 
    LD    HL,SYSVAR_STRBUF+20        ;[4C46] 
    LD    A,(HL)                     ;[4C49] 
    LD    B,0                        ;[4C4A] 
    AND   A                          ;[4C4C] 
    JP    M,QFR1                     ;[4C4D] 
    JR    NZ,NPT0                    ;[4C50] 
    DEC   HL                         ;[4C52] 
    LD    A,(HL)                     ;[4C53] 
    LD    B,A                        ;[4C54] 
    LD    H,A                        ;[4C55] 
    LD    A,(DE)                     ;[4C56] 
    EXX                              ;[4C57] 
    LD    H,A                        ;[4C58] 
    EXX                              ;[4C59] 
    CALL  SUB_PLOT3                  ;[4C5A] 
QFR1:
    LD    HL,SYSVAR_STRBUF+18        ;[4C5D] 
    LD    A,(HL)                     ;[4C60] 
    LD    C,255                      ;[4C61] 
    AND   A                          ;[4C63] 
    JR    NZ,QFR2                    ;[4C64] 
    DEC   HL                         ;[4C66] 
    LD    A,(HL)                     ;[4C67] 
    LD    C,A                        ;[4C68] 
    LD    H,A                        ;[4C69] 
    LD    A,(DE)                     ;[4C6A] 
    EXX                              ;[4C6B] 
    LD    H,A                        ;[4C6C] 
    EXX                              ;[4C6D] 
    CALL  SUB_PLOT3                  ;[4C6E] 
;
QFR2:
    LD    HL,SYSVAR_STRBUF+1         ;[4C71] 
    LD    A,(HL)                     ;[4C74] 
    AND   A                          ;[4C75] 
    JR    Z,QFR3                     ;[4C76] 
    LD    A,B                        ;[4C78] 
    CP    C                          ;[4C79] 
    JR    Z,QFR3                     ;[4C7A] 
    LD    HL,SYSVAR_STRBUF+21        ;[4C7C] 
    LD    A,(HL)                     ;[4C7F] 
    CALL  FILRAM                     ;[4C80] 
QFR3:
NPT0: 
    RET                              ;[4C83]
FILRAM:
    LD    DE,SYSVAR_STRBUF           ;[4C84] 
    LD    (DE),A                     ;[4C87] 
    LD    L,A                        ;[4C88] 
    LD    H,0                        ;[4C89] 
    ADD   HL,HL                      ;[4C8B] 
    ADD   HL,HL                      ;[4C8C] 
    ADD   HL,HL                      ;[4C8D] 
    ADD   HL,HL                      ;[4C8E] 
    ADD   HL,HL                      ;[4C8F] 
    PUSH  HL                         ;[4C90] 
    LD    E,B                        ;[4C91] 
    SRL   E                          ;[4C92] 
    SRL   E                          ;[4C94] 
    SRL   E                          ;[4C96] 
    LD    D,0                        ;[4C98] 
    ADD   HL,DE                      ;[4C9A] 
    EX    DE,HL                      ;[4C9B] 
    POP   HL                         ;[4C9C] 
    PUSH  DE                         ;[4C9D] 
    LD    E,C                        ;[4C9E] 
    SRL   E                          ;[4C9F] 
    SRL   E                          ;[4CA1] 
    SRL   E                          ;[4CA3] 
    LD    D,0                        ;[4CA5] 
    ADD   HL,DE                      ;[4CA7] 
    LD    A,B                        ;[4CA8] 
    LD    DE,$FF80                   ;[4CA9] 
    AND   %00000111                  ;[4CAC] 
    JR    Z,QQ4                      ;[4CAE] 
YY1:
    SRL   D                          ;[4CB0] cb 3a
    DEC   A                          ;[4CB2] 3d
    JR    NZ,YY1                     ;[4CB3] 20 fb
QQ4:
    LD    A,C                        ;[4CB5] 79
    AND   %00000111                  ;[4CB6] e6 07
    JR    Z,QQ6                      ;[4CB8] 28 05
QQ5:
    SRA   E                          ;[4CBA] cb 2b
    DEC   A                          ;[4CBC] 3d
    JR    NZ,QQ5                     ;[4CBD] 20 fb
QQ6:
    POP   BC                         ;[4CBF] c1
    PUSH  HL                         ;[4CC0] e5
    PUSH  BC                         ;[4CC1] c5
    XOR   A                          ;[4CC2] af
    SBC   HL,BC                      ;[4CC3] ed 42
    LD    B,L                        ;[4CC5] 45
    LD    HL,SYSVAR_STRBUF           ;[4CC6] 21 07 64
    LD    A,(HL)                     ;[4CC9] 7e
    EXX                              ;[4CCA] d9
    LD    H,A                        ;[4CCB] 67
    EXX                              ;[4CCC] d9
    JP    Z,EQZ                      ;[4CCD] ca 0a 4d
    JP    M,FEXU                     ;[4CD0] fa 15 4d
    LD    A,D                        ;[4CD3] 7a
    CPL                              ;[4CD4] 2f
    LD    C,A                        ;[4CD5] 4f
    CPL                              ;[4CD6] 2f
    POP   HL                         ;[4CD7] e1
    LD    D,B                        ;[4CD8] 50
    PUSH  DE                         ;[4CD9] d5
    CALL  SYSVAR_OUTB                ;[4CDA] cd 6c 62
;
    LD    HL,SYSVAR_STRBUF           ;[4CDD] 21 07 64
    LD    A,(HL)                     ;[4CE0] 7e
    EXX                              ;[4CE1] d9
    LD    H,A                        ;[4CE2] 67
    EXX                              ;[4CE3] d9
    POP   DE                         ;[4CE4] d1
    LD    A,E                        ;[4CE5] 7b
    CPL                              ;[4CE6] 2f
    LD    C,A                        ;[4CE7] 4f
    CPL                              ;[4CE8] 2f
    POP   HL                         ;[4CE9] e1
    PUSH  HL                         ;[4CEA] e5
    PUSH  DE                         ;[4CEB] d5
    CALL  SYSVAR_OUTB                ;[4CEC] cd 6c 62
    LD    A,$FF                      ;[4CEF] 3e ff
    POP   BC                         ;[4CF1] c1
    LD    C,0                        ;[4CF2] 0e 00
    POP   HL                         ;[4CF4] e1

    DEC     HL                              ;[4CF5] 2b
    LD      DE,SYSVAR_STRBUF                ;[4CF6] 11 07 64
    LD      A,(DE)                          ;[4CF9] 1a
    EXX                                     ;[4CFA] d9
    LD      H,A                             ;[4CFB] 67
    EXX                                     ;[4CFC] d9
    LD      A,$FF                           ;[4CFD] 3e ff
    DEC     B                               ;[4CFF] 05
    JR      Z,EQZ1                          ;[4D00] 28 12
    PUSH    BC                              ;[4D02] c5
    CALL    SYSVAR_OUTB                     ;[4D03] cd 6c 62
    POP     BC                              ;[4D06] c1
    JP      $4CF5                           ;[4D07] c3 f5 4c
EQZ:
    LD      A,E                             ;[4D0A] 7b
    AND     D                               ;[4D0B] a2
    CPL                                     ;[4D0C] 2f
    LD      C,A                             ;[4D0D] 4f
    CPL                                     ;[4D0E] 2f
    POP     HL                              ;[4D0F] e1
    POP     HL                              ;[4D10] e1
    CALL    SYSVAR_OUTB                     ;[4D11] cd 6c 62
EQZ1:
    RET                                     ;[4D14] c9
FEXU:
    POP     HL                              ;[4D15] e1
    POP     HL                              ;[4D16] e1
    RET                                     ;[4D17] c9
;
; EXT TRIANGLE (orig version - rewritten Dec'83)
; 
ETRI:
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
    LD      C,0                             ;[4D2A] 0e 00
    LD      DE,SYSVAR_STRBUF+16             ;[4D2C] 11 17 64
    LD      B,3                             ;[4D2F] 06 03
LL1:
    POP     HL                              ;[4D31] e1
    BIT     7,H                             ;[4D32] cb 7c
    JP      NZ,ERR_NUM_OUT_RANGE            ;[4D34] c2 29 3b
    LD      A,L                             ;[4D37] 7d
    CP      252                             ;[4D38] fe fc
    JP      NC,ERR_NUM_OUT_RANGE            ;[4D3A] d2 29 3b
    LD      (DE),A                          ;[4D3D] 12
    CP      C                               ;[4D3E] b9
    JR      C,LL3                           ;[4D3F] 38 01
    LD      C,A                             ;[4D41] 4f
LL3:
    DEC     DE                              ;[4D42] 
    POP     HL                              ;[4D43] 
    BIT     7,H                             ;[4D44] 
    JP      NZ,ERR_NUM_OUT_RANGE            ;[4D46] 
    LD      A,L                             ;[4D49] 
    LD      (DE),A                          ;[4D4A] 
    DEC     DE                              ;[4D4B] 
    DJNZ    LL1                             ;[4D4C] 
;
    LD      A,C                             ;[4D4E] 79
    LD      HL,SYSVAR_STRBUF+17             ;[4D4F] 21 18 64
    LD      B,$03                           ;[4D52] 06 03
; ??
    DEC     HL                              ;[4D54] 2b
    CP      (HL)                            ;[4D55] be
    JR      NZ,TBD1                         ;[4D56] 20 01
    LD      E,B                             ;[4D58] 58
TBD1:
    DEC     HL                              ;[4D59] 2b
    DJNZ    $4D54                           ;[4D5A] 10 f8
    DEC     HL                              ;[4D5C] 2b
    LD      (HL),E                          ;[4D5D] 73
    LD      B,$03                           ;[4D5E] 06 03
    LD      HL,SYSVAR_STRBUF+17             ;[4D60] 21 18 64
    LD      C,$FD                           ;[4D63] 0e fd
TBD2:
    DEC     HL                              ;[4D65] 2b
    LD      A,(HL)                          ;[4D66] 7e
    CP      C                               ;[4D67] b9
    JR      Z,TBD3                          ;[4D68] 28 03
    JR      NC,TBD4                         ;[4D6A] 30 02
    LD      C,A                             ;[4D6C] 4f
TBD3:
    LD      E,B                             ;[4D6D] 58
TBD4:
    DEC     HL                              ;[4D6E] 2b
    DJNZ    TBD2                            ;[4D6F] 10 f4
    LD      HL,SYSVAR_STRBUF+10             ;[4D71] 21 11 64
    LD      A,(HL)                          ;[4D74] 7e
;
    LD      C,A                             ;[4D75] 4f
    XOR     E                               ;[4D76] ab
    LD      D,A                             ;[4D77] 57
    JR      NZ,TAU                          ;[4D78] 20 05
    INC     A                               ;[4D7A] 3c
    LD      E,A                             ;[4D7B] 5f
    INC     A                               ;[4D7C] 3c
    LD      C,A                             ;[4D7D] 4f
    INC     C                               ;[4D7E] 0c
TAU:
    LD      B,0                             ;[4D7F] 06 00
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
    LD      L,(IX+0)                        ;[4D92] dd 6e 00
    LD      C,(IY+0)                        ;[4D95] fd 4e 00
    CALL    $4E74                           ;[4D98] cd 74 4e
    LD      L,(IX+1)                        ;[4D9B] dd 6e 01
    LD      E,(IY+1)                        ;[4D9E] fd 5e 01
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
    LD      HL,SYSVAR_STRBUF+9              ;[4DB3] 21 10 64
    POP     BC                              ;[4DB6] c1
    PUSH    BC                              ;[4DB7] c5
    LD      B,0                             ;[4DB8] 06 00
    SLA     C                               ;[4DBA] cb 21
    ADD     HL,BC                           ;[4DBC] 09
    PUSH    HL                              ;[4DBD] e5
    EX      (SP),IY                         ;[4DBE] fd e3
    LD      L,(IX+0)                        ;[4DC0] dd 6e 00
    LD      C,(IY+0)                        ;[4DC3] fd 4e 00
    CALL    $4E74                           ;[4DC6] cd 74 4e
    LD      E,(IY+1)                        ;[4DC9] fd 5e 01
    LD      L,(IX+1)                        ;[4DCC] dd 6e 01
    SBC     HL,DE                           ;[4DCF] ed 52
    CALL    Z,$4EF4                         ;[4DD1] cc f4 4e
    JR      Z,$4DD9                         ;[4DD4] 28 03
    CALL    $4E8A                           ;[4DD6] cd 8a 4e
    LD      HL,SYSVAR_STRBUF+4              ;[4DD9] 21 0b 64
    LD      (HL),E                          ;[4DDC] 73
    INC     HL                              ;[4DDD] 23
    LD      (HL),C                          ;[4DDE] 71
    INC     HL                              ;[4DDF] 23
    LD      (HL),B                          ;[4DE0] 70
    EX      (SP),IX                         ;[4DE1] dd e3
    LD      L,(IX+0)                        ;[4DE3] dd 6e 00
    LD      C,(IY+0)                        ;[4DE6] fd 4e 00
    CALL    $4E74                           ;[4DE9] cd 74 4e
    LD      L,(IX+1)                        ;[4DEC] dd 6e 01
    LD      E,(IY+1)                        ;[4DEF] fd 5e 01
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
    LD      HL,SYSVAR_STRBUF+17             ;[4E06] 21 18 64
    LD      (HL),0                          ;[4E09] 36 00
    INC     HL                              ;[4E0B] 23
    DJNZ    $4E09                           ;[4E0C] 10 fb
    LD      HL,$6419                        ;[4E0E] 21 19 64
    LD      A,(IY+0)                        ;[4E11] fd 7e 00
    LD      (HL),A                          ;[4E14] 77
    LD      HL,$641C                        ;[4E15] 21 1c 64
    LD      (HL),A                          ;[4E18] 77
    LD      B,A                             ;[4E19] 47
    LD      C,A                             ;[4E1A] 4f
    LD      A,(IX+1)                        ;[4E1B] dd 7e 01
    LD      E,(IY+1)                        ;[4E1E] fd 5e 01
    LD      D,E                             ;[4E21] 53
    SUB     E                               ;[4E22] 93
    LD      E,A                             ;[4E23] 5f
    LD      A,D                             ;[4E24] 7a
    EX      (SP),IY                         ;[4E25] fd e3
    PUSH    DE                              ;[4E27] d5
    JR      NZ,$4E34                        ;[4E28] 20 0a
    LD      C,(IX+0)                        ;[4E2A] dd 4e 00
    LD      (HL),C                          ;[4E2D] 71
    LD      A,C                             ;[4E2E] 79
    CALL    $4EE2                           ;[4E2F] cd e2 4e
    JR      $4E41                           ;[4E32] 18 0d
    CALL    FILRAM                          ;[4E34] cd 84 4c
    CALL    $4EB4                           ;[4E37] cd b4 4e
    INC     HL                              ;[4E3A] 23
    INC     DE                              ;[4E3B] 13
    CALL    $4ECE                           ;[4E3C] cd ce 4e
    JR      NZ,$4E37                        ;[4E3F] 20 f6

    POP     DE                              ;[4E41] d1
    LD      A,(IY+1)                        ;[4E42] fd 7e 01
    LD      D,(IX+1)                        ;[4E45] dd 56 01
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
    LD      B,(IX+0)                        ;[4E61] dd 46 00
    LD      C,(IY+0)                        ;[4E64] fd 4e 00
    LD      A,C                             ;[4E67] 79
    CP      B                               ;[4E68] b8
    JR      NC,$4E6D                        ;[4E69] 30 02
    LD      C,B                             ;[4E6B] 48
    LD      B,A                             ;[4E6C] 47
    LD      A,(IY+1)                        ;[4E6D] fd 7e 01
    CALL    FILRAM                          ;[4E70] cd 84 4c
    RET                                     ;[4E73] c9
;
    XOR     A                               ;[4E74] af
    LD      H,A                             ;[4E75] 67
    LD      B,A                             ;[4E76] 47
    SBC     HL,BC                           ;[4E77] ed 42
    PUSH    HL                              ;[4E79] e5
    JP      P,$4E82                         ;[4E7A] f2 82 4e
    CPL                                     ;[4E7D] 2f
    XOR     L                               ;[4E7E] ad
    ADD     1                               ;[4E7F] c6 01
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
    ADD     1                               ;[4E90] c6 01

    LD      E,A                             ;[4E92] 5f
    LD      A,C                             ;[4E93] 79
    LD      C,0                             ;[4E94] 0e 00
    CALL    $4F04                           ;[4E96] cd 04 4f
    LD      E,C                             ;[4E99] 59
    LD      C,A                             ;[4E9A] 4f
    POP     HL                              ;[4E9B] e1
    LD      A,H                             ;[4E9C] 7c
    POP     HL                              ;[4E9D] e1
    EX      (SP),HL                         ;[4E9E] e3
    XOR     H                               ;[4E9F] ac
    LD      B,0                             ;[4EA0] 06 00
    JP      P,$4EB3                         ;[4EA2] f2 b3 4e
    LD      B,$FF                           ;[4EA5] 06 ff
    LD      A,E                             ;[4EA7] 7b
    CPL                                     ;[4EA8] 2f
    ADD     1                               ;[4EA9] c6 01
    LD      E,A                             ;[4EAB] 5f
    LD      A,C                             ;[4EAC] 79
    CPL                                     ;[4EAD] 2f
    LD      C,A                             ;[4EAE] 4f
    JP      NC,$4EB3                        ;[4EAF] d2 b3 4e
    INC     BC                              ;[4EB2] 03

    RET                                     ;[4EB3] c9
;
SR3:
    LD    HL,SYSVAR_STRBUF+4        ;[4EB4] 
    LD    DE,SYSVAR_STRBUF+17       ;[4EB7] 
    CALL  $4EF9                     ;[4EBA] 
    LD    B,A                       ;[4EBD] 
    LD    A,(DE)                    ;[4EBE] 
    ADC   (HL)                      ;[4EBF] 
    LD    (DE),A                    ;[4EC0] 
    AND   A                         ;[4EC1] 
    JP    P,SR4                     ;[4EC2] 
    LD    B,0                       ;[4EC5] 
    JR    ETA2                      ;[4EC7] 
SR4:
    JR    Z,ETA2                    ;[4EC9] 
    LD    B,$FF                     ;[4ECB] 

    RET                             ;[4ECD] 

    CALL  $4EF9                     ;[4ECE] 
    LD    C,A                       ;[4ED1] 
    LD    A,(DE)                    ;[4ED2] 
    ADC   (HL)                      ;[4ED3] 
    LD    (DE),A                    ;[4ED4] 
    AND   A                         ;[4ED5] 
    JP    P,$4EDD                   ;[4ED6] 
    LD    C,0                       ;[4ED9] 

    JR    $4EE1                     ;[4EDB] 

    JR    Z,$4EE1                   ;[4EDD] 
    LD    C,$FF                     ;[4EDF] 

    LD    A,C                       ;[4EE1] 

    LD    C,A                       ;[4EE2] 
    CP    B                         ;[4EE3] 
    JR    NC,$4EE8                  ;[4EE4] 
    LD    C,B                       ;[4EE6] 
    LD    B,A                       ;[4EE7] 

    POP   HL                        ;[4EE8] 
    EX    (SP),HL                   ;[4EE9] 
    LD    A,H                       ;[4EEA] 
    PUSH  HL                        ;[4EEB] 
    CALL  FILRAM                    ;[4EEC] 
    POP   HL                        ;[4EEF] 
    INC   H                         ;[4EF0] 
    DEC   L                         ;[4EF1] 
    EX    (SP),HL                   ;[4EF2] 
    JP    (HL)                      ;[4EF3] 

    POP   HL                        ;[4EF4] 
    POP   BC                        ;[4EF5] 
    LD    E,0                       ;[4EF6] 
    JP    (HL)                      ;[4EF8] 

    LD    A,(DE)                    ;[4EF9] 
    ADD   (HL)                      ;[4EFA] 
    LD    (DE),A                    ;[4EFB] 
    INC   DE                        ;[4EFC] 
    INC   HL                        ;[4EFD] 
    LD    A,(DE)                    ;[4EFE] 
    ADC   (HL)                      ;[4EFF] 
    LD    (DE),A                    ;[4F00] 
    INC   HL                        ;[4F01] 
    INC   DE                        ;[4F02] 
    RET                             ;[4F03] 

    LD    HL,0                      ;[4F04] 
    LD    B,$10                     ;[4F07] 
    AND   A                         ;[4F09] 
ZZ1:
    RL    C                         ;[4F0A] 
    RLA                             ;[4F0C] 
    ADC   HL,HL                     ;[4F0D] 
    SBC   HL,DE                     ;[4F0F] 
    JR    NC,XLE                    ;[4F11] 
    ADD   HL,DE                     ;[4F13] 
XLE:
    CCF                             ;[4F14] 
    DJNZ  ZZ1                       ;[4F15] 
    RL    C                         ;[4F17] 
    RLA                             ;[4F19] 
    RET                             ;[4F1A] 
;
; CLW
;
ECLW:
    CALL  SW                        ;[4F1B] 
    LD    HL,(SYSVAR_WINDST)        ;[4F1E] 
    LD    DE,(SYSVAR_WINDST+2)      ;[4F21] 
    LD    A,L                       ;[4F25] 
    LD    (SYSVAR_CURSORX),A        ;[4F26] 
    LD    A,E                       ;[4F29] 
    LD    (SYSVAR_CURSORY),A        ;[4F2A] 
    ADD   HL,HL                     ;[4F2D] 
    LD    A,D                       ;[4F2E] 
    SUB   E                         ;[4F2F] 
    LD    B,L                       ;[4F30] 
    LD    C,H                       ;[4F31] 
    INC   C                         ;[4F32] 
WLL1:
    PUSH  AF                        ;[4F33] 
    LD    A,E                       ;[4F34] 
    PUSH  BC                        ;[4F35] 
    PUSH  DE                        ;[4F36] 
    CALL  FILRAM                    ;[4F37] 
    POP   DE                        ;[4F3A] 
    POP   BC                        ;[4F3B] 
    POP   AF                        ;[4F3C] 
    INC   E                         ;[4F3D] 
    DEC   A                         ;[4F3E] 
    JR    NZ,WLL1                   ;[4F3F] 
SW:
    LD    HL,(SYSVAR_INKST)         ;[4F41] 
    LD    E,H                       ;[4F44] 
    LD    H,L                       ;[4F45] 
    LD    L,E                       ;[4F46] 
    LD    (SYSVAR_INKST),HL         ;[4F47] 
    RET                             ;[4F4A] 

;
; Padding
;
DEFS 165,$FF
;
; Unknown values. Unused?
;
    LD    H,H                       ;[4FF0] 
    LD    E,C                       ;[4FF1] 
    LD    H,H                       ;[4FF2] 
    LD    D,E                       ;[4FF3] 
    LD    E,B                       ;[4FF4] 
;
; Padding
;
DEFS 11,$0
;
DEPHASE
