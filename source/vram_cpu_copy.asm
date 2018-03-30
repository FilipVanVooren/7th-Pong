* FILE......: vram_cpu_copy.asm
* Purpose...: VRAM to CPU memory copy support module

***************************************************************
* CPYV2M - Copy VRAM to CPU memory
***************************************************************
*  BL   @CPYV2M
*  DATA P0,P1,P2
*--------------------------------------------------------------
*  P0 = VDP source address
*  P1 = RAM target address
*  P2 = Number of bytes to copy
*--------------------------------------------------------------
*  BL @XPYV2M
*
*  TMP0 = VDP source address
*  TMP1 = RAM target address
*  TMP2 = Number of bytes to copy
********@*****@*********************@**************************
cpyv2m  mov   *r11+,tmp0            ; VDP source address
        mov   *r11+,tmp1            ; Target address in RAM
        mov   *r11+,tmp2            ; Bytes to copy
*--------------------------------------------------------------
*    Setup VDP read address
*--------------------------------------------------------------
xpyv2m  swpb  tmp0
        movb  tmp0,@vdpa
        swpb  tmp0
        movb  tmp0,@vdpa
*--------------------------------------------------------------
*    Copy bytes from VDP memory to RAM
*--------------------------------------------------------------
        li    r15,vdpr              ; Set VDP read address
        mov   @tmp007,@mcloop       ; Setup copy command
        b     @mcloop               ; Read data from VDP
tmp007  data  >dd5f                 ; MOVB *R15,*TMP+
