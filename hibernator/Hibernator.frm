\ HIBERNATOR.FRM
\- textbox needs excontrols.f


:Object LblHibernater                <Super DialogWindow

Font WinFont
' 2drop value WmCommand-Func   \ function pointer for WM_COMMAND
ColorObject FrmColor      \ the background color 
0 value parent   \ pointer to parent of form

Label LblFirstLine
Label LblHibernate
TextBox TextBox1
PushButton bStartWaiting
PushButton bAbortWaiting
GroupBox LblParameter
RadioButton Radio1
RadioButton Radio2
PushButton bHelp

:M ClassInit:   ( -- )
                ClassInit: super
                \ Insert your code here
                ;M

:M WindowStyle:  ( -- style )
                WS_POPUPWINDOW WS_DLGFRAME or 
                ;M

\ if this form is a modal form a non-zero parent must be set
:M ParentWindow:  ( -- hwndparent | 0 if no parent )
                parent
                ;M

:M SetParent:  ( hwndparent -- ) \ set owner window
                to parent
                ;M

:M WindowTitle: ( -- ztitle )
                z" Hibernater"
                ;M

:M StartSize:   ( -- width height )
                459 237
                ;M

:M StartPos:    ( -- x y )
                150 175
                ;M

:M Close:        ( -- )
                \ Insert your code here
                Close: super
                ;M

:M On_Init:     ( -- )
                s" MS Sans Serif" SetFaceName: WinFont
                8 Width: WinFont
                Create: WinFont

                \ set form color to system color
                COLOR_BTNFACE Call GetSysColor NewColor: FrmColor


                self Start: LblFirstLine
                30 130 412 20 Move: LblFirstLine
                Handle: Winfont SetFont: LblFirstLine
                s" 17-8-2005 22:07:58 Waiting for Sony Sound Forge 7.0" SetText: LblFirstLine

                self Start: LblHibernate
                33 155 402 14 Move: LblHibernate
                Handle: Winfont SetFont: LblHibernate
                s" 17-8-2005 22:08:00 Starting the hibernate state." SetText: LblHibernate

                self Start: TextBox1
                30 90 407 23 Move: TextBox1
                Handle: Winfont SetFont: TextBox1

                self Start: bStartWaiting
                175 185 100 37 Move: bStartWaiting
                Handle: Winfont SetFont: bStartWaiting
                s" Start waiting" SetText: bStartWaiting

                self Start: bAbortWaiting
                50 187 99 34 Move: bAbortWaiting
                Handle: Winfont SetFont: bAbortWaiting
                s" Abort waiting" SetText: bAbortWaiting

                self Start: LblParameter
                30 10 372 63 Move: LblParameter
                Handle: Winfont SetFont: LblParameter
                s" Used parameter:" SetText: LblParameter

                self Start: Radio1
                50 27 277 24 Move: Radio1
                Handle: Winfont SetFont: Radio1
                s" Enter a unique part of the window name." SetText: Radio1

                self Start: Radio2
                50 50 227 16 Move: Radio2
                Handle: Winfont SetFont: Radio2
                s" Enter the PID of a process." SetText: Radio2

                self Start: bHelp
                296 184 99 35 Move: bHelp
                Handle: Winfont SetFont: bHelp
                s" Help" SetText: bHelp

                ;M

:M WM_COMMAND   ( h m w l -- res )
                over LOWORD ( ID ) self   \ object address on stack
                WMCommand-Func ?dup    \ must not be zero
                if        execute
                else        2drop   \ drop ID and object address
                then        0 ;M

:M SetCommand:  ( cfa -- )  \ set WMCommand function
                to WMCommand-Func
                ;M

:M On_Paint:    ( -- )
                0 0 GetSize: self Addr: FrmColor FillArea: dc
                ;M

:M On_Done:    ( -- )
                Delete: WinFont
                \ Insert your code here
                On_Done: super
                ;M

;Object
