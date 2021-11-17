
;***********************************************************************
;*
;*          Camputers Lynx 48k ROM disassembly (version L014)
;*          -------------------------------------------------
;*
;*   Reconstructed from lynx eprom memory images and supplemented with
;*   information from Lynx User Magazine Issue 1 (Camputers, June 1983, 
;*   pages 16-18), Nilug News (Issue 6) by R.B.Poate, and Camputers
;*   Lynx "Mark II" source code (dated: 1-Apr-1984).
;*
;*   Disassembly, collation and formatting by: Mike Panter 06/11/2021.
;*
;*   Additional credit to: Russell Davis  (online archive of materials)
;*                         Pete Todd      (knowledge, insight and Pale)
;*
;*   WARNING: May contain inaccuracies - use at own risk.
;*
;*   Free to distribute. Please include attribution.
;*
;********************** LABELS/SYMBOLS/PREFIXES ************************
;*
;*      SYSVAR_     - RAM addresses used by the Lynx ROM routines
;*      RST_        - Z80 Restarts
;*      DATA_       - Data tables stored in rom (eg. PI)
;*      BASIC_COM_  - Lynx BASIC commands 
;*      BASIC_FN_   - Lynx BASIC functions/operators
;*      MONITOR_    - Lynx MONITOR commands
;*      VDU_        - VDU commands
;*      SUB_        - internal subroutines used by ROM
;*
;* ---------------------------------------------------------------------
;*     COMPILE/ASSEMBLE: z88dk-z80asm -b -mz80 Lynx_48k_Rom.asm
;* ---------------------------------------------------------------------
;*

;
; Lynx global definitions (see separate files)
; Lynx symbols and BASIC tokens
;
include "Lynx.def"
include "Tokens.def"

;
; Start. Disable interrupts. Jump to 3B.
;
BEGIN:
    DI                              ;[0000] 
    LD    A,$20                     ;[0001] 
    OUT   ($80),A                   ;[0003] 
    JP    INIT_CRT                  ;[0005] 

;
; Output character in the A register
;
RST_8:
    JP    PUTCHAR                   ;[0008] 

;
; Rom version identifier L014
;
DATA_L014:
    DB $20,$4C,$30,$31,$34          ;[000B]  .L014

;
; Checks if the character at the address pointed to by DE is a space.
;  - If so, increments DE until it is not a space.
;
RST_10:
    LD    A,(DE)                    ;[0010] 
    CP    ' '                       ;[0011] 
    RET   NZ                        ;[0013] 
    INC   DE                        ;[0014] 
    JR    RST_10                    ;[0015] 
    NOP                             ;[0017] 

;
; Evaluates the reverse polish expression pointed to by DE as a binary integer in HL. 
;
RST_18:
    JP    SUB_ARGUMENT              ;[0018] 

;
; Sue Jansons - who wrote the User Manual
;
SUSY:
    DB    "Susy",$00                ;[001B] 

;
; Checks if the byte after RST is the same as A; if it is not, displays a syntax error. 
;
RST_20:
    EX    (SP),HL                   ;[0020] 
    CP    (HL)                      ;[0021] 
    INC   HL                        ;[0022] 
    EX    (SP),HL                   ;[0023] 
    RET   Z                         ;[0024] 
    CALL  ERR_SYNTAX                ;[0025] 

;
; Evaluates reverse polish expression pointed to by DE in floating point 
; in WRA1 (working register area 1).
;
RST_28:
    JP    SUB_CHK_EXP_EVAL          ;[0028] 
    NOP                             ;[002B] 
    NOP                             ;[002C] 
    NOP                             ;[002D] 
    NOP                             ;[002E] 
    NOP                             ;[002F] 

;
; Jumps to monitor TRAP routine. 
;
RST_30:
    JP    BASIC_COM_MON             ;[0030] 
    POP   HL                        ;[0033] Has POP HL JP (HL) 
    JP    (HL)                      ;[0034] 
    NOP                             ;[0035] 
    NOP                             ;[0036] 
    NOP                             ;[0037] 

;
; NOT YET IMPLEMENTED. Jumps to RAM RSTRAM (see RAM variables).
;
RST_38:
    JP    SYSVAR_RSTRAM             ;[0038] 

;
; Initialise the 6845 CRT controller.
;
INIT_CRT:
    XOR   A                         ;[003B] 
    LD    BC,$FF7F                  ;[003C] 
    OUT   (C),A                     ;[003F] 
    LD    B,$10                     ;[0041] 
    LD    HL,D6845                  ;[0043] 
    XOR   A                         ;[0046] 
INIT_CRT1:
    OUT   ($86),A                   ;[0047] 
    EX    AF,AF'                    ;[0049] 
    LD    A,(HL)                    ;[004A] 
    OUT   ($87),A                   ;[004B] 
    EX    AF,AF'                    ;[004D] 
    INC   A                         ;[004E] 
    INC   HL                        ;[004F] 
    DJNZ  INIT_CRT1                 ;[0050] 
    JP    INIT                      ;[0052] 
    NOP                             ;[0055] 

;
; CRT controller registers.
;
D6845:
    DB    $2F  ;R0=h total          ;[0056] 
    DB    $20  ;R1=h displayed      ;[0057] 
    DB    $26  ;R2=h sync posn      ;[0058] 
    DB    $33  ;R3=h sync width     ;[0059] 
    DB    $4D  ;R4=v total          ;[005A] 
    DB    $02  ;R5=v total adjust   ;[005B] 
    DB    $3F  ;R6=v displayed      ;[005C] 
    DB    $44  ;R7=v sync posn      ;[005D] 
    DB    $00  ;R8=interlace        ;[005E] 
    DB    $03  ;R9=max scanline adr ;[005F] 
    DB    $03  ;R10=cursor start    ;[0060] 
    DB    $03  ;R11=cursor end      ;[0061] 
    DB    $00  ;R12=start hi        ;[0062] 
    DB    $00  ;R13=start lo        ;[0063] 
    DB    $07  ;R14=cursor hi       ;[0064] 
    DB    $DF  ;R15=cursor lo       ;[0065] 

;
; Non-maskable interrupt routine, pointer in RAM
;
NMI_JUMP:
    JP    SYSVAR_NMIRAM             ;[0066] 

;
; Reads byte in red/blue bank at HL into L, and H=0. 
;
INBLUE:
    LD    A,$E8                     ;[0069] 
    EX    AF,AF'                    ;[006B] 
    LD    A,$63                     ;[006C] 
    JR    INBANK                    ;[006E] 

;
; Reads byte in green/alternative green bank at HL into L, and H=0. 
;
INGREEN:
    LD    A,$E4                     ;[0070] 
    EX    AF,AF'                    ;[0072] 
    LD    A,$65                     ;[0073] 
INBANK:
    LD    BC,$FF7F                  ;[0075] 
    OUT   (C),A                     ;[0078] 
    LD    A,$40                     ;[007A] 
    OUT   ($80),A                   ;[007C] 
    EX    AF,AF'                    ;[007E] 
    OUT   ($80),A                   ;[007F] 
    LD    L,(HL)                    ;[0081] 
    XOR   A                         ;[0082] 
    OUT   ($80),A                   ;[0083] 
    OUT   (C),A                     ;[0085] 
    LD    H,A                       ;[0087] 
    RET                             ;[0088] 

;
; Used by keyboard driver
;
KBD_TEST:
    PUSH  BC                        ;[0089] 
    LD    BC,$0500                  ;[008A] 
    CALL  KEYRPT_WAIT               ;[008D] 
    POP   BC                        ;[0090] 
    IN    A,(C)                     ;[0091] 
    CPL                             ;[0093] 
    RET                             ;[0094] 

    AND   (HL)                      ;[0095] Probably unused
    LD    B,B                       ;[0096] 
    SBC   A,B                       ;[0097] 
    RET   PE                        ;[0098] 
    RET   Z                         ;[0099] 

;
; Character Output Routine (via SYSVAR_VIDEO)
;
VIDEO:
    PUSH  HL                        ;[009A] 
    LD    HL,(SYSVAR_BPERL)         ;[009B] 32 bytes per line (usually)
    BIT   6,L                       ;[009E] Is double height?
    POP   HL                        ;[00A0] 
    JP    Z,VIDEO_GETPOS            ;[00A1] If NOT double height chars.
    PUSH  AF                        ;[00A4] 
    CALL  VIDEO_GETPOS              ;[00A5] 
    LD    A,$20                     ;[00A8] 
    CALL  VIDEO_WBANKS              ;[00AA] 
    POP   AF                        ;[00AD] 
    PUSH  AF                        ;[00AE] 
    CALL  VIDEO_GETPOS              ;[00AF] 
    XOR   A                         ;[00B2] 
    CALL  VIDEO_WBANKS              ;[00B3] 
    POP   AF                        ;[00B6] 
    RET                             ;[00B7] 

VIDEO_WBANKS:
    LD    (SYSVAR_BLUBNK),A         ;[00B8] &8000
    LD    (SYSVAR_REDBNK),A         ;[00BB] &C000
    LD    (SYSVAR_GRNBNK),A         ;[00BE] &C000
    RET                             ;[00C1] 

VIDEO_GETPOS:
    PUSH  AF                        ;[00C2] 
    PUSH  HL                        ;[00C3] 
    PUSH  DE                        ;[00C4] 
    PUSH  BC                        ;[00C5] 
    CALL  VIDEO_POS                 ;[00C6] 
    POP   BC                        ;[00C9] 
    POP   DE                        ;[00CA] 
    POP   HL                        ;[00CB] 
    POP   AF                        ;[00CC] 
    RET                             ;[00CD] 

;
; Takes character in A and gives the address (in HL) of the character bitmap, 
; within the alphanumeric or graphic character bitmap tables.
; (called from VIDEO_POS, and LETTER function)
;
FONT:
    LD    HL,(SYSVAR_CHRTBL)        ;[00CE] 
    BIT   7,A                       ;[00D1] 
    JR    Z,FONT_OFFSET             ;[00D3] < 128 ? Alpha chars
    LD    HL,(SYSVAR_GPHTBL)        ;[00D5] > 127 ? Graphic chars
FONT_OFFSET:
    AND   $7F                       ;[00D8] 
    PUSH  HL                        ;[00DA] 
    LD    L,A                       ;[00DB] Let HL=char no.
    LD    H,$00                     ;[00DC] 
    ADD   HL,HL                     ;[00DE] Shift left
    LD    E,L                       ;[00DF] Let DE=HL
    LD    D,H                       ;[00E0] 
    ADD   HL,HL                     ;[00E1] Shift left
    ADD   HL,HL                     ;[00E2] Shift left
    ADD   HL,DE                     ;[00E3] Let HL=HL+DE
    POP   DE                        ;[00E4] Let DE = CHR/GPHTBL
    ADD   HL,DE                     ;[00E5] Let HL = CHRTBL+HL (offset)
    RET                             ;[00E6] 

;
; Get bitmap and physical address/location for a character on screen
; (called from VIDEO-->VIDEO_GETPOS)
;
VIDEO_POS:
    CALL  FONT                      ;[00E7] 
    EX    DE,HL                     ;[00EA] Let DE = font TBL offset
    LD    HL,(SYSVAR_CURSORY)       ;[00EB] 
    LD    H,$00                     ;[00EE] 
    LD    A,(SYSVAR_BPERL)          ;[00F0] 
    SRL   A                         ;[00F3] 
VIDEO_YPOS:
    ADD   HL,HL                     ;[00F5] Deduce Y-Pos and handle double-height.
    SRL   A                         ;[00F6] 
    JR    NZ,VIDEO_YPOS             ;[00F8] 
VIDEO_XPOS:
    LD    A,(SYSVAR_CURSORX)        ;[00FA] 
    RRCA                            ;[00FD] 
    RRCA                            ;[00FE] 
    AND   $3F                       ;[00FF] 
    LD    C,A                       ;[0101] 
    LD    B,$00                     ;[0102] 
    ADD   HL,BC                     ;[0104] 
    LD    A,(SYSVAR_CURSORX)        ;[0105] 
    AND   $03                       ;[0108] 
    JR    Z,JUMP_XPOS1              ;[010A] Choose one of three xpos1/2/3 routines based on X pos.
    DEC   A                         ;[010C] 
    JR    Z,JUMP_XPOS2              ;[010D] 
    DEC   A                         ;[010F] 
    JR    Z,CALL_XPOS3              ;[0110] 
    JR    CALL_XPOS4                ;[0112] 
JUMP_XPOS2:
    JP    VIDEO_XPOS2               ;[0114] 
JUMP_XPOS1:
    JP    VIDEO_XPOS1               ;[0117] 
CALL_XPOS4:
    PUSH  HL                        ;[011A] 
    PUSH  DE                        ;[011B] 
    CALL  VIDEO_XPOS4               ;[011C] 
    POP   DE                        ;[011F] 
    POP   HL                        ;[0120] 
    INC   HL                        ;[0121] 
    JP    VIDEO_XPOS4B              ;[0122] 
CALL_XPOS3:
    PUSH  HL                        ;[0125] 
    PUSH  DE                        ;[0126] 
    CALL  VIDEO_XPOS3               ;[0127] 
    POP   DE                        ;[012A] 
    POP   HL                        ;[012B] 
    INC   HL                        ;[012C] 
    JP    VIDEO_XPOS3B              ;[012D] 

;
; First of four screen position routines (see Nilug 1) <DISPLAY.MAC: VID1>
;
VIDEO_XPOS1:
    LD    B,$0A                     ;[0130] 
VIDEO_XPOS1A:
    PUSH  BC                        ;[0132] 
    LD    A,(SYSVAR_MASK)           ;[0133] 
    OR    $03                       ;[0136] 
    LD    C,A                       ;[0138] 
    LD    A,(DE)                    ;[0139] 
    RLCA                            ;[013A] 
    RLCA                            ;[013B] 
    AND   $FC                       ;[013C] 
    CALL  SYSVAR_OUTB               ;[013E] 
    LD    BC,(SYSVAR_BPERL)         ;[0141] 
    ADD   HL,BC                     ;[0145] 
    INC   DE                        ;[0146] 
    POP   BC                        ;[0147] 
    DJNZ  VIDEO_XPOS1A              ;[0148] 
    RET                             ;[014A] 

;
; Second of four screen position routines (see Nilug 1) <DISPLAY.MAC: VID2>
;
VIDEO_XPOS2:
    LD    B,$0A                     ;[014B] 
VIDEO_XPOS2A:
    PUSH  BC                        ;[014D] 
    LD    A,(SYSVAR_MASK)           ;[014E] 
    OR    $C0                       ;[0151] 
    LD    C,A                       ;[0153] 
    LD    A,(DE)                    ;[0154] 
    AND   $3F                       ;[0155] 
    CALL  SYSVAR_OUTB               ;[0157] 
    LD    BC,(SYSVAR_BPERL)         ;[015A] 
    ADD   HL,BC                     ;[015E] 
    INC   DE                        ;[015F] 
    POP   BC                        ;[0160] 
    DJNZ  VIDEO_XPOS2A              ;[0161] 
    RET                             ;[0163] 

VIDEO_XPOS4B:
    LD    B,$0A                     ;[0164] 
VIDEO_XPOS4C:
    PUSH  BC                        ;[0166] 
    LD    A,(SYSVAR_MASK)           ;[0167] 
    OR    $0F                       ;[016A] 
    LD    C,A                       ;[016C] 
    LD    A,(DE)                    ;[016D] 
    RLCA                            ;[016E] 
    RLCA                            ;[016F] 
    RLCA                            ;[0170] 
    RLCA                            ;[0171] 
    AND   $F0                       ;[0172] 
    CALL  SYSVAR_OUTB               ;[0174] 
    LD    BC,(SYSVAR_BPERL)         ;[0177] 
    ADD   HL,BC                     ;[017B] 
    INC   DE                        ;[017C] 
    POP   BC                        ;[017D] 
    DJNZ  VIDEO_XPOS4C              ;[017E] 
    RET                             ;[0180] 

;
; Fourth of four screen position routines (see Nilug 1)
;
VIDEO_XPOS4:
    LD    B,$0A                     ;[0181] 
VIDEO_XPOS4A:
    PUSH  BC                        ;[0183] 
    LD    A,(SYSVAR_MASK)           ;[0184] 
    OR    $FC                       ;[0187] 
    LD    C,A                       ;[0189] 
    LD    A,(DE)                    ;[018A] 
    RLCA                            ;[018B] 
    RLCA                            ;[018C] 
    RLCA                            ;[018D] 
    RLCA                            ;[018E] 
    AND   $03                       ;[018F] 
    CALL  SYSVAR_OUTB               ;[0191] 
    LD    BC,(SYSVAR_BPERL)         ;[0194] 
    ADD   HL,BC                     ;[0198] 
    INC   DE                        ;[0199] 
    POP   BC                        ;[019A] 
    DJNZ  VIDEO_XPOS4A              ;[019B] 
    RET                             ;[019D] 

VIDEO_XPOS3B:
    LD    B,$0A                     ;[019E] 
VIDEO_XPOS3C:
    PUSH  BC                        ;[01A0] 
    LD    A,(SYSVAR_MASK)           ;[01A1] 
    OR    $3F                       ;[01A4] 
    LD    C,A                       ;[01A6] 
    LD    A,(DE)                    ;[01A7] 
    RRCA                            ;[01A8] 
    RRCA                            ;[01A9] 
    AND   $C0                       ;[01AA] 
    CALL  SYSVAR_OUTB               ;[01AC] 
    LD    BC,(SYSVAR_BPERL)         ;[01AF] 
    ADD   HL,BC                     ;[01B3] 
    INC   DE                        ;[01B4] 
    POP   BC                        ;[01B5] 
    DJNZ  VIDEO_XPOS3C              ;[01B6] 
    RET                             ;[01B8] 

;
; Third of four screen position routines (see Nilug 1)
;
VIDEO_XPOS3:
    LD    B,$0A                     ;[01B9] 
VIDEO_XPOS3A:
    PUSH  BC                        ;[01BB] 
    LD    A,(SYSVAR_MASK)           ;[01BC] 
    OR    $F0                       ;[01BF] 
    LD    C,A                       ;[01C1] 
    LD    A,(DE)                    ;[01C2] 
    RRCA                            ;[01C3] 
    RRCA                            ;[01C4] 
    AND   $0F                       ;[01C5] 
    CALL  SYSVAR_OUTB               ;[01C7] 
    LD    BC,(SYSVAR_BPERL)         ;[01CA] 
    ADD   HL,BC                     ;[01CE] 
    INC   DE                        ;[01CF] 
    POP   BC                        ;[01D0] 
    DJNZ  VIDEO_XPOS3A              ;[01D1] 
    RET                             ;[01D3] 

;
; Bytes to form the characters.
;
DATA_CHARS:
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00      ;[01D4] 
    DB $00,$08,$08,$08,$08,$08,$00,$08,$00,$00      ;[01DE] 
    DB $00,$0A,$0A,$00,$00,$00,$00,$00,$00,$00      ;[01E8] 
    DB $00,$0A,$0A,$1F,$0A,$1F,$0A,$0A,$00,$00      ;[01F2] 
    DB $00,$04,$0E,$14,$0E,$05,$15,$0E,$04,$00      ;[01FC] 
    DB $00,$00,$18,$19,$02,$04,$08,$13,$03,$00      ;[0206] 
    DB $00,$08,$14,$14,$08,$15,$12,$0D,$00,$00      ;[0210] 
    DB $00,$0C,$04,$08,$00,$00,$00,$00,$00,$00      ;[021A] 
    DB $00,$02,$04,$04,$04,$04,$04,$02,$00,$00      ;[0224] 
    DB $00,$10,$08,$08,$08,$08,$08,$10,$00,$00      ;[022E] 
    DB $00,$00,$00,$0A,$04,$1F,$04,$0A,$00,$00      ;[0238] 
    DB $00,$00,$00,$04,$04,$1F,$04,$04,$00,$00      ;[0242] 
    DB $00,$00,$00,$00,$00,$00,$18,$08,$10,$00      ;[024C] 
    DB $00,$00,$00,$00,$00,$1F,$00,$00,$00,$00      ;[0256] 
    DB $00,$00,$00,$00,$00,$00,$0C,$0C,$00,$00      ;[0260] 
    DB $00,$00,$01,$02,$04,$08,$10,$00,$00,$00      ;[026A] 
    DB $00,$0E,$11,$13,$15,$19,$11,$0E,$00,$00      ;[0274] 
    DB $00,$04,$0C,$04,$04,$04,$04,$0E,$00,$00      ;[027E] 
    DB $00,$0E,$11,$01,$0E,$10,$10,$1F,$00,$00      ;[0288] 
    DB $00,$0E,$11,$01,$06,$01,$11,$0E,$00,$00      ;[0292] 
    DB $00,$10,$10,$12,$12,$1F,$02,$02,$00,$00      ;[029C] 
    DB $00,$1F,$10,$1E,$01,$01,$11,$0E,$00,$00      ;[02A6] 
    DB $00,$06,$08,$10,$1E,$11,$11,$0E,$00,$00      ;[02B0] 
    DB $00,$1F,$01,$02,$04,$08,$08,$08,$00,$00      ;[02BA] 
    DB $00,$0E,$11,$11,$0E,$11,$11,$0E,$00,$00      ;[02C4] 
    DB $00,$0E,$11,$11,$0F,$01,$02,$0C,$00,$00      ;[02CE] 
    DB $00,$00,$00,$18,$18,$00,$18,$18,$00,$00      ;[02D8] 
    DB $00,$00,$00,$18,$18,$00,$18,$08,$10,$00      ;[02E2] 
    DB $00,$00,$00,$04,$08,$10,$08,$04,$00,$00      ;[02EC] 
    DB $00,$00,$00,$00,$1E,$00,$1E,$00,$00,$00      ;[02F6] 
    DB $00,$00,$00,$10,$08,$04,$08,$10,$00,$00      ;[0300] 
    DB $00,$0E,$11,$01,$06,$04,$00,$04,$00,$00      ;[030A] 
    DB $00,$0E,$13,$15,$15,$16,$10,$0E,$00,$00      ;[0314] 
    DB $00,$04,$0A,$11,$11,$1F,$11,$11,$00,$00      ;[031E] 
    DB $00,$1E,$11,$1E,$11,$11,$11,$1E,$00,$00      ;[0328] 
    DB $00,$0E,$11,$10,$10,$10,$11,$0E,$00,$00      ;[0332] 
    DB $00,$1C,$12,$11,$11,$11,$11,$1E,$00,$00      ;[033C] 
    DB $00,$1F,$10,$1E,$10,$10,$10,$1F,$00,$00      ;[0346] 
    DB $00,$1F,$10,$1E,$10,$10,$10,$10,$00,$00      ;[0350] 
    DB $00,$0E,$11,$10,$17,$11,$11,$0F,$00,$00      ;[035A] 
    DB $00,$11,$11,$1F,$11,$11,$11,$11,$00,$00      ;[0364] 
    DB $00,$0E,$04,$04,$04,$04,$04,$0E,$00,$00      ;[036E] 
    DB $00,$0F,$02,$02,$02,$02,$12,$0C,$00,$00      ;[0378] 
    DB $00,$11,$12,$14,$18,$14,$12,$11,$00,$00      ;[0382] 
    DB $00,$10,$10,$10,$10,$10,$10,$1F,$00,$00      ;[038C] 
    DB $00,$11,$1B,$15,$11,$11,$11,$11,$00,$00      ;[0396] 
    DB $00,$11,$19,$15,$13,$11,$11,$11,$00,$00      ;[03A0] 
    DB $00,$0E,$11,$11,$11,$11,$11,$0E,$00,$00      ;[03AA] 
    DB $00,$1E,$11,$11,$1E,$10,$10,$10,$00,$00      ;[03B4] 
    DB $00,$0E,$11,$11,$11,$15,$12,$0D,$00,$00      ;[03BE] 
    DB $00,$1E,$11,$11,$1E,$14,$12,$11,$00,$00      ;[03C8] 
    DB $00,$0E,$11,$10,$0E,$01,$11,$0E,$00,$00      ;[03D2] 
    DB $00,$1F,$04,$04,$04,$04,$04,$04,$00,$00      ;[03DC] 
    DB $00,$11,$11,$11,$11,$11,$13,$0D,$00,$00      ;[03E6] 
    DB $00,$11,$11,$11,$11,$11,$0A,$04,$00,$00      ;[03F0] 
    DB $00,$11,$11,$11,$11,$15,$1B,$11,$00,$00      ;[03FA] 
    DB $00,$11,$11,$0A,$04,$0A,$11,$11,$00,$00      ;[0404] 
    DB $00,$11,$11,$0A,$04,$04,$04,$04,$00,$00      ;[040E] 
    DB $00,$1F,$01,$02,$04,$08,$10,$1F,$00,$00      ;[0418] 
    DB $00,$0E,$08,$08,$08,$08,$08,$0E,$00,$00      ;[0422] 
    DB $00,$00,$10,$08,$04,$02,$01,$00,$00,$00      ;[042C] 
    DB $00,$1C,$04,$04,$04,$04,$04,$1C,$00,$00      ;[0436] 
    DB $00,$03,$04,$09,$0A,$0A,$09,$04,$03,$00      ;[0440] 
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$3F      ;[044A] 
    DB $00,$06,$09,$08,$1E,$08,$08,$0F,$00,$00      ;[0454] 
    DB $00,$00,$00,$0D,$13,$11,$11,$0F,$00,$00      ;[045E] 
    DB $00,$10,$10,$16,$19,$11,$11,$1E,$00,$00      ;[0468] 
    DB $00,$00,$00,$0E,$10,$10,$10,$0E,$00,$00      ;[0472] 
    DB $00,$01,$01,$0D,$13,$11,$11,$0F,$00,$00      ;[047C] 
    DB $00,$00,$00,$0E,$11,$1F,$10,$0E,$00,$00      ;[0486] 
    DB $00,$06,$09,$08,$1E,$08,$08,$08,$00,$00      ;[0490] 
    DB $00,$00,$00,$0D,$13,$11,$11,$0F,$01,$0E      ;[049A] 
    DB $00,$10,$10,$16,$19,$11,$11,$11,$00,$00      ;[04A4] 
    DB $00,$00,$04,$00,$04,$04,$04,$04,$00,$00      ;[04AE] 
    DB $00,$00,$02,$00,$02,$02,$02,$02,$12,$0C      ;[04B8] 
    DB $00,$10,$10,$12,$14,$1C,$12,$11,$00,$00      ;[04C2] 
    DB $00,$08,$08,$08,$08,$08,$08,$06,$00,$00      ;[04CC] 
    DB $00,$00,$00,$1A,$15,$15,$15,$15,$00,$00      ;[04D6] 
    DB $00,$00,$00,$16,$19,$11,$11,$11,$00,$00      ;[04E0] 
    DB $00,$00,$00,$0E,$11,$11,$11,$0E,$00,$00      ;[04EA] 
    DB $00,$00,$00,$16,$19,$11,$11,$1E,$10,$10      ;[04F4] 
    DB $00,$00,$00,$0D,$13,$11,$11,$0F,$01,$01      ;[04FE] 
    DB $00,$00,$00,$16,$19,$10,$10,$10,$00,$00      ;[0508] 
    DB $00,$00,$00,$0E,$10,$0E,$01,$0E,$00,$00      ;[0512] 
    DB $00,$00,$08,$1F,$08,$08,$09,$06,$00,$00      ;[051C] 
    DB $00,$00,$00,$11,$11,$11,$13,$0D,$00,$00      ;[0526] 
    DB $00,$00,$00,$11,$11,$11,$0A,$04,$00,$00      ;[0530] 
    DB $00,$00,$00,$11,$11,$15,$1B,$11,$00,$00      ;[053A] 
    DB $00,$00,$00,$11,$0A,$04,$0A,$11,$00,$00      ;[0544] 
    DB $00,$00,$00,$11,$11,$11,$11,$0F,$01,$0E      ;[054E] 
    DB $00,$00,$00,$1F,$02,$04,$08,$1F,$00,$00      ;[0558] 
    DB $00,$00,$00,$04,$02,$1F,$02,$04,$00,$00      ;[0562] 
    DB $00,$00,$00,$04,$08,$1F,$08,$04,$00,$00      ;[056C] 
    DB $00,$00,$00,$04,$0E,$15,$04,$04,$00,$00      ;[0576] 
    DB $00,$00,$00,$04,$04,$15,$0E,$04,$00,$00      ;[0580] 
    DB $00,$30,$08,$24,$04,$04,$24,$08,$30,$00      ;[058A] 
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00      ;[0594] 
    DB $38,$38,$38,$38,$38,$00,$00,$00,$00,$00      ;[059E] 
    DB $07,$07,$07,$07,$07,$00,$00,$00,$00,$00      ;[05A8] 
    DB $3F,$3F,$3F,$3F,$3F,$00,$00,$00,$00,$00      ;[05B2] 
    DB $00,$00,$00,$00,$00,$38,$38,$38,$38,$38      ;[05BC] 
    DB $38,$38,$38,$38,$38,$38,$38,$38,$38,$38      ;[05C6] 
    DB $07,$07,$07,$07,$07,$38,$38,$38,$38,$38      ;[05D0] 
    DB $3F,$3F,$3F,$3F,$3F,$38,$38,$38,$38,$38      ;[05DA] 
    DB $00,$00,$00,$00,$00,$07,$07,$07,$07,$07      ;[05E4] 
    DB $38,$38,$38,$38,$38,$07,$07,$07,$07,$07      ;[05EE] 
    DB $07,$07,$07,$07,$07,$07,$07,$07,$07,$07      ;[05F8] 
    DB $3F,$3F,$3F,$3F,$3F,$07,$07,$07,$07,$07      ;[0602] 
    DB $00,$00,$00,$00,$00,$3F,$3F,$3F,$3F,$3F      ;[060C] 
    DB $38,$38,$38,$38,$38,$3F,$3F,$3F,$3F,$3F      ;[0616] 
    DB $07,$07,$07,$07,$07,$3F,$3F,$3F,$3F,$3F      ;[0620] 
    DB $3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F      ;[062A] 
    DB $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A      ;[0634] 
    DB $3F,$00,$3F,$00,$3F,$00,$3F,$00,$3F,$00      ;[063E] 
    DB $2A,$15,$2A,$15,$2A,$15,$2A,$15,$2A,$15      ;[0648] 
    DB $1E,$08,$08,$08,$08,$08,$08,$1F,$00,$00      ;[0652] 
    DB $3B,$11,$0A,$04,$04,$24,$24,$2E,$00,$00      ;[065C] 
    DB $38,$0C,$0A,$09,$08,$08,$08,$1C,$00,$00      ;[0666] 
    DB $3F,$12,$11,$10,$30,$11,$12,$17,$00,$00      ;[0670] 
    DB $1C,$08,$10,$20,$20,$10,$08,$1C,$00,$00      ;[067A] 
    DB $03,$1B,$18,$00,$37,$37,$07,$07,$00,$00      ;[0684] 
    DB $00,$00,$18,$18,$00,$00,$00,$00,$00,$00      ;[068E] 

;
; Set ink and paper. (VDU 1/2 with argument in A.)
;
SETINK:
    LD    (SYSVAR_INKST),A          ;[0698] 
INKPAPER_EXIT:
    LD    (HL),$00                  ;[069B] 
    JR    SCREEN_END                ;[069D] 

;
; Set paper colour.
;
SETPAPER:
    LD    (SYSVAR_PAPST),A          ;[069F] 
    JR    INKPAPER_EXIT             ;[06A2] 

;
; Display Driver <DISPLAY.MAC:D$SCRN>
;
SCREEN:
    PUSH  AF                        ;[06A4] 
    PUSH  HL                        ;[06A5] 
    PUSH  DE                        ;[06A6] 
    PUSH  BC                        ;[06A7] 
    LD    HL,SYSVAR_LASTDSP         ;[06A8] 
    DEC   (HL)                      ;[06AB] 
    JR    Z,SETINK                  ;[06AC] 
    DEC   (HL)                      ;[06AE] 
    JR    Z,SETPAPER                ;[06AF] 
    LD    (HL),A                    ;[06B1] 
    CP    $20                       ;[06B2] 
    JR    C,OUTB_OR_VDU             ;[06B4] 
    CALL  SYSVAR_VIDEO              ;[06B6] 
    CALL  ADV_CURSOR                ;[06B9] 
    LD    (SYSVAR_CURSORX),DE       ;[06BC] 
SCREEN2:
    LD    A,(SYSVAR_CURSTAT)        ;[06C0] 
    OR    A                         ;[06C3] 
    LD    A,CURCHR                  ;[06C4] 
    CALL  NZ,SYSVAR_VIDEO           ;[06C6] 
SCREEN_END:
    POP   BC                        ;[06C9] 
    POP   DE                        ;[06CA] 
    POP   HL                        ;[06CB] 
    POP   AF                        ;[06CC] 
NULL:
    RET                             ;[06CD] 

;
; Special/normal character routine
;
OUTB_OR_VDU:
    PUSH  AF                        ;[06CE] 
    LD    A,(SYSVAR_CURSTAT)        ;[06CF] 
    OR    A                         ;[06D2] 
    LD    A,' '                     ;[06D3] 
    CALL  NZ,SYSVAR_VIDEO           ;[06D5] Outputs character in A to current cursor position.
    POP   AF                        ;[06D8] 
    LD    HL,SCREEN2                ;[06D9] 
    PUSH  HL                        ;[06DC] Return address.
    LD    HL,SCREEN_TBL             ;[06DD] 
    RLCA                            ;[06E0] 
    LD    E,A                       ;[06E1] 
    LD    D,$00                     ;[06E2] 
    ADD   HL,DE                     ;[06E4] 
    LD    A,(HL)                    ;[06E5] 
    INC   HL                        ;[06E6] 
    LD    H,(HL)                    ;[06E7] 
    LD    L,A                       ;[06E8] 
    JP    (HL)                      ;[06E9] 

;
; List of ROM addresses for the VDU routines. (VDU 0-31)
;
SCREEN_TBL:
    DW    NULL                      ;[06EA] 
    DW    NULL                      ;[06EC] 1
    DW    NULL                      ;[06EE] 2
    DW    NULL                      ;[06F0] 3
    DW    SCREEN_CLEAR              ;[06F2] 4
    DW    SCREEN_UP_ONE             ;[06F4] 5
    DW    SCREEN_DOWN_ONE           ;[06F6] 6
    DW    SCREEN_BELL               ;[06F8] 7
    DW    SCREEN_BACKSPACE          ;[06FA] 8
    DW    SCREEN_TAB                ;[06FC] 9
    DW    SCREEN_LF                 ;[06FE] 10
    DW    NULL                      ;[0700] 11
    DW    PATCH1                    ;[0702] 12
    DW    SCREEN_CRLF               ;[0704] 13
    DW    SCREEN_CURS_ON            ;[0706] 14
    DW    SCREEN_CURS_OFF           ;[0708] 15
    DW    SCREEN_TOP                ;[070A] 16
    DW    NULL                      ;[070C] 17
    DW    SCREEN_INVERT             ;[070E] 18
    DW    SCREEN_BEGIN              ;[0710] 19
    DW    SCREEN_MASK               ;[0712] 20
    DW    SCREEN_MASK+$02           ;[0714] 21
    DW    SCREEN_BACK_CURS          ;[0716] 22
    DW    SCREEN_HOME               ;[0718] 23
    DW    SCREEN_DOUBLE_ON          ;[071A] 24
    DW    SCREEN_DOUBLE_OFF         ;[071C] 25
    DW    NULL                      ;[071E] 26
    DW    NULL                      ;[0720] 27
    DW    SCREEN_HA_LF_UP           ;[0722] 28
    DW    SCREEN_HA_LF              ;[0724] 29
    DW    SCREEN_CLEAR_EOL          ;[0726] 30
    DW    SCREEN_CRLF               ;[0728] 31

;
; Turns double height characters on (VDU 24)
;
SCREEN_DOUBLE_ON:
    LD    A,$40                     ;[072A] 
SCREEN_SET_BPERL:
    LD    (SYSVAR_BPERL),A          ;[072C] I guess it's 64 because 32 cols but printed twice when double height?
    RET                             ;[072F] 

;
; Turns double height characters off (VDU 25)
;
SCREEN_DOUBLE_OFF:
    LD    A,$20                     ;[0730] 
    JR    SCREEN_SET_BPERL          ;[0732] 

;
; Overwrite on (VDU 21)
;
SCREEN_MASK:
    XOR   A                         ;[0734] 
    LD    BC,$FF3E                  ;[0735] (nb. SCREEN_MASK+$02:  LD  A,$FF)
    LD    (SYSVAR_MASK),A           ;[0738] 
    RET                             ;[073B] 

;
; Swaps ink and paper (VDU 18)
;
SCREEN_INVERT:
    LD    HL,(SYSVAR_INKST)         ;[073C] 
    LD    A,L                       ;[073F] 
    LD    L,H                       ;[0740] 
    LD    H,A                       ;[0741] 
    LD    (SYSVAR_INKST),HL         ;[0742] 
    RET                             ;[0745] 

;
; Move cursor over 1 character (to the right)
;
ADV_CURSOR:
    LD    HL,(SYSVAR_WINDST)        ;[0746] 
    LD    DE,(SYSVAR_CURSORX)       ;[0749] 
    LD    A,E                       ;[074D] 
    ADD   A,$03                     ;[074E] 
    LD    E,A                       ;[0750] 
    CP    H                         ;[0751] 
    RET   C                         ;[0752] 
    LD    E,L                       ;[0753] 
ADV_CURSOR1:
    LD    HL,(SYSVAR_WINDST+$02)    ;[0754] Window height.
    LD    A,D                       ;[0757] 
    CALL  SYSVAR_SLFRAM             ;[0758] Unused.
    ADD   A,$0A                     ;[075B] Add 10 pixels
ADV_CURSOR2:
    LD    D,A                       ;[075D] 
    CP    H                         ;[075E] 
    RET   C                         ;[075F] 
    LD    D,L                       ;[0760] 
    RET                             ;[0761] 

;
; Clears screen and homes cursor (VDU 4)
;
SCREEN_CLEAR:
    CALL  _CLS                      ;[0762] 

;
; Homes cursor (takes cursor inside of window) (VDU 23)
;
SCREEN_HOME:
    CALL  SCREEN_CR                 ;[0765] 

;
; Moves cursor to top of screen (VDU 16)
;
SCREEN_TOP:
    LD    A,(SYSVAR_WINDST+$02)     ;[0768] 
    LD    (SYSVAR_CURSORY),A        ;[076B] 
    RET                             ;[076E] 

;
; Carriage return, linefeed, if cursor is not at beginning of line (VDU 19)
;
SCREEN_BEGIN:
    LD    HL,(SYSVAR_WINDST)        ;[076F] 
    LD    A,(SYSVAR_CURSORX)        ;[0772] 
    CP    L                         ;[0775] 
    RET   Z                         ;[0776] 
    LD    A,$0D                     ;[0777] 
    RST   $08                       ;[0779] 
    RET                             ;[077A] 

;
; Carriage return, linefeed, clears to end of line (VDU 13/31)
;
SCREEN_CRLF:
    CALL  SCREEN_CR                 ;[077B] 

;
; Line feed (moves cursor down 10 pixel lines) (VDU 10)
;
SCREEN_LF:
    LD    DE,(SYSVAR_CURSORX)       ;[077E] 
    CALL  ADV_CURSOR1               ;[0782] 
    JR    SAVE_CURSORX              ;[0785] 

;
; Moves cursor down one pixel (VDU 6)
;
SCREEN_DOWN_ONE:
    LD    C,$01                     ;[0787] 
    JR    SCREEN_HA_LF1             ;[0789] 

;
; Moves cursor down 3 pixels (VDU 29) (Half linefeed)
;
SCREEN_HA_LF:
    LD    C,$03                     ;[078B] 
SCREEN_HA_LF1:
    LD    DE,(SYSVAR_CURSORX)       ;[078D] 
    LD    HL,(SYSVAR_WINDST+$02)    ;[0791] 
    LD    A,D                       ;[0794] 
    ADD   A,C                       ;[0795] 
    CALL  ADV_CURSOR2               ;[0796] 
    JR    SAVE_CURSORX              ;[0799] 

;
; Move cursor to the leftmost column of the WINDOW.
;
SCREEN_CR:
    LD    A,(SYSVAR_WINDST)         ;[079B] 
    LD    (SYSVAR_CURSORX),A        ;[079E] 
    RET                             ;[07A1] 

;
; Tabs cursor to next field (VDU 9)
;
SCREEN_TAB:
    LD    A,(SYSVAR_CURSORX)        ;[07A2] 
    INC   A                         ;[07A5] 
    LD    HL,$07BB                  ;[07A6] 
SCREEN_TAB1:
    INC   HL                        ;[07A9] 
    CP    (HL)                      ;[07AA] 
    JR    NC,SCREEN_TAB1            ;[07AB] 
    LD    H,(HL)                    ;[07AD] 
    INC   H                         ;[07AE] 
    JR    Z,SCREEN_CRLF             ;[07AF] 
    DEC   H                         ;[07B1] 
SCREEN_TAB12:
    LD    A,' '                     ;[07B2] Print spaces
    RST   $08                       ;[07B4] 
    LD    A,(SYSVAR_CURSORX)        ;[07B5] 
    CP    H                         ;[07B8] 
    RET   NC                        ;[07B9] 
    JR    SCREEN_TAB12              ;[07BA] 
    DEC   DE                        ;[07BC] 
    INC   SP                        ;[07BD] 
    LD    C,E                       ;[07BE] 
    LD    H,E                       ;[07BF] 
    RST   $38                       ;[07C0] 

;
; Clears to end of line (VDU 30)
;
SCREEN_CLEAR_EOL:
    LD    A,(SYSVAR_WINDST+$01)     ;[07C1] 
    DEC   A                         ;[07C4] 
    LD    HL,(SYSVAR_CURSORX)       ;[07C5] 
    PUSH  HL                        ;[07C8] 
SCREEN_CLEAR_EOL_LOOP:
    LD    (SYSVAR_CURSORX),HL       ;[07C9] 
    PUSH  HL                        ;[07CC] 
    PUSH  AF                        ;[07CD] 
    LD    A,$20                     ;[07CE] 
    CALL  SYSVAR_VIDEO              ;[07D0] 
    POP   AF                        ;[07D3] 
    POP   HL                        ;[07D4] 
    INC   L                         ;[07D5] 
    INC   L                         ;[07D6] 
    INC   L                         ;[07D7] 
    CP    L                         ;[07D8] 
    JR    NC,SCREEN_CLEAR_EOL_LOOP  ;[07D9] 
    POP   DE                        ;[07DB] 
    JR    SAVE_CURSORX              ;[07DC] 

;
; Backspace cursor (VDU 22)
;
SCREEN_BACK_CURS:
    CALL  SUB_BACKSPACE             ;[07DE] 
SAVE_CURSORX:
    LD    (SYSVAR_CURSORX),DE       ;[07E1] 
    RET                             ;[07E5] 

;
; Called by backspace routine.
;
SUB_BACKSPACE:
    LD    HL,(SYSVAR_WINDST)        ;[07E6] 
    LD    DE,(SYSVAR_CURSORX)       ;[07E9] 
    DEC   L                         ;[07ED] 
    LD    B,$03                     ;[07EE] 
SUB_BACKSPACE1:
    DEC   E                         ;[07F0] 
    LD    A,E                       ;[07F1] 
    CP    L                         ;[07F2] 
    JR    Z,SUB_BACKSPACE2          ;[07F3] 
    DJNZ  SUB_BACKSPACE1            ;[07F5] 
    RET                             ;[07F7] 

SUB_BACKSPACE2:
    LD    E,H                       ;[07F8] 
    DEC   E                         ;[07F9] 
    DEC   E                         ;[07FA] 
    DEC   E                         ;[07FB] 
    LD    HL,(SYSVAR_WINDST+$02)    ;[07FC] 
    LD    A,D                       ;[07FF] 
    SUB   $0A                       ;[0800] 
SUB_BACKSPACE3:
    LD    D,A                       ;[0802] 
    SUB   L                         ;[0803] 
    CP    $F6                       ;[0804] 
    RET   C                         ;[0806] 
    LD    A,H                       ;[0807] 
    SUB   $0A                       ;[0808] 
    LD    D,A                       ;[080A] 
    RET                             ;[080B] 

;
; Moves cursor up one pixel (VDU 5)
;
SCREEN_UP_ONE:
    LD    C,$01                     ;[080C] 
    JR    SCREEN_HA_LF_UP1          ;[080E] 

;
; Moves cursor up 3 pixels (VDU 28)
;
SCREEN_HA_LF_UP:
    LD    C,$03                     ;[0810] 
SCREEN_HA_LF_UP1:
    LD    DE,(SYSVAR_CURSORX)       ;[0812] 
    LD    HL,(SYSVAR_WINDST+$02)    ;[0816] 
    LD    A,D                       ;[0819] 
    SUB   C                         ;[081A] 
    CALL  SUB_BACKSPACE3            ;[081B] 
    JR    SAVE_CURSORX              ;[081E] 

;
; Backspace and erase character (VDU 8)
;
SCREEN_BACKSPACE:
    CALL  SCREEN_BACK_CURS          ;[0820] 
    LD    A,$20                     ;[0823] 
    JP    SYSVAR_VIDEO              ;[0825] 

;
; Turns cursor on (VDU 14)
;
SCREEN_CURS_ON:
    LD    A,$01                     ;[0828] 
GET_CURSTAT:
    LD    (SYSVAR_CURSTAT),A        ;[082A] 
    RET                             ;[082D] 

;
; Turns cursor off (VDU 15)
;
SCREEN_CURS_OFF:
    XOR   A                         ;[082E] 
    JR    GET_CURSTAT               ;[082F] 

;
; WINDOW routine.
;
BASIC_COM_WINDOW:
    LD    B,$04                     ;[0831] 
    LD    HL,SYSVAR_WINDST          ;[0833] 
BASIC_COM_WINDOW1:
    PUSH  HL                        ;[0836] 
    PUSH  BC                        ;[0837] 
    CALL  SUB_ARGUMENT              ;[0838] 
    INC   DE                        ;[083B] 
    LD    A,L                       ;[083C] 
    POP   BC                        ;[083D] 
    POP   HL                        ;[083E] 
    LD    (HL),A                    ;[083F] 
    INC   HL                        ;[0840] 
    DJNZ  BASIC_COM_WINDOW1         ;[0841] 
    RET                             ;[0843] 

;
; A routine to decide which bits need to be set. Used in the output of chars.
; (called from OUTB)
;
OUTB_BIT_SET:
    EXX                             ;[0844] 
    XOR   A                         ;[0845] 
    SRL   H                         ;[0846] 
    ADC   A,A                       ;[0848] 
    SRL   L                         ;[0849] 
    ADC   A,A                       ;[084B] 
    EXX                             ;[084C] 
    JR    Z,OUTB_BIT_SET2           ;[084D] 
    DEC   A                         ;[084F] 
    RET   Z                         ;[0850] 
    DEC   A                         ;[0851] 
    JR    Z,OUTB_BIT_SET1           ;[0852] 
    LD    A,$FF                     ;[0854] 
    XOR   E                         ;[0856] 
    LD    D,A                       ;[0857] 
    RET                             ;[0858] 

OUTB_BIT_SET1:
    LD    A,D                       ;[0859] 
    OR    E                         ;[085A] 
    CPL                             ;[085B] 
OUTB_BIT_SET2:
    LD    D,A                       ;[085C] 
    RET                             ;[085D] 

;
; Outputs byte with data in A, mask in C and relative displacement from top left 
; in HL. Uses colour selected by INK and PAPER. (via SYSVAR_OUTB)
;
OUTB:
    EXX                             ;[085E] 
    EX    AF,AF'                    ;[085F] 
    PUSH  AF                        ;[0860] 
    EX    AF,AF'                    ;[0861] 
    PUSH  HL                        ;[0862] 
    LD    HL,(SYSVAR_INKST)         ;[0863] 
    EXX                             ;[0866] 
    PUSH  DE                        ;[0867] 
    LD    E,C                       ;[0868] 
    LD    D,A                       ;[0869] 
OUTB_BLUE:
    PUSH  DE                        ;[086A] 
    CALL  OUTB_BIT_SET              ;[086B] Output a byte to vdu ram.
    LD    A,(SYSVAR_PROTST)         ;[086E] 
    RRCA                            ;[0871] 
    JR    C,OUTB_RED                ;[0872] 
    LD    A,$E8                     ;[0874] BLUE Bank: A=E8 A'=63 BC=8000
    EX    AF,AF'                    ;[0876] 
    LD    A,$63                     ;[0877] 
    LD    BC,(SYSVAR_BLUBNK)        ;[0879] 
    CALL  OUT_TO_BANK               ;[087D] 
OUTB_RED:
    POP   DE                        ;[0880] 
    PUSH  DE                        ;[0881] 
    CALL  OUTB_BIT_SET              ;[0882] 
    LD    A,(SYSVAR_PROTST)         ;[0885] 
    BIT   1,A                       ;[0888] 
    JR    NZ,OUTB_GREEN             ;[088A] 
    LD    A,$E8                     ;[088C] RED Bank: A=E8 A'=63 BC=C000
    EX    AF,AF'                    ;[088E] 
    LD    A,$63                     ;[088F] 
    LD    BC,(SYSVAR_REDBNK)        ;[0891] 
    CALL  OUT_TO_BANK               ;[0895] 
OUTB_GREEN:
    POP   DE                        ;[0898] 
    CALL  OUTB_BIT_SET              ;[0899] 
    LD    A,(SYSVAR_PROTST)         ;[089C] 
    BIT   2,A                       ;[089F] 
    JR    NZ,OUTB_END               ;[08A1] 
    LD    A,$E4                     ;[08A3] GREEN Bank: A=E4 A'=65 BC=C000
    EX    AF,AF'                    ;[08A5] 
    LD    A,$65                     ;[08A6] 
    LD    BC,(SYSVAR_GRNBNK)        ;[08A8] 
    CALL  OUT_TO_BANK               ;[08AC] 
OUTB_END:
    POP   DE                        ;[08AF] 
    EXX                             ;[08B0] 
    POP   HL                        ;[08B1] 
    EXX                             ;[08B2] 
    POP   AF                        ;[08B3] 
    EX    AF,AF'                    ;[08B4] 
    RET                             ;[08B5] 

OUT_TO_BANK:
    PUSH  HL                        ;[08B6] 
    ADD   HL,BC                     ;[08B7] 
    LD    BC,$FF7F                  ;[08B8] 
    OUT   (C),A                     ;[08BB] 
    LD    A,$40                     ;[08BD] 
    OUT   ($80),A                   ;[08BF] 
    EX    AF,AF'                    ;[08C1] 
    OUT   ($80),A                   ;[08C2] 
    LD    A,(HL)                    ;[08C4] 
    AND   E                         ;[08C5] 
    OR    D                         ;[08C6] 
    LD    (HL),A                    ;[08C7] 
    XOR   A                         ;[08C8] 
    OUT   ($80),A                   ;[08C9] 
    OUT   (C),A                     ;[08CB] 
    POP   HL                        ;[08CD] 
    RET                             ;[08CE] 

;
; Called by clear screen routine.
;
CLS_BANK:
    LD    BC,$FF7F                  ;[08CF] 
    OUT   (C),A                     ;[08D2] 
    LD    BC,EXT_ROM                ;[08D4] 
CLS_BANK1:
    LD    (HL),D                    ;[08D7] 
    DEC   BC                        ;[08D8] 
    INC   HL                        ;[08D9] 
    LD    A,B                       ;[08DA] 
    OR    C                         ;[08DB] 
    JR    NZ,CLS_BANK1              ;[08DC] 
    XOR   A                         ;[08DE] 
    LD    BC,$FF7F                  ;[08DF] 
    OUT   (C),A                     ;[08E2] 
    RET                             ;[08E4] 

;
; Called by BASIC clear screen routine.
;
_CLS:
    LD    A,$20                     ;[08E5] 
    OUT   ($80),A                   ;[08E7] 
    LD    DE,(SYSVAR_PAPST)         ;[08E9] 
CLS_BLUE:
    CALL  SUB_CLS_COLOUR            ;[08ED] 
    LD    A,(SYSVAR_PROTST)         ;[08F0] 
    RRCA                            ;[08F3] 
    JR    C,CLS_RED                 ;[08F4] 
    LD    HL,(SYSVAR_BLUBNK)        ;[08F6] 
    LD    A,$23                     ;[08F9] 
    CALL  CLS_BANK                  ;[08FB] 
CLS_RED:
    CALL  SUB_CLS_COLOUR            ;[08FE] 
    LD    A,(SYSVAR_PROTST)         ;[0901] 
    BIT   1,A                       ;[0904] 
    JR    NZ,CLS_GREEN              ;[0906] 
    LD    HL,(SYSVAR_REDBNK)        ;[0908] 
    LD    A,$23                     ;[090B] 
    CALL  CLS_BANK                  ;[090D] 
CLS_GREEN:
    CALL  SUB_CLS_COLOUR            ;[0910] 
    LD    A,(SYSVAR_PROTST)         ;[0913] 
    BIT   2,A                       ;[0916] 
    JR    NZ,CLS_END                ;[0918] 
    LD    HL,(SYSVAR_GRNBNK)        ;[091A] 
    LD    A,$25                     ;[091D] 
    CALL  CLS_BANK                  ;[091F] 
CLS_END:
    XOR   A                         ;[0922] 
    OUT   ($80),A                   ;[0923] 
    RET                             ;[0925] 

;
; Returns D set to FF or 00. Used by CLS.
;
SUB_CLS_COLOUR:
    LD    D,$00                     ;[0926] 
    SRL   E                         ;[0928] 
    RET   NC                        ;[092A] 
    DEC   D                         ;[092B] 
    RET                             ;[092C] 

;
; beeps (VDU 7)
;
SCREEN_BELL:
    LD    HL,KBPLEN                 ;[092D] 
    LD    DE,KBPWAV                 ;[0930] 
    LD    BC,$3F84                  ;[0933] 
    LD    A,$01                     ;[0936] 
    OUT   ($80),A                   ;[0938] 
    JP    BEEP_LOOP                 ;[093A] 

;
; Basic BEEP routine.
;
BASIC_COM_BEEP:
    LD    A,$01                     ;[093D] 
    OUT   ($80),A                   ;[093F] 
    CALL  SUB_ARGUMENT              ;[0941] 
    INC   DE                        ;[0944] 
    PUSH  HL                        ;[0945] 
    CALL  SUB_ARGUMENT              ;[0946] 
    INC   DE                        ;[0949] 
    PUSH  HL                        ;[094A] 
    CALL  SUB_ARGUMENT              ;[094B] 

;
; Beep routine (see Lynx User 2)
;
_BEEP:
    AND   $3F                       ;[094E] 
    LD    B,A                       ;[0950] 
    LD    C,$84                     ;[0951] 
    POP   HL                        ;[0953] 
    INC   HL                        ;[0954] 
    POP   DE                        ;[0955] 
    INC   DE                        ;[0956] 
    INC   D                         ;[0957] 
    INC   E                         ;[0958] 
    DEC   E                         ;[0959] 
    JR    NZ,BEEP_LOOP              ;[095A] 
    INC   E                         ;[095C] 
BEEP_LOOP:
    XOR   A                         ;[095D] 
    OUT   (C),B                     ;[095E] 
    CALL  DELAY                     ;[0960] 
    OUT   (C),A                     ;[0963] 
    CALL  DELAY                     ;[0965] 
    PUSH  BC                        ;[0968] 
    LD    BC,$0080                  ;[0969] 
    IN    B,(C)                     ;[096C] 
    BIT   6,B                       ;[096E] 
    POP   BC                        ;[0970] 
    RET   Z                         ;[0971] 
    DEC   HL                        ;[0972] 
    LD    A,H                       ;[0973] 
    OR    L                         ;[0974] 
    JR    NZ,BEEP_LOOP              ;[0975] 
    RET                             ;[0977] 

;
; Delay routine (used by Beep)
;
DELAY:
    PUSH  DE                        ;[0978] 
DELAY_LOOP:
    DEC   E                         ;[0979] 
    JR    NZ,DELAY_LOOP             ;[097A] 
    DEC   D                         ;[097C] 
    JR    NZ,DELAY_LOOP             ;[097D] 
    POP   DE                        ;[097F] 
    RET                             ;[0980] 

;
; SOUND routine.
;
BASIC_COM_SOUND:
    LD    A,$01                     ;[0981] 
    OUT   ($80),A                   ;[0983] 
    CALL  SUB_ARGUMENT              ;[0985] 
    INC   DE                        ;[0988] 
    PUSH  HL                        ;[0989] 
    CALL  SUB_ARGUMENT              ;[098A] 
    EX    DE,HL                     ;[098D] 
    INC   D                         ;[098E] 
    POP   HL                        ;[098F] 

;
; Sound routine  (see Lynx User 2)
;
_SOUND:
    LD    A,(HL)                    ;[0990] 
    INC   HL                        ;[0991] 
    AND   $3F                       ;[0992] 
    RET   Z                         ;[0994] 
    OUT   ($84),A                   ;[0995] 
    CALL  DELAY                     ;[0997] 
    LD    BC,$0080                  ;[099A] 
    IN    B,(C)                     ;[099D] 
    BIT   6,B                       ;[099F] 
    JR    NZ,_SOUND                 ;[09A1] 
    RET                             ;[09A3] 

;
; Test for escape.
;
TEST_ESCAPE:
    LD    HL,SYSVAR_OLDESC          ;[09A4] 
    LD    BC,$0080                  ;[09A7] 
    IN    A,(C)                     ;[09AA] 
    CPL                             ;[09AC] 
    AND   $40                       ;[09AD] 
    LD    E,A                       ;[09AF] 
    XOR   (HL)                      ;[09B0] 
    LD    (HL),E                    ;[09B1] 
    AND   E                         ;[09B2] 
    RET   Z                         ;[09B3] 
    CALL  KBD_TEST                  ;[09B4] 
    AND   $40                       ;[09B7] 
    RET   Z                         ;[09B9] 
    LD    A,$1B                     ;[09BA] 
    RET                             ;[09BC] 

;
; Keyboard driver. Returns code of key pressed in A. Without single key entries. 
;
KEYDVR:
    PUSH  HL                        ;[09BD] 
    PUSH  BC                        ;[09BE] 
    PUSH  DE                        ;[09BF] 
    XOR   A                         ;[09C0] 
    LD    (SYSVAR_STATUS),A         ;[09C1] 
    CALL  TEST_ESCAPE               ;[09C4] 
    JR    NZ,KEYDVR_END             ;[09C7] 
    LD    C,$80                     ;[09C9] 
    LD    B,$0A                     ;[09CB] 
    LD    HL,SYSVAR_OLDKEY          ;[09CD] 
KEYDVR1:
    DEC   B                         ;[09D0] 
    JP    M,KEYRPT                  ;[09D1] 
    IN    A,(C)                     ;[09D4] 
    CPL                             ;[09D6] 
    AND   $3F                       ;[09D7] 
    OR    A                         ;[09D9] 
    JR    Z,KEYDVR2                 ;[09DA] 
    LD    (SYSVAR_STATUS),A         ;[09DC] 
KEYDVR2:
    LD    E,A                       ;[09DF] 
    XOR   (HL)                      ;[09E0] 
    LD    (HL),E                    ;[09E1] 
    AND   E                         ;[09E2] 
    INC   HL                        ;[09E3] 
    JR    Z,KEYDVR1                 ;[09E4] 
    LD    C,E                       ;[09E6] 
    PUSH  BC                        ;[09E7] 
    LD    C,$FF                     ;[09E8] 
KEYDVR3:
    INC   C                         ;[09EA] 
    RRCA                            ;[09EB] 
    JR    NC,KEYDVR3                ;[09EC] 
    LD    A,B                       ;[09EE] 
    RLCA                            ;[09EF] 
    ADD   A,B                       ;[09F0] 
    RLCA                            ;[09F1] 
    ADD   A,C                       ;[09F2] 
    LD    E,A                       ;[09F3] 
    LD    HL,DATA_KEYBOARD          ;[09F4] Choose upper case (default)
    LD    BC,$0080                  ;[09F7] 
    IN    A,(C)                     ;[09FA] 
    RLCA                            ;[09FC] 
    JR    C,KEYDVR4                 ;[09FD] 
    LD    HL,$0ADF                  ;[09FF] Choose lower case
KEYDVR4:
    LD    B,$02                     ;[0A02] 
    IN    A,(C)                     ;[0A04] 
    BIT   6,A                       ;[0A06] 
    JR    NZ,KEYDVR5                ;[0A08] 
    LD    HL,$0AB2                  ;[0A0A] Choose special?
KEYDVR5:
    LD    D,$00                     ;[0A0D] 
    ADD   HL,DE                     ;[0A0F] 
    POP   DE                        ;[0A10] 
    LD    B,D                       ;[0A11] 
    CALL  KBD_TEST                  ;[0A12] 
    AND   $3F                       ;[0A15] 
    XOR   E                         ;[0A17] 
    JR    NZ,KEYDVR_END0            ;[0A18] 
    LD    A,(HL)                    ;[0A1A] 
    LD    HL,SYSVAR_SHLKT           ;[0A1B] 
    BIT   0,(HL)                    ;[0A1E] 
    CALL  NZ,SHLKT0                 ;[0A20] 
    BIT   1,(HL)                    ;[0A23] 
    CALL  NZ,SHLKT1                 ;[0A25] 
    LD    (SYSVAR_LASTK),A          ;[0A28] 
    LD    C,$02                     ;[0A2B] 
    CP    $03                       ;[0A2D] 
    JR    Z,KEYDVR6                 ;[0A2F] 
    CP    $83                       ;[0A31] 
    JR    Z,KEYDVR6                 ;[0A33] 
    LD    C,$01                     ;[0A35] 
    CP    $00                       ;[0A37] 
    JR    NZ,KEYDVR_END             ;[0A39] 
KEYDVR6:
    LD    A,(SYSVAR_SHLKT)          ;[0A3B] 
    XOR   C                         ;[0A3E] 
    LD    (HL),A                    ;[0A3F] 
KEYDVR_END0:
    XOR   A                         ;[0A40] 
KEYDVR_END:
    POP   DE                        ;[0A41] 
    POP   BC                        ;[0A42] 
    POP   HL                        ;[0A43] 
    RET                             ;[0A44] 

;
; If SHLKT bit zero is set
;
SHLKT0:
    CP    $40                       ;[0A45] 
    RET   C                         ;[0A47] 
    XOR   $20                       ;[0A48] 
    RET                             ;[0A4A] 

;
; If SHLKT bit one is set
;
SHLKT1:
    XOR   $80                       ;[0A4B] 
    RET                             ;[0A4D] 

;
; Handle repeat keys (probably)
;
KEYRPT:
    LD    A,(SYSVAR_STATUS)         ;[0A4E] 
    OR    A                         ;[0A51] 
    LD    HL,(SYSVAR_RPTDLY)        ;[0A52] 
    JR    Z,KEYRPT1                 ;[0A55] 
    LD    HL,(SYSVAR_RPT)           ;[0A57] 
    DEC   HL                        ;[0A5A] 
    LD    A,H                       ;[0A5B] 
    OR    L                         ;[0A5C] 
    JR    Z,KEYRPT2                 ;[0A5D] 
KEYRPT1:
    LD    (SYSVAR_RPT),HL           ;[0A5F] 
    XOR   A                         ;[0A62] 
    JR    KEYDVR_END                ;[0A63] 
KEYRPT2:
    LD    BC,$1000                  ;[0A65] 
    CALL  KEYRPT_WAIT               ;[0A68] 
    LD    A,(SYSVAR_LASTK)          ;[0A6B] 
    JR    KEYDVR_END                ;[0A6E] 
KEYRPT_WAIT:
    DEC   BC                        ;[0A70] 
    LD    A,B                       ;[0A71] 
    OR    C                         ;[0A72] 
    JR    NZ,KEYRPT_WAIT            ;[0A73] 
    RET                             ;[0A75] 

;
; Keyboard data table.
;
DATA_KEYBOARD:
    DB $31,$2A,$2A,$00,$0B,$0A,$33,$34      ;[0A76]  1**...34
    DB $45,$58,$44,$43,$32,$51,$57,$5A      ;[0A7E]  EXDC2QWZ
    DB $53,$41,$35,$52,$54,$56,$47,$46      ;[0A86]  SA5RTVGF
    DB $36,$59,$48,$20,$4E,$42,$37,$38      ;[0A8E]  6YH.NB78
    DB $55,$4D,$2A,$4A,$39,$49,$4F,$2C      ;[0A96]  UM*J9IO,
    DB $2A,$4B,$30,$50,$4C,$2E,$2A,$3B      ;[0A9E]  *K0PL.*;
    DB $2D,$40,$5B,$2F,$2A,$3A,$08,$5D      ;[0AA6]  -@[/*:.]
    DB $16,$0D,$2A,$0C,$03,$00,$00,$00      ;[0AAE]  ..*.....
    DB $00,$00,$1C,$1D,$05,$18,$04,$03      ;[0AB6]  ........
    DB $1B,$11,$17,$1A,$13,$01,$1E,$12      ;[0ABE]  ........
    DB $14,$16,$07,$06,$1F,$19,$08,$00      ;[0AC6]  ........
    DB $0E,$02,$00,$00,$15,$0D,$00,$0A      ;[0ACE]  ........
    DB $00,$09,$0F,$00,$00,$0B,$00,$10      ;[0AD6]  ........
    DB $0C,$21,$2A,$2A,$00,$0B,$0A,$23      ;[0ADE]  .!**...#
    DB $24,$65,$78,$64,$63,$22,$71,$77      ;[0AE6]  $exdc"qw
    DB $7A,$73,$61,$25,$72,$74,$76,$67      ;[0AEE]  zsa%rtvg
    DB $66,$26,$79,$68,$20,$6E,$62,$27      ;[0AF6]  f&yh.nb'
    DB $28,$75,$6D,$3F,$6A,$29,$69,$6F      ;[0AFE]  (um?j)io
    DB $3C,$3F,$6B,$5F,$70,$6C,$3E,$3F      ;[0B06]  <?k_pl>?
    DB $2B,$3D,$60,$5E,$3F,$2A,$2A,$08      ;[0B0E]  +=`^?**.
    DB $7F,$16,$0D,$2A,$0C                  ;[0B16]  ...*.

;
; Find [ESC] shorthand in a list. (Called from SYSVAR_/KEYB)
;
KEYB_ESCKEY:
    LD    A,(SYSVAR_KSMS+$01)       ;[0B1B] 
    OR    A,A                       ;[0B1E] 
    JR    NZ,$0b49                  ;[0B1F] Keyboard modifiers? Like [CTRL] [SHIFT]?
    CALL  KEYDVR                    ;[0B21] Get key in A
    CALL  ESC                       ;[0B24] 
    RET   NZ                        ;[0B27] Return if NOT escape
    RES   5,A                       ;[0B28] 
    CP    $41                       ;[0B2A] 
    RET   C                         ;[0B2C] 
    CP    $5B                       ;[0B2D] 
    RET   NC                        ;[0B2F] 
    SUB   $41                       ;[0B30] Letter found [A-Z]
    LD    HL,SYSVAR_KTBL            ;[0B32] Shorthand char table
    LD    C,A                       ;[0B35] 
    LD    B,$00                     ;[0B36] 
    ADD   HL,BC                     ;[0B38] 
    LD    A,(HL)                    ;[0B39] 
    LD    HL,(SYSVAR_XTTBL)         ;[0B3A] Shorthand token table (Auto, Beep, etc)
    INC   A                         ;[0B3D] 
    LD    B,A                       ;[0B3E] 
    CALL  TOKEN_TO_WORD_FIND        ;[0B3F] 
    LD    (SYSVAR_KSMS),HL          ;[0B42] 
    LD    A,(HL)                    ;[0B45] 
    RES   7,A                       ;[0B46] Reset Bit 7 (word marker)
    RET                             ;[0B48] 

KEYB2:
    LD    HL,(SYSVAR_KSMS)          ;[0B49] 
    INC   HL                        ;[0B4C] 
    LD    (SYSVAR_KSMS),HL          ;[0B4D] 
    LD    A,(HL)                    ;[0B50] 
    BIT   7,A                       ;[0B51] 
    RET   Z                         ;[0B53] 
    XOR   A                         ;[0B54] 
    LD    (SYSVAR_KSMS+$01),A       ;[0B55] 
    LD    A,$20                     ;[0B58] 
    RET                             ;[0B5A] 

;
; Scan for a key. Called from "KEY:"  (via SYSVAR_KEYB)
;
KEYB:
    PUSH  HL                        ;[0B5B] 
    PUSH  BC                        ;[0B5C] 
    PUSH  DE                        ;[0B5D] 
    CALL  KEYB_ESCKEY               ;[0B5E] 
    POP   DE                        ;[0B61] 
    POP   BC                        ;[0B62] 
    POP   HL                        ;[0B63] 
    RET                             ;[0B64] 

;
; Reads sync signal from cassette.
;
RSYNC:
    PUSH  BC                        ;[0B65] 
    LD    A,(SYSVAR_PLYLEV)         ;[0B66] 
    OUT   ($84),A                   ;[0B69] 
    CALL  MOTON                     ;[0B6B] 
    LD    A,$20                     ;[0B6E] 
    OUT   ($87),A                   ;[0B70] 
RSYNC_LOOP40:
    LD    B,$28                     ;[0B72] 
RSYNC_RBYTE:
    CALL  RBYTE                     ;[0B74] 
    OR    A                         ;[0B77] 
    JR    NZ,RSYNC_LOOP40           ;[0B78] Repeat until A is zero.
    DJNZ  RSYNC_RBYTE               ;[0B7A] 
RSYNC_FIND_A5:
    CALL  SYSVAR_RBIT               ;[0B7C] 
    CP    $A5                       ;[0B7F] 
    JR    NZ,RSYNC_FIND_A5          ;[0B81] 
    POP   BC                        ;[0B83] 
    RET                             ;[0B84] 

;
; Reads byte from cassette into A. 
;
RBYTE:
    PUSH  BC                        ;[0B85] 
    PUSH  DE                        ;[0B86] 
    LD    B,$08                     ;[0B87] 
RBYTE_BIT:
    PUSH  BC                        ;[0B89] 
    CALL  SYSVAR_RBIT               ;[0B8A] 
    POP   BC                        ;[0B8D] 
    DJNZ  RBYTE_BIT                 ;[0B8E] 
    POP   DE                        ;[0B90] 
    POP   BC                        ;[0B91] 
    RET                             ;[0B92] 

;
; Writes sync signal to cassette.
;
WSYNC:
    PUSH  BC                        ;[0B93] 
    PUSH  AF                        ;[0B94] 
    CALL  MOTON                     ;[0B95] 
    LD    A,$10                     ;[0B98] 
    OUT   ($87),A                   ;[0B9A] 
    LD    A,(SYSVAR_SYNCLEN)        ;[0B9C] Sync length is 10,243 (&2803).
    LD    B,A                       ;[0B9F] 
WSYNC1:
    PUSH  BC                        ;[0BA0] 
    LD    B,$00                     ;[0BA1] 
    XOR   A                         ;[0BA3] 
WSYNC2:
    CALL  SYSVAR_WBYTE              ;[0BA4] 
    DJNZ  WSYNC2                    ;[0BA7] 
    POP   BC                        ;[0BA9] 
    DJNZ  WSYNC1                    ;[0BAA] 
    LD    A,$A5                     ;[0BAC] Write "A5" byte (marker).
    CALL  SYSVAR_WBYTE              ;[0BAE] 
    POP   AF                        ;[0BB1] 
    POP   BC                        ;[0BB2] 
    RET                             ;[0BB3] 

;
; Output filename to tape.
;
WRITE_FNAME:
    CALL  WSYNC                     ;[0BB4] 
    LD    A,(DE)                    ;[0BB7] 
    CALL  SYSVAR_WBYTE              ;[0BB8] 
WRITE_FNAME_LOOP:
    INC   DE                        ;[0BBB] Repeat until quote ["] character.
    LD    A,(DE)                    ;[0BBC] 
    CALL  SYSVAR_WBYTE              ;[0BBD] 
    CP    $22                       ;[0BC0] 
    JR    NZ,WRITE_FNAME_LOOP       ;[0BC2] 
    RET                             ;[0BC4] 

;
; Disable motor. Line "Not Found".
;
SAVE_END_ERROR:
    CALL  MOTOFF                    ;[0BC5] 
    CALL  ERR_NOT_FOUND             ;[0BC8] 

;
; SAVE BASIC command. (DE -> filename?)
;
BASIC_COM_SAVE:
    CALL  WRITE_FNAME               ;[0BCB] 
    INC   DE                        ;[0BCE] 
    LD    A,(DE)                    ;[0BCF] 
    LD    HL,$0000                  ;[0BD0] 
    PUSH  HL                        ;[0BD3] 
    CP    $0D                       ;[0BD4] 
    JR    Z,SAVE_HEADER             ;[0BD6] 
    POP   HL                        ;[0BD8] 
    INC   DE                        ;[0BD9] 
    CALL  SUB_CHK_EXP_EVAL          ;[0BDA] 
    CALL  FNDLN_WRA1                ;[0BDD] 
    JR    NZ,SAVE_END_ERROR         ;[0BE0] Error - basic line not found.
    PUSH  IX                        ;[0BE2] 
    POP   HL                        ;[0BE4] 
    LD    DE,(SYSVAR_EOB)           ;[0BE5] 
    OR    A                         ;[0BE9] 
    SBC   HL,DE                     ;[0BEA] 
    PUSH  HL                        ;[0BEC] 
SAVE_HEADER:
    LD    HL,(SYSVAR_EOB)           ;[0BED] Calculate program length.
    LD    DE,(SYSVAR_SOB)           ;[0BF0] 
    OR    A                         ;[0BF4] 
    SBC   HL,DE                     ;[0BF5] 
    INC   HL                        ;[0BF7] 
    PUSH  HL                        ;[0BF8] 
    LD    HL,(SYSVAR_SOB)           ;[0BF9] 
    CALL  WSYNC                     ;[0BFC] 
    LD    A,$42                     ;[0BFF] Write letter "B" - chr$($42)
    CALL  SYSVAR_WBYTE              ;[0C01] 
    POP   BC                        ;[0C04] Write basic program length.
    LD    A,C                       ;[0C05] 
    CALL  SYSVAR_WBYTE              ;[0C06] 
    LD    A,B                       ;[0C09] 
    CALL  SYSVAR_WBYTE              ;[0C0A] 
SAVE_BASIC:
    LD    A,(HL)                    ;[0C0D] 
    CALL  SYSVAR_WBYTE              ;[0C0E] 
    INC   HL                        ;[0C11] 
    DEC   BC                        ;[0C12] 
    LD    A,B                       ;[0C13] 
    OR    C                         ;[0C14] 
    JR    NZ,SAVE_BASIC             ;[0C15] 
    POP   HL                        ;[0C17] Write auto-run line number.
    LD    A,L                       ;[0C18] 
    CALL  SYSVAR_WBYTE              ;[0C19] 
    LD    A,H                       ;[0C1C] 
    CALL  SYSVAR_WBYTE              ;[0C1D] 
    CALL  SYSVAR_WBYTE              ;[0C20] Twice, for some reason?
    JP    MOTOFF                    ;[0C23] 

;
; Called by LOAD, VERIFY, APPEND (reads filename/header?).
;
TAPE_READ:
    INC   DE                        ;[0C26] 
TAPE_READ_NEXT:
    PUSH  DE                        ;[0C27] 
    LD    HL,INPBUF                 ;[0C28] 
TAPE_FIND_SYNC:
    CALL  RSYNC                     ;[0C2B] 
    CALL  RBYTE                     ;[0C2E] 
    CP    $22                       ;[0C31] Find quote " character (beginning of filename).
    JR    NZ,TAPE_FIND_SYNC         ;[0C33] 
TAPE_READ_FNAME:
    CALL  RBYTE                     ;[0C35] 
    LD    (HL),A                    ;[0C38] 
    INC   L                         ;[0C39] 
    CP    $22                       ;[0C3A] Find quote " character (end of filename).
    JR    NZ,TAPE_READ_FNAME        ;[0C3C] 
    POP   DE                        ;[0C3E] 
    PUSH  DE                        ;[0C3F] 
    LD    A,$20                     ;[0C40] 
    RST   $08                       ;[0C42] 
    LD    A,$22                     ;[0C43] 
    RST   $08                       ;[0C45] 
    LD    (HL),$00                  ;[0C46] 
    LD    HL,INPBUF                 ;[0C48] 
    PUSH  HL                        ;[0C4B] 
    CALL  PLINE                     ;[0C4C] Display filename.
    DEC   HL                        ;[0C4F] 
    LD    (HL),$0D                  ;[0C50] 
    POP   HL                        ;[0C52] 
    CALL  STRING_CMP                ;[0C53] 
    POP   DE                        ;[0C56] 
    JR    NZ,TAPE_READ_NEXT         ;[0C57] Wrong file, try again.
    RET                             ;[0C59] 

;
; VERIFY BASIC command.
;
BASIC_COM_VERIFY:
    CALL  TAPE_READ                 ;[0C5A] 
    LD    HL,(SYSVAR_SOB)           ;[0C5D] 
    CALL  RSYNC                     ;[0C60] 
    CALL  RBYTE                     ;[0C63] 
    CP    $42                       ;[0C66] 
    JR    NZ,VERIFY_ERROR_EXIT      ;[0C68] 
    CALL  RBYTE                     ;[0C6A] 
    LD    C,A                       ;[0C6D] 
    CALL  RBYTE                     ;[0C6E] 
    LD    B,A                       ;[0C71] 
VERIFY_READ_NEXT:
    CALL  RBYTE                     ;[0C72] 
    CP    (HL)                      ;[0C75] 
    INC   HL                        ;[0C76] 
    JR    NZ,VERIFY_ERROR_EXIT      ;[0C77] 
    DEC   BC                        ;[0C79] 
    LD    A,B                       ;[0C7A] 
    OR    C                         ;[0C7B] 
    JR    NZ,VERIFY_READ_NEXT       ;[0C7C] 
    JP    MOTOFF                    ;[0C7E] 
VERIFY_ERROR_EXIT:
    CALL  MOTOFF                    ;[0C81] 
    JP    ERR_BAD_TAPE              ;[0C84] 

;
; APPEND BASIC command.
;
BASIC_COM_APPEND:
    CALL  TAPE_READ                 ;[0C87] 
    LD    HL,(SYSVAR_EOB)           ;[0C8A] 
    JR    BLOAD_READ_B              ;[0C8D] 

;
; LOAD BASIC command.
;
BASIC_COM_LOAD:
    CALL  TAPE_READ                 ;[0C8F] 
    LD    HL,(SYSVAR_SOB)           ;[0C92] 
BLOAD_READ_B:
    CALL  RSYNC                     ;[0C95] 
    CALL  RBYTE                     ;[0C98] 
    CP    $42                       ;[0C9B] 'B' char
    JR    NZ,BLOAD_READ_B           ;[0C9D] 
    CALL  RBYTE                     ;[0C9F] Read length into BC
    LD    C,A                       ;[0CA2] 
    CALL  RBYTE                     ;[0CA3] 
    LD    B,A                       ;[0CA6] 
BLOAD_READ_PROG:
    CALL  RBYTE                     ;[0CA7] 
    LD    (HL),A                    ;[0CAA] 
    INC   HL                        ;[0CAB] 
    DEC   BC                        ;[0CAC] 
    LD    A,B                       ;[0CAD] 
    OR    C                         ;[0CAE] 
    JR    NZ,BLOAD_READ_PROG        ;[0CAF] 
    DEC   HL                        ;[0CB1] 
    LD    (SYSVAR_EOB),HL           ;[0CB2] end of basic = HL
    CALL  RBYTE                     ;[0CB5] Read execution point -> DE (-ve offset from end)
    LD    E,A                       ;[0CB8] 
    CALL  RBYTE                     ;[0CB9] 
    LD    D,A                       ;[0CBC] 
    OR    E                         ;[0CBD] 
    JP    Z,MOTOFF                  ;[0CBE] 
    ADD   HL,DE                     ;[0CC1] 
    PUSH  HL                        ;[0CC2] 
    CALL  MOTOFF                    ;[0CC3] 
    CALL  ZERO_MEM                  ;[0CC6] 
    POP   IX                        ;[0CC9] Start pos/line
    JP    RUN_BASIC_PROG            ;[0CCB] 

;
; Escape route for read bit routine.
;
RBIT_END:
    CALL  MOTOFF                    ;[0CCE] 
    JP    JUMP_TO_CMDLINE           ;[0CD1] 

;
; Read bit routine.
;
RBIT:
    LD    BC,$0080                  ;[0CD4] 
    LD    D,$00                     ;[0CD7] 
RBIT_LOOP1:
    IN    E,(C)                     ;[0CD9] 
    SRL   E                         ;[0CDB] 
    JR    C,RBIT_LOOP1              ;[0CDD] 
    BIT   5,E                       ;[0CDF] 
    JR    Z,RBIT_END                ;[0CE1] 
RBIT_LOOP2:
    IN    E,(C)                     ;[0CE3] 
    INC   D                         ;[0CE5] 
    SRL   E                         ;[0CE6] 
    JR    NC,RBIT_LOOP2             ;[0CE8] 
    LD    E,A                       ;[0CEA] 
    LD    A,(SYSVAR_CASLEV)         ;[0CEB] 
    CP    D                         ;[0CEE] 
    LD    A,E                       ;[0CEF] 
    RLA                             ;[0CF0] 
    RET                             ;[0CF1] 

;
; Turns cassette motor on. 
;
MOTON:
    LD    A,$02                     ;[0CF2] 
    OUT   ($80),A                   ;[0CF4] 
    LD    A,$0C                     ;[0CF6] 
    OUT   ($86),A                   ;[0CF8] 
    RET                             ;[0CFA] 

;
; Turns cassette motor off. NB must follow MOTON. 
;
MOTOFF:
    XOR   A                         ;[0CFB] 
    OUT   ($87),A                   ;[0CFC] 
    OUT   ($80),A                   ;[0CFE] 
    LD    BC,$1770                  ;[0D00] 
MOTOFF_DELAY:
    DEC   BC                        ;[0D03] 
    LD    A,B                       ;[0D04] 
    OR    C                         ;[0D05] 
    JR    NZ,MOTOFF_DELAY           ;[0D06] 
    RET                             ;[0D08] 

;
; Table used to generate wave. Pointed to by 62A1
;
DATA_CASTBL:
    DB $1D,$1B,$18,$16,$14,$12,$10,$0E      ;[0D09]  ........
    DB $0C,$0A,$09,$07,$06,$05,$04,$03      ;[0D11]  ........
    DB $02,$02,$02,$02,$02,$02,$02,$03      ;[0D19]  ........
    DB $04,$05,$06,$07,$09,$0A,$0C,$0E      ;[0D21]  ........
    DB $10,$12,$14,$16,$18,$1B,$1D,$20      ;[0D29]  ........
    DB $22,$24,$27,$29,$2B,$2D,$2F,$31      ;[0D31]  "$')+-/1
    DB $33,$35,$36,$38,$39,$3A,$3B,$3C      ;[0D39]  35689:;<
    DB $3D,$3D,$3D,$3E,$3D,$3D,$3D,$3C      ;[0D41]  ===>===<
    DB $3B,$3A,$39,$38,$36,$35,$33,$31      ;[0D49]  ;:986531
    DB $2F,$2D,$2B,$29,$27,$24,$22,$20      ;[0D51]  /-+)'$".
    DB $00,$00,$00,$00,$00,$00,$00,$00      ;[0D59]  ........
    DB $00,$00,$00,$00,$00,$00              ;[0D61]  ......

;
; Write byte to tape.
;
WBYTE:
    PUSH  AF                        ;[0D67] 
    PUSH  HL                        ;[0D68] 
    PUSH  DE                        ;[0D69] 
    PUSH  BC                        ;[0D6A] 
    LD    B,$00                     ;[0D6B] 
    LD    E,A                       ;[0D6D] 
    LD    A,(SYSVAR_FINE)           ;[0D6E] 
    LD    D,A                       ;[0D71] 
    SCF                             ;[0D72] 
WBYTE_COARSE:
    RL    E                         ;[0D73] 
    JR    Z,WBYTE_END               ;[0D75] 
    LD    A,(SYSVAR_COARSE)         ;[0D77] 
    JR    C,WBYTE_WAVE              ;[0D7A] 
    RLCA                            ;[0D7C] 
WBYTE_WAVE:
    LD    C,A                       ;[0D7D] 
    LD    HL,(SYSVAR_CASTBL)        ;[0D7E] Load the waveform values
WBYTE_SAMPLE:
    LD    A,(HL)                    ;[0D81] 
    OR    A                         ;[0D82] 
    JR    Z,WBYTE_COARSE            ;[0D83] 
    OUT   ($84),A                   ;[0D85] 
    ADD   HL,BC                     ;[0D87] 
    LD    B,D                       ;[0D88] 
WBYTE_DELAY:
    DJNZ  WBYTE_DELAY               ;[0D89] 
    JR    WBYTE_SAMPLE              ;[0D8B] 
WBYTE_END:
    POP   BC                        ;[0D8D] 
    POP   DE                        ;[0D8E] 
    POP   HL                        ;[0D8F] 
    POP   AF                        ;[0D90] 
    RET                             ;[0D91] 

;
; TAPE. Loads a 4 byte tape speed into HL and DE using the lookup table (DATA_TAPE).
;
BASIC_COM_TAPE:
    RST   $18                       ;[0D92] 
    CP    $06                       ;[0D93] 
    CALL  NC,ERR_NUM_OUT_RANGE      ;[0D95] 
    RLCA                            ;[0D98] 
    RLCA                            ;[0D99] 
    LD    E,A                       ;[0D9A] 
    LD    D,$00                     ;[0D9B] 
    LD    HL,DATA_TAPE              ;[0D9D] 
    ADD   HL,DE                     ;[0DA0] 
    LD    DE,SYSVAR_CASLEV          ;[0DA1] 
    LD    B,$04                     ;[0DA4] 
BASIC_COM_TAPE1:
    LD    A,(HL)                    ;[0DA6] 
    LD    (DE),A                    ;[0DA7] 
    INC   DE                        ;[0DA8] 
    INC   HL                        ;[0DA9] 
    DJNZ  BASIC_COM_TAPE1           ;[0DAA] 
    RET                             ;[0DAC] 

;
; Six 32 bit timing values, used by the TAPE command.
;
DATA_TAPE:
    DB $50,$01,$04,$03,$38,$01,$01,$04      ;[0DAD]  P...8...
    DB $2C,$02,$04,$05,$23,$02,$02,$06      ;[0DB5]  ,...#...
    DB $1B,$02,$01,$07,$14,$03,$02,$08      ;[0DBD]  ........

;
; Moves cursor one character block to the right. (VDU 12) (I don't know why it's called PATCH1)
;
PATCH1:
    CALL  ADV_CURSOR                ;[0DC5] 
    JP    SAVE_CURSORX              ;[0DC8] 

;
; Test if 96k or 48k and set SP accordingly. Called from INIT.
;
SUB_TEST_4896K:
    LD    HL,$9FF8                  ;[0DCB] 
    LD    DE,$BFF8                  ;[0DCE] 
    LD    A,(DE)                    ;[0DD1] 
    CPL                             ;[0DD2] 
    LD    (DE),A                    ;[0DD3] 
    LD    C,(HL)                    ;[0DD4] 
    CPL                             ;[0DD5] 
    LD    (DE),A                    ;[0DD6] 
    LD    A,(HL)                    ;[0DD7] 
    CP    C                         ;[0DD8] 
    JR    NZ,SUB_TEST_END           ;[0DD9] 
    LD    HL,$0FF8                  ;[0DDB] 
    LD    DE,$F000                  ;[0DDE] 
SUB_TEST_96K:
    ADD   HL,DE                     ;[0DE1] 
    LD    A,(HL)                    ;[0DE2] 
    CPL                             ;[0DE3] 
    LD    (HL),A                    ;[0DE4] 
    LD    C,(HL)                    ;[0DE5] 
    CPL                             ;[0DE6] 
    LD    (HL),A                    ;[0DE7] 
    CP    C                         ;[0DE8] 
    JR    Z,SUB_TEST_96K            ;[0DE9] 
SUB_TEST_END:
    LD    SP,HL                     ;[0DEB] 
    JP    START                     ;[0DEC] 

;
; Overwrite off, CR/LF,  greater than symbol >
;
DATA_PROMPT:
    DB $14,$13,$3E,$00              ;[0DEF]  ..>.

;
; Test for [Esc] key. Stop BASIC if necessary.
;
SUB_INPUT_IS_ESC:
    CALL  SYSVAR_LINP               ;[0DF3] 
    CALL  ESC                       ;[0DF6] 
    RET   NZ                        ;[0DF9] Zero if ESC pressed
    POP   DE                        ;[0DFA] 
    POP   DE                        ;[0DFB] 
    POP   BC                        ;[0DFC] 
    LD    IX,(SYSVAR_CURRLP)        ;[0DFD] Current BASIC line
    JP    BASIC_COM_STOP1           ;[0E01] 
    RST   $38                       ;[0E04] 

;
; ERROR. Outputs specified error message.
;
BASIC_COM_ERROR:
    RST   $18                       ;[0E05] 
    JP    DISP_ERROR_A              ;[0E06] 

;
; LETTER - ptr to specified DATA_CHARS definitions.
;
BASIC_FN_LETTER:
    CALL  FPINT                     ;[0E09] 
    LD    A,L                       ;[0E0C] 
    CP    $20                       ;[0E0D] 
    CALL  C,ERR_NUM_OUT_RANGE       ;[0E0F] 
    CALL  FONT                      ;[0E12] 
    JP    INTFP                     ;[0E15] 

;
; MOD.
;
BASIC_FN_MOD:
    CALL  SWAP                      ;[0E18] 
    CALL  BASIC_FN_ABS              ;[0E1B] 
    CALL  PUSH_WRA1                 ;[0E1E] 
    CALL  PUSH_WRA1                 ;[0E21] 
    CALL  SWAP                      ;[0E24] 
    CALL  DIV                       ;[0E27] 
    CALL  BASIC_FN_FRAC             ;[0E2A] 
    CALL  POP_WRA2                  ;[0E2D] 
    CALL  _MULT                     ;[0E30] 
    CALL  POP_WRA2                  ;[0E33] 
    LD    A,(SYSVAR_WRA1)           ;[0E36] 
    CALL  SUB_MOD                   ;[0E39] 
JP_FN_INT:
    JP    BASIC_FN_INT              ;[0E3C] 

;
; DIV.
;
BASIC_FN_DIV:
    CALL  DIV                       ;[0E3F] 
    JR    JP_FN_INT                 ;[0E42] 

;
; Return INK value.
;
BASIC_FN_INK:
    LD    HL,(SYSVAR_INKST)         ;[0E44] 
L_TO_WRA1:
    LD    H,$00                     ;[0E47] 
HL_TO_WRA1:
    JP    INTFP                     ;[0E49] 

;
; Return PAPER value.
;
BASIC_FN_PAPER:
    LD    HL,(SYSVAR_PAPST)         ;[0E4C] 
    JR    L_TO_WRA1                 ;[0E4F] 

;
; POS.
;
BASIC_FN_POS:
    LD    HL,(SYSVAR_CURSORX)       ;[0E51] 
    JR    L_TO_WRA1                 ;[0E54] 

;
; VPOS.
;
BASIC_FN_VPOS:
    LD    HL,(SYSVAR_CURSORY)       ;[0E56] 
    JR    L_TO_WRA1                 ;[0E59] 

;
; GRAPHIC.
;
BASIC_FN_GRAPHIC:
    LD    HL,SYSVAR_GPHTBL          ;[0E5B] 
    JR    HL_TO_WRA1                ;[0E5E] 

;
; ALPHA.
;
BASIC_FN_ALPHA:
    LD    HL,SYSVAR_CHRTBL          ;[0E60] 
    JR    HL_TO_WRA1                ;[0E63] 

;
; INF.
;
BASIC_FN_INF:
    LD    HL,DATA_INF               ;[0E65] 
    JP    LNUM1                     ;[0E68] 

;
; Data for INF.
;
DATA_INF:
    DB $FF,$99,$99,$99,$99          ;[0E6B]  .....

;
; Load BC and HL with the integers in WRA1 and WRA2. 
; Utility routine called by BNOR, BNXOR & BNAND.
;
HLBC_FROM_WRA12:
    CALL  FPINT                     ;[0E70] 
    PUSH  HL                        ;[0E73] Push HL, HL = integer (WRA1)
    LD    HL,SYSVAR_WRA2            ;[0E74] Let HL = WRA2
    CALL  LNUM1                     ;[0E77] Let WRA1 = (HL) (=WRA2)
    CALL  FPINT                     ;[0E7A] Let HL = WRA1
    POP   BC                        ;[0E7D] 
    RET                             ;[0E7E] 

;
; BNOR.
;
BASIC_FN_BNOR:
    CALL  HLBC_FROM_WRA12           ;[0E7F] 
    LD    A,B                       ;[0E82] 
    OR    H                         ;[0E83] 
    LD    H,A                       ;[0E84] 
    LD    A,C                       ;[0E85] 
    OR    L                         ;[0E86] 
BN_RESULT_TO_WRA1:
    LD    L,A                       ;[0E87] 
    JP    INTFP                     ;[0E88] 

;
; BNXOR.
;
BASIC_FN_BNXOR:
    CALL  HLBC_FROM_WRA12           ;[0E8B] 
    LD    A,B                       ;[0E8E] 
    XOR   H                         ;[0E8F] 
    LD    H,A                       ;[0E90] 
    LD    A,C                       ;[0E91] 
    XOR   L                         ;[0E92] 
    JR    BN_RESULT_TO_WRA1         ;[0E93] 

;
; BNAND.
;
BASIC_FN_BNAND:
    CALL  HLBC_FROM_WRA12           ;[0E95] 
    LD    A,B                       ;[0E98] 
    AND   H                         ;[0E99] 
    LD    H,A                       ;[0E9A] 
    LD    A,C                       ;[0E9B] 
    AND   L                         ;[0E9C] 
    JR    BN_RESULT_TO_WRA1         ;[0E9D] 

;
; RAND.
;
BASIC_FN_RAND:
    CALL  PUSH_WRA1                 ;[0E9F] 
    CALL  BASIC_FN_RND              ;[0EA2] 
    CALL  POP_WRA2                  ;[0EA5] 
    CALL  _MULT                     ;[0EA8] 
    JP    BASIC_FN_INT              ;[0EAB] 

;
; CFR. Cursor flash rate.
;
BASIC_COM_CFR:
    RST   $18                       ;[0EAE] 
    LD    (SYSVAR_FLASH),HL         ;[0EAF] CFR.
    RET                             ;[0EB2] 

;
; CCHAR.
;
BASIC_COM_CCHAR:
    RST   $18                       ;[0EB3] 
    LD    (SYSVAR_INPCUR),HL        ;[0EB4] 
    RET                             ;[0EB7] 

;
; List of colours - starting with WHITE
;
BASIC_FN_COLOUR:
    XOR   A                         ;[0EB8] 
    INC   A                         ;[0EB9] 
    LD    B,$AF                     ;[0EBA] YELLOW.
    INC   A                         ;[0EBC] 
    LD    B,$AF                     ;[0EBD] CYAN.
    INC   A                         ;[0EBF] 
    LD    B,$AF                     ;[0EC0] GREEN.
    INC   A                         ;[0EC2] 
    LD    B,$AF                     ;[0EC3] MAGENTA.
    INC   A                         ;[0EC5] 
    LD    B,$AF                     ;[0EC6] RED.
    INC   A                         ;[0EC8] 
    LD    B,$AF                     ;[0EC9] BLUE.
    INC   A                         ;[0ECB] 
    LD    B,$AF                     ;[0ECC] BLACK.
    LD    L,A                       ;[0ECE] 
    LD    H,$00                     ;[0ECF] 
    JP    INTFP                     ;[0ED1] 

;
; Reads reverse polish until CR or comma reached (unused?)
;
READ_RP:
    CALL  RP                        ;[0ED4] 
    LD    (HL),A                    ;[0ED7] 
    CP    $0D                       ;[0ED8] 
    RET   Z                         ;[0EDA] 
    INC   HL                        ;[0EDB] 
    CP    $2C                       ;[0EDC] 
    JR    Z,READ_RP                 ;[0EDE] 
    CALL  ERR_SYNTAX                ;[0EE0] 

;
; VDU routine.
;
BASIC_COM_VDU:
    RST   $18                       ;[0EE3] 
    RST   $08                       ;[0EE4] 
    LD    A,(DE)                    ;[0EE5] 
    CP    $0D                       ;[0EE6] 
    RET   Z                         ;[0EE8] 
    INC   DE                        ;[0EE9] 
    JR    BASIC_COM_VDU             ;[0EEA] 
    LD    B,$05                     ;[0EEC] 
    JR    VALIDATE_WORD_ABCD        ;[0EEE] 

;
; Validation for WINDOW.
;
VALIDATE_WINDOW:
    LD    B,$03                     ;[0EF0] 
    JR    VALIDATE_WORD_ABCD        ;[0EF2] 

;
; Validation for PLOT;BEEP;PAINT.
;
VALIDATE_PLOT:
    LD    B,$02                     ;[0EF4] 

;
; Validation. Words of the form:- WORD a,b,c,d.
;
VALIDATE_WORD_ABCD:
    PUSH  BC                        ;[0EF6] 
    CALL  RP                        ;[0EF7] 
    RST   $20                       ;[0EFA] 
    INC   L                         ;[0EFB] 
    LD    (HL),A                    ;[0EFC] 
    INC   HL                        ;[0EFD] 
    POP   BC                        ;[0EFE] 
    DJNZ  VALIDATE_WORD_ABCD        ;[0EFF] 
    JP    VALIDATE_INK              ;[0F01] 

;
; Validation for '?'.
;
VALIDATE_PRINT:
    DEC   HL                        ;[0F04] 
    LD    A,$1D                     ;[0F05] 
    JP    IL2                       ;[0F07] 

;
; Called from DBASLN (Display Basic Line)
;
PRINT_BAS_LINE:
    LD    A,(IX-$01)                ;[0F0A] 
    SUB   $08                       ;[0F0D] 
    LD    B,A                       ;[0F0F] 
PRINT_BAS_LINE_LOOP:
    CALL  OUTPUT_SPACE              ;[0F10] 
    LD    A,(DE)                    ;[0F13] 
    INC   DE                        ;[0F14] 
    CALL  PRINT_HEX_A               ;[0F15] 
    DJNZ  PRINT_BAS_LINE_LOOP       ;[0F18] 
    JP    DO_INDENT                 ;[0F1A] 

;
; Part of CODE validation.
;
VALIDATE_CODE1:
    LD    A,(DE)                    ;[0F1D] 
    LD    (HL),A                    ;[0F1E] 
    CP    $0D                       ;[0F1F] 
    RET   Z                         ;[0F21] 
    RST   $20                       ;[0F22] 
    JR    NZ,$0EFC                  ;[0F23] 

;
; Validation for CODE.
;
VALIDATE_CODE:
    CALL  VALIDATE_CODE2            ;[0F25] 
    LD    (HL),C                    ;[0F28] 
    INC   HL                        ;[0F29] 
    JR    VALIDATE_CODE1            ;[0F2A] 

;
; Part of CODE validation.
;
VALIDATE_CODE2:
    LD    C,$00                     ;[0F2C] 
    LD    A,(DE)                    ;[0F2E] 
    SUB   $30                       ;[0F2F] 
    RET   C                         ;[0F31] 
    CP    $0A                       ;[0F32] 
    JR    C,$0F3E                   ;[0F34] 
    SUB   $07                       ;[0F36] 
    CP    $0A                       ;[0F38] 
    RET   C                         ;[0F3A] 
    CP    $10                       ;[0F3B] 
    RET   NC                        ;[0F3D] 
    SLA   C                         ;[0F3E] 
    SLA   C                         ;[0F40] 
    SLA   C                         ;[0F42] 
    SLA   C                         ;[0F44] 
    ADD   A,C                       ;[0F46] 
    LD    C,A                       ;[0F47] 
    INC   DE                        ;[0F48] 
    JR    $0F2E                     ;[0F49] 

;
; Set INK routine.
;
BASIC_COM_INK:
    RST   $18                       ;[0F4B] 
    LD    (SYSVAR_INKST),A          ;[0F4C] 
    RET                             ;[0F4F] 

;
; Set PAPER routine.
;
BASIC_COM_PAPER:
    RST   $18                       ;[0F50] 
    LD    (SYSVAR_PAPST),A          ;[0F51] 
    RET                             ;[0F54] 

;
; MOVE.
;
BASIC_COM_MOVE:
    RST   $18                       ;[0F55] 
    INC   DE                        ;[0F56] 
    LD    (SYSVAR_GOLDX),HL         ;[0F57] 
    RST   $18                       ;[0F5A] 
    LD    (SYSVAR_GOLDY),A          ;[0F5B] 
    RET                             ;[0F5E] 

;
; DRAW.
;
BASIC_COM_DRAW:
    RST   $18                       ;[0F5F] 
    INC   DE                        ;[0F60] 
    LD    (SYSVAR_GNEWX),HL         ;[0F61] 
    RST   $18                       ;[0F64] 
    LD    (SYSVAR_GNEWY),A          ;[0F65] 
    JP    SYSVAR_GLINE              ;[0F68] 

;
; PLOT subroutine.
;
SUB_PLOT1:
    RST   $18                       ;[0F6B] 
    INC   DE                        ;[0F6C] 
    LD    BC,(SYSVAR_GOLDX)         ;[0F6D] 
    ADD   HL,BC                     ;[0F71] 
    LD    (SYSVAR_GOLDX),HL         ;[0F72] 
    RST   $18                       ;[0F75] 
    LD    A,(SYSVAR_GOLDY)          ;[0F76] 
    ADD   A,L                       ;[0F79] 
    LD    (SYSVAR_GOLDY),A          ;[0F7A] 
    RET                             ;[0F7D] 

;
; PLOT subroutine.
;
SUB_PLOT2:
    RST   $18                       ;[0F7E] 
    INC   DE                        ;[0F7F] 
    LD    BC,(SYSVAR_GOLDX)         ;[0F80] 
    ADD   HL,BC                     ;[0F84] 
    LD    (SYSVAR_GNEWX),HL         ;[0F85] 
    RST   $18                       ;[0F88] 
    LD    A,(SYSVAR_GOLDY)          ;[0F89] 
    ADD   A,L                       ;[0F8C] 
    LD    (SYSVAR_GNEWY),A          ;[0F8D] 
    JP    SYSVAR_GLINE              ;[0F90] 

;
; PLOT subroutine.
;
BASIC_COM_DOT:
    RST   $18                       ;[0F93] 
    INC   DE                        ;[0F94] 
    LD    (SYSVAR_GNEWX),HL         ;[0F95] 
    LD    (SYSVAR_GOLDX),HL         ;[0F98] 
    RST   $18                       ;[0F9B] 
    LD    (SYSVAR_GNEWY),A          ;[0F9C] 
    LD    (SYSVAR_GOLDY),A          ;[0F9F] 
    JP    SYSVAR_GLINE              ;[0FA2] 

;
; PLOT.
;
BASIC_COM_PLOT:
    RST   $18                       ;[0FA5] 
    INC   DE                        ;[0FA6] 
    OR    A                         ;[0FA7] 
    JP    Z,BASIC_COM_MOVE          ;[0FA8] 
    DEC   L                         ;[0FAB] 
    JP    Z,SUB_PLOT1               ;[0FAC] 
    DEC   L                         ;[0FAF] 
    JP    Z,BASIC_COM_DRAW          ;[0FB0] 
    DEC   L                         ;[0FB3] 
    JP    Z,SUB_PLOT2               ;[0FB4] 
    DEC   L                         ;[0FB7] 
    JP    Z,BASIC_COM_DOT           ;[0FB8] 
    CALL  ERR_NOT_YET_IMP           ;[0FBB] 
    LD    HL,(SYSVAR_GNEWX)         ;[0FBE] 
    PUSH  HL                        ;[0FC1] 
    LD    DE,(SYSVAR_GOLDX)         ;[0FC2] 
    LD    H,$00                     ;[0FC6] 
    LD    D,H                       ;[0FC8] 
    OR    A                         ;[0FC9] 
    SBC   HL,DE                     ;[0FCA] 
    EX    DE,HL                     ;[0FCC] 
    LD    HL,($6264)                ;[0FCD] 
    LD    L,$80                     ;[0FD0] 
    EXX                             ;[0FD2] 
    LD    HL,(SYSVAR_GNEWY)         ;[0FD3] 
    PUSH  HL                        ;[0FD6] 
    LD    DE,(SYSVAR_GOLDY)         ;[0FD7] 
    LD    H,$00                     ;[0FDB] 
    LD    D,H                       ;[0FDD] 
    OR    A                         ;[0FDE] 
    SBC   HL,DE                     ;[0FDF] 
    EX    DE,HL                     ;[0FE1] 
    LD    HL,($6266)                ;[0FE2] 
    LD    L,$80                     ;[0FE5] 
    LD    A,D                       ;[0FE7] 
    OR    E                         ;[0FE8] 
    EXX                             ;[0FE9] 
    LD    B,$01                     ;[0FEA] 
    OR    E                         ;[0FEC] 
    OR    D                         ;[0FED] 
    JR    Z,BASIC_COM_PLOT4         ;[0FEE] 
    DEC   B                         ;[0FF0] 
    CALL  SUB_PLOT5                 ;[0FF1] 
    JR    NZ,BASIC_COM_PLOT2        ;[0FF4] 
    SCF                             ;[0FF6] 
BASIC_COM_PLOT1:
    RR    B                         ;[0FF7] 
    CALL  SUB_PLOT4                 ;[0FF9] 
    CALL  SUB_PLOT5                 ;[0FFC] 
    JR    Z,BASIC_COM_PLOT1         ;[0FFF] 
BASIC_COM_PLOT2:
    CALL  SUB_PLOT3                 ;[1001] 
BASIC_COM_PLOT3:
    ADD   HL,DE                     ;[1004] 
    EXX                             ;[1005] 
    ADD   HL,DE                     ;[1006] 
    EXX                             ;[1007] 
BASIC_COM_PLOT4:
    CALL  SUB_PLOT3                 ;[1008] 
    DJNZ  BASIC_COM_PLOT3           ;[100B] 
    POP   HL                        ;[100D] 
    LD    A,L                       ;[100E] 
    LD    (SYSVAR_GOLDY),A          ;[100F] 
    POP   HL                        ;[1012] 
    LD    (SYSVAR_GOLDX),HL         ;[1013] 
    RET                             ;[1016] 

;
; PLOT subroutine.
;
SUB_PLOT3:
    EXX                             ;[1017] 
    LD    A,H                       ;[1018] 
    EXX                             ;[1019] 
    PUSH  HL                        ;[101A] 
    PUSH  DE                        ;[101B] 
    PUSH  BC                        ;[101C] 
    LD    L,A                       ;[101D] 
    LD    A,H                       ;[101E] 
    LD    H,$00                     ;[101F] 
    ADD   HL,HL                     ;[1021] 
    ADD   HL,HL                     ;[1022] 
    ADD   HL,HL                     ;[1023] 
    ADD   HL,HL                     ;[1024] 
    ADD   HL,HL                     ;[1025] 
    LD    C,A                       ;[1026] 
    SRL   C                         ;[1027] 
    SRL   C                         ;[1029] 
    SRL   C                         ;[102B] 
    LD    B,$00                     ;[102D] 
    ADD   HL,BC                     ;[102F] 
    LD    C,$80                     ;[1030] 
    AND   $07                       ;[1032] 
    JR    Z,SUB_PLOT3B              ;[1034] 
SUB_PLOT3A:
    SRL   C                         ;[1036] 
    DEC   A                         ;[1038] 
    JR    NZ,SUB_PLOT3A             ;[1039] 
SUB_PLOT3B:
    LD    A,C                       ;[103B] 
    CPL                             ;[103C] 
    LD    C,A                       ;[103D] 
    CPL                             ;[103E] 
    CALL  SYSVAR_OUTB               ;[103F] 
    POP   BC                        ;[1042] 
    POP   DE                        ;[1043] 
    POP   HL                        ;[1044] 
    RET                             ;[1045] 

;
; PLOT subroutine.
;
SUB_PLOT4:
    SLA   E                         ;[1046] 
    RL    D                         ;[1048] 
    EXX                             ;[104A] 
    SLA   E                         ;[104B] 
    RL    D                         ;[104D] 
    EXX                             ;[104F] 
    RET                             ;[1050] 

;
; PLOT subroutine.
;
SUB_PLOT5:
    EXX                             ;[1051] 
    LD    A,D                       ;[1052] 
    XOR   E                         ;[1053] 
    AND   $80                       ;[1054] 
    EXX                             ;[1056] 
    LD    C,A                       ;[1057] 
    LD    A,D                       ;[1058] 
    XOR   E                         ;[1059] 
    AND   $80                       ;[105A] 
    OR    C                         ;[105C] 
    RET                             ;[105D] 

;
; Displays string pointed to by HL and terminated by a CR.
;
PRTSTR:
    LD    A,(HL)                    ;[105E] 
    CP    $0D                       ;[105F] 
    RET   Z                         ;[1061] 
    RST   $08                       ;[1062] 
    INC   HL                        ;[1063] 
    JR    PRTSTR                    ;[1064] 

;
; Flash cursor and scan keyboard. (flash rate is in HL)
;
CURSOR_INPUT:
    CALL  FLASH_CURSOR              ;[1066] 
    CALL  KEY                       ;[1069] 
    OR    A                         ;[106C] 
    JR    Z,CURSOR_INPUT            ;[106D] 
    RET                             ;[106F] 

;
; Display buffer.
;
DISPLAY_BUFFER:
    PUSH  HL                        ;[1070] 
    PUSH  DE                        ;[1071] 
    LD    DE,(SYSVAR_CURSORX)       ;[1072] 
    LD    A,$20                     ;[1076] 
    RST   $08                       ;[1078] 
    DEC   HL                        ;[1079] 
DISPLAY_BUFFER1:
    INC   HL                        ;[107A] 
    LD    A,(HL)                    ;[107B] 
    CP    $0D                       ;[107C] 
    JR    Z,DISPLAY_BUFFER2         ;[107E] 
    RST   $08                       ;[1080] 
    JR    DISPLAY_BUFFER1           ;[1081] 
DISPLAY_BUFFER2:
    LD    A,$20                     ;[1083] 
    RST   $08                       ;[1085] 
    LD    (SYSVAR_CURSORX),DE       ;[1086] 
    POP   DE                        ;[108A] 
    POP   HL                        ;[108B] 
    RET                             ;[108C] 

;
; Loop until CR.
;
LINP_LOOP:
    LD    A,(DE)                    ;[108D] 
    CP    $0D                       ;[108E] 
    RET   Z                         ;[1090] 
    INC   B                         ;[1091] 
    INC   DE                        ;[1092] 
    JR    LINP_LOOP                 ;[1093] 

;
; Output the cursor.
;
FLASH_CURSOR:
    EXX                             ;[1095] 
    DEC   HL                        ;[1096] Decrement flash delay counter
    LD    A,H                       ;[1097] 
    OR    L                         ;[1098] 
    JR    NZ,FLASH_CURSOR_END       ;[1099] 
    LD    HL,(SYSVAR_FLASH)         ;[109B] Reset flash delay counter
SWAP_CCHARS:
    LD    A,B                       ;[109E] Swap cursor chars
    LD    B,C                       ;[109F] 
    LD    C,A                       ;[10A0] 
    RST   $08                       ;[10A1] 
    LD    A,$16                     ;[10A2] Backspace
    RST   $08                       ;[10A4] 
FLASH_CURSOR_END:
    EXX                             ;[10A5] 
    RET                             ;[10A6] 

;
; Character input routines
;
CHAR_INPUT:
    EX    AF,AF'                    ;[10A7] 
    LD    A,B                       ;[10A8] 
    CP    MAXLEN                    ;[10A9] 
    JR    NC,LINP1                  ;[10AB] 
    EX    AF,AF'                    ;[10AD] 
    RST   $08                       ;[10AE] 
    INC   DE                        ;[10AF] 
    PUSH  HL                        ;[10B0] 
    PUSH  DE                        ;[10B1] 
    PUSH  BC                        ;[10B2] 
    PUSH  DE                        ;[10B3] 
    EX    DE,HL                     ;[10B4] 
    OR    A                         ;[10B5] 
    SBC   HL,DE                     ;[10B6] 
    LD    C,L                       ;[10B8] 
    LD    B,H                       ;[10B9] 
    POP   DE                        ;[10BA] 
    LD    L,E                       ;[10BB] 
    LD    H,D                       ;[10BC] 
    DEC   HL                        ;[10BD] 
    LDDR                            ;[10BE] 
    POP   BC                        ;[10C0] 
    POP   DE                        ;[10C1] 
    POP   HL                        ;[10C2] 
    LD    (HL),A                    ;[10C3] 
    INC   HL                        ;[10C4] 
    CALL  DISPLAY_BUFFER            ;[10C5] 
    INC   B                         ;[10C8] 
    INC   C                         ;[10C9] 
    JR    LINP1                     ;[10CA] 

;
; Load flash rate and cursor characters.
;
CURS_VALUES:
    LD    HL,INPBUF                 ;[10CC] 
    LD    D,H                       ;[10CF] 
    LD    E,L                       ;[10D0] 
    LD    BC,$0000                  ;[10D1] 
    EXX                             ;[10D4] 
    LD    HL,(SYSVAR_FLASH)         ;[10D5] 
    LD    BC,(SYSVAR_INPCUR)        ;[10D8] 
    EXX                             ;[10DC] 
    RET                             ;[10DD] 

;
; Carriage Return, Linefeed
;
LINP_CRLF:
    LD    (HL),$0D                  ;[10DE] 
    JR    LINP2                     ;[10E0] 

;
; Line input routine - called via SYSVAR_LINP
;
LINP:
    CALL  CURS_VALUES               ;[10E2] 
    LD    A,$0F                     ;[10E5] 
    RST   $08                       ;[10E7] 
    CALL  CURSOR_INPUT              ;[10E8] 
    CP    $11                       ;[10EB] 
    JR    NZ,LINP_CRLF              ;[10ED] 
LINP0:
    CALL  LINP_LOOP                 ;[10EF] 
    CALL  DISPLAY_BUFFER            ;[10F2] 
LINP1:
    EXX                             ;[10F5] 
    LD    A,B                       ;[10F6] 
    RST   $08                       ;[10F7] 
    LD    A,$16                     ;[10F8] 
    RST   $08                       ;[10FA] 
    EXX                             ;[10FB] 
    CALL  CURSOR_INPUT              ;[10FC] 
LINP2:
    CP    $20                       ;[10FF] 
    JR    NC,CHAR_INPUT             ;[1101] 
    CP    $08                       ;[1103] Backspace
    JR    Z,LINP4                   ;[1105] 
    CP    $0B                       ;[1107] Move right
    JP    Z,LINP6                   ;[1109] 
    CP    $0A                       ;[110C] Linefeed
    JP    Z,LINP_CR                 ;[110E] 
    CP    $16                       ;[1111] 
    JR    Z,LINP3                   ;[1113] 
    CP    $0C                       ;[1115] Cursor right
    JR    Z,LINP_INP_CHR            ;[1117] 
    CP    $05                       ;[1119] Control E?
    JP    Z,CONTROL_E               ;[111B] 
    CP    $0D                       ;[111E] Carriage return
    JR    NZ,LINP1                  ;[1120] 
    CALL  PRTSTR                    ;[1122] 
    LD    A,$20                     ;[1125] Space
    RST   $08                       ;[1127] 
    LD    A,$0D                     ;[1128] Carriage return
    RST   $08                       ;[112A] 
    INC   B                         ;[112B] 
    DEC   B                         ;[112C] 
    RET                             ;[112D] 

;
; *tbd
;
LINP3:
    DEC   C                         ;[112E] 
    INC   C                         ;[112F] 
    JR    Z,LINP1                   ;[1130] 
    DEC   HL                        ;[1132] 
    DEC   C                         ;[1133] 
    LD    A,(HL)                    ;[1134] 
    RST   $08                       ;[1135] 
    LD    A,$16                     ;[1136] Backspace
    RST   $08                       ;[1138] 

;
; Output char in A
;
LINP_OUTA:
    RST   $08                       ;[1139] 
    JR    LINP1                     ;[113A] 

;
; Input char
;
LINP_INP_CHR:
    LD    A,(HL)                    ;[113C] 
    CP    $0D                       ;[113D] Carriage return
    JR    Z,LINP1                   ;[113F] 
    INC   HL                        ;[1141] 
    INC   C                         ;[1142] 
    JR    LINP_OUTA                 ;[1143] 

;
; TBD
;
LINP4:
    DEC   C                         ;[1145] 
    INC   C                         ;[1146] 
    JR    Z,LINP1                   ;[1147] 
    DEC   HL                        ;[1149] 
    PUSH  HL                        ;[114A] 
    PUSH  DE                        ;[114B] 
    PUSH  BC                        ;[114C] 
    EX    DE,HL                     ;[114D] 
    OR    A                         ;[114E] 
    SBC   HL,DE                     ;[114F] 
    LD    C,L                       ;[1151] 
    LD    B,H                       ;[1152] 
    LD    L,E                       ;[1153] 
    LD    H,D                       ;[1154] 
    INC   HL                        ;[1155] 
    LDIR                            ;[1156] 
    POP   BC                        ;[1158] 
    POP   DE                        ;[1159] 
    POP   HL                        ;[115A] 
    DEC   DE                        ;[115B] 
    DEC   B                         ;[115C] 
    DEC   C                         ;[115D] 
    LD    A,$16                     ;[115E] Backspace cursor
    RST   $08                       ;[1160] 
    CALL  DISPLAY_BUFFER            ;[1161] 
    JP    LINP1                     ;[1164] 

;
; Handle edit line - [CTRL] E
;
CONTROL_E:
    INC   B                         ;[1167] 
    DEC   B                         ;[1168] 
    JP    NZ,LINP1                  ;[1169] 
    LD    HL,DATA_LINE_NUMBER       ;[116C] Print "Line Number?"
    CALL  PLINE                     ;[116F] 
    CALL  CURS_VALUES               ;[1172] Load cursor values (rate,etc)
    CALL  LINP_CRLF                 ;[1175] 
    LD    DE,INPBUF                 ;[1178] 
    RST   $10                       ;[117B] is (DE) a space?
    CALL  RDN                       ;[117C] 
    CALL  FNDLN_WRA1                ;[117F] 
    CALL  NZ,ERR_NOT_FOUND          ;[1182] 
    LD    HL,(SYSVAR_PRINTD)        ;[1185] 
    PUSH  HL                        ;[1188] 
    LD    HL,SUB_LINP_EDITB         ;[1189] 
    LD    (SYSVAR_PRINTD),HL        ;[118C] Display driver
    LD    HL,INPBUF                 ;[118F] 
    LD    (SYSVAR_EDST),HL          ;[1192] LET Edit buffer = $6000 (beginning of RAM)
    XOR   A                         ;[1195] 
    LD    (SYSVAR_SBC),A            ;[1196] Space before command
    CALL  SYSVAR_DBASLN             ;[1199] Display Basic line
    POP   HL                        ;[119C] 
    LD    (SYSVAR_PRINTD),HL        ;[119D] 
    CALL  CURS_VALUES               ;[11A0] Load cursor flash rate and chars
    JP    LINP0                     ;[11A3] 

;
; Put a character into edit buffer and also handle CR
;
SUB_LINP_EDITB:
    PUSH  AF                        ;[11A6] 
    CP    $1E                       ;[11A7] Clears to end of line
    JR    NZ,SUB_LINP_EDITB1        ;[11A9] 
    LD    A,$0D                     ;[11AB] Carriage return, linefeed
SUB_LINP_EDITB1:
    PUSH  HL                        ;[11AD] 
    LD    HL,(SYSVAR_EDST)          ;[11AE] Let HL = Edit buffer
    LD    (HL),A                    ;[11B1] 
    INC   HL                        ;[11B2] 
    LD    (SYSVAR_EDST),HL          ;[11B3] 
    POP   HL                        ;[11B6] 
    POP   AF                        ;[11B7] 
    RET                             ;[11B8] 

;
; Data. 'Line number?'
;
DATA_LINE_NUMBER:
    DB $4C,$69,$6E,$65,$20,$6E,$75,$6D      ;[11B9]  Line.num
    DB $62,$65,$72,$3F,$20,$00              ;[11C1]  ber?..

LINP6:
    DEC   C                         ;[11C7] 
    INC   C                         ;[11C8] 
    JP    Z,LINP1                   ;[11C9] 
    DEC   HL                        ;[11CC] 
    DEC   C                         ;[11CD] 
    LD    A,(HL)                    ;[11CE] 
    RST   $08                       ;[11CF] 
    LD    A,$16                     ;[11D0] Backspace?
    RST   $08                       ;[11D2] 
    RST   $08                       ;[11D3] 
    JR    LINP6                     ;[11D4] 

;
; Search (HL) and print chars until CR
;
LINP_CR:
    LD    A,(HL)                    ;[11D6] 
    CP    $0D                       ;[11D7] 
    JP    Z,LINP1                   ;[11D9] 
    INC   HL                        ;[11DC] 
    INC   C                         ;[11DD] 
    RST   $08                       ;[11DE] 
    JR    LINP_CR                   ;[11DF] 

;
; Non-command token table
;
DATA_TTBL:
    DB $CD,$45,$4D,$D0,$49,$CB,$45,$59      ;[11E1]  .EM.I.EY
    DB $4E,$D2,$4E,$44,$C8,$4C,$CC,$45      ;[11E9]  N.ND.L.E
    DB $4E,$28,$D6,$41,$4C,$28,$C1,$53      ;[11F1]  N(.AL(.S
    DB $43,$28,$C8,$49,$4D,$45,$4D,$C7      ;[11F9]  C(.IMEM.
    DB $45,$54,$4E,$C9,$4E,$4B,$D0,$41      ;[1201]  ETN.NK.A
    DB $50,$45,$52,$D0,$4F,$53,$D6,$50      ;[1209]  PER.OS.P
    DB $4F,$53,$D4,$52,$55,$45,$C6,$41      ;[1211]  OS.RUE.A
    DB $4C,$53,$45,$C9,$4E,$46,$C2,$4C      ;[1219]  LSE.NF.L
    DB $41,$43,$4B,$C2,$4C,$55,$45,$D2      ;[1221]  ACK.LUE.
    DB $45,$44,$CD,$41,$47,$45,$4E,$54      ;[1229]  ED.AGENT
    DB $41,$C7,$52,$45,$45,$4E,$C3,$59      ;[1231]  A.REEN.Y
    DB $41,$4E,$D9,$45,$4C,$4C,$4F,$57      ;[1239]  AN.ELLOW
    DB $D7,$48,$49,$54,$45,$C1,$4C,$50      ;[1241]  .HITE.LP
    DB $48,$41,$C7,$52,$41,$50,$48,$49      ;[1249]  HA.RAPHI
    DB $43,$D3,$49,$4E,$C3,$4F,$53,$D4      ;[1251]  C.IN.OS.
    DB $41,$4E,$C5,$58,$50,$CC,$4F,$47      ;[1259]  AN.XP.OG
    DB $C1,$4E,$54,$49,$4C,$4F,$47,$CC      ;[1261]  .NTILOG.
    DB $4E,$D3,$47,$4E,$C1,$42,$53,$C9      ;[1269]  N.GN.BS.
    DB $4E,$54,$C6,$52,$41,$43,$D3,$51      ;[1271]  NT.RAC.Q
    DB $52,$D0,$45,$45,$4B,$C4,$50,$45      ;[1279]  R.EEK.PE
    DB $45,$4B,$C9,$4E,$50,$C6,$41,$43      ;[1281]  EK.NP.AC
    DB $54,$C1,$52,$43,$54,$41,$4E,$C1      ;[1289]  T.RCTAN.
    DB $52,$43,$43,$4F,$53,$C1,$52,$43      ;[1291]  RCCOS.RC
    DB $53,$49,$4E,$CC,$43,$54,$4E,$C2      ;[1299]  SIN.CTN.
    DB $49,$4E,$C4,$45,$47,$D2,$41,$44      ;[12A1]  IN.EG.AD
    DB $D2,$41,$4E,$44,$CC,$49,$47,$48      ;[12A9]  .AND.IGH
    DB $54,$50,$45,$4E,$CA,$4F,$59,$53      ;[12B1]  TPEN.OYS
    DB $54,$4B,$D5,$53,$45,$52,$30,$D5      ;[12B9]  TK.SER0.
    DB $53,$45,$52,$31,$D5,$53,$45,$52      ;[12C1]  SER1.SER
    DB $32,$D5,$53,$45,$52,$33,$CC,$45      ;[12C9]  2.SER3.E
    DB $54,$54,$45,$52,$80,$80,$80,$80      ;[12D1]  TTER....
    DB $80,$A8,$CE,$4F,$54,$AD,$80,$80      ;[12D9]  ...OT...
    DB $80,$AA,$2A,$AA,$AF,$AB,$AD,$BE      ;[12E1]  ..*.....
    DB $3D,$BC,$3D,$BC,$3E,$BE,$BC,$BD      ;[12E9]  =.=.>...
    DB $CF,$52,$C1,$4E,$44,$C2,$4E,$4F      ;[12F1]  .R.ND.NO
    DB $52,$C2,$4E,$58,$4F,$52,$C2,$4E      ;[12F9]  R.NXOR.N
    DB $41,$4E,$44,$C4,$49,$56,$CD,$4F      ;[1301]  AND.IV.O
    DB $44,$D4,$48,$45,$4E,$CC,$41,$42      ;[1309]  D.HEN.AB
    DB $45,$4C,$C0,$CF,$4E,$CF,$46,$46      ;[1311]  EL..N.FF
    DB $D3,$54,$45,$50,$D4,$4F,$D4,$41      ;[1319]  .TEP.O.A
    DB $42,$C3,$48,$52,$24,$28,$CC,$45      ;[1321]  B.HR$(.E
    DB $46,$54,$24,$28,$D2,$49,$47,$48      ;[1329]  FT$(.IGH
    DB $54,$24,$28,$CD,$49,$44,$24,$28      ;[1331]  T$(.ID$(
    DB $D5,$50,$43,$24,$28,$CB,$45,$59      ;[1339]  .PC$(.EY
    DB $24,$C7,$45,$54,$24,$D3,$54,$52      ;[1341]  $.ET$.TR
    DB $24,$28,$80,$80                      ;[1349]  $(..

;
; Set to 80. Is it used ?
;
DATA_BLANK:
    DB $80,$80,$80,$80,$80,$80,$80,$80      ;[134D]  ........
    DB $80,$80,$80,$80,$80,$80,$80,$80      ;[1355]  ........
    DB $80,$80,$80,$80,$80,$80,$80,$80      ;[135D]  ........
    DB $80,$80,$80                          ;[1365]  ...

;
; Function evaluation table.
;
DATA_FTBL:
    DB $69,$1E,$0C,$36,$26,$20,$57,$1E      ;[1368]  i..6&.W.
    DB $24,$33,$14,$2D,$0E,$2D,$26,$2D      ;[1370]  $3.-.-&-
    DB $1D,$33,$1E,$20,$44,$0E,$4C,$0E      ;[1378]  .3..D.L.
    DB $51,$0E,$56,$0E,$BF,$35,$AE,$35      ;[1380]  Q.V..5.5
    DB $65,$0E,$CD,$0E,$CA,$0E,$C7,$0E      ;[1388]  e.......
    DB $C4,$0E,$C1,$0E,$BE,$0E,$BB,$0E      ;[1390]  ........
    DB $B8,$0E,$60,$0E,$5B,$0E,$23,$32      ;[1398]  ..`.[.#2
    DB $1A,$32,$90,$31,$84,$31,$E4,$30      ;[13A0]  .2.1.1.0
    DB $AB,$31,$4C,$2F,$3A,$34,$34,$34      ;[13A8]  .1L/:444
    DB $56,$34,$75,$34,$52,$30,$3F,$33      ;[13B0]  V4u4R0?3
    DB $36,$33,$29,$33,$10,$30,$A5,$2F      ;[13B8]  63)3.0./
    DB $85,$2F,$58,$2F,$9D,$1F,$D9,$28      ;[13C0]  ./X/...(
    DB $45,$33,$4E,$33,$9F,$0E,$76,$62      ;[13C8]  E3N3..vb
    DB $79,$62,$7C,$62,$7F,$62,$82,$62      ;[13D0]  yb|b.b.b
    DB $85,$62,$09,$0E,$32,$3B,$32,$3B      ;[13D8]  .b..2;2;
    DB $32,$3B,$32,$3B,$32,$3B,$00,$00      ;[13E0]  2;2;2;..
    DB $A5,$32,$11,$33,$07,$33,$04,$33      ;[13E8]  .2.3.3.3
    DB $D8,$1D,$9A,$30,$C8,$36,$B0,$37      ;[13F0]  ...0.6.7
    DB $6D,$36,$6A,$36,$DA,$32,$D0,$32      ;[13F8]  m6j6.2.2
    DB $BD,$32,$C2,$32,$D5,$32,$AF,$32      ;[1400]  .2.2.2.2
    DB $DF,$32,$F6,$32,$7F,$0E,$8B,$0E      ;[1408]  .2.2....
    DB $95,$0E,$3F,$0E,$18,$0E              ;[1410]  ..?...

;
; Command token table.
;
DATA_XTTBL:
    DB $4B,$CC,$45,$54,$D6,$44,$55,$C4      ;[1416]  K.ET.DU.
    DB $45,$46,$50,$52,$4F,$43,$D0,$52      ;[141E]  EFPROC.R
    DB $4F,$43,$C5,$4E,$44,$50,$52,$4F      ;[1426]  OC.NDPRO
    DB $43,$CE,$45,$58,$54,$C9,$4E,$4B      ;[142E]  C.EXT.NK
    DB $D0,$41,$50,$45,$52,$D2,$41,$4E      ;[1436]  .APER.AN
    DB $44,$4F,$4D,$D6,$45,$52,$49,$46      ;[143E]  DOM.ERIF
    DB $59,$C4,$50,$4F,$4B,$45,$C4,$4F      ;[1446]  Y.POKE.O
    DB $54,$D0,$4F,$4B,$45,$C5,$4E,$44      ;[144E]  T.OKE.ND
    DB $D3,$54,$4F,$50,$C6,$4F,$52,$C7      ;[1456]  .TOP.OR.
    DB $4F,$54,$4F,$C7,$4F,$53,$55,$42      ;[145E]  OTO.OSUB
    DB $D2,$45,$54,$55,$52,$4E,$C3,$4C      ;[1466]  .ETURN.L
    DB $53,$D2,$55,$4E,$C3,$4F,$4E,$54      ;[146E]  S.UN.ONT
    DB $CF,$55,$54,$D2,$45,$4D,$D2,$45      ;[1476]  .UT.EM.E
    DB $41,$44,$C4,$41,$54,$41,$CE,$45      ;[147E]  AD.ATA.E
    DB $57,$C4,$45,$4C,$C1,$55,$54,$4F      ;[1486]  W.EL.UTO
    DB $D0,$52,$49,$4E,$54,$CC,$4F,$41      ;[148E]  .RINT.OA
    DB $44,$D3,$41,$56,$45,$D2,$45,$53      ;[1496]  D.AVE.ES
    DB $54,$4F,$52,$45,$D0,$4C,$4F,$54      ;[149E]  TORE.LOT
    DB $CD,$4F,$56,$45,$C4,$52,$41,$57      ;[14A6]  .OVE.RAW
    DB $C3,$41,$4C,$4C,$C9,$4E,$50,$55      ;[14AE]  .ALL.NPU
    DB $54,$C4,$49,$4D,$C9,$46,$CC,$49      ;[14B6]  T.IM.F.I
    DB $53,$54,$D7,$49,$4E,$44,$4F,$57      ;[14BE]  ST.INDOW
    DB $D0,$41,$55,$53,$45,$D2,$4F,$55      ;[14C6]  .AUSE.OU
    DB $4E,$44,$D4,$52,$41,$49,$4C,$CC      ;[14CE]  ND.RAIL.
    DB $50,$52,$49,$4E,$54,$CC,$4C,$49      ;[14D6]  PRINT.LI
    DB $53,$54,$CC,$41,$42,$45,$4C,$C2      ;[14DE]  ST.ABEL.
    DB $45,$45,$50,$D3,$4F,$55,$4E,$44      ;[14E6]  EEP.OUND
    DB $C1,$50,$50,$45,$4E,$44,$C3,$4F      ;[14EE]  .PPEND.O
    DB $44,$45,$CC,$49,$4E,$4B,$D3,$57      ;[14F6]  DE.INK.W
    DB $41,$50,$D7,$48,$49,$4C,$45,$D7      ;[14FE]  AP.HILE.
    DB $45,$4E,$44,$D2,$45,$50,$45,$41      ;[1506]  END.EPEA
    DB $54,$D5,$4E,$54,$49,$4C,$C0,$40      ;[150E]  T.NTIL.@
    DB $40,$40,$40,$BF,$C5,$4C,$53,$45      ;[1516]  @@@..LSE
    DB $D2,$45,$53,$45,$52,$56,$45,$CD      ;[151E]  .ESERVE.
    DB $4F,$4E,$D2,$45,$4E,$55,$4D,$D8      ;[1526]  ON.ENUM.
    DB $52,$4F,$4D,$C5,$58,$54,$C3,$46      ;[152E]  ROM.XT.F
    DB $52,$C3,$43,$48,$41,$52,$D4,$52      ;[1536]  R.CHAR.R
    DB $41,$43,$45,$D3,$50,$45,$45,$44      ;[153E]  ACE.PEED
    DB $D0,$52,$4F,$54,$45,$43,$54,$C5      ;[1546]  .ROTECT.
    DB $52,$52,$4F,$52,$D4,$41,$50,$45      ;[154E]  RROR.APE
    DB $CD,$4C,$4F,$41,$44,$D4,$45,$58      ;[1556]  .LOAD.EX
    DB $54,$80                              ;[155E]  T.

;
; Input syntax checking table. Validation routine addresses for BASIC words.
;
DATA_XITBL:
    DB $7C,$26,$D4,$0E,$6F,$29,$5D,$29      ;[1560]  |&..o)])
    DB $DB,$26,$D8,$26,$07,$27,$07,$27      ;[1568]  .&.&.'.'
    DB $DB,$26,$16,$26,$BD,$26,$BD,$26      ;[1570]  .&.&.&.&
    DB $BD,$26,$DB,$26,$DB,$26,$DF,$26      ;[1578]  .&.&.&.&
    DB $C3,$26,$C3,$26,$DB,$26,$DB,$26      ;[1580]  .&.&.&.&
    DB $5D,$26,$DB,$26,$BD,$26,$3C,$27      ;[1588]  ]&.&.&<'
    DB $39,$26,$3C,$27,$DB,$26,$68,$26      ;[1590]  9&<'.&h&
    DB $64,$26,$11,$2A,$16,$26,$1D,$26      ;[1598]  d&.*.&.&
    DB $5D,$26,$F4,$0E,$BD,$26,$BD,$26      ;[15A0]  ]&...&.&
    DB $68,$26,$2C,$26,$66,$2E,$FD,$26      ;[15A8]  h&,&f..&
    DB $64,$26,$F0,$0E,$07,$27,$06,$26      ;[15B0]  d&...'.&
    DB $06,$26,$11,$2A,$64,$26,$3C,$27      ;[15B8]  .&.*d&<'
    DB $F4,$0E,$BD,$26,$16,$26,$25,$0F      ;[15C0]  ...&.&%.
    DB $06,$26,$45,$27,$07,$27,$DB,$26      ;[15C8]  .&E'.'.&
    DB $DB,$26,$07,$27,$F4,$0E,$04,$0F      ;[15D0]  .&.'....
    DB $A9,$27,$07,$27,$DB,$26,$64,$26      ;[15D8]  .'.'.&d&
    DB $DB,$26,$21,$62,$07,$27,$07,$27      ;[15E0]  .&!b.'.'
    DB $06,$26,$07,$27,$07,$27,$07,$27      ;[15E8]  .&.'.'.'
    DB $07,$27,$16,$26,$DB,$26              ;[15F0]  .'.&.&

;
; Command execution table. Execution routine addresses for BASIC words.
;
DATA_XETBL:
    DB $48,$21,$E3,$0E,$4A,$3B,$04,$29      ;[15F6]  H!..J;.)
    DB $88,$29,$DB,$23,$4B,$0F,$50,$0F      ;[15FE]  .).#K.P.
    DB $A8,$1F,$5A,$0C,$8C,$23,$93,$0F      ;[1606]  ..Z..#..
    DB $85,$23,$BE,$1F,$2F,$1E,$97,$23      ;[160E]  .#../..#
    DB $A2,$22,$96,$22,$74,$20,$B1,$1F      ;[1616]  ."."t...
    DB $80,$22,$6D,$22,$7D,$23,$5F,$24      ;[161E]  ."m"}#_$
    DB $C5,$21,$5F,$24,$83,$20,$3F,$23      ;[1626]  .!_$..?#
    DB $8A,$28,$A9,$29,$8F,$0C,$CB,$0B      ;[162E]  .(.)....
    DB $7D,$21,$A5,$0F,$55,$0F,$5F,$0F      ;[1636]  }!..U._.
    DB $5F,$20,$94,$20,$CB,$2D,$2C,$24      ;[163E]  _....-,$
    DB $E9,$22,$31,$08,$22,$21,$73,$24      ;[1646]  ."1."!s$
    DB $55,$24,$4E,$22,$38,$23,$5F,$24      ;[164E]  U$N"8#_$
    DB $3D,$09,$81,$09,$87,$0C,$5F,$24      ;[1656]  =....._$
    DB $7E,$24,$5F,$22,$D3,$1F,$C4,$1F      ;[165E]  ~$_"....
    DB $13,$20,$FA,$1F,$32,$3B,$32,$3B      ;[1666]  ....2;2;
    DB $5F,$24,$4E,$2A,$64,$3B,$7E,$2A      ;[166E]  _$N*d;~*
    DB $00,$E0,$24,$62,$AE,$0E,$B3,$0E      ;[1676]  ..$b....
    DB $6E,$24,$60,$24,$2D,$21,$05,$0E      ;[167E]  n$`$-!..
    DB $92,$0D,$62,$3F,$32,$21              ;[1686]  ..b?2!

;
; Lynx initialisation (called after INIT CRT)
;
INIT:
    DI                              ;[168C] 
    LD    HL,DATA_INIT              ;[168D] Initialise stack.
    LD    DE,SYSVAR_STACK           ;[1690] 
    LD    BC,$00D3                  ;[1693] 
    LDIR                            ;[1696] 
    LD    HL,(SYSVAR_SOB)           ;[1698] Setup start of basic.
    LD    (HL),$80                  ;[169B] 
    DEC   HL                        ;[169D] 
    LD    (HL),$0D                  ;[169E] 
    JP    SUB_TEST_4896K            ;[16A0] 

;
; Check for external ROM, display Lynx Logo, start main loop
;
START:
    LD    A,(EXT_ROM)               ;[16A3] 
    OR    A                         ;[16A6] 
    CALL  Z,EXT_ROM                 ;[16A7] External rom is present, boot it. (otherwise FF)
    CALL  ZERO_MEM                  ;[16AA] 
    LD    HL,INPBUF                 ;[16AD] 
    LD    (HL),$0D                  ;[16B0] 
    ADD   HL,SP                     ;[16B2] 
    LD    HL,DATA_LYNX_LOGO         ;[16B3] 
    JR    NC,LOGO_OUTPUT            ;[16B6] 
    LD    HL,DATA_2BEEPS+$02        ;[16B8] Skip a beep
    NOP                             ;[16BB] 
LOGO_OUTPUT:
    CALL  PLINE                     ;[16BC] 
MAIN_LOOP:
    CALL  MAIN1                     ;[16BF] 
    JR    MAIN_LOOP                 ;[16C2] 

;
; MAIN - called from MAIN_LOOP.
;
MAIN1:
    LD    HL,DATA_PROMPT            ;[16C4] 
    CALL  PLINE                     ;[16C7] Display prompt
    LD    A,(SYSVAR_AUTOFL)         ;[16CA] Auto line numbering?
    OR    A                         ;[16CD] 
    JR    Z,USER_INPUT              ;[16CE] Get user input.
    LD    HL,SYSVAR_AUTOST          ;[16D0] Auto increment
    CALL  LNUM1                     ;[16D3] -> WRA1
    CALL  FNDLN_WRA1                ;[16D6] Find line with number in WRA1
    LD    A,' '                     ;[16D9] 
    JR    NZ,MAIN6                  ;[16DB] 
    LD    A,'!'                     ;[16DD] Line already exists - exclamation mark!
MAIN6:
    PUSH  AF                        ;[16DF] 
    CALL  PN                        ;[16E0] Print number in WRA1
    POP   AF                        ;[16E3] 
    RST   $08                       ;[16E4] 
USER_INPUT:
    CALL  SYSVAR_LINP               ;[16E5] Handle user input at the prompt
    JR    NZ,DO_AUTONUM             ;[16E8] 
    LD    HL,SYSVAR_AUTOFL          ;[16EA] 
    LD    (HL),$00                  ;[16ED] 
    RET                             ;[16EF] 

;
; Called from USER_INPUT
;
DO_AUTONUM:
    LD    (SYSVAR_STACK),SP         ;[16F0] 
    LD    DE,INPBUF                 ;[16F4] 
    CALL  LINP_ANLYS                ;[16F7] 
    LD    A,(SYSVAR_AUTOFL)         ;[16FA] 
    OR    A                         ;[16FD] 
    JR    Z,MAIN1                   ;[16FE] 
    LD    HL,SYSVAR_AUTOST          ;[1700] 
    CALL  LNUM1                     ;[1703] 
    LD    HL,$62F8                  ;[1706] 
    CALL  LNUM2                     ;[1709] 
    CALL  ADD                       ;[170C] 
    LD    DE,SYSVAR_AUTOST          ;[170F] 
    JP    WRA1_TO_DE                ;[1712] 

;
; Data used in initialisation.
;
DATA_INIT:
    DB $00,$FF,$01,$00,$00,$00,$00,$00      ;[1715]  ........
    DB $05,$36,$4C,$69,$4D,$69,$4D,$69      ;[171D]  .6LiMiMi
    DB $07,$63,$A4,$06,$5F,$24,$5B,$0B      ;[1725]  .c.._$[.
    DB $01,$00,$01,$00,$00,$07,$66,$07      ;[172D]  ......f.
    DB $66,$07,$67,$10,$68,$E4,$68,$68      ;[1735]  f.g.h.hh
    DB $13,$E1,$11,$16,$14,$60,$15,$F6      ;[173D]  .....`..
    DB $15,$4E,$69,$C3,$3C,$27,$C3,$32      ;[1745]  .Ni.<'.2
    DB $3B,$C9,$00,$00,$C9,$00,$00,$01      ;[174D]  ;.......
    DB $00,$18,$35,$00,$00,$00,$08,$00      ;[1755]  ..5.....
    DB $00,$00,$00,$00,$1C,$30,$15,$1B      ;[175D]  .....0..
    DB $19,$02,$10,$11,$25,$2F,$3E,$28      ;[1765]  ....%/>(
    DB $12,$05,$04,$03,$17,$38,$0E,$44      ;[176D]  .....8.D
    DB $39,$09,$36,$37,$14,$20,$03,$05      ;[1775]  9.67....
    DB $03,$7B,$05,$F5,$00,$07,$00,$00      ;[177D]  .{......
    DB $02,$20,$EF,$00,$C3,$BE,$0F,$00      ;[1785]  ........
    DB $00,$00,$00,$00,$00,$00,$C3,$5E      ;[178D]  .......^
    DB $08,$94,$00,$D4,$01,$20,$00,$00      ;[1795]  ........
    DB $C3,$32,$3B,$C3,$32,$3B,$C3,$32      ;[179D]  .2;.2;.2
    DB $3B,$C3,$32,$3B,$C3,$32,$3B,$C3      ;[17A5]  ;.2;.2;.
    DB $32,$3B,$C9,$00,$00,$C9,$00,$00      ;[17AD]  2;......
    DB $00,$80,$00,$C0,$00,$C0,$C3,$32      ;[17B5]  .......2
    DB $3B,$C3,$32,$3B,$EF,$38,$50,$01      ;[17BD]  ;.2;.8P.
    DB $04,$03,$28,$09,$0D,$C3,$D4,$0C      ;[17C5]  ..(.....
    DB $C3,$67,$0D,$C3,$D7,$18,$C3,$BE      ;[17CD]  .g......
    DB $19,$C3,$A9,$33,$C3,$E5,$27,$C3      ;[17D5]  ...3..'.
    DB $E5,$24,$C3,$9A,$00,$C3,$E2,$10      ;[17DD]  .$......
    DB $C3,$5C,$2D,$00                      ;[17E5]  .\-.

;
; BEEP,BEEP
;
DATA_2BEEPS:
    DB $04,$07,$04,$07              ;[17E9]  ....

;
; Data used to display the 'LYNX LOGO' at power on.
;
DATA_LYNX_LOGO:
    DB $04,$07,$18,$F3,$F4,$F5,$F6,$F7      ;[17ED]  ........
    DB $F8,$F9,$19,$0A,$0A,$0D,$00          ;[17F5]  .......

;
; BASIC line analysis routine.
;
ADV:
    LD    A,(DE)                    ;[17FC] 
    INC   DE                        ;[17FD] 
    CP    $7C                       ;[17FE] 
    JR    Z,ADVSOS                  ;[1800] 
    CP    $79                       ;[1802] 
    JR    Z,ADVSOS                  ;[1804] 
    CP    LEN                       ;[1806] 
    JR    Z,ADV                     ;[1808] 
    CP    ASC                       ;[180A] 
    JR    Z,ADV                     ;[180C] 
    CP    VAL                       ;[180E] 
    JR    Z,ADV                     ;[1810] 
    CP    HNUM                      ;[1812] 
    JR    Z,ADV2                    ;[1814] 
    CP    NUM                       ;[1816] 
    RET   NZ                        ;[1818] 
ADV2:
    INC   DE                        ;[1819] 
    INC   DE                        ;[181A] 
ADV1:
    INC   DE                        ;[181B] 
    INC   DE                        ;[181C] 
    INC   DE                        ;[181D] 
    RET                             ;[181E] 

;
; Line analysis subroutine.
;
ADVSOS:
    CALL  ADV                       ;[181F] 
    CP    EOS                       ;[1822] 
    JR    NZ,ADVSOS                 ;[1824] 
    RET                             ;[1826] 

;
; Line analysis subroutine.
;
PNAMST:
    PUSH  DE                        ;[1827] 
    CALL  DBASLN2                   ;[1828] 
    POP   DE                        ;[182B] 
    RET                             ;[182C] 

;
; Line analysis subroutine. (Polish name?)
;
PNAME:
    LD    A,(DE)                    ;[182D] 
    CP    SOS                       ;[182E] 
    JR    Z,PNAMST                  ;[1830] 
    CP    $80                       ;[1832] 
    JR    NC,PNE1                   ;[1834] Jump if not VAR or NUM
    CP    NUM                       ;[1836] Check if number
    JR    Z,PNAME2                  ;[1838] 
    CP    HNUM                      ;[183A] 
    JR    Z,PNEH1                   ;[183C] 
    RES   6,A                       ;[183E] Must be a variable
    ADD   A,'A'-1                   ;[1840] Put in correct range
    CP    'Z'+1                     ;[1842] 
    JP    C,PUTCHAR                 ;[1844] 
    ADD   A,6                       ;[1847] 
    JP    PUTCHAR                   ;[1849] 
PNAME2:
    PUSH  DE                        ;[184C] Save pointer
    INC   DE                        ;[184D] Inc past num
    EX    DE,HL                     ;[184E] Move to WRA1
    CALL  LNUM1                     ;[184F] 
    CALL  PN                        ;[1852] Display number
    POP   DE                        ;[1855] 
    RET                             ;[1856] 

;
; Line analysis subroutine.
;
PNE1:
    CP    LEN                       ;[1857] 
    JR    Z,PNE14                   ;[1859] 
    CP    ASC                       ;[185B] 
    JR    Z,PNE14                   ;[185D] 
    CP    VAL                       ;[185F] 
    JR    NZ,PNE11                  ;[1861] 
PNE14:
    CALL  PNE11                     ;[1863] 
    PUSH  DE                        ;[1866] 
    INC   DE                        ;[1867] 
    CALL  PNAMST                    ;[1868] 
    POP   DE                        ;[186B] 
    RET                             ;[186C] 

;
; Line analysis subroutine.
;
PNE11:
    CALL  TOKEN_TO_WORD             ;[186D] 
PNE15:
    LD    A,(HL)                    ;[1870] Get first char
    RES   7,A                       ;[1871] 
PNE12:
    RST   $08                       ;[1873] Print it
    INC   HL                        ;[1874] 
    BIT   7,(HL)                    ;[1875] See if done
    RET   NZ                        ;[1877] 
    LD    A,(HL)                    ;[1878] 
    JR    PNE12                     ;[1879] 
PNEH1:
    PUSH  DE                        ;[187B] 
    LD    A,'&'                     ;[187C] 
    RST   $08                       ;[187E] 
    INC   DE                        ;[187F] 
    EX    DE,HL                     ;[1880] 
    CALL  LNUM1                     ;[1881] 
    CALL  FPINT                     ;[1884] 
    CALL  PHEXHL                    ;[1887] 
    POP   DE                        ;[188A] 
    RET                             ;[188B] 

;
; Loop down a list of words to find an address.
;
TOKEN_TO_WORD:
    SUB   $7F                       ;[188C] 
    LD    B,A                       ;[188E] 
    LD    HL,(SYSVAR_TTBL)          ;[188F] 
    DEC   HL                        ;[1892] 
TOKEN_TO_WORD_FIND:
    INC   HL                        ;[1893] 
    BIT   7,(HL)                    ;[1894] 
    JR    Z,TOKEN_TO_WORD_FIND      ;[1896] 
    DJNZ  TOKEN_TO_WORD_FIND        ;[1898] 
    RET                             ;[189A] 

;
; Line analysis subroutine.
;
SP1:
    CP    $C2                       ;[189B] 
    RET   NC                        ;[189D] 
    CP    $BF                       ;[189E] 
    RET   C                         ;[18A0] 
    POP   IX                        ;[18A1] Get return address
    JR    SP21                      ;[18A3] 
SP2:
    POP   IX                        ;[18A5] Get return address
    CP    $C5                       ;[18A7] Right range?
    JR    C,SP2E                    ;[18A9] 
    CP    $D0                       ;[18AB] Put a b$spac in front
    JR    C,SP21                    ;[18AD] AND, OR, etc.
    LD    HL,$2020                  ;[18AF] 
    PUSH  HL                        ;[18B2] 
SP21:
    LD    C,A                       ;[18B3] Save token
    INC   A                         ;[18B4] Word after required one
    CALL  TOKEN_TO_WORD             ;[18B5] 
SP22:
    DEC   HL                        ;[18B8] Back up
    LD    A,(HL)                    ;[18B9] Get char
    BIT   7,A                       ;[18BA] First?
    RES   7,A                       ;[18BC] Ascii
    PUSH  AF                        ;[18BE] Save char
    JR    Z,SP22                    ;[18BF] 
    LD    A,C                       ;[18C1] 
    CP    $D0                       ;[18C2] 
    JR    C,SP2E                    ;[18C4] 
    LD    A,' '                     ;[18C6] Put B$SPAC after and, or, etc.
    PUSH  AF                        ;[18C8] 
SP2E:
    JP    (IX)                      ;[18C9] Exit

;
; Processing.
;
PS:
    POP   IX                        ;[18CB] 
PS1:
    POP   AF                        ;[18CD] Get char
    OR    A                         ;[18CE] Top?
    JR    Z,PSX                     ;[18CF] Exit if top
    RST   $08                       ;[18D1] Print char
    JR    PS1                       ;[18D2] 
PSX:
    PUSH  AF                        ;[18D4] Restore top marker
    JP    (IX)                      ;[18D5] Return

;
; Print a polish expression
;
PP:
    XOR   A                         ;[18D7] 
    PUSH  AF                        ;[18D8] 
    LD    IY,SYSVAR_SYNL            ;[18D9] 
PP1:
    LD    A,(DE)                    ;[18DD] 
    CP    $7F                       ;[18DE] 
    JP    Z,PPX                     ;[18E0] 
    CP    $BF                       ;[18E3] 
    JR    C,PP5                     ;[18E5] 
    LD    A,$29                     ;[18E7] 
    CALL  Z,PUTCHAR                 ;[18E9] 
    CALL  ADV                       ;[18EC] 
    JR    PP1                       ;[18EF] 
PP5:
    LD    (IY+$00),$00              ;[18F1] 
    LD    L,E                       ;[18F5] 
    LD    H,D                       ;[18F6] 
PP2:
    INC   (IY+$00)                  ;[18F7] 
    DEC   (IY+$00)                  ;[18FA] 
    JP    M,PP6                     ;[18FD] 
    CALL  ADV                       ;[1900] 
    LD    A,(DE)                    ;[1903] 
    CP    $7F                       ;[1904] 
    JR    Z,PP6                     ;[1906] 
    CP    $BF                       ;[1908] 
    JP    NC,PP3                    ;[190A] 
    INC   (IY+$00)                  ;[190D] 
    JR    PP2                       ;[1910] 
PP3:
    CP    $C3                       ;[1912] 
    JR    C,PP4                     ;[1914] 
    DEC   (IY+$00)                  ;[1916] 
PP4:
    EXX                             ;[1919] 
    INC   (IY+$00)                  ;[191A] 
    DEC   (IY+$00)                  ;[191D] 
    CALL  Z,SP1                     ;[1920] 
    INC   (IY+$00)                  ;[1923] 
    PUSH  AF                        ;[1926] 
    DEC   (IY+$00)                  ;[1927] 
    POP   AF                        ;[192A] 
    CALL  Z,SP2                     ;[192B] 
    EXX                             ;[192E] 
    JP    PP2                       ;[192F] 
PP6:
    CALL  PS                        ;[1932] 
    LD    E,L                       ;[1935] 
    LD    D,H                       ;[1936] 
    LD    A,(DE)                    ;[1937] 
    CALL  PNAME                     ;[1938] 
    CALL  ADV                       ;[193B] 
    JP    PP1                       ;[193E] 
PPX:
    POP   AF                        ;[1941] 
    RET                             ;[1942] 

;
; Pick up address from a list of BASIC words.
; Check if DE points to a tokenable word.
; Advance DE past word and return token in A 
; else return CHR pointed to by DE & increment DE.
;
TK:
    LD    HL,(SYSVAR_TTBL)          ;[1943] 
    DEC   HL                        ;[1946] 
    LD    B,WORDS                   ;[1947] 
    CALL  TKSUB                     ;[1949] Find word in list, return address if pos.
TK1:
    INC   HL                        ;[194C] 
    BIT   7,(HL)                    ;[194D] Jump to TK1 is not start of word
    JR    Z,TK1                     ;[194F] 
    CP    (HL)                      ;[1951] Check against table
    JR    Z,TK2                     ;[1952] Jump if match
TK5:
    DJNZ  TK1                       ;[1954] else decrement word count
    LD    A,(DE)                    ;[1956] No word matches so get byte
    SCF                             ;[1957] Set carry to indicate no word
    RET                             ;[1958] Found, return

TK2:
    PUSH  DE                        ;[1959] Save pointer
TK3:
    INC   DE                        ;[195A] Increment pointer
    INC   HL                        ;[195B] 
    EX    DE,HL                     ;[195C] 
    RST   $10                       ;[195D] 
    EX    DE,HL                     ;[195E] 
    RST   $10                       ;[195F] Get next char
    BIT   7,(HL)                    ;[1960] Check beginning of next word
    JR    NZ,TK4                    ;[1962] 
    CP    '.'                       ;[1964] G$DOT type abbreviation
    JR    Z,TK6                     ;[1966] 
    CP    $40                       ;[1968] 
    JR    C,TK9                     ;[196A] 
    AND   %11011111                 ;[196C] Uppercase
TK9:
    CP    (HL)                      ;[196E] Keep incrementing until NO
    JR    Z,TK3                     ;[196F] No match found
    POP   DE                        ;[1971] Put pointer back in DE
    CALL  TKSUB                     ;[1972] Get char
    JR    TK5                       ;[1975] Continue looking
TK6:
    INC   DE                        ;[1977] Advance pointer
    RST   $10                       ;[1978] And exit
TK4:
    POP   HL                        ;[1979] Restore stack
    XOR   A                         ;[197A] Put token into A
    SUB   B                         ;[197B] A:=-A
    OR    A                         ;[197C] Clear carry
    RET                             ;[197D] 

;
; Search for start of BASIC word in a list.
;
TKSUB:
    RST   $10                       ;[197E] 
    OR    $80                       ;[197F] Set bit 7
    CP    $C0                       ;[1981] Not alpha if C
    RET   C                         ;[1983] 
    AND   $DF                       ;[1984] 
    RET                             ;[1986] Upper case

;
; Normal to internal language routine.
;
NPSTR:
    LD    B,(IX+$02)                ;[1987] 
    LD    C,(IX+$00)                ;[198A] Save syntax checking
    PUSH  IX                        ;[198D] 
    PUSH  BC                        ;[198F] 
    LD    (HL),$7C                  ;[1990] 
    INC   HL                        ;[1992] 
    CALL  READ_STRING_EXPR          ;[1993] 
    RST   $10                       ;[1996] 
    CP    $3D                       ;[1997] 
    JR    Z,NPSTR1                  ;[1999] 
    CP    $3E                       ;[199B] 
    CALL  NZ,ERR_SOMETHG_MISSG      ;[199D] 
NPSTR1:
    LD    (HL),A                    ;[19A0] 
    INC   HL                        ;[19A1] 
    INC   DE                        ;[19A2] 
    CALL  READ_STRING_EXPR          ;[19A3] 
    LD    (HL),$7B                  ;[19A6] 
    INC   HL                        ;[19A8] 
    POP   BC                        ;[19A9] 
    POP   IX                        ;[19AA] 
    LD    (IX+$02),B                ;[19AC] 
    LD    (IX+$00),C                ;[19AF] 
    LD    (IX+$01),$01              ;[19B2] 
    INC   (IX+$02)                  ;[19B6] 
    LD    A,$01                     ;[19B9] 
    JP    NP2                       ;[19BB] 

;
; Convert normal format to reverse polish
; DE points to normal, HL points to polish
;
NTPS:
    XOR   A                         ;[19BE] 
    PUSH  AF                        ;[19BF] 
    LD    IX,SYSVAR_SYNL            ;[19C0] 
    LD    (IX+$00),$04              ;[19C4] 
    LD    (IX+$01),$04              ;[19C8] 
    LD    (IX+$02),$FF              ;[19CC] 
NP1:
    XOR   A                         ;[19D0] 
NP2:
    LD    (SYSVAR_NPM),A            ;[19D1] 
    CALL  SYNTAX                    ;[19D4] 
    RST   $10                       ;[19D7] 
    CALL  TEST_FOR_STR_EXP          ;[19D8] 
    JR    Z,NPSTR                   ;[19DB] 
    LD    A,(DE)                    ;[19DD] 
    CP    '-'                       ;[19DE] 
    JP    Z,NOS                     ;[19E0] 
    CP    '('                       ;[19E3] 
    JP    Z,NP3                     ;[19E5] 
    CP    ')'                       ;[19E8] 
    JP    Z,NP4                     ;[19EA] 
    CALL  TKSL                      ;[19ED] 
    JP    NC,NP5                    ;[19F0] 
    CALL  TEST_ALPHA                ;[19F3] 
    JP    NC,NP6                    ;[19F6] 
    CALL  TEST_DIGIT                ;[19F9] 
    JP    NC,NP7                    ;[19FC] 
    CP    '&'                       ;[19FF] 
    JP    Z,NP7H                    ;[1A01] 
    CP    '.'                       ;[1A04] 
    JP    Z,NP7                     ;[1A06] 
    LD    (IX+$01),$08              ;[1A09] 
    CALL  SYNTAX                    ;[1A0D] 
    POP   AF                        ;[1A10] 
    OR    A                         ;[1A11] 
    JR    Z,$1A20                   ;[1A12] 
    CP    $28                       ;[1A14] 
    CALL  Z,ERR_MISSING_BRACKET     ;[1A16] 
    LD    (HL),A                    ;[1A19] 
    INC   HL                        ;[1A1A] 
    CALL  DSC                       ;[1A1B] 
    JR    $1A10                     ;[1A1E] 
    LD    (HL),$7F                  ;[1A20] 
    INC   HL                        ;[1A22] 
    XOR   A                         ;[1A23] 
    OR    (IX+$02)                  ;[1A24] 
    CALL  NZ,ERR_SOMETHG_MISSG      ;[1A27] 
    RET                             ;[1A2A] 

NP5:
    LD    (SYSVAR_NPM),A            ;[1A2B] 
    CP    $C0                       ;[1A2E] 
    JP    Z,NOS1                    ;[1A30] 
    CP    $D7                       ;[1A33] 
    JR    NC,$1A09                  ;[1A35] 
    CP    $BF                       ;[1A37] 
    JP    NC,NP10                   ;[1A39] 
    LD    (HL),A                    ;[1A3C] 
    INC   HL                        ;[1A3D] 
    INC   (IX+$02)                  ;[1A3E] 
    LD    B,$C3                     ;[1A41] 
    LD    C,$03                     ;[1A43] 
    CP    $9B                       ;[1A45] 
    JR    NC,$1A89                  ;[1A47] 
    LD    B,$C2                     ;[1A49] 
    INC   (IX+$02)                  ;[1A4B] 
    LD    (IX+$03),$00              ;[1A4E] 
    CP    $85                       ;[1A52] 
    JR    Z,$1A5E                   ;[1A54] 
    CP    $87                       ;[1A56] 
    JR    Z,$1A5E                   ;[1A58] 
    CP    $86                       ;[1A5A] 
    JR    NZ,$1A87                  ;[1A5C] 
    PUSH  BC                        ;[1A5E] 
    CALL  TEST_FOR_STR_EXP          ;[1A5F] 
    CALL  NZ,ERR_TYPE_MISMATCH      ;[1A62] 
    LD    (HL),$79                  ;[1A65] 
    INC   HL                        ;[1A67] 
    PUSH  IX                        ;[1A68] 
    LD    B,(IX+$02)                ;[1A6A] 
    LD    C,(IX+$00)                ;[1A6D] 
    PUSH  BC                        ;[1A70] 
    CALL  READ_STRING_EXPR          ;[1A71] 
    POP   BC                        ;[1A74] 
    POP   IX                        ;[1A75] 
    LD    (IX+$00),C                ;[1A77] 
    LD    (IX+$02),B                ;[1A7A] 
    RST   $10                       ;[1A7D] 
    RST   $20                       ;[1A7E] 
    ADD   HL,HL                     ;[1A7F] 
    LD    (HL),A                    ;[1A80] 
    INC   HL                        ;[1A81] 
    INC   DE                        ;[1A82] 
    LD    (HL),$7B                  ;[1A83] 
    INC   HL                        ;[1A85] 
    POP   BC                        ;[1A86] 
    LD    C,$02                     ;[1A87] 
    LD    (IX+$01),C                ;[1A89] 
    JP    NP103                     ;[1A8C] 
NP3:
    PUSH  AF                        ;[1A8F] 
    INC   DE                        ;[1A90] 
    LD    A,(SYSVAR_SYNL)           ;[1A91] 
    CP    $01                       ;[1A94] 
    JR    NZ,NP31                   ;[1A96] 
    POP   BC                        ;[1A98] 
    LD    A,$C4                     ;[1A99] 
    PUSH  AF                        ;[1A9B] 
    PUSH  BC                        ;[1A9C] 
    DEC   HL                        ;[1A9D] 
    SET   6,(HL)                    ;[1A9E] 
    INC   HL                        ;[1AA0] 
NP31:
    LD    (IX+$01),$04              ;[1AA1] 
    JP    NP1                       ;[1AA5] 
NP4:
    POP   AF                        ;[1AA8] 
    CP    $28                       ;[1AA9] 
    JR    Z,$1AB8                   ;[1AAB] 
    OR    A                         ;[1AAD] 
    JP    Z,$1A20                   ;[1AAE] 
    LD    (HL),A                    ;[1AB1] 
    INC   HL                        ;[1AB2] 
    CALL  DSC                       ;[1AB3] 
    JR    NP4                       ;[1AB6] 
    LD    A,$BF                     ;[1AB8] 
    INC   DE                        ;[1ABA] 
    LD    (HL),A                    ;[1ABB] 
    INC   HL                        ;[1ABC] 
    LD    (IX+$01),$05              ;[1ABD] 
    JP    NP2                       ;[1AC1] 
NP6:
    CALL  TEST_UPPER_LOW            ;[1AC4] A:=token of letter
    LD    (HL),A                    ;[1AC7] Store it
    INC   HL                        ;[1AC8] Increment pointers
    INC   DE                        ;[1AC9] 
    LD    (IX+$01),$01              ;[1ACA] Variable in syntax table
    INC   (IX+$02)                  ;[1ACE] Increment syntax counter
    JP    NP2                       ;[1AD1] 
NP7H:
    LD    (HL),HNUM                 ;[1AD4] 
    JR    NP71                      ;[1AD6] 
NP7:
    LD    (HL),NUM                  ;[1AD8] Number marker
NP71:
    INC   HL                        ;[1ADA] 
    PUSH  HL                        ;[1ADB] 
    CALL  RDN                       ;[1ADC] Read number
    POP   HL                        ;[1ADF] Get pointer
    PUSH  DE                        ;[1AE0] Save pointer
    EX    DE,HL                     ;[1AE1] DE to polish line
    LD    HL,SYSVAR_WRA1            ;[1AE2] HL to work area
    LD    BC,$0005                  ;[1AE5] 
    LDIR                            ;[1AE8] Move number
    EX    DE,HL                     ;[1AEA] Swap back
    POP   DE                        ;[1AEB] Get input line pointer
    LD    A,$02                     ;[1AEC] Number in syntax table
    LD    (SYSVAR_SYNP),A           ;[1AEE] 
    INC   (IX+$02)                  ;[1AF1] Increment syntax counter
    JP    NP2                       ;[1AF4] Next
NOS:
    LD    A,(SYSVAR_NPM)            ;[1AF7] Negate or subtract
    OR    A                         ;[1AFA] Test for zero
    LD    A,SUBT                    ;[1AFB] A:=SUBT token
    INC   DE                        ;[1AFD] Increment pointer
    JR    NZ,NP10                   ;[1AFE] Jump to +/- routine
    LD    A,NEGATE                  ;[1B00] A:=NEGATE token
NOS1:
    PUSH  AF                        ;[1B02] Store on stack
    LD    (IX+$01),$06              ;[1B03] NEG in syntax table
    JP    NP1                       ;[1B07] NEG could follow

;
; Normal to polish.
;
NP10:
    LD    B,A                       ;[1B0A] 
    LD    (IX+$01),$07              ;[1B0B] Store type in syntax table
NP103:
    POP   AF                        ;[1B0F] Get last op.
    OR    A                         ;[1B10] See if top of stack
    JR    Z,NP101                   ;[1B11] Jump if top
    CP    '('                       ;[1B13] If bracket
    JR    Z,NP101                   ;[1B15] Jump
    LD    C,A                       ;[1B17] Save popped op. in C
    CALL  PRIORITY                  ;[1B18] Test priority
    LD    A,C                       ;[1B1B] Unsave
    JR    C,NP101                   ;[1B1C] Priority(A)<Priority(B)
    LD    (HL),A                    ;[1B1E] Store op
    INC   HL                        ;[1B1F] Increment pointer
    CALL  DSC                       ;[1B20] Decrement syntax counter if necessary
    JR    NP103                     ;[1B23] Next off stack
NP101:
    PUSH  AF                        ;[1B25] Put back on stack
    PUSH  BC                        ;[1B26] Put op. on stack
    LD    A,(IX+$03)                ;[1B27] A:=(NPM)
    OR    A                         ;[1B2A] 
    JP    NZ,NP1                    ;[1B2B] 
    INC   A                         ;[1B2E] A now <>0
    JP    NP2                       ;[1B2F] 

;
; Decrement syntax counter
;
DSC:
    CP    $C1                       ;[1B32] 
    RET   Z                         ;[1B34] 
    CP    $BF                       ;[1B35] 
    RET   Z                         ;[1B37] 
    CP    $C0                       ;[1B38] 
    RET   Z                         ;[1B3A] 
    DEC   (IX+$02)                  ;[1B3B] Decrement counter
    CALL  M,ERR_SOMETHG_MISSG       ;[1B3E] Missing operator/operand
    RET                             ;[1B41] 

;
; Get priority
;
PRIORITY:
    PUSH  HL                        ;[1B42] 
    PUSH  DE                        ;[1B43] 
    LD    DE,PTBL-PARENS            ;[1B44] Priority table
    LD    H,$00                     ;[1B47] Add token
    LD    L,C                       ;[1B49] 
    ADD   HL,DE                     ;[1B4A] 
    LD    A,(HL)                    ;[1B4B] get priority
    LD    H,$00                     ;[1B4C] 
    LD    L,B                       ;[1B4E] 
    ADD   HL,DE                     ;[1B4F] 
    CP    (HL)                      ;[1B50] 
    POP   DE                        ;[1B51] 
    POP   HL                        ;[1B52] 
    RET                             ;[1B53] 

;
; Priority table data
;
PTBL:
    DB    0,6,14,20,18,22           ;[1B54] 
    DB    16,12,12,10,10            ;[1B5A] 
    DB    8,8,8,8,8,8               ;[1B5F] 
    DB    2,4                       ;[1B65] 
    DB    2,2,4,12,12,12,12,12,12   ;[1B67] 

;
; Line analysis subroutine.
;
SYNTAX:
    PUSH  HL                        ;[1B70] 
    LD    A,(SYSVAR_SYNL)           ;[1B71] Previous value
    LD    BC,SYNTBL-1               ;[1B74] Get byte from syntax table
    LD    L,A                       ;[1B77] 
    LD    H,$00                     ;[1B78] 
    ADD   HL,BC                     ;[1B7A] 
    LD    A,(SYSVAR_SYNP)           ;[1B7B] Present value
    LD    (SYSVAR_SYNL),A           ;[1B7E] Update last value
    LD    C,$01                     ;[1B81] C := 2**A
SYN1:
    DEC   A                         ;[1B83] 
    JR    Z,SYN2                    ;[1B84] 
    SLA   C                         ;[1B86] 
    JR    SYN1                      ;[1B88] 
SYN2:
    LD    A,C                       ;[1B8A] 
    AND   (HL)                      ;[1B8B] 
    CALL  Z,ERR_SYNTAX              ;[1B8C] Syntax error
    POP   HL                        ;[1B8F] 
    RET                             ;[1B90] 

;
; This looks like data: No idea
;
SYNTBL:
    DB    %11011000                 ;[1B91] 
    DB    %11010000                 ;[1B92] 
    DB    %00001000                 ;[1B93] 
    DB    %00101111                 ;[1B94] 
    DB    %11010000                 ;[1B95] 
    DB    %00001111                 ;[1B96] 
    DB    %00101111                 ;[1B97] 

;
; Reads number pointed to by DE into WRA1 as floating point. (Asc l) 
;
RDN:
    LD    A,(DE)                    ;[1B98] 
    CP    $45                       ;[1B99] 
    JR    Z,$1BC6                   ;[1B9B] 
    CP    $26                       ;[1B9D] 
    JR    NZ,$1BCC                  ;[1B9F] 
    LD    HL,$0000                  ;[1BA1] 
    INC   DE                        ;[1BA4] 
    LD    A,(DE)                    ;[1BA5] 
    SUB   $30                       ;[1BA6] 
    JR    C,$1BC0                   ;[1BA8] 
    CP    $0A                       ;[1BAA] 
    JR    C,$1BB8                   ;[1BAC] 
    SUB   $07                       ;[1BAE] 
    CP    $0A                       ;[1BB0] 
    JR    C,$1BC0                   ;[1BB2] 
    CP    $10                       ;[1BB4] 
    JR    NC,$1BC0                  ;[1BB6] 
    ADD   HL,HL                     ;[1BB8] 
    ADD   HL,HL                     ;[1BB9] 
    ADD   HL,HL                     ;[1BBA] 
    ADD   HL,HL                     ;[1BBB] 
    ADD   A,L                       ;[1BBC] 
    LD    L,A                       ;[1BBD] 
    JR    $1BA4                     ;[1BBE] 
    PUSH  DE                        ;[1BC0] 
    CALL  INTFP                     ;[1BC1] 
    POP   DE                        ;[1BC4] 
    RET                             ;[1BC5] 

    PUSH  DE                        ;[1BC6] 
    CALL  LZERO                     ;[1BC7] 
    POP   DE                        ;[1BCA] 
    RET                             ;[1BCB] 

    LD    C,$C0                     ;[1BCC] 
    CALL  ZWRA1                     ;[1BCE] 
    LD    A,(DE)                    ;[1BD1] 
    CP    $2D                       ;[1BD2] 
    EX    AF,AF'                    ;[1BD4] 
    LD    A,(DE)                    ;[1BD5] 
    CP    $2D                       ;[1BD6] 
    JR    NZ,$1BDD                  ;[1BD8] 
    RES   7,C                       ;[1BDA] 
    INC   DE                        ;[1BDC] 
    LD    A,(DE)                    ;[1BDD] 
    CP    $30                       ;[1BDE] 
    JR    Z,$1BDC                   ;[1BE0] 
    CP    $2E                       ;[1BE2] 
    JR    Z,$1C3D                   ;[1BE4] 
    SUB   $30                       ;[1BE6] 
    CP    $0A                       ;[1BE8] 
    JR    NC,$1C17                  ;[1BEA] 
    LD    B,$08                     ;[1BEC] 
    DEC   C                         ;[1BEE] 
    LD    A,(DE)                    ;[1BEF] 
    CP    $2E                       ;[1BF0] 
    JR    Z,$1C47                   ;[1BF2] 
    SUB   $30                       ;[1BF4] 
    CP    $0A                       ;[1BF6] 
    JR    NC,$1C12                  ;[1BF8] 
    INC   C                         ;[1BFA] 
    CALL  RL1A                      ;[1BFB] 
    INC   DE                        ;[1BFE] 
    DJNZ  $1BEF                     ;[1BFF] 
    DEC   DE                        ;[1C01] 
    DEC   C                         ;[1C02] 
    LD    A,(DE)                    ;[1C03] 
    CP    $2E                       ;[1C04] 
    JR    Z,$1C54                   ;[1C06] 
    SUB   $30                       ;[1C08] 
    CP    $0A                       ;[1C0A] 
    JR    NC,$1C17                  ;[1C0C] 
    INC   DE                        ;[1C0E] 
    INC   C                         ;[1C0F] 
    JR    $1C03                     ;[1C10] 
    CALL  RL10                      ;[1C12] 
    DJNZ  $1C12                     ;[1C15] 
    LD    A,(SYSVAR_WRA1)           ;[1C17] 
    OR    C                         ;[1C1A] 
    PUSH  AF                        ;[1C1B] 
    CALL  $1C5E                     ;[1C1C] 
    POP   AF                        ;[1C1F] 
    ADD   A,L                       ;[1C20] 
    BIT   7,A                       ;[1C21] 
    JR    Z,$1C2B                   ;[1C23] 
    EX    AF,AF'                    ;[1C25] 
    CALL  Z,ERR_OVERFLOW            ;[1C26] 
    JR    $1C2F                     ;[1C29] 
    EX    AF,AF'                    ;[1C2B] 
    CALL  NZ,ERR_OVERFLOW           ;[1C2C] 
    EX    AF,AF'                    ;[1C2F] 
    LD    (SYSVAR_WRA1),A           ;[1C30] 
    LD    A,(SYSVAR_WRA1+$01)       ;[1C33] 
    OR    A                         ;[1C36] 
    PUSH  DE                        ;[1C37] 
    CALL  Z,LZERO                   ;[1C38] 
    POP   DE                        ;[1C3B] 
    RET                             ;[1C3C] 

    INC   DE                        ;[1C3D] Number analysis.
    LD    A,(DE)                    ;[1C3E] 
    DEC   C                         ;[1C3F] 
    CP    $30                       ;[1C40] 
    JR    Z,$1C3D                   ;[1C42] 
    LD    B,$08                     ;[1C44] 
    DEC   DE                        ;[1C46] 
    INC   DE                        ;[1C47] 
    LD    A,(DE)                    ;[1C48] 
    SUB   $30                       ;[1C49] 
    CP    $0A                       ;[1C4B] 
    JR    NC,$1C12                  ;[1C4D] 
    CALL  RL1A                      ;[1C4F] 
    DJNZ  $1C47                     ;[1C52] 
    INC   DE                        ;[1C54] 
    LD    A,(DE)                    ;[1C55] 
    SUB   $30                       ;[1C56] 
    CP    $0A                       ;[1C58] 
    JR    C,$1C54                   ;[1C5A] 
    JR    $1C17                     ;[1C5C] 
    LD    L,$00                     ;[1C5E] 
    LD    A,(DE)                    ;[1C60] 
    CP    $45                       ;[1C61] 
    RET   NZ                        ;[1C63] 
    INC   DE                        ;[1C64] 
    LD    A,(DE)                    ;[1C65] 
    CP    $2D                       ;[1C66] 
    JR    Z,$1C91                   ;[1C68] 
    CP    $2B                       ;[1C6A] 
    INC   DE                        ;[1C6C] 
    JR    Z,$1C77                   ;[1C6D] 
    DEC   DE                        ;[1C6F] 
    CALL  TEST_DIGIT                ;[1C70] 
    JR    NC,$1C77                  ;[1C73] 
    DEC   DE                        ;[1C75] 
    RET                             ;[1C76] 

    LD    A,(DE)                    ;[1C77] 
    SUB   $30                       ;[1C78] 
    CP    $0A                       ;[1C7A] 
    RET   NC                        ;[1C7C] 
    LD    L,A                       ;[1C7D] 
    INC   DE                        ;[1C7E] 
    LD    A,(DE)                    ;[1C7F] 
    SUB   $30                       ;[1C80] 
    CP    $0A                       ;[1C82] 
    RET   NC                        ;[1C84] 
    PUSH  AF                        ;[1C85] 
    LD    A,L                       ;[1C86] 
    RLCA                            ;[1C87] 
    RLCA                            ;[1C88] 
    ADD   A,L                       ;[1C89] 
    RLCA                            ;[1C8A] 
    LD    L,A                       ;[1C8B] 
    POP   AF                        ;[1C8C] 
    ADD   A,L                       ;[1C8D] 
    LD    L,A                       ;[1C8E] 
    INC   DE                        ;[1C8F] 
    RET                             ;[1C90] 

    INC   DE                        ;[1C91] 
    CALL  $1C77                     ;[1C92] 
    LD    A,L                       ;[1C95] 
    NEG                             ;[1C96] 
    LD    L,A                       ;[1C98] 
    RET                             ;[1C99] 

;
; Displays binary number in HL without leading zeros. 
;
PHL:
    PUSH  IY                        ;[1C9A] 
    CALL  $1CA2                     ;[1C9C] 
    POP   IY                        ;[1C9F] 
    RET                             ;[1CA1] 

    LD    IY,$1CCC                  ;[1CA2] 
    LD    D,$00                     ;[1CA6] 
    XOR   A                         ;[1CA8] 
    LD    B,(IY+$01)                ;[1CA9] 
    LD    C,(IY+$00)                ;[1CAC] 
    OR    A                         ;[1CAF] 
    SBC   HL,BC                     ;[1CB0] 
    JR    C,$1CB7                   ;[1CB2] 
    INC   A                         ;[1CB4] 
    JR    $1CB0                     ;[1CB5] 
    ADD   HL,BC                     ;[1CB7] 
    OR    A                         ;[1CB8] 
    JR    Z,$1CBC                   ;[1CB9] 
    DEC   D                         ;[1CBB] 
    BIT   7,D                       ;[1CBC] 
    JR    Z,$1CC3                   ;[1CBE] 
    ADD   A,$30                     ;[1CC0] 
    RST   $08                       ;[1CC2] 
    BIT   0,C                       ;[1CC3] 
    RET   NZ                        ;[1CC5] 
    INC   IY                        ;[1CC6] 
    INC   IY                        ;[1CC8] 
    JR    $1CA8                     ;[1CCA] 
    DJNZ  $1CF5                     ;[1CCC] 
    RET   PE                        ;[1CCE] 
    INC   BC                        ;[1CCF] 
    LD    H,H                       ;[1CD0] 
    NOP                             ;[1CD1] 
    LD    A,(BC)                    ;[1CD2] 
    NOP                             ;[1CD3] 
    LD    BC,$CD00                  ;[1CD4] 
    JP    PO,$2B1C                  ;[1CD7] 
    CALL  $1CEE                     ;[1CDA] 
    CP    $2E                       ;[1CDD] 
    RET   Z                         ;[1CDF] 
    INC   HL                        ;[1CE0] 
    RET                             ;[1CE1] 

    CALL  RL1A                      ;[1CE2] 
    AND   $0F                       ;[1CE5] 
    ADD   A,$30                     ;[1CE7] 
    LD    (HL),A                    ;[1CE9] 
    INC   HL                        ;[1CEA] 
    DJNZ  $1CE2                     ;[1CEB] 
    RET                             ;[1CED] 

    PUSH  BC                        ;[1CEE] 
    LD    B,$08                     ;[1CEF] 
    LD    A,(SYSVAR_ZFLAG)          ;[1CF1] 
    BIT   1,A                       ;[1CF4] 
    JR    Z,$1CFE                   ;[1CF6] 
    LD    B,$03                     ;[1CF8] 
    BIT   0,A                       ;[1CFA] 
    JR    Z,$1D01                   ;[1CFC] 
    CALL  $1D05                     ;[1CFE] 
    POP   BC                        ;[1D01] 
    LD    A,(HL)                    ;[1D02] 
    RET                             ;[1D03] 

    DEC   HL                        ;[1D04] 
    LD    A,(HL)                    ;[1D05] 
    CP    $30                       ;[1D06] 
    RET   NZ                        ;[1D08] 
    DJNZ  $1D04                     ;[1D09] 
    RET                             ;[1D0B] 

    LD    B,$01                     ;[1D0C] 
    CALL  $1CE2                     ;[1D0E] 
    LD    (HL),$2E                  ;[1D11] 
    INC   HL                        ;[1D13] 
    LD    B,$07                     ;[1D14] 
    CALL  $1CD6                     ;[1D16] 
    LD    (HL),$45                  ;[1D19] 
    INC   HL                        ;[1D1B] 
    LD    (HL),$00                  ;[1D1C] 
    LD    HL,SYSVAR_PRTBUF          ;[1D1E] 
    CALL  PLINE                     ;[1D21] 
    LD    HL,SYSVAR_WRA1            ;[1D24] 
    BIT   6,(HL)                    ;[1D27] 
    LD    A,$2D                     ;[1D29] 
    JR    Z,$1D2F                   ;[1D2B] 
    LD    A,$2B                     ;[1D2D] 
    RST   $08                       ;[1D2F] 
    LD    A,(HL)                    ;[1D30] 
    JR    NZ,$1D35                  ;[1D31] 
    NEG                             ;[1D33] 
    AND   $3F                       ;[1D35] 
    LD    L,A                       ;[1D37] 
    LD    H,$00                     ;[1D38] 
    JP    PHL                       ;[1D3A] 
    LD    A,$30                     ;[1D3D] 
    RST   $08                       ;[1D3F] 
    LD    A,(SYSVAR_ZFLAG)          ;[1D40] 
    BIT   1,A                       ;[1D43] 
    RET   Z                         ;[1D45] 
    PUSH  AF                        ;[1D46] 
    LD    A,$2E                     ;[1D47] 
    RST   $08                       ;[1D49] 
    POP   AF                        ;[1D4A] 
    LD    B,$07                     ;[1D4B] 
    BIT   0,A                       ;[1D4D] 
    JR    Z,$1D53                   ;[1D4F] 
    LD    B,$05                     ;[1D51] 
    LD    A,$30                     ;[1D53] 
    RST   $08                       ;[1D55] 
    DJNZ  $1D53                     ;[1D56] 
    RET                             ;[1D58] 

;
; Displays number in WRA1. 
;
PN:
    CALL  ROUND                     ;[1D59] 
    LD    A,(SYSVAR_WRA1)           ;[1D5C] 
    LD    HL,SYSVAR_PRTBUF          ;[1D5F] 
    BIT   7,A                       ;[1D62] 
    JR    NZ,$1D69                  ;[1D64] 
    LD    (HL),$2D                  ;[1D66] 
    INC   HL                        ;[1D68] 
    AND   $7F                       ;[1D69] 
    JR    Z,$1D3D                   ;[1D6B] 
    SUB   $3E                       ;[1D6D] 
    CP    $0A                       ;[1D6F] 
    JR    NC,$1D0C                  ;[1D71] 
    CP    $02                       ;[1D73] 
    JR    C,$1DA1                   ;[1D75] 
    LD    A,(SYSVAR_WRA1)           ;[1D77] 
    AND   $0F                       ;[1D7A] 
    INC   A                         ;[1D7C] 
    LD    B,A                       ;[1D7D] 
    PUSH  AF                        ;[1D7E] 
    CALL  $1CE2                     ;[1D7F] 
    POP   AF                        ;[1D82] 
    SUB   $08                       ;[1D83] 
    NEG                             ;[1D85] 
    LD    (HL),$2E                  ;[1D87] 
    JR    Z,$1D91                   ;[1D89] 
    LD    B,A                       ;[1D8B] 
    INC   HL                        ;[1D8C] 
    CALL  $1CE2                     ;[1D8D] 
    DEC   HL                        ;[1D90] 
    CALL  $1CEE                     ;[1D91] 
    CP    $2E                       ;[1D94] 
    JR    Z,$1D99                   ;[1D96] 
    INC   HL                        ;[1D98] 
    LD    (HL),$00                  ;[1D99] 
    LD    HL,SYSVAR_PRTBUF          ;[1D9B] 
    JP    PLINE                     ;[1D9E] 
    LD    (HL),$30                  ;[1DA1] 
    INC   HL                        ;[1DA3] 
    LD    (HL),$2E                  ;[1DA4] 
    INC   HL                        ;[1DA6] 
    SUB   $01                       ;[1DA7] 
    JR    Z,$1DB1                   ;[1DA9] 
    LD    (HL),$30                  ;[1DAB] 
    INC   HL                        ;[1DAD] 
    INC   A                         ;[1DAE] 
    JR    NZ,$1DAB                  ;[1DAF] 
    LD    B,$08                     ;[1DB1] 
    CALL  $1CD6                     ;[1DB3] 
    JR    $1D99                     ;[1DB6] 

;
; Find array element given subscript in HL and 
; entry in array table pointed to by IX
;
FIND_ARRAY:
    PUSH  HL                        ;[1DB8] 
    LD    C,(IX+$02)                ;[1DB9] 
    LD    B,(IX+$03)                ;[1DBC] 
    OR    A                         ;[1DBF] 
    LD    A,L                       ;[1DC0] 
    OR    H                         ;[1DC1] 
    JR    Z,FNDAR1                  ;[1DC2] 
    DEC   HL                        ;[1DC4] 
    SBC   HL,BC                     ;[1DC5] 
    CALL  NC,ERR_SUBS_OUT_RANGE     ;[1DC7] 
FNDAR1:
    POP   HL                        ;[1DCA] 
    LD    C,L                       ;[1DCB] 
    LD    B,H                       ;[1DCC] 
    ADD   HL,HL                     ;[1DCD] 
    ADD   HL,HL                     ;[1DCE] 
    ADD   HL,BC                     ;[1DCF] 
    LD    C,(IX+$00)                ;[1DD0] 
    LD    B,(IX+$01)                ;[1DD3] 
    ADD   HL,BC                     ;[1DD6] 
    RET                             ;[1DD7] 

;
; Find array subroutine
;
FARR:
    PUSH  DE                        ;[1DD8] 
    CALL  CSW1                      ;[1DD9] 
    DEC   IY                        ;[1DDC] 
    LD    A,(IY+$00)                ;[1DDE] 
    CALL  ARLOC2                    ;[1DE1] 
    LD    A,(IX+$00)                ;[1DE4] 
    OR    (IX+$01)                  ;[1DE7] 
    CALL  Z,ERR_UNDEFINED_VAR       ;[1DEA] 
    CALL  FPINT                     ;[1DED] 
    CALL  FIND_ARRAY                ;[1DF0] 
    INC   HL                        ;[1DF3] 
    LD    A,(HL)                    ;[1DF4] 
    INC   A                         ;[1DF5] 
    CALL  Z,ERR_UNDEFINED_VAR       ;[1DF6] 
    DEC   HL                        ;[1DF9] 
    CALL  LNUM1                     ;[1DFA] 
    POP   DE                        ;[1DFD] 
    RET                             ;[1DFE] 

;
; Variable pointer array
;
VPTA:
    POP   AF                        ;[1DFF] 
    CALL  ARLOC1                    ;[1E00] 
    LD    A,(IX+$00)                ;[1E03] 
    OR    (IX+$01)                  ;[1E06] 
    CALL  Z,ERR_UNDEFINED_VAR       ;[1E09] 
    JP    FIND_ARRAY                ;[1E0C] 

;
; Array locate. IX point to entry in array table.
; HL has value of subscript. DE points to first byte after variable.
;
ARRAY_LOCATE:
    CALL  TEST_UPPER_LOW            ;[1E0F] 
    INC   DE                        ;[1E12] 
ARLOC1:
    PUSH  AF                        ;[1E13] 
    INC   DE                        ;[1E14] 
    RST   $28                       ;[1E15] 
    LD    A,(DE)                    ;[1E16] 
    CP    ')'                       ;[1E17] 
    CALL  NZ,ERR_MISSING_BRACKET    ;[1E19] 
    INC   DE                        ;[1E1C] 
    PUSH  DE                        ;[1E1D] 
    CALL  FPINT                     ;[1E1E] 
    POP   DE                        ;[1E21] 
    POP   AF                        ;[1E22] 
ARLOC2:
    LD    IX,(SYSVAR_ATBL)          ;[1E23] 
    RLCA                            ;[1E27] 
    RLA                             ;[1E28] 
    LD    C,A                       ;[1E29] 
    LD    B,$00                     ;[1E2A] 
    ADD   IX,BC                     ;[1E2C] 
    RET                             ;[1E2E] 

;
; Handle stopping BASIC program; set continue line;  display "Stopped" message.
;
BASIC_COM_STOP:
    LD    IX,(SYSVAR_CURRLP)        ;[1E2F] 
    LD    A,(IX+$00)                ;[1E33] 
    CP    $80                       ;[1E36] 
    CALL  Z,ERR_WRONG_MODE          ;[1E38] 
    CALL  NEXT_LINE                 ;[1E3B] 
BASIC_COM_STOP1:
    LD    (SYSVAR_CONTLP),IX        ;[1E3E] 
    LD    HL,DATA_STOPPED           ;[1E42] 
    CALL  PLINE                     ;[1E45] 
    CALL  SUB_JUMP_TO_CMDLINE1      ;[1E48] 
    JP    TO_CMDLINE                ;[1E4B] 

;
; Data 'Stopped' message.
;
DATA_STOPPED:
    DB $0D,$53,$74,$6F,$70,$70,$65,$64      ;[1E4E]  .Stopped
    DB $00                                  ;[1E56]  .

;
; RND.
;
BASIC_FN_RND:
    CALL  FRNDS                     ;[1E57] 
    LD    HL,(SYSVAR_RNDNO)         ;[1E5A] 
    CALL  INTFP                     ;[1E5D] 
    LD    HL,FLOAT_16B              ;[1E60] 
    CALL  LNUM2                     ;[1E63] 
    JP    DIV                       ;[1E66] 

;
; MEM.
;
BASIC_FN_MEM:
    LD    BC,(SYSVAR_TOV)           ;[1E69] 
    LD    HL,$0000                  ;[1E6D] 
    ADD   HL,SP                     ;[1E70] 
    SBC   HL,BC                     ;[1E71] 
    JP    INTFP                     ;[1E73] 

;
; Called by 'J' command.
;
SUB_JUMP_TO_CMDLINE:
    LD    HL,FLOAT_ZERO             ;[1E76] 
    LD    (SYSVAR_CURRLP),HL        ;[1E79] 
    JP    SUB_LINK_OFF              ;[1E7C] 
SUB_JUMP_TO_CMDLINE1:
    LD    HL,(SYSVAR_CURRLP)        ;[1E7F] 
    LD    A,(HL)                    ;[1E82] 
    CP    $80                       ;[1E83] 
    JR    Z,SUB_JUMP_TO_CMDLINE2    ;[1E85] 
    LD    HL,DATA_IN_LINE           ;[1E87] 
    CALL  PLINE                     ;[1E8A] 
    LD    HL,(SYSVAR_CURRLP)        ;[1E8D] 
    CALL  LNUM1                     ;[1E90] 
    CALL  PN                        ;[1E93] 
SUB_JUMP_TO_CMDLINE2:
    LD    A,$1E                     ;[1E96] 
    RST   $08                       ;[1E98] 
    LD    A,$0D                     ;[1E99] 
    RST   $08                       ;[1E9B] 
    JP    READY_MSG                 ;[1E9C] 

;
; String 'in line'. Used to display msg "Stopped in line [nnnn]", etc.
;
DATA_IN_LINE:
    DB $20,$69,$6E,$20,$6C,$69,$6E,$65      ;[1E9F]  .in.line
    DB $20,$00                              ;[1EA7]  ..

;
; Main process loop for BASIC
;
BASIC:
    LD    IX,(SYSVAR_CURRLP)        ;[1EA9] 
    LD    A,(IX+$00)                ;[1EAD] 
    CP    $80                       ;[1EB0] 
    JR    Z,$1ECA                   ;[1EB2] 
    LD    A,(IX+$06)                ;[1EB4] 
    CP    $25                       ;[1EB7] 
    JR    NZ,$1ECA                  ;[1EB9] 
    LD    A,$0D                     ;[1EBB] 
    RST   $08                       ;[1EBD] 
    LD    BC,EXEC_LINE_RETURN       ;[1EBE] 
    POP   HL                        ;[1EC1] 
    OR    A                         ;[1EC2] 
    SBC   HL,BC                     ;[1EC3] 
    JR    NZ,$1EC1                  ;[1EC5] 
    JP    EXEC_LINE_LOOP            ;[1EC7] 
    CALL  SUB_JUMP_TO_CMDLINE1      ;[1ECA] 
    JP    JUMP_TO_CMDLINE           ;[1ECD] 

;
; Generates next random number in RNDNO. 
;
FRNDS:
    LD    HL,($61F2)                ;[1ED0] 
    RL    L                         ;[1ED3] 
    RL    H                         ;[1ED5] 
    RL    L                         ;[1ED7] 
    RL    H                         ;[1ED9] 
    LD    C,H                       ;[1EDB] 
    LD    A,(SYSVAR_RNDNO)          ;[1EDC] 
    RLA                             ;[1EDF] 
    LD    B,A                       ;[1EE0] 
    LD    DE,($61F1)                ;[1EE1] 
    RL    E                         ;[1EE5] 
    RL    D                         ;[1EE7] 
    RES   7,D                       ;[1EE9] 
    LD    HL,(SYSVAR_RNDNO)         ;[1EEB] 
    ADD   HL,BC                     ;[1EEE] 
    LD    (SYSVAR_RNDNO),HL         ;[1EEF] 
    LD    HL,($61F2)                ;[1EF2] 
    ADC   HL,DE                     ;[1EF5] 
    RES   7,H                       ;[1EF7] 
    LD    ($61F2),HL                ;[1EF9] 
    RET   P                         ;[1EFC] 
    LD    HL,SYSVAR_RNDNO           ;[1EFD] 
    INC   (HL)                      ;[1F00] 
    RET   NZ                        ;[1F01] 
    INC   HL                        ;[1F02] 
    JR    $1F00                     ;[1F03] 

;
; Sets Z flag to zero if ESC key is currently pressed (negative logic)
;
ESC:
    LD    BC,PORT                   ;[1F05] 
    IN    B,(C)                     ;[1F08] 
    BIT   6,B                       ;[1F0A] 
    RET                             ;[1F0C] 

;
; Routine to print 'Ready!'.
;
READY_MSG:
    LD    HL,RDYMSG                 ;[1F0D] 
    JP    PLINE                     ;[1F10] 

;
; Data 'Ready!'.
;
RDYMSG:
    DB    "Ready!",NEWLINE,CEL,0    ;[1F13] 

;
; Test for a full return stack
;
TEST_FULL_RSTACK:
    LD    HL,(SYSVAR_RSTACK)        ;[1F1C] 
    LD    DE,$0100                  ;[1F1F] 
    ADD   HL,DE                     ;[1F22] 
    LD    DE,(SYSVAR_RSP)           ;[1F23] 
    CALL  CHLDE                     ;[1F27] 
    CALL  C,ERR_RETURN_STACK_FULL   ;[1F2A] 
    EX    DE,HL                     ;[1F2D] 
    RET                             ;[1F2E] 

;
; Push HL onto the return stack.
;
PUSH_HL_RSTACK:
    PUSH  DE                        ;[1F2F] 
    PUSH  HL                        ;[1F30] 
    CALL  TEST_FULL_RSTACK          ;[1F31] 
    POP   DE                        ;[1F34] 
    LD    (HL),E                    ;[1F35] 
    INC   HL                        ;[1F36] 
    LD    (HL),D                    ;[1F37] 
    INC   HL                        ;[1F38] 
    LD    (SYSVAR_RSP),HL           ;[1F39] 
    POP   DE                        ;[1F3C] 
    RET                             ;[1F3D] 

;
; Push A onto the return stack.
;
PUSH_A_RSTACK:
    PUSH  DE                        ;[1F3E] 
    PUSH  AF                        ;[1F3F] 
    CALL  TEST_FULL_RSTACK          ;[1F40] 
    POP   AF                        ;[1F43] 
    LD    (HL),A                    ;[1F44] 
    JR    $1F38                     ;[1F45] 

;
; Pop HL off the return stack.
;
POP_HL_RSTACK:
    PUSH  DE                        ;[1F47] 
    LD    HL,(SYSVAR_RSP)           ;[1F48] 
    DEC   HL                        ;[1F4B] 
    LD    D,(HL)                    ;[1F4C] 
    DEC   HL                        ;[1F4D] 
    LD    E,(HL)                    ;[1F4E] 
    LD    (SYSVAR_RSP),HL           ;[1F4F] 
    EX    DE,HL                     ;[1F52] 
    POP   DE                        ;[1F53] 
    RET                             ;[1F54] 

;
; Pop A off the return stack.
;
POP_A_RSTACK:
    LD    HL,(SYSVAR_RSP)           ;[1F55] 
    DEC   HL                        ;[1F58] 
    LD    A,(HL)                    ;[1F59] 
    LD    (SYSVAR_RSP),HL           ;[1F5A] 
    RET                             ;[1F5D] 

;
; LLIST subroutine: 'LINK ON'.
;
SUB_LINK_ON:
    LD    C,$02                     ;[1F5E] 
SUB_LINK_SET:
    LD    A,(SYSVAR_OTYPE)          ;[1F60] 
    AND   $80                       ;[1F63] 
    OR    C                         ;[1F65] 
    LD    (SYSVAR_OTYPE),A          ;[1F66] 
    RET                             ;[1F69] 

;
; LLIST subroutine: "LINK OFF".
;
SUB_LINK_OFF:
    LD    C,$01                     ;[1F6A] 
    JR    SUB_LINK_SET              ;[1F6C] 

;
; Called from MAIN routine. Zeros memory, clears varaiables, etc.
;
ZERO_MEM:
    CALL  CLEAR_VARS                ;[1F6E] 
    LD    HL,$0000                  ;[1F71] 
    LD    (SYSVAR_PROCST),HL        ;[1F74] Ptr to first DEFPROC
    LD    HL,(SYSVAR_EOB)           ;[1F77] 
    INC   HL                        ;[1F7A] 
    LD    (SYSVAR_TOV),HL           ;[1F7B] reset "top of variables"
    LD    HL,(SYSVAR_SOB)           ;[1F7E] 
    DEC   HL                        ;[1F81] 
    LD    (SYSVAR_DATAP),HL         ;[1F82] reset DATA pointer
    LD    HL,(SYSVAR_RSTACK)        ;[1F85] 
    LD    (HL),$00                  ;[1F88] 
    INC   HL                        ;[1F8A] 
    LD    (SYSVAR_RSP),HL           ;[1F8B] Return stack pointer
    LD    HL,(SYSVAR_VTBL)          ;[1F8E] Variable A-Z,a-z table
    LD    DE,$0005                  ;[1F91] 
    LD    B,$35                     ;[1F94] 
    INC   HL                        ;[1F96] 
ZERO_VTBL:
    LD    (HL),$FF                  ;[1F97] 
    ADD   HL,DE                     ;[1F99] 
    DJNZ  ZERO_VTBL                 ;[1F9A] 
    RET                             ;[1F9C] 

;
; LCTN.
;
BASIC_FN_LCTN:
    CALL  FINDLN                    ;[1F9D] 
    CALL  SKIP_LNUM                 ;[1FA0] 
    EX    DE,HL                     ;[1FA3] 
    INC   HL                        ;[1FA4] 
    JP    INTFP                     ;[1FA5] Let WRA1 = HL

;
; RANDOM.
;
BASIC_COM_RANDOM:
    LD    A,R                       ;[1FA8] 
    AND   $7F                       ;[1FAA] 
    INC   A                         ;[1FAC] 
    LD    (SYSVAR_RNDNO),A          ;[1FAD] 
    RET                             ;[1FB0] 

;
; CLS.
;
BASIC_COM_CLS:
    LD    HL,SYSVAR_OTYPE           ;[1FB1] 
    LD    A,(HL)                    ;[1FB4] 
    PUSH  AF                        ;[1FB5] 
    LD    (HL),$01                  ;[1FB6] 
    LD    A,$04                     ;[1FB8] 
    RST   $08                       ;[1FBA] 
    POP   AF                        ;[1FBB] 
    LD    (HL),A                    ;[1FBC] 
    RET                             ;[1FBD] 

;
; END.
;
BASIC_COM_END:
    CALL  READY_MSG                 ;[1FBE] 
    JP    ZERO_CONTLP               ;[1FC1] 

;
; WEND.
;
BASIC_COM_WEND:
    CALL  POP_A_RSTACK              ;[1FC4] 
    CP    $36                       ;[1FC7] 
    CALL  NZ,ERR_WEND_NO_WHILE      ;[1FC9] 
    CALL  POP_HL_RSTACK             ;[1FCC] 
    POP   BC                        ;[1FCF] 
    JP    EXEC_BASIC                ;[1FD0] 

;
; WHILE.
;
BASIC_COM_WHILE:
    RST   $28                       ;[1FD3] 
    LD    A,(SYSVAR_WRA1)           ;[1FD4] 
    CP    $80                       ;[1FD7] 
    JR    Z,DO_WHILE                ;[1FD9] 
    LD    HL,(SYSVAR_CURRLP)        ;[1FDB] 
    CALL  PUSH_HL_RSTACK            ;[1FDE] 
    LD    A,$36                     ;[1FE1] 
    CALL  PUSH_A_RSTACK             ;[1FE3] 
    RET                             ;[1FE6] 

DO_WHILE:
    LD    IX,(SYSVAR_CURRLP)        ;[1FE7] 
    LD    C,$37                     ;[1FEB] 
    LD    B,$36                     ;[1FED] 
    CALL  SUB_WHILE                 ;[1FEF] 
    CALL  C,ERR_WHILE_NO_WEND       ;[1FF2] 
    LD    (SYSVAR_CURRLP),IX        ;[1FF5] 
    RET                             ;[1FF9] 

;
; UNTIL.
;
BASIC_COM_UNTIL:
    PUSH  DE                        ;[1FFA] 
    CALL  POP_A_RSTACK              ;[1FFB] 
    CP    REPEAT                    ;[1FFE] 
EUNT1:
    CALL  NZ,ERR_UNTIL_NO_REPEAT    ;[2000] 
    CALL  POP_HL_RSTACK             ;[2003] 
    POP   DE                        ;[2006] 
    PUSH  HL                        ;[2007] 
    RST   $28                       ;[2008] 
    LD    A,(SYSVAR_WRA1)           ;[2009] 
    CP    $80                       ;[200C] 
    POP   HL                        ;[200E] 
    RET   NZ                        ;[200F] 
    LD    (SYSVAR_CURRLP),HL        ;[2010] 

;
; REPEAT.
;
BASIC_COM_REPEAT:
    LD    HL,(SYSVAR_CURRLP)        ;[2013] 
    CALL  PUSH_HL_RSTACK            ;[2016] 
    LD    A,REPEAT                  ;[2019] 
    JP    PUSH_A_RSTACK             ;[201B] 

;
; GETN.
;
BASIC_FN_GETN:
    CALL  KEY                       ;[201E] 
    OR    A                         ;[2021] 
    JR    Z,BASIC_FN_GETN           ;[2022] 
    JR    FINKY1                    ;[2024] 

;
; KEYN.
;
BASIC_FN_KEYN:
    CALL  KEY                       ;[2026] 
FINKY1:
    LD    L,A                       ;[2029] 
    LD    H,$00                     ;[202A] 
    JP    INTFP                     ;[202C] 

;
; Calls to keyboard driver in KEYB 
;
KEY:
    PUSH  HL                        ;[202F] 
    LD    HL,(SYSVAR_KEYB)          ;[2030] ie. KEYB
    PUSH  BC                        ;[2033] 
    LD    BC,KEY_END                ;[2034] 
    PUSH  BC                        ;[2037] 
    JP    (HL)                      ;[2038] Jump to KEYB
KEY_END:
    POP   BC                        ;[2039] 
    POP   HL                        ;[203A] 
    RET                             ;[203B] 

;
; Display character.
;
SUB_PUTCHAR:
    LD    C,A                       ;[203C] 
    LD    A,(SYSVAR_OTYPE)          ;[203D] Check LINK status
    PUSH  BC                        ;[2040] 
    PUSH  AF                        ;[2041] 
    AND   $81                       ;[2042] 
    JR    Z,SUB_LPUTCHAR            ;[2044] 
    LD    A,C                       ;[2046] 
    LD    HL,(SYSVAR_PRINTD)        ;[2047] 
    LD    BC,SUB_LPUTCHAR           ;[204A] 
    PUSH  BC                        ;[204D] 
    JP    (HL)                      ;[204E] 

;
; Link ON Putchar
;
SUB_LPUTCHAR:
    POP   AF                        ;[204F] 
    POP   BC                        ;[2050] 
    AND   $82                       ;[2051] 
    RET   Z                         ;[2053] 
    LD    A,C                       ;[2054] 
    LD    HL,(SYSVAR_LPRNTD)        ;[2055] 
    JP    (HL)                      ;[2058] 

;
; Check and then evaluate an expression. (AKA N$ESOP)
;
SUB_CHK_EXP_EVAL:
    LD    A,(DE)                    ;[2059] 
    RST   $20                       ;[205A] 
    DB    SOP                       ;[205B] 
    JP    SYSVAR_EE                 ;[205C] 

;
; CALL.
;
BASIC_COM_CALL:
    RST   $18                       ;[205F] 
    PUSH  HL                        ;[2060] 
    LD    A,(DE)                    ;[2061] 
    CP    CR                        ;[2062] 
    JR    Z,ECALL1                  ;[2064] 
    INC   DE                        ;[2066] 
    RST   $18                       ;[2067] 
ECALL1:
    POP   IX                        ;[2068] 
    LD    BC,ECALL2                 ;[206A] 
    PUSH  BC                        ;[206D] 
    JP    (IX)                      ;[206E] 
ECALL2:
    LD    (SYSVAR_HLSTORE),HL       ;[2070] Save the value in HL at 61F4.
    RET                             ;[2073] 

;
; Check for stack full.
;
BASIC_COM_RETURN:
    CALL  POP_A_RSTACK              ;[2074] 
    CP    GOSUB                     ;[2077] 
    CALL  NZ,ERR_RETURN_NO_GOSUB    ;[2079] 
EEPRN1:
    CALL  POP_HL_RSTACK             ;[207C] 
    LD    (SYSVAR_CURRLP),HL        ;[207F] 
    RET                             ;[2082] 

BASIC_COM_NEW:
    LD    HL,(SYSVAR_SOB)           ;[2083] 
    LD    (SYSVAR_EOB),HL           ;[2086] 
    LD    (HL),$80                  ;[2089] 
    LD    (SYSVAR_CURRLP),HL        ;[208B] 
    CALL  ZERO_MEM                  ;[208E] 
    JP    ZERO_CONTLP               ;[2091] 

;
; INPUT.
;
BASIC_COM_INPUT:
    CP    $22                       ;[2094] 
    JR    NZ,EIPT1                  ;[2096] 
    CALL  PRINT_STRING              ;[2098] 
    INC   DE                        ;[209B] 
    INC   DE                        ;[209C] 
EIPT1:
    PUSH  DE                        ;[209D] 
    LD    A,'?'                     ;[209E] 
    RST   $08                       ;[20A0] 
    LD    A,' '                     ;[20A1] 
    RST   $08                       ;[20A3] 
    CALL  SUB_INPUT_IS_ESC          ;[20A4] 
    LD    A,$0F                     ;[20A7] 
    RST   $08                       ;[20A9] 
    LD    DE,INPBUF                 ;[20AA] 
    EXX                             ;[20AD] 
    POP   DE                        ;[20AE] 
    CALL  EIPTS                     ;[20AF] 
    JR    C,EIPT1                   ;[20B2] 
    RET                             ;[20B4] 

EIPTS:
    EXX                             ;[20B5] Input buffer analysis.
    LD    A,(DE)                    ;[20B6] 
    CP    CR                        ;[20B7] 
    EXX                             ;[20B9] 
    SCF                             ;[20BA] 
    RET   Z                         ;[20BB] 
    CALL  VPTR_IS_STR               ;[20BC] 
    PUSH  DE                        ;[20BF] 
    PUSH  HL                        ;[20C0] 
    JR    C,EIPT4                   ;[20C1] 
    EXX                             ;[20C3] 
    LD    HL,(SYSVAR_POLBUF)        ;[20C4] 
    CALL  RP                        ;[20C7] 
    CP    ','                       ;[20CA] 
    JR    Z,EIPT3                   ;[20CC] 
    RST   $20                       ;[20CE] 
    DB    CR                        ;[20CF] 
    DEC   DE                        ;[20D0] 
EIPT3:
    EXX                             ;[20D1] 
    LD    DE,(SYSVAR_POLBUF)        ;[20D2] 
    RST   $28                       ;[20D6] 
    POP   HL                        ;[20D7] 
    EX    DE,HL                     ;[20D8] 
    CALL  WRA1_TO_DE                ;[20D9] 
EIPT5:
    POP   DE                        ;[20DC] 
    LD    A,(DE)                    ;[20DD] 
    CP    CR                        ;[20DE] 
    RET   Z                         ;[20E0] 
    INC   DE                        ;[20E1] 
    JR    EIPTS                     ;[20E2] 
EIPT4:
    EXX                             ;[20E4] 
    POP   HL                        ;[20E5] 
    DEC   HL                        ;[20E6] 
    LD    B,(HL)                    ;[20E7] 
    INC   HL                        ;[20E8] 
    CALL  RDST1                     ;[20E9] 
    EXX                             ;[20EC] 
    JR    EIPT5                     ;[20ED] 

;
; Read string.
;
READ_STRING:
    LD    B,$10                     ;[20EF] 
RDST1:
    CALL  RDSTS                     ;[20F1] 
    JR    Z,RDST3                   ;[20F4] 
    LD    (HL),A                    ;[20F6] 
    INC   HL                        ;[20F7] 
    INC   DE                        ;[20F8] 
    DJNZ  RDST1                     ;[20F9] 
    CALL  RDSTS                     ;[20FB] 
RDST2:
    JR    Z,RDST3                   ;[20FE] 
    INC   DE                        ;[2100] 
    JR    $20FB                     ;[2101] 
RDST3:
    LD    (HL),SZ                   ;[2103] 
    RET   C                         ;[2105] 
    INC   DE                        ;[2106] 
    RET                             ;[2107] 

RDSTS:
    LD    A,(DE)                    ;[2108] Test what DE points to for a comma, a " or a CR.
    CP    $22                       ;[2109] 
    RET   Z                         ;[210B] 
    CP    ','                       ;[210C] 
    RET   Z                         ;[210E] 
    CP    CR                        ;[210F] 
    SCF                             ;[2111] 
    RET                             ;[2112] 

;
; Variable pointer C if string
;
VPTR_IS_STR:
    CALL  TEST_FOR_STRING           ;[2113] 
    JR    Z,VARP1                   ;[2116] 
    CALL  GET_VAR_ADDR              ;[2118] 
    OR    A                         ;[211B] 
    RET                             ;[211C] 

VARP1:
    CALL  SYSVAR_VRPTS              ;[211D] 
    SCF                             ;[2120] 
    RET                             ;[2121] 

;
; PAUSE.
;
BASIC_COM_PAUSE:
    RST   $18                       ;[2122] 
EPAUSE1:
    DEC   HL                        ;[2123] 
    LD    B,$1A                     ;[2124] 
EPAUSE2:
    DJNZ  EPAUSE2                   ;[2126] 
    LD    A,L                       ;[2128] 
    OR    H                         ;[2129] 
    JR    NZ,EPAUSE1                ;[212A] 
    RET                             ;[212C] 

;
; PROTECT.
;
BASIC_COM_PROTECT:
    RST   $18                       ;[212D] 
EPROT1:
    LD    (SYSVAR_PROTST),A         ;[212E] 
    RET                             ;[2131] 

;
; Same as Basic TEXT command. 
;
ETEXT:
    XOR   A                         ;[2132] 
    LD    (SYSVAR_PROTST),A         ;[2133] 
    LD    A,$01                     ;[2136] 
    RST   $08                       ;[2138] 
    LD    A,$04                     ;[2139] 
    RST   $08                       ;[213B] 
    LD    A,$02                     ;[213C] 
    RST   $08                       ;[213E] 
    XOR   A                         ;[213F] 
    RST   $08                       ;[2140] 
    LD    A,$04                     ;[2141] 
    RST   $08                       ;[2143] 
    LD    A,$03                     ;[2144] 
    JR    EPROT1                    ;[2146] 

;
; LET.
;
BASIC_COM_LET:
    CALL  TEST_FOR_STRING           ;[2148] 
    JR    Z,ELET1                   ;[214B] 
    CALL  GET_VAR_ADDR              ;[214D] 
    INC   DE                        ;[2150] 
    PUSH  HL                        ;[2151] 
    RST   $28                       ;[2152] 
    POP   HL                        ;[2153] 
    EX    DE,HL                     ;[2154] 
    PUSH  HL                        ;[2155] 
    CALL  WRA1_TO_DE                ;[2156] 
    POP   DE                        ;[2159] 
ELET7:
    LD    A,(DE)                    ;[215A] 
    CP    CR                        ;[215B] 
    RET   Z                         ;[215D] 
    INC   DE                        ;[215E] 
    JR    BASIC_COM_LET             ;[215F] 
ELET1:
    LD    IY,SYSVAR_CSTACK          ;[2161] 
    CALL  SYSVAR_VRPTS              ;[2165] String pointer
    INC   DE                        ;[2168] 
    PUSH  HL                        ;[2169] 
    PUSH  BC                        ;[216A] 
    CALL  STRING_EXEC               ;[216B] 
    POP   BC                        ;[216E] 
    POP   IX                        ;[216F] 
    LD    HL,SYSVAR_STRBUF          ;[2171] 
ELET2:
    CALL  STRING_SEEK_END           ;[2174] 
ELET3:
    LD    (IX+$00),SZ               ;[2177] 
    JR    ELET7                     ;[217B] 

;
; RESTORE.
;
BASIC_COM_RESTORE:
    CP    $0D                       ;[217D] 
    LD    IX,(SYSVAR_SOB)           ;[217F] 
    JR    Z,$2189                   ;[2183] 
    RST   $28                       ;[2185] 
    CALL  FINDLN                    ;[2186] 
    DEC   IX                        ;[2189] 
    LD    (SYSVAR_DATAP),IX         ;[218B] 
    RET                             ;[218F] 

;
; Find token? Search BASIC file for token in C.
;
FTL:
    LD    A,(IX+$00)                ;[2190] 
    CP    $80                       ;[2193] 
    SCF                             ;[2195] 
    RET   Z                         ;[2196] 
    LD    A,(IX+$06)                ;[2197] 
    CP    C                         ;[219A] 
    RET   Z                         ;[219B] 
    CALL  NEXT_LINE                 ;[219C] 
    JR    FTL                       ;[219F] 

;
; WHILE subroutine.
;
SUB_WHILE:
    LD    A,$FF                     ;[21A1] 
    EX    AF,AF'                    ;[21A3] 
FTLD1:
    LD    A,(IX+$00)                ;[21A4] 
    CP    $80                       ;[21A7] 
    SCF                             ;[21A9] 
    RET   Z                         ;[21AA] 
    LD    A,(IX+$06)                ;[21AB] 
    CP    B                         ;[21AE] 
    JR    Z,FTLD3                   ;[21AF] 
    CP    C                         ;[21B1] 
    JR    Z,FTLD4                   ;[21B2] 
FTLD2:
    CALL  NEXT_LINE                 ;[21B4] 
    JR    FTLD1                     ;[21B7] 
FTLD4:
    EX    AF,AF'                    ;[21B9] 
    OR    A                         ;[21BA] 
    RET   Z                         ;[21BB] 
    DEC   A                         ;[21BC] 
    EX    AF,AF'                    ;[21BD] 
    JR    FTLD2                     ;[21BE] 
FTLD3:
    EX    AF,AF'                    ;[21C0] 
    INC   A                         ;[21C1] 
    EX    AF,AF'                    ;[21C2] 
    JR    FTLD2                     ;[21C3] 

;
; READ.
;
BASIC_COM_READ:
    EXX                             ;[21C5] 
    LD    DE,(SYSVAR_DATAP)         ;[21C6] 
    EXX                             ;[21CA] 
ERD1:
    CALL  EIPTS                     ;[21CB] 
    JR    C,ERD2                    ;[21CE] 
    EXX                             ;[21D0] 
    LD    (SYSVAR_DATAP),DE         ;[21D1] 
    RET                             ;[21D5] 

ERD2:
    EXX                             ;[21D6] 
    INC   DE                        ;[21D7] 
    PUSH  DE                        ;[21D8] 
    POP   IX                        ;[21D9] 
    LD    C,DATA                    ;[21DB] 
    CALL  FTL                       ;[21DD] 
    CALL  C,ERR_OUT_OF_DATA         ;[21E0] 
    CALL  SKIP_LNUM                 ;[21E3] 
    INC   DE                        ;[21E6] 
    EXX                             ;[21E7] 
    JR    ERD1                      ;[21E8] 

;
; Test for string.
;
TEST_FOR_STRING:
    LD    A,(DE)                    ;[21EA] 
    CP    'A'                       ;[21EB] CHR$($41) = 'A' letter
    RET   C                         ;[21ED] 
    INC   DE                        ;[21EE] 
    LD    A,(DE)                    ;[21EF] 
    CP    '$'                       ;[21F0] CHR$($24) = Dollar Sign
    DEC   DE                        ;[21F2] 
    RET                             ;[21F3] 

;
; Read string variable into HL
;
READ_STRING_VAR:
    LD    A,(DE)                    ;[21F4] 
    CP    'A'                       ;[21F5] Buffer from DE buffer
    CALL  C,ERR_SYNTAX              ;[21F7] 
    CP    'Z'+1                     ;[21FA] 
    CALL  NC,ERR_SYNTAX             ;[21FC] 
RDSV1:
    LD    (HL),A                    ;[21FF] 
    INC   HL                        ;[2200] 
    LD    (HL),'$'                  ;[2201] 
    INC   HL                        ;[2203] 
    INC   DE                        ;[2204] 
    INC   DE                        ;[2205] 
DMSR:
    RST   $10                       ;[2206] 
    CP    '('                       ;[2207] 
    RET   NZ                        ;[2209] 
    LD    (HL),A                    ;[220A] 
    INC   HL                        ;[220B] 
    INC   DE                        ;[220C] 
    CALL  RP                        ;[220D] 
    CP    ')'                       ;[2210] 
    CALL  NZ,ERR_MISSING_BRACKET    ;[2212] 
    LD    (HL),A                    ;[2215] 
    INC   HL                        ;[2216] 
    RET                             ;[2217] 

;
; Load A with variable number (ie A=1. 9=2 etc) and HL will return with the address of the variable.
;
GET_VAR_ADDR:
    CALL  TEST_UPPER_LOW            ;[2218] 
    INC   DE                        ;[221B] 
    PUSH  AF                        ;[221C] 
    LD    A,(DE)                    ;[221D] 
    CP    '('                       ;[221E] 
    JP    Z,VPTA                    ;[2220] 
    POP   AF                        ;[2223] 
VTPTR:
    LD    L,A                       ;[2224] 
    LD    H,$00                     ;[2225] 
    PUSH  DE                        ;[2227] 
    LD    E,L                       ;[2228] 
    LD    D,H                       ;[2229] 
    ADD   HL,HL                     ;[222A] 
    ADD   HL,HL                     ;[222B] 
    ADD   HL,DE                     ;[222C] 
    LD    DE,(SYSVAR_VTBL)          ;[222D] 
    ADD   HL,DE                     ;[2231] 
    POP   DE                        ;[2232] 
    RET                             ;[2233] 

;
; Prints binary number in HL. 
;
PHEXHL:
    LD    A,H                       ;[2234] 
    CALL  PRINT_HEX_A               ;[2235] 
    LD    A,L                       ;[2238] 
PRINT_HEX_A:
    PUSH  AF                        ;[2239] 
    RRCA                            ;[223A] 
    RRCA                            ;[223B] 
    RRCA                            ;[223C] 
    RRCA                            ;[223D] 
    CALL  PHEXHL2                   ;[223E] 
    POP   AF                        ;[2241] 
PHEXHL2:
    AND   $0F                       ;[2242] 
    ADD   A,$30                     ;[2244] 
    CP    $3A                       ;[2246] 
    JR    C,PHEXHL_OUTB             ;[2248] 
    ADD   A,$07                     ;[224A] 
PHEXHL_OUTB:
    RST   $08                       ;[224C] 
    RET                             ;[224D] 

;
; LPRINT.
;
BASIC_COM_LPRINT:
    CALL  SUB_LINK_ON               ;[224E] 
    CALL  BASIC_COM_PRINT           ;[2251] 
    JP    SUB_LINK_OFF              ;[2254] 

;
; Prints a string. Print char in DE and loop until " char found.
;
PRINT_STRING:
    INC   DE                        ;[2257] 
    LD    A,(DE)                    ;[2258] 
    CP    $22                       ;[2259] Quote char
    RET   Z                         ;[225B] 
    RST   $08                       ;[225C] 
    JR    PRINT_STRING              ;[225D] 

;
; SWAP.
;
BASIC_COM_SWAP:
    CALL  GET_VAR_ADDR              ;[225F] 
    PUSH  HL                        ;[2262] 
    INC   DE                        ;[2263] 
    CALL  GET_VAR_ADDR              ;[2264] 
    POP   DE                        ;[2267] 
    LD    B,$05                     ;[2268] 
    JP    SWAP1                     ;[226A] 

BASIC_COM_CONT:
    LD    HL,(SYSVAR_CURRLP)        ;[226D] 
    LD    A,(HL)                    ;[2270] 
    CP    $80                       ;[2271] 
    RET   NZ                        ;[2273] 
    POP   BC                        ;[2274] 
    LD    HL,(SYSVAR_CONTLP)        ;[2275] 
    LD    A,L                       ;[2278] 
    OR    H                         ;[2279] 
    CALL  Z,ERR_CANNOT_CONT         ;[227A] 
    JP    EXEC_BASIC                ;[227D] 

;
; RUN. (aka ERUN)
;
BASIC_COM_RUN:
    PUSH  DE                        ;[2280] 
    CALL  ZERO_MEM                  ;[2281] Pre-run module
    POP   DE                        ;[2284] 
    LD    IX,(SYSVAR_SOB)           ;[2285] 
    LD    A,(DE)                    ;[2289] 
    CP    CR                        ;[228A] 
    JR    Z,EGT1                    ;[228C] 
EGT2:
    RST   $28                       ;[228E] Evaluate expression
    CALL  FINDLN                    ;[228F] 
EGT1:
    POP   BC                        ;[2292] 
    JP    RUN_BASIC_PROG            ;[2293] 

;
; GOSUB
;
BASIC_COM_GOSUB:
    LD    HL,(SYSVAR_CURRLP)        ;[2296] 
    CALL  PUSH_HL_RSTACK            ;[2299] 
    LD    A,GOSUB                   ;[229C] 
    CALL  PUSH_A_RSTACK             ;[229E] 
    LD    A,(DE)                    ;[22A1] 

BASIC_COM_GOTO:
    CP    OLABEL                    ;[22A2] 
    JR    NZ,EGT2                   ;[22A4] 
    LD    C,LABEL                   ;[22A6] 
    INC   DE                        ;[22A8] 
    LD    IX,(SYSVAR_SOB)           ;[22A9] 
EGT3:
    PUSH  DE                        ;[22AD] 
    CALL  FTL                       ;[22AE] 
    CALL  C,ERR_NOT_FOUND           ;[22B1] 
    PUSH  IX                        ;[22B4] 
    LD    DE,7                      ;[22B6] 
    ADD   IX,DE                     ;[22B9] 
    PUSH  IX                        ;[22BB] 
    POP   HL                        ;[22BD] 
    POP   IX                        ;[22BE] 
    POP   DE                        ;[22C0] 
    PUSH  DE                        ;[22C1] 
    CALL  STRING_CMP                ;[22C2] 
    JR    Z,EGT4                    ;[22C5] 
    CALL  NEXT_LINE                 ;[22C7] 
    POP   DE                        ;[22CA] 
    JR    NZ,EGT3                   ;[22CB] 
EGT4:
    POP   BC                        ;[22CD] 
    LD    (SYSVAR_CURRLP),IX        ;[22CE] 
    RET                             ;[22D2] 

;
; Compare two strings for compatibility.
;
STRING_CMP:
    LD    A,(DE)                    ;[22D3] 
    CP    (HL)                      ;[22D4] 
    RET   NZ                        ;[22D5] 
    CP    '('                       ;[22D6] 
    RET   Z                         ;[22D8] 
    CP    CR                        ;[22D9] 
    RET   Z                         ;[22DB] 
    INC   HL                        ;[22DC] 
    INC   DE                        ;[22DD] 
    JR    STRING_CMP                ;[22DE] 

;
; LIST (in part)
;
ELIST2:
    LD    IX,(SYSVAR_SOB)           ;[22E0] 
    LD    DE,$FFFF                  ;[22E4] 
    JR    ELIST1                    ;[22E7] 

BASIC_COM_LIST:
    CP    CR                        ;[22E9] 
    LD    A,0                       ;[22EB] 
    LD    (SYSVAR_SBC),A            ;[22ED] 
    JR    Z,ELIST2                  ;[22F0] 
    RST   $28                       ;[22F2] 
    PUSH  DE                        ;[22F3] 
    CALL  FNDLN_WRA1                ;[22F4] 
    POP   DE                        ;[22F7] 
    LD    A,(DE)                    ;[22F8] 
    CP    CR                        ;[22F9] 
    PUSH  IX                        ;[22FB] 
    JR    Z,ELIST3                  ;[22FD] 
    INC   DE                        ;[22FF] 
    RST   $28                       ;[2300] 
    CALL  FNDLN_WRA1                ;[2301] 
ELIST3:
    PUSH  IX                        ;[2304] 
    POP   DE                        ;[2306] 
    POP   IX                        ;[2307] 
    INC   DE                        ;[2309] 
ELIST1:
    LD    A,(IX+$00)                ;[230A] 
    CP    $80                       ;[230D] 
    JR    Z,ELIST4                  ;[230F] 
    PUSH  DE                        ;[2311] 
    CALL  SYSVAR_DBASLN             ;[2312] 
    LD    (SYSVAR_CURRLP),IX        ;[2315] 
ELIST9:
    CALL  ESC                       ;[2319] 
    JR    Z,ELIST4                  ;[231C] 
    LD    BC,PORT                   ;[231E] 
    IN    A,(C)                     ;[2321] 
    RLCA                            ;[2323] 
    JR    NC,ELIST9                 ;[2324] 
    CALL  NEXT_LINE                 ;[2326] 
    POP   DE                        ;[2329] 
    PUSH  IX                        ;[232A] 
    POP   HL                        ;[232C] 
    CALL  CHLDE                     ;[232D] 
    JR    C,ELIST1                  ;[2330] 
ELIST4:
    LD    A,CEL                     ;[2332] 
    RST   $08                       ;[2334] 
    JP    TO_CMDLINE                ;[2335] 

;
; LLIST.
;
BASIC_COM_LLIST:
    CALL  SUB_LINK_ON               ;[2338] 
    LD    A,(DE)                    ;[233B] 
    JP    BASIC_COM_LIST            ;[233C] 

;
; DEL
;
BASIC_COM_DEL:
    RST   $28                       ;[233F] 
    PUSH  DE                        ;[2340] 
    CALL  FINDLN                    ;[2341] 
    POP   DE                        ;[2344] 
    LD    A,(DE)                    ;[2345] 
    CP    $0D                       ;[2346] 
    INC   DE                        ;[2348] 
    PUSH  IX                        ;[2349] 
    JR    Z,$2351                   ;[234B] 
    RST   $28                       ;[234D] 
    CALL  FINDLN                    ;[234E] 
    CALL  NEXT_LINE                 ;[2351] 
    PUSH  IX                        ;[2354] 
    POP   BC                        ;[2356] 
    POP   HL                        ;[2357] 
    LD    E,L                       ;[2358] 
    LD    D,H                       ;[2359] 
    OR    A                         ;[235A] 
    SBC   HL,BC                     ;[235B] 
    CALL  $256E                     ;[235D] 
    JP    ZERO_CONTLP               ;[2360] 

;
; Picks up a Basic argument!
;
SUB_ARGUMENT:
    RST   $28                       ;[2363] 
    LD    A,(SYSVAR_WRA1)           ;[2364] 
    BIT   7,A                       ;[2367] 
    CALL  Z,SUB_ARGUMENT1           ;[2369] 
    CALL  FPINT                     ;[236C] 
    LD    A,L                       ;[236F] 
    RET                             ;[2370] 

;
; Called by SUB_ARGUMENT
;
SUB_ARGUMENT1:
    PUSH  DE                        ;[2371] 
    LD    HL,FLOAT_16B              ;[2372] 
    CALL  LNUM2                     ;[2375] 
    CALL  ADD                       ;[2378] 
    POP   DE                        ;[237B] 
    RET                             ;[237C] 

;
; OUT.
;
BASIC_COM_OUT:
    RST   $18                       ;[237D] 
    PUSH  HL                        ;[237E] 
    INC   DE                        ;[237F] 
    RST   $18                       ;[2380] 
    POP   BC                        ;[2381] 
    OUT   (C),A                     ;[2382] 
    RET                             ;[2384] 

BASIC_COM_POKE:
    RST   $18                       ;[2385] 
    PUSH  HL                        ;[2386] 
    INC   DE                        ;[2387] 
    RST   $18                       ;[2388] 
    POP   HL                        ;[2389] 
    LD    (HL),A                    ;[238A] 
    RET                             ;[238B] 

;
; DPOKE.
;
BASIC_COM_DPOKE:
    RST   $18                       ;[238C] 
    PUSH  HL                        ;[238D] 
    INC   DE                        ;[238E] 
    RST   $18                       ;[238F] 
    LD    C,L                       ;[2390] 
    LD    B,H                       ;[2391] 
    POP   HL                        ;[2392] 
    LD    (HL),C                    ;[2393] 
    INC   HL                        ;[2394] 
    LD    (HL),B                    ;[2395] 
    RET                             ;[2396] 

;
; FOR
;
BASIC_COM_FOR:
    PUSH  AF                        ;[2397] 
    CALL  GET_VAR_ADDR              ;[2398] 
    PUSH  HL                        ;[239B] 
    LD    HL,(SYSVAR_CURRLP)        ;[239C] 
    CALL  PUSH_HL_RSTACK            ;[239F] 
    INC   DE                        ;[23A2] 
    RST   $28                       ;[23A3] 
    POP   HL                        ;[23A4] 
    PUSH  DE                        ;[23A5] 
    INC   HL                        ;[23A6] 
    RES   7,(HL)                    ;[23A7] 
    DEC   HL                        ;[23A9] 
    EX    DE,HL                     ;[23AA] 
    CALL  WRA1_TO_DE                ;[23AB] 
    POP   DE                        ;[23AE] 
    INC   DE                        ;[23AF] 
    RST   $28                       ;[23B0] 
    CALL  $23CC                     ;[23B1] 
    LD    A,(DE)                    ;[23B4] 
    CP    $0D                       ;[23B5] 
    JR    Z,$23C7                   ;[23B7] 
    INC   DE                        ;[23B9] 
    RST   $28                       ;[23BA] 
    CALL  $23CC                     ;[23BB] 
    POP   AF                        ;[23BE] 
    CALL  PUSH_A_RSTACK             ;[23BF] 
    LD    A,$0F                     ;[23C2] 
    JP    PUSH_A_RSTACK             ;[23C4] 
    CALL  LONE                      ;[23C7] 
    JR    $23BB                     ;[23CA] 
    PUSH  DE                        ;[23CC] 
    LD    B,$05                     ;[23CD] 
    LD    DE,SYSVAR_WRA1            ;[23CF] 
    LD    A,(DE)                    ;[23D2] 
    CALL  PUSH_A_RSTACK             ;[23D3] 
    INC   DE                        ;[23D6] 
    DJNZ  $23D2                     ;[23D7] 
    POP   DE                        ;[23D9] 
    RET                             ;[23DA] 

;
; NEXT.
;
BASIC_COM_NEXT:
    LD    HL,(SYSVAR_RSP)           ;[23DB] 
    DEC   HL                        ;[23DE] 
    LD    A,(HL)                    ;[23DF] 
    CP    $0F                       ;[23E0] 
    CALL  NZ,ERR_NEXT_NO_FOR        ;[23E2] 
    DEC   HL                        ;[23E5] 
    LD    A,(DE)                    ;[23E6] 
    CP    (HL)                      ;[23E7] 
    CALL  NZ,ERR_NEXT_NO_FOR        ;[23E8] 
    DEC   HL                        ;[23EB] 
    PUSH  DE                        ;[23EC] 
    CALL  $2423                     ;[23ED] 
    POP   DE                        ;[23F0] 
    LD    A,(SYSVAR_WRA2)           ;[23F1] 
    PUSH  AF                        ;[23F4] 
    PUSH  HL                        ;[23F5] 
    CALL  GET_VAR_ADDR              ;[23F6] 
    PUSH  HL                        ;[23F9] 
    CALL  LNUM1                     ;[23FA] 
    CALL  ADD                       ;[23FD] 
    POP   HL                        ;[2400] 
    EX    DE,HL                     ;[2401] 
    CALL  WRA1_TO_DE                ;[2402] 
    POP   HL                        ;[2405] 
    CALL  $2423                     ;[2406] 
    POP   AF                        ;[2409] 
    BIT   7,A                       ;[240A] 
    PUSH  HL                        ;[240C] 
    CALL  Z,SWAP                    ;[240D] 
    CALL  CMP                       ;[2410] 
    POP   HL                        ;[2413] 
    JR    C,$241E                   ;[2414] 
    LD    A,(HL)                    ;[2416] 
    DEC   HL                        ;[2417] 
    LD    L,(HL)                    ;[2418] 
    LD    H,A                       ;[2419] 
    LD    (SYSVAR_CURRLP),HL        ;[241A] 
    RET                             ;[241D] 

    DEC   HL                        ;[241E] 
    LD    (SYSVAR_RSP),HL           ;[241F] 
    RET                             ;[2422] 

    LD    BC,$0005                  ;[2423] 
    LD    DE,SYSVAR_WRA2+$04        ;[2426] 
    LDDR                            ;[2429] 
    RET                             ;[242B] 

;
; IF
;
BASIC_COM_IF:
    RST   $28                       ;[242C] 
    LD    A,(SYSVAR_WRA1)           ;[242D] 
    CP    $80                       ;[2430] 
    JR    Z,$2439                   ;[2432] 
    INC   DE                        ;[2434] 
    POP   BC                        ;[2435] 
    JP    $24A6                     ;[2436] 
    LD    IX,(SYSVAR_CURRLP)        ;[2439] 
    CALL  NEXT_LINE                 ;[243D] 
    LD    A,(IX+$00)                ;[2440] 
    CP    $80                       ;[2443] 
    RET   Z                         ;[2445] 
    LD    A,(IX+$06)                ;[2446] 
    CP    $3C                       ;[2449] 
    RET   NZ                        ;[244B] 
    LD    (SYSVAR_CURRLP),IX        ;[244C] 
    CALL  SKIP_LNUM                 ;[2450] 
    JR    $2434                     ;[2453] 

;
; TRAIL
;
BASIC_COM_TRAIL:
    LD    HL,SYSVAR_ZFLAG           ;[2455] 
    RES   1,(HL)                    ;[2458] 
    CP    $DA                       ;[245A] 
    RET   NZ                        ;[245C] is execution address for LABEL: ELSE: DATA:REM.
    SET   1,(HL)                    ;[245D] 

;
; CODE, REM, DATA, LABEL, ELSE 
; (non-executable commands, just return)
;
BASIC_COM_NO_EXE:
    RET                             ;[245F] 

;
; SPEED.
;
BASIC_COM_SPEED:
    RST   $18                       ;[2460] 
    LD    HL,SYSVAR_EXFLAG          ;[2461] 
    LD    (SYSVAR_SPEEDST),A        ;[2464] 
    SET   1,(HL)                    ;[2467] 
    OR    A                         ;[2469] 
    RET   NZ                        ;[246A] 
    RES   1,(HL)                    ;[246B] 
    RET                             ;[246D] 

;
; TRACE.
;
BASIC_COM_TRACE:
    LD    HL,SYSVAR_EXFLAG          ;[246E] 
    JR    $2476                     ;[2471] 

;
; ROUND.
;
BASIC_COM_ROUND:
    LD    HL,SYSVAR_ZFLAG           ;[2473] 
    RES   0,(HL)                    ;[2476] 
    CP    $DA                       ;[2478] 
    RET   NZ                        ;[247A] 
    SET   0,(HL)                    ;[247B] 
    RET                             ;[247D] 

;
; LINK.
;
BASIC_COM_LINK:
    LD    HL,SYSVAR_OTYPE           ;[247E] 
    RES   7,(HL)                    ;[2481] 
    CP    $DA                       ;[2483] 
    RET   NZ                        ;[2485] 
    SET   7,(HL)                    ;[2486] 
    RET                             ;[2488] 

    PUSH  HL                        ;[2489] Called from 252D. (part of LIST)
    LD    HL,FLOAT_ZERO             ;[248A] 
    LD    (SYSVAR_CURRLP),HL        ;[248D] 
    POP   HL                        ;[2490] 
    JR    $2496                     ;[2491] 

;
; Executes BASIC program lines
;
EXEC_BASIC:
    LD    (SYSVAR_CURRLP),HL        ;[2493] 
    LD    A,$0F                     ;[2496] 
    RST   $08                       ;[2498] 
    PUSH  HL                        ;[2499] 
    POP   IX                        ;[249A] 
EXEC_LINE_LOOP:
    LD    A,(SYSVAR_EXFLAG)         ;[249C] Trace/speed settings
    OR    A                         ;[249F] 
    CALL  NZ,SYSVAR_DEBUG           ;[24A0] See DEBUG:
    CALL  SKIP_LNUM                 ;[24A3] 
    LD    A,(DE)                    ;[24A6] 
    LD    BC,(SYSVAR_XETBL)         ;[24A7] Command execution table
    CALL  SYSVAR_EXECSUB            ;[24AB] For future use?
    RLCA                            ;[24AE] 
    LD    L,A                       ;[24AF] Lookup command address in table
    LD    H,$00                     ;[24B0] 
    ADD   HL,BC                     ;[24B2] 
    LD    BC,EXEC_LINE_RETURN       ;[24B3] 
    PUSH  BC                        ;[24B6] 
    LD    A,(HL)                    ;[24B7] 
    INC   HL                        ;[24B8] 
    LD    H,(HL)                    ;[24B9] 
    LD    L,A                       ;[24BA] 
    INC   DE                        ;[24BB] 
    LD    A,(DE)                    ;[24BC] 
    JP    (HL)                      ;[24BD] Execute basic command.
EXEC_LINE_RETURN:
    LD    IX,(SYSVAR_CURRLP)        ;[24BE] 
    CALL  NEXT_LINE                 ;[24C2] 
RUN_BASIC_PROG:
    LD    (SYSVAR_CURRLP),IX        ;[24C5] 
    LD    A,(IX+$00)                ;[24C9] 
    CP    $80                       ;[24CC] $80 = End of program marker
    JR    Z,TO_CMDLINE              ;[24CE] 
    LD    (SYSVAR_CONTLP),IX        ;[24D0] 
    CALL  ESC                       ;[24D4] 
    JP    Z,$1E42                   ;[24D7] 
    JR    EXEC_LINE_LOOP            ;[24DA] 

;
; Zero the "continue" line pointer. (cannot continue)
;
ZERO_CONTLP:
    LD    HL,$0000                  ;[24DC] 
    LD    (SYSVAR_CONTLP),HL        ;[24DF] 
TO_CMDLINE:
    JP    JUMP_TO_CMDLINE           ;[24E2] 

;
; SPEED and TRACE routines.
;
DEBUG:
    PUSH  IX                        ;[24E5] 
    PUSH  AF                        ;[24E7] 
    BIT   0,A                       ;[24E8] 
    CALL  NZ,$24F6                  ;[24EA] 
    POP   AF                        ;[24ED] 
    BIT   1,A                       ;[24EE] 
    CALL  NZ,$250A                  ;[24F0] 
    POP   IX                        ;[24F3] 
    RET                             ;[24F5] 

    LD    HL,(SYSVAR_CURRLP)        ;[24F6] TRACE handling routine.
    LD    A,(HL)                    ;[24F9] 
    CP    $80                       ;[24FA] 
    RET   Z                         ;[24FC] 
    LD    A,$3C                     ;[24FD] 
    RST   $08                       ;[24FF] 
    CALL  LNUM1                     ;[2500] 
    CALL  PN                        ;[2503] 
    LD    A,$3E                     ;[2506] 
    RST   $08                       ;[2508] 
    RET                             ;[2509] 

    LD    HL,(SYSVAR_CURRLP)        ;[250A] SPEED handling routine.
    LD    A,(HL)                    ;[250D] 
    CP    $80                       ;[250E] 
    RET   Z                         ;[2510] 
    LD    HL,(SYSVAR_SPEEDST)       ;[2511] 
    LD    H,L                       ;[2514] 
    DEC   HL                        ;[2515] 
    LD    A,H                       ;[2516] 
    OR    L                         ;[2517] 
    JR    NZ,$2515                  ;[2518] 
    RET                             ;[251A] 

;
; Let DE = IX + $06
;
SKIP_LNUM:
    LD    DE,$0006                  ;[251B] 
    ADD   IX,DE                     ;[251E] 
    PUSH  IX                        ;[2520] 
    POP   DE                        ;[2522] 
    RET                             ;[2523] 

;
; Input line analysis routine.
;
LINP_ANLYS:
    CALL  INPLN                     ;[2524] 
    LD    HL,(SYSVAR_POLBUF)        ;[2527] 
    LD    A,(HL)                    ;[252A] 
    CP    $80                       ;[252B] 
    JP    Z,$2489                   ;[252D] 
    CALL  LNUM1                     ;[2530] 
    PUSH  HL                        ;[2533] 
    LD    HL,$0000                  ;[2534] 
    LD    (SYSVAR_CONTLP),HL        ;[2537] 
    CALL  FNDLN_WRA1                ;[253A] 
    POP   HL                        ;[253D] 
    LD    L,(HL)                    ;[253E] 
    LD    H,$00                     ;[253F] 
    PUSH  HL                        ;[2541] 
    JR    NZ,$254C                  ;[2542] 
    LD    D,$00                     ;[2544] 
    LD    E,(IX+$05)                ;[2546] 
    OR    A                         ;[2549] 
    SBC   HL,DE                     ;[254A] 
    PUSH  IX                        ;[254C] 
    POP   DE                        ;[254E] 
    PUSH  IX                        ;[254F] 
    CALL  $256E                     ;[2551] 
    POP   DE                        ;[2554] 
    POP   BC                        ;[2555] 
    LD    HL,(SYSVAR_POLBUF)        ;[2556] 
    LDIR                            ;[2559] 
    JP    ZERO_MEM                  ;[255B] 

;
; Next line. IX points to next line.
;
NEXT_LINE:
    PUSH  DE                        ;[255E] 
    LD    E,(IX+$05)                ;[255F] 
    LD    D,$00                     ;[2562] 
    ADD   IX,DE                     ;[2564] 
    POP   DE                        ;[2566] 
    RET                             ;[2567] 

;
; Compares HL, DE flags set as HL-DE. 
;
CHLDE:
    LD    A,H                       ;[2568] 
    SUB   D                         ;[2569] 
    RET   NZ                        ;[256A] 
    LD    A,L                       ;[256B] 
    SUB   E                         ;[256C] 
    RET                             ;[256D] 

    LD    A,H                       ;[256E] Load line to memory.
    OR    L                         ;[256F] 
    RET   Z                         ;[2570] 
    PUSH  HL                        ;[2571] 
    LD    HL,$0000                  ;[2572] 
    LD    (SYSVAR_PROCST),HL        ;[2575] 
    POP   HL                        ;[2578] 
    BIT   7,H                       ;[2579] 
    JR    NZ,$25A1                  ;[257B] 
    LD    BC,(SYSVAR_EOB)           ;[257D] 
    ADD   HL,BC                     ;[2581] 
    PUSH  HL                        ;[2582] 
    PUSH  DE                        ;[2583] 
    LD    DE,(SYSVAR_STACK)         ;[2584] 
    DEC   D                         ;[2588] 
    CALL  CHLDE                     ;[2589] 
    POP   DE                        ;[258C] 
    CALL  NC,ERR_OUT_OF_MEM         ;[258D] 
    CALL  $25BB                     ;[2590] 
    PUSH  BC                        ;[2593] 
    LD    L,C                       ;[2594] 
    LD    H,B                       ;[2595] 
    OR    A                         ;[2596] 
    SBC   HL,DE                     ;[2597] 
    PUSH  HL                        ;[2599] 
    POP   BC                        ;[259A] 
    POP   HL                        ;[259B] 
    POP   DE                        ;[259C] 
    INC   BC                        ;[259D] 
    LDDR                            ;[259E] 
    RET                             ;[25A0] 

    PUSH  HL                        ;[25A1] 
    PUSH  DE                        ;[25A2] 
    EX    DE,HL                     ;[25A3] 
    OR    A                         ;[25A4] 
    SBC   HL,DE                     ;[25A5] 
    PUSH  HL                        ;[25A7] 
    EX    DE,HL                     ;[25A8] 
    LD    HL,(SYSVAR_EOB)           ;[25A9] 
    OR    A                         ;[25AC] 
    SBC   HL,DE                     ;[25AD] 
    PUSH  HL                        ;[25AF] 
    POP   BC                        ;[25B0] 
    POP   HL                        ;[25B1] 
    POP   DE                        ;[25B2] 
    INC   BC                        ;[25B3] 
    LDIR                            ;[25B4] 
    POP   DE                        ;[25B6] 
    LD    HL,(SYSVAR_EOB)           ;[25B7] 
    ADD   HL,DE                     ;[25BA] 
    LD    (SYSVAR_EOB),HL           ;[25BB] 
    INC   HL                        ;[25BE] 
    LD    (SYSVAR_TOV),HL           ;[25BF] 
    PUSH  DE                        ;[25C2] 
    PUSH  BC                        ;[25C3] 
    CALL  CLEAR_VARS                ;[25C4] 
    POP   BC                        ;[25C7] 
    POP   DE                        ;[25C8] 
    RET                             ;[25C9] 

;
; Called from MAIN. Clears variables [a-Z] and strings.
;
CLEAR_VARS:
    LD    HL,(SYSVAR_STBL)          ;[25CA] 
    LD    B,$68                     ;[25CD] 
    XOR   A                         ;[25CF] 
CLEAR_VARS_LOOP:
    LD    (HL),A                    ;[25D0] 
    INC   HL                        ;[25D1] 
    DJNZ  CLEAR_VARS_LOOP           ;[25D2] 
    LD    HL,(SYSVAR_ATBL)          ;[25D4] 
    LD    E,L                       ;[25D7] 
    LD    D,H                       ;[25D8] 
    INC   DE                        ;[25D9] 
    LD    BC,$00D3                  ;[25DA] 
    LD    (HL),$00                  ;[25DD] 
    LDIR                            ;[25DF] 
    RET                             ;[25E1] 

;
; Reads ASCII pointed to by DE into reverse polish pointed to by HL. 
;
RP:
    LD    (HL),$7D                  ;[25E2] 
    INC   HL                        ;[25E4] 
    CALL  SYSVAR_NTP                ;[25E5] Jump to normal to internal language conversion routine. (NTP)
    LD    A,(SYSVAR_NPM)            ;[25E8] 
    CP    $D7                       ;[25EB] 
    RET   NC                        ;[25ED] 
    LD    A,(DE)                    ;[25EE] 
    INC   DE                        ;[25EF] 
    RET                             ;[25F0] 

;
; Validation utility routine.
;
VALIDATE_UTILITY:
    RST   $20                       ;[25F1] 
    LD    ($2377),HL                ;[25F2] 
    INC   DE                        ;[25F5] 
    LD    A,(DE)                    ;[25F6] 
    INC   DE                        ;[25F7] 
    LD    (HL),A                    ;[25F8] 
    INC   HL                        ;[25F9] 
    CP    $0D                       ;[25FA] 
    CALL  Z,ERR_SYNTAX              ;[25FC] 
    CP    $22                       ;[25FF] 
    JR    NZ,$25F6                  ;[2601] 
    JP    RST_10                    ;[2603] 

;
; Validation for ROUND, TRAIL, LINK, TRACE.
;
VALIDATE_ROUND:
    CALL  TKSL                      ;[2606] 
    CP    $DA                       ;[2609] 
    JR    Z,$260F                   ;[260B] 
    RST   $20                       ;[260D] 
    IN    A,($77)                   ;[260E] 
    INC   HL                        ;[2610] 
    RST   $10                       ;[2611] 
    LD    (HL),A                    ;[2612] 
    RST   $20                       ;[2613] 
    DEC   C                         ;[2614] 
    RET                             ;[2615] 

;
; Validation for LOAD, MLOAD, APPEND, VERIFY.
;
VALIDATE_LOAD:
    CALL  VALIDATE_UTILITY          ;[2616] 
    RST   $20                       ;[2619] 
    DEC   C                         ;[261A] 
    LD    (HL),A                    ;[261B] 
    RET                             ;[261C] 

;
; Validation for SAVE.
;
VALIDATE_SAVE:
    CALL  VALIDATE_UTILITY          ;[261D] 
    CP    $0D                       ;[2620] 
    JR    Z,$261B                   ;[2622] 
    RST   $20                       ;[2624] 
    INC   L                         ;[2625] 
    LD    (HL),A                    ;[2626] 
    INC   HL                        ;[2627] 
    INC   DE                        ;[2628] 
    JP    VALIDATE_INK              ;[2629] 

;
; Validation for INPUT.
;
VALIDATE_INPUT:
    CP    $22                       ;[262C] 
    JR    NZ,$2639                  ;[262E] 
    CALL  VALIDATE_UTILITY          ;[2630] 
    RST   $20                       ;[2633] 
    DEC   SP                        ;[2634] 
    LD    (HL),A                    ;[2635] 
    INC   HL                        ;[2636] 
    INC   DE                        ;[2637] 
    RST   $10                       ;[2638] 
    PUSH  HL                        ;[2639] 
    LD    HL,(SYSVAR_POLBUF)        ;[263A] 
    LD    A,(HL)                    ;[263D] 
    CP    $80                       ;[263E] 
    CALL  Z,ERR_WRONG_MODE          ;[2640] 
    POP   HL                        ;[2643] 
    CALL  TEST_FOR_STRING           ;[2644] 
    JR    Z,$2657                   ;[2647] 
    CALL  VALIDATE_READ             ;[2649] 
    LD    (HL),A                    ;[264C] 
    CP    $0D                       ;[264D] 
    RET   Z                         ;[264F] 
    RST   $20                       ;[2650] 
    INC   L                         ;[2651] 
    INC   HL                        ;[2652] 
    INC   DE                        ;[2653] 
    RST   $10                       ;[2654] 
    JR    $2639                     ;[2655] 
    CALL  READ_STRING_VAR           ;[2657] 
    RST   $10                       ;[265A] 
    JR    $264C                     ;[265B] 

;
; Validation for RESTORE.
;
VALIDATE_RESTORE:
    CP    $0D                       ;[265D] 
    JP    NZ,VALIDATE_INK           ;[265F] 
    LD    (HL),A                    ;[2662] 
    RET                             ;[2663] 

;
; Validation for LIST, LLIST, RENUM.
;
VALIDATE_LIST:
    CP    $0D                       ;[2664] 
    JR    Z,$2662                   ;[2666] 

;
; Validation for CALL.
;
VALIDATE_CALL:
    CALL  RP                        ;[2668] 
    CP    $0D                       ;[266B] 
    JR    Z,$2662                   ;[266D] 
    RST   $20                       ;[266F] 
    INC   L                         ;[2670] 
    LD    (HL),A                    ;[2671] 
    INC   HL                        ;[2672] 
    JP    VALIDATE_INK              ;[2673] 
    POP   AF                        ;[2676] 
    POP   HL                        ;[2677] 
    LD    A,$00                     ;[2678] 
    LD    (HL),A                    ;[267A] 
    INC   HL                        ;[267B] 

;
; Validation routine for LET.
;
VALIDATE_LET:
    CALL  TEST_FOR_STRING           ;[267C] 
    JR    Z,$2696                   ;[267F] 
    CALL  VALIDATE_READ             ;[2681] 
    CP    $3D                       ;[2684] 
    JP    NZ,IERR                   ;[2686] 
    LD    (HL),A                    ;[2689] 
    INC   HL                        ;[268A] 
    INC   DE                        ;[268B] 
    CALL  RP                        ;[268C] 
    CP    $2C                       ;[268F] 
    JR    Z,$267A                   ;[2691] 
    JP    VALIDATE_MON              ;[2693] 
    CALL  READ_STRING_VAR           ;[2696] 
    RST   $10                       ;[2699] 
    RST   $20                       ;[269A] 
    DEC   A                         ;[269B] 
    LD    (HL),A                    ;[269C] 
    INC   HL                        ;[269D] 
    INC   DE                        ;[269E] 
    RST   $10                       ;[269F] 
    CALL  READ_STRING_EXPR          ;[26A0] 
    INC   DE                        ;[26A3] 
    JR    $268F                     ;[26A4] 

;
; Input error
;
IERR:
    LD    DE,INPBUF                 ;[26A6] 
    LD    HL,(SYSVAR_POLBUF)        ;[26A9] 
    PUSH  HL                        ;[26AC] 
    CALL  VALIDATE_INK              ;[26AD] 
    POP   DE                        ;[26B0] 
    CALL  SYSVAR_EE                 ;[26B1] 
    CALL  PN                        ;[26B4] 
    LD    A,CR                      ;[26B7] 
    RST   $08                       ;[26B9] 
    JP    JUMP_TO_CMDLINE           ;[26BA] 

;
; Validation routine for DPOKE, POKE, DOT, OUT, MOVE, DRAW.SOUND.
;
VALIDATE_DPOKE:
    CALL  TEST_IS_COMMA             ;[26BD] 
    JP    VALIDATE_INK              ;[26C0] 

;
; Validation routine for GOSUB, GOTO.  (expr,expr type)
;
VALIDATE_GOTO:
    PUSH  DE                        ;[26C3] 
    CALL  TKSL                      ;[26C4] 
    JR    C,VALIDATE_GOTO2          ;[26C7] 
    CP    OLABEL                    ;[26C9] 
    JR    Z,VALIDATE_GOTO1          ;[26CB] 
VALIDATE_GOTO2:
    POP   DE                        ;[26CD] 
    JP    VALIDATE_INK              ;[26CE] 
VALIDATE_GOTO1:
    POP   BC                        ;[26D1] 
    LD    (HL),A                    ;[26D2] 
    INC   HL                        ;[26D3] 
    RST   $10                       ;[26D4] 
    JP    VALIDATE_REM              ;[26D5] 

;
; Validation routine for NEXT.
;
VALIDATE_NEXT:
    CALL  TEST_IS_VAR               ;[26D8] 

;
; Validation for MON, ENDPROC, RANDOM, END, STOP, RETURN, CLS, CONT, NEW, 
; WEND, REPEAT, DISK, TEXT.
;
VALIDATE_MON:
    LD    (HL),A                    ;[26DB] 
    RST   $20                       ;[26DC] 
    DEC   C                         ;[26DD] 
    RET                             ;[26DE] 

;
; Validation for FOR.
;
VALIDATE_FOR:
    CALL  TEST_IS_VAR               ;[26DF] 
    RST   $20                       ;[26E2] 
    DEC   A                         ;[26E3] 
    INC   DE                        ;[26E4] 
    LD    (HL),A                    ;[26E5] 
    INC   HL                        ;[26E6] 
    CALL  RP                        ;[26E7] 
    RST   $20                       ;[26EA] 
    LD    (IX+$23),A                ;[26EB] 
    CALL  RP                        ;[26EE] 
    CP    $0D                       ;[26F1] 
    JP    Z,$2662                   ;[26F3] 
    RST   $20                       ;[26F6] 
    CALL  C,$2377                   ;[26F7] 
    JP    VALIDATE_INK              ;[26FA] 

;
; Validation for IF.
;
VALIDATE_IF:
    CALL  RP                        ;[26FD] 
    RST   $20                       ;[2700] 
    RST   $10                       ;[2701] 
    LD    (HL),A                    ;[2702] 
    INC   HL                        ;[2703] 
    JP    IL1                       ;[2704] 

;
; Validation for INK, PAPER, PAUSE, WHILE, UNTIL, RESERVE, CFR,  CCHAR, SPEED, 
; PROTECT, ERROR, TAPE.
;
VALIDATE_INK:
    CALL  RP                        ;[2707] 
    JP    VALIDATE_MON              ;[270A] 

;
; Convert to internal language and check for a comma.
;
TEST_IS_COMMA:
    CALL  RP                        ;[270D] 
    RST   $20                       ;[2710] 
    INC   L                         ;[2711] 
    LD    (HL),A                    ;[2712] 
    INC   HL                        ;[2713] 
    RET                             ;[2714] 

;
; Test for a variable and find next non-blank.
;
TEST_IS_VAR:
    CALL  TEST_ALPHA                ;[2715] 
    CALL  C,ERR_SYNTAX              ;[2718] 
    LD    (HL),A                    ;[271B] 
    INC   DE                        ;[271C] 
    INC   HL                        ;[271D] 
    JP    RST_10                    ;[271E] 

;
; is validation routine for READ.
;
VALIDATE_READ:
    CALL  TEST_ALPHA                ;[2721] 
    JP    C,IERR                    ;[2724] 
    LD    (HL),A                    ;[2727] 
    INC   HL                        ;[2728] 
    INC   DE                        ;[2729] 
    RST   $10                       ;[272A] 
    CP    $28                       ;[272B] 
    RET   NZ                        ;[272D] 
    LD    (HL),$28                  ;[272E] 
    INC   HL                        ;[2730] 
    INC   DE                        ;[2731] 
    CALL  RP                        ;[2732] 
    RST   $20                       ;[2735] 
    ADD   HL,HL                     ;[2736] 
    LD    (HL),A                    ;[2737] 
    INC   HL                        ;[2738] 
    JP    RST_10                    ;[2739] 

;
; Validation for REM, DATA, EXT, LABEL.
;
VALIDATE_REM:
    LD    A,(DE)                    ;[273C] 
    LD    (HL),A                    ;[273D] 
    CP    $0D                       ;[273E] 
    RET   Z                         ;[2740] 
    INC   HL                        ;[2741] 
    INC   DE                        ;[2742] 
    JR    VALIDATE_REM              ;[2743] 

;
; Validation for SWAP.
;
VALIDATE_SWAP:
    CALL  VALIDATE_READ             ;[2745] 
    LD    (HL),A                    ;[2748] 
    CP    $2C                       ;[2749] 
    JR    NZ,$2756                  ;[274B] 
    INC   HL                        ;[274D] 
    INC   DE                        ;[274E] 
    CALL  VALIDATE_READ             ;[274F] 
    LD    (HL),A                    ;[2752] 
    CP    $0D                       ;[2753] 
    RET   Z                         ;[2755] 
    CALL  ERR_SOMETHG_MISSG         ;[2756] 

;
; WRA1 to WRA2
;
WRA1_TO_WRA2:
    LD    DE,SYSVAR_WRA2            ;[2759] 

;
; Copy WRA1 to where DE points.
;
WRA1_TO_DE:
    LD    HL,SYSVAR_WRA1            ;[275C] 
    LD    BC,$0005                  ;[275F] 
    LDIR                            ;[2762] 
    RET                             ;[2764] 

;
; Input line process?
;
INPLNP:
    LD    A,(SYSVAR_AUTOFL)         ;[2765] 
    OR    A                         ;[2768] 
    JP    Z,SUB_FIND                ;[2769] 
    PUSH  HL                        ;[276C] 
    LD    HL,SYSVAR_AUTOST          ;[276D] 
    PUSH  DE                        ;[2770] 
    CALL  LNUM1                     ;[2771] 
    POP   DE                        ;[2774] 
    POP   HL                        ;[2775] 
    JP    INPLN3                    ;[2776] 
INPLN:
    CALL  INPLNP                    ;[2779] Line analysis subroutine.
    INC   HL                        ;[277C] 
    LD    (HL),$80                  ;[277D] 
    LD    DE,(SYSVAR_POLBUF)        ;[277F] 
    PUSH  DE                        ;[2783] 
    POP   IX                        ;[2784] 
    OR    A                         ;[2786] 
    SBC   HL,DE                     ;[2787] 
    XOR   A                         ;[2789] 
    CP    H                         ;[278A] 
    CALL  NZ,ERR_LINE_TOO_LONG      ;[278B] 
    LD    (IX+$05),L                ;[278E] 
    RET                             ;[2791] 

;
; Part of the find logic for looking at words in a list.
;
SUB_FIND:
    RST   $10                       ;[2792] 
    CALL  RDN                       ;[2793] 
INPLN3:
    LD    A,(SYSVAR_WRA1)           ;[2796] 
    BIT   7,A                       ;[2799] 
    JP    Z,IERR                    ;[279B] 
    PUSH  DE                        ;[279E] 
    LD    DE,(SYSVAR_POLBUF)        ;[279F] 
    CALL  WRA1_TO_DE                ;[27A3] 
    EX    DE,HL                     ;[27A6] 
    INC   HL                        ;[27A7] 
    POP   DE                        ;[27A8] 
IL1:
    RST   $10                       ;[27A9] Validation for ELSE.
    CALL  SYSVAR_INPLSUB            ;[27AA] 
IL4:
    PUSH  HL                        ;[27AD] 
    LD    HL,(SYSVAR_XTTBL)         ;[27AE] 
    LD    B,(HL)                    ;[27B1] 
    PUSH  BC                        ;[27B2] 
    CALL  $1949                     ;[27B3] 
    JP    C,$2676                   ;[27B6] 
    POP   AF                        ;[27B9] 
    SUB   B                         ;[27BA] 
    POP   HL                        ;[27BB] 
IL2:
    LD    (HL),A                    ;[27BC] 
    INC   HL                        ;[27BD] 
    LD    IX,(SYSVAR_XITBL)         ;[27BE] 
IL3:
    RLCA                            ;[27C2] 
    LD    C,A                       ;[27C3] 
    LD    B,$00                     ;[27C4] 
    ADD   IX,BC                     ;[27C6] 
    LD    C,(IX+$00)                ;[27C8] 
    LD    B,(IX+$01)                ;[27CB] 
    PUSH  BC                        ;[27CE] 
    JP    RST_10                    ;[27CF] 

;
; Print a word from a list (6219).
;
SUB_PRINT_KEYWORD:
    CALL  OUTPUT_SPACE              ;[27D2] 
    LD    HL,(SYSVAR_XTTBL)         ;[27D5] 
    LD    B,A                       ;[27D8] 
    INC   B                         ;[27D9] 
    CALL  TOKEN_TO_WORD_FIND        ;[27DA] 
    CALL  PNE15                     ;[27DD] 
    CALL  OUTPUT_SPACE              ;[27E0] 
    INC   DE                        ;[27E3] 
    RET                             ;[27E4] 

;
; Display BASIC line. (via SYSVAR_DBASLN)
;
DBASLN:
    PUSH  IX                        ;[27E5] 
    POP   HL                        ;[27E7] 
    PUSH  HL                        ;[27E8] 
    CALL  LNUM1                     ;[27E9] Line number
    CALL  PN                        ;[27EC] 
    CALL  TEST_IS_LOOP_END          ;[27EF] Handle loop indentation
    CALL  SUB_INDENT                ;[27F2] 
    CALL  SKIP_LNUM                 ;[27F5] 
DBASLN1:
    LD    A,(DE)                    ;[27F8] Line length
    PUSH  AF                        ;[27F9] 
    CALL  SUB_PRINT_KEYWORD         ;[27FA] 
    POP   AF                        ;[27FD] 
    CP    $3C                       ;[27FE] 
    JR    Z,DBASLN1                 ;[2800] 
    CP    $33                       ;[2802] 
    JP    Z,PRINT_BAS_LINE          ;[2804] 
    DEC   DE                        ;[2807] 
DBASLN2:
    INC   DE                        ;[2808] 
DBASLN3:
    LD    A,(DE)                    ;[2809] 
    CP    $7B                       ;[280A] 
    RET   Z                         ;[280C] 
    CP    $0D                       ;[280D] 
    JR    Z,DO_INDENT               ;[280F] 
    CP    $7D                       ;[2811] 
    JR    Z,DBASLN4                 ;[2813] 
    CP    $80                       ;[2815] 
    JR    NC,DBASLN5                ;[2817] 
    RST   $08                       ;[2819] 
    CP    $22                       ;[281A] 
    JR    NZ,DBASLN2                ;[281C] 
    CALL  PRINT_STRING              ;[281E] 
    RST   $08                       ;[2821] 
    JR    DBASLN2                   ;[2822] 
DBASLN4:
    INC   DE                        ;[2824] 
    CALL  SYSVAR_PP                 ;[2825] 
    JR    DBASLN2                   ;[2828] 
DBASLN5:
    CP    $DF                       ;[282A] 
    PUSH  AF                        ;[282C] 
    CALL  C,OUTPUT_SPACE            ;[282D] 
    CALL  PNE1                      ;[2830] 
    POP   AF                        ;[2833] 
    PUSH  AF                        ;[2834] 
    CALL  C,OUTPUT_SPACE            ;[2835] 
    POP   AF                        ;[2838] 
    INC   DE                        ;[2839] 
    CP    $D7                       ;[283A] 
    JR    Z,DBASLN1                 ;[283C] 
    JR    DBASLN3                   ;[283E] 
DO_INDENT:
    POP   IX                        ;[2840] 
    CALL  INDENT_IF_LOOP            ;[2842] 
    LD    A,$1E                     ;[2845] Clear to end of line
    RST   $08                       ;[2847] 
    LD    A,$1F                     ;[2848] CR/LF
    RST   $08                       ;[284A] 
    RET                             ;[284B] 

;
; Test for FOR, WHILE and REPEAT.
;
INDENT_IF_LOOP:
    LD    A,(IX+$06)                ;[284C] 
    CP    $36                       ;[284F] 
    JR    Z,INDENT_SPACES           ;[2851] 
    CP    $0F                       ;[2853] 
    JR    Z,INDENT_SPACES           ;[2855] 
    CP    $38                       ;[2857] 
    RET   NZ                        ;[2859] 
INDENT_SPACES:
    LD    HL,SYSVAR_SBC             ;[285A] 
    INC   (HL)                      ;[285D] 
    RET                             ;[285E] 

;
; Test for NEXT, WEND and UNTIL.
;
TEST_IS_LOOP_END:
    LD    A,(IX+$06)                ;[285F] 
    CP    $37                       ;[2862] 
    JR    Z,$286D                   ;[2864] 
    CP    $05                       ;[2866] 
    JR    Z,$286D                   ;[2868] 
    CP    $39                       ;[286A] 
    RET   NZ                        ;[286C] 
    LD    A,(SYSVAR_SBC)            ;[286D] 
    OR    A                         ;[2870] 
    RET   Z                         ;[2871] 
    DEC   A                         ;[2872] 
    LD    (SYSVAR_SBC),A            ;[2873] 
    RET                             ;[2876] 

;
; Print spaces for indentation
;
SUB_INDENT:
    LD    A,(SYSVAR_SBC)            ;[2877] 
    OR    A                         ;[287A] 
    RET   Z                         ;[287B] No indent? Return.
    CP    $0A                       ;[287C] 
    JR    C,SUB_INDENT1             ;[287E] 
    LD    A,$0A                     ;[2880] Max 10 indents.
SUB_INDENT1:
    RLCA                            ;[2882] 
    LD    B,A                       ;[2883] 
SUB_INDENT_LOOP:
    CALL  OUTPUT_SPACE              ;[2884] 
    DJNZ  SUB_INDENT_LOOP           ;[2887] 
    RET                             ;[2889] 

;
; AUTO.
;
BASIC_COM_AUTO:
    LD    HL,DATA_AUTO              ;[288A] 
    PUSH  DE                        ;[288D] 
    LD    DE,SYSVAR_AUTOST          ;[288E] 
    LD    BC,$000A                  ;[2891] 
    LDIR                            ;[2894] 
    POP   DE                        ;[2896] 
    CP    $0D                       ;[2897] 
    JR    Z,$28C9                   ;[2899] 
    RST   $28                       ;[289B] 
    LD    A,(SYSVAR_WRA1)           ;[289C] 
    PUSH  DE                        ;[289F] 
    CP    $C0                       ;[28A0] 
    CALL  C,ERR_NUM_OUT_RANGE       ;[28A2] 
    CP    $C7                       ;[28A5] 
    CALL  NC,ERR_NUM_OUT_RANGE      ;[28A7] 
    LD    DE,SYSVAR_AUTOST          ;[28AA] 
    CALL  WRA1_TO_DE                ;[28AD] 
    POP   DE                        ;[28B0] 
    LD    A,(DE)                    ;[28B1] 
    CP    $0D                       ;[28B2] 
    JR    Z,$28C9                   ;[28B4] 
    INC   DE                        ;[28B6] 
    RST   $28                       ;[28B7] 
    LD    A,(SYSVAR_WRA1)           ;[28B8] 
    CP    $C0                       ;[28BB] 
    JR    C,$28A2                   ;[28BD] 
    CP    $F0                       ;[28BF] 
    JR    NC,$28A7                  ;[28C1] 
    LD    DE,$62F8                  ;[28C3] 
    CALL  WRA1_TO_DE                ;[28C6] 
    LD    A,$01                     ;[28C9] 
    LD    (SYSVAR_AUTOFL),A         ;[28CB] 
    RET                             ;[28CE] 

;
; Data for AUTO. The numbers 100 and 10.
;
DATA_AUTO:
    DB $C2,$10,$00,$00,$00,$C1,$10,$00      ;[28CF]  ........
    DB $00,$00                              ;[28D7]  ..

;
; BIN.
;
BASIC_FN_BIN:
    LD    A,(SYSVAR_WRA1)           ;[28D9] 
    CP    $C0                       ;[28DC] 
    JP    C,LZERO                   ;[28DE] 
    CP    $C8                       ;[28E1] 
    CALL  NC,ERR_TYPE_MISMATCH      ;[28E3] 
    SUB   $BF                       ;[28E6] 
    LD    B,A                       ;[28E8] 
    LD    C,$00                     ;[28E9] 
    PUSH  BC                        ;[28EB] 
    CALL  RL10                      ;[28EC] 
    POP   BC                        ;[28EF] 
    AND   $0F                       ;[28F0] 
    CP    $02                       ;[28F2] 
    CALL  NC,ERR_TYPE_MISMATCH      ;[28F4] 
    CP    $01                       ;[28F7] 
    CCF                             ;[28F9] 
    RL    C                         ;[28FA] 
    DJNZ  $28EB                     ;[28FC] 
    LD    L,C                       ;[28FE] 
    LD    H,$00                     ;[28FF] 
    JP    INTFP                     ;[2901] 

;
; Load (DE) to (HL) testing for CR and (.
;
BASIC_COM_PROC:
    LD    HL,(SYSVAR_CURRLP)        ;[2904] 
    CALL  PUSH_HL_RSTACK            ;[2907] 
    LD    A,$04                     ;[290A] 
    CALL  PUSH_A_RSTACK             ;[290C] 
    LD    C,$02                     ;[290F] 
    LD    HL,(SYSVAR_PROCST)        ;[2911] 
    LD    A,L                       ;[2914] 
    OR    H                         ;[2915] 
    PUSH  HL                        ;[2916] 
    POP   IX                        ;[2917] 
    CALL  Z,$293F                   ;[2919] 
    LD    C,$02                     ;[291C] 
    CALL  EGT3                      ;[291E] 
    CP    $0D                       ;[2921] 
    RET   Z                         ;[2923] 
    LD    A,(DE)                    ;[2924] 
    CP    $29                       ;[2925] 
    RET   Z                         ;[2927] 
    INC   HL                        ;[2928] 
    INC   DE                        ;[2929] 
    PUSH  HL                        ;[292A] 
    RST   $28                       ;[292B] 
    POP   HL                        ;[292C] 
    PUSH  DE                        ;[292D] 
    EX    DE,HL                     ;[292E] 
    CALL  GET_VAR_ADDR              ;[292F] 
    PUSH  DE                        ;[2932] 
    INC   HL                        ;[2933] 
    RES   7,(HL)                    ;[2934] 
    DEC   HL                        ;[2936] 
    EX    DE,HL                     ;[2937] 
    CALL  WRA1_TO_DE                ;[2938] 
    POP   HL                        ;[293B] 
    POP   DE                        ;[293C] 
    JR    $2924                     ;[293D] 
    LD    IX,(SYSVAR_SOB)           ;[293F] 
    CALL  FTL                       ;[2943] 
    CALL  C,ERR_NOT_FOUND           ;[2946] 
    LD    (SYSVAR_PROCST),IX        ;[2949] 
    RET                             ;[294D] 

    LD    A,(DE)                    ;[294E] 
    INC   DE                        ;[294F] 
    LD    (HL),A                    ;[2950] 
    CP    $0D                       ;[2951] 
    JR    Z,$295B                   ;[2953] 
    INC   HL                        ;[2955] 
    CP    $28                       ;[2956] 
    JR    NZ,$294E                  ;[2958] 
    RET                             ;[295A] 

    POP   BC                        ;[295B] 
    RET                             ;[295C] 

;
; Validation for PROC.
;
VALIDATE_PROC:
    CALL  $294E                     ;[295D] 
    CALL  RP                        ;[2960] 
    LD    (HL),A                    ;[2963] 
    INC   HL                        ;[2964] 
    CP    $2C                       ;[2965] 
    JR    Z,$2960                   ;[2967] 
    RST   $20                       ;[2969] 
    ADD   HL,HL                     ;[296A] 
    RST   $10                       ;[296B] 
    JP    VALIDATE_MON              ;[296C] 

;
; Validation for DEFPPOC.
;
VALIDATE_DEFPROC:
    CALL  $294E                     ;[296F] 
    RST   $10                       ;[2972] 
    CALL  TEST_ALPHA                ;[2973] 
    CALL  C,ERR_SYNTAX              ;[2976] 
    LD    (HL),A                    ;[2979] 
    INC   DE                        ;[297A] 
    RST   $10                       ;[297B] 
    INC   HL                        ;[297C] 
    LD    A,(DE)                    ;[297D] 
    LD    (HL),A                    ;[297E] 
    INC   HL                        ;[297F] 
    INC   DE                        ;[2980] 
    CP    $2C                       ;[2981] 
    JR    Z,$2972                   ;[2983] 
    JP    $2969                     ;[2985] 

;
; ENDPROC.
;
BASIC_COM_ENDPROC:
    CALL  POP_A_RSTACK              ;[2988] 
    CP    $04                       ;[298B] 
    CALL  NZ,ERR_ENDPROC_NO_PROC    ;[298D] 
    JP    EEPRN1                    ;[2990] 

;
; Part of the PRINT routine.
;
SUB_PRINT:
    INC   DE                        ;[2993] 
    RST   $28                       ;[2994] 
    PUSH  DE                        ;[2995] 
    CALL  FPINT                     ;[2996] 
    POP   DE                        ;[2999] 
    CALL  PHEXHL                    ;[299A] 
    LD    A,$48                     ;[299D] 
    RST   $08                       ;[299F] 
    JP    BASIC_COM_PRINT           ;[29A0] 
    RST   $28                       ;[29A3] 
    PUSH  DE                        ;[29A4] 
    CALL  PN                        ;[29A5] 
    POP   DE                        ;[29A8] 

;
; PRINT.
;
BASIC_COM_PRINT:
    LD    C,$00                     ;[29A9] 
BASIC_COM_PRINT0:
    LD    A,(DE)                    ;[29AB] 
    CP    $0D                       ;[29AC] 
    JR    Z,BASIC_COM_PRINT1        ;[29AE] Do carriage return
    CP    $2C                       ;[29B0] 
    JR    Z,PRINT_TAB               ;[29B2] Do comma
    CP    $3B                       ;[29B4] 
    JR    Z,$29E0                   ;[29B6] Do semicolon
    CP    $23                       ;[29B8] 
    JR    Z,SUB_PRINT               ;[29BA] Do hash #
    CP    $7D                       ;[29BC] 
    JR    Z,$29A3                   ;[29BE] Do close brace }
    CP    $DE                       ;[29C0] 
    JP    Z,PRINT_EXPR              ;[29C2] 
    CP    $D9                       ;[29C5] 
    JP    Z,PRINT_AT                ;[29C7] 
    CALL  STRING_EXEC               ;[29CA] 
    LD    HL,SYSVAR_STRBUF          ;[29CD] 
    CALL  PRTSTR                    ;[29D0] 
    JP    BASIC_COM_PRINT           ;[29D3] 
BASIC_COM_PRINT1:
    LD    A,C                       ;[29D6] 
    OR    A                         ;[29D7] 
    RET   NZ                        ;[29D8] 
    LD    A,$0D                     ;[29D9] Print CR
    RST   $08                       ;[29DB] 
    RET                             ;[29DC] 

;
; Print TAB char
;
PRINT_TAB:
    LD    A,$09                     ;[29DD] 
    RST   $08                       ;[29DF] 
    LD    C,$01                     ;[29E0] 
    INC   DE                        ;[29E2] 
    JR    BASIC_COM_PRINT0          ;[29E3] 

;
; Print expression?
;
PRINT_EXPR:
    INC   DE                        ;[29E5] 
    RST   $18                       ;[29E6] Evaluate expression
    RLCA                            ;[29E7] 
    ADD   A,L                       ;[29E8] 
    LD    HL,(SYSVAR_CURSORX)       ;[29E9] 
    CP    L                         ;[29EC] 
    JR    C,PRINT_NEXT              ;[29ED] 
    LD    (SYSVAR_CURSORX),A        ;[29EF] 
    LD    A,$1E                     ;[29F2] 
    RST   $08                       ;[29F4] 
PRINT_NEXT:
    JP    BASIC_COM_PRINT           ;[29F5] 

;
; Print @ x,y ?
;
PRINT_AT:
    INC   DE                        ;[29F8] 
    RST   $18                       ;[29F9] 
    LD    (SYSVAR_CURSORX),HL       ;[29FA] 
    INC   DE                        ;[29FD] 
    RST   $18                       ;[29FE] 
    LD    (SYSVAR_CURSORY),A        ;[29FF] 
    JR    PRINT_NEXT                ;[2A02] 
    LD    (HL),A                    ;[2A04] 
    INC   DE                        ;[2A05] 
    INC   HL                        ;[2A06] 
    JR    VALIDATE_PRINT1A          ;[2A07] 
    CALL  READ_STRING_EXPR          ;[2A09] 
    JR    $2A10                     ;[2A0C] 
    INC   HL                        ;[2A0E] 
    INC   DE                        ;[2A0F] 
    RST   $10                       ;[2A10] 

;
; Validation for PRINT.
;
VALIDATE_PRINT1:
    LD    (HL),A                    ;[2A11] 
    CP    $0D                       ;[2A12] 
    RET   Z                         ;[2A14] 
    CP    $23                       ;[2A15] 
    JR    Z,$2A04                   ;[2A17] 
    CP    $2C                       ;[2A19] 
    JR    Z,$2A0E                   ;[2A1B] 
    CP    $3B                       ;[2A1D] 
    JR    Z,$2A0E                   ;[2A1F] 
    CALL  TEST_FOR_STR_EXP          ;[2A21] 
    JR    Z,$2A09                   ;[2A24] 
    PUSH  DE                        ;[2A26] 
    CALL  TKSL                      ;[2A27] 
    JR    C,$2A42                   ;[2A2A] 
    CP    $DE                       ;[2A2C] 
    JR    Z,$2A3E                   ;[2A2E] 
    CP    $D9                       ;[2A30] 
    JR    NZ,$2A42                  ;[2A32] 
    POP   BC                        ;[2A34] 
    LD    (HL),A                    ;[2A35] 
    INC   HL                        ;[2A36] 
    CALL  RP                        ;[2A37] 
    RST   $20                       ;[2A3A] 
    INC   L                         ;[2A3B] 
    JR    $2A3F                     ;[2A3C] 
    POP   BC                        ;[2A3E] 
    LD    (HL),A                    ;[2A3F] 
    INC   HL                        ;[2A40] 
    PUSH  DE                        ;[2A41] 
    POP   DE                        ;[2A42] 
VALIDATE_PRINT1A:
    CALL  RP                        ;[2A43] 
    CP    $80                       ;[2A46] 
    CALL  NC,ERR_SYNTAX             ;[2A48] 
    DEC   DE                        ;[2A4B] 
    JR    VALIDATE_PRINT1           ;[2A4C] 

;
; RESERVE.
;
BASIC_COM_RESERVE:
    RST   $18                       ;[2A4E] 
    EX    DE,HL                     ;[2A4F] 
    LD    HL,(SYSVAR_STACK)         ;[2A50] 
    INC   HL                        ;[2A53] 
    INC   HL                        ;[2A54] 
    PUSH  HL                        ;[2A55] 
    OR    A                         ;[2A56] 
    SBC   HL,DE                     ;[2A57] 
    CALL  C,ERR_NUM_OUT_RANGE       ;[2A59] 
    LD    HL,(SYSVAR_TOV)           ;[2A5C] 
    INC   H                         ;[2A5F] 
    INC   H                         ;[2A60] 
    SBC   HL,DE                     ;[2A61] 
    CALL  NC,ERR_NUM_OUT_RANGE      ;[2A63] 
    POP   HL                        ;[2A66] 
    DEC   H                         ;[2A67] 
    DEC   D                         ;[2A68] 
    LD    BC,$0100                  ;[2A69] 
    LDIR                            ;[2A6C] 
    OR    A                         ;[2A6E] 
    EX    DE,HL                     ;[2A6F] 
    SBC   HL,DE                     ;[2A70] 
    EX    DE,HL                     ;[2A72] 
    LD    HL,(SYSVAR_STACK)         ;[2A73] 
    ADD   HL,DE                     ;[2A76] 
    LD    (SYSVAR_STACK),HL         ;[2A77] 
    EX    DE,HL                     ;[2A7A] 
    ADD   HL,SP                     ;[2A7B] 
    LD    SP,HL                     ;[2A7C] 
    RET                             ;[2A7D] 

;
; RENUM
;
BASIC_COM_RENUM:
    CALL  BASIC_COM_AUTO            ;[2A7E] 
    XOR   A                         ;[2A81] 
    LD    (SYSVAR_AUTOFL),A         ;[2A82] 
    LD    IX,(SYSVAR_SOB)           ;[2A85] 
    LD    A,(IX+$00)                ;[2A89] 
    CP    $80                       ;[2A8C] 
    JR    Z,$2AF1                   ;[2A8E] 
    PUSH  IX                        ;[2A90] 
    CALL  SKIP_LNUM                 ;[2A92] 
    LD    A,(DE)                    ;[2A95] 
    CP    $27                       ;[2A96] 
    JR    NZ,$2AA4                  ;[2A98] 
    CALL  ADV                       ;[2A9A] 
    LD    A,(DE)                    ;[2A9D] 
    CP    $D7                       ;[2A9E] 
    JR    NZ,$2A9A                  ;[2AA0] 
    INC   DE                        ;[2AA2] 
    LD    A,(DE)                    ;[2AA3] 
    CP    $3C                       ;[2AA4] 
    JR    NZ,$2AAA                  ;[2AA6] 
    INC   DE                        ;[2AA8] 
    LD    A,(DE)                    ;[2AA9] 
    CP    $10                       ;[2AAA] 
    JR    Z,$2ABA                   ;[2AAC] 
    CP    $14                       ;[2AAE] 
    JR    Z,$2ABA                   ;[2AB0] 
    CP    $11                       ;[2AB2] 
    JR    Z,$2ABA                   ;[2AB4] 
    CP    $20                       ;[2AB6] 
    JR    NZ,$2AEA                  ;[2AB8] 
    INC   DE                        ;[2ABA] 
    LD    A,(DE)                    ;[2ABB] 
    CP    $7D                       ;[2ABC] 
    JR    NZ,$2AEA                  ;[2ABE] 
    INC   DE                        ;[2AC0] 
    LD    A,(DE)                    ;[2AC1] 
    CP    $7E                       ;[2AC2] 
    JR    NZ,$2AEA                  ;[2AC4] 
    INC   DE                        ;[2AC6] 
    PUSH  DE                        ;[2AC7] 
    EX    DE,HL                     ;[2AC8] 
    CALL  LNUM1                     ;[2AC9] 
    CALL  FNDLN_WRA1                ;[2ACC] 
    LD    L,C                       ;[2ACF] 
    LD    H,B                       ;[2AD0] 
    CALL  INTFP                     ;[2AD1] 
    LD    HL,$62F8                  ;[2AD4] 
    CALL  LNUM2                     ;[2AD7] 
    CALL  _MULT                     ;[2ADA] 
    LD    HL,SYSVAR_AUTOST          ;[2ADD] 
    CALL  LNUM2                     ;[2AE0] 
    CALL  ADD                       ;[2AE3] 
    POP   DE                        ;[2AE6] 
    CALL  WRA1_TO_DE                ;[2AE7] 
    POP   IX                        ;[2AEA] 
    CALL  NEXT_LINE                 ;[2AEC] 
    JR    $2A89                     ;[2AEF] 
    LD    IX,(SYSVAR_SOB)           ;[2AF1] 
    LD    HL,SYSVAR_AUTOST          ;[2AF5] 
    CALL  LNUM1                     ;[2AF8] 
    LD    A,(IX+$00)                ;[2AFB] 
    CP    $80                       ;[2AFE] 
    RET   Z                         ;[2B00] 
    PUSH  IX                        ;[2B01] 
    POP   DE                        ;[2B03] 
    PUSH  DE                        ;[2B04] 
    CALL  WRA1_TO_DE                ;[2B05] 
    LD    HL,$62F8                  ;[2B08] 
    CALL  LNUM2                     ;[2B0B] 
    CALL  ADD                       ;[2B0E] 
    POP   IX                        ;[2B11] 
    CALL  NEXT_LINE                 ;[2B13] 
    JR    $2AFB                     ;[2B16] 

;
; Find BASIC line (in WRA1) and Let IX = line address. Otherwise display not found.
;
FINDLN:
    CALL  FNDLN_WRA1                ;[2B18] 
    CALL  NZ,ERR_NOT_FOUND          ;[2B1B] 
    RET                             ;[2B1E] 

;
; Finds line with number in WRA1. IX points to line and z flag set if found, 
; else IX points to next highest line.
;
FNDLN_WRA1:
    LD    IX,(SYSVAR_SOB)           ;[2B1F] 
    LD    BC,$0000                  ;[2B23] 
    LD    A,(IX+$00)                ;[2B26] 
    CP    $80                       ;[2B29] 
    JR    Z,$2B49                   ;[2B2B] 
    PUSH  IX                        ;[2B2D] 
    POP   DE                        ;[2B2F] 
    LD    HL,SYSVAR_WRA1            ;[2B30] 
    PUSH  BC                        ;[2B33] 
    LD    B,$05                     ;[2B34] 
    LD    A,(DE)                    ;[2B36] 
    CP    (HL)                      ;[2B37] 
    JR    C,$2B42                   ;[2B38] 
    JR    NZ,$2B40                  ;[2B3A] 
    INC   HL                        ;[2B3C] 
    INC   DE                        ;[2B3D] 
    DJNZ  $2B36                     ;[2B3E] 
    POP   BC                        ;[2B40] 
    RET                             ;[2B41] 

    POP   BC                        ;[2B42] 
    INC   BC                        ;[2B43] 
    CALL  NEXT_LINE                 ;[2B44] 
    JR    $2B26                     ;[2B47] 
    OR    A                         ;[2B49] 
    RET                             ;[2B4A] 

;
; Test for start of string expression.
;
TEST_FOR_STR_EXP:
    RST   $10                       ;[2B4B] 
    CP    $22                       ;[2B4C] 
    RET   Z                         ;[2B4E] 
    CALL  TEST_FOR_STRING           ;[2B4F] 
    RET   Z                         ;[2B52] 
    PUSH  DE                        ;[2B53] 
    CALL  TKSL                      ;[2B54] 
    POP   DE                        ;[2B57] 
    CP    $DF                       ;[2B58] 
    RET   C                         ;[2B5A] 
    CP    $E7                       ;[2B5B] 
    DEC   A                         ;[2B5D] 
    RET   NC                        ;[2B5E] 
    CP    A                         ;[2B5F] 
    RET                             ;[2B60] 

;
; Line analysis - String expression int?
;
SEINT:
    PUSH  IX                        ;[2B61] 
    LD    A,(DE)                    ;[2B63] 
    RST   $20                       ;[2B64] 
    LD    A,L                       ;[2B65] 
    INC   DE                        ;[2B66] 
    CALL  EE1                       ;[2B67] 
    CALL  FPINT                     ;[2B6A] 
    POP   IX                        ;[2B6D] 
    RET                             ;[2B6F] 

;
; Load A to where IX points. Increment IX.
;
STRDVR:
    LD    (IX+$00),A                ;[2B70] 
    INC   IX                        ;[2B73] 
    RET                             ;[2B75] 

;
; STR$
;
BASIC_FN_STR_STRING:
    PUSH  IX                        ;[2B76] 
    INC   DE                        ;[2B78] Past sop
    CALL  EE1                       ;[2B79] Evaluate
    POP   IX                        ;[2B7C] Restore ptr
    PUSH  DE                        ;[2B7E] Save line ptr
    LD    HL,(SYSVAR_PRINTD)        ;[2B7F] Save scrn dvr
    PUSH  HL                        ;[2B82] 
    LD    HL,STRDVR                 ;[2B83] Change to str dvr
    LD    (SYSVAR_PRINTD),HL        ;[2B86] 
    CALL  PN                        ;[2B89] Print number
    POP   HL                        ;[2B8C] Restore scrn dvr
    LD    (SYSVAR_PRINTD),HL        ;[2B8D] 
    POP   DE                        ;[2B90] Restore line ptr
    JR    ESECT1                    ;[2B91] 

;
; KEY$
;
BASIC_FN_KEY_STRING:
    CALL  KEY                       ;[2B93] 
    OR    A                         ;[2B96] 
    JR    Z,ESECT                   ;[2B97] 

;
; Part of GET$
;
GET_STRING:
    LD    (IX+$00),A                ;[2B99] 
    INC   IX                        ;[2B9C] 
    JR    ESECT                     ;[2B9E] 

;
; GET$
;
BASIC_FN_GET_STRING:
    CALL  KEY                       ;[2BA0] 
    OR    A                         ;[2BA3] 
    JR    Z,BASIC_FN_GET_STRING     ;[2BA4] 
    JR    GET_STRING                ;[2BA6] 

;
; UPC$
;
BASIC_FN_UPC_STRING:
    CALL  SYSVAR_VRPTS              ;[2BA8] 
ESEUP1:
    LD    A,(HL)                    ;[2BAB] 
    CP    $0D                       ;[2BAC] 
    JR    Z,ESECT1                  ;[2BAE] 
    CP    $61                       ;[2BB0] 
    JR    C,ESEUP2                  ;[2BB2] 
    CP    $7B                       ;[2BB4] 
    JR    NC,ESEUP2                 ;[2BB6] 
    RES   5,A                       ;[2BB8] 
ESEUP2:
    LD    (IX+$00),A                ;[2BBA] 
    INC   IX                        ;[2BBD] 
    INC   HL                        ;[2BBF] 
    JR    ESEUP1                    ;[2BC0] 

;
; Left String function?
;
ESECT1:
    INC   DE                        ;[2BC2] 
ESECT:
    PUSH  IX                        ;[2BC3] 
    POP   HL                        ;[2BC5] 
    LD    (HL),SZ                   ;[2BC6] 
    PUSH  HL                        ;[2BC8] 
    LD    BC,SYSVAR_STRBUF          ;[2BC9] 
    OR    A                         ;[2BCC] 
    SBC   HL,BC                     ;[2BCD] 
    INC   H                         ;[2BCF] 
    DEC   H                         ;[2BD0] 
    CALL  NZ,ERR_STRING             ;[2BD1] 
    POP   IX                        ;[2BD4] 
    LD    A,(DE)                    ;[2BD6] 
    CP    $2B                       ;[2BD7] 
    RET   NZ                        ;[2BD9] 
    INC   DE                        ;[2BDA] 
    JR    ESE1                      ;[2BDB] 

;
; String function execution routine. (LEFT$, GET$, KEY$,.etc.)
;
STRING_EXEC:
    LD    IY,SYSVAR_CSTACK          ;[2BDD] 
ESEE:
    LD    IX,SYSVAR_STRBUF          ;[2BE1] 
ESE1:
    LD    A,(DE)                    ;[2BE5] 
    CP    $22                       ;[2BE6] 
    JR    Z,ESE2                    ;[2BE8] 
    CALL  TEST_FOR_STRING           ;[2BEA] 
    JR    Z,ESE3                    ;[2BED] 
    LD    A,(DE)                    ;[2BEF] 
    INC   DE                        ;[2BF0] 
    CP    UPCS                      ;[2BF1] 
    JR    Z,BASIC_FN_UPC_STRING     ;[2BF3] 
    CP    STR                       ;[2BF5] 
    JP    Z,BASIC_FN_STR_STRING     ;[2BF7] 
    CP    GETS                      ;[2BFA] 
    JR    Z,BASIC_FN_GET_STRING     ;[2BFC] 
    CP    INKEYS                    ;[2BFE] 
    JR    Z,BASIC_FN_KEY_STRING     ;[2C00] 
    CP    CHR                       ;[2C02] 
    JR    Z,BASIC_FN_CHR_STRING     ;[2C04] 
    CP    LEFT                      ;[2C06] 
    JR    Z,BASIC_FN_LEFT_STRING    ;[2C08] 
    CP    RIGHT                     ;[2C0A] 
    JR    Z,BASIC_FN_RIGHT_STRING   ;[2C0C] 
    CP    MID                       ;[2C0E] 
    JR    Z,BASIC_FN_MID_STRING     ;[2C10] 
    CALL  ERR_SOMETHG_MISSG         ;[2C12] 
ESE2:
    INC   DE                        ;[2C15] 
    LD    B,$00                     ;[2C16] 
    EX    DE,HL                     ;[2C18] 
    CALL  STRING_SEEK_END           ;[2C19] 
    EX    DE,HL                     ;[2C1C] 
    INC   DE                        ;[2C1D] 
    JR    ESECT                     ;[2C1E] 
ESE3:
    CALL  SYSVAR_VRPTS              ;[2C20] 
    CALL  STRING_SEEK_END           ;[2C23] 
    JR    ESECT                     ;[2C26] 

;
; CHR$ (aka ESE4)
;
BASIC_FN_CHR_STRING:
    CALL  SEINT                     ;[2C28] 
    LD    (IX+$00),L                ;[2C2B] 
    INC   IX                        ;[2C2E] 
    JR    ESECT1                    ;[2C30] 

;
; LEFT$ (aka ESE5)
;
BASIC_FN_LEFT_STRING:
    CALL  SYSVAR_VRPTS              ;[2C32] 
    PUSH  HL                        ;[2C35] 
    INC   DE                        ;[2C36] 
    CALL  SEINT                     ;[2C37] 
    LD    B,L                       ;[2C3A] 
    POP   HL                        ;[2C3B] 
    CALL  PATCH6                    ;[2C3C] 
    JR    ESECT1                    ;[2C3F] 

;
; MID$ (aka ESE7)
;
BASIC_FN_MID_STRING:
    CALL  SYSVAR_VRPTS              ;[2C41] 
    INC   DE                        ;[2C44] 
    PUSH  HL                        ;[2C45] 
    CALL  SEINT                     ;[2C46] 
    INC   DE                        ;[2C49] 
    PUSH  HL                        ;[2C4A] 
    CALL  SEINT                     ;[2C4B] 
    LD    C,L                       ;[2C4E] 
    POP   HL                        ;[2C4F] 
    LD    B,L                       ;[2C50] 
ESE72:
    POP   HL                        ;[2C51] 
ESE71:
    LD    A,(HL)                    ;[2C52] 
    CP    $0D                       ;[2C53] 
    JP    Z,ESECT1                  ;[2C55] 
    INC   HL                        ;[2C58] 
    DJNZ  ESE71                     ;[2C59] 
    DEC   HL                        ;[2C5B] 
    LD    B,C                       ;[2C5C] 
    CALL  PATCH6                    ;[2C5D] 
    JP    ESECT1                    ;[2C60] 

;
; RIGHT$ (aka ESE6)
;
BASIC_FN_RIGHT_STRING:
    CALL  SYSVAR_VRPTS              ;[2C63] 
    INC   DE                        ;[2C66] 
    PUSH  HL                        ;[2C67] 
    CALL  SEINT                     ;[2C68] 
    LD    C,L                       ;[2C6B] 
    POP   HL                        ;[2C6C] 
    PUSH  HL                        ;[2C6D] 
    LD    B,$00                     ;[2C6E] 
ESE61:
    INC   B                         ;[2C70] 
    LD    A,(HL)                    ;[2C71] 
    INC   HL                        ;[2C72] 
    CP    $0D                       ;[2C73] 
    JR    NZ,ESE61                  ;[2C75] 
    LD    A,B                       ;[2C77] 
    SUB   C                         ;[2C78] 
    CALL  C,ERR_STRING              ;[2C79] 
    LD    B,A                       ;[2C7C] 
    JR    ESE72                     ;[2C7D] 

;
; Returns when it sees quote " or CR (aka RSIB)
; Read string into buffer.
;
STRING_SEEK_END:
    LD    A,(HL)                    ;[2C7F] 
    CP    $22                       ;[2C80] 
    RET   Z                         ;[2C82] 
    CP    SZ                        ;[2C83] 
    RET   Z                         ;[2C85] 
    LD    (IX+$00),A                ;[2C86] 
    INC   IX                        ;[2C89] 
    INC   HL                        ;[2C8B] 
    DJNZ  STRING_SEEK_END           ;[2C8C] 
    RET                             ;[2C8E] 

;
; String expr upper case?
;
RSEUPC:
    CALL  READ_STRING_VAR           ;[2C8F] 
    RST   $10                       ;[2C92] 
    CP    ')'                       ;[2C93] 
    LD    (HL),A                    ;[2C95] 
    INC   HL                        ;[2C96] 
    INC   DE                        ;[2C97] 
    CALL  NZ,ERR_MISSING_BRACKET    ;[2C98] 
    JR    RSE8                      ;[2C9B] 

;
; Read string expression (aka RSE)
;
READ_STRING_EXPR:
    CALL  TEST_FOR_STRING           ;[2C9D] 
    JR    Z,RSE7                    ;[2CA0] 
    CALL  TKSL                      ;[2CA2] 
    LD    (HL),A                    ;[2CA5] 
    INC   HL                        ;[2CA6] 
    JR    NC,RSE1                   ;[2CA7] 
    DEC   HL                        ;[2CA9] 
    CALL  VALIDATE_UTILITY          ;[2CAA] 
RSE8:
    RST   $10                       ;[2CAD] 
RSE6:
    CP    '+'                       ;[2CAE] 
    RET   NZ                        ;[2CB0] 
    INC   DE                        ;[2CB1] 
    LD    (HL),A                    ;[2CB2] 
    INC   HL                        ;[2CB3] 
    JR    READ_STRING_EXPR          ;[2CB4] 
RSE1:
    CP    CHR                       ;[2CB6] 
    JR    Z,RSE2                    ;[2CB8] 
    CP    STR                       ;[2CBA] 
    JR    Z,RSE2                    ;[2CBC] 
    CP    INKEYS                    ;[2CBE] 
    JR    Z,RSE8                    ;[2CC0] 
    CP    GETS                      ;[2CC2] 
    JR    Z,RSE8                    ;[2CC4] 
    CP    UPCS                      ;[2CC6] 
    JR    Z,RSEUPC                  ;[2CC8] 
    CP    MID                       ;[2CCA] 
    JR    Z,RSE3                    ;[2CCC] 
    CP    LEFT                      ;[2CCE] 
    JR    Z,RSE5                    ;[2CD0] 
    CP    RIGHT                     ;[2CD2] 
    CALL  NZ,ERR_SOMETHG_MISSG      ;[2CD4] 
RSE5:
    CALL  TEST_FOR_STRING           ;[2CD7] 
RSEN:
    CALL  NZ,ERR_SYNTAX             ;[2CDA] 
    CALL  READ_STRING_VAR           ;[2CDD] 
    RST   $10                       ;[2CE0] 
    INC   DE                        ;[2CE1] 
RSE4:
    CP    ','                       ;[2CE2] 
    JR    NZ,RSEN                   ;[2CE4] 
    LD    (HL),A                    ;[2CE6] 
    INC   HL                        ;[2CE7] 
RSE2:
    DEC   DE                        ;[2CE8] 
    CALL  $2731                     ;[2CE9] 
    JR    RSE6                      ;[2CEC] 
RSE3:
    CALL  TEST_FOR_STRING           ;[2CEE] 
    JR    NZ,RSEN                   ;[2CF1] 
    CALL  READ_STRING_VAR           ;[2CF3] 
    RST   $10                       ;[2CF6] 
    INC   DE                        ;[2CF7] 
    CP    ','                       ;[2CF8] 
    JR    NZ,RSEN                   ;[2CFA] 
    LD    (HL),A                    ;[2CFC] 
    INC   HL                        ;[2CFD] 
    CALL  RP                        ;[2CFE] 
    JR    RSE4                      ;[2D01] 
RSE7:
    CALL  READ_STRING_VAR           ;[2D03] 
    JR    RSE8                      ;[2D06] 

;
; Save HL, Call P$TK
;
TKSL:
    PUSH  HL                        ;[2D08] 
    CALL  TK                        ;[2D09] 
    POP   HL                        ;[2D0C] 
    RET                             ;[2D0D] 

;
; VAL(. Note left bracket is part of the word.
;
BASIC_FN_VAL:
    LD    DE,SYSVAR_STRBUF          ;[2D0E] 
    JP    RDN                       ;[2D11] 

;
; LEN(.
;
BASIC_FN_LEN:
    LD    HL,SYSVAR_STRBUF          ;[2D14] 
    LD    B,$FF                     ;[2D17] 
FLEN1:
    INC   B                         ;[2D19] 
    LD    A,(HL)                    ;[2D1A] 
    INC   HL                        ;[2D1B] 
    CP    $0D                       ;[2D1C] 
    JR    NZ,FLEN1                  ;[2D1E] 
    LD    L,B                       ;[2D20] 
FASC1:
    LD    H,$00                     ;[2D21] 
    JP    INTFP                     ;[2D23] 

;
; ASC(.
;
BASIC_FN_ASC:
    LD    HL,SYSVAR_STRBUF          ;[2D26] 
    LD    L,(HL)                    ;[2D29] 
    JR    FASC1                     ;[2D2A] 

;
; String array
;
VRPTSA:
    CALL  VRPTSP                    ;[2D2C] 
    PUSH  IX                        ;[2D2F] 
    DEC   HL                        ;[2D31] 
    PUSH  HL                        ;[2D32] 
    INC   B                         ;[2D33] B=length of string store
    PUSH  BC                        ;[2D34] area per element-1
    INC   DE                        ;[2D35] 
    CALL  SEINT                     ;[2D36] 
    INC   DE                        ;[2D39] 
    POP   BC                        ;[2D3A] 
    PUSH  DE                        ;[2D3B] 
    PUSH  HL                        ;[2D3C] 
    LD    HL,(SYSVAR_STORE)         ;[2D3D] 
    INC   HL                        ;[2D40] 
    LD    A,(HL)                    ;[2D41] 
    INC   HL                        ;[2D42] 
    LD    H,(HL)                    ;[2D43] 
    LD    L,A                       ;[2D44] 
    EX    DE,HL                     ;[2D45] 
    POP   HL                        ;[2D46] 
    EX    DE,HL                     ;[2D47] 
    CALL  CHLDE                     ;[2D48] 
    EX    DE,HL                     ;[2D4B] 
    CALL  C,ERR_SUBS_OUT_RANGE      ;[2D4C] 
    LD    E,L                       ;[2D4F] 
    LD    D,H                       ;[2D50] 
VRSA2:
    ADD   HL,DE                     ;[2D51] 
    DJNZ  VRSA2                     ;[2D52] 
    POP   DE                        ;[2D54] 
    POP   BC                        ;[2D55] 
    ADD   HL,BC                     ;[2D56] 
    LD    B,(HL)                    ;[2D57] 
    INC   HL                        ;[2D58] 
    POP   IX                        ;[2D59] 
    RET                             ;[2D5B] 

;
; String variable pointer routine.
;
VRPTS:
    LD    A,(DE)                    ;[2D5C] 
    INC   DE                        ;[2D5D] B=max length of string
    INC   DE                        ;[2D5E] HL points to first char of string
    LD    C,A                       ;[2D5F] 
    LD    A,(DE)                    ;[2D60] 
    CP    $28                       ;[2D61] 
    LD    A,C                       ;[2D63] 
    JP    Z,VRPTSA                  ;[2D64] 
VRPTSP:
    SUB   'A'                       ;[2D67] 
    RLCA                            ;[2D69] 
    RLCA                            ;[2D6A] 
VRPTS1:
    LD    HL,(SYSVAR_STBL)          ;[2D6B] 
    LD    C,A                       ;[2D6E] 
    LD    B,$00                     ;[2D6F] 
    ADD   HL,BC                     ;[2D71] 
    EX    AF,AF'                    ;[2D72] 
    LD    A,(HL)                    ;[2D73] 
    INC   HL                        ;[2D74] 
    OR    (HL)                      ;[2D75] 
    LD    A,$10                     ;[2D76] 
    JR    Z,VRPTS2                  ;[2D78] 
    LD    (SYSVAR_STORE),HL         ;[2D7A] 
    LD    A,(HL)                    ;[2D7D] 
    DEC   HL                        ;[2D7E] 
    LD    L,(HL)                    ;[2D7F] 
    LD    H,A                       ;[2D80] 
    LD    B,(HL)                    ;[2D81] 
    INC   HL                        ;[2D82] 
    RET                             ;[2D83] 

VRPTS2:
    LD    BC,VRPTS1                 ;[2D84] 
    PUSH  BC                        ;[2D87] 
EDMSUB:
    LD    BC,(SYSVAR_TOV)           ;[2D88] 
    LD    (HL),B                    ;[2D8C] 
    DEC   HL                        ;[2D8D] 
    LD    (HL),C                    ;[2D8E] 
EDMARS:
    LD    (BC),A                    ;[2D8F] 
    LD    L,A                       ;[2D90] 
    LD    H,$00                     ;[2D91] 
    INC   HL                        ;[2D93] 
    INC   BC                        ;[2D94] 
    LD    A,$0D                     ;[2D95] 
    LD    (BC),A                    ;[2D97] 
    ADD   HL,BC                     ;[2D98] 
    LD    (SYSVAR_TOV),HL           ;[2D99] 
    INC   H                         ;[2D9C] 
    SBC   HL,SP                     ;[2D9D] 
    CALL  NC,ERR_OUT_OF_MEM         ;[2D9F] 
    EX    AF,AF'                    ;[2DA2] 
    RET                             ;[2DA3] 

EDMAR:
    PUSH  BC                        ;[2DA4] 
    PUSH  HL                        ;[2DA5] 
    INC   DE                        ;[2DA6] 
    RST   $18                       ;[2DA7] 
    INC   DE                        ;[2DA8] 
    LD    A,L                       ;[2DA9] 
    OR    H                         ;[2DAA] 
    POP   IX                        ;[2DAB] 
    LD    (IX+$01),L                ;[2DAD] 
    LD    (IX+$02),H                ;[2DB0] 
    POP   BC                        ;[2DB3] 
    JR    Z,EDMAR2                  ;[2DB4] 
    LD    A,B                       ;[2DB6] 
EDMAR1:
    PUSH  AF                        ;[2DB7] 
    PUSH  HL                        ;[2DB8] 
    LD    BC,(SYSVAR_TOV)           ;[2DB9] 
    CALL  EDMARS                    ;[2DBD] 
    POP   HL                        ;[2DC0] 
    POP   AF                        ;[2DC1] 
    LD    C,A                       ;[2DC2] 
    DEC   HL                        ;[2DC3] 
    LD    A,H                       ;[2DC4] 
    OR    L                         ;[2DC5] 
    LD    A,C                       ;[2DC6] 
    JR    NZ,EDMAR1                 ;[2DC7] 
EDMAR2:
    LD    A,(DE)                    ;[2DC9] 
    RET                             ;[2DCA] 

;
; DIM.
;
BASIC_COM_DIM:
    CALL  TEST_FOR_STRING           ;[2DCB] 
    JR    NZ,EDIM3                  ;[2DCE] 
    LD    A,(DE)                    ;[2DD0] 
    INC   DE                        ;[2DD1] 
    INC   DE                        ;[2DD2] 
    INC   DE                        ;[2DD3] 
    PUSH  AF                        ;[2DD4] 
    RST   $18                       ;[2DD5] 
    INC   DE                        ;[2DD6] 
    INC   H                         ;[2DD7] 
    DEC   H                         ;[2DD8] 
    CALL  NZ,ERR_NUM_OUT_RANGE      ;[2DD9] 
    BIT   7,L                       ;[2DDC] 
    CALL  NZ,ERR_NUM_OUT_RANGE      ;[2DDE] 
    INC   L                         ;[2DE1] 
    DEC   L                         ;[2DE2] 
    CALL  Z,ERR_NUM_OUT_RANGE       ;[2DE3] 
    LD    B,L                       ;[2DE6] 
    POP   AF                        ;[2DE7] 
    PUSH  DE                        ;[2DE8] 
    SUB   'A'                       ;[2DE9] 
    RLCA                            ;[2DEB] 
    RLCA                            ;[2DEC] 
    LD    E,A                       ;[2DED] 
    LD    D,$00                     ;[2DEE] 
    LD    HL,(SYSVAR_STBL)          ;[2DF0] 
    ADD   HL,DE                     ;[2DF3] 
    INC   HL                        ;[2DF4] 
    PUSH  HL                        ;[2DF5] 
    LD    A,B                       ;[2DF6] 
    PUSH  BC                        ;[2DF7] 
    CALL  SUB_DIM                   ;[2DF8] 
    POP   BC                        ;[2DFB] 
    POP   HL                        ;[2DFC] 
    POP   DE                        ;[2DFD] 
    LD    A,(DE)                    ;[2DFE] 
    CP    '('                       ;[2DFF] 
    CALL  Z,EDMAR                   ;[2E01] 
    CP    ','                       ;[2E04] 
    INC   DE                        ;[2E06] 
    JR    Z,BASIC_COM_DIM           ;[2E07] 
    RET                             ;[2E09] 

EDIM3:
    CALL  ARRAY_LOCATE              ;[2E0A] Get pointers
    LD    A,(IX+$00)                ;[2E0D] 
    OR    (IX+$01)                  ;[2E10] 
    CALL  NZ,ERR_REDIM_ARRAY        ;[2E13] 
    LD    A,$F0                     ;[2E16] 
    AND   H                         ;[2E18] Check for more than 1k elements
    CALL  NZ,ERR_OVERFLOW           ;[2E19] 
    PUSH  DE                        ;[2E1C] 
    LD    DE,(SYSVAR_TOV)           ;[2E1D] 
    LD    (IX+$02),L                ;[2E21] 
    LD    (IX+$03),H                ;[2E24] 
    INC   HL                        ;[2E27] First element is 0
    PUSH  HL                        ;[2E28] Save no elements
    LD    C,L                       ;[2E29] 
    LD    B,H                       ;[2E2A] 
    ADD   HL,HL                     ;[2E2B] 
    ADD   HL,HL                     ;[2E2C] 
    ADD   HL,BC                     ;[2E2D] 
    ADD   HL,DE                     ;[2E2E] 
    LD    A,$C0                     ;[2E2F] 
    AND   H                         ;[2E31] 
    CALL  Z,ERR_OVERFLOW            ;[2E32] 
    EX    DE,HL                     ;[2E35] 
    LD    HL,0                      ;[2E36] 
    ADD   HL,SP                     ;[2E39] 
    DEC   H                         ;[2E3A] 
    SBC   HL,DE                     ;[2E3B] 
    CALL  C,ERR_OVERFLOW            ;[2E3D] 
    LD    BC,(SYSVAR_TOV)           ;[2E40] 
    LD    (IX+$00),C                ;[2E44] 
    LD    (IX+$01),B                ;[2E47] 
    LD    (SYSVAR_TOV),DE           ;[2E4A] 
    LD    L,C                       ;[2E4E] 
    LD    H,B                       ;[2E4F] Hl=start of array
    POP   BC                        ;[2E50] Bc=no. elements
    LD    DE,5                      ;[2E51] De=length of element
    INC   HL                        ;[2E54] 
EDIM1:
    LD    (HL),$FF                  ;[2E55] 
    ADD   HL,DE                     ;[2E57] 
    DEC   BC                        ;[2E58] 
    LD    A,B                       ;[2E59] 
    OR    C                         ;[2E5A] 
    JR    NZ,EDIM1                  ;[2E5B] 
    POP   DE                        ;[2E5D] 
    LD    A,(DE)                    ;[2E5E] 
    CP    ','                       ;[2E5F] 
    INC   DE                        ;[2E61] 
    JP    Z,BASIC_COM_DIM           ;[2E62] 
    RET                             ;[2E65] 

;
; Validation for DIM.
;
VALIDATE_DIM:
    CALL  TEST_FOR_STRING           ;[2E66] 
    JR    NZ,$2E7C                  ;[2E69] VALIDATE_DIM+$16
    CALL  READ_STRING_VAR           ;[2E6B] 
    CALL  DMSR                      ;[2E6E] VALIDATE_VAR+$12
    RST   $10                       ;[2E71] 
    LD    (HL),A                    ;[2E72] 
    CP    $0D                       ;[2E73] 
    RET   Z                         ;[2E75] 
IDIM1:
    INC   HL                        ;[2E76] 
    RST   $20                       ;[2E77] 
    INC   L                         ;[2E78] 
    INC   DE                        ;[2E79] 
    JR    VALIDATE_DIM              ;[2E7A] 
    CALL  VALIDATE_READ             ;[2E7C] 
    DEC   HL                        ;[2E7F] 
    LD    A,$29                     ;[2E80] 
    CP    (HL)                      ;[2E82] 
    CALL  NZ,ERR_SYNTAX             ;[2E83] 
    INC   HL                        ;[2E86] 
    LD    A,(DE)                    ;[2E87] 
    LD    (HL),A                    ;[2E88] 
    CP    $0D                       ;[2E89] 
    RET   Z                         ;[2E8B] 
    RST   $20                       ;[2E8C] 
    INC   L                         ;[2E8D] 
    INC   HL                        ;[2E8E] 
    INC   DE                        ;[2E8F] 
    RST   $10                       ;[2E90] 
    JR    VALIDATE_DIM              ;[2E91] 

;
; ROUND
;
ROUND:
    LD    A,(SYSVAR_ZFLAG)          ;[2E93] 
    BIT   0,A                       ;[2E96] Round if bit 0 of zflag set
    RET   Z                         ;[2E98] 
    LD    A,(SYSVAR_WRA1)           ;[2E99] 
    AND   $7F                       ;[2E9C] 
    ADD   A,$81                     ;[2E9E] 
    RET   Z                         ;[2EA0] 
    LD    HL,SYSVAR_WRA1+$04        ;[2EA1] 
    LD    A,(HL)                    ;[2EA4] 
    CP    $50                       ;[2EA5] 
    LD    (HL),$00                  ;[2EA7] Zero last 2 digits
    RET   C                         ;[2EA9] Exit if <$50
    SCF                             ;[2EAA] 
    LD    B,$03                     ;[2EAB] 
    PUSH  DE                        ;[2EAD] 
RD1:
    DEC   HL                        ;[2EAE] 
    LD    A,$00                     ;[2EAF] 
    ADC   A,(HL)                    ;[2EB1] 
    DAA                             ;[2EB2] 
    LD    (HL),A                    ;[2EB3] 
    DJNZ  RD1                       ;[2EB4] 
    CALL  ALIGN                     ;[2EB6] 
RDX:
    POP   DE                        ;[2EB9] 
    RET                             ;[2EBA] 

;
; Square contents of WRA1
;
SQUARE:
    CALL  WRA1_TO_WRA2              ;[2EBB] 
    JP    _MULT                     ;[2EBE] 

;
; X := (((A1*X)*X+A2)*X+A3)*X+A4
;
SERIES:
    PUSH  IY                        ;[2EC1] 
    CALL  WRA1_TO_IY                ;[2EC3] Load calc stack
    POP   IY                        ;[2EC6] 
    LD    B,(IX+$00)                ;[2EC8] Series IX points to coeff.
    INC   IX                        ;[2ECB] Inc past # coeff.
    LD    HL,SYSVAR_WRA1            ;[2ECD] Load first coeff.
    PUSH  BC                        ;[2ED0] Save count
    CALL  LIXW                      ;[2ED1] 
    POP   BC                        ;[2ED4] Unsave count
SERIES1:
    PUSH  BC                        ;[2ED5] Save count
    PUSH  IY                        ;[2ED6] Save calc stack pointer
    CALL  IY_TO_WRA2                ;[2ED8] Load WRA2
    POP   IY                        ;[2EDB] 
    CALL  _MULT                     ;[2EDD] 
    CALL  IX_TO_WRA2                ;[2EE0] Load WRA2 with coeff.
    CALL  ADD                       ;[2EE3] 
    POP   BC                        ;[2EE6] Get count
    DJNZ  SERIES1                   ;[2EE7] 
    RET                             ;[2EE9] 

;
; (IY) to WRA1.
;
IY_TO_WRA1:
    CALL  CSW1                      ;[2EEA] 
    CALL  SWAP                      ;[2EED] Swap WRA1,2
CSW1:
    LD    HL,SYSVAR_SYNL            ;[2EF0] LYNX_IY_TO_WRA1+$06
    LD    B,$05                     ;[2EF3] 
CW1:
    DEC   IY                        ;[2EF5] 
    DEC   HL                        ;[2EF7] 
    LD    A,(IY+$00)                ;[2EF8] 
    LD    (HL),A                    ;[2EFB] 
    DJNZ  CW1                       ;[2EFC] 
    RET                             ;[2EFE] 

;
; WRA1 to (IY).
;
WRA1_TO_IY:
    LD    HL,SYSVAR_WRA1            ;[2EFF] 
    LD    B,$05                     ;[2F02] WRA1 to calc stack
WC1:
    LD    A,(HL)                    ;[2F04] 
    LD    (IY+$00),A                ;[2F05] 
    INC   IY                        ;[2F08] 
    INC   HL                        ;[2F0A] 
    DJNZ  WC1                       ;[2F0B] 
    RET                             ;[2F0D] 

;
; (IY) to WRA2
;
IY_TO_WRA2:
    LD    B,$05                     ;[2F0E] 
    LD    HL,SYSVAR_WRA2            ;[2F10] 
LW1:
    LD    A,(IY+$00)                ;[2F13] 
    LD    (HL),A                    ;[2F16] 
    INC   IY                        ;[2F17] 
    INC   HL                        ;[2F19] 
    DJNZ  LW1                       ;[2F1A] 
    RET                             ;[2F1C] 

;
; (IX) to WRA2
;
IX_TO_WRA2:
    LD    HL,SYSVAR_WRA2            ;[2F1D] 
LIXW:
    LD    B,$05                     ;[2F20] 
LW2:
    LD    A,(IX+$00)                ;[2F22] 
    LD    (HL),A                    ;[2F25] 
    INC   IX                        ;[2F26] 
    INC   HL                        ;[2F28] 
    DJNZ  LW2                       ;[2F29] 
    RET                             ;[2F2B] 

;
; Push WRA1 and jump to (IX).
;
PUSH_WRA1:
    POP   IX                        ;[2F2C] 
    LD    A,(SYSVAR_WRA1)           ;[2F2E] 
    PUSH  AF                        ;[2F31] 
    LD    HL,(SYSVAR_WRA1+$01)      ;[2F32] 
    PUSH  HL                        ;[2F35] 
    LD    HL,(SYSVAR_WRA1+$03)      ;[2F36] 
    PUSH  HL                        ;[2F39] 
    JP    (IX)                      ;[2F3A] 

;
; Pop WRA2 and jump to (IX).
;
POP_WRA2:
    POP   IX                        ;[2F3C] 
    POP   HL                        ;[2F3E] 
    LD    (SYSVAR_WRA2+$03),HL      ;[2F3F] 
    POP   HL                        ;[2F42] 
    LD    (SYSVAR_WRA2+$01),HL      ;[2F43] 
    POP   AF                        ;[2F46] 
    LD    (SYSVAR_WRA2),A           ;[2F47] 
    JP    (IX)                      ;[2F4A] 

;
; Log base e, get log base 10
;
BASIC_FN_LN:
    CALL  BASIC_FN_LOG              ;[2F4C] 
    LD    HL,FLOAT_LOGE             ;[2F4F] 
    CALL  LNUM2                     ;[2F52] 
    JP    DIV                       ;[2F55] 

;
; ARCSIN.
;
BASIC_FN_ARCSIN:
    LD    A,(SYSVAR_WRA1)           ;[2F58] 
    CP    $80                       ;[2F5B] 
    JP    Z,LZERO                   ;[2F5D] 
    PUSH  AF                        ;[2F60] 
    JP    FNACOS                    ;[2F61] 

;
; Part of arccos
;
ARCCOS1:
    CALL  SUB                       ;[2F64] 
    CALL  POP_WRA2                  ;[2F67] 
    CALL  DIV                       ;[2F6A] 
    CALL  BASIC_FN_SQR              ;[2F6D] 
    CALL  ARCTANS                   ;[2F70] 
    CALL  WRA1_TO_WRA2              ;[2F73] 
    CALL  ADD                       ;[2F76] 
    POP   AF                        ;[2F79] 
    RLA                             ;[2F7A] 
    RET   C                         ;[2F7B] 
    CALL  WRA1_TO_WRA2              ;[2F7C] 
    CALL  BASIC_FN_PI               ;[2F7F] 
    JP    SUB                       ;[2F82] 

;
; ARCCOS.
;
BASIC_FN_ARCCOS:
    LD    HL,SYSVAR_WRA1            ;[2F85] 
    LD    A,(HL)                    ;[2F88] 
    PUSH  AF                        ;[2F89] 
    SET   7,(HL)                    ;[2F8A] 
    CALL  WRA1_TO_WRA2              ;[2F8C] 
    CALL  PUSH_WRA1                 ;[2F8F] 
    CALL  LONE                      ;[2F92] 
    CALL  ADD                       ;[2F95] 
    CALL  POP_WRA2                  ;[2F98] 
    CALL  PUSH_WRA1                 ;[2F9B] 
    CALL  LONE                      ;[2F9E] 
    JR    ARCCOS1                   ;[2FA1] 
    NOP                             ;[2FA3] 
    NOP                             ;[2FA4] 

;
; ARCTAN.
;
BASIC_FN_ARCTAN:
    LD    A,(SYSVAR_WRA1)           ;[2FA5] 
    PUSH  AF                        ;[2FA8] 
    SET   7,A                       ;[2FA9] 
    LD    (SYSVAR_WRA1),A           ;[2FAB] 
    CP    $C0                       ;[2FAE] 
    JR    NC,ARCTAN3                ;[2FB0] 
    CALL  ARCTANS                   ;[2FB2] 
ARCTAN2:
    POP   AF                        ;[2FB5] 
    BIT   7,A                       ;[2FB6] 
    RET   NZ                        ;[2FB8] 
    LD    HL,SYSVAR_WRA1            ;[2FB9] 
    RES   7,(HL)                    ;[2FBC] 
    RET                             ;[2FBE] 

ARCTAN3:
    CALL  WRA1_TO_WRA2              ;[2FBF] 
    CALL  LONE                      ;[2FC2] 
    CALL  DIV                       ;[2FC5] 
    CALL  ARCTANS                   ;[2FC8] 
ARCTAN4:
    CALL  WRA1_TO_WRA2              ;[2FCB] 
    LD    HL,FLOAT_RDEG             ;[2FCE] 
    CALL  LNUM1                     ;[2FD1] 
    CALL  SUB                       ;[2FD4] 
    JR    ARCTAN2                   ;[2FD7] 
ARCTANS:
    CALL  PUSH_WRA1                 ;[2FD9] 
    CALL  SQUARE                    ;[2FDC] 
    LD    IX,DATA_ARCTAN            ;[2FDF] 
    CALL  SERIES                    ;[2FE3] 
    CALL  POP_WRA2                  ;[2FE6] 
    JP    _MULT                     ;[2FE9] 

;
; Data for ARCTAN
;
DATA_ARCTAN:
    DB $06,$BD,$68,$12,$41,$10,$3E,$33      ;[2FEC]  ..h.A.>3
    DB $60,$62,$69,$BE,$79,$62,$63,$18      ;[2FF4]  `bi.ybc.
    DB $3F,$13,$23,$35,$10,$BF,$19,$80      ;[2FFC]  ?.#5....
    DB $78,$69,$3F,$33,$31,$73,$76,$BF      ;[3004]  xi?31sv.
    DB $99,$99,$96,$11                      ;[300C]  ....

;
; Factorial.
;
BASIC_FN_FACT:
    CALL  BASIC_FN_INT              ;[3010] 
    LD    A,(SYSVAR_WRA1)           ;[3013] 
    CP    $80                       ;[3016] 
    JP    Z,LONE                    ;[3018] 
    CP    $C2                       ;[301B] 
    CALL  NC,ERR_OVERFLOW           ;[301D] 
    BIT   7,A                       ;[3020] 
    CALL  Z,ERR_FUNCT_ARG           ;[3022] 
    CALL  PUSH_WRA1                 ;[3025] 
FACT3:
    LD    HL,FLOAT1                 ;[3028] 
    CALL  LNUM2                     ;[302B] 
    CALL  SUB                       ;[302E] 
    LD    A,(SYSVAR_WRA1)           ;[3031] 
    CP    $80                       ;[3034] 
    JR    Z,FACT4                   ;[3036] 
    CALL  POP_WRA2                  ;[3038] 
    CALL  PUSH_WRA1                 ;[303B] 
    CALL  _MULT                     ;[303E] 
    CALL  POP_WRA2                  ;[3041] 
    CALL  PUSH_WRA1                 ;[3044] 
    CALL  SWAP                      ;[3047] 
    JR    FACT3                     ;[304A] 
FACT4:
    CALL  POP_WRA2                  ;[304C] 
    JP    SWAP                      ;[304F] 

;
; Square root.
;
BASIC_FN_SQR:
    PUSH  IY                        ;[3052] 
    CALL  WRA1_TO_IY                ;[3054] 
    POP   IY                        ;[3057] 
    LD    A,(SYSVAR_WRA1)           ;[3059] 
    CP    $80                       ;[305C] 
    RET   Z                         ;[305E] 
    BIT   7,A                       ;[305F] 
    CALL  Z,ERR_FUNCT_ARG           ;[3061] 
    RES   7,A                       ;[3064] 
    RRCA                            ;[3066] 
    ADD   A,$20                     ;[3067] 
    SET   7,A                       ;[3069] 
SQR2:
    LD    (SYSVAR_WRA1),A           ;[306B] 
    LD    B,$05                     ;[306E] 
SQR3:
    PUSH  BC                        ;[3070] 
    CALL  PUSH_WRA1                 ;[3071] 
    PUSH  IY                        ;[3074] 
    CALL  IY_TO_WRA2                ;[3076] 
    POP   IY                        ;[3079] 
    CALL  SWAP                      ;[307B] 
    CALL  DIV                       ;[307E] 
    CALL  POP_WRA2                  ;[3081] 
    CALL  ADD                       ;[3084] 
    LD    HL,FLOAT_05               ;[3087] 
    CALL  LNUM2                     ;[308A] 
    CALL  _MULT                     ;[308D] 
    POP   BC                        ;[3090] 
    DJNZ  SQR3                      ;[3091] 
    RET                             ;[3093] 

;
; Part of power routine
;
SUB_POWER1:
    CALL  CSW1                      ;[3094] 
    JP    LONE                      ;[3097] 

;
; ** Power routine.
;
BASIC_FN_POWER:
    CALL  CSW1                      ;[309A] 
    LD    A,(SYSVAR_WRA1)           ;[309D] 
    CP    $80                       ;[30A0] 
    JR    Z,SUB_POWER1              ;[30A2] 
    CP    $C0                       ;[30A4] 
    JR    NZ,POWER4                 ;[30A6] 
    CALL  RL10                      ;[30A8] Rotate top digit out
    EX    AF,AF'                    ;[30AB] Save
    LD    B,$04                     ;[30AC] See if other digits are 0
    LD    HL,SYSVAR_WRA1+$01        ;[30AE] 
    XOR   A                         ;[30B1] 
POWER1:
    CP    (HL)                      ;[30B2] 
    JR    NZ,POWER3                 ;[30B3] 
    INC   HL                        ;[30B5] 
    DJNZ  POWER1                    ;[30B6] 
    CALL  CSW1                      ;[30B8] Load a part of a**b
    EX    AF,AF'                    ;[30BB] Get power
    DEC   A                         ;[30BC] 
    RET   Z                         ;[30BD] A**1=a
    LD    B,A                       ;[30BE] 
POWER2:
    PUSH  BC                        ;[30BF] A=a*a*a  b+1 times
    PUSH  IY                        ;[30C0] 
    CALL  IY_TO_WRA2                ;[30C2] Get x
    POP   IY                        ;[30C5] 
    CALL  _MULT                     ;[30C7] 
    POP   BC                        ;[30CA] 
    DJNZ  POWER2                    ;[30CB] 
    RET                             ;[30CD] 

POWER3:
    EX    AF,AF'                    ;[30CE] Get digit
    CALL  RRD1A                     ;[30CF] Rotate back
POWER4:
    CALL  PUSH_WRA1                 ;[30D2] 
    CALL  CSW1                      ;[30D5] 
    CALL  BASIC_FN_LOG              ;[30D8] 
    CALL  POP_WRA2                  ;[30DB] 
    CALL  _MULT                     ;[30DE] 
    JP    BASIC_FN_ANTILOG          ;[30E1] 

;
; LOG - if negative, give error.
;
BASIC_FN_LOG:
    LD    HL,SYSVAR_WRA1            ;[30E4] 
    LD    A,(HL)                    ;[30E7] Get exponent
    CP    $81                       ;[30E8] Neg or 0
    CALL  C,ERR_FUNCT_ARG           ;[30EA] 
    LD    (HL),$C0                  ;[30ED] Store exponent =0 in wra1
    BIT   6,A                       ;[30EF] Save sign in f
    PUSH  AF                        ;[30F1] 
    JR    NZ,FL2                    ;[30F2] 
    NEG                             ;[30F4] 
FL2:
    AND   $3F                       ;[30F6] Zap signs
    LD    B,$FF                     ;[30F8] 
    LD    C,$0A                     ;[30FA] 
FL1:
    INC   B                         ;[30FC] B=tens of A
    SUB   C                         ;[30FD] 
    JR    NC,FL1                    ;[30FE] 
    ADD   A,C                       ;[3100] 
    SLA   B                         ;[3101] B:=B*16
    SLA   B                         ;[3103] 
    SLA   B                         ;[3105] 
    SLA   B                         ;[3107] 
    ADD   A,B                       ;[3109] 
    PUSH  AF                        ;[310A] Save exponent in BCD
    CALL  PUSH_WRA1                 ;[310B] 
    LD    HL,FLOAT_RT10             ;[310E] 
    CALL  LNUM2                     ;[3111] 
    CALL  ADD                       ;[3114] 
    CALL  POP_WRA2                  ;[3117] 
    CALL  PUSH_WRA1                 ;[311A] 
    LD    HL,FLOAT_RT10             ;[311D] 
    CALL  LNUM1                     ;[3120] 
    CALL  SWAP                      ;[3123] 
    CALL  SUB                       ;[3126] 
    CALL  POP_WRA2                  ;[3129] 
    CALL  DIV                       ;[312C] 
    CALL  PUSH_WRA1                 ;[312F] 
    CALL  SQUARE                    ;[3132] 
    LD    IX,DATA_LOG               ;[3135] 
    CALL  SERIES                    ;[3139] Evaluate Series
    CALL  POP_WRA2                  ;[313C] Get original X
    CALL  _MULT                     ;[313F] 
    LD    HL,FLOAT_05               ;[3142] 
    CALL  LNUM2                     ;[3145] 
    CALL  ADD                       ;[3148] 
    LD    HL,SYSVAR_WRA1            ;[314B] WRA2:=WRA1
    PUSH  HL                        ;[314E] 
    CALL  LNUM2                     ;[314F] 
    CALL  LONE                      ;[3152] Load WRA1 with one
    POP   HL                        ;[3155] 
    SET   0,(HL)                    ;[3156] $C1 in exp.
    POP   AF                        ;[3158] Get exponent
    LD    (SYSVAR_WRA1+$01),A       ;[3159] 
    CALL  ALIGN                     ;[315C] Align number
    POP   AF                        ;[315F] Get sign of exponent
    JR    NZ,FL3                    ;[3160] 
    LD    HL,SYSVAR_WRA1            ;[3162] 
    RES   7,(HL)                    ;[3165] 
FL3:
    JP    ADD                       ;[3167] 

;
; Data for LOG routine.
;
DATA_LOG:
    DB $04,$BF,$19,$13,$37,$71,$BE,$94      ;[316A]  ....7q..
    DB $37,$64,$76,$BF,$17,$75,$22,$07      ;[3172]  7dv..u".
    DB $BF,$28,$93,$35,$52,$BF,$86,$85      ;[317A]  .(.5R...
    DB $91,$72                              ;[3182]  .r

;
; EXP.
;
BASIC_FN_EXP:
    LD    HL,FLOAT_LOGE             ;[3184] 
    CALL  LNUM2                     ;[3187] 
    CALL  _MULT                     ;[318A] 
    JP    BASIC_FN_ANTILOG          ;[318D] 

;
; TAN.
;
BASIC_FN_TAN:
    CALL  PUSH_WRA1                 ;[3190] 
    CALL  BASIC_FN_COS              ;[3193] Cosine
    CALL  POP_WRA2                  ;[3196] Load x into wra2
    CALL  PUSH_WRA1                 ;[3199] Stack cos
    LD    HL,SYSVAR_WRA2            ;[319C] 
    CALL  LNUM1                     ;[319F] Load wra2 into wra1
    CALL  BASIC_FN_SIN              ;[31A2] 
    CALL  POP_WRA2                  ;[31A5] Cos into wra2
    JP    DIV                       ;[31A8] Sin/cos

;
; ANTILOG.
;
BASIC_FN_ANTILOG:
    LD    HL,SYSVAR_WRA1            ;[31AB] 
    BIT   7,(HL)                    ;[31AE] Save sign in f'
    EX    AF,AF'                    ;[31B0] 
    SET   7,(HL)                    ;[31B1] Abs(x)
    LD    A,$BF                     ;[31B3] See if int(x)>0
    CP    (HL)                      ;[31B5] 
    JR    C,ANT1                    ;[31B6] 
    INC   A                         ;[31B8] A=0c0h
    PUSH  AF                        ;[31B9] Store exponent
    JR    ANT2                      ;[31BA] 
ANT1:
    LD    A,(SYSVAR_WRA1)           ;[31BC] 
    CALL  FPINTA                    ;[31BF] Int part into hl
    EX    DE,HL                     ;[31C2] Put in de
    LD    HL,$003C                  ;[31C3] If >60 over
    OR    A                         ;[31C6] 
    SBC   HL,DE                     ;[31C7] 
    CALL  C,ERR_OVERFLOW            ;[31C9] 
    LD    A,$C0                     ;[31CC] Form exponent
    ADD   A,E                       ;[31CE] 
    PUSH  AF                        ;[31CF] Save
    LD    A,$BF                     ;[31D0] Make leftover in wra1 into frac
    LD    (SYSVAR_WRA1),A           ;[31D2] 
    OR    A                         ;[31D5] Clear carry
    CALL  ALIGN                     ;[31D6] 
ANT2:
    LD    IX,DATA_ANTILOG           ;[31D9] Antlog coeff.
    CALL  SERIES                    ;[31DD] Evaluate series
    CALL  SQUARE                    ;[31E0] 
    POP   AF                        ;[31E3] Get exponent
    LD    (SYSVAR_WRA1),A           ;[31E4] 
    EX    AF,AF'                    ;[31E7] Get sign
    RET   NZ                        ;[31E8] Return if +
    LD    HL,FLOAT1                 ;[31E9] Else recip.
    CALL  LNUM2                     ;[31EC] 
    CALL  SWAP                      ;[31EF] 
    CALL  DIV                       ;[31F2] 
    RET                             ;[31F5] 

;
; Data for ANTILOG
;
DATA_ANTILOG:
    DB $06,$BD,$56,$54,$90,$20,$BE,$13      ;[31F6]  ..VT....
    DB $42,$09,$40,$BE,$75,$46,$75,$47      ;[31FE]  B.@.uFuG
    DB $BF,$25,$36,$03,$32,$BF,$66,$28      ;[3206]  .%6.2.f(
    DB $43,$15,$C0,$11,$51,$28,$76,$C0      ;[320E]  C...Q(v.
    DB $10,$00,$00,$00                      ;[3216]  ....

;
; COS.
;
BASIC_FN_COS:
    LD    HL,FLOAT_RDEG             ;[321A] 
    CALL  LNUM2                     ;[321D] Add pi/4 to wra1
    CALL  ADD                       ;[3220] 

;
; SIN.
;
BASIC_FN_SIN:
    LD    HL,FLOAT_TAU              ;[3223] 
    CALL  LNUM2                     ;[3226] Convert degrees to radians
    CALL  DIV                       ;[3229] 
    CALL  BASIC_FN_FRAC             ;[322C] Take fractional part
    LD    HL,FLOAT4                 ;[322F] *4
    CALL  LNUM2                     ;[3232] 
    CALL  _MULT                     ;[3235] 
    LD    A,(SYSVAR_WRA1)           ;[3238] Check if negative
    BIT   7,A                       ;[323B] 
    JR    NZ,SIN2                   ;[323D] 
    LD    HL,FLOAT4                 ;[323F] 
    CALL  LNUM2                     ;[3242] Add 4 if neg
    CALL  ADD                       ;[3245] 
SIN2:
    LD    HL,FLOAT1                 ;[3248] 0<=x<1 x := x
    CALL  LNUM2                     ;[324B] 
    CALL  CMP                       ;[324E] 
    JR    NC,SIN1                   ;[3251] 
    CALL  SWAP                      ;[3253] 1<=x<3 x := 2-x
    LD    HL,FLOAT3                 ;[3256] 
    CALL  LNUM1                     ;[3259] 
    CALL  CMP                       ;[325C] 
    JR    NC,SIN3                   ;[325F] 
    LD    HL,FLOAT2                 ;[3261] 
    CALL  LNUM1                     ;[3264] 
    CALL  SUB                       ;[3267] 
    JR    SIN1                      ;[326A] 
SIN3:
    LD    HL,FLOAT4                 ;[326C] 
    CALL  LNUM1                     ;[326F] 
    CALL  SWAP                      ;[3272] 
    CALL  SUB                       ;[3275] 
SIN1:
    CALL  PUSH_WRA1                 ;[3278] Save x
    CALL  SQUARE                    ;[327B] 
    LD    IX,DATA_SINCOS            ;[327E] Coefficients
    CALL  SERIES                    ;[3282] 
    CALL  POP_WRA2                  ;[3285] 
    JP    _MULT                     ;[3288] 

;
; Data for SIN and COS
;
DATA_SINCOS:
    DB $04,$BC,$15,$14,$84,$19,$3D,$46      ;[328B]  ......=F
    DB $73,$76,$56,$BE,$79,$68,$96,$79      ;[3293]  svV.yh.y
    DB $3F,$64,$59,$63,$71,$C0,$15,$70      ;[329B]  ?dYcq..p
    DB $79,$63                              ;[32A3]  yc

;
; NOT.
;
BASIC_FN_NOT:
    CALL  CSW1                      ;[32A5] 
FNOT1:
    LD    A,(SYSVAR_WRA1)           ;[32A8] 
    CP    $80                       ;[32AB] 
    JR    FQ1                       ;[32AD] 

;
; = as in IF A=B
;
BASIC_FN_EQUAL:
    CALL  CMP                       ;[32AF] 
FQ1:
    LD    HL,FLOAT_ZERO             ;[32B2] 
    JR    NZ,FQ2                    ;[32B5] 
    LD    HL,FLOAT1                 ;[32B7] 
FQ2:
    JP    LNUM1                     ;[32BA] 

;
; <> Not equal routine.
;
BASIC_FN_NOT_EQUAL:
    CALL  BASIC_FN_EQUAL            ;[32BD] 
    JR    FNOT1                     ;[32C0] 

;
; > Greater than routine.
;
BASIC_FN_GREATERTHAN:
    NOP                             ;[32C2] 
FG3:
    CALL  CMP                       ;[32C3] 
FG2:
    LD    HL,FLOAT1                 ;[32C6] 
    JR    C,FQ2                     ;[32C9] 
    LD    HL,FLOAT_ZERO             ;[32CB] 
    JR    FQ2                       ;[32CE] 

;
; = Less than or equal to routine.
;
BASIC_FN_LT_EQUAL:
    CALL  BASIC_FN_GREATERTHAN      ;[32D0] 
    JR    FNOT1                     ;[32D3] 

;
; > Greater than routine.
;
BASIC_FN_LESSTHAN:
    CALL  SWAP                      ;[32D5] 
    JR    FG3                       ;[32D8] 

;
; )= Greater than or equal to routine.
;
BASIC_FN_GT_EQUAL:
    CALL  BASIC_FN_LESSTHAN         ;[32DA] 
    JR    FNOT1                     ;[32DD] 

;
; OR.
;
BASIC_FN_OR:
    LD    A,(SYSVAR_WRA1)           ;[32DF] 
    CP    $80                       ;[32E2] 
    JR    NZ,FNR2                   ;[32E4] 
    LD    A,(SYSVAR_WRA2)           ;[32E6] 
    CP    $80                       ;[32E9] 
FNR2:
    LD    HL,FLOAT1                 ;[32EB] 
    JR    NZ,FNR1                   ;[32EE] 
    LD    HL,FLOAT_ZERO             ;[32F0] 
FNR1:
    JP    LNUM1                     ;[32F3] 

;
; AND.
;
BASIC_FN_AND:
    LD    A,(SYSVAR_WRA1)           ;[32F6] 
    CP    $80                       ;[32F9] 
    JR    Z,FNR2                    ;[32FB] 
    LD    A,(SYSVAR_WRA2)           ;[32FD] 
    CP    $80                       ;[3300] 
    JR    FNR2                      ;[3302] 
FFN1:
    CALL  CSW1                      ;[3304] 
FFN0:
    POP   BC                        ;[3307] Fn0, get return addr.
    POP   DE                        ;[3308] Get pointer
    DEC   IY                        ;[3309] Back onto function
    LD    A,(IY+$00)                ;[330B] Get chr
    JP    EE2                       ;[330E] Get function

;
; - Minus sign.
;
BASIC_FN_MINUS:
    CALL  CSW1                      ;[3311] 
    JP    NEGATE_WRA1               ;[3314] 
FN_NEGATE1:
    CP    (HL)                      ;[3317] 
    RET   Z                         ;[3318] 
    XOR   (HL)                      ;[3319] 
    LD    (HL),A                    ;[331A] 
    RET                             ;[331B] 

    NOP                             ;[331C] 

;
; HIMEM.
;
BASIC_FN_HIMEM:
    LD    HL,(SYSVAR_STACK)         ;[331D] 
    INC   HL                        ;[3320] 
    INC   HL                        ;[3321] 
    JR    FN_INP2                   ;[3322] 

;
; HL.
;
BASIC_FN_HL:
    LD    HL,(SYSVAR_HLSTORE)       ;[3324] 
    JR    FN_INP2                   ;[3327] 

;
; INP.
;
BASIC_FN_INP:
    CALL  FPINT                     ;[3329] 
    LD    C,L                       ;[332C] 
    LD    B,H                       ;[332D] 
    IN    A,(C)                     ;[332E] 
FN_INP1:
    LD    L,A                       ;[3330] 
    LD    H,$00                     ;[3331] 
FN_INP2:
    JP    INTFP                     ;[3333] 

;
; DPEEK.
;
BASIC_FN_DPEEK:
    CALL  FPINT                     ;[3336] 
    LD    A,(HL)                    ;[3339] 
    INC   HL                        ;[333A] 
    LD    H,(HL)                    ;[333B] 
    LD    L,A                       ;[333C] 
    JR    FN_INP2                   ;[333D] 

;
; PEEK.
;
BASIC_FN_PEEK:
    CALL  FPINT                     ;[333F] 
    LD    A,(HL)                    ;[3342] 
    JR    FN_INP1                   ;[3343] 

;
; DEG.
;
BASIC_FN_DEG:
    LD    HL,SUB_ANGLE              ;[3345] 
    CALL  LNUM2                     ;[3348] 
    JP    _MULT                     ;[334B] 

;
; RAD.
;
BASIC_FN_RAD:
    LD    HL,SUB_ANGLE              ;[334E] 
    CALL  LNUM2                     ;[3351] 
    JP    DIV                       ;[3354] 

;
; Utility called by RAD and DEG
;
SUB_ANGLE:
    POP   BC                        ;[3357] 
    LD    D,A                       ;[3358] 
    ADD   HL,HL                     ;[3359] 
    LD    D,A                       ;[335A] 
    ADD   A,B                       ;[335B] 

ESTRS:
    LD    IX,SYSVAR_STRBUF+128      ;[335C] 
    CALL  ESE1                      ;[3360] 
    INC   DE                        ;[3363] 
    PUSH  DE                        ;[3364] 
    LD    DE,SYSVAR_STRBUF+128      ;[3365] 
    LD    HL,SYSVAR_STRBUF          ;[3368] 
ESTRS1:
    LD    A,(DE)                    ;[336B] 
    CP    (HL)                      ;[336C] 
    JR    NZ,ESTRS2                 ;[336D] 
    INC   DE                        ;[336F] 
    INC   HL                        ;[3370] 
    CP    SZ                        ;[3371] 
    JR    NZ,ESTRS1                 ;[3373] 
ESTRS2:
    POP   DE                        ;[3375] 
    RET                             ;[3376] 

ESTR:
    CALL  ESEE                      ;[3377] Take data from program line.
    LD    A,(DE)                    ;[337A] 
    INC   DE                        ;[337B] 
    CP    '='                       ;[337C] 
    JR    NZ,ESTR3                  ;[337E] 
    CALL  ESTRS                     ;[3380] 
    PUSH  DE                        ;[3383] 
    LD    DE,FLOAT1                 ;[3384] 
    JR    Z,ESTR2                   ;[3387] 
ESTR1:
    LD    DE,FLOAT_ZERO             ;[3389] 
ESTR2:
    CALL  LCST                      ;[338C] 
    POP   DE                        ;[338F] 
    RET                             ;[3390] 

ESTR3:
    CALL  ESTRS                     ;[3391] 
    PUSH  DE                        ;[3394] 
    LD    DE,FLOAT1                 ;[3395] 
    JR    C,ESTR2                   ;[3398] 
    JR    ESTR1                     ;[339A] 
EESARG:
    CALL  ESEE                      ;[339C] 
    INC   DE                        ;[339F] 
    INC   DE                        ;[33A0] 
    JR    EE1                       ;[33A1] 
ESTRING:
    CALL  ESTR                      ;[33A3] 
    JP    EE1                       ;[33A6] 

;
; Evaluate reverse polish expression.
;
EE:
    LD    IY,SYSVAR_CSTACK          ;[33A9] 
EE1:
    LD    A,(DE)                    ;[33AD] Get CHR
    INC   DE                        ;[33AE] Inc pointer
    CP    ARGSOS                    ;[33AF] 
    JR    Z,EESARG                  ;[33B1] 
    CP    SOS                       ;[33B3] String
    JR    Z,ESTRING                 ;[33B5] 
    CP    NUM                       ;[33B7] Number marker
    JR    Z,EENUM                   ;[33B9] 
    CP    HNUM                      ;[33BB] 
    JR    Z,EENUM                   ;[33BD] 
    CP    53                        ;[33BF] Variable
    JR    C,EEVAR                   ;[33C1] 
    CP    64+53                     ;[33C3] Array
    JR    C,EEARY                   ;[33C5] 
    CP    EOP                       ;[33C7] End
    JR    Z,EEX                     ;[33C9] 
    CP    PARENS                    ;[33CB] Parentheses
    JR    Z,EE1                     ;[33CD] Ignore
    JR    C,EEARY                   ;[33CF] Function
    CP    THEN                      ;[33D1] 
    CALL  NC,ERR_SOMETHG_MISSG      ;[33D3] Error else operator
EE2:
    LD    IX,(SYSVAR_FTBL)          ;[33D6] IX points to function table
    PUSH  DE                        ;[33DA] Save pointer
    CP    $C6                       ;[33DB] 
    PUSH  AF                        ;[33DD] 
    CALL  NC,IY_TO_WRA1             ;[33DE] 
    POP   AF                        ;[33E1] 
    SLA   A                         ;[33E2] A := A*2
    LD    C,A                       ;[33E4] Add A to IX
    LD    B,$00                     ;[33E5] 
    ADD   IX,BC                     ;[33E7] 
    LD    L,(IX+$00)                ;[33E9] Get vector
    LD    H,(IX+$01)                ;[33EC] 
    LD    BC,EERENT                 ;[33EF] Save return address
    PUSH  BC                        ;[33F2] 
    JP    (HL)                      ;[33F3] JP to routine
EERENT:
    POP   DE                        ;[33F4] Unsave pointer
    CALL  WRA1_TO_IY                ;[33F5] Load WRA1
    JP    EE1                       ;[33F8] Next
EENUM:
    CALL  LCST                      ;[33FB] Load calc stack with number
    JR    EE1                       ;[33FE] Next
EEVAR:
    PUSH  DE                        ;[3400] Save pointer
    LD    L,A                       ;[3401] 
    LD    H,$00                     ;[3402] 
    LD    E,L                       ;[3404] 
    LD    D,H                       ;[3405] 
    ADD   HL,HL                     ;[3406] 
    ADD   HL,HL                     ;[3407] 
    ADD   HL,DE                     ;[3408] 
    LD    DE,(SYSVAR_VTBL)          ;[3409] Variable table
    ADD   HL,DE                     ;[340D] 
    INC   HL                        ;[340E] 
    LD    A,(HL)                    ;[340F] 
    INC   A                         ;[3410] 
    DEC   HL                        ;[3411] 
    CALL  Z,ERR_UNDEFINED_VAR       ;[3412] Undefined variable
    EX    DE,HL                     ;[3415] DE point to num
    CALL  LCST                      ;[3416] Load stack
    POP   DE                        ;[3419] Unsave pointer
    JP    EE1                       ;[341A] Next
EEARY:
    LD    (IY+$00),A                ;[341D] Store token
    INC   IY                        ;[3420] Inc calc SP
    JP    EE1                       ;[3422] 
EEX:
    JP    CSW1                      ;[3425] Load WRA1

;
; Load from DE to calc stack
;
LCST:
    LD    B,$05                     ;[3428] 
LS1:
    LD    A,(DE)                    ;[342A] 
    LD    (IY+$00),A                ;[342B] 
    INC   DE                        ;[342E] 
    INC   IY                        ;[342F] 
    DJNZ  LS1                       ;[3431] 
    RET                             ;[3433] 

;
; ABS. Absolute value of WRA1
;
BASIC_FN_ABS:
    LD    HL,SYSVAR_WRA1            ;[3434] 
    SET   7,(HL)                    ;[3437] 
    RET                             ;[3439] 

;
; SGN. Sign of WRA1 1=+,-1=-,0=0
;
BASIC_FN_SGN:
    LD    A,(SYSVAR_WRA1)           ;[343A] 
    PUSH  AF                        ;[343D] Save exponent
    CALL  LZERO                     ;[343E] Store a zero
    POP   AF                        ;[3441] Unsave exponent
    CP    $80                       ;[3442] Return if zero
    RET   Z                         ;[3444] 
    LD    HL,SYSVAR_WRA1+$01        ;[3445] 
    SET   4,(HL)                    ;[3448] 
    BIT   7,A                       ;[344A] 
    LD    A,$40                     ;[344C] 
    JR    Z,SIGN1                   ;[344E] 
    LD    A,$C0                     ;[3450] 
SIGN1:
    LD    (SYSVAR_WRA1),A           ;[3452] 
    RET                             ;[3455] 

;
; INT.
;
BASIC_FN_INT:
    LD    A,(SYSVAR_WRA1)           ;[3456] 
    RES   7,A                       ;[3459] Kill sign
    CP    $47                       ;[345B] 
    RET   NC                        ;[345D] Nothing to be done
    CP    $40                       ;[345E] 
    JP    C,LZERO                   ;[3460] No int part
    SUB   $47                       ;[3463] Calc no of rots.
    NEG                             ;[3465] 
    LD    B,A                       ;[3467] B=# rotations
    PUSH  BC                        ;[3468] Save count
BASIC_FN_INT1:
    CALL  RRD1A                     ;[3469] Rotate right
    DJNZ  BASIC_FN_INT1             ;[346C] 
    POP   BC                        ;[346E] 
BASIC_FN_INT2:
    CALL  RL10                      ;[346F] Rotate 0's back
    DJNZ  BASIC_FN_INT2             ;[3472] 
    RET                             ;[3474] 

;
; FRAC.
;
BASIC_FN_FRAC:
    LD    A,(SYSVAR_WRA1)           ;[3475] 
    RES   7,A                       ;[3478] 
    CP    $47                       ;[347A] If >1e8 no frac
    JP    NC,LZERO                  ;[347C] 
    CP    $40                       ;[347F] 
    RET   C                         ;[3481] No int part
    SUB   $3F                       ;[3482] 
    LD    B,A                       ;[3484] 
    LD    A,(SYSVAR_WRA1)           ;[3485] 
    AND   $C0                       ;[3488] 
    DEC   A                         ;[348A] 
    LD    (SYSVAR_WRA1),A           ;[348B] 
FR1:
    CALL  RL10                      ;[348E] 
    DJNZ  FR1                       ;[3491] 
    OR    A                         ;[3493] 
    JP    ALIGN                     ;[3494] 

;
; Floating point in WRA1 to integer in HL
;
FPINT:
    LD    A,(SYSVAR_WRA1)           ;[3497] 
    CP    $C0                       ;[349A] 
    JP    Z,FPINT1                  ;[349C] 
FPINTA:
    LD    HL,$0000                  ;[349F] 
    BIT   7,A                       ;[34A2] 
    CALL  Z,ERR_NUM_OUT_RANGE       ;[34A4] 
    CP    $C0                       ;[34A7] 
    RET   C                         ;[34A9] 
    CP    $C7                       ;[34AA] See if number too big
    CALL  NC,ERR_NUM_OUT_RANGE      ;[34AC] 
    SUB   $BF                       ;[34AF] Digits in A
    LD    B,A                       ;[34B1] Count in B
    PUSH  DE                        ;[34B2] Save DE
FI1:
    CALL  RL10                      ;[34B3] Rotate digit into A
    LD    E,L                       ;[34B6] HL:=HL*10+A
    LD    D,H                       ;[34B7] 
    ADD   HL,HL                     ;[34B8] 
    ADD   HL,HL                     ;[34B9] 
    ADD   HL,DE                     ;[34BA] 
    ADD   HL,HL                     ;[34BB] 
    LD    E,A                       ;[34BC] 
    LD    D,$00                     ;[34BD] 
    ADD   HL,DE                     ;[34BF] 
    DJNZ  FI1                       ;[34C0] 
    POP   DE                        ;[34C2] Unsave DE
    RET                             ;[34C3] 

;
; Integer in HL to floating point in WRA1. 
;
INTFP:
    LD    A,$C7                     ;[34C4] 
    LD    (SYSVAR_WRA1),A           ;[34C6] Store power and N$SIGN
    PUSH  HL                        ;[34C9] Save number
    LD    HL,$0000                  ;[34CA] N$ZERO WRA1
    LD    (SYSVAR_WRA1+$03),HL      ;[34CD] 
    LD    (SYSVAR_WRA1+$01),HL      ;[34D0] 
    POP   HL                        ;[34D3] 
    LD    B,16                      ;[34D4] Number of bits
INTFP1:
    ADD   HL,HL                     ;[34D6] Top bit into carry
    PUSH  BC                        ;[34D7] Save count
    PUSH  HL                        ;[34D8] Save number
    LD    B,$04                     ;[34D9] Number of mantissa bytes
    LD    HL,SYSVAR_WRA1+$04        ;[34DB] End of WRA1
INTFP2:
    LD    A,(HL)                    ;[34DE] Get byte
    ADC   A,(HL)                    ;[34DF] Double and add carry
    DAA                             ;[34E0] Decimal adjust
    LD    (HL),A                    ;[34E1] Store byte
    DEC   HL                        ;[34E2] Advance pointer
    DJNZ  INTFP2                    ;[34E3] Cont.
    POP   HL                        ;[34E5] Get number
    POP   BC                        ;[34E6] Get count
    DJNZ  INTFP1                    ;[34E7] Cont.
    OR    A                         ;[34E9] Clear carry
    JP    ALIGN                     ;[34EA] Align number

;
; Test for '0' to '9'
;
TEST_DIGIT:
    LD    A,(DE)                    ;[34ED] 
    CP    '0'                       ;[34EE] 
    RET   C                         ;[34F0] 
    CP    '9'+1                     ;[34F1] 
    CCF                             ;[34F3] 
    RET                             ;[34F4] 

;
; Test for 'A' to Z' and 'a' to 'z',
;
TEST_ALPHA:
    LD    A,(DE)                    ;[34F5] 
    CP    'A'                       ;[34F6] 
    RET   C                         ;[34F8] 
    CP    'Z'+1                     ;[34F9] 
    CCF                             ;[34FB] 
    RET   NC                        ;[34FC] 
    CP    'a'                       ;[34FD] 
    RET   C                         ;[34FF] 
    CP    'z'+1                     ;[3500] 
    CCF                             ;[3502] 
    RET                             ;[3503] 

;
; Test for uppercase/lowercase. (aka. N$VT)
;
TEST_UPPER_LOW:
    LD    A,(DE)                    ;[3504] 
    SUB   'A'-1                     ;[3505] 
    CP    27                        ;[3507] 
    RET   C                         ;[3509] 
    SUB   $06                       ;[350A] 
    RET                             ;[350C] 

;
; Clears WRA1 to 0s. 
;
ZWRA1:
    LD    HL,SYSVAR_WRA1            ;[350D] 
    LD    B,$05                     ;[3510] No. of bytes
ZW1:
    LD    (HL),$00                  ;[3512] Store A 0
    INC   HL                        ;[3514] Increment pointer
    DJNZ  ZW1                       ;[3515] Repeat B times
    RET                             ;[3517] Return

;
; Data. Used to to 'Clear to end of line'
;
CRMS:
    DB    NEWLINE,CEL,0             ;[3518] 

;
; Display character in A (PutChar)
;
PUTCHAR:
    PUSH  AF                        ;[351B] 
    CP    $0D                       ;[351C] 
    JR    NZ,DISPLAYB1              ;[351E] 
    PUSH  HL                        ;[3520] 
    LD    HL,(SYSVAR_CRST)          ;[3521] 
    CALL  PLINE                     ;[3524] 
    POP   HL                        ;[3527] 
    POP   AF                        ;[3528] 
    RET                             ;[3529] 

;
; Output a space
;
OUTPUT_SPACE:
    PUSH  AF                        ;[352A] 
    LD    A,' '                     ;[352B] 
    JR    DISPLAYB1                 ;[352D] 

;
; Output character in A to the screen.
;
DISPLAYB:
    PUSH  AF                        ;[352F] 
DISPLAYB1:
    PUSH  HL                        ;[3530] 
    PUSH  BC                        ;[3531] 
    CALL  SUB_PUTCHAR               ;[3532] 
    POP   BC                        ;[3535] 
    POP   HL                        ;[3536] 
    POP   AF                        ;[3537] 
    RET                             ;[3538] 

;
; Display line pointed to by HL and terminated by 0.
;
PLINE:
    LD    A,(HL)                    ;[3539] 
    INC   HL                        ;[353A] 
    OR    A                         ;[353B] 
    RET   Z                         ;[353C] 
    CALL  DISPLAYB                  ;[353D] 
    JR    PLINE                     ;[3540] 

;
; Swaps contents of WRA1 and WRA2. 
;
SWAP:
    LD    HL,SYSVAR_WRA1            ;[3542] 
    LD    DE,SYSVAR_WRA2            ;[3545] 
    LD    B,$05                     ;[3548] 
SWAP1:
    LD    C,(HL)                    ;[354A] 
    LD    A,(DE)                    ;[354B] 
    EX    DE,HL                     ;[354C] 
    LD    (HL),C                    ;[354D] 
    LD    (DE),A                    ;[354E] 
    INC   DE                        ;[354F] 
    INC   HL                        ;[3550] 
    DJNZ  SWAP1                     ;[3551] 
    RET                             ;[3553] 

;
; Called by the subtraction routine (366A).
;
NEGATE_WRA2:
    LD    HL,SYSVAR_WRA2            ;[3554] 
    JR    NEGATE3                   ;[3557] 
NEGATE_WRA1:
    LD    HL,SYSVAR_WRA1            ;[3559] 
NEGATE3:
    LD    A,$80                     ;[355C] 
    JP    FN_NEGATE1                ;[355E] 

;
; Compares WRA2, WRA1. Flags set as (WRA2) - (WRA1). 
;
CMP:
    CALL  CMPS                      ;[3561] 
    RET   Z                         ;[3564] 
    PUSH  AF                        ;[3565] 
    LD    HL,SYSVAR_WRA1            ;[3566] 
    BIT   7,(HL)                    ;[3569] 
    JR    NZ,CMPX1                  ;[356B] 
    LD    HL,SYSVAR_WRA2            ;[356D] 
    BIT   7,(HL)                    ;[3570] 
    JR    NZ,CMPX1                  ;[3572] 
    POP   AF                        ;[3574] 
    CCF                             ;[3575] 
    RET                             ;[3576] 

CMPX1:
    POP   AF                        ;[3577] 
    RET                             ;[3578] 

;
; Subroutine called by compare routine.
;
CMPS:
    LD    HL,SYSVAR_WRA1            ;[3579] 
    LD    DE,SYSVAR_WRA2            ;[357C] 
    LD    B,$05                     ;[357F] 
CMP1:
    LD    A,(DE)                    ;[3581] 
    CP    (HL)                      ;[3582] 
CMP2:
    RET   NZ                        ;[3583] 
    INC   HL                        ;[3584] 
    INC   DE                        ;[3585] 
    DJNZ  CMP1                      ;[3586] 
    RET                             ;[3588] 

;
; Same as N$CMP but compares absolute values
; (called by the addition routine.)
;
CPABS:
    LD    HL,SYSVAR_WRA1            ;[3589] 
    LD    DE,SYSVAR_WRA2            ;[358C] 
    LD    A,(DE)                    ;[358F] 
    RES   7,A                       ;[3590] 
    LD    C,(HL)                    ;[3592] 
    RES   7,C                       ;[3593] 
    CP    C                         ;[3595] 
    LD    B,$05                     ;[3596] 
    JR    CMP2                      ;[3598] 

;
; Align number in WRA1, C contains overflow
;
ALIGN:
    CALL  ALN1                      ;[359A] 
    LD    A,(SYSVAR_WRA1)           ;[359D] Get exponent
    RES   7,A                       ;[35A0] Scap sign
    ADD   A,C                       ;[35A2] Add exponent correction
    JR    Z,LZERO                   ;[35A3] If 0 load WRA1 with 0
    BIT   7,A                       ;[35A5] Check for overflow
    JR    Z,ALN3                    ;[35A7] JP if not
    CP    $C0                       ;[35A9] See if overflowed top or bot.
    CALL  C,ERR_OVERFLOW            ;[35AB] If top, overflow error

;
; Basic FALSE Function: Loads-WRA1 with floating point 0.
;
LZERO:
    LD    HL,FLOAT_ZERO             ;[35AE] 

;
; Loads number pointed to by HL into WRA1
;
LNUM1:
    LD    DE,SYSVAR_WRA1            ;[35B1] 
NUM_HL_TO_WRA:
    LD    BC,5                      ;[35B4] 
    LDIR                            ;[35B7] 
    RET                             ;[35B9] 

;
; Loads number pointed to by HL into WRA2
;
LNUM2:
    LD    DE,SYSVAR_WRA2            ;[35BA] 
    JR    NUM_HL_TO_WRA             ;[35BD] 

;
; Basic TRUE Function: Loads WRA1 with floating point 1.
;
LONE:
    LD    HL,FLOAT1                 ;[35BF] 
    JR    LNUM1                     ;[35C2] 

;
; 14 predefined five-byte floating-point numbers, used for various things.
; (1, 2, 3, 4, 65536, 6.28319, 1.5708, 0.785398, 2.50663, 0.434294, 3.16228, 0.5, -0.5, 0)
;
FLOAT1:        DB $C0,$10,$00,$00,$00          ;[35C4] 
FLOAT2:        DB $C0,$20,$00,$00,$00          ;[35C9] 
FLOAT3:        DB $C0,$30,$00,$00,$00          ;[35CE] 
FLOAT4:        DB $C0,$40,$00,$00,$00          ;[35D3] 
FLOAT_16B:     DB $C4,$65,$53,$60,$00          ;[35D8] 
FLOAT_TAU:     DB $C0,$62,$83,$18,$53          ;[35DD] 
FLOAT_RDEG:    DB $C0,$15,$70,$79,$63          ;[35E2] 
FLOAT_DRAD:    DB $BF,$78,$53,$98,$16          ;[35E7] 
FLOAT_RTAU:    DB $C0,$25,$06,$62,$83          ;[35EC] 
FLOAT_LOGE:    DB $BF,$43,$42,$94,$48          ;[35F1] 
FLOAT_RT10:    DB $C0,$31,$62,$27,$76          ;[35F6] 
FLOAT_05:      DB $BF,$50,$00,$00,$00          ;[35FB] 
FLOAT_M05:     DB $3F,$50,$00,$00,$00          ;[3600] 
FLOAT_ZERO:    DB $80,$00,$00,$00,$00          ;[3605] 
;
; Used by EXEC?? (apparently)
;
DATA_EXEC:
    DB    6,$80                     ;[360A] 

;
; PI.
;
BASIC_FN_PI:
    LD    HL,DATA_NPI               ;[360C] 
    JR    LNUM1                     ;[360F] 

;
; Data for Pi.
;
DATA_NPI:
    DB $C0,$31,$41,$59,$27          ;[3611]  .1AY'

ALN3:
    LD    A,(SYSVAR_WRA1)           ;[3616] Get expression
    ADD   A,C                       ;[3619] Add correction
    LD    (SYSVAR_WRA1),A           ;[361A] Store WRA1
    RET                             ;[361D] 

ALN1:
    LD    BC,$0900                  ;[361E] B=max. number of  rotations. C=correction
    JR    NC,ALN2                   ;[3621] If not overflow, jump
    LD    A,$01                     ;[3623] Rotate in A 1
    CALL  RRD1A                     ;[3625] 
    INC   C                         ;[3628] Increment correction
    RET                             ;[3629] 

ALN2:
    LD    A,(SYSVAR_WRA1+$01)       ;[362A] Get top two digits
    CP    $10                       ;[362D] See if top digit is non-zero
    RET   NC                        ;[362F] Return if non-zero
    DEC   C                         ;[3630] Decrement correction
    CALL  RL10                      ;[3631] Rotate in A zero
    DJNZ  ALN2                      ;[3634] Do for max nine times
    POP   HL                        ;[3636] Pull off return address
    JP    LZERO                     ;[3637] Load WRA1 with zero

;
; Rotate WRA2 right put in A 0
;
RRD20:
    XOR   A                         ;[363A] 
RRD2A:
    PUSH  HL                        ;[363B] "               "   in A reg
    PUSH  BC                        ;[363C] 
    LD    HL,SYSVAR_WRA2+$01        ;[363D] 
    JR    RR2                       ;[3640] 
RRD10:
    XOR   A                         ;[3642] Rotate WRA1 right put in A 0
RRD1A:
    PUSH  HL                        ;[3643] 
    PUSH  BC                        ;[3644] 
    LD    HL,SYSVAR_WRA1+$01        ;[3645] 
RR2:
    CALL  RRSUB                     ;[3648] 
    POP   BC                        ;[364B] 
    POP   HL                        ;[364C] 
    RET                             ;[364D] 

RRSUB:
    LD    B,$04                     ;[364E] 
RR1:
    RRD                             ;[3650] 
    INC   HL                        ;[3652] 
    DJNZ  RR1                       ;[3653] 
    RET                             ;[3655] 

RL10:
    XOR   A                         ;[3656] Rotate WRA1 left with 0
RL1A:
    PUSH  HL                        ;[3657] 
    PUSH  BC                        ;[3658] 
    LD    HL,SYSVAR_WRA1+$04        ;[3659] 
    CALL  RLSUB                     ;[365C] 
    POP   BC                        ;[365F] 
    POP   HL                        ;[3660] 
    RET                             ;[3661] 

RLSUB:
    LD    B,$04                     ;[3662] ? Fancy rotate with (HL) !! ??
RL1:
    RLD                             ;[3664] 
    DEC   HL                        ;[3666] 
    DJNZ  RL1                       ;[3667] 
    RET                             ;[3669] 

;
; Basic Minus Function: Subtracts (WRA2) from (WRA1), stores result in WRA1.
;
SUB:
    CALL  NEGATE_WRA2               ;[366A] 

;
; Basic Add Function:  Adds (WRA1) and (WRA2), stores result in WRA1.
;
ADD:
    CALL  CPABS                     ;[366D] 
    CALL  NC,SWAP                   ;[3670] Swap if necessary
    LD    A,(SYSVAR_WRA2)           ;[3673] Get exponent
    AND   $7F                       ;[3676] Kill sign
    RET   Z                         ;[3678] Return if a zero
    LD    C,A                       ;[3679] Save in C
    LD    A,(SYSVAR_WRA1)           ;[367A] Get exponent
    RES   7,A                       ;[367D] Kill sign
    SUB   C                         ;[367F] A=difference of WRA1,WRA2
    JR    Z,AD1                     ;[3680] No aligning necessary
    CP    $08                       ;[3682] See if WRA1<<WRA2
    RET   NC                        ;[3684] Don't bother adding
    LD    B,A                       ;[3685] Store in B
AD2:
    CALL  RRD20                     ;[3686] Rotate B times
    DJNZ  AD2                       ;[3689] 
AD1:
    LD    A,(SYSVAR_WRA1)           ;[368B] Get expression
    LD    C,A                       ;[368E] Store in C
    LD    A,(SYSVAR_WRA2)           ;[368F] Get expression
    XOR   C                         ;[3692] See if we need to subtract or add
    BIT   7,A                       ;[3693] 
    JR    Z,AD3                     ;[3695] Jump if add necessary
    CALL  SBT12                     ;[3697] Else subtract
    OR    A                         ;[369A] Clear carry
    JP    ALIGN                     ;[369B] Align and return
AD3:
    CALL  AD12                      ;[369E] Add
    JP    ALIGN                     ;[36A1] Align and return
SBT12:
    OR    A                         ;[36A4] Clear carry
    LD    DE,SYSVAR_WRA1+$04        ;[36A5] DE point to end of WRA1
    LD    HL,SYSVAR_WRA2+$04        ;[36A8] HL point to end of WRA2
    LD    B,$04                     ;[36AB] B digits
SBT121:
    LD    A,(DE)                    ;[36AD] Get byte
    SBC   A,(HL)                    ;[36AE] Subtract
    DAA                             ;[36AF] Adjust
    LD    (DE),A                    ;[36B0] Store
    DEC   HL                        ;[36B1] Dec pointers
    DEC   DE                        ;[36B2] 
    DJNZ  SBT121                    ;[36B3] 
    RET                             ;[36B5] 

AD12:
    OR    A                         ;[36B6] Same as SB12 but adding
    LD    DE,SYSVAR_WRA1+$04        ;[36B7] 
    LD    HL,SYSVAR_WRA2+$04        ;[36BA] 
    LD    B,$04                     ;[36BD] 
AD121:
    LD    A,(DE)                    ;[36BF] 
    ADC   A,(HL)                    ;[36C0] 
    DAA                             ;[36C1] 
    LD    (DE),A                    ;[36C2] 
    DEC   HL                        ;[36C3] 
    DEC   DE                        ;[36C4] 
    DJNZ  AD121                     ;[36C5] 
    RET                             ;[36C7] 

;
; Basic Multiply Function: Multiplies (WRA1) and (WRA2), stores answer in WRA1.
;
_MULT:
    LD    A,(SYSVAR_WRA1)           ;[36C8] 
    CP    $80                       ;[36CB] See if zero
    JR    Z,MTZ                     ;[36CD] Load 0 & return
    AND   $7F                       ;[36CF] Kill excess
    LD    C,A                       ;[36D1] Store in c
    LD    HL,SYSVAR_WRA2            ;[36D2] HL point to wra2
    LD    A,(HL)                    ;[36D5] Get exp.
    CP    $80                       ;[36D6] Zero ?
    JR    Z,MTZ                     ;[36D8] Load 0 & return
    AND   $7F                       ;[36DA] Kill sign
    ADD   A,C                       ;[36DC] Add exp.
    SUB   $3F                       ;[36DD] Adjust
    JR    Z,MTZ                     ;[36DF] If zero load wra1 with 0
    BIT   7,A                       ;[36E1] If overflow or underflow
    JR    Z,MT1                     ;[36E3] Do not jp
    CP    $C0                       ;[36E5] Check for overflow
    CALL  C,ERR_OVERFLOW            ;[36E7] 
MTZ:
    JP    LZERO                     ;[36EA] Else underflow
MT1:
    LD    C,A                       ;[36ED] Store in c
    LD    A,(SYSVAR_WRA1)           ;[36EE] Get exp.
    XOR   (HL)                      ;[36F1] Work out sign
    CPL                             ;[36F2] 
    AND   $80                       ;[36F3] 
    ADD   A,C                       ;[36F5] Add to exp.
    LD    (SYSVAR_WRA3),A           ;[36F6] Store in wra3
    CALL  ONEDIGIT                  ;[36F9] One digit only
    JP    Z,MLONE                   ;[36FC] 
    LD    HL,$62D5                  ;[36FF] HL points to wra3+1
    LD    B,$0C                     ;[3702] No. digits to kill
    CALL  ZW1                       ;[3704] Zero them
MLT7:
    LD    DE,SYSVAR_WRA2+$04        ;[3707] End of wra2
    LD    HL,$62DC                  ;[370A] 
    LD    B,$04                     ;[370D] 
MLT6:
    PUSH  BC                        ;[370F] 
    LD    A,(DE)                    ;[3710] 
    PUSH  DE                        ;[3711] 
    LD    E,A                       ;[3712] 
    PUSH  HL                        ;[3713] 
    CALL  MLTW4E                    ;[3714] 
    POP   HL                        ;[3717] 
    CALL  C,ADW3W4                  ;[3718] 
    DEC   HL                        ;[371B] 
    POP   DE                        ;[371C] 
    DEC   DE                        ;[371D] 
    POP   BC                        ;[371E] 
    DJNZ  MLT6                      ;[371F] 
    LD    A,(SYSVAR_WRA3+1)         ;[3721] A=first two digits
    CP    $10                       ;[3724] See if need to rotate
    JR    NC,MT5                    ;[3726] Jp if not
    LD    HL,SYSVAR_WRA3+5          ;[3728] Rot. start point
    LD    B,5                       ;[372B] No. to rotate
    CALL  RL1                       ;[372D] Rotate
    LD    A,(HL)                    ;[3730] Get exp.
    DEC   A                         ;[3731] Dec exp.
    LD    (HL),A                    ;[3732] Store
    AND   $7F                       ;[3733] See if zero
    JR    Z,MTZ                     ;[3735] Jp if zero
MT5:
    LD    HL,SYSVAR_WRA3            ;[3737] Move wra3 to wra1
    JP    LNUM1                     ;[373A] 

;
; Convert E to binary
;
ETOBIN:
    LD    A,E                       ;[373D] 
    AND   $F0                       ;[373E] 
    RRCA                            ;[3740] 
    LD    B,A                       ;[3741] 
    RRCA                            ;[3742] 
    RRCA                            ;[3743] Divide by 8
    ADD   A,B                       ;[3744] 
    LD    B,A                       ;[3745] 
    LD    A,E                       ;[3746] 
    AND   $0F                       ;[3747] 
    ADD   A,B                       ;[3749] 
    LD    E,A                       ;[374A] 
    RET                             ;[374B] 

;
; Subroutine called by multiply.
;
MLTAE:
    LD    HL,0                      ;[374C] 
    LD    B,H                       ;[374F] 
    LD    C,A                       ;[3750] 
MLTAE2:
    SRL   E                         ;[3751] 
    JR    NZ,MLTAE3                 ;[3753] 
    RET   NC                        ;[3755] 
MLTAE3:
    JR    NC,MLTAE1                 ;[3756] 
    LD    A,C                       ;[3758] 
    ADD   A,L                       ;[3759] 
    DAA                             ;[375A] 
    LD    L,A                       ;[375B] 
    LD    A,B                       ;[375C] 
    ADC   A,H                       ;[375D] 
    DAA                             ;[375E] 
    LD    H,A                       ;[375F] 
MLTAE1:
    LD    A,C                       ;[3760] 
    ADD   A,C                       ;[3761] 
    DAA                             ;[3762] 
    LD    C,A                       ;[3763] 
    LD    A,B                       ;[3764] 
    ADC   A,B                       ;[3765] 
    DAA                             ;[3766] 
    LD    B,A                       ;[3767] 
    JR    MLTAE2                    ;[3768] 

;
; Subroutine called by multiply.
;
MLTW4E:
    CALL  ETOBIN                    ;[376A] 
    RET   Z                         ;[376D] Multiply by 0
    PUSH  IX                        ;[376E] Save IX reg
    LD    IX,$62D3                  ;[3770] End of wra4
    LD    (IX+$00),$00              ;[3774] Zero wra4's last byte
    LD    HL,SYSVAR_WRA1+$04        ;[3778] End of wra1
    LD    B,$04                     ;[377B] 4 bytes to multiply
MW4E1:
    PUSH  BC                        ;[377D] Save count
    PUSH  HL                        ;[377E] Save wra1 pointer
    LD    A,(HL)                    ;[377F] Get digit pair
    PUSH  DE                        ;[3780] Save E
    CALL  MLTAE                     ;[3781] Mutiply A & E result in HL
    LD    A,(IX+$00)                ;[3784] Add L to wra4
    ADD   A,L                       ;[3787] 
    DAA                             ;[3788] 
    LD    (IX+$00),A                ;[3789] 
    LD    A,$00                     ;[378C] 
    ADC   A,H                       ;[378E] 
    DAA                             ;[378F] 
    LD    (IX-$01),A                ;[3790] 
    DEC   IX                        ;[3793] 
    POP   DE                        ;[3795] Unsave E
    POP   HL                        ;[3796] Unsave wra1 pointer
    DEC   HL                        ;[3797] Dec " "
    POP   BC                        ;[3798] Get count
    DJNZ  MW4E1                     ;[3799] 
    POP   IX                        ;[379B] Restor ix
    SCF                             ;[379D] Set carry to indicate non-zero
    RET                             ;[379E] 

;
; Subroutine called by multiply.
;
ADW3W4:
    PUSH  HL                        ;[379F] 
    LD    B,$05                     ;[37A0] 
    LD    DE,$62D3                  ;[37A2] 
    OR    A                         ;[37A5] 
ADWW1:
    LD    A,(DE)                    ;[37A6] 
    ADC   A,(HL)                    ;[37A7] 
    DAA                             ;[37A8] 
    LD    (HL),A                    ;[37A9] 
    DEC   HL                        ;[37AA] 
    DEC   DE                        ;[37AB] 
    DJNZ  ADWW1                     ;[37AC] 
    POP   HL                        ;[37AE] 
    RET                             ;[37AF] 

;
; Basic Divide Function: WRA1 = WRA1/WRA2
;
DIV:
    LD    HL,SYSVAR_WRA2            ;[37B0] 
    LD    A,(HL)                    ;[37B3] Get expression
    CP    $80                       ;[37B4] If zero then
    CALL  Z,ERR_DIVIDE_BY_Z         ;[37B6] Divide by zero error
    AND   $7F                       ;[37B9] Kill sign
    LD    C,A                       ;[37BB] Store in C
    LD    A,(SYSVAR_WRA1)           ;[37BC] Get exp.
    CP    $80                       ;[37BF] If zero then
    RET   Z                         ;[37C1] Return
    AND   $7F                       ;[37C2] Kill sign
    SUB   C                         ;[37C4] Get diff
    ADD   A,$40                     ;[37C5] Correct
    JR    Z,DVZ                     ;[37C7] If expr=0 then return a 0
    BIT   7,A                       ;[37C9] Check for overflow or underflow
    JR    Z,DV1                     ;[37CB] Jump if not either of these
    CP    $C0                       ;[37CD] Check for overflow
    CALL  C,ERR_OVERFLOW            ;[37CF] 
DVZ:
    JP    LZERO                     ;[37D2] Load with zero
DV1:
    LD    C,A                       ;[37D5] Store in A
    LD    A,(SYSVAR_WRA1)           ;[37D6] Get expression
    XOR   (HL)                      ;[37D9] XOR with (WRA2)
    CPL                             ;[37DA] 
    AND   $80                       ;[37DB] A=sign
    ADD   A,C                       ;[37DD] Add to exp
    LD    (SYSVAR_WRA1),A           ;[37DE] Store in WRA1
    CALL  ONEDIGIT                  ;[37E1] One digit only?
    JP    Z,DVONE                   ;[37E4] 
    LD    HL,SYSVAR_WRA3+1          ;[37E7] Zero WRA3 &WRAe (not WRA2)
    LD    B,12                      ;[37EA] 
    CALL  ZW1                       ;[37EC] 
    LD    DE,SYSVAR_WRA2+$01        ;[37EF] Shift WRA2 to WRAe
    LD    HL,SYSVAR_WRAE            ;[37F2] 
    LD    B,4                       ;[37F5] 
    CALL  SWAP1                     ;[37F7] 
    LD    DE,SYSVAR_WRA3+1          ;[37FA] Move WRA1 to WRA3+1
    LD    HL,SYSVAR_WRA1+1          ;[37FD] 
    LD    BC,4                      ;[3800] 
    LDIR                            ;[3803] 
    LD    B,8                       ;[3805] No. of digits
DV3:
    PUSH  BC                        ;[3807] Save
    LD    C,$00                     ;[3808] C=digit
DV4:
    CALL  COMPARE                   ;[380A] Compare
    JR    C,DV5                     ;[380D] Jump if zero wanted
    LD    HL,SYSVAR_WRAE+7          ;[380F] Subtract WRAe from WRA3+1
    LD    DE,SYSVAR_WRA3+8          ;[3812] 
    LD    B,8                       ;[3815] 
    CALL  SBT121                    ;[3817] 
    INC   C                         ;[381A] Increment digit count
    JR    DV4                       ;[381B] Continue
DV5:
    LD    A,C                       ;[381D] Put digit in a
    CALL  RL1A                      ;[381E] Rotate into WRA1
    LD    HL,SYSVAR_WRAE            ;[3821] Rotate WRAe
    LD    B,$08                     ;[3824] 
    XOR   A                         ;[3826] 
    CALL  RR1                       ;[3827] 
    POP   BC                        ;[382A] Get digit count
    DJNZ  DV3                       ;[382B] Check if 8 digits done
    LD    A,(SYSVAR_WRA1+$01)       ;[382D] Get top two digits
    CP    $10                       ;[3830] If top digit non-zero
    RET   NC                        ;[3832] Then return
    LD    A,(SYSVAR_WRA1)           ;[3833] Else get exponent
    DEC   A                         ;[3836] Dec it
    JR    Z,DVZ                     ;[3837] If exponent is +0 or -0
    CP    $80                       ;[3839] Then return a zero
    JR    Z,DVZ                     ;[383B] 
    LD    (SYSVAR_WRA1),A           ;[383D] Else restore it
    LD    B,$01                     ;[3840] Rotate in WRA1 extra digit
    JR    DV3                       ;[3842] 

;
; Compare WRA3+1 with WRAE
;
COMPARE:
    LD    DE,SYSVAR_WRA3+1          ;[3844] 
    LD    HL,SYSVAR_WRAE            ;[3847] 
    LD    B,8                       ;[384A] 
    JP    CMP1                      ;[384C] 

DVONE:
    LD    A,(SYSVAR_WRA2+$01)       ;[384F] 
    RRCA                            ;[3852] 
    RRCA                            ;[3853] 
    RRCA                            ;[3854] 
    RRCA                            ;[3855] 
    AND   $0F                       ;[3856] 
    LD    C,A                       ;[3858] 
    XOR   A                         ;[3859] 
    LD    E,A                       ;[385A] 
    LD    B,$04                     ;[385B] 
    LD    HL,SYSVAR_WRA1+$01        ;[385D] 
DVONE1:
    PUSH  BC                        ;[3860] 
    RLD                             ;[3861] 
    CALL  DVSUB                     ;[3863] 
    RLD                             ;[3866] 
    CALL  DVSUB                     ;[3868] 
    RLD                             ;[386B] 
    POP   BC                        ;[386D] 
    INC   HL                        ;[386E] 
    DJNZ  DVONE1                    ;[386F] 
    OR    A                         ;[3871] 
    JP    ALIGN                     ;[3872] 

DVSUB:
    PUSH  BC                        ;[3875] 
    PUSH  AF                        ;[3876] 
    LD    A,E                       ;[3877] 
    RLCA                            ;[3878] 
    RLCA                            ;[3879] 
    ADD   A,E                       ;[387A] 
    RLCA                            ;[387B] 
    POP   BC                        ;[387C] 
    ADD   A,B                       ;[387D] 
    POP   BC                        ;[387E] 
    LD    B,$FF                     ;[387F] 
DVSUB1:
    INC   B                         ;[3881] 
    SUB   C                         ;[3882] 
    JR    NC,DVSUB1                 ;[3883] 
    ADD   A,C                       ;[3885] 
    LD    E,A                       ;[3886] 
    LD    A,B                       ;[3887] 
    RET                             ;[3888] 

;
; jumped to from 349C
;
FPINT1:
    LD    A,(SYSVAR_WRA1+$01)       ;[3889] 
    RRCA                            ;[388C] 
    RRCA                            ;[388D] 
    RRCA                            ;[388E] 
    RRCA                            ;[388F] 
    AND   $0F                       ;[3890] 
    LD    L,A                       ;[3892] 
    LD    H,$00                     ;[3893] 
    RET                             ;[3895] 

;
; One digit only? Subroutine called by multiply and divide.
;
ONEDIGIT:
    LD    A,(SYSVAR_WRA2+1)         ;[3896] 
    AND   $0F                       ;[3899] 
    RET   NZ                        ;[389B] 
    LD    A,(SYSVAR_WRA2+2)         ;[389C] 
    OR    A                         ;[389F] 
    RET   NZ                        ;[38A0] 
    LD    A,(SYSVAR_WRA2+3)         ;[38A1] 
    OR    A                         ;[38A4] 
    RET   NZ                        ;[38A5] 
    LD    A,(SYSVAR_WRA2+4)         ;[38A6] 
    OR    A                         ;[38A9] 
    RET                             ;[38AA] 

;
; Multiply subroutine.
;
MLONE:
    LD    A,(SYSVAR_WRA3)           ;[38AB] 
    LD    (SYSVAR_WRA1),A           ;[38AE] 
    LD    A,(SYSVAR_WRA2+$01)       ;[38B1] 
    AND   $F0                       ;[38B4] 
    RRCA                            ;[38B6] 
    RRCA                            ;[38B7] 
    RRCA                            ;[38B8] 
    RRCA                            ;[38B9] 
    LD    HL,SYSVAR_WRA1+$04        ;[38BA] 
    LD    B,$04                     ;[38BD] 
    LD    D,$00                     ;[38BF] 
MLONE3:
    PUSH  BC                        ;[38C1] 
    PUSH  AF                        ;[38C2] 
    LD    B,A                       ;[38C3] 
    LD    E,$00                     ;[38C4] 
    XOR   A                         ;[38C6] 
    LD    C,(HL)                    ;[38C7] 
MLONE2:
    ADD   A,C                       ;[38C8] 
    DAA                             ;[38C9] 
    JR    NC,MLONE1                 ;[38CA] 
    INC   E                         ;[38CC] 
MLONE1:
    DJNZ  MLONE2                    ;[38CD] 
    ADD   A,D                       ;[38CF] 
    DAA                             ;[38D0] 
    CALL  SUB_MULTIPLY1             ;[38D1] This is "patched" in Mark II rom.  See PAT41.
    POP   AF                        ;[38D4] 
    POP   BC                        ;[38D5] 
    DJNZ  MLONE3                    ;[38D6] 
    INC   E                         ;[38D8] 
    DEC   E                         ;[38D9] 
    LD    A,E                       ;[38DA] 
    JP    NZ,RRD1A                  ;[38DB] 
MLONE4:
    LD    HL,SYSVAR_WRA1            ;[38DE] 
    LD    A,(HL)                    ;[38E1] 
    OR    A                         ;[38E2] 
    JP    Z,LZERO                   ;[38E3] 
    DEC   (HL)                      ;[38E6] 
    RET                             ;[38E7] 

;
; 'J' Command. Exit monitor back to command line.
;
JUMP_TO_CMDLINE:
    LD    SP,(SYSVAR_STACK)         ;[38E8] 
    JP    SUB_JUMP_TO_CMDLINE       ;[38EC] Recover continued.

; 
; Error message table
; 
ERRS:    DB    0                                  ;[38EF] 
OMMSG:   DB    "Out of Memory",0                  ;[38F0] 
WRMSG:   DB    "Wrong Mode",0                     ;[38FE] 
STRMSG:  DB    "String error",0                   ;[3909] 
PRNMSG:  DB    "Missing bracket",0                ;[3916] 
D0MSG:   DB    "Divide by zero error",0           ;[3926] 
OVMSG:   DB    "Overflow error",0                 ;[393B] 
SNMSG:   DB    "Syntax error",0                   ;[394A] 
MOPMSG:  DB    "Something missing",0              ;[3957] 
ARGMSG:  DB    "Function argument error",0        ;[3969] 
NIERR:   DB    "NOT YET IMPLEMENTED",0            ;[3981] 
RAMSG:   DB    "Redimensioned array",0            ;[3995] 
ULMSG:   DB    "Line, LABEL or PROC not found",0  ;[39A9] 
NRMSG:   DB    "Number out of range",0            ;[39C7] 
SRMSG:   DB    "Subscript out of range",0         ;[39DB] 
TMMSG:   DB    "Type mismatch",0                  ;[39F2] 
TLMSG:   DB    "Line too long",0                  ;[3A00] 
CCMSG:   DB    "Cannot continue",0                ;[3A0E] 
ODMSG:   DB    "Out of Data",0                    ;[3A1E] 
RGMSG:   DB    "RETURN without GOSUB",0           ;[3A2A] 
NFMSG:   DB    "NEXT without FOR",0               ;[3A3F] 
UVMSG:   DB    "Undefined variable",0             ;[3A50] 
URMSG:   DB    "UNTIL without REPEAT",0           ;[3A63] 
WWMSG:   DB    "WEND without WHILE",0             ;[3A78] 
WDMSG:   DB    "WHILE without WEND",0             ;[3A8B] 
SMMSG:   DB    "Return stack full",0              ;[3A9E] 
RUMSG:   DB    "REPEAT without UNTIL",0           ;[3AB0] 
GRMSG:   DB    "GOSUB without RETURN",0           ;[3AC5] 
EPMSG:   DB    "ENDPROC without PROC",0           ;[3ADA] 
BTMS:    DB    $0D,"Bad Tape",0                   ;[3AEF] 

;
; Error jump points - increment A (error num) a number of times, 
; depending on label, and display corresponding message.
;
ERR_BAD_TAPE:           DB    0AFH,3CH,6          ;[3AF9] 
ERR_ENDPROC_NO_PROC:    DB    0AFH,3CH,6          ;[3AFC] 
ERR_GOSUB_NO_RETURN:    DB    0AFH,3CH,6          ;[3AFF] 
ERR_REPEAT_NO_UNTIL:    DB    0AFH,3CH,6          ;[3B02] 
ERR_RETURN_STACK_FULL:  DB    0AFH,3CH,6          ;[3B05] 
ERR_WHILE_NO_WEND:      DB    0AFH,3CH,6          ;[3B08] 
ERR_WEND_NO_WHILE:      DB    0AFH,3CH,6          ;[3B0B] 
ERR_UNTIL_NO_REPEAT:    DB    0AFH,3CH,6          ;[3B0E] 
ERR_UNDEFINED_VAR:      DB    0AFH,3CH,6          ;[3B11] 
ERR_NEXT_NO_FOR:        DB    0AFH,3CH,6          ;[3B14] 
ERR_RETURN_NO_GOSUB:    DB    0AFH,3CH,6          ;[3B17] 
ERR_OUT_OF_DATA:        DB    0AFH,3CH,6          ;[3B1A] 
ERR_CANNOT_CONT:        DB    0AFH,3CH,6          ;[3B1D] 
ERR_LINE_TOO_LONG:      DB    0AFH,3CH,6          ;[3B20] 
ERR_TYPE_MISMATCH:      DB    0AFH,3CH,6          ;[3B23] 
ERR_SUBS_OUT_RANGE:     DB    0AFH,3CH,6          ;[3B26] 
ERR_NUM_OUT_RANGE:      DB    0AFH,3CH,6          ;[3B29] 
ERR_NOT_FOUND:          DB    0AFH,3CH,6          ;[3B2C] 
ERR_REDIM_ARRAY:        DB    0AFH,3CH,6          ;[3B2F] 
ERR_NOT_YET_IMP:        DB    0AFH,3CH,6          ;[3B32] 
ERR_FUNCT_ARG:          DB    0AFH,3CH,6          ;[3B35] 
ERR_SOMETHG_MISSG:      DB    0AFH,3CH,6          ;[3B38] 
ERR_SYNTAX:             DB    0AFH,3CH,6          ;[3B3B] 
ERR_OVERFLOW:           DB    0AFH,3CH,6          ;[3B3E] 
ERR_DIVIDE_BY_Z:        DB    0AFH,3CH,6          ;[3B41] 
ERR_MISSING_BRACKET:    DB    0AFH,3CH,6          ;[3B44] 
ERR_STRING:             DB    0AFH,3CH,6          ;[3B47] 
ERR_WRONG_MODE:         DB    0AFH,3CH,6          ;[3B4A] 
ERR_OUT_OF_MEM:         DB    0AFH,3CH            ;[3B4D] 

;
; Display error from lookup table. (SYSVAR_ERRAM: unused RAM call)
;
DISP_ERROR_A:
    CALL  SYSVAR_ERRAM              ;[3B4F] 
    LD    HL,(SYSVAR_ERRTBL)        ;[3B52] Table of error messages. (see DATA_ERROR_MSGS)
    LD    C,A                       ;[3B55] 
ERROR_PRINT:
    LD    A,(HL)                    ;[3B56] Lookup error message. (terminated by zero)
    INC   HL                        ;[3B57] 
    OR    A                         ;[3B58] 
    JR    NZ,ERROR_PRINT            ;[3B59] Skip to next message (=zero) in tbl
    DEC   C                         ;[3B5B] 
    JR    NZ,ERROR_PRINT            ;[3B5C] If C is zero, message found.
    CALL  PLINE                     ;[3B5E] 
    JP    BASIC                     ;[3B61] 

;
; MONitor.
;
BASIC_COM_MON:
    EX    (SP),HL                   ;[3B64] 
    DEC   HL                        ;[3B65] 
    LD    ($61B0),HL                ;[3B66] 
    EX    (SP),HL                   ;[3B69] 
    INC   SP                        ;[3B6A] 
    INC   SP                        ;[3B6B] 
    LD    ($61AE),SP                ;[3B6C] 
    LD    SP,$61AE                  ;[3B70] 
    PUSH  IY                        ;[3B73] 
    PUSH  IX                        ;[3B75] 
    EXX                             ;[3B77] 
    EX    AF,AF'                    ;[3B78] 
    PUSH  BC                        ;[3B79] 
    PUSH  DE                        ;[3B7A] 
    PUSH  HL                        ;[3B7B] 
    PUSH  AF                        ;[3B7C] 
    EXX                             ;[3B7D] 
    EX    AF,AF'                    ;[3B7E] 
    PUSH  BC                        ;[3B7F] 
    PUSH  DE                        ;[3B80] 
    PUSH  HL                        ;[3B81] 
    PUSH  AF                        ;[3B82] 
    LD    ($61BA),SP                ;[3B83] 
    LD    A,$C3                     ;[3B87] 
    LD    ($61B2),A                 ;[3B89] 
    CALL  MONITOR_X1                ;[3B8C] 
    LD    A,$0E                     ;[3B8F] 
    RST   $08                       ;[3B91] 
    JR    $3B9E                     ;[3B92] 
    LD    SP,($61BA)                ;[3B94] 
    LD    HL,$3BC8                  ;[3B98] 
    CALL  PLINE                     ;[3B9B] 
    LD    A,$2A                     ;[3B9E] 
    RST   $08                       ;[3BA0] 
    CALL  SYSVAR_LINP               ;[3BA1] 
    LD    DE,INPBUF                 ;[3BA4] 
    LD    A,(DE)                    ;[3BA7] 
    CALL  TEST_MON_LETTER           ;[3BA8] 
    SUB   $41                       ;[3BAB] 
    JR    C,$3B94                   ;[3BAD] 
    CP    $1A                       ;[3BAF] 
    JR    NC,$3B94                  ;[3BB1] 
    RLCA                            ;[3BB3] 
    INC   DE                        ;[3BB4] 
    LD    BC,$3BCF                  ;[3BB5] 
    LD    L,A                       ;[3BB8] 
    LD    H,$00                     ;[3BB9] 
    ADD   HL,BC                     ;[3BBB] 
    LD    A,(HL)                    ;[3BBC] 
    INC   HL                        ;[3BBD] 
    LD    H,(HL)                    ;[3BBE] 
    LD    L,A                       ;[3BBF] 
    LD    BC,$3B9E                  ;[3BC0] 
    PUSH  BC                        ;[3BC3] 
    RST   $10                       ;[3BC4] 
    CP    $0D                       ;[3BC5] 
    JP    (HL)                      ;[3BC7] 

;
; Data ?????'. Monitor error message.
;
    DB $3F,$3F,$3F,$3F,$0D,$1E,$00  ;[3BC8]  ????...

    ADC   A,E                       ;[3BCF] Two byte addresses for the monitor commands A-Z
    DEC   A                         ;[3BD0] 
    EX    AF,AF'                    ;[3BD1] 
    INC   A                         ;[3BD2] 
    LD    (HL),B                    ;[3BD3] 
    DEC   A                         ;[3BD4] 
    CALL  M,$D43E                   ;[3BD5] 
    LD    A,$CC                     ;[3BD8] 
    DEC   A                         ;[3BDA] 
    OR    $3D                       ;[3BDB] 
    LD    (HL),H                    ;[3BDD] 
    INC   A                         ;[3BDE] 
    LD    A,B                       ;[3BDF] 
    DEC   A                         ;[3BE0] 
    RET   PE                        ;[3BE1] 
    JR    C,$3B78                   ;[3BE2] 
    DEC   SP                        ;[3BE4] 
    LD    HL,($663E)                ;[3BE5] 
    INC   A                         ;[3BE8] 
    SUB   H                         ;[3BE9] 
    DEC   SP                        ;[3BEA] 
    EX    DE,HL                     ;[3BEB] 
    DEC   A                         ;[3BEC] 
    RRA                             ;[3BED] 
    INC   A                         ;[3BEE] 
    SBC   A,$3D                     ;[3BEF] 
    LD    L,D                       ;[3BF1] 
    CCF                             ;[3BF2] 
    INC   BC                        ;[3BF3] 
    INC   A                         ;[3BF4] 
    LD    H,B                       ;[3BF5] 
    DEC   A                         ;[3BF6] 
    LD    L,(HL)                    ;[3BF7] 
    LD    A,$44                     ;[3BF8] 
    LD    A,$00                     ;[3BFA] 
    LD    A,$8E                     ;[3BFC] 
    LD    A,$94                     ;[3BFE] 
    DEC   SP                        ;[3C00] 
    CP    E                         ;[3C01] 
    INC   A                         ;[3C02] 

;
; Monitor S command.
;
MONITOR_S:
    LD    A,$04                     ;[3C03] 
    JP    PUTCHAR                   ;[3C05] 

;
; Monitor B command.
;
MONITOR_B:
    JR    Z,$3C17                   ;[3C08] 
    CALL  SUB_ARGUMENT_INTO_HL      ;[3C0A] 
    LD    ($61B6),HL                ;[3C0D] 
    LD    A,(HL)                    ;[3C10] 
    LD    ($61B5),A                 ;[3C11] 
    LD    (HL),$F7                  ;[3C14] 
    RET                             ;[3C16] 

    LD    HL,($61B6)                ;[3C17] 
    LD    A,($61B5)                 ;[3C1A] 
    LD    (HL),A                    ;[3C1D] 
    RET                             ;[3C1E] 

;
; Monitor P command.
;
MONITOR_P:
    CALL  SUB_ARGUMENT_INTO_HL      ;[3C1F] 
    LD    DE,($61B0)                ;[3C22] 
    ADD   HL,DE                     ;[3C26] 
    LD    ($61B0),HL                ;[3C27] 
    JP    MONITOR_X1                ;[3C2A] 

;
; TBD
;
SUB_TBD_3C2D:
    DEC   BC                        ;[3C2D] 
    DEC   BC                        ;[3C2E] 
    INC   BC                        ;[3C2F] 
    LD    L,C                       ;[3C30] 
    LD    H,B                       ;[3C31] 
    LD    ($61B8),HL                ;[3C32] 
    PUSH  BC                        ;[3C35] 
    CALL  DISPLAY_HL                ;[3C36] 
    LD    A,$3C                     ;[3C39] 
    RST   $08                       ;[3C3B] 
    LD    A,(HL)                    ;[3C3C] 
    CALL  PRINT_HEX_A               ;[3C3D] 
    LD    A,$3E                     ;[3C40] 
    RST   $08                       ;[3C42] 
    CALL  OUTPUT_SPACE              ;[3C43] 
    CALL  SYSVAR_LINP               ;[3C46] 
    POP   BC                        ;[3C49] 
    LD    DE,INPBUF                 ;[3C4A] 
    LD    A,(DE)                    ;[3C4D] 
    CP    $0D                       ;[3C4E] 
    JR    Z,$3C2F                   ;[3C50] 
    CP    $2F                       ;[3C52] 
    JR    Z,SUB_TBD_3C2D            ;[3C54] 
    CP    $2E                       ;[3C56] 
    RET   Z                         ;[3C58] 
    RST   $10                       ;[3C59] 
    CP    $0D                       ;[3C5A] 
    JR    Z,$3C30                   ;[3C5C] 
    CALL  SUB_ARGUMENT_INTO_HL      ;[3C5E] 
    LD    A,L                       ;[3C61] 
    LD    (BC),A                    ;[3C62] 
    INC   BC                        ;[3C63] 
    JR    $3C59                     ;[3C64] 

;
; Monitor M command.
;
MONITOR_M:
    JR    NZ,$3C6D                  ;[3C66] 
    LD    HL,($61B8)                ;[3C68] 
    JR    $3C70                     ;[3C6B] 
    CALL  SUB_ARGUMENT_INTO_HL      ;[3C6D] 
    LD    C,L                       ;[3C70] 
    LD    B,H                       ;[3C71] 
    JR    $3C59                     ;[3C72] 

;
; Monitor H command.
;
MONITOR_H:
    JR    NZ,$3C7B                  ;[3C74] 
    LD    HL,($61B8)                ;[3C76] 
    JR    $3C7E                     ;[3C79] 
    CALL  SUB_ARGUMENT_INTO_HL      ;[3C7B] 
    LD    B,$10                     ;[3C7E] 
    PUSH  BC                        ;[3C80] 
    CALL  $3CA5                     ;[3C81] 
    CALL  OUTPUT_SPACE              ;[3C84] 
    LD    B,$08                     ;[3C87] 
    LD    A,(HL)                    ;[3C89] 
    INC   HL                        ;[3C8A] 
    CALL  $3D55                     ;[3C8B] 
    DJNZ  $3C89                     ;[3C8E] 
    LD    A,$1E                     ;[3C90] 
    RST   $08                       ;[3C92] 
    LD    A,$1F                     ;[3C93] 
    RST   $08                       ;[3C95] 
    CALL  ESC                       ;[3C96] 
    POP   BC                        ;[3C99] 
    JR    Z,$3CA1                   ;[3C9A] 
    DJNZ  $3C80                     ;[3C9C] 
    LD    ($61B8),HL                ;[3C9E] 
    LD    A,$1E                     ;[3CA1] 
    RST   $08                       ;[3CA3] 
    RET                             ;[3CA4] 

    CALL  DISPLAY_HL                ;[3CA5] 
    CALL  OUTPUT_SPACE              ;[3CA8] 
    LD    B,$08                     ;[3CAB] 
    PUSH  HL                        ;[3CAD] 
    LD    A,(HL)                    ;[3CAE] 
    INC   HL                        ;[3CAF] 
    CALL  $3D12                     ;[3CB0] 
    DJNZ  $3CAE                     ;[3CB3] 
    POP   HL                        ;[3CB5] 
    RET                             ;[3CB6] 

;
; Print carriage-return char
;
SUB_PRINT_CR:
    LD    A,$0D                     ;[3CB7] 
    RST   $08                       ;[3CB9] 
    RET                             ;[3CBA] 

;
; Monitor Z command.
;
MONITOR_Z:
    LD    IX,DATA_MONITOR           ;[3CBB] 
    LD    DE,$619A                  ;[3CBF] 
    LD    B,$0C                     ;[3CC2] 
    PUSH  BC                        ;[3CC4] 
    LD    B,$03                     ;[3CC5] 
    LD    A,(IX+$00)                ;[3CC7] 
    RST   $08                       ;[3CCA] 
    INC   IX                        ;[3CCB] 
    DJNZ  $3CC7                     ;[3CCD] 
    CALL  OUTPUT_SPACE              ;[3CCF] 
    LD    A,(DE)                    ;[3CD2] 
    LD    L,A                       ;[3CD3] 
    INC   DE                        ;[3CD4] 
    LD    A,(DE)                    ;[3CD5] 
    LD    H,A                       ;[3CD6] 
    INC   DE                        ;[3CD7] 
    CALL  $3CA5                     ;[3CD8] 
    LD    A,$1E                     ;[3CDB] 
    RST   $08                       ;[3CDD] 
    LD    A,$1F                     ;[3CDE] 
    RST   $08                       ;[3CE0] 
    POP   BC                        ;[3CE1] 
    DJNZ  $3CC4                     ;[3CE2] 
    LD    A,$1E                     ;[3CE4] 
    RST   $08                       ;[3CE6] 
    RET                             ;[3CE7] 

;
; Data for Z command - The register names.
;
DATA_MONITOR:
    DB $41,$46,$20,$48,$4C,$20,$44,$45      ;[3CE8]  AF.HL.DE
    DB $20,$42,$43,$20,$41,$46,$27,$48      ;[3CF0]  .BC.AF'H
    DB $4C,$27,$44,$45,$27,$42,$43,$27      ;[3CF8]  L'DE'BC'
    DB $49,$58,$20,$49,$59,$20,$53,$50      ;[3D00]  IX.IY.SP
    DB $20,$50,$43,$20                      ;[3D08]  .PC.

;
; Display HL.
;
DISPLAY_HL:
    CALL  PHEXHL                    ;[3D0C] 
    JP    OUTPUT_SPACE              ;[3D0F] 
    CALL  PRINT_HEX_A               ;[3D12] 
    JR    $3D0F                     ;[3D15] 

;
; Pick up argument into HL.
;
SUB_ARGUMENT_INTO_HL:
    CALL  $3D24                     ;[3D17] 
    LD    A,(DE)                    ;[3D1A] 
    CP    $0D                       ;[3D1B] 
    RET   Z                         ;[3D1D] 
    CP    $20                       ;[3D1E] 
    RET   Z                         ;[3D20] 
    JP    $3B94                     ;[3D21] 
    LD    HL,$0000                  ;[3D24] Subroutine called by routine above.
    RST   $10                       ;[3D27] 
    LD    A,(DE)                    ;[3D28] 
    CALL  TEST_MON_LETTER           ;[3D29] 
    SUB   $30                       ;[3D2C] 
    RET   C                         ;[3D2E] 
    CP    $0A                       ;[3D2F] 
    JR    C,$3D3B                   ;[3D31] 
    SUB   $07                       ;[3D33] 
    CP    $0A                       ;[3D35] 
    RET   C                         ;[3D37] 
    CP    $10                       ;[3D38] 
    RET   NC                        ;[3D3A] 
    ADD   HL,HL                     ;[3D3B] 
    ADD   HL,HL                     ;[3D3C] 
    ADD   HL,HL                     ;[3D3D] 
    ADD   HL,HL                     ;[3D3E] 
    ADD   A,L                       ;[3D3F] 
    LD    L,A                       ;[3D40] 
    INC   DE                        ;[3D41] 
    JR    $3D28                     ;[3D42] 

;
; Pick up three arguments.
;
SUB_ARGUMENT_3:
    POP   IX                        ;[3D44] 
    CALL  SUB_ARGUMENT_INTO_HL      ;[3D46] 
    PUSH  HL                        ;[3D49] 
    CALL  SUB_ARGUMENT_INTO_HL      ;[3D4A] 
    PUSH  HL                        ;[3D4D] 
    CALL  SUB_ARGUMENT_INTO_HL      ;[3D4E] 
    LD    C,L                       ;[3D51] 
    LD    B,H                       ;[3D52] 
    JP    (IX)                      ;[3D53] 
    AND   $7F                       ;[3D55] 
    CP    $20                       ;[3D57] 
    JR    NC,$3D5D                  ;[3D59] 
    LD    A,$2E                     ;[3D5B] 
    JP    PUTCHAR                   ;[3D5D] 

;
; Monitor T command.
;
MONITOR_T:
    CALL  SUB_ARGUMENT_INTO_HL      ;[3D60] 
    LD    A,(DE)                    ;[3D63] 
    CP    $0D                       ;[3D64] 
    RET   Z                         ;[3D66] 
    INC   DE                        ;[3D67] 
    LD    A,(DE)                    ;[3D68] 
    CP    $0D                       ;[3D69] 
    RET   Z                         ;[3D6B] 
    LD    (HL),A                    ;[3D6C] 
    INC   HL                        ;[3D6D] 
    JR    $3D67                     ;[3D6E] 

;
; Monitor C command.
;
MONITOR_C:
    CALL  SUB_ARGUMENT_3            ;[3D70] 
    POP   DE                        ;[3D73] 
    POP   HL                        ;[3D74] 
    LDIR                            ;[3D75] 
    RET                             ;[3D77] 

;
; Monitor I command.
;
MONITOR_I:
    CALL  SUB_ARGUMENT_3            ;[3D78] 
    POP   DE                        ;[3D7B] 
    POP   HL                        ;[3D7C] 
    CALL  CHLDE                     ;[3D7D] 
    JR    NC,$3D75                  ;[3D80] 
    ADD   HL,BC                     ;[3D82] 
    EX    DE,HL                     ;[3D83] 
    ADD   HL,BC                     ;[3D84] 
    EX    DE,HL                     ;[3D85] 
    DEC   DE                        ;[3D86] 
    DEC   HL                        ;[3D87] 
    LDDR                            ;[3D88] 
    RET                             ;[3D8A] 

;
; Monitor A command.
;
MONITOR_A:
    CALL  SUB_ARGUMENT_INTO_HL      ;[3D8B] 
    PUSH  HL                        ;[3D8E] 
    CALL  SUB_ARGUMENT_INTO_HL      ;[3D8F] 
    LD    E,L                       ;[3D92] 
    LD    D,H                       ;[3D93] 
    POP   HL                        ;[3D94] 
    PUSH  HL                        ;[3D95] 
    ADD   HL,DE                     ;[3D96] 
    CALL  DISPLAY_HL                ;[3D97] 
    POP   HL                        ;[3D9A] 
    PUSH  HL                        ;[3D9B] 
    OR    A                         ;[3D9C] 
    SBC   HL,DE                     ;[3D9D] 
    CALL  DISPLAY_HL                ;[3D9F] 
    POP   HL                        ;[3DA2] 
    EX    DE,HL                     ;[3DA3] 
    DEC   HL                        ;[3DA4] 
    SCF                             ;[3DA5] 
    SBC   HL,DE                     ;[3DA6] 
    LD    A,H                       ;[3DA8] 
    OR    A                         ;[3DA9] 
    JR    Z,$3DB8                   ;[3DAA] 
    INC   A                         ;[3DAC] 
    JR    Z,$3DC2                   ;[3DAD] 
    LD    HL,DATA_MONITOR_A         ;[3DAF] 
    CALL  PLINE                     ;[3DB2] 
    JP    SUB_PRINT_CR              ;[3DB5] 
    LD    A,L                       ;[3DB8] 
    CP    $80                       ;[3DB9] 
    JR    NC,$3DAF                  ;[3DBB] 
    CALL  $3D12                     ;[3DBD] 
    JR    $3DB5                     ;[3DC0] 
    LD    A,L                       ;[3DC2] 
    CP    $80                       ;[3DC3] 
    JR    C,$3DAF                   ;[3DC5] 
    JR    $3DBD                     ;[3DC7] 

;
; Data '??' used in A comand.
;
DATA_MONITOR_A:
    DB $3F,$3F,$00                  ;[3DC9]  ??.

    CALL  SUB_ARGUMENT_3            ;[3DCC] ???? Doesn't seem to be used!!!!
    LD    A,L                       ;[3DCF] 
    POP   HL                        ;[3DD0] 
    POP   DE                        ;[3DD1] 
    OR    A                         ;[3DD2] 
    SBC   HL,DE                     ;[3DD3] 
    LD    C,L                       ;[3DD5] 
    LD    B,H                       ;[3DD6] 
    LD    H,D                       ;[3DD7] 
    LD    L,E                       ;[3DD8] 
    INC   DE                        ;[3DD9] 
    LD    (HL),A                    ;[3DDA] 
    LDIR                            ;[3DDB] 
    RET                             ;[3DDD] 

;
; Monitor Q command.
;
MONITOR_Q:
    CALL  SUB_ARGUMENT_INTO_HL      ;[3DDE] 
    LD    C,L                       ;[3DE1] 
    LD    B,H                       ;[3DE2] 
    IN    A,(C)                     ;[3DE3] 
    CALL  $3D12                     ;[3DE5] 
    JP    SUB_PRINT_CR              ;[3DE8] 

;
; Monitor O command.
;
MONITOR_O:
    CALL  SUB_ARGUMENT_INTO_HL      ;[3DEB] 
    LD    C,L                       ;[3DEE] 
    LD    B,H                       ;[3DEF] 
    CALL  SUB_ARGUMENT_INTO_HL      ;[3DF0] 
    OUT   (C),L                     ;[3DF3] 
    RET                             ;[3DF5] 

;
; Monitor B command.
;
MONITOR_B1:
    CALL  SUB_ARGUMENT_INTO_HL      ;[3DF6] 
    JP    (HL)                      ;[3DF9] 

;
; Test for a Monitor command letter.
;
TEST_MON_LETTER:
    CP    $40                       ;[3DFA] 
    RET   C                         ;[3DFC] 
    RES   5,A                       ;[3DFD] 
    RET                             ;[3DFF] 

;
; Monitor W command.
;
MONITOR_W:
    CALL  SUB_ARGUMENT_INTO_HL      ;[3E00] 
    PUSH  HL                        ;[3E03] 
    CALL  SUB_ARGUMENT_INTO_HL      ;[3E04] 
    LD    E,L                       ;[3E07] 
    LD    D,H                       ;[3E08] 
    POP   HL                        ;[3E09] 
    LD    A,(HL)                    ;[3E0A] 
    CP    E                         ;[3E0B] 
    JR    NZ,$3E17                  ;[3E0C] 
    INC   HL                        ;[3E0E] 
    LD    A,(HL)                    ;[3E0F] 
    DEC   HL                        ;[3E10] 
    CP    D                         ;[3E11] 
    JR    NZ,$3E17                  ;[3E12] 
    CALL  SUB_MONITOR_L             ;[3E14] 
    CALL  ESC                       ;[3E17] 
    RET   Z                         ;[3E1A] 
    INC   HL                        ;[3E1B] 
    LD    A,L                       ;[3E1C] 
    OR    H                         ;[3E1D] 
    JR    NZ,$3E0A                  ;[3E1E] 
    RET                             ;[3E20] 

;
; L command subroutine.
;
SUB_MONITOR_L:
    CALL  DISPLAY_HL                ;[3E21] 
    LD    ($61B8),HL                ;[3E24] 
    JP    SUB_PRINT_CR              ;[3E27] 

;
; Monitor L command.
;
MONITOR_L:
    CALL  SUB_ARGUMENT_INTO_HL      ;[3E2A] 
    PUSH  HL                        ;[3E2D] 
    CALL  SUB_ARGUMENT_INTO_HL      ;[3E2E] 
    LD    E,L                       ;[3E31] 
    POP   HL                        ;[3E32] 
    LD    A,(HL)                    ;[3E33] 
    CP    E                         ;[3E34] 
    JR    NZ,$3E3A                  ;[3E35] 
    CALL  SUB_MONITOR_L             ;[3E37] 
    CALL  ESC                       ;[3E3A] 
    RET   Z                         ;[3E3D] 
    INC   HL                        ;[3E3E] 
    LD    A,L                       ;[3E3F] 
    OR    H                         ;[3E40] 
    JR    NZ,$3E33                  ;[3E41] 
    RET                             ;[3E43] 

;
; Monitor V command.
;
MONITOR_V:
    CALL  SUB_ARGUMENT_3            ;[3E44] 
    POP   DE                        ;[3E47] 
    POP   HL                        ;[3E48] 
    LD    A,(DE)                    ;[3E49] 
    CP    (HL)                      ;[3E4A] 
    CALL  NZ,DISPLAY_HL             ;[3E4B] 
    INC   DE                        ;[3E4E] 
    INC   HL                        ;[3E4F] 
    PUSH  BC                        ;[3E50] 
    CALL  ESC                       ;[3E51] 
    POP   BC                        ;[3E54] 
    JR    Z,$3E5C                   ;[3E55] 
    DEC   BC                        ;[3E57] 
    LD    A,B                       ;[3E58] 
    OR    C                         ;[3E59] 
    JR    NZ,$3E49                  ;[3E5A] 
    JP    SUB_PRINT_CR              ;[3E5C] 

;
; Part of U command.
;
SUB_MONITOR_U:
    POP   DE                        ;[3E5F] 
    POP   HL                        ;[3E60] 
    INC   HL                        ;[3E61] 
    INC   HL                        ;[3E62] 
    INC   HL                        ;[3E63] 
    INC   IX                        ;[3E64] 
    INC   IX                        ;[3E66] 
    POP   BC                        ;[3E68] 
    DJNZ  $3E75                     ;[3E69] 
    JP    $3B94                     ;[3E6B] 

;
; Monitor U command.
;
MONITOR_U:
    LD    HL,DATA_MONITOR           ;[3E6E] 
    LD    IX,$619A                  ;[3E71] 
    PUSH  BC                        ;[3E75] 
    PUSH  HL                        ;[3E76] 
    PUSH  DE                        ;[3E77] 
    LD    B,$03                     ;[3E78] 
    LD    A,(DE)                    ;[3E7A] 
    CP    (HL)                      ;[3E7B] 
    INC   DE                        ;[3E7C] 
    INC   HL                        ;[3E7D] 
    JR    NZ,SUB_MONITOR_U          ;[3E7E] 
    DJNZ  $3E7A                     ;[3E80] 
    POP   BC                        ;[3E82] 
    POP   BC                        ;[3E83] 
    POP   BC                        ;[3E84] 

;
; Monitor X command.
;
MONITOR_X:
    CALL  SUB_ARGUMENT_INTO_HL      ;[3E85] 
    LD    (IX+$00),L                ;[3E88] Display memory starting from where DE points.
    LD    (IX+$01),H                ;[3E8B] 
MONITOR_X1:
    LD    DE,$619A                  ;[3E8E] 
    LD    B,$04                     ;[3E91] 
    CALL  SUB_FLAGS                 ;[3E93] 
    LD    A,$1E                     ;[3E96] 
    RST   $08                       ;[3E98] 
    LD    A,$1F                     ;[3E99] 
    RST   $08                       ;[3E9B] 
    LD    B,$08                     ;[3E9C] 
    CALL  SUB_FLAGS                 ;[3E9E] 
    CALL  $3EB6                     ;[3EA1] 
    LD    A,$1E                     ;[3EA4] 
    RST   $08                       ;[3EA6] 
    JP    SUB_PRINT_CR              ;[3EA7] 

;
; Display the flags.
;
SUB_FLAGS:
    LD    A,(DE)                    ;[3EAA] 
    LD    L,A                       ;[3EAB] 
    INC   DE                        ;[3EAC] 
    LD    A,(DE)                    ;[3EAD] 
    LD    H,A                       ;[3EAE] 
    INC   DE                        ;[3EAF] 
    CALL  DISPLAY_HL                ;[3EB0] 
    DJNZ  SUB_FLAGS                 ;[3EB3] 
    RET                             ;[3EB5] 

    LD    A,($619A)                 ;[3EB6] 
    LD    HL,DATA_FLAGS             ;[3EB9] 
    LD    C,A                       ;[3EBC] 
    SCF                             ;[3EBD] 
    RL    C                         ;[3EBE] 
    RET   Z                         ;[3EC0] 
    LD    A,(HL)                    ;[3EC1] 
    JR    C,$3EC6                   ;[3EC2] 
    LD    A,$2E                     ;[3EC4] 
    RST   $08                       ;[3EC6] 
    INC   HL                        ;[3EC7] 
    OR    A                         ;[3EC8] 
    JR    $3EBE                     ;[3EC9] 

;
; Data. Flags.
;
DATA_FLAGS:
    DB $53,$5A,$31,$48,$31,$50,$4E,$43      ;[3ECB]  SZ1H1PNC
    DB $00                                  ;[3ED3]  .

;
; Monitor E command.
;
MONITOR_E:
    JR    Z,$3EDB                   ;[3ED4] 
    CALL  SUB_ARGUMENT_INTO_HL      ;[3ED6] 
    JR    $3EDE                     ;[3ED9] 
    LD    HL,($61B0)                ;[3EDB] 
    LD    ($61B3),HL                ;[3EDE] 
    LD    SP,($61BA)                ;[3EE1] 
    POP   AF                        ;[3EE5] 
    POP   HL                        ;[3EE6] 
    POP   DE                        ;[3EE7] 
    POP   BC                        ;[3EE8] 
    EXX                             ;[3EE9] 
    EX    AF,AF'                    ;[3EEA] 
    POP   AF                        ;[3EEB] 
    POP   HL                        ;[3EEC] 
    POP   DE                        ;[3EED] 
    POP   BC                        ;[3EEE] 
    EXX                             ;[3EEF] 
    EX    AF,AF'                    ;[3EF0] 
    POP   IX                        ;[3EF1] 
    POP   IY                        ;[3EF3] 
    LD    SP,($61AE)                ;[3EF5] 
    JP    $61B2                     ;[3EF9] 

;
; Monitor D command.
;
MONITOR_D:
    CALL  SUB_ARGUMENT_3            ;[3EFC] 
    PUSH  HL                        ;[3EFF] 
    CALL  $3F4E                     ;[3F00] 
    CALL  WRITE_FNAME               ;[3F03] 
    POP   DE                        ;[3F06] 
    POP   HL                        ;[3F07] 
    POP   BC                        ;[3F08] 
    PUSH  BC                        ;[3F09] 
    OR    A                         ;[3F0A] 
    SBC   HL,BC                     ;[3F0B] 
    INC   HL                        ;[3F0D] 
    LD    C,L                       ;[3F0E] 
    LD    B,H                       ;[3F0F] 
    POP   HL                        ;[3F10] 
    PUSH  DE                        ;[3F11] 
    CALL  WSYNC                     ;[3F12] 
    LD    A,$4D                     ;[3F15] 
    CALL  SYSVAR_WBYTE              ;[3F17] 
    LD    A,C                       ;[3F1A] 
    CALL  SYSVAR_WBYTE              ;[3F1B] 
    LD    A,B                       ;[3F1E] 
    CALL  SYSVAR_WBYTE              ;[3F1F] 
    CALL  $3F46                     ;[3F22] 
    LD    E,$00                     ;[3F25] 
    LD    A,(HL)                    ;[3F27] 
    CALL  SYSVAR_WBYTE              ;[3F28] 
    INC   HL                        ;[3F2B] 
    ADD   A,E                       ;[3F2C] 
    LD    E,A                       ;[3F2D] 
    DEC   BC                        ;[3F2E] 
    LD    A,B                       ;[3F2F] 
    OR    C                         ;[3F30] 
    JR    NZ,$3F27                  ;[3F31] 
    LD    A,E                       ;[3F33] 
    CALL  SYSVAR_WBYTE              ;[3F34] 
    LD    A,$45                     ;[3F37] 
    CALL  SYSVAR_WBYTE              ;[3F39] 
    POP   HL                        ;[3F3C] 
    CALL  $3F46                     ;[3F3D] 
    CALL  SYSVAR_WBYTE              ;[3F40] 
    JP    MOTOFF                    ;[3F43] 
    LD    A,L                       ;[3F46] Write HL to tape.
    CALL  SYSVAR_WBYTE              ;[3F47] 
    LD    A,H                       ;[3F4A] 
    JP    SYSVAR_WBYTE              ;[3F4B] 
    RST   $10                       ;[3F4E] Check for valid file name.
    CP    $22                       ;[3F4F] 
    JP    NZ,$3B94                  ;[3F51] 
    PUSH  DE                        ;[3F54] 
    INC   DE                        ;[3F55] 
    LD    A,(DE)                    ;[3F56] 
    CP    $0D                       ;[3F57] 
    JP    Z,$3B94                   ;[3F59] 
    CP    $22                       ;[3F5C] 
    JR    NZ,$3F55                  ;[3F5E] 
    POP   DE                        ;[3F60] 
    RET                             ;[3F61] 

;
; MLOAD
;
BASIC_COM_MLOAD:
    LD    HL,(SYSVAR_STACK)         ;[3F62] 
    LD    ($61BA),HL                ;[3F65] 
    JR    $3F78                     ;[3F68] 

;
; Monitor P command.
;
MONITOR_P1:
    CALL  $3F4E                     ;[3F6A] 
    LD    HL,(SYSVAR_POLBUF)        ;[3F6D] 
    PUSH  HL                        ;[3F70] 
    EX    DE,HL                     ;[3F71] 
    LD    BC,$00FF                  ;[3F72] 
    LDIR                            ;[3F75] 
    POP   DE                        ;[3F77] 
    CALL  TAPE_READ                 ;[3F78] 
    CALL  RSYNC                     ;[3F7B] 
    CALL  RBYTE                     ;[3F7E] 
    CP    $4D                       ;[3F81] 
    JR    NZ,$3FC4                  ;[3F83] 
    CALL  RBYTE                     ;[3F85] 
    LD    C,A                       ;[3F88] 
    CALL  RBYTE                     ;[3F89] 
    LD    B,A                       ;[3F8C] 
    CALL  RBYTE                     ;[3F8D] 
    LD    L,A                       ;[3F90] 
    CALL  RBYTE                     ;[3F91] 
    LD    H,A                       ;[3F94] 
    LD    E,$00                     ;[3F95] 
    CALL  RBYTE                     ;[3F97] 
    LD    (HL),A                    ;[3F9A] 
    INC   HL                        ;[3F9B] 
    ADD   A,E                       ;[3F9C] 
    LD    E,A                       ;[3F9D] 
    DEC   BC                        ;[3F9E] 
    LD    A,B                       ;[3F9F] 
    OR    C                         ;[3FA0] 
    JR    NZ,$3F97                  ;[3FA1] 
    CALL  RBYTE                     ;[3FA3] 
    CP    E                         ;[3FA6] 
    JR    NZ,$3FC4                  ;[3FA7] 
    CALL  RBYTE                     ;[3FA9] 
    CP    $4E                       ;[3FAC] 
    JR    Z,$3F7B                   ;[3FAE] 
    CALL  RBYTE                     ;[3FB0] 
    LD    L,A                       ;[3FB3] 
    CALL  RBYTE                     ;[3FB4] 
    LD    H,A                       ;[3FB7] 
    CALL  MOTOFF                    ;[3FB8] 
    LD    A,L                       ;[3FBB] 
    OR    H                         ;[3FBC] 
    JR    NZ,SUB_MONITOR_R          ;[3FBD] 
    LD    A,$0D                     ;[3FBF] 
    RST   $08                       ;[3FC1] 
    RET                             ;[3FC2] 

;
; Part of R routine.
;
SUB_MONITOR_R:
    JP    (HL)                      ;[3FC3] 
    CALL  MOTOFF                    ;[3FC4] 
    LD    HL,BTMS                   ;[3FC7] 
    CALL  PLINE                     ;[3FCA] 
    LD    A,$0D                     ;[3FCD] 
    RST   $08                       ;[3FCF] 
    JP    $3B94                     ;[3FD0] 

;
; Multiply subroutine.
;
SUB_MULTIPLY1:
    JR    NC,$3FD6                  ;[3FD3] 
    INC   E                         ;[3FD5] 
    LD    (HL),A                    ;[3FD6] 
    LD    D,E                       ;[3FD7] 
    DEC   HL                        ;[3FD8] 
    RET                             ;[3FD9] 

;
; Part of DIM routine.
;
SUB_DIM:
    PUSH  HL                        ;[3FDA] 
    INC   HL                        ;[3FDB] 
    LD    (HL),$00                  ;[3FDC] 
    INC   HL                        ;[3FDE] 
    LD    (HL),$00                  ;[3FDF] 
    POP   HL                        ;[3FE1] 
    JP    EDMSUB                    ;[3FE2] 
PATCH6:
    LD    A,B                       ;[3FE5] Set to FF and not used.
    OR    A                         ;[3FE6] 
    RET   Z                         ;[3FE7] 
    JP    STRING_SEEK_END           ;[3FE8] 
FNACOS:
    CALL  BASIC_FN_ARCCOS           ;[3FEB] 
    JP    ARCTAN4                   ;[3FEE] 
SUB_MOD:
    RLA                             ;[3FF1] 
    CALL  NC,ADD                    ;[3FF2] 
    LD    HL,FLOAT_05               ;[3FF5] Let HL = 0.5
    CALL  LNUM2                     ;[3FF8] 
    JP    ADD                       ;[3FFB] 
    RST   $38                       ;[3FFE] 
    NOP                             ;[3FFF] 
