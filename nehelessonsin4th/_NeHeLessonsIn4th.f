[DEFINED] -NeHeLessonsIn4th.f   [IF]  100 ms bye [then] \ Preventing duplicate loading.


(( May 6th, 2013.
   OpenGL extensions are now working !
   Added lesson 22 which was a bit hard.

   October 1st, 2018 Adapted for Win32Forth Version: 6.15.05
))

Anew -NeHeLessonsIn4th.f \ April 29th, 2013 by Jos v.d.Ven for Win32Forth version 6.14.01 or better.
needs Helpform.f         \ Shows context sensitive help for each lesson

:long$ about$
$|
$|
$| May 6th, 2013. About the NeHe lessons in Win32Forth,
$| distributed from: http://home.planet.nl/~josv
$|
$| The NeHe lessons are a serie of demos and tutorials to guide
$| one through a number of features of OpenGL.
$| The orginal sources are available in various languages at:
$|
$|   http://nehe.gamedev.net
$|
$| Thanks to Timothy Trussell I was able to port 24 lessons
$| to Win32Forth.
$|
$| The original sources of Timothy can be downloaded from the
$| Taygeta Forth Achive at:
$|
$| ftp://ftp.taygeta.com/pub/Forth/Archive/tutorials/gforth-sdl-opengl
$|
  ;long$

(( Most important modifications for Win32Forth:
 1. SDL is not used.
 2. Open ONE texture at a time when possible.
 3. Uses a mapping in stead of SDL_LoadBMP
 4. Adapted the handling of keystrokes for Win32Forth.
 5. Removed the proto type listnings.
    In combination with OpenGL.f they mostly contained:
 ---[ Prototype Listing ]-------------------------------------------
 : LoadGLTextures              ( -- )
 : HandleKeyPress              ( &event -- )
 : InitGL                      ( -- )
 : DrawGLScene                 ( -- )
 ------------------------------------------------[End Prototypes]---
 6. Each lesson has it's own vocabulary to avoid conflicts.
 7. Functions like LoadGLTexture and Generate-Texture are defined in Opengl.f
 8. All lessons are now in one big program in which you can choose for a lesson.
 ))


\in-system-ok   : [Forth] only forth ;

0 value LastLesson

needs MultiTaskingClass.f
needs WaitableTimer.f
needs AskIntWindow.f                  \ To get integers from a user
needs Opengl.f                        \ For OpenGL support. See opengl.f  \ for a short manual.
needs OpenGlLessons.f                 \ For the missing definitions from GForth
needs NeHeLessons\opengllib-1.02.f
needs NeHeLessons\opengllib-1.03.f
needs NeHeLessons\opengllib-1.04.f
needs NeHeLessons\opengllib-1.05.f
needs NeHeLessons\opengllib-1.06.f
needs NeHeLessons\opengllib-1.07.f
needs NeHeLessons\opengllib-1.08.f
needs NeHeLessons\opengllib-1.09.f
needs NeHeLessons\opengllib-1.10.f
needs NeHeLessons\opengllib-1.11.f
needs NeHeLessons\opengllib-1.12.f
needs NeHeLessons\opengllib-1.13.f
needs NeHeLessons\opengllib-1.16.f
needs NeHeLessons\opengllib-1.17.f
needs NeHeLessons\opengllib-1.18.f
needs NeHeLessons\opengllib-1.19.f
needs NeHeLessons\opengllib-1.20.f
needs NeHeLessons\opengllib-1.21.f
needs NeHeLessons\opengllib-1.22.f
needs NeHeLessons\opengllib-1.23.f
needs NeHeLessons\opengllib-1.24.f
needs NeHeLessons\opengllib-1.25.f
needs NeHeLessons\opengllib-1.26.f
needs NeHeLessons\opengllib-1.27.f
needs IntroScreen.f


