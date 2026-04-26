;***********************************************************************
;*
;*          Camputers Lynx 96k ROM disassembly (version L014)
;*          -------------------------------------------------
;*
;*   Reconstructed from Camputers Lynx "Mark II" source code (Version 505, 31 July 87)
;*
;**************************** VERSION HISTORY **************************
;*
;*   Disassembly, collation and formatting by: Mike Panter 25/06/2022.
;*
;*   VERSION 2 - Additional comments provided by CLAUDE (Anthropic's AI)
;*               under the direction of Mike Panter 07/03/2026.
;*
;**************************** Acknowledgements *************************
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
; 96k ROM entry point ($4000).
; The 48k ROM boots first; at startup it checks whether a byte at EXT_ROM
; ($4000) is non-$FF, and if so calls this address as a subroutine.
; A NOP is placed here so the JP at $4001 is safely skipped on a plain CALL,
; but the true entry point for the full 96k initialisation is EXINIT at $4100.
;
    NOP                             ;[4000] Placeholder - safe landing byte for CALL EXT_ROM
    JP    EXINIT                    ;[4001] Jump to full 96k initialisation routine

; -----------------------------------------------------------------------
; Low-RAM section (LWRAM): copied verbatim into low RAM by EXINIT.
; These routines handle the bank-switching between the 96k extension ROM
; and the main address space.  Because they manipulate the bank register
; themselves, they must reside in RAM (at the same addresses as here, via
; the PHASE directive) so they can still execute when the ROM is mapped out.
; -----------------------------------------------------------------------
;
LWRAM:
;
; ROMOFF: switch the 96k extension ROM out of the address space.
; Port $FF7F controls the bank map. Writing $10 to it disables the ROM,
; exposing the underlying RAM at $4000-$5FFF in its place.
; BC is preserved; all other registers unchanged.
;
ROMOFF:
    PUSH  BC                        ;[4004] Preserve BC (needed by callers)
    LD    BC,$FF7F                  ;[4005] B=$FF, C=$7F: address bank-select port
    LD    A,$10                     ;[4008] $10 = ROM-off flag
    OUT   (C),A                     ;[400A] Write to port $FF7F: ROM disabled, RAM visible
    POP   BC                        ;[400C] Restore BC
    RET                             ;[400D]
;
; ROMON: switch the 96k extension ROM back into the address space.
; Writing $00 to port $FF7F re-enables the ROM at $4000-$5FFF.
; BC is preserved; all other registers unchanged.
;
ROMON:
    PUSH  BC                        ;[400E] Preserve BC
    LD    BC,$FF7F                  ;[400F] B=$FF, C=$7F: address bank-select port
    XOR   A                         ;[4012] A = 0: ROM-on value
    OUT   (C),A                     ;[4013] Write to port $FF7F: ROM re-enabled
    POP   BC                        ;[4015] Restore BC
    RET                             ;[4016]
;
; LAHL: execute LD A,(HL) with HL pointing into low RAM.
; Because the low-RAM region ($4000-$5FFF) is normally occupied by the
; extension ROM, any read from there must be bracketed by ROMOFF/ROMON.
; On entry: HL = address in low RAM to read.
; On exit:  A  = byte read from (HL). BC, DE, HL preserved.
;
LAHL:
    PUSH  BC                        ;[4017] Preserve BC
    PUSH  DE                        ;[4018] Preserve DE
    LD    BC,$FF7F                  ;[4019] Address bank-select port
    LD    DE,$1000                  ;[401C] D=$10 (ROM-off), E=$00 (ROM-on)
    OUT   (C),D                     ;[401F] Write $10 to port $FF7F: disable ROM
    LD    A,(HL)                    ;[4021] Read byte from low RAM
    OUT   (C),E                     ;[4022] Write $00 to port $FF7F: re-enable ROM
    POP   DE                        ;[4024] Restore DE
    POP   BC                        ;[4025] Restore BC
    RET                             ;[4026]
;
; ELDIR: execute LDIR with HL (source) pointing into low RAM.
; Disables the ROM, performs the block copy, then re-enables the ROM.
; Caller sets up HL (source in low RAM), DE (destination), BC (count)
; in the normal Z80 LDIR convention before calling here.
;
ELDIR:
    PUSH  BC                        ;[4027] Preserve BC before bank switch
    LD    BC,$FF7F                  ;[4028] Address bank-select port
    LD    A,$10                     ;[402B] ROM-off value
    OUT   (C),A                     ;[402D] Disable ROM: low RAM now visible at $4000
    POP   BC                        ;[402F] Restore BC (block count for LDIR)
    LDIR                            ;[4030] Block copy: (HL)->(DE), BC bytes
    LD    BC,$FF7F                  ;[4032] Address bank-select port again
    XOR   A                         ;[4035] ROM-on value ($00)
    OUT   (C),A                     ;[4036] Re-enable ROM
    RET                             ;[4038]
;
; RNUM: read a numeric variable from the software store (pad) into the BASIC
; variable area.  The store uses a compact encoding; this routine decodes it
; and writes a 5-byte floating-point value via INTFP.
;
; On entry (all pointers in low RAM, so ROM must be switched out as needed):
;   IX = write pointer into BASIC variable area
;   HL = read pointer into the store (page-chained linked list)
;   BC = end-of-store sentinel (HL == BC means EOF)
;
; The control byte encoding is:
;   Bit 7 = 1 : string type -> type mismatch error
;   Bit 6 = 1 : full 5-byte floating-point follows (PRDN5)
;   Bit 5 = 1 : two-byte integer (high byte follows, then low byte)
;   Bit 4 = 1 : one-byte integer with high nibble in low 4 bits of ctrl byte
;   All zero  : single low byte only (D=0 implied)
;
RNUM:
    CALL  ROMOFF                    ;[4039] Disable ROM: low RAM (store) now accessible
    PUSH  DE                        ;[403C] Preserve DE
    CALL  PRDBYT                    ;[403D] Read control byte from store -> A
    BIT   7,A                       ;[4040] Test bit 7: string type?
    JP    NZ,PRDTM                  ;[4042] Yes: type mismatch error
    BIT   6,A                       ;[4045] Test bit 6: full floating-point?
    JR    NZ,PRDN5                  ;[4047] Yes: read 5 raw bytes directly
    BIT   5,A                       ;[4049] Test bit 5: two-byte integer?
    JR    NZ,PRDN1                  ;[404B] Yes: read high byte then low byte
    LD    D,0                       ;[404D] Assume D=0 (single-byte value)
    BIT   4,A                       ;[404F] Test bit 4: high nibble in control byte?
    JR    Z,PRDN3                   ;[4051] No: A is the low byte directly
    AND   $0F                       ;[4053] Mask: low 4 bits of ctrl = high nibble of value
    JR    PRDN2                     ;[4055] Fall into PRDN2 to read the low byte
PRDN1:
    CALL  PRDBYT                    ;[4057] Read high byte of integer -> A
PRDN2:
    LD    D,A                       ;[405A] D = high byte
    CALL  PRDBYT                    ;[405B] Read low byte of integer -> A
PRDN3:  
    LD    E,A                       ;[405E] E = low byte; DE = integer value
    PUSH  BC                        ;[405F] Preserve store end-sentinel
    PUSH  HL                        ;[4060] Preserve store read pointer
    EX    DE,HL                     ;[4061] HL = integer value (for INTFP)
    CALL  ROMON                     ;[4062] Re-enable ROM (INTFP is in 48k ROM)
    CALL  INTFP                     ;[4065] Convert integer in HL to 5-byte float in WRA1
    LD    B,5                       ;[4068] Copy 5 bytes
    LD    HL,SYSVAR_WRA1            ;[406A] HL -> floating-point result
PRDN4:
    LD    A,(HL)                    ;[406D] Read one byte of floating-point value
    INC   HL                        ;[406E] Advance source
    LD    (IX+0),A                  ;[406F] Write to BASIC variable area via IX
    INC   IX                        ;[4072] Advance write pointer
    DJNZ  PRDN4                     ;[4074] Loop for all 5 bytes
    POP   HL                        ;[4076] Restore store read pointer
    POP   BC                        ;[4077] Restore end-sentinel
    POP   DE                        ;[4078] Restore DE
    RET                             ;[4079]
PRDN5:
    LD    E,$05                     ;[407A] 5 bytes to read (full floating-point)
PRDN6:
    CALL  PRDBYT                    ;[407C] Read one byte from store -> A
    LD    (IX+0),A                  ;[407F] Write directly to BASIC variable area
    INC   IX                        ;[4082] Advance write pointer
    DEC   E                         ;[4084] Decrement byte counter
    JR    NZ,PRDN6                  ;[4085] Loop until all 5 bytes copied
PRDN7:
    POP   DE                        ;[4087] Restore DE
    JP    ROMON                     ;[4088] Re-enable ROM and return
;
; RSTR: read a string variable from the software store into the BASIC variable
; area.  The store byte preceding the string data is a control byte: bit 7
; must be set (string type); the lower 7 bits give the stored string length.
; The string is truncated to the maximum size allowed for this variable (from
; the byte at IX-1, set by the caller).  Terminates the string with SZ ($0D).
;
; On entry: IX = write pointer into BASIC variable area
;           (IX-1) = maximum number of characters for this string variable
;           HL, BC as per RNUM (store read pointer and end-sentinel)
;
RSTR:
    CALL  ROMOFF                    ;[408B] Disable ROM: store in low RAM now accessible
    PUSH  DE                        ;[408E] Preserve DE
    LD    E,(IX-1)                  ;[408F] E = max allowed string length for this variable
    CALL  PRDBYT                    ;[4092] Read control byte from store -> A
    BIT   7,A                       ;[4095] Test bit 7: must be string type
    JP    Z,PRDTM                   ;[4097] Not set: type mismatch error
    RES   7,A                       ;[409A] Clear bit 7: remaining 7 bits = stored length
    LD    D,A                       ;[409C] D = number of characters stored in file
    INC   D                         ;[409D] Pre-increment so first DEC in loop gives true count
PRDS1:
    DEC   D                         ;[409E] Decrement remaining character count
    JR    Z,PRDS2                   ;[409F] Zero: all characters processed, write terminator
    CALL  PRDBYT                    ;[40A1] Read next character from store -> A
    INC   E                         ;[40A4] Test E (max space remaining): increment...
    DEC   E                         ;[40A5] ...then decrement to test without changing E
    JR    Z,PRDS1                   ;[40A6] E was zero: no room left, discard this character
    LD    (IX+0),A                  ;[40A8] Store character into BASIC variable area
    INC   IX                        ;[40AB] Advance write pointer
    DEC   E                         ;[40AD] Decrement remaining space count
    JR    PRDS1                     ;[40AE] Loop for next character
PRDS2:
    LD    (IX+0),SZ                 ;[40B0] Write SZ ($0D) string terminator
    POP   DE                        ;[40B4] Restore DE
    JP    ROMON                     ;[40B5] Re-enable ROM and return
;
; PRDBYT: read the next byte from the page-chained store in low RAM.
; The store is organized as a linked list of 256-byte pages.  Byte 0 of
; each page holds the page number (high byte) of the next page in the chain.
; HL is the current read pointer; BC is the end-of-data sentinel address.
; Interrupts must be disabled by the caller (ROM is switched out).
;
; On exit: A = byte read, HL advanced to next byte.
;
PRDBYT:
    LD    A,H                       ;[40B8] Compare current page (H) to sentinel page (B)
    CP    B                         ;[40B9]
    JR    NZ,PRDB2                  ;[40BA] Different pages: not at end, read normally
    LD    A,L                       ;[40BC] Same page: compare offset (L) to sentinel offset (C)
    CP    C                         ;[40BD]
    JP    Z,PRDEOF                  ;[40BE] HL == BC: end of data
PRDB2:
    INC   L                         ;[40C1] Advance to next byte within page
    JR    NZ,PRDB3                  ;[40C2] No page wrap: read directly
    LD    H,(HL)                    ;[40C4] L wrapped to 0: byte 0 of page = next page number
    INC   L                         ;[40C5] Advance past the page-link byte to byte 1
PRDB3: 
    LD    A,(HL)                    ;[40C6] Read byte from store
    RET                             ;[40C7]
;
; PRDTM: type mismatch error (called when string/numeric type conflict detected).
; Re-enables ROM before calling the error routine (which is in the 48k ROM).
;
PRDTM:
    CALL  ROMON                     ;[40C8] Re-enable ROM before error handling
    CALL  ERR_TYPE_MISMATCH         ;[40CB] Raise "Type Mismatch" error (no return)
;
; PRDEOF: end-of-data error (called when store is exhausted unexpectedly).
; Re-enables ROM before calling the error routine.
;
PRDEOF:
    CALL  ROMON                     ;[40CE] Re-enable ROM before error handling
    CALL  ERR_OUT_OF_DATA           ;[40D1] Raise "Out Of Data" error (no return)
;
; EGETB: fetch the next byte from the software store for saving to tape.
; This routine runs in a tight tape-write loop, so it uses the alternate
; register set (EXX) to minimise the context-switch overhead.
;
; Register usage (alternate set, accessed via EXX):
;   BC' = port $FF7F value for bank control (C = $7F)
;   D'  = ROM-off value ($10), E' = ROM-on value ($00)
;   HL' = current store read pointer (page-chained)
;
; The routine switches RAM in (via D'), reads the next byte, and switches
; ROM back (via E') — all without disturbing the main register set.
;
EGETB:
    EXX                             ;[40D4] Switch to alternate registers
    OUT   (C),D                     ;[40D5] Write D' ($10) to port $FF7F: ROM off, RAM visible
    INC   L                         ;[40D7] Advance store pointer (low byte of address)
    JR    NZ,GTBYT1                 ;[40D8] No page wrap: go read byte
    LD    H,(HL)                    ;[40DA] L wrapped to 0: follow page-link (byte 0 = next page)
    INC   L                         ;[40DB] Advance past the page-link byte to byte 1
GTBYT1:
    LD    A,(HL)                    ;[40DC] Read byte from store -> A (main A, not alt)
    OUT   (C),E                     ;[40DD] Write E' ($00) to port $FF7F: ROM re-enabled
    EXX                             ;[40DF] Restore main registers
    RET                             ;[40E0]
;
; LWLEN: length of the Low-RAM section (ROMOFF through EGETB) to be copied.
; The PHASE $4000 directive offsets all addresses by $4000, so the assembler's
; location counter is $4000 higher than the true ROM offset; deducting $4000
; corrects this to give the real byte count.
;
LWLEN	equ $-LWRAM-$4000
;
; Padding to align EXINIT to $4100.
;
DEFS 31,0
;
; EXINIT: 96k ROM extra initialisation, called from $4001 on first boot.
; This is the main setup routine that extends the 48k ROM environment for
; the 96k Lynx.  It performs three LDIR block copies, patches several 48k
; system variable hooks to point at 96k replacements, and then initialises
; the parallel printer port and the software store (pad).
;
; The 48k ROM calls EXINIT via CALL EXT_ROM ($4000), returning here after
; the NOP at $4000 absorbs the return address harmlessly.
;
EXINIT:
    LD    HL,LWRAM                  ;[4100] HL = source: low-RAM routines in ROM
    LD    D,H                       ;[4103] DE = destination: same address in RAM
    LD    E,L                       ;[4104] (ROM and RAM share the same address space;
    LD    BC,LWLEN                  ;[4105]  writing to DE while ROM is mapped copies into
    LDIR                            ;[4108]  the underlying RAM for when ROM is switched off)
    LD    HL,UPROM                  ;[410A] HL = source: initial upper-RAM values (UPROM table)
    LD    DE,UPRAM                  ;[410D] DE = destination: 96k upper-RAM variable area
    LD    BC,UPLEN                  ;[4110] BC = length of UPROM table
    LDIR                            ;[4113] Copy initial RAM values into upper RAM
    LD    HL,JUMPS                  ;[4115] HL = source: hook jump table (JUMPS)
    LD    DE,SYSVAR_FLIGHT          ;[4118] DE = destination: SYSVAR_FLIGHT (lightpen hook, start of jump table)
    LD    BC,$15                    ;[411B] BC = 21 bytes (7 x 3-byte JP instructions)
    LDIR                            ;[411E] Install lightpen, joystick, user and error hooks into RAM
;
; Patch 48k system variable hooks to point at 96k replacements.
; SYSVAR_EEXT+2 holds the high byte of the EXT execution address.  On a
; 48k machine (or after first-time 96k init) this will be >= $40 (pointing
; into the 96k ROM).  If it is still < $40, EXINIT has not been run before,
; so the EXT RAM table (EXTRAM) must be cleared and the hooks patched.
;
    LD    A,(SYSVAR_EEXT+2)         ;[4120] Read high byte of current EXT exec address
    CP    $40                       ;[4123] Is it already in the 96k ROM range ($4000+)?
    JR    NC,CHG2                   ;[4125] Yes: already initialised, skip to CHG2
    LD    HL,EXTRAM                 ;[4127] No: point at EXT RAM descriptor table
    LD    B,8                       ;[412A] 8 bytes to clear (4 x 2-byte slot entries)
CHG1:
    LD    (HL),0                    ;[412C] Zero one byte of EXTRAM table
    INC   HL                        ;[412E] Advance pointer
    DJNZ  CHG1                      ;[412F] Loop until all 8 bytes cleared
;
; Install 96k-specific hook addresses into the 48k system variable area.
;
    LD    HL,IEXTS                  ;[4131] HL = address of 96k EXT tokeniser
    LD    (SYSVAR_IEXT+1),HL        ;[4134] Patch SYSVAR_IEXT jump to point at IEXTS
    LD    HL,EEXTS                  ;[4137] HL = address of 96k EXT executor
    LD    (SYSVAR_EEXT+1),HL        ;[413A] Patch SYSVAR_EEXT jump to point at EEXTS
    LD    HL,DBL96K                 ;[413D] HL = address of 96k BASIC line display routine
    LD    (SYSVAR_DBASLN+1),HL      ;[4140] Patch SYSVAR_DBASLN to use DBL96K (fixes EXT/REM display)
CHG2:
    LD    HL,EXTTAB                 ;[4143] HL = address of 96k EXT command tables (EXTTAB)
    LD    (EXTRAM+2),HL             ;[4146] Store in EXTRAM slot 2 (internal ROM EXT table slot)
    LD    A,EXT                     ;[4149] A = EXT token value
    LD    (SYSVAR_KTBL+4),A         ;[414B] Assign EXT token to ESC+E shorthand key
    LD    A,FN1                     ;[414E] A = FN1 opcode (JP instruction byte $C3)
    LD    HL,EXSR                   ;[4150] HL = address of 96k per-line execution hook (EXSR)
    LD    (SYSVAR_EXECSUB),A        ;[4153] Write JP opcode into SYSVAR_EXECSUB
    LD    (SYSVAR_EXECSUB+1),HL     ;[4156] Write EXSR address as the jump target
 ;
    CALL  EPPR                      ;[4159] Initialise parallel printer port
    CALL  PAD                       ;[415C] Initialise software store / pad (in low RAM)
    RET                             ;[415F] Return to 48k ROM boot sequence

;
; UPROM: initial values for the 96k upper-RAM variable area.
; Copied to UPRAM by EXINIT.  The length UPLEN is calculated from the
; difference between the end of this table and its start (less $4000 for
; the PHASE offset).  These values seed the store management variables:
; next free page, current file number, 3 file slots, error variable, EXEC
; stack pointer, and the lightpen offset calibration constant.
;
UPROM:	
    DB    2                         ;[4160] NXFRPG: next free store page (page 2 = first usable)
	DB    0                         ;[4161] KFILE: current file number (0 = none open)
	DB    0,PZ,0,PZ,0,PZ,0,0        ;[4162] File slot data: 3 slots, each as (page, PZ-sentinel); plus 2 spare bytes
	DW    0                         ;[416A] ERRVR: error-trap variable pointer (0 = no trap)
	DW    0                         ;[416C] EXECSP: EXEC stack pointer (0 = not active)
	DB    $88                       ;[416E] Lightpen calibration offset ($88 = 136 scan lines)
UPLEN	equ ASMPC-UPROM-$4000
;
; JUMPS: hook vectors copied into the 48k system variable area by EXINIT
; (destination: SYSVAR_FLIGHT, 7 entries x 3 bytes = 21 bytes).
; These JP instructions replace the 48k ROM's default "not yet implemented"
; stubs with working 96k implementations for lightpen, joystick, and error
; handling.  The user-function slots (User0-User3) remain as ERR_NOT_YET_IMP.
;
JUMPS:
    JP    FPEN                      ;[416F] SYSVAR_FLIGHT: lightpen function -> FPEN
    JP    FJOY                      ;[4171] SYSVAR_FJOY:   joystick function -> FJOY
    JP    ERR_NOT_YET_IMP           ;[4175] SYSVAR_FUSER0: User0 (not implemented)
    JP    ERR_NOT_YET_IMP           ;[4178] SYSVAR_FUSER1: User1 (not implemented)
    JP    ERR_NOT_YET_IMP           ;[417B] SYSVAR_FUSER2: User2 (not implemented)
    JP    ERR_NOT_YET_IMP           ;[417E] SYSVAR_FUSER3: User3 (not implemented)
    JP    ERRORHANDLER              ;[4181] SYSVAR_ERRAM:  error hook -> ERRORHANDLER (96k TRAP support)
;
; EXTTAB: descriptor block for the 96k internal-ROM EXT command set.
; This 3-word table is stored into EXTRAM slot 2 by EXINIT.
; The EXT dispatcher (IEXTS/EEXTS) uses it to locate the ASCII name
; table, input-validation dispatch table, and execution dispatch table
; for the 96k EXT commands (EXPLODE, KLAXON, STORE, CIRCLE etc.).
;
EXTTAB:
EXT_ASCII: DW XT96KS                ;[4184] Pointer to ASCII keyword table for 96k EXT commands
EXT_INPUT: DW XI96KS                ;[4186] Pointer to input-validation dispatch table
EXT_EXEC:  DW XE96KS                ;[4188] Pointer to execution dispatch table
;
; EXTK: search an EXT keyword table for the word at DE (input pointer).
; Used during tokenisation to identify which EXT command the user typed.
;
; On entry: HL = pointer to keyword table (first byte = word count)
;           DE = pointer to current input text
;
; On exit:  A  = zero-based position of matched word in table (if match)
;           C flag clear = match found
;           C flag set   = no match (ERR_SYNTAX expected to follow)
;           BC changed; DE advanced past the matched word (or unchanged if no match)
;
; The table format is: [count] [<$80+first-char> <rest...>] ... 
; The high bit of the first character of each word is set as a word-start marker.
; Abbreviation with '.' is supported (e.g. "EXP." matches "EXPLODE").
;
EXTK:
    PUSH  HL                        ;[418A] Save table base address
    LD    B,(HL)                    ;[418B] B = number of words in table
    INC   B                         ;[418C] Pre-increment so DJNZ starts at full count
    PUSH  DE                        ;[418D] Save original input pointer for restart
EXTK1:                              ; Start new word comparison
    POP   DE                        ;[418E] Restore input pointer to start of word
    DJNZ  EXTK2                     ;[418F] Decrement count and jump; if zero, all words exhausted
    POP   HL                        ;[4191] Restore table pointer (failed to match)
    SCF                             ;[4192] Set carry = no match
    RET                             ;[4193]
EXTK2:
    INC   HL                        ;[4194] Advance table pointer
    LD    A,(HL)                    ;[4195] Read next table byte
    SUB   $80                       ;[4196] Test for word-start marker (bit 7 set)
    JR    C,EXTK2                   ;[4198] Not a word-start: skip (still within previous word)
    LD    C,A                       ;[419A] C = first character of this word (marker stripped)
    PUSH  DE                        ;[419B] Save input pointer for this attempt
    JR    EXTK5                     ;[419C] Jump to compare first character
EXTK4:                              ; Advance to next character in table word
    INC   HL                        ;[419E] Move to next table byte
    LD    C,(HL)                    ;[419F] C = next table character
    BIT   7,C                       ;[41A0] Is bit 7 set? (start of next word = end of this one)
    JR    NZ,EXTK8                  ;[41A2] Yes: end of word, match found
EXTK5:                              ; Compare input character against table character
    RST   $10                       ;[41A4] Read next input character into A (skipping spaces)
    INC   DE                        ;[41A5] Advance input pointer
    CP    'a'                       ;[41A6] Is it a lower-case letter?
    JR    C,EXTK6                   ;[41A8] No (below 'a'): skip case conversion
    CP    'z'+1                     ;[41AA] Is it above 'z'?
    JR    NC,EXTK6                  ;[41AC] Yes: not lower-case, skip conversion
    SUB   $20                       ;[41AE] Convert lower-case to upper-case
EXTK6:
    CP    C                         ;[41B0] Does input character match table character?
    JR    Z,EXTK4                   ;[41B1] Yes: advance to next character pair
EXTK7:                              ; Mismatch: check for '.' abbreviation
    CP    '.'                       ;[41B3] Is the input character a '.' (abbreviation marker)?
    JR    NZ,EXTK1                  ;[41B5] No: genuine mismatch, try next word
    BIT   7,(HL)                    ;[41B7] Is HL at the last char of the table word (bit 7 = next word)?
    JR    NZ,EXTK1                  ;[41B9] No: abbreviation too short (matched < 2 chars), reject
EXTK8:                              ; Match found
    POP   HL                        ;[41BB] Discard saved input pointer (DE already advanced)
    POP   HL                        ;[41BC] Restore table base address
    LD    A,(HL)                    ;[41BD] A = total word count
    SUB   B                         ;[41BE] Subtract remaining count -> A = zero-based position
    OR    A                         ;[41BF] Clear carry flag (match found)
    RET                             ;[41C0]
;
; HL2A: index into a word-addressed table.
; Given a table base address in HL and a zero-based index in A, returns the
; 16-bit value at table[A] in HL (each entry is 2 bytes, little-endian).
;
; On entry: HL = base of table, A = index (0-based)
; On exit:  HL = 16-bit value at table[A]; DE preserved.
;
HL2A:
    PUSH  DE                        ;[41C1] Preserve DE
    RLCA                            ;[41C2] A = A * 2 (each entry is 2 bytes)
    LD    E,A                       ;[41C3] DE = byte offset into table
    LD    D,0                       ;[41C4]
    ADD   HL,DE                     ;[41C6] HL -> entry at table[A]
    LD    A,(HL)                    ;[41C7] Read low byte of address
    INC   HL                        ;[41C8]
    LD    H,(HL)                    ;[41C9] Read high byte of address
    LD    L,A                       ;[41CA] Assemble: HL = 16-bit table entry
    POP   DE                        ;[41CB] Restore DE
    RET                             ;[41CC]
;
; IEXTS: EXT command tokeniser (input/syntax phase).
; Called via the SYSVAR_IEXT hook when the tokeniser encounters the EXT token.
; Searches all registered EXT command sets (up to 4 slots in EXTRAM) for a
; match with the current input word, encodes the result as a token byte, and
; dispatches to the corresponding input-validation routine.
;
; The EXTRAM table contains up to 4 slots, each a 2-byte pointer to a 3-word
; descriptor (ASCII table, input dispatch, exec dispatch).  Slot 2 is used by
; the internal 96k ROM (EXTTAB); the other slots are available for external
; ROM expansions.
;
; The token byte is constructed as: (type << 6) | position
;   type     = which slot matched (0-3), shifted left to bits 7-6
;   position = zero-based index within that slot's command list (bits 5-0)
;
; On entry: HL = current Polish buffer write pointer
;           DE = current input pointer
;           A  = current input character
;
IEXTS:
    PUSH  HL                        ;[41CD] Save Polish buffer pointer
    LD    HL,EXTRAM-1               ;[41CE] HL -> one byte before EXTRAM (pre-decrement for loop)
    LD    B,4                       ;[41D1] B = 4 EXT slots to search
IEXTS1:
    PUSH  BC                        ;[41D3] Save slot counter
    INC   HL                        ;[41D4] Advance to low byte of slot pointer
    LD    C,(HL)                    ;[41D5] C = low byte of slot descriptor address
    INC   HL                        ;[41D6] Advance to high byte
    LD    B,(HL)                    ;[41D7] B = high byte of slot descriptor address
    LD    A,C                       ;[41D8] Test whether slot pointer is non-zero
    OR    B                         ;[41D9]
    JR    Z,IEXTS2                  ;[41DA] Slot is empty (null pointer): skip to next slot
    PUSH  BC                        ;[41DC] BC = descriptor address
    POP   IX                        ;[41DD] IX -> 3-word descriptor table for this slot
    PUSH  HL                        ;[41DF] Save EXTRAM scan pointer
    LD    L,(IX+0)                  ;[41E0] Load low byte of ASCII table address
    LD    H,(IX+1)                  ;[41E3] Load high byte -> HL = ASCII keyword table
    CALL  EXTK                      ;[41E6] Search table for match; A = position, C clear if found
    POP   HL                        ;[41E9] Restore EXTRAM scan pointer
    JR    NC,IEXTS3                 ;[41EA] Carry clear = match found, go encode token
IEXTS2:
    POP   BC                        ;[41EC] Restore slot counter
    DJNZ  IEXTS1                    ;[41ED] Try next slot
    CALL  ERR_SYNTAX                ;[41EF] No match in any slot: syntax error
IEXTS3:
    POP   BC                        ;[41F2] B = remaining slot count (used to derive type)
    LD    C,A                       ;[41F3] C = position within matched slot's command list
    LD    A,$04                     ;[41F4] A = 4
    SUB   B                         ;[41F6] A = 4 - remaining = slot type index (0 for slot 0 ... 3 for slot 3)
    RRCA                            ;[41F7] Rotate right twice to shift type into bits 7-6
    RRCA                            ;[41F8] (equivalent to type * $40)
    ADD   C                         ;[41F9] Combine: token = (type << 6) | position
    POP   HL                        ;[41FA] Restore Polish buffer pointer
    LD    (HL),A                    ;[41FB] Write encoded EXT token into Polish buffer
    INC   HL                        ;[41FC] Advance Polish buffer pointer
    LD    A,C                       ;[41FD] A = position (for dispatch table lookup)
    PUSH  HL                        ;[41FE] Save updated Polish pointer (as return address via EX (SP),HL)
    LD    L,(IX+2)                  ;[41FF] Load low byte of input-dispatch table address
    LD    H,(IX+3)                  ;[4202] Load high byte -> HL = input dispatch table
    CALL  HL2A                      ;[4205] Index into table: HL = address of validation routine
    EX    (SP),HL                   ;[4208] Swap: stack gets validation addr, HL gets Polish pointer
    JP    SPACE                     ;[4209] Skip spaces in input, then return (dispatching to validation routine)
;
; DBL96K: display a BASIC line (96k version of PRINT_BAS_LINE).
; This replaces the 48k ROM's DBASLN routine (patched in via SYSVAR_DBASLN
; by EXINIT).  It adds two capabilities the 48k routine lacks:
;   1. EXT command display: decodes the EXT token byte and looks up the
;      ASCII keyword from the appropriate EXT command table.
;   2. REM fix: the 48k routine had a bug where REM argument text was
;      processed through the keyword expander; this version jumps directly
;      to KOPY to copy the raw ASCII bytes, bypassing that path.
;
; On entry: IX = pointer to the current BASIC line (standard convention).
; The routine prints line number, any indentation, then walks the tokenised
; line byte by byte, expanding tokens back to ASCII as it goes.
;
DBL96K:
    PUSH  IX                        ;[420C] Save IX (line pointer used throughout)
    POP   HL                        ;[420E] HL = IX (line pointer)
    PUSH  HL                        ;[420F] Re-save for DO_INDENT restoration at end
    CALL  LNUM1                     ;[4210] Print line number from (IX)
    CALL  PN                        ;[4213] Print a space after line number
    CALL  TEST_IS_LOOP_END          ;[4216] Check if line ends a loop (FOR/REPEAT/WHILE etc.)
    CALL  SUB_INDENT                ;[4219] Apply current indentation level
    CALL  SKIP_LNUM                 ;[421C] Advance DE past the line-number bytes to first token
NDBL1:
    LD    A,(DE)                    ;[421F] Read current token byte
    PUSH  AF                        ;[4220] Save token for post-print checks
    CALL  SUB_PRINT_KEYWORD         ;[4221] Print keyword text for this token; advance DE
    POP   AF                        ;[4224] Restore token value
    ; ---- 96k insert: handle REM and EXT specially ----
    CP    REM                       ;[4225] Was token REM?
    JR    Z,KOPY                    ;[4227] Yes: copy rest of line as raw ASCII (REM fix)
    CP    EXT                       ;[4229] Was token EXT?
    JR    NZ,NDBL6                  ;[422B] No: handle as normal 48k token
    ; EXT token found: the next byte encodes both the slot type (bits 7-6)
    ; and command position (bits 5-0).  Look up the ASCII keyword from the
    ; appropriate EXT command table and print it.
    LD    A,(DE)                    ;[422D] Read EXT sub-token byte (type + position)
    AND   %11000000                 ;[422E] Mask to keep only slot-type bits (7-6)
    RLCA                            ;[4230] Rotate bits 7-6 down to bits 1-0
    RLCA                            ;[4231] A = slot type index (0-3)
    LD    HL,EXTRAM                 ;[4232] HL -> EXTRAM descriptor table
    CALL  HL2A                      ;[4235] HL -> 3-word descriptor for this slot
    LD    A,(HL)                    ;[4238] Read low byte of ASCII table address
    INC   HL                        ;[4239]
    LD    H,(HL)                    ;[423A] Read high byte of ASCII table address
    LD    L,A                       ;[423B] HL -> ASCII keyword table for this EXT slot
    LD    A,(DE)                    ;[423C] Re-read EXT sub-token byte
    AND   %00111111                 ;[423D] Mask to command position (bits 5-0)
    CALL  SUB_PRINT_KEYWORD+6       ;[423F] Print keyword at that position in the ASCII table
    JR    NDBL15                    ;[4242] Rejoin main scan loop (back up DE before INC)
    ; ---- end 96k insert ----
NDBL6:
    CP    ELSE                      ;[4244] Is token ELSE?
    JR    Z,NDBL1                   ;[4246] Yes: print ELSE and loop for next token
    CP    CODE                      ;[4248] Is token CODE? (inline machine code follows)
    JP    Z,PRINT_BAS_LINE          ;[424A] Yes: hand off to 48k routine to display CODE data
NDBL15:
    DEC   DE                        ;[424D] Step back one (NDBL will INC before reading)
NDBL:
    INC   DE                        ;[424E] Advance DE to next byte
NDBL11:
    LD    A,(DE)                    ;[424F] Read next byte of line
    CP    EOS                       ;[4250] End of string sub-expression ($7B)?
    RET   Z                         ;[4252] Yes: line display complete, return
    CP    CR                        ;[4253] Carriage return? (end of statement)
    JR    Z,NDBL4                   ;[4255] Yes: handle indentation and newline
    CP    SOP                       ;[4257] Start-of-Polish marker ($7D)?
    JR    Z,NDBL2                   ;[4259] Yes: print Polish expression
    CP    $80                       ;[425B] Is it a token (>= $80)?
    JR    NC,NDBL3                  ;[425D] Yes: print as keyword (with spacing)
    RST   8                         ;[425F] No: print raw ASCII character
    CP    $22                       ;[4260] Was it a '"' (start of string literal)?
    JR    NZ,NDBL                   ;[4262] No: continue scanning
    CALL  PRINT_STRING              ;[4264] Yes: print the quoted string contents
    RST   8                         ;[4267] Print closing '"'
    JR    NDBL                      ;[4268] Continue
NDBL2:
    INC   DE                        ;[426A] Advance past SOP byte
    CALL  SYSVAR_PP                 ;[426B] Print Polish expression in infix form
    JR    NDBL                      ;[426E] Continue scanning
NDBL3:
    CP    CHR                       ;[4270] Is token CHR (below threshold requiring spaces)?
    PUSH  AF                        ;[4272] Save token and flags (C set if token < CHR)
    CALL  C,DISPLAY_SPACE           ;[4273] If C set (low-range token): print leading space
    CALL  PNE1                      ;[4276] Print keyword name for token at (DE)
    POP   AF                        ;[4279] Restore token
    PUSH  AF                        ;[427A] Re-save
    CALL  C,DISPLAY_SPACE           ;[427B] If C set (low-range token): print trailing space
    POP   AF                        ;[427E] Restore token
    INC   DE                        ;[427F] Advance DE past token byte
    CP    THEN                      ;[4280] Was token THEN?
    JR    Z,NDBL1                   ;[4282] Yes: loop to print keyword on next token
    JR    NDBL11                    ;[4284] No: continue scanning without re-reading
NDBL4:
    POP   IX                        ;[4286] Restore original IX (line pointer)
    JP    DO_INDENT+2               ;[4288] Apply end-of-statement indentation and newline
;
; KOPY1/KOPY: copy raw ASCII bytes from the token stream to the display.
; Used for REM argument text, where the content after the REM token is stored
; as literal ASCII characters terminated by CR.  No token expansion is done.
;
KOPY1:
    INC   DE                        ;[428B] Advance past current byte (entry from mid-stream)
KOPY:
    LD    A,(DE)                    ;[428C] Read next byte
    CP    $0D                       ;[428D] Is it CR? (end of REM text)
    JP    Z,DO_INDENT               ;[428F] Yes: apply indentation/newline and return
    RST   8                         ;[4292] No: print the character
    JR    KOPY1                     ;[4293] Loop for next character
;
; EEXTS: EXT command executor (execution phase).
; Called via the SYSVAR_EEXT hook when the interpreter is about to execute
; a tokenised EXT command.  Decodes the EXT token byte to find the slot and
; command position, looks up the execution routine address from the appropriate
; dispatch table, and jumps to it.
;
; On entry: IX = current IX (saved and restored around dispatch)
;           DE = pointer to EXT sub-token byte in the Polish stream
;           A  = EXT sub-token byte (slot type in bits 7-6, position in bits 5-0)
;
EEXTS:
    PUSH  IX                        ;[4295] Save IX (caller's frame pointer)
    AND   %11000000                 ;[4297] Mask: keep only slot-type bits (7-6)
    RLCA                            ;[4299] Rotate bits 7-6 down to bits 1-0
    RLCA                            ;[429A] A = slot type index (0-3)
    LD    HL,EXTRAM                 ;[429B] HL -> EXTRAM descriptor table base
    CALL  HL2A                      ;[429E] HL -> 3-word descriptor for this slot
    LD    A,H                       ;[42A1] Test whether descriptor pointer is non-null
    OR    L                         ;[42A2]
    CALL  Z,ERR_NOT_YET_IMP         ;[42A3] Null: slot not registered -> "not yet implemented"
    PUSH  HL                        ;[42A6] BC = descriptor address
    POP   IX                        ;[42A7] IX -> 3-word descriptor for this slot
    LD    L,(IX+4)                  ;[42A9] Load low byte of exec dispatch table address
    LD    H,(IX+5)                  ;[42AC] Load high byte -> HL = execution dispatch table
    LD    A,(DE)                    ;[42AF] Re-read EXT sub-token byte
    AND   %00111111                 ;[42B0] Mask to command position (bits 5-0)
    CALL  HL2A                      ;[42B2] Index into exec table: HL = execution routine address
    INC   DE                        ;[42B5] Advance DE past EXT sub-token byte
    LD    A,(DE)                    ;[42B6] Pre-fetch next byte of token stream for command handler
    POP   IX                        ;[42B7] Restore caller's IX
    JP    (HL)                      ;[42B9] Jump to EXT command execution routine
;
; XT96KS: ASCII keyword table for the 96k EXT commands.
; Format: [count] [<$80+first-char> <remaining-chars>] ...
; The count byte ($1B = 27) includes the 21 named commands plus 6 reserved
; placeholder entries (shown as @@@@@@).  The high bit of each word's first
; character acts as a word-start marker, enabling the EXTK scanner to find
; word boundaries without a separate length table.
; The trailing $80 byte acts as an end-of-table sentinel.
;
XT96KS:
    DB    $1B                       ;[42BA] Table entry count: 27 (21 commands + 6 reserved)
	DB    $80+'E',"XPLODE"             ;[42BB]  0: EXPLODE  - sound effect
	DB    $80+'K',"LAXON"              ;[42C2]  1: KLAXON   - sound effect
	DB    $80+'L',"ASER"               ;[42C7]  2: LASER    - sound effect
	DB    $80+'Z',"AP"                 ;[42CD]  3: ZAP      - sound effect
	DB    $80+'S',"TORE"               ;[42D0]  4: STORE    - save variable(s) to pad
	DB    $80+'I',"STORE"              ;[42D5]  5: ISTORE   - save integer variable(s) to pad
	DB    $80+'F',"ETCH"               ;[42DB]  6: FETCH    - load variable(s) from pad
	DB    $80+'W',"IPE"                ;[42E0]  7: WIPE     - delete file from pad
	DB    $80+'B',"ACK"                ;[42E4]  8: BACK     - rewind pad file pointer
	DB    $80+'S',"SAVE"               ;[42E8]  9: SSAVE    - save pad file to tape
	DB    $80+'S',"LOAD"               ;[42ED] 10: SLOAD    - load pad file from tape
	DB    $80+'C',"SAVE"               ;[42F2] 11: CSAVE    - save pad to tape (compact)
	DB    $80+'C',"HAIN"               ;[42F7] 12: CHAIN    - chain-load a BASIC program
	DB    $80+'T',"RAP"                ;[42FC] 13: TRAP     - set error-trap variable
	DB    $80+'N',"OTRAP"              ;[4300] 14: NOTRAP   - clear error trap
	DB    $80+'P',"PRINT"              ;[4306] 15: PPRINT   - output to parallel printer
	DB    $80+'S',"PRINT"              ;[430C] 16: SPRINT   - output to serial port
	DB    $80+'V',"RESET"              ;[4312] 17: VRESET   - reset video/display state
	DB    $80+'C',"IRCLE"              ;[4318] 18: CIRCLE   - draw circle
	DB    $80+'T',"RIANGLE"            ;[431E] 19: TRIANGLE - draw triangle
	DB    $80+'C',"LW"                 ;[4326] 20: CLW      - clear window
	DB    $80+'@',"@@@@@"              ;[4329] 21: (reserved)
	DB    $80+'@',"@@@@@"              ;[432F] 22: (reserved)
	DB    $80+'@',"@@@@@"              ;[4335] 23: (reserved)
	DB    $80+'@',"@@@@@"              ;[433B] 24: (reserved)
    DB    $80+'@',"@@@@@"           ;[4341] 25: (reserved)
	DB    $80+'@',"@@@@@"              ;[4347] 26: (reserved)
    DB    $80                       ;[434D] End-of-table sentinel
;
; XI96KS: input (tokeniser/syntax) dispatch table for the 96k EXT commands.
; Each entry is the address of the input-validation routine for the
; corresponding command.  IEND = no additional syntax (command takes no args);
; IINK, IPWR etc. = shared validation routines from the 48k ROM.
; Position in this table matches position in XT96KS (zero-based).
;
XI96KS:
    DW    IEND                      ;[434E]  0: EXPLODE  - no arguments
    DW    IEND                      ;[4350]  1: KLAXON   - no arguments
    DW    IEND                      ;[4352]  2: LASER    - no arguments
    DW    IEND                      ;[4354]  3: ZAP      - no arguments
    DW    IPWR                      ;[4356]  4: STORE    - validate STORE args
    DW    IIST                      ;[4358]  5: ISTORE   - validate ISTORE args
    DW    IPRD                      ;[435A]  6: FETCH    - validate FETCH args
    DW    IINK                      ;[435C]  7: WIPE     - validate file number (reuse IINK)
    DW    IINK                      ;[435E]  8: BACK     - validate file number (reuse IINK)
    DW    ISSV                      ;[4360]  9: SSAVE    - validate filename
    DW    ISSV                      ;[4362] 10: SLOAD    - validate filename
    DW    ISSV                      ;[4364] 11: CSAVE    - validate filename
    DW    IDPOKE                    ;[4366] 12: CHAIN    - validate filename (reuse IDPOKE)
    DW    ITRP                      ;[4368] 13: TRAP     - validate variable name
    DW    IEND                      ;[436A] 14: NOTRAP   - no arguments
    DW    IEND                      ;[436C] 15: PPRINT   - no arguments
    DW    IEND                      ;[436E] 16: SPRINT   - no arguments
    DW    IEND                      ;[4370] 17: VRESET   - no arguments
    DW    IE4CR                     ;[4372] 18: CIRCLE   - validate 4 args + CR
    DW    IE6CR                     ;[4374] 19: TRIANGLE - validate 6 args + CR
    DW    IEND                      ;[4376] 20: CLW      - no arguments
    DW    IREM                      ;[4378] 21: (reserved - treated as REM/comment)
    DW    IREM                      ;[437A] 22: (reserved)
    DW    IREM                      ;[437C] 23: (reserved)
    DW    IREM                      ;[437E] 24: (reserved)
    DW    IREM                      ;[4380] 25: (reserved)
    DW    IREM                      ;[4382] 26: (reserved)
;
; XE96KS: execution dispatch table for the 96k EXT commands.
; Each entry is the address of the execution routine for the corresponding
; command.  Position in this table matches position in XT96KS (zero-based).
; The 6 reserved slots map to ERR_NOT_YET_IMP so they raise an error if
; somehow invoked.
;
XE96KS:
    DW    EXPL                      ;[4384]  0: EXPLODE  - explosion sound effect
    DW    EKLX                      ;[4386]  1: KLAXON   - klaxon sound effect
    DW    ELSR                      ;[4388]  2: LASER    - laser sound effect
    DW    EZAP                      ;[438A]  3: ZAP      - zap sound effect
    DW    EPWR                      ;[438C]  4: STORE    - save variables to pad
    DW    EIST                      ;[438E]  5: ISTORE   - save integer variables to pad
    DW    EPRD                      ;[4390]  6: FETCH    - load variables from pad
    DW    EWIP                      ;[4392]  7: WIPE     - delete pad file
    DW    EBAK                      ;[4394]  8: BACK     - rewind pad file
    DW    ESSV                      ;[4396]  9: SSAVE    - save pad file to tape
    DW    ESLD                      ;[4398] 10: SLOAD    - load pad file from tape
    DW    ECSV                      ;[439A] 11: CSAVE    - compact save pad to tape
    DW    ECHN                      ;[439C] 12: CHAIN    - chain-load BASIC program
    DW    ETRP                      ;[439E] 13: TRAP     - set error trap variable
    DW    ENTR                      ;[43A0] 14: NOTRAP   - clear error trap
    DW    EPPR                      ;[43A2] 15: PPRINT   - enable parallel printer output
    DW    ESPR                      ;[43A4] 16: SPRINT   - enable serial port output
    DW    EVRS                      ;[43A6] 17: VRESET   - reset video state
    DW    ECIR                      ;[43A8] 18: CIRCLE   - draw circle
    DW    ETRI                      ;[43AA] 19: TRIANGLE - draw triangle
    DW    ECLW                      ;[43AC] 20: CLW      - clear window
    DW    ERR_NOT_YET_IMP           ;[43AE] 21: (reserved)
    DW    ERR_NOT_YET_IMP           ;[43B0] 22: (reserved)
    DW    ERR_NOT_YET_IMP           ;[43B2] 23: (reserved)
    DW    ERR_NOT_YET_IMP           ;[43B4] 24: (reserved)
    DW    ERR_NOT_YET_IMP           ;[43B6] 25: (reserved)
    DW    ERR_NOT_YET_IMP           ;[43B8] 26: (reserved)
;
;----------------------------------------------------------
; Software Store ("Pad") Management
; ------------------------------------
; The 96k Lynx provides a "pad" - a software filing system that uses the
; extra 48k of RAM ($4000-$BFFF, minus the ROM area) to store up to 48
; named files.  The store is organized as a linked list of 256-byte pages:
; byte 0 of each page holds the page number (high byte address) of the
; next page in the chain, or PZ ($FF) to mark the end of the chain.
; File metadata (first page, read/write pointers, length, next-in-chain)
; is kept in upper RAM (KNXFIL onwards) and mirrored to lower RAM in the
; FILINF table (at $200 - 48*8 = $1C0, i.e. just below the low-RAM area).
;
; PAD: initialise the software store on startup.
; Called by EXINIT after the UPROM values have been copied.
; First tests whether the machine actually has 96k of RAM; if not (48k
; Lynx), sets bit 7 of KFILE as a "store unavailable" flag and returns.
; If 96k is confirmed, builds the free-page chain and initialises the
; per-file metadata in low RAM.
;
PAD:
    ; --- 96k RAM test ---
    ; On a true 96k machine, $9FFF and $BFFF are different physical RAM
    ; cells.  On a 48k machine they alias to the same location.  The test
    ; writes a complemented value to $BFFF and then reads $9FFF; if the
    ; two locations are the same cell the read-back will show the write.
    LD    HL,$9FFF                  ;[43BA] HL -> test address in second 16k bank
    LD    DE,$BFFF                  ;[43BD] DE -> test address in third 16k bank
    LD    A,(DE)                    ;[43C0] Read current value at $BFFF
    CPL                             ;[43C1] Complement it
    LD    (DE),A                    ;[43C2] Write complement back to $BFFF
    LD    C,(HL)                    ;[43C3] Read $9FFF into C (saves original for comparison)
    CPL                             ;[43C4] Complement A again (restores original value)
    LD    (DE),A                    ;[43C5] Restore original value at $BFFF
    LD    A,(HL)                    ;[43C6] Read $9FFF again after write to $BFFF
    CP    C                         ;[43C7] Same as before the write? (aliased = 48k)
    JR    Z,PAD1                    ;[43C8] Different value seen at $9FFF -> true 96k, continue
    LD    A,$80                     ;[43CA] 48k machine: set "store unavailable" flag ($80)
    LD    (KFILE),A                 ;[43CC] Store flag in KFILE; bit 7 checked by GETINF
    RET                             ;[43CF] Return: pad not available on this machine
PAD1:
    ; --- Build free-page chain ---
    ; Pages $02-$5F are available for the store (pages $00 and $01 are
    ; system RAM; $40 is the 96k ROM, so it must be skipped).
    ; Each page's byte 0 is written with the number of the next page,
    ; forming a linked free list.  NXFRPG (set to 2 by UPROM) is the
    ; first free page.
    LD    A,(NXFRPG)                ;[43D0] A = first free page number (2 from UPROM)
    LD    H,A                       ;[43D3] H = page number -> HL = $0200 (byte 0 of page 2)
    LD    L,0                       ;[43D4] L = 0: byte 0 of the page (the page-link byte)
PAD2:
    INC   A                         ;[43D6] A = next page number
    LD    (HL),A                    ;[43D7] Write next-page link into byte 0 of current page
    INC   H                         ;[43D8] Advance H to next page (HL stays at byte 0)
    CP    $5F                       ;[43D9] Reached last page ($5F)?
    JR    NZ,PAD2                   ;[43DB] No: continue building chain
    LD    (HL),PZ                   ;[43DD] Yes: write PZ ($FF) end-of-chain sentinel at page $5F
    ; Skip ROM page $40: page $3F's link byte is overwritten to point to $41
    LD    H,$3F                     ;[43DF] HL -> byte 0 of page $3F
    LD    (HL),$41                  ;[43E1] Chain $3F -> $41 (skipping $40 which is the ROM)
    ; --- Initialise per-file metadata in low RAM ---
    ; Copy the 8-byte "blank file" template from upper RAM (KNXFIL) into
    ; the FILINF table in low RAM, once for each of the 48 file slots.
    LD    HL,KNXFIL                 ;[43E3] HL -> file info template in upper RAM
    LD    DE,FILINF                 ;[43E6] DE -> file info table in lower RAM
    LD    B,MXNFIL                  ;[43E9] B = 48 (MXNFIL): one iteration per file slot
PAD3:
    PUSH  BC                        ;[43EB] Save file-slot counter
    LD    BC,RANDOM                 ;[43EC] BC = 8 (RANDOM = bytes per file info entry)
    PUSH  HL                        ;[43EF] Save source pointer (KNXFIL)
    LDIR                            ;[43F0] Copy 8-byte template into this file's FILINF entry
    POP   HL                        ;[43F2] Restore source pointer (same template for each slot)
    POP   BC                        ;[43F3] Restore file-slot counter
    DJNZ  PAD3                      ;[43F4] Repeat for all 48 file slots
    RET                             ;[43F6]
;
; GETINF: read a file number from the BASIC token stream and load that
; file's 8-byte metadata record from low RAM into upper RAM (KNXFIL area).
; The file number in BASIC is 1-based (1..48); internally it is 0-based.
;
; On entry: DE = token stream pointer (pointing at the file-number expression)
; On exit:  DE advanced past the file-number argument; upper RAM populated
;           with the named file's metadata.  KFILE updated with file number.
;
; The metadata record (8 bytes per file, at FILINF + (file-1)*8 in low RAM):
;   KNXFIL  (1) - number of next file in a CSAVE chain (0 = none)
;   KFSTPG  (1) - first page of this file (PZ = $FF if file is empty)
;   KWRPTR  (2) - write pointer (page:offset)
;   KRDPTR  (2) - read pointer  (page:offset)
;   KFILEN  (2) - file length in bytes
;
GETINF:
    LD    HL,KFILE                  ;[43F7] HL -> KFILE (current file number + flags)
    BIT   7,(HL)                    ;[43FA] Test bit 7: store unavailable (48k machine)?
    CALL  NZ,ERR_NOT_YET_IMP        ;[43FC] Yes: "not yet implemented" error
    PUSH  HL                        ;[43FF] Save KFILE address
    RST   $18                       ;[4400] Evaluate expression -> HL (integer), A = low byte
    INC   DE                        ;[4401] Advance DE past the expression terminator
    DEC   H                         ;[4402] Test high byte: decrement...
    INC   H                         ;[4403] ...and restore (sets Z if H was 0, NZ if > 0)
    CALL  NZ,ERR_NUM_OUT_RANGE      ;[4404] High byte non-zero: file number > 255, error
    DEC   A                         ;[4407] Convert 1-based to 0-based (file 1 -> 0)
    CP    MXNFIL                    ;[4408] Compare with max (48): must be 0..47
    CALL  NC,ERR_NUM_OUT_RANGE      ;[440A] >= 48: out of range error
    INC   A                         ;[440D] Restore to 1-based for storage
    POP   HL                        ;[440E] Restore KFILE address
    BIT   6,(HL)                    ;[440F] Is bit 6 set? (cached: info already in upper RAM)
    JR    Z,GTINF0                  ;[4411] No cached info: go load from low RAM
    RES   6,(HL)                    ;[4413] Clear cache-valid flag
    CP    (HL)                      ;[4415] Is this the same file as already cached?
    RET   Z                         ;[4416] Yes: upper RAM already has correct info, done
GTINF0:
    LD    (HL),A                    ;[4417] Update KFILE with current file number
GTINF1:
    DEC   A                         ;[4418] Convert back to 0-based for table indexing
    LD    H,0                       ;[4419]
    LD    L,A                       ;[441B] HL = 0-based file number
    ADD   HL,HL                     ;[441C] HL = file_number * 2
    ADD   HL,HL                     ;[441D] HL = file_number * 4
    ADD   HL,HL                     ;[441E] HL = file_number * 8 (8 bytes per file record)
    PUSH  DE                        ;[441F] Save BASIC token stream pointer
    LD    DE,S                      ;[4420] DE -> FILINF table start in low RAM (file info base)
    ADD   HL,DE                     ;[4423] HL -> this file's 8-byte record in low RAM
    LD    DE,KNXFIL                 ;[4424] DE -> destination: upper RAM file info area
    LD    BC,8                      ;[4427] BC = 8 bytes per file record
    CALL  ELDIR                     ;[442A] Copy low RAM record to upper RAM (ELDIR: ROM off for LDIR)
    POP   DE                        ;[442D] Restore token stream pointer
    RET                             ;[442E]
;
; PUTINF: write the current file's updated metadata from upper RAM back
; into the low RAM FILINF table.  Also sets bit 6 of KFILE as a cache-
; valid flag so GETINF knows the upper RAM is current for this file.
;
PUTINF:
    LD    HL,KFILE                  ;[442F] HL -> KFILE
    LD    A,(HL)                    ;[4432] A = current file number (1-based)
    SET   6,(HL)                    ;[4433] Set bit 6: upper RAM cache is now valid
    DEC   A                         ;[4435] Convert to 0-based
    LD    H,0                       ;[4436]
    LD    L,A                       ;[4438] HL = 0-based file number
    ADD   HL,HL                     ;[4439] HL = file_number * 8
    ADD   HL,HL                     ;[443A]
    ADD   HL,HL                     ;[443B]
    LD    DE,FILINF                 ;[443C] DE -> FILINF table base in low RAM
    ADD   HL,DE                     ;[443F] HL -> this file's low-RAM record
    EX    DE,HL                     ;[4440] DE -> low-RAM record (destination)
    LD    HL,KNXFIL                 ;[4441] HL -> upper RAM source (KNXFIL onwards)
    LD    BC,RANDOM                 ;[4444] BC = 8 bytes (RANDOM = record size)
    LDIR                            ;[4447] Copy upper RAM record back to low RAM
    RET                             ;[4449]
;
; ATTACH: attach free pages to the current file, extending it if needed.
; Reads NXFRPG (next free page) and chains it onto the end of the current
; file.  Sets Z if no free pages are available and the file has not yet
; been started (KWRPTR high byte = PZ = no pages assigned yet).
;
; On exit: Z set = no free page available AND file not started (error)
;          Z clear = page successfully attached (or file already had pages)
;
ATTACH:
    LD    HL,(KWRPTR)               ;[444A] HL = current write pointer (H=page, L=offset)
    LD    L,0                       ;[444D] L = 0: point to byte 0 of the last used page
    LD    A,H                       ;[444F] A = current last-page number
    CP    PZ                        ;[4450] Is it PZ ($FF)? (file not yet started)
    LD    A,(NXFRPG)                ;[4452] A = next free page number (load regardless)
    JR    Z,ATTCH1                  ;[4455] File not started: go set up first page
    LD    (HL),A                    ;[4457] Chain free page onto end: write link in byte 0 of last page
    RET                             ;[4458] Return with Z clear (file had pages, attachment done)
ATTCH1:
    LD    H,A                       ;[4459] H = first free page -> HL = byte 0 of that page
    LD    (KFSTPG),A                ;[445A] Record as first page of this file
    LD    (KWRPTR),HL               ;[445D] Initialise write pointer to start of first page
    LD    (KRDPTR),HL               ;[4460] Initialise read pointer to start of first page
    LD    H,0                       ;[4463]
    LD    (KFILEN),HL               ;[4465] Initialise file length to 0
    CP    PZ                        ;[4468] Is first free page PZ? (store completely full)
    RET                             ;[446A] Z set if no free page; Z clear if page allocated
;
; DETACH: detach any unused free pages beyond the current write position.
; After writing is complete, the page following KWRPTR may have been
; pre-linked into the chain but is now unneeded.  This routine reads the
; link byte at byte 0 of the last used page (via LAHL, with ROM switched
; out), writes PZ to terminate the file there, and returns that page
; number to NXFRPG so it can be reused.
;
DETACH:
    LD    HL,(KWRPTR)               ;[446B] HL = write pointer (H=page, L=offset)
    LD    A,H                       ;[446E] A = last used page
    CP    PZ                        ;[446F] Is it PZ? (file was never started)
    RET   Z                         ;[4471] Yes: nothing to detach
    LD    L,0                       ;[4472] L = 0: point to byte 0 of last used page
    CALL  LAHL                      ;[4474] A = link at byte 0 (next page in chain, or PZ)
    LD    (HL),PZ                   ;[4477] Terminate file: write PZ into byte 0 of last page
    LD    (NXFRPG),A                ;[4479] Return detached page(s) to free pool
    RET                             ;[447C]
;
; IPWR: input-syntax validation for EXT STORE.
; STORE saves a list of comma-separated variable values (numeric or string)
; to the current pad file.  Syntax: STORE file, var1, var2, ...
; The file number is handled by IEXTS before dispatch here; IPWR validates
; the variable/expression list that follows the comma.
;
IPWR:
    CALL  TEST_IS_COMMA             ;[447D] Assert comma separator; skip spaces
    RST   $10                       ;[4480] Skip spaces; read first char of next argument
    CP    CR                        ;[4481] End of line with no argument?
    CALL  Z,ERR_SOMETHG_MISSG       ;[4483] Yes: "something missing" error
    CALL  TEST_FOR_STR_EXP          ;[4486] Is this argument a string expression?
    JR    NZ,IPWR2                  ;[4489] No: treat as numeric expression
    CALL  READ_STRING_EXPR          ;[448B] Yes: encode string expression into Polish buffer
    INC   DE                        ;[448E] Advance past string expression terminator
    JR    IPWR3                     ;[448F] Check for further arguments
IPWR2:
    CALL  RP                        ;[4491] Encode numeric expression into Polish (reverse Polish)
IPWR3:
    CP    ','                       ;[4494] Is terminator a comma? (more arguments follow)
    JP    NZ,IEND                   ;[4496] No: end of argument list, store CR terminator and return
    LD    (HL),A                    ;[4499] Yes: store comma into Polish buffer
    INC   HL                        ;[449A] Advance Polish buffer pointer
    JR    $4480                     ;[449B] Loop: read next argument
;
; IIST: input-syntax validation for EXT ISTORE.
; ISTORE is like STORE but saves integer (numeric-only) values.
; Syntax: ISTORE file, num1, num2, ...
;
IIST:
    CALL  TEST_IS_COMMA             ;[449D] Assert comma; skip to first argument
IIST1:
    RST   $10                       ;[44A0] Skip spaces; read next char
    CP    CR                        ;[44A1] End of line?
    CALL  Z,ERR_SOMETHG_MISSG       ;[44A3] Yes: error (must have at least one argument)
    CALL  RP                        ;[44A6] Encode numeric expression into Polish buffer
    CP    ','                       ;[44A9] Comma? (more arguments follow)
    JP    NZ,IEND                   ;[44AB] No: store CR terminator and return
    LD    (HL),A                    ;[44AE] Store comma into Polish buffer
    INC   HL                        ;[44AF] Advance Polish buffer pointer
    JR    IIST1                     ;[44B0] Loop: read next argument
;
; IPRD: input-syntax validation for EXT FETCH.
; FETCH reads values from the pad file back into variables.
; Syntax: FETCH file, var1, var2, ...
; Variables may be string or numeric; READ_STRING_VAR and IVRY handle
; the respective encodings.
;
IPRD:
    CALL  TEST_IS_COMMA             ;[44B2] Assert comma; skip to first variable
IPRD1:
    CALL  TEST_FOR_STRING           ;[44B5] Is next argument a string variable?
    JR    NZ,IPRD2                  ;[44B8] No: treat as numeric variable
    CALL  READ_STRING_VAR           ;[44BA] Yes: encode string variable reference into Polish
    RST   $10                       ;[44BD] Skip spaces; read terminator character
    JR    IPRD3                     ;[44BE] Check for more arguments
IPRD2:
    CALL  IVRY                      ;[44C0] Encode numeric variable reference into Polish
IPRD3:
    LD    (HL),A                    ;[44C3] Store terminator (comma or CR) in Polish buffer
    CP    CR                        ;[44C4] End of line?
    RET   Z                         ;[44C6] Yes: done
    RST   $20                       ;[44C7] Assert: must be comma
    DB    ','                       ;[44C8] Expected: ','
    INC   HL                        ;[44C9] Advance Polish buffer past the comma
    INC   DE                        ;[44CA] Advance token stream past the comma
    RST   $10                       ;[44CB] Skip spaces; read first char of next argument
    JR    IPRD1                     ;[44CC] Loop: process next variable
;
; ISSV: input-syntax validation for EXT SSAVE, SLOAD, CSAVE.
; These commands take a file number followed by a filename string.
; Syntax: SSAVE/SLOAD/CSAVE file, "filename"
; After the comma, the rest of the syntax is identical to the LOAD command
; (a quoted filename), so ILOAD is called to handle it.
;
ISSV:
    CALL  TEST_IS_COMMA             ;[44CE] Assert comma separator
    RST   $10                       ;[44D1] Skip spaces; read first char after comma
    JP    ILOAD                     ;[44D2] Handle quoted filename (like LOAD statement)
;
; EPWR: execute EXT STORE - write variable values into the current pad file.
; Accepts a comma-separated list of numeric and string values; each is
; encoded into the store using a compact control-byte + data format.
; For numeric values: control byte $40 (full float) + 5 bytes from WRA1.
; For string values: control byte = $80 | length, followed by the characters.
; Calls WROPEN to open/extend the file, then loops over the argument list.
;
EPWR:
    CALL  WROPEN                    ;[44D5] Open/extend file; HL=write ptr, BC=file length
EPWR1:
    PUSH  BC                        ;[44D8] Save file length count
    PUSH  HL                        ;[44D9] Save write pointer
    LD    A,(DE)                    ;[44DA] Read next argument token
    CP    SOP                       ;[44DB] Start-of-Polish? (numeric expression)
    JR    NZ,EPWR4                  ;[44DD] No: must be a string expression
    RST   40                        ;[44DF] Yes: evaluate numeric expression -> WRA1
    POP   HL                        ;[44E0] Restore write pointer
    POP   BC                        ;[44E1] Restore file length count
    PUSH  DE                        ;[44E2] Save token stream pointer
    CALL  WRADV                     ;[44E3] Advance write pointer + increment file length
    LD    (HL),$40                  ;[44E6] Write control byte $40: full floating-point follows
    LD    IX,SYSVAR_WRA1            ;[44E8] IX -> 5-byte float in WRA1
    LD    E,$05                     ;[44EC] E = 5 bytes to write
EPWR2:
    CALL  WRADV                     ;[44EE] Advance write pointer + increment file length
    LD    A,(IX+0)                  ;[44F1] Read one byte of floating-point value
    INC   IX                        ;[44F4] Advance source pointer
    LD    (HL),A                    ;[44F6] Write byte into pad file
    DEC   E                         ;[44F7] Decrement byte counter
    JR    NZ,EPWR2                  ;[44F8] Loop for all 5 bytes
    POP   DE                        ;[44FA] Restore token stream pointer
    JR    EPWR7                     ;[44FB] Check for more arguments
EPWR4:
    CALL  STRING_EXEC               ;[44FD] Evaluate string expression -> SYSVAR_STRBUF
    POP   HL                        ;[4500] Restore write pointer
    POP   BC                        ;[4501] Restore file length count
    PUSH  DE                        ;[4502] Save token stream pointer
    CALL  WRADV                     ;[4503] Advance write pointer (reserve space for control byte)
    PUSH  HL                        ;[4506] Save address of control byte slot
    LD    E,$80                     ;[4507] E = initial control byte: $80 = string type, length=0
    LD    IX,SYSVAR_STRBUF          ;[4509] IX -> start of evaluated string in STRBUF
EPWR5:
    LD    A,(IX+0)                  ;[450D] Read next character from string
    CP    SZ                        ;[4510] Is it SZ ($0D) string terminator?
    JR    Z,EPWR6                   ;[4512] Yes: string fully written
    INC   IX                        ;[4514] Advance source pointer
    CALL  WRADV                     ;[4516] Advance write pointer + increment file length
    LD    (HL),A                    ;[4519] Write character into pad file
    INC   E                         ;[451A] Increment length count in control byte
    JR    EPWR5                     ;[451B] Loop for next character
EPWR6:
    POP   IX                        ;[451D] IX = saved address of control byte slot (was HL)
    LD    (IX+0),E                  ;[451F] Write completed control byte ($80 | length)
    POP   DE                        ;[4522] Restore token stream pointer
EPWR7:
    LD    A,(DE)                    ;[4523] Read argument separator
    INC   DE                        ;[4524] Advance token stream
    CP    ','                       ;[4525] More arguments?
    JR    Z,EPWR1                   ;[4527] Yes: loop for next argument
    JP    EIST9                     ;[4529] No: finalise file (update pointers, detach, putinf)
;
; EIST: execute EXT ISTORE - write integer variable values into the pad file.
; Like EPWR/STORE but stores only numeric values, using a compact encoding
; that avoids the 5-byte float format where possible:
;   - Value fits in 4 bits (0-15): single control byte with value in low nibble
;   - Value fits in 1 byte:        control byte $10 or $20 + 1 data byte
;   - Requires 2 bytes:            control byte with bit 4 set + 2 data bytes
; The control byte always has bit 6 clear and bit 7 clear (numeric, not full float).
;
EIST:
    CALL  WROPEN                    ;[452C] Open/extend file; HL=write ptr, BC=file length
EIST1:
    PUSH  BC                        ;[452F] Save file length count
    PUSH  HL                        ;[4530] Save write pointer
    LD    A,(DE)                    ;[4531] Read next argument token
    CP    SOP                       ;[4532] Must be a Polish (numeric) expression
    CALL  NZ,ERR_TYPE_MISMATCH      ;[4534] Not numeric: type mismatch error
    RST   40                        ;[4537] Evaluate numeric expression -> WRA1
    POP   HL                        ;[4538] Restore write pointer
    POP   BC                        ;[4539] Restore file length count
;
    PUSH  DE                        ;[453A] Save token stream pointer
    PUSH  BC                        ;[453B] Save file length count
    PUSH  HL                        ;[453C] Save write pointer
    CALL  FPINT                     ;[453D] Convert WRA1 float to integer -> HL
    EX    DE,HL                     ;[4540] DE = integer value
    POP   HL                        ;[4541] Restore write pointer
    POP   BC                        ;[4542] Restore file length count
    LD    A,$0F                     ;[4543] A = $0F: test if value fits in 4 bits (0-15)
    CP    D                         ;[4545] Is D (high byte) > $0F?
    JR    NC,EIST2                  ;[4546] No (D <= $0F): may fit in compact form
    CALL  WRADV                     ;[4548] D > $0F: need 2-byte form, advance write pointer
    LD    (HL),$20                  ;[454B] Write control byte $20 (bit 5 set = two-byte integer)
    JR    EIST4                     ;[454D] Write high byte then low byte
EIST2:
    INC   D                         ;[454F] Test if D is zero (INC then DEC to set flags without modifying)
    DEC   D                         ;[4550]
    JR    NZ,EIST3                  ;[4551] D non-zero: value needs at least high byte too
    CP    E                         ;[4553] D=0: compare E with $0F (does value fit in nibble?)
    JR    NC,EIST5                  ;[4554] E <= $0F: fits in 4 bits, skip to write low byte only
EIST3:
    SET   4,D                       ;[4556] Mark D: bit 4 = "high byte present"
EIST4:
    CALL  WRADV                     ;[4558] Advance write pointer for high byte
    LD    (HL),D                    ;[455B] Write high byte of integer (with flags in upper bits)
EIST5:
    CALL  WRADV                     ;[455C] Advance write pointer for low byte
    LD    (HL),E                    ;[455F] Write low byte of integer
    POP   DE                        ;[4560] Restore token stream pointer
    LD    A,(DE)                    ;[4561] Read argument separator
    INC   DE                        ;[4562] Advance token stream
    CP    ','                       ;[4563] More arguments?
    JR    Z,EIST1                   ;[4565] Yes: loop for next integer
EIST9:
    LD    (KWRPTR),HL               ;[4567] Update KWRPTR with final write position
    LD    (KFILEN),BC               ;[456A] Update KFILEN with final file length
    CALL  DETACH                    ;[456E] Detach any unused free pages beyond write position
    CALL  PUTINF                    ;[4571] Write updated file info back to low RAM
    RET                             ;[4574]
;
; WROPEN: open/extend a pad file for writing.
; Calls GETINF to load file metadata (which reads the file number from the
; token stream), then ATTACH to chain a new free page if needed.
; Errors if no free pages are available.
; On exit: HL = current write pointer, BC = current file length.
;
WROPEN:
    CALL  GETINF                    ;[4575] Load file metadata into upper RAM; advance DE past file number
    CALL  ATTACH                    ;[4578] Chain free page onto file if needed
    CALL  Z,ERR_OUT_OF_MEM          ;[457B] Z set: no free pages available -> out of memory error
    LD    HL,(KWRPTR)               ;[457E] HL = current write pointer
    LD    BC,(KFILEN)               ;[4581] BC = current file length
    RET                             ;[4585]
;
; WRADV: advance the write pointer and increment the file length counter.
; HL = write pointer (H=page, L=offset within page).
; BC = file length (running count of bytes written).
; When L wraps through 0 (page boundary), reads the page-link byte at the
; new page's byte 0 to follow the chain.  Errors if the chain is exhausted.
;
WRADV:
    INC   BC                        ;[4586] Increment file length
    INC   L                         ;[4587] Advance offset within page
    RET   NZ                        ;[4588] No page wrap: return immediately
    PUSH  AF                        ;[4589] Save A (page wrap occurred: L wrapped to 0)
    CALL  LAHL                      ;[458A] Read page-link byte at (HL) with ROM switched out
    CP    PZ                        ;[458D] Is next page PZ? (chain exhausted = store full)
    CALL  Z,ERR_OUT_OF_MEM          ;[458F] Yes: out of memory error
    LD    H,A                       ;[4592] H = next page number -> HL = byte 0 of next page
    INC   L                         ;[4593] L = 1: advance past the page-link byte to first data byte
    POP   AF                        ;[4594] Restore A
    RET                             ;[4595]
;
; EPRD: execute EXT FETCH - read variable values from the pad file.
; Reads the file number, then for each variable in the argument list
; calls RNUM or RSTR (from the low-RAM section) to decode and store the value.
;
EPRD:
    CALL  GETINF                    ;[4596] Load file metadata into upper RAM
    LD    HL,(KRDPTR)               ;[4599] HL = current read pointer
    LD    BC,(KWRPTR)               ;[459C] BC = write pointer (used as end-of-data sentinel by PRDBYT)
EPRD1:
    PUSH  BC                        ;[45A0] Save end sentinel
    PUSH  HL                        ;[45A1] Save read pointer
    CALL  VPTR_IS_STR               ;[45A2] Get variable address -> HL; C flag set if string variable
    PUSH  HL                        ;[45A5]
    POP   IX                        ;[45A6] IX -> variable's storage area in BASIC variable table
    POP   HL                        ;[45A8] Restore read pointer
    POP   BC                        ;[45A9] Restore end sentinel
    JR    C,EPRD2                   ;[45AA] C set: string variable -> read string
    CALL  RNUM                      ;[45AC] Numeric: decode value from store into IX (via low-RAM routine)
    JR    EPRD3                     ;[45AF]
EPRD2:
    CALL  RSTR                      ;[45B1] String: decode string from store into IX
EPRD3:
    LD    A,(DE)                    ;[45B4] Read argument separator in token stream
    INC   DE                        ;[45B5] Advance token stream
    CP    ','                       ;[45B6] More arguments?
    JR    Z,EPRD1                   ;[45B8] Yes: loop for next variable
    LD    (KRDPTR),HL               ;[45BA] Update read pointer after last read
    CALL  PUTINF                    ;[45BD] Write updated file info back to low RAM
    RET                             ;[45C0]

;
; EWIP: execute EXT WIPE - delete a pad file, returning its pages to the free pool.
; Loads the file's metadata, chains its pages onto the free list via ATTACH
; (which adds them by linking them to NXFRPG), then resets all metadata to
; indicate an empty/unused file.
;
EWIP:
    CALL  GETINF                    ;[45C1] Load file metadata into upper RAM
    CALL  ATTACH                    ;[45C4] Link file's existing pages onto next-free chain
    LD    HL,KFSTPG                 ;[45C7] HL -> KFSTPG (first page of file)
    LD    A,(HL)                    ;[45CA] A = first page number
    LD    (NXFRPG),A                ;[45CB] Return first page to free pool (NXFRPG -> head of file)
    LD    A,PZ                      ;[45CE] PZ = no first page (file is empty)
    LD    (HL),A                    ;[45D0] Clear KFSTPG: file no longer has a first page
    LD    H,A                       ;[45D1] H = $FF (PZ): pointer page = "not initialised"
    LD    L,0                       ;[45D2] L = 0
    LD    (KWRPTR),HL               ;[45D4] Reset write pointer to PZ:00 (empty)
    LD    (KRDPTR),HL               ;[45D7] Reset read pointer to PZ:00 (empty)
    LD    H,0                       ;[45DA] H = 0
    LD    (KFILEN),HL               ;[45DC] Reset file length to 0
    JP    PUTINF                    ;[45DF] Write zeroed metadata back to low RAM and return
;
; EBAK: execute EXT BACK - rewind the read pointer to the start of a pad file.
; Loads file metadata and resets KRDPTR to point at the first page of the file.
;
EBAK:
    CALL  GETINF                    ;[45E2] Load file metadata into upper RAM
    LD    A,(KFSTPG)                ;[45E5] A = first page of file
    LD    H,A                       ;[45E8] H = first page -> HL = start of file (offset 0)
    LD    L,0                       ;[45E9]
    LD    (KRDPTR),HL               ;[45EB] Reset read pointer to start of file
    JP    PUTINF                    ;[45EE] Write updated metadata back to low RAM and return
;
; ESLD: execute EXT SLOAD - load a pad file from cassette tape.
; Finds the named file on tape and appends its data blocks to the specified
; pad file.  If the pad has no free pages (Z set by ATTACH), fails with
; out-of-memory.  The tape format for a pad data file is:
;   [filename block] 'D' [length-low] [length-high] [data bytes...] [checksum] ['N'|'E'|'E']
; 'N' after the checksum means another data block follows on the same tape
; recording; any other value means the recording is complete.
;
ESLD:
    CALL  GETINF                    ;[45F1] Load file metadata into upper RAM
    CALL  ATTACH                    ;[45F4] Chain a free page onto the file
    JR    Z,EDLD8                   ;[45F7] Z set: no free pages -> out of memory
    CALL  TAPE_READ                 ;[45F9] Search tape for the named file (advances DE past filename)
EDLD1:
    LD    HL,(KWRPTR)               ;[45FC] HL = current write pointer
    CALL  RSYNC                     ;[45FF] Wait for data block sync leader + $A5 marker
    CALL  RBYTE                     ;[4602] Read block type byte
    CP    'D'                       ;[4605] Is it a data block ('D')?
    JR    NZ,EDLD9                  ;[4607] No: unexpected block type -> bad tape error
    CALL  RBYTE                     ;[4609] Read block length: low byte
    LD    C,A                       ;[460C] C = length low
    CALL  RBYTE                     ;[460D] Read block length: high byte
    LD    B,A                       ;[4610] BC = total byte count for this block
    PUSH  BC                        ;[4611] Save byte count (needed later to update KFILEN)
    LD    E,0                       ;[4612] E = running checksum (initialise to 0)
    JR    EDLD4                     ;[4614] Enter data loop at the count-check (BC may be 0)
EDLD2:
    CALL  RBYTE                     ;[4616] Read one data byte from tape
    LD    D,A                       ;[4619] D = byte value (preserve for storage after checksum update)
    ADD   E                         ;[461A] Add to running checksum (8-bit, wraps)
    LD    E,A                       ;[461B] E = updated checksum
    INC   L                         ;[461C] Advance write-pointer offset within current page
    JR    NZ,EDLD3                  ;[461D] No page boundary: store byte directly
    CALL  LAHL                      ;[461F] Page boundary (L wrapped to 0): read page-link byte
    CP    PZ                        ;[4622] Is next page PZ? (store full)
    JR    Z,EDLD8                   ;[4624] Yes: out of memory
    LD    H,A                       ;[4626] H = next page number
    INC   L                         ;[4627] L = 1: skip past page-link byte to first data slot
EDLD3:
    LD    (HL),D                    ;[4628] Store data byte in pad
    DEC   BC                        ;[4629] Decrement remaining byte count
EDLD4:
    LD    A,B                       ;[462A] Test BC == 0 (all bytes read for this block?)
    OR    C                         ;[462B]
    JR    NZ,EDLD2                  ;[462C] No: read next byte
    CALL  RBYTE                     ;[462E] Read checksum byte from tape
    CP    E                         ;[4631] Does it match our running checksum?
    JR    NZ,EDLD9                  ;[4632] No: checksum error -> bad tape
    CALL  RBYTE                     ;[4634] Read continuation byte ('N' = next block, else end)
    LD    (KWRPTR),HL               ;[4637] Update write pointer after this block
    LD    HL,(KFILEN)               ;[463A] Load current file length
    POP   BC                        ;[463D] Restore this block's byte count
    ADD   HL,BC                     ;[463E] Add block length to running total
    LD    (KFILEN),HL               ;[463F] Update file length
    CP    'N'                       ;[4642] Is continuation byte 'N'? (another block follows)
    JR    Z,EDLD1                   ;[4644] Yes: loop to read next block
    CALL  DETACH                    ;[4646] No: detach unused pages beyond write position
    CALL  MOTOFF                    ;[4649] Stop cassette motor
    JP    PUTINF                    ;[464C] Write updated metadata to low RAM and return
EDLD8:
    CALL  MOTOFF                    ;[464F] Stop motor (no free pages)
    CALL  ERR_OUT_OF_MEM            ;[4652] Report out-of-memory error (does not return)
EDLD9:
    CALL  MOTOFF                    ;[4655] Stop motor (bad tape)
    CALL  ERR_BAD_TAPE              ;[4658] Report tape error (does not return)
;
; ESSV: execute EXT SSAVE - save a single pad file to cassette tape.
; A simplified wrapper around ECSV: loads the named file's metadata, clears
; KNXFIL (so ECSV treats this as the last file in the chain), then falls
; through into the common ECSV1 save body.
;
ESSV:
    CALL  GETINF                    ;[465B] Load file metadata into upper RAM
    XOR   A                         ;[465E] A = 0
    LD    (KNXFIL),A                ;[465F] Clear next-file link: no chained file to follow
    JP    ECSV1                     ;[4662] Fall through into CSAVE body
;
; ECSV: execute EXT CSAVE - save a chain of pad files to cassette tape.
; Saves the named file and any files linked via KNXFIL as a single tape
; recording, each as a separate 'D' block preceded by a shared filename
; header.  Blocks are linked with 'N' separators; the last block ends with
; two 'E' bytes.  Uses the alternate register set to hold bank-switch values
; for EGETB (which needs ROM-off access to read pad data in low RAM).
;
; Tape format written:
;   [WSYNC] [filename] [WSYNC] 'D' [len-lo] [len-hi] [data...] [checksum] ['N'|'E'] ['E']
;
ECSV:
    CALL  GETINF                    ;[4665] Load metadata for the first (or only) file
ECSV1:
    ; Pre-load alternate registers for EGETB's ROM-switching idiom
    EXX                             ;[4668] Switch to alternate register set
    LD    BC,$FF7F                  ;[4669] BC' = bank-switch port ($FF7F)
    LD    DE,$1000                  ;[466C] D'=$10 (ROM off), E'=$00 (ROM on, via mask)
    EXX                             ;[466F] Return to main register set
    CALL  WRITE_FNAME               ;[4670] Write sync leader + filename to tape
ECSV2:
    ; Inner loop: save one file's data block
    EXX                             ;[4673] Switch to alternate registers
    LD    A,(KFSTPG)                ;[4674] A = first page of current file
    LD    H,A                       ;[4677] H = first page -> HL = byte 0 of first page
    LD    L,0                       ;[4678]
    EXX                             ;[467A] Return to main registers (HL' = start of file data)
    CALL  WSYNC                     ;[467B] Write sync leader + $A5 marker to finish off name block
    LD    A,'D'                     ;[467E] Block type: 'D' = data
    CALL  SYSVAR_WBYTE              ;[4680] Write block type to tape
    LD    BC,(KFILEN)               ;[4683] BC = file length in bytes
    LD    A,C                       ;[4687] Write length low byte
    CALL  SYSVAR_WBYTE              ;[4688]
    LD    A,B                       ;[468B] Write length high byte
    CALL  SYSVAR_WBYTE              ;[468C]
    LD    E,0                       ;[468F] E = running checksum (initialise to 0)
    JR    ECSV4                     ;[4691] Enter data loop at count-check (file may be empty)
ECSV3:
    CALL  EGETB                     ;[4693] Read next byte from pad (low RAM, ROM switched off)
    CALL  SYSVAR_WBYTE              ;[4696] Write byte to tape
    ADD   E                         ;[4699] Add to running checksum (8-bit)
    LD    E,A                       ;[469A] E = updated checksum
    DEC   BC                        ;[469B] Decrement remaining byte count
ECSV4:
    LD    A,B                       ;[469C] Test BC == 0 (all bytes written?)
    OR    C                         ;[469D]
    JR    NZ,ECSV3                  ;[469E] No: write next byte
    LD    A,E                       ;[46A0] All bytes written: A = final checksum
    CALL  SYSVAR_WBYTE              ;[46A1] Write checksum byte to tape
    LD    A,(KNXFIL)                ;[46A4] A = next file number in chain (0 if none)
    OR    A                         ;[46A7] Is there a next file?
    JR    Z,ECSV5                   ;[46A8] No: write end-of-recording marker
    LD    D,A                       ;[46AA] D = next file number
    LD    A,'N'                     ;[46AB] 'N' = more data follows
    CALL  SYSVAR_WBYTE              ;[46AD] Write 'N' continuation byte to tape
    LD    A,D                       ;[46B0] A = next file number
    CALL  GTINF1                    ;[46B1] Load next file's metadata (1-based, re-uses GETINF body)
    JR    ECSV2                     ;[46B4] Loop: save next file's data block
ECSV5:
    LD    A,'E'                     ;[46B6] 'E' = end of recording
    CALL  SYSVAR_WBYTE              ;[46B8] Write first 'E' byte
    CALL  SYSVAR_WBYTE              ;[46BB] Write second 'E' byte (belt-and-braces termination)
    JP    MOTOFF                    ;[46BE] Stop cassette motor and return
;
; ECHN: execute EXT CHAIN - link two pad files into a CSAVE chain.
; Sets the KNXFIL field of the first (current) file to point to the second.
; Validates that the resulting chain is not circular (would cause CSAVE
; to loop forever).  File number 0 is allowed to clear the chain link.
;
ECHN:
    CALL  GETINF                    ;[46C1] Load metadata for the first file
    RST   $18                       ;[46C4] Evaluate second file number -> HL, A = low byte
    DEC   H                         ;[46C5] Test high byte: DEC then INC to set Z if was 0
    INC   H                         ;[46C6]
    CALL  NZ,ERR_NUM_OUT_RANGE      ;[46C7] High byte non-zero: out of range
    CP    MXNFIL+1                  ;[46CA] File number must be 0..48 (0 = clear chain link)
    CALL  NC,ERR_NUM_OUT_RANGE      ;[46CC] >= 49: out of range
    LD    C,A                       ;[46CF] C = new next-file number
    LD    HL,KFILE                  ;[46D0] HL -> KFILE
    LD    B,(HL)                    ;[46D3] B = current (first) file number
    JR    ECHN2                     ;[46D4] Enter chain-validation loop (check for circularity)
ECHN1:
    ; Walk the chain: follow KNXFIL links from each file's low-RAM record
    DEC   A                         ;[46D6] Convert 1-based file number to 0-based
    LD    H,0                       ;[46D7]
    LD    L,A                       ;[46D9] HL = 0-based file index
    ADD   HL,HL                     ;[46DA] HL = index * 8 (8 bytes per file record)
    ADD   HL,HL                     ;[46DB]
    ADD   HL,HL                     ;[46DC]
    LD    DE,FILINF+0               ;[46DD] DE -> FILINF table (byte 0 of each entry = KNXFIL)
    ADD   HL,DE                     ;[46E0] HL -> KNXFIL field for this file
    CALL  LAHL                      ;[46E1] A = KNXFIL value (next file in chain, or 0)
ECHN2:
    CP    B                         ;[46E4] Does next link point back to the current (first) file?
    CALL  Z,ERR_OVERFLOW            ;[46E5] Yes: circular chain detected -> overflow error
    OR    A                         ;[46E8] Is this the end of the chain (next = 0)?
    JR    NZ,ECHN1                  ;[46E9] No: follow next link
    LD    HL,KNXFIL                 ;[46EB] Reached end of chain: update first file's KNXFIL
    LD    (HL),C                    ;[46EE] Set KNXFIL = new next-file number
    JP    PUTINF                    ;[46EF] Write updated metadata to low RAM and return
;
; ITRP: input-syntax validation for EXT TRAP.
; TRAP takes a single numeric variable name (the variable that will receive
; the error code when an error is trapped).
;
ITRP:
    CALL  IVRY                      ;[46F2] Encode numeric variable reference into Polish buffer
    JP    IEND                      ;[46F5] Store CR terminator and return
;
; ETRP: execute EXT TRAP - set up error trapping.
; Reads the target variable's address, stores it in ERRVR (the error-trap
; variable pointer), and initialises the variable to 0.  When an error
; subsequently occurs, ERRORHANDLER checks ERRVR and, if set, stores the
; error code there and resumes execution rather than reporting the error.
;
ETRP:
    CALL  GET_VAR_ADDR              ;[46F8] Get address of target variable -> HL
    LD    (ERRVR),HL                ;[46FB] Store variable address as error-trap target
    EX    DE,HL                     ;[46FE] DE -> variable (destination for initialisation)
    LD    HL,FLOAT_ZERO             ;[46FF] HL -> 5-byte floating-point zero constant
    LD    BC,5                      ;[4702] BC = 5 bytes
    LDIR                            ;[4705] Zero the trap variable (TRAP clears any previous code)
    RET                             ;[4707]
;
; ENTR: execute EXT NOTRAP - remove error trap.
; Clears ERRVR to 0, disabling the error trap set by TRAP.
;
ENTR:
    LD    HL,0                      ;[4708] HL = 0 (null pointer)
    LD    (ERRVR),HL                ;[470B] Clear error-trap variable address
    RET                             ;[470E]
;
; ERRORHANDLER: error-dispatch hook installed into SYSVAR_ERRTBL by EXINIT.
; Called by the 48k ROM error machinery whenever an error is raised.
; On entry: A = error code, stack has ERROR_PRINT as the return address.
;
; Behaviour:
;   - If not in a running BASIC program (SYSVAR_CURRLP points at $80 line),
;     fall through to normal error printing.
;   - If ERRVR is set (TRAP active): store the error code into the trap
;     variable as a float, then restore SP from EXECSP and resume execution
;     via EXEC2 (as if no error occurred).  Error code 0 is also silently
;     absorbed (ERRSR2) since 0 means "no error" by convention.
;   - Otherwise: fall through to the 48k ROM's normal error handler.
;
ERRORHANDLER:
    LD    HL,ERROR_PRINT            ;[470F] HL = address of normal error-print routine
    EX    (SP),HL                   ;[4712] Push ERROR_PRINT as our eventual return; pop caller's ret addr
    LD    C,A                       ;[4713] C = error code (preserve across calls)
    LD    HL,(SYSVAR_CURRLP)        ;[4714] HL -> current line pointer
    LD    A,(HL)                    ;[4717] Read first byte of current line
    CP    $80                       ;[4718] Is it $80? ($80 = "not in program" sentinel)
    JR    Z,ERRSR3                  ;[471A] Yes: not running a program, never trap, fall through
    LD    HL,(ERRVR)                ;[471C] HL = error-trap variable address (0 if NOTRAP)
    LD    A,H                       ;[471F]
    OR    L                         ;[4720] Is ERRVR zero? (no trap set)
    JR    Z,ERRSR1                  ;[4721] Yes: no trap; check for error code 0
    ; TRAP is active: store error code into trap variable and resume
    PUSH  HL                        ;[4723] Save trap variable address
    LD    L,C                       ;[4724] L = error code
    LD    H,0                       ;[4725] HL = error code as 16-bit integer
    CALL  INTFP                     ;[4727] Convert integer to 5-byte float in WRA1
    LD    HL,SYSVAR_WRA1            ;[472A] HL -> float result
    POP   DE                        ;[472D] DE -> trap variable (saved address)
    LD    BC,NEXT                   ;[472E] BC = 5 (NEXT = bytes per float: reusing constant)
    LDIR                            ;[4731] Copy float error code into trap variable
    JR    ERRSR2                    ;[4733] Resume execution
ERRSR1:
    LD    A,C                       ;[4735] Restore error code
    OR    A                         ;[4736] Is error code 0?
    JR    NZ,ERRSR3                 ;[4737] Non-zero: no trap, report error normally
ERRSR2:
    LD    SP,(EXECSP)               ;[4739] Restore SP to value saved at start of line execution
    JP    EXEC2                     ;[473D] Resume BASIC execution at next statement
ERRSR3:
    LD    HL,(SYSVAR_ERRTBL)        ;[4740] HL -> 48k ROM's error-table entry for this code
    LD    A,C                       ;[4743] Restore error code into A
    RET                             ;[4744] Return to ERROR_PRINT via stack (set up by EX (SP),HL)
;
; EXSR: line-execution hook installed into SYSVAR_EXECSUB by EXINIT.
; Called at the start of each BASIC line execution (via the EXECSUB hook
; vector).  Saves the current stack pointer in EXECSP so ERRORHANDLER can
; restore it if a TRAP catches an error on this line.
;
EXSR:
    POP   HL                        ;[4745] Pop the return address (where EXEC would return to)
    LD    (EXECSP),SP               ;[4746] Save SP: this is the "clean" stack level for this line
    JP    (HL)                      ;[474A] Jump to the actual return address (resume EXEC)
;
; Padding to align EPPR to $4800
;
DEFS 181, $FF
;
;----------------------------------------------------------
;
;		***  PRINTER ROUTINES  ***
;
; EPPR: execute EXT PPRINT - initialise the parallel printer port.
; Strobes the centronics handshake port ($7D) to initialise the hardware,
; installs PPCHAR as the BASIC printer character-output driver (via
; SYSVAR_LPRNTD), and copies the PSTORE default flag/timing values into
; the LXFLAG printer-control RAM area.
; Also called by EXINIT on startup to configure the port at boot time.
;
EPPR:
    PUSH  AF                        ;[4800] Save all registers (may be called at init time)
    PUSH  HL                        ;[4801]
    PUSH  DE                        ;[4802]
    PUSH  BC                        ;[4803]
    IN    A,($7D)                   ;[4804] Read/write port $7D: initialises centronics interface
    LD    HL,PPCHAR                 ;[4806] HL -> PPCHAR: parallel printer character-output routine
    LD    (SYSVAR_LPRNTD),HL        ;[4809] Install as BASIC's printer driver
    LD    HL,PSTORE                 ;[480C] HL -> PSTORE: default parallel printer flag values
; Shared with ESPRT1 (serial init copies 10 bytes; parallel copies 7)
    LD    DE,LXFLAG                 ;[480F] DE -> LXFLAG: start of printer control RAM block
    LD    BC,7                      ;[4812] BC = 7 bytes to copy (LXFLAG..BUFSIZ + BUFCT + zero)
    LDIR                            ;[4815] Copy printer default settings into RAM
    POP   BC                        ;[4817]
    POP   DE                        ;[4818]
    POP   HL                        ;[4819]
    POP   AF                        ;[481A]
    RET                             ;[481B]
;
; EPPR2: entry point used by PPCHR4 to send a byte to the parallel port.
; On entry: A = character byte to send (saved in L by PPCHR4 before the jump)
; L holds the character byte; the routine waits for the printer to be ready
; (STAP), checks for ESCAPE key abort, then outputs via port $7E.
;
EPPR2:
    LD    L,A                       ;[481C] Save character byte in L (STAP/BASP2 uses L)
    LD    BC,$80                    ;[481D] BC = port $80 (keyboard scan port, column 0)
BASP1:
    ; Keyboard abort check: poll keyboard column 0 for ESCAPE key
    IN    A,(C)                     ;[4820] Read keyboard column 0 via port $80
    BIT   6,A                       ;[4822] Test bit 6: ESCAPE key pressed?
    RET   Z                         ;[4824] Yes: abort print (return without printing)
;
; STAP: test whether the parallel printer is ready to receive a byte.
; Reads the centronics status port ($7C): bit 0 = printer busy (0=busy),
; bit 1 = paper-out or offline (0=fault).  Loops back to BASP1 (keyboard
; check) while the printer is busy.
;
STAP:
    IN    A,($7C)                   ;[4825] Read centronics status port
    BIT   0,A                       ;[4827] Test bit 0: printer ready? (1=ready, 0=busy)
    JR    Z,BASP1                   ;[4829] Printer busy: loop back to keyboard/ready check
    BIT   1,A                       ;[482B] Test bit 1: printer online/paper OK? (0=fault)
    RET   Z                         ;[482D] Fault: return without printing
BASP2:
    ; Printer ready: output the character
    LD    A,L                       ;[482E] Restore character byte from L
    OUT   ($7E),A                   ;[482F] Output character to parallel data port $7E
SRLC4:
    ; Update line-position counter (BUFCT) for column-tracking
    CP    ' '                       ;[4831] Is character a control character (< space)?
    CALL  C,NLTEST                  ;[4833] Yes: test if it causes a new line, result in C flag
    LD    HL,BUFCT                  ;[4836] HL -> BUFCT (current column position counter)
    JR    C,PLL4                    ;[4839] C set: new line triggered -> reset BUFCT to 0
    INC   (HL)                      ;[483B] Printable char: increment column counter
    LD    A,(BUFSIZ)                ;[483C] A = line width (default 80)
    CP    (HL)                      ;[483F] Reached end of line?
    RET   NC                        ;[4840] Not yet: return
    LD    (HL),1                    ;[4841] Yes: wrap - reset BUFCT to 1 (start of next line)
    RET                             ;[4843]
PLL4:
    LD    (HL),0                    ;[4844] New line: reset BUFCT to 0 (start of line)
    RET                             ;[4846]
;
; PSTORE: default printer-control values for the PARALLEL printer.
; Copied to LXFLAG..BUFCT+2 on PPRINT initialisation (7 bytes).
; Layout matches the LXFLAG RAM block defined in Lynx.def:
;   LXFLAG  (4 bytes) - control-character action bitmap (32 chars * 1 bit each)
;   NLFLAG  (1 byte)  - "this char causes newline" flag
;   BUFSIZ  (1 byte)  - line width (80)
;   BUFCT   (1 byte)  - current column position (starts at 0)
;
PSTORE:
    DB    %00000000,%00100100       ;[4847] LXFLAG bytes 0-1: CR,LF,FF pass through; others ignored
    DB    %00001000,%10000000       ;[4849] LXFLAG bytes 2-3: TAB, backspace pass through
    DB    %00001111                 ;[484B] NLFLAG: chars that reset column counter (CR/LF/FF/VT)
    DB    80                        ;[484C] BUFSIZ: line width = 80 columns
    DB    0                         ;[484D] BUFCT: initial column position = 0
;
; ESPR: execute EXT SPRINT - initialise the serial printer port.
; Like EPPR but installs SPCHAR as the driver and copies the larger SSTORE
; block (10 bytes including baud-rate timing parameters) into LXFLAG.
;
ESPR:
    PUSH  AF                        ;[484E]
    PUSH  HL                        ;[484F]
    PUSH  DE                        ;[4850]
    PUSH  BC                        ;[4851]
    LD    HL,SPCHAR                 ;[4852] HL -> SPCHAR: serial printer character-output routine
    LD    (SYSVAR_LPRNTD),HL        ;[4855] Install as BASIC's printer driver
    LD    HL,SSTORE                 ;[4858] HL -> SSTORE: default serial printer settings
ESPRT1:
    LD    DE,LXFLAG                 ;[485B] DE -> LXFLAG RAM block
    LD    BC,$0A                    ;[485E] BC = 10 bytes (includes baud timing: BUFDLY/PRTDLY/FFDLY)
    LDIR                            ;[4861] Copy serial printer defaults into RAM
    POP   BC                        ;[4863]
    POP   DE                        ;[4864]
    POP   HL                        ;[4865]
    POP   AF                        ;[4866]
    RET                             ;[4867]
;
; ESPRT2: send a byte to the serial printer port.
; Waits for the serial transmit-ready flag (bit 6 of port $84), then
; outputs the byte via port $82.  After output, calls NLTEST to track
; column position, then applies inter-character and formfeed delays.
;
ESPRT2:
    PUSH  AF                        ;[4868] Save character byte
    LD    C,A                       ;[4869] C = character to send
ESPRT3:
    IN    A,($84)                   ;[486A] Read serial status port
    BIT   6,A                       ;[486C] Bit 6: transmit ready?
    JR    Z,ESPRT3                  ;[486E] Not ready: spin-wait
    LD    A,C                       ;[4870] Restore character
    OUT   ($82),A                   ;[4871] Output character to serial data port $82
    LD    A,(BUFDLY)                ;[4873] A = inter-byte delay value (BUFDLY from SSTORE)
    LD    B,$05                     ;[4876] B = delay multiplier (5 iterations)
    CALL  SPRTDELAY                 ;[4878] Wait: baud-rate pacing delay after the byte
    LD    A,C                       ;[487B] Restore character for column-tracking
    ; Column tracking (shared logic with SRLC4 in parallel path)
    CP    ' '                       ;[487C] Control character?
    CALL  C,NLTEST                  ;[487E] Yes: test for newline, result in C flag
    LD    HL,BUFCT                  ;[4881] HL -> BUFCT (column counter)
    JR    C,ESPRT4                  ;[4884] C set: newline -> reset column counter
    INC   (HL)                      ;[4886] Printable: increment column
    LD    A,(BUFSIZ)                ;[4887] A = line width
    CP    (HL)                      ;[488A] End of line?
    JR    NC,ESPRT7                 ;[488B] No: skip to post-delay
    LD    (HL),1                    ;[488D] Yes: reset column counter to 1
    JR    ESPRT5                    ;[488F] Jump over newline-specific extra delay
ESPRT4:
    LD    A,(HL)                    ;[4891] Save current column count
    LD    (HL),0                    ;[4892] Reset column counter to 0 (newline occurred)
ESPRT5:
    ADD   $10                       ;[4894] A = old column count + $10 (extra delay slots)
    LD    B,A                       ;[4896] B = total inter-character delay iterations
ESPRT6:
    PUSH  BC                        ;[4897] Save delay counter
    LD    A,(PRTDLY)                ;[4898] A = per-iteration print delay value
    LD    B,$05                     ;[489B] B = delay multiplier
    CALL  SPRTDELAY                 ;[489D] Apply one iteration of print delay
    POP   BC                        ;[48A0]
    DJNZ  ESPRT6                    ;[48A1] Repeat for all delay iterations
ESPRT7:
    POP   AF                        ;[48A3] Restore original character byte
    CP    $0C                       ;[48A4] Is it a formfeed ($0C)?
    RET   NZ                        ;[48A6] No: return
    LD    A,(FFDLY)                 ;[48A7] Yes: A = formfeed extra-delay value
    LD    B,$0E                     ;[48AA] B = delay multiplier (14 iterations)
    CALL  SPRTDELAY                 ;[48AC] Apply formfeed delay (paper advance time)
    RET                             ;[48AF]
;
; SPRTDELAY: timing delay used for serial baud-rate pacing and formfeed.
; Performs B iterations of an inner loop that counts HL down from 2^B to 0,
; giving a total delay that scales as A * 2^B loop iterations.
; On entry: A = delay parameter, B = shift count (typically 5 or 14).
;
SPRTDELAY:
    LD    HL,1                      ;[48B0] HL = 1 (starting value for left-shift)
SPRTDELAY1:
    ADD   HL,HL                     ;[48B3] HL = HL * 2 (shift left)
    DJNZ  SPRTDELAY1                ;[48B4] Repeat B times: HL = 2^B
    LD    B,A                       ;[48B6] B = outer loop count (= delay parameter A)
SPRTDELAY2:
    PUSH  HL                        ;[48B7] Save inner-loop count
SPRTDELAY3:
    DEC   HL                        ;[48B8] Inner loop: decrement HL
    LD    A,L                       ;[48B9]
    OR    H                         ;[48BA] HL == 0?
    JR    NZ,SPRTDELAY3             ;[48BB] No: keep decrementing
    POP   HL                        ;[48BD] Restore HL = 2^B for next outer iteration
    DJNZ  SPRTDELAY2                ;[48BE] Repeat A times
    RET                             ;[48C0] Total delay ≈ A * 2^B inner iterations
;
; SSTORE: default printer-control values for the SERIAL printer.
; Copied to LXFLAG (10 bytes) on SPRINT initialisation.
; Layout matches LXFLAG RAM block; 10 bytes covers LXFLAG(4) + NLFLAG(1) +
; BUFSIZ(1) + BUFCT(1) + BUFDLY(1) + PRTDLY(1) + FFDLY(1).
;
SSTORE:
    DB    %00000000,%00100010       ;[48C1] LXFLAG 0-1: CR, LF pass through to serial port
    DB    %00001000,%11000000       ;[48C3] LXFLAG 2-3: TAB, backspace, DEL pass through
    DB    %00011111                 ;[48C5] NLFLAG: chars that cause newline (CR/LF/FF/VT/BS)
    DB    %01010000                 ;[48C6] BUFSIZ: line width = 80 ($50)
    DB    %00000000                 ;[48C7] BUFCT: initial column = 0
    DB    %01000001                 ;[48C8] BUFDLY: inter-byte delay ($41)
    DB    %10000111                 ;[48C9] PRTDLY: inter-character print delay ($87)
    DB    %10000111                 ;[48CA] FFDLY:  formfeed delay ($87)
;
; PPCHAR: send character A to the parallel printer.
; SPCHAR: send character A to the serial printer.
; Shared body (PPCHR1 onwards).  E=0 selects parallel (EPPR2/STAP path);
; E=1 selects serial (ESPRT2 path).  Control characters (< space) are first
; translated via OCHR/LXOUT before output.  Printable characters go directly
; to PPCHR4 -> EPPR2 or ESPRT2.
;
; Parallel
PPCHAR:
    PUSH  DE                        ;[48CB] Save DE
    LD    E,0                       ;[48CC] E = 0: select parallel printer path
    JR    PPCHR1                    ;[48CE]
; Serial
SPCHAR:
    PUSH  DE                        ;[48D0] Save DE
    LD    E,1                       ;[48D1] E = 1: select serial printer path
PPCHR1:
    PUSH  AF                        ;[48D3] Save character byte
    PUSH  HL                        ;[48D4]
    PUSH  BC                        ;[48D5]
    CP    ' '                       ;[48D6] Is character a control character (< $20)?
    CALL  C,OCHR                    ;[48D8] Yes: call OCHR to look up action in LXFLAG bitmap
    JR    NC,PPCHR2                 ;[48DB] OCHR returned carry clear: send character as-is via PPCHR4
    CALL  LXOUT                     ;[48DD] Carry set from OCHR: translate control char via LXOUT
    JR    PPCHR3                    ;[48E0] (LXOUT may recurse via PPCHR4 internally; skip direct call)
PPCHR2:
    CALL  PPCHR4                    ;[48E2] Send character to hardware via EPPR2 or ESPRT2
PPCHR3:
    POP   BC                        ;[48E5]
    POP   HL                        ;[48E6]
    POP   AF                        ;[48E7]
    POP   DE                        ;[48E8]
    RET                             ;[48E9]
;
; PPCHR4: dispatch to the correct hardware output routine.
; Tests E: 0 = parallel (EPPR2), 1 = serial (ESPRT2).
;
PPCHR4:
    BIT   0,E                       ;[48EA] Test E bit 0: 0=parallel, 1=serial
    JP    Z,EPPR2                   ;[48EC] E=0: send via parallel port
    JP    ESPRT2                    ;[48EF] E=1: send via serial port
;
; OCHR: look up a control character's action in the LXFLAG bitmap.
; LXFLAG is a 4-byte (32-bit) bitmap, one bit per control character ($00-$1F).
; A bit set means the character should be passed to LXOUT for special handling
; (translation/suppression/newline simulation); bit clear means send as-is.
; On entry: A = control character (< $20), C = original character.
; On exit:  carry set = call LXOUT; carry clear = send A directly.
;           A = original character restored in C on return.
;
OCHR:
    LD    C,A                       ;[48F2] C = control character (save for return)
    SRL   A                         ;[48F3] A = char >> 1
    SRL   A                         ;[48F5] A = char >> 2
    SRL   A                         ;[48F7] A = char >> 3 = byte index into LXFLAG (0-3)
    LD    HL,LXFLAG                 ;[48F9] HL -> LXFLAG bitmap base
    ADD   L                         ;[48FC] A = L + byte_index
    JR    NC,LXTEST                 ;[48FD] No carry: index stays within first byte of HL
    INC   H                         ;[48FF] Carry: index crossed a 256-byte page boundary
;
; LXTEST: extract the bit for this character from the LXFLAG byte.
; On entry: HL -> correct LXFLAG byte; C = original character.
; Bit position within the byte = character & 7.
; On exit:  carry = the extracted bit (set = special action needed).
;           A = original character (restored from C).
;
LXTEST:
    LD    L,A                       ;[4900] HL -> the correct byte in LXFLAG
    LD    A,C                       ;[4901] A = original character
    AND   7                         ;[4902] A = bit position within the byte (char & 7)
    LD    B,A                       ;[4904] B = bit position
    INC   B                         ;[4905] B = bit_position + 1 (RRA B+1 times shifts bit into carry)
    LD    A,(HL)                    ;[4906] A = LXFLAG byte for this group of 8 chars
LXT2:
    RRA                             ;[4907] Rotate right: shift next bit into carry
    DJNZ  LXT2                      ;[4908] Repeat B+1 times to land the target bit in carry
    LD    A,C                       ;[490A] Restore original character into A
    RET                             ;[490B] Return: carry = action flag for this control char
;
; LXOUT: translate a control character for printer output.
; Looks up the character in LXTABL (a 32-entry translation table for $00-$1F).
; A zero entry means "suppress" (do not print); non-zero = replacement char.
; Special cases:
;   Tab ($09 from table) -> expand to spaces to next 8-column tab stop.
;   Conditional LF ($13 from table) -> output LF only if not at column 0.
; Other mapped characters are passed directly to PPCHR4.
;
LXOUT:
    LD    HL,LXTABL                 ;[490C] HL -> control-character translation table
    LD    B,0                       ;[490F] B = 0: make BC = char for 16-bit ADD HL,BC
    LD    C,A                       ;[4911] C = original control character (index into table)
    ADD   HL,BC                     ;[4912] HL -> table entry for this character
    LD    A,(HL)                    ;[4913] A = translated character (0 = suppress)
    OR    A                         ;[4914] Zero?
    RET   Z                         ;[4915] Yes: suppress this control character, return
    CP    9                         ;[4916] Is translated value 9 (tab)?
    JR    NZ,LX02                   ;[4918] No: handle other translations
    ; Tab expansion: advance to the next 8-column boundary
    LD    A,(BUFCT)                 ;[491A] A = current column position
    LD    B,A                       ;[491D] B = current column (save)
    AND   %11111000                 ;[491E] A = column rounded down to 8-column boundary
    ADD   8                         ;[4920] A = next tab stop position - 1
    LD    HL,BUFSIZ                 ;[4922] HL -> BUFSIZ (line width)
    CP    (HL)                      ;[4925] Would tab stop go past end of line?
    JR    NC,LX03                   ;[4926] Yes: emit a newline instead
    SUB   B                         ;[4928] A = number of spaces needed to reach tab stop
    LD    B,A                       ;[4929] B = space count
LX01:
    LD    A,$20                     ;[492A] A = space character
    PUSH  BC                        ;[492C] Save space counter
    CALL  PPCHR4                    ;[492D] Output one space to hardware
    POP   BC                        ;[4930]
    DJNZ  LX01                      ;[4931] Loop for all required spaces
    RET                             ;[4933]
LX02:
    CP    $13                       ;[4934] Is translated value $13 (conditional linefeed)?
    JR    NZ,LX04                   ;[4936] No: output the translated character directly
    LD    A,(BUFCT)                 ;[4938] A = current column (0 = already at line start)
    OR    A                         ;[493B] Is BUFCT zero? (already at start of line)
    RET   Z                         ;[493C] Yes: suppress the linefeed (avoid double spacing)
LX03:
    LD    A,$0A                     ;[493D] A = linefeed ($0A)
LX04:
    CALL  PPCHR4                    ;[493F] Output the translated/generated character
    RET                             ;[4942]
;
; LXTABL: control-character translation table for the printer.
; One entry per character $00-$1F (32 entries).
; 0 = suppress (don't print); non-zero = substitute this value.
; Notable mappings:
;   $03 -> $0C (ETX -> form feed)
;   $09 -> 9   (HT  -> tab expansion via LXOUT special case)
;   $0A -> $0A (LF  -> newline pass-through)
;   $0B -> $0A (VT  -> newline)
;   $0C -> $0A (FF  -> newline; physical FF handled separately)
;   $0D -> $0A (CR  -> newline on printer)
;   $10 -> $0C (DLE -> form feed)
;   $13 -> $13 (DC3/XOFF -> conditional LF)
;   $16 -> 8   (SYN -> backspace)
;   $1F -> $0A (US  -> newline)
;
LXTABL:
    DB    0,0,0,0,$0C,0,0,0         ;[4943] $00-$07: suppress all except $03->FF
    DB    0,9,0,0,$0A,$0A,0,0       ;[494B] $08-$0F: TAB->tab expand, LF->LF, CR->LF
    DB    $0C,0,0,$13,0,0,8,0       ;[4953] $10-$17: DLE->FF, DC3->condLF, SYN->BS
    DB    0,0,0,0,0,0,0,$0A         ;[495B] $18-$1F: suppress all except $1F->LF
;
; NLTEST: test whether a control character causes a new line on the printer.
; Used to maintain BUFCT (column counter): after printing a newline-inducing
; control character, BUFCT must be reset.  Returns result in carry via C.
;
; NLFLAG is a 6-bit mask: each bit corresponds to one of the 6 "newline"
; characters listed in NLTABL.  If the incoming character matches, the
; corresponding bit is set in C, then rotated into carry on return.
;
; On entry: A = control character being tested.
; On exit:  carry set = this character causes a new line; C modified.
;
NLTEST:
    LD    HL,NLFLAG                 ;[4963] HL -> NLFLAG (bitmask of which chars cause newline)
    LD    C,(HL)                    ;[4966] C = NLFLAG byte (existing state)
    LD    B,6                       ;[4967] B = 6: test against 6 newline characters
    LD    HL,NLTABL                 ;[4969] HL -> NLTABL: list of newline-causing characters
NLT1:
    CP    (HL)                      ;[496C] Does A match this table entry?
    JR    Z,NLT2                    ;[496D] Yes: match found
    INC   HL                        ;[496F] Advance to next table entry
    RR    C                         ;[4970] Rotate C right (cycling through the 6 flag bits)
    DJNZ  NLT1                      ;[4972] Loop for all 6 entries
    LD    C,0                       ;[4974] No match: C = 0 (clear all bits)
NLT2:
    RR    C                         ;[4976] Rotate matched/unmatched result into carry
    RET                             ;[4978] Return: carry = "this char causes newline"
;
; NLTABL: list of control characters that cause a new line on the printer.
; LF($0A), CR($0D), DC4($14), FF($0C), VT($0B), BS($08).
; The trailing zeros are padding (not used; NLTEST only checks 6 entries).
;
NLTABL:
    DB    $0A,$0D,$14,$0C,$0B,8,0,0 ;[4979] LF, CR, DC4, FF, VT, BS

;----------------------------------------------------------
;
; FPEN: LIGHTPEN(n) function - read the lightpen position.
; Returns the X coordinate (n=0) or Y coordinate (n=1) as a float in WRA1.
; The Lynx lightpen interface uses two hardware registers (accessed via port
; $86 to select, port $87 to read):
;   $11 = LP low byte  (X-related low)
;   $10 = LP high byte (Y-related high)
; The LPOFFS calibration byte has Y offset in bits 3-0 and X offset in bits 7-4.
; Range is 0-256 for both axes, matching the text window coordinates.
;
; On entry: WRA1 = argument (0=X, 1=Y) as a float.
;
FPEN:
    CALL  FPINT                     ;[4981] Convert WRA1 float -> integer in HL
    DEC   H                         ;[4984] Test H is zero (DEC then INC without changing H)
    INC   H                         ;[4985]
    CALL  NZ,ERR_NUM_OUT_RANGE      ;[4986] H non-zero: argument > 255, out of range
    LD    C,$87                     ;[4989] C = $87: port to read lightpen data
    LD    A,$11                     ;[498B] A = $11: select LP low register
    OUT   ($86),A                   ;[498D] Write to port $86: select LP register $11
    IN    E,(C)                     ;[498F] E = LP low byte value (read from port $87)
    INC   L                         ;[4991] Test L: INC then DEC to set flags without changing L
    DEC   L                         ;[4992]
    JR    Z,FLT1                    ;[4993] L=0: argument was 0, so return X coordinate
    DEC   L                         ;[4995] L was 1 (Y argument): decrement to test for exactly 1
    CALL  NZ,ERR_NUM_OUT_RANGE      ;[4996] L non-zero after DEC: argument was > 1, error
    ; Return Y coordinate
    DEC   A                         ;[4999] A = $10: select LP high register
    OUT   ($86),A                   ;[499A] Write to port $86: select LP register $10
    IN    D,(C)                     ;[499C] D = LP high byte value (read from port $87)
    EX    DE,HL                     ;[499E] HL = raw Y data (H=high byte, L=low byte)
    ADD   HL,HL                     ;[499F] HL = raw Y << 1
    ADD   HL,HL                     ;[49A0] HL = raw Y << 2
    ADD   HL,HL                     ;[49A1] HL = raw Y << 3 (scale raw value to screen coords)
    LD    A,(LPOFFS)                ;[49A2] A = lightpen calibration offset byte
    AND   %00001111                 ;[49A5] Mask bits 3-0: Y calibration offset
    RLCA                            ;[49A7] Rotate left once (scale Y offset)
    SUB   $10                       ;[49A8] Subtract calibration baseline
    ADD   H                         ;[49AA] Add scaled raw Y high byte
    JR    FLT2                      ;[49AB] Store result and convert to float
FLT1:
    ; Return X coordinate
    SLA   E                         ;[49AD] Shift E left: scale raw X low byte
    SLA   E                         ;[49AF]
    SLA   E                         ;[49B1] E = raw X << 3 (scale to screen range)
    LD    A,(LPOFFS)                ;[49B3] A = lightpen calibration offset byte
    AND   %11110000                 ;[49B6] Mask bits 7-4: X calibration offset
    RRCA                            ;[49B8] Rotate right to align X offset
    RRCA                            ;[49B9]
    RRCA                            ;[49BA] A = X calibration offset (now in bits 4-1)
    SUB   $28                       ;[49BB] Subtract X calibration baseline ($28 = 40)
    ADD   E                         ;[49BD] Add scaled raw X value
FLT2:
    LD    L,A                       ;[49BE] L = coordinate result
    LD    H,0                       ;[49BF] HL = result as 16-bit integer
    JP    INTFP                     ;[49C1] Convert to float in WRA1 and return
;
; FJOY: JOYSTICK(n) function - read joystick position.
; Returns a composite value encoding direction (bits 0-3) and fire button
; (bit 8 = high byte) as an integer float in WRA1.
; Joystick 0 uses port $7A; joystick 1 uses port $7B.
; The raw port byte has active-low direction bits ($00 = no input).
; After CPL, bits 3-0 = direction (indexed into JOYTAB for a 0-8 encoding).
; Bit 5 of the complemented byte = fire button (1=pressed).
; Return value encoding: fire-button in H (0 or 1), direction in L (0-8).
;   0=centre, 1=right, 2=left, 3=right+up, 4=up, 5=right+down, 6=down,
;   7=left+up, 8=left+down.
;
FJOY:
    CALL  FPINT                     ;[49C4] Convert WRA1 float -> integer in HL
    DEC   H                         ;[49C7] Test H is zero (high byte must be 0)
    INC   H                         ;[49C8]
    CALL  NZ,ERR_NUM_OUT_RANGE      ;[49C9] Argument > 255: out of range
    LD    C,$7A                     ;[49CC] C = $7A: port for joystick 0
    INC   L                         ;[49CE] Test L: INC then DEC to check if 0
    DEC   L                         ;[49CF]
    JR    Z,FJOYS1                  ;[49D0] L=0: joystick 0 selected
    DEC   L                         ;[49D2] L was 1: decrement to check exactly 1
    CALL  NZ,ERR_NUM_OUT_RANGE      ;[49D3] L non-zero: argument > 1, error
    INC   C                         ;[49D6] C = $7B: switch to joystick 1 port
FJOYS1:
    IN    A,(C)                     ;[49D7] Read joystick port ($7A or $7B)
    CPL                             ;[49D9] Complement: active-low -> active-high
    PUSH  AF                        ;[49DA] Save complemented byte (need it again for fire bit)
    AND   %00001111                 ;[49DB] Mask bits 3-0: direction nibble
    LD    E,A                       ;[49DD] E = direction index (0-15)
    LD    D,0                       ;[49DE] DE = direction index (16-bit for table lookup)
    LD    HL,JOYTAB                 ;[49E0] HL -> direction lookup table
    ADD   HL,DE                     ;[49E3] HL -> JOYTAB[direction]
    LD    L,(HL)                    ;[49E4] L = direction code (0-8 from table)
    LD    H,0                       ;[49E5] H = 0 initially (no fire)
    POP   AF                        ;[49E7] Restore complemented byte
    BIT   5,A                       ;[49E8] Test bit 5: fire button pressed?
    JR    Z,FJOYS2                  ;[49EA] No: H stays 0
    INC   H                         ;[49EC] Yes: H = 1 (fire button flag in high byte)
FJOYS2:
    JP    INTFP                     ;[49ED] Convert HL integer to float in WRA1 and return
;
; JOYTAB: direction lookup table for joystick bit patterns.
; Index 0-15 (4-bit direction nibble from port); value = direction code 0-8.
; 0=centre, 1=right, 2=left, 3=right+up(?), 4=up, 5=right+down,
; 6=down, 7=left+up(?), 8=left+down, other combinations -> 0.
;
JOYTAB:
    DB    0,8,4,0,6,7,5,0,2,1,3     ;[49F0] Direction codes for bit patterns 0-10
;
;------ VIDEO RESET ------
;
; EVRS: execute EXT VRESET - reset the video display to its default state.
; Reinitialises the 6845 CRTC chip from the D6845 table, reloads the display
; variables from VROM (the initial display parameter block), and sends a
; cursor-home code ($04) to the screen to clear any stray state.
; Used to recover from programs that leave the screen in a corrupted state.
;
EVRS:
    XOR   A                         ;[49FB] A = 0
    OUT   ($80),A                   ;[49FC] Write 0 to port $80: restore default bank/mode
    LD    BC,$FF7F                  ;[49FE] BC = bank-switch port
    OUT   (C),A                     ;[4A01] Write 0: ROM on (ensure extension ROM visible)
    LD    B,$10                     ;[4A03] B = 16: 6845 has 16 registers (R0-R15)
    LD    C,$87                     ;[4A05] C = $87: 6845 data port
    LD    HL,D6845                  ;[4A07] HL -> D6845 table: initial 6845 register values
EVRS1:
    OUT   ($86),A                   ;[4A0A] Write register number A to 6845 address port ($86)
    LD    E,(HL)                    ;[4A0C] E = value for this register from D6845 table
    OUT   (C),E                     ;[4A0D] Write value to 6845 data port ($87)
    INC   A                         ;[4A0F] Advance to next register number
    INC   HL                        ;[4A10] Advance to next D6845 table entry
    DJNZ  EVRS1                     ;[4A11] Repeat for all 16 registers
    LD    HL,VROM                   ;[4A13] HL -> VROM: initial display system variable block
    LD    DE,SYSVAR_CURSORX         ;[4A16] DE -> SYSVAR_CURSORX: start of display variable area
    LD    BC,MOVE                   ;[4A19] BC = MOVE: number of bytes to copy (display vars size)
    LDIR                            ;[4A1C] Restore display variables to power-on defaults
    LD    A,$04                     ;[4A1E] A = $04: cursor-home/display-reset VDU code
    RST   8                         ;[4A20] Send cursor-home to screen output
    RET                             ;[4A21]
;
;------ SOUND EFFECTS ------
;
; EXPL: execute EXT EXPLODE - plays a descending noise-like explosion sound.
; Generates 20 "frames" of square-wave noise using the Z80 R register as a
; pseudo-random delay source.  Each frame plays 100 on/off cycles at a pitch
; taken from EXPTAB (descending from 30 to 12).
; Port $84 = DAC output; port $80 bit 0 = speaker enable.
;
EXPL:
    LD    A,1                       ;[4A22] A = 1: speaker enable bit
    OUT   ($80),A                   ;[4A24] Port $80: enable speaker
    LD    HL,EXPTAB                 ;[4A26] HL -> EXPTAB: 20 descending pitch values
    LD    C,20                      ;[4A29] C = 20 frames to play
EEXPL1:
    LD    E,(HL)                    ;[4A2B] E = pitch value for this frame (from EXPTAB)
    INC   HL                        ;[4A2C] Advance table pointer to next pitch
    LD    B,100                     ;[4A2D] B = 100 on/off cycles per frame
EEXPL2:
    LD    A,E                       ;[4A2F] A = pitch (non-zero: DAC high)
    OUT   ($84),A                   ;[4A30] DAC high: speaker cone out
    LD    A,R                       ;[4A32] A = Z80 R register (pseudo-random refresh count)
EEXPL3:
    DEC   A                         ;[4A34] Decrement delay count
    JR    NZ,EEXPL3                 ;[4A35] Spin for ~R iterations (random half-period)
    XOR   A                         ;[4A37] A = 0: DAC low
    OUT   ($84),A                   ;[4A38] DAC low: speaker cone in
    LD    A,R                       ;[4A3A] A = new R value (differs from previous)
EEXPL4:
    DEC   A                         ;[4A3C] Decrement delay count
    JR    NZ,EEXPL4                 ;[4A3D] Spin for ~R iterations
    DJNZ  EEXPL2                    ;[4A3F] Repeat for all 100 cycles in this frame
    DEC   C                         ;[4A41] Decrement frame counter
    JR    NZ,EEXPL1                 ;[4A42] Play next frame at next (lower) pitch
    XOR   A                         ;[4A44] A = 0
    OUT   ($80),A                   ;[4A45] Port $80: disable speaker
    RET                             ;[4A47]
;
; EXPTAB: pitch values for EXPLODE. 20 entries, descending.
; Written directly to DAC port $84 as the high half of each square-wave cycle.
; Starts with a loud burst (63) then falls to 12 to simulate explosion decay.
;
EXPTAB:
    DB    30,63,62,61,60,58,56,53   ;[4A48] Initial burst then rapid descent
    DB    50,48,45,42,39,36,32,28   ;[4A50]
    DB    24,20,16,12               ;[4A58] Final low values
;
; EKLX: execute EXT KLAXON - two-tone police-siren sound.
; Uses EKLAX1 to repeatedly sweep the DAC from 0 to 63:
;   First pass:  DE=CYAN($96=150) repetitions, C=14 cycles/step (lower tone).
;   Second pass: DE=ADDQ($C8=200) repetitions, C=9 cycles/step (higher tone).
; CYAN and ADDQ are BASIC token constants reused here as convenient counts.
;
EKLX:
    LD    A,1                       ;[4A5C] A = 1: speaker enable
    OUT   ($80),A                   ;[4A5E] Enable speaker
    LD    DE,CYAN                   ;[4A60] DE = $96 (150): repeat count for low tone
    LD    C,14                      ;[4A63] C = 14: delay per step (lower pitch)
    CALL  EKLAX1                    ;[4A65] Play slow sawtooth sweep (lower tone)
    LD    DE,ADDQ                   ;[4A68] DE = $C8 (200): repeat count for high tone
    LD    C,9                       ;[4A6B] C = 9: delay per step (higher pitch)
    CALL  EKLAX1                    ;[4A6D] Play fast sawtooth sweep (higher tone)
    XOR   A                         ;[4A70] A = 0
    OUT   ($80),A                   ;[4A71] Disable speaker
    RET                             ;[4A73]
;
; EKLAX1: play one sawtooth sweep DE times.
; Sweeps DAC 0->63 repeatedly; each step waits C inner loop iterations.
;
EKLAX1:
    XOR   A                         ;[4A74] A = 0: start DAC at bottom of sweep
EKLAX2:
    OUT   ($84),A                   ;[4A75] Write current DAC value to speaker
    LD    B,C                       ;[4A77] B = C: inner delay count
EKLAX3:
    DJNZ  EKLAX3                    ;[4A78] Spin C times: controls pitch
    INC   A                         ;[4A7A] Advance to next DAC value
    CP    64                        ;[4A7B] Reached top of sweep?
    JR    C,EKLAX2                  ;[4A7D] No: continue
    DEC   DE                        ;[4A7F] Completed one 0-63 sweep: decrement count
    LD    A,D                       ;[4A80]
    OR    E                         ;[4A81] DE == 0?
    JR    NZ,EKLAX1                 ;[4A82] No: restart sweep
    RET                             ;[4A84]
;
; ELSR: execute EXT LASER - rising-pitch "pew" laser sound.
; Makes 70 passes; each plays a beep via _BEEP at pitch 63 but with
; DE delay increasing by 2 each pass (slowing the tone = rising pitch effect).
;
ELSR:
    LD    HL,5                      ;[4A85] HL = 5: initial half-period for _BEEP
    LD    DE,1                      ;[4A88] DE = 1: initial delay parameter
    LD    B,70                      ;[4A8B] B = 70: number of pitch steps
ELSR1:
    PUSH  BC                        ;[4A8D] Save pass counter
    PUSH  DE                        ;[4A8E] Save delay parameter
    PUSH  HL                        ;[4A8F] Save half-period
    LD    B,63                      ;[4A90] B = 63: pitch value for _BEEP (high freq)
    CALL  ELSR2                     ;[4A92] Play one beep at this pitch/delay
    POP   HL                        ;[4A95]
    POP   DE                        ;[4A96]
    POP   BC                        ;[4A97]
    INC   DE                        ;[4A98] DE += 2: progressively longer delay
    INC   DE                        ;[4A99]
    DJNZ  ELSR1                     ;[4A9A] Repeat for all 70 steps
    RET                             ;[4A9C]
;
; ELSR2: play one beep segment for LASER via the 48k ROM _BEEP routine.
;
ELSR2:
    PUSH  DE                        ;[4A9D] Push duration parameter (used by _BEEP)
    PUSH  HL                        ;[4A9E] Push wavelength parameter (used by _BEEP)
    LD    A,1                       ;[4A9F] A = 1: speaker enable
    OUT   ($80),A                   ;[4AA1] Enable speaker
    LD    A,B                       ;[4AA3] A = pitch (63)
    JP    _BEEP                     ;[4AA4] Jump to 48k ROM beep routine
;
; EZAP: execute EXT ZAP - "tinkling" crackle sound.
; 20 frames of 50 on/off cycles. Uses R register for random half-periods.
; The NOP in EZAP3 slightly skews the off-phase longer than on-phase,
; giving a characteristic asymmetric crackle different from EXPLODE.
;
EZAP:
    LD    A,1                       ;[4AA7] A = 1: speaker enable
    OUT   ($80),A                   ;[4AA9] Enable speaker
    LD    C,20                      ;[4AAB] C = 20 frames
EZAP1:
    LD    B,50                      ;[4AAD] B = 50 cycles per frame
EZAP2:
    XOR   A                         ;[4AAF] A = 0: DAC low (off phase)
    OUT   ($84),A                   ;[4AB0] DAC low
    LD    A,R                       ;[4AB2] A = R (pseudo-random delay)
EZAP3:
    DEC   A                         ;[4AB4] Decrement delay
    NOP                             ;[4AB5] Extra cycle: off-phase slightly longer
    JR    NZ,EZAP3                  ;[4AB6] Spin ~R iterations
    LD    A,63                      ;[4AB8] A = 63 (full DAC amplitude: on phase)
    OUT   ($84),A                   ;[4ABA] DAC high
    LD    A,R                       ;[4ABC] A = new R value
EZAP4:
    DEC   A                         ;[4ABE] Decrement delay
    JR    NZ,EZAP4                  ;[4ABF] Spin ~R iterations
    DJNZ  EZAP2                     ;[4AC1] Repeat 50 cycles
    DEC   C                         ;[4AC3] Decrement frame counter
    JR    NZ,EZAP1                  ;[4AC4] Play next frame
    XOR   A                         ;[4AC6] A = 0
    OUT   ($80),A                   ;[4AC7] Disable speaker
    RET                             ;[4AC9]
;
;------ CIRCLE ALGORITHM ------
;
; ECIR: execute EXT CIRCLE x, y, r [, f]
; Draws a circle (or filled disc) centred at (x,y) with radius r.
; Optional argument f (0=outline, 1=filled).
;
; Uses a Bresenham integer circle algorithm. All coordinates are signed
; 16-bit integers. SYSVAR_STRBUF is used as a 24-byte working area:
;   +0       = Y coordinate (stored by FILRAM)
;   +1       = fill flag (0=outline, 1=filled)
;   +2       = segment/scratch
;   +3,+4    = centre X (low, high)
;   +5,+6    = centre Y (low, high)
;   +7,+8    = radius (low, high)
;   +9..+16  = 4 pairs of signed (low,high) X/Y offsets for 4 octants
;   +17..+22 = SIG output slots and screen Y accumulator
;
ECIR:
    RST   $18                       ;[4ACA] Evaluate expression -> HL (arg: fill flag f)
    INC   DE                        ;[4ACB] Skip separator
    PUSH  HL                        ;[4ACC] Stack: f
    RST   $18                       ;[4ACD] Evaluate expression -> HL (arg: radius r)
    INC   DE                        ;[4ACE] Skip separator
    PUSH  HL                        ;[4ACF] Stack: f, r
    RST   $18                       ;[4AD0] Evaluate expression -> HL (arg: centre Y)
    INC   DE                        ;[4AD1] Skip separator
    PUSH  HL                        ;[4AD2] Stack: f, r, y
    RST   $18                       ;[4AD3] Evaluate expression -> HL (arg: centre X)
VQ3:
    PUSH  HL                        ;[4AD4] Stack: f, r, y, x
    ; Zero the 14-byte working area at STRBUF+9..+22
    LD    B,14                      ;[4AD5] B = 14 bytes to clear
    LD    HL,SYSVAR_STRBUF+9        ;[4AD7] HL -> STRBUF+9
CLL1:
    LD    (HL),0                    ;[4ADA] Zero one byte
    INC   HL                        ;[4ADC]
    DJNZ  CLL1                      ;[4ADD] Repeat for all 14 bytes
    ;
    ; Pop and validate radius r -> STRBUF+7,+8
    LD    DE,SYSVAR_STRBUF+8        ;[4ADF] DE -> STRBUF+8 (radius high byte slot)
    POP   HL                        ;[4AE2] HL = x (centre X)
    BIT   7,H                       ;[4AE3] X negative?
    JP    NZ,ERR_NUM_OUT_RANGE      ;[4AE5] Yes: error
    LD    A,H                       ;[4AE8]
    AND   $E0                       ;[4AE9] Upper 3 bits of X high byte must be clear
    JP    NZ,ERR_NUM_OUT_RANGE      ;[4AEB] X too large
    LD    A,H                       ;[4AEE]
    LD    (DE),A                    ;[4AEF] Store X high byte at STRBUF+8
    DEC   DE                        ;[4AF0] DE -> STRBUF+7
    LD    A,L                       ;[4AF1]
    LD    (DE),A                    ;[4AF2] Store X low byte at STRBUF+7
    ; Pop and validate centre Y -> STRBUF+5,+6 (signed 13-bit range check)
CLL2:
    DEC   DE                        ;[4AF3] DE -> STRBUF+6
    POP   HL                        ;[4AF4] HL = y (centre Y)
    BIT   7,H                       ;[4AF5] Sign bit of Y
    LD    A,H                       ;[4AF7]
    JR    NZ,CLL3                   ;[4AF8] Negative: use CPL range check
    AND   %11100000                 ;[4AFA] Positive: bits 7-5 must be 0
    JP    NZ,ERR_NUM_OUT_RANGE      ;[4AFC]
    JP    EX1                       ;[4AFF]
CLL3:
    CPL                             ;[4B02] ~H (complement for 2's complement check)
    ADD   1                         ;[4B03] -H
    AND   %01100000                 ;[4B05] Magnitude bits 6-5 must be 0
    JP    NZ,ERR_NUM_OUT_RANGE      ;[4B07]
EX1:
    LD    A,H                       ;[4B0A]
    LD    (DE),A                    ;[4B0B] Store Y high byte at STRBUF+6
    DEC   DE                        ;[4B0C] DE -> STRBUF+5
    LD    A,L                       ;[4B0D]
    LD    (DE),A                    ;[4B0E] Store Y low byte at STRBUF+5
    DEC   DE                        ;[4B0F] DE -> STRBUF+4
    ; Pop and validate centre X -> STRBUF+3,+4 (same signed 13-bit range check)
    POP   HL                        ;[4B10] HL = r (radius)
    BIT   7,H                       ;[4B11] Sign bit
    LD    A,H                       ;[4B13]
    JR    NZ,CLL4                   ;[4B14]
    AND   %11100000                 ;[4B16]
    JP    NZ,ERR_NUM_OUT_RANGE      ;[4B18]
    JP    CLL5                      ;[4B1B]
CLL4:
    CPL                             ;[4B1E]
    ADD   1                         ;[4B1F]
    AND   %01100000                 ;[4B21]
    JP    NZ,ERR_NUM_OUT_RANGE      ;[4B23]
CLL5:
    LD    A,H                       ;[4B26]
    LD    (DE),A                    ;[4B27] Store r high byte at STRBUF+4
    DEC   DE                        ;[4B28] DE -> STRBUF+3
    LD    A,L                       ;[4B29]
    LD    (DE),A                    ;[4B2A] Store r low byte at STRBUF+3
    DEC   DE                        ;[4B2B] DE -> STRBUF+2
    ; Pop and validate fill flag f -> STRBUF+1 (must be 0 or 1)
    POP   HL                        ;[4B2C] HL = f (fill flag)
    LD    A,H                       ;[4B2D]
    AND   A                         ;[4B2E] H must be 0
    JP    NZ,ERR_NUM_OUT_RANGE      ;[4B2F]
    LD    A,L                       ;[4B32]
    AND   %11111110                 ;[4B33] L must be 0 or 1
    JP    NZ,ERR_NUM_OUT_RANGE      ;[4B35]
CHI0:
    DEC   DE                        ;[4B38] DE -> STRBUF+1
    LD    A,L                       ;[4B39] A = fill flag
    LD    (DE),A                    ;[4B3A] Store fill flag at STRBUF+1
    LD    IX,0                      ;[4B3B] IX = 0 (X offset, starts at 0)
    LD    IY,(SYSVAR_STRBUF+7)      ;[4B3F] IY = radius (16-bit from STRBUF+7)
    PUSH  IY                        ;[4B43] Push radius twice
    PUSH  IY                        ;[4B45]
    POP   BC                        ;[4B47] BC = radius
    POP   DE                        ;[4B48] DE = radius
    XOR   A                         ;[4B49] Clear carry
    OR    D                         ;[4B4A] Is radius zero?
    OR    E                         ;[4B4B]
    JP    Z,EXU2                    ;[4B4C] Zero radius: plot single point
    ; Initial Bresenham values: BC = 1-2r, HL = 1-r, DE = 1
    SLA   C                         ;[4B4F] BC = 2*r
    RL    B                         ;[4B51]
    XOR   A                         ;[4B53] Clear carry
    LD    H,A                       ;[4B54] HL = 0
    LD    L,1                       ;[4B55] HL = 1
    SBC   HL,BC                     ;[4B57] HL = 1 - 2r (decision variable)
    LD    C,L                       ;[4B59] BC = 1 - 2r
    LD    B,H                       ;[4B5A]
    ADD   HL,DE                     ;[4B5B] HL = (1-2r) + r = 1-r (error term)
    LD    DE,1                      ;[4B5C] DE = 1 (initial step)
    PUSH  HL                        ;[4B5F] Push error term
    PUSH  DE                        ;[4B60] Push step
    PUSH  BC                        ;[4B61] Push decision variable
;
; MLE: main Bresenham circle loop. Terminates when IX > IY (past 45 degrees).
; Each iteration plots 8 symmetric octant points, then updates state.
;
MLE:
    XOR   A                         ;[4B62] Clear carry for SBC
    PUSH  IX                        ;[4B63]
    POP   DE                        ;[4B65] DE = IX
    PUSH  IY                        ;[4B66]
    POP   HL                        ;[4B68] HL = IY
    SBC   HL,DE                     ;[4B69] HL = IY - IX
    JP    C,EXU                     ;[4B6B] IX > IY: circle complete
    ; Store +IX,-IX,+IY,-IY into STRBUF+9..+16
    LD    HL,SYSVAR_STRBUF+9        ;[4B6E] HL -> STRBUF+9
    PUSH  IX                        ;[4B71]
    POP   DE                        ;[4B73] DE = IX
    LD    (HL),E                    ;[4B74] STRBUF+9  = +IX low
    INC   HL                        ;[4B75]
    LD    (HL),D                    ;[4B76] STRBUF+10 = +IX high
    INC   HL                        ;[4B77]
    LD    A,E                       ;[4B78]
    CPL                             ;[4B79]
    ADD   1                         ;[4B7A] -IX low (2's complement)
    LD    (HL),A                    ;[4B7C] STRBUF+11 = -IX low
    INC   HL                        ;[4B7D]
    LD    A,D                       ;[4B7E]
    CPL                             ;[4B7F]
    ADC   0                         ;[4B80] -IX high (with carry)
    LD    (HL),A                    ;[4B82] STRBUF+12 = -IX high
    INC   HL                        ;[4B83]
    PUSH  IY                        ;[4B84]
    POP   DE                        ;[4B86] DE = IY
    LD    (HL),E                    ;[4B87] STRBUF+13 = +IY low
    INC   HL                        ;[4B88]
    LD    (HL),D                    ;[4B89] STRBUF+14 = +IY high
    INC   HL                        ;[4B8A]
    LD    A,E                       ;[4B8B]
    CPL                             ;[4B8C]
    ADD   1                         ;[4B8D] -IY low
    LD    (HL),A                    ;[4B8F] STRBUF+15 = -IY low
    INC   HL                        ;[4B90]
    LD    A,D                       ;[4B91]
    CPL                             ;[4B92]
    ADC   0                         ;[4B93] -IY high
    LD    (HL),A                    ;[4B95] STRBUF+16 = -IY high
    ; Plot octant pair A: (cx+IX, cy+IY) and (cx+IX, cy-IY)
    LD    HL,SYSVAR_STRBUF+3        ;[4B96] HL -> cx
    LD    DE,SYSVAR_STRBUF+9        ;[4B99] DE -> +IX
    LD    BC,SYSVAR_STRBUF+17       ;[4B9C] BC -> output
    CALL  SIG                       ;[4B9F] STRBUF+17 = cx + IX
    DEC   HL                        ;[4BA2] HL -> cy
    INC   BC                        ;[4BA3]
    INC   DE                        ;[4BA4] DE -> +IY
    CALL  SIG                       ;[4BA5] STRBUF+18 = cy + IY
    INC   HL                        ;[4BA8] HL -> cx
    INC   BC                        ;[4BA9]
    INC   DE                        ;[4BAA] DE -> -IX
    CALL  SIG                       ;[4BAB] STRBUF+20 = cx - IX
    PUSH  HL                        ;[4BAE]
    PUSH  DE                        ;[4BAF]
    PUSH  BC                        ;[4BB0]
    CALL  SCRNT                     ;[4BB1] Plot (cx+IX, cy+IY)
    POP   BC                        ;[4BB4]
    POP   DE                        ;[4BB5]
    POP   HL                        ;[4BB6]
    DEC   HL                        ;[4BB7] HL -> cy
    DEC   BC                        ;[4BB8]
    INC   DE                        ;[4BB9] DE -> -IY
    CALL  SIG                       ;[4BBA] cy - IY
    CALL  SCRNT                     ;[4BBD] Plot (cx+IX, cy-IY)
    ; Plot octant pair B: (cx+IY, cy+IX) and (cx+IY, cy-IX)
    LD    HL,SYSVAR_STRBUF+3        ;[4BC0] HL -> cx
    LD    DE,SYSVAR_STRBUF+13       ;[4BC3] DE -> +IY (swapped to X axis)
    LD    BC,SYSVAR_STRBUF+17       ;[4BC6] BC -> output
    CALL  SIG                       ;[4BC9] STRBUF+17 = cx + IY
    DEC   HL                        ;[4BCC] HL -> cy
    INC   DE                        ;[4BCD] DE -> -IY
    INC   BC                        ;[4BCE]
    CALL  SIG                       ;[4BCF] STRBUF+18 = cy - IY
    LD    DE,SYSVAR_STRBUF+9        ;[4BD2] DE -> +IX (swapped to Y axis)
    INC   HL                        ;[4BD5] HL -> cx
    INC   BC                        ;[4BD6]
    CALL  SIG                       ;[4BD7] STRBUF+20 = cx + IX
    PUSH  HL                        ;[4BDA]
    PUSH  DE                        ;[4BDB]
    PUSH  BC                        ;[4BDC]
    CALL  SCRNT                     ;[4BDD] Plot (cx+IY, cy+IX)
    POP   BC                        ;[4BE0]
    POP   DE                        ;[4BE1]
    POP   HL                        ;[4BE2]
    DEC   HL                        ;[4BE3] HL -> cy
    INC   DE                        ;[4BE4] DE -> -IX
    DEC   BC                        ;[4BE5]
    CALL  SIG                       ;[4BE6] cy - IX
    CALL  SCRNT                     ;[4BE9] Plot (cx+IY, cy-IX)
    ; Update Bresenham state
    POP   BC                        ;[4BEC] BC = decision variable
    POP   DE                        ;[4BED] DE = step
    POP   HL                        ;[4BEE] HL = error term
    BIT   7,H                       ;[4BEF] Error negative?
    JR    Z,CGAM1                   ;[4BF1] Non-negative: IY must decrease
    INC   BC                        ;[4BF3]
    INC   BC                        ;[4BF4] BC += 2 (X-only step)
    ADD   HL,DE                     ;[4BF5] error += step
    JR    CGAM2                     ;[4BF6]
CGAM1:
    DEC   IY                        ;[4BF8] IY -= 1 (Y offset shrinks)
    INC   BC                        ;[4BFA]
    INC   BC                        ;[4BFB]
    INC   BC                        ;[4BFC]
    INC   BC                        ;[4BFD] BC += 4
    ADD   HL,BC                     ;[4BFE] error += decision
CGAM2:
    INC   DE                        ;[4BFF]
    INC   DE                        ;[4C00] DE += 2 (next step = 2*IX+1)
    INC   IX                        ;[4C01] IX += 1
    PUSH  HL                        ;[4C03]
    PUSH  DE                        ;[4C04]
    PUSH  BC                        ;[4C05]
    JP    MLE                       ;[4C06] Next iteration
; EXU: exit the MLE circle loop (IX > IY: all octants covered).
; Pops the three Bresenham state values and returns.
;
EXU:
    POP   BC                        ;[4C09] Discard decision variable
    POP   DE                        ;[4C0A] Discard step
    POP   HL                        ;[4C0B] Discard error term
    RET                             ;[4C0C]
;
; EXU2: radius=0 special case - plot a single point at the centre.
; Reads centre Y (STRBUF+5,+6) and centre X (STRBUF+3,+4) and calls
; SUB_PLOT3 if both coordinates are within the visible screen area.
;
EXU2:
    LD    DE,SYSVAR_STRBUF+6        ;[4C0D] DE -> STRBUF+6 (cy high byte)
    LD    A,(DE)                    ;[4C10] A = cy high byte
    AND   A                         ;[4C11] Non-zero: Y out of range
    RET   NZ                        ;[4C12]
    DEC   DE                        ;[4C13] DE -> STRBUF+5 (cy low byte)
    LD    A,(DE)                    ;[4C14] A = cy low
    CP    252                       ;[4C15] cy >= 252 (off screen)?
    RET   NC                        ;[4C17] Yes: skip
    EXX                             ;[4C18]
    LD    H,A                       ;[4C19] H' = cy (Y for SUB_PLOT3)
    EXX                             ;[4C1A]
    DEC   DE                        ;[4C1B] DE -> STRBUF+4 (cx high byte)
    LD    A,(DE)                    ;[4C1C] A = cx high byte
    AND   A                         ;[4C1D] Non-zero: X out of range
    RET   NZ                        ;[4C1E]
    DEC   DE                        ;[4C1F] DE -> STRBUF+3 (cx low byte)
    LD    A,(DE)                    ;[4C20] A = cx low
    LD    H,A                       ;[4C21] H = cx (X for SUB_PLOT3)
    CALL  SUB_PLOT3                 ;[4C22] Plot pixel at (cx, cy)
    RET                             ;[4C25]
;
; SIG: 16-bit signed add for circle coordinate computation.
; Adds 2-byte value at (DE) to 2-byte value at (HL), stores at (BC).
; All three pointers are advanced by 1 on return; callers use INC to
; give net +2 advance per coordinate pair.
;
SIG:
    LD    A,(DE)                    ;[4C26] A = offset low byte
    ADD   (HL)                      ;[4C27] A += centre low byte
    LD    (BC),A                    ;[4C28] Store result low byte
    INC   HL                        ;[4C29] Advance to high bytes
    INC   BC                        ;[4C2A]
    INC   DE                        ;[4C2B]
    LD    A,(DE)                    ;[4C2C] A = offset high byte
    ADC   (HL)                      ;[4C2D] A += centre high byte (with carry)
    LD    (BC),A                    ;[4C2E] Store result high byte
    RET                             ;[4C2F]
;
; SCRNT: screen-range-check and pixel-plot for one circle point.
; Reads computed screen Y from STRBUF+22 (high), STRBUF+21 (low).
; Reads computed X1 from STRBUF+18,+17 and X2 from STRBUF+20,+19.
; Validates each coordinate is within the screen, then plots via SUB_PLOT3.
; If fill flag (STRBUF+1) is set and X1 != X2, fills the horizontal run
; from X2 to X1 via FILRAM.
;
SCRNT:
    LD    DE,SYSVAR_STRBUF+22       ;[4C30] DE -> STRBUF+22 (Y high)
    LD    A,(DE)                    ;[4C33] A = Y high byte
    AND   A                         ;[4C34] Non-zero: Y > 255, off screen
    JR    NZ,NPT0                   ;[4C35] Skip
    DEC   DE                        ;[4C37] DE -> STRBUF+21 (Y low)
    LD    A,(DE)                    ;[4C38] A = Y low
    CP    252                       ;[4C39] Y >= 252 (off bottom)?
    JP    NC,NPT0                   ;[4C3B] Skip
    ; Check X1 (STRBUF+18,+17): sign bit must be clear (non-negative)
    LD    HL,SYSVAR_STRBUF+18       ;[4C3E] HL -> STRBUF+18 (X1 high)
    LD    A,(HL)                    ;[4C41] A = X1 high
    AND   A                         ;[4C42]
    JP    M,NPT0                    ;[4C43] Negative: X1 off left, skip all
    LD    HL,SYSVAR_STRBUF+20       ;[4C46] HL -> STRBUF+20 (X2 high)
    LD    A,(HL)                    ;[4C49]
    LD    B,0                       ;[4C4A] B = 0 (X1 placeholder if X1 not plotted)
    AND   A                         ;[4C4C]
    JP    M,QFR1                    ;[4C4D] X2 negative: skip X2, try X1
    JR    NZ,NPT0                   ;[4C50] X2 high non-zero: X2 off right, skip both
    ; X2 in range: read and plot X2
    DEC   HL                        ;[4C52] HL -> STRBUF+19 (X2 low)
    LD    A,(HL)                    ;[4C53] A = X2 low (screen X)
    LD    B,A                       ;[4C54] B = X2 (save for fill range)
    LD    H,A                       ;[4C55] H = X2 (X coord for SUB_PLOT3)
    LD    A,(DE)                    ;[4C56] A = Y low (from STRBUF+21)
    EXX                             ;[4C57]
    LD    H,A                       ;[4C58] H' = Y
    EXX                             ;[4C59]
    CALL  SUB_PLOT3                 ;[4C5A] Plot pixel at (X2, Y)
QFR1:
    ; Try plotting X1
    LD    HL,SYSVAR_STRBUF+18       ;[4C5D] HL -> STRBUF+18 (X1 high)
    LD    A,(HL)                    ;[4C60]
    LD    C,255                     ;[4C61] C = 255 (sentinel: no valid X1)
    AND   A                         ;[4C63]
    JR    NZ,QFR2                   ;[4C64] X1 high non-zero: skip X1
    DEC   HL                        ;[4C66] HL -> STRBUF+17 (X1 low)
    LD    A,(HL)                    ;[4C67]
    LD    C,A                       ;[4C68] C = X1 low (save for fill range)
    LD    H,A                       ;[4C69] H = X1 (X coord for SUB_PLOT3)
    LD    A,(DE)                    ;[4C6A] A = Y
    EXX                             ;[4C6B]
    LD    H,A                       ;[4C6C] H' = Y
    EXX                             ;[4C6D]
    CALL  SUB_PLOT3                 ;[4C6E] Plot pixel at (X2, Y)
QFR2:
    ; Check fill flag; if set and X1 != X2, fill horizontal run
    LD    HL,SYSVAR_STRBUF+1        ;[4C71] HL -> STRBUF+1 (fill flag)
    LD    A,(HL)                    ;[4C74]
    AND   A                         ;[4C75] Fill flag zero?
    JR    Z,QFR3                    ;[4C76] No fill: done
    LD    A,B                       ;[4C78] A = X2
    CP    C                         ;[4C79] X2 == X1?
    JR    Z,QFR3                    ;[4C7A] Degenerate span: skip fill
    LD    HL,SYSVAR_STRBUF+21       ;[4C7C] HL -> Y low byte
    LD    A,(HL)                    ;[4C7F] A = Y coordinate
    CALL  FILRAM                    ;[4C80] Fill horizontal run from X2(B) to X1(C) at Y=A
QFR3:
NPT0:
    RET                             ;[4C83]
;
; FILRAM: fill a horizontal pixel run between column B and column C at row A.
; The Lynx screen is 256 pixels wide, 1 bit/pixel, 32 bytes/row.
; Computes byte addresses for B (X2=right) and C (X1=left), builds partial-byte
; edge masks, then writes full bytes for the middle span.
; SYSVAR_OUTB(HL=byte_addr, C=mask, H'=Y) writes one masked byte to all planes.
;
FILRAM:
    LD    DE,SYSVAR_STRBUF          ;[4C84] DE -> STRBUF+0
    LD    (DE),A                    ;[4C87] Save Y coordinate at STRBUF+0
    LD    L,A                       ;[4C88]
    LD    H,0                       ;[4C89] HL = Y
    ADD   HL,HL                     ;[4C8B] HL = Y*2
    ADD   HL,HL                     ;[4C8C] HL = Y*4
    ADD   HL,HL                     ;[4C8D] HL = Y*8
    ADD   HL,HL                     ;[4C8E] HL = Y*16
    ADD   HL,HL                     ;[4C8F] HL = Y*32 (row byte offset)
    PUSH  HL                        ;[4C90] Save row base
    ; Compute byte address of B (X2, rightmost pixel): row + (B>>3)
    LD    E,B                       ;[4C91] E = X2
    SRL   E                         ;[4C92]
    SRL   E                         ;[4C94]
    SRL   E                         ;[4C96] E = X2 >> 3 (byte column)
    LD    D,0                       ;[4C98]
    ADD   HL,DE                     ;[4C9A] HL = row + (X2>>3) = end byte addr
    EX    DE,HL                     ;[4C9B] DE = end byte address
    POP   HL                        ;[4C9C] HL = row base
    PUSH  DE                        ;[4C9D] Save end byte address
    ; Compute byte address of C (X1, leftmost pixel): row + (C>>3)
    LD    E,C                       ;[4C9E] E = X1
    SRL   E                         ;[4C9F]
    SRL   E                         ;[4CA1]
    SRL   E                         ;[4CA3] E = X1 >> 3 (byte column)
    LD    D,0                       ;[4CA5]
    ADD   HL,DE                     ;[4CA7] HL = row + (X1>>3) = start byte addr
    ; Build right-edge mask D = $FF >> (B & 7): bits from X2%8 down to bit 0
    LD    A,B                       ;[4CA8] A = X2
    LD    DE,$FF80                  ;[4CA9] D = $FF (full mask); E = $80 (MSB for left mask)
    AND   %00000111                 ;[4CAC] A = X2 & 7 (bit position)
    JR    Z,QQ4                     ;[4CAE] Bit 0: D stays $FF
YY1:
    SRL   D                         ;[4CB0] D >>= 1 (shift right: remove high bits)
    DEC   A                         ;[4CB2]
    JR    NZ,YY1                    ;[4CB3] Repeat A times
QQ4:
    ; Build left-edge mask E: arithmetic-shift $80 right by (C & 7) positions
    LD    A,C                       ;[4CB5] A = X1
    AND   %00000111                 ;[4CB6] A = X1 & 7
    JR    Z,QQ6                     ;[4CB8] Bit 0: E stays $80
QQ5:
    SRA   E                         ;[4CBA] E >>= 1 arithmetic (fills from left: becomes $C0, $E0...)
    DEC   A                         ;[4CBC]
    JR    NZ,QQ5                    ;[4CBD] Repeat A times
QQ6:
    ; HL = start byte addr; stack top = end byte addr; D = right mask; E = left mask
    POP   BC                        ;[4CBF] BC = end byte address
    PUSH  HL                        ;[4CC0] Save start byte addr
    PUSH  BC                        ;[4CC1] Save end byte addr
    XOR   A                         ;[4CC2] Clear carry
    SBC   HL,BC                     ;[4CC3] HL = start - end (negative = multi-byte)
    LD    B,L                       ;[4CC5] B = -(byte span) as byte count
    LD    HL,SYSVAR_STRBUF          ;[4CC6] HL -> STRBUF+0 (Y)
    LD    A,(HL)                    ;[4CC9] A = Y
    EXX                             ;[4CCA]
    LD    H,A                       ;[4CCB] H' = Y (for SYSVAR_OUTB)
    EXX                             ;[4CCC]
    JP    Z,EQZ                     ;[4CCD] start == end: single-byte fill
    JP    M,FEXU                    ;[4CD0] start > end: invalid range, abort
    ; Multi-byte: write rightmost (X2 side) partial byte first
    LD    A,D                       ;[4CD3] A = right mask D
    CPL                             ;[4CD4] Complement for OUTB mask convention
    LD    C,A                       ;[4CD5] C = ~D (OUTB mask)
    CPL                             ;[4CD6] A = D restored (pixel byte)
    POP   HL                        ;[4CD7] HL = end byte address (X2 side)
    LD    D,B                       ;[4CD8] D = B (byte-span counter)
    PUSH  DE                        ;[4CD9] Push (D=count, E=left mask) for later
    CALL  SYSVAR_OUTB               ;[4CDA] Write right partial byte at X2 side
    ; Write leftmost (X1 side) partial byte
    LD    HL,SYSVAR_STRBUF          ;[4CDD]
    LD    A,(HL)                    ;[4CE0] A = Y
    EXX                             ;[4CE1]
    LD    H,A                       ;[4CE2] H' = Y
    EXX                             ;[4CE3]
    POP   DE                        ;[4CE4] Restore (D=count, E=left mask)
    LD    A,E                       ;[4CE5] A = left mask E
    CPL                             ;[4CE6]
    LD    C,A                       ;[4CE7] C = ~E (OUTB mask)
    CPL                             ;[4CE8] A = E restored
    POP   HL                        ;[4CE9] HL = start byte address (X1 side)
    PUSH  HL                        ;[4CEA] Save for middle-byte loop
    PUSH  DE                        ;[4CEB] Save (D=count, E=left mask)
    CALL  SYSVAR_OUTB               ;[4CEC] Write left partial byte at X1 side
    ; Write middle bytes ($FF = all pixels on)
    LD    A,$FF                     ;[4CEF] A = full pixel byte
    POP   BC                        ;[4CF1] BC: B = -(byte count)
    LD    C,0                       ;[4CF2] C = 0 (mask complement = all bits changeable)
    POP   HL                        ;[4CF4] HL = start byte address
FILL_LOOP:
    DEC   HL                        ;[4CF5] Move right (toward X2) in memory
    LD    DE,SYSVAR_STRBUF          ;[4CF6]
    LD    A,(DE)                    ;[4CF9] A = Y
    EXX                             ;[4CFA]
    LD    H,A                       ;[4CFB] H' = Y
    EXX                             ;[4CFC]
    LD    A,$FF                     ;[4CFD] A = full byte ($FF)
    DEC   B                         ;[4CFF] B-- (loop counter)
    JR    Z,EQZ1                    ;[4D00] B=0: all middle bytes done
    PUSH  BC                        ;[4D02]
    CALL  SYSVAR_OUTB               ;[4D03] Write middle byte (all pixels set)
    POP   BC                        ;[4D06]
    JP    FILL_LOOP                 ;[4D07] Next middle byte
;
; EQZ: single-byte fill (start byte == end byte: run spans < 1 byte).
; Combines left-edge (E) and right-edge (D) masks with AND to get the run mask.
;
EQZ:
    LD    A,E                       ;[4D0A] A = left mask
    AND   D                         ;[4D0B] A = E AND D = exact run mask
    CPL                             ;[4D0C] Complement for OUTB convention
    LD    C,A                       ;[4D0D] C = ~(E AND D)
    CPL                             ;[4D0E] A = E AND D (pixel byte)
    POP   HL                        ;[4D0F] Discard one stacked address
    POP   HL                        ;[4D10] HL = start/end byte address
    CALL  SYSVAR_OUTB               ;[4D11] Write single partial byte
EQZ1:
    RET                             ;[4D14]
;
; FEXU: inverted fill range (start > end), nothing to do.
; Discards two stacked addresses and returns.
;
FEXU:
    POP   HL                        ;[4D15] Discard stacked address
    POP   HL                        ;[4D16] Discard stacked address
    RET                             ;[4D17]
;
;------ TRIANGLE ALGORITHM ------
;
; ETRI: execute EXT TRIANGLE x1,y1, x2,y2, x3,y3
; Draws a filled triangle (or outline) with vertices at three pixel coordinates.
; The algorithm is described as a rewrite of Dec'83; it uses a scan-line fill
; approach: sort vertices by Y, then fill horizontal spans between the three
; pairs of edges using FILRAM.
;
; STRBUF layout used by TRIANGLE:
;   +1..+16  = 3 vertices as (x_low, y_low) pairs, stored at +1,+2 / +3,+4 / etc.
;              (after argument decode into STRBUF+16 downward, 2 bytes per coord,
;               6 pairs = 3 vertices × (x,y))
;   +17..+22 = working area for edge interpolation state
;   +1..+6   = 3×2-byte x-coordinate workspace
;   +9..+11  = per-scan-line x-left/x-right pair for FILRAM
;
ETRI:
    RST     $18                     ;[4D18] Evaluate expression -> HL (x1)
    INC     DE                      ;[4D19] Skip separator
    PUSH    HL                      ;[4D1A] Stack: x1
    RST     $18                     ;[4D1B] Evaluate expression -> HL (y1)
    INC     DE                      ;[4D1C]
    PUSH    HL                      ;[4D1D] Stack: x1, y1
    RST     $18                     ;[4D1E] Evaluate -> HL (x2)
    INC     DE                      ;[4D1F]
    PUSH    HL                      ;[4D20] Stack: x1, y1, x2
    RST     $18                     ;[4D21] Evaluate -> HL (y2)
    INC     DE                      ;[4D22]
    PUSH    HL                      ;[4D23] Stack: x1, y1, x2, y2
    RST     $18                     ;[4D24] Evaluate -> HL (x3)
    INC     DE                      ;[4D25]
    PUSH    HL                      ;[4D26] Stack: x1, y1, x2, y2, x3
    RST     $18                     ;[4D27] Evaluate -> HL (y3)
    INC     DE                      ;[4D28]
    PUSH    HL                      ;[4D29] Stack: x1..y3 (6 values)
    ; Decode 3 vertices into STRBUF: store as (y_low, x_low) pairs working
    ; downward from STRBUF+16.  C = running max-Y (for finding lowest vertex).
    LD      C,0                     ;[4D2A] C = 0 (min Y seen so far, will become max)
    LD      DE,SYSVAR_STRBUF+16     ;[4D2C] DE -> STRBUF+16 (start of vertex store)
    LD      B,3                     ;[4D2F] B = 3 vertices to process
LL1:
    ; Pop Y coordinate; validate non-negative and < 252 (screen height)
    POP     HL                      ;[4D31] HL = x (popped first due to stack reversal)
    BIT     7,H                     ;[4D32] X negative?
    JP      NZ,ERR_NUM_OUT_RANGE    ;[4D34] Yes: error
    LD      A,L                     ;[4D37] A = x low byte
    CP      252                     ;[4D38] x >= 252 (off screen)?
    JP      NC,ERR_NUM_OUT_RANGE    ;[4D3A] Yes: error
    LD      (DE),A                  ;[4D3D] Store x at STRBUF+16,+14,+12
    CP      C                       ;[4D3E] Is this x > current max?
    JR      C,LL3                   ;[4D3F] No: keep current max
    LD      C,A                     ;[4D41] C = new max x (used as Y-max later in sort)
LL3:
    DEC     DE                      ;[4D42] Advance to next slot
    ; Pop X coordinate; validate non-negative
    POP     HL                      ;[4D43] HL = y (due to stack order)
    BIT     7,H                     ;[4D44] Y negative?
    JP      NZ,ERR_NUM_OUT_RANGE    ;[4D46] Yes: error
    LD      A,L                     ;[4D49] A = y low byte
    LD      (DE),A                  ;[4D4A] Store y at STRBUF+15,+13,+11
    DEC     DE                      ;[4D4B] Advance to next slot
    DJNZ    LL1                     ;[4D4C] Process next vertex
    ;
    ; Find the vertex with the maximum Y value (lowest on screen) using
    ; a 3-way scan of STRBUF+17,+15,+13 (the y-bytes).
    ; Result in E = vertex index (1..3) of the bottom vertex.
    LD      A,C                     ;[4D4E] A = max-Y accumulated above
    LD      HL,SYSVAR_STRBUF+17     ;[4D4F] HL -> one past first y-byte
    LD      B,$03                   ;[4D52] B = 3 vertices to scan
    ; Scan loop: step HL down by 2 each time, compare y to find bottom vertex
TBD_SCAN1:
    DEC     HL                      ;[4D54] HL -> y byte of this vertex
    CP      (HL)                    ;[4D55] Is max-Y == this y?
    JR      NZ,TBD1                 ;[4D56] No: not this vertex
    LD      E,B                     ;[4D58] E = B (vertex index 3,2,1)
TBD1:
    DEC     HL                      ;[4D59] HL -> x byte of this vertex (skip)
    DJNZ    TBD_SCAN1               ;[4D5A] Repeat for all 3 vertices
    ; E now holds index of bottom vertex.  Store index at STRBUF+10 (sort key).
    DEC     HL                      ;[4D5C] HL -> STRBUF+10
    LD      (HL),E                  ;[4D5D] Store bottom vertex index at STRBUF+10
    ;
    ; Find the vertex with the minimum Y value (topmost on screen).
    ; C=$FD = 253 (above any valid Y); E = found vertex index.
    LD      B,$03                   ;[4D5E] B = 3 vertices
    LD      HL,SYSVAR_STRBUF+17     ;[4D60] HL -> past first y-byte
    LD      C,$FD                   ;[4D63] C = 253 (sentinel: above all valid Y values)
TBD2:
    DEC     HL                      ;[4D65] HL -> y byte
    LD      A,(HL)                  ;[4D66] A = this y
    CP      C                       ;[4D67] Is A == current min?
    JR      Z,TBD3                  ;[4D68] Equal: record as top vertex
    JR      NC,TBD4                 ;[4D6A] A >= C: not smaller, skip
    LD      C,A                     ;[4D6C] New minimum Y found: update C
TBD3:
    LD      E,B                     ;[4D6D] E = vertex index (3,2,1) of current minimum
TBD4:
    DEC     HL                      ;[4D6E] HL -> x byte (skip)
    DJNZ    TBD2                    ;[4D6F] Next vertex
    ;
    ; E = top vertex index, STRBUF+10 = bottom vertex index.
    ; Compute middle vertex index = 6 - top - bottom (since indices 1+2+3=6).
    ; Set up IX and IY to point into the STRBUF vertex array for edge interpolation.
    LD      HL,SYSVAR_STRBUF+10     ;[4D71] HL -> STRBUF+10 (bottom vertex index)
    LD      A,(HL)                  ;[4D74] A = bottom vertex index
    LD      C,A                     ;[4D75] C = bottom vertex index
    XOR     E                       ;[4D76] A = bottom XOR top (detect if same vertex)
    LD      D,A                     ;[4D77] D = XOR result (0 if degenerate/flat triangle)
    JR      NZ,TAU                  ;[4D78] Non-zero: distinct vertices, proceed
    ; Degenerate case: top == bottom (flat or single-point triangle)
    INC     A                       ;[4D7A] A = 1 (minimum non-zero vertex index)
    LD      E,A                     ;[4D7B]
    INC     A                       ;[4D7C] A = 2
    LD      C,A                     ;[4D7D]
    INC     C                       ;[4D7E] C = 3
TAU:
    ; IX -> STRBUF entry for bottom vertex (base + (C-1)*2)
    ; IY -> STRBUF entry for top vertex    (base + (E-1)*2)
    LD      B,0                     ;[4D7F] B = 0 (high byte for 16-bit arithmetic)
    DEC     HL                      ;[4D81] HL -> STRBUF+9
    PUSH    HL                      ;[4D82] Save base pointer
    SLA     C                       ;[4D83] C *= 2 (2 bytes per vertex entry)
    ADD     HL,BC                   ;[4D85] HL = base + C*2 (bottom vertex offset)
    PUSH    HL                      ;[4D86]
    POP     IX                      ;[4D87] IX -> bottom vertex (x,y) in STRBUF
    POP     HL                      ;[4D89] HL = base pointer
    SLA     A                       ;[4D8A] A = E*2 (E is top vertex index)
    LD      C,A                     ;[4D8C]
    ADD     HL,BC                   ;[4D8D] HL = base + E*2 (top vertex offset)
    PUSH    HL                      ;[4D8E]
    POP     IY                      ;[4D8F] IY -> top vertex (x,y) in STRBUF
    PUSH    DE                      ;[4D91] Save D (XOR key for middle vertex detection)
    ;
    ; SUB_DIVMOD: compute edge DX/DY fraction for the long edge (bottom to top).
    ; Calls the division helper at $4E74.
    LD      L,(IX+0)                ;[4D92] L = bottom vertex x
    LD      C,(IY+0)                ;[4D95] C = top vertex x
    CALL    SUB_DELTA               ;[4D98] Compute |dx|, setup signed delta in C, B, D, H
    LD      L,(IX+1)                ;[4D9B] L = bottom vertex y
    LD      E,(IY+1)                ;[4D9E] E = top vertex y
    SBC     HL,DE                   ;[4DA1] HL = dy (signed, bottom minus top)
    CALL    Z,SUB_HORZEDGE          ;[4DA3] dy==0: horizontal edge, handle specially
    JR      Z,$4DAB                 ;[4DA6] Skip divide if horizontal
    CALL    SUB_SLOPE               ;[4DA8] Compute dx/dy fraction for long edge -> E,C,B
    ; Store edge step (E=frac_low, C=frac_high, B=sign) at STRBUF+8,+9,+10
    LD      HL,$6408                ;[4DAB] HL -> STRBUF+1 (SYSVAR_STRBUF = $6407, so +1 = $6408)
    LD      (HL),E                  ;[4DAE] Store fraction low byte
    INC     HL                      ;[4DAF]
    LD      (HL),C                  ;[4DB0] Store fraction high byte
    INC     HL                      ;[4DB1]
    LD      (HL),B                  ;[4DB2] Store sign byte
    ;
    ; Set up the middle vertex and compute edge steps for the other two edges.
    LD      HL,SYSVAR_STRBUF+9      ;[4DB3] HL -> STRBUF+9 (base of vertex table)
    POP     BC                      ;[4DB6] BC = D (XOR key for identifying middle vertex)
    PUSH    BC                      ;[4DB7] Save again
    LD      B,0                     ;[4DB8]
    SLA     C                       ;[4DBA] C *= 2
    ADD     HL,BC                   ;[4DBC] HL -> middle vertex entry
    PUSH    HL                      ;[4DBD]
    EX      (SP),IY                 ;[4DBE] IY now -> middle vertex; HL = old IY (top vertex)
    ; Compute edge step for bottom-to-middle edge
    LD      L,(IX+0)                ;[4DC0] L = bottom x
    LD      C,(IY+0)                ;[4DC3] C = middle x
    CALL    SUB_DELTA               ;[4DC6] Compute |dx| for bottom-to-middle
    LD      E,(IY+1)                ;[4DC9] E = middle y
    LD      L,(IX+1)                ;[4DCC] L = bottom y
    SBC     HL,DE                   ;[4DCF] HL = dy (bottom minus middle)
    CALL    Z,SUB_HORZEDGE          ;[4DD1] Horizontal: special case
    JR      Z,$4DD9                 ;[4DD4]
    CALL    SUB_SLOPE               ;[4DD6] Compute dx/dy for bottom-to-middle edge -> E,C,B
    ; Store at STRBUF+4,+5,+6
    LD      HL,SYSVAR_STRBUF+4      ;[4DD9] HL -> STRBUF+4
    LD      (HL),E                  ;[4DDC]
    INC     HL                      ;[4DDD]
    LD      (HL),C                  ;[4DDE]
    INC     HL                      ;[4DDF]
    LD      (HL),B                  ;[4DE0]
    EX      (SP),IX                 ;[4DE1] IX now -> top vertex; IY still -> middle
    ; Compute edge step for top-to-middle edge
    LD      L,(IX+0)                ;[4DE3] L = top x
    LD      C,(IY+0)                ;[4DE6] C = middle x
    CALL    SUB_DELTA               ;[4DE9] Compute |dx| for top-to-middle
    LD      L,(IX+1)                ;[4DEC] L = top y
    LD      E,(IY+1)                ;[4DEF] E = middle y
    SBC     HL,DE                   ;[4DF2] HL = dy (top minus middle)
    CALL    Z,SUB_HORZEDGE          ;[4DF4] Horizontal: special case
    JR      Z,$4DFC                 ;[4DF7]
    CALL    SUB_SLOPE               ;[4DF9] Compute dx/dy for top-to-middle edge -> E,C,B
    ; Store at STRBUF+14,+15,+16 ($640E)
    LD      HL,$640E                ;[4DFC] HL -> STRBUF+7
    LD      (HL),E                  ;[4DFF]
    INC     HL                      ;[4E00]
    LD      (HL),C                  ;[4E01]
    INC     HL                      ;[4E02]
    LD      (HL),B                  ;[4E03]
    ;
    ; Zero 6 bytes of interpolation accumulator at STRBUF+17..+22
    LD      B,$06                   ;[4E04] B = 6 bytes to clear
    LD      HL,SYSVAR_STRBUF+17     ;[4E06] HL -> STRBUF+17
    LD      (HL),0                  ;[4E09]
    INC     HL                      ;[4E0B]
    DJNZ    $4E09                   ;[4E0C] Zero 6 bytes
    ;
    ; Initialise the scan-line interpolation state.
    ; IY+0 = top Y; load STRBUF+18 and STRBUF+21 with the top vertex x.
    LD      HL,$6419                ;[4E0E] HL -> STRBUF+18
    LD      A,(IY+0)                ;[4E11] A = top vertex x
    LD      (HL),A                  ;[4E14] STRBUF+18 = top x (left edge accumulator)
    LD      HL,$641C                ;[4E15] HL -> STRBUF+21
    LD      (HL),A                  ;[4E18] STRBUF+21 = top x (right edge accumulator)
    LD      B,A                     ;[4E19] B = top x
    LD      C,A                     ;[4E1A] C = top x (both edges start at same point)
    ;
    ; Compute number of scan lines in upper half (top to middle vertex).
    LD      A,(IX+1)                ;[4E1B] A = bottom y
    LD      E,(IY+1)                ;[4E1E] E = top y
    LD      D,E                     ;[4E21] D = top y
    SUB     E                       ;[4E22] A = bottom y - top y = total height
    LD      E,A                     ;[4E23] E = total height (scan lines)
    LD      A,D                     ;[4E24] A = top y (for first scan-line address)
    EX      (SP),IY                 ;[4E25] IY = middle vertex (from stack); old IY saved
    PUSH    DE                      ;[4E27] Save (D=top y, E=total height)
    ;
    ; Check if top half is zero-height (top y == middle y)
    JR      NZ,$4E34                ;[4E28] Non-zero height: draw upper half
    ; Zero height: just plot the top vertex as a single point/line
    LD      C,(IX+0)                ;[4E2A] C = bottom x (reuse for horizontal fill)
    LD      (HL),C                  ;[4E2D] Update accumulator
    LD      A,C                     ;[4E2E]
    CALL    $4EE2                   ;[4E2F] Handle single degenerate scan line
    JR      $4E41                   ;[4E32] Skip to bottom half
    ;
    ; Draw upper half: scan lines from top y to middle y.
    ; SUB_STEP1/FILRAM fills horizontal spans; SUB_STEP1 advances edge accumulators;
    ; $4ECE tests and wraps the scan-line counter.
    CALL    FILRAM                  ;[4E34] Fill top scan line
TRI_UPPER:
    CALL    SUB_STEP1               ;[4E37] Advance both edge interpolators by one step
    INC     HL                      ;[4E3A] HL++
    INC     DE                      ;[4E3B] Y++
    CALL    SUB_STEP2               ;[4E3C] Test if upper half complete
    JR      NZ,TRI_UPPER            ;[4E3F] Not done: continue upper half
    ;
    ; Draw lower half: from middle y down to bottom y.
    POP     DE                      ;[4E41] Restore (D=top y, E=total height)
    LD      A,(IY+1)                ;[4E42] A = middle y
    LD      D,(IX+1)                ;[4E45] D = bottom y
    LD      E,D                     ;[4E48] E = bottom y
    SUB     E                       ;[4E49] A = middle y - bottom y = lower half height
    JR      Z,$4E5B                 ;[4E4A] Zero: no lower half
    LD      E,A                     ;[4E4C] E = lower half height
    PUSH    DE                      ;[4E4D]
TRI_LOWER:
    CALL    SUB_STEP1               ;[4E4E] Advance edge interpolators
    INC     DE                      ;[4E51] Y++
    LD      HL,$6408                ;[4E52] HL -> STRBUF+1
    CALL    SUB_STEP2               ;[4E55] Test if lower half complete
    JR      NZ,TRI_LOWER            ;[4E58] Not done: continue
    POP     DE                      ;[4E5A]
    ;
POP     IX                          ;[4E5B] IX = saved middle vertex index (from stack)
    POP     BC                      ;[4E5D] BC = middle vertex index
    XOR     A                       ;[4E5E]
    OR      B                       ;[4E5F]
    RET     NZ                      ;[4E60] BC non-zero: done
    ; Final bottom edge: fill span from IX+0 to IY+0 at row IY+1
    LD      B,(IX+0)                ;[4E61] B = bottom left x
    LD      C,(IY+0)                ;[4E64] C = bottom right x
    LD      A,C                     ;[4E67]
    CP      B                       ;[4E68] Ensure B <= C (left <= right)
    JR      NC,$4E6D                ;[4E69]
    LD      C,B                     ;[4E6B] Swap: C = left, B = right
    LD      B,A                     ;[4E6C]
    LD      A,(IY+1)                ;[4E6D] A = Y for final scan line
    CALL    FILRAM                  ;[4E70] Fill bottom edge span
    RET                             ;[4E73]
;
;------ TRIANGLE HELPER ROUTINES ------
;
; SUB_DELTA ($4E74): compute signed X delta for edge interpolation.
; Given two X coordinates in L (source) and C (target):
;   - Computes HL = (signed) (L - C) as a 16-bit value
;   - Returns C = |dx| (absolute delta), sign information in carry and HL.
; Also clears D and H to zero for use as high bytes.
;
SUB_DELTA:
    XOR     A                       ;[4E74] Clear carry
    LD      H,A                     ;[4E75] H = 0
    LD      B,A                     ;[4E76] B = 0
    SBC     HL,BC                   ;[4E77] HL = 0 - C = -C (two's complement)
    PUSH    HL                      ;[4E79] Save -C
    JP      P,$4E82                 ;[4E7A] Positive (C was 0 or delta positive): skip negation
    CPL                             ;[4E7D] Negate low byte ~
    XOR     L                       ;[4E7E] XOR with L (combine with L for |delta|)
    ADD     1                       ;[4E7F] Complete two's complement
    LD      L,A                     ;[4E81] L = |dx|
    LD      C,L                     ;[4E82] C = |dx|
    POP     HL                      ;[4E83] Restore signed delta in HL
    EX      (SP),HL                 ;[4E84] Exchange: HL = caller's saved, push delta
    PUSH    HL                      ;[4E85] Push caller's
    XOR     A                       ;[4E86] Clear A
    LD      D,A                     ;[4E87] D = 0
    LD      H,A                     ;[4E88] H = 0
    RET                             ;[4E89]
;
; SUB_SLOPE ($4E8A): compute dx/dy fractional step for an edge.
; Given C = |dx| and HL = signed dy (from calling $4E74 and SBC HL,DE):
;   - Computes the per-scan-line X step as a fixed-point fraction E.C
;     where E is the integer part and C is the fractional part.
;   - B = sign byte ($00 = positive slope, $FF = negative slope).
; Uses the 16-bit divide at $4F04.
;
SUB_SLOPE:
    PUSH    HL                      ;[4E8A] Save signed dy
    LD      A,L                     ;[4E8B] A = dy low
    JP      P,$4E92                 ;[4E8C] Positive dy: skip negation
    CPL                             ;[4E8F] Negate
    ADD     1                       ;[4E90] A = |dy|
    LD      E,A                     ;[4E92] E = |dy| (divisor)
    LD      A,C                     ;[4E93] A = |dx| (dividend)
    LD      C,0                     ;[4E94] C = 0 (will receive remainder)
    CALL    SUB_DIVMOD              ;[4E96] A,C = |dx| / |dy| with remainder
    LD      E,C                     ;[4E99] E = remainder (fractional part)
    LD      C,A                     ;[4E9A] C = quotient (integer part)
    POP     HL                      ;[4E9B] HL = signed dy
    LD      A,H                     ;[4E9C] A = dy high (sign byte)
    POP     HL                      ;[4E9D] HL = signed delta from $4E74
    EX      (SP),HL                 ;[4E9E] Exchange stack: HL = caller's saved
    XOR     H                       ;[4E9F] XOR sign of dy with sign of dx
    LD      B,0                     ;[4EA0] B = 0 (positive slope)
    JP      P,$4EB3                 ;[4EA2] Signs same (positive result): return
    LD      B,$FF                   ;[4EA5] Signs differ: B = $FF (negative slope)
    ; Negate the fractional step (E,C) for negative slope
    LD      A,E                     ;[4EA7]
    CPL                             ;[4EA8]
    ADD     1                       ;[4EA9] -E
    LD      E,A                     ;[4EAB]
    LD      A,C                     ;[4EAC]
    CPL                             ;[4EAD]
    LD      C,A                     ;[4EAE] ~C
    JP      NC,$4EB3                ;[4EAF] No carry from -E: done
    INC     BC                      ;[4EB2] Carry: adjust BC
    RET                             ;[4EB3]
;
; SR3 ($4EB4): advance edge interpolation accumulators by one scan line.
; Adds the precomputed per-scan-line X step (stored in STRBUF+4,+5,+6) to
; the running X accumulator (STRBUF+17,+18,+19).
; On exit: B = high byte of updated accumulator (sign/overflow indicator).
; Then falls through to companion routine at $4ECE which advances the other edge.
;
SUB_STEP1:
    LD    HL,SYSVAR_STRBUF+4        ;[4EB4] HL -> STRBUF+4 (edge step low)
    LD    DE,SYSVAR_STRBUF+17       ;[4EB7] DE -> STRBUF+17 (accumulator low)
    CALL  SUB_ADDACC                ;[4EBA] Add 2-byte step to 2-byte accumulator
    LD    B,A                       ;[4EBD] B = carry/result of high byte add
    LD    A,(DE)                    ;[4EBE] A = next accumulator byte
    ADC   (HL)                      ;[4EBF] A += step sign byte (with carry)
    LD    (DE),A                    ;[4EC0] Store updated sign byte
    AND   A                         ;[4EC1]
    JP    P,SR4                     ;[4EC2] Non-negative: valid X
    LD    B,0                       ;[4EC5] Clamp to 0 (X off left edge)
    JR    ETA2                      ;[4EC7]
SR4:
    JR    Z,ETA2                    ;[4EC9] Zero: X at edge
    LD    B,$FF                     ;[4ECB] Saturate to $FF (X off right edge)
ETA2:
    RET                             ;[4ECD]
;
; Companion edge advancer ($4ECE): advances the second edge accumulator.
; Adds STRBUF+1,+2 step to STRBUF+22,+23 accumulator.
; On exit: C = updated X for second edge; fills horizontal span (B,C) via FILRAM.
;
SUB_STEP2:
    CALL  SUB_ADDACC                ;[4ECE] Add step (STRBUF+1) to accumulator (STRBUF+22)
    LD    C,A                       ;[4ED1]
    LD    A,(DE)                    ;[4ED2]
    ADC   (HL)                      ;[4ED3]
    LD    (DE),A                    ;[4ED4]
    AND   A                         ;[4ED5]
    JP    P,$4EDD                   ;[4ED6]
    LD    C,0                       ;[4ED9] Clamp C to 0
    JR    $4EE1                     ;[4EDB]
    JR    Z,$4EE1                   ;[4EDD]
    LD    C,$FF                     ;[4EDF] Saturate C to $FF
    LD    A,C                       ;[4EE1] A = second edge X
    LD    C,A                       ;[4EE2] C = second X
    CP    B                         ;[4EE3] Compare first and second X
    JR    NC,$4EE8                  ;[4EE4] C >= B: correct order
    LD    C,B                       ;[4EE6] Swap: ensure B <= C for FILRAM
    LD    B,A                       ;[4EE7]
    ; Plot horizontal span from B to C at current scan line Y (on stack)
    POP   HL                        ;[4EE8] HL = return address of caller
    EX    (SP),HL                   ;[4EE9] HL = Y value from stack; push return addr
    LD    A,H                       ;[4EEA] A = Y coordinate
    PUSH  HL                        ;[4EEB] Save Y back
    CALL  FILRAM                    ;[4EEC] Fill horizontal span at row Y
    POP   HL                        ;[4EEF]
    INC   H                         ;[4EF0] Advance Y (next scan line)
    DEC   L                         ;[4EF1] Decrement span counter
    EX    (SP),HL                   ;[4EF2] Put updated state back
    JP    (HL)                      ;[4EF3] Return via indirect jump to continuation
;
; Horizontal edge handler ($4EF4): called when dy==0 (horizontal edge).
; Pops the dy value and sets E=0 (no vertical span) then returns via (HL).
;
SUB_HORZEDGE:
    POP   HL                        ;[4EF4] Discard dy
    POP   BC                        ;[4EF5] Discard saved value
    LD    E,0                       ;[4EF6] E = 0 (zero span)
    JP    (HL)                      ;[4EF8] Return via indirect jump
;
; ADD_ACCUM ($4EF9): 16-bit accumulator add.
; Adds 2-byte value at (HL) to 2-byte value at (DE), storing result at (DE).
; Both HL and DE are advanced by 2 on return.
; Returns A = low byte of result (for further ADC of sign byte by caller).
;
SUB_ADDACC:
    LD    A,(DE)                    ;[4EF9] A = accumulator low byte
    ADD   (HL)                      ;[4EFA] A += step low byte
    LD    (DE),A                    ;[4EFB] Store result low
    INC   DE                        ;[4EFC]
    INC   HL                        ;[4EFD]
    LD    A,(DE)                    ;[4EFE] A = accumulator high byte
    ADC   (HL)                      ;[4EFF] A += step high byte (with carry)
    LD    (DE),A                    ;[4F00] Store result high
    INC   HL                        ;[4F01]
    INC   DE                        ;[4F02]
    RET                             ;[4F03]
;
; UDIV16 ($4F04): 16-bit unsigned integer division.
; Computes A,C = (A * 256 + C) / DE using a shift-and-subtract algorithm.
; Used by SUB_SLOPE to compute the per-scan-line edge step (dx/dy).
; On entry: A = dividend high byte (|dx|), C = 0, DE = divisor (|dy|).
; On exit:  A = quotient, C = remainder (fractional part for fixed-point step).
; Uses 16 iterations (B = $10).
;
SUB_DIVMOD:
    LD    HL,0                      ;[4F04] HL = 0 (partial remainder)
    LD    B,$10                     ;[4F07] B = 16 (bits to process)
    AND   A                         ;[4F09] Clear carry
ZZ1:
    RL    C                         ;[4F0A] Shift C left (bring in next dividend bit)
    RLA                             ;[4F0C] Shift A left (shift out MSB of dividend)
    ADC   HL,HL                     ;[4F0D] HL = HL*2 + carry (partial remainder shift)
    SBC   HL,DE                     ;[4F0F] HL -= DE (trial subtraction)
    JR    NC,XLE                    ;[4F11] No borrow: subtraction valid
    ADD   HL,DE                     ;[4F13] Restore: HL += DE
XLE:
    CCF                             ;[4F14] Complement carry: 1=subtracted ok, 0=restored
    DJNZ  ZZ1                       ;[4F15] Repeat for all 16 bits
    RL    C                         ;[4F17] Shift final quotient bit into C
    RLA                             ;[4F19] Shift into A
    RET                             ;[4F1A]
;
;------ CLW (CLEAR WINDOW) ------
;
; ECLW: execute EXT CLW - clears the current text window to paper colour.
; First swaps ink and paper (SW) so FILRAM fills with paper colour, then
; fills every scan line of the window from top to bottom, then restores ink/paper.
;
; STRBUF+17..+22 is used by FILRAM for Y and column tracking.
; Window coordinates: SYSVAR_WINDST: left_x, right_x, top_y, bottom_y.
; Screen X is in units of 2 pixels (CURSORX), Y is in pixels (CURSORY).
;
ECLW:
    CALL  SW                        ;[4F1B] Swap ink/paper (so fill uses paper colour)
    LD    HL,(SYSVAR_WINDST)        ;[4F1E] L = window left X, H = window right X
    LD    DE,(SYSVAR_WINDST+2)      ;[4F21] E = window top Y, D = window bottom Y
    LD    A,L                       ;[4F25] A = window left X
    LD    (SYSVAR_CURSORX),A        ;[4F26] Set cursor X to window left (home cursor)
    LD    A,E                       ;[4F29] A = window top Y
    LD    (SYSVAR_CURSORY),A        ;[4F2A] Set cursor Y to window top
    ADD   HL,HL                     ;[4F2D] HL = (right_x, left_x) * 2: convert X units to pixel columns
    LD    A,D                       ;[4F2E] A = bottom Y
    SUB   E                         ;[4F2F] A = (bottom - top) = number of scan lines to fill
    LD    B,L                       ;[4F30] B = window left pixel (X * 2 low byte = left pixel column)
    LD    C,H                       ;[4F31] C = window right pixel (X * 2 high byte)
    INC   C                         ;[4F32] C = right + 1 (inclusive right edge)
WLL1:
    PUSH  AF                        ;[4F33] Save remaining row count
    LD    A,E                       ;[4F34] A = current Y (scan line)
    PUSH  BC                        ;[4F35] Save (B=left, C=right)
    PUSH  DE                        ;[4F36] Save (D=bottom, E=current Y)
    CALL  FILRAM                    ;[4F37] Fill scan line from B to C at row A
    POP   DE                        ;[4F3A]
    POP   BC                        ;[4F3B]
    POP   AF                        ;[4F3C]
    INC   E                         ;[4F3D] E++ (next scan line Y)
    DEC   A                         ;[4F3E] Decrement row count
    JR    NZ,WLL1                   ;[4F3F] Repeat for all rows in window
;
; SW: swap ink and paper colours.
; Exchanges SYSVAR_INKST and SYSVAR_PAPST by loading both as a 16-bit word
; (L = ink, H = paper), swapping them, and writing back.
; Used by ECLW to fill with paper colour, and again after to restore.
;
SW:
    LD    HL,(SYSVAR_INKST)         ;[4F41] L = ink colour, H = paper colour
    LD    E,H                       ;[4F44] E = paper colour
    LD    H,L                       ;[4F45] H = ink colour (will become new paper)
    LD    L,E                       ;[4F46] L = paper colour (will become new ink)
    LD    (SYSVAR_INKST),HL         ;[4F47] Write back swapped: ink<->paper
    RET                             ;[4F4A]

;
; Padding to $4FF0
;
DEFS 165,$FF
;
; ROM identification bytes (unused / padding).
; These 5 bytes at $4FF0 may be a version signature or leftover data.
;
    LD    H,H                       ;[4FF0] NOP-equivalent (LD r,r): padding/marker
    LD    E,C                       ;[4FF1]
    LD    H,H                       ;[4FF2]
    LD    D,E                       ;[4FF3]
    LD    E,B                       ;[4FF4]
;
; Padding to end of ROM
;
DEFS 11,$0
;
DEPHASE
