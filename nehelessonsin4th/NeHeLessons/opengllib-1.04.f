\ ===[ Code Addendum 02 ]============================================
\                 gforth: OpenGL Graphics Lesson 04
\ ===================================================================
\           File: opengllib-1.04.fs
\         Author: Jeff Molofee
\  Linux Version: Ti Leggett
\ gForth Version: Timothy Trussell, 07/07/2010
\    Description: Rotation
\   Forth System: gforth-0.7.0
\   Linux System: Ubuntu v10.04 LTS i386, kernel 2.6.31-23
\   C++ Compiler: gcc version 4.4.3 (Ubuntu 4.4.3-4ubuntu5)
\ ===================================================================
\                       NeHe Productions
\                    http://nehe.gamedev.net/
\ ===================================================================
\                   OpenGL Tutorial Lesson 04
\ ===================================================================
\ This code was created by Jeff Molofee '99
\ (ported to Linux/SDL by Ti Leggett '01)
\ March, 2013 adapted for Win32Forth by Jos v.d.Ven
\ Visit Jeff at http://nehe.gamedev.net/
\ ===================================================================

vocabulary Lesson04  also Lesson04 definitions

\ ---[ Rotation Variables ]------------------------------------------

fvariable r-tri                                             \ ( New )
fvariable r-quad                                            \ ( New )

0e r-tri F!
0e r-quad F!

\ ---[ HandleKeyPress ]----------------------------------------------
\ function to handle key press events:

:long$ h04$
$| About lesson 04:
$|
$| Key-list for the available functions in this lesson:
$|
$| ESC      exits the lesson
$| w        toggles between fullscreen and windowed modes
  ;long$

: HandleKeyPress ( &event -- )          \ Escape is handled in OpenGL.f
    ascii W =
      if     start/end-fullscreen       \ Starts of end the full screen
      else   h04$ ShowHelp         \ Show the help text for this lesson
      then
;

\ ---[ InitGL ]------------------------------------------------------
\ general OpenGL initialization function

: InitGL ( -- )
  \ Enable smooth shading
  GL_SMOOTH gl-shade-model
  \ Set the background black
  0e 0e 0e 0e gl-clear-color
  \ Depth buffer setup
  1e gl-clear-depth
  \ Enable depth testing
  GL_DEPTH_TEST gl-enable
  \ Type of depth test to do
  GL_LEQUAL gl-depth-func
  \ Really nice perspective calculations
  GL_PERSPECTIVE_CORRECTION_HINT GL_NICEST gl-hint
;


\ ---[ DrawGLScene ]-------------------------------------------------
\ Here goes our drawing code

: DrawGLScene ( -- )
  \ Clear the screen and the depth buffer
  GL_COLOR_BUFFER_BIT GL_DEPTH_BUFFER_BIT OR gl-clear

  gl-load-identity                                   \ restore matrix

  \ Move left 1.5 units, and into the screen 6.0
  -1.5e 0e -6e gl-translate-f

  \ Rotate The Triangle On The Y axis                         ( NEW )
  r-tri F@ 0e 1e 0e gl-rotate-f

  GL_TRIANGLES gl-begin                     \ drawing using triangles
     1e  0e 0e gl-color-3f                                      \ red
     0e  1e 0e gl-vertex-3f                         \ top of triangle
     0e  1e 0e gl-color-3f                                    \ green
    -1e -1e 0e gl-vertex-3f                        \ left of triangle
     0e  0e 1e gl-color-3f                                     \ blue
     1e -1e 0e gl-vertex-3f                       \ right of triangle
  gl-end                              \ finished drawing the triangle

  gl-load-identity                                   \ restore matrix

  \ Move right 3 units
  1.5e 0e -6e gl-translate-f

  \ Rotate The Triangle On The Y axis                         ( NEW )
  r-quad F@ 1e 0e 0e gl-rotate-f

  0.5e 0.5e 1e gl-color-3f      \ Set The Color To Blue One Time Only

  GL_QUADS gl-begin                                     \ draw a quad
     1e  1e 0e gl-vertex-3f                               \ top right
    -1e  1e 0e gl-vertex-3f                                \ top left
    -1e -1e 0e gl-vertex-3f                             \ bottom left
     1e -1e 0e gl-vertex-3f                            \ bottom right
  gl-end

  \ Draw it to the screen -- if double buffering is permitted
  sdl-gl-swap-buffers

  \ Gather  our frames per second count
  \ fps-frames 1+ to fps-frames

  \ Display the FPS count to the terminal window
  \ Display-FPS

  \ Increase The Rotation Variable For The Triangle           ( NEW )
  r-tri F@ 0.2e F+ r-tri F!
  \ Decrease The Rotation Variable For The Quad               ( NEW )
  r-quad F@ 0.15e F- r-quad F!
;

: _exitLesson  ( -- )                             \ For a clean start
  DeleteTextures
  true to resizing?
 ;

: ResetLesson  ( -- )                             \ For a clean start
    ResetOpenGL                      \ Cleanup from a previous lesson
    InitGL                   \ Enable some features and load textures
    set-viewpoint-wf32                            \ Set the viewpoint
    false to resizing?
 ;

also Forth definitions

: DrawGLLesson04  ( -- )                          \ Handles ONE frame
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

' DrawGLLesson04 to LastLesson

[Forth]


