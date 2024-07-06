Anew -ProgresWindow.f

250 240 240  palettergb new-color NearWhite
\ Lucida Console Script"

string: HomePage$ s" homejb4th.html" HomePage$ place


:Object ProgresWindow   <Super  Child-Window
Font vFont
26 constant FontHeight

:M On_Init: ( -- )
                On_Init: super
                FontHeight   Height: vFont
                -23          Height: vFont
                0             Width: vFont
                0        Escapement: vFont
                0       Orientation: vFont
                FW_SEMIBOLD          Weight: vFont
                true    Italic: vFont
                0           CharSet: vFont
                3      OutPrecision: vFont
                2     ClipPrecision: vFont
                1           Quality: vFont
                49   PitchAndFamily: vFont
                s" Courier New" SetFacename: vFont
                Create: vFont
                s" 00:00/00:00" PlayStat$ place
 ;M

:M WindowStyle:         ( -- style )   [ WS_POPUP WS_BORDER OR ] literal ;M

:M WindowHasMenu:       ( -- f )                false                    ;M

:M StartSize:           ( -- width height )     150 FontHeight 10 + ;M

:M On_Paint: ( -- )
       0 0 Width Height black FillArea: dc
       SaveDC: dc                      \ save device context
       vFont       SelectObject: dc
       TRANSPARENT    SetBkMode: dc
       NearWhite   SetTextColor: dc
       TA_CENTER   SetTextAlign: dc drop
       Width: self 2/ 1 MakePlayStat$ Textout: dc
       SelectObject: dc \ Restore object
       RestoreDC: dc
;M

;Object


: SetBmpName ( adrName count - )
   140 height !  147 width !    \ size bitmap
   10 window_x ! 10 window_y !  \ position bitmap
   save$ place save$ +Null
 ;

:Object CoverWindow   <Super  Child-Window

Font vFont
Font vFont2
Font vFont3

65 constant FontHeight

:M SwitchToProgresWindow:  ( -- )
     false to CoverWindow-
     close: ProgresWindow close: self
     Start:Toppane.ProgresWindow
 ;M

: On_Unclicked      ( -- )
    ClearExecutionState SwitchToProgresWindow: Self
;

