\ ForthForm generated splitter-window template

Anew Jukebox4Win
\- textbox needs excontrols.f

create NoTooltip$ 1 c, 0 c,

: TooltipSw ( adr n - adrNoTooltip$ n )
    vadr-config NoTooltips- c@
        if  2drop NoTooltip$ 0
        then
 ;


: ShowArtistsChar ( char - )
   CatalogBusy?
     if    drop
     else  true to CatalogBusy?
           search-ArtistsChar: Catalog (RefreshCatalog)
     then
 ;

:Class TrackBarAlpha	<super TrackBar   \ To pick one character from the alphabet

: SavePos   ( - )   GetValue: Self  0x3f + vadr-config PositionSlider 2 + c! ;

:M WM_MOUSEMOVE ( h m w l -- res )
            WM_MOUSEMOVE WM: Super
            s"    " vadr-config PositionSlider  place
            SavePos \ GetValue: Self  0x3f + vadr-config PositionSlider 2 + c!
            Paint: Parent
 ;M

:M ToolString:  ( addr cnt -- )
		binfo place
		binfo count \n->crlf
                ;M

:M WM_LBUTTONUP         { --  }
   disable: self
    enable: self
    SavePos vadr-config PositionSlider 2 + c@ wait-cursor ShowArtistsChar arrow-cursor \ Execute at exit
 ;M

;Class

true value BarUpdate?
0 value TrackBarNewPos

:Class TrackBarNum	<super TrackBar   \ To pick one character from the alphabet

: SetPos         ( - ) GetValue: Self  SetPositionInPlay ;

: TrackbarStat   ( - SecondsDP MinutesdP SecondsCP MinutesCP  )
    GetDurationPlay Seconds>SecondsMinutes
    TrackBarNewPos Seconds>SecondsMinutes
 ;

:M WM_MOUSEMOVE  ( h m w l -- res )
            WM_MOUSEMOVE WM: Super
            Paint: Parent
            GetValue: Self to TrackBarNewPos
            Paint: ProgresWindow
 ;M

:M ToolString:  ( addr cnt -- )
		binfo place
		binfo count \n->crlf
                ;M

