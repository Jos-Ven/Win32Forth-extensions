(( *
 * LANGUAGE    : ANS Forth
 * PROJECT     : DFW Forth Environments
 * DESCRIPTION : Three Dimensional manipulation words
 * CATEGORY    : Example
 * AUTHOR      : Daniel John Lee Parnell/ Marcel Hendrix
 *
 *     Picked up from usenet and adapted to the DFW libs and extensions.
 *     There isn't much to tell. It worked first time. I was impressed by
 *     the realism.
 *
 *     I changed the drawing algorithm to plot the new cubes at the same
 *     time the old set is erased. This is _much_ nicer than how Daniel
 *     did it (a CLS in between!).
 *
 *     Some MacIntosh specials (machine code!) was removed. Of course
 *     the code is now 32-bits and uses floating-point where appropriate.
 *
 *
 * LAST CHANGE : J.M.B.v.d.Ven feb. 2, 1999, ported to Win32Forth,
 *               added move_camera. The speed is increased by swapping
 *               the buffers instead of moving them.
 *
 *               J.M.B.v.d.Ven September 10th, 2001 - 14:17
 *               Changed it for the new version of graphics.f
 *               Adapted for Win32Forth version 6.14
 * ))


 needs toolset.f
 needs graphics.f

anew 3dimcube.f

((

Commands while rotating:
     key:     action:
     K_RIGHT  left  or right
     K_LEFT   right or left
     K_UP     up    or down
     K_DOWN   down  or up
     K_PGDN   zoom in  or out
     K_PGUP   zoom out or in
     K_HOME   reset
     +        increase rotating speed
     -        decrease rotating speed
     ESCAPE   aborts

))

( *************** The 3D graphics words *************** )

0e FVALUE xa  0e FVALUE ya  0e FVALUE za        \ -- Rotation angles
0e FVALUE tx  0e FVALUE ty  0e FVALUE tz        \ -- First translation
0e FVALUE dx  0e FVALUE dy  0e FVALUE dz        \ -- Second translation

0e FVALUE cx  0e FVALUE sx                      \ -- Trig VALUEs
0e FVALUE cy  0e FVALUE sy
0e FVALUE cz  0e FVALUE sz


780e FVALUE zPull                       \ -- Constants for 2D plane projection
250e FVALUE magic

0 VALUE xCenter
0 VALUE yCenter


: sns           xa FSINCOS FTO cx FTO sx
                ya FSINCOS FTO cy FTO sy
                za FSINCOS FTO cz FTO sz ;

: rotate        FTO za  FTO ya  FTO xa ;   \ F: <xAngle> <yAngle> <zAngle> \ --- <>
: translate     FTO tz  FTO ty  FTO tx ;   \ F: <x> <y> <z> \ --- <>
: move_3d       FTO dz  FTO dy  FTO dx ;   \ F: <x> <y> <z> \ --- <>


\ -- The first translation is done before the rotation and the second is done
\ -- after it.  An eye or camera position can be implemented using move_3d
\ -- and some clever use of the rotation words.

\ -- Project point x y z onto the screen with perspective

0e FVALUE x1  0e FVALUE y1  0e FVALUE z1
0e FVALUE x2  0e FVALUE y2  0e FVALUE z2
0e FVALUE dtz 0e FVALUE dty 0e FVALUE dtx

: project                               \ <x> <y> <z> \ --- <x'> <y'>

        0e flocal x1  0e flocal y1  0e flocal z1
        0e flocal x2  0e flocal y2  0e flocal z2

        ( z ) s>f tz f+ flocal dtz      \ Add in the first translation
        ( y ) s>f ty f+ flocal dty
        ( x ) s>f tx f+ flocal dtx

        dtx cz f*  dty sz f* f-  FTO x1  \ Rotate about the Z axis
        dtx sz f*  dty cz f* f+  FTO y1

        dtz cy f*  x1  sy f* f-  FTO z1  \ Rotate about the Y axis
        dtz sy f*  x1  cy f* f+  FTO x2

        y1  cx f*  z1  sx f* f-  FTO y2  \ Rotate about the Z axis
        y1  sx f*  z1  cx f* f+  FTO z2

        dx +FTO x2                       \ Add in the second translation
        dy +FTO y2
        dz +FTO z2

        z2 zPull f- fnegate fdup        \ the perspective 2D projection
        x2 magic f* fswap f/ f>s xCenter +
        y2 magic f* fswap f/ f>s yCenter + ;


