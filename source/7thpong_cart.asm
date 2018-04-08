***************************************************************
*
*  _________  __  .__      __________
*  \______  _/  |_|  |__   \______   \____   ____   ____
*      /    \   __|  |  \   |     ___/  _ \ /    \ / ___\
*     /    / |  | |   Y  \  |    |  (  <_> |   |  / /_/  >
*    /____/  |__| |___|  /  |____|   \____/|___|  \___  /
*                      \/                       \/_____/
*   
*          7th Pong - Arcade Game Entry for the
*         4K Short'n'Sweet game contest 2017-2018
*
*             (c)2017-2018 // Retroclouds Team
*
***************************************************************
* This file: 7thpong_cart.asm       ; Version 180330.1628
*--------------------------------------------------------------
* This is the cartridge version of "7th Pong". 
* Runs on an unexpanded console.
*--------------------------------------------------------------
* v1.1  Bugfix: Game didn't start if speech synthesizer
*               was missing resolved that now.
********@*****@*********************@**************************
        save  >6000,>7fff
        aorg  >6000
*--------------------------------------------------------------
*debug                 equ  1       ; Turn on debugging
*--------------------------------------------------------------
* Skip unused spectra2 code modules for reduced code size
*--------------------------------------------------------------
use_osrom_constants    equ  1       ; Take constants from TI-99/4A OS ROM
skip_rom_bankswitch    equ  1       ; Skip ROM bankswitching support
skip_cpu_cpu_copy      equ  1       ; Skip CPU  to CPU copy functions
skip_vram_cpu_copy     equ  1       ; Skip VRAM to CPU copy functions
skip_grom_cpu_copy     equ  1       ; Skip GROM to CPU copy functions
skip_grom_vram_copy    equ  1       ; Skip GROM to VDP vram copy functions
skip_textmode_support  equ  1       ; Skip 40x24 textmode support
skip_f18a_support      equ  1       ; Skip f18a support
skip_vdp_boxes         equ  1       ; Skip filbox, putbox
skip_vdp_hexsupport    equ  1       ; Skip mkhex, puthex
skip_vdp_bitmap        equ  1       ; Skip bitmap functions
skip_vdp_intscr        equ  1       ; Skip interrupt+screen on/off
skip_vdp_viewport      equ  1       ; Skip viewport functions
skip_vdp_yx2px_calc    equ  1       ; Skip YX to pixel calculation
skip_tms52xx_detection equ  1       ; Skip speech synthesizer detection
skip_keyboard_real     equ  1       ; Skip real keyboard support
skip_random_generator  equ  1       ; Skip random functions 
*--------------------------------------------------------------
* Cartridge header
*--------------------------------------------------------------
grmhdr  byte  >aa,1,1,0,0,0
        data  prog0
        byte  0,0,0,0,0,0,0,0
prog0   data  0                     ; No more items following
        data  cold_boot
 .ifdef debug
        byte  9+11
        text  '7TH PONG 180330.1628'
 .else
        byte 9
        text '7TH PONG'
 .endif
*--------------------------------------------------------------
* Include required files
*--------------------------------------------------------------
        copy  "runlib.asm"
*--------------------------------------------------------------
* SPECTRA2 startup options
*--------------------------------------------------------------
spfclr  equ   >f1                   ; Foreground/Background color for font.
spfbck  equ   >01                   ; Screen background color.
*--------------------------------------------------------------
* Variables
*--------------------------------------------------------------
highsc  equ   >8342                 ; High-Score                                
counter equ   >8344                 ; Delay counter for restart thread
hintpos equ   >8346                 ; YX Position of hint to erase
delay   equ   >8348                 ; Initial value for delay counter
balmovy equ   >834a                 ; Vertical movement of ball
; free  equ   >834c                 ; 2 bytes free
baldir  equ   >834e                 ; Ball direction
tmpvar  equ   >8350                 ; Used by blink thread
colors  equ   >8352                 ; Used by rainbow thread
score1  equ   >8354                 ; Player 1 score
score2  equ   >8356                 ; Player 2 score
ramsat  equ   >8358                 ; SAT in RAM for 4 sprites (16 bytes)
rambuf  equ   >8368                 ; Work buffer
timers  equ   >83e0                 ; Timer table (16 bytes/4 slots)
message equ   >83fc                 ; Address of blinking message
random  equ   >83fe                 ; Address of random table
;--------------------------------------------------------------
; graphics mode 1 configuration (32x24)
;--------------------------------------------------------------
spvmod  equ   graph1                ; Video mode.   See VIDTAB for details.
spfont  equ   fnopt7                ; Font to load. See LDFONT for details.
***************************************************************
* Main
********@*****@*********************@**************************
cold_boot
        clr   @>8300                ; Clear R0 (where spectra2 ws will be),
        b     @runlib               ; we use this to reset the high-score 
main    mov   r0,@highsc            ; Save high-score (r0 survives spectra reset)
        inct  @colors               ; Initial setup of colors
        bl    @vputb
        data  >0300,>d0d0           ; Reset SAT
*--------------------------------------------------------------
* Setup characters
*--------------------------------------------------------------
        bl    @rle2v                ; Characters 1-15
        data  rle_chars,>0808,84    ; Pattern table VDP >0800
*--------------------------------------------------------------
* High-Score
*--------------------------------------------------------------
        bl    @putat
        data  >000b,high
        bl    @putnum               ; High-Score
        data  >000e,highsc,rambuf,>3030
*--------------------------------------------------------------
* Title "7th Pong"
*--------------------------------------------------------------
        bl    @rle2v                ; RLE Decompress to VRAM
        data  rle_title,>0020,272
*---------------------------------------------------------------
* Credits
*---------------------------------------------------------------
        bl    @putat
        data  >0f08,sweet         ; Short'n'Sweet
        bl    @putat
        data  >1707,credit        ; (c) Retroclouds Team
*--------------------------------------------------------------
* Setup threads for title screen
*--------------------------------------------------------------
        li    r0,play             ; "Press Fire To Play"
        mov   r0,@message         ; Blinking message
        li    r0,timers
        mov   r0,@wtitab          ; Our timer table
        bl    @mkslot
        data  >0040,one_time_delay_music
                                  ; Toggle play message every 10 ticks
        data  >0101,rainbow,eol   ; Swap colors every 1 tick(s)
        movb  @bd1,@tmpvar+1      ; Set toggle
        movb  @bd1,@btihi         ; Set highest slot in use
        bl    @mkhook
        data  start               ; Enable User Hook
*--------------------------------------------------------------
* Speech stuff
*--------------------------------------------------------------
        bl    @spprep             ; Run speech synthesizer
        data  can_you_make_it
main1   b     @tmgr               ; Run scheduler
*--------------------------------------------------------------
* User Hook for starting new game
*--------------------------------------------------------------
start   coc   @wbit11,config      ; ANY key pressed ?
        jne   start2
        coc   @wbit3,config       ; Speech synthesizer busy?
*        
*  Ulgy bugfix to resolve problem that game did not start when speech synth was missing.
*  To stay in 4K ROM limit, I don't want to do anything fancy here.
*
*       jeq   start2              ; Yes, ignore key & wait until speech done
        b     @setup              ; Setup game
start2  b     @hookok             ; Exit hook



*--------------------------------------------------------------
* Setup game
*--------------------------------------------------------------
setup   
        bl    @filv
        data  >0000,>20,768       ; Clear screen
        bl    @vchar
        byte  >00,>0f,08,24       ; Draw vertical bar
        data  eol
*---------------------------------------------------------------
* Init variables
*---------------------------------------------------------------
        li    r0,500              ; Initial score 500 points
        mov   r0,@score1          ; Player 1
        mov   r0,@score2          ; Player 2
        li    r0,900
        mov   r0,@delay           ; Set initial value for delay counter
        li    r0,>00ff            ; Ball direction YX. >ff = -1
        mov   r0,@baldir
        inc   r0
        mov   r0,@balmovy
        clr   @random             ; Use system ROM as random table
        clr   @hintpos            ; Reset scoring position + sprite collision!

        bl    @s8x8               ; 8x8 sprite pattern
        bl    @smag2x             ; 2x Sprite magnification
*---------------------------------------------------------------
* Inline memory copy (cpym2m), saving some code size
*---------------------------------------------------------------
        li    r0,>dd74            ; MOVB *TMP0+,*TMP1+
        mov   r0,@mcloop          ; Setup copy operation
        li    tmp0,romsat
        li    tmp1,ramsat
        li    tmp2,14
        bl    @mcloop             ; Copy SAT from ROM to RAM
*---------------------------------------------------------------
* Copy patterns and setup threads
*---------------------------------------------------------------
        bl    @rle2v              ; Copy sprite patterns to SDT
        data  rle_sprite_patterns,>1000,2
        bl    @mkslot             ; Run game controller every tick
        data  >0001,game_controller  
        data  >0102,rainbow       ; Swap colors every 2 ticks
        data  >0230,clear_hint    ; Clear last hint every 2 seconds
        data  >0305,move_ball_Y   ; Move the ball diagonally
        data  eol
        li    r10,>0300           ; Set highest slot to 3
        bl    @mkhook
        data  player              ; Setup user hook
        clr   r13                 ; Reset copy of VDP status register! 
        bl    @sdprep
        data  title_screen_music,sdopt1
        b     @tmgr               ; Start scheduler
*--------------------------------------------------------------
* End main
*--------------------------------------------------------------


***************************************************************
* Threads and Hooks
***************************************************************


***************************************************************
* Thread: One time delay for starting music
********@*****@*******************@****************************
one_time_delay_music:
        bl    @sdprep
        data  title_screen_music,sdopt1
        bl    @mkslot
        data  >0009,blink,eol     ; Blinking message
        b     @slotok


***************************************************************
* Thread: Blinking message
********@*****@*******************@****************************
blink   neg   @tmpvar             ; Switch toggle
        jlt   blink2
blink1  li    tmp1,>1307          ; Y=19, X=7
        mov   tmp1,@wyx
        mov   @message,tmp1       ; Address of text to display
        bl    @xutst0             ; Display message 
        jmp   blink3
blink2  bl    @hchar
        byte  >13,>00,32,32       ; white space x
        data  eol
blink3  b     @slotok             ; Exit to Thread Scheduler


***************************************************************
* Thread: Rainbow colors
********@*****@*******************@****************************
rainbow mov   @colors,tmp1
        inc   tmp1
        ci    tmp1,>0f
        jle   rainbow_rest
        li    tmp1,>02

rainbow_rest:
        mov   tmp1,@colors
        li    tmp2,>10
        s     tmp1,tmp2
        swpb  tmp2
        movb  tmp2,@ramsat+11     ; Set sprite color
        sla   tmp1,4              ; Change Tiles foreground color
        li    tmp0,>0380          ; Color table is at VDP>0380
        li    tmp2,2
        bl    @xfilv
        b     @slotok             ; Exit to Thread Scheduler


***************************************************************
* Thread: Clear hints
********@*****@*******************@****************************
clear_hint:
        mov   @hintpos,@WYX
        bl    @putstr
        data  erase_hint          ; Show empty string
        clr   @hintpos            ; Enable sprite collision (hack!)
        b     @slotok    

***************************************************************
* Thread: Game controller
********@*****@*******************@****************************
game_controller:
        mov   @score1,r0
        jgt   check_score_p2       ; score P1 > 0, move on
        jmp   game_over_p1         ; Game Over P1
check_score_p2:
        mov   @score2,r0
        jgt   continue             ; Score P2 > 0, move on
        jmp   game_over_p2         ; Game Over P2
continue:
        bl    @display_scores      ; Show scores
        bl    @cpym2v
        data  >0300,ramsat,16      ; Copy shadow SAT to VDP
        b     @slotok 
*--------------------------------------------------------------
* Game over - player 1 has lost
*--------------------------------------------------------------
game_over_p1:
        clr   @score1              ; P1 score = 00000
        mov   @score2,r1
        c     r1,@highsc           ; P2 score > HI score ?
        jlt   game_over_rest
        mov   r1,@highsc           ; New HI score 
        jmp   game_over_rest
*--------------------------------------------------------------
* Game over - player 2 has lost
*--------------------------------------------------------------
game_over_p2:
        clr   @score2              ; P2 score = 00000
        mov   @score1,r1
        c     r1,@highsc           ; P1 score > HI score ?
        jlt   game_over_rest
        mov   r1,@highsc           ; New HI score
*--------------------------------------------------------------
* Game Over - Rest
*--------------------------------------------------------------
game_over_rest:
        bl    @mute
        bl    @spprep              ; Run speech synthesizer
        data  hahaha
        bl    @display_scores
        li    r0,msg_game_over     ; Game over!
        mov   r0,@message          ; Set game over message
        bl    @mkslot
        data  >000a,blink          ; Toggle blinking message
        data  >0103,rainbow
        data  >0260,restart,eol
        li    r10,>0200            ; Set highest slot to 2
        bl    @clhook              ; Clear user hook

        li    r0,4
        mov   r0,@counter          ; Set thread delay counter
        b     @slotok              ; Exit thread
*--------------------------------------------------------------
* Subroutine: Display scores
*--------------------------------------------------------------
display_scores:
        mov   r11,r1               ; Save return address
        bl    @putnum              ; Display score player 1
        data  >0004,score1,rambuf,>3030
        bl    @putnum              ; Display score player 2
        data  >0016,score2,rambuf,>3030
        b     *r1                  ; Return
*--------------------------------------------------------------
* End Thread
*--------------------------------------------------------------


***************************************************************
* Thread: Game over - Back to title screen
********@*****@*******************@****************************
restart:
        dec   @counter            ; Decrease delay counter
        jeq   back_to_title
        b     @slotok             ; Exit thread
back_to_title:
        mov   @highsc,r0         
        b     @runlib             ; Reset game (but keep high score)
*--------------------------------------------------------------
* End Thread
*--------------------------------------------------------------
 


***************************************************************
* Thread: Move ball vertically
********@*****@*******************@****************************
move_ball_y:
        mov   @ramsat+8,r0
        a     @balmovy,r0
        mov   r0,@ramsat+8
        b     @slotok
*--------------------------------------------------------------
* End Thread
*--------------------------------------------------------------



***************************************************************
* Hook: Sprite controll
********@*****@*******************@****************************
player  coc   @wbit11,config      ; Any key pressed ?
        jne   move_ball           ; No, so skip key processing
        mov   @wvrtkb,r1          ; For easy processing
*--------------------------------------------------------------
* Paddle player one
*--------------------------------------------------------------
playl   li    r2,k1up
        coc   r2,r1               ; Up?
        jne   play1a
        sb    @bd1,@ramsat        ; Y=Y-1 
        jmp   play2
play1a  li    r2,k1dn
        coc   r2,r1               ; Down?
        jne   play2
        ab    @bd1,@ramsat        ; Y=Y+1
*--------------------------------------------------------------
* Paddle player two
*--------------------------------------------------------------
play2   li    r2,k2up
        coc   r2,r1               ; Up
        jne   play2a
        sb    @bd1,@ramsat+4      ; Y=Y-1
        jmp   move_ball
play2a  li    r2,k2dn
        coc   r2,r1               ; Down?
        jne   move_ball
        ab    @bd1,@ramsat+4      ; Y=Y+1
*--------------------------------------------------------------
* Move ball
*--------------------------------------------------------------
move_ball:
        coc   @wbit12,config      ; Sprite collision occured?
        jne   is_ball_out         ; No, check if ball is out
*--------------------------------------------------------------
* Ball must bounce
*--------------------------------------------------------------
move_ball_check_up:               ; Don't lose ball at top of screen
        mov   @ramsat+8,r0        ; Get Y
        srl   r0,8                ; Remove X
        ci    r0,50               ; Y < 50 ?
        jgt   move_ball_check_down
        li    r0,>0100
        mov   r0,@balmovy         ; Set Y direction to +1
        jmp   move_ball_continue
*--------------------------------------------------------------
move_ball_check_down:             ; Don't lose ball at screen bottom
        ci    r0,145              ; Y > 145 ?
        jlt   move_ball_continue
        li    r0,>ff00
        mov   r0,@balmovy         ; Set Y direction to -1
*--------------------------------------------------------------
move_ball_continue:
        szc   @wbit12,config      ; Unlatch collision flag in config register
        soc   @wbit6,config       ; Block user hook until next frame! (delay)
        mov   @hintpos,r0         ; Should we process collision ?
        jeq   move_ball_collision ; Yes
        b     @move_ball_x        ; No, must be a "ghost"
move_ball_collision:
        mov   @baldir,r0         
        ci    r0,>00ff            ; Moving ball to the left?
        jne   bounce_left         ; No, was moving right, now bounce left
*--------------------------------------------------------------
* Ball - Bounce from left to right
*--------------------------------------------------------------
bounce_right:
        li    r0,>0001            ; Move ball right
        mov   r0,@baldir
        li    r0,>0a00            ; Set new start position X >0a
        movb  r0,@ramsat+9        ; New position
        li    r0,25               ; Player 1 score +25
        li    r1,bonus25
        li    r2,move_ball_x
        S     r0,@delay           ; Speedup game
        ori   config,>0040        ; Turn on bit 6 - Block user hook
        jmp   hint_player1
*--------------------------------------------------------------
* Ball - Bounce from right to left 
*--------------------------------------------------------------
bounce_left:
        li    r0,>00ff            ; Move ball left
        mov   r0,@baldir
        li    r0,>ea00            ; Set new start position
        movb  r0,@ramsat+9        ; New position
        li    r0,25               ; Player 2 score +25
        li    r1,bonus25
        li    r2,move_ball_x
        S     r0,@delay           ; Speedup game
        ori   config,>0040        ; Turn on bit 6
        jmp   hint_player2
*--------------------------------------------------------------
* Check if ball is out
*--------------------------------------------------------------
is_ball_out:
        mov   @baldir,r0
        mov   @ramsat+8,r1
        andi  r1,>00ff            ; Remove Y position
*--------------------------------------------------------------
* Ball out on left screen side ?
*--------------------------------------------------------------
balout1 ci    r0,>00ff            ; Moving bal to the left?
        jne   balout2             ; No, moving right
        ci    r1,>0005            ; Check if bal X < 0x5 
        jgt   move_ball_x         ; No, so just move ball
*--------------------------------------------------------------
*  Ball out - left
*--------------------------------------------------------------
        li    r0,-100             ; Player 1 score -100
        li    r1,lost100           
        li    r2,new_ball_left    ; New ball on left side
        jmp   hint_player1        ; Display score hint
*--------------------------------------------------------------
* Ball out on right screen side ?
*--------------------------------------------------------------
balout2 ci    r1,>00f5            ; Check if bal X > 0xf5
        jlt   move_ball_x         ; No, so just move ball
*--------------------------------------------------------------
* Ball out - right
*--------------------------------------------------------------
        li    r0,-100             ; Player 2 score -100
        li    r1,lost100
        li    r2,new_ball_right   ; New ball on right side
        jmp   hint_player2        ; Display score hint
*--------------------------------------------------------------
* Show score adjustment player 1
*--------------------------------------------------------------
* R0=Score to add/subtract
* R1=Text to display
* R2=Return address
*--------------------------------------------------------------
hint_player1:
        a     r0,@score1          ; Adjust player 1 score
        mov   @ramsat+8,tmp0
        bl    @px2yx
        mov   tmp0,@wyx           ; Set current YX position
        mov   tmp0,@hintpos       ; For erasing later on
        mov   r1,tmp1
        bl    @xutst0
        mov   @x3000,@timers+10   ; Reset slot 2 thread
        b     *R2                 ; Branch to next routine
*--------------------------------------------------------------
* New ball on left side, moving right
*--------------------------------------------------------------
new_ball_left:
        li    r0,>0001            ; Move ball right
        mov   r0,@baldir
        li    r0,>002f            ; New start position
        mov   r0,@ramsat+8        ; Update X position
        jmp   new_random_y        ; Random Y position
*--------------------------------------------------------------
* Show score adjustment player 2
*--------------------------------------------------------------
* R0=Score to add/subtract
* R1=Text to display
* R2=Return address
*--------------------------------------------------------------
hint_player2:
        a     r0,@score2          ; Adjust player 2 score
        mov   @ramsat+8,tmp0
        bl    @px2yx
        ai    tmp0,>fffe          ; Y-1, X-1
        mov   tmp0,@wyx           ; Set current YX position
        mov   tmp0,@hintpos       ; For erasing later on
        mov   r1,tmp1
        bl    @xutst0
        mov   @x3000,@timers+10   ; Reset slot 2 thread
        b     *R2                 ; Branch to next routine
*--------------------------------------------------------------
* New ball on right side, moving left
*--------------------------------------------------------------
new_ball_right:
        li    r0,>00ff            ; Move ball left
        mov   r0,@baldir
        li    r0,>00a0            ; New start position
        mov   r0,@ramsat+8        ; Update X position
*--------------------------------------------------------------
* Get random Y position for new ball
*--------------------------------------------------------------
new_random_y:
        mov   @random,r0          ; Get address of random 
        movb  *r0,r0              ; Get random byte
        inc   @random             ; Next byte in random table
        andi  r0,>a000            ; Make sure Y is <= a0
        ai    r0,>1000            ; Minimum Y=1
        movb  r0,@ramsat+8        ; Update Y position 
*--------------------------------------------------------------
* Get new X position for ball
*--------------------------------------------------------------
move_ball_x:
        ab    @baldir+1,@ramsat+9 ; Move ball
*--------------------------------------------------------------
* Exit hook
*--------------------------------------------------------------
playex  mov   @delay,r2           ; Load delay value
dodelay dec   r2
        jne   dodelay 
        b     @hookok
*--------------------------------------------------------------
* End Thread
*--------------------------------------------------------------


***************************************************************
* Data
***************************************************************
x3000   data  >1800                   ; Delay value for timer 2

*--------------------------------------------------------------
* Data - RLE Compressed title "7th Pong"
*--------------------------------------------------------------
* Compressed 272 bytes / Uncompressed 384 bytes / 70.8% size
rle_title:
        byte  >84,>00,>89,>07,>82,>00
        byte  >82,>07,>81,>03,>82,>00
        byte  >82,>07,>81,>03,>8d,>00
        byte  >81,>09,>86,>07,>82,>00
        byte  >81,>07,>81,>0f,>82,>00
        byte  >81,>01,>81,>07,>81,>08
        byte  >82,>00,>81,>01,>82,>07
        byte  >8f,>00,>81,>0f,>84,>00
        byte  >81,>09,>81,>03,>82,>00
        byte  >82,>07,>81,>08,>82,>00
        byte  >81,>08,>82,>00,>81,>09
        byte  >8d,>00,>81,>0f,>84,>00
        byte  >81,>0f,>81,>00,>81,>08
        byte  >82,>00,>81,>08,>81,>00
        byte  >81,>08,>83,>00,>81,>06
        byte  >82,>00,>81,>09,>8b,>00
        byte  >81,>0e,>84,>07,>81,>0f
        byte  >82,>00,>81,>01,>82,>07
        byte  >81,>02,>81,>00,>81,>01
        byte  >83,>07,>81,>04,>82,>00
        byte  >81,>0f,>9d,>00,>81,>09
        byte  >81,>0f,>87,>00,>8a,>07
        byte  >96,>00,>81,>09,>86,>07
        byte  >83,>00,>81,>09,>84,>07
        byte  >83,>00,>84,>07,>83,>00
        byte  >84,>07,>84,>00,>81,>08
        byte  >85,>00,>83,>07,>81,>0f
        byte  >82,>00,>81,>07,>81,>00
        byte  >81,>09,>81,>00,>81,>0f
        byte  >84,>00,>81,>09,>81,>00
        byte  >81,>0f,>81,>00,>83,>07
        byte  >81,>09,>83,>00,>81,>08
        byte  >84,>00,>81,>08,>82,>00
        byte  >81,>05,>82,>00,>81,>0b
        byte  >81,>07,>81,>0a,>82,>05
        byte  >83,>00,>81,>08,>82,>00
        byte  >81,>0f,>81,>00,>81,>0e
        byte  >81,>07,>81,>0f,>82,>00
        byte  >81,>0a,>82,>00,>81,>01
        byte  >84,>07,>81,>02,>83,>00
        byte  >81,>09,>84,>07,>81,>0f
        byte  >81,>05,>83,>07,>81,>04
        byte  >82,>00,>81,>09,>83,>07
        byte  >82,>00,>81,>0f,>97,>00
        byte  >81,>09,>81,>0f,>85,>07
        byte  >81,>0f

*-------------------------------------------------------------
* RLE encoded character definitions for title "7th Pong"
*-------------------------------------------------------------
* Compressed 84 bytes / Uncompressed 120 bytes / 70% size
rle_chars:
        byte >87,>08,>01,>0f                         ; 1
        byte >87,>08,>01,>f8                         ; 2
        byte >87,>00,>01,>f8                         ; 3
        byte >87,>08,>01,>ff                         ; 4
        byte >88,>01                                 ; 5
        byte >83,>00,>05,>80,>40,>20,>10,>08         ; 6 
        byte >87,>00,>01,>ff                         ; 7
        byte >88,>08                                 ; 8
        byte >20,>80,>40,>20,>10,>08,>04,>02,>01     ; 9
        byte >80,>40,>20,>10,>10,>20,>40,>80         ; 10
        byte >01,>02,>04,>08,>08,>04,>02,>01         ; 11
        byte >3c,>42,>99,>a1,>a1,>99,>42,>3c         ; 12
        byte >88,>00                                 ; 13
        byte >10,>01,>02,>04,>08,>10,>20,>40,>ff     ; 14
        byte >01,>02,>04,>08,>10,>20,>40,>80         ; 15


*-------------------------------------------------------------
* RLE encoded sprite patterns
*-------------------------------------------------------------
* Compressed 2 bytes / Uncompressed 10 bytes / 20% size
rle_sprite_patterns:
        byte  >8a,>18                   ; Paddle sprite + Ball sprite



*-------------------------------------------------------------
* Title screen messages
*-------------------------------------------------------------
high    byte 3
        text "HI-"
sweet   byte 16 
        text "4K ATARIAGE 2018"
play    byte 18
        text "Press Fire To Play"
credit  byte 18
        byte 12                         ; Copyright sign
        text " Retroclouds Team"
*-------------------------------------------------------------
* Game screen messages
*-------------------------------------------------------------
msg_game_over:
        byte  18
        text  'G A M E  O V E R !'  

bonus25:
        byte  4
        text  ' +25'

lost100:
        byte  4
        text  '-100'
        
erase_hint:
        byte  4
        data  >0000,>0000

*-------------------------------------------------------------
* Sprite table
*-------------------------------------------------------------
romsat  data  >4f05,>000f         ; Paddle 1
        data  >4ff0,>000f         ; Paddle 2
        data  >3f70,>010f         ; Ball  
        data  >d000               ; EOF SAT


* ##########################################################################
* # Dump of LPC binary file "can_you_make_it.bin"
* ##########################################################################
can_you_make_it:
        byte talkon
        byte >04,>18,>B5,>8D,>01,>DD,>B0,>14
        byte >BF,>65,>36,>8B,>A8,>3D,>9C,>5E
        byte >CA,>C4,>75,>C9,>30,>7B,>1E,>35
        byte >F5,>25,>C3,>E8,>A5,>CD,>C5,>1A
        byte >0F,>73,>84,>14,>65,>5F,>DC,>9C
        byte >AA,>C8,>52,>2B,>4E,>F1,>8A,>61
        byte >77,>8E,>28,>C3,>9F,>CE,>45,>D5
        byte >6A,>0F,>7F,>F9,>20,>B6,>68,>3C
        byte >82,>5E,>8A,>58,>AD,>CB,>08,>6B
        byte >34,>09,>91,>36,>23,>2E,>5E,>22
        byte >94,>DB,>B4,>AC,>06,>B6,>30,>49
        byte >52,>B2,>16,>49,>D2,>35,>6E,>CB
        byte >9B,>15,>8A,>50,>67,>23,>2B,>59
        byte >DD,>C8,>DA,>8C,>B4,>95,>34,>13
        byte >6B,>33,>92,>9E,>D3,>54,>A2,>CD
        byte >08,>7B,>74,>15,>EB,>36,>C3,>1F
        byte >C9,>94,>AC,>9B,>34,>BF,>07,>26
        byte >E9,>6E,>12,>BC,>9E,>59,>4D,>D5
        byte >09,>01,>84,>94,>66,>40,>37,>C4
        byte >C5,>6A,>81,>D8,>B3,>9B,>36,>B3
        byte >58,>D6,>CC,>6E,>D2,>8C,>E2,>44
        byte >23,>26,>49,>33,>8B,>17,>B1,>18
        byte >27,>CA,>CD,>8E,>2D,>7A,>E4,>02
        byte >02,>16,>09,>53,>46,>33,>CA,>9E
        byte >95,>C4,>18,>5D,>07,>99,>E7,>12
        byte >61,>36,>E3,>6C,>56,>75,>11,>90
        byte >A4,>E9,>03,>BA,>0C,>7B,>40,>97
        byte >00,>00
        byte talkof 

* ##########################################################################
* # Dump of LPC binary file "hahaha.bin"
* ##########################################################################
hahaha  byte talkon 
        byte >4E,>2D,>9B,>2B,>2C,>EB,>14,>BE
        byte >6C,>1A,>AB,>4A,>32,>98,>72,>B4
        byte >24,>62,>CE,>60,>4B,>D6,>F2,>CA
        byte >A8,>49,>CA,>C5,>AD,>2A,>CC,>20
        byte >20,>26,>F1,>C1,>96,>6A,>2D,>13
        byte >71,>06,>53,>A6,>15,>CF,>C4,>1E
        byte >6C,>29,>DE,>5C,>93,>7A,>88,>A5
        byte >45,>53,>57,>D4,>A2,>A7,>2E,>65
        byte >1B,>72,>87,>98,>B7,>A5,>74,>45
        byte >1B,>5C,>89,>36,>DC,>93,>64,>08
        byte >A5,>78,>4B,>56,>BD,>A1,>A7,>61
        byte >E9,>5D,>61,>9D,>93,>BA,>7B,>46
        byte >49,>1D,>7A,>EA,>5A,>DE,>15,>75
        byte >48,>A5,>FA,>50,>55,>DC,>C1,>D7
        byte >64,>4B,>31,>69,>87,>50,>B3,>8D
        byte >44,>D6,>1B,>72,>AD,>BE,>38,>99
        byte >64,>C8,>A5,>C7,>50,>65,>93,>A1
        byte >94,>E2,>8B,>E3,>49,>86,>5E,>AA
        byte >0D,>4E,>C6,>19,>66,>A9,>36,>78
        byte >99,>A4,>D9,>25,>EB,>D0,>65,>93
        byte >E4,>96,>62,>8D,>1F,>A9,>BC,>A7
        byte >7D,>1C,>3E,>A0,>CB,>30
        byte talkof

* ##########################################################################
* # Title screen music "ballblazer" sample by OLD CS1
* ##########################################################################
title_screen_music:
        byte >05,>C7,>08,>DF,>E3,>F0,>09                      * G#33, P3
        byte >01,>F8,>03
        byte >03,>CA,>05,>F0,>09                              * D#43
        byte >01,>F8,>03
        byte >0A,>8B,>23,>93,>AC,>1A,>B3,>CC,>04,>E5,>F3,>03  * G11, C22, F#43, W1
        byte >02,>E3,>F0,>06                                  * P3
        byte >03,>9F,>BF,>F8,>03
        byte >03,>C7,>08,>F0,>09                              * G#33
        byte >01,>FF,>12
        byte >03,>CA,>05,>F0,>09                              * D#43
        byte >01,>F8,>03
        byte >04,>C5,>05,>E5,>F3,>03                          * E43, W1
        byte >02,>E3,>F0,>06                                  * P3
        byte >01,>F8,>03
        byte >03,>C9,>03,>F0,>09                              * B43
        byte >01,>F8,>03
        byte >03,>C7,>08,>F0,>09                              * G#33
        byte >01,>F8,>03
        byte >03,>CA,>05,>F0,>09                              * D#43
        byte >01,>F8,>03
        byte >06,>93,>B3,>CC,>04,>E5,>F3,>03                  * F#43, W1
        byte >02,>E3,>F0,>06                                  * P3
        byte >03,>9F,>BF,>F8,>03
        byte >03,>C7,>08,>F0,>09                              * G#33
        byte >01,>FF,>12
        byte >03,>CA,>05,>F0,>09                              * D#43
        byte >01,>F8,>03
        byte >04,>C5,>06,>E5,>F3,>03                          * C#43, W1
        byte >02,>E3,>F0,>06                                  * P3
        byte >01,>F8,>03
        byte >03,>C1,>07,>F0,>09                              * B33
        byte >01,>F8,>03
        byte >03,>C7,>08,>F0,>09                              * G#33
        byte >01,>F8,>03
        byte >03,>CA,>05,>F0,>09                              * D#43
        byte >01,>F8,>03
        byte >06,>93,>B3,>CC,>04,>E5,>F3,>03                  * F#43, W1
        byte >02,>E3,>F0,>06                                  * P3
        byte >03,>9F,>BF,>F8,>03
        byte >03,>C7,>08,>F0,>09                              * G#33
        byte >01,>FF,>12
        byte >03,>CA,>05,>F0,>09                              * D#43
        byte >01,>F8,>03
        byte >04,>C5,>05,>E5,>F3,>03                          * E43, W1
        byte >02,>E3,>F0,>06                                  * P3
        byte >01,>F8,>03
        byte >03,>C9,>03,>F0,>09                              * B43
        byte >01,>F8,>03
        byte >0A,>8C,>1F,>93,>AE,>12,>B3,>C5,>06,>E3,>F0,>12  * A11, F#22, C#43, P3
        byte >03,>9F,>BF,>FF,>06
        byte >0A,>8B,>23,>93,>A3,>15,>B3,>C1,>07,>E5,>F3,>03  * G11, E22, B33, W1
        byte >02,>E3,>F0,>0F                                  * P3
        byte >03,>9F,>BF,>FF,>06
        byte >09,>8C,>1F,>93,>A0,>14,>B3,>CA,>0A,>F0,>04      * A11, F22, E33
        byte >03,>9F,>BF,>F8,>02
        byte >07,>8B,>23,>93,>A8,>16,>B3,>F0,>04              * G11, D#22
        byte >03,>9F,>BF,>FF,>0E
        byte >08,>8C,>1F,>93,>AC,>1A,>B3,>E5,>F3,>03          * A11, C22, W1
        byte >02,>E3,>F0,>0C                                  * P3
        byte >00
