\ ===================================================================
\           File: opengllib-1.26.fs
\         Author: Banu Cosmin
\  Linux Version: Gray Fox
\ gForth Version: Timothy Trussell, 05/27/2011
\    Description: Clipping & Reflections Using The Stencil Buffer
\   Forth System: gforth-0.7.0
\   Linux System: Ubuntu v10.04 LTS i386, kernel 2.6.32-31
\   C++ Compiler: gcc (Ubuntu 4.4.1-4ubuntu9) 4.4.1
\ ===================================================================
\                       NeHe Productions
\                    http://nehe.gamedev.net/
\ ===================================================================
\                   OpenGL Tutorial Lesson 26
\ ===================================================================
\ This code was created by Jeff Molofee 2000
\ March, 2013 adapted for Win32Forth by Jos v.d.Ven
\ Visit Jeff at http://nehe.gamedev.net/
\ ===================================================================

vocabulary Lesson26  also Lesson26 definitions

\ ---[ Variable Declarations ]---------------------------------------

0 VALUE quadratic                    \ Quadratic For Drawing A Sphere

FVARIABLE xrot                                           \ x rotation
FVARIABLE yrot                                           \ y rotation
FVARIABLE xspeed                                   \ x rotation speed
FVARIABLE yspeed                                   \ y rotation speed
FVARIABLE zoom                                \ depth into the screen
FVARIABLE ballheight                      \ height of ball from floor


\ Light Parameters - passed by address so they have to be 32-bit

create LightAmb[] 0.7e SF, 0.7e SF, 0.7e SF, 1.0e SF,       \ Ambient
create LightDif[] 1.0e SF, 1.0e SF, 1.0e SF, 1.0e SF,       \ Diffuse
create LightPos[] 4.0e SF, 4.0e SF, 6.0e SF, 1.0e SF,      \ Position

\ ---[ Variable Initializations ]------------------------------------

0e0 xrot F!
0e0 yrot F!
1e0 xspeed F!
1e0 yspeed F!
-7.0e zoom F!
0.35e ballheight F!

\ ===[ The code ]====================================================

\ ---[ LoadGLTextures ]----------------------------------------------
\ function to load in bitmap as a GL texture


: LoadGLTextures ( -- status )
  \ create variables for storing surface pointers and return flag
  3 MallocTextures      \ MallocTextures allocates only when not done
\  Texture NumTextures erase                             \ Erase then
  NumTextures texture[] gl-gen-textures         \ create the textures
  \ Attempt to load the texture images by using a mapping
  s" Envwall.bmp" 0 ahndl LoadGLTexture
  s" Ball.bmp"    1 ahndl LoadGLTexture
  s" Envroll.bmp" 2 ahndl LoadGLTexture
  true                         \ exit -1=ok OR abort in LoadGLTexture
;

\ ---[ HandleKeyPress ]----------------------------------------------
\ function to handle key press events:
:long$ h26$
$| About lesson 26:
$|
$| Key-list for the available functions in this lesson:
$|
$| ESC      exits the lesson
$| w        toggles between fullscreen and windowed modes
$| PgUp     increase ball height
$| PgDn     decrease ball height
$| Up       increase x-speed
$| Down     decrease x-speed
$| Left     decrease y-speed
$| Right    increase y-speed
$| a        move object towards viewer
$| x        move object away from viewer
$| Home     Resets the speed zoom and ballheight
$|
$| Tip: Too slow?
$|      Choose in the menu Options for Maximum frames/second
$|      and enter a zero for overspeed.
;long$

