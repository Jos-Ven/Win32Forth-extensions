\ ===================================================================
\           File: opengllib-1.17.fs
\         Author: Giuseppe D'Agata
\  Linux Version: Ti Leggett
\ gForth Version: Timothy Trussell, 07/31/2010
\    Description: 2D texture mapped fonts
\   Forth System: gforth-0.7.0
\   Linux System: Ubuntu v10.04 LTS i386, kernel 2.6.31-24
\   C++ Compiler: gcc (Ubuntu 4.4.1-4ubuntu9) 4.4.1
\ ===================================================================
\                       NeHe Productions
\                    http://nehe.gamedev.net/
\ ===================================================================
\                   OpenGL Tutorial Lesson 17
\ ===================================================================
\ This code was created by Giuseppe D'Agata
\ (ported to Linux/SDL by Ti Leggett '01)
\ March, 2013 adapted for Win32Forth by Jos v.d.Ven
\ Visit Jeff at http://nehe.gamedev.net/
\ ===================================================================

vocabulary Lesson17  also Lesson17 definitions

\ ---[ Variable Declarations ]---------------------------------------

variable baselist                \ base display list for the font set
fvariable count1       \ 1st counter used to move text and for coloring
fvariable count2       \ 2nd counter used to move text and for coloring

\ ---[ Variable Initializations ]------------------------------------

0 baselist !
0e count1 F!
0e count2 F!

\ ---[ KillFont ]----------------------------------------------------
\ Recover memory from our list of characters by deleting all 256 of
\ the display lists we created.

: KillFont ( -- )
  baselist @ 256 gl-delete-lists
;

\ ---[ LoadGLTextures ]----------------------------------------------
\ Function to load in bitmaps as a GL textures

: LoadGLTextures ( -- )
  \ create variables for storing surface pointers and return flag
  2 MallocTextures      \ MallocTextures allocates only when not done
  NumTextures texture[] gl-gen-textures         \ create the textures
  \ Attempt to load the texture images by using a mapping
  s" font.bmp"  0 ahndl LoadGLTexture                       \ ndx = 0
  s" bumps.bmp" 1 ahndl LoadGLTexture                       \ ndx = 1
;

\ ---[ BuildFont ]---------------------------------------------------
\ Function to build our OpenGL font list

\ ---[Note]----------------------------------------------------------
\ BMPs are stored with the top-leftmost pixel being the last byte and
\ the bottom-rightmost pixel being the first byte. So an image that
\ is displayed as
\
\               1 0
\               0 0
\
\ is represented data-wise like
\
\               0 0
\               0 1
\
\ And, because SDL_LoadBMP loads the raw data without translating to
\ how it is thought of when viewed, we need to start at the bottom
\ right corner of the data and work backwards to get everything
\ properly. So the below code has been modified to reflect this.
\ Examine how this is done and how the original tutorial is done to
\ grasp the differences.
\
\ As a side note BMPs are also stored as BGR instead of RGB and that
\ is why we load the texture using GL_BGR.
\
\ It's bass-ackwards I know but whattaya gonna do? -- Ti Leggett
\ Note: Adapted for Win32Forth which does not load bass-ackwards -- Jos vd Ven
\ ------------------------------------------------------[End Note]---

fvariable bf-cx                         \ holds our x character coord
fvariable bf-cy                         \ holds our y character coord

: BuildFont ( -- )
  \ Create 256 display lists
  256 gl-gen-lists baselist !
  \ Select our font texture
  GL_TEXTURE_2D 0 texture-ndx @ gl-bind-texture
  \ Loop thru all 256 lists
  256 0 do
    \ X Position of current character
     i 16 MOD S>F 16e F/  bf-cx F!               \ Moves to the right
    \ Y Position of current character
     i 16 /  S>F   16e F/      bf-cy F!                 \ Moves down
    \ Start building a list
     baselist @ i + GL_COMPILE gl-new-list
      GL_QUADS gl-begin               \ use a quad for each character
        \ texture coordinate - bottom left
        bf-cx F@   1e bf-cy F@ F- 0.0625e F- gl-tex-coord-2f
        \ vertex coordinate - bottom left
        0 0 gl-vertex-2i
        \ texture coordinate - bottom right
        bf-cx F@ 0.0625e F+   1e bf-cy F@ F- 0.0625e F- gl-tex-coord-2f
        \ vertex coordinate - bottom right
        16 0 gl-vertex-2i
        \ texture coordinate - top right
        bf-cx F@  0.0625e F+   1e bf-cy F@  F- gl-tex-coord-2f
        \ vertex coordinate - top right
        16 16 gl-vertex-2i
        \ texture coordinate - top left
        bf-cx F@  1e bf-cy F@  F- gl-tex-coord-2f
        \ vertex coordinate - top left
        0 16 gl-vertex-2i
      gl-end
      \ Move to the right of the character
      10e 0e 0e gl-translate-d
    gl-end-list
  loop
;


\ ---[ glPrint ]-----------------------------------------------------
\ Prints a string
\ The <set> parameter is 0 for Normal, or 1 for Italic

: glPrint { _x _y *str _len _set -- }
  _set 1 > if 1 to _set then
  GL_TEXTURE_2D 0 texture-ndx @ gl-bind-texture  \ Select our texture
  GL_DEPTH_TEST gl-disable                    \ Disable depth testing
  GL_PROJECTION gl-matrix-mode         \ Select the projection matrix
  gl-push-matrix                        \ Store the projection matrix
  gl-load-identity                      \ Reset the projection matrix
  0e 640e 0e 480e -1e 1e gl-ortho            \ Set up an ortho screen
  GL_MODELVIEW gl-matrix-mode           \ Select the modelview matrix
  gl-push-matrix                         \ Store the modelview matrix
  gl-load-identity                       \ Reset the modelview matrix
  _x S>F _y S>F 0e gl-translate-d  \ Position text (0,0==bottom left)
  baselist @ 32 - 128 _set * + gl-list-base     \ Choose the font set
  _len GL_BYTE *str gl-call-lists                    \ Write the text
  GL_PROJECTION gl-matrix-mode         \ Select the projection matrix
  gl-pop-matrix                   \ Restore the old projection matrix
  GL_MODELVIEW gl-matrix-mode           \ Select the modelview matrix
  gl-pop-matrix                   \ Restore the old projection matrix
  GL_DEPTH_TEST gl-enable                   \ Re-enable depth testing
;

\ ---[ HandleKeyPress ]----------------------------------------------
\ function to handle key press events:
:long$ h17$
$| About lesson 17:
$|
$| Key-list for the available functions in this lesson:
$|
$| ESC      exits the lesson
$| w        toggles between fullscreen and windowed modes
  ;long$

\ ---[ HandleKeyPress ]----------------------------------------------
\ function to handle key press events

: HandleKeyPress ( &event -- )          \ Escape is handled in OpenGL.f
    ascii W =
      if     start/end-fullscreen       \ Starts of end the full screen
      else   h17$ ShowHelp         \ Show the help text for this lesson
      then
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
    \ Build our font lists
    BuildFont
    \ Enable smooth shading
    GL_SMOOTH gl-shade-model
    \ Set the background black
    0e 0e 0e 0e gl-clear-color
    \ Depth buffer setup
    1e gl-clear-depth
    \ Type of depth test to do
    GL_LEQUAL gl-depth-func
    \ Select the type of blending
    GL_SRC_ALPHA GL_ONE gl-blend-func
    \ Enable texture mapping
    GL_TEXTURE_2D gl-enable
;

\ ---[ DrawGLScene ]-------------------------------------------------
\ Here goes our drawing code

: DrawGLScene ( -- boolean )
  \ Clear the screen and the depth buffer
  GL_COLOR_BUFFER_BIT GL_DEPTH_BUFFER_BIT OR gl-clear

  gl-load-identity

  \ Select our second texture
  GL_TEXTURE_2D 1 texture-ndx @ gl-bind-texture
  \ Move into the screen 5 units
  0e 0e -5e gl-translate-f
  \ Rotate on the Z axis 45 degrees - clockwise
  45e 0e 0e 1e gl-rotate-f
  \ Rotate on the x & y axes by count1 - left to right
  count1 F@ 30e F* 1e 1e 0e gl-rotate-f
  \ Disable blending before we draw in 3D
  GL_BLEND gl-disable

  1e 1e 1e gl-color-3f                                 \ bright white
  GL_QUADS gl-begin                \ draw the 1st texture mapped quad
    0e 0e gl-tex-coord-2f -1e  1e gl-vertex-2f   \ 1st texture/vertex
    1e 0e gl-tex-coord-2f  1e  1e gl-vertex-2f   \ 2nd texture/vertex
    1e 1e gl-tex-coord-2f  1e -1e gl-vertex-2f   \ 3rd texture/vertex
    0e 1e gl-tex-coord-2f -1e -1e gl-vertex-2f   \ 4th texture/vertex
  gl-end
  \ Rotate on the x & y axes by 90 degrees - left to right
  -90e 1e 1e 0e gl-rotate-f
  GL_QUADS gl-begin                \ draw the 2nd texture mapped quad
    0e 0e gl-tex-coord-2f -1e  1e gl-vertex-2f   \ 1st texture/vertex
    1e 0e gl-tex-coord-2f  1e  1e gl-vertex-2f   \ 2nd texture/vertex
    1e 1e gl-tex-coord-2f  1e -1e gl-vertex-2f   \ 3rd texture/vertex
    0e 1e gl-tex-coord-2f -1e -1e gl-vertex-2f   \ 4th texture/vertex
  gl-end
  \ Re-enable blending
  GL_BLEND gl-enable
  \ Reset the view
  gl-load-identity
  \ Pulsing colors based on text position
  \ Print the GL text to the screen

  \ Set color for first text string
  1e count1 F@ FCOS F*
  1e count2 F@ FSIN F*
  1e 0.5e count1 F@ count2 F@ F+ FCOS F* F- gl-color-3f
  \ Print the first text string
  280e 250e count1 F@ FCOS F* F+ F>S
  235e 200e count2 F@ FSIN F* F+ F>S
  s" NeHe"

  0
  glPrint

  \ Set color for second text string
  1e count2 F@ FSIN F*
  1e 0.5e count1 F@ count2 F@ F+ FCOS F* F-
  1e count1 F@ FCOS F* gl-color-3f
  \ Print the second text string
  280e 230e count2 F@ FCOS F* F+ F>S
  235e 200e count1 F@ FSIN F* F+ F>S
  s" OpenGL"
  1
  glPrint

  \ Set color to red
  0e 0e 1e gl-color-3f
  \ Print the third string
  240e 200e count2 F@ count1 F@ F+ FCOS F* 5e F/ F+ F>S
  2
  s" Giuseppe D'Agata"
  0
  glPrint

  \ Set color to white
  1e 1e 1e gl-color-3f
  \ Print offset text to the screen
  242e 200e count2 F@ count1 F@ F+ FCOS F* 5e F/ F+ F>S
  2
  s" Giuseppe D'Agata"
  0
  glPrint

  \ Draw it to the screen -- if double buffering is permitted
  sdl-gl-swap-buffers

  count1 F@ 0.01e F+ count1 F!              \ increment first counter
  count2 F@ 0.0081e F+ count2 F!           \ increment second counter
;

: ExitLesson17 ( -- )
  KillFont                                       \ clean up font list
  DeleteTextures                                  \ clean up textures
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


: DrawGLLesson17  ( -- )                          \ Handles ONE frame
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

 ' DrawGLLesson17 to LastLesson
[Forth]
\s

