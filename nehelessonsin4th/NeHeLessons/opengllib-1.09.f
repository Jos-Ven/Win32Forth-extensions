\ ===================================================================
\           File: opengllib-1.09.fs
\         Author: Jeff Molofee
\  Linux Version: Ti Leggett
\ gForth Version: Timothy Trussell, 07/25/2010
\    Description: Moving bitmaps in 3D space
\   Forth System: gforth-0.7.0
\   Linux System: Ubuntu v10.04 LTS i386, kernel 2.6.31-23
\   C++ Compiler: gcc version 4.4.3 (Ubuntu 4.4.3-4ubuntu5)
\ ===================================================================
\                       NeHe Productions
\                    http://nehe.gamedev.net/
\ ===================================================================
\                   OpenGL Tutorial Lesson 09
\ ===================================================================
\ This code was created by Jeff Molofee '99
\ (ported to Linux/SDL by Ti Leggett '01)
\ March, 2013 adapted for Win32Forth by Jos v.d.Ven
\ Visit Jeff at http://nehe.gamedev.net/
\ ===================================================================

vocabulary Lesson09  also Lesson09 definitions

\ ---[ Variable Declarations ]---------------------------------------

\ Define the star structure

struct{
  cell    .red                                     \ stars color
  cell    .green
  cell    .blue
  b/float .dist                     \ stars distance from center
  b/float .angle                           \ stars current angle
}struct  Star%
sizeof star% constant /star%

50 constant #Stars


\ allocate space for the array of stars
/star% #Stars * dup mkstruct: Stars[]  Stars[] swap erase


\ ---[ Array Index Functions ]---------------------------------------
\ Index functions to access the arrays

: stars-ndx   ( n -- *stars[n] ) /star% * Stars[] + ;

FALSE value twinkle                                        \ do they?

fvariable zoom                     \ viewing distance away from stars
fvariable tilt                                        \ tilt the view
fvariable spin                               \ for spinning the stars

\ ---[ Variable Initializations ]------------------------------------

             \ Orginal:
-15e zoom F! \ 15e
90e  tilt F! \ 90e
0e   spin F! \ 0

\ ---[ LoadGLTextures ]----------------------------------------------
\ function to load in bitmap as a GL texture

: LoadGLTextures ( -- status )
  \ create variables for storing surface pointers and return flag
  1 MallocTextures      \ MallocTextures allocates only when not done
  NumTextures texture[] gl-gen-textures         \ create the textures
  \ Attempt to load the texture images by using a mapping
  s" star.bmp"  0 ahndl LoadGLTexture                       \ ndx = 0
  true                         \ exit -1=ok OR abort in LoadGLTexture
;


\ ---[ Keyboard Flags ]----------------------------------------------
\ Flags needed to prevent constant toggling if the keys that they
\ represent are held down during program operation.
\ By checking to see if the specific flag is already set, we can then
\ choose to ignore the current keypress event for that key.
\
\ PgUp/PgDn and the Arrow keys will be allowed to be constantly read
\ until they are released.


\ ---[ HandleKeyPress ]----------------------------------------------
\ function to handle key press events:

:long$ h09$
$| About lesson 09:
$|
$| Key-list for the available functions in this lesson:
$|
$|   ESC      exits the lesson
$|   w        toggles between fullscreen and windowed modes
$|   t        toggles twinkling of stars
$|   PageUp   zooms into the scene
$|   PageDown zooms out of the scene
$|   Up       changes tilt of the stars more positive
$|   Down     changes tilt of the stars more negative
  ;long$

: HandleKeyPress ( &event -- )
  case
  \  SDLK_ESCAPE   of TRUE to opengl-exit-flag endof
    ascii W     of  start/end-fullscreen             endof
    ascii T      of  twinkle 0= if 1 else 0 then
                    to twinkle                       endof
    VK_PGUP     of zoom F@ 0.2e F+ zoom F!           endof
    VK_PGDN	of zoom F@ 0.2e F- zoom F!           endof
    VK_UP       of tilt F@ 0.5e F- tilt F!           endof
    VK_DOWN     of tilt F@ 0.5e F+ tilt F!           endof
                h09$ ShowHelp
  endcase
 ;


\ ---[ Set the viewpoint ]-------------------------------------------

: SetViewpoint ( - )
  \  The set up of the viewport happens in OpenGL.f.
  \ Change to the projection matrix and set our viewing volume
  GL_PROJECTION gl-matrix-mode
  \ Reset the matrix
  gl-load-identity
  \ Set our perspective - the F/ calcs the aspect ratio of w/h
  45e widthViewport S>F heightViewport S>F F/ 0.1e 100e gluPerspective \ glu-perspective
  \ Make sure we are changing the model view and not the projection
  GL_MODELVIEW gl-matrix-mode
  \ Reset the matrix
  gl-load-identity
 ;

\ ---[ InitGL ]------------------------------------------------------
\ general OpenGL initialization function

: Color-Stars ( -- )
    #Stars 0 do
      \ Set .red to a random intensity
      rnd 256 MOD i stars-ndx .red !
      \ Set .green to a random intensity
      rnd 256 MOD i stars-ndx .green !
      \ Set .blue to a random intensity
      rnd 256 MOD i stars-ndx .blue !
    loop
 ;

:  PrepareArrays ( - )
    \ Loop thru all of the stars
    #Stars 0 do
       \ Start all the stars at angle zero
       0e  i stars-ndx .angle  F!
       \ calculate distance from the center
       i S>F #Stars S>F F/ 5e F* i stars-ndx .dist F!
    loop
    Color-Stars
 ;


: InitGL ( -- boolean )
    \ Load in the texture
    LoadGLTextures drop
    \ Enable texture mapping ok
    GL_TEXTURE_2D gl-enable
    \ Enable smooth shading
    GL_SMOOTH gl-shade-model
    \ Set the background black
    0e 0e 0e 0e gl-clear-color
    \ Depth buffer setup
    1e gl-clear-depth
    \ Type of depth test to do
    GL_LEQUAL gl-depth-func
    \ Really nice perspective calculations
    GL_PERSPECTIVE_CORRECTION_HINT GL_NICEST gl-hint
    \ Blending translucency based on source alpha value
    GL_SRC_ALPHA GL_ONE gl-blend-func
    \ Enable blending
    GL_BLEND gl-enable
    \ One time actions before starting the show
      PrepareArrays
 ;

\ ---[ DrawGLScene ]-------------------------------------------------
\ Here goes our drawing code

: DrawGLScene ( -- boolean )
  \ Clear the screen and the depth buffer
  GL_COLOR_BUFFER_BIT  GL_DEPTH_BUFFER_BIT OR  gl-clear
  \ Make the stars twinkle when needed
  twinkle     if Color-Stars   then
  \ Select our texture
  \ GL_TEXTURE_2D 0 texture-ndx @ gl-bind-texture \ ?
  \ restore matrix
  \ gl-load-identity   \ 2 times ?

   #Stars  0 do

    \ Reset the view before we draw each star
    gl-load-identity  \ Makes it very slow

   \ Zoom into the screen
    0e 0e zoom F@ gl-translate-f

    \ Tilt the view
    tilt F@ 1e 0e 0e gl-rotate-f
    \ Rotate to the current stars angle
    i stars-ndx .angle F@  0e 1e 0e gl-rotate-f
    \ Move forward on the x plane
    i stars-ndx .dist F@ 0e 0e gl-translate-f
    \ Cancel the current stars angle
    i stars-ndx .angle F@ fnegate 0e 1e 0e gl-rotate-f
    \ Cancel the screen tilt
    tilt F@ fnegate 1e 0e 0e gl-rotate-f

    \ Twinkling stars enabled
    twinkle if
      \ Assign a color
      #Stars i - 1- stars-ndx .red   @
      #Stars i - 1- stars-ndx .green @
      #Stars i - 1- stars-ndx .blue  @ 255 gl-color-4ub
      \ Begin drawing the textured quad
      GL_QUADS gl-begin
        0e 0e gl-tex-coord-2f -1e -1e 0e gl-vertex-3f
        1e 0e gl-tex-coord-2f  1e -1e 0e gl-vertex-3f
        1e 1e gl-tex-coord-2f  1e  1e 0e gl-vertex-3f
        0e 1e gl-tex-coord-2f -1e  1e 0e gl-vertex-3f
      gl-end
    then

    \ Rotate the star on the z axis
    spin F@ 0e 0e 1e gl-rotate-f

    \ Assign a color
    i stars-ndx .red   @
    i stars-ndx .green @
    i stars-ndx .blue  @ 255 gl-color-4ub
    \ Begin drawing the textured quad
    GL_QUADS gl-begin
      0e 0e gl-tex-coord-2f -1e -1e 0e gl-vertex-3f
      1e 0e gl-tex-coord-2f  1e -1e 0e gl-vertex-3f
      1e 1e gl-tex-coord-2f  1e  1e 0e gl-vertex-3f
      0e 1e gl-tex-coord-2f -1e  1e 0e gl-vertex-3f
    gl-end

    \ Used to spin the stars
    spin F@ 0.01e F+ spin F!

    \ Change the angle of a star
    i stars-ndx .angle F@    i S>F #Stars S>F F/ F+
    i stars-ndx .angle F!

    \ Change the distance of a star
    i stars-ndx .dist F@ 0.01e F- i stars-ndx .dist F!
    \ Is the star in the middle yet?
    i stars-ndx .dist F@ F0< if
      \ Move the star 5 units from the center
      i stars-ndx .dist F@ 5e F+ i stars-ndx .dist F!
      \ Give it a new red value
      rnd 256 MOD i stars-ndx .red !
      \ Give it a new green value
      rnd 256 MOD i stars-ndx .green !
      \ Give it a new blue value
      rnd 256 MOD i stars-ndx .blue !
    then
  loop
  \ Draw it to the screen
  sdl-gl-swap-buffers
;

: _exitLesson  ( -- )                             \ For a clean start
  DeleteTextures
  true to resizing?
 ;

: ResetLesson  ( -- )                             \ For a clean start
    ResetOpenGL                      \ Cleanup from a previous lesson
    InitGL                   \ Enable some features and load textures
    SetViewpoint                                  \ Set the viewpoint
    false to resizing?
 ;

also Forth definitions

: DrawGLLesson09  ( -- )                          \ Handles ONE frame
   LessonChanged?
      if  false to LessonChanged?
          ['] HandleKeyPress is KeyboardAction \ Use the keystrokes for this lesson only
          ['] _ExitLesson is ExitLesson    \ Specify ExitLesson to free allocated memory
          Reset-request-to-stop
         \ DynamicScene                               \ Prepare a dynamic scene
      then
   resizing?
     if  ResetLesson
     then
   DrawGLScene           \ Redraw only the changes in the lesson
   ProcesKeyAndRelease                \ HandleKeyPress only here
 ;

 ' DrawGLLesson09 to LastLesson
[Forth]
\s
