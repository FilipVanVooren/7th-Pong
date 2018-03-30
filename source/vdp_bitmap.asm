* FILE......: vdp_bitmap.asm
* Purpose...: VDP bitmap support module

***************************************************************
* BITMAP - Set tiles for displaying bitmap picture
***************************************************************
*  BL   @BITMAP
********@*****@*********************@**************************
bitmap  mov   r11,tmp3              ; Save R11
        mov   @wbase,tmp0           ; Get PNT base address
        bl    @vdwa                 ; Setup VDP write address
        clr   tmp1
        li    tmp2,768              ; Write 768 bytes
*--------------------------------------------------------------
* Repeat 3 times: write bytes >00 .. >FF
*--------------------------------------------------------------
bitma1  movb  tmp1,*r15             ; Write byte
        ai    tmp1,>0100
        dec   tmp2
        jne   bitma1
        b     *tmp3                 ; Exit
