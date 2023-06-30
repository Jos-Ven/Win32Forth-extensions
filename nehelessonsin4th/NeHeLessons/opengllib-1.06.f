\ ===[ Code Addendum 02 ]============================================
\                 gforth: OpenGL Graphics Lesson 06
\ ===================================================================
\           File: opengllib-1.06.fs
\         Author: Jeff Molofee
\  Linux Version: Ti Leggett
\ gForth Version: Timothy Trussell, 07/24/2010
\    Description: Texture Mapping
\   Forth System: gforth-0.7.0
\   Linux System: Ubuntu v10.04 LTS i386, kernel 2.6.31-23
\   C++ Compiler: gcc version 4.4.3 (Ubuntu 4.4.3-4ubuntu5)
\ ===================================================================
\                       NeHe Productions
\                    http://nehe.gamedev.net/
\ ===================================================================
\                   OpenGL Tutorial Lesson 06
\ ===================================================================
\ This code was created by Jeff Molofee '99
\ (ported to Linux/SDL by Ti Leggett '01)
\ March, 2013 adapted for Win32Forth by Jos v.d.Ven
\ Visit Jeff at http://nehe.gamedev.net/
\ ===================================================================

vocabulary Lesson06  also Lesson06 definitions

\ ---[ Variable Declarations ]---------------------------------------

\ Added for Lesson 06
fvariable xrot                                           \ X rotation
fvariable yrot                                           \ Y rotation
fvariable zrot                                           \ Z rotation

\ ---[ Variable Initializations ]------------------------------------

0e xrot F!
0e yrot F!
0e zrot F!

\ ---[ HandleKeyPress ]----------------------------------------------
\ function to handle key press events:
:long$ h06$
$| About lesson 06:
$|
$| Key-list for the available functions in this lesson:
$|
$| ESC      exits the lesson
$| w        toggles between fullscreen and windowed modes
  ;long$


: HandleKeyPress ( &event -- )          \ Escape is handled in OpenGL.f
    ascii W =
      if     start/end-fullscreen       \ Starts of end the full screen
      else   h06$ ShowHelp         \ Show the help text for this lesson
      then
;

\ ---[ LoadGLTextures ]----------------------------------------------
\ function to load in bitmap as an OpenGL texture

: LoadGLTextures ( -- )
  \ create variables for storing surface pointers and return flag
  1 MallocTextures      \ MallocTextures allocates only when not done
  NumTextures texture[] gl-gen-textures         \ create the textures
  \ Attempt to load the texture images by using a mapping
  s" nehe.bmp"  0 ahndl LoadGLTexture                       \ ndx = 0
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
    LoadGLTextures                              \ Load in the texture
    GL_TEXTURE_2D gl-enable                  \ Enable texture mapping
    GL_SMOOTH gl-shade-model                  \ Enable smooth shading
    0e 0e 0e 0e gl-clear-color             \ Set the background black
    1e gl-clear-depth                            \ Depth buffer setup
    GL_DEPTH_TEST gl-enable                    \ Enable depth testing
    GL_LEQUAL gl-depth-func                \ Type of depth test to do
    \ Really nice perspective calculations
    GL_PERSPECTIVE_CORRECTION_HINT GL_NICEST gl-hint
;

\ ---[ DrawGLScene ]-------------------------------------------------
\ Here goes our drawing code

: DrawGLScene ( -- boolean )
  \ Clear the screen and the depth buffer
  GL_COLOR_BUFFER_BIT GL_DEPTH_BUFFER_BIT OR gl-clear

  gl-load-identity                                   \ restore matrix

  0e 0e -5e gl-translate-f             \ Move into the screen 5 units

  xrot F@ 1e 0e 0e gl-rotate-f                 \ rotate on the X axis
  yrot F@ 0e 1e 0e gl-rotate-f                 \ rotate on the Y axis
  zrot F@ 0e 0e 1e gl-rotate-f                 \ rotate on the Z axis

  GL_TEXTURE_2D 0 texture-ndx @ gl-bind-texture  \ Select our texture

\ ---[Note]----------------------------------------------------------
\ The x coordinates of the glTexCoord2f function need to be inverted
\ for SDL because of the way SDL_LoadBmp loads the data. So where
\ in the tutorial it has glTexCoord2f( 1.0f, 0.0f ); it should
\ now read glTexCoord2f( 0.0f, 1.0f );                   - Ti Leggett
\ March 2013: glTexCoord2f adapted for Win32Forth        - Jos Ven
\ ------------------------------------------------------[End Note]---

  GL_QUADS gl-begin                                     \ draw a quad
  \ Front face of the texture and quad
    0e 0e gl-tex-coord-2f -1e -1e  1e gl-vertex-3f      \ bottom left
    1e 0e gl-tex-coord-2f  1e -1e  1e gl-vertex-3f     \ bottom right
    1e 1e gl-tex-coord-2f  1e  1e  1e gl-vertex-3f        \ top right
    0e 1e gl-tex-coord-2f -1e  1e  1e gl-vertex-3f         \ top left

    \ Back face of the texture and quad
    1e 0e gl-tex-coord-2f -1e -1e -1e gl-vertex-3f     \ bottom right
    1e 1e gl-tex-coord-2f -1e  1e -1e gl-vertex-3f        \ top right
    0e 1e gl-tex-coord-2f  1e  1e -1e gl-vertex-3f         \ top left
    0e 0e gl-tex-coord-2f  1e -1e -1e gl-vertex-3f      \ bottom left

    \ Top face of the texture and quad
    0e 1e gl-tex-coord-2f -1e  1e -1e gl-vertex-3f         \ top left
    0e 0e gl-tex-coord-2f -1e  1e  1e gl-vertex-3f      \ bottom left
    1e 0e gl-tex-coord-2f  1e  1e  1e gl-vertex-3f     \ bottom right
    1e 1e gl-tex-coord-2f  1e  1e -1e gl-vertex-3f        \ top right

    \ Bottom face of the texture and quad
    1e 1e gl-tex-coord-2f -1e -1e -1e gl-vertex-3f        \ top right
    0e 1e gl-tex-coord-2f  1e -1e -1e gl-vertex-3f         \ top left
    0e 0e gl-tex-coord-2f  1e -1e  1e gl-vertex-3f      \ bottom left
    1e 0e gl-tex-coord-2f -1e -1e  1e gl-vertex-3f     \ bottom right

    \ Right face of the texture and quad
    1e 0e gl-tex-coord-2f  1e -1e -1e gl-vertex-3f     \ bottom right
    1e 1e gl-tex-coord-2f  1e  1e -1e gl-vertex-3f        \ top right
    0e 1e gl-tex-coord-2f  1e  1e  1e gl-vertex-3f         \ top left
    0e 0e gl-tex-coord-2f  1e -1e  1e gl-vertex-3f      \ bottom left

    \ Left face of the texture and quad
    0e 0e gl-tex-coord-2f -1e -1e -1e gl-vertex-3f      \ bottom left
    1e 0e gl-tex-coord-2f -1e -1e  1e gl-vertex-3f     \ bottom right
    1e 1e gl-tex-coord-2f -1e  1e  1e gl-vertex-3f        \ top right
    0e 1e gl-tex-coord-2f -1e  1e -1e gl-vertex-3f         \ top left
  gl-end

  sdl-gl-swap-buffers                         \ Draw it to the screen
\  fps-frames 1+ to fps-frames    \ Gather our frames per second count
\  Display-FPS          \ Display the FPS count to the terminal window

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
    set-viewpoint                                \ Set the viewpoint
    false to resizing?
 ;


also Forth definitions

: DrawGLLesson06  ( -- )                          \ Handles ONE frame
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

: -DrawGLLesson06  ( -- )
  ['] HandleKeyPress is KeyboardAction \ Use the keystrokes for this lesson only
  Reset-request-to-stop
  DynamicScene                               \ Prepare a dynamic scene
  InitGL                      \ Enable some features and load textures
  set-viewpoint                                   \ Set the viewpoint
  false to request-to-stop    \ Play the game till ESCAPE has been hit
      begin             \ The begin...until structure makes it dynamic
         DrawGLScene           \ Redraw only the changes in the lesson
         ProcesKeyAndRelease                \ HandleKeyPress only here
         request-to-stop               \ Until escape has been pressed
     until
 ;

' DrawGLLesson06 to LastLesson

[Forth]
