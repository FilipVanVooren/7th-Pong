*******************************************************************************
*              ___  ____  ____  ___  ____  ____    __    ___
*             / __)(  _ \( ___)/ __)(_  _)(  _ \  /__\  (__ \
*             \__ \ )___/ )__)( (__   )(   )   / /(__)\  / _/
*             (___/(__)  (____)\___) (__) (_)\_)(__)(__)(____)
*
*                 TMS9900 Monitor & Arcade Game Library
*                                for
*                   the Texas Instruments TI-99/4A
*
*                    2010-2018 by Filip Van Vooren
*
*              https://github.com/FilipVanVooren/spectra2.git
*******************************************************************************
* Credits
*     1) Speech code based on version of Mark Wills
*     2) Number conversion based on work of Mathew Hagerty
*     3) Bold font style based on work of sometimes99er
*******************************************************************************
* This file: runlib.a99
*******************************************************************************
* NOTE
* 14-03-2018    bit 10 CONFIG register reserved for alpha lock key down!
*               But code in VIRKB buggy and disabled for now
* 25-03-2018    LDFNT routine is not using tmp3. Tighten registers useful?
*******************************************************************************
* v1.2    2018/03   Work-in-Progress
*         Bug-fix   Virtual keyboard was missing keys for player 2. Resolved
*                   by adding "O" (p2 up), "," (p2 down), "K" (p2 left) and
*                   "L" (p2 right)
*         Change    Refactored GROM memory code into modules.
*                   Removed dependency of GROM module in LDFNT routine.
*                   Refactored library startup code to reduce code dependencies.
*         Bug-fix   Fixed bug in Speech Synthesizer detection (spconn)
*         Change    Reworked speech player routine (spplay). 
*                   Removed resident speech check. Only support speek external
*                   Removed parameter P1 in (spprep) routine.
*         New       Use constants embedded in OS ROM for reduced code size and
*                   faster (16 bit) memory access.
*         New       Introduced equates for skipping subroutines, allowing
*                   you to reduce code size.
*         Change    Repurpose bit 12 in CONFIG register from "keyboard mode" to
*                   "VDP9918 sprite collision" detected. 
*                   This is a crucial change.
*                   Bit 12 in CONFIG is set if C bit in VDP status register is
*                   on. The important thing is that bit 12 is latched even
*                   if C bit in VDP status register is reset (due to reading
*                   VDP status register). You need to clear bit 12 manually
*                   in your sprite collision routine. 
*         Change    Removed TI-99/4 check upon initialisation for saving
*                   on code size/GROM support..
*         New       Start breaking the monolith, use modules that can
*                   be included when needed only. Major refactoring
*         New       Added CLHOOK broutine
*         Bug-fix   Fixed low-level VDP routines because of wrong VDP bits set.
*         Change    Removed use of config bit 1 in MKHEX subroutine and
*                   got rid of multiple colors possibility. 
*         Change    Removed OS v2.2 check (config bit 10) and repurpose bit 5.
*                   Check if speech synthesizer present upon startup.
*         New       Check if F18A present upon startup (config bit 1)
*         Change    Repurpose bit 1 in CONFIG register from "subroutine state
*                   flag 1" to "F18A present flag"
*         Change    Converted source from upper case to lower case 
*         New       F18A support routines (detect, 80 cols, ...)
*         Bug-fix   Removed 6 years-old bug!
*                   Overflow in calculation of X in YX2PNT routine
*                   resulted in wrong VDP target address.
*------------------------------------------------------------------------------
* v1.1    2011/05   This version was never officially released
*                   but contains many changes and some new functions.
*         Bug-fix   by TREV2005. Fixed YX2PYX register issue
*         Change    Introduced memory location @WCOLMN and rewrote YX2PNT
*                   for using MPY instruction.
*                   Adjusted format of video mode table to include number
*                   of columns per row.
*                   VIDTAB subroutine adjusted as well.
*         Change    Removed subroutine GTCLMN. The functionality is replaced
*                   by the @WCOLMN memory location.
*         New       Added subroutine SCRDIM for setting base and
*                   width of a virtual screen.
*         Change    Introduced memory locations WAUX1,WAUX2,WAUX3.
*         Change    PUTBOX completely rewritten, now supports repeating
*                   vertically and/or horizontally.
*                   This is how its supposed to work from day one..
*                   WARNING PUTBOX is not compatible with V1.
*                   width & height swapped in P1.
*         Change    Removed memory location WSEED.
*                   On startup value is in WAUX1.
*                   Added parameter P1 to RND subroutine (address random seed)
*         Change    Modified FILBOX subroutine. Width and height swapped
*                   in P1 so that it's the same as for PUTBOX subroutine.
*         New       Added VIEW subroutine. This is a viewport into
*                   a virtual screen.
*         New       Added RLE2V subroutine.
*                   Decompress RLE (Run Length Encoded data) to VRAM.
*------------------------------------------------------------------------------
* v1.0    2011/02   Initial version
*******************************************************************************
* Use following equates to skip/exclude support modules
*
* skip_rom_bankswitch       equ  1       ; Skip support for ROM bankswitching
* skip_vram_cpu_copy        equ  1       ; Skip VRAM to CPU copy functions
* skip_cpu_vram_copy        equ  1       ; Skip CPU  to VRAM copy functions
* skip_cpu_cpu_copy         equ  1       ; Skip CPU  to CPU copy functions
* skip_grom_cpu_copy        equ  1       ; Skip GROM to CPU copy functions
* skip_grom_vram_copy       equ  1       ; Skip GROM to VRAM copy functions
* skip_textmode_support     equ  1       ; Skip 40x24 textmode support
* skip_f18a_support         equ  1       ; Skip f18a support
* skip_vdp_hchar            equ  1       ; Skip hchar, xchar
* skip_vdp_vchar            equ  1       ; Skip vchar, xvchar
* skip_vdp_boxes            equ  1       ; Skip filbox, putbox
* skip_vdp_hexsupport       equ  1       ; Skip mkhex, puthex
* skip_vdp_bitmap           equ  1       ; Skip bitmap functions
* skip_vdp_intscr           equ  1       ; Skip interrupt+screen on/off
* skip_vdp_viewport         equ  1       ; Skip viewport functions
* skip_vdp_rle_decompress   equ  1       ; Skip RLE decompress to VRAM
* skip_vdp_yx2px_calc       equ  1       ; Skip YX to pixel calculation
* skip_vdp_px2yx_calc       equ  1       ; Skip pixel to YX calculation
* skip_tms52xx_detection    equ  1       ; Skip speech synthesizer detection
* skip_keyboard_real        equ  1       ; Skip real keyboard support
* skip_random_generator     equ  1       ; Skip random functions
* use_osrom_constants       equ  1       ; Take constants from TI-99/4A OS ROM
*******************************************************************************



*//////////////////////////////////////////////////////////////
*                       RUNLIB MEMORY SETUP
*//////////////////////////////////////////////////////////////

