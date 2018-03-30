* FILE......: vdp_hexsupport.asm
* Purpose...: VDP create, display hex numbers module

***************************************************************
* MKHEX - Convert hex word to string
***************************************************************
*  BL   @MKHEX
*  DATA P0,P1,P2
*--------------------------------------------------------------
*  P0 = Pointer to 16 bit word
*  P1 = Pointer to string buffer
*  P2 = Offset for ASCII digit
*
*  (CONFIG#0 = 1) = Display number at cursor YX
********@*****@*********************@**************************
mkhex   mov   *r11+,tmp0            ; Address of word
        mov   *r11+,@waux3          ; Pointer to string buffer
        li    tmp3,waux1            ; We store the result in WAUX1 and WAUX2
        clr   *tmp3+                ; Clear WAUX1
        clr   *tmp3                 ; Clear WAUX2
        dect  tmp3                  ; Back to WAUX1
        mov   *tmp0,tmp0            ; Get word
*--------------------------------------------------------------
*    Convert nibbles to bytes (is in wrong order)
*--------------------------------------------------------------
        li    tmp1,4
mkhex1  mov   tmp0,tmp2             ; Make work copy
        andi  tmp2,>000f            ; Only keep LSN
        a     *r11,tmp2             ; Add ASCII-offset
mkhex2  swpb  tmp2
        movb  tmp2,*tmp3+           ; Save byte
        srl   tmp0,4                ; Next nibble
        dec   tmp1
        jne   mkhex1                ; Repeat until all nibbles processed
        andi  config,>bfff          ; Reset bit 1 in config register
*--------------------------------------------------------------
*    Build first 2 bytes in correct order
*--------------------------------------------------------------
        mov   @waux3,tmp1           ; Get pointer
        clr   *tmp1                 ; Set length byte to 0
        inc   tmp1                  ; Next byte, not word!
        mov   @waux2,tmp0
        swpb  tmp0
        movb  tmp0,*tmp1+
        swpb  tmp0
        movb  tmp0,*tmp1+
*--------------------------------------------------------------
*    Set length byte
*--------------------------------------------------------------
        mov   @waux3,tmp0           ; Get start of string buffer
        movb  @bd4,*tmp0            ; Set lengh byte to 4
        inct  r11                   ; Skip Parameter P2
*--------------------------------------------------------------
*    Build last 2 bytes in correct order
*--------------------------------------------------------------
        mov   @waux1,tmp0
        swpb  tmp0
        movb  tmp0,*tmp1+
        swpb  tmp0
        movb  tmp0,*tmp1+
*--------------------------------------------------------------
*    Display hex number ?
*--------------------------------------------------------------
        coc   @wbit0,config         ; Check if 'display' bit is set
        jeq   mkhex3                ; Yes, so show at current YX position
        b     *r11                  ; Exit
*--------------------------------------------------------------
*  Display hex number on screen at current YX position
*--------------------------------------------------------------
mkhex3  andi  config,>7fff          ; Reset bit 0
        mov   @waux3,tmp1           ; Get Pointer to string
        b     @xutst0               ; Display string
prefix  data  >0610                 ; Length byte + blank


***************************************************************
* PUTHEX - Put 16 bit word on screen
***************************************************************
*  BL   @PUTHEX
*  DATA P0,P1,P2,P3
*--------------------------------------------------------------
*  P0 = YX position
*  P1 = Pointer to 16 bit word
*  P2 = Pointer to string buffer
*  P3 = Offset for ASCII digit
********@*****@*********************@**************************
puthex  mov   *r11+,@wyx            ; Set cursor
        ori   config,>8000          ; CONFIG register bit 0=1
        jmp   mkhex                 ; Convert number and display

