\ ===================================================================
\           File: opengllib-1.27.fs
\         Author: Banu Cosmin
\  Linux Version: Jeff Pound
\ gForth Version: Timothy Trussell, 06/16/2011
\    Description: Shadows
\   Forth System: gforth-0.7.0
\   Linux System: Ubuntu v10.04 LTS i386, kernel 2.6.32-32
\   C++ Compiler: gcc (Ubuntu 4.4.1-4ubuntu9) 4.4.1
\ ===================================================================
\                       NeHe Productions
\                    http://nehe.gamedev.net/
\ ===================================================================
\                   OpenGL Tutorial Lesson 27
\ ===================================================================
\ This code was created by Jeff Molofee 2000
\ Visit Jeff at http://nehe.gamedev.net/
\ March, 2013 adapted for Win32Forth by Jos v.d.Ven
\ Visit Jeff at http://nehe.gamedev.net/
\ ===================================================================

vocabulary Lesson27  also Lesson27 definitions

\ ============[ Additional Ancilliary Support Routines ]=============

\ ---[ String/Array Words ]------------------------------------------
\ s-new creates the base name, storing the element size in next cell
: s-new    ( size -- ) create , does> ;

\ s-alloc# allots/clears an array of elements; returns 1st address
: s-alloc# ( *base n -- *t ) swap @ * here dup rot dup allot 0 fill ;

\ s-ndx returns the n-th element address of an array
: s-ndx    ( *base n -- *str[n] ) over @ * CELL + + ;

\ ---[ Floating Point +!/-! ]----------------------------------------
\ Floating point versions of the integer +! function

: SF+! ( f: fval *fvar -- ) dup SF@ F+ SF! ;
: SF-! ( f: fval *fvar -- ) FNEGATE SF+! ;

\ ---[ Variable Declarations ]---------------------------------------

\ ---[ quadratic ]---
\ The usage of this variable seems to *imply* that it should be
\ passed by address, but the code does not work unless the actual
\ value is loaded - not the address.

VARIABLE quadratic                   \ Quadratic For Drawing A Sphere

FVARIABLE xrot                                           \ x rotation
FVARIABLE yrot                                           \ y rotation
FVARIABLE xspeed                                   \ x rotation speed
FVARIABLE yspeed                                   \ y rotation speed

\ Light Parameters - passed by address so they have to be 32-bit

4 s-new LightPos[]    0e0 SF,    5e0 SF,   -4e0 SF, 1e0 SF,     \ Pos
4 s-new LightAmb[]  0.2e0 SF,  0.2e0 SF,  0.2e0 SF, 1e0 SF, \ Ambient
4 s-new LightDif[]  0.6e0 SF,  0.6e0 SF,  0.6e0 SF, 1e0 SF, \ Diffuse
4 s-new LightSpc[] -0.2e0 SF, -0.2e0 SF, -0.2e0 SF, 1e0 SF, \ Speclar

\ Material Light Parameters
4 s-new MatAmb[] 0.4e0 SF, 0.4e0 SF, 0.4e0 SF, 1e0 SF,      \ Ambient
4 s-new MatDif[] 0.2e0 SF, 0.6e0 SF, 0.9e0 SF, 1e0 SF,      \ Diffuse
4 s-new MatSpc[] 0e0 SF, 0e0 SF, 0e0 SF, 1e0 SF,           \ Specular
4 s-new MatShn[] 0e0 SF,                                  \ Shininess

\ Passed by value, so can be 64-bit
B/FLOAT s-new ObjPos[]    -2e0 F, -2e0 F, -5e0 F,     \ Object Position
B/FLOAT s-new SpherePos[] -4e0 F, -5e0 F, -6e0 F,     \ Sphere Position


struct{                               \ vertex in 3d-coordinate system
  b/float .sp-x
  b/float .sp-y
  b/float .sp-z
}struct sPoint%
sizeof sPoint% constant /sPoint%  \ 24 ok

struct{                                               \ plane equation
  b/float .eq-a
  b/float .eq-b
  b/float .eq-c
  b/float .eq-d
}struct sPlaneEq%
sizeof sPlaneEq% constant /sPlaneEq%  \ 32 ok

\ structure describing an object's face

\ The original structure

\ struct
\   cell%   3 * field .p[]                         \ array of 3 cells
\   sPoint% 3 * field .normals[]         \ array of 3 sPoint elements
\   cell%   3 * field .neigh[]                     \ array of 3 cells
\   sPlaneEq%   field .planeeq                     \ sPlaneEq element
\   cell%       field .visible                              \ boolean
\ end-struct sPlane%

\ Implementing the String/Array constructs to make indexing simple
\ Note: There is a small difference between gForth 0.6.2 and Win32Forth

struct{                                                        \ GF W32
  cell      .p                    \ size of the .p[] elements  \ 0  0
  offset    .p[]                           \ array of 3 cells  \ 4  4
        3 cells  _add-struct                                   \
  cell      .normals            \ size of the normal elements  \ 16 16
  \ cell      1noop            \  For GF
  offset    .normals[]           \ array of 3 sPoint elements  \ 24 20 *
        /sPoint% 3 * _add-struct                               \
  cell      .neigh               \ size of the neigh elements  \ 96 92
  offset    .neigh[]                       \ array of 3 cells  \ 100 96
        3 cells     _add-struct                                \
  offset    .planeeq                       \ sPlaneEq element  \ 112 108
        /sPlaneEq%  _add-struct                                \
  cell      .visible                                \ boolean  \ 144 140
 \ cell      2noop            \   For gF
}struct sPlane%
sizeof sPlane% constant /sPlane%                               \ 152 144 *


\ object structure

struct{                                                            \ GF W32
  cell    .npoints               \ Number of points in the object  \ 0  0
  cell    .nplanes               \ Number of planes in the object  \ 4  4
  cell    .points                     \ String/Array element size  \ 8  8
 \  cell      3noop            \   For GF
  offset  .points[]                 \ Start a 100 element array    \ 16 12 *
        /sPoint% 100 * _add-struct  \ Addd the 100 element array to the size 2400
  cell    .planes                     \ String/Array element size  \ 2416  2412
  offset  .planes[]                 \ Start a 100 element array    \ 2424  2416
        /sPlane% 100 *  _add-struct \ Addd the 100 element array to the size 14400
 \  cell      4noop            \   For gF
}struct glObject%                            \ size is 17624 bytes
sizeof glObject% constant /glObject%  \ No noops 16816 ? with 4noops OK  \ 17624 1716 *