***************************************************************
* >8300 - >8341     Scratchpad memory layout (66 bytes)
********@*****@*********************@**************************
ws1     equ   >8300                 ; 32 - Primary workspace
mcloop  equ   >8320                 ; 08 - Machine code for loop & speech
wbase   equ   >8328                 ; 02 - PNT base address
wyx     equ   >832a                 ; 02 - Cursor YX position
wtitab  equ   >832c                 ; 02 - Timers: Address of timer table
wtiusr  equ   >832e                 ; 02 - Timers: Address of user hook
wtitmp  equ   >8330                 ; 02 - Timers: Internal use
wvrtkb  equ   >8332                 ; 02 - Virtual keyboard flags
wsdlst  equ   >8334                 ; 02 - Sound player: Tune address
wsdtmp  equ   >8336                 ; 02 - Sound player: Temporary use
wspeak  equ   >8338                 ; 02 - Speech player: Address of LPC data
wcolmn  equ   >833a                 ; 02 - Screen size, columns per row
waux1   equ   >833c                 ; 02 - Temporary storage 1
waux2   equ   >833e                 ; 02 - Temporary storage 2
waux3   equ   >8340                 ; 02 - Temporary storage 3
***************************************************************
by      equ   wyx                   ;      Cursor Y position
bx      equ   wyx+1                 ;      Cursor X position
mcsprd  equ   mcloop+2              ;      Speech read routine
***************************************************************
* Register usage
* R0-R3   General purpose registers
* R4-R8   Temporary registers
* R9      Stack pointer
* R10     Highest slot in use + Timer counter
* R11     Subroutine return address
* R12     Configuration register
* R13     Copy of VDP status byte and counter for sound player
* R14     Copy of VDP register #0 and VDP register #1 bytes
* R15     VDP read/write address
***************************************************************
* Workspace and register equates
********@*****@*********************@**************************
r0      equ   0
r1      equ   1
r2      equ   2
r3      equ   3
r4      equ   4
r5      equ   5
r6      equ   6
r7      equ   7
r8      equ   8
r9      equ   9
r10     equ   10
r11     equ   11
r12     equ   12
r13     equ   13
r14     equ   14
r15     equ   15
r0hb    equ   ws1                   ; HI byte R0
r0lb    equ   ws1+1                 ; LO byte R0
r1hb    equ   ws1+2                 ; HI byte R1
r1lb    equ   ws1+3                 ; LO byte R1
r2hb    equ   ws1+4                 ; HI byte R2
r2lb    equ   ws1+5                 ; LO byte R2
r3hb    equ   ws1+6                 ; HI byte R3
r3lb    equ   ws1+7                 ; LO byte R3
r4hb    equ   ws1+8                 ; HI byte R4
r4lb    equ   ws1+9                 ; LO byte R4
r5hb    equ   ws1+10                ; HI byte R5
r5lb    equ   ws1+11                ; LO byte R5
r6hb    equ   ws1+12                ; HI byte R6
r6lb    equ   ws1+13                ; LO byte R6
r7hb    equ   ws1+14                ; HI byte R7
r7lb    equ   ws1+15                ; LO byte R7
r8hb    equ   ws1+16                ; HI byte R8
r8lb    equ   ws1+17                ; LO byte R8
r9hb    equ   ws1+18                ; HI byte R9
r9lb    equ   ws1+19                ; LO byte R9
r10hb   equ   ws1+20                ; HI byte R10
r10lb   equ   ws1+21                ; LO byte R10
r11hb   equ   ws1+22                ; HI byte R11
r11lb   equ   ws1+23                ; LO byte R11
r12hb   equ   ws1+24                ; HI byte R12
r12lb   equ   ws1+25                ; LO byte R12
r13hb   equ   ws1+26                ; HI byte R13
r13lb   equ   ws1+27                ; LO byte R13
r14hb   equ   ws1+28                ; HI byte R14
r14lb   equ   ws1+29                ; LO byte R14
r15hb   equ   ws1+30                ; HI byte R15
r15lb   equ   ws1+31                ; LO byte R15
tmp0    equ   r4                    ; Temp register 0
tmp1    equ   r5                    ; Temp register 1
tmp2    equ   r6                    ; Temp register 2
tmp3    equ   r7                    ; Temp register 3
tmp4    equ   r8                    ; Temp register 4
tmp5    equ   r9                    ; Temp register 5
tmp6    equ   r15                   ; Temp register 6
tmp0hb  equ   ws1+8                 ; HI byte R4
tmp0lb  equ   ws1+9                 ; LO byte R4
tmp1hb  equ   ws1+10                ; HI byte R5
tmp1lb  equ   ws1+11                ; LO byte R5
tmp2hb  equ   ws1+12                ; HI byte R6
tmp2lb  equ   ws1+13                ; LO byte R6
tmp3hb  equ   ws1+14                ; HI byte R7
tmp3lb  equ   ws1+15                ; LO byte R7
tmp4hb  equ   ws1+16                ; HI byte R8
tmp4lb  equ   ws1+17                ; LO byte R8
tmp5hb  equ   ws1+16                ; HI byte R8
tmp5lb  equ   ws1+17                ; LO byte R8
tmp6hb  equ   ws1+30                ; HI byte R15
tmp6lb  equ   ws1+31                ; LO byte R15
***************************************************************
* Equates for VDP, GROM, SOUND, SPEECH ports
********@*****@*********************@**************************
sound   equ   >8400                 ; Sound generator address
vdpr    equ   >8800                 ; VDP read data window address
vdpw    equ   >8c00                 ; VDP write data window address
vdps    equ   >8802                 ; VDP status register
vdpa    equ   >8c02                 ; VDP address register
grmwa   equ   >9c02                 ; GROM set write address
grmra   equ   >9802                 ; GROM set read address
grmrd   equ   >9800                 ; GROM read byte
grmwd   equ   >9c00                 ; GROM write byte
spchrd  equ   >9000                 ; Address of speech synth Read Data Register
spchwt  equ   >9400                 ; Address of speech synth Write Data Register
***************************************************************
* Equates for registers
********@*****@*********************@**************************
stack   equ   r9                    ; Stack pointer
btihi   equ   ws1+20                ; Highest slot in use (HI byte R10)
config  equ   r12                   ; SPECTRA configuration register
bvdpst  equ   ws1+26                ; Copy of VDP status register (HI byte R13)
vdpr01  equ   r14                   ; Copy of VDP#0 and VDP#1 bytes
vdpr0   equ   ws1+28                ; High byte of R14. Is VDP#0 byte
vdpr1   equ   ws1+29                ; Low byte  of R14. Is VDP#1 byte
vdprw   equ   r15                   ; Contains VDP read/write address
***************************************************************
* Equates for memory locations
********@*****@*********************@**************************
wramf   equ   >832e                 ; Memory location F
wramk   equ   >8338                 ; Memory location K
wraml   equ   >833a                 ; Memory location L
***************************************************************
* The config register equates
*--------------------------------------------------------------
* Configuration flags
* ===================
*
* ; 15  Sound player: tune source       1=ROM/RAM      0=VDP MEMORY
* ; 14  Sound player: repeat tune       1=yes          0=no
* ; 13  Sound player: enabled           1=yes          0=no (or pause)
* ; 12  VDP9918 sprite collision?       1=yes          0=no
* ; 11  Keyboard: ANY key pressed       1=yes          0=no
* ; 10  Keyboard: Alpha lock key down   1=yes          0=no
* ; 09  Timer: Kernel thread enabled    1=yes          0=no
* ; 08  Timer: Block kernel thread      1=yes          0=no
* ; 07  Timer: User hook enabled        1=yes          0=no
* ; 06  Timer: Block user hook          1=yes          0=no
* ; 05  Speech synthesizer present      1=yes          0=no
* ; 04  Speech player: busy             1=yes          0=no
* ; 03  Speech player: enabled          1=yes          0=no
* ; 02  VDP9918 PAL version             1=yes(50)      0=no(60)
* ; 01  F18A present                    1=on           0=off
* ; 00  Subroutine state flag           1=on           0=off
********@*****@*********************@**************************
palon   equ   >2000                 ; bit 2=1   (VDP9918 PAL version)
enusr   equ   >0100                 ; bit 7=1   (Enable user hook)
enknl   equ   >0040                 ; bit 9=1   (Enable kernel thread)
tms5200 equ   >0020                 ; bit 10=1  (Speech Synthesizer present)
***************************************************************
* Subroutine parameter equates
***************************************************************
eol     equ   >ffff                 ; End-Of-List
nofont  equ   >ffff                 ; Skip loading font in RUNLIB
norep   equ   0                     ; PUTBOX > Value for P3. Don't repeat box
num1    equ   >3030                 ; MKNUM  > ASCII 0-9, leading 0's
num2    equ   >3020                 ; MKNUM  > ASCII 0-9, leading spaces
sdopt1  equ   7                     ; SDPLAY > 111 (Player on, repeat, tune in CPU memory)
sdopt2  equ   5                     ; SDPLAY > 101 (Player on, no repeat, tune in CPU memory)
sdopt3  equ   6                     ; SDPLAY > 110 (Player on, repeat, tune in VRAM)
sdopt4  equ   4                     ; SDPLAY > 100 (Player on, no repeat, tune in VRAM)
fnopt1  equ   >0000                 ; LDFNT  > Load TI title screen font
fnopt2  equ   >0006                 ; LDFNT  > Load upper case font
fnopt3  equ   >000c                 ; LDFNT  > Load upper/lower case font
fnopt4  equ   >0012                 ; LDFNT  > Load lower case font
fnopt5  equ   >8000                 ; LDFNT  > Load TI title screen font  & bold
fnopt6  equ   >8006                 ; LDFNT  > Load upper case font       & bold
fnopt7  equ   >800c                 ; LDFNT  > Load upper/lower case font & bold
fnopt8  equ   >8012                 ; LDFNT  > Load lower case font       & bold
*--------------------------------------------------------------
*   Speech player
*--------------------------------------------------------------
talkon  equ   >60                   ; 'start talking' command code for speech synth
talkof  equ   >ff                   ; 'stop talking' command code for speech synth
spkon   equ   >6000                 ; 'start talking' command code for speech synth
spkoff  equ   >ff00                 ; 'stop talking' command code for speech synth
***************************************************************
* Virtual keyboard equates
***************************************************************
* bit  0: ALPHA LOCK down             0=no  1=yes
* bit  1: ENTER                       0=no  1=yes
* bit  2: REDO                        0=no  1=yes
* bit  3: BACK                        0=no  1=yes
* bit  4: Pause                       0=no  1=yes
* bit  5: *free*                      0=no  1=yes
* bit  6: P1 Left                     0=no  1=yes
* bit  7: P1 Right                    0=no  1=yes
* bit  8: P1 Up                       0=no  1=yes
* bit  9: P1 Down                     0=no  1=yes
* bit 10: P1 Space / fire / Q         0=no  1=yes
* bit 11: P2 Left                     0=no  1=yes
* bit 12: P2 Right                    0=no  1=yes
* bit 13: P2 Up                       0=no  1=yes
* bit 14: P2 Down                     0=no  1=yes
* bit 15: P2 Space / fire / Q         0=no  1=yes
***************************************************************
kalpha  equ   >8000                 ; Virtual key alpha lock
kenter  equ   >4000                 ; Virtual key enter
kredo   equ   >2000                 ; Virtual key REDO
kback   equ   >1000                 ; Virtual key BACK
kpause  equ   >0800                 ; Virtual key pause
kfree   equ   >0400                 ; ***NOT USED YET***
*--------------------------------------------------------------
* Keyboard Player 1
*--------------------------------------------------------------
k1uplf  equ   >0280                 ; Virtual key up   + left
k1uprg  equ   >0180                 ; Virtual key up   + right
k1dnlf  equ   >0240                 ; Virtual key down + left
k1dnrg  equ   >0140                 ; Virtual key down + right
k1lf    equ   >0200                 ; Virtual key left
k1rg    equ   >0100                 ; Virtual key right
k1up    equ   >0080                 ; Virtual key up
k1dn    equ   >0040                 ; Virtual key down
k1fire  equ   >0020                 ; Virtual key fire
*--------------------------------------------------------------
* Keyboard Player 2
*--------------------------------------------------------------
k2uplf  equ   >0014                 ; Virtual key up   + left
k2uprg  equ   >000c                 ; Virtual key up   + right
k2dnlf  equ   >0012                 ; Virtual key down + left
k2dnrg  equ   >000a                 ; Virtual key down + right
k2lf    equ   >0010                 ; Virtual key left
k2rg    equ   >0008                 ; Virtual key right
k2up    equ   >0004                 ; Virtual key up
k2dn    equ   >0002                 ; Virtual key down
k2fire  equ   >0001                 ; Virtual key fire
        even


