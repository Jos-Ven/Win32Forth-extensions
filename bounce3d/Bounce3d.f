anew  bounce3d.f \ Needs Win32Forth V6.15.04
\ 2 sided bouncing against triangles in 3D.
\ The size of the ball is not included.
\ The used perspective and the 3D projection on a 2D screen
\ might trick you. Use the z-key for another angle to view the scene.
\ There is a special effect when the StartingSpeed is set to -0.04e
\ and #balls is set to 420.

\ How could we get rid of UU WU UV VV WV and keep about the same or
\ better results in the speed-test. ( see at the end of the code )

s" src\lib\OpenGl" "fpath+    needs opengl.f

121 constant #balls     \ Nice are: 2 20 120 or 420
5  constant #triangles \ 1 or 5 can be used without changing the source.
3  constant #PointsTriangle
0  constant LeftSide   \ v0
1  constant Rightside  \ v1
2  constant Top        \ v2
3  constant #3dPoint   \ The number coordinates in one 3d point
#3dPoint b/float * constant /3d  \ The size of one 3d point
sizeof 3dRoot  constant /3dRoot  \ Contains a direction vector and ID

: 3f@ ( &3dPoint - ) ( f: - x y z ) 3 floats@ ;
: 3f! ( &3dPoint - ) ( f: x y z - ) dup float+ dup float+ f! f! f! ;
synonym >fx@ f@ ( &3dPoint - ) ( f: - n )
: >fy@ ( &3dPoint - ) ( f: - n )  float+ f@ ;
: >fz@ ( &3dPoint - ) ( f: - n )  [ 2 floats ] literal + f@ ;
: >{dir} ( - ) ; immediate   \ Does nothing since it is 1st in object
: >3dPoint  ( &All3dPointsOneObject which - &3dPoint ) /3d * + ;

