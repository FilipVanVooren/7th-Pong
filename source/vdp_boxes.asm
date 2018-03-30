* FILE......: vdp_boxes.a99
* Purpose...: VDP Fillbox, Putbox module

***************************************************************
* FILBOX - Fill box with character
***************************************************************
*  BL   @FILBOX
*  DATA P0,P1,P2
*  ...
*  DATA EOL
*--------------------------------------------------------------
*  P0HB = Upper left corner Y
*  P0LB = Upper left corner X
*  P1HB = Height
*  P1LB = Width
*  P2HB = >00
*  P2LB = Character to fill
********@*****@*********************@**************************
filbox  mov   *r11+,@wyx            ; Upper left corner
        movb  *r11+,tmp3            ; Height in TMP3
        movb  *r11+,tmp2            ; Width in TMP2
        mov   *r11+,tmp1            ; Byte to fill
        mov   r11,tmp4              ; Save R11
        srl   tmp2,8                ; Right-align width
        srl   tmp3,8                ; Right-align height
*--------------------------------------------------------------
*  Do single row
*--------------------------------------------------------------
filbo1  bl    @yx2pnt               ; Get VDP address into TMP0
        li    r11,filbo2            ; New return address
        b     @xfilv                ; Fill VRAM with byte
*--------------------------------------------------------------
*  Recover width & character
*--------------------------------------------------------------
filbo2  mov   tmp4,tmp0
        ai    tmp0,-3               ; R11 - 3
        movb  *tmp0+,tmp2           ; Get Width/Height
        srl   tmp2,8                ; Right align
        mov   *tmp0,tmp1            ; Get character to fill
*--------------------------------------------------------------
*  Housekeeping
*--------------------------------------------------------------
        a     @wh100,@by            ; Y=Y+1
        dec   tmp3
        jgt   filbo1                ; Process next row
        c     *tmp4,@whffff         ; End-Of-List marker found ?
        jeq   filbo3                ; Yes, exit
        mov   tmp4,r11
        jmp   filbox                ; Next one
filbo3  inct  tmp4
        b     *tmp4                 ; Exit


***************************************************************
* PUTBOX - Put tiles in box
***************************************************************
*  BL   @PUTBOX
*  DATA P0,P1,P2,P3
*  ...
*  DATA EOL
*--------------------------------------------------------------
*  P0HB = Upper left corner Y
*  P0LB = Upper left corner X
*  P1HB = Box height
*  P1LB = Box width
*  P2   = Pointer to length-byte prefixed string
*  P3HB = Repeat box A-times vertically
*  P3LB = Repeat box B-times horizontally
*--------------------------------------------------------------
*  Register usage
*  ; TMP0   = work copy of YX cursor position
*  ; TMP1HB = Width  of box + X
*  ; TMP2HB = Height of box + Y
*  ; TMP3   = Pointer to string
*  ; TMP4   = Counter for string
*  ; @WAUX1 = Box AB repeat count
*  ; @WAUX2 = Copy of R11
*  ; @WAUX3 = YX position for next diagonal box
*--------------------------------------------------------------
*  ; Only byte operations on TMP1HB & TMP2HB.
*  ; LO bytes of TMP1 and TMP2 reserved for future use.
********@*****@*********************@**************************
putbox  mov   *r11+,tmp0            ; P0 - Upper left corner YX
        mov   *r11,tmp1             ; P1 - Height/Width in TMP1
        mov   *r11+,tmp2            ; P1 - Height/Width in TMP2
        mov   *r11+,tmp3            ; P2 - Pointer to string
        mov   *r11+,@waux1          ; P3 - Box repeat count AB
        mov   r11,@waux2            ; Save R11
*--------------------------------------------------------------
*  Calculate some positions
*--------------------------------------------------------------
putbo0  ab    tmp0,tmp2             ; TMP2HB = height + Y
        swpb  tmp0
        swpb  tmp1
        ab    tmp0,tmp1             ; TMP1HB = width  + X
        swpb  tmp0
        sla   config,1              ; \ clear config bit 0
        srl   config,1              ; / is only 4 bytes
        mov   tmp0,@waux3           ; Set additional work copy of YX cursor
