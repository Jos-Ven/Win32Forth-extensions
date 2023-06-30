\ Middle.f
\- textbox needs excontrols.f

:Class ttCheckBox	<Super CheckBox \ for version 6.14

:M ToolString:  ( addr cnt -- )
		binfo place
		binfo count \n->crlf
                ;M

;Class


:Class AutoComboListBox 	<super  ComboListBoxExtra

:M On_MouseMove: ( -- )
      RemoveSelection: TopPane.TextBox1
      ShowDropDown: Self
 ;M

;Class

:Object Middle                <Super Child-Window

' 2drop value WmCommand-Func   \ function pointer for WM_COMMAND
ColorObject FrmColor      \ the background color

BitmapButton Button1
BitmapButton Button2
BitmapButton Button3
BitmapButton Button4
BitmapButton Button5
ttPushButton Button6
AutoComboListBox CmbListMore


GroupBox Group1
ttCheckBox Check1

Font WinFont           \ default font


: Set-Win-font ( -- )  Set-Win-font ;


: SaveCheck  ( -- )
    IsButtonChecked?: Check1 vadr-config s_FromCollection- c!
 ;


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


:M StartSize:   ( -- width height )
                49 350
                ;M

:M Close:        ( -- )
                \ Insert your code here, e.g any data entered in form that needs to be saved
                Close: super
                ;M

:M WM_COMMAND   ( h m w l -- res )
                 over LOWORD ( ID ) dup ID_Check1 =
                   if    drop SaveCheck
                   else  2 pick  ID_CmbListMore CBN_SELCHANGE word-join =
                           if     drop DoCmbListMore
                           else   self   WMCommand-Func  ?dup
                                if  execute
                                then
                           then
                   then  2drop  0  ;M

:M SetCommand:  ( cfa -- )  \ set WMCommand function
                to WMCommand-Func
                ;M

:M On_Init:     ( -- )
\ Bitmaps for buttons are loaded in ButtonsRight.f
\ prevent flicker in window on sizing
          CS_DBLCLKS GCL_STYLE hWnd  Call SetClassLong  drop

          Set-Win-font Create: WinFont

          COLOR_BTNFACE Call GetSysColor NewColor: FrmColor

                ID_CmbListMore SetID: CmbListMore
                       self Start: CmbListMore
                5 10 40 25  Move: CmbListMore
                Handle: Winfont SetFont: CmbListMore
                SplitterWindow.Width 2/ SetDroppedWidth: CmbListMore


                self Start: Button1
                5 50 40 25 Move: Button1
                rightupbitmap SetBitmap: Button1

                self Start: Button2
                5 90 40 25 Move: Button2
                rightbitmap SetBitmap: Button2


                self Start: Button3
                5 130 40 25 Move: Button3
                Handle: WinFont SetFont: Button3
                RightDownBitmap SetBitmap: Button3

                self Start: Button4
                5 170 40 25 Move: Button4
                leftbitmap SetBitmap: Button4

                 self Start: Button5
                 5 210 40 25 Move: Button5
                 LeftBelowBitmap SetBitmap: Button5

                self Start: Group1
                2 235 46 88 Move: Group1
                Handle: WinFont SetFont: Group1

                       ID_Check1 SetId: Check1
                            self Start: Check1
                      7 252
                      winxp?
                        if     36
                        else   35
                        then   25 Move: Check1
              Handle: WinFont SetFont: Check1
                       s" -->" SetText: Check1
vadr-config s_FromCollection- c@ Check: Check1

                self Start: Button6
                winxp?
                        if   7 288 37
                        else 6 288 36
                        then 25 Move: Button6
                Handle: WinFont SetFont: Button6
                s" Rnd" SetText: Button6

                ;M

:M On_Paint:    ( -- ) 0 0 GetSize: self Addr: dkgray FillArea: dc
                       SplitterWindow.Width 2/ SetDroppedWidth: CmbListMore
                ;M



:M On_Done:    ( -- )
                Delete: WinFont
                \ Insert your code here, e.g delete fonts, any bitmaps etc.
                On_Done: super
                ;M


;Object



\ 0 start: Middle
