\ FormWiFi.f


:Object FormWiFi                <Super DialogWindow

Font WinFont           \ default font
' 2drop value WmCommand-Func   \ function pointer for WM_COMMAND
ColorObject FrmColor      \ the background color

\ Font setting definitions
Font TextBox1-font
: Set-TextBox1-font ( -- )
                -17          Height: TextBox1-font
                0             Width: TextBox1-font
                0        Escapement: TextBox1-font
                0       Orientation: TextBox1-font
                400          Weight: TextBox1-font
                0           CharSet: TextBox1-font
                1      OutPrecision: TextBox1-font
                2     ClipPrecision: TextBox1-font
                1           Quality: TextBox1-font
                34   PitchAndFamily: TextBox1-font
                s" MS Sans Serif" SetFacename: TextBox1-font ;

Font TextBox2-font
: Set-TextBox2-font ( -- )
                -17          Height: TextBox2-font
                0             Width: TextBox2-font
                0        Escapement: TextBox2-font
                0       Orientation: TextBox2-font
                400          Weight: TextBox2-font
                0           CharSet: TextBox2-font
                1      OutPrecision: TextBox2-font
                2     ClipPrecision: TextBox2-font
                1           Quality: TextBox2-font
                34   PitchAndFamily: TextBox2-font
                s" MS Sans Serif" SetFacename: TextBox2-font ;

Font Label3-font
: Set-Label3-font ( -- )
                -17          Height: Label3-font
                0             Width: Label3-font
                0        Escapement: Label3-font
                0       Orientation: Label3-font
                400          Weight: Label3-font
                0           CharSet: Label3-font
                1      OutPrecision: Label3-font
                2     ClipPrecision: Label3-font
                1           Quality: Label3-font
                34   PitchAndFamily: Label3-font
                s" MS Sans Serif" SetFacename: Label3-font ;

TextBox TextBox1
Label Label1
Label Label2
TextBox TextBox2
PushButton Button1
PushButton Button2
Label Label3


:M ClassInit:   ( -- )
                ClassInit: super
                \ Insert your code here, e.g initialize variables, values etc.
                ;M

:M WindowStyle:  ( -- style )
                WS_POPUPWINDOW WS_DLGFRAME or
                ;M

\ N.B if this form is a modal form a non-zero parent must be set
:M ParentWindow:  ( -- hwndparent | 0 if no parent )
                hWndParent
                ;M

:M WindowTitle: ( -- ztitle )
                z" WiFi Properties"
                ;M

:M StartSize:   ( -- width height )
                368 233
                ;M

:M StartPos:    ( -- x y )
                CenterWindow: Self
                ;M

:M Close:        ( -- )
                \ Insert your code here, e.g any data entered in form that needs to be saved
                Close: super
                ;M

:M WM_COMMAND   ( h m w l -- res )
                dup 0=      \ id is from a menu if lparam is zero
                if        over LOWORD CurrentMenu if dup DoMenu: CurrentMenu then
                          CurrentPopup if dup DoMenu: CurrentPopup then drop
                else	  over LOWORD ( ID ) self   \ object address on stack
                          WMCommand-Func ?dup    \ must not be zero
                          if        execute
                          else    2drop   \ drop ID and object address
                          then
                then      0 ;M

:M SetCommand:  ( cfa -- )  \ set WMCommand function
                to WMCommand-Func
                ;M

:M On_Init:     ( -- )
                s" MS Sans Serif" SetFaceName: WinFont
                8 Width: WinFont
                Create: WinFont

                \ set form color to system color
                COLOR_BTNFACE Call GetSysColor NewColor: FrmColor


                self Start: TextBox1
                93 70 238 28 Move: TextBox1
                Set-TextBox1-font
                Create: TextBox1-font
                Handle: TextBox1-font SetFont: TextBox1
                vadr-config WiFiName$ count SetText: TextBox1


                self Start: Label1
                23 70 42 22 Move: Label1
                Handle: Winfont SetFont: Label1
                s" Name:" SetText: Label1

                self Start: Label2
                23 119 51 22 Move: Label2
                Handle: Winfont SetFont: Label2
                s" Password:" SetText: Label2

                self Start: TextBox2
                92 119 238 26 Move: TextBox2
                Set-TextBox2-font
                Create: TextBox2-font
                Handle: TextBox2-font SetFont: TextBox2
                vadr-config WiFiPassword$ count SetText: TextBox2


                self Start: Button1
                93 177 100 25 Move: Button1
                Handle: Winfont SetFont: Button1
                s" Ok" SetText: Button1

                self Start: Button2
                220 179 100 25 Move: Button2
                Handle: Winfont SetFont: Button2
                s" Cancel" SetText: Button2

                self Start: Label3
                93 13 238 39 Move: Label3
                Set-Label3-font
                Create: Label3-font
                Handle: Label3-font SetFont: Label3
                s" The following proporties will be visible in the cover window:" SetText: Label3

                ;M

:M On_Paint:    ( -- )
                0 0 GetSize: self Addr: FrmColor FillArea: dc
                ;M

:M On_Done:    ( -- )
                Delete: WinFont
                Delete: TextBox1-font
                Delete: TextBox2-font
                Delete: Label3-font
                \ Insert your code here, e.g delete fonts, any bitmaps etc.
                On_Done: super
                ;M

;Object
