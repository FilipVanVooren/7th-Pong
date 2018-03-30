* FILE......: vdp_viewport.asm
* Purpose...: VDP viewport support module

***************************************************************
* SCRDIM - Set (virtual) screen base and dimension
***************************************************************
*  BL   @SCRDIM
*--------------------------------------------------------------
*  INPUT
*  P0 = PNT base address
*  P1 = Number of columns per row
********@*****@*********************@**************************
scrdim  mov   *r11+,@wbase          ; VDP destination address
        mov   *r11+,@wcolmn         ; Number of columns per row
        b     *r11                  ; Exit


***************************************************************
* VIEW - Viewport into virtual screen
***************************************************************
*  BL   @VIEW
*  DATA P0,P1,P2,P3,P4
*--------------------------------------------------------------
*  P0   = Pointer to RAM buffer
*  P1   = Physical screen - upper left corner YX of viewport
*  P2HB = Physical screen - Viewport height
*  P2LB = Physical screen - Viewport width
*  P3   = Virtual screen  - VRAM base address
*  P4   = Virtual screen  - Number of columns
*
*  TMP0 must contain the YX offset in virtual screen
*--------------------------------------------------------------
* Memory usage
* WAUX1 = Virtual screen VRAM base
* WAUX2 = Virtual screen columns per row
* WAUX3 = Virtual screen YX
*
* RAM buffer (offset)
* 01  Physical screen VRAM base
* 23  Physical screen columns per row
* 45  Physical screen YX (viewport upper left corner)
* 67  Height & width of viewport
* 89  Return address
********@*****@*********************@**************************
view    mov   *r11+,tmp4            ; P0: Get pointer to RAM buffer
        mov   @wbase,*tmp4          ; RAM 01 - Save physical screen VRAM base
        mov   @wcolmn,@2(tmp4)      ; RAM 23 - Save physical screen size (columns per row)
        mov   *r11+,@4(tmp4)        ; RAM 45 - P1: Get viewport upper left corner YX
        mov   *r11+,tmp3            ;
        mov   tmp3,@6(tmp4)         ; RAM 67 - P2: Get viewport height & width
        mov   *r11+,@waux1          ; P3: Get virtual screen VRAM base address
        mov   *r11+,@waux2          ; P4: Get virtual screen size (columns per row)
        mov   tmp0,@waux3           ; Get upper left corner YX in virtual screen
        mov   r11,@8(tmp4)          ; RAM 89 - Store R11 for exit
        sla   config,1              ; \
        srl   config,1              ; / Clear CONFIG bits 0
        srl   tmp3,8                ; Row counter
*--------------------------------------------------------------
*    Set virtual screen dimension and position cursor
*--------------------------------------------------------------
view1   mov   @waux1,@wbase         ; Set virtual screen base
        mov   @waux2,@wcolmn        ; Set virtual screen width
        mov   @waux3,@wyx           ; Set cursor in virtual screen
*--------------------------------------------------------------
*    Prepare for copying a single line
*--------------------------------------------------------------
view2   bl    @yx2pnt               ; Get VRAM address in TMP0
        mov   tmp4,tmp1             ; RAM buffer + 10
        ai    tmp1,10               ;
        mov   @6(tmp4),tmp2         ; \ Get RAM buffer byte 1
        andi  tmp2,>00ff            ; / Clear MSB
        xor   @wbit0,config         ; Toggle bit 0
        czc   @wbit0,config         ; Bit 0=0 ?
        jeq   view4                 ; Yes! So copy from RAM to VRAM
*--------------------------------------------------------------
*    Copy line from VRAM to RAM
*--------------------------------------------------------------
view3   bl    @xpyv2m               ; Copy block from VRAM (virtual screen) to RAM
        mov   *tmp4,@wbase          ; Set physical screen base
        mov   @2(tmp4),@wcolmn      ; Set physical screen columns per row
        mov   @4(tmp4),@wyx         ; Set cursor in physical screen
        jmp   view2
*--------------------------------------------------------------
*    Copy line from RAM to VRAM
*--------------------------------------------------------------
view4   bl    @xpym2v               ; Copy block to VRAM
        ab    @bd1,@4(tmp4)         ; Physical screen Y=Y+1
        ab    @bd1,@waux3           ; Virtual screen  Y=Y+1
        dec   tmp3                  ; Update row counter
        jne   view1                 ; Next line unless all rows process
*--------------------------------------------------------------
*    Exit
*--------------------------------------------------------------
viewz   mov   @8(tmp4),r11          ; \
        b     *r11                  ; / exit
