\ ===================================================================
\           File: opengllib-1.13.fs
\         Author: Jeff Molofee
\  Linux Version: Ti Leggett
\ gForth Version: Timothy Trussell, 07/31/2010
\    Description: Bitmap fonts
\   Forth System: gforth-0.7.0
\   Linux System: Ubuntu v10.04 LTS i386, kernel 2.6.31-24
\   C++ Compiler: gcc version 4.4.3 (Ubuntu 4.4.3-4ubuntu5)
\ ===================================================================
\                       NeHe Productions
\                    http://nehe.gamedev.net/
\ ===================================================================
\                   OpenGL Tutorial Lesson 13
\ ===================================================================
\ This code was created by Jeff Molofee '99
\ (ported to Linux/SDL by Ti Leggett '01)
\ March, 2013 adapted for Win32Forth by Jos v.d.Ven
\ Visit Jeff at http://nehe.gamedev.net/
\ ===================================================================

vocabulary Lesson13  also Lesson13 definitions

\ ---[ Variable Declarations ]---------------------------------------

variable baselist                \ base display list for the font set
fvariable count1     \ 1st counter used to move text and for coloring
fvariable count2     \ 2nd counter used to move text and for coloring

\ ---[ Variable Initializations ]------------------------------------

0 baselist !
0e count1 F!
0e count2 F!

255 constant string-len
create temp-string here string-len 1+ dup allot 0 fill

\ ---[ concat-string ]---
\ A basic string concatenation function, to add one string to another

: concat-string { *str _len *dst -- }
  *str *dst 1+ *dst C@ + _len cmove
  *dst C@ _len + *dst C!                \ use *dst[0] as length byte
;

\ ---[ IntToStr ]---
\ Converts an integer value to a string; returns addr/len

: IntToStr ( n -- *str len ) 0 <# #S #> ;

\ ===[ Back to our regularly scheduled code ]========================

\ ---[ KillFont ]----------------------------------------------------
\ Recover memory from our list of characters

: KillFont ( -- )
  baselist @ 96 gl-delete-lists
;

\ ---[ BuildFont ]---------------------------------------------------
\ Builds our font lists

0 value OldFont

Font NewFont

: BuildFont ( -- )                           \ Adapted for Win32Forth
         96 gl-gen-lists baselist !       \ Storage for 96 characters
         26 Height: NewFont
         13  Width: NewFont
    FW_BOLD Weight: NewFont
    s" Courier New" SetFaceName: NewFont   \ The font name to be used
    Create: NewFont                                 \ Create the font
    Handle: NewFont ghdc
    call SelectObject to OldFont            \ Select the font we want
    ghdc 32 96 baselist @
    wglUseFontBitmaps \ Builds 96 characters starting at character 32
    OldFont ghdc call SelectObject             \ Restore the old font
    call DeleteObject ?winerror                \ Delete the new font
 ;

\ ---[ glPrint ]-----------------------------------------------------
\ Print our GL text to the screen.

\ The passed string should have an extra character appended to the
\ end, so the string can be zero-delimited string by *this* function
\ - not by the calling function.  We want to have the string length
\ on the stack when glPrint is called.

: glPrint ( *str _len -- )
  \ skip if string length==0
  dup 0> if
    dup >R                                           \ save length
    temp$ place temp$ dup +null 1+ \ convert to zero-delimited string
    GL_LIST_BIT gl-push-attrib           \ push the display list bits
    baselist @ 32 - gl-list-base           \ Set base character to 32
    R> GL_UNSIGNED_BYTE rot gl-call-lists             \ Draw the text
    gl-pop-attrib                         \ Pop the display list bits
  else
    2DROP
  then
;

\ ---[ HandleKeyPress ]----------------------------------------------
\ function to handle key press events:
:long$ h13$
$| About lesson 13:
$|
$| Key-list for the available functions in this lesson:
$|
$| ESC      exits the lesson
$| W        toggles between fullscreen and windowed modes
  ;long$

\ ---[ HandleKeyPress ]----------------------------------------------
\ function to handle key press events

: HandleKeyPress ( VK_key  -- )
    ascii W =
      if     start/end-fullscreen       \ Starts of end the full screen
      else   h13$ ShowHelp         \ Show the help text for this lesson
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
  \ Return a good value
  BuildFont
  \ returns result from BuildFont
;

\ ---[ DrawGLScene ]-------------------------------------------------
\ Here goes our drawing code

: DrawGLScene ( -- )
  \ Clear the screen and the depth buffer
  GL_COLOR_BUFFER_BIT GL_DEPTH_BUFFER_BIT OR gl-clear
  gl-load-identity
  \ Move into the screen 1 unit
  0e 0e -1e gl-translate-f
  \ Pulsing colors based on text position
  1e count1 F@ FCOS F*
  1e count2 F@ FSIN F*
  1e 0.5e count1 F@ count2 F@ F+ FCOS F* F- gl-color-3f
  \ Position the text on the screen
  -0.45e 0.05e count1 F@ FCOS F* F+
  0.35e count2 F@ FSIN F*
  gl-raster-pos-2f
  \ Build the text string to display
  \ zero temp string length - where we will build our string at
  0 temp-string !
  \ Copy the main text to the temp string
  s" Active OpenGL Text With NeHe - " temp-string concat-string
  \ Convert the whole part of count1 to a string and concat it
  count1 F@ temp$ (g.) temp$ count temp-string concat-string
  \ Print the text to the screen
  temp-string dup 1+ swap C@ glPrint

  count1 F@ 0.051e F+ count1 F!         \ increase the first counter
  count2 F@ 0.005e F+ count2 F!         \ increase the second counter

  \ Draw it to the screen
  sdl-gl-swap-buffers
;


: _exitLesson  ( -- )          \ For a clean start in the next lesson
  KillFont
  true to resizing?
 ;

: ResetLesson  ( -- )              \ For a clean start in this lesson
    ResetOpenGL                      \ Cleanup from a previous lesson
    InitGL                   \ Enable some features and load textures
    set-viewpoint                                 \ Set the viewpoint
    false to resizing?
 ;


also Forth definitions


: DrawGLLesson13  ( -- )                          \ Handles ONE frame
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

 ' DrawGLLesson11 to LastLesson
[Forth]

' DrawGLLesson13 to LastLesson

[Forth]
\s


