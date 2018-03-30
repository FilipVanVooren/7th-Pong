* FILE......: vdp_px2yx_calc.asm
* Purpose...: Calculate YX coordinate for pixel position 

***************************************************************
* PX2YX - Get YX tile position for specified YX pixel position
***************************************************************
*  BL   @PX2YX
*--------------------------------------------------------------
*  INPUT
*  TMP0   = Pixel YX position
*
*  (CONFIG:0 = 1) = Skip sprite adjustment
*--------------------------------------------------------------
*  OUTPUT
*  TMP0HB = Y tile position
*  TMP0LB = X tile position
*  TMP1HB = Y pixel offset
*  TMP1LB = X pixel offset
*--------------------------------------------------------------
*  Remarks
*  This subroutine does not support multicolor or text mode
********@*****@*********************@**************************
px2yx   coc   @wbit0,config         ; Skip sprite adjustment ?
        jeq   px2yx1
        ai    tmp0,>0100            ; Adjust Y. Top of screen is at >FF
px2yx1  mov   tmp0,tmp1             ; Copy YX
        mov   tmp0,tmp2             ; Copy YX
*--------------------------------------------------------------
* Calculate Y tile position
*--------------------------------------------------------------
        srl   tmp0,11               ; Y: Move to TMP0LB & (Y = Y / 8)
*--------------------------------------------------------------
* Calculate Y pixel offset
*--------------------------------------------------------------
        mov   tmp0,tmp3             ; Y: Copy Y tile to TMP3LB
        sla   tmp3,11               ; Y: Move to TMP3HB & (Y = Y * 8)
        neg   tmp3
        ab    tmp1,tmp3             ; Y: offset = Y pixel old + (-Y) pixel new
*--------------------------------------------------------------
* Calculate X tile position
*--------------------------------------------------------------
        andi  tmp1,>00ff            ; Clear TMP1HB
        sla   tmp1,5                ; X: Move to TMP1HB & (X = X / 8)
        movb  tmp1,tmp0             ; X: TMP0 <-- XY tile position
        swpb  tmp0                  ; XY tile position <-> YX tile position
*--------------------------------------------------------------
* Calculate X pixel offset
*--------------------------------------------------------------
        andi  tmp1,>ff00            ; X: Get rid of remaining junk in TMP1LB
        sla   tmp1,3                ; X: (X = X * 8)
        neg   tmp1
        swpb  tmp2                  ; YX <-> XY
        ab    tmp2,tmp1             ; offset X = X pixel old  + (-X) pixel new
        swpb  tmp1                  ; X0 <-> 0X
        movb  tmp3,tmp1             ; 0X --> YX
        b     *r11                  ; Exit