*--------------------------------------------------------------
*  Setup VDP write address
*--------------------------------------------------------------
putbo1  mov   tmp0,@wyx             ; Set YX cursor
        bl    @yx2pnt               ; Calculate VDP address from @WYX
        bl    @vdwa                 ; Set VDP write address from TMP0
        mov   @wyx,tmp0
*--------------------------------------------------------------
*  Prepare string for processing
*--------------------------------------------------------------
        coc   @wbit0,config         ; state flag set ?
        jeq   putbo2                ; Yes, skip length byte
        movb  *tmp3+,tmp4           ; Get length byte ...
        srl   tmp4,8                ; ... and right justify
*--------------------------------------------------------------
*  Write line of tiles in box
*--------------------------------------------------------------
putbo2  movb  *tmp3+,*r15           ; Write to VDP
        dec   tmp4
        jeq   putbo3                ; End of string. Repeat box ?
*--------------------------------------------------------------
*    Adjust cursor
*--------------------------------------------------------------
        inc   tmp0                  ; X=X+1
        swpb  tmp0
        cb    tmp0,tmp1             ; Right boundary reached ?
        swpb  tmp0
        jlt   putbo2                ; Not yet, continue
        ai    tmp0,>0100            ; Y=Y+1
        movb  tmp0,@wyx             ; Update Y cursor
        cb    tmp0,tmp2             ; Bottom boundary reached ?
        jeq   putbo3                ; Yes, exit
*--------------------------------------------------------------
*  Recover starting column
*--------------------------------------------------------------
        mov   @wyx,tmp0             ; ... from YX cursor
        ori   config,>8000          ; CONFIG register bit 0=1
        jmp   putbo1                ; Draw next line
*--------------------------------------------------------------
*  Handling repeating of box
*--------------------------------------------------------------
putbo3  mov   @waux1,tmp0           ; Repeat box ?
        jeq   putbo9                ; No, move on to next list entry
*--------------------------------------------------------------
*     Repeat horizontally
*--------------------------------------------------------------
        swpb  tmp0                  ; BA
        movb  tmp0,tmp0             ; B = 0 ?
        jeq   putbo4                ; Yes, repeat vertically
        swpb  tmp0                  ; AB
        dec   tmp0                  ; B = B - 1
        mov   tmp0,@waux1           ; Update AB repeat count
        movb  tmp1,@waux3+1         ; New X position
        mov   @waux3,tmp0           ; Get new YX position
        mov   @waux2,tmp3
        ai    tmp3,-6               ; Back to P1
        jmp   putbo8
*--------------------------------------------------------------
*     Repeat vertically
*--------------------------------------------------------------
putbo4  swpb  tmp0                  ; AB
        movb  tmp0,tmp0             ; A = 0 ?
        jeq   putbo3                ; Yes, check next entry in list
        ai    tmp0,->0100           ; A = A - 1
        mov   tmp0,@waux1           ; Update AB repeat count
        mov   @waux2,tmp3           ; \
        dec   tmp3                  ; / Back to P3LB
        movb  *tmp3,@waux1+1        ; Update B repeat count
        movb  tmp2,tmp0             ; New Y position
        swpb  tmp0
        ai    tmp3,-6               ; Back to P0LB
        movb  *tmp3+,tmp0
        swpb  tmp0
        mov   tmp0,@waux3           ; Set new YX position
*--------------------------------------------------------------
*      Get Height, Width and reset string pointer
*--------------------------------------------------------------
putbo8  mov   *tmp3,tmp1            ; Get P1 into TMP1
        mov   *tmp3+,tmp2           ; Get P1 into TMP2
        mov   *tmp3,tmp3            ; Get P2 into TMP3
        jmp   putbo0                ; Next box
*--------------------------------------------------------------
*  Next entry in list
*--------------------------------------------------------------
putbo9  mov   @waux2,r11            ; Restore R11
        c     *r11,@whffff          ; End-Of-List marker found ?
        jeq   putboa                ; Yes, exit
        jmp   putbox                ; Next one
putboa  sla   config,2              ; \ clear config bits 0 & 1
        srl   config,2              ; / is only 4 bytes
        b     *r11                  ; Exit
