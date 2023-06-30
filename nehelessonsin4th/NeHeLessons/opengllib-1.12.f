\ ===================================================================
\           File: opengllib-1.12.fs
\         Author: Jeff Molofee
\  Linux Version: Ti Leggett
\ gForth Version: Timothy Trussell, 07/26/2010
\    Description: Display lists
\   Forth System: gforth-0.7.0
\   Linux System: Ubuntu v10.04 LTS i386, kernel 2.6.31-24
\   C++ Compiler: gcc version 4.4.3 (Ubuntu 4.4.3-4ubuntu5)
\ ===================================================================
\                       NeHe Productions
\                    http://nehe.gamedev.net/
\ ===================================================================
\                   OpenGL Tutorial Lesson 12
\ ===================================================================
\ This code was created by Jeff Molofee '99
\ (ported to Linux/SDL by Ti Leggett '01)
\ March, 2013 adapted for Win32Forth by Jos v.d.Ven
\ Visit Jeff at http://nehe.gamedev.net/
\ ===================================================================

vocabulary Lesson12  also Lesson12 definitions

\ ---[ Variable Declarations ]---------------------------------------

variable dl-box                        \ storage for the display list
variable dl-top                 \ storage for the second display list

fvariable x-rot
fvariable y-rot

\ ---[ Array Definitions ]-------------------------------------------
\ These are passed by address to OpenGL, so they must be sfloats

\ Array for the box colors - bright
create box-col[]
1e SF,   0e SF, 0e SF,                                          \ red
1e SF, 0.5e SF, 0e SF,                                       \ orange
1e SF,   1e SF, 0e SF,                                       \ yellow
0e SF,   1e SF, 0e SF,                                        \ green
0e SF,   1e SF, 1e SF,                                         \ blue

\ Array for the top colors - dark
create top-col[]
0.5e SF,    0e SF,   0e SF,                                     \ red
0.5e SF, 0.25e SF,   0e SF,                                  \ orange
0.5e SF,  0.5e SF,   0e SF,                                  \ yellow
  0e SF,  0.5e SF,   0e SF,                                   \ green
  0e SF,  0.5e SF, 0.5e SF,                                    \ blue

\ ---[ Array Index Functions ]---------------------------------------
\ Index functions to access the arrays

: color-ndx ( *col n -- *col[n] ) 3 sfloats * + ;

\ ---[ BuildLists ]--------------------------------------------------

: BuildLists ( -- )
  2 gl-gen-lists dl-box !                           \ Build two lists
  dl-box @ GL_COMPILE gl-new-list    \ New compiled display list, box
    GL_QUADS gl-begin
      0e 1e gl-tex-coord-2f -1e -1e -1e gl-vertex-3f    \ Bottom face
      1e 1e gl-tex-coord-2f  1e -1e -1e gl-vertex-3f
      1e 0e gl-tex-coord-2f  1e -1e  1e gl-vertex-3f
      0e 0e gl-tex-coord-2f -1e -1e  1e gl-vertex-3f

      1e 0e gl-tex-coord-2f -1e -1e  1e gl-vertex-3f     \ Front face
      0e 0e gl-tex-coord-2f  1e -1e  1e gl-vertex-3f
      0e 1e gl-tex-coord-2f  1e  1e  1e gl-vertex-3f
      1e 1e gl-tex-coord-2f -1e  1e  1e gl-vertex-3f

      0e 0e gl-tex-coord-2f -1e -1e -1e gl-vertex-3f      \ Back face
      0e 1e gl-tex-coord-2f -1e  1e -1e gl-vertex-3f
      1e 1e gl-tex-coord-2f  1e  1e -1e gl-vertex-3f
      1e 0e gl-tex-coord-2f  1e -1e -1e gl-vertex-3f

      0e 0e gl-tex-coord-2f  1e -1e -1e gl-vertex-3f     \ Right face
      0e 1e gl-tex-coord-2f  1e  1e -1e gl-vertex-3f
      1e 1e gl-tex-coord-2f  1e  1e  1e gl-vertex-3f
      1e 0e gl-tex-coord-2f  1e -1e  1e gl-vertex-3f

      1e 0e gl-tex-coord-2f -1e -1e -1e gl-vertex-3f      \ Left face
      0e 0e gl-tex-coord-2f -1e -1e  1e gl-vertex-3f
      0e 1e gl-tex-coord-2f -1e  1e  1e gl-vertex-3f
      1e 1e gl-tex-coord-2f -1e  1e -1e gl-vertex-3f
    gl-end
  gl-end-list

  dl-box @ 1+ dl-top !

  dl-top @ GL_COMPILE gl-new-list    \ New compiled display list, top
    GL_QUADS gl-begin
      1e 1e gl-tex-coord-2f -1e  1e -1e gl-vertex-3f       \ Top face
      1e 0e gl-tex-coord-2f -1e  1e  1e gl-vertex-3f
      0e 0e gl-tex-coord-2f  1e  1e  1e gl-vertex-3f
      0e 1e gl-tex-coord-2f  1e  1e -1e gl-vertex-3f
    gl-end
  gl-end-list
;

\ ---[ LoadGLTextures ]----------------------------------------------
\ function to load in bitmap as a GL texture


: LoadGLTextures ( -- )
    1 MallocTextures       \ Initialize the number of needed textures
    s" cube.bmp" map-bitmap >R            \ image loaded successfully
    NumTextures texture[] gl-gen-textures        \ create the texture

    \ texture generation using data from the bitmap
    0 BindTexture-ndx                               \ texture[0]

    \ Generate the texture
    R> Generate-MipMapped-Texture

    \ Linear Filtering
    LinearFiltering

    \ free the image now we are done with it
    ahndl close-map-file drop
;

\ ---[ HandleKeyPress ]----------------------------------------------
\ function to handle key press events:
:long$ h12$
$| About lesson 12:
$|
$| Key-list for the available functions in this lesson:
$|
$| ESC      exits the lesson
$| w        toggles between fullscreen and windowed modes
$| Left     make x rotation more negative
$| Right    make x rotation more positive
$| Up       make y rotation more negative
$| Down     make y rotation more positive
$| Home     Resets the rotation
  ;long$

: HandleKeyPress ( &event -- )
  case
    \ SDLK_ESCAPE of TRUE to opengl-exit-flag endof
    ascii W       of start/end-fullscreen      endof
    VK_LEFT       of y-rot F@ 0.5e F- y-rot F! endof
    VK_RIGHT      of y-rot F@ 0.5e F+ y-rot F! endof
    VK_UP         of x-rot F@ 0.5e F- x-rot F! endof
    VK_DOWN       of x-rot F@ 0.5e F+ x-rot F! endof
    VK_HOME       of 0e x-rot F!   0e y-rot F! endof \ Reset to the default values
                  h12$ ShowHelp
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

: InitGL ( -- boolean )
    \ Load in the texture
    LoadGLTextures
    \ Build our display lists
    BuildLists
    \ Enable texture mapping
    GL_TEXTURE_2D gl-enable
    \ Enable smooth shading
    GL_SMOOTH gl-shade-model
    \ Set the background black
    0e 0e 0e 0.5e gl-clear-color
    \ Depth buffer setup
    1e gl-clear-depth
    \ Enable depth testing
    GL_DEPTH_TEST gl-enable
    \ Type of depth test to do
    GL_LEQUAL gl-depth-func
    \ Enable lighting
    GL_LIGHT0 gl-enable                    \ quick and dirty lighting
    GL_LIGHTING gl-enable                           \ enable lighting
    GL_COLOR_MATERIAL gl-enable            \ enable material coloring
    \ Really nice perspective calculations
    GL_PERSPECTIVE_CORRECTION_HINT GL_NICEST gl-hint
;

\ ---[ DrawGLScene ]-------------------------------------------------
\ Here goes our drawing code

: DrawGLScene ( -- boolean )
  \ Clear the screen and the depth buffer
  GL_COLOR_BUFFER_BIT GL_DEPTH_BUFFER_BIT OR gl-clear
  \ Select our texture
  GL_TEXTURE_2D 0 texture-ndx @ gl-bind-texture
  \ Start loading in our display lists
  6 1 do
    i 0 do
      gl-load-identity                           \ reset the matrix
      \ Position the cubes on the screen
      1.4e i S>F 2.8e F* F+ j S>F 1.4e F* F-    \ 1st param
      6e j S>F F- 2.4e F* 7e F-                 \ 2nd param
      -20e                                      \ 3rd param
      gl-translate-f
      \ Tilt the cubes up and down
      45e 2e j S>F F* F- x-rot F@ f+ 1e 0e 0e gl-rotate-f
      \ Spin cubes left and right
      45e y-rot F@ F+ 0e 1e 0e gl-rotate-f
      \ Select a color -- box
      box-col[] j 1 - color-ndx gl-color-3fv
      \ Draw the box
      dl-box @ gl-call-list
      \ Select a color -- top
      top-col[] j 1 - color-ndx gl-color-3fv
      \ Draw the top
      dl-top @ gl-call-list
    loop
  loop

  \ Draw it to the screen
  sdl-gl-swap-buffers
;

: _exitLesson  ( -- )          \ For a clean start in the next lesson
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


: DrawGLLesson12  ( -- )                          \ Handles ONE frame
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

 ' DrawGLLesson12 to LastLesson
[Forth]
\s

