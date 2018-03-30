* FILE......: rnd_support.asm
* Purpose...: Random generators module

*//////////////////////////////////////////////////////////////
*                     MISC FUNCTIONS
*//////////////////////////////////////////////////////////////


***************************************************************
* RND - Generate random number
***************************************************************
*  BL   @RND
*  DATA P0,P1
*--------------------------------------------------------------
*  P0 = Highest random number allowed
*  P1 = Address of random seed
*--------------------------------------------------------------
*  BL   @RNDX
*
*  TMP0 = Highest random number allowed
*  TMP3 = Address of random seed
*--------------------------------------------------------------
*  OUTPUT
*  TMP0 = The generated random number
********@*****@*********************@**************************
rnd     mov   *r11+,tmp0            ; Highest number allowed
        mov   *r11+,tmp3            ; Get address of random seed
rndx    clr   tmp1
        mov   *tmp3,tmp2            ; Get random seed
        jne   rnd1
        inc   tmp2                  ; May not be zero
rnd1    srl   tmp2,1
        jnc   rnd2
        xor   @rnddat,tmp2
rnd2    mov   tmp2,*tmp3            ; Store new random seed
        div   tmp0,tmp1
        mov   tmp2,tmp0
        b     *r11                  ; Exit
rnddat  data  >0b400                ; The magic number
