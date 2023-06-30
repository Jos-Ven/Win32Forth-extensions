\ ===================================================================
\           File: opengllib-1.23.fs
\         Author: GB Schmick
\  Linux Version: Ti Leggett
\ gForth Version: Timothy Trussell, 08/07/2010
\    Description: Quadrics
\   Forth System: gforth-0.7.0
\   Linux System: Ubuntu v10.04 LTS i386, kernel 2.6.31-24
\   C++ Compiler: gcc (Ubuntu 4.4.1-4ubuntu9) 4.4.1
\ ===================================================================
\                       NeHe Productions
\                    http://nehe.gamedev.net/
\ ===================================================================
\                   OpenGL Tutorial Lesson 23
\ ===================================================================
\ This code was created by Jeff Molofee '99
\ (ported to Linux/SDL by Ti Leggett '01)
\ March, 2013 adapted for Win32Forth by Jos v.d.Ven
\ Visit Jeff at http://nehe.gamedev.net/
\ ===================================================================

vocabulary Lesson23  also Lesson23 definitions

\ ---[ Variable Declarations ]---------------------------------------


FALSE value light                         \ lighting is initially off

0 value filter                                  \ which filter to use

0 value quadratic                 \ storage for our quadratic objects
3 value q-object                               \ which object to draw

fvariable Part1                                       \ start of disc
fvariable Part2                                         \ end of disc
fvariable p1                                             \ increase 1
fvariable p2                                             \ increase 2
fvariable xrot                                           \ x rotation
fvariable yrot                                           \ y rotation
fvariable xspeed                                   \ x rotation speed
fvariable yspeed                                   \ y rotation speed
fvariable zdepth                                  \ depth into screen

\ ---[ Variable Initializations ]------------------------------------
\ 1e xspeed f!
\ 1e yspeed f!
0e p1 F!
1e p2 F!
-5e zdepth F!

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


\ ---[ Load-Image ]--------------------------------------------------
\ Attempt to load the texture images into SDL surfaces, saving the
\ result into the teximage[] array; Return TRUE if result from
\ sdl-loadbmp is <> 0; else return FALSE

: Make-Lin-Texture-and-MipMap { i *src -- }
      \ Create Linear Filtered Texture
      i 2 + BindTexture-ndx
      LinearFiltering
      *src Generate-Texture

      \ Create Create MipMapped Texture
      i 4 + BindTexture-ndx
      MipMappedFiltering
      *src Generate-MipMapped-Texture
 ;

\ ---[ LoadGLTextures ]----------------------------------------------
\ function to load in bitmap as a GL texture

: LoadGLTextures ( -- )
\ create local variable for storing return flag
  6 MallocTextures      \ MallocTextures allocates only when not done
  NumTextures texture[] gl-gen-textures         \ create the textures
\  6 texture gl-gen-textures                    \ create the textures

  s" bg.bmp"      0 dup>r ahndl _LoadGLTexture
                  r> ahndl >hfileAddress @  \ get the BitmapFileHeader
                     Make-Lin-Texture-and-MipMap  un-map-bitmap

  s" reflect.bmp" 1 dup>r ahndl _LoadGLTexture
                  r> ahndl >hfileAddress @
                     Make-Lin-Texture-and-MipMap  un-map-bitmap
;

\ ---[ HandleKeyPress ]----------------------------------------------
\ function to handle key press events:
:long$ h23$
$| About lesson 23:
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
  ;long$

: HandleKeyPress ( &event -- )
  case
\    SDLK_ESCAPE   of TRUE to opengl-exit-flag endof
    ascii W     of  start/end-fullscreen 		endof
    ascii F     of  filter 1+ 3 MOD to filter		endof
    ascii L     of  light if 0 else 1 then to light
                       light if   GL_LIGHTING gl-enable
                             else GL_LIGHTING gl-disable
                             then			endof
    BL          of q-object 1+ 4 MOD to q-object	endof
    VK_PGUP     of zdepth F@ 0.2e F- zdepth F! 	endof
    VK_PGDN     of zdepth F@ 0.2e F+ zdepth F! 	endof
    VK_UP       of xspeed F@ 0.1e F- xspeed F! 	endof
    VK_DOWN     of xspeed F@ 0.1e F+ xspeed F! 	endof
    VK_RIGHT    of yspeed F@ 0.1e F+ yspeed F! 	endof
    VK_LEFT     of yspeed F@ 0.1e F- yspeed F! 	endof
                h23$ ShowHelp
  endcase
;

\ ---[ Set the viewpoint ]-------------------------------------------

: set-viewpoint
  GL_PROJECTION gl-matrix-mode
  \ Reset the matrix
  gl-load-identity
  \ Set our perspective - the F/ calcs the aspect ratio of w/h
  45e widthViewport S>F heightViewport S>F F/ 0.1e 100e glu-perspective
  \ Make sure we are changing the model view and not the projection
  GL_MODELVIEW gl-matrix-mode
  \ Reset the matrix
  gl-load-identity
;

\ ---[ InitGL ]------------------------------------------------------
\ general OpenGL initialization function

: InitGL ( -- boolean )
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
    \ Set the texture generation mode for S to sphere mapping
    GL_S GL_TEXTURE_GEN_MODE GL_SPHERE_MAP gl-tex-gen-i
    \ Set the texture teneration mode for t to sphere mapping
    GL_T  GL_TEXTURE_GEN_MODE  GL_SPHERE_MAP gl-tex-gen-i
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
    0e 0e 0.5e gl-normal-3f                              \ Front Face
    0e 0e gl-tex-coord-2f -1e -1e  1e gl-vertex-3f
    1e 0e gl-tex-coord-2f  1e -1e  1e gl-vertex-3f
    1e 1e gl-tex-coord-2f  1e  1e  1e gl-vertex-3f
    0e 1e gl-tex-coord-2f -1e  1e  1e gl-vertex-3f

    0e 0e -0.5e gl-normal-3f                              \ Back Face
    1e 0e gl-tex-coord-2f -1e -1e -1e gl-vertex-3f
    1e 1e gl-tex-coord-2f -1e  1e -1e gl-vertex-3f
    0e 1e gl-tex-coord-2f  1e  1e -1e gl-vertex-3f
    0e 0e gl-tex-coord-2f  1e -1e -1e gl-vertex-3f

    0e 0.5e 0e gl-normal-3f                                  \ Top Face
    0e 1e gl-tex-coord-2f -1e  1e -1e gl-vertex-3f
    0e 0e gl-tex-coord-2f -1e  1e  1e gl-vertex-3f
    1e 0e gl-tex-coord-2f  1e  1e  1e gl-vertex-3f
    1e 1e gl-tex-coord-2f  1e  1e -1e gl-vertex-3f

    0e -0.5e 0e gl-normal-3f                            \ Bottom Face
    1e 1e gl-tex-coord-2f -1e -1e -1e gl-vertex-3f
    0e 1e gl-tex-coord-2f  1e -1e -1e gl-vertex-3f
    0e 0e gl-tex-coord-2f  1e -1e  1e gl-vertex-3f
    1e 0e gl-tex-coord-2f -1e -1e  1e gl-vertex-3f

    0.5e 0e 0e gl-normal-3f                              \ Right Face
    1e 0e gl-tex-coord-2f  1e -1e -1e gl-vertex-3f
    1e 1e gl-tex-coord-2f  1e  1e -1e gl-vertex-3f
    0e 1e gl-tex-coord-2f  1e  1e  1e gl-vertex-3f
    0e 0e gl-tex-coord-2f  1e -1e  1e gl-vertex-3f

    -0.5e 0e 0e gl-normal-3f                              \ Left Face
    0e 0e gl-tex-coord-2f -1e -1e -1e gl-vertex-3f
    1e 0e gl-tex-coord-2f -1e -1e  1e gl-vertex-3f
    1e 1e gl-tex-coord-2f -1e  1e  1e gl-vertex-3f
    0e 1e gl-tex-coord-2f -1e  1e -1e gl-vertex-3f
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

  \ Enable texture coord generation for S
  GL_TEXTURE_GEN_S gl-enable
  \ Enable texture coord generation for T
  GL_TEXTURE_GEN_T gl-enable

  \ Select a texture based on filter
  GL_TEXTURE_2D filter 2 * 1 + texture-ndx @ gl-bind-texture

  gl-push-matrix

  \ Rotate on the x axis
  xrot F@ 1e 0e 0e gl-rotate-f
  \ Rotate on the y axis
  yrot F@ 0e 1e 0e gl-rotate-f
  \ Determine which object to draw

  q-object case
    0 of DrawGLCube endof                                      \ Cube
    1 of 0e 0e -1.5e gl-translate-f                        \ Cylinder
         quadratic 1e 1e 3e 32 32 glu-cylinder
      endof
    2 of quadratic 1.3e 32 32 glu-sphere endof               \ Sphere
    3 of 0e 0e -1.5e gl-translate-f                            \ Cone
         quadratic 1e 0e 3e 32 32 glu-cylinder
      endof
  endcase

  gl-pop-matrix

  \ Disable texture coord generation for S
  GL_TEXTURE_GEN_S gl-disable
  \ Disable texture coord generation for T
  GL_TEXTURE_GEN_T gl-disable

  \ This will select the BG texture
  GL_TEXTURE_2D filter 2 * texture-ndx @ gl-bind-texture
  gl-push-matrix
    0e 0e -29e gl-translate-f
    GL_QUADS gl-begin
      0e 0e 1e gl-normal-3f
      0e 0e gl-tex-coord-2f -13.3e -10e 10e gl-vertex-3f
      1e 0e gl-tex-coord-2f  13.3e -10e 10e gl-vertex-3f
      1e 1e gl-tex-coord-2f  13.3e  10e 10e gl-vertex-3f
      0e 1e gl-tex-coord-2f -13.3e  10e 10e gl-vertex-3f
    gl-end
  gl-pop-matrix

  \ Draw it to the screen -- if double buffering is permitted
  sdl-gl-swap-buffers

  xrot F@ xspeed F@ F+ xrot F!                       \ increment xrot
  yrot F@ yspeed F@ F+ yrot F!                       \ increment yrot
;

: _exitLesson  ( -- )          \ For a clean start in the next lesson
  quadratic glu-delete-quadric             \ clean up our quadratics
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


: DrawGLLesson23  ( -- )                          \ Handles ONE frame
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

 ' DrawGLLesson23 to LastLesson
[Forth]
\s

