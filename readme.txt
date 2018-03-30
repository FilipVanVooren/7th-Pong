7th Pong
~~~~~~~~

This archive contains my arcade game "7th Pong" for the Texas Instruments 
TI-99/4a Home Computer.  I wrote it in TMS9900 assembly language for the 
Atariage 4K Short'n'Sweet game contest (2018 edition). 

Details about the contest and other submissions can be found here: 
      http://atariage.com/forums/topic/273371-4k-shortnsweet-game-contest/
      http://atariage.com/forums/topic/276364-4k-shortnsweet-game-contest-submissions/


Objective was to write a game, that -including code size- does not occupy more 
than 4092 bytes of ROM/RAM memory. 7th Pong uses 64 bytes of scratch pad RAM.
Total code size is 4122 bytes, including the cartridge header of 30 bytes.


7th Pong is a 2 player game that runs on the unexpanded TI-99/4A home computer.
No additional RAM is required to run the game, joysticks are supported but 
not required. 
The speech synthesizer is supported as well, but not required.

Basically 7th Pong is a showcase for my spectra2 Arcade Game library.
The game features music and speech, but has no sound effects. 

The game has been tested on the real deal and in emulation using following
emulators:

   classic99  -> http://www.harmlesslion.com/software/Classic99
   js99er     -> http://js99er.net/   



*** WARNING *** WARNING *** WARNING *** WARNING ***
The game has a strobe effect both on the game title screen and during gameplay.
The strobe effect may cause seizures. If you are sensitive to fast shifting
color variations and fast repetitive music, then please do not play the game. 
No Joke!



Credits
-------

- Music sample taken of "OLD CS1" rendition of Ballblazer
- Speech samples taken from "Bluewizzard"
- Cartridge label designed by "Ciro" of Team Retroclouds 
- Cartridge picture by "Ciro" of Team Retrocouds 



Game play
---------

You are trapped in the universe of the 7th Pong.
Normal physics as known in our universe do not apply. 

To start the game press the fire button on one of the joysticks or press 
the space bar when playing with keyboard.

Both players start with 500 points. If you hit the ball with your paddle, then
you get +25 points. If you miss the ball, then you lose -100 points. The game
ends when one of both players has a score of 0 points.

Player 1 (Joystick) or keyboard
   E = Move paddle up
   X = Move paddle down


Player 2 (Joystick) or keyboard
   O = Move paddle up
   , = Move paddle down


To quit the game press and hold "FCTN + Quit"



Source code
-----------

Download the source code from Github:

      https://github.com/FilipVanVooren/7th-Pong


To assemble the source code, you should use the excellent xas99 cross-assembler 
by Ralph Benziger. You can find the assembler here:

      http://endlos99.github.io/xdt99/


Use the following command to assemble:

      cd source
      xas99.py -b 7thpong_cart.asm -L 7thpong_cart.lst


To run the cartridge image in classic99:
      1) mv 7thpong_cart_6000.bin 7thpongc.bin
      2) In classic99 top menu: Cartridge -> User -> Open -> <Pick 7thpongc.bin>


To run the cartridge image in js99er:
      1) Click on "Open Cartridge" button -> <Pick 7thpong_cart_6000.bin> 
