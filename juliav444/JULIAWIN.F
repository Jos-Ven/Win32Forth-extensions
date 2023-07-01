anew -juliawin.f

: juliav3-window z" Julia Fractal V4.4" ;

create infoWin32Forth       ( - adr_infoWin32Forth )
        z," Win32Forth is a Public Domain Forth system.\n"
       +z," This program is compiled with Win32Forth version 6.15.03.\n\n"
       +z," You can download the free Win32Forth compiler from the Internet at:\n"
       +z," http://sourceforge.net/projects/win32forth/files\n"
       -null, here 0 c, align infoWin32Forth - constant infoWin32Forth-len

create info-contrib         ( - adr_info-contrib )
       z," The initial Forth formula for the Julia fractal was made by\n"
      +z," M. Hendrix and distributed with Iforth in 1994. \n\n"
      +z," Extended, optimzed and ported to Win32Forth \n"
      +z," by J.M.B.v.d.Ven.\n"
      +z," Can be downloaded from: https://sites.google.com/site/win324th/home\n"
     -null, here 0 c, align info-contrib - constant info-contrib-len


create infojulia            ( - adr_infojulia )
       z," - Includes Julia and Mandelbrot fractals.\n"
      +z," - 16777216 colors.\n"
      +z," - 8 possible Julia styles.\n"
      +z," - A random slide show.\n"
      +z," - Provides zooming and moving.\n\n"
      +z," See Version.txt for details.\n"
     -null, here 0 c, align infojulia - constant infojulia-len

:  +temp$ ( adr$ n dest$ - ) temp$ +place ;

: infojulia$  ( - temp$ n )
   infojulia infojulia-len temp$ place
   s" Threads: " +temp$
   #Hardware-threads 0 (d.) +temp$
   s" . Timeout: "  +temp$
   TimeOut 0 (d.)   +temp$
   s"  ms." +temp$ temp$ +Null
   temp$ count
;

create infojulia-functions  ( - adr_infojulia-functions )
       z," Change the parameters in the menu \nOptions to see various fractals.\n\n"
      +z," Result:\n"
      +z," The elapsed time in the window title after the plot. \n"
   -null, here 0 c, align infojulia-functions - constant infojulia-functions-len


create infomandelbrot-functions  ( - adr_infojulia-functions )
       z," Function keys in the fractal walker:\n"
      +z," - SHIFT + <Up> <Down> <Left> <Right> Zooms in or out of the fractal.\n"
      +z," - <Up> <Down> <Left> <Right> Moves the fractal.\n"
      +z," - <Page Up> or <Page Down>  Zoom speed.\n"
      +z," - <+> or <-> Details.\n"
      +z," - <Home> Reset.\n"
-null, here 0 c, align infomandelbrot-functions - constant infomandelbrot-functions-len

create infomandelbrot-effects  ( - adr_infojulia-effects )
       z," Function keys in the mandelbrot:\n"
      +z," - <b> or <c> Inside black or colored.\n"
      +z," - <d> or <e> Distorts more or less.\n"
      +z," - <p> or <q> More or less patterns.\n"
-null, here 0 c, align infomandelbrot-effects - constant infomandelbrot-effects-len


' julia_title is update-title$
update-title$ 2drop

\ title$ 60 dump abort

' compute to draw-vector

1 value style

: posneg-random ( - 1 | - -1 )
   2 random 1 =
     if -1
     else 1
     then
  ;

: possible-styles ( max-styles - used-styles )
   0 here! 0
      do  1 i lshift dup pad! checked and
            if   pad@  here@  to-cell checked-styles  here 1+!
            then
      loop
   here@
;

\ tb 1111 to checked 15 possible-styles 0
\ cr ' checked-styles 60 dump here ? abort

\ The random routine repeats some values more than others.
\ Some values seldom appear.
\ After some time I saw some colors used 6 times while
\ other values where not used.
\ Solution: keep a tally of the used colors in an other array
\ least-used will search for values which are least used.

\ 0 10 ' used-styles cadump  abort

: mandelbrot? ( style - f ) 256 >= ;


