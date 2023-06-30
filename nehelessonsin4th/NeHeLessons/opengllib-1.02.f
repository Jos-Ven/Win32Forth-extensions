\ ===[ Code Addendum 02 ]============================================
\                 gforth: OpenGL Graphics Lesson 02
\ ===================================================================
\           File: opengllib-1.02.fs
\         Author: Jeff Molofee
\  Linux Version: Ti Leggett
\ gForth Version: Timothy Trussell, 07/06/2010
\    Description: Your first polygon
\   Forth System: gforth-0.7.0
\   Linux System: Ubuntu v10.04 LTS i386, kernel 2.6.31-23
\   C++ Compiler: gcc version 4.4.3 (Ubuntu 4.4.3-4ubuntu5)
\ ===================================================================
\                       NeHe Productions
\                    http://nehe.gamedev.net/
\ ===================================================================
\                   OpenGL Tutorial Lesson 02
\ ===================================================================
\ This code was created by Jeff Molofee '99
\ (ported to Linux/SDL by Ti Leggett '01)
\ March, 2013 adapted for Win32Forth by Jos v.d.Ven
\ Visit Jeff at http://nehe.gamedev.net/
\ ===================================================================

vocabulary Lesson02  also Lesson02 definitions

\ ---[ HandleKeyPress ]----------------------------------------------

:long$ h02$              \ Start a long 0 terminated string named h02$
$| About lesson 02:
$|
$| Key-list for the available functions in this lesson:
$|
$| w        toggles between fullscreen and windowed modes
  ;long$ \ Ends the long string and adds a long count and a zero to it

: HandleKeyPress ( &event -- )          \ Escape is handled in OpenGL.f
    ascii W =
      if     start/end-fullscreen       \ Starts of end the full screen
      else   h02$ ShowHelp         \ Show the help text for this lesson
      then
;

\ ---[ InitGL ]------------------------------------------------------
\ general OpenGL initialization function

: InitGL ( -- boolean )
  \ Enable smooth shading
  GL_SMOOTH gl-shade-model
  \ Set the background black
  0e  0e  0e  0e   gl-clear-color
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

  gl-load-identity

  \ Move left 1.5 units, and into the screen 6.0
  -1.5e 0e -6e gl-translate-f
  GL_TRIANGLES gl-begin                     \ drawing using triangles
      0e 1e 0e gl-vertex-3f                                     \ top
    -1e -1e 0e gl-vertex-3f                             \ bottom left
     1e -1e 0e gl-vertex-3f                            \ bottom right
  gl-end                              \ finished drawing the triangle

  \ Move right 3 units
  3e 0e 0e gl-translate-f
  GL_QUADS gl-begin                                     \ draw a quad
    -1e  1e 0e gl-vertex-3f                                \ top left
     1e  1e 0e gl-vertex-3f                               \ top right
     1e -1e 0e gl-vertex-3f                            \ bottom right
    -1e -1e 0e gl-vertex-3f                             \ bottom left
  gl-end

  \ Draw it to the screen
   glflush sdl-gl-swap-buffers
;

\ OnKeyEvent needs to be in the vocabulary Lesson02
\ otherwise you might get the wrong help.

: OnKeyEvent ( key - ) \ Update only after a key-event from the window
    to LastKeyIn
    LastKeyIn  HandleKeyPress         \ Pass the key to HandleKeyPress
    DrawGLScene                                     \ Redraw the scene
    0 to LastKeyIn                  \ Clear the key for the next event
 ;

: _ExitLesson ( -- )
  true to resizing?             \ Will reset openGL in the next lesson
 ;

also Forth definitions

: DrawGLLesson02  ( -- )
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

' DrawGLLesson02 to LastLesson

[Forth]
\s
