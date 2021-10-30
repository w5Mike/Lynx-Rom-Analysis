Camputers Lynx 48k ROM disassembly (version L014)
=================================================

Reconstructed from Lynx 48k eprom memory images and supplemented with information 
from Lynx User Magazine Issue 1 (Camputers, June 1983, pages 16-18) and Nilug News
(Issue 6) by R.B.Poate. 

Disclaimer: this is just my interpretation of the ROMs - *not* the original source
code (- the whereabouts are unknown).

Disassembly, analysis and mistakes by: Mike Panter 10/10/2021

Credit to: 
 - DAVIS (the original author of the Lynx ROMs @ Camputers)
 - Sue Jansons (author, "Camputers Lynx User Manual", Camputers)

also: 
 - Russell Davis (online archive of materials) 
 - Pete Todd (knowledge, insight and Pale)

WARNING: May contain inaccuracies - use at own risk.

Free to distribute. Please include attribution.

********************** LABELS/SYMBOLS/PREFIXES ************************

 - SYSVAR_     - RAM addresses used by the Lynx ROM routines
 - RST_        - Z80 Restarts
 - DATA_       - Data tables stored in rom (eg. PI)
 - BASIC_COM_  - Lynx BASIC commands
 - BASIC_FN_   - Lynx BASIC functions/operators
 - MONITOR_    - Lynx MONITOR commands
 - VDU_        - VDU commands
 - SUB_        - internal subroutines used by ROM

