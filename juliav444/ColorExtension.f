Anew -ColorExtension.f
needs toolset.f

67108864 constant rgb-offset
16777216 constant PosblColors

:inline pick-a-color       ( N -- color ) \ ( N -- rgb )
  dup 0<> if PosblColors /mod drop then PC_NOCOLLAPSE + ;

7 value colorstep
7 value rgb-to-inc
0 256 0 rgb variable color_false color_false !
12709967 variable color_true color_true !
256 constant max#r#g#b
max#r#g#b cell-array #used-starting-color ( n - #used )

: incr-used-color ( n - n )
   1 over +to-cell #used-starting-color ;

: select-a-startcolor (  max-#color - #color )
   dup random swap  ['] #used-starting-color
   least-used  incr-used-color
 ;

: _random_color ( - rgb )
    max#r#g#b select-a-startcolor
    max#r#g#b select-a-startcolor
    max#r#g#b select-a-startcolor rgb  ;

: random-flag ( - 1 | - -1 )
   2 random 1 =
     if    true
     else  false
     then
  ;

: random-color ( - )
     today 2drop random 1 max 5 * to rgb-to-inc
\    3 random  to rgb-to-inc
   _random_color  _random_color 256 random to colorstep
          random-flag
              if    color_false ! color_true !
              else  swap color_true ! color_false !
              then
 ;

: +green ( colorref +green - colorref+green )     8 lshift +  ;
: +blue  ( colorref +blue  - colorref+blue )     16 lshift +  ;
synonym +red +

: -rot-drop ( n1 n2 n3 - n3 n2 )   -rot drop ;

: +rgb ( colorref +rgb - colorref+rgb )
   rgb-to-inc tb 1   and if 2dup +red   -rot-drop then
   rgb-to-inc tb 10  and if 2dup +green -rot-drop then
   rgb-to-inc tb 100 and if 2dup +blue  -rot-drop then drop    ;

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

: cos          ( angle - cos*100000 )
   90 - dup 0> >r
   abs sin r>
       if negate then
 ;

0 value color

defer way-to-color
' color is way-to-color
 0 0 255  rgb to color

0.1e fvalue distance

\s
