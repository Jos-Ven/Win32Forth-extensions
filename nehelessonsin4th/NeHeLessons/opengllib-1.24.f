\ ===================================================================
\           File: opengllib-1.24.fs
\         Author: Jeff Molofee
\  Linux Version: DarkAlloy
\ gForth Version: Timothy Trussell, 05/01/2011
\    Description: Tokens, extensions, scissor testing, TGA
\   Forth System: gforth-0.7.0
\   Linux System: Ubuntu v10.04 LTS i386, kernel 2.6.32-31
\   C++ Compiler: gcc version 4.4.3 (Ubuntu 4.4.3-4ubuntu5)
\ ===================================================================
\                       NeHe Productions
\                    http://nehe.gamedev.net/
\ ===================================================================
\                   OpenGL Tutorial Lesson 21
\ ===================================================================
\ This code was created by Jeff Molofee '99
\ (ported to Linux/SDL by Dark Alloy)
\ March, 2013 adapted for Win32Forth by Jos v.d.Ven
\ Visit Jeff at http://nehe.gamedev.net/
\ ===================================================================

vocabulary Lesson24  also Lesson24 definitions

\ ---[ Variable Declarations ]---------------------------------------

0 VALUE scroll                        \ Used For Scrolling The Screen
0 VALUE maxtokens                    \ Number Of Extensions Supported
0 VALUE swidth                                        \ Scissor Width
0 VALUE sheight                                      \ Scissor Height
0 VALUE scroller               \ Used to control the Scrolling action

0 VALUE ExtensionsLoaded                        \ only load them once
0 VALUE *Extensions           \ where we loaded the extensions string

variable baselist                \ base display list for the font set
0 baselist !

\ ---[ s-itos ]------------------------------------------------------
\ Converts an integer to a string

: s-itos   ( n -- str len ) 0 <# #S #> ;

\ ---[ s-zlen ]------------------------------------------------------
\ Returns the length of a NULL terminated string

: s-zlen { *str -- len }
  0 begin *str over + C@ 0= if 1 else 1+ 0 then until
;

\ ---[ s-token ]-----------------------------------------------------
\ Returns the *str/len pair from the current address to the next
\ address of the specified token character - or end of list (NULL)
\ After each pass, the (token) pointer is set to the last occurrence
\ of the token found.

0 VALUE (token)                            \ addr of last token found

: s-token { *src _c -- *str len }
  *src 0= if (token) 1+ to *src then   \ if NULL passed use last addr
  0                               \ initial count value for this pass
  begin *src over + C@ dup _c = swap 0= OR if 1 else 1+ 0 then until
  *src over + to (token)                          \ set for next time
  *src swap
;


\ ---[ LoadGLTextures ]----------------------------------------------
\ Loads the image file(s) and generates OpenGL textures from them

: LoadGLTextures ( -- status )
  \ create variables for storing surface pointers and return flag
  1 MallocTextures      \ MallocTextures allocates only when not done
  NumTextures texture[] gl-gen-textures         \ create the textures
  \ Attempt to load the texture images by using a mapping
  s" font.bmp"  0 ahndl LoadGLTexture                       \ ndx = 0
 ;


\ ---[ BuildFont ]---------------------------------------------------
\ Function to build our OpenGL font display list

fvariable bf-cx                         \ holds our x character coord
fvariable bf-cy                         \ holds our y character coord

: BuildFont ( -- )
  \ Create 256 display lists
  256 gl-gen-lists baselist !
  \ Select our font texture
  GL_TEXTURE_2D 0 texture-ndx @ gl-bind-texture
  \ Loop thru all 256 lists
  256 0 do
    \ X Position of current character with a 0.01e correction
     i 16 MOD S>F 16e F/  0.01e F+ bf-cx F!     \ Moves to the right
    \ Y Position of current character
     i 16 /  S>F   16e F/      bf-cy F!                 \ Moves down
    \ Start building a list
     baselist @ i + GL_COMPILE gl-new-list
      GL_QUADS gl-begin               \ use a quad for each character
        \ texture coordinate - bottom left
        bf-cx F@   1e bf-cy F@ F- 0.0625e F- gl-tex-coord-2f
        \ vertex coordinate - bottom left
        0 16 gl-vertex-2i
        \ texture coordinate - bottom right
        bf-cx F@ 0.0625e F+   1e bf-cy F@ F- 0.0625e F- gl-tex-coord-2f
        \ vertex coordinate - bottom right
        16 16 gl-vertex-2i
        \ texture coordinate - top right
        bf-cx F@  0.0625e F+   1e bf-cy F@  F-  gl-tex-coord-2f
        \ vertex coordinate - top right
        16 0 gl-vertex-2i
        \ texture coordinate - top left
        bf-cx F@  1e bf-cy F@  F-  gl-tex-coord-2f  \ cx,1.0f-cy-0.001f
        \ vertex coordinate - top left
        0 0 gl-vertex-2i
      gl-end
      \ Move to the right of the character
      10e 0e 0e gl-translate-d
    gl-end-list
  loop
