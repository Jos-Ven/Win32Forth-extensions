Anew -ParallelPlotter \  Needs at least Win32Forth version 6.14

\ *D doc\classes\
\ *! ParallelPlotter
\ *T ParallelPlotter -- A utillity for fast plotting.

\ *P set-mdot does this in assembler for maximum speed.
\ ** set-mdot is about 10 times faster than SetPixel of windows.
\ ** The parallel plotter can be used in a multitasking environment in which
\ ** each task can plot its own part of a plot.
\ ** This will again reduce the time needed to produce the graphic.

Needs bmpdot.f \ Needed for the structures

cell newuser _BWidth
cell newuser _EndAdresDib


get-current also assembler definitions in-system

: ass>bmp   ( x y  - adr>bmp )
   mov     ecx, edx        \ save UP. The result of mul will be in edx+eax

   mov eax, _BWidth  [UP]  \ x1
   mul     ebx             \ y * Width in eax and edx
   mov     edx, ecx        \ restore UP
   sub     eax, [esp]

   mov     ebx, _BWidth [UP]
   add     ebx, eax        \ addr@+

   mov eax, # #BYTES/PIXEL

   mul     ebx             \  #BYTES/PIXEL* in eax and edx
   mov     edx, ecx        \ restore UP
   add     esp, # 4

   mov  ebx, _EndAdresDib [UP]
   sub  ebx, eax

 ;

: assPlaceInBmp  ( rgb adr>bmp - )
     mov     -4 [ebp], ebx
     mov     ecx,  0 [esp]
     sub     ebx, ebx
     add     esp, # 4

     mov     bl, -4 [ebp]
     mov     2 [ecx], bl

     mov     bl, -2 [ebp]
     mov     bh, -3 [ebp]
     mov     0 [ecx], bx

     pop     ebx
 ;

in-previous previous set-current

code xy>bmp ( x y  - adr>bmp )
\ *G Gets the adres of the position at x y from the plot.
  ass>bmp
next, c;

code set-mdot  \ ( x y rgb - )
\ *G Put a dot at the x y position in a bitmap or DIBsection.
\ ** using the color of the RGB value that is on the stack.
\ ** x and y must point in a valid area 0,0 is at the top left.
\ ** It should be initialized by SetDotsTo: for each task.
   mov     -4 [ebp], ebx
   pop     ebx
   ass>bmp
   push    ebx
   mov     ebx, -4 [ebp]
   assPlaceInBmp
 next,
 end-code




:Class  PlotRectangle <Super Object
\ *G PlotRectangle is used to describe the position and size of the plot.

Record: &InfoRect
\ *G Contains a pointer to the position and size of the plot.
	int X
	int Y
	int Width
	int Height
;Record

\ *P Settings in the PlotRectangle:
\ *B X - The X coordinate of position where the plot will be in its desination.
\ *B Y - The Y coordinate of the plot where the plot will be in its desination.
\ *B Width - The width of the plot. It will be set bij InitDibSection: or InitBmpFile:.
\ *B Height - The height of the plot. It will be set bij InitDibSection: or InitBmpFile:.

:M SetSize: ( w h - )
\ *G Set the size of plot.
      to height to width ;M

:M GetSize: ( - w h )
\ *G Get the size of plot.
      width height ;M

:M SetXy:   ( x y - )
\ *G Set the position of plot in its desination.
      to y to x  ;M

:M GetXy:    ( - x y )
\ *G Get the position of plot in its desination.
      x y ;M

;Class



:Class 24BitsDibClass    <Super PlotRectangle
\ *G The 24BitsDibClass is able to use the fast set-mdot.
\ ** Use SetDotsTo: to point set-mdot into the DIBSection.

	int SelectedObject  \ Internal use
	int PictureBitmap   \ Internal use

	int DIBSectionDC
	int EndAdresDib
	int Bwidth
	int hdcDest
	Int Rop
	int xSrc
	int ySrc
