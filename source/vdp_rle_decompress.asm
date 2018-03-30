* FILE......: vdp_rle_decompress.asm
* Purpose...: RLE decompress to VRAM support module

***************************************************************
* RLE2V - RLE decompress to VRAM memory
***************************************************************
*  BL   @RLE2V
*  DATA P0,P1,P2
*--------------------------------------------------------------
*  P0 = ROM/RAM source address
*  P1 = VDP target address
*  P2 = Length of RLE encoded data
*--------------------------------------------------------------
*  BL @RLE2VX
*
*  TMP0     = VDP target address
*  TMP2 (!) = ROM/RAM source address
*  TMP3 (!) = Length of RLE encoded data
*--------------------------------------------------------------
*  Detail on RLE compression format:
*  - If high bit is set, remaining 7 bits indicate to copy
*    the next byte that many times.
*  - If high bit is clear, remaining 7 bits indicate how many
*    data bytes (non-repeated) follow.
********@*****@*********************@**************************
rle2v   mov   *r11+,tmp2            ; ROM/RAM source address
        mov   *r11+,tmp0            ; VDP target address
        mov   *r11+,tmp3            ; Length of RLE encoded data
        mov   r11,@waux1            ; Save return address
rle2vx  bl    @vdwa                 ; Setup VDP address from TMP0
        mov   tmp2,tmp0             ; We can safely reuse TMP0 now
rle2v0  movb  *tmp0+,tmp2           ; Get control byte into TMP2
        dec   tmp3                  ; Update length
        jeq   rle2vz                ; End of list
        sla   tmp2,1                ; Check bit 0 of control byte
        joc   rle2v2                ; Yes, next byte is compressed
*--------------------------------------------------------------
*    Dump uncompressed bytes
*--------------------------------------------------------------
rle2v1  mov   @rledat,@mcloop       ; Setup machine code (MOVB *TMP0+,*R15)
        srl   tmp2,9                ; Use control byte as counter
        s     tmp2,tmp3             ; Update length
        bl    @mcloop               ; Write data to VDP
        jmp   rle2v3
*--------------------------------------------------------------
*    Dump compressed bytes
*--------------------------------------------------------------
rle2v2  mov   @filzz,@mcloop        ; Setup machine code(MOVB TMP1,*R15)
        srl   tmp2,9                ; Use control byte as counter
        dec   tmp3                  ; Update length
        movb  *tmp0+,tmp1           ; Byte to fill
        bl    @mcloop               ; Write data to VDP
*--------------------------------------------------------------
*    Check if more data to decompress
*--------------------------------------------------------------
rle2v3  mov   tmp3,tmp3             ; Length counter = 0 ?
        jne   rle2v0                ; Not yet, process data
*--------------------------------------------------------------
*    Exit
*--------------------------------------------------------------
rle2vz  mov   @waux1,r11
        b     *r11                  ; Return
rledat  data  >d7f4                 ; MOVB *TMP0+,*R15
