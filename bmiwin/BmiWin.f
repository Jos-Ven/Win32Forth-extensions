Anew BmiWin.f \ September 14th, 2005. For Win32Forth version 6.11.04 or better.

\- textbox needs excontrols.f

needs Resources.f
needs Config.f
needs BmiGraph.f
needs bmi.f
needs bmisettings.f

 159 constant Xb
 28  constant Yb
 372 constant Xt
 240 constant Yt

 80.00e fconstant fXb  \ Left margin measured from the right
 22.00e fconstant fXr  \ Right marin

0.0e fvalue Weight

: MinMaxArea
   BmiVal 7.0e f- MinBmi fmin 0.0e fmax fto MinVal
   BmiVal MaxBmi fmax 7.0e f+ fto MaxVal
 ;

: TypeBefore ( x y adr n - x y )  2over swap 32 -  swap 12 - 2swap wtype 2drop ;
: TypeAfter  ( x y adr n - x y )  2over swap 130 + swap 12 - 2swap wtype 2drop ;
: (f.$)      ( f: n - ) ( - str count )  pad (f.) pad count ;

: $>float     \ ( adr count - f )  FS: ( - n ) \ Note: 0 on FS when f is false
   >float dup not
        if      0 s>f
        then
 ;

create bmi$      maxstring allot
create comment$  maxstring allot

: +comment$  ( adr count - )    comment$ +place ;
: +bmi$      ( adr count - )    bmi$ +place     ;

: SetPrecision ( f - f )
   fdup 100e f<
        if   3
        else 4
        then
   set-precision
 ;

: (f.$)Lim  ( f - )   SetPrecision (f.$) ;

: FillBmi$ ( f: bmi - )
     (f.$)Lim bmi$ place  s"  BMI" +bmi$  s" ." +bmi$ bmi$ +null
 ;

: ConvLbsToKG ( f: lbs - Kg )     LbsConv f*  ;
: ConvKGToLbs ( f: Kg - lbs )     LbsConv f/  ;

: StartComment ( - )
    LBs/Inches- @
       if   s" \nEnter the weight in pounds and the length in inches."
       else s" Enter the weight in kilos and the length in meters."
       then
    comment$ place comment$ +null
  ;

: InLbs?  ( - ) ( f: Kg - Kg|lbs-truncated )
    LBs/Inches- @
      if    ConvKGToLbs 1dec
      then
 ;

: +Kg$ ( f: Kg - )
   (f.$)Lim +comment$ LBs/Inches- @
      if   s"  Lbs"
      else s"  Kg"
      then
    +comment$
 ;

: BmiComment ( f: Weight - ) ( ClassifiedBmi - )
   s"  Your healthy limits are between "  +comment$
   MinWeight InLbs? SetPrecision (f.$)Lim +comment$
   s"  and " +comment$
   MaxWeight InLbs? +Kg$ s" .You are " +comment$
    case
       HealthyWeight  of s" within that range" +comment$ fdrop         endof
       TooHeavyWeight of MaxWeight InLbs? f- +Kg$       s"  too heavy" +comment$ endof
       UnderWeight    of MinWeight InLbs? fswap f- +Kg$ s"  too light" +comment$ endof
    endcase
   s" . " +comment$
   comment$ +null
 ;

: BmiMaxMinRange ( Bmi - 0|Bmi)
   fdup 0.00e 1000e fwithin not
        if fdrop 0.00e
        then
 ;

: .BmiHelp ( hOwnerWindow - )
   >r z" Fill in your weight and length.\nThen watch your BMI analysis.\nChange the settings to use other parameters."
   z" BmiHelp"
   [ MB_OK MB_ICONINFORMATION or MB_TASKMODAL or ] literal r> MessageBox
   drop
  ;

Font vFont

: InitGwindow
     Delete:    vFont
     s" MS Sans Serif" SetFaceName: vFont
     black  SetTextColor: currentDC
     FW_THIN Weight: vFont
     8 Width:   vFont
     18 Height: vFont
     Create:    vFont
     Handle:    vFont SetFont: currentDC
 \   TRANSPARENT SetBkMode: currentDC \ Makes the numbers unclear in some cases

  MinMaxArea
  159 28 372 245 white FillArea: currentDC
                          \ <xb> <yb>      <xt> <yt>
  Xb  Yb          Xt  Yt    100e  MaxVal   0e MinVal set-gwindow

 \ xr Ylevel      wr  Yh
  fXb MinVal scale
  fXr MinBmi scale ltyellow     FillArea: currentDC

  fXb AverageNormal scale 1- AverageNormal (f.$)Lim TypeBefore

  fXb MinBmi scale MinBmi (f.$)Lim TypeBefore
  fXr MaxBmi scale ltgreen      FillArea: currentDC

  fXr AverageNormal scale 1+ white    FillArea: currentDC

  fXb MaxBmi scale MaxBmi (f.$)Lim TypeBefore

  fXr MaxVal scale ltred        FillArea: currentDC

  fXb BmiVal scale 2 - BmiVal   (f.$)Lim TypeAfter
  fXr BmiVal scale 2 + ltblue   FillArea: currentDC

  ShowObese- @
    if  fXb obese scale 1- obese (f.$)Lim TypeBefore
        fXr obese scale 1+ black    FillArea: currentDC
    then
 ;

:Object FormBmi                <Super DialogWindow

