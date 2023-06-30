\ ===================================================================
\           File: opengllib-1.21.fs
\         Author: Jeff Molofee
\  Linux Version: Ti Leggett
\ gForth Version: Timothy Trussell, 08/01/2010
\    Description: Lines, timing, ortho, sound
\   Forth System: gforth-0.7.0
\   Linux System: Ubuntu v10.04 LTS i386, kernel 2.6.31-24
\   C++ Compiler: gcc version 4.4.3 (Ubuntu 4.4.3-4ubuntu5)
\ ===================================================================
\                       NeHe Productions
\                    http://nehe.gamedev.net/
\ ===================================================================
\                   OpenGL Tutorial Lesson 21
\ ===================================================================
\ This code was created by Jeff Molofee '99
\ (ported to Linux/SDL by Ti Leggett '01)
\ March, 2013 adapted for Win32Forth by Jos v.d.Ven
\ Visit Jeff at http://nehe.gamedev.net/
\ ===================================================================

vocabulary Lesson21  also Lesson21 definitions

\ ---[ Variables ]---------------------------------------------------

0 value grid-filled                       \ done filling in the grid?
true value gameover                                \ is the game over?
TRUE value anti                  \ use anti-aliasing to smooth lines?

0 value enemy-delay
3 value speed-adjust                    \ for really slow video cards
5 value player-lives
1 value internal-level                          \ internal game level
1 value displayed-level                        \ displayed game level
1 value game-stage
false value SuperCrazy                               \ SuperCrazy flag


variable baselist                    \ base display list for the font

0 value Chunk                                                 \ audio
0 value Music                                                 \ audio

\ Create a structure for our player

struct{
  cell   .fx                           \ fine movement position
  cell   .fy
  cell   .x                           \ current player position
  cell   .y
  b/float  .spin                                 \ spin direction
}struct object%
sizeof object% constant /object%

\ Allocate memory space for the following structures
here /object% allot constant player                   \ player information
here /object% 9 * allot constant enemies[]             \ enemy information
here /object% allot constant hourglass

\ stepping values for slow video adjustment
create steps[] 1 , 2 , 4 , 5 , 10 , 20 ,

create hline[] here 11 cells 11 * dup allot 0 fill
create vline[] here 11 cells 11 * dup allot 0 fill


: Init-Game-Vars ( -- )
  0 to enemy-delay
  3 to speed-adjust
  5 to player-lives
  1 to internal-level
  1 to displayed-level
  1 to game-stage
  hline[] 11 cells 11 * 0 fill
  vline[] 11 cells 11 * 0 fill
  player /object%  0 fill
  hourglass /object% 0 fill
  enemies[] /object% 9 * 0 fill
;

\ ---[ Array Index Functions ]---------------------------------------
\ Index functions to access the arrays

: enemies-ndx ( n -- *enemies[n] ) 9 MOD /object% * enemies[] + ;
: steps-ndx ( n -- *steps[n] )     6 MOD cells steps[] + ;
: hline-ndx ( x y -- *hline[n] )  11 cells * swap cells + hline[] + ;
: vline-ndx ( x y -- *vline[n] )  11 cells * swap cells + vline[] + ;

: ResetObjects ( -- )
  0 player .x !            \ reset player x to far left of the screen
  0 player .y !                     \ reset player y to top of screen
  0 player .fx !                            \ set fine x pos to match
  0 player .fy !                            \ set fine y pos to match
  \ loop thru all the enemies
  game-stage internal-level * 0 do
    \ Set random X position             Set fine x to match
    6 random 5 + dup i enemies-ndx .x ! 60 * i enemies-ndx .fx !
    \ Set random y position             Set fine y to match
    11 random    dup i enemies-ndx .y ! 40 * i enemies-ndx .fy !
  loop
;

\ ---[ LoadGLTextures ]----------------------------------------------
\ function to load in bitmap as a GL texture

: LoadGLTextures ( -- )
\ create variables for storing surface pointers and return flag
  2 MallocTextures    \ MallocTextures allocates only when not done
  NumTextures texture[] gl-gen-textures       \ create the textures
  \ Attempt to load the texture images by using a mapping
  s" font.bmp"  0 ahndl LoadGLTexture                     \ ndx = 0
  s" image.bmp" 1 ahndl LoadGLTexture                     \ ndx = 1
;

\ ---[ HandleKeyPress ]----------------------------------------------
\ function to handle key press events:
:long$ h21$
$| About lesson 21:
$|
$| Key-list for the available functions in this lesson:
$|
$| ESC      exits the lesson
$| w        toggles between fullscreen and windowed modes
$| a        toggles anti-aliasing
$| s        toggles the super crazy mode for a
$|          little random steering effect.
$| SPACE    starts the game
$| Right    moves player right
$| Left     moves player left
$| Up       moves player up
$| Down     moves player down
  ;long$


: HandleKeyPress ( VK_key  -- )
  case
   \ SDLK_ESCAPE of TRUE to opengl-exit-flag endof
    ascii W     of start/end-fullscreen                 endof
    ascii A     of anti if 0 else 1 then to anti	endof
    ascii S     of SuperCrazy not to SuperCrazy		endof

    BL          of     gameover if
                       FALSE to gameover
                       TRUE to grid-filled
                       1 to internal-level
                       1 to displayed-level
                       1 to game-stage
                       5 to player-lives
                     then
							endof
    VK_RIGHT    of player .x @ 10 <
                   player .fx @ player .x @ 60 * = AND
                   player .fy @ player .y @ 40 * = AND if
                     \ Mark The Current Horizontal Border As Filled
                     TRUE player .x @ player .y @ hline-ndx !
                     1 player .x +!               \ move player right
                   then
                                                        endof
    VK_LEFT     of player .x @ 0>
                   player .fx @ player .x @ 60 * = AND
                   player .fy @ player .y @ 40 * = AND if
                   -1 player .x +!               \ move player left
                   \ Mark The Current Horizontal Border As Filled
                   TRUE player .x @ player .y @ hline-ndx !
                   then
                                                        endof
    VK_UP       of player .y @ 0>
                   player .fx @ player .x @ 60 * = AND
                   player .fy @ player .y @ 40 * = AND if
                     -1 player .y +!                 \ move player up
		    \ Mark The Current Vertical Border As Filled
                     TRUE player .x @ player .y @ vline-ndx !
                   then
                                                       endof
    VK_DOWN     of player .y @ 10 <
                   player .fx @ player .x @ 60 * = AND
                   player .fy @ player .y @ 40 * = AND if
		   \ Mark The Current Vertical Border As Filled
                   TRUE player .x @ player .y @ vline-ndx !
                   1 player .y +!                \ move player down
                   then
                                                      endof
                   h21$ ShowHelp

  endcase
;


\ ---[ BuildFont ]---------------------------------------------------
\ Function to build our OpenGL font list (from Lesson 17)

fvariable bf-cx                         \ holds our x character coord
fvariable bf-cy                         \ holds our y character coord


: BuildFont ( -- )
  \ Create 256 display lists
  256 gl-gen-lists baselist !
  \ Select our font texture
  GL_TEXTURE_2D 0 texture-ndx @ gl-bind-texture
  \ Loop thru all 256 lists
  256 0 do
    \ X Position of current character with a 0.01e correction
     i 16 MOD S>F 16e F/  0.01e F+ bf-cx F!     \ Moves to the right
    \ Y Position of current character
     i 16 /  S>F   16e F/      bf-cy F!                 \ Moves down
    \ Start building a list
     baselist @ i + GL_COMPILE gl-new-list
      GL_QUADS gl-begin               \ use a quad for each character
        \ texture coordinate - bottom left
        bf-cx F@   1e bf-cy F@ F- 0.0625e F- gl-tex-coord-2f
        \ vertex coordinate - bottom left
        0 16 gl-vertex-2i
        \ texture coordinate - bottom right
        bf-cx F@ 0.0625e F+   1e bf-cy F@ F- 0.0625e F- gl-tex-coord-2f
        \ vertex coordinate - bottom right
        16 16 gl-vertex-2i
        \ texture coordinate - top right
        bf-cx F@  0.0625e F+   1e bf-cy F@  F-  gl-tex-coord-2f
        \ vertex coordinate - top right
        16 0 gl-vertex-2i
        \ texture coordinate - top left
        bf-cx F@  1e bf-cy F@  F-  gl-tex-coord-2f  \ cx,1.0f-cy-0.001f
        \ vertex coordinate - top left
        0 0 gl-vertex-2i
      gl-end
      \ Move to the right of the character
      15e 0e 0e gl-translate-d
    gl-end-list
  loop
;

\ ---[ glPrint ]-----------------------------------------------------
\ Prints a string
\ <set> selects Normal <0>, or Italic <1> from the font.bmp image.

: glPrint { _x _y *str _len _set -- }
  _set 1 > if 1 to _set then
  GL_TEXTURE_2D gl-enable                    \ Enable texture mapping
  GL_TEXTURE_2D 0 texture-ndx @ gl-bind-texture  \ Select our texture
  GL_DEPTH_TEST gl-disable                    \ Disable depth testing
  gl-load-identity                       \ Reset the modelview matrix
  _x S>F _y S>F 0e gl-translate-d  \ Position text (0,0==bottom left)
  baselist @ 32 - 128 _set * + gl-list-base     \ Choose the font set
  _set 0= if                     \ if set 0 is used, enlarge the font
    1.5e 2e 1e gl-scale-f            \ scale width and height of font
  then
  _len GL_BYTE *str gl-call-lists                    \ Write the text
  GL_TEXTURE_2D gl-disable                  \ Disable texture mapping
  GL_DEPTH_TEST gl-enable                   \ Re-enable depth testing
;

\ ---[ Set the viewpoint ]-------------------------------------------

: set-viewpoint
   GL_PROJECTION glMatrixMode          \ Select The Projection Matrix
   glLoadIdentity
   0.0e widthViewport s>f heightViewport 17 + s>f
   0.0e -1.0e 1.0e glOrtho \ Create Ortho in window View (0,0 At Top Left)
   GL_MODELVIEW glMatrixMode           \ Select The Projection Matrix
   glLoadIdentity
 ;

\ ---[ InitGL ]------------------------------------------------------
\ general OpenGL initialization function

: InitGL ( -- boolean )
    set-viewpoint
  \ Load in the texture
    LoadGLTextures
    BuildFont                                        \ build the font
    GL_SMOOTH gl-shade-model                  \ Enable smooth shading
    0e 0e 0e 0.5e gl-clear-color           \ Set the background black
    1e gl-clear-depth                            \ Depth buffer setup
    GL_LINE_SMOOTH_HINT GL_NICEST gl-hint     \ set line antialiasing
    GL_BLEND gl-enable                              \ Enable blending
    GL_SRC_ALPHA GL_ONE_MINUS_SRC_ALPHA gl-blend-func    \ blend type
;

\ ---[ PlaySound ]---------------------------------------------------
\ Starts (or stops) a sound.
\ To stop a sound, call PlaySound with 0 0 0 as parameters.

: PlaySound { *sound _len fdwSound  -- }
   fdwSound  0
   _len 0>
     if   *sound _len asciiz
     else  0
     then
   call PlaySound drop
 ;

\ ---[ temp$ ]-------------------------------------------------------
\ A work buffer for string manipulations. Should always be considered
\ to be temporary.

create temp$ here 256 dup allot 0 fill           \ temp string buffer

\ ---[ IntToStr ]----------------------------------------------------
\ Converts an integer value to a string; returns addr/len

: IntToStr ( n -- str len ) 0 <# #S #> ;

\ ---[ concat-string ]-----------------------------------------------
\ A basic string concatenation function, to add one string to another

: concat-string { *str _len *dst -- }
  *str *dst 1+ *dst C@ + _len cmove
  *dst C@ _len + *dst C!                \ use *dst[0] as length byte
;

\ ---[ set-string ]--------------------------------------------------
\ Copies the *src string to the *dst address. *dst[0] is the length.

: set-string ( *str len *dst -- )
  0 over C!                                         \ set length to 0
  concat-string                                   \ copy *str to *dst
;

\ ---[ DrawGLScene ]-------------------------------------------------
\ Here goes our drawing code

: Show-Game-Name ( -- )
  1e 0.5e 1e gl-color-3f                        \ set color to purple
  207 24 s" GRID CRAZY" 0 glPrint
;

: Show-Level ( -- )
  1e 1e 0e gl-color-3f                          \ set color to yellow
  s" Level: " temp$ set-string
  displayed-level IntToStr temp$ concat-string
  20 20 temp$ dup 1+ swap C@ 1 glPrint

;

: Show-Stage ( -- )
  s" Stage: " temp$ set-string
  game-stage IntToStr temp$ concat-string
  20 40 temp$ dup 1+ swap C@ 1 glPrint
;

: Show-GameOver ( -- )
    255 random 255 random 255 random gl-color-3ub \ pick random color
    472 20 s" GAME OVER" 1 glPrint
    456 40 s" PRESS SPACE" 1 glPrint
;

: Draw-Player ( -- )
  \ Start Drawing Our Player Using Lines
  \  game-stage internal-level * 0 do                 \ Was in GForth
    player-lives 1- 0 max 0 ?do                    \ Adapted for Wf32
    gl-load-identity                                 \ reset the view
    490e i 40 * S>F F+ 40e 0e gl-translate-f \ move to right of title
    player .spin F@ FNEGATE 0e 0e 1e gl-rotate-f \ spin counter clock
    0e 1e 0e gl-color-3f            \ set player color to light green
    GL_LINES gl-begin
      -5e -5e gl-vertex-2d                       \ top left of player
       5e  5e gl-vertex-2d                   \ bottom right of player
       5e -5e gl-vertex-2d                      \ top right of player
      -5e  5e gl-vertex-2d                    \ bottom left of player
    gl-end

    \ Rotate counter-clockwise
    player .spin F@ FNEGATE 0.5e F* 0e 0e 1e gl-rotate-f
    \ set player color to dark green
    0e 0.75e 0e gl-color-3f

    GL_LINES gl-begin
      -7e  0e gl-vertex-2d                    \ left center of player
       7e  0e gl-vertex-2d                   \ right center of player
       0e -7e gl-vertex-2d                     \ top center of player
       0e  7e gl-vertex-2d                  \ bottom center of player
    gl-end
  loop
;

: Draw-Hourglass ( -- )
  gl-load-identity                       \ reset the modelview matrix
  \ move to the fine hourglass position
  20 hourglass .x @ 60 * + S>F
  70 hourglass .y @ 40 * + S>F 0e gl-translate-f
  hourglass .spin F@ 0e 0e 1e gl-rotate-f          \ rotate clockwise
  255 random 255 random 255 random gl-color-3ub        \ random color
  GL_LINES gl-begin         \ Start drawing the hourglass using lines
    -5e -5e gl-vertex-2d                      \ top left of hourglass
     5e  5e gl-vertex-2d                  \ bottom right of hourglass
     5e -5e gl-vertex-2d                     \ top right of hourglass
    -5e  5e gl-vertex-2d                   \ bottom left of hourglass
    -5e  5e gl-vertex-2d                   \ bottom left of hourglass
     5e  5e gl-vertex-2d                  \ bottom right of hourglass
    -5e -5e gl-vertex-2d                      \ top left of hourglass
     5e -5e gl-vertex-2d                     \ top right of hourglass
  gl-end
;

: Draw-Enemies ( -- )
  game-stage internal-level * 0 do
    gl-load-identity                     \ reset the modelview matrix
    i enemies-ndx .fx @ S>F 20e F+
    i enemies-ndx .fy @ S>F 70e F+ 0e gl-translate-f
    1e 0.5e 05e gl-color-3f                    \ make enemy body pink
    GL_LINES gl-begin                                    \ draw enemy
       0e -7e gl-vertex-2d                        \ top point of body
      -7e  0e gl-vertex-2d                       \ left point of body
      -7e  0e gl-vertex-2d                       \ left point of body
       0e  7e gl-vertex-2d                     \ bottom point of body
       0e  7e gl-vertex-2d                     \ bottom point of body
       7e  0e gl-vertex-2d                      \ right point of body
       7e  0e gl-vertex-2d                      \ right point of body
       0e -7e gl-vertex-2d                        \ top point of body
    gl-end

    i enemies-ndx .spin F@ 0e 0e 1e gl-rotate-f  \ rotate enemy blade
    1e 0e 0e gl-color-3f                       \ make enemy blade red

    GL_LINES gl-begin
      -7e -7e gl-vertex-2d                        \ top left of enemy
       7e  7e gl-vertex-2d                    \ bottom right of enemy
      -7e  7e gl-vertex-2d                     \ bottom left of enemy
       7e -7e gl-vertex-2d                       \ top right of enemy
    gl-end
  loop
;

: DrawGLScene ( -- )
  \ Clear the screen and the depth buffer
  GL_COLOR_BUFFER_BIT GL_DEPTH_BUFFER_BIT OR gl-clear

  gl-load-identity                                   \ restore matrix

  Show-Game-Name
  Show-Level
  Show-Stage

  gameover if
    Show-GameOver
  then

  Draw-Player

  TRUE to grid-filled                    \ set to TRUE before testing
  2e gl-line-width                  \ set line width for cells to 2.0
  GL_LINE_SMOOTH gl-disable                   \ disable anti-aliasing
  gl-load-identity               \ reset the current modelview matrix
  11 0 do
    11 0 do
      0e 0.5e 1e gl-color-3f
      j i hline-ndx @ if       \ has the horizontal line been traced?
        1e 1e 1e gl-color-3f
      then
      j 10 < if                    \ do not draw too far to the right
        j i hline-ndx @ 0= if
          FALSE to grid-filled    \ the horizontal line is not filled
        then
        GL_LINES gl-begin
          \ Left side of horizontal line
          20e j 60 * S>F F+ 70e i 40 * S>F F+ gl-vertex-2d
          \ Right side of horizontal line
          80e j 60 * S>F F+ 70e i 40 * S>F F+ gl-vertex-2d
        gl-end
      then
      0e 0.5e 1e gl-color-3f                 \ set line color to blue
      j i vline-ndx @ if         \ has the vertical line been traced?
        1e 1e 1e gl-color-3f                \ set line color to white
      then
      i 10 < if                            \ do not draw too far down
        j i vline-ndx @ 0= if      \ if a vertical line is not filled
          FALSE to grid-filled
        then
        GL_LINES gl-begin
          \ Left side of horizontal line
          20e j 60 * S>F F+ 70e i 40 * S>F F+ gl-vertex-2d
          \ Right side of horizontal line
          20e j 60 * S>F F+ 110e i 40 * S>F F+ gl-vertex-2d
        gl-end
      then
      GL_TEXTURE_2D gl-enable                \ Enable texture mapping
      1e 1e 1e gl-color-3f                  \ Set color to full white
      GL_TEXTURE_2D 1 texture-ndx @ gl-bind-texture
      j 10 < i 10 < AND if       \ If in bounds, fill in traced boxes
        \ Are all sides in the box traced?
        j i hline-ndx @
        j i 1+ hline-ndx @ AND
        j i vline-ndx @ AND
        j 1+ i vline-ndx @ AND if
          GL_QUADS gl-begin                    \ Draw a textured quad
            j S>F 10e F/ 0.1e F+
            1e i S>F 10e F/ F- gl-tex-coord-2f            \ top right
            20 j 60 * + 59 + S>F 70 i 40 * + 1 + S>F gl-vertex-2d

            j S>F 10e F/
            1e i S>F 10e F/ F- gl-tex-coord-2f             \ top left
            20 j 60 * + 1 + S>F 70 i 40 * + 1 + S>F gl-vertex-2d

            j S>F 10e F/
            1e i S>F 10e F/ 0.1e F+ F- gl-tex-coord-2f  \ bottom left
            20 j 60 * + 1 + S>F 70 i 40 * + 39 + S>F gl-vertex-2d

            j S>F 10e F/ 0.1e F+
            1e i S>F 10e F/ 0.1e F+ F- gl-tex-coord-2f \ bottom right
            20 j 60 * + 59 + S>F 70 i 40 * + 39 + S>F gl-vertex-2d
          gl-end

        then
      then
      GL_TEXTURE_2D gl-disable              \ Disable texture mapping
    loop
  loop

  1e gl-line-width                        \ set the line width to 1.0

  anti if
    GL_LINE_SMOOTH gl-enable                   \ enable anti-aliasing
  then

  hourglass .fx @ 1 = if
    Draw-Hourglass
  then

  gl-load-identity                       \ reset the modelview matrix
  \ Move to the fine player position
  player .fx @ S>F 20e F+ player .fy @ S>F 70E F+ 0e gl-translate-f
  player .spin F@ 0e 0e 1e gl-rotate-f             \ rotate clockwise
  0e 1e 0e gl-color-3f              \ set player color to light green

  \ Draw the player using lines
  GL_LINES gl-begin
    -5e -5e gl-vertex-2d                         \ top left of player
     5e  5e gl-vertex-2d                     \ bottom right of player
     5e -5e gl-vertex-2d                        \ top right of player
    -5e  5e gl-vertex-2d                      \ bottom left of player
  gl-end

  player .spin F@ 0.5e F* 0e 0e 1e gl-rotate-f     \ rotate clockwise
  0e 0.75e 0e gl-color-3f            \ set player color to dark green

  GL_LINES gl-begin
    -7e  0e gl-vertex-2d                      \ left center of player
     7e  0e gl-vertex-2d                     \ right center of player
     0e -7e gl-vertex-2d                       \ top center of player
     0e  7e gl-vertex-2d                    \ bottom center of player
  gl-end

  Draw-Enemies                                     \ Draw the enemies

  sdl-gl-swap-buffers                         \ Draw it to the screen
;

true value isActive                  \ "focus" indicator for the mouse
true value Sound                                          \ sound flag

: Prepair-the-next-move
    gameover 0= isActive AND if
      game-stage internal-level * 0 do                        \ loop1
        \ Move the enemy right
        i enemies-ndx .x @ player .x @ <
        i enemies-ndx .fy @ i enemies-ndx .y @ 40 * = AND if
          1 i enemies-ndx .x +!
        then
        \ Move the enemy left
        i enemies-ndx .x @ player .x @ >
        i enemies-ndx .fy @ i enemies-ndx .y @ 40 * = AND if
          -1 i enemies-ndx .x +!
        then
        \ Move the enemy down
        i enemies-ndx .y @ player .y @ <
        i enemies-ndx .fx @ i enemies-ndx .x @ 60 * = AND if
          1 i enemies-ndx .y +!
        then
        \ Move the enemy up
        i enemies-ndx .y @ player .y @ >
        i enemies-ndx .fx @ i enemies-ndx .x @ 60 * = AND if
          -1 i enemies-ndx .y +!
        then
        \ Should the enemies move?
        enemy-delay 3 internal-level - >
        hourglass .fx @ 2 <> AND if
          0 to enemy-delay                       \ reset counter to 0
          game-stage internal-level * 0 do                    \ loop2
            i enemies-ndx .spin F@        \ put spin fvalue on fstack
            \ Is fine pos on x axis lower than intended pos?
            i enemies-ndx .fx @ i enemies-ndx .x @ 60 * < if
              \ Increase fine pos on x axis
              speed-adjust steps-ndx @ i enemies-ndx .fx +!
              \ Spin enemy clockwise
              speed-adjust steps-ndx @ S>F F+           \ add to spin
              \ -- keeping spin value on fstack here
            then
            \ Is fine pos on x axis higher than intended pos?
            i enemies-ndx .fx @ i enemies-ndx .x @ 60 * > if
              \ Decrease fine pos on x axis
              speed-adjust steps-ndx @ negate i enemies-ndx .fx +!
              \ Spin enemy counter-clockwise
              speed-adjust steps-ndx @ S>F F-    \ subtract from spin
              \ -- keeping spin value on fstack here
            then
            \ Is fine pos on y axis lower than intended pos?
            i enemies-ndx .fy @ i enemies-ndx .y @ 40 * < if
              \ Increase fine pos on y axis
              speed-adjust steps-ndx @ i enemies-ndx .fy +!
              \ Spin enemy clockwise
              speed-adjust steps-ndx @ S>F F+           \ add to spin
              \ -- keeping spin value on fstack here
            then
            \ Is fine pos on y axis higher than intended pos?
            i enemies-ndx .fy @ i enemies-ndx .y @ 40 * > if
              \ Decrease fine pos on y axis
              speed-adjust steps-ndx @ negate i enemies-ndx .fy +!
              \ Spin enemy clockwise
              speed-adjust steps-ndx @ S>F F-    \ subtract from spin
              \ -- keeping spin value on fstack here
            then
            i enemies-ndx .spin F!           \ save final spin fvalue
          loop
        then

        \ Are any of the enemies on top of the player?
        i enemies-ndx .fx @ player .fx @ =
        i enemies-ndx .fy @ player .fy @ = AND if
          player-lives 1- to player-lives       \ Player loses a life

          player-lives 0= if                   \ Are we out of lives?
            TRUE to gameover
          then

          Sound if
            s" die.wav" SND_SYNC PlaySound       \ play the death sound
          then
          ResetObjects
        then
      loop

      \ Move the player
      \ Is fine pos on x axis lower than intended pos?
      player .fx @ player .x @ 60 * < if
        \ Increase the fine x position
        speed-adjust steps-ndx @ player .fx +!
      then

      \ Is fine pos on x axis greater than intended pos?
      player .fx @ player .x @ 60 * > if
        \ Decrease the fine x position
        speed-adjust steps-ndx @ negate player .fx +!
      then

      \ Is fine pos on y axis lower than intended pos?
      player .fy @ player .y @ 40 * < if
        \ Increase the fine x position
        speed-adjust steps-ndx @ player .fy +!
      then

      \ Is fine pos on y axis greater than intended pos?
      player .fy @ player .y @ 40 * > if
        \ Decrease the fine x position
        speed-adjust steps-ndx @ negate player .fy +!
      then
    then

    \ Is the grid filled in?
    grid-filled if
      Sound if
        \ Play the level complete sound
        s" complete.wav" SND_SYNC PlaySound
      then
      \ Increase the stage
      game-stage 1+ to game-stage
      \ Is the stage higher than 3?
      game-stage 3 > if
        1 to game-stage                     \ yes, reset stage to one
        internal-level 1+ to internal-level         \ increase levels
        displayed-level 1+ to displayed-level
        \ Is the level greater than 3?
        internal-level 3 > if
          3 to internal-level                      \ clamp to level 3
          \ Give a free life - but limit to 5 lives max
          player-lives 1+ 5 MIN to player-lives
        then
      then
      \ Reset the player/enemy positions
      ResetObjects

      \ Clear the grid x and grid y coordinate arrays
      hline[] 11 cells 11 * 0 fill
      vline[] 11 cells 11 * 0 fill
    then \ grid-filled if

    \ If the player hits the hourglass while it is displayed:
    player .fx @ hourglass .x @ 60 * =
    player .fy @ hourglass .y @ 40 * = AND
    hourglass .fx @ 1 = AND if
      Sound if
        \ Play freeze enemy sound
        s" freeze.wav" SND_LOOP SND_ASYNC or PlaySound
      then
      \ Set hourglass fx variable to Two
      2 hourglass .fx !
      \ Set Hourglass fy variable to Zero
      0 hourglass .fy !
    then

    \ Spin the player clockwise
    player .spin F@
    0.5e speed-adjust steps-ndx @ S>F F* F+
    \ Is the spin fvalue >360?
    FDUP 360e F> if 360e F- then
    player .spin F!

    \ Spin the hourglass counter-clockwise
    hourglass .spin F@
    0.25e speed-adjust steps-ndx @ S>F F* F-
    \ Is the spin value <0?
    FDUP 0e F< if 360e F+ then
    hourglass .spin F!

    \ Increment hourglass .fy
    speed-adjust steps-ndx @ hourglass .fy +!

    \ Make the hourglass appear if hourglass .fx==0,
    \ and .fy>(6000/internal-level)

    hourglass .fx @ 0=
    hourglass .fy @ 6000 internal-level / > AND if
      Sound if
        \ Play the hourglass appears sound
        s" hourglass.wav" SND_ASYNC PlaySound
      then
      \ Give the hourglass random .x/.y values; init .fx/.fy
      10 random 1+ hourglass .x !
      11 random hourglass .y !
      1 hourglass .fx !                       \ hourglass will appear
      0 hourglass .fy !                               \ reset counter
    then

    \ Make the hourglass disappear if the hourglass .fx==1, and
    \ the hourglass .fy > (6000/internal-level)
    hourglass .fx @ 1 =
    hourglass .fy @ 6000 internal-level / > AND if
      0 hourglass .fx !                    \ hourglass will disappear
      0 hourglass .fy !                               \ reset counter
    then

    \ Unfreeze the enemies if hourglass .fx = 2, and
    \ hourglass .fy > (500+(500*internal-level))
    hourglass .fx @ 2 =
    hourglass .fy @ 500 500 internal-level * + > AND if
      Sound if
        \ Kill the freeze sound
        0 0 0 PlaySound
      then
      0 hourglass .fx !                        \ unfreeze the enemies
      0 hourglass .fy !                               \ reset counter
    then
    enemy-delay 1+ to enemy-delay
 ;

0 value PreviousKey
0 value cnt
500 value maxcnt

: Change/Accept-Keystoke ( key -- )        \ To make it a bit harder
   SuperCrazy
     if   dup VK_LEFT VK_DOWN between  \ When a cursor key has been pressed
           if  1 +to cnt  10 random 3 >
               cnt maxcnt < and
                   if   dup to PreviousKey
                   else 0 to cnt drop PreviousKey 1+     \ Change the
                        VK_DOWN min VK_LEFT max           \ direction
                   then                                   \ sometimes
           then
     then
   HandleKeyPress
  ;

: _exitLesson  ( -- )          \ For a clean start in the next lesson
  baselist 256 gl-delete-lists               \ clean up the font list
  DeleteTextures
  true to resizing?
 ;

: ResetLesson  ( -- )              \ For a clean start in this lesson
    ResetOpenGL                      \ Cleanup from a previous lesson
    InitGL                   \ Enable some features and load textures
    set-viewpoint                                 \ Set the viewpoint
 ;


also Forth definitions


: DrawGLLesson21  ( -- )                          \ Handles ONE frame
   LessonChanged?
      if  false to LessonChanged?
          ['] Change/Accept-Keystoke is KeyboardAction \ Use the keystrokes for this lesson only
          ['] _ExitLesson is ExitLesson            \ Specify ExitLesson to free allocated memory
          Init-Game-Vars                                         \ initialize the game variables
          ResetObjects                                                       \ reset our objects
          Reset-request-to-stop
      then
   resizing?
     if  ResetLesson
     then
         DrawGLScene              \ Redraw only the changes in the game
         ProcesKeyAndRelease            \ HandleKeyPress at this moment
         Prepair-the-next-move
 ;


 ' DrawGLLesson21 to LastLesson
[Forth]
\s

