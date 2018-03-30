* FILE......: grom_vram_copy.asm
* Purpose...: GROM to VDP vram copy support module

*//////////////////////////////////////////////////////////////
*                       GROM COPY FUNCTIONS
*//////////////////////////////////////////////////////////////

***************************************************************
* CPYG2V - Copy GROM memory to VRAM memory
***************************************************************
*  BL   @CPYG2V
*  DATA P0,P1,P2
*--------------------------------------------------------------
*  P0 = GROM source address
*  P1 = VDP target address
*  P2 = Number of bytes to copy
*--------------------------------------------------------------
*  BL @CPYG2V
*
*  TMP0 = GROM source address
*  TMP1 = VDP target address
*  TMP2 = Number of bytes to copy
********@*****@*********************@**************************
cpyg2v  mov   *r11+,tmp0            ; Memory source address
        mov   *r11+,tmp1            ; Memory target address
        mov   *r11+,tmp2            ; Number of bytes to copy
*--------------------------------------------------------------
* Setup GROM source address
*--------------------------------------------------------------
xpyg2v  movb  tmp0,@grmwa
        swpb  tmp0
        movb  tmp0,@grmwa
*--------------------------------------------------------------
* Setup VDP target address
*--------------------------------------------------------------
        ori   tmp1,>4000
        swpb  tmp1
        movb  tmp1,@vdpa
        swpb  tmp1
        movb  tmp1,@vdpa            ; Set VDP target address
*--------------------------------------------------------------
*    Copy bytes from GROM to VDP memory
*--------------------------------------------------------------
        li    tmp3,grmrd            ; Set TMP3 to GROM data port
        li    r15,vdpw              ; Set VDP write address
        mov   @tmp002,@mcloop       ; Setup copy command
        b     @mcloop               ; Copy bytes
tmp002  data  >d7d7                 ; MOVB *TMP3,*R15
