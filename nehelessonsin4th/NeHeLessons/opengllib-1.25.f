\ ===================================================================
\           File: opengllib-1.25.fs
\         Author: Piotr Cieslak
\  Linux Version: DarkAlloy
\ gForth Version: Timothy Trussell, 05/25/2011
\    Description: Morphing, loading objects
\   Forth System: gforth-0.7.0
\   Linux System: Ubuntu v10.04 LTS i386, kernel 2.6.32-31
\   C++ Compiler: gcc (Ubuntu 4.4.1-4ubuntu9) 4.4.1
\ ===================================================================
\                       NeHe Productions
\                    http://nehe.gamedev.net/
\ ===================================================================
\                   OpenGL Tutorial Lesson 25
\ ===================================================================
\ This code was created by Jeff Molofee 2000
\ Visit Jeff at http://nehe.gamedev.net/
\ March, 2013 adapted for Win32Forth by Jos v.d.Ven
\ ===================================================================

vocabulary Lesson25  also Lesson25 definitions


\ ============[ Additional Ancilliary Support Routines ]=============

\ ---[ String/Array Words ]------------------------------------------

\ s-new creates the base name, storing the element size in next cell
: s-new    ( size -- ) create , does> ;

\ s-alloc allots/clears a single element instance; returns address
: s-alloc  ( *base -- *t ) @ here dup rot dup allot 0 fill ;

\ s-alloc# allots/clears an array of elements; returns 1st address
: s-alloc# ( *base n -- *t ) swap @ * here dup rot dup allot 0 fill ;

\ s-ndx returns the n-th element address of an array
: s-ndx    ( *base n -- *str[n] ) over @ * CELL + + ;

\ s-token scans the source string for the first occurrence of the
\         character /c/ returning *str/len of the string
\         Succeeding calls using NULL as the source address will
\         continue from one byte past the last found address.

0 VALUE (token)                            \ addr of last token found

: s-token { *src _c -- *str len }
  *src 0= if (token) 1+ to *src then   \ if NULL passed use last addr
  0                               \ initial count value for this pass
  begin *src over + C@ dup _c = swap 0= OR if 1 else 1+ 0 then until
  *src over + to (token)                          \ set for next time
  *src swap
;

\ ---[ RANDOM NUMBERS IN FORTH ]-------------------------------------
\  D. H. Lehmers Parametric multiplicative linear congruential
\  random number generator is implemented as outlined in the
\  October 1988 Communications of the ACM ( V 31 N 10 page 1192)
\ --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

     16807 =: (A)
2147483647 =: (M)
    127773 =: (Q)   \ m a /
      2836 =: (R)   \ m a mod

CREATE (SEED)  123475689 ,

\ Returns a full cycle random number
: RAND ( -- rand )                        \ 0 <= rand < 4,294,967,295
   (SEED) @ (Q) /MOD ( lo high)
   (R) * SWAP (A) * 2DUP > IF - ELSE - (M) + THEN  DUP (SEED) ! ;

\ Returns single random number less than n
: RND ( n -- rnd ) RAND SWAP MOD ;                     \ 0 <= rnd < n

\ ---[ Variable Declarations ]---------------------------------------

    0 VALUE step                              \ morphing step counter
  200 VALUE steps                  \ maximum number of morphing steps
FALSE VALUE morph                              \ is morphing enabled?
    0 VALUE *sour                          \ pointer to source object
    0 VALUE *dest                     \ pointer to destination object
    0 VALUE maxver                       \ maximum number of vertices

FVARIABLE xrot                                           \ x rotation
FVARIABLE yrot                                           \ y rotation
FVARIABLE zrot                                           \ z rotation
FVARIABLE xspeed                                   \ x rotation speed
FVARIABLE yspeed                                   \ y rotation speed
FVARIABLE zspeed                                   \ z rotation speed
FVARIABLE cx                                             \ x position
FVARIABLE cy                                             \ y position
FVARIABLE cz                                             \ z position

\ ---[ Start settings ]----------------------------------------------