sizeof ball_dyn constant /ball
#balls /ball * mkstruct: &AllBalls
: >Ball ( #ball - &ball ) /ball * &AllBalls + ;

also Structs definitions in-system
: 3dPoint        ( -- )  /3d                   add-struct ; immediate
: PointsTriangle ( -- )  /3d #PointsTriangle * add-struct ; immediate
previous also forth definitions
: .3d ( &3dPoint - ) 3 0  do  dup i >f@  f. tab  loop drop ;
: 3dDump ( &3dPoints #3dPoints - )
   tabing-on 0 to left-margin 3 to tab-size
   crtab tab ."        x         y         z" /3d * 0
      do    crtab i dup /3d / 4 u.r ." : " over + .3d /3d
      +loop   drop tabing-off ;
in-previous

struct{                                \ One triangle in a 3d space
    /3dRoot _add-struct                \ At >{dir}
    PointsTriangle >3dPoints
    3dPoint >{u}                       \ v1-v0
    3dPoint >{v}                       \ v2-v0
    3dPoint >{n}                       \ The calculated normal
}struct TriangleStruct

sizeof TriangleStruct constant /TriangleStruct
#triangles /TriangleStruct * mkstruct: &AllTriangles

: >Triangle ( #triangle - &Triangle )
     /TriangleStruct * &AllTriangles +  ;

: >TrianglePoint  ( #triangle #point - &Point )
     /3d * swap >Triangle + >3dPoints ;

: >TrianglePoint! ( #triangle #point - ) ( f: x y z - )
     >TrianglePoint 3f! ;

\ The math part

: Sub2vec ( &v1 &v2 &vResult - ) \ &vResult=v1-v2
   3reverse 2dup >fx@ >fx@ f-
            2dup >fy@ >fy@ f-
                 >fz@ >fz@ f- 3f! ;

: Dot*   ( &v1 &v2 - ) ( f - Dot* )
   2dup >fx@ >fx@ f*
   2dup >fy@ >fy@ f* f+
        >fz@ >fz@ f* f+ ;

: Cross* ( &v1 &v2 &vResult - )
   -rot 2dup >fz@ >fy@ f*
        2dup >fy@ >fz@ f* f-
        2dup >fx@ >fz@ f*
        2dup >fz@ >fx@ f* f-
        2dup >fy@ >fx@ f*
             >fx@ >fy@ f* f- 3f! ;

\ The algorithm for the intersection came from:
\ http://geomalgorithms.com/a06-_intersect-2.html
\ Modification: The ray direction vector is not calculated
\ since it is now saved in the structure of the ball.
\ NormalTriangle needs only be calculated at the start
\ or when a triangle has been moved.

: NormalTriangle   ( &Triangle - )
    dup>r >3dPoints     \ The 1st 3dPoint is also the leftside v0
    dup Rightside >3dPoint over r@ >{u} Sub2vec  \ u = v1-v0
    dup    Top    >3dPoint swap r@ >{v} Sub2vec  \ v = v2-v0
    r@ >{u} r@ >{v} r> >{n} Cross* ;  \ Cross product: n = u * v

: NormalTriangles ( - )
   #Triangles 0  do  I >Triangle NormalTriangle  loop ;

1e-40 fconstant small_dist

: NotIntersecting?  ( &Triangle &Ball - flag ) ( f: - ScalarA )
\ Flag: True means no intersection with the triangle plane
\ ScalarA= Scalar distance between the ball and the triangle plane
    dup>r OrgPosition over >3dPoints pad Sub2vec         \ w0 = p0-v0
    dup >{n} pad Dot*  fdup f0<> fnegate             \ a = -dot(n,w0)
      if  fdup >{n}  r> >{dir} Dot*                  \ b = dot(n,dir)
          fdup fabs small_dist f>
               if    f/ fdup f0< 1e f> or exit         \ IntersectY/N
               else  fdrop fdrop true   \ Ray is parallel to triangle
               then
      else  drop r>drop false            \ Ray lies in triangle plane
      then ;

: IntersectPoint ( &vOrg &vDir &vI_vResult - ) ( f: r - )
   >r fdup  2dup >fx@ f* >fx@ f+
      fover 2dup >fy@ f* >fy@ f+
            frot >fz@ f* >fz@ f+  r> 3f! ; \ I = p0 + r * dir

0e fvalue uu  0e fvalue wu  0e fvalue uv  0e fvalue vv  0e fvalue wv

: IntersectPointPlane ( &Triangle &Ball - ) ( f: ScalarA - D )
   >r dup >{n} r@ >{dir} Dot* f/            \ r = ScalarA / b
   r@ OrgPosition r> pad IntersectPoint
   dup >{v} over >{u} dup>r
   over     Dot*  fdup fto uv fdup          \ {u} {v} Dot* fto uv
   f*                                       \ uv * uv
   r@  dup  Dot*  fdup fto uu               \ {u} {u} Dot* fto uu
   dup dup  Dot*  fdup fto vv               \ {v} {v} Dot* fto vv
   f* f-                                    \ D = uv * uv - uu * vv
   pad rot >3dPoints pad Sub2vec            \ {w} = I - V0
   pad swap Dot*  fto wv                    \ {w} {v} Dot* fto wv
   pad r>   Dot*  fto wu ;                  \ {w} {u} Dot* fto wu

: Parametric ( - f ) ( f: D r* r2 r3 - p ) f* f- fswap f/ fdup f0< ;

: OutsideS? ( - flag ) ( f: D - s )    \ s = (uv * wv - vv * wu) / D
   uv wv f*   vv wu Parametric  fdup 1e f> or ;

: OutsideT? ( - flag )  ( f: s D -  )  \ t = (uv * wu - uu * wv) / D
   uv wu f*   uu wv Parametric    f+ 1e f> or ;

: BallOutsideTriangle? ( &Triangle &Ball - flag )
   2dup NotIntersecting?
       if    2drop fdrop true exit
       else  IntersectPointPlane fdup OutsideS?
               if    fdrop fdrop true
               else  fswap OutsideT?
               then
       then ;

\ The algorithm for the reflection vector came from:
\ http://bit.ly/1Osyl0C

: UnitVector ( &n &vResult - ) \ Convert a normal into a unit vector
    swap dup >fx@ f^2  dup >fy@ f^2  f+ dup >fz@ f^2 f+ fsqr
    dup >fx@ fover f/ fswap
    dup >fy@ fover f/
        >fz@ frot  f/ 3f! ;

: Reflection  ( &NL &L - )     \ R = -2* ( L . N ) * N + L
   dup>r over Dot* -2.0e f*    \ &L = The old direction vector
   fdup dup >fx@ f* r@ >fx@ f+ fswap
   fdup dup >fy@ f* r@ >fy@ f+ fswap
   >fz@ f* r@ >fz@ f+ r> 3f! ; \ Replace the old direction vector

: BounceBallTrangle  ( &Triangle &Ball - )
   swap >{n} pad UnitVector   pad swap >{dir} Reflection ;

\ Testing the system in OpenGl.

menubar Openglmenu         \ A minimal menu for the OpenGL window
  popup "&File"  menuitem  "E&xit" ExitScene bye ;
endbar
needs oglwin.f             \ The OpenGL window

sizeof box_dyn   mkstruct: SquashRoom        \ The bounding box
SquashRoom   6.4e  4.90e  9.75e  box_sizes!

0.07e 0.01e f- #Balls s>f f/       fconstant SpeedFactor
0.07e fconstant BallSize    0.002e fconstant StartingSpeed
\ -0.04e  fconstant StartingSpeed \ Special effect

: init-balls ( - )
  StartingSpeed  #Balls 0                    \ Store for each ball:
    do  i dup >Ball tuck id !                \ The ID
        BallSize dup ball_size!              \ The size
        0.6e 1.0e 3.950e  dup position!      \ The starting position
        fdup 7e-4 f+ fdup fdup 0.002e f+ move! \ The direction vector
        SpeedFactor f+             \ Increase the speed for each ball
    loop  fdrop ;

init-balls \ Balls outside the piramid should not get in it and
           \ the blue ball inside the pyramid should not get out.

0 >Ball -0.02e -.5e 2.5e position! \ The blue ball

: SetTriangle ( #Triangle - ) ( f: lx ly lz  rx ry rz  tx ty tz - )
  dup Top      >TrianglePoint! dup Rightside >TrianglePoint!
  dup LeftSide >TrianglePoint! dup           >Triangle id ! ;

\ The red triangle:
\    Left            Right              Top       id
-3e -1.5e 1e    2.44e -2.44e -2e   0.5e 2.4e -4e  0  SetTriangle

#triangles 5 =  [if]  \ Adding the yellow triangular pyramid
 -1e -1e  3e      1e  -1e   3e     0.25e 1e 2e    1  SetTriangle
 -1e -1e  3e     0.5e -1e  1.5e    0.25e 1e 2e    2  SetTriangle
 .5e -1e 1.5e     1e  -1e   3e     0.25e 1e 2e    3  SetTriangle
 -1e -1e  3e     0.5e -1e  1.5e      1e -1e 3e    4  SetTriangle
[then]

: newxyz  ( &fmxyz  - ) dup f@ fnegate f! ;

: BounceInside ( &ball - )      \ Inside the box. Has it's own way to
       SquashRoom over   ( - SquashRoom BALL ) \ prevent a dull scene
       dup fball_size f@ fdup dup ftz f@ f+  \ ball-size + position_z
       over fbox_hz f@ f2dup f>=
            if     dup fmz  newxyz  f2drop   \ z+
            else   fnegate  f<=
                       if    dup fmz newxyz  \ z- front
                       then
            then         ( - SquashRoom BALL ) ( f: - fball_hsize )

       fdup dup fty f@ f+                    \ ball-size + position_y
       over fbox_hy f@ f2dup  f>=
            if     dup  fmy newxyz  fdrop fdrop
            else   fnegate  f<=
                       if   dup fmy newxyz
                       then
            then

       dup ftx f@ f+                         \ ball-size + position_x
       over fbox_hx f@ f2dup  f>=
            if     dup ( fmx) newxyz fdrop fdrop
            else   fnegate  f<=
                       if    dup ( fmx) newxyz
                       then
            then
       2drop move-it ;

: SquashRoomInlist ( - )
     .0e0  .0e0  .0e0  glColor3f
      GL_LINE_LOOP glBegin
           [ SquashRoom box_sizes@ 3fliteral ]  box
      glEnd ;

: TrianglesInlist  ( - )
   #triangles 0 do
     .20e  .02e  i s>f fdup  2e f* .74e fmax objectcolor GLfloat!
       [quad GL_TRIANGLES glBegin
        -1.0e   0.0e    0.0e  glNormal3f               \ Left side V0
           i LeftSide  >TrianglePoint 3f@ glVertex3f
         1.0e   0.0e    0.0e  glNormal3f               \ Right side V1
           i Rightside >TrianglePoint 3f@ glVertex3f
         0.0e   0.0e    1.0e  glNormal3f               \ The top V2
           i Top       >TrianglePoint 3f@ glVertex3f
      glEnd quad]  loop ;

cr cr .( Functions keys:)
cr .(  'DEL' To reset the offsets of all functions keys.)
cr .(  'ESC' Exit to Forth.)
cr .(  'r' Rotation with the cursor keys,PageUp < > and PageDown.)
cr .(  't' Activate moving and zooming with the cursor keys,)
cr .(      PageUp and PageDown.)
cr .(  'z' To start or stop rotation.)  cr

: set-viewpoint ( f: - eyex eyey eyez cntx cnty cntz upx upy upz )
\ eyex  eyey  eyez   centerx centery centerz   upx  upy   upz
  0.0e  0.23e 4.13e     0.0e  0.19e  3.34e     0.0e 0.0e -0.02e ;

0 value display_lst_1

: bouncing-environment ( - ) \ Needed after key-events of slow action
    display_lst_1
       if  display_lst_1 1 glDeleteLists  then
     rdistance 0.e 1e 0.25e  Mut4RotR floats! \ Tell it how to rotate
     0.4e  0.5e  9.5e  0.5e  glClearColor     \ The background
     GL_DEPTH_TEST glEnable
     GL_PROJECTION glMatrixMode
     glLoadIdentity
     47.0e 1.0e   0.01e 15.0e gluPerspective
     set-viewpoint gluLookAt      \ Set a viewpoint
     0.17e 0.17e 0.17e glscalef   \ To get 1 meter nice on screen
     0.0e 0.62e  8.210e fref3TransT floatsf@+ glTranslatef  \ Moving
     286e -100e -114e -28.5e  fref4RotR floatsf@+ glRotatef \  Z key
     GL_MODELVIEW glMatrixMode     \ Set viewing to the model matrix
     1 glGenLists to display_lst_1 \ Start a new display list
       display_lst_1  GL_COMPILE glNewList
           SquashRoomInlist TrianglesInlist
       glEndList ;

1.5e #Balls s>f f/ fconstant ColorballFactor

: .ogl_ball ( id-ball - )
     >r
     glPushMatrix  r@ 0=     \ The first ball must be blue
         if    0.e 0.e 1.0e
         else  r@ 2 max s>f ColorballFactor f* fdup .4e
         then  glColor3f
     r@ >Ball position@  glTranslatef
         GL_POLYGON glBegin
               r> >Ball fball_size f@ 16 16 sphere
         glEnd
     glPopMatrix ;

: .balls ( - ) #balls 0  do  i .ogl_ball   loop ;
: .list  ( - ) glPushMatrix display_lst_1 glCallList glPopMatrix ;
: resizing_bouncing ( - ) Init-Window false to resizing? ;

: Other-actions ( - )  \ Used for resizing and the Z key ( rotating )
     slow-action?      \ Triggered by oglevts.f in a separate thread
        if  false to slow-action?    \ Restart timer for slow actions
            roll-fref4RotR bouncing-environment           \ The Z key
        then
     resizing?                \ Controlled by On_Size msg in oglwin.f
        if  resizing_bouncing bouncing-environment
        then ;

create sound$ ," Plop.wav"
sound$ count file-status dup not value MakeSound?
[if]  .( No optional sound file used. ) cr  [then] drop

: WillBallHitTrangle? ( #triangle #ball - flag )
     swap >Triangle over >Ball 2dup BallOutsideTriangle?
        if    3drop false exit    \ No hit
        else  rot 0> #balls 21 < and MakeSound? and
                 if  sound$ 1+ start-sound  then
        then  BounceBallTrangle true ;

: MoveBalls ( - )  \ Will be started from show-frame during wait time
   #balls 0
       do  true #triangles 0
              do   i j WillBallHitTrangle?   if  invert leave  then
              loop
           if  i >Ball BounceInside  then
       loop  Other-actions ;

: ResetUserInterface ( - )
    false to slow-action?      \ Used by the 'Z' key
    false to static-scene      \ This scene changes
    false to request-to-stop ; \ Stop when ESC is pressed

: bouncing       ( - )
     ResetUserInterface bouncing-environment \ Takes much time
     begin               \ For all frames:
      clear-buffer       \ Clear the color and depth buffer
      .list .balls       \ Build the scene
      show-frame         \ Show it and wait till it's timeout expires
      request-to-stop    \ Stop when Escape has been hit
     until   false to request-to-stop ;

: Start3DBouncing  ( - )
  NormalTriangles           \ Calculate the normals for all triangles
  Start: OpenGLWindow                       \ Start the OpenGL window
  ['] bouncing-environment is painting  \ Then specify a paint action
  ResetOpenGL                       \ Cleanup from a previous drawing
  bouncing ;                                             \ This scene

: ExitBouncing ( - ) DeleteTextures ;
' ExitBouncing       is ExitScene            \ Cleanup.
' MoveBalls          is PrepareNextFrame     \ Before Start3DBouncing

needs src\lib\fmacro\profiler.f

: speed-test ( f: xPos - )
  cr ." ----Speed test----"   NormalTriangles
  0 >Ball -.3893e  2.69270e   dup position!
           .0027e  0.002700e  .0047e  >{dir} dup 3f!
     dup 1 3dDump    \ Old direction
  tsc 2>r  1 0  WillBallHitTrangle?   tsc 2>r
     swap 1 3dDump   \ New direction
  cr 2r> 2r> d- 1 ud,.r ."  CPU-cycles used for "
  not  if  ." **NOT** "  then  ." bouncing (Calculations only)." cr ;

 1.0907e speed-test   0.0907e speed-test   Start3DBouncing

\s My output for the speed-test on a I7 at 3.2 Ghz:

----Speed test----
          x         y         z
   0: .002700  .002700  .004700
          x         y         z
   0: .002700  .002700  .004700
9,036 CPU-cycles used for **NOT** bouncing (Calculations only).

----Speed test----
          x         y         z
   0: .002700  .002700  .004700
          x         y         z
   0: .002700  -.002140    -.004980
11,748 CPU-cycles used for bouncing (Calculations only).
Fps:  61  .0000e .6200e 8.210e