\ *P Settings in the 24BitsDibClass:
\ *B DIBSectionDC - Contains the device context in which the plot will be made.
\ *B EndAdresDib - The last adres of the Dibsection.
\ *B Bwidth - The TOTAL width of the Dibsection.
\ *B hdcDest - Points to the destination device context.
\ *B Rop - The raster-operation code for bit BitBlt in ShowDib:.
\ *B xSrc - The X-coordinate of the source rectangle.
\ *B ySrc - The y-coordinate of the source rectangle.

cell bytes color-array


: fill-24-bits-header-DIB  ( w h total-file-size adr - )   \ 3
    2dup + to EndAdresDib
    2dup dup>r  bfSize !
    sizeof Win3DibHeader   dup rot  bfOffsetBits !
    -  r@  >BitmapInfoHeader biSizeImage !
    19778  r@   bfType w!
    r> >BitmapInfoHeader
      sizeof BITMAPINFOHEADER over biSize !
      1    over biPlanes w!
      24   over biBitCount w!
      4724 over biXPelsPerMeter !
      4724 over biYPelsPerMeter !
      0    over biClrUsed !
      0    over biClrImportant !
      swap over biHeight !
      biWidth !
 ;


: init-graph ( w h - total-file-size )   \ 2
\ biSizeImage The size of the image in bytes. This is worked out from the width, height,
\ number of bits per pixel. In a 24 bit image there are three bytes per pixel.
\ Additionally, GDI requires that every horizontal line in the image aligns on a
\ four byte boundary. So for a 24 bit image the
\ ImageSize is biWidth*biHeight*3 rounded up to the nearest four bytes.
\ You can round up to the width to the nearest four bytes as follows:
\   (.biWidth * 3 + 3) And &HFFFFFFFC
  2dup to height to width
  swap 3 * -4 and swap   \ Calculates the number of needed bytes for each line
  over to Bwidth         \ Save it for the assembler part
  2dup * #bytes/pixel *  \ The biSizeImage
  sizeof Win3DibHeader + \ Include the header
  dup>r pbmi fill-24-bits-header-DIB \ ( w h total-file-size pbmiDib - )
  r>
 ;

:M ReleaseDib:
\ *G Releases the used DIDsection.
          SelectedObject DIBSectionDC Call SelectObject drop
          PictureBitmap Call DeleteObject drop
          DIBSectionDC  call DeleteDC     drop
 ;M

:M InitDibSection: ( w h hdcDest - )     \ 1
\ *G InitDibSection: Is the first thing to do before anything else in the 24BitsDibClass.
\ ** It creates a DIBsection to which set-mdot can plot.
\ *P Notes:
\ *B A DIBsection can be reduced a window.
\ ** In that case you will have to use InitDibSection: again when you resize the window.
\ ** When you give a DIBsection the size of the whole screen then you do NOT have to
\ ** to use InitDibSection: again when you resize the window unless the resolution
\ ** of the screen has been changed.
\ *B When InitDibSection: is used again it will release the old DIDsection.
   EndAdresDib  0<>
      if  ReleaseDib: Self
      then
    to hdcDest init-graph
    0 Call CreateCompatibleDC  to DIBSectionDC
    0  0  color-array  DIB_RGB_COLORS pbmi >BitmapInfoHeader DIBSectionDC
    Call CreateDIBSection dup ?winerror  to PictureBitmap
    PictureBitmap  DIBSectionDC Call SelectObject to SelectedObject
    sizeof Win3DibHeader - color-array @ + to EndAdresDib
 ;M

:M SetRop:    ( Rop - )
\ *G Sets the raster operation for ShowDib:
      to Rop    ;M

:M SetDcDest: ( hdcDest - )
\ *G Sets the destination device context. This can be a window.
     to hdcDest ;M

:M SetXySrc: ( x y - )
\ *G Sets the x y coordinate of the plot to be shown. Default is 0 0 (=Top left)
     to ySrc to xSrc ;M

:M GetXySrc: ( - x y )
\ *G Gets the x y coordinate of the plot to be shown.
     xSrc ySrc  ;M

