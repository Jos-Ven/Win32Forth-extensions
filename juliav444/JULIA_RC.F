\ June 23rd, 2001 - 19:14 by J.M.B.v.d.Ven
\ The input window under options

anew juliadlg.f

WinDC CurrentDC

: restart-msg
     BLACK SetBkColor: currentDC
     white SetTextColor: currentDC
     10 60 ( x y )     s" Click right here to (re)start." textout: currentDC
 ;

defer init-julia


  string: Aa$   s" 0.1e" Aa$ place
  string: Bb$  s"  1.0e" Bb$ place

  string: p1$  s"  1.9e" p1$ place
  string: p2$  s"  1.6e" p2$ place

  string: detail$          s" 1.0e" detail$ place
  string: distortion$      s" 0.6e" distortion$ place
  string: pattern$         s" 10e"  pattern$ place

  string: color_false$     s" 170.0e" color_false$ place
  string: color_true$      s" 100.0e" color_true$ place
  string: BMwidth$         s" 200e"   BMwidth$ place
  string: BMheight$        s" 100e"   BMheight$ place


create error-parameters ( - adr_error-parameters )
       z," Use only a number as a parameter.\n\n"
      +z," Like: 1.6  -1.98  10 \n\n"
      +z," Try again.\n"
     -null, here 0 c, align error-parameters - constant error-parameters-len

defer parameters-again
' noop is parameters-again

: wrong-parameters ( - )
   true error-parameters error-parameters-len ?MessageBox parameters-again  ;

: .parameters ( - )
  cr
   ." Aa " Aa f@ f.
   ." Bb " Bb f@ f.
   ." p1 " p1 f.
   ." p2 " p2 f.
  ;


: convert->float ( flag adr - flag )   \ FS: ( - float )
   float-number-string  and  ;


: get-parameters-and-draw ( - )
   checked 1 max to checked
   true  Aa$ convert->float Aa f!
        Bb$ convert->float Bb f!
        p1$ convert->float fto p1
        p2$ convert->float fto p2
        color_false$ convert->float f>s abs color_false !
        color_true$  convert->float f>s abs color_true !
        detail$      convert->float f>s abs  detail !
        distortion$  convert->float distortion f!
        pattern$     convert->float f>s abs to pattern
        BMwidth$     convert->float f>s abs to BMwidth
        BMheight$    convert->float f>s abs to BMheight
     if   false to stop-drawing  redraw
     else wrong-parameters
     then       \ See the word parameters for an explanation.
 ;

conhndl value julia-base

load-dialog juliadlg juliadlg.res

:Object JuliaDialog <SUPER dialog

IDD_PARAMETERS juliadlg find-dialog-id constant template

:M StartPos: self  900 500 ;M

:M On_Init:
   On_Init: super
  4 set-precision
                 Aa f@ Aa$ fvalue-to-string-and-count IDD_AA SetDlgItemText: self
                 Bb f@ Bb$ fvalue-to-string-and-count IDD_BB SetDlgItemText: self
                 p1 p1$ fvalue-to-string-and-count IDD_P1 SetDlgItemText: self
                 p2 p2$ fvalue-to-string-and-count IDD_P2 SetDlgItemText: self
 distortion f@ distortion$ fvalue-to-string-and-count IDD_DISTORTION
                                                          SetDlgItemText: self
          detail @ s>f detail$ fvalue-to-string-and-count IDD_DETAIL
                                                          SetDlgItemText: self
          pattern  s>f pattern$ fvalue-to-string-and-count IDD_PATTERN
                                                          SetDlgItemText: self
  6 set-precision

          BMwidth  s>f BMwidth$   fvalue-to-string-and-count IDD_WIDTH
                                                          SetDlgItemText: self
          BMheight s>f BMheight$ fvalue-to-string-and-count IDD_HEIGHT
                                                          SetDlgItemText: self
  9 set-precision
                color_false @  s>f color_false$
                fvalue-to-string-and-count IDD_COLOR_FALSE
                                                          SetDlgItemText: self
                color_true @   s>f color_true$
                fvalue-to-string-and-count IDD_COLOR_TRUE
                                                          SetDlgItemText: self
                checked 0 bit-active? IDD_STANDARD     CheckDlgButton: self
                checked 1 bit-active? IDD_ANTI-JULIA   CheckDlgButton: self
                checked 2 bit-active? IDD_EXTREME      CheckDlgButton: self
                checked 3 bit-active? IDD_EXTREME-ANTI CheckDlgButton: self
                checked 4 bit-active? IDD_CAMELEON     CheckDlgButton: self
                checked 5 bit-active? IDD_TIGER        CheckDlgButton: self
                checked 6 bit-active? IDD_SNAKE        CheckDlgButton: self
                checked 7 bit-active? IDD_TENTACLE     CheckDlgButton: self
                checked 8 bit-active? IDD_MAN_STANDARD CheckDlgButton: self
                checked 9 bit-active? IDD_MAN_TIGER    CheckDlgButton: self

                ;M

:M ClassInit:   ( -- )      ClassInit: super ;M


:M Start:  ( -- f )  julia-base template run-dialog ;M

:M On_Command:  ( hCtrl code ID -- f )
        case
          IDOK of
                       IDD_STANDARD     IsDlgButtonChecked: self 0 check!
                       IDD_ANTI-JULIA   IsDlgButtonChecked: self 1 check!
                       IDD_EXTREME      IsDlgButtonChecked: self 2 check!
                       IDD_EXTREME-ANTI IsDlgButtonChecked: self 3 check!
                       IDD_CAMELEON     IsDlgButtonChecked: self 4 check!
                       IDD_TIGER        IsDlgButtonChecked: self 5 check!
                       IDD_SNAKE        IsDlgButtonChecked: self 6 check!
                       IDD_TENTACLE     IsDlgButtonChecked: self 7 check!
                       IDD_MAN_STANDARD IsDlgButtonChecked: self 8 check!
                       IDD_MAN_TIGER    IsDlgButtonChecked: self dup 9 check!
                                        if   plot-mandelbrot-tiger
                                        else plot-mandelbrot-normal
                                        then
  4 set-precision
                  Aa$ dup $max-count IDD_AA GetDlgItemText: self count!
                  Bb$ dup $max-count IDD_BB GetDlgItemText: self count!
                  P1$ dup $max-count IDD_P1 GetDlgItemText: self count!
                  P2$ dup $max-count IDD_P2 GetDlgItemText: self count!
  9 set-precision
  color_true$ dup $max-count IDD_COLOR_TRUE GetDlgItemText: self count!
color_false$ dup $max-count  IDD_COLOR_FALSE GetDlgItemText: self count!
                 detail$     dup $max-count
                             IDD_DETAIL GetDlgItemText: self count!
                 distortion$ dup $max-count
                             IDD_DISTORTION GetDlgItemText: self count!
                 pattern$    dup $max-count
                             IDD_PATTERN GetDlgItemText: self count!

                 BMwidth$    dup $max-count
                             IDD_WIDTH GetDlgItemText: self count!
                 BMheight$   dup $max-count
                             IDD_HEIGHT GetDlgItemText: self count!
                1 end-dialog
          endof

          IDCANCEL of 0 end-dialog  endof
          false swap ( default result )
        endcase ;M

;Object

: parameters          ( -- )
   true to stop-drawing
   Start: JuliaDialog
    if  0 to LastKey get-parameters-and-draw
    then
 ;


' parameters is parameters-again

\s
