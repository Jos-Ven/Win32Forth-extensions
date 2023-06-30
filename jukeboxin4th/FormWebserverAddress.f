\ SERVERSETUP.FRM
\- textbox needs excontrols.f


:Object WebserverAddressDialog           <Super DialogWindow

Font WinFont           \ default font
' 2drop value WmCommand-Func   \ function pointer for WM_COMMAND
ColorObject FrmColor      \ the background color

\ Font setting definitions
Font Label1-font
: Set-Label1-font ( -- )
                -17          Height: Label1-font
                0             Width: Label1-font
                0        Escapement: Label1-font
                0       Orientation: Label1-font
                400          Weight: Label1-font
                0           CharSet: Label1-font
                1      OutPrecision: Label1-font
                2     ClipPrecision: Label1-font
                1           Quality: Label1-font
                34   PitchAndFamily: Label1-font
                s" MS Sans Serif" SetFacename: Label1-font ;

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

Label Label1
Label Label2
Label Label3
TextBox TextBox1
PushButton Button1
PushButton Cancel


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

:M SetParent:  ( hwndparent -- ) \ set owner window
                to hWndParent
                ;M

:M WindowTitle: ( -- ztitle )
                z" Setup server address:"
                ;M

:M StartSize:   ( -- width height )
                321 180
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


                self Start: Label1
                7 26 320 104 Move: Label1
                Set-Label1-font
                Create: Label1-font
                Handle: Label1-font SetFont: Label1
 s" Enter the missing part of the URL through which the webserver can be reached." SetText: Label1

                self Start: Label2
                7 85 40 20 Move: Label2
                Handle: Label1-font SetFont: Label2
                s" http://" SetText: Label2

                self Start: TextBox1
                50 83 150 28 Move: TextBox1
                Set-TextBox1-font
                Create: TextBox1-font
                Handle: TextBox1-font SetFont: TextBox1
                vadr-config AddressWebServer$ count SetText: TextBox1

                self Start: Label3
                203 85 115 20 Move: Label3
                Handle: Label1-font SetFont: Label3
                s" /homejb4th.html" SetText: Label3

                IDOK SetID: Button1
                self Start: Button1
                50 140 100 25 Move: Button1
                Handle: Winfont SetFont: Button1
                s" OK" SetText: Button1

                IDCANCEL SetID: Cancel
                self Start: Cancel
                163 140 100 25 Move: Cancel
                Handle: Winfont SetFont: Cancel
                s" Cancel" SetText: Cancel

                ;M

:M On_Paint:    ( -- )
                0 0 GetSize: self Addr: FrmColor FillArea: dc
                ;M

:M On_Done:    ( -- )
                Delete: WinFont
                Delete: Label1-font
                Delete: TextBox1-font
                \ Insert your code here, e.g delete fonts, any bitmaps etc.
                On_Done: super
                ;M

;Object