: HandleKeyPress ( &event -- )
  case
   \ SDLK_ESCAPE of TRUE to opengl-exit-flag endof
    ascii W     of  start/end-fullscreen endof
    VK_DOWN     of 0.08e0 xspeed F+! 	 endof              \ +xspeed
    VK_UP       of 0.08e0 xspeed F-! 	 endof              \ -xspeed
    VK_LEFT     of 0.08e0 yspeed F-! 	 endof              \ -yspeed
    VK_RIGHT    of 0.08e0 yspeed F+!	 endof              \ +yspeed
    VK_PGUP     of 0.03e0 ballheight F+! endof              \ ball up
    VK_PGDN     of 0.03e0 ballheight F-! endof              \ ball down
    ascii A     of 0.05e0 zoom F+! 	 endof              \ zoom in
    ascii X     of 0.05e0 zoom F-!  	 endof              \ zoom out
    VK_HOME 	of 1e yspeed F! 1e xspeed F!                \ Resets the speed, zoom and
                   -7.0e zoom F!  0.35e ballheight F! endof \ ballheight to the default value
                h26$ ShowHelp
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
    GL_SMOOTH gl-shade-model            \ Enable smooth color shading
    0.2e 0.5e 1.0e 1.0e gl-clear-color     \ Set the background color
    1.0e gl-clear-depth        \ Enables clearing of the depth buffer
    0 gl-clear-stencil                \ clear the stencil buffer to 0
    GL_DEPTH_TEST gl-enable                   \ Enables depth testing
    GL_LEQUAL gl-depth-func                \ Type of depth test to do
    GL_PERSPECTIVE_CORRECTION_HINT GL_NICEST gl-hint    \ Perspective
    GL_TEXTURE_2D gl-enable               \ enable 2D texture mapping

    GL_LIGHT0 GL_AMBIENT LightAmb[] gl-light-fv   \ Set ambient light
    GL_LIGHT0 GL_DIFFUSE LightDif[] gl-light-fv   \ Set diffuse light
    GL_LIGHT0 GL_POSITION LightPos[] gl-light-fv \ Position the light
    GL_LIGHT0 gl-enable                           \ Enable Light Zero
    GL_LIGHTING gl-enable                           \ Enable Lighting

    glu-new-quadric to quadratic             \ Create a new quadratic
    quadratic GL_SMOOTH glu-quadric-normals \ generate smooth normals
    quadratic GL_TRUE glu-quadric-texture     \ enable texture coords

    GL_S GL_TEXTURE_GEN_MODE GL_SPHERE_MAP gl-tex-gen-i      \ set up
    GL_T GL_TEXTURE_GEN_MODE GL_SPHERE_MAP gl-tex-gen-i  \ sphere map
;


\ ---[ DrawGLScene ]-------------------------------------------------

: DrawObject ( -- )
  1.0e 1.0e 1.0e gl-color-3f                     \ set color to white
  GL_TEXTURE_2D  1 texture-ndx @ gl-bind-texture
  quadratic 0.35e 32 16 glu-sphere                \ draw first sphere

  GL_TEXTURE_2D 2 texture-ndx @ gl-bind-texture
  1.0e 1.0e 1.0e 0.4e gl-color-4f     \ color is white with 40% alpha
  GL_BLEND gl-enable                                \ enable blending
  GL_SRC_ALPHA GL_ONE gl-blend-func               \ set blending mode
  GL_TEXTURE_GEN_S gl-enable                  \ enable sphere mapping
  GL_TEXTURE_GEN_T gl-enable                  \ enable sphere mapping

  quadratic 0.35e 32 16 glu-sphere              \ draw another sphere

  GL_TEXTURE_GEN_S gl-disable                \ disable sphere mapping
  GL_TEXTURE_GEN_T gl-disable                \ disable sphere mapping
  GL_BLEND gl-disable                              \ disable blending
;

: DrawFloor ( -- )
  GL_TEXTURE_2D 0 texture-ndx @ gl-bind-texture
  GL_QUADS gl-begin                            \ begin drawing a quad
    0.0e 1.0e 0.0e gl-normal-3f                  \ normal pointing up
    0.0e 1.0e gl-tex-coord-2f                \ bottom left of texture
    -2.0e 0.0e 2.0e gl-vertex-3f        \ bottom left corner of floor

    0.0e 0.0e gl-tex-coord-2f                   \ top left of texture
    -2.0e 0.0e -2.0e gl-vertex-3f          \ top left corner of floor

    1.0e 0.0e gl-tex-coord-2f                  \ top right of texture
    2.0e 0.0e -2.0e gl-vertex-3f          \ top right corner of floor

    1.0e 1.0e gl-tex-coord-2f               \ bottom right of texture
    2.0e 0.0e 2.0e gl-vertex-3f        \ bottom right corner of floor
  gl-end                                      \ done drawing the quad