/glObject% mkstruct:  obj                   \ define/allocate object

\ ---[ obj-point-ndx ]-----------------------------------------------
\ Returns the address of the nth .point[] element in the *obj struct
\ *obj is a pointer to a glObject% structure

: obj-point-ndx { *obj _ndx -- *obj[ndx] } *obj .points _ndx s-ndx ;

\ ---[ obj-plane-ndx ]-----------------------------------------------
\ Returns the address of the nth .plane[] element in the *obj struct
\ *obj is a pointer to a glObject% structure

: obj-plane-ndx { *obj _ndx -- *obj[ndx] } *obj .planes _ndx s-ndx ;

\ ---[ Variables Initializations ]-----------------------------------

 1e0 xrot F!
 1e0 yrot F!
 1e0 xspeed F!
 1e0 yspeed F!

obj /glObject%  0 fill                 \ zero the object data space
/sPoint%  obj .points !             \ set String/Array element size
/sPlane%  obj .planes !             \ set String/Array element size

marker ---set-data---

\ --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
\            This section replaces the ReadObject function
\ --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
\ To choose the object you wish to implement, set the correct VALUE
\ to 1, leaving the others at 0.
\ --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
\ Homework:
\    Modify the code to switch between the different objects:
\       > using a timer
\       > using keypresses (ie, '1', '2', '3' and '4'
\       > add an object for each image
\       > add a pointer to the set-points/set-planes functions
\ --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

1 =: SimpleObject                                        \ 2-d square
1 =: Object0                                               \ 3-d cube
1 =: Object1                                          \ 3-d plus sign
1 =: Object2                              \ DEFAULT: 3-d jumping jack

\ Copy the data to the obj .points[] array

: set-points ( f: x f: y f: z ndx -- )
  obj swap obj-point-ndx >R
  R@ .sp-z F!
  R@ .sp-y F!
  R> .sp-x F!
;

\ Copy the data to the obj .planes[] array

0 value _p0 \ 12 locals is the maximum in Win32Forth version 6.14.*

: set-planes ( p0 p1 p2 n0 .. n8 ndx -- )
  { _p1 _p2 _n0 _n1 _n2 _n3 _n4 _n5 _n6 _n7 _n8 _ndx -- }
  to _p0
  obj _ndx obj-plane-ndx >R
  CELL R@ .p !                            \ set size of .p[] elements
  CELL R@ .neigh !                    \ set size of .neigh[] elements
  /sPoint%  R@ .normals !         \ set size of .normals[] elements
                             \ -- for the String/Array s-ndx function
  \ change the .p values to 0-based numbering by subtracting 1
  _p0 1- R@ .p 0 s-ndx !                                  \ set .p[0]
  _p1 1- R@ .p 1 s-ndx !                                  \ set .p[1]
  _p2 1- R@ .p 2 s-ndx !                                  \ set .p[2]

  R@ .normals 0 s-ndx                        \ address of .normals[0]
  _n0 S>F dup .sp-x F!
  _n1 S>F dup .sp-y F!
  _n2 S>F     .sp-z F!

  R@ .normals 1 s-ndx                        \ address of .normals[1]
  _n3 S>F dup .sp-x F!
  _n4 S>F dup .sp-y F!
  _n5 S>F     .sp-z F!

  R> .normals 2 s-ndx                        \ address of .normals[2]
  _n6 S>F dup .sp-x F!
  _n7 S>F dup .sp-y F!
  _n8 S>F     .sp-z F!
;

SimpleObject [IF]
4 obj .npoints !
-1e0  1e0 -1e0 0 set-points
 1e0  1e0 -1e0 1 set-points
 1e0  1e0  1e0 2 set-points
-1e0  1e0  1e0 3 set-points

2 obj .nplanes !
 1  4  3   0 0 0 0 0 0 0 0 0   0 set-planes
 1  3  2   0 0 0 0 0 0 0 0 0   1 set-planes
[THEN]

Object0 [IF]
8 obj .npoints !
-1e0  1e0 -1e0 0 set-points
 1e0  1e0 -1e0 1 set-points
 1e0  1e0  1e0 2 set-points
-1e0  1e0  1e0 3 set-points
-1e0 -1e0 -1e0 4 set-points
 1e0 -1e0 -1e0 5 set-points
 1e0 -1e0  1e0 6 set-points
-1e0 -1e0  1e0 7 set-points

12 obj .nplanes !
 1  3  2    0  1  0  0  1  0  0  1  0    0 set-planes
 1  4  3    0  1  0  0  1  0  0  1  0    1 set-planes
 5  6  7    0 -1  0  0 -1  0  0 -1  0    2 set-planes
 5  7  8    0 -1  0  0 -1  0  0 -1  0    3 set-planes
 5  4  1   -1  0  0 -1  0  0 -1  0  0    4 set-planes
 5  8  4   -1  0  0 -1  0  0 -1  0  0    5 set-planes
 3  6  2    1  0  0  1  0  0  1  0  0    6 set-planes
 3  7  6    1  0  0  1  0  0  1  0  0    7 set-planes
 5  1  2    0  0 -1  0  0 -1  0  0 -1    8 set-planes
 5  2  6    0  0 -1  0  0 -1  0  0 -1    9 set-planes
 3  4  8    0  0  1  0  0  1  0  0  1   10 set-planes
 3  8  7    0  0  1  0  0  1  0  0  1   11 set-planes
[THEN]

Object1 [IF]
16 obj .npoints !
-2e0  0.2e0 -0.2e0  0 set-points
 2e0  0.2e0 -0.2e0  1 set-points
 2e0  0.2e0  0.2e0  2 set-points
-2e0  0.2e0  0.2e0  3 set-points
-2e0 -0.2e0 -0.2e0  4 set-points
 2e0 -0.2e0 -0.2e0  5 set-points
 2e0 -0.2e0  0.2e0  6 set-points
-2e0 -0.2e0  0.2e0  7 set-points

-0.2e0  2e0 -0.2e0  8 set-points
 0.2e0  2e0 -0.2e0  9 set-points
 0.2e0  2e0  0.2e0 10 set-points
-0.2e0  2e0  0.2e0 11 set-points
-0.2e0 -2e0 -0.2e0 12 set-points
 0.2e0 -2e0 -0.2e0 13 set-points
 0.2e0 -2e0  0.2e0 14 set-points
-0.2e0 -2e0  0.2e0 15 set-points

 24 obj .nplanes !
 1  3  2    0  1  0  0  1  0  0  1  0    0 set-planes
 1  4  3    0  1  0  0  1  0  0  1  0    1 set-planes
 5  6  7    0 -1  0  0 -1  0  0 -1  0    2 set-planes
 5  7  8    0 -1  0  0 -1  0  0 -1  0    3 set-planes
 5  4  1   -1  0  0 -1  0  0 -1  0  0    4 set-planes
 5  8  4   -1  0  0 -1  0  0 -1  0  0    5 set-planes
 3  6  2    1  0  0  1  0  0  1  0  0    6 set-planes
 3  7  6    1  0  0  1  0  0  1  0  0    7 set-planes
 5  1  2    0  0 -1  0  0 -1  0  0 -1    8 set-planes
 5  2  6    0  0 -1  0  0 -1  0  0 -1    9 set-planes
 3  4  8    0  0  1  0  0  1  0  0  1   10 set-planes
 3  8  7    0  0  1  0  0  1  0  0  1   11 set-planes

 9 11 10    0  1  0  0  1  0  0  1  0   12 set-planes
 9 12 11    0  1  0  0  1  0  0  1  0   13 set-planes
13 14 15    0 -1  0  0 -1  0  0 -1  0   14 set-planes
13 15 16    0 -1  0  0 -1  0  0 -1  0   15 set-planes
13 12  9   -1  0  0 -1  0  0 -1  0  0   16 set-planes
13 16 12   -1  0  0 -1  0  0 -1  0  0   17 set-planes
11 14 10    1  0  0  1  0  0  1  0  0   18 set-planes
11 15 14    1  0  0  1  0  0  1  0  0   19 set-planes
13  9 10    0  0 -1  0  0 -1  0  0 -1   20 set-planes
13 10 14    0  0 -1  0  0 -1  0  0 -1   21 set-planes
11 12 16    0  0  1  0  0  1  0  0  1   22 set-planes
11 16 15    0  0  1  0  0  1  0  0  1   23 set-planes
[THEN]

Object2 [IF]
24 obj .npoints !
-2e0  0.2e0 -0.2e0    0 set-points
 2e0  0.2e0 -0.2e0    1 set-points
 2e0  0.2e0  0.2e0    2 set-points
-2e0  0.2e0  0.2e0    3 set-points

-2e0 -0.2e0 -0.2e0    4 set-points
 2e0 -0.2e0 -0.2e0    5 set-points
 2e0 -0.2e0  0.2e0    6 set-points
-2e0 -0.2e0  0.2e0    7 set-points

-0.2e0  2e0 -0.2e0    8 set-points
 0.2e0  2e0 -0.2e0    9 set-points
 0.2e0  2e0  0.2e0   10 set-points
-0.2e0  2e0  0.2e0   11 set-points

-0.2e0 -2e0 -0.2e0   12 set-points
 0.2e0 -2e0 -0.2e0   13 set-points
 0.2e0 -2e0  0.2e0   14 set-points
-0.2e0 -2e0  0.2e0   15 set-points

-0.2e0  0.2e0 -2e0   16 set-points
 0.2e0  0.2e0 -2e0   17 set-points
 0.2e0  0.2e0  2e0   18 set-points
-0.2e0  0.2e0  2e0   19 set-points

-0.2e0 -0.2e0 -2e0   20 set-points
 0.2e0 -0.2e0 -2e0   21 set-points
 0.2e0 -0.2e0  2e0   22 set-points
-0.2e0 -0.2e0  2e0   23 set-points

36 obj .nplanes !
 1  3  2    0  1  0  0  1  0  0  1  0    0 set-planes
 1  4  3    0  1  0  0  1  0  0  1  0    1 set-planes
 5  6  7    0 -1  0  0 -1  0  0 -1  0    2 set-planes
 5  7  8    0 -1  0  0 -1  0  0 -1  0    3 set-planes
 5  4  1   -1  0  0 -1  0  0 -1  0  0    4 set-planes
 5  8  4   -1  0  0 -1  0  0 -1  0  0    5 set-planes
 3  6  2    1  0  0  1  0  0  1  0  0    6 set-planes
 3  7  6    1  0  0  1  0  0  1  0  0    7 set-planes
 5  1  2    0  0 -1  0  0 -1  0  0 -1    8 set-planes
 5  2  6    0  0 -1  0  0 -1  0  0 -1    9 set-planes
 3  4  8    0  0  1  0  0  1  0  0  1   10 set-planes
 3  8  7    0  0  1  0  0  1  0  0  1   11 set-planes

 9 11 10    0  1  0  0  1  0  0  1  0   12 set-planes
 9 12 11    0  1  0  0  1  0  0  1  0   13 set-planes
13 14 15    0 -1  0  0 -1  0  0 -1  0   14 set-planes
13 15 16    0 -1  0  0 -1  0  0 -1  0   15 set-planes
13 12  9   -1  0  0 -1  0  0 -1  0  0   16 set-planes
13 16 12   -1  0  0 -1  0  0 -1  0  0   17 set-planes
11 14 10    1  0  0  1  0  0  1  0  0   18 set-planes
11 15 14    1  0  0  1  0  0  1  0  0   19 set-planes
13  9 10    0  0 -1  0  0 -1  0  0 -1   20 set-planes
13 10 14    0  0 -1  0  0 -1  0  0 -1   21 set-planes
11 12 16    0  0  1  0  0  1  0  0  1   22 set-planes
11 16 15    0  0  1  0  0  1  0  0  1   23 set-planes

17 19 18    0  1  0  0  1  0  0  1  0   24 set-planes
17 20 19    0  1  0  0  1  0  0  1  0   25 set-planes
21 22 23    0 -1  0  0 -1  0  0 -1  0   26 set-planes
21 23 24    0 -1  0  0 -1  0  0 -1  0   27 set-planes
21 20 17   -1  0  0 -1  0  0 -1  0  0   28 set-planes
21 24 20   -1  0  0 -1  0  0 -1  0  0   29 set-planes
19 22 18    1  0  0  1  0  0  1  0  0   30 set-planes
19 23 22    1  0  0  1  0  0  1  0  0   31 set-planes
21 17 18    0  0 -1  0  0 -1  0  0 -1   32 set-planes
21 18 22    0  0 -1  0  0 -1  0  0 -1   33 set-planes
19 20 24    0  0  1  0  0  1  0  0  1   34 set-planes
19 24 23    0  0  1  0  0  1  0  0  1   35 set-planes
[THEN]

---set-data---

\ ==========================[ C  O  D  E ]===========================

\ ---[ SetConnectivity ]---------------------------------------------
\ connectivity procedure - based on Gamasutra's article
\ hard to explain here

0 VALUE .p1i    \ p1i
0 VALUE .p1j    \ p1j
0 VALUE .p2i    \ p2i
0 VALUE .p2j    \ p2j
0 VALUE .q1i    \ P1i
0 VALUE .q1j    \ P1j
0 VALUE .q2i    \ P2i
0 VALUE .q2j    \ P2j
0 VALUE .i
0 VALUE .j
0 VALUE .ki
0 VALUE .kj

: SetConnectivity { *obj -- }
  *obj .nplanes @ 1- 0 do
    i to .i                                         \ for readability
    *obj .nplanes @ .i 1+ do
      i to .j                                       \ for readability
      3 0 do
        i to .ki                                    \ for readability
        *obj .planes .i s-ndx .neigh .ki s-ndx @ 0= if
          3 0 do
            i to .kj                                \ for readability
            .ki to .p1i
            .kj to .p1j
            .ki 1+ 3 MOD to .p2i
            .kj 1+ 3 MOD to .p2j

            *obj .planes .i s-ndx .p .p1i s-ndx @ to .p1i
            *obj .planes .i s-ndx .p .p2i s-ndx @ to .p2i
            *obj .planes .j s-ndx .p .p1j s-ndx @ to .p1j
            *obj .planes .j s-ndx .p .p2j s-ndx @ to .p2j

            .p1i .p2i + .p1i .p2i - ABS 2DUP - 2/ to .q1i
                                             + 2/ to .q2i
            .p1j .p2j + .p1j .p2j - ABS 2DUP - 2/ to .q1j
                                             + 2/ to .q2j

            .q1i .q1j = .q2i .q2j = AND if      \ are they neighbors?
              .j 1+ *obj .planes .i s-ndx .neigh .ki s-ndx !
              .i 1+ *obj .planes .j s-ndx .neigh .kj s-ndx !
            then
          loop
        then
      loop
    loop
  loop
;

\ ---[ CalcPlane ]---------------------------------------------------
\ function for computing a plane equation given 3 points

/sPoint%  s-new v[] v[] 4 s-alloc# drop

: CalcPlane ( *obj *plane -- )
  0 0 { *obj *plane _vt _ot -- }             \ create local variables
  3 0 do
    *obj .points *plane .p i s-ndx @ s-ndx to _ot  \ calc source addr
    v[] i 1+ s-ndx to _vt                            \ calc dest addr
    _ot .sp-x F@ _vt .sp-x F!
    _ot .sp-y F@ _vt .sp-y F!
    _ot .sp-z F@ _vt .sp-z F!
  loop

  \ Calculate the <a> equation
  v[] 1 s-ndx .sp-y F@
  v[] 2 s-ndx .sp-z F@ v[] 3 s-ndx .sp-z F@ F- F*
  v[] 2 s-ndx .sp-y F@
  v[] 3 s-ndx .sp-z F@ v[] 1 s-ndx .sp-z F@ F- F* F+
  v[] 3 s-ndx .sp-y F@
  v[] 1 s-ndx .sp-z F@ v[] 2 s-ndx .sp-z F@ F- F* F+
  *plane .planeeq .eq-a F!

  \ Calculate the <b> equation
  v[] 1 s-ndx .sp-z F@
  v[] 2 s-ndx .sp-x F@ v[] 3 s-ndx .sp-x F@ F- F*
  v[] 2 s-ndx .sp-z F@
  v[] 3 s-ndx .sp-x F@ v[] 1 s-ndx .sp-x F@ F- F* F+
  v[] 3 s-ndx .sp-z F@
  v[] 1 s-ndx .sp-x F@ v[] 2 s-ndx .sp-x F@ F- F* F+
  *plane .planeeq .eq-b F!

  \ Calculate the <c> equation
  v[] 1 s-ndx .sp-x F@
  v[] 2 s-ndx .sp-y F@ v[] 3 s-ndx .sp-y F@ F- F*
  v[] 2 s-ndx .sp-x F@
  v[] 3 s-ndx .sp-y F@ v[] 1 s-ndx .sp-y F@ F- F* F+
  v[] 3 s-ndx .sp-x F@
  v[] 1 s-ndx .sp-y F@ v[] 2 s-ndx .sp-y F@ F- F* F+
  *plane .planeeq .eq-c F!

  \ Calculate the <d> equation - more complex
  v[] 1 s-ndx .sp-x F@
  v[] 2 s-ndx .sp-y F@ v[] 3 s-ndx .sp-z F@ F*
  v[] 3 s-ndx .sp-y F@ v[] 2 s-ndx .sp-z F@ F* F- F*

  v[] 2 s-ndx .sp-x F@
  v[] 3 s-ndx .sp-y F@ v[] 1 s-ndx .sp-z F@ F*
  v[] 1 s-ndx .sp-y F@ v[] 3 s-ndx .sp-z F@ F* F- F* F+

  v[] 3 s-ndx .sp-x F@
  v[] 1 s-ndx .sp-y F@ v[] 2 s-ndx .sp-z F@ F*
  v[] 2 s-ndx .sp-y F@ v[] 1 s-ndx .sp-z F@ F* F- F* F+

  FNEGATE *plane .planeeq .eq-d F!
;

\ ---[ CastShadow ]--------------------------------------------------

\ *lp is a pointer to a GLvector4f type construct, which is a user
\ defined data type array of four floating point values.

/sPoint% mkstruct: v1
/sPoint% mkstruct: v2

FVARIABLE f-side

: CastShadow ( *obj *lp -- )
  0 0 0 0 { *obj *lp _p1 _p2 _k _jj -- }
  \ set visual parameter
  *obj .nplanes @ 0 do
    *obj .planes i s-ndx .planeeq >R
    R@ .eq-a F@ *lp 0 s-ndx F@ F*
    R@ .eq-b F@ *lp 1 s-ndx F@ F* F+
    R@ .eq-c F@ *lp 2 s-ndx F@ F* F+
    R> .eq-d F@ *lp 3 s-ndx F@ F* F+ f-side F!

    f-side F@ F0> if 1 else 0 then *obj .planes i s-ndx .visible !
  loop

  GL_LIGHTING gl-disable
  GL_FALSE gl-depth-mask
  GL_LEQUAL gl-depth-func
  GL_STENCIL_TEST gl-enable
  0 0 0 0 gl-color-mask
  GL_ALWAYS 1 $0FFFFFFFF gl-stencil-func

  \ first pass, stencil operation decreases stencil value

  GL_CCW gl-front-face
  GL_KEEP GL_KEEP GL_INCR gl-stencil-op
  *obj .nplanes @ 0 do
    *obj .planes i s-ndx .visible @ if
      3 0 do
        *obj .planes j s-ndx .neigh i s-ndx @ to _k
        _k 0<> *obj .planes _k 1- s-ndx .visible @ OR if
          \ here we have an edge; draw a polygon
          *obj .planes j s-ndx .p i s-ndx @ to _p1
          i 1+ 3 MOD to _jj
          *obj .planes j s-ndx .p _jj s-ndx @ to _p2
          \ calculate the length of the vector
          *obj .points _p1 s-ndx >R
          R@ .sp-x F@ *lp 0 s-ndx F@ F- 100e0 F* v1 .sp-x F!
          R@ .sp-y F@ *lp 1 s-ndx F@ F- 100e0 F* v1 .sp-y F!
          R> .sp-z F@ *lp 2 s-ndx F@ F- 100e0 F* v1 .sp-z F!
          *obj .points _p2 s-ndx >R
          R@ .sp-x F@ *lp 0 s-ndx F@ F- 100e0 F* v2 .sp-x F!
          R@ .sp-y F@ *lp 1 s-ndx F@ F- 100e0 F* v2 .sp-y F!
          R> .sp-z F@ *lp 2 s-ndx F@ F- 100e0 F* v2 .sp-z F!

          \ draw the polygon
          GL_TRIANGLE_STRIP gl-begin
            *obj .points _p1 s-ndx >R
            R@ .sp-x F@ R@ .sp-y F@ R@ .sp-z F@ gl-vertex-3f
            R@ .sp-x F@ v1 .sp-x F@ F+
            R@ .sp-y F@ v1 .sp-y F@ F+
            R> .sp-z F@ v1 .sp-z F@ F+ gl-vertex-3f
            *obj .points _p2 s-ndx >R
            R@ .sp-x F@ R@ .sp-y F@ R@ .sp-z F@ gl-vertex-3f
            R@ .sp-x F@ v2 .sp-x F@ F+
            R@ .sp-y F@ v2 .sp-y F@ F+
            R> .sp-z F@ v2 .sp-z F@ F+ gl-vertex-3f
          gl-end
        then
      loop
    then
  loop

  \ second pass, stencil operation increases stencil value

  GL_CW gl-front-face
  GL_KEEP GL_KEEP GL_DECR gl-stencil-op
  *obj .nplanes @ 0 do
    *obj .planes i s-ndx .visible @ if
      3 0 do
        *obj .planes j s-ndx .neigh i s-ndx @ to _k
        _k 0<> *obj .planes _k 1- s-ndx .visible @ OR if
          \ here we have an edge; draw a polygon
          *obj .planes j s-ndx .p i s-ndx @ to _p1
          i 1+ 3 MOD to _jj
          *obj .planes j s-ndx .p _jj s-ndx @ to _p2
          \ calculate the length of the vector
          *obj .points _p1 s-ndx >R
          R@ .sp-x F@ *lp 0 s-ndx F@ F- 100e0 F* v1 .sp-x F!
          R@ .sp-y F@ *lp 1 s-ndx F@ F- 100e0 F* v1 .sp-y F!
          R> .sp-z F@ *lp 2 s-ndx F@ F- 100e0 F* v1 .sp-z F!
          *obj .points _p2 s-ndx >R
          R@ .sp-x F@ *lp 0 s-ndx F@ F- 100e0 F* v2 .sp-x F!
          R@ .sp-y F@ *lp 1 s-ndx F@ F- 100e0 F* v2 .sp-y F!
          R> .sp-z F@ *lp 2 s-ndx F@ F- 100e0 F* v2 .sp-z F!
          \ draw the polygon
          GL_TRIANGLE_STRIP gl-begin
            *obj .points _p1 s-ndx >R
            R@ .sp-x F@ R@ .sp-y F@ R@ .sp-z F@ gl-vertex-3f
            R@ .sp-x F@ v1 .sp-x F@ F+
            R@ .sp-y F@ v1 .sp-y F@ F+
            R> .sp-z F@ v1 .sp-z F@ F+ gl-vertex-3f
            *obj .points _p2 s-ndx >R
            R@ .sp-x F@ R@ .sp-y F@ R@ .sp-z F@ gl-vertex-3f
            R@ .sp-x F@ v2 .sp-x F@ F+
            R@ .sp-y F@ v2 .sp-y F@ F+
            R> .sp-z F@ v2 .sp-z F@ F+ gl-vertex-3f
          gl-end
        then
      loop
    then
  loop

  GL_CCW gl-front-face
  1 1 1 1 gl-color-mask

  \ draw a shadowing rectangle covering the entire screen

  0e0 0e0 0e0 0.4e0 gl-color-4f
  GL_BLEND gl-enable
  GL_SRC_ALPHA GL_ONE_MINUS_SRC_ALPHA gl-blend-func
  GL_NOTEQUAL 0 $0FFFFFFFF gl-stencil-func
  GL_KEEP GL_KEEP GL_KEEP gl-stencil-op
  gl-push-matrix
    gl-load-identity
    GL_TRIANGLE_STRIP gl-begin
      -0.1e0  0.1e0 -0.1e0 gl-vertex-3f
      -0.1e0 -0.1e0 -0.1e0 gl-vertex-3f
       0.1e0  0.1e0 -0.1e0 gl-vertex-3f
       0.1e0 -0.1e0 -0.1e0 gl-vertex-3f
    gl-end
  gl-pop-matrix
  GL_BLEND gl-disable
  GL_LEQUAL gl-depth-func
  GL_TRUE gl-depth-mask
  GL_LIGHTING gl-enable
  GL_STENCIL_TEST gl-disable
  GL_SMOOTH gl-shade-model
;

\ ---[ VMatMult ]----------------------------------------------------
\ Matrix Multiplication function
\ *m and *v are pointers to String/Array constructs
\   -- *m is an array of 16 32-bit floating point values (SFLOATs)
\   -- *v is an array of 4  64-bit floating point values

: VMatMult { *m *v -- }
  *m  0 s-ndx SF@ *v 0 s-ndx F@ F*
  *m  4 s-ndx SF@ *v 1 s-ndx F@ F* F+
  *m  8 s-ndx SF@ *v 2 s-ndx F@ F* F+
  *m 12 s-ndx SF@ *v 3 s-ndx F@ F* F+             \ leave on fp stack

  *m  1 s-ndx SF@ *v 0 s-ndx F@ F*
  *m  5 s-ndx SF@ *v 1 s-ndx F@ F* F+
  *m  9 s-ndx SF@ *v 2 s-ndx F@ F* F+
  *m 13 s-ndx SF@ *v 3 s-ndx F@ F* F+             \ leave on fp stack

  *m  2 s-ndx SF@ *v 0 s-ndx F@ F*
  *m  6 s-ndx SF@ *v 1 s-ndx F@ F* F+
  *m 10 s-ndx SF@ *v 2 s-ndx F@ F* F+
  *m 14 s-ndx SF@ *v 3 s-ndx F@ F* F+             \ leave on fp stack

  *m  3 s-ndx SF@ *v 0 s-ndx F@ F*
  *m  7 s-ndx SF@ *v 1 s-ndx F@ F* F+
  *m 11 s-ndx SF@ *v 2 s-ndx F@ F* F+
  *m 15 s-ndx SF@ *v 3 s-ndx F@ F* F+             \ leave on fp stack

  *v 3 s-ndx F!                                 \ store results at *v
  *v 2 s-ndx F!
  *v 1 s-ndx F!
  *v 0 s-ndx F!
;


\ ---[ HandleKeyPress ]----------------------------------------------
:long$ h27$
$| About lesson 27:
$| Key-list for the available functions in this lesson:
$| ESC      exits the lesson
$| w        toggles between fullscreen and windowed modes
$| jlik     adjust x,y position of the light
$| ou       adjust z position of the light
$| sfed     adjust x,y position of the ball
$| xc       adjust z position of the ball
$|      Arrow keys
$| Up       decrease x-speed
$| Down     increase x-speed
$| Left     decrease y-speed
$| Right    increase y-speed
$|      Numeric Keypad
$| 2468     adjust x,y position of the object
$| 71       adjust z position of the object
$|
$| Tip: Try also to move the light just before the ball
$|      by using the keys 'kjuol'.
  ;long$


\ Multiple keypresses at one time are not supported in Win32Forth.

: HandleKeyPress ( &event -- )
  case
  \  SDLK_ESCAPE   of TRUE to opengl-exit-flag endof
    ascii W      of  start/end-fullscreen           endof
    VK_UP        of 0.05e0 xspeed F-! 		    endof \ -xspeed
    VK_DOWN      of 0.05e0 xspeed F+! 		    endof \ +xspeed
    VK_LEFT      of 0.05e0 yspeed F-! 		    endof \ -yspeed
    VK_RIGHT     of 0.05e0 yspeed F+! 		    endof \ +yspeed
    ascii S      of 0.05e0 SpherePos[] 0 s-ndx F-!  endof
    ascii F      of 0.05e0 SpherePos[] 0 s-ndx F+!  endof
    ascii D      of 0.05e0 SpherePos[] 1 s-ndx F-!  endof
    ascii E      of 0.05e0 SpherePos[] 1 s-ndx F+!  endof
    ascii C      of 0.05e0 SpherePos[] 2 s-ndx F-!  endof
    ascii X      of 0.05e0 SpherePos[] 2 s-ndx F+!  endof
    ascii J      of 0.05e0 LightPos[]  0 s-ndx SF-! endof
    ascii L      of 0.05e0 LightPos[]  0 s-ndx SF+! endof
    ascii K      of 0.05e0 LightPos[]  1 s-ndx SF-! endof
    ascii I      of 0.05e0 LightPos[]  1 s-ndx SF+! endof
    ascii U      of 0.05e0 LightPos[]  2 s-ndx SF-! endof
    ascii O      of 0.05e0 LightPos[]  2 s-ndx SF+! endof
    VK_NUMPAD4   of 0.05e0 ObjPos[]    0 s-ndx F-!  endof
    VK_NUMPAD6   of 0.05e0 ObjPos[]    0 s-ndx F+!  endof
    VK_NUMPAD1   of 0.05e0 ObjPos[]    1 s-ndx F-!  endof
    VK_NUMPAD7   of 0.05e0 ObjPos[]    1 s-ndx F+!  endof
    VK_NUMPAD8   of 0.05e0 ObjPos[]    2 s-ndx F-!  endof
    VK_NUMPAD2   of 0.05e0 ObjPos[]    2 s-ndx F+!  endof
        h27$ ShowHelp            \ Show the help text for this lesson
  endcase
;

\ ---[ InitGL ]------------------------------------------------------
\ general OpenGL initialization function

: InitGL ( -- boolean )
  \ Data has already been loaded in the <obj> structure
  obj SetConnectivity                 \ Set Face To Face Connectivity
  obj .nplanes @ 0 do         \ compute plane equations for all faces
    obj dup .planes i s-ndx CalcPlane
  loop
  GL_SMOOTH gl-shade-model              \ Enable smooth color shading
  0e0 0e0 0e0 0.5e0 gl-clear-color         \ Set the background color
  1e0 gl-clear-depth           \ Enables clearing of the depth buffer
  0 gl-clear-stencil                  \ clear the stencil buffer to 0
  GL_DEPTH_TEST gl-enable                     \ Enables depth testing
  GL_LEQUAL gl-depth-func                  \ Type of depth test to do
  GL_PERSPECTIVE_CORRECTION_HINT GL_NICEST gl-hint      \ Perspective

  GL_LIGHT1 GL_POSITION LightPos[] 0 s-ndx gl-light-fv     \ Position
  GL_LIGHT1 GL_AMBIENT  LightAmb[] 0 s-ndx gl-light-fv      \ ambient
  GL_LIGHT1 GL_DIFFUSE  LightDif[] 0 s-ndx gl-light-fv      \ diffuse
  GL_LIGHT1 GL_SPECULAR LightSpc[] 0 s-ndx gl-light-fv     \ specular
  GL_LIGHT1 gl-enable                              \ Enable Light One
  GL_LIGHTING gl-enable                             \ Enable Lighting

  GL_FRONT GL_AMBIENT   MatAmb[] 0 s-ndx gl-material-fv     \ ambient
  GL_FRONT GL_DIFFUSE   MatDif[] 0 s-ndx gl-material-fv     \ diffuse
  GL_FRONT GL_SPECULAR  MatSpc[] 0 s-ndx gl-material-fv    \ specular
  GL_FRONT GL_SHININESS MatShn[] 0 s-ndx gl-material-fv   \ shininess

  GL_BACK gl-cull-face
  GL_CULL_FACE gl-enable
  0.1e0 1e0 0.5e0 1e0 gl-clear-color

  glu-new-quadric quadratic !                \ Create a new quadratic
  quadratic @ GL_SMOOTH glu-quadric-normals \ generate smooth normals
  quadratic @ GL_FALSE glu-quadric-texture   \ disable texture coords
;


\ ---[ DrawGLObject ]------------------------------------------------
\ Procedure for drawing the object - very simple

: DrawGLObject { *obj -- }
  GL_TRIANGLES gl-begin
    *obj .nplanes @ 0 do
      3 0 do
        *obj .planes j s-ndx .normals i s-ndx
        dup .sp-x F@ dup .sp-y F@ .sp-z F@ gl-normal-3f

        *obj .points *obj .planes j s-ndx .p i s-ndx @ s-ndx
        dup .sp-x F@ dup .sp-y F@ .sp-z F@ gl-vertex-3f
      loop
    loop
  gl-end
;

\ ---[ DrawGLRoom ]--------------------------------------------------
\ Draws the environment

: DrawGLRoom ( -- )                             \ Draw The Room (Box)
  GL_QUADS gl-begin
    \ floor
    0e0 1e0 0e0 gl-normal-3f                     \ normal pointing up
    -10e0 -10e0 -20e0 gl-vertex-3f                        \ back left
    -10e0 -10e0  20e0 gl-vertex-3f                       \ front left
     10e0 -10e0  20e0 gl-vertex-3f                      \ front right
     10e0 -10e0 -20e0 gl-vertex-3f                       \ back right
    \ ceiling
    0e0 -1e0 0e0 gl-normal-3f                  \ normal pointing down
    -10e0  10e0  20e0 gl-vertex-3f                       \ front left
    -10e0  10e0 -20e0 gl-vertex-3f                        \ back left
     10e0  10e0 -20e0 gl-vertex-3f                       \ back right
     10e0  10e0  20e0 gl-vertex-3f                      \ front right
    \ front wall
    0e0 0e0 1e0 gl-normal-3f       \ normal pointing away from viewer
    -10e0  10e0 -20e0 gl-vertex-3f                         \ top left
    -10e0 -10e0 -20e0 gl-vertex-3f                      \ bottom left
     10e0 -10e0 -20e0 gl-vertex-3f                     \ bottom right
     10e0  10e0 -20e0 gl-vertex-3f                        \ top right
    \ back wall
    0e0 0e0 -1e0 gl-normal-3f        \ normal pointing towards viewer
     10e0  10e0  20e0 gl-vertex-3f                        \ top right
     10e0 -10e0  20e0 gl-vertex-3f                     \ bottom right
    -10e0 -10e0  20e0 gl-vertex-3f                      \ bottom left
    -10e0  10e0  20e0 gl-vertex-3f                         \ top left
    \ left wall
    1e0 0e0 0e0 gl-normal-3f                  \ normal pointing right
    -10e0  10e0  20e0 gl-vertex-3f                        \ top front
    -10e0 -10e0  20e0 gl-vertex-3f                     \ bottom front
    -10e0 -10e0 -20e0 gl-vertex-3f                      \ bottom back
    -10e0  10e0 -20e0 gl-vertex-3f                         \ top back
    \ right wall
    -1e0 0e0 0e0 gl-normal-3f                  \ normal pointing left
     10e0  10e0 -20e0 gl-vertex-3f                         \ top back
     10e0 -10e0 -20e0 gl-vertex-3f                      \ bottom back
     10e0 -10e0  20e0 gl-vertex-3f                     \ bottom front
     10e0  10e0  20e0 gl-vertex-3f                        \ top front
  gl-end
;

\ ---[ DrawGLScene ]-------------------------------------------------

B/FLOAT s-new lp[]        lp[]  4 s-alloc# drop            \ GLvector4f
B/FLOAT s-new wlp[]       wlp[] 4 s-alloc# drop            \ GLvector4f

\ Data in Minv[] is retrieved from the OpenGL system, so it will have
\ to be accessed as 32-bit floats.  SFLOAT is not defined in gforth,
\ but it is 4 bytes in size.

4 s-new Minv[]          Minv[] 16 s-alloc# drop         \ GLmatrix16f

: DrawGLScene ( -- )
  GL_COLOR_BUFFER_BIT
  GL_DEPTH_BUFFER_BIT OR
  GL_STENCIL_BUFFER_BIT OR gl-clear                    \ Clear screen
  gl-load-identity                                 \ Reset the matrix
  5e0 5e0 -12e0 gl-translate-f     \ zoom into screen 12 units was 20
\ 0e0 0e0 -20e0 gl-translate-f                 \ <<< original version

  GL_LIGHT1 GL_POSITION LightPos[] 0 s-ndx gl-light-fv
  SpherePos[] 0 s-ndx F@
  SpherePos[] 1 s-ndx F@
  SpherePos[] 2 s-ndx F@ gl-translate-f         \ position the sphere
  quadratic @ 1.5e0 32 16 glu-sphere                  \ draw a sphere

  \ calculate light's position relative to local coordinate system
  \ dunno if this is the best way to do it, but it actually works
  \ if u find another aproach, let me know ;)

  \ we build the inversed matrix by doing all the actions in reverse
  \ order and with reverse parameters
  \ (notice -xrot, -yrot, -ObjPos[], etc.)

  gl-load-identity                                 \ reset the matrix
  yrot F@ FNEGATE 0e0 1e0 0e0 gl-rotate-f  \ rotate by -yrot on yaxis
  xrot F@ FNEGATE 1e0 0e0 0e0 gl-rotate-f  \ rotate by -xrot on xaxis
  GL_MODELVIEW_MATRIX Minv[] 0 s-ndx gl-get-float-v   \ retrieve data
  LightPos[] 0 s-ndx SF@ lp[] 0 s-ndx F!
  LightPos[] 1 s-ndx SF@ lp[] 1 s-ndx F!
  LightPos[] 2 s-ndx SF@ lp[] 2 s-ndx F!
  LightPos[] 3 s-ndx SF@ lp[] 3 s-ndx F!
  Minv[] lp[] VMatMult                  \ return values store in lp[]
  ObjPos[] 0 s-ndx F@ FNEGATE
  ObjPos[] 1 s-ndx F@ FNEGATE
  ObjPos[] 2 s-ndx F@ FNEGATE gl-translate-f \ move negative all axes
  GL_MODELVIEW_MATRIX Minv[] 0 s-ndx gl-get-float-v   \ retrieve data
  0e0 wlp[] 0 s-ndx F!
  0e0 wlp[] 1 s-ndx F!
  0e0 wlp[] 2 s-ndx F!
  1e0 wlp[] 3 s-ndx F!
  Minv[] wlp[] VMatMult                \ return values store in wlp[]
  \ local coordinate system, in wlp array
  wlp[] 0 s-ndx F@ lp[] 0 s-ndx F+!          \ calculate the position
  wlp[] 1 s-ndx F@ lp[] 1 s-ndx F+!           \ of the light relative
  wlp[] 2 s-ndx F@ lp[] 2 s-ndx F+!             \ to the local coords

  0.7e0 0.4e0 0e0 1e0 gl-color-4f            \ set color to an orange
  gl-load-identity                       \ reset the modelview matrix
  5e0 5e0 -12e0 gl-translate-f     \ zoom into screen 12 units was 20
