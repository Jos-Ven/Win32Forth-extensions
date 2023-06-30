\ September 10th, 2001 - 11:30 by J.M.B.v.d.Ven
\ Objective: Extend Win32Forth with graphic tools.

\ April 5th, 2003 Changed color_true and color_false into variables.

 needs toolset.f

ANEW graphics.f

vocabulary graphics

: gr \in-system-ok also
     \in-system-ok graphics ;

only forth also graphics definitions

\ 0 255 0 rgb newcolor: black \ \ ( turtle ) 32000 do test

0 0 0 palettergb new-color  current-color

WinDC CurrentDC

: graphics-in-console ( - ) \ initialize DC for the console
  GetHandle: cmd CALL GetDC PutHandle: currentDC
  ;

\ ((
: test
    graphics-in-console
    255 0 do
      255 0 do
        255 0 do
          i k j rgb newcolor: current-color
          i 0 10 i + 200  current-color FillArea: currentDC
       7 +loop
    2 +loop
   loop  ;

\ test \s  8-5 ))

:inline pick-a-color       ( N -- color ) \ ( N -- rgb )
  dup 0<> if PosblColors /mod drop then PC_NOCOLLAPSE + ;

7 value colorstep
7 value rgb-to-inc

256 constant max#r#g#b
max#r#g#b cell-array #used-starting-color ( n - #used )

: +green ( colorref +green - colorref+green )     8 lshift +  ;
: +blue  ( colorref +blue  - colorref+blue )     16 lshift +  ;
synonym +red +

: random-flag ( - 1 | - -1 )
   2 random 1 =
     if    true
     else  false
     then
  ;

: -rot-drop ( n1 n2 n3 - n3 n2 )   -rot drop ;

\ : +rgb ( colorref +rgb - colorref+rgb )
\    rgb-to-inc
\        case
\           1 of +green endof
\           2 of +blue  endof
\                drop +red dup
\        endcase
\ ;

: +rgb ( colorref +rgb - colorref+rgb )
   rgb-to-inc tb 1   and if 2dup +red   -rot-drop then
   rgb-to-inc tb 10  and if 2dup +green -rot-drop then
   rgb-to-inc tb 100 and if 2dup +blue  -rot-drop then drop    ;

: incr-used-color ( n - n )
   1 over +to-cell #used-starting-color ;

\ 0 max#r#g#b ' #used-starting-color cadump  abort

