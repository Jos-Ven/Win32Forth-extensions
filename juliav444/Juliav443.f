(( * April 11th 2012
 * DESCRIPTION : Exterior of Julia Fractal of z^2+c in binary coding
 * CATEGORY    : Graphic example
 * AUTHOR      : Marcel Hendrix   April 6, 1994, Marcel Hendrix
 * LAST CHANGES: By J.M.B.v.d.Ven June 15th, 2012
 * Adapted for the new wTask.
 * See version.txt for the history.
 *
* ))


anew Juliav443.f

iTasks FractalTask

create title$ 200 allot

defer update-title$

false value hwnd-julia
0 value NOmenu-hmnu
0 value julia-hmnu

0 value color_false_bck
0 value color_true_bck
0 value fractal-ready?

400 value BMwidth
300 value BMheight

string: BitmapName$

0 value LastKey
false value stop-drawing
defer redraw  \ Determines what is shown.

24BitsDibClass  DibFractal \ Define a dibsection that will show the fractal on screen
BmpClass BmpFractal \ Define a bmp-class that will put the fractal in a bitmap file
map-handle BmpMapHndl

0 value stop-random-julia
0 value UseOneThread-
0 value Continous-

defer MenuChecks

: OnKey ( key|code - )
   to LastKey
   #IncompleteJobs: ControllerTask
       if      winpause  exit
       then
   true to stop-drawing  true to stop-random-julia
       begin   1 ms #IncompleteJobs: ControllerTask 0=
       until
   false to stop-drawing \ false to stop-random-julia
   LastKey esc =
      if    0 to LastKey true to stop-drawing
      else  redraw
   then
 ;

: change-menu ( hmnu - )    hwnd-julia call SetMenu ?win-error ;

: retitle-julia ( - )  \ for use outside the object
    title$ 1+ hwnd-julia call SetWindowText ?win-error ;

: elapsed-time ( - )  update-title$ 2drop retitle-julia  ;

: time_in_title  ( - adr count )
         ms@ start-time -
                1000 /mod
                  60 /mod
                  60 /mod 2 .#" title$ +place s" :" title$ +place
                          2 .#" title$ +place s" :" title$ +place
                          2 .#" title$ +place s" ." title$ +place
                          3 .#" title$ +place
                          s" .  ==> Win32Forth." title$ +place
                          title$ +NULL
                          title$ count
 ;

' time_in_title is update-title$ \ ( - adr count )

defer innerloop

\ REVISION -juliaf3 "ÄÄÄ Julia Fractal z^2+c Version 1.00 ÄÄÄ"
\ Exterior of Julia Fractal described by z:=z^2+c.



    1 value xm
    1 value ym

    1 value n1
    1 value n2

    cell newuser i1
    cell newuser j1

   1e b/float newuser xx  xx f!
   1e b/float newuser yy  yy f!

\ -- parameters

  0.1e fvariable aa  aa f!
  1.0e fvariable bb  bb f!
  1.9e fvalue p1
  2.0e fvalue p2
  0 value julia-detail


:inline colorize   ( col-index -- )   i1 @ j1 @ rot  set-mdot  ;

: name-in-title ( nfa - )               count title$ place  ;
: juliado ( - julia-detail+ 0  )        julia-detail + 0 ;

1e-4 variable _1e-4   _1e-4 f!

1e2 fvariable _1e2 _1e2 f!
b/float newuser ftmp

code do_standard    ( - color )
       xx faddr@  yy faddr@
                  do  fover fsqr  fover fsqr f2dup f+
                     _1e2 faddr@ f>
                          if  frot fdup f0>
                                if i 276400 ass-lit * color_true addr@+
                                else  i 276400 ass-lit * color_false addr@+
                                then
                              frot fdrop nip fswap fdrop
                              pick-a-color leave
                          then
                     f-  aa faddr@+  xx faddr! ( x1)
                     f* f2*  bb faddr@+  ( y1)
                     xx faddr@ fswap
                  loop
         yy faddr!  xx faddr!
    next,
    end-code


: standard      ( -- )   0  30 juliado   do_standard   colorize ;

99e fvariable _99e _99e f!

