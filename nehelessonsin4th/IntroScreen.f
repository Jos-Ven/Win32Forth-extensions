\ April 26th, 2013 for Win32Forth by J.v.d.Ven

anew IntroScreen.f
needs opengl.f

vocabulary Intro  also Intro definitions
Font vFont


0 value baselist

: init-3Dfont  ( -- )
    sizeof glyphmetricsfloat 256 * malloc to lpgmf_buffer
    255 glGenLists to baselist
    s" Comic Sans MS" SetFaceName: vFont
    Create: vFont
    Handle: vFont ghdc call SelectObject             \ Old font on the stack
    ghdc 1 255 baselist 0.2e 0.09e                    \ create display lists
    WGL_FONT_POLYGONS lpgmf_buffer wglUseFontOutlines \ for the selected font
    ( OldFont) ghdc call SelectObject                 \ Restore the old font
    call DeleteObject ?winerror \ Delete the new font. It is now in the list
 ;

: eye-parameters ( f: -- eyex eyey eyez  centerx centery centerz upx upy upz  )
\  eyex    eyey      eyez
   .0000e   .2300e    4.130e
\ centerx  centery   centerz
   .0000e   .1724e    3.340e
\ upx       upy      upz
   00000e   .000e     -.02000e
 ;

: set-viewpoint
    GL_PROJECTION glMatrixMode             \ starting the projection matrix
    glLoadIdentity

    GL_COLOR_BUFFER_BIT GL_DEPTH_BUFFER_BIT OR glClear
    0.0e0  0e0  .0e0     glColor3f         \ The screen color

\ Setting up a perspective in the projection matrix.
\ This will affect the entire scene.
    47.00e 1.000e .0100e 15.00e  gluPerspective
    0.00e .00e -.200e .000e      glRotatef            \ deg x y z rotate eye
\ Setting up a viewing transformation
    eye-parameters gluLookAt
    .1290e .1583e .1700e    glscalef                        \ Scale it a bit
    0.00e .00e -.200e .000e glRotatef  \ deg x y z  Rotate around the center
    -.8700e 1.399e 21.40e   glTranslatef       \ x y z position of the scene
    4.000e -1.400e .0000e .0000e glRotatef   \ deg x y z  Rotate all objects
\ Continue with the model matrix for the object(s)
    GL_MODELVIEW glMatrixMode
 ;

: InitGL  ( -- )
    init-3Dfont
\ Enable a number of features
    GL_SMOOTH    glShadeModel
    GL_DEPTH_TEST glEnable
    GL_FRONT GL_AMBIENT glColorMaterial
    GL_COLOR_MATERIAL glEnable
    GL_LIGHTING   glEnable
    GL_LIGHT0     glEnable
 ;

: DrawIntro ( -- )
    0.00e 1.1624e .1766e 0.3000e objectcolor!  \ Prepair the color of the object
    GL_POLYGON               \           fill
      -10.00e 0e 0.5e 0e     \       Rotation f: deg xg yg zg
      .2333e .2531e  .7000e  \        Scaling f: xs ys zs
     -.4000e .2100e -.4000e  \ Transformation f: xt yt zt
      [rot-scaled-object  ( fill -- ) ( f: deg xg yg zg   xs ys zs   xt yt zt -- )
    s" NeHe" baselist glType
    object]

    0.00e -4.038e 1.977e .3000e  objectcolor!
    GL_POLYGON
      -10.00e 0e 0.5e 0e
      .2333e   .2531e  .7000e
      -.4000e -.1900e -.4000e
      [rot-scaled-object  ( fill -- ) ( f: deg xg yg zg   xs ys zs   xt yt zt -- )
    s" in Win32Forth." baselist glType
    object]


    0.00e 1.162e .5766e .3000e  objectcolor!
    GL_POLYGON
       0.00e 0e 0.5e 0e
       0.2e     .2531e  .7000e
       -.4000e -.5900e -.4000e
      [rot-scaled-object  ( fill -- )  ( f: deg xg yg zg   xs ys zs   xt yt zt -- )
     s" Choose a lesson and press F1 for help." baselist glType
    object]
    show-frame
 ;

: ExitIntro ( - )
  baselist 255 glDeleteLists                 \ Kill  the 3d Font in the list
  lpgmf_buffer free                                  \ Free the lpgmf_buffer
  100 to Old%rate GetClientRect                       \ restore the viewport
  to heightViewport to widthViewport            \ incase interrupted occured
  switchToDC                                \ Use a DC in one of the lessons
  InitOpenGL
  true to resizing?
 ;


: RefreshIntro ( - )
    InitGL                                            \ Initialize the scene
    set-viewpoint
    DrawIntro                                               \ Draw the scene
 ;

: BootIntro ( - )
   switchToDib  DynamicScene 11 1                \ Switching to a DIBsection
     do  i dup * s>f 100e f/ ScaleDib        \ for the bitmap scaling effect
         RefreshIntro 90 ms request-to-stop
           if leave
           then
     loop
   false to FirstTime
   request-to-stop
     if  exit
     then
   StaticScene
 DrawIntro                                   \ Now it becomes a static scene
 ;

also Forth definitions

: ShowIntro ( -- )
  ['] drop is KeyboardAction            \ Disable all keys here except escape
  ['] ExitIntro is ExitLesson   \ Specify ExitLesson to free allocated memory
  FirstTime
    if    false to request-to-stop BootIntro
    else  StaticScene RefreshIntro
    then
 ;

[Forth]
\s