;

\ Plane Equation for the reflected objects - C DOUBLEs specifically
create EQR[] 0.0e F, -1.0e F, 0.0e F, 0.0e F,

: DrawGLScene  ( -- boolean )
  GL_COLOR_BUFFER_BIT
  GL_DEPTH_BUFFER_BIT OR
  GL_STENCIL_BUFFER_BIT OR gl-clear                    \ Clear screen

  gl-load-identity                                 \ Reset the matrix
  0.0e -0.6e zoom F@ gl-translate-f   \ zoom/raise camera above floor
  0 0 0 0 gl-color-mask                              \ set color mask
  GL_STENCIL_TEST gl-enable                   \ enable stencil buffer
  GL_ALWAYS 1 1 gl-stencil-func
  GL_KEEP GL_KEEP GL_REPLACE gl-stencil-op
  GL_DEPTH_TEST gl-disable                    \ disable depth testing
  DrawFloor                 \ draws the floor (to the stencil buffer)
  GL_DEPTH_TEST gl-enable                      \ enable depth testing
  1 1 1 1 gl-color-mask                     \ set color mask to trues
  GL_EQUAL 1 1 gl-stencil-func
  GL_KEEP GL_KEEP GL_KEEP gl-stencil-op \ no change to stencil buffer
  GL_CLIP_PLANE0 gl-enable    \ enable clip plane to remove artifacts
  GL_CLIP_PLANE0 EQR[] gl-clip-plane \ equation for reflected obejcts
  gl-push-matrix                      \ push the current matrix stack
    1.0e -1.0e 1.0e gl-scale-f                        \ mirror Y axis
    GL_LIGHT0 GL_POSITION LightPos[] gl-light-fv         \ set light0
    0.0e ballheight F@ 0.0e gl-translate-f      \ position the object
    xrot F@ 1.0e 0.0e 0.0e gl-rotate-f             \ rotate on x axis
    yrot F@ 0.0e 1.0e 0.0e gl-rotate-f             \ rotate on y axis
    DrawObject                         \ draw the sphere (reflection)
  gl-pop-matrix                         \ restore the previous matrix
  GL_CLIP_PLANE0 gl-disable        \ disable clip plane for the floor
  GL_STENCIL_TEST gl-disable             \ disable the stencil buffer
  GL_LIGHT0 GL_POSITION LightPos[] gl-light-fv           \ set Light0
  GL_BLEND gl-enable      \ enable blending so reflected object shows
  GL_LIGHTING gl-disable                    \ because we are blending
  1.0e 1.0e 1.0e 0.8e gl-color-4f \ set color to white with 80% alpha
  GL_SRC_ALPHA GL_ONE_MINUS_SRC_ALPHA gl-blend-func
  DrawFloor                                           \ to the screen
  GL_LIGHTING gl-enable                             \ enable lighting
  GL_BLEND gl-disable                \ position ball at proper height
  0.0e ballheight F@ 0.0e gl-translate-f        \ position the object
  xrot F@ 1.0e 0.0e 0.0e gl-rotate-f               \ rotate on x axis
  yrot F@ 0.0e 1.0e 0.0e gl-rotate-f               \ rotate on y axis
  DrawObject                           \ draw the sphere (reflection)
  xspeed F@ xrot F+!                        \ update x rotation angle
  yspeed F@ yrot F+!                        \ update y rotation angle
  gl-flush                                    \ flush the GL pipeline

  \ Draw it to the screen -- if double buffering is permitted
  \ The Lesson code actually calls glutSwapBuffers which I do not
  \ have coded in my system - as yet...

  sdl-gl-swap-buffers
;

: _exitLesson  ( -- )          \ For a clean start in the next lesson
  quadratic glu-delete-quadric              \ clean up our quadratics
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


: DrawGLLesson26  ( -- )                          \ Handles ONE frame
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


 ' DrawGLLesson26 to LastLesson
[Forth]
\s