***************************************************************
* Bank switch routine
***************************************************************
    .ifndef skip_rom_bankswitch
        copy  "rom_bankswitch.asm" 
    .endif


***************************************************************
*                      Some constants
********@*****@*********************@************************** 
    .ifdef use_osrom_constants
wbit0   equ   >06a6                 ; data >8000  Binary 1000000000000000
wbit1   equ   >023c                 ; data >4000  Binary 0100000000000000
wbit2   data  >2000                 ; data >2000  Binary 0010000000000000
wbit3   equ   >0036                 ; data >1000  Binary 0001000000000000
wbit4   equ   >08c6                 ; data >0800  Binary 0000100000000000
wbit5   equ   >0694                 ; data >0400  Binary 0000010000000000
wbit6   equ   >0030                 ; data >0200  Binary 0000001000000000
wbit7   equ   >002a                 ; data >0100  Binary 0000000100000000
wbit8   equ   >06b0                 ; data >0080  Binary 0000000010000000
wbit9   equ   >101e                 ; data >0040  Binary 0000000001000000
wbit10  equ   >0032                 ; data >0020  Binary 0000000000100000
wbit11  data  >0010                 ; data >0010  Binary 0000000000010000
wbit12  equ   >0012                 ; data >0008  Binary 0000000000001000
wbit13  data  >0004                 ; data >0004  Binary 0000000000000100
wbit14  data  >0002                 ; data >0002  Binary 0000000000000010
wbit15  equ   >0378                 ; data >0001  Binary 0000000000000001
whffff  equ   >0e2c                 ; data >ffff  Binary 1111111111111111
bd0     equ   >0002                 ; byte  0     Digit 0
bd1     equ   >002a                 ; byte  1     Digit 1
bd2     equ   >002c                 ; byte  2     Digit 2
bd3     equ   >003e                 ; byte  3     Digit 3
bd4     equ   >000e                 ; byte  4     Digit 4
bd5     equ   >007b                 ; byte  5     Digit 5
bd6     equ   >004e                 ; byte  6     Digit 6
bd7     equ   >0090                 ; byte  7     Digit 7
bd8     equ   >0013                 ; byte  8     Digit 8
bd9     equ   >0006                 ; byte  9     Digit 9
bd208   equ   >00a6                 ; byte  208   Digit 208 (>D0)
    .else
wbit0   data  >8000                 ; Binary 1000000000000000
wbit1   data  >4000                 ; Binary 0100000000000000
wbit2   data  >2000                 ; Binary 0010000000000000
wbit3   data  >1000                 ; Binary 0001000000000000
wbit4   data  >0800                 ; Binary 0000100000000000
wbit5   data  >0400                 ; Binary 0000010000000000
wbit6   data  >0200                 ; Binary 0000001000000000
wbit7   data  >0100                 ; Binary 0000000100000000
wbit8   data  >0080                 ; Binary 0000000010000000
wbit9   data  >0040                 ; Binary 0000000001000000
wbit10  data  >0020                 ; Binary 0000000000100000
wbit11  data  >0010                 ; Binary 0000000000010000
wbit12  data  >0008                 ; Binary 0000000000001000
wbit13  data  >0004                 ; Binary 0000000000000100
wbit14  data  >0002                 ; Binary 0000000000000010
wbit15  data  >0001                 ; Binary 0000000000000001
whffff  data  >ffff                 ; Binary 1111111111111111
bd0     byte  0                     ; Digit 0
bd1     byte  1                     ; Digit 1
bd2     byte  2                     ; Digit 2
bd3     byte  3                     ; Digit 3
bd4     byte  4                     ; Digit 4
bd5     byte  5                     ; Digit 5
bd6     byte  6                     ; Digit 6
bd7     byte  7                     ; Digit 7
bd8     byte  8                     ; Digit 8
bd9     byte  9                     ; Digit 9
bd208   byte  208                   ; Digit 208 (>D0)
        even
    .endif
*--------------------------------------------------------------
* Equates for constants
*--------------------------------------------------------------
anykey  equ   wbit11                ; BIT 11 in the CONFIG register
bbit0   equ   wbit0
bbit1   equ   wbit1
bbit2   equ   wbit2
bbit3   equ   wbit3
bbit4   equ   wbit4
bbit5   equ   wbit5
bbit6   equ   wbit6
bbit7   equ   wbit7
bh10    equ   wbit11+1              ; >10
bh20    equ   wbit10+1              ; >20
bh40    equ   wbit9+1               ; >40
bh80    equ   wbit8+1               ; >80
wd1     equ   wbit15                ; >0001
wh20    equ   wbit10                ; >0020
wh40    equ   wbit9                 ; >0040
wh80    equ   wbit8                 ; >0080
wh100   equ   wbit7                 ; >0100
wh4000  equ   wbit1                 ; >4000


***************************************************************
*                Data used by runtime library
********@*****@*********************@**************************
        copy  "vdp_tables.asm"  

*--------------------------------------------------------------
* ; Machine code for tight loop.
* ; The MOV operation at MCLOOP must be injected by the calling routine.
*--------------------------------------------------------------
*       DATA  >????                 ; \ MCLOOP  MOV   ...
mccode  data  >0606                 ; |         DEC   R6 (TMP2)
        data  >16fd                 ; |         JNE   MCLOOP
        data  >045b                 ; /         B     *R11