code calc-anti-julia   ( - color )
                 do   xx faddr@ fsqr  yy faddr@ fsqr  f+  fdup  _99e faddr@* ftmp faddr!
                      _1e2  faddr@ f>
                              if  yy faddr@ f0>
                                   if     i color_true addr@+ 500000 ass-lit *
                                   else   i color_false addr@+ 500000 ass-lit *
                                   then  s>f ftmp faddr! leave
                               then
                      xx faddr@ fsqr  yy faddr@ fsqr f- aa faddr@+ fdup ftmp faddr!
                      xx faddr@ yy faddr@* f2*  bb faddr@+
                      yy faddr!  xx faddr!
                 loop
           ftmp faddr@ f>s color_false addr@+ 809000 ass-lit *
    next,
    end-code

: anti-julia    9 juliado    \ ( - ) is in the black part of the fractal!
             calc-anti-julia  pick-a-color colorize
  ;

code  calc_extreme ( - )
                     xx faddr@ fsqr  yy faddr@ fsqr f- aa faddr@+ fdup ftmp faddr!
                     xx faddr@ yy faddr@* f2*  bb faddr@+
                     yy  faddr!  xx faddr!
 next,
 end-code



code extreme?  ( - f )
        xx faddr@ fsqr  yy faddr@ fsqr  f+ fdup ftmp faddr! _1e2 faddr@ f>
        next,
        end-code

code color-true? ( - f )
                yy faddr@ f0>
        next,
        end-code

: extreme     \ <> --- <>  adds many colors.
               9 juliado
                  do  extreme?
                         if   color-true?
                                    if    color_true @  ftmp f@ f>s +rgb  pick-a-color
                                    else  color_false @ ftmp f@ f>s negate
                                          +rgb  pick-a-color
                                    endif colorize unloop exit
                               endif
                       calc_extreme
                  loop
       color_false @ color_true @ + ftmp f@ f>s abs 2* negate +rgb pick-a-color colorize ;



: extreme-anti    \ <> --- <>
               9 juliado
                  do  extreme?
                       if   color-true?
                               if    color_true @  ftmp f@ f>s negate +rgb pick-a-color
                               else  color_false @  ftmp f@ f>s +rgb pick-a-color
                               endif colorize unloop exit
                       endif
                  calc_extreme
                  loop
                ftmp f@ f>s color_false @ + 800000 * pick-a-color colorize ;

code calc_cameleon  ( - )
       xx faddr@  fsqr  yy faddr@  fsqr f- aa faddr@+ fdup fsin ftan f>s 9 ass-lit * ftmp addr!
       xx faddr@  yy faddr@  f* f2*  bb faddr@+
       yy faddr! xx faddr!
 next,
 end-code

: fsqr FSQRT ;

: cameleon  ( - )
               9 juliado
                   do  xx faddr@ fsqr  yy faddr@  fsqr  f+ fdup f>s sin 292 / i + ftmp !
                        1e2  f>
                             if   color-true?
                                  if    ftmp @  color_true @ + 100000 *
                                        pick-a-color
                                  else  ftmp @  color_false @ + 100000 *
                                        pick-a-color
                                  endif colorize unloop exit
                             endif
                       calc_cameleon
                  loop
                ftmp @ color_false @ + 800000 * pick-a-color colorize ;


code calc_tiger ( i - )
         xx faddr@ fsqr  yy faddr@ fsqr f- aa faddr@+ fdup fsin ftan f>s * 3000 ass-lit * ftmp addr!
         xx faddr@  yy faddr@* f2*  bb faddr@+
         yy faddr! xx faddr!
 next,
 end-code

code tiger? ( - f )
                      xx faddr@ fsqr  yy faddr@ fsqr  f+               \ 2500
                      fdup fsqr xx faddr@* fsin ftan f>s color_false addr@ * ftmp addr!
                      _1e2 faddr@ f>
 next,
 end-code

: tiger     9 juliado
                  do  tiger?
                         if   ftmp @ posblcolors /mod drop color_true @ * 3000 *
                                   color_false @ + pick-a-color
                                   colorize unloop exit
                         endif
                    i  calc_tiger
                  loop
                ftmp @  color_true @ + pick-a-color colorize ;