:M SetDotsTo: ( - )
\ *G Is needed to point set-mdot into the DIBsection.
\ ** This must be done for each thread.
     EndAdresDib _EndAdresDib !  bwidth  _BWidth !  ;M

:M ShowDib:  ( - )
\ *G Copys the DIBsection to the destination device context.
     Rop ySrc xSrc DIBSectionDC height width y x hdcDest Call BitBlt drop
 ;M


:M ClassInit:  ( -- )
\ *G To set the default settings.
       ClassInit: super  0 to EndAdresDib
       0 0 SetXySrc: Self \ Set the x and y of the source rectangle
       0 0 SetXy:    Self \ Set the x and y of the destination rectangle
       SRCCOPY     to Rop
 ;M

;Class


:Class BmpClass    <Super PlotRectangle
\ *G BmpClass is also able to use the fast set-mdot.
\ ** Several tasks can update various parts at the same time to improve the speed.
\ ** Use SetBmpDotsTo: to point set-mdot into the bitmap for each task.
\ ** Use Close: when you are finished.
\ *P Note: BmpClass may be bigger than you screen.
\ ** The limit depends on your windows system you use.


int EndAdresDib
int Bwidth
int MapHndlBmp


: fill-24-bits-header  ( w h total-file-size vadr - )    \ 3: fill the 24 bits-header
    2dup + to EndAdresDib
    2dup dup>r  bfSize !
    54 dup rot  bfOffsetBits !
    - r@ >BitmapInfoHeader biSizeImage !
    19778  r@   bfType w!
    r> >BitmapInfoHeader
      40   over biSize !
      1    over biPlanes w!
      24   over biBitCount w!
      4724 over biXPelsPerMeter !
      4724 over biYPelsPerMeter !
      swap over biHeight !
      over to bwidth biWidth !
 ;

: map-bitmap  ( name count MapHandle - )                 \ 2: map it
  dup>r open-map-file abort" Can't map BmpFile."
  r> >hfileAddress @  ;


:M InitBmpFile: ( name count width height MapHandle - )  \ 1:
\ *G InitBmpFile: Is the first thing to do before anything else in the BmpClass.
\ ** It creates a 24 bits bmp file to which set-mdot can plot.
      EndAdresDib 0=
         if   >r 2swap   2over swap #bytes/pixel * *
              -rot 2dup r/w create-file abort" Can't create the BmpHeader." >r
              rot sizeof Win3DibHeader +
              dup s>d r@ resize-file abort" Can't resize the BmpFile."
              r> close-file abort" Can't close the BmpFile."
              -rot r> dup to MapHndlBmp map-bitmap fill-24-bits-header
         else 4drop drop
         then
 ;M

:M SetBmpDotsTo:   ( - )
\ *G Point set-mdot into the bitmap.
\ ** must be done for each task
      EndAdresDib _EndAdresDib !  bwidth  _BWidth !
 ;M

:M Close:  ( -- )
\ *G Closes the new bit map file and the plot.
      MapHndlBmp close-map-file drop  0 to EndAdresDib ;M

:M ClassInit:  ( -- )  ClassInit: super 0 to EndAdresDib ;M

