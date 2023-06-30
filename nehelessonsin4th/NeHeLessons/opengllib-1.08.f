\ ===================================================================
\           File: opengllib-1.08.fs
\         Author: Jeff Molofee
\  Linux Version: Ti Leggett
\ gForth Version: Timothy Trussell, 07/25/2010
\    Description: Blending
\   Forth System: gforth-0.7.0
\   Linux System: Ubuntu v10.04 LTS i386, kernel 2.6.31-23
\   C++ Compiler: gcc version 4.4.3 (Ubuntu 4.4.3-4ubuntu5)
\ ===================================================================
\                       NeHe Productions
\                    http://nehe.gamedev.net/
\ ===================================================================
\                   OpenGL Tutorial Lesson 08
\ ===================================================================
\ This code was created by Jeff Molofee '99
\ (ported to Linux/SDL by Ti Leggett '01)
\ March, 2013 adapted for Win32Forth by Jos v.d.Ven
\ Visit Jeff at http://nehe.gamedev.net/
\ ===================================================================

vocabulary Lesson08  also Lesson08 definitions

\ ---[ Variable Declarations ]---------------------------------------

fvariable xrot                                           \ X rotation
fvariable yrot                                           \ Y rotation
fvariable xspeed                                   \ x rotation speed
fvariable yspeed                                   \ y rotation speed
fvariable zdepth                              \ depth into the screen

FALSE value light                     \ whether or not lighting is on
FALSE value blend                     \ whether or not blending is on

\ ---[ Light Values ]------------------------------------------------
\ The following three arrays are RGBA color shadings.
\ They can be accessed by either an index function, or by a struct

\ These light tables are passed by address to gl-light-fv, not value,
\ so they must be stored as 32-bit floats, not normal 64-bit floats.

\ Ambient Light Values
create LightAmbient[]   0.5e SF, 0.5e SF, 0.5e SF, 1e SF,

\ Diffuse Light Values
create LightDiffuse[]   1e SF, 1e SF, 1e SF, 1e SF,

\ Light Position
create LightPosition[]  0e SF, 0e SF, 2e SF, 1e SF,

0 value filter                                  \ which filter to use

\ ---[ Variable Initializations ]------------------------------------

0e xrot F!
0e yrot F!
1e xspeed F!
1e yspeed F!
-5e zdepth F!

\ ---[ LoadGLTextures ]----------------------------------------------
\ function to load in bitmap as a GL texture

: LoadGLTextures ( -- )
    3 MallocTextures       \ Initialize the number of needed textures
    s" glass.bmp" map-bitmap  >R          \ image loaded successfully
    NumTextures texture[] gl-gen-textures       \ create the textures

    \ Load in texture 1
    0 BindTexture-ndx                                    \ texture[0]
    \ Generate texture 1
    R@ Generate-Texture

    \ Nearest Filtering
    NearestFiltering
    \ Load in texture 2
    1 BindTexture-ndx                                    \ texture[1]

    \ Linear Filtering
    LinearFiltering
    \ Generate texture 2
    R@ Generate-Texture

    \ Load in texture 3
    2 BindTexture-ndx                                    \ texture[2]
    \ MipMapped Filtering
    MipMappedFiltering
    \ Generate MipMapped texture 3
    R> Generate-MipMapped-Texture

    ahndl close-map-file drop                  \ Unmap glass.bmp file
;



\ ---[ HandleKeyPress ]----------------------------------------------
\ function to handle key press events:
:long$ h08$
$| About lesson 08:
$|
$| Key-list for the available functions in this lesson:
$|
$|   ESC      exits the lesson
$|   w        toggles between fullscreen and windowed modes
$|   PageUp   zooms into the scene
$|   PageDown zooms out of the scene
$|   b        toggles blending on/off
$|   f        pages thru the different filters [0..2]
$|   l        toggles the light on/off
$|   Up       makes x rotation more negative - incremental
$|   Down     makes x rotation more positive - incremental
$|   Left     makes y rotation more negative - incremental
$|   Right    makes y rotation more positive - incremental
$|   Home     Resets depth and speed
$|
$|  Tip: Try blending with the 'b' key!
  ;long$

: HandleKeyPress ( &event -- )
  case
    \ SDLK_ESCAPE   of TRUE to opengl-exit-flag endof \ Done in OpenGL.f
    ascii W     of start/end-fullscreen            	endof
    VK_PGUP     of zdepth F@ 0.02e F- zdepth F!		endof
    VK_PGDN     of zdepth F@ 0.02e F+ zdepth F! 	endof
    ascii B     of 1 blend xor dup to blend if
                         GL_BLEND gl-enable
                         GL_DEPTH_TEST gl-disable
                       else
                         GL_BLEND gl-disable
                         GL_DEPTH_TEST gl-enable
                       then
							endof
    ascii F     of  filter 1+ 3 MOD to filter endof
    ascii L     of  1 light xor to light
                       light if   GL_LIGHTING gl-enable
                             else GL_LIGHTING gl-disable
                             then
							endof
    VK_UP       of xspeed F@ 0.01e F- xspeed F! 	endof
    VK_DOWN     of xspeed F@ 0.01e F+ xspeed F! 	endof
    VK_RIGHT    of yspeed F@ 0.01e F+ yspeed F! 	endof
    VK_LEFT     of yspeed F@ 0.01e F- yspeed F! 	endof
    VK_HOME     of 1e yspeed F!    1e xspeed F!               \ Resets the speed and
                   -5e zdepth F! 			endof \ zdepth to the default value
                h08$ ShowHelp
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
    \ Enable texture mapping
    GL_TEXTURE_2D gl-enable
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
    \ Set up the ambient light
    GL_LIGHT1 GL_AMBIENT LightAmbient[] gl-light-fv
    \ Set up the diffuse light
    GL_LIGHT1 GL_DIFFUSE LightDiffuse[] gl-light-fv
    \ Position the light
    GL_LIGHT1 GL_POSITION LightPosition[] gl-light-fv
    \ Enable Light One
    GL_LIGHT1 gl-enable
    \ Full brightness, 50% Alpha
    1e 1e 1e 0.5e gl-color-4f
    \ Blending translucency based on source alpha value
    GL_SRC_ALPHA GL_ONE gl-blend-func
;


\ ---[ DrawGLScene ]-------------------------------------------------
\ Here goes our drawing code

: DrawGLScene ( -- )
  \ Clear the screen and the depth buffer
  GL_COLOR_BUFFER_BIT GL_DEPTH_BUFFER_BIT OR gl-clear

  gl-load-identity                                   \ restore matrix

  \ Translate into/out of the screen by zdepth
  0e 0e zdepth F@ gl-translate-f

  xrot F@ 1e 0e 0e gl-rotate-f                 \ rotate on the X axis
  yrot F@ 0e 1e 0e gl-rotate-f                 \ rotate on the Y axis

  \ Select a texture based on filter
  GL_TEXTURE_2D filter texture-ndx @ gl-bind-texture

  GL_QUADS gl-begin                                     \ draw a quad
  \ Front face
    0e 0e 1e gl-normal-3f            \ normal pointing towards viewer
    1e 0e gl-tex-coord-2f -1e -1e  1e gl-vertex-3f  \ Point 1 - front
    0e 0e gl-tex-coord-2f  1e -1e  1e gl-vertex-3f  \ Point 2 - front
    0e 1e gl-tex-coord-2f  1e  1e  1e gl-vertex-3f  \ Point 3 - front
    1e 1e gl-tex-coord-2f -1e  1e  1e gl-vertex-3f  \ Point 4 - front

    \ Back face
    0e 0e -1e gl-normal-3f         \ Normal pointing away from viewer
    0e 0e gl-tex-coord-2f -1e -1e -1e gl-vertex-3f   \ Point 1 - back
    0e 1e gl-tex-coord-2f -1e  1e -1e gl-vertex-3f   \ Point 2 - back
    1e 1e gl-tex-coord-2f  1e  1e -1e gl-vertex-3f   \ Point 3 - back
    1e 0e gl-tex-coord-2f  1e -1e -1e gl-vertex-3f   \ Point 4 - back

    \ Top face
    0e 1e 0e gl-normal-3f                        \ Normal pointing up
    1e 1e gl-tex-coord-2f -1e  1e -1e gl-vertex-3f    \ Point 1 - top
    1e 0e gl-tex-coord-2f -1e  1e  1e gl-vertex-3f    \ Point 2 - top
    0e 0e gl-tex-coord-2f  1e  1e  1e gl-vertex-3f    \ Point 3 - top
    0e 1e gl-tex-coord-2f  1e  1e -1e gl-vertex-3f    \ Point 4 - top

    \ Bottom face
    0e -1e 0e gl-normal-3f                     \ Normal pointing down
    0e 1e gl-tex-coord-2f -1e -1e -1e gl-vertex-3f \ Point 1 - bottom
    1e 1e gl-tex-coord-2f  1e -1e -1e gl-vertex-3f \ Point 2 - bottom
    1e 0e gl-tex-coord-2f  1e -1e  1e gl-vertex-3f \ Point 3 - bottom
    0e 0e gl-tex-coord-2f -1e -1e  1e gl-vertex-3f \ Point 4 - bottom

    \ Right face
    1e 0e 0e gl-normal-3f                     \ Normal pointing right
    0e 0e gl-tex-coord-2f  1e -1e -1e gl-vertex-3f  \ Point 1 - right
    0e 1e gl-tex-coord-2f  1e  1e -1e gl-vertex-3f  \ Point 1 - right
    1e 1e gl-tex-coord-2f  1e  1e  1e gl-vertex-3f  \ Point 1 - right
    1e 0e gl-tex-coord-2f  1e -1e  1e gl-vertex-3f  \ Point 1 - right

    \ Left face
    -1e 0e 0e gl-normal-3f                     \ Normal pointing left
    1e 0e gl-tex-coord-2f -1e -1e -1e gl-vertex-3f   \ Point 1 - left
    0e 0e gl-tex-coord-2f -1e -1e  1e gl-vertex-3f   \ Point 2 - left
    0e 1e gl-tex-coord-2f -1e  1e  1e gl-vertex-3f   \ Point 3 - left
    1e 1e gl-tex-coord-2f -1e  1e -1e gl-vertex-3f   \ Point 4 - left
  gl-end

  \ Draw it to the screen
  sdl-gl-swap-buffers

  xrot F@ xspeed F@ F+ xrot F!                   \ add xspeed to xrot
  yrot F@ yspeed F@ F+ yrot F!                   \ add yspeed to yrot
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


: DrawGLLesson08  ( -- )                          \ Handles ONE frame
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

 ' DrawGLLesson08 to LastLesson
[Forth]
\s
