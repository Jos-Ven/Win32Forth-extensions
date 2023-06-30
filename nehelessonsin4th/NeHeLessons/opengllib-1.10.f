\ ===[ Code Addendum 02 ]============================================
\                 gforth: OpenGL Graphics Lesson 10
\ ===================================================================
\           File: opengllib-1.10.fs
\         Author: Jeff Molofee
\  Linux Version: Ti Leggett
\ gForth Version: Timothy Trussell, 07/25/2010
\    Description: Moving in a 3D world
\   Forth System: gforth-0.7.0
\   Linux System: Ubuntu v10.04 LTS i386, kernel 2.6.31-23
\   C++ Compiler: gcc version 4.4.3 (Ubuntu 4.4.3-4ubuntu5)
\ ===================================================================
\                       NeHe Productions
\                    http://nehe.gamedev.net/
\ ===================================================================
\                   OpenGL Tutorial Lesson 10
\ ===================================================================
\ This code was created by Jeff Molofee '99
\ (ported to Linux/SDL by Ti Leggett '01)
\ March, 2013 adapted for Win32Forth by Jos v.d.Ven
\ Visit Jeff at http://nehe.gamedev.net/
\ ===================================================================

vocabulary Lesson10  also Lesson10 definitions

\ ---[ Structs ]-----------------------------------------------------

\ Build Our Vertex Structure
struct{
  b/FLOAT  vertex-x                              \ 3D Coordinates
  b/FLOAT  vertex-y
  b/FLOAT  vertex-z
  b/FLOAT  vertex-u                         \ Texture Coordinates
  b/FLOAT  vertex-v
}struct vertex%
sizeof vertex% constant /vertex%


\ Build Our Triangle Structure
struct{
  /vertex% 3 * field: vertex[]                \ Array Of Three Vertices
}struct triangle%
sizeof triangle% constant /triangle%

\ Build Our Sector Structure
struct{
  cell sector-#tris                 \ # of triangles in sector
  cell sector-*tris            \ pointer to array of triangles
}struct sector%
sizeof sector% constant /sector%

\ ---[ sector1 ]-----------------------------------------------------
\ Contains the number of polygons in the image, and the address of
\ the array in the dictionary.

here /sector% allot value sector1                        \ Our sector

\ ---[ sector-ndx ]--------------------------------------------------
\ Passed the number of the triangle to access, and the specific
\ vertex required, the base address of that vertex set is returned,
\ from which the vertex -x/-y/-z/-u/-v field can be used to get/set
\ the required vertex address.

\ x_m = sector1.triangle[i].vertex[0].x

: sector-ndx { _#tri _#ver -- *tri[#tri].vertex[#ver] }
  sector1 sector-*tris @                  \ *tri[0]
  /triangle% _#tri * +                    \ *tri[#tri]
  /vertex%   _#ver * +                    \ *(tri[#tri].vertex[#ver])
;

fvariable y-rot                             \ Camera rotation variable
fvariable x-pos                                 \ Camera pos variables
fvariable z-pos
fvariable walkbias                            \ head-bobbin variables
fvariable walkbiasangle
fvariable lookupdown

\ ---[ Light Values ]------------------------------------------------
\ The following three arrays are RGBA color shadings.

\ Ambient Light Values
create LightAmbient[]   0.5e SF, 0.5e SF, 0.5e SF, 1e SF,

\ Diffuse Light Values
create LightDiffuse[]   1e SF, 1e SF, 1e SF, 1e SF,

\ Light Position
create LightPosition[]  0e SF, 0e SF, 2e SF, 1e SF,

0 value filter                                  \ which filter to use

pi 180e F/ fconstant PiOver180            \ for converting to radians
0 value blend

\ ---[ Polygon Definitions ]-----------------------------------------
\ This data definition area holds the contents of the world.txt file
\ that is included in the Lesson 10 source archive.

create [sector-data]

\ Store all of the polygon info into the dictionary.
\ Each group of three lines is a single triangle% struct

0                                              \ init polygon counter

\  x      y       z        u     v
  -3e F,  0e F,  -3e F,    0e F, 6e F,                      \ Floor 1
  -3e F,  0e F,   3e F,    0e F, 0e F,
   3e F,  0e F,   3e F,    6e F, 0e F, 1+      \ increment poly count

  -3e F,  0e F,  -3e F,    0e F, 6e F,
   3e F,  0e F,  -3e F,    6e F, 6e F,
   3e F,  0e F,   3e F,    6e F, 0e F, 1+         \ after each struct

  -3e F,  1e F,  -3e F,    0e F, 6e F,                    \ Ceiling 1
  -3e F,  1e F,   3e F,    0e F, 0e F,
   3e F,  1e F,   3e F,    6e F, 0e F, 1+

  -3e F,  1e F,  -3e F,    0e F, 6e F,
   3e F,  1e F,  -3e F,    6e F, 6e F,
   3e F,  1e F,   3e F,    6e F, 0e F, 1+

  -2e F,  1e F,   -2e F,   0e F, 1e F,                           \ A1
  -2e F,  0e F,   -2e F,   0e F, 0e F,
-0.5e F,  0e F,   -2e F, 1.5e F, 0e F, 1+

  -2e F,  1e F,   -2e F,   0e F, 1e F,
-0.5e F,  1e F,   -2e F, 1.5e F, 1e F,
-0.5e F,  0e F,   -2e F, 1.5e F, 0e F, 1+

   2e F,  1e F,   -2e F,   2e F, 1e F,                           \ A2
   2e F,  0e F,   -2e F,   2e F, 0e F,
 0.5e F,  0e F,   -2e F, 0.5e F, 0e F, 1+

   2e F,  1e F,   -2e F,   2e F, 1e F,
 0.5e F,  1e F,   -2e F, 0.5e F, 1e F,
 0.5e F,  0e F,   -2e F, 0.5e F, 0e F, 1+

  -2e F,  1e F,    2e F,   2e F, 1e F,                           \ B1
  -2e F,  0e F,    2e F,   2e F, 0e F,
-0.5e F,  0e F,    2e F, 0.5e F, 0e F, 1+

  -2e F,  1e F,    2e F,   2e F, 1e F,
-0.5e F,  1e F,    2e F, 0.5e F, 1e F,
-0.5e F,  0e F,    2e F, 0.5e F, 0e F, 1+

   2e F,  1e F,    2e F,   2e F, 1e F,                           \ B2
   2e F,  0e F,    2e F,   2e F, 0e F,
 0.5e F,  0e F,    2e F, 0.5e F, 0e F, 1+

   2e F,  1e F,    2e F,   2e F, 1e F,
 0.5e F,  1e F,    2e F, 0.5e F, 1e F,
 0.5e F,  0e F,    2e F, 0.5e F, 0e F, 1+

  -2e F,  1e F,   -2e F,   0e F, 1e F,                           \ C1
  -2e F,  0e F,   -2e F,   0e F, 0e F,
  -2e F,  0e F, -0.5e F, 1.5e F, 0e F, 1+

  -2e F,  1e F,   -2e F,   0e F, 1e F,
  -2e F,  1e F, -0.5e F, 1.5e F, 1e F,
  -2e F,  0e F, -0.5e F, 1.5e F, 0e F, 1+

  -2e F,  1e F,    2e F,   2e F, 1e F,                           \ C2
  -2e F,  0e F,    2e F,   2e F, 0e F,
  -2e F,  0e F,  0.5e F, 0.5e F, 0e F, 1+

  -2e F,  1e F,    2e F,   2e F, 1e F,
  -2e F,  1e F,  0.5e F, 0.5e F, 1e F,
  -2e F,  0e F,  0.5e F, 0.5e F, 0e F, 1+

   2e F,  1e F,   -2e F,   0e F, 1e F,                           \ D1
   2e F,  0e F,   -2e F,   0e F, 0e F,
   2e F,  0e F, -0.5e F, 1.5e F, 0e F, 1+

   2e F,  1e F,   -2e F,   0e F, 1e F,
   2e F,  1e F, -0.5e F, 1.5e F, 1e F,
   2e F,  0e F, -0.5e F, 1.5e F, 0e F, 1+

   2e F,  1e F,    2e F,   2e F, 1e F,                           \ D2
   2e F,  0e F,    2e F,   2e F, 0e F,
   2e F,  0e F,  0.5e F, 0.5e F, 0e F, 1+

   2e F,  1e F,    2e F,   2e F, 1e F,
   2e F,  1e F,  0.5e F, 0.5e F, 1e F,
   2e F,  0e F,  0.5e F, 0.5e F, 0e F, 1+

-0.5e F,  1e F,   -3e F,   0e F, 1e F,            \ Upper hallway - L
-0.5e F,  0e F,   -3e F,   0e F, 0e F,
-0.5e F,  0e F,   -2e F,   1e F, 0e F, 1+

-0.5e F,  1e F,   -3e F,   0e F, 1e F,
-0.5e F,  1e F,   -2e F,   1e F, 1e F,
-0.5e F,  0e F,   -2e F,   1e F, 0e F, 1+

 0.5e F,  1e F,   -3e F,   0e F, 1e F,            \ Upper hallway - R
 0.5e F,  0e F,   -3e F,   0e F, 0e F,
 0.5e F,  0e F,   -2e F,   1e F, 0e F, 1+

 0.5e F,  1e F,   -3e F,   0e F, 1e F,
 0.5e F,  1e F,   -2e F,   1e F, 1e F,
 0.5e F,  0e F,   -2e F,   1e F, 0e F, 1+

-0.5e F,  1e F,    3e F,   0e F, 1e F,            \ Lower hallway - L
-0.5e F,  0e F,    3e F,   0e F, 0e F,
-0.5e F,  0e F,    2e F,   1e F, 0e F, 1+

-0.5e F,  1e F,    3e F,   0e F, 1e F,
-0.5e F,  1e F,    2e F,   1e F, 1e F,
-0.5e F,  0e F,    2e F,   1e F, 0e F, 1+

 0.5e F,  1e F,    3e F,   0e F, 1e F,            \ Lower hallway - R
 0.5e F,  0e F,    3e F,   0e F, 0e F,
 0.5e F,  0e F,    2e F,   1e F, 0e F, 1+

 0.5e F,  1e F,    3e F,   0e F, 1e F,
 0.5e F,  1e F,    2e F,   1e F, 1e F,
 0.5e F,  0e F,    2e F,   1e F, 0e F, 1+

  -3e F,  1e F,  0.5e F,   1e F, 1e F,            \ Left hallway - Lw
  -3e F,  0e F,  0.5e F,   1e F, 0e F,
  -2e F,  0e F,  0.5e F,   0e F, 0e F, 1+

  -3e F,  1e F,  0.5e F,   1e F, 1e F,
  -2e F,  1e F,  0.5e F,   0e F, 1e F,
  -2e F,  0e F,  0.5e F,   0e F, 0e F, 1+

  -3e F,  1e F, -0.5e F,   1e F, 1e F,            \ Left hallway - Hi
  -3e F,  0e F, -0.5e F,   1e F, 0e F,
  -2e F,  0e F, -0.5e F,   0e F, 0e F, 1+

  -3e F,  1e F, -0.5e F,   1e F, 1e F,
  -2e F,  1e F, -0.5e F,   0e F, 1e F,
  -2e F,  0e F, -0.5e F,   0e F, 0e F, 1+

   3e F,  1e F,  0.5e F,   1e F, 1e F,           \ Right hallway - Lw
   3e F,  0e F,  0.5e F,   1e F, 0e F,
   2e F,  0e F,  0.5e F,   0e F, 0e F, 1+

   3e F,  1e F,  0.5e F,   1e F, 1e F,
   2e F,  1e F,  0.5e F,   0e F, 1e F,
   2e F,  0e F,  0.5e F,   0e F, 0e F, 1+

   3e F,  1e F, -0.5e F,   1e F, 1e F,           \ Right hallway - Hi
   3e F,  0e F, -0.5e F,   1e F, 0e F,
   2e F,  0e F, -0.5e F,   0e F, 0e F, 1+

   3e F,  1e F, -0.5e F,   1e F, 1e F,
   2e F,  1e F, -0.5e F,   0e F, 1e F,
   2e F,  0e F, -0.5e F,   0e F, 0e F, 1+

value #Polygons

[sector-data] sector1 sector-*tris !      \ Initialize sector1 fields
#Polygons     sector1 sector-#tris !

\ ---[ LoadGLTextures ]----------------------------------------------
\ function to load in bitmap as a GL texture


: LoadGLTextures ( -- )
    3 MallocTextures       \ Initialize the number of needed textures
    s" mud.bmp" map-bitmap >R             \ image loaded successfully
    3 texture[] gl-gen-textures                  \ create the texture

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
    MipMappedFiltering                           \ MipMapped Filtering
    \ Generate MipMapped texture 3
    R> Generate-MipMapped-Texture

    ahndl close-map-file drop                     \ Unmap mud.bmp file
;


\ ---[ HandleKeyPress ]----------------------------------------------
\ function to handle key press events:
:long$ h10$
$| About lesson 10:
$|
$| Key-list for the available functions in this lesson:
$|
$| ESC      exits the lesson
$| w        toggles between fullscreen and windowed modes
$| b        toggles between blending on or blending off
$| Up       move forward
$| Down     move backward
$| Right    turns camera to the right
$| Left     turns camera to the left
$| PageUp   looks up
$| PageDown looks down
  ;long$


: HandleKeyPress ( &event -- )
  case
   \ SDLK_ESCAPE   of TRUE to opengl-exit-flag endof
    ascii W            of
                      start/end-fullscreen
                   endof
    VK_UP              of
                     x-pos F@
                     y-rot F@ PiOver180 F* FSIN 0.05e F*
                     F- x-pos F!
                     z-pos F@
                     y-rot F@ PiOver180 F* FCOS 0.05e F*
                     F- z-pos F!
                     walkbiasangle F@ 359e F>= if
                       0e
                     else
                       walkbiasangle F@ 10e F+
                     then
                     FDUP walkbiasangle F!
                     \ Cause the 'player' to bounce
                     PiOver180 F* FSIN 20e F/ walkbias F!
                  endof
    VK_DOWN          of
                     x-pos F@
                     y-rot F@ PiOver180 F* FSIN 0.05e F*
                     F+ x-pos F!
                     z-pos F@
                     y-rot F@ PiOver180 F* FCOS 0.05e F*
                     F+ z-pos F!
                     walkbiasangle F@ 1e F<= if
                       359e
                     else
                       walkbiasangle F@ 10e F-
                     then
                     FDUP walkbiasangle F!
                     \ Cause the 'player' to bounce
                     PiOver180 F* FSIN 20e F/ walkbias F!
                  endof
    ascii B         of blend dup not to blend
                          if    GL_BLEND glDisable
                                GL_DEPTH_TEST glEnable
                          else  GL_BLEND glEnable
                                GL_DEPTH_TEST glDisable
                          then
                  endof

    VK_RIGHT        of y-rot F@ 1.5e F- y-rot F! endof
    VK_LEFT         of y-rot F@ 1.5e F+ y-rot F! endof
    VK_PGUP         of -1.e lookupdown F+!       endof
    VK_PGDN         of  1.e lookupdown F+! 	 endof

                     h10$ ShowHelp
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

    0e lookupdown F!
    0e walkbias F!
    0e walkbiasangle F!

    \ Full brightness, 50% Alpha
    1e 1e 1e 0.5e gl-color-4f
    \ Blending translucency based on source alpha value
    GL_SRC_ALPHA GL_ONE gl-blend-func
;


\ ---[ DrawGLScene ]-------------------------------------------------
\ Here goes our drawing code

fvariable x-m
fvariable y-m
fvariable z-m
fvariable u-m
fvariable v-m
fvariable x-trans
fvariable z-trans
fvariable y-trans
fvariable SceneRotY

: DrawGLScene ( -- boolean )
  x-pos F@ fnegate x-trans F!
  z-pos F@ fnegate z-trans F!
  walkbias F@ 0.25e F- y-trans F!
  360e y-rot F@ F- SceneRotY F!

  \ Clear the screen and the depth buffer
  GL_COLOR_BUFFER_BIT GL_DEPTH_BUFFER_BIT OR gl-clear
  gl-load-identity                                   \ restore matrix
  \ Rotate up and down to look up and down
  lookupdown F@ 1e 0e 0e gl-rotate-f
  \ Rotate depending on direction 'player' is facing
  SceneRotY F@ 0e 1e 0e gl-rotate-f
  \ Translate the scene based on 'player' position
  x-trans F@ y-trans F@ z-trans F@ gl-translate-f
  \ Select a texture based on filter
  GL_TEXTURE_2D filter texture-ndx @ gl-bind-texture

  \ Process each triangle
  sector1 sector-#tris @ 0 do
    GL_TRIANGLES gl-begin
      \ Normal pointing forward
      0e 0e 1e gl-normal-3f

      \ Vertices of first point
      i 0 sector-ndx vertex-u F@
      i 0 sector-ndx vertex-v F@
      gl-tex-coord-2f                        \ set texture coordinate
      i 0 sector-ndx vertex-x F@
      i 0 sector-ndx vertex-y F@
      i 0 sector-ndx vertex-z F@
      gl-vertex-3f                                  \ set the vertice

      \ Vertices of second point
      i 1 sector-ndx vertex-u F@
      i 1 sector-ndx vertex-v F@
      gl-tex-coord-2f                        \ set texture coordinate
      i 1 sector-ndx vertex-x F@
      i 1 sector-ndx vertex-y F@
      i 1 sector-ndx vertex-z F@
      gl-vertex-3f                                  \ set the vertice

      \ Vertices of third point
      i 2 sector-ndx vertex-u F@
      i 2 sector-ndx vertex-v F@
      gl-tex-coord-2f                        \ set texture coordinate
      i 2 sector-ndx vertex-x F@
      i 2 sector-ndx vertex-y F@
      i 2 sector-ndx vertex-z F@
      gl-vertex-3f                                  \ set the vertice
    gl-end
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


: DrawGLLesson10  ( -- )                          \ Handles ONE frame
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


 ' DrawGLLesson10 to LastLesson
[Forth]
\s