;


\ ---[ glPrint ]-----------------------------------------------------
\ Prints a string
\ <set> selects Normal <0>, or Italic <1> from the font.bmp image.

: glPrint { _x _y *str _len _set -- }
  _set 1 > if 1 to _set then
  GL_TEXTURE_2D gl-enable                    \ Enable texture mapping
  GL_TEXTURE_2D 0 texture-ndx @ gl-bind-texture  \ Select our texture
  gl-load-identity                       \ Reset the modelview matrix
  _x S>F _y S>F 0e0 gl-translate-d \ Position text (0,0==bottom left)
  baselist @ 32 - 128 _set * + gl-list-base     \ Choose the font set
  1e0 2e0 1e0 gl-scale-f             \ scale width and height of font
  _len GL_UNSIGNED_BYTE *str gl-call-lists           \ Write the text
  GL_TEXTURE_2D gl-disable                  \ Disable texture mapping
;

5 constant maxlines

: handle-scroller
    scroller case
      -1 of scroll 0> if
              scroll 2 - to scroll
            then
         endof
       1 of scroll 32 maxtokens 9 - * < if
              scroll 2 + to scroll
            then
         endof
    endcase

    scroller -1 = if
      scroll 0> if
        scroll 2 - to scroll
      then
    then

    scroller 1 = if
      scroll 32 maxtokens 9 - * < if
        scroll 2 + to scroll
      then
    then
 ;

\ ---[ HandleKeyPress ]----------------------------------------------
\ function to handle key press events:
:long$ h24$
$| About lesson 24:
$|
$| Key-list for the available functions in this lesson:
$|
$| ESC      exits the lesson
$| w        toggles between fullscreen and windowed modes
$| Up       scrolls extension list up
$| Down     scrolls extension list down
$|
$| Note: OpenGL extensions are not yet active.
  ;long$

: HandleKeyPress ( &event -- )
  case
   \ SDLK_ESCAPE of TRUE to opengl-exit-flag endof
    ascii W     of  start/end-fullscreen   	     endof
    VK_DOWN     of   -1 to scroller handle-scroller  endof
    VK_UP       of    1 to scroller handle-scroller  endof
                h24$ ShowHelp
  endcase
;


\ ---[ Set the viewpoint ]-------------------------------------------

: set-viewpoint
   GL_PROJECTION glMatrixMode          \ Select The Projection Matrix
   glLoadIdentity
   0.0e 640e 480e
   0.0e -1.0e 1.0e glOrtho \ Create Ortho in window View (0,0 At Top Left)
   GL_MODELVIEW glMatrixMode           \ Select The Projection Matrix
 ;

\ ---[ InitGL ]------------------------------------------------------
\ general OpenGL initialization function

: InitGL ( -- boolean )
  \ Load in the texture
  widthViewport  to swidth
  heightViewport to sheight
  LoadGLTextures
  BuildFont                                          \ build the font
  GL_SMOOTH gl-shade-model                    \ Enable smooth shading
  0e 0e 0e 0.5e gl-clear-color             \ Set the background black
  1e gl-clear-depth                              \ Depth buffer setup
  GL_TEXTURE_2D 0 texture-ndx @ gl-bind-texture      \ Select texture
;

\ ---[ DrawGLScene ]-------------------------------------------------
\ Here goes our drawing code