3000 =: maxStars  ( Or Numlinks, see below)

synonym array         cell-array

maxstars array xBuf     \ 2D co-ords
maxstars array yBuf

maxstars array x        \ 3D co-ords
maxstars array y
maxstars array z


\ -- Set up the stars

: makeStars
        'of xBuf maxstars xBuf erase
        'of yBuf maxstars yBuf erase
        maxStars 0 do
                      400 choose  200 - i to-cell x
                      200 choose  200 - i to-cell y
                      600 choose  200 - i to-cell z
                 loop ;

\ -- Draw the stars

: drawStars     maxStars
                0 do
                    i xBuf i yBuf 255 255 255 rgb set-mdot  \ Erase old dot
                    i x  i y  i z  project 2dup   \ Do the 3D projection
                    i to-cell yBuf i to-cell xBuf \ Store location of dot
                    0 0 255 rgb set-mdot          \ Plot new dot
\                   _random_color set-mdot
                 loop  ;


  1e FRAD FVALUE xstep          \ -- Rotation steps
  2e FRAD FVALUE ystep
-10e FRAD FVALUE zstep

14 value time-out

: move_camera   ( key - )
   case                                           \ movements:
     K_LEFT  of distance      +fto dx   endof     \ left  or right
     K_RIGHT of dx distance f- fto dx   endof     \ right or left
     K_DOWN  of dy distance f- fto dy   endof     \ up    or down
     K_UP    of distance      +fto dy   endof     \ down  or up
     K_PGDN  of dz dz fabs 0.1e f* f+ distance f+ fto dz endof \ zoom in or out
     K_PGUP  of dz dz fabs 0.1e f* f- distance f- fto dz endof \ zoom out or in
     K_HOME  of 0e 0e 0e move_3d 14 to time-out  10e fto distance endof \ reset
     ascii + of time-out dup 10 / - 1- 0 max to time-out endof  \ incr. speed
     ascii - of time-out dup 10 / + 1+ +to time-out   endof     \ decr. speed
     esc     of ." Try STARS or DEMO" abort   endof             \ aborts
      endcase
   empty_key_buf
 ;


\ -- Do the stars

\ The console will be white.

: stars         cls graphics-in-console 10e fto distance
                Xmax 2/ TO xCenter  Ymax 2/ TO yCenter
                0e 0e 0e rotate
                0e 0e 0e translate
                0e 0e 0e move_3d

                makeStars
                begin
                    xstep +FTO xa
                    ystep +FTO ya
                    zstep +FTO za
                    sns
                    drawStars
                   key? if key move_camera then
                  time-out ms
                 again ;


                ( **** Do some 3d rotating cubes **** )



0 VALUE numPoints
0 VALUE numLinks


200 array cx            \ -- Allow for 200 points
200 array cy
200 array cz

500 array p1            \ -- Allow for 500 links
500 array p2
500 array p1'
500 array p2'

maxstars array xBuff    \ -- 2D co-ords originals
maxstars array yBuff
maxstars array xBuff'   \ -- 2D co-ords backup
maxstars array yBuff'


true value swap-old-new

: backup-arrays
   swap-old-new not to swap-old-new  ;


\ -- Co-ordinates of the corners of a cube

create cdX   -100 ,  100 ,  100 , -100 , -100 ,  100 ,  100 , -100 ,
create cdY   -100 , -100 ,  100 ,  100 , -100 , -100 ,  100 ,  100 ,
create cdZ   -100 , -100 , -100 , -100 ,  100 ,  100 ,  100 ,  100 ,

\ -- Links between the different points

