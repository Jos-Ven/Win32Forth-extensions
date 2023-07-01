   \ September 10th, 2001 - 11:03 by J.M.B.v.d.Ven

\ The Mandelbrot set is the best known example of a fractal.
\ It includes smaller versions of itself which can be explored to arbitrary
\ levels of detail.
\ It was discovered by Benoit B. Mandelbrot who coined the name "fractal"
\ in 1975 from the Latin fractus or "to break".

\ This version was ported from Pascal

anew mandelbr.f


   b/float newuser a           b/float newuser b
   b/float newuser ca          b/float newuser cbi
   b/float newuser old_a       b/float newuser old_b
2e fvariable _2e _2e f!
4e fvariable _4e _4e f!

   cell newuser tmp
   30  variable detail detail !
   7   value  pattern
   1e fvariable distortion  distortion f!

 1.02e fvalue MaxX  \ hor compr | stretch + -
-2.0e  fvalue MinX  \ right     | left + -

 1.4e  fvalue MaxY  \ vert compr | stretch + -
-1.4e  fvariable MinY  MinY f!   \ up         | down + -

0.0e fvariable _dx _dx f!       0.0e fvariable _dy  _dy f!



\ : calc_pixel_normal ( - n ) ( f: ca cbi - ) \ don't burn your self on the stack
\   f2dup   color_pixel_inside  fto cbi fto ca    fto b  fto a
\   detail 0 do
\              a fto old_a
\              a fdup f* b fdup f* f2dup f- ca f+  fto a ( x )
\              2.0e old_a f*  b f* cbi f+  fto b         ( y ) \ a f. b f. cr
\              f+ 4.0e  f>    if   i tmp !   leave    then
\         loop  tmp @ ;


: mandelbrot_tiger (  - )
   a f@ b f@ f*  1e pattern dup dup dup * * swap 10 / + s>f f/ f/ f>s
   cos  500 / 7 *
   abs color_true @ * pick-a-color  tmp !
 ;

code mandelbrot_normal ( - )
        zero tmp addr!
 next,
 end-code

defer color_pixel_inside

' mandelbrot_normal is color_pixel_inside

code  _calc_pixel
   2dup rot s>f  _dy faddr@*   MinY faddr@+
   fdup cbi faddr! b faddr! ca faddr@  a faddr! detail addr@ zero
        do     a faddr@  old_a faddr!
               b faddr@  old_b faddr!
               a faddr@ fdup f*  b faddr@ fdup f* f2dup f-  ca faddr@+
               distortion faddr@*   a faddr!   ( x )
               _2e faddr@  old_a faddr@*  old_b faddr@*  cbi faddr@+  b faddr!     ( y ) \ a f. b f. cr
               f+  _4e faddr@ f>
                        if   i 80431637 ass-lit * color_false addr@+ tmp addr! leave
                        then
         loop
 next,
 end-code


:inline calc_pixel ( j i - j j i n ) ( f: ca cbi - rgb )
   0 tmp ! color_pixel_inside  _calc_pixel tmp @  pick-a-color
 ;


\ -0.5e 1.0e calc_pixel f.s .s abort
\  0.2e 0.5e calc_pixel abort


: mandelbrot_parallel
    SetDots
    GetRange: FractalTask
       do  i dup s>f _dx f@  f* MinX f+ ca f!
        ym  0 do
                 i calc_pixel  set-mdot
               loop
            drop
          stop-drawing  IF LEAVE ENDIF
        loop
 ;


: MapMandelbrotToSize ( w h - )
     MaxY MinY f@ f-    dup to ym s>f   f/  _dy f! \ ystep
     MaxX MinX f-       dup to xm s>f   f/  _dx f! \ xstep
 ;