*--------------------------------------------------------------
* ; Machine code for reading from the speech synthesizer
* ; The SRC instruction takes 12 uS for execution in scratchpad RAM.
* ; Is required for the 12 uS delay. It destroys R5.
*--------------------------------------------------------------
spcode  data  >d114                 ; \         MOVB  *R4,R4 (TMP0)
        data  >0bc5                 ; /         SRC   R5,12  (TMP1)
        even


*//////////////////////////////////////////////////////////////
*                     FILL & COPY FUNCTIONS
*//////////////////////////////////////////////////////////////


***************************************************************
* FILM - Fill CPU memory with byte
***************************************************************
*  BL   @FILM
*  DATA P0,P1,P2
*--------------------------------------------------------------
*  P0 = Memory start address
*  P1 = Byte to fill
*  P2 = Number of bytes to fill
*--------------------------------------------------------------
*  BL   @XFILM
*
*  TMP0 = Memory start address
*  TMP1 = Byte to fill
*  TMP2 = Number of bytes to fill
********@*****@*********************@**************************
film    mov   *r11+,tmp0            ; Memory start
        mov   *r11+,tmp1            ; Byte to fill
        mov   *r11+,tmp2            ; Repeat count
*--------------------------------------------------------------
* Fill memory with 16 bit words
*--------------------------------------------------------------
xfilm   mov   tmp2,tmp3
        andi  tmp3,1                ; TMP3=1 -> ODD else EVEN

        jeq   film1
        dec   tmp2                  ; Make TMP2 even
film1   movb  @tmp1lb,@tmp1hb       ; Duplicate value
film2   mov   tmp1,*tmp0+
        dect  tmp2
        jne   film2
*--------------------------------------------------------------
* Fill last byte if ODD
*--------------------------------------------------------------
        mov   tmp3,tmp3
        jeq   filmz
        movb  tmp1,*tmp0
filmz   b     *r11


***************************************************************
* FILV - Fill VRAM with byte
***************************************************************
*  BL   @FILV
*  DATA P0,P1,P2
*--------------------------------------------------------------
*  P0 = VDP start address
*  P1 = Byte to fill
*  P2 = Number of bytes to fill
*--------------------------------------------------------------
*  BL   @XFILV
*
*  TMP0 = VDP start address
*  TMP1 = Byte to fill
*  TMP2 = Number of bytes to fill
********@*****@*********************@**************************
filv    mov   *r11+,tmp0            ; Memory start
        mov   *r11+,tmp1            ; Byte to fill
        mov   *r11+,tmp2            ; Repeat count
*--------------------------------------------------------------
*    Setup VDP write address
*--------------------------------------------------------------
xfilv   ori   tmp0,>4000
        swpb  tmp0
        movb  tmp0,@vdpa
        swpb  tmp0
        movb  tmp0,@vdpa
*--------------------------------------------------------------
*    Fill bytes in VDP memory
*--------------------------------------------------------------
        li    r15,vdpw              ; Set VDP write address
        swpb  tmp1
        mov   @filzz,@mcloop        ; Setup move command
        b     @mcloop               ; Write data to VDP
*--------------------------------------------------------------
    .ifdef use_osrom_constants
filzz   equ   >1624                 ; ^data >d7c5 (MOVB TMP1,*R15)
    .else
filzz   data  >d7c5                 ; MOVB TMP1,*R15
    .endif 


*//////////////////////////////////////////////////////////////
*                  CPU to VRAM copy functions
*//////////////////////////////////////////////////////////////
    .ifndef skip_cpu_vram_copy
        copy  "cpu_vram_copy.asm" 
    .endif


*//////////////////////////////////////////////////////////////
*                  VRAM to CPU copy functions
*//////////////////////////////////////////////////////////////
    .ifndef skip_vram_cpu_copy
        copy  "vram_cpu_copy.asm" 
    .endif


*//////////////////////////////////////////////////////////////
*                  CPU to CPU copy functions
*//////////////////////////////////////////////////////////////
    .ifndef skip_cpu_cpu_copy
        copy  "cpu_cpu_copy.asm" 
    .endif


*//////////////////////////////////////////////////////////////
*                GROM to CPU copy functions
*//////////////////////////////////////////////////////////////
    .ifndef skip_grom_cpu_copy
        copy  "grom_cpu_copy.asm" 
    .endif

*//////////////////////////////////////////////////////////////
*                GROM to VRAM copy functions 
*//////////////////////////////////////////////////////////////
    .ifndef skip_grom_vram_copy
        copy  "grom_vram_copy.asm" 
    .endif


*//////////////////////////////////////////////////////////////
*                  RLE decompress to VRAM
*//////////////////////////////////////////////////////////////
    .ifndef skip_vdp_rle_decompress
        copy  "vdp_rle_decompress.asm" 
    .endif


*//////////////////////////////////////////////////////////////
*                      VDP LOW LEVEL FUNCTIONS
*//////////////////////////////////////////////////////////////

***************************************************************
* VDWA / VDRA - Setup VDP write or read address
***************************************************************
*  BL   @VDWA
*
*  TMP0 = VDP destination address for write
*--------------------------------------------------------------
*  BL   @VDRA
*
*  TMP0 = VDP source address for read
********@*****@*********************@**************************
vdwa    ori   tmp0,>4000            ; Prepare VDP address for write
vdra    swpb  tmp0
        movb  tmp0,@vdpa
        swpb  tmp0
        movb  tmp0,@vdpa            ; Set VDP address
        b     *r11

***************************************************************
* VPUTB - VDP put single byte
***************************************************************
*  BL @VPUTB
*  DATA P0,P1
*--------------------------------------------------------------
*  P0 = VDP target address
*  P1 = Byte to write
********@*****@*********************@**************************
vputb   mov   *r11+,tmp0            ; Get VDP target address
        mov   *r11+,tmp1
xvputb  mov   r11,tmp2              ; Save R11
        bl    @vdwa                 ; Set VDP write address

        swpb  tmp1                  ; Get byte to write
        movb  tmp1,*r15             ; Write byte
        b     *tmp2                 ; Exit


***************************************************************
* VGETB - VDP get single byte
***************************************************************
*  BL @VGETB
*  DATA P0
*--------------------------------------------------------------
*  P0 = VDP source address
********@*****@*********************@**************************
vgetb   mov   *r11+,tmp0            ; Get VDP source address
xvgetb  mov   r11,tmp2              ; Save R11
        bl    @vdra                 ; Set VDP read address

        movb  @vdpr,tmp0            ; Read byte

        srl   tmp0,8                ; Right align
        b     *tmp2                 ; Exit

***************************************************************
* VIDTAB - Dump videomode table
***************************************************************
*  BL   @VIDTAB
*  DATA P0
*--------------------------------------------------------------
*  P0 = Address of video mode table
*--------------------------------------------------------------
*  BL   @XIDTAB
*
*  TMP0 = Address of video mode table
*--------------------------------------------------------------
*  Remarks
*  TMP1 = MSB is the VDP target register
*         LSB is the value to write
********@*****@*********************@**************************
vidtab  mov   *r11+,tmp0            ; Get video mode table
xidtab  mov   *tmp0,r14             ; Store copy of VDP#0 and #1 in RAM
*--------------------------------------------------------------
* Calculate PNT base address
*--------------------------------------------------------------
        mov   tmp0,tmp1
        inct  tmp1
        movb  *tmp1,tmp1            ; Get value for VDP#2
        andi  tmp1,>ff00            ; Only keep MSB
        sla   tmp1,2                ; TMP1 *= 400
        mov   tmp1,@wbase           ; Store calculated base
*--------------------------------------------------------------
* Dump VDP shadow registers
*--------------------------------------------------------------
        li    tmp1,>8000            ; Start with VDP register 0
        li    tmp2,8
vidta1  movb  *tmp0+,@tmp1lb        ; Write value to VDP register
        swpb  tmp1
        movb  tmp1,@vdpa
        swpb  tmp1
        movb  tmp1,@vdpa
        ai    tmp1,>0100
        dec   tmp2
        jne   vidta1                ; Next register
        mov   *tmp0,@wcolmn         ; Store # of columns per row
        b     *r11


