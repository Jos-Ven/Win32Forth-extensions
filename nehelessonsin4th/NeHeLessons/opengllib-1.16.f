\ ===================================================================
\           File: opengllib-1.16.fs
\         Author: Jeff Molofee
\  Linux Version: Ti Leggett
\ gForth Version: Timothy Trussell, 07/31/2010
\    Description: Cool looking fog
\   Forth System: gforth-0.7.0
\   Linux System: Ubuntu v10.04 LTS i386, kernel 2.6.31-24
\   C++ Compiler: gcc (Ubuntu 4.4.1-4ubuntu9) 4.4.1
\ ===================================================================
\                       NeHe Productions
\                    http://nehe.gamedev.net/
\ ===================================================================
\                   OpenGL Tutorial Lesson 16
\ ===================================================================
\ This code was created by Jeff Molofee '99
\ (ported to Linux/SDL by Ti Leggett '01)
\ March, 2013 adapted for Win32Forth by Jos v.d.Ven
\ Visit Jeff at http://nehe.gamedev.net/
\ ===================================================================

vocabulary Lesson16  also Lesson16 definitions

\ ---[ Variable Declarations ]---------------------------------------


fvariable xrot                                           \ X rotation
fvariable yrot                                           \ Y rotation
fvariable xspeed                                   \ x rotation speed
fvariable yspeed                                   \ y rotation speed
fvariable zdepth                              \ depth into the screen

0 value FogFilter                                  \ which fog to use
0 value filter                                  \ which filter to use
FALSE value light                         \ lighting is initially off


create FogMode[] GL_EXP , GL_EXP2 , GL_LINEAR ,      \ 3 types of fog

\ ---[ Array Index Functions ]---------------------------------------
\ Index functions to access the arrays

: fogmode-ndx ( n -- *texture[n] ) 3 mod cell * FogMode[] + ;

\ ---[ Light Values ]------------------------------------------------
\ The following three arrays are RGBA color shadings.
\ These light tables are passed by address to gl-light-fv, not value
\ Therefore, OpenGL expects them to be 32-bit floats (gforth sfloats)

\ Ambient Light Values
create LightAmbient[]   0.5e SF, 0.5e SF, 0.5e SF, 1e SF,

\ Diffuse Light Values
create LightDiffuse[]   1e SF, 1e SF, 1e SF, 1e SF,

\ Light Position
create LightPosition[]  0e SF, 0e SF, 2e SF, 1e SF,

\ Fog Color
create FogColor[]       0.5e SF, 0.5e SF, 0.5e SF, 1e SF,

\ ---[ Variable Initializations ]------------------------------------

0e xrot F!
0e yrot F!

1e xspeed F!
1e yspeed F!
-5e zdepth F!

\ ---[ LoadGLTextures ]----------------------------------------------
\ function to load in bitmap as a GL texture


: LoadGLTextures ( -- )
    3 MallocTextures        \ Initialize the number of needed textures

    s" crate.bmp" map-bitmap >R            \ image loaded successfully
\   cr ." Texture Image loaded" cr
    NumTextures texture[] gl-gen-textures        \ create the textures

  \ Load in texture 1
    0 BindTexture-ndx                                     \ texture[0]
    \ Generate texture 1
    R@ Generate-Texture

    \ Nearest Filtering
    NearestFiltering
  \ Load in texture 2
    1 BindTexture-ndx                                     \ texture[1]


    \ Linear Filtering
    LinearFiltering
    \ Generate texture 2
    R@ Generate-Texture

  \ Load in texture 3
    2 BindTexture-ndx                                     \ texture[2]

    \ MipMapped Filtering
    MipMappedFiltering
    \ Generate MipMapped texture 3
    R> Generate-MipMapped-Texture
    ahndl close-map-file drop
;

\ ---[ HandleKeyPress ]----------------------------------------------
\ function to handle key press events:
:long$ h16$
$| About lesson 16:
$|
$| Key-list for the available functions in this lesson:
$|
$| ESC      exits the lesson
$| w        toggles between fullscreen and windowed modes
$| f        cycle thru the different filters
$| g        cycle thru the different fogs
$| l        toggles the light on/off
$| PageUp   zooms into the scene
$| PageDown zooms out of the scene
$| Up       makes x rotation more negative - incremental
$| Down     makes x rotation more positive - incremental
$| Left     makes y rotation more negative - incremental
$| Right    makes y rotation more positive - incremental
  ;long$

: HandleKeyPress ( &event -- )
  case
  \  VK_ESCAPE  of TRUE to opengl-exit-flag endof
    ascii W     of  start/end-fullscreen	endof
    ascii F     of  filter 1+ 3 MOD to filter	endof
    ascii G     of  FogFilter 1+ 3 MOD to FogFilter
                    GL_FOG_MODE FogFilter
                    fogmode-ndx @ gl-fog-i 	endof
    ascii L     of  light if 0 else 1 then
                    dup to light
                       if   GL_LIGHTING gl-enable
                       else GL_LIGHTING gl-disable
                       then
						endof
    VK_PGUP     of zdepth F@ 0.02e F- zdepth F! endof
    VK_PGDN	of zdepth F@ 0.02e F+ zdepth F! endof
    VK_UP       of xspeed F@ 0.01e F- xspeed F! endof
    VK_DOWN     of xspeed F@ 0.01e F+ xspeed F! endof
    VK_RIGHT    of yspeed F@ 0.01e F+ yspeed F! endof
    VK_LEFT     of yspeed F@ 0.01e F- yspeed F! endof
                 h16$ ShowHelp
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
    \ Set the background color
    0.5e 0.5e 0.5e 1e gl-clear-color
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

    \ ---[ Set up the Fog ]---

    GL_FOG_MODE FogFilter fogmode-ndx @ gl-fog-i       \ Set Fog mode
    GL_FOG_COLOR FogColor[] gl-fog-fv                 \ Set Fog color
    GL_FOG_DENSITY 0.35e gl-fog-f            \ Set density of the Fog
    GL_FOG_HINT GL_DONT_CARE gl-hint                 \ Fog Hint value
    GL_FOG_START 1e gl-fog-f                        \ Fog start depth
    GL_FOG_END 5e gl-fog-f                            \ Fog end depth
    GL_FOG gl-enable                                  \ Enable GL_FOG
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


: DrawGLLesson16  ( -- )                          \ Handles ONE frame
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

 ' DrawGLLesson16 to LastLesson
[Forth]
\s