1e xspeed f!
1e yspeed f!
1e zspeed f!
\ -------------------------------------------------------------------

struct{
  b/float .xcoord
  b/float .ycoord
  b/float .zcoord
}struct vertex%
sizeof vertex% constant /vertex%

struct{
  cell .verts             \ number of verrtices for the object
  cell .points                  \ pointer to array of vertices
}struct object%
sizeof object% constant /object%

/object% mkstruct: morph1                 \ the four morphable objects
/object% mkstruct: morph2
/object% mkstruct: morph3
/object% mkstruct: morph4
/object% mkstruct: helper                            \ a helper object

\ Create and allocate the data spaces for the image data points.
\ This uses the String/Array functions to first create a base entry
\ using the s-new function, and then allocates and zeroes the space
\ for a specified number of elements in the array (486 in this case)
\ using the s-alloc# function.
\
\ A specific array element is then accessed using the s-ndx function
\ by specifying the base entry name and the index number to find:
\
\    486 0 do
\      Sphere[] i s-ndx          ( -- *Sphere[i] )
\      ( do something with the data )
\      dup .xcoord F@
\      dup .ycoord F@
\          .zcoord F@ gl-vertex-3f
\    loop

/vertex% s-new Sphere[]         \ create a String/Array base entry
Sphere[] 486 s-alloc# drop      \ allocate the data space immediately

/vertex% s-new Torus[]          Torus[]  486 s-alloc# drop
/vertex% s-new Tube[]           Tube[]   486 s-alloc# drop
/vertex% s-new Stars[]          Stars[]  486 s-alloc# drop
/vertex% s-new Helper[]         Helper[] 486 s-alloc# drop

\ ---[ Variable Initializations ]------------------------------------

-10e0 cz F!  \ was -15e

\ ===[ The code ]====================================================

\ ---[ LoadObj ]-----------------------------------------------------
\ Loads the specified data file into a temp buffer above <here>