: PaintLesson ( - ) \ Starts or changes an OpenGl lesson
   Reset-request-to-stop
    begin   request-to-stop not
    while   LessonChanged?
              if  ExitLesson  close: HelpForm
                  ['] noop is ExitLesson
              then
            painting static-scene
               if    exit \ Just one time
               then
    repeat  \ Loop till Esc has been pressed or another
 ;          \ lesson has been started.

: DynamicPaint ( cfa - )
   is painting
   true to LessonChanged?
   static-scene
   DynamicScene
      if  PaintLesson
      then
 ;

: StaticPaint ( cfa - )
   is painting
   true to LessonChanged?
   static-scene
      if    PaintLesson
      else  StaticScene  PaintLesson
      then
 ;

menubar Openglmenu
 popup "# 02-10"
   menuitem " 02: A first polygon."             ['] DrawGLLesson02 StaticPaint ;
   menuitem " 03: Adding colors."               ['] DrawGLLesson03 StaticPaint ;
   menuitem " 04: Adding rotation."             ['] DrawGLLesson04 DynamicPaint ;
   menuitem " 05: 3D shapes with colors and rotation." ['] DrawGLLesson05 DynamicPaint ;
   menuitem " 06: Adding a texture."            ['] DrawGLLesson06 DynamicPaint ;
   menuitem " 07: Texture Filters, Lighting."   ['] DrawGLLesson07 DynamicPaint ;
   menuitem " 08: Adding Blending."             ['] DrawGLLesson08 DynamicPaint ;
   menuitem " 09: Moving bitmaps."              ['] DrawGLLesson09 DynamicPaint ;
   menuitem " 10: Moving Through A 3D World."   ['] DrawGLLesson10 DynamicPaint ;
 popup "# 11-20"
   menuitem " 11: Flag Effect."                 ['] DrawGLLesson11 DynamicPaint ;
   menuitem " 12: Display Lists."               ['] DrawGLLesson12 DynamicPaint ;
   menuitem " 13: Bitmap Fonts"                 ['] DrawGLLesson13 DynamicPaint ;
   menuitem " 16: Cool looking fog."            ['] DrawGLLesson16 DynamicPaint ;
   menuitem " 17: 2D Texture Font."             ['] DrawGLLesson17 DynamicPaint ;
   menuitem " 18: Quadrics."                    ['] DrawGLLesson18 DynamicPaint ;
   menuitem " 19: Particles."                   ['] DrawGLLesson19 DynamicPaint ;
   menuitem " 20: Masking."                     ['] DrawGLLesson20 DynamicPaint ;
 popup "# 21-27"
   menuitem " 21: Lines, Antialiasing, Timing, Ortho View and Simple Sounds."
                                                ['] DrawGLLesson21 DynamicPaint ;
   menuitem " 22: Bump-Mapping, Multi-Texturing & Extensions"       ['] DrawGLLesson22 DynamicPaint ;
   menuitem " 23: Sphere Mapping Quadrics In OpenGL."               ['] DrawGLLesson23 DynamicPaint ;
   menuitem " 24: Tokens, Extensions, Scissor Testing And TGA Loading." ['] DrawGLLesson24 StaticPaint ;
   menuitem " 25: Morphing & Loading Objects From A File."          ['] DrawGLLesson25 DynamicPaint ;
   menuitem " 26: Clipping & Reflections Using The Stencil Buffer." ['] DrawGLLesson26 DynamicPaint ;
   menuitem " 27: Shadows."                                         ['] DrawGLLesson27 DynamicPaint ;
 popup "Options"
   menuitem   "W - Full screen or window mode"  start-FullscreenOpenGLWindow ;
  :menuitem  mScaleDibsection    "Scale Dibsection"   ScaleDibsection ;
   menuitem   "Maximum frames/second"                          set-speed-fps ;
   menuitem   "About the NeHe lessons in Win32Forth"  close: HelpForm   about$ ShowHelp  ;
endbar

needs Oglwin.f  \                   \ For the window

: SetStateMenuScaleDibsection ( flag - )
    Enable:  mScaleDibsection
 ;

' SetStateMenuScaleDibsection is MenuScaleDibsection

: start-opengl ( -- )
    start-opengl-window
    InitOpenGL  LastLesson StaticPaint
    Openglmenu  SetMenuBar: OpenGLWindow
 ;

 ' ShowIntro to LastLesson                      \ The initial screen

\ start-opengl  \s                             \ Activate this line for interactive debugging

NoConsoleBoot ' start-opengl SAVE NeHeLessonsIn4th.exe \ Generate a program.

winver winnt4 >= [IF]  \ For V6.0.0.0 Common-Controls
  current-dir$ count pad place
  s" \" pad +place
  s" NeHeLessonsIn4th.exe" pad +place
  pad count "path-file drop AddToFile
               CREATEPROCESS_MANIFEST_RESOURCE_ID RT_MANIFEST s" NeHeLessonsIn4th.exe.manifest" "path-file drop  AddResource
                101 s" NeHeLessonsIn4th.ico" "path-file drop AddIcon
                false EndUpdate
        [else]
               s" NeHeLessonsIn4th.ico" s" NeHeLessonsIn4th.exe" Prepend<home>\ AddAppIcon
        [then]

\ Require Checksum.f  s" NeHeLessonsIn4th.exe" (AddCheckSum)
 cr .( Starting NeHeLessonsIn4th.exe)

 dir *.exe
 dos" NeHeLessonsIn4th.exe" dos$ $exec drop cr
 3 pause-seconds
 bye

\s
