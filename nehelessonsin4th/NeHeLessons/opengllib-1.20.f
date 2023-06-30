\ ===================================================================
\           File: opengllib-1.20.fs
\         Author: Jeff Molofee
\  Linux Version: Ti Leggett
\ gForth Version: Timothy Trussell, 08/01/2010
\    Description: Masking
\   Forth System: gforth-0.7.0
\   Linux System: Ubuntu v10.04 LTS i386, kernel 2.6.31-24
\   C++ Compiler: gcc version 4.4.3 (Ubuntu 4.4.3-4ubuntu5)
\ ===================================================================
\                       NeHe Productions
\                    http://nehe.gamedev.net/
\ ===================================================================
\                   OpenGL Tutorial Lesson 20
\ ===================================================================
\ This code was created by Jeff Molofee '99
\ (ported to Linux/SDL by Ti Leggett '01)
\ March, 2013 adapted for Win32Forth by Jos v.d.Ven
\ Visit Jeff at http://nehe.gamedev.net/
\ ===================================================================

vocabulary Lesson20  also Lesson20 definitions

\ ---[ Variable Declarations ]---------------------------------------

fvariable xrot                                           \ X rotation
fvariable yrot                                           \ Y rotation
fvariable zrot                                           \ Z rotation
fvariable rolling                                   \ rolling texture

TRUE value masking                              \ masking toggle flag
FALSE value scene                                 \ scene toggle flag

\ ---[ Variable Initializations ]------------------------------------

900e xrot F!
900e yrot F!
900e zrot F!
900e rolling F!

\ ---[ LoadGLTextures ]----------------------------------------------
\ function to load in bitmap as a GL texture

: LoadGLTextures ( -- )
  \ create variables for storing surface pointers and return flag
  5 MallocTextures      \ MallocTextures allocates only when not done
  NumTextures texture[] gl-gen-textures         \ create the textures
  \ Attempt to load the texture images by using a mapping
   s" logo.bmp"   0 ahndl LoadGLTexture
   s" mask1.bmp"  1 ahndl LoadGLTexture
   s" image1.bmp" 2 ahndl LoadGLTexture
   s" mask2.bmp"  3 ahndl LoadGLTexture
   s" image2.bmp" 4 ahndl LoadGLTexture
;

\ ---[ HandleKeyPress ]----------------------------------------------
\ function to handle key press events:
:long$ h20$
$| About lesson 20:
$|
$| Key-list for the available functions in this lesson:
$|
$| ESC      exits the lesson
$| w        toggles between fullscreen and windowed modes
$| m        toggles masking
$| SPACE    toggles the scene to display
  ;long$

: HandleKeyPress ( &event -- )
  case
   \ SDLK_ESCAPE of TRUE to opengl-exit-flag endof
    ascii W     of  start/end-fullscreen 		 endof
    ASCII M     of   masking if 0 else 1 then to masking endof
    BL          of scene if 0 else 1 then to scene 	 endof
                h20$ ShowHelp
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

: InitGL ( -- )
  \ Load in the texture
  LoadGLTextures
    0e 0e 0e 0.5e gl-clear-color           \ Set the background black
    1e gl-clear-depth                            \ Depth buffer setup
    GL_DEPTH_TEST gl-enable                    \ Enable depth testing
    GL_SMOOTH gl-shade-model                  \ Enable smooth shading
    GL_TEXTURE_2D gl-enable                  \ Enable texture mapping
 ;

\ ---[ DrawGLScene ]-------------------------------------------------
\ Here goes our drawing code

: -rolling rolling F@ FNEGATE ;

: DrawGLScene ( -- boolean )
  \ Clear the screen and the depth buffer
  GL_COLOR_BUFFER_BIT GL_DEPTH_BUFFER_BIT OR gl-clear

  gl-load-identity                                   \ restore matrix

  0e 0e -2e gl-translate-f             \ Move into the screen 2 units

  GL_TEXTURE_2D 0 texture-ndx @ gl-bind-texture    \ set logo texture

  GL_QUADS gl-begin                            \ draw a textured quad
    0e -rolling 0e F+ gl-tex-coord-2f -1.1e -1.1e 0e gl-vertex-3f
    3e -rolling 0e F+ gl-tex-coord-2f  1.1e -1.1e 0e gl-vertex-3f
    3e -rolling 3e F+ gl-tex-coord-2f  1.1e  1.1e 0e gl-vertex-3f
    0e -rolling 3e F+ gl-tex-coord-2f -1.1e  1.1e 0e gl-vertex-3f
  gl-end


  GL_BLEND gl-enable                                \ enable blending
  GL_DEPTH_TEST gl-disable                    \ disable depth testing

  masking if                                    \ is masking enabled?
    GL_DST_COLOR GL_ZERO gl-blend-func
  then

  scene if                                   \ draw the second scene?
    0e 0e -1e gl-translate-f       \ Translate into the screen 1 unit
    \ Rotate on the Z axis 360 degrees
    rolling F@ 360e F* 0e 0e 1e gl-rotate-f

    masking if
      \ Select the second mask texture
      GL_TEXTURE_2D 3 texture-ndx @ gl-bind-texture
      GL_QUADS gl-begin                        \ draw a textured quad
        0e 1e gl-tex-coord-2f -1.1e -1.1e 0e gl-vertex-3f
        1e 1e gl-tex-coord-2f  1.1e -1.1e 0e gl-vertex-3f
        1e 0e gl-tex-coord-2f  1.1e  1.1e 0e gl-vertex-3f
        0e 0e gl-tex-coord-2f -1.1e  1.1e 0e gl-vertex-3f
      gl-end
    then

    \ Copy Image 2 Color To The Screen
    GL_ONE GL_ONE gl-blend-func
    \ Select The Second Image Texture
    GL_TEXTURE_2D 4 texture-ndx @ gl-bind-texture
    \ Start Drawing A Textured Quad
    GL_QUADS gl-begin                          \ draw a textured quad
      0e 1e gl-tex-coord-2f -1.1e -1.1e 0e gl-vertex-3f
      1e 1e gl-tex-coord-2f  1.1e -1.1e 0e gl-vertex-3f
      1e 0e gl-tex-coord-2f  1.1e  1.1e 0e gl-vertex-3f
      0e 0e gl-tex-coord-2f -1.1e  1.1e 0e gl-vertex-3f
    gl-end
  else
     masking if
      \ Select the first mask texture
      GL_TEXTURE_2D 1 texture-ndx @ gl-bind-texture
      GL_QUADS gl-begin                        \ draw a textured quad
        rolling F@       4e gl-tex-coord-2f
        -1.1e -1.1e 0e gl-vertex-3f
        rolling F@ 4e F+ 4e gl-tex-coord-2f
         1.1e -1.1e 0e gl-vertex-3f
        rolling F@ 4e F+ 0e gl-tex-coord-2f
         1.1e  1.1e 0e gl-vertex-3f
        rolling F@       0e gl-tex-coord-2f
        -1.1e  1.1e 0e gl-vertex-3f
      gl-end
    then
    \ Copy Image 1 Color To The Screen
    GL_ONE GL_ONE gl-blend-func
    \ Select The First Image Texture
    GL_TEXTURE_2D 2 texture-ndx @ gl-bind-texture
    \ Start Drawing A Textured Quad
    GL_QUADS gl-begin                          \ draw a textured quad
      rolling F@       4e gl-tex-coord-2f -1.1e -1.1e 0e gl-vertex-3f
      rolling F@ 4e F+ 4e gl-tex-coord-2f  1.1e -1.1e 0e gl-vertex-3f
      rolling F@ 4e F+ 0e gl-tex-coord-2f  1.1e  1.1e 0e gl-vertex-3f
      rolling F@       0e gl-tex-coord-2f -1.1e  1.1e 0e gl-vertex-3f
    gl-end
  then

  GL_DEPTH_TEST gl-enable                      \ enable depth testing
  GL_BLEND gl-disable                              \ disable blending

  \ Increase our texture rolling variable
  rolling F@ 0.002e F+ FDUP 1e F> if 1e F- then rolling F!

  \ Draw it to the screen
  sdl-gl-swap-buffers

  xrot F@ 0.3e F+ xrot F!                 \ increment x axis rotation
  yrot F@ 0.2e F+ yrot F!                 \ increment y axis rotation
  zrot F@ 0.4e F+ zrot F!                 \ increment z axis rotation
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


: DrawGLLesson20  ( -- )                          \ Handles ONE frame
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

 ' DrawGLLesson20 to LastLesson
[Forth]
\s
