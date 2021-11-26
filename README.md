Camputers Lynx 48k ROM disassembly (version L014)
=================================================

Originally, this assembly code was reconstructed from Lynx 48k eprom memory images, and supplemented with information from Lynx User Magazine Issue 1 (Camputers, June 1983, pages 16-18) and Nilug News (Issue 6) by R.B.Poate. It has now been supplemented with Camputers Lynx "Mark II" source code (circa: 1-Apr-1984) (see below).

Some of the labels and symbols arise from Lynx User and Nilug News, and others are my own creations for clarity. A rough database and script was used to create the disassembly listing.

This code can be assembled (eg. using Z88dk) to produce a 16k ROM which is an exact replica of the original L014 ROMs (2x8k) that were supplied with the Lynx computer.

17/11/2021: The code has now been enhanced with information from some original source code dated Apr-1984 (kindly supplied by Russell Davis and Pete Todd - see below). The 1984 source code was written using Macro-80 Assembler and (most likely) originates from Camputers themselves. However the code is different in some ways, and looks to be an enhanced version of the original ROM (ie. a post L014 version). I refer to this code as the "Mark II source code", as it was probably targetting the later 96k and 128k Lynx models. Nevertheless, it contains many of the original rom routines. Subsequently, labels, comments, and symbols from the Mark II listing have been incorporated back into my L014 assembly, for consistency and clarity, where useful.

I am unsure if the Mark II code ever made it to production. At the time of writing, an online archive of the complete Mark II source code can be found at Pete Todd's website, here: http://www.retrogubbins.co.uk/downloads/summary/20-lynx-rom-source-code

Finally: this is just my *interpretation* of the ROMs - *not* the original source
code. The analysis is incomplete, and may change. It's purpose is to aid understanding.

Disassembly and analysis by: Mike Panter 26/11/2021

Credit to: 
 - DAVIS (the original author of the Lynx ROMs @ Camputers)
 - Sue Jansons (author, "Camputers Lynx User Manual", Camputers)

also: 
 - Russell Davis (online archive of materials) 
 - Pete Todd (knowledge, insight and Pale)

WARNING: May contain inaccuracies - use at own risk.

Free to distribute. Please include attribution.

********************** LABELS/SYMBOLS/PREFIXES ************************

      * SYSVAR_     - RAM addresses used by the Lynx ROM routines
      * RST_        - Z80 Restarts
      * DATA_       - Data tables stored in rom (eg. PI)
      * E<command>  - Lynx BASIC command
      * F<name>     - Lynx BASIC functions/operators
      * I<name>     - Validation of BASIC commands/functions.
      * MONITOR_    - Lynx MONITOR commands
      * VDU_        - VDU commands
      * SUB_        - internal subroutines used by ROM