code  calc_snake  ( - )
                     xx faddr@ fsin  yy faddr@ fcos f- aa faddr@+
                     xx faddr@ yy faddr@* f2*  bb faddr@+
                     yy faddr! xx faddr!
 next,
 end-code


14e  fvariable _14 _14 f!
100e  fvariable _100 _100 f!

code  snake?  ( - f )
                      xx faddr@ fsqr  yy faddr@ fsqr  f+  fdup _100 faddr@* f>s ftmp addr!
                      _14 faddr@  f>
 next,
 end-code


: snake   0 20 juliado  \ <> --- <>
                  do  drop i snake?
                            if  color-true?
                                   if    i ftmp @ i colorstep * 85000 * + +
                                         i negate +rgb color_true @ + pick-a-color
                                   else  i ftmp @ i colorstep * 85000 * - +
                                         i +rgb color_false @ + pick-a-color
                                   endif  colorize unloop drop exit
                            endif
                       calc_snake
                  loop
                ftmp @  color_false @ + colorstep * 17000 * -
                pick-a-color  colorize ;


code calc_tentacle ( - )
                     xx faddr@ fsin yy faddr@ ftan f- aa faddr@+ fdup f>s ftmp addr!
                     xx faddr@ yy faddr@* f2*  bb faddr@+
                     yy faddr! xx faddr!
        next,
        end-code

1001e fvariable _1001e _1001e f!

code tentacle? ( i - f )
                    xx faddr@ fsqr  yy faddr@ fsqr  f+  fdup _1001e faddr@* f>s + ftmp addr!
                    _14  faddr@ f>
        next,
        end-code


: tentacle    20 juliado  \ <> --- <>
                  do    i tentacle?
                               if  color-true?
                                     if    ftmp @  color_true @ +  pick-a-color
                                     else  ftmp @  color_false @ +  pick-a-color
                                     endif colorize unloop  exit
                               endif
                       calc_tentacle
                  loop
                ftmp @ 30000 * color_false @ + pick-a-color  colorize ;


