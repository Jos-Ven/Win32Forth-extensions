anew  -TextDialog.f

\ Some details:
\ Auto-sizes a window TextDialog depended on the number
\ of lines pointed by the word WindowText.
\ The text is not limited to 255 bytes.
\ No scrollbars.
\ A Font in a TextDialog can be changed.
\ There can be more than one TextDialog in use.

needs excontrols.f

WinDC CurrentDC
Font vFont

16 value wLineSpace  \ Vertical line space
0  value wTextlenght \ Determined in WindowText
71 value wMargin     \ For the OK button

: GetDeskTopSize ( -- w h )
   0 pad 0 spi_getworkarea Call SystemParametersInfo DROP
   pad 8 + 2@ swap
;

: MidPoint ( x y w h - mx my )     rot  + 2/  -rot  + 2/  swap  ;

: CenterAroundMidpoint { mx my w h } ( mx my w h - xl yl )
        GetDeskTopSize 40 -
        my h 2/  - 0 max
        swap h - min
        mx w 2/  - 0 max
        rot w - min
        swap
 ;

Create wTitle$  maxstring allot

\in-system-ok : _wl  ( wLineSpace - ) dup +to wTextlenght postpone literal ;

: ResetTextlenght  ( - )        0 to wTextlenght  ; immediate
: 1l     ( - )                  wLineSpace    _wl ; immediate
: 2l     ( - )                  wLineSpace 2* _wl ; immediate
: wtype  ( x y adr n - x y )    2over 2swap textout: currentDC  ;