;Class


  (( \  Disable or delete this line to see the possible use of a Dibsection in a window

  24BitsDibClass  DibTest    \ Define a new DibSection
  0 255 0 rgb value RgbColor \ Make a color


: plot-in-dibsection ( - ) \ Be sure the plot fits in the Dibsection or write a clip support.
  150 50 do  50 i  RgbColor  set-mdot  loop   \ otherwise the plot chrashes
  350 50 do  i 50  RgbColor  set-mdot  loop

  160 40 do  40 i  RgbColor  set-mdot  loop
  360 40 do  i 40  RgbColor  set-mdot  loop

  170 30 do  30 i  RgbColor  set-mdot  loop
  370 30 do  i 30  RgbColor  set-mdot  loop

  180 20 do  20 i  RgbColor  set-mdot  loop
  380 20 do  i 20  RgbColor  set-mdot  loop

  190 10 do  10 i  RgbColor  set-mdot  loop
  390 10 do  i 10  RgbColor  set-mdot  loop

  200 0 do   0  i  RgbColor  set-mdot  loop
  400 0 do   i  0  RgbColor  set-mdot  loop
 ;

: ShowPlot ( - ) \ A testcase for a dibsection
    plot-in-dibsection    \ Make the plot
\      10 25 SetXy: DibTest \ Puts the plot in an other place than at 0 0 in the window when active.
    ShowDib:  DibTest     \ Show the plot in the window
  ;


:Object DibWindow     <Super Window

int SecondTime?

:M StartPos:  ( -- x y )   CenterWindow: Self drop 0 ;M
:M StartSize: ( -- w h )   500 250 ;M
:M MinSize:   ( - w h )    400 200 ;M   \ The minimal size for the plot
:M WindowHasMenu: ( -- f )    true ;M

: 4dropShowDib  4drop ShowDib: DibTest ;

:M WM_MOVE      ( hwnd msg wparam lparam -- res )
                4dropShowDib 0 \ Show again when moved.
 ;M                            \ Needed when the window is partly moved off the desktop.

:M On_SetFocus: ( h m w l -- ) \ Needed in older windows systems. Otherwise the plot stays incomplete
                true to have-focus? 4dropShowDib   \ when another window has been moved over the plot.
 ;M

:M On_Size:     ( l p  -- )        \ Then the bitmap must be resized
              SIZE_MINIMIZED  <>   \ InitDibSection: throws the old one away and makes a new one.
                 if  GetSize: Self GetDC: Self InitDibSection: DibTest
                     SetDotsTo: DibTest
                     ShowPlot
                 then
              drop
  ;M

:M Close:      ( h m w l -- res )  4drop   ReleaseDib: DibTest   bye 0 ;M
;Object


menubar DibWindowMenu
  popup "&File"
     menuitem "E&xit" 'X' Close: DibWindow  ;
endbar

DibWindowMenu SetMenuBar: DibWindow
: StartTest ( - )  start: DibWindow  ;

StartTest abort ))


  \s  Disable or delete this line to see the possible use for a bitmap


 BmpClass BmpTest    \ Define a new object for a bitmap


 0 255 0 rgb value RgbColor   \ Make a color

: plot-in-the-color-array ( - ) \ Be sure the plot fits in the bitmap or write a clip support.
  150 50 do  50 i  RgbColor  set-mdot  loop   \ otherwise the program chrashes
  350 50 do  i 50  RgbColor  set-mdot  loop

  160 40 do  40 i  RgbColor  set-mdot  loop
  360 40 do  i 40  RgbColor  set-mdot  loop

  170 30 do  30 i  RgbColor  set-mdot  loop
  370 30 do  i 30  RgbColor  set-mdot  loop

  180 20 do  20 i  RgbColor  set-mdot  loop
  380 20 do  i 20  RgbColor  set-mdot  loop

  190 10 do  10 i  RgbColor  set-mdot  loop
  390 10 do  i 10  RgbColor  set-mdot  loop

  200 0 do   0  i  RgbColor  set-mdot  loop
  400 0 do   i  0  RgbColor  set-mdot  loop
 ;

: TestBitmap ( - ) \ A testcase for a bitmap
  s" test.bmp" 400 200 ahndl InitBmpFile: BmpTest   \ start a file for the plot

  SetBmpDotsTo: BmpTest     \ To point the set-mdot into the file
    ahndl >hfileAddress @ dup>r >color-array   \ Get the color-array
    r> >BitmapInfoHeader biSizeImage @         \ Get it's size
    0xff fill                                  \ Make the color-array white
  plot-in-the-color-array                      \ Make the plot
  Close: BmpTest
  ;

   TestBitmap
   chdir
   dir test.bmp
   cr .( See it in paint)
   cr dos" mspaint.exe test.bmp" dos$ $exec drop

abort

\s