: select-a-startcolor (  max-#color - #color )
   dup random swap  ['] #used-starting-color
   least-used  incr-used-color
 ;

: _random_color ( - rgb )
    max#r#g#b select-a-startcolor
    max#r#g#b select-a-startcolor
    max#r#g#b select-a-startcolor rgb  ;

0 256 0 rgb variable color_false color_false !
12709967 variable color_true color_true !
0 value color_false_bck
0 value color_true_bck


: random-color ( - )
     today 2drop random 1 max 5 * to rgb-to-inc
\    3 random  to rgb-to-inc
   _random_color  _random_color 256 random to colorstep
          random-flag
              if    color_false ! color_true !
              else  swap color_true ! color_false !
              then
 ;

0 value color
defer way-to-color
' color is way-to-color
 0 0 255  rgb to color

create &InfoRect  4 cells allot    ( - &InfoRect )
&InfoRect 4 cells erase
&InfoRect constant window_x
&InfoRect 1 cells+ constant window_y
&InfoRect 2 cells+ constant width
&InfoRect 3 cells+ constant height

: getwindow ( - hwnd x y w h )
   &InfoRect Call GetActiveWindow dup
   -rot Call GetClientRect ( GetWindowRect ) ?win-error
   window_x @ window_y @ width @ height @
 ;

\  getwindow tp abort

: GetClientRect_window  ( - )
   &InfoRect Call GetActiveWindow Call GetClientRect drop
 ;

: Xmax    ( - width )    GetClientRect_window width @ ;
: Ymax    ( - Ymax  )    GetClientRect_window height @ ;

-1 value prev-y  -1 value  prev-x
0.1e fvalue distance

\ 67108864 constant rgb-offset
16777216 constant PosblColors

: moveto        ( x y -- )
   2dup Moveto: CurrentDC  to prev-y  to prev-x pause ;

: lineto        ( x y -- )
\    way-to-color newcolor: current-color
\    current-color LineColor: CurrentDC
     way-to-color pick-a-color gethandle: CurrentDC Call SetTextColor drop
    2dup LineTo: CurrentDC to prev-y  to prev-x ;


: pixel-on      ( x y -- )
   2dup to prev-y  to prev-x swap
   way-to-color @ -rot
   GetHandle: CurrentDC Call SetPixelV drop pause
 ;

 ' color is way-to-color \ defer the color when using set-dot

defer set-dot

: dot>screen ( x y rgb -- )
   -rot swap GetHandle: CurrentDC Call SetPixelV drop ;

' dot>screen is set-dot


synonym set-mdot       set-dot

: ptest
   cls graphics-in-console
   800 0 do i 37 0 0 255 rgb set-dot loop
   650 0 do i 31 0 255 0 rgb set-dot loop
   650 0 do i 32 255 0 0  rgb set-dot loop
   650 0 do i 33 0 0 0 rgb set-dot loop
  ;
  \ ptest abort

\ pen: ltgreen dup call DeleteObject
\ Brush: ltgreen dup call DeleteObject
\ UnInitColor: ltred

0e FVALUE win.xleft
0e FVALUE win.xright
0e FVALUE win.ybot
0e FVALUE win.ytop
0e FVALUE win.xdif
0e FVALUE win.ydif


variable SXoffs
variable SXdiff
variable SYoffs
variable SYdiff

1.0e FVALUE PenX
1.0e FVALUE PenY


: SET-GWINDOW   \ <xb> <yb> <xt> <yt> --- <>  F: <xb> <yb> <xt> <yt> --- <>
                2OVER  SYoffs ! SXoffs !
                ROT  - SYdiff !                 \ hardware coordinates!
                SWAP - SXdiff !
                FTO win.ytop
                FTO win.xright
                FTO win.ybot
                FTO win.xleft
                win.xright win.xleft F- FTO win.xdif
                win.ytop  win.ybot   F- FTO win.ydif ;

: SCALE         \ F: <x> <y> --- <>  <> --- <x> <y>
                win.ybot  F-  win.ydif F/  SYdiff @ S>F F*  F>S SYoffs @ +
                win.xleft F-  win.xdif F/  SXdiff @ S>F F*  F>S SXoffs @ +
                SWAP ;

\ -- Won't plot a point that doesn't fall within the window.
: PLOT-POINT    PenX win.xleft win.xright       \ <color> --- <>
                F2DUP F> IF FSWAP ENDIF
                  FWITHIN 0= IF DROP EXIT ENDIF
                PenY win.ybot  win.ytop
                F2DUP F> IF FSWAP ENDIF
                  FWITHIN 0= IF DROP EXIT ENDIF
                PenX PenY SCALE ROT SET-DOT ;

: xypos        ( x y -- )
                 to prev-y  to prev-x ;

synonym plot lineto     synonym xyplot moveto

: -line          ( _x2 _y2 _x1 _y1 -- )
                2swap moveto lineto ;

: line          ( _x2 _y2 _x1 _y1 -- )
                2swap moveto lineto ;

: draw-mline    \ <xb> <yb> <xe> <ye> <color> --- <>
                ( to color way-to-color ) LineColor: CurrentDC line ;

create sinus
     0 ,  1745 ,  3490 ,  5234 ,  6976 ,  8716 , 10453 , 12187 , 13917 ,
 15643 , 17365 , 19081 , 20791 , 22495 , 24192 , 25882 , 27564 , 29237 ,
 30902 , 32567 , 34202 , 35837 , 37461 , 39073 , 40674 , 42262 , 43837 ,
 45399 , 46947 , 48481 , 50000 , 51504 , 52992 , 54464 , 55919 , 57358 ,
 58779 , 60182 , 61566 , 62932 , 64279 , 65606 , 66913 , 68200 , 69466 ,
 70711 , 71934 , 73135 , 74314 , 75471 , 76604 , 77715 , 78801 , 79864 ,
 80902 , 81915 , 82904 , 83867 , 84805 , 85717 , 86603 , 87462 , 88295 ,
 89101 , 89879 , 90631 , 91355 , 92050 , 92718 , 93358 , 93969 , 94552 ,
 95106 , 95630 , 96126 , 96593 , 97030 , 97437 , 97815 , 98163 , 98481 ,
 98769 , 99027 , 99255 , 99452 , 99619 , 99756 , 99863 , 99939 , 99985 ,
100000 ,

: (sinus)  4 * sinus + @ ;   ( angle - unsigned_sin*100000 )

: sin  ( angle - sin*100000 )
   dup abs dup
   360 > if  360 mod
         then dup
         91 < if (sinus)                                 \ < 90
              else dup 181 <
                   if 180 - abs (sinus)                   \ 91 - 179
                   else dup 271 <
                        if 180 - (sinus) negate            \ 180 - 269
                        else 360 - abs (sinus) negate      \ 270 - 360
                        then
                    then
                then
   swap 0< if negate
           then
 ;
\ 90 sin .s abort

\ Idea's from:
\ C.Jansen, C.v.d.Ven, R.Fransen en J.v.d.Ven.

: cos          ( angle - cos*100000 )
   90 - dup 0> >r
   abs sin r>
       if negate then
 ;

: stop-key ( - )
     key?
      if   key abort  then
 ;

: pauze     ( -- )    \ wait for a key <esc> will abort
     begin
       key?
     until key 27 =
   if cr ." Stoped !" abort then
 ;


: 0plot         ( -- )
     0 0 xyplot
  ;

0 value angle
: clear ( - ) \ puts 0 in the turtle
   0plot  0 to angle
 ;

: center
   width @ 2 / height @ 2 / xyplot 0 to angle
 ;

: turn          ( angle - )
   angle + dup 360 >=
    360 and -
    dup -360 <=
    360 and +
    to angle
 ;

: /0 ( n1 q - / )      \ avoids divide by zero
  dup 0=
        if 2drop 0 exit
        then /
 ;

: */rounded ( n1 n2 q - */rounded ) \ gives a better result
    dup 0=
        if drop 2drop 0 exit
        then
    dup >r */mod swap 10 * r> / 5 >= abs +
 ;

: (pencil        ( length -)
    dup angle cos 100000 */rounded
    prev-x + swap angle sin 100000 */rounded  prev-y + lineto
 ;

: pencil ( length -)
    way-to-color LineColor: CurrentDC
    (pencil
 ;

: slowpencil ( lengte slow - )
    way-to-color LineColor: CurrentDC
     swap 0
     do
    \ dup 0 do loop
     1 (pencil
    loop drop
 ;

: penup  ( length - )
   dup angle cos 100000 */rounded prev-x  + swap
     angle sin 100000 */rounded
     prev-x + to prev-y to prev-x
 ;

(( Disable or delete this line for the following test.

: test
  cls graphics-in-console
   0   0             MoveTo: CurrentDC
   ltblue            LineColor: CurrentDC
   40 to angle
   1000 (pencil
 ;
  test  cr .s abort ))


: InformationBox   { adr len \ message$ -- }
     MAXSTRING localAlloc: message$
      adr len message$ place
      message$ +NULL
      MB_OK  MB_ICONINFORMATION  or
      MB_TASKMODAL or
      z" Information:"
      message$ 1+
      NULL call MessageBox drop
 ;

0 value vscroll

: wcr ( x1 y1 - x2 y2 )      vscroll 7 + +  ;

: wtype  ( x y adr n - x y ) 2over 2swap textout: currentDC  ;

\ cls graphics-in-console 20 30 s"  test " wtype 2drop

\s