: LoadObj ( *str len -- *buf )
  0 0 0 0 { *str _len _fh *buf *src #src -- *buf }
  here 65536 MOD 65536 swap - here + to *buf   \ set temp buffer addr
  *buf 65536 255 fill                            \ zero the temp buffer
  *buf to *src
  *str _len r/o open-file throw to _fh             \ open source file
  begin
    *src 4096 _fh read-file throw dup *src + to *src 0=
  until
  *src *buf - to #src               \ calculate length of data loaded
  _fh close-file throw                            \ close source file
  *buf                                        \ return buffer address
;

\ ---[ ProcessObj ]--------------------------------------------------
\ Converts the object data from text to floating point, and then
\ stores the FP numbers to the *dst array.
\ The destination array is a String/Array construct.

: ProcessObj ( *buf *dst *obj -- #verts )
  0 { *buf *dst *obj #verts -- #verts }
  *buf $20 s-token + 1+ $0D s-token
  0.0 2OVER >number 2DROP DROP DUP to #verts  \ get #vertices
  ( #verts ) 0 do
    + 2 +                      \ advance to start of next vertice set
    $20 s-token 2DUP >float drop *dst i s-ndx .xcoord F! + 5 +
    $20 s-token 2DUP >float drop *dst i s-ndx .ycoord F! + 5 +
    $0D s-token 2DUP >float drop *dst i s-ndx .zcoord F!
  loop
  2DROP                                 \ drop addr/len of last found
  #verts maxver > if #verts to maxver then            \ update maxver
  #verts *obj .verts !                         \ set #verts in object
  *dst *obj .points !                  \ set vertex address in object
;

s" Sphere.txt" LoadObj ( *buf ) Sphere[] morph1 ProcessObj
s" Torus.txt"  LoadObj ( *buf ) Torus[]  morph2 ProcessObj
s" Tube.txt"   LoadObj ( *buf ) Tube[]   morph3 ProcessObj
s" Sphere.txt" LoadObj ( *buf ) Helper[] helper ProcessObj


\ ---[ HandleKeyPress ]----------------------------------------------
\ function to handle key press events:
:long$ h25$
$| About lesson 25:
$|
$| Key-list for the available functions in this lesson:
$|
$| ESC      exits the lesson
$| w        toggles between fullscreen and windowed modes
$| PgUp     increase z-speed
$| PgDn     decrease z-speed
$| Up       decrease x-speed
$| Down     increase x-speed
$| Left     decrease y-speed
$| Right    increase y-speed
$| Home     Resets the speed rotation and postion
$| d        move object right
$| a        move object left
$| q        move object up
$| s        move object down
$| z        move object towards viewer
$| x        move object away from viewer
$| 1..4     morphs to different objects ))

: HandleKeyPress ( &event -- )
  case
   \ ascii ESCAPE of TRUE to opengl-exit-flag endof
    ascii W     of  start/end-fullscreen endof

    VK_HOME     of    0e0 xrot F!
                      0e0 yrot F!
                      0e0 zrot F!
                      0e0 xspeed F!
                      0e0 yspeed F!
                      0e0 zspeed F!
                      0e0 cx F!
                      0e0 cy F!
                      -15e0 cz F!
                  endof

    VK_PGDN      of 0.01e0 zspeed F-! endof                \ -zspeed
    VK_PGUP      of 0.01e0 zspeed F+! endof                \ +zspeed
    VK_UP        of 0.01e0 xspeed F-! endof                \ -xspeed
    VK_DOWN      of 0.01e0 xspeed F+! endof                \ +xspeed
    VK_LEFT      of 0.01e0 yspeed F-! endof                \ -yspeed
    VK_RIGHT     of 0.01e0 yspeed F+! endof                \ +yspeed

    ascii D      of 0.01e0 cx F+! endof                 \ move right
    ascii A      of 0.01e0 cx F-! endof                  \ move left
    ascii Q      of 0.01e0 cy F+! endof                    \ move up
    ascii S      of 0.01e0 cy F-! endof                  \ move down
    ascii Z      of 0.01e0 cz F+! endof                \ move closer
    ascii X      of 0.01e0 cz F-! endof                  \ move away

    ascii 1      of morph FALSE = if
                       TRUE to morph         \ start morphing process
                       morph1 to *dest             \ set *dest object
                     then
                  endof

    ascii 2      of morph FALSE = if
                       TRUE to morph         \ start morphing process
                       morph2 to *dest             \ set *dest object
                     then
                  endof

    ascii 3      of morph FALSE = if
                       TRUE to morph         \ start morphing process
                       morph3 to *dest             \ set *dest object
                     then
                  endof

    ascii 4      of morph FALSE = if
                       TRUE to morph         \ start morphing process
                       morph4 to *dest             \ set *dest object
                     then
                  endof
                 h25$ ShowHelp
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

: InitGL ( -- boolean )
  GL_SRC_ALPHA GL_ONE gl-blend-func   \ Set blending for translucency
  0e 0e 0e 0e gl-clear-color               \ Set the background black
  1e gl-clear-depth            \ Enables clearing of the depth buffer
  GL_LESS gl-depth-func                    \ Type of depth test to do
  GL_DEPTH_TEST gl-enable                     \ Enables depth testing
  GL_SMOOTH gl-shade-model              \ Enable smooth color shading
  GL_PERSPECTIVE_CORRECTION_HINT GL_NICEST gl-hint      \ Perspective

  \ Initialize the morph4 object data (stars)
  486 0 do            \ all x/y/z points are a random float in -7..+7
    14000 RND S>F 1000e F/ 7e F- Stars[] i s-ndx .xcoord F!
    14000 RND S>F 1000e F/ 7e F- Stars[] i s-ndx .ycoord F!
    14000 RND S>F 1000e F/ 7e F- Stars[] i s-ndx .zcoord F!
  loop

  486 morph4 .verts ! Stars[] morph4 .points !

  \ Source & Destination are set to the first object (morph1)
  morph1 to *sour
  morph1 to *dest
;

\ ---[ Calculate ]---------------------------------------------------
\ Calculates movement of points during morphing
\ --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
\ Changed to add the destination VERTEX* in the call
\ Considering simply putting the x/y/z values on the FP stack
\ --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

: Calculate ( ndx *v -- )
  0 0 { _ndx *v *src *dst -- }
  *sour .points @ _ndx s-ndx to *src             \ calc base pointers
  *dest .points @ _ndx s-ndx to *dst
  *src .xcoord F@ *dst .xcoord F@ F- steps S>F F/ *v .xcoord F!
  *src .ycoord F@ *dst .ycoord F@ F- steps S>F F/ *v .ycoord F!
  *src .zcoord F@ *dst .zcoord F@ F- steps S>F F/ *v .zcoord F!
;

\ ---[ DrawGLScene ]-------------------------------------------------

FVARIABLE tx                              \ temporary x/y/z variables
FVARIABLE ty
FVARIABLE tz
/vertex% mkstruct: qtemp               \ temporary vertex storage area

: DrawGLScene ( -- boolean )
  GL_COLOR_BUFFER_BIT GL_DEPTH_BUFFER_BIT OR gl-clear  \ Clear screen
  gl-load-identity                                 \ Reset the matrix
  cx F@ cy F@ cz F@ gl-translate-f       \ translate display position

  xrot F@ 1e 0e 0e gl-rotate-f                 \ rotate on the x axis
  yrot F@ 0e 1e 0e gl-rotate-f                 \ rotate on the y axis
  zrot F@ 0e 0e 1e gl-rotate-f                 \ rotate on the z axis

  xspeed F@ xrot F+!                   \ Increase the rotation values
  yspeed F@ yrot F+!
  zspeed F@ zrot F+!

  GL_POINTS gl-begin
    486 0 do
      morph if
        i qtemp Calculate
      else
        0e0 qtemp .xcoord F!
        0e0 qtemp .ycoord F!
        0e0 qtemp .zcoord F!
      then

      helper .points @ i s-ndx >R
      qtemp .xcoord F@ R@ .xcoord F-! R@ .xcoord F@ tx F!
      qtemp .ycoord F@ R@ .ycoord F-! R@ .ycoord F@ ty F!
      qtemp .zcoord F@ R@ .zcoord F-! R> .zcoord F@ tz F!

      0e 1e 1e gl-color-3f                    \ set color to off-blue
      tx F@ ty F@ tz F@ gl-vertex-3f     \ draw a point at temp x/y/z

      0e 0.5e 1e gl-color-3f                 \ darken the color a bit
      2e0 qtemp .xcoord F@ F* tx F-!             \ calc two positions
      2e0 qtemp .ycoord F@ F* ty F-!                          \ ahead
      2e0 qtemp .ycoord F@ F* ty F-!
      tx F@ ty F@ tz F@ gl-vertex-3f            \ draw a second point

      0e 0e 1e gl-color-3f              \ set color to very dark blue
      2e0 qtemp .xcoord F@ F* tx F-!             \ calc two positions
      2e0 qtemp .ycoord F@ F* ty F-!                          \ ahead
      2e0 qtemp .ycoord F@ F* ty F-!                          \ again
      tx F@ ty F@ tz F@ gl-vertex-3f             \ draw a third point
    loop
  gl-end

  \ If we're morphing and we have not gone through all 200 steps
  \ increase our step counter; otherwise set morphing to false, make
  \ Source=Destination and set the step counter back to zero.

  step steps < morph AND if
    step 1+ to step
  else
    FALSE to morph
    *dest to *sour
    0 to step
  then

  \ Draw it to the screen -- if double buffering is permitted
  sdl-gl-swap-buffers
;

: _exitLesson  ( -- )          \ For a clean start in the next lesson
  true to resizing?
 ;

: ResetLesson  ( -- )              \ For a clean start in this lesson
    ResetOpenGL                      \ Cleanup from a previous lesson
    InitGL                   \ Enable some features and load textures
    set-viewpoint                                 \ Set the viewpoint
    false to resizing?
 ;


also Forth definitions


: DrawGLLesson25  ( -- )                          \ Handles ONE frame
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


 ' DrawGLLesson25 to LastLesson
[Forth]
\s

