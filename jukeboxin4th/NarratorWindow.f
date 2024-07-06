\ SETTINGSNARRATOR.FRM
\- textbox needs excontrols.f


false value TestingTts

: WaitForTts   ( - )  \ No Looping for the mouse is needed since it
   h_ev_h_ev_tts_done event-wait  \ the tts runs on a separate thread
 ;


: WaitTestTtsLoop   ( n - )
   0
    do  winpause 50 ms  TestingTts not
        if   leave
        then
    loop
 ;

: WaitState  ( - )      true  to busy? wait-cursor ;
: ReadyState ( - )      false to busy? arrow-cursor ;
: NotBusy?   ( - flag ) busy? not ;
: StopTestTts ( -- ) false to TestingTts ;

: DoTestTts     ( -- )
    Pausing? not dup
      if   true to busy? PausePlay 300 ms
      then
    True to TestingTts  volume@  drop
    vadr-config ttsVolume c@  5 * dup volume!
    ToSay{ s" This is the JukeBox In 4Th, test." }Say
          begin  ToSay{ s" Move the sliders, listen, and hit OK when ready." }Say
                 75 WaitTestTtsLoop
                 TestingTts not
           until
    ToSay{ s" End of test." }Say \ WaitForTts
    655 / dup volume!
       if  300 ms  mp vlc-play
           false to busy?
       then
 ;