Font WinFont
' 2drop value WmCommand-Func   \ function pointer for WM_COMMAND
ColorObject FrmColor      \ the background color
int parent   \ pointer to parent of form

TextBox TextBoxWeight
Label LabelWeight
Label LabelLength
TextBox TextBoxLength
PushButton ButtonCalc        \ IDOK
PushButton ButtonSettings    100 constant IdSettings
GroupBox GroupGraph
GroupBox GroupBmi
Label LabelComment
PushButton ButtonHelp        200 constant IdHelp

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
                z" BMI Calculator"
                ;M

:M StartSize:   ( -- width height )
                388 265
                ;M

:M StartPos:    ( -- x y )
                 150 175
                ;M

:M Close:        ( -- )
                \ Insert your code here
                DisableConfigFile
                Close: super
                ;M


:M On_Init:     ( -- )
                EnableConfigFile StartComment
                SingaporeCutoff
                GetHandle: Self SetParent: BMISettings
                getDC: self puthandle: CurrentDC
                s" MS Sans Serif" SetFaceName: WinFont
                8 Width: WinFont
                Create: WinFont

                \ set form color to system color
                COLOR_BTNFACE Call GetSysColor NewColor: FrmColor


                self Start: TextBoxWeight
                60 20 72 20 Move: TextBoxWeight
                Handle: Winfont SetFont: TextBoxWeight

                self Start: LabelWeight
                10 20 50 20 Move: LabelWeight
                Handle: Winfont SetFont: LabelWeight
                s" Weight:" SetText: LabelWeight

                self Start: LabelLength
                10 50 50 20 Move: LabelLength
                Handle: Winfont SetFont: LabelLength
                s" Length:" SetText: LabelLength

                self Start: TextBoxLength
                60 50 72 20 Move: TextBoxLength
                Handle: Winfont SetFont: TextBoxLength
                Lenght$ count SetText: TextBoxLength

                IdSettings SetID: ButtonSettings
                self Start: ButtonSettings
                80 197 65 23 Move: ButtonSettings
                Handle: Winfont SetFont: ButtonSettings
                s" Settings" SetText: ButtonSettings

                IDOK SetID: ButtonCalc
                self Start: ButtonCalc
                10 227 136 23 Move: ButtonCalc
                Handle: Winfont SetFont: ButtonCalc
                s" Calculate" SetText: ButtonCalc

                self Start: GroupGraph
                154 10 223 240 Move: GroupGraph  \ move: { x y w h -- }
                Handle: Winfont SetFont: GroupGraph
                s" BMI Analysis" SetText: GroupGraph

                self Start: GroupBmi
                10 80 137 111 Move: GroupBmi
                Handle: Winfont SetFont: GroupBmi
                s" BMI/Comment" SetText: GroupBmi

                self Start: LabelComment
                15 100 124 88 Move: LabelComment
                Handle: Winfont SetFont: LabelComment
                comment$ count SetText: LabelComment

                IdHelp SetID: ButtonHelp
                self Start: ButtonHelp
                10 197 65 23 Move: ButtonHelp
                Handle: Winfont SetFont: ButtonHelp
                s" Help" SetText: ButtonHelp

                ;M

: GetParameters ( - flag ) ( f: - Kg length )   \ Only valid when the button
        GetText: TextBoxWeight $>float fdup fto Weight   \ Calulate is acivated
        GetText: TextBoxLength 2dup Lenght$ place $>float and LBs/Inches- @
           if   InchConv f* fswap ConvLbsToKG fswap
           then
 ;

0.0e fvalue _Length

: (CalculateBmi) ( Kg length - )
   f2dup bmi BmiMaxMinRange fdup fto BmiVal
   fdup FillBmi$ Bmi$ count comment$ place
   fswap BmiAnalyse  Weight BmiComment
   comment$ count SetText: LabelComment
 ;

: DoButtonCalc  ( - )
    GetParameters
       if    fdup fto _Length  (CalculateBmi)
       else  fdrop fdrop 0.0e fto BmiVal \ error
       then
 ;

: GetDataCalculateBmi  Paint: Self 2drop  Weight  _Length (CalculateBmi) ;

' GetDataCalculateBmi is CalculateBmi

: DoButtonSettings  ( - )
    Start: BMISettings
 ;


: HandleButtons ( Action/Button - )
        case
          IDOK        of   DoButtonCalc                 endof
          IdSettings  of   DoButtonSettings             endof
          IdHelp      of   GetHandle: Self .BmiHelp     endof
                     0.0e fto BmiVal
        endcase
       paint: self
 ;

:M WM_COMMAND   ( h m w l -- res )
                over LOWORD ( ID ) self   \ object address on stack
                WMCommand-Func ?dup       \ must not be zero
                     if      execute drop HandleButtons
                     else    2drop        \ drop ID and object address
                     then    0
                ;M

:M SetCommand:  ( cfa -- )  \ set WMCommand function
                to WMCommand-Func
                ;M

:M On_Paint:    ( -- )
                0 0 GetSize: self Addr: FrmColor FillArea: dc
                BmiVal f0=
                   if  StartComment comment$ count SetText: LabelComment
                   then
                InitGwindow
                ;M

:M On_Done:    ( -- )
                Delete: WinFont
                \ Insert your code here
                On_Done: super
                bye
                ;M

;Object

: StartBmiWin  start: FormBmi ;

' StartBmiWin turnkey BmiWin.exe
s" bmi.ico" s" BmiWin.exe"  AddAppIcon
StartBmiWin
\s
