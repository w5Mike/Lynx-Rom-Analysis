## Camputers Lynx 48k/96k ROM disassembly (version L014)

This assembly code was originally constructed from Lynx 48k eprom memory images, and supplemented with information from Lynx User Magazine *(Lynx User Issue 1 - Camputers, June 1983, pages 16-18)* and Nilug News (*Issue 6*) by R.B.Poate. It has now been supplemented with Camputers Lynx "Mark II" source code *(circa: 1-Apr-1984)* (see below).

Some of the labels and symbols arise from Lynx User and Nilug News, and others are my own creations for clarity. A rough database and script was used to create the disassembly listing.

This code can be assembled (eg. using Z88dk) to produce an exact replica of the original "L014" ROMs (2x8k) that were supplied with the original Lynx computer. The assembly itself contains an identifier "L014", which likely represents the version number.

### "Davis" ROM Source Code 

**17/11/2021:** The code has now been enhanced with information from source code dated April 1984 (kindly supplied by Russell Davis and Pete Todd - see below). The 1984 source code was written using Macro-80 Assembler and (most likely) originates from **Camputers** themselves. The embedded identifier for this ROM is "Davis" - the name of the primary author.

The code is different in some ways, and looks to be an enhanced version of the original ROM (ie. a post L014 version). I refer to this code as the "Mark II source code", as it was probably targetting the later 96k and 128k Lynx models. Nevertheless, it contains many of the original rom routines. Subsequently, labels, comments, and symbols from the Mark II listing have been incorporated back into my L014 assembly, for consistency and clarity, where useful.

I am unsure if the Mark II code ever made it to production. At the time of writing, an online archive of the complete Mark II source code can be found at Peter Todd's website, here: [Pete's archive: Lynx Rom Source Code](http://www.retrogubbins.co.uk/downloads/summary/20-lynx-rom-source-code)

### Claude/AI Annotation Enhancements

**06/03/2026**: Additional comments/annotations provided by CLAUDE (Anthropic's AI) under the direction of Mike Panter 06/03/2026.

A considerable number of annotations have been added to the source code to aid understanding. 
*Many of the comments were created by AI and may contain errors.*

### Finally
This is just my *interpretation* of the ROMs and *not* the original source code. The analysis is incomplete, and may change. It's purpose is to aid understanding.

*WARNING: may contain inaccuracies - use at own risk.*

Free to distribute. Please include attribution.

---

### Credits and Attribution
- Mike Panter - modern/recent disassembly and analysis (26/11/2021, 06/03/2026)
- Richard Greenwood - original founder (Camputers Ltd) 
- John Shirreff - system architecture (Camputers Ltd)
- Martin Crutchley - tooling (Camputers Ltd)

#### Original ROM Development:

 - Davis Jansons - original author of the Lynx ROMs/BASIC @ Camputers
 - Shane Voss and Fiona Mille - Hardware driver authors 
 - Michael Behrend and Ron Penrose - Graphics routines authors
 - Sue Jansons - "Camputers Lynx User Manual" author

#### Thanks to: 
 - Russell Davis (online archive of Lynx-related materials) 
 - Pete Todd (knowledge, insight and Pale)

---
#### LABELS/SYMBOLS/PREFIXES
 - ```SYSVAR_```     - RAM addresses used by the Lynx ROM routines
 - ```RST_```        - Z80 Restarts
 - ```DATA_```       - Data tables stored in rom (eg. PI)
 - ```E<command>```  - Lynx BASIC command
 - ```F<name>```     - Lynx BASIC functions/operators
 - ```I<name>```     - Validation of BASIC commands/functions.
 - ```MONITOR_```    - Lynx MONITOR commands
 - ```VDU_```        - VDU commands
 - ```SUB_```        - internal subroutines used by ROM
