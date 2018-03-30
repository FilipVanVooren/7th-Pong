* FILE......: rom_bankswitch.asm
* Purpose...: ROM bankswitching Support module

*//////////////////////////////////////////////////////////////
*                   BANKSWITCHING FUNCTIONS
*//////////////////////////////////////////////////////////////

***************************************************************
* SWBNK - Switch ROM bank
***************************************************************
*  BL   @SWBNK
*  DATA P0,P1
*--------------------------------------------------------------
*  P0 = Bank selection address (>600X)
*  P1 = Vector address
*--------------------------------------------------------------
*  B    @SWBNKX
*
*  TMP0 = Bank selection address (>600X)
*  TMP1 = Vector address
*--------------------------------------------------------------
*  Important! The bank-switch routine must be at the exact
*  same location accross banks
********@*****@*********************@**************************
swbnk   mov   *r11+,tmp0
        mov   *r11+,tmp1
swbnkx  clr   *tmp0                 ; Select bank in TMP0
        mov   *tmp1,tmp1
        b     *tmp1                 ; Switch to routine in TMP1
