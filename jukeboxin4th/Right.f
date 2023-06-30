anew -Right
\- textbox needs excontrols.f
\- usebitmap needs bitmap.f


:Object Right                <Super Child-Window

' 2drop value WmCommand-Func   \ function pointer for WM_COMMAND
ColorObject FrmColor      \ the background color
int StartValue
BitmapButton Button1
BitmapButton Button2
BitmapButton Button3
BitmapButton Button4
BitmapButton Button5
BitmapButton Button6
ttPushButton Button7
ttPushButton Button8

Font WinFont           \ default font
: Set-Win-font ( -- ) Set-Win-font ;

:M ClassInit:   ( -- )
                ClassInit: super
                +dialoglist  \ allow handling of dialog messages
                687  to id     \ set child id, changeable
                \ Insert your code here, e.g initialize variables, values etc.
                ;M

:M Display:     ( -- ) \ unhide the child window
                SW_SHOWNORMAL Show: self ;M

:M Hide:        ( -- )   \ hide the...aughhh but you know that!
                SW_HIDE Show: self ;M

\ :M WindowStyle: ( -- style ) WindowStyle: Super WS_CLIPCHILDREN or ;M

\ :M StartSize:   ( -- width height )
\                50 260
\                ;M

:M On_Paint:    ( -- ) 0 0 GetSize: self Addr: dkgray FillArea: dc ;M

:M Close:        ( -- )
                \ Insert your code here, e.g any data entered in form that needs to be saved
                Close: super
                ;M


:M WM_COMMAND   ( h m w l -- res )
                over LOWORD ( ID ) self   \ object address on stack
                WMCommand-Func ?dup       \ must not be zero
                if    execute
                then  2drop   0  ;M

:M SetCommand:  ( cfa -- )  \ set WMCommand function
                to WMCommand-Func
                ;M

:M On_Init:     ( -- )
         \ prevent flicker in window on sizing
          CS_DBLCLKS GCL_STYLE hWnd  Call SetClassLong  drop
                _up usebitmap   \ create bitmap handle
                GetDc: self   dup>r CreateDIBitmap to upbitmap
                _scrldn usebitmap r@ CreateDIBitmap to downbitmap

                _first usebitmap r@ CreateDIBitmap to firstbitmap
                _last  usebitmap r@ CreateDIBitmap to lastbitmap
                _right usebitmap r@ CreateDIBitmap to rightbitmap
              _RightUp usebitmap r@ CreateDIBitmap to RightUpbitmap
            _RightDown usebitmap r@ CreateDIBitmap to RightDownbitmap
                 _Left usebitmap r@ CreateDIBitmap to Leftbitmap
            _LeftBelow usebitmap r@ CreateDIBitmap to LeftBelowBitmap
              _Shuffle usebitmap r@ CreateDIBitmap to ShuffleBitmap
                 _Sort usebitmap r@ CreateDIBitmap to SortBitmap

                r> ReleaseDc: self

               Set-Win-font Create: WinFont


                \ set form color to system color
                COLOR_BTNFACE Call GetSysColor NewColor: FrmColor


                self Start: Button1
                5 10 40 25 Move: Button1
                firstbitmap SetBitmap: Button1

                self Start: Button2
                5 50 40 25 Move: Button2
                upbitmap SetBitmap: Button2

                self Start: Button3
                5 90 40 25 Move: Button3
                downbitmap SetBitmap: Button3

                self Start: Button4
                5 130 40 25 Move: Button4
                lastbitmap SetBitmap: Button4

                self Start: Button5
                5 170 40 25 Move: Button5
                ShuffleBitmap SetBitmap: Button5

                self Start: Button6
                5 210 40 25 Move: Button6
                SortBitmap SetBitmap: Button6

\                self Start: Button7
\                5 250 40 25 Move: Button7
\                Handle: Winfont SetFont: Button7
\                s" More" SetText: Button7


                self Start: Button7
                5 250 40 25 Move: Button7
                Handle: WinFont SetFont: Button7
                s" Info" SetText: Button7

                self Start: Button8
                5 290 40 25 Move: Button8
                Handle: Winfont SetFont: Button8
                s" #Req" SetText: Button8
                ;M

:M On_Done:    ( -- )
                Delete: WinFont
                \ Insert your code here, e.g delete fonts, any bitmaps etc.
                upbitmap ?dup
                if      Call DeleteObject drop
                        0 to upbitmap
                then    downbitmap ?dup
                if      Call DeleteObject drop
                        0 to downbitmap
                then    On_Done: super
                On_Done: super
                ;M

;Object


 \ 0 start: Right
