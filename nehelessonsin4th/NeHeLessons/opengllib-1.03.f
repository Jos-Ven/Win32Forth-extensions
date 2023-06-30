\ ===[ Code Addendum 03 ]============================================
\                 gforth: OpenGL Graphics Lesson 03
\ ===================================================================
\           File: opengllib-1.03.fs
\         Author: Jeff Molofee
\  Linux Version: Ti Leggett
\ gForth Version: Timothy Trussell, 07/06/2010
\    Description: Adding color
\   Forth System: gforth-0.7.0
\   Linux System: Ubuntu v10.04 LTS i386, kernel 2.6.31-23
\   C++ Compiler: gcc version 4.4.3 (Ubuntu 4.4.3-4ubuntu5)
\ ===================================================================
\                       NeHe Productions
\                    http://nehe.gamedev.net/
\ ===================================================================
\                   OpenGL Tutorial Lesson 03
\ ===================================================================
\ This code was created by Jeff Molofee '99
\ (ported to Linux/SDL by Ti Leggett '01)
\ March, 2013 adapted for Win32Forth by Jos v.d.Ven
\ Visit Jeff at http://nehe.gamedev.net/
\ ===================================================================

vocabulary Lesson03  also Lesson03 definitions

\ ---[ HandleKeyPress ]----------------------------------------------
:long$ h03$
$| About lesson 03:
$|
$| Key-list for the available functions in this lesson:
$|
$| w        toggles between fullscreen and windowed modes
  ;long$

: HandleKeyPress ( &event -- )          \ Escape is handled in OpenGL.f
    ascii W =
      if     start/end-fullscreen       \ Starts of end the full screen
      else   h03$ ShowHelp         \ Show the help text for this lesson
      then
;


\ ---[ InitGL ]------------------------------------------------------
\ General OpenGL initialization function

: InitGL ( -- boolean )
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

: DrawGLScene ( -- boolean )
  \ Clear the screen and the depth buffer
  GL_COLOR_BUFFER_BIT GL_DEPTH_BUFFER_BIT OR gl-clear

  \ Reset the matrix
  gl-load-identity

  \ Move left 1.5 units, and into the screen 6.0
  -1.5e 0e -6e gl-translate-f

  GL_TRIANGLES gl-begin                     \ drawing using triangles
     1e  0e 0e gl-color-3f                                      \ red
     0e  1e 0e gl-vertex-3f                         \ top of triangle
     0e  1e 0e gl-color-3f                                    \ green
    -1e -1e 0e gl-vertex-3f                        \ left of triangle
     0e  0e 1e gl-color-3f                                     \ blue
     1e -1e 0e gl-vertex-3f                       \ right of triangle
  gl-end                              \ finished drawing the triangle

  \ Move right 3 units
  3e 0e 0e gl-translate-f
  0.5e 0.5e 1e gl-color-3f      \ Set The Color To Blue One Time Only

  GL_QUADS gl-begin                                     \ draw a quad
     1e  1e 0e gl-vertex-3f                               \ top right
    -1e  1e 0e gl-vertex-3f                                \ top left
    -1e -1e 0e gl-vertex-3f                             \ bottom left
     1e -1e 0e gl-vertex-3f                            \ bottom right
  gl-end

  \ Draw it to the screen -- if double buffering is permitted
   sdl-gl-swap-buffers

;

: _ExitLesson ( -- )
  true to resizing?             \ Will reset openGL in the next lesson
 ;

: OnKeyEvent ( key - ) \ Update only after a key-event from the window
    to LastKeyIn
    LastKeyIn  HandleKeyPress         \ Pass the key to HandleKeyPress
    DrawGLScene                                     \ Redraw the scene
    0 to LastKeyIn                  \ Clear the key for the next event
 ;

also Forth definitions

: DrawGLLesson03  ( -- )
    ['] OnKeyEvent is KeyboardAction \ Use the keystrokes for this lesson only
    LessonChanged?
      if  ['] _ExitLesson is ExitLesson
          ResetOpenGL
          InitGL
          set-viewpoint-wf32                                     \ Set the viewpoint
          DrawGLScene
      then
    DrawGLScene
 ;


' DrawGLLesson03 to LastLesson

[Forth]

\s