:M WM_KILLFOCUS  ( h m w l -- )
       true to BarUpdate? 2drop 0
       ['] PlayStat  is TimeStats
 ;M

:M WM_SETFOCUS   ( h m w l -- )
               false to BarUpdate? 0
              ['] TrackbarStat is TimeStats
;M

:M WM_LBUTTONUP         { --  }
   disable: self
   true to BarUpdate?
   enable: self
   SetPos
 ;M

;Class

:Class ComboListBoxExtra	<super ComboListBox

: SendSelf ( n n msg - ) GetID: Self SendDlgItemMessage: parent drop ;

:M SetDroppedWidth: ( Width - ) 0 swap  CB_SETDROPPEDWIDTH SendSelf ;M
:M SetMinVisible:   ( #Items - ) 0 swap CB_SETMINVISIBLE   SendSelf ;M
:M ResetContent:    ( - )       0 0     CB_RESETCONTENT    SendSelf ;M
:M FirstLine:       ( - )       0 0     CB_SETCURSEL       SendSelf ;M
:M ShowDropDown:    ( - )       0 true  CB_SHOWDROPDOWN    SendSelf ;M
:M CloseDropDown:   ( - )       0 false CB_SHOWDROPDOWN    SendSelf ;M

;Class


:Class ttComboListBox	<super  ComboListBoxExtra

:M ToolString:  ( addr cnt -- ) binfo place binfo count \n->crlf ;M

;Class


0   value ToolBarHeight    \ set to height of toolbar if any
0   value StatusBarHeight  \ set to height of status bar if any
185 value TopHeight \ 175
0   value LeftWidth
4   value ThicknessH
7   value ThicknessV
50  value BlankRight
5   value BlankLeft
0   value BlankBottom
0   value dragging
0   value mousedown

: RightXpos      ( -- n )   LeftWidth ThicknessV + ;

:Object TopPane   <Super Child-Window
Font vFont
35 constant FontHeight

' 2drop value WmCommand-Func   \ function pointer for WM_COMMAND
ColorObject FrmColor      \ the background color

TrackBarAlpha TrackBar1
vTrackBarNum TrackBarVol
TrackBarNum  TrackBarPos
TextBox    TextBox1
ttPushButton Button1
ttPushButton Button2
ttPushButton Button+
ttPushButton Button-
ttPushButton Button3
ttPushButton Button4
ttPushButton Button5
ttPushButton Button6
ttPushButton Button7

ttComboListBox CmbList1

Font WinFont           \ default font

: Set-Win-font ( -- )  Set-Win-font ;

:M ClassInit:    ( -- )
                ClassInit: super
                +dialoglist  \ allow handling of dialog messages
                685  to id     \ set child id, changeable
                \ Insert your code here, e.g initialize variables, values etc.
               ;M

:M On_Init:      ( -- )
         On_Init: super \ ++ Needed for the playbuttons
         \ prevent flicker in window on sizing
          CS_DBLCLKS GCL_STYLE hWnd  Call SetClassLong  drop

               Set-Win-font
               Create: WinFont
                screen-size drop 1280 <
                    if    Winxp?
                            if    FW_THIN Weight: vFont -10
                            else  FW_BOLD Weight: vFont -12 then
                    else  Winxp?
                            if    FW_THIN Weight: vFont   -12
                            else  FW_NORMAL Weight: vFont -15 then
                            then
                Width: vFont
                FontHeight  Height: vFont
                Set-vFont


                Create: vFont
                \ set form color to system color
                COLOR_BTNFACE Call GetSysColor NewColor: FrmColor

                self Start: Button7
                0 92 25 25 Move: Button7
                Handle: Winfont SetFont: Button7
                s" X" SetText: Button7

                ID_CmbList1 SetID: CmbList1
                CBS_SORT AddStyle: CmbList1
                       self Start: CmbList1
               0 95 100 25  Move: CmbList1
               Handle: Winfont SetFont: CmbList1
               125 SetDroppedWidth: CmbList1

                self Start: Button6
                100 70 25 25 Move: Button6
                Handle: Winfont SetFont: Button6
                s" <--" SetText: Button6


                self Start: TextBox1
                65 91 140 26 Move: TextBox1
                Handle: Winfont SetFont: TextBox1
                vadr-config TextBox1$ count SetText: TextBox1

	        TBS_AUTOTICKS  AddStyle: TrackBar1
                self Start: TrackBar1
                1 27 false SetRange: TrackBar1
                vadr-config PositionSlider 2 + c@ 0x3f - SetValue: TrackBar1

	        \ TBS_AUTOTICKS  AddStyle: TrackBarPos
                self Start: TrackBarPos
                0 20 false SetRange: TrackBarPos
                0 SetValue: TrackBarPos

	        TBS_AUTOTICKS  AddStyle: TrackBarVol
                self Start: TrackBarVol
                0 RangeVolBar false SetRange: TrackBarVol


                self Start: Button3
                51 70 15 25 Move: Button3
                Handle: Winfont SetFont: Button3
                s" <" SetText: Button3

                self Start: Button4
                78 70 15 25 Move: Button4
                Handle: Winfont SetFont: Button4
                s" >" SetText: Button4

                IDOK SetID: Button2
                self Start: Button2
                210 91 72 26 Move: Button2
                Handle: Winfont SetFont: Button2
                s" Search" SetText: Button2
                GetStyle: Button2 BS_DEFPUSHBUTTON OR SetStyle: Button2

                self Start: Button+
                31 70 25 25 Move: Button+
                Handle: Winfont SetFont: Button+
                s" +" SetText: Button+

                self Start: Button-
                52 70 25 25 Move: Button-
                Handle: Winfont SetFont: Button-
                s" -" SetText: Button-

                self Start: Button1
                25 8 50 26 Move: Button1
                Handle: Winfont SetFont: Button1
                s" || -->" SetText: Button1

                self Start: Button5
                25 8 50 26 Move: Button5
                Handle: Winfont SetFont: Button5
                s" Next" SetText: Button5
 ;M


:M ChangeChar:   ( n -- )
  CatalogBusy? not
    if   wait-cursor
         vadr-config PositionSlider 2 + dup>r
         c@ + ascii @ max ascii Z min
         dup r> c! dup 0x3f - SetValue: TrackBar1
         ShowArtistsChar Paint: Self
         arrow-cursor
    then
 ;M

:M SetVolBar:    ( - )
      RangeVolBar mp-volume@  drop ScaleVol /  - SetValue: TrackBarVol
;M

:M SetRangePosBar: ( range - )
      0 swap false SetRange: TrackBarPos
;M

:M SetPosBar:    ( - )
      BarUpdate?
         if   CurrentPositionPlay SetValue: TrackBarPos
         then
;M

:M ExWindowStyle: ( -- style )
        ExWindowStyle: Super
        WS_EX_CLIENTEDGE or ;M

: DoCmbList1 ( h_m w_l --  )
   drop hiword CBN_CLOSEUP =
        if   OpenFilterWindow
        then
 ;



:M WM_COMMAND     ( h_m w_l -- res )
                 over IDOK =
                     if     2drop _SearchInCatalog
                     else  over loword ID_CmbList1 =
                           if     DoCmbList1
                           else
                            over loword ( ID ) self   \ object address on stack
                            WMCommand-Func ?dup       \ must not be zero
                                 if        execute
                                 else  \   2drop      \ drop ID and object address
                                 then   2drop
                            then
                     then
                   0  ;M


:M SetCommand:        ( cfa -- )    to WMCommand-Func ;M  \ set WMCommand function
:M GetSearchText:     ( - z$ )      GetText: TextBox1 ;M
:M WindowStyle:       ( -- style )  WindowStyle: Super WS_CLIPCHILDREN or ;M
:M MoveTrackbarAlpha: ( x y w h - ) Move: TrackBar1 ;M
:M MoveTrackbarVol:   ( x y w h - ) Move: TrackBarVol ;M
:M MoveTrackbarPos:   ( x y w h - ) Move: TrackBarPos ;M

:M On_Paint: ( -- )
     0 0 Width Height black FillArea: dc
        SaveDC: dc                      \ save device context
        vFont       SelectObject: dc
        TRANSPARENT    SetBkMode: dc
        NearWhite   SetTextColor: dc
        TA_CENTER   SetTextAlign: dc drop
                    pfilename$ count nip 0>
                         if    pfilename$ count ExtractRecord
                               Width: self 41 - 2/ 22 2dup
                               struct, InlineRecord RecordDef Artist
                               struct, InlineRecord RecordDef Cnt_Artist c@ Textout: dc
                               FontHeight + 5 -    \ x y
                               DT_LEFT DT_NOCLIP or DT_WORDBREAK or
                               DT_VCENTER or -rot  \ uformat
                               Width: self  2 pick + 41 -
                               Height: Self   SetRect: TempRect
                               TempRect
                               struct, InlineRecord RecordDef Cnt_Title c@
                               struct, InlineRecord RecordDef Title
                               GetHandle: dc  Call DrawText drop

                         then
        ltYellow SetTextColor: dc
        RightXpos 40 - TopHeight 40 -  vadr-config PositionSlider 1+ 3 Textout: dc
        SelectObject: dc \ Restore object
        RestoreDC: dc
 ;M

;Object

:Noname ( - )  Paint: TopPane ; is Paint_TopPane

\ See Mediatree.f for  BottomLeftPane and BottomRightPane


\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ \\\\\ Splitter Bar \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

COLOR_BTNFACE Call GetSysColor new-color BTNFACE

:Class SplitterBar   <Super child-window

:M WindowStyle:   ( -- style )   \ return the window style
        WindowStyle: super
        [ WS_DISABLED WS_CLIPSIBLINGS or ] literal or ;M


:M On_Paint:      ( -- )            \ screen redraw method
        0 0 Width Height ltgray FillArea: dc
;M

:M On_Init:      ( -- )
        \ Remove CS_HREDRAW and CS_VREDRAW styles from all instances of
        \ class Child-Window to prevent flicker in window on sizing.
        CS_DBLCLKS GCL_STYLE hWnd  Call SetClassLong  drop
  ;M


;Class

SplitterBar SplitterH
SplitterBar SplitterV


\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ \\\\\ Splitter Window - the main window \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\


:Object SplitterWindow   <Super TrayWindow


\ int dragging
\ int mousedown

: RightWidth      ( -- n )   Width RightXpos - BlankRight - 5 max ;
: SplitterYpos    ( -- n )   ToolBarHeight TopHeight + ;
: BottomYpos      ( -- n )   SplitterYpos ThicknessH + ;
: StatusBarYpos   ( -- n )   height StatusbarHeight - ;
: BottomHeight    ( -- n )   StatusBarYpos BottomYpos - BlankBottom - ;
: TotalHeight     ( -- n )   StatusBarYpos ToolBarHeight - ;
: LeftWidthMin    ( -- n )   LeftWidth width min ;
: TopHeightMin    ( -- n )   TopHeight TotalHeight min ;

:M GetRightWidth: ( -- n )   RightWidth ;M

: position-windows ( -- )
        MovePlayButtons
        BlankLeft  ToolBarHeight BlankLeft + Width  BlankLeft 2* - TopHeightMin BlankLeft -  Move: TopPane
        BlankLeft  BottomYpos     LeftWidthMin BlankRight -   ThicknessV -  BottomHeight Move: CatalogWindow
        RightXpos  BottomYpos     RightWidth    BottomHeight  Move: RequestWindow   \ BottomRightPane
        LeftWidth  BottomYpos     ThicknessV    BottomHeight   Move: SplitterV
        0          SplitterYpos     Width         ThicknessH   Move: SplitterH
        MoveMiddleButtons MoveRightButtons MoveProgresWindow
        ;

: Splitter        ( -- n )   \ the splitter window the cursor is on
        hWnd get-mouse-xy
        dup ToolBarHeight StatusBarYpos within
        IF
            2dup BottomYpos height within  swap  LeftWidth RightXpos within  and
            IF  2drop  1
            ELSE  SplitterYpos BottomYpos within  swap  0 width within  and IF  2  ELSE  0  THEN
            THEN
        ELSE 2drop 0
        THEN ;

: On_Tracking     ( -- )   \ set min and max values of LeftWidth and TopHeight here
        mousedown dragging or 0= ?EXIT
        dragging
        Case
            1 of  mousex  0max  Width 100 - min  thicknessV 2/ - 140  max to LeftWidth  endof
            2 of  mousey ToolBarHeight -  0max  TotalHeight 5 - min   thicknessH 2/ - 10 max to TopHeight  endof
        EndCase
        position-windows
        WINPAUSE ;

: On_Clicked      ( -- )
        mousedown not IF  hWnd Call SetCapture drop  THEN
        true to mousedown
        Splitter to dragging
        On_Tracking ;

: On_Unclicked    ( -- )
        mousedown IF  Call ReleaseCapture drop  THEN
        false to mousedown
        false to dragging
        ;

: On_DblClick    ( -- )
        false to mousedown
        Splitter 1 =
        IF
            LeftWidth 8 >
            IF    0 thicknessV 2/ - to LeftWidth
            ELSE  Width thicknessV - 2/  to LeftWidth
            THEN
        position-windows
        THEN ;

:M WM_SETCURSOR   ( h m w l -- )
        Splitter
        Case
            0  of  DefWindowProc: self  endof
            1  of  SIZEWE-CURSOR    1   endof
            2  of  SIZENS-CURSOR    1   endof
        EndCase
        ;M

\ -----------------------------------------------------------------------------
\ Traybar handling
\ -----------------------------------------------------------------------------
:M ShowWindow:   ( -- )
        IsVisible?: self 0=
        if   ShowWindow: super
             SW_RESTORE Show: RequestWindow Update: RequestWindow
             SW_RESTORE Show: ProgresWindow Update: ProgresWindow
             SW_RESTORE Show: FilterWindow  Update: FilterWindow
             Hwnd WindowToForeground
        then ;M

:M HideWindow:   ( -- )
        IsVisible?: self
        if   SW_HIDE Show: ProgresWindow Update: ProgresWindow
             SW_HIDE Show: FilterWindow  Update: FilterWindow
             HideWindow: super
        then ;M

:M WindowTitle:  ( -- ztitle )    z" JukeboxIn4Th" ;M
:M GetTooltip:   ( -- addr len )  WindowTitle: self zcount ;M
\ -----------------------------------------------------------------------------

:M SetParent:   ( hwndparent -- )  to parent ;M     \ Set owner
:M WindowHasMenu: ( -- f )   true ;M
:M WindowStyle: ( -- style )  WindowStyle: Super WS_CLIPCHILDREN or ;M
:M StartSize:   ( -- w h )  screen-size >r 6 * 10 / dup 2/ to LeftWidth r> 4 / 3 * ;M
:M StartPos:    ( -- x y )  CenterWindow: Self ;M
:M WM_INITMENU  ( h m w l -- res ) MenuChecks  0 ;M
:M On_Size:     ( -- )     GetWindowRect: Self DockLeft: FilterWindow  position-windows ;M
:M MinSize:     ( -- width height )  300 100  ;M


:M Classinit: ( -- )
        ClassInit: super   \ init super class
        ['] On_Clicked     SetClickFunc: self
        ['] On_Unclicked   SetUnClickFunc: self
        ['] On_Tracking    SetTrackFunc: self
        ['] On_DblClick    SetDblClickFunc: self
        ;M


:M AddFilesFromSelector:  ( - )    \ add one or more files
        vadr-config 0=   if   map-config-file  then
        CatalogPath first-path" SetDir: GetFilesDialog
        GetHandle: self Start: GetFilesDialog count nip 0>
        if   OpenAppendDatabase 0 GetFile: GetFilesDialog GetLabel
             ClearAllFromCollection #SelectedFiles: GetFilesDialog
             wait-cursor 0
                do  #Done incr dup i GetFile: GetFilesDialog AddFile
                loop
             RemoveDuplicates
             arrow-cursor  CloseReMap  RefreshCatalog
        then ;M

:M OnWmCommand: ( hwnd msg wparam lparam -- hwnd msg wparam lparam )
            over LOWORD ( command ID ) dup IsCommand?
            IF    2dup DoCommand \ intercept Toolbar and shortkey commands
            ELSE  drop  OnWmCommand: Super \ intercept Menu commands
            THEN  ;M

:M On_Init:     ( -- )
        On_Init: super \ ++ Also needed for the traywindow

        AccelTable EnableAccelerators \ init the accelerator table
        \ prevent flicker in window on sizing
        CS_DBLCLKS GCL_STYLE hWnd  Call SetClassLong  drop
        self Start: TopPane
        self Start: CatalogWindow
        self Start: RequestWindow \ BottomRightPane
        self Start: SplitterH
        self Start: SplitterV
        GetHandle: Self SetParent: InfoForm
        GetHandle: Self SetParent: WaitWindow
        GetHandle: Self SetParent: NarratorWindow
        GetHandle: Self SetParent: WebserverAddressDialog
        GetHandle: Self SetParent: FormWiFi
        ;M



:M WM_TIMER     ( hm wl -- res ) \ handle the WM_TIMER events
        drop 1 =
             if     HandleJoystick
             else   SetPosBar: TopPane
                   \ CoverWindow-
                   \ if    Paint: CoverWindow
                   \ else
                    Paint: ProgresWindow
                   \ then
             then
        0
 ;M

:M On_Paint:    ( -- ) 0 0 GetSize: self Addr: dkgray FillArea: dc ;M


\ GetWindowRect: SplitterWindow  ok....
\ .s [4] 342 200 1605 1070  ok..

:M WM_MOVE      ( h m w l -- f )
               GetWindowRect: Self DockLeft: FilterWindow
               MoveProgresWindow  Paint: ProgresWindow
               2drop  0
        ;M

:M Close:       ( -- )
                1 hWnd Call KillTimer drop
                2 hWnd Call KillTimer drop
                AccelTable DisableAccelerators \ free the accelerator table
                end-play vlc-instance vlc-free
                TerminateAllJobs: RightPane
                TerminateAllJobs: WebserverTasks
                TerminateAllJobs: Catalog_iTask
                TerminateAllJobs: JukeBoxTasks
                0 CALL ExitProcess
                ;M
;Object

: ExitJukeBox   ( - )  Close: SplitterWindow ; IDM_QUIT SetCommand


\s

