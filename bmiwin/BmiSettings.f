\ BMISETTINGS.FRM
\- textbox needs excontrols.f

defer CalculateBmi

:Object BMISettings                <Super DialogWindow

Font WinFont
' 2drop value WmCommand-Func   \ function pointer for WM_COMMAND
ColorObject FrmColor      \ the background color
int parent   \ pointer to parent of form

GroupBox Options
GroupBox Units
RadioButton KG/Meters
RadioButton LBs/Inches
Label LabelOr
CheckBox SingCutoff
CheckBox ShowObese
PushButton SettingsOk

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

:M SetParent:  ( hwndparent -- ) \ set owner window
                to parent
                ;M

:M WindowTitle: ( -- ztitle )
                z" BMI Settings"
                ;M

:M StartSize:   ( -- width height )
                328 184
                ;M

:M StartPos:    ( -- x y )
                \ StartPos: FormBmi 20 20 d+
                150 175 40 40 d+
                ;M

:M Close:        ( -- )
                Delete: WinFont
                \ Insert your code here
                Close: super
                ;M

:M On_Init:     ( -- )
                s" MS Sans Serif" SetFaceName: WinFont
                8 Width: WinFont
                Create: WinFont

                \ set form color to system color
                COLOR_BTNFACE Call GetSysColor NewColor: FrmColor


                self Start: Options
                160 20 165 113 Move: Options
                Handle: Winfont SetFont: Options
                s" Options" SetText: Options

                self Start: Units
                20 20 126 113 Move: Units
                Handle: Winfont SetFont: Units
                s" Units" SetText: Units

                self Start: KG/Meters
                30 40 102 27 Move: KG/Meters
                Handle: Winfont SetFont: KG/Meters
                s" KG / Meters" SetText: KG/Meters


                self Start: LBs/Inches
                30 90 101 35 Move: LBs/Inches
                Handle: Winfont SetFont: LBs/Inches
                s" LBs / Inches" SetText: LBs/Inches

                LBs/Inches- @
                   if    CheckButton:  LBs/Inches
                   else  CheckButton:  KG/Meters
                   then

                self Start: LabelOr
                70 70 23 20 Move: LabelOr
                Handle: Winfont SetFont: LabelOr
                s" Or" SetText: LabelOr

                self Start: SingCutoff
                170 40 147 46 Move: SingCutoff
                Handle: Winfont SetFont: SingCutoff
                s" Use Singapore cutoff" SetText: SingCutoff
                SingCutoff- @
                   if   CheckButton: SingCutoff
                   then

                self Start: ShowObese
                170 90 108 30 Move: ShowObese
                Handle: Winfont SetFont: ShowObese
                s" Show obese" SetText: ShowObese
                ShowObese- @
                   if   CheckButton: ShowObese
                   then

                IDOK SetID: SettingsOk
                self Start: SettingsOk
                160 150 59 24 Move: SettingsOk
                Handle: Winfont SetFont: SettingsOk
                s" Ok" SetText: SettingsOk

                ;M

: GetSettingsForm  ( - )
   IsButtonChecked?: LBs/Inches  LBs/Inches- !
   IsButtonChecked?: SingCutoff  SingCutoff- !
   IsButtonChecked?: ShowObese   ShowObese-  !
 ;

: HandleSettings  ( Action/Button - )
                IDOK =
                     if   GetSettingsForm close: Self
                     then
 ;

:M WM_COMMAND   ( h m w l -- res )
                over LOWORD ( ID ) self   \ object address on stack
                WMCommand-Func ?dup    \ must not be zero
                     if      execute drop HandleSettings
                     else    2drop        \ drop ID and object address
                     then    0 ;M

:M SetCommand:  ( cfa -- )  \ set WMCommand function
                to WMCommand-Func
                ;M

:M On_Paint:    ( -- )
                0 0 GetSize: Self Addr: FrmColor FillArea: dc
                ;M

:M On_Done:    ( -- )
                \ Insert your code here
                On_Done: super
\                CalculateBmi \ Runs into some kind of bug at SetText: LabelResult
                ;M

;Object

\s
