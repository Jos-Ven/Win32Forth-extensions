\ ===================================================================
\           File: opengllib-1.19.fs
\         Author: Jeff Molofee
\  Linux Version: Ti Leggett
\ gForth Version: Timothy Trussell, 08/01/2010
\    Description: Particle Engine Using Triangle Strips
\   Forth System: gforth-0.7.0
\   Linux System: Ubuntu v10.04 LTS i386, kernel 2.6.31-24
\   C++ Compiler: gcc version 4.4.3 (Ubuntu 4.4.3-4ubuntu5)
\ ===================================================================
\                       NeHe Productions
\                    http://nehe.gamedev.net/
\ ===================================================================
\                   OpenGL Tutorial Lesson 19
\ ===================================================================
\ This code was created by Jeff Molofee '99
\ (ported to Linux/SDL by Ti Leggett '01)
\ March, 2013 adapted for Win32Forth by Jos v.d.Ven
\ Visit Jeff at http://nehe.gamedev.net/
\ ===================================================================

vocabulary Lesson19  also Lesson19 definitions

\ ---[ Variable Declarations ]---------------------------------------

1000 constant MaxParticles              \ maximum number of particles

fvariable slowdown                              \ slow down particles
fvariable xspeed                                       \ base x speed
fvariable yspeed                                       \ base y speed
fvariable zoom                                     \ used to zoom out

TRUE value rainbow                            \ toggle rainbow effect
1 value rainbow-delay                          \ rainbow effect delay
1 value rainbow-color                                 \ rainbow color

60e xspeed f!
60e yspeed f!


\ ---[ Variable Initializations ]------------------------------------

2e slowdown F!
-40e zoom F!


struct{
  cell     p-active                    \ active particle (yes/no)
  b/float  p-life                                 \ particle life
  b/float  p-fade                                    \ fade speed
  b/float  p-r                                        \ red value
  b/float  p-g                                      \ green value
  b/float  p-b                                       \ blue value
  b/float  p-x                                       \ x position
  b/float  p-y                                       \ y position
  b/float  p-z                                       \ z position
  b/float  p-xi                                     \ x direction
  b/float  p-yi                                     \ y direction
  b/float  p-zi                                     \ z direction
  b/float  p-xg                                       \ x gravity
  b/float  p-yg                                       \ y gravity
  b/float  p-zg                                       \ z gravity
}struct particle%
sizeof particle% constant /particle%

\ Rainbow of colors

struct{
  b/float  c-red
  b/float  c-green
  b/float  c-blue
}struct color%
sizeof color% constant /color%

create colors[]
1e    F, 0.5e  F, 0.5e  F,
1e    F, 0.75e F, 0.5e  F,
1e    F, 1e    F, 0.5e  F,
0.75e F, 1e    F, 0.5e  F,
0.5e  F, 1e    F, 0.5e  F,
0.5e  F, 1e    F, 0.75e F,
0.5e  F, 1e    F, 1e    F,
0.5e  F, 0.75e F, 1e    F,
0.5e  F, 0.5e  F, 1e    F,
0.75e F, 0.5e  F, 1e    F,
1e    F, 0.5e  F, 1e    F,
1e    F, 0.5e  F, 0.75e F,

\ Index function to access colors[] array
: color-ndx ( n -- *color[n] ) /color% * colors[] + ;

\ Pointer to array of particle structs.
\ This is allocated at run-time when InitGL is executed.

0 value particle[]

\ Index function to access particle[] array
: particle-ndx ( n -- *particle[n] )  /particle% * particle[] + ;

\ ---[ LoadGLTextures ]----------------------------------------------
\ function to load in bitmap as a GL texture

: LoadGLTextures ( -- )
  \ create variables for storing surface pointers and return flag
  1 MallocTextures      \ MallocTextures allocates only when not done
  NumTextures texture[] gl-gen-textures         \ create the textures
  \ Attempt to load the texture images by using a mapping
  s" particle.bmp"  0 ahndl  LoadGLTexture                         \ ndx = 0
;


\ ---[ ResetParticle ]-----------------------------------------------
\ Resets a particle to its initial state

0 value rp-ptr
0 value rp-color

0e fvalue _xdir  \ Win32Forth has no flocals
0e fvalue _ydir
0e fvalue _zdir

: ResetParticle { _num _color }  \ { _num _color f: _xdir f: _ydir f: _zdir -- }
  fto _zdir  fto _ydir  fto _xdir
  \ Initialize the index pointers once
  _num particle-ndx to rp-ptr
  _color color-ndx to rp-color
  \ Reset all of the struct fields
  TRUE rp-ptr p-active !                   \ Make the particle active
  1e rp-ptr p-life F!                  \ Give the particle life, Igor
  100 random S>F 1000e F/ 0.003e F+ rp-ptr p-fade F!    \ Random fade
  rp-color c-red   F@ rp-ptr p-r F!                         \ set red
  rp-color c-green F@ rp-ptr p-g F!                       \ set green
  rp-color c-blue  F@ rp-ptr p-b F!                        \ set blue
  0e    rp-ptr p-x  F!                             \ reset x position
  0e    rp-ptr p-y  F!                             \ reset y position
  0e    rp-ptr p-z  F!                             \ reset z position
  _xdir rp-ptr p-xi F!                       \ Random speed on x axis
  _ydir rp-ptr p-yi F!                       \ Random speed on y axis
  _zdir rp-ptr p-zi F!                       \ Random speed on z axis
  0e    rp-ptr p-xg F!                        \ reset horizontal pull
  -0.8e rp-ptr p-yg F!                  \ Set vertical pull downwards
  0e    rp-ptr p-zg F!                         \ reset pull on z axis
;


\ ---[ HandleKeyPress ]----------------------------------------------
\ function to handle key press events:
:long$ h19$
$| About lesson 19:
$|
$| Key-list for the available functions in this lesson:
$| ESC      exits the lesson
$| w        toggles between fullscreen and windowed modes
$| PageUp   zooms into the scene
$| PageDown zooms out of the scene
$| TAB      resets all particles; makes them explode
$| RETURN   toggles the rainbow color effect
$| SPACE    turns off rainbowing; cycles thru the colors
$|      Arrow Keys:
$| Up       increase particles y movement
$| Down     decrease particles y movement
$| Right    increase particles x movement
$| Left     decrease particles x movement
$|      Numeric Keypad:
$| KP-Plus  speeds up the particles
$| KP-Minus slows down the particles
$| KP-8     increase particles y gravity
$| KP-2     decrease particles y gravity
$| KP-6     increase particles x gravity
$| KP-4     decrease particles x gravity
  ;long$

: HandleKeyPress ( &event -- )
  case
   \ SDLK_ESCAPE of TRUE to opengl-exit-flag endof
   ascii W     of  start/end-fullscreen endof

   VK_TAB      of  MaxParticles 0 do
                         i                                      \ num
                         i 1 + MaxParticles 12 / /            \ color
                         50 random S>F 26e F- 10e F*             \ xi
                         50 random S>F 25e F- 10e F*             \ yi
                         FDUP                                    \ zi
                         ResetParticle
                       loop
		   endof
   VK_RETURN   of rainbow if FALSE else TRUE then to rainbow
                       25 to rainbow-delay
                   endof
   BL          of FALSE to rainbow
                       0 to rainbow-delay
                       rainbow-color 1+ 12 MOD to rainbow-color
		  endof
   VK_PGUP     of zoom F@ 0.01e F+ zoom F! endof
   VK_PGDN     of zoom F@ 0.01e F- zoom F! endof
   VK_UP                   of yspeed F@ 200e F< if
                       yspeed F@ 1e F+ yspeed F!
                     then
                  endof
   VK_DOWN     of yspeed F@ -200e F> if
                       yspeed F@ 1e F- yspeed F!
                     then
                  endof
   VK_RIGHT    of xspeed F@ 200e F< if
                       xspeed F@ 1e F+ xspeed F!
                     then
                  endof
   VK_LEFT     of xspeed F@ -200e F> if
                       xspeed F@ 1e F- xspeed F!
                     then
                  endof
   VK_NUMPAD+ of slowdown F@ 1e F> if
                       slowdown F@ 0.01e F- slowdown F!
                      then
                  endof
   VK_NUMPAD- of slowdown F@ 4e F< if
                       slowdown F@ 0.01e F+ slowdown F!
                     then
                  endof
   VK_NUMPAD8  of MaxParticles 0 do
                       i particle-ndx p-yg F@ FDUP 1.5e F< if
                         0.01e F+ i particle-ndx p-yg F!
                       else
                         FDROP
                       then
                     loop
                  endof
    VK_NUMPAD2 of MaxParticles 0 do
                       i particle-ndx p-yg F@ FDUP -1.5e F> if
                         0.01e F- i particle-ndx p-yg F!
                       else
                         FDROP
                       then
                     loop
                  endof
   VK_NUMPAD6  of MaxParticles 0 do
                       i particle-ndx p-xg F@ FDUP 1.5e F< if
                         0.01e F+ i particle-ndx p-xg F!
                       else
                         FDROP
                       then
                     loop
                  endof
    VK_NUMPAD4 of MaxParticles 0 do
                       i particle-ndx p-xg F@ FDUP -1.5e F> if
                         0.01e F- i particle-ndx p-xg F!
                       else
                         FDROP
                       then
                     loop
                  endof
                h19$ ShowHelp
  endcase
;


\ ---[ Set the viewpoint ]-------------------------------------------

: set-viewpoint ( -- )   \ the call to glViewport is done in Opengl.f
  GL_PROJECTION gl-matrix-mode
  \ Reset the matrix
  gl-load-identity
  \ Set our perspective - the F/ calcs the aspect ratio of w/h
  45e widthViewport  S>F heightViewport  S>F F/ 0.1e 100e glu-perspective
  \ Make sure we are changing the model view and not the projection
  GL_MODELVIEW gl-matrix-mode
;

\ ---[ InitGL ]------------------------------------------------------
\ general OpenGL initialization function

: SetViewpoint ( - )
  \ set up the viewport
\  glin
  \ Change to the projection matrix and set our viewing volume
  GL_PROJECTION gl-matrix-mode
  \ Reset the matrix
  gl-load-identity
  \ Set our perspective - the F/ calcs the aspect ratio of w/h
  45e widthViewport S>F heightViewport S>F F/ 0.1e 200e gluPerspective \ glu-perspective

  \ Make sure we are changing the model view and not the projection
  GL_MODELVIEW gl-matrix-mode
  \ Reset the matrix
  gl-load-identity
 ;

: ResetALLParticles
    MaxParticles 0 do
      i                                                         \ num
      i 1 + MaxParticles 12 / /                               \ color
      50 random S>F 26e F- 10e F*                                \ xi
      50 random S>F 25e F- 10e F*                                \ yi
      FDUP                                                       \ zi
      ResetParticle
    loop
 ;

: InitGL ( -- boolean )
    \ Load in the texture
    LoadGLTextures
    \ Allocate space for the particle[] array - 116,000 bytes
    particle[] 0= if      \ if &particle[]=0 skip - already allocated
         \ Allocate the space and then - 116,000 bytes
         /particle%  MaxParticles * dup malloc
         \ assign the address
         dup to particle[] swap erase        \ and clear it to zeroes
    then
    \ Enable smooth shading
    GL_SMOOTH gl-shade-model
    \ Set the background black
    0e 0e 0e 0e gl-clear-color
    \ Depth buffer setup
    1e gl-clear-depth
    \ Disable depth testing
    GL_DEPTH_TEST gl-disable
    \ Enable blending
    GL_BLEND gl-enable
    \ Type of blending to perform
    GL_SRC_ALPHA GL_ONE gl-blend-func
    \ Really nice perspective calculations
    GL_PERSPECTIVE_CORRECTION_HINT GL_NICEST gl-hint
    \ Really nice point smoothing
    GL_POINT_SMOOTH_HINT GL_NICEST gl-hint
    \ Enable texture mapping
    GL_TEXTURE_2D gl-enable
    \ Select our texture
    GL_TEXTURE_2D 0 texture-ndx @ gl-bind-texture
    ResetALLParticles
    \ Enable rainbow coloring at start
    TRUE to rainbow
;

\ ---[ DrawGLScene ]-------------------------------------------------
\ Here goes our drawing code

\ Float variables used in DrawGLScene

fvariable ds-x
fvariable ds-y
fvariable ds-z
0 value ds-ptr                 \ storage for pointer <i particle-ndx>

: DrawGLScene ( -- )
  \ Clear the screen and the depth buffer
  GL_COLOR_BUFFER_BIT GL_DEPTH_BUFFER_BIT OR gl-clear
  gl-load-identity
  \ Modify each of the particles
  MaxParticles 0 do
    i particle-ndx to ds-ptr
    ds-ptr p-active @ if                    \ is the particle active?
      ds-ptr p-x F@ ds-x F!            \ Grab our particle x position
      ds-ptr p-y F@ ds-y F!            \ Grab our particle y position
      ds-ptr p-z F@ zoom F@ F+ ds-z F! \ Grab our particle z position

      \ Draw particle using our RGB values, fading based on its life
      ds-ptr dup p-r F@ dup p-g F@ dup p-b F@ p-life F@ gl-color-4f

      GL_TRIANGLE_STRIP gl-begin   \ Build quad from a triangle strip
        1e 1e gl-tex-coord-2f                             \ top right
        ds-x F@ 0.5e F+ ds-y F@ 0.5e F+ ds-z F@ gl-vertex-3f
        0e 1e gl-tex-coord-2f                              \ top left
        ds-x F@ 0.5e F- ds-y F@ 0.5e F+ ds-z F@ gl-vertex-3f
        1e 0e gl-tex-coord-2f                          \ bottom right
        ds-x F@ 0.5e F+ ds-y F@ 0.5e F- ds-z F@ gl-vertex-3f
        0e 0e gl-tex-coord-2f                           \ bottom left
        ds-x F@ 0.5e F- ds-y F@ 0.5e F- ds-z F@ gl-vertex-3f
      gl-end

      \ gforth uses two stacks - one for integers and one for floats.
      \ ds-ptr puts an address onto the int stack, while the F@ F* F+
      \ and F! words work with data on the float stack.
      \ The <dup> word makes a copy of the top of the integer stack.
      \ Keeping this in mind, the flow here is pretty easy to follow.

      \ Move on the x axis by x speed
      ds-ptr dup p-x F@ dup p-xi F@ slowdown F@ 1000e F* F/ F+ p-x F!
      \ Move on the y axis by y speed
      ds-ptr dup p-y F@ dup p-yi F@ slowdown F@ 1000e F* F/ F+ p-y F!
      \ Move on the z axis by y speed
      ds-ptr dup p-z F@ dup p-zi F@ slowdown F@ 1000e F* F/ F+ p-z F!
      \ Take pull on x axis into account
      ds-ptr dup p-xi F@ dup p-xg F@ F+ p-xi F!
      \ Take pull on y axis into account
      ds-ptr dup p-yi F@ dup p-yg F@ F+ p-yi F!
      \ Take pull on z axis into account
      ds-ptr dup p-zi F@ dup p-zg F@ F+ p-zi F!
      \ Reduce the particles' life by 'fade' value
      ds-ptr p-life F@ ds-ptr p-fade F@ F- ds-ptr p-life F!
      \ If the particle dies, revive it
      ds-ptr p-life F@ F0< if
        i                                                       \ num
        rainbow-color                                         \ color
        xspeed F@  60 random S>F 32e F- F+                       \ xi
        yspeed F@  60 random S>F 30e F- F+                       \ yi
        60 random S>F 32e F-                                     \ zi
        ResetParticle
      then
    then
  loop

  \ Draw it to the screen
  sdl-gl-swap-buffers
;

: _exitLesson  ( -- )          \ For a clean start in the next lesson
  particle[] free drop 0 to particle[]    \ Free the array particle[]
  DeleteTextures
  true to resizing?
 ;

: ResetLesson  ( -- )              \ For a clean start in this lesson
    ResetOpenGL                      \ Cleanup from a previous lesson
    InitGL                   \ Enable some features and load textures
    set-viewpoint                                 \ Set the viewpoint
    false to resizing?
 ;


also Forth definitions


: DrawGLLesson19  ( -- )                          \ Handles ONE frame
   LessonChanged?
      if  false to LessonChanged?
          ['] HandleKeyPress is KeyboardAction \ Use the keystrokes for this lesson only
          ['] _ExitLesson is ExitLesson    \ Specify ExitLesson to free allocated memory
          Reset-request-to-stop
      then
   resizing?
     if  ResetLesson
     then
   DrawGLScene           \ Redraw only the changes in the lesson
   ProcesKeyAndRelease                \ HandleKeyPress only here
 ;


 ' DrawGLLesson19 to LastLesson
[Forth]
\s

