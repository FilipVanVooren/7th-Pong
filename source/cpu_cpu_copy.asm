* FILE......: cpu_cpu_copy.asm
* Purpose...: CPU to CPU memory copy support module

*//////////////////////////////////////////////////////////////
*                       CPU COPY FUNCTIONS
*//////////////////////////////////////////////////////////////

***************************************************************
* CPYM2M - Copy CPU memory to CPU memory
***************************************************************
*  BL   @CPYM2M
*  DATA P0,P1,P2
*--------------------------------------------------------------
*  P0 = Memory source address
*  P1 = Memory target address
*  P2 = Number of bytes to copy
*--------------------------------------------------------------
*  BL @XPYM2M
*
*  TMP0 = Memory source address
*  TMP1 = Memory target address
*  TMP2 = Number of bytes to copy
********@*****@*********************@**************************
cpym2m  mov   *r11+,tmp0            ; Memory source address
        mov   *r11+,tmp1            ; Memory target address
        mov   *r11+,tmp2            ; Number of bytes to copy
*--------------------------------------------------------------
* Do some checks first
*--------------------------------------------------------------
xpym2m  andi  config,>7fff          ; Clear CONFIG bit 0
        mov   tmp0,tmp3
        andi  tmp3,1
        jne   cpyodd                ; Odd source address handling
cpym1   mov   tmp1,tmp3
        andi  tmp3,1
        jne   cpyodd                ; Odd target address handling
*--------------------------------------------------------------
* 8 bit copy
*--------------------------------------------------------------
cpym2   coc   @wbit0,config         ; CONFIG bit 0 set ?
        jne   cpym3
        mov   @tmp011,@mcloop       ; Setup byte copy command
        b     @mcloop               ; Copy memory and exit
*--------------------------------------------------------------
* 16 bit copy
*--------------------------------------------------------------
cpym3   mov   tmp2,tmp3
        andi  tmp3,1                ; TMP3=1 -> ODD else EVEN
        jeq   cpym4
        dec   tmp2                  ; Make TMP2 even
cpym4   mov   *tmp0+,*tmp1+
        dect  tmp2
        jne   cpym4
*--------------------------------------------------------------
* Copy last byte if ODD
*--------------------------------------------------------------
        mov   tmp3,tmp3
        jeq   cpymz
        movb  *tmp0,*tmp1
cpymz   b     *r11
*--------------------------------------------------------------
* Handle odd source/target address
*--------------------------------------------------------------
cpyodd  ori   config,>8000        ; Set CONFIG bot 0
        jmp   cpym2
tmp011  data  >dd74               ; MOVB *TMP0+,*TMP1+