***************************************************************
* PUTVR  - Put single VDP register
***************************************************************
*  BL   @PUTVR
*  DATA P0
*--------------------------------------------------------------
*  P0 = MSB is the VDP target register
*       LSB is the value to write
*--------------------------------------------------------------
*  BL   @PUTVRX
*
*  TMP0 = MSB is the VDP target register
*         LSB is the value to write
********@*****@*********************@**************************
putvr   mov   *r11+,tmp0
putvrx  ori   tmp0,>8000
        swpb  tmp0
        movb  tmp0,@vdpa
        swpb  tmp0
        movb  tmp0,@vdpa
        b     *r11

***************************************************************
* PUTV01  - Put VDP registers #0 and #1
***************************************************************
*  BL   @PUTV01
********@*****@*********************@**************************
putv01  mov   r11,tmp4              ; Save R11
        mov   r14,tmp0
        srl   tmp0,8
        bl    @putvrx               ; Write VR#0
        li    tmp0,>0100
        movb  @r14lb,@tmp0lb
        bl    @putvrx               ; Write VR#1
        b     *tmp4                 ; Exit

*//////////////////////////////////////////////////////////////
*            VDP interrupt & screen on/off
*//////////////////////////////////////////////////////////////
    .ifndef skip_vdp_intscr
        copy  "vdp_intscr.asm"
    .endif

***************************************************************
* SMAG1X - Set sprite magnification 1x
***************************************************************
*  BL @SMAG1X
********@*****@*********************@**************************
smag1x  andi  r14,>fffe             ; VDP#R1 bit 7=0 (Sprite magnification 1x)
        jmp   putv01

***************************************************************
* SMAG2X - Set sprite magnification 2x
***************************************************************
*  BL @SMAG2X
********@*****@*********************@**************************
smag2x  ori   r14,>0001             ; VDP#R1 bit 7=1 (Sprite magnification 2x)
        jmp   putv01

***************************************************************
* S8X8 - Set sprite size 8x8 bits
***************************************************************
*  BL @S8X8
********@*****@*********************@**************************
s8x8    andi  r14,>fffd             ; VDP#R1 bit 6=0 (Sprite size 8x8)
        jmp   putv01

***************************************************************
* S16X16 - Set sprite size 16x16 bits
***************************************************************
*  BL @S16X16
********@*****@*********************@**************************
s16x16  ori   r14,>0002             ; VDP#R1 bit 6=1 (Sprite size 16x16)
        jmp   putv01

***************************************************************
* YX2PNT - Get VDP PNT address for current YX cursor position
***************************************************************
*  BL   @YX2PNT
*--------------------------------------------------------------
*  INPUT
*  @WYX = Cursor YX position
*--------------------------------------------------------------
*  OUTPUT
*  TMP0 = VDP address for entry in Pattern Name Table
*--------------------------------------------------------------
*  Register usage
*  TMP0, R14, R15
********@*****@*********************@**************************
yx2pnt  mov   r14,tmp0              ; Save VDP#0 & VDP#1
        mov   @wyx,r14              ; Get YX
        srl   r14,8                 ; Right justify (remove X)
        mpy   @wcolmn,r14           ; pos = Y * (columns per row)
*--------------------------------------------------------------
* Do rest of calculation with R15 (16 bit part is there)
* Re-use R14
*--------------------------------------------------------------
        mov   @wyx,r14              ; Get YX
        andi  r14,>00ff             ; Remove Y
        a     r14,r15               ; pos = pos + X
        a     @wbase,r15            ; pos = pos + (PNT base address)
*--------------------------------------------------------------
* Clean up before exit
*--------------------------------------------------------------
        mov   tmp0,r14              ; Restore VDP#0 & VDP#1
        mov   r15,tmp0              ; Return pos in TMP0
        li    r15,vdpw              ; VDP write address
        b     *r11


*//////////////////////////////////////////////////////////////
*         VDP calculate pixel position for YX coordinate
*//////////////////////////////////////////////////////////////
    .ifndef skip_vdp_yx2px_calc
        copy  "vdp_yx2px_calc.asm"
    .endif

*//////////////////////////////////////////////////////////////
*         VDP calculate YX coordinate for pixel position
*//////////////////////////////////////////////////////////////
    .ifndef skip_vdp_px2yx_calc
        copy  "vdp_px2yx_calc.asm"
    .endif

*//////////////////////////////////////////////////////////////
*                    VDP BITMAP FUNCTIONS
*//////////////////////////////////////////////////////////////
    .ifdef skip_vdp_bitmap
    .else
        copy  "vdp_bitmap.asm"
    .endif

*//////////////////////////////////////////////////////////////
*                 VDP F18A LOW-LEVEL FUNCTIONS
*//////////////////////////////////////////////////////////////
    .ifdef skip_f18a_support
    .else
        copy  "f18a_support.asm"
    .endif

*//////////////////////////////////////////////////////////////
*                      VDP TILE FUNCTIONS
*//////////////////////////////////////////////////////////////

***************************************************************
* LDFNT - Load TI-99/4A font from GROM into VDP
***************************************************************
*  BL   @LDFNT
*  DATA P0,P1
*--------------------------------------------------------------
*  P0 = VDP Target address
*  P1 = Font options
********@*****@*********************@**************************
ldfnt   mov   r11,tmp4              ; Save R11
        inct  r11                   ; Get 2nd parameter (font options)
        mov   *r11,tmp0             ; Get P0
        andi  config,>7fff          ; CONFIG register bit 0=0
        coc   @wbit0,tmp0
        jne   ldfnt1
        ori   config,>8000          ; CONFIG register bit 0=1
        andi  tmp0,>7fff            ; Parameter value bit 0=0
*--------------------------------------------------------------
* Read font table address from GROM into tmp1
*--------------------------------------------------------------
ldfnt1  mov   @tmp006(tmp0),tmp0    ; Load GROM index address into tmp0
        movb  tmp0,@grmwa           ; Setup GROM source byte 1 for reading
        swpb  tmp0
        movb  tmp0,@grmwa           ; Setup GROM source byte 2 for reading
        movb  @grmrd,tmp1           ; Read font table address byte 1
        swpb  tmp1 
        movb  @grmrd,tmp1           ; Read font table address byte 2
        swpb  tmp1 
*--------------------------------------------------------------
* Setup GROM source address from tmp1
*--------------------------------------------------------------
        movb  tmp1,@grmwa
        swpb  tmp1
        movb  tmp1,@grmwa           ; Setup GROM address for reading
*--------------------------------------------------------------
* Setup VDP target address
*--------------------------------------------------------------
        mov   *tmp4,tmp0            ; Get P1 (VDP destination)
        bl    @vdwa                 ; Setup VDP destination address
        inct  tmp4                  ; R11=R11+2
        mov   *tmp4,tmp1            ; Get font options into TMP1
        andi  tmp1,>7fff            ; Parameter value bit 0=0
        mov   @tmp006+2(tmp1),tmp2  ; Get number of patterns to copy
        mov   @tmp006+4(tmp1),tmp1  ; 7 or 8 byte pattern ?
*--------------------------------------------------------------
* Copy from GROM to VRAM
*--------------------------------------------------------------
ldfnt2  src   tmp1,1                ; Carry set ?
        joc   ldfnt4                ; Yes, go insert a >00
        movb  @grmrd,tmp0
*--------------------------------------------------------------
*   Make font fat
*--------------------------------------------------------------
        coc   @wbit0,config         ; Fat flag set ?
        jne   ldfnt3                ; No, so skip
        movb  tmp0,tmp6
        srl   tmp6,1
        soc   tmp6,tmp0
*--------------------------------------------------------------
*   Dump byte to VDP and do housekeeping
*--------------------------------------------------------------
ldfnt3  movb  tmp0,@vdpw            ; Dump byte to VRAM
        dec   tmp2
        jne   ldfnt2
        inct  tmp4                  ; R11=R11+2
        li    r15,vdpw              ; Set VDP write address
        andi  config,>7fff          ; CONFIG register bit 0=0
        b     *tmp4                 ; Exit
ldfnt4  movb  @bd0,@vdpw            ; Insert byte >00 into VRAM
        jmp   ldfnt2
*--------------------------------------------------------------
* Fonts pointer table
*--------------------------------------------------------------
tmp006  data  >004c,64*8,>0000      ; Pointer to TI title screen font
        data  >004e,64*7,>0101      ; Pointer to upper case font
        data  >004e,96*7,>0101      ; Pointer to upper & lower case font
        data  >0050,32*7,>0101      ; Pointer to lower case font