: julia_title ( - adr count )
\  ['] innerloop >body @ >name dup nfa-count title$ place \ doesn't work in a turnkey appl.
   ['] innerloop >body @
        case
            ['] standard     of s" standard"                endof
            ['] anti-julia   of s" anti-julia"              endof
            ['] extreme      of s" extreme"                 endof
            ['] extreme-anti of s" extreme-anti"            endof
            ['] cameleon     of s" cameleon"                endof
            ['] tiger        of s" tiger"                   endof
            ['] snake        of s" snake"                   endof
            ['] tentacle     of s" tentacle"                endof
                  drop s" cameleon" dup
        endcase
   title$ place
  s"  " title$  +place  time_in_title
 ;


1.3e fvalue fzoom-dist
1e fvalue fzoom-posx
1e fvalue fzoom-posy

1.2e fvalue fdist
0e fvalue fposx
0e fvalue fposy

: RangeJulia  ( limit low - ) \ For each range in the Julia fractal
   do   xm i + i1 !
        ym negate ym 1-
           ?do   ym i +  j1 !
                 j s>f p1 f* n1 s>f f/
                 fzoom-posy f*  fposy f+  xx f!
                 i s>f p2 f* n2 s>f f/
                 fzoom-posx f*  fposx f+  yy f!
                 innerloop
            -1 +loop
        stop-drawing
              if   leave
              endif
   loop
 ;

0 value ToBmp?

0 value FractalWidth

: MapJuliaToSize  ( w h - )
                 2/  to ym
                 2/ dup to xm to n1
                 n1 s>f p1 f* p2 f/ f>s to n2
 ;

: SetDots ( - )
    below ToBmp?
         if     SetBmpDotsTo: BmpFractal
         else   SetDotsTo: DibFractal
         then
 ;

: outerloop_parallel ( - )
    SetDots
    GetRange: FractalTask RangeJulia  ( n1 n1-negate - ) \ For each range
   \ 0 StopTaskTimer: FractalTask
 ;

 0e0 fvalue SmallestCycleTime  \ Is set at the start

0 value ProgresNesting
0 value TimeOut

: Progres  ( - )
   Continous- not ProgresNesting and
   if true to ProgresNesting
      begin  #IncompleteJobs: FractalTask
                 if SmallestCycleTime 9e-10 f>
                         if    300  \ For a slow PC
                         else  50
                         then
                 dup to TimeOut ms
                 then
               #IncompleteJobs: FractalTask
      while    call GdiFlush drop SuspendThreads: FractalTask \ Suspend all tasks before showing the dibsection
               ShowDib: DibFractal
               ResumeThreads: FractalTask
      repeat
    false to ProgresNesting
  then
 ;

: use-one-or-all-threads ( - )
    UseOneThread-
       if    UseOneThreadOnly: FractalTask
       else  UseALLThreads: FractalTask
       then
 ;

: OuterloopOnScreen  ( - )
\ Analyze: FractalTask
\ TimeSeconds: FractalTask
    true to ProgresNesting
    ['] Progres Submit: ControllerTask
    use-one-or-all-threads
    GetSize:  DibFractal MapJuliaToSize
    n1   n1 negate  ['] outerloop_parallel
    Parallel: FractalTask
    ShowDib: DibFractal update-title$ retitle-julia 2drop
\ .JobAnalysis: FractalTask  .ThreadBlock: FractalTask
;


\ debug OuterloopOnScreen \ SubmitRange: FractalTask

: FilenameBmp ( - adr$ cnt )
    s" .bmp" BitmapName$ +place BitmapName$ dup +null count ;

: OuterloopInBmp  ( - )
\    UseOneThreadOnly: FractalTask  \ to test
    true to ProgresNesting
    FilenameBmp BMwidth BMheight  2dup MapJuliaToSize BmpMapHndl InitBmpFile: BmpFractal
    n1   n1 negate  [']  outerloop_parallel
    Parallel: FractalTask
    Close: BmpFractal
;



 0 value FractalNesting?

: OuterloopTask
 realtime_priority_class set-priority
 FractalNesting? not
   if  true to FractalNesting?
   ToBmp?
     if    OuterloopInBmp
     else  OuterloopOnScreen
     then
  false to FractalNesting?
  then
;



: posx-posy-min  ( - fmin )            fzoom-posy fzoom-posx  fmin  ;
: fzoom          ( f: fpos - fofset )  fzoom-dist f* 10e f/ ;

\ : +fto noop ;

: julia-walker
   LastKey
   time-reset update-title$ retitle-julia 2drop
      case
        ascii +       of 1 +to julia-detail                             endof
        ascii -       of julia-detail 1 - 0 max to julia-detail         endof
        k_up          of fdist posx-posy-min f* fabs +fto fposx         endof
        k_down        of fdist posx-posy-min f* fabs fnegate +fto fposx endof
        k_left        of fdist posx-posy-min f* fabs +fto fposy         endof
        k_right       of fdist posx-posy-min f* fabs fnegate +fto fposy endof

        k_shift_up    of fzoom-posx fzoom fnegate +fto fzoom-posx       endof
        k_shift_down  of fzoom-posx fzoom  +fto fzoom-posx              endof

        k_shift_left  of fzoom-posy fzoom  +fto fzoom-posy              endof
        k_shift_right of fzoom-posy fzoom fnegate +fto fzoom-posy       endof

        k_home        of 1e fto fzoom-posx 1e fto fzoom-posy
                         0e fto fposx      0e fto fposy
                         1.2e fto fdist    0   to julia-detail          endof
        k_pgup        of fzoom-dist 1.2e f* fto fzoom-dist
                         fdist 1.2e f* fto fdist                        endof
        k_pgdn        of fzoom-dist 1.2e f/ fto fzoom-dist
                         fdist 1.2e f/ fto fdist                        endof
        esc           of true to stop-random-julia                      endof
       endcase
     ['] OuterloopTask Submit: ControllerTask
 ;



: init-parameters
                ['] julia_title is update-title$
                FractalWidth  DibFractal.height  MapJuliaToSize
                time-reset
  ;


10 constant #styles
#styles cell-array checked-styles
#styles cell-array used-styles
#styles cell-array styles
0 value julia-style

' standard is innerloop


\s