create pd1    0 , 1 , 2 , 3 , 4 , 5 , 6 , 7 , 0 , 1 , 2 , 3 ,
create pd2    1 , 2 , 3 , 0 , 5 , 6 , 7 , 4 , 4 , 5 , 6 , 7 ,

0 value qz  0 value qy  0 value qx  0 value temp

: makeCube ( x y z - ) ( Place a cube with sizes of 100 centered at x y z )
          local qz  local qy  local qx ( Store the displacement of the cube )
          numPoints local temp         ( Store the current number of points )
          8 0 do                       ( Add the points to make up the cube )
                i cdx []cell @  qx + numPoints to-cell cx
                i cdy []cell @  qy + numPoints to-cell cy
                i cdz []cell @  qz + numPoints to-cell cz
                numPoints MaxStars > abort" makeCube: enlarge MaxStars"
                1 +to numPoints
          loop

         12 0 do                       ( Now add in the links )
                i pd1 []cell @ temp + numLinks to-cell p1 (( numLinks ))
                i pd2 []cell @ temp + numLinks to-cell p2 (( numLinks ))
                numLinks MaxStars > abort" makeCube: enlarge MaxStars"
                1 +TO numLinks
          loop ;


\ -- Calculate the points

: calc  \ get all points, project and store it in the buffers
   numPoints 0 swap-old-new
       if
            do
               i cx  i cy  i cz  project i to-cell yBuff  i to-cell xBuff
          loop
       else
            do
               i cx  i cy  i cz  project i to-cell yBuff' i to-cell xBuff'
           loop
       then
                ;


\ -- Draw the scene in the buffer

black value color_drawIt

: drawIt        local color_drawIt                     \ <color> \ --- <>
                numLinks
                0 do
                    i p1 dup  xBuff swap yBuff ( x1 y1 )
                    i p2 dup  xBuff swap yBuff ( x2 y2 )
                    color_drawIt DRAW-MLINE
                loop
                backup-arrays ;

\ -- Draw the new scene, undraw the old one

white value color_(Un)drawIt

: (Un)drawIt     \ <color> \ --- <>
    local color_(Un)drawIt  numLinks  0 swap-old-new
            if
                  do
                     i p1 dup  xBuff  swap yBuff  ( x1 y1 ) \ new
                     i p2 dup  xBuff  swap yBuff  ( x2 y2 )
                     i p1 dup  xBuff' swap yBuff' ( x1 y1 ) \ old
                     i p2 dup  xBuff' swap yBuff' ( x2 y2 )
                     white DRAW-MLINE            \ undraw
                     black DRAW-MLINE            \ draw
                loop
            else
                  do
                     i p1 dup  xBuff' swap yBuff' ( x1 y1 )
                     i p2 dup  xBuff' swap yBuff' ( x2 y2 )
                     i p1 dup  xBuff  swap yBuff  ( x1 y1 )
                     i p2 dup  xBuff  swap yBuff  ( x2 y2 )
                     white DRAW-MLINE
                     black DRAW-MLINE
                loop
             then  backup-arrays ;

\ -- Rotate some cubes on the screen

\ The console will be white.

: demo          cls graphics-in-console 10e fto distance
                cr 10e fto distance
                0 to numPoints         \ Reset the number of points
                0 to numLinks          \ Reset the number of links
                true to swap-old-new

                0 0 0     makecube      \ Generate some cubes to look at
                400 0 0   makecube
                -400 0 0  makecube
                0 400 0   makecube
                0 -400 0  makecube
                0 0 400   makecube
                0 0 -400  makecube

                Xmax 2/ TO xCenter Ymax 2/ TO yCenter

                0e 0e 0e rotate         \ Zero everything
                0e 0e 0e translate
                0e 0e 0e move_3d

                sns                     \ Calculate a frame to fill the buffer
                calc
                black drawIt
                begin
                    xstep +FTO xa        \ Rotate the scene
                    ystep +FTO ya
                    zstep +FTO za
                    black (Un)drawIt     \ Now draw it
                    sns                 \ Start to calculate  the next frame
                    calc                \ Do the actual calculations
                   key? if key move_camera then
                  time-out ms
                 again ;

\ debug sns
 demo \s