: TestTts            ( -- )
     TestingTts
       if    false to TestingTts
       else   NotBusy?
                if   ['] DoTestTts Submit: JukeBoxTasks
                then
       then
 ;

20 constant RangeVolBar

defer pitch!
defer VoiceRate!
defer ttsVolume!

:Class VertTrackBarNum	<super TrackBar

:M WindowStyle: ( -- style )     WindowStyle: super TBS_VERT or ;M
:M ToolString:  ( addr cnt -- )  binfo place  binfo count \n->crlf  ;M
:M Release:     ( --  )          disable: self  enable: Self ;M

;Class


:Class vTrackBarNum	<super VertTrackBarNum

:M SetVolume:   ( -- )   RangeVolBar   GetValue: Self -  5 * dup mp-volume! ;M
:M WM_LBUTTONUP { --  }  Release: Self   SetVolume: Self   ;M
:M WM_MOUSEMOVE ( h m w l -- res ) WM_MOUSEMOVE WM: Super  SetVolume: Self ;M

;Class

:Class PitchNarratorTrackBarNum	<super VertTrackBarNum

:M SetPitch:   ( -- )  10 GetValue: Self - pitch!  ;M
:M WM_LBUTTONUP { --  } Release: Self   SetPitch: Self ;M
:M WM_MOUSEMOVE ( h m w l -- res ) WM_MOUSEMOVE WM: Super  SetPitch: Self ;M

;Class

:Class RateNarratorTrackBarNum	<super VertTrackBarNum

:M SetRate:   ( -- )  5 GetValue: Self -  dup
                      VoiceRate!  cpVoice->SetRate  drop
 ;M

:M WM_LBUTTONUP { --  } Release: Self   SetRate: Self ;M
:M WM_MOUSEMOVE ( h m w l -- res ) WM_MOUSEMOVE WM: Super  SetRate: Self ;M

;Class


:Class VolNarratorTrackBarNum	<super VertTrackBarNum

:M SetVolume:   ( -- )  20 GetValue: Self - ttsVolume! ;M
:M WM_LBUTTONUP { --  } Release: Self   SetVolume: Self ;M
:M WM_MOUSEMOVE ( h m w l -- res ) WM_MOUSEMOVE WM: Super  SetVolume: Self ;M

;Class

:Object NarratorWindow                <Super DialogWindow
VolNarratorTrackBarNum   TrackBarVol
PitchNarratorTrackBarNum TrackBarPitch
RateNarratorTrackBarNum  TrackBarRate

Font WinFont           \ default font
' 2drop value WmCommand-Func   \ function pointer for WM_COMMAND
ColorObject FrmColor      \ the background color

Label Label1
Label Label2
Label Label3
Label Label4
Label Label5
Label Label6
GroupBox Group1
PushButton Button1
PushButton Button2
RadioButton Radio1
RadioButton Radio2
RadioButton Radio3


:M ClassInit:   ( -- )
                ClassInit: super
                +dialoglist  \ allow handling of dialog messages
              \  693  to id     \ set child id, changeable
                \ Insert your code here, e.g initialize variables, values etc.
                ;M

:M Display:     ( -- ) \ unhide the child window
                SW_SHOWNORMAL Show: self ;M

:M Hide:        ( -- )   \ hide the...aughhh but you know that!
                SW_HIDE Show: self ;M

:M WindowTitle: ( -- ztitle )
                z" Settings Narrator"
                ;M

:M StartSize:   ( -- width height )
                359 205
                ;M

:M WindowStyle: ( -- style )
                WS_CAPTION WS_POPUPWINDOW or
                ;M


:M StartPos:    ( -- x y )
                CenterWindow: Self
                ;M


:M WM_COMMAND   ( h m w l -- res )
                over LOWORD ( ID ) self   \ object address on stack
                WMCommand-Func ?dup    \ must not be zero
                if    execute
                then  2drop   0  ;M


:M SetCommand:  ( cfa -- )  \ set WMCommand function
                to WMCommand-Func
                ;M

:M On_Init:     ( -- )
                s" MS Sans Serif" SetFaceName: WinFont
                8 Width: WinFont
                Create: WinFont

                \ set form color to system color
                COLOR_BTNFACE Call GetSysColor NewColor: FrmColor

                self Start: Group1
                244 5 102 115 Move: Group1
                Handle: Winfont SetFont: Group1
                s" Announce time:" SetText: Group1

                self Start: Radio1
                256 28 77 26 Move: Radio1
                Handle: Winfont SetFont: Radio1
                s" Never" SetText: Radio1

                self Start: Radio2
                256 58 77 24 Move: Radio2
                Handle: Winfont SetFont: Radio2
                s" Always" SetText: Radio2

                self Start: Radio3
                256 88 77 25 Move: Radio3
                Handle: Winfont SetFont: Radio3
                s" 30 minutes" SetText: Radio3

                self Start: Label1
                6 186 56 25 Move: Label1
                Handle: Winfont SetFont: Label1
                SS_CENTER +Style: Label1
                s" Pitch" SetText: Label1

                self Start: Label2
                79 186 68 25 Move: Label2
                Handle: Winfont SetFont: Label2
                SS_CENTER +Style: Label2
                s" Rate" SetText: Label2

                self Start: Label3
                164 186 68 25 Move: Label3
                Handle: Winfont SetFont: Label3
                SS_CENTER +Style: Label3
                s" Volume" SetText: Label3

                self Start: Button1
                256 125 80 25 Move: Button1
                Handle: Winfont SetFont: Button1
                s" Test On/Off" SetText: Button1

                self Start: Button2
                256 158 80 25 Move: Button2
                Handle: Winfont SetFont: Button2
                s" Ok" SetText: Button2

	        TBS_AUTOTICKS  AddStyle: TrackBarPitch
                self Start: TrackBarPitch
                21 30 25 155  Move: TrackBarPitch
                0 10 false SetRange: TrackBarPitch
                10 vadr-config pitch c@ - SetValue: TrackBarPitch

	        TBS_AUTOTICKS  AddStyle: TrackBarRate
                self Start: TrackBarRate
                100 30 25 155  Move: TrackBarRate
                0 10 false SetRange: TrackBarRate
                10 5 vadr-config VoiceRate c@  cVal + - SetValue: TrackBarRate

	        TBS_AUTOTICKS  AddStyle: TrackBarVol
                self Start: TrackBarVol
                179 30 25 155  Move: TrackBarVol
                0 RangeVolBar false SetRange: TrackBarVol
                RangeVolBar vadr-config ttsVolume c@ - SetValue: TrackBarVol

                self Start: Label4
                11 14 40 25 Move: Label4
                Handle: Winfont SetFont: Label4
                SS_CENTER +Style: Label4
                vadr-config  pitch c@ (l.int) SetText: Label4

                self Start: Label5
                76 14 68 25 Move: Label5
                Handle: Winfont SetFont: Label5
                SS_CENTER +Style: Label5
                vadr-config  VoiceRate c@ cVal (l.int) SetText: Label5

                self Start: Label6
                153 14 68 25 Move: Label6
                Handle: Winfont SetFont: Label6
                SS_CENTER +Style: Label6
                vadr-config  ttsVolume c@ (l.int) SetText: Label6

                vadr-config TellTime- c@
                 case
                      0 of Check: Radio1 endof
                      1 of Check: Radio2 endof
                      2 of Check: Radio3 endof
                 endcase
               ;M

:M On_Paint:    ( -- )
                0 0 GetSize: self Addr: FrmColor FillArea: dc
                ;M

: SaveRadioButtons ( -- )
   IsButtonChecked?: Radio1  if  0  then
   IsButtonChecked?: Radio2  if  1  then
   IsButtonChecked?: Radio3  if  2  then
   vadr-config TellTime-  c!

 ;

:M Close:        ( -- )
                \ Insert your code here, e.g any data entered in form that needs to be saved
                SaveRadioButtons StopTestTts
                Close: super
                ;M

:M On_Done:    ( -- )
                Delete: WinFont
                \ Insert your code here, e.g delete fonts, any bitmaps etc.
                On_Done: super
                ;M

;Object

: CloseNarratorWindow ( -- )
    Close: NarratorWindow
 ;

: SetPitch! ( n  -- )
   dup vadr-config  pitch c!  (l.int) SetText: NarratorWindow.Label4
   Paint: NarratorWindow.Label4
 ; ' SetPitch! is pitch!

: SetVoiceRate! ( n  -- )
   dup vadr-config  VoiceRate c!  (l.int) SetText: NarratorWindow.Label5
   Paint: NarratorWindow.Label5
 ; ' SetVoiceRate! is VoiceRate!

: SettsVolume! ( n  -- )
   dup vadr-config  ttsVolume c!  5 *
   dup (l.int) SetText: NarratorWindow.Label6
   TestingTts
     if     dup volume!
     else   drop
     then
   Paint: NarratorWindow.Label6
 ; ' SettsVolume! is ttsVolume!
