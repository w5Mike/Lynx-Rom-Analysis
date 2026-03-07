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
;**************************** VERSION HISTORY **************************
;*
;*   Disassembly, collation and formatting by: Mike Panter 06/11/2021.
;*
;*   VERSION 2 - Additional comments provided by CLAUDE (Anthropic's AI)
;*               under the direction of Mike Panter 06/03/2026.
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
;********************** LABELS/SYMBOLS/PREFIXES ************************
;*
;*      SYSVAR_     - RAM addresses used by the Lynx ROM routines
;*      RST_        - Z80 Restarts
;*      DATA_       - Data tables stored in rom (eg. PI)
;*      E<command>  - Lynx BASIC command
;*      F<name>     - Lynx BASIC functions/operators
;*      I<name>     - Validation of BASIC commands/functions.
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
;
PUBLIC INTFP, ERR_TYPE_MISMATCH, ERR_OUT_OF_DATA, ERR_NOT_YET_IMP, ERR_SYNTAX, SPACE
PUBLIC LNUM1, PN, TEST_IS_LOOP_END, SUB_INDENT, SKIP_LNUM, SUB_PRINT_KEYWORD, PRINT_BAS_LINE
PUBLIC PRINT_STRING, DISPLAY_SPACE, PNE1, DO_INDENT, IEND, _BEEP, D6845, ERR_BAD_TAPE
PUBLIC ERR_NUM_OUT_RANGE, ERR_OUT_OF_MEM, ERR_OVERFLOW, ERR_SOMETHG_MISSG, ERROR_PRINT
PUBLIC EXEC2, FLOAT_ZERO, FPINT, GET_VAR_ADDR, IDPOKE, IE4CR, IE6CR, IINK, ILOAD, IVRY 
PUBLIC IREM, MOTOFF, RBYTE, READ_STRING_EXPR, READ_STRING_VAR, RP, RSYNC, STRING_EXEC
PUBLIC SUB_PLOT3, TAPE_READ, TEST_FOR_STR_EXP, TEST_FOR_STRING, TEST_IS_COMMA
PUBLIC VPTR_IS_STR, WRITE_FNAME, WSYNC, VROM, DFTW
;
; Lynx symbols and BASIC tokens
;
include "Lynx.def"
include "Tokens.def"

SECTION _48k_1

;
; Power-on / Reset entry point.
; Disables maskable interrupts immediately, sets port $80 bit 5 (selects ROM
; bank / disables RAM overlay), then jumps to the 6845 CRT initialisation
; routine. This is the very first code executed on every cold start.
;
BEGIN:
    DI                              ;[0000] Disable interrupts - safe startup state
    LD    A,$20                     ;[0001] Bit 5 = ROM bank select / disable RAM overlay
    OUT   ($80),A                   ;[0003] Write to system control port
    JP    CRTC                      ;[0005] Jump to 6845 CRT controller initialisation

;
; RST $08 - Output character in A to the current output device.
; This is the primary character output restart; almost every print
; operation in the ROM uses "RST $08" as a one-byte call to PUTCHAR.
;
RST_8:
    JP    PUTCHAR                   ;[0008] Jump to the full character output routine

;
; ROM version identifier string. Sits at a fixed offset immediately after
; RST $08. The string " L014" identifies this as ROM revision L014.
; Readable from BASIC via PEEK on this address range.
;
LYNX_IDENT:
    DB    " L014"                   ;[000B] Version string: space + "L014"

;
; Skip leading spaces. DE points to the current parse position in a BASIC
; line or expression. If the byte at (DE) is a space ($20), DE is advanced
; and the check is repeated; returns when (DE) is a non-space character.
; Used throughout the tokeniser and expression evaluator.
;
SPACE:
    LD    A,(DE)                    ;[0010] Load current character
    CP    ' '                       ;[0011] Is it a space?
    RET   NZ                        ;[0013] No - return with DE pointing here
    INC   DE                        ;[0014] Yes - advance past the space
    JR    SPACE                     ;[0015] Check again
    NOP                             ;[0017] Padding to align RST $18 to $0018

;
; RST $18 - Evaluate integer expression.
; Evaluates the reverse-polish expression pointed to by DE, returning
; the result as a 16-bit binary integer in HL. DE is advanced past
; the expression. Used wherever a BASIC command needs a simple integer
; argument (BEEP counts, line numbers, port numbers, etc.).
;
RST_18:
    JP    EINT                      ;[0018] Jump to integer expression evaluator

;
; Hidden "Easter egg" - name of the Lynx User Manual author, Sue Jansons.
; This null-terminated string sits at a fixed location just after RST $18
; and is padding / a tribute embedded by the ROM authors.
;
SUSY:
    DB    "Susy",$00                ;[001B] Sue Jansons' name, null-terminated

;
; RST $20 - Expect a specific character or syntax error.
; The byte immediately following the RST $20 instruction in the caller's
; code is the expected character. This routine pops the return address
; (HL), compares the expected byte at (HL) with A, then increments HL
; (past the expected byte) and pushes it back. If A matches, execution
; continues normally; otherwise ERR_SYNTAX is called.
; Usage: RST $20 / DB expected_char
;
RST_20:
    EX    (SP),HL                   ;[0020] HL = return address (points at expected char)
    CP    (HL)                      ;[0021] Compare A with the expected character
    INC   HL                        ;[0022] Advance return address past the DB byte
    EX    (SP),HL                   ;[0023] Put updated return address back on stack
    RET   Z                         ;[0024] Match - return to caller (after the DB byte)
    CALL  ERR_SYNTAX                ;[0025] No match - syntax error

;
; RST $28 - Evaluate floating-point expression.
; Evaluates the reverse-polish expression pointed to by DE, storing the
; result in floating-point form in WRA1 (Working Register Area 1, a 5-byte
; area in RAM). DE is advanced past the expression on return. Used wherever
; a BASIC command needs a full floating-point value (SIN, COS, etc.).
;
RST_28:
    JP    SUB_CHK_EXP_EVAL          ;[0028] Jump to floating-point expression evaluator
    DB    0,0,0,0,0                 ;[002B] Padding to align RST $30 to $0030

;
; RST $30 - Jump to MONITOR trap handler.
; Called when the Z80 executes RST $30 during normal BASIC execution, or
; when an NMI occurs and the monitor is active. Also contains a POP HL /
; JP (HL) trampoline used internally by the monitor for indirect jumps.
;
RST_30:
    JP    EMON                      ;[0030] Jump to monitor entry point
    POP   HL                        ;[0033] Trampoline: pop destination into HL
    JP    (HL)                      ;[0034] and jump to it
    DB    0,0,0                     ;[0035] Padding to align RST $38 to $0038

;
; RST $38 / IM1 Maskable Interrupt handler - jumps to RAM vector.
; On the Lynx this RST is used as a soft interrupt and as the IM1
; interrupt entry point. The target address (SYSVAR_RSTRAM) is held
; in RAM so the handler can be redirected at runtime. Not yet
; implemented in this ROM version; the RAM word is initialised to a
; RET instruction during INIT.
;
RST_38:
    JP    SYSVAR_RSTRAM             ;[0038] Jump through RAM-resident vector

;
; Initialise the Motorola 6845 CRT Controller.
; Writes 16 register values from the D6845 table into the 6845.
; Register select is port $86; data is port $87.
; Port $FF7F (BC=$FF7F, OUT (C),A) resets the video hardware first.
; After the 6845 is configured, execution falls through to INIT.
;
CRTC:
    XOR   A                         ;[003B] A = 0 (first register index)
    LD    BC,$FF7F                  ;[003C] B=$FF (port address hi), C=$7F (port lo)
    OUT   (C),A                     ;[003F] Reset video hardware via port $FF7F
    LD    B,$10                     ;[0041] 16 registers to load
    LD    HL,D6845                  ;[0043] HL -> 6845 register value table
    XOR   A                         ;[0046] Start with register 0
CRTC1:
    OUT   ($86),A                   ;[0047] Select 6845 register number
    EX    AF,AF'                    ;[0049] Swap: save register index
    LD    A,(HL)                    ;[004A] Get register value from table
    OUT   ($87),A                   ;[004B] Write value to selected 6845 register
    EX    AF,AF'                    ;[004D] Restore register index
    INC   A                         ;[004E] Next register
    INC   HL                        ;[004F] Next table entry
    DJNZ  CRTC1                     ;[0050] Loop for all 16 registers
    JP    INIT                      ;[0052] 6845 done - proceed to system initialisation
    NOP                             ;[0055] Padding

;
; 6845 CRT Controller register values for the Lynx display.
; The Lynx uses a 6 MHz pixel clock with 32 columns x 63 rows character
; cells (each cell is 6 px wide x 10 scan lines). The display runs at
; approximately 50 Hz (PAL). These values produce the standard Lynx
; 256x192 effective resolution within a 32-column, 63-row character grid.
;
D6845:
    DB    $2F  ;R0  = Horizontal Total       = 47 (total chars per line including blanking)
    DB    $20  ;R1  = Horizontal Displayed   = 32 (visible columns)
    DB    $26  ;R2  = Horizontal Sync Pos    = 38 (sync pulse start position)
    DB    $33  ;R3  = Sync widths            = $33 (H-sync=3 chars, V-sync=3 rows)
    DB    $4D  ;R4  = Vertical Total (rows)  = 77 (total character rows including blanking)
    DB    $02  ;R5  = Vertical Total Adjust  = 2 scan lines (fine vertical adjust)
    DB    $3F  ;R6  = Vertical Displayed     = 63 (visible character rows)
    DB    $44  ;R7  = Vertical Sync Pos      = 68 (sync position in rows)
    DB    $00  ;R8  = Interlace Mode         = 0 (non-interlaced)
    DB    $03  ;R9  = Max Scan Line Address  = 3 (4 scan lines per half-row for 10-line chars)
    DB    $03  ;R10 = Cursor Start Line      = 3 (cursor shape start scan)
    DB    $03  ;R11 = Cursor End Line        = 3 (cursor shape end scan - single line cursor)
    DB    $00  ;R12 = Start Address (High)   = 0 (video RAM starts at $0000 in video space)
    DB    $00  ;R13 = Start Address (Low)    = 0
    DB    $07  ;R14 = Cursor Address (High)  = $07 (initial cursor position high byte)
    DB    $DF  ;R15 = Cursor Address (Low)   = $DF (initial cursor position low byte = col 31, row 7)

;
; NMI (Non-Maskable Interrupt) handler.
; Jumps through a RAM word (SYSVAR_NMIRAM) so the NMI handler can be
; replaced at runtime (e.g. by MONITOR or user code). By default the
; RAM word is initialised to point to the monitor entry, so pressing
; the NMI button on the Lynx drops into the machine-code monitor.
;
NMI_JUMP:
    JP    SYSVAR_NMIRAM             ;[0066] Jump through RAM-resident NMI vector

;
; Read a byte from the RED/BLUE video bank at address HL.
; The Lynx display uses three separate colour planes (red, green, blue),
; each held in a different switched memory bank. This routine temporarily
; switches in the red/blue bank, reads the byte at (HL) into L (H=0),
; then restores normal memory mapping. Bank switching is controlled via
; port $80 (system control register) and port $FF7F (via BC=$FF7F, OUT(C),A).
; Returns: L = byte read, H = 0.
;
INBLUE:
    LD    A,$E8                     ;[0069] Bank-select code for red/blue plane
    EX    AF,AF'                    ;[006B] Stash it in alternate AF
    LD    A,$63                     ;[006C] Port $FF7F value to enable red/blue bank
    JR    INBANK                    ;[006E] Jump to common bank-read routine

;
; Read a byte from the GREEN / alternative-green video bank at address HL.
; Same mechanism as INBLUE but selects the green colour plane instead.
; Returns: L = byte read, H = 0.
;
INGREEN:
    LD    A,$E4                     ;[0070] Bank-select code for green plane
    EX    AF,AF'                    ;[0072] Stash it in alternate AF
    LD    A,$65                     ;[0073] Port $FF7F value to enable green bank
                                    ; *** FALL THROUGH to INBANK ***
;
; Common bank-read routine used by both INBLUE and INGREEN.
; On entry: A  = port $FF7F value to select the bank
;           A' = port $80 bank-select byte (stashed via EX AF,AF')
;           HL = address to read within the selected bank
; On exit:  L  = byte read from (HL) in the selected bank
;           H  = 0
;           All other registers and bank mapping restored.
;
INBANK:
    LD    BC,$FF7F                  ;[0075] B=$FF, C=$7F - address for bank-select port
    OUT   (C),A                     ;[0078] Select the requested video bank via port $FF7F
    LD    A,$40                     ;[007A] Set bit 6 = enable bank-switching mode
    OUT   ($80),A                   ;[007C] Assert bank-switch enable on system control port
    EX    AF,AF'                    ;[007E] Retrieve the stashed bank-select byte
    OUT   ($80),A                   ;[007F] Activate the specific colour bank
    LD    L,(HL)                    ;[0081] Read the byte from the bank into L
    XOR   A                         ;[0082] A = 0 (used to deselect and to clear H)
    OUT   ($80),A                   ;[0083] Deselect bank (clear system control port)
    OUT   (C),A                     ;[0085] Restore normal bank mapping (port $FF7F = 0)
    LD    H,A                       ;[0087] H = 0 (result is the 8-bit value in L only)
    RET                             ;[0088]

;
; Keyboard debounce delay, then re-read column.
; After a key transition is detected, this routine waits KDBNCE loop
; iterations to let the key contacts settle, then re-reads the same
; keyboard column port (already loaded in BC by the caller). Returns
; the complemented raw port value in A so that pressed keys appear as
; '1' bits (the Lynx keyboard gives 0 for pressed, so CPL inverts this).
;
DBNCE:
    PUSH  BC                        ;[0089] Save keyboard column port address
    LD    BC,KDBNCE                 ;[008A] Load debounce wait count
    CALL  KBD_DLAY                  ;[008D] Busy-wait for contacts to settle
    POP   BC                        ;[0090] Restore keyboard column port address
    IN    A,(C)                     ;[0091] Re-read the column
    CPL                             ;[0093] Invert: pressed keys now give '1' bits
    RET                             ;[0094]

    AND   (HL)                      ;[0095] Probably unused - unreachable bytes
    LD    B,B                       ;[0096] 
    SBC   A,B                       ;[0097] 
    RET   PE                        ;[0098] 
    RET   Z                         ;[0099] 

;
; Character output driver - called indirectly via the SYSVAR_VIDEO RAM vector.
; Handles both normal and double-height character modes.
;
; In normal mode (BPERL=$20, bit 6 of L clear): falls straight through to
; VIDEO_GETPOS which calculates the screen address and draws the character.
;
; In double-height mode (BPERL=$40, bit 6 of L set): each character occupies
; two consecutive 10-scan-line rows. The routine draws a space in the upper
; row (to blank any previous content there), then draws the actual character
; in the lower row. VIDEO_WBANKS is called in each pass to apply the write
; to all three colour planes simultaneously.
;
VIDEO:
    PUSH  HL                        ;[009A] Preserve HL (character code in A)
    LD    HL,(SYSVAR_BPERL)         ;[009B] Load bytes-per-line / mode flags
    BIT   6,L                       ;[009E] Bit 6 set = double-height mode (BPERL=$40)?
    POP   HL                        ;[00A0] Restore HL
    JP    Z,VIDEO_GETPOS            ;[00A1] Normal height - draw character directly
    PUSH  AF                        ;[00A4] Double-height: save character code
    CALL  VIDEO_GETPOS              ;[00A5] Position cursor at upper half of cell
    LD    A,$20                     ;[00A8] Space - blank the upper row
    CALL  VIDEO_WBANKS              ;[00AA] Write space to all three colour banks
    POP   AF                        ;[00AD] Restore character code
    PUSH  AF                        ;[00AE] 
    CALL  VIDEO_GETPOS              ;[00AF] Position cursor at lower half of cell
    XOR   A                         ;[00B2] A=0: signal to draw actual character data
    CALL  VIDEO_WBANKS              ;[00B3] Write character to all three colour banks
    POP   AF                        ;[00B6] 
    RET                             ;[00B7]

;
; Set the pending write byte for all three colour planes to A, then return.
; The actual pixel write happens later via SYSVAR_OUTB. By storing the same
; value in all three bank variables, the next OUTB call will update red,
; green and blue simultaneously, producing a fully-coloured character cell.
;
VIDEO_WBANKS:
    LD    (SYSVAR_BLUBNK),A         ;[00B8] Blue plane write value  (bank at $8000)
    LD    (SYSVAR_REDBNK),A         ;[00BB] Red plane write value   (bank at $C000)
    LD    (SYSVAR_GRNBNK),A         ;[00BE] Green plane write value (bank at $C000)
    RET                             ;[00C1]

;
; Wrapper that saves and restores all registers around a call to VIDEO_POS.
; Ensures the caller's AF, HL, DE, BC are all preserved across the draw call.
;
VIDEO_GETPOS:
    PUSH  AF                        ;[00C2] 
    PUSH  HL                        ;[00C3] 
    PUSH  DE                        ;[00C4] 
    PUSH  BC                        ;[00C5] 
    CALL  VIDEO_POS                 ;[00C6] Calculate screen address and draw character
    POP   BC                        ;[00C9] 
    POP   DE                        ;[00CA] 
    POP   HL                        ;[00CB] 
    POP   AF                        ;[00CC] 
    RET                             ;[00CD]

;
; Return the ROM address of the 10-byte bitmap for the character in A.
; Characters 0-127 use the alphanumeric table (address in SYSVAR_CHRTBL,
; default = CHRTBS in ROM). Characters 128-255 use the graphics table
; (SYSVAR_GPHTBL, default = graphic block patterns after CHRTBS).
; Each entry is exactly 10 bytes (one byte per scan line, 10 lines tall).
;
; Calculation: address = table_base + (char & $7F) * 10
; Multiply by 10 is done as: n*2 -> save as DE; n*8 -> add DE = n*10.
;
; Returns: HL = address of the 10-byte character bitmap.
; Called from VIDEO_POS (to draw a character) and FLETTER (LETTER function).
;
FONT:
    LD    HL,(SYSVAR_CHRTBL)        ;[00CE] Default: alphanumeric bitmap table address
    BIT   7,A                       ;[00D1] Is bit 7 set? (char code >= 128 = graphic)
    JR    Z,FONT_OFFSET             ;[00D3] No - use alphanumeric table already in HL
    LD    HL,(SYSVAR_GPHTBL)        ;[00D5] Yes - switch to graphics bitmap table
FONT_OFFSET:
    AND   $7F                       ;[00D8] Mask to 7-bit index (0-127) within table
    PUSH  HL                        ;[00DA] Save table base address
    LD    L,A                       ;[00DB] HL = character index
    LD    H,$00                     ;[00DC] 
    ADD   HL,HL                     ;[00DE] HL = index * 2
    LD    E,L                       ;[00DF] DE = index * 2  (save for later)
    LD    D,H                       ;[00E0] 
    ADD   HL,HL                     ;[00E1] HL = index * 4
    ADD   HL,HL                     ;[00E2] HL = index * 8
    ADD   HL,DE                     ;[00E3] HL = index * 10  (8 + 2)
    POP   DE                        ;[00E4] DE = table base address
    ADD   HL,DE                     ;[00E5] HL = table_base + (index * 10)
    RET                             ;[00E6] HL now points to the 10-byte character bitmap

;
; Calculate the screen RAM address for the current cursor position, and
; dispatch to the correct bit-alignment routine (XPOS1-4).
;
; The Lynx screen is 1 bit per pixel, 256 pixels wide = 32 bytes per row.
; Characters are 6 pixels wide, so each occupies 6 bits of the byte stream.
; Since 6 does not divide evenly into 8, a character can begin at one of
; four possible 2-bit boundaries within a byte (bit offsets 0, 2, 4 or 6).
; The low 2 bits of the X cursor position select which boundary applies:
;
;   Slot 0 (X & 3 = 0): bits 7-2 of byte N            (fits in one byte)
;   Slot 1 (X & 3 = 1): bits 5-0 of byte N            (fits in one byte)
;   Slot 2 (X & 3 = 2): bits 3-0 of byte N,
;                        bits 7-6 of byte N+1          (spans two bytes)
;   Slot 3 (X & 3 = 3): bits 1-0 of byte N,
;                        bits 7-4 of byte N+1          (spans two bytes)
;
; For slots 2 and 3, the caller handles the two-byte case by calling the
; "left" routine for byte N, incrementing HL, then calling the "right"
; routine for byte N+1.
;
; On entry: A = character code to draw.
; On exit:  character pixels written to screen RAM at the cursor position.
;
VIDEO_POS:
    CALL  FONT                      ;[00E7] HL = address of character's 10-byte bitmap
    EX    DE,HL                     ;[00EA] DE = bitmap address (free HL for screen address)
    LD    HL,(SYSVAR_CURSORY)       ;[00EB] HL = current Y cursor position (pixel row)
    LD    H,$00                     ;[00EE] Clear H - Y fits in one byte
    LD    A,(SYSVAR_BPERL)          ;[00F0] A = bytes per line (32 normal, 64 double-height)
    SRL   A                         ;[00F3] Halve it to derive the shift count
VIDEO_YPOS:
    ADD   HL,HL                     ;[00F5] HL *= 2 (repeated to multiply Y by BPERL)
    SRL   A                         ;[00F6] Shift count down
    JR    NZ,VIDEO_YPOS             ;[00F8] Loop until done: HL = Y * BPERL (byte row offset)
VIDEO_XPOS:
    LD    A,(SYSVAR_CURSORX)        ;[00FA] A = X cursor position (in character columns)
    RRCA                            ;[00FD] Divide X by 4 to get the byte offset within row
    RRCA                            ;[00FE] (4 character columns fit per byte at 6 bits each)
    AND   $3F                       ;[00FF] Mask to 6 bits
    LD    C,A                       ;[0101] 
    LD    B,$00                     ;[0102] BC = byte offset within the row
    ADD   HL,BC                     ;[0104] HL = screen RAM address of the target byte
    LD    A,(SYSVAR_CURSORX)        ;[0105] Re-load X to extract the 2-bit slot
    AND   $03                       ;[0108] Low 2 bits = which 2-bit boundary (slot 0-3)
    JR    Z,JP_VID1                 ;[010A] Slot 0 -> VIDEO_XPOS1
    DEC   A                         ;[010C] 
    JR    Z,JP_VID2                 ;[010D] Slot 1 -> VIDEO_XPOS2
    DEC   A                         ;[010F] 
    JR    Z,VID3                    ;[0110] Slot 2 -> VIDEO_XPOS3 (spans two bytes)
    JR    CALL_XPOS4                ;[0112] Slot 3 -> VIDEO_XPOS4 (spans two bytes)
JP_VID2:
    JP    VIDEO_XPOS2               ;[0114] Long-jump trampoline (JR range too short)
JP_VID1:
    JP    VIDEO_XPOS1               ;[0117] Long-jump trampoline
;
; Slot 3 spans two bytes. Draw bits 1-0 of each row into byte N first,
; then advance HL and draw bits 7-4 of each row into byte N+1.
;
CALL_XPOS4:
    PUSH  HL                        ;[011A] Save screen address (byte N)
    PUSH  DE                        ;[011B] Save bitmap address
    CALL  VIDEO_XPOS4               ;[011C] Draw 2 bits into byte N (bits 1-0)
    POP   DE                        ;[011F] 
    POP   HL                        ;[0120] 
    INC   HL                        ;[0121] Advance to byte N+1
    JP    VIDEO_XPOS4B              ;[0122] Draw 4 bits into byte N+1 (bits 7-4)
;
; Slot 2 spans two bytes. Draw bits 3-0 of each row into byte N first,
; then advance HL and draw bits 7-6 of each row into byte N+1.
;
VID3:
    PUSH  HL                        ;[0125] Save screen address (byte N)
    PUSH  DE                        ;[0126] Save bitmap address
    CALL  VIDEO_XPOS3               ;[0127] Draw 4 bits into byte N (bits 3-0)
    POP   DE                        ;[012A] 
    POP   HL                        ;[012B] 
    INC   HL                        ;[012C] Advance to byte N+1
    JP    VIDEO_XPOS3B              ;[012D] Draw 2 bits into byte N+1 (bits 7-6)

;
; VIDEO_XPOS1-4: The four bit-alignment character rendering routines.
;
; The Lynx screen is 1 bit per pixel. Characters are 6 pixels (bits) wide.
; Each routine draws all 10 scan lines of a character into screen RAM,
; handling one of the four possible 2-bit boundary alignments. On each
; of the 10 iterations:
;   - DE points to the next bitmap byte (one row of 6 pixel bits)
;   - HL points to the screen RAM byte for that scan line
;   - The 6 bitmap bits are shifted into the correct position within the byte
;   - Unused bits in the byte are protected by ORing SYSVAR_MASK with a
;     "protect" mask before passing to SYSVAR_OUTB, which merges the new
;     bits with the existing screen content (overwrite or transparent mode)
;   - HL advances by BPERL (32) bytes to move to the next scan line
;
; SYSVAR_MASK: $00 = overwrite mode, $FF = transparent/OR mode.
;
; Slot 0 - character starts at bit 7 (leftmost).
; 6 bitmap bits occupy bits 7-2 of the screen byte.
; Bitmap byte is shifted LEFT 2 to align to bit 7.
; AND $FC cleans up any carry bits. Mask $03 protects bits 1-0
; (the 2 bits belonging to the next character position).
;
VIDEO_XPOS1:
    LD    B,$0A                     ;[0130] 10 scan lines to draw
VIDEO_XPOS1A:
    PUSH  BC                        ;[0132] Save line counter
    LD    A,(SYSVAR_MASK)           ;[0133] Get overwrite/transparent mask
    OR    $03                       ;[0136] Protect bits 1-0 (next character's bits)
    LD    C,A                       ;[0138] C = protect mask for OUTB
    LD    A,(DE)                    ;[0139] A = bitmap byte for this scan line
    RLCA                            ;[013A] Shift bitmap left 2 bits to reach bit 7
    RLCA                            ;[013B] 
    AND   $FC                       ;[013C] Clear bits 1-0 (clean up after rotate)
    CALL  SYSVAR_OUTB               ;[013E] Merge with screen byte and write to all banks
    LD    BC,(SYSVAR_BPERL)         ;[0141] BC = bytes per line (32)
    ADD   HL,BC                     ;[0145] HL = next scan line's screen address
    INC   DE                        ;[0146] DE = next bitmap row
    POP   BC                        ;[0147] Restore line counter
    DJNZ  VIDEO_XPOS1A              ;[0148] Repeat for all 10 scan lines
    RET                             ;[014A]

;
; Slot 1 - character starts at bit 5.
; 6 bitmap bits occupy bits 5-0 of the screen byte.
; No shift needed - bitmap bits go directly into the low 6 bits.
; AND $3F masks off the top 2 bits of the bitmap byte (always 0 in font
; data, but masking is safe). Mask $C0 protects bits 7-6 (the 2 bits
; belonging to the previous character position).
;
VIDEO_XPOS2:
    LD    B,$0A                     ;[014B] 10 scan lines to draw
VIDEO_XPOS2A:
    PUSH  BC                        ;[014D] Save line counter
    LD    A,(SYSVAR_MASK)           ;[014E] Get overwrite/transparent mask
    OR    $C0                       ;[0151] Protect bits 7-6 (previous character's bits)
    LD    C,A                       ;[0153] C = protect mask for OUTB
    LD    A,(DE)                    ;[0154] A = bitmap byte for this scan line
    AND   $3F                       ;[0155] Keep only the 6 bitmap bits (bits 5-0)
    CALL  SYSVAR_OUTB               ;[0157] Merge with screen byte and write to all banks
    LD    BC,(SYSVAR_BPERL)         ;[015A] BC = bytes per line (32)
    ADD   HL,BC                     ;[015E] HL = next scan line's screen address
    INC   DE                        ;[015F] DE = next bitmap row
    POP   BC                        ;[0160] Restore line counter
    DJNZ  VIDEO_XPOS2A              ;[0161] Repeat for all 10 scan lines
    RET                             ;[0163]

;
; Slot 3, right byte (byte N+1) - draws the upper 4 bits of each bitmap row.
; The 6 bitmap bits span bytes N and N+1. Byte N holds bits 1-0 (2 bits),
; byte N+1 holds bits 7-4 (4 bits). Here we shift the bitmap LEFT 4 to
; move the top 4 bits of the character into bits 7-4 of the screen byte.
; Mask $0F protects bits 3-0 of byte N+1 (the next character's bits).
;
VIDEO_XPOS4B:
    LD    B,$0A                     ;[0164] 10 scan lines to draw
VIDEO_XPOS4C:
    PUSH  BC                        ;[0166] Save line counter
    LD    A,(SYSVAR_MASK)           ;[0167] Get overwrite/transparent mask
    OR    $0F                       ;[016A] Protect bits 3-0 (next character's bits)
    LD    C,A                       ;[016C] C = protect mask for OUTB
    LD    A,(DE)                    ;[016D] A = bitmap byte for this scan line
    RLCA                            ;[016E] Shift bitmap left 4 to reach bits 7-4
    RLCA                            ;[016F] 
    RLCA                            ;[0170] 
    RLCA                            ;[0171] 
    AND   $F0                       ;[0172] Keep only bits 7-4 (top 4 of the 6 char bits)
    CALL  SYSVAR_OUTB               ;[0174] Merge with screen byte and write to all banks
    LD    BC,(SYSVAR_BPERL)         ;[0177] BC = bytes per line (32)
    ADD   HL,BC                     ;[017B] HL = next scan line's screen address
    INC   DE                        ;[017C] DE = next bitmap row
    POP   BC                        ;[017D] Restore line counter
    DJNZ  VIDEO_XPOS4C              ;[017E] Repeat for all 10 scan lines
    RET                             ;[0180]

;
; Slot 3, left byte (byte N) - draws the lower 2 bits of each bitmap row.
; The 6 bitmap bits span bytes N and N+1. Byte N holds the bottom 2 bits
; of the character in screen bits 1-0. Shift bitmap LEFT 4, then AND $03
; keeps only those 2 bits. Mask $FC protects bits 7-2 of byte N
; (the 6 bits of the previous character).
;
VIDEO_XPOS4:
    LD    B,$0A                     ;[0181] 10 scan lines to draw
VIDEO_XPOS4A:
    PUSH  BC                        ;[0183] Save line counter
    LD    A,(SYSVAR_MASK)           ;[0184] Get overwrite/transparent mask
    OR    $FC                       ;[0187] Protect bits 7-2 (previous character's bits)
    LD    C,A                       ;[0189] C = protect mask for OUTB
    LD    A,(DE)                    ;[018A] A = bitmap byte for this scan line
    RLCA                            ;[018B] Shift bitmap left 4
    RLCA                            ;[018C] 
    RLCA                            ;[018D] 
    RLCA                            ;[018E] 
    AND   $03                       ;[018F] Keep only bits 1-0 (bottom 2 of 6 char bits)
    CALL  SYSVAR_OUTB               ;[0191] Merge with screen byte and write to all banks
    LD    BC,(SYSVAR_BPERL)         ;[0194] BC = bytes per line (32)
    ADD   HL,BC                     ;[0198] HL = next scan line's screen address
    INC   DE                        ;[0199] DE = next bitmap row
    POP   BC                        ;[019A] Restore line counter
    DJNZ  VIDEO_XPOS4A              ;[019B] Repeat for all 10 scan lines
    RET                             ;[019D]

;
; Slot 2, right byte (byte N+1) - draws the upper 2 bits of each bitmap row.
; The 6 bitmap bits span bytes N and N+1. Byte N+1 holds the top 2 bits of
; the character in screen bits 7-6. Shift bitmap RIGHT 2, then AND $C0
; keeps only those 2 bits. Mask $3F protects bits 5-0 of byte N+1
; (the 6 bits of the next character).
;
VIDEO_XPOS3B:
    LD    B,$0A                     ;[019E] 10 scan lines to draw
XX4:
    PUSH  BC                        ;[01A0] Save line counter
    LD    A,(SYSVAR_MASK)           ;[01A1] Get overwrite/transparent mask
    OR    $3F                       ;[01A4] Protect bits 5-0 (next character's bits)
    LD    C,A                       ;[01A6] C = protect mask for OUTB
    LD    A,(DE)                    ;[01A7] A = bitmap byte for this scan line
    RRCA                            ;[01A8] Shift bitmap right 2 to reach bits 7-6
    RRCA                            ;[01A9] 
    AND   $C0                       ;[01AA] Keep only bits 7-6 (top 2 of the 6 char bits)
    CALL  SYSVAR_OUTB               ;[01AC] Merge with screen byte and write to all banks
    LD    BC,(SYSVAR_BPERL)         ;[01AF] BC = bytes per line (32)
    ADD   HL,BC                     ;[01B3] HL = next scan line's screen address
    INC   DE                        ;[01B4] DE = next bitmap row
    POP   BC                        ;[01B5] Restore line counter
    DJNZ  XX4                       ;[01B6] Repeat for all 10 scan lines
    RET                             ;[01B8]

;
; Slot 2, left byte (byte N) - draws the lower 4 bits of each bitmap row.
; The 6 bitmap bits span bytes N and N+1. Byte N holds the bottom 4 bits
; of the character in screen bits 3-0. Shift bitmap RIGHT 2, then AND $0F
; keeps only those 4 bits. Mask $F0 protects bits 7-4 of byte N
; (the 4 bits belonging to the previous character at this slot).
;
VIDEO_XPOS3:
    LD    B,$0A                     ;[01B9] 10 scan lines to draw
VIDEO_XPOS3A:
    PUSH  BC                        ;[01BB] Save line counter
    LD    A,(SYSVAR_MASK)           ;[01BC] Get overwrite/transparent mask
    OR    $F0                       ;[01BF] Protect bits 7-4 (previous character's bits)
    LD    C,A                       ;[01C1] C = protect mask for OUTB
    LD    A,(DE)                    ;[01C2] A = bitmap byte for this scan line
    RRCA                            ;[01C3] Shift bitmap right 2 to reach bits 3-0
    RRCA                            ;[01C4] 
    AND   $0F                       ;[01C5] Keep only bits 3-0 (bottom 4 of 6 char bits)
    CALL  SYSVAR_OUTB               ;[01C7] Merge with screen byte and write to all banks
    LD    BC,(SYSVAR_BPERL)         ;[01CA] BC = bytes per line (32)
    ADD   HL,BC                     ;[01CE] HL = next scan line's screen address
    INC   DE                        ;[01CF] DE = next bitmap row
    POP   BC                        ;[01D0] Restore line counter
    DJNZ  VIDEO_XPOS3A              ;[01D1] Repeat for all 10 scan lines
    RET                             ;[01D3]

;
; Character bitmap table. Each character is defined as 10 bytes, one byte
; per scan line, read top-to-bottom. Within each byte, bits 5-0 are the
; 6 pixel columns (bit 5 = leftmost, bit 0 = rightmost). Bits 7-6 are
; always 0. The table covers ASCII $20 (space) through $7F (delete), then
; graphic block characters starting at $E0.
;
; These bitmaps are the default font; SYSVAR_CHRTBL can be pointed at a
; user-defined RAM table to replace them.
;
CHRTBS:
    DB    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00   ;[01D4] 
    DB    $00,$08,$08,$08,$08,$08,$00,$08,$00,$00   ;[01DE] !
    DB    $00,$0A,$0A,$00,$00,$00,$00,$00,$00,$00   ;[01E8] "
    DB    $00,$0A,$0A,$1F,$0A,$1F,$0A,$0A,$00,$00   ;[01F2] #
    DB    $00,$04,$0E,$14,$0E,$05,$15,$0E,$04,$00   ;[01FC] $
    DB    $00,$00,$18,$19,$02,$04,$08,$13,$03,$00   ;[0206] %
    DB    $00,$08,$14,$14,$08,$15,$12,$0D,$00,$00   ;[0210] &
    DB    $00,$0C,$04,$08,$00,$00,$00,$00,$00,$00   ;[021A] '
    DB    $00,$02,$04,$04,$04,$04,$04,$02,$00,$00   ;[0224] (
    DB    $00,$10,$08,$08,$08,$08,$08,$10,$00,$00   ;[022E] )
    DB    $00,$00,$00,$0A,$04,$1F,$04,$0A,$00,$00   ;[0238] *
    DB    $00,$00,$00,$04,$04,$1F,$04,$04,$00,$00   ;[0242] +
    DB    $00,$00,$00,$00,$00,$00,$18,$08,$10,$00   ;[024C] ,
    DB    $00,$00,$00,$00,$00,$1F,$00,$00,$00,$00   ;[0256] -
    DB    $00,$00,$00,$00,$00,$00,$0C,$0C,$00,$00   ;[0260] .
    DB    $00,$00,$01,$02,$04,$08,$10,$00,$00,$00   ;[026A] /
    DB    $00,$0E,$11,$13,$15,$19,$11,$0E,$00,$00   ;[0274] 0
    DB    $00,$04,$0C,$04,$04,$04,$04,$0E,$00,$00   ;[027E] 1
    DB    $00,$0E,$11,$01,$0E,$10,$10,$1F,$00,$00   ;[0288] 2
    DB    $00,$0E,$11,$01,$06,$01,$11,$0E,$00,$00   ;[0292] 3
    DB    $00,$10,$10,$12,$12,$1F,$02,$02,$00,$00   ;[029C] 4
    DB    $00,$1F,$10,$1E,$01,$01,$11,$0E,$00,$00   ;[02A6] 5
    DB    $00,$06,$08,$10,$1E,$11,$11,$0E,$00,$00   ;[02B0] 6
    DB    $00,$1F,$01,$02,$04,$08,$08,$08,$00,$00   ;[02BA] 7
    DB    $00,$0E,$11,$11,$0E,$11,$11,$0E,$00,$00   ;[02C4] 8
    DB    $00,$0E,$11,$11,$0F,$01,$02,$0C,$00,$00   ;[02CE] 9
    DB    $00,$00,$00,$18,$18,$00,$18,$18,$00,$00   ;[02D8] :
    DB    $00,$00,$00,$18,$18,$00,$18,$08,$10,$00   ;[02E2] ;
    DB    $00,$00,$00,$04,$08,$10,$08,$04,$00,$00   ;[02EC] <
    DB    $00,$00,$00,$00,$1E,$00,$1E,$00,$00,$00   ;[02F6] =
    DB    $00,$00,$00,$10,$08,$04,$08,$10,$00,$00   ;[0300] >
    DB    $00,$0E,$11,$01,$06,$04,$00,$04,$00,$00   ;[030A] ?
    DB    $00,$0E,$13,$15,$15,$16,$10,$0E,$00,$00   ;[0314] @
    DB    $00,$04,$0A,$11,$11,$1F,$11,$11,$00,$00   ;[031E] A
    DB    $00,$1E,$11,$1E,$11,$11,$11,$1E,$00,$00   ;[0328] B
    DB    $00,$0E,$11,$10,$10,$10,$11,$0E,$00,$00   ;[0332] C
    DB    $00,$1C,$12,$11,$11,$11,$11,$1E,$00,$00   ;[033C] D
    DB    $00,$1F,$10,$1E,$10,$10,$10,$1F,$00,$00   ;[0346] E
    DB    $00,$1F,$10,$1E,$10,$10,$10,$10,$00,$00   ;[0350] F
    DB    $00,$0E,$11,$10,$17,$11,$11,$0F,$00,$00   ;[035A] G
    DB    $00,$11,$11,$1F,$11,$11,$11,$11,$00,$00   ;[0364] H
    DB    $00,$0E,$04,$04,$04,$04,$04,$0E,$00,$00   ;[036E] I
    DB    $00,$0F,$02,$02,$02,$02,$12,$0C,$00,$00   ;[0378] J
    DB    $00,$11,$12,$14,$18,$14,$12,$11,$00,$00   ;[0382] K
    DB    $00,$10,$10,$10,$10,$10,$10,$1F,$00,$00   ;[038C] L
    DB    $00,$11,$1B,$15,$11,$11,$11,$11,$00,$00   ;[0396] M
    DB    $00,$11,$19,$15,$13,$11,$11,$11,$00,$00   ;[03A0] N
    DB    $00,$0E,$11,$11,$11,$11,$11,$0E,$00,$00   ;[03AA] O
    DB    $00,$1E,$11,$11,$1E,$10,$10,$10,$00,$00   ;[03B4] P
    DB    $00,$0E,$11,$11,$11,$15,$12,$0D,$00,$00   ;[03BE] Q
    DB    $00,$1E,$11,$11,$1E,$14,$12,$11,$00,$00   ;[03C8] R
    DB    $00,$0E,$11,$10,$0E,$01,$11,$0E,$00,$00   ;[03D2] S
    DB    $00,$1F,$04,$04,$04,$04,$04,$04,$00,$00   ;[03DC] T
    DB    $00,$11,$11,$11,$11,$11,$13,$0D,$00,$00   ;[03E6] U
    DB    $00,$11,$11,$11,$11,$11,$0A,$04,$00,$00   ;[03F0] V
    DB    $00,$11,$11,$11,$11,$15,$1B,$11,$00,$00   ;[03FA] W
    DB    $00,$11,$11,$0A,$04,$0A,$11,$11,$00,$00   ;[0404] X
    DB    $00,$11,$11,$0A,$04,$04,$04,$04,$00,$00   ;[040E] Y
    DB    $00,$1F,$01,$02,$04,$08,$10,$1F,$00,$00   ;[0418] Z
    DB    $00,$0E,$08,$08,$08,$08,$08,$0E,$00,$00   ;[0422] [
    DB    $00,$00,$10,$08,$04,$02,$01,$00,$00,$00   ;[042C] \
    DB    $00,$1C,$04,$04,$04,$04,$04,$1C,$00,$00   ;[0436] ]
    DB    $00,$03,$04,$09,$0A,$0A,$09,$04,$03,$00   ;[0440] ^
    DB    $00,$00,$00,$00,$00,$00,$00,$00,$00,$3F   ;[044A] _
    DB    $00,$06,$09,$08,$1E,$08,$08,$0F,$00,$00   ;[0454] `
    DB    $00,$00,$00,$0D,$13,$11,$11,$0F,$00,$00   ;[045E] a
    DB    $00,$10,$10,$16,$19,$11,$11,$1E,$00,$00   ;[0468] b
    DB    $00,$00,$00,$0E,$10,$10,$10,$0E,$00,$00   ;[0472] c
    DB    $00,$01,$01,$0D,$13,$11,$11,$0F,$00,$00   ;[047C] d
    DB    $00,$00,$00,$0E,$11,$1F,$10,$0E,$00,$00   ;[0486] e
    DB    $00,$06,$09,$08,$1E,$08,$08,$08,$00,$00   ;[0490] f
    DB    $00,$00,$00,$0D,$13,$11,$11,$0F,$01,$0E   ;[049A] g
    DB    $00,$10,$10,$16,$19,$11,$11,$11,$00,$00   ;[04A4] h
    DB    $00,$00,$04,$00,$04,$04,$04,$04,$00,$00   ;[04AE] i
    DB    $00,$00,$02,$00,$02,$02,$02,$02,$12,$0C   ;[04B8] j
    DB    $00,$10,$10,$12,$14,$1C,$12,$11,$00,$00   ;[04C2] k
    DB    $00,$08,$08,$08,$08,$08,$08,$06,$00,$00   ;[04CC] l
    DB    $00,$00,$00,$1A,$15,$15,$15,$15,$00,$00   ;[04D6] m
    DB    $00,$00,$00,$16,$19,$11,$11,$11,$00,$00   ;[04E0] n
    DB    $00,$00,$00,$0E,$11,$11,$11,$0E,$00,$00   ;[04EA] o
    DB    $00,$00,$00,$16,$19,$11,$11,$1E,$10,$10   ;[04F4] p
    DB    $00,$00,$00,$0D,$13,$11,$11,$0F,$01,$01   ;[04FE] q
    DB    $00,$00,$00,$16,$19,$10,$10,$10,$00,$00   ;[0508] r
    DB    $00,$00,$00,$0E,$10,$0E,$01,$0E,$00,$00   ;[0512] s
    DB    $00,$00,$08,$1F,$08,$08,$09,$06,$00,$00   ;[051C] t
    DB    $00,$00,$00,$11,$11,$11,$13,$0D,$00,$00   ;[0526] u
    DB    $00,$00,$00,$11,$11,$11,$0A,$04,$00,$00   ;[0530] v
    DB    $00,$00,$00,$11,$11,$15,$1B,$11,$00,$00   ;[053A] w
    DB    $00,$00,$00,$11,$0A,$04,$0A,$11,$00,$00   ;[0544] x
    DB    $00,$00,$00,$11,$11,$11,$11,$0F,$01,$0E   ;[054E] y (descender in rows 9-10)
    DB    $00,$00,$00,$1F,$02,$04,$08,$1F,$00,$00   ;[0558] z
    DB    $00,$00,$00,$04,$02,$1F,$02,$04,$00,$00   ;[0562] { (left arrow - Lynx uses braces as arrows)
    DB    $00,$00,$00,$04,$08,$1F,$08,$04,$00,$00   ;[056C] | (right arrow)
    DB    $00,$00,$00,$04,$0E,$15,$04,$04,$00,$00   ;[0576] } (up arrow)
    DB    $00,$00,$00,$04,$04,$15,$0E,$04,$00,$00   ;[0580] ~ (down arrow)
    DB    $00,$30,$08,$24,$04,$04,$24,$08,$30,$00   ;[058A] DEL ($7F) - displayed as a crossed-circle symbol
;
; Graphic character bitmaps ($E0-$F9). Each is 10 bytes like the alpha chars.
;
; $E0-$EF: 16 block-fill patterns. Each character cell is divided into a
; top half (rows 1-5) and a bottom half (rows 6-10), and within each half
; into a left sub-block (bits 5-3, value $38 = 111000b) and a right sub-block
; (bits 2-0, value $07 = 000111b). The 16 patterns cover all combinations
; of top-left, top-right, bottom-left, bottom-right being filled or empty,
; making them suitable for low-resolution block graphics.
;
; $F0-$F2: Texture fill patterns (checkerboard and horizontal stripes).
;
; $F3-$F9: Seven tiles that together form the "Lynx" startup logo graphic.
;
    DB    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00   ;[0594] $E0 - blank
    DB    $38,$38,$38,$38,$38,$00,$00,$00,$00,$00   ;[059E] $E1 - top-left filled
    DB    $07,$07,$07,$07,$07,$00,$00,$00,$00,$00   ;[05A8] $E2 - top-right filled
    DB    $3F,$3F,$3F,$3F,$3F,$00,$00,$00,$00,$00   ;[05B2] $E3 - top half fully filled
    DB    $00,$00,$00,$00,$00,$38,$38,$38,$38,$38   ;[05BC] $E4 - bottom-left filled
    DB    $38,$38,$38,$38,$38,$38,$38,$38,$38,$38   ;[05C6] $E5 - left half filled (full height)
    DB    $07,$07,$07,$07,$07,$38,$38,$38,$38,$38   ;[05D0] $E6 - top-right + bottom-left filled
    DB    $3F,$3F,$3F,$3F,$3F,$38,$38,$38,$38,$38   ;[05DA] $E7 - top full + bottom-left filled
    DB    $00,$00,$00,$00,$00,$07,$07,$07,$07,$07   ;[05E4] $E8 - bottom-right filled
    DB    $38,$38,$38,$38,$38,$07,$07,$07,$07,$07   ;[05EE] $E9 - top-left + bottom-right filled
    DB    $07,$07,$07,$07,$07,$07,$07,$07,$07,$07   ;[05F8] $EA - right half filled (full height)
    DB    $3F,$3F,$3F,$3F,$3F,$07,$07,$07,$07,$07   ;[0602] $EB - top full + bottom-right filled
    DB    $00,$00,$00,$00,$00,$3F,$3F,$3F,$3F,$3F   ;[060C] $EC - bottom half fully filled
    DB    $38,$38,$38,$38,$38,$3F,$3F,$3F,$3F,$3F   ;[0616] $ED - top-left + bottom full filled
    DB    $07,$07,$07,$07,$07,$3F,$3F,$3F,$3F,$3F   ;[0620] $EE - top-right + bottom full filled
    DB    $3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F   ;[062A] $EF - fully filled solid block
    DB    $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A   ;[0634] $F0 - fine checkerboard (101010 every row)
    DB    $3F,$00,$3F,$00,$3F,$00,$3F,$00,$3F,$00   ;[063E] $F1 - horizontal stripes (alternate full/empty)
    DB    $2A,$15,$2A,$15,$2A,$15,$2A,$15,$2A,$15   ;[0648] $F2 - diagonal weave (101010 / 010101 alternating)
;
; Lynx startup logo tiles ($F3-$F9).
; These 7 graphic characters tile together horizontally to display the
; "Lynx" wordmark on the startup/boot screen.
;
    DB    $1E,$08,$08,$08,$08,$08,$08,$1F,$00,$00   ;[0652] $F3 - logo tile 1 (left edge of 'L')
    DB    $3B,$11,$0A,$04,$04,$24,$24,$2E,$00,$00   ;[065C] $F4 - logo tile 2
    DB    $38,$0C,$0A,$09,$08,$08,$08,$1C,$00,$00   ;[0666] $F5 - logo tile 3
    DB    $3F,$12,$11,$10,$30,$11,$12,$17,$00,$00   ;[0670] $F6 - logo tile 4
    DB    $1C,$08,$10,$20,$20,$10,$08,$1C,$00,$00   ;[067A] $F7 - logo tile 5
    DB    $03,$1B,$18,$00,$37,$37,$07,$07,$00,$00   ;[0684] $F8 - logo tile 6
    DB    $00,$00,$18,$18,$00,$00,$00,$00,$00,$00   ;[068E] $F9 - logo tile 7 (rightmost)

;
; Set ink colour (VDU 1). Called from SCREEN when SYSVAR_LASTDSP decrements
; to 1, meaning the previous byte was the VDU 1 command and A holds the
; ink colour argument. Stores the colour in SYSVAR_INKST, clears (HL)
; (the LASTDSP counter, setting it back to 0), then exits SCREEN.
;
SETINK:
    LD    (SYSVAR_INKST),A          ;[0698] Store new ink colour
INKPAPER_EXIT:
    LD    (HL),$00                  ;[069B] Clear LASTDSP (command consumed)
    JR    SCREEN_END                ;[069D] Return through SCREEN's register-restore exit

;
; Set paper colour (VDU 2). Same mechanism as SETINK; called when
; SYSVAR_LASTDSP decrements to 0 after receiving a VDU 2 + argument pair.
;
SETPAPER:
    LD    (SYSVAR_PAPST),A          ;[069F] Store new paper colour
    JR    INKPAPER_EXIT             ;[06A2]

;
; Main display/character output driver. <DISPLAY.MAC: D$SCRN>
; This is the top-level output routine; all BASIC PRINT output, VDU commands,
; and direct screen writes pass through here via RST $08 -> PUTCHAR -> SCREEN.
;
; Characters >= $20 are printed at the current cursor position via SYSVAR_VIDEO
; and the cursor is then advanced. The cursor character (CURCHR) is redrawn
; after every character if SYSVAR_CURSTAT (cursor on/off flag) is non-zero.
;
; Characters < $20 are VDU control codes dispatched through SCREEN_TBL.
; Two-byte VDU sequences (VDU 1 = ink, VDU 2 = paper) are handled by
; incrementing SYSVAR_LASTDSP so that the next call captures the argument
; byte and routes it to SETINK or SETPAPER.
;
SCREEN:
    PUSH  AF                        ;[06A4] Save all registers - SCREEN must be non-destructive
    PUSH  HL                        ;[06A5] 
    PUSH  DE                        ;[06A6] 
    PUSH  BC                        ;[06A7] 
    LD    HL,SYSVAR_LASTDSP         ;[06A8] HL -> pending VDU argument counter
    DEC   (HL)                      ;[06AB] Decrement: if a 2-byte VDU was in progress...
    JR    Z,SETINK                  ;[06AC] ...counter hit 1: this byte is the INK argument
    DEC   (HL)                      ;[06AE] Decrement again...
    JR    Z,SETPAPER                ;[06AF] ...counter hit 0 (wrapped): this is PAPER argument
    LD    (HL),A                    ;[06B1] Not a pending argument: store char as new LASTDSP
    CP    $20                       ;[06B2] Is it a control code (< space)?
    JR    C,OUTB_OR_VDU             ;[06B4] Yes - handle as VDU command
    CALL  SYSVAR_VIDEO              ;[06B6] No - draw the printable character at cursor
    CALL  ADV_CURSOR                ;[06B9] Advance cursor one character position
    LD    (SYSVAR_CURSORX),DE       ;[06BC] Save updated cursor X/Y position
SCREEN2:
    LD    A,(SYSVAR_CURSTAT)        ;[06C0] Is the cursor currently visible?
    OR    A                         ;[06C3] 
    LD    A,CURCHR                  ;[06C4] Load cursor character code
    CALL  NZ,SYSVAR_VIDEO           ;[06C6] If cursor on: redraw cursor at new position
SCREEN_END:
    POP   BC                        ;[06C9] Restore all registers
    POP   DE                        ;[06CA] 
    POP   HL                        ;[06CB] 
    POP   AF                        ;[06CC] 
NULL:
    RET                             ;[06CD] (NULL also used as a no-op VDU handler)

;
; Handle control characters (A < $20) and two-byte VDU sequences.
; If the cursor is currently shown, first erase it by printing a space at
; the current position. Then dispatch through SCREEN_TBL using A as index.
; On return from the VDU handler, execution resumes at SCREEN2 (which
; redraws the cursor if enabled).
;
OUTB_OR_VDU:
    PUSH  AF                        ;[06CE] Save control code
    LD    A,(SYSVAR_CURSTAT)        ;[06CF] Is cursor visible?
    OR    A                         ;[06D2] 
    LD    A,' '                     ;[06D3] Load space (to erase cursor graphic)
    CALL  NZ,SYSVAR_VIDEO           ;[06D5] If cursor on: erase it before processing VDU
    POP   AF                        ;[06D8] Restore control code
    LD    HL,SCREEN2                ;[06D9] Push SCREEN2 as return address so VDU handlers
    PUSH  HL                        ;[06DC] return via SCREEN2 (which redraws cursor)
    LD    HL,SCREEN_TBL             ;[06DD] HL -> VDU dispatch table
    RLCA                            ;[06E0] A * 2 (each table entry is a 2-byte address)
    LD    E,A                       ;[06E1] 
    LD    D,$00                     ;[06E2] DE = byte offset into table
    ADD   HL,DE                     ;[06E4] HL -> table entry for this VDU code
    LD    A,(HL)                    ;[06E5] Load low byte of handler address
    INC   HL                        ;[06E6] 
    LD    H,(HL)                    ;[06E7] Load high byte of handler address
    LD    L,A                       ;[06E8] HL = handler address
    JP    (HL)                      ;[06E9] Jump to VDU handler (returns via SCREEN2)

;
; VDU control code dispatch table. Each entry is a 2-byte handler address.
; VDU codes with no function point to NULL (a plain RET).
; VDU 1 (ink) and VDU 2 (paper) are two-byte sequences: the command byte
; sets SYSVAR_LASTDSP so the argument byte on the next call is routed to
; SETINK or SETPAPER directly, bypassing this table entirely.
;
SCREEN_TBL:
    DW    NULL                      ;[06EA] VDU  0 - null (ignored)
    DW    NULL                      ;[06EC] VDU  1 - INK colour (argument byte follows)
    DW    NULL                      ;[06EE] VDU  2 - PAPER colour (argument byte follows)
    DW    NULL                      ;[06F0] VDU  3 - unused
    DW    SCREEN_CLEAR              ;[06F2] VDU  4 - clear screen and home cursor
    DW    SCREEN_UP_ONE             ;[06F4] VDU  5 - cursor up 1 pixel
    DW    SCREEN_DOWN_ONE           ;[06F6] VDU  6 - cursor down 1 pixel
    DW    SCREEN_BELL               ;[06F8] VDU  7 - bell (BEEP)
    DW    SCREEN_BACKSPACE          ;[06FA] VDU  8 - backspace (cursor left one char)
    DW    SCREEN_TAB                ;[06FC] VDU  9 - tab to next field
    DW    SCREEN_LF                 ;[06FE] VDU 10 - line feed (cursor down 10 pixels)
    DW    NULL                      ;[0700] VDU 11 - unused
    DW    PATCH1                    ;[0702] VDU 12 - (patched entry - see PATCH1)
    DW    SCREEN_CRLF               ;[0704] VDU 13 - carriage return + line feed
    DW    SCREEN_CURS_ON            ;[0706] VDU 14 - cursor on
    DW    SCREEN_CURS_OFF           ;[0708] VDU 15 - cursor off
    DW    SCREEN_TOP                ;[070A] VDU 16 - move cursor to top of window
    DW    NULL                      ;[070C] VDU 17 - unused
    DW    SCREEN_INVERT             ;[070E] VDU 18 - swap ink and paper colours
    DW    SCREEN_BEGIN              ;[0710] VDU 19 - CR+LF only if not at start of line
    DW    SCREEN_MASK               ;[0712] VDU 20 - overwrite mode on  (SYSVAR_MASK = $00)
    DW    SCREEN_MASK+$02           ;[0714] VDU 21 - overwrite mode off (SYSVAR_MASK = $FF)
    DW    SCREEN_BACK_CURS          ;[0716] VDU 22 - cursor left one character
    DW    SCREEN_HOME               ;[0718] VDU 23 - home cursor (to top-left of window)
    DW    SCREEN_DOUBLE_ON          ;[071A] VDU 24 - double-height characters on
    DW    SCREEN_DOUBLE_OFF         ;[071C] VDU 25 - double-height characters off
    DW    NULL                      ;[071E] VDU 26 - unused
    DW    NULL                      ;[0720] VDU 27 - unused (reserved for ESC)
    DW    SCREEN_HA_LF_UP           ;[0722] VDU 28 - cursor up 3 pixels (half line feed up)
    DW    SCREEN_HA_LF              ;[0724] VDU 29 - cursor down 3 pixels (half line feed)
    DW    SCREEN_CLEAR_EOL          ;[0726] VDU 30 - clear to end of line
    DW    SCREEN_CRLF               ;[0728] VDU 31 - carriage return + line feed

;
; Turns double height characters on (VDU 24).
; Sets SYSVAR_BPERL to $40 (64), meaning 64 bytes per displayed row.
; In double-height mode each character cell is printed twice (top and bottom
; halves), so the effective column pitch doubles from the normal 32 columns.
;
SCREEN_DOUBLE_ON:
    LD    A,$40                     ;[072A] 64 bytes per row (double height: 32 cols * 2 bytes each)
SCREEN_SET_BPERL:
    LD    (SYSVAR_BPERL),A          ;[072C] Update bytes-per-line system variable
    RET                             ;[072F] 

;
; Turns double height characters off (VDU 25).
; Restores SYSVAR_BPERL to $20 (32), the normal single-height value.
;
SCREEN_DOUBLE_OFF:
    LD    A,$20                     ;[0730] 32 bytes per row (normal height: 32 columns)
    JR    SCREEN_SET_BPERL          ;[0732] Share tail of SCREEN_DOUBLE_ON

;
; Overwrite mode on (VDU 20).
; Clears SYSVAR_MASK to $00 so that character pixels are OR'd into video RAM
; without preserving existing pixels underneath.  The instruction sequence is
; self-modifying: the byte at SCREEN_MASK+$02 is the immediate operand of the
; LD A,n that follows, so patching it to $FF switches to overwrite mode off
; (VDU 21) without a separate routine.
;
SCREEN_MASK:
    XOR   A                         ;[0734] A = $00 (transparent/overwrite-on mask)
    LD    BC,$FF3E                  ;[0735] B=$FF (mask-off value stored here), C=$3E (LD A,n opcode)
                                    ;       NB: SCREEN_MASK+$02 is the LD A,$FF for VDU 21
    LD    (SYSVAR_MASK),A           ;[0738] Store mask: $00 = OR mode (pixels set, never cleared)
    RET                             ;[073B] 

;
; Swaps ink and paper colours (VDU 18).
; Exchanges the values of SYSVAR_INKST and SYSVAR_PAPST by loading both as a
; 16-bit word (L=ink, H=paper), swapping L and H in registers, then writing
; them back.
;
SCREEN_INVERT:
    LD    HL,(SYSVAR_INKST)         ;[073C] L = ink colour, H = paper colour
    LD    A,L                       ;[073F] A = ink
    LD    L,H                       ;[0740] L = paper (will become new ink location)
    LD    H,A                       ;[0741] H = ink  (will become new paper location)
    LD    (SYSVAR_INKST),HL         ;[0742] Write back swapped: ink<->paper
    RET                             ;[0745] 

;
; Advance cursor one character to the right.
; Characters are 6 pixels wide.  The cursor X coordinate is in units of 2 pixels
; (one X unit = 2 pixels), so a 6-pixel character occupies 3 X units.
; ADV_CURSOR adds 3 to X to step one column.  The screen is 256 pixels wide
; (128 X units).  The default window spans KWNDLF=3 to KWNDRT=123, giving
; 120 X units = 40 columns of 6 pixels each.
; If the new X position would exceed the right edge of the window the cursor
; wraps to the left edge and tries to advance one text row down.
;
ADV_CURSOR:
    LD    HL,(SYSVAR_WINDST)        ;[0746] HL: L = window left X, H = window right X
    LD    DE,(SYSVAR_CURSORX)       ;[0749] D = cursor Y, E = cursor X
    LD    A,E                       ;[074D] A = current X
    ADD   A,$03                     ;[074E] Advance 3 X units (= 6 pixels = one character column)
    LD    E,A                       ;[0750] E = new X
    CP    H                         ;[0751] Reached or passed right edge of window?
    RET   C                         ;[0752] No: return with updated E
    LD    E,L                       ;[0753] Yes: wrap X back to left edge of window
ADV_CURSOR1:
    LD    HL,(SYSVAR_WINDST+$02)    ;[0754] HL: L = window top Y, H = window bottom Y
    LD    A,D                       ;[0757] A = current Y
    CALL  SYSVAR_SLFRAM             ;[0758] Call scroll/line-feed hook (may scroll screen up)
    ADD   A,$0A                     ;[075B] Advance 10 pixels (one character row)
ADV_CURSOR2:
    LD    D,A                       ;[075D] D = new Y
    CP    H                         ;[075E] Reached or passed bottom of window?
    RET   C                         ;[075F] No: return
    LD    D,L                       ;[0760] Yes: clamp Y to window top
    RET                             ;[0761] 

;
; Clears the screen and homes the cursor (VDU 4).
; Falls through into SCREEN_HOME.
;
SCREEN_CLEAR:
    CALL  _CLS                      ;[0762] Erase all three colour planes

;
; Homes the cursor to the top-left corner of the window (VDU 23).
; Falls through into SCREEN_TOP after setting X to the left edge.
;
SCREEN_HOME:
    CALL  SCREEN_CR                 ;[0765] Set cursor X to window left edge

;
; Moves cursor Y to the top of the window (VDU 16).
;
SCREEN_TOP:
    LD    A,(SYSVAR_WINDST+$02)     ;[0768] Window top Y coordinate
    LD    (SYSVAR_CURSORY),A        ;[076B] Set cursor Y to top of window
    RET                             ;[076E] 

;
; Carriage return + line feed only if the cursor is not already at the
; beginning of the line (VDU 19).
; Useful for ensuring output always starts at a fresh line without emitting
; a redundant blank line when the cursor is already at column 0.
;
SCREEN_BEGIN:
    LD    HL,(SYSVAR_WINDST)        ;[076F] L = window left X
    LD    A,(SYSVAR_CURSORX)        ;[0772] Current cursor X
    CP    L                         ;[0775] Already at left edge?
    RET   Z                         ;[0776] Yes: nothing to do
    LD    A,$0D                     ;[0777] No: emit CR (VDU 13) to go to start of next line
    RST   $08                       ;[0779] Output character via SCREEN handler
    RET                             ;[077A] 

;
; Carriage return + line feed, clearing to end of line (VDU 13 / VDU 31).
; Resets X to the left window edge via SCREEN_CR, then falls through to
; SCREEN_LF to advance Y by one text row.
;
SCREEN_CRLF:
    CALL  SCREEN_CR                 ;[077B] Move X to left edge of window

;
; Line feed: advances the cursor down by one full character row (10 pixels)
; (VDU 10).
;
SCREEN_LF:
    LD    DE,(SYSVAR_CURSORX)       ;[077E] D = cursor Y, E = cursor X
    CALL  ADV_CURSOR1               ;[0782] Advance Y by 10 pixels, scroll if needed
    JR    SAVE_CURSORX              ;[0785] Store updated cursor position

;
; Moves cursor down by exactly 1 pixel (VDU 6).
;
SCREEN_DOWN_ONE:
    LD    C,$01                     ;[0787] Step = 1 pixel
    JR    SCREEN_HA_LF1             ;[0789] 

;
; Half line feed downward: moves cursor down 3 pixels (VDU 29).
; Shares the body of SCREEN_HA_LF1 with SCREEN_DOWN_ONE.
;
SCREEN_HA_LF:
    LD    C,$03                     ;[078B] Step = 3 pixels (half a character row)
SCREEN_HA_LF1:
    LD    DE,(SYSVAR_CURSORX)       ;[078D] D = cursor Y, E = cursor X
    LD    HL,(SYSVAR_WINDST+$02)    ;[0791] HL: L = window top Y, H = window bottom Y
    LD    A,D                       ;[0794] A = current Y
    ADD   A,C                       ;[0795] Add step (1 or 3 pixels)
    CALL  ADV_CURSOR2               ;[0796] Clamp to window bottom, update D
    JR    SAVE_CURSORX              ;[0799] Store updated cursor position

;
; Carriage return: moves cursor X to the leftmost column of the window.
; Does NOT advance Y; used as the 'CR' part of CRLF sequences.
;
SCREEN_CR:
    LD    A,(SYSVAR_WINDST)         ;[079B] Window left X coordinate
    LD    (SYSVAR_CURSORX),A        ;[079E] Set cursor X to left edge
    RET                             ;[07A1] 

;
; Tab to the next tab stop (VDU 9).
; Tab stops are defined by TBLE1 below: 27, 51, 75, 99 pixel positions (every
; 24 pixels, roughly every 8 characters in normal mode).  Spaces are printed
; until the cursor reaches the next stop.  If no stop is found (value = $FF
; sentinel) the cursor wraps to the next line.
;
SCREEN_TAB:
    LD    A,(SYSVAR_CURSORX)        ;[07A2] Current cursor X
    INC   A                         ;[07A5] Look for a stop strictly to the right
    LD    HL,TBLE1-1                ;[07A6] Point one before table so first INC HL hits entry 0
SCREEN_TAB1:
    INC   HL                        ;[07A9] Advance to next table entry
    CP    (HL)                      ;[07AA] Is cursor X < this tab stop?
    JR    NC,SCREEN_TAB1            ;[07AB] No: try next stop
    LD    H,(HL)                    ;[07AD] H = tab stop pixel value
    INC   H                         ;[07AE] Was it the $FF sentinel (past last real stop)?
    JR    Z,SCREEN_CRLF             ;[07AF] Yes: wrap to next line
    DEC   H                         ;[07B1] Restore actual tab stop value into H
SCREEN_TAB12:
    LD    A,' '                     ;[07B2] Print a space to advance cursor
    RST   $08                       ;[07B4] Output space character
    LD    A,(SYSVAR_CURSORX)        ;[07B5] Re-read X (RST $08 advances it)
    CP    H                         ;[07B8] Reached the tab stop?
    RET   NC                        ;[07B9] Yes (or overshot): done
    JR    SCREEN_TAB12              ;[07BA] No: print another space

;
; Tab stop table (pixel X positions of the four tab stops).
; $FF acts as a sentinel meaning "wrap to next line".
;
TBLE1:
    DB    27,51,75,99,255           ;[07BC] Tab stops at pixel columns 27, 51, 75, 99

;
; Clears from the current cursor position to the right edge of the window
; line by printing spaces (VDU 30).
; Preserves the original cursor X on the stack and restores it afterwards
; via SAVE_CURSORX so the visible cursor does not move after the clear.
;
SCREEN_CLEAR_EOL:
    LD    A,(SYSVAR_WINDST+$01)     ;[07C1] Window right edge X (exclusive)
    DEC   A                         ;[07C4] Last valid column pixel
    LD    HL,(SYSVAR_CURSORX)       ;[07C5] HL: H = cursor Y, L = cursor X
    PUSH  HL                        ;[07C8] Save original cursor position to restore later
SCREEN_CLEAR_EOL_LOOP:
    LD    (SYSVAR_CURSORX),HL       ;[07C9] Position cursor at current column
    PUSH  HL                        ;[07CC] Save position across SYSVAR_VIDEO call
    PUSH  AF                        ;[07CD] Save right-edge value
    LD    A,$20                     ;[07CE] Space character
    CALL  SYSVAR_VIDEO              ;[07D0] Draw space at current cursor position
    POP   AF                        ;[07D3] Restore right-edge value
    POP   HL                        ;[07D4] Restore current position
    INC   L                         ;[07D5] Advance to next column (3 X units = 6 pixels = one char cell)
    INC   L                         ;[07D6] 
    INC   L                         ;[07D7] 
    CP    L                         ;[07D8] Reached or passed right edge?
    JR    NC,SCREEN_CLEAR_EOL_LOOP  ;[07D9] No: continue clearing
    POP   DE                        ;[07DB] Restore original cursor position into DE
    JR    SAVE_CURSORX              ;[07DC] Write saved position back to SYSVAR_CURSORX

;
; Moves the cursor one character to the left (backspace) without erasing
; the character under the cursor (VDU 22).
;
SCREEN_BACK_CURS:
    CALL  SUB_BACKSPACE             ;[07DE] Calculate new cursor position in DE
SAVE_CURSORX:
    LD    (SYSVAR_CURSORX),DE       ;[07E1] Store updated cursor X and Y
    RET                             ;[07E5] 

;
; Calculates the cursor position one character to the left of the current
; position, returning the result in DE.  Handles wrap-around from the left
; edge of the window to the end of the line above.
; Each character is 6 pixels wide (3 X units), so three DECs on E step back one column.
; If wrapping past the left edge, E is set to the window right edge minus 3
; and D (Y) is decremented by 10 pixels (one row).
;
SUB_BACKSPACE:
    LD    HL,(SYSVAR_WINDST)        ;[07E6] L = window left X, H = window right X
    LD    DE,(SYSVAR_CURSORX)       ;[07E9] D = cursor Y, E = cursor X
    DEC   L                         ;[07ED] L = window left X - 1 (used as wrap sentinel)
    LD    B,$03                     ;[07EE] 3 X units per character (= 6 pixels)
SUB_BACKSPACE1:
    DEC   E                         ;[07F0] Step cursor X back one pixel
    LD    A,E                       ;[07F1] 
    CP    L                         ;[07F2] Passed the left edge - 1?
    JR    Z,SUB_BACKSPACE2          ;[07F3] Yes: need to wrap to previous line
    DJNZ  SUB_BACKSPACE1            ;[07F5] Repeat 3 times (one full column)
    RET                             ;[07F7] No wrap needed: return with updated E

SUB_BACKSPACE2:
    LD    E,H                       ;[07F8] E = window right X (start from right of line above)
    DEC   E                         ;[07F9] 
    DEC   E                         ;[07FA] 
    DEC   E                         ;[07FB] E = right edge - 3 (last character column)
    LD    HL,(SYSVAR_WINDST+$02)    ;[07FC] L = window top Y, H = window bottom Y
    LD    A,D                       ;[07FF] A = current Y
    SUB   $0A                       ;[0800] Move up one row (10 pixels)
SUB_BACKSPACE3:
    LD    D,A                       ;[0802] D = new Y
    SUB   L                         ;[0803] A = new Y - window top Y
    CP    $F6                       ;[0804] Is new Y above window top? ($F6 = -10 wrapped)
    RET   C                         ;[0806] Yes: clamp at top (return as-is)
    LD    A,H                       ;[0807] A = window bottom Y
    SUB   $0A                       ;[0808] One row up from the bottom
    LD    D,A                       ;[080A] D = bottom row of window
    RET                             ;[080B] 

;
; Moves cursor up by exactly 1 pixel (VDU 5).
;
SCREEN_UP_ONE:
    LD    C,$01                     ;[080C] Step = 1 pixel
    JR    SCREEN_HA_LF_UP1          ;[080E] 

;
; Half line feed upward: moves cursor up 3 pixels (VDU 28).
; Mirrors SCREEN_HA_LF but in the upward direction.
;
SCREEN_HA_LF_UP:
    LD    C,$03                     ;[0810] Step = 3 pixels
SCREEN_HA_LF_UP1:
    LD    DE,(SYSVAR_CURSORX)       ;[0812] D = cursor Y, E = cursor X
    LD    HL,(SYSVAR_WINDST+$02)    ;[0816] Window top/bottom Y
    LD    A,D                       ;[0819] Current Y
    SUB   C                         ;[081A] Subtract step (move upward)
    CALL  SUB_BACKSPACE3            ;[081B] Clamp to window top, handle underflow
    JR    SAVE_CURSORX              ;[081E] Store updated position

;
; Backspace and erase: moves cursor one character left then overwrites the
; vacated cell with a space (VDU 8).
;
SCREEN_BACKSPACE:
    CALL  SCREEN_BACK_CURS          ;[0820] Move cursor left one character
    LD    A,$20                     ;[0823] Space character to erase with
    JP    SYSVAR_VIDEO              ;[0825] Draw space at new cursor position (tail call)

;
; Turns the cursor on (VDU 14).  Sets SYSVAR_CURSTAT to 1.
;
SCREEN_CURS_ON:
    LD    A,$01                     ;[0828] 1 = cursor visible
GET_CURSTAT:
    LD    (SYSVAR_CURSTAT),A        ;[082A] Store cursor on/off state
    RET                             ;[082D] 

;
; Turns the cursor off (VDU 15).  Sets SYSVAR_CURSTAT to 0.
;
SCREEN_CURS_OFF:
    XOR   A                         ;[082E] A = 0 = cursor hidden
    JR    GET_CURSTAT               ;[082F] Share tail of SCREEN_CURS_ON

;
; WINDOW command handler.
; Reads four consecutive byte arguments (left X, right X, top Y, bottom Y)
; from the expression evaluator and stores them directly into the four bytes
; of SYSVAR_WINDST.  B counts down from 4 to 0.
;
EWINDOW:
    LD    B,$04                     ;[0831] 4 bytes to read
    LD    HL,SYSVAR_WINDST          ;[0833] Destination: window bounds system variable
EWINDOW1:
    PUSH  HL                        ;[0836] Save destination pointer
    PUSH  BC                        ;[0837] Save loop counter
    CALL  EINT                      ;[0838] Evaluate next integer argument into HL
    INC   DE                        ;[083B] Advance past delimiter in token stream
    LD    A,L                       ;[083C] Low byte of integer result
    POP   BC                        ;[083D] Restore loop counter
    POP   HL                        ;[083E] Restore destination pointer
    LD    (HL),A                    ;[083F] Store byte into SYSVAR_WINDST[0..3]
    INC   HL                        ;[0840] Advance destination pointer
    DJNZ  EWINDOW1                  ;[0841] Repeat for all 4 bytes
    RET                             ;[0843] 

;
; Determines which pixel mask bits need to be set or cleared for a character
; cell byte, used during character output (OUTB).
; The alternate HL register pair (HL') holds the pixel shift amount; the
; result is placed in D (data) based on whether ink or paper colour applies
; to each bit pair.
; On entry: D = data byte, E = mask byte, HL' = scroll shift.
; Returns with D updated for the colour plane being written.
;
OUTB_BIT_SET:
    EXX                             ;[0844] Switch to alternate registers (HL' = shift)
    XOR   A                         ;[0845] Clear A to accumulate 2-bit colour selector
    SRL   H                         ;[0846] Shift MSB of H' into carry
    ADC   A,A                       ;[0848] Bit 1 of selector = H' carry
    SRL   L                         ;[0849] Shift MSB of L' into carry
    ADC   A,A                       ;[084B] Bit 0 of selector = L' carry; A = 0..3
    EXX                             ;[084C] Restore main registers
    JR    Z,OUTB_BIT_SET2           ;[084D] A=0: both bits clear -> use paper (D=0)
    DEC   A                         ;[084F] 
    RET   Z                         ;[0850] A was 1: ink bit set for this plane -> D unchanged (ink)
    DEC   A                         ;[0851] 
    JR    Z,OUTB_BIT_SET1           ;[0852] A was 2: OR ink+paper bits
    LD    A,$FF                     ;[0854] A was 3: both set -> invert mask
    XOR   E                         ;[0856] D = NOT(mask) XOR data
    LD    D,A                       ;[0857] 
    RET                             ;[0858] 

OUTB_BIT_SET1:
    LD    A,D                       ;[0859] Combine data and mask for mixed ink/paper
    OR    E                         ;[085A] 
    CPL                             ;[085B] Complement: clears bits that are both data and mask
OUTB_BIT_SET2:
    LD    D,A                       ;[085C] Store result as new data byte
    RET                             ;[085D] 

;
; Outputs one byte of character pixel data to all three colour planes (BLUE,
; RED, GREEN), respecting the current INK and PAPER colours and the protection
; mask stored in SYSVAR_PROTST.
;
; Entry:  A  = pixel data byte (1 bits = foreground / ink pixels)
;         C  = mask byte       (1 bits = pixels to update in this cell)
;         HL = relative byte offset from the top-left of the screen buffer
;
; SYSVAR_PROTST bits control which planes are written:
;   bit 0 = protect BLUE  (skip if set)
;   bit 1 = protect RED   (skip if set)
;   bit 2 = protect GREEN (skip if set)
;
OUTB:
    EXX                             ;[085E] Preserve main HL/BC/DE in alternate set
    EX    AF,AF'                    ;[085F] Swap to alternate AF
    PUSH  AF                        ;[0860] Save alternate AF
    EX    AF,AF'                    ;[0861] Restore main AF (pixel data)
    PUSH  HL                        ;[0862] Save screen offset HL
    LD    HL,(SYSVAR_INKST)         ;[0863] H' = paper colour byte, L' = ink colour byte
    EXX                             ;[0866] HL' now holds ink/paper; restore main regs
    PUSH  DE                        ;[0867] Save caller's DE
    LD    E,C                       ;[0868] E = mask byte
    LD    D,A                       ;[0869] D = pixel data byte
OUTB_BLUE:
    PUSH  DE                        ;[086A] Save data/mask for this plane
    CALL  OUTB_BIT_SET              ;[086B] Compute colour-masked data byte for BLUE plane
    LD    A,(SYSVAR_PROTST)         ;[086E] Check protection bits
    RRCA                            ;[0871] Bit 0 -> carry: is BLUE plane protected?
    JR    C,OUTB_RED                ;[0872] Yes: skip writing to BLUE
    LD    A,$E8                     ;[0874] Page-out opcode for BLUE bank select port
    EX    AF,AF'                    ;[0876] A' = $E8 (bank select value)
    LD    A,$63                     ;[0877] A = $63 (bank enable value)
    LD    BC,(SYSVAR_BLUBNK)        ;[0879] BC = start address of BLUE video bank
    CALL  OUT_TO_BANK               ;[087D] Write byte to BLUE plane at HL+BC
OUTB_RED:
    POP   DE                        ;[0880] Restore data/mask
    PUSH  DE                        ;[0881] Save again for GREEN
    CALL  OUTB_BIT_SET              ;[0882] Compute colour-masked data byte for RED plane
    LD    A,(SYSVAR_PROTST)         ;[0885] Check protection bits
    BIT   1,A                       ;[0888] Is RED plane protected?
    JR    NZ,OUTB_GREEN             ;[088A] Yes: skip writing to RED
    LD    A,$E8                     ;[088C] Bank select port value for RED
    EX    AF,AF'                    ;[088E] A' = $E8
    LD    A,$63                     ;[088F] A = $63 (bank enable)
    LD    BC,(SYSVAR_REDBNK)        ;[0891] BC = start address of RED video bank
    CALL  OUT_TO_BANK               ;[0895] Write byte to RED plane at HL+BC
OUTB_GREEN:
    POP   DE                        ;[0898] Restore data/mask for GREEN
    CALL  OUTB_BIT_SET              ;[0899] Compute colour-masked data byte for GREEN plane
    LD    A,(SYSVAR_PROTST)         ;[089C] Check protection bits
    BIT   2,A                       ;[089F] Is GREEN plane protected?
    JR    NZ,OUTB_END               ;[08A1] Yes: skip writing to GREEN
    LD    A,$E4                     ;[08A3] Bank select port value for GREEN
    EX    AF,AF'                    ;[08A5] A' = $E4
    LD    A,$65                     ;[08A6] A = $65 (bank enable)
    LD    BC,(SYSVAR_GRNBNK)        ;[08A8] BC = start address of GREEN video bank
    CALL  OUT_TO_BANK               ;[08AC] Write byte to GREEN plane at HL+BC
OUTB_END:
    POP   DE                        ;[08AF] Restore caller's DE
    EXX                             ;[08B0] Restore alternate HL/BC/DE
    POP   HL                        ;[08B1] Restore screen offset
    EXX                             ;[08B2] Back to main register set
    POP   AF                        ;[08B3] Restore alternate AF
    EX    AF,AF'                    ;[08B4] Swap back
    RET                             ;[08B5] 

;
; Writes the computed pixel byte to one colour-plane bank in video RAM.
; The Lynx uses a bank-switched RAM architecture: a short I/O sequence
; pages in the target bank, writes the byte, then pages the bank out again.
;
; Entry:  HL  = byte offset within the colour plane
;         BC  = base address of the colour plane bank
;         A'  = bank select I/O value (written to port $FF7F)
;         A   = bank page-in value  (written to port $80)
; D holds the colour-masked pixel data; E holds the mask.
; The final write is: (HL + BC) = ((HL+BC) AND E) OR D
;
OUT_TO_BANK:
    PUSH  HL                        ;[08B6] Save pixel offset
    ADD   HL,BC                     ;[08B7] HL = absolute address in video bank
    LD    BC,$FF7F                  ;[08B8] BC = bank select I/O port address
    OUT   (C),A                     ;[08BB] Select bank via port $FF7F
    LD    A,$40                     ;[08BD] Page-in command for port $80
    OUT   ($80),A                   ;[08BF] Page in the video bank
    EX    AF,AF'                    ;[08C1] A = bank-specific page value (A')
    OUT   ($80),A                   ;[08C2] Set correct bank page
    LD    A,(HL)                    ;[08C4] Read existing byte from video RAM
    AND   E                         ;[08C5] Apply mask (preserve bits not being updated)
    OR    D                         ;[08C6] Set new pixel bits from colour data
    LD    (HL),A                    ;[08C7] Write merged byte back to video RAM
    XOR   A                         ;[08C8] A = 0: page-out value
    OUT   ($80),A                   ;[08C9] Page out the video bank
    OUT   (C),A                     ;[08CB] Deselect bank
    POP   HL                        ;[08CD] Restore pixel offset
    RET                             ;[08CE] 

;
; Fills one colour-plane bank with the value in D (called by _CLS).
; Pages the bank in, writes D to every byte from HL to HL+EXT_ROM ($4000
; bytes), then pages the bank out.
;
; Entry:  A  = bank select value (written to port $FF7F)
;         HL = start address within the colour plane bank
;         D  = fill byte ($FF for a solid colour, $00 for black)
;
CLS_BANK:
    LD    BC,$FF7F                  ;[08CF] Bank select I/O port
    OUT   (C),A                     ;[08D2] Select the colour-plane bank
    LD    BC,EXT_ROM                ;[08D4] BC = $4000 (length of one colour plane)
CLS_BANK1:
    LD    (HL),D                    ;[08D7] Write fill byte to this address
    DEC   BC                        ;[08D8] Decrement byte counter
    INC   HL                        ;[08D9] Advance pointer
    LD    A,B                       ;[08DA] 
    OR    C                         ;[08DB] BC == 0?
    JR    NZ,CLS_BANK1              ;[08DC] No: continue filling
    XOR   A                         ;[08DE] A = 0: deselect value
    LD    BC,$FF7F                  ;[08DF] Bank select I/O port again
    OUT   (C),A                     ;[08E2] Deselect the bank
    RET                             ;[08E4] 

;
; Clear Screen: erases all three colour planes to the current PAPER colour.
; The Lynx display is RGB with three separate 16KB video RAM banks.
; SUB_CLS_COLOUR converts the paper colour nibble for each plane into either
; $00 (plane bit clear) or $FF (plane bit set) for the fill, then CLS_BANK
; performs the actual bank fill.
; SYSVAR_PROTST bits protect individual planes from being cleared (same
; semantics as in OUTB).
;
_CLS:
    LD    A,$20                     ;[08E5] Page-in value for CLS video access
    OUT   ($80),A                   ;[08E7] Page in video RAM
    LD    DE,(SYSVAR_PAPST)         ;[08E9] E = paper colour byte (3-bit RGB)
CLS_BLUE:
    CALL  SUB_CLS_COLOUR            ;[08ED] D = $FF if BLUE paper bit set, else $00; shifts E
    LD    A,(SYSVAR_PROTST)         ;[08F0] Check protection register
    RRCA                            ;[08F3] Bit 0 -> carry: BLUE protected?
    JR    C,CLS_RED                 ;[08F4] Yes: skip BLUE clear
    LD    HL,(SYSVAR_BLUBNK)        ;[08F6] HL = base address of BLUE bank
    LD    A,$23                     ;[08F9] Bank select value for BLUE
    CALL  CLS_BANK                  ;[08FB] Fill BLUE plane with D
CLS_RED:
    CALL  SUB_CLS_COLOUR            ;[08FE] D = $FF if RED paper bit set; shifts E
    LD    A,(SYSVAR_PROTST)         ;[0901] 
    BIT   1,A                       ;[0904] Bit 1: RED protected?
    JR    NZ,CLS_GREEN              ;[0906] Yes: skip RED clear
    LD    HL,(SYSVAR_REDBNK)        ;[0908] HL = base address of RED bank
    LD    A,$23                     ;[090B] Bank select value for RED
    CALL  CLS_BANK                  ;[090D] Fill RED plane with D
CLS_GREEN:
    CALL  SUB_CLS_COLOUR            ;[0910] D = $FF if GREEN paper bit set; shifts E
    LD    A,(SYSVAR_PROTST)         ;[0913] 
    BIT   2,A                       ;[0916] Bit 2: GREEN protected?
    JR    NZ,CLS_END                ;[0918] Yes: skip GREEN clear
    LD    HL,(SYSVAR_GRNBNK)        ;[091A] HL = base address of GREEN bank
    LD    A,$25                     ;[091D] Bank select value for GREEN
    CALL  CLS_BANK                  ;[091F] Fill GREEN plane with D
CLS_END:
    XOR   A                         ;[0922] A = 0
    OUT   ($80),A                   ;[0923] Page out video RAM
    RET                             ;[0925] 

;
; Helper for _CLS: converts the LSB of E (the paper colour register) into a
; fill byte for one colour plane, then shifts E right ready for the next plane.
; Returns D = $FF if the colour bit for this plane is 1, $00 if it is 0.
;
SUB_CLS_COLOUR:
    LD    D,$00                     ;[0926] Assume fill = 0 (plane off)
    SRL   E                         ;[0928] Shift bit 0 of paper colour into carry
    RET   NC                        ;[092A] Carry clear: plane is off, D stays $00
    DEC   D                         ;[092B] D = $FF ($00 - 1): plane is on, fill with $FF
    RET                             ;[092C] 

;
; Bell / BEEP (VDU 7).
; Generates a short fixed-pitch beep using the predefined constants:
;   KBPLEN = 180  (beep duration in half-cycles)
;   KBPWAV = 456  (wavelength: controls pitch)
; Loads HL = KBPLEN, DE = KBPWAV, BC = $3F84 (loop counter / DAC port),
; then pages in the sound hardware and jumps into the beep loop.
;
SCREEN_BELL:
    LD    HL,KBPLEN                 ;[092D] HL = beep duration (180 half-cycles)
    LD    DE,KBPWAV                 ;[0930] DE = wavelength (456 -> ~1 kHz tone)
    LD    BC,$3F84                  ;[0933] B = $3F (loop count), C = $84 (DAC output port)
    LD    A,$01                     ;[0936] 
    OUT   ($80),A                   ;[0938] Page in sound hardware
    JP    BEEP_LOOP                 ;[093A] Enter shared beep loop

;
; BASIC BEEP command handler.
; Reads pitch and duration arguments from the expression evaluator, maps the
; pitch to the range 0..63 (AND $3F), then falls through into _BEEP.
;
EBEEP:
    LD    A,$01                     ;[093D] 
    OUT   ($80),A                   ;[093F] Page in sound hardware
    CALL  EINT                      ;[0941] Read first argument (pitch) into HL
    INC   DE                        ;[0944] Skip separator
    PUSH  HL                        ;[0945] Save pitch argument
    CALL  EINT                      ;[0946] Read second argument (duration) into HL
    INC   DE                        ;[0949] Skip separator
    PUSH  HL                        ;[094A] Save duration argument
    CALL  EINT                      ;[094B] Read third argument (wavelength?) into HL

;
; Core beep routine.  Sets up B (pitch masked to 6 bits) and the loop
; counters, then drives the DAC at port $84 to produce a square wave.
; See Lynx User Issue 2 for a description of the sound registers.
;
_BEEP:
    AND   $3F                       ;[094E] Clamp pitch to 6 bits (0..63)
    LD    B,A                       ;[0950] B = pitch value for DAC
    LD    C,$84                     ;[0951] C = DAC output port
    POP   HL                        ;[0953] HL = duration argument
    INC   HL                        ;[0954] Adjust duration (1-based)
    POP   DE                        ;[0955] DE = wavelength argument
    INC   DE                        ;[0956] Adjust wavelength
    INC   D                         ;[0957] 
    INC   E                         ;[0958] 
    DEC   E                         ;[0959] Normalise E (test for zero then undo)
    JR    NZ,BEEP_LOOP              ;[095A] E non-zero: start beep immediately
    INC   E                         ;[095C] E was zero: set to 1 to avoid zero-length delay
BEEP_LOOP:
    XOR   A                         ;[095D] A = 0 (DAC off)
    OUT   (C),B                     ;[095E] Output pitch byte to DAC (turn tone ON)
    CALL  DELAY                     ;[0960] Half-cycle delay (DE controls duration)
    OUT   (C),A                     ;[0963] Output 0 to DAC (turn tone OFF)
    CALL  DELAY                     ;[0965] Half-cycle delay
    PUSH  BC                        ;[0968] Save B (pitch) and C (port)
    LD    BC,$0080                  ;[0969] BC = port $80 status register
    IN    B,(C)                     ;[096C] Read hardware status byte
    BIT   6,B                       ;[096E] Bit 6: BREAK/escape flag
    POP   BC                        ;[0970] Restore B and C
    RET   Z                         ;[0971] Break detected: abort beep
    DEC   HL                        ;[0972] Decrement duration counter
    LD    A,H                       ;[0973] 
    OR    L                         ;[0974] HL == 0?
    JR    NZ,BEEP_LOOP              ;[0975] No: continue beeping
    RET                             ;[0977] Done

;
; Delay loop used by BEEP and SOUND routines to control tone frequency.
; DE holds the loop count: outer loop on D, inner loop on E.
; At the Z80's 4 MHz clock, each pass through DELAY_LOOP is ~4 T-states;
; the total delay in T-states is approximately D * E * 4.
; DE is preserved across the call.
;
DELAY:
    PUSH  DE                        ;[0978] Save DE
DELAY_LOOP:
    DEC   E                         ;[0979] Inner loop counter
    JR    NZ,DELAY_LOOP             ;[097A] 
    DEC   D                         ;[097C] Outer loop counter
    JR    NZ,DELAY_LOOP             ;[097D] 
    POP   DE                        ;[097F] Restore DE
    RET                             ;[0980] 

;
; BASIC SOUND command handler.
; Reads the note table address and duration from the expression evaluator,
; then pages in the sound hardware and falls through into _SOUND.
;
ESOUND:
    LD    A,$01                     ;[0981] 
    OUT   ($80),A                   ;[0983] Page in sound hardware
    CALL  EINT                      ;[0985] Read first argument (note table address?)
    INC   DE                        ;[0988] Skip separator
    PUSH  HL                        ;[0989] Save argument
    CALL  EINT                      ;[098A] Read second argument (duration/delay count)
    EX    DE,HL                     ;[098D] DE = duration argument
    INC   D                         ;[098E] Adjust D
    POP   HL                        ;[098F] HL = note table address

;
; Core SOUND routine: plays a sequence of notes from a table pointed to by HL.
; Each byte in the table is a note value (AND'd to 6 bits); a zero byte ends
; the sequence.  The DELAY routine uses DE as the inter-note timing.
; Polls port $80 bit 6 after each note to allow BREAK to abort.
; See Lynx User Issue 2 for full SOUND command documentation.
;
_SOUND:
    LD    A,(HL)                    ;[0990] Read next note byte from table
    INC   HL                        ;[0991] Advance table pointer
    AND   $3F                       ;[0992] Clamp to 6-bit pitch (0 = end of sequence)
    RET   Z                         ;[0994] Zero: end of note table, return
    OUT   ($84),A                   ;[0995] Output pitch to DAC
    CALL  DELAY                     ;[0997] Wait for note duration
    LD    BC,$0080                  ;[099A] BC = status port
    IN    B,(C)                     ;[099D] Read status
    BIT   6,B                       ;[099F] BREAK pressed?
    JR    NZ,_SOUND                 ;[09A1] No: play next note
    RET                             ;[09A3] Yes: abort

;
; Tests whether the [ESC] key is currently being pressed (edge-triggered).
; Uses a roll-over byte (SYSVAR_OLDESC) to detect a fresh key-press rather
; than a held key.  Returns A = $1B (ESC) if a new ESC press is detected,
; A = 0 otherwise.
;
ESCKEY:
    LD    HL,SYSVAR_OLDESC          ;[09A4] HL -> previous ESC state byte
    LD    BC,PORT                   ;[09A7] BC = keyboard I/O port ($80), B=0, C=port
    IN    A,(C)                     ;[09AA] Read keyboard hardware byte
    CPL                             ;[09AC] Invert: pressed keys become 1 bits
    AND   $40                       ;[09AD] Isolate ESC bit (bit 6)
    LD    E,A                       ;[09AF] E = current ESC bit (0 or $40)
    XOR   (HL)                      ;[09B0] XOR with previous state: bit set if changed
    LD    (HL),E                    ;[09B1] Update stored previous state
    AND   E                         ;[09B2] AND with current: bit set only if newly pressed
    RET   Z                         ;[09B3] Return if no new ESC press
    CALL  DBNCE                     ;[09B4] Debounce: re-read and verify still pressed
    AND   $40                       ;[09B7] Check ESC bit again after debounce
    RET   Z                         ;[09B9] Return if it was a bounce
    LD    A,$1B                     ;[09BA] A = ESC character code ($1B)
    RET                             ;[09BC] Return with A = ESC

;
; Main keyboard driver.
; Scans all 10 keyboard columns, detects the first newly-pressed key using
; the roll-over table (SYSVAR_OLDKEY), converts the column/row position to
; a character code via KEYTBL or SHFTBL, handles shift-lock and graphics
; mode, and returns the character in A.  Returns A = 0 if no new key press.
;
KEYDVR:
    PUSH  HL                        ;[09BD] 
    PUSH  BC                        ;[09BE] 
    PUSH  DE                        ;[09BF] 
    XOR   A                         ;[09C0] Clear A
    LD    (SYSVAR_STATUS),A         ;[09C1] Clear "any key active" flag
    CALL  ESCKEY                    ;[09C4] Check ESC key first
    JR    NZ,KEYDVR_END             ;[09C7] ESC pressed: return with ESC code
    LD    C,PORT                    ;[09C9] C = keyboard I/O port
    LD    B,10                      ;[09CB] 10 keyboard columns to scan
    LD    HL,SYSVAR_OLDKEY          ;[09CD] HL -> roll-over table (one byte per column)
KEYDVR1:
    DEC   B                         ;[09D0] Step column counter (9..0)
    JP    M,KEYX                    ;[09D1] All columns done: check autorepeat
    IN    A,(C)                     ;[09D4] Read column B from keyboard port
    CPL                             ;[09D6] Invert (pressed = 1)
    AND   00111111B                 ;[09D7] Mask off non-key bits 6 and 7
    OR    A                         ;[09D9] Any keys active in this column?
    JR    Z,KEYDVR7                 ;[09DA] No: skip status update
    LD    (SYSVAR_STATUS),A         ;[09DC] At least one key down: set activity flag
KEYDVR7:
    LD    E,A                       ;[09DF] E = current column state
    XOR   (HL)                      ;[09E0] XOR with previous state (detect changes)
    LD    (HL),E                    ;[09E1] Update roll-over byte for this column
    AND   E                         ;[09E2] AND with current: isolate newly-pressed keys
    INC   HL                        ;[09E3] Advance roll-over pointer
    JR    Z,KEYDVR1                 ;[09E4] No new key in this column: try next
    LD    C,E                       ;[09E6] C = new-key bitmask for this column
    PUSH  BC                        ;[09E7] Save column index (B) and new-key mask (C)
    LD    C,$FF                     ;[09E8] C will become bit number (0..5)
KEYDVR2:
    INC   C                         ;[09EA] Increment bit counter
    RRCA                            ;[09EB] Shift new-key mask right
    JR    NC,KEYDVR2                ;[09EC] Repeat until the set bit falls into carry
    LD    A,B                       ;[09EE] A = column number (0..9)
    RLCA                            ;[09EF] A = column * 2
    ADD   A,B                       ;[09F0] A = column * 3
    RLCA                            ;[09F1] A = column * 6
    ADD   A,C                       ;[09F2] A = column*6 + row (0..59): key table index
    LD    E,A                       ;[09F3] E = key index
    LD    HL,KEYTBL                 ;[09F4] HL -> upper-case key table
    LD    BC,PORT                   ;[09F7] B = 0, C = keyboard port (column 0)
    IN    A,(C)                     ;[09FA] Read column 0 (contains SHIFT key on bit 7)
    RLCA                            ;[09FC] Shift bit 7 (SHIFT) into carry
    JR    C,KEYDVR4                 ;[09FD] Carry set = SHIFT not pressed: use upper table
    LD    HL,SHFTBL                 ;[09FF] SHIFT pressed: use lower-case / shifted table
KEYDVR4:
    LD    B,$02                     ;[0A02] B = 2 (column for CTRL key check)
    IN    A,(C)                     ;[0A04] Read column 2 (contains CTRL key)
    BIT   6,A                       ;[0A06] Bit 6 = CTRL key (0 = pressed)
    JR    NZ,KEYDVR5                ;[0A08] Not pressed: keep current table
    LD    HL,CNTRL                  ;[0A0A] CTRL pressed: use control-code table
KEYDVR5:
    LD    D,$00                     ;[0A0D] DE = key index (D=0, E=index)
    ADD   HL,DE                     ;[0A0F] HL -> character for this key
    POP   DE                        ;[0A10] Restore column/row saved at PUSH BC
    LD    B,D                       ;[0A11] B = column (for DBNCE)
    CALL  DBNCE                     ;[0A12] Debounce: re-read column B and verify
    AND   $3F                       ;[0A15] Mask off non-key bits
    XOR   E                         ;[0A17] Compare with saved new-key mask
    JR    NZ,KEYDVR_END0            ;[0A18] Key bounced: discard
    LD    A,(HL)                    ;[0A1A] A = character code from key table
    LD    HL,SYSVAR_SHLKT           ;[0A1B] HL -> shift-lock flags
    BIT   0,(HL)                    ;[0A1E] Shift-lock active?
    CALL  NZ,SHLKT0                 ;[0A20] Yes: swap upper/lower case
    BIT   1,(HL)                    ;[0A23] Graphics mode active?
    CALL  NZ,SHLKT1                 ;[0A25] Yes: convert to graphics character
    LD    (SYSVAR_LASTK),A          ;[0A28] Store character as last key pressed
    LD    C,$02                     ;[0A2B] C = XOR mask for shift-lock toggle
    CP    $03                       ;[0A2D] SHIFT-LOCK key code?
    JR    Z,KEYDVR6                 ;[0A2F] Yes: toggle shift-lock bit
    CP    $83                       ;[0A31] GRAPHICS-LOCK key code?
    JR    Z,KEYDVR6                 ;[0A33] Yes: toggle graphics-lock bit
    LD    C,$01                     ;[0A35] C = XOR mask for graphics toggle
    CP    $00                       ;[0A37] NULL character?
    JR    NZ,KEYDVR_END             ;[0A39] No: normal key, return character
KEYDVR6:
    LD    A,(SYSVAR_SHLKT)          ;[0A3B] Read shift-lock flags
    XOR   C                         ;[0A3E] Toggle the appropriate lock bit
    LD    (HL),A                    ;[0A3F] Store updated flags
KEYDVR_END0:
    XOR   A                         ;[0A40] Return 0 (lock key pressed, no printable char)
KEYDVR_END:
    POP   DE                        ;[0A41] 
    POP   BC                        ;[0A42] 
    POP   HL                        ;[0A43] 
    RET                             ;[0A44] 

;
; Shift-lock character conversion: if SYSVAR_SHLKT bit 0 is set and the
; character is alphabetic (>= $40), XOR bit 5 to swap upper/lower case.
;
SHLKT0:
    CP    $40                       ;[0A45] Is character < $40 (non-alphabetic)?
    RET   C                         ;[0A47] Yes: leave unchanged
    XOR   $20                       ;[0A48] Toggle case bit (ASCII upper<->lower)
    RET                             ;[0A4A] 

;
; Graphics-mode character conversion: if SYSVAR_SHLKT bit 1 is set, XOR bit
; 7 to select the graphics character set (characters $80-$FF).
;
SHLKT1:
    XOR   $80                       ;[0A4B] Toggle graphics/text character bit
    RET                             ;[0A4D] 

;
; Handles key autorepeat and the end-of-scan path.
; Called when all 10 columns have been scanned without finding a new key press.
; If SYSVAR_STATUS shows no keys are currently held, loads the initial repeat
; delay; otherwise decrements the repeat counter and returns the last character
; (SYSVAR_LASTK) when the counter reaches zero.
;
KEYX:
    LD    A,(SYSVAR_STATUS)         ;[0A4E] Any key currently held down?
    OR    A                         ;[0A51] 
    LD    HL,(SYSVAR_RPTDLY)        ;[0A52] HL = initial repeat delay value
    JR    Z,KX1                     ;[0A55] No key held: reset repeat timer
    LD    HL,(SYSVAR_RPT)           ;[0A57] HL = current repeat countdown
    DEC   HL                        ;[0A5A] Decrement countdown
    LD    A,H                       ;[0A5B] 
    OR    L                         ;[0A5C] Reached zero?
    JR    Z,KYREPT                  ;[0A5D] Yes: time to repeat
KX1:
    LD    (SYSVAR_RPT),HL           ;[0A5F] Store updated/reset repeat counter
    XOR   A                         ;[0A62] Return 0 (no character yet)
    JR    KEYDVR_END                ;[0A63] 
KYREPT:
    LD    BC,KREPT2                 ;[0A65] BC = autorepeat inter-character delay ($1000)
    CALL  KBD_DLAY                  ;[0A68] Busy-wait for repeat delay
    LD    A,(SYSVAR_LASTK)          ;[0A6B] Return the last character as the repeated key
    JR    KEYDVR_END                ;[0A6E] 
KBD_DLAY:
    DEC   BC                        ;[0A70] Decrement delay counter
    LD    A,B                       ;[0A71] 
    OR    C                         ;[0A72] BC == 0?
    JR    NZ,KBD_DLAY               ;[0A73] No: keep waiting
    RET                             ;[0A75] 

;
; Keyboard scan-code to ASCII lookup tables.
; The Lynx keyboard has 10 columns * 6 rows = 60 key positions.
; KEYTBL: unshifted (upper case / default) characters.
; SHFTBL: shifted (lower case / alternate) characters.
; CNTRL:  control characters (CTRL held down).
; Layout: 6 bytes per column, columns 0..9.
;
KEYTBL:
    DB    "1**",$00,CUP,CDOWN       ;[0A76] Col 0: 1, *, *, NUL, cursor-up, cursor-down
    DB    "34EXDC"                  ;[0A7C] Col 1: 3, 4, E, X, D, C
    DB    "2QWZSA"                  ;[0A82] Col 2: 2, Q, W, Z, S, A
    DB    "5RTVGF"                  ;[0A88] Col 3: 5, R, T, V, G, F
    DB    "6YH NB"                  ;[0A8E] Col 4: 6, Y, H, space, N, B
    DB    "78UM*J"                  ;[0A94] Col 5: 7, 8, U, M, *, J
    DB    "9IO,*K"                  ;[0A9A] Col 6: 9, I, O, ',', *, K
    DB    "0PL.*;"                  ;[0AA0] Col 7: 0, P, L, '.', *, ;
    DB    "-@[/*:"                  ;[0AA6] Col 8: -, @, [, /, *, :
    DB    8,']',CLEFT,CR,'*',CRIGHT ;[0AAC] Col 9: BS, ], cursor-left, CR, *, cursor-right
CNTRL:
    DB    $03,0,0,0,0,0             ;[0AB2] Col 0 CTRL: ETX(BREAK), 0,0,0,0,0
    DB    $1C,$1D,$05,$18,$04,$03   ;[0AB8] Col 1 CTRL: FS,GS,ENQ,CAN,EOT,ETX
    DB    $1B,$11,$17,$1A,$13,$01   ;[0ABE] Col 2 CTRL: ESC,DC1,ETB,SUB,DC3,SOH
    DB    $1E,$12,$14,$16,$07,$06   ;[0AC4] Col 3 CTRL: RS,DC2,DC4,SYN,BEL,ACK
    DB    $1F,$19,$08,$00,$0E,$02   ;[0ACA] Col 4 CTRL: US,EM,BS,NUL,SO,STX
    DB    0,0,$15,$0D,0,$0A         ;[0AD0] Col 5 CTRL: 0,0,NAK,CR,0,LF
    DB    0,$09,$0F,0,0,$0B         ;[0AD6] Col 6 CTRL: 0,HT,SI,0,0,VT
    DB    0,$10,$0C                 ;[0ADC] Col 7 CTRL (partial): 0,DLE,FF
SHFTBL:
    DB    $21,$2A,$2A,0,$0B,$0A     ;[0ADF] Col 0 SHIFT: !, *, *, NUL, cursor-up, cursor-down
    DB    "#$exdc"                  ;[0AE5] Col 1 SHIFT: #, $, e, x, d, c
    DB    $22,"qwzsa"               ;[0AEB] Col 2 SHIFT: ", q, w, z, s, a
    DB    "%rtvgf"                  ;[0AF1] Col 3 SHIFT: %, r, t, v, g, f
    DB    "&yh nb"                  ;[0AF7] Col 4 SHIFT: &, y, h, space, n, b
    DB    $27,"(um?j"               ;[0AFD] Col 5 SHIFT: ', (, u, m, ?, j
    DB    ")io<?k"                  ;[0B03] Col 6 SHIFT: ), i, o, <, ?, k
    DB    "_pl>?+"                  ;[0B09] Col 7 SHIFT: _, p, l, >, ?, +
    DB    "=`^?**"                  ;[0B0F] Col 8 SHIFT: =, `, ^, ?, *, *
    DB    8,$7F,CLEFT,CR,'*',CRIGHT ;[0B15] Col 9 SHIFT: BS, DEL, cursor-left, CR, *, cursor-right

;
; ESC shorthand expansion handler (called via SYSVAR_KEYB).
; Pressing [ESC] followed by a letter A-Z expands to the BASIC keyword mapped
; to that letter in SYSVAR_KTBL (a 26-byte table).  The expansion is stored
; in SYSVAR_KSMS so subsequent keyboard reads return the individual characters
; of the expanded word one at a time.
;
KSM:
    LD    A,(SYSVAR_KSMS+$01)       ;[0B1B] Is expansion already in progress?
    OR    A,A                       ;[0B1E] 
    JR    NZ,KSM1                   ;[0B1F] Yes: return next character from buffer
    CALL  KEYDVR                    ;[0B21] No: get a fresh keypress
    CALL  ESC                       ;[0B24] Is it an ESC prefix?
    RET   NZ                        ;[0B27] Not ESC: return character as-is
    RES   5,A                       ;[0B28] Clear bit 5 to normalise to upper case
    CP    'A'                       ;[0B2A] Is it in the range A-Z?
    RET   C                         ;[0B2C] Below 'A': not a valid shorthand, return
    CP    'Z'+1                     ;[0B2D] 
    RET   NC                        ;[0B2F] Above 'Z': not a valid shorthand, return
    SUB   'A'                       ;[0B30] A = 0..25 (index into shorthand table)
    LD    HL,SYSVAR_KTBL            ;[0B32] HL -> 26-byte shorthand-to-token table
    LD    C,A                       ;[0B35] 
    LD    B,0                       ;[0B36] BC = index
    ADD   HL,BC                     ;[0B38] HL -> token for this letter
    LD    A,(HL)                    ;[0B39] A = BASIC token number for this letter
    LD    HL,(SYSVAR_XTTBL)         ;[0B3A] HL -> command token expansion table
    INC   A                         ;[0B3D] Adjust: TOKEN_TO_WORD_FIND uses 1-based index
    LD    B,A                       ;[0B3E] B = token number
    CALL  TOKEN_TO_WORD_FIND        ;[0B3F] HL -> first character of keyword string
    LD    (SYSVAR_KSMS),HL          ;[0B42] Store expansion pointer in KSMS
    LD    A,(HL)                    ;[0B45] Read first character of keyword
    RES   7,A                       ;[0B46] Clear bit 7 (end-of-word marker)
    RET                             ;[0B48] Return first character of expanded keyword

KSM1:
    LD    HL,(SYSVAR_KSMS)          ;[0B49] HL -> current position in expansion string
    INC   HL                        ;[0B4C] Advance to next character
    LD    (SYSVAR_KSMS),HL          ;[0B4D] Update expansion pointer
    LD    A,(HL)                    ;[0B50] Read next character
    BIT   7,A                       ;[0B51] Bit 7 set = end of keyword token
    RET   Z                         ;[0B53] Not end: return this character
    XOR   A                         ;[0B54] End of expansion: return 0 to signal completion
    LD    (SYSVAR_KSMS+$01),A       ;[0B55] Clear "expansion active" flag
    LD    A,' '                     ;[0B58] Return a trailing space after the keyword
    RET                             ;[0B5A] 

;
; Top-level keyboard scan entry point.  Called via SYSVAR_KEYB by the BASIC
; interpreter whenever a character is needed from the keyboard.  Wraps KSM
; (which handles ESC shorthand) with register save/restore.
;
KEYB:
    PUSH  HL                        ;[0B5B] 
    PUSH  BC                        ;[0B5C] 
    PUSH  DE                        ;[0B5D] 
    CALL  KSM                       ;[0B5E] Get next character (with shorthand expansion)
    POP   DE                        ;[0B61] 
    POP   BC                        ;[0B62] 
    POP   HL                        ;[0B63] 
    RET                             ;[0B64] 

;
; Reads the sync signal from the cassette tape.
; Waits for a run of $28 (40) consecutive zero bytes (the sync leader), then
; watches for the $A5 sync marker byte that signals the start of real data.
; The playback level (SYSVAR_PLYLEV) sets the comparator threshold for the
; cassette input circuit.
;
RSYNC:
    PUSH  BC                        ;[0B65] 
    LD    A,(SYSVAR_PLYLEV)         ;[0B66] Load comparator threshold for cassette input
    OUT   ($84),A                   ;[0B69] Set playback voltage reference
    CALL  MOTON                     ;[0B6B] Start cassette motor
    LD    A,$20                     ;[0B6E] 
    OUT   ($87),A                   ;[0B70] Enable cassette read mode
RSYNC_LOOP40:
    LD    B,$28                     ;[0B72] Require 40 consecutive zero bytes
RSYNC_RBYTE:
    CALL  RBYTE                     ;[0B74] Read one byte from tape
    OR    A                         ;[0B77] Is it zero?
    JR    NZ,RSYNC_LOOP40           ;[0B78] Non-zero: restart zero-byte count
    DJNZ  RSYNC_RBYTE               ;[0B7A] Decrement counter; loop until 40 zeros seen
RSYNC_FIND_A5:
    CALL  SYSVAR_RBIT               ;[0B7C] Read next byte (via bit-read hook)
    CP    $A5                       ;[0B7F] Is it the sync marker?
    JR    NZ,RSYNC_FIND_A5          ;[0B81] No: keep reading until $A5 found
    POP   BC                        ;[0B83] 
    RET                             ;[0B84] Sync found: return

;
; Reads one byte from cassette tape into A.
; Calls SYSVAR_RBIT eight times, assembling the result bit-by-bit into A.
;
RBYTE:
    PUSH  BC                        ;[0B85] 
    PUSH  DE                        ;[0B86] 
    LD    B,$08                     ;[0B87] 8 bits per byte
RBYTE_BIT:
    PUSH  BC                        ;[0B89] Save bit counter
    CALL  SYSVAR_RBIT               ;[0B8A] Read one bit; result accumulated in A via RBIT
    POP   BC                        ;[0B8D] Restore bit counter
    DJNZ  RBYTE_BIT                 ;[0B8E] Repeat for all 8 bits
    POP   DE                        ;[0B90] 
    POP   BC                        ;[0B91] 
    RET                             ;[0B92] A = assembled byte

;
; Writes the sync signal to cassette tape.
; Outputs SYSVAR_SYNCLEN * 256 zero bytes (the sync leader), then writes the
; $A5 sync marker byte.  At the default speed (TAPE 0, SYNCLEN=3) this gives
; 768 zero bytes (~2.5 s of leader at 1200 baud).
;
WSYNC:
    PUSH  BC                        ;[0B93] 
    PUSH  AF                        ;[0B94] 
    CALL  MOTON                     ;[0B95] Start cassette motor
    LD    A,$10                     ;[0B98] 
    OUT   ($87),A                   ;[0B9A] Enable cassette write mode
    LD    A,(SYSVAR_SYNCLEN)        ;[0B9C] Outer loop count (default 3 for TAPE 0)
    LD    B,A                       ;[0B9F] B = outer loop counter
WSYNC1:
    PUSH  BC                        ;[0BA0] 
    LD    B,$00                     ;[0BA1] B = 0 -> inner loop of 256 iterations
    XOR   A                         ;[0BA3] A = 0 (sync byte)
WSYNC2:
    CALL  SYSVAR_WBYTE              ;[0BA4] Write one zero byte to tape
    DJNZ  WSYNC2                    ;[0BA7] Inner loop: 256 zero bytes
    POP   BC                        ;[0BA9] 
    DJNZ  WSYNC1                    ;[0BAA] Outer loop: SYNCLEN * 256 zero bytes total
    LD    A,$A5                     ;[0BAC] Sync marker byte
    CALL  SYSVAR_WBYTE              ;[0BAE] Write marker to tape
    POP   AF                        ;[0BB1] 
    POP   BC                        ;[0BB2] 
    RET                             ;[0BB3] 

;
; Writes the filename to tape, preceded by a sync signal.
; The filename is pointed to by DE and terminated by a '"' (double-quote)
; character, matching the SAVE "filename" syntax.
;
WRITE_FNAME:
    CALL  WSYNC                     ;[0BB4] Write sync leader + $A5 marker
    LD    A,(DE)                    ;[0BB7] Read first byte of filename (the opening '"')
    CALL  SYSVAR_WBYTE              ;[0BB8] Write it to tape
WRITE_FNAME_LOOP:
    INC   DE                        ;[0BBB] Advance to next filename character
    LD    A,(DE)                    ;[0BBC] Read character
    CALL  SYSVAR_WBYTE              ;[0BBD] Write character to tape
    CP    $22                       ;[0BC0] Closing '"' reached?
    JR    NZ,WRITE_FNAME_LOOP       ;[0BC2] No: continue writing filename
    RET                             ;[0BC4] Filename written including closing '"'

;
; Tape error exit: turns off motor and reports "Not Found" error.
;
SAVE_END_ERROR:
    CALL  MOTOFF                    ;[0BC5] Stop cassette motor
    CALL  ERR_NOT_FOUND             ;[0BC8] Report error (does not return)

;
; SAVE BASIC command.
; Writes the filename, then the BASIC program to tape.
; If a line number is specified after the filename, only that line (and
; beyond) is saved and the auto-run line number is stored in the tape header.
; Format on tape: sync + filename + sync + 'B' + length(2) + data + run-line(2)
;
ESAVE:
    CALL  WRITE_FNAME               ;[0BCB] Write sync and filename to tape
    INC   DE                        ;[0BCE] Skip closing '"' in source line
    LD    A,(DE)                    ;[0BCF] Peek at next character
    LD    HL,0                      ;[0BD0] HL = 0: default auto-run line (none)
    PUSH  HL                        ;[0BD3] Save auto-run line on stack
    CP    $0D                       ;[0BD4] End of line (no line number specified)?
    JR    Z,SAVE_HEADER             ;[0BD6] Yes: save whole program with no auto-run
    POP   HL                        ;[0BD8] No: discard default auto-run
    INC   DE                        ;[0BD9] Skip separator
    CALL  SUB_CHK_EXP_EVAL          ;[0BDA] Evaluate the line number expression
    CALL  FNDLN_WRA1                ;[0BDD] Find that BASIC line; result in IX
    JR    NZ,SAVE_END_ERROR         ;[0BE0] Line not found: error
    PUSH  IX                        ;[0BE2] IX -> start of requested line
    POP   HL                        ;[0BE4] HL = start address
    LD    DE,(SYSVAR_EOB)           ;[0BE5] DE = end of BASIC
    OR    A                         ;[0BE9] Clear carry
    SBC   HL,DE                     ;[0BEA] HL = (start of line) - (end): negative offset
    PUSH  HL                        ;[0BEC] Push auto-run offset (used later)
SAVE_HEADER:
    LD    HL,(SYSVAR_EOB)           ;[0BED] Calculate total program length
    LD    DE,(SYSVAR_SOB)           ;[0BF0] DE = start of BASIC
    OR    A                         ;[0BF4] 
    SBC   HL,DE                     ;[0BF5] HL = EOB - SOB = program size
    INC   HL                        ;[0BF7] Add 1 for end marker
    PUSH  HL                        ;[0BF8] Save program length
    LD    HL,(SYSVAR_SOB)           ;[0BF9] HL -> start of BASIC program
    CALL  WSYNC                     ;[0BFC] Write second sync block (for program data)
    LD    A,'B'                     ;[0BFF] Type byte: 'B' = BASIC program
    CALL  SYSVAR_WBYTE              ;[0C01] Write 'B' to tape
    POP   BC                        ;[0C04] BC = program length
    LD    A,C                       ;[0C05] 
    CALL  SYSVAR_WBYTE              ;[0C06] Write length low byte
    LD    A,B                       ;[0C09] 
    CALL  SYSVAR_WBYTE              ;[0C0A] Write length high byte
SAVE_BASIC:
    LD    A,(HL)                    ;[0C0D] Read byte from BASIC program
    CALL  SYSVAR_WBYTE              ;[0C0E] Write byte to tape
    INC   HL                        ;[0C11] Advance source pointer
    DEC   BC                        ;[0C12] Decrement byte counter
    LD    A,B                       ;[0C13] 
    OR    C                         ;[0C14] All bytes written?
    JR    NZ,SAVE_BASIC             ;[0C15] No: continue
    POP   HL                        ;[0C17] HL = auto-run line offset (or 0)
    LD    A,L                       ;[0C18] 
    CALL  SYSVAR_WBYTE              ;[0C19] Write auto-run low byte
    LD    A,H                       ;[0C1C] 
    CALL  SYSVAR_WBYTE              ;[0C1D] Write auto-run high byte
    CALL  SYSVAR_WBYTE              ;[0C20] Write extra trailing byte (purpose unclear)
    JP    MOTOFF                    ;[0C23] Stop motor and return

;
; Called by LOAD, VERIFY and APPEND to find the correct file on tape.
; Reads sync blocks and filenames in a loop until the filename on tape
; matches the filename pointed to by DE in the BASIC program.
; The found filename is also printed to the screen as it is read.
;
TAPE_READ:
    INC   DE                        ;[0C26] Skip past opening '"' of filename in source
TAPE_READ_NEXT:
    PUSH  DE                        ;[0C27] Save pointer to desired filename
    LD    HL,INPBUF                 ;[0C28] HL -> input buffer (to receive tape filename)
TAPE_FIND_SYNC:
    CALL  RSYNC                     ;[0C2B] Wait for sync leader + $A5
    CALL  RBYTE                     ;[0C2E] Read next byte
    CP    $22                       ;[0C31] Opening '"' of filename?
    JR    NZ,TAPE_FIND_SYNC         ;[0C33] No: wrong block type, try again
TAPE_READ_FNAME:
    CALL  RBYTE                     ;[0C35] Read one character of filename from tape
    LD    (HL),A                    ;[0C38] Store in input buffer
    INC   L                         ;[0C39] Advance buffer pointer
    CP    $22                       ;[0C3A] Closing '"'?
    JR    NZ,TAPE_READ_FNAME        ;[0C3C] No: keep reading filename
    POP   DE                        ;[0C3E] Restore pointer to desired filename
    PUSH  DE                        ;[0C3F] Save again (needed after comparison)
    LD    A,' '                     ;[0C40] Print a space before the filename
    RST   $08                       ;[0C42] 
    LD    A,$22                     ;[0C43] Print opening '"'
    RST   $08                       ;[0C45] 
    LD    (HL),$00                  ;[0C46] Null-terminate the tape filename in buffer
    LD    HL,INPBUF                 ;[0C48] HL -> buffered tape filename
    PUSH  HL                        ;[0C4B] 
    CALL  PLINE                     ;[0C4C] Print the filename to screen
    DEC   HL                        ;[0C4F] HL -> last character printed
    LD    (HL),SZ                   ;[0C50] Replace with string-end marker for comparison
    POP   HL                        ;[0C52] HL -> buffered filename
    CALL  STRING_CMP                ;[0C53] Compare tape filename with desired filename (DE)
    POP   DE                        ;[0C56] Restore desired filename pointer
    JR    NZ,TAPE_READ_NEXT         ;[0C57] Names differ: keep searching tape
    RET                             ;[0C59] Names match: correct file found

;
; VERIFY BASIC command.
; Reads the program header from tape and compares every byte with the BASIC
; program currently in memory, reporting BAD TAPE if any byte differs.
;
EVERIFY:
    CALL  TAPE_READ                 ;[0C5A] Find file on tape (match filename)
    LD    HL,(SYSVAR_SOB)           ;[0C5D] HL -> start of BASIC program in RAM
    CALL  RSYNC                     ;[0C60] Wait for data block sync
    CALL  RBYTE                     ;[0C63] Read type byte
    CP    'B'                       ;[0C66] Must be 'B' for BASIC
    JR    NZ,VERIFY_ERROR_EXIT      ;[0C68] Wrong type: error
    CALL  RBYTE                     ;[0C6A] Read length low byte
    LD    C,A                       ;[0C6D] C = length low
    CALL  RBYTE                     ;[0C6E] Read length high byte
    LD    B,A                       ;[0C71] BC = program length
VERIFY_READ_NEXT:
    CALL  RBYTE                     ;[0C72] Read one byte from tape
    CP    (HL)                      ;[0C75] Compare with byte in RAM
    INC   HL                        ;[0C76] Advance RAM pointer
    JR    NZ,VERIFY_ERROR_EXIT      ;[0C77] Mismatch: report error
    DEC   BC                        ;[0C79] Decrement remaining byte count
    LD    A,B                       ;[0C7A] 
    OR    C                         ;[0C7B] All bytes checked?
    JR    NZ,VERIFY_READ_NEXT       ;[0C7C] No: continue
    JP    MOTOFF                    ;[0C7E] All bytes matched: stop motor and return
VERIFY_ERROR_EXIT:
    CALL  MOTOFF                    ;[0C81] Stop motor
    JP    ERR_BAD_TAPE              ;[0C84] Report BAD TAPE error (does not return)

;
; APPEND BASIC command.
; Loads a BASIC program from tape and appends it to the end of the program
; already in memory, rather than overwriting from the start.
;
EAPPEND:
    CALL  TAPE_READ                 ;[0C87] Find file on tape
    LD    HL,(SYSVAR_EOB)           ;[0C8A] HL -> end of existing BASIC (append point)
    JR    BLOAD_READ_B              ;[0C8D] Share LOAD body

;
; LOAD BASIC command.
; Loads a BASIC program from tape into memory, overwriting the current program.
; Falls through into the shared load body (BLOAD_READ_B).
;
ELOAD:
    CALL  TAPE_READ                 ;[0C8F] Find file on tape
    LD    HL,(SYSVAR_SOB)           ;[0C92] HL -> start of BASIC (load destination)
BLOAD_READ_B:
    CALL  RSYNC                     ;[0C95] Wait for data block sync
    CALL  RBYTE                     ;[0C98] Read type byte
    CP    'B'                       ;[0C9B] Is it a BASIC block?
    JR    NZ,BLOAD_READ_B           ;[0C9D] No: wrong block, keep searching
    CALL  RBYTE                     ;[0C9F] Read program length low byte
    LD    C,A                       ;[0CA2] C = length low
    CALL  RBYTE                     ;[0CA3] Read program length high byte
    LD    B,A                       ;[0CA6] BC = total program length
BLOAD_READ_PROG:
    CALL  RBYTE                     ;[0CA7] Read one byte from tape
    LD    (HL),A                    ;[0CAA] Store in RAM
    INC   HL                        ;[0CAB] Advance destination pointer
    DEC   BC                        ;[0CAC] Decrement byte count
    LD    A,B                       ;[0CAD] 
    OR    C                         ;[0CAE] All bytes loaded?
    JR    NZ,BLOAD_READ_PROG        ;[0CAF] No: continue
    DEC   HL                        ;[0CB1] HL now points to last byte written
    LD    (SYSVAR_EOB),HL           ;[0CB2] Update end-of-BASIC pointer
    CALL  RBYTE                     ;[0CB5] Read auto-run offset low byte
    LD    E,A                       ;[0CB8] E = offset low
    CALL  RBYTE                     ;[0CB9] Read auto-run offset high byte
    LD    D,A                       ;[0CBC] DE = auto-run offset (signed, relative to EOB)
    OR    E                         ;[0CBD] Is DE == 0? (no auto-run)
    JP    Z,MOTOFF                  ;[0CBE] Zero: just stop motor and return
    ADD   HL,DE                     ;[0CC1] HL = EOB + offset = auto-run line address
    PUSH  HL                        ;[0CC2] 
    CALL  MOTOFF                    ;[0CC3] Stop motor
    CALL  ZERO_MEM                  ;[0CC6] Initialise variables area
    POP   IX                        ;[0CC9] IX = auto-run start line
    JP    EXEC5                     ;[0CCB] Start executing BASIC from that line

;
; Escape route from the bit-read routine: motor off and return to command line.
; Called by RBIT when the tape signal is lost (no valid transitions detected).
;
RBIT_END:
    CALL  MOTOFF                    ;[0CCE] Stop cassette motor
    JP    JUMP_TO_CMDLINE           ;[0CD1] Return to BASIC command prompt

;
; Reads one bit from the cassette tape into the carry flag.
; Uses pulse-width detection: measures the time between falling edge and
; rising edge of the signal.  The count in D is compared with SYSVAR_CASLEV
; to distinguish a '0' bit (short pulse) from a '1' bit (long pulse).
; If no valid signal is detected (bit 5 of the port byte is clear) the
; routine aborts via RBIT_END.
; The resulting bit is accumulated into A via RLA (called 8 times by RBYTE).
;
RBIT:
    LD    BC,$0080                  ;[0CD4] B = 0, C = cassette status port ($80)
    LD    D,$00                     ;[0CD7] D = pulse-width counter
RBIT_LOOP1:
    IN    E,(C)                     ;[0CD9] Read cassette port
    SRL   E                         ;[0CDB] Shift: bit 0 (signal) -> carry
    JR    C,RBIT_LOOP1              ;[0CDD] Signal high: wait for falling edge
    BIT   5,E                       ;[0CDF] Bit 5 of port: valid signal present?
    JR    Z,RBIT_END                ;[0CE1] No valid signal: abort
RBIT_LOOP2:
    IN    E,(C)                     ;[0CE3] Read cassette port again
    INC   D                         ;[0CE5] Increment pulse-width counter
    SRL   E                         ;[0CE6] Shift: bit 0 -> carry
    JR    NC,RBIT_LOOP2             ;[0CE8] Signal still low: keep counting
    LD    E,A                       ;[0CEA] Save current accumulated byte
    LD    A,(SYSVAR_CASLEV)         ;[0CEB] A = threshold level for bit discrimination
    CP    D                         ;[0CEE] Threshold >= D (short pulse = '0')?
    LD    A,E                       ;[0CEF] Restore accumulated byte (flags unaffected)
    RLA                             ;[0CF0] Rotate carry (bit result) into A
    RET                             ;[0CF1] 

;
; Turns the cassette motor on.
; Writes to ports $80 and $86 to enable the motor relay.
;
MOTON:
    LD    A,$02                     ;[0CF2] Motor-on command
    OUT   ($80),A                   ;[0CF4] Send to control port
    LD    A,$0C                     ;[0CF6] Motor relay enable value
    OUT   ($86),A                   ;[0CF8] Send to motor control port
    RET                             ;[0CFA] 

;
; Turns the cassette motor off.
; Zeros ports $87 and $80, then waits for KMOTWT (6000) loop iterations
; to allow the tape to coast to a stop before any further I/O.
;
MOTOFF:
    XOR   A                         ;[0CFB] A = 0
    OUT   ($87),A                   ;[0CFC] Disable cassette read/write
    OUT   ($80),A                   ;[0CFE] Turn off motor relay
    LD    BC,KMOTWT                 ;[0D00] BC = 6000 (motor coast-down delay)
MOTOFF_DELAY:
    DEC   BC                        ;[0D03] Decrement delay counter
    LD    A,B                       ;[0D04] 
    OR    C                         ;[0D05] BC == 0?
    JR    NZ,MOTOFF_DELAY           ;[0D06] No: keep waiting
    RET                             ;[0D08] 

;
; Cassette waveform table (sine-wave approximation for analogue output).
; Pointed to by SYSVAR_CASTBL.  Used by WBYTE to generate the analogue
; waveform written to the cassette DAC (port $84).
; Values trace the positive half of a sine wave at 64 samples, peak ~$3E,
; then return to zero; the zero-filled tail ($0D59-$0D66) acts as a guard.
;
DATA_CASTBL:
    DB $1D,$1B,$18,$16,$14,$12,$10,$0E      ;[0D09]  Rising slope (sine ascent)
    DB $0C,$0A,$09,$07,$06,$05,$04,$03      ;[0D11]  
    DB $02,$02,$02,$02,$02,$02,$02,$03      ;[0D19]  Near-zero plateau, then rising
    DB $04,$05,$06,$07,$09,$0A,$0C,$0E      ;[0D21]  Rising to peak
    DB $10,$12,$14,$16,$18,$1B,$1D,$20      ;[0D29]  
    DB $22,$24,$27,$29,$2B,$2D,$2F,$31      ;[0D31]  Peak region
    DB $33,$35,$36,$38,$39,$3A,$3B,$3C      ;[0D39]  
    DB $3D,$3D,$3D,$3E,$3D,$3D,$3D,$3C      ;[0D41]  Flat peak at $3E
    DB $3B,$3A,$39,$38,$36,$35,$33,$31      ;[0D49]  Descending slope
    DB $2F,$2D,$2B,$29,$27,$24,$22,$20      ;[0D51]  
    DB $00,$00,$00,$00,$00,$00,$00,$00      ;[0D59]  Zero guard (end-of-table sentinel)
    DB $00,$00,$00,$00,$00,$00              ;[0D61]  

;
; Writes one byte to cassette tape using analogue waveform output.
; Each bit of the byte (MSB first, with a leading '1') generates a series of
; DAC samples from DATA_CASTBL.  The coarse/fine speed parameters from
; SYSVAR_COARSE and SYSVAR_FINE control the inter-sample step and delay,
; allowing the tape speed to be adjusted by the TAPE command.
;
WBYTE:
    PUSH  AF                        ;[0D67] 
    PUSH  HL                        ;[0D68] 
    PUSH  DE                        ;[0D69] 
    PUSH  BC                        ;[0D6A] 
    LD    B,$00                     ;[0D6B] B = inter-sample delay counter (reset each sample)
    LD    E,A                       ;[0D6D] E = byte to send (bits shifted out MSB first)
    LD    A,(SYSVAR_FINE)           ;[0D6E] A = fine speed value (inner delay loop count)
    LD    D,A                       ;[0D71] D = fine delay
    SCF                             ;[0D72] Set carry: inject a leading '1' bit
WBYTE_COARSE:
    RL    E                         ;[0D73] Shift next bit of byte into carry
    JR    Z,WBYTE_END               ;[0D75] All bits shifted out (E became 0): done
    LD    A,(SYSVAR_COARSE)         ;[0D77] A = coarse step through waveform table
    JR    C,WBYTE_WAVE              ;[0D7A] Carry set = '1' bit: use step as-is
    RLCA                            ;[0D7C] Carry clear = '0' bit: double the step (shorter wave)
WBYTE_WAVE:
    LD    C,A                       ;[0D7D] C = table step for this bit
    LD    HL,(SYSVAR_CASTBL)        ;[0D7E] HL -> start of waveform table
WBYTE_SAMPLE:
    LD    A,(HL)                    ;[0D81] Read sample value from table
    OR    A                         ;[0D82] Zero? (end-of-table sentinel)
    JR    Z,WBYTE_COARSE            ;[0D83] Yes: move to next bit
    OUT   ($84),A                   ;[0D85] Output sample to DAC
    ADD   HL,BC                     ;[0D87] Advance table pointer by step
    LD    B,D                       ;[0D88] Reload fine delay counter
WBYTE_DELAY:
    DJNZ  WBYTE_DELAY               ;[0D89] Fine delay loop (D iterations)
    JR    WBYTE_SAMPLE              ;[0D8B] Process next sample in this bit's wave cycle
WBYTE_END:
    POP   BC                        ;[0D8D] 
    POP   DE                        ;[0D8E] 
    POP   HL                        ;[0D8F] 
    POP   AF                        ;[0D90] 
    RET                             ;[0D91] 

;
; TAPE command handler.
; Reads a tape speed number (0-5) from the expression and loads the four
; corresponding timing parameters into the cassette system variables.
; The six entries in TAPTBL below map to increasing tape speeds.
;
ETAPE:
    RST   $18                       ;[0D92] Evaluate expression -> HL (speed 0..5)
    CP    $06                       ;[0D93] Speed out of range?
    CALL  NC,ERR_NUM_OUT_RANGE      ;[0D95] Yes: error (does not return)
    RLCA                            ;[0D98] A = speed * 2
    RLCA                            ;[0D99] A = speed * 4 (each entry is 4 bytes)
    LD    E,A                       ;[0D9A] DE = byte offset into table
    LD    D,$00                     ;[0D9B] 
    LD    HL,TAPTBL                 ;[0D9D] HL -> tape speed table
    ADD   HL,DE                     ;[0DA0] HL -> correct 4-byte entry
    LD    DE,SYSVAR_CASLEV          ;[0DA1] DE -> destination: CASLEV, COARSE, FINE, SYNCLEN
    LD    B,$04                     ;[0DA4] 4 bytes to copy
ETAPE1:
    LD    A,(HL)                    ;[0DA6] Read parameter byte
    LD    (DE),A                    ;[0DA7] Store into sysvar
    INC   DE                        ;[0DA8] 
    INC   HL                        ;[0DA9] 
    DJNZ  ETAPE1                    ;[0DAA] 
    RET                             ;[0DAC] 

;
; Tape speed parameter table (TAPE 0..5).
; Each entry is 4 bytes: CASLEV, COARSE, FINE, SYNCLEN.
; CASLEV: comparator threshold for pulse-width discrimination.
; COARSE: waveform table step (higher = higher frequency = faster).
; FINE:   inter-sample delay (lower = shorter delay = faster).
; SYNCLEN: number of sync blocks (higher speed needs longer sync for reliability).
;
TAPTBL:
    DB    80,1,4,3                  ;[0DAD] TAPE 0: slowest (~600 baud equivalent)
    DB    56,1,1,4                  ;[0DB1] TAPE 1
    DB    44,2,4,5                  ;[0DB5] TAPE 2
    DB    35,2,2,6                  ;[0DB9] TAPE 3
    DB    27,2,1,7                  ;[0DBD] TAPE 4
    DB    20,3,2,8                  ;[0DC1] TAPE 5: fastest

;
; Moves the cursor one full character block to the right (VDU 12).
; Named PATCH1 possibly because it was added as a patch to the VDU dispatch
; table at entry $0702 after the original ROM was assembled.
;
PATCH1:
    CALL  ADV_CURSOR                ;[0DC5] Advance cursor X by 3 X units (6 pixels = one column)
    JP    SAVE_CURSORX              ;[0DC8] Store updated cursor position

;
; Detects whether a 96K RAM expansion is fitted and sets the stack pointer
; to the top of available RAM accordingly.
; Tests for RAM at $BFF8 vs $9FF8 to distinguish 48K from 64K, then walks
; upward in $1000 increments from $F000 to find the top of fitted RAM for
; 96K detection.  SP is set to the top RAM address found, and execution
; continues at START.
;
SUB_TEST_4896K:
    LD    HL,$9FF8                  ;[0DCB] HL -> test location for 48K boundary
    LD    DE,$BFF8                  ;[0DCE] DE -> test location for 64K boundary
    LD    A,(DE)                    ;[0DD1] Read existing value at $BFF8
    CPL                             ;[0DD2] Invert it
    LD    (DE),A                    ;[0DD3] Write inverted value back
    LD    C,(HL)                    ;[0DD4] Read $9FF8 to check for aliasing
    CPL                             ;[0DD5] Invert the write value again (restore original)
    LD    (DE),A                    ;[0DD6] Restore original value at $BFF8
    LD    A,(HL)                    ;[0DD7] Re-read $9FF8
    CP    C                         ;[0DD8] Did $9FF8 change when $BFF8 was written?
    JR    NZ,SUB_TEST_END           ;[0DD9] Yes: aliasing detected, 48K only -> set SP=$9FF8
    LD    HL,$0FF8                  ;[0DDB] Start search at $0FF8 + $F000 = $FFF8
    LD    DE,$F000                  ;[0DDE] Step size for search
SUB_TEST_96K:
    ADD   HL,DE                     ;[0DE1] HL += $F000 (wraps around in 16-bit arithmetic)
    LD    A,(HL)                    ;[0DE2] Read test location
    CPL                             ;[0DE3] Invert
    LD    (HL),A                    ;[0DE4] Write back
    LD    C,(HL)                    ;[0DE5] Read it back
    CPL                             ;[0DE6] Invert again (restore original)
    LD    (HL),A                    ;[0DE7] Restore original value
    CP    C                         ;[0DE8] Did the read-back match the write?
    JR    Z,SUB_TEST_96K            ;[0DE9] Yes: RAM present here, continue searching upward
SUB_TEST_END:
    LD    SP,HL                     ;[0DEB] SP = highest RAM address found
    JP    START                     ;[0DEC] Continue with system initialisation

;
; Command-line prompt string (overwrite-off, CRLF, '>' character, terminator).
; Printed by the BASIC interpreter after each command completes.
;
PROMPT:
    DB    20,19,'>',0               ;[0DEF] VDU 20 (overwrite off), VDU 19 (CRLF if needed), '>', NUL

;
; Tests for [ESC] keypress and halts BASIC execution if one is detected.
; Used by the input routines (via SYSVAR_LINP) to allow the user to break out
; of a running program.
;
SUB_INPUT_IS_ESC:
    CALL  SYSVAR_LINP               ;[0DF3] Get next character from input (line input hook)
    CALL  ESC                       ;[0DF6] Test if character is ESC
    RET   NZ                        ;[0DF9] Not ESC: return character to caller
    POP   DE                        ;[0DFA] ESC: discard return addresses to unwind call stack
    POP   DE                        ;[0DFB] 
    POP   BC                        ;[0DFC] 
    LD    IX,(SYSVAR_CURRLP)        ;[0DFD] IX = address of current BASIC line
    JP    STOP1                     ;[0E01] Jump to STOP handler (display "STOP in line N")
    RST   $38                       ;[0E04] (unreachable - padding / breakpoint)

;
; ERROR n -- display error message number n.
;
EERROR:
    RST   $18                       ;[0E05] Evaluate expression -> A (error number)
    JP    DISP_ERROR_A              ;[0E06] Display the error message and return to prompt

;
; LETTER(n) -- returns the address of the character definition for ASCII code n.
; Used to read or redefine character bitmaps in DATA_CHARS.
;
FLETTER:
    CALL  FPINT                     ;[0E09] Convert float to integer -> HL
    LD    A,L                       ;[0E0C] A = character code
    CP    $20                       ;[0E0D] Is it below space ($20)?
    CALL  C,ERR_NUM_OUT_RANGE       ;[0E0F] Yes: error (only printable chars have bitmaps)
    CALL  FONT                      ;[0E12] FONT(A): calculate address of char bitmap
    JP    INTFP                     ;[0E15] Convert integer result back to float and return

;
; MOD(x,y) -- returns the modulus (remainder) of x divided by y, with the
; result having the same sign as the dividend (x).
;
FMOD:
    CALL  SWAP                      ;[0E18] Swap WRA1 and WRA2 so divisor is in WRA1
    CALL  FABSLTE                   ;[0E1B] ABS(x) <= ABS(y)?  (overflow check)
    CALL  PUSH_WRA1                 ;[0E1E] Push dividend onto working register stack
    CALL  PUSH_WRA1                 ;[0E21] Push again (needed for two uses below)
    CALL  SWAP                      ;[0E24] Restore original order
    CALL  DIV                       ;[0E27] WRA1 = x / y
    CALL  FFRAC                     ;[0E2A] WRA1 = fractional part of (x/y)
    CALL  POP_WRA2                  ;[0E2D] WRA2 = dividend
    CALL  _MULT                     ;[0E30] WRA1 = frac(x/y) * y = remainder
    CALL  POP_WRA2                  ;[0E33] WRA2 = original dividend (for sign)
    LD    A,(SYSVAR_WRA1)           ;[0E36] A = sign byte of remainder
    CALL  SUB_MOD                   ;[0E39] Adjust sign to match dividend
JP_FN_INT:
    JP    FINT                      ;[0E3C] Truncate to integer and return

;
; DIV(x,y) -- integer division; returns INT(x/y).
;
FDIV:
    CALL  DIV                       ;[0E3F] WRA1 = x / y (floating point)
    JR    JP_FN_INT                 ;[0E42] Truncate to integer

;
; INK -- returns the current ink colour value as a number.
;
FINK:
    LD    HL,(SYSVAR_INKST)         ;[0E44] HL = ink colour byte
L_TO_WRA1:
    LD    H,$00                     ;[0E47] Clear H (only L is the colour value)
HL_TO_WRA1:
    JP    INTFP                     ;[0E49] Convert integer HL to float in WRA1 and return

;
; PAPER -- returns the current paper colour value as a number.
;
FPAPER:
    LD    HL,(SYSVAR_PAPST)         ;[0E4C] HL = paper colour byte
    JR    L_TO_WRA1                 ;[0E4F] 

;
; POS -- returns the current cursor X position (pixel column).
;
FPOS:
    LD    HL,(SYSVAR_CURSORX)       ;[0E51] HL = cursor X (L) and Y (H)
    JR    L_TO_WRA1                 ;[0E54] Return L (cursor X) as integer

;
; VPOS -- returns the current cursor Y position (pixel row).
;
FVPOS:
    LD    HL,(SYSVAR_CURSORY)       ;[0E56] HL: L = cursor Y
    JR    L_TO_WRA1                 ;[0E59] Return cursor Y as integer

;
; GRAPHIC -- returns the address of the user-defined graphics character table.
;
FGRAPHIC:
    LD    HL,SYSVAR_GPHTBL          ;[0E5B] HL = address of SYSVAR_GPHTBL (pointer to table)
    JR    HL_TO_WRA1                ;[0E5E] 

;
; ALPHA -- returns the address of the standard character definition table.
;
FALPHA:
    LD    HL,SYSVAR_CHRTBL          ;[0E60] HL = address of SYSVAR_CHRTBL (pointer to table)
    JR    HL_TO_WRA1                ;[0E63] 

;
; INF -- returns the floating-point representation of infinity (largest
; representable value: $FF99999999).
;
FINF:
    LD    HL,DATA_INF               ;[0E65] HL -> 5-byte infinity constant
    JP    LNUM1                     ;[0E68] Load 5-byte literal into WRA1 and return

;
; Infinity constant: 5-byte float, exponent $FF, mantissa $9999 9999...
;
DATA_INF:
    DB $FF,$99,$99,$99,$99          ;[0E6B]  Floating-point infinity representation

;
; Utility: loads HL (integer result from WRA1) and BC (integer from WRA2)
; for use by the bitwise operators BNOR, BNXOR and BNAND.
;
HLBC_FROM_WRA12:
    CALL  FPINT                     ;[0E70] Convert WRA1 to integer -> HL
    PUSH  HL                        ;[0E73] Save WRA1 integer
    LD    HL,SYSVAR_WRA2            ;[0E74] HL -> WRA2 floating-point value
    CALL  LNUM1                     ;[0E77] Load WRA2 into WRA1
    CALL  FPINT                     ;[0E7A] Convert WRA2 to integer -> HL
    POP   BC                        ;[0E7D] BC = original WRA1 integer, HL = WRA2 integer
    RET                             ;[0E7E] 

;
; BNOR(x,y) -- bitwise OR of the integer parts of x and y.
;
FBNOR:
    CALL  HLBC_FROM_WRA12           ;[0E7F] HL = x, BC = y as integers
    LD    A,B                       ;[0E82] 
    OR    H                         ;[0E83] High byte: x OR y
    LD    H,A                       ;[0E84] 
    LD    A,C                       ;[0E85] 
    OR    L                         ;[0E86] Low byte: x OR y
BN_RESULT_TO_WRA1:
    LD    L,A                       ;[0E87] HL = result
    JP    INTFP                     ;[0E88] Convert to float and store in WRA1

;
; BNXOR(x,y) -- bitwise XOR of the integer parts of x and y.
;
FBNXOR:
    CALL  HLBC_FROM_WRA12           ;[0E8B] 
    LD    A,B                       ;[0E8E] 
    XOR   H                         ;[0E8F] 
    LD    H,A                       ;[0E90] 
    LD    A,C                       ;[0E91] 
    XOR   L                         ;[0E92] 
    JR    BN_RESULT_TO_WRA1         ;[0E93] 

;
; BNAND(x,y) -- bitwise AND of the integer parts of x and y.
;
FBNAND:
    CALL  HLBC_FROM_WRA12           ;[0E95] 
    LD    A,B                       ;[0E98] 
    AND   H                         ;[0E99] 
    LD    H,A                       ;[0E9A] 
    LD    A,C                       ;[0E9B] 
    AND   L                         ;[0E9C] 
    JR    BN_RESULT_TO_WRA1         ;[0E9D] 

;
; RAND(n) -- returns a random integer in the range 0 to n-1.
;
FRAND:
    CALL  PUSH_WRA1                 ;[0E9F] Push n onto working register stack
    CALL  FRND                      ;[0EA2] WRA1 = RND (0.0 <= RND < 1.0)
    CALL  POP_WRA2                  ;[0EA5] WRA2 = n
    CALL  _MULT                     ;[0EA8] WRA1 = RND * n
    JP    FINT                      ;[0EAB] Return INT(RND * n)

;
; CFR n -- sets the cursor flash rate.
; Stores a 16-bit value from the expression directly into SYSVAR_FLASH.
;
ECFR:
    RST   $18                       ;[0EAE] Evaluate expression -> HL
    LD    (SYSVAR_FLASH),HL         ;[0EAF] Store new flash rate (lower = faster flash)
    RET                             ;[0EB2] 

;
; CCHAR n -- sets the cursor character(s) displayed at the cursor position.
; Stores a 16-bit value into SYSVAR_INPCUR, allowing the cursor shape/char
; to be customised.
;
ECCHAR:
    RST   $18                       ;[0EB3] Evaluate expression -> HL
    LD    (SYSVAR_INPCUR),HL        ;[0EB4] Store cursor character value
    RET                             ;[0EB7] 

;
; Colour value initialisation stubs.
; Each colour function (WHITE..BLUE) shares the same 3-byte sequence to load
; a fixed floating-point value; BLACK is a special case (returns 0).
; The five bytes at FN_WHITE ($AF,$3C,6) decode as: XOR A; LD L,A; then a
; jump into shared code.  The identical bytes for YELLOW through BLUE suggest
; these all return the same numeric code (6) - the colour values are set
; differently via INK/PAPER.
;
FN_WHITE:
    DB    $AF,$3C,6                 ;[0EB8] XOR A; LD L,A; 6 (WHITE colour constant)
FN_YELLOW:
    DB    $AF,$3C,6                 ;[0EBB] (YELLOW)
FN_CYAN:
    DB    $AF,$3C,6                 ;[0EBE] (CYAN)
FN_GREEN:
    DB    $AF,$3C,6                 ;[0EC1] (GREEN)
FN_MAGENTA:
    DB    $AF,$3C,6                 ;[0EC4] (MAGENTA)
FN_RED:
    DB    $AF,$3C,6                 ;[0EC7] (RED)
FN_BLUE:
    DB    $AF,$3C,6                 ;[0ECA] (BLUE)
FN_BLACK:
    XOR   A                         ;[0ECD] A = 0 (BLACK colour code)
    LD    L,A                       ;[0ECE] L = 0
    LD    H,$00                     ;[0ECF] HL = 0
    JP    INTFP                     ;[0ED1] Convert integer 0 to float and return

;
; VDU validation: reads comma-separated expressions until a CR or end of
; statement is reached, storing each evaluated byte into the buffer at HL.
; Used during tokenisation of the VDU statement.
;
IVDU:
    CALL  RP                        ;[0ED4] Evaluate reverse-polish expression -> A
    LD    (HL),A                    ;[0ED7] Store byte in output buffer
    CP    CR                        ;[0ED8] End of statement?
    RET   Z                         ;[0EDA] Yes: done
    INC   HL                        ;[0EDB] Advance buffer pointer
    CP    ','                       ;[0EDC] Comma separator?
    JR    Z,IVDU                    ;[0EDE] Yes: read next value
    CALL  ERR_SYNTAX                ;[0EE0] Neither CR nor comma: syntax error

;
; VDU command runtime: sends each byte stored in DE to the screen driver
; via RST $08, stopping at CR.
;
EVDU:
    RST   $18                       ;[0EE3] Evaluate first argument -> A (via RP)
    RST   $08                       ;[0EE4] Output byte A to screen (VDU handler)
    LD    A,(DE)                    ;[0EE5] Read next byte from evaluated argument list
    CP    CR                        ;[0EE6] End of list?
    RET   Z                         ;[0EE8] Yes: done
    INC   DE                        ;[0EE9] Advance to next byte
    JR    EVDU                      ;[0EEA] Loop

;
; Validation helper: reads 6 comma-separated expressions (for commands that
; take 6 arguments, like PLOT with colour).
;
IE6CR:
    LD    B,$05                     ;[0EEC] 5 more expressions after the first = 6 total
    JR    ICOMMAS_CR                ;[0EEE] 

;
; Validation helper: reads 4 comma-separated expressions (e.g. WINDOW x,y,w,h).
;
IE4CR:
    LD    B,$03                     ;[0EF0] 3 more after first = 4 total
    JR    ICOMMAS_CR                ;[0EF2] 

;
; Validation helper: reads 3 comma-separated expressions (e.g. PLOT x,y or BEEP p,d).
;
ICCCR:
    LD    B,$02                     ;[0EF4] 2 more after first = 3 total

;
; General comma-separated expression reader (B+1 expressions total).
; Reads each expression via RP (reverse polish evaluator), storing the result
; byte in the buffer at HL, separated by ',' tokens in the token stream.
;
ICOMMAS_CR:
    PUSH  BC                        ;[0EF6] Save remaining count
    CALL  RP                        ;[0EF7] Evaluate next expression -> A
    RST   $20                       ;[0EFA] Check for ',' separator token
    DB    ','                       ;[0EFB] Expected separator character
ICOMMAS_CR1:
    LD    (HL),A                    ;[0EFC] Store evaluated byte in buffer
    INC   HL                        ;[0EFD] Advance buffer pointer
    POP   BC                        ;[0EFE] Restore remaining count
    DJNZ  ICOMMAS_CR                ;[0EFF] Decrement and loop if more expressions remain
    JP    IINK                      ;[0F01] Done: validate INK/PAPER suffix if present

;
; Validation for '?' (shorthand for PRINT).
; Backs up one token and re-processes as a PRINT statement.
;
IPRINT:
    DEC   HL                        ;[0F04] Step back one byte in token buffer
    LD    A,PRINT                   ;[0F05] A = PRINT token
    JP    IL2                       ;[0F07] Process as PRINT token

;
; Called from DBASLN (Display Basic Line) to print the raw hex bytes of a
; BASIC line with leading spaces for indentation.  Used by the LIST command
; debug/hex display mode.
;
PRINT_BAS_LINE:
    LD    A,(IX-$01)                ;[0F0A] A = byte count from frame (set by caller)
    SUB   $08                       ;[0F0D] Adjust for header bytes already displayed
    LD    B,A                       ;[0F0F] B = number of data bytes to print
PRINT_BAS_LINE_LOOP:
    CALL  DISPLAY_SPACE             ;[0F10] Print a leading space
    LD    A,(DE)                    ;[0F13] Read next byte from BASIC line
    INC   DE                        ;[0F14] Advance source pointer
    CALL  PRINT_HEX_A               ;[0F15] Print byte as 2 hex digits
    DJNZ  PRINT_BAS_LINE_LOOP       ;[0F18] Loop for all data bytes
    JP    DO_INDENT                 ;[0F1A] Print indentation and continue display

;
; Part of CODE statement validation: reads hex digits into C and stores them
; in the token buffer at HL, stopping at CR or ','.
;
ICODE1:
    LD    A,(DE)                    ;[0F1D] Peek at next character
    LD    (HL),A                    ;[0F1E] Store in token buffer
    CP    $0D                       ;[0F1F] CR = end of statement?
    RET   Z                         ;[0F21] Yes: done
    RST   $20                       ;[0F22] Check for ',' separator
    JR    NZ,ICOMMAS_CR1            ;[0F23] Not comma: treat as next expression byte

;
; Validation for the CODE statement (inline hex data).
; Reads a hex integer using RHEX, then chains to ICODE1 to handle the rest.
;
ICODE:
    CALL  RHEX                      ;[0F25] Read hex digits into C
    LD    (HL),C                    ;[0F28] Store hex value byte in token buffer
    INC   HL                        ;[0F29] Advance buffer pointer
    JR    ICODE1                    ;[0F2A] Handle delimiter

;
; Read a hexadecimal number from the source line into C.
; Accepts 0-9 and A-F (upper case only).  Stops on the first non-hex character.
; Each new digit shifts C left 4 bits (one nibble) and the new nibble is added.
;
RHEX:
    LD    C,$00                     ;[0F2C] C = accumulated hex value
RHEX1:
    LD    A,(DE)                    ;[0F2E] Read next character
    SUB   '0'                       ;[0F2F] Subtract '0' (ASCII offset)
    RET   C                         ;[0F31] Below '0': not a hex digit, return
    CP    $0A                       ;[0F32] 0-9?
    JR    C,RHEX2                   ;[0F34] Yes: digit is valid as-is
    SUB   $07                       ;[0F36] 'A'-'F': adjust by 7 (A=10..F=15)
    CP    $0A                       ;[0F38] Now in range 10..15?
    RET   C                         ;[0F3A] No (was between '9' and 'A'): not hex, return
    CP    $10                       ;[0F3B] Larger than F (>15)?
    RET   NC                        ;[0F3D] Yes: not a valid hex digit, return
RHEX2:
    SLA   C                         ;[0F3E] Shift C left 4 bits (4 x SLA)
    SLA   C                         ;[0F40] 
    SLA   C                         ;[0F42] 
    SLA   C                         ;[0F44] 
    ADD   A,C                       ;[0F46] Add new nibble to low bits
    LD    C,A                       ;[0F47] C = updated accumulator
    INC   DE                        ;[0F48] Advance source pointer past this digit
    JR    RHEX1                     ;[0F49] Read next digit

;
; INK n -- sets the ink (foreground) colour.
; Stores the evaluated byte from RST $18 into SYSVAR_INKST.
;
EINK:
    RST   $18                       ;[0F4B] Evaluate expression -> A
    LD    (SYSVAR_INKST),A          ;[0F4C] Update ink colour system variable
    RET                             ;[0F4F] 

;
; PAPER n -- sets the paper (background) colour.
; Stores the evaluated byte into SYSVAR_PAPST.
;
EPAPER:
    RST   $18                       ;[0F50] Evaluate expression -> A
    LD    (SYSVAR_PAPST),A          ;[0F51] Update paper colour system variable
    RET                             ;[0F54] 

;
; MOVE x,y -- sets the graphics cursor position without drawing.
; Stores X (16-bit) in SYSVAR_GOLDX and Y (8-bit) in SYSVAR_GOLDY.
;
EMOVE:
    RST   $18                       ;[0F55] Evaluate X expression -> HL
    INC   DE                        ;[0F56] Skip comma separator
    LD    (SYSVAR_GOLDX),HL         ;[0F57] Store graphics cursor X
    RST   $18                       ;[0F5A] Evaluate Y expression -> A
    LD    (SYSVAR_GOLDY),A          ;[0F5B] Store graphics cursor Y
    RET                             ;[0F5E]
;
; DRAW x,y -- draws a line from the current graphics cursor position to (x,y).
; Stores the destination coordinates in SYSVAR_GNEWX/SYSVAR_GNEWY then calls
; the line-draw hook (SYSVAR_GLINE).  After the draw the graphics cursor is
; implicitly updated by the line routine.
;
EDRAW:
    RST   $18                       ;[0F5F] Evaluate X argument -> HL
    INC   DE                        ;[0F60] Skip comma separator
    LD    (SYSVAR_GNEWX),HL         ;[0F61] Store destination X
    RST   $18                       ;[0F64] Evaluate Y argument -> A
    LD    (SYSVAR_GNEWY),A          ;[0F65] Store destination Y
    JP    SYSVAR_GLINE              ;[0F68] Draw line from GOLD(X,Y) to GNEW(X,Y)

;
; PLOT submode 1: relative MOVE.
; Reads dx,dy offsets and adds them to the current graphics cursor position
; (SYSVAR_GOLDX / SYSVAR_GOLDY), updating the cursor in place without drawing.
;
SUB_PLOT1:
    RST   $18                       ;[0F6B] Evaluate dx offset -> HL
    INC   DE                        ;[0F6C] Skip comma
    LD    BC,(SYSVAR_GOLDX)         ;[0F6D] BC = current graphics X
    ADD   HL,BC                     ;[0F71] HL = new X (current + dx)
    LD    (SYSVAR_GOLDX),HL         ;[0F72] Update graphics cursor X
    RST   $18                       ;[0F75] Evaluate dy offset -> L
    LD    A,(SYSVAR_GOLDY)          ;[0F76] A = current graphics Y
    ADD   A,L                       ;[0F79] A = new Y (current + dy)
    LD    (SYSVAR_GOLDY),A          ;[0F7A] Update graphics cursor Y
    RET                             ;[0F7D] 

;
; PLOT submode 2: relative DRAW.
; Reads dx,dy offsets, adds them to the current graphics cursor to form the
; destination (SYSVAR_GNEWX / SYSVAR_GNEWY), then draws the line.
;
SUB_PLOT2:
    RST   $18                       ;[0F7E] Evaluate dx offset -> HL
    INC   DE                        ;[0F7F] Skip comma
    LD    BC,(SYSVAR_GOLDX)         ;[0F80] BC = current graphics X
    ADD   HL,BC                     ;[0F84] HL = destination X
    LD    (SYSVAR_GNEWX),HL         ;[0F85] Store as new X target
    RST   $18                       ;[0F88] Evaluate dy offset -> L
    LD    A,(SYSVAR_GOLDY)          ;[0F89] A = current graphics Y
    ADD   A,L                       ;[0F8C] A = destination Y
    LD    (SYSVAR_GNEWY),A          ;[0F8D] Store as new Y target
    JP    SYSVAR_GLINE              ;[0F90] Draw line from GOLD to GNEW

;
; PLOT submode 4 (DOT): absolute plot of a single point.
; Stores the given (x,y) as both the old and new graphics cursor position
; so that calling SYSVAR_GLINE draws a zero-length line (i.e. a single dot).
;
EDOT:
    RST   $18                       ;[0F93] Evaluate X -> HL
    INC   DE                        ;[0F94] Skip comma
    LD    (SYSVAR_GNEWX),HL         ;[0F95] Destination X = given X
    LD    (SYSVAR_GOLDX),HL         ;[0F98] Source X = same (zero-length line -> dot)
    RST   $18                       ;[0F9B] Evaluate Y -> A
    LD    (SYSVAR_GNEWY),A          ;[0F9C] Destination Y = given Y
    LD    (SYSVAR_GOLDY),A          ;[0F9F] Source Y = same
    JP    SYSVAR_GLINE              ;[0FA2] "Draw" zero-length line = plot dot

;
; PLOT mode,x,y -- general graphics command dispatcher.
; Reads a mode byte and dispatches to the appropriate submode:
;   0 -> EMOVE  (absolute move, no draw)
;   1 -> SUB_PLOT1 (relative move)
;   2 -> EDRAW  (absolute draw)
;   3 -> SUB_PLOT2 (relative draw)
;   4 -> EDOT   (plot dot)
; Modes 5+ are reserved ("not yet implemented").
; Modes >= 5 fall into a partial Bresenham line-draw implementation (below)
; that appears unfinished.
;
EPLOT:
    RST   $18                       ;[0FA5] Evaluate mode byte -> HL (L = mode)
    INC   DE                        ;[0FA6] Skip comma
    OR    A                         ;[0FA7] Test L (mode); also clears carry for SBC below
    JP    Z,EMOVE                   ;[0FA8] Mode 0: absolute MOVE
    DEC   L                         ;[0FAB] 
    JP    Z,SUB_PLOT1               ;[0FAC] Mode 1: relative MOVE
    DEC   L                         ;[0FAF] 
    JP    Z,EDRAW                   ;[0FB0] Mode 2: absolute DRAW
    DEC   L                         ;[0FB3] 
    JP    Z,SUB_PLOT2               ;[0FB4] Mode 3: relative DRAW
    DEC   L                         ;[0FB7] 
    JP    Z,EDOT                    ;[0FB8] Mode 4: DOT (single pixel)
    CALL  ERR_NOT_YET_IMP           ;[0FBB] Mode 5+: unimplemented (would return here)
    ; --- Partial Bresenham line-draw (modes 5+, likely incomplete) ---
    LD    HL,(SYSVAR_GNEWX)         ;[0FBE] HL = destination X
    PUSH  HL                        ;[0FC1] Save for cursor update later
    LD    DE,(SYSVAR_GOLDX)         ;[0FC2] DE = source X
    LD    H,$00                     ;[0FC6] Zero H (use only 8-bit X delta)
    LD    D,H                       ;[0FC8] Zero D
    OR    A                         ;[0FC9] Clear carry
    SBC   HL,DE                     ;[0FCA] HL = dx (destination X - source X)
    EX    DE,HL                     ;[0FCC] DE = dx
    LD    HL,($6264)                ;[0FCD] HL = (address $6264) [unknown sysvar]
    LD    L,$80                     ;[0FD0] L = $80 (fractional accumulator init)
    EXX                             ;[0FD2] Switch to alternate register set
    LD    HL,(SYSVAR_GNEWY)         ;[0FD3] HL' = destination Y (in L)
    PUSH  HL                        ;[0FD6] Save for cursor update
    LD    DE,(SYSVAR_GOLDY)         ;[0FD7] DE' = source Y (in E)
    LD    H,$00                     ;[0FDB] Zero H'
    LD    D,H                       ;[0FDD] Zero D'
    OR    A                         ;[0FDE] Clear carry
    SBC   HL,DE                     ;[0FDF] HL' = dy (destination Y - source Y)
    EX    DE,HL                     ;[0FE1] DE' = dy
    LD    HL,($6266)                ;[0FE2] HL' = (address $6266) [unknown sysvar]
    LD    L,$80                     ;[0FE5] L' = $80 (fractional accumulator init)
    LD    A,D                       ;[0FE7] 
    OR    E                         ;[0FE8] Is dy == 0?
    EXX                             ;[0FE9] Restore main registers
    LD    B,$01                     ;[0FEA] B = step count (at least 1 pixel)
    OR    E                         ;[0FEC] Is dx also 0? (combined with dy test above)
    OR    D                         ;[0FED] 
    JR    Z,EPLOT4                  ;[0FEE] Both zero: plot a single point
    DEC   B                         ;[0FF0] B = 0: use Bresenham algorithm
    CALL  SUB_PLOT5                 ;[0FF1] Test sign bits of dx and dy
    JR    NZ,EPLOT2                 ;[0FF4] Signs differ: major axis is X
    SCF                             ;[0FF6] Signs same: set carry for initial step
EPLOT1:
    RR    B                         ;[0FF7] Rotate carry into B (select axis)
    CALL  SUB_PLOT4                 ;[0FF9] Double the deltas (scale step)
    CALL  SUB_PLOT5                 ;[0FFC] Test sign bits again
    JR    Z,EPLOT1                  ;[0FFF] Still same sign: keep scaling
EPLOT2:
    CALL  SUB_PLOT3                 ;[1001] Plot one pixel
EPLOT3:
    ADD   HL,DE                     ;[1004] Accumulate X step (main registers)
    EXX                             ;[1005] 
    ADD   HL,DE                     ;[1006] Accumulate Y step (alternate registers)
    EXX                             ;[1007] 
EPLOT4:
    CALL  SUB_PLOT3                 ;[1008] Plot one pixel at current position
    DJNZ  EPLOT3                    ;[100B] Decrement step count; loop
    POP   HL                        ;[100D] Restore destination Y
    LD    A,L                       ;[100E] 
    LD    (SYSVAR_GOLDY),A          ;[100F] Update graphics cursor Y to destination
    POP   HL                        ;[1012] Restore destination X
    LD    (SYSVAR_GOLDX),HL         ;[1013] Update graphics cursor X to destination
    RET                             ;[1016] 

;
; PLOT helper: plots a single pixel at the screen position calculated from
; the current Bresenham accumulator values.
; Converts the 16-bit X/Y accumulators to a byte offset and bit mask within
; the video RAM, then calls SYSVAR_OUTB to write the pixel in the current
; ink colour.
;
; The Lynx screen is 256 pixels wide and 248 pixels tall.
; Each row is 32 bytes wide (KBPERL = 32); each pixel is 1 bit (32 * 8 = 256).
; Byte offset = (Y * 32) + (X >> 3); bit position = X AND 7 (MSB first).
;
SUB_PLOT3:
    EXX                             ;[1017] Access alternate registers
    LD    A,H                       ;[1018] A = high byte of Y accumulator (integer Y)
    EXX                             ;[1019] Restore main registers
    PUSH  HL                        ;[101A] Save X accumulator
    PUSH  DE                        ;[101B] Save X step
    PUSH  BC                        ;[101C] Save loop counter
    LD    L,A                       ;[101D] L = integer Y
    LD    A,H                       ;[101E] A = high byte of X accumulator (integer X)
    LD    H,$00                     ;[101F] H = 0
    ADD   HL,HL                     ;[1021] HL = Y * 2
    ADD   HL,HL                     ;[1022] HL = Y * 4
    ADD   HL,HL                     ;[1023] HL = Y * 8
    ADD   HL,HL                     ;[1024] HL = Y * 16
    ADD   HL,HL                     ;[1025] HL = Y * 32 (row byte offset)
    LD    C,A                       ;[1026] C = integer X
    SRL   C                         ;[1027] C = X >> 1
    SRL   C                         ;[1029] C = X >> 2
    SRL   C                         ;[102B] C = X >> 3 (byte column within row)
    LD    B,$00                     ;[102D] 
    ADD   HL,BC                     ;[102F] HL = byte offset = Y*32 + X/8
    LD    C,$80                     ;[1030] C = $80 = 10000000b (start with MSB set)
    AND   $07                       ;[1032] A = X AND 7 (bit position within byte, 0=MSB)
    JR    Z,SUB_PLOT3B              ;[1034] Bit 0: C is already correct ($80)
SUB_PLOT3A:
    SRL   C                         ;[1036] Shift bit mask right
    DEC   A                         ;[1038] Decrement bit position counter
    JR    NZ,SUB_PLOT3A             ;[1039] Repeat until bit mask is in correct position
SUB_PLOT3B:
    LD    A,C                       ;[103B] A = pixel bit mask
    CPL                             ;[103C] Invert: A = background mask (0 where pixel is)
    LD    C,A                       ;[103D] C = mask byte for OUTB (bits to preserve)
    CPL                             ;[103E] Restore: A = pixel data byte (1 bit set)
    CALL  SYSVAR_OUTB               ;[103F] Write pixel: data=A, mask=C, offset=HL
    POP   BC                        ;[1042] Restore loop counter
    POP   DE                        ;[1043] Restore X step
    POP   HL                        ;[1044] Restore X accumulator
    RET                             ;[1045] 

;
; PLOT helper: left-shifts both the main DE (X delta) and alternate DE' (Y delta)
; by one bit, effectively doubling both step values.  Used by the Bresenham
; setup loop to find the dominant axis.
;
SUB_PLOT4:
    SLA   E                         ;[1046] Shift X delta low byte left
    RL    D                         ;[1048] Shift carry into X delta high byte
    EXX                             ;[104A] Switch to alternate registers
    SLA   E                         ;[104B] Shift Y delta low byte left
    RL    D                         ;[104D] Shift carry into Y delta high byte
    EXX                             ;[104F] Restore main registers
    RET                             ;[1050] 

;
; PLOT helper: tests whether the sign bits (bit 7) of the main DE (X delta)
; and alternate DE' (Y delta) differ.  Returns Z if signs are the same,
; NZ if they differ.  Used to determine the dominant axis for the Bresenham
; line algorithm.
;
SUB_PLOT5:
    EXX                             ;[1051] Access alternate registers
    LD    A,D                       ;[1052] A = Y delta high byte
    XOR   E                         ;[1053] XOR with Y delta low byte
    AND   $80                       ;[1054] Isolate sign bit
    EXX                             ;[1056] Restore main registers
    LD    C,A                       ;[1057] C = Y sign result
    LD    A,D                       ;[1058] A = X delta high byte
    XOR   E                         ;[1059] XOR with X delta low byte
    AND   $80                       ;[105A] Isolate sign bit
    OR    C                         ;[105C] Combine X and Y sign results
    RET                             ;[105D] Returns Z if both signs equal, NZ if differ

;
; Prints a string pointed to by HL, terminated by CR ($0D).
; Each character is output via RST $08 (the screen character output handler).
; HL is advanced past the CR on return.
;
PRTSTR:
    LD    A,(HL)                    ;[105E] Read next character
    CP    CR                        ;[105F] Is it the CR terminator?
    RET   Z                         ;[1061] Yes: done (HL points to the CR)
    RST   $08                       ;[1062] Output character to screen
    INC   HL                        ;[1063] Advance string pointer
    JR    PRTSTR                    ;[1064] Loop

;
; Waits for a keypress, flashing the cursor while waiting.
; Calls CFLASH to toggle the cursor at the rate set by SYSVAR_FLASH, then
; calls KEY to poll the keyboard.  Loops until a non-zero key code is returned.
;
INPKEY:
    CALL  CFLASH                    ;[1066] Toggle cursor if flash period has elapsed
    CALL  KEY                       ;[1069] Poll keyboard (returns 0 if no key)
    OR    A                         ;[106C] Key pressed?
    JR    Z,INPKEY                  ;[106D] No: keep flashing and waiting
    RET                             ;[106F] Yes: A = key character code

;
; Displays the current input buffer contents with a trailing space, while
; preserving the cursor X position so it appears to stay still on screen.
; Called after each character insert/delete to refresh the visible line.
; The buffer is at HL and terminated by CR; a space is printed before and
; after the content to erase any previous character at the edges.
;
DISPLAY_BUFFER:
    PUSH  HL                        ;[1070] Save buffer pointer
    PUSH  DE                        ;[1071] Save cursor position
    LD    DE,(SYSVAR_CURSORX)       ;[1072] DE = current cursor position (to restore later)
    LD    A,$20                     ;[1076] Space character
    RST   $08                       ;[1078] Print leading space (erases leftover char)
    DEC   HL                        ;[1079] Step back one (will be incremented in loop)
DISPLAY_BUFFER1:
    INC   HL                        ;[107A] Advance to next character
    LD    A,(HL)                    ;[107B] Read character
    CP    $0D                       ;[107C] CR = end of buffer?
    JR    Z,DISPLAY_BUFFER2         ;[107E] Yes: print trailing space and finish
    RST   $08                       ;[1080] No: output character to screen
    JR    DISPLAY_BUFFER1           ;[1081] Loop
DISPLAY_BUFFER2:
    LD    A,$20                     ;[1083] Trailing space (erases any character past end)
    RST   $08                       ;[1085] Print it
    LD    (SYSVAR_CURSORX),DE       ;[1086] Restore cursor X to its saved position
    POP   DE                        ;[108A] 
    POP   HL                        ;[108B] 
    RET                             ;[108C] 

;
; Scans forward from DE until a CR ($0D) is found.
; Increments B for each character skipped (counting characters to end of line).
; Returns with DE pointing to the CR and B = count of characters skipped.
;
FINDCR:
    LD    A,(DE)                    ;[108D] Read character at DE
    CP    $0D                       ;[108E] Is it CR?
    RET   Z                         ;[1090] Yes: done, DE -> CR
    INC   B                         ;[1091] Count one more character
    INC   DE                        ;[1092] Advance pointer
    JR    FINDCR                    ;[1093] Loop

;
; Cursor flash routine: manages the blinking cursor during line input.
; Uses the alternate HL register pair as a countdown timer (initialised from
; SYSVAR_FLASH = KFLASH = $200).  When the counter reaches zero the two cursor
; characters in B' and C' are swapped, one is printed, and the cursor is
; immediately backspaced so subsequent characters appear to overwrite it.
;
; The alternate registers carry persistent state across calls:
;   HL' = countdown timer
;   B'  = character currently on screen at cursor position
;   C'  = character to replace it with on next flash
;
CFLASH:
    EXX                             ;[1095] Switch to alternate registers (HL', B', C')
    DEC   HL                        ;[1096] Decrement flash countdown timer
    LD    A,H                       ;[1097] 
    OR    L                         ;[1098] Has timer reached zero?
    JR    NZ,CFLASH1                ;[1099] No: timer still running, no flash yet
    LD    HL,(SYSVAR_FLASH)         ;[109B] Yes: reload timer from SYSVAR_FLASH ($200)
SWAP_CCHARS:
    LD    A,B                       ;[109E] A = current cursor character
    LD    B,C                       ;[109F] B = alternate cursor character (now current)
    LD    C,A                       ;[10A0] C = old current character (now alternate)
    RST   $08                       ;[10A1] Print the new cursor character at cursor pos
    LD    A,CLEFT                   ;[10A2] VDU 22 = cursor-left (backspace without erase)
    RST   $08                       ;[10A4] Step cursor back so next char overwrites cursor
CFLASH1:
    EXX                             ;[10A5] Restore main registers
    RET                             ;[10A6] 

;
; Insert character into input buffer at the current edit position.
; Inserts A into the buffer at HL, shifting everything from HL to DE
; (end of buffer) one byte to the right using LDDR (copy backwards),
; then refreshes the display.
;
; Register use during LINP:
;   HL = pointer to current insert position in buffer
;   DE = pointer to end of buffer (one past last char, where CR is)
;   B  = number of characters in the buffer
;   C  = index of edit cursor within the buffer
; The buffer is in INPBUF ($6000), max length MAXLEN (240) characters.
;
CHAR_INPUT:
    EX    AF,AF'                    ;[10A7] Save character to insert in A'
    LD    A,B                       ;[10A8] A = current buffer length
    CP    MAXLEN                    ;[10A9] Buffer full (240 chars)?
    JR    NC,LINP2                  ;[10AB] Yes: discard character and loop back
    EX    AF,AF'                    ;[10AD] Restore character in A
    RST   $08                       ;[10AE] Echo character to screen
    INC   DE                        ;[10AF] Extend buffer end by one byte
    PUSH  HL                        ;[10B0] Save insert position
    PUSH  DE                        ;[10B1] Save new buffer end
    PUSH  BC                        ;[10B2] Save counts
    PUSH  DE                        ;[10B3] DE = source for LDDR (new end)
    EX    DE,HL                     ;[10B4] HL = new end, DE = insert position
    OR    A                         ;[10B5] Clear carry
    SBC   HL,DE                     ;[10B6] HL = number of bytes to shift (new_end - insert_pos)
    LD    C,L                       ;[10B8] BC = byte count for LDDR
    LD    B,H                       ;[10B9] 
    POP   DE                        ;[10BA] DE = new end (LDDR destination)
    LD    L,E                       ;[10BB] HL = DE - 1 = old end (LDDR source)
    LD    H,D                       ;[10BC] 
    DEC   HL                        ;[10BD] HL -> last byte of old content
    LDDR                            ;[10BE] Shift buffer content right by 1 byte
    POP   BC                        ;[10C0] Restore counts
    POP   DE                        ;[10C1] Restore buffer end
    POP   HL                        ;[10C2] Restore insert position
    LD    (HL),A                    ;[10C3] Store new character at insert position
    INC   HL                        ;[10C4] Advance insert pointer
    CALL  DISPLAY_BUFFER            ;[10C5] Refresh screen display of buffer
    INC   B                         ;[10C8] Increment total character count
    INC   C                         ;[10C9] Increment cursor position index
    JR    LINP2                     ;[10CA] Return to input loop

;
; Initialises the line input state for a fresh input operation.
; Sets up the buffer pointers, clears the character count and cursor index,
; loads the flash timer and cursor characters from SYSVAR_FLASH/SYSVAR_INPCUR
; into the alternate register set, and returns.
;
; On return (main registers):
;   HL = DE = INPBUF start
;   BC = 0 (B = length, C = cursor index)
; On return (alternate registers):
;   HL' = flash countdown timer
;   B'C' = cursor character pair
;
LINPS:
    LD    HL,INPBUF                 ;[10CC] HL -> input buffer start ($6000)
    LD    D,H                       ;[10CF] DE = HL = INPBUF
    LD    E,L                       ;[10D0] 
    LD    BC,$0000                  ;[10D1] B = 0 (buffer length), C = 0 (cursor index)
    EXX                             ;[10D4] Switch to alternate registers
    LD    HL,(SYSVAR_FLASH)         ;[10D5] HL' = initial flash countdown ($200)
    LD    BC,(SYSVAR_INPCUR)        ;[10D8] B'C' = cursor character pair (from SYSVAR_INPCUR)
    EXX                             ;[10DC] Restore main registers
    RET                             ;[10DD] 

;
; Handles CR in the input buffer: writes a CR byte at HL and falls through
; to LINP9 to process the completed line.
;
LINP_CRLF:
    LD    (HL),CR                   ;[10DE] Terminate buffer with CR
    JR    LINP9                     ;[10E0] Process the completed line

;
; Line input routine - the main entry point called via SYSVAR_LINP.
; Initialises the input state (via LINPS), turns the cursor off, then
; waits for keyboard input (via INPKEY).
; Checks the first key for RLAST (value 17, a special "recall last line" key):
; if pressed, the previous buffer content is recalled and displayed; otherwise
; the buffer is cleared with a CR.  Then enters the main character dispatch
; loop (LINP2).
;
LINP:
    CALL  LINPS                     ;[10E2] Initialise input buffer and flash state
    LD    A,CUROFF                  ;[10E5] A = VDU 15 (cursor off)
    RST   $08                       ;[10E7] Turn cursor off while waiting for first key
    CALL  INPKEY                    ;[10E8] Wait for first keypress (with cursor flash)
    CP    RLAST                     ;[10EB] Is it the "recall last line" key (value 17)?
    JR    NZ,LINP_CRLF              ;[10ED] No: start with empty buffer (write CR)
LINP12:
    CALL  FINDCR                    ;[10EF] Scan buffer to find end (sets B = length)
    CALL  DISPLAY_BUFFER            ;[10F2] Display current buffer content on screen
LINP2:
    EXX                             ;[10F5] Access alternate registers
    LD    A,B                       ;[10F6] A = cursor character (B' = current cursor char)
    RST   $08                       ;[10F7] Print cursor character at current position
    LD    A,CLEFT                   ;[10F8] VDU 22 = cursor-left (backspace without erase)
    RST   $08                       ;[10FA] Step back so next output overlaps cursor
    EXX                             ;[10FB] Restore main registers
    CALL  INPKEY                    ;[10FC] Wait for next keypress
LINP9:
    CP    $20                       ;[10FF] Is it a printable character (space or above)?
    JR    NC,CHAR_INPUT             ;[1101] Yes: insert into buffer
    CP    $08                       ;[1103] Backspace (delete char left)?
    JR    Z,LINP8                   ;[1105] Yes: handle delete
    CP    CUP                       ;[1107] Cursor up (move to start of line)?
    JP    Z,LINPU                   ;[1109] Yes
    CP    CDOWN                     ;[110C] Cursor down (move to end of line)?
    JP    Z,LINPD                   ;[110E] Yes
    CP    CLEFT                     ;[1111] Cursor left (move back one char)?
    JR    Z,LINP4                   ;[1113] Yes
    CP    CRIGHT                    ;[1115] Cursor right (move forward one char)?
    JR    Z,LINP6                   ;[1117] Yes
    CP    $05                       ;[1119] CTRL-E (invoke line editor)?
    JP    Z,EDIT                    ;[111B] Yes
    CP    CR                        ;[111E] Carriage return (accept line)?
    JR    NZ,LINP2                  ;[1120] Unknown control: ignore, loop back
    CALL  PRTSTR                    ;[1122] Print any remaining chars in buffer (cleans display)
    LD    A,' '                     ;[1125] Print trailing space
    RST   $08                       ;[1127] 
    LD    A,CR                      ;[1128] Print CR to move to next line
    RST   $08                       ;[112A] 
    INC   B                         ;[112B] Test B: is buffer empty? (INC then DEC)
    DEC   B                         ;[112C] (Flags set; actual value unchanged)
    RET                             ;[112D] Return with Z set if empty, NZ if line entered

;
; Left arrow key: moves the edit cursor one character to the left.
; If already at the start of the buffer (C=0), does nothing.
; Otherwise decrements both the buffer pointer and the cursor index,
; redisplays the character (to ensure it is visible), and loops back.
;
LINP4:
    DEC   C                         ;[112E] Test C (cursor index): was it 0?
    INC   C                         ;[112F] Restore C (flags reflect the DEC)
    JR    Z,LINP2                   ;[1130] C was 0: already at start, ignore
    DEC   HL                        ;[1132] Move buffer pointer back one character
    DEC   C                         ;[1133] Decrement cursor index
    LD    A,(HL)                    ;[1134] Read the character we just stepped over
    RST   $08                       ;[1135] Redisplay it (moves screen cursor right)
    LD    A,$16                     ;[1136] VDU 22 = cursor-left (VDU backspace)
    RST   $08                       ;[1138] Step screen cursor back left

;
; Shared output and loop: outputs A to screen then returns to LINP2.
;
LINP_OUTA:
    RST   $08                       ;[1139] Output character in A
    JR    LINP2                     ;[113A] Back to input loop

;
; Right arrow key: moves the edit cursor one character to the right.
; If already at the end of the buffer (current char is CR), does nothing.
; Otherwise advances both the buffer pointer and the cursor index, and
; outputs the character (which moves the screen cursor right).
;
LINP6:
    LD    A,(HL)                    ;[113C] Read character at current buffer position
    CP    CR                        ;[113D] Already at end of buffer?
    JR    Z,LINP2                   ;[113F] Yes: ignore
    INC   HL                        ;[1141] Advance buffer pointer
    INC   C                         ;[1142] Increment cursor index
    JR    LINP_OUTA                 ;[1143] Output character (moves screen cursor right)

;
; Backspace/delete: removes the character immediately to the left of the
; cursor from the buffer.  If at the start (C=0), does nothing.
; The buffer content from HL onwards is shifted left by one byte using LDIR,
; effectively closing the gap.  The display is then refreshed.
;
LINP8:
    DEC   C                         ;[1145] Test C: was cursor at start?
    INC   C                         ;[1146] Restore C
    JR    Z,LINP2                   ;[1147] Yes: nothing to delete, loop
    DEC   HL                        ;[1149] Step back to character to delete
    PUSH  HL                        ;[114A] Save new buffer position
    PUSH  DE                        ;[114B] Save buffer end pointer
    PUSH  BC                        ;[114C] Save counts
    EX    DE,HL                     ;[114D] DE = destination (position of deleted char)
    OR    A                         ;[114E] Clear carry
    SBC   HL,DE                     ;[114F] HL = number of bytes to shift (end - dest)
    LD    C,L                       ;[1151] BC = shift count
    LD    B,H                       ;[1152] 
    LD    L,E                       ;[1153] HL = source = destination + 1
    LD    H,D                       ;[1154] 
    INC   HL                        ;[1155] HL -> char after deleted position
    LDIR                            ;[1156] Shift buffer left by 1 byte
    POP   BC                        ;[1158] Restore counts
    POP   DE                        ;[1159] Restore buffer end
    POP   HL                        ;[115A] Restore buffer position (now points to next char)
    DEC   DE                        ;[115B] Buffer is one byte shorter
    DEC   B                         ;[115C] Decrement total character count
    DEC   C                         ;[115D] Decrement cursor index
    LD    A,CLEFT                   ;[115E] VDU 22 = cursor-left (backspace the display)
    RST   $08                       ;[1160] 
    CALL  DISPLAY_BUFFER            ;[1161] Refresh display from new buffer content
    JP    LINP2                     ;[1164] Return to input loop

;
; CTRL-E: in-line editor.
; Allows the user to type a line number, then retrieves and displays that
; BASIC line for editing. The displayed line is written via the EDITS hook
; into INPBUF so LINP12 can treat it as a recalled line.
; If B is non-zero (buffer not empty), the edit is ignored.
;
EDIT:
    INC   B                         ;[1167] Test B: is buffer already non-empty?
    DEC   B                         ;[1168] (Restore B; flags set)
    JP    NZ,LINP2                  ;[1169] Non-empty: ignore CTRL-E
    LD    HL,EDTMSG                 ;[116C] HL -> "Line number? " prompt string
    CALL  PLINE                     ;[116F] Print prompt
    CALL  LINPS                     ;[1172] Re-initialise input state
    CALL  LINP_CRLF                 ;[1175] Get input from user (line number)
    LD    DE,INPBUF                 ;[1178] DE -> input buffer (contains the line number)
    RST   $10                       ;[117B] Skip leading spaces in DE
    CALL  RDN                       ;[117C] Read number from DE into WRA1
    CALL  FNDLN_WRA1                ;[117F] Find that BASIC line; IX -> line if found
    CALL  NZ,ERR_NOT_FOUND          ;[1182] Not found: error (does not return)
    LD    HL,(SYSVAR_PRINTD)        ;[1185] Save current display driver address
    PUSH  HL                        ;[1188] 
    LD    HL,EDITS                  ;[1189] HL -> EDITS character intercept routine
    LD    (SYSVAR_PRINTD),HL        ;[118C] Redirect display driver to EDITS
    LD    HL,INPBUF                 ;[118F] HL -> input buffer
    LD    (SYSVAR_EDST),HL          ;[1192] Initialise edit buffer write pointer
    XOR   A                         ;[1195] A = 0 (no leading space before command)
    LD    (SYSVAR_SBC),A            ;[1196] Clear "space before command" flag
    CALL  SYSVAR_DBASLN             ;[1199] Display the BASIC line (feeds chars through EDITS)
    POP   HL                        ;[119C] Restore original display driver address
    LD    (SYSVAR_PRINTD),HL        ;[119D] Reinstall original display driver
    CALL  LINPS                     ;[11A0] Re-initialise input state for editing
    JP    LINP12                    ;[11A3] Enter edit loop with the retrieved line

;
; Display driver intercept used by EDIT.
; Receives each character output by SYSVAR_DBASLN and writes it into the edit
; buffer (INPBUF) via SYSVAR_EDST, converting VDU 30 (clear to end of line)
; to a CR so the buffer is properly terminated.
;
EDITS:
    PUSH  AF                        ;[11A6] 
    CP    CEL                       ;[11A7] Is character VDU 30 (clear to end of line)?
    JR    NZ,EDITS1                 ;[11A9] No: store as-is
    LD    A,CR                      ;[11AB] Yes: convert to CR (buffer terminator)
EDITS1:
    PUSH  HL                        ;[11AD] 
    LD    HL,(SYSVAR_EDST)          ;[11AE] HL -> current write position in edit buffer
    LD    (HL),A                    ;[11B1] Store character
    INC   HL                        ;[11B2] Advance write pointer
    LD    (SYSVAR_EDST),HL          ;[11B3] Update SYSVAR_EDST
    POP   HL                        ;[11B6] 
    POP   AF                        ;[11B7] 
    RET                             ;[11B8] 

;
; Prompt string for CTRL-E editor.
;
EDTMSG:
    DB    "Line number? ",0         ;[11B9] NUL-terminated prompt

;
; Cursor-up key: moves the edit cursor to the start of the buffer.
; Repeatedly steps HL back and decrements C until C reaches zero
; (the beginning of the line), outputting each character passed through
; so the screen cursor follows.
;
LINPU:
    DEC   C                         ;[11C7] Test C: already at start?
    INC   C                         ;[11C8] Restore C
    JP    Z,LINP2                   ;[11C9] Yes: at start, nothing to do
    DEC   HL                        ;[11CC] Move buffer pointer back
    DEC   C                         ;[11CD] Decrement cursor index
    LD    A,(HL)                    ;[11CE] Read character at new position
    RST   $08                       ;[11CF] Output it (moves screen cursor right)
    LD    A,$16                     ;[11D0] VDU 22 = cursor-left
    RST   $08                       ;[11D2] Step screen cursor back
    RST   $08                       ;[11D3] Step screen cursor back again (2x for char width)
    JR    LINPU                     ;[11D4] Loop until at start

;
; Cursor-down key: moves the edit cursor to the end of the buffer (just
; before the CR).  Outputs each character passed through so the screen
; cursor follows.
;
LINPD:
    LD    A,(HL)                    ;[11D6] Read character at current buffer position
    CP    CR                        ;[11D7] Already at end?
    JP    Z,LINP2                   ;[11D9] Yes: nothing to do
    INC   HL                        ;[11DC] Advance buffer pointer
    INC   C                         ;[11DD] Increment cursor index
    RST   $08                       ;[11DE] Output character (moves screen cursor right)
    JR    LINPD                     ;[11DF] Loop until CR found

;
; Non-command token table (DATA_TTBS).
; Maps BASIC function and operator names to their token bytes.
; Each entry is encoded with the last character of the name having bit 7 set
; (the S flag in the assembler source marks these bytes with +S = +$80).
; The table is scanned sequentially by the tokeniser.
;
DATA_TTBS:
    DB    'M'+S,"EM"                ;[11E1] MEM     - free memory
    DB    'P'+S,"I"                 ;[11E4] PI      - mathematical pi
    DB    'K'+S,"EYN"               ;[11E6] INKEY   - keyboard scan (numeric)
    DB    'R'+S,"ND"                ;[11EA] RND     - random number
    DB    'H'+S,"L"                 ;[11ED] HL      - Z80 HL register value
    DB    'L'+S,"EN("               ;[11EF] LEN(    - string length
    DB    'V'+S,"AL("               ;[11F3] VAL(    - string to number
    DB    'A'+S,"SC("               ;[11F7] ASC(    - ASCII code of first char
    DB    'H'+S,"IMEM"              ;[11FB] HIMEM   - top of free memory
    DB    'G'+S,"ETN"               ;[1200] GET     - wait for keypress (numeric)
    DB    'I'+S,"NK"                ;[1204] INK     - current ink colour
    DB    'P'+S,"APER"              ;[1207] PAPER   - current paper colour
    DB    'P'+S,"OS"                ;[120C] POS     - cursor X position
    DB    'V'+S,"POS"               ;[120F] VPOS    - cursor Y position
    DB    'T'+S,"RUE"               ;[1213] TRUE    - boolean true (1)
    DB    'F'+S,"ALSE"              ;[1217] FALSE   - boolean false (0)
    DB    'I'+S,"NF"                ;[121C] INF     - infinity
    DB    'B'+S,"LACK"              ;[121F] BLACK   - colour constant
    DB    'B'+S,"LUE"               ;[1224] BLUE    - colour constant
    DB    'R'+S,"ED"                ;[1228] RED     - colour constant
    DB    'M'+S,"AGENTA"            ;[122B] MAGENTA - colour constant
    DB    'G'+S,"REEN"              ;[1232] GREEN   - colour constant
    DB    'C'+S,"YAN"               ;[1237] CYAN    - colour constant
    DB    'Y'+S,"ELLOW"             ;[123B] YELLOW  - colour constant
    DB    'W'+S,"HITE"              ;[1241] WHITE   - colour constant
    DB    'A'+S,"LPHA"              ;[1246] ALPHA   - address of char table
    DB    'G'+S,"RAPHIC"            ;[124B] GRAPHIC - address of graphic table
    DB    'S'+S,"IN"                ;[1252] SIN     - sine
    DB    'C'+S,"OS"                ;[1255] COS     - cosine
    DB    'T'+S,"AN"                ;[1258] TAN     - tangent
    DB    'E'+S,"XP"                ;[125B] EXP     - e^x
    DB    'L'+S,"OG"                ;[125E] LOG     - log base 10
    DB    'A'+S,"NTILOG"            ;[1261] ANTILOG - 10^x
    DB    'L'+S,"N"                 ;[1268] LN      - natural log
    DB    'S'+S,"GN"                ;[126A] SGN     - sign (-1/0/+1)
    DB    'A'+S,"BS"                ;[126D] ABS     - absolute value
    DB    'I'+S,"NT"                ;[1270] INT     - integer part (floor)
    DB    'F'+S,"RAC"               ;[1273] FRAC    - fractional part
    DB    'S'+S,"QR"                ;[1277] SQR     - square root
    DB    'P'+S,"EEK"               ;[127A] PEEK    - read byte from memory
    DB    'D'+S,"PEEK"              ;[127E] DPEEK   - read 16-bit word from memory
    DB    'I'+S,"NP"                ;[1283] INP     - read I/O port
    DB    'F'+S,"ACT"               ;[1286] FACTORIAL - n!
    DB    'A'+S,"RCTAN"             ;[128A] ATN     - arctangent
    DB    'A'+S,"RCCOS"             ;[1290] ARCCOS  - arccosine
    DB    'A'+S,"RCSIN"             ;[1296] ARCSIN  - arcsine
    DB    'L'+S,"CTN"               ;[129C] LOCATION - peek at address (alias?)
    DB    'B'+S,"IN"                ;[12A0] BIN     - binary to integer
    DB    'D'+S,"EG"                ;[12A3] DEG     - radians to degrees
    DB    'R'+S,"AD"                ;[12A6] RAD     - degrees to radians
    DB    'R'+S,"AND"               ;[12A9] RAND    - random integer 0..n-1
    DB    'L'+S,"IGHTPEN"           ;[12AD] LIGHTPEN - lightpen X position
    DB    'J'+S,"OYSTK"             ;[12B5] JOYSTICK - joystick input
    DB    'U'+S,"SER0"              ;[12BB] USER0   - user-defined function 0
    DB    'U'+S,"SER1"              ;[12C0] USER1   - user-defined function 1
    DB    'U'+S,"SER2"              ;[12C5] USER2   - user-defined function 2
    DB    'U'+S,"SER3"              ;[12CA] USER3   - user-defined function 3
    DB    'L'+S,"ETTER"             ;[12CF] LETTER  - address of char bitmap
    DB    S,S,S,S,S                 ;[12D5] (5 unused entries)
    DB    '('+S                     ;[12DA] (       - open parenthesis
    DB    'N'+S,"OT"                ;[12DB] NOT     - logical/bitwise NOT
    DB    '-'+S                     ;[12DE] -       - unary negation
    DB    S                         ;[12DF] FN0     - user function 0
    DB    S                         ;[12E0] FN1     - user function 1
    DB    S                         ;[12E1] ARRAY   - array index
    DB    '*'+S,"*"                 ;[12E2] **      - power/exponentiation
    DB    '*'+S                     ;[12E4] *       - multiply
    DB    '/'+S                     ;[12E5] /       - divide
    DB    '+'+S                     ;[12E6] +       - add
    DB    '-'+S                     ;[12E7] -       - subtract
    DB    '>'+S,"="                 ;[12E8] >=      - greater than or equal
    DB    '<'+S,"="                 ;[12EA] <=      - less than or equal
    DB    '<'+S,">"                 ;[12EC] <>      - not equal
    DB    '>'+S                     ;[12EE] >       - greater than
    DB    '<'+S                     ;[12EF] <       - less than
    DB    '='+S                     ;[12F0] =       - equal
    DB    'O'+S,"R"                 ;[12F1] OR      - logical OR
    DB    'A'+S,"ND"                ;[12F3] AND     - logical AND
    DB    'B'+S,"NOR"               ;[12F6] BNOR    - bitwise OR
    DB    'B'+S,"NXOR"              ;[12FA] BNXOR   - bitwise XOR
    DB    'B'+S,"NAND"              ;[12FF] BNAND   - bitwise AND
    DB    'D'+S,"IV"                ;[1304] DIV     - integer division
    DB    'M'+S,"OD"                ;[1307] MOD     - modulus
    DB    'T'+S,"HEN"               ;[130A] THEN    - IF...THEN
    DB    'L'+S,"ABEL"              ;[130E] LABEL   - branch target label
    DB    '@'+S                     ;[1313] @       - AT (cursor positioning)
    DB    'O'+S,"N"                 ;[1314] ON      - ON...GOTO/GOSUB
    DB    'O'+S,"FF"                ;[1316] OFF     - (used with ON)
    DB    'S'+S,"TEP"               ;[1319] STEP    - FOR...STEP
    DB    'T'+S,"O"                 ;[131D] TO      - FOR...TO
    DB    'T'+S,"AB"                ;[131F] TAB     - TAB(n) in PRINT
    DB    'C'+S,"HR$("              ;[1322] CHR$(   - character from ASCII code
    DB    'L'+S,"EFT$("             ;[1327] LEFT$(  - left substring
    DB    'R'+S,"IGHT$("            ;[132D] RIGHT$( - right substring
    DB    'M'+S,"ID$("              ;[1334] MID$(   - mid substring
    DB    'U'+S,"PC$("              ;[1339] UPC$(   - uppercase string
    DB    'K'+S,"EY$"               ;[133E] INKEY$  - keyboard scan (string)
    DB    'G'+S,"ET$"               ;[1342] GET$    - wait for keypress (string)
    DB    'S'+S,"TR$("              ;[1346] STR$(   - number to string
    DB    S                         ;[134B] (1 unused entry)
    DB    S,S,S,S,S,S,S,S,S,S,S,S,S,S,S;[134C] (15 unused entries)
    DB    S,S,S,S,S,S,S,S,S,S,S,S,S ;[135B] (13 unused entries - padding to align table)

;
; Function evaluation jump table (DATA_FTBS).
; Each entry is a 2-byte address of the routine that implements the
; corresponding function token from DATA_TTBS (same order).
; The BASIC evaluator looks up the token index in this table and calls
; the routine.  Entries pointing to ERR_NOT_YET_IMP are reserved slots
; for future functions.
;
DATA_FTBS:
    DW    FMEM                      ;[1368] MEM
    DW    FPI                       ;[136A] PI
    DW    FKEYN                     ;[136C] INKEY
    DW    FRND                      ;[136E] RND
    DW    FHL                       ;[1370] HL
    DW    FLEN                      ;[1372] LEN
    DW    FVAL                      ;[1374] VAL
    DW    FASC                      ;[1376] ASC
    DW    FHIMEM                    ;[1378] HIMEM
    DW    FGETN                     ;[137A] GET
    DW    FINK                      ;[137C] INK
    DW    FPAPER                    ;[137E] PAPER
    DW    FPOS                      ;[1380] POS
    DW    FVPOS                     ;[1382] VPOS
    DW    LONE                      ;[1384] TRUE  (loads constant 1)
    DW    LZERO                     ;[1386] FALSE (loads constant 0)
    DW    FINF                      ;[1388] INF
    DW    FN_BLACK                  ;[138A] BLACK
    DW    FN_BLUE                   ;[138C] BLUE
    DW    FN_RED                    ;[138E] RED
    DW    FN_MAGENTA                ;[1390] MAGENTA
    DW    FN_GREEN                  ;[1392] GREEN
    DW    FN_CYAN                   ;[1394] CYAN
    DW    FN_YELLOW                 ;[1396] YELLOW
    DW    FN_WHITE                  ;[1398] WHITE
    DW    FALPHA                    ;[139A] ALPHA
    DW    FGRAPHIC                  ;[139C] GRAPHIC
    DW    FSIN                      ;[139E] SIN
    DW    FCOS                      ;[13A0] COS
    DW    FTAN                      ;[13A2] TAN
    DW    FEXP                      ;[13A4] EXP
    DW    FLOG                      ;[13A6] LOG
    DW    FANTILOG                  ;[13A8] ANTILOG
    DW    FLN                       ;[13AA] LN
    DW    FSGN                      ;[13AC] SGN
    DW    FABSLTE                   ;[13AE] ABS
    DW    FINT                      ;[13B0] INT
    DW    FFRAC                     ;[13B2] FRAC
    DW    FSQR                      ;[13B4] SQR
    DW    FPEEK                     ;[13B6] PEEK
    DW    FDPEEK                    ;[13B8] DPEEK
    DW    FINP                      ;[13BA] INP
    DW    FFACT                     ;[13BC] FACTORIAL
    DW    FARCTAN                   ;[13BE] ATN
    DW    FARCCOS                   ;[13C0] ARCCOS
    DW    FARCSIN                   ;[13C2] ARCSIN
    DW    FLCTN                     ;[13C4] LOCATION
    DW    FBIN                      ;[13C6] BIN
    DW    FDEG                      ;[13C8] DEG
    DW    FRAD                      ;[13CA] RAD
    DW    FRAND                     ;[13CC] RAND
    DW    SYSVAR_FLIGHT             ;[13CE] LIGHTPEN (hook - default: ERR_NOT_YET_IMP)
    DW    SYSVAR_FJOY               ;[13D0] JOYSTICK (hook - default: ERR_NOT_YET_IMP)
    DW    SYSVAR_FUSER0             ;[13D2] USER0    (hook - user-definable)
    DW    SYSVAR_FUSER1             ;[13D4] USER1    (hook - user-definable)
    DW    SYSVAR_FUSER2             ;[13D6] USER2    (hook - user-definable)
    DW    SYSVAR_FUSER3             ;[13D8] USER3    (hook - user-definable)
    DW    FLETTER                   ;[13DA] LETTER
    DW    ERR_NOT_YET_IMP           ;[13DC] (reserved)
    DW    ERR_NOT_YET_IMP           ;[13DE] (reserved)
    DW    ERR_NOT_YET_IMP           ;[13E0] (reserved)
    DW    ERR_NOT_YET_IMP           ;[13E2] (reserved)
    DW    ERR_NOT_YET_IMP           ;[13E4] (reserved)
    DW    0                         ;[13E6] ( (parentheses - handled inline, not via table)
    DW    FNOT                      ;[13E8] NOT
    DW    FMINUS                    ;[13EA] - (unary negation)
    DW    FFN0                      ;[13EC] FN0 (user function call)
    DW    FFN1                      ;[13EE] FN1 (user function call)
    DW    FARR                      ;[13F0] ARRAY (array element access)
    DW    FPOWER                    ;[13F2] ** (exponentiation)
    DW    _MULT                     ;[13F4] *  (multiplication)
    DW    DIV                       ;[13F6] /  (division)
    DW    ADD                       ;[13F8] +  (addition)
    DW    SUB                       ;[13FA] -  (subtraction)
    DW    FGT_EQUAL                 ;[13FC] >= (greater-or-equal)
    DW    FLT_EQUAL                 ;[13FE] <= (less-or-equal)
    DW    FNOT_EQUAL                ;[1400] <> (not equal)
    DW    FGREATERTHAN              ;[1402] >  (greater than)
    DW    FLESSTHAN                 ;[1404] <  (less than)
    DW    FEQUAL                    ;[1406] =  (equal)
    DW    FNOR                      ;[1408] OR  (logical OR)
    DW    FAND                      ;[140A] AND (logical AND)
    DW    FBNOR                     ;[140C] BNOR  (bitwise OR)
    DW    FBNXOR                    ;[140E] BNXOR (bitwise XOR)
    DW    FBNAND                    ;[1410] BNAND (bitwise AND)
    DW    FDIV                      ;[1412] DIV (integer division)
    DW    FMOD                      ;[1414] MOD (modulus)

;
; Command token table (XTTBLS).
; Defines the text of each Lynx BASIC command keyword.
; Each entry has the final character with bit 7 set (marked '+S' in source)
; to signal end-of-token.  The tokeniser scans this table sequentially.
; The table is referenced by SYSVAR_XTTBL (initialised in DATA_RAMC).
; Note: the first byte ($00 = BREAK) has no text; it acts as a sentinel.
;
XTTBLS:
    DB    BREAK                     ;[1416] (sentinel / BREAK token)
    DB    'L'+S,"ET"                ;[1417] LET
    DB    'V'+S,"DU"                ;[141A] VDU
    DB    'D'+S,"EFPROC"            ;[141D] DEFPROC
    DB    'P'+S,"ROC"               ;[1424] PROC
    DB    'E'+S,"NDPROC"            ;[1428] ENDPROC
    DB    'N'+S,"EXT"               ;[142F] NEXT
    DB    'I'+S,"NK"                ;[1433] INK
    DB    'P'+S,"APER"              ;[1436] PAPER
    DB    'R'+S,"ANDOM"             ;[143B] RANDOM
    DB    'V'+S,"ERIFY"             ;[1441] VERIFY
    DB    'D'+S,"POKE"              ;[1447] DPOKE
    DB    'D'+S,"OT"                ;[144C] DOT    (same as PLOT mode 4)
    DB    'P'+S,"OKE"               ;[144F] POKE
    DB    'E'+S,"ND"                ;[1453] END
    DB    'S'+S,"TOP"               ;[1456] STOP
    DB    'F'+S,"OR"                ;[145A] FOR
    DB    'G'+S,"OTO"               ;[145D] GOTO
    DB    'G'+S,"OSUB"              ;[1461] GOSUB
    DB    'R'+S,"ETURN"             ;[1466] RETURN
    DB    'C'+S,"LS"                ;[146C] CLS
    DB    'R'+S,"UN"                ;[146F] RUN
    DB    'C'+S,"ONT"               ;[1472] CONT
    DB    'O'+S,"UT"                ;[1476] OUT
    DB    'R'+S,"EM"                ;[1479] REM
    DB    'R'+S,"EAD"               ;[147C] READ
    DB    'D'+S,"ATA"               ;[1480] DATA
    DB    'N'+S,"EW"                ;[1484] NEW
    DB    'D'+S,"EL"                ;[1487] DELETE
    DB    'A'+S,"UTO"               ;[148A] AUTO
    DB    'P'+S,"RINT"              ;[148E] PRINT
    DB    'L'+S,"OAD"               ;[1493] LOAD
    DB    'S'+S,"AVE"               ;[1497] SAVE
    DB    'R'+S,"ESTORE"            ;[149B] RESTORE
    DB    'P'+S,"LOT"               ;[14A2] PLOT
    DB    'M'+S,"OVE"               ;[14A6] MOVE
    DB    'D'+S,"RAW"               ;[14AA] DRAW
    DB    'C'+S,"ALL"               ;[14AE] CALL
    DB    'I'+S,"NPUT"              ;[14B2] INPUT
    DB    'D'+S,"IM"                ;[14B7] DIM
    DB    'I'+S,"F"                 ;[14BA] IF
    DB    'L'+S,"IST"               ;[14BC] LIST
    DB    'W'+S,"INDOW"             ;[14C0] WINDOW
    DB    'P'+S,"AUSE"              ;[14C6] PAUSE
    DB    'R'+S,"OUND"              ;[14CB] ROUND
    DB    'T'+S,"RAIL"              ;[14D0] TRAIL
    DB    'L'+S,"PRINT"             ;[14D5] LPRINT
    DB    'L'+S,"LIST"              ;[14DB] LLIST
    DB    'L'+S,"ABEL"              ;[14E0] LABEL
    DB    'B'+S,"EEP"               ;[14E5] BEEP
    DB    'S'+S,"OUND"              ;[14E9] SOUND
    DB    'A'+S,"PPEND"             ;[14EE] APPEND
    DB    'C'+S,"ODE"               ;[14F4] CODE  (inline hex data in listing)
    DB    'L'+S,"INK"               ;[14F8] LINK
    DB    'S'+S,"WAP"               ;[14FC] SWAP
    DB    'W'+S,"HILE"              ;[1500] WHILE
    DB    'W'+S,"END"               ;[1505] WEND
    DB    'R'+S,"EPEAT"             ;[1509] REPEAT
    DB    'U'+S,"NTIL"              ;[150F] UNTIL
    DB    '@'+S,"@@@@"              ;[1514] (reserved / unused)
    DB    '?'+S                     ;[1519] ?  (shorthand for PRINT)
    DB    'E'+S,"LSE"               ;[151A] ELSE
    DB    'R'+S,"ESERVE"            ;[151E] RESERVE
    DB    'M'+S,"ON"                ;[1525] MONITOR
    DB    'R'+S,"ENUM"              ;[1528] RENUM
    DB    'X'+S,"ROM"               ;[152D] XROM  (execute external ROM command)
    DB    'E'+S,"XT"                ;[1531] EXT   (extensible hook for add-ons)
    DB    'C'+S,"FR"                ;[1534] CFR   (cursor flash rate)
    DB    'C'+S,"CHAR"              ;[1537] CCHAR (cursor character)
    DB    'T'+S,"RACE"              ;[153C] TRACE
    DB    'S'+S,"PEED"              ;[1541] SPEED
    DB    'P'+S,"ROTECT"            ;[1546] PROTECT
    DB    'E'+S,"RROR"              ;[154D] ERROR
    DB    'T'+S,"APE"               ;[1552] TAPE
    DB    'M'+S,"LOAD"              ;[1556] MLOAD (machine code load)
    DB    'T'+S,"EXT"               ;[155B] TEXT
    DB    S                         ;[155F] (end-of-table sentinel)

;
; Input syntax validation table (XITBLS).
; Each entry is a 2-byte address of the routine that validates the syntax of
; the corresponding command token from XTTBLS (same order, starting at LET).
; Called during tokenisation to check and encode the arguments of each command.
;
XITBLS:
    DW    ILET                      ;[1560] LET
    DW    IVDU                      ;[1562] VDU
    DW    IDEFPROC                  ;[1564] DEFPROC
    DW    IPROC                     ;[1566] PROC
    DW    IEND                      ;[1568] ENDPROC
    DW    INEXT                     ;[156A] NEXT
    DW    IINK                      ;[156C] INK
    DW    IINK                      ;[156E] PAPER    (same validator as INK)
    DW    IEND                      ;[1570] RANDOM
    DW    ILOAD                     ;[1572] VERIFY
    DW    IDPOKE                    ;[1574] DPOKE
    DW    IDPOKE                    ;[1576] DOT      (same validator as DPOKE: x,y)
    DW    IDPOKE                    ;[1578] POKE     (same validator: addr,val)
    DW    IEND                      ;[157A] END
    DW    IEND                      ;[157C] STOP
    DW    IFOR                      ;[157E] FOR
    DW    IGOTO                     ;[1580] GOTO
    DW    IGOTO                     ;[1582] GOSUB    (same validator as GOTO)
    DW    IEND                      ;[1584] RETURN
    DW    IEND                      ;[1586] CLS
    DW    IRESTORE                  ;[1588] RUN
    DW    IEND                      ;[158A] CONT
    DW    IDPOKE                    ;[158C] OUT      (same validator: port,val)
    DW    IREM                      ;[158E] REM
    DW    IRD                       ;[1590] READ
    DW    IREM                      ;[1592] DATA     (same validator as REM: raw text)
    DW    IEND                      ;[1594] NEW
    DW    ICALL                     ;[1596] DELETE
    DW    ILIST                     ;[1598] AUTO
    DW    IPRINT1                   ;[159A] PRINT
    DW    ILOAD                     ;[159C] LOAD
    DW    ISAVE                     ;[159E] SAVE
    DW    IRESTORE                  ;[15A0] RESTORE
    DW    ICCCR                     ;[15A2] PLOT     (3 args: mode,x,y)
    DW    IDPOKE                    ;[15A4] MOVE     (same validator: x,y)
    DW    IDPOKE                    ;[15A6] DRAW     (same validator: x,y)
    DW    ICALL                     ;[15A8] CALL
    DW    IINPUT                    ;[15AA] INPUT
    DW    IDIM                      ;[15AC] DIM
    DW    IIF                       ;[15AE] IF
    DW    ILIST                     ;[15B0] LIST
    DW    IE4CR                     ;[15B2] WINDOW   (4 args: left,right,top,bottom)
    DW    IINK                      ;[15B4] PAUSE    (single expression)
    DW    IROUND                    ;[15B6] ROUND
    DW    IROUND                    ;[15B8] TRAIL
    DW    IPRINT1                   ;[15BA] LPRINT
    DW    ILIST                     ;[15BC] LLIST
    DW    IREM                      ;[15BE] LABEL    (raw text label)
    DW    ICCCR                     ;[15C0] BEEP     (3 args: pitch,dur,wave)
    DW    IDPOKE                    ;[15C2] SOUND    (same validator: addr,dur)
    DW    ILOAD                     ;[15C4] APPEND
    DW    ICODE                     ;[15C6] CODE     (hex data)
    DW    IROUND                    ;[15C8] LINK
    DW    ISWAP                     ;[15CA] SWAP
    DW    IINK                      ;[15CC] WHILE    (single expression)
    DW    IEND                      ;[15CE] WEND
    DW    IEND                      ;[15D0] REPEAT
    DW    IINK                      ;[15D2] UNTIL    (single expression)
    DW    ICCCR                     ;[15D4] (reserved)
    DW    IPRINT                    ;[15D6] ?        (shorthand PRINT)
    DW    IL1                       ;[15D8] ELSE
    DW    IINK                      ;[15DA] RESERVE
    DW    IEND                      ;[15DC] MONITOR
    DW    ILIST                     ;[15DE] RENUM
    DW    IEND                      ;[15E0] XROM
    DW    SYSVAR_IEXT               ;[15E2] EXT      (hook - syntax checker for extensions)
    DW    IINK                      ;[15E4] CFR
    DW    IINK                      ;[15E6] CCHAR
    DW    IROUND                    ;[15E8] TRACE
    DW    IINK                      ;[15EA] SPEED
    DW    IINK                      ;[15EC] PROTECT
    DW    IINK                      ;[15EE] ERROR
    DW    IINK                      ;[15F0] TAPE
    DW    ILOAD                     ;[15F2] MLOAD
    DW    IEND                      ;[15F4] TEXT

;
; Command execution table (XETBLS).
; Each entry is a 2-byte address of the routine that executes the corresponding
; command token (same order as XTTBLS / XITBLS, starting at LET).
; Called by the BASIC interpreter after tokenisation to run each statement.
;
XETBLS:
    DW    ELET                      ;[15F6] LET
    DW    EVDU                      ;[15F8] VDU
    DW    ERR_WRONG_MODE            ;[15FA] DEFPROC  (only valid in program mode)
    DW    EPROC                     ;[15FC] PROC
    DW    EENDPROC                  ;[15FE] ENDPROC
    DW    ENEXT                     ;[1600] NEXT
    DW    EINK                      ;[1602] INK
    DW    EPAPER                    ;[1604] PAPER
    DW    ERANDOM                   ;[1606] RANDOM
    DW    EVERIFY                   ;[1608] VERIFY
    DW    EDPOKE                    ;[160A] DPOKE
    DW    EDOT                      ;[160C] DOT      (plot single pixel)
    DW    EPOKE                     ;[160E] POKE
    DW    EEND                      ;[1610] END
    DW    ESTOP                     ;[1612] STOP
    DW    EFOR                      ;[1614] FOR
    DW    EGOTO                     ;[1616] GOTO
    DW    EGOSUB                    ;[1618] GOSUB
    DW    ERETURN                   ;[161A] RETURN
    DW    ECLS                      ;[161C] CLS
    DW    ERUN                      ;[161E] RUN
    DW    ECONT                     ;[1620] CONT
    DW    EOUT                      ;[1622] OUT
    DW    ENO_EXE                   ;[1624] REM      (no execution)
    DW    EREAD                     ;[1626] READ
    DW    ENO_EXE                   ;[1628] DATA     (no execution; data consumed by READ)
    DW    ENEW                      ;[162A] NEW
    DW    EDEL                      ;[162C] DELETE
    DW    EAUTO                     ;[162E] AUTO
    DW    EPRINT                    ;[1630] PRINT
    DW    ELOAD                     ;[1632] LOAD
    DW    ESAVE                     ;[1634] SAVE
    DW    ERESTORE                  ;[1636] RESTORE
    DW    EPLOT                     ;[1638] PLOT
    DW    EMOVE                     ;[163A] MOVE
    DW    EDRAW                     ;[163C] DRAW
    DW    ECALL                     ;[163E] CALL
    DW    EINPUT                    ;[1640] INPUT
    DW    EDIM                      ;[1642] DIM
    DW    EIF                       ;[1644] IF
    DW    ELIST                     ;[1646] LIST
    DW    EWINDOW                   ;[1648] WINDOW
    DW    EPAUSE                    ;[164A] PAUSE
    DW    EROUND                    ;[164C] ROUND
    DW    ETRAIL                    ;[164E] TRAIL
    DW    ELPRINT                   ;[1650] LPRINT
    DW    ELLIST                    ;[1652] LLIST
    DW    ENO_EXE                   ;[1654] LABEL    (no execution; label consumed by GOTO etc)
    DW    EBEEP                     ;[1656] BEEP
    DW    ESOUND                    ;[1658] SOUND
    DW    EAPPEND                   ;[165A] APPEND
    DW    ENO_EXE                   ;[165C] CODE     (no execution; data only)
    DW    ELINK                     ;[165E] LINK
    DW    ESWAP                     ;[1660] SWAP
    DW    EWHILE                    ;[1662] WHILE
    DW    EWEND                     ;[1664] WEND
    DW    EREPEAT                   ;[1666] REPEAT
    DW    EUNTIL                    ;[1668] UNTIL
    DW    ERR_NOT_YET_IMP           ;[166A] (reserved FTEXT - not implemented)
    DW    ERR_NOT_YET_IMP           ;[166C] ?        (reserved)
    DW    ENO_EXE                   ;[166E] ELSE     (handled by IF, no direct execution)
    DW    ERESERVE                  ;[1670] RESERVE
    DW    EMON                      ;[1672] MONITOR
    DW    ERENUM                    ;[1674] RENUM
    DW    XROM                      ;[1676] XROM
    DW    SYSVAR_EEXT               ;[1678] EXT      (hook - execution for extensions)
    DW    ECFR                      ;[167A] CFR
    DW    ECCHAR                    ;[167C] CCHAR
    DW    ETRACE                    ;[167E] TRACE
    DW    ESPEED                    ;[1680] SPEED
    DW    EPROTECT                  ;[1682] PROTECT
    DW    EERROR                    ;[1684] ERROR
    DW    ETAPE                     ;[1686] TAPE
    DW    EMLOAD                    ;[1688] MLOAD
    DW    ETEXT                     ;[168A] TEXT

;
; System initialisation (called after CRT/video hardware is set up).
; Copies the RAM initialisation block (DATA_RAMC, $D3 = 211 bytes) into the
; system variable area starting at SYSVAR_STACK, sets up the initial BASIC
; program (a single $80 end-marker after a CR), then jumps to SUB_TEST_4896K
; to detect RAM size and set the stack pointer.
;
INIT:
    DI                              ;[168C] Disable interrupts during initialisation
    LD    HL,DATA_RAMC              ;[168D] HL -> RAM initialisation data block
    LD    DE,SYSVAR_STACK           ;[1690] DE -> destination in system variable area
    LD    BC,$00D3                  ;[1693] BC = 211 bytes to copy
    LDIR                            ;[1696] Copy initialisation data into RAM
    LD    HL,(SYSVAR_SOB)           ;[1698] HL -> start of BASIC area
    LD    (HL),$80                  ;[169B] Write end-of-BASIC marker ($80)
    DEC   HL                        ;[169D] Step back one byte
    LD    (HL),$0D                  ;[169E] Write CR before marker (empty program)
    JP    SUB_TEST_4896K            ;[16A0] Detect RAM size and set SP, then jump to START

;
; Boot entry point: checks for an external ROM, displays the Lynx logo,
; then enters the main command-line loop.
; If the byte at $4000 (EXT_ROM) is $00 (not $FF = absent), an external ROM
; is present and is called to perform its own initialisation/boot sequence.
; The intro display includes two BEEPs and a graphics logo (VDU sequences).
;
START:
    LD    A,(EXT_ROM)               ;[16A3] Read first byte of external ROM area
    OR    A                         ;[16A6] Is it zero? (zero = external ROM present)
    CALL  Z,EXT_ROM                 ;[16A7] Yes: call external ROM boot routine
    CALL  ZERO_MEM                  ;[16AA] Initialise variable/string/array areas
    LD    HL,INPBUF                 ;[16AD] HL -> input buffer
    LD    (HL),$0D                  ;[16B0] Write CR to empty the input buffer
    ADD   HL,SP                     ;[16B2] Add SP to detect RAM overlap (96K test)
    LD    HL,INTRO                  ;[16B3] HL -> intro display sequence
    JR    NC,LOGO_OUTPUT            ;[16B6] No carry: safe to show full logo with beeps
    LD    HL,DATA_2BEEPS+$02        ;[16B8] Carry: 96K overlap - skip first beep, start mid-sequence
    NOP                             ;[16BB] (timing/alignment NOP)
LOGO_OUTPUT:
    CALL  PLINE                     ;[16BC] Output the intro/logo sequence
MAIN_LOOP:
    CALL  MAIN1                     ;[16BF] Run one command-line interaction
    JR    MAIN_LOOP                 ;[16C2] Loop forever

;
; Main command-line handler: displays the prompt, handles AUTO line numbering,
; reads a line of user input, and processes it.
;
MAIN1:
    LD    HL,PROMPT                 ;[16C4] HL -> PROMPT string (VDU 20, VDU 19, '>', NUL)
    CALL  PLINE                     ;[16C7] Display the prompt
    LD    A,(SYSVAR_AUTOFL)         ;[16CA] Is AUTO mode active?
    OR    A                         ;[16CD] 
    JR    Z,USER_INPUT              ;[16CE] No: just get input
    LD    HL,SYSVAR_AUTOST          ;[16D0] Yes: HL -> current auto line number
    CALL  LNUM1                     ;[16D3] Load auto line number into WRA1
    CALL  FNDLN_WRA1                ;[16D6] Does that line number already exist?
    LD    A,' '                     ;[16D9] Assume it doesn't: prepare space character
    JR    NZ,MAIN6                  ;[16DB] Line not found: print space after number
    LD    A,'!'                     ;[16DD] Line already exists: print '!' warning
MAIN6:
    PUSH  AF                        ;[16DF] Save space or '!' indicator
    CALL  PN                        ;[16E0] Print the auto line number
    POP   AF                        ;[16E3] 
    RST   $08                       ;[16E4] Print space or '!' after the number
USER_INPUT:
    CALL  SYSVAR_LINP               ;[16E5] Get a line of input from keyboard
    JR    NZ,DO_AUTONUM             ;[16E8] Non-zero result: line was entered, process it
    LD    HL,SYSVAR_AUTOFL          ;[16EA] Zero result: empty line entered
    LD    (HL),$00                  ;[16ED] Turn AUTO mode off
    RET                             ;[16EF] Return to MAIN_LOOP

;
; Processes a line of user input (called from USER_INPUT when a line is entered).
; Saves the stack pointer, analyses the input line (tokenises/stores it in BASIC
; memory), and if AUTO mode is still active, increments the auto line number by
; the step value stored in SYSVAR_AUTOST+5.
;
DO_AUTONUM:
    LD    (SYSVAR_STACK),SP         ;[16F0] Save current SP in SYSVAR_STACK (for CONT/error recovery)
    LD    DE,INPBUF                 ;[16F4] DE -> input buffer containing the entered line
    CALL  LINP_ANLYS                ;[16F7] Analyse/tokenise the input line and store in BASIC
    LD    A,(SYSVAR_AUTOFL)         ;[16FA] Is AUTO mode still active?
    OR    A                         ;[16FD] 
    JR    Z,MAIN1                   ;[16FE] No: return to prompt immediately
    LD    HL,SYSVAR_AUTOST          ;[1700] HL -> auto line number in WRA1 format
    CALL  LNUM1                     ;[1703] Load current auto number into WRA1
    LD    HL,$62F8                  ;[1706] HL -> auto step value (stored in SYSVAR area)
    CALL  LNUM2                     ;[1709] Load auto step into WRA2
    CALL  ADD                       ;[170C] WRA1 = auto number + step
    LD    DE,SYSVAR_AUTOST          ;[170F] DE -> auto line number store
    JP    WRA1_TO_DE                ;[1712] Store new auto number and return

;
; RAM initialisation data block (DATA_RAMC).
; Copied verbatim into system variable RAM starting at SYSVAR_STACK during INIT.
; This sets up all the default values for the BASIC interpreter's working variables.
; Total size: $D3 (211) bytes.
;
DATA_RAMC:
    DW    $FF00                     ;[1715] SYSVAR_STACK: initial stack high byte $FF, low $00
    DB    1,0,0,0                   ;[1717] Random number seed (WRA1 format, mantissa $1,0,0,0)
    DW    0                         ;[171B] HL store (working register, initialised to 0)
    DW    FLOAT_ZERO                ;[171D] Current line pointer -> floating-point zero
    DW    SYSVAR_SOBS-1             ;[171F] Start of BASIC - 1 (pre-decremented pointer)
    DW    SYSVAR_SOBS               ;[1721] SOB: start of BASIC program ($694D)
    DW    SYSVAR_SOBS               ;[1723] EOB: end of BASIC (initially same as SOB = empty)
    DW    SYSVAR_POLBUFS            ;[1725] Polish (RPN) buffer start address
    DW    SCREEN                    ;[1727] SYSVAR_PRINTD: display driver (SCREEN routine)
    DW    ENO_EXE                   ;[1729] Printer driver (default: no-op)
    DW    KEYB                      ;[172B] SYSVAR_KEYB: keyboard driver (KEYB routine)
    DB    1                         ;[172D] Output type: 1 = display, 2 = printer
    DB    0                         ;[172E] Last character output
    DB    1                         ;[172F] Current variable type (1 = numeric)
    DB    0                         ;[1730] Continue line pointer low byte
    DB    0                         ;[1731] Continue line pointer high byte
    DW    SYSVAR_RSTACKS            ;[1732] Return stack base address
    DW    SYSVAR_RSTACKS            ;[1734] Return stack pointer (initially at base = empty)
    DW    SYSVAR_VTBLS              ;[1736] Variable table start
    DW    SYSVAR_ATBLS              ;[1738] Array table start
    DW    SYSVAR_STBLS              ;[173A] String table start
    DW    DATA_FTBS                 ;[173C] Function evaluation table
    DW    DATA_TTBS                 ;[173E] Non-command token text table
    DW    XTTBLS                    ;[1740] Command token text table
    DW    XITBLS                    ;[1742] Command syntax validation table
    DW    XETBLS                    ;[1744] Command execution table
    DW    SYSVAR_SOBS+1             ;[1746] Top of variables area (just above BASIC start)
    JP    IREM                      ;[1748] SYSVAR_LINP default: line-input using IREM-style handler
    JP    ERR_NOT_YET_IMP           ;[174B] SYSVAR_IEXT default: EXT syntax = not implemented
    DB    $C9                       ;[174E] SYSVAR_EEXT[0]: $C9 = RET opcode (EXT exec = no-op)
    DW    0                         ;[174F] SYSVAR_EEXT[1-2]
    DB    $C9                       ;[1751] Hook before execute line: $C9 = RET (no-op)
    DW    0                         ;[1752] Zero flag: rounding on, ROUND mode
    DB    1                         ;[1754] SYSVAR_AUTOFL: AUTO off (1 = off, set later to 0)
    DB    0                         ;[1755] Carriage-return message flag
    DW    CRMSG                     ;[1756] SYSVAR_KSMS: single-key shorthand pointer (-> CRMSG)
    DB    0                         ;[1758] SYSVAR_RPTDLY low: keyboard repeat delay
    DB    0                         ;[1759] SYSVAR_LASTK: last key pressed
    DB    0                         ;[175A] SYSVAR_STATUS: keyboard activity flag
    DW    8                         ;[175B] SYSVAR_RPT: repeat counter (8 = initial value)
    DB    0,0,0,0                   ;[175D] SYSVAR_SHLKT + 3 bytes: shift-lock off, padding
    ; ESC shorthand assignment table (26 entries, one per letter A-Z).
    ; Each byte is the token number of the BASIC command assigned to that letter.
    DB    AUTO,BEEP,CONT,DELETE     ;[1761] A=AUTO, B=BEEP, C=CONT, D=DELETE
    DB    DATA,DEFPRC,GOTO,GOSUB    ;[1765] E=DATA, F=DEFPROC, G=GOTO, H=GOSUB
    DB    INPUT,LABEL,MONITR,LIST   ;[1769] I=INPUT, J=LABEL, K=MONITOR, L=LIST
    DB    RETURN,NEXT,ENDPRC,PROC   ;[176D] M=RETURN, N=NEXT, O=ENDPROC, P=PROC
    DB    REM,REPEAT,STOP,TRACE     ;[1771] Q=REM, R=REPEAT, S=STOP, T=TRACE
    DB    UNTIL,VERIFY,WHILE,WEND   ;[1775] U=UNTIL, V=VERIFY, W=WHILE, X=WEND
    DB    RUN,RESTOR                ;[1779] Y=RUN, Z=RESTORE

;
; Video/display initialisation data (VROM).
; Copied into the video system variable area on a video reset (VRESET).
; Establishes default cursor position, window bounds, colours, flash rate,
; cursor character, graphics state, colour plane bank addresses, and the
; default hooks for GLINE, OUTB, VIDEO, LINP etc.
;
VROM:
    DB    3                         ;[177B] SYSVAR_CURSORX: initial cursor X = 3 (left margin)
    DB    5                         ;[177C] SYSVAR_CURSORY: initial cursor Y = 5 (top margin)
DFTW:
    DB    KWNDLF,KWNDRT,5,245       ;[177D] SYSVAR_WINDST: window left=3, right=123, top=5, bottom=245
    DB    0                         ;[1781] SYSVAR_CURSTAT: cursor off initially
    DB    7                         ;[1782] SYSVAR_INKST: ink = 7 (white)
    DB    0                         ;[1783] SYSVAR_PAPST: paper = 0 (black)
    DW    KFLASH                    ;[1784] SYSVAR_FLASH: cursor flash period ($200 = ~512 ticks)
    DB    ' '                       ;[1786] SYSVAR_INPCUR low byte: cursor char = space
    DB    $EF                       ;[1787] SYSVAR_INPCUR high byte: alternate cursor char ($EF)
    DB    0                         ;[1788] EXFLAG: extension flag (0 = no extension active)
    JP    $0FBE                     ;[1789] SYSVAR_GLINE: default line-draw hook (partial PLOT code)
    DW    0                         ;[178C] SYSVAR_GOLDX: graphics cursor X = 0
    DB    0                         ;[178E] SYSVAR_GOLDY: graphics cursor Y = 0
    DW    0                         ;[178F] SYSVAR_GNEWX: new graphics X = 0
    DB    0                         ;[1791] SYSVAR_GNEWY: new graphics Y = 0
    DB    0                         ;[1792] SYSVAR_PROTST: protect store = 0 (all planes writable)
    JP    OUTB                      ;[1793] SYSVAR_OUTB: pixel-write hook -> OUTB
    DW    CHRTBS-320                ;[1796] SYSVAR_CHRTBL: character table (ALPHA) at CHRTBS-320
    DW    CHRTBS                    ;[1798] SYSVAR_GPHTBL: graphics character table at CHRTBS
    DW    KBPERL                    ;[179A] SYSVAR_BPERL: bytes per screen line = 32 (normal height)
    DB    0                         ;[179C] SYSVAR_MASK: display mask = 0 (overwrite mode off)
    JP    ERR_NOT_YET_IMP           ;[179D] SYSVAR_SLFRAM: scroll/linefeed hook (not implemented)
    JP    ERR_NOT_YET_IMP           ;[17A0] (reserved hook)
    JP    ERR_NOT_YET_IMP           ;[17A3] (reserved hook)
    JP    ERR_NOT_YET_IMP           ;[17A6] (reserved hook)
    JP    ERR_NOT_YET_IMP           ;[17A9] (reserved hook)
    JP    ERR_NOT_YET_IMP           ;[17AC] SYSVAR_FLIGHT/FJOY area: lightpen/joystick = not implemented
    DB    $C9                       ;[17AF] SYSVAR_FUSER0[0]: $C9 = RET (USER0 = no-op by default)
    DW    0                         ;[17B0] SYSVAR_FUSER0[1-2]
    DB    $C9                       ;[17B2] SYSVAR_FUSER1[0]: RET
    DW    0                         ;[17B3] SYSVAR_FUSER1[1-2]
    DW    KBLUE                     ;[17B5] SYSVAR_BLUBNK: BLUE video bank base address ($8000)
    DW    KRED                      ;[17B7] SYSVAR_REDBNK: RED video bank base address ($C000)
    DW    KGREEN                    ;[17B9] SYSVAR_GRNBNK: GREEN video bank base address ($C000)
    JP    ERR_NOT_YET_IMP           ;[17BB] SYSVAR_NMIRAM: NMI handler (not implemented)
    JP    ERR_NOT_YET_IMP           ;[17BE] SYSVAR_RSTRAM: IRQ/reset handler (not implemented)
    DW    ERRS                      ;[17C1] SYSVAR_ERRTBL: address of error message table
    DB    $50,$01,$04,$03           ;[17C3] CASLEV=$50/$80, COARSE=$01, FINE=$04, SYNCLEN=$03 (default tape speed)
    DB    $28                       ;[17C7] SYSVAR_PLYLEV: playback voltage reference ($28 = 40)
    DW    DATA_CASTBL               ;[17C8] SYSVAR_CASTBL: waveform table address
    JP    RBIT                      ;[17CA] SYSVAR_RBIT: bit-read hook -> RBIT
    JP    WBYTE                     ;[17CD] SYSVAR_WBYTE: byte-write hook -> WBYTE
    JP    PP                        ;[17D0] PP hook (print/paging?)
    JP    NTPS                      ;[17D3] NTPS hook (number-to-print-string?)
    JP    EE                        ;[17D6] EE hook (expression evaluator entry?)
    JP    DBASLN                    ;[17D9] SYSVAR_DBASLN: display BASIC line -> DBASLN
    JP    DEBUG                     ;[17DC] DEBUG hook
    JP    VIDEO                     ;[17DF] SYSVAR_VIDEO: character output hook -> VIDEO
    JP    LINP                      ;[17E2] SYSVAR_LINP: line input hook -> LINP
    JP    VRPTS                     ;[17E5] SYSVAR_VRPTS: string variable pointer hook -> VRPTS
    DB    0                         ;[17E8] (padding / end of VROM block)

;
; Two-beep intro sequence data.
; Used by START to produce the power-on double beep.
; Each pair of bytes is a VDU sequence: $04 (CLS) followed by $07 (BELL).
;
DATA_2BEEPS:
    DB $04,$07,$04,$07              ;[17E9] VDU 4 (CLS), VDU 7 (beep), VDU 4, VDU 7

;
; Power-on introduction/logo display sequence.
; Output via PLINE at startup.  The sequence uses VDU codes and graphic
; character codes to display the "LYNX" logo on screen:
;   $04 = CLS, $07 = BELL, $18 = VDU 24 (double-height on),
;   $F3..$F9 = graphic characters forming the LYNX logo,
;   $19 = VDU 25 (double-height off), $0A = line feed, $0D = CR, $00 = end.
;
INTRO:
    DB    $04,$07,$18,$F3,$F4       ;[17ED] CLS, BEEP, double-height on, LYNX logo chars 1-2
    DB    $F5,$F6,$F7,$F8,$F9       ;[17F2] LYNX logo chars 3-7
    DB    $19,$0A,$0A,$0D,$00       ;[17F7] double-height off, LF, LF, CR, end


;
; BASIC line analysis: advance DE past the current token.
; Handles the special cases where a token (such as LEN, ASC, VAL) is followed
; by a string expression sub-expression (marked with SOS/$7C or $79), or where
; the token is a numeric literal (NUM/$7E or HNUM/$7A), in which case an extra
; 5 bytes follow (the floating-point value).
;
ADV:
    LD    A,(DE)                    ;[17FC] Read current token at DE
    INC   DE                        ;[17FD] Advance past it
    CP    $7C                       ;[17FE] SOS: start-of-string sub-expression marker?
    JR    Z,ADVSOS                  ;[1800] Yes: scan ahead to matching EOS
    CP    $79                       ;[1802] ARGSOS: argument-string sub-expression?
    JR    Z,ADVSOS                  ;[1804] Yes: scan ahead to EOS
    CP    LEN                       ;[1806] LEN token (which precedes a string)?
    JR    Z,ADV                     ;[1808] Yes: recurse to skip the string operand too
    CP    ASC                       ;[180A] ASC token?
    JR    Z,ADV                     ;[180C] Yes: recurse
    CP    VAL                       ;[180E] VAL token?
    JR    Z,ADV                     ;[1810] Yes: recurse
    CP    HNUM                      ;[1812] Hex number literal marker?
    JR    Z,ADV2                    ;[1814] Yes: skip 5-byte float value
    CP    NUM                       ;[1816] Decimal number literal marker?
    RET   NZ                        ;[1818] No: nothing extra to skip, return
ADV2:
    INC   DE                        ;[1819] Skip 2 extra bytes (float high word)
    INC   DE                        ;[181A] 
ADV1:
    INC   DE                        ;[181B] Skip remaining 3 bytes of 5-byte float
    INC   DE                        ;[181C] 
    INC   DE                        ;[181D] 
    RET                             ;[181E] 

;
; Scan forward past a string sub-expression, looking for the EOS ($7B) token
; that closes it.  Calls ADV repeatedly to step over each token within the
; sub-expression, then checks for EOS; loops until found.
;
ADVSOS:
    CALL  ADV                       ;[181F] Advance past next token inside string expr
    CP    EOS                       ;[1822] Is it the end-of-string marker ($7B)?
    JR    NZ,ADVSOS                 ;[1824] No: keep scanning
    RET                             ;[1826] Yes: DE now points past the EOS

;
; Display BASIC line helper: saves DE, calls DBASL (display current line), restores DE.
; Used to print a BASIC line from within the line-display path without losing
; the current parse pointer.
;
PNAMST:
    PUSH  DE                        ;[1827] Save parse pointer
    CALL  DBASL                     ;[1828] Display the current BASIC line (from IX)
    POP   DE                        ;[182B] Restore parse pointer
    RET                             ;[182C] 

;
; Print the name (text form) of the token at DE into the BASIC listing output.
; Handles variables, numeric literals, hex literals, and keyword tokens.
; Called by the BASIC line-display (LIST) machinery.
;
; Token encoding in the internal tokenised line format:
;   $00..$7F (below $80): variable or special marker
;     - NUM ($7E): followed by 5-byte floating-point literal
;     - HNUM ($7A): followed by 5-byte float (displayed as &xxxx hex)
;     - SOS ($7C): string sub-expression begin
;     - $80+: variable token (bit 6 cleared -> letter A-Z or a-z)
;   $80..$BF: function/operator tokens (looked up in SYSVAR_TTBL)
;   $C0+: command tokens
;
PNAME:
    LD    A,(DE)                    ;[182D] Read token at DE
    CP    SOS                       ;[182E] SOS ($7C) = string sub-expression?
    JR    Z,PNAMST                  ;[1830] Yes: display the sub-expression as a line
    CP    $80                       ;[1832] Is it a function/operator token ($80+)?
    JR    NC,PNE1                   ;[1834] Yes: look it up in token table
    CP    NUM                       ;[1836] Numeric literal ($7E)?
    JR    Z,PNAME2                  ;[1838] Yes: display as decimal number
    CP    HNUM                      ;[183A] Hex literal ($7A)?
    JR    Z,PNEH1                   ;[183C] Yes: display as &xxxx
    RES   6,A                       ;[183E] Clear bit 6 to get variable letter index
    ADD   A,'A'-1                   ;[1840] Convert to ASCII letter (1='A', 2='B', ...)
    CP    'Z'+1                     ;[1842] Is it A-Z?
    JP    C,PUTCHAR                 ;[1844] Yes: print the letter and return
    ADD   A,6                       ;[1847] No: adjust for lowercase letters (a-z range)
    JP    PUTCHAR                   ;[1849] Print the letter

PNAME2:
    PUSH  DE                        ;[184C] Save current parse pointer
    INC   DE                        ;[184D] Step past the NUM marker
    EX    DE,HL                     ;[184E] HL -> the 5-byte float value in the line
    CALL  LNUM1                     ;[184F] Load the float from (HL) into WRA1
    CALL  PN                        ;[1852] Print WRA1 as a decimal number string
    POP   DE                        ;[1855] Restore parse pointer
    RET                             ;[1856] (DE still points to the NUM marker, caller advances)

;
; Print keyword token: handles function/operator tokens ($80..$FF).
; Dispatches to sub-routines that look up the token text in SYSVAR_TTBL
; and print it with appropriate surrounding spaces.
;
PNE1:
    CP    LEN                       ;[1857] LEN token (has a string argument)?
    JR    Z,PNE14                   ;[1859] Yes: print keyword then recurse for string
    CP    ASC                       ;[185B] ASC token?
    JR    Z,PNE14                   ;[185D] Yes
    CP    VAL                       ;[185F] VAL token?
    JR    NZ,PNE11                  ;[1861] No: just print the keyword
PNE14:
    CALL  PNE11                     ;[1863] Print the keyword text
    PUSH  DE                        ;[1866] Save parse pointer
    INC   DE                        ;[1867] Advance past the token
    CALL  PNAMST                    ;[1868] Display the string sub-expression that follows
    POP   DE                        ;[186B] Restore parse pointer
    RET                             ;[186C] 

;
; Print a token's keyword text from the token table.
; Looks up the token in SYSVAR_TTBL, then prints each character of the keyword,
; stripping bit 7 from the final character.  Surrounding spaces are added for
; binary operators (AND, OR, etc.) by SP1/SP2.
;
PNE11:
    CALL  TOKEN_TO_WORD             ;[186D] HL -> first char of keyword in token table
PNE15:
    LD    A,(HL)                    ;[1870] Read character
    RES   7,A                       ;[1871] Clear bit 7 (last-char marker) to get ASCII
PNE12:
    RST   $08                       ;[1873] Print the character
    INC   HL                        ;[1874] Advance to next character
    BIT   7,(HL)                    ;[1875] Is bit 7 set on the next char? (= end of word)
    RET   NZ                        ;[1877] Yes: done (next entry starts here)
    LD    A,(HL)                    ;[1878] No: read next char (bit 7 clear = more to print)
    JR    PNE12                     ;[1879] Print it

;
; Print a hex literal token (&xxxx format).
; Displays a '&' prefix, loads the 5-byte float from the token stream into WRA1,
; converts it to an integer, then prints it as 4 hex digits via PHEXHL.
;
PNEH1:
    PUSH  DE                        ;[187B] Save parse pointer
    LD    A,'&'                     ;[187C] Hex prefix character
    RST   $08                       ;[187E] Print '&'
    INC   DE                        ;[187F] Step past HNUM marker
    EX    DE,HL                     ;[1880] HL -> 5-byte float in the token stream
    CALL  LNUM1                     ;[1881] Load float into WRA1
    CALL  FPINT                     ;[1884] Convert WRA1 float to integer in HL
    CALL  PHEXHL                    ;[1887] Print HL as 4 hex digits
    POP   DE                        ;[188A] Restore parse pointer
    RET                             ;[188B] 

;
; Find the text entry for a token in the token table.
; Subtracts $7F from the token value to get a 1-based index, then scans
; SYSVAR_TTBL sequentially, stepping over entries by looking for bytes with
; bit 7 set (which mark the last character of each entry).
; Returns HL pointing to the first character of the matching entry.
;
TOKEN_TO_WORD:
    SUB   $7F                       ;[188C] Convert token to 1-based index (token $80 -> 1)
    LD    B,A                       ;[188E] B = index (number of entries to skip)
    LD    HL,(SYSVAR_TTBL)          ;[188F] HL -> token text table base
    DEC   HL                        ;[1892] Pre-decrement (loop increments before testing)
TOKEN_TO_WORD_FIND:
    INC   HL                        ;[1893] Advance to next character
    BIT   7,(HL)                    ;[1894] Is bit 7 set? (= last char of a token entry)
    JR    Z,TOKEN_TO_WORD_FIND      ;[1896] No: still within current entry, keep scanning
    DJNZ  TOKEN_TO_WORD_FIND        ;[1898] Yes: end of one entry; decrement index, loop
    RET                             ;[189A] HL points to last char of the target entry

;
; SP1: called when the token at the top of the operator stack has a precedence
; level that requires a prefix to be printed before the next operand.
; Checks whether the token needs a space prefix (used by unary operators and
; parenthesised sub-expressions).  If the token is below PARENS range, returns
; directly; otherwise falls through to print the keyword with SP21.
;
SP1:
    CP    FN0                       ;[189B] Is token below FN0 ($C2)? (e.g. a simple function)
    RET   NC                        ;[189D] No: no prefix needed, return
    CP    PARENS                    ;[189E] Is token below PARENS ($BF)?
    RET   C                         ;[18A0] Yes: return without prefix
    POP   IX                        ;[18A1] Pop return address into IX (for JP (IX) return)
    JR    SP21                      ;[18A3] Print keyword and arrange prefix spaces

;
; SP2: called before printing a binary operator; arranges surrounding spaces
; for operators at or above AND/OR precedence (ORQ and above get spaces on both
; sides, lower-precedence operators get a trailing space only).
;
SP2:
    POP   IX                        ;[18A5] Pop return address into IX
    CP    POWER                     ;[18A7] Is token below POWER ($C5)?
    JR    C,SP2E                    ;[18A9] Yes: low-precedence unary, no leading space
    CP    ORQ                       ;[18AB] Is token below ORQ ($D0, i.e. AND/OR level)?
    JR    C,SP21                    ;[18AD] Yes: keyword only, no leading space
    LD    HL,$2020                  ;[18AF] HL = two space characters (leading space)
    PUSH  HL                        ;[18B2] Push them onto stack to be printed by PS
SP21:
    LD    C,A                       ;[18B3] Save token in C
    INC   A                         ;[18B4] Token + 1 = next token (to find end of this entry)
    CALL  TOKEN_TO_WORD             ;[18B5] HL -> last char of next entry (= end of this entry)
SP22:
    DEC   HL                        ;[18B8] Step back one character
    LD    A,(HL)                    ;[18B9] Read character
    BIT   7,A                       ;[18BA] Is bit 7 set? (= first char of this entry)
    RES   7,A                       ;[18BC] Strip bit 7 to get ASCII value
    PUSH  AF                        ;[18BE] Push character onto stack
    JR    Z,SP22                    ;[18BF] Not the first char yet: keep scanning backwards
    LD    A,C                       ;[18C1] Restore token
    CP    ORQ                       ;[18C2] Is it AND/OR level or above?
    JR    C,SP2E                    ;[18C4] No: no trailing space
    LD    A,' '                     ;[18C6] Yes: push a trailing space
    PUSH  AF                        ;[18C8] (will be printed after keyword by PS)
SP2E:
    JP    (IX)                      ;[18C9] Return via saved return address

;
; PS: prints all characters stacked on the Z80 stack down to the sentinel $00,
; then restores the sentinel and returns via IX.
; Characters are pushed individually (as AF pairs) by SP21/SP22.
; The sentinel $00 pushed by PP marks the bottom of the character stack.
;
PS:
    POP   IX                        ;[18CB] Save return address in IX
PS1:
    POP   AF                        ;[18CD] Pop next character from stack
    OR    A                         ;[18CE] Is it the $00 sentinel?
    JR    Z,PSX                     ;[18CF] Yes: done
    RST   $08                       ;[18D1] No: print the character
    JR    PS1                       ;[18D2] Loop
PSX:
    PUSH  AF                        ;[18D4] Restore the $00 sentinel to the stack
    JP    (IX)                      ;[18D5] Return via saved address

;
; PP: prints a tokenised (Polish/RPN) expression in human-readable infix form.
; Called via SYSVAR_PP hook during BASIC line display (LIST).
; DE points to the start of the Polish expression buffer; HL is used for output.
;
; The Polish notation used by the Lynx BASIC interpreter stores expressions in
; a form where operators follow their operands (postfix/RPN).  This routine
; reverses the process, reconstructing infix notation with correct operator
; precedence and parenthesisation for display.
;
; IY is used to point to SYSVAR_SYNL (a level counter used during traversal).
; The $00 sentinel pushed at entry marks the bottom of the operator stack.
;
PP:
    XOR   A                         ;[18D7] A = 0 (sentinel value)
    PUSH  AF                        ;[18D8] Push sentinel onto stack
    LD    IY,SYSVAR_SYNL            ;[18D9] IY -> level counter in SYSVAR area
PP1:
    LD    A,(DE)                    ;[18DD] Read next token from Polish expression
    CP    EOP                       ;[18DE] Is it EOP ($7F = end of polish)?
    JP    Z,PPX                     ;[18E0] Yes: done
    CP    PARENS                    ;[18E3] Is it >= PARENS ($BF)? (i.e. an operator)
    JR    C,PP5                     ;[18E5] No: it's an operand, process it
    LD    A,')'                     ;[18E7] Operator: check if it's a close-paren token
    CALL  Z,PUTCHAR                 ;[18E9] If exactly PARENS, print ')' to close paren group
    CALL  ADV                       ;[18EC] Advance DE past this token (and any trailing data)
    JR    PP1                       ;[18EF] Next token
PP5:
    LD    (IY+$00),$00              ;[18F1] Reset level counter to 0
    LD    L,E                       ;[18F5] Save current scan position (restart point)
    LD    H,D                       ;[18F6] (HL = DE = start of this operand group)
PP2:
    INC   (IY+$00)                  ;[18F7] Increment level (test for <0 condition)
    DEC   (IY+$00)                  ;[18FA] Decrement back (sets flags without changing value)
    JP    M,PP6                     ;[18FD] Negative: reached end of sub-expression, emit
    CALL  ADV                       ;[1900] Advance DE past current token
    LD    A,(DE)                    ;[1903] Read next token
    CP    EOP                       ;[1904] End of polish?
    JR    Z,PP6                     ;[1906] Yes: emit stacked operators and operand
    CP    PARENS                    ;[1908] Operator token?
    JP    NC,PP3                    ;[190A] Yes: handle operator
    INC   (IY+$00)                  ;[190D] Operand: increment level counter
    JR    PP2                       ;[1910] Continue scanning
PP3:
    CP    FN1                       ;[1912] Is operator binary (>= FN1/$C3)?
    JR    C,PP4                     ;[1914] No: it's unary, don't decrement level
    DEC   (IY+$00)                  ;[1916] Binary operator: decrement level
PP4:
    EXX                             ;[1919] Save DE/HL scan pointers in alternate registers
    INC   (IY+$00)                  ;[191A] Test level == 0
    DEC   (IY+$00)                  ;[191D] (flags set; value unchanged)
    CALL  Z,SP1                     ;[1920] Level 0: print any required prefix (unary op space)
    INC   (IY+$00)                  ;[1923] Test level == -1
    PUSH  AF                        ;[1926] Save flags
    DEC   (IY+$00)                  ;[1927] Restore level value
    POP   AF                        ;[192A] 
    CALL  Z,SP2                     ;[192B] Level -1: print operator with surrounding spaces
    EXX                             ;[192E] Restore scan pointers
    JP    PP2                       ;[192F] Continue
PP6:
    CALL  PS                        ;[1932] Print all stacked operator characters
    LD    E,L                       ;[1935] Restore scan position to saved restart point
    LD    D,H                       ;[1936] 
    LD    A,(DE)                    ;[1937] Read the operand token at the restart point
    CALL  PNAME                     ;[1938] Print its name (variable, number, or keyword)
    CALL  ADV                       ;[193B] Advance DE past the operand
    JP    PP1                       ;[193E] Continue with next token
PPX:
    POP   AF                        ;[1941] Remove sentinel from stack
    RET                             ;[1942] 

;
; TK: tokeniser -- tries to match the text at DE against the token tables.
; If a keyword is found, advances DE past it and returns the token byte in A
; (carry clear).  If no keyword matches, returns the raw character at DE in A
; and advances DE by 1 (carry set).
;
; Searches first through SYSVAR_TTBL (function/operator tokens, WORDS=$80
; entries), using TKSUB to normalise the first character and TK1 to step
; through entries. The '.' abbreviation convention is also handled (e.g. PR.
; matches PRINT).
;
TK:
    LD    HL,(SYSVAR_TTBL)          ;[1943] HL -> token text table base
    DEC   HL                        ;[1946] Pre-decrement (loop starts with INC)
    LD    B,WORDS                   ;[1947] B = $80 = number of token table entries
    CALL  TKSUB                     ;[1949] Normalise first char at DE (uppercase, set bit 7)
TK1:
    INC   HL                        ;[194C] Advance to next char in table
    BIT   7,(HL)                    ;[194D] Is bit 7 set? (= first char of a new entry)
    JR    Z,TK1                     ;[194F] No: still within current entry, skip
    CP    (HL)                      ;[1951] Does first char match table entry?
    JR    Z,TK2                     ;[1952] Yes: possible match, verify rest of word
TK5:
    DJNZ  TK1                       ;[1954] No: decrement count, try next entry
    LD    A,(DE)                    ;[1956] No match found: return raw character at DE
    SCF                             ;[1957] Set carry to indicate "no token found"
    RET                             ;[1958] 

TK2:
    PUSH  DE                        ;[1959] Save input pointer (in case match fails)
TK3:
    INC   DE                        ;[195A] Advance input pointer
    INC   HL                        ;[195B] Advance table pointer
    EX    DE,HL                     ;[195C] Swap so RST $10 operates on DE (input)
    RST   $10                       ;[195D] Skip spaces in input (DE advances past spaces)
    EX    DE,HL                     ;[195E] Swap back
    RST   $10                       ;[195F] Skip spaces in table pointer too
    BIT   7,(HL)                    ;[1960] Is this the last char of the table entry?
    JR    NZ,TK4                    ;[1962] Yes: all chars matched, token found
    CP    '.'                       ;[1964] Input char is '.'? (abbreviation shorthand)
    JR    Z,TK6                     ;[1966] Yes: treat as matching the rest of the keyword
    CP    $40                       ;[1968] Is char < '@' (i.e. non-alpha)?
    JR    C,TK9                     ;[196A] Yes: compare directly without case conversion
    AND   %11011111                 ;[196C] Force uppercase for case-insensitive compare
TK9:
    CP    (HL)                      ;[196E] Does input char match table char?
    JR    Z,TK3                     ;[196F] Yes: keep comparing
    POP   DE                        ;[1971] No: restore saved input pointer
    CALL  TKSUB                     ;[1972] Re-normalise first char (for next table scan)
    JR    TK5                       ;[1975] Continue searching
TK6:
    INC   DE                        ;[1977] '.' abbreviation: advance past the '.'
    RST   $10                       ;[1978] Skip any trailing spaces
TK4:
    POP   HL                        ;[1979] Discard saved input pointer (match succeeded)
    XOR   A                         ;[197A] 
    SUB   B                         ;[197B] Token value = WORDS - remaining_count
    OR    A                         ;[197C] Clear carry (token found)
    RET                             ;[197D] A = token byte, carry clear

;
; TKSUB: normalise the first character of a potential keyword for tokeniser
; comparison.  Skips leading spaces (RST $10), sets bit 7 (to match the
; format used in the token table where first chars have bit 7 set), and
; converts to uppercase for case-insensitive matching.
; Returns without matching ($C0 or above = non-alpha, e.g. '(' or '+').
;
TKSUB:
    RST   $10                       ;[197E] Skip spaces; A = first non-space char at DE
    OR    $80                       ;[197F] Set bit 7 (table first-char format)
    CP    $C0                       ;[1981] Is it $C0 or above? (non-alpha character)
    RET   C                         ;[1983] Yes: return as-is (symbols are matched literally)
    AND   %11011111                 ;[1984] Convert to uppercase (clear bit 5)
    RET                             ;[1986] 

;
; NPSTR: handle a string comparison or assignment in the NTPS (normal-to-polish)
; converter.  Called when a string sub-expression is encountered.
; Stores the string operator ('=' or '>') and the string operand in the Polish
; buffer, then updates the syntax counters in the IX syntax frame.
;
NPSTR:
    LD    B,(IX+$02)                ;[1987] Save current syntax counter
    LD    C,(IX+$00)                ;[198A] Save current syntax type
    PUSH  IX                        ;[198D] Save IX syntax frame
    PUSH  BC                        ;[198F] Save BC
    LD    (HL),$7C                  ;[1990] Store SOS ($7C) marker in Polish buffer
    INC   HL                        ;[1992] Advance Polish buffer pointer
    CALL  READ_STRING_EXPR          ;[1993] Read and encode the string expression into HL
    RST   $10                       ;[1996] Skip spaces in input (DE)
    CP    '='                       ;[1997] Is next char '='?
    JR    Z,NPSTR1                  ;[1999] Yes: valid string comparison operator
    CP    '>'                       ;[199B] Is it '>'?
    CALL  NZ,ERR_SOMETHG_MISSG      ;[199D] No: syntax error ("something missing")
NPSTR1:
    LD    (HL),A                    ;[19A0] Store the operator ('=' or '>') in Polish buffer
    INC   HL                        ;[19A1] 
    INC   DE                        ;[19A2] Advance past the operator in input
    CALL  READ_STRING_EXPR          ;[19A3] Read the right-hand string expression
    LD    (HL),EOS                  ;[19A6] Store EOS ($7B) to close the string sub-expression
    INC   HL                        ;[19A8] 
    POP   BC                        ;[19A9] Restore BC
    POP   IX                        ;[19AA] Restore IX syntax frame
    LD    (IX+$02),B                ;[19AC] Restore syntax counter
    LD    (IX+$00),C                ;[19AF] Restore syntax type
    LD    (IX+$01),$01              ;[19B2] Set syntax state: variable follows (string result)
    INC   (IX+$02)                  ;[19B6] Increment operand count
    LD    A,$01                     ;[19B9] Signal: operand just read
    JP    NP2                       ;[19BB] Re-enter NTPS main loop

;
; NTPS: convert a normal (infix) BASIC expression to Reverse Polish (postfix)
; notation for the evaluator.  DE points to the infix input; HL points to the
; output Polish buffer.
;
; Uses IX as a pointer to a 4-byte syntax checking frame (SYSVAR_SYNL area):
;   (IX+0) = SYNL: previous syntax type (for adjacency checking)
;   (IX+1) = SYNP: current/incoming syntax type
;   (IX+2) = syntax counter (operand/operator balance; must return to 0)
;   (IX+3) = NPM:  last operand/operator flag (0 = last was operator, non-0 = operand)
;
; The operator stack is the Z80 hardware stack.  A $00 sentinel is pushed at
; entry to mark the bottom of the operator stack.
;
NTPS:
    XOR   A                         ;[19BE] A = 0 (operator stack sentinel)
    PUSH  AF                        ;[19BF] Push sentinel
    LD    IX,SYSVAR_SYNL            ;[19C0] IX -> syntax check frame
    LD    (IX+$00),$04              ;[19C4] SYNL = 4 (initial "previous type")
    LD    (IX+$01),$04              ;[19C8] SYNP = 4 (initial "current type")
    LD    (IX+$02),$FF              ;[19CC] Syntax counter = $FF (effectively -1 to start)
NP1:
    XOR   A                         ;[19D0] A = 0: last token was an operator/start
NP2:
    LD    (SYSVAR_NPM),A            ;[19D1] Store NPM flag (0 = operator, non-0 = operand)
    CALL  SYNTAX                    ;[19D4] Validate syntax adjacency (error if illegal)
    RST   $10                       ;[19D7] Skip spaces in input
    CALL  TEST_FOR_STR_EXP          ;[19D8] Is next token a string expression?
    JR    Z,NPSTR                   ;[19DB] Yes: handle string comparison
    LD    A,(DE)                    ;[19DD] Read next character from input
    CP    '-'                       ;[19DE] Could be unary negation or binary subtract
    JP    Z,NOS                     ;[19E0] Disambiguate based on NPM flag
    CP    '('                       ;[19E3] Open parenthesis?
    JP    Z,NP3                     ;[19E5] Yes: push onto operator stack
    CP    ')'                       ;[19E8] Close parenthesis?
    JP    Z,NP4                     ;[19EA] Yes: pop stack to matching '('
    CALL  TKSL                      ;[19ED] Try to tokenise as keyword/operator
    JP    NC,NP5                    ;[19F0] Carry clear: token found, handle it
    CALL  TEST_ALPHA                ;[19F3] Is it an alphabetic variable?
    JP    NC,NP6                    ;[19F6] Yes: emit as variable
    CALL  TEST_DIGIT                ;[19F9] Is it a digit?
    JP    NC,NP7                    ;[19FC] Yes: read and emit as numeric literal
    CP    '&'                       ;[19FF] Hex literal prefix?
    JP    Z,NP7H                    ;[1A01] Yes: read as hex number
    CP    '.'                       ;[1A04] Leading '.' (e.g. .5)?
    JP    Z,NP7                     ;[1A06] Yes: treat as numeric literal
NP9:
    LD    (IX+$01),$08              ;[1A09] SYNP = 8 = "command" syntax type
    CALL  SYNTAX                    ;[1A0D] Validate; will trigger error if out of place
NP92:
    POP   AF                        ;[1A10] Pop operator from operator stack
    OR    A                         ;[1A11] Is it the $00 sentinel?
    JR    Z,NP91                    ;[1A12] Yes: stack empty, finish
    CP    '('                       ;[1A14] Is it an unmatched '('?
    CALL  Z,ERR_MISSING_BRACKET     ;[1A16] Yes: syntax error
    LD    (HL),A                    ;[1A19] Store operator in Polish output buffer
    INC   HL                        ;[1A1A] 
    CALL  DSC                       ;[1A1B] Decrement syntax counter (balance check)
    JR    NP92                      ;[1A1E] Pop next operator
NP91:
    LD    (HL),EOP                  ;[1A20] Store EOP ($7F) end-of-polish marker
    INC   HL                        ;[1A22] 
    XOR   A                         ;[1A23] 
    OR    (IX+$02)                  ;[1A24] Check syntax counter: should be 0 (balanced)
    CALL  NZ,ERR_SOMETHG_MISSG      ;[1A27] Non-zero: missing operand or operator
    RET                             ;[1A2A] 

NP5:
    LD    (SYSVAR_NPM),A            ;[1A2B] Store token as NPM (marks "last was operand/fn")
    CP    NOT                       ;[1A2E] Is it the NOT operator?
    JP    Z,NOS1                    ;[1A30] Yes: handle as unary prefix
    CP    THEN                      ;[1A33] Is token >= THEN? (i.e. a command, not operator)
    JR    NC,NP9                    ;[1A35] Yes: treat as end-of-expression
    CP    PARENS                    ;[1A37] Is it >= PARENS? (arithmetic operator)
    JP    NC,NP10                   ;[1A39] Yes: handle as binary operator
    LD    (HL),A                    ;[1A3C] Function token: store directly in Polish buffer
    INC   HL                        ;[1A3D] 
    INC   (IX+$02)                  ;[1A3E] Increment syntax counter (expects one result)
    LD    B,$C3                     ;[1A41] Assume FN1 ($C3) = function taking one arg
    LD    C,$03                     ;[1A43] SYNP = 3 for FN1
    CP    SIN                       ;[1A45] Is function >= SIN? (standard numeric functions)
    JR    NC,NP12                   ;[1A47] Yes: use FN1 syntax
    LD    B,$C2                     ;[1A49] No: use FN0 ($C2) = function taking no arg
    INC   (IX+$02)                  ;[1A4B] Extra increment for FN0 (two results expected)
    LD    (IX+$03),$00              ;[1A4E] NPM = 0
    CP    LEN                       ;[1A52] Is it LEN, ASC, or VAL? (takes string arg)
    JR    Z,NP52                    ;[1A54] 
    CP    ASC                       ;[1A56] 
    JR    Z,NP52                    ;[1A58] 
    CP    VAL                       ;[1A5A] 
    JR    NZ,NP53                   ;[1A5C] No: proceed normally
NP52:
    PUSH  BC                        ;[1A5E] Save BC (FN0/FN1 and SYNP values)
    CALL  TEST_FOR_STR_EXP          ;[1A5F] Verify a string expression follows
    CALL  NZ,ERR_TYPE_MISMATCH      ;[1A62] No string: type mismatch error
    LD    (HL),$79                  ;[1A65] Store ARGSOS ($79) = string-argument marker
    INC   HL                        ;[1A67] 
    PUSH  IX                        ;[1A68] Save IX syntax frame
    LD    B,(IX+$02)                ;[1A6A] Save syntax counter
    LD    C,(IX+$00)                ;[1A6D] Save syntax type
    PUSH  BC                        ;[1A70] 
    CALL  READ_STRING_EXPR          ;[1A71] Encode the string argument into Polish buffer
    POP   BC                        ;[1A74] 
    POP   IX                        ;[1A75] Restore IX
    LD    (IX+$00),C                ;[1A77] Restore syntax type
    LD    (IX+$02),B                ;[1A7A] Restore syntax counter
    RST   $10                       ;[1A7D] Skip spaces
    RST   $20                       ;[1A7E] Expect specific character (next byte is target)
    DB    ')'                       ;[1A7F] Expected closing ')'
    LD    (HL),A                    ;[1A80] Store ')' in Polish buffer
    INC   HL                        ;[1A81] 
    INC   DE                        ;[1A82] Advance past ')'
    LD    (HL),EOS                  ;[1A83] Store EOS ($7B) to close string sub-expression
    INC   HL                        ;[1A85] 
    POP   BC                        ;[1A86] Restore BC
NP53:
    LD    C,2                       ;[1A87] C = 2: FN0 SYNP value
NP12:
    LD    (IX+$01),C                ;[1A89] Set SYNP to FN0 or FN1 syntax type
    JP    NP103                     ;[1A8C] Handle operator stack precedence

NP3:
    PUSH  AF                        ;[1A8F] Push '(' onto operator stack
    INC   DE                        ;[1A90] Advance past '(' in input
    LD    A,(SYSVAR_SYNL)           ;[1A91] Was the previous token a variable?
    CP    1                         ;[1A94] SYNL = 1 means a variable just preceded '('
    JR    NZ,NP31                   ;[1A96] No: normal parenthesised expression
    POP   BC                        ;[1A98] Yes: pop the '(' we just pushed
    LD    A,$C4                     ;[1A99] A = ARRAY token ($C4)
    PUSH  AF                        ;[1A9B] Push ARRAY token as operator instead
    PUSH  BC                        ;[1A9C] Push '(' back
    DEC   HL                        ;[1A9D] Step back in Polish buffer
    SET   6,(HL)                    ;[1A9E] Set bit 6 on the variable token = mark as array
    INC   HL                        ;[1AA0] 
NP31:
    LD    (IX+$01),$04              ;[1AA1] SYNP = 4: '(' in syntax table
    JP    NP1                       ;[1AA5] Continue (operand or unary op can follow)

NP4:
    POP   AF                        ;[1AA8] Close paren: pop operator from stack
    CP    '('                       ;[1AA9] Is it the matching '('?
    JR    Z,NP41                    ;[1AAB] Yes: matching bracket found
    OR    A                         ;[1AAD] Is it the $00 sentinel (unmatched ')')?
    JP    Z,NP91                    ;[1AAE] Yes: treat as end of expression
    LD    (HL),A                    ;[1AB1] Store popped operator in Polish buffer
    INC   HL                        ;[1AB2] 
    CALL  DSC                       ;[1AB3] Decrement syntax counter
    JR    NP4                       ;[1AB6] Keep popping until matching '(' found
NP41:
    LD    A,PARENS                  ;[1AB8] Store PARENS marker ($BF) in Polish buffer
    INC   DE                        ;[1ABA] Advance past ')' in input
    LD    (HL),A                    ;[1ABB] 
    INC   HL                        ;[1ABC] 
    LD    (IX+$01),5                ;[1ABD] SYNP = 5: ')' in syntax table
    JP    NP2                       ;[1AC1] Binary operator or end can follow

NP6:
    CALL  TEST_UPPER_LOW            ;[1AC4] Convert variable letter to token value
    LD    (HL),A                    ;[1AC7] Store variable token in Polish buffer
    INC   HL                        ;[1AC8] 
    INC   DE                        ;[1AC9] Advance past variable letter in input
    LD    (IX+$01),$01              ;[1ACA] SYNP = 1: variable in syntax table
    INC   (IX+$02)                  ;[1ACE] Increment syntax counter
    JP    NP2                       ;[1AD1] Binary operator or end can follow

NP7H:
    LD    (HL),HNUM                 ;[1AD4] Store HNUM ($7A) hex literal marker in buffer
    JR    NP71                      ;[1AD6] Read the hex value

NP7:
    LD    (HL),NUM                  ;[1AD8] Store NUM ($7E) decimal literal marker
NP71:
    INC   HL                        ;[1ADA] Advance past marker in Polish buffer
    PUSH  HL                        ;[1ADB] Save Polish buffer pointer
    CALL  RDN                       ;[1ADC] Read number from DE input into WRA1 (float)
    POP   HL                        ;[1ADF] Restore Polish buffer pointer
    PUSH  DE                        ;[1AE0] Save input pointer
    EX    DE,HL                     ;[1AE1] DE -> Polish buffer, HL -> WRA1
    LD    HL,SYSVAR_WRA1            ;[1AE2] HL -> 5-byte working register
    LD    BC,5                      ;[1AE5] Copy 5 bytes (the float value)
    LDIR                            ;[1AE8] Copy float from WRA1 into Polish buffer
    EX    DE,HL                     ;[1AEA] Restore: HL -> next Polish buffer position
    POP   DE                        ;[1AEB] Restore input pointer
    LD    A,$02                     ;[1AEC] SYNP = 2: numeric literal in syntax table
    LD    (SYSVAR_SYNP),A           ;[1AEE] Update syntax type
    INC   (IX+$02)                  ;[1AF1] Increment syntax counter
    JP    NP2                       ;[1AF4] Binary operator or end can follow

;
; NOS: disambiguate '-' as unary negation or binary subtraction.
; If NPM is zero (last token was an operator or start of expression), '-' is
; unary negation (NEGATE token); otherwise it is binary subtraction (SUBT token).
;
NOS:
    LD    A,(SYSVAR_NPM)            ;[1AF7] A = NPM flag (0 = operator preceded '-')
    OR    A                         ;[1AFA] Test for zero
    LD    A,SUBT                    ;[1AFB] Preload A with SUBT token ($C9)
    INC   DE                        ;[1AFD] Advance past '-' in input
    JR    NZ,NP10                   ;[1AFE] NPM non-zero: binary subtract, handle as operator
    LD    A,NEGATE                  ;[1B00] NPM zero: unary negation ($C1)
NOS1:
    PUSH  AF                        ;[1B02] Push NEGATE onto operator stack
    LD    (IX+$01),$06              ;[1B03] SYNP = 6: negation in syntax table
    JP    NP1                       ;[1B07] Operand must follow

;
; NP10: handle a binary operator (arithmetic, comparison, logical).
; Pops operators from the stack while their precedence >= the new operator's
; precedence, emitting them to the Polish buffer.  Then pushes the new operator.
;
NP10:
    LD    B,A                       ;[1B0A] B = new operator token
    LD    (IX+$01),$07              ;[1B0B] SYNP = 7: binary operator in syntax table
NP103:
    POP   AF                        ;[1B0F] Pop operator from stack
    OR    A                         ;[1B10] Is it the $00 sentinel?
    JR    Z,NP101                   ;[1B11] Yes: stack empty, push new operator
    CP    '('                       ;[1B13] Is it a '(' bracket?
    JR    Z,NP101                   ;[1B15] Yes: stop popping (brackets delimit precedence)
    LD    C,A                       ;[1B17] C = popped operator
    CALL  PRIORITY                  ;[1B18] Compare priority(C) vs priority(B)
    LD    A,C                       ;[1B1B] Restore popped operator
    JR    C,NP101                   ;[1B1C] Carry: priority(C) < priority(B), stop popping
    LD    (HL),A                    ;[1B1E] Emit popped operator to Polish buffer
    INC   HL                        ;[1B1F] 
    CALL  DSC                       ;[1B20] Decrement syntax counter
    JR    NP103                     ;[1B23] Pop next
NP101:
    PUSH  AF                        ;[1B25] Restore popped operator back onto stack
    PUSH  BC                        ;[1B26] Push new operator onto stack
    LD    A,(IX+$03)                ;[1B27] A = NPM value
    OR    A                         ;[1B2A] 
    JP    NZ,NP1                    ;[1B2B] NPM non-zero: next token is an operand
    INC   A                         ;[1B2E] NPM zero: set A to 1
    JP    NP2                       ;[1B2F] Continue: binary operator or operand can follow

;
; DSC: decrement syntax counter if the operator requires it.
; NEGATE, PARENS, and NOT are unary or structural and do not consume an
; operand from the counter; all other operators do.
;
DSC:
    CP    NEGATE                    ;[1B32] Is it NEGATE ($C1)?
    RET   Z                         ;[1B34] Yes: no decrement
    CP    PARENS                    ;[1B35] Is it PARENS ($BF)?
    RET   Z                         ;[1B37] Yes: no decrement
    CP    NOT                       ;[1B38] Is it NOT ($C0)?
    RET   Z                         ;[1B3A] Yes: no decrement
    DEC   (IX+$02)                  ;[1B3B] Decrement syntax counter
    CALL  M,ERR_SOMETHG_MISSG       ;[1B3E] Negative: too many operators (missing operand)
    RET                             ;[1B41] 

;
; PRIORITY: compare the precedence of two operators C and B.
; Returns carry set if priority(C) < priority(B), i.e. C should stay on stack.
; Uses PTBL, indexed relative to PARENS, so token PARENS+n -> PTBL[n].
;
PRIORITY:
    PUSH  HL                        ;[1B42] 
    PUSH  DE                        ;[1B43] 
    LD    DE,PTBL-PARENS            ;[1B44] DE = base address adjusted for PARENS offset
    LD    H,$00                     ;[1B47] 
    LD    L,C                       ;[1B49] HL = C (stacked operator token)
    ADD   HL,DE                     ;[1B4A] HL -> PTBL entry for C
    LD    A,(HL)                    ;[1B4B] A = priority of C
    LD    H,$00                     ;[1B4C] 
    LD    L,B                       ;[1B4E] HL = B (new operator token)
    ADD   HL,DE                     ;[1B4F] HL -> PTBL entry for B
    CP    (HL)                      ;[1B50] Compare priority(C) with priority(B)
    POP   DE                        ;[1B51] 
    POP   HL                        ;[1B52] 
    RET                             ;[1B53] Returns carry if priority(C) < priority(B)

;
; Operator precedence table (PTBL).
; Indexed by token value minus PARENS ($BF), covering tokens $BF..$D5.
; Higher values = higher precedence (binds tighter).
; Layout: PARENS(0), NOT(6), NEGATE(14), FN0(20), FN1(18), ARRAY(22),
;         **(16), *(12), /(12), +(10), -(10), >=(8), <=(8), <>(8), >(8), <(8), =(8),
;         OR(2), AND(4), BNOR(2), BNXOR(2), BNAND(4), DIV(12), MOD(12)...
;
PTBL:
    DB    0,6,14,20,18,22           ;[1B54] PARENS, NOT, NEGATE, FN0, FN1, ARRAY
    DB    16,12,12,10,10            ;[1B5A] **, *, /, +, -
    DB    8,8,8,8,8,8               ;[1B5F] >=, <=, <>, >, <, =
    DB    2,4                       ;[1B65] OR, AND
    DB    2,2,4,12,12,12,12,12,12   ;[1B67] BNOR, BNXOR, BNAND, DIV, MOD, THEN, LABEL, @, ON

;
; SYNTAX: validates that the current token type (SYSVAR_SYNP) is legal
; following the previous token type (SYSVAR_SYNL).
; Uses SYNTBL to look up a bitmask of allowed successor types; signals a
; syntax error if the current type's bit is not set.
;
; Syntax type codes (used as bit positions in SYNTBL):
;   1 = variable, 2 = number, 3 = FN0 (0-arg fn), 4 = '(' / start,
;   5 = ')', 6 = NEGATE, 7 = binary operator, 8 = command
;
SYNTAX:
    PUSH  HL                        ;[1B70] 
    LD    A,(SYSVAR_SYNL)           ;[1B71] A = previous syntax type
    LD    BC,SYNTBL-1               ;[1B74] BC -> syntax table (1-indexed)
    LD    L,A                       ;[1B77] HL = previous type (index into table)
    LD    H,$00                     ;[1B78] 
    ADD   HL,BC                     ;[1B7A] HL -> SYNTBL[previous_type]
    LD    A,(SYSVAR_SYNP)           ;[1B7B] A = current/incoming syntax type
    LD    (SYSVAR_SYNL),A           ;[1B7E] Update SYNL = SYNP (for next call)
    LD    C,$01                     ;[1B81] C = 2^0 = 1 (will shift to form bitmask)
SYN1:
    DEC   A                         ;[1B83] Decrement type index
    JR    Z,SYN2                    ;[1B84] Reached zero: bitmask is in C
    SLA   C                         ;[1B86] Shift bitmask left (C = 2^(type-1))
    JR    SYN1                      ;[1B88] 
SYN2:
    LD    A,C                       ;[1B8A] A = bitmask for current type
    AND   (HL)                      ;[1B8B] Test against allowed-successors mask in table
    CALL  Z,ERR_SYNTAX              ;[1B8C] Zero: type not allowed here, syntax error
    POP   HL                        ;[1B8F] 
    RET                             ;[1B90] 

;
; SYNTBL: syntax adjacency table.
; Each byte is a bitmask of allowed successor syntax types (bit n = type n+1 allowed).
; Indexed 1..7 by the previous syntax type (SYNL).
; Bit 0 (value 1) = variable; bit 1 (2) = number; bit 2 (4) = FN0;
; bit 3 (8) = '('; bit 4 (16) = ')'; bit 5 (32) = NEGATE; bit 6 (64) = binary op;
; bit 7 (128) = command.
;
;   Entry 1 (variable):  %11011000 = variable, number, FN0, '(' allowed after
;   Entry 2 (number):    %11010000 = variable, number, '(' allowed after (but not FN0)
;   Entry 3 (FN0):       %00001000 = only '(' allowed after FN0
;   Entry 4 ('('):       %00101111 = variable, number, FN0, '(', NEGATE allowed
;   Entry 5 (')'):       %11010000 = variable, number, '(' after ')'
;   Entry 6 (NEGATE):    %00001111 = variable, number, FN0, '(' after negation
;   Entry 7 (binary op): %00101111 = variable, number, FN0, '(', NEGATE after operator
;
SYNTBL:
    DB    %11011000                 ;[1B91] After variable:    allows variable/number/FN0/'('
    DB    %11010000                 ;[1B92] After number:      allows variable/number/'('
    DB    %00001000                 ;[1B93] After FN0:         allows '(' only
    DB    %00101111                 ;[1B94] After '(':         allows var/num/FN0/'('/NEGATE
    DB    %11010000                 ;[1B95] After ')':         allows variable/number/'('
    DB    %00001111                 ;[1B96] After NEGATE:      allows var/num/FN0/'('
    DB    %00101111                 ;[1B97] After binary op:   allows var/num/FN0/'('/NEGATE

;
; RDN: read a numeric literal from the text at DE into WRA1 as a floating-point value.
; Handles decimal integers, decimals with fractional parts, 'E' format (scientific
; notation), and hex literals prefixed with '&'.
; The special case of a bare 'E' at DE is treated as zero (since 'E' alone in
; BASIC is not a number but may appear as a variable name in some contexts).
;
RDN:
    LD    A,(DE)                    ;[1B98] Read first character
    CP    'E'                       ;[1B99] Is it 'E' alone (no digit before E)?
    JR    Z,RDNMZ                   ;[1B9B] Yes: treat as zero
    CP    '&'                       ;[1B9D] Hex literal prefix?
    JR    NZ,RDNUM1                 ;[1B9F] No: normal decimal number
    LD    HL,$0000                  ;[1BA1] HL = 0 (hex accumulator)
RDNUM2:
    INC   DE                        ;[1BA4] Advance past '&' (or previous hex digit)
    LD    A,(DE)                    ;[1BA5] Read next character
    SUB   '0'                       ;[1BA6] Subtract '0' to get value
    JR    C,RDNMX                   ;[1BA8] Below '0': end of hex literal
    CP    $0A                       ;[1BAA] In range 0-9?
    JR    C,RDNUM3                  ;[1BAC] Yes: decimal digit
    SUB   $07                       ;[1BAE] Adjust for A-F (A=10, B=11, ...)
    CP    $0A                       ;[1BB0] Below 10?
    JR    C,RDNMX                   ;[1BB2] Yes: not a valid hex digit (between 9 and A)
    CP    $10                       ;[1BB4] Above F (>15)?
    JR    NC,RDNMX                  ;[1BB6] Yes: end of hex literal
RDNUM3:
    ADD   HL,HL                     ;[1BB8] HL <<= 1
    ADD   HL,HL                     ;[1BB9] HL <<= 1
    ADD   HL,HL                     ;[1BBA] HL <<= 1
    ADD   HL,HL                     ;[1BBB] HL = HL * 16 (shift in new nibble)
    ADD   A,L                       ;[1BBC] Add new hex digit to low byte
    LD    L,A                       ;[1BBD] Store
    JR    RDNUM2                    ;[1BBE] Read next hex digit
RDNMX:
    PUSH  DE                        ;[1BC0] Save updated DE (points past last hex digit)
    CALL  INTFP                     ;[1BC1] Convert HL integer to float in WRA1
    POP   DE                        ;[1BC4] 
    RET                             ;[1BC5] 

RDNMZ:
    PUSH  DE                        ;[1BC6] Save DE
    CALL  LZERO                     ;[1BC7] Load floating-point zero into WRA1
    POP   DE                        ;[1BCA] 
    RET                             ;[1BCB] 

;
; RDNUM1: read a signed decimal floating-point number from the text at DE.
; Handles optional leading '-', integer part (up to 8 significant digits),
; optional decimal point and fractional part, and trailing 'E±nn' exponent.
; The result is accumulated in WRA1 using the RL1A / RL10 digit-rotation helpers.
;
; C accumulates a raw exponent count; bit 7 of C = sign of the mantissa
; (bit 7 set = positive, cleared by a leading '-').
;
RDNUM1:
    LD    C,$C0                     ;[1BCC] C = $C0: positive mantissa (bit 7 set), exponent=0
    CALL  ZWRA1                     ;[1BCE] Zero WRA1 (mantissa = 0)
    LD    A,(DE)                    ;[1BD1] Read first char
    CP    MINUS                     ;[1BD2] Is it '-' ($2D)?
    EX    AF,AF'                    ;[1BD4] Save the comparison result in A'
    LD    A,(DE)                    ;[1BD5] Re-read first char
    CP    MINUS                     ;[1BD6] Is it '-'?
    JR    NZ,RDN1                   ;[1BD8] No: positive number, skip sign handling
    RES   7,C                       ;[1BDA] Negative: clear bit 7 of C (negative mantissa)
RDN2:
    INC   DE                        ;[1BDC] Advance past '-' (or leading zero)
RDN1:
    LD    A,(DE)                    ;[1BDD] Read character
    CP    '0'                       ;[1BDE] Leading zero?
    JR    Z,RDN2                    ;[1BE0] Yes: skip it (advance and re-read)
    CP    '.'                       ;[1BE2] Decimal point with no integer part (e.g. .5)?
    JR    Z,RDND1                   ;[1BE4] Yes: go to fractional part
    SUB   '0'                       ;[1BE6] Convert to 0-9
    CP    10                        ;[1BE8] Valid digit?
    JR    NC,NOTNM2                 ;[1BEA] No: number has no digits, skip to finish
    LD    B,$08                     ;[1BEC] B = 8: maximum significant digits to read
    DEC   C                         ;[1BEE] Pre-decrement exponent count (compensated in loop)
RDN3:
    LD    A,(DE)                    ;[1BEF] Read character
    CP    '.'                       ;[1BF0] Decimal point?
    JR    Z,RDND3                   ;[1BF2] Yes: switch to fractional part
    SUB   '0'                       ;[1BF4] Convert to 0-9
    CP    10                        ;[1BF6] Valid digit?
    JR    NC,NOTNM                  ;[1BF8] No: end of integer digits
    INC   C                         ;[1BFA] Increment exponent (one more digit before point)
    CALL  RL1A                      ;[1BFB] Rotate digit A into WRA1 mantissa (BCD shift)
    INC   DE                        ;[1BFE] Advance pointer
    DJNZ  RDN3                      ;[1BFF] Loop up to 8 digits
    DEC   DE                        ;[1C01] One too many: step back
    DEC   C                         ;[1C02] Compensate exponent
RDN4:
    LD    A,(DE)                    ;[1C03] Read remaining digits (beyond 8 significant)
    CP    '.'                       ;[1C04] Decimal point?
    JR    Z,RDND4                   ;[1C06] Yes: skip fractional part
    SUB   '0'                       ;[1C08] Digit?
    CP    10                        ;[1C0A] 
    JR    NC,NOTNM2                 ;[1C0C] No: end of integer part
    INC   DE                        ;[1C0E] Advance (digits beyond 8 are counted but not stored)
    INC   C                         ;[1C0F] Increment exponent count
    JR    RDN4                      ;[1C10] 
NOTNM:
    CALL  RL10                      ;[1C12] Rotate a zero into WRA1 (pad remaining digit slots)
    DJNZ  NOTNM                     ;[1C15] Repeat for remaining B slots
NOTNM2:
    LD    A,(SYSVAR_WRA1)           ;[1C17] Get exponent byte from WRA1
    OR    C                         ;[1C1A] Combine with accumulated raw exponent in C
    PUSH  AF                        ;[1C1B] Save combined exponent
    CALL  REXP                      ;[1C1C] Read optional 'E±nn' exponent from input -> L
    POP   AF                        ;[1C1F] Restore combined exponent
    ADD   A,L                       ;[1C20] Add E-part exponent to combined exponent
    BIT   7,A                       ;[1C21] Is result exponent positive (bit 7 set in Lynx format)?
    JR    Z,NNM5                    ;[1C23] Zero: exponent is negative, check sign
    EX    AF,AF'                    ;[1C25] Get original sign comparison from A'
    CALL  Z,ERR_OVERFLOW            ;[1C26] Sign changed during E part: overflow error
    JR    NNM6                      ;[1C29] 
NNM5:
    EX    AF,AF'                    ;[1C2B] Get original sign
    CALL  NZ,ERR_OVERFLOW           ;[1C2C] Overflow if sign changed
NNM6:
    EX    AF,AF'                    ;[1C2F] Retrieve final exponent in A
NOTNM3:
    LD    (SYSVAR_WRA1),A           ;[1C30] Store exponent byte in WRA1
    LD    A,(SYSVAR_WRA1+$01)       ;[1C33] Read the top two mantissa digits
    OR    A                         ;[1C36] Are they zero?
    PUSH  DE                        ;[1C37] Save DE
    CALL  Z,LZERO                   ;[1C38] Yes: the value is zero, store FLOAT_ZERO
    POP   DE                        ;[1C3B] 
    RET                             ;[1C3C] 

;
; RDND1: read the fractional (decimal) part of a number, starting just after
; the decimal point.  Skips leading zeros (adjusting the exponent), then reads
; up to 8 significant fractional digits via RL1A.
;
RDND1:
    INC   DE                        ;[1C3D] Advance past '.'
    LD    A,(DE)                    ;[1C3E] Read first fractional character
    DEC   C                         ;[1C3F] Decrement exponent (first fractional digit = x0.1)
    CP    '0'                       ;[1C40] Leading zero in fraction?
    JR    Z,RDND1                   ;[1C42] Yes: loop back (dec C, skip zero, re-check)
    LD    B,8                       ;[1C44] B = 8 significant digits
    DEC   DE                        ;[1C46] Step back (RDND3 will INC before reading)
RDND3:
    INC   DE                        ;[1C47] Advance pointer
RDND2:
    LD    A,(DE)                    ;[1C48] Read character
    SUB   '0'                       ;[1C49] Convert to 0-9
    CP    10                        ;[1C4B] Valid digit?
    JR    NC,NOTNM                  ;[1C4D] No: done with significant digits
    CALL  RL1A                      ;[1C4F] Rotate digit into WRA1 mantissa
    DJNZ  RDND3                     ;[1C52] Repeat up to 8 times
RDND4:
    INC   DE                        ;[1C54] Skip remaining fractional digits (beyond 8)
    LD    A,(DE)                    ;[1C55] 
    SUB   '0'                       ;[1C56] 
    CP    10                        ;[1C58] Still a digit?
    JR    C,RDND4                   ;[1C5A] Yes: skip it
    JR    NOTNM2                    ;[1C5C] Finish number (combine exponents, store)

;
; REXP: read an optional 'E±nn' exponent from the text at DE.
; Returns the exponent value in L (signed: positive for E+n, negative for E-n).
; If the next character is not 'E', returns L=0 immediately.
; Handles E+, E-, E with no sign (positive assumed), and restores DE if 'E'
; is present but not followed by a valid exponent digit (e.g. a bare 'E' variable).
;
REXP:
    LD    L,$00                     ;[1C5E] Default exponent = 0
    LD    A,(DE)                    ;[1C60] Read character
    CP    'E'                       ;[1C61] Is it 'E'?
    RET   NZ                        ;[1C63] No: no exponent, return L=0
    INC   DE                        ;[1C64] Advance past 'E'
    LD    A,(DE)                    ;[1C65] Read sign character
    CP    MINUS                     ;[1C66] Is it '-'?
    JR    Z,RXP2                    ;[1C68] Yes: negative exponent
    CP    '+'                       ;[1C6A] Is it '+'?
    INC   DE                        ;[1C6C] Advance (speculatively, past '+')
    JR    Z,RXP1                    ;[1C6D] Yes: read positive exponent
    DEC   DE                        ;[1C6F] Not '+': un-advance
    CALL  TEST_DIGIT                ;[1C70] Is it a digit?
    JR    NC,RXP1                   ;[1C73] Yes: read unsigned positive exponent
    DEC   DE                        ;[1C75] Not a digit: restore DE to point back at 'E'
    RET                             ;[1C76] Return L=0 (treat 'E' as variable, not exponent)
RXP1:
    LD    A,(DE)                    ;[1C77] Read exponent digit
    SUB   '0'                       ;[1C78] Convert to 0-9
    CP    10                        ;[1C7A] Valid digit?
    RET   NC                        ;[1C7C] No: done (single-digit or no exponent)
    LD    L,A                       ;[1C7D] L = first exponent digit
    INC   DE                        ;[1C7E] Advance to second digit
    LD    A,(DE)                    ;[1C7F] Read it
    SUB   '0'                       ;[1C80] Convert to 0-9
    CP    10                        ;[1C82] Valid digit?
    RET   NC                        ;[1C84] No: single-digit exponent, done
    PUSH  AF                        ;[1C85] Save second digit
    LD    A,L                       ;[1C86] A = first digit
    RLCA                            ;[1C87] A *= 2
    RLCA                            ;[1C88] A *= 4
    ADD   A,L                       ;[1C89] A *= 5
    RLCA                            ;[1C8A] A *= 10
    LD    L,A                       ;[1C8B] L = first_digit * 10
    POP   AF                        ;[1C8C] Restore second digit
    ADD   A,L                       ;[1C8D] Add second digit
    LD    L,A                       ;[1C8E] L = two-digit exponent value
    INC   DE                        ;[1C8F] Advance past second digit
    RET                             ;[1C90] 
RXP2:
    INC   DE                        ;[1C91] Advance past '-'
    CALL  RXP1                      ;[1C92] Read positive exponent value into L
    LD    A,L                       ;[1C95] 
    NEG                             ;[1C96] Negate: L = -(exponent value)
    LD    L,A                       ;[1C98] 
    RET                             ;[1C99] 

;
; PHL: display the integer value in HL as a decimal number without leading zeros.
; Uses IY as a pointer into DECTBL (powers of 10) and a "leading zero" suppress flag.
; Saves and restores IY around the call via the PHL1 helper.
;
PHL:
    PUSH  IY                        ;[1C9A] Save IY (used for other purposes elsewhere)
    CALL  PHL1                      ;[1C9C] Do the actual display
    POP   IY                        ;[1C9F] Restore IY
    RET                             ;[1CA1] 
PHL1:
    LD    IY,DECTBL                 ;[1CA2] IY -> powers-of-10 table
    LD    D,$00                     ;[1CA6] D = 0 (used as leading-zero suppress flag: 0 = suppressing)
PHL2:
    XOR   A                         ;[1CA8] A = 0 (digit count)
    LD    B,(IY+$01)                ;[1CA9] BC = current power of 10 (high byte)
    LD    C,(IY+$00)                ;[1CAC] (low byte)
    OR    A                         ;[1CAF] Clear carry
PHL2A:
    SBC   HL,BC                     ;[1CB0] HL -= power-of-10
    JR    C,PHL4                    ;[1CB2] Went negative: digit is A
    INC   A                         ;[1CB4] Increment digit
    JR    PHL2A                     ;[1CB5] Subtract again
PHL4:
    ADD   HL,BC                     ;[1CB7] Restore HL (add back the over-subtraction)
    OR    A                         ;[1CB8] Is digit zero?
    JR    Z,PHL5                    ;[1CB9] Yes: possible leading zero
    DEC   D                         ;[1CBB] Non-zero: set D negative (enable output of zeros hereafter)
PHL5:
    BIT   7,D                       ;[1CBC] Is bit 7 set? (D negative = output enabled)
    JR    Z,PHL6                    ;[1CBE] No: suppress this leading zero
    ADD   A,'0'                     ;[1CC0] Convert digit to ASCII
    RST   $08                       ;[1CC2] Print the digit
PHL6:
    BIT   0,C                       ;[1CC3] Is C odd? (C=1 means we just processed the units digit)
    RET   NZ                        ;[1CC5] Yes: done (units power = 1, which is odd)
    INC   IY                        ;[1CC6] Advance to next (smaller) power of 10
    INC   IY                        ;[1CC8] (each entry is 2 bytes)
    JR    PHL2                      ;[1CCA] Process next digit

;
; Powers-of-10 table for PHL decimal display.
; Each entry is a 16-bit little-endian value.
;
DECTBL:
    DW    10000                     ;[1CCC] 10^4
    DW    1000                      ;[1CCE] 10^3
    DW    100                       ;[1CD0] 10^2
    DW    10                        ;[1CD2] 10^1
    DW    1                         ;[1CD4] 10^0

;
; PHL3: helper used by the floating-point printer (PN/PDEC).
; Rotates B digits out of WRA1 into a text buffer at HL, then backs up
; over trailing zeros using PN5.
;
PHL3:
    CALL  PN1                       ;[1CD6] Rotate B digits from WRA1 into buffer at HL
    DEC   HL                        ;[1CD9] Step back to last digit written
    CALL  PN5                       ;[1CDA] Remove trailing zeros (HL -> last significant digit)
    CP    '.'                       ;[1CDD] Was the last char a '.'?
    RET   Z                         ;[1CDF] Yes: leave HL pointing at '.', return
    INC   HL                        ;[1CE0] No: advance past last significant digit
    RET                             ;[1CE1] 

;
; PN1: rotate B decimal digits out of WRA1 into a text buffer at HL.
; Each call to RL1A shifts the next BCD digit out of the top of WRA1 into
; the low 4 bits of A, which is then converted to ASCII and stored.
;
PN1:
    CALL  RL1A                      ;[1CE2] Rotate top BCD digit of WRA1 into A (low 4 bits)
    AND   $0F                       ;[1CE5] Keep only the digit (0-9)
    ADD   A,'0'                     ;[1CE7] Convert to ASCII ('0'..'9')
    LD    (HL),A                    ;[1CE9] Store in buffer
    INC   HL                        ;[1CEA] Advance buffer pointer
    DJNZ  PN1                       ;[1CEB] Repeat B times
    RET                             ;[1CED] 

;
; PN5: scan backwards from HL through a digit string, removing trailing zeros.
; The number of digits to check is controlled by SYSVAR_ZFLAG:
;   bit 1 = 0: check 8 digits; bit 1 = 1, bit 0 = 0: check 3 digits (ROUND mode);
;   bit 1 = 1, bit 0 = 1: check 5 digits (TRAIL mode? partial rounding).
; Returns with HL pointing to the last non-zero digit (or '.').
;
PN5:
    PUSH  BC                        ;[1CEE] 
    LD    B,8                       ;[1CEF] Default: scan up to 8 digits
    LD    A,(SYSVAR_ZFLAG)          ;[1CF1] Read number display flag
    BIT   1,A                       ;[1CF4] Is bit 1 set?
    JR    Z,PN53                    ;[1CF6] No: use B=8
    LD    B,3                       ;[1CF8] Yes: start with B=3 (ROUND mode)
    BIT   0,A                       ;[1CFA] Is bit 0 also set?
    JR    Z,PN54                    ;[1CFC] No: use B=3
PN53:
    CALL  PN51                      ;[1CFE] Scan back B positions removing trailing zeros
PN54:
    POP   BC                        ;[1D01] 
    LD    A,(HL)                    ;[1D02] Return last character in A
    RET                             ;[1D03] 

PN52:
    DEC   HL                        ;[1D04] Step back one position
PN51:
    LD    A,(HL)                    ;[1D05] Read character
    CP    '0'                       ;[1D06] Is it a trailing zero?
    RET   NZ                        ;[1D08] No: found last significant digit
    DJNZ  PN52                      ;[1D09] Yes: step back and try again
    RET                             ;[1D0B] 

;
; PN7: display a floating-point number in scientific ('E') notation.
; Formats WRA1 as D.DDDDDDDEsNN where D is the first digit, DDDDDDD are
; further significant digits (trailing zeros suppressed), s is '+'/'-',
; and NN is the exponent.
; Uses SYSVAR_PRTBUF as a temporary text buffer.
;
PN7:
    LD    B,1                       ;[1D0C] B = 1: write first significant digit
    CALL  PN1                       ;[1D0E] Rotate first digit into buffer at HL
    LD    (HL),'.'                  ;[1D11] Place decimal point
    INC   HL                        ;[1D13] 
    LD    B,7                       ;[1D14] B = 7: write 7 more digits
    CALL  PHL3                      ;[1D16] Write digits and strip trailing zeros
    LD    (HL),'E'                  ;[1D19] Write 'E' exponent marker
    INC   HL                        ;[1D1B] 
    LD    (HL),0                    ;[1D1C] NUL-terminate the buffer (PLINE reads to NUL)
    LD    HL,SYSVAR_PRTBUF          ;[1D1E] HL -> start of print buffer
    CALL  PLINE                     ;[1D21] Print the mantissa string
    LD    HL,SYSVAR_WRA1            ;[1D24] HL -> WRA1 (exponent byte)
    BIT   6,(HL)                    ;[1D27] Is bit 6 set? (Lynx float: bit6=0 -> positive exp)
    LD    A,'-'                     ;[1D29] Prepare '-' for negative exponent
    JR    Z,PN8                     ;[1D2B] Bit 6 clear: negative exponent, print '-'
    LD    A,'+'                     ;[1D2D] Bit 6 set: positive exponent, print '+'
PN8:
    RST   $08                       ;[1D2F] Print '+' or '-'
    LD    A,(HL)                    ;[1D30] Re-read WRA1 exponent byte
    JR    NZ,PN9                    ;[1D31] Positive: use exponent as-is
    NEG                             ;[1D33] Negative: negate to get absolute value
PN9:
    AND   $3F                       ;[1D35] Mask to 6-bit exponent magnitude
    LD    L,A                       ;[1D37] HL = exponent value
    LD    H,$00                     ;[1D38] 
    JP    PHL                       ;[1D3A] Print exponent as decimal integer

;
; PZERO: display the value zero, with optional trailing decimal places
; controlled by SYSVAR_ZFLAG (TRAIL/ROUND mode).
;
PZERO:
    LD    A,'0'                     ;[1D3D] Print leading '0'
    RST   $08                       ;[1D3F] 
    LD    A,(SYSVAR_ZFLAG)          ;[1D40] Read display mode flag
    BIT   1,A                       ;[1D43] Is bit 1 set? (TRAIL or ROUND mode active)
    RET   Z                         ;[1D45] No: just '0', done
    PUSH  AF                        ;[1D46] Save ZFLAG
    LD    A,'.'                     ;[1D47] Print decimal point
    RST   $08                       ;[1D49] 
    POP   AF                        ;[1D4A] Restore ZFLAG
    LD    B,7                       ;[1D4B] Default: 7 decimal places
    BIT   0,A                       ;[1D4D] Is bit 0 set? (ROUND mode = fewer places)
    JR    Z,PZ1                     ;[1D4F] No: use 7
    LD    B,$05                     ;[1D51] Yes: use 5 decimal places
PZ1:
    LD    A,'0'                     ;[1D53] Print a '0' decimal place
    RST   $08                       ;[1D55] 
    DJNZ  PZ1                       ;[1D56] Repeat B times
    RET                             ;[1D58] 

;
; PN: display the floating-point value in WRA1 as a human-readable decimal string.
; Rounds the value first (via ROUND), then chooses the appropriate format:
;   - Zero exponent: display as '0'
;   - Exponent in range for fixed notation: display as integer or decimal
;   - Exponent out of range: display in scientific 'E' notation
; Negative values are preceded by '-'.
; SYSVAR_ZFLAG controls whether trailing zeros are appended (TRAIL/ROUND mode).
;
PN:
    CALL  ROUND                     ;[1D59] Round WRA1 to current precision
    LD    A,(SYSVAR_WRA1)           ;[1D5C] Read exponent byte
    LD    HL,SYSVAR_PRTBUF          ;[1D5F] HL -> print buffer
    BIT   7,A                       ;[1D62] Is bit 7 set? (negative value)
    JR    NZ,PN6                    ;[1D64] No (bit7=1 means positive in Lynx float format)
    LD    (HL),'-'                  ;[1D66] Negative: store '-' in buffer
    INC   HL                        ;[1D68] 
PN6:
    AND   $7F                       ;[1D69] Strip sign bit from exponent
    JR    Z,PZERO                   ;[1D6B] Exponent zero: display as '0'
    SUB   $40-2                     ;[1D6D] Adjust exponent: subtract $3E (bias)
    CP    10                        ;[1D6F] Is adjusted exponent >= 10? (very large number)
    JR    NC,PN7                    ;[1D71] Yes: use scientific notation
    CP    2                         ;[1D73] Is it < 2? (value is 0.01 to 0.999...)
    JR    C,PDEC                    ;[1D75] Yes: use decimal notation with leading '0.'
    LD    A,(SYSVAR_WRA1)           ;[1D77] Re-read exponent (with sign bit)
PN11:
    AND   $0F                       ;[1D7A] Low 4 bits = count of integer digits
    INC   A                         ;[1D7C] +1 (there is always at least 1 digit before '.')
    LD    B,A                       ;[1D7D] B = number of integer digits to write
    PUSH  AF                        ;[1D7E] Save count
    CALL  PN1                       ;[1D7F] Write B integer digits into buffer
    POP   AF                        ;[1D82] Restore count
    SUB   8                         ;[1D83] Remaining digits = 8 - integer_count
    NEG                             ;[1D85] = 8 - B (fractional digits available)
    LD    (HL),'.'                  ;[1D87] Place decimal point
    JR    Z,PN12                    ;[1D89] Zero fractional digits: go to trailing-zero strip
    LD    B,A                       ;[1D8B] B = number of fractional digits
    INC   HL                        ;[1D8C] Advance past '.'
    CALL  PN1                       ;[1D8D] Write fractional digits
    DEC   HL                        ;[1D90] Step back to last digit
PN12:
    CALL  PN5                       ;[1D91] Remove trailing zeros
    CP    '.'                       ;[1D94] Was last char a '.'?
    JR    Z,PN13                    ;[1D96] Yes: leave HL at '.', drop it
    INC   HL                        ;[1D98] No: advance past last significant digit
PN13:
    LD    (HL),$00                  ;[1D99] NUL-terminate the buffer
    LD    HL,SYSVAR_PRTBUF          ;[1D9B] HL -> buffer start
    JP    PLINE                     ;[1D9E] Print the complete number string

;
; PDEC: display a floating-point number in '0.ddd' form (value between 0.01 and 1).
; Stores '0.' then the required leading zeros, then 8 significant digits
; with trailing zeros stripped.
;
PDEC:
    LD    (HL),'0'                  ;[1DA1] Store '0'
    INC   HL                        ;[1DA3] 
    LD    (HL),'.'                  ;[1DA4] Store '.'
    INC   HL                        ;[1DA6] 
    SUB   1                         ;[1DA7] A = number of leading zeros after '.' (from exponent)
    JR    Z,PD1                     ;[1DA9] Zero leading zeros: go straight to digits
PD2:
    LD    (HL),'0'                  ;[1DAB] Store a leading '0'
    INC   HL                        ;[1DAD] 
    INC   A                         ;[1DAE] Increment (towards 0)
    JR    NZ,PD2                    ;[1DAF] Keep until A=0
PD1:
    LD    B,8                       ;[1DB1] B = 8 significant digits to write
    CALL  PHL3                      ;[1DB3] Write digits and strip trailing zeros
    JR    PN13                      ;[1DB6] NUL-terminate and print

;
; FIND_ARRAY: given a subscript value in HL and an array table entry pointed to
; by IX, returns in HL the address of the corresponding array element.
; Each array element is 5 bytes (a floating-point value).
; IX format: (IX+0/1) = base address of array data, (IX+2/3) = dimension size.
; Calls ERR_SUBS_OUT_RANGE if the subscript is out of bounds.
;
FIND_ARRAY:
    PUSH  HL                        ;[1DB8] Save subscript
    LD    C,(IX+$02)                ;[1DB9] C = dimension size low byte
    LD    B,(IX+$03)                ;[1DBC] B = dimension size high byte
    OR    A                         ;[1DBF] Clear carry
    LD    A,L                       ;[1DC0] Test subscript: is HL non-zero?
    OR    H                         ;[1DC1] 
    JR    Z,FNDAR1                  ;[1DC2] Zero subscript: allow (skip bounds check)
    DEC   HL                        ;[1DC4] HL = subscript - 1 (for <= comparison)
    SBC   HL,BC                     ;[1DC5] (subscript-1) - dimension: carry if in range
    CALL  NC,ERR_SUBS_OUT_RANGE     ;[1DC7] No carry: subscript >= dimension, error
FNDAR1:
    POP   HL                        ;[1DCA] Restore subscript
    LD    C,L                       ;[1DCB] BC = subscript (for multiply)
    LD    B,H                       ;[1DCC] 
    ADD   HL,HL                     ;[1DCD] HL = subscript * 2
    ADD   HL,HL                     ;[1DCE] HL = subscript * 4
    ADD   HL,BC                     ;[1DCF] HL = subscript * 5  (5 bytes per element)
    LD    C,(IX+$00)                ;[1DD0] C = array data base address low byte
    LD    B,(IX+$01)                ;[1DD3] B = array data base address high byte
    ADD   HL,BC                     ;[1DD6] HL = base + subscript*5 = element address
    RET                             ;[1DD7] 

;
; FARR: function handler for array element access (ARRAY token, $C4).
; Called from the evaluator when an array subscript expression is encountered.
; Evaluates the subscript, locates the array in the array table, bounds-checks,
; and returns the element value in WRA1.
;
FARR:
    PUSH  DE                        ;[1DD8] Save parse pointer
    CALL  CSW1                      ;[1DD9] Evaluate the subscript expression -> WRA1/IY
    DEC   IY                        ;[1DDC] Step IY back (calculator stack adjustment)
    LD    A,(IY+$00)                ;[1DDE] A = variable token from stack
    CALL  ARLOC2                    ;[1DE1] Locate array in array table -> IX
    LD    A,(IX+$00)                ;[1DE4] Check if array is defined
    OR    (IX+$01)                  ;[1DE7] Base address zero?
    CALL  Z,ERR_UNDEFINED_VAR       ;[1DEA] Yes: array not dimensioned, error
    CALL  FPINT                     ;[1DED] Convert WRA1 subscript float to integer in HL
    CALL  FIND_ARRAY                ;[1DF0] HL = address of array element
    INC   HL                        ;[1DF3] Advance to type byte of element
    LD    A,(HL)                    ;[1DF4] Read type byte
    INC   A                         ;[1DF5] Is it $FF (undefined element)?
    CALL  Z,ERR_UNDEFINED_VAR       ;[1DF6] Yes: error
    DEC   HL                        ;[1DF9] Restore HL to element base
    CALL  LNUM1                     ;[1DFA] Load element value into WRA1
    POP   DE                        ;[1DFD] Restore parse pointer
    RET                             ;[1DFE] 

;
; VPTA: variable pointer to array -- used when a variable token directly
; precedes an array subscript.  Pops the variable token from the calculator
; stack, locates the array, and returns the element address via FIND_ARRAY.
;
VPTA:
    POP   AF                        ;[1DFF] Pop (discard) return address (called via JP)
    CALL  ARLOC1                    ;[1E00] Locate array from variable token at DE
    LD    A,(IX+$00)                ;[1E03] Check array is defined
    OR    (IX+$01)                  ;[1E06] 
    CALL  Z,ERR_UNDEFINED_VAR       ;[1E09] Not defined: error
    JP    FIND_ARRAY                ;[1E0C] Return element address in HL

;
; ARRAY_LOCATE: decode an array subscript expression from the token stream,
; evaluate it, and locate the array table entry.
; Reads the variable token, the subscript expression inside '(' ... ')', and
; sets IX to point to the array table entry for that variable.
;
ARRAY_LOCATE:
    CALL  TEST_UPPER_LOW            ;[1E0F] Read and normalise variable letter -> A
    INC   DE                        ;[1E12] Advance past the variable token
ARLOC1:
    PUSH  AF                        ;[1E13] Save variable token
    INC   DE                        ;[1E14] Advance past '(' 
    RST   $28                       ;[1E15] Evaluate subscript expression (RST $28 = EE)
    LD    A,(DE)                    ;[1E16] Read next character
    CP    ')'                       ;[1E17] Should be ')'
    CALL  NZ,ERR_MISSING_BRACKET    ;[1E19] Missing bracket: syntax error
    INC   DE                        ;[1E1C] Advance past ')'
    PUSH  DE                        ;[1E1D] Save DE
    CALL  FPINT                     ;[1E1E] Convert subscript float to integer in HL
    POP   DE                        ;[1E21] 
    POP   AF                        ;[1E22] Restore variable token
ARLOC2:
    LD    IX,(SYSVAR_ATBL)          ;[1E23] IX -> array table base
    RLCA                            ;[1E27] Rotate variable token
    RLA                             ;[1E28] A = variable index * 4 (each entry is 4 bytes)
    LD    C,A                       ;[1E29] BC = offset into array table
    LD    B,$00                     ;[1E2A] 
    ADD   IX,BC                     ;[1E2C] IX -> array table entry for this variable
    RET                             ;[1E2E] 

;
; ESTOP: execute STOP statement.
; Saves the next line as the CONTinue address, displays "Stopped in line N",
; and returns to the command line.
; If the program is not running (current line pointer has $80 in first byte),
; signals an error (STOP is not valid at the prompt).
;
ESTOP:
    LD    IX,(SYSVAR_CURRLP)        ;[1E2F] IX -> current BASIC line being executed
    LD    A,(IX+$00)                ;[1E33] Read first byte of line
    CP    $80                       ;[1E36] Is it $80 (end-of-program / not in program)?
    CALL  Z,ERR_WRONG_MODE          ;[1E38] Yes: STOP at prompt is an error
    CALL  NEXT_LINE                 ;[1E3B] Advance IX to the next line (CONT resumes here)
STOP1:
    LD    (SYSVAR_CONTLP),IX        ;[1E3E] Save next line as CONT address
STOP2:
    LD    HL,STOPPED_MSG            ;[1E42] HL -> "Stopped" message
    CALL  PLINE                     ;[1E45] Print it
    CALL  ERRLN                     ;[1E48] Print " in line N"
    JP    TO_CMDLINE                ;[1E4B] Return to command line prompt

STOPPED_MSG:
    DB    NEWLINE,"Stopped",0       ;[1E4E] CR + "Stopped" + NUL

;
; FRND: RAND function -- returns a random integer in the range 0 to N-1,
; where N is the value in WRA1.
; Generates the next random number via FRNDS, converts it to a float,
; divides by 65536 (FLOAT_64k) to get a value in [0,1), then multiplies
; by N to get the result.  (The final scaling by N is handled by DIV.)
;
FRND:
    CALL  FRNDS                     ;[1E57] Advance SYSVAR_RNDNO and return new value in HL
    LD    HL,(SYSVAR_RNDNO)         ;[1E5A] HL = lower 16 bits of 31-bit random number
    CALL  INTFP                     ;[1E5D] Convert HL to float in WRA1
    LD    HL,FLOAT_64k              ;[1E60] HL -> floating-point constant 65536.0
    CALL  LNUM2                     ;[1E63] Load 65536.0 into WRA2
    JP    DIV                       ;[1E66] WRA1 = WRA1 / 65536.0 = random value in [0,1)

;
; FMEM: MEM function -- returns the number of free bytes of memory.
; Computes SP - SYSVAR_TOV (top of variables), which is the space between
; the current stack pointer and the top of the variable/string/array tables.
;
FMEM:
    LD    BC,(SYSVAR_TOV)           ;[1E69] BC = top-of-variables address
    LD    HL,0                      ;[1E6D] 
    ADD   HL,SP                     ;[1E70] HL = current stack pointer
    SBC   HL,BC                     ;[1E71] HL = SP - TOV = free memory
    JP    INTFP                     ;[1E73] Convert to float in WRA1 and return

;
; SUB_JUMP_TO_CMDLINE: resets the current-line pointer to zero (not running)
; then falls through to SUB_LINK_OFF to disable any active LINK and return
; to the command line.
;
SUB_JUMP_TO_CMDLINE:
    LD    HL,FLOAT_ZERO             ;[1E76] HL -> floating-point zero constant
    LD    (SYSVAR_CURRLP),HL        ;[1E79] Clear current-line pointer (= not in program)
    JP    SUB_LINK_OFF              ;[1E7C] Disable LINK output and return to prompt

;
; ERRLN: print " in line N" if currently executing a BASIC program,
; then prints a carriage return and "Ready!".
; If the current-line pointer has $80 in its first byte, execution is not
; in a program (command-line mode) so the line number is omitted.
;
ERRLN:
    LD    HL,(SYSVAR_CURRLP)        ;[1E7F] HL -> current BASIC line
    LD    A,(HL)                    ;[1E82] Read first byte
    CP    $80                       ;[1E83] Is it $80 (command-line mode)?
    JR    Z,ERLN1                   ;[1E85] Yes: skip line number display
    LD    HL,IN_LINE_ERMSG          ;[1E87] HL -> " in line " string
    CALL  PLINE                     ;[1E8A] Print it
    LD    HL,(SYSVAR_CURRLP)        ;[1E8D] HL -> current line again
    CALL  LNUM1                     ;[1E90] Load line number into WRA1
    CALL  PN                        ;[1E93] Print line number as decimal
ERLN1:
    LD    A,$1E                     ;[1E96] VDU 30 = clear to end of line
    RST   $08                       ;[1E98] 
    LD    A,$0D                     ;[1E99] CR
    RST   $08                       ;[1E9B] 
    JP    READY_MSG                 ;[1E9C] Print "Ready!" and return to prompt

IN_LINE_ERMSG:
    DB    " in line ",0             ;[1E9F] NUL-terminated " in line " string

;
; ERR_RECOVERY: BASIC error recovery handler.
; Called when an error occurs during program execution.
; If currently executing an INPUT statement, cleans up by printing a CR,
; unwinding the stack to the EXEC_LINE_LOOP return address, and re-entering
; the line execution loop (to re-prompt the INPUT).
; Otherwise calls ERRLN to display the error location and returns to the
; command line.
;
ERR_RECOVERY:
    LD    IX,(SYSVAR_CURRLP)        ;[1EA9] IX -> current BASIC line
    LD    A,(IX+$00)                ;[1EAD] First byte of line
    CP    $80                       ;[1EB0] Command-line mode?
    JR    Z,ERR_RECOVERY1           ;[1EB2] Yes: no special INPUT recovery
    LD    A,(IX+$06)                ;[1EB4] Read command token of current statement
    CP    INPUT                     ;[1EB7] Is it an INPUT statement?
    JR    NZ,ERR_RECOVERY1          ;[1EB9] No: normal error display
    LD    A,$0D                     ;[1EBB] Yes: print CR to move to new line
    RST   $08                       ;[1EBD] 
    LD    BC,EXEC2                  ;[1EBE] BC = target return address (EXEC_LINE_LOOP entry)
ERR_RECOVERY2:
    POP   HL                        ;[1EC1] Pop return address from stack
    OR    A                         ;[1EC2] Clear carry
    SBC   HL,BC                     ;[1EC3] Does HL == EXEC2?
    JR    NZ,ERR_RECOVERY2          ;[1EC5] No: keep unwinding
    JP    EXEC_LINE_LOOP            ;[1EC7] Yes: re-enter line execution loop
ERR_RECOVERY1:
    CALL  ERRLN                     ;[1ECA] Print error line info
    JP    JUMP_TO_CMDLINE           ;[1ECD] Return to command line

;
; FRNDS: advance the 31-bit pseudo-random number generator stored in
; SYSVAR_RNDNO (4 bytes at $61F0).
; Uses a linear feedback shift register algorithm: rotates bits through the
; 31-bit value and XORs in feedback from the upper bits via the address $61F2.
; The result is stored back into SYSVAR_RNDNO.
; Ensures the result is never zero (if zero, increments until non-zero).
;
FRNDS:
    LD    HL,($61F2)                ;[1ED0] HL = upper 2 bytes of RNDNO (feedback bits)
    RL    L                         ;[1ED3] Rotate L left through carry
    RL    H                         ;[1ED5] Rotate H left through carry
    RL    L                         ;[1ED7] Rotate again
    RL    H                         ;[1ED9] HL now holds feedback value
    LD    C,H                       ;[1EDB] C = feedback high byte
    LD    A,(SYSVAR_RNDNO)          ;[1EDC] A = RNDNO byte 0 (lowest)
    RLA                             ;[1EDF] Rotate A left through carry (from HL rotations)
    LD    B,A                       ;[1EE0] B = new RNDNO byte 0 candidate
    LD    DE,(SYSVAR_RNDNO+1)       ;[1EE1] DE = RNDNO bytes 1-2
    RL    E                         ;[1EE5] Rotate E through carry
    RL    D                         ;[1EE7] Rotate D through carry
    RES   7,D                       ;[1EE9] Clear bit 31 (maintain 31-bit value)
    LD    HL,(SYSVAR_RNDNO)         ;[1EEB] HL = RNDNO bytes 0-1
    ADD   HL,BC                     ;[1EEE] Add feedback to lower 16 bits
    LD    (SYSVAR_RNDNO),HL         ;[1EEF] Store updated lower 16 bits
    LD    HL,(SYSVAR_RNDNO+2)       ;[1EF2] HL = RNDNO bytes 2-3
    ADC   HL,DE                     ;[1EF5] Add feedback + carry to upper bits
    RES   7,H                       ;[1EF7] Keep value 31-bit (clear bit 31)
    LD    (SYSVAR_RNDNO+2),HL       ;[1EF9] Store updated upper 16 bits
    RET   P                         ;[1EFC] Return if result is non-zero (positive = non-zero)
    LD    HL,SYSVAR_RNDNO           ;[1EFD] Result is zero: force non-zero
FRND1:
    INC   (HL)                      ;[1F00] Increment byte
    RET   NZ                        ;[1F01] Non-zero: done
    INC   HL                        ;[1F02] Byte overflowed to zero: advance to next byte
    JR    FRND1                     ;[1F03] Try again

;
; ESC: test whether the ESC key is currently held down.
; Reads hardware port $80 (PORT) and tests bit 6.
; Returns Z set if ESC is pressed (bit 6 = 0 = active low).
;
ESC:
    LD    BC,PORT                   ;[1F05] BC = $0080 (keyboard hardware port)
    IN    B,(C)                     ;[1F08] Read keyboard status byte into B
    BIT   6,B                       ;[1F0A] Test bit 6 (ESC key: 0 = pressed)
    RET                             ;[1F0C] Returns: Z set if ESC pressed, NZ if not

;
; READY_MSG: print the "Ready!" message and return.
; Called after error display, STOP, and end-of-program.
;
READY_MSG:
    LD    HL,RDYMSG                 ;[1F0D] HL -> "Ready!" string
    JP    PLINE                     ;[1F10] Print and return via PLINE

RDYMSG:
    DB    "Ready!",NEWLINE,CEL,0    ;[1F13] "Ready!" + CR + VDU 30 (clear to EOL) + NUL

;
; TEST_FULL_RSTACK: check whether the BASIC return stack has room for one more
; entry (2 bytes).  The return stack grows upward from SYSVAR_RSTACK; its
; maximum size is 256 bytes ($100).
; If the stack pointer (SYSVAR_RSP) has reached SYSVAR_RSTACK + $100, the
; stack is full and ERR_RETURN_STACK_FULL is called.
; Returns HL = current RSP value on success.
;
TEST_FULL_RSTACK:
    LD    HL,(SYSVAR_RSTACK)        ;[1F1C] HL -> base of return stack
    LD    DE,$0100                  ;[1F1F] DE = 256 (stack capacity in bytes)
    ADD   HL,DE                     ;[1F22] HL = RSTACK + 256 (= top limit)
    LD    DE,(SYSVAR_RSP)           ;[1F23] DE = current stack pointer
    CALL  CHLDE                     ;[1F27] Compare HL with DE
    CALL  C,ERR_RETURN_STACK_FULL   ;[1F2A] Carry: RSP >= limit, stack full
    EX    DE,HL                     ;[1F2D] HL = current RSP (ready for caller to store into)
    RET                             ;[1F2E] 

;
; PUSH_HL_RSTACK: push the value of HL onto the BASIC return stack as a
; 16-bit little-endian entry, then update SYSVAR_RSP.
; DE is preserved across this call.
;
PUSH_HL_RSTACK:
    PUSH  DE                        ;[1F2F] Save DE
    PUSH  HL                        ;[1F30] Save value to push (HL)
    CALL  TEST_FULL_RSTACK          ;[1F31] HL = RSP, checks for overflow
    POP   DE                        ;[1F34] DE = value to store (original HL)
    LD    (HL),E                    ;[1F35] Store low byte at RSP
    INC   HL                        ;[1F36] 
    LD    (HL),D                    ;[1F37] Store high byte at RSP+1
    INC   HL                        ;[1F38] HL = new RSP
    LD    (SYSVAR_RSP),HL           ;[1F39] Update stack pointer
    POP   DE                        ;[1F3C] Restore DE
    RET                             ;[1F3D] 

;
; PUSH_A_RSTACK: push the single byte in A onto the BASIC return stack,
; then update SYSVAR_RSP.  Used to push token codes (e.g. GOSUB, REPEAT,
; WHILE=$36) that mark the type of a return-stack frame.
; Falls through into the tail of PUSH_HL_RSTACK at $1F38 (INC HL /
; LD (SYSVAR_RSP),HL / POP DE / RET), which is shared between both routines.
;
PUSH_A_RSTACK:
    PUSH  DE                        ;[1F3E] Save DE
    PUSH  AF                        ;[1F3F] Save A
    CALL  TEST_FULL_RSTACK          ;[1F40] HL = RSP, checks for overflow
    POP   AF                        ;[1F43] Restore A
    LD    (HL),A                    ;[1F44] Store byte at RSP
    JR    $1F38                     ;[1F45] Jump into PUSH_HL_RSTACK tail: INC HL / LD (SYSVAR_RSP),HL / POP DE / RET

;
; POP_HL_RSTACK: pop a 16-bit value from the BASIC return stack into HL.
; Decrements SYSVAR_RSP by 2 and returns the value.  DE is preserved.
;
POP_HL_RSTACK:
    PUSH  DE                        ;[1F47] Save DE
    LD    HL,(SYSVAR_RSP)           ;[1F48] HL = current RSP
    DEC   HL                        ;[1F4B] Step back to high byte
    LD    D,(HL)                    ;[1F4C] D = high byte
    DEC   HL                        ;[1F4D] Step back to low byte
    LD    E,(HL)                    ;[1F4E] E = low byte
    LD    (SYSVAR_RSP),HL           ;[1F4F] Update RSP (now points to popped entry base)
    EX    DE,HL                     ;[1F52] HL = popped 16-bit value
    POP   DE                        ;[1F53] Restore DE
    RET                             ;[1F54] 

;
; POP_A_RSTACK: pop a single byte from the BASIC return stack into A.
; Decrements SYSVAR_RSP by 1.
;
POP_A_RSTACK:
    LD    HL,(SYSVAR_RSP)           ;[1F55] HL = current RSP
    DEC   HL                        ;[1F58] Step back one byte
    LD    A,(HL)                    ;[1F59] A = popped byte
    LD    (SYSVAR_RSP),HL           ;[1F5A] Update RSP
    RET                             ;[1F5D] 

;
; SUB_LINK_ON: enable LINK output (send output to both screen and printer).
; Sets bits of SYSVAR_OTYPE: bit 1 = LINK active, bit 0 = screen output.
; SYSVAR_OTYPE layout: bit 7 = suppress screen, bit 1 = LINK (printer) on,
; bit 0 = screen on (0 = off, 1 = on).
;
SUB_LINK_ON:
    LD    C,$02                     ;[1F5E] C = $02 (LINK on, screen off)
SUB_LINK_SET:
    LD    A,(SYSVAR_OTYPE)          ;[1F60] Read current output type
    AND   $80                       ;[1F63] Keep only bit 7 (screen-suppress flag)
    OR    C                         ;[1F65] Set LINK/screen bits from C
    LD    (SYSVAR_OTYPE),A          ;[1F66] Store updated output type
    RET                             ;[1F69] 

;
; SUB_LINK_OFF: disable LINK output (screen output only).
; Sets SYSVAR_OTYPE bits to $01 (screen on, LINK off).
;
SUB_LINK_OFF:
    LD    C,$01                     ;[1F6A] C = $01 (screen on, LINK off)
    JR    SUB_LINK_SET              ;[1F6C] Apply via SUB_LINK_SET

;
; ZERO_MEM: initialise all BASIC runtime state for a new program run (RUN/NEW).
; Zeros the array table, clears DEFPROC pointer, resets TOV (top-of-variables)
; to just above EOB, resets the DATA pointer to just before SOB, initialises
; the return stack, and marks all 53 numeric variables (A-Z, a-z, plus one
; extra) as undefined ($FF in their type byte).
;
ZERO_MEM:
    CALL  ZERO_ARRAY                ;[1F6E] Zero all 53 array table entries
    LD    HL,$0000                  ;[1F71] 
    LD    (SYSVAR_PROCST),HL        ;[1F74] Clear DEFPROC pointer (no procedures defined)
    LD    HL,(SYSVAR_EOB)           ;[1F77] HL = end-of-BASIC pointer
    INC   HL                        ;[1F7A] HL = first byte after BASIC program
    LD    (SYSVAR_TOV),HL           ;[1F7B] TOV = just above BASIC (variables start here)
    LD    HL,(SYSVAR_SOB)           ;[1F7E] HL = start-of-BASIC pointer
    DEC   HL                        ;[1F81] HL = one byte before BASIC
    LD    (SYSVAR_DATAP),HL         ;[1F82] DATA pointer = before SOB (READ will search forward)
    LD    HL,(SYSVAR_RSTACK)        ;[1F85] HL -> return stack base
    LD    (HL),$00                  ;[1F88] Write sentinel $00 at stack base
    INC   HL                        ;[1F8A] 
    LD    (SYSVAR_RSP),HL           ;[1F8B] RSP = RSTACK+1 (stack empty, sentinel in place)
    LD    HL,(SYSVAR_VTBL)          ;[1F8E] HL -> variable table base
    LD    DE,$0005                  ;[1F91] DE = 5 (bytes per variable entry)
    LD    B,$35                     ;[1F94] B = 53 (26 uppercase + 26 lowercase + 1)
    INC   HL                        ;[1F96] Skip to type byte (offset 1 within each 5-byte entry)
ZERO_VTBL:
    LD    (HL),$FF                  ;[1F97] Mark variable as undefined ($FF = not set)
    ADD   HL,DE                     ;[1F99] Advance to next variable's type byte
    DJNZ  ZERO_VTBL                 ;[1F9A] Repeat for all 53 variables
    RET                             ;[1F9C] 

;
; FLCTN: LCTN function -- returns the internal byte offset of a BASIC line.
; Searches for the line number in WRA1 using FINDLN, skips the line number
; field, then returns the offset of the first statement byte as a float.
; This gives the programmer a way to obtain a line's memory position.
;
FLCTN:
    CALL  FINDLN                    ;[1F9D] Find line number (from WRA1) -> IX = line pointer
    CALL  SKIP_LNUM                 ;[1FA0] Skip past the line number in the line header
    EX    DE,HL                     ;[1FA3] HL = address after line number
    INC   HL                        ;[1FA4] HL = address of first statement byte
    JP    INTFP                     ;[1FA5] Convert HL integer to float in WRA1 and return

;
; ERANDOM: RANDOM statement -- seeds the random number generator with a
; value derived from the Z80 R register (refresh counter), which varies
; depending on how long the program has been running.
; Only the low 7 bits of R are used; result is stored as the first byte of
; SYSVAR_RNDNO.
;
ERANDOM:
    LD    A,R                       ;[1FA8] Read Z80 memory refresh counter
    AND   $7F                       ;[1FAA] Mask to 7 bits (R is a 7-bit counter)
    INC   A                         ;[1FAC] Ensure non-zero (FRNDS must never be seeded with 0)
    LD    (SYSVAR_RNDNO),A          ;[1FAD] Store as seed byte 0 of random number
    RET                             ;[1FB0] 

;
; ECLS: CLS statement -- clears the screen.
; Temporarily forces output to screen only (SYSVAR_OTYPE = $01) while sending
; the CLS control code (VDU 4 = clear screen on the Lynx), then restores the
; original output type so LINK state is not disturbed.
;
ECLS:
    LD    HL,SYSVAR_OTYPE           ;[1FB1] HL -> output type register
    LD    A,(HL)                    ;[1FB4] Save current output type
    PUSH  AF                        ;[1FB5] 
    LD    (HL),$01                  ;[1FB6] Force output to screen only
    LD    A,$04                     ;[1FB8] VDU 4 = clear screen
    RST   $08                       ;[1FBA] Send CLS
    POP   AF                        ;[1FBB] Restore saved output type
    LD    (HL),A                    ;[1FBC] 
    RET                             ;[1FBD] 

;
; EEND: END statement -- prints "Ready!" and exits the execution loop.
;
EEND:
    CALL  READY_MSG                 ;[1FBE] Print "Ready!\n"
    JP    EXEC_EXIT                 ;[1FC1] Exit program execution, return to command line

;
; EWEND: WEND statement -- close a WHILE loop.
; Pops the frame type byte from the return stack and verifies it is $36
; (the WHILE token).  Then pops the saved line pointer and jumps back
; to re-execute the WHILE condition.
;
EWEND:
    CALL  POP_A_RSTACK              ;[1FC4] Pop frame type byte
    CP    $36                       ;[1FC7] Is it WHILE ($36)?
    CALL  NZ,ERR_WEND_NO_WHILE      ;[1FC9] No: WEND without matching WHILE
    CALL  POP_HL_RSTACK             ;[1FCC] HL = saved WHILE line pointer
    POP   BC                        ;[1FCF] Discard current return address from Z80 stack
    JP    EXEC_BASIC                ;[1FD0] Re-execute from the WHILE line

;
; EWHILE: WHILE statement -- conditional loop start.
; Evaluates the condition expression (RST $28).  If the condition is false
; (WRA1 exponent byte = $80 = float zero), scans forward to find the matching
; WEND and skips past it.  If true, pushes the current line pointer and a
; WHILE frame marker ($36) onto the return stack.
;
EWHILE:
    RST   $28                       ;[1FD3] Evaluate condition expression -> WRA1
    LD    A,(SYSVAR_WRA1)           ;[1FD4] Read WRA1 exponent byte
    CP    $80                       ;[1FD7] Is it $80 (= floating-point zero = false)?
    JR    Z,DO_WHILE                ;[1FD9] Yes: skip to find WEND
    LD    HL,(SYSVAR_CURRLP)        ;[1FDB] Condition true: HL = current line pointer
    CALL  PUSH_HL_RSTACK            ;[1FDE] Push line pointer for WEND to return to
    LD    A,$36                     ;[1FE1] A = WHILE frame marker (WHILE token = $36)
    CALL  PUSH_A_RSTACK             ;[1FE3] Push frame type
    RET                             ;[1FE6] Continue execution with loop body

DO_WHILE:
    LD    IX,(SYSVAR_CURRLP)        ;[1FE7] IX = current line (the WHILE line)
    LD    C,$37                     ;[1FEB] C = WEND token ($37) = target to find
    LD    B,$36                     ;[1FED] B = WHILE token ($36) = nesting start
    CALL  SUB_WHILE                 ;[1FEF] Search forward for matching WEND, IX -> WEND line
    CALL  C,ERR_WHILE_NO_WEND       ;[1FF2] Carry = reached end of program without WEND
    LD    (SYSVAR_CURRLP),IX        ;[1FF5] Update current line to WEND line (will advance past it)
    RET                             ;[1FF9] 

;
; EUNTIL: UNTIL statement -- end of a REPEAT...UNTIL loop.
; Pops the frame type from the return stack and checks it is REPEAT ($38).
; Then pops the saved line pointer.  Evaluates the UNTIL condition: if true
; (non-zero), the loop exits; if false, sets CURRLP back to the REPEAT line
; to repeat the loop body.
;
EUNTIL:
    PUSH  DE                        ;[1FFA] Save current parse pointer
    CALL  POP_A_RSTACK              ;[1FFB] Pop frame type byte
    CP    REPEAT                    ;[1FFE] Is it REPEAT ($38)?
SECTION _48k_2
PHASE $2000
EUNT1:
    CALL  NZ,ERR_UNTIL_NO_REPEAT    ;[2000] No: UNTIL without matching REPEAT
    CALL  POP_HL_RSTACK             ;[2003] HL = saved REPEAT line pointer
    POP   DE                        ;[2006] Restore parse pointer
    PUSH  HL                        ;[2007] Save REPEAT line pointer
    RST   $28                       ;[2008] Evaluate UNTIL condition -> WRA1
    LD    A,(SYSVAR_WRA1)           ;[2009] Read WRA1 exponent
    CP    $80                       ;[200C] Is it zero (false = repeat again)?
    POP   HL                        ;[200E] Restore REPEAT line pointer
    RET   NZ                        ;[200F] Non-zero (true): exit loop, return normally
    LD    (SYSVAR_CURRLP),HL        ;[2010] False: set current line back to REPEAT line

;
; EREPEAT: REPEAT statement -- unconditional loop start.
; Pushes the current line pointer and a REPEAT frame marker ($38) onto the
; return stack, then continues execution.  UNTIL will use these to loop back.
;
EREPEAT:
    LD    HL,(SYSVAR_CURRLP)        ;[2013] HL = current BASIC line pointer
    CALL  PUSH_HL_RSTACK            ;[2016] Push line pointer for UNTIL to return to
    LD    A,REPEAT                  ;[2019] A = REPEAT frame marker ($38)
    JP    PUSH_A_RSTACK             ;[201B] Push frame type and return

;
; FGETN: GETN function -- waits until a key is pressed, then returns its
; ASCII value as a float.  Loops until KEY returns a non-zero value.
;
FGETN:
    CALL  KEY                       ;[201E] Poll keyboard driver -> A = key code (0 = no key)
    OR    A                         ;[2021] Is A zero?
    JR    Z,FGETN                   ;[2022] Yes: no key yet, loop
    JR    FINKY1                    ;[2024] Key pressed: convert to float

;
; FKEYN: KEYN function -- returns the ASCII value of the current key pressed,
; or 0 if no key is pressed.  Does not wait.
;
FKEYN:
    CALL  KEY                       ;[2026] Poll keyboard -> A = key code or 0
FINKY1:
    LD    L,A                       ;[2029] L = key code
    LD    H,$00                     ;[202A] H = 0
    JP    INTFP                     ;[202C] Convert HL to float in WRA1 and return

;
; KEY: call the keyboard driver pointed to by SYSVAR_KEYB.
; Sets up a return address (KEY_END) on the Z80 stack before jumping to the
; driver, so the driver can RET normally.  HL and BC are preserved.
; Returns A = ASCII key code, or 0 if no key is currently pressed.
;
KEY:
    PUSH  HL                        ;[202F] Save HL
    LD    HL,(SYSVAR_KEYB)          ;[2030] HL = address of keyboard driver routine
    PUSH  BC                        ;[2033] Save BC
    LD    BC,KEY_END                ;[2034] BC = return address for the driver
    PUSH  BC                        ;[2037] Push return address onto stack
    JP    (HL)                      ;[2038] Jump to keyboard driver (will RET to KEY_END)
KEY_END:
    POP   BC                        ;[2039] Restore BC
    POP   HL                        ;[203A] Restore HL
    RET                             ;[203B] 

;
; SUB_PUTCHAR: central character output dispatcher.
; Sends character A to the screen and/or printer depending on SYSVAR_OTYPE.
; SYSVAR_OTYPE bits: bit 0 = screen on, bit 1 = LINK/printer on, bit 7 = suppress screen.
; If bits 0 and 7 are both zero, skip directly to LINK output (SUB_LPUTCHAR).
; Otherwise calls SYSVAR_PRINTD (display driver) first, then falls into
; SUB_LPUTCHAR to handle LINK (printer) output.
;
SUB_PUTCHAR:
    LD    C,A                       ;[203C] Save character in C
    LD    A,(SYSVAR_OTYPE)          ;[203D] Read output type flags
    PUSH  BC                        ;[2040] Save C (character)
    PUSH  AF                        ;[2041] Save OTYPE
    AND   $81                       ;[2042] Mask: keep bit 7 (suppress) and bit 0 (screen)
    JR    Z,SUB_LPUTCHAR            ;[2044] Both zero: screen output disabled, go to LINK only
    LD    A,C                       ;[2046] Restore character
    LD    HL,(SYSVAR_PRINTD)        ;[2047] HL = display driver address
    LD    BC,SUB_LPUTCHAR           ;[204A] BC = return address (chain to LINK output)
    PUSH  BC                        ;[204D] Push return address for display driver
    JP    (HL)                      ;[204E] Call display driver; it will RET to SUB_LPUTCHAR

;
; SUB_LPUTCHAR: LINK output stage of SUB_PUTCHAR.
; Called after screen output (or directly if screen is disabled).
; Checks bit 1 of SYSVAR_OTYPE: if set, sends the character to the LINK
; (printer) driver at SYSVAR_LPRNTD.
;
SUB_LPUTCHAR:
    POP   AF                        ;[204F] Restore saved OTYPE
    POP   BC                        ;[2050] Restore character in C
    AND   $82                       ;[2051] Mask: keep bit 7 and bit 1 (LINK active)
    RET   Z                         ;[2053] Neither bit set: no printer output, return
    LD    A,C                       ;[2054] Restore character
    LD    HL,(SYSVAR_LPRNTD)        ;[2055] HL = printer driver address
    JP    (HL)                      ;[2058] Jump to printer driver (it will RET to caller)

;
; SUB_CHK_EXP_EVAL: check that the next byte in the token stream is SOP ($7D,
; start-of-polish marker), then evaluate the expression at SYSVAR_EE.
; Used before evaluating an expression to assert the expression is properly
; tokenised (starts with SOP).
;
SUB_CHK_EXP_EVAL:
    LD    A,(DE)                    ;[2059] Read next token from parse pointer DE
    RST   $20                       ;[205A] Assert: next byte must match the following DB
    DB    SOP                       ;[205B] Expected: SOP = $7D (start-of-polish marker)
    JP    SYSVAR_EE                 ;[205C] Jump through SYSVAR_EE to expression evaluator

;
; ECALL: CALL statement -- calls a machine-code subroutine at the address
; given by the expression in WRA1.
; Evaluates the address expression, then optionally evaluates a second
; expression (comma-separated) and passes it as a parameter in HL.
; The called routine may return a value in HL, which is saved in SYSVAR_HLSTORE.
;
ECALL:
    RST   $18                       ;[205F] Evaluate expression -> WRA1, convert to int -> HL
    PUSH  HL                        ;[2060] Save call address
    LD    A,(DE)                    ;[2061] Read next token
    CP    CR                        ;[2062] End of statement (CR)?
    JR    Z,ECALL1                  ;[2064] Yes: no parameter, go to call
    INC   DE                        ;[2066] Skip separator (comma or similar)
    RST   $18                       ;[2067] Evaluate parameter expression -> HL
ECALL1:
    POP   IX                        ;[2068] IX = call address
    LD    BC,ECALL2                 ;[206A] BC = return address after the called routine
    PUSH  BC                        ;[206D] Push return address
    JP    (IX)                      ;[206E] Call the machine-code routine (RET -> ECALL2)
ECALL2:
    LD    (SYSVAR_HLSTORE),HL       ;[2070] Save HL result from called routine ($61F4)
    RET                             ;[2073] 

;
; ERETURN: RETURN statement -- return from a GOSUB.
; Pops the frame type from the return stack and checks it is GOSUB ($11).
; Then pops the saved line pointer and restores CURRLP to resume after
; the GOSUB statement.
;
ERETURN:
    CALL  POP_A_RSTACK              ;[2074] Pop frame type byte
    CP    GOSUB                     ;[2077] Is it GOSUB ($11)?
    CALL  NZ,ERR_RETURN_NO_GOSUB    ;[2079] No: RETURN without GOSUB
EEPRN1:
    CALL  POP_HL_RSTACK             ;[207C] HL = saved line pointer (line after GOSUB)
    LD    (SYSVAR_CURRLP),HL        ;[207F] Restore current-line pointer
    RET                             ;[2082] Continue execution after the GOSUB

;
; ENEW: NEW statement -- erase the BASIC program and reset all state.
; Sets EOB = SOB (empty program), writes $80 end-of-program marker, resets
; CURRLP, then calls ZERO_MEM to clear all variables and stacks.
;
ENEW:
    LD    HL,(SYSVAR_SOB)           ;[2083] HL = start of BASIC program area
    LD    (SYSVAR_EOB),HL           ;[2086] EOB = SOB (program is now empty)
    LD    (HL),$80                  ;[2089] Write $80 end-of-program marker at SOB
    LD    (SYSVAR_CURRLP),HL        ;[208B] CURRLP = SOB (not in a program)
    CALL  ZERO_MEM                  ;[208E] Clear variables, stacks, DATA pointer
    JP    EXEC_EXIT                 ;[2091] Return to command line

;
; EINPUT: INPUT statement -- prompts the user for input and assigns values
; to the listed variables.
; If the next byte is '"' ($22), prints the quoted prompt string first.
; Prints "? " prompt, reads a line via SUB_INPUT_IS_ESC into INPBUF,
; then calls EIPTS to parse and assign the values.
; If any assignment fails (carry returned), re-prompts from the top.
;
EINPUT:
    CP    $22                       ;[2094] Is the next byte '"'? (quoted prompt)
    JR    NZ,EIPT1                  ;[2096] No: skip to prompt
    CALL  PRINT_STRING              ;[2098] Print the quoted prompt string
    INC   DE                        ;[209B] Skip past closing '"'
    INC   DE                        ;[209C] Skip past any separator after the string
EIPT1:
    PUSH  DE                        ;[209D] Save variable list pointer
    LD    A,'?'                     ;[209E] Print '?'
    RST   $08                       ;[20A0] 
    LD    A,' '                     ;[20A1] Print ' '
    RST   $08                       ;[20A3] 
    CALL  SUB_INPUT_IS_ESC          ;[20A4] Read input line into INPBUF; ESC handling
    LD    A,$0F                     ;[20A7] VDU 15 = cursor off
    RST   $08                       ;[20A9] 
    LD    DE,INPBUF                 ;[20AA] DE -> input buffer (data just entered)
    EXX                             ;[20AD] Swap to alternate registers (DE' = INPBUF)
    POP   DE                        ;[20AE] Restore variable list pointer into DE
    CALL  EIPTS                     ;[20AF] Parse input buffer and assign to variables
    JR    C,EIPT1                   ;[20B2] Carry: ran out of data, re-prompt
    RET                             ;[20B4] 

;
; EIPTS: parse input data (in DE', the alternate DE = INPBUF pointer) and
; assign successive values to the variables listed at DE.
; Handles both numeric and string variables.
; Returns carry set if the input buffer was exhausted before all variables
; were assigned (causes EINPUT to re-prompt).
;
EIPTS:
    EXX                             ;[20B5] Swap to alternate registers (DE = INPBUF pointer)
    LD    A,(DE)                    ;[20B6] Read next input character
    CP    CR                        ;[20B7] End of input line?
    EXX                             ;[20B9] Swap back (DE = variable list again)
    SCF                             ;[20BA] Set carry (signal: out of data)
    RET   Z                         ;[20BB] Yes: return with carry (need more input)
    CALL  VPTR_IS_STR               ;[20BC] Is the current variable a string? -> carry set if yes
    PUSH  DE                        ;[20BF] Save variable list pointer
    PUSH  HL                        ;[20C0] Save variable address
    JR    C,EIPT4                   ;[20C1] Carry: string variable, handle separately
    EXX                             ;[20C3] Numeric: swap to INPBUF pointer
    LD    HL,(SYSVAR_POLBUF)        ;[20C4] HL -> Polish (tokenisation) buffer
    CALL  RP                        ;[20C7] Read and tokenise numeric expression from DE -> HL
    CP    ','                       ;[20CA] Did tokeniser stop at ','?
    JR    Z,EIPT3                   ;[20CC] Yes: advance past it
    RST   $20                       ;[20CE] No: assert next byte is CR
    DB    CR                        ;[20CF] Expected CR
    DEC   DE                        ;[20D0] Step back (so next iteration sees CR again)
EIPT3:
    EXX                             ;[20D1] Swap back to variable list pointer
    LD    DE,(SYSVAR_POLBUF)        ;[20D2] DE -> start of tokenised expression
    RST   $28                       ;[20D6] Evaluate the expression -> WRA1
    POP   HL                        ;[20D7] HL = variable address
    EX    DE,HL                     ;[20D8] DE = variable address, HL = post-eval parse ptr
    CALL  WRA1_TO_DE                ;[20D9] Store WRA1 float into variable at DE
EIPT5:
    POP   DE                        ;[20DC] Restore variable list pointer
    LD    A,(DE)                    ;[20DD] Read next variable token
    CP    CR                        ;[20DE] End of variable list?
    RET   Z                         ;[20E0] Yes: done (carry clear = success)
    INC   DE                        ;[20E1] Skip separator (comma)
    JR    EIPTS                     ;[20E2] Process next variable

EIPT4:
    EXX                             ;[20E4] String variable: swap to INPBUF pointer
    POP   HL                        ;[20E5] HL = string variable address
    DEC   HL                        ;[20E6] Step back to length/type byte
    LD    B,(HL)                    ;[20E7] B = max string length from variable header
    INC   HL                        ;[20E8] HL = string data address
    CALL  RDST1                     ;[20E9] Read string from INPBUF into variable at HL
    EXX                             ;[20EC] Swap back to variable list pointer
    JR    EIPT5                     ;[20ED] Continue with next variable

;
; READ_STRING: read a string from the input at DE into the buffer at HL.
; Uses a maximum length of $10 (16) characters.  Falls through to RDST1.
;
READ_STRING:
    LD    B,$10                     ;[20EF] B = 16 (default max string length)
RDST1:
    CALL  RDSTS                     ;[20F1] Test current char: is it a delimiter?
    JR    Z,RDST3                   ;[20F4] Z: '"' or ',' found, end of string
    LD    (HL),A                    ;[20F6] Store character in buffer
    INC   HL                        ;[20F7] Advance buffer pointer
    INC   DE                        ;[20F8] Advance input pointer
    DJNZ  RDST1                     ;[20F9] Repeat up to B times (max length)
    CALL  RDSTS                     ;[20FB] B exhausted: check for delimiter
RDST2:
    JR    Z,RDST3                   ;[20FE] Z: delimiter found, done
    INC   DE                        ;[2100] Not a delimiter: skip excess character
    JR    $20FB                     ;[2101] Check again
RDST3:
    LD    (HL),SZ                   ;[2103] Terminate string with SZ ($0D = string end marker)
    RET   C                         ;[2105] Carry set by RDSTS when CR found: return
    INC   DE                        ;[2106] '"' or ',' found: advance past it
    RET                             ;[2107] 

;
; RDSTS: test the character at DE for a string delimiter.
; Returns: Z set if '"' (end of quoted string).
;          Z set if ',' (field separator) -- actually Z from CP ','.
;          Carry set, Z clear if any other character (continue reading).
; Note: CR causes SCF (carry set) to signal end of input line.
;
RDSTS:
    LD    A,(DE)                    ;[2108] Read character at DE
    CP    $22                       ;[2109] Is it '"'?
    RET   Z                         ;[210B] Yes: Z set, return (end of quoted string)
    CP    ','                       ;[210C] Is it ','?
    RET   Z                         ;[210E] Yes: Z set, return (field separator)
    CP    CR                        ;[210F] Is it CR?
    SCF                             ;[2111] Set carry (signals: end of line)
    RET                             ;[2112] Returns: carry set, Z set only if A was CR

;
; VPTR_IS_STR: determine whether the current variable at DE is a string variable
; (name ending in '$') and return its address.
; If numeric: calls GET_VAR_ADDR -> HL = variable address, carry clear.
; If string:  calls SYSVAR_VRPTS (string variable pointer routine) -> carry set.
;
VPTR_IS_STR:
    CALL  TEST_FOR_STRING           ;[2113] Z set if variable at DE is a string (name ends '$')
    JR    Z,VARP1                   ;[2116] Yes: handle as string
    CALL  GET_VAR_ADDR              ;[2118] Numeric: get variable address -> HL
    OR    A                         ;[211B] Clear carry
    RET                             ;[211C] Return carry clear (numeric variable)
VARP1:
    CALL  SYSVAR_VRPTS              ;[211D] String: call string variable pointer routine
    SCF                             ;[2120] Set carry to signal "is a string variable"
    RET                             ;[2121] 

;
; EPAUSE: PAUSE statement -- busy-wait delay.
; Evaluates the delay count into HL (RST $18), then loops HL times,
; each inner iteration taking approximately 26 T-states ($1A * ~2 T-states
; per DJNZ = ~52 T-states), giving roughly 52 * HL * 26 T-states total.
; On a 4 MHz Z80 this is approximately HL * 338 microseconds per outer loop.
;
EPAUSE:
    RST   $18                       ;[2122] Evaluate expression -> integer in HL
EPAUSE1:
    DEC   HL                        ;[2123] Decrement outer counter
    LD    B,$1A                     ;[2124] B = 26 (inner loop count)
EPAUSE2:
    DJNZ  EPAUSE2                   ;[2126] Inner busy-wait loop
    LD    A,L                       ;[2128] Test HL for zero
    OR    H                         ;[2129] 
    JR    NZ,EPAUSE1                ;[212A] Not zero: outer loop again
    RET                             ;[212C] Done

;
; EPROTECT: PROTECT statement -- stores a protection status byte.
; Evaluates the expression (RST $18) into HL; the low byte of HL (A) is
; stored in SYSVAR_PROTST.  Used to mark a program as protected/unprotected.
;
EPROTECT:
    RST   $18                       ;[212D] Evaluate expression -> integer in HL (A = low byte)
EPROT1:
    LD    (SYSVAR_PROTST),A         ;[212E] Store protection byte
    RET                             ;[2131] 

;
; ETEXT: TEXT statement -- switch to text mode.
; Clears the protection status, then sends a sequence of VDU codes to the
; display driver to initialise text mode on the Lynx:
;   VDU 1  = set mode (hardware-specific init)
;   VDU 4  = clear screen
;   VDU 2  = set character size / mode
;   VDU 0  = (mode parameter byte)
;   VDU 4  = clear screen again
; Finally stores $03 in SYSVAR_PROTST (TEXT protection state).
;
ETEXT:
    XOR   A                         ;[2132] A = 0
    LD    (SYSVAR_PROTST),A         ;[2133] Clear protection status
    LD    A,$01                     ;[2136] VDU 1 (mode init)
    RST   $08                       ;[2138] Send it
    LD    A,$04                     ;[2139] VDU 4 (clear screen)
    RST   $08                       ;[213B] 
    LD    A,$02                     ;[213C] VDU 2 (character size)
    RST   $08                       ;[213E] 
    XOR   A                         ;[213F] VDU 0 (mode parameter)
    RST   $08                       ;[2140] 
    LD    A,$04                     ;[2141] VDU 4 (clear screen)
    RST   $08                       ;[2143] 
    LD    A,$03                     ;[2144] A = $03 (TEXT protection state)
    JR    EPROT1                    ;[2146] Store in SYSVAR_PROTST

;
; ELET: LET statement (and implicit assignment) -- evaluate expression and
; assign to one or more variables.
; Handles both numeric and string variables.  For numeric variables, evaluates
; the expression with RST $28, then calls WRA1_TO_DE to store WRA1 into the
; variable's 5-byte float slot.  For string variables, calls STRING_EXEC to
; evaluate the string expression and copies the result.
; Multiple assignments separated by commas are handled by looping.
;
ELET:
    CALL  TEST_FOR_STRING           ;[2148] Is current variable a string (name ends '$')?
    JR    Z,ELET1                   ;[214B] Yes: string assignment
    CALL  GET_VAR_ADDR              ;[214D] Numeric: get variable address -> HL
    INC   DE                        ;[2150] Skip '=' separator
    PUSH  HL                        ;[2151] Save variable address
    RST   $28                       ;[2152] Evaluate numeric expression -> WRA1
    POP   HL                        ;[2153] HL = variable address
    EX    DE,HL                     ;[2154] DE = variable address
    PUSH  HL                        ;[2155] Save post-expression parse pointer
    CALL  WRA1_TO_DE                ;[2156] Store WRA1 into variable at DE
    POP   DE                        ;[2159] Restore parse pointer
ELET7:
    LD    A,(DE)                    ;[215A] Read next token
    CP    CR                        ;[215B] End of statement?
    RET   Z                         ;[215D] Yes: done
    INC   DE                        ;[215E] Skip separator (comma)
    JR    ELET                      ;[215F] Assign next variable

ELET1:
    LD    IY,SYSVAR_CSTACK          ;[2161] IY -> calculator stack (for string eval)
    CALL  SYSVAR_VRPTS              ;[2165] Get string variable pointer -> HL/BC
    INC   DE                        ;[2168] Skip '='
    PUSH  HL                        ;[2169] Save string variable address
    PUSH  BC                        ;[216A] Save string info
    CALL  STRING_EXEC               ;[216B] Evaluate string expression -> SYSVAR_STRBUF
    POP   BC                        ;[216E] Restore string info
    POP   IX                        ;[216F] IX = string variable address
    LD    HL,SYSVAR_STRBUF          ;[2171] HL -> evaluated string result
ELET2:
    CALL  STRING_SEEK_END           ;[2174] Find end of string in STRBUF -> HL at terminator
ELET3:
    LD    (IX+$00),SZ               ;[2177] Write SZ ($0D) terminator into variable
    JR    ELET7                     ;[217B] Check for more assignments

;
; ERESTORE: RESTORE statement -- reset the DATA pointer.
; With no argument (CR follows): resets DATAP to one byte before SOB
; (so the next READ will find the first DATA statement).
; With a line number argument: evaluates it, finds the line, and sets
; DATAP to one byte before that line.
;
ERESTORE:
    CP    CR                        ;[217D] No argument?
    LD    IX,(SYSVAR_SOB)           ;[217F] IX = start of BASIC (default restore point)
    JR    Z,ERESTORE1               ;[2183] Yes: use SOB
    RST   $28                       ;[2185] Evaluate line number -> WRA1
    CALL  FINDLN                    ;[2186] Find the line -> IX
ERESTORE1:
    DEC   IX                        ;[2189] IX = one byte before the target line
    LD    (SYSVAR_DATAP),IX         ;[218B] Update DATA pointer
    RET                             ;[218F] 

;
; FTL: scan forward through the BASIC program looking for a statement whose
; command token (at IX+6) matches the token in C.
; IX must point to the current BASIC line; it is advanced via NEXT_LINE.
; Returns: carry clear if found (IX -> matching line), carry set if end of
; program ($80 in first byte) reached without a match.
;
FTL:
    LD    A,(IX+$00)                ;[2190] Read first byte of current line
    CP    $80                       ;[2193] End-of-program marker?
    SCF                             ;[2195] Set carry (not found)
    RET   Z                         ;[2196] Yes: return carry set (not found)
    LD    A,(IX+$06)                ;[2197] Read command token of this line (offset 6)
    CP    C                         ;[219A] Does it match the target token?
    RET   Z                         ;[219B] Yes: return carry clear (found), IX -> this line
    CALL  NEXT_LINE                 ;[219C] Advance IX to next BASIC line
    JR    FTL                       ;[219F] Try again

;
; SUB_WHILE: scan forward through BASIC lines looking for a matching WEND (C)
; while correctly handling nested WHILE (B) / WEND pairs.
; Uses A' as a nesting depth counter (starts at $FF = -1; increments on WHILE,
; decrements on WEND; when $FF again, the matching WEND has been found).
; IX is advanced by NEXT_LINE.  Returns carry set if end of program reached.
;
SUB_WHILE:
    LD    A,$FF                     ;[21A1] Initial nesting depth = -1 (to be incremented to 0)
    EX    AF,AF'                    ;[21A3] Save in A'
FTLD1:
    LD    A,(IX+$00)                ;[21A4] Read first byte of current line
    CP    $80                       ;[21A7] End-of-program?
    SCF                             ;[21A9] Set carry
    RET   Z                         ;[21AA] Yes: not found, return carry set
    LD    A,(IX+$06)                ;[21AB] Read command token
    CP    B                         ;[21AE] Is it WHILE (B = $36)?
    JR    Z,FTLD3                   ;[21AF] Yes: increase nesting depth
    CP    C                         ;[21B1] Is it WEND (C = $37)?
    JR    Z,FTLD4                   ;[21B2] Yes: decrease nesting depth
FTLD2:
    CALL  NEXT_LINE                 ;[21B4] Advance to next line
    JR    FTLD1                     ;[21B7] Check next line
FTLD4:
    EX    AF,AF'                    ;[21B9] Retrieve nesting depth
    OR    A                         ;[21BA] Is it zero? (found the matching WEND)
    RET   Z                         ;[21BB] Yes: return carry clear (found), IX -> WEND line
    DEC   A                         ;[21BC] Decrease nesting (one WEND consumed)
    EX    AF,AF'                    ;[21BD] Save updated depth
    JR    FTLD2                     ;[21BE] Continue scanning
FTLD3:
    EX    AF,AF'                    ;[21C0] Retrieve nesting depth
    INC   A                         ;[21C1] Increase nesting (one WHILE seen)
    EX    AF,AF'                    ;[21C2] Save updated depth
    JR    FTLD2                     ;[21C3] Continue scanning

;
; EREAD: READ statement -- reads values from DATA statements into variables.
; Uses SYSVAR_DATAP as the current position within DATA statements (in the
; alternate DE register, DE').  Calls EIPTS to assign values to the listed
; variables.  If the current DATA statement is exhausted (EIPTS returns carry),
; searches for the next DATA statement with FTL and advances DATAP into it.
; Updates SYSVAR_DATAP after each successful read.
;
EREAD:
    EXX                             ;[21C5] Swap to alternate registers
    LD    DE,(SYSVAR_DATAP)         ;[21C6] DE' = current DATA read pointer
    EXX                             ;[21CA] Swap back (DE' holds DATAP)
ERD1:
    CALL  EIPTS                     ;[21CB] Parse and assign next value from DE' -> variables at DE
    JR    C,ERD2                    ;[21CE] Carry: current DATA exhausted, find next DATA line
    EXX                             ;[21D0] Swap to alternate registers
    LD    (SYSVAR_DATAP),DE         ;[21D1] Update DATAP to current position in DATA
    RET                             ;[21D5] Done

ERD2:
    EXX                             ;[21D6] Swap to alternate registers (DE' = DATAP)
    INC   DE                        ;[21D7] Advance past end of current DATA line
    PUSH  DE                        ;[21D8] Save updated pointer
    POP   IX                        ;[21D9] IX = current search position
    LD    C,DATA                    ;[21DB] C = DATA token ($19) = token to search for
    CALL  FTL                       ;[21DD] Scan forward for next DATA statement -> IX
    CALL  C,ERR_OUT_OF_DATA         ;[21E0] Carry: no more DATA, error
    CALL  SKIP_LNUM                 ;[21E3] Skip line header (line number bytes)
    INC   DE                        ;[21E6] Skip DATA token itself
    EXX                             ;[21E7] Swap back
    JR    ERD1                      ;[21E8] Try assigning from the new DATA line

;
; TEST_FOR_STRING: test whether the variable at DE is a string variable.
; A string variable has a name consisting of a letter ('A'-'Z') followed
; immediately by '$'.
; Returns: Z set if it IS a string variable (name byte at DE+1 is '$').
;          Z clear (carry set if < 'A') if it is not a string variable.
; DE is not modified.
;
TEST_FOR_STRING:
    LD    A,(DE)                    ;[21EA] Read variable name byte at DE
    CP    'A'                       ;[21EB] Is it below 'A'? (not a variable letter)
    RET   C                         ;[21ED] Yes: return carry set, not a string
    INC   DE                        ;[21EE] Temporarily advance to check next byte
    LD    A,(DE)                    ;[21EF] Read the byte after the variable name
    CP    '$'                       ;[21F0] Is it '$'? (string variable suffix)
    DEC   DE                        ;[21F2] Restore DE
    RET                             ;[21F3] Returns: Z set if '$' found (string variable)

;
; READ_STRING_VAR: read a string variable name from the token stream at DE
; and write it (as "X$" or "X$(") into the buffer at HL.
; Validates that DE points to an uppercase letter A-Z; errors if not.
; Also handles string array references: if '(' follows '$', copies the
; subscript expression (via RP) into the buffer.
;
READ_STRING_VAR:
    LD    A,(DE)                    ;[21F4] Read variable name character
    CP    'A'                       ;[21F5] Is it a valid uppercase letter?
    CALL  C,ERR_SYNTAX              ;[21F7] No (below 'A'): syntax error
    CP    'Z'+1                     ;[21FA] Above 'Z'?
    CALL  NC,ERR_SYNTAX             ;[21FC] Yes: syntax error
RDSV1:
    LD    (HL),A                    ;[21FF] Store variable letter in buffer
    INC   HL                        ;[2200] 
    LD    (HL),'$'                  ;[2201] Store '$' suffix
    INC   HL                        ;[2203] 
    INC   DE                        ;[2204] Advance past variable letter
    INC   DE                        ;[2205] Advance past '$' in source
DMSR:
    RST   $10                       ;[2206] Skip spaces in source
    CP    '('                       ;[2207] Is next char '('? (array subscript)
    RET   NZ                        ;[2209] No: plain string variable, done
    LD    (HL),A                    ;[220A] Store '(' in buffer
    INC   HL                        ;[220B] 
    INC   DE                        ;[220C] Advance past '('
    CALL  RP                        ;[220D] Read and tokenise subscript expression into HL
    CP    ')'                       ;[2210] Next char should be ')'
    CALL  NZ,ERR_MISSING_BRACKET    ;[2212] Not ')': error
    LD    (HL),A                    ;[2215] Store ')' in buffer
    INC   HL                        ;[2216] 
    RET                             ;[2217] 

;
; GET_VAR_ADDR: given a numeric variable token at DE, return a pointer to
; its 5-byte storage slot in the variable table (SYSVAR_VTBL).
; Calls TEST_UPPER_LOW to convert the letter to a 1-based index (A=1..Z=26,
; a=27..z=52), then computes: HL = VTBL + index * 5.
; If the next byte after the variable letter is '(' it's an array reference,
; and VPTA is called instead.
;
GET_VAR_ADDR:
    CALL  TEST_UPPER_LOW            ;[2218] A = variable index (1-based: A=1, Z=26, a=27...)
    INC   DE                        ;[221B] Advance past variable letter
    PUSH  AF                        ;[221C] Save index
    LD    A,(DE)                    ;[221D] Read next token
    CP    '('                       ;[221E] Is it '('? (array subscript)
    JP    Z,VPTA                    ;[2220] Yes: array access, call VPTA
    POP   AF                        ;[2223] No: restore index
VTPTR:
    LD    L,A                       ;[2224] HL = index
    LD    H,$00                     ;[2225] 
    PUSH  DE                        ;[2227] Save DE
    LD    E,L                       ;[2228] DE = index (copy for multiply)
    LD    D,H                       ;[2229] 
    ADD   HL,HL                     ;[222A] HL = index * 2
    ADD   HL,HL                     ;[222B] HL = index * 4
    ADD   HL,DE                     ;[222C] HL = index * 5
    LD    DE,(SYSVAR_VTBL)          ;[222D] DE = variable table base address
    ADD   HL,DE                     ;[2231] HL = VTBL + index*5 = variable slot address
    POP   DE                        ;[2232] Restore DE
    RET                             ;[2233] HL -> 5-byte variable slot

;
; PHEXHL: print HL as a 4-digit hexadecimal number (no prefix).
; Calls PRINT_HEX_A for the high byte, then falls through for the low byte.
;
PHEXHL:
    LD    A,H                       ;[2234] A = high byte
    CALL  PRINT_HEX_A               ;[2235] Print high byte as 2 hex digits
    LD    A,L                       ;[2238] A = low byte
PRINT_HEX_A:
    PUSH  AF                        ;[2239] Save low nibble for second digit
    RRCA                            ;[223A] Shift high nibble down
    RRCA                            ;[223B] 
    RRCA                            ;[223C] 
    RRCA                            ;[223D] A = high nibble of byte
    CALL  PHEXHL2                   ;[223E] Print high nibble as hex digit
    POP   AF                        ;[2241] Restore original byte (low nibble)
PHEXHL2:
    AND   $0F                       ;[2242] Isolate low nibble
    ADD   A,$30                     ;[2244] Add '0' ($30) -> '0'..'9' for digits 0-9
    CP    $3A                       ;[2246] Is it above '9'?
    JR    C,PHEXHL_OUTB             ;[2248] No: it's a decimal digit, print it
    ADD   A,$07                     ;[224A] Yes: adjust to 'A'..'F' ($41..$46)
PHEXHL_OUTB:
    RST   $08                       ;[224C] Print the hex character
    RET                             ;[224D] 

;
; ELPRINT: LPRINT statement -- like PRINT but sends output to the LINK
; (printer) port.  Enables LINK output, calls EPRINT, then disables LINK.
;
ELPRINT:
    CALL  SUB_LINK_ON               ;[224E] Enable LINK (printer) output
    CALL  EPRINT                    ;[2251] Execute PRINT (output goes to printer via LINK)
    JP    SUB_LINK_OFF              ;[2254] Disable LINK and return

;
; PRINT_STRING: print a quoted string literal from the token stream at DE.
; DE must point to the opening '"'; the routine advances past it, prints
; each character until the closing '"' is found, then returns.
; DE points to the closing '"' on return.
;
PRINT_STRING:
    INC   DE                        ;[2257] Advance past opening '"'
    LD    A,(DE)                    ;[2258] Read next character
    CP    $22                       ;[2259] Is it the closing '"'?
    RET   Z                         ;[225B] Yes: done
    RST   $08                       ;[225C] No: print the character
    JR    PRINT_STRING              ;[225D] Loop for next character

;
; ESWAP: SWAP statement -- swap the 5-byte float values of two numeric variables.
; Gets the address of the first variable, advances DE past the separator,
; gets the address of the second variable, then calls SWAP1 to exchange
; 5 bytes between the two addresses.
;
ESWAP:
    CALL  GET_VAR_ADDR              ;[225F] HL = address of first variable
    PUSH  HL                        ;[2262] Save it
    INC   DE                        ;[2263] Skip separator (comma)
    CALL  GET_VAR_ADDR              ;[2264] HL = address of second variable
    POP   DE                        ;[2267] DE = address of first variable
    LD    B,$05                     ;[2268] B = 5 (bytes per float variable)
    JP    SWAP1                     ;[226A] Swap B bytes between HL and DE

;
; ECONT: CONT statement -- continue execution from where it was stopped.
; If CURRLP is not $80 (not at command line), does nothing (program is still
; running).  Otherwise checks CONTLP; if zero, cannot continue (error).
; If CONTLP is valid, jumps directly to EXEC_BASIC to resume at that line.
;
ECONT:
    LD    HL,(SYSVAR_CURRLP)        ;[226D] HL = current-line pointer
    LD    A,(HL)                    ;[2270] Read first byte
    CP    $80                       ;[2271] Is it $80 (program not running)?
    RET   NZ                        ;[2273] No: program is running, CONT is a no-op
    POP   BC                        ;[2274] Discard return address (we jump directly)
    LD    HL,(SYSVAR_CONTLP)        ;[2275] HL = CONT (continue) line pointer
    LD    A,L                       ;[2278] Test for zero (cannot continue)
    OR    H                         ;[2279] 
    CALL  Z,ERR_CANNOT_CONT         ;[227A] Zero: cannot continue, error
    JP    EXEC_BASIC                ;[227D] Resume execution at CONTLP

;
; ERUN: RUN statement -- start or restart program execution.
; Calls ZERO_MEM to initialise runtime state (clears variables etc.).
; With no argument (CR): runs from the first line (SOB).
; With a line number argument: evaluates it and calls FINDLN to locate it,
; then starts execution from that line.
;
ERUN:
    PUSH  DE                        ;[2280] Save parse pointer
    CALL  ZERO_MEM                  ;[2281] Initialise runtime state
    POP   DE                        ;[2284] Restore parse pointer
    LD    IX,(SYSVAR_SOB)           ;[2285] IX = start of BASIC program
    LD    A,(DE)                    ;[2289] Read next token
    CP    CR                        ;[228A] No argument?
    JR    Z,EGT1                    ;[228C] Yes: run from first line
EGT2:
    RST   $28                       ;[228E] Evaluate line number -> WRA1
    CALL  FINDLN                    ;[228F] Find the line -> IX
EGT1:
    POP   BC                        ;[2292] Discard current Z80 return address
    JP    EXEC5                     ;[2293] Start execution at IX

;
; EGOSUB: GOSUB statement -- call a BASIC subroutine.
; Pushes the current line pointer and a GOSUB marker ($11) onto the return
; stack so RETURN can find its way back.  Then falls through to EGOTO to
; jump to the target line or label.
;
EGOSUB:
    LD    HL,(SYSVAR_CURRLP)        ;[2296] HL = current line pointer (return address)
    CALL  PUSH_HL_RSTACK            ;[2299] Push line pointer for RETURN
    LD    A,GOSUB                   ;[229C] A = GOSUB token ($11)
    CALL  PUSH_A_RSTACK             ;[229E] Push frame type marker
    LD    A,(DE)                    ;[22A1] 

;
; EGOTO: GOTO statement (and GOSUB target jump).
; If followed by OLABEL token ($D8), searches for a matching LABEL statement
; by name comparison.  Otherwise evaluates the line number and jumps to FINDLN.
;
EGOTO:
    CP    OLABEL                    ;[22A2] Is next token OLABEL ($D8)?  (GOTO @label)
    JR    NZ,EGT2                   ;[22A4] No: numeric line number, go to FINDLN path
    LD    C,LABEL                   ;[22A6] C = LABEL token ($2F) = statement to search for
    INC   DE                        ;[22A8] Skip OLABEL token
    LD    IX,(SYSVAR_SOB)           ;[22A9] IX = start of program (search from beginning)
EGT3:
    PUSH  DE                        ;[22AD] Save label name pointer
    CALL  FTL                       ;[22AE] Find next LABEL statement -> IX
    CALL  C,ERR_NOT_FOUND           ;[22B1] Carry: no more LABELs, label not found error
    PUSH  IX                        ;[22B4] Save IX (pointer to LABEL line)
    LD    DE,7                      ;[22B6] DE = 7 (offset to label name in line)
    ADD   IX,DE                     ;[22B9] IX -> label name in the LABEL statement
    PUSH  IX                        ;[22BB] Push pointer to label name in program
    POP   HL                        ;[22BD] HL = pointer to label name in program
    POP   IX                        ;[22BE] Restore IX to LABEL line base
    POP   DE                        ;[22C0] Restore label name pointer (from GOTO @name)
    PUSH  DE                        ;[22C1] Save it again (for possible next iteration)
    CALL  STRING_CMP                ;[22C2] Compare label name at DE with program label at HL
    JR    Z,EGT4                    ;[22C5] Z: names match, jump to this line
    CALL  NEXT_LINE                 ;[22C7] No match: advance IX to next line
    POP   DE                        ;[22CA] Restore label name pointer
    JR    NZ,EGT3                   ;[22CB] NZ: keep searching (Z would mean end of program)
EGT4:
    POP   BC                        ;[22CD] Discard saved label pointer
    LD    (SYSVAR_CURRLP),IX        ;[22CE] Set CURRLP to the found LABEL line
    RET                             ;[22D2] Return (execution will continue from CURRLP)


;
; STRING_CMP: compare two strings for equality.
; DE points to the first string; HL points to the second.
; Characters are compared one by one until a mismatch, '(' (array subscript
; delimiter), or CR (end of name) is found.
; Returns: Z set if strings match up to the delimiter, NZ if they differ.
;
STRING_CMP:
    LD    A,(DE)                    ;[22D3] Read character from first string
    CP    (HL)                      ;[22D4] Compare with second string character
    RET   NZ                        ;[22D5] Mismatch: return NZ
    CP    '('                       ;[22D6] Is it '('? (end of name, start of subscript)
    RET   Z                         ;[22D8] Yes: strings matched up to '(', return Z
    CP    CR                        ;[22D9] Is it CR? (end of name)
    RET   Z                         ;[22DB] Yes: strings matched to end, return Z
    INC   HL                        ;[22DC] Advance both pointers
    INC   DE                        ;[22DD] 
    JR    STRING_CMP                ;[22DE] Compare next character

;
; ELIST2: LIST with no arguments -- list entire program.
; Sets IX to start of BASIC, DE to $FFFF (no end limit), then falls into ELIST1.
;
ELIST2:
    LD    IX,(SYSVAR_SOB)           ;[22E0] IX -> first line of program
    LD    DE,$FFFF                  ;[22E4] DE = $FFFF (no upper limit on line numbers)
    JR    ELIST1                    ;[22E7] Enter listing loop

;
; ELIST: LIST [start[,end]] -- list BASIC program lines.
; With no argument (CR): lists the whole program via ELIST2.
; With one argument: evaluates start line, finds it, lists from there to end.
; With two arguments (comma-separated): evaluates both, lists the range.
; SYSVAR_SBC is cleared to 0 before listing (no indentation).
;
ELIST:
    CP    CR                        ;[22E9] No argument?
    LD    A,0                       ;[22EB] A = 0
    LD    (SYSVAR_SBC),A            ;[22ED] Clear indentation flag
    JR    Z,ELIST2                  ;[22F0] No argument: list all
    RST   $28                       ;[22F2] Evaluate start line number -> WRA1
    PUSH  DE                        ;[22F3] Save parse pointer
    CALL  FNDLN_WRA1                ;[22F4] Find start line -> IX
    POP   DE                        ;[22F7] Restore parse pointer
    LD    A,(DE)                    ;[22F8] Read next character
    CP    CR                        ;[22F9] Is it CR? (no end argument)
    PUSH  IX                        ;[22FB] Save start line pointer
    JR    Z,ELIST3                  ;[22FD] Yes: list from start to end of program
    INC   DE                        ;[22FF] Skip comma separator
    RST   $28                       ;[2300] Evaluate end line number -> WRA1
    CALL  FNDLN_WRA1                ;[2301] Find end line -> IX
ELIST3:
    PUSH  IX                        ;[2304] Push end line pointer
    POP   DE                        ;[2306] DE = end line pointer
    POP   IX                        ;[2307] IX = start line pointer
    INC   DE                        ;[2309] DE = one past end line (exclusive upper bound)
ELIST1:
    LD    A,(IX+$00)                ;[230A] Read first byte of current line
    CP    $80                       ;[230D] End-of-program marker?
    JR    Z,ELIST4                  ;[230F] Yes: done listing
    PUSH  DE                        ;[2311] Save end-line pointer
    CALL  SYSVAR_DBASLN             ;[2312] Display current BASIC line (via hook)
    LD    (SYSVAR_CURRLP),IX        ;[2315] Update CURRLP to current line (for ESC check)
ELIST9:
    CALL  ESC                       ;[2319] Is ESC pressed?
    JR    Z,ELIST4                  ;[231C] Yes: abort listing
    LD    BC,PORT                   ;[231E] BC = keyboard port ($0080)
    IN    A,(C)                     ;[2321] Read keyboard hardware
    RLCA                            ;[2323] Rotate bit 7 into carry (BREAK/SPACE key)
    JR    NC,ELIST9                 ;[2324] Carry clear (bit 7 = 0): key held, pause
    CALL  NEXT_LINE                 ;[2326] Advance IX to next line
    POP   DE                        ;[2329] Restore end-line pointer
    PUSH  IX                        ;[232A] IX = current line pointer
    POP   HL                        ;[232C] HL = current line pointer
    CALL  CHLDE                     ;[232D] Compare HL (current) with DE (end limit)
    JR    C,ELIST1                  ;[2330] Current < end: list next line
ELIST4:
    LD    A,CEL                     ;[2332] VDU 30 = clear to end of line
    RST   $08                       ;[2334] Send it
    JP    TO_CMDLINE                ;[2335] Return to command line

;
; ELLIST: LLIST -- list BASIC program to printer (LINK output).
; Enables LINK, then falls directly into ELIST with the current DE (argument).
;
ELLIST:
    CALL  SUB_LINK_ON               ;[2338] Enable LINK (printer) output
    LD    A,(DE)                    ;[233B] Re-read argument byte (ELIST expects it in A)
    JP    ELIST                     ;[233C] Execute LIST with LINK active

;
; EDEL: DEL start[,end] -- delete a range of BASIC lines.
; Evaluates the start line number, finds it.  If a second argument follows
; (comma), evaluates the end line and finds it too.  Computes the number of
; bytes to delete (negative HL = shrink), calls INSERT to close the gap,
; then returns to the command line.
;
EDEL:
    RST   $28                       ;[233F] Evaluate start line -> WRA1
    PUSH  DE                        ;[2340] Save parse pointer
    CALL  FINDLN                    ;[2341] Find start line -> IX
    POP   DE                        ;[2344] Restore parse pointer
    LD    A,(DE)                    ;[2345] Read next character
    CP    $0D                       ;[2346] Is it CR? (no end argument)
    INC   DE                        ;[2348] Advance past separator (speculative)
    PUSH  IX                        ;[2349] Save start line pointer
    JR    Z,EDEL1                   ;[234B] CR: delete only the start line
    RST   $28                       ;[234D] Evaluate end line -> WRA1
    CALL  FINDLN                    ;[234E] Find end line -> IX
EDEL1:
    CALL  NEXT_LINE                 ;[2351] IX -> first line after deleted range
    PUSH  IX                        ;[2354] Push first-line-after pointer
    POP   BC                        ;[2356] BC = first line after range
    POP   HL                        ;[2357] HL = start of range (first line to delete)
    LD    E,L                       ;[2358] DE = start of range
    LD    D,H                       ;[2359] 
    OR    A                         ;[235A] Clear carry
    SBC   HL,BC                     ;[235B] HL = start - (start + length) = -(length)
    CALL  INSERT                    ;[235D] INSERT with negative HL removes bytes at DE
    JP    EXEC_EXIT                 ;[2360] Return to command line

;
; EINT: evaluate an integer expression and return its low byte in A.
; If the result is negative (bit 7 of WRA1 exponent clear in Lynx float format),
; adds 65536 first (ADD64K) to handle two's-complement interpretation of
; 16-bit values in the range $8000-$FFFF returned as negative floats.
;
EINT:
    RST   $28                       ;[2363] Evaluate expression -> WRA1
    LD    A,(SYSVAR_WRA1)           ;[2364] Read exponent byte
    BIT   7,A                       ;[2367] Is bit 7 set? (positive in Lynx float format)
    CALL  Z,ADD64K                  ;[2369] No (negative): add 65536 to get unsigned value
    CALL  FPINT                     ;[236C] Convert WRA1 float to integer -> HL
    LD    A,L                       ;[236F] A = low byte of integer result
    RET                             ;[2370] 

;
; ADD64K: add 65536.0 to WRA1.
; Used to convert a negative 16-bit float result to an unsigned value
; (e.g. -1.0 -> 65535.0).
;
ADD64K:
    PUSH  DE                        ;[2371] Save DE
    LD    HL,FLOAT_64k              ;[2372] HL -> floating-point constant 65536.0
    CALL  LNUM2                     ;[2375] Load 65536.0 into WRA2
    CALL  ADD                       ;[2378] WRA1 = WRA1 + WRA2 (= WRA1 + 65536)
    POP   DE                        ;[237B] Restore DE
    RET                             ;[237C] 

;
; EOUT: OUT port, value -- write a byte to a Z80 I/O port.
; Evaluates the port number (RST $18 -> HL), then the value byte (RST $18 -> A).
; Issues OUT (C), A with the port in BC (low byte = port number from L).
;
EOUT:
    RST   $18                       ;[237D] Evaluate port expression -> integer in HL (A=L)
    PUSH  HL                        ;[237E] Save port number
    INC   DE                        ;[237F] Skip comma separator
    RST   $18                       ;[2380] Evaluate value expression -> integer in HL (A=L)
    POP   BC                        ;[2381] BC = port number (C = low byte = port)
    OUT   (C),A                     ;[2382] Write A to I/O port C
    RET                             ;[2384] 

;
; EPOKE: POKE address, value -- write a byte to a memory address.
; Evaluates the address (RST $18 -> HL), then the byte value (RST $18 -> A).
; Stores A at (HL).
;
EPOKE:
    RST   $18                       ;[2385] Evaluate address -> integer in HL
    PUSH  HL                        ;[2386] Save address
    INC   DE                        ;[2387] Skip comma separator
    RST   $18                       ;[2388] Evaluate value -> integer in HL (A = L)
    POP   HL                        ;[2389] HL = address
    LD    (HL),A                    ;[238A] Write byte to memory
    RET                             ;[238B] 

;
; EDPOKE: DPOKE address, value -- write a 16-bit word to a memory address.
; Evaluates the address (RST $18 -> HL), then the 16-bit value (RST $18 -> HL).
; Stores the word little-endian at the address.
;
EDPOKE:
    RST   $18                       ;[238C] Evaluate address -> integer in HL
    PUSH  HL                        ;[238D] Save address
    INC   DE                        ;[238E] Skip comma separator
    RST   $18                       ;[238F] Evaluate value -> integer in HL
    LD    C,L                       ;[2390] BC = value to store (little-endian)
    LD    B,H                       ;[2391] 
    POP   HL                        ;[2392] HL = address
    LD    (HL),C                    ;[2393] Store low byte
    INC   HL                        ;[2394] 
    LD    (HL),B                    ;[2395] Store high byte
    RET                             ;[2396] 

;
; EFOR: FOR var = start TO limit [STEP step] -- FOR loop initialisation.
; Pushes the current line pointer and a FOR frame onto the return stack.
; Frame layout on return stack (top to bottom after setup):
;   FOR token ($0F)      <- top
;   variable token byte
;   5 bytes: step value  (WRA1 float, pushed byte by byte)
;   5 bytes: limit value (WRA1 float, pushed byte by byte)
;   saved line pointer   (2 bytes, for NEXT to return to)
;
EFOR:
    PUSH  AF                        ;[2397] Save variable token (in A from EXEC dispatch)
    CALL  GET_VAR_ADDR              ;[2398] HL = address of loop variable
    PUSH  HL                        ;[239B] Save variable address
    LD    HL,(SYSVAR_CURRLP)        ;[239C] HL = current line pointer
    CALL  PUSH_HL_RSTACK            ;[239F] Push current line pointer (NEXT returns here)
    INC   DE                        ;[23A2] Skip '=' token
    RST   $28                       ;[23A3] Evaluate start value -> WRA1
    POP   HL                        ;[23A4] HL = variable address
    PUSH  DE                        ;[23A5] Save parse pointer
    INC   HL                        ;[23A6] HL -> type byte of variable
    RES   7,(HL)                    ;[23A7] Clear bit 7 of type byte (mark variable as defined)
    DEC   HL                        ;[23A9] HL -> variable base
    EX    DE,HL                     ;[23AA] DE = variable address
    CALL  WRA1_TO_DE                ;[23AB] Store start value into loop variable
    POP   DE                        ;[23AE] Restore parse pointer
    INC   DE                        ;[23AF] Skip TO token
    RST   $28                       ;[23B0] Evaluate limit value -> WRA1
    CALL  EFORS                     ;[23B1] Push 5 bytes of WRA1 (limit) onto return stack
    LD    A,(DE)                    ;[23B4] Read next token
    CP    $0D                       ;[23B5] Is it CR? (no STEP clause)
    JR    Z,EFOR2                   ;[23B7] Yes: use default step of 1
    INC   DE                        ;[23B9] Skip STEP token
    RST   $28                       ;[23BA] Evaluate step value -> WRA1
EFOR1:
    CALL  EFORS                     ;[23BB] Push 5 bytes of WRA1 (step) onto return stack
    POP   AF                        ;[23BE] Restore variable token
    CALL  PUSH_A_RSTACK             ;[23BF] Push variable token byte
    LD    A,$0F                     ;[23C2] A = FOR frame marker ($0F)
    JP    PUSH_A_RSTACK             ;[23C4] Push FOR marker and return

EFOR2:
    CALL  LONE                      ;[23C7] Load 1.0 into WRA1 (default step)
    JR    EFOR1                     ;[23CA] Push step and complete frame

;
; EFORS: push the 5-byte float in WRA1 onto the BASIC return stack.
; Pushes bytes from WRA1+0 through WRA1+4 individually via PUSH_A_RSTACK.
; DE is preserved across this call.
;
EFORS:
    PUSH  DE                        ;[23CC] Save DE
    LD    B,$05                     ;[23CD] B = 5 (bytes in a float)
    LD    DE,SYSVAR_WRA1            ;[23CF] DE -> WRA1 base
EFOR3:
    LD    A,(DE)                    ;[23D2] Read one byte of WRA1
    CALL  PUSH_A_RSTACK             ;[23D3] Push it onto return stack
    INC   DE                        ;[23D6] Advance to next byte
    DJNZ  EFOR3                     ;[23D7] Repeat 5 times
    POP   DE                        ;[23D9] Restore DE
    RET                             ;[23DA] 

;
; ENEXT: NEXT [var] -- end of FOR loop.
; Checks the return stack frame type ($0F) and variable token match.
; Pops the step and limit values from the return stack into WRA2.
; Adds step to the loop variable; if the variable is still within the limit,
; loops back by restoring CURRLP to the FOR line.  Otherwise exits the loop
; by popping the return stack frame.
;
ENEXT:
    LD    HL,(SYSVAR_RSP)           ;[23DB] HL = current return stack pointer
    DEC   HL                        ;[23DE] Point to FOR frame marker byte
    LD    A,(HL)                    ;[23DF] Read frame marker
    CP    $0F                       ;[23E0] Is it $0F (FOR frame)?
    CALL  NZ,ERR_NEXT_NO_FOR        ;[23E2] No: NEXT without FOR
    DEC   HL                        ;[23E5] Point to variable token byte
    LD    A,(DE)                    ;[23E6] Read NEXT variable token from program
    CP    (HL)                      ;[23E7] Does it match the FOR variable?
    CALL  NZ,ERR_NEXT_NO_FOR        ;[23E8] No: variable mismatch
    DEC   HL                        ;[23EB] HL now points into the step value on stack
    PUSH  DE                        ;[23EC] Save parse pointer
    CALL  ENXTS                     ;[23ED] Pop 5-byte step value from stack into WRA2; HL updated
    POP   DE                        ;[23F0] Restore parse pointer
    LD    A,(SYSVAR_WRA2)           ;[23F1] Read WRA2 exponent (sign of step)
    PUSH  AF                        ;[23F4] Save step sign
    PUSH  HL                        ;[23F5] Save stack pointer (pointing at limit value)
    CALL  GET_VAR_ADDR              ;[23F6] HL = address of loop variable
    PUSH  HL                        ;[23F9] Save variable address
    CALL  LNUM1                     ;[23FA] Load loop variable value into WRA1
    CALL  ADD                       ;[23FD] WRA1 = variable + step (WRA2)
    POP   HL                        ;[2400] HL = variable address
    EX    DE,HL                     ;[2401] DE = variable address
    CALL  WRA1_TO_DE                ;[2402] Store incremented value back into variable
    POP   HL                        ;[2405] HL = stack pointer (at limit value)
    CALL  ENXTS                     ;[2406] Pop 5-byte limit value from stack into WRA2; HL updated
    POP   AF                        ;[2409] Restore step sign (WRA2 exponent)
    BIT   7,A                       ;[240A] Is bit 7 set? (positive step in Lynx float)
    PUSH  HL                        ;[240C] Save updated stack pointer
    CALL  Z,SWAP                    ;[240D] Negative step: swap WRA1/WRA2 for correct comparison
    CALL  CMP                       ;[2410] Compare WRA1 (variable) with WRA2 (limit)
    POP   HL                        ;[2413] Restore stack pointer
    JR    C,ENXT1                   ;[2414] Carry: variable > limit (loop finished)
    LD    A,(HL)                    ;[2416] Read high byte of saved line pointer
    DEC   HL                        ;[2417] 
    LD    L,(HL)                    ;[2418] L = low byte of saved line pointer
    LD    H,A                       ;[2419] H = high byte
    LD    (SYSVAR_CURRLP),HL        ;[241A] Restore CURRLP to FOR line (loop back)
    RET                             ;[241D] 

ENXT1:
    DEC   HL                        ;[241E] Move past the line pointer on the stack
    LD    (SYSVAR_RSP),HL           ;[241F] Update RSP to pop entire FOR frame
    RET                             ;[2422] Exit loop (continue after NEXT)

;
; ENXTS: pop 5 bytes from the BASIC return stack into WRA2 (big-endian, stored
; highest address first).  Uses LDDR to copy from the stack into WRA2.
; HL is decremented past the 5 bytes popped and the RSP is updated implicitly
; by HL being decremented before the call (NEXT manages RSP itself).
;
ENXTS:
    LD    BC,5                      ;[2423] BC = 5 bytes to copy
    LD    DE,SYSVAR_WRA2+$04        ;[2426] DE -> last byte of WRA2 (LDDR fills backwards)
    LDDR                            ;[2429] Copy 5 bytes: (HL)->(DE), both decrement
    RET                             ;[242B] HL now points 5 bytes below where it started

;
; EIF: IF condition THEN ... -- conditional execution.
; Evaluates the condition expression (RST $28).  If true (WRA1 != zero),
; advances past THEN token and falls into EXEC4 to execute the THEN clause.
; If false (WRA1 = zero / exponent = $80), skips to the next line.
; Special case: if the next line begins with token $3C (ELSE), sets CURRLP
; to that line and executes its clause instead.
;
EIF:
    RST   $28                       ;[242C] Evaluate condition -> WRA1
    LD    A,(SYSVAR_WRA1)           ;[242D] Read WRA1 exponent
    CP    $80                       ;[2430] Is it $80 (zero = false)?
    JR    Z,EIF1                    ;[2432] Yes: condition is false
EIF2:
    INC   DE                        ;[2434] Skip THEN token
    POP   BC                        ;[2435] Discard return address (entering exec loop)
    JP    EXEC4                     ;[2436] Execute the THEN clause directly
EIF1:
    LD    IX,(SYSVAR_CURRLP)        ;[2439] IX = current line
    CALL  NEXT_LINE                 ;[243D] Advance IX to next line
    LD    A,(IX+$00)                ;[2440] Read first byte of next line
    CP    $80                       ;[2443] End of program?
    RET   Z                         ;[2445] Yes: IF with no ELSE, done
    LD    A,(IX+$06)                ;[2446] Read command token of next line
    CP    $3C                       ;[2449] Is it $3C (ELSE token)?
    RET   NZ                        ;[244B] No: no ELSE, done
    LD    (SYSVAR_CURRLP),IX        ;[244C] Yes: set CURRLP to ELSE line
    CALL  SKIP_LNUM                 ;[2450] DE -> first token of ELSE line body
    JR    EIF2                      ;[2453] Execute ELSE clause

;
; ETRAIL: TRAIL [ON|OFF] -- control trailing-zero display in number output.
; Clears bit 1 of SYSVAR_ZFLAG (trail off by default), then checks if the
; argument token is TON ($DA).  If it is, sets bit 1 (trail on).
; Falls through into ENO_EXE / EROUND shared logic.
; Token $DA = TON ("ON"), $DB = TOFF ("OFF").
;
ETRAIL:
    LD    HL,SYSVAR_ZFLAG           ;[2455] HL -> number display flag
    RES   1,(HL)                    ;[2458] Clear bit 1 (TRAIL off)
    CP    $DA                       ;[245A] Is argument TON ($DA = "ON")?
    RET   NZ                        ;[245C] No (TOFF or no arg): leave trail off, return
    SET   1,(HL)                    ;[245D] Yes: set bit 1 (TRAIL on)

;
; ENO_EXE: null execution handler -- used as the execution routine for
; CODE, REM, DATA, LABEL, ELSE (statements that are parsed but not executed).
; Also the fall-through target from ETRAIL when trail is turned on.
;
ENO_EXE:
    RET                             ;[245F] 

;
; ESPEED: SPEED n -- set execution speed throttle.
; Evaluates n (RST $18 -> A).  Stores A in SYSVAR_SPEEDST and sets bit 1 of
; SYSVAR_EXFLAG to enable the speed delay in the exec loop.
; If n is zero, clears bit 1 of EXFLAG (speed throttle off).
;
ESPEED:
    RST   $18                       ;[2460] Evaluate speed value -> integer in HL (A = L)
    LD    HL,SYSVAR_EXFLAG          ;[2461] HL -> execution flags
    LD    (SYSVAR_SPEEDST),A        ;[2464] Store speed value
    SET   1,(HL)                    ;[2467] Set bit 1 (speed throttle active)
    OR    A                         ;[2469] Is speed value zero?
    RET   NZ                        ;[246A] No: speed throttle enabled, return
    RES   1,(HL)                    ;[246B] Zero: clear bit 1 (no throttle)
    RET                             ;[246D] 

;
; ETRACE: TRACE [ON|OFF] -- enable or disable line-number tracing.
; Sets/clears bit 0 of SYSVAR_EXFLAG.  Shares logic with EROUND via ERND1.
; When TRACE is on, DEBUG prints "<N>" before each line (via DBTRAC).
;
ETRACE:
    LD    HL,SYSVAR_EXFLAG          ;[246E] HL -> execution flags
    JR    ERND1                     ;[2471] Shared ON/OFF logic

;
; EROUND: ROUND [ON|OFF] -- control rounding of displayed numbers.
; Sets/clears bit 0 of SYSVAR_ZFLAG.
;
EROUND:
    LD    HL,SYSVAR_ZFLAG           ;[2473] HL -> number display flag
ERND1:
    RES   0,(HL)                    ;[2476] Clear bit 0 (off by default)
    CP    $DA                       ;[2478] Is argument TON ($DA = "ON")?
    RET   NZ                        ;[247A] No: leave off, return
    SET   0,(HL)                    ;[247B] Yes: set bit 0 (on)
    RET                             ;[247D] 

;
; ELINK: LINK [ON|OFF] -- permanently enable or disable LINK (printer) output.
; Controls bit 7 of SYSVAR_OTYPE.  When bit 7 is set, screen output is
; suppressed (output goes to printer only).  With no argument or OFF, clears
; bit 7; with ON ($DA), sets it.
;
ELINK:
    LD    HL,SYSVAR_OTYPE           ;[247E] HL -> output type register
    RES   7,(HL)                    ;[2481] Clear bit 7 (screen suppress off = LINK off)
    CP    $DA                       ;[2483] Is argument TON ($DA = "ON")?
    RET   NZ                        ;[2485] No: LINK off, return
    SET   7,(HL)                    ;[2486] Yes: set bit 7 (suppress screen, LINK on)
    RET                             ;[2488] 

;
; EXECIM: immediate-mode execution entry point.
; Called from LINP_ANLYS ($252D) when the input line has no line number
; (immediate command).  Clears CURRLP to $0000 (not in a program), then
; falls into EXECM1 to execute the tokenised line in HL.
;
EXECIM:
    PUSH  HL                        ;[2489] Save tokenised line pointer
    LD    HL,FLOAT_ZERO             ;[248A] HL -> floating-point zero constant
    LD    (SYSVAR_CURRLP),HL        ;[248D] CURRLP = 0 (command-line mode)
    POP   HL                        ;[2490] Restore tokenised line pointer
    JR    EXECM1                    ;[2491] Execute the line

;
; EXEC_BASIC: enter the BASIC program execution loop.
; HL must point to the first line to execute.  Stores HL into CURRLP,
; sends VDU 15 (cursor off), converts HL to IX, then falls into
; EXEC_LINE_LOOP.
;
EXEC_BASIC:
    LD    (SYSVAR_CURRLP),HL        ;[2493] Store current-line pointer
EXECM1:
    LD    A,$0F                     ;[2496] VDU 15 = cursor off
    RST   $08                       ;[2498] Send it
    PUSH  HL                        ;[2499] 
    POP   IX                        ;[249A] IX = line pointer (for SKIP_LNUM etc.)

;
; EXEC_LINE_LOOP: main BASIC execution loop.
; Checks SYSVAR_EXFLAG for TRACE/SPEED; calls DEBUG hook if active.
; Calls SKIP_LNUM to advance DE to the first statement token of the current
; line (IX+6).  Then falls into EXEC4 to dispatch the command.
;
EXEC_LINE_LOOP:
    LD    A,(SYSVAR_EXFLAG)         ;[249C] Read execution flags (TRACE bit 0, SPEED bit 1)
    OR    A                         ;[249F] Any flags set?
    CALL  NZ,SYSVAR_DEBUG           ;[24A0] Yes: call DEBUG hook (TRACE/SPEED handling)
    CALL  SKIP_LNUM                 ;[24A3] DE -> first token of current line (IX+6)

;
; EXEC4: dispatch and execute one BASIC statement.
; Reads the command token from DE, looks it up in the command execution table
; (SYSVAR_XETBL), and calls the handler with the next token in A and DE
; pointing past the command token.
; On return, falls into EXEC2 to advance to the next line.
;
EXEC4:
    LD    A,(DE)                    ;[24A6] Read command token
    LD    BC,(SYSVAR_XETBL)         ;[24A7] BC -> command execution table base
EXEC41:
    CALL  SYSVAR_EXECSUB            ;[24AB] Call pre-execution hook (future use)
    RLCA                            ;[24AE] Token * 2 (each table entry is 2 bytes = address)
    LD    L,A                       ;[24AF] HL = token * 2
    LD    H,$00                     ;[24B0] 
    ADD   HL,BC                     ;[24B2] HL -> table entry for this command
    LD    BC,EXEC2                  ;[24B3] BC = return address (next-line advance)
    PUSH  BC                        ;[24B6] Push return address
    LD    A,(HL)                    ;[24B7] Read low byte of handler address
    INC   HL                        ;[24B8] 
    LD    H,(HL)                    ;[24B9] H = high byte of handler address
    LD    L,A                       ;[24BA] L = low byte
    INC   DE                        ;[24BB] Advance DE past command token
    LD    A,(DE)                    ;[24BC] A = next byte after command (argument / sub-token)
    JP    (HL)                      ;[24BD] Jump to command handler (returns to EXEC2)

;
; EXEC2: called after each statement handler returns.
; Advances IX to the next BASIC line and falls into EXEC5.
;
EXEC2:
    LD    IX,(SYSVAR_CURRLP)        ;[24BE] IX = current line pointer
    CALL  NEXT_LINE                 ;[24C2] Advance IX to next line

;
; EXEC5: start execution of the line now in IX.
; Updates CURRLP, checks for end-of-program ($80), saves CONTLP, checks ESC,
; then loops back to EXEC_LINE_LOOP.
;
EXEC5:
    LD    (SYSVAR_CURRLP),IX        ;[24C5] Update CURRLP
    LD    A,(IX+$00)                ;[24C9] Read first byte of new line
    CP    $80                       ;[24CC] End-of-program marker?
    JR    Z,TO_CMDLINE              ;[24CE] Yes: program finished, return to command line
    LD    (SYSVAR_CONTLP),IX        ;[24D0] Save as CONT line (can CONT from here)
    CALL  ESC                       ;[24D4] Is ESC pressed?
    JP    Z,STOP2                   ;[24D7] Yes: stop execution (like STOP statement)
    JR    EXEC_LINE_LOOP            ;[24DA] No: execute next line

;
; EXEC_EXIT: clear the CONT pointer (program finished or NEW/END executed;
; cannot continue), then fall through to TO_CMDLINE.
;
EXEC_EXIT:
    LD    HL,0                      ;[24DC] HL = 0
    LD    (SYSVAR_CONTLP),HL        ;[24DF] Clear CONT pointer (cannot continue)
TO_CMDLINE:
    JP    JUMP_TO_CMDLINE           ;[24E2] Return to command-line prompt

;
; DEBUG: TRACE and SPEED handler, called from EXEC_LINE_LOOP when EXFLAG != 0.
; Bit 0 of EXFLAG: TRACE active -> calls DBTRAC to print "<N>".
; Bit 1 of EXFLAG: SPEED active -> calls DBSPED to busy-wait.
; IX is preserved across the call.
;
DEBUG:
    PUSH  IX                        ;[24E5] Save IX
    PUSH  AF                        ;[24E7] Save EXFLAG value
    BIT   0,A                       ;[24E8] TRACE bit set?
    CALL  NZ,DBTRAC                 ;[24EA] Yes: print line number trace
    POP   AF                        ;[24ED] Restore EXFLAG
    BIT   1,A                       ;[24EE] SPEED bit set?
    CALL  NZ,DBSPED                 ;[24F0] Yes: insert speed delay
    POP   IX                        ;[24F3] Restore IX
    RET                             ;[24F5] 

;
; DBTRAC: TRACE line-number display.
; Prints "<N>" where N is the current BASIC line number.
; If CURRLP has $80 in its first byte (not in a program), returns immediately.
;
DBTRAC:
    LD    HL,(SYSVAR_CURRLP)        ;[24F6] HL = current line pointer
    LD    A,(HL)                    ;[24F9] Read first byte
    CP    $80                       ;[24FA] Not in a program?
    RET   Z                         ;[24FC] Yes: skip trace output
    LD    A,'<'                     ;[24FD] Print '<'
    RST   $08                       ;[24FF] 
    CALL  LNUM1                     ;[2500] Load current line number into WRA1
    CALL  PN                        ;[2503] Print line number as decimal
    LD    A,'>'                     ;[2506] Print '>'
    RST   $08                       ;[2508] 
    RET                             ;[2509] 

;
; DBSPED: SPEED delay handler.
; Busy-waits for a time proportional to SYSVAR_SPEEDST by looping HL times
; (where HL = SPEEDST in both bytes, giving a 16-bit count).
; Returns immediately if not in a program.
;
DBSPED:
    LD    HL,(SYSVAR_CURRLP)        ;[250A] HL = current line pointer
    LD    A,(HL)                    ;[250D] Read first byte
    CP    $80                       ;[250E] Not in a program?
    RET   Z                         ;[2510] Yes: skip delay
    LD    HL,(SYSVAR_SPEEDST)       ;[2511] HL = speed store (byte; H will be set = L below)
    LD    H,L                       ;[2514] H = L (replicate byte into both halves for 16-bit count)
DBSPD1:
    DEC   HL                        ;[2515] Decrement delay counter
    LD    A,H                       ;[2516] Test HL for zero
    OR    L                         ;[2517] 
    JR    NZ,DBSPD1                 ;[2518] Not zero: keep waiting
    RET                             ;[251A] Delay complete

;
; SKIP_LNUM: advance DE to point to the first statement token of the current
; BASIC line.  A Lynx BASIC line header is 6 bytes (offset 0..5), so the
; first statement byte is at IX+6.
; Sets DE = IX + 6 by adding 6 to IX and copying to DE.
;
SKIP_LNUM:
    LD    DE,$0006                  ;[251B] DE = 6 (line header size)
    ADD   IX,DE                     ;[251E] IX -> first statement byte
    PUSH  IX                        ;[2520] Copy IX to DE via stack
    POP   DE                        ;[2522] DE = IX = pointer to first token
    RET                             ;[2523] 

;
; LINP_ANLYS: input line analysis -- called from the command loop after a
; line has been read into INPBUF and tokenised into SYSVAR_POLBUF.
; If the first byte of POLBUF is $80 (no line number = immediate command),
; jumps to EXECIM to execute it directly.
; Otherwise the line has a line number: loads it, clears CONTLP, finds or
; creates the line in the BASIC program, and stores the tokenised line.
; Finishes with ZERO_MEM (re-initialise runtime for the new program state).
;
LINP_ANLYS:
    CALL  INPLN                     ;[2524] Tokenise the input line from INPBUF -> POLBUF
    LD    HL,(SYSVAR_POLBUF)        ;[2527] HL -> tokenised line buffer
    LD    A,(HL)                    ;[252A] Read first byte
    CP    $80                       ;[252B] Is it $80 (no line number)?
    JP    Z,EXECIM                  ;[252D] Yes: immediate command, execute now
    CALL  LNUM1                     ;[2530] Load line number from (HL) into WRA1
    PUSH  HL                        ;[2533] Save pointer (points to line length byte)
    LD    HL,$0000                  ;[2534] 
    LD    (SYSVAR_CONTLP),HL        ;[2537] Clear CONT pointer (editing program = cannot continue)
    CALL  FNDLN_WRA1                ;[253A] Find or locate insertion point for line -> IX
    POP   HL                        ;[253D] HL -> line length byte in POLBUF
    LD    L,(HL)                    ;[253E] L = line length from POLBUF header
    LD    H,$00                     ;[253F] HL = line length
    PUSH  HL                        ;[2541] Save line length
    JR    NZ,STL1                   ;[2542] NZ: line does not yet exist, insert fresh
    LD    D,$00                     ;[2544] Line exists: D = 0
    LD    E,(IX+$05)                ;[2546] E = existing line length (from IX+5)
    OR    A                         ;[2549] Clear carry
    SBC   HL,DE                     ;[254A] HL = new_length - old_length (signed delta)
STL1:
    PUSH  IX                        ;[254C] Push insertion point
    POP   DE                        ;[254E] DE = insertion point address
    PUSH  IX                        ;[254F] Save insertion point again
    CALL  INSERT                    ;[2551] Adjust program space by HL bytes at DE
    POP   DE                        ;[2554] Restore insertion point -> DE
    POP   BC                        ;[2555] BC = new line length
    LD    HL,(SYSVAR_POLBUF)        ;[2556] HL -> tokenised line in POLBUF
    LDIR                            ;[2559] Copy BC bytes from POLBUF into program at DE
    JP    ZERO_MEM                  ;[255B] Re-initialise runtime state

;
; NEXT_LINE: advance IX to point to the next BASIC line.
; Each line stores its length at offset 5 (IX+5).  This is added to IX
; to step to the start of the following line.  DE is preserved.
;
NEXT_LINE:
    PUSH  DE                        ;[255E] Save DE
    LD    E,(IX+$05)                ;[255F] E = current line length (bytes including header)
    LD    D,$00                     ;[2562] D = 0 (length is 8-bit)
    ADD   IX,DE                     ;[2564] IX -> next line
    POP   DE                        ;[2566] Restore DE
    RET                             ;[2567] 

;
; CHLDE: compare HL with DE, setting flags as for HL - DE.
; Returns: Z if HL == DE, NZ if different, C if HL < DE (unsigned).
;
CHLDE:
    LD    A,H                       ;[2568] Compare high bytes
    SUB   D                         ;[2569] 
    RET   NZ                        ;[256A] Different high bytes: return with flags set
    LD    A,L                       ;[256B] Compare low bytes
    SUB   E                         ;[256C] 
    RET                             ;[256D] Flags reflect HL - DE

;
; INSERT: insert or delete HL bytes in the BASIC program at address DE.
; Positive HL: insert HL bytes (expand program), copying from EOB down.
; Negative HL (bit 7 of H set): delete |HL| bytes (shrink program), copying up.
; In both cases, after the move, EOB and TOV are updated, PROCST is cleared,
; and ZERO_ARRAY is called to reset the array table (program has changed).
; If HL is zero, returns immediately (nothing to do).
; Calls ERR_OUT_OF_MEM if insertion would overflow into the stack.
;
INSERT:
    LD    A,H                       ;[256E] Test HL for zero
    OR    L                         ;[256F] 
    RET   Z                         ;[2570] Zero: nothing to do
    PUSH  HL                        ;[2571] Save HL (byte count / delta)
    LD    HL,$0000                  ;[2572] 
    LD    (SYSVAR_PROCST),HL        ;[2575] Clear PROCST (program structure changed)
    POP   HL                        ;[2578] Restore delta
    BIT   7,H                       ;[2579] Is bit 7 set? (negative = deletion)
    JR    NZ,INSN                   ;[257B] Yes: deletion path
    LD    BC,(SYSVAR_EOB)           ;[257D] BC = current end-of-BASIC
    ADD   HL,BC                     ;[2581] HL = new EOB (after insertion)
    PUSH  HL                        ;[2582] Save new EOB
    PUSH  DE                        ;[2583] Save insertion point
    LD    DE,(SYSVAR_STACK)         ;[2584] DE = HIMEM/stack base address
    DEC   D                         ;[2588] DE = HIMEM - 256 (safety margin)
    CALL  CHLDE                     ;[2589] Compare new EOB with (HIMEM - 256)
    POP   DE                        ;[258C] Restore insertion point
    CALL  NC,ERR_OUT_OF_MEM         ;[258D] New EOB >= HIMEM-256: out of memory
    CALL  INSRTS                    ;[2590] Move bytes up; BC = old EOB (source), DE = insertion point
    PUSH  BC                        ;[2593] Save old EOB
    LD    L,C                       ;[2594] HL = old EOB
    LD    H,B                       ;[2595] 
    OR    A                         ;[2596] Clear carry
    SBC   HL,DE                     ;[2597] HL = old EOB - insertion point = bytes to move
    PUSH  HL                        ;[2599] 
    POP   BC                        ;[259A] BC = byte count for LDDR
    POP   HL                        ;[259B] HL = old EOB (source for LDDR)
    POP   DE                        ;[259C] DE = new EOB (destination for LDDR)
    INC   BC                        ;[259D] +1 (LDDR moves BC bytes inclusive)
    LDDR                            ;[259E] Move bytes down (from old EOB towards insertion point)
    RET                             ;[25A0] 

INSN:
    PUSH  HL                        ;[25A1] Save negative delta (deletion size, negated)
    PUSH  DE                        ;[25A2] Save deletion start address
    EX    DE,HL                     ;[25A3] HL = deletion start
    OR    A                         ;[25A4] Clear carry
    SBC   HL,DE                     ;[25A5] HL = deletion_start - delta (= deletion end + 1)
    PUSH  HL                        ;[25A7] Save source address for LDIR
    EX    DE,HL                     ;[25A8] Restore registers
    LD    HL,(SYSVAR_EOB)           ;[25A9] HL = current EOB
    OR    A                         ;[25AC] 
    SBC   HL,DE                     ;[25AD] HL = EOB - deletion_start = bytes to move
    PUSH  HL                        ;[25AF] 
    POP   BC                        ;[25B0] BC = byte count for LDIR
    POP   HL                        ;[25B1] HL = source (first byte after deleted range)
    POP   DE                        ;[25B2] DE = destination (deletion start)
    INC   BC                        ;[25B3] +1 inclusive
    LDIR                            ;[25B4] Copy bytes down (close the gap)
    POP   DE                        ;[25B6] DE = original negative delta
    LD    HL,(SYSVAR_EOB)           ;[25B7] HL = current EOB
    ADD   HL,DE                     ;[25BA] HL = EOB + delta (delta is negative = new EOB)
INSRTS:
    LD    (SYSVAR_EOB),HL           ;[25BB] Update EOB
    INC   HL                        ;[25BE] 
    LD    (SYSVAR_TOV),HL           ;[25BF] TOV = EOB + 1 (variables start just after program)
    PUSH  DE                        ;[25C2] Save DE
    PUSH  BC                        ;[25C3] Save BC
    CALL  ZERO_ARRAY                ;[25C4] Reset array table (program changed)
    POP   BC                        ;[25C7] 
    POP   DE                        ;[25C8] 
    RET                             ;[25C9] 

;
; ZERO_ARRAY: zero the string table and the array variable table.
; Clears $68 (104) bytes from SYSVAR_STBL (string table base) to zero,
; then fills the 53-entry array table (SYSVAR_ATBL, 4 bytes * 53 = 212 bytes)
; with zeros using a self-extending LDIR fill pattern.
;
ZERO_ARRAY:
    LD    HL,(SYSVAR_STBL)          ;[25CA] HL -> string table base
    LD    B,$68                     ;[25CD] B = 104 (bytes to clear)
    XOR   A                         ;[25CF] A = 0
ZARR2:
    LD    (HL),A                    ;[25D0] Write zero
    INC   HL                        ;[25D1] 
    DJNZ  ZARR2                     ;[25D2] Repeat 104 times
    LD    HL,(SYSVAR_ATBL)          ;[25D4] HL -> array table base
    LD    E,L                       ;[25D7] DE = HL (destination = source + 1)
    LD    D,H                       ;[25D8] 
    INC   DE                        ;[25D9] DE = ATBL + 1
    LD    BC,211                    ;[25DA] BC = 211 = 4*53 - 1 (bytes - 1)
    LD    (HL),$00                  ;[25DD] Write first zero byte
    LDIR                            ;[25DF] Propagate zero through all 212 bytes
    RET                             ;[25E1] 

;
; RP: read and tokenise one expression from the input text at DE into the
; reverse-polish buffer at HL.  Writes SOP ($7D) as the first byte, then
; calls SYSVAR_NTP (the normal-to-polish converter) to fill the rest.
; After conversion, checks the last-token type (SYSVAR_NPM): if it is >= THEN
; ($D7), the expression ended on a command token (e.g. TO, STEP, THEN) and
; returns with that token in A and DE pointing past it.
; Otherwise reads and returns the terminating character (comma, CR, etc.).
;
RP:
    LD    (HL),SOP                  ;[25E2] Write SOP ($7D) start-of-polish marker
    INC   HL                        ;[25E4] Advance buffer pointer past SOP
    CALL  SYSVAR_NTP                ;[25E5] Convert infix expression to Polish notation
    LD    A,(SYSVAR_NPM)            ;[25E8] A = last token type processed
    CP    THEN                      ;[25EB] Is it >= THEN ($D7)? (command token: TO, THEN etc.)
    RET   NC                        ;[25ED] Yes: return with command token in A, DE past it
    LD    A,(DE)                    ;[25EE] No: read the terminating character at DE
    INC   DE                        ;[25EF] Advance past it
    RET                             ;[25F0] Return with terminator in A

;
; QUOT: read a quoted string literal from the input at DE into the token
; buffer at HL.  Asserts that the first character is '"' (RST $20), stores it,
; then copies characters into HL until another '"' is found.
; Triggers ERR_SYNTAX if CR is encountered before the closing '"'.
; On return, A = the character after the closing '"', DE points past it,
; and HL points past the copied string.
;
QUOT:
    RST   $20                       ;[25F1] Assert: next char at DE must be '"'
    DB    $22                       ;[25F2] Expected: '"'
    LD    (HL),A                    ;[25F3] Store '"' in buffer
    INC   HL                        ;[25F4] 
    INC   DE                        ;[25F5] Advance past the '"' in source
QU1:
    LD    A,(DE)                    ;[25F6] Read next character
    INC   DE                        ;[25F7] Advance source pointer
    LD    (HL),A                    ;[25F8] Store in buffer
    INC   HL                        ;[25F9] Advance buffer pointer
    CP    CR                        ;[25FA] Is it CR? (unterminated string)
    CALL  Z,ERR_SYNTAX              ;[25FC] Yes: syntax error
    CP    $22                       ;[25FF] Is it closing '"'?
    JR    NZ,QU1                    ;[2601] No: keep copying
    JP    SPACE                     ;[2603] Yes: skip trailing spaces and return

;
; IROUND: tokeniser validation for ROUND, TRAIL, LINK, TRACE statements.
; Reads the ON/OFF argument token (via TKSL).  If it is TON ($DA), stores it
; and reads the following character.  Otherwise asserts that TOFF ($DB) follows
; (RST $20).  Writes the token and a terminating CR into the token buffer at HL.
;
IROUND:
    CALL  TKSL                      ;[2606] Tokenise next word -> A (token or char)
    CP    $DA                       ;[2609] Is it TON ($DA = "ON")?
    JR    Z,IRD1                    ;[260B] Yes: store TON
    RST   $20                       ;[260D] No: assert it must be TOFF
    DB    TOFF                      ;[260E] Expected: TOFF ($DB = "OFF")
IRD1:
    LD    (HL),A                    ;[260F] Store ON/OFF token in buffer
    INC   HL                        ;[2610] 
    RST   $10                       ;[2611] Skip spaces; A = next non-space char (should be CR)
    LD    (HL),A                    ;[2612] Store terminator (CR)
    RST   $20                       ;[2613] Assert: must be CR
    DB    CR                        ;[2614] Expected: CR
    RET                             ;[2615] 

;
; ILOAD: tokeniser validation for LOAD, MLOAD, APPEND, VERIFY statements.
; Reads a quoted filename string into the token buffer via QUOT, then
; asserts that a CR follows.  Stores the CR in the buffer.
;
ILOAD:
    CALL  QUOT                      ;[2616] Read quoted filename into buffer at HL
    RST   $20                       ;[2619] Assert: CR must follow
    DB    CR                        ;[261A] Expected: CR
ILD1:
    LD    (HL),A                    ;[261B] Store CR in buffer
    RET                             ;[261C] 

;
; ISAVE: tokeniser validation for SAVE statement.
; Reads a quoted filename, then optionally a comma-separated type argument
; (read via IINK).  If no comma (CR follows), stores CR and returns.
;
ISAVE:
    CALL  QUOT                      ;[261D] Read quoted filename into buffer at HL
    CP    $0D                       ;[2620] Is terminator CR? (no extra argument)
    JR    Z,ILD1                    ;[2622] Yes: store CR and return
    RST   $20                       ;[2624] No: assert comma follows
    DB    ','                       ;[2625] Expected: ','
    LD    (HL),A                    ;[2626] Store comma in buffer
    INC   HL                        ;[2627] 
    INC   DE                        ;[2628] Advance past comma
    JP    IINK                      ;[2629] Read type argument and return

;
; IINPUT: tokeniser validation for INPUT statement.
; If a '"' follows, reads the prompt string via QUOT then asserts ';' separator.
; Then falls into IRD to read and validate the variable list.
;
IINPUT:
    CP    $22                       ;[262C] Is next char '"'? (prompt string)
    JR    NZ,IRD                    ;[262E] No: go straight to variable list
    CALL  QUOT                      ;[2630] Read prompt string into buffer
    RST   $20                       ;[2633] Assert: ';' separator must follow prompt
    DB    ';'                       ;[2634] Expected: ';'
    LD    (HL),A                    ;[2635] Store ';' in buffer
    INC   HL                        ;[2636] 
    INC   DE                        ;[2637] Advance past ';'
    RST   $10                       ;[2638] Skip spaces

;
; IRD: tokeniser validation for INPUT and READ variable lists.
; Reads successive variable names (numeric or string) separated by commas
; into the token buffer at HL.  Terminates at CR.
; For numeric variables, calls IVRY to tokenise the variable reference.
; For string variables, calls READ_STRING_VAR.
; Checks that this is not a command-line INPUT (POLBUF first byte != $80).
;
IRD:
    PUSH  HL                        ;[2639] Save buffer pointer
    LD    HL,(SYSVAR_POLBUF)        ;[263A] HL -> tokenised line buffer
    LD    A,(HL)                    ;[263D] Read first byte
    CP    $80                       ;[263E] Is it $80 (command-line mode)?
    CALL  Z,ERR_WRONG_MODE          ;[2640] Yes: INPUT not valid at command line
    POP   HL                        ;[2643] Restore buffer pointer
    CALL  TEST_FOR_STRING           ;[2644] Is current variable a string (ends in '$')?
    JR    Z,IREAD1                  ;[2647] Yes: handle as string variable
    CALL  IVRY                      ;[2649] No: tokenise numeric variable reference
IREAD3:
    LD    (HL),A                    ;[264C] Store terminator (CR or ',') in buffer
    CP    $0D                       ;[264D] Is it CR?
    RET   Z                         ;[264F] Yes: done
    RST   $20                       ;[2650] No: assert comma
    DB    ','                       ;[2651] Expected: ','
    INC   HL                        ;[2652] Advance buffer pointer
    INC   DE                        ;[2653] Advance source pointer
    RST   $10                       ;[2654] Skip spaces
    JR    IRD                       ;[2655] Process next variable

IREAD1:
    CALL  READ_STRING_VAR           ;[2657] Tokenise string variable name into buffer at HL
    RST   $10                       ;[265A] Skip spaces
    JR    IREAD3                    ;[265B] Store terminator and check for more

;
; IRESTORE: tokeniser validation for RESTORE statement.
; If CR follows (no argument), stores it and returns.
; Otherwise falls into IINK to read an expression argument.
;
IRESTORE:
    CP    CR                        ;[265D] No argument?
    JP    NZ,IINK                   ;[265F] No: read expression via IINK
OC1:
    LD    (HL),A                    ;[2662] Store CR in buffer
    RET                             ;[2663] 

;
; ILIST: tokeniser validation for LIST, LLIST, RENUM.
; Accepts optional expression(s).  If CR, stores it and returns.
; Otherwise falls into ICALL to read expression(s).
;
ILIST:
    CP    CR                        ;[2664] No argument?
    JR    Z,OC1                     ;[2666] Yes: store CR and return

;
; ICALL: tokeniser validation for CALL statement.
; Reads a mandatory expression, then optionally a comma-separated second
; expression.  Stores terminator in buffer.
;
ICALL:
    CALL  RP                        ;[2668] Read and tokenise first expression -> buffer
    CP    $0D                       ;[266B] Terminator CR?
    JR    Z,OC1                     ;[266D] Yes: done
    RST   $20                       ;[266F] No: assert comma
    DB    ','                       ;[2670] Expected: ','
    LD    (HL),A                    ;[2671] Store comma in buffer
    INC   HL                        ;[2672] 
    JP    IINK                      ;[2673] Read second expression via IINK

;
; ILETX: error recovery for LET tokeniser -- called when LET parsing fails.
; Pops the stack and restores HL, then falls into ILET1 with A=0.
;
ILETX:
    POP   AF                        ;[2676] Discard saved AF
    POP   HL                        ;[2677] Restore buffer pointer
ILET1:
    LD    A,$00                     ;[2678] A = 0 (no separator)
ILET4:
    LD    (HL),A                    ;[267A] Store separator byte in buffer
    INC   HL                        ;[267B] Advance buffer pointer

;
; ILET: tokeniser validation for LET (and implicit assignment).
; Reads variable=expression pairs, handling both numeric and string variables.
; Multiple assignments separated by commas are handled by looping.
;
ILET:
    CALL  TEST_FOR_STRING           ;[267C] Is current variable a string?
    JR    Z,ILET3                   ;[267F] Yes: string assignment path
    CALL  IVRY                      ;[2681] No: tokenise numeric variable reference
    CP    '='                       ;[2684] Assert '=' follows


    JP    NZ,IERR                   ;[2686] Not '=': input error
    LD    (HL),A                    ;[2689] Store '=' in buffer
    INC   HL                        ;[268A] 
    INC   DE                        ;[268B] Advance past '='
    CALL  RP                        ;[268C] Tokenise the RHS expression
ILET7:
    CP    ','                       ;[268F] Is terminator ','? (another assignment follows)
    JR    Z,ILET4                   ;[2691] Yes: store comma and loop for next assignment
    JP    IEND                      ;[2693] No: store CR and return

ILET3:
    CALL  READ_STRING_VAR           ;[2696] Tokenise string variable name into buffer at HL
    RST   $10                       ;[2699] Skip spaces
    RST   $20                       ;[269A] Assert: '=' must follow
    DB    '='                       ;[269B] Expected: '='
    LD    (HL),A                    ;[269C] Store '=' in buffer
    INC   HL                        ;[269D] 
    INC   DE                        ;[269E] Advance past '='
    RST   $10                       ;[269F] Skip spaces
    CALL  READ_STRING_EXPR          ;[26A0] Tokenise string expression into buffer
    INC   DE                        ;[26A3] Advance past string expression terminator
    JR    ILET7                     ;[26A4] Check for further assignments

;
; IERR: input error handler for the LET tokeniser.
; Re-tokenises the input as a raw expression (IINK), evaluates it, prints the
; result, outputs a CR, and returns to the command line.
; Called when a LET expression cannot be parsed as an assignment.
;
IERR:
    LD    DE,INPBUF                 ;[26A6] DE -> input buffer (raw input text)
    LD    HL,(SYSVAR_POLBUF)        ;[26A9] HL -> Polish token buffer
    PUSH  HL                        ;[26AC] Save Polish buffer pointer
    CALL  IINK                      ;[26AD] Re-tokenise entire input as expression
    POP   DE                        ;[26B0] DE -> Polish buffer (now contains tokenised expr)
    CALL  SYSVAR_EE                 ;[26B1] Evaluate the expression -> WRA1
    CALL  PN                        ;[26B4] Print WRA1 as decimal number
    LD    A,CR                      ;[26B7] A = CR
    RST   $08                       ;[26B9] Print CR
    JP    JUMP_TO_CMDLINE           ;[26BA] Return to command line

;
; IDPOKE: tokeniser validation for DPOKE, POKE, DOT, OUT, MOVE, DRAW, SOUND.
; Reads the first expression, asserts a comma, then reads the second via IINK.
;
IDPOKE:
    CALL  TEST_IS_COMMA             ;[26BD] Tokenise first expression, assert and store ','
    JP    IINK                      ;[26C0] Tokenise second expression and return

;
; IGOTO: tokeniser validation for GOSUB and GOTO.
; If followed by OLABEL ($D8, @label syntax), stores the OLABEL token and
; copies the label name via IREM.  Otherwise reads a numeric expression via IINK.
;
IGOTO:
    PUSH  DE                        ;[26C3] Save input pointer
    CALL  TKSL                      ;[26C4] Try to tokenise next word
    JR    C,IGOTO2                  ;[26C7] Carry: not a keyword, use numeric expression
    CP    OLABEL                    ;[26C9] Is it OLABEL ($D8)?
    JR    Z,IGOTO1                  ;[26CB] Yes: label-based GOTO/GOSUB
IGOTO2:
    POP   DE                        ;[26CD] Restore input pointer
    JP    IINK                      ;[26CE] Tokenise as numeric line-number expression
IGOTO1:
    POP   BC                        ;[26D1] Discard saved DE (label path, DE already advanced)
    LD    (HL),A                    ;[26D2] Store OLABEL token in buffer
    INC   HL                        ;[26D3] 
    RST   $10                       ;[26D4] Skip spaces to label name
    JP    IREM                      ;[26D5] Copy label name verbatim to end of line

;
; INEXT: tokeniser validation for NEXT statement.
; Reads the optional loop variable (TEST_IS_VAR), then falls into IEND.
;
INEXT:
    CALL  TEST_IS_VAR               ;[26D8] Read optional variable token into buffer

;
; IEND: tokeniser validation for statements with no argument or a simple token.
; Stores A (current character, should be CR) in the buffer and asserts CR.
; Used by: MON, ENDPROC, RANDOM, END, STOP, RETURN, CLS, CONT, NEW,
;          WEND, REPEAT, DISK, TEXT.
;
IEND:
    LD    (HL),A                    ;[26DB] Store current character (CR) in buffer
    RST   $20                       ;[26DC] Assert: must be CR
    DB    CR                        ;[26DD] Expected: CR
    RET                             ;[26DE] 

;
; IFOR: tokeniser validation for FOR statement.
; Reads: variable '=' expr TO expr [STEP expr]
; Stores variable token, '=' (decremented to mark assignment), start expression,
; TO token (stored in IX+$23 as a flag), limit expression, and optional STEP.
;
IFOR:
    CALL  TEST_IS_VAR               ;[26DF] Read loop variable token into buffer
    RST   $20                       ;[26E2] Assert: '=' must follow
    DEC   A                         ;[26E3] A = '=' - 1 (stored as marker, not literal '=')
    INC   DE                        ;[26E4] Advance past '='
    LD    (HL),A                    ;[26E5] Store modified '=' marker in buffer
    INC   HL                        ;[26E6] 
    CALL  RP                        ;[26E7] Tokenise start expression
    RST   $20                       ;[26EA] Assert: TO token must follow
    LD    (IX+$23),A                ;[26EB] Store TO token in IX frame (syntax record)
    CALL  RP                        ;[26EE] Tokenise limit expression
    CP    $0D                       ;[26F1] Is terminator CR? (no STEP)
    JP    Z,OC1                     ;[26F3] Yes: store CR and return
    RST   $20                       ;[26F6] Assert: STEP token must follow
    CALL  C,$2377                   ;[26F7] Carry: call error handler if assertion failed
    JP    IINK                      ;[26FA] Tokenise STEP expression and return

;
; IIF: tokeniser validation for IF statement.
; Reads the condition expression, asserts THEN token, stores it, then
; falls into IL1 to tokenise the THEN clause.
;
IIF:
    CALL  RP                        ;[26FD] Tokenise condition expression
    RST   $20                       ;[2700] Assert: THEN must follow
    DB    THEN                      ;[2701] Expected: THEN ($D7)
    LD    (HL),A                    ;[2702] Store THEN token in buffer
    INC   HL                        ;[2703] 
    JP    IL1                       ;[2704] Continue tokenising the THEN clause

;
; IINK: tokeniser validation for INK, PAPER, PAUSE, WHILE, UNTIL, RESERVE,
; CFR, CCHAR, SPEED, PROTECT, ERROR, TAPE.  One expression followed by CR.
;
IINK:
    CALL  RP                        ;[2707] Tokenise single expression
    JP    IEND                      ;[270A] Assert CR and return

;
; TEST_IS_COMMA: tokenise an expression then assert and store a comma separator.
; Used by multi-argument statements (DPOKE, POKE, OUT, MOVE etc.).
;
TEST_IS_COMMA:
    CALL  RP                        ;[270D] Tokenise first expression into buffer
    RST   $20                       ;[2710] Assert: ',' must follow
    DB    ','                       ;[2711] Expected: ','
    LD    (HL),A                    ;[2712] Store ',' in buffer
    INC   HL                        ;[2713] 
    RET                             ;[2714] 

;
; TEST_IS_VAR: read a variable token from the input at DE into the buffer at HL.
; Calls TEST_ALPHA to verify it is alphabetic; errors if not.
; Stores the token, advances DE, and skips trailing spaces.
;
TEST_IS_VAR:
    CALL  TEST_ALPHA                ;[2715] Test if current char is alphabetic
    CALL  C,ERR_SYNTAX              ;[2718] Not alpha: syntax error
    LD    (HL),A                    ;[271B] Store variable token in buffer
    INC   DE                        ;[271C] Advance past variable letter
    INC   HL                        ;[271D] Advance buffer pointer
    JP    SPACE                     ;[271E] Skip spaces and return

;
; IVRY: tokeniser for a numeric variable reference in READ/INPUT/LET lists.
; Reads an alphabetic variable token; errors via IERR if not alphabetic.
; Handles plain variables and array subscripts (if '(' follows).
;
IVRY:
    CALL  TEST_ALPHA                ;[2721] Test if current char is alphabetic
    JP    C,IERR                    ;[2724] Not alpha: input error
    LD    (HL),A                    ;[2727] Store variable token in buffer
    INC   HL                        ;[2728] 
    INC   DE                        ;[2729] Advance past variable letter
    RST   $10                       ;[272A] Skip spaces
    CP    '('                       ;[272B] Is next char '('? (array subscript)
    RET   NZ                        ;[272D] No: plain variable, done
ARARG:
    LD    (HL),'('                  ;[272E] Store '(' in buffer
    INC   HL                        ;[2730] 
ARG3:
    INC   DE                        ;[2731] Advance past '('
    CALL  RP                        ;[2732] Tokenise subscript expression
    RST   $20                       ;[2735] Assert: ')' must follow
    DB    ')'                       ;[2736] Expected: ')'
    LD    (HL),A                    ;[2737] Store ')' in buffer
    INC   HL                        ;[2738] 
    JP    SPACE                     ;[2739] Skip spaces and return

;
; IREM: tokeniser for REM, DATA, EXT, LABEL statements.
; Copies all remaining characters from DE to the buffer at HL verbatim,
; including and stopping at CR.
;
IREM:
    LD    A,(DE)                    ;[273C] Read character from input
    LD    (HL),A                    ;[273D] Store in buffer
    CP    CR                        ;[273E] Is it CR?
    RET   Z                         ;[2740] Yes: done (CR stored, return)
    INC   HL                        ;[2741] Advance buffer pointer
    INC   DE                        ;[2742] Advance input pointer
    JR    IREM                      ;[2743] Copy next character

;
; ISWAP: tokeniser validation for SWAP statement.
; Reads two comma-separated variable references into the buffer.
; Errors if no comma between them.
;
ISWAP:
    CALL  IVRY                      ;[2745] Tokenise first variable reference
    LD    (HL),A                    ;[2748] Store separator character
    CP    ','                       ;[2749] Is it ','?
    JR    NZ,ISW1                   ;[274B] No: error
    INC   HL                        ;[274D] Store comma in buffer
    INC   DE                        ;[274E] Advance past ','
    CALL  IVRY                      ;[274F] Tokenise second variable reference
    LD    (HL),A                    ;[2752] Store terminator
    CP    CR                        ;[2753] Is it CR?
    RET   Z                         ;[2755] Yes: done
ISW1:
    CALL  ERR_SOMETHG_MISSG         ;[2756] Missing comma or variable: error

;
; WRA1_TO_WRA2: copy the 5-byte float in WRA1 into WRA2.
; Falls through to WRA1_TO_DE with DE = WRA2.
;
WRA1_TO_WRA2:
    LD    DE,SYSVAR_WRA2            ;[2759] DE -> WRA2 destination

;
; WRA1_TO_DE: copy the 5-byte float in WRA1 to the address in DE.
; Used to store a computed float value into a variable slot or working area.
;
WRA1_TO_DE:
    LD    HL,SYSVAR_WRA1            ;[275C] HL -> WRA1 source
    LD    BC,5                      ;[275F] BC = 5 bytes
    LDIR                            ;[2762] Copy WRA1 -> (DE)
    RET                             ;[2764] 

;
; INPLNP: input line pre-processor.
; If AUTO mode is active (SYSVAR_AUTOFL != 0), loads the current AUTO line
; number from SYSVAR_AUTOST into WRA1 and falls into INPLN3 to inject it.
; Otherwise calls SUB_FIND to read the line number from the input.
;
INPLNP:
    LD    A,(SYSVAR_AUTOFL)         ;[2765] A = AUTO flag (0 = off)
    OR    A                         ;[2768] Is it zero?
    JP    Z,SUB_FIND                ;[2769] Yes: read line number from input
    PUSH  HL                        ;[276C] Save buffer pointer
    LD    HL,SYSVAR_AUTOST          ;[276D] HL -> AUTO start/step storage
    PUSH  DE                        ;[2770] Save input pointer
    CALL  LNUM1                     ;[2771] Load AUTO line number from (HL) into WRA1
    POP   DE                        ;[2774] Restore input pointer
    POP   HL                        ;[2775] Restore buffer pointer
    JP    INPLN3                    ;[2776] Inject AUTO line number into buffer

;
; INPLN: tokenise an input line from INPBUF into the Polish buffer (SYSVAR_POLBUF).
; Calls INPLNP to handle AUTO numbering or read the line number, then writes a
; $80 end-of-program sentinel, measures the line length, errors if too long
; (>= 256 bytes), and stores the length byte in the line header at IX+5.
;
INPLN:
    CALL  INPLNP                    ;[2779] Pre-process: inject or read line number
    INC   HL                        ;[277C] Advance past last byte written
    LD    (HL),$80                  ;[277D] Write $80 end-of-program sentinel
    LD    DE,(SYSVAR_POLBUF)        ;[277F] DE -> start of Polish buffer
    PUSH  DE                        ;[2783] 
    POP   IX                        ;[2784] IX -> Polish buffer start
    OR    A                         ;[2786] Clear carry
    SBC   HL,DE                     ;[2787] HL = end - start = line length
    XOR   A                         ;[2789] A = 0
    CP    H                         ;[278A] Is H non-zero? (length >= 256)
    CALL  NZ,ERR_LINE_TOO_LONG      ;[278B] Yes: line too long error
    LD    (IX+$05),L                ;[278E] Store length byte in line header at offset 5
    RET                             ;[2791] 

;
; SUB_FIND: read and tokenise a line number (or immediate command) from the
; input text at DE.  Skips leading spaces, reads a decimal number into WRA1.
; Falls into INPLN3.
;
SUB_FIND:
    RST   $10                       ;[2792] Skip leading spaces; A = first non-space char
    CALL  RDN                       ;[2793] Read decimal number from DE into WRA1
INPLN3:
    LD    A,(SYSVAR_WRA1)           ;[2796] Read WRA1 exponent byte
    BIT   7,A                       ;[2799] Is bit 7 set? (positive = has a line number)
    JP    Z,IERR                    ;[279B] Zero (negative/zero): no valid line number, error
    PUSH  DE                        ;[279E] Save input pointer (past the line number)
    LD    DE,(SYSVAR_POLBUF)        ;[279F] DE -> Polish buffer
    CALL  WRA1_TO_DE                ;[27A3] Store line number float at start of Polish buffer
    EX    DE,HL                     ;[27A6] HL = DE = pointer just past the stored line number
    INC   HL                        ;[27A7] Advance to line-length byte position
    POP   DE                        ;[27A8] Restore input pointer

;
; IL1: tokenise the body of an input line (statements) into the buffer at HL.
; Skips spaces, calls SYSVAR_INPLSUB (input line sub-routine hook) for any
; extra processing, then falls into IL4 to tokenise each command token.
;
IL1:
    RST   $10                       ;[27A9] Skip spaces; A = first non-space char
    CALL  SYSVAR_INPLSUB            ;[27AA] Call RAM input-line-processing hook

;
; IL4: tokenise one command token from the input at DE into the buffer at HL.
; Looks up the token in SYSVAR_XTTBL (command token table), stores the token
; byte, then dispatches to the token's input validation routine via SYSVAR_XITBL.
;
IL4:
    PUSH  HL                        ;[27AD] Save buffer pointer
    LD    HL,(SYSVAR_XTTBL)         ;[27AE] HL -> command token table
    LD    B,(HL)                    ;[27B1] B = number of tokens in table
    PUSH  BC                        ;[27B2] Save token count
    CALL  $1949                     ;[27B3] Call TK1 (token search): find command token in table
    JP    C,ILETX                   ;[27B6] Carry: not a keyword token, try as LET/expression
    POP   AF                        ;[27B9] A = original token count
    SUB   B                         ;[27BA] A = count - remaining = token index
    POP   HL                        ;[27BB] Restore buffer pointer
IL2:
    LD    (HL),A                    ;[27BC] Store token byte in buffer
    INC   HL                        ;[27BD] Advance buffer pointer
    LD    IX,(SYSVAR_XITBL)         ;[27BE] IX -> input validation routine table
IL3:
    RLCA                            ;[27C2] Token * 2 (each table entry is 2 bytes)
    LD    C,A                       ;[27C3] BC = offset into validation table
    LD    B,$00                     ;[27C4] 
    ADD   IX,BC                     ;[27C6] IX -> validation routine address entry
    LD    C,(IX+$00)                ;[27C8] C = low byte of validation routine address
    LD    B,(IX+$01)                ;[27CB] B = high byte
    PUSH  BC                        ;[27CE] Push validation routine address
    JP    SPACE                     ;[27CF] Skip spaces then JP (SP) to validation routine

;
; SUB_PRINT_KEYWORD: print a BASIC keyword from the command token table.
; Called during BASIC line display (LIST).  Prints a leading space, looks up
; the keyword text in SYSVAR_XTTBL via TOKEN_TO_WORD_FIND, prints it via PNE15,
; then prints a trailing space and advances DE past the token.
;
SUB_PRINT_KEYWORD:
    CALL  DISPLAY_SPACE             ;[27D2] Print a leading space
    LD    HL,(SYSVAR_XTTBL)         ;[27D5] HL -> command token table
    LD    B,A                       ;[27D8] B = token value
    INC   B                         ;[27D9] B+1 (TOKEN_TO_WORD_FIND decrements before scanning)
    CALL  TOKEN_TO_WORD_FIND        ;[27DA] HL -> last char of matching keyword entry
    CALL  PNE15                     ;[27DD] Print keyword text (scanning backwards from end)
    CALL  DISPLAY_SPACE             ;[27E0] Print a trailing space
    INC   DE                        ;[27E3] Advance DE past the token byte
    RET                             ;[27E4] 

;
; DBASLN: display one BASIC line as text (LIST output).
; Called via SYSVAR_DBASLN hook.  Prints the line number, handles ELSE clause
; indentation, prints the command keyword, then prints the rest of the line
; token by token.  Handles string literals, Polish expressions (SOP/$7D),
; operator tokens, and the THEN continuation.
; Sends CEL (clear to end of line) and XCRLF (CR/LF) at the end.
;
DBASLN:
    PUSH  IX                        ;[27E5] 
    POP   HL                        ;[27E7] HL = IX = current line pointer
    PUSH  HL                        ;[27E8] Save for later (INDENT_IF_LOOP)
    CALL  LNUM1                     ;[27E9] Load line number from (HL) into WRA1
    CALL  PN                        ;[27EC] Print line number
    CALL  TEST_IS_LOOP_END          ;[27EF] Check if line ends a loop (decrement indent)
    CALL  SUB_INDENT                ;[27F2] Print indentation spaces
    CALL  SKIP_LNUM                 ;[27F5] DE -> first token of line (past 6-byte header)
DBASLN1:
    LD    A,(DE)                    ;[27F8] Read command token
    PUSH  AF                        ;[27F9] Save token
    CALL  SUB_PRINT_KEYWORD         ;[27FA] Print the keyword with surrounding spaces
    POP   AF                        ;[27FD] Restore token
    CP    $3C                       ;[27FE] Is it $3C (ELSE token)?
    JR    Z,DBASLN1                 ;[2800] Yes: print ELSE then continue with next command
    CP    $33                       ;[2802] Is it $33 (PRINT token)?
    JP    Z,PRINT_BAS_LINE          ;[2804] Yes: special PRINT line handler
    DEC   DE                        ;[2807] Back up one (DBASL will INC before reading)
DBASL:
    INC   DE                        ;[2808] Advance to next byte
DBASLN11:
    LD    A,(DE)                    ;[2809] Read next byte
    CP    $7B                       ;[280A] Is it EOS ($7B = end of string sub-expression)?
    RET   Z                         ;[280C] Yes: end of line content, return
    CP    $0D                       ;[280D] Is it CR? (end of statement)
    JR    Z,DO_INDENT               ;[280F] Yes: handle indentation and emit CRLF
    CP    $7D                       ;[2811] Is it SOP ($7D = start of Polish expression)?
    JR    Z,DBASLN2                 ;[2813] Yes: print Polish expression
    CP    $80                       ;[2815] Is it >= $80? (operator/function token)
    JR    NC,DBASLN3                ;[2817] Yes: print token keyword
    RST   $08                       ;[2819] Print raw character (variable letter, digit, etc.)
    CP    $22                       ;[281A] Was it '"'? (start of string literal)
    JR    NZ,DBASL                  ;[281C] No: continue scanning
    CALL  PRINT_STRING              ;[281E] Yes: print the quoted string contents
    RST   $08                       ;[2821] Print closing '"'
    JR    DBASL                     ;[2822] Continue
DBASLN2:
    INC   DE                        ;[2824] Advance past SOP ($7D)
    CALL  SYSVAR_PP                 ;[2825] Print the Polish expression (via PP hook)
    JR    DBASL                     ;[2828] Continue with rest of line
DBASLN3:
    CP    $DF                       ;[282A] Is token < $DF? (low operator range)
    PUSH  AF                        ;[282C] Save token and flags
    CALL  C,DISPLAY_SPACE           ;[282D] Low operator: print leading space
    CALL  PNE1                      ;[2830] Print keyword/operator text
    POP   AF                        ;[2833] Restore token
    PUSH  AF                        ;[2834] Save again
    CALL  C,DISPLAY_SPACE           ;[2835] Low operator: print trailing space
    POP   AF                        ;[2838] Restore token
    INC   DE                        ;[2839] Advance past operator token
    CP    THEN                      ;[283A] Is it THEN ($D7)?
    JR    Z,DBASLN1                 ;[283C] Yes: next token is another command keyword
    JR    DBASLN11                  ;[283E] No: continue printing expression tokens

DO_INDENT:
    POP   IX                        ;[2840] Restore saved line pointer into IX
    CALL  INDENT_IF_LOOP            ;[2842] Update indent level if this is a loop-start line
    LD    A,CEL                     ;[2845] VDU 30 = clear to end of line
    RST   $08                       ;[2847] 
    LD    A,XCRLF                   ;[2848] VDU $1F = CR/LF
    RST   $08                       ;[284A] 
    RET                             ;[284B] 

;
; INDENT_IF_LOOP: increment the indent level counter (SYSVAR_SBC) if the
; current line (IX+6) is a loop-opening statement: WHILE ($36), FOR ($0F),
; or REPEAT ($38).
;
INDENT_IF_LOOP:
    LD    A,(IX+$06)                ;[284C] Read command token of current line
    CP    WHILE                     ;[284F] Is it WHILE ($36)?
    JR    Z,INDENT_SPACES           ;[2851] Yes: indent
    CP    FOR                       ;[2853] Is it FOR ($0F)?
    JR    Z,INDENT_SPACES           ;[2855] Yes: indent
    CP    REPEAT                    ;[2857] Is it REPEAT ($38)?
    RET   NZ                        ;[2859] No: not a loop start, return
INDENT_SPACES:
    LD    HL,SYSVAR_SBC             ;[285A] HL -> indent counter
    INC   (HL)                      ;[285D] Increment indent level
    RET                             ;[285E] 

;
; TEST_IS_LOOP_END: decrement the indent level counter (SYSVAR_SBC) if the
; current line is a loop-closing statement: WEND ($37), NEXT ($05), or
; UNTIL ($39).  Only decrements if counter is non-zero.
;
TEST_IS_LOOP_END:
    LD    A,(IX+$06)                ;[285F] Read command token
    CP    WEND                      ;[2862] Is it WEND ($37)?
    JR    Z,DBLS4                   ;[2864] Yes: decrement
    CP    $05                       ;[2866] Is it NEXT ($05)?
    JR    Z,DBLS4                   ;[2868] Yes: decrement
    CP    $39                       ;[286A] Is it UNTIL ($39)?
    RET   NZ                        ;[286C] No: not a loop end, return
DBLS4:
    LD    A,(SYSVAR_SBC)            ;[286D] Read indent counter
    OR    A                         ;[2870] Is it zero?
    RET   Z                         ;[2871] Yes: already at zero, don't go negative
    DEC   A                         ;[2872] Decrement
    LD    (SYSVAR_SBC),A            ;[2873] Store updated indent level
    RET                             ;[2876] 

;
; SUB_INDENT: print indentation spaces for BASIC listing.
; Prints 2 * SYSVAR_SBC spaces (capped at 20 for max indent of 10 levels).
; Returns immediately if SBC is zero (no indentation).
;
SUB_INDENT:
    LD    A,(SYSVAR_SBC)            ;[2877] A = current indent level
    OR    A                         ;[287A] Is it zero?
    RET   Z                         ;[287B] Yes: no indentation
    CP    $0A                       ;[287C] Is it >= 10?
    JR    C,SUB_INDENT1             ;[287E] No: use as-is
    LD    A,$0A                     ;[2880] Yes: cap at 10 levels
SUB_INDENT1:
    RLCA                            ;[2882] A = level * 2 (2 spaces per indent level)
    LD    B,A                       ;[2883] B = number of spaces to print
SUB_INDENT_LOOP:
    CALL  DISPLAY_SPACE             ;[2884] Print one space
    DJNZ  SUB_INDENT_LOOP           ;[2887] Repeat B times
    RET                             ;[2889] 

;
; EAUTO: AUTO [start[,step]] -- enable automatic line numbering.
; Copies the default values (100 and 10) from DATA_AUTO into SYSVAR_AUTOST,
; then if arguments are given, evaluates and validates them (must be in float
; exponent range $C0..$C7, i.e. small positive integers), storing them in
; SYSVAR_AUTOST.  Sets SYSVAR_AUTOFL = 1 to enable AUTO mode.
;
EAUTO:
    LD    HL,DATA_AUTO              ;[288A] HL -> default AUTO data (100, 10 as floats)
    PUSH  DE                        ;[288D] Save parse pointer
    LD    DE,SYSVAR_AUTOST          ;[288E] DE -> AUTO start/step storage
    LD    BC,$000A                  ;[2891] BC = 10 (copy 10 bytes = two 5-byte floats)
    LDIR                            ;[2894] Copy defaults into SYSVAR_AUTOST
    POP   DE                        ;[2896] Restore parse pointer
    CP    $0D                       ;[2897] Is next token CR? (no arguments)
    JR    Z,EAUTOX                  ;[2899] Yes: use defaults, enable AUTO
EAUTO2:
    RST   $28                       ;[289B] Evaluate start line number -> WRA1
    LD    A,(SYSVAR_WRA1)           ;[289C] Read WRA1 exponent
    PUSH  DE                        ;[289F] Save parse pointer
    CP    $C0                       ;[28A0] Is exponent < $C0? (too small / zero)
EATOC:
    CALL  C,ERR_NUM_OUT_RANGE       ;[28A2] Yes: out of range error
    CP    $C7                       ;[28A5] Is exponent >= $C7? (too large)
EATONC:
    CALL  NC,ERR_NUM_OUT_RANGE      ;[28A7] Yes: out of range error
    LD    DE,SYSVAR_AUTOST          ;[28AA] DE -> AUTO start storage
    CALL  WRA1_TO_DE                ;[28AD] Store validated start value
    POP   DE                        ;[28B0] Restore parse pointer
    LD    A,(DE)                    ;[28B1] Read next token
    CP    $0D                       ;[28B2] Is it CR? (no step argument)
    JR    Z,EAUTOX                  ;[28B4] Yes: use default step
    INC   DE                        ;[28B6] Skip comma separator
    RST   $28                       ;[28B7] Evaluate step value -> WRA1
    LD    A,(SYSVAR_WRA1)           ;[28B8] Read WRA1 exponent
    CP    $C0                       ;[28BB] Is it < $C0?
    JR    C,EATOC                   ;[28BD] Yes: out of range
    CP    $F0                       ;[28BF] Is it >= $F0? (too large for step)
    JR    NC,EATONC                 ;[28C1] Yes: out of range
    LD    DE,$62F8                  ;[28C3] DE = SYSVAR_AUTOST + 5 (step storage = second float)
    CALL  WRA1_TO_DE                ;[28C6] Store validated step value
EAUTOX:
    LD    A,$01                     ;[28C9] A = 1 (AUTO enabled)
    LD    (SYSVAR_AUTOFL),A         ;[28CB] Set AUTO flag
    RET                             ;[28CE] 

;
; DATA_AUTO: default AUTO line number and step as 5-byte floats.
; First 5 bytes: 100.0; second 5 bytes: 10.0.
;
DATA_AUTO:
    DB $C2,$10,$00,$00,$00          ;[28CF] Float: 100.0 (default start)
    DB $C1,$10,$00,$00,$00          ;[28D4] Float: 10.0  (default step)

;
; FBIN: BIN() function -- convert a decimal integer whose digits are all 0 or 1
; into the binary value those digits represent (treating each digit as a bit).
; E.g. BIN(1010) = 10 (decimal).
; The value in WRA1 must be a small positive integer ($C0..$C7 exponent range).
; Returns the result as a float in WRA1.
;
FBIN:
    LD    A,(SYSVAR_WRA1)           ;[28D9] Read WRA1 exponent
    CP    $C0                       ;[28DC] Is it < $C0? (zero or negative)
    JP    C,LZERO                   ;[28DE] Yes: result is zero
    CP    $C8                       ;[28E1] Is it >= $C8? (more than 8 digits)
    CALL  NC,ERR_TYPE_MISMATCH      ;[28E3] Yes: type mismatch (too many bits)
    SUB   $BF                       ;[28E6] A = number of digits (exponent - $BF)
    LD    B,A                       ;[28E8] B = digit count
    LD    C,$00                     ;[28E9] C = result accumulator (bit pattern)
FBIN1:
    PUSH  BC                        ;[28EB] Save BC
    CALL  RL10                      ;[28EC] Rotate next BCD digit out of WRA1 into A (low 4 bits)
    POP   BC                        ;[28EF] Restore BC
    AND   $0F                       ;[28F0] Keep digit (0 or 1)
    CP    $02                       ;[28F2] Is digit >= 2? (invalid binary digit)
    CALL  NC,ERR_TYPE_MISMATCH      ;[28F4] Yes: not a binary digit, error
    CP    $01                       ;[28F7] Is digit 1?
    CCF                             ;[28F9] Complement carry: carry set if digit was 1
    RL    C                         ;[28FA] Rotate carry into C (shift in the bit)
    DJNZ  FBIN1                     ;[28FC] Repeat for all B digits
    LD    L,C                       ;[28FE] HL = result integer
    LD    H,$00                     ;[28FF] 
    JP    INTFP                     ;[2901] Convert to float in WRA1 and return

;
; EPROC: PROC name[(args)] -- call a named procedure.
; Pushes the current line pointer and ENDPRC ($04) frame marker onto the
; return stack (so ENDPROC can return here).  Searches for the procedure
; definition (DEFPROC) starting from SYSVAR_PROCST cache, or from SOB if
; not cached.  Jumps to the DEFPROC line via EGT3 (label-based search).
; If arguments are present, evaluates each expression and stores it into
; the corresponding parameter variable defined in the DEFPROC header.
;
EPROC:
    LD    HL,(SYSVAR_CURRLP)        ;[2904] HL = current line pointer
    CALL  PUSH_HL_RSTACK            ;[2907] Push return line pointer
    LD    A,ENDPRC                  ;[290A] A = ENDPRC marker ($04)
    CALL  PUSH_A_RSTACK             ;[290C] Push frame type marker
    LD    C,DEFPRC                  ;[290F] C = DEFPRC token ($02) = target to find
    LD    HL,(SYSVAR_PROCST)        ;[2911] HL = cached DEFPROC pointer
    LD    A,L                       ;[2914] Test HL for zero
    OR    H                         ;[2915] 
    PUSH  HL                        ;[2916] 
    POP   IX                        ;[2917] IX = cached pointer (may be 0)
    CALL  Z,EPROCS                  ;[2919] Zero: not cached, search from SOB -> IX, updates cache
    LD    C,DEFPRC                  ;[291C] C = DEFPRC (search target for EGT3)
    CALL  EGT3                      ;[291E] Find DEFPROC by name -> IX = DEFPROC line
    CP    CR                        ;[2921] Is next char CR? (no arguments)
    RET   Z                         ;[2923] Yes: no argument passing, done
EPROC1:
    LD    A,(DE)                    ;[2924] Read next char
    CP    ')'                       ;[2925] Is it ')' (end of argument list)?
    RET   Z                         ;[2927] Yes: done
    INC   HL                        ;[2928] Advance parameter pointer in DEFPROC header
    INC   DE                        ;[2929] Advance past separator in caller
    PUSH  HL                        ;[292A] Save parameter pointer
    RST   $28                       ;[292B] Evaluate argument expression -> WRA1
    POP   HL                        ;[292C] Restore parameter pointer
    PUSH  DE                        ;[292D] Save caller parse pointer
    EX    DE,HL                     ;[292E] DE = parameter pointer, HL = saved
    CALL  GET_VAR_ADDR              ;[292F] HL = address of parameter variable
    PUSH  DE                        ;[2932] Save parameter pointer
    INC   HL                        ;[2933] HL -> type byte of parameter variable
    RES   7,(HL)                    ;[2934] Clear bit 7 (mark variable as defined)
    DEC   HL                        ;[2936] HL -> variable base
    EX    DE,HL                     ;[2937] DE = variable address
    CALL  WRA1_TO_DE                ;[2938] Store argument value into parameter variable
    POP   HL                        ;[293B] Restore parameter pointer
    POP   DE                        ;[293C] Restore caller parse pointer
    JR    EPROC1                    ;[293D] Process next argument

;
; EPROCS: search for the first DEFPROC statement from SOB and cache the result.
; Updates SYSVAR_PROCST with the address of the first DEFPROC line found.
;
EPROCS:
    LD    IX,(SYSVAR_SOB)           ;[293F] IX = start of BASIC program
    CALL  FTL                       ;[2943] Scan forward for DEFPRC token -> IX
    CALL  C,ERR_NOT_FOUND           ;[2946] Not found: procedure does not exist
    LD    (SYSVAR_PROCST),IX        ;[2949] Cache pointer to first DEFPROC
    RET                             ;[294D] 

;
; IPROCS: tokenise procedure name into buffer.
; Copies characters from DE into HL until CR or '(' is found.
; If '(' is found, returns with HL pointing past it (arguments follow).
; If CR is found, pops the return address and returns to caller's caller.
;
IPROCS:
    LD    A,(DE)                    ;[294E] Read character
    INC   DE                        ;[294F] Advance input pointer
    LD    (HL),A                    ;[2950] Store in buffer
    CP    $0D                       ;[2951] Is it CR?
    JR    Z,IPRCS1                  ;[2953] Yes: no argument list, pop and return
    INC   HL                        ;[2955] Advance buffer pointer
    CP    $28                       ;[2956] Is it '('?
    JR    NZ,IPROCS                 ;[2958] No: keep copying name
    RET                             ;[295A] Yes: name copied, '(' stored, return

IPRCS1:
    POP   BC                        ;[295B] Pop return address (skip IPROC/IDEFPROC continuation)
    RET                             ;[295C] Return to caller's caller

;
; IPROC: tokeniser validation for PROC statement.
; Copies the procedure name (via IPROCS), then reads successive comma-separated
; argument expressions via RP, storing each in the buffer.
; Asserts closing ')' and CR at the end.
;
IPROC:
    CALL  IPROCS                    ;[295D] Copy procedure name into buffer
IPROC1:
    CALL  RP                        ;[2960] Tokenise next argument expression
    LD    (HL),A                    ;[2963] Store terminator (')' or ',')
    INC   HL                        ;[2964] 
    CP    ','                       ;[2965] Is it ','? (more arguments)
    JR    Z,IPROC1                  ;[2967] Yes: tokenise next argument
IPROCR:
    RST   $20                       ;[2969] Assert: ')' must follow
    DB    ')'                       ;[296A] Expected: ')'
    RST   $10                       ;[296B] Skip spaces
    JP    IEND                      ;[296C] Assert CR and return

;
; IDEFPROC: tokeniser validation for DEFPROC statement.
; Copies the procedure name (via IPROCS), then reads successive comma-separated
; parameter variable names.  Each parameter is stored as its token byte followed
; by a '$' or plain letter.
;
IDEFPROC:
    CALL  IPROCS                    ;[296F] Copy procedure name into buffer
IDFPR1:
    RST   $10                       ;[2972] Skip spaces
    CALL  TEST_ALPHA                ;[2973] Is next char alphabetic?
    CALL  C,ERR_SYNTAX              ;[2976] No: syntax error
    LD    (HL),A                    ;[2979] Store parameter letter token
    INC   DE                        ;[297A] Advance past letter
    RST   $10                       ;[297B] Skip spaces
    INC   HL                        ;[297C] Advance buffer
    LD    A,(DE)                    ;[297D] Read next char (could be '$', ',', or ')')
    LD    (HL),A                    ;[297E] Store it
    INC   HL                        ;[297F] 
    INC   DE                        ;[2980] Advance past it
    CP    ','                       ;[2981] Is it ','? (more parameters)
    JR    Z,IDFPR1                  ;[2983] Yes: read next parameter
    JP    IPROCR                    ;[2985] No: assert ')' and CR

;
; EENDPROC: ENDPROC statement -- return from a named procedure.
; Pops the frame type from the return stack and verifies it is ENDPRC ($04).
; Then calls EEPRN1 to pop the saved line pointer and restore CURRLP.
;
EENDPROC:
    CALL  POP_A_RSTACK              ;[2988] Pop frame type byte
    CP    ENDPRC                    ;[298B] Is it ENDPRC ($04)?
    CALL  NZ,ERR_ENDPROC_NO_PROC    ;[298D] No: ENDPROC without PROC
    JP    EEPRN1                    ;[2990] Pop return line pointer and resume

;
; PRINT_HEX: handle PRINT # expression -- print value as hexadecimal.
; Advances DE past '#', evaluates the expression, converts to integer,
; prints as 4 hex digits via PHEXHL, then prints 'H' suffix.
; Falls through into EPRINT to handle any further PRINT items.
;
PRINT_HEX:
    INC   DE                        ;[2993] Advance past '#'
    RST   $28                       ;[2994] Evaluate expression -> WRA1
    PUSH  DE                        ;[2995] Save parse pointer
    CALL  FPINT                     ;[2996] Convert WRA1 to integer -> HL
    POP   DE                        ;[2999] Restore parse pointer
    CALL  PHEXHL                    ;[299A] Print HL as 4 hex digits
    LD    A,'H'                     ;[299D] Print 'H' suffix
    RST   $08                       ;[299F] 
    JP    EPRINT                    ;[29A0] Continue with next PRINT item

;
; EPRT3: handle PRINT of a numeric expression (SOP token encountered).
; Evaluates the Polish expression, prints the result, then continues.
;
EPRT3:
    RST   $28                       ;[29A3] Evaluate expression -> WRA1
    PUSH  DE                        ;[29A4] Save parse pointer
    CALL  PN                        ;[29A5] Print WRA1 as decimal number
    POP   DE                        ;[29A8] Restore parse pointer

;
; EPRINT: PRINT statement handler.
; Scans the tokenised PRINT argument list at DE, dispatching on each separator:
;   CR        -> print newline (unless C=1 from ';')
;   ','       -> print TAB character ($09)
;   ';'       -> set C=1 (suppress trailing newline), advance
;   '#'       -> print next expression as hex (PRINT_HEX)
;   SOP ($7D) -> evaluate and print numeric expression (EPRT3)
;   TAB token -> position cursor to column (PRINT_TAB)
;   AT token  -> position cursor at x,y (PRINT_AT)
;   other     -> evaluate as string expression and print
; C=0 at entry; set to 1 by ';' to suppress the trailing CR.
;
EPRINT:
    LD    C,$00                     ;[29A9] C = 0 (no semicolon seen yet)
EPRT1:
    LD    A,(DE)                    ;[29AB] Read next PRINT item token
    CP    CR                        ;[29AC] End of PRINT statement?
    JR    Z,EPRTX                   ;[29AE] Yes: handle trailing newline
    CP    ','                       ;[29B0] Comma separator?
    JR    Z,EPRT2                   ;[29B2] Yes: print TAB
    CP    ';'                       ;[29B4] Semicolon separator?
    JR    Z,EPRT4                   ;[29B6] Yes: suppress newline
    CP    '#'                       ;[29B8] Hash = hex print?
    JR    Z,PRINT_HEX               ;[29BA] Yes: print as hex
    CP    SOP                       ;[29BC] SOP ($7D) = start of numeric expression?
    JR    Z,EPRT3                   ;[29BE] Yes: evaluate and print number
    CP    TAB                       ;[29C0] TAB token ($DE)?
    JP    Z,PRINT_TAB               ;[29C2] Yes: handle TAB(n)
    CP    AT                        ;[29C5] AT token ($D9)?
    JP    Z,PRINT_AT                ;[29C7] Yes: handle AT x,y
EPRT6:
    CALL  STRING_EXEC               ;[29CA] Evaluate string expression -> SYSVAR_STRBUF
    LD    HL,SYSVAR_STRBUF          ;[29CD] HL -> evaluated string result
EPRT8:
    CALL  PRTSTR                    ;[29D0] Print the string
    JP    EPRINT                    ;[29D3] Continue with next PRINT item

EPRTX:
    LD    A,C                       ;[29D6] A = semicolon flag
    OR    A                         ;[29D7] Was ';' the last separator?
    RET   NZ                        ;[29D8] Yes: suppress newline, return
    LD    A,CR                      ;[29D9] No: print CR
    RST   $08                       ;[29DB] 
    RET                             ;[29DC] 

EPRT2:
    LD    A,$09                     ;[29DD] A = TAB character ($09)
    RST   $08                       ;[29DF] Print TAB
EPRT4:
    LD    C,$01                     ;[29E0] C = 1 (semicolon/comma seen: suppress newline)
    INC   DE                        ;[29E2] Advance past separator
    JR    EPRT1                     ;[29E3] Process next PRINT item

;
; PRINT_TAB: handle TAB(n) in a PRINT statement.
; Evaluates n, computes the target cursor X position as (n*2 + current_zone),
; and sets SYSVAR_CURSORX to that position via VDU 30 (set cursor X).
; If the cursor is already past the target, does nothing (no wrap).
;
PRINT_TAB:
    INC   DE                        ;[29E5] Advance past TAB token
    RST   $18                       ;[29E6] Evaluate TAB argument -> integer in HL (A = L)
    RLCA                            ;[29E7] A = n * 2 (cursor X units are 2-pixel steps)
    ADD   A,L                       ;[29E8] A = n*2 + L (add back L for zone offset?)
    LD    HL,(SYSVAR_CURSORX)       ;[29E9] HL = current cursor X (low byte = X)
    CP    L                         ;[29EC] Is target <= current X?
    JR    C,PRINT_NEXT              ;[29ED] Yes: already past target, skip
    LD    (SYSVAR_CURSORX),A        ;[29EF] Store new cursor X
    LD    A,$1E                     ;[29F2] VDU $1E = set cursor position
    RST   $08                       ;[29F4] Send it
PRINT_NEXT:
    JP    EPRINT                    ;[29F5] Continue with next PRINT item

;
; PRINT_AT: handle AT x,y in a PRINT statement.
; Evaluates x and y expressions and stores them in SYSVAR_CURSORX/CURSORY,
; then continues PRINT processing.
;
PRINT_AT:
    INC   DE                        ;[29F8] Advance past AT token
    RST   $18                       ;[29F9] Evaluate x expression -> integer in HL
    LD    (SYSVAR_CURSORX),HL       ;[29FA] Store x (low byte) and y (high byte? via HL store)
    INC   DE                        ;[29FD] Skip comma separator
    RST   $18                       ;[29FE] Evaluate y expression -> integer in HL (A = L)
    LD    (SYSVAR_CURSORY),A        ;[29FF] Store y coordinate
    JR    PRINT_NEXT                ;[2A02] Continue PRINT


;
; IPRTH: tokeniser for PRINT '#' (hex print) item.
; Stores '#' in the buffer, advances DE and HL, then falls into VALIDATE_PRINT1A
; to tokenise the expression argument.
;
IPRTH:
    LD    (HL),A                    ;[2A04] Store '#' in buffer
    INC   DE                        ;[2A05] Advance past '#'
    INC   HL                        ;[2A06] Advance buffer pointer
    JR    VALIDATE_PRINT1A          ;[2A07] Tokenise the expression

;
; IPT4: tokenise a string expression item in a PRINT statement.
;
IPT4:
    CALL  READ_STRING_EXPR          ;[2A09] Tokenise string expression into buffer at HL
    JR    IPT5                      ;[2A0C] Skip spaces and continue

;
; IPT2: skip a separator (',' or ';') in a PRINT tokeniser argument list.
;
IPT2:
    INC   HL                        ;[2A0E] Advance buffer pointer (store separator later)
    INC   DE                        ;[2A0F] Advance past separator
IPT5:
    RST   $10                       ;[2A10] Skip spaces; A = next non-space char

;
; IPRINT1: tokeniser validation for PRINT statement.
; Reads and stores successive PRINT items into the token buffer at HL.
; Handles: CR (end), '#' (hex), ',' and ';' (separators), string expressions,
; TAB ($DE) and AT ($D9) tokens, and numeric expressions via RP.
;
IPRINT1:
    LD    (HL),A                    ;[2A11] Store current character in buffer
    CP    $0D                       ;[2A12] Is it CR?
    RET   Z                         ;[2A14] Yes: done
    CP    $23                       ;[2A15] Is it '#'?
    JR    Z,IPRTH                   ;[2A17] Yes: hex print item
    CP    $2C                       ;[2A19] Is it ','?
    JR    Z,IPT2                    ;[2A1B] Yes: comma separator
    CP    $3B                       ;[2A1D] Is it ';'?
    JR    Z,IPT2                    ;[2A1F] Yes: semicolon separator
    CALL  TEST_FOR_STR_EXP          ;[2A21] Is this a string expression?
    JR    Z,IPT4                    ;[2A24] Yes: tokenise as string expression
    PUSH  DE                        ;[2A26] Save input pointer
    CALL  TKSL                      ;[2A27] Try to tokenise next word
    JR    C,IPRTP3                  ;[2A2A] Carry: not a keyword, tokenise as numeric expr
    CP    $DE                       ;[2A2C] Is it TAB ($DE)?
    JR    Z,IPRTP1                  ;[2A2E] Yes: store TAB token
    CP    $D9                       ;[2A30] Is it AT ($D9)?
    JR    NZ,IPRTP3                 ;[2A32] No: not a known PRINT keyword, treat as expression
    POP   BC                        ;[2A34] Discard saved DE (AT path: DE already advanced)
    LD    (HL),A                    ;[2A35] Store AT token ($D9) in buffer
    INC   HL                        ;[2A36] 
    CALL  RP                        ;[2A37] Tokenise first AT argument (x)
    RST   $20                       ;[2A3A] Assert: comma must follow
    INC   L                         ;[2A3B] (adjusts HL after RST $20 stores separator)
    JR    IPRTP2                    ;[2A3C] Store separator and tokenise second argument
IPRTP1:
    POP   BC                        ;[2A3E] Discard saved DE (TAB path)
IPRTP2:
    LD    (HL),A                    ;[2A3F] Store separator/token in buffer
    INC   HL                        ;[2A40] 
    PUSH  DE                        ;[2A41] (save DE for IPRTP3 to restore)
IPRTP3:
    POP   DE                        ;[2A42] Restore input pointer
VALIDATE_PRINT1A:
    CALL  RP                        ;[2A43] Tokenise expression into buffer
    CP    $80                       ;[2A46] Is terminator >= $80? (token, not ASCII)
    CALL  NC,ERR_SYNTAX             ;[2A48] Yes: unexpected token, syntax error
    DEC   DE                        ;[2A4B] Back up DE to point to the terminator byte
    JR    IPRINT1                   ;[2A4C] Store terminator and continue

;
; ERESERVE: RESERVE n -- reserve n bytes of memory by moving the stack pointer.
; Evaluates n (RST $18 -> DE).  Checks that the new stack base (STACK - n) is
; within safe bounds: above STACK-256 (guard page) and below TOV+512.
; Copies 256 bytes from the current stack top to the new position, adjusts
; SYSVAR_STACK and SP accordingly.
;
ERESERVE:
    RST   $18                       ;[2A4E] Evaluate n -> integer in HL (DE = n)
    EX    DE,HL                     ;[2A4F] DE = n (bytes to reserve), HL = other
    LD    HL,(SYSVAR_STACK)         ;[2A50] HL = current HIMEM/stack base
    INC   HL                        ;[2A53] 
    INC   HL                        ;[2A54] HL = STACK + 2
    PUSH  HL                        ;[2A55] Save STACK+2
    OR    A                         ;[2A56] Clear carry
    SBC   HL,DE                     ;[2A57] HL = (STACK+2) - n = new stack base
    CALL  C,ERR_NUM_OUT_RANGE       ;[2A59] Underflow: n too large
    LD    HL,(SYSVAR_TOV)           ;[2A5C] HL = top of variables
    INC   H                         ;[2A5F] HL += 512 (safety margin above variables)
    INC   H                         ;[2A60] 
    SBC   HL,DE                     ;[2A61] Check new stack won't collide with variables
    CALL  NC,ERR_NUM_OUT_RANGE      ;[2A63] No carry: stack too close to variables
    POP   HL                        ;[2A66] HL = STACK + 2 (old stack top)
    DEC   H                         ;[2A67] HL = old stack area high page
    DEC   D                         ;[2A68] DE = n - 256 (page-sized shift)
    LD    BC,$0100                  ;[2A69] BC = 256 (one page)
    LDIR                            ;[2A6C] Copy 256 bytes from old stack area to new position
    OR    A                         ;[2A6E] Clear carry
    EX    DE,HL                     ;[2A6F] 
    SBC   HL,DE                     ;[2A70] HL = delta (amount stack moved)
    EX    DE,HL                     ;[2A72] DE = delta
    LD    HL,(SYSVAR_STACK)         ;[2A73] HL = SYSVAR_STACK
    ADD   HL,DE                     ;[2A76] HL = new stack base
    LD    (SYSVAR_STACK),HL         ;[2A77] Update SYSVAR_STACK
    EX    DE,HL                     ;[2A7A] DE = new stack base
    ADD   HL,SP                     ;[2A7B] HL = new SP (adjust by same delta)
    LD    SP,HL                     ;[2A7C] Update stack pointer
    RET                             ;[2A7D] 

;
; ERENUM: RENUM [start[,step]] -- renumber BASIC program lines.
; Uses EAUTO to parse and validate the start/step arguments (stored in
; SYSVAR_AUTOST), then clears AUTOFL.
; Pass 1 (REN/REN5): scans every line, finds GOTO/GOSUB/RUN/RESTORE targets
; that use numeric line numbers (SOP + NUM token), looks up the old line number
; in the program to find its position, computes the new number using the
; start/step stored in AUTOST, and updates the 5-byte float in the token stream.
; Pass 2 (REN7/REN8): renumbers the line header floats sequentially starting
; from AUTOST, incrementing by AUTOST+5 each time.
;
ERENUM:
    CALL  EAUTO                     ;[2A7E] Parse RENUM arguments into SYSVAR_AUTOST
    XOR   A                         ;[2A81] A = 0
    LD    (SYSVAR_AUTOFL),A         ;[2A82] Clear AUTO flag (EAUTO may have set it)
REN:
    LD    IX,(SYSVAR_SOB)           ;[2A85] IX = start of BASIC program
REN5:
    LD    A,(IX+$00)                ;[2A89] Read first byte of line
    CP    $80                       ;[2A8C] End of program?
    JR    Z,REN7                    ;[2A8E] Yes: pass 1 done, begin pass 2
    PUSH  IX                        ;[2A90] Save current line pointer
    CALL  SKIP_LNUM                 ;[2A92] DE -> first token of line
    LD    A,(DE)                    ;[2A95] Read command token
    CP    IF                        ;[2A96] Is it IF ($27)?
    JR    NZ,REN1                   ;[2A98] No: check for GOTO etc.
REN6:
    CALL  ADV                       ;[2A9A] Advance DE past one token/sub-expression
    LD    A,(DE)                    ;[2A9D] Read next token
    CP    THEN                      ;[2A9E] Is it THEN ($D7)?
    JR    NZ,REN6                   ;[2AA0] No: keep scanning past IF condition
    INC   DE                        ;[2AA2] Skip THEN token
    LD    A,(DE)                    ;[2AA3] Read token after THEN
REN1:
    CP    ELSE                      ;[2AA4] Is it ELSE ($3C)?
    JR    NZ,REN2                   ;[2AA6] No: check for jump statements
    INC   DE                        ;[2AA8] Skip ELSE token
    LD    A,(DE)                    ;[2AA9] Read token after ELSE
REN2:
    CP    GOTO                      ;[2AAA] Is it GOTO ($10)?
    JR    Z,REN3                    ;[2AAC] Yes: has a line number target
    CP    RUN                       ;[2AAE] Is it RUN ($14)?
    JR    Z,REN3                    ;[2AB0] Yes
    CP    GOSUB                     ;[2AB2] Is it GOSUB ($11)?
    JR    Z,REN3                    ;[2AB4] Yes
    CP    RESTOR                    ;[2AB6] Is it RESTORE ($20)?
    JR    NZ,REN4                   ;[2AB8] None of the above: skip this line
REN3:
    INC   DE                        ;[2ABA] Advance past the jump token
    LD    A,(DE)                    ;[2ABB] Read next byte (should be SOP)
    CP    SOP                       ;[2ABC] Is it SOP ($7D)?
    JR    NZ,REN4                   ;[2ABE] No: not a simple numeric target
    INC   DE                        ;[2AC0] Skip SOP
    LD    A,(DE)                    ;[2AC1] Read next byte (should be NUM)
    CP    NUM                       ;[2AC2] Is it NUM ($7E = numeric literal)?
    JR    NZ,REN4                   ;[2AC4] No: not a plain number
    INC   DE                        ;[2AC6] Skip NUM token
    PUSH  DE                        ;[2AC7] Save pointer to 5-byte line number float
    EX    DE,HL                     ;[2AC8] HL = pointer to old line number float
    CALL  LNUM1                     ;[2AC9] Load old line number into WRA1
    CALL  FNDLN_WRA1                ;[2ACC] Find that line in program -> IX, BC = line index
    LD    L,C                       ;[2ACF] HL = line index (BC from FNDLN_WRA1)
    LD    H,B                       ;[2AD0] 
    CALL  INTFP                     ;[2AD1] Convert line index to float in WRA1
    LD    HL,SYSVAR_AUTOST+5        ;[2AD4] HL -> step value (second float in AUTOST)
    CALL  LNUM2                     ;[2AD7] Load step into WRA2
    CALL  _MULT                     ;[2ADA] WRA1 = index * step
    LD    HL,SYSVAR_AUTOST          ;[2ADD] HL -> start value (first float in AUTOST)
    CALL  LNUM2                     ;[2AE0] Load start into WRA2
    CALL  ADD                       ;[2AE3] WRA1 = (index * step) + start = new line number
    POP   DE                        ;[2AE6] Restore pointer to old float in token stream
    CALL  WRA1_TO_DE                ;[2AE7] Overwrite old line number with new number
REN4:
    POP   IX                        ;[2AEA] Restore line pointer
    CALL  NEXT_LINE                 ;[2AEC] Advance to next line
    JR    REN5                      ;[2AEF] Continue pass 1

REN7:
    LD    IX,(SYSVAR_SOB)           ;[2AF1] Pass 2: IX = start of program
    LD    HL,SYSVAR_AUTOST          ;[2AF5] HL -> start value
    CALL  LNUM1                     ;[2AF8] Load start line number into WRA1
REN8:
    LD    A,(IX+$00)                ;[2AFB] Read first byte of line
    CP    $80                       ;[2AFE] End of program?
    RET   Z                         ;[2B00] Yes: done
    PUSH  IX                        ;[2B01] 
    POP   DE                        ;[2B03] DE = current line pointer
    PUSH  DE                        ;[2B04] Save it
    CALL  WRA1_TO_DE                ;[2B05] Write new line number float into line header
    LD    HL,$62F8                  ;[2B08] HL -> SYSVAR_AUTOST+5 (step float)
    CALL  LNUM2                     ;[2B0B] Load step into WRA2
    CALL  ADD                       ;[2B0E] WRA1 = current + step (next line number)
    POP   IX                        ;[2B11] Restore line pointer
    CALL  NEXT_LINE                 ;[2B13] Advance IX to next line
    JR    REN8                      ;[2B16] Renumber next line

;
; FINDLN: find a BASIC line by number (in WRA1).
; Calls FNDLN_WRA1; if the line is not found (NZ), calls ERR_NOT_FOUND.
;
FINDLN:
    CALL  FNDLN_WRA1                ;[2B18] Search for line -> IX, Z if found
    CALL  NZ,ERR_NOT_FOUND          ;[2B1B] Not found: error
    RET                             ;[2B1E] 

;
; FNDLN_WRA1: find the BASIC line whose number matches the float in WRA1.
; Scans the program from SOB forward.  Each line's 5-byte line number (at IX+0)
; is compared byte-by-byte with WRA1.  Returns IX -> matching line, Z set if
; exact match found.  If the current line number exceeds WRA1, returns IX ->
; that line (insertion point), Z clear.  BC = number of lines scanned.
;
FNDLN_WRA1:
    LD    IX,(SYSVAR_SOB)           ;[2B1F] IX = start of BASIC program
    LD    BC,$0000                  ;[2B23] BC = line count
FLN1:
    LD    A,(IX+$00)                ;[2B26] Read first byte of line
    CP    $80                       ;[2B29] End-of-program marker?
    JR    Z,FLN3                    ;[2B2B] Yes: not found, return NZ
    PUSH  IX                        ;[2B2D] 
    POP   DE                        ;[2B2F] DE = current line pointer
    LD    HL,SYSVAR_WRA1            ;[2B30] HL -> target line number float
    PUSH  BC                        ;[2B33] Save line count
    LD    B,$05                     ;[2B34] B = 5 (bytes to compare)
FLN2:
    LD    A,(DE)                    ;[2B36] Read byte from line header
    CP    (HL)                      ;[2B37] Compare with WRA1 byte
    JR    C,FLN4                    ;[2B38] Line number < WRA1: keep searching
    JR    NZ,FLN5                   ;[2B3A] Line number > WRA1: gone past it (NZ = not found)
    INC   HL                        ;[2B3C] Equal so far: advance both pointers
    INC   DE                        ;[2B3D] 
    DJNZ  FLN2                      ;[2B3E] Compare all 5 bytes
FLN5:
    POP   BC                        ;[2B40] Restore line count
    RET                             ;[2B41] Z set if all 5 bytes matched (exact match)

FLN4:
    POP   BC                        ;[2B42] Restore line count
    INC   BC                        ;[2B43] Increment line count
    CALL  NEXT_LINE                 ;[2B44] Advance IX to next line
    JR    FLN1                      ;[2B47] Try next line

FLN3:
    OR    A                         ;[2B49] Clear Z flag (not found: end-of-program hit)
    RET                             ;[2B4A] Return NZ

;
; TEST_FOR_STR_EXP: test whether the current position in the input at DE is
; the start of a string expression.
; Returns Z set if: the next non-space char is '"' (string literal), or the
; next token is a string variable (ends in '$'), or the next keyword token is
; in the range CHR ($DF) .. STR ($E6) (string functions).
;
TEST_FOR_STR_EXP:
    RST   $10                       ;[2B4B] Skip spaces; A = next non-space char
    CP    $22                       ;[2B4C] Is it '"'? (string literal)
    RET   Z                         ;[2B4E] Yes: Z set (is a string expression)
    CALL  TEST_FOR_STRING           ;[2B4F] Is it a string variable (ends '$')?
    RET   Z                         ;[2B52] Yes: Z set
    PUSH  DE                        ;[2B53] Save input pointer
    CALL  TKSL                      ;[2B54] Try to tokenise next word -> A
    POP   DE                        ;[2B57] Restore input pointer (don't advance DE)
    CP    CHR                       ;[2B58] Is token < CHR ($DF)?
    RET   C                         ;[2B5A] Yes: not a string function token, carry set, NZ
    CP    STR+1                     ;[2B5B] Is token > STR ($E6)?
    DEC   A                         ;[2B5D] (adjust A for return value)
    RET   NC                        ;[2B5E] Yes: not in string function range, NZ
    CP    A                         ;[2B5F] Set Z (token is in CHR..STR range = string function)
    RET                             ;[2B60] Return Z set

;
; SEINT: evaluate a bracketed integer sub-expression in a string context.
; Asserts SOP ($7D) at DE, evaluates the expression via EE1, converts to
; integer via FPINT.  Returns integer in HL.  IX is preserved.
;
SEINT:
    PUSH  IX                        ;[2B61] Save IX
    LD    A,(DE)                    ;[2B63] Read next token
    RST   $20                       ;[2B64] Assert: must be SOP ($7D)
    DB    SOP                       ;[2B65] Expected: SOP = start-of-polish
    INC   DE                        ;[2B66] Advance past SOP
    CALL  EE1                       ;[2B67] Evaluate expression -> WRA1
    CALL  FPINT                     ;[2B6A] Convert WRA1 to integer -> HL
    POP   IX                        ;[2B6D] Restore IX
    RET                             ;[2B6F] 

;
; STRDVR: string-building output driver.
; Stores character A at (IX) and increments IX.
; Used as a substitute display driver so PN can write into a string buffer
; instead of to the screen (see FSTR_STRING).
;
STRDVR:
    LD    (IX+0),A                  ;[2B70] Store character at IX
    INC   IX                        ;[2B73] Advance string buffer pointer
    RET                             ;[2B75] 

;
; FSTR_STRING: STR$() function -- convert a numeric expression to a string.
; Evaluates the numeric expression via EE1, then temporarily replaces the
; display driver (SYSVAR_PRINTD) with STRDVR so that PN writes into IX
; (pointing at SYSVAR_STRBUF) instead of to the screen.  Restores the
; original driver afterwards.
;
FSTR_STRING:
    PUSH  IX                        ;[2B76] Save IX (string buffer pointer)
    INC   DE                        ;[2B78] Advance past SOP
    CALL  EE1                       ;[2B79] Evaluate numeric expression -> WRA1
    POP   IX                        ;[2B7C] Restore IX (= SYSVAR_STRBUF via STRING_EXEC)
    PUSH  DE                        ;[2B7E] Save parse pointer
    LD    HL,(SYSVAR_PRINTD)        ;[2B7F] HL = current display driver address
    PUSH  HL                        ;[2B82] Save it
    LD    HL,STRDVR                 ;[2B83] HL = string-building driver
    LD    (SYSVAR_PRINTD),HL        ;[2B86] Install string driver
    CALL  PN                        ;[2B89] Print WRA1 into string buffer via STRDVR
    POP   HL                        ;[2B8C] Restore original display driver
    LD    (SYSVAR_PRINTD),HL        ;[2B8D] Re-install it
    POP   DE                        ;[2B90] Restore parse pointer
    JR    ESECT1                    ;[2B91] Advance DE and terminate string

;
; FKEY_STRING: INKEY$ function -- return the currently-pressed key as a
; one-character string, or empty string if no key is pressed.
;
FKEY_STRING:
    CALL  KEY                       ;[2B93] Poll keyboard -> A (0 = no key)
    OR    A                         ;[2B96] Any key pressed?
    JR    Z,ESECT                   ;[2B97] No: return empty string

;
; GET_STRING: store character A as a one-character string at (IX), then
; terminate and return.  Used by FKEY_STRING and FGET_STRING.
;
GET_STRING:
    LD    (IX+$00),A                ;[2B99] Store character in string buffer
    INC   IX                        ;[2B9C] Advance string buffer pointer
    JR    ESECT                     ;[2B9E] Terminate string and return

;
; FGET_STRING: GET$ function -- wait for a key press and return it as a
; one-character string.  Loops until KEY returns non-zero.
;
FGET_STRING:
    CALL  KEY                       ;[2BA0] Poll keyboard -> A
    OR    A                         ;[2BA3] Key pressed?
    JR    Z,FGET_STRING             ;[2BA4] No: keep waiting
    JR    GET_STRING                ;[2BA6] Yes: store character and return

;
; FUPC_STRING: UPC$() function -- convert a string variable to upper case.
; Reads the string variable pointer via SYSVAR_VRPTS (HL -> string data).
; Scans characters: if in range 'a'..'z', clears bit 5 (converts to upper).
; Copies each character into IX (string buffer), stops at SZ (CR = end).
;
FUPC_STRING:
    CALL  SYSVAR_VRPTS              ;[2BA8] HL -> string variable data
ESEUP1:
    LD    A,(HL)                    ;[2BAB] Read character
    CP    SZ                        ;[2BAC] Is it SZ ($0D = string end)?
    JR    Z,ESECT1                  ;[2BAE] Yes: terminate and return
    CP    'a'                       ;[2BB0] Is it below 'a'?
    JR    C,ESEUP2                  ;[2BB2] Yes: not lowercase, copy as-is
    CP    'z'+1                     ;[2BB4] Is it above 'z'?
    JR    NC,ESEUP2                 ;[2BB6] Yes: not lowercase, copy as-is
    RES   5,A                       ;[2BB8] Clear bit 5: convert 'a'-'z' to 'A'-'Z'
ESEUP2:
    LD    (IX+$00),A                ;[2BBA] Store character in output buffer
    INC   IX                        ;[2BBD] Advance output pointer
    INC   HL                        ;[2BBF] Advance source pointer
    JR    ESEUP1                    ;[2BC0] Loop

;
; ESECT1: advance DE past the current string function token, then fall into
; ESECT to terminate the string in the buffer and check for concatenation.
;
ESECT1:
    INC   DE                        ;[2BC2] Advance parse pointer past string function token

;
; ESECT: terminate the string currently being built in SYSVAR_STRBUF at IX,
; write SZ ($0D) as end marker, and check for string concatenation ('+').
; If a '+' follows in the token stream (DE), continues building the string
; via ESE1.  Also checks that the string does not exceed 255 bytes (high byte
; of offset from SYSVAR_STRBUF must be zero).
;
ESECT:
    PUSH  IX                        ;[2BC3] 
    POP   HL                        ;[2BC5] HL = current end of string buffer
    LD    (HL),SZ                   ;[2BC6] Write SZ ($0D) string terminator
    PUSH  HL                        ;[2BC8] Save end pointer
    LD    BC,SYSVAR_STRBUF          ;[2BC9] BC = string buffer base
    OR    A                         ;[2BCC] Clear carry
    SBC   HL,BC                     ;[2BCD] HL = length of string so far
    INC   H                         ;[2BCF] 
    DEC   H                         ;[2BD0] Test H: is it zero?
    CALL  NZ,ERR_STRING             ;[2BD1] Non-zero: string > 255 bytes, error
    POP   IX                        ;[2BD4] Restore IX = end of string (after SZ)
    LD    A,(DE)                    ;[2BD6] Read next token
    CP    $2B                       ;[2BD7] Is it '+'? (string concatenation)
    RET   NZ                        ;[2BD9] No: done
    INC   DE                        ;[2BDA] Skip '+'
    JR    ESE1                      ;[2BDB] Continue building concatenated string

;
; STRING_EXEC: evaluate a string expression from the token stream at DE into
; SYSVAR_STRBUF.  Sets up IY = SYSVAR_CSTACK and IX = SYSVAR_STRBUF, then
; dispatches on the first token to the appropriate string function handler.
; Handles: '"' (literal), string variable, UPC$ ($E3), STR$ ($E6), GET$ ($E5),
; INKEY$ ($E4), CHR$ ($DF), LEFT$ ($E0), RIGHT$ ($E1), MID$ ($E2).
;
STRING_EXEC:
    LD    IY,SYSVAR_CSTACK          ;[2BDD] IY -> calculator stack
ESEE:
    LD    IX,SYSVAR_STRBUF          ;[2BE1] IX -> string result buffer
ESE1:
    LD    A,(DE)                    ;[2BE5] Read next token
    CP    $22                       ;[2BE6] Is it '"'? (string literal)
    JR    Z,ESE2                    ;[2BE8] Yes: copy literal
    CALL  TEST_FOR_STRING           ;[2BEA] Is it a string variable?
    JR    Z,ESE3                    ;[2BED] Yes: copy string variable content
    LD    A,(DE)                    ;[2BEF] Read token (for function dispatch)
    INC   DE                        ;[2BF0] Advance past token
    CP    UPCS                      ;[2BF1] UPC$ ($E3)?
    JR    Z,FUPC_STRING             ;[2BF3] Yes
    CP    STR                       ;[2BF5] STR$ ($E6)?
    JP    Z,FSTR_STRING             ;[2BF7] Yes
    CP    GETS                      ;[2BFA] GET$ ($E5)?
    JR    Z,FGET_STRING             ;[2BFC] Yes
    CP    INKEYS                    ;[2BFE] INKEY$ ($E4)?
    JR    Z,FKEY_STRING             ;[2C00] Yes
    CP    CHR                       ;[2C02] CHR$ ($DF)?
    JR    Z,FCHR_STRING             ;[2C04] Yes
    CP    LEFT                      ;[2C06] LEFT$ ($E0)?
    JR    Z,FLEFT_STRING            ;[2C08] Yes
    CP    RIGHT                     ;[2C0A] RIGHT$ ($E1)?
    JR    Z,FRIGHT_STRING           ;[2C0C] Yes
    CP    MID                       ;[2C0E] MID$ ($E2)?
    JR    Z,FMID_STRING             ;[2C10] Yes
    CALL  ERR_SOMETHG_MISSG         ;[2C12] None matched: error

ESE2:
    INC   DE                        ;[2C15] Skip opening '"'
    LD    B,$00                     ;[2C16] B = 0 (no length limit for STRING_SEEK_END)
    EX    DE,HL                     ;[2C18] HL = source pointer (into tokenised string)
    CALL  STRING_SEEK_END           ;[2C19] Copy string chars from HL into IX until '"' or SZ
    EX    DE,HL                     ;[2C1C] DE = updated source pointer
    INC   DE                        ;[2C1D] Skip closing '"'
    JR    ESECT                     ;[2C1E] Terminate and check for '+'

ESE3:
    CALL  SYSVAR_VRPTS              ;[2C20] HL -> string variable data, B = max length
    CALL  STRING_SEEK_END           ;[2C23] Copy string from HL into IX until end
    JR    ESECT                     ;[2C26] Terminate and check for '+'

;
; FCHR_STRING: CHR$() function -- convert an integer to a one-character string.
; Evaluates the bracketed integer argument via SEINT -> HL.
; Stores L (the character code) at IX and advances IX, then terminates.
;
FCHR_STRING:
    CALL  SEINT                     ;[2C28] Evaluate integer argument -> HL (L = char code)
    LD    (IX+$00),L                ;[2C2B] Store character in string buffer
    INC   IX                        ;[2C2E] Advance string buffer pointer
    JR    ESECT1                    ;[2C30] Advance DE and terminate string

;
; FLEFT_STRING: LEFT$(str$, n) -- return leftmost n characters of a string.
; Gets the string variable pointer (HL -> string data), evaluates n via SEINT,
; copies up to n characters via PATCH6, then terminates.
;
FLEFT_STRING:
    CALL  SYSVAR_VRPTS              ;[2C32] HL -> string variable data, B = max length
    PUSH  HL                        ;[2C35] Save string pointer
    INC   DE                        ;[2C36] Skip comma separator
    CALL  SEINT                     ;[2C37] Evaluate n -> HL (L = count)
    LD    B,L                       ;[2C3A] B = n (character count)
    POP   HL                        ;[2C3B] Restore string pointer
    CALL  PATCH6                    ;[2C3C] Copy B characters from HL to IX
    JR    ESECT1                    ;[2C3F] Advance DE and terminate

;
; FMID_STRING: MID$(str$, start, length) -- return a substring.
; Gets string pointer, evaluates start position (1-based), skips start-1 chars,
; evaluates length, copies that many characters via PATCH6, then terminates.
;
FMID_STRING:
    CALL  SYSVAR_VRPTS              ;[2C41] HL -> string variable data
    INC   DE                        ;[2C44] Skip comma before start argument
    PUSH  HL                        ;[2C45] Save string pointer
    CALL  SEINT                     ;[2C46] Evaluate start position -> HL (L = start, 1-based)
    INC   DE                        ;[2C49] Skip comma before length argument
    PUSH  HL                        ;[2C4A] Save start position (L = start)
    CALL  SEINT                     ;[2C4B] Evaluate length -> HL (L = length)
    LD    C,L                       ;[2C4E] C = length
    POP   HL                        ;[2C4F] HL = start position
    LD    B,L                       ;[2C50] B = start (1-based skip count)
ESE72:
    POP   HL                        ;[2C51] HL = string pointer
ESE71:
    LD    A,(HL)                    ;[2C52] Read character
    CP    $0D                       ;[2C53] Is it CR/SZ (end of string)?
    JP    Z,ESECT1                  ;[2C55] Yes: ran out of string before reaching start
    INC   HL                        ;[2C58] Advance source pointer
    DJNZ  ESE71                     ;[2C59] Decrement B (skip start-1 characters)
    DEC   HL                        ;[2C5B] Step back to last skipped character
    LD    B,C                       ;[2C5C] B = length (now copy C characters)
    CALL  PATCH6                    ;[2C5D] Copy B characters from HL to IX
    JP    ESECT1                    ;[2C60] Advance DE and terminate

;
; FRIGHT_STRING: RIGHT$(str$, n) -- return rightmost n characters of a string.
; Gets string pointer, measures string length (B), computes start offset
; (length - n), then copies n characters via PATCH6 (shared with MID$ via ESE72).
;
FRIGHT_STRING:
    CALL  SYSVAR_VRPTS              ;[2C63] HL -> string variable data
    INC   DE                        ;[2C66] Skip comma before n argument
    PUSH  HL                        ;[2C67] Save string pointer
    CALL  SEINT                     ;[2C68] Evaluate n -> HL (L = count)
    LD    C,L                       ;[2C6B] C = n (characters to copy)
    POP   HL                        ;[2C6C] Restore string pointer
    PUSH  HL                        ;[2C6D] Save again for ESE72
    LD    B,$00                     ;[2C6E] B = 0 (length counter)
ESE61:
    INC   B                         ;[2C70] Count characters
    LD    A,(HL)                    ;[2C71] Read character
    INC   HL                        ;[2C72] Advance pointer
    CP    $0D                       ;[2C73] Is it CR/SZ (end of string)?
    JR    NZ,ESE61                  ;[2C75] No: keep counting
    LD    A,B                       ;[2C77] A = string length + 1 (including terminator)
    SUB   C                         ;[2C78] A = (length+1) - n = skip count
    CALL  C,ERR_STRING              ;[2C79] Carry: n > length, error
    LD    B,A                       ;[2C7C] B = characters to skip before copying
    JR    ESE72                     ;[2C7D] Jump into MID$ copy logic

;
; STRING_SEEK_END: copy characters from HL into IX (string buffer) until a
; '"' or SZ ($0D) terminator is found, or B bytes have been copied (if B != 0).
; Updates both HL and IX.  Returns with HL pointing at the terminator.
;
STRING_SEEK_END:
    LD    A,(HL)                    ;[2C7F] Read character
    CP    $22                       ;[2C80] Is it '"'?
    RET   Z                         ;[2C82] Yes: end of string literal
    CP    SZ                        ;[2C83] Is it SZ ($0D = string end)?
    RET   Z                         ;[2C85] Yes: end of string variable
    LD    (IX+$00),A                ;[2C86] Store character in output buffer
    INC   IX                        ;[2C89] Advance output pointer
    INC   HL                        ;[2C8B] Advance source pointer
    DJNZ  STRING_SEEK_END           ;[2C8C] Decrement B; if non-zero, continue
    RET                             ;[2C8E] B exhausted: return

;
; RSEUPC: tokenise UPC$(str$) argument in READ_STRING_EXPR.
; Reads the string variable name, asserts ')', stores it, advances DE, then
; falls into RSE8 to check for '+' concatenation.
;
RSEUPC:
    CALL  READ_STRING_VAR           ;[2C8F] Tokenise string variable name into buffer at HL
    RST   $10                       ;[2C92] Skip spaces
    CP    ')'                       ;[2C93] Is next char ')'?
    LD    (HL),A                    ;[2C95] Store it in buffer (')' or error char)
    INC   HL                        ;[2C96] 
    INC   DE                        ;[2C97] Advance past ')'
    CALL  NZ,ERR_MISSING_BRACKET    ;[2C98] Not ')': error
    JR    RSE8                      ;[2C9B] Check for '+' concatenation

;
; READ_STRING_EXPR: tokenise a string expression into the buffer at HL.
; Handles all string types: string variables, string literals, and string
; function tokens (CHR$, STR$, INKEY$, GET$, UPC$, MID$, LEFT$, RIGHT$).
; Supports string concatenation via '+'.
;
READ_STRING_EXPR:
    CALL  TEST_FOR_STRING           ;[2C9D] Is it a string variable?
    JR    Z,RSE7                    ;[2CA0] Yes: tokenise variable name
    CALL  TKSL                      ;[2CA2] Try to tokenise keyword -> A
    LD    (HL),A                    ;[2CA5] Store token in buffer
    INC   HL                        ;[2CA6] 
    JR    NC,RSE1                   ;[2CA7] No carry: matched a keyword token, dispatch
    DEC   HL                        ;[2CA9] Carry: not a keyword, restore buffer pointer
    CALL  QUOT                      ;[2CAA] Tokenise string literal (must start with '"')
RSE8:
    RST   $10                       ;[2CAD] Skip spaces
RSE6:
    CP    '+'                       ;[2CAE] Is it '+' (concatenation)?
    RET   NZ                        ;[2CB0] No: done
    INC   DE                        ;[2CB1] Skip '+'
    LD    (HL),A                    ;[2CB2] Store '+' in buffer
    INC   HL                        ;[2CB3] 
    JR    READ_STRING_EXPR          ;[2CB4] Tokenise next string expression

RSE1:
    CP    CHR                       ;[2CB6] Is token CHR$ ($DF)?
    JR    Z,RSE2                    ;[2CB8] Yes: has integer argument
    CP    STR                       ;[2CBA] Is token STR$ ($E6)?
    JR    Z,RSE2                    ;[2CBC] Yes: has numeric argument
    CP    INKEYS                    ;[2CBE] Is token INKEY$ ($E4)?
    JR    Z,RSE8                    ;[2CC0] Yes: no argument, check for '+'
    CP    GETS                      ;[2CC2] Is token GET$ ($E5)?
    JR    Z,RSE8                    ;[2CC4] Yes: no argument
    CP    UPCS                      ;[2CC6] Is token UPC$ ($E3)?
    JR    Z,RSEUPC                  ;[2CC8] Yes: has string variable argument
    CP    MID                       ;[2CCA] Is token MID$ ($E2)?
    JR    Z,RSE3                    ;[2CCC] Yes: MID$ path
    CP    LEFT                      ;[2CCE] Is token LEFT$ ($E0)?
    JR    Z,RSE5                    ;[2CD0] Yes: LEFT$/RIGHT$ shared path
    CP    RIGHT                     ;[2CD2] Is token RIGHT$ ($E1)?
    CALL  NZ,ERR_SOMETHG_MISSG      ;[2CD4] None matched: error

RSE5:
    CALL  TEST_FOR_STRING           ;[2CD7] Is argument a string variable?
RSEN:
    CALL  NZ,ERR_SYNTAX             ;[2CDA] No: syntax error
    CALL  READ_STRING_VAR           ;[2CDD] Tokenise string variable name
    RST   $10                       ;[2CE0] Skip spaces
    INC   DE                        ;[2CE1] Advance past '('
RSE4:
    CP    ','                       ;[2CE2] Is it ','?
    JR    NZ,RSEN                   ;[2CE4] No: missing comma, error
    LD    (HL),A                    ;[2CE6] Store ',' in buffer
    INC   HL                        ;[2CE7] 
RSE2:
    DEC   DE                        ;[2CE8] Step back (ARG3 expects DE at '(')
    CALL  ARG3                      ;[2CE9] Tokenise the integer/numeric argument
    JR    RSE6                      ;[2CEC] Check for '+' concatenation

RSE3:
    CALL  TEST_FOR_STRING           ;[2CEE] MID$: is argument a string variable?
    JR    NZ,RSEN                   ;[2CF1] No: error
    CALL  READ_STRING_VAR           ;[2CF3] Tokenise string variable name
    RST   $10                       ;[2CF6] Skip spaces
    INC   DE                        ;[2CF7] Advance past '('
    CP    ','                       ;[2CF8] Is it ','?
    JR    NZ,RSEN                   ;[2CFA] No: missing comma, error
    LD    (HL),A                    ;[2CFC] Store ',' in buffer
    INC   HL                        ;[2CFD] 
    CALL  RP                        ;[2CFE] Tokenise start position expression
    JR    RSE4                      ;[2D01] Handle length argument (comma + ARG3)

RSE7:
    CALL  READ_STRING_VAR           ;[2D03] Tokenise string variable name into buffer
    JR    RSE8                      ;[2D06] Check for '+' concatenation

;
; TKSL: tokenise next word at DE without modifying HL.
; Saves HL, calls TK (tokeniser), then restores HL.
; Returns A = token (carry clear) or raw char (carry set).
;
TKSL:
    PUSH  HL                        ;[2D08] Save HL
    CALL  TK                        ;[2D09] Tokenise next word at DE -> A
    POP   HL                        ;[2D0C] Restore HL
    RET                             ;[2D0D] 

;
; FVAL: VAL() function -- convert a string to a number.
; The string argument has already been evaluated into SYSVAR_STRBUF by the
; expression evaluator.  Reads the decimal number from STRBUF via RDN.
;
FVAL:
    LD    DE,SYSVAR_STRBUF          ;[2D0E] DE -> string buffer (contains the string to convert)
    JP    RDN                       ;[2D11] Read decimal number from DE -> WRA1 and return

;
; FLEN: LEN() function -- return the length of a string.
; Counts characters in SYSVAR_STRBUF until SZ ($0D) is found.
; Returns the count as a float in WRA1.
;
FLEN:
    LD    HL,SYSVAR_STRBUF          ;[2D14] HL -> string buffer
    LD    B,$FF                     ;[2D17] B = -1 (pre-decremented; FLEN1 increments first)
FLEN1:
    INC   B                         ;[2D19] Increment length counter
    LD    A,(HL)                    ;[2D1A] Read character
    INC   HL                        ;[2D1B] Advance pointer
    CP    SZ                        ;[2D1C] Is it SZ ($0D = end of string)?
    JR    NZ,FLEN1                  ;[2D1E] No: keep counting
    LD    L,B                       ;[2D20] L = string length
FASC1:
    LD    H,0                       ;[2D21] H = 0
    JP    INTFP                     ;[2D23] Convert HL to float in WRA1 and return

;
; FASC: ASC() function -- return the ASCII code of the first character of
; a string.  Reads the first byte from SYSVAR_STRBUF.
;
FASC:
    LD    HL,SYSVAR_STRBUF          ;[2D26] HL -> string buffer
    LD    L,(HL)                    ;[2D29] L = first character of string
    JR    FASC1                     ;[2D2A] Convert to float and return

;
; VRPTSA: string array variable pointer routine.
; Handles DIM'd string array access: A$(n).
; Reads the string array table entry, evaluates the subscript, computes the
; address of the n-th string element, and returns HL -> element, B = max length.
;
VRPTSA:
    CALL  VRPTSP                    ;[2D2C] Get array base info (A already has var letter)
    PUSH  IX                        ;[2D2F] Save IX
    DEC   HL                        ;[2D31] HL -> low byte of array base pointer
    PUSH  HL                        ;[2D32] Save pointer
    INC   B                         ;[2D33] B = element size (length field + 1)
    PUSH  BC                        ;[2D34] Save element size
    INC   DE                        ;[2D35] Skip '(' in token stream
    CALL  SEINT                     ;[2D36] Evaluate subscript -> HL (L = index)
    INC   DE                        ;[2D39] Skip ')' 
    POP   BC                        ;[2D3A] BC = element size
    PUSH  DE                        ;[2D3B] Save parse pointer
    PUSH  HL                        ;[2D3C] Save subscript (L = index)
    LD    HL,(SYSVAR_STORE)         ;[2D3D] HL -> array dimension storage
    INC   HL                        ;[2D40] 
    LD    A,(HL)                    ;[2D41] Read dimension high byte
    INC   HL                        ;[2D42] 
    LD    H,(HL)                    ;[2D43] H = high byte
    LD    L,A                       ;[2D44] L = low byte; HL = dimension
    EX    DE,HL                     ;[2D45] DE = dimension
    POP   HL                        ;[2D46] HL = subscript
    EX    DE,HL                     ;[2D47] HL = dimension, DE = subscript
    CALL  CHLDE                     ;[2D48] Compare dimension with subscript
    EX    DE,HL                     ;[2D4B] Restore: HL = subscript
    CALL  C,ERR_SUBS_OUT_RANGE      ;[2D4C] subscript >= dimension: error
    LD    E,L                       ;[2D4F] DE = subscript (index)
    LD    D,H                       ;[2D50] 
VRSA2:
    ADD   HL,DE                     ;[2D51] HL += DE (multiply: HL = index * element_size)
    DJNZ  VRSA2                     ;[2D52] Repeat B times (B = element size)
    POP   DE                        ;[2D54] Restore parse pointer
    POP   BC                        ;[2D55] BC = array base address
    ADD   HL,BC                     ;[2D56] HL = base + offset = element address
    LD    B,(HL)                    ;[2D57] B = max length of this string element
    INC   HL                        ;[2D58] HL -> first character of string element
    POP   IX                        ;[2D59] Restore IX
    RET                             ;[2D5B] 

;
; VRPTS: string variable pointer routine (via SYSVAR_VRPTS hook).
; Entry: DE -> variable token (letter + '$'), or letter + '$' + '(' for arrays.
; Reads the variable letter, advances DE past letter and '$'.
; If '(' follows: array access -> VRPTSA.
; Otherwise: plain string variable -> VRPTSP.
; Returns HL -> first character of string data, B = max length of the string.
;
VRPTS:
    LD    A,(DE)                    ;[2D5C] Read variable letter
    INC   DE                        ;[2D5D] Advance past letter
    INC   DE                        ;[2D5E] Advance past '$'
    LD    C,A                       ;[2D5F] Save letter in C
    LD    A,(DE)                    ;[2D60] Read next char (may be '(')
    CP    $28                       ;[2D61] Is it '('?
    LD    A,C                       ;[2D63] Restore letter into A
    JP    Z,VRPTSA                  ;[2D64] Yes: array access

VRPTSP:
    SUB   'A'                       ;[2D67] A = variable index (0-based: A=0, Z=25)
    RLCA                            ;[2D69] A = index * 2
    RLCA                            ;[2D6A] A = index * 4 (4 bytes per string table entry)
VRPTS1:
    LD    HL,(SYSVAR_STBL)          ;[2D6B] HL -> string variable table base
    LD    C,A                       ;[2D6E] BC = offset into string table
    LD    B,$00                     ;[2D6F] 
    ADD   HL,BC                     ;[2D71] HL -> string table entry for this variable
    EX    AF,AF'                    ;[2D72] Save A in alternate
    LD    A,(HL)                    ;[2D73] Read low byte of string pointer
    INC   HL                        ;[2D74] 
    OR    (HL)                      ;[2D75] OR with high byte: is pointer zero?
    LD    A,$10                     ;[2D76] A = 16 (default max string length)
    JR    Z,VRPTS2                  ;[2D78] Zero: string not yet allocated, allocate it
    LD    (SYSVAR_STORE),HL         ;[2D7A] Save pointer to high byte (for VRPTSA dimension)
    LD    A,(HL)                    ;[2D7D] Read high byte of string pointer
    DEC   HL                        ;[2D7E] 
    LD    L,(HL)                    ;[2D7F] L = low byte of string pointer
    LD    H,A                       ;[2D80] H = high byte; HL -> string storage
    LD    B,(HL)                    ;[2D81] B = max length (stored at start of string allocation)
    INC   HL                        ;[2D82] HL -> first character of string
    RET                             ;[2D83] 

VRPTS2:
    LD    BC,VRPTS1                 ;[2D84] BC = return address (re-enter VRPTS1 after alloc)
    PUSH  BC                        ;[2D87] Push return address

;
; EDMSUB: allocate a new string variable in the variable heap (above TOV).
; A = requested max length ($10 = 16 bytes by default).
; Writes the TOV pointer into the string table entry at HL (low/high bytes).
; Allocates A+1 bytes (1 length byte + A data bytes) at TOV,
; writes the length byte and an SZ terminator, and updates TOV.
; Checks that allocation doesn't exceed the stack (ERR_OUT_OF_MEM).
;
EDMSUB:
    LD    BC,(SYSVAR_TOV)           ;[2D88] BC = current top-of-variables
    LD    (HL),B                    ;[2D8C] Store high byte of TOV in string table (high byte)
    DEC   HL                        ;[2D8D] 
    LD    (HL),C                    ;[2D8E] Store low byte of TOV (low byte)
EDMARS:
    LD    (BC),A                    ;[2D8F] Write length byte A at TOV
    LD    L,A                       ;[2D90] L = length
    LD    H,$00                     ;[2D91] HL = length
    INC   HL                        ;[2D93] HL = length + 1 (total bytes to allocate)
    INC   BC                        ;[2D94] BC = TOV + 1 (past length byte)
    LD    A,SZ                      ;[2D95] A = SZ ($0D = string end)
    LD    (BC),A                    ;[2D97] Write SZ terminator at start of string data
    ADD   HL,BC                     ;[2D98] HL = new TOV (TOV + 1 + length)
    LD    (SYSVAR_TOV),HL           ;[2D99] Update TOV
    INC   H                         ;[2D9C] HL + 256 (check against SP)
    SBC   HL,SP                     ;[2D9D] HL = (new_TOV + 256) - SP
    CALL  NC,ERR_OUT_OF_MEM         ;[2D9F] NC: new_TOV too close to stack, error
    EX    AF,AF'                    ;[2DA2] Restore A from alternate (offset into string table)
    RET                             ;[2DA3] Return to VRPTS1 (via pushed return address)

;
; EDMAR: allocate or resize string array elements.
; Called from EDIM when DIM A$(n) includes array string storage.
; Reads the dimension from the token stream, stores it in the array table entry
; (IX+1, IX+2), then iterates over all elements allocating storage via EDMARS.
; B = element size (max string length), set by caller.
;
EDMAR:
    PUSH  BC                        ;[2DA4] Save BC (element size)
    PUSH  HL                        ;[2DA5] Save HL (string table pointer)
    INC   DE                        ;[2DA6] Skip '(' before dimension
    RST   $18                       ;[2DA7] Evaluate dimension -> integer in HL (A = L)
    INC   DE                        ;[2DA8] Skip ')' after dimension
    LD    A,L                       ;[2DA9] A = dimension count (low byte)
    OR    H                         ;[2DAA] Test HL for zero
    POP   IX                        ;[2DAB] IX = string table pointer
    LD    (IX+$01),L                ;[2DAD] Store dimension low byte in table entry
    LD    (IX+$02),H                ;[2DB0] Store dimension high byte
    POP   BC                        ;[2DB3] Restore BC (B = element size)
    JR    Z,EDMAR2                  ;[2DB4] Zero dimension: nothing to allocate
    LD    A,B                       ;[2DB6] A = element size (max string length)
EDMAR1:
    PUSH  AF                        ;[2DB7] Save element size
    PUSH  HL                        ;[2DB8] Save remaining count
    LD    BC,(SYSVAR_TOV)           ;[2DB9] BC = current TOV
    CALL  EDMARS                    ;[2DBD] Allocate one string element at TOV
    POP   HL                        ;[2DC0] Restore count
    POP   AF                        ;[2DC1] Restore element size
    LD    C,A                       ;[2DC2] C = element size
    DEC   HL                        ;[2DC3] Decrement remaining count
    LD    A,H                       ;[2DC4] Test HL for zero
    OR    L                         ;[2DC5] 
    LD    A,C                       ;[2DC6] Restore A = element size
    JR    NZ,EDMAR1                 ;[2DC7] Not zero: allocate next element
EDMAR2:
    LD    A,(DE)                    ;[2DC9] Read next token after dimension expression
    RET                             ;[2DCA] Return with A = next token

;
; EDIM: DIM statement handler.
; For string arrays (variable ends in '$'): reads variable letter, reads
; string length argument (RST $18 -> L = max length), validates it (must be
; a small positive integer, 1..127), then allocates the string variable via
; EDMSUB and optionally processes an array subscript.
; For numeric arrays: calls ARRAY_LOCATE to find/create the array table entry,
; validates that it has not already been DIM'd, checks the dimension is <= 1023,
; allocates dimension*5+5 bytes above TOV, initialises all elements to $FF
; (undefined), and updates the array table entry.
;
EDIM:
    CALL  TEST_FOR_STRING           ;[2DCB] Is variable a string (ends '$')?
    JR    NZ,EDIM3                  ;[2DCE] No: numeric array
    LD    A,(DE)                    ;[2DD0] Read variable letter
    INC   DE                        ;[2DD1] Advance past letter
    INC   DE                        ;[2DD2] Advance past '$'
    INC   DE                        ;[2DD3] Advance past '('
    PUSH  AF                        ;[2DD4] Save variable letter
    RST   $18                       ;[2DD5] Evaluate max-length argument -> integer in HL
    INC   DE                        ;[2DD6] Advance past ')'
    INC   H                         ;[2DD7] Test H: should be zero (length must be < 256)
    DEC   H                         ;[2DD8] 
    CALL  NZ,ERR_NUM_OUT_RANGE      ;[2DD9] H != 0: length too large
    BIT   7,L                       ;[2DDC] Is bit 7 of L set? (negative = too large)
    CALL  NZ,ERR_NUM_OUT_RANGE      ;[2DDE] Yes: error
    INC   L                         ;[2DE1] Test L+1 for overflow (L=255 would wrap to 0)
    DEC   L                         ;[2DE2] 
    CALL  Z,ERR_NUM_OUT_RANGE       ;[2DE3] Zero: L was 0 (zero length not allowed)
    LD    B,L                       ;[2DE6] B = max string length
    POP   AF                        ;[2DE7] Restore variable letter
    PUSH  DE                        ;[2DE8] Save parse pointer
    SUB   'A'                       ;[2DE9] A = variable index (0-based)
    RLCA                            ;[2DEB] A = index * 2
    RLCA                            ;[2DEC] A = index * 4 (4 bytes per string table entry)
    LD    E,A                       ;[2DED] DE = offset into string table
    LD    D,$00                     ;[2DEE] 
    LD    HL,(SYSVAR_STBL)          ;[2DF0] HL -> string table base
    ADD   HL,DE                     ;[2DF3] HL -> string table entry for this variable
    INC   HL                        ;[2DF4] HL -> high-byte word of entry
    PUSH  HL                        ;[2DF5] Save string table pointer
    LD    A,B                       ;[2DF6] A = max string length
    PUSH  BC                        ;[2DF7] Save BC
    CALL  SUB_DIM                   ;[2DF8] Allocate string storage via SUB_DIM (calls EDMSUB)
    POP   BC                        ;[2DFB] Restore BC
    POP   HL                        ;[2DFC] Restore string table pointer
    POP   DE                        ;[2DFD] Restore parse pointer
    LD    A,(DE)                    ;[2DFE] Read next token
    CP    '('                       ;[2DFF] Is it '('? (array dimension follows)
    CALL  Z,EDMAR                   ;[2E01] Yes: allocate array elements via EDMAR
    CP    ','                       ;[2E04] Is it ','? (more DIM items)
    INC   DE                        ;[2E06] Advance past ',' or token
    JR    Z,EDIM                    ;[2E07] Yes: process next DIM item
    RET                             ;[2E09] Done

EDIM3:
    CALL  ARRAY_LOCATE              ;[2E0A] Parse array reference -> IX = array table entry, HL = dimension
    LD    A,(IX+$00)                ;[2E0D] Read array base address low byte
    OR    (IX+$01)                  ;[2E10] OR with high byte: is base address zero?
    CALL  NZ,ERR_REDIM_ARRAY        ;[2E13] Non-zero: already DIM'd, error
    LD    A,$F0                     ;[2E16] 
    AND   H                         ;[2E18] Check high nibble of dimension: must be < $1000
    CALL  NZ,ERR_OVERFLOW           ;[2E19] Non-zero: more than 4095 elements, overflow
    PUSH  DE                        ;[2E1C] Save parse pointer
    LD    DE,(SYSVAR_TOV)           ;[2E1D] DE = current top-of-variables (= array base)
    LD    (IX+$02),L                ;[2E21] Store dimension low byte in array table
    LD    (IX+$03),H                ;[2E24] Store dimension high byte
    INC   HL                        ;[2E27] HL = dimension + 1 (element count including 0)
    PUSH  HL                        ;[2E28] Save element count
    LD    C,L                       ;[2E29] BC = element count
    LD    B,H                       ;[2E2A] 
    ADD   HL,HL                     ;[2E2B] HL = count * 2
    ADD   HL,HL                     ;[2E2C] HL = count * 4
    ADD   HL,BC                     ;[2E2D] HL = count * 5 (5 bytes per float element)
    ADD   HL,DE                     ;[2E2E] HL = TOV + count*5 = new TOV
    LD    A,$C0                     ;[2E2F] 
    AND   H                         ;[2E31] Check: new TOV must be in low memory (< $4000)
    CALL  Z,ERR_OVERFLOW            ;[2E32] Zero: TOV wrapped into high memory, overflow
    EX    DE,HL                     ;[2E35] DE = new TOV, HL = old TOV (array base)
    LD    HL,0                      ;[2E36] 
    ADD   HL,SP                     ;[2E39] HL = current SP
    DEC   H                         ;[2E3A] HL = SP - 256 (safety margin)
    SBC   HL,DE                     ;[2E3B] HL = (SP-256) - new_TOV
    CALL  C,ERR_OVERFLOW            ;[2E3D] Carry: new TOV too close to stack
    LD    BC,(SYSVAR_TOV)           ;[2E40] BC = old TOV = array base address
    LD    (IX+$00),C                ;[2E44] Store array base low byte in table entry
    LD    (IX+$01),B                ;[2E47] Store array base high byte
    LD    (SYSVAR_TOV),DE           ;[2E4A] Update TOV to new value
    LD    L,C                       ;[2E4E] HL = array base address
    LD    H,B                       ;[2E4F] 
    POP   BC                        ;[2E50] BC = element count
    LD    DE,5                      ;[2E51] DE = 5 (bytes per element)
    INC   HL                        ;[2E54] HL = first element (skip past element 0 slot)
EDIM1:
    LD    (HL),$FF                  ;[2E55] Mark element as undefined ($FF = uninitialised type byte)

    ADD   HL,DE                     ;[2E57] Advance to next element (HL += 5)
    DEC   BC                        ;[2E58] Decrement remaining count
    LD    A,B                       ;[2E59] Test BC for zero
    OR    C                         ;[2E5A] 
    JR    NZ,EDIM1                  ;[2E5B] Not zero: initialise next element
    POP   DE                        ;[2E5D] Restore parse pointer
    LD    A,(DE)                    ;[2E5E] Read next token
    CP    ','                       ;[2E5F] Is it ','? (more DIM items)
    INC   DE                        ;[2E61] Advance past ',' or token
    JP    Z,EDIM                    ;[2E62] Yes: process next DIM item
    RET                             ;[2E65] Done

;
; IDIM: tokeniser validation for DIM statement.
; For string variables/arrays: reads variable name (including optional subscript
; via DMSR), stores separator, and loops for comma-separated lists.
; For numeric arrays: calls IVRY to read the variable reference including '(',
; verifies ')' was stored, then handles the list.
;
IDIM:
    CALL  TEST_FOR_STRING           ;[2E66] Is it a string variable?
    JR    NZ,IDIM1                  ;[2E69] No: numeric array
    CALL  READ_STRING_VAR           ;[2E6B] Tokenise string variable name into buffer at HL
    CALL  DMSR                      ;[2E6E] Handle optional '(' subscript dimension
    RST   $10                       ;[2E71] Skip spaces
    LD    (HL),A                    ;[2E72] Store separator (CR or ',') in buffer
    CP    $0D                       ;[2E73] Is it CR?
    RET   Z                         ;[2E75] Yes: done
    INC   HL                        ;[2E76] Advance buffer pointer
    RST   $20                       ;[2E77] Assert: ',' must follow
    DB    ','                       ;[2E78] Expected: ','
    INC   DE                        ;[2E79] Advance past ','
    JR    IDIM                      ;[2E7A] Process next DIM item

IDIM1:
    CALL  IVRY                      ;[2E7C] Tokenise numeric variable including '(' subscript
    DEC   HL                        ;[2E7F] Step back to check last stored char
    LD    A,')'                     ;[2E80] Expected closing ')'
    CP    (HL)                      ;[2E82] Is last stored char ')'?
    CALL  NZ,ERR_SYNTAX             ;[2E83] No: syntax error (missing bracket)
    INC   HL                        ;[2E86] Restore HL
    LD    A,(DE)                    ;[2E87] Read next token
    LD    (HL),A                    ;[2E88] Store separator in buffer
    CP    CR                        ;[2E89] Is it CR?
    RET   Z                         ;[2E8B] Yes: done
    RST   $20                       ;[2E8C] Assert: next char must be ','
    DB    ','                       ;[2E8D] Expected delimiter
    INC   HL                        ;[2E8E] Advance buffer pointer past ','
    INC   DE                        ;[2E8F] Advance parse pointer past ','
    RST   $10                       ;[2E90] Skip spaces
    JR    IDIM                      ;[2E91] Process next DIM item

;
; ROUND: round the value in WRA1 to the nearest integer.
; Only rounds if bit 0 of SYSVAR_ZFLAG is set (rounding mode enabled).
; Checks whether the last BCD byte of WRA1 (WRA1+4) is >= $50 (i.e. >= 0.5).
; If so, propagates a carry upward through WRA1+3..WRA1+1 using BCD arithmetic,
; then re-aligns the result.
;
ROUND:
    LD    A,(SYSVAR_ZFLAG)          ;[2E93] Load rounding-mode flag byte
    BIT   0,A                       ;[2E96] Is bit 0 set (rounding enabled)?
    RET   Z                         ;[2E98] No: return without rounding
    LD    A,(SYSVAR_WRA1)           ;[2E99] Load the exponent byte
    AND   $7F                       ;[2E9C] Mask off sign bit
    ADD   A,$81                     ;[2E9E] Overflows to zero only if exponent was $7F (max)
    RET   Z                         ;[2EA0] At maximum exponent: cannot meaningfully round
    LD    HL,SYSVAR_WRA1+$04        ;[2EA1] HL -> last (least-significant) mantissa byte
    LD    A,(HL)                    ;[2EA4] Load last byte (2 BCD digits = fractional part)
    CP    $50                       ;[2EA5] Is fractional part >= 0.50 (BCD $50)?
    LD    (HL),$00                  ;[2EA7] Zero the last 2 digits regardless
    RET   C                         ;[2EA9] Fraction < 0.50: no carry needed, done
    SCF                             ;[2EAA] Set carry (the +1 to propagate upward)
    LD    B,$03                     ;[2EAB] Loop 3 times (bytes WRA1+3 down to WRA1+1)
    PUSH  DE                        ;[2EAD] Save DE across the loop
RD1:
    DEC   HL                        ;[2EAE] Step back one byte toward MSB
    LD    A,$00                     ;[2EAF] A = 0 (will receive carry only)
    ADC   A,(HL)                    ;[2EB1] Add carry into this BCD byte
    DAA                             ;[2EB2] BCD-adjust the result
    LD    (HL),A                    ;[2EB3] Store back
    DJNZ  RD1                       ;[2EB4] Repeat for all 3 mantissa bytes
    CALL  ALIGN                     ;[2EB6] Re-align the floating-point number in WRA1
RDX:
    POP   DE                        ;[2EB9] Restore DE
    RET                             ;[2EBA]

;
; SQUARE: square the value in WRA1 (WRA1 = WRA1 * WRA1).
; Copies WRA1 into WRA2 then calls _MULT.
;
SQUARE:
    CALL  WRA1_TO_WRA2              ;[2EBB] WRA2 = WRA1
    JP    _MULT                     ;[2EBE] WRA1 = WRA1 * WRA2 = WRA1^2

;
; SERIES: evaluate the polynomial X := (((A1*X+A2)*X+A3)*X+A4)...
; IX points to the coefficient table; the first byte is the count of coefficients,
; followed by that many 5-byte BCD floats. WRA1 holds the value of X.
; IY is used as a temporary push-down calculation stack.
;
SERIES:
    PUSH  IY                        ;[2EC1] Save IY (calculation stack pointer)
    CALL  WRA1_TO_IY                ;[2EC3] Push X onto the IY calc stack
    POP   IY                        ;[2EC6] Restore IY
    LD    B,(IX+$00)                ;[2EC8] B = number of coefficients
    INC   IX                        ;[2ECB] Advance IX past the count byte
    LD    HL,SYSVAR_WRA1            ;[2ECD] HL -> WRA1 (destination for first coefficient)
    PUSH  BC                        ;[2ED0] Save coefficient count
    CALL  LIXW                      ;[2ED1] Load first coefficient from (IX) into WRA1; advance IX
    POP   BC                        ;[2ED4] Restore count
SERIES1:
    PUSH  BC                        ;[2ED5] Save remaining count
    PUSH  IY                        ;[2ED6] Save calc stack pointer
    CALL  IY_TO_WRA2                ;[2ED8] Pop X from calc stack into WRA2
    POP   IY                        ;[2EDB] Restore calc stack pointer
    CALL  _MULT                     ;[2EDD] WRA1 = WRA1 * X (multiply running result by X)
    CALL  IX_TO_WRA2                ;[2EE0] Load next coefficient from (IX) into WRA2; advance IX
    CALL  ADD                       ;[2EE3] WRA1 = WRA1 + coefficient
    POP   BC                        ;[2EE6] Restore count
    DJNZ  SERIES1                   ;[2EE7] Repeat for all coefficients
    RET                             ;[2EE9] WRA1 = polynomial result

;
; IY_TO_WRA1: pop a 5-byte float from the IY stack into WRA1.
; Calls CSW1 to copy into the WRA2 area, then swaps WRA1 and WRA2.
;
IY_TO_WRA1:
    CALL  CSW1                      ;[2EEA] Pop IY stack into WRA2 area (pre-decrement)
    CALL  SWAP                      ;[2EED] Swap WRA1 and WRA2 so result lands in WRA1

;
; CSW1: pop 5 bytes from the IY stack (pre-decrement) into SYSVAR_WRA1..SYSVAR_SYNL-1.
; Used internally by IY_TO_WRA1 and elsewhere to restore a saved float from the
; calculation stack.
;
CSW1:
    LD    HL,SYSVAR_SYNL            ;[2EF0] HL -> one byte past end of WRA2 (= WRA2+5)
    LD    B,$05                     ;[2EF3] Copy 5 bytes
CW1:
    DEC   IY                        ;[2EF5] Pre-decrement IY (pop semantics)
    DEC   HL                        ;[2EF7] Pre-decrement destination
    LD    A,(IY+$00)                ;[2EF8] Read byte from calc stack
    LD    (HL),A                    ;[2EFB] Write to WRA area
    DJNZ  CW1                       ;[2EFC] Repeat for all 5 bytes
    RET                             ;[2EFE]

;
; WRA1_TO_IY: push the 5-byte float from WRA1 onto the IY stack (post-increment).
;
WRA1_TO_IY:
    LD    HL,SYSVAR_WRA1            ;[2EFF] HL -> WRA1
    LD    B,$05                     ;[2F02] Copy 5 bytes
WC1:
    LD    A,(HL)                    ;[2F04] Read byte from WRA1
    LD    (IY+$00),A                ;[2F05] Write to calc stack at IY
    INC   IY                        ;[2F08] Advance IY (push semantics)
    INC   HL                        ;[2F0A] Advance source
    DJNZ  WC1                       ;[2F0B]
    RET                             ;[2F0D]

;
; IY_TO_WRA2: copy 5 bytes from the IY stack (post-increment) into WRA2.
;
IY_TO_WRA2:
    LD    B,$05                     ;[2F0E] Copy 5 bytes
    LD    HL,SYSVAR_WRA2            ;[2F10] HL -> WRA2
LW1:
    LD    A,(IY+$00)                ;[2F13] Read from calc stack
    LD    (HL),A                    ;[2F16] Write into WRA2
    INC   IY                        ;[2F17] Advance IY
    INC   HL                        ;[2F19] Advance destination
    DJNZ  LW1                       ;[2F1A]
    RET                             ;[2F1C]

;
; IX_TO_WRA2: load 5 bytes from (IX) into WRA2; IX is advanced past the data.
; LIXW: same copy but destination is whatever HL points to on entry.
;
IX_TO_WRA2:
    LD    HL,SYSVAR_WRA2            ;[2F1D] HL -> WRA2 (default destination)
LIXW:
    LD    B,$05                     ;[2F20] Copy 5 bytes
LW2:
    LD    A,(IX+$00)                ;[2F22] Read byte from (IX)
    LD    (HL),A                    ;[2F25] Write to destination
    INC   IX                        ;[2F26] Advance source
    INC   HL                        ;[2F28] Advance destination
    DJNZ  LW2                       ;[2F29]
    RET                             ;[2F2B]

;
; PUSH_WRA1: push WRA1 onto the hardware stack and jump via (IX).
; Pops the return address into IX, pushes WRA1's 5 bytes (as AF + two HL pairs),
; then jumps to IX. This lets a caller save WRA1 on the Z80 stack and resume
; at a computed address.
;
PUSH_WRA1:
    POP   IX                        ;[2F2C] IX = return address (caller's continuation)
    LD    A,(SYSVAR_WRA1)           ;[2F2E] Load exponent byte
    PUSH  AF                        ;[2F31] Push exponent
    LD    HL,(SYSVAR_WRA1+$01)      ;[2F32] Load mantissa bytes 1-2
    PUSH  HL                        ;[2F35]
    LD    HL,(SYSVAR_WRA1+$03)      ;[2F36] Load mantissa bytes 3-4
    PUSH  HL                        ;[2F39]
    JP    (IX)                      ;[2F3A] Jump to caller's continuation

;
; POP_WRA2: pop a PUSH_WRA1-saved value from the hardware stack into WRA2,
; then jump via (IX).
;
POP_WRA2:
    POP   IX                        ;[2F3C] IX = return address
    POP   HL                        ;[2F3E] Retrieve mantissa bytes 3-4
    LD    (SYSVAR_WRA2+$03),HL      ;[2F3F] Store into WRA2
    POP   HL                        ;[2F42] Retrieve mantissa bytes 1-2
    LD    (SYSVAR_WRA2+$01),HL      ;[2F43] Store into WRA2
    POP   AF                        ;[2F46] Retrieve exponent
    LD    (SYSVAR_WRA2),A           ;[2F47] Store exponent into WRA2
    JP    (IX)                      ;[2F4A] Jump to caller's continuation

;
; FLN: BASIC LN() function - natural logarithm.
; Computes LN(x) = LOG10(x) / LOG10(e) = LOG10(x) * ln(10).
; FLOAT_LOGE = log10(e) = 0.434294... so we divide by it to get LN.
;
FLN:
    CALL  FLOG                      ;[2F4C] WRA1 = LOG10(WRA1)
    LD    HL,FLOAT_LOGE             ;[2F4F] HL -> log10(e) constant (0.434294...)
    CALL  LNUM2                     ;[2F52] WRA2 = log10(e)
    JP    DIV                       ;[2F55] WRA1 = LOG10(x) / log10(e) = LN(x)

;
; FARCSIN: BASIC ARCSIN() function.
; If the argument is zero, returns zero. Otherwise saves the sign and
; falls into FNACOS/FARCCOS to compute the result via the identity
; ARCSIN(x) = PI/2 - ARCCOS(x).
;
FARCSIN:
    LD    A,(SYSVAR_WRA1)           ;[2F58] Load exponent
    CP    $80                       ;[2F5B] Is argument zero (exponent $80)?
    JP    Z,LZERO                   ;[2F5D] Yes: ARCSIN(0) = 0
    PUSH  AF                        ;[2F60] Save sign/exponent for ARCCOS1 to use
    JP    FNACOS                    ;[2F61] Compute via FNACOS (ARCCOS then adjustment)

;
; ARCCOS1: common tail shared by ARCSIN and ARCCOS.
; Computes SQRT((1-x)/(1+x)), takes ARCTAN, doubles it.
; The sign saved by the caller controls the final adjustment.
;
ARCCOS1:
    CALL  SUB                       ;[2F64] WRA1 = WRA1 - WRA2
    CALL  POP_WRA2                  ;[2F67] Restore WRA2 from hardware stack
    CALL  DIV                       ;[2F6A] WRA1 = (1-x) / (1+x)
    CALL  FSQR                      ;[2F6D] WRA1 = SQRT(...)
    CALL  ARCTANS                   ;[2F70] WRA1 = ARCTAN(SQRT(...))
    CALL  WRA1_TO_WRA2              ;[2F73] WRA2 = ARCTAN result
    CALL  ADD                       ;[2F76] WRA1 = 2 * ARCTAN (double it)
    POP   AF                        ;[2F79] Retrieve saved sign from FARCSIN/FARCCOS
    RLA                             ;[2F7A] Rotate sign bit into carry
    RET   C                         ;[2F7B] Positive argument: done
    CALL  WRA1_TO_WRA2              ;[2F7C] WRA2 = result so far
    CALL  FPI                       ;[2F7F] WRA1 = PI
    JP    SUB                       ;[2F82] WRA1 = PI - result (adjust for negative arg)

;
; FARCCOS: BASIC ARCCOS() function.
; Uses the identity: ARCCOS(x) = 2*ARCTAN(SQRT((1-|x|)/(1+|x|))).
; Saves the sign, forces positive, computes (1-|x|) and (1+|x|), then
; calls ARCCOS1 for the final calculation.
;
FARCCOS:
    LD    HL,SYSVAR_WRA1            ;[2F85] HL -> WRA1
    LD    A,(HL)                    ;[2F88] Load exponent (with sign bit)
    PUSH  AF                        ;[2F89] Save sign for ARCCOS1
    SET   7,(HL)                    ;[2F8A] Force positive: |x|
    CALL  WRA1_TO_WRA2              ;[2F8C] WRA2 = |x|
    CALL  PUSH_WRA1                 ;[2F8F] Push |x| onto hardware stack
    CALL  LONE                      ;[2F92] WRA1 = 1.0
    CALL  ADD                       ;[2F95] WRA1 = 1 + |x|
    CALL  POP_WRA2                  ;[2F98] WRA2 = |x| (restore)
    CALL  PUSH_WRA1                 ;[2F9B] Push (1+|x|) onto stack
    CALL  LONE                      ;[2F9E] WRA1 = 1.0
    JR    ARCCOS1                   ;[2FA1] Compute: 1 - |x| then enter ARCCOS1
    NOP                             ;[2FA3] Padding
    NOP                             ;[2FA4] Padding

;
; FARCTAN: BASIC ARCTAN() function.
; For |x| < 1: uses direct Chebyshev series ARCTANS.
; For |x| >= 1: uses identity ARCTAN(x) = PI/2 - ARCTAN(1/x).
; Sign is saved and restored at the end.
;
FARCTAN:
    LD    A,(SYSVAR_WRA1)           ;[2FA5] Load exponent (bit 7 = sign)
    PUSH  AF                        ;[2FA8] Save sign
    SET   7,A                       ;[2FA9] Force magnitude positive
    LD    (SYSVAR_WRA1),A           ;[2FAB] WRA1 = |x|
    CP    $C0                       ;[2FAE] Is |x| >= 1.0 (exponent >= $C0)?
    JR    NC,ARCTAN3                ;[2FB0] Yes: use reciprocal identity
    CALL  ARCTANS                   ;[2FB2] Direct series: WRA1 = ARCTAN(|x|)
ARCTAN2:
    POP   AF                        ;[2FB5] Retrieve original sign
    BIT   7,A                       ;[2FB6] Was original argument positive (bit 7 set)?
    RET   NZ                        ;[2FB8] Yes: done
    LD    HL,SYSVAR_WRA1            ;[2FB9] HL -> WRA1
    RES   7,(HL)                    ;[2FBC] Negate: clear sign bit (Lynx: 1=pos, 0=neg)
    RET                             ;[2FBE]

ARCTAN3:
    CALL  WRA1_TO_WRA2              ;[2FBF] WRA2 = |x|
    CALL  LONE                      ;[2FC2] WRA1 = 1.0
    CALL  DIV                       ;[2FC5] WRA1 = 1/|x|
    CALL  ARCTANS                   ;[2FC8] WRA1 = ARCTAN(1/|x|)
ARCTAN4:
    CALL  WRA1_TO_WRA2              ;[2FCB] WRA2 = ARCTAN(1/|x|)
    LD    HL,FLOAT_NPI2             ;[2FCE] HL -> PI/2 constant
    CALL  LNUM1                     ;[2FD1] WRA1 = PI/2
    CALL  SUB                       ;[2FD4] WRA1 = PI/2 - ARCTAN(1/|x|) = ARCTAN(|x|)
    JR    ARCTAN2                   ;[2FD7] Apply sign and return

;
; ARCTANS: Chebyshev series evaluation for ARCTAN (for |x| <= 1).
; Squares x as the series variable, evaluates DATA_ARCTAN polynomial,
; then multiplies the result by x.
;
ARCTANS:
    CALL  PUSH_WRA1                 ;[2FD9] Save x on hardware stack
    CALL  SQUARE                    ;[2FDC] WRA1 = x^2
    LD    IX,DATA_ARCTAN            ;[2FDF] IX -> ARCTAN polynomial coefficients
    CALL  SERIES                    ;[2FE3] WRA1 = polynomial(x^2)
    CALL  POP_WRA2                  ;[2FE6] WRA2 = x (restore)
    JP    _MULT                     ;[2FE9] WRA1 = polynomial(x^2) * x = ARCTAN(x)

;
; DATA_ARCTAN: 6 Chebyshev coefficients for ARCTAN series.
;
DATA_ARCTAN:
    DB $06,$BD,$68,$12,$41,$10,$3E,$33      ;[2FEC] Count=6, coefficient 1
    DB $60,$62,$69,$BE,$79,$62,$63,$18      ;[2FF4] Coefficients 2-3
    DB $3F,$13,$23,$35,$10,$BF,$19,$80      ;[2FFC] Coefficients 4-5
    DB $78,$69,$3F,$33,$31,$73,$76,$BF      ;[3004] Coefficient 6 (start)
    DB $99,$99,$96,$11                      ;[300C] Coefficient 6 (end)

;
; FFACT: BASIC FACT() function - factorial.
; Truncates to integer, returns 0!=1, errors on >34 (overflow) or negative.
; Iteratively computes n * (n-1) * ... * 1.
;
FFACT:
    CALL  FINT                      ;[3010] Truncate WRA1 to integer
    LD    A,(SYSVAR_WRA1)           ;[3013] Load exponent
    CP    $80                       ;[3016] Is argument zero?
    JP    Z,LONE                    ;[3018] Yes: 0! = 1
    CP    $C2                       ;[301B] Is exponent >= $C2 (value > 34)?
    CALL  NC,ERR_OVERFLOW           ;[301D] Yes: overflow
    BIT   7,A                       ;[3020] Is number negative (bit 7 clear = negative)?
    CALL  Z,ERR_FUNCT_ARG           ;[3022] Yes: domain error
    CALL  PUSH_WRA1                 ;[3025] Push n onto hardware stack
FACT3:
    LD    HL,FLOAT_N1               ;[3028] HL -> 1.0
    CALL  LNUM2                     ;[302B] WRA2 = 1.0
    CALL  SUB                       ;[302E] WRA1 = n - 1
    LD    A,(SYSVAR_WRA1)           ;[3031] Check exponent of (n-1)
    CP    $80                       ;[3034] Is (n-1) = 0?
    JR    Z,FACT4                   ;[3036] Yes: finished multiplying
    CALL  POP_WRA2                  ;[3038] WRA2 = accumulated product
    CALL  PUSH_WRA1                 ;[303B] Push (n-1) for next iteration
    CALL  _MULT                     ;[303E] WRA1 = (n-1) * product
    CALL  POP_WRA2                  ;[3041] WRA2 = (n-1) saved
    CALL  PUSH_WRA1                 ;[3044] Push updated product
    CALL  SWAP                      ;[3047] WRA1 = (n-1) for next subtract
    JR    FACT3                     ;[304A] Loop
FACT4:
    CALL  POP_WRA2                  ;[304C] WRA2 = final product (n!)
    JP    SWAP                      ;[304F] WRA1 = n!, return

;
; FSQR: BASIC SQR() function - square root via 5 Newton-Raphson iterations.
; x_new = (x + N/x) / 2. Errors on negative argument.
;
FSQR:
    PUSH  IY                        ;[3052] Save IY
    CALL  WRA1_TO_IY                ;[3054] Push N (argument) onto IY calc stack
    POP   IY                        ;[3057] Restore IY
    LD    A,(SYSVAR_WRA1)           ;[3059] Load exponent
    CP    $80                       ;[305C] Is argument zero?
    RET   Z                         ;[305E] Yes: SQR(0) = 0
    BIT   7,A                       ;[305F] Negative (bit 7 clear)?
    CALL  Z,ERR_FUNCT_ARG           ;[3061] Yes: domain error
    RES   7,A                       ;[3064] Strip sign bit
    RRCA                            ;[3066] Halve the exponent (initial estimate)
    ADD   A,$20                     ;[3067] Adjust estimate
    SET   7,A                       ;[3069] Restore positive sign
SQR2:
    LD    (SYSVAR_WRA1),A           ;[306B] Store initial estimate
    LD    B,$05                     ;[306E] 5 Newton-Raphson iterations
SQR3:
    PUSH  BC                        ;[3070] Save iteration count
    CALL  PUSH_WRA1                 ;[3071] Save current estimate x
    PUSH  IY                        ;[3074] Save IY
    CALL  IY_TO_WRA2                ;[3076] WRA2 = N (original argument)
    POP   IY                        ;[3079] Restore IY
    CALL  SWAP                      ;[307B] WRA1 = N, WRA2 = x
    CALL  DIV                       ;[307E] WRA1 = N/x
    CALL  POP_WRA2                  ;[3081] WRA2 = x (restore estimate)
    CALL  ADD                       ;[3084] WRA1 = N/x + x
    LD    HL,FLOAT_HALF             ;[3087] HL -> 0.5
    CALL  LNUM2                     ;[308A] WRA2 = 0.5
    CALL  _MULT                     ;[308D] WRA1 = (N/x + x) * 0.5 = new estimate
    POP   BC                        ;[3090] Restore count
    DJNZ  SQR3                      ;[3091] Repeat 5 times
    RET                             ;[3093] WRA1 = SQR(N)

;
; SUB_POWER1: helper - returns 1.0 for the case x^0.
;
SUB_POWER1:
    CALL  CSW1                      ;[3094] Restore base from IY stack
    JP    LONE                      ;[3097] WRA1 = 1.0

;
; FPOWER: BASIC ** operator - WRA2 raised to the power WRA1.
; Special cases for exponent=0 (->1), exponent=1 (->base), small positive
; integers (->fast multiply loop). General case uses exp(n*log(base)).
;
FPOWER:
    CALL  CSW1                      ;[309A] Pop base from IY stack into WRA2 area
    LD    A,(SYSVAR_WRA1)           ;[309D] Load exponent value
    CP    $80                       ;[30A0] Is exponent zero?
    JR    Z,SUB_POWER1              ;[30A2] Yes: x^0 = 1
    CP    $C0                       ;[30A4] Is exponent exactly 1.0 ($C0)?
    JR    NZ,POWER4                 ;[30A6] No: use log/antilog method
    CALL  RL10                      ;[30A8] Rotate top BCD digit of WRA1 out into A
    EX    AF,AF'                    ;[30AB] Save the digit
    LD    B,$04                     ;[30AC] Check remaining 4 mantissa bytes
    LD    HL,SYSVAR_WRA1+$01        ;[30AE] HL -> WRA1 mantissa
    XOR   A                         ;[30B1] A = 0 (test value)
POWER1:
    CP    (HL)                      ;[30B2] Is this byte zero?
    JR    NZ,POWER3                 ;[30B3] No: not a small integer, use log method
    INC   HL                        ;[30B5]
    DJNZ  POWER1                    ;[30B6] Check all 4 bytes
    CALL  CSW1                      ;[30B8] Integer exponent: restore base into WRA1
    EX    AF,AF'                    ;[30BB] Retrieve the integer digit
    DEC   A                         ;[30BC] n-1 multiplications needed
    RET   Z                         ;[30BD] Exponent was 1: base^1 = base, return
    LD    B,A                       ;[30BE] B = exponent - 1
POWER2:
    PUSH  BC                        ;[30BF] Save count
    PUSH  IY                        ;[30C0] Save IY
    CALL  IY_TO_WRA2                ;[30C2] WRA2 = base (from IY stack)
    POP   IY                        ;[30C5]
    CALL  _MULT                     ;[30C7] WRA1 *= base
    POP   BC                        ;[30CA]
    DJNZ  POWER2                    ;[30CB] Repeat n-1 times
    RET                             ;[30CD] WRA1 = base^n

POWER3:
    EX    AF,AF'                    ;[30CE] Retrieve rotated digit
    CALL  RRD1A                     ;[30CF] Rotate it back into WRA1
POWER4:
    CALL  PUSH_WRA1                 ;[30D2] Save exponent on stack
    CALL  CSW1                      ;[30D5] Restore base into WRA1
    CALL  FLOG                      ;[30D8] WRA1 = LOG10(base)
    CALL  POP_WRA2                  ;[30DB] WRA2 = exponent
    CALL  _MULT                     ;[30DE] WRA1 = exponent * LOG10(base)
    JP    FANTILOG                  ;[30E1] WRA1 = 10^(exponent*LOG10(base)) = base^exponent

;
; FLOG: BASIC LOG() function - common logarithm (base 10).
; Errors if argument <= 0. Separates the integer power-of-10 exponent from the
; fractional mantissa, evaluates LOG of the mantissa via a Chebyshev series
; (DATA_LOG), then adds the integer exponent back.
;
FLOG:
    LD    HL,SYSVAR_WRA1            ;[30E4] HL -> WRA1
    LD    A,(HL)                    ;[30E7] Load exponent byte
    CP    $81                       ;[30E8] Is argument <= 0?
    CALL  C,ERR_FUNCT_ARG           ;[30EA] Yes: error
    LD    (HL),$C0                  ;[30ED] Set exponent to $C0 (=1.x, strip integer part)
    BIT   6,A                       ;[30EF] Check sign of integer exponent
    PUSH  AF                        ;[30F1] Save for sign-of-exponent test later
    JR    NZ,FL2                    ;[30F2] Positive exponent: no negation
    NEG                             ;[30F4] Negative: negate to get magnitude
FL2:
    AND   $3F                       ;[30F6] Mask to 6-bit magnitude
    LD    B,$FF                     ;[30F8] B = -1 (tens counter)
    LD    C,$0A                     ;[30FA] C = 10 (divisor)
FL1:
    INC   B                         ;[30FC] Increment tens
    SUB   C                         ;[30FD] Subtract 10
    JR    NC,FL1                    ;[30FE] Loop while >= 0
    ADD   A,C                       ;[3100] Restore units digit
    SLA   B                         ;[3101] B = tens * 2
    SLA   B                         ;[3103] B = tens * 4
    SLA   B                         ;[3105] B = tens * 8
    SLA   B                         ;[3107] B = tens * 16 (shift to high nibble)
    ADD   A,B                       ;[3109] A = packed BCD: tens*16 + units
    PUSH  AF                        ;[310A] Save BCD integer exponent
    CALL  PUSH_WRA1                 ;[310B] Save fractional mantissa
    LD    HL,FLOAT_SQ10             ;[310E] HL -> SQRT(10) = 3.16228...
    CALL  LNUM2                     ;[3111] WRA2 = SQRT(10)
    CALL  ADD                       ;[3114] WRA1 = mantissa + SQRT(10)
    CALL  POP_WRA2                  ;[3117] WRA2 = saved mantissa
    CALL  PUSH_WRA1                 ;[311A] Push (mantissa + SQRT(10))
    LD    HL,FLOAT_SQ10             ;[311D] HL -> SQRT(10)
    CALL  LNUM1                     ;[3120] WRA1 = SQRT(10)
    CALL  SWAP                      ;[3123] WRA1 = mantissa, WRA2 = SQRT(10)
    CALL  SUB                       ;[3126] WRA1 = mantissa - SQRT(10)
    CALL  POP_WRA2                  ;[3129] WRA2 = (mantissa + SQRT(10))
    CALL  DIV                       ;[312C] WRA1 = (mantissa-SQRT(10))/(mantissa+SQRT(10))
    CALL  PUSH_WRA1                 ;[312F] Save ratio for final multiply
    CALL  SQUARE                    ;[3132] WRA1 = ratio^2
    LD    IX,DATA_LOG               ;[3135] IX -> LOG series coefficients
    CALL  SERIES                    ;[3139] WRA1 = polynomial(ratio^2)
    CALL  POP_WRA2                  ;[313C] WRA2 = ratio
    CALL  _MULT                     ;[313F] WRA1 = polynomial * ratio
    LD    HL,FLOAT_HALF             ;[3142] HL -> 0.5
    CALL  LNUM2                     ;[3145] WRA2 = 0.5
    CALL  ADD                       ;[3148] WRA1 += 0.5 (half-exponent correction)
    LD    HL,SYSVAR_WRA1            ;[314B] HL -> WRA1
    PUSH  HL                        ;[314E] Save pointer
    CALL  LNUM2                     ;[314F] WRA2 = fractional LOG result
    CALL  LONE                      ;[3152] WRA1 = 1.0
    POP   HL                        ;[3155] Restore HL -> WRA1
    SET   0,(HL)                    ;[3156] Set bit 0 of exponent: WRA1 exponent = $C1
    POP   AF                        ;[3158] Retrieve packed BCD integer exponent
    LD    (SYSVAR_WRA1+$01),A       ;[3159] Store BCD exponent into WRA1 mantissa
    CALL  ALIGN                     ;[315C] Normalise WRA1
    POP   AF                        ;[315F] Retrieve sign of integer exponent
    JR    NZ,FL3                    ;[3160] Positive: skip negation
    LD    HL,SYSVAR_WRA1            ;[3162] HL -> WRA1
    RES   7,(HL)                    ;[3165] Negate (clear sign bit)
FL3:
    JP    ADD                       ;[3167] WRA1 = integer_part + fractional_LOG = LOG10(x)

;
; DATA_LOG: 4 Chebyshev coefficients for the LOG(mantissa) series.
;
DATA_LOG:
    DB $04,$BF,$19,$13,$37,$71,$BE,$94      ;[316A] Count=4, coefficient 1
    DB $37,$64,$76,$BF,$17,$75,$22,$07      ;[3172] Coefficients 2-3
    DB $BF,$28,$93,$35,$52,$BF,$86,$85      ;[317A] Coefficient 4 (start)
    DB $91,$72                              ;[3182] Coefficient 4 (end)

;
; FEXP: BASIC EXP() function - e^x = 10^(x * log10(e)).
;
FEXP:
    LD    HL,FLOAT_LOGE             ;[3184] HL -> log10(e) = 0.434294...
    CALL  LNUM2                     ;[3187] WRA2 = log10(e)
    CALL  _MULT                     ;[318A] WRA1 = x * log10(e)
    JP    FANTILOG                  ;[318D] WRA1 = 10^(x*log10(e)) = e^x

;
; FTAN: BASIC TAN() = SIN(x) / COS(x).
;
FTAN:
    CALL  PUSH_WRA1                 ;[3190] Save x
    CALL  FCOS                      ;[3193] WRA1 = COS(x)
    CALL  POP_WRA2                  ;[3196] WRA2 = x
    CALL  PUSH_WRA1                 ;[3199] Push COS(x)
    LD    HL,SYSVAR_WRA2            ;[319C] HL -> WRA2 (where x is stored)
    CALL  LNUM1                     ;[319F] WRA1 = x
    CALL  FSIN                      ;[31A2] WRA1 = SIN(x)
    CALL  POP_WRA2                  ;[31A5] WRA2 = COS(x)
    JP    DIV                       ;[31A8] WRA1 = SIN(x)/COS(x) = TAN(x)

;
; FANTILOG: compute 10^x (antilogarithm base 10).
; Separates integer part, evaluates 10^frac via DATA_ANTILOG series,
; squares the result (series computes 10^(frac/2)), sets the integer-part exponent.
; Handles negative x by computing the reciprocal.
;
FANTILOG:
    LD    HL,SYSVAR_WRA1            ;[31AB] HL -> WRA1
    BIT   7,(HL)                    ;[31AE] Test sign (bit 7 set = positive in Lynx)
    EX    AF,AF'                    ;[31B0] Save sign flag in AF'
    SET   7,(HL)                    ;[31B1] Force |x|
    LD    A,$BF                     ;[31B3] Threshold for |x| < 1.0
    CP    (HL)                      ;[31B5] Is |x| < 1.0?
    JR    C,ANT1                    ;[31B6] No: has an integer part to extract
    INC   A                         ;[31B8] A = $C0 (integer part = 0)
    PUSH  AF                        ;[31B9] Save exponent = $C0
    JR    ANT2                      ;[31BA] Proceed with series
ANT1:
    LD    A,(SYSVAR_WRA1)           ;[31BC] Reload exponent
    CALL  FPINTA                    ;[31BF] Convert integer part of WRA1 to binary in HL
    EX    DE,HL                     ;[31C2] DE = integer part
    LD    HL,$003C                  ;[31C3] HL = 60 (max safe exponent: 10^60)
    OR    A                         ;[31C6] Clear flags
    SBC   HL,DE                     ;[31C7] HL = 60 - integer_part
    CALL  C,ERR_OVERFLOW            ;[31C9] Overflow if integer_part > 60
    LD    A,$C0                     ;[31CC] Base exponent
    ADD   A,E                       ;[31CE] A = $C0 + integer_part
    PUSH  AF                        ;[31CF] Save
    LD    A,$BF                     ;[31D0] Replace WRA1 exponent with $BF (fractional only)
    LD    (SYSVAR_WRA1),A           ;[31D2]
    OR    A                         ;[31D5] Clear carry
    CALL  ALIGN                     ;[31D6] Align fractional part
ANT2:
    LD    IX,DATA_ANTILOG           ;[31D9] IX -> ANTILOG series coefficients
    CALL  SERIES                    ;[31DD] WRA1 = 10^(frac/2) via series
    CALL  SQUARE                    ;[31E0] WRA1 = (10^(frac/2))^2 = 10^frac
    POP   AF                        ;[31E3] Retrieve integer-part exponent
    LD    (SYSVAR_WRA1),A           ;[31E4] Set exponent: WRA1 = 10^x
    EX    AF,AF'                    ;[31E7] Retrieve original sign of x
    RET   NZ                        ;[31E8] Positive x: done
    LD    HL,FLOAT_N1               ;[31E9] Negative x: compute 1/10^|x|
    CALL  LNUM2                     ;[31EC] WRA2 = 1.0
    CALL  SWAP                      ;[31EF] WRA1 = 1.0, WRA2 = 10^|x|
    CALL  DIV                       ;[31F2] WRA1 = 1/10^|x| = 10^x
    RET                             ;[31F5]

;
; DATA_ANTILOG: 6 Chebyshev coefficients for FANTILOG.
;
DATA_ANTILOG:
    DB $06,$BD,$56,$54,$90,$20,$BE,$13      ;[31F6] Count=6, coefficient 1
    DB $42,$09,$40,$BE,$75,$46,$75,$47      ;[31FE] Coefficients 2-3
    DB $BF,$25,$36,$03,$32,$BF,$66,$28      ;[3206] Coefficients 4-5
    DB $43,$15,$C0,$11,$51,$28,$76,$C0      ;[320E] Coefficient 6 (start)
    DB $10,$00,$00,$00                      ;[3216] Coefficient 6 (end)

;
; FCOS: BASIC COS() function - cosine.
; Adds 1.0 to x (since COS(x) = SIN(x + PI/2) in the Lynx cycle encoding
; where a full cycle = 4.0) then falls through to FSIN.
;
FCOS:
    LD    HL,FLOAT_NPI2             ;[321A] 
    CALL  LNUM2                     ;[321D] Add pi/4 to wra1
    CALL  ADD                       ;[3220] 
    ; Falls through to FSIN

;
; FSIN: BASIC SIN() function - sine.
; Argument is in Lynx angular units where 4.0 = full 360 degrees.
; Range-reduces to [0,1) quarter-cycle, mirrors/reflects for correct quadrant,
; then evaluates a Chebyshev polynomial series (DATA_SINCOS).
;
FSIN:
    LD    HL,FLOAT_TAU              ;[3223] HL -> 4.0 (full cycle constant)
    CALL  LNUM2                     ;[3226] WRA2 = 4.0
    CALL  DIV                       ;[3229] WRA1 = x/4 (normalise to [0, 1))
    CALL  FFRAC                     ;[322C] WRA1 = fractional part only
    LD    HL,FLOAT_N4               ;[322F] HL -> 4.0
    CALL  LNUM2                     ;[3232] WRA2 = 4.0
    CALL  _MULT                     ;[3235] WRA1 = frac(x/4) * 4, now in [0,4)
    LD    A,(SYSVAR_WRA1)           ;[3238] Load exponent (check sign)
    BIT   7,A                       ;[323B] Test sign bit (positive = bit 7 set in Lynx)
    JR    NZ,SIN2                   ;[323D] Non-negative: skip correction
    LD    HL,FLOAT_N4               ;[323F] HL -> 4.0 (add 4.0 to bring into [0,4))
    CALL  LNUM2                     ;[3242] WRA2 = 4.0
    CALL  ADD                       ;[3245] WRA1 += 4.0 (map negative to [0,4))
SIN2:
    LD    HL,FLOAT_N1               ;[3248] HL -> 1.0
    CALL  LNUM2                     ;[324B] WRA2 = 1.0
    CALL  CMP                       ;[324E] Compare WRA1 with 1.0
    JR    NC,SIN1                   ;[3251] WRA1 < 1.0: first quadrant, use as-is
    CALL  SWAP                      ;[3253] WRA1 >= 1.0: 1<=x<4, swap for mirror test
    LD    HL,FLOAT_N3               ;[3256] HL -> 3.0
    CALL  LNUM1                     ;[3259] WRA1 = 3.0
    CALL  CMP                       ;[325C] Compare WRA1 (3.0) with WRA2 (x)
    JR    NC,SIN3                   ;[325F] x >= 3.0: fourth quadrant
    LD    HL,FLOAT_N2               ;[3261] HL -> 2.0
    CALL  LNUM1                     ;[3264] WRA1 = 2.0
    CALL  SUB                       ;[3267] WRA1 = 2.0 - x (mirror around 1.0)
    JR    SIN1                      ;[326A] Evaluate with mirrored argument
SIN3:
    LD    HL,FLOAT_N4               ;[326C] HL -> 4.0
    CALL  LNUM1                     ;[326F] WRA1 = 4.0
    CALL  SWAP                      ;[3272] WRA1 = x (fourth quadrant), WRA2 = 4.0
    CALL  SUB                       ;[3275] WRA1 = x - 4.0 (fold into [-1,0])
SIN1:
    CALL  PUSH_WRA1                 ;[3278] Save reduced argument x
    CALL  SQUARE                    ;[327B] WRA1 = x^2
    LD    IX,DATA_SINCOS            ;[327E] IX -> SIN/COS Chebyshev coefficients
    CALL  SERIES                    ;[3282] WRA1 = polynomial(x^2)
    CALL  POP_WRA2                  ;[3285] WRA2 = x (restore)
    JP    _MULT                     ;[3288] WRA1 = polynomial(x^2) * x = SIN(x)

;
; DATA_SINCOS: 4 Chebyshev polynomial coefficients for SIN/COS calculation.
;
DATA_SINCOS:
    DB $04,$BC,$15,$14,$84,$19,$3D,$46      ;[328B] Count=4, coefficient 1
    DB $73,$76,$56,$BE,$79,$68,$96,$79      ;[3293] Coefficients 2-3
    DB $3F,$64,$59,$63,$71,$C0,$15,$70      ;[329B] Coefficient 4 (start)
    DB $79,$63                              ;[32A3] Coefficient 4 (end)

;
; FNOT: BASIC NOT operator - logical NOT.
; Pops WRA2 from IY stack (CSW1), then returns 1.0 if WRA1 is zero, else 0.0.
;
FNOT:
    CALL  CSW1                      ;[32A5] Pop IY stack -> WRA2 (discard saved value)
FNOT1:
    LD    A,(SYSVAR_WRA1)           ;[32A8] Load exponent of WRA1
    CP    $80                       ;[32AB] Is WRA1 zero (exponent = $80)?
    JR    FQ1                       ;[32AD] Branch: if zero, return 1.0; else 0.0

;
; FEQUAL: BASIC = comparison operator.
; Returns 1.0 (true) if WRA1 = WRA2, else 0.0 (false).
;
FEQUAL:
    CALL  CMP                       ;[32AF] Compare WRA1 with WRA2; sets Z if equal
FQ1:
    LD    HL,FLOAT_ZERO             ;[32B2] Assume false (0.0)
    JR    NZ,FQ2                    ;[32B5] Not equal/true: load FLOAT_ZERO
    LD    HL,FLOAT_N1               ;[32B7] Equal/zero: load 1.0
FQ2:
    JP    LNUM1                     ;[32BA] WRA1 = selected float constant

;
; FNOT_EQUAL: BASIC <> operator - not equal.
; Returns 1.0 if WRA1 <> WRA2, else 0.0.
;
FNOT_EQUAL:
    CALL  FEQUAL                    ;[32BD] Compute equality (1.0 if equal)
    JR    FNOT1                     ;[32C0] Invert the result

;
; FGREATERTHAN: BASIC > operator.
; Returns 1.0 if WRA1 > WRA2, else 0.0.
;
FGREATERTHAN:
    NOP                             ;[32C2] Alignment padding
FG3:
    CALL  CMP                       ;[32C3] Compare WRA1 vs WRA2; carry set if WRA1 < WRA2
FG2:
    LD    HL,FLOAT_N1               ;[32C6] HL -> 1.0 (true)
    JR    C,FQ2                     ;[32C9] Carry set = WRA1 > WRA2 (after accounting for arg order)
    LD    HL,FLOAT_ZERO             ;[32CB] HL -> 0.0 (false)
    JR    FQ2                       ;[32CE] Return the selected value

;
; FLT_EQUAL: BASIC <= operator (less than or equal).
; Returns 1.0 if WRA1 <= WRA2.
;
FLT_EQUAL:
    CALL  FGREATERTHAN              ;[32D0] Compute > result (1.0 if greater)
    JR    FNOT1                     ;[32D3] Invert

;
; FLESSTHAN: BASIC < operator.
; Swaps WRA1 and WRA2 then uses the > logic.
;
FLESSTHAN:
    CALL  SWAP                      ;[32D5] Reverse argument order
    JR    FG3                       ;[32D8] Now CMP gives < logic

;
; FGT_EQUAL: BASIC >= operator (greater than or equal).
;
FGT_EQUAL:
    CALL  FLESSTHAN                 ;[32DA] Compute < result (1.0 if less)
    JR    FNOT1                     ;[32DD] Invert

;
; FNOR: BASIC OR operator.
; Returns 1.0 if either WRA1 or WRA2 is non-zero, else 0.0.
;
FNOR:
    LD    A,(SYSVAR_WRA1)           ;[32DF] Load WRA1 exponent
    CP    $80                       ;[32E2] Is WRA1 zero?
    JR    NZ,FNR2                   ;[32E4] WRA1 non-zero: result is 1.0 regardless of WRA2
    LD    A,(SYSVAR_WRA2)           ;[32E6] WRA1 is zero: check WRA2
    CP    $80                       ;[32E9] Is WRA2 also zero?
FNR2:
    LD    HL,FLOAT_N1               ;[32EB] HL -> 1.0 (true)
    JR    NZ,FNR1                   ;[32EE] At least one non-zero: return 1.0
    LD    HL,FLOAT_ZERO             ;[32F0] Both zero: return 0.0
FNR1:
    JP    LNUM1                     ;[32F3] WRA1 = result

;
; FAND: BASIC AND operator.
; Returns 1.0 if both WRA1 and WRA2 are non-zero, else 0.0.
;
FAND:
    LD    A,(SYSVAR_WRA1)           ;[32F6] Load WRA1 exponent
    CP    $80                       ;[32F9] Is WRA1 zero?
    JR    Z,FNR2                    ;[32FB] Yes: result is 0.0 regardless of WRA2
    LD    A,(SYSVAR_WRA2)           ;[32FD] WRA1 non-zero: check WRA2
    CP    $80                       ;[3300] Is WRA2 zero?
    JR    FNR2                      ;[3302] Both paths lead to FNR2 (result based on Z flag)

;
; FFN1/FFN0: helper for inline function dispatch.
; CSW1 pops from IY stack; then retrieves the return address and a pointer
; from the hardware stack, steps IY back one token, and re-enters EE2 to
; dispatch the next function in a function-call chain.
;
FFN1:
    CALL  CSW1                      ;[3304] Pop IY calc stack -> WRA2
FFN0:
    POP   BC                        ;[3307] BC = return address (from previous EE call)
    POP   DE                        ;[3308] DE = pointer (line/expression pointer)
    DEC   IY                        ;[3309] Step IY back by one (re-read function token)
    LD    A,(IY+$00)                ;[330B] Read the function token byte
    JP    EE2                       ;[330E] Re-dispatch via function table

;
; FMINUS: BASIC unary minus / subtraction operator.
; Pops WRA2 from IY stack (via CSW1), then negates WRA1.
;
FMINUS:
    CALL  CSW1                      ;[3311] Pop IY stack into WRA2
    JP    NEGATE_WRA1               ;[3314] Negate WRA1

;
; FN_NEGATE1: helper to conditionally flip the sign of a float at (HL).
; Compares A with the byte at (HL): if equal, sign is already correct (RET Z).
; Otherwise XOR to toggle the sign bit and store back.
;
FN_NEGATE1:
    CP    (HL)                      ;[3317] Is A == exponent at (HL)?
    RET   Z                         ;[3318] Yes: no change needed
    XOR   (HL)                      ;[3319] Toggle sign bit
    LD    (HL),A                    ;[331A] Store updated exponent
    RET                             ;[331B]

    NOP                             ;[331C] Alignment padding

;
; FHIMEM: BASIC HIMEM function - returns the high memory address (top of free RAM).
; Reads SYSVAR_STACK, adds 2 (skips past the stack pointer word itself),
; then converts the 16-bit address to float via INTFP.
;
FHIMEM:
    LD    HL,(SYSVAR_STACK)         ;[331D] HL = current stack pointer low boundary
    INC   HL                        ;[3320] +1
    INC   HL                        ;[3321] +2 (skip past saved SP word)
    JR    FN_INP2                   ;[3322] Convert HL to float in WRA1

;
; FHL: BASIC HL() function - returns the current value of the HL register store.
; Used to retrieve a 16-bit value left by a USR call.
;
FHL:
    LD    HL,(SYSVAR_HLSTORE)       ;[3324] HL = value left in HL-store by previous USR
    JR    FN_INP2                   ;[3327] Convert to float

;
; FINP: BASIC INP() function - reads a byte from an I/O port.
; Converts argument to integer, uses as port address, reads via IN A,(C).
;
FINP:
    CALL  FPINT                     ;[3329] WRA1 -> integer in HL
    LD    C,L                       ;[332C] Port number low byte
    LD    B,H                       ;[332D] Port number high byte
    IN    A,(C)                     ;[332E] Read byte from port BC
FN_INP1:
    LD    L,A                       ;[3330] L = byte read
    LD    H,$00                     ;[3331] H = 0 (16-bit value)
FN_INP2:
    JP    INTFP                     ;[3333] Convert 16-bit HL to float in WRA1

;
; FDPEEK: BASIC DPEEK() function - reads a 16-bit word from memory.
; Converts argument to address, reads two bytes, assembles little-endian word.
;
FDPEEK:
    CALL  FPINT                     ;[3336] WRA1 -> address in HL
    LD    A,(HL)                    ;[3339] Read low byte
    INC   HL                        ;[333A] Advance to high byte
    LD    H,(HL)                    ;[333B] H = high byte
    LD    L,A                       ;[333C] L = low byte
    JR    FN_INP2                   ;[333D] Convert 16-bit HL to float

;
; FPEEK: BASIC PEEK() function - reads a single byte from memory.
;
FPEEK:
    CALL  FPINT                     ;[333F] WRA1 -> address in HL
    LD    A,(HL)                    ;[3342] Read byte at address
    JR    FN_INP1                   ;[3343] Zero-extend and convert to float

;
; FDEG: BASIC DEG() function - converts radians to degrees.
; Multiplies by 360/(2*PI) = 180/PI using the SUB_ANGLE constant.
;
FDEG:
    LD    HL,SUB_ANGLE              ;[3345] HL -> degrees conversion constant
    CALL  LNUM2                     ;[3348] WRA2 = constant
    JP    _MULT                     ;[334B] WRA1 = radians * (180/PI) = degrees

;
; FRAD: BASIC RAD() function - converts degrees to radians.
; Divides by the same constant (360/(2*PI)).
;
FRAD:
    LD    HL,SUB_ANGLE              ;[334E] HL -> degrees conversion constant
    CALL  LNUM2                     ;[3351] WRA2 = constant
    JP    DIV                       ;[3354] WRA1 = degrees / (180/PI) = radians

;
; SUB_ANGLE: data constant for DEG/RAD conversion.
; Note: the first two bytes look like code (POP BC / LD D,A) but this is just
; the BCD float data bytes - this area is only reached via LNUM2/LNUM1 data loads.
;
SUB_ANGLE:
    POP   BC                        ;[3357] (data byte as opcode - only data path used)
    LD    D,A                       ;[3358] (data byte)
    ADD   HL,HL                     ;[3359] (data byte)
    LD    D,A                       ;[335A] (data byte)
    ADD   A,B                       ;[335B] (data byte: end of 5-byte float constant)

;
; ESTRS: compare the string at (IX) with the string at SYSVAR_STRBUF.
; Used by string comparison operators. Sets Z if strings match.
;
ESTRS:
    LD    IX,SYSVAR_STRBUF+128      ;[335C] IX -> second string buffer area
    CALL  ESE1                      ;[3360] Evaluate/copy string into (IX) buffer
    INC   DE                        ;[3363] Skip past string terminator
    PUSH  DE                        ;[3364] Save expression pointer
    LD    DE,SYSVAR_STRBUF+128      ;[3365] DE -> second string
    LD    HL,SYSVAR_STRBUF          ;[3368] HL -> first string
ESTRS1:
    LD    A,(DE)                    ;[336B] Load byte from second string
    CP    (HL)                      ;[336C] Compare with byte from first string
    JR    NZ,ESTRS2                 ;[336D] Mismatch: stop comparing
    INC   DE                        ;[336F] Advance second string pointer
    INC   HL                        ;[3370] Advance first string pointer
    CP    SZ                        ;[3371] Was this the string terminator (SZ)?
    JR    NZ,ESTRS1                 ;[3373] No: keep comparing
ESTRS2:
    POP   DE                        ;[3375] Restore expression pointer
    RET                             ;[3376] Z set if strings matched completely

;
; ESTR: evaluate a string comparison expression.
; Handles = operator (exact match) and < operator (string less-than).
;
ESTR:
    CALL  ESEE                      ;[3377] Evaluate first string operand -> SYSVAR_STRBUF
    LD    A,(DE)                    ;[337A] Read next token
    INC   DE                        ;[337B] Advance pointer
    CP    '='                       ;[337C] Is it '=' (equality)?
    JR    NZ,ESTR3                  ;[337E] No: check other operators
    CALL  ESTRS                     ;[3380] Compare strings; Z if equal
    PUSH  DE                        ;[3383] Save expression pointer
    LD    DE,FLOAT_N1               ;[3384] DE -> 1.0 (true)
    JR    Z,ESTR2                   ;[3387] Strings equal: return 1.0
ESTR1:
    LD    DE,FLOAT_ZERO             ;[3389] Not equal/not less-than: return 0.0
ESTR2:
    CALL  LCST                      ;[338C] Load float constant onto IY calc stack
    POP   DE                        ;[338F] Restore expression pointer
    RET                             ;[3390]

;
; ESTR3: handle string comparison operators other than =.
; Compares strings and checks the carry flag for < result.
;
ESTR3:
    CALL  ESTRS                     ;[3391] Compare strings; carry if first < second
    PUSH  DE                        ;[3394] Save expression pointer
    LD    DE,FLOAT_N1               ;[3395] DE -> 1.0 (true)
    JR    C,ESTR2                   ;[3398] Carry set: first < second, return 1.0
    JR    ESTR1                     ;[339A] Not less-than: return 0.0

;
; EESARG: handle a string argument (ARGSOS token) in expression evaluation.
; Advances DE past two bytes then re-enters EE1.
;
EESARG:
    CALL  ESEE                      ;[339C] Evaluate string argument
    INC   DE                        ;[339F] Skip first extra byte
    INC   DE                        ;[33A0] Skip second extra byte
    JR    EE1                       ;[33A1] Continue expression evaluation

;
; ESTRING: handle a string literal (SOS token) in expression evaluation.
;
ESTRING:
    CALL  ESTR                      ;[33A3] Evaluate string comparison
    JP    EE1                       ;[33A6] Continue expression evaluation

;
; EE: Evaluate a reverse-polish (tokenised) expression.
; Initialises IY to the calculation stack base (SYSVAR_CSTACK) then enters EE1.
;
EE:
    LD    IY,SYSVAR_CSTACK          ;[33A9] IY = calculation stack base address

;
; EE1: main expression evaluation loop.
; Dispatches on the current token in the expression pointed to by DE.
; Tokens: NUM/HNUM (number literal), 0-52 (variable), 53-116 (array),
;         EOP (end), PARENS (ignored), functions, and operators.
;
EE1:
    LD    A,(DE)                    ;[33AD] Read next token from expression
    INC   DE                        ;[33AE] Advance expression pointer
    CP    ARGSOS                    ;[33AF] String argument token?
    JR    Z,EESARG                  ;[33B1] Yes
    CP    SOS                       ;[33B3] String literal token?
    JR    Z,ESTRING                 ;[33B5] Yes
    CP    NUM                       ;[33B7] Numeric literal (decimal)?
    JR    Z,EENUM                   ;[33B9] Yes
    CP    HNUM                      ;[33BB] Numeric literal (hex)?
    JR    Z,EENUM                   ;[33BD] Yes
    CP    53                        ;[33BF] Token < 53 = simple variable?
    JR    C,EEVAR                   ;[33C1] Yes: load variable
    CP    64+53                     ;[33C3] Token < 117 = array variable?
    JR    C,EEARY                   ;[33C5] Yes: load array element
    CP    EOP                       ;[33C7] End-of-expression token?
    JR    Z,EEX                     ;[33C9] Yes: exit
    CP    PARENS                    ;[33CB] Parentheses token (used as no-op)?
    JR    Z,EE1                     ;[33CD] Yes: skip it
    JR    C,EEARY                   ;[33CF] Token in array range: treat as array/function
    CP    THEN                      ;[33D1] Token >= THEN = unexpected keyword?
    CALL  NC,ERR_SOMETHG_MISSG      ;[33D3] Yes: syntax error

;
; EE2: dispatch an operator or function token.
; IX -> function dispatch table (SYSVAR_FTBL).
; For tokens >= $C6 (binary operators), pops WRA1 from calc stack first.
; Doubles token value as table index (each entry is a 2-byte address).
;
EE2:
    LD    IX,(SYSVAR_FTBL)          ;[33D6] IX -> function/operator dispatch table
    PUSH  DE                        ;[33DA] Save expression pointer
    CP    $C6                       ;[33DB] Is token a binary operator (>= $C6)?
    PUSH  AF                        ;[33DD] Save token
    CALL  NC,IY_TO_WRA1             ;[33DE] Yes: pop first operand from calc stack into WRA1
    POP   AF                        ;[33E1] Restore token
    SLA   A                         ;[33E2] A *= 2 (word index into table)
    LD    C,A                       ;[33E4] Low byte of offset
    LD    B,$00                     ;[33E5] High byte = 0
    ADD   IX,BC                     ;[33E7] IX -> correct table entry
    LD    L,(IX+$00)                ;[33E9] Read function address low byte
    LD    H,(IX+$01)                ;[33EC] Read function address high byte
    LD    BC,EERENT                 ;[33EF] BC = return address (EERENT)
    PUSH  BC                        ;[33F2] Push return address onto stack
    JP    (HL)                      ;[33F3] Jump to the function/operator handler

;
; EERENT: re-entry point after a function/operator handler returns.
; Pushes WRA1 result onto the IY calc stack, then loops back to EE1.
;
EERENT:
    POP   DE                        ;[33F4] Restore expression pointer
    CALL  WRA1_TO_IY                ;[33F5] Push result onto calc stack
    JP    EE1                       ;[33F8] Evaluate next token

;
; EENUM: load a numeric literal from the expression stream onto the calc stack.
; The 5-byte BCD float immediately follows the NUM/HNUM token in the tokenised line.
;
EENUM:
    CALL  LCST                      ;[33FB] Push 5-byte constant at (DE) onto IY stack; advance DE
    JR    EE1                       ;[33FE] Continue

;
; EEVAR: load a simple variable's value onto the IY calculation stack.
; Token value is 0-52, each variable occupies 5 bytes in the variable table.
;
EEVAR:
    PUSH  DE                        ;[3400] Save expression pointer
    LD    L,A                       ;[3401] L = token (variable index)
    LD    H,$00                     ;[3402] H = 0
    LD    E,L                       ;[3404] Save copy
    LD    D,H                       ;[3405]
    ADD   HL,HL                     ;[3406] HL = index * 2
    ADD   HL,HL                     ;[3407] HL = index * 4
    ADD   HL,DE                     ;[3408] HL = index * 5 (byte offset in variable table)
    LD    DE,(SYSVAR_VTBL)          ;[3409] DE -> variable table base
    ADD   HL,DE                     ;[340D] HL -> variable entry
    INC   HL                        ;[340E] HL -> first mantissa byte (skip exponent)
    LD    A,(HL)                    ;[340F] Read mantissa byte 1
    INC   A                         ;[3410] Test if $FF (uninitialised)
    DEC   HL                        ;[3411] Back to exponent byte
    CALL  Z,ERR_UNDEFINED_VAR       ;[3412] $FF mantissa = variable not yet assigned
    EX    DE,HL                     ;[3415] DE -> variable data (5 bytes)
    CALL  LCST                      ;[3416] Copy 5 bytes from (DE) onto IY calc stack
    POP   DE                        ;[3419] Restore expression pointer
    JP    EE1                       ;[341A] Continue expression evaluation

;
; EEARY: push a raw token byte onto the IY stack as a deferred array reference.
; Array lookups happen later during operator dispatch.
;
EEARY:
    LD    (IY+$00),A                ;[341D] Store array token byte on calc stack
    INC   IY                        ;[3420] Advance calc stack pointer
    JP    EE1                       ;[3422] Continue expression evaluation

;
; EEX: expression evaluation complete.
; Pop the final result from the IY stack into WRA1.
;
EEX:
    JP    CSW1                      ;[3425] Pop IY stack -> WRA1 (result)

;
; LCST: copy a 5-byte BCD float literal from (DE) onto the IY calculation stack.
; DE is advanced by 5 on return. Used for inline numeric literals.
;
LCST:
    LD    B,$05                     ;[3428] 5 bytes to copy
LS1:
    LD    A,(DE)                    ;[342A] Read byte from source
    LD    (IY+$00),A                ;[342B] Write to calc stack
    INC   DE                        ;[342E] Advance source
    INC   IY                        ;[342F] Advance calc stack pointer
    DJNZ  LS1                       ;[3431] Repeat for all 5 bytes
    RET                             ;[3433]

;
; FABS: BASIC ABS() function - absolute value of WRA1.
; Forces the sign bit (bit 7 of exponent) to 1 (positive in Lynx convention).
;
FABSLTE:
    LD    HL,SYSVAR_WRA1            ;[3434] HL -> exponent byte
    SET   7,(HL)                    ;[3437] Set bit 7 = force positive
    RET                             ;[3439]

;
; FSGN: BASIC SGN() function - sign of WRA1.
; Returns: 1.0 if positive, -1.0 if negative, 0.0 if zero.
;
FSGN:
    LD    A,(SYSVAR_WRA1)           ;[343A] Load exponent (bit 7 = sign)
    PUSH  AF                        ;[343D] Save exponent
    CALL  LZERO                     ;[343E] Set WRA1 = 0.0 (clear mantissa)
    POP   AF                        ;[3441] Restore saved exponent
    CP    $80                       ;[3442] Was WRA1 zero (exponent = $80)?
    RET   Z                         ;[3444] Yes: SGN(0) = 0
    LD    HL,SYSVAR_WRA1+$01        ;[3445] HL -> mantissa byte 1
    SET   4,(HL)                    ;[3448] Set bit 4 = BCD digit 1 (makes mantissa = $10)
    BIT   7,A                       ;[344A] Was number positive (bit 7 set)?
    LD    A,$40                     ;[344C] A = $40 (negative exponent encoding: -1.0)
    JR    Z,SIGN1                   ;[344E] Number was negative: use $40 (-1)
    LD    A,$C0                     ;[3450] A = $C0 (positive exponent encoding: +1.0)
SIGN1:
    LD    (SYSVAR_WRA1),A           ;[3452] Store exponent: WRA1 = ±1.0
    RET                             ;[3455]

;
; FINT: BASIC INT() function - integer part of WRA1 (truncate toward zero).
; If exponent implies 8+ digits (>= $47), number is already integer: return as-is.
; If exponent implies < 1 (< $40), number is purely fractional: return 0.
; Otherwise: rotate digits right to remove fractional part, then rotate 0s back.
;
FINT:
    LD    A,(SYSVAR_WRA1)           ;[3456] Load exponent
    RES   7,A                       ;[3459] Remove sign bit (work with magnitude)
    CP    $47                       ;[345B] >= $47 means >= 8 digits (all integer)?
    RET   NC                        ;[345D] Yes: already an integer
    CP    $40                       ;[345E] < $40 means exponent < 1?
    JP    C,LZERO                   ;[3460] Yes: purely fractional, INT = 0
    SUB   $47                       ;[3463] Number of fractional digits (negative)
    NEG                             ;[3465] Make positive: digits to rotate
    LD    B,A                       ;[3467] B = rotation count
    PUSH  BC                        ;[3468] Save
BASIC_FN_INT1:
    CALL  RRD1A                     ;[3469] Rotate right (shift out fractional BCD digit)
    DJNZ  BASIC_FN_INT1             ;[346C] Repeat
    POP   BC                        ;[346E] Restore count
BASIC_FN_INT2:
    CALL  RL10                      ;[346F] Rotate 0 back in (restore digit count)
    DJNZ  BASIC_FN_INT2             ;[3472] Repeat same count
    RET                             ;[3474] WRA1 = INT(original)

;
; FFRAC: BASIC FRAC() function - fractional part of WRA1 (WRA1 - INT(WRA1)).
; If exponent >= $47 (8+ digits), there is no fractional part: return 0.
; If exponent < $40 (pure fraction), return as-is.
; Otherwise: shift out integer digits by rotating left, re-align.
;
FFRAC:
    LD    A,(SYSVAR_WRA1)           ;[3475] Load exponent
    RES   7,A                       ;[3478] Strip sign bit
    CP    $47                       ;[347A] >= 8 digits?
    JP    NC,LZERO                  ;[347C] Yes: no fractional part, return 0
    CP    $40                       ;[347F] < 1.0?
    RET   C                         ;[3481] Yes: entirely fractional, return as-is
    SUB   $3F                       ;[3482] Count of integer digits to shift out
    LD    B,A                       ;[3484] B = shift count
    LD    A,(SYSVAR_WRA1)           ;[3485] Reload exponent with sign
    AND   $C0                       ;[3488] Keep sign+type bits only
    DEC   A                         ;[348A] Decrement (adjust exponent for post-shift)
    LD    (SYSVAR_WRA1),A           ;[348B] Store adjusted exponent
FR1:
    CALL  RL10                      ;[348E] Rotate left: shift integer digit out of MSB
    DJNZ  FR1                       ;[3491] Repeat for all integer digits
    OR    A                         ;[3493] Clear carry
    JP    ALIGN                     ;[3494] Re-normalise the remaining fraction

;
; FPINT: convert the float in WRA1 to a 16-bit integer in HL.
; Handles the special case of exponent = $C0 (value = 1.0) directly via FPINT1.
; Otherwise falls through to FPINTA for the general case.
;
FPINT:
    LD    A,(SYSVAR_WRA1)           ;[3497] Load exponent
    CP    $C0                       ;[349A] Is exponent exactly $C0 (10^0 = 1.0)?
    JP    Z,FPINT1                  ;[349C] Yes: special-case path
FPINTA:
    LD    HL,$0000                  ;[349F] HL = 0 (accumulator)
    BIT   7,A                       ;[34A2] Is number negative (bit 7 clear = negative)?
    CALL  Z,ERR_NUM_OUT_RANGE       ;[34A4] Yes: negative numbers can't be converted (unsigned)
    CP    $C0                       ;[34A7] Is exponent < $C0 (< 1.0)?
    RET   C                         ;[34A9] Yes: fractional part only, HL = 0
    CP    $C7                       ;[34AA] Is exponent >= $C7 (> 9999999)?
    CALL  NC,ERR_NUM_OUT_RANGE      ;[34AC] Yes: too large for 16-bit
    SUB   $BF                       ;[34AF] A = number of BCD digits (1..7)
    LD    B,A                       ;[34B1] B = digit count
    PUSH  DE                        ;[34B2] Save DE
FI1:
    CALL  RL10                      ;[34B3] Rotate next BCD digit from WRA1 into A
    LD    E,L                       ;[34B6] HL * 10 + A:
    LD    D,H                       ;[34B7]   save old HL in DE
    ADD   HL,HL                     ;[34B8]   HL = HL * 2
    ADD   HL,HL                     ;[34B9]   HL = HL * 4
    ADD   HL,DE                     ;[34BA]   HL = HL * 5
    ADD   HL,HL                     ;[34BB]   HL = HL * 10
    LD    E,A                       ;[34BC]   E = BCD digit
    LD    D,$00                     ;[34BD]   D = 0
    ADD   HL,DE                     ;[34BF]   HL = HL * 10 + digit
    DJNZ  FI1                       ;[34C0] Repeat for all digits
    POP   DE                        ;[34C2] Restore DE
    RET                             ;[34C3] HL = integer value

;
; INTFP: convert the 16-bit integer in HL to a BCD float in WRA1.
; Uses a binary-to-BCD shift-left approach: for each of the 16 bits,
; doubles all BCD digits in WRA1 (with BCD carry) and adds the next bit.
;
INTFP:
    LD    A,$C7                     ;[34C4] A = $C7 (exponent for 5-digit number: 10^7)
    LD    (SYSVAR_WRA1),A           ;[34C6] Set WRA1 exponent (positive, 8 digits)
    PUSH  HL                        ;[34C9] Save input integer
    LD    HL,$0000                  ;[34CA] Clear mantissa bytes 1-4
    LD    (SYSVAR_WRA1+$03),HL      ;[34CD]
    LD    (SYSVAR_WRA1+$01),HL      ;[34D0]
    POP   HL                        ;[34D3] Restore input integer
    LD    B,16                      ;[34D4] Process 16 bits
INTFP1:
    ADD   HL,HL                     ;[34D6] Shift next bit into carry
    PUSH  BC                        ;[34D7] Save bit count
    PUSH  HL                        ;[34D8] Save remaining bits
    LD    B,$04                     ;[34D9] 4 mantissa bytes to process
    LD    HL,SYSVAR_WRA1+$04        ;[34DB] HL -> least significant mantissa byte
INTFP2:
    LD    A,(HL)                    ;[34DE] Load mantissa byte
    ADC   A,(HL)                    ;[34DF] Double it (BCD × 2) with carry from previous
    DAA                             ;[34E0] BCD-adjust the doubled value
    LD    (HL),A                    ;[34E1] Store back
    DEC   HL                        ;[34E2] Move to next more-significant byte

    DJNZ  INTFP2                    ;[34E3] Process all 4 mantissa bytes
    POP   HL                        ;[34E5] Restore remaining bits of integer
    POP   BC                        ;[34E6] Restore bit count
    DJNZ  INTFP1                    ;[34E7] Process next bit
    OR    A                         ;[34E9] Clear carry flag
    JP    ALIGN                     ;[34EA] Normalise WRA1 to standard BCD float form

;
; TEST_DIGIT: test if byte at (DE) is an ASCII decimal digit '0'-'9'.
; Returns: carry clear if digit, carry set if not.
;
TEST_DIGIT:
    LD    A,(DE)                    ;[34ED] Read byte at DE
    CP    '0'                       ;[34EE] Below '0'?
    RET   C                         ;[34F0] Yes: not a digit, carry set
    CP    '9'+1                     ;[34F1] Above '9'?
    CCF                             ;[34F3] Complement carry: carry set if > '9' -> NC if digit
    RET                             ;[34F4] NC = digit, C = not a digit

;
; TEST_ALPHA: test if byte at (DE) is an ASCII letter A-Z or a-z.
; Returns carry clear if alphabetic, carry set if not.
;
TEST_ALPHA:
    LD    A,(DE)                    ;[34F5] Read byte
    CP    'A'                       ;[34F6] Below 'A'?
    RET   C                         ;[34F8] Yes: not alpha
    CP    'Z'+1                     ;[34F9] In A-Z range?
    CCF                             ;[34FB] Complement: NC if in A-Z
    RET   NC                        ;[34FC] In A-Z: return (NC = alpha)
    CP    'a'                       ;[34FD] Below 'a'?
    RET   C                         ;[34FF] Yes: not alpha
    CP    'z'+1                     ;[3500] In a-z range?
    CCF                             ;[3502] Complement: NC if in a-z
    RET                             ;[3503] NC = alpha

;
; TEST_UPPER_LOW: test if byte at (DE) is an uppercase or lowercase letter.
; Strips to 0-25 range for uppercase, or 0-25 for lowercase.
; Returns carry if in range (A-Z or a-z mapped to 0-25).
;
TEST_UPPER_LOW:
    LD    A,(DE)                    ;[3504] Read byte
    SUB   'A'-1                     ;[3505] A -= 64: A='A'->1, A='Z'->26
    CP    27                        ;[3507] Is A < 27 (i.e. was char in 'A'-'Z')?
    RET   C                         ;[3509] Yes: uppercase letter, return with carry
    SUB   $06                       ;[350A] Adjust for lowercase gap ('a'-'Z' = 6)
    RET                             ;[350C] Returns mapped value; carry if in a-z

;
; ZWRA1: zero all 5 bytes of WRA1 (set the working register to 0.0).
;
ZWRA1:
    LD    HL,SYSVAR_WRA1            ;[350D] HL -> WRA1
    LD    B,$05                     ;[3510] 5 bytes to zero
ZW1:
    LD    (HL),$00                  ;[3512] Zero this byte
    INC   HL                        ;[3514] Next byte
    DJNZ  ZW1                       ;[3515]
    RET                             ;[3517]

;
; CRMSG: carriage-return / clear-to-end-of-line message.
; Used when outputting a newline to clear the rest of the display line.
;
CRMSG:
    DB    NEWLINE,CEL,0             ;[3518] Newline, clear-to-EOL, string terminator

;
; PUTCHAR: output character in A to the screen.
; If character is CR ($0D), outputs the CRMSG sequence (newline + clear-to-EOL)
; instead. Otherwise falls through to DISPLAYB.
;
PUTCHAR:
    PUSH  AF                        ;[351B] Save character
    CP    $0D                       ;[351C] Is it CR?
    JR    NZ,DISPLAYB1              ;[351E] No: output as-is
    PUSH  HL                        ;[3520] Yes: output CRMSG sequence
    LD    HL,(SYSVAR_CRST)          ;[3521] HL -> CR string (CRMSG or custom)
    CALL  PLINE                     ;[3524] Output the string
    POP   HL                        ;[3527] Restore HL
    POP   AF                        ;[3528] Restore A
    RET                             ;[3529]

;
; DISPLAY_SPACE: output a space character.
;
DISPLAY_SPACE:
    PUSH  AF                        ;[352A] Save caller's A
    LD    A,' '                     ;[352B] Load space
    JR    DISPLAYB1                 ;[352D] Output it

;
; DISPLAYB: output character in A, preserving HL, BC, AF.
;
DISPLAYB:
    PUSH  AF                        ;[352F] Save A
DISPLAYB1:
    PUSH  HL                        ;[3530] Save HL
    PUSH  BC                        ;[3531] Save BC
    CALL  SUB_PUTCHAR               ;[3532] Output character via system routine
    POP   BC                        ;[3535] Restore BC
    POP   HL                        ;[3536] Restore HL
    POP   AF                        ;[3537] Restore AF
    RET                             ;[3538]

;
; PLINE: output null-terminated string pointed to by HL.
;
PLINE:
    LD    A,(HL)                    ;[3539] Read byte
    INC   HL                        ;[353A] Advance pointer
    OR    A                         ;[353B] Is it null terminator?
    RET   Z                         ;[353C] Yes: done
    CALL  DISPLAYB                  ;[353D] Output character
    JR    PLINE                     ;[3540] Next character

;
; SWAP: exchange the contents of WRA1 and WRA2 (5 bytes each).
;
SWAP:
    LD    HL,SYSVAR_WRA1            ;[3542] HL -> WRA1
    LD    DE,SYSVAR_WRA2            ;[3545] DE -> WRA2
    LD    B,$05                     ;[3548] 5 bytes
SWAP1:
    LD    C,(HL)                    ;[354A] C = byte from WRA1
    LD    A,(DE)                    ;[354B] A = byte from WRA2
    EX    DE,HL                     ;[354C] Swap pointers
    LD    (HL),C                    ;[354D] WRA2 byte = old WRA1 byte
    LD    (DE),A                    ;[354E] WRA1 byte = old WRA2 byte
    INC   DE                        ;[354F] Advance both pointers
    INC   HL                        ;[3550]
    DJNZ  SWAP1                     ;[3551]
    RET                             ;[3553]

;
; NEGATE_WRA2: negate the sign bit of WRA2 (flip positive/negative).
;
NEGATE_WRA2:
    LD    HL,SYSVAR_WRA2            ;[3554] HL -> WRA2 exponent byte
    JR    NEGATE3                   ;[3557]

;
; NEGATE_WRA1: negate the sign bit of WRA1.
;
NEGATE_WRA1:
    LD    HL,SYSVAR_WRA1            ;[3559] HL -> WRA1 exponent byte
NEGATE3:
    LD    A,$80                     ;[355C] Mask to test/flip sign bit
    JP    FN_NEGATE1                ;[355E] XOR sign bit if not already zero

;
; CMP: compare WRA2 with WRA1, setting flags as for (WRA2 - WRA1).
; Returns Z if equal. If not equal, accounts for sign conventions:
; if the result register (WRA1) is positive (bit 7 set), flags are as CMPS.
; If WRA1 is negative, the carry from CMPS is complemented.
;
CMP:
    CALL  CMPS                      ;[3561] Unsigned magnitude compare; sets Z if equal
    RET   Z                         ;[3564] Equal: done
    PUSH  AF                        ;[3565] Save flags
    LD    HL,SYSVAR_WRA1            ;[3566] HL -> WRA1
    BIT   7,(HL)                    ;[3569] Is WRA1 positive (bit 7 set)?
    JR    NZ,CMPX1                  ;[356B] Yes: result already correct
    LD    HL,SYSVAR_WRA2            ;[356D] HL -> WRA2
    BIT   7,(HL)                    ;[3570] Is WRA2 positive?
    JR    NZ,CMPX1                  ;[3572] Yes: result already correct
    POP   AF                        ;[3574] Both negative: complement carry
    CCF                             ;[3575] Flip carry (reverse sense for negatives)
    RET                             ;[3576]
CMPX1:
    POP   AF                        ;[3577] Restore flags unchanged
    RET                             ;[3578]

;
; CMPS: compare WRA1 and WRA2 byte-by-byte (unsigned / signed-exponent).
; Compares all 5 bytes from MSB (exponent) to LSB.
; Returns: Z if equal, NZ+carry if WRA2 > WRA1.
;
CMPS:
    LD    HL,SYSVAR_WRA1            ;[3579] HL -> WRA1
    LD    DE,SYSVAR_WRA2            ;[357C] DE -> WRA2
    LD    B,$05                     ;[357F] 5 bytes to compare
CMP1:
    LD    A,(DE)                    ;[3581] Load WRA2 byte
    CP    (HL)                      ;[3582] Compare with WRA1 byte
CMP2:
    RET   NZ                        ;[3583] Difference found: return with flags set
    INC   HL                        ;[3584] Next byte
    INC   DE                        ;[3585]
    DJNZ  CMP1                      ;[3586] Repeat for all 5 bytes
    RET                             ;[3588] All bytes equal: Z set

;
; CPABS: compare the absolute values (magnitudes) of WRA1 and WRA2.
; Ignores the sign bit; used by the addition routine to order operands.
;
CPABS:
    LD    HL,SYSVAR_WRA1            ;[3589] HL -> WRA1
    LD    DE,SYSVAR_WRA2            ;[358C] DE -> WRA2
    LD    A,(DE)                    ;[358F] Load WRA2 exponent
    RES   7,A                       ;[3590] Strip sign bit (absolute value)
    LD    C,(HL)                    ;[3592] Load WRA1 exponent
    RES   7,C                       ;[3593] Strip sign bit
    CP    C                         ;[3595] Compare unsigned magnitudes
    LD    B,$05                     ;[3596] Set up for byte-by-byte comparison
    JR    CMP2                      ;[3598] If exponents differ, return; else fall into byte compare

;
; ALIGN: normalise the BCD floating-point number in WRA1 after an arithmetic operation.
; C contains an overflow/underflow correction value from the operation.
; Calls ALN1 first (handle carry-out or shift left to normalise),
; then adjusts the exponent and checks for overflow/underflow.
;
ALIGN:
    CALL  ALN1                      ;[359A] Handle carry/normalise: updates C
    LD    A,(SYSVAR_WRA1)           ;[359D] Load exponent
    RES   7,A                       ;[35A0] Strip sign bit
    ADD   A,C                       ;[35A2] Apply exponent correction from ALN1
    JR    Z,LZERO                   ;[35A3] Exponent became 0: result is zero
    BIT   7,A                       ;[35A5] Bit 7 set after add = overflow/underflow
    JR    Z,ALN3                    ;[35A7] No overflow: go store corrected exponent
    CP    $C0                       ;[35A9] Did it wrap above (>= $C0 means underflow wrapped)
    CALL  C,ERR_OVERFLOW            ;[35AB] Below $C0 wrap: overflow error
    ; Falls through to LZERO (underflow: result too small, return 0)

;
; LZERO: load WRA1 with 0.0 (floating-point zero).
; Falls through to LNUM1 with HL -> FLOAT_ZERO.
;
LZERO:
    LD    HL,FLOAT_ZERO             ;[35AE] HL -> zero constant

;
; LNUM1: copy the 5-byte BCD float at (HL) into WRA1.
;
LNUM1:
    LD    DE,SYSVAR_WRA1            ;[35B1] DE -> WRA1
NUM_HL_TO_WRA:
    LD    BC,5                      ;[35B4] 5 bytes to copy
    LDIR                            ;[35B7] Copy (HL) -> (DE)
    RET                             ;[35B9]

;
; LNUM2: copy the 5-byte BCD float at (HL) into WRA2.
;
LNUM2:
    LD    DE,SYSVAR_WRA2            ;[35BA] DE -> WRA2
    JR    NUM_HL_TO_WRA             ;[35BD] Reuse copy loop

;
; LONE: load WRA1 with 1.0 (floating-point one).
;
LONE:
    LD    HL,FLOAT_N1               ;[35BF] HL -> FLOAT_N1 (1.0)
    JR    LNUM1                     ;[35C2] Copy into WRA1

;
; Pre-defined BCD floating-point constants.
; Format: [exponent][m1][m2][m3][m4]
;   exponent: bit7=sign (1=pos,0=neg), bits6-0 = power (bias $40, so $C0 = 10^0)
;   mantissa: 8 BCD digits packed into 4 bytes
;
FLOAT_N1:    DB $C0,$10,$00,$00,$00 ;[35C4] 1.0         (exp=$C0=10^0, mantissa=1.0000000)
FLOAT_N2:    DB $C0,$20,$00,$00,$00 ;[35C9] 2.0
FLOAT_N3:    DB $C0,$30,$00,$00,$00 ;[35CE] 3.0
FLOAT_N4:    DB $C0,$40,$00,$00,$00 ;[35D3] 4.0
FLOAT_64k:   DB $C4,$65,$53,$60,$00 ;[35D8] 65536.0     (2^16, used for USR return values)
FLOAT_TAU:   DB $C0,$62,$83,$18,$53 ;[35DD] 6.2831853   (2*PI = TAU, full circle)
FLOAT_NPI2:  DB $C0,$15,$70,$79,$63 ;[35E2] 1.5707963   (PI/2)
FLOAT_NPI4:  DB $BF,$78,$53,$98,$16 ;[35E7] 0.7853982   (PI/4)
FLOAT_RTAU:  DB $C0,$25,$06,$62,$83 ;[35EC] 2.5066283   (SQRT(2*PI), used by FFACT)
FLOAT_LOGE:  DB $BF,$43,$42,$94,$48 ;[35F1] 0.43429448  (log10(e), used by FLN/FEXP)
FLOAT_SQ10:  DB $C0,$31,$62,$27,$76 ;[35F6] 3.1622776   (SQRT(10), used by FLOG)
FLOAT_HALF:  DB $BF,$50,$00,$00,$00 ;[35FB] 0.5
FLOAT_MHALF: DB $3F,$50,$00,$00,$00 ;[3600] -0.5        (sign bit 0 = negative)
FLOAT_ZERO:  DB $80,$00,$00,$00,$00 ;[3605] 0.0         (exponent $80 = zero sentinel)

;
; DATA_EXEC: data used by EXEC to reset the arithmetic context.
;
DATA_EXEC:
    DB    6,$80                     ;[360A] 6 bytes follows; $80 = zero exponent

;
; FPI: BASIC PI constant function.
; Loads WRA1 with the value of PI (3.1415927).
;
FPI:
    LD    HL,DATA_NPI               ;[360C] HL -> PI constant
    JR    LNUM1                     ;[360F] Copy into WRA1

;
; DATA_NPI: BCD float constant for PI = 3.1415927.
;
DATA_NPI:
    DB $C0,$31,$41,$59,$27          ;[3611] PI = 3.1415927 (8 significant digits)

;
; ALN3: complete ALIGN when no overflow occurred.
; Restores the sign bit and stores the corrected exponent.
;
ALN3:
    LD    A,(SYSVAR_WRA1)           ;[3616] Load original exponent (with sign)
    ADD   A,C                       ;[3619] Apply correction C
    LD    (SYSVAR_WRA1),A           ;[361A] Store updated exponent
    RET                             ;[361D]

;
; ALN1: pre-normalise step for ALIGN.
; C is initialised to 0. If there was a carry-out from the last BCD operation
; (indicated by carry flag on entry), shifts WRA1 right by one BCD digit (calls
; RRD1A with A=1) and increments the correction C.
; If no carry, shifts WRA1 left (RL10 calls) until the top BCD digit is non-zero,
; decrementing C for each shift.
;
ALN1:
    LD    BC,$0900                  ;[361E] B=9 (max left-shift iterations), C=0 (correction)
    JR    NC,ALN2                   ;[3621] No carry-out: normalise left
    LD    A,$01                     ;[3623] A=1: digit to rotate in at the top
    CALL  RRD1A                     ;[3625] Shift WRA1 right by one BCD digit
    INC   C                         ;[3628] Correction += 1 (exponent increases by 1)
    RET                             ;[3629]

;
; ALN2: left-normalise WRA1 (shift left until top BCD digit is non-zero).
;
ALN2:
    LD    A,(SYSVAR_WRA1+$01)       ;[362A] Load top mantissa byte (two most-significant BCD digits)
    CP    $10                       ;[362D] Is the most-significant digit non-zero (>= $10)?
    RET   NC                        ;[362F] Yes: normalised, done
    DEC   C                         ;[3630] Correction -= 1 (exponent decreases by 1)
    CALL  RL10                      ;[3631] Rotate WRA1 left one BCD digit (insert 0 at LSB)
    DJNZ  ALN2                      ;[3634] Repeat up to 9 times
    POP   HL                        ;[3636] Exhausted shifts: pop return address (discard ALN1 frame)
    JP    LZERO                     ;[3637] Underflow to zero

;
; RRD20: rotate WRA2 right by one BCD digit, inserting 0 at the MSB.
; RRD2A: same but with A as the digit to insert at the MSB.
;
RRD20:
    XOR   A                         ;[363A] A = 0 (digit to insert)
RRD2A:
    PUSH  HL                        ;[363B] Save HL
    PUSH  BC                        ;[363C] Save BC
    LD    HL,SYSVAR_WRA2+$01        ;[363D] HL -> WRA2 mantissa start
    JR    RR2                       ;[3640] Perform the rotation

;
; RRD10: rotate WRA1 right by one BCD digit, inserting 0 at the MSB.
; RRD1A: same but with A as the digit to insert at the MSB.
;
RRD10:
    XOR   A                         ;[3642] A = 0 (digit to insert)
RRD1A:
    PUSH  HL                        ;[3643] Save HL
    PUSH  BC                        ;[3644] Save BC
    LD    HL,SYSVAR_WRA1+$01        ;[3645] HL -> WRA1 mantissa start
RR2:
    CALL  RRSUB                     ;[3648] Do the right-rotation
    POP   BC                        ;[364B] Restore BC
    POP   HL                        ;[364C] Restore HL
    RET                             ;[364D]

;
; RRSUB: rotate 4 bytes at (HL) right by one BCD digit, inserting A at MSB.
; Uses Z80 RRD instruction which rotates a nibble between A and (HL):
;   high nibble of (HL) -> low nibble of (HL), low nibble of (HL) -> A, A -> high nibble of (HL)
; Applied to consecutive bytes this shifts BCD digits right across the mantissa.
;
RRSUB:
    LD    B,$04                     ;[364E] 4 bytes = 8 BCD digits
RR1:
    RRD                             ;[3650] Rotate right: A<->low nibble of (HL), shift nibbles
    INC   HL                        ;[3652] Next byte
    DJNZ  RR1                       ;[3653]
    RET                             ;[3655]

;
; RL10: rotate WRA1 left by one BCD digit, inserting 0 at the LSB.
; RL1A: same but with A as the digit to insert at the LSB.
;
RL10:
    XOR   A                         ;[3656] A = 0 (digit to insert at LSB)
RL1A:
    PUSH  HL                        ;[3657] Save HL
    PUSH  BC                        ;[3658] Save BC
    LD    HL,SYSVAR_WRA1+$04        ;[3659] HL -> WRA1 LSB (last byte)
    CALL  RLSUB                     ;[365C] Perform left rotation from LSB upward
    POP   BC                        ;[365F] Restore BC
    POP   HL                        ;[3660] Restore HL
    RET                             ;[3661]

;
; RLSUB: rotate 4 bytes at (HL) left by one BCD digit, inserting A at LSB.
; Uses Z80 RLD instruction: low nibble of (HL) -> high nibble of (HL),
; A -> low nibble of (HL), high nibble of (HL) -> A.
; HL is decremented after each byte (works from LSB toward MSB).
;
RLSUB:
    LD    B,$04                     ;[3662] 4 bytes = 8 BCD digits
RL1:
    RLD                             ;[3664] Rotate left: A<->high nibble, shift nibbles left

    DEC   HL                        ;[3666] Move to next more-significant byte
    DJNZ  RL1                       ;[3667] Repeat for all 4 bytes
    RET                             ;[3669]

;
; SUB: BASIC subtraction. Subtracts WRA2 from WRA1 (WRA1 = WRA1 - WRA2).
; Negates WRA2 then falls through to ADD.
;
SUB:
    CALL  NEGATE_WRA2               ;[366A] WRA2 = -WRA2

;
; ADD: BASIC addition. Computes WRA1 = WRA1 + WRA2.
; Ensures |WRA1| >= |WRA2| by swapping if needed, aligns WRA2's mantissa
; to match WRA1's exponent, then performs BCD add or subtract based on signs.
;
ADD:
    CALL  CPABS                     ;[366D] Compare magnitudes: carry if |WRA1| < |WRA2|
    CALL  NC,SWAP                   ;[3670] If |WRA1| < |WRA2|: swap so larger magnitude in WRA1
    LD    A,(SYSVAR_WRA2)           ;[3673] Load WRA2 exponent
    AND   $7F                       ;[3676] Strip sign bit
    RET   Z                         ;[3678] WRA2 is zero: WRA1 unchanged, done
    LD    C,A                       ;[3679] C = WRA2 exponent magnitude
    LD    A,(SYSVAR_WRA1)           ;[367A] Load WRA1 exponent
    RES   7,A                       ;[367D] Strip sign bit
    SUB   C                         ;[367F] A = exponent difference (WRA1_exp - WRA2_exp)
    JR    Z,AD1                     ;[3680] Same exponent: no alignment shift needed
    CP    $08                       ;[3682] Difference >= 8 digits?
    RET   NC                        ;[3684] Yes: WRA2 too small to matter, skip add
    LD    B,A                       ;[3685] B = number of right-shifts needed for WRA2
AD2:
    CALL  RRD20                     ;[3686] Shift WRA2 right by one BCD digit
    DJNZ  AD2                       ;[3689] Repeat B times
AD1:
    LD    A,(SYSVAR_WRA1)           ;[368B] Load WRA1 exponent/sign
    LD    C,A                       ;[368E] C = WRA1 exponent
    LD    A,(SYSVAR_WRA2)           ;[368F] Load WRA2 exponent/sign
    XOR   C                         ;[3692] XOR signs: bit 7 set if signs differ
    BIT   7,A                       ;[3693] Do signs differ?
    JR    Z,AD3                     ;[3695] No: same sign -> BCD addition
    CALL  SBT12                     ;[3697] Different signs -> BCD subtraction
    OR    A                         ;[369A] Clear carry
    JP    ALIGN                     ;[369B] Normalise result

AD3:
    CALL  AD12                      ;[369E] Same signs -> BCD addition
    JP    ALIGN                     ;[36A1] Normalise result (carry may be set for overflow)

;
; SBT12: BCD subtract WRA2 from WRA1 byte-by-byte (from LSB to MSB).
; Result stored back into WRA1. Uses DAA for decimal correction.
;
SBT12:
    OR    A                         ;[36A4] Clear carry flag
    LD    DE,SYSVAR_WRA1+$04        ;[36A5] DE -> WRA1 LSB
    LD    HL,SYSVAR_WRA2+$04        ;[36A8] HL -> WRA2 LSB
    LD    B,$04                     ;[36AB] 4 mantissa bytes
SBT121:
    LD    A,(DE)                    ;[36AD] Load WRA1 byte
    SBC   A,(HL)                    ;[36AE] WRA1 -= WRA2 + borrow
    DAA                             ;[36AF] BCD adjust
    LD    (DE),A                    ;[36B0] Store result
    DEC   HL                        ;[36B1] Next byte toward MSB
    DEC   DE                        ;[36B2]
    DJNZ  SBT121                    ;[36B3]
    RET                             ;[36B5]

;
; AD12: BCD add WRA2 to WRA1 byte-by-byte (from LSB to MSB).
; Result stored back into WRA1. Uses DAA for decimal correction.
;
AD12:
    OR    A                         ;[36B6] Clear carry flag
    LD    DE,SYSVAR_WRA1+$04        ;[36B7] DE -> WRA1 LSB
    LD    HL,SYSVAR_WRA2+$04        ;[36BA] HL -> WRA2 LSB
    LD    B,$04                     ;[36BD] 4 mantissa bytes
AD121:
    LD    A,(DE)                    ;[36BF] Load WRA1 byte
    ADC   A,(HL)                    ;[36C0] WRA1 += WRA2 + carry
    DAA                             ;[36C1] BCD adjust
    LD    (DE),A                    ;[36C2] Store result
    DEC   HL                        ;[36C3] Next byte toward MSB
    DEC   DE                        ;[36C4]
    DJNZ  AD121                     ;[36C5]
    RET                             ;[36C7]

;
; _MULT: BCD floating-point multiplication. WRA1 = WRA1 * WRA2.
; Computes the result exponent by adding the two exponents (bias-adjusted),
; determines the result sign, then performs long BCD multiplication into WRA3.
;
_MULT:
    LD    A,(SYSVAR_WRA1)           ;[36C8] Load WRA1 exponent
    CP    $80                       ;[36CB] Is WRA1 zero?
    JR    Z,MTZ                     ;[36CD] Yes: result is zero
    AND   $7F                       ;[36CF] Strip sign bit
    LD    C,A                       ;[36D1] C = WRA1 exponent magnitude
    LD    HL,SYSVAR_WRA2            ;[36D2] HL -> WRA2
    LD    A,(HL)                    ;[36D5] Load WRA2 exponent
    CP    $80                       ;[36D6] Is WRA2 zero?
    JR    Z,MTZ                     ;[36D8] Yes: result is zero
    AND   $7F                       ;[36DA] Strip sign bit
    ADD   A,C                       ;[36DC] Add exponents
    SUB   $3F                       ;[36DD] Remove bias (each exponent has $40 bias; combined is $7F but $40 base needs -$3F)
    JR    Z,MTZ                     ;[36DF] Result exponent = 0: underflow to zero
    BIT   7,A                       ;[36E1] Bit 7 set = overflow or underflow wrap
    JR    Z,MT1                     ;[36E3] No overflow: proceed
    CP    $C0                       ;[36E5] Is it above $C0 (overflow rather than underflow)?
    CALL  C,ERR_OVERFLOW            ;[36E7] Overflow error
MTZ:
    JP    LZERO                     ;[36EA] Underflow: result = 0
MT1:
    LD    C,A                       ;[36ED] C = result exponent magnitude
    LD    A,(SYSVAR_WRA1)           ;[36EE] WRA1 exponent (with sign)
    XOR   (HL)                      ;[36F1] XOR with WRA2 exponent: bit 7 = XOR of signs
    CPL                             ;[36F2] Complement: 1 in bit 7 if signs were same (result positive)
    AND   $80                       ;[36F3] Keep only sign bit
    ADD   A,C                       ;[36F5] Combine sign with exponent
    LD    (SYSVAR_WRA3),A           ;[36F6] Store result exponent in WRA3
    CALL  ONEDIGIT                  ;[36F9] Test if WRA1 has only one significant digit
    JP    Z,MLONE                   ;[36FC] Yes: use fast single-digit multiply path
    LD    HL,$62D5                  ;[36FF] HL -> WRA3+1 (result mantissa area, WRA3 at $62D4)
    LD    B,$0C                     ;[3702] 12 bytes to zero (WRA3 mantissa + working area)
    CALL  ZW1                       ;[3704] Zero result accumulation area
MLT7:
    LD    DE,SYSVAR_WRA2+$04        ;[3707] DE -> WRA2 LSB
    LD    HL,$62DC                  ;[370A] HL -> inner working area
    LD    B,$04                     ;[370D] 4 bytes of WRA2 mantissa
MLT6:
    PUSH  BC                        ;[370F] Save outer loop count
    LD    A,(DE)                    ;[3710] A = current WRA2 byte (2 BCD digits)
    PUSH  DE                        ;[3711] Save DE
    LD    E,A                       ;[3712] E = WRA2 byte
    PUSH  HL                        ;[3713] Save HL
    CALL  MLTW4E                    ;[3714] Multiply WRA1 mantissa by E, result in working area
    POP   HL                        ;[3717] Restore HL
    CALL  C,ADW3W4                  ;[3718] If carry, add partial product into WRA3 accumulator
    DEC   HL                        ;[371B] Step HL one byte toward MSB
    POP   DE                        ;[371C] Restore DE
    DEC   DE                        ;[371D] Step DE one byte toward MSB (next WRA2 byte)
    POP   BC                        ;[371E] Restore outer loop count
    DJNZ  MLT6                      ;[371F] Repeat for all 4 WRA2 bytes
    LD    A,(SYSVAR_WRA3+1)         ;[3721] Check most-significant WRA3 mantissa byte
    CP    $10                       ;[3724] Is the leading BCD digit non-zero (>= $10)?
    JR    NC,MT5                    ;[3726] Yes: properly normalised, copy to WRA1
    LD    HL,SYSVAR_WRA3+5          ;[3728] HL -> WRA3+5 (working area)
    LD    B,5                       ;[372B] 5 bytes to rotate
    CALL  RL1                       ;[372D] Rotate left one BCD digit to normalise
    LD    A,(HL)                    ;[3730] Load the exponent byte that RL1 moved
    DEC   A                         ;[3731] Decrement exponent (shifted mantissa left by 1)
    LD    (HL),A                    ;[3732] Store
    AND   $7F                       ;[3733] Strip sign to check for zero exponent
    JR    Z,MTZ                     ;[3735] Exponent = 0: underflow, result = 0
MT5:
    LD    HL,SYSVAR_WRA3            ;[3737] HL -> WRA3 (normalised result)
    JP    LNUM1                     ;[373A] Copy WRA3 to WRA1 and return

;
; ETOBIN: convert a packed BCD byte in E to binary (0-99 -> 0-99 as binary).
; High nibble * 10 + low nibble.
;
ETOBIN:
    LD    A,E                       ;[373D] A = packed BCD byte
    AND   $F0                       ;[373E] Isolate high nibble
    RRCA                            ;[3740] Shift right 1 (/ 2)
    LD    B,A                       ;[3741] Save
    RRCA                            ;[3742] Shift right 1 more (/ 4 total)
    RRCA                            ;[3743] Shift right 1 more (/ 8 total)
    ADD   A,B                       ;[3744] A = high_nibble/8 + high_nibble/2 = high_nibble * (5/8) ??? 
    LD    B,A                       ;[3745] Save tens * 10 in binary
    LD    A,E                       ;[3746] Reload BCD byte
    AND   $0F                       ;[3747] Isolate low nibble (units)
    ADD   A,B                       ;[3749] A = tens*10 + units = binary value
    LD    E,A                       ;[374A] Store result back in E
    RET                             ;[374B]

;
; MLTAE: multiply A by E (both BCD byte pairs = 2 BCD digits each).
; Uses binary shift-and-add with BCD correction (DAA after each step).
; Result is a 2-byte BCD product in HL (H=high byte, L=low byte).
;
MLTAE:
    LD    HL,0                      ;[374C] HL = 0 (accumulator)
    LD    B,H                       ;[374F] B = 0 (high byte of multiplicand working)
    LD    C,A                       ;[3750] C = A (multiplicand low byte)
MLTAE2:
    SRL   E                         ;[3751] Shift multiplier right; bit 0 -> carry
    JR    NZ,MLTAE3                 ;[3753] E non-zero: still more bits
    RET   NC                        ;[3755] E was 0 and last bit was 0: done (result in HL)
MLTAE3:
    JR    NC,MLTAE1                 ;[3756] Current bit is 0: skip add
    LD    A,C                       ;[3758] Add BC (current shifted value) to HL
    ADD   A,L                       ;[3759] L += C (BCD)
    DAA                             ;[375A] BCD adjust
    LD    L,A                       ;[375B]
    LD    A,B                       ;[375C]
    ADC   A,H                       ;[375D] H += B + carry
    DAA                             ;[375E] BCD adjust
    LD    H,A                       ;[375F]
MLTAE1:
    LD    A,C                       ;[3760] Double BC (shift multiplicand left)
    ADD   A,C                       ;[3761] C *= 2 (BCD)
    DAA                             ;[3762]
    LD    C,A                       ;[3763]
    LD    A,B                       ;[3764]
    ADC   A,B                       ;[3765] B *= 2 + carry
    DAA                             ;[3766]
    LD    B,A                       ;[3767]
    JR    MLTAE2                    ;[3768] Next bit

;
; MLTW4E: multiply the WRA1 mantissa (4 bytes) by E (a BCD byte pair).
; Result is placed in a working area (WRA4) pointed to by IX.
; Returns carry set if result is non-zero.
;
MLTW4E:
    CALL  ETOBIN                    ;[376A] Convert E from packed BCD to binary
    RET   Z                         ;[376D] If E is 0, result is 0 (no carry)
    PUSH  IX                        ;[376E] Save IX
    LD    IX,$62D3                  ;[3770] IX -> end of WRA4 working area
    LD    (IX+$00),$00              ;[3774] Zero last byte of WRA4
    LD    HL,SYSVAR_WRA1+$04        ;[3778] HL -> WRA1 LSB
    LD    B,$04                     ;[377B] 4 mantissa bytes to process
MW4E1:
    PUSH  BC                        ;[377D] Save byte count
    PUSH  HL                        ;[377E] Save WRA1 pointer
    LD    A,(HL)                    ;[377F] A = current WRA1 mantissa byte
    PUSH  DE                        ;[3780] Save E
    CALL  MLTAE                     ;[3781] HL = A * E (BCD 4-digit result)
    LD    A,(IX+$00)                ;[3784] Load current WRA4 byte
    ADD   A,L                       ;[3787] Add low product byte
    DAA                             ;[3788] BCD adjust
    LD    (IX+$00),A                ;[3789] Store back
    LD    A,$00                     ;[378C] A = 0 (for carry propagation)
    ADC   A,H                       ;[378E] Add high product byte + carry
    DAA                             ;[378F] BCD adjust
    LD    (IX-$01),A                ;[3790] Store one byte further up
    DEC   IX                        ;[3793] Step IX toward MSB
    POP   DE                        ;[3795] Restore E
    POP   HL                        ;[3796] Restore WRA1 pointer
    DEC   HL                        ;[3797] Step to next WRA1 byte (toward MSB)
    POP   BC                        ;[3798] Restore byte count
    DJNZ  MW4E1                     ;[3799] Repeat for all 4 bytes
    POP   IX                        ;[379B] Restore IX
    SCF                             ;[379D] Set carry = result is non-zero
    RET                             ;[379E]

;
; ADW3W4: add the WRA4 partial product (at $62D3..fixed) into WRA3 accumulator.
; HL on entry points to the current position in WRA3 to add into.
;
ADW3W4:
    PUSH  HL                        ;[379F] Save HL
    LD    B,$05                     ;[37A0] 5 bytes to add
    LD    DE,$62D3                  ;[37A2] DE -> WRA4 LSB
    OR    A                         ;[37A5] Clear carry
ADWW1:
    LD    A,(DE)                    ;[37A6] Load WRA4 byte
    ADC   A,(HL)                    ;[37A7] Add WRA3 byte + carry
    DAA                             ;[37A8] BCD adjust
    LD    (HL),A                    ;[37A9] Store back into WRA3
    DEC   HL                        ;[37AA] Next byte toward MSB
    DEC   DE                        ;[37AB]
    DJNZ  ADWW1                     ;[37AC]
    POP   HL                        ;[37AE] Restore HL
    RET                             ;[37AF]

;
; DIV: BCD floating-point division. WRA1 = WRA1 / WRA2.
; Checks for divide by zero, computes result exponent (WRA1_exp - WRA2_exp + $40),
; determines result sign, then performs long BCD division (8 result digits).
;
DIV:
    LD    HL,SYSVAR_WRA2            ;[37B0] HL -> WRA2
    LD    A,(HL)                    ;[37B3] Load WRA2 exponent
    CP    $80                       ;[37B4] Is WRA2 zero?
    CALL  Z,ERR_DIVIDE_BY_Z         ;[37B6] Yes: divide by zero error
    AND   $7F                       ;[37B9] Strip sign bit
    LD    C,A                       ;[37BB] C = WRA2 exponent magnitude
    LD    A,(SYSVAR_WRA1)           ;[37BC] Load WRA1 exponent
    CP    $80                       ;[37BF] Is WRA1 zero?
    RET   Z                         ;[37C1] Yes: 0 / anything = 0
    AND   $7F                       ;[37C2] Strip sign bit
    SUB   C                         ;[37C4] A = WRA1_exp - WRA2_exp
    ADD   A,$40                     ;[37C5] Re-bias to $40 base
    JR    Z,DVZ                     ;[37C7] Result exponent = 0: return zero
    BIT   7,A                       ;[37C9] Overflow or underflow?
    JR    Z,DV1                     ;[37CB] No: proceed
    CP    $C0                       ;[37CD] Above $C0 = overflow?
    CALL  C,ERR_OVERFLOW            ;[37CF] Overflow error
DVZ:
    JP    LZERO                     ;[37D2] Underflow: return 0

DV1:
    LD    C,A                       ;[37D5] C = result exponent
    LD    A,(SYSVAR_WRA1)           ;[37D6] Load WRA1 exponent (with sign)
    XOR   (HL)                      ;[37D9] XOR with WRA2 exponent: bit 7 = sign XOR
    CPL                             ;[37DA] Complement
    AND   $80                       ;[37DB] Keep only sign bit
    ADD   A,C                       ;[37DD] Combine with exponent
    LD    (SYSVAR_WRA1),A           ;[37DE] Store result exponent into WRA1
    CALL  ONEDIGIT                  ;[37E1] Is WRA2 a single BCD digit?
    JP    Z,DVONE                   ;[37E4] Yes: use fast single-digit divide path
    LD    HL,SYSVAR_WRA3+1          ;[37E7] HL -> WRA3+1 (zero result area and WRAe)
    LD    B,12                      ;[37EA] 12 bytes to zero
    CALL  ZW1                       ;[37EC] Zero WRA3 and WRAe working areas
    LD    DE,SYSVAR_WRA2+$01        ;[37EF] DE -> WRA2 mantissa
    LD    HL,SYSVAR_WRAE            ;[37F2] HL -> WRAe (extended dividend register)
    LD    B,4                       ;[37F5] 4 bytes
    CALL  SWAP1                     ;[37F7] Copy WRA2 mantissa into WRAe
    LD    DE,SYSVAR_WRA3+1          ;[37FA] DE -> WRA3+1 (dividend accumulator)
    LD    HL,SYSVAR_WRA1+1          ;[37FD] HL -> WRA1 mantissa
    LD    BC,4                      ;[3800] 4 bytes
    LDIR                            ;[3803] Copy WRA1 mantissa into WRA3+1
    LD    B,8                       ;[3805] B = 8 result digits to compute
DV3:
    PUSH  BC                        ;[3807] Save digit count
    LD    C,$00                     ;[3808] C = current quotient digit
DV4:
    CALL  COMPARE                   ;[380A] Is WRA3+1 >= WRAe (divisor)?
    JR    C,DV5                     ;[380D] No: digit is done (WRA3+1 < WRAe)
    LD    HL,SYSVAR_WRAE+7          ;[380F] HL -> WRAe LSB end
    LD    DE,SYSVAR_WRA3+8          ;[3812] DE -> WRA3+1 LSB end
    LD    B,8                       ;[3815] 8 bytes
    CALL  SBT121                    ;[3817] WRA3+1 -= WRAe (subtract divisor)
    INC   C                         ;[381A] Increment quotient digit
    JR    DV4                       ;[381B] Try again (count how many times divisor fits)
DV5:
    LD    A,C                       ;[381D] A = quotient digit (0-9)
    CALL  RL1A                      ;[381E] Rotate digit into WRA1 result mantissa
    LD    HL,SYSVAR_WRAE            ;[3821] HL -> WRAe
    LD    B,$08                     ;[3824] 8 bytes
    XOR   A                         ;[3826] A = 0 (insert 0 at MSB)
    CALL  RR1                       ;[3827] Shift WRAe right one BCD digit (×10 for next digit)
    POP   BC                        ;[382A] Restore digit count
    DJNZ  DV3                       ;[382B] Next digit (8 total)
    LD    A,(SYSVAR_WRA1+$01)       ;[382D] Check leading mantissa byte
    CP    $10                       ;[3830] Leading digit non-zero (>= $10)?
    RET   NC                        ;[3832] Yes: result normalised, done
    LD    A,(SYSVAR_WRA1)           ;[3833] Load result exponent
    DEC   A                         ;[3836] Decrement exponent (result needs left shift)
    JR    Z,DVZ                     ;[3837] Exponent wrapped to 0: underflow
    CP    $80                       ;[3839] Wrapped to zero sentinel?
    JR    Z,DVZ                     ;[383B] Yes: zero
    LD    (SYSVAR_WRA1),A           ;[383D] Store decremented exponent
    LD    B,$01                     ;[3840] One more digit to compute
    JR    DV3                       ;[3842] Get the extra digit

;
; COMPARE: compare WRA3+1 with WRAe (used by division loop).
; Returns carry set if WRA3+1 < WRAe.
;
COMPARE:
    LD    DE,SYSVAR_WRA3+1          ;[3844] DE -> WRA3+1
    LD    HL,SYSVAR_WRAE            ;[3847] HL -> WRAe (divisor)
    LD    B,8                       ;[384A] 8 bytes to compare
    JP    CMP1                      ;[384C] Byte-by-byte compare (carry if DE < HL)

;
; DVONE: fast path for division when WRA2 has only one significant BCD digit.
; Extracts the single digit from WRA2, then divides WRA1 mantissa byte-by-byte.
;
DVONE:
    LD    A,(SYSVAR_WRA2+$01)       ;[384F] Load WRA2 first mantissa byte
    RRCA                            ;[3852] Shift high nibble to low
    RRCA                            ;[3853]
    RRCA                            ;[3854]
    RRCA                            ;[3855]
    AND   $0F                       ;[3856] Isolate high nibble = single digit divisor
    LD    C,A                       ;[3858] C = divisor digit
    XOR   A                         ;[3859] A = 0 (initial remainder)
    LD    E,A                       ;[385A] E = 0
    LD    B,$04                     ;[385B] 4 mantissa bytes
    LD    HL,SYSVAR_WRA1+$01        ;[385D] HL -> WRA1 mantissa start
DVONE1:
    PUSH  BC                        ;[3860] Save byte count
    RLD                             ;[3861] Rotate high nibble of (HL) through A: get high digit pair
    CALL  DVSUB                     ;[3863] Divide: A = quotient digit, E = remainder
    RLD                             ;[3866] Rotate next nibble through A: get low digit pair
    CALL  DVSUB                     ;[3868] Divide next digit
    RLD                             ;[386B] Restore (HL) byte (RLD leaves nibbles rotated once)
    POP   BC                        ;[386D] Restore byte count
    INC   HL                        ;[386E] Advance to next mantissa byte
    DJNZ  DVONE1                    ;[386F] Repeat for all 4 bytes
    OR    A                         ;[3871] Clear carry
    JP    ALIGN                     ;[3872] Normalise result

;
; DVSUB: single-digit BCD division helper.
; Computes: quotient_digit = (E*10 + A) / C, remainder in E.
; On entry: A = current nibble (digit), E = previous remainder, C = divisor (1-9).
; On exit: A = quotient digit (0-9), E = new remainder.
;
DVSUB:
    PUSH  BC                        ;[3875] Save BC
    PUSH  AF                        ;[3876] Save A (current digit nibble)
    LD    A,E                       ;[3877] A = previous remainder
    RLCA                            ;[3878] A <<= 1 (×2)
    RLCA                            ;[3879] A <<= 1 (×4)
    ADD   A,E                       ;[387A] A = E*4 + E = E*5
    RLCA                            ;[387B] A <<= 1 = E*10
    POP   BC                        ;[387C] Restore (B = old A nibble, C corrupted)
    ADD   A,B                       ;[387D] A = E*10 + current nibble
    POP   BC                        ;[387E] Restore original BC
    LD    B,$FF                     ;[387F] B = -1 (will count up from -1)
DVSUB1:
    INC   B                         ;[3881] B++ (quotient digit counter)
    SUB   C                         ;[3882] A -= divisor
    JR    NC,DVSUB1                 ;[3883] While A >= 0: keep subtracting
    ADD   A,C                       ;[3885] Restore: A += C (get back valid remainder)
    LD    E,A                       ;[3886] E = remainder
    LD    A,B                       ;[3887] A = quotient digit (0-9)
    RET                             ;[3888]

;
; FPINT1: fast path for FPINT when WRA1 exponent is exactly $C0 (value 1.x).
; Extracts the leading BCD digit pair and returns the integer part (0-9) in HL.
;
FPINT1:
    LD    A,(SYSVAR_WRA1+$01)       ;[3889] Load first mantissa byte
    RRCA                            ;[388C] Shift high nibble to low position
    RRCA                            ;[388D]
    RRCA                            ;[388E]
    RRCA                            ;[388F]
    AND   $0F                       ;[3890] Isolate high nibble (leading BCD digit)
    LD    L,A                       ;[3892] L = digit value (0-9)
    LD    H,$00                     ;[3893] H = 0
    RET                             ;[3895] HL = integer part (0-9)

;
; ONEDIGIT: test whether WRA2 has only a single non-zero BCD digit.
; Used by MULT and DIV to choose the fast single-digit path.
; Returns Z if WRA2 has exactly one digit (bytes 2-4 of mantissa are all zero
; and the low nibble of byte 1 is zero).
;
ONEDIGIT:
    LD    A,(SYSVAR_WRA2+1)         ;[3896] Load first mantissa byte
    AND   $0F                       ;[3899] Is low nibble zero (only one digit in this byte)?
    RET   NZ                        ;[389B] No: not a single digit
    LD    A,(SYSVAR_WRA2+2)         ;[389C] Load second mantissa byte
    OR    A                         ;[389F] Is it zero?
    RET   NZ                        ;[38A0] No: not a single digit
    LD    A,(SYSVAR_WRA2+3)         ;[38A1] Load third mantissa byte
    OR    A                         ;[38A4] Is it zero?
    RET   NZ                        ;[38A5] No: not a single digit
    LD    A,(SYSVAR_WRA2+4)         ;[38A6] Load fourth mantissa byte
    OR    A                         ;[38A9] Is it zero? Z set if all remaining bytes zero
    RET                             ;[38AA] Z = single digit (fast path applicable)

;
; MLONE: fast-path multiply when WRA2 has a single BCD digit.
; Extracts the single digit from WRA2, then multiplies each byte of WRA1
; by that digit using repeated BCD addition.
;
MLONE:
    LD    A,(SYSVAR_WRA3)           ;[38AB] Load pre-computed result exponent from WRA3
    LD    (SYSVAR_WRA1),A           ;[38AE] Set WRA1 exponent (sign+magnitude from _MULT setup)
    LD    A,(SYSVAR_WRA2+$01)       ;[38B1] Load WRA2 first mantissa byte
    AND   $F0                       ;[38B4] Isolate high nibble (the single digit)
    RRCA                            ;[38B6] Shift high nibble to low nibble position
    RRCA                            ;[38B7]
    RRCA                            ;[38B8]
    RRCA                            ;[38B9] A = single BCD digit (1-9)
    LD    HL,SYSVAR_WRA1+$04        ;[38BA] HL -> WRA1 LSB
    LD    B,$04                     ;[38BD] 4 mantissa bytes to process
    LD    D,$00                     ;[38BF] D = carry accumulator
MLONE3:
    PUSH  BC                        ;[38C1] Save byte count
    PUSH  AF                        ;[38C2] Save digit
    LD    B,A                       ;[38C3] B = digit (loop counter for repeated add)
    LD    E,$00                     ;[38C4] E = overflow counter
    XOR   A                         ;[38C6] A = 0 (result accumulator)
    LD    C,(HL)                    ;[38C7] C = current WRA1 mantissa byte
MLONE2:
    ADD   A,C                       ;[38C8] A += C (repeated addition = multiplication)
    DAA                             ;[38C9] BCD adjust
    JR    NC,MLONE1                 ;[38CA] No BCD overflow
    INC   E                         ;[38CC] E counts BCD overflows (carry-outs)
MLONE1:
    DJNZ  MLONE2                    ;[38CD] Repeat digit times (A = C * digit, BCD)
    ADD   A,D                       ;[38CF] Add carry from previous byte
    DAA                             ;[38D0] BCD adjust
    CALL  SUB_MULTIPLY1             ;[38D1] Handle final carry propagation (patched in Mark II ROM - see PAT41)
    POP   AF                        ;[38D4] Restore digit
    POP   BC                        ;[38D5] Restore byte count
    DJNZ  MLONE3                    ;[38D6] Process next byte
    INC   E                         ;[38D8] E++ then DEC to set flags without changing E
    DEC   E                         ;[38D9]
    LD    A,E                       ;[38DA] A = final overflow count
    JP    NZ,RRD1A                  ;[38DB] Non-zero: rotate WRA1 right to normalise
MLONE4:
    LD    HL,SYSVAR_WRA1            ;[38DE] HL -> WRA1 exponent
    LD    A,(HL)                    ;[38E1] Load exponent
    OR    A                         ;[38E2] Test for zero exponent
    JP    Z,LZERO                   ;[38E3] Exponent zero: result is zero
    DEC   (HL)                      ;[38E6] Decrement exponent (adjust for leading-digit normalisation)
    RET                             ;[38E7]

;
; 'J' Monitor Command: exit the monitor back to the BASIC command line.
; Restores the stack pointer from SYSVAR_STACK and jumps to the BASIC prompt.
;
JUMP_TO_CMDLINE:
    LD    SP,(SYSVAR_STACK)         ;[38E8] Restore BASIC stack pointer
    JP    SUB_JUMP_TO_CMDLINE       ;[38EC] Jump to BASIC ready prompt

;
; Error message strings.
; Each string is null-terminated and corresponds to a BASIC error condition.
;
ERRS:    DB    0                                ;[38EF] (padding/sentinel)
OMMSG:   DB    "Out of Memory",0                ;[38F0] Error 1
WRMSG:   DB    "Wrong Mode",0                   ;[38FE] Error 2
STRMSG:  DB    "String error",0                 ;[3909] Error 3
PRNMSG:  DB    "Missing bracket",0              ;[3916] Error 4
D0MSG:   DB    "Divide by zero error",0         ;[3926] Error 5
OVMSG:   DB    "Overflow error",0               ;[393B] Error 6
SNMSG:   DB    "Syntax error",0                 ;[394A] Error 7
MOPMSG:  DB    "Something missing",0            ;[3957] Error 8
ARGMSG:  DB    "Function argument error",0      ;[3969] Error 9
NIERR:   DB    "NOT YET IMPLEMENTED",0          ;[3981] Error 10
RAMSG:   DB    "Redimensioned array",0          ;[3995] Error 11
ULMSG:   DB    "Line, LABEL or PROC not found",0 ;[39A9] Error 12
NRMSG:   DB    "Number out of range",0          ;[39C7] Error 13
SRMSG:   DB    "Subscript out of range",0       ;[39DB] Error 14
TMMSG:   DB    "Type mismatch",0                ;[39F2] Error 15
TLMSG:   DB    "Line too long",0                ;[3A00] Error 16
CCMSG:   DB    "Cannot continue",0              ;[3A0E] Error 17
ODMSG:   DB    "Out of Data",0                  ;[3A1E] Error 18
RGMSG:   DB    "RETURN without GOSUB",0         ;[3A2A] Error 19
NFMSG:   DB    "NEXT without FOR",0             ;[3A3F] Error 20
UVMSG:   DB    "Undefined variable",0           ;[3A50] Error 21
URMSG:   DB    "UNTIL without REPEAT",0         ;[3A63] Error 22
WWMSG:   DB    "WEND without WHILE",0           ;[3A78] Error 23
WDMSG:   DB    "WHILE without WEND",0           ;[3A8B] Error 24
SMMSG:   DB    "Return stack full",0            ;[3A9E] Error 25
RUMSG:   DB    "REPEAT without UNTIL",0         ;[3AB0] Error 26
GRMSG:   DB    "GOSUB without RETURN",0         ;[3AC5] Error 27
EPMSG:   DB    "ENDPROC without PROC",0         ;[3ADA] Error 28
BTMS:    DB    $0D,"Bad Tape",0                 ;[3AEF] Error 29 (tape load error)

;
; Error entry points.
; Each label is a chain of DB $AF, $3C bytes (Z80: XOR A; INC A) followed by
; the number of additional increments. Falling into a later label increments A
; more times before reaching the common DISP_ERROR_A handler.
; The combined effect sets A = error number, which is used to look up ERRS table.
; Each DB $AF increments A by 1 ($AF = XOR A resets, then $3C = INC A adds 1).
; Actually: $AF = XOR A (A=0), $3C = INC A (A=1), then subsequent $3C each add 1.
;
ERR_BAD_TAPE:           DB    $AF,$3C,6       ;[3AF9] A = 29 (bad tape)
ERR_ENDPROC_NO_PROC:    DB    $AF,$3C,6       ;[3AFC] A = 28
ERR_GOSUB_NO_RETURN:    DB    $AF,$3C,6       ;[3AFF] A = 27
ERR_REPEAT_NO_UNTIL:    DB    $AF,$3C,6       ;[3B02] A = 26
ERR_RETURN_STACK_FULL:  DB    $AF,$3C,6       ;[3B05] A = 25
ERR_WHILE_NO_WEND:      DB    $AF,$3C,6       ;[3B08] A = 24
ERR_WEND_NO_WHILE:      DB    $AF,$3C,6       ;[3B0B] A = 23
ERR_UNTIL_NO_REPEAT:    DB    $AF,$3C,6       ;[3B0E] A = 22
ERR_UNDEFINED_VAR:      DB    $AF,$3C,6       ;[3B11] A = 21
ERR_NEXT_NO_FOR:        DB    $AF,$3C,6       ;[3B14] A = 20
ERR_RETURN_NO_GOSUB:    DB    $AF,$3C,6       ;[3B17] A = 19
ERR_OUT_OF_DATA:        DB    $AF,$3C,6       ;[3B1A] A = 18
ERR_CANNOT_CONT:        DB    $AF,$3C,6       ;[3B1D] A = 17
ERR_LINE_TOO_LONG:      DB    $AF,$3C,6       ;[3B20] A = 16
ERR_TYPE_MISMATCH:      DB    $AF,$3C,6       ;[3B23] A = 15

ERR_SUBS_OUT_RANGE:     DB    $AF,$3C,6       ;[3B26] A = 14 (subscript out of range)
ERR_NUM_OUT_RANGE:      DB    $AF,$3C,6       ;[3B29] A = 13 (number out of range)
ERR_NOT_FOUND:          DB    $AF,$3C,6       ;[3B2C] A = 12 (line/label not found)
ERR_REDIM_ARRAY:        DB    $AF,$3C,6       ;[3B2F] A = 11 (redimensioned array)
ERR_NOT_YET_IMP:        DB    $AF,$3C,6       ;[3B32] A = 10 (not yet implemented)
ERR_FUNCT_ARG:          DB    $AF,$3C,6       ;[3B35] A = 9  (function argument error)
ERR_SOMETHG_MISSG:      DB    $AF,$3C,6       ;[3B38] A = 8  (something missing)
ERR_SYNTAX:             DB    $AF,$3C,6       ;[3B3B] A = 7  (syntax error)
ERR_OVERFLOW:           DB    $AF,$3C,6       ;[3B3E] A = 6  (overflow)
ERR_DIVIDE_BY_Z:        DB    $AF,$3C,6       ;[3B41] A = 5  (divide by zero)
ERR_MISSING_BRACKET:    DB    $AF,$3C,6       ;[3B44] A = 4  (missing bracket)
ERR_STRING:             DB    $AF,$3C,6       ;[3B47] A = 3  (string error)
ERR_WRONG_MODE:         DB    $AF,$3C,6       ;[3B4A] A = 2  (wrong mode)
ERR_OUT_OF_MEM:         DB    $AF,$3C         ;[3B4D] A = 1  (out of memory; only 2 bytes)

;
; DISP_ERROR_A: display error message number A by scanning the message table.
; Calls SYSVAR_ERRAM hook (unused RAM vector, normally NOP/RET).
; Scans SYSVAR_ERRTBL for the C-th null-terminated string, then displays it.
;
DISP_ERROR_A:
    CALL  SYSVAR_ERRAM              ;[3B4F] Call user-definable error handler hook
    LD    HL,(SYSVAR_ERRTBL)        ;[3B52] HL -> error message table (normally ERRS = $38EF)
    LD    C,A                       ;[3B55] C = error number (1-based)
ERROR_PRINT:
    LD    A,(HL)                    ;[3B56] Read byte from message table
    INC   HL                        ;[3B57] Advance pointer
    OR    A                         ;[3B58] Is it null terminator?
    JR    NZ,ERROR_PRINT            ;[3B59] No: keep scanning this string
    DEC   C                         ;[3B5B] Decrement string count
    JR    NZ,ERROR_PRINT            ;[3B5C] Not yet at target string: scan next
    CALL  PLINE                     ;[3B5E] Found: display the string via PLINE
    JP    ERR_RECOVERY              ;[3B61] Jump to error recovery (back to BASIC prompt)

;
; EMON: enter the monitor from a MON command in BASIC.
; Saves the return address as the trapped PC (one byte before the call instruction),
; discards the call return address from the stack, then falls into TRAP1.
;
EMON:
    EX    (SP),HL                   ;[3B64] HL = return address (the instruction after the call)
    DEC   HL                        ;[3B65] HL = address of the call instruction itself
    LD    (TRAPPC),HL               ;[3B66] Save as the trapped PC
    EX    (SP),HL                   ;[3B69] Restore return address to stack
    INC   SP                        ;[3B6A] Discard high byte of return address
    INC   SP                        ;[3B6B] Discard low byte of return address (popped SP twice)

;
; TRAP1: NMI / breakpoint entry point.
; Saves the complete Z80 register context into the TRAP register save area,
; then falls through to MONENT.
;
TRAP1:
    LD    (TRAPSP),SP               ;[3B6C] Save current SP (before we change it)
    LD    SP,TRAPSP                 ;[3B70] Set SP -> TRAPSP so pushes save into trap area
    PUSH  IY                        ;[3B73] Save IY
    PUSH  IX                        ;[3B75] Save IX
    EXX                             ;[3B77] Switch to alternate register set
    EX    AF,AF'                    ;[3B78] Switch to alternate AF
    PUSH  BC                        ;[3B79] Save BC'
    PUSH  DE                        ;[3B7A] Save DE'
    PUSH  HL                        ;[3B7B] Save HL'
    PUSH  AF                        ;[3B7C] Save AF'
    EXX                             ;[3B7D] Switch back to main registers
    EX    AF,AF'                    ;[3B7E] Switch back to main AF
    PUSH  BC                        ;[3B7F] Save BC
    PUSH  DE                        ;[3B80] Save DE
    PUSH  HL                        ;[3B81] Save HL
    PUSH  AF                        ;[3B82] Save AF

;
; MONENT: main monitor entry point after register save.
; Saves the current monitor SP, writes a JP opcode for the G command,
; displays registers and the monitor prompt, then dispatches commands.
;
MONENT:
    LD    (MONSP),SP                ;[3B83] Save monitor stack pointer for MONERR reset
    LD    A,$C3                     ;[3B87] A = JP opcode byte
    LD    (GOPC),A                  ;[3B89] Store at GOPC (used by G command to build JP nn)
    CALL  PREG                      ;[3B8C] Display compact register summary
    LD    A,$0E                     ;[3B8F] A = cursor-right / prompt char
    RST   $08                       ;[3B91] Display the prompt character
    JR    MONBUG                    ;[3B92] Enter command input loop

;
; MONERR: display monitor error (unknown/invalid command) and re-prompt.
;
MONERR:
    LD    SP,(MONSP)                ;[3B94] Restore monitor stack (discard partial command state)
    LD    HL,MONERM                 ;[3B98] HL -> error message "????"
    CALL  PLINE                     ;[3B9B] Display error message

;
; MONBUG: main monitor command input and dispatch loop.
; Prompts with '*', reads a line, uppercases the first character,
; maps it to A-Z (0-25), looks up in MONTBL, and jumps to the handler.
;
MONBUG:
    LD    A,$2A                     ;[3B9E] A = '*' (monitor prompt character)
    RST   $08                       ;[3BA0] Display '*'
    CALL  SYSVAR_LINP               ;[3BA1] Read a line of input into INPBUF
    LD    DE,INPBUF                 ;[3BA4] DE -> start of input buffer
    LD    A,(DE)                    ;[3BA7] Read first character (the command letter)
    CALL  LUCC                      ;[3BA8] Convert lowercase to uppercase
    SUB   $41                       ;[3BAB] A -= 'A': A=0 for 'A', 25 for 'Z'
    JR    C,MONERR                  ;[3BAD] Below 'A': invalid command
    CP    $1A                       ;[3BAF] A >= 26 (beyond 'Z')?
    JR    NC,MONERR                 ;[3BB1] Yes: invalid command
    RLCA                            ;[3BB3] A *= 2 (word index into MONTBL)
    INC   DE                        ;[3BB4] DE -> rest of input (arguments after command letter)
    LD    BC,MONTBL                 ;[3BB5] BC -> monitor command table
    LD    L,A                       ;[3BB8] L = byte offset
    LD    H,$00                     ;[3BB9] H = 0
    ADD   HL,BC                     ;[3BBB] HL -> entry in MONTBL
    LD    A,(HL)                    ;[3BBC] Read low byte of handler address
    INC   HL                        ;[3BBD]
    LD    H,(HL)                    ;[3BBE] Read high byte
    LD    L,A                       ;[3BBF] HL = handler address
    LD    BC,MONBUG                 ;[3BC0] BC = return address (MONBUG loop)
    PUSH  BC                        ;[3BC3] Push return address (so handler can RET back to loop)
    RST   $10                       ;[3BC4] Skip leading spaces in input buffer
    CP    $0D                       ;[3BC5] Was rest of line empty (CR)?
    JP    (HL)                      ;[3BC7] Jump to command handler

;
; MONERM: monitor error message ("????").
;
MONERM:
    DB    "????",NEWLINE,CEL,0      ;[3BC8] Unknown command indicator + newline + clear-to-EOL

;
; MONTBL: monitor command dispatch table (2-byte addresses for commands A-Z).
;
MONTBL:
    DW    ARTHM                     ;[3BCF] A: Arithmetic (hex add/subtract)
    DW    BRKPT                     ;[3BD1] B: Breakpoint set/clear
    DW    COPY                      ;[3BD3] C: Copy memory block
    DW    DUMP                      ;[3BD5] D: Dump memory to tape
    DW    EXECUT                    ;[3BD7] E: Execute (resume at address)
    DW    FILL                      ;[3BD9] F: Fill memory block
    DW    GO                        ;[3BDB] G: Go (jump to address)
    DW    HEX                       ;[3BDD] H: Hex dump with ASCII
    DW    INTELL                    ;[3BDF] I: Intelligent copy (handles overlaps)
    DW    JUMP_TO_CMDLINE           ;[3BE1] J: Jump to BASIC command line
    DW    MONERR                    ;[3BE3] K: (unused - gives error)
    DW    LOCAT                     ;[3BE5] L: Locate (search for byte)
    DW    MODFY                     ;[3BE7] M: Modify memory interactively
    DW    MONERR                    ;[3BE9] N: (unused - gives error)
    DW    MOUT                      ;[3BEB] O: Output to I/O port
    DW    PCINC                     ;[3BED] P: PC increment (adjust trapped PC)
    DW    QUERY                     ;[3BEF] Q: Query (read from I/O port)
    DW    RTAPE                     ;[3BF1] R: Read from tape
    DW    MONCLS                    ;[3BF3] S: Screen clear
    DW    TYPE                      ;[3BF5] T: Type ASCII into memory
    DW    UPDAT                     ;[3BF7] U: Update saved register
    DW    COMPAR                    ;[3BF9] V: Verify/compare memory blocks
    DW    WORD                      ;[3BFB] W: Word search
    DW    PREG                      ;[3BFD] X: Display registers (compact)
    DW    MONERR                    ;[3BFF] Y: (unused - gives error)
    DW    REGIST                    ;[3C01] Z: Display all registers with names

;
; MONCLS: Monitor S command - clear the screen.
; Sends character $04 (clear screen control code).
;
MONCLS:
    LD    A,$04                     ;[3C03] A = clear-screen character
    JP    PUTCHAR                   ;[3C05] Display it and return

;
; BRKPT: Monitor B command - set or clear a breakpoint.
; With no address: restore original opcode at the breakpoint address.
; With address: save the opcode there, replace it with RST $30 (breakpoint trap).
;
BRKPT:
    JR    Z,BRKPT1                  ;[3C08] CR only: clear breakpoint (restore saved opcode)
    CALL  RDHXZ                     ;[3C0A] Read hex address from input into HL
    LD    (BRKPST+1),HL             ;[3C0D] Save breakpoint address in BRKPST+1
    LD    A,(HL)                    ;[3C10] Read opcode currently at that address

    LD    (BRKPST),A                ;[3C11] Save original opcode in BRKPST
    LD    (HL),BRKRST               ;[3C14] Overwrite with RST $30 (breakpoint instruction)
    RET                             ;[3C16]

;
; BRKPT1: clear the breakpoint (restore original opcode).
;
BRKPT1:
    LD    HL,(BRKPST+1)             ;[3C17] HL = saved breakpoint address
    LD    A,(BRKPST)                ;[3C1A] A = saved original opcode
    LD    (HL),A                    ;[3C1D] Restore original opcode at breakpoint address
    RET                             ;[3C1E]

;
; PCINC: Monitor P command - increment (adjust) the trapped PC by a hex offset.
; Reads a signed hex offset, adds it to TRAPPC, and displays updated registers.
;
PCINC:
    CALL  RDHXZ                     ;[3C1F] Read hex offset into HL
    LD    DE,(TRAPPC)               ;[3C22] DE = current trapped PC
    ADD   HL,DE                     ;[3C26] HL = TRAPPC + offset
    LD    (TRAPPC),HL               ;[3C27] Store updated PC
    JP    PREG                      ;[3C2A] Display updated registers

;
; MODFY5/MODFY6/MODFY2: modify memory subroutines.
; MODFY5: step back 2 bytes (user pressed '/').
; MODFY6: step forward 1 byte (user pressed CR).
; MODFY2: display address, current byte, get input.
;
MODFY5:
    DEC   BC                        ;[3C2D] BC -= 1
    DEC   BC                        ;[3C2E] BC -= 1 (total: back 2 to counteract the INC in MODFY6)
MODFY6:
    INC   BC                        ;[3C2F] Step BC forward by 1 byte
MODFY2:
    LD    L,C                       ;[3C30] HL = BC (current address)
    LD    H,B                       ;[3C31]
    LD    (MONST),HL                ;[3C32] Save current address in MONST (for next M command)
    PUSH  BC                        ;[3C35] Save current address
    CALL  PRINT_HEX_HL              ;[3C36] Display address as hex
    LD    A,'<'                     ;[3C39] Display '<' separator
    RST   $08                       ;[3C3B]
    LD    A,(HL)                    ;[3C3C] Read current byte at address
    CALL  PRINT_HEX_A               ;[3C3D] Display as hex
    LD    A,'>'                     ;[3C40] Display '>' separator
    RST   $08                       ;[3C42]
    CALL  DISPLAY_SPACE             ;[3C43] Display space
    CALL  SYSVAR_LINP               ;[3C46] Read user input into INPBUF
    POP   BC                        ;[3C49] Restore current address
    LD    DE,INPBUF                 ;[3C4A] DE -> input buffer
    LD    A,(DE)                    ;[3C4D] Read first character
    CP    CR                        ;[3C4E] CR alone: advance to next byte
    JR    Z,MODFY6                  ;[3C50]
    CP    '/'                       ;[3C52] '/': step back
    JR    Z,MODFY5                  ;[3C54]
    CP    '.'                       ;[3C56] '.': exit modify mode
    RET   Z                         ;[3C58]
MODFY1:
    RST   $10                       ;[3C59] Skip leading spaces
    CP    CR                        ;[3C5A] CR: advance to next byte
    JR    Z,MODFY2                  ;[3C5C]
    CALL  RDHXZ                     ;[3C5E] Read hex byte value into HL
    LD    A,L                       ;[3C61] A = byte value
    LD    (BC),A                    ;[3C62] Store at current address
    INC   BC                        ;[3C63] Advance to next byte
    JR    MODFY1                    ;[3C64] Read next byte

;
; MODFY: Monitor M command - interactive memory modify.
; With no address: continue from last M address (MONST).
; With address: start from given address.
; Prompts: XXXX<YY> ; CR=next, /=back, .=exit, hex bytes=store.
;
MODFY:
    JR    NZ,MODFY3                 ;[3C66] Argument given: read address
    LD    HL,(MONST)                ;[3C68] No argument: use saved address
    JR    MODFY4                    ;[3C6B]
MODFY3:
    CALL  RDHXZ                     ;[3C6D] Read hex address into HL
MODFY4:
    LD    C,L                       ;[3C70] BC = HL (working address in BC for byte ops)
    LD    B,H                       ;[3C71]
    JR    MODFY1                    ;[3C72] Enter modify loop

;
; HEX: Monitor H command - hex dump with ASCII.
; Dumps 16 rows of 8 bytes each. Each row: address + 8 hex bytes + 8 ASCII chars.
; With no address: continue from last H address. With address: start there.
;
HEX:
    JR    NZ,HEX5                   ;[3C74] Argument given: read address
    LD    HL,(MONST)                ;[3C76] No argument: use saved address
    JR    HEX3                      ;[3C79]
HEX5:
    CALL  RDHXZ                     ;[3C7B] Read start address into HL
HEX3:
    LD    B,$10                     ;[3C7E] B = 16 rows
HEX2:
    PUSH  BC                        ;[3C80] Save row count
    CALL  HEXSUB                    ;[3C81] Print address + 8 hex bytes (HL advances by 8)
    CALL  DISPLAY_SPACE             ;[3C84] Space between hex and ASCII
    LD    B,$08                     ;[3C87] B = 8 characters for ASCII column
HEX4:
    LD    A,(HL)                    ;[3C89] Read byte
    INC   HL                        ;[3C8A] Advance (HL now points 8 bytes back to same row)
    CALL  DSPASC                    ;[3C8B] Display as ASCII (or '.' if non-printable)
    DJNZ  HEX4                      ;[3C8E] Repeat 8 times
    LD    A,CEL                     ;[3C90] Clear to end of line
    RST   $08                       ;[3C92]
    LD    A,XCRLF                   ;[3C93] Carriage return / new line
    RST   $08                       ;[3C95]
    CALL  ESC                       ;[3C96] Check if ESC pressed (abort)
    POP   BC                        ;[3C99] Restore row count
    JR    Z,HEXXX                   ;[3C9A] ESC: abort
    DJNZ  HEX2                      ;[3C9C] Next row
    LD    (MONST),HL                ;[3C9E] Save position for next H command
HEXXX:
    LD    A,CEL                     ;[3CA1] Clear to end of line
    RST   $08                       ;[3CA3]
    RET                             ;[3CA4]

;
; HEXSUB: print address (HL) in hex followed by a space and 8 bytes of hex data.
; HL is advanced by 8 on return but the original is also left on the stack caller pops.
;
HEXSUB:
    CALL  PRINT_HEX_HL              ;[3CA5] Print HL as 4 hex digits + space
    CALL  DISPLAY_SPACE             ;[3CA8] Extra space
    LD    B,8                       ;[3CAB] B = 8 bytes to print
    PUSH  HL                        ;[3CAD] Save start address (caller uses this for ASCII pass)
HEX1:
    LD    A,(HL)                    ;[3CAE] Read byte
    INC   HL                        ;[3CAF] Advance
    CALL  MPHXA                     ;[3CB0] Print as hex + space
    DJNZ  HEX1                      ;[3CB3]
    POP   HL                        ;[3CB5] Restore start address (ASCII pass will use this)
    RET                             ;[3CB6]

;
; CRLF: output a carriage return character.
;
CRLF:
    LD    A,CR                      ;[3CB7] A = CR
    RST   $08                       ;[3CB9] Output it
    RET                             ;[3CBA]

;
; REGIST: Monitor Z command - display all registers with names.
; Iterates through REGMSG (12 x 3-char names) paired with TRAPAF..TRAPPC area.
; Outputs: "name hex_value" for each register pair, 12 lines total.
;
REGIST:
    LD    IX,REGMSG                 ;[3CBB] IX -> register name strings
    LD    DE,TRAPAF                 ;[3CBF] DE -> saved register values (AF first)
    LD    B,12                      ;[3CC2] B = 12 register pairs (AF,HL,DE,BC,AF',HL',DE',BC',IX,IY,SP,PC)
REGST1:
    PUSH  BC                        ;[3CC4] Save outer count
    LD    B,3                       ;[3CC5] Print 3-char register name
REGST2:
    LD    A,(IX+$00)                ;[3CC7] Read name character
    RST   $08                       ;[3CCA] Display it
    INC   IX                        ;[3CCB] Next char
    DJNZ  REGST2                    ;[3CCD] Repeat 3 times
    CALL  DISPLAY_SPACE             ;[3CCF] Space between name and value
    LD    A,(DE)                    ;[3CD2] Read saved register low byte
    LD    L,A                       ;[3CD3] L = low byte
    INC   DE                        ;[3CD4]
    LD    A,(DE)                    ;[3CD5] Read saved register high byte
    LD    H,A                       ;[3CD6] H = high byte
    INC   DE                        ;[3CD7]
    CALL  HEXSUB                    ;[3CD8] Print HL as 4 hex digits + 8 bytes (reuses HEXSUB)
    LD    A,CEL                     ;[3CDB] Clear to end of line
    RST   $08                       ;[3CDD]
    LD    A,XCRLF                   ;[3CDE] Carriage return
    RST   $08                       ;[3CE0]
    POP   BC                        ;[3CE1] Restore count
    DJNZ  REGST1                    ;[3CE2] Next register
    LD    A,CEL                     ;[3CE4] Final clear-to-EOL
    RST   $08                       ;[3CE6]
    RET                             ;[3CE7]

;
; REGMSG: 3-character register name strings (12 names, each exactly 3 chars, no null).
;
REGMSG:
    DB    "AF HL DE BC "            ;[3CE8] Main registers
    DB    "AF'HL'DE'BC'"            ;[3CF4] Alternate registers
    DB    "IX IY SP PC "            ;[3D00] Index/special registers

;
; PRINT_HEX_HL: print HL as 4 hex digits followed by a space.
; MPHXA: print A as 2 hex digits followed by a space.
;
PRINT_HEX_HL:
    CALL  PHEXHL                    ;[3D0C] Print HL as 4 hex digits
MPHL1:
    JP    DISPLAY_SPACE             ;[3D0F] Print space and return

MPHXA:
    CALL  PRINT_HEX_A               ;[3D12] Print A as 2 hex digits
    JR    MPHL1                     ;[3D15] Print space and return

;
; RDHXZ: read a hex value and require end-of-input (CR or space).
; Calls READHX then verifies the next character is CR or space; errors otherwise.
;
RDHXZ:
    CALL  READHX                    ;[3D17] Read hex number into HL
RDHX6:
    LD    A,(DE)                    ;[3D1A] Read next char
    CP    CR                        ;[3D1B] CR = end of input: OK
    RET   Z                         ;[3D1D]
    CP    ' '                       ;[3D1E] Space = separator: OK
    RET   Z                         ;[3D20]
    JP    MONERR                    ;[3D21] Unexpected char: error

;
; READHX: read a 4-digit hex number from (DE) into HL.
; Skips leading spaces, reads up to 4 hex digits.
;
READHX:
    LD    HL,0                      ;[3D24] HL = 0 (accumulator)
    RST   $10                       ;[3D27] Skip leading spaces
RDHX2:
    LD    A,(DE)                    ;[3D28] Read next character

    CALL  LUCC                      ;[3D29] Convert to uppercase
    SUB   '0'                       ;[3D2C] A -= '0': 0 if '0', 9 if '9', etc.
    RET   C                         ;[3D2E] Below '0': not hex, return (HL unchanged)
    CP    10                        ;[3D2F] Is it 0-9?
    JR    C,RDHX4                   ;[3D31] Yes: valid decimal digit
    SUB   7                         ;[3D33] A -= 7: 'A'-'0'-7 = 10, 'F'-'0'-7 = 15
    CP    10                        ;[3D35] Still below 10?
    RET   C                         ;[3D37] Yes: was in ':'-'@' gap, not valid hex
    CP    16                        ;[3D38] Above 'F'?
    RET   NC                        ;[3D3A] Yes: not valid hex
RDHX4:
    ADD   HL,HL                     ;[3D3B] HL <<= 1
    ADD   HL,HL                     ;[3D3C] HL <<= 1
    ADD   HL,HL                     ;[3D3D] HL <<= 1
    ADD   HL,HL                     ;[3D3E] HL <<= 1 (HL = HL * 16)
    ADD   A,L                       ;[3D3F] A = new hex digit
    LD    L,A                       ;[3D40] L = (HL * 16) | digit
    INC   DE                        ;[3D41] Advance input pointer
    JR    RDHX2                     ;[3D42] Read next digit

;
; READ3H: read 3 hex values from input, pushing them onto the stack.
; Returns: BC = third value, (SP) = second value, (SP+2) = first value.
; IX is saved and restored; caller pops the stack values.
;
READ3H:
    POP   IX                        ;[3D44] IX = return address (we'll JP (IX) at end)
RD3H1:
    CALL  RDHXZ                     ;[3D46] Read first hex value into HL
    PUSH  HL                        ;[3D49] Push first value
    CALL  RDHXZ                     ;[3D4A] Read second hex value into HL
    PUSH  HL                        ;[3D4D] Push second value
    CALL  RDHXZ                     ;[3D4E] Read third hex value into HL
    LD    C,L                       ;[3D51] BC = third value
    LD    B,H                       ;[3D52]
    JP    (IX)                      ;[3D53] Return to caller (via saved return address)

;
; DSPASC: display a byte as ASCII. Non-printable characters (< $20) shown as '.'.
; Strips bit 7 first (handles chars with parity bit set).
;
DSPASC:
    AND   $7F                       ;[3D55] Strip bit 7 (parity)
    CP    ' '                       ;[3D57] Is it a printable ASCII char (>= space)?
    JR    NC,$3D5D                  ;[3D59] Yes: display it as-is
    LD    A,'.'                     ;[3D5B] No: replace with '.'
    JP    PUTCHAR                   ;[3D5D] Display and return

;
; TYPE: Monitor T command - type ASCII text into memory starting at address.
; Reads the address, then stores each following character into memory.
;
TYPE:
    CALL  RDHXZ                     ;[3D60] Read start address into HL
    LD    A,(DE)                    ;[3D63] Read next char (should be space or CR)
    CP    $0D                       ;[3D64] CR (no text): done
    RET   Z                         ;[3D66]
TYPE1:
    INC   DE                        ;[3D67] Advance to next input char
    LD    A,(DE)                    ;[3D68] Read it
    CP    $0D                       ;[3D69] CR = end of text
    RET   Z                         ;[3D6B]
    LD    (HL),A                    ;[3D6C] Store ASCII byte at current address
    INC   HL                        ;[3D6D] Advance memory pointer
    JR    TYPE1                     ;[3D6E] Next character

;
; COPY: Monitor C command - simple (dumb) forward block copy.
; Reads: source_start, source_end, destination.
; Uses LDIR (forward copy; overlaps not handled).
;
COPY:
    CALL  READ3H                    ;[3D70] Read 3 hex values: BC=length/end, (SP)=dest, (SP+2)=src
    POP   DE                        ;[3D73] DE = destination address
    POP   HL                        ;[3D74] HL = source start
COPY1:
    LDIR                            ;[3D75] Copy BC bytes from HL to DE
    RET                             ;[3D77]

;
; INTELL: Monitor I command - intelligent copy (handles overlapping regions).
; Reads: source_start, source_end, destination.
; If destination > source (overlap risk): uses LDDR (backward copy); else uses LDIR.
;
INTELL:
    CALL  READ3H                    ;[3D78] Read 3 hex values: BC=count, (SP)=dest, (SP+2)=src
    POP   DE                        ;[3D7B] DE = destination
    POP   HL                        ;[3D7C] HL = source start
    CALL  CHLDE                     ;[3D7D] Compare HL and DE: carry if HL < DE (dest > src)
    JR    NC,COPY1                  ;[3D80] HL >= DE: no forward-overlap risk, use LDIR
    ADD   HL,BC                     ;[3D82] HL = source end (start + count)
    EX    DE,HL                     ;[3D83]
    ADD   HL,BC                     ;[3D84] HL = dest end
    EX    DE,HL                     ;[3D85] DE = source end, HL = dest end
    DEC   DE                        ;[3D86] Point to last source byte
    DEC   HL                        ;[3D87] Point to last dest byte
    LDDR                            ;[3D88] Backward copy (prevents overlap corruption)
    RET                             ;[3D8A]

;
; ARTHM: Monitor A command - hex arithmetic.
; Reads two hex values, displays: sum, difference, and byte offset.
;
ARTHM:
    CALL  RDHXZ                     ;[3D8B] Read first value into HL
    PUSH  HL                        ;[3D8E] Save
    CALL  RDHXZ                     ;[3D8F] Read second value into HL
    LD    E,L                       ;[3D92] DE = second value
    LD    D,H                       ;[3D93]
    POP   HL                        ;[3D94] HL = first value
    PUSH  HL                        ;[3D95] Save first value again
    ADD   HL,DE                     ;[3D96] HL = first + second (sum)
    CALL  PRINT_HEX_HL              ;[3D97] Display sum
    POP   HL                        ;[3D9A] Restore first value
    PUSH  HL                        ;[3D9B] Save again
    OR    A                         ;[3D9C] Clear carry
    SBC   HL,DE                     ;[3D9D] HL = first - second (difference)
    CALL  PRINT_HEX_HL              ;[3D9F] Display difference
    POP   HL                        ;[3DA2] Restore first value
    EX    DE,HL                     ;[3DA3] DE = first, HL = second
    DEC   HL                        ;[3DA4] HL = second - 1
    SCF                             ;[3DA5] Set carry
    SBC   HL,DE                     ;[3DA6] HL = second - 1 - first = byte offset
    LD    A,H                       ;[3DA8] Check high byte of offset
    OR    A                         ;[3DA9]
    JR    Z,ARTH1                   ;[3DAA] High byte = 0: offset fits in one byte
    INC   A                         ;[3DAC] Is high byte = $FF?
    JR    Z,ARTH2                   ;[3DAD] Yes: negative single-byte offset
ARTH3:
    LD    HL,ARTHMSG                ;[3DAF] Offset too large: display "??"
    CALL  PLINE                     ;[3DB2]
ARTH4:
    JP    CRLF                      ;[3DB5] Output newline and return
ARTH1:
    LD    A,L                       ;[3DB8] A = low byte of offset
    CP    $80                       ;[3DB9] >= $80 (negative as signed)?
    JR    NC,ARTH3                  ;[3DBB] Yes: out of signed byte range, show "??"
ARTH5:
    CALL  MPHXA                     ;[3DBD] Display offset as hex
    JR    ARTH4                     ;[3DC0] Newline
ARTH2:
    LD    A,L                       ;[3DC2] A = low byte of negative offset
    CP    $80                       ;[3DC3] < $80 (would be positive as unsigned)?
    JR    C,ARTH3                   ;[3DC5] Yes: out of signed byte range, show "??"
    JR    ARTH5                     ;[3DC7] Display it

;
; ARTHMSG: "??" displayed when offset is out of single-byte range.
;
ARTHMSG:
    DB    "??",0                    ;[3DC9]

;
; FILL: Monitor F command - fill memory block with a byte value.
; Reads: start_address, end_address, fill_byte.
; Fills from start to end (inclusive) with the byte.
;
FILL:
    CALL  READ3H                    ;[3DCC] Read 3 values: BC=fill_byte(L), (SP)=end, (SP+2)=start
    LD    A,L                       ;[3DCF] A = fill byte
    POP   HL                        ;[3DD0] HL = end address
    POP   DE                        ;[3DD1] DE = start address
    OR    A                         ;[3DD2] Clear carry
    SBC   HL,DE                     ;[3DD3] HL = length (end - start)
    LD    C,L                       ;[3DD5] BC = length
    LD    B,H                       ;[3DD6]
    LD    H,D                       ;[3DD7] HL = start address
    LD    L,E                       ;[3DD8]
    INC   DE                        ;[3DD9] DE = start + 1
    LD    (HL),A                    ;[3DDA] Store fill byte at start
    LDIR                            ;[3DDB] Fill remainder: copy first byte to the rest
    RET                             ;[3DDD]

;
; QUERY: Monitor Q command - read a byte from an I/O port and display it.
;
QUERY:
    CALL  RDHXZ                     ;[3DDE] Read port number into HL
    LD    C,L                       ;[3DE1] C = port low byte
    LD    B,H                       ;[3DE2] B = port high byte
    IN    A,(C)                     ;[3DE3] Read byte from port BC
    CALL  MPHXA                     ;[3DE5] Display as 2 hex digits + space
    JP    CRLF                      ;[3DE8] Newline

;
; MOUT: Monitor O command - output a byte to an I/O port.
;
MOUT:
    CALL  RDHXZ                     ;[3DEB] Read port number into HL
    LD    C,L                       ;[3DEE] C = port low byte
    LD    B,H                       ;[3DEF] B = port high byte
    CALL  RDHXZ                     ;[3DF0] Read byte value into HL
    OUT   (C),L                     ;[3DF3] Output L to port BC
    RET                             ;[3DF5]

;
; GO: Monitor G command - execute from an address.
; Reads the address and jumps directly to it (not restoring saved registers).
;
GO:
    CALL  RDHXZ                     ;[3DF6] Read address into HL
    JP    (HL)                      ;[3DF9] Jump to it

;
; LUCC: convert lowercase ASCII letter to uppercase.
; If A < $40 (not a letter or already uppercase): return unchanged.
; Otherwise: clear bit 5 to force uppercase.
;
LUCC:
    CP    $40                       ;[3DFA] Is A < '@' (not a letter)?
    RET   C                         ;[3DFC] Yes: return unchanged
    RES   5,A                       ;[3DFD] Clear bit 5: 'a'-'z' -> 'A'-'Z'
    RET                             ;[3DFF]

;
; WORD: Monitor W command - search memory for a 16-bit word value.
; Reads: start_address, word_value.
; Scans from start_address to $FFFF, printing each matching address.
;
WORD:
    CALL  RDHXZ                     ;[3E00] Read start address into HL
    PUSH  HL                        ;[3E03] Save start address
    CALL  RDHXZ                     ;[3E04] Read word value into HL
    LD    E,L                       ;[3E07] E = low byte of word to find
    LD    D,H                       ;[3E08] D = high byte of word to find
    POP   HL                        ;[3E09] HL = search start address
WORD1:
    LD    A,(HL)                    ;[3E0A] Read byte at current address
    CP    E                         ;[3E0B] Compare with low byte of word
    JR    NZ,WORD2                  ;[3E0C] No match
    INC   HL                        ;[3E0E] Check next byte
    LD    A,(HL)                    ;[3E0F] Read high byte
    DEC   HL                        ;[3E10] Restore HL to base address
    CP    D                         ;[3E11] Compare with high byte of word
    JR    NZ,WORD2                  ;[3E12] No match
    CALL  WORDSB                    ;[3E14] Print address and save in MONST
WORD2:
    CALL  ESC                       ;[3E17] Check for ESC key (abort)
    RET   Z                         ;[3E1A] ESC pressed: stop
    INC   HL                        ;[3E1B] Advance to next address
    LD    A,L                       ;[3E1C] Check for address wrap ($FFFF + 1 = 0)
    OR    H                         ;[3E1D]
    JR    NZ,WORD1                  ;[3E1E] Not wrapped: continue
    RET                             ;[3E20] Wrapped to 0: done

;
; WORDSB: print HL as hex address and newline, save in MONST.
; Shared by WORD, LOCAT, and COMPAR.
;
WORDSB:
    CALL  PRINT_HEX_HL              ;[3E21] Print address in hex + space
    LD    (MONST),HL                ;[3E24] Save as last found address
    JP    CRLF                      ;[3E27] Newline and return

;
; LOCAT: Monitor L command - locate (search for) a single byte value.
; Reads: start_address, byte_value.
; Scans from start_address to $FFFF, printing each matching address.
;
LOCAT:
    CALL  RDHXZ                     ;[3E2A] Read start address into HL
    PUSH  HL                        ;[3E2D] Save start address
    CALL  RDHXZ                     ;[3E2E] Read byte to find into HL
    LD    E,L                       ;[3E31] E = byte to find
    POP   HL                        ;[3E32] HL = search start
LOCAT2:
    LD    A,(HL)                    ;[3E33] Read byte at current address
    CP    E                         ;[3E34] Does it match?
    JR    NZ,LOCAT1                 ;[3E35] No: skip
    CALL  WORDSB                    ;[3E37] Yes: print address
LOCAT1:
    CALL  ESC                       ;[3E3A] Check for ESC (abort)
    RET   Z                         ;[3E3D] ESC: stop
    INC   HL                        ;[3E3E] Next address
    LD    A,L                       ;[3E3F]
    OR    H                         ;[3E40] Address wrapped to 0?
    JR    NZ,LOCAT2                 ;[3E41] No: continue
    RET                             ;[3E43]

;
; COMPAR: Monitor V command - verify/compare two memory blocks.
; Reads: source_start, source_end, dest_start (via READ3H).
; Reports addresses where source and dest differ.
;
COMPAR:
    CALL  READ3H                    ;[3E44] BC=count, (SP)=dest, (SP+2)=source
    POP   DE                        ;[3E47] DE = destination block start
    POP   HL                        ;[3E48] HL = source block start
COMPR1:
    LD    A,(DE)                    ;[3E49] Read destination byte
    CP    (HL)                      ;[3E4A] Compare with source byte
    CALL  NZ,PRINT_HEX_HL           ;[3E4B] Mismatch: print source address
    INC   DE                        ;[3E4E] Advance both pointers
    INC   HL                        ;[3E4F]
    PUSH  BC                        ;[3E50] Save count
    CALL  ESC                       ;[3E51] Check for ESC
    POP   BC                        ;[3E54]
    JR    Z,COMPR4                  ;[3E55] ESC: abort
    DEC   BC                        ;[3E57] Decrement count
    LD    A,B                       ;[3E58]
    OR    C                         ;[3E59] BC = 0?
    JR    NZ,COMPR1                 ;[3E5A] No: continue
COMPR4:
    JP    CRLF                      ;[3E5C] Newline and return

;
; UPDAT2: continuation of UPDAT register search when name doesn't match.
; Steps past the current register entry and loops.
;
UPDAT2:
    POP   DE                        ;[3E5F] Discard saved DE
    POP   HL                        ;[3E60] Restore HL to beginning of current name
    INC   HL                        ;[3E61] Step past name character 1
    INC   HL                        ;[3E62] Step past name character 2
    INC   HL                        ;[3E63] Step past name character 3
    INC   IX                        ;[3E64] Step IX past register low byte
    INC   IX                        ;[3E66] Step IX past register high byte
    POP   BC                        ;[3E68] Restore outer loop count
    DJNZ  UPDAT0                    ;[3E69] Try next register name
    JP    MONERR                    ;[3E6B] Register name not found: error

;
; UPDAT: Monitor U command - update (write) a saved register value.
; Input: register name (2-3 chars) followed by new hex value.
; Matches name against REGMSG table and writes the new value into TRAPAF..TRAPPC area.
;
UPDAT:
    LD    HL,REGMSG                 ;[3E6E] HL -> register name table
    LD    IX,TRAPAF                 ;[3E71] IX -> first saved register value
UPDAT0:
    PUSH  BC                        ;[3E75] Save loop count (B = remaining registers)
    PUSH  HL                        ;[3E76] Save HL (current name position)
    PUSH  DE                        ;[3E77] Save DE (input buffer pointer)
    LD    B,$03                     ;[3E78] 3 characters to compare
UPDAT1:
    LD    A,(DE)                    ;[3E7A] Read input char
    CP    (HL)                      ;[3E7B] Compare with name char
    INC   DE                        ;[3E7C] Advance input pointer
    INC   HL                        ;[3E7D] Advance name pointer
    JR    NZ,UPDAT2                 ;[3E7E] Mismatch: try next register
    DJNZ  UPDAT1                    ;[3E80] Compare all 3 chars
    POP   BC                        ;[3E82] Discard saved DE, HL, BC (match found)
    POP   BC                        ;[3E83]
    POP   BC                        ;[3E84]
    CALL  RDHXZ                     ;[3E85] Read new hex value into HL
    LD    (IX+$00),L                ;[3E88] Store low byte into saved register
    LD    (IX+$01),H                ;[3E8B] Store high byte into saved register

;
; PREG: Monitor X command - display saved registers in compact form.
; Displays two groups: first 4 register pairs, then the remaining 8.
; Then displays the flags field.
;
PREG:
    LD    DE,TRAPAF                 ;[3E8E] DE -> saved AF (start of register area)
    LD    B,4                       ;[3E91] Display 4 register pairs (AF,HL,DE,BC)
    CALL  PREGS                     ;[3E93] Display them
    LD    A,CEL                     ;[3E96] Clear to EOL
    RST   $08                       ;[3E98]
    LD    A,XCRLF                   ;[3E99] Carriage return
    RST   $08                       ;[3E9B]
    LD    B,8                       ;[3E9C] Display 8 more (AF',HL',DE',BC',IX,IY,SP,PC)
    CALL  PREGS                     ;[3E9E]
    CALL  PFLAG                     ;[3EA1] Display flags field
    LD    A,CEL                     ;[3EA4] Clear to EOL
    RST   $08                       ;[3EA6]
    JP    CRLF                      ;[3EA7] Newline

;
; PREGS: display B register pairs from (DE), each as 4 hex digits + space.
;
PREGS:
    LD    A,(DE)                    ;[3EAA] Read low byte of register
    LD    L,A                       ;[3EAB]
    INC   DE                        ;[3EAC]
    LD    A,(DE)                    ;[3EAD] Read high byte
    LD    H,A                       ;[3EAE]
    INC   DE                        ;[3EAF]
    CALL  PRINT_HEX_HL              ;[3EB0] Display as 4 hex digits + space
    DJNZ  PREGS                     ;[3EB3] Repeat B times
    RET                             ;[3EB5]

;
; PFLAG: display the CPU flags field in symbolic form.
; Reads saved AF flags byte, displays each flag as its letter (set) or '.' (clear).
; Uses FLGMSG string: "SZ1H1PNC" (Sign, Zero, -, HalfCarry, -, Parity, Neg, Carry).
;
PFLAG:
    LD    A,(TRAPAF)                ;[3EB6] Load saved flags byte (F register)
    LD    HL,FLGMSG                 ;[3EB9] HL -> flag name string
    LD    C,A                       ;[3EBC] C = flags (will be rotated)
    SCF                             ;[3EBD] Set carry to act as stop sentinel in C
PFLAG1:
    RL    C                         ;[3EBE] Rotate next flag bit into carry
    RET   Z                         ;[3EC0] C became 0 (sentinel reached): done
    LD    A,(HL)                    ;[3EC1] Load flag letter from FLGMSG
    JR    C,PFLAG2                  ;[3EC2] Flag bit set: display the letter
    LD    A,'.'                     ;[3EC4] Flag bit clear: display '.'
PFLAG2:
    RST   $08                       ;[3EC6] Display character
    INC   HL                        ;[3EC7] Advance to next flag letter
    OR    A                         ;[3EC8] (clears carry; OR sets flags)
    JR    PFLAG1                    ;[3EC9] Next flag bit

;
; FLGMSG: flag name characters in bit order (MSB first: S, Z, -, H, -, P, N, C).
;
FLGMSG:
    DB    "SZ1H1PNC",0              ;[3ECB] 8 flag names + null

;
; EXECUT: Monitor E command - execute (resume from monitor).
; With address: execute from given address.
; Without address (CR only): resume from saved TRAPPC.
; Restores all saved registers and jumps via GOPC.
;
EXECUT:
    JR    Z,EXECUT1                 ;[3ED4] CR only: use saved TRAPPC
    CALL  RDHXZ                     ;[3ED6] Read execution address into HL
    JR    UNTRP1                    ;[3ED9] Use it as the target
EXECUT1:
    LD    HL,(TRAPPC)               ;[3EDB] HL = saved PC (resume point)
UNTRP1:
    LD    (GOPC+1),HL               ;[3EDE] Write target address into the JP instruction at GOPC
    LD    SP,(MONSP)                ;[3EE1] Restore monitor stack pointer
    POP   AF                        ;[3EE5] Restore main AF
    POP   HL                        ;[3EE6] Restore main HL
    POP   DE                        ;[3EE7] Restore main DE
    POP   BC                        ;[3EE8] Restore main BC
    EXX                             ;[3EE9] Switch to alternate registers
    EX    AF,AF'                    ;[3EEA]
    POP   AF                        ;[3EEB] Restore alternate AF'
    POP   HL                        ;[3EEC] Restore alternate HL'
    POP   DE                        ;[3EED] Restore alternate DE'
    POP   BC                        ;[3EEE] Restore alternate BC'
    EXX                             ;[3EEF] Switch back to main registers
    EX    AF,AF'                    ;[3EF0]
    POP   IX                        ;[3EF1] Restore IX
    POP   IY                        ;[3EF3] Restore IY
    LD    SP,(TRAPSP)               ;[3EF5] Restore the original user stack pointer
    JP    GOPC                      ;[3EF9] Execute: JP to target address (GOPC = $C3 nn nn)

;
; DUMP: Monitor D command - save memory block to tape.
; Format: 'D "filename" start end transfer_address'
; Tape format: sync + 'M' + length(2) + load_addr(2) + data + checksum + 'E' + transfer_addr(2).
;
DUMP:
    CALL  READ3H                    ;[3EFC] BC=transfer_addr, (SP)=end_addr, (SP+2)=start_addr
    PUSH  HL                        ;[3EFF] Push transfer address (was in HL from READ3H)
    CALL  DUMSUB                    ;[3F00] Validate filename (must be quoted)
    CALL  WRITE_FNAME               ;[3F03] Write filename to tape
    POP   DE                        ;[3F06] DE = transfer address
    POP   HL                        ;[3F07] HL = end address
    POP   BC                        ;[3F08] BC = start address
    PUSH  BC                        ;[3F09] Re-save start for data loop
    OR    A                         ;[3F0A] Clear carry
    SBC   HL,BC                     ;[3F0B] HL = end - start = length - 1
    INC   HL                        ;[3F0D] HL = length
    LD    C,L                       ;[3F0E] BC = length
    LD    B,H                       ;[3F0F]
    POP   HL                        ;[3F10] HL = start address
    PUSH  DE                        ;[3F11] Save transfer address
    CALL  WSYNC                     ;[3F12] Write sync pulses
    LD    A,'M'                     ;[3F15] Write 'M' block marker
    CALL  SYSVAR_WBYTE              ;[3F17]
    LD    A,C                       ;[3F1A] Write length low byte
    CALL  SYSVAR_WBYTE              ;[3F1B]
    LD    A,B                       ;[3F1E] Write length high byte
    CALL  SYSVAR_WBYTE              ;[3F1F]
    CALL  W2BYTE                    ;[3F22] Write load address (HL = start) as 2 bytes
    LD    E,0                       ;[3F25] E = running checksum
DUMP2:
    LD    A,(HL)                    ;[3F27] Read data byte
    CALL  SYSVAR_WBYTE              ;[3F28] Write to tape
    INC   HL                        ;[3F2B] Advance data pointer
    ADD   A,E                       ;[3F2C] Accumulate checksum
    LD    E,A                       ;[3F2D]
    DEC   BC                        ;[3F2E] Decrement byte count
    LD    A,B                       ;[3F2F]
    OR    C                         ;[3F30] BC = 0?
    JR    NZ,DUMP2                  ;[3F31] No: continue
    LD    A,E                       ;[3F33] A = final checksum
    CALL  SYSVAR_WBYTE              ;[3F34] Write checksum byte
    LD    A,'E'                     ;[3F37] Write 'E' end-of-block marker
    CALL  SYSVAR_WBYTE              ;[3F39]
    POP   HL                        ;[3F3C] HL = transfer address
    CALL  W2BYTE                    ;[3F3D] Write transfer address (2 bytes)
    CALL  SYSVAR_WBYTE              ;[3F40] Write one more byte (padding/extra)
    JP    MOTOFF                    ;[3F43] Stop tape motor and return

;
; W2BYTE: write the 16-bit value in HL to tape (low byte first, then high byte).
;
W2BYTE:
    LD    A,L                       ;[3F46] A = low byte
    CALL  SYSVAR_WBYTE              ;[3F47] Write low byte
    LD    A,H                       ;[3F4A] A = high byte
    JP    SYSVAR_WBYTE              ;[3F4B] Write high byte and return

;
; DUMSUB: validate and position DE past a quoted filename in the input buffer.
; Input must start with '"'. Scans for closing '"', errors if not found (CR first).
; On return, DE points just after the closing '"'.
;
DUMSUB:
    RST   $10                       ;[3F4E] Skip leading spaces
    CP    '"'                       ;[3F4F] First non-space must be '"'
    JP    NZ,MONERR                 ;[3F51] No quote: error
    PUSH  DE                        ;[3F54] Save position after opening '"'
DUMP1:
    INC   DE                        ;[3F55] Advance into filename
    LD    A,(DE)                    ;[3F56] Read char
    CP    CR                        ;[3F57] CR before closing '"'?
    JP    Z,MONERR                  ;[3F59] Yes: unterminated filename, error
    CP    '"'                       ;[3F5C] Closing '"'?
    JR    NZ,DUMP1                  ;[3F5E] No: continue scanning
    POP   DE                        ;[3F60] Restore DE (pointing after opening '"')
    RET                             ;[3F61] DE is now correctly positioned for WRITE_FNAME

;
; EMLOAD: entry point for MLOAD command (load from tape into BASIC).
; Sets MONSP from SYSVAR_STACK, then falls into tape load at ELDM1.
;
EMLOAD:
    LD    HL,(SYSVAR_STACK)         ;[3F62] HL = BASIC stack pointer
    LD    (MONSP),HL                ;[3F65] Save as monitor SP (for error recovery)
    JR    ELDM1                     ;[3F68] Enter tape load

;
; RTAPE: Monitor R command - read (load) a block from tape.
; Validates filename, copies filename to polled-input buffer,
; then enters the tape load loop.
;
RTAPE:
    CALL  DUMSUB                    ;[3F6A] Validate and position past filename
    LD    HL,(SYSVAR_POLBUF)        ;[3F6D] HL -> polled input buffer
    PUSH  HL                        ;[3F70] Save buffer address
    EX    DE,HL                     ;[3F71] HL = DE = filename start in input
    LD    BC,255                    ;[3F72] Max 255 chars to copy
    LDIR                            ;[3F75] Copy filename into polled buffer
    POP   DE                        ;[3F77] DE = polled buffer (filename copy)
ELDM1:
    CALL  TAPE_READ                 ;[3F78] Initialise tape read (start motor, etc.)
RTAPE6:
    CALL  RSYNC                     ;[3F7B] Read sync sequence from tape
    CALL  RBYTE                     ;[3F7E] Read first byte after sync
    CP    'M'                       ;[3F81] Is it 'M' (block marker)?
    JR    NZ,RTPERR                 ;[3F83] No: bad tape format error
    CALL  RBYTE                     ;[3F85] Read length low byte
    LD    C,A                       ;[3F88] C = length low
    CALL  RBYTE                     ;[3F89] Read length high byte
    LD    B,A                       ;[3F8C] BC = block length
    CALL  RBYTE                     ;[3F8D] Read load address low byte
    LD    L,A                       ;[3F90] L = load address low
    CALL  RBYTE                     ;[3F91] Read load address high byte
    LD    H,A                       ;[3F94] HL = load address
    LD    E,0                       ;[3F95] E = checksum accumulator
RTAPE2:
    CALL  RBYTE                     ;[3F97] Read data byte
    LD    (HL),A                    ;[3F9A] Store at load address
    INC   HL                        ;[3F9B] Advance load pointer
    ADD   A,E                       ;[3F9C] Accumulate checksum
    LD    E,A                       ;[3F9D]
    DEC   BC                        ;[3F9E] Decrement remaining count
    LD    A,B                       ;[3F9F]
    OR    C                         ;[3FA0] BC = 0?
    JR    NZ,RTAPE2                 ;[3FA1] No: read more data
    CALL  RBYTE                     ;[3FA3] Read checksum byte
    CP    E                         ;[3FA6] Does it match computed checksum?
    JR    NZ,RTPERR                 ;[3FA7] No: bad tape (checksum error)
    CALL  RBYTE                     ;[3FA9] Read end marker
    CP    'N'                       ;[3FAC] Is it 'N' (continuation block follows)?
    JR    Z,RTAPE6                  ;[3FAE] Yes: read next block
    CALL  RBYTE                     ;[3FB0] Read transfer address low byte
    LD    L,A                       ;[3FB3] L = transfer address low
    CALL  RBYTE                     ;[3FB4] Read transfer address high byte
    LD    H,A                       ;[3FB7] HL = transfer address
    CALL  MOTOFF                    ;[3FB8] Stop tape motor
    LD    A,L                       ;[3FBB]
    OR    H                         ;[3FBC] Is transfer address 0?
    JR    NZ,RTAPE5                 ;[3FBD] No: execute from transfer address
    LD    A,CR                      ;[3FBF] Transfer = 0: no auto-execute, output CR
    RST   $08                       ;[3FC1]
    RET                             ;[3FC2]

;
; RTAPE5: execute from the transfer address loaded from tape.
;
RTAPE5:
    JP    (HL)                      ;[3FC3] Jump to transfer address

;
; RTPERR: tape read error handler.
; Stops motor, displays "Bad Tape" message, and re-enters monitor prompt.
;
RTPERR:
    CALL  MOTOFF                    ;[3FC4] Stop tape motor
    LD    HL,BTMS                   ;[3FC7] HL -> "Bad Tape" message
    CALL  PLINE                     ;[3FCA] Display error
    LD    A,CR                      ;[3FCD] Output CR
    RST   $08                       ;[3FCF]
    JP    MONERR                    ;[3FD0] Return to monitor prompt

;
; SUB_MULTIPLY1: carry propagation patch for MLONE multiplication.
; If carry set from BCD addition: increments E (overflow counter) and
; stores result. This entry point is where Mark II ROM patches apply (PAT41).
;
SUB_MULTIPLY1:
    JR    NC,$3FD6                  ;[3FD3] No carry: skip to store
    INC   E                         ;[3FD5] Carry: increment overflow count
    LD    (HL),A                    ;[3FD6] Store result byte into WRA1
    LD    D,E                       ;[3FD7] D = E (carry count for next iteration)
    DEC   HL                        ;[3FD8] Advance pointer toward MSB
    RET                             ;[3FD9]

;
; SUB_DIM: helper for DIM statement string table initialisation.
; Zeroes two bytes past (HL) (the string length/pointer field),
; then jumps to EDMSUB to continue DIM processing.
;
SUB_DIM:
    PUSH  HL                        ;[3FDA] Save HL
    INC   HL                        ;[3FDB] Point to second byte
    LD    (HL),$00                  ;[3FDC] Zero it
    INC   HL                        ;[3FDE] Point to third byte
    LD    (HL),$00                  ;[3FDF] Zero it
    POP   HL                        ;[3FE1] Restore HL
    JP    EDMSUB                    ;[3FE2] Continue DIM processing

;
; PATCH6: spare patch area (filled with $FF in the original ROM).
; In the 48K ROM these bytes are used for a small routine fragment;
; the comment "Set to FF and not used" reflects the Mark I ROM where
; this area was unused padding.
;
PATCH6:
    LD    A,B                       ;[3FE5] (patch area - see ROM version notes)
    OR    A                         ;[3FE6]
    RET   Z                         ;[3FE7]
    JP    STRING_SEEK_END           ;[3FE8] Jump to string end-seek routine

;
; FNACOS: ARCSIN helper via ARCCOS.
; Computes ARCCOS of the current value, then adjusts using ARCTAN4.
; This implements: ARCSIN(x) via ARCCOS identity for negative arguments.
;
FNACOS:
    CALL  FARCCOS                   ;[3FEB] Compute ARCCOS(x)
    JP    ARCTAN4                   ;[3FEE] Adjust to get ARCSIN result

;
; SUB_MOD: MOD operator adjustment.
; If result was negative (carry from division), adds the divisor back.
; Then adds 0.5 twice (net effect: adjust rounding for MOD semantics).
;
SUB_MOD:
    RLA                             ;[3FF1] Test sign of result (rotate carry from sign)
    CALL  NC,ADD                    ;[3FF2] If carry clear (negative): add WRA2 (divisor) back
    LD    HL,FLOAT_HALF             ;[3FF5] HL -> 0.5
    CALL  LNUM2                     ;[3FF8] WRA2 = 0.5
    JP    ADD                       ;[3FFB] WRA1 += 0.5 (final MOD adjustment)

    RST   $38                       ;[3FFE] (filler - RST 38h = $FF opcode, triggers IM1 handler)
    NOP                             ;[3FFF] End of ROM at $3FFF
DEPHASE