* FILE......: vdp_vchar.a99
* Purpose...: VDP vchar module

***************************************************************
* Repeat characters vertically at YX
***************************************************************
*  BL    @VCHAR
*  DATA  P0,P1
*  ...
*  DATA  EOL                        ; End-of-list
*--------------------------------------------------------------
*  P0HB = Y position
*  P0LB = X position
*  P1HB = Byte to write
*  P1LB = Number of times to repeat
********@*****@*********************@**************************
vchar   mov   *r11+,@wyx            ; Set YX position
        mov   r11,tmp3              ; Save R11 in TMP3
vchar1  mov   @wcolmn,tmp4          ; Get columns per row
        bl    @yx2pnt               ; Get VDP address into TMP0
        movb  *tmp3+,tmp1           ; Byte to write
        movb  *tmp3+,tmp2
        srl   tmp2,8                ; Repeat count
*--------------------------------------------------------------
*    Setup VDP write address
*--------------------------------------------------------------
vchar2  bl    @vdwa                 ; Setup VDP write address
*--------------------------------------------------------------
*    Dump tile to VDP and do housekeeping
*--------------------------------------------------------------
        movb  tmp1,*r15             ; Dump tile to VDP
        a     tmp4,tmp0             ; Next row
        dec   tmp2
        jne   vchar2
        c     *tmp3,@whffff         ; End-Of-List marker found ?
        jeq   vchar3                ; Yes, exit
        mov   *tmp3+,@wyx           ; Save YX position
        jmp   vchar1                ; Next one
vchar3  inct  tmp3
        b     *tmp3                 ; Exit

***************************************************************
* Repeat characters vertically at YX
***************************************************************
* TMP0 = YX position
* TMP1 = Byte to write
* TMP2 = Repeat count
***************************************************************
xvchar  mov   r11,tmp4              ; Save return address
        mov   tmp0,@wyx             ; Set cursor position
        swpb  tmp1                  ; Byte to write into MSB
        mov   @wcolmn,tmp3          ; Get columns per row
        bl    @yx2pnt               ; Get VDP address into TMP0
*--------------------------------------------------------------
*    Setup VDP write address
*--------------------------------------------------------------
xvcha1  bl    @vdwa                 ; Setup VDP write address
*--------------------------------------------------------------
*    Dump tile to VDP and do housekeeping
*--------------------------------------------------------------
        movb  tmp1,*r15             ; Dump tile to VDP
        a     @wcolmn,tmp0          ; Next row
        dec   tmp2
        jne   xvcha1
        b     *tmp4                 ; Exit