: mandelbrot   \ September 8th, 2003 The use of ym was not right. Changed it.
   FractalWidth  DibFractal.height  MapMandelbrotToSize
   use-one-or-all-threads
   false to fractal-ready?
   true to ProgresNesting
   xm 0 ['] mandelbrot_parallel Parallel: FractalTask
   ShowDib: DibFractal
   update-title$ retitle-julia 2drop
;

: MandelbrotInBmp ( - )
   FilenameBmp BMwidth BMheight 2dup MapMandelbrotToSize BmpMapHndl InitBmpFile: BmpFractal
   false to fractal-ready?
   true to ProgresNesting
   xm 0 ['] mandelbrot_parallel Parallel: FractalTask
   Close: BmpFractal
   update-title$ retitle-julia 2drop
;


: MandelbrotTaskScreen
  realtime_priority_class set-priority
   FractalNesting? not
      if  true to FractalNesting?
          ToBmp?
             if   MandelbrotInBmp
             else  ['] Progres Submit: ControllerTask mandelbrot
             then
          false to FractalNesting?
      then
;


: hor_zoom_out   \ Prevents flipping while zooming out
   maxX minX f- 2e f/  \ average
   fdup distance f* 2e f* minX fswap f- fto minX
   distance f* 2e f* maxX  f+  fto maxX
;

: vert_zoom_out   \ Prevents flipping while zooming out
   maxY MinY f@ f- 2e f/  \ average
   fdup distance f* 2e f* MinY f@ fswap f- minY f!
   distance f* 2e f* maxY  f+  fto maxY
;

: hor_step  ( f: - n )   maxX minX f- distance f* fabs ;
: vert_step ( f: - n )   maxY MinY f@ f- distance f* fabs ;

: +value$->title$ \ f: ( n -  )
   pad fvalue-to-string s"  " pad +place pad count title$ +place ;

: mandelbrot_title ( - adr count )
   s" Mandelbrot at: " title$ place
   minx +value$->title$    maxx +value$->title$
   MinY f@ +value$->title$    maxy +value$->title$
   detail @ (.) title$ +place s"  " title$ +place time_in_title
 ;

: distort-fact ( f: - n )
   minx maxx f- fabs MinY f@ maxy f- fabs f+  100e f/ ;

: init-mandelbrot-title ( - )
   10 SET-PRECISION  ['] mandelbrot_title is update-title$  ;

: plot-mandelbrot-normal ( - ) ['] mandelbrot_normal is color_pixel_inside ;
: plot-mandelbrot-tiger  ( - ) ['] mandelbrot_tiger  is color_pixel_inside ;

: mandelbrot_walker
  init-mandelbrot-title
  time-reset update-title$ 2drop   retitle-julia
  lastkey
      case
        K_RIGHT       of maxX hor_step minx fover f- fto minX  f- fto maxX endof
        K_LEFT        of hor_step       fdup +fto minX           +fto maxX endof
        K_DOWN        of maxY vert_step MinY f@ fover f- minY f! f- fto maxY endof
        K_UP          of vert_step      fdup minY f@ f+ minY f!   +fto maxY endof
        K_SHIFT_RIGHT of hor_step       maxX fover f- fto maxX   +fto minX endof
        K_SHIFT_LEFT  of hor_zoom_out                                      endof
        K_SHIFT_DOWN  of vert_zoom_out                                     endof
        K_SHIFT_UP    of vert_step      maxY fover f- fto maxY minY f@ f+ minY f! endof
        ascii B       of plot-mandelbrot-normal                            endof
        ascii C       of plot-mandelbrot-tiger                             endof
        ascii D       of distort-fact distortion f@  f+ distortion f!      endof
        ascii E       of distort-fact fnegate distortion f@  f+ distortion f!     endof
        ascii P       of 1 +to pattern                                     endof
        ascii Q       of 1 negate +to pattern                              endof
        ascii +       of 10 detail  @ + detail !                           endof
        ascii -       of detail @ 10 - 3 max  detail !                     endof
        K_PGUP        of distance 1.3e f* fto distance                     endof
        K_PGDN        of distance 1.3e f/ fto distance                     endof
        K_HOME        of 1.02e fto MaxX -2.0e  fto MinX  30 detail !
                         1.4e  fto MaxY  -1.4e MinY f! 1e distortion f!
                         0 255 100 rgb color_true ! 0 color_false ! endof
      endcase
  ['] MandelbrotTaskScreen Submit: ControllerTask
  6 SET-PRECISION
 ;

: get-style  ( n - vector )
    dup to julia-style dup 2 /mod drop -
        case
                0   of ['] standard                endof
                2   of ['] anti-julia              endof
                4   of ['] extreme                 endof
                8   of ['] extreme-anti            endof
               16   of ['] cameleon                endof
               32   of ['] tiger                   endof
               64   of ['] snake                   endof
              128   of ['] tentacle                endof
                  drop ['] cameleon dup
        endcase
 ;

: compute ( - )
   ['] retitle-julia is update-title$
   init-parameters checked dup #active-bits 1 =
      if get-style is innerloop
      then
     julia-walker
 ;

' compute is redraw

' compute value draw-vector ( - )
: resume-drawing ( - )   draw-vector is redraw ;
\s
