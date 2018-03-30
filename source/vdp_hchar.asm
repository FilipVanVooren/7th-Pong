* FILE......: vdp_hchar.a99
* Purpose...: VDP hchar module

***************************************************************
* Repeat characters horizontally at YX
***************************************************************
*  BL    @HCHAR
*  DATA  P0,P1
*  ...
*  DATA  EOL                        ; End-of-list
*--------------------------------------------------------------
*  P0HB = Y position
*  P0LB = X position
*  P1HB = Byte to write
*  P1LB = Number of times to repeat
********@*****@*********************@**************************
hchar   mov   *r11+,@wyx            ; Set YX position
        movb  *r11+,tmp1
hcharx  srl   tmp1,8                ; Byte to write
        movb  *r11+,tmp2
        srl   tmp2,8                ; Repeat count
        mov   r11,tmp3
        bl    @yx2pnt               ; Get VDP address into TMP0
*--------------------------------------------------------------
*    Draw line
*--------------------------------------------------------------
        li    r11,hchar1
        b     @xfilv                ; Draw
*--------------------------------------------------------------
*    Do housekeeping
*--------------------------------------------------------------
hchar1  c     *tmp3,@whffff         ; End-Of-List marker found ?
        jeq   hchar2                ; Yes, exit
        mov   tmp3,r11
        jmp   hchar                 ; Next one
hchar2  inct  tmp3
        b     *tmp3                 ; Exit