***************************************************************
* Put length-byte prefixed string at current YX
***************************************************************
*  BL   @PUTSTR
*  DATA P0
*
*  P0 = Pointer to string
*--------------------------------------------------------------
*  REMARKS
*  First byte of string must contain length
********@*****@*********************@**************************
putstr  mov   *r11+,tmp1
xutst0  movb  *tmp1+,tmp2           ; Get length byte
xutstr  mov   r11,tmp3
        bl    @yx2pnt               ; Get VDP destination address
        mov   tmp3,r11
        srl   tmp2,8                ; Right justify length byte
        b     @xpym2v               ; Display string


***************************************************************
* Put length-byte prefixed string at YX
***************************************************************
*  BL   @PUTAT
*  DATA P0,P1
*
*  P0 = YX position
*  P1 = Pointer to string
*--------------------------------------------------------------
*  REMARKS
*  First byte of string must contain length
********@*****@*********************@**************************
putat   mov   *r11+,@wyx            ; Set YX position
        b     @putstr


*//////////////////////////////////////////////////////////////
*                   VDP hchar functions
*//////////////////////////////////////////////////////////////
    .ifndef skip_vdp_hchar
        copy  "vdp_hchar.asm" 
    .endif

*//////////////////////////////////////////////////////////////
*                   VDP vchar functions
*//////////////////////////////////////////////////////////////
    .ifndef skip_vdp_vchar
        copy  "vdp_vchar.asm" 
    .endif

*//////////////////////////////////////////////////////////////
*                    VDP box functions
*//////////////////////////////////////////////////////////////
    .ifndef skip_vdp_boxes
        copy  "vdp_boxes.asm" 
    .endif

*//////////////////////////////////////////////////////////////
*                VDP unsigned numbers support
*//////////////////////////////////////////////////////////////
    .ifndef skip_vdp_numsupport
        copy  "vdp_numsupport.asm" 
    .endif

*//////////////////////////////////////////////////////////////
*                 VDP hex numbers support
*//////////////////////////////////////////////////////////////
    .ifndef skip_vdp_hexsupport
        copy  "vdp_hexsupport.asm" 
    .endif

*//////////////////////////////////////////////////////////////
*                 VDP viewport functionality
*//////////////////////////////////////////////////////////////
    .ifndef skip_vdp_viewport
        copy  "vdp_viewport.asm" 
    .endif


*//////////////////////////////////////////////////////////////
*                            SOUND
*//////////////////////////////////////////////////////////////

***************************************************************
* MUTE - Mute all sound generators
***************************************************************
*  BL  @MUTE
*  Mute sound generators and clear sound pointer
*
*  BL  @MUTE2
*  Mute sound generators without clearing sound pointer
********@*****@*********************@**************************
mute    clr   @wsdlst               ; Clear sound pointer
mute2   szc   @wbit13,config        ; Turn off/pause sound player
        li    tmp0,muttab
        li    tmp1,sound            ; Sound generator port >8400
        movb  *tmp0+,*tmp1          ; Generator 0
        movb  *tmp0+,*tmp1          ; Generator 1
        movb  *tmp0+,*tmp1          ; Generator 2
        movb  *tmp0,*tmp1           ; Generator 3
        b     *r11
muttab  byte  >9f,>bf,>df,>ff       ; Table for muting all generators


***************************************************************
* SDPREP - Prepare for playing sound
***************************************************************
*  BL   @SDPREP
*  DATA P0,P1
*
*  P0 = Address where tune is stored
*  P1 = Option flags for sound player
*--------------------------------------------------------------
*  REMARKS
*  Use the below equates for P1:
*
*  SDOPT1 => Tune is in CPU memory + loop
*  SDOPT2 => Tune is in CPU memory
*  SDOPT3 => Tune is in VRAM + loop
*  SDOPT4 => Tune is in VRAM
********@*****@*********************@**************************
sdprep  mov   *r11,@wsdlst          ; Set tune address
        mov   *r11+,@wsdtmp         ; Set tune address in temp
        andi  r12,>fff8             ; Clear bits 13-14-15
        soc   *r11+,config          ; Set options
        movb  @bd1,@r13lb           ; Set initial duration
        b     *r11

***************************************************************
* SDPLAY - Sound player for tune in VRAM or CPU memory
***************************************************************
*  BL  @SDPLAY
*--------------------------------------------------------------
*  REMARKS
*  Set config register bit13=0 to pause player.
*  Set config register bit14=1 to repeat (or play next tune).
********@*****@*********************@**************************
sdplay  coc   @wbit13,config        ; Play tune ?
        jeq   sdpla1                ; Yes, play
        b     *r11
*--------------------------------------------------------------
* Initialisation
*--------------------------------------------------------------
sdpla1  dec   r13                   ; duration = duration - 1
        cb    @r13lb,@bd0           ; R13LB == 0 ?
        jeq   sdpla3                ; Play next note
sdpla2  b     *r11                  ; Note still busy, exit
sdpla3  coc   @wbit15,config        ; Play tune from CPU memory ?
        jeq   mmplay
*--------------------------------------------------------------
* Play tune from VDP memory
*--------------------------------------------------------------
vdplay  mov   @wsdtmp,tmp0          ; Get tune address
        swpb  tmp0
        movb  tmp0,@vdpa
        swpb  tmp0
        movb  tmp0,@vdpa
        clr   tmp0
        movb  @vdpr,tmp0            ; length = 0 (end of tune) ?
        jeq   sdexit                ; Yes. exit
vdpla1  srl   tmp0,8                ; Right justify length byte
        a     tmp0,@wsdtmp          ; Adjust for next table entry
vdpla2  movb  @vdpr,@>8400          ; Feed byte to sound generator
        dec   tmp0
        jne   vdpla2
        movb  @vdpr,@r13lb          ; Set duration counter
vdpla3  inct  @wsdtmp               ; Adjust for next table entry, honour byte (1) + (n+1)
        b     *r11
*--------------------------------------------------------------
* Play tune from CPU memory
*--------------------------------------------------------------
mmplay  mov   @wsdtmp,tmp0
        movb  *tmp0+,tmp1           ; length = 0 (end of tune) ?
        jeq   sdexit                ; Yes, exit
mmpla1  srl   tmp1,8                ; Right justify length byte
        a     tmp1,@wsdtmp          ; Adjust for next table entry
mmpla2  movb  *tmp0+,@>8400         ; Feed byte to sound generator
        dec   tmp1
        jne   mmpla2
        movb  *tmp0,@r13lb          ; Set duration counter
        inct  @wsdtmp               ; Adjust for next table entry, honour byte (1) + (n+1)
        b     *r11
*--------------------------------------------------------------
* Exit. Check if tune must be looped
*--------------------------------------------------------------
sdexit  coc   @wbit14,config        ; Loop flag set ?
        jne   sdexi2                ; No, exit
        mov   @wsdlst,@wsdtmp
        movb  @bd1,@r13lb           ; Set initial duration
sdexi1  b     *r11                  ; Exit
sdexi2  andi  config,>fff8          ; Reset music player
        b     *r11                  ; Exit


*//////////////////////////////////////////////////////////////
*                            SPEECH
*//////////////////////////////////////////////////////////////

***************************************************************
* SPSTAT - Read status register byte from speech synthesizer
***************************************************************
*  LI  TMP2,@>....
*  B   @SPSTAT
*--------------------------------------------------------------
* REMARKS
* Destroys R11 !
*
* Register usage
* TMP0HB = Status byte read from speech synth
* TMP1   = Temporary use  (scratchpad machine code)
* TMP2   = Return address for this subroutine
* R11    = Return address (scratchpad machine code)
********@*****@*********************@**************************
spstat  li    tmp0,spchrd           ; (R4) = >9000
        mov   @spcode,@mcsprd       ; \
        mov   @spcode+2,@mcsprd+2   ; / Load speech read code
        li    r11,spsta1            ; Return to SPSTA1
        b     @mcsprd               ; Run scratchpad code
spsta1  mov   @mccode,@mcsprd       ; \
        mov   @mccode+2,@mcsprd+2   ; / Restore tight loop code
        b     *tmp2                 ; Exit

*//////////////////////////////////////////////////////////////
*        TMS52xx - Check if speech synthesizer connected
*//////////////////////////////////////////////////////////////
    .ifndef skip_tms52xx_detection
        copy  "tms52xx_detect.asm" 
    .endif


