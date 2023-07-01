anew export.f


: set-bitmap-sizes  ( - w h )
   BMwidth aligned BMheight aligned  2dup SetSize: BmpFractal
 ;

: save-bmp  ( buffername$ - )
   s" Saving. Please wait...                     "  title$ place retitle-julia
    NOmenu-hmnu change-menu
    count BitmapName$ place BitmapName$ +null time-reset
       false to stop-drawing true to ToBmp?
       draw-vector ['] compute =
            if    OuterloopInBmp
            else  MandelbrotInBmp
            then
       false to ToBmp?
  s" Done "  title$ place time_in_title retitle-julia 2drop
  julia-hmnu change-menu
  ;



: n>tmp$ ( n - adr )     s>d (d.) tmp$ place tmp$  dup 0terminated 1+ ;

FileSaveDialog save-params "Save parameters" "Parameter Files (*.ini)|*.ini|All Files (*.*)|*.*|"

: n>profile ( inifile section key n - inifile section )
   2 pick >r n>tmp$ +inifile r> ;

: save-ini ( buffername$ - )
   dup s" .ini" rot +place dup count swap + 0 swap !
   z" mandelbrot"       z" distortion"   distortion f@  f>profile
                        z" detail"       detail @       n>profile
                        z" pattern"      pattern        n>profile
                        z" MaxX"         MaxX           f>profile
                        z" MinX"         MinX           f>profile
                        z" MaxY"         MaxY           f>profile
                        z" MinY"         MinY f@        f>profile
   drop z" julia"       z" Xx"           Xx f@          f>profile
                        z" Yy"           Yy f@          f>profile
                        z" Aa"           Aa f@          f>profile
                        z" Bb"           Bb f@          f>profile
                        z" p1"           p1             f>profile
                        z" p2"           p2             f>profile
                        z" julia-detail" julia-detail   n>profile
                        z" julia-style"  julia-style    n>profile
                        z" color_false"  color_false @  n>profile
                        z" color_true"   color_true  @  n>profile
                        z" colorstep"    colorstep      n>profile
                        z" rgb-to-inc"   rgb-to-inc     n>profile
                        z" fzoom-posx"   fzoom-posx     f>profile
                        z" fzoom-posye"  fzoom-posy     f>profile
                        z" fposy"        fposy          f>profile
                        z" fposx"        fposx          f>profile
                        z" fdist"        fdist          f>profile
   2drop
 ;

: save-to-inifile
  hwnd-julia Start: save-params dup count lower dup extension> save-ini
 ;

FileSaveDialog save-bmp-dlg "Save bitmap and parameters" "Parameter Files (*.bmp;*.ini)|*.bmp;*.ini|All Files (*.*)|*.*|"

: save-to-bmp-and-ini ( FileName$ - )
  dup extension> dup save-bmp
  dup extension> save-ini
 ;

: save-to-bmpfile  ( - )
  hwnd-julia Start: save-bmp-dlg dup count lower
  save-to-bmp-and-ini
 ;

FileOpenDialog Inifile "Load parameter file" "Parameter Files (*.ini)|*.ini|All Files (*.*)|*.*|"

: load-ini
   ['] compute to draw-vector
   hwnd-julia Start: inifile
   z" julia"            z" Xx"           profile>f Xx f!
                        z" Yy"           profile>f Yy f!
                        z" Aa"           profile>f Aa f!
                        z" Bb"           profile>f Bb f!
                        z" p1"           profile>f fto p1
                        z" p2"           profile>f fto p2
                        z" julia-detail" profile>s to julia-detail
                        z" julia-style"  profile>s dup to julia-style dup to checked 1 =
                               if   ['] mandelbrot_walker
                               else ['] compute
                               then
                        is redraw
                        z" color_false"  profile>s color_false !
                        z" color_true"   profile>s color_true !
                        z" colorstep"    profile>s to colorstep
                        z" rgb-to-inc"   profile>s to rgb-to-inc
                        z" fzoom-posx"   profile>f fto fzoom-posx
                        z" fzoom-posye"  profile>f fto fzoom-posy
                        z" fposy"        profile>f fto fposy
                        z" fposx"        profile>f fto fposx
                        z" fdist"        profile>f fto fdist
   drop z" mandelbrot"  z" detail"       profile>s detail !
                        z" pattern"      profile>s to pattern
                        z" distortion"   profile>f distortion f!
                        z" MaxX"         profile>f fto MaxX
                        z" MinX"         profile>f fto MinX
                        z" MaxY"         profile>f fto MaxY
                        z" MinY"         profile>f MinY f!
   2drop
   redraw
 ;

: load>backbuffer
   hwnd-julia Start: inifile
   z" julia"      z" color_false"  profile>s to color_false_bck
                  z" color_true"   profile>s to color_true_bck
   2drop
 ;
