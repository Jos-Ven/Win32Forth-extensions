\ INFOFORM.FRM
\- textbox needs excontrols.f


:Object InfoForm                <Super Window

Font WinFont           \ default font
' 2drop value WmCommand-Func   \ function pointer for WM_COMMAND
ColorObject FrmColor      \ the background color

Label Label1
Label Label2
Label Label3
Label Label4
TextBox TextBox1
TextBox TextBox2
TextBox TextBox3
TextBox TextBox4
PushButton Button1
PushButton Button2


:M ClassInit:   ( -- )
                ClassInit: super
                +dialoglist  \ allow handling of dialog messages
                \ 689  to id     \ set child id, changeable
                \ Insert your code here, e.g initialize variables, values etc.
                ;M

:M Display:     ( -- ) \ unhide the child window
                SW_SHOWNORMAL Show: self ;M

:M Hide:        ( -- )   \ hide the...aughhh but you know that!
                SW_HIDE Show: self ;M

:M WindowTitle: ( -- ztitle )
                z" InfoForm"
                ;M

:M StartSize:   ( -- width height )
                597 193
                ;M

:M StartPos:    ( -- x y )
                CenterWindow: Self
                ;M

:M WindowStyle:  ( -- style )
                WS_POPUPWINDOW WS_DLGFRAME or
                ;M

:M Close:        ( -- )
                \ Insert your code here, e.g any data entered in form that needs to be saved
                Close: super
                ;M

:M WM_COMMAND   ( h m w l -- res )
                over LOWORD ( ID ) self   \ object address on stack
                WMCommand-Func ?dup    \ must not be zero
                if    execute
                then  2drop  0  ;M

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
                20 22 54 25 Move: Label1
                Handle: Winfont SetFont: Label1
                s" Artist:" SetText: Label1

                self Start: Label2
                20 49 54 25 Move: Label2
                Handle: Winfont SetFont: Label2
                s" Album:" SetText: Label2

                self Start: Label3
                20 76 54 25 Move: Label3
                Handle: Winfont SetFont: Label3
                s" Song:" SetText: Label3

                self Start: Label4
                20 103 54 25 Move: Label4
                Handle: Winfont SetFont: Label4
                s" Location:" SetText: Label4


                self Start: TextBox1
                79 22 494 25 Move: TextBox1
                Handle: Winfont SetFont: TextBox1

   last-selected -1 =
     if    pfilename$ count ExtractRecord InlineRecord
     else  last-selected
     then  dup  \ - Record adres
                CountedArtist SetText: TextBox1
                self Start: TextBox2
                79 49 494 25 Move: TextBox2
                Handle: Winfont SetFont: TextBox2
            dup CountedAlbum SetText: TextBox2

                self Start: TextBox3
                79 76 494 25 Move: TextBox3
                Handle: Winfont SetFont: TextBox3
             dup  CountedTitle SetText: TextBox3

                self Start: TextBox4
                79 103 494 24 Move: TextBox4
                Handle: Winfont SetFont: TextBox4
                PathSong  SetText: TextBox4

                self Start: Button1
                275 144 100 25 Move: Button1
                Handle: Winfont SetFont: Button1
                s" Cancel" SetText: Button1

                self Start: Button2
                150 144 100 25 Move: Button2
                Handle: Winfont SetFont: Button2
                s" Explore" SetText: Button2
                ;M

:M On_Paint:    ( -- )
                0 0 GetSize: self Addr: FrmColor FillArea: dc
                ;M

:M On_Done:    ( -- )
                Delete: WinFont
                \ Insert your code here, e.g delete fonts, any bitmaps etc.
                On_Done: super
                ;M

;Object
