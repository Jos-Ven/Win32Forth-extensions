\ ===================================================================
\           File: opengllib-1.18.fs
\         Author: GB Schmick
\  Linux Version: Ti Leggett
\ gForth Version: Timothy Trussell, 08/01/2010
\    Description: Quadrics
\   Forth System: gforth-0.7.0
\   Linux System: Ubuntu v10.04 LTS i386, kernel 2.6.31-24
\   C++ Compiler: gcc (Ubuntu 4.4.1-4ubuntu9) 4.4.1
\ ===================================================================
\                       NeHe Productions
\                    http://nehe.gamedev.net/
\ ===================================================================
\                   OpenGL Tutorial Lesson 18
\ ===================================================================
\ This code was created by Jeff Molofee '99
\ (ported to Linux/SDL by Ti Leggett '01)
\ March, 2013 adapted for Win32Forth by Jos v.d.Ven
\ Visit Jeff at http://nehe.gamedev.net/
\ ===================================================================

vocabulary Lesson18  also Lesson18 definitions

\ ---[ Variable Declarations ]---------------------------------------

FALSE value light                         \ lighting is initially off

0 value filter                                  \ which filter to use

0 value quadratic                 \ storage for our quadratic objects
5 value q-object                              \ which object to draw

fvariable Part1                                       \ start of disc
fvariable Part2                                         \ end of disc
fvariable p1                                             \ increase 1
fvariable p2                                             \ increase 2
fvariable xrot                                           \ x rotation
fvariable yrot                                           \ y rotation
fvariable xspeed                                   \ x rotation speed
fvariable yspeed                                   \ y rotation speed
fvariable zdepth                                  \ depth into screen

\ From <glu.h> for QuadricNormal defines
\ -- I have not converted the constants in glu.h as yet

100000 constant GLU_SMOOTH
100001 constant GLU_FLAT
100002 constant GLU_NONE

\ ---[ Variable Initializations ]------------------------------------

0e p1 F!
1e p2 F!
-5e zdepth F! \ -5e

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

\ ---[ LoadGLTextures ]----------------------------------------------
\ function to load in bitmap as a GL texture

: LoadGLTextures ( -- )
    3 MallocTextures       \ Initialize the number of needed textures
    \ Attempt to load the texture images into SDL surfaces
    s" wall.bmp" map-bitmap >R                  \ save surface pointer

    NumTextures texture[] gl-gen-textures        \ create the textures

    \ Load texture 0
    0 BindTexture-ndx                                     \ texture[0]

    \ Generate texture 0
    R@ Generate-Texture

    \ Nearest Filtering
    NearestFiltering

    \ Load texture 1
    1 BindTexture-ndx                                     \ texture[1]

    \ Linear Filtering
    LinearFiltering

    \ Generate texture 1
    R@ Generate-Texture

    \ Load texture 2
    2 BindTexture-ndx                                     \ texture[2]

    \ MipMapped Filtering
    MipMappedFiltering

    \ Generate texture 2
    R> Generate-MipMapped-Texture

    ahndl close-map-file 2drop
;

\ ---[ HandleKeyPress ]----------------------------------------------
\ function to handle key press events:
:long$ h18$
$| About lesson 18:
$|
$| Key-list for the available functions in this lesson:
$|
$| ESC      exits the lesson
$| w        toggles between fullscreen and windowed modes
$| f        cycle thru the different filters
$| l        toggles the light on/off
$| SPACE    cycles thru different objects
$| PageUp   zooms into the scene
$| PageDown zooms out of the scene
$| Up       makes x rotation more negative - incremental
$| Down     makes x rotation more positive - incremental
$| Left     makes y rotation more negative - incremental
$| Right    makes y rotation more positive - incremental
$| Home     resets the speed and depth
  ;long$

: HandleKeyPress ( &event -- )
  case
  \  SDLK_ESCAPE   of TRUE to opengl-exit-flag endof
    ascii W     of  start/end-fullscreen            	endof
    ascii F     of filter 1+ 3 MOD to filter 		endof
    ascii L     of
                       light if 0 else 1 then to light
                       light if   GL_LIGHTING gl-enable
                             else GL_LIGHTING gl-disable
                             then			endof
    BL    	of q-object 1+ 6 MOD to q-object	endof
    VK_PGUP     of zdepth F@ 0.02e F- zdepth F! 	endof
    VK_PGDN     of zdepth F@ 0.02e F+ zdepth F! 	endof
    VK_UP       of xspeed F@ 0.01e F- xspeed F!		endof
    VK_DOWN     of xspeed F@ 0.01e F+ xspeed F!		endof
    VK_RIGHT    of yspeed F@ 0.01e F+ yspeed F!		endof
    VK_LEFT     of yspeed F@ 0.01e F- yspeed F!		endof
    VK_HOME     of 0e yspeed F!    0e xspeed F!               \ Resets the speed and
                  -5e zdepth F! 			endof \ zdepth to the default value
                h18$ ShowHelp
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
    \ Create a pointer to the quadric object
    glu-new-quadric to quadratic
    \ Create smooth normals
    quadratic GLU_SMOOTH glu-quadric-normals
    \ Create texture coords
    quadratic GL_TRUE glu-quadric-texture
;

: DrawGLCube ( -- )
  \ Start drawing quads
  GL_QUADS gl-begin
    0e 0e 1e gl-normal-3f
    1e 0e gl-tex-coord-2f -1e -1e  1e gl-vertex-3f
    0e 0e gl-tex-coord-2f  1e -1e  1e gl-vertex-3f
    0e 1e gl-tex-coord-2f  1e  1e  1e gl-vertex-3f
    1e 1e gl-tex-coord-2f -1e  1e  1e gl-vertex-3f
    0e 0e -1e gl-normal-3f
    0e 0e gl-tex-coord-2f -1e -1e -1e gl-vertex-3f
    0e 1e gl-tex-coord-2f -1e  1e -1e gl-vertex-3f
    1e 1e gl-tex-coord-2f  1e  1e -1e gl-vertex-3f
    1e 0e gl-tex-coord-2f  1e -1e -1e gl-vertex-3f
    0e 1e 0e gl-normal-3f
    1e 1e gl-tex-coord-2f -1e  1e -1e gl-vertex-3f
    1e 0e gl-tex-coord-2f -1e  1e  1e gl-vertex-3f
    0e 0e gl-tex-coord-2f  1e  1e  1e gl-vertex-3f
    0e 1e gl-tex-coord-2f  1e  1e -1e gl-vertex-3f
    0e -1e 0e gl-normal-3f
    0e 1e gl-tex-coord-2f -1e -1e -1e gl-vertex-3f
    1e 1e gl-tex-coord-2f  1e -1e -1e gl-vertex-3f
    1e 0e gl-tex-coord-2f  1e -1e  1e gl-vertex-3f
    0e 0e gl-tex-coord-2f -1e -1e  1e gl-vertex-3f
    1e 0e 0e gl-normal-3f
    0e 0e gl-tex-coord-2f  1e -1e -1e gl-vertex-3f
    0e 1e gl-tex-coord-2f  1e  1e -1e gl-vertex-3f
    1e 1e gl-tex-coord-2f  1e  1e  1e gl-vertex-3f
    1e 0e gl-tex-coord-2f  1e -1e  1e gl-vertex-3f
    -1e 0e 0e gl-normal-3f
    1e 0e gl-tex-coord-2f -1e -1e -1e gl-vertex-3f
    0e 0e gl-tex-coord-2f -1e -1e  1e gl-vertex-3f
    0e 1e gl-tex-coord-2f -1e  1e  1e gl-vertex-3f
    1e 1e gl-tex-coord-2f -1e  1e -1e gl-vertex-3f
  gl-end
;


\ ---[ DrawGLScene ]-------------------------------------------------
\ Here goes our drawing code

: DrawGLScene ( -- boolean )
  \ Clear the screen and the depth buffer
  GL_COLOR_BUFFER_BIT GL_DEPTH_BUFFER_BIT OR gl-clear

  gl-load-identity

  \ Translate into/out of the screen by zdepth
  0e 0e zdepth F@ gl-translate-f
  \ Rotate on the x axis
  xrot F@ 1e 0e 0e gl-rotate-f
  \ Rotate on the y axis
  yrot F@ 0e 1e 0e gl-rotate-f
  \ Select a texture based on filter
  GL_TEXTURE_2D filter texture-ndx @ gl-bind-texture
  \ Determine which object to draw
  q-object case
    0 of DrawGLCube 				endof
    1 of 0e 0e -1.5e gl-translate-f
         quadratic 1e 1e 3e 32 32 glu-cylinder
						endof
    2 of quadratic 0.5e 1.5e 32 32 glu-disk 	endof
    3 of quadratic 1.3e 32 32 glu-sphere 	endof
    4 of 0e 0e -1.5e gl-translate-f
         quadratic 1e 0e 3e 32 32 glu-cylinder	endof
    5 of Part1 F@ p1 F@ F+ Part1 F!
         Part2 F@ p2 F@ F+ Part2 F!
         Part1 F@ 359e F> if
           0e p1 F!
           0e Part1 F!
           1e p2 F!
           0e Part2 F!
         then
         Part2 F@ 359e F> if
           1e p1 F!
           0e p2 F!
         then
         quadratic 0.5e 1.5e 32 32
         Part1 F@ Part2 F@ FOVER F- glu-partial-disk
						endof
  endcase

  \ Draw it to the screen -- if double buffering is permitted
  sdl-gl-swap-buffers

  xrot F@ xspeed F@ F+ xrot F!                       \ increment xrot
  yrot F@ yspeed F@ F+ yrot F!                       \ increment yrot

;

: ExitLesson18 ( -- )
  quadratic glu-delete-quadric              \ clean up our quadratics
  NumTextures texture[] gl-delete-textures        \ clean up textures
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


: DrawGLLesson18  ( -- )                          \ Handles ONE frame
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

 ' DrawGLLesson18 to LastLesson
[Forth]
\s
