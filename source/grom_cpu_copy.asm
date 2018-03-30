* FILE......: grom_cpu_copy.asm
* Purpose...: GROM -> CPU copy support module

*//////////////////////////////////////////////////////////////
*                       GROM COPY FUNCTIONS
*//////////////////////////////////////////////////////////////


***************************************************************
* CPYG2M - Copy GROM memory to CPU memory
***************************************************************
*  BL   @CPYG2M
*  DATA P0,P1,P2
*--------------------------------------------------------------
*  P0 = GROM source address
*  P1 = CPU target address
*  P2 = Number of bytes to copy
*--------------------------------------------------------------
*  BL @CPYG2M
*
*  TMP0 = GROM source address
*  TMP1 = CPU target address
*  TMP2 = Number of bytes to copy
********@*****@*********************@**************************
cpyg2m  mov   *r11+,tmp0            ; Memory source address
        mov   *r11+,tmp1            ; Memory target address
        mov   *r11+,tmp2            ; Number of bytes to copy
*--------------------------------------------------------------
* Setup GROM source address
*--------------------------------------------------------------
xpyg2m  movb  tmp0,@grmwa
        swpb  tmp0
        movb  tmp0,@grmwa
*--------------------------------------------------------------
*    Copy bytes from GROM to CPU memory
*--------------------------------------------------------------
        li    tmp0,grmrd            ; Set TMP0 to GROM data port
        mov   @tmp003,@mcloop       ; Setup copy command
        b     @mcloop               ; Copy bytes
tmp003  data  >dd54                 ; MOVB *TMP0,*TMP1+