: DrawGLScene ( -- boolean )
  0 0 0 { _cnt *next _len -- boolean }
  \ Clear the screen and the depth buffer
  GL_COLOR_BUFFER_BIT GL_DEPTH_BUFFER_BIT OR gl-clear

  gl-load-identity                                   \ restore matrix

  1e 0.5e 0.5e gl-color-3f                  \ set color to bright red
  50 16 s" Renderer" 1 glPrint                     \ display Renderer
  80 48 s" Vendor"   1 glPrint                  \ display Vendor Name
  66 80 s" Version"  1 glPrint                      \ display Version

  1e 0.7e 0.4e gl-color-3f                      \ set color to orange

  200 16 GL_RENDERER gl-get-string dup s-zlen 1 glPrint
  200 48 GL_VENDOR   gl-get-string dup s-zlen 1 glPrint
  200 80 GL_VERSION  gl-get-string dup s-zlen 1 glPrint

  0.5e 0.5e 1e gl-color-3f                 \ set color to bright blue
  192 432 s" NeHe Productions" 1 glPrint        \ at bottom of screen

  gl-load-identity                       \ reset the modelview matrix
  1e 1e 1e gl-color-3f                           \ set color to white
  GL_LINE_STRIP gl-begin                  \ start drawing line strips
    639e 417e gl-vertex-2d                  \ top/right of bottom box
    0e 417e gl-vertex-2d                     \ top/left of bottom box
    0e 480e gl-vertex-2d                   \ lower/left of bottom box
    639e 480e gl-vertex-2d                \ lower/right of bottom box
    639e 128e gl-vertex-2d            \ up to bottom/right of top box
  gl-end
  GL_LINE_STRIP gl-begin           \ start drawing another line strip
    0e 128e gl-vertex-2d                     \ bottom/left of top box
    639e 128e gl-vertex-2d                  \ bottom/right of top box
    639e 1e gl-vertex-2d                       \ top/right of top box
    0e 1e gl-vertex-2d                          \ top/left of top box
    0e 417e gl-vertex-2d             \ down to top/left of bottom box
  gl-end

  \ Set up the viewport for displaying the Extensions listing

  1                             \ x
  0.135416e sheight S>F F* F>S  \ x y
  swidth 2 -                    \ x y width
  0.597916e sheight S>F F* F>S  \ x y width height

\  GetWindowRect nip   \ x y width height 269

  gl-scissor                    \ --          \ define scissor region
  GL_SCISSOR_TEST gl-enable                  \ enable scissor testing

  \ Load the GL Extensions text into a buffer now
  \ A flag will be set after this has been executed once, so that the
  \ next run of the code will not re-load the Extensions data.

  ExtensionsLoaded 0= if                  \ load them if this flag==0
    GL_EXTENSIONS gl-get-string >R       \ get Extension text address
    here dup to *Extensions R@ s-zlen 1+ dup allot 0 fill \ allot buf
    R@ *Extensions R> s-zlen cmove              \ copy data to buffer
    1 to ExtensionsLoaded         \ toggle flag that buffer is loaded
  then

  *Extensions $20 s-token        \ Get the first entry in the listing
  begin
    (token) C@ 0<>        \ loop thru the entire string until 0 found
  while
    to _len to *next
    _cnt 1+ to _cnt
    _cnt maxtokens > if _cnt to maxtokens then
    0.5e 1e 0.5e gl-color-3f              \ set color to bright green
    10 110 _cnt 32 * + scroll - _cnt s-itos 0 glPrint   \ Extension #
    1e 1e 0.5e gl-color-3f                      \ set color to yellow
    50 110 _cnt 32 * + scroll - *next _len 0 glPrint  \ Extension text
    NULL $20 s-token                          \ search for next token
  repeat
  2DROP

  GL_SCISSOR_TEST gl-disable                \ disable scissor testing

  sdl-gl-swap-buffers                         \ Draw it to the screen
;

: OnKeyEvent ( key - ) \ Update only after a key-event from the window
    to LastKeyIn
    LastKeyIn  HandleKeyPress         \ Pass the key to HandleKeyPress
    DrawGLScene                                     \ Redraw the scene
    0 to LastKeyIn                  \ Clear the key for the next event
 ;

: _ExitLesson ( -- )
  baselist @ 256 gl-delete-lists             \ clean up the font list
  NumTextures texture[] gl-delete-textures        \ clean up textures
 ;

also Forth definitions


: DrawGLLesson24  ( -- )
    ['] OnKeyEvent is KeyboardAction \ Use the keystrokes for this lesson only
    LessonChanged?
      if  ['] _ExitLesson is ExitLesson
          ResetOpenGL
          InitGL
            set-viewpoint                                   \ Set the viewpoint
          DrawGLScene
      then
    DrawGLScene
 ;

 ' DrawGLLesson24 to LastLesson
[Forth]
\s
