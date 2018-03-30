* FILE......: vdp_yx2px_calc.asm
* Purpose...: Calculate pixel position for YX coordinate

***************************************************************
* YX2PX - Get pixel position for cursor YX position
***************************************************************
*  BL   @YX2PX
*
*  (CONFIG:0 = 1) = Skip sprite adjustment
*--------------------------------------------------------------
*  INPUT
*  @WYX   = Cursor YX position
*--------------------------------------------------------------
*  OUTPUT
*  TMP0HB = Y pixel position
*  TMP0LB = X pixel position
*--------------------------------------------------------------
*  Remarks
*  This subroutine does not support multicolor or text mode
********@*****@*********************@**************************
yx2px   mov   @wyx,tmp0
yx2pxx  mov   r11,tmp2              ; Save return address
        swpb  tmp0                  ; Y<->X
        clr   tmp1                  ; Clear before copy
        movb  tmp0,tmp1             ; Copy X to TMP1
        sla   tmp1,3                ; X=X*8
        sla   tmp0,3                ; Y=Y*8
        movb  tmp1,tmp0
        swpb  tmp0                  ; X<->Y
yx2pi1  coc   @wbit0,config         ; Skip sprite adjustment ?
        jeq   yx2pi3                ; Yes, exit
*--------------------------------------------------------------
* Adjust for Y sprite location
* See VDP Programmers Guide, Section 9.2.1
*--------------------------------------------------------------
yx2pi2  sb    @bd1,tmp0             ; Adjust Y. Top of screen is at >FF
        cb    @bd208,tmp0           ; Y position = >D0 ?
        jeq   yx2pi2                ; Yes, but that's not allowed, correct
yx2pi3  b     *tmp2                 ; Exit
