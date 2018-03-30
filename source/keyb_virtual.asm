* FILE......: keyb_virtual.asm
* Purpose...: Virtual keyboard module

***************************************************************
* VIRTKB - Read virtual keyboard and joysticks
***************************************************************
*  BL @VIRTKB
*--------------------------------------------------------------
*  COLUMN     0     1  2  3  4  5    6   7
*         +---------------------------------+------+
*  ROW 7  |   =     .  ,  M  N  /   JS1 JS2 | Fire |
*  ROW 6  | SPACE   L  K  J  H  :;  JS1 JS2 | Left |
*  ROW 5  | ENTER   O  I  U  Y  P   JS1 JS2 | Right|
*  ROW 4  |         9  8  7  6  0   JS1 JS2 | Down |
*  ROW 3  | FCTN    2  3  4  5  1   JS1 JS2 | Up   |
*  ROW 2  | SHIFT   S  D  F  G  A           +------|
*  ROW 1  | CTRL    W  E  R  T  Q                  |
*  ROW 0  |         X  C  V  B  Z                  |
*         +----------------------------------------+
*  See MG smart programmer 1986
*  September/Page 15 and November/Page 6
*  Also see virtual keyboard status for bits to check
*--------------------------------------------------------------
*  Register usage
*  TMP0     Keyboard matrix column to process
*  TMP1MSB  Keyboard matrix 8 bits of 1 column
*  TMP2     Virtual keyboard flags
*  TMP3     Address of entry in mapping table
*  TMP4     Copy of R12 (CONFIG REGISTER)
*  R12      CRU communication
********@*****@*********************@**************************
virtkb
*       szc   @wbit10,config        ; Reset alpha lock down key
        szc   @wbit11,config        ; Reset ANY key
        mov   config,tmp4           ; Save R12 (CONFIG REGISTER)
        clr   tmp0                  ; Value in MSB! Start with column 0
        clr   tmp2                  ; Erase virtual keyboard flags
        li    tmp3,kbmap0           ; Start with column 0
*--------------------------------------------------------------
* Check alpha lock key
*-------@-----@---------------------@--------------------------
        clr   r12
        sbz   >0015                 ; Set P5
        tb    7
        jeq   virtk1
        li    tmp2,kalpha           ; Alpha lock key down
*       soc   @wbit10,config        ; Set alpha lock down key (CONFIG)
*--------------------------------------------------------------
* Scan keyboard matrix
*-------@-----@---------------------@--------------------------
virtk1  sbo   >0015                 ; Reset P5
        li    r12,>0024             ; Scan full 8x8 keyboard matrix. R12 is used by LDCR
        ldcr  tmp0,3                ; Set keyboard column with a value from 0-7 (3=3 bits)
        li    r12,>0006             ; Load CRU base for row. R12 required by STCR
        seto  tmp1                  ; >FFFF
        stcr  tmp1,8                ; Bring 8 row bits into MSB of TMP1
        inv   tmp1
        jeq   virtk2                ; >0000 ?
        soc   @wbit11,tmp4          ; Set ANY key in copy of CONFIG register
*--------------------------------------------------------------
* Process column
*-------@-----@---------------------@--------------------------
virtk2  coc   *tmp3+,tmp1           ; Check bit mask
        jne   virtk3
        soc   *tmp3,tmp2            ; Set virtual keyboard flags
virtk3  inct  tmp3
        c     *tmp3,@kbeoc          ; End-of-column ?
        jne   virtk2                ; No, next entry
        inct  tmp3
*--------------------------------------------------------------
* Prepare for next column
*-------@-----@---------------------@--------------------------
virtk4  ci    tmp0,>0700            ; Column 7 processed ?
        jeq   virtk6                ; Yes, exit
        ci    tmp0,>0200            ; Column 2 processed ?
        jeq   virtk5                ; Yes, skip
        ai    tmp0,>0100
        jmp   virtk1
virtk5  li    tmp0,>0500            ; Skip columns 3-4
        jmp   virtk1
*--------------------------------------------------------------
* Exit
*-------@-----@---------------------@--------------------------
virtk6  mov   tmp4,config           ; Restore CONFIG register
        mov   tmp2,@wvrtkb          ; Save virtual keyboard flags
        jne   virtk7
        b     *r11                  ; Exit
virtk7  ci    tmp2,>ffff            ; FCTN-QUIT pressed ?
        jne   virtk8                ; No
        seto  r1                    ; Set exit flag
        b     @runli1               ; Yes, reset computer
virtk8  ci    tmp2,kalpha           ; Only alpha-lock pressed ?
        jne   virtk9
        szc   @wbit11,config        ; Yes, so reset ANY key
virtk9  b     *r11                  ; Exit
*--------------------------------------------------------------
* Mapping table
*-------@-----@---------------------@--------------------------
*                                   ; Bit 01234567
kbmap0  data  >1100,>ffff           ; >11 00010001  FCTN QUIT
        data  >0200,k1fire          ; >02 00000010  spacebar
        data  >0400,kenter          ; >04 00000100  enter
kbeoc   data  >ffff

kbmap1  data  >0800,kback           ; >08 00001000  FCTN BACK
        data  >0200,k2rg            ; >02 00000010  L (arrow right)
        data  >0400,k2up            ; >04 00000100  O (arrow up)
        data  >2000,k1lf            ; >20 00100000  S (arrow left)
        data  >8000,k1dn            ; >80 10000000  X (arrow down)
        data  >ffff

kbmap2  data  >0800,kredo           ; >08 00001000  FCTN REDO
        data  >0100,k2dn            ; >01 00000001  , (arrow down)
        data  >2000,k1rg            ; >20 00100000  D (arrow right)
        data  >4000,k1up            ; >80 01000000  E (arrow up)
        data  >0200,k2lf            ; >02 00000010  K (arrow left)
        data  >ffff

kbcol5  data  >0100,k2fire          ; >01 00000001  / (fire) 
        data  >0800,kpause          ; >08 00001000  P (pause)
        data  >8000,k1fire          ; >80 01000000  Q (fire)
        data  >ffff

kbmap6  data  >0100,k1fire          ; >01 00000001  joystick 1 FIRE
        data  >0200,k1lf            ; >02 00000010  joystick 1 left
        data  >0400,k1rg            ; >04 00000100  joystick 1 right
        data  >0800,k1dn            ; >08 00001000  joystick 1 down
        data  >1000,k1up            ; >10 00010000  joystick 1 up
        data  >ffff

kbmap7  data  >0100,k2fire          ; >01 00000001  joystick 2 FIRE
        data  >0200,k2lf            ; >02 00000010  joystick 2 left
        data  >0400,k2rg            ; >04 00000100  joystick 2 right
        data  >0800,k2dn            ; >08 00001000  joystick 2 down
        data  >1000,k2up            ; >10 00010000  joystick 2 up
        data  >ffff