: random-style ( - n )
   #styles possible-styles                               \ max ptr
   dup  random  over ['] used-styles least-used >r       \ start random
   0 swap ['] used-styles least-used dup used-styles     \ overall least used
   r@ used-styles <= r> swap           \ take the random way if it is least used
      if    nip
      else  drop
      then
   1 over +to-cell used-styles checked-styles
    dup  mandelbrot?
   if    ['] mandelbrot_tiger is color_pixel_inside
   else dup get-style is innerloop
   then
 ;


: random-mandelbrot-show ( - )
   init-mandelbrot-title ['] mandelbrot_tiger  is color_pixel_inside
        486 random 10 + s>f 100e f/ distortion f!
        43 random   3 + detail ! random-color
        40 random   2 + to pattern
        14 random   6 + negate s>f 10e  f/ fto minX
        40 random  20 +        s>f 100e f/ fto maxX
       180 random 100 + s>f 200e f/ fdup   fto maxY
                                 fnegate   minY f!
        time-reset update-title$ 2drop retitle-julia
        mandelbrot
        update-title$ retitle-julia 2drop 6 set-precision
 ;

: 1slide  ( - )
          stop-drawing not
            if
              random-style mandelbrot?
                if   random-mandelbrot-show
                else 190 random posneg-random * s>f 100e f/ aa f!
                     600 random s>f 100e f/ bb f! random-color
                     init-parameters
                     time-reset update-title$ retitle-julia 2drop OuterloopOnScreen ShowDib: DibFractal
                     elapsed-time 100 ms
                then
            then
 ;

: WaitForInterrupt  ( ms - flag )
    false swap 10 / dup 100 / swap 0
       do  dup ms winpause stop-random-julia
               if   nip true swap leave   then
       loop
    drop
 ;

: random-julia
   DisableScreenSaver init-random drop false to stop-random-julia
       begin  1slide drop 10000 WaitForInterrupt  until
   ClearExecutionState Z" ready.wav" sounds
 ;

string: incr-name0   s" E:\development\FORTH\_Julia\test" incr-name0 place
string: incr-name    s" E:\development\FORTH\_Julia\test" incr-name place

FileSaveDialog save-slides-dlg "The saved slides start with: " "Parameter Files (*.bmp;*.ini)|*.bmp;*.ini|All Files (*.*)|*.*|"
create #slides$ max-handle allot  #slides$ off

NewEditDialog SlidesDlg "Maximum slides" "Number of slides to make:" "Ok"   ""  ""

: save-random-slides
   hwnd-julia   Start: save-slides-dlg dup count lower dup extension>
   init-random drop false to stop-drawing set-bitmap-sizes 2drop 0
   #slides$ dup s" 20" rot place julia-base Start: SlidesDlg not
      if  2drop exit
      then
   #slides$ count number? not abort" Bad number" d>s abs 0
   NOmenu-hmnu change-menu
   false to stop-random-julia
       do
         over extension>  over count incr-name place          \ reset name
         1+ dup s>d <# # # # # #> incr-name +place incr-name  \ add a number to the name
         10 60 incr-name count textout: currentDC
         incr-name 0terminated
         1slide save-to-bmp-and-ini
         winpause 30 ms stop-random-julia
           if  100 ms false to stop-drawing leave
           then
       loop  2drop
   ['] compute to draw-vector
   julia-hmnu change-menu
 ;

: stop_no_back_buffer ( n - n )
    dup 0=
     if not s" Load colors in the backbuffer in the menu Options first."  ?MessageBox drop abort
     then
;

: swap_false ( - )
   color_false_bck stop_no_back_buffer color_false @
   to color_false_bck color_false ! redraw
 ;

: swap_true ( - )
   color_true_bck stop_no_back_buffer color_true @
   to color_true_bck  color_true ! redraw
 ;

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

: .Fractal
   false to stop-drawing resume-drawing redraw
 ;

: SetDibSize ( - )
     DibFractal.&InfoRect hwnd-julia Call GetClientRect drop
     DibFractal.width  to FractalWidth
 ;


menubar Nomenu
 popup "Busy...."
endbar

:Object JuliaWindow     <Super Window

\ Rectangle clientRect
int SecondTime?

( overide the default window class to use a black background )
: Julia-class ( -- )
                default-window-class
                DefaultCursor: [ self ] NULL Call LoadCursor  to hCursor
                CS_DBLCLKS CS_HREDRAW + CS_VREDRAW + to Style
                BLACK_BRUSH Call GetStockObject to hbrBackground
  ;

: register-julia-window  ( -- f ) Julia-class register-the-class ;


:M Start:       ( -- )
                hWnd 0=
                if      s" JuliaWindow" SetClassName: self
                        register-julia-window drop
                        create-frame-window to hWnd
                        screen-size  over to FractalWidth \ Allocate the whole screen once.
                        GetDC: Self  InitDibSection: DibFractal
                        SW_SHOWNORMAL Show: self
                else    SetFocus: self
                then
                start: super
                ;M

:M ReTitle:     ( -- )             julia_title 2drop update-title$ SetTitle: self   ;M
:M WindowStyle: ( -- style )       WindowStyle: SUPER WS_BORDER OR WS_OVERLAPPED OR ;M
:M StartSize:   ( -- w h )         screen-size >r 7 * 12 / r> 4 / 3 *               ;M
:M MinSize:     ( - w h )          30 60              ;M
:M WM_INITMENU  ( h m w l -- res ) MenuChecks  0      ;M
:M StartPos:    ( -- x y )         CenterWindow: Self ;M
:M WindowTitle: ( -- Zstring )     juliav3-window     ;M

:M WM_MOVE      ( hwnd msg wparam lparam -- res )
                4drop ShowDib: DibFractal 0  \ Needed when the window was partly of the screen
   ;M

:M WM_MOVE      ( hwnd msg wparam lparam -- res )
                4drop ShowDib: DibFractal 0  \ Needed when the window was partly of the screen
   ;M

:M On_SetFocus: ( h m w l -- )  \ Needed in older windows systems
                4drop true to have-focus?
                ShowDib: DibFractal

 ;M

: 0KeyCode { ascii alt funktionkey -- code|ascii }
    funktionkey 0=
      if ascii $6A >
             if   ascii $2F and \ For + and -
             else ascii
             then   \ leaves ascii with shift in
      else  funktionkey \ leaves the functionkey
      then
 ;



: KeyCode { ascii alt funktionkey -- code|ascii }
    funktionkey 0=
      if ascii $6A >
             if   ascii $2F and \ For + and -
             else ascii
             then   \ leaves ascii with shift in
      else  funktionkey \ leaves the functionkey
      then
 ;


:M WM_KEYDOWN ( key lKeyData -- res )
     over
        Case   \ these are the codes specified in keyboard.cpp
            VK_F1      of  0x10001  endof
            VK_F2      of  0x10002  endof
            VK_F3      of  0x10003  endof
            VK_F4      of  0x10004  endof
            VK_F5      of  0x10005  endof
            VK_F6      of  0x10006  endof
            VK_F7      of  0x10007  endof
            VK_F8      of  0x10008  endof
            VK_F9      of  0x10009  endof
            VK_F10     of  0x10010  endof
            VK_F11     of  0x10011  endof
            VK_F12     of  0x10012  endof
            VK_HOME    of  0x20000  endof
            VK_END     of  0x20001  endof
            VK_INSERT  of  0x20002  endof
            VK_DELETE  of  0x20003  endof
            VK_LEFT    of  0x20004  endof
            VK_RIGHT   of  0x20005  endof
            VK_UP      of  0x20006  endof
            VK_DOWN    of  0x20007  endof
            VK_SCROLL  of  0x20008  endof
            VK_PAUSE   of  0x20009  endof
            VK_PRIOR   of  0x20010  endof
            VK_NEXT    of  0x20011  endof
            ( default )   0 swap
        EndCase  \ 2
     dup
        IF
            VK_CONTROL call GetKeyState 32768 and IF  0x40000 or  THEN
            VK_SHIFT   call GetKeyState 32768 and IF  0x80000 or  THEN
        THEN
    KeyCode OnKey  0
 ;M

:M On_Size:  ( l p -- )
               SIZE_MINIMIZED  <>
                   if  true to stop-drawing
                           begin  #IncompleteJobs: ControllerTask     \ Wait till the fractal task has been stopped
                           while  winpause
                           repeat
                       0 to LastKey SetDibSize
                       SetDotsTo: DibFractal
                       false to stop-drawing
                       SecondTime?
                           if    Redraw
                           else  true to SecondTime?
                           then
                   then
                drop
                ;M

:M On_Init:     ( -- )
                On_Init: super
                cycle-time  fto SmallestCycleTime
                CS_DBLCLKS  GCL_STYLE hWnd  Call SetClassLong  drop
                true to stop-drawing
                GetHandle: self to hwnd-julia
                addr:      self to julia-base
                getDC:     self puthandle: CurrentDC
                false to SecondTime?
                ;M

:M On_Done:     ( -- )
                true to stop-drawing
                TerminateAllJobs: FractalTask
                TerminateAllJobs: ControllerTask
                0 Call PostQuitMessage drop
                On_Done: super
                ;M

:M WM_CLOSE     ( h m w l -- res ) bye  0 ;M

;Object


: ClrDib ( - )
\ 0 0 xy>bmp  _EndAdresDib @ over - 0 fill ShowDib: DibFractal \ Works but is not as nice as using set-mdot
\ paint: JuliaWindow   exit                                    \ in this case
 GetSize: DibFractal
    0 do
       dup 0 do i j 0 set-mdot
       loop
     loop
  drop
  ShowDib: DibFractal
 ;

: do-init-julia (  - )  ['] color is way-to-color ;

' do-init-julia is init-julia

\s