: +l"  ( -<string">- )
      state @
          if      postpone 1l postpone + postpone (s")  ,"
          else    true abort" Use it inside definitions."
          then ; immediate

: +2l"  ( -<string">- )
      state @
          if      postpone 2l postpone + postpone (s")  ,"
          else    true abort" Use it inside definitions."
          then ; immediate


:CLASS TextDialog                <Super DialogWindow

Font WinFont
' 2drop value WmCommand-Func    \ function pointer for WM_COMMAND
ColorObject FrmColor            \ the background color
int parent                  \ pointer to parent of form. Changed into an INT
int ParentX
int ParentY
int Totheight
int Textlenght
int WindowText

PushButton Button1

:M ClassInit:   ( -- )
                ClassInit: super
                \ Insert your code here
                ;M

:M WindowStyle:  ( -- style )
               WS_POPUPWINDOW WS_DLGFRAME or WS_CHILD or 
                ;M

\ if this form is a modal form a non-zero parent must be set
:M ParentWindow:  ( -- hwndparent | 0 if no parent )
                parent
                ;M

:M SetTextlenght: ( Textlenght - )
                 to Textlenght
                 Textlenght wMargin + to Totheight
                ;M

:M SetParentPos:  ( x y hwndparent -- ) \ set owner window
                to parent to ParentY to ParentX
                ;M

:M WindowTitle: ( -- ztitle )
                z" Help"
                ;M

:M StartSize:   ( -- width height )
                322 Totheight
                ;M

:M GetPositionParent: ( -- px py pw ph )
     Parent 0>
        if      pad 16 erase
                pad Parent Call GetWindowRect ?WinError
                pad 2@ swap pad 8 + 2@ swap
         else   0 0 GetDeskTopSize  \ take the desktop when there is no parent.
         then
      ;M

:M StartPos:    ( -- x y )
                GetPositionParent: Self
                MidPoint
                StartSize: self
                CenterAroundMidpoint
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

                IDOK SetID: Button1
                self Start: Button1
                Handle: Winfont SetFont: Button1
                115 Totheight 45 - 86 37 Move: Button1
                s" Ok" SetText: Button1
                ;M

:M WM_COMMAND   ( h m w l -- res )
                over LOWORD ( ID ) self   \ object address on stack
                WMCommand-Func ?dup    \ must not be zero
                if        execute  2drop
                                close: self
                else        2drop   \ drop ID and object address
                then        0 ;M

:M SetCommand:  ( cfa -- )  \ set WMCommand function
                to WMCommand-Func
                ;M

:M On_Paint:    ( -- )
                getDC: self puthandle: CurrentDC
                s" MS Sans Serif" SetFaceName: vFont
                black  SetTextColor: currentDC
                FW_NORMAL Weight: vFont
                8 Width:   vFont
                18 Height: vFont
                Create:    vFont
                Handle:    vFont SetFont: currentDC
                TRANSPARENT SetBkMode: currentDC

                0 0 GetSize: self Addr: FrmColor FillArea: dc
                WindowText execute
                ;M

:M On_Done:    ( -- )
                Delete: WinFont
                Delete:    vFont
                CurrentDC  call DeleteDC drop
                \ Insert your code here
                On_Done: super
                ;M

: IsWindowText ( CfaText - ) to WindowText  ;


;Class


\s Demo:

: HelpText ( - ) \ contains the WindowText
   ResetTextlenght
   10 1l   s" The hibernator will try to put your PC in a hibernate" wtype ( x y adr n - x y )
      +l" state when the program in the textbox becomes one" wtype
      +l" minute inactive. If the hybernate state is not possible"       wtype
      +l" then the suspend mode is tried."                   wtype

     +2l" First enable and test the hibernate state"         wtype
      +l" of your PC without the use of this program."       wtype

     +2l" Then choose the desired parameter and put the"     wtype
      +l" parameter in the testbox."                         wtype
      +l" Press the button 'Start waiting'. to start"        wtype

     +2l" The Process Identifier (PID) can be obtained"      wtype
      +l" from the taskmanager. Sometimes you may have"      wtype
      +l" to activate an extra column to see it."            wtype

     +2l" Note: This program is depended on the reliability" wtype
      +l" and configuration of your PC."                     wtype

                Delete:    vFont                  \ Changing the font
                s" MS Sans Serif" SetFaceName: vFont
                black SetTextColor: currentDC
                FW_BOLD   Weight: vFont           \ Make it bold
                8 Width:   vFont
                18 Height: vFont
                Create:    vFont
                Handle:    vFont SetFont: currentDC
                TRANSPARENT SetBkMode: currentDC

    +2l" The use of hibernator is at your own risk."        wtype
      2drop
 ;

:OBJECT HelpDialog              <Super TextDialog
                :M WindowTitle: ( -- ztitle )
                   ['] HelpText IsWindowText
                   z" Help"
                ;M
;OBJECT

wTextlenght SetTextlenght: HelpDialog

: ShowHelpDialog ( - )    start: HelpDialog   ;


: AboutText
   ResetTextlenght

   10 1l   s" The hibernator might safe you energy costs."          wtype

     +2l" EG: A program needs much time to compute."                wtype
      +l" When it is complete the program becomes idle."            wtype
      +l" The hibernator is able to spot this and will"             wtype
      +l" try to put the PC in the hibernate state after"           wtype
      +l" one minute."                                              wtype

     +2l" Your screen and your data should not be changed"          wtype
      +l" by this action, when you activate your PC again."         wtype

     +2l" If a PC is in the hibernate state it uses no power."      wtype
      +l" When the suspend state is active the use of."             wtype
      +l" power is reduced."                                        wtype

    nip 50 swap

      +2l" The hibernator is written in Win32Forth " wtype
       +l" Version 6.11.04 by J.v.d.Ven."            wtype
    2drop
 ;

:OBJECT AboutDialog <Super TextDialog
               :M WindowTitle: ( -- ztitle )
                   ['] AboutText IsWindowText
                   z" About"
               ;M
;OBJECT

wTextlenght SetTextlenght: AboutDialog

: ShowAboutDialog ( - )    start:  AboutDialog   ;

\ \s
 ShowAboutDialog
 ShowHelpDialog

\s
