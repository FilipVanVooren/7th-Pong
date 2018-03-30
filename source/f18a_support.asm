* FILE......: f18a_support.asm
* Purpose...: F18A Support module

*//////////////////////////////////////////////////////////////
*                 VDP F18A LOW-LEVEL FUNCTIONS
*//////////////////////////////////////////////////////////////

***************************************************************
* F18UNL - Unlock F18A VDP
***************************************************************
*  BL   @F18UNL
********@*****@*********************@**************************
f18unl  mov   r11,tmp4              ; Save R11
        bl    @putvr                ; Write once
        data  >391c                 ; VR1/57, value 00011100
        bl    @putvr                ; Write twice, unlock F18A
        data  >391c
        bl    @putvr                ; Write sane value
        data  >01e0                 ; VR1, value 11100000
        b     *tmp4                 ; Exit


***************************************************************
* F18LCK - Lock F18A VDP
***************************************************************
*  BL   @F18LCK
********@*****@*********************@**************************
f18lck  mov   r11,tmp4              ; Save R11 
        bl    @putvr                ; VR1/57, value 00011100
        data  >391c
        b     *tmp4                 ; Exit


***************************************************************
* F18CHK - Check if F18A VDP present
***************************************************************
*  BL   @F18CHK
*--------------------------------------------------------------
*  REMARKS
*  VDP memory >3f00->3f05 still has part of GPU code upon exit.
********@*****@*********************@**************************
f18chk  mov   r11,tmp4              ; Save R11
        bl    @cpym2v
        data  >3f00,f18gpu,6        ; Copy F18A GPU code to VRAM
        bl    @putvr
        data  >363f                 ; Load MSB of GPU PC (>3f) into VR54 (>36)
        bl    @putvr
        data  >3700                 ; Load LSB of GPU PC (>00) into VR55 (>37)
                                    ; GPU code should run now
***************************************************************
* VDP @>3f00 == 0 ? F18A present : F18a not present
***************************************************************        
        li    tmp0,>3f00
        bl    @vdra                 ; Set VDP read address to >3f00
        movb  @vdpr,tmp0            ; Read MSB byte
        srl   tmp0,8
        movb  @vdpr,tmp0            ; Read LSB byte
        mov   tmp0,tmp0             ; For comparing with 0
        jeq   f18yes
f18no   andi  config,>bfff          ; CONFIG Register bit 1=0 
        jmp   f18exi               
f18yes  ori   config,>4000          ; CONFIG Register bit 1=1
f18exi  bl    @filv                 ; Clear VDP mem >3f00->3f07
        data  >3f00,>00,6 
        b     *tmp4                 ; Exit
***************************************************************
* GPU code
********@*****@*********************@**************************
f18gpu  data  >04e0                 ; 3f00 \ 04e0  clr @>3f00
        data  >3f00                 ; 3f02 / 3f00
        data  >0340                 ; 3f04   0340  idle



***************************************************************
* F18FWV - Get F18A Firmware Version
***************************************************************
*  BL   @F18FWV
*--------------------------------------------------------------
*  REMARKS
*  Successfully tested with F18A v1.8, note that this does not
*  work with F18 v1.3 but you shouldn't be using such old F18A
*  firmware to begin with. 
*--------------------------------------------------------------
*  TMP0 High nibble = major version
*  TMP0 Low nibble  = minor version
*
*  Example: >0018     F18a Firmware v1.8
********@*****@*********************@**************************
f18fwv  mov   r11,tmp4              ; Save R11
        coc   @wbit1,config         ; CONFIG bit 1 set ?
        jne   f18fw1
***************************************************************
* Read F18A major/minor version
***************************************************************
        mov   @vdps,tmp0            ; Clear VDP status register
        bl    @putvr                ; Write to VR#15 for setting F18A status
        data  >0f0e                 ; register to read (0e=VR#14)
        clr   tmp0
        movb  @vdps,tmp0
        srl   tmp0,8
f18fw1  b     *tmp4                 ; Exit

