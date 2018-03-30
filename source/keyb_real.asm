* FILE......: keyb_real.asm
* Purpose...: Full (real) keyboard support module

*//////////////////////////////////////////////////////////////
*                     KEYBOARD FUNCTIONS 
*//////////////////////////////////////////////////////////////

***************************************************************
* REALKB - Scan keyboard in real mode
***************************************************************
*  BL @REALKB
*--------------------------------------------------------------
*  Based on work done by Simon Koppelmann
*  taken from the book "TMS9900 assembler auf dem TI-99/4A"
********@*****@*********************@**************************
realkb  mov   r12,tmp0              ; Save R12 (CONFIG) in TMP0
        andi  tmp0,>7fff            ; Reset bit 0 in saved CONFIG register
        li    r12,>0024
        li    r15,kbsmal            ; Default is KBSMAL table
        clr   tmp2
        ldcr  tmp2,>0003            ; Lower case by default
*--------------------------------------------------------------
* SHIFT key pressed ?
*--------------------------------------------------------------
        clr   r12
        tb    >0008                 ; Shift-key ?
        jeq   realk1                ; No
        li    r15,kbshft            ; Yes, use KBSHIFT table
*--------------------------------------------------------------
* FCTN key pressed ?
*--------------------------------------------------------------
realk1  tb    >0007                 ; FNCTN-key ?
        jeq   realk2                ; No
        li    r15,kbfctn            ; Yes, use KBFCTN table
*--------------------------------------------------------------
* CTRL key pressed ?
*--------------------------------------------------------------
realk2  tb    >0009                 ; CTRL-key ?
        jeq   realk3                ; No
        li    r15,kbctrl            ; Yes, use KBCTRL table
*--------------------------------------------------------------
* ALPHA LOCK key down ?
*--------------------------------------------------------------
realk3  sbz   >0015                 ; Set P5
        tb    >0007                 ; ALPHA-Lock key ?
        jne   realk4                ; No,  saved CONFIG register bit 0 = 0
        ori   tmp0,>8000            ; Yes, saved CONFIG register bit 0 = 1
*--------------------------------------------------------------
* Scan keyboard column
*--------------------------------------------------------------
realk4  sbo   >0015                 ; Reset P5
        li    tmp2,6                ; Bitcombination for CRU, column counter
realk5  dec   tmp2
        li    r12,>24               ; CRU address for P2-P4
        swpb  tmp2
        ldcr  tmp2,3                ; Transfer bit combination
        swpb  tmp2
        li    r12,6                 ; CRU read address
        stcr  tmp3,8                ; Transfer 8 bits into R2HB
        inv   tmp3                  ;
        andi  tmp3,>ff00            ; Clear TMP3LB
*--------------------------------------------------------------
* Scan keyboard row
*--------------------------------------------------------------
        clr   tmp1                  ; Use TMP1 as row counter from now on
realk6  sla   tmp3,1                ; R2 bitcombinations scanned by shifting left.
        joc   realk8                ; If no carry after 8 loops, then it means no key
realk7  inc   tmp1                  ; was pressed on that line.
        ci    tmp1,8
        jl    realk6
        mov   tmp2,tmp2             ; All 6 columns processed ?
        jh    realk5                ; No, next column
        jmp   realkz                ; Yes, exit
*--------------------------------------------------------------
* Check for match in data table
*--------------------------------------------------------------
realk8  mov   tmp2,tmp4
        sla   tmp4,3                ; TMP4 = TMP2 * 8
        a     tmp1,tmp4             ; TMP4 = TMP4 + TMP1
        a     r15,tmp4              ; TMP4 = TMP4 + base address of data table (R15)
        movb  *tmp4,*tmp4           ; Is the byte on that address = >00 ?
        jeq   realk7                ; Yes, then discard and continue scanning (FCTN, SHIFT, CTRL)
*--------------------------------------------------------------
* Determine ASCII value of key
*--------------------------------------------------------------
realk9  movb  *tmp4,tmp2            ; Real keypress. It's safe to reuse TMP2 now
        coc   @wbit0,tmp0           ; ALPHA-Lock key pressed ?
        jne   realka                ; No, continue with KBCONT4
        cb    tmp2,@kbsmal+42       ; Is ASCII of key pressed < 97 ('a') ?
        jl    realka
        cb    tmp2,@kbsmal+40       ; and ASCII of key pressed > 122 ('z') ?
        jh    realka                ; No, continue with REALKA
        ai    tmp2,->2000           ; ASCII = ASCII - 32 (lowercase to uppercase!)
realka  srl   tmp2,8                ; Right justify
        mov   tmp2,@waux3           ; Store ASCII value of key in WAUX3
        soc   @wbit11,tmp0          ; Set ANYKEY flag in saved CONFIG register
realkz  mov   tmp0,r12              ; Restore CONFIG register
        li    r15,vdpw              ; Setup VDP write address again after using R15 as temp storage
        b     *r11                  ; Exit
********@*****@*********************@**************************
kbsmal  data  >ff00,>0000,>ff0d,>203D
        text  'xws29ol.'
        text  'ced38ik,'
        text  'vrf47ujm'
        text  'btg56yhn'
        text  'zqa10p;/'
kbshft  data  >ff00,>0000,>ff0d,>202B
        text  'XWS@(OL>'
        text  'CED#*IK<'
        text  'VRF$&UJM'
        text  'BTG%^YHN'
        text  'ZQA!)P:-'
kbfctn  data  >ff00,>0000,>ff0d,>2005
        data  >0a7e,>0804,>0f27,>c2B9
        data  >600b,>0907,>063f,>c1B8
        data  >7f5b,>7b02,>015f,>c0C3
        data  >be5d,>7d0e,>0cc6,>bfC4
        data  >5cb9,>7c03,>bc22,>bdBA
kbctrl  data  >ff00,>0000,>ff0d,>209D
        data  >9897,>93b2,>9f8f,>8c9B
        data  >8385,>84b3,>9e89,>8b80
        data  >9692,>86b4,>b795,>8a8D
        data  >8294,>87b5,>b698,>888E
        data  >9a91,>81b1,>b090,>9cBB