***************************************************************
* SPPREP - Prepare for playing speech
***************************************************************
*  BL   @SPPREP
*  DATA P0
*
*  P0 = Address of LPC data for external voice.
********@*****@*********************@**************************
spprep  mov   *r11+,@wspeak         ; Set speech address
        soc   @wbit3,config         ; Clear bit 3
        b     *r11

***************************************************************
* SPPLAY - Speech player
***************************************************************
* BL  @SPPLAY
*--------------------------------------------------------------
* Register usage
* TMP3   = Copy of R11
* R12    = CONFIG register
********@*****@*********************@**************************
spplay  czc   @wbit3,config         ; Player off ?
        jeq   spplaz                ; Yes, exit
sppla1  mov   r11,tmp3              ; Save R11
        coc   @tmp010,config        ; Speech player enabled+busy ?
        jeq   spkex3                ; Check FIFO buffer level
*--------------------------------------------------------------
* Speak external: Push LPC data to speech synthesizer
*--------------------------------------------------------------
spkext  mov   @wspeak,tmp0
        movb  *tmp0+,@spchwt        ; Send byte to speech synth
        jmp   $+2                   ; Delay
        li    tmp2,16
spkex1  movb  *tmp0+,@spchwt        ; Send byte to speech synth
        dec   tmp2
        jne   spkex1
        ori   config,>0800          ; bit 4=1 (busy)
        mov   tmp0,@wspeak          ; Update LPC pointer
        jmp   spplaz                ; Exit
*--------------------------------------------------------------
* Speak external: Check synth FIFO buffer level
*--------------------------------------------------------------
spkex3  li    tmp2,spkex4           ; Set return address for SPSTAT
        b     @spstat               ; Get speech FIFO buffer status
spkex4  coc   @wh4000,tmp0          ; FIFO BL (buffer low) bit set ?
        jeq   spkex5                ; Yes, refill
        jmp   spplaz                ; No, exit
*--------------------------------------------------------------
* Speak external: Refill synth with LPC data if FIFO buffer low
*--------------------------------------------------------------
spkex5  mov   @wspeak,tmp0
        li    tmp2,8                ; Bytes to send to speech synth
spkex6  movb  *tmp0+,tmp1
        movb  tmp1,@spchwt          ; Send byte to speech synth
        ci    tmp1,spkoff           ; Speak off marker found ?
        jeq   spkex8
        dec   tmp2
        jne   spkex6                ; Send next byte
        mov   tmp0,@wspeak          ; Update LPC pointer
spkex7  jmp   spplaz                ; Exit
*--------------------------------------------------------------
* Speak external: Done with speaking
*--------------------------------------------------------------
spkex8  szc   @tmp010,config        ; bit 3,4,5=0
        clr   @wspeak               ; Reset pointer
spplaz  b     *tmp3                 ; Exit
tmp010  data  >1800                 ; Binary 0001100000000000
                                    ; Bit    0123456789ABCDEF

*//////////////////////////////////////////////////////////////
*                           KEYBOARD
*//////////////////////////////////////////////////////////////


*//////////////////////////////////////////////////////////////
*             Keyboard support (virtual keyboard) 
*//////////////////////////////////////////////////////////////
        copy  "keyb_virtual.asm" 


*//////////////////////////////////////////////////////////////
*             Keyboard support (in real mode) 
*//////////////////////////////////////////////////////////////
    .ifndef skip_keyboard_real
        copy  "keyb_real.asm" 
    .endif


*//////////////////////////////////////////////////////////////
*                            TIMERS
*//////////////////////////////////////////////////////////////

***************************************************************
* TMGR - X - Start Timer/Thread scheduler
***************************************************************
*  B @TMGR
*--------------------------------------------------------------
*  REMARKS
*  Timer/Thread scheduler. Normally called from MAIN.
*  Don't forget to set BTIHI to highest slot in use.
*
*  Register usage in TMGR8 - TMGR11
*  TMP0  = Pointer to timer table
*  R10LB = Use as slot counter
*  TMP2  = 2nd word of slot data
*  TMP3  = Address of routine to call
********@*****@*********************@**************************
tmgr    limi  0                     ; No interrupt processing
*--------------------------------------------------------------
* Read VDP status register
*--------------------------------------------------------------
tmgr1   movb  @vdps,r13             ; Save copy of VDP status register in R13
*--------------------------------------------------------------
* Latch sprite collision flag
*--------------------------------------------------------------
        coc   @wbit2,r13            ; C flag on ?
        jne   tmgr1a                ; No, so move on
        soc   @wbit12,config        ; Latch bit 12 in config register
*--------------------------------------------------------------
* Interrupt flag
*--------------------------------------------------------------
tmgr1a  coc   @wbit0,r13            ; Interupt flag set ?
        jeq   tmgr4                 ; Yes, process slots 0..n
*--------------------------------------------------------------
* Run speech player
*--------------------------------------------------------------
        coc   @wbit3,config         ; Speech player on ?
        jne   tmgr2
        bl    @sppla1               ; Run speech player
*--------------------------------------------------------------
* Run kernel thread
*--------------------------------------------------------------
tmgr2   coc   @wbit8,config         ; Kernel thread blocked ?
        jeq   tmgr3                 ; Yes, skip to user hook
        coc   @wbit9,config         ; Kernel thread enabled ?
        jne   tmgr3                 ; No, skip to user hook
        b     @kernel               ; Run kernel thread
*--------------------------------------------------------------
* Run user hook
*--------------------------------------------------------------
tmgr3   coc   @wbit6,config         ; User hook blocked ?
        jeq   tmgr1
        coc   @wbit7,config         ; User hook enabled ?
        jne   tmgr1
        mov   @wtiusr,tmp0
        b     *tmp0                 ; Run user hook
*--------------------------------------------------------------
* Do some internal housekeeping
*--------------------------------------------------------------
tmgr4   szc   @tmdat,config         ; Unblock kernel thread and user hook
        mov   r10,tmp0
        andi  tmp0,>00ff            ; Clear HI byte
        coc   @wbit2,config         ; PAL flag set ?
        jeq   tmgr5
        ci    tmp0,60               ; 1 second reached ?
        jmp   tmgr6
tmgr5   ci    tmp0,50
tmgr6   jlt   tmgr7                 ; No, continue
        jmp   tmgr8
tmgr7   inc   r10                   ; Increase tick counter
*--------------------------------------------------------------
* Loop over slots
*--------------------------------------------------------------
tmgr8   mov   @wtitab,tmp0          ; Pointer to timer table
        andi  r10,>ff00             ; Use R10LB as slot counter. Reset.
tmgr9   mov   *tmp0,tmp3            ; Is slot empty ?
        jeq   tmgr11                ; Yes, get next slot
*--------------------------------------------------------------
*  Check if slot should be executed
*--------------------------------------------------------------
        inct  tmp0                  ; Second word of slot data
        inc   *tmp0                 ; Update tick count in slot
        mov   *tmp0,tmp2            ; Get second word of slot data
        cb    @tmp2hb,@tmp2lb       ; Slot target count = Slot internal counter ?
        jne   tmgr10                ; No, get next slot
        andi  tmp2,>ff00            ; Clear internal counter
        mov   tmp2,*tmp0            ; Update timer table
*--------------------------------------------------------------
*  Run slot, we only need TMP0 to survive
*--------------------------------------------------------------
        mov   tmp0,@wtitmp          ; Save TMP0
        bl    *tmp3                 ; Call routine in slot
slotok  mov   @wtitmp,tmp0          ; Restore TMP0

*--------------------------------------------------------------
*  Prepare for next slot
*--------------------------------------------------------------
tmgr10  inc   r10                   ; Next slot
        cb    @r10lb,@btihi         ; Last slot done ?
        jgt   tmgr12                ; yes, Wait for next VDP interrupt
        inct  tmp0                  ; Offset for next slot
        jmp   tmgr9                 ; Process next slot
tmgr11  inct  tmp0                  ; Skip 2nd word of slot data
        jmp   tmgr10                ; Process next slot
tmgr12  andi  r10,>ff00             ; Use R10LB as tick counter. Reset.
        jmp   tmgr1
tmdat   data  >0280                 ; Bit 8 (kernel thread) and bit 6 (user hook)