\ 0e0 0e0 -20e0 gl-translate-f                 \ <<< original version

  DrawGLRoom                                          \ draw the room
  ObjPos[] 0 s-ndx F@
  ObjPos[] 1 s-ndx F@
  ObjPos[] 2 s-ndx F@ gl-translate-f
  xrot F@ 1e0 0e0 0e0 gl-rotate-f
  yrot F@ 0e0 1e0 0e0 gl-rotate-f

  obj DrawGLObject                     \ draw the loaded object image
  obj lp[] CastShadow           \ cast shadow based on the silhouette

  0.7e0 0.4e0 0e0 1e0 gl-color-4f            \ set color to an orange
  GL_LIGHTING gl-disable                            \ disble lighting
  GL_FALSE gl-depth-mask                         \ disable depth mask
  lp[] 0 s-ndx F@
  lp[] 1 s-ndx F@
  lp[] 2 s-ndx F@ gl-translate-f      \ translate to light's position
  \ Notice we are still in the local coordinate system
  quadratic @ 0.2e0 16 8 glu-sphere     \ draw a little yellow sphere
  GL_LIGHTING gl-enable                             \ enable lighting
  GL_TRUE gl-depth-mask                           \ enable depth mask

  xspeed F@ xrot F+!                        \ update x rotation angle
  yspeed F@ yrot F+!                        \ update y rotation angle
  gl-flush                                    \ flush the GL pipeline

  \ Draw it to the screen
  sdl-gl-swap-buffers
;

: _ExitLesson ( -- )
  quadratic @ glu-delete-quadric            \ clean up our quadratics
  switchToDC                     \ Use a DIBsection in the new lesson
 ;

: ResetLesson  ( -- )                             \ For a clean start
    glout switchToDIB SetWhViewport            \ Using a DIBsection in this lesson
    false MenuScaleDibsection
    InitOpenGL                \ otherwise the whole scene is too dark
    InitGL                   \ Enable some features and load textures
    set-viewpoint-wf32                            \ Set the viewpoint
 ;

also Forth definitions

: DrawGLLesson27  ( -- )
   LessonChanged?
      if  false to LessonChanged?
          ['] HandleKeyPress is KeyboardAction \ Use the keystrokes for this lesson only
          ['] _ExitLesson is ExitLesson    \ Specify ExitLesson to free allocated memory
          ResetLesson
      then
   resizing?
     if  ResetLesson
     then
    DrawGLScene                \ Redraw only the changes in the lesson
   ProcesKeyAndRelease                     \ HandleKeyPress only here
 ;


 ' DrawGLLesson27 to LastLesson
[Forth]
\s