:M Classinit: ( -- )
        ClassInit: super   \ init super class
        ['] On_Unclicked   SetUnClickFunc: self

 ;M

:M ExWindowStyle: ( -- exstyle )   WS_EX_TOPMOST ;M

:M On_Init: ( -- )
              On_Init: super
              s" QrCode.bmp" SetBmpName
              Self start: ProgresWindow
              screen-size 40 - swap 173 - swap  173 30 Move: ProgresWindow
              WinXp?
                 IF    FW_THIN     Weight: vFont
                 ELSE  FW_DONTCARE Weight: vFont
                 THEN
              screen-size drop 1280 <
                 if    WinXp?
                          if 11
                          else 14                          then
                 else   WinXp?
                          if 14
                          else 18
                          then
                 then  Width: vFont
              FontHeight  Height: vFont
              Set-vFont
              Create: vFont
              s" Times New Roman" SetFaceName: vFont2
              9 Width: vFont2
              10  Height: vFont2
              Create: vFont2

              s" Times New Roman" SetFaceName: vFont3
              9 Width: vFont3
              15 Height: vFont3
              Create: vFont3

              DisableScreenSaver
              Hwnd to ogl-hwnd      \ For _load-bitmap
              getDC: self to ghdc   \ For _load-bitmap

 ;M


:M WindowStyle:         ( -- style )        [ WS_POPUP  ] literal ;M
:M WindowHasMenu:       ( -- f )            false                 ;M
:M StartSize:           ( -- width height ) screen-size           ;M


: FontDist ( - dist ) FontHeight 4 * 3 / ;


:M On_Paint: ( -- )
      SaveDC: dc
      0 0 Width Height black FillArea: dc

        vFont       SelectObject: dc
        TRANSPARENT    SetBkMode: dc
        NearWhite   SetTextColor: dc
        TA_CENTER   SetTextAlign: dc drop
                    pfilename$ count nip 0>
                         if    pfilename$ count ExtractRecord
                               screen-size 2/ swap 2/ swap FontDist - 2dup
                               struct, InlineRecord RecordDef Artist
                               struct, InlineRecord RecordDef Cnt_Artist c@ Textout: dc
                               FontDist +
                               struct, InlineRecord RecordDef Title
                               struct, InlineRecord RecordDef Cnt_Title c@
                               Textout: dc

        vFont2       SelectObject: dc drop
        screen-size 8 - swap 86 - swap s" J u k e b o x I n 4 T h" Textout: dc
                         then

        vadr-config Webserver- c@
           if  _load-bitmap 0= abort" Failed to load the bitmap"
               vFont3    SelectObject: dc drop
               TA_LEFT   SetTextAlign: dc drop
               window_x @  160 vadr-config WiFiName$ count Textout: dc
               window_x @  180 vadr-config WiFiPassword$ count Textout: dc
               window_x @  200 vadr-config
                  s" http://" pad place
                  AddressWebServer$ count pad +place
                  s" /" pad +place HomePage$ count pad +place
               pad count Textout: dc
           then

      SelectObject: dc drop
      RestoreDC: dc
;M


;Object




:Object WaitWindow                <Super  Window

Font vFont           \ default font
' 2drop value WmCommand-Func   \ function pointer for WM_COMMAND
ColorObject FrmColor      \ the background color

:M ClassInit:   ( -- )
                ClassInit: super
                +dialoglist  \ allow handling of dialog messages
                \ 689  to id     \ set child id, changeable
                \ Insert your code here, e.g initialize variables, values etc.
                ;M

:M WindowTitle: ( -- ztitle )
                z" InfoForm"
                ;M

:M StartSize:   ( -- width height )
                400 100
                ;M

:M StartPos:    ( -- x y )
                CenterWindow: Self
                ;M

:M WindowStyle:  ( -- style )
                WS_POPUPWINDOW  WS_THICKFRAME  or
                ;M

:M Close:        ( -- )
                \ Insert your code here, e.g any data entered in form that needs to be saved
                Close: super
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
                12 Width: vFont
                36 Height: vFont
                Set-vFont
                Create: vFont

                \ set form color to system color
                \ COLOR_BTNFACE Call GetSysColor NewColor: FrmColor
                ;M

:M WM_MOUSEMOVE (  w l -- res )
                drop wait-cursor
                0 ;M


:M On_Paint:    ( -- )
       wait-cursor
       SaveDC: dc                      \ save device context
       vFont       SelectObject: dc
       TRANSPARENT    SetBkMode: dc
       0 0 Width Height LTyellow FillArea: dc
       black   SetTextColor: dc
       0 14 GetSize: self SetRect: winRect
       s" This may take several minutes. \n" tmp$ place

       #done @ dup 0>
         if    s>d (UD,.) tmp$ +place
         else  drop
         then

       tmp$ +null
       tmp$ count winRect
       DT_CENTER DT_VCENTER or DT_NOCLIP or DrawText: dc
       SelectObject: dc \ Restore object
       RestoreDC: dc drop
                ;M

:M On_Done:    ( -- )
                Delete: vFont
                \ Insert your code here, e.g delete fonts, any bitmaps etc.
                On_Done: super
                ;M

;Object

: AboutMsg ( hOwnerWindow - )
   >r z" Written by Jos v.d.Ven\n\nin Win32Forth.\n\nVersion: 4.0\n\nhttps://github.com/Jos-Ven/Win32Forth-extensions"
   z" About the JukeboxIn4Th"
   [ MB_OK MB_ICONINFORMATION or MB_TASKMODAL or ] literal r> MessageBox
   drop
  ;

\s