***************************************************************
* MKSLOT - Allocate timer slot(s)
***************************************************************
*  BL    @MKSLOT
*  BYTE  P0HB,P0LB
*  DATA  P1
*  ....
*  DATA  EOL                        ; End-of-list
*--------------------------------------------------------------
*  P0 = Slot number, target count
*  P1 = Subroutine to call via BL @xxxx if slot is fired
********@*****@*********************@**************************
mkslot  mov   *r11+,tmp0
        mov   *r11+,tmp1
*--------------------------------------------------------------
*  Calculate address of slot
*--------------------------------------------------------------
        mov   tmp0,tmp2
        srl   tmp2,6                ; Right align & TMP2 = TMP2 * 4
        a     @wtitab,tmp2          ; Add table base
*--------------------------------------------------------------
*  Add slot to table
*--------------------------------------------------------------
        mov   tmp1,*tmp2+           ; Store address of subroutine
        sla   tmp0,8                ; Get rid of slot number
        mov   tmp0,*tmp2            ; Store target count and reset tick count
*--------------------------------------------------------------
*  Check for end of list
*--------------------------------------------------------------
        c     *r11,@whffff          ; End of list ?
        jeq   mkslo1                ; Yes, exit
        jmp   mkslot                ; Process next entry
*--------------------------------------------------------------
*  Exit
*--------------------------------------------------------------
mkslo1  inct  r11
        b     *r11                  ; Exit


***************************************************************
* CLSLOT - Clear single timer slot
***************************************************************
*  BL    @CLSLOT
*  DATA  P0
*--------------------------------------------------------------
*  P0 = Slot number
********@*****@*********************@**************************
clslot  mov   *r11+,tmp0
xlslot  sla   tmp0,2                ; TMP0 = TMP0*4
        a     @wtitab,tmp0          ; Add table base
        clr   *tmp0+                ; Clear 1st word of slot
        clr   *tmp0                 ; Clear 2nd word of slot
        b     *r11                  ; Exit


***************************************************************
* KERNEL - The kernel thread
*--------------------------------------------------------------
*  REMARKS
*  You shouldn't call the kernel thread manually.
*  Instead control it via the CONFIG register.
********@*****@*********************@**************************
kernel  soc   @wbit8,config         ; Block kernel thread
        coc   @wbit13,config        ; Sound player on ?
        jne   kerne1
        bl    @sdpla1               ; Run sound player
kerne1  bl    @virtkb               ; Scan virtual keyboard
    .ifndef skip_keyboard_real
        coc   @wbit12,config        ; Keyboard mode real ?
        jne   kernez                ; No, exit
        bl    @realkb               ; Scan full keyboard
    .endif
kernez  b     @tmgr3                ; Exit



***************************************************************
* MKHOOK - Allocate user hook
***************************************************************
*  BL    @MKHOOK
*  DATA  P0
*--------------------------------------------------------------
*  P0 = Address of user hook
*--------------------------------------------------------------
*  REMARKS
*  The user hook gets executed after the kernel thread.
*  The user hook must always exit with "B @HOOKOK"
********@*****@*********************@**************************
mkhook  mov   *r11+,@wtiusr         ; Set user hook address
        ori   config,enusr          ; Enable user hook
mkhoo1  b     *r11                  ; Return
hookok  equ   tmgr1                 ; Exit point for user hook


***************************************************************
* CLHOOK - Clear user hook
***************************************************************
*  BL    @CLHOOK
********@*****@*********************@**************************
clhook  clr   @wtiusr               ; Unset user hook address
        andi  config,>feff          ; Disable user hook (bit 7=0)
        b     *r11                  ; Return


*//////////////////////////////////////////////////////////////
*                       MISC FUNCTIONS
*//////////////////////////////////////////////////////////////

***************************************************************
* POPR. - Pop registers & return to caller
***************************************************************
*  B  @POPRG.
*--------------------------------------------------------------
*  REMARKS
*  R11 must be at stack bottom
********@*****@*********************@**************************
popr3   mov   *stack+,r3
popr2   mov   *stack+,r2
popr1   mov   *stack+,r1
popr0   mov   *stack+,r0
poprt   mov   *stack+,r11
        b     *r11

*//////////////////////////////////////////////////////////////
*                    RANDOM GENERATOR 
*//////////////////////////////////////////////////////////////
    .ifndef skip_random_generator
        copy  "rnd_support.asm" 
    .endif


*//////////////////////////////////////////////////////////////
*                    RUNLIB INITIALISATION
*//////////////////////////////////////////////////////////////

***************************************************************
*  RUNLIB - Runtime library initalisation
***************************************************************
*  B  @RUNLIB
*--------------------------------------------------------------
*  REMARKS
*  If R1 in WS1 equals >FFFF we return to the TI title screen
*  after clearing scratchpad memory.
*  Use 'B @RUNLI1' to exit your program.
********@*****@*********************@**************************
runlib  clr   @>8302                ; Reset exit flag (R1 in workspace WS1!)
*--------------------------------------------------------------
* Alternative entry point
*--------------------------------------------------------------
runli1  limi  0                     ; Turn off interrupts
        lwpi  ws1                   ; Activate workspace 1
        mov   @>83c0,r3             ; Get random seed from OS monitor

*--------------------------------------------------------------
* Clear scratch-pad memory from R4 upwards
*--------------------------------------------------------------
runli2  li    r2,>8308
runli3  clr   *r2+                  ; Clear scratchpad >8306->83FF
        ci    r2,>8400
        jne   runli3
*--------------------------------------------------------------
* Exit to TI-99/4A title screen ?
*--------------------------------------------------------------
        ci    r1,>ffff              ; Exit flag set ?
        jne   runli4                ; No, continue
        blwp  @0                    ; Yes, bye bye
*--------------------------------------------------------------
* Determine if VDP is PAL or NTSC
*--------------------------------------------------------------
runli4  mov   r3,@waux1             ; Store random seed
        clr   r1                    ; Reset counter
        li    r2,10                 ; We test 10 times
runli5  mov   @vdps,r3
        coc   @wbit0,r3             ; Interupt flag set ?
        jeq   runli6
        inc   r1                    ; Increase counter
        jmp   runli5
runli6  dec   r2                    ; Next test
        jne   runli5
        ci    r1,>1250              ; Max for NTSC reached ?
        jle   runli7                ; No, so it must be NTSC
        ori   config,palon          ; Yes, it must be PAL, set flag
*--------------------------------------------------------------
* Copy machine code to scratchpad (prepare tight loop)
*--------------------------------------------------------------
runli7  li    r1,mccode             ; Machinecode to patch
        li    r2,mcloop+2           ; Scratch-pad reserved for machine code
        mov   *r1+,*r2+             ; Copy 1st instruction 
        mov   *r1+,*r2+             ; Copy 2nd instruction
        mov   *r1+,*r2+             ; Copy 3rd instruction
*--------------------------------------------------------------
* Initialize registers, memory, ...
*--------------------------------------------------------------
runli9  clr   r1
        clr   r2
        clr   r3
        li    stack,>8400           ; Set stack
        li    r15,vdpw              ; Set VDP write address
        bl    @mute                 ; Mute sound generators
*--------------------------------------------------------------
* Setup video memory
*--------------------------------------------------------------
        bl    @filv
        data  >0000,>00,16000       ; Clear VDP memory
        bl    @filv
        data  >0380,spfclr,16       ; Load color table
*--------------------------------------------------------------
* Check if there is a F18A present
*--------------------------------------------------------------
    .ifndef skip_f18a_support
        bl    @f18unl               ; Unlock the F18A
        bl    @f18chk               ; Check if F18A is there
        bl    @f18lck               ; Lock the F18A again
    .endif
*--------------------------------------------------------------
* Check if there is a speech synthesizer attached
*--------------------------------------------------------------
    .ifndef skip_tms52xx_detection
        bl    @spconn 
    .endif
*--------------------------------------------------------------
* Load video mode table & font
*--------------------------------------------------------------
runlic  bl    @vidtab               ; Load video mode table into VDP
        data  spvmod                ; Equate selected video mode table
        li    tmp0,spfont           ; Get font option
        inv   tmp0                  ; NOFONT (>FFFF) specified ?
        jeq   runlid                ; Yes, skip it
        bl    @ldfnt
        data  >0900,spfont          ; Load specified font
*--------------------------------------------------------------
* Branch to main program
*--------------------------------------------------------------
runlid  ori   config,enknl          ; Enable kernel thread
        b     @main                 ; Give control to main program
